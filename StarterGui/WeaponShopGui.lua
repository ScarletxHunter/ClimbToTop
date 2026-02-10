-- ============================================
-- WEAPON SHOP SCRIPT (v3 - Auto-close on round start)
-- Place in: StarterGui/WeaponShopGui/LocalScript
--
-- FIXED: Shop auto-closes when round/voting starts
-- FIXED: Shop doesn't reappear after round ends
-- FIXED: Permanent weapons show OWNED + EQUIP
-- ============================================

local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent
local container = gui:WaitForChild("Container")
local header = container:WaitForChild("Header")
local closeButton = header:WaitForChild("CloseButton")
local collapseButton = header:WaitForChild("CollapseButton")
local coinsLabel = header:WaitForChild("CoinsFrame"):WaitForChild("CoinsLabel")
local cardArea = container:WaitForChild("CardArea")

print("?? Weapon Shop initializing...")

-- ============================================
-- WEAPON DATA
-- ============================================

local WEAPONS = {
	{
		Name = "Push Tool",
		Description = "Your trusty starter. Sends players flying with a force field blast!",
		Icon = "rbxassetid://6034287594",
		IconColor = Color3.fromRGB(100, 200, 255),
		Rarity = "STARTER",
		RarityColor = Color3.fromRGB(100, 150, 200),
		CoinPrice = 0,
		RobuxPrice = 0,
		ProductId = nil,
		Stats = {
			{Name = "Power", Value = 50, Max = 100, Color = Color3.fromRGB(255, 80, 80), Emoji = "?"},
			{Name = "Range", Value = 10, Max = 20, Color = Color3.fromRGB(80, 180, 255), Emoji = "??"},
			{Name = "Speed", Value = 4, Max = 10, Color = Color3.fromRGB(80, 255, 120), Emoji = "??"},
		},
		ToolName = "PushTool",
	},
	{
		Name = "Hammer",
		Description = "Massive slam! 50% more knockback with devastating ground pound.",
		Icon = "rbxassetid://6034509993",
		IconColor = Color3.fromRGB(200, 120, 50),
		Rarity = "RARE",
		RarityColor = Color3.fromRGB(255, 150, 50),
		CoinPrice = 500,
		RobuxPrice = 199,
		ProductId = 3532286297,
		Stats = {
			{Name = "Power", Value = 75, Max = 100, Color = Color3.fromRGB(255, 80, 80), Emoji = "?"},
			{Name = "Range", Value = 10, Max = 20, Color = Color3.fromRGB(80, 180, 255), Emoji = "??"},
			{Name = "Speed", Value = 3, Max = 10, Color = Color3.fromRGB(80, 255, 120), Emoji = "??"},
		},
		ToolName = "Hammer",
	},
	{
		Name = "Speed Gun",
		Description = "Temporary speed boost! 50% faster for 10 seconds.",
		Icon = "rbxassetid://6031763426",
		IconColor = Color3.fromRGB(255, 200, 100),
		Rarity = "RARE",
		RarityColor = Color3.fromRGB(255, 150, 50),
		CoinPrice = 750,
		RobuxPrice = 249,
		ProductId = 0,
		Stats = {
			{Name = "Power", Value = 0, Max = 100, Color = Color3.fromRGB(255, 80, 80), Emoji = "?"},
			{Name = "Range", Value = 0, Max = 20, Color = Color3.fromRGB(80, 180, 255), Emoji = "??"},
			{Name = "Speed", Value = 10, Max = 10, Color = Color3.fromRGB(80, 255, 120), Emoji = "??"},
		},
		ToolName = "SpeedGun",
	},
	{
		Name = "Ice Staff",
		Description = "Freeze your enemies solid for 3 seconds! Click a player to freeze them.",
		Icon = "rbxassetid://6034509993",
		IconColor = Color3.fromRGB(150, 200, 255),
		Rarity = "EPIC",
		RarityColor = Color3.fromRGB(150, 100, 255),
		CoinPrice = 1000,
		RobuxPrice = 299,
		ProductId = 3532286673,
		Stats = {
			{Name = "Power", Value = 40, Max = 100, Color = Color3.fromRGB(255, 80, 80), Emoji = "?"},
			{Name = "Range", Value = 15, Max = 20, Color = Color3.fromRGB(80, 180, 255), Emoji = "??"},
			{Name = "Speed", Value = 1, Max = 10, Color = Color3.fromRGB(80, 255, 120), Emoji = "??"},
		},
		ToolName = "IceStaff",
	},
	{
		Name = "Gravity Hammer",
		Description = "Slam creates shockwave! Pushes all nearby players with massive force.",
		Icon = "rbxassetid://6034509993",
		IconColor = Color3.fromRGB(200, 80, 200),
		Rarity = "LEGENDARY",
		RarityColor = Color3.fromRGB(255, 215, 0),
		CoinPrice = 2500,
		RobuxPrice = 499,
		ProductId = 3532287059,
		Stats = {
			{Name = "Power", Value = 90, Max = 100, Color = Color3.fromRGB(255, 80, 80), Emoji = "?"},
			{Name = "Range", Value = 18, Max = 20, Color = Color3.fromRGB(80, 180, 255), Emoji = "??"},
			{Name = "Speed", Value = 2, Max = 10, Color = Color3.fromRGB(80, 255, 120), Emoji = "??"},
		},
		ToolName = "GravityHammer",
	},
	{
		Name = "Acid Trail",
		Description = "Leave a damaging acid trail behind you for 5 seconds! Enemies take damage.",
		Icon = "rbxassetid://6034509993",
		IconColor = Color3.fromRGB(0, 255, 0),
		Rarity = "EPIC",
		RarityColor = Color3.fromRGB(0, 255, 100),
		CoinPrice = 1500,
		RobuxPrice = 0,
		ProductId = 0,
		Stats = {
			{Name = "Power", Value = 5, Max = 100, Color = Color3.fromRGB(255, 80, 80), Emoji = "?"},
			{Name = "Range", Value = 0, Max = 20, Color = Color3.fromRGB(80, 180, 255), Emoji = "??"},
			{Name = "Speed", Value = 3, Max = 10, Color = Color3.fromRGB(80, 255, 120), Emoji = "??"},
		},
		ToolName = "AcidTrail",
	},
	{
		Name = "Flight Boots",
		Description = "Fly upward for 3 seconds! Escape danger or reach high places.",
		Icon = "rbxassetid://6034509993",
		IconColor = Color3.fromRGB(135, 206, 250),
		Rarity = "EPIC",
		RarityColor = Color3.fromRGB(100, 200, 255),
		CoinPrice = 2000,
		RobuxPrice = 0,
		ProductId = 0,
		Stats = {
			{Name = "Power", Value = 0, Max = 100, Color = Color3.fromRGB(255, 80, 80), Emoji = "?"},
			{Name = "Range", Value = 0, Max = 20, Color = Color3.fromRGB(80, 180, 255), Emoji = "??"},
			{Name = "Speed", Value = 8, Max = 10, Color = Color3.fromRGB(80, 255, 120), Emoji = "??"},
		},
		ToolName = "FlightBoots",
	},
}

