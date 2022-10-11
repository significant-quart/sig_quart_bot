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


return {
    returnCommandInput = returnCommandInput,
    interval = interval,
    createTimestamp = createTimestamp
}