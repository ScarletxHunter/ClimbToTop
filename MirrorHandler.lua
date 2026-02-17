-- ============================================
-- MIRROR HANDLER - Lobby window transparency
-- "Mirror" part in workspace: visible in lobby, semi-transparent during round
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local workspaceService = game:GetService("Workspace")

local GameValues = ReplicatedStorage:WaitForChild("GameValues")
local GameState = GameValues:WaitForChild("GameState")

local mirrorPart = workspaceService:WaitForChild("Mirror", 10)
if not mirrorPart then
	warn("?? Mirror part not found in Workspace!")
	return
end

local LOBBY_TRANSPARENCY = 0    -- Fully visible / opaque in lobby
local PLAYING_TRANSPARENCY = 0.5 -- Semi-transparent during rounds
local TWEEN_TIME = 1.5

local function updateMirror()
	local state = GameState.Value
	local targetTransparency

	if state == "Playing" then
		targetTransparency = PLAYING_TRANSPARENCY
	else
		targetTransparency = LOBBY_TRANSPARENCY
	end

	local tween = TweenService:Create(
		mirrorPart,
		TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ Transparency = targetTransparency }
	)
	tween:Play()

	print("?? Mirror transparency ?", targetTransparency, "(State:", state .. ")")
end

GameState:GetPropertyChangedSignal("Value"):Connect(updateMirror)

-- Initial
updateMirror()

print("? Mirror Handler initialized")