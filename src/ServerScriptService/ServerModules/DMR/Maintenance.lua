local module = {}
local Core = shared.Core
local Wrap = Core.Get("Wrap")
local Network = Core.Get("Network")
local CoRoutine = Core.Get("CoRoutine")
local SignalProvider = Core.Get("SignalProvider")
module.Thermals = SignalProvider:Get("ThermalFunctions")
module.PowerLasers = SignalProvider:Get("PowerLaserFunctions")
module.Coolant = SignalProvider:Get("CoolantFunctions")
module.Startup = SignalProvider:Get("StartupFunctions")
module.Maintenance = SignalProvider:Get("MaintenanceFunctions")

local Debounce = false
local FuelUnder20 = false
local OutOfFuel = false
local MaintenanceActive = false
local Handles = {
	[1] = false,
	[2] = false,
	[3] = false,
}
local Keys = {
	[1] = false,
	[2] = false,
}
local FuelCells = {
	[1] = true,
	[2] = true,
	[3] = true,
}
local PreviousCellType = {
	[1] = "Generic",
	[2] = "Generic",
	[3] = "Generic",
}
local FuelCellsType = {
	[1] = "Generic",
	[2] = "Generic",
	[3] = "Generic",
}

local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Controls = game:GetService("Workspace").DMR.ReactorControlInterfaces
local Monitors = Controls.Monitors
local Reactor = game:GetService("Workspace").DMR.ReactorCore
local ReactorCore = Reactor.Core
local Global = Core.Get("Global")
local CellStorage = Core.Get("FuelCellStorage")
local Connections = {}

--#region Functions
local Functions = {}

function Functions:Start()
	Debounce = true

	for i = 1, 3 do
		FuelCells[i] = "Need Replacement"
	end

	for _, v in pairs(Controls.Monitors:GetChildren()) do
		v.OfflineNotice.Enabled = true
		v.Screen.Enabled = false
	end

	Controls.ShutdownPanel.Shutdown.OfflineNotice.Enabled = false
	Controls.ShutdownPanel.Shutdown.Screen.Enabled = true

	for _, v in pairs(Controls.Monitors:GetChildren()) do
		v.OfflineNotice.TextLabel.Text = "DMR OFFLINE FOR MAINTENANCE..."
	end

	Controls.ShutdownPanel.Shutdown.OfflineNotice.TextLabel.Text = "DMR OFFLINE FOR MAINTENANCE..."
	Global:FindAudio("Main-tain-ence_mode"):Play()
	Global:FindAudio("Fuel_Cell_Depleted"):Stop()
	Network:SignalAll("Notification", "Maintenance mode for the DMR has been engaged. Replace all three fuel cells to restart the DMR.", "none",	8)

	task.wait(Global:FindAudio("Main-tain-ence_mode").TimeLength + 0.5)

	Global:FindAudio("Fuel Capsule Replacement"):Play()

	for i = 1, 3 do
		ReactorCore.FuelCells["Console" .. i].LowerConsole.Handle.ClickDetector.MaxActivationDistance = 12
	end

	Network:SignalAll("Notification", "Reminder: Fuel cells can be made at the Hadron Collider in Sector A.", "none", 8)
	CellStorage:Toggle(true)

	task.wait(1)

	MaintenanceActive = true
	Debounce = false
end

function Functions:End()
	Debounce = true
	CellStorage:Toggle(false)

	for i = 1, 3 do
		FuelCells[i] = true
		module.Thermals:Fire("RefuelFire", i, FuelCellsType[i])
	end

	module.Thermals:Fire("PostMaintenance")

	MaintenanceActive = false
	OutOfFuel = false
	FuelUnder20 = false

	for i = 1, 3 do
		Handles[i] = false
	end

	for _, v in pairs(Controls.Monitors:GetChildren()) do
		v.OfflineNotice.TextLabel.Text = "DMR READY FOR RE-IGNITION..."
	end

	Network:SignalAll("Notification", "Maintenance completed. Restart the DMR by turning the key on the main ignition panel.", "none", 10)

	for i = 1, 2 do
		Controls.MaintenancePanel["Key" .. i].Key.Center.Sound:Play()
		Global:TweenModel(Controls.MaintenancePanel["Key" .. i].Key, Controls.MaintenancePanel["Key" .. i].Org.CFrame, false, 0.5)
		Controls.MaintenancePanel["Stage" .. i].BrickColor = BrickColor.new("Bright red")
		Keys[i] = false
	end

	module.Startup:Fire("Variable", "Key", false)
	module.Startup:Fire("Variable", "CanTurn", true)
	module.Startup:Fire("Variable", "BootDebounce", false)

	Controls.Start.Key.ClickDetector.MaxActivationDistance = 16
	Controls.Start.Key.Sound:Play()
	Global:TweenModel(Controls.Start.KeyM.KeyM, Controls.Start.KeyM.Org.CFrame, false, 0.5)
	TweenService:Create(Controls.Start.Lock_Ind, TweenInfo.new(0.5), { Color = Color3.fromRGB(27, 42, 53) }):Play()

	task.wait(1)

	Debounce = false
