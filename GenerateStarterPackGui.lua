-- ============================================
-- STARTER PACK GUI GENERATOR (FULLY FUNCTIONAL)
-- ============================================
-- Run this script ONCE to generate the Starter Pack GUI in StarterGui
-- Matches the design of the Gamepass/Shop GUI with full functionality
-- 
-- Instructions:
-- 1. Copy this script to ServerScriptService or use the Command Bar
-- 2. Run the script once (it will create the GUI in StarterGui)
-- 3. The GUI will appear in StarterGui WITH ALL SCRIPTS AND FUNCTIONALITY
-- 4. Delete this generator script when done
-- 5. Edit the GUI manually as needed
-- ============================================

print("Creating StarterPackGui in StarterGui...")

-- ============================================
-- CREATE MAIN SCREENGUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StarterPackGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game.StarterGui

-- ============================================
-- MAIN CONTAINER (matches shop theme)
-- ============================================
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0.5, 0, 0.55, 0)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(28, 25, 45)  -- Dark purple theme
container.BorderSizePixel = 0
container.Visible = false
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 16)
containerCorner.Parent = container

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = Color3.fromRGB(100, 60, 200)  -- Purple accent
containerStroke.Thickness = 2
containerStroke.Parent = container

print("  ✓ Main container created")

-- ============================================
-- TITLE BAR
-- ============================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 32, 65)
titleBar.BorderSizePixel = 0
titleBar.Parent = container

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 16)
titleBarCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
titleLabel.Position = UDim2.new(0.1, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎁 STARTER PACK"
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = titleBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

print("  ✓ Title bar with close button created")

-- ============================================
-- BODY CONTAINER
-- ============================================
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, -40, 1, -70)
body.Position = UDim2.new(0, 20, 0, 60)
body.BackgroundTransparency = 1
body.Parent = container

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 15)
bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Parent = body

print("  ✓ Body container with layout created")

-- ============================================
-- DESCRIPTION LABEL
-- ============================================
local descLabel = Instance.new("TextLabel")
descLabel.Name = "Description"
descLabel.Size = UDim2.new(1, 0, 0, 60)
descLabel.BackgroundTransparency = 1
descLabel.Text = "Welcome to Climb To Top! Here's your starter pack to help you begin your journey!"
descLabel.Font = Enum.Font.Gotham
descLabel.TextSize = 14
descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
descLabel.TextWrapped = true
descLabel.LayoutOrder = 1
descLabel.Parent = body

print("  ✓ Description label created")

-- ============================================
-- ITEMS CONTAINER
-- ============================================
local itemsFrame = Instance.new("Frame")
itemsFrame.Name = "ItemsFrame"
itemsFrame.Size = UDim2.new(1, 0, 0, 180)
itemsFrame.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
itemsFrame.BorderSizePixel = 0
itemsFrame.LayoutOrder = 2
itemsFrame.Parent = body

local itemsCorner = Instance.new("UICorner")
itemsCorner.CornerRadius = UDim.new(0, 12)
itemsCorner.Parent = itemsFrame

local itemsList = Instance.new("UIListLayout")
itemsList.Padding = UDim.new(0, 10)
itemsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
itemsList.Parent = itemsFrame

local itemsPadding = Instance.new("UIPadding")
itemsPadding.PaddingTop = UDim.new(0, 15)
itemsPadding.PaddingBottom = UDim.new(0, 15)
itemsPadding.PaddingLeft = UDim.new(0, 20)
itemsPadding.PaddingRight = UDim.new(0, 20)
itemsPadding.Parent = itemsFrame

-- Create reward items
local items = {
	{emoji = "💰", text = "500 Bonus Coins"},
	{emoji = "⚡", text = "Speed Boost Trail"},
	{emoji = "🎨", text = "Free Rainbow Trail"},
}

