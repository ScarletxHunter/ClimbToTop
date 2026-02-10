-- ============================================
-- UNIVERSAL WEAPON HANDLER (Server)
-- Place in: ServerScriptService/UniversalWeaponHandler
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

print("?? Universal Weapon Handler loading...")

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local useWeaponEvent = remoteEvents:FindFirstChild("UseWeapon")
if not useWeaponEvent then
	useWeaponEvent = Instance.new("RemoteEvent")
	useWeaponEvent.Name = "UseWeapon"
	useWeaponEvent.Parent = remoteEvents
	print("? Created UseWeapon RemoteEvent")
end

local cooldowns = {}

local function isRoundActive()
	if _G.IsRoundActive then return _G.IsRoundActive() end
	return false
end

-- ============================================
-- WEAPONS
-- ============================================

local weapons = {
	["PushTool"] = {
		Cooldown = 2,
		Action = function(player)
			if not isRoundActive() then return end
			local character = player.Character
			if not character then return end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			for _, otherPlayer in pairs(Players:GetPlayers()) do
				if otherPlayer ~= player and otherPlayer.Character then
					local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
					if otherHrp then
						local distance = (hrp.Position - otherHrp.Position).Magnitude
						if distance <= 20 then
							local direction = (otherHrp.Position - hrp.Position).Unit
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.new(100000, 100000, 100000)
							bv.Velocity = direction * 60 + Vector3.new(0, 10, 0)
							bv.Parent = otherHrp
							Debris:AddItem(bv, 0.2)
						end
					end
				end
			end
		end
	},

	["Hammer"] = {
		Cooldown = 3,
		Action = function(player)
			if not isRoundActive() then return end
			local character = player.Character
			if not character then return end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			for _, otherPlayer in pairs(Players:GetPlayers()) do
				if otherPlayer ~= player and otherPlayer.Character then
					local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
					local otherHum = otherPlayer.Character:FindFirstChild("Humanoid")
					if otherHrp and otherHum and otherHum.Health > 0 then
						local distance = (hrp.Position - otherHrp.Position).Magnitude
						if distance <= 15 then
							local direction = (otherHrp.Position - hrp.Position).Unit
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.new(100000, 100000, 100000)
							bv.Velocity = direction * 50 + Vector3.new(0, 20, 0)
							bv.Parent = otherHrp
							Debris:AddItem(bv, 0.2)
						end
					end
				end
			end
		end
	},

	["SpeedGun"] = {
		Cooldown = 15,
		Action = function(player)
			local character = player.Character
			if not character then return end
			local humanoid = character:FindFirstChild("Humanoid")
			if not humanoid then return end
			local originalSpeed = humanoid.WalkSpeed
			humanoid.WalkSpeed = originalSpeed * 2
			task.delay(5, function()
				if humanoid and humanoid.Parent then
					humanoid.WalkSpeed = originalSpeed
				end
			end)
		end
	},

	["IceStaff"] = {
		Cooldown = 5,
		Action = function(player, targetPlayer)
			if not isRoundActive() then return end
			if not targetPlayer or not targetPlayer.Character then return end
			if targetPlayer == player then return end

			local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
			local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not targetHum or not targetHrp then return end

			local playerHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if playerHrp and (playerHrp.Position - targetHrp.Position).Magnitude > 50 then return end

			local origSpeed = targetHum.WalkSpeed
			local origJump = targetHum.JumpPower
			targetHum.WalkSpeed = 0
			targetHum.JumpPower = 0

			local ice = Instance.new("Part")
			ice.Name = "IceSphere"
			ice.Shape = Enum.PartType.Ball
			ice.Size = Vector3.new(5, 5, 5)
			ice.CFrame = targetHrp.CFrame
			ice.Anchored = true
			ice.CanCollide = false
			ice.Material = Enum.Material.Ice
			ice.Color = Color3.fromRGB(135, 206, 250)
			ice.Transparency = 0.5
			ice.Parent = workspace

			local p = Instance.new("ParticleEmitter")
			p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			p.Color = ColorSequence.new(Color3.fromRGB(135, 206, 250))
			p.Size = NumberSequence.new(0.5)
			p.Lifetime = NumberRange.new(0.5, 1)
			p.Rate = 50
			p.Parent = ice

			task.delay(3, function()
				if targetHum and targetHum.Parent then
					targetHum.WalkSpeed = origSpeed
					targetHum.JumpPower = origJump
				end
				if ice and ice.Parent then ice:Destroy() end
			end)
		end
	},

	["GravityHammer"] = {
		Cooldown = 8,
		Action = function(player)
			if not isRoundActive() then return end
			local character = player.Character
			if not character then return end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			for _, otherPlayer in pairs(Players:GetPlayers()) do
				if otherPlayer ~= player and otherPlayer.Character then
					local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
					local otherHum = otherPlayer.Character:FindFirstChild("Humanoid")
					if otherHrp and otherHum and otherHum.Health > 0 then
						if (hrp.Position - otherHrp.Position).Magnitude <= 25 then
							otherHum:TakeDamage(15)
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.new(0, 100000, 0)
							bv.Velocity = Vector3.new(0, -80, 0)
							bv.Parent = otherHrp
							Debris:AddItem(bv, 0.3)
						end
					end
				end
			end
		end
	},

	["AcidTrail"] = {
		Cooldown = 8,
		Action = function(player)
			if not isRoundActive() then return end
			local character = player.Character
			if not character then return end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			local TRAIL_DURATION = 5
			local SLOW_PERCENT = 0.4
			local SLOW_DURATION = 2.5
			local PUDDLE_LIFETIME = 4
			local PUDDLE_RADIUS = 4

			local puddles = {}
			local slowedPlayers = {}

			-- Spawn puddles
			task.spawn(function()
				local elapsed = 0
				while elapsed < TRAIL_DURATION do
					if not character or not character.Parent then break end
					if not hrp or not hrp.Parent then break end

					local puddle = Instance.new("Part")
					puddle.Name = "AcidPuddle"
					puddle.Size = Vector3.new(PUDDLE_RADIUS * 2, 0.3, PUDDLE_RADIUS * 2)
					puddle.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
					puddle.Anchored = true
					puddle.CanCollide = false
					puddle.Material = Enum.Material.Neon
					puddle.Color = Color3.fromRGB(0, 255, 0)
					puddle.Transparency = 0.3
					puddle.Shape = Enum.PartType.Cylinder
					puddle.Orientation = Vector3.new(0, 0, 90)
					puddle.Parent = workspace

					local particles = Instance.new("ParticleEmitter")
					particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
					particles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
					particles.Size = NumberSequence.new(0.5)
					particles.Lifetime = NumberRange.new(0.5, 1)
					particles.Rate = 15
					particles.Parent = puddle

					table.insert(puddles, puddle)
					Debris:AddItem(puddle, PUDDLE_LIFETIME)

					task.wait(0.25)
					elapsed = elapsed + 0.25
				end
			end)

			-- Distance-based slow check
			task.spawn(function()
				local checkDuration = TRAIL_DURATION + PUDDLE_LIFETIME + 1
				local checkElapsed = 0
				while checkElapsed < checkDuration do
					-- Clean expired
					local active = {}
					for _, p in ipairs(puddles) do
						if p and p.Parent then table.insert(active, p) end
					end
					puddles = active

					if #puddles == 0 and checkElapsed > TRAIL_DURATION then break end

					for _, otherPlayer in pairs(Players:GetPlayers()) do
						if otherPlayer ~= player and otherPlayer.Character then
							local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
							local otherHum = otherPlayer.Character:FindFirstChild("Humanoid")
							if otherHrp and otherHum and otherHum.Health > 0 then
								local nearPuddle = false
								for _, p in ipairs(puddles) do
									if p and p.Parent then
										if (otherHrp.Position - p.Position).Magnitude <= PUDDLE_RADIUS + 2 then
											nearPuddle = true
											break
										end
									end
								end

								if nearPuddle and not slowedPlayers[otherPlayer.UserId] then
									slowedPlayers[otherPlayer.UserId] = true
									local origSpeed = otherHum.WalkSpeed
									otherHum.WalkSpeed = origSpeed * SLOW_PERCENT
									print("?? Acid SLOWED", otherPlayer.Name)

									task.spawn(function()
										-- Green tint
										local tinted = {}
										for _, part in pairs(otherPlayer.Character:GetDescendants()) do
											if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
												table.insert(tinted, {part = part, color = part.Color})
												part.Color = Color3.fromRGB(
													math.floor(part.Color.R * 255 * 0.5),
													math.min(255, math.floor(part.Color.G * 255 * 0.5 + 128)),
													math.floor(part.Color.B * 255 * 0.5)
												)
											end
										end

										task.wait(SLOW_DURATION)

										if otherHum and otherHum.Parent then
											otherHum.WalkSpeed = origSpeed
										end
										for _, data in ipairs(tinted) do
											if data.part and data.part.Parent then
												data.part.Color = data.color
											end
										end
										slowedPlayers[otherPlayer.UserId] = nil
										print("?? Acid wore off for", otherPlayer.Name)
									end)
								end
							end
						end
					end

					task.wait(0.2)
					checkElapsed = checkElapsed + 0.2
				end
			end)
		end
	},

	["FlightBoots"] = {
		Cooldown = 12,
		Action = function(player)
			local character = player.Character
			if not character then return end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(0, math.huge, 0)
			bv.Velocity = Vector3.new(0, 50, 0)
			bv.Parent = hrp

			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
			particles.Size = NumberSequence.new(1)
			particles.Lifetime = NumberRange.new(0.5, 1)
			particles.Rate = 50
			particles.Speed = NumberRange.new(5, 10)
			particles.Parent = hrp

			task.delay(3, function()
				if bv and bv.Parent then bv:Destroy() end
				if particles and particles.Parent then particles:Destroy() end
			end)
		end
	}
}

-- ============================================
-- HANDLER
-- ============================================

useWeaponEvent.OnServerEvent:Connect(function(player, weaponName, ...)
	if not weapons[weaponName] then return end

	local weapon = weapons[weaponName]
	local playerCooldowns = cooldowns[player.UserId] or {}
	local lastUse = playerCooldowns[weaponName] or 0

	if tick() - lastUse < weapon.Cooldown then return end

	cooldowns[player.UserId] = playerCooldowns
	playerCooldowns[weaponName] = tick()

	print("??", player.Name, "used", weaponName)
	weapon.Action(player, ...)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.UserId] = nil
end)

print("? Universal Weapon Handler ready!")
print("   Registered weapons:")
for name, data in pairs(weapons) do
	print("   -", name, "(Cooldown: " .. data.Cooldown .. "s)")
end