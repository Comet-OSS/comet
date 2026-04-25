--// Imports
local cascade = require("@packages/cascade")

local utility = require("@core/utility")
local commandFramework = require("@core/commandFramework")
local storage = require("@modules/storage")

local themes = require("@ui/themes")
local components = require("@ui/components")
local views = require("@ui/views")

local keybind = require("@modules/keybind")
local instances = require("@modules/instances")
local services = require("@modules/services")

local keybinds = require("@config/keybinds")
local commands = require("@config/commands")
local statusCodes = require("@config/statusCodes")

--// References
local cbD = utility.cbD

--// Types
type RenderedCommand = {
	Data: any,
	Score: number,
	Component: any,
}

type CommandUsageState = {
	UsageCounts: { [string]: number },
	Recent: { string },
	QueryPreferences: { [string]: { [string]: number } },
}

--// State
local comet = {
	Views = {},
}

local currentResults: { RenderedCommand } = {}
local selectedIndex = 1
local isRendering = false
local persistedState = storage.LoadJson("state.json", {
	CommandUsage = {
		UsageCounts = {},
		Recent = {},
		QueryPreferences = {},
	},
	Keybinds = {},
})
local commandUsageState: CommandUsageState = persistedState.CommandUsage

if
	type(commandUsageState) ~= "table"
	or type(commandUsageState.UsageCounts) ~= "table"
	or type(commandUsageState.Recent) ~= "table"
	or type(commandUsageState.QueryPreferences) ~= "table"
then
	commandUsageState = {
		UsageCounts = {},
		Recent = {},
		QueryPreferences = {},
	}
end

local function normalizeRecent(rawRecent: any): { string }
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

commandUsageState.Recent = normalizeRecent(commandUsageState.Recent)

--// Variables
local commandPalette: any

local function normalizeTitle(title: string): string
	return string.lower(string.gsub(title, "^%s*(.-)%s*$", "%1"))
end

local function bindStateSave(keybindSnapshot: { [string]: { [string]: { string | Enum.KeyCode } } })
	local latestState = storage.LoadJson("state.json", {})
	latestState.CommandUsage = commandUsageState
	latestState.Keybinds = keybindSnapshot
	storage.SaveJson("state.json", latestState)
end

local function bindSnapshot()
	local serialized = {}
	for sectionName, sectionTable in pairs(keybinds) do
		if sectionName == "_META" or type(sectionTable) ~= "table" then
			continue
		end

		serialized[sectionName] = {}
		for bindName, bindValue in pairs(sectionTable) do
			if type(bindValue) == "table" and bindValue.Value ~= nil then
				serialized[sectionName][bindName] = table.clone(bindValue.Value)
			end
		end
	end

	return serialized
end

local function loadStatePersistence()
	local persisted = storage.LoadJson("state.json", {})
	local savedKeybinds = persisted.Keybinds

	for sectionName, sectionTable in pairs(keybinds) do
		if sectionName == "_META" or type(sectionTable) ~= "table" then
			continue
		end

		for bindName, bindValue in pairs(sectionTable) do
			if type(bindValue) ~= "table" or bindValue.Value == nil or bindValue.Changed == nil then
				continue
			end

			local saved = savedKeybinds and savedKeybinds[sectionName] and savedKeybinds[sectionName][bindName]
			if type(saved) == "table" and #saved > 0 then
				bindValue.Value = saved
			end

			bindValue.Changed:Connect(function()
				bindStateSave(bindSnapshot())
			end)
		end
	end
end

--// Private Methods
local function fuzzyMatch(str: string, query: string)
	if query == "" then
		return true, str, 0
	end
	local lowerStr = str:lower()
	local lowerQuery = query:lower()

	local highlighted = ""
	local score = 0
	local strIdx = 1
	local queryIdx = 1

	while strIdx <= #str do
		local c1 = lowerStr:sub(strIdx, strIdx)
		if queryIdx <= #query and c1 == lowerQuery:sub(queryIdx, queryIdx) then
			highlighted ..= '<b><font color="#58a6ff">' .. str:sub(strIdx, strIdx) .. "</font></b>"
			queryIdx += 1
			score += 10
		else
			highlighted ..= str:sub(strIdx, strIdx)
		end
		strIdx += 1
	end

	if queryIdx > #query then
		return true, highlighted, score
	end
	return false, "", 0
end

local function startBounds(value: string, query: string): boolean
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

