command("help", function(args, message)
	local commandData = {}
	for name, command in pairs(commands.GetAll()) do
		local category = command:Category()

		if category and #category > 0 then
			if not commandData[category] then
				commandData[category] = {}
			end

			table.insert(commandData[category], F("> %s%s", prefix, name))
			local children = command:GetChildren()
			if children then
				for childName, child in pairs(children) do
					table.insert(commandData[category], F("> ↳ %s", childName))
				end
			end
		end
	end

	local response = {
		title = "List of available commands",
		color = config.colours.default,
		description = ""
	}

	for category, commands in pairs(commandData) do
		response.description =  F("%s\n\n__%s__\n%s", response.description, category, table.concat(commands, "\n"))
	end

	message:reply {
		embed = response
	}
end)