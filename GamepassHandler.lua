-- ============================================
-- GAMEPASS HANDLER - VIP, Admin, Coin Multiplier, Extra Speed, Double XP
-- ============================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chat = game:GetService("Chat")
local gameValues = ReplicatedStorage:FindFirstChild("GameValues")
local gameState = gameValues and gameValues:FindFirstChild("GameState")

-- ============================================
-- ?? GAMEPASS IDS - SET YOUR IDS HERE
-- ============================================
local GAMEPASSES = {
	VIP = {
		Id = 0,  -- SET YOUR GAMEPASS ID
		Name = "VIP",
		Description = "2x Coins, VIP Chat Tag, VIP Trail Access",
		CoinMultiplier = 2.0,
		ChatTag = "[VIP] ",
		ChatColor = Color3.fromRGB(255, 215, 0),
	},
	Admin = {
		Id = 0,  -- SET YOUR GAMEPASS ID
		Name = "Admin",
		Description = "Admin commands, special effects, 3x Coins",
		CoinMultiplier = 3.0,
		ChatTag = "[ADMIN] ",
		ChatColor = Color3.fromRGB(255, 50, 50),
	},
	CoinBoost = {
		Id = 0,  -- SET YOUR GAMEPASS ID
		Name = "Coin Boost",
		Description = "Permanently earn 1.5x coins every round",
		CoinMultiplier = 1.5,
		ChatTag = "",
		ChatColor = Color3.fromRGB(255, 255, 255),
	},
	SpeedBoost = {
		Id = 0,  -- SET YOUR GAMEPASS ID
		Name = "Speed Boost",
		Description = "+10% permanent speed boost",
		SpeedMultiplier = 0.10,
		ChatTag = "",
		ChatColor = Color3.fromRGB(255, 255, 255),
	},
	DoubleXP = {
		Id = 0,  -- SET YOUR GAMEPASS ID
		Name = "Double XP",
		Description = "Earn double XP from all activities",
		XPMultiplier = 2.0,
		ChatTag = "",
		ChatColor = Color3.fromRGB(255, 255, 255),
	},
}

local playerGamepasses = {} -- { userId = { VIP = true, Admin = false, ... } }

-- ============================================
-- CHECK OWNERSHIP
-- ============================================

local function checkGamepasses(player)
	playerGamepasses[player.UserId] = {}

	for key, gp in pairs(GAMEPASSES) do
		if gp.Id > 0 then
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.Id)
			end)
			playerGamepasses[player.UserId][key] = (success and owns) or false
		else
			playerGamepasses[player.UserId][key] = false
		end
	end

	print("?? Gamepasses for", player.Name .. ":", playerGamepasses[player.UserId])
end

local function hasGamepass(player, gamepassKey)
	if not playerGamepasses[player.UserId] then return false end
	return playerGamepasses[player.UserId][gamepassKey] == true
end

-- ============================================
-- COIN MULTIPLIER
-- ============================================

_G.GetCoinMultiplier = function(player)
	local multiplier = 1.0

	if hasGamepass(player, "Admin") then
		multiplier = math.max(multiplier, GAMEPASSES.Admin.CoinMultiplier)
	elseif hasGamepass(player, "VIP") then
		multiplier = math.max(multiplier, GAMEPASSES.VIP.CoinMultiplier)
	elseif hasGamepass(player, "CoinBoost") then
		multiplier = math.max(multiplier, GAMEPASSES.CoinBoost.CoinMultiplier)
	end

	return multiplier
end

-- ============================================
-- SPEED BOOST
-- ============================================

local function applySpeedBoost(player)
	if not hasGamepass(player, "SpeedBoost") then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local currentSpeed = humanoid.WalkSpeed
	local boost = GAMEPASSES.SpeedBoost.SpeedMultiplier or 0.10
	humanoid.WalkSpeed = currentSpeed * (1 + boost)
	print("? Speed boost applied to", player.Name, "?", humanoid.WalkSpeed)
end

-- ============================================
-- VIP CHAT TAG
-- ============================================

