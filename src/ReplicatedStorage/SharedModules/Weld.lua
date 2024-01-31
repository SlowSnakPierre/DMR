local module = {}
module.cache = {}

function module.Weld(self, p1, p2, Type, C0)
	local w = Instance.new(Type or "Weld")
	w.Name = p1.Name .. "-" .. p2.Name .. " " .. (Type or "Weld")
	w.Part0, w.Part1 = p1, p2
	if C0 then
		w.C0 = p2.CFrame:ToObjectSpace(p1.CFrame):Inverse()
	end
	w.Parent = p1
	table.insert(module.cache, w)
	return w
end

function module.Model(self, model, main)
	for k,v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			if main then
				self:Weld(v, main, "Weld", true)
			else
				main = v
			end
		end
	end
	return main
end

function module.Clean(self)
	local num = 0
	for k,v in pairs(module.cache) do
		if v.Parent == nil or v.Part0 == nil or v.Part1 == nil then
			num = num+1
			v:Destroy()
		end
	end
	print("[Welds] Cleaned "..num.." welds")
	return num
end

function module.UnAnchor(self, model)
	for k,v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored = false
		end
	end
end

return module