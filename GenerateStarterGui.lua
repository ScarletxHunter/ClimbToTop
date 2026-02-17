-- ============================================
-- STARTER GUI GENERATOR SCRIPT (FULLY FUNCTIONAL)
-- ============================================
-- Run this script ONCE to generate the complete GUI structure in StarterGui
-- This creates a FULLY FUNCTIONAL GUI with all scripts, animations, and logic
-- After running, you can edit the GUI manually in StarterGui
-- 
-- Instructions:
-- 1. Copy this script to ServerScriptService or use the Command Bar
-- 2. Run the script once (it will create the GUI in StarterGui)
-- 3. The GUI will appear in StarterGui in the Explorer WITH ALL FUNCTIONALITY
-- 4. Delete this generator script when done
-- 5. Edit the GUI elements and scripts manually as needed
-- ============================================

-- ============================================
-- CREATE MAIN SCREENGUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainMenuGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game.StarterGui

print("Creating MainMenuGui in StarterGui...")

-- ============================================
-- BACKGROUND FRAME (Semi-transparent overlay)
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

print("  ✓ Background frame created")

-- ============================================
-- MAIN MENU CONTAINER FRAME
-- ============================================
local mainMenuFrame = Instance.new("Frame")
mainMenuFrame.Name = "MainMenuFrame"
mainMenuFrame.Size = UDim2.new(0.4, 0, 0.6, 0)  -- 40% width, 60% height
mainMenuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)  -- Centered
mainMenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainMenuFrame.BackgroundColor3 = Color3.fromRGB(28, 25, 45)  -- Dark purple theme
mainMenuFrame.BorderSizePixel = 0
mainMenuFrame.Parent = screenGui

-- Add rounded corners to main frame
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = mainMenuFrame

-- Add outline stroke to main frame
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 60, 200)  -- Purple accent
mainStroke.Thickness = 3
mainStroke.Parent = mainMenuFrame

-- Add padding for proper spacing inside main frame
local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingTop = UDim.new(0, 20)
mainPadding.PaddingBottom = UDim.new(0, 20)
mainPadding.PaddingLeft = UDim.new(0, 30)
mainPadding.PaddingRight = UDim.new(0, 30)
mainPadding.Parent = mainMenuFrame

print("  ✓ Main menu frame created with rounded corners, stroke, and padding")

-- ============================================
-- TITLE SECTION (ImageLabel with text overlay)
-- ============================================
local titleLabel = Instance.new("ImageLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 80)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 32, 65)
titleLabel.BackgroundTransparency = 0
titleLabel.BorderSizePixel = 0
titleLabel.Image = "rbxassetid://0"  -- Placeholder for title image (replace with your image ID)
titleLabel.ScaleType = Enum.ScaleType.Fit
titleLabel.Parent = mainMenuFrame

-- Rounded corners for title
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleLabel

-- Title outline stroke
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(120, 80, 220)
titleStroke.Thickness = 2
titleStroke.Parent = titleLabel

-- Title text overlay (shows even without image)
local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "MAIN MENU"
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 32
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Parent = titleLabel

print("  ✓ Title section created")

-- ============================================
-- BUTTON CONTAINER
-- ============================================
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, 0, 1, -100)  -- Fill remaining space below title
buttonContainer.Position = UDim2.new(0, 0, 0, 100)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = mainMenuFrame

-- Add list layout for automatic vertical button arrangement
local buttonLayout = Instance.new("UIListLayout")
buttonLayout.Name = "ButtonLayout"
buttonLayout.Padding = UDim.new(0, 15)  -- 15px spacing between buttons
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.Parent = buttonContainer

print("  ✓ Button container with UIListLayout created")

