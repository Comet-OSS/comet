--!native
--!strict

--// Imports
local services = require("@modules/services")

--// Constants
local ROOT_FOLDER = ".comet"
local STATE_FILE = "state.json"

--// Variables
local HttpService = services.HttpService

--// Module
local storage = {}

local function readState(): { [string]: any }
	local state = storage.LoadJson(STATE_FILE, {})
	if type(state) == "table" then
		return state
	end
	return {}
end

local function writeState(state: { [string]: any }): boolean
	return storage.SaveJson(STATE_FILE, state)
end

local function normalizeStateKeys(stateValue: any): { string }
	if type(stateValue) == "string" then
		return { stateValue }
	end
	if type(stateValue) == "table" then
		return stateValue
	end
	return { "Value" }
end

local function ensureRoot()
	if not makefolder or not isfolder then
		return false
	end

	if not isfolder(ROOT_FOLDER) then
		pcall(makefolder, ROOT_FOLDER)
	end

	return true
end

function storage.LoadJson(fileName: string, fallback: any): any
	if not readfile or not isfile then
		return fallback
	end

	if not ensureRoot() then
		return fallback
	end

	local path = (`{ROOT_FOLDER}/{fileName}`)
	if not isfile(path) then
		return fallback
	end

	local okRead, raw = pcall(readfile, path)
	if not okRead or type(raw) ~= "string" or raw == "" then
		return fallback
	end

	local okDecode, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if okDecode then
		return decoded
	end

	return fallback
end

function storage.SaveJson(fileName: string, payload: any): boolean
	if not writefile then
		return false
	end

	if not ensureRoot() then
		return false
	end

	local okEncode, encoded = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not okEncode or type(encoded) ~= "string" then
		return false
	end

	local path = (`{ROOT_FOLDER}/{fileName}`)
	local okWrite = pcall(writefile, path, encoded)
	return okWrite
end

function storage.getUiFlag(flag: string, fallback: any): any
	local state = readState()
	local flags = state.UiFlags
	if type(flags) ~= "table" then
		return fallback
	end

	local value = flags[flag]
	if value == nil then
		return fallback
	end

	return value
end

function storage.uiFlag(flag: string, component: any, stateValue: any?): any
	if type(component) ~= "table" then
		return component
	end

	local keys = normalizeStateKeys(stateValue)
	local persisted = storage.getUiFlag(flag, nil)

	if #keys == 1 then
		local key = keys[1]
		if persisted ~= nil then
			component[key] = persisted
		end
	else
		if type(persisted) == "table" then
			for _, key in ipairs(keys) do
				if persisted[key] ~= nil then
					component[key] = persisted[key]
				end
			end
		end
	end

	for _, key in ipairs(keys) do
		local changedKey = (`{key}Changed`)
		local existingChanged = component[changedKey]

		component[changedKey] = function(self: any, ...)
			if existingChanged then
				existingChanged(self, ...)
			end

			local state = readState()
			local flags = state.UiFlags
			if type(flags) ~= "table" then
				flags = {}
				state.UiFlags = flags
			end

			if #keys == 1 then
				flags[flag] = component[keys[1]]
			else
				local data = {}
				for _, stateKey in ipairs(keys) do
					data[stateKey] = component[stateKey]
				end
				flags[flag] = data
			end

			writeState(state)
		end
	end

	return component
end

return storage
