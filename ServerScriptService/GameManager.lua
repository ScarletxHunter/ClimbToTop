-- ============================================
-- GAME MANAGER (Unlimited Placement Finishers)
-- Place in: ServerScriptService/GameManager
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

print("?? Game Manager loading...")

for _, spawn in pairs(workspace:GetDescendants()) do
	if spawn:IsA("SpawnLocation") then
		spawn.Enabled = false
		spawn.Duration = 0
	end
end
print("?? Disabled all default spawn locations - GameManager controls spawning")

local MapLoader = require(script.Parent:WaitForChild("MapLoader"))
local VotingSystem = require(script.Parent:WaitForChild("VotingSystem"))
local CoinManager = require(script.Parent:WaitForChild("CoinManager"))
local SoundManager = require(script.Parent:WaitForChild("SoundManager"))
local ObjectSpawner = require(script.Parent:WaitForChild("ObjectSpawner"))

print("? Core modules loaded")

-- ============================================
-- ADMIN HOOKS (Skip Intermission / End Round)
-- ============================================
local skipIntermission = false
local skipVoting = false
local endRoundNow = false

_G.SkipIntermission = function()
	skipIntermission = true
	skipVoting = true
	print("?? ADMIN: Skip intermission + voting triggered!")
end

_G.EndRound = function()
	endRoundNow = true
	print("?? ADMIN: End round triggered!")
end

local GameConfig = nil

pcall(function()
	GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig", 3))
	print("? GameConfig loaded from ReplicatedStorage")
end)

if not GameConfig then
	pcall(function()
		GameConfig = require(script.Parent:WaitForChild("GameConfig", 3))
		print("? GameConfig loaded from ServerScriptService")
	end)
end

if GameConfig then
	print("?? Using GameConfig values!")
	if GameConfig.PrintConfig then
		GameConfig.PrintConfig()
	end
else
	warn("?? GameConfig not found! Using defaults.")
end

local function cfg(category, key, default)
	if GameConfig and GameConfig[category] and GameConfig[category][key] ~= nil then
		return GameConfig[category][key]
	end
	return default
end

local CONFIG = {
	IntermissionTime = cfg("Timing", "IntermissionTime", 20),
	VotingTime       = cfg("Timing", "VotingTime", 15),
	RoundTime        = cfg("Timing", "RoundTime", 120),
	RoundEndTime     = cfg("Timing", "RoundEndTime", 5),
	MinPlayers       = cfg("Timing", "MinPlayers", 1),
	WinReward           = cfg("CoinRewards", "WinReward", 500),
	SecondPlace         = cfg("CoinRewards", "SecondPlace", 250),
	ThirdPlace          = cfg("CoinRewards", "ThirdPlace", 125),
	ParticipationReward = cfg("CoinRewards", "Participation", 50),
}

print("?? Config loaded:")
print("   Intermission:", CONFIG.IntermissionTime .. "s")
print("   Voting:", CONFIG.VotingTime .. "s")
print("   Round:", CONFIG.RoundTime .. "s")
print("   MinPlayers:", CONFIG.MinPlayers)
print("   WinReward:", CONFIG.WinReward)
print("   Participation:", CONFIG.ParticipationReward)

local WinnerPodium = nil
pcall(function()
	WinnerPodium = require(script.Parent:WaitForChild("WinnerPodium"))
	print("? WinnerPodium module loaded")
end)

local currentMap = nil
local roundActive = false
local winners = {}
local lastWinners = {}
local roundStartTime = 0
local winnerTimes = {}
local lastWinnerTimes = {}
local characterConnections = {}

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name)
	local remote = remoteEvents:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteEvents
		print("? Created", name, "RemoteEvent")
	end
	return remote
end

local timerEvent = getOrCreateRemote("TimerUpdate")
local transitionEvent = getOrCreateRemote("TransitionEvent")
local showWinnerEvent = getOrCreateRemote("ShowWinner")
local showWinEvent = getOrCreateRemote("ShowWin")

-- ============================================
-- CLEANUP TOOL EFFECTS
-- ============================================

local function cleanupToolEffects()
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name == "RangeIndicator" or
			obj.Name == "PushRadius" or
			obj.Name == "IceSphere" or
			obj.Name == "AcidPuddle" or
			obj.Name == "ToolEffect" then
			obj:Destroy()
		end
	end
	print("?? Cleaned up tool effects from workspace")
end

-- ============================================
-- TELEPORT FUNCTIONS
-- ============================================

