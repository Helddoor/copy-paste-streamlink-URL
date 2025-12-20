local utils = require 'mp.utils'

mp.msg.info("COPY-PASTE-STREAMLINK-URL LOADED")
mp.add_hook("on_load", 50, function()
   local url = mp.get_property("user-data/next-url")
   local forced_title = mp.get_property("user-data/forced-title")
  
   -- Second call clears it so it doesn't affect the next video
   if url and url ~= "" then
      url = url:gsub('"', ''):gsub("'", "")
      mp.set_property("user-data/real-url", url)
      mp.set_property("user-data/next-url", "")
   end

   if forced_title and forced_title ~= "" then
        forced_title = forced_title:gsub('"', ''):gsub("'", "")
        mp.set_property("file-local-options/force-media-title", forced_title)
        mp.set_property("user-data/forced-title", "")
    end
end)

function trim(s)
   return (s:gsub("^%s*(%S+)%s*", "%1"))
end

function streamlink(url)
   local filename = url:match("([^/]+)$") or "stream" -- Extract filename from URL (gets everything after the last /)
   filename = filename:gsub("%?.*", "")    -- Remove query parameters (everything after ?)
   local clean_title = filename:gsub("[^%w%.]", "_")    -- Sanitize: replace non-alphanumeric chars (except . ) with underscores


   local pid = utils.getpid()
   local port = 8000 + (pid % 1000) 
   local addr = "http://127.0.0.1:" .. port
   
   mp.osd_message("Streamlink: Initializing Engine...")
   
   mp.command_native_async({
      name = "subprocess",
      args = { 
         "streamlink", 
         "--player-external-http", 
         "--player-external-http-port", tostring(port), 
         url, 
         "best",
         "--retry-streams", "5",
         "--retry-open", "5"
      },
      playback_only = false,
      capture_stdout = false,
      capture_stderr = false
   })

   -- 2. Give Streamlink a moment to initialize the server (1.5 seconds) then tell mpv to pull the data from that local server.
   mp.add_timeout(1.5, function()
      mp.osd_message("Streamlink: Connecting...")
      -- Store metadata in user-data so the hook can pick it up
      mp.set_property("user-data/real-url", url)
      mp.set_property("user-data/forced-title", clean_title)
      mp.commandv("loadfile", addr, "replace")
      -- prevents AUTO-PLAY:
      mp.set_property_bool("pause", true)
   end)
end

function openURL()
   
   local subprocess = {
      name = "subprocess",
      args = { "powershell", "-Command", "Get-Clipboard", "-Raw" },
      playback_only = false,
      capture_stdout = true,
      capture_stderr = true
   }
   
   mp.osd_message("Getting URL from clipboard...")
   
   local r = mp.command_native(subprocess)
   
   -- Failed getting clipboard data for some reason
   if r.status < 0 or not r.stdout then
      mp.osd_message("Failed getting clipboard data!")
      print("Error(string): "..r.error_string)
      print("Error(stderr): "..r.stderr)
      return
   end
   
   local url = trim(r.stdout)
   if not url or url == "" then
      mp.osd_message("Clipboard empty")
      return
   end
	
   -- Technically the old way (but mpv should support this now natively)
   -- mp.commandv("loadfile", url, "replace")
   streamlink(url)

end

mp.add_key_binding("ctrl+v", openURL)