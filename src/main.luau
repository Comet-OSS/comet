--// Imports
local cascade = require("@packages/cascade")
local topbarPlus = require("@packages/topbarPlus")

local utility = require("@core/utility")
local commandFramework = require("@core/commandFramework")
local storage = require("@modules/storage")

local themes = require("@ui/themes")
local components = require("@ui/components")
local views = require("@ui/views")

local keybind = require("@modules/keybind")
local instances = require("@modules/instances")
local services = require("@modules/services")
local search = require("@modules/search")

local keybinds = require("@config/keybinds")
local commands = require("@config/commands")

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

--// Variables
local comet = {
	Views = {},
}
local persistedState = storage.LoadJson("state.json", {
	CommandUsage = {
		UsageCounts = {},
		Recent = {},
		QueryPreferences = {},
	},
	Keybinds = {},
})

local commandPalette: any
local isHoveringResults = false
local currentResults: { RenderedCommand } = {}
local selectedIndex = 1
local isRendering = false
local commandUsageState: CommandUsageState = persistedState.CommandUsage

local heldNavKey: Enum.KeyCode? = nil
local navHoldToken = 0

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

--// Private Methods
commandUsageState.Recent = search.NormalizeRecent(commandUsageState.Recent)

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

			if selectedIndex == 1 then
				scrollFrame.CanvasPosition = Vector2.new(0, 0)
			elseif top < canvasPos then
				scrollFrame.CanvasPosition = Vector2.new(0, top)
			elseif bottom > canvasPos + winSize then
				scrollFrame.CanvasPosition = Vector2.new(0, bottom - winSize)
			end
		end
	end
end

