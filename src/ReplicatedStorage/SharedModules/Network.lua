local module = {}
local Core = shared.Core

local isServer = game:GetService("RunService"):IsServer()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Promise = Core.Get("Promise")
local NetworkLog = nil
if isServer then
	NetworkLog = Core.Get("NetworkLog")
end

local EndPoints = {}

function module.GetEndpoint(self, EndpointName, BindType)
	if EndPoints[EndpointName] then
		return EndPoints[EndpointName]
	end
	local _NetworkingStorage = ReplicatedStorage:FindFirstChild("_NetworkingStorage")
	if not _NetworkingStorage and isServer then
		_NetworkingStorage = Instance.new("Folder")
		_NetworkingStorage.Parent = ReplicatedStorage
		_NetworkingStorage.Name = "_NetworkingStorage"
	end
	if not _NetworkingStorage then
		while true do
			task.wait()
			if _NetworkingStorage then
				break
			end			
		end
		return module:GetEndpoint(EndpointName, BindType)
	end
	local _NetworkingStorage_Endpoint = _NetworkingStorage:FindFirstChild(EndpointName)
	if _NetworkingStorage_Endpoint then
		if _NetworkingStorage_Endpoint:IsA(BindType) then
			if not isServer then
				EndPoints[EndpointName] = _NetworkingStorage_Endpoint
				_NetworkingStorage_Endpoint.Name = HttpService:GenerateGUID()
			end
			return _NetworkingStorage_Endpoint
		else
			return false
		end
	end
	if isServer then
		local Bind = Instance.new(BindType)
		Bind.Name = EndpointName
		Bind.Parent = _NetworkingStorage
		return Bind
	end
	local lastTime = tick()
	local tookTime = false
	while true do
		task.wait()
		if tick() - lastTime > 5 and not tookTime then
			warn(("[Network] Endpoint '%s' of class '%s' was not reserved on server, yielding..."):format(EndpointName, BindType))
			tookTime = true
		end
		if _NetworkingStorage:FindFirstChild(EndpointName) then
			break
		end		
	end
	if tookTime then
		warn(("[Network] Endpoint yield for '%s' has resolved"):format(EndpointName))
	end
	local EndPoint = _NetworkingStorage:FindFirstChild(EndpointName)
	if not EndPoint:IsA(BindType) then
		return false
	end
	if not isServer then
		EndPoints[EndpointName] = EndPoint
		EndPoint.Name = HttpService:GenerateGUID()
	end
	return EndPoint
end

function module.ObserveSignal(self, BindName, callback)
	return Promise.try(function()
		return module:GetEndpoint(BindName, "RemoteEvent")
	end):andThen(function(result)
		assert(result, ("[Network] Another endpoint with name %s exists of a different class."):format(BindName))
		local side
		if isServer then
			side = "server"
		else
			side = "client"
		end
		print(("[Network] Now observing endpoint '%s' on %s."):format(BindName, side))
		if isServer then
			return result.OnServerEvent:Connect(function(plr, ...)
				local args = { ... }
				task.defer(function()
					local success, errmsgs = pcall(NetworkLog.AddEntryForPlayer, plr, "Event", BindName, args)
					if not success then
						warn(tostring(errmsgs))
					end
				end)
				callback(plr, ...)
			end)
		end
		return result.OnClientEvent:Connect(callback)
	end)
end

function module.Signal(self, BindName, ...)
	local Bind = module:GetEndpoint(BindName, "RemoteEvent")
	assert(Bind, ("[Network] Another endpoint with name %s exists of a different class."):format(BindName))
	if not isServer then
		Bind:FireServer(...)
		return
	end
	if typeof(BindName) == "Instance" and BindName:IsA("Player") then
		warn("Error: You probably meant to pass the endpoint name first, not the player being signaled.")
	end
	Bind:FireClient(...)
end

function module.SignalAsync(self, BindName, ...)
	return Promise.try(module.Signal, module, BindName, ...)
end

function module.SignalAll(self, BindName, ...)
	local Bind = module:GetEndpoint(BindName, "RemoteEvent")
	assert(Bind, ("[Network] Another endpoint with name %s exists of a different class."):format(BindName))
	if not isServer then
		warn("[Network] 'SignalAll' is intended for firing all clients, this cannot be used on the client.")
		return
	end
	Bind:FireAllClients(...)
end

function module.OnInvoke(self, BindName, callback)
	local Bind = module:GetEndpoint(BindName, "RemoteFunction")
	assert(Bind, ("[Network] Another endpoint with name %s exists of a different class."):format(BindName))
	if not isServer then
		warn("[Network] Using 'OnClientInvoke' is not advised or permitted.")
		return
	end
	function Bind.OnServerInvoke(plr, ...)
		local args = { ... }
		task.defer(function()
			pcall(NetworkLog.AddEntryForPlayer, plr, "Function", BindName, args)
		end)
		return callback(plr, ...)
	end
end

function module.Invoke(self, BindName, ...)
	local endpoint = module:GetEndpoint(BindName, "RemoteFunction")
	assert(endpoint, ("[Network] Another endpoint with name %s exists of a different class."):format(BindName))
	if isServer then
		warn("[Network] Using 'InvokeClient' is not advised or permitted.")
		return
	end
	local lastTime = tick()
	local TookTime = false
	local results = nil
	local args = { ... }
	local success = false
	task.spawn(function()
		results = table.pack(endpoint:InvokeServer(unpack(args)))
		success = true
	end)
	while not success do
		if tick() - lastTime > 10 and not TookTime then
			warn(string.format("[Network::Danger] %s is taking a long time to return! Args:", BindName, ...))
			TookTime = true
		end
		task.wait()	
	end
	if TookTime then
		warn(string.format("[Network::Undanger] %s has finished return. Took %s!", BindName, tick() - lastTime))
	end
	return table.unpack(results)
end

function module.InvokePromise(self, callback, ...)
	local args = { ... }
	return Promise.new(function(promise, promiseerror)
		local errmessage = nil
		local success = nil
		success, errmessage = pcall(module.Invoke, module, callback, unpack(args))
		if success then
			promise(errmessage)
			return
		end
		promiseerror(errmessage)
	end)
end

function module.Reserve(self, ...)
	for _, v in pairs({ ... }) do
		module:GetEndpoint(v[1], v[2])
		print(("[Network] Reserved endpoint '%s' with class %s"):format(v[1], v[2]))
	end
end

return module
