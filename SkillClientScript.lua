local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = script.Parent

local reFolder = RS:WaitForChild("RemoteEvents", 15)
if not reFolder then warn("No RemoteEvents") return end


local ActivateSkill = reFolder:WaitForChild("ActivateSkill", 10)
local SkillUpdate = reFolder:WaitForChild("SkillUpdate", 10)
local NotifyClient = reFolder:WaitForChild("NotifyClient", 10)
local SkillCooldownStart = reFolder:WaitForChild("SkillCooldownStart", 10)
-- BWEffect handled by SkillEffectsGui

-- Get GUI elements
local skillFrame = gui:WaitForChild("SkillFrame")
local skillIcon = skillFrame:WaitForChild("SkillIcon")
local skillNameLabel = skillFrame:WaitForChild("SkillName")
local keyHint = skillFrame:WaitForChild("KeyHint")
local cdOverlay = skillFrame:WaitForChild("CooldownOverlay")
local cdText = cdOverlay:WaitForChild("CooldownText")

-- Make sure overlay is styled correctly
cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
cdOverlay.BackgroundTransparency = 0.5
cdOverlay.Visible = false
cdOverlay.ZIndex = skillFrame.ZIndex + 2
cdText.ZIndex = skillFrame.ZIndex + 3
cdText.TextColor3 = Color3.new(1, 1, 1)
cdText.TextSize = 22
cdText.Font = Enum.Font.GothamBlack
cdText.TextStrokeTransparency = 0
cdText.TextStrokeColor3 = Color3.new(0, 0, 0)
cdText.Text = ""

-- State
local hasSkill = false
local currentSkill = nil
local cooldown = 10
local lastUsedTime = 0
local onCooldown = false
local waitingForServer = false
local cooldownGeneration = 0

-- SKILL NOTIFICATION MAP (keys match info.Name from SkillUpdate)
local SKILL_NOTIFICATIONS = {
	["Freeze Time"] = {Title = "FREEZE TIME!", Message = "You froze all players!", Icon = "FT"},
	["Dash"] = {Title = "DASH!", Message = "Speed burst activated!", Icon = "DS"},
	["Phase"] = {Title = "PHASE!", Message = "You're phasing through obstacles!", Icon = "PH"},
	["Shockwave"] = {Title = "SHOCKWAVE!", Message = "Knockback wave unleashed!", Icon = "SW"},
	["Speed Burst"] = {Title = "SPEED BURST!", Message = "Maximum speed activated!", Icon = "SB"},
	["Momentum"] = {Title = "MOMENTUM!", Message = "Sustained speed boost!", Icon = "MO"},
	["Teleport"] = {Title = "TELEPORT!", Message = "Teleported forward!", Icon = "TP"},
	["Time Rewind"] = {Title = "TIME REWIND!", Message = "Rewinding position!", Icon = "TR"},
	["Bomber"] = {Title = "BOMBER!", Message = "Bomb deployed!", Icon = "BM"},
	["Titan Shield"] = {Title = "TITAN SHIELD!", Message = "Immune to ragdoll and collisions!", Icon = "TS"},
	["Star Power"] = {Title = "STAR POWER!", Message = "Invincible and super fast!", Icon = "RS"},
	["Sakura Bloom"] = {Title = "SAKURA BLOOM!", Message = "Healed and boosted!", Icon = "SK"},
	["Frost Freeze"] = {Title = "FROST FREEZE!", Message = "Froze nearby players!", Icon = "FF"},
	["Void Portal"] = {Title = "VOID PORTAL!", Message = "Portal placed!", Icon = "VP"},
	["Lightning"] = {Title = "LIGHTNING!", Message = "Zapped nearby players!", Icon = "LS"},
	["Phantom Clone"] = {Title = "PHANTOM CLONE!", Message = "Clones and speed boost!", Icon = "PC"},
	["Acid Pool"] = {Title = "ACID POOL!", Message = "Acid pool deployed!", Icon = "AP"},
	["Gravity Field"] = {Title = "GRAVITY FIELD!", Message = "Enemies float!", Icon = "GF"},
}

