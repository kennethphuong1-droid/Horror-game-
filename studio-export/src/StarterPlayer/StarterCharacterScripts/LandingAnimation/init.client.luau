-- Only play the custom landing after a drop of at least MinimumFallHeight studs.
local RunService = game:GetService("RunService")
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local animator = humanoid:WaitForChild("Animator")
local animation = script:WaitForChild("LandingAnimation")
local track = animator:LoadAnimation(animation)
track.Priority = Enum.AnimationPriority.Movement
track.Looped = false
local airborne = false
local peakY = root.Position.Y
local connections = {}
local TweenService = game:GetService("TweenService")
local highlight = script:WaitForChild("HeavyLandingHighlight")
highlight.Adornee = character
local flashTween
local flashGeneration = 0
local function clearFlash()
	flashGeneration += 1
	if flashTween then flashTween:Cancel(); flashTween = nil end
	highlight.Enabled = false
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
end
local function flash()
	clearFlash()
	local generation = flashGeneration
	highlight.Enabled = true
	highlight.FillTransparency = 0.65
	highlight.OutlineTransparency = 0.55
	task.delay(0.08, function()
		if generation ~= flashGeneration or not highlight.Parent then return end
		flashTween = TweenService:Create(highlight, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FillTransparency = 1, OutlineTransparency = 1,
		})
		flashTween.Completed:Once(function(state)
			if generation == flashGeneration and state == Enum.PlaybackState.Completed then
				highlight.Enabled = false
				flashTween = nil
			end
		end)
		flashTween:Play()
	end)
end
local function stop()
	if track.IsPlaying then track:Stop(0.1) end
	humanoid:SetAttribute("LandingAnimationPlaying", false)
end
table.insert(connections, track.Ended:Connect(function()
	humanoid:SetAttribute("LandingAnimationPlaying", false)
end))
table.insert(connections, RunService.Heartbeat:Connect(function()
	if airborne then peakY = math.max(peakY, root.Position.Y) end
end))
table.insert(connections, humanoid.StateChanged:Connect(function(_, state)
	if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
		if not airborne then peakY = root.Position.Y end
		airborne = true
		stop()
	elseif state == Enum.HumanoidStateType.Landed then
		local drop = peakY - root.Position.Y
		local wasAirborne = airborne
		airborne = false
		local minimum = script:GetAttribute("MinimumFallHeight") or 12
		if wasAirborne and drop >= minimum and humanoid.Health > 0 and not humanoid.Sit then
			humanoid:SetAttribute("LandingAnimationPlaying", true)
			track:Play(0.05)
			flash()
		end
	elseif state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.RunningNoPhysics then
		airborne = false
		stop()
	end
end))
table.insert(connections, humanoid.Died:Connect(function()
	clearFlash()
	airborne = false
	stop()
end))
script.Destroying:Connect(function()
	clearFlash()
	for _, connection in connections do connection:Disconnect() end
	stop()
	track:Destroy()
end)

