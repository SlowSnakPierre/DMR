local module = {}
module.__index = module

local Maid = shared.Core.Get("Maid")

function module.new(Part, actionText, duration, maxActivationDistance)
	assert(Part:IsA("BasePart") or (Part:IsA("Model") and Part.PrimaryPart), "[Interaction] Argument 1 expected to be part/model.")
	assert(not actionText or type(actionText) == "string", "[Interaction] Argument 2 expected to be string.")
	assert(not duration or type(duration) == "number", "[Interaction] Argument 3 expected to be number.")
	local ProxPrompt = Instance.new("ProximityPrompt")
	ProxPrompt.Enabled = false
	ProxPrompt.Parent = Part:IsA("BasePart") and Part or Part.PrimaryPart
	ProxPrompt.RequiresLineOfSight = false
	ProxPrompt.ActionText = actionText or "Interact"
	ProxPrompt.MaxActivationDistance = maxActivationDistance or 10
	ProxPrompt.HoldDuration = duration or 0
	return setmetatable({
		Part = Part,
		Prompt = ProxPrompt,
		_Maid = Maid.new()
	}, module)
end

function module.SetAction(self, actionText)
	self.Prompt.ActionText = actionText
end

function module.ApplyConfig(self, actionText)
	assert(not actionText or type(actionText) == "string", "[Interaction] Argument 1 expected to be string.")
	self.Prompt.ActionText = actionText or self.Prompt.ActionText
end

function module.SetKeyboardActivation(self, key)
	self.Prompt.KeyboardKeyCode = key
end

function module.Disable(self)
	self.Prompt.Enabled = false
end

function module.Enable(self)
	self.Prompt.Enabled = true
end

function module.SetDuration(self, duration)
	self.Prompt.HoldDuration = duration
end

function module.Triggered(self, callback)
	local connexion = self.Prompt.Triggered:Connect(callback)
	self._Maid:GiveTask(connexion)
	return connexion
end

function module.HoldBegan(self, callback)
	self._Maid:GiveTask(self.Prompt.PromptButtonHoldBegan:Connect(callback))
end

function module.HoldEnded(self, callback)
	self._Maid:GiveTask(self.Prompt.PromptButtonHoldEnded:Connect(callback))
end

function module.Destroy(self)
	if not self.Destroyed then
		self.Prompt:Destroy()
		self._Maid:DoCleaning()
	end
end

return module