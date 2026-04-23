--// Imports
local utility = require("@core/utility")

--// Private Functions
local function cast(service: string): Instance
	return utility.GetService(service)
end

--// Module
return {
	Players = cast("Players") :: Players,
	Workspace = cast("Workspace") :: Workspace,
	ReplicatedStorage = cast("ReplicatedStorage") :: ReplicatedStorage,
	Lighting = cast("Lighting") :: Lighting,
	CoreGui = cast("CoreGui") :: CoreGui,
	GuiService = cast("GuiService") :: GuiService,
	ContentProvider = cast("ContentProvider") :: ContentProvider,
	UserInputService = cast("UserInputService") :: UserInputService,
	RunService = cast("RunService") :: RunService,
	HttpService = cast("HttpService") :: HttpService,
	TweenService = cast("TweenService") :: TweenService,
	CollectionService = cast("CollectionService") :: CollectionService,
	ContextActionService = cast("ContextActionService") :: ContextActionService,
}
