--[[
    "StartupFunction"
]]

local module = {}
local Core = shared.Core

local RanObj = Random.new(6969)

local BootDebounce = false
local CanTurn = true
local Key = false
local StartupType = "Default"
local Calibration = ((RanObj:NextInteger(1, 2) - 1) * 8) + 1
local Calibrated = false

local FCLocks = {
    [1] = false,
    [2] = false,
    [3] = false,
}

local Fdwtr = {
    [1] = false,
    [2] = false,
    [3] = false,
    [4] = false,
    [5] = false,
    [6] = false,
}

local startCalibrated = true
local DebugMode = false

local TweenService = game:GetService("TweenService")
local IsStudio = game:GetService("RunService"):IsStudio()

local Modules = script.Parent
local Audios = workspace.Audios
local Controls = workspace.DMR.ReactorControlInterfaces
local Monitors = Controls.Monitors
local Reactor = workspace.DMR.ReactorCore
local ReactorCore = Reactor.Core

local Wrap = Core.Get("Wrap")
local Network = Core.Get("Network")
local Global = Core.Get("Global")
local CFMS = Core.Get("CFMS")
local Energy = Core.Get("CoolEffectsScript")

local PowerLasers = Core.Get("PowerLasers", true)
local Thermals = Core.Get("Thermals", true)
local Coolant = Core.Get("Coolant", true)

local Connections = {}

--#region Functions
local Functions = {}

function Functions:endMusic()
    task.wait(20)
    TweenService:Create(Global.FindAudio("Startup"), TweenInfo.new(15), { Volume = 0 }):Play()

    task.wait(15)
    Global.FindAudio("Startup"):Stop()
end

