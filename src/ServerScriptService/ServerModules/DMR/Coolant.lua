local module = {}
local Core = shared.Core
local Global = Core.Get("Global")
local Wrap = Core.Get("Wrap", true)
local Network = Core.Get("Network")
local SignalProvider = Core.Get("SignalProvider")
module.Coolant = SignalProvider:Get("CoolantFunctions")

local TweenService = game:GetService("TweenService")
local DMR = game:GetService("Workspace"):WaitForChild("DMR")

local Controls = DMR:WaitForChild("ReactorControlInterfaces")
local CoolantControls = Controls:WaitForChild("Coolant")
local Monitors = Controls:WaitForChild("Monitors")
local Reactor = DMR:WaitForChild("ReactorCore")

local Connections = {}

local ValveSwitches = {
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false,
}

local CoolantLevel = 0
local ValvesOn = 0
local PumpsOn = 0

local PumpActive = {
	[1] = false,
	[2] = false,
}

local pump1db = false
local pump2db = false

local GlobalScreenVal = 100

local inletdb = {
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false,
}

local bdb = true
local val

local function Disconnect(...)
    local function DisconnectFunction(What)
        if type(What) == "table" then
            for Index, Signal in pairs(What) do
                if Signal then
                    Signal:Disconnect()
                end
            end
        else
            What:Disconnect()
        end
    end

    for Index, Value in pairs({...}) do
        DisconnectFunction(Value)
    end
end

--#region Functions
local Functions = {}

function Functions:ChangeCoolantLevel(level)
    local gl = "Button"..level
    CoolantControls:WaitForChild(gl):WaitForChild("Light").BrickColor = BrickColor.new("Bright red")

    for k,v in pairs(CoolantControls:GetChildren()) do
        if v:FindFirstChild("Button") then
            if v.Name ~= gl then
                v:WaitForChild("Light").BrickColor = BrickColor.new("Black")
            end
        end
    end

    Functions:UpdateGlobalPercentage(level)
    Global:InfoOutput("COOLANT", "PUMP LEVEL SET TO "..level)
    CoolantLevel = level
end

function Functions:UpdateValveSwitch(switch)
    if ValveSwitches[switch] == false then
        Global:SwitchToggle(Controls:WaitForChild("CoolantCirc"..switch), "On")
        Global:SwitchToggle(Controls:WaitForChild("CoolantInletValve"..switch), "On")
        ValveSwitches[switch] = true
        ValvesOn = ValvesOn + 1
    elseif ValveSwitches[switch] == true then
        Global:SwitchToggle(Controls:WaitForChild("CoolantCirc"..switch), "Off")
        Global:SwitchToggle(Controls:WaitForChild("CoolantInletValve"..switch), "Off")
        ValveSwitches[switch] = false
        ValvesOn = ValvesOn - 1
        if ValvesOn == 0 then
            Functions:ChangeCoolantLevel(0)
        end
    end
end

function Functions:UpdateGlobalPercentage(level)
    if level == 0 then
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), {Value = 0}):Play()
    elseif level == 1 then
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), {Value = 25}):Play()
    elseif level == 2 then
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), {Value = 50}):Play()
    elseif level == 3 then
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), {Value = 75}):Play()
    elseif level == 4 then
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), {Value = 100}):Play()
    end
end

function Functions:EnableControls()
    for k,v in pairs(CoolantControls:GetChildren()) do
        if v:FindFirstChild("Button") then
            v:WaitForChild("Button"):WaitForChild("Center"):WaitForChild("ClickDetector").MaxActivationDistance = 32
        end
    end
    for k = 1, 4 do
        local cc = "CoolantInletValve"..k
        Controls:WaitForChild(cc):WaitForChild("Center"):WaitForChild("ClickDetector").MaxActivationDistance = 32
    end
    Global:SwitchToggle(Controls:WaitForChild("PMotorSwitch1"), "On")
    Global:SwitchToggle(Controls:WaitForChild("PMotorSwitch2"), "On")
    Controls:WaitForChild("PMotorSwitch1"):WaitForChild("Center"):WaitForChild("ClickDetector").MaxActivationDistance = 32
    Controls:WaitForChild("PMotorSwitch2"):WaitForChild("Center"):WaitForChild("ClickDetector").MaxActivationDistance = 32
    Controls:WaitForChild("Pump1"):WaitForChild("Noise"):WaitForChild("Running"):Play()
    Controls:WaitForChild("Pump2"):WaitForChild("Noise"):WaitForChild("Running"):Play()
    Monitors:WaitForChild("PowerBoard"):WaitForChild("Diagram1"):WaitForChild("Monitoring"):WaitForChild("P1Status").Text = "ONLINE"
    Monitors:WaitForChild("PowerBoard"):WaitForChild("Diagram1"):WaitForChild("Monitoring"):WaitForChild("P2Status").Text = "ONLINE"
    PumpActive[1] = true
    PumpActive[2] = true
    PumpsOn = 2
    Functions:ChangeCoolantLevel(3)
