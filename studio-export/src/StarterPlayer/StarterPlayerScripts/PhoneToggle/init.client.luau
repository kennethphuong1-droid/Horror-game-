local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local ACTION = "ToggleIPhone"
local StarterGui = game:GetService("StarterGui")
local BLOCK_HOTBAR = "HidePhoneBackpack"
local connections = {}
local function hideBackpack()
	task.spawn(function()
		for attempt = 1, 10 do
			local ok = pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
			if ok then return end
			task.wait(0.2)
		end
	end)
end
hideBackpack()
table.insert(connections, player.CharacterAdded:Connect(hideBackpack))

ContextActionService:BindActionAtPriority(BLOCK_HOTBAR, function()
	if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value + 100,
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Zero, Enum.KeyCode.Backquote)

local remote = game:GetService("ReplicatedStorage"):WaitForChild("PhoneEquipRequest")
local held = false
local lastPress = -math.huge
table.insert(connections, UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then held = false end
end))
table.insert(connections, UserInputService.WindowFocusReleased:Connect(function() held = false end))
ContextActionService:BindActionAtPriority(ACTION, function(_, state)
	if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		held = false
		return Enum.ContextActionResult.Sink
	end
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	if UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then return Enum.ContextActionResult.Pass end
	local now = os.clock()
	if held or now - lastPress < 0.2 then return Enum.ContextActionResult.Sink end
	held, lastPress = true, now
	local character = player.Character
	local h = character and character:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 then return Enum.ContextActionResult.Sink end
	local phone = character:FindFirstChild("iPhone")
	remote:FireServer(phone == nil, character)
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value + 100, Enum.KeyCode.F)
script.Destroying:Connect(function()
	ContextActionService:UnbindAction(ACTION)
	ContextActionService:UnbindAction(BLOCK_HOTBAR)
	for _, connection in connections do connection:Disconnect() end
end)

