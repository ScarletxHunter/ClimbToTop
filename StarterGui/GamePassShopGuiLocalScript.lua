-- ============================================
-- GAMEPASS SHOP GUI SCRIPT (WEAPONS Tab Replacement!)
-- Place in: StarterGui/GamePassShopGui/LocalScript
-- ============================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local container = gui:WaitForChild("Container")
local header = container:WaitForChild("Header")
local closeButton = header:WaitForChild("CloseButton")
local tabRow = container:WaitForChild("TabRow")
local itemList = container:WaitForChild("ItemList")

-- Tab buttons
local gamepassTab = tabRow:WaitForChild("GAMEPASSTab")
local cashTab = tabRow:WaitForChild("CASHTab")
local weaponsTab = tabRow:WaitForChild("WEAPONSTab")

print("??? GamePass Shop initializing...")

local currentTab = "GAMEPASS"

-- ============================================
-- TAB COLORS (WEAPONS replaces BOOSTS)
-- ============================================

local TAB_COLORS = {
	GAMEPASS = {Active = Color3.fromRGB(0, 150, 255), Inactive = Color3.fromRGB(30, 60, 100)},
	CASH = {Active = Color3.fromRGB(80, 200, 80), Inactive = Color3.fromRGB(30, 70, 40)},
	WEAPONS = {Active = Color3.fromRGB(220, 60, 220), Inactive = Color3.fromRGB(80, 30, 80)},
}

local allTabs = {
	GAMEPASS = gamepassTab,
	CASH = cashTab,
	WEAPONS = weaponsTab,
}

-- ============================================
-- ALL SHOP ITEMS (3 TABS - WEAPONS ADDED!)
-- ============================================

