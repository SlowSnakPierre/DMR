--[[
    "MeltdownFunctions"
]]

local module = {}
local Core = shared.Core

local Badges = {
	ReactorShutdown = 2124482126,
	ReactorMeltdown = 2124482127,
	ThatJustHappened = 2124484131,
}

local Code = "N/A"
local Input = ""

local Debounce = {
	DebounceMain = false,
	KeypadDebounce = false,
	StickynoteDebounce = false,
	MeltdownDebounce = true,
}

local ShutdownVariables = {
	ShutdownWindow = false,
	ShutdownActive = false,
	KeypadActive = false,
	Key1Primed = false,
	Key2Primed = false,
	TempBelow3500 = false,
}

local DestructionVariables = {
	PowerLaser1 = false,
	PowerLaser3 = false,
	DiagonalLift = false,
	DMRCrane = false,
}

local Extras = {
	["Logo"] = false,
	["Cave"] = false,
	["Crane"] = false,
}

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local BadgeService = game:GetService("BadgeService")

local NSD = Core.Get("NSDHole", true)
local Hazmat = Core.Get("Hazmat_Handler", true)
local PowerLasers = Core.Get("PowerLasers", true)
local Thermals = Core.Get("Thermals", true)
local Hazmat_Func = Hazmat.Functions
local CraneCollapseToPL3 = Core.Get("CraneCollapseToPL3")
local Globals = Core.Get("Global")
local CFMS = Core.Get("CFMS")
local Energy = Core.Get("CoolEffectsScript")
local CoRoutine = Core.Get("CoRoutine")
local Network = Core.Get("Network")
local Wrap = Core.Get("Wrap")

local Reactor = workspace.DMR.ReactorCore
local Controls = workspace.DMR.ReactorControlInterfaces
local Sounds = workspace.Audios
local ReactorCore = Reactor.Core
local Monitors = Controls.Monitors
local ShutdownPanel = Controls.ShutdownPanel
local Effects = Sounds.Effects
local Explosions = Effects.Explosions
local Rumble = Effects.Rumbling

local Connections = {}
local RanObj = Random.new(tick())

local Counter = function(count)
	task.wait(0.25)

	if count >= 100 then
		local seconds = string.sub(tostring(count), 1, string.len(count) - 2)
		local notseconds = string.sub(tostring(count), string.len(count) - 1, string.len(count))
		local minutes = math.floor(seconds / 60)
		local sec = seconds - minutes * 60

        if string.len(minutes) == 1 then
			minutes = "0" .. minutes
		end

        if string.len(sec) == 1 then
			sec = "0" .. sec
		end

        for _, v in pairs(Controls.Monitors:GetDescendants()) do
			if v.Name == "ShutdownWCountdown" then
				v.Text = "[ " .. minutes .. ":" .. sec .. ":" .. notseconds .. " ]"
			end
		end
	elseif count == 0 then
		for _, v in pairs(Controls.Monitors:GetDescendants()) do
			if v.Name == "ShutdownWCountdown" then
				v.Text = "[ 00:00:00 ]"
			end
		end
	else
		for _, v in pairs(Controls.Monitors:GetDescendants()) do
			if v.Name == "ShutdownWCountdown" then
				v.Text = "[ 00:00:" .. count .. " ]"
			end
		end
	end
end

local function GenerateCode()
	local GeneratedCode = RanObj:NextInteger(10000, 99999)
	Code = GeneratedCode

	print("The shutdown code is " .. tostring(GeneratedCode))

	for _, v in pairs(ShutdownPanel.NumPad:GetDescendants()) do
		if v:IsA("ClickDetector") then
			v.MaxActivationDistance = 32
		end
	end

	local Ran = RanObj:NextInteger(1, 8)
	local StickyNote = "SN" .. tonumber(Ran)

    Controls.StickyNotes[StickyNote].Text.SurfaceGui.TextLabel.Text = Code
	Controls.StickyNotes[StickyNote].Text.BillboardGui.Enabled = true
	Controls.StickyNotes[StickyNote].Text.Hint:Play()
	Controls.StickyNotes[StickyNote].ClickDetector.MaxActivationDistance = 32
end

local function GenerateStringFromCode(code)
	local code = tostring(code)

    if string.len(code) < 5 then
		return table.concat(string.split(code .. string.rep("_", 5 - string.len(code)), ""), " ")
	else
		return table.concat(string.split(code, ""), " ")
	end
end

local function ClearStickyNotes()
	for _, v in pairs(Controls.StickyNotes:GetDescendants()) do
		if v:IsA("BillboardGui") then
			v.Enabled = false
		elseif v:IsA("ClickDetector") then
			v.MaxActivationDistance = 0
		end
	end
end

--#region Functions
local Functions = {}

function Functions:Destruction()
    CoRoutine.Wrap(function()
        local Ran = RanObj:NextInteger(1, 5)

        if Ran == 1 then
            if DestructionVariables.DMRCrane == false and DestructionVariables.PowerLaser3 == false then
                DestructionVariables.DMRCrane = true
                DestructionVariables.PowerLaser3 = true

                CraneCollapseToPL3.Functions:Run()
                Hazmat_Func:HZState("Hazard")

                TweenService:Create(script.Parent.Thermals.Radiation, TweenInfo.new(190, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Value = RanObj:NextInteger(1000, 1500) }):Play()
            end
        end
    end)
