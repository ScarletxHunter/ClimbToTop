-- ============================================
-- CAMERA ZOOM - Set fixed zoom distance
-- Place in: StarterPlayer > StarterPlayerScripts
-- ============================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ============================================
-- CAMERA SETTINGS (EDIT THESE!)
-- ============================================

local CAMERA_ZOOM = {
	MinDistance = 10,  -- Closest zoom (change this!)
	MaxDistance = 50,  -- Farthest zoom (change this!)
	DefaultDistance = 25, -- Starting zoom

	-- LOCK CAMERA? (no scrolling)
	Locked = false, -- Set to true to lock at one zoom level
	LockedDistance = 25, -- Distance if locked
}

-- ============================================
-- APPLY SETTINGS
-- ============================================

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

if CAMERA_ZOOM.Locked then
	-- LOCKED MODE: Can't zoom in/out
	player.CameraMinZoomDistance = CAMERA_ZOOM.LockedDistance
	player.CameraMaxZoomDistance = CAMERA_ZOOM.LockedDistance
	player.CameraMode = Enum.CameraMode.Classic
	print("?? Camera locked at:", CAMERA_ZOOM.LockedDistance, "studs")
else
	-- FREE MODE: Can zoom with scroll wheel
	player.CameraMinZoomDistance = CAMERA_ZOOM.MinDistance
	player.CameraMaxZoomDistance = CAMERA_ZOOM.MaxDistance
	player.CameraMode = Enum.CameraMode.Classic
	print("?? Camera zoom range:", CAMERA_ZOOM.MinDistance, "-", CAMERA_ZOOM.MaxDistance, "studs")
end

-- Reset camera on respawn
player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")

	if CAMERA_ZOOM.Locked then
		player.CameraMinZoomDistance = CAMERA_ZOOM.LockedDistance
		player.CameraMaxZoomDistance = CAMERA_ZOOM.LockedDistance
	else
		player.CameraMinZoomDistance = CAMERA_ZOOM.MinDistance
		player.CameraMaxZoomDistance = CAMERA_ZOOM.MaxDistance
	end
end)

print("? Camera zoom script loaded")