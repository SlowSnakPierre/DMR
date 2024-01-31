local Core = shared.Core
local module = {}
module.__index = module
module.ClassName = "Binder"
local Maid = Core.Get("Maid", true)
local CollectionService = game:GetService("CollectionService")
local Signal = Core.Get("Signal", true)
local RunService = game:GetService("RunService")

function module.new(tagName, constructor)
	local Final = setmetatable({}, module)
	Final._maid = Maid.new()
	Final._tagName = tagName or error("Bad argument 'tagName', expected string")
	Final._constructor = constructor or error("Bad argument 'constructor', expected table or function")
	Final._instToClass = {}
	Final._allClassSet = {}
	Final._pendingInstSet = {}
	Final._listeners = {}
	delay(5, function()
		if not Final._loaded then
			warn("Binder is not loaded. Call :Init() on it!")
		end
	end)
	return Final
end

function module.isBinder(self)
	local isBinder = false
	if type(self) == "table" then
		isBinder = self.ClassName == "Binder"
	end
	return isBinder
end

function module.Init(Server)
	if Server._loaded then
		return
	end
	Server._loaded = true
	local BindableEvent = Instance.new("BindableEvent")
	for _, v in pairs(CollectionService:GetTagged(Server._tagName)) do
		local Connexion = BindableEvent.Event:Connect(function()
			if game.Players.LocalPlayer.Backpack:IsAncestorOf(v) or game.Players.LocalPlayer.Character:IsAncestorOf(v) then
				Server:_add(v)
			end
		end)
		BindableEvent:Fire()
		Connexion:Disconnect()
	end
	BindableEvent:Destroy()
	Server._maid:GiveTask(CollectionService:GetInstanceAddedSignal(Server._tagName):Connect(function(tool)
		if game.Players.LocalPlayer.Backpack:IsAncestorOf(tool) or game.Players.LocalPlayer.Character:IsAncestorOf(tool) then
			Server:_add(tool)
		end
	end))
	Server._maid:GiveTask(CollectionService:GetInstanceRemovedSignal(Server._tagName):Connect(function(tool)
		if game.Players.LocalPlayer.Backpack:IsAncestorOf(tool) or game.Players.LocalPlayer.Character:IsAncestorOf(tool) then
			Server:_remove(tool)
		end
	end))
end

function module.GetTag(self)
	return self._tagName
end

function module.GetConstructor(self)
	return self._constructor
end

function module.ObserveInstance(self, listeners, listenerss)
	self._listeners[listeners] = self._listeners[listeners] or {}
	self._listeners[listeners][listenerss] = true
	return function()
		if not self._listeners[listeners] then
			return
		end
		self._listeners[listeners][listenerss] = nil
		if not next(self._listeners[listeners]) then
			self._listeners[listeners] = nil
		end
	end
end

function module.GetClassAddedSignal(SignalClass)
	if SignalClass._classAddedSignal then
		return SignalClass._classAddedSignal
	end
	SignalClass._classAddedSignal = Signal.new("BinderClassAdded")
	SignalClass._maid:GiveTask(SignalClass._classAddedSignal)
	return SignalClass._classAddedSignal
end

function module.GetClassRemovingSignal(SignalClass)
	if SignalClass._classRemovingSignal then
		return SignalClass._classRemovingSignal
	end
	SignalClass._classRemovingSignal = Signal.new("BinderClassRemoving")
	SignalClass._maid:GiveTask(SignalClass._classRemovingSignal)
	return SignalClass._classRemovingSignal
end

