
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MPS = game:GetService("MarketplaceService")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

-- Wait for notification system to be ready
task.spawn(function()
	local tries = 0
	while not _G.Notify and tries < 50 do
		task.wait(0.1)
		tries = tries + 1
	end
	if _G.Notify then
		print("? TrailShop: _G.Notify connected")
	else
		warn("?? TrailShop: _G.Notify not found after 5s")
	end
end)


local plr = Players.LocalPlayer
local gui = script.Parent
local TMID = 1711477336
local SHOW_TRAIL_ICONS = false -- Set false to remove trail icons

local shopToggle = gui:WaitForChild("ShopToggle")
local container = gui:WaitForChild("Container")
local titleBar = container:WaitForChild("TitleBar")
local tabBar = container:WaitForChild("Body"):WaitForChild("LeftPanel"):WaitForChild("TabBar")
local trailList = container:WaitForChild("Body"):WaitForChild("LeftPanel"):WaitForChild("TrailList")
local rp = container:WaitForChild("Body"):WaitForChild("RightPanel")
local preview = rp:WaitForChild("Preview")
local selName = rp:WaitForChild("SelectedName")
local selDesc = rp:WaitForChild("SelectedDesc")
local priceLabel = rp:WaitForChild("PriceRow"):WaitForChild("PriceLabel")
local actionBtn = rp:WaitForChild("ActionBtn")
local closeBtn = titleBar:WaitForChild("CloseBtn")
container.Visible = false

for _,c in ipairs(tabBar:GetChildren()) do if c:IsA("TextButton") or c:IsA("UIListLayout") then c:Destroy() end end
local tl = Instance.new("UIListLayout") tl.FillDirection=Enum.FillDirection.Horizontal tl.HorizontalAlignment=Enum.HorizontalAlignment.Left tl.Padding=UDim.new(0,6) tl.Parent=tabBar

local CATS={
	{N="Free",L="FREE",A=Color3.fromRGB(100,200,100),I=Color3.fromRGB(40,80,40)},
	{N="Coin",L="COIN",A=Color3.fromRGB(255,200,50),I=Color3.fromRGB(80,65,20)},
	{N="Premium",L="PREMIUM",A=Color3.fromRGB(180,80,255),I=Color3.fromRGB(60,30,80)},
}
local tabs={}
for _,cat in ipairs(CATS) do
	local b=Instance.new("TextButton") b.Name=cat.N.."Tab" b.Size=UDim2.new(0,92,1,0) b.BackgroundColor3=cat.I b.BorderSizePixel=0
	b.Font=Enum.Font.GothamBlack b.TextSize=12 b.TextColor3=Color3.new(1,1,1) b.Text=cat.L b.Parent=tabBar
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,10) tabs[cat.N]={B=b,A=cat.A,I=cat.I}
end

for _,c in ipairs(trailList:GetChildren()) do if c:IsA("UIGridLayout") or c:IsA("TextButton") or c:IsA("ImageButton") or c:IsA("Frame") then c:Destroy() end end
local gr=Instance.new("UIGridLayout") gr.CellSize=UDim2.new(0,88,0,88) gr.CellPadding=UDim2.new(0,10,0,10) gr.SortOrder=Enum.SortOrder.LayoutOrder gr.Parent=trailList

local shopData,curCat,curEq,owned,hasTM,selTrail,cards,selId = nil,"Free",nil,{},false,nil,{},nil
local setPrev
local cdbgShop = function() end

-- inRoundCheck: track if we're in a round
local inRound = false
task.spawn(function()
	local RS2 = game:GetService("ReplicatedStorage")
	local GV2 = RS2:FindFirstChild("GameValues")
	if not GV2 then return end
	local GS2 = GV2:FindFirstChild("GameState")
	if not GS2 then return end
	inRound = (GS2.Value == "Playing")
	GS2.Changed:Connect(function(v)
		inRound = (v == "Playing")
		-- Refresh display when state changes
		if selTrail and setPrev then setPrev(selTrail) end
	end)
end)
-- end inRoundCheck

