-- ============================================
-- ADMIN PANEL CLIENT
-- Place in: StarterGui/AdminPanel/AdminClient (LocalScript)
-- ONLY ScarletxHunterx can use this
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = script.Parent

-- ADMIN CHECK
local ADMIN_NAMES = {"ScarletxHunterx"}
local ADMIN_IDS = {658326075}

local function isAdmin()
	for _, name in ipairs(ADMIN_NAMES) do
		if player.Name == name then return true end
	end
	for _, id in ipairs(ADMIN_IDS) do
		if player.UserId == id then return true end
	end
	return false
end

if not isAdmin() then
	gui.Enabled = false
	local toggle = gui:FindFirstChild("ToggleButton")
	if toggle then toggle.Visible = false end
	return
end

print("?? Admin Panel loading for", player.Name)

-- FIND UI
local mainPanel = gui:WaitForChild("MainPanel")
local toggleBtn = gui:WaitForChild("ToggleButton")
local closeBtn = mainPanel:WaitForChild("TitleBar"):WaitForChild("CloseBtn")
local content = mainPanel:WaitForChild("Content")
local statusBar = mainPanel:WaitForChild("StatusBar")
local tabBar = mainPanel:WaitForChild("TabBar")

local playersTab = content:WaitForChild("PlayersTab")
local economyTab = content:WaitForChild("EconomyTab")
local gameTab = content:WaitForChild("GameTab")
local debugTab = content:WaitForChild("DebugTab")
local debugOutput = debugTab:WaitForChild("DebugOutput")

-- REMOTE
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local adminEvent = remoteEvents and remoteEvents:WaitForChild("AdminCommand", 5)

-- STATE
local noclipOn = false
local noclipConn = nil
local godMode = false

-- STATUS
local function setStatus(txt, col)
	statusBar.Text = "  " .. txt
	statusBar.TextColor3 = col or Color3.fromRGB(0, 255, 0)
	task.delay(4, function()
		if statusBar and statusBar.Parent then
			statusBar.Text = "  Ready"
			statusBar.TextColor3 = Color3.fromRGB(0, 255, 0)
		end
	end)
end

-- SEND
local function send(cmd, data)
	if adminEvent then
		adminEvent:FireServer(cmd, data or {})
		print("?? Admin:", cmd)
	else
		setStatus("ERROR: No remote!", Color3.fromRGB(255, 50, 50))
	end
end

-- TOGGLE
toggleBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = not mainPanel.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
end)

-- TABS
local allTabs = {PLAYERS = playersTab, ECONOMY = economyTab, GAME = gameTab, DEBUG = debugTab}
local function switchTab(name)
	for n, t in pairs(allTabs) do t.Visible = (n == name) end
	for _, b in pairs(tabBar:GetChildren()) do
		if b:IsA("TextButton") then
			b.BackgroundColor3 = b.Name == "Tab_" .. name and Color3.fromRGB(60, 65, 80) or Color3.fromRGB(40, 42, 55)
		end
	end
end
for _, b in pairs(tabBar:GetChildren()) do
	if b:IsA("TextButton") then
		b.MouseButton1Click:Connect(function()
			switchTab(b.Name:gsub("Tab_", ""))
		end)
	end
end
switchTab("PLAYERS")

-- GET INPUTS
local function getTarget(tab)
	if tab == "ECONOMY" then
		local i = economyTab:FindFirstChild("EcoTarget")
		return i and i.Text or ""
	else
		local i = playersTab:FindFirstChild("TargetPlayer")
		return i and i.Text or ""
	end
end

local function getCoinAmount()
	local i = economyTab:FindFirstChild("CoinAmount")
	return i and tonumber(i.Text) or nil
end

local function getWeaponName()
	local i = economyTab:FindFirstChild("WeaponName")
	return i and i.Text or ""
end

