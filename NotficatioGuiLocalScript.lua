local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

-- Set _G.Notify early so other scripts can call it before we finish loading
local pendingNotifs = {}
_G.Notify = function(t, m, d, ty)
	table.insert(pendingNotifs, {t, m, d or 2, ty})
end

local re = RS:WaitForChild("RemoteEvents", 10)
local notifyRemote = re and re:WaitForChild("NotifyClient", 10) or nil

-- Try to find NotifFrame in the GUI hierarchy; if missing, CREATE it
local notifFrame = script.Parent and script.Parent:FindFirstChild("NotifFrame")
if not notifFrame then
	-- Build notification frame programmatically
	notifFrame = Instance.new("Frame")
	notifFrame.Name = "NotifFrame"
	notifFrame.Size = UDim2.new(0.3, 0, 0.08, 0)
	notifFrame.Position = UDim2.new(1.2, 0, 0.82, 0)
	notifFrame.AnchorPoint = Vector2.new(1, 0)
	notifFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
	notifFrame.BackgroundTransparency = 0
	notifFrame.BorderSizePixel = 0
	notifFrame.ZIndex = 100
	notifFrame.Parent = script.Parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notifFrame

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(80, 65, 110)
	uiStroke.Thickness = 2
	uiStroke.Parent = notifFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -16, 0.5, 0)
	titleLabel.Position = UDim2.new(0, 8, 0, 2)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.ZIndex = 101
	titleLabel.Parent = notifFrame

	local msgLabel = Instance.new("TextLabel")
	msgLabel.Name = "Message"
	msgLabel.Size = UDim2.new(1, -16, 0.45, 0)
	msgLabel.Position = UDim2.new(0, 8, 0.5, 0)
	msgLabel.BackgroundTransparency = 1
	msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	msgLabel.Font = Enum.Font.Gotham
	msgLabel.TextSize = 13
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
	msgLabel.ZIndex = 101
	msgLabel.Parent = notifFrame

	print("NotificationGui: NotifFrame created programmatically")
end

local title = notifFrame:FindFirstChild("Title") or notifFrame:WaitForChild("Title", 3)
local msg = notifFrame:FindFirstChild("Message") or notifFrame:WaitForChild("Message", 3)
local stroke = notifFrame:FindFirstChildWhichIsA("UIStroke")

if not title or not msg then
	warn("NotificationGui: Could not find or create Title/Message labels")
	return
end

-- Try to get ConfirmGui (optional - don't break if missing)
local confirmGui, confirmFrame, cTitle, cMsg, yesBtn, noBtn
pcall(function()
	confirmGui = script.Parent.Parent:FindFirstChild("ConfirmGui") or script.Parent.Parent:WaitForChild("ConfirmGui", 3)
	if confirmGui then
		confirmFrame = confirmGui:WaitForChild("ConfirmFrame", 3)
		if confirmFrame then
			cTitle = confirmFrame:WaitForChild("Title", 3)
			cMsg = confirmFrame:WaitForChild("Message", 3)
			yesBtn = confirmFrame:WaitForChild("YesButton", 3)
			noBtn = confirmFrame:WaitForChild("NoButton", 3)
		end
	end
end)

local queue = {}
local showing = false
local confirmCallback = nil

local colors = {
	info = {bg = Color3.fromRGB(20, 18, 28), stroke = Color3.fromRGB(80, 65, 110), title = Color3.fromRGB(255, 220, 100)},
	success = {bg = Color3.fromRGB(15, 35, 20), stroke = Color3.fromRGB(0, 200, 80), title = Color3.fromRGB(100, 255, 150)},
	warning = {bg = Color3.fromRGB(40, 30, 15), stroke = Color3.fromRGB(255, 180, 50), title = Color3.fromRGB(255, 220, 100)},
	trail = {bg = Color3.fromRGB(20, 15, 35), stroke = Color3.fromRGB(160, 80, 255), title = Color3.fromRGB(200, 140, 255)},
	skill = {bg = Color3.fromRGB(25, 20, 45), stroke = Color3.fromRGB(180, 100, 255), title = Color3.fromRGB(220, 180, 255)},
	error = {bg = Color3.fromRGB(40, 15, 15), stroke = Color3.fromRGB(255, 80, 80), title = Color3.fromRGB(255, 120, 120)},
}

local function showNotif(titleText, msgText, duration, nType)
	if showing then
		table.insert(queue, {titleText, msgText, duration, nType})
		return
	end
	showing = true
	local c = colors[nType or "info"] or colors.info
	
	notifFrame.BackgroundColor3 = c.bg
	if stroke then stroke.Color = c.stroke end
	title.Text = titleText or "Notice"
	title.TextColor3 = c.title
	msg.Text = msgText or ""
	
	notifFrame.Position = UDim2.new(1.2, 0, 0.82, 0)
	TS:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.97, 0, 0.82, 0)
	}):Play()
	
	task.delay(duration or 2.5, function()
		TS:Create(notifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1.2, 0, 0.82, 0)
		}):Play()
		task.delay(0.3, function()
			showing = false
			if #queue > 0 then
				local nxt = table.remove(queue, 1)
				showNotif(nxt[1], nxt[2], nxt[3], nxt[4])
			end
		end)
	end)
end

-- Confirm system (optional)
local function confirm(titleText, msgText, onYes)
	if not confirmFrame then return end
	confirmCallback = onYes
	cTitle.Text = titleText or "Confirm"
	cMsg.Text = msgText or "Are you sure?"
	confirmFrame.Visible = true
end

if yesBtn then
	yesBtn.MouseButton1Click:Connect(function()
		if confirmFrame then confirmFrame.Visible = false end
		if confirmCallback then confirmCallback() end
		confirmCallback = nil
	end)
end
if noBtn then
	noBtn.MouseButton1Click:Connect(function()
		if confirmFrame then confirmFrame.Visible = false end
		confirmCallback = nil
	end)
end

if notifyRemote then
	notifyRemote.OnClientEvent:Connect(function(t, m, d, ty)
		showNotif(t, m, d, ty)
	end)
end

_G.ShowNotification = showNotif
_G.ConfirmAction = confirm
_G.Confirm = function(titleArg, msgArg, callback)
	confirm(titleArg, msgArg, function()
		if callback then callback(true) end
	end)
end
_G.Notify = showNotif

-- Flush any notifications queued before we were ready
for _, n in ipairs(pendingNotifs) do
	showNotif(n[1], n[2], n[3], n[4])
end
pendingNotifs = {}

print("Notification + Confirm system ready")
print("Notification GLOBALS READY: _G.Notify, _G.Confirm, _G.ShowNotification")
