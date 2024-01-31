local module = {}
local Core = shared.Core
local Network = Core.Get("Network")
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

function module.Award(self, plr, badgeid)
	if not BadgeService:UserHasBadgeAsync(plr.UserId, badgeid) then
		BadgeService:AwardBadge(plr.UserId, badgeid)
		local infos = BadgeService:GetBadgeInfoAsync(badgeid)
		--Network:Signal("Notify", plr, "Success", "Nouveau Badge !", ("Vous venez de remporter le badge %s, félicitations !"):format(infos.Name)) // NOTIFICATION
	end
end

return module