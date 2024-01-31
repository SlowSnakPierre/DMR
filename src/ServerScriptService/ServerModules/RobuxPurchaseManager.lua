local module = {}
local Core = shared.Core
local Network = Core.Get("Network")

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local SessionStorage = {}

function module.HasGamepass(self, player, gamepassName)
	return SessionStorage[tostring(player.UserId)] and SessionStorage[tostring(player.UserId)][gamepassName]
end

function module.AddGamepass(self, player, gamepassName)
	SessionStorage[tostring(player.UserId)] = SessionStorage[tostring(player.UserId)] or {}
	SessionStorage[tostring(player.UserId)][gamepassName] = true
end

function module.ProcessReceipt(self, receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	
	local player = Players:GetPlayerByUserId(userId)
	if player then
		-- TODO: Add What needed
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function module.Init(self)
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		module:ProcessReceipt(receiptInfo)
	end
	
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, purchased)
		if not purchased then return end
		
		-- TODO: Gestion Gamepass
	end)
	
	Players.PlayerAdded:Connect(function(plr)
		SessionStorage[tostring(plr.UserId)] = {}
		-- TODO: Gestion Gamepass
	end)
	
	Network:OnInvoke("RobuxPurchaseManager", function(plr, method, data)
		if method == "HasGamepass" then
			return module:HasGamepass(plr, data)
		end
	end)
end

return module