-- Phone distraction: narrow peripheral vision while leaving the center unobscured.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("PhoneAwarenessOverlay")
local vignette = gui:WaitForChild("PeripheralShade")
local depth = script:WaitForChild("PhoneDepthOfField"):Clone()
local color = script:WaitForChild("PhoneDistractionColor"):Clone()
local binding = "PhoneAwarenessFocus"
local blend = 0
RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value + 5, function(dt)
	local camera = workspace.CurrentCamera
	if not camera then gui.Enabled = false; depth.Enabled = false; color.Enabled = false; return end
	if depth.Parent ~= camera then depth.Parent = camera end
	if color.Parent ~= camera then color.Parent = camera end
	local character = player.Character
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local phone = character and character:FindFirstChild("iPhone")
	local active = h and h.Health > 0 and phone and phone:IsA("Tool") and phone:GetAttribute("IPhoneTool")
	local desired = active and 1 or 0
	blend += (desired - blend) * (1 - math.exp(-9 * dt))
	if math.abs(desired - blend) < 0.001 then blend = desired end
	gui.Enabled = blend > 0
	vignette.GroupTransparency = 1 - blend
	color.Enabled = blend > 0
	color.Saturation = -0.2 * blend
	color.Contrast = 0.05 * blend
	color.Brightness = 0
	local head = character and character:FindFirstChild("Head")
	local distance = head and (camera.CFrame.Position - head.Position).Magnitude or 2
	depth.FocusDistance = math.max(2, distance)
	depth.InFocusRadius = 3
	depth.NearIntensity = 0
	depth.FarIntensity = blend
	depth.Enabled = blend > 0
end)
script.Destroying:Connect(function()
	RunService:UnbindFromRenderStep(binding)
	gui.Enabled = false
	vignette.GroupTransparency = 1
	depth:Destroy()
	color:Destroy()
end)

