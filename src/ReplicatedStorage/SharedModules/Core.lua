local Core = {}
Core._LogQueue = {}

local RunService = game:GetService("RunService")

local IsStudio = RunService:IsStudio()

local loaded = {}
local AlreadyInit = {}
local cachedModules = {}
local CompletitionCallbacks = {}

local CoreLoaded = false

function Core._Import(module)
	if not module:IsA("ModuleScript") then
		return
	end
	local startLoadTick = tick()
	local TookTimes = false
	local Functions = nil
	task.spawn(function()
		Functions = table.pack(pcall(require, module))
	end)
	while Functions == nil do
		if tick() - startLoadTick > 5 and not TookTimes then
			warn(string.format("[Core::Danger] %s prend beaucoup de temps pour être charger !", module.Name))
			TookTimes = true
		end
		task.wait()	
	end
	if TookTimes then
		warn(string.format("[Core::Fix] %s a fini de se charger. (%s)", module.Name, tick() - startLoadTick))
	end
	return table.unpack(Functions)
end

function Core.Load(module)
	if module ~= script then
		loaded[module.Name] = module
	end
end

function Core._GetTitle(p3)
	local Final
	if IsStudio then
		local Prefix
		if RunService:IsServer() then
			Prefix = "Server"
		else
			Prefix = "Client"
		end
		Final = ("[Core] [%s]"):format(Prefix) or "[Core]"
	else
		Final = "[Core]"
	end
	return Final
end

function Core.BulkLoad(...)
	local function interativeLoad(item)
		if item:IsA("ModuleScript") then
			Core.Load(item)
			return
		end
		for k, v in pairs(item:GetChildren()) do
			interativeLoad(v)
		end
	end
	for k, v in pairs({ ... }) do
		if v then
			assert(v:IsA("Folder"), ("%s Impossible de charger en masse depuis '%s' car ce n'est pas un dossier."):format(Core:_GetTitle(), v.Name))
			print(("%s Chargement des modules dans le répertoire '%s'"):format(Core:_GetTitle(), v.Name))
			interativeLoad(v)
		end
	end
end

function Core._TryInit(_, moduleName, moduleFunctions)
	if type(moduleFunctions) == "table" and moduleFunctions.Init and not AlreadyInit[moduleName] then
		AlreadyInit[moduleName] = true
		local TookLongTime = false
		local startLoadTick = tick()
		local success = nil
		local errmessage = nil
		task.spawn(function()
			success, errmessage = pcall(moduleFunctions.Init, moduleFunctions)
		end)
		while success == nil do
			if tick() - startLoadTick > 5 and not TookLongTime then
				warn(string.format("[Core::Danger] %s prend beaucoup de temps pour être charger !", moduleName))
				TookLongTime = true
			end
			if tick() - startLoadTick > 5 and moduleName ~= "UserInterface" then
				print("Loading continue for "..moduleName.."...")
			end
			task.wait()
		end
		if TookLongTime then
			warn(string.format("[Core::Fix] %s a fini de se charger. (%s)", moduleName, tick() - startLoadTick))
		end
		if not success then
			warn((("%s La méthode d'initialisation pour le service '%s' a échoué : \n%s"):format(Core:_GetTitle(), moduleName, errmessage)))
			table.insert(Core._LogQueue, {
				errorMessage = ("%s La méthode d'initialisation pour le service '%s' a échoué : \n%s"):format(Core:_GetTitle(), moduleName, errmessage), 
				errorScriptName = moduleName, 
				errorStackTrace = moduleName
			})
		end
	end
end

function Core.Get(moduleName, TryInit)
	if cachedModules[moduleName] then
		if not TryInit then
			Core:_TryInit(moduleName, cachedModules[moduleName])
		end
		return cachedModules[moduleName]
	end
	if not loaded[moduleName] then
		local loadTick = tick()
		warn(("%s Attente pour le module non-importé '%s'"):format(Core:_GetTitle(), moduleName))
		while true do
			task.wait()
			if loaded[moduleName] then
				break
			end
			if loadTick + 5 <= tick() then
				break
			end		
		end
	end
	if not loaded[moduleName] then
		error(("%s Le module '%s' a dépassé le délai d'attente, la requête est ignorée."):format(Core:_GetTitle(), moduleName))
		return
	end
	local success, Functions = Core._Import(loaded[moduleName])
	if not success then
		loaded[moduleName] = nil
		warn(("%s Échec de l'importation du module '%s': %s"):format(Core:_GetTitle(), moduleName, Functions))
		table.insert(Core._LogQueue, {
			errorMessage = ("%s Échec de l'importation du module '%s': %s"):format(Core:_GetTitle(), moduleName, Functions), 
			errorScriptName = moduleName, 
			errorStackTrace = moduleName
		})
		return
	end
	cachedModules[moduleName] = Functions
	local wasFound
	if type(Functions) == "table" and Functions.Init then
		wasFound = "trouvée"
	else
		wasFound = "introuvable"
	end
	print(("%s Importation réussie de '%s' pour la première fois, mise en cache. Méthode Init %s."):format(Core:_GetTitle(), moduleName, wasFound))
	if not TryInit then
		Core:_TryInit(moduleName, Functions)
	end
	return Functions
end

function Core.BulkGet(...)
	local Final = {}
	for _, v in pairs({ ... }) do
		if typeof(v) == "Instance" then
			for _, j in pairs(v:GetChildren()) do
				if j:IsA("ModuleScript") and not j:FindFirstChild("IGNORE") then
					Final[j] = Core.Get(j.Name)
				end
			end
		else
			Final[v] = Core.Get(v)
		end
	end
	return Final
end

function Core.MarkAsLoaded()
	if not CoreLoaded then
		for _, v in pairs(CompletitionCallbacks) do
			task.spawn(v)
		end
		CoreLoaded = true
		print("[Core] Client marqué comme chargé !")
	end
end

function Core.OnLoadingCompletion(callback)
	if CoreLoaded then
		task.spawn(callback)
		return
	end
	table.insert(CompletitionCallbacks, callback)
end

return Core
