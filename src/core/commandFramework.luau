--!native

--// Types
export type Command = {
	Title: string,
	Icon: string?,
	OnTrigger: () -> ()
}

--// State
local registry: { Command } = {}

--// Module
local Commands = {}

function Commands.Register(command: Command, super: any?)
	if typeof(command) == "function" then
		error("Commands.Register expected a command table, received a function. Make sure command modules return a table (or a function that returns a table) and that caller invoked it with app.")
	end

	if command == nil then
		error("Commands.Register received nil command")
	end

	if typeof(command.OnTrigger) ~= "function" then
		warn(("Command '%s' has invalid OnTrigger (type=%s)"):format(tostring(command.Title), typeof(command.OnTrigger)))
	end

	if super then
		command.Super = super
	end

	table.insert(registry, command)
end

function Commands.GetCommands(): { Command }
	return registry
end

return Commands
