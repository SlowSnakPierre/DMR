return function(callback, ...)
	assert(type(callback) == "function", "[fastSpawn] Can only spawn functions.")
	local Bind = Instance.new("BindableEvent")
	local args = { ... }
	local selected = select("#", ...)
	Bind.Event:Connect(function()
		callback(unpack(args, 1, selected))
	end)
	Bind:Fire()
	Bind:Destroy()
end
