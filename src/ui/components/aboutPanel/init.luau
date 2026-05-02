--// Imports
local cascade = require("@packages/cascade")

--// References
local binder = cascade.Binder
local create = cascade.Creator.Create

--// Private Methods
local function textLabel(
	parent: Instance,
	name: string,
	text: string,
	textSize: number,
	fontWeight: Enum.FontWeight,
	layoutOrder: number,
	themeKeys: { [string]: any }
): TextLabel
	return create("TextLabel")({
		Name = name,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxassetid://12187365364", fontWeight),
		LayoutOrder = layoutOrder,
		LineHeight = 1.15,
		RichText = true,
		Size = UDim2.new(1, 0, 0, 0),
		Text = text,
		TextSize = textSize,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,

		__dynamicKeys = themeKeys,
	}) :: TextLabel
end

--// Publish
return function(self, properties: any)
	properties = properties or {}

	local parent = self.__container or self.__instance or self
	local theme = self.Theme

	local productName = properties.ProductName or "Comet"
	local versionLine = properties.VersionLine or ""
	local tagline = properties.Tagline
	local specs = properties.Specs or {}
	local footerText = properties.Footer or ""
	local symbolImage = properties.Symbol

	local structures = {}

	structures.Card = binder.Apply(
		properties,
		create("Frame")({
			Name = "AboutCard",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = parent,

			create("UIPadding")({
				PaddingTop = UDim.new(0, 40),
				PaddingBottom = UDim.new(0, 40),
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
			}),

			create("Frame")({
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 32),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Wraps = true,
				}),

				create("Frame")({
					Name = "Mark",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = 1,
					Size = UDim2.fromOffset(140, 140),

					create("ImageLabel")({
						Name = "Glyph",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = symbolImage or "",
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromOffset(140, 140),
					}),
				}),

				create("Frame")({
					Name = "Copy",
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = 2,
					Size = UDim2.new(0, 320, 0, 0),

					create("UIListLayout")({
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Top,
					}),
				}),
			}),
		})
	) :: Frame

	local content = structures.Card:FindFirstChild("Content") :: Frame
	local copy = content:FindFirstChild("Copy") :: Frame
	local markFrame = content:FindFirstChild("Mark") :: Frame
	structures.Glyph = markFrame:FindFirstChild("Glyph") :: ImageLabel
	structures.Glyph.Visible = symbolImage ~= nil and symbolImage ~= ""

	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	structures.Title = textLabel(copy, "Title", productName, 40, Enum.FontWeight.Bold, nextOrder(), {
		TextColor3 = theme.Text.SelectionPrimary[1],
		TextTransparency = theme.Text.SelectionPrimary[2],
	})
	structures.Title.LineHeight = 1.0

	structures.Subtitle = textLabel(copy, "Subtitle", versionLine, 13, Enum.FontWeight.Medium, nextOrder(), {
		TextColor3 = theme.Text.Secondary[1],
		TextTransparency = theme.Text.Secondary[2],
	})

	create("Frame")({
		Name = "TaglineSpacer",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 10),
		Parent = copy,
	})

	if tagline and tagline ~= "" then
		structures.Tagline = textLabel(copy, "Tagline", tagline, 13, Enum.FontWeight.Bold, nextOrder(), {
			TextColor3 = theme.Text.SelectionPrimary[1],
			TextTransparency = theme.Text.SelectionPrimary[2],
		})
	end

	create("Frame")({
		Name = "SpecsSpacer",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 16),
		Parent = copy,
	})

	for index, entry in ipairs(specs) do
		if type(entry) == "table" and entry.Key and entry.Value then
			create("Frame")({
				Name = "Spec" .. tostring(index),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
				Size = UDim2.new(1, 0, 0, 0),
				Parent = copy,

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 12),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Top,
				}),

				create("TextLabel")({
					Name = "Key",
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold),
					LayoutOrder = 1,
					LineHeight = 1.15,
					RichText = true,
					Size = UDim2.new(0, 80, 0, 0),
					Text = tostring(entry.Key),
					TextSize = 13,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					__dynamicKeys = {
						TextColor3 = theme.Text.SelectionPrimary[1],
						TextTransparency = theme.Text.SelectionPrimary[2],
					},
				}),

				create("TextLabel")({
					Name = "Value",
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
					LayoutOrder = 2,
					LineHeight = 1.15,
					RichText = true,
					Size = UDim2.new(1, -92, 0, 0),
					Text = tostring(entry.Value),
					TextSize = 13,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					__dynamicKeys = {
						TextColor3 = theme.Text.Secondary[1],
						TextTransparency = theme.Text.Secondary[2],
					},
				}),
			})
		end
	end

	local copyCtx = cascade.Component({
		Theme = self.Theme,
		Accent = self.Accent,
		Parent = copy,
	})

	create("Frame")({
		Name = "ActionsSpacer",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 12),
		Parent = copy,
	})

	local actions = copyCtx:HStack({
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	actions.Structures.Body.LayoutOrder = nextOrder()

	local rowFrame = (actions.Structures.Body :: any).__instance or actions.Structures.Body
	local btnCtx = cascade.Component({
		Theme = self.Theme,
		Accent = self.Accent,
		Parent = rowFrame :: Instance,
	})

	structures.UpdateButton = btnCtx:Button({
		State = "Secondary",
		Label = properties.SoftwareUpdateLabel or "Copy version",
		Pushed = properties.OnSoftwareUpdate,
	})

	create("Frame")({
		Name = "FooterSpacer",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 16),
		Parent = copy,
	})

	if footerText ~= "" then
		structures.Footer = textLabel(copy, "Footer", footerText, 12, Enum.FontWeight.Bold, nextOrder(), {
			TextColor3 = theme.Text.Tertiary[1],
			TextTransparency = theme.Text.Tertiary[2],
		})
		structures.Footer.TextXAlignment = Enum.TextXAlignment.Left
	end

	local object = binder.Wrap(properties, {
		ProductName = function(value: string)
			structures.Title.Text = value
		end,
		VersionLine = function(value: string)
			structures.Subtitle.Text = value
		end,
		Symbol = function(value: string?)
			structures.Glyph.Image = value or ""
			structures.Glyph.Visible = value ~= nil and value ~= ""
		end,
	}, structures.Card)

	object.Type = "AboutPanel"
	object.Theme = self.Theme
	object.Structures = structures
	object.__container = structures.Card

	binder.Apply(properties, object)

	return object
end
