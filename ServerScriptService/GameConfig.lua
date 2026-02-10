-- ============================================
-- GAME CONFIG - Central configuration file
-- Edit all game settings here!
-- ============================================

local GameConfig = {}

-- ============================================
-- TIMING SETTINGS
-- ============================================
GameConfig.Timing = {
	IntermissionTime = 30,      -- Lobby wait time
	VotingTime = 10,            -- Map voting duration
	RoundTime = 30,            -- Round duration (30 sec )
	RoundEndTime = 5,           -- Results screen duration
	MinPlayers = 1,             -- Minimum players to start

	-- Transition effects
	FadeInDuration = 1.5,       -- Fade to black duration
	FadeOutDuration = 1.5,      -- Fade from black duration
	LoadingScreenDuration = 5,  -- Black screen loading time
}

-- ============================================
-- COIN REWARDS (Customize coin amounts!)
-- ============================================
GameConfig.CoinRewards = {
	-- Win rewards
	WinReward = 10000,        -- 1st place (touches End first)
	SecondPlace = 10000,      -- 2nd place
	ThirdPlace = 75,        -- 3rd place

	-- Progress-based rewards (didn't reach End)
	Progress75 = 30,        -- Made it 75% up
	Progress50 = 20,        -- Made it 50% up
	Progress25 = 10,        -- Made it 25% up
	Participation = 5,      -- At least tried!

	-- Lobby coins (passive spawning during intermission)
	LobbyCoins = {
		Enabled = true,
		CoinValue = 1,       -- Coins per pickup
		CoinsPerSpawn = 5,   -- How many spawn at once
		SpawnInterval = 30,  -- Seconds between spawns
		Lifetime = 60,       -- Seconds before coin despawns
		SpawnArea = {
			Center = Vector3.new(0, 5, 0),  -- Offset from SpawnLocation
			Radius = 30,                     -- How far coins spread
		},
	},

	-- Map coins (collected during climb) WITH RESPAWNING
	MapCoins = {
		Enabled = true,
		CoinValue = 3,       -- Coins per pickup
		RespawnTime = 20,    -- Seconds to respawn after collection (CHANGE THIS!)
		CoinsToSpawn = 15,   -- How many coins (if automatic)
		SpawnHeightPercent = {
			Min = 20,        -- Start spawning at 20% height
			Max = 90,        -- Stop spawning at 90% height
		},
		SpreadRadius = 15,   -- How far from center
	},

	-- Top platform coins (at End part) - ONE TIME ONLY
	TopPlatformCoins = {
		Enabled = true,
		CoinValue = 5,       -- Coins per pickup
		-- NO respawn - collected once per round
	},
}

-- ============================================
-- OBJECT SPAWNER DEFAULTS
-- (Can be overridden per-spawner using attributes)
-- ============================================
GameConfig.ObjectSpawner = {
	SpawnInterval = 2,           -- Seconds between spawns
	SpawnIntervalRandom = 0.5,   -- Random variation
	ObjectLifetime = 25,         -- Seconds before auto-despawn
	MaxObjectsAtOnce = 20,       -- Max active objects per spawner
	SpawnCount = 10,             -- Objects per spawn burst

	-- Physics
	Bounciness = 0.5,
	Friction = 0.5,
	Gravity = 1.0,               -- Gravity multiplier

	-- Velocity
	InitialVelocity = Vector3.new(0, -40, 0),  -- Starting velocity
	RandomVelocity = Vector3.new(5, 0, 5),     -- Random offset range
}

-- ============================================
-- RAGDOLL SETTINGS
-- ============================================
GameConfig.Ragdoll = {
	Duration = 1,        -- How long player is stunned (seconds)
	Cooldown = 3,        -- Can't be hit again for X seconds
}

-- ============================================
-- SHOP/TOOL SETTINGS
-- ============================================
GameConfig.Shop = {
	-- Tool prices (in coins)
	ToolPrices = {
		PushTool = 0,      -- Free starter tool
		Hammer = 500,
		IceStaff = 1000,
	},

	-- Timed weapons (coins purchase)
	TimedWeapons = {
		Enabled = true,
		DefaultDuration = 120,  -- Seconds (2 minutes)
	},
}

-- ============================================
-- PODIUM SETTINGS
-- ============================================
GameConfig.Podium = {
	DisplayDuration = 60,  -- How long winners stay on podium (seconds)

	-- Clone settings
	CloneTransparency = 0.3,  -- 0 = solid, 1 = invisible
	ShowSparkles = true,

	-- Pedestal colors (optional - for auto-coloring)
	Colors = {
		FirstPlace = Color3.fromRGB(255, 215, 0),   -- Gold
		SecondPlace = Color3.fromRGB(192, 192, 192), -- Silver
		ThirdPlace = Color3.fromRGB(205, 127, 50),   -- Bronze
	},
}

-- ============================================
-- CAMERA SETTINGS
-- ============================================
GameConfig.Camera = {
	MinZoom = 10,     -- Closest zoom
	MaxZoom = 50,     -- Farthest zoom
	DefaultZoom = 25, -- Starting zoom
	Locked = false,   -- If true, can't zoom in/out
}

-- ============================================
-- SOUND IDs (Replace with your own!)
-- ============================================
GameConfig.Sounds = {
	Music = {
		MenuMusic = "rbxassetid://1838673350",
		Map1Music = "rbxassetid://1845458027",
		Map2Music = "rbxassetid://1845458027",
		Map3Music = "rbxassetid://1845458027",
		VictoryMusic = "rbxassetid://1843463175",
	},

	SFX = {
		ObjectSpawn = "rbxassetid://3398620867",
		PlayerHit = "rbxassetid://9125402735",
		PlayerWin = "rbxassetid://3398620867",
		Countdown = "rbxassetid://9120386436",
		VoteClick = "rbxassetid://3398620867",
		CoinPickup = "rbxassetid://3398620867",
	},

	Volumes = {
		Music = 0.3,
		SFX = 0.5,
	},
}

-- ============================================
-- VALIDATION - Check workspace setup
-- ============================================

function GameConfig.ValidateWorkspace()
	local errors = {}

	-- Check for Workspace containers
	if not workspace:FindFirstChild("MapContainer") then
		table.insert(errors, "Missing: Workspace/MapContainer")
	end

	if not workspace:FindFirstChild("FallingObjectsContainer") then
		table.insert(errors, "Missing: Workspace/FallingObjectsContainer")
	end

	-- Check for Lobby (optional - can be in Workspace root)
	local lobby = workspace:FindFirstChild("Lobby")
	if lobby then
		-- Check for WinnerPodium
		local podium = lobby:FindFirstChild("WinnerPodium")
		if podium then
			-- Check podium parts
			if not podium:FindFirstChild("FirstPlace") then
				table.insert(errors, "Missing: Workspace/Lobby/WinnerPodium/FirstPlace")
			end
			if not podium:FindFirstChild("SecondPlace") then
				table.insert(errors, "Missing: Workspace/Lobby/WinnerPodium/SecondPlace")
			end
			if not podium:FindFirstChild("ThirdPlace") then
				table.insert(errors, "Missing: Workspace/Lobby/WinnerPodium/ThirdPlace")
			end
		end
	end

	-- Check for SpawnLocation (can be in Lobby or Workspace root)
	local spawnLocation = (lobby and lobby:FindFirstChild("SpawnLocation")) or workspace:FindFirstChild("SpawnLocation")
	if not spawnLocation then
		table.insert(errors, "Missing: SpawnLocation (in Lobby or Workspace)")
	end

	-- Check ServerStorage
	local serverStorage = game:GetService("ServerStorage")
	if not serverStorage:FindFirstChild("Maps") then
		table.insert(errors, "Missing: ServerStorage/Maps")
	end

	-- Report results
	if #errors > 0 then
		warn("?? WORKSPACE SETUP ERRORS:")
		for _, error in ipairs(errors) do
			warn("   - " .. error)
		end
		return false, errors
	else
		print("? Workspace setup validated!")
		return true, {}
	end
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get config value safely
function GameConfig.Get(category, key, default)
	if GameConfig[category] and GameConfig[category][key] ~= nil then
		return GameConfig[category][key]
	end
	return default
end

-- Check if feature is enabled
function GameConfig.IsEnabled(feature)
	if feature == "LobbyCoins" then
		return GameConfig.CoinRewards.LobbyCoins.Enabled
	elseif feature == "MapCoins" then
		return GameConfig.CoinRewards.MapCoins.Enabled
	elseif feature == "TopPlatformCoins" then
		return GameConfig.CoinRewards.TopPlatformCoins.Enabled
	elseif feature == "TimedWeapons" then
		return GameConfig.Shop.TimedWeapons.Enabled
	elseif feature == "PodiumSparkles" then
		return GameConfig.Podium.ShowSparkles
	end

	return false
end

-- Get all map names from ServerStorage
function GameConfig.GetAvailableMaps()
	local maps = {}
	local serverStorage = game:GetService("ServerStorage")
	local mapsFolder = serverStorage:FindFirstChild("Maps")

	if mapsFolder then
		for _, mapFolder in pairs(mapsFolder:GetChildren()) do
			if mapFolder:IsA("Folder") then
				table.insert(maps, mapFolder.Name)
			end
		end
	end

	return maps
end

-- Print current config (for debugging)
function GameConfig.PrintConfig()
	print("=== GAME CONFIG ===")
	print("Intermission Time:", GameConfig.Timing.IntermissionTime)
	print("Round Time:", GameConfig.Timing.RoundTime)
	print("Min Players:", GameConfig.Timing.MinPlayers)
	print("")
	print("Win Reward:", GameConfig.CoinRewards.WinReward)
	print("Lobby Coins Enabled:", GameConfig.CoinRewards.LobbyCoins.Enabled)
	print("Map Coins Enabled:", GameConfig.CoinRewards.MapCoins.Enabled)
	print("Map Coins Respawn Time:", GameConfig.CoinRewards.MapCoins.RespawnTime, "seconds")
	print("Top Coins Enabled:", GameConfig.CoinRewards.TopPlatformCoins.Enabled)
	print("")
	print("Available Maps:", table.concat(GameConfig.GetAvailableMaps(), ", "))
	print("==================")
end

return GameConfig