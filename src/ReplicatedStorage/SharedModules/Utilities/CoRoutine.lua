local Routines = {}
local OrgEnvs = {}
local OrgWait = task.wait

local function RandomID()
    local String = ""
    
    for k = 1, Random.new(tick()):NextInteger(5, 25) do
        String = String .. string.char(Random.new(tick() + math.random(math.random(1, 50), math.random(51, 100))):NextInteger(097, 122))
    end

    return String
end

local function Create(Function, Env, Alive, ...)
    local Args = {}
    local Break = false
    local Env = Env
    local ID = RandomID()

    local RunFunction = function()
        local Args = Args
        local Function = Function
        Function(unpack(Args))
    end

    local wait = function(Value)
        if Break == false then
            OrgWait(Value)
            coroutine.resume(Routines[ID].Thread)

            if Break == true then
                error()
            end
        else
            error()
        end
    end

    local SetEnv = function()
        setfenv(Function, setmetatable({}, {
            __index = function(self, index)
                if index == "wait" then
                    return wait
                elseif index == "HARDBREAKROUTINE" then
                    Routines[ID].Break(false)
                else
                    return Env[index]
                end
            end,
            __newindex = function(self, index, key)
                Env[index] = key
            end
        }))
    end

    Routines[ID] = {
        ["Thread"] = coroutine.create(function()
            local Ran, Error = pcall(RunFunction)

            if Error and Break == false then
                warn("Got error running Function ID: " .. tostring(ID) .. "Error;\n"..tostring(Error))
            end
        end),
        ["Function"] = Function,
        ["Break"] = function(SoftBreak)
            Break = true
            if not SoftBreak then
                OrgEnvs[Function] = Env
                setfenv(Function, {["BROKENADDED"] = "BROKENADDED"})
            end

            for k,v in pairs(Routines[ID]) do
                Routines[ID][k] = nil
            end

            Routines[ID] = nil
        end,
        ["ID"] = ID
    }

    if Alive ~= nil then
        if Alive == true then
            SetEnv()
        end
    end

    return Routines[ID]
end

return {
    Routines = Routines,
    Create = Create,
    Wrap = function(Function, Alive, ...)
        local RetTable = Create(Function, getfenv(2), Alive, ...)
        coroutine.resume(RetTable.Thread)
        return RetTable
    end,
    Clear = function(SoftBreak)
        for k,v in pairs(Routines) do
            v.Break(SoftBreak)
        end

        return "CLEARED"
    end,
    Break = function(ID, SoftBreak)
		if Routines[ID] ~= nil then
			if Routines[ID].Break then
				Routines[ID].Break(SoftBreak)
				
				return "BROKEN"
			end
		end

		return "ERROR"
    end,
	Restore = function(FunctionToRestore, OverrideEnv)
		local Env = nil

		if type(OverrideEnv) == "table" then
			Env = OverrideEnv
		else
			Env = getfenv(2)
		end

		setfenv(FunctionToRestore, Env)

		return FunctionToRestore
	end
}