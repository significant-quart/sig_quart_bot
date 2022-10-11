local uv = require("uv")
local json = require("json")

local running, resume, yield = coroutine.running, coroutine.resume, coroutine.yield


local ytdl = require("../deps/discordia/libs/class")("ytdl")


function ytdl:__init(url, search)
	local stdout = uv.new_pipe(false)
	local child

	local function close()
        child:kill()

        if not stdout:is_closing() then
            stdout:close()
        end
    end

	local args = { "--dump-json", url }
	if search then
		table.insert(args, 1, "ytsearch")
		table.insert(args, 1, "--default-search")
	end

	child = assert(uv.spawn("youtube-dl.bat", {
		args = args,
		stdio = { 0, stdout, 2 },
	}), "youtube-dl could not be started, is it installed and on your executable path?")

	local thread = running()

	stdout:read_start(function(err, chunk)
		if err or not chunk then
			close()
		else
			self._buffer = chunk
		end

		stdout:read_stop()

        return assert(resume(thread))
	end)

	yield()
end

function ytdl:read()
	self._buffer = json.decode(self._buffer)
	self._data = {}

	if not self._buffer then
		return "video data could not be used", true
	end

	if not self._buffer.formats then
		return "no formats could be found", true
	end

	if self._buffer.requested_formats then
        for _, format in pairs(self._buffer.requested_formats) do
            if format.url:find("mime=audio") then
                self._data.audio = format.url

                break
            end
        end
    elseif self._buffer.url then
        self._data.audio = self._buffer.url
    end

	if not self._data.audio then
		return "no suitable formats could be found", true
	end

	self._data.duration = (self._buffer.duration or 0.0)
	self._data.live = (self._data.duration == 0.0)
	self._data.title = (self._buffer.title or "")
    self._data.thumbnail = (self._buffer.thumbnail or "")
	self._data.url = (self._buffer.webpage_url or "")

	return self._data, false
end

return ytdl