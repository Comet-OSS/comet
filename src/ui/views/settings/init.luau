local _types = require("@packages/cascade/types")

return function(app: _types.App)
	--// Imports
	local cascade = require("@packages/cascade")

	local utility = require("@core/utility")

	local keybind = require("@modules/keybind")
	local services = require("@modules/services")

	local keybinds = require("@config/keybinds")

	local subitems = require("@self/subitems")

	--// References
	local UserInputService = services.UserInputService

	--// UI
	local window = app:Window({
		Title = "Settings",
		Size = UserInputService.TouchEnabled and UDim2.fromOffset(550, 325) or UDim2.fromOffset(850, 530),
		UIBlur = false,
	})

	-- Setup
	do
		window.Visible = false
		window.CanExit = false
	end

	-- Build groups
	do
		local function tab(root, tabInfo)
			local sharedTabs = utility.safePath(_P, "shared.Views.Settings.Tabs", true)
			local tab = root:Tab({
				Selected = tabInfo.Selected,
				Title = tabInfo.Title,
				Icon = tabInfo.Icon,
			})
			
			sharedTabs[tabInfo.Title] = tab
			tabInfo.Build(cascade, app, window, tab)
		end

		for _, group in subitems do
			if group.Tabs then
				local section = window:Section({
					Title = group.Title,
					Disclosure = false,
				})

				for _, tabInfo in group.Tabs do
					tab(section, tabInfo)
				end
			else
				tab(window, group)
			end
		end
	end

	--// Connections
	do
		local bindValue = keybinds.Settings.Open
		local bind = keybind.new(bindValue, { sink = true })

		bind:Connect(function(inputComplete: boolean)
			if inputComplete then
				if not window.Visible then
					window.Visible = true
				else
					window.Minimized = not window.Minimized
				end
			end
		end)
	end

	--// Publish
	return window
end
