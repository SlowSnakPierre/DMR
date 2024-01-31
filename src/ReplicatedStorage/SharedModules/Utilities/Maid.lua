local module = {}
module = {
	ClassName = "Maid", 
	new = function()
		return setmetatable({
			_tasks = {}
		}, module)
	end, 
	isMaid = function(Class)
		local isMaid = false
		if type(Class) == "table" then
			isMaid = Class.ClassName == "Maid"
		end
		return isMaid
	end, 
	__index = function(self, index)
		if module[index] then
			return module[index]
		end
		return self._tasks[index]
	end, 
	__newindex = function(self, index, value)
		if module[index] ~= nil then
			error(("'%s' is reserved"):format(tostring(index)), 2)
		end
		local tasks = self._tasks
		local Task = tasks[index]
		if Task == value then
			return
		end
		tasks[index] = value
		if Task then
			if type(Task) == "function" then
				Task()
				return
			end
			if typeof(Task) ~= "RBXScriptConnection" then
				if Task.Destroy then
					Task:Destroy()
				end
				return
			end
		else
			return
		end
		Task:Disconnect()
	end, 
	GiveTask = function(self, Task)
		if not Task then
			error("Task cannot be false or nil", 2)
		end
		if shared.Core.Get("Promise").is(Task) then
			task.spawn(function()
				local v4, v5 = Task:await()
				if v4 then
					self:GiveTask(v5)
				end
			end)
			return
		end
		local count = #self._tasks + 1
		self[count] = Task
		if type(Task) == "table" and not Task.Destroy then
			warn("[Maid.GiveTask] - Gave table task without .Destroy\n\n" .. debug.traceback())
		end
		return count
	end, 
	GivePromise = function(self, promise)
		local resolved = promise:resolved()
		local Task = self:GiveTask(resolved)
		resolved:Finally(function()
			self[Task] = nil
		end)
		return resolved
	end, 
	DoCleaning = function(self)
		local tasks = self._tasks
		for k, v in pairs(tasks) do
			if typeof(v) == "RBXScriptConnection" then
				tasks[k] = nil
				v:Disconnect()
			end
		end
		local idx, obj = next(tasks)
		while obj ~= nil do
			tasks[idx] = nil
			if type(obj) == "function" then
				obj()
			elseif typeof(obj) == "RBXScriptConnection" then
				obj:Disconnect()
			elseif obj.Destroy then
				obj:Destroy()
			end
			local newidx, newobj = next(tasks)
			idx = newidx
			obj = newobj		
		end
	end
}
module.Destroy = module.DoCleaning
return module
