-- ============================================
-- PLAYER DATA MANAGER - FIXED (Coins in Leaderstats)
-- Place in: ServerScriptService/PlayerDataManager
-- ============================================

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerStats_V1")

local PlayerDataManager = {}
local playerData = {} -- Cache of loaded data

-- Default stats for new players
local DEFAULT_DATA = {
	Wins = 0,
	GamesPlayed = 0,
	FastestTime = 999,
	TotalPlayTime = 0,
	Coins = 0,
}

-- ============================================
-- CREATE LEADERSTATS (FIXED - NOW INCLUDES COINS!)
-- ============================================

local function createLeaderstats(player)
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create Coins stat (FIXED - WAS MISSING!)
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	-- Create Wins stat
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats

	print("? Created leaderstats for", player.Name, "(Coins + Wins)")
	return leaderstats
end

-- Load player data
function PlayerDataManager.LoadData(player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		-- Migrate old data (add missing fields)
		if not data.Coins then
			data.Coins = 0
		end

		playerData[player.UserId] = data
		print("? Loaded data for:", player.Name)

		-- Sync to leaderstats
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local winsValue = leaderstats:FindFirstChild("Wins")
			if winsValue then
				winsValue.Value = data.Wins
			end

			-- FIXED - Sync coins too!
			local coinsValue = leaderstats:FindFirstChild("Coins")
			if coinsValue then
				coinsValue.Value = data.Coins
				print("?? Synced coins to leaderstats:", data.Coins)
			end
		end
	else
		-- New player or load failed
		playerData[player.UserId] = table.clone(DEFAULT_DATA)
		print("?? Created new data for:", player.Name)
	end

	return playerData[player.UserId]
end

-- Save player data
function PlayerDataManager.SaveData(player)
	if not playerData[player.UserId] then return end

	-- Sync from leaderstats before saving
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then
			playerData[player.UserId].Coins = coinsValue.Value
		end
	end

	local success, err = pcall(function()
		PlayerDataStore:SetAsync("Player_" .. player.UserId, playerData[player.UserId])
	end)

	if success then
		print("?? Saved data for:", player.Name)
	else
		warn("?? Failed to save data for:", player.Name, err)
	end
end

-- Get player data
function PlayerDataManager.GetData(player)
	return playerData[player.UserId] or DEFAULT_DATA
end

-- Update stat
function PlayerDataManager.UpdateStat(player, statName, value)
	if not playerData[player.UserId] then return end
	playerData[player.UserId][statName] = value
end

-- Increment stat
function PlayerDataManager.IncrementStat(player, statName, amount)
	if not playerData[player.UserId] then return end
	playerData[player.UserId][statName] = playerData[player.UserId][statName] + (amount or 1)
end

-- Record a win
function PlayerDataManager.RecordWin(player, time)
	if not playerData[player.UserId] then return end

	local data = playerData[player.UserId]
	data.Wins = data.Wins + 1

	-- Update fastest time if better
	if time < data.FastestTime then
		data.FastestTime = time
		print("?? New record for", player.Name .. ":", time, "seconds!")
	end

	-- UPDATE LEADERSTATS
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local winsValue = leaderstats:FindFirstChild("Wins")
		if winsValue then
			winsValue.Value = data.Wins
		end
	end

	PlayerDataManager.SaveData(player)
end

-- Record game played
function PlayerDataManager.RecordGame(player)
	if not playerData[player.UserId] then return end
	playerData[player.UserId].GamesPlayed = playerData[player.UserId].GamesPlayed + 1
	PlayerDataManager.SaveData(player)
end

-- Get all players sorted by wins
function PlayerDataManager.GetTopPlayers()
	local sortedPlayers = {}

	for _, player in pairs(Players:GetPlayers()) do
		local data = PlayerDataManager.GetData(player)
		table.insert(sortedPlayers, {
			Player = player,
			Wins = data.Wins,
			FastestTime = data.FastestTime,
		})
	end

	-- Sort by wins (highest first)
	table.sort(sortedPlayers, function(a, b)
		return a.Wins > b.Wins
	end)

	return sortedPlayers
end

-- ============================================
-- COIN FUNCTIONS (FIXED - Updates leaderstats!)
-- ============================================

-- Add coins
function PlayerDataManager.AddCoins(player, amount)
	if not playerData[player.UserId] then return end

	-- Safety check
	if not playerData[player.UserId].Coins then
		playerData[player.UserId].Coins = 0
	end

	playerData[player.UserId].Coins = playerData[player.UserId].Coins + amount

	-- UPDATE LEADERSTATS (THIS WAS MISSING!)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then
			coinsValue.Value = playerData[player.UserId].Coins
		end
	end

	print("??", player.Name, "earned", amount, "coins! Total:", playerData[player.UserId].Coins)
end

-- Remove coins
function PlayerDataManager.RemoveCoins(player, amount)
	if not playerData[player.UserId] then return false end

	-- Safety check
	if not playerData[player.UserId].Coins then
		playerData[player.UserId].Coins = 0
	end

	local data = playerData[player.UserId]
	if data.Coins >= amount then
		data.Coins = data.Coins - amount

		-- UPDATE LEADERSTATS (THIS WAS MISSING!)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coinsValue = leaderstats:FindFirstChild("Coins")
			if coinsValue then
				coinsValue.Value = data.Coins
			end
		end

		return true
	end
	return false
end

-- Get coins
function PlayerDataManager.GetCoins(player)
	if not playerData[player.UserId] then return 0 end

	-- Safety check
	if not playerData[player.UserId].Coins then
		playerData[player.UserId].Coins = 0
	end

	return playerData[player.UserId].Coins
end

-- ============================================
-- INITIALIZATION
-- ============================================

-- Initialize system
Players.PlayerAdded:Connect(function(player)
	-- Create leaderstats FIRST (now includes Coins!)
	createLeaderstats(player)

	-- Then load data (which will sync to leaderstats)
	PlayerDataManager.LoadData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerDataManager.SaveData(player)
	playerData[player.UserId] = nil
end)

-- Auto-save every 5 minutes
task.spawn(function()
	while task.wait(300) do
		for _, player in pairs(Players:GetPlayers()) do
			PlayerDataManager.SaveData(player)
		end
		print("?? Auto-saved all player data")
	end
end)

return PlayerDataManager