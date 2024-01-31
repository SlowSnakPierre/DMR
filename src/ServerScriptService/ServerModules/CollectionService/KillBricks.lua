local module = {}

function module:Init()
	for k,v in pairs(game:GetService("CollectionService"):GetTagged("KillBricks")) do
		v.Touched:Connect(function(hit)
			if hit.Parent:FindFirstChild("Humanoid") then
				hit.Parent:FindFirstChild("Humanoid").Health = 0
			end
		end)
	end
end

return module