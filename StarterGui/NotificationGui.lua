-- ============================================
-- NOTIFICATION HANDLER (Clean & Fixed)
-- Place in: StarterGui/NotificationGui/LocalScript
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local container = gui:WaitForChild("Container")

print("?? Notification Handler loading...")

-- ============================================
-- CREATE NOTIFICATION
-- ============================================

local function showNotification(message, isSuccess, icon)
	print("?? Creating notification:", message)

	-- Main notification frame
	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.Size = UDim2.new(0, 420, 0, 80)
	notif.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
	notif.BorderSizePixel = 0
	notif.ZIndex = 100
	notif.Parent = container

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 12)
	notifCorner.Parent = notif

	-- Colored left accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 6, 1, 0)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = isSuccess and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 80, 80)
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 101
	accentBar.Parent = notif

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 12)
	accentCorner.Parent = accentBar

	-- Cover to make accent flat on right side
	local accentCover = Instance.new("Frame")
	accentCover.Size = UDim2.new(1, 0, 1, 0)
	accentCover.Position = UDim2.new(0.5, 0, 0, 0)
	accentCover.BackgroundColor3 = accentBar.BackgroundColor3
	accentCover.BorderSizePixel = 0
	accentCover.ZIndex = 101
	accentCover.Parent = accentBar

	-- Outer glow/stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = isSuccess and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(255, 100, 100)
	stroke.Thickness = 2
	stroke.Transparency = 0.6
	stroke.Parent = notif

	-- Background gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 35, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 20, 40))
	})
	gradient.Rotation = 90
	gradient.Parent = notif

	-- Icon circle background
	local iconBg = Instance.new("Frame")
	iconBg.Name = "IconBg"
	iconBg.Size = UDim2.new(0, 50, 0, 50)
	iconBg.Position = UDim2.new(0, 20, 0.5, -25)
	iconBg.BackgroundColor3 = isSuccess and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(255, 80, 80)
	iconBg.BorderSizePixel = 0
	iconBg.ZIndex = 102
	iconBg.Parent = notif

	local iconBgCorner = Instance.new("UICorner")
	iconBgCorner.CornerRadius = UDim.new(0.25, 0)
	iconBgCorner.Parent = iconBg

	-- Icon text
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "IconLabel"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon or (isSuccess and "?" or "?")
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	iconLabel.TextSize = 28
	iconLabel.ZIndex = 103
	iconLabel.Parent = iconBg

	-- Message text
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(1, -90, 1, 0)
	messageLabel.Position = UDim2.new(0, 80, 0, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.Font = Enum.Font.GothamBold
	messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	messageLabel.TextSize = 15
	messageLabel.TextWrapped = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Center
	messageLabel.ZIndex = 102
	messageLabel.Parent = notif

	print("? Notification frame created!")

	-- Slide in from right
	notif.Position = UDim2.new(0, 450, 0, 0)
	local slideIn = TweenService:Create(
		notif,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0, 0, 0, 0)}
	)
	slideIn:Play()

	-- Icon pop animation
	iconBg.Size = UDim2.new(0, 0, 0, 0)
	local iconPop = TweenService:Create(
		iconBg,
		TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 50, 0, 50)}
	)

	-- Start icon animation after slide starts
	task.delay(0.2, function()
		iconPop:Play()
	end)

	print("?? Animations playing")

	-- Remove after 4 seconds
	task.delay(4, function()
		print("??? Removing notification")

		-- Slide out to right
		local slideOut = TweenService:Create(
			notif,
			TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{Position = UDim2.new(0, 450, 0, 0)}
		)
		slideOut:Play()

		-- Wait for animation to finish
		slideOut.Completed:Wait()
		notif:Destroy()
		print("? Notification removed")
	end)
end

-- ============================================
-- CONNECT TO SERVER EVENTS
-- ============================================

task.spawn(function()
	print("? Waiting for RemoteEvents...")

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 30)
	if not remoteEvents then
		warn("? RemoteEvents not found!")
		return
	end

	print("? Found RemoteEvents")

	-- Get or create NotifyPurchase event
	local notifyPurchase = remoteEvents:FindFirstChild("NotifyPurchase")
	if not notifyPurchase then
		print("?? NotifyPurchase not found, creating...")
		notifyPurchase = Instance.new("RemoteEvent")
		notifyPurchase.Name = "NotifyPurchase"
		notifyPurchase.Parent = remoteEvents
		print("? Created NotifyPurchase")
	end

	-- Listen for notifications from server
	notifyPurchase.OnClientEvent:Connect(function(itemName, success, icon)
		print("?? NOTIFICATION RECEIVED!")
		print("   Item:", itemName)
		print("   Success:", success)
		print("   Icon:", icon)

		if success then
			showNotification("?? " .. itemName .. " purchased!", true, icon)
		else
			showNotification("? " .. itemName .. " purchase failed", false, "?")
		end
	end)

	print("? Notification system ready!")
end)

-- ============================================
-- GLOBAL FUNCTION (for manual use)
-- ============================================

_G.ShowNotification = showNotification

-- Test notification after 3 seconds
task.delay(3, function()
	print("?? Testing notification...")
	showNotification("Welcome! TO CLIMB THE HILL! ??", true, "?")
end)

print("? Notification Handler loaded!")