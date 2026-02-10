-- ============================================
-- MAP LOADER
-- Place in: ServerScriptService/MapLoader (ModuleScript)
-- ============================================

local MapLoader = {}

local ServerStorage = game:GetService("ServerStorage")
local workspace = game:GetService("Workspace")

local currentMap = nil

-- ============================================
-- LOAD MAP
-- ============================================

function MapLoader.LoadMap(mapName)
	print("??? Loading map:", mapName)

	-- Unload current map first
	MapLoader.UnloadMap()

	-- Find map in ServerStorage
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("? Maps folder not found in ServerStorage!")
		return nil
	end

	local mapTemplate = mapsFolder:FindFirstChild(mapName)
	if not mapTemplate then
		warn("? Map not found:", mapName)
		return nil
	end

	-- Clone map to workspace
	local map = mapTemplate:Clone()
	map.Name = "CurrentMap"
	map.Parent = workspace

	currentMap = map

	print("? Loaded map:", mapName)
	return map
end

-- ============================================
-- UNLOAD MAP
-- ============================================

function MapLoader.UnloadMap()
	if currentMap then
		print("??? Unloading current map...")
		currentMap:Destroy()
		currentMap = nil
	end

	-- Also clean up any leftover maps
	local oldMap = workspace:FindFirstChild("CurrentMap")
	if oldMap then
		oldMap:Destroy()
	end
end

-- ============================================
-- GET CURRENT MAP
-- ============================================

function MapLoader.GetCurrentMap()
	return currentMap
end

print("? MapLoader module loaded")

return MapLoader