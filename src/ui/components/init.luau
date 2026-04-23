--// Imports
local cascade = require("@packages/cascade")

--// Variables
local components = {
    ["CommandPalette"] = require("@self/commandPalette"),
    ["PaletteItem"] = require("@self/paletteItem"),
    ["TitledRow"] = require("@self/titledRow"),
    ["KeybindLabel"] = require("@self/keybindLabel"),
    ["KeystrokeField"] = require("@self/Keystroke Field"),
}

--// Publish
return function()
    for name, component in pairs(components) do
        cascade.RegisterComponent(name, component)
    end
end
