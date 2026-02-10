-- ============================================
-- TRAIL SHOP CLIENT (TEST MODE - TrailMaster forced OFF)
-- Place in: StarterGui/TrailShop/LocalScript
-- 
-- ?? TEST MODE ACTIVE: hasTrailMaster forced to false
-- ?? REMOVE the test override lines before publishing!
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local gui = script.Parent

print("? Trail Shop loading...")

-- ============================================
-- TRAIL DATA
-- ============================================
local TRAILMASTER_GAMEPASS_ID = 1704388512

local TRAILS = {
	-- FREE TRAILS
	{Name = "White",      Color1 = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(200, 200, 200), Premium = false, LayoutOrder = 1},
	{Name = "Red",        Color1 = Color3.fromRGB(255, 50, 50),   Color2 = Color3.fromRGB(180, 20, 20),   Premium = false, LayoutOrder = 2},
	{Name = "Blue",       Color1 = Color3.fromRGB(50, 100, 255),  Color2 = Color3.fromRGB(20, 50, 180),   Premium = false, LayoutOrder = 3},
	{Name = "Green",      Color1 = Color3.fromRGB(50, 255, 50),   Color2 = Color3.fromRGB(20, 180, 20),   Premium = false, LayoutOrder = 4},

	-- TRAILMASTER PREMIUM TRAILS
	{Name = "Rainbow",    Color1 = Color3.fromRGB(255, 0, 0),     Color2 = Color3.fromRGB(0, 0, 255),     Premium = true, Rainbow = true, LayoutOrder = 5},
	{Name = "Gold",       Color1 = Color3.fromRGB(255, 215, 0),   Color2 = Color3.fromRGB(255, 170, 0),   Premium = true, LayoutOrder = 6},
	{Name = "Purple",     Color1 = Color3.fromRGB(180, 50, 255),  Color2 = Color3.fromRGB(100, 0, 200),   Premium = true, LayoutOrder = 7},
	{Name = "Cyan",       Color1 = Color3.fromRGB(0, 255, 255),   Color2 = Color3.fromRGB(0, 180, 220),   Premium = true, LayoutOrder = 8},
	{Name = "Pink",       Color1 = Color3.fromRGB(255, 105, 180), Color2 = Color3.fromRGB(255, 50, 150),  Premium = true, LayoutOrder = 9},
	{Name = "Fire",       Color1 = Color3.fromRGB(255, 100, 0),   Color2 = Color3.fromRGB(255, 200, 0),   Premium = true, LayoutOrder = 10},
	{Name = "Ice",        Color1 = Color3.fromRGB(150, 220, 255), Color2 = Color3.fromRGB(200, 240, 255), Premium = true, LayoutOrder = 11},
	{Name = "Shadow",     Color1 = Color3.fromRGB(30, 0, 50),     Color2 = Color3.fromRGB(80, 0, 120),    Premium = true, LayoutOrder = 12},
	{Name = "Neon Green", Color1 = Color3.fromRGB(0, 255, 100),   Color2 = Color3.fromRGB(100, 255, 0),   Premium = true, LayoutOrder = 13},
	{Name = "Lava",       Color1 = Color3.fromRGB(255, 50, 0),    Color2 = Color3.fromRGB(255, 150, 0),   Premium = true, LayoutOrder = 14},
}

-- ============================================
-- UI ELEMENTS
-- ============================================
local panelFrame = gui:WaitForChild("Panel")
local toggleBtn = gui:WaitForChild("TrailToggle")
local closeBtn = panelFrame:WaitForChild("TitleBar"):WaitForChild("CloseBtn")
local trailList = panelFrame:WaitForChild("TrailList")
local unequipBtn = panelFrame:WaitForChild("UnequipBtn")
local infoLabel = panelFrame:WaitForChild("InfoLabel")

-- ============================================
-- REMOTE
-- ============================================
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local trailEvent = remoteEvents and remoteEvents:FindFirstChild("TrailEquip")
if not trailEvent then
	trailEvent = remoteEvents and remoteEvents:WaitForChild("TrailEquip", 5)
end

-- ============================================
-- STATE
-- ============================================
local hasTrailMaster = false
local currentTrail = nil
local panelOpen = false

-- ============================================
-- ?? TEST MODE TOGGLE
-- Set to true = pretend you DON'T own TrailMaster
-- Set to false = normal mode (checks real gamepass ownership)
-- ?? SET TO false BEFORE PUBLISHING YOUR GAME!
-- ============================================
local TEST_MODE_FORCE_LOCKED = false -- <<-- SET TO false TO CHECK REAL PASS

