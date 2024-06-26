local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Core = require(ReplicatedStorage.SharedModules.Core)
shared.Core = Core
local load = tick()

Core.BulkLoad(ServerScriptService.ServerModules, ReplicatedStorage.SharedModules)
print("[SERVER] BulkLoad fini !")

--"PerformanceManager", "DebugManager", "RobuxPurchaseManager", "BadgeServer", "DataManager",
Core.BulkGet("LoggingService", "Hazmat_Handler", "Cam_Hook", ServerScriptService.ServerModules.DMR, "EnergySys", "KillBricks")

print("[SERVER] Chargement terminé ! ("..tick()-load.." secondes )")