--// Publish
return function(_app)
	return {
		Title = "Copy Job ID",
		Icon = "",
		OnTrigger = function()
			if setclipboard then
				setclipboard(game.JobId)
			end
		end,
	}
end
