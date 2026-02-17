-- ============================================
-- STARTER PACK GUI - Matches TrailShop/GamepassShop Theme
-- ============================================

local Players = game:GetService("Players")
local MPS = game:GetService("MarketplaceService")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StarterPackGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============================================
-- STARTER PACK CONTAINER (matches shop theme)
-- ============================================
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0.5, 0, 0.55, 0)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(28, 25, 45)
container.BorderSizePixel = 0
container.Visible = false
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 16)
containerCorner.Parent = container

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = Color3.fromRGB(100, 60, 200)
containerStroke.Thickness = 2
containerStroke.Parent = container

-- Title Bar
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

-- Body
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

-- Description
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

-- Items Container
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

-- Items
local items = {
	{emoji = "💰", text = "500 Bonus Coins"},
	{emoji = "⚡", text = "Speed Boost Trail"},
	{emoji = "🎨", text = "Free Rainbow Trail"},
}

for i, item in ipairs(items) do
	local itemLabel = Instance.new("TextLabel")
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

-- Claim Button
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

-- Toggle function
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

toggleBtn.MouseButton1Click:Connect(function()
	toggleContainer()
end)

closeBtn.MouseButton1Click:Connect(function()
	toggleContainer(false)
end)

-- Claim button (connects to server-side rewards)
claimBtn.MouseButton1Click:Connect(function()
	-- TODO: Fire RemoteEvent to grant rewards on server
	local claimEvent = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("ClaimStarterPack")
	
	if claimEvent then
		-- Fire server event to grant rewards
		claimEvent:FireServer()
		-- Server will send back success/failure via notification system
	else
		-- Not yet implemented - inform user
		if _G.Notify then
			_G.Notify("⚠️ Coming Soon", "Starter pack rewards are not yet configured!", 3, "warning")
		end
	end
	
	toggleContainer(false)
end)

print("✅ StarterPack GUI loaded")
