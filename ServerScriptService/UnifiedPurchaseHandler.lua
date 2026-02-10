-- ============================================
-- UNIFIED PURCHASE HANDLER (v2 - FIXED)
-- Place in: ServerScriptService/UnifiedPurchaseHandler
--
-- FIXED: Does NOT put weapons directly in backpack
-- FIXED: Uses _G.RegisterPermanentWeapon (ShopHandler controls equipping)
-- FIXED: Only loads permanent weapons ONCE on first join, not every respawn
-- FIXED: Robux weapon purchases register through ShopHandler
-- ============================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local permanentWeaponsStore = DataStoreService:GetDataStore("PermanentWeapons_v1")

print("?? Unified Purchase Handler loading...")

-- ============================================
-- ENSURE REMOTE EVENTS FOLDER EXISTS
-- ============================================

local function getOrCreateRemoteEvents()
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = ReplicatedStorage
		print("? Created RemoteEvents folder")
	end
	return remoteEvents
end

local function getOrCreateNotifyEvent()
	local remoteEvents = getOrCreateRemoteEvents()

	local notifyEvent = remoteEvents:FindFirstChild("NotifyPurchase")
	if not notifyEvent then
		notifyEvent = Instance.new("RemoteEvent")
		notifyEvent.Name = "NotifyPurchase"
		notifyEvent.Parent = remoteEvents
		print("? Created NotifyPurchase RemoteEvent")
	end

	return notifyEvent
end

local NotifyPurchaseEvent = getOrCreateNotifyEvent()

-- ============================================
-- ALL PRODUCTS DATABASE
-- ============================================

local PRODUCTS = {
	-- COIN PACKS
	[3532194043] = {
		Type = "Coins",
		Name = "Small Coin Pack",
		Amount = 500
	},
	[3532194379] = {
		Type = "Coins",
		Name = "Medium Coin Pack",
		Amount = 1200
	},
	[3532194611] = {
		Type = "Coins",
		Name = "Large Coin Pack",
		Amount = 2750
	},
	[3532194827] = {
		Type = "Coins",
		Name = "Mega Coin Pack",
		Amount = 5500
	},
	[3532195036] = {
		Type = "Coins",
		Name = "Ultra Coin Pack",
		Amount = 12000
	},

	-- WEAPONS (PERMANENT)
	[3532286297] = {
		Type = "Weapon",
		Name = "Hammer",
		ToolName = "Hammer"
	},
	[3532286673] = {
		Type = "Weapon",
		Name = "Ice Staff",
		ToolName = "IceStaff"
	},
	[3532287059] = {
		Type = "Weapon",
		Name = "Gravity Hammer",
		ToolName = "GravityHammer"
	},
}

-- Track which players have already been initialized (prevents re-loading on every respawn)
local playersInitialized = {}

-- ============================================
-- GIVE COINS TO PLAYER
-- ============================================

local function giveCoins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = coins.Value + amount
			print("?? Gave", amount, "coins to", player.Name, "| New total:", coins.Value)
			return true
		end
	end
	warn("? Failed to give coins - leaderstats not found")
	return false
end

-- ============================================
-- SAVE PERMANENT WEAPON
-- ============================================

local function savePermanentWeapon(userId, toolName)
	local success, err = pcall(function()
		local key = "Player_" .. userId
		local data = permanentWeaponsStore:GetAsync(key) or {}

		data[toolName] = true
		permanentWeaponsStore:SetAsync(key, data)
		print("?? Saved permanent weapon:", toolName, "for user:", userId)
	end)

	if not success then
		warn("? Failed to save permanent weapon:", err)
	end

	return success
end

-- ============================================
-- LOAD PERMANENT WEAPONS
-- ============================================

local function loadPermanentWeapons(userId)
	local success, data = pcall(function()
		local key = "Player_" .. userId
		return permanentWeaponsStore:GetAsync(key) or {}
	end)

	if success then
		print("? Loaded permanent weapons for user:", userId)
		return data
	else
		warn("? Failed to load permanent weapons:", data)
		return {}
	end
end

-- ============================================
-- REGISTER WEAPON THROUGH SHOPHANDLER
-- Does NOT put weapons directly in backpack!
-- ShopHandler decides when/if to equip
-- ============================================

local function registerWeaponWithShopHandler(player, toolName)
	-- Wait for ShopHandler to be ready
	local attempts = 0
	while not _G.RegisterPermanentWeapon and attempts < 20 do
		task.wait(0.5)
		attempts += 1
	end

	if _G.RegisterPermanentWeapon then
		_G.RegisterPermanentWeapon(player, toolName)
		print("? Registered", toolName, "with ShopHandler for", player.Name)
		return true
	else
		warn("?? ShopHandler not ready - could not register", toolName)
		return false
	end
end

-- ============================================
-- LOAD AND REGISTER ALL PERMANENT WEAPONS (once on join)
-- ============================================

