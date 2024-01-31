local module = {}
module.Logs = {}

local Core = shared.Core
local Players = game:GetService("Players")

function module.GetLogs(self)
	return module.Logs
end

function module.AddLog(self, Category, Description)
	table.insert(module.Logs, {
		At = os.time(),
		Log = Description,
		LogType = Category
	})
end

function module.ListenPlayer(self, plr)
	self:AddLog("Joueurs", plr.Name.." ("..plr.UserId..") à rejoind le serveur")

	plr.CharacterAdded:Connect(function(char)
		if plr.Team ~= nil then
			self:AddLog("Avatars", plr.Name.." ("..plr.UserId..") à spawn en "..plr.Team.Name)
		end

		char.Humanoid.Died:Connect(function()
			local creator = char.Humanoid:FindFirstChild("creator")
			if creator and creator.Value ~= nil then
				self:AddLog("Avatars", plr.Name.." ("..plr.UserId..") ["..plr.Team.Name.."] à été tué par "..creator.Value.Name.." ("..creator.Value.UserId..") ["..plr.Team.Name.."]")
			else
				self:AddLog("Avatars", plr.Name.." ("..plr.UserId..") ["..plr.Team.Name.."] est mort")
			end
		end)
	end)
end

function module.Init(self)
	Players.PlayerAdded:Connect(function(plr)
		self:ListenPlayer(plr)
	end)

	Players.PlayerRemoving:Connect(function(plr)
		self:AddLog("Joueurs", plr.Name.." ("..plr.UserId..") à quitté le serveur")
	end)
end

return module