local ALL_ITEMS = {
	-- ==================== GAMEPASS TAB ====================
	{
		Name = "Starter Pack",
		Description = "500 coins + starter weapon + welcome trail!",
		Price = 149,
		GamePassId = 1704084817,
		Icon = "??",
		Color = Color3.fromRGB(100, 200, 100),
		Category = "GAMEPASS",
		Type = "GamePass"
	},
	{
		Name = "Trail Master",
		Description = "10+ amazing trail effects! Change anytime.",
		Price = 99,
		GamePassId = 1704388512,
		Icon = "?",
		Color = Color3.fromRGB(150, 100, 255),
		Category = "GAMEPASS",
		Type = "GamePass"
	},
	{
		Name = "Head Start",
		Description = "Spawn 3s early + 15% speed boost!",
		Price = 149,
		GamePassId = 1704300498,
		Icon = "??",
		Color = Color3.fromRGB(100, 200, 255),
		Category = "GAMEPASS",
		Type = "GamePass"
	},
	{
		Name = "VIP Pass",
		Description = "2x coins, rainbow name, sparkle trail, VIP badge!",
		Price = 199,
		GamePassId = 1704140664,
		Icon = "??",
		Color = Color3.fromRGB(255, 215, 0),
		Category = "GAMEPASS",
		Type = "GamePass"
	},
	{
		Name = "Athlete Pass",
		Description = "+10% speed and +10% jump power!",
		Price = 199,
		GamePassId = 1703657605,
		Icon = "??",
		Color = Color3.fromRGB(255, 150, 50),
		Category = "GAMEPASS",
		Type = "GamePass"
	},
	{
		Name = "Knockback Resist",
		Description = "50% less knockback + 30% heavier!",
		Price = 449,
		GamePassId = 1703795339,
		Icon = "???",
		Color = Color3.fromRGB(200, 80, 80),
		Category = "GAMEPASS",
		Type = "GamePass"
	},

	-- ==================== CASH TAB (COIN PACKS) ====================
	{
		Name = "Small Pack",
		Description = "Get 500 coins instantly!",
		Price = 50,
		ProductId = 3532194043,
		Icon = "??",
		Color = Color3.fromRGB(0, 180, 255),
		Category = "CASH",
		Type = "Product"
	},
	{
		Name = "Medium Pack",
		Description = "Get 1,200 coins! (+20% Bonus)",
		Price = 100,
		ProductId = 3532194379,
		Icon = "??",
		Color = Color3.fromRGB(0, 200, 255),
		Category = "CASH",
		Type = "Product"
	},
	{
		Name = "Large Pack",
		Description = "Get 2,750 coins! (+37% Bonus)",
		Price = 200,
		ProductId = 3532194611,
		Icon = "??",
		Color = Color3.fromRGB(0, 220, 255),
		Category = "CASH",
		Type = "Product"
	},
	{
		Name = "Mega Pack",
		Description = "Get 5,500 coins! (+57% Bonus)",
		Price = 350,
		ProductId = 3532194827,
		Icon = "??",
		Color = Color3.fromRGB(100, 200, 255),
		Category = "CASH",
		Type = "Product"
	},
	{
		Name = "Ultra Pack",
		Description = "Get 12,000 coins! (+100% Bonus)",
		Price = 600,
		ProductId = 3532195036,
		Icon = "??",
		Color = Color3.fromRGB(150, 150, 255),
		Category = "CASH",
		Type = "Product"
	},

	-- ==================== WEAPONS TAB (PERMANENT ROBUX TOOLS) ====================
	{
		Name = "Shield Bubble",
		Description = "Block 3 hits per round! Press Q to activate.",
		Price = 199,
		ProductId = 0, -- ADD YOUR PRODUCT ID!
		Icon = "???",
		Color = Color3.fromRGB(100, 200, 255),
		Category = "WEAPONS",
		Type = "Product"
	},
	{
		Name = "Jump Sword",
		Description = "Double jump! 5 uses per round. Press E to use.",
		Price = 199,
		ProductId = 0, -- ADD YOUR PRODUCT ID!
		Icon = "??",
		Color = Color3.fromRGB(150, 255, 150),
		Category = "WEAPONS",
		Type = "Product"
	},
	{
		Name = "Speed Boots",
		Description = "50% faster for 10 seconds! 2 uses per round.",
		Price = 149,
		ProductId = 0, -- ADD YOUR PRODUCT ID!
		Icon = "??",
		Color = Color3.fromRGB(255, 200, 100),
		Category = "WEAPONS",
		Type = "Product"
	},
	{
		Name = "Mega Push",
		Description = "Push players 2x farther! Stronger than free push.",
		Price = 249,
		ProductId = 0, -- ADD YOUR PRODUCT ID!
		Icon = "??",
		Color = Color3.fromRGB(255, 100, 100),
		Category = "WEAPONS",
		Type = "Product"
	},
	{
		Name = "Teleport Pad",
		Description = "Place a teleport point! Return to it once per round.",
		Price = 299,
		ProductId = 0, -- ADD YOUR PRODUCT ID!
		Icon = "??",
		Color = Color3.fromRGB(200, 100, 255),
		Category = "WEAPONS",
		Type = "Product"
	},
	{
		Name = "Ice Blaster",
		Description = "Freeze players for 3 seconds! 3 uses per round.",
		Price = 349,
		ProductId = 0, -- ADD YOUR PRODUCT ID!
		Icon = "??",
		Color = Color3.fromRGB(150, 200, 255),
		Category = "WEAPONS",
		Type = "Product"
	},
}

-- ============================================
-- CHECK OWNERSHIP
-- ============================================

local function checkOwnership(passId)
	if not passId then return false end
	local success, owned = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return success and owned
end

-- ============================================
-- CREATE ITEM CARD
-- ============================================

