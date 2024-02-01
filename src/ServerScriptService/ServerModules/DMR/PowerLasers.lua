local module = {}
local Core = shared.Core
local SignalProvider = Core.Get("SignalProvider")
module.PowerLasers = SignalProvider:Get("PowerLaserFunctions")

local IsGlobal = true
local LaserLevel = 2

local LaserLevels = {
	[1] = 2,
	[2] = 2,
	[3] = 2,
	[4] = 2,
	[5] = 2,
	[6] = 2,
}

local LaserParts = {
	[1] = "Blue1",
	[2] = "Blue2",
	[3] = "Blue3",
	[4] = "Blue4",
	[5] = "Blue5",
	[6] = "Blue6",
}

local LaserTrans = {
	[0] = 0.8,
	[1] = 0.6,
	[2] = 0.4,
	[3] = 0.2,
	[4] = 0,
}

local ScreenVals = {}

local GlobalScreenVal = 100

local TweenService = game:GetService("TweenService")

local Globals = Core.Get("Global")
local Network = Core.Get("Network")
local Wrap = Core.Get("Wrap", true)

local Controls = game:GetService("Workspace").DMR.ReactorControlInterfaces
local LaserControls = Controls.PowerLasers
local Monitors = Controls.Monitors
local Reactor = game:GetService("Workspace").DMR.ReactorCore
local Stabilizers = Reactor.MainStabalizer

local Connections = {}

--#region Functions
local Functions = {}

function Functions:ChangeGlobalLevel(Level)
    for i = 1, 6 do
        local ls = "Blue" .. i
        Globals:MultiTween(Stabilizers[ls], "Transparency", LaserTrans[Level], false, 1)
    end

    local gl = "Global" .. Level
    LaserControls[gl].Light.BrickColor = BrickColor.new("Bright red")

    for _, v in pairs(Controls.PowerLasers:GetChildren()) do
        if v:FindFirstChild("Button") then
            if v.Name ~= gl then
                v.Light.BrickColor = BrickColor.new("Black")
            end
        end
    end
    Functions:UpdateGlobalPercentage(Level)
    LaserLevel = Level
end

function Functions:ChangeIndividualLevel(Laser, Level, TweenMonitor)
    local ls = "Blue" .. Laser
    Globals:MultiTween(Stabilizers[ls], "Transparency", LaserTrans[Level], false, 1)
    LaserLevels[Laser] = Level
    if TweenMonitor == true then
        Functions:UpdatePercentage(Laser, Level)
        task.wait(1)
    else
        Functions:InstantPercentUpdate(Laser, Level)
    end
end

function Functions:DramaticStartup()
    for _, Value in pairs(LaserParts) do
        Globals:MultiTween(Stabilizers[Value], "Transparency", 0, false, 10)
    end
    Reactor.Core.Core.Sound:Play()
    Globals:MultiTween(Reactor.Core.Core.Sound, "PlaybackSpeed", 1.1, true, 10)
end

function Functions:InstaStart()
    for _, Value in pairs(LaserParts) do
        Globals:MultiTween(Stabilizers[Value], "Transparency", 0, false, 1)
    end
    Reactor.Core.Core.Sound.PlaybackSpeed = 1
    task.wait(1)
    Functions:ChangeGlobalLevel(2)
end

function Functions:EnableControls()
    Controls.PLModeSwitch.Indicator.BrickColor = BrickColor.new("Bright red")
    Controls.PLModeSwitch.WaitInd.Light.BrickColor = BrickColor.new("Bright yellow")
    for _, v in pairs(Controls.PowerLasers:GetChildren()) do
        if v:FindFirstChild("Button") then
            v.Button.Center.ClickDetector.MaxActivationDistance = 32
        end
        if v:FindFirstChild("Screen") then
            v.Screen.SurfaceGui.Offline.Visible = false
            v.Screen.SurfaceGui.Disabled.Visible = true
        end
    end
    Controls.PLModeSwitch.WaitInd.Light.BrickColor = BrickColor.new("Black")
    Controls.PLModeSwitch.ReadyInd.Light.BrickColor = BrickColor.new("Lime green")
    Controls.PLModeSwitch.Buttons.Right.Part.ClickDetector.MaxActivationDistance = 32

    Functions:ChangeGlobalLevel(LaserLevel)
