-- ============================================
-- TIMER GUI - LocalScript (references pre-built GUI)
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local timerGui = script.Parent
local container = timerGui:WaitForChild("Container")
local stateLabel = container:WaitForChild("StateLabel")
local timerLabel = container:WaitForChild("TimerLabel")
local containerStroke = container:WaitForChild("ContainerStroke")
local containerGradient = container:FindFirstChild("ContainerGradient")
if not containerGradient then
	containerGradient = container:FindFirstChildOfClass("UIGradient")
	if containerGradient and containerGradient.Name ~= "ContainerGradient" then
		containerGradient.Name = "ContainerGradient"
	end
end
if not containerGradient then
	containerGradient = Instance.new("UIGradient")
	containerGradient.Name = "ContainerGradient"
	containerGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 50, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 35, 25)),
	})
	containerGradient.Parent = container
	warn("TimerGuiScript: ContainerGradient missing, created fallback gradient")
end

local GameValues = ReplicatedStorage:WaitForChild("GameValues")
local GameState = GameValues:WaitForChild("GameState")
local Timer = GameValues:WaitForChild("Timer")

local STATE_COLORS = {
	Intermission = Color3.fromRGB(100, 255, 100),
	Voting       = Color3.fromRGB(255, 200, 50),
	Playing      = Color3.fromRGB(50, 255, 100),
	RoundEnd     = Color3.fromRGB(255, 100, 100),
}

local STROKE_COLORS = {
	Intermission = Color3.fromRGB(80, 200, 80),
	Voting       = Color3.fromRGB(200, 160, 40),
	Playing      = Color3.fromRGB(40, 200, 80),
	RoundEnd     = Color3.fromRGB(200, 80, 80),
}

local GRADIENT_COLORS = {
	Intermission = { Color3.fromRGB(25, 50, 35), Color3.fromRGB(20, 35, 25) },
	Voting       = { Color3.fromRGB(60, 50, 20), Color3.fromRGB(40, 35, 15) },
	Playing      = { Color3.fromRGB(20, 55, 30), Color3.fromRGB(15, 40, 20) },
	RoundEnd     = { Color3.fromRGB(60, 25, 25), Color3.fromRGB(40, 15, 15) },
}

local function tweenProp(obj, prop, val, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.5, Enum.EasingStyle.Sine), { [prop] = val }):Play()
end

GameState:GetPropertyChangedSignal("Value"):Connect(function()
	local state = GameState.Value
	stateLabel.Text = string.upper(state)

	tweenProp(stateLabel, "TextColor3", STATE_COLORS[state] or Color3.fromRGB(255, 255, 255))
	tweenProp(containerStroke, "Color", STROKE_COLORS[state] or Color3.fromRGB(100, 80, 180))

	local gc = GRADIENT_COLORS[state]
	if gc then
		containerGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, gc[1]),
			ColorSequenceKeypoint.new(1, gc[2]),
		})
	end

	-- Pop animation
	TweenService:Create(container, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 220, 0, 88)
	}):Play()
	task.delay(0.15, function()
		TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
			Size = UDim2.new(0, 200, 0, 80)
		}):Play()
	end)
end)

Timer:GetPropertyChangedSignal("Value"):Connect(function()
	local t = Timer.Value
	timerLabel.Text = string.format("%02d:%02d", math.floor(t / 60), t % 60)

	if t <= 5 then
		tweenProp(timerLabel, "TextColor3", Color3.fromRGB(255, 50, 50), 0.2)
	elseif t <= 15 then
		tweenProp(timerLabel, "TextColor3", Color3.fromRGB(255, 200, 0), 0.3)
	else
		tweenProp(timerLabel, "TextColor3", Color3.fromRGB(255, 255, 255), 0.3)
	end
end)

timerLabel.Text = string.format("%02d:%02d", math.floor(Timer.Value / 60), Timer.Value % 60)
stateLabel.Text = string.upper(GameState.Value)
print("? Timer GUI loaded")