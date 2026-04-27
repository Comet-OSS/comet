--// Publish
return function(cascade, app, window, root)
	--// Imports
	local utility = require("@core/utility")
	local storage = require("@modules/storage")
	local themes = require("@themes")

	--// Variables
	local uiBehavior = utility.safePath(_P.shared, "UiBehavior")

	do -- Menu Navigation
		local section = root:PageSection({ Title = "Menu Navigation" })

		do -- Navigation hold
			local form = section:Form()

			-- Hold delay
			do
				local row = form:TitledRow({
					Title = "Nav Auto-scroll Delay",
					Subtitle = "How long it takes to trigger auto-scroll",
				})

				storage.uiFlag(
					row.Title,
					row:Right():Stepper({
						Minimum = 0.1,
						Maximum = 1,
						Step = 0.01,
						Fielded = true,
						Value = uiBehavior.MenuNavHoldDelay,
						ValueChanged = function(self, value: number)
							uiBehavior.MenuNavHoldDelay = value
						end,
					})
				)
			end

			-- Acceleration
			do
				local row = form:TitledRow({
					Title = "Nav Auto-scroll Acceleration",
					Subtitle = "Acceleration increase per second",
				})

				storage.uiFlag(
					row.Title,
					row:Right():Stepper({
						Minimum = 0.01,
						Maximum = 0.1,
						Step = 0.01,
						Fielded = true,
						Value = uiBehavior.MenuNavRepeatAccelPerSecond,
						ValueChanged = function(self, value: number)
							uiBehavior.MenuNavRepeatAccelPerSecond = value
						end,
					})
				)
			end
		end
	end
end
