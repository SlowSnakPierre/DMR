local module = {}
local SignalProvider = {}
local Signal = shared.Core.Get("Signal", true)

function module.Get(self, callback)
	return SignalProvider[callback] or self:_Register(callback)
end

function module.Remove(self, SignalName)
	if SignalProvider[SignalName] == nil then
		return warn(string.format("SignalProvider with name %s has not been registered!", SignalName))
	end
	SignalProvider[SignalName]:Destroy()
	SignalProvider[SignalName] = nil
end

function module._Register(self, SignalName)
	if SignalProvider[SignalName] then
		return warn(string.format("SignalProvider with name %s has already been registered!", SignalName))
	end
	local NewSignal = Signal.new()
	NewSignal._bindableEvent.Name = string.format("ev:%s", SignalName)
	SignalProvider[SignalName] = NewSignal
	return NewSignal
end

return module