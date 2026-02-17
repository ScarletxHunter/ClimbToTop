-- ============================================
-- ULTIMATE DEBUGGER - Paste this into Studio Command Bar
-- Diagnoses: Round system, CoinSpawner, Timer, TrailShop
-- ============================================

print("\n")
print("==============================================")
print("   RUNTTOTOP ULTIMATE DIAGNOSTIC")
print("==============================================\n")

local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local WS = workspace

local errors = {}
local warnings = {}
local info = {}

local function addError(msg) table.insert(errors, "ERROR: " .. msg) end
local function addWarn(msg) table.insert(warnings, "WARN: " .. msg) end
local function addInfo(msg) table.insert(info, "OK: " .. msg) end

-- ============================================
-- 1. CHECK GAME VALUES
-- ============================================
print("--- 1. GAME VALUES ---")
local GV = RS:FindFirstChild("GameValues")
if not GV then
	addError("ReplicatedStorage.GameValues MISSING! Round system cannot work.")
else
	addInfo("GameValues exists")
	local GS = GV:FindFirstChild("GameState")
	local TM = GV:FindFirstChild("Timer")
	local CM = GV:FindFirstChild("CurrentMap")
	if not GS then addError("GameValues.GameState MISSING") else addInfo("GameState = '" .. GS.Value .. "'") end
	if not TM then addError("GameValues.Timer MISSING") else addInfo("Timer = " .. TM.Value) end
	if not CM then addError("GameValues.CurrentMap MISSING") else addInfo("CurrentMap = '" .. CM.Value .. "'") end
end

-- ============================================
-- 2. CHECK REMOTE EVENTS
-- ============================================
print("\n--- 2. REMOTE EVENTS ---")
local RE = RS:FindFirstChild("RemoteEvents")
if not RE then
	addError("ReplicatedStorage.RemoteEvents MISSING!")
else
	addInfo("RemoteEvents folder exists")
	local requiredRemotes = {"TransitionEvent", "PlayerWon", "TrailEquip", "TrailUpdate", "GetTrailShopData", "NotifyClient"}
	for _, name in ipairs(requiredRemotes) do
		local r = RE:FindFirstChild(name)
		if not r then addWarn("Remote '" .. name .. "' MISSING in RemoteEvents") else addInfo("Remote '" .. name .. "' exists (" .. r.ClassName .. ")") end
	end
end

local WDE = RS:FindFirstChild("WinDisplayEvent")
if not WDE then addWarn("WinDisplayEvent MISSING in ReplicatedStorage") else addInfo("WinDisplayEvent exists") end

local UC = RS:FindFirstChild("UpdateCoins")
if not UC then addWarn("UpdateCoins RemoteEvent MISSING") else addInfo("UpdateCoins exists") end

local GC = RS:FindFirstChild("GetCoins")
if not GC then addWarn("GetCoins RemoteFunction MISSING") else addInfo("GetCoins exists") end

-- ============================================
-- 3. CHECK SERVER SCRIPTS
-- ============================================
print("\n--- 3. SERVER SCRIPTS ---")
local gameScripts = SSS:FindFirstChild("GameScripts")
if not gameScripts then
	addError("ServerScriptService.GameScripts MISSING! No game logic will run.")
else
	addInfo("GameScripts folder exists")
	local requiredModules = {"GameManager", "VotingSystem", "MapLoader", "ObjectSpawner", "CoinSpawner", "SoundManager", "PlayerDataManager"}
	for _, name in ipairs(requiredModules) do
		local m = gameScripts:FindFirstChild(name)
		if not m then
			addError("Module '" .. name .. "' MISSING from GameScripts!")
		else
			addInfo("Module '" .. name .. "' exists (" .. m.ClassName .. ")")
		end
	end
end

-- ============================================
-- 4. CHECK MAPS
-- ============================================
print("\n--- 4. MAPS ---")
local mapsFolder = SS:FindFirstChild("Maps")
if not mapsFolder then
	addError("ServerStorage.Maps MISSING! No maps to play.")
