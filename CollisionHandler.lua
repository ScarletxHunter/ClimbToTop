local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundManager = require(script.Parent:WaitForChild("SoundManager"))

if _G.__CollisionHandlerLoaded then
	warn("CollisionHandler already loaded, skipping duplicate instance")
	return
end
_G.__CollisionHandlerLoaded = true

local RAGDOLL_TIME = 2
local COOLDOWN_TIME = 3
local cooldowns = {}

local function isRoundActive()
	local gv = ReplicatedStorage:FindFirstChild("GameValues")
	if gv then
		local gs = gv:FindFirstChild("GameState")
		if gs then return gs.Value == "Playing" end
	end
	return false
end

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local ragdollEvent = remoteEvents:FindFirstChild("PlayerRagdolled")
if not ragdollEvent then
	ragdollEvent = Instance.new("RemoteEvent")
	ragdollEvent.Name = "PlayerRagdolled"
	ragdollEvent.Parent = remoteEvents
end

local function getTetheredPlayer(player)
	if not player or not player.Character then return nil end
	local attrs = {
		player.Character:GetAttribute("TetherTargetUserId"),
		player.Character:GetAttribute("TetheredUserId"),
		player.Character:GetAttribute("TetherPartnerUserId"),
		player:GetAttribute("TetherTargetUserId"),
		player:GetAttribute("TetheredUserId"),
		player:GetAttribute("TetherPartnerUserId"),
	}
	for _, id in ipairs(attrs) do
		if type(id) == "number" then
			local linked = Players:GetPlayerByUserId(id)
			if linked and linked ~= player then
				return linked
			end
		end
	end
	return nil
end

local function ragdollPlayer(player, fromTether)
	if cooldowns[player.Name] then return end
	if not player.Character then return end
	if not isRoundActive() then return end

	local humanoid = player.Character:FindFirstChild("Humanoid")
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end
	if humanoid.Health <= 0 then return end
	if player.Character:GetAttribute("Shielded") then return end
	if player.Character:FindFirstChildOfClass("ForceField") then return end

	local trailShield = player.Character:GetAttribute("TrailShield") or 0
	cooldowns[player.Name] = true

	-- Tiny bump - just fall over
	local kf = 1 - trailShield
	hrp.AssemblyLinearVelocity = Vector3.new(0, 2 * kf, 0)
	humanoid.PlatformStand = true
	hrp.AssemblyAngularVelocity = Vector3.new(math.random(-1,1), 0, math.random(-1,1))

	pcall(function() SoundManager.PlaySFXForPlayer(player, "PlayerHit") end)
	pcall(function() ragdollEvent:FireClient(player, "self", hrp.Position) end)

	for _, op in pairs(Players:GetPlayers()) do
		if op ~= player and op.Character then
			local ohrp = op.Character:FindFirstChild("HumanoidRootPart")
			if ohrp and (ohrp.Position - hrp.Position).Magnitude <= 60 then
				pcall(function() ragdollEvent:FireClient(op, "other", hrp.Position) end)
			end
		end
	end

	print("??", player.Name, "ragdolled")

	if not fromTether then
		local tethered = getTetheredPlayer(player)
		if tethered and not cooldowns[tethered.Name] then
			ragdollPlayer(tethered, true)
		end
	end

	task.delay(RAGDOLL_TIME, function()
		if not humanoid or not humanoid.Parent then return end
		if not hrp or not hrp.Parent then return end

		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.Anchored = true

		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {player.Character}
		local ground = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rp)

		if ground then
			hrp.CFrame = CFrame.new(ground.Position + Vector3.new(0, 3, 0))
		end

		task.wait(0.1)
		if hrp and hrp.Parent then
			hrp.Anchored = false
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		if humanoid and humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid.Sit = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.Jump = true
		end

		print("?", player.Name, "snapped back up")
	end)

	task.delay(COOLDOWN_TIME, function()
		cooldowns[player.Name] = nil
	end)
end

local objectsContainer = workspace:WaitForChild("FallingObjectsContainer")

objectsContainer.ChildAdded:Connect(function(object)
	task.wait(0.1)

	local function connectHitbox(hitbox)
		hitbox.Touched:Connect(function(hit)
			local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
			if hitPlayer and hitPlayer.Character and hitPlayer.Character:FindFirstChild("Humanoid") and not hitPlayer.Character:GetAttribute("Phasing") then
				ragdollPlayer(hitPlayer)
			end
		end)
	end

	if object:IsA("BasePart") then connectHitbox(object) end
	local hitbox = object:FindFirstChild("Hitbox")
	if hitbox then connectHitbox(hitbox) end
	if object:IsA("Model") and object.PrimaryPart then connectHitbox(object.PrimaryPart) end
	if object:IsA("Model") then
		for _, part in pairs(object:GetDescendants()) do
			if part:IsA("BasePart") then connectHitbox(part) end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.Name] = nil
end)

print("? CollisionHandler FRESH - snap recovery")
print("   Ragdoll:", RAGDOLL_TIME .. "s then SNAP to ground")
print("   Cooldown:", COOLDOWN_TIME .. "s")
