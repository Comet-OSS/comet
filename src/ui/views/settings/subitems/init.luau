--// Imports
local cascade = require("@packages/cascade")

--// Publish
return {
    ["Personalization"] = {
        Appearance = {
            Selected = true,
            Icon = cascade.Symbols.paintpalette,
            Build = require("@self/General/appearance"),
        },
    },
    ["System"] = {
        Shortcuts = {
            Icon = cascade.Symbols.command,
            Build = require("@self/General/shortcuts"),
        },
    },
}