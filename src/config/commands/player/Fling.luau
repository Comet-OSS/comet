return function(self)
	--// Imports
	local utility = require("@core/utility")
	local services = require("@modules/services")
	local noclip = require("./Noclip")(self)

	--// Variables
	local noclipSuper = {}

	--// Private Methods
	local function invokeNoclip(title)
		for _, invocator in pairs(noclip.Invocators) do
			if invocator.Title == title then
				invocator.OnTrigger(invocator, noclipSuper)
				return
			end
		end
	end

	--// Publish
	return {
		Title = "Fling",
		Icon = "",
		Invocators = {
			{
				Title = "Enable",
				OnTrigger = function(self, super)
					if super._flinging then
						return
					end

					local player = utility.GetPlayer()
					if not player then
						return
					end

					local character = utility.GetCharacter(player)
					if not character then
						return
					end

					local root = character:FindFirstChild("HumanoidRootPart")
					if not root then
						return
					end

					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if not humanoid then
						return
					end

					invokeNoclip("Enable")

					for _, v in pairs(character:GetDescendants()) do
						if v:IsA("BasePart") then
							super._originalPhysProps = v.CustomPhysicalProperties
							v.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
						end
					end

					local bav = Instance.new("BodyAngularVelocity")
					bav.AngularVelocity = Vector3.new(0, 99999, 0)
					bav.MaxTorque = Vector3.new(0, math.huge, 0)
					bav.P = math.huge
					bav.Parent = root
					super._angularVelocity = bav

					for _, v in pairs(character:GetChildren()) do
						if v:IsA("BasePart") then
							v.CanCollide = false
							v.Massless = true
							v.AssemblyLinearVelocity = Vector3.zero
						end
					end

					super._flinging = true

					local phase = 0
					local elapsed = 0
					super._connection = services.RunService.Stepped:Connect(function(_, dt)
						if not super._flinging or not super._angularVelocity or not super._angularVelocity.Parent then
							return
						end
						elapsed += dt
						if phase == 0 and elapsed >= 0.2 then
							elapsed = 0
							phase = 1
							super._angularVelocity.AngularVelocity = Vector3.zero
						elseif phase == 1 and elapsed >= 0.1 then
							elapsed = 0
							phase = 0
							super._angularVelocity.AngularVelocity = Vector3.new(0, 99999, 0)
						end
					end)

					super._diedConnection = humanoid.Died:Connect(function()
						super._flinging = false
						if super._diedConnection then
							super._diedConnection:Disconnect()
							super._diedConnection = nil
						end
					end)
				end,
			},
			{
				Title = "Disable",
				OnTrigger = function(self, super)
					if not super._flinging then
						return
					end

					super._flinging = false
					invokeNoclip("Disable")

					if super._diedConnection then
						super._diedConnection:Disconnect()
						super._diedConnection = nil
					end

					if super._connection then
						super._connection:Disconnect()
						super._connection = nil
					end

					if super._angularVelocity and super._angularVelocity.Parent then
						super._angularVelocity.AngularVelocity = Vector3.zero
					end

					if super._angularVelocity then
						super._angularVelocity:Destroy()
						super._angularVelocity = nil
					end

					services.RunService.Heartbeat:Wait()

					local player = utility.GetPlayer()
					if not player then
						return
					end
					local character = utility.GetCharacter(player)

					if character then
						for _, v in pairs(character:GetDescendants()) do
							if v:IsA("BasePart") then
								v.Massless = false
								v.CustomPhysicalProperties = super._originalPhysProps
							end
						end
					end

					if character then
						for _, v in pairs(character:GetChildren()) do
							if v:IsA("BasePart") then
								v.AssemblyLinearVelocity = Vector3.zero
								v.AssemblyAngularVelocity = Vector3.zero
							end
						end
					end
				end,
			},
		},
	}
end
