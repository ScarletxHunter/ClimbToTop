-- ============================================
-- COMMAND BAR SCRIPT: Create CoinsMan spawn points
-- Run in Studio Command Bar (Edit mode)
-- ============================================

local ServerStorage = game:GetService("ServerStorage")

local mapsFolder = ServerStorage:FindFirstChild("Maps")
if not mapsFolder then
	warn("Maps folder not found: ServerStorage/Maps")
	return
end

local POINTS_PER_MAP = 14
local RADIUS = 28
local HEIGHT = 4

local function getStartPosition(mapFolder)
	local props = mapFolder:FindFirstChild("Props")
	if props then
		local start = props:FindFirstChild("Start")
		if start and start:IsA("BasePart") then
			return start.Position
		end
		local anyStart = props:FindFirstChild("StartHere") or props:FindFirstChild("StartHere1")
		if anyStart and anyStart:IsA("BasePart") then
			return anyStart.Position
		end
	end
	local rootStart = mapFolder:FindFirstChild("Start")
	if rootStart and rootStart:IsA("BasePart") then
		return rootStart.Position
	end
	return Vector3.new(0, 10, 0)
end

for _, mapFolder in ipairs(mapsFolder:GetChildren()) do
	if not mapFolder:IsA("Folder") then continue end

	local props = mapFolder:FindFirstChild("Props")
	if not props then
		props = Instance.new("Folder")
		props.Name = "Props"
		props.Parent = mapFolder
	end

	local coinsMan = props:FindFirstChild("CoinsMan")
	if not coinsMan then
		coinsMan = Instance.new("Folder")
		coinsMan.Name = "CoinsMan"
		coinsMan.Parent = props
	end
	if coinsMan:GetAttribute("CooldownSeconds") == nil then
		coinsMan:SetAttribute("CooldownSeconds", 15)
	end
	if coinsMan:GetAttribute("SpawnInterval") == nil then
		coinsMan:SetAttribute("SpawnInterval", 1)
	end
	if coinsMan:GetAttribute("MaxActiveCoins") == nil then
		coinsMan:SetAttribute("MaxActiveCoins", 8)
	end
	if coinsMan:GetAttribute("CoinValue") == nil then
		coinsMan:SetAttribute("CoinValue", 5)
	end

	local center = getStartPosition(mapFolder)
	-- If points already exist, keep them. Only create missing points.
	local existing = 0
	for _, child in ipairs(coinsMan:GetChildren()) do
		if child:IsA("BasePart") then existing += 1 end
	end
	if existing == 0 then
		for i = 1, POINTS_PER_MAP do
			local angle = (math.pi * 2) * ((i - 1) / POINTS_PER_MAP)
			local point = Instance.new("Part")
			point.Name = "CoinPoint" .. i
			point.Anchored = true
			point.CanCollide = false
			point.Transparency = 0.35
			point.Material = Enum.Material.Neon
			point.Color = Color3.fromRGB(255, 220, 40)
			point.Shape = Enum.PartType.Ball
			point.Size = Vector3.new(1.4, 1.4, 1.4)

			local offset = Vector3.new(math.cos(angle) * RADIUS, HEIGHT + math.random(-2, 3), math.sin(angle) * RADIUS)
			point.Position = center + offset
			point.Parent = coinsMan
		end
	else
		print("Keeping existing points for", mapFolder.Name, "-", existing, "point(s)")
	end

	local template = props:FindFirstChild("CoinTemplate")
	if not template then
		template = Instance.new("Part")
		template.Name = "CoinTemplate"
		template.Shape = Enum.PartType.Cylinder
		template.Size = Vector3.new(0.35, 1.5, 1.5)
		template.Material = Enum.Material.Neon
		template.Color = Color3.fromRGB(255, 220, 40)
		template.Anchored = true
		template.CanCollide = false
		template.CanTouch = true
		template.CanQuery = false
		template.CFrame = CFrame.new(center + Vector3.new(0, HEIGHT + 4, 0)) * CFrame.Angles(0, 0, math.rad(90))
		template.Parent = props
		print("Created placeholder CoinTemplate in", mapFolder.Name, "(replace with your 3D model)")
	end

	print("CoinsMan ready for", mapFolder.Name)
end

print("Done. Move CoinPoint parts where you want, and replace Props/CoinTemplate with your own model.")

