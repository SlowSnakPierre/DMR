local HumanoidUtils = {}
local Players = game:GetService("Players")

function HumanoidUtils.getAlivePlayerRootPart(player)
	local humanoid = HumanoidUtils.getPlayerHumanoid(player)
	if humanoid and not (humanoid.Health <= 0) then
		return humanoid.RootPart
	end
	return nil
end

function HumanoidUtils.getPlayerRootPart(player)
	local humanoid = HumanoidUtils.getPlayerHumanoid(player)
	if not humanoid then
		return nil
	end
	return humanoid.RootPart
end

function HumanoidUtils.getPlayerHumanoid(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

function HumanoidUtils.getAlivePlayerHumanoid(player)
	local humanoid = HumanoidUtils.getPlayerHumanoid(player)
	if humanoid and not (humanoid.Health <= 0) then
		return humanoid
	end
	return nil
end

function HumanoidUtils.unequipTools(player)
	local humanoid = HumanoidUtils.getPlayerHumanoid(player)
	if humanoid then
		humanoid:UnequipTools()
	end
end

function HumanoidUtils.getPlayerFromCharacter(character)
	local currentCharacter = character
	local currentPlayer = Players:GetPlayerFromCharacter(currentCharacter)
	while not currentPlayer do
		if not currentCharacter.Parent then
			return nil
		end
		currentCharacter = currentCharacter.Parent
		currentPlayer = Players:GetPlayerFromCharacter(currentCharacter)
	end
	return currentPlayer
end

return HumanoidUtils