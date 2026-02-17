-- ============================================
-- SPECIAL ACTIONS COMMAND BAR GENERATOR
-- ============================================
-- This script generates:
-- 1. Kill All Players ImageButton (💀)
-- 2. Skip to Finish ImageButton (🏁)
-- 3. Fixes StarterPack gamepass requirement
-- 4. Updates server handlers with ProcessReceipt integration
--
-- Instructions:
-- 1. Run this script ONCE in the command bar
-- 2. Set your Dev Product IDs in the generated scripts
-- 3. Delete this generator script when done
-- ============================================

print("============================================")
print("SPECIAL ACTIONS GENERATOR - Starting...")
print("============================================")

-- ============================================
-- STEP 1: CREATE CLIENT-SIDE GUI
-- ============================================
print("\n[1/4] Creating SpecialActionsGui in StarterGui...")

-- Delete existing GUI if present
local oldGui = game.StarterGui:FindFirstChild("SpecialActionsGui")
if oldGui then
	oldGui:Destroy()
	print("  ✓ Removed old SpecialActionsGui")
end

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpecialActionsGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game.StarterGui

-- ============================================
-- KILL ALL PLAYERS BUTTON (💀)
-- ============================================
local killAllBtn = Instance.new("ImageButton")
killAllBtn.Name = "KillAllButton"
killAllBtn.Size = UDim2.new(0, 70, 0, 70)
killAllBtn.Position = UDim2.new(1, -90, 0.5, -100)
killAllBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
killAllBtn.BorderSizePixel = 0
killAllBtn.Image = ""
killAllBtn.Visible = false
killAllBtn.Parent = screenGui

local killCorner = Instance.new("UICorner")
killCorner.CornerRadius = UDim.new(0, 16)
killCorner.Parent = killAllBtn

local killStroke = Instance.new("UIStroke")
killStroke.Color = Color3.fromRGB(255, 255, 255)
killStroke.Thickness = 3
killStroke.Parent = killAllBtn

-- Kill All icon
local killIcon = Instance.new("TextLabel")
killIcon.Size = UDim2.new(1, 0, 0.6, 0)
killIcon.Position = UDim2.new(0, 0, 0.1, 0)
killIcon.BackgroundTransparency = 1
killIcon.Text = "💀"
killIcon.Font = Enum.Font.GothamBold
killIcon.TextSize = 32
killIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
killIcon.Parent = killAllBtn

-- Kill All text
local killText = Instance.new("TextLabel")
killText.Size = UDim2.new(1, 0, 0.3, 0)
killText.Position = UDim2.new(0, 0, 0.65, 0)
killText.BackgroundTransparency = 1
killText.Text = "KILL ALL"
killText.Font = Enum.Font.GothamBlack
killText.TextSize = 9
killText.TextColor3 = Color3.fromRGB(255, 255, 255)
killText.TextWrapped = true
killText.Parent = killAllBtn

print("  ✓ Kill All button created")

-- ============================================
-- SKIP TO FINISH BUTTON (🏁)
-- ============================================
local skipBtn = Instance.new("ImageButton")
skipBtn.Name = "SkipToFinishButton"
skipBtn.Size = UDim2.new(0, 70, 0, 70)
skipBtn.Position = UDim2.new(1, -90, 0.5, 0)
skipBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
skipBtn.BorderSizePixel = 0
skipBtn.Image = ""
skipBtn.Visible = false
skipBtn.Parent = screenGui

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 16)
skipCorner.Parent = skipBtn

local skipStroke = Instance.new("UIStroke")
skipStroke.Color = Color3.fromRGB(255, 255, 255)
skipStroke.Thickness = 3
skipStroke.Parent = skipBtn

-- Skip icon
local skipIcon = Instance.new("TextLabel")
skipIcon.Size = UDim2.new(1, 0, 0.6, 0)
skipIcon.Position = UDim2.new(0, 0, 0.1, 0)
skipIcon.BackgroundTransparency = 1
skipIcon.Text = "🏁"
skipIcon.Font = Enum.Font.GothamBold
skipIcon.TextSize = 32
skipIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
skipIcon.Parent = skipBtn