-- ============================================
-- STATE
-- ============================================

local ownedTools = {}
local coinWeapon = nil
local equippedWeapon = "PushTool"
local playerCoins = 0
local cardUpdaters = {}
local shopIsOpen = false

-- ============================================
-- COINS DISPLAY
-- ============================================

local function updateCoinsDisplay()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			playerCoins = coins.Value
			coinsLabel.Text = tostring(coins.Value)
		end
	end
end

local function refreshAllCards()
	for _, fn in ipairs(cardUpdaters) do
		fn()
	end
end

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local coins = leaderstats:WaitForChild("Coins", 5)
		if coins then
			updateCoinsDisplay()
			coins.Changed:Connect(function()
				updateCoinsDisplay()
				refreshAllCards()
			end)
		end
	end
end)

-- ============================================
-- LOAD STATE FROM SERVER
-- ============================================

local function loadServerState()
	local getOwned = ReplicatedStorage:FindFirstChild("GetOwnedTools")
	if getOwned and getOwned:IsA("RemoteFunction") then
		local ok, result = pcall(function() return getOwned:InvokeServer() end)
		if ok and result then
			ownedTools = result.ownedTools or {}
			coinWeapon = result.coinWeapon
			equippedWeapon = result.equipped or "PushTool"
			print("? Loaded shop state | Equipped:", equippedWeapon, "| Coin weapon:", tostring(coinWeapon))
			refreshAllCards()
		end
	end