end

function Functions:DisableControls()
    Controls.PLModeSwitch.Buttons.Right.Part.ClickDetector.MaxActivationDistance = 0
    Controls.PLModeSwitch.Buttons.Left.Part.ClickDetector.MaxActivationDistance = 0
    Controls.PLModeSwitch.Indicator.BrickColor = BrickColor.new("Bright red")
    for _, v in pairs(Controls.PowerLasers:GetChildren()) do
        if v:FindFirstChild("Button") then
            v.Button.Center.ClickDetector.MaxActivationDistance = 0
        end
        if v:FindFirstChild("Screen") then
            v.Screen.SurfaceGui.Offline.Visible = true
            v.Screen.SurfaceGui.Disabled.Visible = false
        end
    end
end

function Functions:MeltdownDisable()
    Controls.PLModeSwitch.Buttons.Right.Part.ClickDetector.MaxActivationDistance = 0
    Controls.PLModeSwitch.Buttons.Left.Part.ClickDetector.MaxActivationDistance = 0
    Controls.PLModeSwitch.Indicator.BrickColor = BrickColor.new("Bright red")
    for _, v in pairs(Controls.PowerLasers:GetChildren()) do
        if v:FindFirstChild("Button") then
            v.Button.Center.ClickDetector.MaxActivationDistance = 0
        end
    end
end

function Functions:UpdateGlobalPercentage(Level)
    if Level == 0 then
        Globals:MultiTween(Reactor.Core.Core.Sound, "PlaybackSpeed", 0.7, false, 0.75)
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 0 }):Play()
    end
    if Level == 1 then
        Globals:MultiTween(Reactor.Core.Core.Sound, "PlaybackSpeed", 0.8, false, 0.75)
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 25 }):Play()
    end
    if Level == 2 then
        Globals:MultiTween(Reactor.Core.Core.Sound, "PlaybackSpeed", 0.9, false, 0.75)
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 50 }):Play()
    end
    if Level == 3 then
        Globals:MultiTween(Reactor.Core.Core.Sound, "PlaybackSpeed", 1, false, 0.75)
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 75 }):Play()
    end
    if Level == 4 then
        Globals:MultiTween(Reactor.Core.Core.Sound, "PlaybackSpeed", 1.1, false, 0.75)
        TweenService:Create(GlobalScreenVal, TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 100 }):Play()
    end
end

function Functions:UpdatePercentage(Laser, Level)
    if Level == 0 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 0 }):Play()
    end
    if Level == 1 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 25 }):Play()
    end
    if Level == 2 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 50 }):Play()
    end
    if Level == 3 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 75 }):Play()
    end
    if Level == 4 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0.75, Enum.EasingStyle.Linear), { Value = 100 }):Play()
    end
end

function Functions:InstantPercentUpdate(Laser, Level)
    if Level == 0 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0, Enum.EasingStyle.Linear), { Value = 0 }):Play()
    end
    if Level == 1 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0, Enum.EasingStyle.Linear), { Value = 25 }):Play()
    end
    if Level == 2 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0, Enum.EasingStyle.Linear), { Value = 50 }):Play()
    end
    if Level == 3 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0, Enum.EasingStyle.Linear), { Value = 75 }):Play()
    end
    if Level == 4 then
        TweenService:Create(ScreenVals[Laser], TweenInfo.new(0, Enum.EasingStyle.Linear), { Value = 100 }):Play()
    end
end

function Functions:ReturnGlobalLevel()
    return LaserLevel
end

function Functions:ReturnIndividualLevel(Laser)
    return LaserLevels[Laser]
end

function Functions:ReturnCurrentMode()
    return IsGlobal
