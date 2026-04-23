--// Imports
local cascade, _types = require("@packages/cascade"), require("@packages/cascade/types")
local ui = require("@self/ui")

--// References
local binder = cascade.Binder

--// Types
type CommandPalette = {
	Visible: boolean,
	Focused: boolean,
	Text: string,
}

--// Publish
return function(self, properties: any)
	properties = properties or {}
	properties.Focused = properties.Focused ~= nil and properties.Focused or false

	--// UI
	local structures, theme = ui(self, properties)
	local object = binder.Wrap(properties, {
		Visible = function(val: boolean)
			structures.Body.Visible = val
		end,
		Focused = function(val: boolean)
			if val then
				structures.InputStroke.Color = theme.InputBorderFocused[1].Value
				structures.InputStroke.Transparency = theme.InputBorderFocused[2].Value
			else
				structures.InputStroke.Color = theme.InputBorderReady[1].Value
				structures.InputStroke.Transparency = theme.InputBorderReady[2].Value
			end
		end,
		Text = function(val: string)
			structures.SearchInput.Text = val
		end,
	}, structures.Body)

	structures.SearchInput.Focused:Connect(function()
		object.Focused = true
	end)

	structures.SearchInput.FocusLost:Connect(function()
		object.Focused = false
	end)

	object.Type = "CommandPalette"
	object.Theme = self.Theme
	object.Structures = structures
	object.__container = structures.ResultsContainer

	binder.Apply(properties, object)

	return object :: CommandPalette
end
