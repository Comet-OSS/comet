local _types = require("@packages/Cascade/types")

return function(app: _types.App)
	--// Imports
	local cascade = require("@packages/Cascade")

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

	-- Build groups
	do
		local function tab(root, tabName, tabInfo)
			local tab = root:Tab({
				Selected = tabInfo.Selected,
				Title = tabName,
				Icon = tabInfo.Icon,
			})

			tabInfo.Build(cascade, app, window, tab)
		end

		for group, tabs in subitems do
			if tabs.Build then
				tab(window, group, tabs)
			else
				local section = window:Section({
					Title = group,
					Disclosure = false,
				})

				for tabName, tabInfo in tabs do
					tab(section, tabName, tabInfo)
				end
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
