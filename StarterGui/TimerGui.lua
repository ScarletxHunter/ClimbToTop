-- ============================================
-- TIMER GUI (FIXED - Uses YOUR MainFrame!)
-- Place in: StarterGui/TimerGui/LocalScript
--
-- FIX: Changed to match YOUR TimerGui structure:
--      MainFrame > PhaseLabel + TimerLabel
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

print("?? Timer GUI loading...")

-- UI Elements (YOUR structure: TimerGui > MainFrame > PhaseLabel + TimerLabel)
local timerGui = script.Parent
local frame = timerGui:WaitForChild("MainFrame")          -- YOUR frame name!
local stateLabel = frame:WaitForChild("PhaseLabel")        -- YOUR label name!
local timerLabel = frame:WaitForChild("TimerLabel")

-- Remote Event (from GameManager)
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local timerEvent = remoteEvents and remoteEvents:WaitForChild("TimerUpdate", 10)

-- ============================================
-- STATE CONFIGURATION
-- ============================================

local STATE_CONFIG = {
	Intermission = {
		Text = "INTERMISSION",
		Color = Color3.fromRGB(80, 150, 255),   -- Blue
		ShowTimer = true,
	},
	Voting = {
		Text = "VOTE NOW!",
		Color = Color3.fromRGB(255, 200, 50),   -- Gold
		ShowTimer = true,
	},
	Round = {
		Text = "ROUND TIME",
		Color = Color3.fromRGB(80, 255, 120),   -- Green
		ShowTimer = true,
	},
	RoundOver = {
		Text = "ROUND OVER!",
		Color = Color3.fromRGB(255, 80, 80),    -- Red
		ShowTimer = false,
	},
}

-- ============================================
-- FORMAT TIME
-- ============================================

local function formatTime(seconds)
	if not seconds or seconds < 0 then seconds = 0 end
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

-- ============================================
-- UPDATE DISPLAY
-- ============================================

local lastState = ""

local function updateTimer(timeValue, state)
	local config = STATE_CONFIG[state]
	if not config then
		-- Unknown state, show raw
		stateLabel.Text = string.upper(tostring(state or ""))
		timerLabel.Text = formatTime(timeValue or 0)
		return
	end

	-- Update state label
	stateLabel.Text = config.Text
	stateLabel.TextColor3 = config.Color

	-- ============================================
	-- "RoundOver" shows "GG!" instead of countdown
	-- ============================================
	if state == "RoundOver" then
		if lastState ~= "RoundOver" then
			-- First frame of RoundOver - pulse effect
			timerLabel.Text = "GG!"
			timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)

			local origSize = timerLabel.TextSize
			TweenService:Create(timerLabel,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{TextSize = origSize + 8}
			):Play()
			task.delay(0.3, function()
				TweenService:Create(timerLabel,
					TweenInfo.new(0.3, Enum.EasingStyle.Sine),
					{TextSize = origSize}
				):Play()
			end)
		else
			timerLabel.Text = "GG!"
		end
	else
		-- Normal timer display
		timerLabel.Text = formatTime(timeValue or 0)

		-- Color based on time remaining (round only)
		if state == "Round" then
			if timeValue and timeValue <= 10 then
				timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)    -- Red urgent!
			elseif timeValue and timeValue <= 30 then
				timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)   -- Yellow warning
			else
				timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White normal
			end
		else
			timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	lastState = state
end

-- ============================================
-- CONNECT TO REMOTE EVENT
-- ============================================

if timerEvent then
	timerEvent.OnClientEvent:Connect(function(timeValue, state)
		updateTimer(timeValue, state)
	end)
	print("? Timer GUI loaded (using MainFrame)")
else
	warn("?? TimerUpdate remote event not found!")
end

-- Initial state
stateLabel.Text = "WAITING..."
timerLabel.Text = "0:00"