-- ============================================
-- TRAIL SHOP HANDLER v7 CLEAN REWRITE
-- 4 Free | 32 Coin | 12 Premium
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))

print("? Trail Shop Handler v7 loading...")

local function dbg(hId, loc, msg, data)
	-- #region agent log
	pcall(function()
		HttpService:PostAsync("http://127.0.0.1:7243/ingest/f4b63b01-cff3-4a42-b344-cb9c3aec0ae1",
			HttpService:JSONEncode({hypothesisId=hId,location=loc,message=msg,data=data or {},timestamp=DateTime.now().UnixTimestampMillis}),
			Enum.HttpContentType.ApplicationJson)
	end)
	-- #endregion
end

local TRAILMASTER_GAMEPASS_ID = 1711477336

local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "RemoteEvents"
	remoteFolder.Parent = ReplicatedStorage
end

local function getOrCreate(name, isFunc)
	local r = remoteFolder:FindFirstChild(name)
	if not r then
		r = isFunc and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remoteFolder
	end
	return r
end

local TrailEquip = getOrCreate("TrailEquip")
local TrailUpdate = getOrCreate("TrailUpdate")
local GetTrailShopData = getOrCreate("GetTrailShopData", true)
local NotifyClientRemote = getOrCreate("NotifyClient")
local LightningShockEffectRemote = getOrCreate("LightningShockEffect")
local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
local gameState = gameValues and gameValues:FindFirstChild("GameState")

local function isRoundActive()
	return gameState and gameState.Value == "Playing"
end

