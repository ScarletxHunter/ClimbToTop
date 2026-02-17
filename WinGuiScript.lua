-- ============================================
-- WIN GUI - Personal win notification
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local winGui = script.Parent
local frame = winGui:WaitForChild("Frame")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local WinEvent = RemoteEvents:WaitForChild("PlayerWon")

local ORIGINAL_SIZE = frame.Size

WinEvent.OnClientEvent:Connect(function()
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Visible = true

	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = ORIGINAL_SIZE
	}):Play()

	task.delay(5, function()
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()
		task.delay(0.31, function() frame.Visible = false end)
	end)
end)

print("? Win GUI loaded")