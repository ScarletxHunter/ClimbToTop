local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local container = script.Parent:WaitForChild("Container")
local valueLabel = container:WaitForChild("Value")
local plusBtn = container:WaitForChild("PlusButton")

local function formatCoins(n)
	n = math.floor(n or 0)
	local s = tostring(n)
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1,1) == "," then formatted = formatted:sub(2) end
	return formatted
end

-- Hover effect
plusBtn.MouseEnter:Connect(function()
	TweenService:Create(plusBtn, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(135, 230, 70)}):Play()
end)
plusBtn.MouseLeave:Connect(function()
	TweenService:Create(plusBtn, TweenInfo.new(0.10), {BackgroundColor3 = Color3.fromRGB(110, 200, 55)}):Play()
end)

-- Click opens coin shop (waits for _G.OpenCoinShop to be set by CoinPurchaseScript)
plusBtn.MouseButton1Click:Connect(function()
	if _G.OpenShop then
		_G.OpenShop("Coins")
	end
end)

-- Update coins display
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 30)
	if not ls then warn("[CoinsGui] No leaderstats") return end
	local coins = ls:WaitForChild("Coins", 30)
	if not coins then warn("[CoinsGui] No Coins value") return end

	valueLabel.Text = formatCoins(coins.Value)
	coins.Changed:Connect(function()
		valueLabel.Text = formatCoins(coins.Value)
	end)
end)

print("? Coin display active")
