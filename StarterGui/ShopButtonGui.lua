-- Place in: StarterGui/ShopButtonGui/LocalScript

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = script.Parent
local shopButton = gui:WaitForChild("ShopButton")

print("?? Shop Button loading...")

shopButton.MouseButton1Click:Connect(function()
	print("?? SHOP BUTTON CLICKED!")

	-- Button animation
	TweenService:Create(
		shopButton,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
		{Size = UDim2.new(0.13, 0, 0.085, 0)}
	):Play()

	-- Get PlayerGui
	local playerGui = player:WaitForChild("PlayerGui", 5)
	if not playerGui then
		warn("? PlayerGui not found!")
		return
	end

	-- Find GamePassShopGui
	local gamePassShopGui = playerGui:FindFirstChild("GamePassShopGui")
	if not gamePassShopGui then
		warn("? GamePassShopGui not found!")
		return
	end

	-- Enable and show
	gamePassShopGui.Enabled = true

	local container = gamePassShopGui:FindFirstChild("Container")
	if container then
		container.Visible = true
		container.Size = UDim2.new(0, 0, 0, 0)
		container.Position = UDim2.new(0.5, 0, 0.5, 0)

		TweenService:Create(
			container,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{
				Size = UDim2.new(0.7, 0, 0.7, 0),
				Position = UDim2.new(0.15, 0, 0.15, 0)
			}
		):Play()

		print("? GAMEPASS SHOP OPENED!")
	end
end)

print("? Shop Button loaded!")