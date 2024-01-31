local module = {}
local Core = shared.Core
local Network = Core.Get("Network")
local Players = game:GetService("Players")
local PlayerPerfs = {}

function module.Init(self)
	Network:ObserveSignal("PerformanceService", function(player, method, data)
		PlayerPerfs[player.UserId] = PlayerPerfs[player.UserId] or {
			Statistics = {},
			ScreenResolution = {},
			Device = {}
		}
		
		if method == "Statistics" then
			PlayerPerfs[player.UserId]["Statistics"] = data
		elseif method == "ScreenResolution" then
			PlayerPerfs[player.UserId]["ScreenResolution"] = data
		end
	end)
	
	Network:ObserveSignal("PerformanceInquiry", function(player, method, data)
		if method == "HandshakeResponse" then
			PlayerPerfs[player.UserId] = PlayerPerfs[player.UserId] or {
				Statistics = {},
				ScreenResolution = {},
				Device = {}
			}
			
			PlayerPerfs[player.UserId]["Device"] = data.Device
		end
	end)
	
	Players.PlayerAdded:Connect(function(plr)
		Network:Signal("PerformanceInquiry", plr, "Handshake")
	end)
end

return module