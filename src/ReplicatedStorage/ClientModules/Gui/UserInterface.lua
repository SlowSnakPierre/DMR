local module = {}
local Frames = {}
local InterfaceShowSignals = {}
local InterfaceHideSignals = {}
local loaded = {}
local cachedModules = {}
local Core = shared.Core
local LocalPlayer = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")
local CoreGui = LocalPlayer.PlayerGui:WaitForChild("CoreGui", 100)
local CollectionService = game:GetService("CollectionService")
local PreferenceClient = Core.Get("PreferenceClient")
local ClientUtility = Core.Get("ClientUtility")
local Signal = Core.Get("Signal")

function module._Import(self, module)
	if not loaded[module] then
		loaded[module] = true
		local InterfaceModule = script.InterfaceModules:FindFirstChild(module.Name)
		if InterfaceModule then
			local TookTime = false
			local startTime = tick()
			local success = nil
			local Functions = nil
			task.spawn(function()
				success, Functions = pcall(require, InterfaceModule)
			end)
			while success == nil do
				if tick() - startTime > 10 and not TookTime then
					warn(string.format("[UI::Danger] Importing %s is taking a dangerous amount of time!", InterfaceModule.Name))
					TookTime = true
				end
				task.wait()			
			end
			if TookTime then
				warn(string.format("[UI::Undanger] %s has finished require. Took %s!", InterfaceModule.Name, tick() - startTime))
			end
			if success then
				cachedModules[module.Name] = Functions
				print(("[Core] [User Interface] Interface module '%s' has successfully loaded"):format(module.Name))
				if type(Functions) == "table" and Functions.Init then
					local TookTime = false
					local startTime = tick()
					local success = nil
					local errmessage = nil
					task.spawn(function()
						success, errmessage = pcall(Functions.Init, Functions)
					end)
					while success == nil do
						if tick() - startTime > 10 and not TookTime then
							warn(string.format("[UI::Danger] %s is taking a long time to initialise!", InterfaceModule.Name))
							TookTime = true
						end
						task.wait()					
					end
					if TookTime then
						warn(string.format("[UI::Undanger] %s has finished initialising. Took %s!", InterfaceModule.Name, tick() - startTime))
					end
					if not success then
						warn(("[Core] [User Interface] Module %s failed to load!\n%s"):format(module.Name, errmessage))
					end
				end
			else
				warn("[UserInterface] Failed to require CoreGui module: " .. module.Name)
			end
		end
	end
end

function module.Init(module)
	StarterGui:SetCoreGuiEnabled("PlayerList", false)
	for _, v in pairs(CoreGui:GetChildren()) do
		task.spawn(function()
			module:_Import(v)
		end)
	end
	local HUD = module:GetFrame("HUD")
	local function Rescale(Xbox)
		local Position
		if Xbox then
			Position = 0.385
		else
			Position = 0.121
		end
		HUD.Controls.Position = UDim2.fromScale(0.012, Position)
	end
	LocalPlayer:GetAttributeChangedSignal("InMenu"):Connect(function()
		if LocalPlayer:GetAttribute("InMenu") then
			Rescale(false)
			return
		end
		task.wait(0.75)
	end)
	LocalPlayer.PlayerGui.DescendantAdded:Connect(function(descendant)
		local Attribute = descendant:GetAttribute("Xbox")
		if Attribute == true then
			CollectionService:AddTag(descendant, "XboxShow")
			return
		end
		if Attribute == false then
			CollectionService:AddTag(descendant, "XboxHide")
		end
	end)
	for _, v in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
		local Attribute = v:GetAttribute("Xbox")
		if Attribute == true then
			CollectionService:AddTag(v, "XboxShow")
		elseif Attribute == false then
			CollectionService:AddTag(v, "XboxHide")
		end
	end
	CollectionService:GetInstanceAddedSignal("XboxShow"):Connect(function(value)
		value.Visible = ClientUtility.isUsingGamepad
	end)
	CollectionService:GetInstanceAddedSignal("XboxHide"):Connect(function(value)
		value.Visible = not ClientUtility.isUsingGamepad
	end)
	local function UpdateXbox(value)
		for k, v in pairs(CollectionService:GetTagged("XboxShow")) do
			v.Visible = value
		end
		for k, v in pairs(CollectionService:GetTagged("XboxHide")) do
			v.Visible = not value
		end
	end
	ClientUtility.UsingGamepadChanged:Connect(UpdateXbox)
	UpdateXbox(ClientUtility.isUsingGamepad)
end

function module.GetFrame(self, FrameName)
	return CoreGui:FindFirstChild(FrameName)
end

function module.HideAll()
	CoreGui.Enabled = false
end

function module.ShowAll()
	CoreGui.Enabled = true
end

function module.Get(self, moduleName, load)
	if cachedModules[moduleName] then
		return cachedModules[moduleName]
	end
	if not load then
		local startTime = tick()
		print(("[UserInterface] Yielding for module '%s'."):format(moduleName))
		while true do
			task.wait()
			if tick() - startTime > 10 then
				warn("[UserInterface] "..moduleName.." took too much times, so not loaded !")
				break
			end
			if cachedModules[moduleName] then
				break
			end
		end
		if cachedModules[moduleName] then
			return cachedModules[moduleName]
		end
	end
end

function module.Show(self, FrameName, Hide)
	local Frame = module:GetFrame(FrameName)
	if Frame then
		local MODULE = module:Get(FrameName, true)
		if MODULE and typeof(MODULE) == "table" and MODULE._CoreShow then
			task.spawn(function()
				local success, msg = pcall(MODULE._CoreShow)
				if not success then
					warn("_CoreShow Failed!", msg)
				end
			end)
		else
			Frame.Visible = true
		end
		if Hide then
			for _, v in pairs(Frames) do
				if v ~= FrameName then
					module:Hide(v)
				end
			end
			if not table.find(Frames, FrameName) then
				table.insert(Frames, FrameName)
			end
		end
		if InterfaceShowSignals[FrameName] then
			InterfaceShowSignals[FrameName]:Fire()
		end
	end
end

function module.Hide(self, FrameName)
	local Frame = module:GetFrame(FrameName)
	if Frame then
		local MODULE = module:Get(FrameName, true)
		if MODULE and typeof(MODULE) == "table" and MODULE._CoreHide then
			task.spawn(function()
				pcall(MODULE._CoreHide)
			end)
		else
			Frame.Visible = false
		end
		if table.find(Frames, FrameName) then
			table.remove(Frames, table.find(Frames, FrameName))
		end
		if InterfaceHideSignals[FrameName] then
			InterfaceHideSignals[FrameName]:Fire()
		end
	end
end

function module.IsMainOpen()
	return #Frames > 0
end

function module.GetInterfaceShownSignal(self, FrameName)
	if not module:GetFrame(FrameName) then
		return
	end
	if InterfaceShowSignals[FrameName] == nil then
		InterfaceShowSignals[FrameName] = Signal.new("InterfaceShowSignal")
	end
	return InterfaceShowSignals[FrameName]
end

function module.GetInterfaceHiddenSignal(self, FrameName)
	if not module:GetFrame(FrameName) then
		return
	end
	if InterfaceHideSignals[FrameName] == nil then
		InterfaceHideSignals[FrameName] = Signal.new("InterfaceHideSignal")
	end
	return InterfaceHideSignals[FrameName]
end

return module