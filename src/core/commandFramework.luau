--!native

--// Imports
local cascade = require("@packages/cascade")

local statusCodes = require("@config/statusCodes")

--// Types
export type Command = {
	Title: string,
	Icon: string?,
	OnTrigger: () -> (),
}

--// State
local registry: { Command } = {}

--// Module
local Commands = {}

function Commands.Register(command: Command, super: any?)
	if typeof(command) == "function" then
		error(
			"Commands.Register expected a command table, received a function. Make sure command modules return a table (or a function that returns a table) and that caller invoked it with app."
		)
	end

	if command == nil then
		error("Commands.Register received nil command")
	end

	if typeof(command.OnTrigger) ~= "function" then
		warn(
			("Command '%s' has invalid OnTrigger (type=%s)"):format(tostring(command.Title), typeof(command.OnTrigger))
		)
	end

	if super then
		command.Super = super
	end

	local oldOnTrigger = command.OnTrigger

	command.OnTrigger = function(...)
		local success, result = pcall(oldOnTrigger, ...)
		local codeLabel = (type(result) == "table" and result.status)
				and (statusCodes.OnTrigger[result.status] or tostring(result.status))
			or nil

		local app = _P and _P.shared and (_P.shared.App or _P.shared.app)

		if not success then
			if app and app.Notification then
				app:Notification({
					App = "Comet",
					AppIcon = "rbxassetid://109261725124277",

					Icon = cascade.Symbols.command,
					Title = `{command.Title}`,
					Subtitle = `Error running command: {tostring(result)}`,

					Duration = 5,
				})
			end
		elseif result and result.message then
			if app and app.Notification then
				app:Notification({
					App = "Comet",
					AppIcon = "rbxassetid://109261725124277",

					Icon = cascade.Symbols.command,
					Title = `{command.Title}`,
					Subtitle = codeLabel and (codeLabel .. ": " .. (result.message or "Error"))
						or (result.message or "Error running command"),

					Duration = 5,
				})
			end
		end

		return result
	end

	table.insert(registry, command)
end

function Commands.GetCommands(): { Command }
	return registry
end

return Commands
