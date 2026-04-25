--// Imports
local valueState = require("@modules/valueState")

--// Publish
return { -- Bindings, Metadata
	Palette = {
		Search = valueState.new({ "Control", "P" }),
		Command = valueState.new({ "Control", "Shift", "P" }),
	},
	Settings = {
		Open = valueState.new({ "Control", "Comma" }),
	},

	_META = {
		--[[
			- Top level tables are seperate pagesections. Define _Subtitle for the subtitle of it, the key is the title.
			- In each pagesection you must define a table for a form, define a new table for a new form. You must define at least one form.
			- Each key in a form is a row. The key is the titledRow title. The value is the subtitle.
		]]
		Palette = {
			_Subtitle = "Palette related shortcuts",

			[1] = {
				Search = "Search for game instances quickly",
				Command = "Use a quick command",
			},
		},
		Settings = {
			_Subtitle = "Settings window shortcuts",

			[1] = {
				Open = "Open the Comet settings window",
			},
		},
	},
}