for i, item in ipairs(items) do
	local itemLabel = Instance.new("TextLabel")
	itemLabel.Name = "Item" .. i
	itemLabel.Size = UDim2.new(1, -20, 0, 35)
	itemLabel.BackgroundColor3 = Color3.fromRGB(45, 38, 70)
	itemLabel.BorderSizePixel = 0
	itemLabel.Text = item.emoji .. "  " .. item.text
	itemLabel.Font = Enum.Font.GothamBold
	itemLabel.TextSize = 16
	itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	itemLabel.TextXAlignment = Enum.TextXAlignment.Left
	itemLabel.Parent = itemsFrame
	
	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 8)
	itemCorner.Parent = itemLabel
	
	local itemPad = Instance.new("UIPadding")
	itemPad.PaddingLeft = UDim.new(0, 15)
	itemPad.Parent = itemLabel
end

print("  ✓ Reward items created")

-- ============================================
-- CLAIM BUTTON
-- ============================================
local claimBtn = Instance.new("TextButton")
claimBtn.Name = "ClaimBtn"
claimBtn.Size = UDim2.new(0.8, 0, 0, 50)
claimBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
claimBtn.BorderSizePixel = 0
claimBtn.Text = "✓ CLAIM STARTER PACK"
claimBtn.Font = Enum.Font.GothamBlack
claimBtn.TextSize = 18
claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
claimBtn.LayoutOrder = 3
claimBtn.Parent = body

local claimBtnCorner = Instance.new("UICorner")
claimBtnCorner.CornerRadius = UDim.new(0, 12)
claimBtnCorner.Parent = claimBtn

print("  ✓ Claim button created")

-- ============================================
-- TOGGLE BUTTON (bottom left)
-- ============================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "StarterPackToggle"
toggleBtn.Size = UDim2.new(0, 60, 0, 60)
toggleBtn.Position = UDim2.new(0, 20, 1, -80)
toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 200)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "🎁"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 28
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 12)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(255, 255, 255)
toggleStroke.Thickness = 2
toggleStroke.Parent = toggleBtn

print("  ✓ Toggle button created")

-- ============================================
-- MAIN SCRIPT (LocalScript)
-- ============================================
local mainScript = Instance.new("LocalScript")
mainScript.Name = "StarterPackScript"
mainScript.Parent = screenGui

mainScript.Source = [[
-- ============================================
-- STARTER PACK GUI SCRIPT - Full functionality
-- ============================================

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local screenGui = script.Parent
local container = screenGui:WaitForChild("Container")
local toggleBtn = screenGui:WaitForChild("StarterPackToggle")
local titleBar = container:WaitForChild("TitleBar")
local closeBtn = titleBar:WaitForChild("CloseBtn")
local body = container:WaitForChild("Body")
local claimBtn = body:WaitForChild("ClaimBtn")

-- ============================================
-- TOGGLE FUNCTIONALITY
-- ============================================
local function toggleContainer(force)
	local shouldOpen = force
	if shouldOpen == nil then
		shouldOpen = not container.Visible
	end
	
	if shouldOpen then
		container.Visible = true
		container.Size = UDim2.new(0, 0, 0, 0)
		TS:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.5, 0, 0.55, 0)
		}):Play()
	else
		TS:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()
		task.delay(0.2, function() container.Visible = false end)
	end
end

-- ============================================
-- BUTTON HOVER EFFECTS
-- ============================================
local function addButtonHover(btn, normalColor, hoverColor)
	btn.MouseEnter:Connect(function()
		TS:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = hoverColor
		}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TS:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = normalColor
		}):Play()
	end)
end

-- Apply hover effects
addButtonHover(toggleBtn, Color3.fromRGB(100, 60, 200), Color3.fromRGB(120, 80, 220))
addButtonHover(closeBtn, Color3.fromRGB(200, 50, 50), Color3.fromRGB(220, 70, 70))
addButtonHover(claimBtn, Color3.fromRGB(100, 200, 100), Color3.fromRGB(120, 220, 120))

-- ============================================
-- BUTTON CONNECTIONS
-- ============================================
toggleBtn.MouseButton1Click:Connect(function()
	toggleContainer()
end)

closeBtn.MouseButton1Click:Connect(function()
	toggleContainer(false)
end)

-- ============================================
-- CLAIM FUNCTIONALITY
-- ============================================
local hasClaimed = false

