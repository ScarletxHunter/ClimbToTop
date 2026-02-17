local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local board = workspace:WaitForChild("LobbyLeaderboard"):WaitForChild("Board")
local surfGui = board:WaitForChild("LeaderboardSurface")
local bg = surfGui:WaitForChild("Background")

local function formatTime(seconds)
	if not seconds or seconds <= 0 or seconds >= 999 then return "--" end
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	if m > 0 then return string.format("%dm %ds", m, s) end
	return string.format("%.1fs", s)
end

local function formatPlayTime(seconds)
	if not seconds or seconds <= 0 then return "0m" end
	local hours = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	if hours > 0 then return hours .. "h " .. mins .. "m" end
	return mins .. "m"
end

local function refreshBoard()
	-- Gather data from all online players
	local data = {}
	for _, p in pairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		if not ls then continue end
		local wins = ls:FindFirstChild("Wins")
		
		-- Get extended data from PlayerDataManager
		local PDM = nil
		pcall(function()
			PDM = require(game.ServerScriptService:FindFirstChild("PlayerDataManager") or game.ServerScriptService:FindFirstChild("GameScripts"):FindFirstChild("PlayerDataManager"))
		end)
		
		local pData = nil
		if PDM and PDM.GetData then
			pData = PDM.GetData(p)
		end
		
		table.insert(data, {
			Player = p,
			Wins = wins and wins.Value or 0,
			FastestTime = pData and pData.FastestTime or 999,
			TotalPlayTime = pData and pData.TotalPlayTime or 0,
		})
	end
	
	-- Sort by wins
	table.sort(data, function(a, b) return a.Wins > b.Wins end)
	
	-- Update rows
	for i = 1, 10 do
		local row = bg:FindFirstChild("Row" .. i)
		if not row then continue end
		
		local d = data[i]
		local pName = row:FindFirstChild("PlayerName")
		local winsLabel = row:FindFirstChild("Wins")
		local fastest = row:FindFirstChild("Fastest")
		local played = row:FindFirstChild("TimePlayed")
		local face = row:FindFirstChild("Face")
		
		if d then
			if pName then pName.Text = d.Player.DisplayName end
			if winsLabel then winsLabel.Text = tostring(d.Wins) end
			if fastest then fastest.Text = formatTime(d.FastestTime) end
			if played then played.Text = formatPlayTime(d.TotalPlayTime) end
			if face then
				pcall(function()
					local thumb = Players:GetUserThumbnailAsync(d.Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
					face.Image = thumb
				end)
			end
			row.Visible = true
		else
			if pName then pName.Text = "" end
			if winsLabel then winsLabel.Text = "" end
			if fastest then fastest.Text = "" end
			if played then played.Text = "" end
			if face then face.Image = "" end
			row.Visible = false
		end
	end
end

-- Refresh every 10 seconds
while true do
	pcall(refreshBoard)
	task.wait(10)
end
