local cascade = require("@packages/cascade")

return function(self, properties: any)
	--// Imports
	local creator = cascade.Creator
	local binder = cascade.Binder

	--// References
	local create = creator.Create
	local apply = binder.Apply

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme.Controls.CommandItem
	local controls = self.Theme.Controls
	local textTheme = self.Theme.Text
	local structures = {}

	local function contextColor(defaultColor, selectedColor)
		return function()
			return properties.IsSelected and selectedColor[1].Value or defaultColor[1].Value
		end
	end

	local function contextAlpha(defaultColor, selectedColor)
		return function()
			return properties.IsSelected and selectedColor[2].Value or defaultColor[2].Value
		end
	end

	structures.Body = apply(
		properties,
		create("TextButton")({
			Name = properties.Name,
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = properties.LayoutOrder or 0,
			Text = "",
			Parent = parent,

			__dynamicKeys = {
				BackgroundColor3 = theme.Background[1],
				BackgroundTransparency = theme.Background[2],
			},
			__contextKeys = {
				BackgroundColor3 = contextColor(theme.Background, controls.Selection),
				BackgroundTransparency = contextAlpha(theme.Background, controls.Selection),
			},

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			create("UICorner")({
				CornerRadius = UDim.new(0, 4),
			}),

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),

			create("Frame")({
				Name = "Leading",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 1,

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				create("ImageLabel")({
					Name = "Icon",
					Visible = false,
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(14, 14),
					LayoutOrder = 1,

					__dynamicKeys = {
						ImageColor3 = theme.IconDefault[1],
						ImageTransparency = theme.IconDefault[2],
					},
					__contextKeys = {
						ImageColor3 = contextColor(theme.IconDefault, textTheme.SelectionPrimary),
						ImageTransparency = contextAlpha(theme.IconDefault, textTheme.SelectionPrimary),
					},
				}),

				create("TextLabel")({
					Name = "Title",
					RichText = true,
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
					FontFace = Font.new("rbxassetid://12187365364"),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = properties.Title,
					LayoutOrder = 2,

					__dynamicKeys = {
						TextColor3 = theme.TextDefault[1],
						TextTransparency = theme.TextDefault[2],
					},
					__contextKeys = {
						TextColor3 = contextColor(theme.TextDefault, textTheme.SelectionPrimary),
						TextTransparency = contextAlpha(theme.TextDefault, textTheme.SelectionPrimary),
					},
				}),
			}),

			create("Frame")({
				Name = "Trailing",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 2,

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				create("TextLabel")({
					Name = "Shortcut",
					Visible = false,
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
					FontFace = Font.new("rbxassetid://12187365364"),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					Text = "",

					__dynamicKeys = {
						TextColor3 = self.Theme.Text.Secondary[1],
						TextTransparency = self.Theme.Text.Secondary[2],
					},
					__contextKeys = {
						TextColor3 = contextColor(self.Theme.Text.Secondary, textTheme.SelectionPrimary),
						TextTransparency = contextAlpha(self.Theme.Text.Secondary, textTheme.SelectionPrimary),
					},
				}),
			}),
		})
	) :: TextButton

	--// Initialize
	structures.Leading = structures.Body:FindFirstChild("Leading") :: Frame
	structures.Trailing = structures.Body:FindFirstChild("Trailing") :: Frame
	structures.Title = structures.Leading:FindFirstChild("Title") :: TextLabel
	structures.Icon = structures.Leading:FindFirstChild("Icon") :: ImageLabel
	structures.Shortcut = structures.Trailing:FindFirstChild("Shortcut") :: TextLabel

	return structures, theme, parent
end