-- ============================================
-- HELPER FUNCTION: Create ImageButton
-- ============================================
local function createImageButton(name, layoutOrder, buttonText, backgroundColor, imageId)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Size = UDim2.new(0.85, 0, 0, 70)  -- 85% of container width, 70px height
	btn.BackgroundColor3 = backgroundColor
	btn.BorderSizePixel = 0
	btn.Image = imageId or "rbxassetid://0"  -- Placeholder image (replace with your image ID)
	btn.ScaleType = Enum.ScaleType.Fit
	btn.ImageTransparency = 0.3  -- Semi-transparent to show background color
	btn.LayoutOrder = layoutOrder
	btn.Parent = buttonContainer
	
	-- Rounded corners for button
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 16)
	btnCorner.Parent = btn
	
	-- Button outline stroke
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Name = "ButtonStroke"
	btnStroke.Color = Color3.fromRGB(150, 100, 255)
	btnStroke.Thickness = 2
	btnStroke.Transparency = 0
	btnStroke.Parent = btn
	
	-- Aspect ratio constraint for consistent sizing across devices
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 5.0  -- Wide button (5:1 ratio)
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
	
	return btn
end

-- ============================================
-- CREATE MENU BUTTONS (Color-coded by function)
-- ============================================

-- Play/Start Button (Green theme)
local playButton = createImageButton(
	"PlayButton", 
	1, 
	"▶ PLAY", 
	Color3.fromRGB(50, 150, 50),  -- Green for Play/Start action
	"rbxassetid://0"
)
print("  ✓ Play button created (Green)")

-- Settings Button (Default purple theme)
local settingsButton = createImageButton(
	"SettingsButton", 
	2, 
	"⚙ SETTINGS", 
	Color3.fromRGB(60, 50, 100),  -- Default purple
	"rbxassetid://0"
)
print("  ✓ Settings button created")

-- Shop/Store Button (Gold theme)
local shopButton = createImageButton(
	"ShopButton", 
	3, 
	"🛒 SHOP", 
	Color3.fromRGB(200, 150, 50),  -- Gold for Shop/Store
	"rbxassetid://0"
)
print("  ✓ Shop button created (Gold)")

-- Leaderboard Button (Blue theme)
local leaderboardButton = createImageButton(
	"LeaderboardButton", 
	4, 
	"🏆 LEADERBOARD", 
	Color3.fromRGB(50, 100, 200),  -- Blue for Leaderboard
	"rbxassetid://0"
)
print("  ✓ Leaderboard button created (Blue)")

-- ============================================
-- CLOSE/EXIT BUTTON (Top Right Corner)
-- ============================================
local closeButton = Instance.new("ImageButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 50, 0, 50)
closeButton.Position = UDim2.new(1, -60, 0, 10)  -- Top right, with 10px margin
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)  -- Red for Close/Exit
closeButton.BorderSizePixel = 0
closeButton.Image = "rbxassetid://0"  -- Placeholder for X icon (replace with your image ID)
closeButton.ScaleType = Enum.ScaleType.Fit
closeButton.ImageTransparency = 0.3
closeButton.Parent = mainMenuFrame

-- Rounded corners for close button
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 12)
closeCorner.Parent = closeButton

-- Close button outline stroke
local closeStroke = Instance.new("UIStroke")
closeStroke.Name = "CloseStroke"
closeStroke.Color = Color3.fromRGB(255, 100, 100)
closeStroke.Thickness = 2
closeStroke.Parent = closeButton

-- Close button text (X symbol)
local closeText = Instance.new("TextLabel")
closeText.Name = "CloseText"
closeText.Size = UDim2.new(1, 0, 1, 0)
closeText.BackgroundTransparency = 1
closeText.Text = "✕"
closeText.Font = Enum.Font.GothamBold
closeText.TextSize = 28
closeText.TextColor3 = Color3.fromRGB(255, 255, 255)
closeText.Parent = closeButton

-- Close button aspect ratio (square)
local closeAspect = Instance.new("UIAspectRatioConstraint")
closeAspect.AspectRatio = 1.0  -- Square button (1:1 ratio)
closeAspect.Parent = closeButton

print("  ✓ Close button created (Red)")

-- ============================================
-- MAIN GUI SCRIPT (LocalScript)
-- ============================================
-- This script handles all GUI functionality, animations, and button logic
local mainScript = Instance.new("LocalScript")
mainScript.Name = "MainMenuScript"
mainScript.Parent = screenGui

