local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local gui = script.Parent
local toggleBtn = gui:WaitForChild("LBToggle")
local panel = gui:WaitForChild("Panel")
local entries = panel:WaitForChild("Entries")
local template = panel:WaitForChild("EntryTemplate")
local winsTab = panel:FindFirstChild("WinsTab", true)
local coinsTab = panel:FindFirstChild("CoinsTab", true)

-- MEDAL COLORS for top 3
local MEDAL_COLORS = {
	Color3.fromRGB(255, 200, 50),  -- Gold
	Color3.fromRGB(200, 200, 210), -- Silver
	Color3.fromRGB(200, 130, 60),  -- Bronze
}
local MEDAL_BG = {
	Color3.fromRGB(60, 50, 20),
	Color3.fromRGB(45, 45, 55),
	Color3.fromRGB(50, 35, 20),
}
local MEDALS = {"??", "??", "??"}

local ROW_COLORS = {
	Color3.fromRGB(200, 50, 50),   -- red
	Color3.fromRGB(200, 140, 40),  -- gold
	Color3.fromRGB(40, 160, 60),   -- green
	Color3.fromRGB(40, 130, 200),  -- blue
	Color3.fromRGB(140, 60, 200),  -- purple
}

-- Toggle
local panelOpen = false
local function toggle(force)
	if force ~= nil then panelOpen = force else panelOpen = not panelOpen end
	panel.Visible = panelOpen
end

toggleBtn.MouseButton1Click:Connect(function() toggle() end)

local closeBtn = panel:FindFirstChild("CloseBtn")
if closeBtn then
	closeBtn.MouseButton1Click:Connect(function()
		toggle(false)
	end)
end
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.L then toggle() end
end)

-- Current sort
local currentStat = "Wins"

local function clearEntries()
	for _, c in pairs(entries:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
end

local function refreshBoard()
	clearEntries()
	
	-- Gather players and values
	local data = {}
	for _, p in pairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		if ls then
			local stat = ls:FindFirstChild(currentStat)
			if stat then
				table.insert(data, {Player = p, Value = stat.Value})
			end
		end
	end
	
	-- Sort descending
	table.sort(data, function(a, b) return a.Value > b.Value end)
	
	-- Create entries
	for i, d in ipairs(data) do
		if i > 50 then break end
		
		local entry = template:Clone()
		entry.Name = "Entry_" .. i
		entry.Visible = true
		entry.LayoutOrder = i
		entry.ZIndex = 26
		
		-- Top 3 get medal colors
		if i <= 3 then
			entry.BackgroundColor3 = MEDAL_BG[i]
			local s = entry:FindFirstChildWhichIsA("UIStroke")
			if s then s.Color = MEDAL_COLORS[i] s.Thickness = 2 end
		else
			-- Cycle through cartoony row colors
			local colorIdx = ((i - 4) % #ROW_COLORS) + 1
			entry.BackgroundColor3 = ROW_COLORS[colorIdx]
			entry.BackgroundTransparency = 0.6
			local s = entry:FindFirstChildWhichIsA("UIStroke")
			if s then s.Color = ROW_COLORS[colorIdx] s.Transparency = 0.3 end
		end
		
		-- Rank
		local rank = entry:FindFirstChild("Rank")
		if rank then
			if i <= 3 then
				rank.Text = MEDALS[i]
				rank.TextColor3 = MEDAL_COLORS[i]
			else
				rank.Text = "#" .. i
				rank.TextColor3 = Color3.fromRGB(180, 170, 210)
			end
		end
		
		-- Face
		local face = entry:FindFirstChild("Face")
		if face then
			pcall(function()
				face.Image = Players:GetUserThumbnailAsync(
					d.Player.UserId, 
					Enum.ThumbnailType.HeadShot, 
					Enum.ThumbnailSize.Size48x48
				)
			end)
		end
		
		-- Name
		local pName = entry:FindFirstChild("PlayerName")
		if pName then
			pName.Text = d.Player.DisplayName
			if d.Player == plr then
				pName.TextColor3 = Color3.fromRGB(160, 220, 255)
			else
				pName.TextColor3 = Color3.new(1, 1, 1)
			end
		end
		
		-- Value
		local val = entry:FindFirstChild("Value")
		if val then
			val.Text = tostring(d.Value)
			if currentStat == "Coins" then
				val.TextColor3 = Color3.fromRGB(255, 200, 50)
			else
				val.TextColor3 = Color3.fromRGB(100, 255, 150)
			end
		end
		
		entry.Parent = entries
	end
end

-- Tab switching
if winsTab then
	winsTab.MouseButton1Click:Connect(function()
		currentStat = "Wins"
		winsTab.BackgroundColor3 = Color3.fromRGB(100, 60, 200)
		winsTab.TextColor3 = Color3.new(1, 1, 1)
		coinsTab.BackgroundColor3 = Color3.fromRGB(40, 32, 65)
		coinsTab.TextColor3 = Color3.fromRGB(160, 150, 190)
		refreshBoard()
	end)
end

if coinsTab then
	coinsTab.MouseButton1Click:Connect(function()
		currentStat = "Coins"
		coinsTab.BackgroundColor3 = Color3.fromRGB(200, 150, 30)
		coinsTab.TextColor3 = Color3.new(1, 1, 1)
		winsTab.BackgroundColor3 = Color3.fromRGB(40, 32, 65)
		winsTab.TextColor3 = Color3.fromRGB(160, 150, 190)
		refreshBoard()
	end)
end

-- Auto refresh
task.spawn(function()
	task.wait(2)
	refreshBoard()
end)

-- Refresh when players join/leave
Players.PlayerAdded:Connect(function() task.wait(1) refreshBoard() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) refreshBoard() end)

-- Refresh every 15 seconds
task.spawn(function()
	while true do
		task.wait(15)
		refreshBoard()
	end
end)

print("?? Leaderboard ready! Press L or click ??")