claimBtn.MouseButton1Click:Connect(function()
	if hasClaimed then
		if _G.Notify then
			_G.Notify("ℹ️ Already Claimed", "You've already claimed your starter pack!", 3, "info")
		end
		return
	end
	
	-- Try to find the claim remote event
	local claimEvent = RS:FindFirstChild("RemoteEvents")
	if claimEvent then
		claimEvent = claimEvent:FindFirstChild("ClaimStarterPack")
	end
	
	if claimEvent then
		-- Fire server event to grant rewards
		claimEvent:FireServer()
		hasClaimed = true
		
		-- Update button appearance
		claimBtn.Text = "✓ CLAIMED!"
		claimBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		
		if _G.Notify then
			_G.Notify("🎁 Success!", "Starter pack claimed! Rewards granted!", 4, "success")
		end
		
		-- Close after 1.5 seconds
		task.delay(1.5, function()
			toggleContainer(false)
		end)
	else
		-- Server-side not implemented yet
		if _G.Notify then
			_G.Notify("⚠️ Coming Soon", "Starter pack rewards are not yet configured on the server!", 3, "warning")
		else
			warn("StarterPack: Server-side claim event not found. Please implement RemoteEvents/ClaimStarterPack")
		end
	end
end)

-- ============================================
-- AUTO-OPEN ON FIRST JOIN
-- ============================================
-- Check if this is the player's first time
task.spawn(function()
	-- Wait for leaderstats to load
	local leaderstats = plr:WaitForChild("leaderstats", 10)
	if not leaderstats then return end
	
	-- Simple heuristic: if player has 0 or very few coins, show starter pack
	local coins = leaderstats:FindFirstChild("Coins")
	if coins and coins.Value < 100 then
		-- Wait a moment for other GUIs to load
		task.wait(2)
		-- Auto-open for new players
		toggleContainer(true)
	end
end)

-- ============================================
-- GLOBAL FUNCTION
-- ============================================
_G.OpenStarterPack = function()
	toggleContainer(true)
end

-- ============================================
-- KEYBOARD SHORTCUT (P for Pack)
-- ============================================
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.P then
		toggleContainer()
	end
end)

print("StarterPackGui initialized successfully!")
print("Press P to toggle, or call _G.OpenStarterPack() from other scripts")
]]

print("  ✓ Main script created with full functionality")

-- ============================================
-- COMPLETION MESSAGE
-- ============================================
print("")
print("========================================")
print("✓ STARTER PACK GUI GENERATION COMPLETE!")
print("========================================")
print("The 'StarterPackGui' has been created in StarterGui")
print("")
print("Features Included:")
print("  ✓ Shop-style design matching gamepass GUI")
print("  ✓ Animated open/close transitions")
print("  ✓ Hover effects on all buttons")
print("  ✓ Toggle button (bottom left corner)")
print("  ✓ Claim button with server integration")
print("  ✓ Auto-opens for new players (< 100 coins)")
print("  ✓ Keyboard shortcut (P key)")
print("  ✓ Global function (_G.OpenStarterPack)")
print("")
print("UI Structure:")
print("  • Container (main frame)")
print("  • Title Bar with close button")
print("  • Description text")
print("  • Items frame with 3 reward items")
print("  • Claim button")
print("  • Toggle button (screen corner)")
print("")
print("Colors Match Shop Theme:")
print("  • Background: RGB(28, 25, 45) - Dark purple")
print("  • Accent: RGB(100, 60, 200) - Purple")
print("  • Title bar: RGB(40, 32, 65)")
print("  • Items: RGB(45, 38, 70)")
print("  • Claim button: RGB(100, 200, 100) - Green")
print("")
print("Next Steps:")
print("1. Check StarterGui in Explorer")
print("2. Test the GUI - it's fully functional!")
print("3. Customize reward items in ItemsFrame")
print("4. Implement server-side RemoteEvents/ClaimStarterPack")
print("5. Delete this generator script")
print("")
print("Server Implementation Needed:")
print("  Create: ReplicatedStorage.RemoteEvents.ClaimStarterPack")
print("  Grant: 500 coins, trails, or other rewards")
print("  Use: PlayerDataManager to save claimed status")
print("========================================")
print("")