-- Write the main script source
mainScript.Source = [[
-- ============================================
-- MAIN MENU GUI SCRIPT - Handles all functionality
-- ============================================

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local screenGui = script.Parent
local mainMenuFrame = screenGui:WaitForChild("MainMenuFrame")
local background = screenGui:WaitForChild("Background")
local buttonContainer = mainMenuFrame:WaitForChild("ButtonContainer")

-- Get all buttons
local playButton = buttonContainer:WaitForChild("PlayButton")
local settingsButton = buttonContainer:WaitForChild("SettingsButton")
local shopButton = buttonContainer:WaitForChild("ShopButton")
local leaderboardButton = buttonContainer:WaitForChild("LeaderboardButton")
local closeButton = mainMenuFrame:WaitForChild("CloseButton")

-- ============================================
-- BUTTON HOVER AND CLICK ANIMATIONS
-- ============================================

-- Helper function to add hover effects to buttons
local function addButtonEffects(btn, normalColor, hoverColor)
	local btnStroke = btn:FindFirstChild("ButtonStroke") or btn:FindFirstChild("CloseStroke")
	local originalSize = btn.Size
	
	-- Hover effect
	btn.MouseEnter:Connect(function()
		TS:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = hoverColor
		}):Play()
		if btnStroke then
			TS:Create(btnStroke, TweenInfo.new(0.2), {
				Thickness = 3
			}):Play()
		end
	end)
	
	btn.MouseLeave:Connect(function()
		TS:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = normalColor
		}):Play()
		if btnStroke then
			TS:Create(btnStroke, TweenInfo.new(0.2), {
				Thickness = 2
			}):Play()
		end
	end)
	
	-- Press animation
	btn.MouseButton1Down:Connect(function()
		TS:Create(btn, TweenInfo.new(0.1), {
			Size = UDim2.new(originalSize.X.Scale * 0.94, originalSize.X.Offset, originalSize.Y.Scale, originalSize.Y.Offset - 5)
		}):Play()
	end)
	
	btn.MouseButton1Up:Connect(function()
		TS:Create(btn, TweenInfo.new(0.1), {
			Size = originalSize
		}):Play()
	end)
end

-- Apply effects to all buttons
addButtonEffects(playButton, Color3.fromRGB(50, 150, 50), Color3.fromRGB(70, 180, 70))
addButtonEffects(settingsButton, Color3.fromRGB(60, 50, 100), Color3.fromRGB(80, 70, 130))
addButtonEffects(shopButton, Color3.fromRGB(200, 150, 50), Color3.fromRGB(220, 170, 70))
addButtonEffects(leaderboardButton, Color3.fromRGB(50, 100, 200), Color3.fromRGB(70, 120, 220))
addButtonEffects(closeButton, Color3.fromRGB(200, 50, 50), Color3.fromRGB(255, 70, 70))

-- ============================================
-- BUTTON FUNCTIONALITY
-- ============================================

-- Play Button - Hides menu (you can add game start logic)
playButton.Activated:Connect(function()
	print("Play button clicked!")
	mainMenuFrame.Visible = false
	background.Visible = false
	-- TODO: Add your game start logic here
	-- Example: Fire a RemoteEvent to start the game
end)

-- Settings Button - Opens settings (placeholder)
settingsButton.Activated:Connect(function()
	print("Settings button clicked!")
	-- TODO: Add settings menu toggle logic here
	-- Example: Check if SettingsGui exists and toggle it
	local settingsGui = plr.PlayerGui:FindFirstChild("SettingsGui")
	if settingsGui then
		local settingsFrame = settingsGui:FindFirstChild("SettingsFrame")
		if settingsFrame then
			settingsFrame.Visible = not settingsFrame.Visible
		end
	else
		warn("SettingsGui not found. Create a settings menu first!")
	end
end)

-- Shop Button - Opens shop (placeholder)
shopButton.Activated:Connect(function()
	print("Shop button clicked!")
	-- TODO: Add shop menu toggle logic here
	-- Example: Check if ShopGui exists and toggle it
	local shopGui = plr.PlayerGui:FindFirstChild("NewShopGui") or plr.PlayerGui:FindFirstChild("ShopGui")
	if shopGui then
		local shopFrame = shopGui:FindFirstChild("ShopFrame") or shopGui:FindFirstChild("Container")
		if shopFrame then
			shopFrame.Visible = not shopFrame.Visible
		end
	else
		warn("ShopGui not found. The shop system may not be implemented yet!")
	end
end)

