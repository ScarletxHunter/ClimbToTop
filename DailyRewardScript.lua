local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

if _G.__DailyRewardClientLoaded then
	warn("DailyRewardScript already loaded, skipping duplicate instance")
	return
end
_G.__DailyRewardClientLoaded = true

local plr = Players.LocalPlayer
local gui = script.Parent
local panel = gui:WaitForChild("Panel")
local closeBtn = panel:WaitForChild("CloseBtn")
local claimBtn = panel:WaitForChild("ClaimBtn")
local streakLabel = panel:WaitForChild("StreakLabel")
local days = panel:WaitForChild("Days")

local onPad = false
local claiming = false
local countdownActive = false
local countdownSeconds = 0
local gameValues = RS:FindFirstChild("GameValues")
local gameState = gameValues and gameValues:FindFirstChild("GameState")
local iconInspectCount = 0

-- #region agent log
local reDbg = RS:WaitForChild("RemoteEvents", 10)
local ClientDebugLog = reDbg and reDbg:FindFirstChild("ClientDebugLog")
local function cdbg(hId, loc, msg, data)
	if ClientDebugLog then
		pcall(function()
			ClientDebugLog:FireServer({
				runId="ui_visibility_debug",
				hypothesisId=hId,
				location=loc,
				message=msg,
				data=data or {},
				timestamp=DateTime.now().UnixTimestampMillis
			})
		end)
	end
end
-- #endregion

-- #region agent log
cdbg("DR_INIT", "DailyRewardScript:init", "Script initialized", {
	panelVisible = panel.Visible,
	gameState = gameState and gameState.Value or "nil",
})
-- #endregion

-- Close
closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
	-- #region agent log
	cdbg("DR_CLOSE", "DailyRewardScript:close", "Panel closed by user", {
		panelVisible = panel.Visible,
	})
	-- #endregion
end)

-- Detect stepping on pad
task.spawn(function()
	-- #region agent log
	local padLogTimer = 0
	-- #endregion
	while true do
		task.wait(0.5)
		local char = plr.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end
		
		local padPart = workspace:FindFirstChild("DailyRewardPad")
		-- #region agent log
		padLogTimer = padLogTimer + 1
		if padLogTimer <= 3 then
			cdbg("H1", "DailyRewardScript:padLoop", "Pad check", {padPartFound=padPart~=nil, padChildFound=padPart and padPart:FindFirstChild("Pad")~=nil or false, hrpPos={hrp.Position.X, hrp.Position.Y, hrp.Position.Z}})
		end
		-- #endregion
		if not padPart then continue end
		local pad = padPart:FindFirstChild("Pad")
		if not pad then continue end

		-- #region agent log
		if iconInspectCount < 8 and (padLogTimer % 2 == 0) then
			iconInspectCount = iconInspectCount + 1
			local dailyIcon = padPart:FindFirstChild("DailyIcon")
			local imageLabel = dailyIcon and dailyIcon:FindFirstChildWhichIsA("ImageLabel")
			local payload = {
				padModelFound = true,
				dailyIconFound = dailyIcon ~= nil,
				dailyIconClass = dailyIcon and dailyIcon.ClassName or "nil",
				distToPad = math.floor((hrp.Position - pad.Position).Magnitude * 100) / 100,
				gameState = gameState and gameState.Value or "nil",
			}
			if dailyIcon and dailyIcon:IsA("BillboardGui") then
				payload.billboardSize = tostring(dailyIcon.Size)
				payload.studsOffset = tostring(dailyIcon.StudsOffset)
				payload.maxDistance = dailyIcon.MaxDistance
				payload.alwaysOnTop = dailyIcon.AlwaysOnTop
				payload.currentDistance = dailyIcon.CurrentDistance
			elseif dailyIcon and dailyIcon:IsA("SurfaceGui") then
				payload.surfaceSizingMode = tostring(dailyIcon.SizingMode)
				payload.pixelsPerStud = dailyIcon.PixelsPerStud
				payload.canvasSize = tostring(dailyIcon.CanvasSize)
			end
			if imageLabel then
				payload.imageLabelSize = tostring(imageLabel.Size)
				payload.imageLabelScaleType = tostring(imageLabel.ScaleType)
			end
			cdbg("DR_ICON", "DailyRewardScript:padLoop", "DailyIcon runtime snapshot", payload)
		end
		-- #endregion
		
		local dist = (hrp.Position - pad.Position).Magnitude
		if dist < 7 and not onPad then
			onPad = true
			-- #region agent log
			cdbg("DR_PAD", "DailyRewardScript:padLoop", "ON PAD - requesting data", {
				dist=dist,
				gameState = gameState and gameState.Value or "nil",
			})
			-- #endregion
			-- Request daily reward data from server
			local re = RS:FindFirstChild("RemoteEvents")
			if re then
				local getDR = re:FindFirstChild("GetDailyReward")
				if getDR then
					local data = getDR:InvokeServer()
					-- #region agent log
					cdbg("DR_PAD", "DailyRewardScript:padLoop", "Got data from server", {
						dataReceived=data~=nil,
						currentDay=data and data.CurrentDay or "nil",
						claimed=data and data.ClaimedToday or "nil",
					})
					-- #endregion
					if data then
						updateUI(data)
						panel.Visible = true
						-- #region agent log
						cdbg("DR_VIS", "DailyRewardScript:padLoop", "Panel set visible", {
							panelVisible = panel.Visible,
							dist = dist,
							gameState = gameState and gameState.Value or "nil",
						})
						-- #endregion
					end
				end
			end
		elseif dist >= 10 then
			onPad = false
			panel.Visible = false
			-- #region agent log
			cdbg("DR_VIS", "DailyRewardScript:padLoop", "Panel hidden (left pad area)", {
				panelVisible = panel.Visible,
				dist = dist,
				gameState = gameState and gameState.Value or "nil",
			})
			-- #endregion
		end
	end
end)

