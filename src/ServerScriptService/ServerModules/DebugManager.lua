local module = {}
local Core = shared.Core
local Network = Core.Get("Network")
local LoggingService = Core.Get("LoggingService")

function module.Init(self)
	Network:ObserveSignal("DebugService", function(Player, Platform, Type, Message, ScriptName, StackTrace)
		print(("[DebugManager] [%s] %s got an error on %s with error message %s and stacktrace %s"):format(Type, Player.Name, ScriptName, Message, StackTrace))
		
		LoggingService:AddLog("DebugService", ("[%s] %s a obtenu une erreur sur %s avec le message d'erreur %s et le suivi de la pile %s"):format(Type, Player.Name, ScriptName, Message, StackTrace))
	end)
end

return module