setPrev = function(t)
	selTrail=t selId=t and t.Id or nil
	if not t then selName.Text="Select a trail" selDesc.Text="" priceLabel.Text="" actionBtn.Text="Equip"
		actionBtn.BackgroundColor3=Color3.fromRGB(0,130,255) preview.BackgroundColor3=Color3.fromRGB(50,45,80)
		local og=preview:FindFirstChildOfClass("UIGradient") if og then og:Destroy() end
		local pi=preview:FindFirstChild("PreviewIcon") if pi then pi.Visible=false end return end
	selName.Text=t.Name or "Trail" selDesc.Text=t.Description or ""
	local og=preview:FindFirstChildOfClass("UIGradient") if og then og:Destroy() end
	-- Update preview icon
	local prevIcon = preview:FindFirstChild("PreviewIcon")
	if SHOW_TRAIL_ICONS and t.Icon and t.Icon ~= "" then
		if not prevIcon then
			prevIcon = Instance.new("ImageLabel")
			prevIcon.Name = "PreviewIcon"
			prevIcon.Size = UDim2.new(1, -16, 1, -16)
			prevIcon.Position = UDim2.new(0, 8, 0, 8)
			prevIcon.BackgroundTransparency = 1
			prevIcon.ScaleType = Enum.ScaleType.Fit
			prevIcon.ZIndex = 3
			prevIcon.Parent = preview
		end
		prevIcon.Image = t.Icon
		prevIcon.Visible = true
	else
		if prevIcon then prevIcon.Visible = false end
	end
	if t.Rainbow then
		local g=Instance.new("UIGradient") g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
			ColorSequenceKeypoint.new(0.17,Color3.fromRGB(255,165,0)),ColorSequenceKeypoint.new(0.33,Color3.fromRGB(255,255,0)),
			ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.67,Color3.fromRGB(0,150,255)),
			ColorSequenceKeypoint.new(0.83,Color3.fromRGB(75,0,130)),ColorSequenceKeypoint.new(1,Color3.fromRGB(148,0,211))}) g.Parent=preview
	else preview.BackgroundColor3=t.Color1 or Color3.fromRGB(100,100,120)
		if t.Color2 then local g=Instance.new("UIGradient") g.Color=ColorSequence.new(t.Color1 or Color3.new(1,1,1),t.Color2) g.Parent=preview end end

	local o=owned[t.Id] local isO=(o==true) local isL=(o=="locked") local isE=(curEq==t.Id)
	local isP=t.RequiresGamepass==true local isPL=isP and not hasTM local isF=(t.Price==0 and not isP) local isC=(t.Category=="Coin")
	if isP then priceLabel.Text="Premium"
	elseif isC and t.Price>0 then priceLabel.Text="Coins: "..t.Price
	else priceLabel.Text="Free" end
	if isE then actionBtn.Text="Equipped" actionBtn.BackgroundColor3=Color3.fromRGB(0,150,80)
	elseif isPL then actionBtn.Text="Get TrailMaster" actionBtn.BackgroundColor3=Color3.fromRGB(120,60,180)
	elseif isF then actionBtn.Text="Equip" actionBtn.BackgroundColor3=Color3.fromRGB(0,130,255)
	elseif isP and hasTM then actionBtn.Text="Equip" actionBtn.BackgroundColor3=Color3.fromRGB(0,130,255)
	elseif isC and isO then actionBtn.Text="Bought" actionBtn.BackgroundColor3=Color3.fromRGB(0,150,80)
	elseif isC and isL then actionBtn.Text="Locked (1 per round)" actionBtn.BackgroundColor3=Color3.fromRGB(80,80,80)
	else actionBtn.Text="Buy ("..( t.Price or 0)..")" actionBtn.BackgroundColor3=Color3.fromRGB(0,180,80) end
	-- Override ALL actions during rounds
	if inRound and not isE then
		actionBtn.Text = "Locked (In Round)"
		actionBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	end
	-- #region agent log
	cdbgShop("PRICE_FMT", "TrailShopScript:setPrev", "Price/action labels set", {
		trailId = t.Id,
		priceText = priceLabel.Text,
		actionText = actionBtn.Text,
	})
	-- #endregion
end

local function hlSel() for id,btn in pairs(cards) do local st=btn:FindFirstChildOfClass("UIStroke")
	if st then if id==selId then st.Transparency=0 st.Thickness=2 else st.Transparency=0.5 st.Thickness=1.2 end end end end

