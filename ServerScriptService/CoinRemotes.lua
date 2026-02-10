-- ============================================
-- COIN REMOTES - Setup communication
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get PlayerDataManager
local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))

-- Create RemoteEvent for updates
local UpdateCoinsEvent = Instance.new("RemoteEvent")
UpdateCoinsEvent.Name = "UpdateCoins"
UpdateCoinsEvent.Parent = ReplicatedStorage

-- Create RemoteFunction to get coins
local GetCoinsFunction = Instance.new("RemoteFunction")
GetCoinsFunction.Name = "GetCoins"
GetCoinsFunction.Parent = ReplicatedStorage

GetCoinsFunction.OnServerInvoke = function(player)
	return PlayerDataManager.GetCoins(player)
end

-- Function to sync coins to client
local function syncCoins(player)
	local coins = PlayerDataManager.GetCoins(player)
	UpdateCoinsEvent:FireClient(player, coins)
end

-- Sync coins when player joins
Players.PlayerAdded:Connect(function(player)
	task.wait(2) -- Wait for data to load
	syncCoins(player)
end)

-- Public function to update and sync
_G.UpdatePlayerCoins = function(player, amount)
	PlayerDataManager.AddCoins(player, amount)
	syncCoins(player)
end

print("? Coin Remotes initialized")