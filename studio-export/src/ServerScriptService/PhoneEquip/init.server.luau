local Players = game:GetService("Players")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("PhoneEquipRequest")
local lastRequest = {}
remote.OnServerEvent:Connect(function(player, equip, character)
	if typeof(equip) ~= "boolean" or character ~= player.Character then return end
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < 0.15 then return end
	lastRequest[player] = now
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not h or h.Health <= 0 or not backpack then return end
	local phone = character:FindFirstChild("iPhone") or backpack:FindFirstChild("iPhone")
	if not phone or not phone:IsA("Tool") or not phone:GetAttribute("IPhoneTool") then return end
	if equip then
		if phone.Parent == backpack then h:EquipTool(phone) end
	else
		if phone.Parent == character then
			h:UnequipTools()
			if phone.Parent == character then phone.Parent = backpack end
		end
	end
	for _, light in phone:GetDescendants() do
		if light:IsA("Light") then light.Enabled = phone.Parent == character end
	end
end)
Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)