local function getRecentIndex(commandTitle: string): number?
	local normalizedTitle = normalizeTitle(commandTitle)
	for i, title in ipairs(commandUsageState.Recent) do
		if normalizeTitle(title) == normalizedTitle then
			return i
		end
	end

	return nil
end

local function queryScore(commandTitle: string, query: string, baseScore: number, includeUsageSignals: boolean?): number
	local rank = baseScore
	local lowerTitle = commandTitle:lower()
	local lowerQuery = query:lower()

	if lowerQuery ~= "" then
		if string.sub(lowerTitle, 1, #lowerQuery) == lowerQuery then
			rank += 120
		elseif startBounds(commandTitle, query) then
			rank += 80
		end
	end

	local matchStart = string.find(lowerTitle, lowerQuery, 1, true)
	if matchStart then
		rank += math.max(0, 30 - matchStart)
	end

	if includeUsageSignals ~= false then
		local usageCount = commandUsageState.UsageCounts[commandTitle] or 0
		rank += usageCount * 10

		local recentIndex = getRecentIndex(commandTitle)
		if recentIndex then
			rank += math.max(0, 200 - (recentIndex * 15))
		end

		if lowerQuery ~= "" then
			local pref = commandUsageState.QueryPreferences[lowerQuery]
			if pref then
				rank += (pref[commandTitle] or 0) * 60
			end
		end
	end

	return rank
end

local function rememberCommandChoice(commandTitle: string, query: string)
	local normalizedTitle = normalizeTitle(commandTitle)
	commandUsageState.UsageCounts[commandTitle] = (commandUsageState.UsageCounts[commandTitle] or 0) + 1

	for i = #commandUsageState.Recent, 1, -1 do
		if normalizeTitle(commandUsageState.Recent[i]) == normalizedTitle then
			table.remove(commandUsageState.Recent, i)
		end
	end

	table.insert(commandUsageState.Recent, 1, commandTitle)
	while #commandUsageState.Recent > 8 do
		table.remove(commandUsageState.Recent)
	end

	local cleanQuery = query:sub(2):lower()
	if cleanQuery ~= "" then
		commandUsageState.QueryPreferences[cleanQuery] = commandUsageState.QueryPreferences[cleanQuery] or {}
		local pref = commandUsageState.QueryPreferences[cleanQuery]
		pref[commandTitle] = (pref[commandTitle] or 0) + 1
	end

	bindStateSave(bindSnapshot())
end

local function addSectionHeader(title: string, layoutOrder: number)
	local header = Instance.new("TextLabel")
	header.Name = "SectionHeader"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 20)
	header.LayoutOrder = layoutOrder
	header.FontFace = Font.new("rbxassetid://12187365364")
	header.TextSize = 12
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = title
	header.TextColor3 = commandPalette.Theme.Text.Secondary[1].Value
	header.TextTransparency = commandPalette.Theme.Text.Secondary[2].Value
	header.Parent = commandPalette.Structures.ResultsContainer
end

local function applySelection()
	if #currentResults == 0 then
		return
	end

	if selectedIndex > #currentResults then
		selectedIndex = #currentResults
	end
	if selectedIndex < 1 then
		selectedIndex = 1
	end

	for i, item in ipairs(currentResults) do
		if item.Component then
			item.Component.IsSelected = (i == selectedIndex)
		end
	end

	local selectedItem = currentResults[selectedIndex]

	if selectedItem and selectedItem.Component then
		local child = selectedItem.Component

		if child.Parent and child.Parent:IsA("ScrollingFrame") then
			local scrollFrame = child.Parent
			local top = child.AbsolutePosition.Y - scrollFrame.AbsolutePosition.Y + scrollFrame.CanvasPosition.Y
			local bottom = top + child.AbsoluteSize.Y
			local canvasPos = scrollFrame.CanvasPosition.Y
			local winSize = scrollFrame.AbsoluteWindowSize.Y

			if top < canvasPos then
				scrollFrame.CanvasPosition = Vector2.new(0, top)
			elseif bottom > canvasPos + winSize then
				scrollFrame.CanvasPosition = Vector2.new(0, bottom - winSize)
			end
		end
	end
end

