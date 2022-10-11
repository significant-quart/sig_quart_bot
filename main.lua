local discordia = require("discordia")
local JSON = require("json")
local fs = require("fs")
local commands = require("commands")


local F = string.format


local config = assert(fs.readFileSync("config.json"), "could not find or read config.json")
config = assert(JSON.decode(config), "could not parse config.json")


local client = discordia.Client {
	cacheAllMembers = true,
	dateTime = "%F @ %T",
	logLevel = (config.debug and 4 or 3)
}
local logger = discordia.Logger((config.debug and 4 or 3), "%F @ %T")


local function embed(description, response)
	local content = {
		description = description,
		color = config.colours.default
	}

	if response ~= nil then
		if response.username == nil then
			return response:reply {
				embed = content
			}
		else
			return response:send {
				embed = content
			}
		end
	end

	return content
end

local function log(level, ...)
	if config.debug == false and level > 2 then
		return
	end

	logger:log(level, ...)
end


do
	discordia.extensions()

	local moduleMetadata = setmetatable({
		require = require,

		discordia = discordia,
		client = client,

		config = config,

		commands = commands,
		command = commands.command,

		round = math.round,
		F = F,
		embed = embed,
		log = log,

		prefix = config.prefix
	}, {
		__index = _G
	})

	local function loadModule(name)
		local module = fs.readFileSync(F("./modules/%s.lua", name))

		loadstring(module, "@"..name, "t", moduleMetadata)()
	end

	for name, type in fs.scandirSync("./modules") do
		if type == "file" then
			local fileName = name:match("(.*)%.lua")
			if fileName then
				local _, err = pcall(loadModule, fileName)

				if err ~= nil then
					log(1, F("Error loading module %s [%s]", fileName, err))

					return
				else
					log(3, F("Loaded module: %s", fileName))
				end
			end
		end
	end

	client:run("Bot "..assert(fs.readFileSync("./.token"), "could not find or read .token"))
end