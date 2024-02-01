local module = {}
local Core = shared.Core
local Network = Core.Get("Network")
local Depth = Core.Get("Depth")

function module:Init()
    Network:ObserveSignal("CameraListener", function(ID, Settings)
        if Depth:GetActive() == false then
            Depth:SetActive(true)
            Depth:SetID(ID)
            Depth:TweenCamera(Settings)
        elseif Settings.Override == true then
            Depth.TweenInfo.Stop()
            Depth:Reset(Settings)
            Depth:SetActive(true)
            Depth:SetID(ID)
            Depth:TweenCamera(Settings)
        end
    end)
end

return module