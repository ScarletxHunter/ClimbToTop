-- ============================================
-- COIN SPAWNER - Uses your custom CoinTemplate model
-- Place spawn points in: Map.Props.CoinsMan (BaseParts)
-- Place coin template in: Map.Props.CoinTemplate (Model or BasePart)
-- ============================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local CoinSpawner = {}

local DEFAULTS = {
	MaxActiveCoins = 8,
	SpawnCheckInterval = 1,
	RespawnDelay = 15,
	CoinValue = 5,
	FloatOffsetY = 0,
}

local running = false
local coinFolder = Workspace:FindFirstChild("ActiveCoinsContainer")
if not coinFolder then
	coinFolder = Instance.new("Folder")
	coinFolder.Name = "ActiveCoinsContainer"
	coinFolder.Parent = Workspace
end

local pointState = {} -- [BasePart] = {coin = BasePart|nil, nextSpawnAt = number}

local function dbg(hId, loc, msg, data)
	-- #region agent log
	pcall(function()
		HttpService:PostAsync(
			"http://127.0.0.1:7243/ingest/f4b63b01-cff3-4a42-b344-cb9c3aec0ae1",
			HttpService:JSONEncode({
				runId = "coin_spawner_debug",
				hypothesisId = hId,
				location = loc,
				message = msg,
				data = data or {},
				timestamp = DateTime.now().UnixTimestampMillis,
			}),
			Enum.HttpContentType.ApplicationJson
		)
	end)
	-- #endregion
end

local function clearActiveCoins()
	for _, c in ipairs(coinFolder:GetChildren()) do
		c:Destroy()
	end
	for point, state in pairs(pointState) do
		state.coin = nil
		state.nextSpawnAt = 0
		if not point or not point.Parent then
			pointState[point] = nil
		end
	end
end

local function readConfig()
	local cfg = {
		MaxActiveCoins = DEFAULTS.MaxActiveCoins,
		SpawnCheckInterval = DEFAULTS.SpawnCheckInterval,
		RespawnDelay = DEFAULTS.RespawnDelay,
		CoinValue = DEFAULTS.CoinValue,
		FloatOffsetY = DEFAULTS.FloatOffsetY,
	}
	local coinsMan = Workspace:FindFirstChild("CoinsMan")
	if not coinsMan then
		return cfg
	end
	local maxActive = coinsMan:GetAttribute("MaxActiveCoins")
	if typeof(maxActive) == "number" then cfg.MaxActiveCoins = math.max(1, math.floor(maxActive)) end
	local interval = coinsMan:GetAttribute("SpawnInterval")
	if typeof(interval) == "number" then cfg.SpawnCheckInterval = math.max(0.2, interval) end
	local cooldown = coinsMan:GetAttribute("CooldownSeconds")
	if typeof(cooldown) == "number" then cfg.RespawnDelay = math.max(1, cooldown) end
	local coinValue = coinsMan:GetAttribute("CoinValue")
	if typeof(coinValue) == "number" then cfg.CoinValue = math.max(1, math.floor(coinValue)) end
	local floatY = coinsMan:GetAttribute("FloatOffsetY")
	if typeof(floatY) == "number" then cfg.FloatOffsetY = floatY end
	return cfg
end

