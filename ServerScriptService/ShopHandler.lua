-- ============================================
-- SHOP HANDLER (v7 - FIXED Robux weapons + Reset bug)
-- Place in: ServerScriptService/ShopHandler
--
-- FIXED: Robux weapons NEVER auto-equip (notification only)
-- FIXED: Reset in lobby = PushTool ONLY (nothing else)
-- FIXED: Reset in round = coin weapon or chosen weapon only
-- FIXED: RegisterPermanentWeapon does NOT call giveWeapon
-- FIXED: LoadPermanentWeapons does NOT equip anything
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))

print("?? Shop Handler loading...")

-- ============================================
-- STATE
-- ============================================

local playerCoinWeapon = {}       -- Coin weapon bought THIS round
local playerEquipped = {}         -- Currently equipped weapon name
local playerPermanentTools = {}   -- Robux weapons (permanent, never auto-equip)
local playerChosenWeapon = {}     -- Manually chosen weapon from shop
local isRoundActive = false

local TOOL_PRICES = {
	PushTool = 0,
	Hammer = 500,
	SpeedGun = 750,
	IceStaff = 1000,
	GravityHammer = 2500,
	AcidTrail = 1500,
	FlightBoots = 2000
}

local ALL_WEAPONS = {"PushTool", "Hammer", "SpeedGun", "IceStaff", "GravityHammer", "AcidTrail", "FlightBoots"}

-- ============================================
-- REMOTE EVENTS
-- ============================================

local function getOrCreate(className, name, parent)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end
	local new = Instance.new(className)
	new.Name = name
	new.Parent = parent
	print("   ? Created", name)
	return new
end

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local staleBuyTool = remoteEvents:FindFirstChild("BuyTool")
if staleBuyTool then staleBuyTool:Destroy() end
local BuyToolEvent = getOrCreate("RemoteEvent", "BuyTool", ReplicatedStorage)
local GetOwnedToolsFunction = getOrCreate("RemoteFunction", "GetOwnedTools", ReplicatedStorage)
local RefreshShopEvent = getOrCreate("RemoteEvent", "RefreshShop", remoteEvents)

local NotifyEvent = getOrCreate("RemoteEvent", "ShowNotification", remoteEvents)

-- ============================================
-- HELPERS
-- ============================================

local function getToolsFolder()
	return ReplicatedStorage:FindFirstChild("Tools")
		or ServerStorage:FindFirstChild("Tools")
		or ServerStorage
end

