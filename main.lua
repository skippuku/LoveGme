
local LoveGme = require "lovegme"
local gme

local pause = false
local currentPath = "no file"
local report = "drag a supported file here to play it\nuse left and right keys to go through tracks\nuse p to pause"

function love.load(args)
	gme = LoveGme()
	local path = args[1]
	if path then openFile(love.filesystem.newFile(path)) end
	updateTitle()
end

function love.update()
    gme:update()
end

function love.draw()
	love.graphics.print(report, 10,10)
end

function love.keypressed(key)
	if key == "left" then
		local next_track = gme.current_track - 1
		if next_track < 0 then
			next_track = gme.track_count - 1 -- last track
		end
		gme:setTrack(next_track)
		gme:play()
	elseif key == "right" then
		local next_track = gme.current_track + 1
		if next_track >= gme.track_count then
			next_track = 0 -- first track
		end
		gme:setTrack(next_track)
		gme:play()
	elseif key == 'p' then
		pause = not pause
		if pause then
			gme:pause()
		else
			gme:play()
		end
	end
	updateTitle()
end

function love.filedropped(file)
	openFile(file)
end

function updateTitle()
	love.window.setTitle("LoveGme Player: "
		..(currentPath:match("^.+/(.+)$") or "no file")
		.." "..(gme.current_track+1)
		.."/"..gme.track_count
	)
end

function openFile(file)
	if file then
		gme:loadFile(file)
		gme:play()
		currentPath = file:getFilename()
		updateTitle()
		genReport()
	end
end

function genReport()
	report = ""
	for k, v in pairs(gme.info) do
		report = report ..k..": "..v.."\n"
	end
end
