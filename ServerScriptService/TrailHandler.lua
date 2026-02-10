-- ============================================
-- TRAIL HANDLER (Server)
-- Place in: ServerScriptService/TrailHandler (Script)
-- Handles: Trail equip/unequip requests from clients
-- Validates TrailMaster gamepass ownership for premium trails
-- Re-applies trails on respawn so other players can see them
-- Fixed: Removed MaxWidth (not valid on Trail), uses WidthScale instead
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

print("? Trail Handler loading...")

-- TrailMaster gamepass ID
local TRAILMASTER_GAMEPASS_ID = 1704388512

-- ============================================
-- TRAIL DATA (must match client trail list)
-- ============================================
local TRAILS = {
	-- Free trails
	White      = {Color1 = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(200, 200, 200), Premium = false},
	Red        = {Color1 = Color3.fromRGB(255, 50, 50),   Color2 = Color3.fromRGB(180, 20, 20),   Premium = false},
	Blue       = {Color1 = Color3.fromRGB(50, 100, 255),  Color2 = Color3.fromRGB(20, 50, 180),   Premium = false},
	Green      = {Color1 = Color3.fromRGB(50, 255, 50),   Color2 = Color3.fromRGB(20, 180, 20),   Premium = false},
	-- Premium trails (require TrailMaster gamepass)
	Rainbow    = {Color1 = Color3.fromRGB(255, 0, 0),     Color2 = Color3.fromRGB(0, 0, 255),     Premium = true},
	Gold       = {Color1 = Color3.fromRGB(255, 215, 0),   Color2 = Color3.fromRGB(255, 170, 0),   Premium = true},
	Purple     = {Color1 = Color3.fromRGB(180, 50, 255),  Color2 = Color3.fromRGB(100, 0, 200),   Premium = true},
	Cyan       = {Color1 = Color3.fromRGB(0, 255, 255),   Color2 = Color3.fromRGB(0, 180, 220),   Premium = true},
	Pink       = {Color1 = Color3.fromRGB(255, 105, 180), Color2 = Color3.fromRGB(255, 50, 150),  Premium = true},
	Fire       = {Color1 = Color3.fromRGB(255, 100, 0),   Color2 = Color3.fromRGB(255, 200, 0),   Premium = true},
	Ice        = {Color1 = Color3.fromRGB(150, 220, 255), Color2 = Color3.fromRGB(200, 240, 255), Premium = true},
	Shadow     = {Color1 = Color3.fromRGB(30, 0, 50),     Color2 = Color3.fromRGB(80, 0, 120),    Premium = true},
	["Neon Green"] = {Color1 = Color3.fromRGB(0, 255, 100), Color2 = Color3.fromRGB(100, 255, 0), Premium = true},
	Lava       = {Color1 = Color3.fromRGB(255, 50, 0),    Color2 = Color3.fromRGB(255, 150, 0),   Premium = true},
}

-- ============================================
-- REMOTE EVENT
-- ============================================
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local trailEvent = remoteEvents:FindFirstChild("TrailEquip")
if not trailEvent then
	trailEvent = Instance.new("RemoteEvent")
	trailEvent.Name = "TrailEquip"
	trailEvent.Parent = remoteEvents
	print("? Created TrailEquip RemoteEvent")
end

-- ============================================
-- PLAYER TRAIL DATA (stores which trail each player has equipped)
-- ============================================
local playerTrails = {}

-- ============================================
-- REMOVE TRAIL FROM CHARACTER
-- Cleans up any existing trail + attachments
-- ============================================
local function removeTrailFromCharacter(character)
	if not character then return end
	for _, child in pairs(character:GetDescendants()) do
		if child:IsA("Trail") and child.Name == "PlayerTrail" then
			child:Destroy()
		end
		if child:IsA("Attachment") and (child.Name == "TrailAttach0" or child.Name == "TrailAttach1") then
			child:Destroy()
		end
	end
end

-- ============================================
-- APPLY TRAIL TO CHARACTER
-- Creates attachments + trail on the player's HumanoidRootPart
-- ============================================
local function applyTrailToCharacter(player, trailName)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local trailData = TRAILS[trailName]
	if not trailData then return end

	-- Remove any existing trail first
	removeTrailFromCharacter(character)

	-- Create top attachment (trail starts here)
	local attach0 = Instance.new("Attachment")
	attach0.Name = "TrailAttach0"
	attach0.Position = Vector3.new(0, 1, 0)
	attach0.Parent = hrp

	-- Create bottom attachment (trail ends here)
	local attach1 = Instance.new("Attachment")
	attach1.Name = "TrailAttach1"
	attach1.Position = Vector3.new(0, -1, 0)
	attach1.Parent = hrp

	-- Create the trail effect
	-- NOTE: WidthScale controls how wide the trail is (NOT MaxWidth which doesn't exist)
	local trail = Instance.new("Trail")
	trail.Name = "PlayerTrail"
	trail.Attachment0 = attach0
	trail.Attachment1 = attach1
	trail.Lifetime = 1.5
	trail.MinLength = 0.1
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.LightEmission = 0.5
	trail.LightInfluence = 0.3
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(trailData.Color1, trailData.Color2)
	trail.Parent = hrp

	print("? Applied", trailName, "trail to", player.Name)
end

-- ============================================
-- HANDLE EQUIP/UNEQUIP REQUESTS FROM CLIENTS
-- ============================================
trailEvent.OnServerEvent:Connect(function(player, action, trailName)
	if action == "Equip" then
		-- Validate trail exists
		local trailData = TRAILS[trailName]
		if not trailData then
			warn("?? Unknown trail:", trailName)
			return
		end

		-- Validate premium trails require TrailMaster gamepass
		if trailData.Premium then
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, TRAILMASTER_GAMEPASS_ID)
			end)
			if not (success and owns) then
				warn("??", player.Name, "tried to equip premium trail without TrailMaster!")
				return
			end
		end

		-- Save selection and apply
		playerTrails[player.UserId] = trailName
		applyTrailToCharacter(player, trailName)

	elseif action == "Unequip" then
		-- Clear selection and remove trail
		playerTrails[player.UserId] = nil
		if player.Character then
			removeTrailFromCharacter(player.Character)
		end
		print("?", player.Name, "removed their trail")
	end
end)

-- ============================================
-- RE-APPLY TRAIL ON RESPAWN
-- When a player dies and respawns, put their trail back on
-- ============================================
local function setupRespawnHandler(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1)
		local trailName = playerTrails[player.UserId]
		if trailName then
			applyTrailToCharacter(player, trailName)
		end
	end)
end

-- Connect for new players
Players.PlayerAdded:Connect(function(player)
	setupRespawnHandler(player)
end)

-- Connect for players already in game (studio testing)
for _, player in pairs(Players:GetPlayers()) do
	setupRespawnHandler(player)
end

-- ============================================
-- CLEANUP ON LEAVE
-- Remove trail data when player leaves
-- ============================================
Players.PlayerRemoving:Connect(function(player)
	playerTrails[player.UserId] = nil
end)

-- ============================================
-- PRINT STATS
-- ============================================
local freeCount = 0
local premiumCount = 0
for _, data in pairs(TRAILS) do
	if data.Premium then
		premiumCount = premiumCount + 1
	else
		freeCount = freeCount + 1
	end
end

print("? Trail Handler ready!")
print("   Trails: " .. freeCount .. " free, " .. premiumCount .. " premium")
print("   TrailMaster Pass ID:", TRAILMASTER_GAMEPASS_ID)