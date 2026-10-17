-- Blend native and converted clips together in the reference rig's joint frames.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local clips = require(script:WaitForChild("CompatiblePoses"))
local saved = {}
local leans = setmetatable({}, {__mode = "k"})
local function restore()
	for joint, transform in saved do if joint.Parent then joint.Transform = transform end end
	table.clear(saved)
end
local before = RunService.PreAnimation:Connect(restore)
local after = RunService.PreSimulation:Connect(function(dt)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local h = character and character:FindFirstChildOfClass("Humanoid")
		local animator = h and h:FindFirstChildOfClass("Animator")
		if not animator or h.Health <= 0 or not character:FindFirstChild("TorsoRot") then continue end
		local layers = {}
		local runWeight = 0
		for _, track in animator:GetPlayingAnimationTracks() do
			local id = track.Animation and track.Animation.AnimationId:match("%d+")
			local frames = id and clips[id]
			if id == "126175296967819" then runWeight += track.WeightCurrent end
			if not frames or track.WeightCurrent < 0.0001 then continue end
			local first, second = frames[1], frames[#frames]
			local time = track.TimePosition
			for index = 1, #frames - 1 do
				if time >= frames[index].time and time < frames[index + 1].time then
					first, second = frames[index], frames[index + 1]; break
				end
			end
			local alpha = math.clamp((time - first.time) / math.max(second.time - first.time, 0.0001), 0, 1)
			local priority = track.Priority == Enum.AnimationPriority.Core and -1 or track.Priority.Value
			local layer = layers[priority] or {}
			layers[priority] = layer
			for name, transform in first.poses do
				local pose = transform:Lerp(second.poses[name] or transform, alpha)
				if id == "87983269304583" and (name == "Left Arm" or name == "Right Arm") then
					local seconds = math.max(script:GetAttribute("FallArmRaiseSeconds") or 1.4, 0.1)
					local progress = math.clamp(time / seconds, 0, 1)
					progress = progress * progress * (3 - 2 * progress)
					local angle = math.rad(script:GetAttribute("FallArmRaiseDegrees") or 145)
					local raised = CFrame.Angles(0, 0, name == "Left Arm" and -angle or angle)
					pose = CFrame.new(pose.Position) * pose.Rotation:Lerp(raised, progress)
				end
				local weight = track.WeightCurrent
				local entry = layer[name]
				if entry then
					entry.pose = entry.pose:Lerp(pose, weight / (entry.weight + weight))
					entry.weight += weight
				else layer[name] = {pose = pose, weight = weight} end
			end
		end
		local priorities = {}
		for priority in layers do table.insert(priorities, priority) end
		table.sort(priorities)
		local targets = {}
		for _, priority in priorities do
			for name, entry in layers[priority] do
				targets[name] = (targets[name] or CFrame.identity):Lerp(entry.pose, math.min(entry.weight, 1))
			end
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		local lean = leans[character] or {pitch = 0, roll = 0}
		leans[character] = lean
		local pitch, roll = 0, 0
		local state = h:GetState()
		local grounded = h.FloorMaterial ~= Enum.Material.Air and not h.Sit
			and (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics)
			and not h:GetAttribute("LandingAnimationPlaying")
		if root and grounded and runWeight > 0.001 then
			local velocity = root.AssemblyLinearVelocity
			local flat = Vector3.new(velocity.X, 0, velocity.Z)
			if flat.Magnitude > 1 then
				local direction = root.CFrame:VectorToObjectSpace(flat.Unit)
				local strength = math.min(runWeight, 1) * math.clamp(flat.Magnitude / math.max(h.WalkSpeed, 1), 0, 1)
				pitch = direction.Z * math.rad(script:GetAttribute("SprintForwardLeanDegrees") or 8) * strength
				roll = -direction.X * math.rad(script:GetAttribute("SprintSideLeanDegrees") or 10) * strength
			end
		end
		local ease = 1 - math.exp(-8 * dt)
		lean.pitch += (pitch - lean.pitch) * ease
		lean.roll += (roll - lean.roll) * ease
		if not grounded then lean.pitch, lean.roll = 0, 0 end
		if targets.TorsoRot then
			local pose = targets.TorsoRot
			targets.TorsoRot = CFrame.new(pose.Position) * CFrame.Angles(lean.pitch, 0, lean.roll) * pose.Rotation
		end
		local phone = character:FindFirstChild("iPhone")
		local checkingPhone = phone and phone:IsA("Tool") and phone:GetAttribute("IPhoneTool")
			and grounded and not h:GetAttribute("LandingAnimationPlaying")
		lean.phone = (lean.phone or 0) + ((checkingPhone and 1 or 0) - (lean.phone or 0)) * (1 - math.exp(-10 * dt))
		if lean.phone > 0.001 then
			local arm = CFrame.Angles(math.rad(75), 0, math.rad(-18))
			targets["Right Arm"] = (targets["Right Arm"] or CFrame.identity):Lerp(arm, lean.phone)
			if targets.Head then
				targets.Head = targets.Head * CFrame.Angles(math.rad(-12 * lean.phone), math.rad(-8 * lean.phone), 0)
			end
		end
		for _, joint in character:GetDescendants() do
			if joint:IsA("Motor6D") and joint.Enabled and targets[joint.Name] then
				saved[joint] = joint.Transform
				joint.Transform = targets[joint.Name]
			end
		end
	end
end)
script.Destroying:Connect(function()
	before:Disconnect(); after:Disconnect(); restore()
end)

