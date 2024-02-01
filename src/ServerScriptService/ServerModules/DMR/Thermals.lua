local module = {}
local Core = shared.Core
local SignalProvider = Core.Get("SignalProvider")
module.Thermals = SignalProvider:Get("ThermalFunctions")
module.PowerLasers = SignalProvider:Get("PowerLaserFunctions")
module.Coolant = SignalProvider:Get("CoolantFunctions")
module.Meltdown = SignalProvider:Get("MeltdownFunctions")
module.Maintenance = SignalProvider:Get("MaintenanceFunctions")

local TweenService = game:GetService("TweenService")

local Controls = game:GetService("Workspace"):WaitForChild("DMR"):WaitForChild("ReactorControlInterfaces")
local Monitors = Controls.Monitors
local Reactor = game:GetService("Workspace"):WaitForChild("DMR"):WaitForChild("ReactorCore")
local ReactorCore = Reactor.Core

local CoRoutine = Core.Get("CoRoutine")

local Global = Core.Get("Global")
local Settings = Core.Get("Settings")
local CFMS = Core.Get("CFMS")
local Network = Core.Get("Network")
local Wrap = Core.Get("Wrap", true)

local RanObj = Random.new(time())

local Connections = {}

local TurbineGens = {
	[1] = Instance.new("NumberValue"),
	[2] = Instance.new("NumberValue"),
}

local TurbineValve = {
	[1] = Instance.new("NumberValue"),
	[2] = Instance.new("NumberValue"),
}

local TurbineBoolean = {
	[1] = Instance.new("BoolValue"),
	[2] = Instance.new("BoolValue"),
}

local ReliefVal = {
	[1] = Instance.new("BoolValue"),
	[2] = Instance.new("BoolValue"),
	[3] = Instance.new("BoolValue"),
	[4] = Instance.new("BoolValue"),
}

local CycleActive = false
local AlarmMute = false
local AlarmPhase = "N/A"
local IntegPhase = "N/A"
local MeltdownActive = false
local ReliefsActive = 0
local TurbineTotalOutput = 0
local fueldeb = false
local depdeb = false
local Radiation
local Temp
local Integrity

local DMR = {
	DMRTemp = 600, --//temp starting point
	DMRFuel = 60, --//average fuel starting point
	DMRInteg = 100, --//integ starting point
}

--//Fuel cell types: "Generic", "Efficient", "Reactive", & "Super"
local FuelCells = {
	[1] = "Generic",
	[2] = "Generic",
	[3] = "Generic",
}

local Fuel = {
	[1] = 60,
	[2] = 60,
	[3] = 60,
}

local ReliefPressure = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
}

local ReliefDebounce = {
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false,
}

local dtb = {
	[1] = false,
	[2] = false,
}

local function ReturnFuelCellMath(v)
	if v then
		if v == "Generic" then
			return 2
		elseif v == "Efficient" then
			return 1
		elseif v == "Reactive" then
			return 5
		elseif v == "Super" then
			return 4
		end
	end
end

local function ReturnFuelCellType(v)
	if v == "Generic" then
		return 0.2
	elseif v == "Efficient" then
		return 0.1
	elseif v == "Reactive" then
		return 0.6
	elseif v == "Super" then
		return 0.15
	end
end

--#region Functions

local Functions = {}

function Functions:PLCycle()
	for l = 0, 4 do
		if module.PowerLasers:Fire("ReturnCurrentMode") then
			if module.PowerLasers:Fire("ReturnGlobalLevel") == l then
				for z = 1, 3 do
					DMR.DMRTemp = DMR.DMRTemp
						+ (
							((tonumber(ReturnFuelCellMath(FuelCells[z])) * (l + 1)) ^ Settings.PowerLaserBuff)
							* (Fuel[z] / 100)
						)
						/ 3
				end
			end
		else
			for i = 1, 6 do
				if module.PowerLasers:Fire("ReturnIndividualLevel", i) == l then
					for z = 1, 3 do
						DMR.DMRTemp = DMR.DMRTemp
							+ (
								(((tonumber(ReturnFuelCellMath(FuelCells[z])) * (l + 1)) / 6)
									^ Settings.PowerLaserBuff
								) * (Fuel[z] / 100)
							)
							/ 3
					end
				end
			end
		end
	end
end

function Functions:FuelCycle()
	for l = 0, 4 do
		if module.PowerLasers:Fire("ReturnCurrentMode") then
			if module.PowerLasers:Fire("ReturnGlobalLevel") == l then
				for z = 1, 3 do
					Fuel[z] = Fuel[z] - ((tonumber(ReturnFuelCellType(FuelCells[z])) * (l + 1)) / Settings.FuelDepletionRate) / 3
				end
			end
		else
			for i = 1, 6 do
				if module.PowerLasers:Fire("ReturnIndividualLevel", i) == l then
					for z = 1, 3 do
						Fuel[z] = Fuel[z]
							- (
								((tonumber(ReturnFuelCellType(FuelCells[z])) * (l + 1)) / 6)
								/ Settings.FuelDepletionRate
							)
							/ 3
					end
				end
			end
		end
	end

	DMR.DMRFuel = (Fuel[1] + Fuel[2] + Fuel[3]) / 3
end

function Functions:CoolantCycle()
	for a = 1, 2 do
		if module.Coolant:Fire("ReturnPumpsActive") == a then
			for b = 1, 4 do
				if module.Coolant:Fire("ReturnValveNumber") == b then
					for c = 1, 4 do
						if module.Coolant:Fire("ReturnCoolantLevel") == c then
							DMR.DMRTemp = DMR.DMRTemp
								- (((0.225 * (tonumber(c) + 1)) * (tonumber(b) + 1)) * (tonumber(a) / 2))
									^ Settings.CoolantBuff
						end
					end
				end
			end
		end
	end
end