end

function Functions:Explosions()
    CoRoutine.Wrap(function()
        local Ran = RanObj:NextInteger(1, 2)

        if Ran == 1 then
            local Chosen = RanObj:NextInteger(1, 6)
            Explosions["Explosion" .. tonumber(Chosen)]:Play()
        elseif Ran == 2 then
            Explosions.Explosion_Crumble:Play()
        end
    end)
end

function Functions:BlastSheltersOpen()
    CoRoutine.Wrap(function()
        Globals:FindAudio("Please_Proceed_to_the_bla_immediatly"):Play()

        Network:SignalAll("Notification", "Blast shelters are open and will close soon!", "none", 5)

        Controls.BSSL1.BillboardGui.Enabled = true
        Controls.BSCH7.BillboardGui.Enabled = true

        Controls.Sublevel1BS.LockdownDoor.Frame.Union.Sound:Play()
        Controls.Charlie7BS.LockdownDoor.Frame.Union.Sound:Play()

        Globals:TweenModel(Controls.Sublevel1BS.LockdownDoor.Door, Controls.Sublevel1BS.LockdownDoor.Orig.CFrame, false, 12)
        Globals:TweenModel(Controls.Charlie7BS.LockdownDoor.Door, Controls.Charlie7BS.LockdownDoor.Orig.CFrame, false, 12)
    end)
end

function Functions:BlastSheltersClose()
    CoRoutine.Wrap(function()
        Network:SignalAll("Notification", "Blast shelters closing, evacuate to the Tartarus Zone!", "none", 5)

        Controls.Sublevel1BS.LockdownDoor.Frame.Union.Sound:Play()
        Controls.Charlie7BS.LockdownDoor.Frame.Union.Sound:Play()

        Globals:TweenModel(Controls.Sublevel1BS.LockdownDoor.Door, Controls.Sublevel1BS.LockdownDoor.TGP.CFrame, false, 12)
        Globals:TweenModel(Controls.Charlie7BS.LockdownDoor.Door, Controls.Charlie7BS.LockdownDoor.TGP.CFrame, false, 12)

        task.wait(13)

        Controls.Sublevel1BS.LockdownDoor.Frame.Union.LockedSound:Play()
        Controls.Charlie7BS.LockdownDoor.Frame.Union.LockedSound:Play()

        Controls.BSSL1.BillboardGui.Enabled = false
        Controls.BSCH7.BillboardGui.Enabled = false
    end)
end

function Functions:Rumble()
    CoRoutine.Wrap(function()
        local Chosen = RanObj:NextInteger(1, 14)
        Rumble["Rumble" .. tonumber(Chosen)]:Play()
    end)
end

function Functions:NewPowerOutage()
    CoRoutine.Wrap(function()
        local Chance = math.random(1, 3)

        if Chance == 3 then
            task.wait(math.random(1, 5))
            task.spawn(function()
                Energy:Off()
            end)

            task.wait(math.random(11, 30))
            task.spawn(function()
                Energy:On()
            end)
        end
    end, true)
end

function Functions:Shake(int1, int2)
    local Value = RanObj:NextInteger(tonumber(int1), tonumber(int2))
    local Time = RanObj:NextNumber(2, 6)

    Network:SignalAll("Shake", Value, Time)
end

function Functions:Dust(int1, int2)
    CoRoutine.Wrap(function()
        local Chosen = RanObj:NextInteger(tonumber(int1), tonumber(int2))

        for _, v in pairs(workspace.Dust:GetChildren()) do
            v.Dust.Enabled = true
            v.Dust2.Enabled = true
        end

        task.wait(Chosen)

        for _, v in pairs(workspace.Dust:GetChildren()) do
            v.Dust.Enabled = false
            v.Dust2.Enabled = false
        end
    end, true)
end

function Functions:PowerLaserFailure()
    CoRoutine.Wrap(function()
        Hazmat_Func:HZState("Hazard")
        TweenService:Create(script.Parent.Thermals.Radiation, TweenInfo.new(190, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Value = RanObj:NextInteger(1000, 1500) }):Play()

        local Ran = RanObj:NextInteger(1, 8)

        if Ran == 1 or Ran == 3 then
            local PL = "PL" .. tonumber(Ran)
            local PLVariable = "PowerLaser" .. tonumber(Ran)
            local Blue = "Blue" .. tonumber(Ran)

            if DestructionVariables[PLVariable] == false then
                DestructionVariables[PLVariable] = true

                PowerLasers.Functions:MeltdownDisable()

                TweenService:Create(Monitors.PowerBoard["PowerLaser" .. tonumber(Ran)], TweenInfo.new(2), { Color = Color3.fromRGB(190, 104, 98) }):Play()
                Reactor.MainStabalizer[Blue].Position = Vector3.new(Reactor.MainStabalizer[Blue].Position.X, 62, Reactor.MainStabalizer[Blue].Position.Z)

                Functions:Shake(70, 150)
                Functions:Dust(2, 4)

                Reactor.Power_Lasers[PL].Model.Model.Explosion.Sound:Play()

                Reactor.Power_Lasers[PL].Model.Model.Explosion.PointLight.Enabled = true
                Reactor.Power_Lasers[PL].Model.Model.Explosion.ParticleEmitter.Enabled = true
                Reactor.Power_Lasers[PL].Model.Model.Explosion.ParticleEmitter2.Enabled = true
                Reactor.Power_Lasers[PL].Model.Model.Explosion.ParticleEmitter3.Enabled = true

                Globals:TweenModel(Reactor.Power_Lasers[PL].Model.Model, Reactor.Power_Lasers[PL].Model.TGP1.CFrame, false, 1)

                task.wait(0.5)

                Reactor.Power_Lasers[PL].Model.Model.Explosion.PointLight.Enabled = false
                Reactor.Power_Lasers[PL].Model.Model.Explosion.ParticleEmitter.Enabled = false
                Reactor.Power_Lasers[PL].Model.Model.Explosion.ParticleEmitter2.Enabled = false
                Reactor.Power_Lasers[PL].Model.Model.Explosion.ParticleEmitter3.Enabled = false

                task.wait(0.5)

                Globals:TweenModel(Reactor.Power_Lasers[PL].Model.Model, Reactor.Power_Lasers[PL].Model.TGP2.CFrame, false, 1)
            end
        end
    end, true)