local function loadAndRegisterWeapons(player)
	-- Wait for ShopHandler to be ready
	local attempts = 0
	while not _G.LoadPermanentWeapons and attempts < 20 do
		task.wait(0.5)
		attempts += 1
	end

	print("?? Checking permanent weapons for", player.Name)
	local permanentWeapons = loadPermanentWeapons(player.UserId)

	-- Tell ShopHandler about ALL permanent weapons (just data, no equipping)
	if _G.LoadPermanentWeapons then
		_G.LoadPermanentWeapons(player, permanentWeapons)
	end

	-- Register each weapon individually (sends notification, refreshes shop)
	local count = 0
	for toolName, owned in pairs(permanentWeapons) do
		if owned then
			-- Use RegisterPermanentWeapon which does NOT auto-equip
			if _G.RegisterPermanentWeapon then
				_G.RegisterPermanentWeapon(player, toolName)
			end
			count += 1
		end
	end

	if count > 0 then
		print("? Registered", count, "permanent weapon(s) for", player.Name, "— NOT auto-equipped")
	else
		print("?? No permanent weapons for", player.Name)
	end
end

-- ============================================
-- PROCESS RECEIPT (UNIFIED!)
-- ============================================

local function processReceipt(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local purchaseId = receiptInfo.PurchaseId

	print("????????????????????????????????????????")
	print("?? PROCESSING PURCHASE")
	print("   User ID:", userId)
	print("   Product ID:", productId)
	print("   Purchase ID:", purchaseId)
	print("????????????????????????????????????????")

	local productData = PRODUCTS[productId]
	if not productData then
		warn("?? Unknown product ID:", productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then
		warn("? Player not found for userId:", userId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print("?? Product Type:", productData.Type)
	print("?? Product Name:", productData.Name)

	-- ==================== HANDLE COIN PACKS ====================
	if productData.Type == "Coins" then
		print("?? Processing coin pack purchase...")

		local success = giveCoins(player, productData.Amount)
		if not success then
			warn("? Failed to give coins!")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		print("?? Sending notification to client...")
		pcall(function()
			NotifyPurchaseEvent:FireClient(player, productData.Name, true, "??")
		end)

		print("? Coin pack purchase complete!")
		print("????????????????????????????????????????")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- ==================== HANDLE WEAPONS ====================
	if productData.Type == "Weapon" then
		print("?? Processing weapon purchase...")

		-- Save to DataStore FIRST
		print("?? Saving permanent weapon ownership...")
		local saved = savePermanentWeapon(userId, productData.ToolName)
		if not saved then
			warn("? Failed to save weapon ownership!")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Register with ShopHandler (does NOT auto-equip)
		print("?? Registering weapon with ShopHandler...")
		registerWeaponWithShopHandler(player, productData.ToolName)

		-- Send notification
		print("?? Sending notification to client...")
		pcall(function()
			NotifyPurchaseEvent:FireClient(player, productData.Name, true, "??")
		end)

		print("? Weapon purchase complete! Player can equip from Weapon Shop.")
		print("????????????????????????????????????????")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	warn("?? Unknown product type:", productData.Type)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ============================================
-- SET CALLBACK
-- ============================================

MarketplaceService.ProcessReceipt = processReceipt
print("? ProcessReceipt callback registered")

-- ============================================
-- REMOTE FUNCTION: GET PERMANENT WEAPONS
-- ============================================

local getOwnedPermanent = ReplicatedStorage:FindFirstChild("GetOwnedPermanentTools")
if not getOwnedPermanent then
	getOwnedPermanent = Instance.new("RemoteFunction")
	getOwnedPermanent.Name = "GetOwnedPermanentTools"
	getOwnedPermanent.Parent = ReplicatedStorage
	print("? Created GetOwnedPermanentTools RemoteFunction")
end

getOwnedPermanent.OnServerInvoke = function(player)
	local permanentWeapons = loadPermanentWeapons(player.UserId)
	print("?? Sending permanent weapons to", player.Name)
	return permanentWeapons
end

-- ============================================
-- PLAYER JOIN: Load permanent weapons ONCE
-- NOT on every respawn!
-- ============================================

Players.PlayerAdded:Connect(function(player)
	-- Wait for character to load first time
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	task.wait(1.5) -- Wait for ShopHandler to initialize first

	-- Only load once per player session
	if not playersInitialized[player.UserId] then
		playersInitialized[player.UserId] = true
		loadAndRegisterWeapons(player)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	playersInitialized[player.UserId] = nil
end)

-- Handle players already in game (Studio restart)
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		if not playersInitialized[player.UserId] then
			playersInitialized[player.UserId] = true
			task.wait(1.5)
			loadAndRegisterWeapons(player)
		end
	end)
end

-- ============================================
-- STARTUP SUMMARY
-- ============================================

print("????????????????????????????????????????")
print("? Unified Purchase Handler ready!")
print("????????????????????????????????????????")
print("?? Registered products:")

local coinPackCount = 0
local weaponCount = 0

for productId, data in pairs(PRODUCTS) do
	if data.Type == "Coins" then
		coinPackCount = coinPackCount + 1
		print("   ?? " .. data.Name .. " (" .. data.Amount .. " coins) - ID: " .. productId)
	elseif data.Type == "Weapon" then
		weaponCount = weaponCount + 1
		print("   ?? " .. data.Name .. " - ID: " .. productId)
	end
end

print("????????????????????????????????????????")
print("?? Total: " .. coinPackCount .. " coin packs, " .. weaponCount .. " weapons")
print("????????????????????????????????????????")