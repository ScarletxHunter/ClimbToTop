-- ============================================
-- FIXED TRANSITION GUI SCRIPT
-- Place in: StarterGui/TransitionGui/LocalScript
-- ============================================

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gui = script.Parent
local mainContainer = gui:WaitForChild("MainContainer")
local blackScreen = mainContainer:WaitForChild("BlackScreen")
local centerContainer = mainContainer:WaitForChild("CenterContainer")
local loadingIcon = mainContainer:WaitForChild("LoadingIcon")
local innerCircle = loadingIcon:WaitForChild("InnerCircle")
local loadingText = centerContainer:WaitForChild("LoadingText")
local progressBar = centerContainer:WaitForChild("ProgressBar")
local progressFill = progressBar:WaitForChild("Fill")
local tipText = centerContainer:WaitForChild("TipText")

print("?? TransitionGui script starting...")

-- START HIDDEN - Only show when transition is triggered
mainContainer.Visible = false

local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEventsFolder then
	warn("?? RemoteEvents not found!")
	return
end

local TransitionEvent = RemoteEventsFolder:WaitForChild("TransitionEvent", 10)
if not TransitionEvent then
	warn("?? TransitionEvent not found!")
	return
end

print("? Found TransitionEvent")

local tips = {
	"TIP: Collect coins to unlock tools!",
	"TIP: Watch out for falling objects!",
	"TIP: Top 3 finishers get bonus coins!",
	"TIP: Use the shop during intermission!",
	"TIP: Each map has unique obstacles!",
}

local currentTipIndex = 1
local loadingAnimActive = false
local spinTween = nil

-- Animate loading icon (spin)
local function animateLoadingIcon()
	if spinTween then spinTween:Cancel() end

	spinTween = TweenService:Create(
		loadingIcon,
		TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{Rotation = 360}
	)
	spinTween:Play()
end

-- Stop loading icon
local function stopLoadingIcon()
	if spinTween then
		spinTween:Cancel()
		spinTween = nil
	end
	loadingIcon.Rotation = 0
end

-- Animate loading text
local function animateLoadingText()
	loadingAnimActive = true
	task.spawn(function()
		local dots = 0
		while loadingAnimActive do
			dots = (dots % 3) + 1
			loadingText.Text = "LOADING" .. string.rep(".", dots)
			task.wait(0.5)
		end
		loadingText.Text = "LOADING"
	end)
end

-- Stop loading text animation
local function stopLoadingText()
	loadingAnimActive = false
	loadingText.Text = "LOADING"
end

-- Cycle tips
local function cycleTips()
	task.spawn(function()
		while loadingAnimActive do
			TweenService:Create(tipText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
			task.wait(0.6)

			currentTipIndex = currentTipIndex % #tips + 1
			tipText.Text = tips[currentTipIndex]

			TweenService:Create(tipText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
			task.wait(3)
		end
	end)
end

-- Update progress bar
local function updateProgress(percent)
	TweenService:Create(
		progressFill,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		{Size = UDim2.new(percent / 100, 0, 1, 0)}
	):Play()
end

-- Show all loading elements
local function showLoadingElements()
	-- Make everything visible instantly
	TweenService:Create(loadingIcon, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	TweenService:Create(innerCircle, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()

	local iconStroke = loadingIcon:FindFirstChild("UIStroke")
	if iconStroke then
		TweenService:Create(iconStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
	end

	TweenService:Create(loadingText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	TweenService:Create(progressBar, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	TweenService:Create(progressFill, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	TweenService:Create(tipText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

	local barStroke = progressBar:FindFirstChild("UIStroke")
	if barStroke then
		TweenService:Create(barStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
	end
end

-- Hide all loading elements
local function hideLoadingElements()
	-- Make everything invisible
	TweenService:Create(loadingIcon, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(innerCircle, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()

	local iconStroke = loadingIcon:FindFirstChild("UIStroke")
	if iconStroke then
		TweenService:Create(iconStroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
	end

	TweenService:Create(loadingText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(progressBar, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(progressFill, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(tipText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()

	local barStroke = progressBar:FindFirstChild("UIStroke")
	if barStroke then
		TweenService:Create(barStroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
	end
end

-- Fade to black
local function fadeIn(duration)
	duration = duration or 1.5
	print("?? CLIENT: Fading to black...")

	-- Show container
	mainContainer.Visible = true

	-- Fade black screen in
	blackScreen.BackgroundTransparency = 1
	TweenService:Create(blackScreen, TweenInfo.new(duration), {BackgroundTransparency = 0}):Play()

	task.wait(duration)

	-- Now show loading elements
	showLoadingElements()

	-- Start animations
	animateLoadingIcon()
	animateLoadingText()
	cycleTips()

	-- Simulate loading progress
	for i = 0, 100, 5 do
		updateProgress(i)
		task.wait(0.1)
	end

	print("? Faded to black complete")
end

-- Fade from black
local function fadeOut(duration)
	duration = duration or 1.5
	print("?? CLIENT: Fading from black...")

	-- Stop animations first
	stopLoadingText()
	stopLoadingIcon()

	-- Hide loading elements
	hideLoadingElements()

	task.wait(0.6)

	-- Fade black screen out
	TweenService:Create(blackScreen, TweenInfo.new(duration), {BackgroundTransparency = 1}):Play()

	task.wait(duration)

	-- Hide container completely
	mainContainer.Visible = false

	-- Reset progress
	updateProgress(0)

	print("? Faded from black complete")
end

-- Listen for transition events
TransitionEvent.OnClientEvent:Connect(function(action, duration)
	print("?? Transition event:", action, "Duration:", duration)

	if action == "FadeIn" then
		fadeIn(duration)
	elseif action == "FadeOut" then
		fadeOut(duration)
	end
end)

print("? Transition GUI loaded (hidden until triggered)")