-- ============================================
-- CHECK GAMEPASS
-- ============================================
local function checkTrailMaster()
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, TRAILMASTER_GAMEPASS_ID)
	end)
	hasTrailMaster = success and owns

	-- ?? TEST MODE OVERRIDE
	if TEST_MODE_FORCE_LOCKED then
		hasTrailMaster = false
		print("?? TEST MODE: TrailMaster forced OFF (premium trails locked)")
	end

	if hasTrailMaster then
		infoLabel.Text = "?? TrailMaster active! All trails unlocked!"
		infoLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	else
		infoLabel.Text = "Select a trail! ?? = TrailMaster Pass required"
		infoLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	end
end

-- ============================================
-- TOGGLE PANEL
-- ============================================
toggleBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	panelFrame.Visible = panelOpen
end)

closeBtn.MouseButton1Click:Connect(function()
	panelOpen = false
	panelFrame.Visible = false
end)

-- ============================================
-- CHECK IF TRAIL IS LOCKED
-- ============================================
local function isTrailLocked(trailData)
	return trailData.Premium and not hasTrailMaster
end

-- ============================================
-- CREATE TRAIL ON CHARACTER
-- ============================================
local activeTrail = nil
local rainbowConnection = nil

local function removeTrail()
	if rainbowConnection then
		rainbowConnection:Disconnect()
		rainbowConnection = nil
	end
	if activeTrail and activeTrail.Parent then
		activeTrail:Destroy()
	end
	activeTrail = nil

	local char = player.Character
	if char then
		for _, child in pairs(char:GetDescendants()) do
			if child:IsA("Trail") and child.Name == "PlayerTrail" then
				child:Destroy()
			end
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			for _, a in pairs(hrp:GetChildren()) do
				if a.Name == "TrailAttach0" or a.Name == "TrailAttach1" then
					a:Destroy()
				end
			end
		end
	end
end

local function applyTrail(trailData)
	removeTrail()
	if not trailData then return end

	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local attach0 = Instance.new("Attachment")
	attach0.Name = "TrailAttach0"
	attach0.Position = Vector3.new(0, 1, 0)
	attach0.Parent = hrp

	local attach1 = Instance.new("Attachment")
	attach1.Name = "TrailAttach1"
	attach1.Position = Vector3.new(0, -1, 0)
	attach1.Parent = hrp

	local trail = Instance.new("Trail")
	trail.Name = "PlayerTrail"
	trail.Attachment0 = attach0
	trail.Attachment1 = attach1
	trail.Lifetime = 1.5
	trail.MinLength = 0.1
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.LightEmission = 0.5
	trail.LightInfluence = 0.3
	trail.FaceCamera = true

	if trailData.Rainbow then
		local hue = 0
		trail.Color = ColorSequence.new(Color3.fromHSV(0, 1, 1), Color3.fromHSV(0.5, 1, 1))
		rainbowConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
			hue = (hue + dt * 0.3) % 1
			if trail and trail.Parent then
				trail.Color = ColorSequence.new(
					Color3.fromHSV(hue, 1, 1),
					Color3.fromHSV((hue + 0.5) % 1, 1, 1)
				)
			end
		end)
	else
		trail.Color = ColorSequence.new(trailData.Color1, trailData.Color2)
	end

	trail.Parent = hrp
	activeTrail = trail
	currentTrail = trailData.Name

	print("? Equipped trail:", trailData.Name)
end

-- ============================================
-- UPDATE ALL CARD VISUALS
-- ============================================
local function updateCardVisuals(equippedTrailName)
	for _, c in pairs(trailList:GetChildren()) do
		if c:IsA("TextButton") then
			local s = c:FindFirstChild("Status")
			local cs = c:FindFirstChild("CardStroke")

			local tData = nil
			for _, t in ipairs(TRAILS) do
				if c.Name == "Trail_" .. t.Name then
					tData = t
					break
				end
			end

			if not tData then continue end

			local locked = isTrailLocked(tData)
			local equipped = (equippedTrailName and c.Name == "Trail_" .. equippedTrailName)

			if equipped then
				if s then
					s.Text = "? EQUIPPED"
					s.TextColor3 = Color3.fromRGB(0, 255, 0)
				end
				if cs then
					cs.Thickness = 2.5
					cs.Transparency = 0
				end
				c.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
			elseif locked then
				if s then
					s.Text = "?? TrailMaster"
					s.TextColor3 = Color3.fromRGB(255, 170, 0)
				end
				if cs then
					cs.Thickness = 1.5
					cs.Transparency = 0.3
				end
				c.BackgroundColor3 = Color3.fromRGB(35, 30, 45)
			else
				if s then
					s.Text = "? Available"
					s.TextColor3 = Color3.fromRGB(0, 255, 100)
				end
				if cs then
					cs.Thickness = 1.5
					cs.Transparency = 0.3
				end
				c.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
			end
		end
	end
