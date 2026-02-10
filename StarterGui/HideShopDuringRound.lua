-- ============================================
-- SHOP VISIBILITY CONTROLLER
-- Place in: StarterPlayerScripts/HideShopDuringRound (LocalScript)
-- 
-- Fixed: Weapon shop does NOT auto-open anymore
-- Fixed: Shop just shows/hides based on round phase
-- Fixed: No random pop-ups
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("?? Shop Visibility Controller loading...")

local lastState = nil

-- ============================================
-- FIND ALL SHOP GUIS
-- ============================================
local function getShopGuis()
	local guis = {}
	local names = {
		"WeaponShopGui", "GamePassShop", "GamePassShopGui",
		"CoinShop", "CoinShopGui", "ShopButton", "ShopButtonGui"
	}
	for _, name in ipairs(names) do
		local g = playerGui:FindFirstChild(name)
		if g then table.insert(guis, g) end
	end
	return guis
end

-- ============================================
-- HIDE SHOP UIS (during round/voting)
-- ============================================
local function hideShopUIs()
	if lastState == "hidden" then return end
	lastState = "hidden"
	for _, g in ipairs(getShopGuis()) do
		g.Enabled = false
	end
	print("?? Shop UIs hidden (round active)")
end

-- ============================================
-- SHOW SHOP UIS (during lobby/intermission/round over)
-- No auto-open of weapon shop — player can open it themselves
-- ============================================
local function showShopUIs()
	if lastState == "shown" then return end
	lastState = "shown"
	for _, g in ipairs(getShopGuis()) do
		g.Enabled = true
	end
	print("?? Shop UIs shown (lobby/intermission)")
end

-- ============================================
-- LISTEN FOR TIMER PHASE CHANGES
-- ============================================
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if remoteEvents then
	local timerEvent = remoteEvents:WaitForChild("TimerUpdate", 5)
	if timerEvent then
		timerEvent.OnClientEvent:Connect(function(timeLeft, phase)
			if phase == "Round" then
				hideShopUIs()
			elseif phase == "Voting" then
				hideShopUIs()
			elseif phase == "RoundOver" then
				-- Just show the shop buttons, don't force-open weapon shop
				showShopUIs()
			elseif phase == "Intermission" then
				showShopUIs()
			end
		end)
		print("? Listening for TimerUpdate")
	end
end

-- ============================================
-- INITIAL STATE: Show everything on first load
-- ============================================
lastState = "shown"
for _, g in ipairs(getShopGuis()) do
	g.Enabled = true
end
print("?? Shop UIs shown (initial load)")
print("? Shop Visibility Controller loaded")