end

function Functions:Check()
	if FuelCells[1] == true and FuelCells[2] == true and FuelCells[3] == true then
		Network:SignalAll("Notification", "All Fuel Cells have been locked. Re-click the maintenance button to end maintenance restart the DMR.", "none", 15)
		Global:FindAudio("Fuel Capsule Replacement completed"):Play()
	end
end

function Functions:Out()
	OutOfFuel = true

	for i = 1, 3 do
		FuelCells[i] = "Depleted"
	end

	Global:FindAudio("Fuel_Cell_Depleted"):Play()
	Network:SignalAll("Notification", "Dark Matter Reactor fuel depleted. Refueling required.", "none", 10)
end

function Functions:Under20()
	FuelUnder20 = true

	for i = 1, 3 do
		FuelCells[i] = "Depleted"
	end

	Global:FindAudio("Fuel_Cell_Low"):Play()
	Network:SignalAll("Notification", "Dark Matter Reactor average fuel level under 20%. Refueling required soon.", "none", 10)
end
--#endregion

local function MaintKeys(plr, i)
	if Keys[i] == false and not Debounce then
		Debounce = true
		Keys[i] = true

		Network:SignalAll("ConsolePrint", "Maintenance panel key #" .. i .. " turned by " .. plr.Name)
		Controls.MaintenancePanel["Stage" .. i].BrickColor = BrickColor.new("Shamrock")
		Controls.MaintenancePanel["Key" .. i].Key.Center.Sound:Play()
		Global:TweenModel( Controls.MaintenancePanel["Key" .. i].Key, Controls.MaintenancePanel["Key" .. i].ToGo.CFrame, true, 0.5)
		Debounce = false

		task.wait(3)

		if (Keys[1] == true and Keys[2] == false) or (Keys[1] == false and Keys[2] == true) then
			Debounce = true
			Controls.MaintenancePanel["Stage" .. i].BrickColor = BrickColor.new("Bright red")

			Network:SignalAll("ConsolePrint", "Maintenance priming sequence aborted- both keys not turned in time.")
			Global:TweenModel( Controls.MaintenancePanel["Key" .. i].Key, Controls.MaintenancePanel["Key" .. i].Org.CFrame, true, 0.5)

			Keys[i] = false
			Debounce = false
		end
	end
end