end

function Functions:ShutdownPrereq()
    ShutdownVariables.TempBelow3500 = true
end

function Functions:ShutdownPre()
    Network:SignalAll("Notification", "Emergency reactor shutdown sequence engaged!", "none", 5)

    CoRoutine.Wrap(ClearStickyNotes, true)

    Globals:FindAudio("Suspense"):Play()

    for _, v in pairs(Controls.Monitors:GetDescendants()) do
        if v:IsA("SurfaceGui") and v.Name == "PrepSys" then
            v.Enabled = true
        elseif v:IsA("SurfaceGui") and v.Name == "CountdownTimer" then
            v.Enabled = false
        end
    end

    task.wait(57)

    Globals:FindAudio("AlarmDaDaDa"):Stop()
    Globals:FindAudio("AlarmErr"):Stop()
    Globals:FindAudio("AlarmWah"):Stop()
    Globals:FindAudio("Resonance"):Stop()

    if DestructionVariables.PowerLaser1 == false and DestructionVariables.PowerLaser3 == false then
        if ShutdownVariables.TempBelow3500 == true then
            Network:SignalAll("Notification", "Emergency reactor shutdown sequence successful! Shutting down the reactor now...", "happy", 8)
            CoRoutine.Wrap(function() Functions:Shutdown() end, true)
        else
            Globals:FindAudio("Shutdown_Failure_2_electric_boogaloo"):Play()
            Network:SignalAll("Notification", "Emergency reactor shutdown sequence failure. Temperature exceeding limits for safe absorbtion rod insertion.", "none", 12)

            task.wait(Globals:FindAudio("Shutdown_Failure_2_electric_boogaloo").TimeLength)

            CoRoutine.Wrap(function() Functions:Phase2() end, true)
        end
    else
        Globals:FindAudio("Reactor_Shutdown_Failure"):Play()
        Network:SignalAll("Notification", "Emergency reactor shutdown sequence failure. Unable to shutdown critical systems.", "none", 8)

        task.wait(Globals:FindAudio("Reactor_Shutdown_Failure").TimeLength)

        CoRoutine.Wrap(function() Functions:Phase2() end, true)
    end
end

