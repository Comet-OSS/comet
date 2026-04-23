--!native

--// Imports
local commandFramework = require("@core/commandFramework")

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
    UI = {
        require("@self/ui/Settings"),
    },
}

--// Publish
return function(app)
    for _, group in pairs(commands) do
        for _, commandModule in pairs(group) do
            local command = commandModule
            if typeof(commandModule) == "function" then
                command = commandModule(app)
            end

            commandFramework.Register(command)
        end
    end
end
