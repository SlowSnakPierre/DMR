local module = {
	ClassName = "Promise"
}
module.__index = module
local fastSpawn = shared.Core.Get("fastSpawn", true)
local promiseResolved = nil
local promiseRejected = nil
local RunService = game:GetService("RunService")


function module.isPromise(self)
	local isPromise = false
	if type(self) == "table" then
		isPromise = self.ClassName == "Promise"
	end
	return isPromise
end

function module.new(callback)
	local self = setmetatable({
		_pendingExecuteList = {}, 
		_unconsumedException = true, 
		_source = ""
	}, module)
	if type(callback) == "function" then
		callback(self:_getResolveReject())
	end
	return self
end

function module.spawn(self)
	local promise = module.new()
	fastSpawn(self, promise:_getResolveReject())
	return promise
end

function module.resolved(...)
	local selected = select("#", ...)
	if selected == 0 then
		return promiseResolved
	end
	if selected == 1 then
		local args = ...
		local isPromise = false
		if type(args) == "table" then
			isPromise = args.ClassName == "Promise"
		end
		if isPromise then
			local args = ...
			if not args._pendingExecuteList then
				return args
			end
		end
	end
	local promise = module.new()
	promise:Resolve(...)
	return promise
end

function module.rejected(...)
	local selected = select("#", ...)
	if selected == 0 then
		return promiseRejected
	end
	local promise = module.new()
	promise:_reject({ ... }, selected)
	return promise
end

function module.IsPending(self)
	return self._pendingExecuteList ~= nil
end

function module.IsFulfilled(self)
	return self._fulfilled ~= nil
end

function module.IsRejected(self)
	return self._rejected ~= nil
end

function module.Wait(self)
	if self._fulfilled then
		return unpack(self._fulfilled, 1, self._valuesLength)
	end
	if self._rejected then
		return error(tostring(self._rejected[1]), 2)
	end
	local Bind = Instance.new("BindableEvent")
	self:Then(function()
		Bind:Fire()
	end, function()
		Bind:Fire()
	end)
	Bind.Event:Wait()
	Bind:Destroy()
	if not self._rejected then
		return unpack(self._fulfilled, 1, self._valuesLength)
	end
	return error(tostring(self._rejected[1]), 2)
end

function module.Yield(self)
	if self._fulfilled then
		return true, unpack(self._fulfilled, 1, self._valuesLength)
	end
	if self._rejected then
		return false, unpack(self._rejected, 1, self._valuesLength)
	end
	local Bind = Instance.new("BindableEvent")
	self:Then(function()
		Bind:Fire()
	end, function()
		Bind:Fire()
	end)
	Bind.Event:Wait()
	Bind:Destroy()
	if self._fulfilled then
		return true, unpack(self._fulfilled, 1, self._valuesLength)
	end
	if not self._rejected then
		return
	end
	return false, unpack(self._rejected, 1, self._valuesLength)
end

