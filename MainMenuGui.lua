-- ============================================
-- MAIN MENU GUI - Starter GUI with ImageButtons
-- Clean, organized layout ready for scripting
-- ============================================

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")

-- ============================================
-- CREATE MAIN SCREENGUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainMenuGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============================================
-- BACKGROUND FRAME (Semi-transparent)
-- ============================================
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.4
background.BorderSizePixel = 0
background.Visible = true
background.Parent = screenGui

-- ============================================
-- MAIN MENU CONTAINER
-- ============================================
local mainMenuFrame = Instance.new("Frame")
mainMenuFrame.Name = "MainMenuFrame"
mainMenuFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
mainMenuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainMenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainMenuFrame.BackgroundColor3 = Color3.fromRGB(28, 25, 45)
mainMenuFrame.BorderSizePixel = 0
mainMenuFrame.Parent = screenGui

-- Add rounded corners
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = mainMenuFrame

-- Add outline stroke
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 60, 200)
mainStroke.Thickness = 3
mainStroke.Parent = mainMenuFrame

-- Add padding for proper spacing
local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingTop = UDim.new(0, 20)
mainPadding.PaddingBottom = UDim.new(0, 20)
mainPadding.PaddingLeft = UDim.new(0, 30)
mainPadding.PaddingRight = UDim.new(0, 30)
mainPadding.Parent = mainMenuFrame

-- ============================================
-- TITLE SECTION
-- ============================================
local titleLabel = Instance.new("ImageLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 80)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 32, 65)
titleLabel.BackgroundTransparency = 0
titleLabel.BorderSizePixel = 0
titleLabel.Image = "rbxassetid://0"  -- Placeholder for title image
titleLabel.ScaleType = Enum.ScaleType.Fit
titleLabel.Parent = mainMenuFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleLabel

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(120, 80, 220)
titleStroke.Thickness = 2
titleStroke.Parent = titleLabel

-- Title text overlay (in case no image is used)
local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "MAIN MENU"
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 32
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Parent = titleLabel

-- ============================================
-- BUTTON CONTAINER
-- ============================================
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, 0, 1, -100)
buttonContainer.Position = UDim2.new(0, 0, 0, 100)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = mainMenuFrame

-- Add list layout for organized button placement
local buttonLayout = Instance.new("UIListLayout")
buttonLayout.Name = "ButtonLayout"
buttonLayout.Padding = UDim.new(0, 15)
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.Parent = buttonContainer

-- ============================================
-- HELPER FUNCTION: Create ImageButton
-- ============================================
local function createImageButton(name, layoutOrder, buttonText, imageId)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Size = UDim2.new(0.85, 0, 0, 70)
	btn.BackgroundColor3 = Color3.fromRGB(60, 50, 100)
	btn.BorderSizePixel = 0
	btn.Image = imageId or "rbxassetid://0"  -- Placeholder image
	btn.ScaleType = Enum.ScaleType.Fit
	btn.ImageTransparency = 0.3  -- Semi-transparent to show background color
	btn.LayoutOrder = layoutOrder
	btn.Parent = buttonContainer
	
	-- Rounded corners
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 16)
	btnCorner.Parent = btn
	
	-- Button outline
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Name = "ButtonStroke"
	btnStroke.Color = Color3.fromRGB(150, 100, 255)
	btnStroke.Thickness = 2
	btnStroke.Transparency = 0
	btnStroke.Parent = btn
	
	-- Aspect ratio constraint for consistent sizing
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 5.0  -- Wide button (350:70 ratio)
	aspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
	aspectRatio.Parent = btn
	
	-- Button text overlay
	local btnText = Instance.new("TextLabel")
	btnText.Name = "ButtonText"
	btnText.Size = UDim2.new(1, 0, 1, 0)
	btnText.BackgroundTransparency = 1
	btnText.Text = buttonText
	btnText.Font = Enum.Font.GothamBold
	btnText.TextSize = 24
	btnText.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnText.TextStrokeTransparency = 0.5
	btnText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	btnText.Parent = btn
	
	-- Hover effect
	btn.MouseEnter:Connect(function()
		TS:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(80, 70, 130)
		}):Play()
		TS:Create(btnStroke, TweenInfo.new(0.2), {
			Color = Color3.fromRGB(200, 150, 255),
			Thickness = 3
		}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TS:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(60, 50, 100)
		}):Play()
		TS:Create(btnStroke, TweenInfo.new(0.2), {
			Color = Color3.fromRGB(150, 100, 255),
			Thickness = 2
		}):Play()
	end)
	
	-- Press animation
	btn.MouseButton1Down:Connect(function()
		TS:Create(btn, TweenInfo.new(0.1), {
			Size = UDim2.new(0.80, 0, 0, 65)
		}):Play()
	end)
	
	btn.MouseButton1Up:Connect(function()
		TS:Create(btn, TweenInfo.new(0.1), {
			Size = UDim2.new(0.85, 0, 0, 70)
		}):Play()
	end)
	
	return btn
end

-- ============================================
-- CREATE MENU BUTTONS
-- ============================================