function Functions:ReliefCycle()
	for i = 1, 4 do
		if ReliefsActive == i then
			DMR.DMRTemp = DMR.DMRTemp - (3 ^ Settings.ReliefsBuff * i)
		end
	end
end

function Functions:IntegCycle()
	if DMR.DMRInteg > 1 then
		if DMR.DMRTemp >= 3500 and DMR.DMRTemp < 3750 then
			DMR.DMRInteg = DMR.DMRInteg - 0.5
			for i = 1, 3 do
				Fuel[i] = Fuel[i] + 0.2
			end
		elseif DMR.DMRTemp >= 3750 and DMR.DMRTemp < 4000 then
			DMR.DMRInteg = DMR.DMRInteg - 1
			for i = 1, 3 do
				Fuel[i] = Fuel[i] + 0.4
			end
		elseif DMR.DMRTemp >= 4000 and DMR.DMRTemp < 4250 then
			DMR.DMRInteg = DMR.DMRInteg - 1.5
			for i = 1, 3 do
				Fuel[i] = Fuel[i] + 0.6
			end
		elseif DMR.DMRTemp >= 4250 and DMR.DMRTemp < 4500 then
			DMR.DMRInteg = DMR.DMRInteg - 2
			for i = 1, 3 do
				Fuel[i] = Fuel[i] + 0.8
			end
		elseif DMR.DMRTemp >= 4500 and DMR.DMRTemp < 4750 then
			DMR.DMRInteg = DMR.DMRInteg - 2.5
			for i = 1, 3 do
				Fuel[i] = Fuel[i] + 1
			end
		elseif DMR.DMRTemp >= 4750 and DMR.DMRTemp < 5000 then
			DMR.DMRInteg = DMR.DMRInteg - 3
			for i = 1, 3 do
				Fuel[i] = Fuel[i] + 1.2
			end
		elseif DMR.DMRTemp >= 5000 then
			DMR.DMRInteg = DMR.DMRInteg - 3.5
			for i = 1, 3 do
				Fuel[i] = Fuel[i] + 1.4
			end
		end
	end
end

function Functions:GetRadiation()
	return Radiation
end

function Functions:TempCheck()
	if DMR.DMRTemp >= 1200 then
		if not Monitors.PowerBoard.ClickToView.AlarmArr.IsPlaying and AlarmPhase == "N/A" then
			AlarmPhase = 1
			AlarmMute = false
			Monitors.PowerBoard.ClickToView.AlarmArr.Volume = 0.25
			Monitors.PowerBoard.ClickToView.AlertBeep.Volume = 0.5
			Controls.OverheatAlarm.bell.Volume = 0.5
			Monitors.PowerBoard.ClickToView.AlarmArr:Play()
			Global:FindAudio("AlarmDaDaDa"):Play()

			task.wait(Global:FindAudio("AlarmDaDaDa").TimeLength)
			Network:SignalAll("Notification", "Dark Matter Reactor exceeding safe operating parameters.", "error", 8)
			Global:FindAudio("ExceedingSafeParamaters"):Play()
		end
		if DMR.DMRTemp >= 2250 then
			Monitors.PowerBoard.ClickToView.AlertBeep:Play()
			if AlarmPhase == 1 then
				AlarmPhase = 2
				AlarmMute = false
				Monitors.PowerBoard.ClickToView.AlarmArr.Volume = 0.25
				Monitors.PowerBoard.ClickToView.AlertBeep.Volume = 0.5
				Controls.OverheatAlarm.bell.Volume = 0.5
				Global:FindAudio("AlarmDaDaDa"):Play()

				task.wait(Global:FindAudio("AlarmDaDaDa").TimeLength)
				Network:SignalAll("Notification", "Dark Matter Reactor exceeding safe temperature limits.", "error", 8)
				Global:FindAudio("ExceedingSafeParamaters"):Stop()
				Global:FindAudio("ExceedingSafeTemperature"):Play()
			end
			if DMR.DMRTemp >= 3500 then
				if not Controls.OverheatAlarm.bell.IsPlaying and AlarmPhase == 2 then
					Controls.OverheatAlarm.bell:Play()
					AlarmPhase = 3
					AlarmMute = false
					Monitors.PowerBoard.ClickToView.AlarmArr.Volume = 0.25
					Monitors.PowerBoard.ClickToView.AlertBeep.Volume = 0.5
					Controls.OverheatAlarm.bell.Volume = 0.5
					Global:FindAudio("AlarmDaDaDa"):Play()
					CFMS.AlarmsOperations(5)

					task.wait(Global:FindAudio("AlarmDaDaDa").TimeLength)
					Network:SignalAll("Notification",
						"Dark Matter Reactor superstructure overheated. Structural integrity loss possible.",
						"error",
						10
					)
					Global:FindAudio("ExceedingSafeParamaters"):Stop()
					Global:FindAudio("ExceedingSafeTemperature"):Stop()
					Global:FindAudio("IntegDropping"):Play()
				end
			elseif DMR.DMRTemp < 3200 and AlarmPhase == 3 then
				CFMS.AlarmsOperations(0)
				Controls.OverheatAlarm.bell:Stop()
				AlarmPhase = 2
			end
		elseif DMR.DMRTemp < 2000 and AlarmPhase == 2 then
			AlarmPhase = 1
		end
	elseif DMR.DMRTemp < 1000 and AlarmPhase == 1 then
		Monitors.PowerBoard.ClickToView.AlarmArr:Stop()
		AlarmPhase = "N/A"
	end
end

