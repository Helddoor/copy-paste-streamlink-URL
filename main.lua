local utils = require 'mp.utils'

mp.msg.info("COPY-PASTE-STREAMLINK-URL LOADED")

function trim(s)
   return (s:gsub("^%s*(%S+)%s*", "%1"))
end

function streamlink(url)
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
      mp.commandv("loadfile", addr, "replace")
      mp.set_property("file-local-options/force-media-title", "Streamlink: " .. url)
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