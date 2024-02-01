local module = {}
local Core = shared.Core
local Network = Core.Get("Network")
Network:Reserve({ "CameraListener", "RemoteEvent" })

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Monitors = {}

function module:Init()
    for _,v in pairs(CollectionService:GetTagged("Monitors")) do
        local ID = HttpService:GenerateGUID(false)
        local Settings = require(v.ClickDetector.Settings)
        Monitors[ID] = {
            Object = v,
            Players = {}
        }

        v.ClickDetector.MouseClick:Connect(function(Player)
            if Player.Character ~= nil then
                if Player.Character.Humanoid.WalkSpeed > 0 and Player.Character.Humanoid.Health > 0 then
                    Monitors[ID].Players[Player.Name] = Player
                    Network:Signal("CameraListener", Player, ID, Settings)
                end
            end
        end)
    end

    Network:ObserveSignal("CameraListener", function(Player, ToID, Command)
        if Monitors[ToID] ~= nil then
            local Monitor = Monitors[ToID]
            if Monitor.Players[Player.Name] ~= nil then
                if Command == "Finish" then
                    Monitor.Players[Player.Name] = nil
                    Player.Character:WaitForChild("HumanoidRootPart").Anchored = false
                elseif Command == "Freeze" then
                    Player.Character:WaitForChild("HumanoidRootPart").Anchored = true
                elseif Command == "Resume" then
                    Player.Character:WaitForChild("HumanoidRootPart").Anchored = false
                end
            end
        end
    end)
end

return module