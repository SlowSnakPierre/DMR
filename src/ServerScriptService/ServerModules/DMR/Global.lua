local Functions = {}

local TweenService = game:GetService("TweenService")
local Core = shared.Core
local Network = Core.Get("Network")
local TweenNet = Core.Get("Tween")

function Functions:MultiTween(Inst, Type, To, Wait, Time)
    local Table = {}
    Table[Type] = To

    local Tween = TweenService:Create(Inst, TweenInfo.new(Time, Enum.EasingStyle.Linear), Table)
    Tween:Play()

    if Wait then
        task.wait(Time)
    end

    return Tween
end

function Functions:BaseTween(Inst, Value, To, Time, Wait, Style, Direction)
    Network:SignalAll("TweenIns", Inst, Value, To, Time, Style, Direction)

    if Wait then
        task.wait(Time)
    end
end

function Functions:TweenModel(Model, To, Wait, Time, ...)
    local EasingStyle, EasingDirection

    if (... and (typeof(...) == "table")) then
        EasingStyle, EasingDirection = unpack(...)
    else
        EasingStyle, EasingDirection = Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
    end

    local Data = { Style = EasingStyle, Direction = EasingDirection }

    TweenNet:Tween(Model, To, Time, Data)

    if Wait then
        task.wait(Time)
    end
end

function Functions:TweenModelBounceOut(Model, To, Wait, Time)
    Functions:TweenModel(Model, To, Wait, Time, {Enum.EasingStyle.Bounce, Enum.EasingDirection.Out})
end

function Functions:TweenModelLinearIn(Model, To, Wait, Time)
    Functions:TweenModel(Model, To, Wait, Time, {Enum.EasingStyle.Linear, Enum.EasingDirection.In})
end

function Functions:TweenModelInOnly(Model, To, Wait, Time)
    Functions:TweenModel(Model, To, Wait, Time, {Enum.EasingStyle.Sine, Enum.EasingDirection.In})
end

function Functions:TweenModelOutOnly(Model, To, Wait, Time)
    Functions:TweenModel(Model, To, Wait, Time, {Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
end

function Functions:InfoOutput(Area, Input)
    for k,v in pairs(game.Workspace:WaitForChild("DMR"):WaitForChild("ReactorControlInterfaces"):WaitForChild("Monitors"):GetChildren()) do
        if v.Name == "Output" then
            v.Screen.Main.FiveArea.Text = v.Screen.Main.FourArea.Text
            v.Screen.Main.Five.Text = v.Screen.Main.Four.Text
            v.Screen.Main.FourArea.Text = v.Screen.Main.ThreeArea.Text
            v.Screen.Main.Four.Text = v.Screen.Main.Three.Text
            v.Screen.Main.ThreeArea.Text = v.Screen.Main.TwoArea.Text
            v.Screen.Main.Three.Text = v.Screen.Main.Two.Text
            v.Screen.Main.TwoArea.Text = v.Screen.Main.OneArea.Text
            v.Screen.Main.Two.Text = v.Screen.Main.One.Text
            v.Screen.Main.OneArea.Text = Area
            v.Screen.Main.One.Text = Input
        end
    end
end

function Functions:FindAudio(Name)
	local Audios = {}

	for _, Descendant in pairs(game.Workspace.Audios:GetDescendants()) do
		if Descendant.ClassName == "Sound" then
            Audios[Descendant.Name] = Descendant
        end
	end

	if Audios[Name] then
        return Audios[Name]
    end

	warn("Audio not Found: "..Name)

	return Instance.new("Sound")
end

function Functions:SwitchToggle(switch, option)
    if option == "On" then
        Functions:MultiTween(switch.Second, "Color", BrickColor.new("Bright green").Color, false, 0.25)
        Functions:MultiTween(switch.First, "Color", BrickColor.new("Really black").Color, false, 0.25)
        Functions:MultiTween(switch.Center, "CFrame", switch.ToGo.CFrame, true, 0.05)
    elseif option == "Off" then
        Functions:MultiTween(switch.Second, "Color", BrickColor.new("Really black").Color, false, 0.25)
        Functions:MultiTween(switch.First, "Color", BrickColor.new("Bright red").Color, false, 0.25)
        Functions:MultiTween(switch.Center, "CFrame", switch.Org.CFrame, true, 0.05)
    end
end

function Functions:Shaker(intensity, timeToStart, length, timeToEnd, waitForEnd)
    if intensity == nil then
        intensity = 150
    end

    if timeToStart == nil then
        timeToStart = 0.5
    end

    if length == nil then
        length = 2
    end

    if timeToEnd == nil then
        timeToEnd = 4
    end

    if waitForEnd == nil then
        waitForEnd = false
    end

    task.wait(length)

    if waitForEnd then
        task.wait(timeToEnd)
    end
end

function Functions:ChangeSetting(object, property, tweenTime, setval, Wait)
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    TweenService:Create(object, tweenInfo, {[property] = setval}):Play()

    if Wait then
        task.wait(tweenTime + 0.1)
    end
end

return Functions