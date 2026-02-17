-- ============================================
-- MAP LOADER - Loads and unloads maps
-- ============================================

local ServerStorage = game:GetService("ServerStorage")
local workspaceService = game:GetService("Workspace")

local MapLoader = {}

local mapContainer = workspaceService:WaitForChild("MapContainer")

function MapLoader.UnloadMap()
	print("??? Unloading current map...")
	mapContainer:ClearAllChildren()
	
	-- Also clean up any parts placed in Workspace root
	for _, name in ipairs({"Start", "End", "Spawners", "PropStop", "CoinsMan", "CoinTemplate"}) do
		local existing = workspaceService:FindFirstChild(name)
		if existing and not existing:IsA("Camera") and not existing:IsA("Terrain") then
			existing:Destroy()
		end
	end
	-- Clean up StartHere parts
	for i = 1, 10 do
		local sh = workspaceService:FindFirstChild("StartHere" .. i)
		if sh then sh:Destroy() end
	end
	local sh = workspaceService:FindFirstChild("StartHere")
	if sh then sh:Destroy() end
end

function MapLoader.LoadMap(mapName)
	print("??? Loading map:", mapName)
	MapLoader.UnloadMap()

	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("? Maps folder not found in ServerStorage!")
		return false
	end

	local mapFolder = mapsFolder:FindFirstChild(mapName)
	if not mapFolder then
		warn("? Map not found:", mapName)
		return false
	end

	local propsFolder = mapFolder:FindFirstChild("Props")
	if propsFolder then
		for _, prop in pairs(propsFolder:GetChildren()) do
			local clone = prop:Clone()
			
			-- Special parts go to Workspace root so GameManager can find them
			if clone.Name == "Start" or clone.Name == "End" or clone.Name == "PropStop" then
				clone.Parent = workspaceService
				print("  ?? " .. clone.Name .. " ? Workspace root")
			elseif clone.Name:match("^StartHere%d*$") then
				clone.Parent = workspaceService
				print("  ?? " .. clone.Name .. " ? Workspace root")
			elseif clone.Name == "Spawners" then
				clone.Parent = workspaceService
				print("  ?? Spawners folder ? Workspace root (" .. #clone:GetChildren() .. " spawners)")
			elseif clone.Name == "CoinsMan" then
				clone.Parent = workspaceService
				print("  ?? CoinsMan folder ? Workspace root (" .. #clone:GetChildren() .. " points)")
			elseif clone.Name == "CoinTemplate" then
				clone.Parent = workspaceService
				print("  ?? CoinTemplate ? Workspace root")
			else
				clone.Parent = mapContainer
			end
		end
		print("? Loaded props for", mapName)
	end

	local function cloneNamedFromDescendants(root, wantedName)
		for _, d in ipairs(root:GetDescendants()) do
			if d.Name == wantedName then
				local clone = d:Clone()
				clone.Name = wantedName
				clone.Parent = workspaceService
				print("  ?? " .. wantedName .. " ? Workspace root (from descendants)")
				return true
			end
		end
		return false
	end

	-- Also check for Start/End directly in map folder (not in Props)
	for _, name in ipairs({"Start", "End"}) do
		local part = mapFolder:FindFirstChild(name)
		if part and not workspaceService:FindFirstChild(name) then
			local clone = part:Clone()
			clone.Parent = workspaceService
			print("  ?? " .. name .. " ? Workspace root (from map root)")
		end
	end

	-- Compatibility: allow CoinsMan / CoinTemplate directly in map root too
	for _, name in ipairs({"CoinsMan", "CoinTemplate"}) do
		local obj = mapFolder:FindFirstChild(name)
		if obj and not workspaceService:FindFirstChild(name) then
			local clone = obj:Clone()
			clone.Parent = workspaceService
			print("  ?? " .. name .. " ? Workspace root (from map root)")
		end
	end

	-- Fallback: if still missing, find by name anywhere in map descendants
	if not workspaceService:FindFirstChild("CoinsMan") then
		cloneNamedFromDescendants(mapFolder, "CoinsMan")
	end
	if not workspaceService:FindFirstChild("CoinTemplate", true) then
		cloneNamedFromDescendants(mapFolder, "CoinTemplate")
	end

	local loadedCoinsMan = workspaceService:FindFirstChild("CoinsMan")
	local loadedCoinTemplate = workspaceService:FindFirstChild("CoinTemplate", true)
	print("  ?? Coin assets loaded? CoinsMan=", loadedCoinsMan ~= nil, "CoinTemplate=", loadedCoinTemplate ~= nil)

	return true
end

return MapLoader
