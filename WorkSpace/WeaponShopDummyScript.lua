-- ============================================
-- SHOP NPC SCRIPT (Fixed Icon Visibility)
-- Place in: Workspace/ShopNPC/Script
-- ============================================

local npc = script.Parent
local torso = npc:WaitForChild("Torso") or npc:WaitForChild("HumanoidRootPart")
local head = npc:WaitForChild("Head")

print("?? Shop NPC script loading...")

-- =========================================================
-- PROXIMITYPROMPT
-- =========================================================

local prompt = Instance.new("ProximityPrompt")
prompt.Name = "ShopPrompt"
prompt.ActionText = "Open Weapon Shop"
prompt.ObjectText = "?? Shop Keeper"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.MaxActivationDistance = 10
prompt.HoldDuration = 0
prompt.RequiresLineOfSight = false
prompt.Parent = torso

-- =========================================================
-- CLICKDETECTOR
-- =========================================================

local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 12
clickDetector.Parent = torso

-- =========================================================
-- FLOATING ICON (FIXED - Only visible when close!)
-- =========================================================

local billboard = Instance.new("BillboardGui")
billboard.Name = "ShopLabel"
billboard.Size = UDim2.new(0, 120, 0, 120)  -- Smaller size
billboard.StudsOffset = Vector3.new(0, 3.5, 0)
billboard.AlwaysOnTop = false  -- CHANGED: Don't show through walls
billboard.MaxDistance = 30  -- ADDED: Only visible within 30 studs!
billboard.Parent = head

-- Icon (smaller)
local iconLabel = Instance.new("ImageLabel")
iconLabel.Size = UDim2.new(0, 50, 0, 50)  -- Smaller icon
iconLabel.Position = UDim2.new(0.5, -25, 0, 10)
iconLabel.BackgroundTransparency = 1
iconLabel.Image = "rbxassetid://6031094687"  -- Gun icon
iconLabel.ImageColor3 = Color3.fromRGB(255, 215, 0)
iconLabel.Parent = billboard

-- Text
local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 0, 25)
textLabel.Position = UDim2.new(0, 0, 1, -20)
textLabel.BackgroundTransparency = 1
textLabel.Text = "SHOP"
textLabel.Font = Enum.Font.FredokaOne
textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
textLabel.TextSize = 18  -- Fixed size instead of scaled
textLabel.TextStrokeTransparency = 0.5
textLabel.Parent = billboard

-- Spinning animation
local TweenService = game:GetService("TweenService")
local spinTween = TweenService:Create(
	iconLabel,
	TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
	{Rotation = 360}
)
spinTween:Play()

-- =========================================================
-- REMOTE EVENT
-- =========================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)

if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

local OpenShopEvent = RemoteEvents:FindFirstChild("OpenToolShop")
if not OpenShopEvent then
	OpenShopEvent = Instance.new("RemoteEvent")
	OpenShopEvent.Name = "OpenToolShop"
	OpenShopEvent.Parent = RemoteEvents
end

-- =========================================================
-- INTERACTIONS
-- =========================================================

prompt.Triggered:Connect(function(player)
	print("?? [ProximityPrompt]", player.Name, "opened weapon shop")
	OpenShopEvent:FireClient(player)
end)

clickDetector.MouseClick:Connect(function(player)
	print("?? [ClickDetector]", player.Name, "clicked shop NPC")
	OpenShopEvent:FireClient(player)
end)

print("? Shop NPC ready with limited icon visibility!")