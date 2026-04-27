--// Module
local utility = {}

--// State
local toggledFunctions = {}

--// References
local rawDatamodel = getrawmetatable and getrawmetatable(game)
	or {
		__index = function(self, Index)
			return self[Index]
		end,

		__newindex = function(self, Index, Value)
			self[Index] = Value
		end,
	}

utility.index = rawDatamodel.__index
utility.newindex = rawDatamodel.__newindex

utility._GetService = utility.index(game, "GetService")
utility.GetChildren = utility.index(game, "GetChildren")
utility.GetDescendants = utility.index(game, "GetDescendants")
utility.FindFirstChild = utility.index(game, "FindFirstChild")
utility.FindFirstChildOfClass = utility.index(game, "FindFirstChildOfClass")
utility.WaitForChild = utility.index(game, "WaitForChild")

--// Public Methods
function utility.safePath(root: {[any]: any}, path: string, makeMissingDirs: boolean?): any
	for key in path:gmatch("[^.]+") do
		if type(root) ~= "table" then
			return nil
		end

		if root[key] == nil then
			if makeMissingDirs then
				root[key] = {}
			else
				return nil
			end
		end
		
		root = root[key]
	end

	return root
end

function utility.printD(...)
	if _P.target == "Debug" then
		print(...)
	end
end

function utility.cbD(f)
	if _P.target == "Debug" then
		return f()
	end
	
	return nil
end

function utility.mergeArrays<T>(...: {T}): {T}
	local result = {}

	for _, arr in { ... } do
		table.move(arr, 1, #arr, #result + 1, result)
	end

	return result
end

function utility.GetService(service: string): Instance
	local result = utility._GetService(game, service)

	return cloneref and cloneref(result) or result
end

function utility.GetPlayer(): Player?
	local success, result = pcall(function()
		return utility.GetService("Players")
	end)

	return success and utility.index(result, "LocalPlayer")
end

function utility.GetCharacter(player: Player?): Model?
	local success, result = pcall(function()
		return player and utility.index(player, "Character")
	end)

	return success and result
end

function utility.GetHumanoid(player: Player?): Humanoid?
	local success, result = pcall(function()
		local character = utility.GetCharacter(player)

		return character and utility.FindFirstChildOfClass(character, "Humanoid")
	end)

	return success and result
end

function utility.TeleportClient(placeId: number?, jobId: string?)
	placeId = placeId or game.PlaceId
	jobId = jobId or game.JobId

	local player = utility.GetPlayer()
	local teleportService = utility.GetService("TeleportService") :: TeleportService

	if placeId and jobId then
		teleportService:TeleportToPlaceInstance(placeId, jobId, player)
	end
end

function utility.BlankFunction(tbl: { [any]: any }, method: string, override: (...any) -> any, value: boolean)
	assert(typeof(tbl) == "table", "First argument must be a table")
	assert(typeof(method) == "string", "Second argument must be the method name")

	if value == false then
		if not toggledFunctions[tbl] then
			toggledFunctions[tbl] = {}
		end

		if not toggledFunctions[tbl][method] then
			toggledFunctions[tbl][method] = tbl[method]
		end

		tbl[method] = override
	else
		if toggledFunctions[tbl] and toggledFunctions[tbl][method] then
			tbl[method] = toggledFunctions[tbl][method]
			toggledFunctions[tbl][method] = nil
		end
	end
end

function utility.ProcessTable(tbl: { any }, fn: (any) -> any, concatStr: string?)
	local result = {}
	for i, v in ipairs(tbl) do
		table.insert(result, fn(v))
	end

	if concatStr then
		return table.concat(result, concatStr)
	end

	return result
end


return utility
