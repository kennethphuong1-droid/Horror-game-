-- StarterPlayer > StarterPlayerScripts. Ctrl: right, left, free.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local ACTION = "HorrorShoulderLock"
local BEFORE_CAMERA = ACTION .. "Offset"
local AFTER_CAMERA = ACTION .. "Facing"
local WIDTH = 1.75 -- studs to either shoulder
local EASE_RATE = 10 -- reaches roughly 95% of the offset in 0.3 seconds
local TURN_RATE = 16
local MODES = { "Free", "Right", "Left" }

local mode = 0
local shoulder = 0
local humanoid, root
local baseOffset = Vector3.zero
local originalAutoRotate = true
local previousMouseBehavior = Enum.MouseBehavior.Default
local previousMouseIcon = true
local ownsMouse = false
local menuOpen = false
local windowFocused = true
local connections = {}
local characterGeneration = 0

local function releaseMouse()
	if ownsMouse then
		UserInputService.MouseBehavior = previousMouseBehavior
		UserInputService.MouseIconEnabled = previousMouseIcon
		ownsMouse = false
	end
end

local function available()
	local camera = workspace.CurrentCamera
	return humanoid and humanoid.Parent and humanoid.Health > 0
		and root and root.Parent and camera
		and camera.CameraType == Enum.CameraType.Custom
		and camera.CameraSubject == humanoid
		and not humanoid.Sit and not menuOpen and windowFocused
		and not UserInputService:GetFocusedTextBox()
end

local function publish()
	script:SetAttribute("CurrentView", MODES[mode + 1])
end

local function resetCharacter()
	if humanoid and humanoid.Parent then
		humanoid.CameraOffset = baseOffset
		humanoid.AutoRotate = originalAutoRotate
	end
	releaseMouse()
	humanoid, root = nil, nil
	mode, shoulder = 0, 0
	publish()
end

local function attach(character)
	characterGeneration += 1
	local generation = characterGeneration
	resetCharacter()
	local h = character:WaitForChild("Humanoid", 10)
	local r = character:WaitForChild("HumanoidRootPart", 10)
	if generation ~= characterGeneration or character ~= player.Character or not h or not r then
		return
	end
	humanoid, root = h, r
	baseOffset = h.CameraOffset
	originalAutoRotate = h.AutoRotate
end

ContextActionService:BindActionAtPriority(ACTION, function(_, state)
	if UserInputService:GetFocusedTextBox() or menuOpen or not windowFocused then
		return Enum.ContextActionResult.Pass
	end
	if state == Enum.UserInputState.Begin and available() then
		mode = (mode + 1) % 3
		publish()
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl)

RunService:BindToRenderStep(BEFORE_CAMERA, Enum.RenderPriority.Camera.Value - 1, function(dt)
	if not humanoid or not root or not humanoid.Parent or not root.Parent then return end
	local active = available()
	local camera = workspace.CurrentCamera
	local distance = camera and (camera.CFrame.Position - camera.Focus.Position).Magnitude or 0
	-- Do not push the first-person camera out of the character's head.
	local desired = active and distance > 1 and (mode == 1 and WIDTH or mode == 2 and -WIDTH or 0) or 0
	shoulder += (desired - shoulder) * (1 - math.exp(-EASE_RATE * dt))
	if math.abs(desired - shoulder) < 0.001 then shoulder = desired end
	if active and camera then
		-- Camera-relative offset stays on the chosen screen side while the avatar turns.
		local right = camera.CFrame.RightVector
		local flatRight = Vector3.new(right.X, 0, right.Z)
		if flatRight.Magnitude > 0.01 then
			humanoid.CameraOffset = baseOffset + root.CFrame:VectorToObjectSpace(flatRight.Unit * shoulder)
		end
	else
		humanoid.CameraOffset = baseOffset
	end
	script:SetAttribute("ShoulderOffset", shoulder)
end)

RunService:BindToRenderStep(AFTER_CAMERA, Enum.RenderPriority.Camera.Value + 1, function(dt)
	local active = available()
	if active and mode ~= 0 then
		if not ownsMouse then
			previousMouseBehavior = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
				and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
			previousMouseIcon = UserInputService.MouseIconEnabled
			ownsMouse = true
		end
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		humanoid.AutoRotate = false
		local look = workspace.CurrentCamera.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude > 0.01 then
			local target = CFrame.lookAt(root.Position, root.Position + flatLook.Unit)
			root.CFrame = root.CFrame:Lerp(target, 1 - math.exp(-TURN_RATE * dt))
		end
	else
		releaseMouse()
		if humanoid and humanoid.Parent then humanoid.AutoRotate = originalAutoRotate end
	end
end)

table.insert(connections, player.CharacterAdded:Connect(attach))
table.insert(connections, player.CharacterRemoving:Connect(function()
	characterGeneration += 1
	resetCharacter()
end))
table.insert(connections, GuiService.MenuOpened:Connect(function() menuOpen = true; releaseMouse() end))
table.insert(connections, GuiService.MenuClosed:Connect(function() menuOpen = false end))
table.insert(connections, UserInputService.WindowFocusReleased:Connect(function() windowFocused = false; releaseMouse() end))
table.insert(connections, UserInputService.WindowFocused:Connect(function() windowFocused = true end))
table.insert(connections, script.Destroying:Connect(function()
	ContextActionService:UnbindAction(ACTION)
	RunService:UnbindFromRenderStep(BEFORE_CAMERA)
	RunService:UnbindFromRenderStep(AFTER_CAMERA)
	for _, connection in connections do connection:Disconnect() end
	resetCharacter()
end))

publish()
if player.Character then task.spawn(attach, player.Character) end
