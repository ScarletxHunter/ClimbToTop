local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local plr = Players.LocalPlayer
local gui = script.Parent
local panel = gui:WaitForChild("Panel")
local closeBtn = panel:FindFirstChild("CloseBtn", true)
local content = panel:WaitForChild("Content")

-- Close
if closeBtn then
	closeBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)
end

_G.OpenSettings = function()
	panel.Visible = not panel.Visible
end

-- =============================================
-- SLIDER SETUP
-- =============================================
local function setupSlider(rowName, callback)
	local row = content:FindFirstChild(rowName)
	if not row then return end
	local track = row:FindFirstChild("Track")
	if not track then return end
	local fill = track:FindFirstChild("Fill")
	local knob = track:FindFirstChild("Knob")
	local pctLabel = row:FindFirstChild("PctLabel")
	if not fill or not knob then return end

	local dragging = false

	local function update(inputX)
		local trackAbsPos = track.AbsolutePosition.X
		local trackAbsSize = track.AbsoluteSize.X
		if trackAbsSize == 0 then return end
		local pct = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, -9, 0.5, -9)
		if pctLabel then pctLabel.Text = math.floor(pct * 100) .. "%" end
		if callback then callback(pct) end
	end

	knob.MouseButton1Down:Connect(function() dragging = true end)

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input.Position.X)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- =============================================
-- TOGGLE SETUP
-- =============================================
local function setupToggle(rowName, callback)
	local row = content:FindFirstChild(rowName)
	if not row then return end
	local toggleBg = row:FindFirstChild("ToggleBg")
	if not toggleBg then return end
	local dot = toggleBg:FindFirstChild("Dot")
	local stateVal = row:FindFirstChild("State")
	if not dot or not stateVal then return end

	toggleBg.MouseButton1Click:Connect(function()
		stateVal.Value = not stateVal.Value
		local on = stateVal.Value

		TS:Create(toggleBg, TweenInfo.new(0.15), {
			BackgroundColor3 = on and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(60, 50, 80)
		}):Play()
		TS:Create(dot, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
			Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
		}):Play()

		if callback then callback(on) end
	end)
end

-- =============================================
-- DEFAULTS + PERSISTENCE
-- =============================================
_G.SoundVolume = 0.8
_G.ScreenShakeEnabled = true
_G.ParticlesEnabled = true

-- Store original volumes so we can scale proportionally
local originalVolumes = {}

-- Save settings to server via RemoteEvent
local function saveSettings()
	local re = RS:FindFirstChild("RemoteEvents")
	if re then
		local saveSettingsEvent = re:FindFirstChild("SaveSettings")
		if saveSettingsEvent then
			saveSettingsEvent:FireServer(_G.SoundVolume, _G.ScreenShakeEnabled, _G.ParticlesEnabled)
		end
	end
end

-- Collect ALL sounds in the game
local function getAllSounds()
	local sounds = {}
	
	-- BG music in workspace
	local bgm = workspace:FindFirstChild("Sound")
	if bgm and bgm:IsA("Sound") then
		table.insert(sounds, bgm)
	end
	
	-- Sounds in SoundService
	for _, snd in pairs(SoundService:GetDescendants()) do
		if snd:IsA("Sound") then
			table.insert(sounds, snd)
		end
	end
	
	-- Sounds in PlayerGui (ClientSoundHandler)
	local pg = plr:FindFirstChild("PlayerGui")
	if pg then
		for _, snd in pairs(pg:GetDescendants()) do
			if snd:IsA("Sound") then
				table.insert(sounds, snd)
			end
		end
	end
	
	-- Sounds in workspace (other than bg music)
	for _, snd in pairs(workspace:GetDescendants()) do
		if snd:IsA("Sound") then
			table.insert(sounds, snd)
		end
	end
	
	return sounds
end

-- Save originals after a short delay
task.spawn(function()
	task.wait(2)
	for _, snd in pairs(getAllSounds()) do
		if not originalVolumes[snd] then
			originalVolumes[snd] = snd.Volume
		end
	end
end)

-- Load saved settings from player attributes (set by server on join)
task.spawn(function()
	task.wait(3) -- Wait for originals to be saved first
	local savedVol = plr:GetAttribute("Setting_SoundVolume")
	local savedShake = plr:GetAttribute("Setting_ScreenShake")
	local savedParticles = plr:GetAttribute("Setting_Particles")
	if savedVol ~= nil then _G.SoundVolume = savedVol end
	if savedShake ~= nil then _G.ScreenShakeEnabled = savedShake end
	if savedParticles ~= nil then _G.ParticlesEnabled = savedParticles end
	-- Apply loaded volume
	if savedVol then
		for _, snd in pairs(getAllSounds()) do
			if originalVolumes[snd] then
				snd.Volume = originalVolumes[snd] * savedVol
			end
		end
		-- Update slider UI
		local row = content:FindFirstChild("SoundsVolume")
		if row then
			local track = row:FindFirstChild("Track")
			if track then
				local fill = track:FindFirstChild("Fill")
				local knob = track:FindFirstChild("Knob")
				local pctLabel = row:FindFirstChild("PctLabel")
				if fill then fill.Size = UDim2.new(savedVol, 0, 1, 0) end
				if knob then knob.Position = UDim2.new(savedVol, -9, 0.5, -9) end
				if pctLabel then pctLabel.Text = math.floor(savedVol * 100) .. "%" end
			end
		end
	end
	print("? Settings loaded from save:", "Vol=" .. tostring(_G.SoundVolume), "Shake=" .. tostring(_G.ScreenShakeEnabled), "Particles=" .. tostring(_G.ParticlesEnabled))
end)

-- =============================================
-- ?? SOUNDS SLIDER - controls EVERYTHING
-- =============================================
setupSlider("SoundsVolume", function(pct)
	_G.SoundVolume = pct
	for _, snd in pairs(getAllSounds()) do
		if not originalVolumes[snd] then
			originalVolumes[snd] = snd.Volume
		end
		snd.Volume = originalVolumes[snd] * pct
	end
	saveSettings()
end)

-- ?? SCREEN SHAKE
setupToggle("ScreenShake", function(on)
	_G.ScreenShakeEnabled = on
	saveSettings()
end)

-- ? PARTICLES
setupToggle("Particles", function(on)
	_G.ParticlesEnabled = on
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("ParticleEmitter") then
			obj.Enabled = on
		end
	end
	saveSettings()
end)

-- Keep watching for new sounds (bg music changes each round, new SFX)
task.spawn(function()
	while true do
		task.wait(3)
		for _, snd in pairs(getAllSounds()) do
			if not originalVolumes[snd] then
				originalVolumes[snd] = snd.Volume
				-- Apply current volume setting to new sounds
				snd.Volume = originalVolumes[snd] * (_G.SoundVolume or 0.8)
			end
		end
	end
end)

print("? Settings ready!")
print("   ?? Sounds = ALL audio (music + SFX + buttons)")
print("   ?? Screen Shake")
print("   ? Particles")
