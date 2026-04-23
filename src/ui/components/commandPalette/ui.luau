--// Imports
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
	local theme = self.Theme.Controls.CommandBar
	local structures = {}

	--// UI
	structures.Body = apply(
		properties,
		create("Frame")({
			Name = "CommandBar",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 48),
			Size = UDim2.fromOffset(600, 400),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Parent = parent,

			__dynamicKeys = {
				BackgroundColor3 = theme.Background[1],
				BackgroundTransparency = theme.Background[2],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 8),
			}),

			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				__dynamicKeys = {
					Color = theme.Border[1],
					Transparency = theme.Border[2],
				},
			}),

			create("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),

			create("Frame")({
				Name = "InputPaddingBox",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 36),
				LayoutOrder = 1,

				create("UIPadding")({
					PaddingTop = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 6),
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				}),

				create("Frame")({
					Name = "SearchContainer",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.new(1, 0, 1, 0),
					BorderSizePixel = 0,

					__dynamicKeys = {
						BackgroundColor3 = theme.InputBackground[1],
						BackgroundTransparency = theme.InputBackground[2],
					},

					create("UICorner")({
						CornerRadius = UDim.new(0, 4),
					}),

					create("UIStroke")({
						Name = "InputStroke",
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						__dynamicKeys = {
							Color = theme.InputBorderReady[1],
							Transparency = theme.InputBorderReady[2],
						},
						__contextKeys = {
							Color = function()
								return properties.Focused and theme.InputBorderFocused[1].Value
									or theme.InputBorderReady[1].Value
							end,
							Transparency = function()
								return properties.Focused and theme.InputBorderFocused[2].Value
									or theme.InputBorderReady[2].Value
							end,
						},
					}),

					create("UIPadding")({
						PaddingLeft = UDim.new(0, 6),
						PaddingRight = UDim.new(0, 6),
					}),

					create("TextBox")({
						Name = "SearchInput",
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						FontFace = Font.new("rbxassetid://12187365364"),
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "",
						PlaceholderText = "Type a command or search...",
						ClearTextOnFocus = false,

						__dynamicKeys = {
							TextColor3 = self.Theme.Text.Primary[1],
							TextTransparency = self.Theme.Text.Primary[2],
							PlaceholderColor3 = self.Theme.Text.Secondary[1],
						},
					}),
				}),
			}),

			create("ScrollingFrame")({
				Name = "ResultsContainer",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, -40),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollBarThickness = 6,
				LayoutOrder = 2,

				__dynamicKeys = {
					ScrollBarImageColor3 = self.Theme.Controls.Separator.Background[1],
					ScrollBarImageTransparency = self.Theme.Controls.Separator.Background[2],
				},

				create("UIListLayout")({
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 0),
				}),

				create("UIPadding")({
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
					PaddingTop = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 6),
				}),
			}),
		})
	) :: Frame

	--// Initialize
	structures.InputPaddingBox = structures.Body:FindFirstChild("InputPaddingBox") :: Frame
	structures.SearchContainer = structures.InputPaddingBox:FindFirstChild("SearchContainer") :: Frame
	structures.InputStroke = structures.SearchContainer:FindFirstChild("InputStroke") :: UIStroke
	structures.SearchInput = structures.SearchContainer:FindFirstChild("SearchInput") :: TextBox
	structures.ResultsContainer = structures.Body:FindFirstChild("ResultsContainer") :: ScrollingFrame

	return structures, theme, parent
end