end

function Functions:DisableControls()
    for k,v in pairs(CoolantControls:GetChildren()) do
        if v:FindFirstChild("Button") then
            v:WaitForChild("Button"):WaitForChild("Center"):WaitForChild("ClickDetector").MaxActivationDistance = 0
        end
    end
    for k = 1, 4 do
        local cc = "CoolantInletValve"..k
        Controls:WaitForChild(cc):WaitForChild("Center"):WaitForChild("ClickDetector").MaxActivationDistance = 0
    end
    Global:SwitchToggle(Controls:WaitForChild("PMotorSwitch1"), "Off")
    Global:SwitchToggle(Controls:WaitForChild("PMotorSwitch2"), "Off")
    Controls:WaitForChild("PMotorSwitch1"):WaitForChild("Center"):WaitForChild("ClickDetector").MaxActivationDistance = 0
    Controls:WaitForChild("PMotorSwitch2"):WaitForChild("Center"):WaitForChild("ClickDetector").MaxActivationDistance = 0
    Controls:WaitForChild("Pump1"):WaitForChild("Noise"):WaitForChild("Running"):Stop()
    Controls:WaitForChild("Pump2"):WaitForChild("Noise"):WaitForChild("Running"):Stop()
    Controls:WaitForChild("Pump1"):WaitForChild("Noise"):WaitForChild("Shutoff"):Play()
    Controls:WaitForChild("Pump2"):WaitForChild("Noise"):WaitForChild("Shutoff"):Play()
    Monitors:WaitForChild("PowerBoard"):WaitForChild("Diagram1"):WaitForChild("Monitoring"):WaitForChild("P1Status").Text = "OFFLINE"
    Monitors:WaitForChild("PowerBoard"):WaitForChild("Diagram1"):WaitForChild("Monitoring"):WaitForChild("P2Status").Text = "OFFLINE"
    PumpActive[1] = false
    PumpActive[2] = false
    PumpsOn = 0
    Functions:ChangeCoolantLevel(0)
end

function Functions:ReturnValveNumber()
    return ValvesOn
end

function Functions:ReturnPumpsActive()
    return PumpsOn
end

function Functions:ReturnCoolantLevel()
    return CoolantLevel
end
--#endregion

