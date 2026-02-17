-- ============================================
-- ADMIN GUI BUILDER - Paste ALL of this into Roblox Studio Command Bar
-- Creates the full AdminGui ScreenGui in StarterGui
-- After running, you can change any colors/sizes/fonts in Properties!
-- Then add the AdminClient LocalScript inside AdminGui
-- ============================================

local SG = game:GetService("StarterGui")
if SG:FindFirstChild("AdminGui") then SG.AdminGui:Destroy() end

local function c(cls, p)
	local i = Instance.new(cls)
	for k,v in pairs(p) do if k~="P" then pcall(function() i[k]=v end) end end
	if p.P then i.Parent = p.P end
	return i
end
local function corner(p,r) c("UICorner",{CornerRadius=UDim.new(0,r or 8),P=p}) end
local function stroke(p,col,t) c("UIStroke",{Color=col or Color3.fromRGB(55,55,75),Thickness=t or 1,P=p}) end

-- Colors (change these in Properties after building!)
local bg      = Color3.fromRGB(22,22,32)
local hdr     = Color3.fromRGB(38,38,55)
local btnC    = Color3.fromRGB(55,115,245)
local danger  = Color3.fromRGB(210,55,55)
local success = Color3.fromRGB(45,170,75)
local warnC   = Color3.fromRGB(225,155,35)
local purple  = Color3.fromRGB(130,70,220)
local inputC  = Color3.fromRGB(16,16,26)
local txt     = Color3.fromRGB(228,228,238)
local dim     = Color3.fromRGB(120,120,145)
local accent  = Color3.fromRGB(95,175,255)
local tabC    = Color3.fromRGB(42,42,58)
local border  = Color3.fromRGB(55,55,75)

-- ═══ ScreenGui ═══
local gui = c("ScreenGui", {Name="AdminGui", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=100, P=SG})

-- ═══ Toggle Button ═══
local toggleBtn = c("TextButton", {Name="ToggleBtn", Size=UDim2.new(0,48,0,48), Position=UDim2.new(1,-60,1,-130), BackgroundColor3=btnC, Text="⚙", TextColor3=txt, TextSize=24, Font=Enum.Font.GothamBold, AutoButtonColor=false, Visible=true, P=gui})
corner(toggleBtn,12) stroke(toggleBtn,accent,2)

-- ═══ Panel ═══
local panelW = 350
local panel = c("Frame", {Name="Panel", Size=UDim2.new(0,panelW,1,-20), Position=UDim2.new(1,-(panelW+8),0,10), BackgroundColor3=bg, Visible=false, ClipsDescendants=true, P=gui})
corner(panel,14) stroke(panel,border,1)

-- TopBar
local topBar = c("Frame", {Name="TopBar", Size=UDim2.new(1,0,0,46), BackgroundColor3=hdr, P=panel})
corner(topBar,14)
c("TextLabel", {Name="Title", Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,14,0,0), BackgroundTransparency=1, Text="⚙ Admin Panel", TextColor3=accent, Font=Enum.Font.GothamBold, TextSize=18, TextXAlignment=Enum.TextXAlignment.Left, P=topBar})
local closeBtn = c("TextButton", {Name="CloseBtn", Size=UDim2.new(0,34,0,34), Position=UDim2.new(1,-40,0,6), BackgroundColor3=danger, Text="✕", TextColor3=txt, TextSize=16, Font=Enum.Font.GothamBold, AutoButtonColor=false, P=topBar})
corner(closeBtn,8)

-- TargetFrame
local tgtY = 52
local tgtFrame = c("Frame", {Name="TargetFrame", Size=UDim2.new(1,-16,0,42), Position=UDim2.new(0,8,0,tgtY), BackgroundColor3=inputC, P=panel})
corner(tgtFrame,8) stroke(tgtFrame,border,1)
c("TextLabel", {Name="TargetLabel", Size=UDim2.new(0,55,1,0), Position=UDim2.new(0,8,0,0), BackgroundTransparency=1, Text="Target:", TextColor3=dim, Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, P=tgtFrame})
c("TextBox", {Name="TargetBox", Size=UDim2.new(1,-125,1,-8), Position=UDim2.new(0,62,0,4), BackgroundTransparency=1, PlaceholderText="player name...", PlaceholderColor3=dim, Text="", TextColor3=txt, Font=Enum.Font.Gotham, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, P=tgtFrame})
local meBtn = c("TextButton", {Name="MeBtn", Size=UDim2.new(0,48,0,30), Position=UDim2.new(1,-56,0,6), BackgroundColor3=btnC, Text="Me", TextColor3=txt, Font=Enum.Font.GothamBold, TextSize=13, AutoButtonColor=false, P=tgtFrame})
corner(meBtn,6)

