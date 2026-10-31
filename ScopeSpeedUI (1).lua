-- ScopeSpeedUI.lua
-- Movable/minimizable local UI for a private Roblox/LuaU project.
-- UI state only: connect the multiplier to your own local scope controller.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("ScopeSpeedUI")
if oldGui then
    oldGui:Destroy()
end

local enabled = false
local multiplier = 2
local minimized = false

local FULL_SIZE = UDim2.fromOffset(260, 174)
local MIN_SIZE = UDim2.fromOffset(260, 42)

local gui = Instance.new("ScreenGui")
gui.Name = "ScopeSpeedUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = FULL_SIZE
frame.Position = UDim2.new(0, 18, 0, 110) -- starts near the upper-left, not screen center
frame.BackgroundColor3 = Color3.fromRGB(24, 27, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(75, 85, 105)
stroke.Thickness = 1
stroke.Parent = frame

-- Header / drag handle
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -92, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "SCOPE SPEED"
title.TextColor3 = Color3.fromRGB(240, 243, 250)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "Minimize"
minimizeButton.Size = UDim2.fromOffset(32, 28)
minimizeButton.Position = UDim2.new(1, -40, 0, 7)
minimizeButton.BackgroundColor3 = Color3.fromRGB(55, 62, 76)
minimizeButton.Text = "—"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.TextSize = 18
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.AutoButtonColor = true
minimizeButton.Parent = header

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 7)
minCorner.Parent = minimizeButton

local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -42)
body.Position = UDim2.fromOffset(0, 42)
body.BackgroundTransparency = 1
body.Parent = frame

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.fromOffset(120, 26)
status.Position = UDim2.fromOffset(12, 0)
status.BackgroundTransparency = 1
status.Text = "Status: OFF"
status.TextColor3 = Color3.fromRGB(240, 243, 250)
status.TextSize = 13
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = body

local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.fromOffset(104, 30)
toggle.Position = UDim2.new(1, -116, 0, -2)
toggle.BackgroundColor3 = Color3.fromRGB(75, 80, 92)
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Text = "OFF"
toggle.TextSize = 13
toggle.Font = Enum.Font.GothamBold
toggle.AutoButtonColor = true
toggle.Parent = body

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 7)
toggleCorner.Parent = toggle

local valueLabel = Instance.new("TextLabel")
valueLabel.Name = "Multiplier"
valueLabel.Size = UDim2.new(1, -24, 0, 22)
valueLabel.Position = UDim2.fromOffset(12, 39)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "倍率: 2x"
valueLabel.TextColor3 = Color3.fromRGB(240, 243, 250)
valueLabel.TextSize = 13
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.Parent = body

local sliderBack = Instance.new("Frame")
sliderBack.Name = "SliderBack"
sliderBack.Size = UDim2.new(1, -24, 0, 10)
sliderBack.Position = UDim2.fromOffset(12, 72)
sliderBack.BackgroundColor3 = Color3.fromRGB(65, 71, 84)
sliderBack.BorderSizePixel = 0
sliderBack.Parent = body

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = sliderBack

local sliderFill = Instance.new("Frame")
sliderFill.Name = "SliderFill"
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(85, 155, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = sliderFill

local sliderButton = Instance.new("TextButton")
sliderButton.Name = "SliderInput"
sliderButton.Size = UDim2.new(1, 0, 1, 22)
sliderButton.Position = UDim2.fromOffset(0, -6)
sliderButton.BackgroundTransparency = 1
sliderButton.Text = ""
sliderButton.AutoButtonColor = false
sliderButton.Parent = sliderBack

local function updateSlider(value)
    multiplier = math.clamp(math.floor(value + 0.5), 2, 500)
    local alpha = (multiplier - 2) / 498
    sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
    valueLabel.Text = "倍率: " .. multiplier .. "x"
end

local function updateToggle()
    status.Text = enabled and "Status: ON" or "Status: OFF"
    toggle.Text = enabled and "ON" or "OFF"
    toggle.BackgroundColor3 = enabled
        and Color3.fromRGB(35, 145, 95)
        or Color3.fromRGB(75, 80, 92)
end

toggle.Activated:Connect(function()
    enabled = not enabled
    updateToggle()
end)

-- Minimize to a small title bar; tap the same button to restore.
minimizeButton.Activated:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    frame.Size = minimized and MIN_SIZE or FULL_SIZE
    minimizeButton.Text = minimized and "+" or "—"
end)

-- Slider supports mouse and touch input.
local sliderDragging = false

local function setSliderFromScreenX(screenX)
    local width = sliderBack.AbsoluteSize.X
    if width <= 0 then
        return
    end

    local x = screenX - sliderBack.AbsolutePosition.X
    local alpha = math.clamp(x / width, 0, 1)
    updateSlider(2 + alpha * 498)
end

sliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        setSliderFromScreenX(input.Position.X)
    end
end)

-- Drag the panel from any unused part of the header.
local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        -- Do not start moving when the minimize button itself is pressed.
        local mousePos = input.Position
        local buttonPos = minimizeButton.AbsolutePosition
        local buttonSize = minimizeButton.AbsoluteSize
        local overButton =
            mousePos.X >= buttonPos.X
            and mousePos.X <= buttonPos.X + buttonSize.X
            and mousePos.Y >= buttonPos.Y
            and mousePos.Y <= buttonPos.Y + buttonSize.Y

        if not overButton then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPosition = frame.Position
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        setSliderFromScreenX(input.Position.X)
    end

    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize
            local newX = startPosition.X.Offset + delta.X
            local newY = startPosition.Y.Offset + delta.Y

            if viewport then
                newX = math.clamp(newX, 0, math.max(0, viewport.X - frame.AbsoluteSize.X))
                newY = math.clamp(newY, 0, math.max(0, viewport.Y - frame.AbsoluteSize.Y))
            end

            frame.Position = UDim2.fromOffset(newX, newY)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragInput = nil
        end
    end
end)

local function getScopeSpeedMultiplier()
    return enabled and multiplier or 1
end

updateSlider(2)
updateToggle()

-- UI state access for code in this same local environment.
_G.GetScopeSpeedMultiplier = getScopeSpeedMultiplier
