local utilities = require("utilities")
local ytdl = require("ytdl")
local timer = require("timer")

local ERRORS = {
    CONNECTED = "I'm already connected to a channel",
    NOT_CONNECTED = "I'm not connected to any channel.",
    USER_NOT_CONNECTED = "you need to be connected to a channel.",
    WRONG_CHANNEL = "you need to be in the same channel as me.",
    IDLE = "nothing is playing at the moment.",
    LIVE = "this command is not available for live streams.",
    WRONG_SEEK = F("you did format the seek command properly.\nExample ``%sseek 00:01:30`` or ``%sseek 01:30`` (``HH:MM:SS`` or ``MM:SS``)", prefix, prefix),
    LONG_SEEK = "seek cannot exceed duration of audio"
}
local VOLUME_MAX = 100.0
local VOLUME_MIN = 0.1


local connection
local currentlyPlaying
local queue = {}
local volume = 1.0


local function formatTime(seconds, live)
    if live then
        return "LIVE"
    end

	seconds = tonumber(seconds)

    if seconds > 0 then
        if seconds < 3600 then
            return os.date('!%M:%S', seconds)
        end

        return os.date('!%H:%M:%S', seconds)
    end

    return "??:??"
end

local function calculateElapsedTime()
    if currentlyPlaying.start == nil then
        return 0
    end

    if currentlyPlaying.paused then
        return currentlyPlaying.elapsedTime
    end

    return (os.time() - currentlyPlaying.start) + currentlyPlaying.elapsedTime
end

