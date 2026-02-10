-- ============================================
-- LEADERBOARD GUI SCRIPT (Opens At Studio Set Location)
-- Place in: StarterGui/LeaderboardGui/LocalScript
-- ============================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local gui = script.Parent
local openButton = gui:WaitForChild("OpenButton")
local container = gui:WaitForChild("Container")
local toggleButton = container:WaitForChild("Header"):WaitForChild("ToggleButton")
local playerList = container:WaitForChild("PlayerList")

-- USE PROPERTIES SET IN STUDIO!
-- Do NOT reset Position/Size in code
container.Visible = false

-- Player entry function (unchanged)
local function createPlayerEntry(playerData, rank)
	local entry = Instance.new("Frame")
	entry.Name = playerData.Name
	entry.Size = UDim2.new(1, -10, 0, 50)
	entry.BackgroundColor3 = rank % 2 == 0 and Color3.fromRGB(25, 35, 55) or Color3.fromRGB(30, 45, 65)
	entry.BorderSizePixel = 0
	entry.LayoutOrder = rank

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 10)
	entryCorner.Parent = entry

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "Rank"
	rankLabel.Size = UDim2.new(0.25, 0, 0.8, 0)
	rankLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = "#" .. rank
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextColor3 = rank == 1 and Color3.fromRGB(255, 215, 0) or 
		rank == 2 and Color3.fromRGB(192, 192, 192) or 
		rank == 3 and Color3.fromRGB(205, 127, 50) or 
		Color3.fromRGB(200, 200, 200)
	rankLabel.TextScaled = true
	rankLabel.Parent = entry

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(0.4, 0, 0.8, 0)
	nameLabel.Position = UDim2.new(0.3, 0, 0.1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = playerData.Name
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = entry

	local winsLabel = Instance.new("TextLabel")
	winsLabel.Name = "Wins"
	winsLabel.Size = UDim2.new(0.25, 0, 0.8, 0)
	winsLabel.Position = UDim2.new(0.72, 0, 0.1, 0)
	winsLabel.BackgroundTransparency = 1
	winsLabel.Text = tostring(playerData.Wins or 0)
	winsLabel.Font = Enum.Font.GothamBold
	winsLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
	winsLabel.TextScaled = true
	winsLabel.Parent = entry

	return entry
end

-- Update leaderboard (unchanged)
local function updateLeaderboard()
	for _, child in pairs(playerList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local playerData = {}
	for _, plr in pairs(Players:GetPlayers()) do
		local leaderstats = plr:FindFirstChild("leaderstats")
		if leaderstats then
			local wins = leaderstats:FindFirstChild("Wins")
			table.insert(playerData, {
				Name = plr.Name,
				Wins = wins and wins.Value or 0
			})
		end
	end

	table.sort(playerData, function(a, b)
		return a.Wins > b.Wins
	end)

	for rank, data in ipairs(playerData) do
		local entry = createPlayerEntry(data, rank)
		entry.Parent = playerList
	end
end

-- Toggle leaderboard (respects Studio set properties)
local function toggleLeaderboard()
	local isVisible = container.Visible
	container.Visible = not isVisible

	if not isVisible then
		-- Optionally animate size for pop-in effect WITHOUT affecting position
		local targetSize = container.Size
		container.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(
			container,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = targetSize }
		):Play()

		updateLeaderboard()
	end
end

openButton.MouseButton1Click:Connect(function()
	toggleLeaderboard()
end)

toggleButton.MouseButton1Click:Connect(function()
	toggleLeaderboard()
end)

task.spawn(function()
	while true do
		task.wait(5)
		if container.Visible then
			updateLeaderboard()
		end
	end
end)

Players.PlayerAdded:Connect(function()
	if container.Visible then
		task.wait(1)
		updateLeaderboard()
	end
end)

Players.PlayerRemoving:Connect(function()
	if container.Visible then
		task.wait(0.5)
		updateLeaderboard()
	end
end)