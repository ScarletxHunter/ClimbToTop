-- ============================================
-- OBJECT SPAWNER - Spawns falling objects
-- Per-spawner configuration support
-- ============================================

local ServerStorage = game:GetService("ServerStorage")
local workspace = game:GetService("Workspace")
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local ObjectSpawner = {}

local spawning = false
local currentObjects = {}
local spawners = {}
local objectsContainer = workspace:WaitForChild("FallingObjectsContainer")

-- Get spawner-specific config (or use defaults)
local function getSpawnerConfig(spawner)
	local config = {
		SpawnInterval = spawner:GetAttribute("SpawnInterval") or GameConfig.ObjectSpawner.SpawnInterval,
		SpawnIntervalRandom = spawner:GetAttribute("SpawnIntervalRandom") or GameConfig.ObjectSpawner.SpawnIntervalRandom,
		ObjectLifetime = spawner:GetAttribute("ObjectLifetime") or GameConfig.ObjectSpawner.ObjectLifetime,
		MaxObjects = spawner:GetAttribute("MaxObjects") or GameConfig.ObjectSpawner.MaxObjectsAtOnce,
		SpawnCount = spawner:GetAttribute("SpawnCount") or GameConfig.ObjectSpawner.SpawnCount,
		Bounciness = spawner:GetAttribute("Bounciness") or GameConfig.ObjectSpawner.Bounciness,
		Friction = spawner:GetAttribute("Friction") or GameConfig.ObjectSpawner.Friction,
	}
	return config
end

-- Find spawners
local function findSpawners()
	spawners = {}

	local singleSpawner = workspace:FindFirstChild("Spawner")
	if singleSpawner then
		table.insert(spawners, {
			Part = singleSpawner,
			Config = getSpawnerConfig(singleSpawner),
			Objects = {}
		})
	end

	local spawnersFolder = workspace:FindFirstChild("Spawners")
	if spawnersFolder then
		for _, spawner in pairs(spawnersFolder:GetChildren()) do
			if spawner:IsA("BasePart") then
				table.insert(spawners, {
					Part = spawner,
					Config = getSpawnerConfig(spawner),
					Objects = {}
				})
			end
		end
	end

	if #spawners == 0 then
		warn("?? No spawners found!")
	else
		print("? Found", #spawners, "spawner(s)")
		for i, spawnerData in ipairs(spawners) do
			print("   Spawner", i .. ":", spawnerData.Part.Name)
			print("      SpawnInterval:", spawnerData.Config.SpawnInterval)
			print("      SpawnCount:", spawnerData.Config.SpawnCount)
			print("      MaxObjects:", spawnerData.Config.MaxObjects)
		end
	end
end

-- Clean up objects for a specific spawner
local function cleanupObjects(spawnerData)
	for i = #spawnerData.Objects, 1, -1 do
		local obj = spawnerData.Objects[i]
		if not obj or not obj.Parent then
			table.remove(spawnerData.Objects, i)
		end
	end
end

-- Make object bouncy
local function makeObjectBouncy(part, config)
	local physicalProperties = PhysicalProperties.new(
		0.7,
		config.Friction,
		config.Bounciness,
		1,
		1
	)
	part.CustomPhysicalProperties = physicalProperties
end

-- Spawn object
local function spawnObject(spawnerData, objectModel)
	cleanupObjects(spawnerData)

	if #spawnerData.Objects >= spawnerData.Config.MaxObjects then
		return
	end

	local spawner = spawnerData.Part
	local clone = objectModel:Clone()

	-- Spread objects across spawner area
	local randomOffset = Vector3.new(math.random(-8, 8), math.random(0, 2), math.random(-8, 8))

	if clone:IsA("Model") then
		if not clone.PrimaryPart then
			warn("?? Model has no PrimaryPart:", clone.Name)
			clone:Destroy()
			return
		end

		clone:SetPrimaryPartCFrame(spawner.CFrame * CFrame.new(randomOffset))
		clone.Parent = objectsContainer

		makeObjectBouncy(clone.PrimaryPart, spawnerData.Config)

		-- Apply velocity
		clone.PrimaryPart.Velocity = Vector3.new(math.random(-5, 5), -40, math.random(-5, 5))
		clone.PrimaryPart.RotVelocity = Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))

		-- PropStop collision detection for Models
		clone.PrimaryPart.Touched:Connect(function(hit)
			if hit.Name == "PropStop" then
				clone:Destroy()
			end
		end)

	elseif clone:IsA("BasePart") then
		clone.CFrame = spawner.CFrame * CFrame.new(randomOffset)
		clone.Parent = objectsContainer

		makeObjectBouncy(clone, spawnerData.Config)

		-- Apply velocity
		clone.Velocity = Vector3.new(math.random(-5, 5), -40, math.random(-5, 5))
		clone.RotVelocity = Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))

		-- PropStop collision detection for Parts
		clone.Touched:Connect(function(hit)
			if hit.Name == "PropStop" then
				clone:Destroy()
			end
		end)
	else
		clone:Destroy()
		return
	end

	table.insert(spawnerData.Objects, clone)

	-- Auto cleanup after lifetime
	task.delay(spawnerData.Config.ObjectLifetime, function()
		if clone and clone.Parent then
			clone:Destroy()
		end
	end)
end

-- Spawn loop for a single spawner
local function spawnLoop(spawnerData, objects)
	while spawning do
		for i = 1, spawnerData.Config.SpawnCount do
			local randomObject = objects[math.random(1, #objects)]
			spawnObject(spawnerData, randomObject)
			task.wait(0.2)
		end

		local waitTime = spawnerData.Config.SpawnInterval + (math.random() * spawnerData.Config.SpawnIntervalRandom)
		task.wait(waitTime)
	end
end

function ObjectSpawner.StartSpawning(mapName)
	print("?? Starting spawner for:", mapName)
	findSpawners()

	if #spawners == 0 then
		warn("?? No spawners found, skipping object spawning")
		return
	end

	spawning = true

	-- Get falling objects for this map
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then return end

	local mapFolder = mapsFolder:FindFirstChild(mapName)
	if not mapFolder then return end

	local fallingObjects = mapFolder:FindFirstChild("FallingObjects")
	if not fallingObjects or #fallingObjects:GetChildren() == 0 then
		warn("?? No falling objects for map:", mapName)
		return
	end

	local objects = fallingObjects:GetChildren()
	print("?? Spawn loop ready with", #objects, "object types")

	-- Start independent spawn loop for each spawner
	for _, spawnerData in ipairs(spawners) do
		task.spawn(function()
			spawnLoop(spawnerData, objects)
		end)
	end
end

function ObjectSpawner.StopSpawning()
	print("?? Stopping spawner")
	spawning = false
	objectsContainer:ClearAllChildren()
	for _, spawnerData in ipairs(spawners) do
		spawnerData.Objects = {}
	end
	currentObjects = {}
end

return ObjectSpawner