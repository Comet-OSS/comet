--!native
--!strict

--// Imports
local utility = require("@core/utility")

--// Types
export type InstanceItem = {
	Title: string,
	Instance: Instance?,
}

--// Module
local Instances = {}

function Instances.Search(query: string): { InstanceItem }
	local results: { InstanceItem } = {}
	local searchStr = query:lower()

	local function scan(parent: Instance, depth: number)
		if depth > 2 then
			return
		end
		for _, child in ipairs(utility.GetChildren(parent)) do
			if string.find(child.Name:lower(), searchStr, 1, true) then
				table.insert(
					results,
					{
						Title = child.Name .. " (" .. #utility.GetChildren(child) .. " children)",
						Instance = child,
					} :: InstanceItem
				)
			end
			scan(child, depth + 1)
		end
	end

	if searchStr ~= "" then
		pcall(function()
			scan(game, 1)
		end)
	end

	return results
end

return Instances
