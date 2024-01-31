local module = {}

local Players = game:GetService("Players")

local function waitForEvents(...)
	local events = { ... }
	local Bindable = Instance.new("BindableEvent")
	local function onEventFired(...)
		for k = 1, #events do
			events[k]:Disconnect()
		end
		return Bindable:Fire(...)
	end
	for k = 1, #events do
		events[k] = events[k]:Connect(onEventFired)
	end
	return Bindable.Event:Wait()
end

function module.registerHumanoidReady(Callback)
	local function onCharacterReady(Player, Character)
		if not Character.Parent then
			waitForEvents(Character.AncestryChanged, Player.CharacterAdded)
		end
		if Player.Character ~= Character or not Character.Parent then
			return
		end
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		while Character:IsDescendantOf(game) and not Humanoid do
			waitForEvents(Character.ChildAdded, Character.AncestryChanged, Player.CharacterAdded)
			Humanoid = Character:FindFirstChildOfClass("Humanoid")		
		end
		if Player.Character ~= Character or not Character:IsDescendantOf(game) then
			return
		end
		local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
		while Character:IsDescendantOf(game) and not HumanoidRootPart do
			waitForEvents(Character.ChildAdded, Character.AncestryChanged, Humanoid.AncestryChanged, Player.CharacterAdded)
			HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")		
		end
		if HumanoidRootPart and Humanoid:IsDescendantOf(game) and Character:IsDescendantOf(game) and Player.Character == Character then
			Callback(Player, Character, Humanoid)
		end
	end
	local function onPlayerAdded(Player)
		local ancestryConn = nil
		local CharConn = Player.CharacterAdded:Connect(function(char)
			onCharacterReady(Player, char)
		end)
		ancestryConn = Player.AncestryChanged:Connect(function(_, parent)
			if not game:IsAncestorOf(parent) then
				ancestryConn:Disconnect()
				CharConn:Disconnect()
			end
		end)
		local Character = Player.Character
		if Character then
			onCharacterReady(Player, Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return module