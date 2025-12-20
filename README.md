# copy paste

Before was it not possible to copy paste links into mpv that feature was seemingly added at 28.12.2024 (https://github.com/mpv-player/mpv/issues/15695). This script was based on something I found somewhere but I do not remember where. It is also now modified to use streamlink to play the video to hopefully resolve some playback skip issues I sometimes have

## Requirements

Besides mpv, have streamlink installed

## Config streamlink config

If the following folder/files do not exist then create them.

location:  
%APPDATA%\streamlink\config

example config:

```
# Use mpv as the default player
player=mpv

# Always pick the best quality
default-stream=best

#Allows to download multiple segements at once
stream-segment-threads=6
#stream-segment-threads=10 # might be a bit too much

# Pass these stability arguments to mpv every time (technically should use mpv configs)
player-args=--cache=yes --demuxer-max-bytes=500MiB
```