local function clearAllWeapons(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character

	for _, weaponName in ipairs(ALL_WEAPONS) do
		if backpack then
			local tool = backpack:FindFirstChild(weaponName)
			if tool then tool:Destroy() end
		end
		if character then
			local tool = character:FindFirstChild(weaponName)
			if tool then tool:Destroy() end
		end
	end
end

local function giveSingleWeapon(player, toolName)
	-- IMPORTANT: Clears ALL weapons first, then gives ONLY one
	clearAllWeapons(player)

	local toolsFolder = getToolsFolder()
	local tool = toolsFolder:FindFirstChild(toolName)
	if tool then
		local clone = tool:Clone()
		clone.Parent = player.Backpack
		playerEquipped[player.UserId] = toolName
		print("   ? Equipped", toolName, "for", player.Name)
		return true
	else
		warn("   ?? Tool not found:", toolName)
		return false
	end
end

-- What weapon should this player have RIGHT NOW
local function getCorrectWeapon(player)
	local uid = player.UserId

	-- LOBBY: Always PushTool, no exceptions
	if not isRoundActive then
		return "PushTool"
	end

	-- ROUND PRIORITY:
	-- 1. Coin weapon (spent coins this round — highest priority)
	if playerCoinWeapon[uid] then
		return playerCoinWeapon[uid]
	end

	-- 2. Manually chosen weapon from shop (tapped EQUIP on a permanent weapon)
	if playerChosenWeapon[uid] then
		local permTools = playerPermanentTools[uid]
		if permTools and permTools[playerChosenWeapon[uid]] then
			return playerChosenWeapon[uid]
		end
	end

	-- 3. Default: PushTool (Robux weapons do NOT auto-equip)
	return "PushTool"
end

-- ============================================
-- INITIALIZE PLAYER
-- ============================================

local function initializePlayer(player)
	local uid = player.UserId
	playerCoinWeapon[uid] = nil
	playerEquipped[uid] = "PushTool"
	playerChosenWeapon[uid] = nil

	giveSingleWeapon(player, "PushTool")
	print("?? Initialized", player.Name, "with PushTool")
end

-- ============================================
-- GET OWNED TOOLS (client queries this)
-- ============================================

GetOwnedToolsFunction.OnServerInvoke = function(player)
	local uid = player.UserId
	local permTools = playerPermanentTools[uid] or {}
	local coinWpn = playerCoinWeapon[uid]
	local equipped = playerEquipped[uid] or "PushTool"

	local owned = {}
	for toolName, _ in pairs(permTools) do
		owned[toolName] = "permanent"
	end
	owned["PushTool"] = "starter"
	if coinWpn then
		owned[coinWpn] = "rental"
	end

	return {
		ownedTools = owned,
		coinWeapon = coinWpn,
		equipped = equipped,
	}
end

-- ============================================
-- BUY TOOL
-- ============================================

BuyToolEvent.OnServerEvent:Connect(function(player, toolName, price)
	local uid = player.UserId
	print("??", player.Name, "wants to buy:", toolName)

	if not TOOL_PRICES[toolName] then
		warn("   ?? Invalid tool:", toolName)
		BuyToolEvent:FireClient(player, false, toolName, "invalid")
		return
	end

	-- PushTool: always free, just equip
	if toolName == "PushTool" then
		playerChosenWeapon[uid] = nil
		giveSingleWeapon(player, "PushTool")
		BuyToolEvent:FireClient(player, true, toolName, "equipped")
		return
	end

	-- Permanent weapon: player tapped EQUIP in shop
	local permTools = playerPermanentTools[uid]
	if permTools and permTools[toolName] then
		playerChosenWeapon[uid] = toolName
		giveSingleWeapon(player, toolName)
		BuyToolEvent:FireClient(player, true, toolName, "permanent")
		print("   ?", player.Name, "chose to equip permanent:", toolName)
		return
	end

	-- Already bought a different coin weapon this round
	local existingCoin = playerCoinWeapon[uid]
	if existingCoin and existingCoin ~= toolName then
		warn("   ?? Already bought", existingCoin, "this round!")
		BuyToolEvent:FireClient(player, false, toolName, "locked")
		return
	end

	-- Re-equip same coin weapon
	if existingCoin == toolName then
		giveSingleWeapon(player, toolName)
		BuyToolEvent:FireClient(player, true, toolName, "reequip")
		return
	end

	-- New coin purchase
	local playerCoins = PlayerDataManager.GetCoins(player)
	local toolPrice = TOOL_PRICES[toolName]

	print("   Player coins:", playerCoins, "| Tool price:", toolPrice)

	if playerCoins < toolPrice then
		warn("   ?? Not enough coins:", playerCoins, "<", toolPrice)
		BuyToolEvent:FireClient(player, false, toolName, "broke")
		return
	end

	local success = PlayerDataManager.RemoveCoins(player, toolPrice)
	if not success then
		BuyToolEvent:FireClient(player, false, toolName, "error")
		return
	end

	playerCoinWeapon[uid] = toolName
	playerChosenWeapon[uid] = nil
	giveSingleWeapon(player, toolName)

	if _G.UpdatePlayerCoins then
		_G.UpdatePlayerCoins(player, 0)
	end

	BuyToolEvent:FireClient(player, true, toolName, "purchased")
	print("   ?", player.Name, "purchased:", toolName, "for", toolPrice, "coins (LOCKED)")
end)

-- ============================================
-- ROUND START
-- ============================================

_G.EquipPurchasedWeapon = function(player)
	if not player then return end
	isRoundActive = true

	local weapon = getCorrectWeapon(player)
	giveSingleWeapon(player, weapon)

	pcall(function() RefreshShopEvent:FireClient(player) end)
	print("?? Round start: gave", player.Name, "their weapon:", weapon)
end

-- ============================================
-- ROUND END
-- ============================================

_G.ResetCoinPurchases = function(player)
	if not player then return end
	isRoundActive = false

	local uid = player.UserId
	playerCoinWeapon[uid] = nil
	playerEquipped[uid] = nil
	playerChosenWeapon[uid] = nil

	giveSingleWeapon(player, "PushTool")

	pcall(function() RefreshShopEvent:FireClient(player) end)
	print("?? Round end: reset", player.Name, "? PushTool")
end

-- ============================================
-- PERMANENT WEAPON HOOKS (Robux purchases)
-- NEVER auto-equip. Just register + notify + refresh shop.
-- ============================================

_G.RegisterPermanentWeapon = function(player, toolName)
	if not player or not toolName then return end
	local uid = player.UserId

	if not playerPermanentTools[uid] then
		playerPermanentTools[uid] = {}
	end
	playerPermanentTools[uid][toolName] = true

	-- DO NOT EQUIP — just notify and refresh
	print("   ?? Registered permanent weapon", toolName, "for", player.Name, "— NOT auto-equipped")

	pcall(function()
		NotifyEvent:FireClient(player, "You unlocked " .. toolName .. "! ?? Equip it from the Weapon Shop!")
	end)

	pcall(function()
		RefreshShopEvent:FireClient(player)
	end)

	print("??", player.Name, "permanently owns:", toolName)
end

_G.LoadPermanentWeapons = function(player, toolsTable)
	if not player or not toolsTable then return end
	playerPermanentTools[player.UserId] = toolsTable
	-- Just load data — DO NOT equip anything
	print("   ?? Loaded permanent weapons for", player.Name, "— NOT auto-equipped")
end

-- ============================================
-- PLAYER LIFECYCLE
-- ============================================

Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	initializePlayer(player)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)

		local correctWeapon = getCorrectWeapon(player)

		local backpack = player:FindFirstChild("Backpack")
		if not backpack then return end

		-- Count how many weapons they have (should be exactly 1)
		local weaponCount = 0
		for _, weaponName in ipairs(ALL_WEAPONS) do
			if backpack:FindFirstChild(weaponName) then weaponCount += 1 end
			if character and character:FindFirstChild(weaponName) then weaponCount += 1 end
		end

		-- If they have the correct weapon and ONLY that weapon, we're good
		if weaponCount == 1 then
			local hasCorrect = backpack:FindFirstChild(correctWeapon) or 
				(character and character:FindFirstChild(correctWeapon))
			if hasCorrect then
				print("?? Respawn:", player.Name, "already has", correctWeapon, "— skipping")
				return
			end
		end

		-- Wrong weapon or multiple weapons — fix it
		clearAllWeapons(player)
		local toolsFolder = getToolsFolder()
		local tool = toolsFolder:FindFirstChild(correctWeapon)
		if tool then
			local clone = tool:Clone()
			clone.Parent = backpack
			playerEquipped[player.UserId] = correctWeapon
		end

		print("?? Respawn:", player.Name, "?", correctWeapon, "(round:", tostring(isRoundActive), ")")
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local uid = player.UserId
	playerCoinWeapon[uid] = nil
	playerEquipped[uid] = nil
	playerPermanentTools[uid] = nil
	playerChosenWeapon[uid] = nil
end)

for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function() initializePlayer(player) end)
end

print("? Shop Handler loaded!")
print("   Tools:", table.concat((function()
	local t = {}
	for name, price in pairs(TOOL_PRICES) do
		table.insert(t, name .. "=" .. price)
	end
	return t
end)(), ", "))