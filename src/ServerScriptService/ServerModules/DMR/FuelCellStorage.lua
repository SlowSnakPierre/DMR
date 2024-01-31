local module = {}
local Core = shared.Core
local MarketplaceService = game:GetService("MarketplaceService")
local Network = Core.Get("Network")
local MaintenanceActive = false

local ServerStorage = game:GetService("ServerStorage")

local CellStorage = {
	[1] = false,
	[2] = false,
	[3] = false,
	[4] = false,
	[5] = false,
	[6] = false,
}

function module:Toggle(toggle)
	if toggle ~= nil then
		if toggle == true then
			MaintenanceActive = true
		elseif toggle == false then
			MaintenanceActive = false
		end
	end
end

function module:Init()
	for i = 1, 2 do
		local fc = "Cell" .. i
		local rci = workspace:WaitForChild("DMR"):WaitForChild("FuelCellStorage")
		rci:WaitForChild(fc):WaitForChild("ClickDetector").MouseClick:Connect(function(plr)
			if CellStorage[i] == false then
				for _, v in pairs(plr:WaitForChild("Backpack"):GetChildren()) do
					if plr:WaitForChild("Backpack"):FindFirstChild("Generic Cell") then
						CellStorage[i] = true
						Network:Signal("Notification", plr, "Fuel cell stored! You can pick this up once maintenance is engaged.", "happy", 10)
						plr:WaitForChild("Backpack")["Generic Cell"]:Destroy()
						for _, v in pairs(rci[fc]:GetDescendants()) do
							if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("WedgePart") or v:IsA("MeshPart") then
								v.Transparency = 0
							elseif v.Name == "Handle" then
								v.Transparency = 1
							end
						end
						break
					elseif not plr:WaitForChild("Backpack"):FindFirstChild("Generic Cell") then
						Network:Signal("Notification", plr, "You require a fuel cell to use this!", "error", 5)
					end
				end
			elseif CellStorage[i] == true then
				if MaintenanceActive == true then
					for _, v in pairs(plr:WaitForChild("Backpack"):GetChildren()) do
						if not plr:WaitForChild("Backpack"):FindFirstChild("Generic Cell") then
							local tool = game:GetService("ServerStorage").HadronCollider.DMRFuel.Generic["Generic Cell"]
								:Clone()
							tool.Parent = plr:WaitForChild("Backpack")
							rci[fc].Body.Sound:Play()
							CellStorage[i] = false
							for _, v in pairs(rci[fc]:GetDescendants()) do
								if
									v:IsA("Part")
									or v:IsA("UnionOperation")
									or v:IsA("WedgePart")
									or v:IsA("MeshPart")
								then
									v.Transparency = 0.8
								elseif v.Name == "Handle" then
									v.Transparency = 1
								end
							end
							break
						elseif plr:WaitForChild("Backpack"):FindFirstChild("Generic Cell") then
							Network:Signal("Notification", plr, "You cannot have more than one fuel cell!", "error", 5)
							break
						end
					end
				else
					Network:Signal("Notification", plr, "Activate maintenance first to get a fuel cell!", "error", 5)
				end
			end
		end)
	end

	for i = 3, 6 do
		local fc = "Cell" .. i
		local rci = workspace:WaitForChild("DMR"):WaitForChild("FuelCellStorage")
		rci:WaitForChild(fc):WaitForChild("ClickDetector").MouseClick:Connect(function(plr)
			if MarketplaceService:UserOwnsGamePassAsync(plr.UserId, 12175359) then
				if CellStorage[i] == false then
					for _, v in pairs(plr:WaitForChild("Backpack"):GetChildren()) do
						if plr:WaitForChild("Backpack"):FindFirstChild("Generic Cell") then
							CellStorage[i] = true
							Network:Signal("Notification", plr, "Fuel cell stored! You can pick this up once maintenance is engaged.", "happy", 10)
							plr:WaitForChild("Backpack"):WaitForChild("Generic Cell"):Destroy()
							for _, v in pairs(rci:WaitForChild(fc):GetDescendants()) do
                                if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("WedgePart") or v:IsA("MeshPart") then
									v.Transparency = 0
								elseif v.Name == "Handle" then
									v.Transparency = 1
								end
							end
							break
						elseif not plr:WaitForChild("Backpack"):FindFirstChild("Generic Cell") then
							Network:Signal("Notification", plr, "You require a fuel cell to use this!", "error", 5)
						end
					end
				elseif CellStorage[i] == true then
					if MaintenanceActive == true then
						for _, v in pairs(plr:WaitForChild("Backpack"):GetChildren()) do
							if not plr:WaitForChild("Backpack"):FindFirstChild("Generic Cell") then
								local tool = ServerStorage:WaitForChild("HadronCollider"):WaitForChild("DMRFuel"):WaitForChild("Generic"):WaitForChild("Generic Cell"):Clone()
								tool.Parent = plr:WaitForChild("Backpack")
								rci:WaitForChild(fc):WaitForChild("Body"):WaitForChild("Sound"):Play()
								CellStorage[i] = false
								for _, v in pairs(rci:WaitForChild(fc):GetDescendants()) do
									if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("WedgePart") or v:IsA("MeshPart") then
										v.Transparency = 0.8
									elseif v.Name == "Handle" then
										v.Transparency = 1
									end
								end
								break
							elseif plr:WaitForChild("Backpack"):FindFirstChild("Generic Cell") then
								Network:Signal("Notification", plr, "You cannot have more than one fuel cell!", "error", 5)
								break
							end
						end
					else
						Network:Signal("Notification", plr, "Activate maintenance first to get a fuel cell!", "error", 5)
					end
				end
			else
				Network:Signal("Notification", plr, 'To use extra fuel cells, buy the "Extra Fuel Cell Storage" gamepass.', "none", 5)
				MarketplaceService:PromptGamePassPurchase(plr, 12175359)
			end
		end)
	end
end

return module
