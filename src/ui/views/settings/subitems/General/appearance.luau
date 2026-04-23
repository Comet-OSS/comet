--// Publish
return function(cascade, app, window, root)
	local storage = require("@modules/storage")
	local themes = require("@themes")

	do -- Appearance
		local form = root:PageSection({ Title = "Color scheme" }):Form()

		do -- Dark mode
			local row = form:TitledRow({
				Title = "Dark mode",
				Subtitle = "An application appearance setting that uses a dark color palette to provide a comfortable viewing experience tailored for low-light environments.",
			})

			storage.uiFlag(row.Title, row:Right():Toggle({
				Value = app.Theme._id == "Dark",
				ValueChanged = function(self, value: boolean)
					app.Theme = value and themes.Dark or themes.Light
				end,
			}))
		end

		do -- Application accent
			local row = form:TitledRow({
				Title = "Application accent",
				Subtitle = "An application appearance setting that allows you to change the overall accent of the application.",
			})

			local flattenedAccents = {}
			for accent, _ in pairs(cascade.Accents) do
				table.insert(flattenedAccents, accent)
			end

			local accentValue = table.find(flattenedAccents, (app.Accent and app.Accent._id) or "Blue")

			storage.uiFlag(row.Title, row:Right():PopUpButton({
				Value = accentValue,
				Options = flattenedAccents,
				ValueChanged = function(self, value: number)
					app.Accent = cascade.Accents[self.Options[value]]
				end,
			}))
		end
	end
end
