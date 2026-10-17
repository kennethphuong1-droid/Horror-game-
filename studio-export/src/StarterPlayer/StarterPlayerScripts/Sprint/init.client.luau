local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("SprintRequest")
local lastTap = -math.huge
local held = false
local requested = false
local menuOpen = false
local focused = true
local camera, baseFov
local boost = 0
local connections = {}
local function stop()
	if requested then remote:FireServer(false, player.Character) end
	requested, held, lastTap = false, false, -math.huge
end
table.insert(connections, UIS.InputBegan:Connect(function(input, processed)
	if input.KeyCode ~= Enum.KeyCode.W or processed or held or menuOpen or not focused or UIS:GetFocusedTextBox() then return end
	held = true
	local now = os.clock()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if now - lastTap <= 0.28 and h and h.Health > 0 and not h.Sit then
		requested = true
		remote:FireServer(true, player.Character)
		lastTap = -math.huge
	else lastTap = now end
end))
table.insert(connections, UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		held = false
		if requested then stop() end
	end
end))
table.insert(connections, UIS.WindowFocusReleased:Connect(function() focused = false; stop() end))
table.insert(connections, UIS.WindowFocused:Connect(function() focused = true end))
table.insert(connections, UIS.TextBoxFocused:Connect(stop))
table.insert(connections, GuiService.MenuOpened:Connect(function() menuOpen = true; stop() end))
table.insert(connections, GuiService.MenuClosed:Connect(function() menuOpen = false end))
table.insert(connections, player.CharacterRemoving:Connect(stop))
table.insert(connections, player.CharacterAdded:Connect(function() stop() end))

RunService:BindToRenderStep("HorrorSprintFov", Enum.RenderPriority.Camera.Value + 2, function(dt)
	local current = workspace.CurrentCamera
	if current ~= camera then
		if camera and baseFov then camera.FieldOfView = baseFov end
		camera, baseFov = current, current and current.FieldOfView
		boost = 0
	end
	if not camera then return end
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if requested and (not h or h.Health <= 0 or h.Sit) then stop() end
	local active = h and h:GetAttribute("Sprinting") and held and h.MoveDirection.Magnitude > 0.1
		and not menuOpen and focused and camera.CameraType == Enum.CameraType.Custom
	local desired = active and 12 or 0
	boost += (desired - boost) * (1 - math.exp(-8 * dt))
	if math.abs(desired - boost) < 0.01 then boost = desired end
	camera.FieldOfView = baseFov + boost
	script:SetAttribute("FovBoost", boost)
	script:SetAttribute("SprintRequested", requested)
end)
script.Destroying:Connect(function()
	stop()
	RunService:UnbindFromRenderStep("HorrorSprintFov")
	for _, c in connections do c:Disconnect() end
	if camera and baseFov then camera.FieldOfView = baseFov end
end)