-- Skip text
local skipText = Instance.new("TextLabel")
skipText.Size = UDim2.new(1, 0, 0.3, 0)
skipText.Position = UDim2.new(0, 0, 0.65, 0)
skipText.BackgroundTransparency = 1
skipText.Text = "SKIP"
skipText.Font = Enum.Font.GothamBlack
skipText.TextSize = 11
skipText.TextColor3 = Color3.fromRGB(255, 255, 255)
skipText.TextWrapped = true
skipText.Parent = skipBtn

print("  ✓ Skip button created")

-- ============================================
-- CLIENT-SIDE SCRIPT
-- ============================================
local clientScript = Instance.new("LocalScript")
clientScript.Name = "SpecialActionsScript"
clientScript.Source = [[-- ============================================
-- SPECIAL ACTIONS GUI - CLIENT SCRIPT
-- ============================================

-- ⚙️ CONFIGURATION - Set your Dev Product IDs here
local KILL_ALL_PRODUCT_ID = 0  -- Replace with your Kill All product ID
local SKIP_PRODUCT_ID = 0       -- Replace with your Skip product ID

local Players = game:GetService("Players")
local MPS = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local screenGui = script.Parent
local killAllBtn = screenGui:WaitForChild("KillAllButton")
local skipBtn = screenGui:WaitForChild("SkipToFinishButton")

-- ============================================
-- GAME STATE VISIBILITY CONTROL
-- ============================================
local function updateButtonVisibility()
	local gameValues = RS:FindFirstChild("GameValues")
	if not gameValues then return end
	
	local gameState = gameValues:FindFirstChild("GameState")
	if not gameState then return end
	
	local isPlaying = (gameState.Value == "Playing")
	killAllBtn.Visible = isPlaying
	skipBtn.Visible = isPlaying
end

-- Watch for game state changes
task.spawn(function()
	local gameValues = RS:WaitForChild("GameValues", 30)
	if not gameValues then return end
	
	local gameState = gameValues:WaitForChild("GameState", 10)
	if not gameState then return end
	
	-- Initial check
	updateButtonVisibility()
	
	-- Listen for changes
	gameState.Changed:Connect(function()
		updateButtonVisibility()
	end)
end)

-- ============================================
-- KILL ALL BUTTON ACTION
-- ============================================
killAllBtn.MouseButton1Click:Connect(function()
	if KILL_ALL_PRODUCT_ID <= 0 then
		if _G.Notify then
			_G.Notify("⚠️ Not Available", "This feature is not yet configured.", 3, "warning")
		end
		return
	end
	
	-- Prompt for dev product purchase
	local success, err = pcall(function()
		MPS:PromptProductPurchase(plr, KILL_ALL_PRODUCT_ID)
	end)
	
	if not success then
		warn("Failed to prompt Kill All purchase:", err)
	end
end)

-- ============================================
-- SKIP TO FINISH BUTTON ACTION
-- ============================================
skipBtn.MouseButton1Click:Connect(function()
	if SKIP_PRODUCT_ID <= 0 then
		if _G.Notify then
			_G.Notify("⚠️ Not Available", "This feature is not yet configured.", 3, "warning")
		end
		return
	end
	
	-- Prompt for dev product purchase
	local success, err = pcall(function()
		MPS:PromptProductPurchase(plr, SKIP_PRODUCT_ID)
	end)
	
	if not success then
		warn("Failed to prompt Skip purchase:", err)
	end
end)

print("✅ Special Actions GUI loaded")
]]
clientScript.Parent = screenGui

print("  ✓ Client script embedded")
print("✅ SpecialActionsGui created successfully!")

-- ============================================
-- STEP 2: CREATE SERVER-SIDE HANDLER
-- ============================================
print("\n[2/4] Creating SpecialActionsHandler in ServerScriptService...")

