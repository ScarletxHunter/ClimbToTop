-- ============================================
-- CLIENT SOUND HANDLER - Plays sounds locally
-- Place in: StarterPlayer/StarterPlayerScripts/ClientSoundHandler (LocalScript)
-- Fixed: Looks in RemoteEvents folder + timeout (no infinite yield)
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

print("?? Client Sound Handler loading...")

-- Sound IDs (must match server!)
local SOUND_IDS = {
	ObjectSpawn = "rbxassetid://3398620867",
	PlayerHit = "rbxassetid://9125402735",
	PlayerWin = "rbxassetid://3398620867",
	Countdown = "rbxassetid://9120386436",
	VoteClick = "rbxassetid://3398620867",
}

local VOLUMES = {
	SFX = 0.5,
}

-- Create local SFX folder
local sfxFolder = Instance.new("Folder")
sfxFolder.Name = "LocalSFX"
sfxFolder.Parent = SoundService

-- Create sounds
for name, id in pairs(SOUND_IDS) do
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = VOLUMES.SFX
	sound.Looped = false
	sound.Parent = sfxFolder
end

-- Look for PlaySoundEvent in MULTIPLE places (with timeout, no infinite yield)
local PlaySoundEvent = nil

-- Check RemoteEvents folder first
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEvents then
	PlaySoundEvent = remoteEvents:FindFirstChild("PlaySoundEvent")
end

-- Check ReplicatedStorage root
if not PlaySoundEvent then
	PlaySoundEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
end

-- Wait briefly if not found yet
if not PlaySoundEvent then
	if remoteEvents then
		PlaySoundEvent = remoteEvents:WaitForChild("PlaySoundEvent", 5)
	end
end

if not PlaySoundEvent then
	PlaySoundEvent = ReplicatedStorage:WaitForChild("PlaySoundEvent", 3)
end

if PlaySoundEvent then
	PlaySoundEvent.OnClientEvent:Connect(function(sfxName)
		local sound = sfxFolder:FindFirstChild(sfxName)
		if sound then
			sound:Play()
		else
			warn("?? Client SFX not found:", sfxName)
		end
	end)
	print("? Client Sound Handler loaded! (connected to PlaySoundEvent)")
else
	-- Not an error - just means server doesn't use PlaySoundEvent yet
	print("?? Client Sound Handler loaded (PlaySoundEvent not found - SFX disabled)")
end