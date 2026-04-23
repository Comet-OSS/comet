--!native
--!strict

--// Imports
local utility = require("@core/utility")

--// Types
export type Command = {
	Title: string,
	Icon: string?,
	OnTrigger: () -> ()
}

--// State
local registry: { Command } = {}

--// Module
local Commands = {}

function Commands.Register(command: Command)
	table.insert(registry, command)
end

function Commands.GetCommands(): { Command }
	return registry
end

function Commands.Initialize()
	Commands.Register({
		Title = "Rejoin",
		Icon = "",
		OnTrigger = function()
			utility.TeleportClient()
		end,
	})

	Commands.Register({
		Title = "Copy Job ID",
		Icon = "",
		OnTrigger = function()
			if setclipboard then
				setclipboard(game.JobId)
			end
		end,
	})

	Commands.Register({
		Title = "Refresh",
		Icon = "",
		OnTrigger = function()
			local player = utility.GetPlayer()
			if not player then return end

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
	})

	Commands.Register({
		Title = "Reset",
		Icon = "",
		OnTrigger = function()
			local hum = utility.GetHumanoid(utility.GetPlayer())
			if hum then
				hum.Health = 0
			end
		end,
	})

	Commands.Register({
		Title = "Instance Search",
		Icon = "",
		Shortcut = "Ctrl + P",
		OnTrigger = function()
		end,
	})

	Commands.Register({
		Title = "Command Palette",
		Icon = "",
		Shortcut = "Ctrl + Shift + P",
		OnTrigger = function()
		end,
	})
end

return Commands