local function calculateSeekDuration(time)
    local hm, ms, s = time:match("^(%d+):(%d+)"..(#time > 5 and ":(%d+)" or ""))
    hm, ms, s = (tonumber(hm) or 0), (tonumber(ms) or 0), (tonumber(s) or 0)

    return (hm * 60 * (#time > 5 and 60 or 1)) + (ms * (#time > 5 and 60 or 1)) + s
end

local function deleteTimeout()
    if not currentlyPlaying or currentlyPlaying.live then
        return
    end

    if currentlyPlaying.timeout then
        p("removed old timeout")

        timer.clearTimeout(currentlyPlaying.timeout)
    end
end

local function createTimeout()
    if not currentlyPlaying or currentlyPlaying.live then
        return
    end

    deleteTimeout()

    local elapsedTime = calculateElapsedTime()
    if not elapsedTime then
        return
    end

    currentlyPlaying.timeout = timer.setTimeout(((currentlyPlaying.duration + 1) - elapsedTime) * 1000, coroutine.wrap(function()
        p("evaluated skip")

        commands.GetAll()["skip"]:Evaluate(nil, nil, true)
    end))

    p("made new timeout")
end


command("summon", function(args, message)
    assert(message.member and message.member.voiceChannel, "")
    assert(connection == nil, ERRORS.CONNECTED)

    connection = message.member.voiceChannel:join()
end):Category("Music Commands")

command("dc", function(args, message)
    assert(connection ~= nil, ERRORS.NOT_CONNECTED)
    assert(message.member and message.member.voiceChannel and message.member.voiceChannel.id == connection.channel.id, ERRORS.WRONG_CHANNEL)

    connection:close()
    connection = nil
end):Category("Music Commands")

command("play", function(args, message)
    assert(args[2], "")
    assert(message.member and message.member.voiceChannel, ERRORS.USER_NOT_CONNECTED)

    if not connection then
        commands.GetAll()["summon"]:Evaluate(args, message)
    else
        assert(message.member.voiceChannel.id == connection.channel.id, ERRORS.WRONG_CHANNEL)
    end

    local search, query = false, ""
    local searchMessage

    if not args[3] and args[2]:match("^h?t?t?p?s?:?/?/?www%.") then
        query = args[2]
    else
        query = utilities.returnCommandInput(args)
        search = true
        searchMessage = embed(F("%s searching for ``%s``", message.author.mentionString, query), message)
    end

    local handle = ytdl(query, search)
    local data, err = handle:read()

    assert(err == false, data)

    if search then
        searchMessage:delete()
    end

    data.elapsedTime = 0
    data.owner = message.author.mentionString

    if not currentlyPlaying then
        currentlyPlaying = data

        connection:playFFmpeg(data.audio, nil, function()
            currentlyPlaying.start = os.time()

            currentlyPlaying.message = message:reply {
                embed = {
                    description = F("**Now playing**\n[%s](%s) [%s]", data.title, data.url, data.owner),
                    color = config.colours.default,
                    thumbnail = {
                        url = data.thumbnail
                    }
                }
            }

            createTimeout()
        end, nil, { "-filter:a", F("volume=%.1f", volume) })
    else
        data.message = message:reply {
            embed = {
                description = F("**Added to the queue**\n[%s](%s) [%s]", data.title, data.url, data.owner),
                thumbnail = {
                    url = data.thumbnail
                },
                color = config.colours.default
            }
        }

        table.insert(queue, data)
    end
end):Category("Music Commands"):CreateAlias("p")

command("skip", function(args, message, force)
    if not force then
        assert(connection ~= nil, ERRORS.NOT_CONNECTED)
        assert(message.member and message.member.voiceChannel, ERRORS.USER_NOT_CONNECTED)
        assert(currentlyPlaying ~= nil, ERRORS.IDLE)
    end

    currentlyPlaying.message:delete()

    if #queue > 0 then
        deleteTimeout()

        currentlyPlaying = queue[1]

        local channel = currentlyPlaying.message.channel
        currentlyPlaying.message:delete()

        connection:playFFmpeg(currentlyPlaying.audio, nil, function()
            currentlyPlaying.start = os.time()

            if channel then
                currentlyPlaying.message = channel:send {
                    embed = {
                        description = F("**Now playing**\n[%s](%s) [%s]", currentlyPlaying.title, currentlyPlaying.url, currentlyPlaying.owner),
                        color = config.colours.default,
                        thumbnail = {
                            url = currentlyPlaying.thumbnail
                        }
                    }
                }
            end

            table.remove(queue, 1)

            createTimeout()
        end, nil, { "-filter:a", F("volume=%.1f", volume) })
    else
        connection:stopStream()
        deleteTimeout()
        currentlyPlaying = nil
    end
end):Category("Music Commands"):CreateAlias("s")

command("pause", function(args, message)
    assert(connection ~= nil, ERRORS.NOT_CONNECTED)
    assert(message.member and message.member.voiceChannel, ERRORS.USER_NOT_CONNECTED)
    assert(currentlyPlaying ~= nil, ERRORS.IDLE)
    assert(not currentlyPlaying.paused, "")

    connection:pauseStream()
    currentlyPlaying.paused = true
    currentlyPlaying.elapsedTime = os.time() - currentlyPlaying.start
    deleteTimeout()
end):Category("Music Commands")

command("resume", function(args, message)
    assert(connection ~= nil, ERRORS.NOT_CONNECTED)
    assert(message.member and message.member.voiceChannel, ERRORS.USER_NOT_CONNECTED)
    assert(currentlyPlaying ~= nil, ERRORS.IDLE)
    assert(currentlyPlaying.paused, "")

    connection:resumeStream()
    currentlyPlaying.paused = false
    currentlyPlaying.start = os.time()
    createTimeout()
end):Category("Music Commands")

command("time", function(args, message)
    assert(connection ~= nil, ERRORS.NOT_CONNECTED)
    assert(message.member and message.member.voiceChannel, ERRORS.USER_NOT_CONNECTED)
    assert(currentlyPlaying ~= nil, ERRORS.IDLE)

    assert(not currentlyPlaying.live, ERRORS.LIVE)

    local elapsedTime = calculateElapsedTime()

    if elapsedTime > currentlyPlaying.duration then
        elapsedTime = currentlyPlaying.duration
    end

    message:reply{
        embed = {
            description = F("[%s](%s) [%s]\n%s⚪%s %s/%s", currentlyPlaying.title, currentlyPlaying.url, currentlyPlaying.owner, ("▬"):rep((elapsedTime / currentlyPlaying.duration * 20) - 1 ), ("▬"):rep((20 - (elapsedTime / currentlyPlaying.duration * 20))), formatTime(elapsedTime), formatTime(currentlyPlaying.duration)),
            thumbnail = {
                url = currentlyPlaying.thumbnail
            },
            color = config.colours.default,
            footer = {
                icon_url = message.guild.iconURL,
            }
        }
    }
end):Category("Music Commands")

command("seek", function(args, message)
    assert(args[2], "")
    assert(connection ~= nil, ERRORS.NOT_CONNECTED)
    assert(message.member and message.member.voiceChannel, ERRORS.USER_NOT_CONNECTED)
    assert(currentlyPlaying ~= nil, ERRORS.IDLE)
    assert(not currentlyPlaying.live, ERRORS.LIVE)

    local seekDuration = calculateSeekDuration(args[2])
    assert(seekDuration > 0, ERRORS.WRONG_SEEK)
    assert(seekDuration <= currentlyPlaying.duration, ERRORS.LONG_SEEK)

    deleteTimeout()

    connection:playFFmpeg(currentlyPlaying.audio, nil, function()
        currentlyPlaying.paused = false

        currentlyPlaying.elapsedTime = seekDuration
        currentlyPlaying.start = os.time()

        createTimeout()
    end, { "-ss", seekDuration }, { "-filter:a", F("volume=%.1f", volume) })
end):Category("Music Commands")

command("volume", function(args, message)
    assert(connection ~= nil, ERRORS.NOT_CONNECTED)
    assert(message.member and message.member.voiceChannel, ERRORS.USER_NOT_CONNECTED)
    assert(currentlyPlaying ~= nil, ERRORS.IDLE)

    args[2] = tonumber(args[2])
    assert(args[2], "")

    volume = args[2]

    connection:playFFmpeg(currentlyPlaying.audio, nil, function()
        currentlyPlaying.paused = false

        createTimeout()
    end, { "-ss", calculateElapsedTime() }, { "-filter:a", F("volume=%.1f", math.clamp(args[2], VOLUME_MIN, VOLUME_MAX) + 0.0) })
end):Category("Music Commands")

command("queue", function(args, message) 
    assert(connection ~= nil, ERRORS.NOT_CONNECTED)
    assert(message.member and message.member.voiceChannel, ERRORS.USER_NOT_CONNECTED)
    assert(currentlyPlaying ~= nil, ERRORS.IDLE)

    local queueData = F("  Title%s| Duration\n", (" "):rep(35))
    for i = 0, #queue, 1 do
        local data = (i == 0 and currentlyPlaying or queue[i])
        local title = (#data.title > 39 and F("%s…", data.title:sub(1, 38)) or data.title)

        queueData = queueData..F("%s %s%s | %s\n",
            (i == 0 and data.paused and "∥" or i == 0 and not data.paused and "→" or "↳"),
            title, (" "):rep(39 - #title),
            formatTime(data.duration, data.live))
    end

    embed(F("```%s```", queueData), message)
end):Category("Music Commands")

command("clearqueue", function(args, message)
    queue = {}

    embed(F("%s queue has been cleared.", message.author.mentionString), message)
end):Category("Music Commands")



client:on("voiceDisconnect", function(member)
    if member.user == client.user then
        connection = nil

        if currentlyPlaying then
            deleteTimeout()

            currentlyPlaying.message:delete()
        end

        currentlyPlaying = nil
        queue = {}
    end
end)

client:on("voiceChannelJoin", function(member, channel)
    if member.user == client.user then
        member:deafen()

        if connection then
            connection = channel:join()
        end
    end
end)