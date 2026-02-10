-- ============================================
-- GAMEPASS HANDLER (All 6 Passes)
-- Place in: ServerScriptService/GamePassHandler
-- ============================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("?? GamePass Handler loading...")

-- ============================================
-- GAMEPASS IDs (YOUR IDs!)
-- ============================================

local GAMEPASSES = {
	StarterPack = 1704084817,       -- 149 R$
	TrailMaster = 1704388512,       -- 99 R$
	HeadStart = 1704300498,         -- 149 R$
	VIP = 1704140664,               -- 199 R$
	Athlete = 1703657605,           -- 199 R$
	KnockbackResist = 1703795339,   -- 449 R$
}

-- Store player passes
local playerPasses = {}

-- ============================================
-- CHECK IF PLAYER OWNS GAMEPASS
-- ============================================

local function ownsGamePass(player, passId)
	local success, owned = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)

	if success then
		return owned
	else
		warn("?? Failed to check GamePass for", player.Name)
		return false
	end
end

-- ============================================
-- APPLY GAMEPASS BENEFITS
-- ============================================

local function applyStarterPack(player)
	print("?? Applying Starter Pack to", player.Name)

	-- Give 500 coins
	local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
	PlayerDataManager.AddCoins(player, 500)

	-- TODO: Give exclusive starter weapon
	-- (We'll create this tool later)

	print("? Starter Pack applied!")
end

local function applyVIP(player)
	print("?? Applying VIP Pass to", player.Name)

	-- VIP benefits handled by:
	-- - Coin multiplier (in coin collection script)
	-- - Rainbow name (client-side)
	-- - Sparkle trail (client-side)
	-- - VIP badge (client-side)

	-- Create VIP attribute for other scripts to check
	player:SetAttribute("IsVIP", true)

	print("? VIP Pass applied!")
end

local function applyAthlete(player)
	print("?? Applying Athlete Pass to", player.Name)

	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	-- Apply permanent boosts
	humanoid.WalkSpeed = humanoid.WalkSpeed * 1.10  -- +10%
	humanoid.JumpPower = humanoid.JumpPower * 1.10  -- +10%

	-- Set attribute
	player:SetAttribute("HasAthlete", true)

	print("? Athlete Pass applied! Speed:", humanoid.WalkSpeed, "Jump:", humanoid.JumpPower)
end

local function applyKnockbackResist(player)
	print("??? Applying Knockback Resistance to", player.Name)

	-- Set attribute for push tool to check
	player:SetAttribute("HasKnockbackResist", true)

	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Make player heavier (harder to push)
	local bodyPosition = humanoidRootPart:FindFirstChild("BodyPosition")
	if not bodyPosition then
		-- Increase mass via AssemblyMass (read-only, so we use BodyForce)
		local bodyForce = Instance.new("BodyForce")
		bodyForce.Name = "KnockbackResistance"
		bodyForce.Force = Vector3.new(0, humanoidRootPart.AssemblyMass * 196.2 * 0.3, 0)  -- 30% heavier
		bodyForce.Parent = humanoidRootPart
	end

	print("? Knockback Resistance applied!")
end

-- ============================================
-- CHECK ALL PASSES FOR PLAYER
-- ============================================

local function checkPlayerPasses(player)
	print("?? Checking GamePasses for", player.Name)

	playerPasses[player.UserId] = {}

	-- Check each pass
	for passName, passId in pairs(GAMEPASSES) do
		local owned = ownsGamePass(player, passId)
		playerPasses[player.UserId][passName] = owned

		if owned then
			print("?", player.Name, "owns", passName)

			-- Apply benefits
			if passName == "StarterPack" then
				applyStarterPack(player)
			elseif passName == "VIP" then
				applyVIP(player)
			elseif passName == "Athlete" then
				applyAthlete(player)
			elseif passName == "KnockbackResist" then
				applyKnockbackResist(player)
			elseif passName == "TrailMaster" then
				player:SetAttribute("HasTrailMaster", true)
			elseif passName == "HeadStart" then
				player:SetAttribute("HasHeadStart", true)
			end
		end
	end

	print("? GamePass check complete for", player.Name)
end

-- ============================================
-- HANDLE CHARACTER RESPAWN (Reapply benefits)
-- ============================================

local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Reapply Athlete boost
	if playerPasses[player.UserId] and playerPasses[player.UserId].Athlete then
		task.wait(1)  -- Wait for humanoid to load
		applyAthlete(player)
	end

	-- Reapply Knockback Resistance
	if playerPasses[player.UserId] and playerPasses[player.UserId].KnockbackResist then
		task.wait(1)
		applyKnockbackResist(player)
	end
end

-- ============================================
-- PLAYER JOIN/LEAVE
-- ============================================

Players.PlayerAdded:Connect(function(player)
	-- Check passes
	checkPlayerPasses(player)

	-- Handle respawns
	player.CharacterAdded:Connect(onCharacterAdded)
end)

Players.PlayerRemoving:Connect(function(player)
	playerPasses[player.UserId] = nil
end)

-- ============================================
-- EXPOSE FUNCTIONS
-- ============================================

local GamePassHandler = {}

function GamePassHandler.HasPass(player, passName)
	if not playerPasses[player.UserId] then return false end
	return playerPasses[player.UserId][passName] or false
end

function GamePassHandler.GetPassId(passName)
	return GAMEPASSES[passName]
end

print("? GamePass Handler ready!")
print("   Registered passes:")
for name, id in pairs(GAMEPASSES) do
	print("   -", name, "- ID:", id)
end

return GamePassHandler