local function MaintButton(plr)
	if not Debounce then
		if MaintenanceActive then
			if FuelCells[1] == true and FuelCells[2] == true and FuelCells[3] == true then
				Debounce = true

				Controls.MaintenancePanel.Button.Bloop:Play()
				Network:SignalAll("ConsolePrint", "Maintenance Mode disengaged by " .. plr.Name)

				Global:FindAudio("Fuel Capsule Replacement completed"):Stop()
				Global:FindAudio("Main-ten-ance_Completed"):Play()

				task.wait(Global:FindAudio("Main-ten-ance_Completed").TimeLength - 2)

				module.Startup:Fire("Variable", "StartupType", "Maintenance")
				Functions:End()
			else
				Debounce = true

				Monitors.Maintenance.ErrorSFX:Play()
				Monitors.Maintenance.OfflineNotice.Enabled = false
				Monitors.Maintenance.Error.Enabled = true
				Monitors.Maintenance.Error.Reason.Text = "Maintenance access denied; all fuel cells pending insertion"

				Network:Signal("Notification", plr, "Insert all the fuel cells to end maintenance.", "error", 5)

				task.wait(4)

				Monitors.Maintenance.OfflineNotice.Enabled = true
				Monitors.Maintenance.Error.Enabled = false

				task.wait(4)

				Debounce = false
			end
		else
			if Keys[1] == true and Keys[2] == true then
				if (FuelUnder20 and OutOfFuel) or (FuelUnder20 and not OutOfFuel) then
					Debounce = true

					module.PowerLasers:Fire("DisableControls")

					Controls.PLModeSwitch.Buttons.Left.Part.ClickDetector.MaxActivationDistance = 0
					Controls.PLModeSwitch.Buttons.Right.Part.ClickDetector.MaxActivationDistance = 0

					module.Thermals:Fire("DisableControls")
					module.Coolant:Fire("DisableControls")
					module.Thermals:Fire("EndThermalLoop")

					Network:SignalAll("ConsolePrint", "Maintenance Mode engaged by " .. plr.Name)

					TweenService:Create(module.Thermals:Fire("GetRadiation"), TweenInfo.new(7), { Value = 0 }):Play()

					for i = 1, 6 do
						TweenService:Create(Monitors.PowerBoard["PowerLaser" .. i], TweenInfo.new(7), { Color = Color3.fromRGB(213, 115, 61) }):Play()
						TweenService:Create(Reactor.MainStabalizer["Blue" .. i], TweenInfo.new(7), { Transparency = 1 }):Play()
					end

					if FuelUnder20 and OutOfFuel then
						CoRoutine.Wrap(function() Functions:Start() end, true)
					elseif FuelUnder20 and not OutOfFuel then
						TweenService:Create(ReactorCore.Core.Sound, TweenInfo.new(10), { PlaybackSpeed = 0 }):Play()
						task.wait(10)
						CoRoutine.Wrap(function() Functions:Start() end, true)
					end

					Network:SignalAll("CompleteChallenge", "DMRMAINTENANCE")
				else
					Debounce = true

					Monitors.Maintenance.ErrorSFX:Play()
					Monitors.Maintenance.Screen.Enabled = false
					Monitors.Maintenance.Error.Enabled = true
					Monitors.Maintenance.Error.Reason.Text = "Maintenance access denied; prerequisites not met (Avg. Fuel Level < 20%)"

					Network:Signal("Notification", plr, "The average fuel level must be under 20% to activate maintenance.", "error", 6)

					task.wait(4)

					Monitors.Maintenance.Screen.Enabled = true
					Monitors.Maintenance.Error.Enabled = false

					task.wait(4)

					Debounce = false
				end
			elseif Keys[1] == false and Keys[2] == false then
				Debounce = true

				Monitors.Maintenance.ErrorSFX:Play()
				Monitors.Maintenance.Screen.Enabled = false
				Monitors.Maintenance.Error.Enabled = true
				Monitors.Maintenance.Error.Reason.Text = "Maintenance access denied; keys not turned"

				Network:Signal("Notification", plr, "Turn the maintenance panel keys to be able to use this button.", "error", 5)

				task.wait(4)

				Monitors.Maintenance.Screen.Enabled = true
				Monitors.Maintenance.Error.Enabled = false

				task.wait(4)

				Debounce = false
			end
		end
	end
end

