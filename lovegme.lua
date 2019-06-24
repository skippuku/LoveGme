
local ffi = require "ffi"

ffi.cdef[[
typedef const char* gme_err_t;
typedef struct Music_Emu Music_Emu;
gme_err_t gme_open_file( const char path [], Music_Emu** out, int sample_rate );
gme_err_t gme_open_data( void const* data, long size, Music_Emu** out, int sample_rate );
int gme_track_count( Music_Emu const* );

gme_err_t gme_start_track( Music_Emu*, int index );
gme_err_t gme_play( Music_Emu*, int count, short out [] );

void gme_set_tempo( Music_Emu*, double tempo);
void gme_enable_accuracy( Music_Emu*, int enabled);

typedef struct gme_info_t
{
	/* times in milliseconds; -1 if unknown */
	int length;			/* total length, if file specifies it */
	int intro_length;	/* length of song up to looping section */
	int loop_length;	/* length of looping section */

	/* Length if available, otherwise intro_length+loop_length*2 if available,
	otherwise a default of 150000 (2.5 minutes). */
	int play_length;

	int i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15; /* reserved */

	/* empty string ("") if not available */
	const char* system;
	const char* game;
	const char* song;
	const char* author;
	const char* copyright;
	const char* comment;
	const char* dumper;

	const char *s7,*s8,*s9,*s10,*s11,*s12,*s13,*s14,*s15; /* reserved */
} gme_info_t;
gme_err_t gme_track_info( Music_Emu const*, gme_info_t** out, int track );
void gme_free_info( gme_info_t* );

int gme_voice_count( Music_Emu const* );
const char* gme_voice_name( Music_Emu const*, int i );
void gme_mute_voice( Music_Emu*, int index, int mute );
void gme_mute_voices( Music_Emu*, int muting_mask );
]]

local gme = ffi.load("libgme")

ffi.metatype("Music_Emu", {
	__gc == function (emu)
		gme.gme_delete(emu)
	end
})

ffi.metatype("gme_info_t", {
	__gc = function (info)
		gme.gme_free_info(info)
	end
})

local INFO_STR = {
	system = true,
	game = true,
	song = true,
	author = true,
	copyright = true,
	comment = true,
	dumper = true
}

local INFO_INT = {
	length = true,
	intro_length = true,
	loop_length = true,
	play_length = true
}

local LoveGme = {}
local sample_rate, buf_size, voice_count, track_count, current_track
local emu, qs, out, info
local playing

function LoveGme.init(rate, buf, arg_count_buf)
	sample_rate = rate or 44100
	buf_size = buf or 8192

	voice_count = 0
	track_count = 0
	current_track = 0

	playing = false

	qs = love.audio.newQueueableSource(sample_rate, 16, 2, arg_count_buf)
	emu = ffi.new("Music_Emu*[1]")
	info = ffi.new("gme_info_t*[1]")
end

function LoveGme.loadFile(fileName)
	local fileData = love.filesystem.newFileData(fileName)
	gme.gme_open_data(fileData:getPointer(), fileData:getSize(), emu, sample_rate)
	--gme.gme_open_file(fileName, emu, sample_rate)
	track_count = gme.gme_track_count( emu[0] )
	voice_count = gme.gme_voice_count( emu[0] )
	LoveGme.setTrack(0)
end

function LoveGme.setTrack(track)
	qs:stop()
	if track_count==0 or track >= track_count then
		error("no track "..track)
	end
	current_track = track
	gme.gme_track_info( emu[0], info, track)
	gme.gme_start_track( emu[0], current_track )
end

function LoveGme.getSource()
	return qs
end

function LoveGme.update()
	while qs:getFreeBufferCount() > 0 do
		local sd = love.sound.newSoundData(buf_size/2, sample_rate, 16, 2)
		gme.gme_play( emu[0], buf_size, sd:getPointer())
		qs:queue(sd)
		if playing then qs:play() end
	end
end

function LoveGme.setTempo(tempo)
	gme.gme_set_tempo(emu[0], tempo)
end

function LoveGme.enableAccuracy(bool)
	gme.gme_enable_accuracy( emu[0], bool )
end

function LoveGme.info(name)
	if INFO_STR[name] then
		return ffi.string( info[0][name] )
	elseif INFO_INT[name] then
		return tonumber( info[0][name] )
	else
		return "no info for " .. name
	end
end

function LoveGme.getVoiceCount()
	return voice_count
end

function LoveGme.getVoiceName(voice)
	return ffi.string( gme.gme_voice_name( emu[0], voice ) )
end

function LoveGme.muteVoice(voice, bool)
	gme.gme_mute_voice( emu[0], voice, bool)
end

function LoveGme.muteVoices(mask)
	gme.gme_mute_voices( emu[0], mask )
end

function LoveGme.getTrackCount()
	return track_count
end

function LoveGme.play()
	qs:play()
	playing = true
end

function LoveGme.pause()
	qs:pause()
	playing = false
end

function LoveGme.stop()
	qs:stop()
	playing = false
end

function LoveGme.resume()
	qs:resume()
	playing = false
end

return LoveGme
