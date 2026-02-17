-- ============================================
-- ADMIN CLIENT - Connects to pre-built AdminGui
-- Place as: StarterGui > AdminGui > AdminClient (LocalScript)
-- Run AdminGuiBuilder_CommandBar.lua in Command Bar first!
-- ============================================

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")

-- ============ AUTH CHECK ============
local remoteEvents = RS:WaitForChild("RemoteEvents", 10)
if not remoteEvents then return end
local AdminCheck = remoteEvents:WaitForChild("AdminCheck", 5)
if not AdminCheck then return end

local ok, isAdmin = pcall(function() return AdminCheck:InvokeServer() end)
if not ok or not isAdmin then return end

local AdminRemote = remoteEvents:WaitForChild("AdminCommand")
local AdminGetTrails = remoteEvents:WaitForChild("AdminGetTrails", 5)
local plr = Players.LocalPlayer
local gui = script.Parent

-- ============ UI REFERENCES ============
local toggleBtn = gui:WaitForChild("ToggleBtn")
local panel = gui:WaitForChild("Panel")
local topBar = panel:WaitForChild("TopBar")
local closeBtn = topBar:WaitForChild("CloseBtn")
local targetFrame = panel:WaitForChild("TargetFrame")
local targetBox = targetFrame:WaitForChild("TargetBox")
local meBtnUI = targetFrame:WaitForChild("MeBtn")
local tabBar = panel:WaitForChild("TabBar")

-- Content frames
local playerContent = panel:WaitForChild("PlayerContent")
local cashContent = panel:WaitForChild("CashContent")
local roundContent = panel:WaitForChild("RoundContent")
local trailContent = panel:WaitForChild("TrailContent")
local serverContent = panel:WaitForChild("ServerContent")

-- Input boxes (search recursively)
local speedBox = playerContent:FindFirstChild("SpeedBox", true)
local jumpBox = playerContent:FindFirstChild("JumpBox", true)
local coinBox = cashContent:FindFirstChild("CoinBox", true)
local winBox = cashContent:FindFirstChild("WinBox", true)
local timerBox = roundContent:FindFirstChild("TimerBox", true)
local trailBox = trailContent:FindFirstChild("TrailBox", true)
local announceBox = serverContent:FindFirstChild("AnnounceBox", true)

-- Dynamic grids
local playerGrid = playerContent:WaitForChild("PlayerGrid")
local trailGrid = trailContent:WaitForChild("TrailGrid")

-- Show toggle button
toggleBtn.Visible = true

-- ============ HELPERS ============
local function getTarget() return targetBox.Text end
local function fire(cmd, args) AdminRemote:FireServer(cmd, args) end

local function flash(b)
	local orig = b.BackgroundColor3
	b.BackgroundColor3 = Color3.new(1, 1, 1)
	task.delay(0.08, function() pcall(function() b.BackgroundColor3 = orig end) end)
end

local function findBtn(parent, name)
	return parent:FindFirstChild(name, true)
end

local function connectBtn(parent, name, callback)
	local b = findBtn(parent, name)
	if b and b:IsA("TextButton") then
		b.Activated:Connect(function()
			flash(b)
			callback()
		end)
	else
		warn("AdminClient: Button not found: " .. name)
	end
end

-- ============ PANEL ANIMATION ============
local panelW = panel.Size.X.Offset
local panelOpen = false

-- Start off-screen
panel.Position = UDim2.new(1, panelW + 10, 0, 10)
panel.Visible = false

local function animatePanel(show)
	panelOpen = show
	if show then
		panel.Visible = true
		TS:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -(panelW + 8), 0, 10)
		}):Play()
	else
		local tween = TS:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, panelW + 10, 0, 10)
		})
		tween:Play()
		tween.Completed:Connect(function()
			if not panelOpen then panel.Visible = false end
		end)
	end
end

-- Expose global toggle so ButtonBarScript can use it (with admin check built-in)
_G.ToggleAdminPanel = function()
	animatePanel(not panelOpen)
end

toggleBtn.Activated:Connect(function()
	flash(toggleBtn)
	animatePanel(not panelOpen)
end)
closeBtn.Activated:Connect(function()
	flash(closeBtn)
	animatePanel(false)
end)

-- F2 keyboard toggle
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.F2 then animatePanel(not panelOpen) end
end)

-- "Me" button
meBtnUI.Activated:Connect(function()
	flash(meBtnUI)
	targetBox.Text = plr.Name
end)

