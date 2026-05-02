--// Imports
local utility = require("@core/utility")
local services = require("@modules/services")

--// Publish
return function(self)
	return {
		Title = "Noclip",
		Icon = "",
		Invocators = {
			{
				Title = "Enable",
				OnTrigger = function(self, super)
					super._enabled = true

					super._originalProperties = super._originalProperties or {}

					if super._connection then
						super._connection:Disconnect()
						super._connection = nil
					end

					local player = utility.GetPlayer()
					if not player then
						return
					end

					local character = utility.GetCharacter(player)
					if not character then
						return
					end

					super._connection = services.RunService.Stepped:Connect(function()
						for _, v in pairs(character:GetChildren()) do
							if v:IsA("BasePart") then
								if not super._originalProperties[v] then
									super._originalProperties[v] = v.CanCollide
								end

								v.CanCollide = false
							end
						end
					end)
				end,
			},
			{
				Title = "Disable",
				OnTrigger = function(self, super)
					if not super._originalProperties then
						return
					end
 
					if super._connection then
						super._connection:Disconnect()
						super._connection = nil
					end

					super._enabled = false

					local player = utility.GetPlayer()
					if not player then
						return
					end

					local character = utility.GetCharacter(player)
					if not character then
						return
					end

					for _, v in pairs(character:GetChildren()) do
						if v:IsA("BasePart") then
							if super._originalProperties[v] then
								v.CanCollide = super._originalProperties[v]
							end
						end
					end

					super._originalProperties = {}
				end,
			},
		},
	}
end
