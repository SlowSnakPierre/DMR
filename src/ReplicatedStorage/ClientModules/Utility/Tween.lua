local module = {}
local Core = shared.Core
local Network = Core.Get("Network")
local TweenService = game:GetService("TweenService")

local Mode = "Tween"
local Style = Enum.EasingStyle.Sine
local Direction = Enum.EasingDirection.InOut

local function Move(Model, ToCFrame, TimeOfDelay, Skip)
	if Model.PrimaryPart ~= nil then
		if Skip then
			if Skip == true then
				task.wait(TimeOfDelay)

				Model:SetPrimaryPartCFrame(ToCFrame)

				return
			end
		end

		if Mode == "Fast" then
			task.wait(TimeOfDelay)

			Model:SetPrimaryPartCFrame(ToCFrame)
		elseif Mode == "Tween" then
			local CFrameValue = Instance.new("CFrameValue")
			CFrameValue.Value = Model:GetPrimaryPartCFrame()

			CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
				Model:SetPrimaryPartCFrame(CFrameValue.Value)
			end)

			local TweenInfoForTween = TweenInfo.new(TimeOfDelay, Style, Direction)
			local Tween = TweenService:Create(CFrameValue, TweenInfoForTween, { Value = ToCFrame })

			Tween:Play()

			local Self
			Self = Tween.Completed:Connect(function()
				CFrameValue:Destroy()
				Self:Disconnect()
			end)

			task.wait(TimeOfDelay)
		end
	end
end

function module:Init()
	Network:ObserveSignal("Tween", function(InstanceToTween, ToCFrame, Time, Data)
		if type(Data) == "table" then
			Style = Data.Style
			Direction = Data.Direction
		else
			Style = Enum.EasingStyle.Sine
			Direction = Enum.EasingDirection.InOut
		end

		if InstanceToTween ~= nil then
			Move(InstanceToTween, ToCFrame, Time)
		end
	end)

	Network:ObserveSignal("TweenIns", function(Inst, Value, To, Time, Style, Direction)
		if Inst ~= nil then
			local Tween = TweenService:Create(
				Inst,
				TweenInfo.new(Time, Enum.EasingStyle[tostring(Style)], Enum.EasingDirection[tostring(Direction)]),
				{ [Value] = To }
			)

			Tween:Play()
		end
	end)
end

return module