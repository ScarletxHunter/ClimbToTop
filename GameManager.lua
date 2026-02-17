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
	-- #region agent log
	pcall(function()
		HttpService:PostAsync(
			"http://127.0.0.1:7243/ingest/f4b63b01-cff3-4a42-b344-cb9c3aec0ae1",
			HttpService:JSONEncode({
				runId = "coin_spawner_debug",
				hypothesisId = hId,
				location = loc,
				message = msg,
				data = data or {},
				timestamp = DateTime.now().UnixTimestampMillis,
			}),
			Enum.HttpContentType.ApplicationJson
		)
	end)
	-- #endregion
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
local roundEndTriggered = false

-- ============================================
-- START LOCATIONS
-- ============================================

local function getStartLocations()
	local starts = {}
	for _, obj in pairs(workspace:GetDescendants()) do
		-- Match parts named "Start" OR starting with "StartHere"
		if obj:IsA("BasePart") and (obj.Name == "Start" or string.sub(obj.Name, 1, 9) == "StartHere") then
			table.insert(starts, obj)
		end
	end
	
	if #starts == 0 then
		warn("⚠️ No 'Start' parts found in workspace! Players may spawn incorrectly.")
	end
	
	return starts
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
		warn("⚠️ No start locations found! Teleporting to lobby instead.")
		teleportPlayersToLobby()
		return
	end
	
	local allPlayers = {}
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(allPlayers, plr)
		end
	end

	for i, plr in ipairs(allPlayers) do
		local startPart = startLocations[((i - 1) % #startLocations) + 1]
		local offset = Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))
		plr.Character.HumanoidRootPart.CFrame = startPart.CFrame * CFrame.new(offset)
	end
	print("✅ Teleported", #allPlayers, "players across", #startLocations, "start location(s)")
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
	-- Mark as late joiner if round is active OR voting
	if GameState.Value == "Playing" or GameState.Value == "Voting" then
		lateJoiners[plr.UserId] = true
		print("⏸️ " .. plr.Name .. " joined during " .. GameState.Value .. ", will spawn in lobby")
	end

	plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		if GameState.Value == "Playing" then
			if lateJoiners[plr.UserId] then
				-- NEW player who joined mid-round ? lobby
				teleportPlayerToLobby(plr)
				print("?? Late joiner " .. plr.Name .. " sent to lobby")
			else
				-- EXISTING player who reset → back to map start
				local startLocations = getStartLocations()
				if #startLocations > 0 and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local randomStart = startLocations[math.random(1, #startLocations)]
					local offset = Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))
					plr.Character.HumanoidRootPart.CFrame = randomStart.CFrame * CFrame.new(offset)
					print("🔄 " .. plr.Name .. " reset → back to map start")
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

local function intermissionPhase()
	print("🏠 INTERMISSION PHASE")

	-- Only clear lateJoiners who have left the game
	local currentPlayers = {}
	for _, plr in pairs(Players:GetPlayers()) do
		currentPlayers[plr.UserId] = true
	end
	
	for userId, _ in pairs(lateJoiners) do
		if not currentPlayers[userId] then
			lateJoiners[userId] = nil
			print("🧹 Removed late joiner who left: UserID " .. userId)
		end
	end
	
	-- Clear winners and reset state
	MapLoader.UnloadMap()
	ObjectSpawner.StopSpawning()
	CoinSpawner.StopSpawning()
	winners = {}
	roundActive = false
	roundEndTriggered = false

	if _G.ResetCoinTrails then _G.ResetCoinTrails() end

	teleportPlayersToLobby()
	SoundManager.PlayMusic("MenuMusic")

	startTimer(CONFIG.IntermissionTime, "Intermission")
end

local function votingPhase()
	print("??? VOTING PHASE")
	VotingSystem.StartVoting()

	startTimer(CONFIG.VotingTime, "Voting")

	VotingSystem.StopVoting()

	local winningMap = VotingSystem.GetWinner()
	CurrentMap.Value = winningMap
	print("??? Winning map:", winningMap)

	return winningMap
end

local function roundPhase(mapName)
	print("🏁 ROUND PHASE - Loading map:", mapName)

	-- Clear late joiners from previous round (players are ready for new round)
	lateJoiners = {}
	print("✅ Late joiners cleared before round starts")

	-- Fade to black
	SoundManager.PlaySFXForAll("Transition")
	for _, plr in pairs(Players:GetPlayers()) do
		TransitionEvent:FireClient(plr, "FadeIn", 1.5)
	end
	task.wait(2)

	MapLoader.LoadMap(mapName)
	task.wait(0.5)

	teleportPlayersToRoundStart()

	task.wait(3)

	GameState.Value = "Playing"
	roundActive = true
	roundStartTime = tick()
	winners = {}

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

	ObjectSpawner.StartSpawning(mapName)
	dbgCoin("H_GM_COIN_CALL", "GameManager:roundPhase", "About to call CoinSpawner.StartSpawning", {
		mapName = mapName,
		gameState = GameState.Value,
	})
	local okCoin, errCoin = pcall(function()
		CoinSpawner.StartSpawning(mapName)
	end)
	dbgCoin("H_GM_COIN_CALL", "GameManager:roundPhase", "CoinSpawner.StartSpawning result", {
		ok = okCoin,
		err = errCoin,
	})
	if not okCoin then
		warn("CoinSpawner.StartSpawning failed:", errCoin)
	end

	-- Timer countdown - also check if roundActive was set to false by win detection
	Timer.Value = CONFIG.RoundTime
	for i = CONFIG.RoundTime, 0, -1 do
		if not roundActive then break end

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

		if i <= 3 and i > 0 then
			SoundManager.PlaySFXForAll("Countdown")
		end

		task.wait(1)
	end

	-- If round ended by timer (not by winners), wait a moment
	if roundActive then
		roundActive = false
	end

	ObjectSpawner.StopSpawning()
	CoinSpawner.StopSpawning()

	if winConnection then
		winConnection:Disconnect()
		winConnection = nil
	end
end

local function roundEndPhase()
	print("?? ROUND END PHASE")
	roundActive = false
	ObjectSpawner.StopSpawning()
	CoinSpawner.StopSpawning()

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
end

-- ============================================
-- MAIN GAME LOOP
-- ============================================

local function gameLoop()
	while true do
		repeat
			print("⏳ Waiting for players... (" .. #Players:GetPlayers() .. "/" .. CONFIG.MinPlayers .. ")")
			task.wait(2)
		until enoughPlayers()

		-- Recheck before starting intermission
		if not enoughPlayers() then 
			print("⚠️ Not enough players, restarting wait...")
			continue 
		end
		
		intermissionPhase()
		
		-- Recheck after intermission before voting
		if not enoughPlayers() then 
			print("⚠️ Not enough players after intermission, restarting...")
			continue 
		end
		
		local mapName = votingPhase()
		
		-- Recheck before round starts
		if not enoughPlayers() then 
			print("⚠️ Not enough players after voting, restarting...")
			continue 
		end
		
		roundPhase(mapName)
		roundEndPhase()
	end
end

print("?? GAME MANAGER STARTED")
gameLoop()