local function teleportToLobby(plr)
	if not plr then return end
	local character = plr.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid then return end

	local lobby, spawnLocation
	local attempts = 0
	repeat
		lobby = workspace:FindFirstChild("Lobby")
		spawnLocation = lobby and lobby:FindFirstChild("SpawnLocation")
		if not spawnLocation then
			task.wait(0.05)
			attempts = attempts + 1
		end
	until spawnLocation or attempts > 100

	if not spawnLocation then
		warn("?? Could not find lobby SpawnLocation!")
		return
	end

	hrp.Velocity = Vector3.new(0, 0, 0)
	hrp.RotVelocity = Vector3.new(0, 0, 0)
	hrp.Anchored = true
	hrp.CFrame = spawnLocation.CFrame * CFrame.new(math.random(-10,10), 10, math.random(-10,10))
	task.wait(0.05)
	hrp.Anchored = false
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	print("? Teleported", plr.Name, "to lobby")
end

local function teleportToMap(plr, map)
	if not plr or not map then return end
	local character = plr.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid then return end

	local spawnPoints = {}

	for _, descendant in pairs(map:GetDescendants()) do
		if descendant.Name == "StartHere" and descendant:IsA("BasePart") then
			table.insert(spawnPoints, descendant)
			print("   Found StartHere spawn point")
			break
		end
	end

	if #spawnPoints == 0 then
		local spawns = map:FindFirstChild("Spawns", true)
		if spawns then
			for _, child in pairs(spawns:GetChildren()) do
				if child:IsA("BasePart") or child:IsA("SpawnLocation") then
					table.insert(spawnPoints, child)
				end
			end
		end
	end

	if #spawnPoints == 0 then
		for _, descendant in pairs(map:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Name:match("Spawn") then
				table.insert(spawnPoints, descendant)
			end
		end
	end

	if #spawnPoints == 0 then
		for _, descendant in pairs(map:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Name == "Start" then
				table.insert(spawnPoints, descendant)
			end
		end
	end

	if #spawnPoints > 0 then
		local randomSpawn = spawnPoints[math.random(1, #spawnPoints)]
		hrp.Velocity = Vector3.new(0, 0, 0)
		hrp.RotVelocity = Vector3.new(0, 0, 0)
		hrp.Anchored = true
		hrp.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0)
		task.wait(0.05)
		hrp.Anchored = false
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		print("? Teleported", plr.Name, "to", randomSpawn.Name, "in map")
	else
		local anyPart = map:FindFirstChildWhichIsA("BasePart", true)
		if anyPart then
			hrp.Anchored = true
			hrp.CFrame = anyPart.CFrame + Vector3.new(0, 20, 0)
			task.wait(0.05)
			hrp.Anchored = false
		end
	end
end

local function teleportAllToLobby()
	for _, plr in pairs(Players:GetPlayers()) do
		task.spawn(function() teleportToLobby(plr) end)
	end
	print("?? Teleported all players to lobby")
end

local function teleportAllToMap(map)
	task.wait(0.5)
	for _, plr in pairs(Players:GetPlayers()) do
		task.spawn(function() teleportToMap(plr, map) end)
	end
	print("??? Teleported all players to map")
end

-- ============================================
-- WEAPON HELPERS
-- ============================================

local function givePushTool(plr)
	local backpack = plr:FindFirstChild("Backpack")
	if not backpack then return end
	if backpack:FindFirstChild("PushTool") then return end
	local character = plr.Character
	if character and character:FindFirstChild("PushTool") then return end
	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if toolsFolder then
		local pushTool = toolsFolder:FindFirstChild("PushTool")
		if pushTool then
			local tool = pushTool:Clone()
			tool.Parent = backpack
		end
	end
end

local function resetWeaponsForRoundEnd(plr)
	if _G.ClearRentalTools then pcall(function() _G.ClearRentalTools(plr) end) end
	if _G.ResetCoinPurchases then pcall(function() _G.ResetCoinPurchases(plr) end) end
end

local function equipWeaponForRoundStart(plr)
	if _G.EquipPurchasedWeapon then
		pcall(function() _G.EquipPurchasedWeapon(plr) end)
	else
		givePushTool(plr)
	end
end

-- ============================================
-- FINISH DETECTION
-- ============================================

local function findFinishPart(map)
	if not map then return nil end
	local names = {"End", "Finish", "FinishLine", "Goal"}
	for _, name in ipairs(names) do
		local found = map:FindFirstChild(name, true)
		if found then
			if found:IsA("BasePart") then return found end
			if found:IsA("Model") then
				if found.PrimaryPart then return found.PrimaryPart end
				local firstPart = found:FindFirstChildWhichIsA("BasePart", true)
				if firstPart then return firstPart end
			end
		end
	end
	for _, descendant in pairs(map:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local lowerName = descendant.Name:lower()
			if lowerName == "end" or lowerName == "finish" or lowerName == "finishline" or lowerName == "goal" then
				return descendant
			end
		end
	end
	return nil
end

local function ordinal(n)
	local s = tostring(n)
	if s:sub(-2) == "11" or s:sub(-2) == "12" or s:sub(-2) == "13" then
		return s .. "th"
	end
	local last = s:sub(-1)
	if last == "1" then return s .. "st" end
	if last == "2" then return s .. "nd" end
	if last == "3" then return s .. "rd" end
	return s .. "th"
end

-- ============================================
-- CHARACTER HANDLER
-- ============================================

local function handleCharacterSpawn(plr, character)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not hrp or not humanoid then return end
	task.wait(0.1)

	if roundActive and currentMap then
		teleportToMap(plr, currentMap)
		equipWeaponForRoundStart(plr)
	else
		teleportToLobby(plr)
		equipWeaponForRoundStart(plr)
	end
end

local function setupCharacterHandler(plr)
	if characterConnections[plr] then
		characterConnections[plr]:Disconnect()
		characterConnections[plr] = nil
	end

	characterConnections[plr] = plr.CharacterAdded:Connect(function(character)
		handleCharacterSpawn(plr, character)
	end)

	if plr.Character then
		task.spawn(function() handleCharacterSpawn(plr, plr.Character) end)
	end
end

-- ============================================
-- GAME PHASES
-- ============================================

local function runIntermission()
	roundActive = false
	lastWinners = winners
	lastWinnerTimes = winnerTimes
	winners = {}
	winnerTimes = {}
	MapLoader.UnloadMap()
	cleanupToolEffects()
	CoinManager.StopMapCoins()
	teleportAllToLobby()

	if #lastWinners > 0 then
		if WinnerPodium then
			local podiumData = {}
			for rank, plr in ipairs(lastWinners) do
				if plr and plr.Parent then
					table.insert(podiumData, {Player = plr})
				end
			end
			if WinnerPodium.DisplayWinners and #podiumData > 0 then
				pcall(function() WinnerPodium.DisplayWinners(podiumData) end)
			end
		end
		task.wait(5)
	else
		if WinnerPodium and WinnerPodium.Clear then
			pcall(function() WinnerPodium.Clear() end)
		end
	end

	CoinManager.StartLobbyCoins()
	SoundManager.PlayMusic("MenuMusic")

	-- ADMIN: Can skip intermission
	skipIntermission = false
	for i = CONFIG.IntermissionTime, 1, -1 do
		if skipIntermission then
			skipIntermission = false
			print("?? Intermission skipped by admin!")
			timerEvent:FireAllClients(0, "Intermission")
			break
		end
		timerEvent:FireAllClients(i, "Intermission")
		task.wait(1)
	end
end

local function runVoting()
	CoinManager.StopLobbyCoins()
	VotingSystem.StartVoting(CONFIG.VotingTime)

	-- ADMIN: Can skip voting
	skipVoting = false
	for i = CONFIG.VotingTime, 1, -1 do
		if skipVoting then
			skipVoting = false
			print("?? Voting skipped by admin!")
			timerEvent:FireAllClients(0, "Voting")
			break
		end
		timerEvent:FireAllClients(i, "Voting")
		task.wait(1)
	end

	VotingSystem.EndVoting()
	local chosenMap = "Yup"
	local success, result = pcall(function()
		return VotingSystem.GetWinningMap()
	end)
	if success and result and result ~= "" then
		chosenMap = result
	end
	return chosenMap
end

local function runRound(mapName)
	roundActive = true
	winners = {}
	winnerTimes = {}
	roundStartTime = tick()
	local winnerIds = {}

	for _, plr in pairs(Players:GetPlayers()) do
		equipWeaponForRoundStart(plr)
	end

	transitionEvent:FireAllClients("FadeIn")
	task.wait(3)
	currentMap = MapLoader.LoadMap(mapName)
	if not currentMap then
		transitionEvent:FireAllClients("FadeOut")
		roundActive = false
		return
	end

	print("??? Map loaded:", currentMap.Name, "- now teleporting players")
	teleportAllToMap(currentMap)
	task.wait(1)
	transitionEvent:FireAllClients("FadeOut")
	CoinManager.StartMapCoins(currentMap)
	SoundManager.PlayMusic("RoundMusic")
	pcall(function() ObjectSpawner.StartSpawning(mapName) end)

	local finishPart = findFinishPart(currentMap)
	local touchConnections = {}

	local function registerWinner(plr)
		if not roundActive then return end
		if not plr or not plr.Parent then return end
		if winnerIds[plr.UserId] then return end

		table.insert(winners, plr)
		winnerIds[plr.UserId] = true
		local position = #winners
		local timeTaken = math.floor(tick() - roundStartTime)
		winnerTimes[plr] = timeTaken

		local reward = CONFIG.ParticipationReward
		if position == 1 then reward = CONFIG.WinReward
		elseif position == 2 then reward = CONFIG.SecondPlace
		elseif position == 3 then reward = CONFIG.ThirdPlace end

		if _G.UpdatePlayerCoins then _G.UpdatePlayerCoins(plr, reward) end

		local leaderstats = plr:FindFirstChild("leaderstats")
		if leaderstats then
			local winsVal = leaderstats:FindFirstChild("Wins")
			if winsVal then winsVal.Value = winsVal.Value + 1 end
		end

		if WinnerPodium and WinnerPodium.SaveWinnerData then
			pcall(function() WinnerPodium.SaveWinnerData(plr, position) end)
		end

		for _, client in pairs(Players:GetPlayers()) do
			pcall(function() showWinnerEvent:FireClient(client, plr, timeTaken, position) end)
		end

		pcall(function() showWinEvent:FireClient(plr, ordinal(position), reward) end)
	end

	if finishPart and finishPart:IsA("BasePart") then
		local conn = finishPart.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then return end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then return end
			local plr = Players:GetPlayerFromCharacter(character)
			if not plr then return end
			registerWinner(plr)
		end)
		table.insert(touchConnections, conn)

		local parent = finishPart.Parent
		if parent and parent:IsA("Model") then
			for _, child in pairs(parent:GetDescendants()) do
				if child:IsA("BasePart") and child ~= finishPart then
					local childConn = child.Touched:Connect(function(hit)
						local character = hit.Parent
						if not character then return end
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						if not humanoid or humanoid.Health <= 0 then return end
						local plr = Players:GetPlayerFromCharacter(character)
						if not plr then return end
						registerWinner(plr)
					end)
					table.insert(touchConnections, childConn)
				end
			end
		end
	end

	-- ADMIN: Can end round early
	endRoundNow = false
	for i = CONFIG.RoundTime, 1, -1 do
		if endRoundNow then
			endRoundNow = false
			print("?? Round ended by admin!")
			timerEvent:FireAllClients(0, "Round")
			break
		end
		timerEvent:FireAllClients(i, "Round")
		task.wait(1)
		if not roundActive then break end
	end

	for _, conn in ipairs(touchConnections) do
		conn:Disconnect()
	end

	roundActive = false

	for i = CONFIG.RoundEndTime, 1, -1 do
		timerEvent:FireAllClients(i, "RoundOver")
		task.wait(1)
	end

	for _, plr in pairs(Players:GetPlayers()) do
		if not winnerIds[plr.UserId] then
			if _G.UpdatePlayerCoins then _G.UpdatePlayerCoins(plr, CONFIG.ParticipationReward) end
			pcall(function() showWinEvent:FireClient(plr, nil, CONFIG.ParticipationReward) end)
		end
	end

	if WinnerPodium and WinnerPodium.DisplayWinners then
		local podiumData = {}
		for rank = 1, 3 do
			local plr = winners[rank]
			if plr and plr.Parent then
				table.insert(podiumData, {Player = plr})
			end
		end
		if #podiumData > 0 then
			pcall(function() WinnerPodium.DisplayWinners(podiumData) end)
		elseif WinnerPodium and WinnerPodium.Clear then
			pcall(function() WinnerPodium.Clear() end)
		end
	end

	for _, plr in pairs(Players:GetPlayers()) do
		resetWeaponsForRoundEnd(plr)
	end

	cleanupToolEffects()
	pcall(function() ObjectSpawner.StopSpawning() end)
	CoinManager.StopMapCoins()
	SoundManager.StopMusic()
end

-- ============================================
-- GAME LOOP
-- ============================================

local function gameLoop()
	while true do
		while #Players:GetPlayers() < CONFIG.MinPlayers do
			task.wait(5)
		end
		runIntermission()
		local mapName = runVoting()
		if mapName then
			runRound(mapName)
		end
		task.wait(2)
	end
end

-- ============================================
-- PLAYER CONNECTIONS
-- ============================================

Players.PlayerAdded:Connect(function(plr)
	print("?? Player joined:", plr.Name)
	setupCharacterHandler(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
	if characterConnections[plr] then
		characterConnections[plr]:Disconnect()
		characterConnections[plr] = nil
	end
end)

for _, plr in pairs(Players:GetPlayers()) do
	setupCharacterHandler(plr)
end

_G.IsRoundActive = function() return roundActive end
_G.GetCurrentMap = function() return currentMap end

print("? Workspace setup validated!")
print("?? GAME MANAGER STARTED")

task.delay(3, function()
	print("? Starting game loop...")
	gameLoop()
end)