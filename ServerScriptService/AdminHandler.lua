-- ============================================
-- ADMIN HANDLER (Server)
-- Place in: ServerScriptService/AdminHandler (Script)
-- ONLY ScarletxHunterx can use this
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

print("?? Admin Handler loading...")

local ADMIN_NAMES = {"ScarletxHunterx"}
local ADMIN_IDS = {658326075}

local function isAdmin(p)
	for _, name in ipairs(ADMIN_NAMES) do
		if p.Name == name then return true end
	end
	for _, id in ipairs(ADMIN_IDS) do
		if p.UserId == id then return true end
	end
	return false
end

-- Remote
local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not re then
	re = Instance.new("Folder")
	re.Name = "RemoteEvents"
	re.Parent = ReplicatedStorage
end

local adminEvent = re:FindFirstChild("AdminCommand")
if not adminEvent then
	adminEvent = Instance.new("RemoteEvent")
	adminEvent.Name = "AdminCommand"
	adminEvent.Parent = re
end

-- Helpers
local function find(name)
	if not name or name == "" then return nil end
	name = name:lower()
	for _, p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #name) == name then return p end
	end
	return nil
end

local function hrp(p) return p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function hum(p) return p and p.Character and p.Character:FindFirstChild("Humanoid") end

local function msg(admin, text, color)
	adminEvent:FireClient(admin, "Message", {text = text, color = color})
end

-- ============================================
-- COMMANDS
-- ============================================
local cmds = {}

cmds.KillPlayer = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local h = hum(t)
	if h then h.Health = 0 end
	print("?? ADMIN:", a.Name, "killed", t.Name)
end

cmds.HealPlayer = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local h = hum(t)
	if h then h.Health = h.MaxHealth end
	print("?? ADMIN:", a.Name, "healed", t.Name)
end

cmds.TeleportToLobby = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local spawn = workspace:FindFirstChild("LobbySpawn") or workspace:FindFirstChild("SpawnLocation")
	local r = hrp(t)
	if spawn and r then r.CFrame = spawn.CFrame + Vector3.new(0, 5, 0) end
	print("?? ADMIN:", a.Name, "TP'd", t.Name, "to lobby")
end

cmds.TeleportToMe = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local ar, tr = hrp(a), hrp(t)
	if ar and tr then tr.CFrame = ar.CFrame * CFrame.new(0, 0, -5) end
	print("?? ADMIN:", a.Name, "TP'd", t.Name, "to self")
end

cmds.LaunchPlayer = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local r = hrp(t)
	if r then
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(0, math.huge, 0)
		bv.Velocity = Vector3.new(0, 200, 0)
		bv.Parent = r
		Debris:AddItem(bv, 0.5)
	end
	print("?? ADMIN:", a.Name, "launched", t.Name)
end

cmds.FreezePlayer = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local h = hum(t)
	if h then h.WalkSpeed = 0; h.JumpPower = 0 end
	local r = hrp(t)
	if r then r.Anchored = true end
	print("?? ADMIN:", a.Name, "froze", t.Name)
end

cmds.UnfreezePlayer = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local h = hum(t)
	if h then h.WalkSpeed = 16; h.JumpPower = 50 end
	local r = hrp(t)
	if r then r.Anchored = false end
	print("?? ADMIN:", a.Name, "unfroze", t.Name)
end

cmds.KickPlayer = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	if t == a then return msg(a, "Can't kick yourself!") end
	t:Kick("Kicked by admin")
	print("?? ADMIN:", a.Name, "kicked", t.Name)
end

-- ECONOMY
cmds.AddCoins = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local ls = t:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Coins") then
		ls.Coins.Value = ls.Coins.Value + (d.amount or 0)
	end
	print("?? ADMIN:", a.Name, "added", d.amount, "coins to", t.Name)
end

cmds.SetCoins = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local ls = t:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Coins") then
		ls.Coins.Value = d.amount or 0
	end
	print("?? ADMIN:", a.Name, "set", t.Name, "coins to", d.amount)
end

cmds.AddWins = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local ls = t:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Wins") then
		ls.Wins.Value = ls.Wins.Value + (d.amount or 0)
	end
	print("?? ADMIN:", a.Name, "added", d.amount, "wins to", t.Name)
end

cmds.GiveWeapon = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local folders = {ReplicatedStorage:FindFirstChild("Tools"), ServerStorage:FindFirstChild("Tools")}
	for _, folder in pairs(folders) do
		if folder then
			local tool = folder:FindFirstChild(d.weapon)
			if tool then
				tool:Clone().Parent = t.Backpack
				print("?? ADMIN:", a.Name, "gave", d.weapon, "to", t.Name)
				return
			end
		end
	end
	msg(a, "Weapon not found: " .. (d.weapon or "nil"))