end

-- ============================================
-- CREATE STAT BAR
-- ============================================

local function createStatBar(parent, stat, yScale)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0.88, 0, 0.05, 0)
	row.Position = UDim2.new(0.06, 0, yScale, 0)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(0.08, 0, 1, 0)
	emoji.BackgroundTransparency = 1
	emoji.Text = stat.Emoji
	emoji.TextSize = 12
	emoji.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.20, 0, 1, 0)
	label.Position = UDim2.new(0.09, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = stat.Name
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(200, 220, 255)
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local trackBg = Instance.new("Frame")
	trackBg.Size = UDim2.new(0.48, 0, 0, 8)
	trackBg.Position = UDim2.new(0.30, 0, 0.5, -4)
	trackBg.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
	trackBg.BorderSizePixel = 0
	trackBg.ClipsDescendants = true
	trackBg.Parent = row

	Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp(stat.Value / stat.Max, 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = stat.Color
	fill.BorderSizePixel = 0
	fill.Parent = trackBg

	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0.12, 0, 1, 0)
	valLabel.Position = UDim2.new(0.82, 0, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = tostring(stat.Value)
	valLabel.Font = Enum.Font.GothamBold
	valLabel.TextColor3 = stat.Color
	valLabel.TextSize = 13
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.Parent = row
end

-- ============================================
-- CREATE WEAPON CARD
-- ============================================

local function createWeaponCard(weaponData)
	local card = Instance.new("Frame")
	card.Name = weaponData.Name
	card.Size = UDim2.new(0, 280, 1, -20)
	card.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
	card.BorderSizePixel = 0
	card.ClipsDescendants = true

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

	local cardGradient = Instance.new("UIGradient")
	cardGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 35, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 22, 40))
	})
	cardGradient.Rotation = 90
	cardGradient.Parent = card

	local rarityBadge = Instance.new("Frame")
	rarityBadge.Size = UDim2.new(1, 0, 0.065, 0)
	rarityBadge.BackgroundColor3 = weaponData.RarityColor
	rarityBadge.BorderSizePixel = 0
	rarityBadge.Parent = card

	Instance.new("UICorner", rarityBadge).CornerRadius = UDim.new(0, 18)

	local badgeCover = Instance.new("Frame")
	badgeCover.Size = UDim2.new(1, 0, 0.4, 0)
	badgeCover.Position = UDim2.new(0, 0, 0.6, 0)
	badgeCover.BackgroundColor3 = weaponData.RarityColor
	badgeCover.BorderSizePixel = 0
	badgeCover.Parent = rarityBadge

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 1, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = "? " .. weaponData.Rarity .. " ?"
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarityLabel.TextSize = 13
	rarityLabel.TextStrokeTransparency = 0.5
	rarityLabel.Parent = rarityBadge

	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 80, 0.20, 0)
	iconBg.Position = UDim2.new(0.5, -40, 0.08, 0)
	iconBg.BackgroundColor3 = Color3.fromRGB(20, 35, 60)
	iconBg.BorderSizePixel = 0
	iconBg.Parent = card

	Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 15)

	local iconBgStroke = Instance.new("UIStroke")
	iconBgStroke.Color = weaponData.RarityColor
	iconBgStroke.Thickness = 3
	iconBgStroke.Parent = iconBg

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.75, 0, 0.75, 0)
	icon.Position = UDim2.new(0.125, 0, 0.125, 0)
	icon.BackgroundTransparency = 1
	icon.Image = weaponData.Icon
	icon.ImageColor3 = weaponData.IconColor
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = iconBg

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.06, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.30, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = weaponData.Name
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.88, 0, 0.10, 0)
	descLabel.Position = UDim2.new(0.06, 0, 0.37, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = weaponData.Description
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
	descLabel.TextSize = 11
	descLabel.TextWrapped = true
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = card

	local statStartY = 0.48
	for i, stat in ipairs(weaponData.Stats) do
		createStatBar(card, stat, statStartY + (i - 1) * 0.06)
	end

	local coinButton = Instance.new("TextButton")
	coinButton.Name = "CoinButton"
	coinButton.Size = UDim2.new(0.88, 0, 0.09, 0)
	coinButton.Position = UDim2.new(0.06, 0, 0.70, 0)
	coinButton.BorderSizePixel = 0
	coinButton.Font = Enum.Font.GothamBold
	coinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	coinButton.TextSize = 14
	coinButton.Parent = card

	Instance.new("UICorner", coinButton).CornerRadius = UDim.new(0, 10)

	local coinBtnStroke = Instance.new("UIStroke")
	coinBtnStroke.Name = "CoinStroke"
	coinBtnStroke.Thickness = 2
	coinBtnStroke.Parent = coinButton

	local robuxButton = Instance.new("TextButton")
	robuxButton.Name = "RobuxButton"
	robuxButton.Size = UDim2.new(0.88, 0, 0.09, 0)
	robuxButton.Position = UDim2.new(0.06, 0, 0.82, 0)
	robuxButton.BorderSizePixel = 0
	robuxButton.Font = Enum.Font.GothamBold
	robuxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	robuxButton.TextSize = 13
	robuxButton.Parent = card

	Instance.new("UICorner", robuxButton).CornerRadius = UDim.new(0, 10)

	local robuxBtnStroke = Instance.new("UIStroke")
	robuxBtnStroke.Name = "RobuxStroke"
	robuxBtnStroke.Thickness = 2
	robuxBtnStroke.Parent = robuxButton

	-- ============================================
	-- UPDATE CARD STATE
	-- ============================================

	local function updateCard()
		local ownership = ownedTools[weaponData.ToolName]
		local isPermanent = (ownership == "permanent")
		local isRental = (ownership == "rental")
		local isStarter = (ownership == "starter")
		local isEquipped = (equippedWeapon == weaponData.ToolName)

		local isLocked = false
		if coinWeapon and coinWeapon ~= weaponData.ToolName and not isPermanent then
			isLocked = true
		end

		-- PERMANENT OWNERSHIP
		if isPermanent then
			robuxButton.Visible = true
			robuxButton.Text = "?? OWNED FOREVER"
			robuxButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			robuxButton.TextColor3 = Color3.fromRGB(40, 30, 0)
			robuxBtnStroke.Color = Color3.fromRGB(200, 150, 0)

			coinButton.Visible = true
			coinButton.Position = UDim2.new(0.06, 0, 0.70, 0)
			robuxButton.Position = UDim2.new(0.06, 0, 0.82, 0)

			if isEquipped then
				coinButton.Text = "? EQUIPPED"
				coinButton.BackgroundColor3 = Color3.fromRGB(0, 140, 80)
				coinBtnStroke.Color = Color3.fromRGB(0, 80, 40)
				-- cardStroke.Color = Color3.fromRGB(0, 200, 100)
			else
				coinButton.Text = "? EQUIP"
				coinButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
				coinBtnStroke.Color = Color3.fromRGB(0, 120, 200)
				-- cardStroke.Color = Color3.fromRGB(255, 215, 0)
			end
			return
		end

		-- NON-PERMANENT
		robuxButton.Position = UDim2.new(0.06, 0, 0.82, 0)
		robuxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		coinButton.Visible = true
		robuxButton.Visible = (weaponData.RobuxPrice > 0)

		if weaponData.CoinPrice == 0 and weaponData.RobuxPrice == 0 then
			robuxButton.Visible = false
			coinButton.Position = UDim2.new(0.06, 0, 0.76, 0)
		else
			coinButton.Position = UDim2.new(0.06, 0, 0.70, 0)
		end

		if isRental or (isStarter and isEquipped) then
			coinButton.Text = "? EQUIPPED"
			coinButton.TextSize = 14
			coinButton.BackgroundColor3 = Color3.fromRGB(0, 140, 80)
			coinBtnStroke.Color = Color3.fromRGB(0, 80, 40)
			-- cardStroke.Color = Color3.fromRGB(0, 200, 100)
		elseif isLocked then
			coinButton.Text = "?? LOCKED (Bought " .. tostring(coinWeapon) .. ")"
			coinButton.TextSize = 11
			coinButton.BackgroundColor3 = Color3.fromRGB(50, 40, 50)
			coinBtnStroke.Color = Color3.fromRGB(30, 25, 35)
			-- cardStroke.Color = Color3.fromRGB(60, 50, 70)
		elseif weaponData.CoinPrice == 0 then
			coinButton.Text = "? EQUIP FREE"
			coinButton.TextSize = 14
			coinButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			coinBtnStroke.Color = Color3.fromRGB(0, 100, 200)
			-- cardStroke.Color = weaponData.RarityColor
		elseif playerCoins < weaponData.CoinPrice then
			coinButton.Text = "?? " .. weaponData.CoinPrice .. " Coins"
			coinButton.TextSize = 14
			coinButton.BackgroundColor3 = Color3.fromRGB(60, 65, 85)
			coinBtnStroke.Color = Color3.fromRGB(30, 35, 50)
			-- cardStroke.Color = Color3.fromRGB(50, 60, 90)
		else
			coinButton.Text = "?? " .. weaponData.CoinPrice .. " (1 Round)"
			coinButton.TextSize = 14
			coinButton.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
			coinBtnStroke.Color = Color3.fromRGB(0, 100, 40)
			-- cardStroke.Color = weaponData.RarityColor
		end

		if weaponData.RobuxPrice > 0 then
			robuxButton.Text = "? " .. weaponData.RobuxPrice .. " R$ (Forever)"
			robuxButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			robuxBtnStroke.Color = Color3.fromRGB(0, 120, 200)
		end
	end

	-- ============================================
	-- COIN BUTTON CLICK
	-- ============================================

	coinButton.MouseButton1Click:Connect(function()
		local ownership = ownedTools[weaponData.ToolName]

		-- Permanent weapon: tap EQUIP
		if ownership == "permanent" then
			if equippedWeapon == weaponData.ToolName then return end

			TweenService:Create(coinButton,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
				{Size = UDim2.new(0.90, 0, 0.095, 0)}
			):Play()

			coinButton.Text = "? Equipping..."

			local buyRemote = ReplicatedStorage:FindFirstChild("BuyTool")
			if buyRemote then
				print("? Equipping permanent:", weaponData.ToolName)
				buyRemote:FireServer(weaponData.ToolName, 0)
			end
			return
		end

		if ownership == "rental" then return end

		-- Locked
		if coinWeapon and coinWeapon ~= weaponData.ToolName then
			local orig = coinButton.Position
			for _ = 1, 3 do
				coinButton.Position = orig + UDim2.new(0, 5, 0, 0)
				task.wait(0.04)
				coinButton.Position = orig + UDim2.new(0, -5, 0, 0)
				task.wait(0.04)
			end
			coinButton.Position = orig
			return
		end

		-- Can't afford
		if weaponData.CoinPrice > 0 and playerCoins < weaponData.CoinPrice then
			local orig = coinButton.Position
			for _ = 1, 3 do
				coinButton.Position = orig + UDim2.new(0, 5, 0, 0)
				task.wait(0.04)
				coinButton.Position = orig + UDim2.new(0, -5, 0, 0)
				task.wait(0.04)
			end
			coinButton.Position = orig
			return
		end

		TweenService:Create(coinButton,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
			{Size = UDim2.new(0.90, 0, 0.095, 0)}
		):Play()

		coinButton.Text = "? Buying..."

		local buyRemote = ReplicatedStorage:FindFirstChild("BuyTool")
		if buyRemote then
			print("?? Buying:", weaponData.ToolName)
			buyRemote:FireServer(weaponData.ToolName, weaponData.CoinPrice)
		else
			warn("? BuyTool remote not found!")
			task.delay(1, updateCard)
		end
	end)

	-- ============================================
	-- ROBUX BUTTON CLICK
	-- ============================================

	robuxButton.MouseButton1Click:Connect(function()
		if ownedTools[weaponData.ToolName] == "permanent" then return end

		if not weaponData.ProductId or weaponData.ProductId == 0 then
			warn("?? Product ID not set for:", weaponData.Name)
			return
		end

		print("? Buying permanently:", weaponData.Name)

		TweenService:Create(robuxButton,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
			{Size = UDim2.new(0.90, 0, 0.095, 0)}
		):Play()

		pcall(function()
			MarketplaceService:PromptProductPurchase(player, weaponData.ProductId)
		end)
	end)

	table.insert(cardUpdaters, updateCard)
	updateCard()
	return card
end

-- ============================================
-- TOGGLE SHOP (with state tracking)
-- ============================================

local function forceCloseShop()
	if not shopIsOpen then return end
	shopIsOpen = false
	container.Visible = false
	print("? Weapon Shop force-closed")
end

local function toggleShop(visible)
	if visible == nil then
		visible = not shopIsOpen
	end

	if visible then
		updateCoinsDisplay()
		loadServerState()
		shopIsOpen = true
		container.Visible = true
		container.Size = UDim2.new(0, 0, 0, 0)
		container.Position = UDim2.new(0.5, 0, 0.5, 0)

		TweenService:Create(container,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0.85, 0, 0.75, 0), Position = UDim2.new(0.075, 0, 0.125, 0)}
		):Play()

		print("?? Weapon Shop opened")
	else
		shopIsOpen = false

		TweenService:Create(container,
			TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}
		):Play()

		task.delay(0.3, function()
			container.Visible = false
		end)

		print("? Weapon Shop closed")
	end
