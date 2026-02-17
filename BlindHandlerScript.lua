local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local reFolder = RS:WaitForChild("RemoteEvents", 15)
local BlindEffect = reFolder and reFolder:WaitForChild("BlindEffect", 10)

-- Create blind overlay
local blindGui = Instance.new("ScreenGui")
blindGui.Name = "BlindOverlay"
blindGui.DisplayOrder = 50
blindGui.ResetOnSpawn = false
blindGui.Parent = player:WaitForChild("PlayerGui")

local blindFrame = Instance.new("Frame")
blindFrame.Name = "BlindFrame"
blindFrame.Size = UDim2.new(1, 0, 1, 0)
blindFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blindFrame.BackgroundTransparency = 1
blindFrame.BorderSizePixel = 0
blindFrame.ZIndex = 100
blindFrame.Parent = blindGui

local blindText = Instance.new("TextLabel")
blindText.Name = "BlindText"
blindText.Size = UDim2.new(1, 0, 0, 40)
blindText.Position = UDim2.new(0, 0, 0.4, 0)
blindText.BackgroundTransparency = 1
blindText.Text = ""
blindText.TextSize = 20
blindText.Font = Enum.Font.GothamBold
blindText.TextColor3 = Color3.fromRGB(200, 50, 50)
blindText.TextStrokeTransparency = 0
blindText.ZIndex = 101
blindText.Parent = blindFrame

if BlindEffect then
	BlindEffect.OnClientEvent:Connect(function(active, duration, blindType, attackerName)
		if active then
			blindText.Text = ""
			if blindType == "shadow" then
				blindFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 20)
				blindText.Text = "?? SHADOWED by " .. (attackerName or "???")
				blindText.TextColor3 = Color3.fromRGB(150, 50, 200)
			elseif blindType == "solar" then
				blindFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
				blindText.Text = "?? SOLAR FLASH by " .. (attackerName or "???")
				blindText.TextColor3 = Color3.fromRGB(255, 200, 50)
			elseif blindType == "void" then
				blindFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				blindText.Text = "??? VOID BLINDED by " .. (attackerName or "???")
				blindText.TextColor3 = Color3.fromRGB(100, 0, 150)
			end
			-- Fade in
			TS:Create(blindFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.02}):Play()
			-- Auto fade out
			task.delay(duration or 2, function()
				TS:Create(blindFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
				task.wait(0.5)
				blindText.Text = ""
			end)
		else
			TS:Create(blindFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
			blindText.Text = ""
		end
	end)
end

print("? Blind Effect handler loaded")