function Functions:dmrStartup()
    CanTurn = false
    if StartupType == "Default" then
        Network:SignalAll("Notification", "Dark Matter Reactor ignition sequence initiated.", "none", 5)
        Audios.HumanAnnouncements.Announcements.Disabled = false
        Controls.ShutdownPanel.Shutdown.OfflineNotice.TextLabel.Text = "PENDING REACTOR IGNITION SEQUENCE COMPLETION..."

        for _, v in pairs(Monitors:GetChildren()) do
            v.OfflineNotice.TextLabel.Text = "PENDING REACTOR IGNITION SEQUENCE COMPLETION..."
        end

        Global.FindAudio("Ignition_Initialized"):Play()
        task.wait(Global.FindAudio("Ignition_Initialized").TimeLength + 2)
        Global.FindAudio("Powerlaser"):Play()

        Global.FindAudio("Startup"):Play()

        for i = 1, 3 do
            TweenService:Create(Reactor.MainStabalizer["Red" .. i], TweenInfo.new(9), { Transparency = 0 }):Play()
        end

        for i = 1, 2 do
            TweenService:Create(Monitors.PowerBoard["GravityLaser" .. i], TweenInfo.new(9), { Color = Color3.fromRGB(131, 229, 95) }):Play()
        end

        task.wait(9)

        Global.FindAudio("Gravity_Laser_online"):Play()

        task.wait(Global.FindAudio("Gravity_Laser_online").TimeLength)

        Global.FindAudio("Raising_Core"):Play()
        Global.TweenModel(ReactorCore, Reactor.CoreRaised.CFrame, true, 15)

        --StartCodex:Fire()

        Global.FindAudio("DMR_Raised"):Play()

        task.wait(6)
    end

    if StartupType ~= "Default" then
        Network:SignalAll("Notification", "Dark Matter Reactor re-ignition sequence initiated.", "none", 5)
        Audios.HumanAnnouncements.Announcements.Disabled = false

        Controls.ShutdownPanel.Shutdown.OfflineNotice.TextLabel.Text = "PENDING REACTOR RE-IGNITION SEQUENCE COMPLETION..."

        for _, v in pairs(Monitors:GetChildren()) do
            v.OfflineNotice.TextLabel.Text = "PENDING REACTOR RE-IGNITION SEQUENCE COMPLETION..."
        end
    end

    Global.FindAudio("Activate_Lasers"):Play()

    task.wait(3)

    Global.FindAudio("Opening_valves"):Play()
    Global.FindAudio("InitPower"):Play()

    Network:SignalAll("Shake", math.random(50, 75), 10)

    TweenService:Create(Modules.Thermals:WaitForChild("Radiation"), TweenInfo.new(10), { Value = RanObj:NextInteger(600, 700) }):Play()

    for i = 1, 6 do
        TweenService:Create(Monitors.PowerBoard["PowerLaser" .. i], TweenInfo.new(10), { Color = Color3.fromRGB(131, 229, 95) }):Play()
    end

    ReactorCore.Core.Sound:Play()
    PowerLasers.Functions:DramaticStartup()

    task.wait(1)

    local Ran = 1

    if StartupType ~= "Maintenance" then
        Ran = RanObj:NextInteger(1, 5)
    else
        Ran = 1
    end

    if Ran == 2 then
        CFMS.AlarmsOperations(0)
        Global.FindAudio("outage"):Play()

        TweenService:Create(Modules.Thermals:WaitForChild("Radiation"), TweenInfo.new(9), { Value = 0 }):Play()
        TweenService:Create(Global.FindAudio("Startup"), TweenInfo.new(9), { PlaybackSpeed = 0 }):Play()
        TweenService:Create(ReactorCore.Core.Sound, TweenInfo.new(9), { PlaybackSpeed = 0 }):Play()

        Controls.ShutdownPanel.Shutdown.OfflineNotice.Enabled = false
        Controls.ShutdownPanel.Shutdown.Screen.Enabled = false
        for _, monitor in pairs(Controls.Monitors:GetChildren()) do
            monitor.OfflineNotice.Enabled = false
            monitor.Screen.Enabled = false
        end

        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "SPart" then
                v.Sound:Stop()
            end
        end

        for i = 1, 6 do
            TweenService:Create(Monitors.PowerBoard["PowerLaser" .. i], TweenInfo.new(9), { Color = Color3.fromRGB(213, 115, 61) }):Play()
            TweenService:Create(Reactor.MainStabalizer["Blue" .. i], TweenInfo.new(9), { Transparency = 1 }):Play()
        end

        task.spawn(function()
            Energy.Off()
        end)

        task.wait(6)

        task.wait(RanObj:NextInteger(10, 16))

        Controls.ShutdownPanel.Shutdown.OfflineNotice.Enabled = true

        for _, monitor in pairs(Controls.Monitors:GetChildren()) do
            monitor.OfflineNotice.Enabled = true
        end

        Network:SignalAll("Notification", "Unknown error- DMR Ignition sequence failure.", "none", 4)
        Controls.ShutdownPanel.Shutdown.OfflineNotice.TextLabel.Text = "POWER INSTABILITY DETECTED; IGNITION FAILURE"

        for _, v in pairs(Controls.Monitors:GetChildren()) do
            v.OfflineNotice.TextLabel.Text = "POWER INSTABILITY DETECTED; IGNITION FAILURE"
        end

        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "SPart" then
                v.Sound:Play()
            end
        end

        task.spawn(function()
            Energy.On()
        end)

        task.wait(8)

        Network:SignalAll("Notification", "DMR Startup parameters undergoing reconfiguration.", "none", 6)
        Controls.ShutdownPanel.Shutdown.OfflineNotice.TextLabel.Text = "RECONFIGURATING STARTUP PARAMETERS; PLEASE WAIT..."

        for _, v in pairs(Controls.Monitors:GetChildren()) do
            v.OfflineNotice.TextLabel.Text = "RECONFIGURATING STARTUP PARAMETERS; PLEASE WAIT..."
        end

        Global.FindAudio("Startup"):Stop()
        Global.FindAudio("Startup").PlaybackSpeed = 1

        task.wait(8)

        Network:SignalAll("Notification", "DMR Startup parameters successfully reconfigured; ready for startup.", "none", 8)
        Controls.ShutdownPanel.Shutdown.OfflineNotice.TextLabel.Text = "DMR READY FOR RE-IGNITION"

        for _, v in pairs(Controls.Monitors:GetChildren()) do
            v.OfflineNotice.TextLabel.Text = "DMR READY FOR RE-IGNITION"
        end

        if Thermals.Functions:ReturnFuel() >= 10 then
            Thermals.Functions:FuelDebug(Thermals.Functions:ReturnFuel() - 10)
        end

        Controls.Start.Key.Sound:Play()
        Global.TweenModel(Controls.Start.KeyM.KeyM, Controls.Start.KeyM.Org.CFrame, false, 0.5)
        TweenService:Create(Controls.Start.Lock_Ind, TweenInfo.new(0.5), { Color = Color3.fromRGB(27, 42, 53) }):Play()
        Controls.Start.Key.ClickDetector.MaxActivationDistance = 16

        CanTurn = true
        Key = false
        StartupType = "Restart"

        task.wait(1)
        BootDebounce = false
    else
        task.wait(2)

        Network:SignalAll("Notification", "Successful DMR Ignition. Switching to manual control...", "none", 7)
        Global.FindAudio("Power_lasers_online"):Play()

        task.wait(Global.FindAudio("Power_lasers_online").TimeLength)

        Network:SignalAll("CompleteChallenge", "DMRSTARTUP")

        task.wait(1)

        Monitors.PowerBoard.ClickToView.LightStart:Play()
        Controls.Monitors.PowerBoard.ClickToView.LightStart:Play()

        for _, c in pairs(Controls.Monitors.PowerBoard.PowerBoardLights.BlinkyLights:GetChildren()) do
            c.Material = "Neon"
        end

        for _, c in pairs(Controls.Monitors.PowerBoard.PowerBoardLights.OtherLights:GetChildren()) do
            c.Material = "Neon"
        end

        task.wait(1.5)

        for _, c in pairs(Controls.Monitors.PowerBoard.PowerBoardLights.BlinkyLights:GetChildren()) do
            c.Material = "SmoothPlastic"
        end

        for _, c in pairs(Controls.Monitors.PowerBoard.PowerBoardLights.OtherLights:GetChildren()) do
            c.Material = "SmoothPlastic"
        end

        task.wait(1.5)

        if StartupType == "Default" or StartupType == "Restart" then
            Global.FindAudio("DMR_Online"):Play()
        elseif StartupType == "Maintenance" then
            Global.FindAudio("DMR Resuming normal operations"):Play()
        end

        Audios.HumanAnnouncements.Announcements.Disabled = false
        CFMS.AlarmsOperations(0)

        for _, thing in pairs(workspace.DMR.ReactorControlInterfaces.Monitors:GetChildren()) do
            if thing.Name == "Output" then
                thing.Screen.Main.FiveArea.Text = ""
                thing.Screen.Main.Five.Text = ""
                thing.Screen.Main.FourArea.Text = ""
                thing.Screen.Main.Four.Text = ""
                thing.Screen.Main.ThreeArea.Text = ""
                thing.Screen.Main.Three.Text = ""
                thing.Screen.Main.TwoArea.Text = ""
                thing.Screen.Main.Two.Text = ""
                thing.Screen.Main.OneArea.Text = ""
                thing.Screen.Main.One.Text = ""
            end
        end

        Controls.ShutdownPanel.Shutdown.OfflineNotice.Enabled = false
        Controls.ShutdownPanel.Shutdown.Screen.Enabled = true

        for _, monitor in pairs(Controls.Monitors:GetChildren()) do
            monitor.OfflineNotice.Enabled = false
            monitor.Screen.Enabled = true
        end

        if StartupType == "Default" then
            Global.InfoOutput("CORE", "DARK MATTER REACTOR NOW ONLINE")
            Network:SignalAll("Notification", "Dark Matter Reactor ignition sequence completed, reactor core online.", "none", 5)
        elseif StartupType == "Maintenance" then
            Global.InfoOutput("CORE", "DARK MATTER REACTOR RESUMING OPERATIONS")
            Network:SignalAll("Notification", "Dark Matter Reactor re-ignition sequence completed, reactor core online.", "none", 5)
        end

        task.spawn(function()
            Functions.endMusic()
        end)

        PowerLasers.Functions:EnableControls()
        Coolant.Functions:EnableControls()
        Thermals.Functions:EnableControls()
        Thermals.Functions:BeginThermalLoop()
    end