function Functions:Shutdown()
    PowerLasers.Functions:DisableControls()

    Network:SignalAll("CompleteChallenge", "SAVEDMR")

    Globals:FindAudio("SuccessfulShutdown").Volume = 1.25
    Globals:FindAudio("SuccessfulShutdown"):Play()
    Globals:FindAudio("Shutdown Sucess"):Play()

    TweenService:Create(ReactorCore.Core.Sound, TweenInfo.new(10), { PlaybackSpeed = 0 }):Play()

    for i = 1, 6 do
        TweenService:Create(Controls.Monitors.PowerBoard["PowerLaser" .. i], TweenInfo.new(10), { Color = Color3.fromRGB(213, 115, 61) }):Play()
    end

    for i = 1, 6 do
        local Blue = "Blue" .. i
        Reactor.MainStabalizer[Blue].PointLight.Enabled = false
        TweenService:Create(Reactor.MainStabalizer[Blue], TweenInfo.new(10), { Transparency = 1 }):Play()
    end

    task.wait(10)

    ReactorCore.Core.Sound:Stop()

    Globals:TweenModel(ReactorCore, CFrame.new(ReactorCore.Centre.Position.X, ReactorCore.Centre.Position.Y - 57, ReactorCore.Centre.Position.Z), false, 15)
    Thermals.Functions:DisableControls()

    for i = 1, 4 do
        local S = "Sprinkler" .. i
        Controls[S].ParticleEmitter.Enabled = true
        Controls[S].wudder:Play()
    end

    task.wait(8)

    CFMS.AlarmsOperations(0)
    workspace.DMR.Core_Damage.Core_Fire.Fire.Enabled = false

    Thermals.Functions:EndThermalLoop()
    Controls.OverheatAlarm.bell:Stop()
    Controls.Monitors.PowerBoard.ClickToView.AlarmArr:Stop()
    Controls.Monitors.PowerBoard.ClickToView.AlertBeep:Stop()

    for _, v in pairs(Controls.Monitors:GetDescendants()) do
        if v:IsA("SurfaceGui") and v.Name == "PrepSys" then
            v.Enabled = false
        elseif v:IsA("SurfaceGui") and v.Name == "Screen" then
            v.Enabled = false
        end
    end

    for _, v in pairs(Controls.Monitors:GetChildren()) do
        v.OfflineNotice.Enabled = true
        v.Screen.Enabled = false
        v.OfflineNotice.TextLabel.Text = "SYSTEM UNAVAILABLE; EMERGENCY REACTOR SHUTDOWN ENGAGED"
    end

    task.wait(6)

    for i = 1, 4 do
        local S = "Sprinkler" .. i
        Controls[S].ParticleEmitter.Enabled = false
        Controls[S].wudder:Stop()
    end

    for i = 1, 2 do
        TweenService:Create(Controls.Monitors.PowerBoard["GravityLaser" .. i], TweenInfo.new(5), { Color = Color3.fromRGB(213, 115, 61) }):Play()
    end

    for i = 1, 3 do
        local Red = "Red" .. i
        Reactor.MainStabalizer[Red].PointLight.Enabled = false
        TweenService:Create(Reactor.MainStabalizer[Red], TweenInfo.new(5), { Transparency = 1 }):Play()
    end

    task.wait(5)

    Globals:FindAudio("Reactor_Ops_Report_Status"):Play()

    Network:SignalAll("CompleteChallenge", "DMRSHUTDOWN")

    task.wait(13)

    Network:SignalAll("MeltDeltDownYesICanSpeel", "FIRE_ENDING", "SHUTDOWN_ENDING")

    for _, v in ipairs(Players:GetPlayers()) do
        BadgeService:AwardBadge(v.UserId, Badges.ReactorShutdown)
    end

    task.wait(2)

    local Target = workspace.TeleportBack.CFrame

    for _, Player in pairs(Players:GetChildren()) do
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            coroutine.wrap(function()
                Player.Character:FindFirstChild("Humanoid").Jump = true
                Player:RequestStreamAroundAsync(workspace.TeleportBack.Position)
                Player.Character.HumanoidRootPart.CFrame = Target + Vector3.new(0, Player * 5, 0)
                Hazmat_Func:ZGSet(Player, false)
            end)()
        end
    end

    Hazmat_Func:Regen()
end

function Functions:MeltdownSequence()
    CoRoutine.Wrap(function() Functions:Phase1() end, true)
end

function Functions:Phase1()
    workspace.Audios.HumanAnnouncements.Announcements.Disabled = true
    workspace.Audios.Effects.OtherUnworldlyNoises.Sounds.Disabled = true

    Functions:Rumble()

    --CodexCleanup:Fire()

    Globals:FindAudio("Resonance"):Play()
    Functions:Shake(13, 20)
    Functions:Dust(2, 4)

    task.wait(5)

    Globals:FindAudio("AlarmDaDaDa"):Play()

    task.wait(5)

    Functions:Rumble()
    Functions:Shake(5, 10)
    Functions:Dust(2, 4)

    task.wait(2)

    Globals:InfoOutput("DMR", "INTEGRITY MONITORING FAILURE")

    Globals:FindAudio("Integrity Monitoring Failure"):Play()
    task.wait(Globals:FindAudio("Integrity Monitoring Failure").TimeLength + 2)

    Functions:Rumble()
    Functions:Shake(20, 40)
    Functions:Dust(2, 4)

    task.wait(17)

    Globals:FindAudio("Pressure monitoring failure"):Play()

    task.wait(12)

    Globals:FindAudio("AlarmErr"):Play()
    Globals:FindAudio("Minumum Safe Distance"):Play()

    Functions:Rumble()
    Functions:Shake(20, 40)
    Functions:Dust(2, 4)

    task.wait(18)

    Globals:FindAudio("thisisnotadrill"):Play()

    task.wait(12)

    Functions:Rumble()
    Functions:Shake(25, 50)
    Functions:Dust(2, 4)

    task.wait(27)

    Functions:Rumble()
    Functions:Shake(20, 40)
    Functions:NewPowerOutage()
    Functions:Dust(2, 4)

    task.wait(10)

    Globals:FindAudio("Prembtion Protocol"):Play()
    Globals:InfoOutput("DMR", "PREEMPTION PROTOCOL INITIATED ")

    task.wait(4)

    Globals:FindAudio("AlarmErr").Looped = false

    Functions:Rumble()
    Functions:Shake(20, 40)
    Functions:Dust(2, 4)

    task.wait(14)

    Globals:FindAudio("reactoropspersonnel"):Play()

    task.wait(8)

    Functions:Rumble()
    Functions:Shake(10, 25)
    Functions:Dust(2, 4)
    Functions:PowerLaserFailure()

    task.wait(12)

    Globals:FindAudio("Estimating reactor destruct"):Play()

    task.wait(10)

    Globals:FindAudio("AlarmWah"):Play()
    Globals:FindAudio("10 minutes"):Play()
    Globals:InfoOutput("DMR", "DETONATION IN 10 MINUTES")
    Functions:Rumble()
    Functions:Shake(10, 25)
    Functions:NewPowerOutage()
    Functions:Dust(2, 4)

    task.wait(16)

    CoRoutine.Wrap(function() Functions:ShutdownW() end, true)
