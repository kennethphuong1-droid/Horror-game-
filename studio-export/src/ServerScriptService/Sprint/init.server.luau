local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("SprintRequest")
local states = {}
local function attach(player, character)
	local h = character:WaitForChild("Humanoid", 10)
	if not h or player.Character ~= character then return end
	states[player] = { humanoid = h, walkSpeed = h.WalkSpeed, lastStart = -math.huge }
	h:SetAttribute("Sprinting", false)
end
local function watch(player)
	player.CharacterAdded:Connect(function(c) attach(player, c) end)
	player.CharacterRemoving:Connect(function() states[player] = nil end)
	if player.Character then task.spawn(attach, player, player.Character) end
end
remote.OnServerEvent:Connect(function(player, requested, character)
	if typeof(requested) ~= "boolean" or character ~= player.Character then return end
	local state = states[player]
	if not state then return end
	local h = state.humanoid
	if requested then
		if h.Health <= 0 or h.Sit or os.clock() - state.lastStart < 0.15 then return end
		state.lastStart = os.clock()
	end
	h:SetAttribute("Sprinting", requested)
	h.WalkSpeed = requested and 26 or state.walkSpeed
end)
RunService.Heartbeat:Connect(function()
	for _, state in states do
		local h = state.humanoid
		if h.Parent and h:GetAttribute("Sprinting") and (h.Health <= 0 or h.Sit) then
			h:SetAttribute("Sprinting", false)
			h.WalkSpeed = state.walkSpeed
		end
	end
end)
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
for _, player in Players:GetPlayers() do watch(player) end
