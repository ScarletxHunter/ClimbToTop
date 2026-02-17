-- ============================================
-- CLIENT SOUND HANDLER - ALL sounds present
-- Place in: StarterPlayer/StarterPlayerScripts/ClientSoundHandler (LocalScript)
-- Change any ID here to swap sounds
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SOUND_IDS = {
	-- ============ GAME EVENTS ============
	ObjectSpawn  = "rbxassetid://3398620867",
	PlayerHit    = "rbxassetid://9125402735",
	PlayerWin    = "rbxassetid://3398620867",
	Countdown    = "rbxassetid://9120386436",
	RoundStart   = "rbxassetid://3398620867",
	RoundEnd     = "rbxassetid://3398620867",
	WinFanfare   = "rbxassetid://3398620867",
	WinnerDisplay = "rbxassetid://3398620867",
	Transition   = "rbxassetid://3398620867",

	-- ============ UI SOUNDS ============
	VoteClick    = "rbxassetid://3398620867",
	ButtonClick  = "rbxassetid://3398620867",
	ButtonHover  = "rbxassetid://3398620867",

	-- ============ SHOP / COINS ============
	CoinCollect  = "rbxassetid://3398620867",
	Purchase     = "rbxassetid://3398620867",
	Error        = "rbxassetid://3398620867",
	NotEnoughCoins = "rbxassetid://3398620867",

	-- ============ TRAIL ============
	TrailEquip   = "rbxassetid://3398620867",
	TrailUnequip = "rbxassetid://3398620867",

	-- ============ WEAPONS ============
	WeaponUse    = "rbxassetid://3398620867",
	PushTool     = "rbxassetid://3398620867",
	Hammer       = "rbxassetid://3398620867",
	IceStaff     = "rbxassetid://3398620867",
	GravityHammer = "rbxassetid://3398620867",
	WavePush     = "rbxassetid://3398620867",

	-- ============ RAGDOLL ============
	RagdollSelf  = "rbxassetid://9125402735",
	RagdollOther = "rbxassetid://3398620867",

	-- ============ MISC ============
	ShopOpen     = "rbxassetid://3398620867",
	ShopClose    = "rbxassetid://3398620867",
	LevelUp      = "rbxassetid://3398620867",
}

local VOLUMES = {
	PlayerHit    = 0.7,
	RagdollSelf  = 0.8,
	CoinCollect  = 0.6,
	WinFanfare   = 0.9,
	WinnerDisplay = 0.8,
	Transition   = 0.5,
	Countdown    = 0.7,
	RoundStart   = 0.8,
	Error        = 0.6,
}

local DEFAULT_VOLUME = 0.5

-- ============================================
-- CREATE SOUND OBJECTS
-- ============================================

local sfxFolder = SoundService:FindFirstChild("LocalSFX")
if sfxFolder then sfxFolder:Destroy() end

sfxFolder = Instance.new("Folder")
sfxFolder.Name = "LocalSFX"
sfxFolder.Parent = SoundService

for name, id in pairs(SOUND_IDS) do
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = VOLUMES[name] or DEFAULT_VOLUME
	sound.Looped = false
	sound.Parent = sfxFolder
end

print("?? Created", #sfxFolder:GetChildren(), "sound objects")

-- ============================================
-- PLAY SOUND FUNCTION (can be called from anywhere)
-- ============================================

local function playSound(sfxName)
	local sound = sfxFolder:FindFirstChild(sfxName)
	if sound then
		-- Clone and play so overlapping sounds work
		local clone = sound:Clone()
		clone.Parent = sfxFolder
		clone:Play()
		clone.Ended:Connect(function()
			clone:Destroy()
		end)
		-- Safety cleanup
		task.delay(5, function()
			if clone and clone.Parent then clone:Destroy() end
		end)
	else
		warn("?? Client SFX not found:", sfxName)
	end
end

-- Expose globally so other client scripts can use it
_G.PlayClientSound = playSound

-- ============================================
-- LISTEN FOR SERVER EVENTS
-- ============================================

local PlaySoundEvent = ReplicatedStorage:WaitForChild("PlaySoundEvent", 10)

if PlaySoundEvent then
	PlaySoundEvent.OnClientEvent:Connect(function(sfxName)
		playSound(sfxName)
	end)
	print("   ? PlaySoundEvent connected")
else
	warn("   ?? PlaySoundEvent not found — server-triggered sounds disabled")
end

-- ============================================
-- LISTEN FOR RAGDOLL SOUNDS
-- ============================================

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if remoteEvents then
	local ragdollEvent = remoteEvents:FindFirstChild("PlayerRagdolled")
	if not ragdollEvent then
		ragdollEvent = remoteEvents:WaitForChild("PlayerRagdolled", 10)
	end

	if ragdollEvent then
		ragdollEvent.OnClientEvent:Connect(function(ragdollType, position)
			if ragdollType == "self" then
				playSound("RagdollSelf")
			elseif ragdollType == "other" then
				playSound("RagdollOther")
			end
		end)
		print("   ? Ragdoll sounds connected")
	end
end

-- ============================================
-- AUTO-HOOK BUTTON CLICKS
-- ============================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hookedButtons = {}

local function hookButton(btn)
	if hookedButtons[btn] then return end
	hookedButtons[btn] = true
	btn.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
	end)
end

local function scanButtons()
	for _, desc in ipairs(playerGui:GetDescendants()) do
		if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and not hookedButtons[desc] then
			hookButton(desc)
		end
	end
end

playerGui.DescendantAdded:Connect(function(desc)
	if desc:IsA("TextButton") or desc:IsA("ImageButton") then
		task.defer(function() hookButton(desc) end)
	end
end)

task.delay(3, scanButtons)
task.spawn(function()
	while true do
		task.wait(10)
		scanButtons()
	end
end)

print("   ? Auto button click sounds active")

-- ============================================
-- COIN COLLECT SOUND
-- ============================================

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 15)
	if not leaderstats then return end
	local coins = leaderstats:WaitForChild("Coins", 10)
	if not coins then return end

	local lastValue = coins.Value
	local initialized = false
	task.delay(3, function()
		initialized = true
		lastValue = coins.Value
	end)

	coins.Changed:Connect(function(newValue)
		if not initialized then
			lastValue = newValue
			return
		end
		if newValue > lastValue then
			playSound("CoinCollect")
		end
		lastValue = newValue
	end)
	print("   ? Coin collect sound connected")
end)

-- ============================================
-- ROUND START / END SOUNDS
-- ============================================

task.spawn(function()
	local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
	if not gameValues then return end
	local gameState = gameValues:FindFirstChild("GameState")
	if not gameState then return end

	local lastState = gameState.Value

	gameState:GetPropertyChangedSignal("Value"):Connect(function()
		local newState = gameState.Value
		if newState == "Playing" and lastState ~= "Playing" then
			playSound("RoundStart")
		elseif newState == "RoundEnd" and lastState ~= "RoundEnd" then
			playSound("RoundEnd")
		end
		lastState = newState
	end)
	print("   ? Round start/end sounds connected")
end)

print("?? Client Sound Handler loaded")
print("   ?? Total sounds:", #sfxFolder:GetChildren())