end

-- ============================================
-- BUILD TRAIL CARDS
-- ============================================
local function buildCards()
	for _, child in pairs(trailList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, trail in ipairs(TRAILS) do
		local locked = isTrailLocked(trail)

		local card = Instance.new("TextButton")
		card.Name = "Trail_" .. trail.Name
		card.BackgroundColor3 = locked and Color3.fromRGB(35, 30, 45) or Color3.fromRGB(40, 35, 55)
		card.BorderSizePixel = 0
		card.Text = ""
		card.ZIndex = 52
		card.LayoutOrder = trail.LayoutOrder
		card.AutoButtonColor = true
		card.Parent = trailList
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Name = "CardStroke"
		cardStroke.Color = trail.Color1
		cardStroke.Thickness = 1.5
		cardStroke.Transparency = 0.3
		cardStroke.Parent = card

		local colorBar = Instance.new("Frame")
		colorBar.Size = UDim2.new(1, -10, 0, 8)
		colorBar.Position = UDim2.new(0, 5, 0, 5)
		colorBar.BorderSizePixel = 0
		colorBar.ZIndex = 53
		colorBar.Parent = card
		Instance.new("UICorner", colorBar).CornerRadius = UDim.new(0, 4)

		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(trail.Color1, trail.Color2)
		gradient.Parent = colorBar

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -10, 0, 18)
		nameLabel.Position = UDim2.new(0, 5, 0, 18)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = trail.Name
		nameLabel.TextSize = 13
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 53
		nameLabel.Parent = card

		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "Status"
		statusLabel.Size = UDim2.new(1, -10, 0, 16)
		statusLabel.Position = UDim2.new(0, 5, 1, -20)
		statusLabel.BackgroundTransparency = 1
		statusLabel.TextSize = 11
		statusLabel.Font = Enum.Font.Gotham
		statusLabel.TextXAlignment = Enum.TextXAlignment.Left
		statusLabel.ZIndex = 53
		statusLabel.Parent = card

		if locked then
			statusLabel.Text = "?? TrailMaster"
			statusLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
		else
			statusLabel.Text = "? Available"
			statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
		end

		card.MouseButton1Click:Connect(function()
			if isTrailLocked(trail) then
				pcall(function()
					MarketplaceService:PromptGamePassPurchase(player, TRAILMASTER_GAMEPASS_ID)
				end)
				return
			end

			applyTrail(trail)

			if trailEvent then
				trailEvent:FireServer("Equip", trail.Name)
			end

			updateCardVisuals(trail.Name)
		end)
	end

	if currentTrail then
		updateCardVisuals(currentTrail)
	end
end

-- ============================================
-- UNEQUIP
-- ============================================
unequipBtn.MouseButton1Click:Connect(function()
	removeTrail()
	currentTrail = nil
	if trailEvent then
		trailEvent:FireServer("Unequip")
	end
	updateCardVisuals(nil)
	print("? Trail removed")
end)

-- ============================================
-- RE-APPLY TRAIL ON RESPAWN
-- ============================================
player.CharacterAdded:Connect(function(character)
	if currentTrail then
		task.wait(1)
		for _, trail in ipairs(TRAILS) do
			if trail.Name == currentTrail then
				applyTrail(trail)
				break
			end
		end
	end
end)

-- ============================================
-- GAMEPASS PURCHASE LISTENER
-- ============================================
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, purchased)
	if plr == player and passId == TRAILMASTER_GAMEPASS_ID and purchased then
		hasTrailMaster = true
		infoLabel.Text = "?? TrailMaster active! All trails unlocked!"
		infoLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		buildCards()
		print("? TrailMaster purchased! All trails unlocked!")
	end
end)

-- ============================================
-- INITIALIZE
-- ============================================
checkTrailMaster()
buildCards()

print("? Trail Shop loaded! (" .. #TRAILS .. " trails)")
print("   Free: 4 | Premium: " .. (#TRAILS - 4))
if TEST_MODE_FORCE_LOCKED then
	print("   ?? TEST MODE: TrailMaster forced OFF")
	print("   ?? Set TEST_MODE_FORCE_LOCKED = false before publishing!")
end