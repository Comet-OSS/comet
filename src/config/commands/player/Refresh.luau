--// Imports
local utility = require("@core/utility")

--// Publish
return function(_app)
	return {
		Title = "Refresh",
		Icon = "",
		OnTrigger = function()
			local player = utility.GetPlayer()
			if not player then
				return
			end

			local char = utility.GetCharacter(player)
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")

				if root then
					local currentPos = (root :: BasePart).CFrame
					local conn: RBXScriptConnection

					conn = player.CharacterAdded:Connect(function(newChar)
						if conn then
							conn:Disconnect()
						end

						local newRoot = newChar:WaitForChild("HumanoidRootPart", 5)
						if newRoot then
							(newRoot :: BasePart).CFrame = currentPos
						end
					end)
				end

				local hum = utility.GetHumanoid(player)
				if hum then
					hum.Health = 0
				end
			end
		end,
	}
end
