-- ============================================
-- PROGRESS GUI - Shows ALL players with FACE THUMBNAILS
-- FIXED: Thumbnail loading, dynamic Start/End
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local progressGui = script.Parent

local GameState = ReplicatedStorage:WaitForChild("GameValues"):WaitForChild("GameState")

local container = progressGui:WaitForChild("ProgressContainer")
local barBG = container:WaitForChild("BarBG")
local barFill = barBG:WaitForChild("BarFill")

local startPart = nil
local endPart = nil

local playerMarkers = {}

local MARKER_COLORS = {
	Color3.fromRGB(255, 100, 100),
	Color3.fromRGB(100, 200, 255),
	Color3.fromRGB(255, 200, 50),
	Color3.fromRGB(100, 255, 150),
	Color3.fromRGB(255, 100, 255),
	Color3.fromRGB(255, 160, 80),
	Color3.fromRGB(150, 100, 255),
	Color3.fromRGB(100, 255, 255),
}

local function getColor(idx)
	return MARKER_COLORS[((idx - 1) % #MARKER_COLORS) + 1]
end

-- ============================================
-- FIND START/END PARTS DYNAMICALLY
-- ============================================

local function findStartAndEnd()
	startPart = nil
	endPart = nil

	local currentMap = workspace:FindFirstChild("CurrentMap")
	local searchTargets = {}

	if currentMap then
		table.insert(searchTargets, currentMap)
	end
	table.insert(searchTargets, workspace)

	for _, target in ipairs(searchTargets) do
		if not startPart then
			for _, name in ipairs({"StartHere", "Start", "SpawnPoint"}) do
				local found = target:FindFirstChild(name, true)
				if found and found:IsA("BasePart") then
					startPart = found
					break
				end
			end
		end

		if not endPart then
			for _, name in ipairs({"End", "Finish", "FinishLine", "Goal"}) do
				local found = target:FindFirstChild(name, true)
				if found then
					if found:IsA("BasePart") then
						endPart = found
						break
					elseif found:IsA("Model") then
						local primary = found.PrimaryPart or found:FindFirstChildWhichIsA("BasePart")
						if primary then
							endPart = primary
							break
						end
					end
				end
			end
		end

		if startPart and endPart then break end
	end

	if startPart and endPart then
		print("?? Progress: Start=" .. startPart.Name .. " End=" .. endPart.Name)
	else
		if not startPart then warn("?? Progress: Start part not found") end
		if not endPart then warn("?? Progress: End part not found") end
	end
end

local function getProgress(plr)
	if not startPart or not endPart then return 0 end
	local char = plr.Character
	if not char then return 0 end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return 0 end
	local sY = startPart.Position.Y
	local eY = endPart.Position.Y
	local dist = eY - sY
	if dist == 0 then dist = 0.0001 end
	return math.clamp((hrp.Position.Y - sY) / dist, 0, 1)
end

-- ============================================
-- CREATE MARKER WITH PROPER HEAD THUMBNAIL
-- ============================================

local function createMarker(plr, idx)
	if playerMarkers[plr.UserId] then return end
	local color = getColor(idx)

	local isLocal = (plr == player)
	local size = isLocal and 30 or 24

	local marker = Instance.new("Frame")
	marker.Name = "Marker_" .. plr.Name
	marker.Size = UDim2.new(0, size, 0, size)
	marker.Position = UDim2.new(0.5, -math.floor(size / 2), 1, -math.floor(size / 2))
	marker.AnchorPoint = Vector2.new(0, 0.5)
	marker.BackgroundColor3 = color
	marker.BorderSizePixel = 0
	marker.ZIndex = isLocal and 15 or 10
	marker.ClipsDescendants = true
	marker.Parent = container

	Instance.new("UICorner", marker).CornerRadius = UDim.new(1, 0)

	local mStroke = Instance.new("UIStroke")
	mStroke.Name = "MarkerStroke"
	mStroke.Thickness = isLocal and 3 or 2
	mStroke.Color = isLocal and Color3.fromRGB(255, 255, 50) or Color3.fromRGB(255, 255, 255)
	mStroke.Parent = marker

	-- Player face image — fills the entire circle
	local faceImg = Instance.new("ImageLabel")
	faceImg.Name = "FaceImage"
	faceImg.Size = UDim2.new(1, 0, 1, 0)
	faceImg.Position = UDim2.new(0, 0, 0, 0)
	faceImg.BackgroundTransparency = 1
	faceImg.ScaleType = Enum.ScaleType.Crop
	faceImg.ZIndex = (isLocal and 16 or 11)
	faceImg.Parent = marker
	-- No separate UICorner needed — parent ClipsDescendants handles circular clipping

	-- Load headshot thumbnail
	task.spawn(function()
		local success, content, isReady = pcall(function()
			return Players:GetUserThumbnailAsync(
				plr.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)

		if success and content and content ~= "" then
			-- content is the URL, isReady is boolean
			if faceImg and faceImg.Parent then
				faceImg.Image = content
				-- Hide the colored background so only the face shows
				marker.BackgroundTransparency = 1
				print("?? Loaded face for", plr.Name)
			end
		else
			-- Failed to load — keep colored circle with first letter
			local letterLabel = Instance.new("TextLabel")
			letterLabel.Size = UDim2.new(1, 0, 1, 0)
			letterLabel.BackgroundTransparency = 1
			letterLabel.Text = string.upper(string.sub(plr.Name, 1, 1))
			letterLabel.Font = Enum.Font.GothamBold
			letterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			letterLabel.TextScaled = true
			letterLabel.ZIndex = isLocal and 16 or 11
			letterLabel.Parent = marker
			warn("?? Failed to load face for", plr.Name, "- using letter")
		end
	end)

	playerMarkers[plr.UserId] = marker
end

local function removeMarker(plr)
	if playerMarkers[plr.UserId] then
		playerMarkers[plr.UserId]:Destroy()
		playerMarkers[plr.UserId] = nil
	end
end

local function clearMarkers()
	for uid, m in pairs(playerMarkers) do
		m:Destroy()
	end
	playerMarkers = {}
end

-- ============================================
-- VISIBILITY + ROUND RESET
-- ============================================

local function updateVisibility()
	local isPlaying = (GameState.Value == "Playing")
	progressGui.Enabled = isPlaying

	if isPlaying then
		clearMarkers()
		task.delay(0.5, function()
			findStartAndEnd()
		end)
	end
end

GameState:GetPropertyChangedSignal("Value"):Connect(updateVisibility)
updateVisibility()

-- ============================================
-- UPDATE LOOP
-- ============================================

RunService.RenderStepped:Connect(function()
	if GameState.Value ~= "Playing" then return end
	if not startPart or not endPart then return end

	local allPlayers = Players:GetPlayers()
	for i, plr in ipairs(allPlayers) do
		if not playerMarkers[plr.UserId] then
			createMarker(plr, i)
		end
	end

	local localProg = getProgress(player)
	barFill.Size = UDim2.new(1, 0, localProg, 0)

	for _, plr in ipairs(allPlayers) do
		local m = playerMarkers[plr.UserId]
		if m then
			local prog = getProgress(plr)
			local yPos = 1 - prog
			local halfSize = (plr == player) and -15 or -12
			m.Position = UDim2.new(0.5, halfSize, yPos, 0)
		end
	end
end)

Players.PlayerRemoving:Connect(removeMarker)
print("? Progress GUI (all players with faces) loaded")