function Functions:IntegCheck()
	if DMR.DMRInteg <= 75 then
		if IntegPhase == "N/A" then
			IntegPhase = 1
			AlarmMute = false
			Monitors.PowerBoard.ClickToView.AlarmArr.Volume = 0.25
			Monitors.PowerBoard.ClickToView.AlertBeep.Volume = 0.5
			Controls.OverheatAlarm.bell.Volume = 0.5
			Global:FindAudio("AlarmDaDaDa"):Play()
			CFMS.AlarmsOperations(5)

			task.wait(Global:FindAudio("AlarmDaDaDa").TimeLength)
			Network:SignalAll("Notification", "Dark Matter Reactor superstructure integrity at 75%.", "error", 10)
			Global:FindAudio("CoreInteg75"):Play()
		end
		if DMR.DMRInteg <= 50 then
			if IntegPhase == 1 then
				IntegPhase = 2
				AlarmMute = false
				Monitors.PowerBoard.ClickToView.AlarmArr.Volume = 0.25
				Monitors.PowerBoard.ClickToView.AlertBeep.Volume = 0.5
				Controls.OverheatAlarm.bell.Volume = 0.5
				Global:FindAudio("AlarmDaDaDa"):Play()
				CFMS.AlarmsOperations(5)

				task.wait(Global:FindAudio("AlarmDaDaDa").TimeLength)
				Network:SignalAll("Notification", "Dark Matter Reactor superstructure integrity at 50%.", "error", 10)
				Global:FindAudio("CoreInteg75"):Stop()
				Global:FindAudio("CoreInteg50"):Play()
			end
			if DMR.DMRInteg <= 25 then
				if IntegPhase == 2 then
					IntegPhase = 3
					AlarmMute = false
					Monitors.PowerBoard.ClickToView.AlarmArr.Volume = 0.25
					Monitors.PowerBoard.ClickToView.AlertBeep.Volume = 0.5
					Controls.OverheatAlarm.bell.Volume = 0.5
					Global:FindAudio("AlarmDaDaDa"):Play()
					CFMS.AlarmsOperations(5)

					task.wait(Global:FindAudio("AlarmDaDaDa").TimeLength)
					Network:SignalAll("Notification", "Dark Matter Reactor superstructure integrity at 25%.", "error", 10)
					Global:FindAudio("CoreInteg75"):Stop()
					Global:FindAudio("CoreInteg50"):Stop()
					Global:FindAudio("CoreInteg25"):Play()
				end
				if DMR.DMRInteg <= 10 and IntegPhase == 3 then
					IntegPhase = 4
					AlarmMute = false
					Monitors.PowerBoard.ClickToView.AlarmArr.Volume = 0.25
					Monitors.PowerBoard.ClickToView.AlertBeep.Volume = 0.5
					Controls.OverheatAlarm.bell.Volume = 0.5
					Global:FindAudio("CoreInteg75"):Stop()
					Global:FindAudio("CoreInteg50"):Stop()
					Global:FindAudio("CoreInteg25"):Stop()
					MeltdownActive = true

					task.spawn(function()
						Functions:ShutdownChecks()
					end)

					module.Meltdown:Fire("Phase1")
				end
			end
		end
	end
end

function Functions:FuelCheck()
	if DMR.DMRInteg > 25 then
		if DMR.DMRFuel >= 0 then
			if DMR.DMRFuel < 1 and not depdeb then
				depdeb = true
				module.PowerLasers:Fire("MeltdownDisable")
				TweenService:Create(ReactorCore.Core.Sound, TweenInfo.new(10), { PlaybackSpeed = 0 }):Play()

				task.wait(10)
				ReactorCore.Core.Sound:Stop()
				module.Maintenance:Fire("Out")
			elseif DMR.DMRFuel <= 20 and not fueldeb then
				fueldeb = true
				module.Maintenance:Fire("Under20")
			end
		else
			DMR.DMRFuel = 0
		end
	elseif DMR.DMRInteg < 25 and DMR.DMRFuel < 25 then
		DMR.DMRTemp = 4000
	end
end

function Functions:ReliefRefresh(Valve)
	local cc = "Relief" .. Valve
	ReliefDebounce[Valve] = true
	Controls[cc].Tweener.Main.ClickDetector.MaxActivationDistance = 0
	Monitors.Relief.Screen.Main["RVCap" .. Valve].Text = "COOLING"
	Controls[cc].Tweener.Main.Sound:Play()
	Global:TweenModel(Controls[cc].Tweener, Controls[cc].Org.CFrame, true, 0.5)
	Controls[cc].Light.BrickColor = BrickColor.new("Bright red")
	task.wait(120)
	Controls[cc].Tweener.Main.ClickDetector.MaxActivationDistance = 32
	Monitors.Relief.Screen.Main["RVCap" .. Valve].Text = "0"
	Controls[cc].Light.BrickColor = BrickColor.new("Black")
	ReliefPressure[Valve] = 0
	ReliefDebounce[Valve] = false
end

