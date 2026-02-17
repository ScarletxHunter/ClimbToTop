-- ============================================
-- OBJECT SPAWNER - Per-spawner config via Attributes
-- ============================================
-- Set these Attributes on each Spawner part in Studio:
--
--   SpawnInterval      (number)  Time in seconds between each batch. Default: 0.5
--   SpawnCount         (number)  How many objects per batch. Default: 4
--   SpawnIntervalRandom(number)  Extra random seconds added to interval. Default: 0
--   ObjectLifetime     (number)  Seconds before object auto-despawns. Default: 25
--   SpawnDelay         (number)  Seconds between each object IN a batch. Default: 0.05
--                                (set to 0 for instant burst)
--
-- RECOMMENDED SETTINGS for fast action:
--   SpawnInterval = 0.5   (new batch every 0.5s)
--   SpawnCount = 8        (8 objects per batch)
--   SpawnDelay = 0        (all 8 spawn instantly)
--   SpawnIntervalRandom = 0.2  (slight randomness)
--   ObjectLifetime = 20   (despawn after 20s)
--
-- MaxObjectsAtOnce is global (set in DEFAULTS below).
-- ============================================

local ServerStorage = game:GetService("ServerStorage")
local workspaceService = game:GetService("Workspace")

local ObjectSpawner = {}


-- Global defaults (used if a spawner has no attribute set)
local DEFAULTS = {
	SpawnInterval = 0.5,
	SpawnIntervalRandom = 0,
	ObjectLifetime = 25,
	MaxObjectsAtOnce = 120,
	SpawnCount = 4,
	SpawnDelay = 0.05,
	Bounciness = 0.5,
	Friction = 0.5,
}

local spawning = false
local currentObjects = {}
local spawners = {}
local objectsContainer = workspaceService:WaitForChild("FallingObjectsContainer")

-- Read per-spawner config from Attributes, fall back to defaults
local function getSpawnerConfig(spawnerPart)
	return {
		SpawnInterval = spawnerPart:GetAttribute("SpawnInterval") or DEFAULTS.SpawnInterval,
		SpawnIntervalRandom = spawnerPart:GetAttribute("SpawnIntervalRandom") or DEFAULTS.SpawnIntervalRandom,
		SpawnCount = spawnerPart:GetAttribute("SpawnCount") or DEFAULTS.SpawnCount,
		SpawnDelay = spawnerPart:GetAttribute("SpawnDelay") or DEFAULTS.SpawnDelay,
		ObjectLifetime = spawnerPart:GetAttribute("ObjectLifetime") or DEFAULTS.ObjectLifetime,
	}
end

local function findSpawners()
	spawners = {}

	local singleSpawner = workspaceService:FindFirstChild("Spawner")
	if singleSpawner and singleSpawner:IsA("BasePart") then
		table.insert(spawners, {
			Part = singleSpawner,
			Config = getSpawnerConfig(singleSpawner),
		})
	end

	local spawnersFolder = workspaceService:FindFirstChild("Spawners")
	if spawnersFolder then
		for _, spawner in pairs(spawnersFolder:GetChildren()) do
			if spawner:IsA("BasePart") then
				table.insert(spawners, {
					Part = spawner,
					Config = getSpawnerConfig(spawner),
				})
			end
		end
	end

	if #spawners == 0 then
		warn("No spawners found!")
	else
		for _, s in ipairs(spawners) do
			print("Spawner:", s.Part.Name,
				"| Interval:", s.Config.SpawnInterval,
				"| Count:", s.Config.SpawnCount,
				"| Delay:", s.Config.SpawnDelay,
				"| Lifetime:", s.Config.ObjectLifetime)
		end
	end
end

local function cleanupObjects()
	for i = #currentObjects, 1, -1 do
		local obj = currentObjects[i]
		if not obj or not obj.Parent then
			table.remove(currentObjects, i)
		end
	end
end

local function makeObjectBouncy(part)
	part.CustomPhysicalProperties = PhysicalProperties.new(
		0.7, DEFAULTS.Friction, DEFAULTS.Bounciness, 1, 1
	)
end

