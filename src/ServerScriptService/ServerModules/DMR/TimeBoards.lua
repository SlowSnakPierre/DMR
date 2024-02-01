local module = {}
local DMROn = true
local hour, min, sec, k = 0, 0, 0, 1

function module:DisplayNumber(num, TwoDigitID, DigitID)
    for k,Disp in pairs(game:GetService("CollectionService"):GetTagged("Clock")) do
        local Digit = Disp:WaitForChild(TwoDigitID):WaitForChild(DigitID):WaitForChild("Disp")

        for k,v in pairs(Digit:GetChildren()) do
            if string.match(v.Name, num) then
                v.Material = Enum.Material.Neon
                v.BrickColor = BrickColor.new("Bright red")
            end
        end
    end
end

function module:ResetNumber(TwoDigitID, DigitID)
    for k,Disp in pairs(game:GetService("CollectionService"):GetTagged("Clock")) do
        local Digit = Disp:WaitForChild(TwoDigitID):WaitForChild(DigitID):WaitForChild("Disp")

        for k,v in pairs(Digit:GetChildren()) do
            v.Material = Enum.Material.Plastic
            v.BrickColor = BrickColor.new("Black")
        end
    end
end

function module:WriteTwoDigit(num, TwoDigitID)
    num = tostring(num)
    if string.len(num) == 1 then
        num = "0"..num
    end

    local FirstDigit = string.sub(num, 1, 1)
    local SecondDigit = string.sub(num, 2, 2)

    module:ResetNumber(TwoDigitID, 1)
    module:ResetNumber(TwoDigitID, 2)

    module:DisplayNumber(FirstDigit, TwoDigitID, 1)
    module:DisplayNumber(SecondDigit, TwoDigitID, 2)
end

function module:WriteAllDigits(num)
    num = tostring(num)
    if string.len(num) == 0 then
        num = "000000"
    elseif string.len(num) == 1 then
        num = "00000"..num
    elseif string.len(num) == 2 then
        num = "0000"..num
    elseif string.len(num) == 3 then
        num = "000"..num
    elseif string.len(num) == 4 then
        num = "00"..num
    elseif string.len(num) == 5 then
        num = "0"..num
    end

    local FirstDigit = string.sub(num, 1, 2)
    local SecondDigit = string.sub(num, 3, 4)
    local ThirdDigit = string.sub(num, 5, 6)

    module:WriteTwoDigit(FirstDigit, 1)
    module:WriteTwoDigit(SecondDigit, 2)
    module:WriteTwoDigit(ThirdDigit, 3)
end

function module:Run()
    DMROn = true
    while DMROn do
        hour = math.floor(k / 3600)
        min = math.floor((k - (hour * 3600)) / 60)
        sec = k - (hour * 3600) - (min * 60)
        hour = tostring(hour)
        min = tostring(min)
        sec = tostring(sec)

        if string.len(hour) == 1 then
            hour = "0"..hour
        end
        if string.len(min) == 1 then
            min = "0"..min
        end
        if string.len(sec) == 1 then
            sec = "0"..sec
        end

        module:WriteAllDigits(hour..min..sec)
        task.wait(1)
        k = k + 1
    end
end

function module:Reset()
    DMROn = false
    hour, min, sec, k = 0, 0, 0, 1
    module:WriteAllDigits("000000")
end

return module