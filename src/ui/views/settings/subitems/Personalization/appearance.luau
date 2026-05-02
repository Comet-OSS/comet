--// Imports
local _types = require("@packages/cascade/types")
local storage = require("@modules/storage")
local themes = require("@themes")

return function(cascade, app, window, root: _types.Page)
	--// UI
	do -- Theme
		local form = root:PageSection({ Title = "Theme" }):Form() :: _types.Form

		do -- Appearance
			local row = form:TitledRow({
				Title = "Appearance",
			}) :: _types.Row

			storage.uiFlag(
				row.Title,
				row:Right():RadioButtonGroup({
					Options = { "Dark", "Light" },
					Value = app.Theme._id == "Dark" and 1,
					ValueChanged = function(self, value: number)
						app.Theme = themes[self.Options[value]]
					end,
				})
			)
		end

		do -- Color
			local row = form:TitledRow({
				Title = "Color",
			}) :: _types.Row

			local flattenedAccents = {}
			for accent, _ in pairs(cascade.Accents) do
				table.insert(flattenedAccents, accent)
			end

			local accentValue = table.find(flattenedAccents, (app.Accent and app.Accent._id) or "Graphite")

			storage.uiFlag(
				row.Title,
				row:Right():PopUpButton({
					Value = accentValue,
					Options = flattenedAccents,
					ValueChanged = function(self, value: number)
						app.Accent = cascade.Accents[self.Options[value]]
					end,
				})
			)
		end
	end
end