end

-- ============================================
-- BUTTONS
-- ============================================

closeButton.MouseButton1Click:Connect(function()
	toggleShop(false)
end)

collapseButton.MouseButton1Click:Connect(function()
	toggleShop(false)
end)

-- ============================================
-- AUTO-CLOSE ON ROUND/VOTING START
-- ============================================

task.spawn(function()
	local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if remoteEventsFolder then
		local timerEvent = remoteEventsFolder:FindFirstChild("TimerUpdate")
		if not timerEvent then
			timerEvent = remoteEventsFolder:WaitForChild("TimerUpdate", 10)
		end

		if timerEvent then
			timerEvent.OnClientEvent:Connect(function(timeLeft, phase)
				-- Force close shop when voting or round starts
				if phase == "Voting" or phase == "Round" or phase == "RoundOver" then
					if shopIsOpen then
						forceCloseShop()
						print("?? Weapon Shop auto-closed (phase:", phase, ")")
					end
				end
			end)
			print("? Weapon Shop auto-close listener connected")
		end
	end
end)

-- ============================================
-- CONNECT REMOTES
-- ============================================

task.spawn(function()
	loadServerState()

	local buyRemote = ReplicatedStorage:FindFirstChild("BuyTool")
	if not buyRemote then
		buyRemote = ReplicatedStorage:WaitForChild("BuyTool", 10)
	end

	if buyRemote then
		buyRemote.OnClientEvent:Connect(function(success, toolName, reason)
			if success then
				if reason == "permanent" then
					ownedTools[toolName] = "permanent"
					equippedWeapon = toolName
				elseif reason == "purchased" or reason == "reequip" or reason == "equipped" then
					if toolName ~= "PushTool" then
						ownedTools[toolName] = "rental"
						coinWeapon = toolName
					end
					equippedWeapon = toolName
				end
				print("? Now equipped:", toolName, "(" .. tostring(reason) .. ")")
			else
				if reason == "locked" then
					print("?? Locked out - already bought", coinWeapon, "this round")
				else
					warn("? Purchase failed:", toolName, reason)
				end
			end
			refreshAllCards()
		end)
		print("? BuyTool listener connected")
	else
		warn("?? BuyTool remote not found after 10s!")
	end

	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEventsFolder then
		local refreshEvt = remoteEventsFolder:FindFirstChild("RefreshShop")
		if refreshEvt then
			refreshEvt.OnClientEvent:Connect(function()
				coinWeapon = nil
				ownedTools = {}
				equippedWeapon = "PushTool"
				loadServerState()
				print("?? Shop refreshed (round reset or new purchase)")
			end)
		end

		local openShop = remoteEventsFolder:FindFirstChild("OpenToolShop")
		if openShop then
			openShop.OnClientEvent:Connect(function()
				print("?? NPC opened shop")
				toggleShop(true)
			end)
			print("? Listening for NPC")
		end
	end

	print("? Weapon Shop remotes connected")
end)

-- ============================================
-- BUILD CARDS
-- ============================================

for _, data in ipairs(WEAPONS) do
	createWeaponCard(data).Parent = cardArea
end

-- Make sure shop starts closed
container.Visible = false
shopIsOpen = false

_G.OpenWeaponShop = toggleShop

print("? Weapon Shop loaded (" .. #WEAPONS .. " weapons)")