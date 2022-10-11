client:on("messageCreate", function(message)
	if message.author.bot or not next(message.guild) then return end

	local args = message.content:split(" ")

	if args[1] and args[1]:sub(1, #prefix) == prefix then
		local command = commands.Get(args[1]:sub((#prefix + 1), #args[1]))

		if command then
			local _, err = pcall(function()
				if args[2] then
					local commandChild = command:GetChild(args[2])
					if commandChild then
						commandChild:Evaluate(args, message)

						return
					end
				end

				command:Evaluate(args, message)
			end)

			log(3, F("Command %s entered by %s", command:Name(), message.author.tag))

			if err ~= nil then
				local fErr = err:match(":%d+:(.+)")

				if fErr ~= nil and #fErr > 1 then
					log(1, err)

					embed(F("%s %s", message.author.mentionString, fErr), message)
				end
			end
		end
	end
end)