-- ============ TAB SWITCHING ============
local contentFrames = {
	Player = playerContent,
	Cash   = cashContent,
	Round  = roundContent,
	Trail  = trailContent,
	Server = serverContent,
}

local tabBtns = {}
for _, ch in pairs(tabBar:GetChildren()) do
	if ch:IsA("TextButton") then
		local tabName = ch.Name:gsub("Tab_", "")
		tabBtns[tabName] = ch
	end
end

-- Read colors from the first tab to use as active/inactive
local activeColor = Color3.fromRGB(55, 115, 245)
local inactiveColor = Color3.fromRGB(42, 42, 58)
-- Try to read from actual tab buttons
if tabBtns["Player"] then activeColor = tabBtns["Player"].BackgroundColor3 end
if tabBtns["Cash"] then inactiveColor = tabBtns["Cash"].BackgroundColor3 end

local activeTab = "Player"

local function switchTab(name)
	activeTab = name
	for tName, tBtn in pairs(tabBtns) do
		tBtn.BackgroundColor3 = (tName == name) and activeColor or inactiveColor
	end
	for cName, cFrame in pairs(contentFrames) do
		cFrame.Visible = (cName == name)
		if cName == name then cFrame.CanvasPosition = Vector2.new(0, 0) end
	end
	-- Refresh dynamic content
	if name == "Player" then refreshPlayerGrid() end
	if name == "Trail" then refreshTrailGrid() end
end

for name, btn in pairs(tabBtns) do
	btn.Activated:Connect(function()
		flash(btn)
		switchTab(name)
	end)
end

-- ============ DYNAMIC: PLAYER GRID ============
function refreshPlayerGrid()
	for _, ch in pairs(playerGrid:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end
	for i, p in ipairs(Players:GetPlayers()) do
		local pb = Instance.new("TextButton")
		pb.Text = p.DisplayName
		pb.BackgroundColor3 = (p == plr) and Color3.fromRGB(130, 70, 220) or Color3.fromRGB(42, 42, 58)
		pb.TextColor3 = Color3.fromRGB(228, 228, 238)
		pb.Font = Enum.Font.GothamBold
		pb.TextSize = 12
		pb.LayoutOrder = i
		pb.AutoButtonColor = false
		Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 6)
		pb.Parent = playerGrid
		pb.Activated:Connect(function()
			flash(pb)
			targetBox.Text = p.Name
		end)
	end
end

-- ============ DYNAMIC: TRAIL GRID ============
local trailsLoaded = false