-- Delete existing handler if present
local oldHandler = game.ServerScriptService:FindFirstChild("SpecialActionsHandler")
if oldHandler then
	oldHandler:Destroy()
	print("  ✓ Removed old SpecialActionsHandler")
end

local serverHandler = Instance.new("Script")
serverHandler.Name = "SpecialActionsHandler"
serverHandler.Source = [[-- ============================================
-- SPECIAL ACTIONS HANDLER (Server-Side)
-- Handles Kill All Players and Skip to Finish
-- ============================================

-- ⚙️ CONFIGURATION - Set your Dev Product IDs here (must match client-side)
local KILL_ALL_PRODUCT_ID = 0  -- Replace with your Kill All product ID
local SKIP_PRODUCT_ID = 0       -- Replace with your Skip product ID

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- ============================================
-- HELPER: Send notification to player
-- ============================================
local function notifyPlayer(player, title, message, duration, nType)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return end
	
	local notifyRemote = remoteEvents:FindFirstChild("NotifyClient")
	if notifyRemote then
		notifyRemote:FireClient(player, title, message, duration or 3, nType or "success")
	end
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
		notifyPlayer(requestingPlayer, "⚠️ Not Available", "Must be in a round to use this!", 3, "warning")
		return
	end
	
	-- Kill all players except the one who activated it
	local killedCount = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= requestingPlayer and player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
				killedCount = killedCount + 1
			end
		end
	end
	
	-- Notify the purchaser
	notifyPlayer(requestingPlayer, "💀 Kill All Activated!", 
		string.format("Eliminated %d player%s!", killedCount, killedCount == 1 and "" or "s"), 
		3, "success")
	
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
		notifyPlayer(player, "⚠️ Not Available", "Must be in a round to use this!", 3, "warning")
		return
	end
	
	local character = player.Character
	if not character then 
		notifyPlayer(player, "⚠️ Error", "Character not found!", 3, "error")
		return 
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then 
		notifyPlayer(player, "⚠️ Error", "Character not loaded properly!", 3, "error")
		return 
	end
	
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
		notifyPlayer(player, "🏁 Skipped to Finish!", "You've been teleported to the end!", 3, "success")
		print(string.format("🏁 %s skipped to finish", player.Name))
	else
		notifyPlayer(player, "⚠️ Error", "No finish line found on this map!", 3, "error")
		warn(string.format("⚠️ No End/GamepassEnd part found for %s", player.Name))
	end
end

-- ============================================
-- INTEGRATE WITH COINREMOTES PROCESSRECEIPT
-- ============================================
-- This function will be called by the updated CoinRemotes.lua ProcessReceipt
_G.ProcessSpecialActionPurchase = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	if receiptInfo.ProductId == KILL_ALL_PRODUCT_ID and KILL_ALL_PRODUCT_ID > 0 then
		killAllPlayers(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif receiptInfo.ProductId == SKIP_PRODUCT_ID and SKIP_PRODUCT_ID > 0 then
		skipToFinish(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	-- Not a special action product
	return nil
end

print("✅ Special Actions Handler loaded")
print("⚙️  Set KILL_ALL_PRODUCT_ID and SKIP_PRODUCT_ID in this script")
]]
serverHandler.Parent = game.ServerScriptService

print("  ✓ Server handler created")
print("✅ SpecialActionsHandler created successfully!")

-- ============================================
-- STEP 3: UPDATE COINREMOTES.LUA PROCESSRECEIPT
-- ============================================
print("\n[3/4] Updating CoinRemotes.lua ProcessReceipt...")

local coinRemotes = game.ServerScriptService:FindFirstChild("CoinRemotes")
if coinRemotes then
	local source = coinRemotes.Source
	
	-- Check if already updated
	if source:find("ProcessSpecialActionPurchase") then
		print("  ⚠️  CoinRemotes.lua already has ProcessSpecialActionPurchase integration")
	else
		-- Find the ProcessReceipt function and add integration
		local processReceiptPattern = "MarketplaceService%.ProcessReceipt = function%(receiptInfo%)"
		
		if source:find(processReceiptPattern) then
			-- Insert the special actions check before the coin products loop
			local newSource = source:gsub(
				"(MarketplaceService%.ProcessReceipt = function%(receiptInfo%)%s+local player = Players:GetPlayerByUserId%(receiptInfo%.PlayerId%)%s+if not player then return Enum%.ProductPurchaseDecision%.NotProcessedYet end)",
				[[%1
	
	-- Check for Special Actions purchases first
	if _G.ProcessSpecialActionPurchase then
		local result = _G.ProcessSpecialActionPurchase(receiptInfo)
		if result then return result end
	end]]
			)
			
			coinRemotes.Source = newSource
			print("  ✓ CoinRemotes.lua ProcessReceipt updated with special actions integration")
		else
			print("  ⚠️  Could not find ProcessReceipt function pattern in CoinRemotes.lua")
			print("  ℹ️  You may need to manually integrate ProcessSpecialActionPurchase")
		end
	end
else
	warn("  ⚠️  CoinRemotes.lua not found in ServerScriptService!")
	print("  ℹ️  You'll need to manually integrate the ProcessReceipt handler")
end

-- ============================================
-- STEP 4: FIX STARTERPACK GAMEPASS CHECK
-- ============================================
print("\n[4/4] Fixing StarterPackRewardHandler gamepass check...")

local starterPackHandler = game.ServerScriptService:FindFirstChild("StarterPackRewardHandler")
if starterPackHandler then
	local source = starterPackHandler.Source
	
	-- Check if already has gamepass check
	if source:find("UserOwnsGamePassAsync") and source:find("1708836892") then
		print("  ⚠️  StarterPackRewardHandler already has gamepass check")
	else
		-- Add gamepass configuration at the top
		local newSource = source:gsub(
			"(local STARTER_PACK_REWARDS = {)",
			[[-- ⚙️ GAMEPASS CONFIGURATION
local STARTERPACK_GAMEPASS_ID = 1708836892  -- Starter Pack gamepass

%1]]
		)
		
		-- Update the claim handler to check gamepass ownership
		newSource = newSource:gsub(
			"(claimEvent%.OnServerEvent:Connect%(function%(player%)%s+)%-%- Check if already claimed",
			[[%1-- Check gamepass ownership FIRST
	local ownsGamepass = false
	pcall(function()
		local MPS = game:GetService("MarketplaceService")
		ownsGamepass = MPS:UserOwnsGamePassAsync(player.UserId, STARTERPACK_GAMEPASS_ID)
	end)
	
	if not ownsGamepass then
		notifyPlayer(player, "⚠️ Gamepass Required", "You need the Starter Pack gamepass!", 3, "error")
		return
	end
	
	-- Check if already claimed]]
		)
		
		starterPackHandler.Source = newSource
		print("  ✓ StarterPackRewardHandler updated with gamepass requirement")
	end
else
	warn("  ⚠️  StarterPackRewardHandler not found in ServerScriptService!")
	print("  ℹ️  You'll need to manually add gamepass checking")
end

-- ============================================
-- COMPLETION
-- ============================================
print("\n============================================")
print("✅ SPECIAL ACTIONS GENERATOR - COMPLETE!")
print("============================================")
print("\n📋 NEXT STEPS:")
print("1. Set your Dev Product IDs in:")
print("   - StarterGui.SpecialActionsGui.SpecialActionsScript")
print("   - ServerScriptService.SpecialActionsHandler")
print("\n2. Create Dev Products in Roblox:")
print("   - Kill All Players (💀)")
print("   - Skip to Finish (🏁)")
print("\n3. Test in-game:")
print("   - Buttons appear during 'Playing' state")
print("   - Purchases work correctly")
print("   - StarterPack requires gamepass ownership")
print("\n4. Delete this generator script")
print("============================================")
