-- ============================================
-- COIN MANAGER (FIXED - Uses YOUR Coin Model)
-- Place in: ServerScriptService/CoinManager (ModuleScript)
--
-- FIXES:
--   1. Uses actual "Coin" model from ServerStorage
--      (not ugly yellow cylinder parts)
--   2. Lobby spawns: workspace > LobbyCoins > CoinSpawn1, CoinSpawn2...
--      (was looking in wrong place: Lobby.CoinSpawns)
--   3. Map spawns: map > CoinSpawns > Coin1, Coin2...
--   4. Top coin spawns: map > TopCoinSpawns > TopCoin1, TopCoin2...
--   5. No more random fallback spawn positions
-- ============================================

local CoinManager = {}

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local COIN_VALUE = 1
local TOP_COIN_VALUE = 5           -- Top coins are worth more!
local LOBBY_COIN_RESPAWN_TIME = 5
local MAP_COIN_RESPAWN_TIME = 8
local COIN_COLLECTION_COOLDOWN = 0.5
local COIN_HOVER_HEIGHT = 2        -- How high above spawn point

-- State
local lobbyCoinSpawns = {}         -- {position1, position2, ...}
local mapCoinSpawns = {}           -- {position1, position2, ...}
local topCoinSpawns = {}           -- {position1, position2, ...}
local activeLobbyCoins = {}        -- {coin1, coin2, ...}
local activeMapCoins = {}
local activeTopCoins = {}
local lobbySpawnerActive = false
local mapSpawnerActive = false
local playerCooldowns = {}

print("?? CoinManager loading...")

-- ============================================
-- GET COIN MODEL FROM SERVERSTORAGE
-- ============================================

local function getCoinTemplate()
	local coinModel = ServerStorage:FindFirstChild("Coin")
	if coinModel then
		print("? Found Coin model in ServerStorage")
		return coinModel
	end

	warn("?? No 'Coin' model found in ServerStorage! Creating fallback.")

	-- Fallback: create a simple coin part if model missing
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Size = Vector3.new(2, 2, 0.5)
	coin.Shape = Enum.PartType.Cylinder
	coin.BrickColor = BrickColor.new("Bright yellow")
	coin.Material = Enum.Material.Neon
	coin.Anchored = true
	coin.CanCollide = false
	coin.Rotation = Vector3.new(0, 0, 90)
	return coin
end

-- ============================================
-- SPAWN COIN AT POSITION
-- ============================================

