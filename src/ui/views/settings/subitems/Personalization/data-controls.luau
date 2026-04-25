--// Publish
return function(cascade, app, window, root)
	local storage = require("@modules/storage")

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
					Value = storage.getUiFlag("AutoSaveConfig", true),
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
				local ok = storage.SaveJson("state.json", {})
				app:Notification({
					App = "Comet",
					Title = ok and "Saved config deleted" or "Delete failed",
					Subtitle = ok and "All persisted configuration removed." or "Unable to delete configuration.",
					Duration = 4,
				})
			end,
		})
	end
end