function Functions:Output()
	if not MeltdownActive then
		TweenService:Create(
			Radiation,
			TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Value = RanObj:NextInteger(100, 300) }
		):Play()
	end

	if DMR.DMRTemp < 200000 then
		TweenService:Create(Temp, TweenInfo.new(3, Enum.EasingStyle.Linear), { Value = DMR.DMRTemp }):Play()
	else
		for _, v in pairs(Monitors:GetDescendants()) do
			if v:IsA("TextLabel") and v.Name == "CoreTemp" then
				v.Text = "ERROR"
			end
		end
	end

	if not MeltdownActive then
		TweenService:Create(Integrity, TweenInfo.new(3, Enum.EasingStyle.Linear), { Value = math.floor(DMR.DMRInteg) })
			:Play()
	else
		for _, v in pairs(Monitors:GetDescendants()) do
			if v:IsA("TextLabel") and v.Name == "CoreInteg" then
				v.Text = "ERROR"
			end
		end
	end

	for i = 1, 3 do
		local fc = "FC" .. i .. "Level"
		if Fuel[i] >= 1 and Fuel[i] <= 100 then
			TweenService:Create(
				Monitors.FuelScreen.Screen.Main[fc].Slider,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundColor3 = Color3.fromRGB(0, 255, 17) }
			):Play()
			TweenService:Create(
				Monitors.FuelScreen2.Screen.Main[fc].Slider,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundColor3 = Color3.fromRGB(0, 255, 17) }
			):Play()
			TweenService:Create(
				Monitors.Maintenance.Screen.Main[fc].Slider,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundColor3 = Color3.fromRGB(0, 255, 17) }
			):Play()

			Monitors.FuelScreen.Screen.Main[fc].Slider:TweenSize(
				UDim2.new(1, 0, (-1 * (tonumber(Fuel[i]) / 100)), 0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Sine,
				1,
				5
			)
			Monitors.FuelScreen2.Screen.Main[fc].Slider:TweenSize(
				UDim2.new(1, 0, (-1 * (tonumber(Fuel[i]) / 100)), 0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Sine,
				1,
				5
			)
			Monitors.Maintenance.Screen.Main[fc].Slider:TweenSize(
				UDim2.new(1, 0, (-1 * (tonumber(Fuel[i]) / 100)), 0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Sine,
				1,
				5
			)
		elseif Fuel[i] > 100 then
			Monitors.FuelScreen.Screen.Main[fc].Slider.Size = UDim2.new(1, 0, -1, 0)
			Monitors.FuelScreen2.Screen.Main[fc].Slider.Size = UDim2.new(1, 0, -1, 0)
			Monitors.Maintenance.Screen.Main[fc].Slider.Size = UDim2.new(1, 0, -1, 0)

			TweenService:Create(
				Monitors.FuelScreen.Screen.Main[fc].Slider,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundColor3 = Color3.fromRGB(255, 55, 55) }
			):Play()
			TweenService:Create(
				Monitors.FuelScreen2.Screen.Main[fc].Slider,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundColor3 = Color3.fromRGB(255, 55, 55) }
			):Play()
			TweenService:Create(
				Monitors.Maintenance.Screen.Main[fc].Slider,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundColor3 = Color3.fromRGB(255, 55, 55) }
			):Play()
		else
			Monitors.FuelScreen.Screen.Main[fc].Slider.Size = UDim2.new(1, 0, 0, 0)
			Monitors.FuelScreen2.Screen.Main[fc].Slider.Size = UDim2.new(1, 0, 0, 0)
			Monitors.Maintenance.Screen.Main[fc].Slider.Size = UDim2.new(1, 0, 0, 0)
		end
		if Fuel[i] < 10 then
			Monitors.FuelScreen.Screen.Main[fc].Slider.LevelLabel.Position = UDim2.new(0, 0, -0.15, -40)
			Monitors.FuelScreen2.Screen.Main[fc].Slider.LevelLabel.Position = UDim2.new(0, 0, -0.15, -40)
			Monitors.Maintenance.Screen.Main[fc].Slider.LevelLabel.Position = UDim2.new(0, 0, -0.15, -40)

			Monitors.FuelScreen.Screen.Main[fc].Slider.LevelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			Monitors.FuelScreen2.Screen.Main[fc].Slider.LevelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			Monitors.Maintenance.Screen.Main[fc].Slider.LevelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			Monitors.FuelScreen.Screen.Main[fc].Slider.LevelLabel.Position = UDim2.new(0, 0, 0, 0)
			Monitors.FuelScreen2.Screen.Main[fc].Slider.LevelLabel.Position = UDim2.new(0, 0, 0, 0)
			Monitors.Maintenance.Screen.Main[fc].Slider.LevelLabel.Position = UDim2.new(0, 0, 0, 0)

			Monitors.FuelScreen.Screen.Main[fc].Slider.LevelLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			Monitors.FuelScreen2.Screen.Main[fc].Slider.LevelLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			Monitors.Maintenance.Screen.Main[fc].Slider.LevelLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		end

		if Fuel[i] < 50000 then
			Monitors.FuelScreen.Screen.Main[fc].Slider.LevelLabel.Text = "" .. math.floor(Fuel[i]) .. "%"
			Monitors.FuelScreen2.Screen.Main[fc].Slider.LevelLabel.Text = "" .. math.floor(Fuel[i]) .. "%"
			Monitors.Maintenance.Screen.Main[fc].Slider.LevelLabel.Text = "" .. math.floor(Fuel[i]) .. "%"
		else
			Monitors.FuelScreen.Screen.Main[fc].Slider.LevelLabel.Text = "ERROR"
			Monitors.FuelScreen2.Screen.Main[fc].Slider.LevelLabel.Text = "ERROR"
			Monitors.Maintenance.Screen.Main[fc].Slider.LevelLabel.Text = "ERROR"
		end
	end

	if DMR.DMRFuel < 50000 then
		Monitors.CoreTemp.Screen.Main.AvgFuel.Text = "" .. math.floor(DMR.DMRFuel) .. "% AVG."
	else
		Monitors.CoreTemp.Screen.Main.AvgFuel.Text = "ERROR"
	end
end

