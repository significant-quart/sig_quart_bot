local uv = require("uv")
local json = require("json")

local running, resume, yield = coroutine.running, coroutine.resume, coroutine.yield


local ytdl = require("../deps/Discordia/libs/class")("ytdl")


function ytdl:__init(url, search)
	local stdout = uv.new_pipe(false)
	local child, thread

	local function close()
        child:kill()

        if not stdout:is_closing() then
            stdout:close()
        end
    end

	local args = { "--no-playlist", "--dump-json", url }
	if search then
		table.insert(args, 1, "ytsearch")
		table.insert(args, 1, "--default-search")
	end

	child = assert(uv.spawn("youtube-dl", {
		args = args,
		stdio = { 0, stdout, 2 },
	}, function()
		close()

		return assert(resume(thread))
	end), "youtube-dl could not be started, is it installed and on your executable path?")

	thread = running()

	self._buffer = ""

	stdout:read_start(function(err, chunk)
		if err then
			close()

			return assert(resume(thread))
		elseif chunk then
			self._buffer = self._buffer..chunk
		end
	end)

	yield()
end

function ytdl:read()
	self._data = json.decode(self._buffer)
	self._buffer = nil

	if not self._data then
		return "video data could not be used", true
	end

	if not self._data.formats then
		return "no formats could be found", true
	end

	local audio

	if self._data.requested_formats then
        for _, format in pairs(self._data.requested_formats) do
            if format.url:find("mime=audio") then
                audio = format.url

                break
            end
        end
    elseif self._data.url then
        audio = self._data.url
    end

	if not audio then
		return "no suitable formats could be found", true
	end


	return {
		audio = audio,
		duration = self._data.duration,
		live = (self._data.duration == 0.0),
		title = self._data.title,
		thumbnail = self._data.thumbnail,
		url = self._data.webpage_url
	}, false
end


return ytdl