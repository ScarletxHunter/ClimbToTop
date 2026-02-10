-- ============================================
-- COINS GUI (Position Bottom-Right, Static Icon)
-- Place in: StarterGui/CoinsGui/LocalScript
-- ============================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = script.Parent

-- ALWAYS SHOW COINS GUI
gui.Enabled = true
gui.ResetOnSpawn = false

print("?? Coins GUI starting...")

local container = gui:WaitForChild("Container")
local coinsLabel = container:WaitForChild("CoinsLabel")
local coinIcon = container:WaitForChild("CoinIcon")
local plusButton = container:WaitForChild("PlusButton")

-- ==== FIX UI POSITION: Bottom Right ====
container.AnchorPoint = Vector2.new(1, 1)
container.Position = UDim2.new(1, -24, 1, -24)  -- 24px from right/bottom edges (adjust as needed)
container.Size = UDim2.new(0, 190, 0, 60)       -- Change size as you like

-- ==== REMOVE COIN ICON SPIN ====
-- If you want the icon completely static, comment/remove any animation:
-- (Original animateCoinIcon and call REMOVED.)

-- Update coins (simple, static)
local function updateCoins(newAmount, oldAmount)
	oldAmount = oldAmount or 0
	local duration = 0.6
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < duration do
			local alpha = (tick() - startTime) / duration
			coinsLabel.Text = tostring(math.floor(oldAmount + (newAmount - oldAmount) * alpha))
			task.wait()
		end
		coinsLabel.Text = tostring(newAmount)
	end)

	-- Optional: pop effect for icon/color without spin
	TweenService:Create(coinIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {ImageColor3 = Color3.fromRGB(255, 255, 100)}):Play()
	TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 200, 0, 62)}):Play()
	task.wait(0.2)
	TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 190, 0, 60)}):Play()
end

-- Connect to leaderstats
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 30)
	if not leaderstats then
		warn("? Leaderstats not found!")
		return
	end

	local coins = leaderstats:WaitForChild("Coins", 10)
	if not coins then
		warn("? Coins not found!")
		return
	end

	coinsLabel.Text = tostring(coins.Value)

	coins.Changed:Connect(function(newValue)
		local oldValue = tonumber(coinsLabel.Text) or 0
		updateCoins(newValue, oldValue)
	end)

	print("? Coins GUI connected!")
end)

-- Plus button (opens COIN SHOP)
plusButton.MouseButton1Click:Connect(function()
	print("?? PLUS BUTTON CLICKED!")
	TweenService:Create(plusButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Size = UDim2.new(0.17, 0, 0.65, 0)}):Play()

	local playerGui = player:WaitForChild("PlayerGui", 5)
	if not playerGui then return end

	local coinShopGui = playerGui:FindFirstChild("CoinShopGui")
	if not coinShopGui then
		warn("? CoinShopGui not found!")
		return
	end

	coinShopGui.Enabled = true
	local coinShopContainer = coinShopGui:FindFirstChild("Container")
	if coinShopContainer then
		coinShopContainer.Visible = true
		coinShopContainer.Size = UDim2.new(0, 0, 0, 0)
		coinShopContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
		TweenService:Create(coinShopContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.6, 0, 0.75, 0),
			Position = UDim2.new(0.2, 0, 0.125, 0)
		}):Play()
		print("? COIN SHOP OPENED!")
	end
end)

print("? Coins GUI fully loaded")