local TRAILS = {
	{Id="White",Name="White Trail",Description="A clean white streak. No bonuses -- just style.",Category="Free",Price=0,TrailType="Visual",Color1=Color3.fromRGB(255,255,255),Color2=Color3.fromRGB(200,200,200),Lifetime=1.5,LightEmission=0.3,LayoutOrder=1},
	{Id="Red",Name="Red Trail",Description="Stand out in red. Classic look.",Category="Free",Price=0,TrailType="Visual",Color1=Color3.fromRGB(255,50,50),Color2=Color3.fromRGB(180,20,20),Lifetime=1.5,LightEmission=0.4,LayoutOrder=2},
	{Id="Blue",Name="Blue Trail",Description="Cool blue streak. Simple and sleek.",Category="Free",Price=0,TrailType="Visual",Color1=Color3.fromRGB(50,100,255),Color2=Color3.fromRGB(20,50,180),Lifetime=1.5,LightEmission=0.4,LayoutOrder=3},
	{Id="Green",Name="Green Trail",Description="Fresh nature vibes. Go green!",Category="Free",Price=0,TrailType="Visual",Color1=Color3.fromRGB(50,255,50),Color2=Color3.fromRGB(20,180,20),Lifetime=1.5,LightEmission=0.4,LayoutOrder=4},
	{Id="Gold",Name="Gold Trail",Description="Shiny gold streak. Slightly faster than normal (+4% speed).",Category="Coin",Price=50,TrailType="Speed",SpeedBoost=0.04,Color1=Color3.fromRGB(255,215,0),Color2=Color3.fromRGB(255,170,0),Lifetime=1.8,LightEmission=0.6,LayoutOrder=5},
	{Id="Cyan",Name="Cyan Trail",Description="Bright cyan flow. +4% speed and +4% jump.",Category="Coin",Price=75,TrailType="SpeedJump",SpeedBoost=0.04,JumpBoost=0.04,Color1=Color3.fromRGB(0,255,255),Color2=Color3.fromRGB(0,180,220),Lifetime=1.8,LightEmission=0.6,LayoutOrder=6},
	{Id="Purple",Name="Purple Trail",Description="Royal purple. +6% jump power.",Category="Coin",Price=75,TrailType="Jump",JumpBoost=0.06,Color1=Color3.fromRGB(180,50,255),Color2=Color3.fromRGB(100,0,200),Lifetime=1.8,LightEmission=0.5,LayoutOrder=7},
	{Id="Orange",Name="Orange Trail",Description="Fiery orange. +6% speed.",Category="Coin",Price=100,TrailType="Speed",SpeedBoost=0.06,Color1=Color3.fromRGB(255,150,0),Color2=Color3.fromRGB(255,100,0),Lifetime=1.8,LightEmission=0.5,LayoutOrder=8},
	{Id="Pink",Name="Pink Trail",Description="Sweet pink with health regen. +5% speed, 0.5 HP/sec.",Category="Coin",Price=100,TrailType="SpeedRegen",SpeedBoost=0.05,RegenRate=0.5,Color1=Color3.fromRGB(255,105,180),Color2=Color3.fromRGB(255,50,150),Lifetime=1.8,LightEmission=0.5,LayoutOrder=9},
	{Id="Emerald",Name="Emerald Trail",Description="Emerald glow. +8% jump.",Category="Coin",Price=125,TrailType="Jump",JumpBoost=0.08,Color1=Color3.fromRGB(0,200,80),Color2=Color3.fromRGB(0,150,50),Lifetime=2.0,LightEmission=0.5,LayoutOrder=10},
	{Id="Ice",Name="Ice Trail",Description="Cold ice shield. 8% damage reduction.",Category="Coin",Price=150,TrailType="Shield",ShieldPercent=0.08,Color1=Color3.fromRGB(150,220,255),Color2=Color3.fromRGB(200,240,255),Lifetime=2.0,LightEmission=0.6,LayoutOrder=11},
	{Id="Fire",Name="Fire Trail",Description="Burning aura. +8% speed, damages nearby players.",Category="Coin",Price=150,TrailType="SpeedPoison",SpeedBoost=0.08,DamagePerSec=0.5,AuraRadius=5,Color1=Color3.fromRGB(255,100,0),Color2=Color3.fromRGB(255,200,0),Lifetime=2.0,LightEmission=0.7,LayoutOrder=12},
	{Id="Shadow",Name="Shadow Trail",Description="Dark blind aura. +6% speed, blinds players behind you.",Category="Coin",Price=175,TrailType="SpeedGhost",SpeedBoost=0.06,GhostAlpha=0.25,Color1=Color3.fromRGB(30,0,50),Color2=Color3.fromRGB(80,0,120),Lifetime=2.0,LightEmission=0.2,LayoutOrder=13},
	{Id="NeonGreen",Name="Neon Trail",Description="Bright neon. +6% speed +4% jump.",Category="Coin",Price=200,TrailType="SpeedJump",SpeedBoost=0.06,JumpBoost=0.04,Color1=Color3.fromRGB(0,255,100),Color2=Color3.fromRGB(100,255,0),Lifetime=2.0,LightEmission=0.8,LayoutOrder=14},
	{Id="Lava",Name="Lava Trail",Description="Molten lava aura. +8% speed, burns nearby players.",Category="Coin",Price=200,TrailType="SpeedPoison",SpeedBoost=0.08,DamagePerSec=2,AuraRadius=5,Color1=Color3.fromRGB(255,50,0),Color2=Color3.fromRGB(255,150,0),Lifetime=2.2,LightEmission=0.7,LayoutOrder=15},
	{Id="AcidSlime",Name="Acid Slime Trail",Description="Drops acid puddles while moving. Walk over them to damage enemies. +6% speed.",Category="Coin",Price=200,TrailType="SpeedPuddle",SpeedBoost=0.06,PuddleDrop=true,PuddleDamage=1,PuddleDuration=4,PuddleInterval=1.5,Color1=Color3.fromRGB(80,255,0),Color2=Color3.fromRGB(0,180,0),Lifetime=3.0,LightEmission=0.6,LayoutOrder=16},
	{Id="Quicksand",Name="Quicksand Trail",Description="Slows nearby players 25%. +5% speed.",Category="Coin",Price=225,TrailType="SpeedSlow",SpeedBoost=0.05,SlowPercent=0.25,SlowDuration=1.5,AuraRadius=5,Color1=Color3.fromRGB(194,160,90),Color2=Color3.fromRGB(150,110,50),Lifetime=3.5,LightEmission=0.2,LayoutOrder=17},
	{Id="FrostBite",Name="Frostbite Trail",Description="Freezes nearby players 0.75s. +5% speed.",Category="Coin",Price=250,TrailType="SpeedFreeze",SpeedBoost=0.05,FreezeDuration=0.75,FreezeRadius=5,Color1=Color3.fromRGB(100,200,255),Color2=Color3.fromRGB(200,230,255),Lifetime=2.5,LightEmission=0.7,LayoutOrder=18},
	{Id="Electric",Name="Electric Trail",Description="Micro stun aura. +8% speed, shocks nearby players.",Category="Coin",Price=275,TrailType="ShockAura",SpeedBoost=0.08,SlowPercent=0.40,SlowDuration=0.5,ShockKnockback=12,AuraRadius=6,Color1=Color3.fromRGB(255,255,0),Color2=Color3.fromRGB(100,200,255),Lifetime=1.5,LightEmission=1.0,LayoutOrder=19},
	{Id="Magnet",Name="Magnet Trail",Description="Pulls coins from 12 studs away. +4% speed.",Category="Coin",Price=300,TrailType="SpeedMagnet",SpeedBoost=0.04,MagnetRadius=12,Color1=Color3.fromRGB(200,50,50),Color2=Color3.fromRGB(80,80,200),Lifetime=2.0,LightEmission=0.5,LayoutOrder=20},
	{Id="Solar",Name="Solar Trail",Description="While moving, blinds nearby players for 1.2s in a 12 stud radius. +9% speed.",Category="Coin",Price=350,TrailType="Speed",SpeedBoost=0.09,Color1=Color3.fromRGB(255,220,50),Color2=Color3.fromRGB(255,150,0),Lifetime=2.0,LightEmission=1.0,LayoutOrder=21},
	{Id="Crystal",Name="Crystal Trail",Description="Crystal shield. +8% speed, 10% damage reduction.",Category="Coin",Price=400,TrailType="SpeedShield",SpeedBoost=0.08,ShieldPercent=0.10,Color1=Color3.fromRGB(180,220,255),Color2=Color3.fromRGB(120,180,255),Lifetime=2.2,LightEmission=0.7,LayoutOrder=22},
	{Id="ToxicMist",Name="Toxic Mist Trail",Description="Poison aura. +7% speed, 1 dmg/sec to nearby players.",Category="Coin",Price=400,TrailType="SpeedPoison",SpeedBoost=0.07,DamagePerSec=1,AuraRadius=6,Color1=Color3.fromRGB(100,200,0),Color2=Color3.fromRGB(50,150,0),Lifetime=3.0,LightEmission=0.4,LayoutOrder=23},
	{Id="Storm",Name="Storm Trail",Description="Storm knockback. +9% speed, pushes nearby players.",Category="Coin",Price=450,TrailType="SpeedShock",SpeedBoost=0.09,ShockKnockback=8,SlowPercent=0.15,SlowDuration=1,AuraRadius=6,Color1=Color3.fromRGB(80,80,120),Color2=Color3.fromRGB(150,150,200),Lifetime=2.0,LightEmission=0.5,LayoutOrder=24},
	{Id="Drift",Name="Drift Trail",Description="Fast drift. +10% speed.",Category="Coin",Price=500,TrailType="Speed",SpeedBoost=0.10,Color1=Color3.fromRGB(200,200,255),Color2=Color3.fromRGB(100,150,255),Lifetime=1.5,LightEmission=0.6,LayoutOrder=25},
	{Id="Pulse",Name="Pulse Trail",Description="Pulsing energy. +8% speed, +3% jump.",Category="Coin",Price=550,TrailType="SpeedJump",SpeedBoost=0.08,JumpBoost=0.03,Color1=Color3.fromRGB(255,100,200),Color2=Color3.fromRGB(200,50,255),Lifetime=1.8,LightEmission=0.8,LayoutOrder=26},
	{Id="PhantomEcho",Name="Phantom Echo Trail",Description="Ghost style trail. +9% speed with afterimage.",Category="Coin",Price=600,TrailType="SpeedGhost",SpeedBoost=0.09,GhostAlpha=0.35,Color1=Color3.fromRGB(150,150,200),Color2=Color3.fromRGB(80,80,150),Lifetime=2.5,LightEmission=0.3,LayoutOrder=27},
	{Id="FreezeTime",Name="Freeze Time Trail",Description="Press E to freeze ALL players in black & white for 1.5s! 30s cooldown.",Category="Coin",Price=750,TrailType="Skill",SkillType="FreezeTime",SkillCooldown=30,SkillDuration=1.5,Color1=Color3.fromRGB(100,100,100),Color2=Color3.fromRGB(50,50,50),Lifetime=2.0,LightEmission=0.3,LayoutOrder=28},
	{Id="PhaseTrail",Name="Phase Trail",Description="Press E to walk through players and objects for 8s. 23s cooldown.",Category="Coin",Price=900,TrailType="Skill",SkillType="Phase",SkillCooldown=23,SkillDuration=8,Color1=Color3.fromRGB(200,180,255),Color2=Color3.fromRGB(100,50,200),Lifetime=2.0,LightEmission=0.5,LayoutOrder=29},
	{Id="ShockTrail",Name="Shock Trail",Description="Press E to push players 10 studs. +5% speed. 22s cooldown.",Category="Coin",Price=1000,TrailType="Skill",SkillType="Shockwave",SkillCooldown=22,SkillKnockback=10,SpeedBoost=0.05,Color1=Color3.fromRGB(255,255,100),Color2=Color3.fromRGB(255,200,0),Lifetime=1.5,LightEmission=1.0,LayoutOrder=30},
	{Id="MomentumTrail",Name="Momentum Trail",Description="Press E for +19% speed for 15s. Sustained boost. +6% passive. 30s CD.",Category="Coin",Price=1200,TrailType="Skill",SkillType="Momentum",SkillCooldown=30,SkillDuration=15,SkillSpeedMult=0.19,SpeedBoost=0.06,Color1=Color3.fromRGB(255,150,50),Color2=Color3.fromRGB(255,50,0),Lifetime=1.8,LightEmission=0.7,LayoutOrder=31},
	{Id="TeleportTrail",Name="Teleport Trail",Description="Press E to teleport 16 studs forward. +5% speed. 12s cooldown.",Category="Coin",Price=1500,TrailType="Skill",SkillType="Teleport",SkillCooldown=12,SkillDistance=16,SpeedBoost=0.05,Color1=Color3.fromRGB(150,0,255),Color2=Color3.fromRGB(50,0,150),Lifetime=2.0,LightEmission=0.6,LayoutOrder=32},
	{Id="DashTrail",Name="Dash Trail",Description="Press E to dash forward! 8s cooldown.",Category="Coin",Price=1500,TrailType="Skill",SkillType="Dash",SkillCooldown=8,SkillDistance=12,SpeedBoost=0.0,Color1=Color3.fromRGB(50,200,255),Color2=Color3.fromRGB(0,100,200),Lifetime=1.5,LightEmission=0.8,LayoutOrder=33},
	{Id="TimeRewindTrail",Name="Time Rewind Trail",Description="Press E to return to your position 2s ago. +5% speed. 20s CD.",Category="Coin",Price=1800,TrailType="Skill",SkillType="TimeRewind",SkillCooldown=20,SkillRewindTime=2,SpeedBoost=0.05,Color1=Color3.fromRGB(0,200,150),Color2=Color3.fromRGB(0,100,80),Lifetime=2.5,LightEmission=0.5,LayoutOrder=34},
	{Id="BomberTrail",Name="Bomber Trail",Description="Press E to drop a bomb. 3s fuse, 25 damage. +6% speed. 10s CD.",Category="Coin",Price=1800,TrailType="Skill",SkillType="Bomber",SkillCooldown=10,SkillDuration=3,SpeedBoost=0.06,Color1=Color3.fromRGB(200,200,200),Color2=Color3.fromRGB(100,100,100),Lifetime=2.0,LightEmission=0.4,LayoutOrder=35},
	{Id="SpeedBurstTrail",Name="Speed Burst Trail",Description="Press E for 2.5x speed burst for 5s. Short nitro boost! +6% passive. 15s CD.",Category="Coin",Price=2000,TrailType="Skill",SkillType="SpeedBurst",SkillCooldown=15,SkillDuration=5,SpeedBoost=0.06,Color1=Color3.fromRGB(255,50,50),Color2=Color3.fromRGB(255,200,0),Lifetime=1.5,LightEmission=1.0,LayoutOrder=36},
	{Id="Rainbow",Name="Rainbow Trail",Description="Press E for STAR POWER! 10s of fast rainbow colors, max speed, big jumps, invincibility. 45s CD.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Skill",SkillType="RainbowStar",SkillCooldown=45,SpeedBoost=0.10,JumpBoost=0.10,Rainbow=true,Lifetime=2.5,LightEmission=0.8,LayoutOrder=37},
	{Id="Galaxy",Name="Galaxy Trail",Description="Cosmic galaxy effect. +12% speed. Star-like particles orbit you.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Speed",SpeedBoost=0.12,GalaxyVFX=true,Color1=Color3.fromRGB(20,0,80),Color2=Color3.fromRGB(150,50,255),Lifetime=2.5,LightEmission=0.6,LayoutOrder=38},
	{Id="Lightning",Name="Lightning Trail",Description="Press E to zap players within 15 studs. 15 damage, 1s stun. +12% speed. 18s CD.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Skill",SkillType="LightningShock",SkillCooldown=18,SpeedBoost=0.12,SlowPercent=0.30,SlowDuration=0.5,ShockKnockback=8,AuraRadius=5,Color1=Color3.fromRGB(255,255,100),Color2=Color3.fromRGB(100,150,255),Lifetime=1.5,LightEmission=1.0,LayoutOrder=39},
	{Id="Void",Name="Void Trail",Description="Press E to place portals. Touch to teleport between them. 15s CD per portal. +6% speed.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Skill",SkillType="VoidPortal",SkillCooldown=15,SpeedBoost=0.06,GhostAlpha=0.40,Color1=Color3.fromRGB(0,0,0),Color2=Color3.fromRGB(20,0,40),Lifetime=2.0,LightEmission=0.0,LayoutOrder=40},
	{Id="Sakura",Name="Sakura Trail",Description="Press E for cherry blossom burst: heal to full + 15% speed + shield for 5s. 25s CD.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Skill",SkillType="SakuraBloom",SkillCooldown=25,SpeedBoost=0.08,RegenRate=1,Color1=Color3.fromRGB(255,180,200),Color2=Color3.fromRGB(255,100,150),Lifetime=2.5,LightEmission=0.5,LayoutOrder=41},
	{Id="Frost",Name="Frost Trail",Description="Press E to freeze players within 12 studs for 1.5s. 15% shield, +5% speed. 20s CD.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Skill",SkillType="FrostFreeze",SkillCooldown=20,SpeedBoost=0.05,ShieldPercent=0.15,Color1=Color3.fromRGB(180,220,255),Color2=Color3.fromRGB(220,240,255),Lifetime=2.2,LightEmission=0.7,LayoutOrder=42},
	{Id="Inferno",Name="Inferno Trail",Description="+15% speed. Max passive speed!",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Speed",SpeedBoost=0.15,Color1=Color3.fromRGB(255,0,0),Color2=Color3.fromRGB(255,255,0),Lifetime=2.5,LightEmission=1.0,LayoutOrder=43},
	{Id="Phantom",Name="Phantom Trail",Description="Press E: Spawn 3 clones + 30% speed for 4s. +9% passive speed. 20s CD.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Skill",SkillType="PhantomClone",SkillCooldown=20,SpeedBoost=0.09,GhostAlpha=0.50,Color1=Color3.fromRGB(200,200,220),Color2=Color3.fromRGB(100,100,140),Lifetime=2.0,LightEmission=0.3,LayoutOrder=44},
	{Id="Titan",Name="Titan Trail",Description="Press E for 10s shield. Blocks ragdolls and collisions. 30s CD. 20% passive shield, +10% jump.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Skill",SkillType="TitanShield",SkillCooldown=30,ShieldPercent=0.20,JumpBoost=0.10,Color1=Color3.fromRGB(150,100,50),Color2=Color3.fromRGB(200,160,80),Lifetime=2.5,LightEmission=0.4,LayoutOrder=45},
	{Id="Supernova",Name="Supernova Trail",Description="+12% speed +10% jump. Explosive combo.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="SpeedJump",SpeedBoost=0.12,JumpBoost=0.10,Color1=Color3.fromRGB(255,200,50),Color2=Color3.fromRGB(255,50,100),Lifetime=3.0,LightEmission=1.0,LayoutOrder=46},
	{Id="LowGravity",Name="Low Gravity Trail",Description="Press E: gravity field makes enemies float for 4s. 0.7 gravity +8% speed. 25s CD.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Skill",SkillType="GravityField",SkillCooldown=25,GravityMultiplier=0.7,SpeedBoost=0.08,GravityAuraRadius=8,Color1=Color3.fromRGB(100,80,200),Color2=Color3.fromRGB(50,0,100),Lifetime=2.5,LightEmission=0.6,LayoutOrder=47},
	{Id="AcidStorm",Name="Acid Storm Trail",Description="Press E: circle puddles follow you for 5s. 3 dmg/s, 30% slow. Passive puddles while moving. 18s CD.",Category="Premium",Price=0,RequiresGamepass=true,TrailType="Skill",SkillType="AcidPool",SkillCooldown=18,SpeedBoost=0.07,PuddleDrop=true,PuddleInterval=1.2,PuddleDuration=4,PuddleDamage=1,Color1=Color3.fromRGB(80,255,0),Color2=Color3.fromRGB(0,180,0),Lifetime=3.0,LightEmission=0.6,LayoutOrder=48},
}

local TRAIL_MAP = {}
for _, trail in ipairs(TRAILS) do TRAIL_MAP[trail.Id] = trail end
local ALWAYS_FREE = {White=true, Red=true, Blue=true, Green=true}

local gamepassCache = {}
local activeEffects = {}
local roundPurchases = {}
local trailMasterCache = {}

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, gamePassId, wasPurchased)
	-- #region agent log
	dbg("H6", "TrailShop:GamePassPurchaseFinished", "Purchase event fired", {player=plr.Name, gpId=gamePassId, wasPurchased=wasPurchased, expectedGpId=TRAILMASTER_GAMEPASS_ID, matches=gamePassId==TRAILMASTER_GAMEPASS_ID})
	-- #endregion
	if wasPurchased and gamePassId == TRAILMASTER_GAMEPASS_ID then
		trailMasterCache[plr.UserId] = true
		-- Persist to PlayerDataManager so it survives rejoins
		pcall(function()
			local pData = PlayerDataManager.GetData(plr)
			if pData then pData.HasTrailMaster = true end
			PlayerDataManager.SaveData(plr)
		end)
		if TrailUpdate then TrailUpdate:FireClient(plr, "Refresh") end
	end
end)

