-- ============================================
-- VOTING GUI CLIENT (Template-Based - Respects YOUR layout)
-- Place in: StarterGui/VotingGui/LocalScript
--
-- Clones YOUR CardTemplate exactly as you designed it
-- Does NOT override sizes or positions
-- Lets YOUR UIListLayout handle card positioning
-- Works on mobile + PC
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = script.Parent
local container = gui:WaitForChild("Container")
local mapButtonsFrame = container:WaitForChild("MapButtons")
local scrollFrame = mapButtonsFrame:WaitForChild("ScrollFrame")

-- Add UIPadding to prevent cutoff on left and right sides
local containerPadding = container:FindFirstChildOfClass("UIPadding")
if not containerPadding then
	containerPadding = Instance.new("UIPadding")
	containerPadding.Parent = container
end
-- Always set proper padding values to prevent cutoff
containerPadding.PaddingLeft = UDim.new(0, 20)  -- 20px left padding
containerPadding.PaddingRight = UDim.new(0, 20)  -- 20px right padding
containerPadding.PaddingTop = UDim.new(0, 15)   -- 15px top padding
containerPadding.PaddingBottom = UDim.new(0, 15) -- 15px bottom padding

-- Get the template you built in Studio
local cardTemplate = scrollFrame:WaitForChild("CardTemplate")
cardTemplate.Visible = false -- Keep template hidden, we clone it

local votedMap = nil
local voteUpdateEvent = nil
local castVoteEvent = nil
local autoCloseThread = nil
local originalContainerPosition = container.Position

print("??? Voting GUI loading...")

-- ============================================
-- ACCENT COLORS (one per card)
-- ============================================

local CARD_ACCENTS = {
	Color3.fromRGB(0, 180, 255),
	Color3.fromRGB(140, 90, 255),
	Color3.fromRGB(255, 150, 50),
	Color3.fromRGB(0, 220, 130),
	Color3.fromRGB(255, 80, 120),
}

local MAP_ICONS = { "???", "??", "???", "??", "???", "??" }

-- ============================================
-- SHOW / HIDE
-- ============================================

local function showVotingGui()
	container.Position = originalContainerPosition
	gui.Enabled = true
end

local function hideVotingGui()
	if autoCloseThread then
		task.cancel(autoCloseThread)
		autoCloseThread = nil
	end
	gui.Enabled = false
	container.Position = originalContainerPosition
end

-- ============================================
-- CLEAR CLONED CARDS (keeps template + layouts)
-- ============================================

local function clearMapCards()
	for _, child in pairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "CardTemplate" then
			child:Destroy()
		end
	end
end

-- ============================================
-- WAIT FOR REMOTE EVENTS
-- ============================================

local function waitForVotingEvents()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then
		warn("? RemoteEvents folder not found!")
		return false
	end

	voteUpdateEvent = remoteEvents:WaitForChild("VoteUpdate", 60)
	if not voteUpdateEvent then
		warn("? VoteUpdate event not found after 60s")
		return false
	end

	castVoteEvent = remoteEvents:WaitForChild("CastVote", 5)
	if not castVoteEvent then
		warn("? CastVote event not found")
		return false
	end

	print("? Found voting RemoteEvents")
	return true
end

-- ============================================
-- CREATE MAP CARDS (clones your template, NO size overrides)
-- ============================================

