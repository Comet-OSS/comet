--// Imports
local utility = require("@core/utility")

--// Publish
return function(_app)
	return {
		Title = "Reset",
		Icon = "",
		OnTrigger = function()
			local hum = utility.GetHumanoid(utility.GetPlayer())
			if hum then
				hum.Health = 0
			end
		end,
	}
end