local function spawnObject(objectModel, spawnerPart, lifetime)
	cleanupObjects()
	if #currentObjects >= DEFAULTS.MaxObjectsAtOnce then return end

	local clone = objectModel:Clone()
	local destroyed = false

	local randomOffset = Vector3.new(
		math.random(-8, 8),
		math.random(0, 2),
		math.random(-8, 8)
	)

	-- Connect PropStop detection on a part
	local function setupTouched(hitbox)
		hitbox.Touched:Connect(function(hit)
			if hit.Name == "PropStop" and not destroyed then
				destroyed = true
				clone:Destroy()
			end
		end)
	end

	if clone:IsA("Model") then
		if not clone.PrimaryPart then
			local fallback = clone:FindFirstChildWhichIsA("BasePart")
			if not fallback then
				warn("Model has no BasePart at all:", clone.Name)
				clone:Destroy()
				return
			end
			clone.PrimaryPart = fallback
		end
		clone:PivotTo(spawnerPart.CFrame * CFrame.new(randomOffset))
		clone.Parent = objectsContainer

		-- Collect all BaseParts, unanchor, set physics, PropStop
		local parts = {}
		local existingWelds = 0
		for _, desc in pairs(clone:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = false
				desc.CanCollide = true
				makeObjectBouncy(desc)
				setupTouched(desc)
				table.insert(parts, desc)
			elseif desc:IsA("JointInstance") then
				existingWelds = existingWelds + 1
			end
		end

		-- If the model has no welds, create WeldConstraints to bond every
		-- child part to the PrimaryPart so they fall as a single unit
		local createdWelds = 0
		if existingWelds == 0 and #parts > 1 then
			local root = clone.PrimaryPart
			for _, part in ipairs(parts) do
				if part ~= root then
					local wc = Instance.new("WeldConstraint")
					wc.Part0 = root
					wc.Part1 = part
					wc.Parent = root
					createdWelds = createdWelds + 1
				end
			end
		end

		clone.PrimaryPart.Velocity = Vector3.new(math.random(-5, 5), -40, math.random(-5, 5))
		clone.PrimaryPart.RotVelocity = Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))

	elseif clone:IsA("BasePart") then
		clone.CFrame = spawnerPart.CFrame * CFrame.new(randomOffset)
		clone.Parent = objectsContainer
		makeObjectBouncy(clone)
		clone.Velocity = Vector3.new(math.random(-5, 5), -40, math.random(-5, 5))
		clone.RotVelocity = Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))
		setupTouched(clone)
	else
		clone:Destroy()
		return
	end

	table.insert(currentObjects, clone)

	task.delay(lifetime, function()
		if clone and clone.Parent then clone:Destroy() end
	end)
end

-- Each spawner runs its own loop with its own timing
local function spawnLoopForSpawner(spawnerData, objects)
	local part = spawnerData.Part
	local config = spawnerData.Config
	local spawnDelay = config.SpawnDelay
	local objectLifetime = config.ObjectLifetime

	while spawning do
		for i = 1, config.SpawnCount do
			local randomObject = objects[math.random(1, #objects)]
			spawnObject(randomObject, part, objectLifetime)
			if spawnDelay > 0 then task.wait(spawnDelay) end
		end
		local waitTime = config.SpawnInterval + math.random() * config.SpawnIntervalRandom
		task.wait(waitTime)
	end
end

function ObjectSpawner.StartSpawning(mapName)
	print("Starting spawner for:", mapName)
	findSpawners()
	spawning = true

	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then return end

	local mapFolder = mapsFolder:FindFirstChild(mapName)
	if not mapFolder then return end

	local fallingObjects = mapFolder:FindFirstChild("FallingObjects")
	if not fallingObjects or #fallingObjects:GetChildren() == 0 then
		warn("No falling objects for map:", mapName)
		return
	end

	local objects = fallingObjects:GetChildren()

	print("Spawn loops ready with", #objects, "object types across", #spawners, "spawner(s)")
	print("  Max objects:", DEFAULTS.MaxObjectsAtOnce)

	for _, spawnerData in ipairs(spawners) do
		task.spawn(function()
			spawnLoopForSpawner(spawnerData, objects)
		end)
	end
end

function ObjectSpawner.StopSpawning()
	print("Stopping spawner")
	spawning = false
	objectsContainer:ClearAllChildren()
	currentObjects = {}
end

return ObjectSpawner
