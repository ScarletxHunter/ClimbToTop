local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
print("?? Skill Handler v2 loading...")

local function dbg(hId, loc, msg, data)
	-- Debug logging (print only, no HTTP)
end

local reFolder = RS:WaitForChild("RemoteEvents")
local function goc(n)
	local r = reFolder:FindFirstChild(n)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = n
		r.Parent = reFolder
	end
	return r
end

local ActivateSkill = goc("ActivateSkill")
local SkillUpdate = goc("SkillUpdate")
local NotifyClient = goc("NotifyClient")
local BWEffect = goc("BWEffect")
local SkillCooldownStart = goc("SkillCooldownStart")
local RainbowStarEffect = goc("RainbowStarEffect")
local LightningShockEffect = goc("LightningShockEffect")
local SkillActiveStart = goc("SkillActiveStart")
local SkillReset = goc("SkillReset")

-- ClientDebugLog (HTTP removed)
local ClientDebugLog = goc("ClientDebugLog")
ClientDebugLog.OnServerEvent:Connect(function(plr, payload)
	-- no-op: HTTP debug logging disabled
end)

local GameValues = RS:WaitForChild("GameValues", 15) or RS:FindFirstChild("GameValues")
local GameState = GameValues and (GameValues:WaitForChild("GameState", 10) or GameValues:FindFirstChild("GameState")) or nil

local function isRoundActive()
	-- Re-fetch if nil (might have been created late)
	if not GameState then
		local gv = RS:FindFirstChild("GameValues")
		if gv then GameState = gv:FindFirstChild("GameState") end
	end
	if GameState and GameState:IsA("StringValue") then
		return GameState.Value == "Playing"
	end
	-- If GameState still doesn't exist, allow skills (don't block in Studio testing)
	return true
end

local playerSkills = {}
local posHistory = {}

local COOLDOWNS = {
	Dash = 8,
	FreezeTime = 30,
	Phase = 23,
	Shockwave = 22,
	SpeedBurst = 15,
	Momentum = 30,
	Teleport = 12,
	TimeRewind = 20,
	Bomber = 10,
	-- New skills
	TitanShield = 30,
	RainbowStar = 45,
	SakuraBloom = 25,
	FrostFreeze = 20,
	VoidPortal = 15,
	LightningShock = 18,
	PhantomClone = 20,
	AcidPool = 18,
	GravityField = 25,
}
RunService.Heartbeat:Connect(function()
	for _, p in pairs(Players:GetPlayers()) do
		local c = p.Character
		if c then
			local h = c:FindFirstChild("HumanoidRootPart")
			if h then
				if not posHistory[p.UserId] then posHistory[p.UserId] = {} end
				table.insert(posHistory[p.UserId], {pos = h.CFrame, time = tick()})
				while #posHistory[p.UserId] > 0 and tick() - posHistory[p.UserId][1].time > 10 do
					table.remove(posHistory[p.UserId], 1)
				end
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		posHistory[plr.UserId] = {}
		task.wait(1)
		posHistory[plr.UserId] = {}
		-- Cooldown persists through resets (no exploit)
		-- Position history cleared above
	end)
end)

