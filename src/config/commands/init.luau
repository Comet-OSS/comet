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

--// Publish
return function(self)
    for groupName, group in pairs(commands) do
        for _, commandModule in pairs(group) do
            local command = commandModule
            if typeof(commandModule) == "function" then
                local success, result = pcall(commandModule, self)
                if success then
                    command = result
                else
                    self.App:Notification({
                        App = "Comet",

                        Title = "Command Registration",
                        Subtitle = `There was an error registering a command, we can't retrieve any info.`,
                        Icon = cascade.Symbols.command,

                        Duration = 5,
                    })

                    continue
                end
            end

            if type(command) == "table" then
                command.Group = groupName
            end

            commandFramework.Register(command)
        end
    end
end
