local Players = game:GetService("Players")
local MPS = game:GetService("MarketplaceService")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local gui = script.Parent
local toggleBtn = gui:WaitForChild("ShopToggle")
local content = gui:WaitForChild("Content")
local closeBtn = content:WaitForChild("CloseBtn")
local scroll = content:WaitForChild("Scroll")
local tabRow = content:WaitForChild("TabRow")

local gpPage = scroll:WaitForChild("GamepassPage")
local coinPage = scroll:WaitForChild("CoinPage")

-- PAGES
local pages = {
	Gamepasses = gpPage,
	Coins = coinPage,
}

local currentTab = "Gamepasses"

local function switchTab(tabName)
	currentTab = tabName
	for name, page in pairs(pages) do
		page.Visible = (name == tabName)
	end
	for name, btn in pairs({}) do end -- updated below
	for _, btn in pairs(tabRow:GetChildren()) do
		if btn:IsA("TextButton") then
			local isActive = btn.Name == "Tab_" .. tabName
			btn.BackgroundColor3 = isActive 
				and Color3.fromRGB(100, 60, 200) 
				or Color3.fromRGB(40, 32, 65)
			btn.TextColor3 = isActive 
				and Color3.fromRGB(255, 255, 255) 
				or Color3.fromRGB(160, 150, 190)
		end
	end
	scroll.CanvasPosition = Vector2.new(0, 0)
end

-- Tab clicks
for _, btn in pairs(tabRow:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			local tabName = btn.Name:gsub("Tab_", "")
			switchTab(tabName)
		end)
	end
end

-- TOGGLE
local shopOpen = false
local function toggleShop(force)
	if force ~= nil then shopOpen = force else shopOpen = not shopOpen end
	if shopOpen then
		content.Visible = true
		content.Size = UDim2.new(0, 0, 0, 0)
		TS:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.58, 0, 0.6, 0)
		}):Play()
	else
		TS:Create(content, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()
		task.delay(0.2, function() content.Visible = false end)
	end
end

toggleBtn.MouseButton1Click:Connect(function() toggleShop() end)
closeBtn.MouseButton1Click:Connect(function() toggleShop(false) end)
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.G then toggleShop() end
end)

-- GAMEPASS OWNERSHIP CHECK
local ownedCache = {}
local function checkOwned(id)
	if ownedCache[id] ~= nil then return ownedCache[id] end
	local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(plr.UserId, id) end)
	ownedCache[id] = ok and owns or false
	return ownedCache[id]
end

-- WIRE GAMEPASS CARDS
local gpGrid = gpPage:FindFirstChild("GamepassGrid")
if gpGrid then
	for _, card in pairs(gpGrid:GetChildren()) do
		if not card:IsA("ImageLabel") then continue end
		local idVal = card:FindFirstChild("GamepassId")
		if not idVal then continue end
		local gpId = idVal.Value
		local buyBtn = card:FindFirstChild("BuyButton")
		
		-- Check ownership
		local owned = checkOwned(gpId)
		if owned then
			card.BackgroundColor3 = Color3.fromRGB(18, 40, 25)
			local s = card:FindFirstChildWhichIsA("UIStroke")
			if s then s.Color = Color3.fromRGB(0, 200, 80) s.Thickness = 2 end
			if buyBtn then 
				buyBtn.Text = "? OWNED" 
				buyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60) 
			end
		end
		
		-- Buy click
		if buyBtn then
			buyBtn.MouseButton1Click:Connect(function()
				if not checkOwned(gpId) then
					pcall(function() MPS:PromptGamePassPurchase(plr, gpId) end)
				end
			end)
		end
	end
end

-- PURCHASE FINISHED ? update card
MPS.PromptGamePassPurchaseFinished:Connect(function(p, id, bought)
	if p ~= plr or not bought then return end
	ownedCache[id] = true
	if gpGrid then
		for _, card in pairs(gpGrid:GetChildren()) do
			if card:IsA("ImageLabel") then
				local idV = card:FindFirstChild("GamepassId")
				if idV and idV.Value == id then
					card.BackgroundColor3 = Color3.fromRGB(18, 40, 25)
					local s = card:FindFirstChildWhichIsA("UIStroke")
					if s then s.Color = Color3.fromRGB(0, 200, 80) end
					local bb = card:FindFirstChild("BuyButton")
					if bb then bb.Text = "? OWNED" bb.BackgroundColor3 = Color3.fromRGB(0, 140, 60) end
				end
			end
		end
	end
	-- Notification
	if _G.Notify then
		_G.Notify("? Purchased!", "Gamepass activated!", 3, "success")
	end
end)

-- COIN BALANCE
local balLabel = coinPage:FindFirstChild("BalanceLabel") 
	or coinPage:FindFirstChildWhichIsA("Frame") and coinPage:FindFirstChildWhichIsA("Frame"):FindFirstChild("BalanceLabel")
local function updateBalance()
	local ls = plr:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("Coins")
	if coins and balLabel then
		balLabel.Text = "?? Your Balance: " .. tostring(coins.Value)
	end
end

task.spawn(function()
	local ls = plr:WaitForChild("leaderstats", 30)
	if ls then
		local coins = ls:WaitForChild("Coins", 10)
		if coins then
			updateBalance()
			coins.Changed:Connect(updateBalance)
		end
	end
end)

-- COIN BUY BUTTONS
local BuyCoinsEvent = RS:FindFirstChild("BuyCoinsEvent")
local coinGrid = coinPage:FindFirstChild("CoinGrid")
if coinGrid then
	-- Try to get product info from server
	local ok, products = pcall(function()
		local gf = RS:FindFirstChild("GetCoinProducts")
		if gf then return gf:InvokeServer() end
		return nil
	end)
	
	for _, card in pairs(coinGrid:GetChildren()) do
		if not card:IsA("ImageLabel") then continue end
		local idx = card:FindFirstChild("CardIndex")
		local buyBtn = card:FindFirstChild("BuyButton")
		
		-- Update with server product data if available
		if ok and products and idx then
			local product = products[idx.Value]
			if product then
				local amt = card:FindFirstChild("CoinAmount")
				if amt then amt.Text = (product.CoinsAmount or "???") .. " Coins" end
				if buyBtn then buyBtn.Text = "R$ " .. (product.RobuxPrice or "???") end
			end
		end
		
		if buyBtn and idx then
			buyBtn.MouseButton1Click:Connect(function()
				if BuyCoinsEvent then
					BuyCoinsEvent:FireServer(idx.Value)
				end
			end)
		end
	end
end

-- REGISTER GLOBAL OPEN
_G.OpenShop = function(tab)
	toggleShop(true)
	if tab then switchTab(tab) end
end

-- Init
switchTab("Gamepasses")
print("?? New Shop ready! Press G or click ?? to open")
