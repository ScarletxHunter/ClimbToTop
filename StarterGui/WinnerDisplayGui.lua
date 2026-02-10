-- ============================================
-- WINNER DISPLAY GUI - ViewportFrame Display
-- Place in: StarterGui/WinnerDisplayGui/Container/LocalScript
--
-- FIX: Added safety checks for data format.
--      GameManager was sending (table) instead of
--      (player, time, rank). Now GameManager is fixed
--      but this script also validates data just in case.
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local container = script.Parent
local gui = container.Parent

local title = container:WaitForChild("Title")
local viewport = container:WaitForChild("CharacterViewport")
local winnerName = container:WaitForChild("WinnerName")
local winnerTime = container:WaitForChild("WinnerTime")

print("?? Winner Display GUI initializing...")

-- Wait for RemoteEvent
local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEventsFolder then
	warn("? RemoteEvents folder not found!")
	return
end

local ShowWinnerEvent = RemoteEventsFolder:WaitForChild("ShowWinner", 10)
if not ShowWinnerEvent then
	warn("? ShowWinner RemoteEvent not found!")
	return
end

print("? Found ShowWinner RemoteEvent")

-- Clear viewport
local function clearViewport()
	for _, obj in pairs(viewport:GetChildren()) do
		if not obj:IsA("UICorner") and not obj:IsA("UIStroke") then
			obj:Destroy()
		end
	end
end

-- Safe character clone with Archivable fix
local function safeCloneCharacter(character)
	local originalArchivable = {}
	for _, obj in pairs(character:GetDescendants()) do
		originalArchivable[obj] = obj.Archivable
		obj.Archivable = true
	end
	local charArchivable = character.Archivable
	character.Archivable = true

	local clone = character:Clone()

	character.Archivable = charArchivable
	for obj, val in pairs(originalArchivable) do
		if obj and obj.Parent then
			obj.Archivable = val
		end
	end

	return clone
end

-- Create 3D character in viewport
local function createViewportCharacter(targetPlayer)
	clearViewport()

	print("   ?? Creating viewport for", targetPlayer.Name)

	-- Wait for character if needed (with timeout)
	local character = targetPlayer.Character
	if not character then
		print("      ? Waiting for character...")
		local waited = 0
		while not targetPlayer.Character and waited < 3 do
			task.wait(0.5)
			waited = waited + 0.5
		end
		character = targetPlayer.Character
	end

	if not character then
		warn("   ?? No character to display after wait")
		return false
	end

	-- Wait a bit for character to fully load
	task.wait(0.3)

	-- Clone character with safety
	local success, charClone = pcall(function()
		return safeCloneCharacter(character)
	end)

	if not success or not charClone then
		warn("   ?? Failed to clone character:", success and "nil clone" or charClone)
		return false
	end

	-- Remove scripts and tools
	for _, obj in pairs(charClone:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
			obj:Destroy()
		elseif obj:IsA("Tool") then
			obj:Destroy()
		elseif obj:IsA("ForceField") then
			obj:Destroy()
		end
	end

	-- Set up humanoid
	local humanoid = charClone:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Health = humanoid.MaxHealth
	end

	-- Position character FIRST using PivotTo (before anchoring!)
	charClone:PivotTo(CFrame.new(0, 0, 0))

	-- THEN anchor all parts (after positioning)
	for _, part in pairs(charClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- Parent to viewport
	charClone.Parent = viewport

	-- Create camera close to face (mugshot style)
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(
		Vector3.new(0, 1.5, -2.5),
		Vector3.new(0, 1.3, 0)
	)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	print("   ? Created viewport character")
	return true
end

-- Show winner display
local function showWinner(winnerPlayer, timeTaken, rank)
	print("?? Showing winner display:", winnerPlayer.Name, timeTaken .. "s", "Rank:", rank)

	-- Update title based on rank
	if rank == 1 then
		title.Text = "?? 1ST PLACE!"
		title.BackgroundColor3 = Color3.fromRGB(255, 215, 0)  -- Gold
	elseif rank == 2 then
		title.Text = "?? 2ND PLACE!"
		title.BackgroundColor3 = Color3.fromRGB(192, 192, 192)  -- Silver
	elseif rank == 3 then
		title.Text = "?? 3RD PLACE!"
		title.BackgroundColor3 = Color3.fromRGB(205, 127, 50)  -- Bronze
	else
		title.Text = "? FINISHED!"
		title.BackgroundColor3 = Color3.fromRGB(0, 170, 255)  -- Blue
	end

	-- Update text
	winnerName.Text = winnerPlayer.Name
	winnerTime.Text = "Time: " .. timeTaken .. " seconds"

	-- Create character in viewport
	local success = createViewportCharacter(winnerPlayer)
	if not success then
		warn("?? Failed to create viewport, showing text only")
	end

	-- Animate in
	container.Visible = true
	container.Size = UDim2.new(0, 0, 0, 0)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(
		container,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0.35, 0, 0.6, 0),
			Position = UDim2.new(0.325, 0, 0.2, 0)
		}
	):Play()

	print("? Winner display shown!")

	-- Auto-hide after 5 seconds
	task.delay(5, function()
		hideWinner()
	end)
end

-- Hide winner display
function hideWinner()
	TweenService:Create(
		container,
		TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}
	):Play()

	task.delay(0.5, function()
		container.Visible = false
		clearViewport()
	end)
end

-- Listen for winner announcements
ShowWinnerEvent.OnClientEvent:Connect(function(winnerPlayer, timeTaken, rank)
	-- FIX: Validate the data format
	-- Old GameManager sent (table) instead of (player, number, number)
	-- This safety check handles both formats

	-- If first arg is a table (old format), skip it
	if typeof(winnerPlayer) == "table" then
		warn("?? Received old table format for ShowWinner, skipping")
		return
	end

	-- Validate winnerPlayer is an actual Player
	if not winnerPlayer or not winnerPlayer:IsA("Player") then
		warn("?? Invalid winnerPlayer received:", typeof(winnerPlayer))
		return
	end

	-- Default values
	timeTaken = tonumber(timeTaken) or 0
	rank = tonumber(rank) or 1

	print("?? CLIENT: Received winner event!", winnerPlayer.Name, timeTaken, "Rank:", rank)

	-- Wait a bit for character to stabilize
	task.wait(0.5)

	showWinner(winnerPlayer, timeTaken, rank)
end)

print("? Winner Display GUI loaded and listening")