-- During free fall, face horizontal travel rather than the shoulder-lock camera.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local binding = "HorrorAirTravelFacing"
local activeRoot, yaw
RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value + 3, function(dt)
	local character = player.Character
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not h or not root or h.Health <= 0 or h.Sit or h:GetState() ~= Enum.HumanoidStateType.Freefall then
		activeRoot, yaw = nil, nil
		return
	end
	if activeRoot ~= root then
		activeRoot = root
		local look = root.CFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
	end
	local velocity = root.AssemblyLinearVelocity
	local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
	if horizontal.Magnitude > 1 then
		local desired = math.atan2(-horizontal.X, -horizontal.Z)
		local difference = (desired - yaw + math.pi) % (2 * math.pi) - math.pi
		local rate = script:GetAttribute("TurnRate") or 10
		yaw += difference * (1 - math.exp(-rate * dt))
	end
	root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
end)
script.Destroying:Connect(function()
	RunService:UnbindFromRenderStep(binding)
end)

