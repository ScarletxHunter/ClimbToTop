-- ============================================
-- COLLISION HANDLER (Ragdolls players hit by falling objects)
-- Place in: ServerScriptService/CollisionHandler (Script)
-- 
-- Fixed: Now watches "FallingObjectsContainer" (where ObjectSpawner puts objects)
-- Fixed: Detects NEW objects spawned during the round (DescendantAdded)
-- Fixed: Works with both BaseParts and Models
-- Fixed: Ragdoll lasts 2-4 seconds with knockback
-- ============================================

local Players = game:GetService("Players")

print("?? Collision Handler loading...")

local RAGDOLL_TIME = 3 -- seconds to stay ragdolled
local KNOCKBACK_FORCE = 40 -- how hard the player gets pushed

-- ============================================
-- RAGDOLL FUNCTIONS
-- ============================================

local function unRagdoll(character)
	if not character then return end
	if not character.Parent then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

		-- Small delay then force jump to unstick
		task.delay(0.1, function()
			if humanoid and humanoid.Parent then
				humanoid.Jump = true
			end
		end)
	end
end

local function ragdollPlayer(player, hitPart)
	local character = player and player.Character
	if not character then return end
	if not character.Parent then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	-- Don't ragdoll dead players
	if humanoid.Health <= 0 then return end

	-- Set ragdoll state
	humanoid.PlatformStand = true

	-- Apply knockback away from the hit object
	if hitPart and hitPart:IsA("BasePart") then
		local direction = (hrp.Position - hitPart.Position).Unit
		-- Add some upward force so they fly a bit
		direction = Vector3.new(direction.X, 0.5, direction.Z).Unit
		hrp.AssemblyLinearVelocity = direction * KNOCKBACK_FORCE + Vector3.new(0, 20, 0)

		-- Add some spin for visual effect
		hrp.AssemblyAngularVelocity = Vector3.new(
			math.random(-5, 5),
			math.random(-3, 3),
			math.random(-5, 5)
		)
	end

	-- Unragdoll after delay
	task.delay(RAGDOLL_TIME, function()
		unRagdoll(character)
	end)
end

-- ============================================
-- DEBOUNCE (one ragdoll at a time per player)
-- ============================================

local ragdolling = {}

local function onObjectHitPlayer(hitPart, objectPart)
	-- hitPart = the player's body part that got touched
	-- objectPart = the falling object that hit them
	if not hitPart or not hitPart.Parent then return end

	local character = hitPart.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Skip if already ragdolling
	if ragdolling[player.UserId] then return end

	-- Start ragdoll
	ragdolling[player.UserId] = true
	ragdollPlayer(player, objectPart)

	-- Clear debounce after ragdoll ends + buffer
	task.delay(RAGDOLL_TIME + 1, function()
		ragdolling[player.UserId] = nil
	end)
end

-- ============================================
-- CONNECT TOUCH DETECTION TO AN OBJECT
-- ============================================

local function connectTouchToObject(object)
	if object:IsA("BasePart") then
		object.Touched:Connect(function(hitPart)
			onObjectHitPlayer(hitPart, object)
		end)
	elseif object:IsA("Model") then
		-- Connect to all parts inside the model
		for _, part in pairs(object:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Touched:Connect(function(hitPart)
					onObjectHitPlayer(hitPart, part)
				end)
			end
		end
		-- Also connect to parts added later inside the model
		object.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				desc.Touched:Connect(function(hitPart)
					onObjectHitPlayer(hitPart, desc)
				end)
			end
		end)
	end
end

-- ============================================
-- WATCH THE FALLING OBJECTS CONTAINER
-- This is where ObjectSpawner puts spawned objects
-- ============================================

local function setupFallingObjectsWatcher()
	-- Find or wait for the container
	local container = workspace:FindFirstChild("FallingObjectsContainer")

	if not container then
		-- Wait for it to be created
		local conn
		conn = workspace.ChildAdded:Connect(function(child)
			if child.Name == "FallingObjectsContainer" then
				container = child
				print("? Found FallingObjectsContainer")

				-- Connect existing objects
				for _, obj in pairs(container:GetChildren()) do
					connectTouchToObject(obj)
				end

				-- Watch for new objects spawned during the round
				container.ChildAdded:Connect(function(newObj)
					connectTouchToObject(newObj)
				end)

				conn:Disconnect()
			end
		end)
	else
		print("? Found FallingObjectsContainer")

		-- Connect existing objects
		for _, obj in pairs(container:GetChildren()) do
			connectTouchToObject(obj)
		end

		-- Watch for new objects spawned during the round
		container.ChildAdded:Connect(function(newObj)
			connectTouchToObject(newObj)
		end)
	end
end

-- ============================================
-- ALSO WATCH "SpawnerObjects" FOLDER (legacy support)
-- ============================================

local function setupLegacySpawnerObjects()
	local spawnerFolder = workspace:FindFirstChild("SpawnerObjects")
	if spawnerFolder then
		print("? Found SpawnerObjects folder (legacy)")
		for _, obj in pairs(spawnerFolder:GetChildren()) do
			connectTouchToObject(obj)
		end
		spawnerFolder.ChildAdded:Connect(function(newObj)
			connectTouchToObject(newObj)
		end)
	end
end

-- ============================================
-- CLEANUP ON PLAYER LEAVE
-- ============================================

Players.PlayerRemoving:Connect(function(player)
	ragdolling[player.UserId] = nil
end)

-- ============================================
-- START
-- ============================================

setupFallingObjectsWatcher()
setupLegacySpawnerObjects()

print("? Collision Handler active (ragdoll with restore, no perma-stuck)")
print("   Ragdoll time: " .. RAGDOLL_TIME .. "s")
print("   Knockback force: " .. KNOCKBACK_FORCE)
print("   Watching: FallingObjectsContainer + SpawnerObjects")