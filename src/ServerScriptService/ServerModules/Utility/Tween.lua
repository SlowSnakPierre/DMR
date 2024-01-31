local module = {}
local Core = shared.Core
local Network = Core.Get("Network")

function module:Tween(InstanceToTween, ToCFrame, Time, Data)
	if InstanceToTween == nil then
		return
	end

	Network:SignalAll("Tween", InstanceToTween, ToCFrame, Time, Data)

	task.wait(Time)

	if InstanceToTween.PrimaryPart then
		InstanceToTween:SetPrimaryPartCFrame(ToCFrame)
	elseif InstanceToTween:IsA("BasePart") then
		InstanceToTween.CFrame = ToCFrame
	else
		print("Attempted to tween a non model Instance: ".. InstanceToTween:GetFullName())
	end
end

return module