-- ============================================
-- PLAYERS TAB
-- ============================================
for _, btn in pairs(playersTab:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			local target = getTarget("PLAYERS")
			if target == "" then
				setStatus("Enter a player name first!", Color3.fromRGB(255, 200, 0))
				return
			end
			local t = btn.Text
			if t:find("Kill") then send("KillPlayer", {target=target}); setStatus("Killed " .. target)
			elseif t:find("Heal") then send("HealPlayer", {target=target}); setStatus("Healed " .. target)
			elseif t:find("Lobby") then send("TeleportToLobby", {target=target}); setStatus("TP'd " .. target)
			elseif t:find("to Me") then send("TeleportToMe", {target=target}); setStatus("TP'd " .. target .. " to you")
			elseif t:find("Launch") then send("LaunchPlayer", {target=target}); setStatus("Launched " .. target)
			elseif t:find("Freeze") and not t:find("Un") then send("FreezePlayer", {target=target}); setStatus("Froze " .. target)
			elseif t:find("Unfreeze") then send("UnfreezePlayer", {target=target}); setStatus("Unfroze " .. target)
			elseif t:find("Kick") then send("KickPlayer", {target=target}); setStatus("Kicked " .. target)
			end
		end)
	end
end

-- ============================================
-- ECONOMY TAB
-- ============================================
for _, btn in pairs(economyTab:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			local target = getTarget("ECONOMY")
			local amount = getCoinAmount()
			local weapon = getWeaponName()
			local t = btn.Text

			if t:find("Add Coins") then
				if target == "" then setStatus("Enter player name!", Color3.fromRGB(255,200,0)); return end
				if not amount then setStatus("Enter a number!", Color3.fromRGB(255,200,0)); return end
				send("AddCoins", {target=target, amount=amount})
				setStatus("Added " .. amount .. " coins to " .. target)

			elseif t:find("Set Coins") then
				if target == "" then setStatus("Enter player name!", Color3.fromRGB(255,200,0)); return end
				if not amount then setStatus("Enter a number!", Color3.fromRGB(255,200,0)); return end
				send("SetCoins", {target=target, amount=amount})
				setStatus("Set " .. target .. " coins to " .. amount)

			elseif t:find("Add Wins") then
				if target == "" then setStatus("Enter player name!", Color3.fromRGB(255,200,0)); return end
				if not amount then setStatus("Enter a number!", Color3.fromRGB(255,200,0)); return end
				send("AddWins", {target=target, amount=amount})
				setStatus("Added " .. amount .. " wins to " .. target)

			elseif t:find("Give Weapon") then
				if target == "" then setStatus("Enter player name!", Color3.fromRGB(255,200,0)); return end
				if weapon == "" then setStatus("Enter weapon name!", Color3.fromRGB(255,200,0)); return end
				send("GiveWeapon", {target=target, weapon=weapon})
				setStatus("Gave " .. weapon .. " to " .. target)

			elseif t:find("10K") then
				send("AddCoins", {target=player.Name, amount=10000})
				setStatus("Added 10K to yourself!")

			elseif t:find("100K") then
				send("AddCoins", {target=player.Name, amount=100000})
				setStatus("Added 100K to yourself!")

			elseif t:find("Reset") then
				send("SetCoins", {target=player.Name, amount=0})
				setStatus("Reset your coins to 0")

			elseif t:find("All Weapons") then
				send("GiveAllWeapons", {target=player.Name})
				setStatus("Giving all weapons!")
			end
		end)
	end
end

-- ============================================
-- GAME TAB
-- ============================================
for _, btn in pairs(gameTab:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			local t = btn.Text
			if t:find("Skip") then send("SkipToRound"); setStatus("Skipping to round...")
			elseif t:find("End Round") then send("EndRound"); setStatus("Ending round...")
			elseif t:find("Cleanup") then send("CleanupEffects"); setStatus("Cleaning effects...")
			elseif t:find("Respawn") then send("RespawnAll"); setStatus("Respawning all...")
			elseif t:find("TP All") then send("TeleportAllToLobby"); setStatus("TP all to lobby...")
			elseif t:find("Speed Boost") then send("SpeedBoostAll"); setStatus("Speed boosted all!")
			elseif t:find("Kill All") then send("KillAll"); setStatus("Killed all!")
			elseif t:find("Max Speed") then
				local c = player.Character
				if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = 100 end
				setStatus("Max speed ON!")
			elseif t:find("Reset Speed") then
				local c = player.Character
				if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = 16 end
				setStatus("Speed reset!")
			elseif t:find("Super Jump") then
				local c = player.Character
				if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = 150 end
				setStatus("Super jump ON!")
			elseif t:find("God Mode") then
				godMode = not godMode
				if godMode then
					local c = player.Character
					if c and c:FindFirstChild("Humanoid") then
						c.Humanoid.MaxHealth = math.huge
						c.Humanoid.Health = math.huge
					end
					setStatus("God Mode ON!", Color3.fromRGB(255, 200, 0))
				else
					local c = player.Character
					if c and c:FindFirstChild("Humanoid") then
						c.Humanoid.MaxHealth = 100
						c.Humanoid.Health = 100
					end
					setStatus("God Mode OFF")
				end
			end
		end)
	end
