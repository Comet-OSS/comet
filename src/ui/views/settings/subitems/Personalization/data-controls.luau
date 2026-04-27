--// Publish
return function(cascade, app, window, root)
	local storage = require("@modules/storage")
	local utility = require("@core/utility")
	local statusCodes = require("@config/statusCodes")

	local section = root:PageSection({ Title = "Data Controls" })

	do -- Autosaving
		local form = section:Form()

		do
			local row = form:TitledRow({
				Title = "Auto-save state",
				Subtitle = "Automatically save config changes to your state file.",
			})

			storage.uiFlag(
				"AutoSaveConfig",
				row:Right():Toggle({
					Value = true,
				})
			)
		end
	end

	do -- Manual save and delete
		local form = section:Form()

		local row = form:TitledRow({
			Title = "Data controls",
			Subtitle = "Manage your config-state data.",
		})

		local right = row:Right()

		right:Button({
			Label = "Delete state",
			State = "Destructive",
			Pushed = function()
				local function result(success, sub)
					app:Notification({
						App = "Comet",
						Title = success and "Save state cleared" or "Delete failed",
						Subtitle = success and "All persisted configuration removed." or sub,
						Duration = 4,
					})
				end

				local path = utility.safePath(_P, "shared.CleanPersistance")

				if not path then
					result(path, statusCodes._GeneralMessages.MissingInternalPath)

					return
				else
					local success = path()

					result(success, "Failed to clear storage persistance")
				end
			end,
		})
	end
end
