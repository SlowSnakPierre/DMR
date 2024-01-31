local module = {}

local alarmStatus = 0 -- 0: disabled, 1: holy alarms, 2: red alarms, 3: blue alarms
local alarmsLock = false

function module:SetAlarmsTo0()
	for k,v in pairs(game.Workspace:WaitForChild("Facility_EmergencyLights"):GetChildren()) do
		if v:FindFirstChild("Motor") ~= nil then
			v.Motor.AlarmStart:Stop()
			v.Motor.alarm:Stop()
			v.Motor.EmgcyAlarm:Stop()
			v.Motor.HingeConstraint.AngularVelocity = 0
			v.Motor.EmgcyAlarm.Volume = 1
			v.Motor.Anchored = true
		end
		
		if v:FindFirstChild("Light") ~= nil then
			v.Light.Color = Color3.new('New Yeller')
			v.Light.SpotLight.Color = Color3.fromRGB( 255, 255, 21)
			v.Light.SpotLight.Range = 36
			v.Light.SpotLight.Brightness = 7.1
			v.Light.SpotLight.Enabled = false
			v.Light.Material = Enum.Material.SmoothPlastic
			v.Light.Anchored = true
		end
	end
end

function module:AlarmsOperations(setAlarmsTo, lockAlarms)
	if lockAlarms ~= nil then
		if lockAlarms == false then
			alarmsLock = false
		end
	end 
	
	if setAlarmsTo == 0 and alarmStatus ~= 0 and alarmsLock == false then
		alarmStatus = 0
		module:SetAlarmsTo0()
	elseif setAlarmsTo == 1 and alarmStatus ~= 1 and alarmsLock == false then
		alarmStatus = 1
		if alarmStatus ~= 0 then
			module:SetAlarmsTo0()
			wait()
		end

		for k, v in pairs (game.Workspace:WaitForChild("Facility_EmergencyLights"):GetChildren()) do
			if v:FindFirstChild("Motor") ~= nil then
				v.Motor.AlarmStart.Volume = 0.4
				v.Motor.AlarmStart.PlaybackSpeed = 1
				v.Motor.AlarmStart:Play()
				v.Motor.HingeConstraint.AngularVelocity = 5
				v.Motor.Anchored = false
			end
			
			if v:FindFirstChild("Light") ~= nil then
				v.Light.SpotLight.Enabled=true
				v.Light.Material = Enum.Material.Neon
				v.Light.Anchored = false
			end
		end		
	elseif setAlarmsTo == 2 and alarmStatus ~= 2 and alarmsLock == false then
		alarmStatus = 2
		if alarmStatus ~= 0 then
			module:SetAlarmsTo0()
			wait()
		end

		for k, v in pairs (game.Workspace:WaitForChild("Facility_EmergencyLights"):GetChildren()) do
			if v:FindFirstChild("Motor") ~= nil then
				v.Motor.EmgcyAlarm.SoundId = "rbxassetid://2957818046"
				v.Motor.EmgcyAlarm.Volume = 1
				v.Motor.EmgcyAlarm.PlaybackSpeed = 0.55
				v.Motor.EmgcyAlarm:Play()
				v.Motor.HingeConstraint.AngularVelocity = 5
				v.Motor.Anchored = false
			end
			
			if v:FindFirstChild("Light") ~= nil then
				v.Light.BrickColor = BrickColor.new('Bright red')
				v.Light.SpotLight.Color = Color3.fromRGB(255, 0, 0)
				v.Light.SpotLight.Brightness = 15
				v.Light.SpotLight.Range = 42.5
				v.Light.SpotLight.Enabled = true
				v.Light.Material = Enum.Material.Neon
				v.Light.Anchored = false
			end
		end
	elseif setAlarmsTo == 3 and alarmStatus ~= 3 and alarmsLock == false then
		alarmStatus = 3
		if alarmStatus ~= 0 then
			module:SetAlarmsTo0()
			wait()
		end

		for k, v in pairs (game.Workspace:WaitForChild("Facility_EmergencyLights"):GetChildren()) do
			if v:FindFirstChild("Motor") ~= nil then
				v.Motor.EmgcyAlarm.SoundId = "rbxassetid://143301594"
				v.Motor.EmgcyAlarm.Volume = 1
				v.Motor.EmgcyAlarm.PlaybackSpeed = 0.95
				v.Motor.EmgcyAlarm:Play()
				v.Motor.HingeConstraint.AngularVelocity = 5
				v.Motor.Anchored = false
			end
			
			if v:FindFirstChild("Light") ~= nil then
				v.Light.BrickColor = BrickColor.new('Baby blue')
				v.Light.SpotLight.Color = Color3.fromRGB(0, 0, 255)
				v.Light.SpotLight.Brightness = 15
				v.Light.SpotLight.Range = 42.5
				v.Light.SpotLight.Enabled = true
				v.Light.Material = Enum.Material.Neon
				v.Light.Anchored = false
			end
		end
	elseif setAlarmsTo == 4 and alarmStatus ~= 4 and alarmsLock == false then
		alarmStatus = 4
		if alarmStatus ~= 0 then
			module:SetAlarmsTo0()
			wait()
		end

		for k, v in pairs (game.Workspace:WaitForChild("Facility_EmergencyLights"):GetChildren()) do
			if v:FindFirstChild("Motor") ~= nil then
				v.Motor.EmgcyAlarm.SoundId = "rbxassetid://3476799174"
				v.Motor.EmgcyAlarm.Volume = 1.5
				v.Motor.EmgcyAlarm.PlaybackSpeed = 1
				v.Motor.HingeConstraint.AngularVelocity = 5
				v.Motor.EmgcyAlarm:Play()
				v.Motor.Anchored = false
			end
			
			if v:FindFirstChild("Light") ~= nil then
				v.Light.Color = Color3.fromRGB(255, 170, 0)
				v.Light.SpotLight.Color = Color3.fromRGB(255, 85, 0)
				v.Light.SpotLight.Brightness = 15
				v.Light.SpotLight.Range = 42.5
				v.Light.SpotLight.Enabled = true
				v.Light.Material = Enum.Material.Neon
				v.Light.Anchored = false
			end
		end
	elseif setAlarmsTo == 5 and alarmStatus ~= 5 and alarmsLock == false then
		alarmStatus = 5
		if alarmStatus ~= 0 then
			module:SetAlarmsTo0()
			wait()
		end

		for k, v in pairs(game.Workspace:WaitForChild("Facility_EmergencyLights"):GetChildren()) do
			if v:FindFirstChild("Motor") ~= nil then
				v.Motor.EmgcyAlarm.SoundId = "rbxassetid://1340574673"
				v.Motor.EmgcyAlarm.Volume = 1.25
				v.Motor.EmgcyAlarm.PlaybackSpeed = 1
				v.Motor.HingeConstraint.AngularVelocity = 5
				v.Motor.EmgcyAlarm:Play()
				v.Motor.Anchored = false
			end
			
			if v:FindFirstChild("Light") ~= nil then
				v.Light.Color = Color3.fromRGB(255, 255, 0)
				v.Light.SpotLight.Color = Color3.fromRGB(255, 255, 0)
				v.Light.SpotLight.Brightness = 7.1
				v.Light.SpotLight.Range = 36
				v.Light.SpotLight.Enabled = true
				v.Light.Material = Enum.Material.Neon
				v.Light.Anchored = false
			end
		end
	end

	if lockAlarms ~= nil then
		if lockAlarms == true then
			alarmsLock = true
		end
	end 
end


function module:FacilityPower(command)
	if command == false then
		local rootFolder = game.Workspace:WaitForChild("Facility_Lights")
		
		for i,v in pairs(rootFolder:WaitForChild("Floodlights"):GetDescendants()) do
			if v:IsA("SpotLight") then
				v.Enabled = true
				v.Parent.Material = Enum.Material.Neon
			end
		end
		
		local Sounds = game.Workspace:WaitForChild("Audios"):WaitForChild("FAAS")
		
		for i,v in pairs(Sounds:GetDescendants()) do
			if v:IsA("Sound") then
				v:Stop()
			end
		end
	elseif command == true then
		game.Workspace:WaitForChild("Audios"):WaitForChild("Effects"):WaitForChild("Ambience"):WaitForChild("Big Switch Sound Effect"):Play()
		local rootFolder = game.Workspace:WaitForChild("Facility_Lights")
		
		for i,v in pairs(rootFolder:WaitForChild("Floodlights"):GetDescendants()) do
			if v:IsA("SpotLight") then
				v.Enabled = false
				v.Parent.Material = Enum.Material.SmoothPlastic
			end
		end
		
		game.Lighting.Ambient = Color3.fromRGB(99,99,99)
	end
end

return module