end

function Functions:ShutdownW()
    ShutdownVariables.ShutdownWindow = true

    CFMS.AlarmsOperations(4)
    Globals:InfoOutput("DMR", "SHUTDOWN WINDOW ACTIVE")
    ShutdownPanel.Shutdown.Screen.Main.Visible = false
    ShutdownPanel.Shutdown.Screen.Emergency.Visible = true
    CoRoutine.Wrap(GenerateCode, true)

    Network:SignalAll("Notification", "DMR Emergency Shutdown window active. Try to find the code to shutdown the DMR.", "none", 7.5)

    task.wait(1)

    Network:SignalAll("Notification", "Note: All power lasers must be operational and the core temperature must be under 3000 Kelvin.", "none", 7.5)

    for _, v in pairs(Controls.Monitors:GetDescendants()) do
        if v.Name == "CountdownTimer" then
            v.Enabled = true
            v.Parent.Screen.Enabled = false
        end
    end

    script.Countdown.Value = 131 * 100

    TweenService:Create(script.Countdown, TweenInfo.new(131, Enum.EasingStyle.Linear), { Value = 0 }):Play()

    Globals:FindAudio("Shutdown Active r"):Play()

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(17)

    Globals:FindAudio("Distress_Signal"):Play()
    Globals:InfoOutput("DMR", "DISTRESS SIGNAL SENT")

    task.wait(9)

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    Globals:FindAudio("Coms_down"):Play()
    Globals:FindAudio("AlarmWah").Looped = false

    task.wait(7)

    Functions:Explosions()
    Functions:Rumble()
    Functions:NewPowerOutage()
    Functions:Shake(20, 40)
    Functions:Dust(1, 3)

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(5)

    Functions:Explosions()
    Functions:Rumble()
    Functions:Shake(20, 40)
    Functions:Dust(1, 3)
    Functions:Destruction()

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(5)

    Globals:FindAudio("AlarmDaDaDa"):Play()
    task.wait(Globals:FindAudio("AlarmDaDaDa").TimeLength)
    Globals:FindAudio("Max_Radiation"):Play()

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(10)

    Globals:FindAudio("Facility_Integ_Comprimised"):Play()

    Functions:Rumble()
    Functions:Shake(20, 40)
    Functions:Dust(1, 3)

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(10)

    Globals:FindAudio("Science Personnel Evac"):Play()
    Globals:FindAudio("Rumble7"):Play()
    Functions:Rumble()
    Functions:Shake(20, 40)
    Functions:Dust(1, 3)
    Globals:FindAudio("AlarmErr"):Play()
    Globals:FindAudio("AlarmErr").Looped = true

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(16)

    Globals:FindAudio("IntegDropping"):Play()
    Globals:InfoOutput("DMR", "INTEGRITY DROPPING")
    Functions:Rumble()
    Functions:NewPowerOutage()
    Functions:Shake(20, 40)
    Functions:Dust(1, 3)

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(6)

    Functions:Rumble()
    Functions:Shake(20, 40)
    Functions:Dust(1, 3)

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(16)

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(16)

    Functions:PowerLaserFailure()
    Globals:FindAudio("AlarmErr").Looped = false
    Globals:FindAudio("Please_do_not_use_the_ERROR"):Play()

    task.wait(8)

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    Functions:Rumble()
    Functions:Shake(20, 40)
    Functions:Dust(1, 3)
    Globals:FindAudio("FAAS_Error"):Play()

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    task.wait(5)

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    for _, v in pairs(Controls.Monitors:GetDescendants()) do
        if v.Name == "CountdownTimer" then
            v.Enabled = false
            v.Parent.Screen.Enabled = true
        end
    end

    ShutdownVariables.ShutdownWindow = false

    if ShutdownVariables.ShutdownActive == true then
        return
    end

    Globals:InfoOutput("DMR", "SHUTDOWN WINDOW EXPIRED")

    CoRoutine.Wrap(ClearStickyNotes, true)

    Network:SignalAll("Notification", "The DMR Emergency Shutdown window has expired.", "none", 5)

    Globals:FindAudio("AlarmDaDaDa"):Play()

    task.wait(Globals:FindAudio("AlarmDaDaDa").TimeLength)

    Globals:FindAudio("5 minutes"):Play()

    task.wait(Globals:FindAudio("5 minutes").TimeLength + 1)

    CoRoutine.Wrap(function() Functions:Phase2() end, true)
end

