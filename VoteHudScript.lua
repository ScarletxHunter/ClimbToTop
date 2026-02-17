-- ============================================
-- VOTE HUD GUI - Shows vote counts at bottom of screen
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local voteHudGui = script.Parent
local container = voteHudGui:WaitForChild("Container")

local GameState = ReplicatedStorage:WaitForChild("GameValues"):WaitForChild("GameState")
local UpdateVoteHud = ReplicatedStorage:WaitForChild("UpdateVoteHud", 10)
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local ClientDebugLog = remoteEvents and remoteEvents:FindFirstChild("ClientDebugLog")

-- #region agent log
local function cdbgVote(hId, loc, msg, data)
	if not ClientDebugLog then return end
	pcall(function()
		ClientDebugLog:FireServer({
			id = "log_" .. tostring(math.floor(os.clock() * 1000)) .. "_" .. HttpService:GenerateGUID(false),
			runId = "ui_visibility_debug",
			hypothesisId = hId,
			location = loc,
			message = msg,
			data = data or {},
			timestamp = DateTime.now().UnixTimestampMillis
		})
	end)
end
-- #endregion

if not UpdateVoteHud then warn("? UpdateVoteHud not found") return end

local slots = {}
for i = 1, 3 do
	local slot = container:FindFirstChild("Slot" .. i)
	if slot then
		slots[i] = {
			Frame = slot,
			MapName = slot:FindFirstChild("MapName"),
			VoteCount = slot:FindFirstChild("VoteCount"),
		}
	end
end

-- Show/hide based on game state
local ORIGINAL_SIZE = container.Size

-- #region agent log
cdbgVote("VOTE_INIT", "VoteHudScript:init", "Vote HUD script initialized", {
	containerVisible = container.Visible,
	containerSize = tostring(container.Size),
	gameState = GameState.Value,
})
-- #endregion

GameState:GetPropertyChangedSignal("Value"):Connect(function()
	-- #region agent log
	cdbgVote("VOTE_STATE", "VoteHudScript:GameStateChanged", "GameState changed", {
		newState = GameState.Value,
		containerVisible = container.Visible,
		containerSize = tostring(container.Size),
	})
	-- #endregion
	if GameState.Value == "Voting" then
		container.Visible = true
		container.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = ORIGINAL_SIZE
		}):Play()
	else
		TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()
		task.delay(0.21, function() container.Visible = false end)
		-- #region agent log
		cdbgVote("VOTE_VIS", "VoteHudScript:GameStateChanged", "Vote HUD hide requested", {
			state = GameState.Value,
			containerVisible = container.Visible,
			containerSize = tostring(container.Size),
		})
		-- #endregion
	end
end)

-- Update from server
UpdateVoteHud.OnClientEvent:Connect(function(voteCounts, assignedMaps)
	if not voteCounts or not assignedMaps then return end
	-- #region agent log
	cdbgVote("VOTE_EVENT", "VoteHudScript:UpdateVoteHud", "UpdateVoteHud received", {
		gameState = GameState.Value,
		containerVisible = container.Visible,
		mapCount = (assignedMaps["VoteObject1"] and 1 or 0) + (assignedMaps["VoteObject2"] and 1 or 0) + (assignedMaps["VoteObject3"] and 1 or 0),
	})
	-- #endregion

	-- Map VoteObject assignments to slots
	for i = 1, 3 do
		local slotData = slots[i]
		if not slotData then continue end

		local mapName = assignedMaps["VoteObject" .. i]
		if mapName then
			slotData.Frame.Visible = true
			if slotData.MapName then slotData.MapName.Text = mapName end
			if slotData.VoteCount then
				local count = voteCounts[mapName] or 0
				slotData.VoteCount.Text = tostring(count)

				-- Pop animation on vote change
				TweenService:Create(slotData.VoteCount, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
					TextSize = 20
				}):Play()
				task.delay(0.1, function()
					if slotData.VoteCount then
						TweenService:Create(slotData.VoteCount, TweenInfo.new(0.15), {
							TextSize = 14
						}):Play()
					end
				end)
			end
		else
			slotData.Frame.Visible = false
		end
	end
end)

-- Initial
if GameState.Value == "Voting" then
	container.Visible = true
else
	container.Visible = false
end

-- #region agent log
cdbgVote("VOTE_INIT", "VoteHudScript:init", "Initial visibility applied", {
	gameState = GameState.Value,
	containerVisible = container.Visible,
	containerSize = tostring(container.Size),
})
-- #endregion

print("? Vote HUD GUI loaded")