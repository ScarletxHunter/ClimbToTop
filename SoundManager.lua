-- ============================================
-- SOUND MANAGER - All game sounds (Server)
-- Centralized sound config - change IDs here
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundManager = {}

-- ============================================
-- ?? SOUND CONFIGURATION - CHANGE ALL IDS HERE
-- ============================================
SoundManager.SOUND_IDS = {
	-- MUSIC
	MenuMusic       = "rbxassetid://1838673350",
	Map1Music       = "rbxassetid://1845458027",
	Map2Music       = "rbxassetid://1845458027",
	Map3Music       = "rbxassetid://1845458027",
	VictoryMusic    = "rbxassetid://1843463175",

	-- SFX
	ObjectSpawn     = "rbxassetid://3398620867",
	PlayerHit       = "rbxassetid://9125402735",
	PlayerWin       = "rbxassetid://3398620867",
	Countdown       = "rbxassetid://9120386436",
	VoteClick       = "rbxassetid://3398620867",
	ButtonClick     = "rbxassetid://3398620867",
	ButtonHover     = "rbxassetid://3398620867",
	CoinCollect     = "rbxassetid://3398620867",
	TrailEquip      = "rbxassetid://3398620867",
	Purchase        = "rbxassetid://3398620867",
	Error           = "rbxassetid://3398620867",
	Transition      = "rbxassetid://3398620867",
	RoundStart      = "rbxassetid://3398620867",
	WinFanfare      = "rbxassetid://3398620867",
}

SoundManager.VOLUMES = {
	Music = 0.3,
	SFX = 0.5,
}

-- Active state
local currentMusic = nil
local musicFolder = nil
local sfxFolder = nil

local function initialize()
	musicFolder = Instance.new("Folder")
	musicFolder.Name = "Music"
	musicFolder.Parent = SoundService

	sfxFolder = Instance.new("Folder")
	sfxFolder.Name = "SFX"
	sfxFolder.Parent = SoundService

	for name, id in pairs(SoundManager.SOUND_IDS) do
		if name:match("Music") then
			local sound = Instance.new("Sound")
			sound.Name = name
			sound.SoundId = id
			sound.Volume = SoundManager.VOLUMES.Music
			sound.Looped = (name ~= "VictoryMusic")
			sound.Parent = musicFolder
		else
			local sound = Instance.new("Sound")
			sound.Name = name
			sound.SoundId = id
			sound.Volume = SoundManager.VOLUMES.SFX
			sound.Looped = false
			sound.Parent = sfxFolder
		end
	end

	-- Remote for client sounds
	if not ReplicatedStorage:FindFirstChild("PlaySoundEvent") then
		local re = Instance.new("RemoteEvent")
		re.Name = "PlaySoundEvent"
		re.Parent = ReplicatedStorage
	end

	print("?? Sound Manager initialized")
end

function SoundManager.PlayMusic(musicName)
	if not musicFolder then initialize() end
	if currentMusic then currentMusic:Stop() end

	local sound = musicFolder:FindFirstChild(musicName)
	if sound then
		sound:Play()
		currentMusic = sound
		print("?? Playing:", musicName)
	else
		warn("? Music not found:", musicName)
	end
end

function SoundManager.StopMusic()
	if currentMusic then
		currentMusic:Stop()
		currentMusic = nil
	end
end

function SoundManager.PlaySFX(sfxName)
	if not sfxFolder then initialize() end
	local sound = sfxFolder:FindFirstChild(sfxName)
	if sound then sound:Play() end
end

function SoundManager.PlaySFXForPlayer(player, sfxName)
	local re = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
	if re then
		re:FireClient(player, sfxName)
	end
end

function SoundManager.PlaySFXForAll(sfxName)
	local re = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
	if re then
		re:FireAllClients(sfxName)
	end
end

initialize()

return SoundManager