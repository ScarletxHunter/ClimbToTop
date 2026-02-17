-- ============================================
-- STARTER PACK SETUP COMMAND SCRIPT
-- One-time setup script to configure the StarterPack reward system
-- Place this in ServerScriptService or Workspace, run once in Studio, then delete
-- ============================================

print("🚀 Starting StarterPack Setup...")

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

-- ============================================
-- STEP 1: Create RemoteEvents Folder (if needed)
-- ============================================
local remoteEvents = RS:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = RS
	print("✅ Created RemoteEvents folder in ReplicatedStorage")
else
	print("✅ RemoteEvents folder already exists")
end

-- ============================================
-- STEP 2: Create ClaimStarterPack RemoteEvent
-- ============================================
local claimEvent = remoteEvents:FindFirstChild("ClaimStarterPack")
if not claimEvent then
	claimEvent = Instance.new("RemoteEvent")
	claimEvent.Name = "ClaimStarterPack"
	claimEvent.Parent = remoteEvents
	print("✅ Created ClaimStarterPack RemoteEvent")
else
	print("⚠️  ClaimStarterPack RemoteEvent already exists")
end

-- ============================================
-- STEP 3: Create CheckStarterPackClaim RemoteFunction
-- ============================================
local checkFunction = remoteEvents:FindFirstChild("CheckStarterPackClaim")
if not checkFunction then
	checkFunction = Instance.new("RemoteFunction")
	checkFunction.Name = "CheckStarterPackClaim"
	checkFunction.Parent = remoteEvents
	print("✅ Created CheckStarterPackClaim RemoteFunction")
else
	print("⚠️  CheckStarterPackClaim RemoteFunction already exists")
end

-- ============================================
-- STEP 4: Create StarterPackRewardHandler Script
-- ============================================
local handlerScript = SSS:FindFirstChild("StarterPackRewardHandler")
if not handlerScript then
	handlerScript = Instance.new("Script")
	handlerScript.Name = "StarterPackRewardHandler"
	handlerScript.Parent = SSS
	
	-- Add the handler code
	handlerScript.Source = [[-- ============================================
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
	-- Return cached instance if we already found it
	if PlayerDataManager then return PlayerDataManager end
	
	-- Try to find and require PlayerDataManager
	local success, result = pcall(function()
		local pdm = game.ServerScriptService:FindFirstChild("PlayerDataManager") 
			or (game.ServerScriptService:FindFirstChild("GameScripts") 
				and game.ServerScriptService.GameScripts:FindFirstChild("PlayerDataManager"))
		if pdm then
			return require(pdm)
		end
		return nil
	end)
	
	-- Cache only if successful
	if success and result then
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
]]
	
	print("✅ Created StarterPackRewardHandler script in ServerScriptService")
else
	print("⚠️  StarterPackRewardHandler script already exists")
end

print("")
print("=" .. string.rep("=", 60))
print("🎉 STARTER PACK SETUP COMPLETE!")
print("=" .. string.rep("=", 60))
print("")
print("📋 Summary:")
print("   ✅ ClaimStarterPack RemoteEvent created")
print("   ✅ CheckStarterPackClaim RemoteFunction created")
print("   ✅ StarterPackRewardHandler script created")
print("")
print("📝 Next Steps:")
print("   1. The StarterPackGui.lua already has auto-prompt functionality")
print("   2. Test the starter pack by joining the game as a new player")
print("   3. You can delete this setup script after confirming it works")
print("")
print("⚙️  To customize rewards, edit the STARTER_PACK_REWARDS table in:")
print("   ServerScriptService > StarterPackRewardHandler")
print("")
print("=" .. string.rep("=", 60))
