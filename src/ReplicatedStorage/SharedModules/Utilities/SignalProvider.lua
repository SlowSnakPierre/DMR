local module = {}
local SignalProvider = {}
local Signal = shared.Core.Get("Signal", true)

function module.Get(self, callback)
	local SignalType = string.match(callback, "Function") and "BindableFunction" or "BindableEvent"
	return SignalProvider[callback] or self:_Register(callback, SignalType)
end

function module.Remove(self, SignalName)
	if SignalProvider[SignalName] == nil then
		return warn(string.format("SignalProvider with name %s has not been registered!", SignalName))
	end
	SignalProvider[SignalName]:Destroy()
	SignalProvider[SignalName] = nil
end

function module._Register(self, SignalName, SignalType)
	if SignalProvider[SignalName] then
		return warn(string.format("SignalProvider with name %s has already been registered!", SignalName))
	end
	local NewSignal = Signal.new(SignalName, SignalType)
	SignalProvider[SignalName] = NewSignal
	return NewSignal
end

return module