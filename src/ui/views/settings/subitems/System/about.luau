--// Publish
return function(cascade, app, window, root)
	--// Imports
	local utility = require("@core/utility")

	--// Variables
	local meta = _P
	local tag = utility.safePath(meta, "tag")
	local target = utility.safePath(meta, "target")
	local variant = utility.safePath(meta, "variant")
	local generatedAt = utility.safePath(meta, "generatedAt")
	local prerelease = utility.safePath(meta, "prerelease")

	local versionLine = string.format("Version %s", tag)
	if type(prerelease) == "string" and prerelease ~= "" then
		versionLine = string.format("%s (%s)", versionLine, prerelease)
	end

	local tagline: string
	if type(variant) == "string" and variant ~= "" then
		tagline = string.format("%s · %s", target, variant)
	else
		tagline = target
	end

	local formattedDate = generatedAt
	if type(generatedAt) == "string" then
		local year, month, day = string.match(generatedAt, "^(%d+)%-(%d+)%-(%d+)")
		if year and month and day then
			local months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
			local monthName = months[tonumber(month)] or month
			formattedDate = string.format("%s %d, %s", monthName, tonumber(day), year)
		end
	end

	local specs = {
		{ Key = "Executor", Value = (identifyexecutor and identifyexecutor()) or "Unknown" },
		{ Key = "Target", Value = target },
		{ Key = "Generated", Value = formattedDate },
		{ Key = "PlaceId", Value = tostring(game.PlaceId) },
	}

	--// Private Methods
	local function copyVersion()
		local text = string.format("Comet %s (%s)", tag, target)

		if setclipboard then
			setclipboard(text)
		end

		app:Notification({
			App = "Comet",
			AppIcon = "rbxassetid://109261725124277",

			Title = setclipboard and "Copied" or "Unable to copy",
			Subtitle = not setclipboard and "The executor does not have `setclipboard`",

			Duration = 4,
		})
	end

	--// Initialize
	root:AboutPanel({
		ProductName = "Comet",
		VersionLine = versionLine,
		Tagline = tagline,
		Specs = specs,
		Footer = "© 2026 Comet-OSS, All Rights Reserved. MIT license.",
		Symbol = "rbxassetid://109261725124277",
		OnSoftwareUpdate = copyVersion,
	})
end
