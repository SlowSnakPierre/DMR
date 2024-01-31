local module = {}
local Players = game:GetService("Players")
local Core = shared.Core
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local Signal = Core.Get("Signal")
local UserInputService = game:GetService("UserInputService")
local Network = Core.Get("Network")
local ProximityPromptService = game:GetService("ProximityPromptService")

function module.GetLocalPlayerHeadShot(self, ThumbnailType, ThumbnailSize)
	local thumb, success = Players:GetUserThumbnailAsync(LocalPlayer.UserId, ThumbnailType or Enum.ThumbnailType.HeadShot, ThumbnailSize or Enum.ThumbnailSize.Size420x420)
	if success then
		return thumb
	end
	return ""
end

function module.SetPrompts(self, enabled)
	ProximityPromptService.Enabled = enabled
end

function module.SetCore(self, enabled)
	StarterGui:SetCoreGuiEnabled("Chat", enabled)
	StarterGui:SetCoreGuiEnabled("EmotesMenu", enabled)
	StarterGui:SetCoreGuiEnabled("Health", enabled)
end

function module.IsMobile()
	return module.isUsingTouch
end

function module.IsXbox()
	return GuiService:IsTenFootInterface()
end

function module.IsGamepad()
	return module.isUsingGamepad
end

function module.IsGamepadInput(self, GameInput)
	local Input = GameInput and string.sub(GameInput.Name, 0, 7) == "Gamepad"
	return Input
end

function module.Init()
	module.UsingGamepadChanged = Signal.new("UsingGamepadChanged")
	module.UsingTouchChanged = Signal.new("UsingTouchChanged")
	module.isUsingTouch = not UserInputService.KeyboardEnabled and UserInputService.TouchEnabled
	module.lastUsedGamepad = Enum.UserInputType.Gamepad1
	module.isUsingGamepad = module:IsXbox() or module:IsGamepadInput(UserInputService:GetLastInputType())
	UserInputService.LastInputTypeChanged:Connect(function(input)
		local isTouch = input == Enum.UserInputType.Touch
		if module.isUsingTouch ~= isTouch then
			module.isUsingTouch = isTouch
			module.UsingTouchChanged:Fire(isTouch)
		end
		local isGamepadInput = module:IsGamepadInput(input)
		module.lastUsedGamepad = input
		if module.isUsingGamepad ~= isGamepadInput then
			module.UsingGamepadChanged:Fire(isGamepadInput)
			module.isUsingGamepad = isGamepadInput
		end
	end)
	if module:IsXbox() then
		--Network:Signal("RequestXbox")
	end
end

return module