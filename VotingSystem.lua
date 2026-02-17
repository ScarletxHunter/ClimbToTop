-- ============================================
-- VOTING SYSTEM - Auto map preview images on pedestals
-- FIXED: Only shows as many pedestals as unique maps
-- NEW: SurfaceGui with map image + name auto-created
-- ============================================

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local workspaceService = game:GetService("Workspace")

local VotingSystem = {}

local votes = {}
local voteCounts = {}
local voteConnections = {}
local assignedMaps = {}
local playerVoteDebounce = {}

local function getAvailableMaps()
	local maps = {}
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if mapsFolder then
		for _, mapFolder in pairs(mapsFolder:GetChildren()) do
			if mapFolder:IsA("Folder") then
				table.insert(maps, mapFolder.Name)
			end
		end
	end
	return maps
end

local function shuffle(tbl)
	local n = #tbl
	for i = n, 2, -1 do
		local j = math.random(1, i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

local function cleanupVoteConnections()
	for _, conn in ipairs(voteConnections) do
		conn:Disconnect()
	end
	voteConnections = {}
	playerVoteDebounce = {}
end

-- ============================================
-- MAP PREVIEW IMAGE SYSTEM
-- Reads "MapImage" StringValue from each map folder
-- Auto-creates SurfaceGui on vote pedestals
-- ============================================

local function getMapImageId(mapName)
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then return "" end

	local mapFolder = mapsFolder:FindFirstChild(mapName)
	if not mapFolder then return "" end

	-- Look for StringValue named "MapImage"
	local mapImage = mapFolder:FindFirstChild("MapImage")
	if mapImage and mapImage:IsA("StringValue") and mapImage.Value ~= "" then
		return mapImage.Value
	end

	-- Also check for Decal named "MapImage" (alternative setup)
	local mapDecal = mapFolder:FindFirstChild("MapImage")
	if mapDecal and mapDecal:IsA("Decal") and mapDecal.Texture ~= "" then
		return mapDecal.Texture
	end

	return ""
end

-- Find the best face to put the image on (the face players see)
local function getBestFace(part)
	-- Default to Front, but check for existing SurfaceGui to match
	local existing = part:FindFirstChildWhichIsA("SurfaceGui")
	if existing then
		return existing.Face
	end
	return Enum.NormalId.Front
end

local function updatePedestalImage(voteObj, mapName)
	if not voteObj then return end

	-- Find the main visible part of the pedestal
	-- Try VotePart first, then the model's PrimaryPart, then any large part
	local targetPart = nil

	-- Check for a dedicated "ImagePart" or "DisplayPart"
	local imagePart = voteObj:FindFirstChild("ImagePart") or voteObj:FindFirstChild("DisplayPart")
	if imagePart and imagePart:IsA("BasePart") then
		targetPart = imagePart
	end

	-- Fall back to VotePart
	if not targetPart then
		local votePart = voteObj:FindFirstChild("VotePart")
		if votePart and votePart:IsA("BasePart") then
			targetPart = votePart
		end
	end

	-- Fall back to PrimaryPart
	if not targetPart and voteObj:IsA("Model") and voteObj.PrimaryPart then
		targetPart = voteObj.PrimaryPart
	end

	-- Fall back to first BasePart
	if not targetPart then
		targetPart = voteObj:FindFirstChildWhichIsA("BasePart")
	end

	if not targetPart then
		warn("?? No part found for map preview on", voteObj.Name)
		return
	end

	-- Find or create SurfaceGui
	local surfaceGui = targetPart:FindFirstChild("MapPreviewGui")
	if not surfaceGui then
		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "MapPreviewGui"
		surfaceGui.Face = getBestFace(targetPart)
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surfaceGui.PixelsPerStud = 50
		surfaceGui.AlwaysOnTop = false
		surfaceGui.ResetOnSpawn = false
		surfaceGui.Parent = targetPart
	end

	-- Find or create ImageLabel
	local imageLabel = surfaceGui:FindFirstChild("MapImage")
	if not imageLabel then
		imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = "MapImage"
		imageLabel.Size = UDim2.new(1, 0, 1, 0)
		imageLabel.Position = UDim2.new(0, 0, 0, 0)
		imageLabel.BackgroundTransparency = 1
		imageLabel.ScaleType = Enum.ScaleType.Crop
		imageLabel.ZIndex = 1
		imageLabel.Parent = surfaceGui

		-- Rounded corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = imageLabel
	end

	-- Find or create map name label (bottom overlay)
	local nameLabel = surfaceGui:FindFirstChild("MapNameOverlay")
	if not nameLabel then
		nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "MapNameOverlay"
		nameLabel.Size = UDim2.new(1, 0, 0.22, 0)
		nameLabel.Position = UDim2.new(0, 0, 0.78, 0)
		nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		nameLabel.BackgroundTransparency = 0.35
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.ZIndex = 2
		nameLabel.Parent = surfaceGui

		local nameCorner = Instance.new("UICorner")
		nameCorner.CornerRadius = UDim.new(0, 6)
		nameCorner.Parent = nameLabel

		-- Text padding
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 6)
		padding.PaddingRight = UDim.new(0, 6)
		padding.Parent = nameLabel
	end

	-- Set content
	if mapName and mapName ~= "" then
		local imageId = getMapImageId(mapName)

		if imageId ~= "" then
			imageLabel.Image = imageId
			imageLabel.ImageTransparency = 0
			imageLabel.Visible = true
			print("??? Map preview:", mapName, "?", voteObj.Name)
		else
			-- No image — show a colored placeholder
			imageLabel.Image = ""
			imageLabel.ImageTransparency = 1
			imageLabel.BackgroundTransparency = 0.3
			imageLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
			imageLabel.Visible = true
			print("?? No preview image for", mapName, "(add MapImage StringValue to map folder)")
		end

		nameLabel.Text = mapName
		nameLabel.Visible = true
		surfaceGui.Enabled = true
	else
		-- No map assigned — hide everything
		imageLabel.Image = ""
		imageLabel.Visible = false
		nameLabel.Text = ""
		nameLabel.Visible = false
		surfaceGui.Enabled = false
	end