local function mkCard(t)
	local hasIcon = SHOW_TRAIL_ICONS and t.Icon and t.Icon ~= ""
	local b
	if hasIcon then
		b = Instance.new("ImageButton")
		b.Image = ""
		b.AutoButtonColor = false
	else
		b = Instance.new("ImageButton")
		b.Image = ""
		b.AutoButtonColor = false
	end
	b.Name = "T_" .. t.Id
	b.BorderSizePixel = 0
	b.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
	b.ClipsDescendants = true
	b.LayoutOrder = t.LayoutOrder or 99
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 14)

	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(100, 70, 180)
	st.Thickness = 1.2
	st.Transparency = 0.5
	st.Parent = b

	-- Color swatch background
	local sw = Instance.new("Frame")
	sw.Name = "Sw"
	sw.Size = UDim2.new(1, -14, 1, -34)
	sw.Position = UDim2.new(0, 7, 0, 7)
	sw.BorderSizePixel = 0
	sw.BackgroundColor3 = t.Color1 or Color3.fromRGB(120, 120, 140)
	sw.Parent = b
	Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 10)

	-- Gradient on swatch
	local g = Instance.new("UIGradient")
	if t.Rainbow then
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 150, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211)),
		})
	elseif t.Color2 then
		g.Color = ColorSequence.new(t.Color1 or Color3.new(1, 1, 1), t.Color2)
	else
		g:Destroy()
		g = nil
	end
	if g then g.Parent = sw end

	-- Icon image overlay (on top of swatch)
	if hasIcon then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, -8, 1, -8)
		icon.Position = UDim2.new(0, 4, 0, 4)
		icon.BackgroundTransparency = 1
		icon.Image = t.Icon
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = 3
		icon.Parent = sw
	end

	-- Lock overlay
	local o = owned[t.Id]
	if o == "locked" then
		local lo = Instance.new("Frame")
		lo.Name = "Lock"
		lo.Size = UDim2.new(1, 0, 1, 0)
		lo.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		lo.BackgroundTransparency = 0.6
		lo.ZIndex = 5
		lo.Parent = b
		Instance.new("UICorner", lo).CornerRadius = UDim.new(0, 14)
		local li = Instance.new("TextLabel")
		li.Size = UDim2.new(1, 0, 0.6, 0)
		li.Position = UDim2.new(0, 0, 0.1, 0)
		li.BackgroundTransparency = 1
		li.Text = "🔒"
		li.TextSize = 28
		li.ZIndex = 6
		li.Parent = b
	end

	-- Trail name at bottom
	local nl = Instance.new("TextLabel")
	nl.Name = "Nm"
	nl.Size = UDim2.new(1, -10, 0, 18)
	nl.Position = UDim2.new(0, 5, 1, -22)
	nl.BackgroundTransparency = 1
	nl.Text = t.Name or "Trail"
	nl.Font = Enum.Font.GothamBold
	nl.TextSize = 10
	nl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nl.TextTruncate = Enum.TextTruncate.AtEnd
	nl.Parent = b

	b.MouseButton1Click:Connect(function() setPrev(t) hlSel() end)
	return b
end

-- #region agent log
local reDbgShop = RS:WaitForChild("RemoteEvents", 10)
local ClientDebugLogShop = reDbgShop and reDbgShop:FindFirstChild("ClientDebugLog")
cdbgShop = function(hId, loc, msg, data)
	if ClientDebugLogShop then pcall(function() ClientDebugLogShop:FireServer({hypothesisId=hId,location=loc,message=msg,data=data or {},timestamp=DateTime.now().UnixTimestampMillis}) end) end
end
-- #endregion

