local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MarkerUpdateEvent = game.ReplicatedStorage.MarkerUpdateEvent

local playerProgress = {}

MarkerUpdateEvent.OnServerEvent:Connect(function(player, progress)
	playerProgress[player.UserId] = progress
	MarkerUpdateEvent:FireAllClients(player, progress)
end)

Players.PlayerAdded:Connect(function(newPlayer)
	for userId, progress in pairs(playerProgress) do
		local otherPlayer = Players:GetPlayerByUserId(userId)
		if otherPlayer then
			MarkerUpdateEvent:FireClient(newPlayer, otherPlayer, progress)
		end
	end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	playerProgress[leavingPlayer.UserId] = nil
	MarkerUpdateEvent:FireAllClients(leavingPlayer, nil)
end)