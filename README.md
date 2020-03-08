# LoveGme
Wrapper for Game Music Emu in Love using luajit's ffi.

# What is this?
[Game Music Emu](https://bitbucket.org/mpyne/game-music-emu/wiki/Home) emulates old game systems' sound hardware so you can play songs made for the NES, SNES, Genesis, etc. The advantages of this over rendering to an ogg or something is *really small* file sizes, tempo control, and song structure (like an intro part that you don't want to loop). 

Anyway, to use this you need to build the .dll or .so (make sure it's named libgme) and put that with the rest or the libraries love uses (SDL2.dll etc.)

# Usage
### Basic Usage
```Lua
LoveGme = require "lovegme"

function love.load()
  gme = LoveGme()
  gme:loadFile("coolSong.nsf") -- note this will automatically set to the 1st track
  gme:setTrack(3) -- sets to the 4th track
  gme:play()
end

function love.update()
  gme:update() -- don't forget this!
end
```
If the file only has one track or you want to play the first track, then it is unnecessary to "set" the track as it is automatically set to the first one.
### Info
When a track is set, it's info is loaded into a table called `info`.

The following keys will contain strings ( empty if not specified in the file ): `system`, `game`, `song`, `author`, `copyright`, `comment`, `dumper`

These will contain number values ( -1 if not found ): `length`, `intro_length`, `loop_length`, `play_length`

The LoveGme instance also has variables called `track_count`, `current_track`, and `voice_count`. Example:
```Lua
-- plays next track and displays the name of the song
local next = gme.current_track + 1
gme:setTrack(next < gme.track_count and next or 0)
print("currently playing: " .. gme.info.song)
```
### Voices
Getting the name of a voice:
```Lua
print( "the title bestowed upon the 3rd voice by Game Music Emu: " .. gme:getVoiceName(2) )
```
Muting a voice:
```Lua
gme:muteVoice(0, true)
```
Unmuting a voice:
```Lua
gme:muteVoice(0, false)
```
Muting voices 2 and 5
```Lua
local bit = require "bit"
gme:muteVoices(bit.or( 2^1, 2^4 )) -- 0b01010
```
### Sound Effects
You can render out a part of a track to sound data for sound effects.
```Lua
-- renders out 0.2 seconds of track 1
local soundEffect = love.audio.newSource( gme:renderTrackData(0, 0.2) )
```
### Control
An instance of LoveGme will have functions `play`, `pause`, `stop`, and `resume` which work like the similarly named functions of love audio sources.

You can also get the queueableSource object from the instance which is stored in `source`, so if you wanted to, say, apply a filter you can do so.
```Lua
local source = gme.source
source:setFilter {
	type = "highpass",
    highgain = 0.2
}
```
### Others
`setTempo` can change the tempo.
```Lua
gme:setTempo(0.5) -- half tempo
```
this does not change the *speed* or pitch, but you can do that with
```Lua
gme.source:setPitch(0.5) -- half speed (and pitch)
```
There is also a function called `enableAccuracy` but i can't notice a difference when using it so i can't even guarantee that it works, but it works like muteVoice (pass a boolean).
### Sample rate and buffers
When you create a LoveGme instance you can pass 3 numbers. Sample Rate, Buffer Size, and Buffer Count.
The defaults for these are 44100, 8192, and *what ever love chooses(usually 8)* respectively. But, yeah you can use your own values when you create an instance.
```Lua
gme = LoveGme(96000,256,4)
```
