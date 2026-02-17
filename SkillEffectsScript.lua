local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local gui = script.Parent
local freezeBanner = gui:WaitForChild("FreezeBanner")
local freezeTitle = freezeBanner:WaitForChild("Title")
local freezeMsg = freezeBanner:WaitForChild("Message")
local frostOverlay = gui:WaitForChild("FrostOverlay")
local timerBar = gui:WaitForChild("FreezeTimer")
local timerFill = timerBar:WaitForChild("Fill")

local reFolder = RS:WaitForChild("RemoteEvents", 15)
if not reFolder then warn("[SkillEffects] No RemoteEvents") return end

local BWEffect = reFolder:WaitForChild("BWEffect", 10)
local NotifyClient = reFolder:FindFirstChild("NotifyClient")
local RainbowStarEffect = reFolder:WaitForChild("RainbowStarEffect", 15)
local LightningShockEffect = reFolder:WaitForChild("LightningShockEffect", 15)
-- #region agent log
local reDbgFX = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents", 10)
local ClientDebugLogFX = reDbgFX and reDbgFX:FindFirstChild("ClientDebugLog")
local function cdbgFX(hId, loc, msg, data)
	if ClientDebugLogFX then pcall(function() ClientDebugLogFX:FireServer({hypothesisId=hId,location=loc,message=msg,data=data or {},timestamp=DateTime.now().UnixTimestampMillis}) end) end
end
cdbgFX("H3", "SkillEffectsScript:init", "Remote refs", {rainbowFound=RainbowStarEffect~=nil, lightningFound=LightningShockEffect~=nil})
-- #endregion

-- ============================================
-- B&W / FREEZE EFFECT
-- ============================================
local currentCC = nil

local function cleanupBW()
	-- Remove ALL BWColorCorrection effects
	for _, cc in pairs(Lighting:GetChildren()) do
		if cc:IsA("ColorCorrectionEffect") and (cc.Name == "BWColorCorrection" or cc.Name == "FreezeFlash") then
			cc:Destroy()
		end
	end
	currentCC = nil
end

local function applyFreezeEffect(duration)
	-- Clean any old effects
	cleanupBW()
	
	-- Create fresh B&W effect
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "BWColorCorrection"
	cc.Saturation = -1           -- FULL desaturation = true black & white
	cc.Brightness = -0.05        -- Slightly darker
	cc.Contrast = 0.15           -- More contrast for dramatic look
	cc.TintColor = Color3.new(1, 1, 1)  -- WHITE = no tint (prevents pink!)
	cc.Parent = Lighting
	currentCC = cc
	
	-- Quick white flash on freeze start
	local flash = Instance.new("ColorCorrectionEffect")
	flash.Name = "FreezeFlash"
	flash.Brightness = 0.6
	flash.Saturation = -1
	flash.Contrast = 0
	flash.TintColor = Color3.new(1, 1, 1)
	flash.Parent = Lighting
	TS:Create(flash, TweenInfo.new(0.4), {Brightness = 0}):Play()
	task.delay(0.5, function()
		if flash and flash.Parent then flash:Destroy() end
	end)
	
	-- Show freeze banner
	freezeBanner.Visible = true
	freezeBanner.Position = UDim2.new(0.5, 0, -0.1, 0) -- start offscreen
	TS:Create(freezeBanner, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, 0, 0.12, 0)
	}):Play()
	
	-- Show frost overlay (subtle blue tint on edges)
	frostOverlay.Visible = true
	frostOverlay.BackgroundTransparency = 0.85
	
	-- Show timer bar
	timerBar.Visible = true
	timerFill.Size = UDim2.new(1, 0, 1, 0)
	
	-- Animate timer bar draining
	TS:Create(timerFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()
	
	-- Auto cleanup after duration
	task.delay(duration, function()
		-- Smooth unfade
		if cc and cc.Parent then
			TS:Create(cc, TweenInfo.new(1), {
				Saturation = 0,
				Brightness = 0,
				Contrast = 0,
			}):Play()
			task.wait(1)
			if cc and cc.Parent then cc:Destroy() end
		end
		
		-- Hide banner (slide up)
		TS:Create(freezeBanner, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, -0.1, 0)
		}):Play()
		task.wait(0.3)
		freezeBanner.Visible = false
		
		-- Hide frost overlay
		TS:Create(frostOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		task.wait(0.5)
		frostOverlay.Visible = false
		
		-- Hide timer
		timerBar.Visible = false
		
		currentCC = nil
	end)
end

local function removeFreezeEffect()
	cleanupBW()
	freezeBanner.Visible = false
	frostOverlay.Visible = false
	timerBar.Visible = false
