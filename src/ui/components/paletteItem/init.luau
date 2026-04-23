--!native

--// Imports
local signal = require("@packages/signal")

--// Types
type Signal<T...> = signal.Signal<T...>

export type Properties = {
	Keys: { string | Enum.KeyCode },
	Sink: boolean?,
	OnTriggered: ((gameProcessed: boolean) -> ())?,
	OnReleased: (() -> ())?,
}

--// Init
local cascade = require("@packages/cascade")
local ui = require("@self/ui")
local keybind = require("@modules/keybind")

local binder = cascade.Binder

return function(self, properties: any)
	properties = properties or {}
	properties.IsSelected = properties.IsSelected == true

	local structures = ui(self, properties)

	local object = binder.Wrap(properties, {
		Title = function(val: string)
			structures.Title.Text = val
			structures.Body.SearchIndex = val
		end,
		Icon = function(val: string)
			if val and val ~= "" then
				structures.Icon.Image = val
				structures.Icon.Visible = true
			else
				structures.Icon.Visible = false
			end
		end,
		Shortcut = function(val: any)
			local function formatShortcut(s)
				local function fmtOne(v)
					if typeof(v) == "EnumItem" or type(v) == "string" then
						if keybind and keybind.enumToPhysical then
							return keybind.enumToPhysical(v)
						end
						return tostring(v)
					end

					return tostring(v)
				end

				if type(s) == "table" then
					local parts = {}
					for _, v in ipairs(s) do
						table.insert(parts, fmtOne(v))
					end
					return table.concat(parts, " + ")
				else
					return fmtOne(s)
				end
			end

			if val and val.Value ~= nil then -- ValueState
				local current = val.Value
				structures.Shortcut.Text = current and formatShortcut(current) or ""
				structures.Shortcut.Visible = (current ~= nil and current ~= "")

				if val.Changed and type(val.Changed.Connect) == "function" then
					val.Changed:Connect(function(newVal)
						structures.Shortcut.Text = newVal and formatShortcut(newVal) or ""
						structures.Shortcut.Visible = (newVal ~= nil and newVal ~= "")
					end)
				end
			else
				local text = if val ~= nil then formatShortcut(val) else ""
				structures.Shortcut.Text = text
				structures.Shortcut.Visible = (text ~= nil and text ~= "")
			end
		end,
		IsSelected = function(val)
			local commandItemTheme = self.Theme.Controls.CommandItem
			local selection = self.Theme.Controls.Selection
			local selectedText = self.Theme.Text.SelectionPrimary

			if val then
				structures.Body.BackgroundColor3 = selection[1].Value
				structures.Body.BackgroundTransparency = selection[2].Value
				structures.Title.TextColor3 = selectedText[1].Value
				structures.Title.TextTransparency = selectedText[2].Value
				structures.Icon.ImageColor3 = selectedText[1].Value
				structures.Icon.ImageTransparency = selectedText[2].Value
				structures.Shortcut.TextColor3 = selectedText[1].Value
				structures.Shortcut.TextTransparency = selectedText[2].Value
			else
				structures.Body.BackgroundColor3 = commandItemTheme.Background[1].Value
				structures.Body.BackgroundTransparency = commandItemTheme.Background[2].Value
				structures.Title.TextColor3 = commandItemTheme.TextDefault[1].Value
				structures.Title.TextTransparency = commandItemTheme.TextDefault[2].Value
				structures.Icon.ImageColor3 = commandItemTheme.IconDefault[1].Value
				structures.Icon.ImageTransparency = commandItemTheme.IconDefault[2].Value
				structures.Shortcut.TextColor3 = self.Theme.Text.Secondary[1].Value
				structures.Shortcut.TextTransparency = self.Theme.Text.Secondary[2].Value
			end
		end,
	}, structures.Body)

	object.Type = "PaletteItem"
	object.Structures = structures

	structures.Body.Activated:Connect(function()
		if object.OnTrigger then
			pcall(object.OnTrigger)
		end
	end)

	structures.Body.MouseEnter:Connect(function()
		if object.OnFocused then
			pcall(object.OnFocused)
		end
	end)

	binder.Apply(properties, object, {})

	return object
end