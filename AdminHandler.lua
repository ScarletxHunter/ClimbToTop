-- ============================================
-- ADMIN HANDLER - Advanced with Chat Commands
-- Place in: ServerScriptService > GameScripts
-- ============================================

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SSS = game:GetService("ServerScriptService")

-- ============ ADMIN LIST ============
local ADMINS = {
	658326075,
}

local function isAdmin(plr)
	for _, id in ipairs(ADMINS) do
		if plr.UserId == id then return true end
	end
	return false
end

-- ============ REMOTES ============
local remoteEvents = RS:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = RS
end

local function goc(name, isFunc)
	local r = remoteEvents:FindFirstChild(name)
	if not r then
		r = isFunc and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remoteEvents
	end
	return r
end

local AdminRemote = goc("AdminCommand")
local AdminCheck = goc("AdminCheck", true)
local AdminGetTrails = goc("AdminGetTrails", true)
local AdminGetPlayers = goc("AdminGetPlayers", true)
local NotifyClient = goc("NotifyClient")

AdminCheck.OnServerInvoke = function(plr)
	return isAdmin(plr)
end

local PDM = require(SSS:WaitForChild("PlayerDataManager"))

-- ============ HELPERS ============
local function findPlayer(name)
	if not name or name == "" then return nil end
	name = name:lower()
	for _, p in pairs(Players:GetPlayers()) do
		if p.Name:lower() == name or p.DisplayName:lower() == name then return p end
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #name) == name then return p end
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p.DisplayName:lower():sub(1, #name) == name then return p end
	end
	return nil
end

local function respond(plr, msg)
	NotifyClient:FireClient(plr, "Admin", msg, 4, "info")
	print("⚙ Admin | " .. plr.Name .. ": " .. msg)
end

-- ============ COMMANDS ============
local COMMANDS = {}

-- ─── PLAYER COMMANDS ───

COMMANDS.Kill = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found: " .. tostring(args.Target)) end
	local c = t.Character
	if c then
		local h = c:FindFirstChild("Humanoid")
		if h then h.Health = 0 end
	end
	respond(plr, "Killed " .. t.Name)
end

COMMANDS.Kick = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	if t == plr then return respond(plr, "Can't kick yourself") end
	local reason = args.Reason or "Kicked by admin."
	t:Kick(reason)
	respond(plr, "Kicked " .. t.Name)
end

COMMANDS.Respawn = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	t:LoadCharacter()
	respond(plr, "Respawned " .. t.Name)
end

COMMANDS.Heal = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local c = t.Character
	if c then
		local h = c:FindFirstChild("Humanoid")
		if h then h.Health = h.MaxHealth end
	end
	respond(plr, "Healed " .. t.Name)
end

COMMANDS.GodMode = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local c = t.Character
	if c then
		local ff = c:FindFirstChild("ForceField")
		if ff then
			ff:Destroy()
			respond(plr, "God mode OFF for " .. t.Name)
		else
			Instance.new("ForceField").Parent = c
			respond(plr, "God mode ON for " .. t.Name)
		end
	end
end

COMMANDS.Freeze = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local c = t.Character
	if c then
		local h = c:FindFirstChild("HumanoidRootPart")
		if h then
			h.Anchored = not h.Anchored
			respond(plr, (h.Anchored and "Froze " or "Unfroze ") .. t.Name)
		end
	end
end

COMMANDS.TeleportTo = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local c1 = plr.Character
	local c2 = t.Character
	if c1 and c2 then
		local h1 = c1:FindFirstChild("HumanoidRootPart")
		local h2 = c2:FindFirstChild("HumanoidRootPart")
		if h1 and h2 then h1.CFrame = h2.CFrame * CFrame.new(0, 0, -5) end
	end
	respond(plr, "Teleported to " .. t.Name)
end

COMMANDS.TpAllToMe = function(plr, args)
	local c = plr.Character
	if not c then return respond(plr, "No character") end
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local count = 0
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= plr then
			local pc = p.Character
			if pc then
				local ph = pc:FindFirstChild("HumanoidRootPart")
				if ph then
					ph.CFrame = hrp.CFrame * CFrame.new(math.random(-5, 5), 0, math.random(-5, 5))
					count = count + 1
				end
			end
		end
	end
	respond(plr, "Teleported " .. count .. " players to you")
end

COMMANDS.SetSpeed = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local speed = tonumber(args.Amount) or 16
	local c = t.Character
	if c then
		local h = c:FindFirstChild("Humanoid")
		if h then
			h.WalkSpeed = speed
			c:SetAttribute("BaseWalkSpeed", speed)
		end
	end
	respond(plr, "Set " .. t.Name .. " speed to " .. speed)
end

COMMANDS.SetJump = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local jump = tonumber(args.Amount) or 50
	local c = t.Character
	if c then
		local h = c:FindFirstChild("Humanoid")
		if h then
			h.JumpPower = jump
			c:SetAttribute("BaseJumpPower", jump)
		end
	end
	respond(plr, "Set " .. t.Name .. " jump to " .. jump)
end

COMMANDS.Invisible = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local c = t.Character
	if not c then return end
	local isVis = true
	for _, part in pairs(c:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Transparency < 1 then
				part:SetAttribute("_AdminOrigTransparency", part.Transparency)
				part.Transparency = 1
				isVis = false
			else
				local orig = part:GetAttribute("_AdminOrigTransparency")
				part.Transparency = orig or 0
			end
		end
	end
	respond(plr, (isVis and "Visible" or "Invisible") .. " for " .. t.Name)
end

-- ─── ECONOMY COMMANDS ───

COMMANDS.GiveCoins = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local amount = tonumber(args.Amount) or 0
	if amount <= 0 then return respond(plr, "Invalid amount") end
	local ls = t:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Coins")
		if c then c.Value = c.Value + amount end
	end
	local data = PDM.GetData(t)
	if data then data.Coins = (data.Coins or 0) + amount end
	if _G.UpdatePlayerCoins then _G.UpdatePlayerCoins(t, amount) end
	if _G.SyncPlayerCoins then _G.SyncPlayerCoins(t) end
	PDM.SaveData(t)
	respond(plr, "Gave " .. amount .. " coins to " .. t.Name)
end

COMMANDS.RemoveCoins = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local amount = tonumber(args.Amount) or 0
	if amount <= 0 then return respond(plr, "Invalid amount") end
	local ls = t:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Coins")
		if c then c.Value = math.max(c.Value - amount, 0) end
	end
	local data = PDM.GetData(t)
	if data then data.Coins = math.max((data.Coins or 0) - amount, 0) end
	if _G.SyncPlayerCoins then _G.SyncPlayerCoins(t) end
	PDM.SaveData(t)
	respond(plr, "Removed " .. amount .. " coins from " .. t.Name)
end

COMMANDS.SetCoins = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local amount = tonumber(args.Amount) or 0
	local ls = t:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Coins")
		if c then c.Value = amount end
	end
	local data = PDM.GetData(t)
	if data then data.Coins = amount end
	if _G.SyncPlayerCoins then _G.SyncPlayerCoins(t) end
	PDM.SaveData(t)
	respond(plr, "Set " .. t.Name .. " coins to " .. amount)
end

COMMANDS.GiveWins = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local amount = tonumber(args.Amount) or 1
	local ls = t:FindFirstChild("leaderstats")
	if ls then
		local w = ls:FindFirstChild("Wins")
		if w then w.Value = w.Value + amount end
	end
	local data = PDM.GetData(t)
	if data then data.Wins = (data.Wins or 0) + amount end
	PDM.SaveData(t)
	respond(plr, "Gave " .. amount .. " wins to " .. t.Name)
end

-- ─── ROUND COMMANDS ───

COMMANDS.SkipRound = function(plr, args)
	if _G.AdminSkipRound then
		_G.AdminSkipRound()
		respond(plr, "Skipping round (timer -> 1)")
	else
		-- Fallback: direct timer set
		local gv = RS:FindFirstChild("GameValues")
		if gv then
			local timer = gv:FindFirstChild("RoundTimer") or gv:FindFirstChild("Timer")
			if timer then timer.Value = 1 end
		end
		respond(plr, "Skipping round (fallback)")
	end
end

COMMANDS.EndRound = function(plr, args)
	if _G.AdminEndRound then
		_G.AdminEndRound()
		respond(plr, "Force ending round")
	else
		-- Fallback
		local gv = RS:FindFirstChild("GameValues")
		if gv then
			local timer = gv:FindFirstChild("RoundTimer") or gv:FindFirstChild("Timer")
			if timer then timer.Value = 0 end
		end
		respond(plr, "Force ending round (fallback)")
	end
end

COMMANDS.SetTimer = function(plr, args)
	local t = tonumber(args.Amount) or 60
	-- Set via admin hook so GameManager picks it up
	_G.AdminSetTimer = t
	-- Also set the visible Timer value immediately
	local gv = RS:FindFirstChild("GameValues")
	if gv then
		local timer = gv:FindFirstChild("RoundTimer") or gv:FindFirstChild("Timer")
		if timer then timer.Value = t end
	end
	respond(plr, "Set round timer to " .. t .. "s")
end

COMMANDS.SetGameState = function(plr, args)
	local state = args.State or "Intermission"
	local gv = RS:FindFirstChild("GameValues")
	if gv then
		local gs = gv:FindFirstChild("GameState")
		if gs then gs.Value = state end
	end
	-- If setting to a non-Playing state, also end the round
	if state ~= "Playing" and _G.AdminEndRound then
		_G.AdminEndRound()
	end
	respond(plr, "Game state -> " .. state)
end

COMMANDS.SetTime = function(plr, args)
	local t = args.Time
	if t == "Day" then Lighting.ClockTime = 12
	elseif t == "Night" then Lighting.ClockTime = 0
	elseif t == "Sunset" then Lighting.ClockTime = 18
	elseif t == "Sunrise" then Lighting.ClockTime = 6
	end
	respond(plr, "Time of day -> " .. tostring(t))
end

-- ─── TRAIL COMMANDS ───

COMMANDS.GiveTrail = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local trailId = args.TrailId
	if not trailId or trailId == "" then return respond(plr, "No trail ID specified") end

	-- Give permanently
	PDM.AddPermanentTrail(t, trailId)
	PDM.SaveData(t)

	-- Auto-equip via global hook
	if _G.AdminEquipTrail then
		local ok, err = _G.AdminEquipTrail(t, trailId)
		if ok then
			respond(plr, "Gave + equipped '" .. trailId .. "' on " .. t.Name)
		else
			respond(plr, "Gave '" .. trailId .. "' (equip error: " .. tostring(err) .. ")")
		end
	else
		respond(plr, "Gave '" .. trailId .. "' to " .. t.Name .. " (trail system loading)")
	end
end

COMMANDS.EquipTrail = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local trailId = args.TrailId
	if not trailId or trailId == "" then return respond(plr, "No trail ID") end

	if _G.AdminEquipTrail then
		local ok, err = _G.AdminEquipTrail(t, trailId)
		if ok then respond(plr, "Equipped '" .. trailId .. "' on " .. t.Name)
		else respond(plr, "Failed: " .. tostring(err)) end
	else
		respond(plr, "Trail system not loaded yet")
	end
end

COMMANDS.UnequipTrail = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end

	if _G.AdminUnequipTrail then
		_G.AdminUnequipTrail(t)
		respond(plr, "Unequipped trail from " .. t.Name)
	else
		PDM.SetEquippedTrail(t, nil)
		respond(plr, "Unequipped trail from " .. t.Name)
	end
end

COMMANDS.RemoveTrail = function(plr, args)
	local t = findPlayer(args.Target)
	if not t then return respond(plr, "Player not found") end
	local trailId = args.TrailId
	if not trailId or trailId == "" then return respond(plr, "No trail ID") end

	local data = PDM.GetData(t)
	if data then
		if data.OwnedTrails then data.OwnedTrails[trailId] = nil end
		if data.PermanentTrails then data.PermanentTrails[trailId] = nil end
		if data.EquippedTrail == trailId then
			if _G.AdminUnequipTrail then _G.AdminUnequipTrail(t)
			else PDM.SetEquippedTrail(t, nil) end
		end
	end
	PDM.SaveData(t)
	respond(plr, "Removed '" .. trailId .. "' from " .. t.Name)
end

-- ─── SERVER COMMANDS ───

COMMANDS.Announce = function(plr, args)
	local msg = args.Message or ""
	if msg == "" then return respond(plr, "No message") end
	for _, p in pairs(Players:GetPlayers()) do
		NotifyClient:FireClient(p, "ANNOUNCEMENT", msg, 6, "info")
	end
	respond(plr, "Announced: " .. msg)
end

-- ============ REMOTE FUNCTIONS ============

AdminGetTrails.OnServerInvoke = function(plr)
	if not isAdmin(plr) then return {} end
	if _G.AllTrailData then return _G.AllTrailData end
	return {}
end

AdminGetPlayers.OnServerInvoke = function(plr)
	if not isAdmin(plr) then return {} end
	local list = {}
	for _, p in pairs(Players:GetPlayers()) do
		table.insert(list, {Name = p.Name, DisplayName = p.DisplayName, UserId = p.UserId})
	end
	return list
end

-- ============ REMOTE EVENT HANDLER ============

AdminRemote.OnServerEvent:Connect(function(plr, cmd, args)
	if not isAdmin(plr) then return end
	local fn = COMMANDS[cmd]
	if fn then
		print("⚙ " .. plr.Name .. " admin cmd: " .. cmd)
		fn(plr, args or {})
	else
		respond(plr, "Unknown command: " .. tostring(cmd))
	end
end)

-- ============ CHAT COMMANDS ============
-- Use /command or !command in chat

local CHAT_MAP = {
	kill    = function(plr, a) COMMANDS.Kill(plr, {Target = a[1]}) end,
	kick    = function(plr, a) COMMANDS.Kick(plr, {Target = a[1], Reason = table.concat(a, " ", 2)}) end,
	respawn = function(plr, a) COMMANDS.Respawn(plr, {Target = a[1] or plr.Name}) end,
	heal    = function(plr, a) COMMANDS.Heal(plr, {Target = a[1] or plr.Name}) end,
	god     = function(plr, a) COMMANDS.GodMode(plr, {Target = a[1] or plr.Name}) end,
	invis   = function(plr, a) COMMANDS.Invisible(plr, {Target = a[1] or plr.Name}) end,
	freeze  = function(plr, a) COMMANDS.Freeze(plr, {Target = a[1]}) end,
	tp      = function(plr, a) COMMANDS.TeleportTo(plr, {Target = a[1]}) end,
	tpall   = function(plr, a) COMMANDS.TpAllToMe(plr, {}) end,
	speed   = function(plr, a) COMMANDS.SetSpeed(plr, {Target = a[1], Amount = a[2]}) end,
	jump    = function(plr, a) COMMANDS.SetJump(plr, {Target = a[1], Amount = a[2]}) end,
	coins   = function(plr, a) COMMANDS.GiveCoins(plr, {Target = a[1], Amount = a[2]}) end,
	rmcoins = function(plr, a) COMMANDS.RemoveCoins(plr, {Target = a[1], Amount = a[2]}) end,
	setcoins= function(plr, a) COMMANDS.SetCoins(plr, {Target = a[1], Amount = a[2]}) end,
	wins    = function(plr, a) COMMANDS.GiveWins(plr, {Target = a[1], Amount = a[2]}) end,
	skip    = function(plr, a) COMMANDS.SkipRound(plr, {}) end,
	endround= function(plr, a) COMMANDS.EndRound(plr, {}) end,
	timer   = function(plr, a) COMMANDS.SetTimer(plr, {Amount = a[1]}) end,
	state   = function(plr, a) COMMANDS.SetGameState(plr, {State = a[1]}) end,
	day     = function(plr) COMMANDS.SetTime(plr, {Time = "Day"}) end,
	night   = function(plr) COMMANDS.SetTime(plr, {Time = "Night"}) end,
	sunset  = function(plr) COMMANDS.SetTime(plr, {Time = "Sunset"}) end,
	sunrise = function(plr) COMMANDS.SetTime(plr, {Time = "Sunrise"}) end,
	trail   = function(plr, a) COMMANDS.GiveTrail(plr, {Target = a[1], TrailId = a[2]}) end,
	equip   = function(plr, a) COMMANDS.EquipTrail(plr, {Target = a[1], TrailId = a[2]}) end,
	unequip = function(plr, a) COMMANDS.UnequipTrail(plr, {Target = a[1]}) end,
	rmtrail = function(plr, a) COMMANDS.RemoveTrail(plr, {Target = a[1], TrailId = a[2]}) end,
	say     = function(plr, a) COMMANDS.Announce(plr, {Message = table.concat(a, " ")}) end,
	announce= function(plr, a) COMMANDS.Announce(plr, {Message = table.concat(a, " ")}) end,
	cmds    = function(plr)
		respond(plr, "Commands: /kill /kick /heal /god /invis /freeze /tp /tpall /speed /jump /coins /rmcoins /setcoins /wins /skip /endround /timer /state /day /night /trail /equip /unequip /say /cmds")
	end,
}

local function handleChat(plr, msg)
	if not isAdmin(plr) then return end
	local prefix = msg:sub(1, 1)
	if prefix ~= "/" and prefix ~= "!" then return end

	local content = msg:sub(2)
	local parts = content:split(" ")
	if #parts == 0 then return end

	local cmd = parts[1]:lower()
	local args = {}
	for i = 2, #parts do table.insert(args, parts[i]) end

	local handler = CHAT_MAP[cmd]
	if handler then
		print("⚙ Chat cmd from " .. plr.Name .. ": " .. msg)
		handler(plr, args)
	end
end

-- Connect chat for all players
Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg) handleChat(plr, msg) end)
end)

-- Connect existing players (Studio testing)
for _, plr in pairs(Players:GetPlayers()) do
	plr.Chatted:Connect(function(msg) handleChat(plr, msg) end)
end

print("⚙ Admin Handler loaded!")
print("   Admins: " .. table.concat(ADMINS, ", "))
print("   GUI: F2 or tap toggle button")
print("   Chat: /cmds for command list")
