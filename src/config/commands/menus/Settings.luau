return function(self)
	--// Imports
	local keybinds = require("@config/keybinds")

	--// Variables
	local window = self.Views.Settings
	
	--// Publish
	return {
		Shortcut = keybinds.Settings.Open,
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
end