local function applyChatTag(player)
	-- Apply via legacy chat system if available
	local tag = ""
	local tagColor = Color3.fromRGB(255, 255, 255)

	if hasGamepass(player, "Admin") then
		tag = GAMEPASSES.Admin.ChatTag
		tagColor = GAMEPASSES.Admin.ChatColor
	elseif hasGamepass(player, "VIP") then
		tag = GAMEPASSES.VIP.ChatTag
		tagColor = GAMEPASSES.VIP.ChatColor
	end

	if tag ~= "" then
		-- For TextChatService (modern chat)
		local textChatService = game:GetService("TextChatService")
		local chatConnection
		chatConnection = textChatService.OnIncomingMessage:Connect(function(message)
			-- This is handled client-side, so we fire an event
		end)

		-- Store tag info for client to read
		player:SetAttribute("ChatTag", tag)
		player:SetAttribute("ChatTagColorR", math.floor(tagColor.R * 255))
		player:SetAttribute("ChatTagColorG", math.floor(tagColor.G * 255))
		player:SetAttribute("ChatTagColorB", math.floor(tagColor.B * 255))
	end
end

-- ============================================
-- ADMIN COMMANDS
-- ============================================

local ADMIN_COMMANDS = {
	["/speed"] = function(player, args)
		if not hasGamepass(player, "Admin") then return end
		local speed = tonumber(args[1]) or 16
		speed = math.clamp(speed, 1, 100)
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = speed
			print("?? Admin", player.Name, "set speed to", speed)
		end
	end,
	["/jump"] = function(player, args)
		if not hasGamepass(player, "Admin") then return end
		local power = tonumber(args[1]) or 50
		power = math.clamp(power, 1, 200)
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.JumpPower = power
			print("?? Admin", player.Name, "set jump to", power)
		end
	end,
	["/sparkle"] = function(player, args)
		if not hasGamepass(player, "Admin") then return end
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local sparkle = Instance.new("Sparkles")
			sparkle.Name = "AdminSparkle"
			sparkle.Parent = player.Character.HumanoidRootPart
			task.delay(10, function()
				if sparkle and sparkle.Parent then sparkle:Destroy() end
			end)
		end
	end,
	["/resetspeed"] = function(player, args)
		if not hasGamepass(player, "Admin") then return end
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = 16
		end
	end,
}

-- Admin command remote
local AdminCommandEvent = Instance.new("RemoteEvent")
AdminCommandEvent.Name = "AdminCommand"
AdminCommandEvent.Parent = ReplicatedStorage

AdminCommandEvent.OnServerEvent:Connect(function(player, command)
	if not hasGamepass(player, "Admin") then return end

	local parts = string.split(command, " ")
	local cmd = parts[1]:lower()
	local args = {}
	for i = 2, #parts do
		table.insert(args, parts[i])
	end

	if ADMIN_COMMANDS[cmd] then
		ADMIN_COMMANDS[cmd](player, args)
	end
end)

-- ============================================
-- REMOTE FOR CLIENTS TO CHECK GAMEPASSES
-- ============================================

local GetGamepassInfo = Instance.new("RemoteFunction")
GetGamepassInfo.Name = "GetGamepassInfo"
GetGamepassInfo.Parent = ReplicatedStorage

GetGamepassInfo.OnServerInvoke = function(player)
	local result = {}
	for key, gp in pairs(GAMEPASSES) do
		result[key] = {
			Id = gp.Id,
			Name = gp.Name,
			Description = gp.Description,
			Owned = hasGamepass(player, key),
		}
	end
	return result
end

-- Check if player has a specific gamepass (for other scripts)
_G.HasGamepass = function(player, gamepassKey)
	return hasGamepass(player, gamepassKey)
end

-- ============================================
-- INITIALIZATION
-- ============================================

