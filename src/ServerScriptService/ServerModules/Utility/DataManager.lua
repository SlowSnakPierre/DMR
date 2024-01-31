local module = {}
local Core = shared.Core

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataConfig = Core.Get("DataConfig")

local IsStudio = game:GetService("RunService"):IsStudio()

local DataStore = DataStoreService:GetDataStore("PlayerSave"..(IsStudio and "_Studio" or ""))

local Cache = {}
local Cooldown = {}

local function table_count(tbl)
	local count = 0
	for k,v in pairs(tbl) do
		count += 1
	end
	return count
end

function module.LoadPlayer(self, player)
	local PId = player.UserId
	
	Cache[tostring(PId)] = table.clone(DataConfig.Default)
	
	local plr_data = DataStore:GetAsync(PId)
	if plr_data then
		for k,v in pairs(plr_data) do
			if typeof(v) == "table" and table_count(v) > 0 then
				Cache[tostring(PId)][k] = Cache[tostring(PId)][k] or {}
				for n,j in pairs(v) do
					Cache[tostring(PId)][k][n] = j
				end
			else
				Cache[tostring(PId)][k] = v
			end
		end
	end
	
	player:SetAttribute("DataLoaded", true)
end

function module.SavePlr(self, player)
	local PId = player.UserId
	if Cooldown[tostring(PId)] and Cooldown[tostring(PId)] > tick() then return end
	
	local plr_data = Cache[tostring(PId)]
	if plr_data then
		DataStore:SetAsync(PId, plr_data)
		Cooldown[tostring(PId)] = tick() + 5
	end
end

function module.GetData(self, player, dataName)
	local PId = player.UserId
	repeat wait() until player:GetAttribute("DataLoaded") == true
	
	if Cache[tostring(PId)] then
		if Cache[tostring(PId)][dataName] then
			return Cache[tostring(PId)][dataName]
		end
	end
	warn("[DataManager] Data \""..dataName.."\" Not Found for player "..player.Name)
end

function module.SetData(self, player, dataName, dataValue)
	local PId = player.UserId
	repeat wait() until player:GetAttribute("DataLoaded") == true
	
	if Cache[tostring(PId)] then
		Cache[tostring(PId)][dataName] = dataValue
		return true
	end

	warn("[DataManager] Data \""..dataName.."\" Couldn't be set for player "..player.Name)
	return false
end

function module.Init(self)
	Players.PlayerAdded:Connect(function(player)
		module:LoadPlayer(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		module:SavePlr(player)
	end)
	
	for k,v in pairs(Players:GetPlayers()) do
		module:LoadPlayer(v)
	end
	
	game:BindToClose(function()
		for k,v in pairs(Players:GetPlayers()) do
			module:SavePlr(v)
		end
		wait()
	end)
end

return module