function module:Init()
    Disconnect(Connections)

    if val then
        val:Destroy()
    end

	ValveSwitches = {
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = false,
	}

	CoolantLevel = 0
	ValvesOn = 0
	PumpsOn = 0

	PumpActive = {
		[1] = false,
		[2] = false,
	}

	pump1db = false
	pump2db = false

	GlobalScreenVal = 100

	inletdb = {
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = false,
	}

	bdb = true

    val = Instance.new("IntValue")
    val.Value = 100
    Connections.CoolantValueChanged = val.Changed:Connect(function(v)
        Monitors:WaitForChild("Coolant"):WaitForChild("Screen"):WaitForChild("Main"):WaitForChild("Current").Text = v .. "%"
        Monitors:WaitForChild("PowerBoard"):WaitForChild("Diagram1"):WaitForChild("Monitoring"):WaitForChild("CoolantLevel").Text = v .. "%"
    end)

    GlobalScreenVal = val

    for k = 1, 4 do
        local cc = "CoolantCirc"..k
        Connections[cc] = Controls:WaitForChild(cc):WaitForChild("Center"):WaitForChild("ClickDetector").MouseClick:Connect(Wrap:Make(function(Player)
            Functions:UpdateValveSwitch(k)
            Controls[cc]:WaitForChild("Center"):WaitForChild("Sound"):Play()
            Network:SignalAll("ConsolePrint", "Coolant circulation valve ".. k .." toggled by ".. Player.Name)
        end))
    end

    for k = 1, 4 do
        local cc = "CoolantInletValve"..k
        Connections[cc] = Controls:WaitForChild(cc):WaitForChild("Center"):WaitForChild("ClickDetector").MouseClick:Connect(Wrap:Make(function(Player)
            if inletdb[k] == false then
                inletdb[k] = true
                Functions:UpdateValveSwitch(k)
                Controls:WaitForChild(cc):WaitForChild("Center"):WaitForChild("Sound"):Play()
                Network:SignalAll("ConsolePrint", "Coolant inlet valve ".. k .." toggled by ".. Player.Name)
                task.wait(2)
                inletdb[k] = false
            end
        end))
    end

    for k = 0, 4 do
        local gl = "Button"..k
        Connections[gl] = CoolantControls:WaitForChild(gl):WaitForChild("Button"):WaitForChild("Center"):WaitForChild("ClickDetector").MouseClick:Connect(Wrap:Make(function(Player)
            if bdb then
                bdb = false
                if PumpActive[1] == true or PumpActive[2] == true then
                    CoolantControls:WaitForChild(gl):WaitForChild("Button"):WaitForChild("Center"):WaitForChild("Sound"):Play()
                    Global:MultiTween(
                        CoolantControls:WaitForChild(gl):WaitForChild("Button"):WaitForChild("Center"),
                        "CFrame",
                        CoolantControls:WaitForChild(gl):WaitForChild("TGP").CFrame,
                        true,
                        0.2
                    )
                    task.wait(0.2)
                    Functions:ChangeCoolantLevel(k)
                    Global:MultiTween(
                        CoolantControls:WaitForChild(gl):WaitForChild("Button"):WaitForChild("Center"),
                        "CFrame",
                        CoolantControls:WaitForChild(gl):WaitForChild("Org").CFrame,
                        true,
                        0.2
                    )
                    Network:SignalAll("ConsolePrint", "Coolant input set to ".. k .." by ".. Player.Name)
                    task.wait(2)
                else
                    Network:Signal("Notification", Player, "Enable one or both of the Coolant Pumps to use this system.", "error", 7.5)
                    Monitors:WaitForChild("Coolant"):WaitForChild("Screen").Enabled = false
                    Monitors:WaitForChild("Coolant"):WaitForChild("Error").Enabled = true
                    Monitors:WaitForChild("Coolant"):WaitForChild("ErrorSFX"):Play()
                    task.wait(2)
                    Monitors:WaitForChild("Coolant"):WaitForChild("Screen").Enabled = true
                    Monitors:WaitForChild("Coolant"):WaitForChild("Error").Enabled = false
                end
                bdb = true
            end
        end))
    end

    Connections.PumpOne = Controls:WaitForChild("PMotorSwitch1"):WaitForChild("Center"):WaitForChild("ClickDetector").MouseClick:Connect(Wrap:Make(function(Player)
        if PumpActive[1] == false and pump1db == false then
            pump1db = true
            Network:SignalAll("ConsolePrint", "Coolant pump #1 activated by ".. Player.Name)
            Global:SwitchToggle(Controls:WaitForChild("PMotorSwitch1"), "On")
            Controls:WaitForChild("Pump1"):WaitForChild("Center"):WaitForChild("Sound"):Play()
            while Controls:WaitForChild("Pump1"):WaitForChild("Noise"):WaitForChild("Startup").IsPlaying == true do
                Controls:WaitForChild("Pump1"):WaitForChild("Light1").Material = Enum.Material.Neon
                Controls:WaitForChild("Pump1"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = true
                Controls:WaitForChild("Pump1"):WaitForChild("Light2").Material = Enum.Material.Neon
                Controls:WaitForChild("Pump1"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = true
                task.wait(1)
                Controls:WaitForChild("Pump1"):WaitForChild("Light1").Material = Enum.Material.Plastic
                Controls:WaitForChild("Pump1"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = false
                Controls:WaitForChild("Pump1"):WaitForChild("Light2").Material = Enum.Material.Plastic
                Controls:WaitForChild("Pump1"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = false
                task.wait(1)
            end
            Controls:WaitForChild("Pump1"):WaitForChild("Light1").Material = Enum.Material.Plastic
            Controls:WaitForChild("Pump1"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = false
            Controls:WaitForChild("Pump1"):WaitForChild("Light2").Material = Enum.Material.Plastic
            Controls:WaitForChild("Pump1"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = false
            Controls:WaitForChild("Pump1"):WaitForChild("Noise"):WaitForChild("Running"):Play()
            Monitors:WaitForChild("PowerBoard"):WaitForChild("Diagram1"):WaitForChild("Monitoring"):WaitForChild("P1Status").Text = "ONLINE"
            Global:InfoOutput("COOLANT", "PUMP #1 NOW ACTIVE")
            Monitors:WaitForChild("Coolant"):WaitForChild("Screen"):WaitForChild("Main"):WaitForChild("P1Status").Text = "TRUE"
            Monitors:WaitForChild("Coolant"):WaitForChild("Screen"):WaitForChild("Main"):WaitForChild("RateOne").Text = "38 L/S"
            PumpActive[1] = true
            PumpsOn = PumpsOn + 1
            pump1db = false
        elseif PumpActive[1] == true and pump1db == false then
            pump1db = true
            Network:SignalAll("ConsolePrint", "Coolant pump #1 desactivated by ".. Player.Name)
            Global:SwitchToggle(Controls:WaitForChild("PMotorSwitch1"), "Off")
            Controls:WaitForChild("Pump1"):WaitForChild("Noise"):WaitForChild("Running"):Stop()
            Controls:WaitForChild("Pump1"):WaitForChild("Noise"):WaitForChild("Shutoff"):Play()
            while Controls:WaitForChild("Pump1"):WaitForChild("Noise"):WaitForChild("Shutoff").IsPlaying == true do
                Controls:WaitForChild("Pump1"):WaitForChild("Light1").Material = Enum.Material.Neon
                Controls:WaitForChild("Pump1"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = true
                Controls:WaitForChild("Pump1"):WaitForChild("Light2").Material = Enum.Material.Neon
                Controls:WaitForChild("Pump1"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = true
                task.wait(1)
                Controls:WaitForChild("Pump1"):WaitForChild("Light1").Material = Enum.Material.Plastic
                Controls:WaitForChild("Pump1"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = false
                Controls:WaitForChild("Pump1"):WaitForChild("Light2").Material = Enum.Material.Plastic
                Controls:WaitForChild("Pump1"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = false
                task.wait(1)
            end
            Controls:WaitForChild("Pump1"):WaitForChild("Light1").Material = Enum.Material.Plastic
            Controls:WaitForChild("Pump1"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = false
            Controls:WaitForChild("Pump1"):WaitForChild("Light2").Material = Enum.Material.Plastic
            Controls:WaitForChild("Pump1"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = false
            Controls:WaitForChild("Pump1"):WaitForChild("Noise"):WaitForChild("Running"):Play()
            Monitors:WaitForChild("PowerBoard"):WaitForChild("Diagram1"):WaitForChild("Monitoring"):WaitForChild("P1Status").Text = "OFFLINE"
            Global:InfoOutput("COOLANT", "PUMP #1 NOW INACTIVE")
            Monitors:WaitForChild("Coolant"):WaitForChild("Screen"):WaitForChild("Main"):WaitForChild("P1Status").Text = "FALSE"
            Monitors:WaitForChild("Coolant"):WaitForChild("Screen"):WaitForChild("Main"):WaitForChild("RateOne").Text = "0 L/S"
            PumpActive[1] = false
            PumpsOn = PumpsOn - 1
            pump1db = false
        end
    end))

    Connections.PumpTwo = Controls:WaitForChild("PMotorSwitch2"):WaitForChild("Center"):WaitForChild("ClickDetector").MouseClick:Connect(Wrap:Make(function(Player)
        if PumpActive[2] == false and pump2db == false then
            pump2db = true
            Network:SignalAll("ConsolePrint", "Coolant pump #2 activated by ".. Player.Name)
            Global:SwitchToggle(Controls:WaitForChild("PMotorSwitch2"), "On")
            Controls:WaitForChild("Pump2"):WaitForChild("Center"):WaitForChild("Sound"):Play()
            while Controls:WaitForChild("Pump2"):WaitForChild("Noise"):WaitForChild("Startup").IsPlaying == true do
                Controls:WaitForChild("Pump2"):WaitForChild("Light1").Material = Enum.Material.Neon
                Controls:WaitForChild("Pump2"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = true
                Controls:WaitForChild("Pump2"):WaitForChild("Light2").Material = Enum.Material.Neon
                Controls:WaitForChild("Pump2"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = true
                task.wait(1)
                Controls:WaitForChild("Pump2"):WaitForChild("Light1").Material = Enum.Material.Plastic
                Controls:WaitForChild("Pump2"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = false
                Controls:WaitForChild("Pump2"):WaitForChild("Light2").Material = Enum.Material.Plastic
                Controls:WaitForChild("Pump2"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = false
                task.wait(1)
            end
            Controls:WaitForChild("Pump2"):WaitForChild("Light1").Material = Enum.Material.Plastic
            Controls:WaitForChild("Pump2"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = false
            Controls:WaitForChild("Pump2"):WaitForChild("Light2").Material = Enum.Material.Plastic
            Controls:WaitForChild("Pump2"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = false
            Controls:WaitForChild("Pump2"):WaitForChild("Noise"):WaitForChild("Running"):Play()
            Monitors:WaitForChild("PowerBoard"):WaitForChild("Diagram1"):WaitForChild("Monitoring"):WaitForChild("P2Status").Text = "ONLINE"
            Global:InfoOutput("COOLANT", "PUMP #2 NOW ACTIVE")
            Monitors:WaitForChild("Coolant"):WaitForChild("Screen"):WaitForChild("Main"):WaitForChild("P2Status").Text = "TRUE"
            Monitors:WaitForChild("Coolant"):WaitForChild("Screen"):WaitForChild("Main"):WaitForChild("RateTwo").Text = "38 L/S"
            PumpActive[2] = true
            PumpsOn = PumpsOn + 1
            pump2db = false
        elseif PumpActive[2] == true and pump2db == false then
            pump2db = true
            Network:SignalAll("ConsolePrint", "Coolant pump #2 desactivated by ".. Player.Name)
            Global:SwitchToggle(Controls:WaitForChild("PMotorSwitch2"), "Off")
            Controls:WaitForChild("Pump2"):WaitForChild("Noise"):WaitForChild("Running"):Stop()
            Controls:WaitForChild("Pump2"):WaitForChild("Noise"):WaitForChild("Shutoff"):Play()
            while Controls:WaitForChild("Pump2"):WaitForChild("Noise"):WaitForChild("Shutoff").IsPlaying == true do
                Controls:WaitForChild("Pump2"):WaitForChild("Light1").Material = Enum.Material.Neon
                Controls:WaitForChild("Pump2"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = true
                Controls:WaitForChild("Pump2"):WaitForChild("Light2").Material = Enum.Material.Neon
                Controls:WaitForChild("Pump2"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = true
                task.wait(1)
                Controls:WaitForChild("Pump2"):WaitForChild("Light1").Material = Enum.Material.Plastic
                Controls:WaitForChild("Pump2"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = false
                Controls:WaitForChild("Pump2"):WaitForChild("Light2").Material = Enum.Material.Plastic
                Controls:WaitForChild("Pump2"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = false
                task.wait(1)
            end
            Controls:WaitForChild("Pump2"):WaitForChild("Light1").Material = Enum.Material.Plastic
            Controls:WaitForChild("Pump2"):WaitForChild("Light1"):WaitForChild("PointLight").Enabled = false
            Controls:WaitForChild("Pump2"):WaitForChild("Light2").Material = Enum.Material.Plastic
            Controls:WaitForChild("Pump2"):WaitForChild("Light2"):WaitForChild("PointLight").Enabled = false
            Controls:WaitForChild("Pump2"):WaitForChild("Noise"):WaitForChild("Running"):Play()
            Monitors:WaitForChild("PowerBoard"):WaitForChild("Diagram1"):WaitForChild("Monitoring"):WaitForChild("P2Status").Text = "OFFLINE"
            Global:InfoOutput("COOLANT", "PUMP #2 NOW INACTIVE")
            Monitors:WaitForChild("Coolant"):WaitForChild("Screen"):WaitForChild("Main"):WaitForChild("P2Status").Text = "FALSE"
            Monitors:WaitForChild("Coolant"):WaitForChild("Screen"):WaitForChild("Main"):WaitForChild("RateTwo").Text = "0 L/S"
            PumpActive[2] = false
            PumpsOn = PumpsOn - 1
            pump2db = false
        end
    end))
    
    module.Coolant:Connect(function(Function, ...)
		if Functions[Function] then
			return Functions[Function](unpack({ ... }))
		end
    end)
end

return module