Players.PlayerAdded:Connect(function(player)
	checkGamepasses(player)
	applyChatTag(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		applySpeedBoost(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerGamepasses[player.UserId] = nil
end)

-- Handle mid-game purchases
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if not wasPurchased then return end

	-- Refresh all gamepasses for this player
	checkGamepasses(player)
	applyChatTag(player)
	applySpeedBoost(player)

	-- INSTANT REWARD: Knockback Tool
	if gamepassId == 1708531013 then
		local toolFolder = game:GetService("ServerStorage"):FindFirstChild("GamepassTools")
		if toolFolder then
			local kbTool = toolFolder:FindFirstChild("KnockbackTool")
			if kbTool then
				local bp = player:FindFirstChild("Backpack")
				if bp and not bp:FindFirstChild("KnockbackTool") then
					kbTool:Clone().Parent = bp
				end
			end
		end
		print("?? Gave KnockbackTool to", player.Name, "instantly!")
	end

	-- INSTANT REWARD: VIP effects
	if gamepassId == 1709154874 then
		task.spawn(function()
			task.wait(0.5)
			if player.Character then
				-- Rainbow name will be applied by applyRainbowName if it exists
				pcall(function() applyRainbowName(player) end)
			end
		end)
		print("?? Applied VIP effects for", player.Name, "instantly!")
	end

	-- INSTANT REWARD: Athlete speed boost (already handled by applySpeedBoost above)
	-- gamepassId 1707648990

	-- INSTANT REWARD: HeadStart
	-- gamepassId 1711495326 (effect applies next round automatically)

	-- INSTANT REWARD: TrailMaster
	if gamepassId == 1711477336 then
		print("? TrailMaster unlocked for", player.Name, "instantly!")
	end

	-- INSTANT REWARD: StarterPack
	if gamepassId == 1708836892 then
		print("?? StarterPack activated for", player.Name, "instantly!")
	end

	-- INSTANT REWARD: KnockbackResist
	if gamepassId == 1710491715 then
		print("?? KnockbackResist activated for", player.Name, "instantly!")
	end

	print("??", player.Name, "purchased gamepass:", gamepassId)
end)

print("? Gamepass Handler initialized")
-- KNOCKBACK TOOL GAMEPASS (1708531013)
local function giveKnockbackTool(player)
	local toolFolder = game:GetService("ServerStorage"):FindFirstChild("GamepassTools")
	if not toolFolder then return end
	local kbTool = toolFolder:FindFirstChild("KnockbackTool")
	if not kbTool then return end
	local bp = player:FindFirstChild("Backpack")
	if bp and not bp:FindFirstChild("KnockbackTool") then
		kbTool:Clone().Parent = bp
	end
end

local function removeKnockbackTool(player)
	local bp = player:FindFirstChild("Backpack")
	if bp then
		local tool = bp:FindFirstChild("KnockbackTool")
		if tool then tool:Destroy() end
	end
	if player.Character then
		local equipped = player.Character:FindFirstChild("KnockbackTool")
		if equipped then equipped:Destroy() end
	end
end

local function applyKnockbackToolState(player)
	local owns = false
	pcall(function() owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1708531013) end)
	if not owns then
		removeKnockbackTool(player)
		return
	end
	if gameState and gameState.Value ~= "Playing" then
		removeKnockbackTool(player)
		return
	end
	giveKnockbackTool(player)
end

local MPS = game:GetService("MarketplaceService")
game:GetService("Players").PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.delay(1, function()
			applyKnockbackToolState(player)
		end)
	end)
end)

-- Give to existing players
for _, p in pairs(game:GetService("Players"):GetPlayers()) do
	task.spawn(function()
		local owns = false
		pcall(function() owns = MPS:UserOwnsGamePassAsync(p.UserId, 1708531013) end)
		if owns then
			p.CharacterAdded:Connect(function()
				task.delay(1, function() applyKnockbackToolState(p) end)
			end)
			if p.Character then applyKnockbackToolState(p) end
		end
	end)
end
if gameState then
	gameState.Changed:Connect(function()
		for _, p in pairs(Players:GetPlayers()) do
			applyKnockbackToolState(p)
		end
	end)
end
print("Knockback tool gamepass active (ID: 1708531013)")

-- VIP RAINBOW NAME
local RunService = game:GetService("RunService")
local function applyRainbowName(player)
	if not hasGamepass(player, "VIP") then return end
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	
	-- Remove old
	local old = head:FindFirstChild("RainbowBillboard")
	if old then old:Destroy() end
	
	local bb = Instance.new("BillboardGui")
	bb.Name = "RainbowBillboard"
	bb.Size = UDim2.new(0, 200, 0, 50)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = false
	bb.Parent = head
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Parent = bb
	
	-- Hide default name
	local hum = char:FindFirstChild("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	
	-- Rainbow cycle
	task.spawn(function()
		local hue = 0
		while nameLabel and nameLabel.Parent and char and char.Parent do
			hue = (hue + 0.01) % 1
			nameLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
			task.wait(0.03)
		end
	end)
	
	-- VIP sparkle
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and not hrp:FindFirstChild("VIPSparkle") then
		local sp = Instance.new("Sparkles")
		sp.Name = "VIPSparkle"
		sp.SparkleColor = Color3.fromRGB(255, 215, 0)
		sp.Parent = hrp
	end
	
	print("VIP Rainbow name + sparkle applied to", player.Name)
end

-- Apply on character spawn
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(1.5)
		applyRainbowName(p)
	end)
end)
for _, p in pairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function()
		task.wait(1.5)
		applyRainbowName(p)
	end)
	if p.Character then task.spawn(function() task.wait(1) applyRainbowName(p) end) end
end
