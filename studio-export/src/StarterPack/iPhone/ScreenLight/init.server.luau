local tool = script.Parent
local function setLights(enabled)
	for _, light in tool:GetDescendants() do
		if light:IsA("Light") then light.Enabled = enabled end
	end
end
local lastRoot
local equipSound = tool:WaitForChild("Handle"):WaitForChild("EquipSfx")
tool.Equipped:Connect(function()
	lastRoot = tool.Parent:FindFirstChild("HumanoidRootPart")
	setLights(true)
	equipSound:Stop()
	equipSound.TimePosition = 0
	equipSound:Play()
end)
tool.Unequipped:Connect(function()
	setLights(false)
	equipSound:Stop()
	if not lastRoot or not lastRoot.Parent then return end
	-- Play from the character, since sounds in the Backpack are not spatially audible.
	local shutdown = tool.Handle.StowSfx:Clone()
	shutdown.Parent = lastRoot
	shutdown:Play()
	game:GetService("TweenService"):Create(shutdown, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		PlaybackSpeed = 0.9,
	}):Play()
	game:GetService("Debris"):AddItem(shutdown, 3)
end)

