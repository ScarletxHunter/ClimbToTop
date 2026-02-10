-- ============================================
-- WIN GUI (Shows when YOU finish the race)
-- Place in: StarterGui/WinGui/LocalScript
-- ============================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent

gui.Enabled = true
gui.ResetOnSpawn = false

print("?? Win GUI loading...")

local container = gui:WaitForChild("Container", 10)
if not container then
	warn("? Container not found in WinGui!")
	return
end

local titleLabel = container:WaitForChild("Title", 5)
local messageLabel = container:WaitForChild("Message", 5)

container.Visible = false

local originalSize = container.Size
local originalPosition = container.Position

print("? Win GUI loaded - Container found")

-- ============================================
-- SHOW WIN NOTIFICATION
-- ============================================

local isShowing = false

local function showWin(position, reward)
	if isShowing then return end
	isShowing = true

	print("?? SHOWING WIN GUI! Position:", position, "Reward:", reward)

	if titleLabel then
		if position and position ~= "" then
			local posStr = tostring(position)
			if posStr == "1st" or posStr == "1" then
				titleLabel.Text = "?? YOU WON! ??"
				titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			elseif posStr == "2nd" or posStr == "2" then
				titleLabel.Text = "?? 2ND PLACE!"
				titleLabel.TextColor3 = Color3.fromRGB(192, 192, 192)
			elseif posStr == "3rd" or posStr == "3" then
				titleLabel.Text = "?? 3RD PLACE!"
				titleLabel.TextColor3 = Color3.fromRGB(205, 127, 50)
			else
				titleLabel.Text = "? " .. tostring(position) .. " PLACE!"
				titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
			end
		else
			titleLabel.Text = "? ROUND OVER!"
			titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		end
	end

	if messageLabel then
		if position and position ~= "" and reward and reward > 0 then
			messageLabel.Text = tostring(position) .. " Place • +" .. tostring(reward) .. " Coins!"
		elseif reward and reward > 0 then
			messageLabel.Text = "+" .. tostring(reward) .. " Coins!"
		else
			messageLabel.Text = "Thanks for playing!"
		end
	end

	container.Visible = true
	container.Size = UDim2.new(0, 0, 0, 0)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(container,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = originalSize, Position = originalPosition}
	):Play()

	task.delay(5, function()
		TweenService:Create(container,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}
		):Play()

		task.delay(0.35, function()
			container.Visible = false
			isShowing = false
		end)
	end)
end

-- ============================================
-- LISTEN FOR ShowWin REMOTE
-- ============================================

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if remoteEvents then
	local showWinEvent = remoteEvents:WaitForChild("ShowWin", 10)
	if showWinEvent then
		showWinEvent.OnClientEvent:Connect(function(position, reward)
			print("?? Received ShowWin! Position:", position, "Reward:", reward)
			showWin(position, reward)
		end)
		print("? Listening for ShowWin remote")
	else
		warn("?? ShowWin RemoteEvent not found")
	end
else
	warn("?? RemoteEvents folder not found")
end

-- ============================================
-- FALLBACK: Watch leaderstats
-- ============================================

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then return end

	local wins = leaderstats:WaitForChild("Wins", 5)
	if wins then
		local lastWins = wins.Value

		wins:GetPropertyChangedSignal("Value"):Connect(function()
			if wins.Value > lastWins then
				if not isShowing then
					print("?? Wins changed (fallback), showing win GUI")
					showWin(1, 0)
				end
				lastWins = wins.Value
			end
		end)
		print("? Leaderstats fallback connected")
	end
end)

print("? Win GUI ready")