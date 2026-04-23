--// Publish
return function(cascade, app, window, root)
	local storage = require("@modules/storage")
	local themes = require("@themes")

	do -- Appearance
		local form = root:PageSection({ Title = "Appearance" }):Form()

		do -- Dark mode
			local row = form:TitledRow({
				Title = "Dark mode",
				Subtitle = "An application appearance setting that uses a dark color palette to provide a comfortable viewing experience tailored for low-light environments.",
			})

			storage.uiFlag("WindowDarkMode", row:Right():Toggle({
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

			storage.uiFlag("WindowAccent", row:Right():PopUpButton({
				Value = accentValue,
				Options = flattenedAccents,
				ValueChanged = function(self, value: number)
					app.Accent = cascade.Accents[self.Options[value]]
				end,
			}))
		end
	end

	do -- Input
		local form = root:PageSection({ Title = "Input" }):Form()


		do -- Searching
			local row = form:TitledRow({
				Title = "Searchable",
				Subtitle = "Allows users to search for content in a page with a search-field in the titlebar.",
			})

			storage.uiFlag("WindowSearchable", row:Right():Toggle({
				Value = window.Searching,
				ValueChanged = function(self, value: boolean)
					window.Searching = value
				end,
			}))
		end

		do -- Draggable
			local row = form:TitledRow({
				Title = "Draggable",
				Subtitle = "Allows users to move the window with a mouse or touch device.",
			})

			storage.uiFlag("WindowDraggable", row:Right():Toggle({
				Value = window.Draggable,
				ValueChanged = function(self, value: boolean)
					window.Draggable = value
				end,
			}))
		end

		do -- Resizable
			local row = form:TitledRow({
				Title = "Resizable",
				Subtitle = "Allows users to resize the window with a mouse or touch device.",
			})

			storage.uiFlag("WindowResizable", row:Right():Toggle({
				Value = window.Resizable,
				ValueChanged = function(self, value: boolean)
					window.Resizable = value
				end,
			}))
		end
	end

	do -- Effects
		local form = root:PageSection({
			Title = "Effects",
			Subtitle = "These effects may be resource intensive across different systems.",
		}):Form()

		do -- Dropshadow
			local row = form:TitledRow({
				Title = "Dropshadow",
				Subtitle = "Enables a dropshadow effect on the window.",
			})

			storage.uiFlag("WindowDropshadow", row:Right():Toggle({
				Value = window.Dropshadow,
				ValueChanged = function(self, value: boolean)
					window.Dropshadow = value
				end,
			}))
		end

		--[[ do -- UI Blur
			local row = form:TitledRow({
				Title = "Background blur",
				Subtitle = "Enables a UI background blur effect on the window.",
			})

			storage.uiFlag("WindowBlur", row:Right():Toggle({
				Value = window.UIBlur,
				ValueChanged = function(self, value: boolean)
					window.UIBlur = value
				end,
			}))
		end ]]
	end
end