local function formatTime(secs)
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

function updateUI(data)
	local currentDay = data.CurrentDay or 1
	local claimed = data.ClaimedToday or false
	local streak = data.Streak or 1
	
	streakLabel.Text = "Streak: Day " .. streak
	
	for i = 1, 7 do
		local box = days:FindFirstChild("Day" .. i)
		if not box then continue end
		local check = box:FindFirstChild("Checkmark")
		local bxStroke = box:FindFirstChild("BoxStroke")
		
		if i < currentDay then
			-- Already claimed
			if check then check.Visible = true end
			box.BackgroundTransparency = 0.4
		elseif i == currentDay then
			-- Today's reward (next to claim) - never show checkmark here
			if check then check.Visible = false end
			box.BackgroundTransparency = 0
			if bxStroke then bxStroke.Thickness = 3 end
			-- Glow effect
			TS:Create(box, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				BackgroundColor3 = Color3.fromRGB(50, 40, 75)
			}):Play()
		else
			-- Future days
			box.BackgroundTransparency = 0.5
			if check then check.Visible = false end
		end
	end
	
	if claimed then
		local secs = data.SecondsUntilReset or 0
		if secs > 0 then
			countdownSeconds = secs
			countdownActive = true
			claimBtn.Text = "LOCKED - " .. formatTime(secs)
		else
			claimBtn.Text = "CLAIMED TODAY"
		end
		claimBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	else
		countdownActive = false
		claimBtn.Text = "CLAIM REWARD"
		claimBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 60)
	end
end

claimBtn.MouseButton1Click:Connect(function()
	if claiming then return end
	claiming = true
	local re = RS:FindFirstChild("RemoteEvents")
	if not re then claiming = false return end
	local claimDR = re:FindFirstChild("ClaimDailyReward")
	if not claimDR then claiming = false return end
	
	local result = claimDR:InvokeServer()
	if result and result.Success then
		if _G.Notify then
			_G.Notify("Claimed!", result.Message or "Reward collected!", 3, "success")
		end
		-- Refresh UI
		local getDR = re:FindFirstChild("GetDailyReward")
		if getDR then
			local data = getDR:InvokeServer()
			if data then updateUI(data) end
		end
	elseif result then
		if _G.Notify then
			_G.Notify("? Already Claimed", result.Message or "Come back tomorrow!", 3, "warning")
		end
	end
	task.delay(0.5, function()
		claiming = false
	end)
end)

-- Countdown timer loop for claim button
task.spawn(function()
	while true do
		task.wait(1)
		if countdownActive and countdownSeconds > 0 then
			countdownSeconds = countdownSeconds - 1
			if countdownSeconds <= 0 then
				countdownActive = false
				claimBtn.Text = "CLAIM REWARD"
				claimBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 60)
			else
				claimBtn.Text = "LOCKED - " .. formatTime(countdownSeconds)
			end
		end
	end
end)

print("Daily Rewards client ready")