function Functions:Phase2()
    for _, v in pairs(Controls.Monitors:GetDescendants()) do
        if v.Name == "CountdownTimer" then
            v.Enabled = false
        elseif v.Name == "PrepSys" then
            v.Enabled = false
        elseif v.Name == "Screen" then
            v.Enabled = true
        end
    end

    Globals:FindAudio("Breach"):Play()
    Globals:FindAudio("Code_Black"):Play()
    CFMS.AlarmsOperations(2)

    Hazmat_Func:HZState("Dead")
    PowerLasers.Functions:MeltdownDisable()
    Thermals.Functions:ThermalRunawayFire()

    TweenService:Create(Lighting, TweenInfo.new(200, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { FogColor = Color3.fromRGB(132, 60, 38) }):Play()
    TweenService:Create(Lighting, TweenInfo.new(200, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { FogEnd = 500 }):Play()
    TweenService:Create(ReactorCore.Core.Sound, TweenInfo.new(60, Enum.EasingStyle.Sine, Enum.EasingDirection.In),{ Volume = 1.5 }):Play()
    TweenService:Create(ReactorCore.Core.Sound, TweenInfo.new(230, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { PlaybackSpeed = 10 }):Play()
    TweenService:Create(ReactorCore.Heat, TweenInfo.new(120, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Transparency = 0 }):Play()

    for _, v in pairs(ReactorCore.DMRSign:GetDescendants()) do
        if v:IsA("TextLabel") then
            TweenService:Create(v, TweenInfo.new(60, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 1 }):Play()
            TweenService:Create(v, TweenInfo.new(40, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextColor3 = Color3.fromRGB(193, 193, 123) }):Play()
        elseif v:IsA("Decal") then
            TweenService:Create(v, TweenInfo.new(60, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 1 }):Play()
        end
    end

    workspace.DMR.Core_Damage.Core_Fire.Smoke.Enabled = true

    task.wait(3)

    TweenService:Create(script.Parent.Thermals.Radiation, TweenInfo.new(190, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Value = RanObj:NextInteger(20000, 30000) }):Play()

    task.wait(7)

    Functions:Rumble()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:NewPowerOutage()
    Functions:Dust(1, 3)

    task.wait(15)

    Globals:FindAudio("DMR Ops Evac"):Play()

    Functions:Rumble()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)
    Functions:Destruction()

    task.wait(8)

    Globals:FindAudio("Controls_Irresponsive"):Play()

    Functions:Rumble()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)

    task.wait(8)

    Functions:BlastSheltersOpen()

    task.wait(11)

    Globals:FindAudio("Pressure Purge Failure"):Play()

    Functions:Rumble()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)

    task.wait(10)

    workspace.DMR.Core_Damage.Core_Fire.Fire.Enabled = true
    Globals:FindAudio("AlarmBuzzer").Looped = false
    Globals:FindAudio("System_Fairure"):Play()

    Functions:Rumble()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)

    task.wait(15)

    Globals:FindAudio("High_Rads_Levels_Detected"):Play()

    task.wait(Globals:FindAudio("High_Rads_Levels_Detected").TimeLength + 0.2)

    Globals:FindAudio("Reactor_Operations_Cavern"):Play()

    Functions:Rumble()
    Functions:NewPowerOutage()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)
    Functions:Destruction()

    task.wait(2)

    Globals:FindAudio("AlarmAhh"):Play()
    Globals:FindAudio("AlarmAhh").Looped = true

    task.wait(6)

    Functions:Rumble()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)
    Functions:Destruction()

    task.wait(17)

    Globals:FindAudio("FAAS_Error"):Play()

    Functions:Rumble()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)

    task.wait(8)

    Globals:FindAudio("AlarmAhh").Looped = false

    Functions:Rumble()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)

    task.wait(4)

    Functions:Rumble()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)
    Functions:Destruction()

    task.wait(4)

    Functions:Rumble()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)
    Functions:Destruction()

    task.wait(15)

    Globals:FindAudio("Lockdown protocol"):Play()

    task.wait(7)

    Functions:Rumble()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)
    Functions:NewPowerOutage()

    task.wait(12)

    Functions:Rumble()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)
    Functions:Destruction()

    task.wait(11)

    Globals:FindAudio("Lockdown 30 seconds"):Play()

    task.wait(5)

    Functions:Rumble()
    Functions:Explosions()
    Functions:Shake(60, 90)
    Functions:Dust(1, 3)
    Functions:Destruction()

    task.wait(10)

    Globals:FindAudio("Lockdown 10 seconds"):Play()

    task.wait(2)

    Globals:FindAudio("cuttingourlosses"):Play()
    ReactorCore.Core.implode:Play()
    Functions:BlastSheltersClose()

    task.wait(10)

    CoRoutine.Wrap(function() Functions:Phase3() end, true)
end