local function loadData()
	local re=RS:WaitForChild("RemoteEvents",10) if not re then return end
	local f=re:WaitForChild("GetTrailShopData",10) if not f then return end
	local ok,d=pcall(function() return f:InvokeServer() end)
	-- #region agent log
	cdbgShop("SHOP_CLIENT", "TrailShopScript:loadData", "InvokeServer result", {ok=ok, hasData=d~=nil, hasTrails=d and d.Trails~=nil or false, trailCount=d and d.Trails and #d.Trails or 0, hasTM=d and d.HasTrailMaster or false, errMsg=not ok and tostring(d) or nil})
	-- #endregion
	if ok and d then shopData=d owned=d.Owned or {} curEq=d.Equipped hasTM=d.HasTrailMaster or false end
end

local function refresh()
	for _,c in ipairs(trailList:GetChildren()) do if c:IsA("TextButton") or c:IsA("ImageButton") then c:Destroy() end end
	cards={}
	-- #region agent log
	cdbgShop("SHOP_CLIENT", "TrailShopScript:refresh", "Refresh called", {hasShopData=shopData~=nil, hasTrails=shopData and shopData.Trails~=nil or false, trailCount=shopData and shopData.Trails and #shopData.Trails or 0, curCat=curCat})
	-- #endregion
	if not shopData or not shopData.Trails then return end
	local cardCount = 0
	for _,t in ipairs(shopData.Trails) do if t.Category==curCat then local c=mkCard(t) c.Parent=trailList cards[t.Id]=c cardCount=cardCount+1 end end
	-- #region agent log
	cdbgShop("SHOP_CLIENT", "TrailShopScript:refresh", "Cards created", {cardCount=cardCount, curCat=curCat})
	-- #endregion
	if selTrail and selTrail.Category==curCat then setPrev(selTrail) else setPrev(nil) end
	hlSel()
end

local function switchCat(n) curCat=n for k,d in pairs(tabs) do TS:Create(d.B,TweenInfo.new(0.2),{BackgroundColor3=(k==n) and d.A or d.I}):Play() end refresh() end
for n,d in pairs(tabs) do d.B.MouseButton1Click:Connect(function() switchCat(n) end) end

actionBtn.MouseButton1Click:Connect(function()
	if not selTrail then return end
	local re=RS:WaitForChild("RemoteEvents") local eq=re:WaitForChild("TrailEquip") local t=selTrail
	local o=owned[t.Id] local isO=(o==true) local isL=(o=="locked") local isE=(curEq==t.Id)
	local isP=t.RequiresGamepass==true local isPL=isP and not hasTM local isF=(t.Price==0 and not isP) local isC=(t.Category=="Coin")
	if isPL then pcall(function() MPS:PromptGamePassPurchase(plr,TMID) end) return end
	if isE then return end
	if isF or (isP and hasTM) then eq:FireServer("Equip",t.Id) return end
	if isC and isO then eq:FireServer("Equip",t.Id) return end
	if isC and isL then if _G.Notify then _G.Notify("Locked!","Already bought a coin trail this round!",3,"warning") end return end
	if isC and not isO then
		if _G.Confirm then _G.Confirm("Buy "..(t.Name or "Trail").."?","Spend "..t.Price.." coins?\nLasts this round only!\nOnly 1 coin trail per round!",
			function(yes) if yes then eq:FireServer("Purchase",t.Id) end end)
		else eq:FireServer("Purchase",t.Id) end return end
	eq:FireServer("Purchase",t.Id)
end)

local pOpen=false local PS=container.Size local PP=container.Position
local function toggle(f) if f~=nil then pOpen=f else pOpen=not pOpen end
	if pOpen then loadData() container.Visible=true container.Size=UDim2.new(0,0,0,0) container.Position=UDim2.new(0.5,0,0.5,0)
		TS:Create(container,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=PS,Position=PP}):Play()
		task.delay(0.25,function() switchCat(curCat) end)
	else TS:Create(container,TweenInfo.new(0.18),{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)}):Play()
		task.delay(0.18,function() container.Visible=false end) end end

shopToggle.MouseButton1Click:Connect(function() toggle() end)
closeBtn.MouseButton1Click:Connect(function() toggle(false) end)
UIS.InputBegan:Connect(function(i,g) if g then return end if i.KeyCode==Enum.KeyCode.B then toggle() end end)

task.spawn(function()
	local re=RS:WaitForChild("RemoteEvents",10) if not re then return end
	local ue=re:WaitForChild("TrailUpdate",10) if not ue then return end
	ue.OnClientEvent:Connect(function(act,tid)
		if act=="Equipped" then curEq=tid owned[tid]=true loadData() if selTrail then setPrev(selTrail) end refresh()
		elseif act=="Unequipped" then curEq=nil loadData() if selTrail then setPrev(selTrail) end refresh()
		elseif act=="Purchased" then owned[tid]=true curEq=tid loadData() if selTrail then setPrev(selTrail) end refresh()
			if _G.Notify then _G.Notify("Trail Purchased!","Active this round!",3,"trail") end
		elseif act=="Refresh" then
			-- Gamepass purchased or data changed - reload everything
			loadData() if selTrail then setPrev(selTrail) end refresh()
			if _G.Notify then _G.Notify("Unlocked!","TrailMaster gamepass activated! Premium trails unlocked!",3,"success") end
		elseif act=="NeedGamepass" then pcall(function() MPS:PromptGamePassPurchase(plr,TMID) end)
		elseif act=="NotEnoughCoins" then if _G.Notify then _G.Notify("Not Enough!","Need more coins!",3,"warning") end
		elseif act=="NeedPurchase" then if _G.Notify then _G.Notify("Buy First!","Purchase this trail!",3,"warning") end end
	end)
end)

loadData() switchCat("Free")
print("? Trail Shop loaded (v7 client)")

-- COIN DISPLAY IN TRAIL SHOP
task.spawn(function()
	local RS = game:GetService("ReplicatedStorage")
	local player = game:GetService("Players").LocalPlayer
	local cd = script.Parent:WaitForChild("Container"):WaitForChild("TitleBar"):FindFirstChild("CoinDisplay")
	if not cd then return end
	
	local function updateCd()
		local coins = 0
		local getCoins = RS:FindFirstChild("GetCoins")
		if getCoins then
			local ok, c = pcall(function() return getCoins:InvokeServer() end)
			if ok and c then coins = c end
		else
			local ls = player:FindFirstChild("leaderstats")
			if ls then local cv = ls:FindFirstChild("Coins") if cv then coins = cv.Value end end
		end
		cd.Text = "Coins: " .. tostring(coins)
	end
	
	local ls = player:WaitForChild("leaderstats", 10)
	if ls then local cv = ls:WaitForChild("Coins", 10) if cv then cv.Changed:Connect(updateCd) end end
	
	while true do updateCd() task.wait(3) end
end)

-- ROUND_LOCK_CLIENT
task.spawn(function()
	local RS = game:GetService("ReplicatedStorage")
	local GV = RS:FindFirstChild("GameValues")
	local GS = GV and GV:FindFirstChild("GameState")
	if not GS then return end
	
	local container = script.Parent:FindFirstChild("Container")
	if not container then return end
	
	GS.Changed:Connect(function(v)
		if v == "Playing" then
			-- Close shop when round starts
			container.Visible = false
		end
	end)
end)

-- ROUND_LOCK_BUTTONS
task.spawn(function()
	local RS = game:GetService("ReplicatedStorage")
	local GV = RS:FindFirstChild("GameValues")
	if not GV then return end
	local GS = GV:FindFirstChild("GameState")
	if not GS then return end
	
	local container = script.Parent:FindFirstChild("Container")
	if not container then return end
	local body = container:FindFirstChild("Body")
	if not body then return end
	local rPanel = body:FindFirstChild("RightPanel")
	if not rPanel then return end
	local actionBtn = rPanel:FindFirstChild("ActionBtn")
	if not actionBtn then return end
	
	local savedText = ""
	local savedColor = actionBtn.BackgroundColor3
	local locked = false
	
	local function lockShop()
		locked = true
		savedText = actionBtn.Text
		savedColor = actionBtn.BackgroundColor3
		actionBtn.Text = "LOCKED (In Round)"
		actionBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	end
	
	local function unlockShop()
		locked = false
		actionBtn.Text = savedText
		actionBtn.BackgroundColor3 = savedColor
	end
	
	GS.Changed:Connect(function(v)
		if v == "Playing" then
			lockShop()
		else
			unlockShop()
		end
	end)
	
	if GS.Value == "Playing" then
		lockShop()
	end
	
	-- Override action button click during lock
	actionBtn.MouseButton1Click:Connect(function()
		if locked then
			if _G.Notify then
				_G.Notify("Locked!", "You can only buy/equip trails in the lobby!", 2.5, "warning")
			end
		end
	end)
end)