end

cmds.GiveAllWeapons = function(a, d)
	local t = find(d.target)
	if not t then return msg(a, "Player not found!") end
	local folders = {ReplicatedStorage:FindFirstChild("Tools"), ServerStorage:FindFirstChild("Tools")}
	local count = 0
	for _, folder in pairs(folders) do
		if folder then
			for _, tool in pairs(folder:GetChildren()) do
				if tool:IsA("Tool") then
					local has = false
					for _, existing in pairs(t.Backpack:GetChildren()) do
						if existing.Name == tool.Name then has = true; break end
					end
					if not has then
						tool:Clone().Parent = t.Backpack
						count = count + 1
					end
				end
			end
		end
	end
	msg(a, "Gave " .. count .. " weapons!")
	print("?? ADMIN:", a.Name, "gave all weapons to", t.Name, "(" .. count .. ")")
end

-- GAME
cmds.SkipToRound = function(a, d)
	if _G.SkipIntermission then
		_G.SkipIntermission()
	else
		msg(a, "SkipIntermission not set up in GameManager")
	end
	print("?? ADMIN:", a.Name, "skip to round")
end

cmds.EndRound = function(a, d)
	if _G.EndRound then
		_G.EndRound()
	else
		msg(a, "EndRound not set up in GameManager")
	end
	print("?? ADMIN:", a.Name, "end round")
end

cmds.CleanupEffects = function(a, d)
	local count = 0
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj.Name == "RangeIndicator" or obj.Name == "AcidPuddle" or obj.Name == "IceSphere" or obj.Name == "PushRadius" then
			obj:Destroy()
			count = count + 1
		end
	end
	msg(a, "Cleaned " .. count .. " effects")
	print("?? ADMIN:", a.Name, "cleaned", count, "effects")
end

cmds.RespawnAll = function(a, d)
	for _, p in pairs(Players:GetPlayers()) do p:LoadCharacter() end
	print("?? ADMIN:", a.Name, "respawned all")
end

cmds.TeleportAllToLobby = function(a, d)
	local spawn = workspace:FindFirstChild("LobbySpawn") or workspace:FindFirstChild("SpawnLocation")
	if spawn then
		for _, p in pairs(Players:GetPlayers()) do
			local r = hrp(p)
			if r then r.CFrame = spawn.CFrame + Vector3.new(math.random(-5,5), 5, math.random(-5,5)) end
		end
	end
	print("?? ADMIN:", a.Name, "TP'd all to lobby")
end

cmds.SpeedBoostAll = function(a, d)
	for _, p in pairs(Players:GetPlayers()) do
		local h = hum(p)
		if h then
			local orig = h.WalkSpeed
			h.WalkSpeed = orig * 2
			task.delay(10, function()
				if h and h.Parent then h.WalkSpeed = orig end
			end)
		end
	end
	msg(a, "Speed boost 10s!")
	print("?? ADMIN:", a.Name, "speed boost all")
end

cmds.KillAll = function(a, d)
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= a then
			local h = hum(p)
			if h then h.Health = 0 end
		end
	end
	print("?? ADMIN:", a.Name, "killed all")
end

cmds.GetServerStats = function(a, d)
	adminEvent:FireClient(a, "ServerStats", {
		players = #Players:GetPlayers(),
		uptime = math.floor(workspace.DistributedGameTime),
		roundActive = _G.IsRoundActive and _G.IsRoundActive() or false,
		memory = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb()),
	})
	print("?? ADMIN:", a.Name, "requested stats")
end

-- ============================================
-- HANDLER
-- ============================================
adminEvent.OnServerEvent:Connect(function(player, command, data)
	if not isAdmin(player) then
		warn("?? NON-ADMIN tried admin command:", player.Name, command)
		player:Kick("Unauthorized")
		return
	end

	local handler = cmds[command]
	if handler then
		local ok, err = pcall(handler, player, data or {})
		if not ok then
			warn("?? Admin error:", command, err)
			msg(player, "Error: " .. tostring(err), Color3.fromRGB(255, 50, 50))
		end
	else
		warn("?? Unknown command:", command)
		msg(player, "Unknown: " .. tostring(command))
	end
end)

print("? Admin Handler ready!")
print("   Admins: ScarletxHunterx (658326075)")
print("   Commands: " .. (function() local c=0; for _ in pairs(cmds) do c=c+1 end; return c end)())