end

function Functions:Instastart()
    BootDebounce = true
    CanTurn = false
    Calibrated = true

    ReactorCore.Core.Sound:Play()

    for i = 1, 3 do
        Reactor.MainStabalizer["Red" .. i].Transparency = 0
        Global.SwitchToggle(Controls.FuelLocks["Switch" .. i], "On")
        Controls.FuelLocks["Switch" .. i].Center.ClickDetector.MaxActivationDistance = 0
        FCLocks[i] = true
    end

    Global.TweenModel(ReactorCore, Reactor.CoreRaised.CFrame, false, 5)

    --StartCodex:Fire()

    PowerLasers.Functions:InstaStart()

    for i = 1, 2 do
        Monitors.PowerBoard["GravityLaser" .. i].Color = Color3.fromRGB(131, 229, 95)
    end

    task.wait(1)

    Controls.PLCalibration.PowerLaserCalib.Screen.Frame.Bar.Meter:TweenPosition(UDim2.new(0.55, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 1)

    for i = 1, 6 do
        Global.TweenModel(Reactor.Power_Lasers["PL" .. i].Model.Model, Reactor.Power_Lasers["PL" .. i].Model.Calibration.TGP5.CFrame, false, 1)
        Monitors.PowerBoard["PowerLaser" .. i].Color = Color3.fromRGB(131, 229, 95)
        Controls.FeedwaterSwitches["Switch" .. i].Center.ClickDetector.MaxActivationDistance = 0
        Global.SwitchToggle(Controls.FeedwaterSwitches["Switch" .. i], "On")
        Fdwtr[i] = true
    end

    for _, thing in pairs(workspace.DMR.ReactorControlInterfaces.Monitors:GetChildren()) do
        if thing.Name == "Output" then
            thing.Screen.Main.FiveArea.Text = ""
            thing.Screen.Main.Five.Text = ""
            thing.Screen.Main.FourArea.Text = ""
            thing.Screen.Main.Four.Text = ""
            thing.Screen.Main.ThreeArea.Text = ""
            thing.Screen.Main.Three.Text = ""
            thing.Screen.Main.TwoArea.Text = ""
            thing.Screen.Main.Two.Text = ""
            thing.Screen.Main.OneArea.Text = ""
            thing.Screen.Main.One.Text = ""
        end
    end

    Controls.ShutdownPanel.Shutdown.OfflineNotice.Enabled = false
    Controls.ShutdownPanel.Shutdown.Screen.Enabled = true

    for _, monitor in pairs(Controls.Monitors:GetChildren()) do
        monitor.OfflineNotice.Enabled = false
        monitor.Screen.Enabled = true
    end

    Global.InfoOutput("CORE", "DARK MATTER REACTOR NOW ONLINE")

    PowerLasers.Functions:EnableControls()
    Coolant.Functions:EnableControls()
    Thermals.Functions:EnableControls()
    Thermals.Functions:BeginThermalLoop()
end

function Functions:Variable(Index, Key)
    --RETURNTABLE[Index] = Key
end
--#endregion

local PrimerKey = function(plr)
	if not BootDebounce then
		if CanTurn then
			if not Key then
				BootDebounce = true
				Key = true

				Controls.Start.Key.Sound:Play()
				Global.TweenModel(Controls.Start.KeyM.KeyM, Controls.Start.KeyM.ToGo.CFrame, false, 0.5)
				TweenService:Create(Controls.Start.Lock_Ind, TweenInfo.new(0.5), { Color = Color3.fromRGB(213, 115, 61) }):Play()

				task.wait(1)

				TweenService:Create(Controls.Start.Main_Power_Button, TweenInfo.new(1), { Color = Color3.fromRGB(196, 40, 28) }):Play()
				CFMS.AlarmsOperations(1)
				Controls.Start.Main_Power_Button.ClickDetector.MaxActivationDistance = 16

                task.wait(1)

                BootDebounce = false
			else
				BootDebounce = true
				Key = false

				Controls.Start.Key.Sound:Play()
				Global.TweenModel(Controls.Start.KeyM.KeyM, Controls.Start.KeyM.Org.CFrame, false, 0.5)

				task.wait(1)

                TweenService:Create(Controls.Start.Lock_Ind, TweenInfo.new(0.5), { Color = Color3.fromRGB(27, 42, 53) }):Play()
				TweenService:Create(Controls.Start.Main_Power_Button, TweenInfo.new(1), { Color = Color3.fromRGB(126, 25, 17) }):Play()
				CFMS.AlarmsOperations(0)
				Controls.Start.Main_Power_Button.ClickDetector.MaxActivationDistance = 0

                task.wait(1)

				BootDebounce = false
			end
		end
	end
end

local MainButton = function(plr)
	if not BootDebounce then
		if Key then
			if FCLocks[1] == true and FCLocks[2] == true and FCLocks[3] == true then
				if Fdwtr[1] == true and Fdwtr[2] == true and Fdwtr[3] == true and Fdwtr[4] == true and Fdwtr[5] == true and Fdwtr[6] == true then
					if Calibrated then
						BootDebounce = true

						Network:SignalAll("ConsolePrint", "Reactor startup initialized by " .. plr.Name)

						Controls.Start.Main_Power_Button.ClickDetector.MaxActivationDistance = 0
						Controls.Start.Key.ClickDetector.MaxActivationDistance = 0
						Controls.Start.Main_Power_Button.Sound:Play()

						TweenService:Create(Controls.Start.Main_Power_Button, TweenInfo.new(1), { Color = Color3.fromRGB(126, 25, 17) }):Play()
						TweenService:Create(Controls.Start.Main_Power_Button, TweenInfo.new(0.2), { ["CFrame"] = Controls.Start.ToGo.CFrame }):Play()

						task.wait(0.2)

						TweenService:Create(Controls.Start.Main_Power_Button, TweenInfo.new(0.2), { ["CFrame"] = Controls.Start.Org.CFrame }):Play()
						Functions.dmrStartup()
					else
						Network:Signal("Notification", plr, "Calibrate the PowerLasers on the left side of this desk to engage startup.", "error", 6)
					end
				else
					Network:Signal("Notification", plr, "Enable the Feedwater Pumps on the Power Control Desk (left to this desk) to engage startup.", "error", 7.5)
				end
			else
				Network:Signal("Notification", plr, "Enable the Fuel Cell Locks on the left side of this desk to engage startup.", "error", 6)
			end
		end
	else
		Network:Signal("Notification", plr, "Please task.wait.", "error", 6)
	end
end

local function FuelLock(plr, i)
	if not FCLocks[i] then
		Network:SignalAll("ConsolePrint", "Fuel Cell lock " .. i .. " engaged by " .. plr.Name)
		Global.SwitchToggle(Controls.FuelLocks["Switch" .. i], "On")
		Controls.FuelLocks["Switch" .. i].Center.Sound:Play()
		Controls.FuelLocks["Switch" .. i].Center.ClickDetector.MaxActivationDistance = 0
		FCLocks[i] = true
	end
end

local function FeedWtr(plr, i)
	if not Fdwtr[i] then
		Network:SignalAll("ConsolePrint", "Feedwater Pump " .. i .. " engaged by " .. plr.Name)
		Global.SwitchToggle(Controls.FeedwaterSwitches["Switch" .. i], "On")
		Controls.FeedwaterSwitches["Switch" .. i].Center.Sound:Play()
		Controls.FeedwaterSwitches["Switch" .. i].Center.ClickDetector.MaxActivationDistance = 0
		Fdwtr[i] = true
	end
end

local function CalLeft(plr)
	if not BootDebounce then
		if Calibration >= 2 then
			BootDebounce = true
			Calibration = Calibration - 1

			Controls.PLCalibration.Left.Button.Center.Sound:Play()
			Global.TweenModel(Controls.PLCalibration.Left.Button, Controls.PLCalibration.Left.TGP.CFrame, true, 0.15)
			Global.TweenModel(Controls.PLCalibration.Left.Button, Controls.PLCalibration.Left.Org.CFrame, true, 0.15)

			Controls.PLCalibration.PowerLaserCalib.Screen.Frame.Bar.Meter:TweenPosition(UDim2.new(((Calibration / 10) + 0.05), 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 6)

			for i = 1, 6 do
				Reactor.Power_Lasers["PL" .. i].Model.Model.Explosion.Move:Play()
				Global.TweenModel(Reactor.Power_Lasers["PL" .. i].Model.Model, Reactor.Power_Lasers["PL" .. i].Model.Calibration["TGP" .. Calibration].CFrame, false, 6)
			end

			task.wait(6)

			if Calibration == 5 then
				Calibrated = true
				Controls.PLCalibration.NC.Light.Material = Enum.Material.SmoothPlastic
				Controls.PLCalibration.NC.Light.BrickColor = BrickColor.new("Really black")
				Controls.PLCalibration.C.Light.Material = Enum.Material.Neon
				Controls.PLCalibration.C.Light.Color = Color3.fromRGB(131, 229, 95)
			else
				Calibrated = false
				Controls.PLCalibration.NC.Light.Material = Enum.Material.Neon
				Controls.PLCalibration.NC.Light.BrickColor = BrickColor.new("Bright red")
				Controls.PLCalibration.C.Light.Material = Enum.Material.SmoothPlastic
				Controls.PLCalibration.C.Light.BrickColor = BrickColor.new("Really black")
			end

			task.wait(1)

			BootDebounce = false
		end
	end
end

local function CalRight(plr)
	if not BootDebounce then
		if Calibration <= 8 then
			BootDebounce = true
			Calibration = Calibration + 1
			Controls.PLCalibration.Right.Button.Center.Sound:Play()
			Global.TweenModel(Controls.PLCalibration.Right.Button, Controls.PLCalibration.Right.TGP.CFrame, true, 0.15)
			Global.TweenModel(Controls.PLCalibration.Right.Button, Controls.PLCalibration.Right.Org.CFrame, true, 0.15)

			Controls.PLCalibration.PowerLaserCalib.Screen.Frame.Bar.Meter:TweenPosition(UDim2.new(((Calibration / 10) + 0.05), 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 6)

			for i = 1, 6 do
				Reactor.Power_Lasers["PL" .. i].Model.Model.Explosion.Move:Play()
				Global.TweenModel(Reactor.Power_Lasers["PL" .. i].Model.Model, Reactor.Power_Lasers["PL" .. i].Model.Calibration["TGP" .. Calibration].CFrame, false, 6)
			end

			task.wait(6)

			if Calibration == 5 then
				Calibrated = true
				Controls.PLCalibration.NC.Light.Material = Enum.Material.SmoothPlastic
				Controls.PLCalibration.NC.Light.BrickColor = BrickColor.new("Really black")
				Controls.PLCalibration.C.Light.Material = Enum.Material.Neon
				Controls.PLCalibration.C.Light.Color = Color3.fromRGB(131, 229, 95)
			else
				Calibrated = false
				Controls.PLCalibration.NC.Light.Material = Enum.Material.Neon
				Controls.PLCalibration.NC.Light.BrickColor = BrickColor.new("Bright red")
				Controls.PLCalibration.C.Light.Material = Enum.Material.SmoothPlastic
				Controls.PLCalibration.C.Light.BrickColor = BrickColor.new("Really black")
			end

			task.wait(1)

			BootDebounce = false
		end
	end
end

local Disconnect = function(...)
	local DisconnectFunction = function(What)
		if type(What) == "table" then
			for _, Signal in pairs(What) do
				Signal:Disconnect()
			end
		else
			What:Disconnect()
		end
	end

	for _, Value in pairs({ ... }) do
		DisconnectFunction(Value)
	end
end

function module:Init()
	Disconnect(Connections)

    BootDebounce = false
    CanTurn = true
    Key = false
    StartupType = "Default"
    Calibration = ((RanObj:NextInteger(1, 2) - 1) * 8) + 1
    Calibrated = false

    FCLocks = {
        [1] = false,
        [2] = false,
        [3] = false,
    }

    Fdwtr = {
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = false,
        [5] = false,
        [6] = false,
    }

	for i = 1, 6 do
		Global.TweenModel(Reactor.Power_Lasers["PL" .. i].Model.Model, Reactor.Power_Lasers["PL" .. i].Model.Calibration["TGP" .. Calibration].CFrame, false, 1)
	end

	Controls.PLCalibration.PowerLaserCalib.Screen.Frame.Bar.Meter:TweenPosition(UDim2.new(((Calibration / 10) + 0.05), 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 6)

	task.wait(2)

	if startCalibrated then
		if IsStudio then
			for i = 1, 6 do
				Global.TweenModel(Reactor.Power_Lasers["PL" .. i].Model.Model, Reactor.Power_Lasers["PL" .. i].Model.Calibration.TGP5.CFrame, false, 1)
			end

			Controls.PLCalibration.PowerLaserCalib.Screen.Frame.Bar.Meter:TweenPosition(UDim2.new(0.55, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 1)

			Calibrated = true
		end
	end

	if DebugMode == true then
		if IsStudio then
			task.spawn(function()
				Functions.Instastart()
			end)
		end
	end

	for i = 1, 3 do
		Connections["FuelL" .. i] = Controls.FuelLocks["Switch" .. i].Center.ClickDetector.MouseClick:Connect(Wrap:Make(function(plr)
            FuelLock(plr, i)
        end))
	end

    for i = 1, 6 do
		Connections["FdWater" .. i] = Controls.FeedwaterSwitches["Switch" .. i].Center.ClickDetector.MouseClick:Connect(Wrap:Make(function(plr)
            FeedWtr(plr, i)
        end))
	end

    Connections.MButton = Controls.Start.Main_Power_Button.ClickDetector.MouseClick:Connect(Wrap:Make(function(plr)
		MainButton(plr)
	end))

    Connections.PrimeKey = Controls.Start.Key.ClickDetector.MouseClick:Connect(Wrap:Make(function(plr)
		PrimerKey(plr)
	end))

    Connections.PLCLeft = Controls.PLCalibration.Left.Button.Center.ClickDetector.MouseClick:Connect(Wrap:Make(function(plr)
		CalLeft(plr)
	end))

	Connections.PLCRight = Controls.PLCalibration.Right.Button.Center.ClickDetector.MouseClick:Connect(Wrap:Make(function(plr)
        CalRight(plr)
    end))
end

module.Functions = Functions

return module