end

local function clearAllPedestalImages()
	local votingFolder = workspaceService:FindFirstChild("Voting")
	if not votingFolder then return end

	for i = 1, 5 do
		local voteObj = votingFolder:FindFirstChild("VoteObject" .. i)
		if voteObj then
			updatePedestalImage(voteObj, nil)
		end
	end
end

-- ============================================
-- UPDATE BILLBOARD + HUD DISPLAYS
-- ============================================

local function updateWorldDisplays()
	local votingFolder = workspaceService:FindFirstChild("Voting")
	if not votingFolder then return end

	for i = 1, 3 do
		local voteObj = votingFolder:FindFirstChild("VoteObject" .. i)
		if not voteObj then continue end

		local mapName = assignedMaps["VoteObject" .. i]

		if not mapName then
			local highlight = voteObj:FindFirstChild("Highlight")
			if highlight then highlight.Enabled = false end

			local votePart = voteObj:FindFirstChild("VotePart")
			if votePart then
				local billboard = votePart:FindFirstChild("VoteDisplay")
				if billboard then
					local mapLabel = billboard:FindFirstChild("MapNameLabel")
					local countLabel = billboard:FindFirstChild("VoteCountLabel")
					if mapLabel then mapLabel.Text = "" end
					if countLabel then countLabel.Text = "" end
				end
			end
			continue
		end

		local votePart = voteObj:FindFirstChild("VotePart")
		if not votePart then continue end

		local billboard = votePart:FindFirstChild("VoteDisplay")
		if not billboard then continue end

		local mapLabel = billboard:FindFirstChild("MapNameLabel")
		local countLabel = billboard:FindFirstChild("VoteCountLabel")

		if mapLabel then
			mapLabel.Text = mapName
		end
		if countLabel then
			local count = voteCounts[mapName] or 0
			countLabel.Text = tostring(count) .. " Vote" .. (count == 1 and "" or "s")
		end
	end
end

local function updateClientHud()
	local UpdateVoteHud = ReplicatedStorage:FindFirstChild("UpdateVoteHud")
	if UpdateVoteHud then
		UpdateVoteHud:FireAllClients(voteCounts, assignedMaps)
	end
end

local function updateAllDisplays()
	updateWorldDisplays()
	updateClientHud()
end

-- ============================================
-- START VOTING
-- ============================================

