local Scheduler = {}
Scheduler.__index = Scheduler
local Core = shared.Core

local RunService = game:GetService("RunService")

local Signal = Core.Get("Signal")
local Maid = Core.Get("Maid")

function Scheduler.new(loopTime)
	local self = setmetatable({
		LoopTime = loopTime, 
		Signal = Signal.new("SchedulerSignal"), 
		Elapsed = 0, 
		Maid = Maid.new()
	}, Scheduler)
	self.Maid:GiveTask(self.Signal)
	return self
end


function Scheduler.Start(self)
	self.Maid:GiveTask(RunService.Heartbeat:Connect(function()
		if self.LoopTime < tick() - self.Elapsed then
			self.Elapsed = tick()
			self.Signal:Fire()
		end
	end))
end

function Scheduler.Tick(self, callback)
	return self.Signal:Connect(callback)
end

function Scheduler.Destroy(self)
	self.Maid:DoCleaning()
end

return Scheduler
