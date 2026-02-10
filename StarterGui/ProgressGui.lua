-- =========================================================
-- PROGRESS BAR SCRIPT (STUDIO-RESPECT; VERTICAL FILL)
-- Place in: StarterGui/ProgressGui/LocalScript
-- =========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- UI References (uses positions from Studio!)
local progressGui = script.Parent
local bgFrame = progressGui:WaitForChild("BG")
local fillFrame = bgFrame:WaitForChild("Start")
local startCap = bgFrame:WaitForChild("StartCap")
local endCap = bgFrame:WaitForChild("End")
local playerMarker = bgFrame:WaitForChild("PlayerMarker")

-- Store original Studio layout
local originalMarkerPosition = playerMarker.Position
local originalMarkerSize = playerMarker.Size
local originalMarkerAnchorPoint = playerMarker.AnchorPoint
local originalFillSize = fillFrame.Size
local originalFillPosition = fillFrame.Position
local originalFillAnchorPoint = fillFrame.AnchorPoint

-- Map progress parts
local startPart = nil
local endPart = nil
local totalDistance = 100
local startY = 0
local endY = 100

-- Remote: phase tracking
local currentPhase = "Waiting"
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEvents then
	local timerEvent = remoteEvents:FindFirstChild("TimerUpdate")
	if timerEvent then
		timerEvent.OnClientEvent:Connect(function(_, phase)
			currentPhase = phase or "Waiting"
		end)
	end
end

-- Find Start/End parts in map
local function findMapParts()
	local currentMap = workspace:FindFirstChild("CurrentMap")
	if currentMap then
		startPart = currentMap:FindFirstChild("StartHere", true) or currentMap:FindFirstChild("Start", true)
		endPart = currentMap:FindFirstChild("End", true) or currentMap:FindFirstChild("Finish", true)
	else
		startPart = workspace:FindFirstChild("StartHere", true) or workspace:FindFirstChild("Start", true)
		endPart = workspace:FindFirstChild("End", true) or workspace:FindFirstChild("Finish", true)
	end
	if startPart and endPart then
		startY = startPart.Position.Y
		endY = endPart.Position.Y
		totalDistance = math.max(math.abs(endY - startY), 0.0001)
		return true
	end
	return false
end

-- Color gradient (green -> yellow -> orange)
local function lerp(a, b, t)
	return a + (b - a) * t
end
local function getColorForProgress(progress)
	if progress < 0.5 then
		local alpha = progress / 0.5
		return Color3.new(lerp(0.2, 1, alpha), lerp(0.8, 0.8, alpha), 0)
	else
		local alpha = (progress - 0.5) / 0.5
		return Color3.new(1, lerp(0.8, 0.4, alpha), 0)
	end
end

-- Player thumbnail
local function loadPlayerThumbnail()
	local success, content = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)
	if success and content then
		playerMarker.Image = content
		playerMarker.ImageTransparency = 0
	else
		playerMarker.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		playerMarker.BackgroundTransparency = 0
	end
end

-- Show bar only in round and if map has parts
local function updateVisibility()
	local isRoundActive = (currentPhase == "Round")
	local hasMapParts = findMapParts()
	local shouldShow = isRoundActive and hasMapParts

	progressGui.Enabled = shouldShow
	bgFrame.Visible = shouldShow
end

-- Check visibility periodically so UI always responds
task.spawn(function()
	while true do
		updateVisibility()
		task.wait(2)
	end
end)

-- Main update loop
local currentProgress = 0
local targetProgress = 0
local smoothSpeed = 0.15

RunService.RenderStepped:Connect(function()
	if not progressGui.Enabled then return end

	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Calculate progress (0 to 1)
	local playerY = hrp.Position.Y
	targetProgress = math.clamp((playerY - startY) / totalDistance, 0, 1)
	currentProgress = lerp(currentProgress, targetProgress, smoothSpeed)

	-- ====== FILL BAR (UPWARD) ======
	fillFrame.Size = UDim2.new(
		originalFillSize.X.Scale, 
		originalFillSize.X.Offset,
		currentProgress,    -- Fill upward
		0
	)
	fillFrame.BackgroundColor3 = getColorForProgress(currentProgress)

	-- ====== MARKER POSITION (UP BAR) ======
	playerMarker.Position = UDim2.new(
		originalMarkerPosition.X.Scale,
		originalMarkerPosition.X.Offset,
		1 - currentProgress,  -- Moves up as progress increases (1 = bottom, 0 = top)
		0
	)
end)

-- Reset on respawn
player.CharacterAdded:Connect(function()
	currentProgress = 0
	targetProgress = 0
	task.wait(1)
	loadPlayerThumbnail()
	updateVisibility()
end)

-- Initial load
task.spawn(loadPlayerThumbnail)

print("? Progress Bar loaded (Studio layout respected)")