end

-- ============================================
-- DEBUG TAB
-- ============================================
for _, btn in pairs(debugTab:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			local t = btn.Text

			if t:find("Server Stats") then
				send("GetServerStats")
				setStatus("Requesting stats...")

			elseif t:find("All Players") then
				local info = "=== PLAYERS ===\n"
				for _, p in pairs(Players:GetPlayers()) do
					local coins, wins = "?", "?"
					local ls = p:FindFirstChild("leaderstats")
					if ls then
						if ls:FindFirstChild("Coins") then coins = tostring(ls.Coins.Value) end
						if ls:FindFirstChild("Wins") then wins = tostring(ls.Wins.Value) end
					end
					info = info .. p.Name .. " | ??" .. coins .. " | ??" .. wins .. "\n"
				end
				debugOutput.Text = info

			elseif t:find("All Weapons") then
				local info = "=== WEAPONS ===\n"
				pcall(function()
					local cfg = require(ReplicatedStorage:WaitForChild("WeaponConfigs", 2))
					for name, c in pairs(cfg) do
						info = info .. (c.Emoji or "") .. " " .. name .. " CD:" .. (c.Cooldown or "?") .. "s " .. (c.Rarity or "") .. "\n"
					end
				end)
				debugOutput.Text = info

			elseif t:find("Inventory") then
				local info = "=== INVENTORY ===\n"
				local bp = player:FindFirstChild("Backpack")
				if bp then
					for _, tool in pairs(bp:GetChildren()) do
						if tool:IsA("Tool") then info = info .. "?? " .. tool.Name .. "\n" end
					end
				end
				local ch = player.Character
				if ch then
					for _, tool in pairs(ch:GetChildren()) do
						if tool:IsA("Tool") then info = info .. "? " .. tool.Name .. " (held)\n" end
					end
				end
				local ls = player:FindFirstChild("leaderstats")
				if ls then
					info = info .. "\n?? " .. (ls:FindFirstChild("Coins") and tostring(ls.Coins.Value) or "?")
					info = info .. "\n?? " .. (ls:FindFirstChild("Wins") and tostring(ls.Wins.Value) or "?")
				end
				debugOutput.Text = info

			elseif t:find("Noclip") then
				noclipOn = not noclipOn
				if noclipOn then
					noclipConn = RunService.Stepped:Connect(function()
						local c = player.Character
						if c then
							for _, p in pairs(c:GetDescendants()) do
								if p:IsA("BasePart") then p.CanCollide = false end
							end
						end
					end)
					setStatus("Noclip ON!", Color3.fromRGB(255, 200, 0))
				else
					if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
					setStatus("Noclip OFF")
				end

			elseif t:find("Invisible") then
				local ch = player.Character
				if ch then
					local vis = true
					for _, p in pairs(ch:GetDescendants()) do
						if p:IsA("BasePart") and p.Transparency >= 0.9 then vis = false; break end
					end
					for _, p in pairs(ch:GetDescendants()) do
						if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
							p.Transparency = vis and 1 or 0
						end
						if p:IsA("Decal") or p:IsA("Texture") then
							p.Transparency = vis and 1 or 0
						end
					end
					setStatus(vis and "Invisible ON" or "Invisible OFF")
				end
			end
		end)
	end
end

-- SERVER RESPONSES
if adminEvent then
	adminEvent.OnClientEvent:Connect(function(rtype, data)
		if rtype == "ServerStats" then
			debugOutput.Text = "=== SERVER ===\n"
				.. "Players: " .. (data.players or "?") .. "\n"
				.. "Uptime: " .. (data.uptime or "?") .. "s\n"
				.. "Round: " .. tostring(data.roundActive) .. "\n"
				.. "Memory: " .. (data.memory or "?") .. "MB\n"
		elseif rtype == "Message" then
			setStatus(data.text or "Done", data.color)
		end
	end)
end

-- F9 SHORTCUT
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F9 then
		mainPanel.Visible = not mainPanel.Visible
	end
end)

print("? Admin Panel loaded! Press F9 or ??")