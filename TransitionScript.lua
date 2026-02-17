-- ============================================
-- TRANSITION GUI - LocalScript (FIXED: ensures visibility + ZIndex)
-- ============================================

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local transitionGui = script.Parent
local blackScreen = transitionGui:WaitForChild("BlackScreen")
local loadingText = blackScreen:WaitForChild("LoadingText")
local textStroke = loadingText:WaitForChild("TextStroke")
local spinner = blackScreen:WaitForChild("Spinner")

-- ============================================
-- FIX: Ensure BlackScreen covers EVERYTHING
-- ============================================

-- Force the GUI to be on top of everything
transitionGui.DisplayOrder = 999
transitionGui.IgnoreGuiInset = true
transitionGui.ResetOnSpawn = false
transitionGui.Enabled = true
transitionGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Force BlackScreen to fill entire screen
blackScreen.Size = UDim2.new(1, 0, 1, 0)
blackScreen.Position = UDim2.new(0, 0, 0, 0)
blackScreen.AnchorPoint = Vector2.new(0, 0)
blackScreen.BorderSizePixel = 0
blackScreen.ZIndex = 100

-- Start invisible
blackScreen.BackgroundTransparency = 1
loadingText.TextTransparency = 1
textStroke.Transparency = 1

-- Fix ZIndex on children so they show on top of BlackScreen
loadingText.ZIndex = 101
spinner.ZIndex = 101

-- ============================================
-- REMOTE
-- ============================================

local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local TransitionEvent = RemoteEventsFolder:WaitForChild("TransitionEvent", 10)
if not TransitionEvent then warn("? TransitionEvent not found!") return end

-- ============================================
-- SOUND (play via local SFX)
-- ============================================

local function playTransitionSound()
	local SoundService = game:GetService("SoundService")
	local sfxFolder = SoundService:FindFirstChild("LocalSFX")
	if sfxFolder then
		local snd = sfxFolder:FindFirstChild("Transition")
		if snd then snd:Play() end
	end
end

-- ============================================
-- COLLECT CIRCLES AND SPINNER DOTS
-- ============================================

local circles = {}
for _, child in ipairs(blackScreen:GetChildren()) do
	if child:IsA("Frame") and child.Name:match("^Circle") then
		table.insert(circles, child)
		child.ZIndex = 101
		child.BackgroundTransparency = 1 -- Start hidden
	end
end

local spinDots = {}
for _, child in ipairs(spinner:GetChildren()) do
	if child:IsA("Frame") and child.Name:match("^SpinDot") then
		table.insert(spinDots, child)
		child.ZIndex = 102
	end
end

-- ============================================
-- SPINNER ANIMATION
-- ============================================

local spinnerRunning = false

local function startSpinner()
	spinnerRunning = true
	task.spawn(function()
		while spinnerRunning do
			for i, dot in ipairs(spinDots) do
				TweenService:Create(dot, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
					BackgroundTransparency = 0, Size = UDim2.new(0, 14, 0, 14)
				}):Play()
				task.wait(0.2)
				TweenService:Create(dot, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
					BackgroundTransparency = 0.6, Size = UDim2.new(0, 10, 0, 10)
				}):Play()
			end
			task.wait(0.3)
		end
	end)
end

local function stopSpinner()
	spinnerRunning = false
	for _, dot in ipairs(spinDots) do
		TweenService:Create(dot, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	end
	task.delay(0.5, function()
		for _, dot in ipairs(spinDots) do
			dot.BackgroundTransparency = 1
			dot.Visible = false
		end
		spinner.Visible = false
	end)
end

-- ============================================
-- FADE IN (screen goes BLACK)
-- ============================================

local isFading = false

local function fadeIn(duration)
	duration = duration or 0.8
	if isFading then return end
	isFading = true

	print("?? TRANSITION: Fading to black...")

	playTransitionSound()

	-- Hide core GUIs
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)

	-- Make sure blackscreen is set up
	blackScreen.Visible = true
	blackScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

	-- Tween to fully opaque
	local bgTween = TweenService:Create(blackScreen, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
		BackgroundTransparency = 0
	})
	bgTween:Play()

	-- Show loading text
	TweenService:Create(loadingText, TweenInfo.new(duration), { TextTransparency = 0 }):Play()
	TweenService:Create(textStroke, TweenInfo.new(duration), { Transparency = 0 }):Play()

	-- Show circles
	for _, circle in ipairs(circles) do
		TweenService:Create(circle, TweenInfo.new(duration), { BackgroundTransparency = 0.5 }):Play()
	end

	-- Start spinner dots
	startSpinner()

	bgTween.Completed:Wait()
	isFading = false
	print("?? TRANSITION: Fully black")
end

-- ============================================
-- FADE OUT (screen goes CLEAR)
-- ============================================

local function fadeOut(duration)
	duration = duration or 0.8
	if isFading then return end
	isFading = true

	print("?? TRANSITION: Fading from black...")

	stopSpinner()

	-- Hide text first
	TweenService:Create(loadingText, TweenInfo.new(duration * 0.4), { TextTransparency = 1 }):Play()
	TweenService:Create(textStroke, TweenInfo.new(duration * 0.4), { Transparency = 1 }):Play()
	task.wait(duration * 0.3)

	-- Fade screen away
	local bgTween = TweenService:Create(blackScreen, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	})
	bgTween:Play()

	-- Hide circles
	for _, circle in ipairs(circles) do
		TweenService:Create(circle, TweenInfo.new(duration), { BackgroundTransparency = 1 }):Play()
	end

	bgTween.Completed:Wait()

	-- Restore core GUIs
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)

	isFading = false
	print("?? TRANSITION: Fully clear")
end

-- ============================================
-- LISTEN FOR SERVER EVENTS
-- ============================================

TransitionEvent.OnClientEvent:Connect(function(action, duration)
	print("?? Transition received:", action, "duration:", duration)

	if action == "FadeIn" then
		fadeIn(duration)
	elseif action == "FadeOut" then
		fadeOut(duration)
	elseif action == "Quick" then
		fadeIn(0.3)
		task.wait(0.5)
		fadeOut(0.5)
	end
end)

-- Initial fade out (in case screen starts black from loading)
task.wait(0.5)
fadeOut(1)

print("? Transition GUI loaded (DisplayOrder: 999, ZIndex: 100)")