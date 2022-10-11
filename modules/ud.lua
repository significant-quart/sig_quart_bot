local utilities = require("utilities")
local http = require("coro-http")
local json = require("json")
local querystring = require("querystring")


command("ud", function(args, message)
    assert(args[2] ~= nil, "")

    local term = assert(querystring.urlencode(utilities.returnCommandInput(args)), "could not parse term.")

    local res, body = http.request("GET", F("https://mashape-community-urban-dictionary.p.rapidapi.com/define?term=%s", term), { { "x-rapidapi-host", "mashape-community-urban-dictionary.p.rapidapi.com" }, { "x-rapidapi-key", config.keys.rapid }  })
    assert(res.code == 200, "API request failed, are you sure the term provided is valid?")
    body = assert(json.decode(body), "could not parse response from the server.")

    body = body.list
    table.sort(body, function(a, b)
        return (a.thumbs_up - a.thumbs_down) > (b.thumbs_up - b.thumbs_down)
    end)

    local data = body[1]
    assert(data ~= nil and data.word and data.definition and data.permalink and data.thumbs_up and data.thumbs_down and data.example and data.author, "required details were missing from definition data.")
    data.example = data.example:split("\n")[1]

    local response = {
        title = F("Urban dictionary definition of ``%s``", data.word),
        description = F("[%s](%s)", data.definition, data.permalink),
        color = config.colours.default,
        fields = {
            {
                name = ":thumbsup:",
                value = tostring(data.thumbs_up),
                inline = true
            },
            {
                name = ":thumbsdown:",
                value = tostring(data.thumbs_down),
                inline = true
            },
            {
                name = "Example",
                value = data.example,
                inline = false
            },
            {
                name = "Author",
                value = data.author,
                inline = true
            }
        }
    }

    if data.sound_urls and data.sound_urls[1] then
        table.insert(response.fields, { 
            name = "Audio pronunciation",
            value = F("[%s](%s)", data.word, data.sound_urls[1]),
            inline = true
        })
    end

    message:reply {
        embed = response
    }
end):Category("Fun Commands"):Description("Query the Urban Dictionary.")