-- ============================================
-- SKILL BUTTON UPDATE
-- ============================================
SkillUpdate.OnClientEvent:Connect(function(active, info)
	if active and info then
		hasSkill = true
		currentSkill = info
		cooldown = info.Cooldown or 10
		skillIcon.Text = info.Icon or "SK"
		skillNameLabel.Text = info.Name or "Skill"
		skillFrame.Visible = true
		-- Re-sync cooldown UI after respawn/re-equip if server says cooldown still running.
		local remaining = tonumber(info.RemainingCooldown) or 0
		if remaining > 0 then
			cooldown = remaining
			onCooldown = true
			waitingForServer = false
			startCooldownDisplay()
		else
			onCooldown = false
			cdOverlay.Visible = false
			cdText.Text = ""
		end
		local activeRemaining = tonumber(info.ActiveRemaining) or 0
		if activeRemaining > 0 and _G.Notify then
			_G.Notify("Active", (info.Name or "Skill") .. " active for " .. activeRemaining .. "s", 2, "info")
		end
		TS:Create(skillFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {BackgroundTransparency = 0.1}):Play()
	else
		hasSkill = false
		currentSkill = nil
		skillFrame.Visible = false
		onCooldown = false
		cdOverlay.Visible = false
		cdText.Text = ""
	end
end)

-- ============================================
-- COOLDOWN DISPLAY
-- ============================================
local function startCooldownDisplay()
	cooldownGeneration = cooldownGeneration + 1
	local myGen = cooldownGeneration
	local myCooldown = cooldown  -- Capture at call time so external changes can't affect this loop
	cdOverlay.Visible = true
	cdOverlay.BackgroundTransparency = 0.5
	cdOverlay.Size = UDim2.new(1, 0, 1, 0)
	
	-- Animate the overlay shrinking from top to bottom
	task.spawn(function()
		local startTime = tick()
		while onCooldown and cooldownGeneration == myGen do
			local elapsed = tick() - startTime
			local remaining = math.max(myCooldown - elapsed, 0)
			local fraction = remaining / myCooldown
			
			-- Update countdown text (whole seconds only to avoid flicker)
			local secs = math.ceil(remaining)
			if secs >= 1 then
				cdText.Text = tostring(secs)
			else
				cdText.Text = remaining > 0.1 and "1" or ""
			end
			
			-- Shrink overlay from top
			local clampedFraction = math.max(fraction, 0.02)
			cdOverlay.Size = UDim2.new(1, 0, clampedFraction, 0)
			cdOverlay.Position = UDim2.new(0, 0, 0, 0)
			
			if remaining <= 0 then
				onCooldown = false
				cdOverlay.Visible = false
				cdOverlay.Size = UDim2.new(1, 0, 1, 0)
				cdText.Text = ""
				
				-- Flash ready effect
				TS:Create(skillFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(100, 230, 100)}):Play()
				task.wait(0.12)
				TS:Create(skillFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 30, 60)}):Play()
				
				-- Ready notification (defer so _G.Notify is available; wait briefly if needed)
				local skillName = currentSkill and (currentSkill.Name or "Skill") or "Skill"
				task.defer(function()
					local tries = 0
					while not _G.Notify and tries < 50 do
						task.wait(0.1)
						tries = tries + 1
					end
					if _G.Notify then
						_G.Notify("Ready!", skillName .. " is ready!", 2, "success")
					end
				end)
				break
			end
			
			task.wait(0.1) -- Smooth updates
		end
	end)
end

-- ============================================
-- ACTIVATE ON E PRESS OR BUTTON CLICK
-- ============================================
local function tryActivate()
	if not hasSkill or onCooldown or waitingForServer then return end
	if not ActivateSkill then return end
	
	waitingForServer = true
	ActivateSkill:FireServer()
	task.delay(2, function()
		if waitingForServer then
			waitingForServer = false
		end
	end)
	
	-- Show skill activation notification
	if currentSkill and _G.Notify then
		local notif = SKILL_NOTIFICATIONS[currentSkill.Name]
		if notif then
			_G.Notify(notif.Title, notif.Message, 2, "skill")
		else
			_G.Notify((currentSkill.Name or "Skill") .. "!", "Skill activated!", 2, "skill")
		end
	end
	
