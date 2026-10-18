-- Lightweight Hub UI
-- Local testing environment

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("LightHub")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "LightHub"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local toggle = create("TextButton", {
    Name = "Toggle",
    Size = UDim2.fromOffset(42, 42),
    Position = UDim2.new(0, 12, 0.5, -21),
    Text = "U",
    TextScaled = true,
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    TextColor3 = Color3.new(1, 1, 1),
}, gui)

create("UICorner", {
    CornerRadius = UDim.new(1, 0),
}, toggle)

local panel = create("Frame", {
    Name = "Panel",
    Size = UDim2.fromOffset(245, 290),
    Position = UDim2.new(0, 62, 0.5, -145),
    BackgroundColor3 = Color3.fromRGB(24, 24, 30),
    Visible = false,
}, gui)

create("UICorner", {
    CornerRadius = UDim.new(0, 8),
}, panel)

local title = create("TextLabel", {
    Size = UDim2.new(1, -12, 0, 36),
    Position = UDim2.fromOffset(6, 4),
    BackgroundTransparency = 1,
    Text = "Light Hub",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local tabs = {"Combat", "Visuals", "Movement", "Config"}
local status = create("TextLabel", {
    Size = UDim2.new(1, -16, 0, 42),
    Position = UDim2.fromOffset(8, 244),
    BackgroundTransparency = 1,
    Text = "Local test hub",
    TextColor3 = Color3.fromRGB(180, 180, 190),
    TextSize = 12,
    TextWrapped = true,
}, panel)

for i, name in ipairs(tabs) do
    local button = create("TextButton", {
        Size = UDim2.new(1, -16, 0, 38),
        Position = UDim2.fromOffset(8, 42 + (i - 1) * 47),
        BackgroundColor3 = Color3.fromRGB(43, 43, 52),
        TextColor3 = Color3.new(1, 1, 1),
        Text = name,
        TextSize = 14,
    }, panel)

    create("UICorner", {
        CornerRadius = UDim.new(0, 5),
    }, button)

    button.Activated:Connect(function()
        status.Text = name .. " tab selected"
    end)
end

toggle.Activated:Connect(function()
    panel.Visible = not panel.Visible
end)

-- Drag the panel using touch or mouse.
local dragging = false
local dragStart, startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
