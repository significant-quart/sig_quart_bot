local http = require("coro-http")
local enums = require("enums")
local utilities = require("utilities")


local OVERLAY_MAP = {
    triggered = "triggered",
    lgbt = "gay",
    wasted = "wasted",
    jail = "jail"
}


command("coin", function(args, message)
    math.randomseed(os.time())

    embed((math.random(1, 2) == 1 and "Heads" or "Tails"), message)
end):Category("Fun Commands"):Description("Flip a coin.")

command("ping", function(args, message)
    message:reply {
        embed = {
            title = "Pong",
            image = {
                url = "https://media1.tenor.com/images/6f1d20bb80a1c3f7fbe3ffb80e3bbf4e/tenor.gif"
            },
            color = config.colours.default
        }
    }
end):Category("Fun Commands"):Description("Pong.")

command("whois", function(args, message)
    local member
    if message.mentionedUsers and message.mentionedUsers.first then
        member = assert(message.guild:getMember(message.mentionedUsers.first), "something went wrong")
    elseif args[2] and tonumber(args[2]) ~= nil then
        member = assert(message.guild:getMember(args[2]), "something went wrong")
    else
        member = message.member
    end

    local roleNames = {}
    member.roles:forEach(function(role)
        table.insert(roleNames, role.mentionString)
    end)

    message:reply {
        embed = {
            color = config.colours.default,
            fields = {
                {
                    name = "Name",
                    value = member.name,
                    inline = true
                },
                {
                    name = "Discriminator",
                    value = member.user.discriminator,
                    inline = true
                },
                {
                    name = "ID",
                    value = member.id,
                    inline = true
                },
                {
                    name = "Status",
                    value = member.status,
                    inline = true
                },
                {
                    name = "Joined Guild",
                    value = (member.joinedAt and utilities.createTimestamp(discordia.Date().fromISO(member.joinedAt):toSeconds(), enums.RELATIVE) or "?"),
                    inline = true
                },
                {
                    name = "Joined Discord",
                    value = utilities.createTimestamp(discordia.Date().fromSnowflake(member.id):toSeconds(), enums.RELATIVE),
                    inline = true
                },
                {
                    name = "Roles",
                    value = table.concat(roleNames, ", ")
                }
            }
        }
    }
end):Category("Fun Commands"):Description("Get info about a user.")

for k, v in pairs(OVERLAY_MAP) do
    command(k, function(args, message)
        local avatar = assert(message.author.avatarURL, "could not find your avatar.")
        local res, body = http.request("GET", F("https://some-random-api.ml/canvas/%s?avatar=%s", v, avatar))
        assert(res.code == 200 and body ~= nil, "could not load the overlay image.")

        message:reply {
            file = { "img.png", body }
        }
    end):Category("Fun Commands"):Description(F("Apply a %s overlay to your avatar.", v))
end