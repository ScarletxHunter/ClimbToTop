-- ============================================
-- WIN DISPLAY GUI - Shows winner to everyone
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local winDisplayGui = script.Parent
local card = winDisplayGui:WaitForChild("WinCard")
local faceImage = card:WaitForChild("FaceImage")
local winnerNameLabel = card:WaitForChild("WinnerName")
local timeLabel = card:WaitForChild("TimeLabel")
local crown = card:WaitForChild("Crown")

local WinDisplayEvent = ReplicatedStorage:WaitForChild("WinDisplayEvent", 10)
if not WinDisplayEvent then warn("? WinDisplayEvent not found") return end

local ORIGINAL_SIZE = card.Size

WinDisplayEvent.OnClientEvent:Connect(function(winnerName, winnerUserId, timeTaken)
	-- Set headshot
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size150x150
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(winnerUserId, thumbType, thumbSize)
	end)
	if ok and content then
		faceImage.Image = content
	end

	winnerNameLabel.Text = winnerName
	timeLabel.Text = "?? Time: " .. tostring(timeTaken) .. "s"

	-- Animate in
	card.Size = UDim2.new(0, 0, 0, 0)
	card.Visible = true
	TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = ORIGINAL_SIZE
	}):Play()

	-- Crown bounce
	task.spawn(function()
		for i = 1, 3 do
			TweenService:Create(crown, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
				Position = UDim2.new(0.5, -27, 0, -35)
			}):Play()
			task.wait(0.3)
			TweenService:Create(crown, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
				Position = UDim2.new(0.5, -27, 0, -28)
			}):Play()
			task.wait(0.3)
		end
	end)

	-- Sparkle animation
	for _, child in ipairs(card:GetChildren()) do
		if child.Name:match("^Sparkle") then
			task.spawn(function()
				for _ = 1, 5 do
					TweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
						TextTransparency = 0.2, Rotation = child.Rotation + 60
					}):Play()
					task.wait(0.4)
					TweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
						TextTransparency = 0.7, Rotation = child.Rotation + 60
					}):Play()
					task.wait(0.4)
				end
			end)
		end
	end

	-- Auto hide after 6 seconds
	task.delay(6, function()
		TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()
		task.delay(0.41, function() card.Visible = false end)
	end)
end)

print("? Win Display GUI loaded")