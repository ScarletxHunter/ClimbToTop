local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local plr = Players.LocalPlayer
local gui = script.Parent
local bar = gui:WaitForChild("ButtonBar")

-- #region agent log
local reDbgBar = RS:WaitForChild("RemoteEvents", 10)
local ClientDebugLogBar = reDbgBar and reDbgBar:FindFirstChild("ClientDebugLog")
local function cdbgBar(hId, loc, msg, data)
	local payload = {
		id = "log_" .. tostring(math.floor(os.clock() * 1000)) .. "_" .. HttpService:GenerateGUID(false),
		runId = "btnbar_icon_debug",
		hypothesisId = hId,
		location = loc,
		message = msg,
		data = data or {},
		timestamp = DateTime.now().UnixTimestampMillis,
	}
	if ClientDebugLogBar then
		pcall(function()
			ClientDebugLogBar:FireServer(payload)
		end)
	end
end
-- #endregion

-- Find the other GUIs
local function findGui(name)
	return plr:WaitForChild("PlayerGui"):FindFirstChild(name)
end

-- Actions map
local actions = {}

actions.Shop = function()
	local g = findGui("NewShopGui")
	if not g then return end
	local content = g:FindFirstChild("Content")
	if not content then return end
	
	if content.Visible then
		TS:Create(content, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.delay(0.2, function() content.Visible = false end)
	else
		content.Visible = true
		content.Size = UDim2.new(0, 0, 0, 0)
		TS:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.58, 0, 0.6, 0)
		}):Play()
	end
end

