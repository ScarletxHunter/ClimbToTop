-- ============================================
-- LOADING SCREEN - FIXED (no spam, full unload)
-- ============================================

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

pcall(function() ReplicatedFirst:RemoveDefaultLoadingScreen() end)
if not game:IsLoaded() then game.Loaded:Wait() end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 30)
if not playerGui then return end

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

local MINIMUM_DISPLAY_TIME = 5

-- Clone template ONCE
local templateGui = script.Parent
if not templateGui or not templateGui:IsA("ScreenGui") then return end

-- Prevent multiple clones: check if we already have one
if playerGui:FindFirstChild("LoadingScreenActive") then return end

local loadingScreen = templateGui:Clone()
loadingScreen.Name = "LoadingScreenActive"
loadingScreen.Parent = playerGui
loadingScreen.Enabled = true

-- Kill any duplicates
for _, g in ipairs(playerGui:GetChildren()) do
	if g:IsA("ScreenGui") and g.Name == "LoadingScreenActive" and g ~= loadingScreen then
		g:Destroy()
	end
end

local bg = loadingScreen:FindFirstChild("Background")
if not bg then
	loadingScreen:Destroy()
	return
end

local gameTitle = bg:FindFirstChild("GameTitle")
local barBG = bg:FindFirstChild("LoadingBarBG")
local barFill = barBG and barBG:FindFirstChild("LoadingBarFill")
local loadingText = bg:FindFirstChild("LoadingText")
local tipLabel = bg:FindFirstChild("TipLabel")

if not barFill or not loadingText then
	loadingScreen:Destroy()
	return
end

-- Tips
local TIPS = {
	"?? TIP: Push other players to earn bonus coins!",
	"?? TIP: Be the first to reach the top!",
	"?? TIP: Unlock new trails in the shop!",
	"? TIP: Dodge falling objects!",
	"?? TIP: Trails give you speed boosts!",
	"?? TIP: Higher placement = More coins!",
	"? TIP: VIP players earn double coins!",
	"?? TIP: Robux trails last forever!",
}
if tipLabel then
	tipLabel.Text = TIPS[math.random(1, #TIPS)]
end

local startTime = tick()
local finished = false

-- Title bounce
if gameTitle then
	task.spawn(function()
		while not finished and gameTitle and gameTitle.Parent do
			TweenService:Create(gameTitle, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0.1, 0, 0.18, 0)
			}):Play()
			task.wait(0.8)
			if finished then break end
			TweenService:Create(gameTitle, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0.1, 0, 0.22, 0)
			}):Play()
			task.wait(0.8)
		end
	end)
end

-- Progress bar (single loop, no branching)
task.spawn(function()
	for i = 0, 100 do
		if finished then return end
		if not loadingScreen or not loadingScreen.Parent then return end
		if barFill and barFill.Parent then
			barFill.Size = UDim2.new(i / 100, 0, 1, 0)
		end
		if loadingText and loadingText.Parent then
			loadingText.Text = string.format("Loading game... %d%%", i)
		end
		task.wait(0.04)
	end
end)

-- Wait for character
if not player.Character then
	player.CharacterAdded:Wait()
end

local elapsed = tick() - startTime
local remain = MINIMUM_DISPLAY_TIME - elapsed
if remain > 0 then task.wait(remain) end

finished = true
if loadingText and loadingText.Parent then
	loadingText.Text = "? READY!"
end
task.wait(0.5)

-- FULL FADE: hit EVERY GuiObject under the ScreenGui, including bg itself
local fadeInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function fadeObject(obj)
	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		TweenService:Create(obj, fadeInfo, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		pcall(function()
			TweenService:Create(obj, fadeInfo, { TextStrokeTransparency = 1 }):Play()
		end)
	elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		TweenService:Create(obj, fadeInfo, { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
	elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
		TweenService:Create(obj, fadeInfo, { BackgroundTransparency = 1 }):Play()
	end
end

-- Fade background first
fadeObject(bg)

-- Fade ALL descendants
for _, obj in ipairs(loadingScreen:GetDescendants()) do
	fadeObject(obj)
end

-- Also fade any UIStroke
for _, obj in ipairs(loadingScreen:GetDescendants()) do
	if obj:IsA("UIStroke") then
		TweenService:Create(obj, fadeInfo, { Transparency = 1 }):Play()
	end
end

task.wait(1.2)

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)

loadingScreen.Enabled = false
task.wait(0.05)
loadingScreen:Destroy()

print("? Loading screen complete")