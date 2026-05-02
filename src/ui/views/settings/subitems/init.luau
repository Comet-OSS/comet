--// Imports
local cascade = require("@packages/cascade")

--// Publish
return {
	{
		Title = "Personalization",
		Tabs = {
			{
				Title = "Appearance",
				Selected = true,
				Icon = cascade.Symbols.paintpalette,
				Build = require("@self/Personalization/appearance"),
			},
			{
				Title = "Accessibility",
				Icon = cascade.Symbols.figure,
				Build = require("@self/Personalization/accessibility"),
			},
			{
				Title = "Data Controls",
				Icon = cascade.Symbols.documentBadgeGearshape,
				Build = require("@self/Personalization/data-controls"),
			},
		},
	},
	{
		Title = "System",
		Tabs = {
			{
				Title = "About",
				Icon = cascade.Symbols.sparkles,
				Build = require("@self/System/about"),
			},
			{
				Title = "Changelog",
				Icon = cascade.Symbols.scroll,
				Build = require("@self/System/changelog"),
			},
			{
				Title = "Shortcuts",
				Icon = cascade.Symbols.command,
				Build = require("@self/System/shortcuts"),
			},
			{
				Title = "Startup",
				Icon = cascade.Symbols.power,
				Build = require("@self/System/startup"),
			},
		},
	},
}
