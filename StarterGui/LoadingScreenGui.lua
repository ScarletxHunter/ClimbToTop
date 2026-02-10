-- ============================================
-- LOADING SCREEN SCRIPT (Uses Studio-built elements)
-- Place in: StarterGui/LoadingScreenGui/LocalScript
-- ============================================

local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local gui = script.Parent

local LOADING_DURATION = 3

print("?? Loading Screen starting...")

-- Hide hotbar
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)
print("?? Hotbar hidden during loading")

-- ============================================
-- FIND YOUR STUDIO ELEMENTS
-- ============================================
local mainFrame = gui:WaitForChild("MainFrame", 5)
if not mainFrame then
	warn("? MainFrame not found!")
	gui.Enabled = false
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
	return
end

local logoLabel = mainFrame:FindFirstChild("LogoLabel")
local loadingText = mainFrame:FindFirstChild("LoadingText")
local statusText = mainFrame:FindFirstChild("StatusText")
local progressBar = mainFrame:FindFirstChild("ProgressBar")
local progressFill = progressBar and progressBar:FindFirstChild("ProgressFill")
local spinnerContainer = mainFrame:FindFirstChild("SpinnerContainer")
local outerCircle = spinnerContainer and spinnerContainer:FindFirstChild("OuterCircle")
local outerStroke = outerCircle and outerCircle:FindFirstChild("OuterStroke")
local innerCircle = outerCircle and outerCircle:FindFirstChild("InnerCircle")
local progressStroke = progressBar and progressBar:FindFirstChild("ProgressStroke")

print("? Loading screen elements found")

-- ============================================
-- SPINNER PULSE ANIMATION
-- ============================================
local spinnerActive = true

local function animateSpinner()
	if not outerCircle then return end
	task.spawn(function()
		while spinnerActive do
			TweenService:Create(outerCircle,
				TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{BackgroundColor3 = Color3.fromRGB(0, 200, 255)}
			):Play()
			if outerStroke then
				TweenService:Create(outerStroke,
					TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Transparency = 0}
				):Play()
			end
			task.wait(0.8)
			if not spinnerActive then break end

			TweenService:Create(outerCircle,
				TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{BackgroundColor3 = Color3.fromRGB(0, 130, 220)}
			):Play()
			if outerStroke then
				TweenService:Create(outerStroke,
					TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Transparency = 0.5}
				):Play()
			end
			task.wait(0.8)
		end
	end)
end

-- ============================================
-- LOADING DOTS ANIMATION
-- ============================================
local loadingActive = true

local function animateLoadingText()
	if not loadingText then return end
	task.spawn(function()
		local dots = {".", "..", "..."}
		local i = 1
		while loadingActive do
			loadingText.Text = "LOADING" .. dots[i]
			i = (i % 3) + 1
			task.wait(0.4)
		end
	end)
end

-- ============================================
-- HIDE LOADING SCREEN
-- ============================================
local function hideLoadingScreen()
	print("?? Hiding loading screen...")
	loadingActive = false
	spinnerActive = false

	local fadeTime = 0.5
	local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Fade out everything
	TweenService:Create(mainFrame, fadeInfo, {BackgroundTransparency = 1}):Play()

	if logoLabel then
		if logoLabel:IsA("TextLabel") then
			TweenService:Create(logoLabel, fadeInfo, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		elseif logoLabel:IsA("ImageLabel") then
			TweenService:Create(logoLabel, fadeInfo, {ImageTransparency = 1}):Play()
		end
	end
	if loadingText then
		TweenService:Create(loadingText, fadeInfo, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end
	if statusText then
		TweenService:Create(statusText, fadeInfo, {TextTransparency = 1}):Play()
	end
	if progressBar then
		TweenService:Create(progressBar, fadeInfo, {BackgroundTransparency = 1}):Play()
	end
	if progressFill then
		TweenService:Create(progressFill, fadeInfo, {BackgroundTransparency = 1}):Play()
	end
	if outerCircle then
		TweenService:Create(outerCircle, fadeInfo, {BackgroundTransparency = 1}):Play()
	end
	if innerCircle then
		TweenService:Create(innerCircle, fadeInfo, {BackgroundTransparency = 1}):Play()
	end
	if outerStroke then
		TweenService:Create(outerStroke, fadeInfo, {Transparency = 1}):Play()
	end
	if progressStroke then
		TweenService:Create(progressStroke, fadeInfo, {Transparency = 1}):Play()
	end

	-- Fade any extra elements you added
	for _, child in pairs(mainFrame:GetDescendants()) do
		pcall(function()
			if child:IsA("Frame") then
				TweenService:Create(child, fadeInfo, {BackgroundTransparency = 1}):Play()
			elseif child:IsA("TextLabel") then
				TweenService:Create(child, fadeInfo, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
			elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
				TweenService:Create(child, fadeInfo, {ImageTransparency = 1}):Play()
			end
		end)
	end

	task.wait(fadeTime)

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
	print("?? Hotbar shown after loading")

	gui.Enabled = false
	print("? Loading screen hidden")
end

-- ============================================
-- LOADING SEQUENCE
-- ============================================
local function startLoading()
	print("?? Starting loading sequence...")

	-- Reset progress fill to empty
	if progressFill then
		progressFill.Size = UDim2.new(0, 0, 1, 0)
	end

	animateLoadingText()
	animateSpinner()

	-- Fade in logo
	if logoLabel then
		if logoLabel:IsA("TextLabel") then
			logoLabel.TextTransparency = 1
			logoLabel.TextStrokeTransparency = 1
			TweenService:Create(logoLabel, TweenInfo.new(0.8), {TextTransparency = 0, TextStrokeTransparency = 0.5}):Play()
		elseif logoLabel:IsA("ImageLabel") then
			logoLabel.ImageTransparency = 1
			TweenService:Create(logoLabel, TweenInfo.new(0.8), {ImageTransparency = 0}):Play()
		end
	end

	task.wait(0.3)

	-- Fade in loading text
	if loadingText then
		loadingText.TextTransparency = 1
		TweenService:Create(loadingText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	end

	-- Preload assets
	local assetsToLoad = {}
	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if toolsFolder then
		for _, tool in pairs(toolsFolder:GetDescendants()) do
			if tool:IsA("Texture") or tool:IsA("Decal") then
				table.insert(assetsToLoad, tool)
			end
		end
	end

	if #assetsToLoad > 0 then
		task.spawn(function()
			ContentProvider:PreloadAsync(assetsToLoad)
		end)
	end

	-- Animate progress bar
	if progressFill then
		local totalSteps = 100
		local stepTime = LOADING_DURATION / totalSteps

		for i = 1, totalSteps do
			local progress = i / totalSteps

			TweenService:Create(progressFill,
				TweenInfo.new(stepTime, Enum.EasingStyle.Linear),
				{Size = UDim2.new(progress, 0, 1, 0)}
			):Play()

			if statusText then
				if progress < 0.3 then
					statusText.Text = "Loading assets..."
				elseif progress < 0.6 then
					statusText.Text = "Preparing game..."
				elseif progress < 0.9 then
					statusText.Text = "Almost ready..."
				else
					statusText.Text = "Starting game..."
				end
			end

			task.wait(stepTime)
		end
	else
		task.wait(LOADING_DURATION)
	end

	if statusText then
		statusText.Text = "Ready!"
	end
	print("? Loading complete")

	task.wait(0.3)
	hideLoadingScreen()
end

-- ============================================
-- START
-- ============================================
gui.Enabled = true

if not player.Character then
	player.CharacterAdded:Wait()
end

task.wait(0.1)
startLoading()

print("? Loading Screen script loaded")