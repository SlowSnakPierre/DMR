local module = {}
local Core = shared.Core
local Network = Core.Get("Network")
Network:Reserve({ "Tween", "RemoteEvent" })

function module:Tween(InstanceToTween, ToCFrame, Time, Data)
	task.spawn(function()
		local Ins

		if InstanceToTween == nil then
			return
		end

		if InstanceToTween:IsA("Model") then
			if InstanceToTween.PrimaryPart then
				Ins = InstanceToTween.PrimaryPart
			end
		else
			Ins = InstanceToTween
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
	end)
end

return module