function refreshTrailGrid()
	if trailsLoaded then return end
	if not AdminGetTrails then
		warn("AdminClient: AdminGetTrails remote not found")
		return
	end

	-- Clear old buttons first
	for _, ch in pairs(trailGrid:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end

	local ok2, data = pcall(function() return AdminGetTrails:InvokeServer() end)
	if not ok2 then
		warn("AdminClient: Failed to get trails:", data)
		return
	end
	if not data or #data == 0 then
		-- Trail system not loaded yet - DON'T set trailsLoaded so we retry next time
		warn("AdminClient: Trail list empty, will retry next time you open Trail tab")
		-- Show a hint
		local hint = Instance.new("TextButton")
		hint.Name = "_RetryHint"
		hint.Text = "⟳ Trails loading... Tap to retry"
		hint.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
		hint.TextColor3 = Color3.fromRGB(200, 200, 220)
		hint.Font = Enum.Font.GothamBold
		hint.TextSize = 12
		hint.Size = UDim2.new(1, 0, 0, 34)
		hint.AutoButtonColor = false
		Instance.new("UICorner", hint).CornerRadius = UDim.new(0, 6)
		hint.Parent = trailGrid
		hint.Activated:Connect(function()
			hint:Destroy()
			refreshTrailGrid()
		end)
		return
	end

	-- Got real data - mark as loaded
	trailsLoaded = true

	local catColors = {
		Free    = Color3.fromRGB(45, 170, 75),
		Coin    = Color3.fromRGB(225, 155, 35),
		Premium = Color3.fromRGB(130, 70, 220),
	}
	for idx, t in ipairs(data) do
		local tb = Instance.new("TextButton")
		tb.Text = t.Id
		tb.BackgroundColor3 = catColors[t.Category] or Color3.fromRGB(42, 42, 58)
		tb.TextColor3 = Color3.fromRGB(228, 228, 238)
		tb.Font = Enum.Font.GothamBold
		tb.TextSize = 11
		tb.LayoutOrder = idx
		tb.AutoButtonColor = false
		Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)
		tb.Parent = trailGrid
		tb.Activated:Connect(function()
			flash(tb)
			if trailBox then trailBox.Text = t.Id end
		end)
	end
	print("⚙ Admin: Loaded " .. #data .. " trails into picker")
end

-- ============ CONNECT BUTTONS ============

-- Player tab
connectBtn(playerContent, "Kill", function() fire("Kill", {Target = getTarget()}) end)
connectBtn(playerContent, "Kick", function() fire("Kick", {Target = getTarget()}) end)
connectBtn(playerContent, "Heal", function() fire("Heal", {Target = getTarget()}) end)
connectBtn(playerContent, "Respawn", function() fire("Respawn", {Target = getTarget()}) end)
connectBtn(playerContent, "GodMode", function() fire("GodMode", {Target = getTarget()}) end)
connectBtn(playerContent, "Freeze", function() fire("Freeze", {Target = getTarget()}) end)
connectBtn(playerContent, "TeleportTo", function() fire("TeleportTo", {Target = getTarget()}) end)
connectBtn(playerContent, "TpAllToMe", function() fire("TpAllToMe", {}) end)
connectBtn(playerContent, "Invisible", function() fire("Invisible", {Target = getTarget()}) end)
connectBtn(playerContent, "SetSpeed", function()
	fire("SetSpeed", {Target = getTarget(), Amount = speedBox and speedBox.Text or "16"})
end)
connectBtn(playerContent, "SetJump", function()
	fire("SetJump", {Target = getTarget(), Amount = jumpBox and jumpBox.Text or "50"})
end)

-- Cash tab
connectBtn(cashContent, "GiveCoins", function()
	fire("GiveCoins", {Target = getTarget(), Amount = coinBox and coinBox.Text or "0"})
end)
connectBtn(cashContent, "RemoveCoins", function()
	fire("RemoveCoins", {Target = getTarget(), Amount = coinBox and coinBox.Text or "0"})
end)
connectBtn(cashContent, "SetCoins", function()
	fire("SetCoins", {Target = getTarget(), Amount = coinBox and coinBox.Text or "0"})
end)
connectBtn(cashContent, "GiveWins", function()
	fire("GiveWins", {Target = getTarget(), Amount = winBox and winBox.Text or "1"})
end)

-- Round tab
connectBtn(roundContent, "SkipRound", function() fire("SkipRound", {}) end)
connectBtn(roundContent, "EndRound", function() fire("EndRound", {}) end)
connectBtn(roundContent, "SetTimer", function()
	fire("SetTimer", {Amount = timerBox and timerBox.Text or "60"})
end)
connectBtn(roundContent, "Intermission", function() fire("SetGameState", {State = "Intermission"}) end)
connectBtn(roundContent, "Playing", function() fire("SetGameState", {State = "Playing"}) end)
connectBtn(roundContent, "Voting", function() fire("SetGameState", {State = "Voting"}) end)
connectBtn(roundContent, "RoundEnd", function() fire("SetGameState", {State = "RoundEnd"}) end)
connectBtn(roundContent, "Day", function() fire("SetTime", {Time = "Day"}) end)
connectBtn(roundContent, "Night", function() fire("SetTime", {Time = "Night"}) end)
connectBtn(roundContent, "Sunset", function() fire("SetTime", {Time = "Sunset"}) end)
connectBtn(roundContent, "Sunrise", function() fire("SetTime", {Time = "Sunrise"}) end)

-- Trail tab
connectBtn(trailContent, "GiveTrail", function()
	fire("GiveTrail", {Target = getTarget(), TrailId = trailBox and trailBox.Text or ""})
end)
connectBtn(trailContent, "EquipTrail", function()
	fire("EquipTrail", {Target = getTarget(), TrailId = trailBox and trailBox.Text or ""})
end)
connectBtn(trailContent, "UnequipTrail", function()
	fire("UnequipTrail", {Target = getTarget()})
end)
connectBtn(trailContent, "RemoveTrail", function()
	fire("RemoveTrail", {Target = getTarget(), TrailId = trailBox and trailBox.Text or ""})
end)

-- Server tab
connectBtn(serverContent, "SendAnnounce", function()
	fire("Announce", {Message = announceBox and announceBox.Text or ""})
end)
connectBtn(serverContent, "TpAllBtn", function()
	fire("TpAllToMe", {})
end)

-- ============ INIT ============
switchTab("Player")
print("⚙ Admin Panel ready! Press F2 or tap ⚙")
print("   Chat commands: type /cmds in chat")