local function ConsoleHandle(plr, i)
	if not Debounce then
		if MaintenanceActive then
			local console = ReactorCore.FuelCells["Console" .. i].LowerConsole

			if Handles[i] == false then
				Debounce = true
				FuelCells[i] = false

				console.Handle.ClickDetector.MaxActivationDistance = 0
				console.Handle.Main.Sound:Play()
				Global:FindAudio("Fuel_Cell"):Play()

				Network:SignalAll("ConsolePrint", "Fuel Cell " .. i .. " removed by " .. plr.Name)
				Network:SignalAll("Notification", "Fuel Cell " .. i .. " removed.", "none", 3)
				Global:TweenModel(console.Handle, console.ToGoParts.Down.CFrame, false, 1)

				task.wait(1)

				Global:FindAudio("Cell" .. i):Play()

				task.wait(1)

				Global:FindAudio("Unlocked"):Play()

				console.green.Material = Enum.Material.SmoothPlastic
				console.red.Material = Enum.Material.Neon

				ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"].PRIMARY.SoundUnlock:Play()

				Global:TweenModel(ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"], ReactorCore.FuelCells["Console" .. i].TGP["pre-insert"].CFrame, true, 1)
				Global:TweenModel(ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"], ReactorCore.FuelCells["Console" .. i].TGP.eject.CFrame, true, 1.3)

				if ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"].Name == "GenericCell" then
					PreviousCellType[i] = "Generic"
				elseif ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"].Name == "ReactiveCell" then
					PreviousCellType[i] = "Reactive"
				elseif ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"].Name == "SuperCell" then
					PreviousCellType[i] = "Super"
				elseif ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"].Name == "EfficientCell" then
					PreviousCellType[i] = "Efficient"
				end

				ServerStorage.HadronCollider.DMRFuel[FuelCellsType[i]]["Depleted " .. FuelCellsType[i] .. " Cell"]:Clone().Parent = plr.Backpack

				for _, v in pairs(ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"]:GetDescendants()) do
					if v:IsA("BasePart") or v:IsA("Decal") then
						v.Transparency = 1
					elseif v:IsA("PointLight") then
						v.Enabled = false
					end
				end

				task.wait(1)

				console.Handle.ClickDetector.MaxActivationDistance = 32
				Handles[i] = true
				Debounce = false
			elseif Handles[i] == true then
				if FuelCells[i] == "Ready" then
					Debounce = true

					console.Handle.ClickDetector.MaxActivationDistance = 0
					console.Handle.Main.Sound:Play()
					Global:FindAudio("Fuel_Cell"):Play()

					Network:SignalAll("ConsolePrint", "Fuel Cell " .. i .. " inserted by " .. plr.Name)
					Network:SignalAll("Notification", "" .. tostring(FuelCellsType[i]) .. " type cell inserted in fuel chamber slot " .. i, "none", 3)
					Global:TweenModel(console.Handle, console.ToGoParts.Up.CFrame, false, 1)

                    task.wait(1)

                    Global:FindAudio("Cell" .. i):Play()

                    task.wait(1)

                    Network:Signal("CompleteChallenge", plr, "FUELDMR")

                    Global:FindAudio("Locked"):Play()

                    console.green.Material = Enum.Material.Neon
					console.red.Material = Enum.Material.SmoothPlastic
					ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"].PRIMARY.SoundLock:Play()

                    Global:TweenModel(
						ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"],
						ReactorCore.FuelCells["Console" .. i].TGP.insert.CFrame,
						true,
						1
					)

                    task.wait(1)

                    Handles[i] = true
					FuelCells[i] = true

                    Functions:Check()

                    Debounce = false
				else
					Network:Signal("Notification", plr, "Insert a fuel cell to do this!", "error", 3)
				end
			end
		else
			Network:Signal("Notification", plr, "Engage maintenance first!", "error", 3)
		end
	else
		Network:Signal("Notification", plr, "Please wait...", "error", 3)
	end
end

local function CellTouch(hit, i)
	if MaintenanceActive and FuelCells[i] == false and Debounce == false then
		Debounce = true
		local found = false

		if hit.Parent:IsA("Tool") then
			for _, v in pairs(hit.Parent:GetChildren()) do
				if v.Parent.Name == "Generic Cell" then
					found = true
					FuelCellsType[i] = "Generic"
					break
				elseif v.Parent.Name == "Super Cell" then
					found = true
					FuelCellsType[i] = "Super"
					break
				elseif v.Parent.Name == "Reactive Cell" then
					found = true
					FuelCellsType[i] = "Reactive"
					break
				elseif v.Parent.Name == "Efficient Cell" then
					found = true
					FuelCellsType[i] = "Efficient"
					break
				end
			end
		end

		if found == true then
			hit.Parent:Destroy()

			for _, v in pairs(ReactorCore.FuelCells["Console" .. i][PreviousCellType[i] .. "Cell"]:GetDescendants()) do
				if v:IsA("BasePart") and v.Name == "Color" then
					v.Color = ServerStorage.HadronCollider.DMRFuel[FuelCellsType[i]][FuelCellsType[i] .. " Cell"].Color.Color
					v.Transparency = 0
				elseif v:IsA("BasePart") or v:IsA("Decal") then
					v.Transparency = 0
				elseif v:IsA("PointLight") then
					v.Enabled = true
				end
			end

			ReactorCore.FuelCells["Console" .. i][PreviousCellType[i] .. "Cell"].Name = FuelCellsType[i] .. "Cell"
			Global:TweenModel(ReactorCore.FuelCells["Console" .. i][FuelCellsType[i] .. "Cell"], ReactorCore.FuelCells["Console" .. i].TGP["pre-insert"].CFrame, true, 1)
			FuelCells[i] = "Ready"
		end

		Debounce = false
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

	Debounce = false
	FuelUnder20 = false
	OutOfFuel = false
	MaintenanceActive = false

	Handles = {
		[1] = false,
		[2] = false,
		[3] = false,
	}

	Keys = {
		[1] = false,
		[2] = false,
	}

	FuelCells = {
		[1] = true,
		[2] = true,
		[3] = true,
	}

	PreviousCellType = {
		[1] = "Generic",
		[2] = "Generic",
		[3] = "Generic",
	}

	FuelCellsType = {
		[1] = "Generic",
		[2] = "Generic",
		[3] = "Generic",
	}

	for i = 1, 3 do
		Connections["CHandle" .. i] = ReactorCore.FuelCells["Console" .. i].LowerConsole.Handle.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
            ConsoleHandle(Player, i)
        end))

        Connections["CTouch" .. i] = ReactorCore.FuelCells["Console" .. i].Touch.Touched:Connect(function(What)
			CellTouch(What, i)
		end)
	end

	for i = 1, 2 do
		Connections["Keys" .. i] = Controls.MaintenancePanel["Key" .. i].Key.Center.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
            MaintKeys(Player, i)
        end))
	end

	Connections.MButton = Controls.MaintenancePanel.Button.ClickDetector.MouseClick:Connect(Wrap:Make(MaintButton))
    
    module.Maintenance:Connect(function(Function, ...)
		if Functions[Function] then
			return Functions[Function](unpack({ ... }))
		end
    end)
end

return module
