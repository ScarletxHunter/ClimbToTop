-- ============================================
-- WINNER PODIUM - With WORKING Dancing + Top 3 Support
-- THIS IS A MODULESCRIPT!
-- Place in: ServerScriptService
-- ============================================

local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

local WinnerPodium = {}

local currentClones = {}
local savedCharacterData = {}

-- Configuration
local PODIUM_CONFIG = {
	DisplayDuration = 60,
}

-- Find podium parts
local function getPodiumParts()
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then
		warn("?? No Lobby folder in Workspace!")
		return nil
	end

	local podium = lobby:FindFirstChild("WinnerPodium")
	if not podium then
		warn("?? No WinnerPodium folder in Lobby!")
		return nil
	end

	return {
		FirstPlace = podium:FindFirstChild("FirstPlace"),
		SecondPlace = podium:FindFirstChild("SecondPlace"),
		ThirdPlace = podium:FindFirstChild("ThirdPlace")
	}
end

-- Safely clone a character
local function safeCloneCharacter(character)
	local originalArchivable = {}
	for _, obj in pairs(character:GetDescendants()) do
		originalArchivable[obj] = obj.Archivable
		obj.Archivable = true
	end
	local charArchivable = character.Archivable
	character.Archivable = true

	local clone = character:Clone()

	character.Archivable = charArchivable
	for obj, val in pairs(originalArchivable) do
		if obj and obj.Parent then
			obj.Archivable = val
		end
	end

	return clone
end

-- Clear existing clones
function WinnerPodium.Clear()
	for _, clone in pairs(currentClones) do
		if clone and clone.Parent then
			pcall(function()
				clone:Destroy()
			end)
		end
	end
	currentClones = {}
	savedCharacterData = {}
	print("?? Cleared podium clones")
end

-- SAVE character data when player finishes
function WinnerPodium.SaveWinnerData(player, rank)
	print("?? Saving character data for", player.Name, "rank", rank)

	if not player.Character then
		warn("   ? No character to save")
		return false
	end

	local success, clone = pcall(function()
		return safeCloneCharacter(player.Character)
	end)

	if not success then
		warn("   ? Clone error:", clone)
		return false
	end

	if not clone then
		warn("   ? Clone returned nil")
		return false
	end

	-- Remove scripts, tools, and other problematic objects
	for _, obj in pairs(clone:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
			obj:Destroy()
		elseif obj:IsA("ForceField") then
			obj:Destroy()
		elseif obj:IsA("Tool") then
			obj:Destroy()
		end
	end

	clone.Name = player.Name .. "_SavedClone_Rank" .. rank
	clone.Parent = game:GetService("ServerStorage")

	savedCharacterData[player.UserId] = {
		Clone = clone,
		PlayerName = player.Name,
		Rank = rank
	}

	print("   ? Saved clone to ServerStorage")
	return true
end

-- Create display from saved data with WORKING DANCING!
local function createPodiumDisplay(userId, pedestalPart, rank)
	local data = savedCharacterData[userId]
	if not data or not data.Clone then
		warn("   ? No saved data for userId:", userId)
		return nil
	end

	print("   ?? Creating display from saved data for", data.PlayerName, "rank", rank)

	local clone = data.Clone:Clone()
	clone.Name = data.PlayerName .. "_PodiumClone"

	-- Configure humanoid
	local humanoid = clone:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Health = humanoid.MaxHealth
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Get HumanoidRootPart
	local hrp = clone:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("      ? Clone has no HumanoidRootPart!")
		clone:Destroy()
		return nil
	end

	-- Position the model on the pedestal
	local yOffset = pedestalPart.Size.Y / 2 + 3
	clone:PivotTo(pedestalPart.CFrame * CFrame.new(0, yOffset, 0))

	-- Parent to workspace FIRST (before anchoring/welding)
	clone.Parent = workspace:FindFirstChild("Lobby") or workspace

	-- Keep character UNANCHORED for animations to work!
	-- Instead, weld the HumanoidRootPart to the pedestal
	hrp.Anchored = false
	hrp.CanCollide = false

	-- Create invisible anchor part welded to pedestal
	local anchorPart = Instance.new("Part")
	anchorPart.Name = "AnchorPart"
	anchorPart.Size = Vector3.new(1, 1, 1)
	anchorPart.Transparency = 1
	anchorPart.CanCollide = false
	anchorPart.Anchored = true
	anchorPart.CFrame = hrp.CFrame
	anchorPart.Parent = clone

	-- Weld HumanoidRootPart to anchor part
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = anchorPart
	weld.Parent = hrp

	-- Make all other parts anchored and non-collidable
	for _, part in pairs(clone:GetDescendants()) do
		if part:IsA("BasePart") and part ~= hrp and part ~= anchorPart then
			part.Anchored = false  -- Keep unanchored for animation
			part.CanCollide = false
		end
	end

	print("      ?? Welded character to pedestal (unanchored for animation)")

	-- ADD DANCING ANIMATION! ??
	if humanoid then
		-- Wait a moment for character to settle
		task.wait(0.1)

		-- Create animator
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		-- Dance animation IDs (Roblox built-in emotes)
		local danceAnimations = {
			"rbxassetid://3333499508",  -- 1st: Penguin
			"rbxassetid://3333136415",  -- 2nd: Salute  
			"rbxassetid://3333432454",  -- 3rd: Stadium
		}

		-- Pick dance based on rank
		local danceId = danceAnimations[rank] or danceAnimations[1]

		-- Load and play animation
		local success, animTrack = pcall(function()
			local anim = Instance.new("Animation")
			anim.AnimationId = danceId
			local track = animator:LoadAnimation(anim)
			return track
		end)

		if success and animTrack then
			animTrack.Looped = true
			animTrack.Priority = Enum.AnimationPriority.Action
			animTrack:Play()
			print("      ?? Playing dance animation for rank", rank, "ID:", danceId)
		else
			warn("      ?? Failed to load dance animation:", animTrack)
		end
	end

	-- Add name label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = hrp

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1

	local medal = rank == 1 and "??" or rank == 2 and "??" or "??"
	nameLabel.Text = medal .. " " .. data.PlayerName

	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Parent = billboard

	print("      ? Successfully created display with dance animation")
	return clone
end

-- Display winners on podium (from saved data)
function WinnerPodium.DisplayWinners(winners)
	print("?? === DISPLAYING WINNERS ON PODIUM ===")
	print("   Winners to display:", #winners)

	for _, clone in pairs(currentClones) do
		if clone and clone.Parent then
			clone:Destroy()
		end
	end
	currentClones = {}

	local podiumParts = getPodiumParts()
	if not podiumParts then
		warn("?? Podium parts not found!")
		return
	end

	for rank, winnerData in ipairs(winners) do
		if rank > 3 then break end

		local player = winnerData.Player
		local pedestalPart

		print("   Processing rank", rank .. ":", player and player.Name or "nil")

		if rank == 1 then
			pedestalPart = podiumParts.FirstPlace
		elseif rank == 2 then
			pedestalPart = podiumParts.SecondPlace
		elseif rank == 3 then
			pedestalPart = podiumParts.ThirdPlace
		end

		if pedestalPart and player then
			local clone = createPodiumDisplay(player.UserId, pedestalPart, rank)
			if clone then
				table.insert(currentClones, clone)
				print("      ? Placed", player.Name)
			end
		end
	end

	print("?? === PODIUM DISPLAY COMPLETE ===")
	print("   Total clones created:", #currentClones)

	task.delay(PODIUM_CONFIG.DisplayDuration, function()
		WinnerPodium.Clear()
	end)
end

return WinnerPodium