--// Types
export type CommandUsageState = {
	UsageCounts: { [string]: number },
	Recent: { string },
	QueryPreferences: { [string]: { [string]: number } },
}

--// Module
local Search = {}

function Search.NormalizeRecent(rawRecent: any): { string }
	if type(rawRecent) ~= "table" then
		return {}
	end

	local normalized = {}
	local numeric = {}
	for key, value in pairs(rawRecent) do
		if type(value) == "string" then
			local numericKey = tonumber(key)
			if numericKey ~= nil then
				table.insert(numeric, { Index = numericKey, Value = value })
			end
		end
	end

	table.sort(numeric, function(a, b)
		return a.Index < b.Index
	end)
	for _, entry in ipairs(numeric) do
		table.insert(normalized, entry.Value)
	end

	if #normalized == 0 then
		for _, value in ipairs(rawRecent) do
			if type(value) == "string" then
				table.insert(normalized, value)
			end
		end
	end

	return normalized
end

function Search.NormalizeTitle(title: string): string
	return string.lower(string.gsub(title, "^%s*(.-)%s*$", "%1"))
end

function Search.FuzzyMatch(str: string, query: string): (boolean, string, number)
	if query == "" then
		return true, str, 0
	end
	local lowerStr = str:lower()
	local lowerQuery = query:lower()

	local highlighted = ""
	local score = 0
	local strIdx = 1
	local queryIdx = 1
	local consecutive = 0

	while strIdx <= #str do
		local c1 = lowerStr:sub(strIdx, strIdx)
		if queryIdx <= #query and c1 == lowerQuery:sub(queryIdx, queryIdx) then
			highlighted ..= '<b><font color="#58a6ff">' .. str:sub(strIdx, strIdx) .. "</font></b>"
			queryIdx += 1
			score += 10 + (consecutive * 5)
			
			if strIdx == 1 or not string.match(lowerStr:sub(strIdx - 1, strIdx - 1), "[%w]") then
				score += 15
			end
			
			consecutive += 1
		else
			highlighted ..= str:sub(strIdx, strIdx)
			consecutive = 0
		end
		strIdx += 1
	end

	if queryIdx > #query then
		return true, highlighted, score
	end
	return false, "", 0
end

function Search.StartBounds(value: string, query: string): boolean
	local lowerValue = value:lower()
	local lowerQuery = query:lower()
	local start = 1

	while true do
		local idx = string.find(lowerValue, lowerQuery, start, true)
		if not idx then
			return false
		end

		if idx == 1 then
			return true
		end

		local previousChar = lowerValue:sub(idx - 1, idx - 1)
		if not string.match(previousChar, "[%w]") then
			return true
		end

		start = idx + 1
	end
end

function Search.GetRecentIndex(commandTitle: string, state: CommandUsageState): number?
	local normalizedTitle = Search.NormalizeTitle(commandTitle)
	for i, title in ipairs(state.Recent) do
		if Search.NormalizeTitle(title) == normalizedTitle then
			return i
		end
	end

	return nil
end

function Search.QueryScore(commandTitle: string, query: string, baseScore: number, state: CommandUsageState, includeUsageSignals: boolean?): number
	local rank = baseScore
	local lowerTitle = commandTitle:lower()
	local lowerQuery = query:lower()

	if lowerQuery ~= "" then
		if string.sub(lowerTitle, 1, #lowerQuery) == lowerQuery then
			rank += 120
		elseif Search.StartBounds(commandTitle, query) then
			rank += 80
		end
	end

	local matchStart = string.find(lowerTitle, lowerQuery, 1, true)
	if matchStart then
		rank += math.max(0, 30 - matchStart)
	end

	if includeUsageSignals ~= false then
		local usageCount = state.UsageCounts[commandTitle] or 0
		rank += usageCount * 10

		local recentIndex = Search.GetRecentIndex(commandTitle, state)
		if recentIndex then
			rank += math.max(0, 200 - (recentIndex * 15))
		end

		if lowerQuery ~= "" then
			local pref = state.QueryPreferences[lowerQuery]
			if pref then
				rank += (pref[commandTitle] or 0) * 60
			end
		end
	end

	return rank
end

function Search.RememberCommandChoice(commandTitle: string, query: string, state: CommandUsageState)
	local normalizedTitle = Search.NormalizeTitle(commandTitle)
	state.UsageCounts[commandTitle] = (state.UsageCounts[commandTitle] or 0) + 1

	for i = #state.Recent, 1, -1 do
		if Search.NormalizeTitle(state.Recent[i]) == normalizedTitle then
			table.remove(state.Recent, i)
		end
	end

	table.insert(state.Recent, 1, commandTitle)
	while #state.Recent > 8 do
		table.remove(state.Recent)
	end

	local cleanQuery = string.match(query:sub(2), "^%s*(.*)") or ""
	if cleanQuery ~= "" then
		state.QueryPreferences[cleanQuery] = state.QueryPreferences[cleanQuery] or {}
		local pref = state.QueryPreferences[cleanQuery]
		pref[commandTitle] = (pref[commandTitle] or 0) + 1
	end
end

return Search
