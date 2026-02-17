-- ============================================
-- SPECIAL ACTION BUTTONS GUI
-- Kill All Players & Skip to Finish Line
-- ============================================

local Players = game:GetService("Players")
local MPS = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")

-- Product IDs for dev products (these need to be set up in Roblox Studio)
-- Replace these with actual dev product IDs from your game
local KILL_ALL_PRODUCT_ID = 0  -- TODO: Set up dev product and add ID here
local SKIP_PRODUCT_ID = 0       -- TODO: Set up dev product and add ID here

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpecialActionsGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============================================
-- KILL ALL PLAYERS BUTTON
-- ============================================
local killAllBtn = Instance.new("ImageButton")
killAllBtn.Name = "KillAllButton"
killAllBtn.Size = UDim2.new(0, 70, 0, 70)
killAllBtn.Position = UDim2.new(1, -90, 0.5, -100)
killAllBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
killAllBtn.BorderSizePixel = 0
killAllBtn.Image = ""  -- You can add an image asset ID here
killAllBtn.Visible = false  -- Only visible during match
killAllBtn.Parent = screenGui

local killCorner = Instance.new("UICorner")
killCorner.CornerRadius = UDim.new(0, 16)
killCorner.Parent = killAllBtn

local killStroke = Instance.new("UIStroke")
killStroke.Color = Color3.fromRGB(255, 255, 255)
killStroke.Thickness = 3
killStroke.Parent = killAllBtn

-- Kill All icon/label
local killLabel = Instance.new("TextLabel")
killLabel.Size = UDim2.new(1, 0, 0.6, 0)
killLabel.Position = UDim2.new(0, 0, 0.1, 0)
killLabel.BackgroundTransparency = 1
killLabel.Text = "💀"
killLabel.Font = Enum.Font.GothamBold
killLabel.TextSize = 32
killLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
killLabel.Parent = killAllBtn

local killText = Instance.new("TextLabel")
killText.Size = UDim2.new(1, 0, 0.3, 0)
killText.Position = UDim2.new(0, 0, 0.65, 0)
killText.BackgroundTransparency = 1
killText.Text = "Kill All"
killText.Font = Enum.Font.GothamBlack
killText.TextSize = 11
killText.TextColor3 = Color3.fromRGB(255, 255, 255)
killText.TextWrapped = true
killText.Parent = killAllBtn

-- ============================================
-- SKIP TO FINISH LINE BUTTON
-- ============================================
local skipBtn = Instance.new("ImageButton")
skipBtn.Name = "SkipToFinishButton"
skipBtn.Size = UDim2.new(0, 70, 0, 70)
skipBtn.Position = UDim2.new(1, -90, 0.5, 10)
skipBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
skipBtn.BorderSizePixel = 0
skipBtn.Image = ""  -- You can add an image asset ID here
skipBtn.Visible = false  -- Only visible during match
skipBtn.Parent = screenGui

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 16)
skipCorner.Parent = skipBtn

local skipStroke = Instance.new("UIStroke")
skipStroke.Color = Color3.fromRGB(255, 255, 255)
skipStroke.Thickness = 3
skipStroke.Parent = skipBtn

-- Skip icon/label
local skipLabel = Instance.new("TextLabel")
skipLabel.Size = UDim2.new(1, 0, 0.6, 0)
skipLabel.Position = UDim2.new(0, 0, 0.1, 0)
skipLabel.BackgroundTransparency = 1
skipLabel.Text = "🏁"
skipLabel.Font = Enum.Font.GothamBold
skipLabel.TextSize = 32
skipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
skipLabel.Parent = skipBtn

local skipText = Instance.new("TextLabel")
skipText.Size = UDim2.new(1, 0, 0.3, 0)
skipText.Position = UDim2.new(0, 0, 0.65, 0)
skipText.BackgroundTransparency = 1
skipText.Text = "Skip"
skipText.Font = Enum.Font.GothamBlack
skipText.TextSize = 11
skipText.TextColor3 = Color3.fromRGB(50, 50, 50)
skipText.TextWrapped = true
skipText.Parent = skipBtn

-- ============================================
-- GAME STATE TRACKING
-- ============================================
-- Show/hide buttons based on game state
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
-- REMOTE EVENTS
-- ============================================
-- Get or create RemoteEvents for actions
local remoteEvents = RS:WaitForChild("RemoteEvents", 30)
if not remoteEvents then
	warn("⚠️ RemoteEvents folder not found!")
	return
end

local killAllEvent = remoteEvents:FindFirstChild("KillAllPlayers")
local skipEvent = remoteEvents:FindFirstChild("SkipToFinish")

-- ============================================
-- BUTTON ACTIONS
-- ============================================
-- Kill All Players button
killAllBtn.MouseButton1Click:Connect(function()
	-- Show confirmation dialog
	local confirmText = "Kill all players in the match?\n\nThis will cost Robux!"
	
	if _G.Confirm then
		_G.Confirm("💀 Kill All Players?", confirmText, function(confirmed)
			if confirmed then
				-- Prompt for dev product purchase
				if KILL_ALL_PRODUCT_ID > 0 then
					pcall(function()
						MPS:PromptProductPurchase(plr, KILL_ALL_PRODUCT_ID)
					end)
				else
					-- If no product ID set, just fire the event (for testing)
					if killAllEvent then
						killAllEvent:FireServer()
					else
						warn("⚠️ KillAllPlayers RemoteEvent not found!")
					end
					
					if _G.Notify then
						_G.Notify("💀 Kill All!", "All players eliminated!", 3, "success")
					end
				end
			end
		end)
	else
		-- No confirm dialog available, just prompt
		if KILL_ALL_PRODUCT_ID > 0 then
			pcall(function()
				MPS:PromptProductPurchase(plr, KILL_ALL_PRODUCT_ID)
			end)
		else
			-- For testing without product
			if killAllEvent then
				killAllEvent:FireServer()
			else
				warn("⚠️ KillAllPlayers RemoteEvent not found!")
			end
		end
	end
end)

-- Skip to Finish Line button
skipBtn.MouseButton1Click:Connect(function()
	-- Show confirmation dialog
	local confirmText = "Skip to the finish line?\n\nThis will cost Robux!"
	
	if _G.Confirm then
		_G.Confirm("🏁 Skip to Finish?", confirmText, function(confirmed)
			if confirmed then
				-- Prompt for dev product purchase
				if SKIP_PRODUCT_ID > 0 then
					pcall(function()
						MPS:PromptProductPurchase(plr, SKIP_PRODUCT_ID)
					end)
				else
					-- If no product ID set, just fire the event (for testing)
					if skipEvent then
						skipEvent:FireServer()
					else
						warn("⚠️ SkipToFinish RemoteEvent not found!")
					end
					
					if _G.Notify then
						_G.Notify("🏁 Teleported!", "You've been moved to the finish!", 3, "success")
					end
				end
			end
		end)
	else
		-- No confirm dialog available, just prompt
		if SKIP_PRODUCT_ID > 0 then
			pcall(function()
				MPS:PromptProductPurchase(plr, SKIP_PRODUCT_ID)
			end)
		else
			-- For testing without product
			if skipEvent then
				skipEvent:FireServer()
			else
				warn("⚠️ SkipToFinish RemoteEvent not found!")
			end
		end
	end
end)

print("✅ Special Actions GUI loaded")
