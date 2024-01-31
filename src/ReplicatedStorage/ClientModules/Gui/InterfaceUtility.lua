local module = {
	Cache = {}
}
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = game:GetService("Players").LocalPlayer

function module.TweenTransparency(self, guiObject, show, tweenTime, isCallbackNeeded, callback)
	if isCallbackNeeded or not self.Cache[guiObject] then
		local originalTransparency = {}
		if guiObject.ClassName:match("Image") then
			originalTransparency.ImageTransparency = guiObject.ImageTransparency
		end
		if guiObject.ClassName:match("Text") and not guiObject:IsA("UITextSizeConstraint") then
			originalTransparency.TextTransparency = guiObject.TextTransparency
		end
		if isCallbackNeeded or guiObject:IsA("GuiObject") and guiObject.BackgroundTransparency ~= 1 then
			originalTransparency.BackgroundTransparency = guiObject.BackgroundTransparency
		end
		if guiObject:IsA("ScrollingFrame") then
			originalTransparency.ScrollBarImageTransparency = guiObject.ScrollBarImageTransparency
		end
		if guiObject:IsA("UIStroke") then
			originalTransparency.Transparency = guiObject.Transparency
		end
		if originalTransparency ~= {} then
			self.Cache[guiObject] = originalTransparency
		end
	end
	local cachedTransparency = self.Cache[guiObject]
	if cachedTransparency then
		local targetTransparency
		if show ~= "Show" then
			local tweenTransparency = {}
			for k, _ in next, cachedTransparency do
				tweenTransparency[k] = show
			end
			targetTransparency = tweenTransparency or cachedTransparency
		else
			targetTransparency = cachedTransparency
		end
		local tween = TweenService:Create(guiObject, TweenInfo.new(tweenTime and 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), targetTransparency)
		tween:Play()
		if typeof(callback) == "function" then
			tween.Completed:Connect(callback)
		end
	end
end

function module.RecurseTransparency(self, guiObject, show, tweenTime)
	self:TweenTransparency(guiObject, show, tweenTime)
	for _, child in pairs(guiObject:GetChildren()) do
		self:RecurseTransparency(child, show, tweenTime)
	end
end

function module.SlowTopLevelTransparency(self, gui, show, tweenTime)
	for _, guiObject in pairs(gui:GetChildren()) do
		self:TweenTransparency(guiObject, show, tweenTime)
		wait(0.05)
	end
end

function module.RecurseSlowTopLevelTransparency(self, guiObject, show, tweenTime)
	self:TweenTransparency(guiObject, show, tweenTime)
	for _, v in pairs(guiObject:GetChildren()) do
		self:RecurseTransparency(v, show, tweenTime)
		wait(0.05)
	end
end

function module.Blur(self, blurSize, tweenTime, showOrHide)
	if showOrHide == "Show" then
		Lighting:WaitForChild("MenuBlur").Enabled = true
	end
	TweenService:Create(Lighting:WaitForChild("MenuBlur"), TweenInfo.new(tweenTime and 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = blurSize
	}):Play()
	if showOrHide == "Hide" then
		wait(tweenTime)
		Lighting:WaitForChild("MenuBlur").Enabled = false
	end
end

function module.MouseEntered(self, guiObjects, onMouseEnter)
	for index, guiObject in pairs(guiObjects) do
		if guiObject:IsA("ImageButton") or guiObject:IsA("TextButton") then
			guiObject.MouseEnter:Connect(function()
				local success, error = pcall(onMouseEnter, guiObject)
				if not success then
					warn("[Utility:MouseEntered]", error)
				end
			end)
		end
	end
end

function module.MouseLeft(self, guiObjects, onMouseLeave)
	for index, guiObject in pairs(guiObjects) do
		if guiObject:IsA("ImageButton") or guiObject:IsA("TextButton") then
			guiObject.MouseLeave:Connect(function()
				local success, error = pcall(onMouseLeave, guiObject)
				if not success then
					warn("[Utility:MouseLeft]", error)
				end
			end)
		end
	end
end

function module._AncestorsVisible(self, guiObject)
	local parent = guiObject.Parent
	if parent:IsA("ScreenGui") and parent.Enabled then
		return true
	end
	if not parent:IsA("GuiBase2d") or not parent.Visible then
		return false
	end
	return self:_AncestorsVisible(parent)
end

function module.IsVisible(self, guiObject)
	if guiObject:IsDescendantOf(LocalPlayer.PlayerGui) and guiObject:IsA("GuiBase2d") then
		if guiObject:IsA("ScreenGui") and guiObject.Enabled then
			return true
		end
		if guiObject.Visible then
			local ViewportSize = workspace.CurrentCamera.ViewportSize
			local Mid = guiObject.AbsolutePosition + guiObject.AbsoluteSize * guiObject.AnchorPoint
			if Mid.X > 0 and Mid.X < ViewportSize.X and Mid.Y > 0 and Mid.Y < ViewportSize.Y then
				return module:_AncestorsVisible(guiObject)
			end
		end
	end
	return false
end

return module