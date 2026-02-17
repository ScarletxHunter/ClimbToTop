-- ============================================
-- GAME MANAGER - FIXED: Up to 3 winners, delayed round end
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local CONFIG = {
	IntermissionTime = 15,
	VotingTime = 30,
	RoundTime = 120,
	RoundEndTime = 10,
	MinPlayers = 1,
	MaxWinners = 3,
	WaitAfterLastWinner = 8, -- seconds to wait after 3rd winner (or any winner) before ending
}

local GameValues = ReplicatedStorage:WaitForChild("GameValues")
local GameState = GameValues:WaitForChild("GameState")
local Timer = GameValues:WaitForChild("Timer")
local CurrentMap = GameValues:WaitForChild("CurrentMap")

local VotingSystem = require(script.Parent:WaitForChild("VotingSystem"))
local MapLoader = require(script.Parent:WaitForChild("MapLoader"))
local ObjectSpawner = require(script.Parent:WaitForChild("ObjectSpawner"))
local CoinSpawner = require(script.Parent:WaitForChild("CoinSpawner"))
local SoundManager = require(script.Parent:WaitForChild("SoundManager"))
local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))

local function dbgCoin(hId, loc, msg, data)
	-- Debug logging (print only, no HTTP)
end

local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local TransitionEvent = RemoteEventsFolder:WaitForChild("TransitionEvent")
local WinEvent = RemoteEventsFolder:WaitForChild("PlayerWon")

local WinDisplayEvent
if not ReplicatedStorage:FindFirstChild("WinDisplayEvent") then
	WinDisplayEvent = Instance.new("RemoteEvent")
	WinDisplayEvent.Name = "WinDisplayEvent"
	WinDisplayEvent.Parent = ReplicatedStorage
else
	WinDisplayEvent = ReplicatedStorage.WinDisplayEvent
end

if not ReplicatedStorage:FindFirstChild("UpdateVoteHud") then
	local e = Instance.new("RemoteEvent")
	e.Name = "UpdateVoteHud"
	e.Parent = ReplicatedStorage
end

-- State
local roundActive = false
local lateJoiners = {} -- tracks players who joined mid-round
local winners = {}      -- list of winner players (up to 3)
local roundStartTime = 0
local winConnection = nil

-- Admin hooks for round control
_G.AdminEndRound = function()
	roundActive = false
	_G.AdminForceEndRound = true
	print("? Admin: Ending round via hook")
end

_G.AdminSkipRound = function()
	_G.AdminSetTimer = 1
	print("? Admin: Skipping round via hook")
end
-- ============================================
-- START LOCATIONS
-- ============================================

local function getStartLocations()
	local locations = {}
	for _, child in pairs(workspace:GetChildren()) do
		if child:IsA("BasePart") and child.Name:match("^StartHere%d*$") then
			table.insert(locations, child)
		end
	end
	if #locations == 0 then
		local single = workspace:FindFirstChild("StartHere")
		if single then table.insert(locations, single) end
	end
	return locations
end

-- ============================================
-- TELEPORTATION
-- ============================================

local function teleportPlayerToLobby(plr)
	if not plr.Character then return end
	local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	-- Find SpawnLocation (real SpawnLocation class first, then any Part named SpawnLocation)
	local spawn = nil
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("SpawnLocation") then
			spawn = obj
			break
		end
	end
	if not spawn then
		spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("SpawnLocationPart_OLD")
	end
	if spawn then
		hrp.CFrame = spawn.CFrame + Vector3.new(math.random(-5, 5), 5, math.random(-5, 5))
	else
		-- Fallback to hardcoded lobby position
		hrp.CFrame = CFrame.new(-765 + math.random(-5, 5), 9, -717 + math.random(-5, 5))
	end
end

local function teleportPlayersToLobby()
	for _, plr in pairs(Players:GetPlayers()) do
		teleportPlayerToLobby(plr)
	end
	print("?? Teleported all players to lobby")
end

