local AntiSpam = {} -- Index: <instance> Player | Key: <int> Number of attempts
local DelayQueue = {} -- Index: <instance> Player | Key: <boolean> Delaying
local DefaultSpam = 15
local module = {}

function module:Make(Function, OptionalCooldownParameter)
	local SpamStop

	if tonumber(OptionalCooldownParameter) ~= nil then
		SpamStop = tonumber(OptionalCooldownParameter)
	else
		SpamStop = DefaultSpam
	end

    local Delay = function(Player)
        DelayQueue[Player] = true

        task.wait(5)

        DelayQueue[Player] = false
        AntiSpam[Player] = 0
    end



    return function(Player)
        if AntiSpam[Player] == nil then
            AntiSpam[Player] = 0
        end

        if DelayQueue[Player] == nil then
            DelayQueue[Player] = false
        end

        if AntiSpam[Player] < SpamStop then
            AntiSpam[Player] = AntiSpam[Player] + 1
            Function(Player)
        elseif AntiSpam[Player] >= SpamStop and DelayQueue[Player] == false then
            Delay(Player)
        end
    end
end

function module:Init()
    task.spawn(function()
        while true do
            task.wait(0.25)

            for Player, Attempts in pairs(AntiSpam) do
                if Attempts > 1 then
                    AntiSpam[Player] = Attempts - 1
                end
            end
        end
    end)
end

return module