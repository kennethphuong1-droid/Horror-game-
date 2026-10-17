-- Footsteps follow authored foot-contact phases, including speed changes and crossfades.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local contacts = require(script:WaitForChild("FootContacts"))
local scopes = {}
local random = Random.new()
local function cleanup(character)
	local scope = scopes[character]
	if not scope then return end
	if scope.mute then scope.mute:Disconnect() end
	if scope.running and scope.running.Parent then scope.running.Volume = scope.originalVolume end
	for _, sound in scope.sounds do sound:Destroy() end
	scopes[character] = nil
end
local connection = RunService.Heartbeat:Connect(function()
	local alive = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local h = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local animator = h and h:FindFirstChildOfClass("Animator")
		if not root or not animator then continue end
		alive[character] = true
		local scope = scopes[character]
		if not scope then
			scope = {sounds = {}, positions = {}, lastStep = -math.huge, generations = {}}
			scopes[character] = scope
		end
		local running = root:FindFirstChild("Running")
		if running and running:IsA("Sound") and running ~= scope.running then
			if scope.mute then scope.mute:Disconnect() end
			scope.running, scope.originalVolume = running, running.Volume
			running.Volume = 0
			scope.mute = running:GetPropertyChangedSignal("Volume"):Connect(function()
				if running.Volume ~= 0 then running.Volume = 0 end
			end)
		end
		local tracks = animator:GetPlayingAnimationTracks()
		local lead, schedule
		local playing = {}
		for _, track in tracks do
			local id = track.Animation and track.Animation.AnimationId:match("%d+")
			if id and contacts[id] then
				playing[track] = true
				if track.WeightCurrent > 0.05 and (not lead or track.WeightCurrent > lead.WeightCurrent) then
					lead, schedule = track, contacts[id]
				end
			end
		end
		local state = h:GetState()
		local velocity = root.AssemblyLinearVelocity
		local grounded = h.Health > 0 and not h.Sit and h.FloorMaterial ~= Enum.Material.Air
			and (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics)
			and Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 1
			and not h:GetAttribute("LandingAnimationPlaying")
		if lead and grounded then
			local previous = scope.positions[lead]
			local current = lead.TimePosition
			local duration = schedule.duration
			local elapsed = previous and (current - previous) % duration or 0
			-- Ignore phase seeks when a newly blended stride is aligned.
			if previous and elapsed > 0 and elapsed < 0.25 then
				for _, event in schedule.events do
					local distance = (event.time - previous) % duration
					if distance > 0 and distance <= elapsed and os.clock() - scope.lastStep >= 0.16 then
						local foot = character:FindFirstChild(event.foot)
						if foot then
							local sound = scope.sounds[event.foot]
							if not sound then
								sound = Instance.new("Sound")
								sound.Name = "SyncedFootstep"
								sound.SoundId = script:GetAttribute("SoundId")
								sound.RollOffMinDistance = 5
								sound.RollOffMaxDistance = 45
								sound.Looped = false
								sound.Parent = foot
								scope.sounds[event.foot] = sound
							end
							sound.Volume = (h:GetAttribute("Sprinting") and 0.38 or 0.28) * random:NextNumber(0.92, 1.08)
							sound.PlaybackSpeed = random:NextNumber(0.96, 1.04)
							sound:Stop()
							sound.TimePosition = script:GetAttribute("SampleStart") or 0
							sound:Play()
							scope.lastStep = os.clock()
							local generation = (scope.generations[event.foot] or 0) + 1
							scope.generations[event.foot] = generation
							task.delay(script:GetAttribute("SampleDuration") or 0.16, function()
								if scopes[character] == scope and scope.generations[event.foot] == generation then sound:Stop() end
							end)
						end
					end
				end
			end
		end
		for track in scope.positions do if not playing[track] then scope.positions[track] = nil end end
		for track in playing do scope.positions[track] = track.TimePosition end
	end
	for character in scopes do if not alive[character] then cleanup(character) end end
end)
script.Destroying:Connect(function()
	connection:Disconnect()
	for character in scopes do cleanup(character) end
end)

