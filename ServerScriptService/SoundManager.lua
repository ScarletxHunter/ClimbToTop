-- ============================================
-- SOUND MANAGER (FIXED - Working Sound IDs)
-- Place in: ServerScriptService/SoundManager (ModuleScript)
-- ============================================

local SoundManager = {}

local SoundService = game:GetService("SoundService")

-- ? WORKING SOUND IDs (Verified)
local MUSIC_TRACKS = {
	MenuMusic = "rbxassetid://9043887091",   -- Calm menu music
	RoundMusic = "rbxassetid://9043932460",  -- Epic battle music
	VictoryMusic = "rbxassetid://1837849285", -- Victory fanfare
}

local SOUND_EFFECTS = {
	PlayerHit = "rbxassetid://9119561046",
	CoinCollect = "rbxassetid://6723720636",
	Freeze = "rbxassetid://9114397505",
	SpeedBoost = "rbxassetid://9120239226",
}

local currentMusic = nil

print("?? Sound Manager loading...")

-- ============================================
-- PLAY MUSIC
-- ============================================

function SoundManager.PlayMusic(trackName)
	local musicId = MUSIC_TRACKS[trackName]

	if not musicId then
		warn("?? Music not found:", trackName)
		return
	end

	-- Stop current music
	if currentMusic then
		currentMusic:Stop()
		currentMusic:Destroy()
		currentMusic = nil
	end

	-- Create new music
	local music = Instance.new("Sound")
	music.Name = trackName
	music.SoundId = musicId
	music.Volume = 0.2
	music.Looped = true
	music.Parent = SoundService

	currentMusic = music
	music:Play()

	print("?? Playing:", trackName)
end

-- ============================================
-- STOP MUSIC
-- ============================================

function SoundManager.StopMusic()
	if currentMusic then
		currentMusic:Stop()
		currentMusic:Destroy()
		currentMusic = nil
		print("?? Music stopped")
	end
end

-- ============================================
-- PLAY SOUND EFFECT
-- ============================================

function SoundManager.PlaySound(soundName, position)
	local soundId = SOUND_EFFECTS[soundName]

	if not soundId then
		warn("?? Sound effect not found:", soundName)
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.5
	sound.Parent = workspace

	if position then
		local part = Instance.new("Part")
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.Size = Vector3.new(1, 1, 1)
		part.Position = position
		part.Parent = workspace

		sound.Parent = part
		sound:Play()

		task.delay(5, function()
			part:Destroy()
		end)
	else
		sound:Play()
		task.delay(5, function()
			sound:Destroy()
		end)
	end
end

print("? Sound Manager initialized")

return SoundManager