end
--#endregion

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

    IsGlobal = true
    LaserLevel = 2

    LaserLevels = {
        [1] = 2,
        [2] = 2,
        [3] = 2,
        [4] = 2,
        [5] = 2,
        [6] = 2,
    }

    LaserParts = {
        [1] = "Blue1",
        [2] = "Blue2",
        [3] = "Blue3",
        [4] = "Blue4",
        [5] = "Blue5",
        [6] = "Blue6",
    }

    LaserTrans = {
        [0] = 0.8,
        [1] = 0.6,
        [2] = 0.4,
        [3] = 0.2,
        [4] = 0,
    }

    ScreenVals = {}

    GlobalScreenVal = 100

	for i = 1, 6 do
		local val = Instance.new("IntValue")
		val.Value = 100

		Connections["VALLASERSCREEN" .. i] = val.Changed:Connect(function(v)
			LaserControls["LaserScreen" .. i].Screen.SurfaceGui.Online.ValueText.Text = v .. "%"
			LaserControls["LaserScreen" .. i].Screen.SurfaceGui.Online.Output.Text = "ROD INPUT: " .. (100 - v) .. "%"
			Monitors.PowerLaser.Screen.Separate["LaserLevel" .. i].Text = v .. "%"
		end)

		ScreenVals[i] = val
	end

	local val = Instance.new("IntValue")
	val.Value = 100

	Connections.GlobalChanged = val.Changed:Connect(function(v)
		Monitors.PowerLaser.Screen.Global.Intensity.Text = v .. "%"
	end)

	GlobalScreenVal = val

	local gbdb = true

	for i = 0, 4 do
		local gl = "Global" .. i
		Connections[gl] = LaserControls[gl].Button.Center.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
			if gbdb then
				gbdb = false

				LaserControls[gl].Button.Center.Sound:Play()
				Globals:MultiTween(LaserControls[gl].Button.Center, "CFrame", LaserControls[gl].TGP.CFrame, true, 0.2)

                task.wait(0.2)

                Functions:ChangeGlobalLevel(i)

                Network:SignalAll("ConsolePrint", "Power lasers set to " .. i .. " by " .. Player.Name)
				Globals:InfoOutput("PL", "GLOBAL LEVEL SET TO " .. i)
				Globals:MultiTween(LaserControls[gl].Button.Center, "CFrame", LaserControls[gl].Org.CFrame, true, 0.2)

                task.wait(2)

                gbdb = true
			end
		end))
	end

	for i = 1, 6 do
		local ls = "LaserScreen" .. i
		local lldb = true

		Connections[ls] = LaserControls[ls].Up.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
			if lldb then
				lldb = false
				LaserControls[ls].Screen.Sound:Play()

                if LaserLevels[i] >= 0 and LaserLevels[i] < 4 then
					Globals:MultiTween(Reactor.Core.Core.Sound, "PlaybackSpeed", Reactor.Core.Core.Sound.PlaybackSpeed + 0.015, false, 0.75)
					Functions:ChangeIndividualLevel(i, LaserLevels[i] + 1, true)
					Network:SignalAll("ConsolePrint", "Power laser " .. i .. " level set to " .. LaserLevels[i] .. " by" .. Player.Name)
					Globals:InfoOutput("PL", "LASER #" .. i .. " LEVEL SET TO " .. LaserLevels[i])
				end

                lldb = true
			end
		end))

		Connections[ls .. "DOWN"] = LaserControls[ls].Down.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
			if lldb then
				lldb = false
				LaserControls[ls].Screen.Sound:Play()

                if LaserLevels[i] > 0 and LaserLevels[i] <= 4 then
					Globals:MultiTween(Reactor.Core.Core.Sound, "PlaybackSpeed", Reactor.Core.Core.Sound.PlaybackSpeed - 0.015, false, 0.75)
					Functions:ChangeIndividualLevel(i, LaserLevels[i] - 1, true)
					Network:SignalAll("ConsolePrint", "Power laser " .. i .. " level set to " .. LaserLevels[i] .. " by " .. Player.Name)
					Globals:InfoOutput("PL", "LASER #" .. i .. " LEVEL SET TO " .. LaserLevels[i])
				end

                lldb = true
			end
		end))
	end

	Connections.Left = Controls.PLModeSwitch.Buttons.Left.Part.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
		if IsGlobal == false then
			IsGlobal = true

            Network:SignalAll("ConsolePrint", "Power laser control mode switched to global by " .. Player.Name)

            Controls.PLModeSwitch.Buttons.Left.Part.ClickDetector.MaxActivationDistance = 0
			Controls.PLModeSwitch.Buttons.Right.Part.ClickDetector.MaxActivationDistance = 0
			Controls.PLModeSwitch.ReadyInd.Light.BrickColor = BrickColor.new("Black")
			Controls.PLModeSwitch.WaitInd.Light.BrickColor = BrickColor.new("Bright yellow")

            Globals:InfoOutput("PL", "MODE SWITCHED TO GLOBAL")

            Controls.PLModeSwitch.Indicator.BrickColor = BrickColor.new("Bright red")
			Monitors.PowerLaser.Screen.Global.Visible = true
			Monitors.PowerLaser.Screen.Separate.Visible = false

            Functions:ChangeGlobalLevel(LaserLevel)

            for _, v in pairs(Controls.PowerLasers:GetChildren()) do
				if v:FindFirstChild("Button") then
					v.Button.Center.ClickDetector.MaxActivationDistance = 32
				end

                if v:FindFirstChild("Screen") then
					v.Down.ClickDetector.MaxActivationDistance = 0
					v.Up.ClickDetector.MaxActivationDistance = 0
					v.Screen.SurfaceGui.Disabled.Visible = true
					v.Screen.SurfaceGui.Online.Visible = false
				end
			end

            task.wait(30)

            Controls.PLModeSwitch.WaitInd.Light.BrickColor = BrickColor.new("Black")
			Controls.PLModeSwitch.ReadyInd.Light.BrickColor = BrickColor.new("Lime green")
			Controls.PLModeSwitch.Buttons.Right.Part.ClickDetector.MaxActivationDistance = 32
		end
	end))

	Connections.Right = Controls.PLModeSwitch.Buttons.Right.Part.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
		if IsGlobal == true then
			IsGlobal = false

            Network:SignalAll("ConsolePrint", "Power laser control mode switched to manual by " .. Player.Name)

            Controls.PLModeSwitch.Buttons.Left.Part.ClickDetector.MaxActivationDistance = 0
			Controls.PLModeSwitch.Buttons.Right.Part.ClickDetector.MaxActivationDistance = 0
			Controls.PLModeSwitch.ReadyInd.Light.BrickColor = BrickColor.new("Black")
			Controls.PLModeSwitch.WaitInd.Light.BrickColor = BrickColor.new("Bright yellow")

            Globals:InfoOutput("PL", "MODE SWITCHED TO SEPARATE")

            Controls.PLModeSwitch.Indicator.BrickColor = BrickColor.new("Lapis")
			Monitors.PowerLaser.Screen.Global.Visible = false
			Monitors.PowerLaser.Screen.Separate.Visible = true

            for i = 1, 6 do
				Functions:ChangeIndividualLevel(i, LaserLevel, false)
			end

            for _, v in pairs(Controls.PowerLasers:GetChildren()) do
				if v:FindFirstChild("Screen") then
					v.Down.ClickDetector.MaxActivationDistance = 32
					v.Up.ClickDetector.MaxActivationDistance = 32
					v.Screen.SurfaceGui.Disabled.Visible = false
					v.Screen.SurfaceGui.Online.Visible = true
				end

                if v:FindFirstChild("Button") then
					v.Button.Center.ClickDetector.MaxActivationDistance = 0
				end
			end

            task.wait(30)

            Controls.PLModeSwitch.WaitInd.Light.BrickColor = BrickColor.new("Black")
			Controls.PLModeSwitch.ReadyInd.Light.BrickColor = BrickColor.new("Lime green")
			Controls.PLModeSwitch.Buttons.Left.Part.ClickDetector.MaxActivationDistance = 32
		end
	end))
    
    module.PowerLasers:Connect(function(Function, ...)
		if Functions[Function] then
			return Functions[Function](unpack({ ... }))
		end
    end)
end

return module
