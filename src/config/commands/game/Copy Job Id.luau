--// Publish
return function(self)
	return {
		Title = "Copy Job ID",
		Icon = "",
		OnTrigger = function()
			if setclipboard then
				setclipboard(game.JobId)
			else
				return {
					status = 400,
					message = "The executor does not have `setclipboard`"
				}
			end
		end,
	}
end
