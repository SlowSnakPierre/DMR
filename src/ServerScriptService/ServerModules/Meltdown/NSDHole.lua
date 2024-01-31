local module = {}

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NSDHole = Workspace.DMR.Black_Hole
local Hole    = NSDHole.Hole
local Region  = NSDHole.Region
local Nuke    = NSDHole.Nuke
local DMR  	  = NSDHole.DMRPlayerCollector
local Control = NSDHole.ControlPlayerCollector

local Regen   = Workspace.DMR.RegenDestruction

local Cache = {}

local Connections = {}
local Hooked = {}
local CleanUp = {}

local function Disconnect(...)
    local function DisconnectFunction(What)
        if type(What) == "table" then
            for _, Signal in pairs(What) do
                Signal:Disconnect()
            end
        else
            What:Disconnect()
        end
    end

    for _, Value in pairs({...}) do
        DisconnectFunction(Value)
    end
end

local function Hide(...)
    local function HideFunction(Ins)
        if Ins:IsA("BasePart") then
            Ins.Transparency = 1
            Ins.CanCollide = false
        elseif Ins:IsA("FaceInstance") then
            Ins.Transparency = 1
        elseif Ins:IsA("RopeConstraint") then
            Ins.Enabled = false
            Ins.Visible = false
        elseif Ins:IsA("GuiObject") then
            Ins.Visible = false
        elseif Ins:IsA("Sound") then
            Ins:Stop()
        elseif Ins:IsA("LayerCollector") then
            Ins.Enabled = false
        elseif Ins:IsA("Light") then
            Ins.Enabled = true
        end
    end

    for _, Ins in pairs({...}) do
        HideFunction(Ins)

        for _, Des in pairs(Ins:GetDescendants()) do
            HideFunction(Des)
        end
    end
end

local function FakeClone(Ins)
    local Cl = Ins:Clone()

    for _, Des in pairs(Cl:GetDescendants()) do
        Cache[Des] = Des
    end

    Cache[Cl] = Cl
    Cl.Parent = Regen

    Hide(Ins)

    return Cl
end

local function Zuck(Ins)
    local BP = Instance.new("BodyPosition")
    BP.D = 4
    BP.MaxForce = Vector3.new(100000000, 100000000, 100000000)
    BP.P = 100
    BP.Position = Vector3.new(-793.796, 655.87, 48.806)
    BP.Parent = Ins
    Ins.CanCollide = false
    Ins.Anchored = false
end

local function InhaleTheSuck(Tree)
    local NewTree = FakeClone(Tree)

    for _, Des in pairs(NewTree:GetDescendants()) do
        if Des:IsA("BasePart") then
            Zuck(Des)
        end
    end
end

local function PlayerCollector(What)
    for _, Ins in pairs(What) do
        if Ins ~= nil then
            if Ins.Parent then
                if Ins.Parent:FindFirstChild("Humanoid") then
                    if Players:GetPlayerFromCharacter(Ins.Parent) then
                        local Player = Players:GetPlayerFromCharacter(Ins.Parent)

                        if Hooked[Player] == nil then
                            Hooked[Player] = Player

                            if Player.Character:FindFirstChild("Humanoid") then
                                if Player.Character:FindFirstChild("Humanoid").Health > 0 then
                                    for _, Child in pairs(Player.Character:GetChildren()) do
                                        if Child:IsA("BasePart") and Child.Name ~= "Head" then
                                            Child.CanCollide = false
                                        end
                                    end

                                    local BP = Instance.new("BodyPosition")
                                    CleanUp[BP] = BP
                                    BP.D = 4
                                    BP.P = 200
                                    BP.Position = Vector3.new(-793.796, 655.87, 48.806)
                                    BP.Parent = Player.Character.HumanoidRootPart
                                    BP.MaxForce = Vector3.new(12500, 12500, 12500)
                                    wait(2)
                                    BP.MaxForce = Vector3.new(15000, 15000, 15000)
                                    wait(2)
                                    BP.MaxForce = Vector3.new(17500, 17500, 17500)
                                    wait(2)
                                    BP.MaxForce = Vector3.new(20000, 20000, 20000)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function module:NSDHole()
    Hole.Emit.Enabled = true
    Hole.Sound.MaxDistance = 100000
    Workspace.DMR.RCR_Break.Break:Play()

    local DMRArea = Region3.new(DMR.Position - (DMR.Size/2), DMR.Position + (DMR.Size/2))
    Connections.DMR = RunService.Stepped:Connect(function()
        PlayerCollector(Workspace:FindPartsInRegion3(DMRArea, nil, math.huge))
    end)

    local ControlArea = Region3.new(Control.Position - (Control.Size/2), Control.Position + (Control.Size/2))
    Connections.Control = RunService.Stepped:Connect(function()
        PlayerCollector(Workspace:FindPartsInRegion3(ControlArea, nil, math.huge))
    end)

    local RegionArea = Region3.new(Region.Position - (Region.Size/2), Region.Position + (Region.Size/2))

    Connections.Step = RunService.Stepped:Connect(function()
        for _, Ins in pairs(Workspace:FindPartsInRegion3(RegionArea, nil, math.huge)) do
            if Ins ~= NSDHole or Ins ~= Hole or Ins ~= Nuke or Ins ~= Region then
                if Cache[Ins] ~= nil then
                    Ins:Destroy()
                elseif Ins.Parent:FindFirstChild("Humanoid") then
                    Ins.Parent:FindFirstChild("Humanoid").Health = 0
                end
            end
        end
    end)

    for _, Ins in pairs(CollectionService:GetTagged("Zuck")) do
        InhaleTheSuck(Ins)
    end
end

function module:EndNSD()
    Cache = {}
    Hooked = {}

    for _, Ins in pairs(CleanUp) do
        if Ins ~= nil then
            if Ins.Parent ~= nil then
                Ins:Destroy()
            end
        end
    end

    Disconnect(Connections)
end

return {
    Functions = module
}