local function renderCommands(query: string, isCommandSearch: boolean)
	if isRendering then
		return
	end
	isRendering = true

	for _, child in ipairs(commandPalette.Structures.ResultsContainer:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
			child:Destroy()
		end
	end

	table.clear(currentResults)

	local rawMatches = {}
	if isCommandSearch then
		local searchStr = query:sub(2)

		for _, cmd in ipairs(commandFramework.GetCommands()) do
			local matched, highlightedText, score = fuzzyMatch(cmd.Title, searchStr)

			if matched then
				local rankedScore = queryScore(cmd.Title, searchStr, score)
				table.insert(rawMatches, {
					Title = highlightedText,
					Score = rankedScore,
					RawTitle = cmd.Title,
					Icon = cmd.Icon,
					Shortcut = cmd.Shortcut,
					IsRecent = getRecentIndex(cmd.Title) ~= nil,
					Group = cmd.Group or "Other",

					OnTrigger = function()
						rememberCommandChoice(cmd.Title, query)
						commandPalette.Visible = false
						cmd.OnTrigger()
					end,
				})
			end
		end
	else
		local searchStr = query

		if searchStr ~= "" then
			local insts = instances.Search(searchStr)

			for _, inst in ipairs(insts) do
				local matched, highlightedText, score = fuzzyMatch(inst.Title, searchStr)
				if matched then
					local rankedScore = queryScore(inst.Title, searchStr, score, false)
					table.insert(rawMatches, {
						Title = highlightedText,
						Score = rankedScore,
						RawTitle = inst.Title,

						OnTrigger = function()
							commandPalette.Visible = false
						end,
					})
				end
			end
		end
	end

	table.sort(rawMatches, function(a, b)
		if a.Score == b.Score then
			if a.IsRecent ~= b.IsRecent then
				return a.IsRecent
			end
			return a.RawTitle < b.RawTitle
		end
		return a.Score > b.Score
	end)

	local iterMatches = rawMatches
	if isCommandSearch and query == ">" then
		local recentMatches = {}
		local otherMatches = {}
		for _, data in ipairs(rawMatches) do
			if data.IsRecent then
				table.insert(recentMatches, data)
			else
				table.insert(otherMatches, data)
			end
		end

		local groupedEntries = {}
		local layoutOrder = 1

		if #recentMatches > 0 then
			table.insert(groupedEntries, { Type = "Header", Title = "Recently Used", LayoutOrder = layoutOrder })
			layoutOrder += 1
			for _, data in ipairs(recentMatches) do
				table.insert(groupedEntries, { Type = "Item", Data = data, LayoutOrder = layoutOrder })
				layoutOrder += 1
			end
		end

		local groups = {}
		for _, data in ipairs(rawMatches) do
			local groupName = data.Group or "Other"
			groups[groupName] = groups[groupName] or {}
			table.insert(groups[groupName], data)
		end

		local groupNames = {}
		for name, _ in pairs(groups) do
			table.insert(groupNames, name)
		end
		table.sort(groupNames)

		for _, gname in ipairs(groupNames) do
			local items = groups[gname]
			if items and #items > 0 then
				table.insert(groupedEntries, { Type = "Header", Title = gname, LayoutOrder = layoutOrder })
				layoutOrder += 1
				for _, data in ipairs(items) do
					table.insert(groupedEntries, { Type = "Item", Data = data, LayoutOrder = layoutOrder })
					layoutOrder += 1
				end
			end
		end

		for _, entry in ipairs(groupedEntries) do
			if entry.Type == "Header" then
				addSectionHeader(entry.Title, entry.LayoutOrder)
			elseif entry.Type == "Item" then
				local data = entry.Data
				local resultIndex = #currentResults + 1
				local comp = commandPalette:PaletteItem({
					LayoutOrder = entry.LayoutOrder,
					Title = data.Title,
					Icon = data.Icon,
					Shortcut = data.Shortcut,
					OnTrigger = data.OnTrigger,
					OnFocused = function()
						if not isRendering then
							selectedIndex = resultIndex
							applySelection()
						end
					end,
				})

				table.insert(currentResults, {
					Data = data,
					Score = data.Score,
					Component = comp,
				})
			end
		end
	else
		for _, data in ipairs(iterMatches) do
			local resultIndex = #currentResults + 1
			local comp = commandPalette:PaletteItem({
				LayoutOrder = resultIndex,
				Title = data.Title,
				Icon = data.Icon,
				Shortcut = data.Shortcut,
				OnTrigger = data.OnTrigger,
				OnFocused = function()
					if not isRendering then
						selectedIndex = resultIndex
						applySelection()
					end
				end,
			})

			table.insert(currentResults, {
				Data = data,
				Score = data.Score,
				Component = comp,
			})
		end
	end

	selectedIndex = 1
	applySelection()

	isRendering = false
end

local function toggleCommandBar(initialText: string)
	commandPalette.Visible = not commandPalette.Visible

	if commandPalette.Visible then
		commandPalette.Text = initialText

		task.spawn(function()
			commandPalette.Structures.SearchInput:CaptureFocus()
			commandPalette.Structures.SearchInput.CursorPosition = #initialText + 1
		end)

		renderCommands(initialText, initialText:sub(1, 1) == ">")
	end
end

--// UI
local app = cascade.New({
	Theme = themes.Dark,
	Accent = cascade.Accents.Graphite,
	WindowPill = false,
})

local cleanup
if getgenv then
	local env = getgenv()

	if typeof(env.__myriadCleanup) == "function" then
		pcall(env.__myriadCleanup)
	end

	local cleaned = false
	cleanup = function()
		if cleaned then
			return
		end
		cleaned = true

		if env.__myriadCleanup == cleanup then
			env.__myriadCleanup = nil
		end
		app:Destroy()
	end

	env.__myriadCleanup = cleanup
end

cbD(function()
	app.Parent = utility.GetService("CoreGui")
end)

components()

comet.Views.Settings = views.settings(app)
comet.App = app
comet.Cascade = cascade

commands(comet)
loadStatePersistence()

commandPalette = app:CommandPalette({
	Visible = false,
})

--// Connections
services.UserInputService.InputBegan:Connect(function(key)
	if not commandPalette.Structures.SearchInput:IsFocused() or key.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if key.KeyCode == Enum.KeyCode.Escape then
		commandPalette.Visible = false
		return
	end

	if #currentResults == 0 then
		return
	end

	if key.KeyCode == Enum.KeyCode.Up then
		selectedIndex = (selectedIndex == 1) and #currentResults or selectedIndex - 1
		applySelection()
	elseif key.KeyCode == Enum.KeyCode.Down then
		selectedIndex = (selectedIndex == #currentResults) and 1 or selectedIndex + 1
		applySelection()
	end
end)

commandPalette.Structures.SearchInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local selected = currentResults[selectedIndex]

		if selected then
			local success, result = pcall(selected.Data.OnTrigger)
			local codeLabel = result
				and (result.status and (statusCodes.OnTrigger[result.status] or tostring(result.status)))

			if not success then
				app:Notification({
					App = "Comet",

					Title = `{selected.Data.Title}`,
					Subtitle = `Error running command: {result}`,
					Icon = cascade.Symbols.command,

					Duration = 5,
				})
			elseif result and result.message then
				app:Notification({
					App = "Comet",

					Title = `{selected.Data.Title}`,
					Subtitle = codeLabel and (codeLabel .. ": " .. (result.message or "Error"))
						or (result.message or "Error running command"),
					Icon = cascade.Symbols.command,

					Duration = 5,
				})
			end
		end
	else
		commandPalette.Visible = false
	end
end)

commandPalette.Structures.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	local text = commandPalette.Structures.SearchInput.Text

	renderCommands(text, text:sub(1, 1) == ">")
end)

--// Keybinds
-- Search palette
do
	local bindValue = keybinds.Palette.Search
	local bind = keybind.new(bindValue, { sink = true })

	bind:Connect(function(inputComplete: boolean)
		if inputComplete then
			toggleCommandBar("")
		end
	end)
end

-- Command palette
do
	local bindValue = keybinds.Palette.Command
	local bind = keybind.new(bindValue, { sink = true })

	bind:Connect(function(inputComplete: boolean)
		if inputComplete then
			toggleCommandBar(">")
		end
	end)
end

do
	local showInitGreeting = storage.getUiFlag("ShowInitGreeting", true)
	if showInitGreeting then
		local paletteOpen = {}

		for _, v in keybinds.Palette.Command.Value do
			table.insert(paletteOpen, keybind.enumToPhysical(v))
		end

		app:Notification({
			App = "Comet",

			Title = `Palette loaded`,
			Subtitle = `The command palette has loaded. Press \`{table.concat(paletteOpen, " + ")}\` to use it`,
			Icon = cascade.Symbols.command,

			Duration = 10,
		})
	end
end

return 0