else
	local mapNames = {}
	for _, m in pairs(mapsFolder:GetChildren()) do
		if m:IsA("Folder") then
			table.insert(mapNames, m.Name)
			-- Check required parts in each map
			local props = m:FindFirstChild("Props")
			local hasStart, hasEnd, hasStartHere, hasSpawners, hasCoinsMan, hasCoinTemplate = false, false, false, false, false, false
			local hasFallingObjects = m:FindFirstChild("FallingObjects") ~= nil

			if props then
				for _, p in pairs(props:GetChildren()) do
					if p.Name == "Start" then hasStart = true end
					if p.Name == "End" then hasEnd = true end
					if p.Name:match("^StartHere") then hasStartHere = true end
					if p.Name == "Spawners" then hasSpawners = true end
					if p.Name == "CoinsMan" then hasCoinsMan = true end
					if p.Name == "CoinTemplate" then hasCoinTemplate = true end
				end
			end
			-- Also check map root for CoinsMan/CoinTemplate
			if not hasCoinsMan and m:FindFirstChild("CoinsMan") then hasCoinsMan = true end
			if not hasCoinTemplate and m:FindFirstChild("CoinTemplate") then hasCoinTemplate = true end
			-- Check descendants too
			if not hasCoinTemplate then
				for _, d in pairs(m:GetDescendants()) do
					if d.Name == "CoinTemplate" then hasCoinTemplate = true break end
				end
			end

			local mapStatus = m.Name .. ": "
			if not hasStart then mapStatus = mapStatus .. "[NO Start] " addWarn(m.Name .. " missing 'Start' part") end
			if not hasEnd then mapStatus = mapStatus .. "[NO End] " addWarn(m.Name .. " missing 'End' part") end
			if not hasStartHere then mapStatus = mapStatus .. "[NO StartHere] " addWarn(m.Name .. " missing 'StartHere' parts") end
			if not hasSpawners then mapStatus = mapStatus .. "[NO Spawners] " addWarn(m.Name .. " missing 'Spawners' folder") end
			if not hasFallingObjects then mapStatus = mapStatus .. "[NO FallingObjects] " addWarn(m.Name .. " missing 'FallingObjects'") end
			if not hasCoinsMan then mapStatus = mapStatus .. "[NO CoinsMan] " addError(m.Name .. " missing 'CoinsMan' - COINS WON'T SPAWN!") end
			if not hasCoinTemplate then mapStatus = mapStatus .. "[NO CoinTemplate] " addError(m.Name .. " missing 'CoinTemplate' - COINS WON'T SPAWN!") end

			if hasStart and hasEnd and hasStartHere and hasSpawners and hasFallingObjects and hasCoinsMan and hasCoinTemplate then
				addInfo(m.Name .. ": All required parts present")
			end
		end
	end
	addInfo("Available maps: " .. table.concat(mapNames, ", "))
end

-- ============================================
-- 5. CHECK WORKSPACE (DURING ROUND)
-- ============================================
print("\n--- 5. WORKSPACE STATE ---")
local wsStart = WS:FindFirstChild("Start")
local wsEnd = WS:FindFirstChild("End")
local wsCoinsMan = WS:FindFirstChild("CoinsMan")
local wsCoinTemplate = WS:FindFirstChild("CoinTemplate", true)
local wsSpawners = WS:FindFirstChild("Spawners")
local wsMapContainer = WS:FindFirstChild("MapContainer")
local wsVoting = WS:FindFirstChild("Voting")
local wsActiveCoinsCont = WS:FindFirstChild("ActiveCoinsContainer")
local wsFallingObjCont = WS:FindFirstChild("FallingObjectsContainer")