local function createMapButtons(maps)
	clearMapCards()

	print("?? Creating cards for", #maps, "maps")

	for i, mapName in ipairs(maps) do
		local accent = CARD_ACCENTS[((i - 1) % #CARD_ACCENTS) + 1]
		local icon = MAP_ICONS[((i - 1) % #MAP_ICONS) + 1]

		-- Clone YOUR template exactly as you designed it
		-- NO size or position changes � your UIListLayout handles that
		local card = cardTemplate:Clone()
		card.Name = mapName
		card.Visible = true
		card.LayoutOrder = i
		card.Parent = scrollFrame

		-- ============================================
		-- FILL IN DATA (only changes text/colors, not sizes)
		-- ============================================

		-- Map Icon
		local mapIcon = card:FindFirstChild("MapIcon")
		if mapIcon then
			if mapIcon:IsA("TextLabel") then
				mapIcon.Text = icon
			end
		end

		-- Map Name
		local mapNameLabel = card:FindFirstChild("MapName")
		if mapNameLabel then
			mapNameLabel.Text = mapName
		end

		-- Vote Count
		local voteFrame = card:FindFirstChild("VoteFrame")
		local voteCount = nil
		local voteFill = nil
		if voteFrame then
			voteCount = voteFrame:FindFirstChild("VoteCount")
			voteFill = voteFrame:FindFirstChild("VoteFill")
			if voteCount then
				voteCount.Text = "0 votes"
			end
			if voteFill then
				voteFill.Size = UDim2.new(0, 0, 1, 0)
			end
		end

		-- Checkmark (hidden until voted)
		local checkmark = card:FindFirstChild("Checkmark")
		if checkmark then
			checkmark.Visible = false
		end

		-- ============================================
		-- APPLY ACCENT COLOR (optional � remove if you set colors in template)
		-- ============================================

		local cardStroke = card:FindFirstChildWhichIsA("UIStroke")
		if cardStroke then
			cardStroke.Color = accent
		end

		if voteCount then
			voteCount.TextColor3 = accent
		end

		if voteFill then
			voteFill.BackgroundColor3 = accent
		end

		if mapNameLabel then
			mapNameLabel.TextStrokeColor3 = accent
		end

		-- ============================================
		-- VOTE BUTTON
		-- ============================================

		local voteBtn = card:FindFirstChild("VoteButton")
		if voteBtn then
			-- Hover effects (PC only)
			voteBtn.MouseEnter:Connect(function()
				if votedMap ~= mapName then
					TweenService:Create(voteBtn, TweenInfo.new(0.15),
						{BackgroundColor3 = Color3.fromRGB(0, 160, 255)}):Play()
					if cardStroke then
						TweenService:Create(cardStroke, TweenInfo.new(0.15),
							{Transparency = 0}):Play()
					end
				end
			end)

			voteBtn.MouseLeave:Connect(function()
				if votedMap ~= mapName then
					TweenService:Create(voteBtn, TweenInfo.new(0.15),
						{BackgroundColor3 = Color3.fromRGB(0, 130, 255)}):Play()
					if cardStroke then
						TweenService:Create(cardStroke, TweenInfo.new(0.15),
							{Transparency = 0.35}):Play()
					end
				end
			end)

			-- CLICK TO VOTE
			voteBtn.MouseButton1Click:Connect(function()
				if not castVoteEvent then
					warn("?? Cannot vote - castVoteEvent not ready")
					return
				end

				if votedMap == mapName then return end

				print("??? Voting for", mapName)
				votedMap = mapName
				castVoteEvent:FireServer(mapName)

				-- Update ALL card visuals
				for _, child in pairs(scrollFrame:GetChildren()) do
					if child:IsA("Frame") and child.Name ~= "CardTemplate" then
						local btn = child:FindFirstChild("VoteButton")
						local stroke = child:FindFirstChildWhichIsA("UIStroke")
						local check = child:FindFirstChild("Checkmark")
						if not btn then continue end

						if child.Name == mapName then
							-- This card was voted for
							TweenService:Create(btn, TweenInfo.new(0.25),
								{BackgroundColor3 = Color3.fromRGB(0, 200, 90)}):Play()
							if stroke then
								TweenService:Create(stroke, TweenInfo.new(0.25),
									{Transparency = 0, Color = Color3.fromRGB(0, 220, 100)}):Play()
							end
							btn.Text = "? VOTED!"
							if check then check.Visible = true end
						else
							-- Other cards reset
							TweenService:Create(btn, TweenInfo.new(0.25),
								{BackgroundColor3 = Color3.fromRGB(0, 130, 255)}):Play()
							if stroke then
								local idx = child.LayoutOrder
								local origAccent = CARD_ACCENTS[((idx - 1) % #CARD_ACCENTS) + 1]
								TweenService:Create(stroke, TweenInfo.new(0.25),
									{Transparency = 0.35, Color = origAccent}):Play()
							end
							btn.Text = "? VOTE"
							if check then check.Visible = false end
						end
					end
				end

				-- Auto-close after 3 seconds
				if autoCloseThread then
					task.cancel(autoCloseThread)
					autoCloseThread = nil
				end

				autoCloseThread = task.delay(3, function()
					if votedMap and gui.Enabled then
						TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
							{Position = UDim2.new(originalContainerPosition.X.Scale, originalContainerPosition.X.Offset, -0.5, 0)}
						):Play()
						task.delay(0.4, function()
							gui.Enabled = false
							container.Position = originalContainerPosition
						end)
						print("??? Voting GUI auto-closed after vote")
					end
					autoCloseThread = nil
				end)
			end)
		end
	end

	print("? Created", #maps, "map cards (from your template)")
end

-- ============================================
-- UPDATE VOTE COUNTS
-- ============================================

local function updateVoteCounts(voteCounts, maps)
	local totalVotes = 0
	for _, count in pairs(voteCounts) do
		totalVotes = totalVotes + count
	end

	for mapName, count in pairs(voteCounts) do
		local card = scrollFrame:FindFirstChild(mapName)
		if card and card:IsA("Frame") then
			local voteFrame = card:FindFirstChild("VoteFrame")
			if voteFrame then
				local voteLabel = voteFrame:FindFirstChild("VoteCount")
				if voteLabel then
					voteLabel.Text = count .. " vote" .. (count == 1 and "" or "s")
				end

				local voteFill = voteFrame:FindFirstChild("VoteFill")
				if voteFill then
					local pct = totalVotes > 0 and (count / totalVotes) or 0
					TweenService:Create(voteFill,
						TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Size = UDim2.new(pct, 0, 1, 0)}
					):Play()
				end
			end
		end
	end
end

-- ============================================
-- MAIN SETUP
-- ============================================

task.spawn(function()
	local success = waitForVotingEvents()
	if not success then
		warn("? Failed to get voting events")
		return
	end

	local currentRoundMaps = nil

	voteUpdateEvent.OnClientEvent:Connect(function(voteCounts, maps)
		print("?? Vote update received")

		-- Check if new voting round
		local isNewRound = false
		if not currentRoundMaps then
			isNewRound = true
		elseif maps and #maps ~= #currentRoundMaps then
			isNewRound = true
		else
			for i, name in ipairs(maps or {}) do
				if currentRoundMaps[i] ~= name then
					isNewRound = true
					break
				end
			end
		end

		if isNewRound then
			print("?? New voting round detected, creating cards")
			container.Position = originalContainerPosition

			if autoCloseThread then
				task.cancel(autoCloseThread)
				autoCloseThread = nil
			end

			votedMap = nil
			currentRoundMaps = maps and table.clone(maps) or {}

			if maps and #maps > 0 then
				createMapButtons(maps)
			end

			updateVoteCounts(voteCounts, maps)
			showVotingGui()
			print("? Voting GUI shown")
		else
			print("?? Updating vote counts only")
			updateVoteCounts(voteCounts, maps)
		end
	end)

	-- Hide on round/intermission
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local timerEvent = remoteEvents:FindFirstChild("TimerUpdate")
		if timerEvent then
			timerEvent.OnClientEvent:Connect(function(timeLeft, phase)
				if phase == "Round" or phase == "Intermission" or phase == "RoundOver" then
					hideVotingGui()
					currentRoundMaps = nil
				end
			end)
		end
	end

	print("? Voting GUI loaded and listening")
end)