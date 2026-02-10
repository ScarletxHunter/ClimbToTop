local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent

print("?? Weapon Indicator loading...")

local container = gui:WaitForChild("Container")
local iconLabel = container:WaitForChild("Icon")
local nameLabel = container:WaitForChild("WeaponName")
local statusLabel = container:WaitForChild("Status")
local uistroke = container:WaitForChild("Stroke")
local updateEvent = gui:WaitForChild("UpdateIndicator")

-- Clean up ANY old RangeIndicators that might still exist
local function cleanupRangeIndicators()
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj.Name == "RangeIndicator" then
			obj:Destroy()
		end
	end
	if player.Character then
		for _, obj in pairs(player.Character:GetDescendants()) do
			if obj.Name == "RangeIndicator" then
				obj:Destroy()
			end
		end
	end
end

cleanupRangeIndicators()

-- Listen for ToolGui updates
updateEvent.Event:Connect(function(weaponName, emoji, status, color)
	nameLabel.Text = weaponName or "Unknown"
	iconLabel.Text = emoji or "??"
	statusLabel.Text = status or "READY"
	statusLabel.TextColor3 = color or Color3.fromRGB(0, 255, 0)

	if status == "READY" then
		uistroke.Color = Color3.fromRGB(0, 255, 0)
		task.delay(0.5, function()
			if uistroke and uistroke.Parent then
				uistroke.Color = Color3.fromRGB(0, 170, 255)
			end
		end)
	elseif status == "COOLDOWN" then
		uistroke.Color = Color3.fromRGB(255, 80, 80)
	end
end)

-- Track tool equip/unequip (GUI only, no range circle)
local WeaponConfigs = nil
pcall(function()
	WeaponConfigs = require(ReplicatedStorage:WaitForChild("WeaponConfigs", 3))
end)

local function onCharacterAdded(character)
	-- Clean any leftover range indicators from old version
	cleanupRangeIndicators()

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			local cfg = WeaponConfigs and WeaponConfigs[child.Name] or {}
			gui.Enabled = true
			nameLabel.Text = cfg.DisplayName or child.Name
			iconLabel.Text = cfg.Emoji or "??"
			statusLabel.Text = "READY"
			statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			local hasTool = false
			for _, c in pairs(character:GetChildren()) do
				if c:IsA("Tool") then hasTool = true break end
			end
			if not hasTool then
				gui.Enabled = false
			end
		end
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

player.CharacterRemoving:Connect(function()
	gui.Enabled = false
end)

print("? Weapon Indicator GUI loaded! (no range circle)")