local function moveSelection(delta: number)
	if #currentResults == 0 then
		return
	end

	if delta < 0 then
		selectedIndex = (selectedIndex == 1) and #currentResults or selectedIndex - 1
	else
		selectedIndex = (selectedIndex == #currentResults) and 1 or selectedIndex + 1
	end
	applySelection()
end

local function startNavHold(keyCode: Enum.KeyCode, delta: number)
	heldNavKey = keyCode
	navHoldToken += 1
	local myToken = navHoldToken

	local startTime = os.clock()
	task.spawn(function()
		local behavior = utility.safePath(_P.shared, "UiBehavior", true)
		if behavior.MenuNavHoldDelay == nil then
			behavior.MenuNavHoldDelay = 0.32
		end
		if behavior.MenuNavRepeatStartInterval == nil then
			behavior.MenuNavRepeatStartInterval = 0.085
		end
		if behavior.MenuNavRepeatMinInterval == nil then
			behavior.MenuNavRepeatMinInterval = 0.035
		end
		if behavior.MenuNavRepeatAccelPerSecond == nil then
			behavior.MenuNavRepeatAccelPerSecond = 0.02
		end

		task.wait(behavior.MenuNavHoldDelay)

		while
			navHoldToken == myToken
			and heldNavKey == keyCode
			and commandPalette
			and commandPalette.Visible
			and commandPalette.Structures
			and commandPalette.Structures.SearchInput
			and commandPalette.Structures.SearchInput:IsFocused()
		do
			local heldFor = os.clock() - startTime
			local interval = math.max(
				behavior.MenuNavRepeatMinInterval,
				behavior.MenuNavRepeatStartInterval - (heldFor * behavior.MenuNavRepeatAccelPerSecond)
			)

			moveSelection(delta)
			task.wait(interval)
		end
	end)
end

local function stopNavHold(keyCode: Enum.KeyCode?)
	if keyCode == nil or heldNavKey == keyCode then
		heldNavKey = nil
		navHoldToken += 1
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
		local searchStr = string.match(query:sub(2), "^%s*(.*)") or ""

		for _, cmd in ipairs(commandFramework.GetCommands()) do
			local matched, highlightedText, score = search.FuzzyMatch(cmd.Title, searchStr)

			if matched then
				local rankedScore = search.QueryScore(cmd.Title, searchStr, score, commandUsageState)
				table.insert(rawMatches, {
					Title = highlightedText,
					Score = rankedScore,
					RawTitle = cmd.Title,
					Icon = cmd.Icon,
					Shortcut = cmd.Shortcut,
					IsRecent = search.GetRecentIndex(cmd.Title, commandUsageState) ~= nil,
					Group = cmd.Group or "Other",

					OnTrigger = function()
						search.RememberCommandChoice(cmd.Title, query, commandUsageState)
						bindStateSave(bindSnapshot())
						commandPalette.Visible = false
						cmd.OnTrigger(cmd, cmd.Super)
					end,
				})
			end
		end
	else
		local searchStr = query

		if searchStr ~= "" then
			local insts = instances.Search(searchStr)

			for _, inst in ipairs(insts) do
				local matched, highlightedText, score = search.FuzzyMatch(inst.Title, searchStr)
				if matched then
					local rankedScore = search.QueryScore(inst.Title, searchStr, score, commandUsageState, false)
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
	local cleanQuery = isCommandSearch and (string.match(query:sub(2), "^%s*(.*)") or "") or query
	if isCommandSearch and cleanQuery == "" then
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
	if not commandPalette.Visible then
		stopNavHold()
	end

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

--// Topbar
do
	-- Root
	do
		app.TopbarIcon = topbarPlus.new()
		app.TopbarIcon:setImage(cascade.Symbols.sparkle):setLabel("Comet")
		app.TopbarIcon:setCaption("Open comet menus")
	end

	-- Search
	do
		app.TopbarIcon_Search = topbarPlus.new()
		app.TopbarIcon_Search:setImage(cascade.Symbols.magnifyingglass):setLabel("Search"):setOrder(1)

		app.TopbarIcon_Search.selected:Connect(function()
			app.TopbarIcon_Search:deselect()
			app.TopbarIcon:deselect()

			toggleCommandBar("")
		end)
	end

	-- Command
	do
		app.TopbarIcon_Command = topbarPlus.new()
		app.TopbarIcon_Command
			:setImage(cascade.Symbols.chevronLeftForwardslashChevronRight)
			:setLabel("Commands")
			:setOrder(2)

		app.TopbarIcon_Command.selected:Connect(function()
			app.TopbarIcon_Command:deselect()
			app.TopbarIcon:deselect()

			toggleCommandBar(">")
		end)
	end

	-- Search
	do
		app.TopbarIcon_Settings = topbarPlus.new()
		app.TopbarIcon_Settings:setImage(cascade.Symbols.gearshape):setLabel("Settings"):setOrder(3)

		app.TopbarIcon_Settings.selected:Connect(function()
			app.TopbarIcon_Settings:deselect()
			app.TopbarIcon:deselect()

			comet.Views.Settings.Visible = true
			comet.Views.Settings.Minimized = false
		end)
	end

	app.TopbarIcon:setDropdown({ app.TopbarIcon_Search, app.TopbarIcon_Command, app.TopbarIcon_Settings })
end

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

_P.shared.CleanPersistance = function(): boolean
	local ok = storage.SaveJson("state.json", {})
	commandUsageState = {
		UsageCounts = {},
		Recent = {},
		QueryPreferences = {},
	}

	return ok
end

cbD(function()
	app.Parent = utility.GetService("CoreGui")
end)

components()

do
	local behavior = utility.safePath(_P.shared, "UiBehavior", true)

	if behavior.MenuNavHoldDelay == nil then
		behavior.MenuNavHoldDelay = 0.32
	end

	if behavior.MenuNavRepeatStartInterval == nil then
		behavior.MenuNavRepeatStartInterval = 0.085
	end

	if behavior.MenuNavRepeatMinInterval == nil then
		behavior.MenuNavRepeatMinInterval = 0.035
	end

	if behavior.MenuNavRepeatAccelPerSecond == nil then
		behavior.MenuNavRepeatAccelPerSecond = 0.02
	end
end

comet.Views.Settings = views.settings(app)
comet.App = app
comet.Cascade = cascade

_P.shared.App = app

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
		stopNavHold()
		commandPalette.Visible = false
		return
	end

	if #currentResults == 0 then
		return
	end

	if key.KeyCode == Enum.KeyCode.Up then
		moveSelection(-1)
		startNavHold(Enum.KeyCode.Up, -1)
	elseif key.KeyCode == Enum.KeyCode.Down then
		moveSelection(1)
		startNavHold(Enum.KeyCode.Down, 1)
	end
end)

services.UserInputService.InputEnded:Connect(function(key)
	if key.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if key.KeyCode == Enum.KeyCode.Up or key.KeyCode == Enum.KeyCode.Down then
		stopNavHold(key.KeyCode)
	end
end)

commandPalette.Structures.ResultsContainer.MouseEnter:Connect(function()
	isHoveringResults = true
end)
commandPalette.Structures.ResultsContainer.MouseLeave:Connect(function()
	isHoveringResults = false
end)

commandPalette.Structures.SearchInput.FocusLost:Connect(function(enterPressed)
	stopNavHold()
	if enterPressed then
		local selected = currentResults[selectedIndex]
		if selected then
			selected.Data.OnTrigger(selected.Data, selected.Data.Super)
		end
	else
		if isHoveringResults then
			task.defer(function()
				commandPalette.Structures.SearchInput:CaptureFocus()
			end)
		else
			commandPalette.Visible = false
		end
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
			AppIcon = "rbxassetid://109261725124277",

			Icon = cascade.Symbols.command,
			Title = `Palette loaded`,
			Subtitle = `The command palette has loaded. Press \`{table.concat(paletteOpen, " + ")}\` to use it`,

			Duration = 10,
		})
	end
end

return 0
