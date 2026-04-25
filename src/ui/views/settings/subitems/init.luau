--// Imports
local cascade = require("@packages/cascade")

--// Publish
return {
    ["Personalization"] = {
        Appearance = {
            Selected = true,
            Icon = cascade.Symbols.paintpalette,
            Build = require("@self/Personalization/appearance"),
        },
        ["Data Controls"] = {
            Icon = cascade.Symbols.documentBadgeGearshape,
            Build = require("@self/Personalization/data-controls"),
        },
    },
    ["System"] = {
        Shortcuts = {
            Icon = cascade.Symbols.command,
            Build = require("@self/System/shortcuts"),
        },
        Startup = {
            Icon = cascade.Symbols.power,
            Build = require("@self/System/startup"),
        },
    },
}