local function spawnCoin(position, parent, coinTable, coinValue)
	coinValue = coinValue or COIN_VALUE

	-- Clone the actual coin model from ServerStorage
	local template = getCoinTemplate()
	local coin = template:Clone()
	coin.Name = "ActiveCoin"

	-- Position the coin above the spawn point
	if coin:IsA("Model") then
		-- It's a Model, use PivotTo
		coin:PivotTo(CFrame.new(position + Vector3.new(0, COIN_HOVER_HEIGHT, 0)))

		-- Make sure all parts are anchored and non-collidable for collection
		local primaryPart = coin.PrimaryPart or coin:FindFirstChildWhichIsA("BasePart")
		if primaryPart then
			-- Set up touch detection on the primary part
			primaryPart.CanCollide = false

			primaryPart.Touched:Connect(function(hit)
				onCoinTouched(coin, hit, coinValue, coinTable)
			end)
		end

		-- Also connect Touched on ALL BaseParts in the model
		for _, part in pairs(coin:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Touched:Connect(function(hit)
					onCoinTouched(coin, hit, coinValue, coinTable)
				end)
			end
		end
	else
		-- It's a single Part
		coin.Position = position + Vector3.new(0, COIN_HOVER_HEIGHT, 0)
		coin.Anchored = true
		coin.CanCollide = false

		coin.Touched:Connect(function(hit)
			onCoinTouched(coin, hit, coinValue, coinTable)
		end)
	end

	coin.Parent = parent or workspace

	-- Rotation animation
	task.spawn(function()
		while coin and coin.Parent do
			if coin:IsA("Model") then
				local pivot = coin:GetPivot()
				coin:PivotTo(pivot * CFrame.Angles(0, math.rad(2), 0))
			else
				coin.Rotation = coin.Rotation + Vector3.new(0, 2, 0)
			end
			task.wait(0.03)
		end
	end)

	-- Bobbing animation
	task.spawn(function()
		local startPos = position + Vector3.new(0, COIN_HOVER_HEIGHT, 0)
		local time = 0
		while coin and coin.Parent do
			time = time + 0.05
			local newY = startPos.Y + math.sin(time * 2) * 0.5
			if coin:IsA("Model") then
				local pivot = coin:GetPivot()
				coin:PivotTo(CFrame.new(startPos.X, newY, startPos.Z) * (pivot - pivot.Position))
			else
				coin.Position = Vector3.new(startPos.X, newY, startPos.Z)
			end
			task.wait(0.05)
		end
	end)

	table.insert(coinTable, coin)
	return coin
end

-- ============================================
-- COLLECT COIN (defined as local before use)
-- ============================================

function onCoinTouched(coin, hit, coinValue, coinTable)
	if not hit or not hit.Parent then return end
	if not coin or not coin.Parent then return end

	local humanoid = hit.Parent:FindFirstChild("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	-- Cooldown check
	local cooldownKey = player.UserId .. "_" .. tostring(coin)
	if playerCooldowns[cooldownKey] then return end

	playerCooldowns[cooldownKey] = true
	task.delay(COIN_COLLECTION_COOLDOWN, function()
		playerCooldowns[cooldownKey] = nil
	end)

	-- Award coins
	coinValue = coinValue or COIN_VALUE

	if _G.UpdatePlayerCoins then
		_G.UpdatePlayerCoins(player, coinValue)
	else
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value = coins.Value + coinValue
			end
		end
	end

	-- Fire client notification (if GetCoins remote exists)
	local getCoins = ReplicatedStorage:FindFirstChild("GetCoins")
	if getCoins and getCoins:IsA("RemoteEvent") then
		pcall(function()
			getCoins:FireClient(player, coinValue)
		end)
	end

	print("??", player.Name, "collected", coinValue, "coin(s)!")

	-- Remove coin from active list
	local index = table.find(coinTable, coin)
	if index then
		table.remove(coinTable, index)
	end

	-- Destroy coin
	coin:Destroy()
end

-- ============================================
-- LOAD LOBBY SPAWNS
-- workspace > LobbyCoins > CoinSpawn1, CoinSpawn2...
-- ============================================

local function loadLobbySpawns()
	lobbyCoinSpawns = {}

	-- YOUR STRUCTURE: workspace > LobbyCoins folder
	local lobbyCoinsFolder = workspace:FindFirstChild("LobbyCoins")
	if lobbyCoinsFolder then
		for _, spawn in pairs(lobbyCoinsFolder:GetChildren()) do
			if spawn:IsA("BasePart") then
				table.insert(lobbyCoinSpawns, spawn.Position)
			end
		end
		print("? Loaded", #lobbyCoinSpawns, "lobby coin spawns from workspace.LobbyCoins")
	else
		warn("?? workspace.LobbyCoins folder not found! No lobby coins will spawn.")
	end
end

-- ============================================
-- LOAD MAP SPAWNS
-- map > CoinSpawns > Coin1, Coin2...
-- map > TopCoinSpawns > TopCoin1, TopCoin2...
-- ============================================

local function loadMapSpawns(map)
	mapCoinSpawns = {}
	topCoinSpawns = {}

	if not map then return end

	-- Regular coin spawns: map > CoinSpawns > Coin1, Coin2...
	local coinSpawnsFolder = map:FindFirstChild("CoinSpawns")
	if coinSpawnsFolder then
		for _, spawn in pairs(coinSpawnsFolder:GetChildren()) do
			if spawn:IsA("BasePart") then
				table.insert(mapCoinSpawns, spawn.Position)
			end
		end
		print("? Loaded", #mapCoinSpawns, "map coin spawns from CoinSpawns")
	else
		warn("?? No CoinSpawns folder found in map:", map.Name)
	end

	-- Top coin spawns (harder to reach, worth more)
	-- map > TopCoinSpawns > TopCoin1, TopCoin2...
	local topSpawnsFolder = map:FindFirstChild("TopCoinSpawns")
	if topSpawnsFolder then
		for _, spawn in pairs(topSpawnsFolder:GetChildren()) do
			if spawn:IsA("BasePart") then
				table.insert(topCoinSpawns, spawn.Position)
			end
		end
		print("? Loaded", #topCoinSpawns, "top coin spawns from TopCoinSpawns")
	else
		print("?? No TopCoinSpawns folder in map (optional)")
	end
end

-- ============================================
-- START LOBBY COINS
-- ============================================

function CoinManager.StartLobbyCoins()
	if lobbySpawnerActive then return end
	lobbySpawnerActive = true

	loadLobbySpawns()

	if #lobbyCoinSpawns == 0 then
		warn("?? No lobby coin spawns found, skipping")
		lobbySpawnerActive = false
		return
	end

	print("?? Starting lobby coin spawner with", #lobbyCoinSpawns, "spawns...")

	-- Spawn initial coins
	for _, position in pairs(lobbyCoinSpawns) do
		spawnCoin(position, workspace, activeLobbyCoins, COIN_VALUE)
	end

	print("?? Spawned", #activeLobbyCoins, "lobby coins")

	-- Respawn loop
	task.spawn(function()
		while lobbySpawnerActive do
			task.wait(LOBBY_COIN_RESPAWN_TIME)
			if not lobbySpawnerActive then break end

			-- Respawn missing coins
			local currentCount = #activeLobbyCoins
			local targetCount = #lobbyCoinSpawns

			if currentCount < targetCount then
				-- Figure out which spawn positions don't have a coin nearby
				for _, spawnPos in pairs(lobbyCoinSpawns) do
					local hasCoin = false
					for _, coin in pairs(activeLobbyCoins) do
						if coin and coin.Parent then
							local coinPos
							if coin:IsA("Model") then
								coinPos = coin:GetPivot().Position
							else
								coinPos = coin.Position
							end
							if (coinPos - spawnPos).Magnitude < 5 then
								hasCoin = true
								break
							end
						end
					end

					if not hasCoin then
						spawnCoin(spawnPos, workspace, activeLobbyCoins, COIN_VALUE)
					end
				end
			end
		end
	end)
end

-- ============================================
-- STOP LOBBY COINS
-- ============================================

function CoinManager.StopLobbyCoins()
	if not lobbySpawnerActive then return end
	lobbySpawnerActive = false

	for _, coin in pairs(activeLobbyCoins) do
		if coin and coin.Parent then
			coin:Destroy()
		end
	end
	activeLobbyCoins = {}

	print("?? Stopped lobby coin spawner")
end

-- ============================================
-- START MAP COINS
-- ============================================

function CoinManager.StartMapCoins(map)
	if mapSpawnerActive then return end
	mapSpawnerActive = true

	loadMapSpawns(map)

	print("?? Starting map coin spawner...")

	-- Spawn regular coins
	for _, position in pairs(mapCoinSpawns) do
		spawnCoin(position, map, activeMapCoins, COIN_VALUE)
	end
	print("?? Spawned", #activeMapCoins, "map coins")

	-- Spawn top coins (worth more!)
	for _, position in pairs(topCoinSpawns) do
		spawnCoin(position, map, activeTopCoins, TOP_COIN_VALUE)
	end
	if #activeTopCoins > 0 then
		print("? Spawned", #activeTopCoins, "top coins (worth", TOP_COIN_VALUE, "each)")
	end

	-- Respawn loop for map coins
	task.spawn(function()
		while mapSpawnerActive do
			task.wait(MAP_COIN_RESPAWN_TIME)
			if not mapSpawnerActive then break end

			-- Respawn regular coins
			for _, spawnPos in pairs(mapCoinSpawns) do
				local hasCoin = false
				for _, coin in pairs(activeMapCoins) do
					if coin and coin.Parent then
						local coinPos
						if coin:IsA("Model") then
							coinPos = coin:GetPivot().Position
						else
							coinPos = coin.Position
						end
						if (coinPos - spawnPos).Magnitude < 5 then
							hasCoin = true
							break
						end
					end
				end

				if not hasCoin then
					spawnCoin(spawnPos, map, activeMapCoins, COIN_VALUE)
				end
			end

			-- Respawn top coins
			for _, spawnPos in pairs(topCoinSpawns) do
				local hasCoin = false
				for _, coin in pairs(activeTopCoins) do
					if coin and coin.Parent then
						local coinPos
						if coin:IsA("Model") then
							coinPos = coin:GetPivot().Position
						else
							coinPos = coin.Position
						end
						if (coinPos - spawnPos).Magnitude < 5 then
							hasCoin = true
							break
						end
					end
				end

				if not hasCoin then
					spawnCoin(spawnPos, map, activeTopCoins, TOP_COIN_VALUE)
				end
			end
		end
	end)
end

-- ============================================
-- STOP MAP COINS
-- ============================================

function CoinManager.StopMapCoins()
	if not mapSpawnerActive then return end
	mapSpawnerActive = false

	for _, coin in pairs(activeMapCoins) do
		if coin and coin.Parent then
			coin:Destroy()
		end
	end
	activeMapCoins = {}

	for _, coin in pairs(activeTopCoins) do
		if coin and coin.Parent then
			coin:Destroy()
		end
	end
	activeTopCoins = {}

	mapCoinSpawns = {}
	topCoinSpawns = {}

	print("?? Stopped map coin spawner")
end

print("? CoinManager module loaded")

return CoinManager