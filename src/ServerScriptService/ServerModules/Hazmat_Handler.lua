local module = {}
local Functions = {}

local Core = shared.Core
local Network = Core.Get("Network")

local InChamber = {}
local State = "Normal" -- Normal, Hazard, Dead

local function Check(Player)
	local Character = Player.Character

	if not Character:FindFirstChild("Torso") or not Character:FindFirstChild("Helmet") then
		repeat
			if not Character:FindFirstChild("Torso") or not Character:FindFirstChild("Helmet") and Character.Humanoid.Health > 0 then
				if State == "Normal" then
					Character.Humanoid.Health = Character.Humanoid.Health - 5
				elseif State == "Hazard" then
					Character.Humanoid.Health = Character.Humanoid.Health - 10
				elseif State == "Dead" then
					Character.Humanoid.Health = Character.Humanoid.Health - 20
				end
			end

			if Character.Humanoid.Health <= 0 then
				InChamber[Player]:Disconnect()
				InChamber[Player] = nil

				break
			end

			task.wait(1)
		until InChamber[Player] == nil
	elseif State == "Hazard" then
		repeat
			Character.Humanoid.Health = Character.Humanoid.Health - 2.5

			if Character.Humanoid.Health <= 0 then
				InChamber[Player]:Disconnect()
				InChamber[Player] = nil

				break
			end

			task.wait(2)
		until InChamber[Player] == nil
	elseif State == "Dead" then
		repeat
			Character.Humanoid.Health = Character.Humanoid.Health - 10

			if Character.Humanoid.Health <= 0 then
				InChamber[Player]:Disconnect()
				InChamber[Player] = nil

				break
			end

			task.wait(1)
		until InChamber[Player] == nil
	end
end

local function Set(Player, SetState)
	if SetState == true then
		InChamber[Player] = Player.Character.Humanoid.Died:Connect(function()
			if InChamber[Player] ~= nil then
				InChamber[Player]:Disconnect()
			end

			InChamber[Player] = nil
		end)

		Check(Player)
	else
		if InChamber[Player] ~= nil then
			InChamber[Player]:Disconnect()
			InChamber[Player] = nil
		end
	end
end

--#region Functions
function Functions:HZSetfunction(Player, State)
	Set(Player, State)
end

function Functions:HZState(SetState)
	if State ~= "Dead" then
		State = SetState

		for Player, NA in pairs(InChamber) do
			if Player ~= nil and NA ~= nil and Player.Character then
				if InChamber[Player] ~= nil then
					InChamber[Player]:Disconnect()
					InChamber[Player] = nil
				end

				delay(3, function()
					InChamber[Player] = Player.Character.Humanoid.Died:Connect(function()
						if InChamber[Player] ~= nil then
							InChamber[Player]:Disconnect()
						end

						InChamber[Player] = nil
					end)

					game:GetService("ReplicatedStorage").Game.Events.Game.Hazmat:FireClient(Player, true, State)

					Check(Player)
				end)
			end
		end
	end
end

function Functions:Regen()
	State = "Normal"
end
--#endregion

function module:Init()
    Network:OnInvoke("HZReturnState", function(Player)
        if InChamber[Player] ~= nil then
            return true
        end
    
        return false
    end)

    Network:OnInvoke("HazmatState", function()
        return State
    end)
end

module.Functions = Functions

return module