function Functions:Phase3()
    Globals:FindAudio("Gravitational Anomoly"):Play()
    Globals:FindAudio("Explosion_Rumble"):Play()
    Functions:Rumble()
    Functions:Shake(200, 300)
    Functions:Dust(1, 3)

    task.spawn(function()
        Energy:Off()
    end)

    CoRoutine.Wrap(function()
        for _, v in pairs(workspace.DMR.Core_Damage:GetChildren()) do
            if v.Name == "Core_Explosive" then
                v:FindFirstChild("ParticleEmitter").Enabled = true
            end
        end
    end)

    task.wait(0.5)
    task.wait(0.4)

    NSD.Functions:NSDHole()

    CoRoutine.Wrap(function()
        for _, v in pairs(workspace.DMR.Core_Damage:GetChildren()) do
            if v.Name == "Core_Explosive" then
                v:FindFirstChild("ParticleEmitter").Enabled = false
            end
        end
    end)

    Network:SignalAll("CompleteChallenge", "DMRMELTDOWN")

    task.wait(42.6)

    Globals:FindAudio("Explosion_MainStream"):Play()

    task.wait(0.8)

    NSD.Functions:EndNSD()

    TweenService:Create(Lighting, TweenInfo.new(2), { ExposureCompensation = 0.5 }):Play()
    TweenService:Create(Lighting, TweenInfo.new(2), { Ambient = Color3.fromRGB(255, 255, 255) }):Play()

    workspace.DMR.Black_Hole.Nuke.Script.Disabled = false

    task.wait(1)

    Network:SignalAll("MeltDeltDownYesICanSpeel", "FIRE_ENDING", "MELTDOWN_ENDING")

    Functions:Rumble()
    Functions:Shake(800, 1400)
    Functions:Dust(1, 3)

    for _, v in ipairs(Players:GetPlayers()) do
        BadgeService:AwardBadge(v.UserId, Badges.ReactorMeltdown)
    end

    task.wait(2)
    Energy:InstaOn()

    task.wait(2)
    local Target = workspace.TeleportBack.CFrame

    for Number, Player in pairs(Players:GetChildren()) do
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            task.spawn(function()
                Player.Character:FindFirstChild("Humanoid").Jump = true
                Player:RequestStreamAroundAsync(workspace.TeleportBack.Position)
                Player.Character.HumanoidRootPart.CFrame = Target + Vector3.new(0, Number * 5, 0)
                Hazmat_Func:ZGSet(Player, false)
            end)
        end
    end

    Hazmat_Func:Regen()
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
	print("Compiling")

	Disconnect(Connections)

	CoRoutine.Clear()

	script.Countdown.Value = 0

	Badges = {
		ReactorShutdown = 2124482126,
		ReactorMeltdown = 2124482127,
		ThatJustHappened = 2124484131,
	}

	Code = "N/A"
	Input = ""

	Debounce = {
		DebounceMain = false,
		KeypadDebounce = false,
		StickynoteDebounce = false,
		MeltdownDebounce = true,
	}

	ShutdownVariables = {
		ShutdownWindow = false,
		ShutdownActive = false,
		KeypadActive = false,
		Key1Primed = false,
		Key2Primed = false,
		TempBelow3500 = false,
	}

	DestructionVariables = {
		PowerLaser1 = false,
		PowerLaser3 = false,
		DiagonalLift = false,
		DMRCrane = false,
	}

	Extras = {
		["Logo"] = false,
		["Cave"] = false,
		["Crane"] = false,
	}

	Connections.Counter = script.Countdown.Changed:Connect(Counter)

	for i = 0, 9 do
		local n = "Num" .. i
		Connections[n] = ShutdownPanel.NumPad[n].Union.ClickDetector.MouseClick:Connect(Wrap:Make(function()
			if string.len(Input) < 5 and Debounce.KeypadDebounce == false then
				Debounce.KeypadDebounce = true
				ShutdownPanel.NumPad[n].Union.Sound:Play()
				Input = Input .. i
				ShutdownPanel.Shutdown.Screen.Emergency.Number.Text = GenerateStringFromCode(Input)

                task.wait(0.25)

                Debounce.KeypadDebounce = false
			end
		end))
	end

	Connections.Clear = ShutdownPanel.NumPad.Clr.Union.ClickDetector.MouseClick:Connect(Wrap:Make(function()
		if Debounce.KeypadDebounce == false then
			Debounce.KeypadDebounce = true
			Input = ""
			ShutdownPanel.Shutdown.Screen.Emergency.Number.Text = GenerateStringFromCode(Input)

            task.wait(0.25)

            Debounce.KeypadDebounce = false
		end
	end))

	Connections.Enter = ShutdownPanel.NumPad.Entr.Union.ClickDetector.MouseClick:Connect(Wrap:Make(function()
		if Debounce.KeypadDebounce == false then
			Debounce.KeypadDebounce = true
			ShutdownPanel.NumPad.Entr.Union.Sound:Play()

            if Input == tostring(Code) then
				ShutdownVariables.KeypadActive = true

				ShutdownPanel.Shutdown.Screen.Emergency.Number.Text = "CODE ACCEPTED"
				ShutdownPanel.Stage1.BrickColor = BrickColor.new("Shamrock")
				ShutdownPanel.Button.Material = Enum.Material.Neon
				ShutdownPanel.Button.Err.Volume = 0.5
				ShutdownPanel.Button.ClickDetector.MaxActivationDistance = 32
				ShutdownPanel.Key1.Key.Center.ClickDetector.MaxActivationDistance = 32
				ShutdownPanel.Key2.Key.Center.ClickDetector.MaxActivationDistance = 32
			else
				Input = ""

				ShutdownPanel.Shutdown.Screen.Emergency.Number.Text = GenerateStringFromCode(Input)
				ShutdownPanel.Shutdown.Screen.Enabled = false
				ShutdownPanel.Shutdown.Error.Enabled = true
				ShutdownPanel.Shutdown.Error.TextLabel.Text = "ACCESS DENIED; INCORRECT CODE"
				ShutdownPanel.Shutdown.ErrorSFX:Play()

                task.wait(2)

                ShutdownPanel.Shutdown.Screen.Enabled = true
				ShutdownPanel.Shutdown.Error.Enabled = false

				Debounce.KeypadDebounce = false
			end
		end
	end))

	for i = 1, 2 do
		local key = "Key" .. i

        Connections[key] = ShutdownPanel[key].Key.Center.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
			if ShutdownVariables["Key" .. i .. "Primed"] == false then
				ShutdownVariables["Key" .. i .. "Primed"] = true
				Network:SignalAll("ConsolePrint", "Shutdown panel key #1 turned by " .. Player.Name)
				ShutdownPanel[key].Key.Center.Sound:Play()
				Globals:TweenModel(ShutdownPanel[key].Key, ShutdownPanel[key].ToGo.CFrame, false, 0.5)

                if i == 1 then
					ShutdownPanel.Stage2.BrickColor = BrickColor.new("Shamrock")
				elseif i == 2 then
					ShutdownPanel.Stage3.BrickColor = BrickColor.new("Shamrock")
				end
			end
		end))
	end

	for i = 1, 8 do
		local stick = "SN" .. i

        Connections[stick] = Controls.StickyNotes[stick].ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
			if ShutdownVariables.ShutdownWindow == true and Debounce.StickynoteDebounce == false then
				Debounce.StickynoteDebounce = true
				Controls.StickyNotes[stick].Text.Hint:Play()
				Controls.StickyNotes[stick].Text.BillboardGui.TextLabel.Text = "The shutdown code is " .. Code .. "!"

                Network:SignalAll("CompleteChallenge", "DMRSHUTDOWNCODE")

                Network:SignalAll("ConsolePrint", "Shutdown code discovered by " .. Player.Name .. "!")
			end
		end))
	end

	Connections.ShutdownButton = ShutdownPanel.Button.ClickDetector.MouseClick:Connect(Wrap:Make(function(Player)
		if Debounce.DebounceMain == false then
			if ShutdownVariables.Key1Primed == true and ShutdownVariables.Key2Primed == true and ShutdownVariables.KeypadActive == true and ShutdownVariables.ShutdownWindow == true then
				local Ran = RanObj:NextInteger(1, 40)

				if Ran == 1 then
					Debounce.DebounceMain = true
					ShutdownVariables.ShutdownActive = true

					ShutdownPanel.Button.Bloop:Play()
					ShutdownPanel.Button.ClickDetector.MaxActivationDistance = 0

					Globals:FindAudio("AlarmDaDaDa"):Stop()
					Globals:FindAudio("AlarmErr"):Stop()
					Globals:FindAudio("AlarmWah"):Stop()
					Globals:FindAudio("Resonance"):Stop()

					for _, v in pairs(Controls.Monitors:GetDescendants()) do
						if v.Name == "CountdownTimer" then
							v.Enabled = false
							v.Parent.Screen.Enabled = true
						end
					end

					task.wait(ShutdownPanel.Button.Bloop.TimeLength)

					ShutdownPanel.Button.gone:Play()

					task.wait(2.4)

					TweenService:Create(ShutdownPanel.Button, TweenInfo.new(2.6), { Transparency = 1 }):Play()

					task.wait(2.6)

					for _, v in ipairs(Players:GetPlayers()) do
						BadgeService:AwardBadge(v.UserId, Badges.ThatJustHappened)
					end

					CoRoutine.Wrap(function() Functions:Phase2() end, true)
				else
					Debounce.DebounceMain = true
					ShutdownVariables.ShutdownActive = true
					ShutdownPanel.Button.Bloop:Play()

					for _, v in pairs(Sounds:GetDescendants()) do
						if v:IsA("Sound") then
							v:Stop()
						end
					end

					Globals:FindAudio("AlarmDaDaDa"):Stop()
					Globals:FindAudio("AlarmErr"):Stop()
					Globals:FindAudio("AlarmWah"):Stop()
					Globals:FindAudio("Resonance"):Stop()
					Globals:FindAudio("Emergency Shutdown Activated"):Play()

					CoRoutine.Wrap(function() Functions:ShutdownPre() end, true)
				end
			elseif ShutdownVariables.ShutdownWindow == false and Debounce.DebounceMain == false then
				Debounce.DebounceMain = true
				ShutdownPanel.Button.Err:Play()
				ShutdownPanel.Shutdown.Screen.Enabled = false
				ShutdownPanel.Shutdown.Error.Enabled = true
				ShutdownPanel.Shutdown.Error.TextLabel.Text = "ACCESS DENIED; SHUTDOWN WINDOW NOT ACTIVE"

				task.wait(2)

				ShutdownPanel.Shutdown.Screen.Enabled = true
				ShutdownPanel.Shutdown.Error.Enabled = true
				ShutdownPanel.Shutdown.Error.TextLabel.Text = "ACCESS DENIED; X"
				Debounce.DebounceMain = false
			else
				Debounce.DebounceMain = true
				ShutdownPanel.Button.Err:Play()
				ShutdownPanel.Shutdown.Screen.Enabled = false
				ShutdownPanel.Shutdown.Error.Enabled = true
				ShutdownPanel.Shutdown.Error.TextLabel.Text = "ACCESS DENIED; PREREQUISITES NOT MET"

				task.wait(2)

				ShutdownPanel.Shutdown.Screen.Enabled = true
				ShutdownPanel.Shutdown.Error.Enabled = true
				ShutdownPanel.Shutdown.Error.TextLabel.Text = "ACCESS DENIED; X"
				Debounce.DebounceMain = false
			end
		else
			Network:Signal("Notification", Player, "You can only use this during the meltdown!", "error", 5)
		end
	end))
end

module.Functions = Functions

return module