local function teleportPlayersToRoundStart()
	local startLocations = getStartLocations()
	if #startLocations == 0 then
		warn("?? No StartHere parts found!")
		return
	end
	local allPlayers = Players:GetPlayers()
	for i, plr in ipairs(allPlayers) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local startPart = startLocations[((i - 1) % #startLocations) + 1]
			local offset = Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))
			plr.Character.HumanoidRootPart.CFrame = startPart.CFrame * CFrame.new(offset)
		end
	end
	print("? Teleported", #allPlayers, "players across", #startLocations, "start location(s)")
end

-- ============================================
-- TIMER
-- ============================================

local function startTimer(duration, stateName)
	GameState.Value = stateName
	Timer.Value = duration
	for i = duration, 0, -1 do
		Timer.Value = i
		task.wait(1)
	end
end

local function enoughPlayers()
	return #Players:GetPlayers() >= CONFIG.MinPlayers
end

-- ============================================
-- PLAYER SPAWN HANDLING
-- ============================================

Players.PlayerAdded:Connect(function(plr)
	-- Mark as late joiner if round is active
	if GameState.Value == "Playing" then
		lateJoiners[plr.UserId] = true
		print("?? " .. plr.Name .. " joined mid-round, will spawn in lobby")
	end

	plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		if GameState.Value == "Playing" then
			if lateJoiners[plr.UserId] then
				-- NEW player who joined mid-round ? lobby
				teleportPlayerToLobby(plr)
				print("?? Late joiner " .. plr.Name .. " sent to lobby")
			else
				-- EXISTING player who reset ? back to map start
				local startLocations = getStartLocations()
				if #startLocations > 0 and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local randomStart = startLocations[math.random(1, #startLocations)]
					local offset = Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))
					plr.Character.HumanoidRootPart.CFrame = randomStart.CFrame * CFrame.new(offset)
					print("?? " .. plr.Name .. " reset ? back to map start")
				end
			end
		else
			-- Not in round - make sure player is in lobby
			teleportPlayerToLobby(plr)
		end
	end)
end)

-- ============================================
-- RANK TEXT FOR WINNERS
-- ============================================

local function getPlaceText(place)
	if place == 1 then return "1st"
	elseif place == 2 then return "2nd"
	elseif place == 3 then return "3rd"
	else return tostring(place) .. "th" end
end

-- ============================================
-- WIN DETECTION (up to 3 winners)
-- ============================================

local function setupWinDetection()
	if winConnection then
		winConnection:Disconnect()
		winConnection = nil
	end

	local endPart = workspace:FindFirstChild("End")
	if not endPart then
		warn("?? No 'End' part found!")
		return
	end

	winConnection = endPart.Touched:Connect(function(hit)
		if not roundActive then return end

		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if not plr then return end

		-- Check if this player already won
		for _, w in ipairs(winners) do
			if w.Player == plr then return end
		end

		-- Check max winners
		if #winners >= CONFIG.MaxWinners then return end

		local timeTaken = math.floor(tick() - roundStartTime)
		local place = #winners + 1

		table.insert(winners, { Player = plr, Time = timeTaken, Place = place })

		print("??", getPlaceText(place), "PLACE:", plr.Name, "Time:", timeTaken, "seconds")

		-- Record stats
		if place == 1 then
			PlayerDataManager.RecordWin(plr, timeTaken)
		end

		-- Award coins based on place
		local coinRewards = { 150, 100, 75 }
		local reward = coinRewards[place] or 50
		local multiplier = 1.0
		if _G.GetCoinMultiplier then
			multiplier = _G.GetCoinMultiplier(plr)
		end
		reward = math.floor(reward * multiplier)

		if _G.UpdatePlayerCoins then
			_G.UpdatePlayerCoins(plr, reward)
		end
		print("??", plr.Name, "earned", reward, "coins! (" .. getPlaceText(place) .. " place)")

		-- Notify winner personally (shows first)
		WinEvent:FireClient(plr)

		-- Show winner card to ALL players (delayed so personal shows first)
		task.delay(3, function()
			WinDisplayEvent:FireAllClients(plr.Name, plr.UserId, timeTaken, place)
		end)

		SoundManager.PlaySFXForAll("WinFanfare")

		-- If 3rd winner, start countdown to end round
		if #winners >= CONFIG.MaxWinners then
			print("?? All", CONFIG.MaxWinners, "winners found! Ending round in", CONFIG.WaitAfterLastWinner, "seconds...")
			task.delay(CONFIG.WaitAfterLastWinner, function()
				roundActive = false
			end)
		end
	end)
end

-- ============================================
-- PHASES
-- ============================================

local function safeCoinStop()
	local ok, err = pcall(function() CoinSpawner.StopSpawning() end)
	if not ok then warn("[DBG-ROUND] CoinSpawner.StopSpawning error:", err) end
end

local function safeObjStop()
	local ok, err = pcall(function() ObjectSpawner.StopSpawning() end)
	if not ok then warn("[DBG-ROUND] ObjectSpawner.StopSpawning error:", err) end
end

