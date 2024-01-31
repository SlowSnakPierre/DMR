local module = {}
local Core = shared.Core

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ScriptContext = game:GetService("ScriptContext")

local Network = Core.Get("Network")
local Scheduler = Core.Get("Scheduler")

local Platform

if GuiService:IsTenFootInterface() then
	Platform = "Console"
elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
	Platform = "Mobile"
else
	Platform = "Desktop"
end

local function UpdateLogs()
	for k,v in ipairs(Core._LogQueue or {}) do
		Network:Signal("DebugService", Platform, "core", v.errorMessage, v.errorScriptName, v.errorStackTrace)
	end
	Core._LogQueue = {}
	print("[DebugService] Processed Client Core Queue")
end

function module.Init(self)
	ScriptContext.Error:Connect(function(Message, StackTrace, Script)
		if not Script then
			return
		end
		local scriptName = "Unknown"
		pcall(function()
			scriptName = Script:GetFullName()
		end)
		Network:Signal("DebugService", Platform, "error", Message, scriptName, StackTrace)
	end)
	
	Core.OnLoadingCompletion(UpdateLogs)
	
	local Schedule = Scheduler.new(60)
	Schedule:Tick(UpdateLogs)
	Schedule:Start()
end

return module