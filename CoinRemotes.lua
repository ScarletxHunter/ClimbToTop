-- ============================================
-- COIN REMOTES - FIXED: Includes coin purchase remotes
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))

-- ============================================
-- UPDATE COINS REMOTE
-- ============================================

local UpdateCoinsEvent = Instance.new("RemoteEvent")
UpdateCoinsEvent.Name = "UpdateCoins"
UpdateCoinsEvent.Parent = ReplicatedStorage

local GetCoinsFunction = Instance.new("RemoteFunction")
GetCoinsFunction.Name = "GetCoins"
GetCoinsFunction.Parent = ReplicatedStorage

GetCoinsFunction.OnServerInvoke = function(player)
	return PlayerDataManager.GetCoins(player)
end

-- Sync coins to client
local function syncCoins(player)
	local coins = PlayerDataManager.GetCoins(player)
	UpdateCoinsEvent:FireClient(player, coins)
end


-- ============================================
-- COIN PRODUCTS (DevProducts for buying coins with Robux)
-- SET YOUR DEVELOPER PRODUCT IDS HERE
-- ============================================

local COIN_PRODUCTS = {
	{ProductId = 3534986084, CoinsAmount = 500, DisplayName = "500 Coins", RobuxPrice = 49},
	{ProductId = 3534986160, CoinsAmount = 1500, DisplayName = "1,500 Coins", RobuxPrice = 99},
	{ProductId = 3534986278, CoinsAmount = 5000, DisplayName = "5,000 Coins", RobuxPrice = 249},
	{ProductId = 3534986360, CoinsAmount = 15000, DisplayName = "15,000 Coins", RobuxPrice = 499},
}

-- ============================================
-- COIN PURCHASE REMOTES
-- ============================================

local GetCoinProducts = Instance.new("RemoteFunction")
GetCoinProducts.Name = "GetCoinProducts"
GetCoinProducts.Parent = ReplicatedStorage

local BuyCoinsEvent = Instance.new("RemoteEvent")
BuyCoinsEvent.Name = "BuyCoinsEvent"
BuyCoinsEvent.Parent = ReplicatedStorage

GetCoinProducts.OnServerInvoke = function(player)
	return COIN_PRODUCTS
end

BuyCoinsEvent.OnServerEvent:Connect(function(player, productIndex)
	local product = COIN_PRODUCTS[productIndex]
	if not product then
		warn("? Invalid product index:", productIndex)
		return
	end

	if product.ProductId and product.ProductId > 0 then
		-- Prompt developer product purchase
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, product.ProductId)
		end)
	else
		warn("?? Product ID not set for:", product.DisplayName)
	end
end)

-- Handle developer product receipts
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	for _, product in ipairs(COIN_PRODUCTS) do
		if product.ProductId == receiptInfo.ProductId then
			PlayerDataManager.AddCoins(player, product.CoinsAmount)
			PlayerDataManager.SaveData(player)

			-- Sync to client
			syncCoins(player)

			print("??", player.Name, "purchased", product.DisplayName, "(DevProduct)")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Sync on join
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	syncCoins(player)
end)

-- Public functions for other scripts
_G.UpdatePlayerCoins = function(player, amount)
	PlayerDataManager.AddCoins(player, amount)
	syncCoins(player)
end

_G.SyncPlayerCoins = function(player)
	syncCoins(player)
end

print("? Coin Remotes initialized (with purchase system)")