local function hasTrailMaster(plr)
	if trailMasterCache[plr.UserId] == true then
		-- #region agent log
		dbg("H6", "TrailShop:hasTrailMaster", "Cache HIT", {uid=plr.UserId, result=true})
		-- #endregion
		return true
	end
	-- Check PlayerDataManager saved state (persists across rejoins in Studio)
	local savedTM = false
	pcall(function()
		local pData = PlayerDataManager.GetData(plr)
		if pData and pData.HasTrailMaster then savedTM = true end
	end)
	if savedTM then
		trailMasterCache[plr.UserId] = true
		-- #region agent log
		dbg("H6", "TrailShop:hasTrailMaster", "Saved data HIT", {uid=plr.UserId})
		-- #endregion
		return true
	end
	local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, TRAILMASTER_GAMEPASS_ID) end)
	-- #region agent log
	dbg("H6", "TrailShop:hasTrailMaster", "API check", {uid=plr.UserId, ok=ok, owns=owns, gpId=TRAILMASTER_GAMEPASS_ID})
	-- #endregion
	if ok and owns then trailMasterCache[plr.UserId] = true return true end
	return false
end

local function isOwned(plr, trailId)
	if ALWAYS_FREE[trailId] then return true end
	local trail = TRAIL_MAP[trailId] if not trail then return false end
	if trail.RequiresGamepass then return hasTrailMaster(plr) end
	if trail.Category == "Coin" then local rp = roundPurchases[plr.UserId] return rp ~= nil and rp[trailId] == true end
	return false