local function intermissionPhase()
	print("? INTERMISSION PHASE")
	print("[DBG-ROUND] intermissionPhase START")
	lateJoiners = {} -- clear late joiners for new round
	MapLoader.UnloadMap()
	safeObjStop()
	safeCoinStop()
	winners = {}
	roundActive = false

	pcall(function() if _G.ResetCoinTrails then _G.ResetCoinTrails() end end)

	teleportPlayersToLobby()
	SoundManager.PlayMusic("MenuMusic")

	startTimer(CONFIG.IntermissionTime, "Intermission")
	print("[DBG-ROUND] intermissionPhase END")
end

local function votingPhase()
	print("??? VOTING PHASE")
	print("[DBG-ROUND] votingPhase START")
	VotingSystem.StartVoting()

	startTimer(CONFIG.VotingTime, "Voting")

	VotingSystem.StopVoting()

	local winningMap = VotingSystem.GetWinner()
	CurrentMap.Value = winningMap
	print("??? Winning map:", winningMap)
	print("[DBG-ROUND] votingPhase END | map:", winningMap)

	return winningMap
end

local function roundPhase(mapName)
	print("?? ROUND PHASE - Loading map:", mapName)
	print("[DBG-ROUND] roundPhase START | map:", mapName)

	-- Fade to black
	SoundManager.PlaySFXForAll("Transition")
	for _, plr in pairs(Players:GetPlayers()) do
		TransitionEvent:FireClient(plr, "FadeIn", 1.5)
	end
	task.wait(2)

	print("[DBG-ROUND] Loading map...")
	local mapOk, mapErr = pcall(function()
		MapLoader.LoadMap(mapName)
	end)
	if not mapOk then
		warn("[DBG-ROUND] MapLoader.LoadMap FAILED:", mapErr)
	else
		print("[DBG-ROUND] MapLoader.LoadMap OK")
	end
	task.wait(0.5)

	teleportPlayersToRoundStart()

	task.wait(3)

	GameState.Value = "Playing"
	Timer.Value = CONFIG.RoundTime
	roundActive = true
	roundStartTime = tick()
	winners = {}
	print("[DBG-ROUND] GameState=Playing | Timer=", CONFIG.RoundTime, "| roundActive=true")

	setupWinDetection()

	SoundManager.PlaySFXForAll("RoundStart")
	for _, plr in pairs(Players:GetPlayers()) do
		TransitionEvent:FireClient(plr, "FadeOut", 1.5)
	end
	task.wait(2)

	local musicName = "Map1Music"
	if mapName:lower():find("2") then musicName = "Map2Music"
	elseif mapName:lower():find("3") then musicName = "Map3Music" end
	SoundManager.PlayMusic(musicName)

	print("[DBG-ROUND] Starting ObjectSpawner...")
	local okObj, errObj = pcall(function()
		ObjectSpawner.StartSpawning(mapName)
	end)
	if not okObj then
		warn("[DBG-ROUND] ObjectSpawner.StartSpawning FAILED:", errObj)
	else
		print("[DBG-ROUND] ObjectSpawner.StartSpawning OK")
	end

	print("[DBG-ROUND] Starting CoinSpawner...")
	local okCoin, errCoin = pcall(function()
		CoinSpawner.StartSpawning(mapName)
	end)
	if not okCoin then
		warn("[DBG-ROUND] CoinSpawner.StartSpawning FAILED:", errCoin)
	else
		print("[DBG-ROUND] CoinSpawner.StartSpawning OK")
	end

	-- Timer countdown - also check if roundActive was set to false by win detection
	print("[DBG-ROUND] Entering timer loop | RoundTime=", CONFIG.RoundTime)
	for i = CONFIG.RoundTime, 0, -1 do
		if not roundActive then
			print("[DBG-ROUND] Timer loop EXIT: roundActive=false at i=", i)
			break
		end

		-- Admin override: force end round
		if _G.AdminForceEndRound then
			_G.AdminForceEndRound = nil
			roundActive = false
			print("? Admin forced round end")
			break
		end

		-- Admin override: jump timer to a specific value
		if _G.AdminSetTimer then
			i = _G.AdminSetTimer
			_G.AdminSetTimer = nil
			print("? Admin set timer to " .. i)
		end

		Timer.Value = i

		-- Log every 30 seconds to track progress
		if i % 30 == 0 then
			print("[DBG-ROUND] Timer tick | i=", i, "| roundActive=", roundActive, "| winners=", #winners)
		end

		if i <= 3 and i > 0 then
			SoundManager.PlaySFXForAll("Countdown")
		end

		task.wait(1)
	end

	print("[DBG-ROUND] Timer loop DONE | roundActive=", roundActive)

	-- If round ended by timer (not by winners), wait a moment
	if roundActive then
		roundActive = false
	end

	print("[DBG-ROUND] Stopping spawners...")
	safeObjStop()
	safeCoinStop()

	if winConnection then
		winConnection:Disconnect()
		winConnection = nil
	end
	print("[DBG-ROUND] roundPhase END")
end

local function roundEndPhase()
	print("?? ROUND END PHASE")
	print("[DBG-ROUND] roundEndPhase START")
	roundActive = false
	safeObjStop()
	safeCoinStop()

	-- Award coins based on placement for non-winners
	local winnerSet = {}
	for _, w in ipairs(winners) do
		winnerSet[w.Player.UserId] = true
	end

	local playerProgress = {}
	local playersAwarded = {}
	for _, plr in pairs(Players:GetPlayers()) do
		PlayerDataManager.RecordGame(plr)

		-- Skip winners (they already got coins)
		if winnerSet[plr.UserId] then continue end

		local character = plr.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local startPartRef = workspace:FindFirstChild("Start")
			local endPartRef = workspace:FindFirstChild("End")

			if hrp and startPartRef and endPartRef then
				local sY = startPartRef.Position.Y
				local eY = endPartRef.Position.Y
				local dist = eY - sY
				if dist == 0 then dist = 0.0001 end
				local progress = math.clamp(((hrp.Position.Y - sY) / dist) * 100, 0, 100)

				table.insert(playerProgress, { Player = plr, Progress = progress })
			end
		end
	end

	table.sort(playerProgress, function(a, b) return a.Progress > b.Progress end)

	for rank, data in ipairs(playerProgress) do
		local plr = data.Player
		local progress = data.Progress
		local coinReward = 0

		if progress >= 75 then
			coinReward = 30
		elseif progress >= 50 then
			coinReward = 20
		elseif progress >= 25 then
			coinReward = 10
		else
			coinReward = 5
		end

		local multiplier = 1.0
		if _G.GetCoinMultiplier then
			multiplier = _G.GetCoinMultiplier(plr)
		end
		coinReward = math.floor(coinReward * multiplier)

		if _G.UpdatePlayerCoins then
			_G.UpdatePlayerCoins(plr, coinReward)
		end
		print("??", plr.Name, "earned", coinReward, "coins! (" .. math.floor(progress) .. "%)")
	end

	if #winners > 0 then
		local winnerNames = {}
		for _, w in ipairs(winners) do
			table.insert(winnerNames, w.Player.Name)
		end
		print("?? Winners:", table.concat(winnerNames, ", "))
		SoundManager.PlayMusic("VictoryMusic")
	else
		print("? Time's up! No winners.")
		SoundManager.StopMusic()
	end

	startTimer(CONFIG.RoundEndTime, "RoundEnd")
	teleportPlayersToLobby()
	print("[DBG-ROUND] roundEndPhase END")
end

-- ============================================
-- MAIN GAME LOOP
-- ============================================

local function gameLoop()
	local loopCount = 0
	while true do
		loopCount = loopCount + 1
		print("[DBG-ROUND] === GAME LOOP ITERATION", loopCount, "===")

		repeat
			print("? Waiting for players... (" .. #Players:GetPlayers() .. "/" .. CONFIG.MinPlayers .. ")")
			task.wait(2)
		until enoughPlayers()

		print("[DBG-ROUND] Enough players! Starting round cycle...")
		local phaseOk, phaseErr = pcall(function()
			intermissionPhase()
		end)
		if not phaseOk then
			warn("[DBG-ROUND] intermissionPhase CRASHED:", phaseErr)
		end

		local mapName
		phaseOk, phaseErr = pcall(function()
			mapName = votingPhase()
		end)
		if not phaseOk then
			warn("[DBG-ROUND] votingPhase CRASHED:", phaseErr)
			mapName = "DefaultMap"
		end

		phaseOk, phaseErr = pcall(function()
			roundPhase(mapName)
		end)
		if not phaseOk then
			warn("[DBG-ROUND] roundPhase CRASHED:", phaseErr)
		end

		phaseOk, phaseErr = pcall(function()
			roundEndPhase()
		end)
		if not phaseOk then
			warn("[DBG-ROUND] roundEndPhase CRASHED:", phaseErr)
		end

		print("[DBG-ROUND] === GAME LOOP ITERATION", loopCount, "COMPLETE ===")
	end
end

print("?? GAME MANAGER STARTED")
gameLoop()