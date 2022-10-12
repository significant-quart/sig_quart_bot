local timer = require("timer")


local F = string.format


local function returnCommandInput(args, seperator)
    return table.concat(args, (seperator or " "), 2)
end

local function interval(ms, cb)
	return timer.setInterval(ms, coroutine.wrap(cb))
end

local function createTimestamp(unix, type)
    return F("<t:%d:%s>", unix, type)
end

local function clockToSeconds(time)
    local hm, ms, s = time:match("^(%d+):(%d+)"..(#time > 5 and ":(%d+)" or ""))
    hm, ms, s = (tonumber(hm) or 0), (tonumber(ms) or 0), (tonumber(s) or 0)

    return (hm * 60 * (#time > 5 and 60 or 1)) + (ms * (#time > 5 and 60 or 1)) + s
end


return {
    returnCommandInput = returnCommandInput,
    interval = interval,
    createTimestamp = createTimestamp,
    clockToSeconds = clockToSeconds
}