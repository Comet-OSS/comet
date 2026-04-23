--// Publish
return function(app)
	--// Imports
	local views = require("@ui/views")
	local keybinds = require("@config/keybinds")

	--// Variables
	local window = views.settings(app)
	
	window.Visible = false

	local data = {
		Title = "Settings",
		Icon = "",
		OnTrigger = function()
			if not window.Visible then
				window.Visible = true
			else
				window.Minimized = not window.Minimized
			end
		end,
	}

	data.Shortcut = keybinds.Settings.Open

	return data
end
