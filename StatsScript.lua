local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MPS = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local sf = script.Parent:WaitForChild("StatsFrame")

local GV = RS:FindFirstChild("GameValues")
local GS = GV and GV:FindFirstChild("GameState")

local speedVal = sf:WaitForChild("SpeedRow"):WaitForChild("Value")
local trailVal = sf:WaitForChild("TrailRow"):WaitForChild("Value")
local skillVal = sf:WaitForChild("SkillRow"):WaitForChild("Value")
local boostVal = sf:WaitForChild("BoostRow"):WaitForChild("Value")

-- Show during rounds
if GS then
	GS.Changed:Connect(function(v)
		sf.Visible = (v == "Playing")
	end)
	sf.Visible = (GS.Value == "Playing")
end

-- TRAIL SKILL MAP (matches TrailShopHandler)
local SKILL_TRAILS = {
	FreezeTime = "FreezeTime",
	DashTrail = "Dash",
	PhaseTrail = "Phase",
	ShockTrail = "Shockwave",
	MomentumTrail = "SpeedBurst",
	TeleportTrail = "Teleport",
	TimeRewindTrail = "TimeRewind",
	BomberTrail = "Bomber",
	SpeedBurstTrail = "SpeedBurst",
}

-- GAMEPASS IDS
local GP_VIP = 1709154874
local GP_ATHLETE = 1707648990
local GP_KNOCKBACK = 1708531013
local GP_KNOCKBACK_RESIST = 1710491715
local GP_TRAILMASTER = 1711477336
local GP_HEADSTART = 1711495326
local GP_STARTERPACK = 1708836892

-- Cache gamepass ownership
local gpCache = {}
local function hasGP(id)
	if gpCache[id] ~= nil then return gpCache[id] end
	local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(player.UserId, id) end)
	gpCache[id] = ok and owns or false
	return gpCache[id]
end

-- Get equipped trail from server data
local function getEquippedTrail()
	local re = RS:FindFirstChild("RemoteEvents")
	if re then
		local getData = re:FindFirstChild("GetTrailShopData")
		if getData then
			local ok, data = pcall(function() return getData:InvokeServer() end)
			if ok and data and data.Equipped then
				return data.Equipped
			end
		end
	end
	return nil
end

-- Get trail name from ID
local TRAIL_NAMES = {
	White="White",Red="Red",Blue="Blue",Green="Green",
	Gold="Gold",Cyan="Cyan",Purple="Purple",Orange="Orange",
	Pink="Pink",Emerald="Emerald",Ice="Ice",Fire="Fire",
	Shadow="Shadow",NeonGreen="Neon",Lava="Lava",
	AcidSlime="Acid Slime",Quicksand="Quicksand",FrostBite="Frostbite",
	Electric="Electric",Magnet="Magnet",Solar="Solar",Crystal="Crystal",
	ToxicMist="Toxic Mist",Storm="Storm",Drift="Drift",Pulse="Pulse",
	PhantomEcho="Phantom Echo",
	FreezeTime="Freeze Time",DashTrail="Dash",PhaseTrail="Phase",
	ShockTrail="Shock",MomentumTrail="Momentum",TeleportTrail="Teleport",
	TimeRewindTrail="Time Rewind",BomberTrail="Bomber",SpeedBurstTrail="Speed Burst",
	Rainbow="Rainbow",Galaxy="Galaxy",Lightning="Lightning",Void="Void",
	Sakura="Sakura",Frost="Frost",Inferno="Inferno",Phantom="Phantom",
	Titan="Titan",Supernova="Supernova",LowGravity="Low Gravity",
}

local cachedTrail = nil
local lastTrailCheck = 0

RunService.Heartbeat:Connect(function()
	if not sf.Visible then return end
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")

	-- Speed
	if hum then
		speedVal.Text = math.floor(hum.WalkSpeed) .. " sp"
	end

	-- Trail (check every 2 seconds, not every frame)
	if tick() - lastTrailCheck > 2 then
		lastTrailCheck = tick()
		task.spawn(function()
			cachedTrail = getEquippedTrail()
		end)
	end

	local trailName = "None"
	if cachedTrail and cachedTrail ~= "" then
		trailName = TRAIL_NAMES[cachedTrail] or cachedTrail
	end
	trailVal.Text = trailName

	-- Skill
	local skillText = "None"
	if cachedTrail and SKILL_TRAILS[cachedTrail] then
		skillText = SKILL_TRAILS[cachedTrail]
	end
	skillVal.Text = skillText

	-- Boost breakdown
	if hum then
		local base = 16
		local totalBoost = math.floor(((hum.WalkSpeed / base) - 1) * 100)
		if totalBoost < 0 then totalBoost = 0 end
		local parts = {}
		if totalBoost > 0 then
			table.insert(parts, "+" .. totalBoost .. "%")
		else
			table.insert(parts, "+0%")
		end
		boostVal.Text = table.concat(parts)
	end
end)

-- Gamepass perks display
local gpVal = sf:FindFirstChild("GPRow") and sf.GPRow:FindFirstChild("Value")
if gpVal then
	task.spawn(function()
		local perks = {}
		if hasGP(GP_VIP) then table.insert(perks, "VIP") end
		if hasGP(GP_ATHLETE) then table.insert(perks, "Athlete") end
		if hasGP(GP_TRAILMASTER) then table.insert(perks, "TrailMstr") end
		if hasGP(GP_HEADSTART) then table.insert(perks, "HeadStart") end
		if hasGP(GP_STARTERPACK) then table.insert(perks, "Starter") end
		if hasGP(GP_KNOCKBACK) then table.insert(perks, "KB") end
		if hasGP(GP_KNOCKBACK_RESIST) then table.insert(perks, "KBRes") end
		if #perks > 0 then
			gpVal.Text = table.concat(perks, ", ")
		else
			gpVal.Text = "None"
		end
	end)
end

print("Stats GUI loaded - auto shows during rounds")