function Functions:TurbineOutput()
	for i = 1, 2 do
		if TurbineBoolean[i].Value == true then
			Monitors.Turbine.Screen.Sys:FindFirstChild("TurbineStatus" .. i).Text = "ACTIVE"
			Monitors.Turbine.Screen.Sys:FindFirstChild("Product" .. i).Text = TurbineGens[i].Value .. " gWm"
			TweenService:Create(
				Controls["Turbine" .. i].LPT.Sound,
				TweenInfo.new(3, Enum.EasingStyle.Linear),
				{ PlaybackSpeed = 0.1 + (TurbineGens[i].Value * 10) }
			):Play()
			TweenService:Create(
				Controls["Turbine" .. i].LPT.Sound,
				TweenInfo.new(3, Enum.EasingStyle.Linear),
				{ PlaybackSpeed = 0.3 + (TurbineGens[i].Value * 13) }
			):Play()

			for _, v in pairs(Controls["Turbine" .. i]:GetDescendants()) do
				if v:IsA("HingeConstraint") then
					TweenService:Create(
						v,
						TweenInfo.new(3, Enum.EasingStyle.Linear),
						{ AngularVelocity = TurbineGens[i].Value * 1000 }
					):Play()
				end
			end
		end

		local num = 0
		if TurbineBoolean[1].Value == true and TurbineBoolean[2].Value == true then
			num = (TurbineGens[1].Value + TurbineGens[2].Value)
		elseif TurbineBoolean[1].Value == true and TurbineBoolean[2].Value == false then
			num = TurbineGens[1].Value
		elseif TurbineBoolean[1].Value == false and TurbineBoolean[2].Value == true then
			num = TurbineGens[2].Value
		end

		Monitors.Turbine.Screen.Sys.GrossProduct.Text = (num * 60) .. " gWh"
		Monitors.TurbineTotalOutput.Screen.Sys.gWh.Text = (num * 60) .. " gWh"
		Monitors.PowerBoard.gWh.SurfaceGui.TextLabel.Text = (num * 60) .. " gWh"

		TurbineTotalOutput = (TurbineTotalOutput + num)
		Monitors.TurbineTotalOutput.Screen.Sys.gW.Text = string.sub(TurbineTotalOutput / 60, 1, 6) .. " gW"
	end
end

function Functions:EnableControls()
	for i = 1, 4 do
		local cc = "Relief" .. i
		Controls[cc].Tweener.Main.ClickDetector.MaxActivationDistance = 32
	end
end

function Functions:DisableControls()
	for i = 1, 4 do
		local cc = "Relief" .. i
		Controls[cc].Tweener.Main.ClickDetector.MaxActivationDistance = 0
	end
end

