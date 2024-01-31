local module = {}
module.__index = module
module.ClassName = "Signal"

function module.new(bindable)
	local Class = setmetatable({}, module)
	Class._bindableEvent = Instance.new("BindableEvent")
	Class._argData = nil
	Class._argCount = nil
	if bindable ~= nil then
		Class._bindableEvent.Name = string.format("bindable:%s", bindable)
	end
	Class._source = ""
	return Class
end

function module.Fire(self, ...)
	if not self._bindableEvent then
		warn(("Signal is already destroyed. %s"):format(self._source))
		return
	end
	self._argData = { ... }
	self._argCount = select("#", ...)
	self._bindableEvent:Fire()
end

function module.Connect(self, callback)
	if type(callback) ~= "function" then
		error(("connect(%s)"):format((typeof(callback))), 2)
	end
	return self._bindableEvent.Event:Connect(function()
		callback(unpack(self._argData, 1, self._argCount))
	end)
end

function module.Wait(self)
	self._bindableEvent.Event:Wait()
	assert(self._argData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
	return unpack(self._argData, 1, self._argCount)
end

function module.Destroy(self)
	if self._bindableEvent then
		self._bindableEvent:Destroy()
		self._bindableEvent = nil
	end
	self._argData = nil
	self._argCount = nil
	setmetatable(self, nil)
end

return module