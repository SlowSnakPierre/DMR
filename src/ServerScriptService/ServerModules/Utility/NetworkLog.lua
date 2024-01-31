local module = {}
local Core = shared.Core
local LoggingService = Core.Get("LoggingService")
local isStudio = game:GetService("RunService"):IsStudio()

function module.AddEntryForPlayer(plr, Type, name, args)
	if isStudio then
		print("[NetworkLog] "..plr.Name.." fired "..name.." ("..Type..") with args : ", table.unpack(args))
	end
	
	LoggingService:AddLog("Réseau", plr.Name.." ("..plr.UserId..") à utilisé l'événement "..name.." ("..Type..")")
end

return module