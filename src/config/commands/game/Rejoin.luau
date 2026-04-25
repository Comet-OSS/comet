--// Imports
local utility = require("@core/utility")

--// Publish
return function(self)
	return {
		Title = "Rejoin",
		Icon = "",
		OnTrigger = function()
			utility.TeleportClient()
		end,
	}
end