local function getSpawnPoints()
	local points = {}
	local coinsMan = Workspace:FindFirstChild("CoinsMan")
	if not coinsMan then
		dbg("H_COIN_POINTS", "CoinSpawner:getSpawnPoints", "CoinsMan missing in Workspace", {})
		return points
	end
	for _, d in ipairs(coinsMan:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(points, d)
		end
	end
	dbg("H_COIN_POINTS", "CoinSpawner:getSpawnPoints", "Spawn points collected", {count = #points})
	return points
end

local function getTemplate()
	local tpl = Workspace:FindFirstChild("CoinTemplate", true)
	if not tpl then
		dbg("H_TEMPLATE", "CoinSpawner:getTemplate", "CoinTemplate missing", {})
		return nil
	end
	if not tpl:IsA("Model") and not tpl:IsA("BasePart") then
		dbg("H_TEMPLATE", "CoinSpawner:getTemplate", "CoinTemplate invalid type", {class = tpl.ClassName})
		return nil
	end
	dbg("H_TEMPLATE", "CoinSpawner:getTemplate", "CoinTemplate found", {
		name = tpl.Name,
		class = tpl.ClassName,
		path = tpl:GetFullName(),
	})
	return tpl
end

local function awardCoins(player, amount)
	if _G.UpdatePlayerCoins then
		_G.UpdatePlayerCoins(player, amount)
		return
	end
	local ok, pdm = pcall(function()
		local mod = ServerScriptService:FindFirstChild("PlayerDataManager")
			or (ServerScriptService:FindFirstChild("GameScripts") and ServerScriptService.GameScripts:FindFirstChild("PlayerDataManager"))
		return mod and require(mod) or nil
	end)
	if ok and pdm and pdm.AddCoins then
		pdm.AddCoins(player, amount)
	end
end

local function bindTouchForCoin(coinContainer, touchParts, point, coinValue, respawnDelay)
	local taken = false
	local connections = {}
	local function onTouched(hit)
		if taken then return end
		local character = hit and hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		taken = true
		for _, c in ipairs(connections) do
			c:Disconnect()
		end
		awardCoins(player, coinValue)
		dbg("H_COIN_PICKUP", "CoinSpawner:bindTouchForCoin", "Coin collected", {
			player = player.Name,
			value = coinValue,
			point = point.Name,
		})
		coinContainer:Destroy()
		local state = pointState[point]
		if state then
			state.coin = nil
			state.nextSpawnAt = tick() + respawnDelay
		end
	end
	for _, part in ipairs(touchParts) do
		table.insert(connections, part.Touched:Connect(onTouched))
	end
end

local function makeCoin(point, template, coinValue, respawnDelay, floatY)
	local spawnPos = point.Position + Vector3.new(0, floatY, 0)
	local coin = template:Clone()
	coin.Name = "ActiveCoin"

	local touchParts = {}
	if coin:IsA("BasePart") then
		coin.Transparency = 0
		coin.Anchored = true
		coin.CanCollide = false
		coin.CanTouch = true
		coin.CanQuery = false
		coin.CFrame = CFrame.new(spawnPos)
		table.insert(touchParts, coin)
	elseif coin:IsA("Model") then
		local p = coin.PrimaryPart or coin:FindFirstChildWhichIsA("BasePart")
		if not p then
			dbg("H_TEMPLATE", "CoinSpawner:makeCoin", "Template model has no BasePart", {point = point.Name})
			coin:Destroy()
			return nil
		end
		if not coin.PrimaryPart then
			coin.PrimaryPart = p
		end
		coin:PivotTo(CFrame.new(spawnPos))
		for _, d in ipairs(coin:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Transparency = 0
				d.Anchored = true
				d.CanCollide = false
				d.CanTouch = true
				d.CanQuery = false
				table.insert(touchParts, d)
			end
		end
	end
	coin.Parent = coinFolder
	bindTouchForCoin(coin, touchParts, point, coinValue, respawnDelay)
	return coin
end

function CoinSpawner.StartSpawning(mapName)
	running = true
	clearActiveCoins()
	local cfg = readConfig()

	local points = getSpawnPoints()
	for _, p in ipairs(points) do
		pointState[p] = {coin = nil, nextSpawnAt = 0}
	end
	local template = getTemplate()

	-- Hide the original template so only spawned clones are visible
	if template then
		if template:IsA("BasePart") then
			template.Transparency = 1
			template.CanTouch = false
			template.CanCollide = false
		elseif template:IsA("Model") then
			for _, d in ipairs(template:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Transparency = 1
					d.CanTouch = false
					d.CanCollide = false
				end
			end
		end
		dbg("H_TEMPLATE_HIDE", "CoinSpawner:StartSpawning", "Template hidden", {
			name = template.Name,
			path = template:GetFullName(),
		})
	end

	dbg("H_COIN_START", "CoinSpawner:StartSpawning", "Coin spawner started", {
		mapName = mapName,
		spawnPointCount = #points,
		templateFound = template ~= nil,
		cooldown = cfg.RespawnDelay,
		spawnInterval = cfg.SpawnCheckInterval,
		maxActive = cfg.MaxActiveCoins,
		coinValue = cfg.CoinValue,
	})
	print("[CoinSpawner] Start map=", mapName, "points=", #points, "template=", template ~= nil, "cooldown=", cfg.RespawnDelay)

	if #points == 0 then
		warn("CoinSpawner: No CoinsMan spawn points found in Workspace")
		return
	end
	if not template then
		warn("CoinSpawner: CoinTemplate not found in loaded map (create Props/CoinTemplate)")
		return
	end

	task.spawn(function()
		while running do
			local activeCount = #coinFolder:GetChildren()
			if activeCount < cfg.MaxActiveCoins then
				local eligible = {}
				local now = tick()
				for _, point in ipairs(points) do
					local state = pointState[point]
					if state and (not state.coin or not state.coin.Parent) then
						state.coin = nil
						if now >= (state.nextSpawnAt or 0) then
							table.insert(eligible, point)
						end
					end
				end
				if #eligible > 0 then
					local pick = eligible[math.random(1, #eligible)]
					local state = pointState[pick]
					if state then
						state.coin = makeCoin(pick, template, cfg.CoinValue, cfg.RespawnDelay, cfg.FloatOffsetY)
						print("[CoinSpawner] Spawned coin at", pick.Name, "eligible=", #eligible)
						dbg("H_RANDOM", "CoinSpawner:loop", "Spawned at random eligible point", {
							pickedPoint = pick.Name,
							eligibleCount = #eligible,
							activeBefore = activeCount,
						})
					end
				else
					dbg("H_COOLDOWN", "CoinSpawner:loop", "No eligible points (cooldown active)", {
						activeCount = activeCount,
						pointCount = #points,
					})
				end
			end
			task.wait(cfg.SpawnCheckInterval)
		end
	end)
end

function CoinSpawner.StopSpawning()
	if not running and #coinFolder:GetChildren() == 0 then return end
	running = false
	clearActiveCoins()
	dbg("H_COIN_STOP", "CoinSpawner:StopSpawning", "Coin spawner stopped", {})
end

return CoinSpawner

