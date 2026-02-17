local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local function dbg(hId, loc, msg, data)
	-- Debug logging (print only, no HTTP)
end

local DailyStore = DataStoreService:GetDataStore("DailyRewards_V1")
if _G.__DailyRewardHandlerLoaded then
	warn("DailyRewardHandler already loaded, skipping duplicate instance")
	return
end
_G.__DailyRewardHandlerLoaded = true

local re = RS:WaitForChild("RemoteEvents")
local getDR = re:WaitForChild("GetDailyReward")
local claimDR = re:WaitForChild("ClaimDailyReward")

local REWARDS = {
	{Day = 1, Type = "Coins", Amount = 500},
	{Day = 2, Type = "Coins", Amount = 750},
	{Day = 3, Type = "Coins", Amount = 1000},
	{Day = 4, Type = "Boost", Amount = 10},
	{Day = 5, Type = "Coins", Amount = 2500},
	{Day = 6, Type = "Boost", Amount = 20},
	{Day = 7, Type = "Coins", Amount = 5000},
}

local playerDailyData = {}
local claimInProgress = {}

local function getDayNumber()
	return math.floor(os.time() / 86400)
end

local function loadDailyData(player)
	-- Only load from DataStore ONCE per session
	if playerDailyData[player.UserId] then
		return playerDailyData[player.UserId]
	end
	
	local ok, data = pcall(function()
		return DailyStore:GetAsync("Daily_" .. player.UserId)
	end)
	if ok and data then
		playerDailyData[player.UserId] = data
		print("Daily data LOADED for", player.Name, "| Day:", data.CurrentDay, "| Streak:", data.Streak, "| LastClaim:", data.LastClaimDay)
	else
		if not ok then
			warn("DAILY LOAD FAILED for", player.Name, ":", data)
		else
			print("Daily data NEW for", player.Name, "(no saved data)")
		end
		playerDailyData[player.UserId] = {
			LastClaimDay = 0,
			Streak = 0,
			CurrentDay = 1,
		}
	end
	return playerDailyData[player.UserId]
end

local function resetDailyForTesting(player)
	if not RunService:IsStudio() then return end
	if player.UserId >= 0 then return end
	pcall(function()
		DailyStore:RemoveAsync("Daily_" .. player.UserId)
	end)
	playerDailyData[player.UserId] = {
		LastClaimDay = 0,
		Streak = 0,
		CurrentDay = 1,
	}
end

local function saveDailyData(player)
	if not playerDailyData[player.UserId] then return end
	local ok, err = pcall(function()
		DailyStore:SetAsync("Daily_" .. player.UserId, playerDailyData[player.UserId])
	end)
	if ok then
		print("Daily data SAVED for", player.Name, "| Day:", playerDailyData[player.UserId].CurrentDay, "| Streak:", playerDailyData[player.UserId].Streak)
	else
		warn("DAILY SAVE FAILED for", player.Name, ":", err)
	end
end

-- Load data when player joins
Players.PlayerAdded:Connect(function(player)
	resetDailyForTesting(player)
	loadDailyData(player)
end)

-- Also load for existing players
for _, p in pairs(Players:GetPlayers()) do
	task.spawn(function() loadDailyData(p) end)
end

getDR.OnServerInvoke = function(player)
	-- #region agent log
	dbg("H1", "DailyRewardHandler:getDR", "GetDailyReward invoked", {player=player.Name, uid=player.UserId})
	-- #endregion
	local data = loadDailyData(player)
	local today = getDayNumber()
	local claimed = (data.LastClaimDay == today)
	-- #region agent log
	dbg("H1", "DailyRewardHandler:getDR", "Returning data", {currentDay=data.CurrentDay, streak=data.Streak, claimed=claimed, lastClaimDay=data.LastClaimDay, today=today})
	-- #endregion
	
	-- Check if streak broke (missed more than 1 day)
	if data.LastClaimDay > 0 and today - data.LastClaimDay > 1 then
		data.Streak = 0
		data.CurrentDay = 1
	end
	
	-- Calculate seconds until next daily reset (next UTC midnight)
	local now = os.time()
	local nextReset = (today + 1) * 86400
	local secsLeft = math.max(0, nextReset - now)

	return {
		CurrentDay = data.CurrentDay,
		Streak = data.Streak,
		ClaimedToday = claimed,
		SecondsUntilReset = secsLeft,
	}
