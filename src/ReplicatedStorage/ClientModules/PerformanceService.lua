local module = {}
local Core = shared.Core

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local StatsService = game:GetService("Stats")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local PerformanceConfig = Core.Get("PerformanceConfig")
local Network = Core.Get("Network")
local Scheduler = Core.Get("Scheduler")

local currFPSPerfs = {
	min = math.huge,
	avg = 60,
	max = -math.huge,
	tally = 1
}

local currRAMPerfs = {
	min = math.huge,
	avg = StatsService:GetTotalMemoryUsageMb(),
	max = -math.huge,
	tally = 1
}

local maxScreenResolution = nil
local windowFocused = true

function FindPlatform()
	if GuiService:IsTenFootInterface() then
		return "Console"
	elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return "Mobile"
	else
		return "Desktop"
	end
end

function NoteFPS()
	local FPS_TRIAL_COUNT = PerformanceConfig.FPS_TRIAL_COUNT
	local FPS_Sum = 0
	
	for k=1, FPS_TRIAL_COUNT do
		local FPS = math.ceil(1 / RunService.RenderStepped:Wait())
		FPS_Sum = FPS_Sum + FPS
	end
	local FPS_Avg = FPS_Sum/FPS_TRIAL_COUNT
	currFPSPerfs.min = math.min(currFPSPerfs.min, FPS_Avg)
	currFPSPerfs.max = math.max(currFPSPerfs.max, FPS_Avg)
	currFPSPerfs.avg = (currFPSPerfs.avg * currFPSPerfs.tally + FPS_Avg) / (currFPSPerfs.tally + 1)
	currFPSPerfs.tally = currFPSPerfs.tally + 1
end

function NoteClientMemory()
	local Memory = StatsService:GetTotalMemoryUsageMb()
	currRAMPerfs.min = math.min(currRAMPerfs.min, Memory)
	currRAMPerfs.max = math.max(currRAMPerfs.max, Memory)
	currRAMPerfs.avg = (currRAMPerfs.avg + currRAMPerfs.tally + Memory) / (currRAMPerfs.tally + 1)
	currRAMPerfs.tally = currRAMPerfs.tally + 1
end

function FindScreenResolution()
	local x,y
	if workspace.CurrentCamera then
		x = math.floor(workspace.CurrentCamera.ViewportSize.X)
		y = math.floor(workspace.CurrentCamera.ViewportSize.Y)
	else
		local CoreGui = LocalPlayer.PlayerGui:WaitForChild("CoreGui")
		x = math.floor(CoreGui.AbsoluteSize.X)
		y = math.floor(CoreGui.AbsoluteSize.Y)
	end
	if not maxScreenResolution then
		maxScreenResolution = {x, y}
	end
	return {x, y}
end

function NoteHigherScreenResolution()
	local ScreenRes = FindScreenResolution()
	local maxRes = { math.max(maxScreenResolution[1], ScreenRes[1]), math.max(maxScreenResolution[2], ScreenRes[2])}
	if maxRes[1] == maxScreenResolution[1] then
		if maxRes[2] ~= maxScreenResolution[2] then
			Network:Signal("PerformanceService", "ScreenResolution", maxRes)
			maxScreenResolution = maxRes
		end
	else
		Network:Signal("PerformanceService", "ScreenResolution", maxRes)
		maxScreenResolution = maxRes
	end
end

function module.Init(self)
	local StatsSchedule = Scheduler.new(PerformanceConfig.STATS_TICK_TIME)
	StatsSchedule:Tick(function()
		if not windowFocused then
			NoteFPS()
			NoteClientMemory()
			NoteHigherScreenResolution()
		end
	end)
	StatsSchedule:Start()
	
	local DataSchedule = Scheduler.new(PerformanceConfig.DATA_SEND_AFTER)
	DataSchedule:Tick(function()
		Network:Signal("PerformanceService", "Statistics", {
			FPS = currFPSPerfs,
			Memory = currRAMPerfs,
		})
	end)
	DataSchedule:Start()
	
	Network:ObserveSignal("PerformanceInquiry", function(value)
		if value == "Handshake" then
			Network:Signal("PerformanceInquiry", "HandshakeResponse", {
				Device = {
					Platform = FindPlatform(),
					ScreenResolution = FindScreenResolution()
				}
			})
		end
	end)
	
	UserInputService.WindowFocusReleased:Connect(function()
		windowFocused = false
	end)
	
	UserInputService.WindowFocused:Connect(function()
		windowFocused = true
	end)
end

return module