actions.Trails = function()
	local g = findGui("TrailShopGui")
	if not g then return end
	local container = g:FindFirstChild("Container")
	if not container then return end
	
	if container.Visible then
		TS:Create(container, TweenInfo.new(0.18), {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		task.delay(0.18, function() container.Visible = false end)
	else
		container.Visible = true
		container.Size = UDim2.new(0, 0, 0, 0)
		container.Position = UDim2.new(0.5, 0, 0.5, 0)
		TS:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.72, 0, 0.72, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
	end
end

actions.Leaderboard = function()
	local g = findGui("NewLeaderboardGui")
	if not g then return end
	local panel = g:FindFirstChild("Panel")
	if not panel then return end
	panel.Visible = not panel.Visible
end

actions.Admin = function()
	-- #region agent log
	warn("[DBG-ADM] Admin button pressed")
	-- #endregion

	-- Use the global toggle function from AdminClient (handles animation)
	if _G.ToggleAdminPanel then
		-- #region agent log
		warn("[DBG-ADM] Using _G.ToggleAdminPanel")
		-- #endregion
		_G.ToggleAdminPanel()
		return
	end

	-- #region agent log
	warn("[DBG-ADM] _G.ToggleAdminPanel is NIL, trying fallback")
	-- #endregion

	-- Fallback: check admin and toggle directly
	local re = RS:FindFirstChild("RemoteEvents")
	if not re then return end
	local check = re:FindFirstChild("AdminCheck")
	if check then
		local ok, isAdmin = pcall(function() return check:InvokeServer() end)
		if not ok or not isAdmin then
			if _G.Notify then _G.Notify("Access Denied", "Admin only!", 2, "error") end
			return
		end
	end
	
	local g = findGui("AdminGui")
	-- #region agent log
	warn("[DBG-ADM] findGui('AdminGui') =", tostring(g))
	-- #endregion
	if not g then return end
	local panel = g:FindFirstChild("Panel")
	if not panel then return end
	-- #region agent log
	warn("[DBG-ADM] Panel found, Visible:", panel.Visible, "Position:", tostring(panel.Position))
	-- #endregion
	panel.Visible = not panel.Visible
end

actions.Pets = function()
	if _G.Notify then
		_G.Notify("Pets", "Coming soon!", 2, "info")
	end
end

actions.Settings = function()
	-- Use global function from SettingsScript (most reliable)
	if _G.OpenSettings then
		_G.OpenSettings()
		return
	end
	-- Fallback
	local g = findGui("SettingsGui")
	if g then
		local p = g:FindFirstChild("Panel")
		if p then p.Visible = not p.Visible end
	end
end

-- Wire all buttons (Activated works on both desktop + mobile)
for _, btn in pairs(bar:GetChildren()) do
	if not btn:IsA("GuiButton") then continue end
	-- #region agent log
	cdbgBar("H_BTN_CLASS", "ButtonBarScript:init", "Button discovered", {
		name = btn.Name,
		className = btn.ClassName,
		size = tostring(btn.Size),
		backgroundTransparency = btn.BackgroundTransparency,
		hasAction = btn:FindFirstChild("Action") ~= nil,
		selectable = btn.Selectable,
	})
	-- #endregion

	if btn:IsA("ImageButton") then
		-- #region agent log
		cdbgBar("H_BTN_IMAGE", "ButtonBarScript:init", "ImageButton properties", {
			name = btn.Name,
			image = btn.Image,
			scaleType = tostring(btn.ScaleType),
			imageTransparency = btn.ImageTransparency,
			imageRectSize = tostring(btn.ImageRectSize),
		})
		-- #endregion
	end

	local hoverStroke = btn:FindFirstChildWhichIsA("UIStroke")
	if hoverStroke then
		-- #region agent log
		cdbgBar("H_HOVER_SRC", "ButtonBarScript:init", "Initial stroke state", {
			name = btn.Name,
			color = tostring(hoverStroke.Color),
			thickness = hoverStroke.Thickness,
			transparency = hoverStroke.Transparency,
		})
		-- #endregion
	end

	local actionVal = btn:FindFirstChild("Action")
	if not actionVal then continue end
	
	btn.Activated:Connect(function()
		-- #region agent log
		warn("[DBG-BTN] CLICKED:", btn.Name, "-> action:", actionVal.Value)
		-- #endregion
		-- Button press animation
		local orig = btn.Size
		local pressed = UDim2.new(
			orig.X.Scale * 0.92, math.floor(orig.X.Offset * 0.92),
			orig.Y.Scale * 0.92, math.floor(orig.Y.Offset * 0.92)
		)
		TS:Create(btn, TweenInfo.new(0.06), {Size = pressed}):Play()
		task.wait(0.06)
		TS:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Back), {Size = orig}):Play()
		
		-- Run action
		local fn = actions[actionVal.Value]
		if fn then fn() end
	end)
	
	-- Hover effect (desktop)
	btn.MouseEnter:Connect(function()
		local s = btn:FindFirstChildWhichIsA("UIStroke")
		if s then
			-- #region agent log
			cdbgBar("H_HOVER_STROKE", "ButtonBarScript:hover", "MouseEnter before stroke", {
				name = btn.Name,
				color = tostring(s.Color),
				thickness = s.Thickness,
				transparency = s.Transparency,
			})
			-- #endregion
			s.Thickness = 1.5 s.Transparency = 0
			-- #region agent log
			cdbgBar("H_HOVER_STROKE", "ButtonBarScript:hover", "MouseEnter after stroke", {
				name = btn.Name,
				color = tostring(s.Color),
				thickness = s.Thickness,
				transparency = s.Transparency,
			})
			-- #endregion
		end
	end)
	btn.MouseLeave:Connect(function()
		local s = btn:FindFirstChildWhichIsA("UIStroke")
		if s then
			-- #region agent log
			cdbgBar("H_HOVER_STROKE", "ButtonBarScript:hover", "MouseLeave before stroke", {
				name = btn.Name,
				color = tostring(s.Color),
				thickness = s.Thickness,
				transparency = s.Transparency,
			})
			-- #endregion
			s.Thickness = 0 s.Transparency = 0.7
			-- #region agent log
			cdbgBar("H_HOVER_STROKE", "ButtonBarScript:hover", "MouseLeave after stroke", {
				name = btn.Name,
				color = tostring(s.Color),
				thickness = s.Thickness,
				transparency = s.Transparency,
			})
			-- #endregion
		end
	end)

	btn.SelectionGained:Connect(function()
		-- #region agent log
		cdbgBar("H_SELECTION", "ButtonBarScript:selection", "SelectionGained", {
			name = btn.Name,
			selectable = btn.Selectable,
		})
		-- #endregion
	end)

	btn.SelectionLost:Connect(function()
		-- #region agent log
		cdbgBar("H_SELECTION", "ButtonBarScript:selection", "SelectionLost", {
			name = btn.Name,
			selectable = btn.Selectable,
		})
		-- #endregion
	end)
end

print("✅ ButtonBar ready!")
print("   🛒 Shop (G) | ✨ Trails (B) | 🏆 Leaderboard (L) | ⚙ Admin (F2)")