function Functions:PowerBoardFlash()
	local colors = { Color3.fromRGB(131, 229, 95), Color3.fromRGB(131, 229, 95), Color3.fromRGB(246, 253, 101) }
	local otherchance = { 6, 6 }
	if MeltdownActive then
		colors = { Color3.fromRGB(246, 253, 101), Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 70, 70) }
		otherchance = { 3, 2 }
	elseif DMR.DMRInteg <= 50 then
		colors = { Color3.fromRGB(246, 253, 101), Color3.fromRGB(255, 70, 70) }
	elseif DMR.DMRTemp >= 3500 then
		colors = { Color3.fromRGB(246, 253, 101), Color3.fromRGB(246, 253, 101), Color3.fromRGB(255, 70, 70) }
		otherchance = { 3, 3 }
	elseif DMR.DMRTemp >= 2250 then
		colors = {
			Color3.fromRGB(131, 229, 95),
			Color3.fromRGB(246, 253, 101),
			Color3.fromRGB(246, 253, 101),
			Color3.fromRGB(255, 70, 70),
		}
	elseif DMR.DMRTemp >= 1200 then
		colors = { Color3.fromRGB(131, 229, 95), Color3.fromRGB(246, 253, 101) }
		otherchance = { 4, 4 }
	end
	for i, c in pairs(Monitors.PowerBoard.PowerBoardLights.OtherLights:GetDescendants()) do
		if math.random(1, otherchance[1]) >= otherchance[2] then
			if c:IsA("BasePart") then
				c.Material = "Neon"
			end
		end
	end
	for i, c in pairs(Monitors.PowerBoard.PowerBoardLights.BlinkyLights:GetDescendants()) do
		if c:IsA("BasePart") then
			c.Material = "Neon"
			c.Color = colors[math.random(1, #colors)]
		end
	end
end

function Functions:PowerBoardOff()
	for i, c in
		pairs(
			game:GetService("Workspace").DMR.ReactorControlInterfaces.Monitors.PowerBoard.PowerBoardLights.OtherLights
				:GetDescendants()
		)
	do
		if c:IsA("BasePart") then
			c.Material = "SmoothPlastic"
		end
	end
	for i, c in
		pairs(
			game:GetService("Workspace").DMR.ReactorControlInterfaces.Monitors.PowerBoard.PowerBoardLights.BlinkyLights
				:GetDescendants()
		)
	do
		if c:IsA("BasePart") then
			c.Material = "SmoothPlastic"
			c.Color = Color3.fromRGB(237, 234, 234)
		end
	end
end

function Functions:ControlRoomLightsFlash()
	for i, c in pairs(Controls.CRLights:GetDescendants()) do
		local v = 3
		if MeltdownActive then
			v = 2
		end
		if math.random(1, 3) >= v then
			if c:IsA("BasePart") then
				c.Material = "Neon"
				c.Transparency = 0
				if c.BrickColor == BrickColor.new("Grime") then
					c.Color = game:GetService("Workspace").DMR.colorcontrolbricks.green.Color
				elseif c.Color == Color3.fromRGB(163, 75, 75) then
					c.Color = game:GetService("Workspace").DMR.colorcontrolbricks.red.Color
				elseif c.Color == Color3.fromRGB(253, 234, 141) then
					c.Color = game:GetService("Workspace").DMR.colorcontrolbricks.yellow.Color
				end
			end
		end
	end
end

function Functions:ControlRoomLightsOff()
	for i, c in pairs(game:GetService("Workspace").DMR.ReactorControlInterfaces.CRLights:GetDescendants()) do
		if c:IsA("BasePart") then
			c.Material = "SmoothPlastic"
			c.Transparency = 0.3
			if c.Color == game:GetService("Workspace").DMR.colorcontrolbricks.green.Color then
				c.BrickColor = BrickColor.new("Grime")
			elseif c.Color == game:GetService("Workspace").DMR.colorcontrolbricks.red.Color then
				c.Color = Color3.fromRGB(163, 75, 75)
			elseif c.Color == game:GetService("Workspace").DMR.colorcontrolbricks.yellow.Color then
				c.Color = Color3.fromRGB(253, 234, 141)
			end
		end
	end
end

function Functions:ShutdownPrereq()
	for i = 1, 3 do
		Fuel[i] = Fuel[i] + 1
	end
	if DMR.DMRTemp <= 3000 then
		module.Meltdown:Fire("ShutdownPrereq")
	end
end

function Functions:ShutdownChecks()
	while MeltdownActive do
		task.wait(6)
		Functions:ShutdownPrereq()
	end
end

function Functions:ThermalRunaway()
	while MeltdownActive do
		task.wait(3)
		for i = 1, 3 do
			Fuel[i] = Fuel[i] * 2
		end
	end
end

function Functions:EndThermalLoop()
	CycleActive = false
	for _, v in pairs(Monitors:GetDescendants()) do
		if v:IsA("TextLabel") and v.Name == "CoreTemp" then
			v.Text = "ERROR"
		end
	end
	Functions:PowerBoardOff()
	Functions:ControlRoomLightsOff()
end

function Functions:BeginThermalLoop()
	for _, v in pairs(Controls.CRLights.CR:GetChildren()) do
		v.Color = Color3.fromRGB(
			math.floor(v.BrickColor.Color.r * 255),
			math.floor(v.BrickColor.Color.g * 255),
			math.floor(v.BrickColor.Color.b * 255)
		)
	end

	for i = 1, 3 do
		for _, v in pairs(Monitors:GetDescendants()) do
			if v:IsA("TextLabel") and v.Name == ("FC" .. i .. "Cond") then
				v.Text = "" .. string.upper(FuelCells[i])
			end
		end
	end

	CycleActive = true

	while CycleActive do
		if DMR.DMRTemp >= 150 and DMR.DMRFuel > 0 then
			CoRoutine.Wrap(function()
				Functions:PLCycle()
			end, true)
			CoRoutine.Wrap(function()
				Functions:CoolantCycle()
			end, true)
			CoRoutine.Wrap(function()
				Functions:ReliefCycle()
			end, true)
		elseif DMR.DMRTemp < 150 then
			DMR.DMRTemp = 150
		end

		for i = 1, 3 do
			if Fuel[i] <= 0 then
				Fuel[i] = 0
			end
		end

		CoRoutine.Wrap(function()
			Functions:FuelCycle()
		end, true)
		CoRoutine.Wrap(function()
			Functions:IntegCycle()
		end, true)

		CoRoutine.Wrap(function()
			Functions:TempCheck()
		end, true)
		CoRoutine.Wrap(function()
			Functions:IntegCheck()
		end, true)
		CoRoutine.Wrap(function()
			Functions:FuelCheck()
		end, true)

		CoRoutine.Wrap(function()
			Functions:Output()
		end, true)
		CoRoutine.Wrap(function()
			Functions:TurbineOutput()
		end, true)
		CoRoutine.Wrap(function()
			Functions:PowerBoardFlash()
		end, true)
		CoRoutine.Wrap(function()
			Functions:ControlRoomLightsFlash()
		end, true)

		task.wait(1.5)

		CoRoutine.Wrap(function()
			Functions:PowerBoardOff()
		end, true)
		CoRoutine.Wrap(function()
			Functions:ControlRoomLightsOff()
		end, true)

		task.wait(1.5)
	end
end

function Functions:ReturnFuel()
	return DMR.DMRFuel
end

function Functions:TempDebug(Input)
	DMR.DMRTemp = Input
end

function Functions:FuelDebug(Input)
	for i = 1, 3 do
		Fuel[i] = Input
	end
end

function Functions:IntegDebug(Input)
	DMR.DMRInteg = Input
end

function Functions:RefuelFire(num, celltype)
	FuelCells[num] = celltype
	Fuel[num] = 100
end

function Functions:ThermalRunawayFire()
	CoRoutine.Wrap(function()
		Functions:ThermalRunaway()
	end, true)
end

function Functions:PostMaintenance()
	fueldeb = false
	depdeb = false
end

--#endregion

local Disconnect = function(...)
	local DisconnectFunction = function(What)
		if type(What) == "table" then
			for Index, Signal in pairs(What) do
				Signal:Disconnect()
			end
		else
			What:Disconnect()
		end
	end

	for Index, Value in pairs({ ... }) do
		DisconnectFunction(Value)
	end
end

function module:Init()
	Disconnect(Connections)
	CoRoutine.Clear(false)

	if Radiation and Temp and Integrity then
		Radiation:Destroy()
		Temp:Destroy()
		Integrity:Destroy()
	end

	TurbineGens = {
		[1] = Instance.new("NumberValue"),
		[2] = Instance.new("NumberValue"),
	}

	TurbineValve = {
		[1] = Instance.new("NumberValue"),
		[2] = Instance.new("NumberValue"),
	}

	TurbineBoolean = {
		[1] = Instance.new("BoolValue"),
		[2] = Instance.new("BoolValue"),
	}

	ReliefVal = {
		[1] = Instance.new("BoolValue"),
		[2] = Instance.new("BoolValue"),
		[3] = Instance.new("BoolValue"),
		[4] = Instance.new("BoolValue"),
	}

	CycleActive = false
	AlarmMute = false
	AlarmPhase = "N/A"
	IntegPhase = "N/A"
	MeltdownActive = false
	ReliefsActive = 0
	TurbineTotalOutput = 0
	fueldeb = false
	depdeb = false

	DMR = {
		DMRTemp = 600, --//temp starting point
		DMRFuel = 60, --//average fuel starting point
		DMRInteg = 100, --//integ starting point
	}

	--//Fuel cell types: "Generic", "Efficient", "Reactive", & "Super"
	FuelCells = {
		[1] = "Generic",
		[2] = "Generic",
		[3] = "Generic",
	}

	Fuel = {
		[1] = 60,
		[2] = 60,
		[3] = 60,
	}

	ReliefPressure = {
		[1] = 0,
		[2] = 0,
		[3] = 0,
		[4] = 0,
	}

	ReliefDebounce = {
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = false,
	}

	dtb = {
		[1] = false,
		[2] = false,
	}

	Radiation = Instance.new("IntValue")
	Radiation.Name = "Radiation"
	Radiation.Parent = script
	module.Radiation = Radiation

	Temp = Instance.new("IntValue")
	Temp.Name = "Temp"
	Temp.Parent = script

	Integrity = Instance.new("NumberValue")
	Integrity.Name = "Integrity"
	Integrity.Parent = script

	Connections.Roentgen = Radiation.Changed:Connect(function()
		task.wait(0.25)
		Monitors.PowerBoard.Sieverts.SurfaceGui.TextLabel.Text = Radiation.Value .. " R PER HOUR"
	end)

	Connections.Temp = Temp.Changed:Connect(function()
		task.wait(0.25)
		for _, v in pairs(Monitors:GetDescendants()) do
			if v:IsA("TextLabel") and v.Name == "CoreTemp" then
				v.Text = Temp.Value .. " °K"
			end
		end
	end)

	Connections.Integ = Integrity.Changed:Connect(function()
		task.wait(0.25)
		for _, v in pairs(Monitors:GetDescendants()) do
			if v:IsA("TextLabel") and v.Name == "CoreInteg" then
				v.Text = "" .. math.floor(Integrity.Value) .. "%"
			end
		end
	end)

	for i = 1, 4 do
		ReliefVal[i].Value = false
		Connections["ReliefValve_Changed" .. i] = ReliefVal[i].Changed:Connect(function(v)
			if ReliefVal[i].Value == true then
				while ReliefVal[i].Value do
					if ReliefPressure[i] == 60 then
						ReliefsActive = ReliefsActive - 1
						ReliefVal[i].Value = false
						Monitors.Relief.Screen.Main["RVActive" .. i].Text = "FALSE"
						Functions:ReliefRefresh(i)
						break
					else
						ReliefPressure[i] = ReliefPressure[i] + 1
						Monitors.Relief.Screen.Main["RVCap" .. i].Text = "" .. ReliefPressure[i]
						task.wait(1)
					end
				end
			end
		end)
	end

	for i = 1, 2 do
		TurbineBoolean[i].Value = false
		Connections["TurbineBoolean" .. i] = TurbineBoolean[i].Changed:Connect(function(v)
			if TurbineBoolean[i].Value == true then
				while TurbineBoolean[i].Value == true do
					task.wait(3)
					for l = 0, 4 do
						if module.PowerLasers:Fire("ReturnCurrentMode") then
							if module.PowerLasers:Fire("ReturnGlobalLevel") == l then
								TurbineGens[i].Value = string.sub(
									((DMR.DMRTemp / l + 1) * TurbineValve[i].Value / RanObj:NextInteger(9000, 9500))
										/ 60,
									1,
									-11
								)
							end
						else
							for v = 1, 6 do
								if module.PowerLasers:Fire("ReturnIndividualLevel", v) == l then
									TurbineGens[i].Value = string.sub(
										(
											(DMR.DMRTemp / ((l + 1) / 6))
											* TurbineValve[i].Value
											/ RanObj:NextInteger(9000, 9500)
										) / 60,
										1,
										-11
									)
								end
							end
						end
					end
				end
			end
		end)
	end

	for i = 1, 4 do
		local cc = "Relief" .. i
		Connections[cc] = Controls[cc].Tweener.Main.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
			if ReliefVal[i].Value == false and not ReliefDebounce[i] then
				ReliefDebounce[i] = true
				Network:SignalAll("ConsolePrint", "Relief valve " .. i .. " toggled on by " .. Player.Name)
				Controls[cc].Tweener.Main.Sound:Play()
				Global:TweenModel(Controls[cc].Tweener, Controls[cc].To.CFrame, true, 0.5)
				Controls[cc].Light.BrickColor = BrickColor.new("Lime green")
				ReliefVal[i].Value = true
				ReliefsActive = ReliefsActive + 1
				Monitors.Relief.Screen.Main["RVActive" .. i].Text = "TRUE"
				ReliefDebounce[i] = false
			elseif ReliefVal.Value == true and not ReliefDebounce[i] then
				ReliefDebounce[i] = true
				Network:SignalAll("ConsolePrint", "Relief valve " .. i .. " toggled off by " .. Player.Name)
				Controls[cc].Tweener.Main.Sound:Play()
				Global:TweenModel(Controls[cc].Tweener, Controls[cc].Org.CFrame, true, 0.5)
				Controls[cc].Light.BrickColor = BrickColor.new("Black")
				ReliefVal[i].Value = false
				ReliefsActive = ReliefsActive - 1
				Monitors.Relief.Screen.Main["RVActive" .. i].Text = "FALSE"
				ReliefDebounce[i] = false
			end
		end))
	end

	TurbineGens[1].Value = 0
	TurbineGens[2].Value = 0
	TurbineValve[1].Value = 100
	TurbineValve[2].Value = 100

	for i = 1, 2 do
		Connections["Turbine" .. i .. "ValveUp"] =
			Controls["Turbine" .. i .. "Valve"].Up.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
				if not dtb[i] then
					if CycleActive then
						if TurbineBoolean[i].Value == true then
							if TurbineValve[i].Value <= 90 then
								dtb[i] = true
								for b = 1, 10 do
									TurbineValve[i].Value = tonumber(TurbineValve[i].Value) + 1
									Controls["Turbine" .. i .. "Valve"].Screen.SurfaceGui.Online.ValueText.Text = TurbineValve[i].Value
										.. "%"
									task.wait(0.025)
								end
								task.wait(1)
								dtb[i] = false
							end
						else
							Network:Signal("Notification", Player, "Activate the turbines first!", "error", 5)
						end
					end
				end
			end))

		Connections["Turbine" .. i .. "ValveDown"] =
			Controls["Turbine" .. i .. "Valve"].Down.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
				if not dtb[i] then
					if CycleActive then
						if TurbineBoolean[i].Value == true then
							if TurbineValve[i].Value >= 10 then
								dtb[i] = true
								for b = 1, 10 do
									TurbineValve[i].Value = tonumber(TurbineValve[i].Value) - 1
									Controls["Turbine" .. i .. "Valve"].Screen.SurfaceGui.Online.ValueText.Text = TurbineValve[i].Value
										.. "%"
									task.wait(0.025)
								end
								task.wait(1)
								dtb[i] = false
							end
						else
							Network:Signal("Notification", Player, "Activate the turbines first!", "error", 5)
						end
					end
				end
			end))

		Connections["Turb" .. i] = Controls["Turb" .. i].Center.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
			if not dtb[i] then
				if CycleActive then
					if TurbineBoolean[i].Value == false then
						dtb[i] = true
						Network:SignalAll("ConsolePrint", "Steam turbine #" .. i .. " toggled on by " .. Player.Name)
						Controls["Turb" .. i].Center.Sound:Play()
						Global:SwitchToggle(Controls["Turb" .. i], "On")
						Controls["Turbine" .. i .. "Valve"].Screen.SurfaceGui.Offline.Visible = false
						Controls["Turbine" .. i .. "Valve"].Screen.SurfaceGui.Online.Visible = true
						Monitors.Turbine.Screen.Sys:FindFirstChild("Valve" .. i).Text = "OPENING"

						TweenService:Create(
							Monitors.PowerBoard["Turbine" .. i],
							TweenInfo.new(15),
							{ Color = Color3.fromRGB(131, 229, 95) }
						):Play()
						TweenService
							:Create(Controls["Turbine" .. i].LPT.Sound, TweenInfo.new(15), { PlaybackSpeed = 0.5 })
							:Play()
						TweenService
							:Create(Controls["Turbine" .. i].HPT.Sound, TweenInfo.new(15), { PlaybackSpeed = 0.8 })
							:Play()
						for _, v in pairs(Controls["Turbine" .. i]:GetDescendants()) do
							if v:IsA("HingeConstraint") then
								TweenService:Create(v, TweenInfo.new(15), { AngularVelocity = 40 }):Play()
							end
						end

						task.wait(15)
						TurbineBoolean[i].Value = true
						Monitors.Turbine.Screen.Sys["Valve" .. i].Text = "OPENED"

						task.wait(5)
						dtb[i] = false
					elseif TurbineBoolean[i].Value == true then
						dtb[i] = true
						Network:SignalAll("ConsolePrint", "Steam turbine #" .. i .. " toggled off by " .. Player.Name)
						Controls["Turb" .. i].Center.Sound:Play()
						Global:SwitchToggle(Controls["Turb" .. i], "Off")
						Controls["Turbine" .. i .. "Valve"].Screen.SurfaceGui.Offline.Visible = true
						Controls["Turbine" .. i .. "Valve"].Screen.SurfaceGui.Online.Visible = false
						Monitors.Turbine.Screen.Sys:FindFirstChild("Valve" .. i).Text = "CLOSING"

						Monitors.Turbine.Screen.Sys:FindFirstChild("Product" .. i).Text = "0 gWm"
						Monitors.Turbine.Screen.Sys:FindFirstChild("TurbineStatus" .. i).Text = "INACTIVE"
						Monitors.Turbine.Screen.Sys:FindFirstChild("Valve" .. i).Text = "CLOSING"

						TweenService:Create(
							Monitors.PowerBoard["Turbine" .. i],
							TweenInfo.new(15),
							{ Color = Color3.fromRGB(213, 115, 61) }
						):Play()
						TweenService
							:Create(Controls["Turbine" .. i].LPT.Sound, TweenInfo.new(15), { PlaybackSpeed = 0 })
							:Play()
						TweenService
							:Create(Controls["Turbine" .. i].HPT.Sound, TweenInfo.new(15), { PlaybackSpeed = 0 })
							:Play()
						for _, v in pairs(Controls["Turbine" .. i]:GetDescendants()) do
							if v:IsA("HingeConstraint") then
								TweenService:Create(v, TweenInfo.new(15), { AngularVelocity = 0 }):Play()
							end
						end

						task.wait(15)
						TurbineBoolean[i].Value = false
						Monitors.Turbine.Screen.Sys:FindFirstChild("Product" .. i).Text = "0 gWm"
						Monitors.Turbine.Screen.Sys:FindFirstChild("TurbineStatus" .. i).Text = "INACTIVE"
						Monitors.Turbine.Screen.Sys:FindFirstChild("Valve" .. i).Text = "CLOSED"

						task.wait(5)
						dtb[i] = false
					end
				else
					Network:Signal("Notification", Player, "Activate the DMR first!", "error", 5)
				end
			end
		end))
	end

	Connections.AlarmMute = Controls.AlarmMute.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
		if not AlarmMute then
			AlarmMute = true
			Network:SignalAll("ConsolePrint", "Alarm button pressed by " .. Player.Name)
			Controls.AlarmMute.Click:Play()
			Monitors.PowerBoard.ClickToView.AlarmArr.Volume = 0
			Monitors.PowerBoard.ClickToView.AlertBeep.Volume = 0
			Controls.OverheatAlarm.bell.Volume = 0
			Controls.OverheatAlarm.Material = Enum.Material.SmoothPlastic
		end
	end))

    module.Thermals:Connect(function(Function, ...)
		if Functions[Function] then
			return Functions[Function](unpack({ ... }))
		end
    end)
end

return module