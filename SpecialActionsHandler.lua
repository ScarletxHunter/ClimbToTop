-- ============================================
-- SPECIAL ACTIONS HANDLER (Server-Side)
-- Handles Kill All Players and Skip to Finish
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Product IDs - these should match the client-side values
-- Example: local KILL_ALL_PRODUCT_ID = 123456789
local KILL_ALL_PRODUCT_ID = 0  -- TODO: Set up dev product and add ID
local SKIP_PRODUCT_ID = 0       -- TODO: Set up dev product and add ID

-- Get or create RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local killAllEvent = remoteEvents:FindFirstChild("KillAllPlayers")
if not killAllEvent then
	killAllEvent = Instance.new("RemoteEvent")
	killAllEvent.Name = "KillAllPlayers"
	killAllEvent.Parent = remoteEvents
end

local skipEvent = remoteEvents:FindFirstChild("SkipToFinish")
if not skipEvent then
	skipEvent = Instance.new("RemoteEvent")
	skipEvent.Name = "SkipToFinish"
	skipEvent.Parent = remoteEvents
end

-- ============================================
-- KILL ALL PLAYERS FUNCTION
-- ============================================
local function killAllPlayers(requestingPlayer)
	-- Check if we're in a round
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if not gameValues then return end
	
	local gameState = gameValues:FindFirstChild("GameState")
	if not gameState or gameState.Value ~= "Playing" then
		warn("⚠️ Kill All: Not in a round")
		return
	end
	
	-- Kill all players except the one who activated it
	local killedCount = 0
	for _, eliminatedPlayer in ipairs(Players:GetPlayers()) do
		if eliminatedPlayer ~= requestingPlayer and eliminatedPlayer.Character then
			local humanoid = eliminatedPlayer.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
				killedCount = killedCount + 1
				
				-- Notify the eliminated player
				local notifyRemote = ReplicatedStorage:FindFirstChild("RemoteEvents") 
					and ReplicatedStorage.RemoteEvents:FindFirstChild("NotifyClient")
				if notifyRemote then
					notifyRemote:FireClient(eliminatedPlayer, "💀 You were eliminated!", "Another player used Kill All", 3, "error")
				end
			end
		end
	end
	
	-- Notify the purchaser with kill count
	local notifyRemote = ReplicatedStorage:FindFirstChild("RemoteEvents") 
		and ReplicatedStorage.RemoteEvents:FindFirstChild("NotifyClient")
	if notifyRemote then
		notifyRemote:FireClient(requestingPlayer, "💀 Kill All!", "Eliminated " .. killedCount .. " players!", 3, "success")
	end
	
	print(string.format("💀 %s killed %d players", requestingPlayer.Name, killedCount))
end

-- ============================================
-- SKIP TO FINISH FUNCTION
-- ============================================
local function skipToFinish(player)
	-- Check if we're in a round
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if not gameValues then return end
	
	local gameState = gameValues:FindFirstChild("GameState")
	if not gameState or gameState.Value ~= "Playing" then
		warn("⚠️ Skip to Finish: Not in a round")
		return
	end
	
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Look for End part or GamepassEnd part
	local endPart = workspace:FindFirstChild("End") or workspace:FindFirstChild("GamepassEnd")
	
	-- If not found in root, search descendants
	if not endPart then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and (obj.Name == "End" or obj.Name == "GamepassEnd") then
				endPart = obj
				break
			end
		end
	end
	
	if endPart then
		-- Teleport player to the end part
		hrp.CFrame = endPart.CFrame + Vector3.new(0, 5, 0)
		print(string.format("🏁 %s skipped to finish", player.Name))
	else
		warn(string.format("⚠️ No End/GamepassEnd part found for %s", player.Name))
	end
end

-- ============================================
-- EVENT HANDLERS (Server-side validation)
-- ============================================
-- These should ONLY be called after purchase validation
-- DO NOT enable direct server event calling in production

killAllEvent.OnServerEvent:Connect(function(player)
	-- Block direct calls - only ProcessReceipt should grant actions
	warn(string.format("⚠️ SECURITY: %s attempted Kill All without purchase!", player.Name))
end)

skipEvent.OnServerEvent:Connect(function(player)
	-- Block direct calls - only ProcessReceipt should grant actions
	warn(string.format("⚠️ SECURITY: %s attempted Skip without purchase!", player.Name))
end)

-- ============================================
-- DEV PRODUCT PURCHASE HANDLING
-- ============================================
-- IMPORTANT: This ProcessReceipt handler is provided as reference code.
-- You MUST integrate this into your existing ProcessReceipt in CoinRemotes.lua
-- to avoid overwriting the existing coin purchase handling.
--
-- Steps to integrate:
-- 1. Open CoinRemotes.lua
-- 2. Find the existing MarketplaceService.ProcessReceipt function
-- 3. Add the product ID checks below to that function
-- 4. Do NOT uncomment the line below - use the existing ProcessReceipt
-- ============================================

--[[
-- REFERENCE CODE - Integrate this into CoinRemotes.lua ProcessReceipt:

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	if receiptInfo.ProductId == KILL_ALL_PRODUCT_ID then
		-- Grant Kill All action
		killAllPlayers(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif receiptInfo.ProductId == SKIP_PRODUCT_ID then
		-- Grant Skip to Finish action
		skipToFinish(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	-- Let existing handler process other products
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
--]]

print("✅ Special Actions Handler loaded")