end

-- ============================================
-- LISTEN FOR BWEffect FROM SERVER
-- ============================================
if BWEffect then
	BWEffect.OnClientEvent:Connect(function(active, duration, casterUserId, casterName)
		if active then
			if tonumber(casterUserId) == player.UserId then
				freezeTitle.Text = "FREEZE TIME"
				freezeMsg.Text = "You froze all players!"
			else
				local who = tostring(casterName or "Another player")
				freezeTitle.Text = "TIME STOPPED"
				freezeMsg.Text = who .. " froze time!"
			end
			applyFreezeEffect(duration or 10)
		else
			removeFreezeEffect()
		end
	end)
	print("? BWEffect listener connected")
end

-- ============================================
-- LISTEN FOR SKILL NOTIFICATIONS FROM SERVER
-- ============================================
-- The server fires NotifyClient with freeze info to OTHER players
-- This catches "TIME STOPPED!" notifications for frozen players
if NotifyClient then
	NotifyClient.OnClientEvent:Connect(function(title, message, duration, ntype)
		-- Check if it's a freeze notification
		if ntype == "freeze" or (title and tostring(title):find("FROZEN")) or (title and tostring(title):find("STOPPED")) then
			-- Update banner text with attacker info
			freezeTitle.Text = "? " .. tostring(title)
			freezeMsg.Text = tostring(message)
		end
		
		-- Also pass to global notify system
		task.spawn(function()
			-- Wait a moment for _G.Notify to be ready
			local tries = 0
			while not _G.Notify and tries < 20 do
				task.wait(0.1)
				tries = tries + 1
			end
			if _G.Notify then
				_G.Notify(title, message, duration, ntype == "freeze" and "warning" or ntype)
			end
		end)
	end)
	print("? NotifyClient listener connected (freeze notifications)")
end

