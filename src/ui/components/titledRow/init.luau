--// Imports
local cascade, _types = require("@packages/cascade"), require("@packages/cascade/types")

--// References
local binder = cascade.Binder

--// Publish
return function(self, properties: any)
	properties = properties or {}
	properties.Title = properties.Title or "Title"

	--// Structures
	local row = self:Row({ SearchIndex = properties.Title }) :: _types.Row
	local titleStack = row:Left():TitleStack({ Title = properties.Title }) :: _types.TitleStack

	--// Bind
	local object = binder.Wrap(properties, {
		Title = function(val: string)
			titleStack.Title = val
			row.SearchIndex = val
		end,
		Subtitle = function(val: string?)
			titleStack.Subtitle = val
		end,
	}, row)

	object.Type = "TitledRow"
	object.Structures = { Row = row, TitleStack = titleStack }
	binder.Apply(properties, object, {})

	return object :: { Title: string, Subtitle: string? }
end
