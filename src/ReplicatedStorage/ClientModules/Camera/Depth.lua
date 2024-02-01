local module = {
    ID = nil,
    Current = nil,
    Active = false
}

local Core = shared.Core
local Network = Core.Get("Network")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local UI = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("CameraHint"):Clone()

local CFrameC = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("CFrameCam"):Clone()
module.CFrameC = CFrameC

local Camera = Workspace.CurrentCamera
module.Camera = Camera

local Cache = {}
local OldCframe = nil

local function IsPart(Ins)
    local run, err = pcall(function()
        local Test = Ins.ClassName
    end)

    if err == nil then
        return true
    else
        return false
    end
end

local function Hide(...)
	Cache = {}

	local function HideFunction(Ins)
		if Ins:IsA("BasePart") then
			Cache[Ins] = {["Transparency"] = Ins.Transparency,["CanCollide"] = Ins.CanCollide}
			Ins.Transparency = 1
			Ins.CanCollide = false
		elseif Ins:IsA("FaceInstance") then
			Cache[Ins] = {["Transparency"] = Ins.Transparency}
			Ins.Transparency = 1
		elseif Ins:IsA("RopeConstraint") then
			Cache[Ins] = {["Enabled"] = Ins.Enabled,["Visible"] = Ins.Visible}
			Ins.Enabled = false
			Ins.Visible = false
		elseif Ins:IsA("GuiObject") then
			Cache[Ins] = {["Visible"] = Ins.Visible}
			Ins.Visible = false
		elseif Ins:IsA("LayerCollector") then
			Cache[Ins] = {["Enabled"] = Ins.Enabled}
			Ins.Enabled = false
		elseif Ins:IsA("Light") then
			Cache[Ins] = {["Enabled"] = Ins.Enabled}
			Ins.Enabled = true
		end
	end

	for Index, Ins in pairs({...}) do
		HideFunction(Ins)

		for Index, Des in pairs(Ins:GetDescendants()) do
			HideFunction(Des)
		end
	end
end

local function UnHide()
	for Ins, Table in pairs(Cache) do
		if Ins ~= nil then
			for Property, Value in pairs(Table) do
				Ins[Property] = Value
			end
		end
	end

	Cache = {}
end

function module:TweenCamera(Settings)
    OldCframe = module.Camera.CFrame

    local Time = Settings.Time
    local CamCFrame = module.CFrameC:Clone()

    module.REvent = Player.Character.Humanoid.Died:Connect(function()
        module:Reset(Settings)
    end)

    if Settings.Local == true then
        Player.Character.HumanoidRootPart.Anchored = true
    else
        module:Send("Freeze")
    end

    StarterGui:SetCoreGuiEnabled("All", false)
    StarterGui:SetCore("ResetButtonCallback", false)

    Hide(Player.Character)

    CamCFrame.Parent = Workspace

    if type(Settings.From) == "string" then
        CamCFrame.CFrame = Player.Character:WaitForChild("Head").CFrame
    else
        if IsPart(Settings.From) == true then
            CamCFrame.CFrame = Settings.From.CFrame
        else
            CamCFrame.CFrame = Settings.From
        end
    end

    if IsPart(Settings.ToFrame) == true then
        Settings.ToFrame = Settings.ToFrame.CFrame
    end

    module.TweenInfo.Part = CamCFrame
    module.TweenInfo.ToCFrame = Settings.ToFrame
    module.TweenInfo.Time = Time
    
    module.Thread.Create("Camera_Tween", function()
        module:Tween()
    end)

    module.Thread.Start("Camera_Tween")

    if Settings.Override == true and Settings.Reset == true then
        task.wait(Settings.WaitTime or Time + 3)

        module:Reset(Settings)
    elseif Settings.Override == false then
        module.Current = UI:Clone()
        module.Current.Parent = Player.PlayerGui

        module.Event = UserInputService.InputBegan:Connect(function(Input)
            module.TweenInfo.Stop()
            module:Reset(Settings)
        end)
    elseif Settings.Reset == false then
        module:Send("Finish")
    end
end

function module:Reset(Settings)
    if module.TweenInfo.Stop ~= nil then
        module.TweenInfo.Stop()
    end

    task.wait()

    module.Camera.CameraSubject = Player.Character.Humanoid
    module.Camera.CameraType = Enum.CameraType.Custom

    UnHide(Player.Character)

    if Settings.Local == true then
        Player.Character.HumanoidRootPart.Anchored = false
    else
        module:Send("Resume")
        module:Send("Finish")
    end

    module.TweenInfo = {Stop = nil, Part = nil, ToCFrame = nil, Time = nil}
    module.ID = nil

    if module.Current ~= nil then
        module.Current:Destroy()
        module.Current = nil
    end

    if module.Event ~= nil then
        module.Event:Disconnect()
        module.Event = nil
    end

    if module.REvent ~= nil then
        module.REvent:Disconnect()
        module.REvent = nil
    end

    StarterGui:SetCoreGuiEnabled("All", true)
    StarterGui:SetCore("ResetButtonCallback", true)

    if OldCframe ~= nil then
        module.Camera.CFrame = OldCframe
        OldCframe = nil
    end

    module.Camera.CameraSubject = Player.Character.Humanoid
    module.Camera.CameraType = Enum.CameraType.Custom

    module.Active = false
end

module.TweenInfo = {Stop = nil, Part = nil, ToCFrame = nil, Time = nil}

function module:Tween()
    local Part = module.TweenInfo.Part
    local ToCFrame = module.TweenInfo.ToCFrame
    local Time = module.TweenInfo.Time

    module.Camera.CameraType = Enum.CameraType.Scriptable
    module.Camera.CameraSubject = nil
    module.Camera.Focus = ToCFrame

    local TweenedCompleted = "N/A"
    local Info = TweenInfo.new(Time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local CFrameValue = Instance.new("CFrameValue")
    CFrameValue.Value = Part.CFrame

    CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
        Part.CFrame = CFrameValue.Value
        module.Camera.CoordinateFrame = CFrameValue.Value
    end)

    local Tween = TweenService:Create(CFrameValue, Info, { Value = ToCFrame })
    Tween:Play()

    Tween.Completed:Connect(function()
        CFrameValue:Destroy()
        TweenedCompleted = "Yes"
    end)

    module.TweenInfo.Stop = function()
        Tween:Cancel()
    end
end

function module:Send(Command)
    Network:Signal("CameraListener", module.ID, Command)
end

module.Thread = {
    Threads = {},
    Start = function(ID)
        coroutine.resume(module.Thread.Threads[ID])
    end,
    Stop = function(ID)
        coroutine.yield(module.Thread.Threads[ID])
        module.Thread.Threads[ID] = nil
    end,
    Create = function(ID, Function, ...)
        module.Thread.Threads[ID] = coroutine.create(Function)
    end
}

function module:SetActive(bool)
    module.Active = bool
end

function module:SetID(ID)
    module.ID = ID
end

function module:GetActive()
    return module.Active
end

function module:GetID()
    return module.ID
end

return module