-- ============================================
-- COIN SHOP GUI SCRIPT (With Your Product IDs)
-- Place in: StarterGui/CoinShopGui/LocalScript
-- ============================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local container = gui:WaitForChild("Container")
local closeButton = container:WaitForChild("Header"):WaitForChild("CloseButton")
local coinPackList = container:WaitForChild("CoinPackList")

print("?? Coin Shop initializing...")

-- ============================================
-- COIN PACKS (YOUR PRODUCT IDs!)
-- ============================================

local coinPacks = {
	{
		Name = "Small Pack",
		Coins = 500,
		Price = 50,
		ProductId = 3532194043,
		Icon = "??",
		Color = Color3.fromRGB(0, 180, 255),
		Bonus = ""
	},
	{
		Name = "Medium Pack",
		Coins = 1200,
		Price = 100,
		ProductId = 3532194379,
		Icon = "??",
		Color = Color3.fromRGB(0, 200, 255),
		Bonus = "+20% Bonus!"
	},
	{
		Name = "Large Pack",
		Coins = 2750,
		Price = 200,
		ProductId = 3532194611,
		Icon = "??",
		Color = Color3.fromRGB(0, 220, 255),
		Bonus = "+37% Bonus!"
	},
	{
		Name = "Mega Pack",
		Coins = 5500,
		Price = 350,
		ProductId = 3532194827,
		Icon = "??",
		Color = Color3.fromRGB(100, 200, 255),
		Bonus = "+57% Bonus!"
	},
	{
		Name = "Ultra Pack",
		Coins = 12000,
		Price = 600,
		ProductId = 3532195036,
		Icon = "??",
		Color = Color3.fromRGB(150, 150, 255),
		Bonus = "+100% Bonus!"
	},
}

-- ============================================
-- CREATE COIN PACK CARD
-- ============================================

local function createCoinPackCard(packData)
	local card = Instance.new("Frame")
	card.Name = packData.Name
	card.Size = UDim2.new(0.95, 0, 0, 140)
	card.BackgroundColor3 = packData.Color
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
		ColorSequenceKeypoint.new(0, packData.Color),
		ColorSequenceKeypoint.new(1, Color3.new(packData.Color.R * 0.6, packData.Color.G * 0.6, packData.Color.B * 0.6))
	})
	gradient.Rotation = 90
	gradient.Parent = card

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0, 15, 0.5, -30)
	icon.BackgroundTransparency = 1
	icon.Text = packData.Icon
	icon.Font = Enum.Font.FredokaOne
	icon.TextSize = 50
	icon.Parent = card

	-- Pack Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 150, 0, 30)
	nameLabel.Position = UDim2.new(0, 85, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = packData.Name
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 20
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = card

	-- Coins Amount
	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Size = UDim2.new(0, 150, 0, 25)
	coinsLabel.Position = UDim2.new(0, 85, 0, 50)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "?? " .. tostring(packData.Coins) .. " Coins"
	coinsLabel.Font = Enum.Font.Gotham
	coinsLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
	coinsLabel.TextSize = 16
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Parent = card

	-- Bonus Badge (if exists)
	if packData.Bonus ~= "" then
		local bonusBadge = Instance.new("TextLabel")
		bonusBadge.Size = UDim2.new(0, 110, 0, 22)
		bonusBadge.Position = UDim2.new(0, 85, 0, 80)
		bonusBadge.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
		bonusBadge.Text = packData.Bonus
		bonusBadge.Font = Enum.Font.GothamBold
		bonusBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		bonusBadge.TextSize = 12
		bonusBadge.BorderSizePixel = 0
		bonusBadge.Parent = card

		local bonusCorner = Instance.new("UICorner")
		bonusCorner.CornerRadius = UDim.new(0, 6)
		bonusCorner.Parent = bonusBadge

		local bonusStroke = Instance.new("UIStroke")
		bonusStroke.Color = Color3.fromRGB(0, 0, 0)
		bonusStroke.Thickness = 2
		bonusStroke.Parent = bonusBadge
	end

	-- Buy Button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 140, 0, 50)
	buyButton.Position = UDim2.new(1, -155, 0.5, -25)
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	buyButton.Text = "?? BUY - " .. packData.Price .. " R$"
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 18
	buyButton.BorderSizePixel = 0
	buyButton.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = buyButton

	local btnGradient = Instance.new("UIGradient")
	btnGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 220, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 80))
	})
	btnGradient.Rotation = 90
	btnGradient.Parent = buyButton

	-- Purchase Logic
	buyButton.MouseButton1Click:Connect(function()
		print("?? Purchasing:", packData.Name, "- Product ID:", packData.ProductId)

		-- Button click animation
		TweenService:Create(
			buyButton,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
			{Size = UDim2.new(0, 145, 0, 52)}
		):Play()

		-- Prompt purchase
		local success, err = pcall(function()
			MarketplaceService:PromptProductPurchase(player, packData.ProductId)
		end)

		if not success then
			warn("? Purchase prompt failed:", err)
		end
	end)

	return card
end

-- ============================================
-- POPULATE SHOP
-- ============================================

local function setupShop()
	for _, packData in ipairs(coinPacks) do
		local card = createCoinPackCard(packData)
		card.Parent = coinPackList
	end
	print("? Created", #coinPacks, "coin pack cards")
end

-- ============================================
-- TOGGLE SHOP
-- ============================================

local function toggleShop(visible)
	if visible == nil then
		visible = not container.Visible
	end

	container.Visible = visible

	if visible then
		container.Size = UDim2.new(0, 0, 0, 0)
		container.Position = UDim2.new(0.5, 0, 0.5, 0)

		TweenService:Create(
			container,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{
				Size = UDim2.new(0.6, 0, 0.75, 0),
				Position = UDim2.new(0.2, 0, 0.125, 0)
			}
		):Play()

		print("?? Coin Shop opened")
	else
		print("? Coin Shop closed")
	end
end

-- ============================================
-- CLOSE BUTTON
-- ============================================

closeButton.MouseButton1Click:Connect(function()
	print("? Close button clicked")
	toggleShop(false)
end)

-- ============================================
-- INITIALIZE
-- ============================================

setupShop()

-- Expose globally
_G.OpenCoinShop = toggleShop

print("? Coin Shop GUI loaded with", #coinPacks, "products")