end

local function buildOwnedTable(plr)
	local owned = {}
	local hasTM = hasTrailMaster(plr)
	local rp = roundPurchases[plr.UserId]
	local hasCoinTrail = false
	if rp then for _ in pairs(rp) do hasCoinTrail = true break end end
	for _, trail in ipairs(TRAILS) do
		if ALWAYS_FREE[trail.Id] then owned[trail.Id] = true
		elseif trail.RequiresGamepass then owned[trail.Id] = hasTM
		elseif trail.Category == "Coin" then
			if rp and rp[trail.Id] then owned[trail.Id] = true
			elseif hasCoinTrail then owned[trail.Id] = "locked"
			else owned[trail.Id] = false end
		else owned[trail.Id] = false end
	end
	return owned
end

local function getEquippedValidated(plr)
	local eq = PlayerDataManager.GetEquippedTrail(plr)
	if not eq or eq == "" then return nil end
	if not TRAIL_MAP[eq] then PlayerDataManager.SetEquippedTrail(plr, nil) return nil end
	if not isOwned(plr, eq) then PlayerDataManager.SetEquippedTrail(plr, nil) return nil end
	return eq
end

local function removeTrailVisual(plr)
	local char = plr.Character if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, c in pairs(hrp:GetChildren()) do if c.Name == "TrailAttach0" or c.Name == "TrailAttach1" then c:Destroy() end end
		for _, c in pairs(hrp:GetDescendants()) do if c:IsA("Trail") and c.Name == "PlayerTrail" then c:Destroy() end end
	end
	for _, c in pairs(char:GetDescendants()) do if c.Name == "TrailParticle" or c.Name == "TrailGravity" then c:Destroy() end end
end

local function removeTrailEffects(plr)
	local uid = plr.UserId
	if activeEffects[uid] then
		for _, conn in ipairs(activeEffects[uid].connections or {}) do
			if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
		end
		if activeEffects[uid].gravityPart and activeEffects[uid].gravityPart.Parent then activeEffects[uid].gravityPart:Destroy() end
		activeEffects[uid] = nil
	end
	local char = plr.Character if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if hum then hum.WalkSpeed = char:GetAttribute("BaseWalkSpeed") or 16 hum.JumpPower = char:GetAttribute("BaseJumpPower") or 50 hum.AutoRotate = true end
	char:SetAttribute("TrailShield", 0)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local orig = part:GetAttribute("OriginalTransparency") if orig then part.Transparency = orig end
		end
	end
end

local function removeFullTrail(plr)
	removeTrailVisual(plr) removeTrailEffects(plr)
	if _G.OnTrailEquipped then pcall(function() _G.OnTrailEquipped(plr, nil) end) end
end

local function applyTrailVisual(plr, td)
	local char = plr.Character if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end
	removeTrailVisual(plr)
	local uid = plr.UserId
	if not activeEffects[uid] then activeEffects[uid] = {connections = {}} end
	local a0 = Instance.new("Attachment") a0.Name = "TrailAttach0" a0.Position = Vector3.new(0,1,0) a0.Parent = hrp
	local a1 = Instance.new("Attachment") a1.Name = "TrailAttach1" a1.Position = Vector3.new(0,-1,0) a1.Parent = hrp
	local trail = Instance.new("Trail") trail.Name = "PlayerTrail" trail.Attachment0 = a0 trail.Attachment1 = a1
	trail.Lifetime = td.Lifetime or 1.5 trail.MinLength = 0.1 trail.FaceCamera = true
	trail.LightEmission = td.LightEmission or 0.3 trail.LightInfluence = 0.3
	trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0,3),NumberSequenceKeypoint.new(0.5,1.5),NumberSequenceKeypoint.new(1,0)})
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.7,0.3),NumberSequenceKeypoint.new(1,1)})
	if td.Rainbow then trail.Color = ColorSequence.new(Color3.fromHSV(0,1,1),Color3.fromHSV(0.5,1,1))
	else trail.Color = ColorSequence.new(td.Color1, td.Color2) end
	trail.Parent = hrp
	if td.Rainbow then
		local hue = 0
		local c = RunService.Heartbeat:Connect(function(dt) hue = (hue+dt*0.3)%1 if trail and trail.Parent then trail.Color = ColorSequence.new(Color3.fromHSV(hue,1,1),Color3.fromHSV((hue+0.5)%1,1,1)) end end)
		table.insert(activeEffects[uid].connections, c)
	end
	if td.LightEmission and td.LightEmission >= 0.7 then
		local p = Instance.new("ParticleEmitter") p.Name = "TrailParticle"
		p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		p.Rate = 15 p.Lifetime = NumberRange.new(0.3,0.8) p.Speed = NumberRange.new(1,3)
		p.Size = NumberSequence.new(0.3) p.SpreadAngle = Vector2.new(180,180)
		p.Color = td.Rainbow and ColorSequence.new(Color3.fromRGB(255,255,255)) or ColorSequence.new(td.Color1, td.Color2)
		p.Parent = hrp
	end
end