end

claimDR.OnServerInvoke = function(player)
	if claimInProgress[player.UserId] then
		return {Success = false, Message = "Please wait..."}
	end
	claimInProgress[player.UserId] = true

	local today = getDayNumber()
	local didClaim = false
	local dayIndex = 1
	local updatedData
	local ok, err = pcall(function()
		updatedData = DailyStore:UpdateAsync("Daily_" .. player.UserId, function(oldData)
			local data = oldData or {
				LastClaimDay = 0,
				Streak = 0,
				CurrentDay = 1,
			}
			if data.LastClaimDay > 0 and today - data.LastClaimDay > 1 then
				data.Streak = 0
				data.CurrentDay = 1
			end
			if data.LastClaimDay == today then
				return data
			end
			dayIndex = ((data.CurrentDay - 1) % 7) + 1
			data.LastClaimDay = today
			data.Streak = data.Streak + 1
			data.CurrentDay = data.CurrentDay + 1
			didClaim = true
			return data
		end)
	end)
	claimInProgress[player.UserId] = nil
	if not ok then
		warn("Daily reward update failed for", player.Name, err)
		return {Success = false, Message = "Failed to claim reward. Try again."}
	end
	playerDailyData[player.UserId] = updatedData
	if not didClaim then
		return {Success = false, Message = "Already claimed today! Come back tomorrow."}
	end

	local reward = REWARDS[dayIndex]
	
	-- Now give reward
	if reward.Type == "Coins" then
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local coins = ls:FindFirstChild("Coins")
			if coins then
				coins.Value = coins.Value + reward.Amount
			end
		end
		-- Also update PlayerDataManager
		pcall(function()
			local PDM = require(game.ServerScriptService:FindFirstChild("PlayerDataManager") or game.ServerScriptService:FindFirstChild("GameScripts"):FindFirstChild("PlayerDataManager"))
			if PDM and PDM.GetData then
				local pData = PDM.GetData(player)
				if pData then pData.Coins = (pData.Coins or 0) + reward.Amount end
			end
		end)
	elseif reward.Type == "Boost" then
		-- 2x Coins boost
		local boostFolder = player:FindFirstChild("Boosts")
		if not boostFolder then
			boostFolder = Instance.new("Folder")
			boostFolder.Name = "Boosts"
			boostFolder.Parent = player
		end
		-- Remove old boost if exists
		local oldBoost = boostFolder:FindFirstChild("CoinBoost2x")
		if oldBoost then oldBoost:Destroy() end
		
		local boost = Instance.new("NumberValue")
		boost.Name = "CoinBoost2x"
		boost.Value = reward.Amount * 60 -- minutes to seconds
		boost.Parent = boostFolder
		
		-- Timer to remove boost
		task.spawn(function()
			task.wait(reward.Amount * 60)
			if boost and boost.Parent then boost:Destroy() end
		end)
	end
	
	local msg = "Day " .. dayIndex .. ": " .. (reward.Type == "Coins" and (reward.Amount .. " Coins!") or ("2x Coins for " .. reward.Amount .. " minutes!"))
	print(player.Name, "claimed daily reward:", msg, "| Data saved via UpdateAsync")
	
	-- Also save explicitly as backup (UpdateAsync already saved, but this ensures in-memory cache matches)
	task.spawn(function()
		saveDailyData(player)
	end)
	
	return {Success = true, Message = msg}
end

Players.PlayerRemoving:Connect(function(player)
	saveDailyData(player) -- Save on leave
	playerDailyData[player.UserId] = nil
	claimInProgress[player.UserId] = nil
end)

-- Save all on shutdown (parallel saves for speed)
game:BindToClose(function()
	local threads = {}
	for _, p in pairs(Players:GetPlayers()) do
		table.insert(threads, task.spawn(function()
			saveDailyData(p)
		end))
	end
	-- Give DataStore calls time to complete
	task.wait(3)
end)

print("Daily Reward Handler loaded!")
