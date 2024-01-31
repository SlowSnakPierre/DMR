local module = {}
local Core = shared.Core

local TweenService = game:GetService("TweenService")

local EnergySys = Core.Get("EnergySys", true)
local Global = Core.Get("Global")

local Generic = {}
local GenericStat = {}

function module:Off()
	Global:FindAudio("outage"):Play()
    EnergySys.Functions:PowerStat(false)

	for _, v in pairs(workspace.Facility_Lights:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			task.spawn(function()
				task.wait(1.75)
				v.Enabled = true
				task.wait(math.random(50, 100) / 100)
				v.Enabled = false
			end)
		end
	end

	for _, v in pairs(workspace.Facility_Lights.GenLights:GetDescendants()) do
		if v:IsA("SpotLight") or v:IsA("PointLight") then
			if v.Enabled then
				task.spawn(function()
					Generic[v] = v.Brightness
					GenericStat[v] = v.Enabled

					local loop = math.random(2, 5)
					for _ = 1, loop do
						v.Parent.Material = Enum.Material.SmoothPlastic
						v.Enabled = false

						task.wait(math.random(25, 90) / 100)
						v.Parent.Material = Enum.Material.Neon
						v.Enabled = true

						task.wait(math.random(25, 90) / 100)
					end

					v.Parent.Material = Enum.Material.SmoothPlastic
					TweenService:Create(v, TweenInfo.new(math.random(30, 60) / 10), { Brightness = 0 }):Play()
				end)
			end
		end
	end

	task.wait(6)
	TweenService:Create(game:GetService("Lighting"), TweenInfo.new(3.5), { Ambient = Color3.fromRGB(0, 0, 0) }):Play()
end

module.InstaOn = function()
	script.Parent.EnergySys:Invoke("PowerStat", true)

	for _, v in pairs(workspace.Facility_Lights.GenLights:GetDescendants()) do
		if v:IsA("SpotLight") or v:IsA("PointLight") then
			if GenericStat[v] == true then
				v.Brightness = Generic[v]
				v.Parent.Material = Enum.Material.Neon
				v.Enabled = true
			end
		end
	end

	Generic = {}
	GenericStat = {}
end

function module:On()
	Global:FindAudio("restore"):Play()
	EnergySys.Functions:PowerStat(true)

	for _, v in pairs(workspace.Facility_Lights.GenLights:GetDescendants()) do
		if v:IsA("SpotLight") or v:IsA("PointLight") then
			if GenericStat[v] == true then
				TweenService:Create(v, TweenInfo.new(math.random(30, 60) / 10), { Brightness = Generic[v] }):Play()
				task.spawn(function()
					local loop = math.random(2, 5)
					for i = 1, loop do
						v.Parent.Material = Enum.Material.SmoothPlastic
						v.Enabled = false

						task.wait(math.random(25, 90) / 100)
						v.Parent.Material = Enum.Material.Neon
						v.Enabled = true

						task.wait(math.random(25, 90) / 100)
					end
				end)
			end
		end
	end

	task.wait(3)
	TweenService:Create(game:GetService("Lighting"), TweenInfo.new(6), { Ambient = Color3.fromRGB(99, 99, 99) }):Play()

	task.wait(9)
	Generic = {}
	GenericStat = {}
end

return module