function module.Resolve(self, ...)
	if not self._pendingExecuteList then
		return
	end
	local selected = select("#", ...)
	if selected == 0 then
		self:_fulfill({}, 0)
		return
	end
	if self == ... then
		self:Reject("TypeError: Resolved to self")
		return
	end
	local args = ...
	local isPromise = false
	if type(args) == "table" then
		isPromise = args.ClassName == "Promise"
	end
	if not isPromise then
		if type((...)) == "function" then
			if selected > 1 then
				warn((("When resolving a function, extra arguments are discarded! See:\n\n%s"):format(self._source)))
			end
			({ ... })(self:_getResolveReject())
			return
		else
			self:_fulfill({ ... }, selected)
			return
		end
	end
	if selected > 1 then
		warn((("When resolving a promise, extra arguments are discarded! See:\n\n%s"):format(self._source)))
	end
	local args = ...
	if args._pendingExecuteList then
		args._unconsumedException = false
		local Functions = {}
		Functions[1] = function(...)
			self:Resolve(...)
		end
		Functions[2] = function(...)
			if self._pendingExecuteList then
				self:_reject({ ... }, select("#", ...))
			end
		end
		Functions[3] = nil
		args._pendingExecuteList[#args._pendingExecuteList + 1] = Functions
		return
	end
	if args._rejected then
		args._unconsumedException = false
		self:_reject(args._rejected, args._valuesLength)
		return
	end
	if not args._fulfilled then
		error("[Promise.Resolve] - Bad promise2 state")
		return
	end
	self:_fulfill(args._fulfilled, args._valuesLength)
end

function module._fulfill(self, fulfilled, valueLength)
	if not self._pendingExecuteList then
		return
	end
	self._fulfilled = fulfilled
	self._valuesLength = valueLength
	for _, v in pairs(self._pendingExecuteList) do
		self:_executeThen(unpack(v))
	end
	self._pendingExecuteList = nil
end

function module.Reject(self, ...)
	self:_reject({ ... }, select("#", ...))
end

function module._reject(self, rejected, valueLength)
	if not self._pendingExecuteList then
		return
	end
	self._rejected = rejected
	self._valuesLength = valueLength
	for _, v in pairs(self._pendingExecuteList) do
		self:_executeThen(unpack(v))
	end
	self._pendingExecuteList = nil
	if self._unconsumedException and self._valuesLength > 0 then
		coroutine.resume(coroutine.create(function()
			RunService.Heartbeat:Wait()
			if self._unconsumedException then
				warn(("[Promise] - Uncaught exception in promise: %q"):format(tostring(self._rejected[1])))
			end
		end))
	end
end

function module.Then(self, value, callback)
	if type(callback) == "function" then
		self._unconsumedException = false
	end
	if not self._pendingExecuteList then
		return self:_executeThen(value, callback, nil)
	end
	local promise = module.new()
	self._pendingExecuteList[#self._pendingExecuteList + 1] = { value, callback, promise }
	return promise
end

function module.Tap(self, value, callback)
	local Result = self:Then(value, callback)
	if Result == self then
		return Result
	end
	if Result._fulfilled then
		return self
	end
	if Result._rejected then
		return self
	end
	if not Result._pendingExecuteList then
		error("Bad result state")
		return
	end
	local function returnval()
		return self
	end
	return Result:Then(returnval, returnval)
end

function module.Finally(self, callback)
	return self:Then(callback, callback)
end

function module.Catch(self, callback)
	return self:Then(nil, callback)
end

function module.Destroy(self)
	self:_reject({}, 0)
end

function module.GetResults(self)
	if self._rejected then
		return false, unpack(self._rejected, 1, self._valuesLength)
	end
	if not self._fulfilled then
		error("Still pending")
		return
	end
	return true, unpack(self._fulfilled, 1, self._valuesLength)
end

function module._getResolveReject(self)
	return function(...)
		self:Resolve(...)
	end, function(...)
		self:_reject({ ... }, select("#", ...))
	end
end

function module._executeThen(self, callback1, callback2, callback3)
	if self._fulfilled then
		if type(callback1) == "function" then
			if callback3 then
				callback3:Resolve(callback1(unpack(self._fulfilled, 1, self._valuesLength)))
				return callback3
			else
				local args = table.pack(callback1(unpack(self._fulfilled, 1, self._valuesLength)))
				if args.n == 0 then
					return promiseResolved
				elseif args.n == 1 then
					local arg = args[1]
					local isPromise = false
					if type(arg) == "table" then
						isPromise = arg.ClassName == "Promise"
					end
					if isPromise then
						return args[1]
					else
						local promise = module.new()
						promise:Resolve(table.unpack(args, 1, args.n))
						return promise
					end
				else
					local promise = module.new()
					promise:Resolve(table.unpack(args, 1, args.n))
					return promise
				end
			end
		elseif callback3 then
			callback3:_fulfill(self._fulfilled, self._valuesLength)
			return callback3
		else
			return self
		end
	end
	if not self._rejected then
		error("Internal error: still pending")
		return
	end
	if type(callback2) ~= "function" then
		if callback3 then
			callback3:_reject(self._rejected, self._valuesLength)
			return callback3
		else
			return self
		end
	end
	if callback3 then
		callback3:Resolve(callback2(unpack(self._rejected, 1, self._valuesLength)))
		return callback3
	end
	local args = table.pack(callback2(unpack(self._rejected, 1, self._valuesLength)))
	if args.n == 0 then
		return promiseResolved
	end
	if args.n == 1 then
		local arg1 = args[1]
		local isPromise = false
		if type(arg1) == "table" then
			isPromise = arg1.ClassName == "Promise"
		end
		if isPromise then
			return args[1]
		end
	end
	local promise = module.new()
	promise:Resolve(table.unpack(args, 1, args.n))
	return promise
end

promiseResolved = module.new()
promiseResolved:_fulfill({}, 0)
promiseRejected = module.new()
promiseRejected:_reject({}, 0)

return module