function VotingSystem.StartVoting()
	print("??? Starting world-based voting...")
	cleanupVoteConnections()
	votes = {}
	voteCounts = {}
	assignedMaps = {}

	local maps = getAvailableMaps()
	if #maps == 0 then
		warn("? No maps available!")
		return
	end

	shuffle(maps)

	local pedestalCount = math.min(#maps, 3)

	for _, mapName in pairs(maps) do
		voteCounts[mapName] = 0
	end

	local votingFolder = workspaceService:FindFirstChild("Voting")
	if not votingFolder then
		warn("? Workspace > Voting folder not found!")
		return
	end

	local HIGHLIGHT_COLORS = {
		Color3.fromRGB(255, 100, 100),
		Color3.fromRGB(100, 255, 100),
		Color3.fromRGB(100, 150, 255),
	}

	for i = 1, 3 do
		local voteObj = votingFolder:FindFirstChild("VoteObject" .. i)
		if not voteObj then continue end

		if i <= pedestalCount then
			local mapName = maps[i]
			assignedMaps["VoteObject" .. i] = mapName

			-- ? AUTO-UPDATE MAP PREVIEW IMAGE
			updatePedestalImage(voteObj, mapName)

			local highlight = voteObj:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = HIGHLIGHT_COLORS[i] or Color3.fromRGB(255, 255, 255)
				highlight.FillTransparency = 0.5
				highlight.OutlineTransparency = 0
				highlight.Enabled = true
			end

			local votePart = voteObj:FindFirstChild("VotePart")
			if votePart then
				local touchConn = votePart.Touched:Connect(function(hit)
					local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
					if not hitPlayer then return end

					if playerVoteDebounce[hitPlayer.UserId] then return end
					playerVoteDebounce[hitPlayer.UserId] = true
					task.delay(1.5, function()
						playerVoteDebounce[hitPlayer.UserId] = nil
					end)

					if votes[hitPlayer.Name] then
						local oldMap = votes[hitPlayer.Name]
						voteCounts[oldMap] = math.max((voteCounts[oldMap] or 1) - 1, 0)
					end

					votes[hitPlayer.Name] = mapName
					voteCounts[mapName] = (voteCounts[mapName] or 0) + 1

					print("???", hitPlayer.Name, "voted for", mapName)

					local PlaySoundEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
					if PlaySoundEvent then
						PlaySoundEvent:FireClient(hitPlayer, "VoteClick")
					end

					updateAllDisplays()
				end)
				table.insert(voteConnections, touchConn)
			end

			print("?? VoteObject" .. i, "?", mapName)
		else
			-- Hide unused pedestal
			assignedMaps["VoteObject" .. i] = nil

			-- ? CLEAR IMAGE on unused pedestals
			updatePedestalImage(voteObj, nil)

			local highlight = voteObj:FindFirstChild("Highlight")
			if highlight then highlight.Enabled = false end

			local votePart = voteObj:FindFirstChild("VotePart")
			if votePart then
				local billboard = votePart:FindFirstChild("VoteDisplay")
				if billboard then
					local ml = billboard:FindFirstChild("MapNameLabel")
					local cl = billboard:FindFirstChild("VoteCountLabel")
					if ml then ml.Text = "—" end
					if cl then cl.Text = "" end
				end
			end
		end
	end

	task.wait(0.5)
	updateAllDisplays()

	print("? World voting active with", #maps, "map(s),", pedestalCount, "pedestal(s)")
end

-- ============================================
-- STOP VOTING
-- ============================================

function VotingSystem.StopVoting()
	cleanupVoteConnections()

	-- ? CLEAR ALL IMAGES when voting ends
	clearAllPedestalImages()

	local votingFolder = workspaceService:FindFirstChild("Voting")
	if votingFolder then
		for i = 1, 3 do
			local voteObj = votingFolder:FindFirstChild("VoteObject" .. i)
			if voteObj then
				local highlight = voteObj:FindFirstChild("Highlight")
				if highlight then highlight.Enabled = false end
			end
		end
	end
end

-- ============================================
-- GET WINNER
-- ============================================

function VotingSystem.GetWinner()
	local winningMap = nil
	local maxVotes = 0

	for mapName, count in pairs(voteCounts) do
		if count > maxVotes then
			maxVotes = count
			winningMap = mapName
		end
	end

	if not winningMap or maxVotes == 0 then
		local maps = getAvailableMaps()
		if #maps > 0 then
			winningMap = maps[math.random(1, #maps)]
		end
		print("?? Random map selected:", winningMap)
	end

	return winningMap
end

function VotingSystem.GetAssignedMaps()
	return assignedMaps
end

return VotingSystem