local function createItemCard(itemData)
	local card = Instance.new("Frame")
	card.Name = itemData.Name
	card.BackgroundColor3 = itemData.Color
	card.BorderSizePixel = 0

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 15)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(0, 0, 0)
	cardStroke.Thickness = 3
	cardStroke.Parent = card

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.6, 0.6, 0.6))
	})
	gradient.Rotation = 90
	gradient.Parent = card

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 0, 50)
	iconLabel.Position = UDim2.new(0, 0, 0, 8)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = itemData.Icon
	iconLabel.Font = Enum.Font.FredokaOne
	iconLabel.TextSize = 40
	iconLabel.TextXAlignment = Enum.TextXAlignment.Center
	iconLabel.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0, 22)
	nameLabel.Position = UDim2.new(0.05, 0, 0, 58)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.Name
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.9, 0, 0, 40)
	descLabel.Position = UDim2.new(0.05, 0, 0, 82)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = itemData.Description
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	descLabel.TextSize = 11
	descLabel.TextWrapped = true
	descLabel.TextStrokeTransparency = 0.6
	descLabel.Parent = card

	local owned = itemData.Type == "GamePass" and checkOwnership(itemData.GamePassId)

	if owned then
		local ownedBadge = Instance.new("TextLabel")
		ownedBadge.Size = UDim2.new(0.8, 0, 0, 32)
		ownedBadge.Position = UDim2.new(0.1, 0, 1, -42)
		ownedBadge.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
		ownedBadge.Text = "? OWNED"
		ownedBadge.Font = Enum.Font.GothamBold
		ownedBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		ownedBadge.TextSize = 14
		ownedBadge.BorderSizePixel = 0
		ownedBadge.Parent = card

		local ownedCorner = Instance.new("UICorner")
		ownedCorner.CornerRadius = UDim.new(0, 10)
		ownedCorner.Parent = ownedBadge
	else
		local buyButton = Instance.new("TextButton")
		buyButton.Size = UDim2.new(0.8, 0, 0, 32)
		buyButton.Position = UDim2.new(0.1, 0, 1, -42)
		buyButton.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
		buyButton.Text = "?? " .. itemData.Price .. " R$"
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.TextSize = 15
		buyButton.BorderSizePixel = 0
		buyButton.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent = buyButton

		buyButton.MouseButton1Click:Connect(function()
			TweenService:Create(buyButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
				Size = UDim2.new(0.83, 0, 0, 34)
			}):Play()

			if itemData.Type == "GamePass" then
				print("?? Purchasing GamePass:", itemData.Name)
				pcall(function()
					MarketplaceService:PromptGamePassPurchase(player, itemData.GamePassId)
				end)
			elseif itemData.Type == "Product" then
				if itemData.ProductId == 0 then
					warn("?? Product ID not set for:", itemData.Name)
					return
				end
				print("?? Purchasing Product:", itemData.Name)
				pcall(function()
					MarketplaceService:PromptProductPurchase(player, itemData.ProductId)
				end)
			end
		end)
	end

	return card
end

-- ============================================
-- CLEAR & SWITCH TAB
-- ============================================

local function clearItemList()
	for _, child in pairs(itemList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function switchTab(tabName)
	print("?? Switching to tab:", tabName)
	currentTab = tabName

	for name, button in pairs(allTabs) do
		local colors = TAB_COLORS[name]
		if name == tabName then
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = colors.Active}):Play()
		else
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = colors.Inactive}):Play()
		end
	end

	clearItemList()

	local count = 0
	for _, itemData in ipairs(ALL_ITEMS) do
		if itemData.Category == tabName then
			createItemCard(itemData).Parent = itemList
			count = count + 1
		end
	end

	print("   ? Showing", count, "items for", tabName)
end

-- ============================================
-- TAB CLICKS
-- ============================================

gamepassTab.MouseButton1Click:Connect(function()
	switchTab("GAMEPASS")
end)

cashTab.MouseButton1Click:Connect(function()
	switchTab("CASH")
end)

weaponsTab.MouseButton1Click:Connect(function()
	switchTab("WEAPONS")
end)

-- ============================================
-- TOGGLE SHOP
-- ============================================

local function toggleShop(visible)
	if visible then
		container.Visible = true
		container.Size = UDim2.new(0, 0, 0, 0)
		container.Position = UDim2.new(0.5, 0, 0.5, 0)

		TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.6, 0, 0.7, 0),
			Position = UDim2.new(0.2, 0, 0.15, 0)
		}):Play()
	else
		TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()

		task.delay(0.3, function()
			container.Visible = false
		end)
	end
end

closeButton.MouseButton1Click:Connect(function()
	toggleShop(false)
end)

-- ============================================
-- INITIALIZE
-- ============================================

switchTab("GAMEPASS")

_G.OpenGamePassShop = toggleShop

print("? Shop loaded! (GAMEPASS, CASH, WEAPONS)")