-- Leaderboard Button - Shows leaderboard (placeholder)
leaderboardButton.Activated:Connect(function()
	print("Leaderboard button clicked!")
	-- TODO: Add leaderboard display logic here
	-- Example: Check if LeaderboardGui exists and toggle it
	local leaderboardGui = plr.PlayerGui:FindFirstChild("LeaderboardGui")
	if leaderboardGui then
		local leaderboardFrame = leaderboardGui:FindFirstChild("LeaderboardFrame")
		if leaderboardFrame then
			leaderboardFrame.Visible = not leaderboardFrame.Visible
		end
	else
		warn("LeaderboardGui not found. The leaderboard system may not be implemented yet!")
	end
end)

-- Close Button - Hides the menu
closeButton.Activated:Connect(function()
	print("Close button clicked!")
	mainMenuFrame.Visible = false
	background.Visible = false
end)

-- ============================================
-- GLOBAL TOGGLE FUNCTION
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
		local titleLabel = mainMenuFrame:FindFirstChild("TitleLabel")
		if titleLabel then
			local titleText = titleLabel:FindFirstChild("TitleText")
			if titleText then
				titleText.TextSize = 24
			end
		end
		
		-- Adjust button text size
		for _, btn in pairs(buttonContainer:GetChildren()) do
			if btn:IsA("ImageButton") then
				local btnText = btn:FindFirstChild("ButtonText")
				if btnText then
					btnText.TextSize = 20
				end
			end
		end
		
		-- Adjust close button
		closeButton.Size = UDim2.new(0, 45, 0, 45)
		local closeText = closeButton:FindFirstChild("CloseText")
		if closeText then
			closeText.TextSize = 24
		end
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
print("Press ESC to toggle menu, or call _G.ToggleMainMenu() from other scripts")
]]

print("  ✓ Main GUI script created with full functionality")
print("  ✓ Button animations (hover, click) added")
print("  ✓ Button click handlers added")
print("  ✓ Mobile scaling logic added")
print("  ✓ Keyboard shortcut (ESC) added")
print("  ✓ Global toggle function (_G.ToggleMainMenu) added")

-- ============================================
-- COMPLETION MESSAGE
-- ============================================
print("")
print("========================================")
print("✓ GUI GENERATION COMPLETE!")
print("========================================")
print("The 'MainMenuGui' has been created in StarterGui")
print("")
print("Next Steps:")
print("1. Check StarterGui in the Explorer window")
print("2. Expand 'MainMenuGui' to see all elements AND SCRIPTS")
print("3. Test the menu - it's FULLY FUNCTIONAL!")
print("4. Replace placeholder images (rbxassetid://0) with your own")
print("5. Edit button scripts to integrate with your game systems")
print("6. Delete this GenerateStarterGui script when done")
print("")
print("Button Functionality (ALREADY IMPLEMENTED):")
print("  • PlayButton (Green) - Hides menu (add game start logic)")
print("  • SettingsButton - Toggles SettingsGui if it exists")
print("  • ShopButton (Gold) - Toggles ShopGui if it exists")
print("  • LeaderboardButton (Blue) - Toggles LeaderboardGui if it exists")
print("  • CloseButton (Red) - Hides the menu")
print("  • ESC Key - Toggles menu visibility")
print("  • _G.ToggleMainMenu() - Global function to toggle from other scripts")
print("")
print("Features Included:")
print("  ✓ Hover animations on all buttons")
print("  ✓ Click/press animations")
print("  ✓ Mobile-friendly responsive design")
print("  ✓ Keyboard shortcuts (ESC)")
print("  ✓ Global toggle function")
print("  ✓ Automatic integration with existing GUIs")
print("")
print("UI Elements Created:")
print("  • ScreenGui (MainMenuGui)")
print("  • Background Frame (semi-transparent overlay)")
print("  • MainMenuFrame (main container)")
print("  • TitleLabel (ImageLabel with text)")
print("  • 5 ImageButtons (with UICorner, UIStroke, UIAspectRatioConstraint)")
print("  • UIListLayout (automatic button arrangement)")
print("  • UIPadding (proper spacing)")
print("  • MainMenuScript (LocalScript with ALL functionality)")
print("========================================")
print("")