-- Play/Start Button
local playButton = createImageButton("PlayButton", 1, "▶ PLAY", "rbxassetid://0")
playButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)  -- Green theme

-- Settings Button
local settingsButton = createImageButton("SettingsButton", 2, "⚙ SETTINGS", "rbxassetid://0")

-- Shop/Store Button
local shopButton = createImageButton("ShopButton", 3, "🛒 SHOP", "rbxassetid://0")
shopButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)  -- Gold theme

-- Leaderboard Button
local leaderboardButton = createImageButton("LeaderboardButton", 4, "🏆 LEADERBOARD", "rbxassetid://0")
leaderboardButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)  -- Blue theme

-- ============================================
-- CLOSE/EXIT BUTTON (Top Right Corner)
-- ============================================
local closeButton = Instance.new("ImageButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 50, 0, 50)
closeButton.Position = UDim2.new(1, -60, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)  -- Red theme
closeButton.BorderSizePixel = 0
closeButton.Image = "rbxassetid://0"  -- Placeholder for X icon
closeButton.ScaleType = Enum.ScaleType.Fit
closeButton.ImageTransparency = 0.3
closeButton.Parent = mainMenuFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 12)
closeCorner.Parent = closeButton

local closeStroke = Instance.new("UIStroke")
closeStroke.Name = "CloseStroke"
closeStroke.Color = Color3.fromRGB(255, 100, 100)
closeStroke.Thickness = 2
closeStroke.Parent = closeButton

-- Close button text
local closeText = Instance.new("TextLabel")
closeText.Name = "CloseText"
closeText.Size = UDim2.new(1, 0, 1, 0)
closeText.BackgroundTransparency = 1
closeText.Text = "✕"
closeText.Font = Enum.Font.GothamBold
closeText.TextSize = 28
closeText.TextColor3 = Color3.fromRGB(255, 255, 255)
closeText.Parent = closeButton

-- Close button aspect ratio
local closeAspect = Instance.new("UIAspectRatioConstraint")
closeAspect.AspectRatio = 1.0  -- Square button
closeAspect.Parent = closeButton

-- Close button hover effect
closeButton.MouseEnter:Connect(function()
	TS:Create(closeButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	}):Play()
	TS:Create(closeStroke, TweenInfo.new(0.2), {
		Thickness = 3
	}):Play()
end)

closeButton.MouseLeave:Connect(function()
	TS:Create(closeButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	}):Play()
	TS:Create(closeStroke, TweenInfo.new(0.2), {
		Thickness = 2
	}):Play()
end)

-- ============================================
-- BUTTON FUNCTIONALITY (Placeholder - Ready for Scripting)
-- ============================================

playButton.Activated:Connect(function()
	print("Play button clicked!")
	-- TODO: Add play/start game logic here
end)

settingsButton.Activated:Connect(function()
	print("Settings button clicked!")
	-- TODO: Add settings menu toggle logic here
	-- Example: Toggle existing SettingsGui if it exists
end)

shopButton.Activated:Connect(function()
	print("Shop button clicked!")
	-- TODO: Add shop menu toggle logic here
	-- Example: Toggle existing shop GUI
end)

leaderboardButton.Activated:Connect(function()
	print("Leaderboard button clicked!")
	-- TODO: Add leaderboard display logic here
end)

closeButton.Activated:Connect(function()
	print("Close button clicked!")
	-- Hide the main menu
	mainMenuFrame.Visible = false
	background.Visible = false
end)

-- ============================================
-- GLOBAL TOGGLE FUNCTION (For external scripts)
-- ============================================
_G.ToggleMainMenu = function()
	local isVisible = mainMenuFrame.Visible
	mainMenuFrame.Visible = not isVisible
	background.Visible = not isVisible
	
	if not isVisible then
		-- Animate menu opening
		mainMenuFrame.Size = UDim2.new(0, 0, 0, 0)
		TS:Create(mainMenuFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.4, 0, 0.6, 0)
		}):Play()
	end
end

-- ============================================
-- MOBILE SCALING ADJUSTMENTS
-- ============================================
local function adjustForMobile()
	local screenSize = workspace.CurrentCamera.ViewportSize
	local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
	
	if isMobile or screenSize.X < 800 then
		-- Adjust main menu size for smaller screens
		mainMenuFrame.Size = UDim2.new(0.85, 0, 0.75, 0)
		
		-- Adjust title text size
		titleText.TextSize = 24
		
		-- Adjust button text size
		for _, btn in pairs(buttonContainer:GetChildren()) do
			if btn:IsA("ImageButton") then
				local btnText = btn:FindFirstChild("ButtonText")
				if btnText then
					btnText.TextSize = 20
				end
			end
		end
		
		-- Adjust close button size
		closeButton.Size = UDim2.new(0, 45, 0, 45)
		closeText.TextSize = 24
	end
end

-- Call on startup
adjustForMobile()

-- Recalculate on viewport size change
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustForMobile)

-- ============================================
-- KEYBOARD SHORTCUT (ESC to toggle menu)
-- ============================================
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		_G.ToggleMainMenu()
	end
end)

print("MainMenuGui initialized successfully!")
