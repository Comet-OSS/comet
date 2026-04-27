return function(self)
	--// Imports
	local utility = require("@core/utility")
	local keybinds = require("@config/keybinds")
	local statuscodes = require("@config/statusCodes")

	--// Variables
	local sharedTabs = utility.safePath(_P, "shared.Views.Settings.Tabs")
	local window = self.Views.Settings

	--// Initialize
	local command = {
		Shortcut = keybinds.Settings.Open,
		Title = "Settings",
		Icon = "",
		OnTrigger = function()
			if not window.Visible then
				window.Visible = true
			else
				window.Minimized = false
			end
		end,
		Invocators = {},
	}

	if sharedTabs then
		for tabName, tab in utility.safePath(_P, "shared.Views.Settings.Tabs") do
			command.Invocators[tabName] = {
				Title = tabName,
				OnTrigger = function(super)
					super.OnTrigger()
					tab.Selected = true
				end,
			}
		end
	else
		return {
			status = 401,
			message = statuscodes._GeneralMessages.MissingInternalPath,
		}
	end

	--// Publish
	return command
end