local function applyTrailEffects(plr, td)
	removeTrailEffects(plr)
	local char = plr.Character if not char then return end
	local hum = char:FindFirstChild("Humanoid") if not hum then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end
	local uid = plr.UserId
	if not activeEffects[uid] then activeEffects[uid] = {connections = {}} end
	local baseSpeed = char:GetAttribute("BaseWalkSpeed") or hum.WalkSpeed
	local baseJump = char:GetAttribute("BaseJumpPower") or hum.JumpPower
	char:SetAttribute("BaseWalkSpeed", baseSpeed) char:SetAttribute("BaseJumpPower", baseJump)
	local fs, fj = baseSpeed, baseJump
	if td.SpeedBoost and td.SpeedBoost > 0 then fs = fs * (1 + td.SpeedBoost) end
	if td.JumpBoost and td.JumpBoost > 0 then fj = fj * (1 + td.JumpBoost) end
	if _G.HasGamepass and _G.HasGamepass(plr, "SpeedBoost") then fs = fs * 1.10 end
	hum.WalkSpeed = fs hum.JumpPower = fj
	if td.ShieldPercent and td.ShieldPercent > 0 then char:SetAttribute("TrailShield", td.ShieldPercent)
	else char:SetAttribute("TrailShield", 0) end
	if td.GhostAlpha and td.GhostAlpha > 0 then
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				if not part:GetAttribute("OriginalTransparency") then part:SetAttribute("OriginalTransparency", part.Transparency) end
				part.Transparency = math.min(part.Transparency + td.GhostAlpha, 0.9)
			end
		end
	end
	if td.RegenRate and td.RegenRate > 0 then
		local c = RunService.Heartbeat:Connect(function(dt)
			if not hum or not hum.Parent or hum.Health <= 0 then return end
			local blockedUntil = char:GetAttribute("RegenBlockedUntil") or 0
			if tick() < blockedUntil then return end
			hum.Health = math.min(hum.Health + td.RegenRate * dt, hum.MaxHealth)
		end)
		table.insert(activeEffects[uid].connections, c)
	end
	if td.GravityMultiplier and td.GravityMultiplier < 1 then
		local ag = Instance.new("BodyForce") ag.Name = "TrailGravity"
		ag.Force = Vector3.new(0, hrp:GetMass() * workspace.Gravity * (1 - td.GravityMultiplier), 0) ag.Parent = hrp
		activeEffects[uid].gravityPart = ag
	end
	if td.GravityAuraRadius and td.GravityAuraRadius > 0 then
		local r = td.GravityAuraRadius
		local gravAuraConn = RunService.Heartbeat:Connect(function()
			if not char or not char.Parent or not hrp or not hrp.Parent then return end
			if not isRoundActive() then return end
			for _, o in pairs(Players:GetPlayers()) do
				if o ~= plr and o.Character then
					local oH = o.Character:FindFirstChild("HumanoidRootPart")
					local oU = o.Character:FindFirstChild("Humanoid")
					if oH and oU and oU.Health > 0 then
						local d = (oH.Position - hrp.Position).Magnitude
						if d <= r and d >= 0.5 then
							local existing = oH:FindFirstChild("GravityAuraForce")
							if not existing then
								local bf = Instance.new("BodyForce")
								bf.Name = "GravityAuraForce"
								bf.Force = Vector3.new(0, oH:GetMass() * workspace.Gravity * 0.3, 0)
								bf.Parent = oH
								task.delay(0.5, function() if bf and bf.Parent then bf:Destroy() end end)
							end
						end
					end
				end
			end
		end)
		table.insert(activeEffects[uid].connections, gravAuraConn)
	end
	local function validTarget(o) if o == plr or not o.Character then return nil,nil,nil end
		local oh = o.Character:FindFirstChild("HumanoidRootPart") local ou = o.Character:FindFirstChild("Humanoid")
		if not oh or not ou or ou.Health <= 0 then return nil,nil,nil end return o.Character, oh, ou end
	local function isInAura(oH, tH, r)
		if not oH or not oH.Parent or not tH or not tH.Parent then return false end
		local d = (tH.Position - oH.Position).Magnitude
		return d <= r and d >= 0.5
	end
	local function restoreSpd(op, ou, fb, fbj) if not ou or not ou.Parent then return end
		local oc = op.Character if not oc then ou.WalkSpeed = fb ou.JumpPower = fbj return end
		local ob = oc:GetAttribute("BaseWalkSpeed") or 16 local obj = oc:GetAttribute("BaseJumpPower") or 50
		local eq = nil pcall(function() eq = PlayerDataManager.GetEquippedTrail(op) end)
		if eq and TRAIL_MAP[eq] then local t = TRAIL_MAP[eq] ou.WalkSpeed = ob*(1+(t.SpeedBoost or 0)) ou.JumpPower = obj*(1+(t.JumpBoost or 0))
		else ou.WalkSpeed = ob ou.JumpPower = obj end end
	if td.SlowPercent and td.SlowPercent > 0 then
		local cd = {}
		local r = math.max(3, (td.AuraRadius or 6) - 1)
		local c = RunService.Heartbeat:Connect(function() if not char or not char.Parent or not hrp or not hrp.Parent then return end
			if not isRoundActive() then return end
			for _, o in pairs(Players:GetPlayers()) do local _, oH, oU = validTarget(o)
				if oH and oU and not cd[o.UserId] and isInAura(hrp, oH, r) then cd[o.UserId] = true
					local ss = oU.WalkSpeed oU.WalkSpeed = ss * (1 - td.SlowPercent)
					if td.ShockKnockback and td.ShockKnockback > 0 then
						local dir = (oH.Position - hrp.Position) if dir.Magnitude > 0.1 then dir = dir.Unit else dir = Vector3.new(1,0,0) end
						oH.AssemblyLinearVelocity = dir * td.ShockKnockback + Vector3.new(0,10,0)
						LightningShockEffectRemote:FireClient(o, td.SlowDuration or 0.5)
						NotifyClientRemote:FireClient(o, "Shocked!", plr.DisplayName .. " shocked you!", 1.5, "warning")
						local zap = Instance.new("Part")
						zap.Name = "TrailShockPulse"
						zap.Shape = Enum.PartType.Ball
						zap.Size = Vector3.new(5, 5, 5)
						zap.CFrame = oH.CFrame
						zap.Anchored = true
						zap.CanCollide = false
						zap.Material = Enum.Material.Neon
						zap.Color = Color3.fromRGB(255, 245, 120)
						zap.Transparency = 0.55
						zap.Parent = workspace
						Debris:AddItem(zap, 0.4)
						-- #region agent log
						dbg("H_LT3", "TrailShop:ShockAura", "ShockAura target stunned", {owner=plr.Name, target=o.Name, radius=r, distance=math.floor(((oH.Position - hrp.Position).Magnitude) * 100) / 100})
						-- #endregion
					end
					task.spawn(function() task.wait(td.SlowDuration or 1.5) restoreSpd(o, oU, ss, 50) task.wait(3) cd[o.UserId] = nil end)
				end end end)
		table.insert(activeEffects[uid].connections, c)
	end
	if td.FreezeDuration and td.FreezeDuration > 0 then
		local cd = {} local r = (td.FreezeRadius or 5) + 4
		local lastFreezeLog = 0
		local c = RunService.Heartbeat:Connect(function() if not char or not char.Parent or not hrp or not hrp.Parent then return end
			if not isRoundActive() then return end
			local nearest = math.huge
			local candidateCt = 0
			for _, o in pairs(Players:GetPlayers()) do local _, oH, oU = validTarget(o)
				if oH and oU then
					local dNow = (oH.Position - hrp.Position).Magnitude
					if dNow < nearest then nearest = dNow end
				end
				if oH and oU and not cd[o.UserId] and isInAura(hrp, oH, r) then candidateCt = candidateCt + 1 cd[o.UserId] = true
					local ss, sj = oU.WalkSpeed, oU.JumpPower oU.WalkSpeed = 0 oU.JumpPower = 0 oU.AutoRotate = false oH.AssemblyLinearVelocity = Vector3.zero
					local ice = Instance.new("Part") ice.Name = "TrailFreeze" ice.Size = Vector3.new(5,7,5) ice.CFrame = oH.CFrame
					ice.Anchored = true ice.CanCollide = false ice.Material = Enum.Material.Ice ice.Color = Color3.fromRGB(150,220,255) ice.Transparency = 0.4 ice.Parent = workspace
					Debris:AddItem(ice, td.FreezeDuration + 1)
					-- #region agent log
					dbg("H_FR2", "TrailShop:SpeedFreeze", "Freeze applied", {owner=plr.Name, target=o.Name, radius=r, freezeDuration=td.FreezeDuration, distance=math.floor(((oH.Position - hrp.Position).Magnitude) * 100) / 100})
					-- #endregion
					task.spawn(function() task.wait(td.FreezeDuration) if ice and ice.Parent then ice:Destroy() end
						if oU and oU.Parent then oU.AutoRotate = true restoreSpd(o, oU, ss, sj) end task.wait(6) cd[o.UserId] = nil end)
				end
			end
			if tick() - lastFreezeLog >= 1.5 then
				lastFreezeLog = tick()
				-- #region agent log
				dbg("H_FR2", "TrailShop:SpeedFreeze", "Freeze scan tick", {owner=plr.Name, radius=r, candidatesThisTick=candidateCt, nearestEnemy=nearest == math.huge and -1 or math.floor(nearest * 100) / 100})
				-- #endregion
			end
		end)
		table.insert(activeEffects[uid].connections, c)
	end
	if td.DamagePerSec and td.DamagePerSec > 0 then
		local r = (td.AuraRadius or 6) + 2
		local c = RunService.Heartbeat:Connect(function(dt) if not char or not char.Parent or not hrp or not hrp.Parent then return end
			if not isRoundActive() then return end
			for _, o in pairs(Players:GetPlayers()) do local oChar, oH, oU = validTarget(o)
				if oChar and oH and oU and isInAura(hrp, oH, r) then
					oChar:SetAttribute("RegenBlockedUntil", tick() + 0.4)
					oU:TakeDamage(td.DamagePerSec * dt)
				end
			end
		end)
		table.insert(activeEffects[uid].connections, c)
	end
	if td.PuddleDrop and (td.Id == "AcidSlime" or td.Id == "AcidStorm") then
		local puddleInterval = td.PuddleInterval or 1.5
		local puddleDuration = td.PuddleDuration or 4
		local puddleDamage = td.PuddleDamage or 1
		local puddleLast = 0
		local puddleConn = RunService.Heartbeat:Connect(function(dt)
			if not char or not char.Parent or not hrp or not hrp.Parent then return end
			if not isRoundActive() then return end
			local vel = hrp.AssemblyLinearVelocity
			local spd = Vector3.new(vel.X, 0, vel.Z).Magnitude
			if spd < 3 then return end
			if tick() - puddleLast < puddleInterval then return end
			puddleLast = tick()
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {char}
			local groundRay = workspace:Raycast(hrp.Position + Vector3.new(0, 5, 0), Vector3.new(0, -40, 0), rayParams)
			local pos = groundRay and groundRay.Position or hrp.Position
			local size = td.Id == "AcidStorm" and Vector3.new(0.3, 4, 4) or Vector3.new(0.3, 3, 3) -- X=thickness, Y/Z=diameter
			local pool = Instance.new("Part")
			pool.Name = "AcidPuddle_" .. plr.Name
			pool.Size = size pool.Shape = Enum.PartType.Cylinder
			local n = groundRay and groundRay.Normal or Vector3.new(0, 1, 0)
			if n.Y < 0.99 then
				local tangent = n:Cross(Vector3.new(0, 1, 0))
				if tangent.Magnitude < 0.01 then tangent = n:Cross(Vector3.new(1, 0, 0)) end
				tangent = tangent.Unit
				pool.CFrame = CFrame.fromMatrix(pos + n * (size.X / 2), n, tangent)
			else
				pool.CFrame = CFrame.new(pos + Vector3.new(0, size.X / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
			end
			pool.Anchored = true pool.CanCollide = false pool.Material = Enum.Material.Neon
			pool.Color = Color3.fromRGB(80, 255, 0) pool.Transparency = (td.Id == "AcidStorm" and 0.3 or 0.45) pool.Parent = workspace
			Debris:AddItem(pool, puddleDuration + 1)
			local puddleEnd = tick() + puddleDuration
			local damageConn
			local ownerUid = plr.UserId
			damageConn = RunService.Heartbeat:Connect(function(dt2)
				if not pool or not pool.Parent or tick() > puddleEnd then if damageConn then damageConn:Disconnect() end return end
				local center = pool.Position local rad = (pool.Size.Y + pool.Size.Z) / 4
				for _, o in pairs(Players:GetPlayers()) do
					if o.UserId ~= ownerUid and o.Character then
						local oH = o.Character:FindFirstChild("HumanoidRootPart")
						local oU = o.Character:FindFirstChild("Humanoid")
						if oH and oU and oU.Health > 0 then
							local d = (oH.Position - center).Magnitude
							if d <= rad then
								o.Character:SetAttribute("RegenBlockedUntil", tick() + 0.5)
								oU:TakeDamage(puddleDamage * dt2)
							end
						end
					end
				end
			end)
			task.delay(puddleDuration + 1, function() if damageConn then damageConn:Disconnect() end end)
		end)
		table.insert(activeEffects[uid].connections, puddleConn)
	end
	if td.MagnetRadius and td.MagnetRadius > 0 then
		local mr = td.MagnetRadius
		local c = RunService.Heartbeat:Connect(function() if not char or not char.Parent or not hrp or not hrp.Parent then return end
			for _, coin in pairs(workspace:GetDescendants()) do
				if coin.Name == "ActiveCoin" and coin:IsA("BasePart") then
					local d = (coin.Position - hrp.Position).Magnitude if d <= mr and d > 2 then coin.Position = coin.Position + (hrp.Position - coin.Position).Unit * 1.5 end end end end)
		table.insert(activeEffects[uid].connections, c)
	end
	if td.GhostAlpha and td.GhostAlpha > 0 then
		local lastSpawn = 0
		local afterConn = RunService.Heartbeat:Connect(function()
			if not char or not char.Parent or not hrp or not hrp.Parent then return end
			local vel = hrp.AssemblyLinearVelocity
			local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
			if speed < 3 then return end
			if tick() - lastSpawn < 0.12 then return end
			lastSpawn = tick()
			for _, part in pairs(char:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					local ghost = Instance.new("Part") ghost.Name = "TrailGhost" ghost.Size = part.Size ghost.CFrame = part.CFrame
					ghost.Anchored = true ghost.CanCollide = false ghost.Material = Enum.Material.Neon ghost.Transparency = 0.4
					ghost.Color = td.Color1 or Color3.fromRGB(200,180,255) ghost.Parent = workspace
					local mesh = part:FindFirstChildWhichIsA("SpecialMesh") or part:FindFirstChildWhichIsA("DataModelMesh")
					if mesh then pcall(function() mesh:Clone().Parent = ghost end) end
					task.spawn(function() for t = 1, 8 do task.wait(0.05) if ghost and ghost.Parent then ghost.Transparency = 0.4 + (t*0.075) end end if ghost and ghost.Parent then ghost:Destroy() end end)
				end
			end
			for _, acc in pairs(char:GetChildren()) do
				if acc:IsA("Accessory") then local handle = acc:FindFirstChild("Handle")
					if handle and handle:IsA("BasePart") then
						local ghost = Instance.new("Part") ghost.Name = "TrailGhost" ghost.Size = handle.Size ghost.CFrame = handle.CFrame
						ghost.Anchored = true ghost.CanCollide = false ghost.Material = Enum.Material.Neon ghost.Transparency = 0.4
						ghost.Color = td.Color1 or Color3.fromRGB(200,180,255) ghost.Parent = workspace
						local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
						if mesh then pcall(function() mesh:Clone().Parent = ghost end) end
						task.spawn(function() for t = 1, 8 do task.wait(0.05) if ghost and ghost.Parent then ghost.Transparency = 0.4 + (t*0.075) end end if ghost and ghost.Parent then ghost:Destroy() end end)
					end end
			end
		end)
		table.insert(activeEffects[uid].connections, afterConn)
	end
	local BlindRemote = remoteFolder:FindFirstChild("BlindEffect")
	-- BLIND LOBBY CHECK
	local GVB = game.ReplicatedStorage:FindFirstChild("GameValues")
	local GSB = GVB and GVB:FindFirstChild("GameState")
	if BlindRemote and (td.Id == "Shadow" or td.Id == "Void") then
		local blindCD = {}
		local blindType = td.Id == "Void" and "void" or "shadow"
		local blindRadius = td.Id == "Void" and 8 or 6
		local blindDuration = td.Id == "Void" and 2.5 or 1.5
		local blindConn = RunService.Heartbeat:Connect(function()
			if not char or not char.Parent or not hrp or not hrp.Parent then return end
			if GSB and GSB.Value ~= "Playing" then return end
			for _, o in pairs(Players:GetPlayers()) do
				if o ~= plr and o.Character then
					local oH = o.Character:FindFirstChild("HumanoidRootPart")
					local oU = o.Character:FindFirstChild("Humanoid")
					if oH and oU and oU.Health > 0 and not blindCD[o.UserId] then
						local diff = oH.Position - hrp.Position local dist = diff.Magnitude
						if dist <= blindRadius and dist > 0.5 then
							local dot = hrp.CFrame.LookVector:Dot(diff.Unit)
							if dot < -0.1 then blindCD[o.UserId] = true
								BlindRemote:FireClient(o, true, blindDuration, blindType, plr.Name)
								task.spawn(function() task.wait(blindDuration + 3) blindCD[o.UserId] = nil end)
							end end end end end end)
		table.insert(activeEffects[uid].connections, blindConn)
	end
	if td.GalaxyVFX or td.Id == "Galaxy" then
		local galaxyLast = 0
		local galaxyConn = RunService.Heartbeat:Connect(function()
			if not char or not char.Parent or not hrp or not hrp.Parent then return end
			if tick() - galaxyLast < 0.15 then return end
			galaxyLast = tick()
			local t = tick()
			for i = 1, 2 do
				local angle = (t * 2 + i * math.pi) % (2 * math.pi)
				local r = 4 local y = math.sin(t * 3) * 1
				local offset = Vector3.new(math.cos(angle) * r, y, math.sin(angle) * r)
				local orb = Instance.new("Part")
				orb.Name = "GalaxyOrb" orb.Shape = Enum.PartType.Ball orb.Size = Vector3.new(0.6, 0.6, 0.6)
				orb.CFrame = hrp.CFrame * CFrame.new(offset)
				orb.Anchored = true orb.CanCollide = false orb.Material = Enum.Material.Neon
				orb.Color = Color3.fromRGB(80 + math.floor(50 * math.sin(t + i)), 50, 180 + math.floor(75 * math.cos(t * 0.7)))
				orb.Transparency = 0.3 orb.Parent = workspace
				task.spawn(function() for j = 1, 6 do task.wait(0.05) if orb and orb.Parent then orb.Transparency = 0.3 + (j * 0.1) end end if orb and orb.Parent then orb:Destroy() end end)
				Debris:AddItem(orb, 1)
			end
		end)
		table.insert(activeEffects[uid].connections, galaxyConn)
	end
	if td.Id == "Void" then
		local fogLast = 0
		local fogConn = RunService.Heartbeat:Connect(function()
			if not char or not char.Parent or not hrp or not hrp.Parent then return end
			if tick() - fogLast < 0.25 then return end fogLast = tick()
			local fog = Instance.new("Part") fog.Name = "VoidFog"
			fog.Size = Vector3.new(math.random(2,4), math.random(1,2), math.random(2,4))
			fog.CFrame = hrp.CFrame * CFrame.new(math.random(-4,4), math.random(-1,3), math.random(-4,4))
			fog.Anchored = true fog.CanCollide = false fog.Material = Enum.Material.Neon
			fog.Color = Color3.fromRGB(10,0,20) fog.Transparency = 0.6 fog.Parent = workspace
			task.spawn(function() for t = 1, 8 do task.wait(0.06) if fog and fog.Parent then fog.Transparency = 0.6 + (t*0.05) end end if fog and fog.Parent then fog:Destroy() end end)
		end)
		table.insert(activeEffects[uid].connections, fogConn)
	end
	-- SOLAR LOBBY CHECK
	local GVS = game.ReplicatedStorage:FindFirstChild("GameValues")
	local GSS = GVS and GVS:FindFirstChild("GameState")
	if td.Id == "Solar" then
		local SB = remoteFolder:FindFirstChild("BlindEffect")
		if SB then
			local fCD = {} local fTimer = 0
			local sConn = RunService.Heartbeat:Connect(function(dt)
				if not char or not char.Parent or not hrp or not hrp.Parent then return end
				if GSS and GSS.Value ~= "Playing" then return end
				local vel = hrp.AssemblyLinearVelocity local spd = Vector3.new(vel.X,0,vel.Z).Magnitude
				if spd < 3 then return end fTimer = fTimer + dt if fTimer < 4 then return end fTimer = 0
				local ring = Instance.new("Part") ring.Name = "SolarFlash" ring.Shape = Enum.PartType.Ball
				ring.Size = Vector3.new(3,3,3) ring.CFrame = hrp.CFrame ring.Anchored = true ring.CanCollide = false
				ring.Material = Enum.Material.Neon ring.Color = Color3.fromRGB(255,230,100) ring.Transparency = 0.2 ring.Parent = workspace
				task.spawn(function() for t = 1, 10 do task.wait(0.03) if ring and ring.Parent then local s = 3+(t*3) ring.Size = Vector3.new(s,s,s) ring.Transparency = 0.2+(t*0.08) end end if ring and ring.Parent then ring:Destroy() end end)
				for _, o in pairs(Players:GetPlayers()) do
					if o ~= plr and o.Character and not fCD[o.UserId] then
						local oH = o.Character:FindFirstChild("HumanoidRootPart")
						if oH and (oH.Position - hrp.Position).Magnitude <= 12 then
							fCD[o.UserId] = true SB:FireClient(o, true, 1.2, "solar", plr.Name)
							task.spawn(function() task.wait(6) fCD[o.UserId] = nil end)
						end end end
			end)
			table.insert(activeEffects[uid].connections, sConn)
		end
	end
end
local function applyFullTrail(plr, td)
	applyTrailVisual(plr, td) applyTrailEffects(plr, td)
	if _G.OnTrailEquipped then pcall(function() _G.OnTrailEquipped(plr, td) end) end
	local nc = remoteFolder:FindFirstChild("NotifyClient")
	if nc then nc:FireClient(plr,"Trail Equipped!",td.Name.." is now active!",3,"trail") end
end
local function resetRoundPurchases()
	for _,plr in pairs(Players:GetPlayers()) do
		local eq=PlayerDataManager.GetEquippedTrail(plr)
		if eq and eq~="" then local t=TRAIL_MAP[eq]
			if t and t.Category=="Coin" then removeFullTrail(plr) PlayerDataManager.SetEquippedTrail(plr,"")
				TrailUpdate:FireClient(plr,"Unequipped","") end end end
	roundPurchases={} print("Round purchases reset") end
_G.ResetCoinTrails=resetRoundPurchases
local function handlePurchase(plr,trailId)
	-- #region agent log
	dbg("H6", "TrailShop:handlePurchase", "Purchase attempt", {player=plr.Name, trailId=trailId})
	-- #endregion
	local trail=TRAIL_MAP[trailId] if not trail then return end
	local GV=ReplicatedStorage:FindFirstChild("GameValues")
	if GV then local GS=GV:FindFirstChild("GameState")
		if GS and GS.Value=="Playing" then return end end
	if trail.RequiresGamepass and not hasTrailMaster(plr) then
		-- #region agent log
		dbg("H6", "TrailShop:handlePurchase", "BLOCKED: No gamepass", {player=plr.Name, trailId=trailId})
		-- #endregion
		TrailUpdate:FireClient(plr,"NeedGamepass",trailId) return
	end
	if ALWAYS_FREE[trailId] or (trail.RequiresGamepass and hasTrailMaster(plr)) then
		PlayerDataManager.SetEquippedTrail(plr,trailId) applyFullTrail(plr,trail) TrailUpdate:FireClient(plr,"Equipped",trailId) return end
	if roundPurchases[plr.UserId] and roundPurchases[plr.UserId][trailId] then
		PlayerDataManager.SetEquippedTrail(plr,trailId) applyFullTrail(plr,trail) TrailUpdate:FireClient(plr,"Equipped",trailId) return end
	if trail.Category=="Coin" and roundPurchases[plr.UserId] then
		for eid,_ in pairs(roundPurchases[plr.UserId]) do if eid~=trailId then return end end end
	local coins=PlayerDataManager.GetCoins(plr)
	if coins<trail.Price then TrailUpdate:FireClient(plr,"NotEnoughCoins",trailId) return end
	PlayerDataManager.RemoveCoins(plr,trail.Price)
	if not roundPurchases[plr.UserId] then roundPurchases[plr.UserId]={} end
	roundPurchases[plr.UserId][trailId]=true
	PlayerDataManager.SetEquippedTrail(plr,trailId)
	pcall(function() PlayerDataManager.SaveData(plr) end)
	applyFullTrail(plr,trail) TrailUpdate:FireClient(plr,"Purchased",trailId)
end
local function handleEquip(plr,trailId)
	local trail=TRAIL_MAP[trailId] if not trail then return end
	if ALWAYS_FREE[trailId] then
		PlayerDataManager.SetEquippedTrail(plr,trailId) applyFullTrail(plr,trail) TrailUpdate:FireClient(plr,"Equipped",trailId) return end
	if trail.RequiresGamepass then
		if hasTrailMaster(plr) then PlayerDataManager.SetEquippedTrail(plr,trailId) applyFullTrail(plr,trail) TrailUpdate:FireClient(plr,"Equipped",trailId)
		else TrailUpdate:FireClient(plr,"NeedGamepass",trailId) end return end
	if roundPurchases[plr.UserId] and roundPurchases[plr.UserId][trailId] then
		PlayerDataManager.SetEquippedTrail(plr,trailId) applyFullTrail(plr,trail) TrailUpdate:FireClient(plr,"Equipped",trailId)
	else TrailUpdate:FireClient(plr,"NeedPurchase",trailId) end
end
local function handleUnequip(plr)
	PlayerDataManager.SetEquippedTrail(plr,nil) removeFullTrail(plr) TrailUpdate:FireClient(plr,"Unequipped","")
end
TrailEquip.OnServerEvent:Connect(function(plr,action,trailId)
	if typeof(action)~="string" then return end
	if action=="Purchase" then handlePurchase(plr,trailId)
	elseif action=="Equip" then handleEquip(plr,trailId)
	elseif action=="Unequip" then handleUnequip(plr) end
end)
GetTrailShopData.OnServerInvoke=function(plr)
	-- #region agent log
	dbg("SHOP", "TrailShop:GetTrailShopData", "Invoke called", {player=plr.Name, uid=plr.UserId})
	-- #endregion
	local ok, result = pcall(function()
		return {Trails=TRAILS,Owned=buildOwnedTable(plr),Equipped=getEquippedValidated(plr),HasTrailMaster=hasTrailMaster(plr)}
	end)
	-- #region agent log
	dbg("SHOP", "TrailShop:GetTrailShopData", "Invoke result", {player=plr.Name, ok=ok, hasResult=result~=nil, errMsg=not ok and tostring(result) or nil, trailCount=ok and result and result.Trails and #result.Trails or 0})
	-- #endregion
	if ok then return result end
	warn("GetTrailShopData error for", plr.Name, ":", result)
	return nil
end
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function() task.wait(1)
		local eq=getEquippedValidated(plr) if eq then local t=TRAIL_MAP[eq] if t then applyFullTrail(plr,t) end end end)
	if plr.Character then task.spawn(function() task.wait(1)
		local eq=getEquippedValidated(plr) if eq then local t=TRAIL_MAP[eq] if t then applyFullTrail(plr,t) end end end) end
end)
Players.PlayerRemoving:Connect(function(plr)
	trailMasterCache[plr.UserId]=nil removeFullTrail(plr)
	activeEffects[plr.UserId]=nil gamepassCache[plr.UserId]=nil roundPurchases[plr.UserId]=nil
	pcall(function() PlayerDataManager.SaveData(plr) end)
end)
-- SETTINGS PERSISTENCE
local SaveSettings = getOrCreate("SaveSettings")
SaveSettings.OnServerEvent:Connect(function(plr, soundVol, shakeEnabled, particlesEnabled)
	pcall(function()
		plr:SetAttribute("Setting_SoundVolume", tonumber(soundVol) or 0.8)
		plr:SetAttribute("Setting_ScreenShake", shakeEnabled ~= false)
		plr:SetAttribute("Setting_Particles", particlesEnabled ~= false)
		local pData = PlayerDataManager.GetData(plr)
		if pData then
			pData.Settings = {
				SoundVolume = tonumber(soundVol) or 0.8,
				ScreenShake = shakeEnabled ~= false,
				Particles = particlesEnabled ~= false,
			}
		end
		pcall(function() PlayerDataManager.SaveData(plr) end)
	end)
end)

-- Load settings for player on join
local function loadPlayerSettings(plr)
	pcall(function()
		local pData = PlayerDataManager.GetData(plr)
		if pData and pData.Settings then
			plr:SetAttribute("Setting_SoundVolume", pData.Settings.SoundVolume or 0.8)
			plr:SetAttribute("Setting_ScreenShake", pData.Settings.ScreenShake ~= false)
			plr:SetAttribute("Setting_Particles", pData.Settings.Particles ~= false)
		end
	end)
end

-- Hook into existing PlayerAdded - load settings
for _, p in pairs(Players:GetPlayers()) do task.spawn(function() loadPlayerSettings(p) end) end
Players.PlayerAdded:Connect(function(p) task.spawn(function() task.wait(1) loadPlayerSettings(p) end) end)

print("Trail Shop Handler v7 loaded!")
local fc,cc,pc=0,0,0
for _,t in ipairs(TRAILS) do if t.Category=="Free" then fc=fc+1 elseif t.Category=="Coin" then cc=cc+1 elseif t.Category=="Premium" then pc=pc+1 end end
print("  Total:",#TRAILS,"| Free:",fc,"| Coin:",cc,"| Premium:",pc)
-- ROUND LOCK SYSTEM
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GVS = RS:FindFirstChild("GameValues")
local GS = GVS and GVS:FindFirstChild("GameState")

local function resetRoundLocks()
	for _, p in pairs(Players:GetPlayers()) do
		p:SetAttribute("TrailEquippedThisRound", false)
		p:SetAttribute("TrailPurchasedThisRound", false)
	end
end

if GS then
	GS.Changed:Connect(function(v)
		if v == "Intermission" or v == "RoundEnd" then
			resetRoundLocks()
		end
	end)
end

local function canPurchase(player)
	if player:GetAttribute("TrailPurchasedThisRound") then
		local re = RS:FindFirstChild("RemoteEvents")
		local notify = re and re:FindFirstChild("NotifyClient")
		if notify then
			notify:FireClient(player, "Locked", "You already bought a trail this round!", 2, "warning")
		end
		return false
	end
	return true
end

local function canEquip(player)
	if player:GetAttribute("TrailEquippedThisRound") then
		local re = RS:FindFirstChild("RemoteEvents")
		local notify = re and re:FindFirstChild("NotifyClient")
		if notify then
			notify:FireClient(player, "Locked", "You already equipped a trail this round!", 2, "warning")
		end
		return false
	end
	return true
end

-- ============================================
-- ADMIN HOOKS (used by AdminHandler)
-- ============================================
_G.AllTrailData = {}
for _, t in ipairs(TRAILS) do
	table.insert(_G.AllTrailData, {Id = t.Id, Name = t.Name, Category = t.Category})
end

_G.AdminEquipTrail = function(player, trailId)
	local trail = TRAIL_MAP[trailId]
	if not trail then return false, "Trail '" .. tostring(trailId) .. "' not found" end
	PlayerDataManager.SetEquippedTrail(player, trailId)
	applyFullTrail(player, trail)
	TrailUpdate:FireClient(player, "Equipped", trailId)
	return true
end

_G.AdminUnequipTrail = function(player)
	PlayerDataManager.SetEquippedTrail(player, nil)
	removeFullTrail(player)
	TrailUpdate:FireClient(player, "Unequipped", "")
	return true
end

print("✅ Trail admin hooks registered")
