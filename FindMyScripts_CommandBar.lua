-- ============================================
-- FIND MY SCRIPTS - Paste in Command Bar
-- Finds where all game scripts actually live
-- ============================================

print("\n=== FINDING ALL SCRIPTS ===\n")

local function searchIn(root, rootName)
	local found = {}
	for _, d in pairs(root:GetDescendants()) do
		if d:IsA("Script") or d:IsA("ModuleScript") or d:IsA("LocalScript") then
			table.insert(found, {Name = d.Name, Class = d.ClassName, Path = d:GetFullName()})
		end
	end
	if #found > 0 then
		print("--- " .. rootName .. " (" .. #found .. " scripts) ---")
		for _, s in ipairs(found) do
			local tag = ""
			if s.Name == "GameManager" or s.Name == "CoinRemotes" or s.Name == "CoinSpawner"
				or s.Name == "PlayerDataManager" or s.Name == "TrailShopHandler" or s.Name == "MapLoader"
				or s.Name == "VotingSystem" or s.Name == "ObjectSpawner" or s.Name == "SoundManager" then
				tag = " <<<< GAME SCRIPT"
			end
			print("  [" .. s.Class .. "] " .. s.Path .. tag)
		end
	end
end

searchIn(game:GetService("ServerScriptService"), "ServerScriptService")
searchIn(game:GetService("ServerStorage"), "ServerStorage")
searchIn(game:GetService("ReplicatedStorage"), "ReplicatedStorage")
searchIn(game:GetService("StarterPlayer"), "StarterPlayer")
searchIn(game:GetService("StarterGui"), "StarterGui")
searchIn(workspace, "Workspace")

print("\n--- CHECKING SPECIFIC LOCATIONS ---")
local SSS = game:GetService("ServerScriptService")

-- Check all direct children of SSS
print("\nServerScriptService direct children:")
for _, c in pairs(SSS:GetChildren()) do
	print("  " .. c.ClassName .. ": " .. c.Name)
end

-- Check if GameManager is a Script (not Module)
for _, d in pairs(SSS:GetDescendants()) do
	if d.Name == "GameManager" then
		print("\n!! GameManager found: " .. d:GetFullName() .. " (" .. d.ClassName .. ")")
		print("   Parent: " .. d.Parent.Name .. " (" .. d.Parent.ClassName .. ")")
		if d.Parent and d.Parent ~= SSS then
			print("   GameManager is inside: " .. d.Parent:GetFullName())
		end
	end
	if d.Name == "CoinRemotes" then
		print("!! CoinRemotes found: " .. d:GetFullName() .. " (" .. d.ClassName .. ")")
		if d:IsA("ModuleScript") then
			warn("   CoinRemotes is a ModuleScript! It should be a Script so it auto-runs!")
		end
	end
end

print("\n=== DONE ===")