-- TabBar
local tabY = tgtY + 48
local tabBarFrame = c("Frame", {Name="TabBar", Size=UDim2.new(1,-16,0,34), Position=UDim2.new(0,8,0,tabY), BackgroundTransparency=1, P=panel})
c("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,3), FillDirection=Enum.FillDirection.Horizontal, P=tabBarFrame})

local tabNames = {"Player","Cash","Round","Trail","Server"}
for i, name in ipairs(tabNames) do
	local tb = c("TextButton", {Name="Tab_"..name, Size=UDim2.new(1/#tabNames,-3,1,0), BackgroundColor3=(i==1 and btnC or tabC), Text=name, TextColor3=txt, Font=Enum.Font.GothamBold, TextSize=12, LayoutOrder=i, AutoButtonColor=false, P=tabBarFrame})
	corner(tb,6)
end

-- ═══ HELPERS for tab content ═══
local contentY = tabY + 40

local function makeContent(name, vis)
	local sf = c("ScrollingFrame", {Name=name, Size=UDim2.new(1,-16,1,-(contentY+8)), Position=UDim2.new(0,8,0,contentY), BackgroundTransparency=1, ScrollBarThickness=4, ScrollBarImageColor3=dim, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, Visible=vis, P=panel})
	c("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6), P=sf})
	c("UIPadding", {PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2), PaddingTop=UDim.new(0,2), PaddingBottom=UDim.new(0,2), P=sf})
	return sf
end

local function sectHdr(parent, text, order)
	local h = c("Frame", {Name="Hdr_"..text:gsub("%s",""), Size=UDim2.new(1,0,0,28), BackgroundColor3=hdr, LayoutOrder=order, P=parent})
	corner(h,6)
	c("TextLabel", {Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,8,0,0), BackgroundTransparency=1, Text=text, TextColor3=accent, Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, P=h})
end

local function btnRow(parent, buttons, order)
	local row = c("Frame", {Name="Row_"..order, Size=UDim2.new(1,0,0,42), BackgroundTransparency=1, LayoutOrder=order, P=parent})
	c("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4), FillDirection=Enum.FillDirection.Horizontal, P=row})
	for i, bd in ipairs(buttons) do
		local b = c("TextButton", {Name=bd[1], Size=UDim2.new(1/#buttons,-4,1,0), BackgroundColor3=bd[2] or btnC, Text=bd[1], TextColor3=txt, Font=Enum.Font.GothamBold, TextSize=13, LayoutOrder=i, AutoButtonColor=false, P=row})
		corner(b,6)
	end
end

local function fullBtn(parent, name, color, order, label)
	local b = c("TextButton", {Name=name, Size=UDim2.new(1,0,0,42), BackgroundColor3=color or btnC, Text=label or name, TextColor3=txt, Font=Enum.Font.GothamBold, TextSize=14, LayoutOrder=order, AutoButtonColor=false, P=parent})
	corner(b,8)
end

local function inputBox(parent, name, placeholder, order)
	local fr = c("Frame", {Name=name.."Frame", Size=UDim2.new(1,0,0,40), BackgroundColor3=inputC, LayoutOrder=order, P=parent})
	corner(fr,6) stroke(fr,border,1)
	c("TextBox", {Name=name, Size=UDim2.new(1,-16,1,-8), Position=UDim2.new(0,8,0,4), BackgroundTransparency=1, PlaceholderText=placeholder, PlaceholderColor3=dim, Text="", TextColor3=txt, Font=Enum.Font.Gotham, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, P=fr})
end

-- ═══════════════════════════════════════
-- PLAYER TAB
-- ═══════════════════════════════════════
local pTab = makeContent("PlayerContent", true)
sectHdr(pTab, "ONLINE PLAYERS", 1)
local pGrid = c("Frame", {Name="PlayerGrid", Size=UDim2.new(1,0,0,40), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, LayoutOrder=2, P=pTab})
c("UIGridLayout", {CellSize=UDim2.new(0.48,0,0,34), CellPadding=UDim2.new(0.02,0,0,4), SortOrder=Enum.SortOrder.LayoutOrder, P=pGrid})

sectHdr(pTab, "ACTIONS", 3)
btnRow(pTab, {{"Kill",danger},{"Kick",danger},{"Heal",success}}, 4)
btnRow(pTab, {{"Respawn",btnC},{"GodMode",warnC},{"Freeze",purple}}, 5)
btnRow(pTab, {{"TeleportTo",btnC},{"TpAllToMe",warnC}}, 6)
fullBtn(pTab, "Invisible", purple, 7, "Toggle Invisible")

sectHdr(pTab, "SPEED & JUMP", 8)
inputBox(pTab, "SpeedBox", "Speed (default 16)", 9)
fullBtn(pTab, "SetSpeed", btnC, 10, "Set Speed")
inputBox(pTab, "JumpBox", "Jump Power (default 50)", 11)
fullBtn(pTab, "SetJump", btnC, 12, "Set Jump")

-- ═══════════════════════════════════════
-- CASH TAB
-- ═══════════════════════════════════════
local cTab = makeContent("CashContent", false)
sectHdr(cTab, "COINS", 1)
inputBox(cTab, "CoinBox", "Amount...", 2)
btnRow(cTab, {{"GiveCoins",success},{"RemoveCoins",danger},{"SetCoins",warnC}}, 3)
sectHdr(cTab, "WINS", 4)
inputBox(cTab, "WinBox", "Amount (default 1)...", 5)
fullBtn(cTab, "GiveWins", success, 6, "Give Wins")

-- ═══════════════════════════════════════
-- ROUND TAB
-- ═══════════════════════════════════════
local rTab = makeContent("RoundContent", false)
sectHdr(rTab, "ROUND CONTROL", 1)
btnRow(rTab, {{"SkipRound",warnC},{"EndRound",danger}}, 2)
inputBox(rTab, "TimerBox", "Seconds (e.g. 60)...", 3)
fullBtn(rTab, "SetTimer", btnC, 4, "Set Round Timer")
sectHdr(rTab, "GAME STATE", 5)
btnRow(rTab, {{"Intermission",btnC},{"Playing",success}}, 6)
btnRow(rTab, {{"Voting",purple},{"RoundEnd",danger}}, 7)
sectHdr(rTab, "TIME OF DAY", 8)
btnRow(rTab, {{"Day",warnC},{"Night",purple}}, 9)
btnRow(rTab, {{"Sunset",Color3.fromRGB(200,100,50)},{"Sunrise",Color3.fromRGB(200,150,50)}}, 10)

-- ═══════════════════════════════════════
-- TRAIL TAB
-- ═══════════════════════════════════════
local tTab = makeContent("TrailContent", false)
sectHdr(tTab, "GIVE / MANAGE TRAIL", 1)
inputBox(tTab, "TrailBox", "Trail ID (e.g. Rainbow, Fire, Titan)...", 2)
btnRow(tTab, {{"GiveTrail",success},{"EquipTrail",btnC}}, 3)
btnRow(tTab, {{"UnequipTrail",warnC},{"RemoveTrail",danger}}, 4)
sectHdr(tTab, "AVAILABLE TRAILS (tap to select)", 5)
local tGrid = c("Frame", {Name="TrailGrid", Size=UDim2.new(1,0,0,40), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, LayoutOrder=6, P=tTab})
c("UIGridLayout", {CellSize=UDim2.new(0.48,0,0,32), CellPadding=UDim2.new(0.02,0,0,3), SortOrder=Enum.SortOrder.LayoutOrder, P=tGrid})
-- Hint button (replaced dynamically by script)
local tHint = c("TextButton", {Name="_RetryHint", Text="Trails load when you open this tab", BackgroundColor3=Color3.fromRGB(55,55,75), TextColor3=dim, Font=Enum.Font.GothamBold, TextSize=11, AutoButtonColor=false, P=tGrid})
corner(tHint, 6)

-- ═══════════════════════════════════════
-- SERVER TAB
-- ═══════════════════════════════════════
local sTab = makeContent("ServerContent", false)
sectHdr(sTab, "ANNOUNCEMENT", 1)
inputBox(sTab, "AnnounceBox", "Message to all players...", 2)
fullBtn(sTab, "SendAnnounce", btnC, 3, "Send Announcement")
sectHdr(sTab, "TELEPORT", 4)
fullBtn(sTab, "TpAllBtn", warnC, 5, "Teleport All Players To Me")
sectHdr(sTab, "CHAT COMMANDS", 6)
local helpLabel = c("TextLabel", {Name="CmdHelp", Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundColor3=inputC, Text="/kill /kick /heal /god /invis /freeze\n/tp /tpall /speed /jump\n/coins /rmcoins /setcoins /wins\n/skip /endround /timer /state\n/day /night /trail /equip /unequip\n/say /announce /cmds", TextColor3=dim, Font=Enum.Font.Code, TextSize=11, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, LayoutOrder=7, P=sTab})
corner(helpLabel,6)
c("UIPadding", {PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8), PaddingTop=UDim.new(0,6), PaddingBottom=UDim.new(0,6), P=helpLabel})

print("✅ AdminGui created in StarterGui!")
print("   → You can now change colors, sizes, fonts in Properties panel")
print("   → Add a LocalScript named 'AdminClient' inside AdminGui")
print("   → Paste the AdminClient.lua code into that LocalScript")
