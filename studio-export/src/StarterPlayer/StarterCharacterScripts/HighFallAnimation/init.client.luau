-- Use the custom falling pose only for drops meeting the heavy-landing threshold.
local RunService = game:GetService("RunService")
local character = script.Parent
local h = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local animator = h:WaitForChild("Animator")
local track = animator:LoadAnimation(script:WaitForChild("FallAnimation"))
track.Priority = Enum.AnimationPriority.Movement
track.Looped = false
local airborne, triggered = false, false
local peak = root.Position.Y
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {character}
params.RespectCanCollide = true
local function stop()
	if track.IsPlaying then track:Stop(0.1) end
end
local stateConnection = h.StateChanged:Connect(function(_, state)
	if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
		if not airborne then peak = root.Position.Y; triggered = false end
		airborne = true
	elseif state ~= Enum.HumanoidStateType.Freefall then
		airborne, triggered = false, false
		stop()
	end
end)
local heartbeat = RunService.Heartbeat:Connect(function()
	if not airborne or h.Health <= 0 then return end
	peak = math.max(peak, root.Position.Y)
	if h:GetState() ~= Enum.HumanoidStateType.Freefall or root.AssemblyLinearVelocity.Y >= -1 then return end
	if triggered then
		-- Hold the end pose during a long drop rather than looping the clip.
		if track.Length > 0 and track.IsPlaying and track.TimePosition >= track.Length - 0.04 then
			track:AdjustSpeed(0)
		end
		return
	end
	local landing = character:FindFirstChild("LandingAnimation")
	local minimum = landing and landing:GetAttribute("MinimumFallHeight") or 12
	local drop = peak - root.Position.Y
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -512, 0), params)
	if hit then
		local leg = character:FindFirstChild("Left Leg")
		local standingHeight = h.HipHeight + root.Size.Y / 2 + (leg and leg.Size.Y or 0)
		drop = math.max(drop, peak - hit.Position.Y - standingHeight)
	end
	if drop >= minimum then
		triggered = true
		track:Play(0.15, 1, 1)
	end
end)
script.Destroying:Connect(function()
	stateConnection:Disconnect()
	heartbeat:Disconnect()
	stop()
	track:Destroy()
end)

