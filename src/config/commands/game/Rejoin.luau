--// Imports
local utility = require("@core/utility")

--// Publish
return function(_app)
	return {
		Title = "Rejoin",
		Icon = "",
		OnTrigger = function()
			utility.TeleportClient()
		end,
	}
end