local function execFreezeTime(plr, td)
	local dur = math.clamp(td.SkillDuration or 4.5, 1, 4.5)
	-- #region agent log
	dbg("H_FT", "SkillHandler:execFreezeTime", "ENTRY", {player=plr.Name, duration=dur, tdDuration=td.SkillDuration, playerCount=#Players:GetPlayers()})
	-- #endregion
	local frozen = {}
	for _, o in pairs(Players:GetPlayers()) do
		if o ~= plr and o.Character then
			local oH = o.Character:FindFirstChild("HumanoidRootPart")
			local oU = o.Character:FindFirstChild("Humanoid")
			if oH and oU and oU.Health > 0 then
				local ss, sj = oU.WalkSpeed, oU.JumpPower
				oU.WalkSpeed = 0
				oU.JumpPower = 0
				oU.AutoRotate = false
				oH.AssemblyLinearVelocity = Vector3.zero
				NotifyClient:FireClient(o, "TIME STOPPED!", plr.DisplayName .. " froze time!", dur, "freeze")
				table.insert(frozen, {H = oU, SS = ss, SJ = sj})
				-- #region agent log
				dbg("H_FT", "SkillHandler:execFreezeTime", "Froze player", {target=o.Name})
				-- #endregion
			end
		end
	end
	-- #region agent log
	dbg("H_FT", "SkillHandler:execFreezeTime", "Firing BWEffect to all", {frozenCount=#frozen, duration=dur})
	-- #endregion
	BWEffect:FireAllClients(true, dur, plr.UserId, plr.DisplayName)
	task.delay(dur, function()
		BWEffect:FireAllClients(false, 0)
		for _, d in ipairs(frozen) do
			if d.H and d.H.Parent then
				d.H.AutoRotate = true
				d.H.WalkSpeed = d.SS
				d.H.JumpPower = d.SJ
				d.H.PlatformStand = false
				d.H:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	end)
	return {Success = true, Count = #frozen, CooldownDelay = dur}
end

local function execDash(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local lookDir = h.CFrame.LookVector
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {c}
	local groundRay = workspace:Raycast(h.Position, Vector3.new(0, -10, 0), rayParams)
	local dashDir = lookDir
	if groundRay then
		local normal = groundRay.Normal
		local projected = lookDir - normal * lookDir:Dot(normal)
		if projected.Magnitude > 0.1 then dashDir = projected.Unit end
	end
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bv.Velocity = dashDir * 80 + Vector3.new(0, 2, 0)
	bv.Parent = h
	Debris:AddItem(bv, 0.25)
	task.spawn(function()
		for j = 1, 6 do
			if not h or not h.Parent then break end
			local box = Instance.new("Part")
			box.Name = "seeBox"
			box.Size = Vector3.new(1.5, 1.5, 1.5)
			box.CFrame = h.CFrame
			box.Anchored = true
			box.CanCollide = false
			box.Material = Enum.Material.Neon
			box.Color = Color3.fromRGB(50, 200, 255)
			box.Transparency = 0.3
			box.Parent = workspace
			Debris:AddItem(box, 0.6)
			task.wait(0.04)
		end
	end)
	return true
end

local function execPhase(plr, td)
	local c = plr.Character
	if not c then return false end
	local hum = c:FindFirstChild("Humanoid")
	if not hum then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local dur = math.clamp(td.SkillDuration or 2, 0.5, 10)
	c:SetAttribute("Phasing", true)
	local origTransparency = {}
	for _, p in pairs(c:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			origTransparency[p] = p.Transparency
			p.Transparency = math.min(p.Transparency + 0.5, 0.8)
		end
	end
	pcall(function()
		local PS = game:GetService("PhysicsService")
		pcall(function() PS:RegisterCollisionGroup("PhasePlayer") end)
		pcall(function() PS:RegisterCollisionGroup("SolidPlayer") end)
		pcall(function() PS:RegisterCollisionGroup("FallingObject") end)
		pcall(function() PS:CollisionGroupSetCollidable("PhasePlayer", "SolidPlayer", false) end)
		pcall(function() PS:CollisionGroupSetCollidable("PhasePlayer", "FallingObject", false) end)
		pcall(function() PS:CollisionGroupSetCollidable("PhasePlayer", "Default", true) end)
		-- Set player to PhasePlayer
		for _, p in pairs(c:GetDescendants()) do
			if p:IsA("BasePart") then p.CollisionGroup = "PhasePlayer" end
		end
		-- Set other players to SolidPlayer
		for _, op in pairs(Players:GetPlayers()) do
			if op ~= plr and op.Character then
				for _, p in pairs(op.Character:GetDescendants()) do
					if p:IsA("BasePart") then p.CollisionGroup = "SolidPlayer" end
				end
			end
		end
		-- Set ALL falling objects to FallingObject group
		local foc = workspace:FindFirstChild("FallingObjectsContainer")
		if foc then
			for _, obj in pairs(foc:GetDescendants()) do
				if obj:IsA("BasePart") then obj.CollisionGroup = "FallingObject" end
			end
		end
		-- Set Props folder objects too
		local props = workspace:FindFirstChild("Props")
		if props then
			for _, obj in pairs(props:GetDescendants()) do
				if obj:IsA("BasePart") then obj.CollisionGroup = "FallingObject" end
			end
		end
	end)
	
	-- Keep tagging NEW objects that spawn during phase
	local phaseConn
	task.spawn(function()
		local foc = workspace:FindFirstChild("FallingObjectsContainer")
		if foc then
			phaseConn = foc.DescendantAdded:Connect(function(obj)
				if obj:IsA("BasePart") then
					pcall(function() obj.CollisionGroup = "FallingObject" end)
				end
			end)
		end
	end)
	-- Afterimage effect on server
	task.spawn(function()
		local startT = tick()
		while (tick() - startT) < dur and c and c.Parent and h and h.Parent do
			for _, part in pairs(c:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 0.9 then
					local ghost = Instance.new("Part")
					ghost.Name = "Afterimage"
					ghost.Size = part.Size
					ghost.CFrame = part.CFrame
					ghost.Anchored = true
					ghost.CanCollide = false
					ghost.Material = Enum.Material.Neon
					ghost.Color = Color3.fromRGB(200, 180, 255)
					ghost.Transparency = 0.5
					ghost.Parent = workspace
					Debris:AddItem(ghost, 0.4)
				end
			end
			task.wait(0.15)
		end
	end)
	task.delay(dur, function()
		-- Disconnect the object watcher
		if phaseConn then phaseConn:Disconnect() phaseConn = nil end
		
		if c and c.Parent then
			c:SetAttribute("Phasing", nil)
			for _, p in pairs(c:GetDescendants()) do
				if p:IsA("BasePart") then pcall(function() p.CollisionGroup = "Default" end) end
			end
			for p, t in pairs(origTransparency) do
				if p and p.Parent then p.Transparency = t end
			end
		end
		-- Restore other players
		for _, op in pairs(Players:GetPlayers()) do
			if op ~= plr and op.Character then
				for _, p in pairs(op.Character:GetDescendants()) do
					if p:IsA("BasePart") then pcall(function() p.CollisionGroup = "Default" end) end
				end
			end
		end
		-- Restore falling objects
		local foc = workspace:FindFirstChild("FallingObjectsContainer")
		if foc then
			for _, obj in pairs(foc:GetDescendants()) do
				if obj:IsA("BasePart") then pcall(function() obj.CollisionGroup = "Default" end) end
			end
		end
		local props = workspace:FindFirstChild("Props")
		if props then
			for _, obj in pairs(props:GetDescendants()) do
				if obj:IsA("BasePart") then pcall(function() obj.CollisionGroup = "Default" end) end
			end
		end
		
		NotifyClient:FireClient(plr, "Phase", "Phase ended!", 2, "info")
	end)
	return {Success = true, CooldownDelay = dur}
end

local function execShockwave(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local kb = td.SkillKnockback or 10
	local range = 35
	local ct = 0
	local ring = Instance.new("Part")
	ring.Name = "seeBox"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.5, 4, 4)
	ring.CFrame = h.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 255, 100)
	ring.Transparency = 0.3
	ring.Parent = workspace
	Debris:AddItem(ring, 1.5)
	task.spawn(function()
		for j = 1, 15 do
			task.wait(0.05)
			if ring and ring.Parent then
				local s = 4 + (j * 5)
				ring.Size = Vector3.new(0.5, s, s)
				ring.Transparency = 0.3 + (j * 0.04)
			end
		end
	end)
	for _, o in pairs(Players:GetPlayers()) do
		if o ~= plr and o.Character then
			local oH = o.Character:FindFirstChild("HumanoidRootPart")
			local oHum = o.Character:FindFirstChild("Humanoid")
			if oH and oHum and oHum.Health > 0 then
				local dist = (oH.Position - h.Position).Magnitude
				if dist <= range then
					local dir = (oH.Position - h.Position)
					if dir.Magnitude > 0.1 then dir = dir.Unit else dir = Vector3.new(1, 0, 0) end
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					bv.Velocity = dir * kb * 12 + Vector3.new(0, 40, 0)
					bv.Parent = oH
					Debris:AddItem(bv, 0.4)
					ct = ct + 1
				end
			end
		end
	end
	return {Success = true, Count = ct}
end

local speedBurstActive = {}
local function execSpeedBurst(plr, td)
	if speedBurstActive[plr.UserId] then
		NotifyClient:FireClient(plr, "Active!", "Speed Burst already active!", 2, "warning")
		return false
	end
	local c = plr.Character
	if not c then return false end
	local hum = c:FindFirstChild("Humanoid")
	if not hum then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	local dur = 5
	local baseSpeed = c:GetAttribute("BaseWalkSpeed") or hum.WalkSpeed
	hum.WalkSpeed = baseSpeed * 2.5
	speedBurstActive[plr.UserId] = true
	if h then
		task.spawn(function()
			for j = 1, dur * 4 do
				if not h or not h.Parent or not hum or not hum.Parent then break end
				local box = Instance.new("Part")
				box.Name = "SpeedTrail"
				box.Size = Vector3.new(0.4, 0.4, 2.5)
				box.CFrame = h.CFrame * CFrame.new(math.random(-2, 2), math.random(-1, 2), -2)
				box.Anchored = true
				box.CanCollide = false
				box.Material = Enum.Material.Neon
				box.Color = Color3.fromRGB(255, 120, 30)
				box.Transparency = 0.3
				box.Parent = workspace
				Debris:AddItem(box, 0.4)
				task.wait(0.25)
			end
		end)
	end
	task.delay(dur, function()
		if hum and hum.Parent then hum.WalkSpeed = baseSpeed end
		speedBurstActive[plr.UserId] = nil
	end)
	return {Success = true, CooldownDelay = dur}
end

-- MOMENTUM: Sustained boost, long duration
local momentumActive = {}
local function execMomentum(plr, td)
	if momentumActive[plr.UserId] then
		NotifyClient:FireClient(plr, "Active!", "Momentum already active!", 2, "warning")
		return false
	end
	local c = plr.Character
	if not c then return false end
	local hum = c:FindFirstChild("Humanoid")
	if not hum then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	local dur = 15
	local baseSpeed = c:GetAttribute("BaseWalkSpeed") or hum.WalkSpeed
	hum.WalkSpeed = baseSpeed * (19 / 16)
	momentumActive[plr.UserId] = true
	if h then
		task.spawn(function()
			for j = 1, dur * 2 do
				if not h or not h.Parent or not hum or not hum.Parent then break end
				local box = Instance.new("Part")
				box.Name = "MomentumTrail"
				box.Size = Vector3.new(0.3, 0.3, 1.8)
				box.CFrame = h.CFrame * CFrame.new(math.random(-1, 1), math.random(0, 2), -1.5)
				box.Anchored = true
				box.CanCollide = false
				box.Material = Enum.Material.Neon
				box.Color = Color3.fromRGB(80, 255, 120)
				box.Transparency = 0.4
				box.Parent = workspace
				Debris:AddItem(box, 0.6)
				task.wait(0.5)
			end
		end)
	end
	task.delay(dur, function()
		if hum and hum.Parent then hum.WalkSpeed = baseSpeed end
		momentumActive[plr.UserId] = nil
	end)
	return {Success = true, CooldownDelay = dur}
end

local function execTeleport(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local dist = math.clamp(td.SkillDistance or 32, 16, 48)
	local look3D = h.CFrame.LookVector
	local flatLook = Vector3.new(look3D.X, 0, look3D.Z)
	if flatLook.Magnitude < 0.1 then flatLook = Vector3.new(0, 0, -1) end
	flatLook = flatLook.Unit

	-- Raycast params - exclude character
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {c}

	-- Wall check - how far forward can we go?
	local actualDist = dist
	for yOff = 2, 8, 2 do
		local origin = h.Position + Vector3.new(0, yOff, 0)
		local ray = workspace:Raycast(origin, flatLook * dist, rayParams)
		if ray then
			local isWall = math.abs(ray.Normal.Y) < 0.3
			if isWall and ray.Distance < actualDist then
				actualDist = math.max(ray.Distance - 3, 2)
			end
		end
	end

	-- Start effect
	local startBox = Instance.new("Part")
	startBox.Name = "seeBox"
	startBox.Size = Vector3.new(3, 5, 3)
	startBox.CFrame = h.CFrame
	startBox.Anchored = true
	startBox.CanCollide = false
	startBox.Material = Enum.Material.Neon
	startBox.Color = Color3.fromRGB(150, 0, 255)
	startBox.Transparency = 0.4
	startBox.Parent = workspace
	Debris:AddItem(startBox, 1.5)

	-- Find landing spot - ONLY on Ramp parts
	-- Build whitelist of all Ramp parts
	local rampParams = RaycastParams.new()
	local rampParts = {}
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "Ramp" then
			table.insert(rampParts, obj)
		end
	end

	-- If we have Ramp parts, use Include filter to ONLY land on them
	local useRampFilter = #rampParts > 0
	if useRampFilter then
		rampParams.FilterType = Enum.RaycastFilterType.Include
		rampParams.FilterDescendantsInstances = rampParts
	else
		-- Fallback: no ramps found, use normal exclude filter
		rampParams.FilterType = Enum.RaycastFilterType.Exclude
		rampParams.FilterDescendantsInstances = {c}
	end

	-- Try multiple distances to find a Ramp to land on
	local finalPos = nil
	local tryDistances = {actualDist, actualDist * 0.75, actualDist * 0.5, actualDist * 0.25}
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {c}
	local function isSafeTeleportPoint(pos)
		local nearby = workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(6, 8, 6), overlapParams)
		local hasSolid = false
		for _, part in ipairs(nearby) do
			if part:IsA("BasePart") and part.CanCollide and part.Transparency < 1 then
				hasSolid = true
				break
			end
		end
		if not hasSolid then
			return false
		end
		local floorRay = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), rayParams)
		return floorRay ~= nil
	end

	for _, tryDist in ipairs(tryDistances) do
		local targetXZ = h.Position + flatLook * tryDist
		local downOrigin = Vector3.new(targetXZ.X, h.Position.Y + 500, targetXZ.Z)
		local downRay = workspace:Raycast(downOrigin, Vector3.new(0, -1000, 0), rampParams)
		if downRay then
			local candidate = downRay.Position + Vector3.new(0, 3.5, 0)
			if isSafeTeleportPoint(candidate) then
				finalPos = candidate
				break
			end
		end
	end

	-- If no Ramp found and we have ramp filter, try fallback: land on any solid ground ahead
	if not finalPos then
		local fallbackParams = RaycastParams.new()
		fallbackParams.FilterType = Enum.RaycastFilterType.Exclude
		fallbackParams.FilterDescendantsInstances = {c}
		for _, tryDist in ipairs(tryDistances) do
			local targetXZ = h.Position + flatLook * tryDist
			local downOrigin = Vector3.new(targetXZ.X, h.Position.Y + 500, targetXZ.Z)
			local downRay = workspace:Raycast(downOrigin, Vector3.new(0, -1000, 0), fallbackParams)
			if downRay and downRay.Instance.CanCollide then
				local candidate = downRay.Position + Vector3.new(0, 3.5, 0)
				if isSafeTeleportPoint(candidate) then
					finalPos = candidate
					break
				end
			end
		end
	end
	-- If still no position and we had ramp filter, try nearest Ramp
	if not finalPos and useRampFilter then
		-- Find closest Ramp part in the forward direction
		local bestRamp = nil
		local bestDist = math.huge
		for _, ramp in ipairs(rampParts) do
			local toRamp = (ramp.Position - h.Position)
			local flatToRamp = Vector3.new(toRamp.X, 0, toRamp.Z)
			local dot = 0
			if flatToRamp.Magnitude > 0.1 then
				dot = flatToRamp.Unit:Dot(flatLook)
			end
			-- Must be roughly in front of player (within ~90 degrees)
			if dot > 0.3 and flatToRamp.Magnitude < dist and flatToRamp.Magnitude < bestDist then
				bestRamp = ramp
				bestDist = flatToRamp.Magnitude
			end
		end
		if bestRamp then
			local candidate = bestRamp.Position + Vector3.new(0, 3.5, 0)
			if isSafeTeleportPoint(candidate) then
				finalPos = candidate
			end
		end
	end

	if not finalPos then
		NotifyClient:FireClient(plr, "Can't TP!", "No safe spot ahead!", 2, "warning")
		return false
	end

	-- Teleport
	h.AssemblyLinearVelocity = Vector3.zero
	h.AssemblyAngularVelocity = Vector3.zero
	h.Anchored = true
	h.CFrame = CFrame.new(finalPos) * CFrame.Angles(0, math.atan2(-flatLook.X, -flatLook.Z), 0)
	task.delay(0.1, function()
		if h and h.Parent then
			h.Anchored = false
			h.AssemblyLinearVelocity = Vector3.zero
		end
	end)

	-- End effect
	local endBox = Instance.new("Part")
	endBox.Name = "seeBox"
	endBox.Size = Vector3.new(3, 5, 3)
	endBox.CFrame = h.CFrame
	endBox.Anchored = true
	endBox.CanCollide = false
	endBox.Material = Enum.Material.Neon
	endBox.Color = Color3.fromRGB(200, 50, 255)
	endBox.Transparency = 0.3
	endBox.Parent = workspace
	Debris:AddItem(endBox, 1.5)
	return true
end

local function execTimeRewind(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local hum = c:FindFirstChild("Humanoid")
	local hist = posHistory[plr.UserId]
	if not hist or #hist < 3 then
		NotifyClient:FireClient(plr, "Not Enough Data!", "Move around first!", 2, "warning")
		return false
	end
	local rewindTime = td.SkillRewindTime or 4
	local target = tick() - rewindTime
	local best = nil
	for ii, e in ipairs(hist) do
		if e.time <= target then best = e end
	end
	if not best and #hist > 0 then best = hist[1] end
	if not best then
		NotifyClient:FireClient(plr, "No History!", "Try again!", 2, "warning")
		return false
	end
	local rewindPos = best.pos
	local distance = (h.Position - rewindPos.Position).Magnitude
	if distance < 2 then
		NotifyClient:FireClient(plr, "Too Close!", "Move more first!", 2, "warning")
		return false
	end
	if hum then
		hum.PlatformStand = false
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	for _, part in pairs(c:GetDescendants()) do
		if part:IsA("BodyVelocity") or part:IsA("BodyForce") or part:IsA("BodyGyro") or part:IsA("BodyAngularVelocity") then
			part:Destroy()
		end
	end
	local anchoredParts = {}
	for _, part in pairs(c:GetDescendants()) do
		if part:IsA("BasePart") then
			if not part.Anchored then
				part.Anchored = true
				table.insert(anchoredParts, part)
			end
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	local oldPos = rewindPos.Position
	local oldLook = rewindPos.LookVector
	local flatLook = Vector3.new(oldLook.X, 0, oldLook.Z)
	if flatLook.Magnitude < 0.1 then flatLook = Vector3.new(0, 0, -1) end
	flatLook = flatLook.Unit
	h.CFrame = CFrame.new(oldPos) * CFrame.Angles(0, math.atan2(-flatLook.X, -flatLook.Z), 0)
	local curBox = Instance.new("Part")
	curBox.Name = "seeBox"
	curBox.Size = Vector3.new(3, 5, 3)
	curBox.CFrame = h.CFrame
	curBox.Anchored = true
	curBox.CanCollide = false
	curBox.Material = Enum.Material.Neon
	curBox.Color = Color3.fromRGB(0, 200, 150)
	curBox.Transparency = 0.3
	curBox.Parent = workspace
	Debris:AddItem(curBox, 1.5)
	task.delay(0.3, function()
		for _, part in ipairs(anchoredParts) do
			if part and part.Parent then
				part.Anchored = false
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
		if hum and hum.Parent then
			hum.PlatformStand = false
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
	return true
end

local function execBomber(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local bombRadius = 25
	local bombDamage = 25
	local bombKnockback = 15
	local fuseTime = 3
	local look3D = h.CFrame.LookVector
	local flatLook = Vector3.new(look3D.X, 0, look3D.Z)
	if flatLook.Magnitude < 0.1 then flatLook = Vector3.new(0, 0, -1) end
	flatLook = flatLook.Unit
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {c}
	local aheadPos = h.Position + flatLook * 8
	local groundRay = workspace:Raycast(aheadPos + Vector3.new(0, 20, 0), Vector3.new(0, -40, 0), rayParams)
	local bombPos
	if groundRay then
		bombPos = groundRay.Position + Vector3.new(0, 1.5, 0)
	else
		bombPos = h.Position + flatLook * 8 + Vector3.new(0, 1, 0)
	end
	local bomb = Instance.new("Part")
	bomb.Name = "Bomb_" .. plr.Name
	bomb.Shape = Enum.PartType.Ball
	bomb.Size = Vector3.new(3, 3, 3)
	bomb.CFrame = CFrame.new(bombPos)
	bomb.Color = Color3.fromRGB(30, 30, 30)
	bomb.Material = Enum.Material.SmoothPlastic
	bomb.Anchored = true
	bomb.CanCollide = true
	bomb.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 0, 0)
	light.Brightness = 2
	light.Range = 8
	light.Parent = bomb
	local fuse = Instance.new("Part")
	fuse.Name = "Fuse"
	fuse.Size = Vector3.new(0.3, 0.8, 0.3)
	fuse.CFrame = CFrame.new(bombPos + Vector3.new(0, 2, 0))
	fuse.Color = Color3.fromRGB(255, 100, 0)
	fuse.Material = Enum.Material.Neon
	fuse.Anchored = true
	fuse.CanCollide = false
	fuse.Parent = bomb
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 60, 0, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = bomb
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = "💣 3"
	tl.TextColor3 = Color3.fromRGB(255, 50, 50)
	tl.TextStrokeTransparency = 0
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 24
	tl.Parent = bb
	task.spawn(function()
		for countdown = fuseTime, 1, -1 do
			if not bomb or not bomb.Parent then return end
			tl.Text = "💣 " .. countdown
			local blinkCount = countdown == 1 and 5 or 2
			for blink = 1, blinkCount do
				if not bomb or not bomb.Parent then return end
				light.Enabled = false
				bomb.Color = Color3.fromRGB(200, 50, 50)
				task.wait(countdown == 1 and 0.1 or 0.25)
				if not bomb or not bomb.Parent then return end
				light.Enabled = true
				bomb.Color = Color3.fromRGB(30, 30, 30)
				task.wait(countdown == 1 and 0.1 or 0.25)
			end
		end
		if not bomb or not bomb.Parent then return end
		local explodePos = bomb.Position
		local explosion = Instance.new("Part")
		explosion.Name = "BombExplosion"
		explosion.Shape = Enum.PartType.Ball
		explosion.Size = Vector3.new(4, 4, 4)
		explosion.CFrame = CFrame.new(explodePos)
		explosion.Anchored = true
		explosion.CanCollide = false
		explosion.Material = Enum.Material.Neon
		explosion.Color = Color3.fromRGB(255, 150, 0)
		explosion.Transparency = 0.2
		explosion.Parent = workspace
		Debris:AddItem(explosion, 1)
		task.spawn(function()
			for ex = 1, 10 do
				task.wait(0.03)
				if explosion and explosion.Parent then
					local s = 4 + (ex * 5)
					explosion.Size = Vector3.new(s, s, s)
					explosion.Transparency = 0.2 + (ex * 0.08)
				end
			end
		end)
		local re = Instance.new("Explosion")
		re.Position = explodePos
		re.BlastRadius = 0
		re.BlastPressure = 0
		re.DestroyJointRadiusPercent = 0
		re.Parent = workspace
		for _, o in pairs(Players:GetPlayers()) do
			if o.Character then
				local oH = o.Character:FindFirstChild("HumanoidRootPart")
				local oHum = o.Character:FindFirstChild("Humanoid")
				if oH and oHum and oHum.Health > 0 then
					local d = (oH.Position - explodePos).Magnitude
					if d <= bombRadius then
						local dir = (oH.Position - explodePos)
						if dir.Magnitude > 0.1 then dir = dir.Unit else dir = Vector3.new(0, 1, 0) end
						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
						bv.Velocity = dir * bombKnockback * 10 + Vector3.new(0, 50, 0)
						bv.Parent = oH
						Debris:AddItem(bv, 0.5)
						if o ~= plr then
							oHum.Health = math.max(oHum.Health - bombDamage, 1)
						end
					end
				end
			end
		end
		bomb:Destroy()
	end)
	return {Success = true, CooldownDelay = fuseTime}
end

-- TitanShield: 10s immune to ragdoll, phase through objects
local function execTitanShield(plr, td)
	-- #region agent log
	dbg("H2", "SkillHandler:execTitanShield", "TitanShield ENTRY", {player=plr.Name, hasChar=plr.Character~=nil})
	-- #endregion
	local c = plr.Character
	if not c then return false end
	local hum = c:FindFirstChild("Humanoid")
	local h = c:FindFirstChild("HumanoidRootPart")
	if not hum or not h then return false end
	local dur = 10
	c:SetAttribute("Shielded", true)
	c:SetAttribute("Phasing", true)
	-- Visible ForceField shield
	local ff = Instance.new("ForceField")
	ff.Name = "TitanShieldFF"
	ff.Visible = true
	ff.Parent = c
	-- Blue glow on body
	local origColors = {}
	for _, p in pairs(c:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			origColors[p] = p.Color
			p.Color = Color3.fromRGB(80, 150, 255)
			p.Material = Enum.Material.Neon
		end
	end
	-- #region agent log
	dbg("H2", "SkillHandler:execTitanShield", "Shielded+Phasing set, ForceField created", {shielded=c:GetAttribute("Shielded")})
	-- #endregion
	-- Collision groups
	local PS = game:GetService("PhysicsService")
	pcall(function() PS:RegisterCollisionGroup("PhasePlayer") end)
	pcall(function() PS:RegisterCollisionGroup("SolidPlayer") end)
	pcall(function() PS:RegisterCollisionGroup("FallingObject") end)
	pcall(function() PS:CollisionGroupSetCollidable("PhasePlayer", "SolidPlayer", false) end)
	pcall(function() PS:CollisionGroupSetCollidable("PhasePlayer", "FallingObject", false) end)
	pcall(function() PS:CollisionGroupSetCollidable("PhasePlayer", "Default", true) end) -- keep ground collision
	for _, p in pairs(c:GetDescendants()) do
		if p:IsA("BasePart") then pcall(function() p.CollisionGroup = "PhasePlayer" end) end
	end
	-- Set existing falling objects
	local foc = workspace:FindFirstChild("FallingObjectsContainer")
	if foc then
		for _, obj in pairs(foc:GetDescendants()) do
			if obj:IsA("BasePart") then pcall(function() obj.CollisionGroup = "FallingObject" end) end
		end
	end
	local props = workspace:FindFirstChild("Props")
	if props then
		for _, obj in pairs(props:GetDescendants()) do
			if obj:IsA("BasePart") then pcall(function() obj.CollisionGroup = "FallingObject" end) end
		end
	end
	-- Watch for NEW objects spawned during shield
	local newObjConn = nil
	if foc then
		newObjConn = foc.DescendantAdded:Connect(function(obj)
			if obj:IsA("BasePart") then
				pcall(function() obj.CollisionGroup = "FallingObject" end)
			end
		end)
	end
	task.delay(dur - 2, function()
		if c and c.Parent and c:GetAttribute("Shielded") then
			NotifyClient:FireClient(plr, "TitanShield", "Shield ending in 2s!", 2, "warning")
			task.spawn(function()
				for i = 1, 4 do
					if not c or not c.Parent then break end
					for _, p in pairs(c:GetDescendants()) do
						if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
							pcall(function()
								p.Transparency = (i % 2 == 0) and 0.15 or 0
							end)
						end
					end
					task.wait(0.25)
				end
				if c and c.Parent then
					for _, p in pairs(c:GetDescendants()) do
						if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
							pcall(function() p.Transparency = 0 end)
						end
					end
				end
			end)
		end
	end)
	task.delay(dur, function()
		-- Disconnect watcher
		if newObjConn then newObjConn:Disconnect() end
		-- Remove shield
		if ff and ff.Parent then ff:Destroy() end
		if c and c.Parent then
			c:SetAttribute("Shielded", nil)
			c:SetAttribute("Phasing", nil)
			for _, p in pairs(c:GetDescendants()) do
				if p:IsA("BasePart") then
					pcall(function() p.CollisionGroup = "Default" end)
					if origColors[p] then pcall(function() p.Color = origColors[p] p.Material = Enum.Material.SmoothPlastic end) end
				end
			end
		end
		-- Reset falling objects
		if foc then for _, obj in pairs(foc:GetDescendants()) do if obj:IsA("BasePart") then pcall(function() obj.CollisionGroup = "Default" end) end end end
		if props then for _, obj in pairs(props:GetDescendants()) do if obj:IsA("BasePart") then pcall(function() obj.CollisionGroup = "Default" end) end end end
	end)
	return {Success = true, CooldownDelay = dur}
end

-- RainbowStar: Mario star power - speed, jump, phase, invincibility
local function execRainbowStar(plr, td)
	-- #region agent log
	dbg("H3", "SkillHandler:execRainbowStar", "RainbowStar ENTRY", {player=plr.Name})
	-- #endregion
	local c = plr.Character
	if not c then return false end
	local hum = c:FindFirstChild("Humanoid")
	local h = c:FindFirstChild("HumanoidRootPart")
	if not hum or not h then return false end
	local dur = 10
	local ff = Instance.new("ForceField")
	ff.Parent = c
	c:SetAttribute("Shielded", true)
	local baseSpeed = c:GetAttribute("BaseWalkSpeed") or hum.WalkSpeed
	local baseJump = c:GetAttribute("BaseJumpPower") or hum.JumpPower
	hum.WalkSpeed = baseSpeed * 1.8
	hum.JumpPower = baseJump * 1.5
	-- #region agent log
	dbg("H_RS1", "SkillHandler:execRainbowStar", "Buffs applied", {duration=dur, baseSpeed=baseSpeed, newSpeed=hum.WalkSpeed, baseJump=baseJump, newJump=hum.JumpPower})
	-- #endregion
	c:SetAttribute("Phasing", true)
	pcall(function()
		local PS = game:GetService("PhysicsService")
		pcall(function() PS:RegisterCollisionGroup("PhasePlayer") end)
		pcall(function() PS:RegisterCollisionGroup("SolidPlayer") end)
		pcall(function() PS:RegisterCollisionGroup("FallingObject") end)
		pcall(function() PS:CollisionGroupSetCollidable("PhasePlayer", "SolidPlayer", false) end)
		pcall(function() PS:CollisionGroupSetCollidable("PhasePlayer", "FallingObject", false) end)
		for _, p in pairs(c:GetDescendants()) do
			if p:IsA("BasePart") then p.CollisionGroup = "PhasePlayer" end
		end
		for _, op in pairs(Players:GetPlayers()) do
			if op ~= plr and op.Character then
				for _, p in pairs(op.Character:GetDescendants()) do
					if p:IsA("BasePart") then p.CollisionGroup = "SolidPlayer" end
				end
			end
		end
		local foc = workspace:FindFirstChild("FallingObjectsContainer")
		if foc then for _, obj in pairs(foc:GetDescendants()) do if obj:IsA("BasePart") then obj.CollisionGroup = "FallingObject" end end end
		local props = workspace:FindFirstChild("Props")
		if props then for _, obj in pairs(props:GetDescendants()) do if obj:IsA("BasePart") then obj.CollisionGroup = "FallingObject" end end end
	end)
	-- Fire rainbow color cycling to ALL players so everyone sees it
	for _, p in pairs(Players:GetPlayers()) do
		RainbowStarEffect:FireClient(p, true, dur, plr.UserId)
	end
	task.delay(dur, function()
		if ff and ff.Parent then ff:Destroy() end
		if hum and hum.Parent then hum.WalkSpeed = baseSpeed hum.JumpPower = baseJump end
		if c and c.Parent then c:SetAttribute("Phasing", nil) c:SetAttribute("Shielded", nil) end
		for _, p in pairs(c:GetDescendants()) do
			if p:IsA("BasePart") then pcall(function() p.CollisionGroup = "Default" end) end
		end
		for _, op in pairs(Players:GetPlayers()) do
			if op.Character then
				for _, p in pairs(op.Character:GetDescendants()) do
					if p:IsA("BasePart") then pcall(function() p.CollisionGroup = "Default" end) end
				end
			end
		end
		local foc = workspace:FindFirstChild("FallingObjectsContainer")
		if foc then for _, obj in pairs(foc:GetDescendants()) do if obj:IsA("BasePart") then pcall(function() obj.CollisionGroup = "Default" end) end end end
		local props = workspace:FindFirstChild("Props")
		if props then for _, obj in pairs(props:GetDescendants()) do if obj:IsA("BasePart") then pcall(function() obj.CollisionGroup = "Default" end) end end end
		for _, p in pairs(Players:GetPlayers()) do
			RainbowStarEffect:FireClient(p, false, 0, plr.UserId)
		end
	end)
	return {Success = true, CooldownDelay = dur}
end

-- SakuraBloom: Heal to full + 5s speed boost + shield
local function execSakuraBloom(plr, td)
	local c = plr.Character
	if not c then return false end
	local hum = c:FindFirstChild("Humanoid")
	if not hum then return false end
	local dur = 5
	hum.Health = hum.MaxHealth
	local baseSpeed = c:GetAttribute("BaseWalkSpeed") or hum.WalkSpeed
	local oldShield = c:GetAttribute("TrailShield") or 0
	hum.WalkSpeed = baseSpeed * 1.15
	c:SetAttribute("TrailShield", math.max(oldShield, 0.15))
	task.delay(dur, function()
		if hum and hum.Parent then hum.WalkSpeed = baseSpeed end
		if c and c.Parent and c:GetAttribute("TrailShield") == 0.15 then c:SetAttribute("TrailShield", oldShield) end
	end)
	return {Success = true, CooldownDelay = dur}
end

-- FrostFreeze: Freeze players within 12 studs for 1.5s
local function execFrostFreeze(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local radius = 12
	local dur = 1.5
	local frozen = {}
	local nearestDist = math.huge
	-- #region agent log
	dbg("H_FF1", "SkillHandler:execFrostFreeze", "FrostFreeze ENTRY", {player=plr.Name, radius=radius, duration=dur, origin=tostring(h.Position)})
	-- #endregion
	for _, o in pairs(Players:GetPlayers()) do
		if o ~= plr and o.Character then
			local oH = o.Character:FindFirstChild("HumanoidRootPart")
			local oU = o.Character:FindFirstChild("Humanoid")
			if oH and oU and oU.Health > 0 then
				local dist = (oH.Position - h.Position).Magnitude
				if dist < nearestDist then nearestDist = dist end
				if dist <= radius then
					local ss, sj = oU.WalkSpeed, oU.JumpPower
					oU.WalkSpeed = 0 oU.JumpPower = 0 oU.AutoRotate = false oU.PlatformStand = true oH.AssemblyLinearVelocity = Vector3.zero
					local ice = Instance.new("Part")
					ice.Name = "FrostFreezeFX"
					ice.Size = Vector3.new(5, 6, 5)
					ice.CFrame = oH.CFrame
					ice.Anchored = true
					ice.CanCollide = false
					ice.Material = Enum.Material.Ice
					ice.Color = Color3.fromRGB(160, 220, 255)
					ice.Transparency = 0.45
					ice.Parent = workspace
					Debris:AddItem(ice, dur + 0.5)
					NotifyClient:FireClient(o, "FROZEN!", plr.DisplayName .. " froze you!", dur, "freeze")
					table.insert(frozen, {H = oU, SS = ss, SJ = sj})
				end
			end
		end
	end
	-- #region agent log
	dbg("H_FF1", "SkillHandler:execFrostFreeze", "Freeze scan summary", {frozenCount=#frozen, nearestEnemyDist=nearestDist == math.huge and -1 or math.floor(nearestDist * 100) / 100})
	-- #endregion
	task.delay(dur, function()
		for _, d in ipairs(frozen) do
			if d.H and d.H.Parent then
				d.H.AutoRotate = true d.H.WalkSpeed = d.SS d.H.JumpPower = d.SJ d.H.PlatformStand = false
				d.H:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	end)
	return {Success = true, Count = #frozen, CooldownDelay = 0}
end

-- VoidPortal: Place portals, owner can teleport between them
local playerPortals = {}
local portalDebounce = {} -- MODULE-LEVEL: shared across ALL portals per player
local function execVoidPortal(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local uid = plr.UserId
	if not playerPortals[uid] then playerPortals[uid] = {} end
	local portals = playerPortals[uid]
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {c}
	local groundRay = workspace:Raycast(h.Position + Vector3.new(0, 2, 0), Vector3.new(0, -20, 0), rayParams)
	local pos = groundRay and (groundRay.Position + Vector3.new(0, 0.5, 0)) or (h.Position + Vector3.new(0, 0.5, 0))
	if #portals >= 2 then
		local oldest = table.remove(portals, 1)
		if oldest and oldest.Parent then oldest:Destroy() end
	end
	local portal = Instance.new("Part")
	portal.Name = "VoidPortal_" .. plr.Name
	portal.Size = Vector3.new(4, 1, 4)
	portal.Shape = Enum.PartType.Cylinder
	portal.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	portal.Anchored = true portal.CanCollide = false
	portal.Material = Enum.Material.Neon portal.Color = Color3.fromRGB(5, 0, 15)
	portal.Transparency = 0.3 portal.Parent = workspace
	portal:SetAttribute("PortalOwner", uid)
	table.insert(portals, portal)
	Debris:AddItem(portal, 60)
	local function onTouched(toucher)
		local tchar = toucher.Parent
		local tplr = Players:GetPlayerFromCharacter(tchar)
		if not tplr or tplr ~= plr then return end
		if #portals < 2 then return end
		-- #region agent log
		dbg("H4", "SkillHandler:VoidPortal:onTouched", "Portal touched", {player=plr.Name, portalCount=#portals, debounce=portalDebounce[uid] or false})
		-- #endregion
		if portalDebounce[uid] then return end
		portalDebounce[uid] = true
		local other = portals[1] == portal and portals[2] or portals[1]
		if not other or not other.Parent then portalDebounce[uid] = nil return end
		local opos = other.Position + Vector3.new(0, 3, 0)
		local hrp = tplr.Character and tplr.Character:FindFirstChild("HumanoidRootPart")
		if hrp and hrp.Parent then
			hrp.CFrame = CFrame.new(opos)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
		task.delay(2, function() portalDebounce[uid] = nil end)
	end
	portal.Touched:Connect(onTouched)
	return {Success = true, CooldownDelay = 0}
end

-- LightningShock: Zap players within 15 studs, 15 dmg, 1s stun, knockback
local function execLightningShock(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local radius = 15 local kb = 15 local dmg = 15 local stunDur = 1 local ct = 0
	local shocked = {}
	local nearest = math.huge
	-- #region agent log
	dbg("H_LT2", "SkillHandler:execLightningShock", "LightningShock ENTRY", {player=plr.Name, radius=radius, damage=dmg, stunDuration=stunDur, origin=tostring(h.Position)})
	-- #endregion
	for _, o in pairs(Players:GetPlayers()) do
		if o ~= plr and o.Character then
			local oH = o.Character:FindFirstChild("HumanoidRootPart")
			local oHum = o.Character:FindFirstChild("Humanoid")
			if oH and oHum and oHum.Health > 0 then
				local dist = (oH.Position - h.Position).Magnitude
				if dist < nearest then nearest = dist end
				if dist <= radius then
					local dir = (oH.Position - h.Position)
					if dir.Magnitude > 0.1 then dir = dir.Unit else dir = Vector3.new(1, 0, 0) end
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					bv.Velocity = dir * kb * 8 + Vector3.new(0, 30, 0)
					bv.Parent = oH
					Debris:AddItem(bv, 0.4)
					oHum.Health = math.max(oHum.Health - dmg, 1)
					LightningShockEffect:FireClient(o, stunDur)
					NotifyClient:FireClient(o, "Stunned!", plr.DisplayName .. " shocked you!", stunDur, "warning")
					local ss, sj = oHum.WalkSpeed, oHum.JumpPower
					oHum.WalkSpeed = 0 oHum.JumpPower = 0 oHum.AutoRotate = false oH.AssemblyLinearVelocity = Vector3.zero
					table.insert(shocked, {H = oHum, SS = ss, SJ = sj})
					-- #region agent log
					dbg("H_LT2", "SkillHandler:execLightningShock", "Target shocked", {target=o.Name, distance=math.floor(dist * 100) / 100, newHealth=oHum.Health, notified=true})
					-- #endregion
					ct = ct + 1
				end
			end
		end
	end
	-- #region agent log
	dbg("H_LT2", "SkillHandler:execLightningShock", "Shock summary", {player=plr.Name, shockedCount=ct, nearestEnemy=nearest == math.huge and -1 or math.floor(nearest * 100) / 100})
	-- #endregion
	task.delay(stunDur, function()
		for _, d in ipairs(shocked) do
			if d.H and d.H.Parent then d.H.AutoRotate = true d.H.WalkSpeed = d.SS d.H.JumpPower = d.SJ d.H:ChangeState(Enum.HumanoidStateType.GettingUp) end
		end
	end)
	return {Success = true, Count = ct, CooldownDelay = 0}
end

-- PhantomClone: 3 ghost clones of the player + 30% speed for 4s
local function execPhantomClone(plr, td)
	-- #region agent log
	dbg("H5", "SkillHandler:execPhantomClone", "PhantomClone ENTRY", {player=plr.Name})
	-- #endregion
	local c = plr.Character
	if not c then return false end
	local hum = c:FindFirstChild("Humanoid")
	local h = c:FindFirstChild("HumanoidRootPart")
	if not hum or not h then return false end
	local dur = 4
	local baseSpeed = c:GetAttribute("BaseWalkSpeed") or hum.WalkSpeed
	hum.WalkSpeed = baseSpeed * 1.3
	-- #region agent log
	dbg("H_PC1", "SkillHandler:execPhantomClone", "Speed boost applied", {baseSpeed=baseSpeed, newSpeed=hum.WalkSpeed, duration=dur, origin=tostring(h.Position)})
	-- #endregion
	-- Determine trail color for ghost tint
	local cloneColor = Color3.fromRGB(150, 150, 200)
	if td and td.Color1 then cloneColor = td.Color1 end
	for i = 1, 3 do
		task.spawn(function()
			local dir = Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)
			if dir.Magnitude < 0.3 then dir = Vector3.new(1, 0, 0) end
			dir = dir.Unit * 18
			-- Use Archivable to clone the full character model
			local wasArchivable = c.Archivable
			c.Archivable = true
			local clone = c:Clone()
			c.Archivable = wasArchivable
			clone.Name = plr.Name .. "_PhantomClone_" .. i
			-- Remove scripts, humanoid state, tools from clone
			for _, child in pairs(clone:GetDescendants()) do
				if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
					child:Destroy()
				end
			end
			-- Remove tool objects
			for _, child in pairs(clone:GetChildren()) do
				if child:IsA("Tool") or child:IsA("BackpackItem") then child:Destroy() end
			end
			-- Make clone ghostly
			local cloneHum = clone:FindFirstChild("Humanoid")
			if cloneHum then
				cloneHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				cloneHum.NameDisplayDistance = 0
				cloneHum.HealthDisplayDistance = 0
			end
			for _, part in pairs(clone:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = math.max(part.Transparency, 0.4)
					part.Material = Enum.Material.Neon
					part.Color = cloneColor
				end
			end
			-- Position offset
			local cloneHRP = clone:FindFirstChild("HumanoidRootPart")
			if cloneHRP then
				cloneHRP.CFrame = h.CFrame * CFrame.new((i - 2) * 4, 0, 0)
				-- #region agent log
				dbg("H_PC1", "SkillHandler:execPhantomClone", "Clone spawned", {index=i, clonePos=tostring(cloneHRP.Position), sourcePos=tostring(h.Position)})
				-- #endregion
			else
				-- #region agent log
				dbg("H_PC1", "SkillHandler:execPhantomClone", "Clone missing HRP", {index=i})
				-- #endregion
			end
			clone.Parent = workspace
			Debris:AddItem(clone, 4)
			-- Animate: move in direction + fade out, while hugging ground on slopes
			task.spawn(function()
				local stepPos = cloneHRP and cloneHRP.Position or h.Position
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {c, clone}
				for t = 1, 20 do
					task.wait(0.15)
					if not clone or not clone.Parent then break end
					stepPos = stepPos + Vector3.new(dir.X * 0.15, 0, dir.Z * 0.15)
					local groundRay = workspace:Raycast(stepPos + Vector3.new(0, 12, 0), Vector3.new(0, -30, 0), rayParams)
					if groundRay then
						stepPos = Vector3.new(stepPos.X, groundRay.Position.Y + 2.7, stepPos.Z)
					end
					if clone.PrimaryPart then
						clone:PivotTo(CFrame.new(stepPos, stepPos + Vector3.new(dir.X, 0, dir.Z)))
					else
						for _, gp in pairs(clone:GetDescendants()) do
							if gp:IsA("BasePart") then
								gp.CFrame = gp.CFrame + Vector3.new(dir.X * 0.15, 0, dir.Z * 0.15)
							end
						end
					end
					for _, gp in pairs(clone:GetDescendants()) do
						if gp:IsA("BasePart") then
							gp.Transparency = math.min(0.4 + (t * 0.03), 1)
						end
					end
				end
				if clone and clone.Parent then clone:Destroy() end
			end)
		end)
	end
	task.delay(dur, function()
		if hum and hum.Parent then hum.WalkSpeed = baseSpeed end
		-- #region agent log
		dbg("H_PC1", "SkillHandler:execPhantomClone", "Speed restored", {restoredSpeed=baseSpeed, stillHasHum=hum and hum.Parent ~= nil})
		-- #endregion
	end)
	return {Success = true, CooldownDelay = dur}
end

-- AcidPool: Circle puddles that follow the player for 5s (dropped along path), work on ramps
local acidPuddleRadius = 4
local acidPuddleDamagePerSec = 3
local acidPuddleSlowMult = 0.7
local acidPuddleLifetime = 4

local function spawnAcidPuddle(plr, worldPos)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {plr.Character or {}}
	if not plr.Character then return end
	local rayOrigin = worldPos + Vector3.new(0, 5, 0)
	local groundRay = workspace:Raycast(rayOrigin, Vector3.new(0, -40, 0), rayParams)
	local pos = groundRay and groundRay.Position or worldPos
	local size = Vector3.new(0.3, 8, 8) -- X=thickness, Y/Z=diameter (bigger circles)
	local pool = Instance.new("Part")
	pool.Name = "AcidPuddle_" .. plr.Name
	pool.Size = size
	pool.Shape = Enum.PartType.Cylinder
	pool.CFrame = CFrame.new(pos + Vector3.new(0, size.X / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	if groundRay and groundRay.Normal then
		local n = groundRay.Normal
		if n.Y < 0.99 then
			local tangent = n:Cross(Vector3.new(0, 1, 0))
			if tangent.Magnitude < 0.01 then tangent = n:Cross(Vector3.new(1, 0, 0)) end
			tangent = tangent.Unit
			pool.CFrame = CFrame.fromMatrix(pos + n * (size.X / 2), n, tangent)
		end
	end
	pool.Anchored = true
	pool.CanCollide = false
	pool.Material = Enum.Material.Neon
	pool.Color = Color3.fromRGB(80, 255, 0)
	pool.Transparency = 0.2
	pool.Parent = workspace
	-- Glow ring around the puddle
	local ring = Instance.new("Part")
	ring.Name = "AcidRing"
	ring.Size = Vector3.new(0.15, 8.5, 8.5)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = pool.CFrame
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(0, 180, 0)
	ring.Transparency = 0.5
	ring.Parent = workspace
	Debris:AddItem(ring, acidPuddleLifetime + 1)
	-- Bubble particles rising from puddle
	local bubbleAttach = Instance.new("Attachment")
	bubbleAttach.Parent = pool
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "AcidBubbles"
	bubbles.Color = ColorSequence.new(Color3.fromRGB(100, 255, 50), Color3.fromRGB(0, 200, 0))
	bubbles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0)})
	bubbles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	bubbles.Lifetime = NumberRange.new(0.5, 1.2)
	bubbles.Rate = 12
	bubbles.Speed = NumberRange.new(1, 3)
	bubbles.SpreadAngle = Vector2.new(30, 30)
	bubbles.LightEmission = 0.6
	bubbles.Parent = bubbleAttach
	-- Fade out puddle near end
	task.delay(acidPuddleLifetime - 1, function()
		if pool and pool.Parent then
			task.spawn(function()
				for i = 1, 10 do
					task.wait(0.1)
					if pool and pool.Parent then pool.Transparency = 0.2 + (i * 0.08) end
					if ring and ring.Parent then ring.Transparency = 0.5 + (i * 0.05) end
				end
			end)
		end
	end)
	Debris:AddItem(pool, acidPuddleLifetime + 1)
	local center = pool.Position
	local rad = acidPuddleRadius
	local puddleEnd = tick() + acidPuddleLifetime
	local ownerUserId = plr.UserId
	local damageConn
	damageConn = RunService.Heartbeat:Connect(function(dt)
		if not pool or not pool.Parent or tick() > puddleEnd then
			if damageConn then damageConn:Disconnect() end
			return
		end
		for _, o in pairs(Players:GetPlayers()) do
			if o.UserId ~= ownerUserId and o.Character then
				local oH = o.Character:FindFirstChild("HumanoidRootPart")
				local oU = o.Character:FindFirstChild("Humanoid")
				if oH and oU and oU.Health > 0 then
					local d = (oH.Position - center).Magnitude
					if d <= rad then
						o.Character:SetAttribute("RegenBlockedUntil", tick() + 0.5)
						oU:TakeDamage(acidPuddleDamagePerSec * dt)
						local base = o.Character:GetAttribute("BaseWalkSpeed") or 16
						oU.WalkSpeed = math.min(oU.WalkSpeed, base * acidPuddleSlowMult)
					end
				end
			end
		end
	end)
	task.delay(acidPuddleLifetime + 1, function()
		if damageConn then damageConn:Disconnect() end
	end)
end

local function execAcidPool(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {c}
	local poolDur = 5
	local puddleInterval = 0.55
	local skillEndTime = tick() + poolDur
	do
		local groundRay = workspace:Raycast(h.Position + Vector3.new(0, 5, 0), Vector3.new(0, -40, 0), rayParams)
		spawnAcidPuddle(plr, groundRay and groundRay.Position or h.Position)
	end
	task.spawn(function()
		while tick() < skillEndTime do
			task.wait(puddleInterval)
			if not c or not c.Parent or not h or not h.Parent then break end
			local groundRay = workspace:Raycast(h.Position + Vector3.new(0, 5, 0), Vector3.new(0, -40, 0), rayParams)
			local pos = groundRay and groundRay.Position or h.Position
			spawnAcidPuddle(plr, pos)
		end
	end)
	return {Success = true, CooldownDelay = poolDur}
end

-- GravityField: Enemies in 12 studs float for 4s
local gravityFieldActive = {}
local function execGravityField(plr, td)
	local c = plr.Character
	if not c then return false end
	local h = c:FindFirstChild("HumanoidRootPart")
	if not h then return false end
	local radius = 12 local dur = 4
	local affected = {}
	-- #region agent log
	dbg("H_GF1", "SkillHandler:execGravityField", "GravityField ENTRY", {player=plr.Name, radius=radius, duration=dur, origin=tostring(h.Position)})
	-- #endregion
	for _, o in pairs(Players:GetPlayers()) do
		if o ~= plr and o.Character then
			local oH = o.Character:FindFirstChild("HumanoidRootPart")
			local oU = o.Character:FindFirstChild("Humanoid")
			if oH and oU and oU.Health > 0 then
				local dist = (oH.Position - h.Position).Magnitude
				if dist <= radius then
					local bv = Instance.new("BodyVelocity")
					bv.Name = "GravityFieldForce"
					bv.MaxForce = Vector3.new(0, math.huge, 0)
					bv.Velocity = Vector3.new(0, 30, 0)
					bv.Parent = oH
					local ring = Instance.new("Part")
					ring.Name = "GravityFieldFX"
					ring.Shape = Enum.PartType.Ball
					ring.Size = Vector3.new(4, 4, 4)
					ring.CFrame = oH.CFrame
					ring.Anchored = false
					ring.CanCollide = false
					ring.Massless = true
					ring.Transparency = 0.65
					ring.Material = Enum.Material.Neon
					ring.Color = Color3.fromRGB(140, 110, 255)
					ring.Parent = workspace
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = oH
					weld.Part1 = ring
					weld.Parent = ring
					Debris:AddItem(ring, dur + 0.5)
					NotifyClient:FireClient(o, "Low Gravity!", plr.DisplayName .. " made you float!", 2, "warning")
					table.insert(affected, {hrp = oH, force = bv})
					-- #region agent log
					dbg("H_GF1", "SkillHandler:execGravityField", "Target affected", {target=o.Name, distance=math.floor(dist * 100) / 100, velocityY=bv.Velocity.Y})
					-- #endregion
				end
			end
		end
	end
	-- #region agent log
	dbg("H_GF1", "SkillHandler:execGravityField", "GravityField summary", {affectedCount=#affected})
	-- #endregion
	task.delay(dur, function()
		for _, a in ipairs(affected) do
			if a.force and a.force.Parent then a.force:Destroy() end
		end
	end)
	return {Success = true, Count = #affected, CooldownDelay = dur}
end

local EXEC = {
	FreezeTime = execFreezeTime,
	Dash = execDash,
	Phase = execPhase,
	Shockwave = execShockwave,
	SpeedBurst = execSpeedBurst,
	Momentum = execMomentum,
	Teleport = execTeleport,
	TimeRewind = execTimeRewind,
	Bomber = execBomber,
	TitanShield = execTitanShield,
	RainbowStar = execRainbowStar,
	SakuraBloom = execSakuraBloom,
	FrostFreeze = execFrostFreeze,
	VoidPortal = execVoidPortal,
	LightningShock = execLightningShock,
	PhantomClone = execPhantomClone,
	AcidPool = execAcidPool,
	GravityField = execGravityField,
}

ActivateSkill.OnServerEvent:Connect(function(plr)
	-- #region agent log
	dbg("H2", "SkillHandler:ActivateSkill", "ActivateSkill fired", {player=plr.Name, gameStateExists=GameState~=nil, gameStateVal=GameState and GameState.Value or "NIL", hasSkill=playerSkills[plr.UserId]~=nil, skillId=playerSkills[plr.UserId] and playerSkills[plr.UserId].SkillId or "NONE"})
	-- #endregion
	-- LOBBY BLOCK: skills only work during rounds
	local roundActive = isRoundActive()
	local gsVal = GameState and GameState.Value or "NIL"
	-- #region agent log
	dbg("H_ACT", "SkillHandler:ActivateSkill", "Round check", {roundActive=roundActive, gameStateVal=gsVal, gameStateExists=GameState~=nil})
	-- #endregion
	if not roundActive then
		NotifyClient:FireClient(plr, "Not Now!", "Skills only work during rounds!", 2, "warning")
		dbg("H_ACT", "SkillHandler:ActivateSkill", "BLOCKED: round not active", {gameStateVal=gsVal})
		return
	end
	local ps = playerSkills[plr.UserId]
	if not ps or not ps.SkillId then
		-- #region agent log
		dbg("H2", "SkillHandler:ActivateSkill", "BLOCKED: No skill registered", {uid=plr.UserId, ps=ps and "exists" or "nil"})
		-- #endregion
		NotifyClient:FireClient(plr, "No Skill!", "Equip a trail with a skill first!", 2, "warning")
		return
	end
	local cdToUse = COOLDOWNS[ps.SkillId] or ps.Cooldown or 10
	if ps.SkillActiveUntil and tick() < ps.SkillActiveUntil then
		local rem = math.ceil(ps.SkillActiveUntil - tick())
		NotifyClient:FireClient(plr, "Active!", "Skill still active for " .. rem .. "s", 2, "warning")
		return
	end
	if ps.LastUsed and (tick() - ps.LastUsed) < cdToUse then
		local rem = math.ceil(cdToUse - (tick() - ps.LastUsed))
		NotifyClient:FireClient(plr, "Cooldown!", "Wait " .. rem .. "s", 2, "warning")
		return
	end
	local fn = EXEC[ps.SkillId]
	-- #region agent log
	dbg("H2", "SkillHandler:ActivateSkill", "Calling exec", {skillId=ps.SkillId, fnExists=fn~=nil})
	-- #endregion
	if fn then
		local raw = fn(plr, ps.TrailData or {})
		local ok = false
		local result = nil
		local cooldownDelay = 0
		if type(raw) == "table" then
			ok = raw.Success ~= false
			result = raw.Count
			cooldownDelay = math.max(tonumber(raw.CooldownDelay) or 0, 0)
		elseif type(raw) == "number" then
			ok = true
			result = raw
		elseif type(raw) == "boolean" then
			ok = raw
		else
			ok = raw ~= nil
		end
		if not ok then
			return
		end
		ps.SkillActiveUntil = tick() + cooldownDelay
		if cooldownDelay > 0 then
			SkillActiveStart:FireClient(plr, cooldownDelay, ps.SkillId)
		end
		ps.CooldownToken = (ps.CooldownToken or 0) + 1
		local token = ps.CooldownToken
		local function startCooldownNow()
			local current = playerSkills[plr.UserId]
			if not current or current.CooldownToken ~= token then return end
			current.LastUsed = tick()
			current.SkillActiveUntil = nil
			SkillCooldownStart:FireClient(plr, cdToUse)
		end
		if cooldownDelay > 0 then
			task.delay(cooldownDelay, startCooldownNow)
		else
			startCooldownNow()
		end
		local msg = ps.SkillId
		local notifDur = 2
		if ps.SkillId == "FreezeTime" then msg = "Froze " .. (result or 0) .. " players! (" .. (cooldownDelay > 0 and cooldownDelay or 1.5) .. "s)" notifDur = 3
		elseif ps.SkillId == "Shockwave" then msg = "Pushed " .. (result or 0) .. " players!"
		elseif ps.SkillId == "Dash" then msg = "Dashed forward!"
		elseif ps.SkillId == "Phase" then msg = "Phasing for 8s!"
		elseif ps.SkillId == "SpeedBurst" then msg = "Speed boost for 5s!" notifDur = 3
		elseif ps.SkillId == "Momentum" then msg = "Momentum for 15s!" notifDur = 3
		elseif ps.SkillId == "Teleport" then msg = "Teleported!"
		elseif ps.SkillId == "TimeRewind" then msg = "Rewound!"
		elseif ps.SkillId == "Bomber" then msg = "Bomb deployed! 3s fuse!"
		elseif ps.SkillId == "TitanShield" then msg = "Shield active for 10s!" notifDur = 3
		elseif ps.SkillId == "RainbowStar" then msg = "Star Power for 10s!" notifDur = 3
		elseif ps.SkillId == "SakuraBloom" then msg = "Healed + boost for 5s!"
		elseif ps.SkillId == "FrostFreeze" then msg = "Froze " .. (result or 0) .. " players! (1.5s)"
		elseif ps.SkillId == "VoidPortal" then msg = "Portal created!"
		elseif ps.SkillId == "LightningShock" then msg = "Zapped " .. (result or 0) .. " players!"
		elseif ps.SkillId == "PhantomClone" then msg = "Clones for 4s + speed boost!" notifDur = 3
		elseif ps.SkillId == "AcidPool" then msg = "Acid pool for 5s!" notifDur = 3
		elseif ps.SkillId == "GravityField" then msg = "Float " .. (result or 0) .. " players for 4s!"
		end
		NotifyClient:FireClient(plr, ps.SkillId .. "!", msg, notifDur, "skill")
		-- #region agent log
		dbg("H_SKMSG", "SkillHandler:ActivateSkill", "Skill notification fired", {player=plr.Name, skillId=ps.SkillId, title=ps.SkillId .. "!", message=msg, duration=notifDur, cooldownDelay=cooldownDelay, ntype="skill"})
		-- #endregion
		print("??", plr.Name, "used", ps.SkillId)
	end
end)

_G.OnTrailEquipped = function(plr, trailData)
	-- #region agent log
	dbg("H2", "SkillHandler:OnTrailEquipped", "Trail equipped callback", {player=plr.Name, hasTrailData=trailData~=nil, skillType=trailData and trailData.SkillType or "NONE", trailId=trailData and trailData.Id or "NONE"})
	-- #endregion
	if trailData and trailData.SkillType then
		local SKILL_INFO = {
			FreezeTime = {Icon = "FT", Name = "Freeze Time"},
			Dash = {Icon = "DS", Name = "Dash"},
			Phase = {Icon = "PH", Name = "Phase"},
			Shockwave = {Icon = "SW", Name = "Shockwave"},
			SpeedBurst = {Icon = "SB", Name = "Speed Burst"},
			Momentum = {Icon = "MO", Name = "Momentum"},
			Teleport = {Icon = "TP", Name = "Teleport"},
			TimeRewind = {Icon = "TR", Name = "Time Rewind"},
			Bomber = {Icon = "BM", Name = "Bomber"},
			TitanShield = {Icon = "TS", Name = "Titan Shield"},
			RainbowStar = {Icon = "RS", Name = "Star Power"},
			SakuraBloom = {Icon = "SK", Name = "Sakura Bloom"},
			FrostFreeze = {Icon = "FF", Name = "Frost Freeze"},
			VoidPortal = {Icon = "VP", Name = "Void Portal"},
			LightningShock = {Icon = "LS", Name = "Lightning"},
			PhantomClone = {Icon = "PC", Name = "Phantom Clone"},
			AcidPool = {Icon = "AP", Name = "Acid Pool"},
			GravityField = {Icon = "GF", Name = "Gravity Field"},
		}
		local info = SKILL_INFO[trailData.SkillType]
		if info then
			local existing = playerSkills[plr.UserId]
			local preservedLastUsed = existing and existing.LastUsed or nil
			local preservedActiveUntil = existing and existing.SkillActiveUntil or nil
			local preservedToken = existing and existing.CooldownToken or 0
			local isSameSkill = existing and existing.SkillId == trailData.SkillType
			playerSkills[plr.UserId] = {
				SkillId = trailData.SkillType,
				Cooldown = COOLDOWNS[trailData.SkillType] or 10,
				LastUsed = isSameSkill and preservedLastUsed or nil,
				SkillActiveUntil = isSameSkill and preservedActiveUntil or nil,
				CooldownToken = isSameSkill and preservedToken or 0,
				TrailData = trailData,
			}
		SkillUpdate:FireClient(plr, true, {
			Icon = info.Icon,
			Name = info.Name,
			Cooldown = COOLDOWNS[trailData.SkillType] or 10,
			RemainingCooldown = math.max(0, math.ceil((COOLDOWNS[trailData.SkillType] or 10) - (tick() - (playerSkills[plr.UserId].LastUsed or 0)))),
			ActiveRemaining = math.max(0, math.ceil((playerSkills[plr.UserId].SkillActiveUntil or 0) - tick())),
		})
			return
		end
	end
	playerSkills[plr.UserId] = nil
	SkillUpdate:FireClient(plr, false, nil)
end

Players.PlayerRemoving:Connect(function(plr)
	playerSkills[plr.UserId] = nil
	posHistory[plr.UserId] = nil
end)

print("? Skill Handler v2 loaded!")
print("   Skills: FreezeTime, Dash, Phase, Shockwave, SpeedBurst, Momentum, Teleport, TimeRewind, Bomber, TitanShield, RainbowStar, SakuraBloom, FrostFreeze, VoidPortal, LightningShock, PhantomClone, AcidPool, GravityField")

-- SKILL RESET ON ROUND END
local function resetAllSkills(reason)
	dbg("H_RESET", "SkillHandler:resetAllSkills", "Reset triggered", {reason=reason})
	for _, p in pairs(Players:GetPlayers()) do
		local ps = playerSkills[p.UserId]
		if ps then
			ps.LastUsed = nil
			ps.SkillActiveUntil = nil
			ps.CooldownToken = 0
		end
		if p.Character then
			p.Character:SetAttribute("Phasing", nil)
			p.Character:SetAttribute("Shielded", nil)
			for _, ff in pairs(p.Character:GetChildren()) do
				if ff:IsA("ForceField") then ff:Destroy() end
			end
		end
		-- Reset CLIENT-SIDE cooldowns
		pcall(function() SkillReset:FireClient(p) end)
	end
	-- Clean up portals
	for uid, portals in pairs(playerPortals) do
		for _, portal in ipairs(portals) do
			if portal and portal.Parent then portal:Destroy() end
		end
	end
	playerPortals = {}
	portalDebounce = {}
	print("Skills reset for all players (" .. reason .. ")")
end

-- Listen for GameState changes (round end)
task.spawn(function()
	local gv = RS:WaitForChild("GameValues", 30) or RS:FindFirstChild("GameValues")
	if not gv then dbg("H_RESET", "SkillHandler", "GameValues NOT FOUND after 30s") return end
	local gs = gv:WaitForChild("GameState", 15) or gv:FindFirstChild("GameState")
	if not gs then dbg("H_RESET", "SkillHandler", "GameState NOT FOUND after 15s") return end
	GameState = gs -- update the reference
	dbg("H_RESET", "SkillHandler", "GameState listener connected", {currentVal=gs.Value})
	gs.Changed:Connect(function(val)
		dbg("H_RESET", "SkillHandler:GameStateChanged", "State changed", {newVal=val})
		if val == "Intermission" or val == "RoundEnd" or val == "Voting" then
			resetAllSkills("round ended: " .. val)
		end
	end)
end)

-- Re-sync skill UI on player respawn
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		task.wait(1) -- wait for character to fully load
		local ps = playerSkills[plr.UserId]
		if ps and ps.SkillId then
			-- Reset cooldowns on respawn
			ps.LastUsed = nil
			ps.SkillActiveUntil = nil
			ps.CooldownToken = 0
			pcall(function() SkillReset:FireClient(plr) end)
			dbg("H_RESET", "SkillHandler:CharacterAdded", "Reset skill on respawn", {player=plr.Name, skillId=ps.SkillId})
		end
	end)
end)
-- Also handle players already in the game
for _, plr in pairs(Players:GetPlayers()) do
	plr.CharacterAdded:Connect(function(char)
		task.wait(1)
		local ps = playerSkills[plr.UserId]
		if ps and ps.SkillId then
			ps.LastUsed = nil
			ps.SkillActiveUntil = nil
			ps.CooldownToken = 0
			pcall(function() SkillReset:FireClient(plr) end)
		end
	end)
end