if wsMapContainer then
	addInfo("MapContainer exists (" .. #wsMapContainer:GetChildren() .. " children)")
else
	addWarn("MapContainer not in Workspace")
end

if wsFallingObjCont then
	addInfo("FallingObjectsContainer exists (" .. #wsFallingObjCont:GetChildren() .. " objects)")
else
	addError("FallingObjectsContainer MISSING from Workspace!")
end

if wsActiveCoinsCont then
	addInfo("ActiveCoinsContainer exists (" .. #wsActiveCoinsCont:GetChildren() .. " coins)")
else
	addWarn("ActiveCoinsContainer not found (created at runtime)")
end

-- Check current round state
local currentState = GV and GV:FindFirstChild("GameState") and GV.GameState.Value or "UNKNOWN"
if currentState == "Playing" then
	addInfo("ROUND IS ACTIVE")
	if wsStart then addInfo("'Start' part in workspace") else addWarn("'Start' part NOT in workspace during round!") end
	if wsEnd then addInfo("'End' part in workspace") else addWarn("'End' part NOT in workspace during round!") end
	if wsCoinsMan then
		local coinPoints = 0
		for _, d in pairs(wsCoinsMan:GetDescendants()) do if d:IsA("BasePart") then coinPoints = coinPoints + 1 end end
		addInfo("CoinsMan in workspace with " .. coinPoints .. " spawn points")
	else
		addError("CoinsMan NOT in workspace during round! Coins cannot spawn!")
	end
	if wsCoinTemplate then
		addInfo("CoinTemplate found: " .. wsCoinTemplate:GetFullName())
	else
		addError("CoinTemplate NOT in workspace during round! Coins cannot spawn!")
	end
	if wsSpawners then addInfo("Spawners in workspace (" .. #wsSpawners:GetChildren() .. ")") end
else
	addInfo("Round not active (state: " .. currentState .. ")")
end

-- Count StartHere parts
local startHereCount = 0
for _, c in pairs(WS:GetChildren()) do
	if c:IsA("BasePart") and c.Name:match("^StartHere%d*$") then startHereCount = startHereCount + 1 end
end
if startHereCount > 0 then addInfo(startHereCount .. " StartHere parts in workspace") end

-- ============================================
-- 6. CHECK PLAYER DATA
-- ============================================
print("\n--- 6. PLAYER DATA ---")
for _, plr in pairs(Players:GetPlayers()) do
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then
		addError(plr.Name .. " has NO leaderstats! Coins/Wins won't display.")
	else
		local wins = ls:FindFirstChild("Wins")
		local coins = ls:FindFirstChild("Coins")
		if not wins then addError(plr.Name .. " leaderstats missing 'Wins'")
		else addInfo(plr.Name .. " Wins = " .. wins.Value) end
		if not coins then addError(plr.Name .. " leaderstats missing 'Coins'")
		else addInfo(plr.Name .. " Coins = " .. coins.Value) end
	end
end

-- ============================================
-- 7. CHECK GLOBAL FUNCTIONS
-- ============================================
print("\n--- 7. GLOBAL FUNCTIONS ---")
if _G.UpdatePlayerCoins then addInfo("_G.UpdatePlayerCoins exists") else addError("_G.UpdatePlayerCoins MISSING! CoinSpawner and GameManager can't award coins!") end
if _G.SyncPlayerCoins then addInfo("_G.SyncPlayerCoins exists") else addWarn("_G.SyncPlayerCoins missing") end
if _G.GetCoinMultiplier then addInfo("_G.GetCoinMultiplier exists") else addInfo("_G.GetCoinMultiplier not set (no multiplier)") end
if _G.ResetCoinTrails then addInfo("_G.ResetCoinTrails exists") else addWarn("_G.ResetCoinTrails missing (trail reset won't work)") end
if _G.AdminEndRound then addInfo("_G.AdminEndRound exists") else addWarn("_G.AdminEndRound missing") end
if _G.AdminSkipRound then addInfo("_G.AdminSkipRound exists") else addWarn("_G.AdminSkipRound missing") end
if _G.OnTrailEquipped then addInfo("_G.OnTrailEquipped exists") else addInfo("_G.OnTrailEquipped not set") end
if _G.AllTrailData then addInfo("_G.AllTrailData exists (" .. #_G.AllTrailData .. " trails)") else addWarn("_G.AllTrailData missing") end
if _G.AdminEquipTrail then addInfo("_G.AdminEquipTrail exists") else addWarn("_G.AdminEquipTrail missing") end

-- ============================================
-- 8. CHECK VOTING
-- ============================================
print("\n--- 8. VOTING ---")
if wsVoting then
	addInfo("Voting folder exists")
	for i = 1, 3 do
		local vo = wsVoting:FindFirstChild("VoteObject" .. i)
		if vo then
			local vp = vo:FindFirstChild("VotePart")
			if vp then addInfo("VoteObject" .. i .. " has VotePart")
			else addWarn("VoteObject" .. i .. " missing VotePart!") end
		else
			addWarn("VoteObject" .. i .. " MISSING from Voting folder")
		end
	end
else
	addError("Workspace.Voting folder MISSING! Map voting won't work.")
end

-- ============================================
-- 9. CHECK SPAWN LOCATION
-- ============================================
print("\n--- 9. SPAWN/LOBBY ---")
local hasSpawnLoc = false
for _, obj in pairs(WS:GetChildren()) do
	if obj:IsA("SpawnLocation") then hasSpawnLoc = true break end
end
if hasSpawnLoc then addInfo("SpawnLocation found in workspace")
else
	local spPart = WS:FindFirstChild("SpawnLocation") or WS:FindFirstChild("SpawnLocationPart_OLD")
	if spPart then addInfo("SpawnLocation part found (not SpawnLocation class)")
	else addWarn("No SpawnLocation found! Players will spawn at hardcoded fallback position.") end
end

-- ============================================
-- 10. SCRIPT LOAD ORDER CHECK
-- ============================================
print("\n--- 10. SCRIPT LOAD ORDER ---")
-- Check if CoinRemotes loaded (sets _G.UpdatePlayerCoins)
if _G.UpdatePlayerCoins then
	addInfo("CoinRemotes loaded successfully (set _G.UpdatePlayerCoins)")
else
	addError("CoinRemotes did NOT load! _G.UpdatePlayerCoins is nil!")
	addError("This means: GameManager requires CoinSpawner which may load BEFORE CoinRemotes")
	addError("FIX: CoinRemotes must be a Script, not a ModuleScript, and must load before GameManager calls CoinSpawner")
end

-- ============================================
-- PRINT RESULTS
-- ============================================
print("\n")
print("==============================================")
print("   DIAGNOSTIC RESULTS")
print("==============================================")

if #errors > 0 then
	print("\n??? ERRORS (" .. #errors .. "):")
	for _, e in ipairs(errors) do
		warn("  " .. e)
	end
end

if #warnings > 0 then
	print("\n?? WARNINGS (" .. #warnings .. "):")
	for _, w in ipairs(warnings) do
		warn("  " .. w)
	end
end

print("\n? INFO (" .. #info .. "):")
for _, i in ipairs(info) do
	print("  " .. i)
end

print("\n==============================================")
if #errors > 0 then
	warn("?? " .. #errors .. " ERRORS FOUND! These are likely causing your bugs.")
else
	print("? No critical errors found! Check warnings above.")
end
print("==============================================")

-- ============================================
-- BONUS: LIVE TIMER MONITOR (runs for 15 seconds)
-- ============================================
print("\n--- LIVE TIMER MONITOR (15 sec) ---")
print("Watching Timer.Value changes for 15 seconds...")
local timerVal = GV and GV:FindFirstChild("Timer")
if timerVal then
	task.spawn(function()
		local lastVal = timerVal.Value
		for sec = 1, 15 do
			task.wait(1)
			local newVal = timerVal.Value
			local gsVal = GV:FindFirstChild("GameState") and GV.GameState.Value or "?"
			if newVal ~= lastVal then
				print("[TIMER MONITOR] sec=" .. sec .. " | Timer: " .. lastVal .. " -> " .. newVal .. " | State: " .. gsVal)
			else
				warn("[TIMER MONITOR] sec=" .. sec .. " | Timer STUCK at " .. newVal .. " | State: " .. gsVal)
			end
			lastVal = newVal
		end
		print("[TIMER MONITOR] Done monitoring.")
	end)
else
	warn("[TIMER MONITOR] Cannot monitor - Timer value not found!")
end