function module.GetAll(Class)
	local Final = {}
	for k, _ in pairs(Class._allClassSet) do
		Final[#Final + 1] = k
	end
	return Final
end

function module.GetAllSet(Set)
	return Set._allClassSet
end

function module.Bind(self, callback)
	if RunService:IsClient() then
		warn(("[Binder.Bind] - Bindings '%s' done on the client! Will be disrupted upon server replication!"):format(self._tagName))
	end
	CollectionService:AddTag(callback, self._tagName)
	return self:Get(callback)
end

function module.Unbind(self, callback)
	assert(typeof(callback) == "Instance", "Error unbinding.")
	if RunService:IsClient() then
		warn(("[Binder.Bind] - Unbinding '%s' done on the client! Might be disrupted upon server replication!"):format(self._tagName))
	end
	CollectionService:RemoveTag(callback, self._tagName)
end

function module.BindClient(self, callback)
	if not RunService:IsClient() then
		warn(("[Binder.BindClient] - Bindings '%s' done on the server! Will be replicated!"):format(self._tagName))
	end
	CollectionService:AddTag(callback, self._tagName)
	return self:Get(callback)
end

function module.UnbindClient(self, inst)
	assert(typeof(inst) == "Instance", "Error unbinding client.")
	CollectionService:RemoveTag(inst, self._tagName)
end

function module.Get(self, inst)
	assert(typeof(inst) == "Instance", "Argument 'inst' is not an Instance")
	return self._instToClass[inst]
end

function module._add(self, inst)
	assert(typeof(inst) == "Instance", "Argument 'inst' is not an Instance")
	if self._instToClass[inst] then
		return
	end
	if self._pendingInstSet[inst] == true then
		warn("[Binder._add] - Reentered add. Still loading, probably caused by error in constructor.")
		return
	end
	self._pendingInstSet[inst] = true
	local constructor
	if type(self._constructor) == "function" then
		constructor = self._constructor(inst)
	elseif self._constructor.Create then
		constructor = self._constructor:Create(inst)
	else
		constructor = self._constructor.new(inst)
	end
	if self._pendingInstSet[inst] ~= true then
		warn(("[Binder._add] - Failed to load instance %q of %q, removed while loading!"):format(inst:GetFullName(), tostring(type(self._constructor) == "table" and self._constructor.ClassName or self._constructor)))
		return
	end
	self._pendingInstSet[inst] = nil
	if type(constructor) ~= "table" or type(constructor.Destroy) ~= "function" then
		warn(constructor)
		warn(("[Binder._add] - Bad class constructed for self %q"):format(self._tagName))
		return
	end
	assert(self._instToClass[inst] == nil, "Overwrote")
	self._allClassSet[constructor] = true
	self._instToClass[inst] = constructor
	local listeners = self._listeners[inst]
	if listeners then
		local BindableEvent = Instance.new("BindableEvent")
		for k, _ in pairs(listeners) do
			local Connexion = BindableEvent.Event:Connect(function()
				k(constructor)
			end)
			BindableEvent:Fire()
			Connexion:Disconnect()
		end
		BindableEvent:Destroy()
	end
	if self._classAddedSignal then
		self._classAddedSignal:Fire(constructor, inst)
	end
end

function module._remove(self, inst)
	self._pendingInstSet[inst] = nil
	local Class = self._instToClass[inst]
	if Class == nil then
		return
	end
	if self._classRemovingSignal then
		self._classRemovingSignal:Fire(Class, inst)
	end
	self._instToClass[inst] = nil
	self._allClassSet[Class] = nil
	local listeners = self._listeners[inst]
	if listeners then
		local BindableEvent = Instance.new("BindableEvent")
		for func, _ in pairs(listeners) do
			local Connexion = BindableEvent.Event:Connect(function()
				func(nil)
			end)
			BindableEvent:Fire()
			Connexion:Disconnect()
		end
		BindableEvent:Destroy()
	end
	if Class.Destroy then
		Class:Destroy()
		return
	end
	warn(("[Binder._remove] - Class %q no longer has destroy, something destroyed it!"):format(tostring(self._tagName)))
end

function module.Destroy(self)
	local Idx, Class = next(self._instToClass)
	while Class ~= nil do
		self:_remove(Class)
		assert(self._instToClass[Idx] == nil, "Error destroying binder.")
		local idx, class = next(self._instToClass)
		Idx = idx
		Class = class	
	end
	self._maid:DoCleaning()
end

return module