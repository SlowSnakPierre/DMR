--[[
    "CraneCollapseToPL3"
]]

local module = {}

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local function MultiTween(Inst, Type, To, Wait, Time)
    local Table = {}; Table[Type] = To
    local Info = TweenInfo.new(Time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local Tween = TweenService:Create(Inst, Info, Table); Tween:Play()
    if Wait then task.wait(Time) end; return Tween
end

local function TweenModel(model, to, Wait, time)
    local CFrameValue = Instance.new("CFrameValue"); CFrameValue.Value = model:GetPrimaryPartCFrame()

    CFrameValue:GetPropertyChangedSignal("Value"):connect(function()
        model:SetPrimaryPartCFrame(CFrameValue.Value)
    end)

    local info = TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(CFrameValue, info, { Value = to }); tween:Play()
    if Wait then task.wait(time) end; return tween
end

local function TweenModel2(model, to, Wait, time)
    local CFrameValue = Instance.new("CFrameValue"); CFrameValue.Value = model:GetPrimaryPartCFrame()

    CFrameValue:GetPropertyChangedSignal("Value"):connect(function()
        model:SetPrimaryPartCFrame(CFrameValue.Value)
    end)

    local info = TweenInfo.new(time, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
    local tween = TweenService:Create(CFrameValue, info, { Value = to }); tween:Play()
    if Wait then task.wait(time) end; return tween
end

function module:Run()
    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Sound.Boom:Play()
    MultiTween(Workspace.DMR.ReactorCore.MainStabalizer.Blue3, "Transparency", 0.8, false, 0.6)
    TweenModel(Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane, Workspace.DMR.Destruction.DMRCrane.DMRCrane.Pos1B.CFrame, false, 1)

    task.wait(.5)

    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Crane.SCenter.HingeConstraint.TargetAngle=-40
    MultiTween(Workspace.DMR.ReactorCore.MainStabalizer.Blue3, "Transparency", 0.5, true, 0.6)
    MultiTween(Workspace.DMR.ReactorCore.MainStabalizer.Blue3, "Transparency", 1, false, 0.4)

    task.wait(.5)

    TweenModel(Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane, Workspace.DMR.Destruction.DMRCrane.DMRCrane.Pos2B.CFrame, false, 2)

    task.wait(1)

    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Crane.SCenter.HingeConstraint.TargetAngle=10

    task.wait(1)

    TweenModel(Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane, Workspace.DMR.Destruction.DMRCrane.DMRCrane.Pos3B.CFrame, false, 3)
    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Crane.SCenter.HingeConstraint.TargetAngle=30
    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Sound.Sound:Play()

    task.wait(2)

    for _, v in pairs(Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model:GetChildren()) do
        if v:IsA("BasePart") then
            if v.Name == "SteamCrack" then
                v.crack.Transparency = 0
            end

            if v.Name == "LightPart" then
                MultiTween(v, "Color", Color3.new(0,0,0), false, 0.2)
                v.SpotLight.Enabled = false
            end

            if v.Name == "StructureBreach" then
                v.bom.Enabled = true
                v.steam:Play()
                task.delay(0.2, function()
                    v.bom.Enabled = false
                    v.Effect.Enabled = true
                end)
            end
        end
    end

    Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model.Explosion.Sound:Play()
    Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model.BentPL.BentCollision.ParticleEmitter.Enabled = true
    Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model.BentPL.BentCollision.debrisfx.Enabled = true

    task.delay(0.6, function()
        Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model.BentPL.BentCollision.ParticleEmitter.Enabled = false
        Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model.BentPL.BentCollision.debrisfx.Enabled = false
    end)

    TweenModel2(Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model, Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.TGP2.CFrame, false, 0.5)
    TweenModel2(Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model.BentPL, Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model.BentPL.Destructions.Pos.CFrame, false, 0.5)
    TweenModel2(Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model.BentPL.Model, Workspace.DMR.ReactorCore.Power_Lasers.PL3.Model.Model.BentPL.Model.Destructions.Pos.CFrame, false, 0.5)

    game:GetService("TweenService"):Create(Workspace.DMR.ReactorControlInterfaces.Monitors.PowerBoard.PowerLaser3, TweenInfo.new(2), {Color = Color3.fromRGB(190, 104, 98)}):Play()

    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Crane.SCenter.HingeConstraint.TargetAngle=7.5
    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Sound.Blam:Play()
    TweenModel(Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top, Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Pos1.CFrame, false, .8)

    task.wait(.4)

    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Crane.SCenter.HingeConstraint.TargetAngle=0

    task.wait(.5)

    TweenModel2(Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure, Workspace.DMR.Destruction.DMRCrane.DMRCrane.Pos4.CFrame, false, 7)
    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Crane.SCenter.HingeConstraint.TargetAngle=40

    task.wait(3)

    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Crane.SCenter.HingeConstraint.TargetAngle=-120

    task.wait(3)

    Workspace.DMR.Destruction.DMRCrane.DMRCrane.Crane.Structure.Top.Sound.Boom:Stop()
end

return {
    Functions = module
}