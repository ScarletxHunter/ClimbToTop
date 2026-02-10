-- ============================================
-- VOTING SYSTEM (Shows 3 random maps per round)
-- Place in: ServerScriptService/VotingSystem
-- Fixed: Only picks 3 maps from the pool each round
-- Fixed: Clears votes properly between rounds
-- Fixed: Rotates map options so players see variety
-- ============================================

local VotingSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local votes = {}
local availableMaps = {}
local votingActive = false
local voteConnection = nil
local lastUsedMaps = {} -- Track maps used recently to rotate better

-- How many map choices to show each round
local MAX_VOTE_OPTIONS = 3

print("?? VotingSystem module loading...")

-- ============================================
-- GET ALL MAPS FROM SERVERSTROAGE
-- ============================================
local function getAllMaps()
	local maps = {}
	local mapsFolder = ServerStorage:FindFirstChild("Maps")

	if not mapsFolder then
		warn("? Maps folder not found!")
		return {"Yup"}
	end

	for _, map in pairs(mapsFolder:GetChildren()) do
		if map:IsA("Model") or map:IsA("Folder") then
			table.insert(maps, map.Name)
		end
	end

	if #maps == 0 then
		return {"Yup"}
	end

	print("?? Found", #maps, "maps:", table.concat(maps, ", "))
	return maps
end

-- ============================================
-- PICK 3 RANDOM MAPS (avoids repeating last round's maps when possible)
-- ============================================
local function pickRandomMaps(allMaps, count)
	-- If we have fewer maps than the count, just use all of them
	if #allMaps <= count then
		-- Shuffle them at least
		local shuffled = {}
		for _, m in ipairs(allMaps) do
			table.insert(shuffled, m)
		end
		for i = #shuffled, 2, -1 do
			local j = math.random(1, i)
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		end
		return shuffled
	end

	-- Separate maps into "fresh" (not used last round) and "recent" (used last round)
	local fresh = {}
	local recent = {}
	for _, mapName in ipairs(allMaps) do
		if table.find(lastUsedMaps, mapName) then
			table.insert(recent, mapName)
		else
			table.insert(fresh, mapName)
		end
	end

	-- Shuffle both pools
	for i = #fresh, 2, -1 do
		local j = math.random(1, i)
		fresh[i], fresh[j] = fresh[j], fresh[i]
	end
	for i = #recent, 2, -1 do
		local j = math.random(1, i)
		recent[i], recent[j] = recent[j], recent[i]
	end

	-- Pick from fresh first, then fill from recent if needed
	local picked = {}
	for _, mapName in ipairs(fresh) do
		if #picked >= count then break end
		table.insert(picked, mapName)
	end
	for _, mapName in ipairs(recent) do
		if #picked >= count then break end
		table.insert(picked, mapName)
	end

	-- Final shuffle so order feels random
	for i = #picked, 2, -1 do
		local j = math.random(1, i)
		picked[i], picked[j] = picked[j], picked[i]
	end

	-- Save what we picked for next round's rotation
	lastUsedMaps = {}
	for _, m in ipairs(picked) do
		table.insert(lastUsedMaps, m)
	end

	return picked
end

-- ============================================
-- START VOTING
-- ============================================
function VotingSystem.StartVoting(duration)
	print("?? Starting voting...")

	votingActive = true
	votes = {} -- CLEAR OLD VOTES!

	-- Get all maps and pick 3 random ones
	local allMaps = getAllMaps()
	availableMaps = pickRandomMaps(allMaps, MAX_VOTE_OPTIONS)

	print("?? Selected", #availableMaps, "maps for voting:", table.concat(availableMaps, ", "))
	print("   (from", #allMaps, "total maps)")

	local voteCounts = {}
	for _, mapName in pairs(availableMaps) do
		voteCounts[mapName] = 0
	end

	-- Get or create remote events
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = ReplicatedStorage
	end

	local voteUpdateEvent = remoteEvents:FindFirstChild("VoteUpdate")
	if not voteUpdateEvent then
		voteUpdateEvent = Instance.new("RemoteEvent")
		voteUpdateEvent.Name = "VoteUpdate"
		voteUpdateEvent.Parent = remoteEvents
		print("? Created VoteUpdate RemoteEvent")
	end

	local castVoteEvent = remoteEvents:FindFirstChild("CastVote")
	if not castVoteEvent then
		castVoteEvent = Instance.new("RemoteEvent")
		castVoteEvent.Name = "CastVote"
		castVoteEvent.Parent = remoteEvents
		print("? Created CastVote RemoteEvent")
	end

	-- Send the selected maps to all clients
	voteUpdateEvent:FireAllClients(voteCounts, availableMaps)
	print("? Sent", #availableMaps, "map options to clients")

	-- Listen for votes
	if voteConnection then
		voteConnection:Disconnect()
	end

	voteConnection = castVoteEvent.OnServerEvent:Connect(function(player, mapName)
		if not votingActive then return end
		if not table.find(availableMaps, mapName) then return end

		-- Remove old vote if player is changing their vote
		if votes[player.UserId] then
			local oldMap = votes[player.UserId]
			voteCounts[oldMap] = math.max(0, voteCounts[oldMap] - 1)
		end

		-- Record new vote
		votes[player.UserId] = mapName
		voteCounts[mapName] = (voteCounts[mapName] or 0) + 1

		print("???", player.Name, "voted for", mapName, "| Total votes:", voteCounts[mapName])
		voteUpdateEvent:FireAllClients(voteCounts, availableMaps)
	end)
end

-- ============================================
-- END VOTING
-- ============================================
function VotingSystem.EndVoting()
	votingActive = false
	if voteConnection then
		voteConnection:Disconnect()
		voteConnection = nil
	end
	print("?? Voting ended")
end

-- ============================================
-- GET WINNING MAP
-- ============================================
function VotingSystem.GetWinningMap()
	print("?? Calculating winning map...")

	-- Count votes for each available map
	local voteCounts = {}
	for _, mapName in pairs(availableMaps) do
		voteCounts[mapName] = 0
	end

	for userId, mapName in pairs(votes) do
		voteCounts[mapName] = (voteCounts[mapName] or 0) + 1
	end

	-- Find the map with the most votes
	local winningMap = nil
	local highestVotes = -1

	for mapName, count in pairs(voteCounts) do
		print("   -", mapName, ":", count, "votes")
		if count > highestVotes then
			highestVotes = count
			winningMap = mapName
		end
	end

	-- If no votes, pick randomly from the available options
	if not winningMap or highestVotes == 0 then
		if #availableMaps > 0 then
			winningMap = availableMaps[math.random(1, #availableMaps)]
			print("?? No votes, randomly selected:", winningMap)
		else
			winningMap = "Yup"
		end
	end

	print("?? Winning map:", winningMap, "with", highestVotes, "votes")
	return winningMap
end

-- ============================================
-- GET AVAILABLE MAPS (for other scripts)
-- ============================================
function VotingSystem.GetAvailableMaps()
	return availableMaps
end

print("? VotingSystem module loaded")

return VotingSystem