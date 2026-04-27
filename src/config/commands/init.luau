--!native

--// Imports
local commandFramework = require("@core/commandFramework")
local cascade = require("@packages/cascade")

--// Variables
local commands = {
	Player = {
		require("@self/player/Refresh"),
		require("@self/player/Reset"),
	},
	Game = {
		require("@self/game/Rejoin"),
		require("@self/game/Copy Job Id"),
	},
	Menus = {
		require("@self/menus/Settings"),
	},
}

--// Private Methods
local function regErr(self, info: string?, invocator: boolean?)
	self.App:Notification({
		App = "Comet",

		Title = "Command Registration",
		Subtitle = `There was an error registering a {
            invocator and "invocator" 
            or "command"
        } {
            info and (": " .. info) 
            or ", we can't retrieve any info."
        }`,

		Icon = cascade.Symbols.command,
		Duration = 5,
	})
end

local function reg(self, commandModule, groupName, super)
	local command = commandModule

	if typeof(commandModule) == "function" then
		local success, result = pcall(commandModule, self)

		if success then
			command = result
		else
			return false
		end
	end

	if type(command) == "table" then
		command.Group = groupName
	end

    if super then
        command.Title = `{super.Title}: {command.Title}`
    end

    commandFramework.Register(command, super)

	return command
end

--// Publish
return function(self)
	for groupName, group in pairs(commands) do
		for _, commandModule in pairs(group) do
            local registeredCommand = reg(self, commandModule, groupName)

			if not registeredCommand then
				regErr(self)

				continue
			end

			if registeredCommand.Invocators then
                local invocType = type(registeredCommand.Invocators)
                
				if invocType ~= "table" then
					regErr(self, `invalid type, expected 'table', got {invocType}`, true)
					continue
				end

				for _, invocator in registeredCommand.Invocators do
                    reg(self, invocator, groupName, registeredCommand)
				end
			end
		end
	end
end