end

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.E then
		tryActivate()
	end
end)

-- Mobile support
skillFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryActivate()
	end
end)

-- ============================================
-- NOTIFICATIONS FROM SERVER
-- ============================================
if NotifyClient then
	NotifyClient.OnClientEvent:Connect(function(title, message, duration, ntype)
		if ntype == "warning" then
			waitingForServer = false
		end
		if _G.Notify then
			_G.Notify(title, message, duration, ntype)
		end
	end)
end

-- ============================================
-- ACTIVE TIMER DISPLAY (shows green countdown while skill is active)
-- ============================================
local activeTimerGen = 0

if SkillCooldownStart then
	SkillCooldownStart.OnClientEvent:Connect(function(serverCooldown)
		cooldown = tonumber(serverCooldown) or cooldown
		waitingForServer = false
		-- Cancel any active timer so cooldown overlay takes over
		activeTimerGen = activeTimerGen + 1
		cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		cdOverlay.BackgroundTransparency = 0.5
		cdOverlay.Position = UDim2.new(0, 0, 0, 0)
		cdText.TextColor3 = Color3.new(1, 1, 1)
		onCooldown = true
		lastUsedTime = tick()
		startCooldownDisplay()
	end)
end
local SkillActiveStart = reFolder:WaitForChild("SkillActiveStart", 10)
if SkillActiveStart then
	SkillActiveStart.OnClientEvent:Connect(function(activeDuration, skillId)
		activeDuration = tonumber(activeDuration) or 0
		if activeDuration <= 0 then return end
		activeTimerGen = activeTimerGen + 1
		local myGen = activeTimerGen
		cdOverlay.Visible = true
		cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
		cdOverlay.BackgroundTransparency = 0.45
		cdOverlay.Size = UDim2.new(1, 0, 1, 0)
		cdText.TextColor3 = Color3.fromRGB(200, 255, 200)
		task.spawn(function()
			local startTime = tick()
			while activeTimerGen == myGen do
				local elapsed = tick() - startTime
				local remaining = math.max(activeDuration - elapsed, 0)
				local fraction = math.clamp(remaining / activeDuration, 0, 1)
				-- Show whole seconds only (no decimals = no flicker)
				local secs = math.ceil(remaining)
				if secs >= 1 then
					cdText.Text = secs .. "s"
				else
					cdText.Text = remaining > 0.1 and "1s" or ""
				end
				cdOverlay.Size = UDim2.new(1, 0, math.max(fraction, 0.02), 0)
				cdOverlay.Position = UDim2.new(0, 0, 1 - math.max(fraction, 0.02), 0)
				if remaining <= 0 then
					-- Clean exit: reset overlay for cooldown phase
					cdOverlay.Visible = false
					cdOverlay.Size = UDim2.new(1, 0, 1, 0)
					cdOverlay.Position = UDim2.new(0, 0, 0, 0)
					cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					cdOverlay.BackgroundTransparency = 0.5
					cdText.TextColor3 = Color3.new(1, 1, 1)
					cdText.Text = ""
					break
				end
				task.wait(0.1)
			end
		end)
	end)
end

-- B&W EFFECT handled by SkillEffectsScript.lua (BWEffect remote listener is there)

_G.StopPhaseAfterimage = function()
	phaseActive = false
end

-- ============================================
-- BOMBER TARGET
-- ============================================
_G.GetBomberTarget = nil

print("? Skill Client loaded! Press [E] to use skill")
print("   Skills activate when you equip a trail with a skill")
print("   Cooldown timer displays on skill icon")

-- SKILL RESET LISTENER
local _re = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local _sr = _re:WaitForChild("SkillReset", 10)
if _sr then
	_sr.OnClientEvent:Connect(function()
		-- Reset cooldown
		onCooldown = false
		waitingForServer = false
		lastUsedTime = 0
		-- Reset overlay
		cdOverlay.Visible = false
		cdOverlay.Size = UDim2.new(1, 0, 1, 0)
		cdText.Text = ""
	end)
end
