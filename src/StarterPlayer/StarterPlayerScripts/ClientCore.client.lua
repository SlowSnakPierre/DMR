local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Core = require(ReplicatedStorage.SharedModules.Core)
shared.Core = Core
local load = tick()

Core.BulkLoad(ReplicatedStorage.ClientModules, ReplicatedStorage.SharedModules)
--Core.BulkGet("PerformanceService", "DebugService", "UserInterface")

print("[CLIENT] BulkLoad fini !")

Core.MarkAsLoaded()

print("[CLIENT] Chargement terminé ! ("..tick()-load.." secondes )")