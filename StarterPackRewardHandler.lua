-- ============================================
-- STARTER PACK REWARD HANDLER
-- Place in: ServerScriptService
-- ============================================

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- ============================================
-- CONFIGURATION - Easy to customize rewards
-- ============================================
local STARTER_PACK_REWARDS = {
	Coins = 5000,
	Trail = "Blue",
	Wins = 1,
}

-- ============================================
-- DATASTORE & TRACKING
-- ============================================
local StarterPackStore = DataStoreService:GetDataStore("StarterPack_V1")
local claimedPlayers = {} -- In-memory cache: {[UserId] = true}

-- Cache PlayerDataManager to avoid repeated require calls
local PlayerDataManager = nil
local function getPlayerDataManager()
	if PlayerDataManager then return PlayerDataManager end
	
	local success, result = pcall(function()
		return require(game.ServerScriptService:FindFirstChild("PlayerDataManager") 
			or game.ServerScriptService:FindFirstChild("GameScripts"):FindFirstChild("PlayerDataManager"))
	end)
	
	if success then
		PlayerDataManager = result
	end
	
	return PlayerDataManager
end

-- ============================================
-- HELPER: Load claim status from DataStore
-- ============================================
local function hasClaimedStarterPack(player)
	-- Check in-memory cache first
	if claimedPlayers[player.UserId] then
		return true
	end
	
	-- Load from DataStore
	local success, claimed = pcall(function()
		return StarterPackStore:GetAsync("Claimed_" .. player.UserId)
	end)
	
	if success and claimed then
		claimedPlayers[player.UserId] = true
		return true
	end
	
	return false
end

-- ============================================
-- HELPER: Mark player as claimed
-- ============================================
local function markAsClaimed(player)
	claimedPlayers[player.UserId] = true
	
	pcall(function()
		StarterPackStore:SetAsync("Claimed_" .. player.UserId, true)
	end)
end

-- ============================================
-- HELPER: Give rewards to player
-- ============================================
local function giveRewards(player)
	local PDM = getPlayerDataManager()
	
	-- Give Coins
	if STARTER_PACK_REWARDS.Coins and STARTER_PACK_REWARDS.Coins > 0 then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value = coins.Value + STARTER_PACK_REWARDS.Coins
			end
		end
		
		-- Also update PlayerDataManager if available
		if PDM and PDM.GetData then
			local pData = PDM.GetData(player)
			if pData then 
				pData.Coins = (pData.Coins or 0) + STARTER_PACK_REWARDS.Coins
			end
		end
	end
	
	-- Give Trail
	if STARTER_PACK_REWARDS.Trail and STARTER_PACK_REWARDS.Trail ~= "" then
		if PDM and PDM.AddTrail then
			PDM.AddTrail(player, STARTER_PACK_REWARDS.Trail)
		end
	end
	
	-- Give Wins
	if STARTER_PACK_REWARDS.Wins and STARTER_PACK_REWARDS.Wins > 0 then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local wins = leaderstats:FindFirstChild("Wins")
			if wins then
				wins.Value = wins.Value + STARTER_PACK_REWARDS.Wins
			end
		end
		
		-- Also update PlayerDataManager if available
		if PDM and PDM.GetData then
			local pData = PDM.GetData(player)
			if pData then 
				pData.Wins = (pData.Wins or 0) + STARTER_PACK_REWARDS.Wins
			end
		end
	end
end

-- ============================================
-- HELPER: Send notification to player
-- ============================================
local function notifyPlayer(player, title, message, duration, nType)
	local notifyRemote = RS:FindFirstChild("RemoteEvents") 
		and RS.RemoteEvents:FindFirstChild("NotifyClient")
	
	if notifyRemote then
		notifyRemote:FireClient(player, title, message, duration or 3, nType or "success")
	end
end

-- ============================================
-- REMOTE EVENTS SETUP
-- ============================================
local remoteEvents = RS:WaitForChild("RemoteEvents", 10)
if not remoteEvents then
	warn("⚠️ StarterPackRewardHandler: RemoteEvents folder not found!")
	return
end

-- Wait for ClaimStarterPack RemoteEvent
local claimEvent = remoteEvents:WaitForChild("ClaimStarterPack", 10)
if not claimEvent then
	warn("⚠️ StarterPackRewardHandler: ClaimStarterPack RemoteEvent not found!")
	return
end

-- Wait for CheckStarterPackClaim RemoteFunction
local checkFunction = remoteEvents:WaitForChild("CheckStarterPackClaim", 10)
if not checkFunction then
	warn("⚠️ StarterPackRewardHandler: CheckStarterPackClaim RemoteFunction not found!")
	return
end

-- ============================================
-- CLAIM HANDLER
-- ============================================
claimEvent.OnServerEvent:Connect(function(player)
	-- Check if already claimed
	if hasClaimedStarterPack(player) then
		notifyPlayer(player, "Already Claimed", "You've already claimed your starter pack!", 3, "warning")
		return
	end
	
	-- Give rewards
	giveRewards(player)
	
	-- Mark as claimed
	markAsClaimed(player)
	
	-- Notify success
	local rewardText = string.format("%d Coins, %s Trail, %d Win", 
		STARTER_PACK_REWARDS.Coins, 
		STARTER_PACK_REWARDS.Trail, 
		STARTER_PACK_REWARDS.Wins)
	notifyPlayer(player, "🎁 Starter Pack Claimed!", rewardText, 4, "success")
	
	print("✅ Starter Pack claimed by:", player.Name)
end)

-- ============================================
-- CHECK CLAIM STATUS HANDLER
-- ============================================
checkFunction.OnServerInvoke = function(player)
	return hasClaimedStarterPack(player)
end

-- ============================================
-- LOAD CLAIM STATUS ON JOIN
-- ============================================
Players.PlayerAdded:Connect(function(player)
	-- Pre-load claim status for performance
	task.spawn(function()
		hasClaimedStarterPack(player)
	end)
end)

-- Also load for existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		hasClaimedStarterPack(player)
	end)
end

print("✅ StarterPackRewardHandler loaded successfully!")
