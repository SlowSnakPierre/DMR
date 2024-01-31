local module = {
	ClassName = "BinderProvider"
}
module.__index = module
local PromiseLegacy = shared.Core.Get("PromiseLegacy", true)

function module.new(initMethod)
	local Final = setmetatable({}, module)
	Final.BindersAddedPromise = PromiseLegacy.new()
	Final.AfterInitPromise = PromiseLegacy.new()
	Final._initMethod = initMethod or error("No initMethod")
	Final._afterInit = false
	Final._binders = {}
	return Final
end

function module.PromiseBinder(self, Promise)
	if not self.BindersAddedPromise:IsFulfilled() then
		return self.BindersAddedPromise:Then(function()
			local promise = self:Get(Promise)
			if promise then
				return promise
			end
			return PromiseLegacy.rejected()
		end)
	end
	local promise = self:Get(Promise)
	if not promise then
		return PromiseLegacy.rejected()
	end
	return PromiseLegacy.resolved(promise)
end

function module.Init(self)
	self:_initMethod(self)
	self.BindersAddedPromise:Resolve()
end

function module.AfterInit(self)
	self._afterInit = true
	for _, v in pairs(self._binders) do
		v:Init()
	end
	self.AfterInitPromise:Resolve()
end

function module.__index(self, index)
	if module[index] then
		return module[index]
	end
	error(("%q Not a valid index"):format(tostring(index)))
end

function module.Get(self, tagName)
	assert(type(tagName) == "string", "tagName must be a string")
	return rawget(self, tagName)
end

function module.Add(self, binder)
	assert(not self._afterInit, "Already inited")
	assert(not self:Get(binder:GetTag()), "Error with adding binder.")
	table.insert(self._binders, binder)
	self[binder:GetTag()] = binder
end

return module