-- ============================================
-- RAINBOW STAR POWER (color cycling on local player)
-- ============================================
if RainbowStarEffect then
	local activeRainbowConns = {}
	local rainbowState = {}
	local RAINBOW_SEQUENCE = {
		Color3.fromRGB(0, 170, 255),   -- blue
		Color3.fromRGB(0, 255, 120),   -- green
		Color3.fromRGB(170, 80, 255),  -- purple
		Color3.fromRGB(255, 80, 80),   -- red
		Color3.fromRGB(255, 230, 80),  -- yellow
	}
	RainbowStarEffect.OnClientEvent:Connect(function(active, duration, targetUserId)
		-- #region agent log
		cdbgFX("H3", "SkillEffectsScript:RainbowStar", "Event received", {active=active, duration=duration, targetUserId=targetUserId, localUserId=player.UserId})
		-- #endregion
		-- Find target character (could be local or any other player)
		local targetPlayer = nil
		if targetUserId then
			for _, p in pairs(Players:GetPlayers()) do
				if p.UserId == targetUserId then targetPlayer = p break end
			end
		else
			targetPlayer = player
		end
		if not targetPlayer or not targetPlayer.Character then return end
		local char = targetPlayer.Character
		local uid = targetPlayer.UserId
		local partCount = 0
		for _, p in pairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				partCount = partCount + 1
			end
		end
		-- #region agent log
		cdbgFX("H_RS2", "SkillEffectsScript:RainbowStar", "Resolved target for rainbow", {targetName=targetPlayer.Name, partCount=partCount, duration=duration})
		-- #endregion
		-- If deactivating, clean up
		if not active then
			if activeRainbowConns[uid] then
				activeRainbowConns[uid]:Disconnect()
				activeRainbowConns[uid] = nil
			end
			local st = rainbowState[uid]
			if st then
				if st.ring and st.ring.Parent then st.ring:Destroy() end
				if st.origColors then
					for part, col in pairs(st.origColors) do
						if part and part.Parent then
							pcall(function() part.Color = col end)
						end
					end
				end
			end
			rainbowState[uid] = nil
			return
		end
		-- Store original colors once, then cycle through fixed rainbow sequence quickly.
		local origColors = {}
		for _, p in pairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				origColors[p] = p.Color
			end
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local ring = nil
		if hrp then
			ring = Instance.new("Part")
			ring.Name = "RainbowStarRing"
			ring.Shape = Enum.PartType.Ball
			ring.Size = Vector3.new(7, 7, 7)
			ring.CFrame = hrp.CFrame
			ring.Anchored = false
			ring.CanCollide = false
			ring.Massless = true
			ring.Material = Enum.Material.Neon
			ring.Transparency = 0.7
			ring.Color = RAINBOW_SEQUENCE[1]
			ring.Parent = workspace
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hrp
			weld.Part1 = ring
			weld.Parent = ring
		end
		rainbowState[uid] = {origColors = origColors, ring = ring}
		if activeRainbowConns[uid] then activeRainbowConns[uid]:Disconnect() end
		local conn
		local elapsed = 0
		conn = game:GetService("RunService").RenderStepped:Connect(function(dt)
			if not char or not char.Parent then if conn then conn:Disconnect() activeRainbowConns[uid] = nil end return end
			elapsed = elapsed + dt
			local index = (math.floor(elapsed * 4) % #RAINBOW_SEQUENCE) + 1 -- visible color swap
			local c = RAINBOW_SEQUENCE[index]
			for _, p in pairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					p.Color = c
				end
			end
			-- Also color accessories
			for _, acc in pairs(char:GetChildren()) do
				if acc:IsA("Accessory") then
					local handle = acc:FindFirstChild("Handle")
					if handle then pcall(function() handle.Color = c end) end
				end
			end
			if ring and ring.Parent then
				ring.Color = c
			end
		end)
		activeRainbowConns[uid] = conn
		task.delay(duration or 10, function()
			if activeRainbowConns[uid] then
				activeRainbowConns[uid]:Disconnect()
				activeRainbowConns[uid] = nil
			end
			local st = rainbowState[uid]
			if st then
				if st.ring and st.ring.Parent then st.ring:Destroy() end
				if st.origColors then
					for part, col in pairs(st.origColors) do
						if part and part.Parent then
							pcall(function() part.Color = col end)
						end
					end
				end
			end
			rainbowState[uid] = nil
		end)
	end)
end

-- ============================================
-- LIGHTNING SHOCK EFFECT (electricity on shocked players)
-- ============================================
if LightningShockEffect then
	LightningShockEffect.OnClientEvent:Connect(function(stunDuration)
		if not player.Character then return end
		local char = player.Character
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChild("Humanoid")
		if _G.Notify then
			_G.Notify("Stunned!", "You are shocked!", math.max(1, stunDuration or 1), "warning")
		end
		-- Screen feedback so stun is obvious to the victim.
		local shockFx = Instance.new("ColorCorrectionEffect")
		shockFx.Name = "LightningStunFX"
		shockFx.Brightness = 0.2
		shockFx.Contrast = 0.25
		shockFx.Saturation = -0.15
		shockFx.TintColor = Color3.fromRGB(255, 240, 120)
		shockFx.Parent = Lighting
		task.delay(math.max(0.25, stunDuration or 1), function()
			if shockFx and shockFx.Parent then shockFx:Destroy() end
		end)
		local ring = nil
		if hrp then
			ring = Instance.new("Part")
			ring.Name = "LightningStunRing"
			ring.Shape = Enum.PartType.Ball
			ring.Size = Vector3.new(6, 6, 6)
			ring.CFrame = hrp.CFrame
			ring.Anchored = false
			ring.CanCollide = false
			ring.Massless = true
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(255, 245, 130)
			ring.Transparency = 0.68
			ring.Parent = workspace
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hrp
			weld.Part1 = ring
			weld.Parent = ring
			task.delay(math.max(0.5, stunDuration or 1), function()
				if ring and ring.Parent then ring:Destroy() end
			end)
		end
		if hum then
			local oldHealth = hum.HealthDisplayDistance
			hum.HealthDisplayDistance = 0
			task.delay(math.max(0.25, stunDuration or 1), function()
				if hum and hum.Parent then hum.HealthDisplayDistance = oldHealth end
			end)
		end
		for i = 1, 6 do
			task.spawn(function()
				for j = 1, 3 do
					if not char or not char.Parent then return end
					local hrp2 = char:FindFirstChild("HumanoidRootPart")
					if not hrp2 then return end
					local bolt = Instance.new("Part")
					bolt.Name = "LightningBolt" bolt.Size = Vector3.new(0.2, 2, 0.2)
					bolt.Material = Enum.Material.Neon bolt.Color = Color3.fromRGB(255, 255, 150)
					bolt.Transparency = 0.3 bolt.Anchored = true bolt.CanCollide = false
					bolt.CFrame = hrp2.CFrame * CFrame.new(math.random(-3, 3), math.random(-2, 4), math.random(-3, 3))
					bolt.Parent = workspace
					task.delay(0.15, function() if bolt and bolt.Parent then bolt:Destroy() end end)
					task.wait(0.2)
				end
			end)
			task.wait(0.15)
		end
	end)
end

print("? Skill Effects Handler loaded!")
print("   ? Freeze: B&W + banner + timer bar")
print("   ? No pink tint (TintColor = white)")
