local cascade = require("@packages/cascade")

return {
	Appearance = {
		Window = {
            Selected = true,
			Icon = cascade.Symbols.sidebarLeft,
			Build = require("@self/Appearance/window"),
		},
	},
	General = {
		Shortcuts = {
			Icon = cascade.Symbols.command,
			Build = require("@self/General/shortcuts"),
		},
	},
}
