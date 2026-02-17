-- ============================================
-- PLAYER DATA MANAGER - FULL with trails, coins, DataStore
-- Place in: ServerScriptService > GameScripts > PlayerDataManager (ModuleScript)
-- ============================================

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerStats_V4")

local PlayerDataManager = {}
local playerData = {}

local DEFAULT_DATA = {
	Wins = 0,
	GamesPlayed = 0,
	FastestTime = 999,
	TotalPlayTime = 0,
	Coins = 0,
	OwnedTrails = {},         -- { RedTrail = true, BlueTrail = true }
	PermanentTrails = {},     -- { RainbowTrail = true } (robux purchases)
	EquippedTrail = "",
}

-- ============================================
-- LOAD / SAVE
-- ============================================

function PlayerDataManager.LoadData(player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		-- Migrate missing fields
		for key, defaultValue in pairs(DEFAULT_DATA) do
			if data[key] == nil then
				data[key] = defaultValue
			end
		end
		playerData[player.UserId] = data
		print("? Loaded data for:", player.Name)
	else
		playerData[player.UserId] = {}
		for key, val in pairs(DEFAULT_DATA) do
			if type(val) == "table" then
				playerData[player.UserId][key] = {}
			else
				playerData[player.UserId][key] = val
			end
		end
		print("?? Created new data for:", player.Name)
	end

	-- Create leaderstats (for BOTH new and returning players)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local winsVal = Instance.new("IntValue")
	winsVal.Name = "Wins"
	winsVal.Value = playerData[player.UserId].Wins or 0
	winsVal.Parent = ls

	local coinsVal = Instance.new("IntValue")
	coinsVal.Name = "Coins"
	coinsVal.Value = playerData[player.UserId].Coins or 0
	coinsVal.Parent = ls

	print("?? Leaderstats created | Wins:", winsVal.Value, "| Coins:", coinsVal.Value)

	return playerData[player.UserId]
end

function PlayerDataManager.SaveData(player)
	if not playerData[player.UserId] then return end

	local success, err = pcall(function()
		PlayerDataStore:SetAsync("Player_" .. player.UserId, playerData[player.UserId])
	end)

	if success then
		print("?? Saved data for:", player.Name)
	else
		warn("? Failed to save data for:", player.Name, err)
	end
end

function PlayerDataManager.GetData(player)
	return playerData[player.UserId] or DEFAULT_DATA
end

-- ============================================
-- STATS
-- ============================================

function PlayerDataManager.UpdateStat(player, statName, value)
	if not playerData[player.UserId] then return end
	playerData[player.UserId][statName] = value
end

function PlayerDataManager.IncrementStat(player, statName, amount)
	if not playerData[player.UserId] then return end
	playerData[player.UserId][statName] = (playerData[player.UserId][statName] or 0) + (amount or 1)
end

function PlayerDataManager.RecordWin(player, time)
	if not playerData[player.UserId] then return end
	local data = playerData[player.UserId]
	data.Wins = (data.Wins or 0) + 1

	if time < (data.FastestTime or 999) then
		data.FastestTime = time
		print("?? New record for", player.Name .. ":", time, "seconds!")
	end

	PlayerDataManager.SaveData(player)
end

function PlayerDataManager.RecordGame(player)
	if not playerData[player.UserId] then return end
	playerData[player.UserId].GamesPlayed = (playerData[player.UserId].GamesPlayed or 0) + 1
	PlayerDataManager.SaveData(player)
end

-- ============================================
-- COINS
-- ============================================

function PlayerDataManager.AddCoins(player, amount)
	if not playerData[player.UserId] then return end
	playerData[player.UserId].Coins = (playerData[player.UserId].Coins or 0) + amount
	print("??", player.Name, "earned", amount, "coins! Total:", playerData[player.UserId].Coins)
	-- Sync leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then local cv = ls:FindFirstChild("Coins") if cv then cv.Value = playerData[player.UserId].Coins end end
end

function PlayerDataManager.RemoveCoins(player, amount)
	if not playerData[player.UserId] then return false end
	local data = playerData[player.UserId]
	data.Coins = data.Coins or 0
	if data.Coins >= amount then
		data.Coins = data.Coins - amount
		-- Sync leaderstats
		local ls = player:FindFirstChild("leaderstats")
		if ls then local cv = ls:FindFirstChild("Coins") if cv then cv.Value = data.Coins end end
		return true
	end
	return false
end


function PlayerDataManager.GetCoins(player)
	if not playerData[player.UserId] then return 0 end
	return playerData[player.UserId].Coins or 0
end

-- ============================================
-- TRAILS
-- ============================================

function PlayerDataManager.OwnsTrail(player, trailName)
	if not playerData[player.UserId] then return false end
	local data = playerData[player.UserId]

	-- Check permanent trails first (robux)
	if data.PermanentTrails and data.PermanentTrails[trailName] then
		return true
	end

	-- Check regular owned trails (coin)
	if data.OwnedTrails and data.OwnedTrails[trailName] then
		return true
	end

	return false
end

function PlayerDataManager.AddTrail(player, trailName)
	if not playerData[player.UserId] then return end
	if not playerData[player.UserId].OwnedTrails then
		playerData[player.UserId].OwnedTrails = {}
	end
	playerData[player.UserId].OwnedTrails[trailName] = true
	print("??", player.Name, "now owns trail:", trailName)
end

function PlayerDataManager.AddPermanentTrail(player, trailName)
	if not playerData[player.UserId] then return end
	if not playerData[player.UserId].PermanentTrails then
		playerData[player.UserId].PermanentTrails = {}
	end
	playerData[player.UserId].PermanentTrails[trailName] = true

	-- Also add to OwnedTrails so it shows up
	if not playerData[player.UserId].OwnedTrails then
		playerData[player.UserId].OwnedTrails = {}
	end
	playerData[player.UserId].OwnedTrails[trailName] = true

	print("??", player.Name, "now permanently owns trail:", trailName)
end

function PlayerDataManager.IsPermanentTrail(player, trailName)
	if not playerData[player.UserId] then return false end
	local data = playerData[player.UserId]
	return data.PermanentTrails and data.PermanentTrails[trailName] == true
end

function PlayerDataManager.GetEquippedTrail(player)
	if not playerData[player.UserId] then return "" end
	return playerData[player.UserId].EquippedTrail or ""
end

function PlayerDataManager.SetEquippedTrail(player, trailName)
	if not playerData[player.UserId] then return end
	playerData[player.UserId].EquippedTrail = trailName or ""
end

-- Reset coin trails (called each round)
-- Keeps permanent (robux) trails, removes coin trails
function PlayerDataManager.ResetCoinTrails(player)
	if not playerData[player.UserId] then return end
	local data = playerData[player.UserId]

	local newOwned = {}

	-- Keep only permanent trails
	if data.PermanentTrails then
		for trailName, _ in pairs(data.PermanentTrails) do
			newOwned[trailName] = true
		end
	end

	data.OwnedTrails = newOwned

	-- If equipped trail was a coin trail (not permanent), unequip it
	local equipped = data.EquippedTrail or ""
	if equipped ~= "" then
		if not (data.PermanentTrails and data.PermanentTrails[equipped]) then
			data.EquippedTrail = ""
		end
	end
end

-- ============================================
-- LEADERBOARD
-- ============================================

function PlayerDataManager.GetTopPlayers()
	local sortedPlayers = {}
	for _, player in pairs(Players:GetPlayers()) do
		local data = PlayerDataManager.GetData(player)
		table.insert(sortedPlayers, {
			Player = player,
			Wins = data.Wins or 0,
			FastestTime = data.FastestTime or 999,
		})
	end
	table.sort(sortedPlayers, function(a, b)
		return a.Wins > b.Wins
	end)
	return sortedPlayers
end

-- ============================================
-- INITIALIZATION
-- ============================================

Players.PlayerAdded:Connect(function(player)
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

-- Save all on game close
game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		PlayerDataManager.SaveData(player)
	end
end)

return PlayerDataManager