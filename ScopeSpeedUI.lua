-- ScopeSpeedUI.lua
-- Local UI scaffold for a private Roblox/LuaU project.
-- This file provides the toggle and 2x-500x multiplier setting.
-- Connect getScopeSpeedMultiplier() to your own scope/aim animation code.

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

local gui = Instance.new("ScreenGui")
gui.Name = "ScopeSpeedUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(260, 166)
frame.Position = UDim2.new(0.5, -130, 0.5, -83)
frame.BackgroundColor3 = Color3.fromRGB(24, 27, 35)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(75, 85, 105)
stroke.Thickness = 1
stroke.Parent = frame

local function makeLabel(name, text, size, position, textSize)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(240, 243, 250)
    label.TextSize = textSize or 14
    label.Font = Enum.Font.Gotham
    label.Parent = frame
    return label
end

local title = makeLabel(
    "Title",
    "SCOPE SPEED",
    UDim2.new(1, -20, 0, 30),
    UDim2.fromOffset(10, 8),
    16
)
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local status = makeLabel(
    "Status",
    "Status: OFF",
    UDim2.fromOffset(120, 24),
    UDim2.fromOffset(12, 47),
    13
)
status.TextXAlignment = Enum.TextXAlignment.Left

local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.fromOffset(104, 30)
toggle.Position = UDim2.new(1, -116, 0, 44)
toggle.BackgroundColor3 = Color3.fromRGB(75, 80, 92)
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Text = "OFF"
toggle.TextSize = 13
toggle.Font = Enum.Font.GothamBold
toggle.AutoButtonColor = true
toggle.Parent = frame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 7)
toggleCorner.Parent = toggle

local valueLabel = makeLabel(
    "Multiplier",
    "倍率: 2x",
    UDim2.new(1, -24, 0, 22),
    UDim2.fromOffset(12, 86),
    13
)
valueLabel.TextXAlignment = Enum.TextXAlignment.Left

local sliderBack = Instance.new("Frame")
sliderBack.Name = "SliderBack"
sliderBack.Size = UDim2.new(1, -24, 0, 10)
sliderBack.Position = UDim2.fromOffset(12, 119)
sliderBack.BackgroundColor3 = Color3.fromRGB(65, 71, 84)
sliderBack.BorderSizePixel = 0
sliderBack.Parent = frame

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
sliderButton.Size = UDim2.new(1, 0, 1, 18)
sliderButton.Position = UDim2.fromOffset(0, -4)
sliderButton.BackgroundTransparency = 1
sliderButton.Text = ""
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

local draggingSlider = false

local function setSliderFromInput(input)
    local width = sliderBack.AbsoluteSize.X
    if width <= 0 then
        return
    end

    local x = input.Position.X - sliderBack.AbsolutePosition.X
    local alpha = math.clamp(x / width, 0, 1)
    updateSlider(2 + alpha * 498)
end

sliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        setSliderFromInput(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        setSliderFromInput(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

-- Drag the panel by its title area.
local draggingFrame = false
local dragStart
local startPosition

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingFrame = true
        dragStart = input.Position
        startPosition = frame.Position
    end
end)

title.InputChanged:Connect(function(input)
    if draggingFrame and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingFrame = false
    end
end)

-- Call this from your own local scope animation/controller:
-- local speed = getScopeSpeedMultiplier()
-- if speed then ... end
local function getScopeSpeedMultiplier()
    if enabled then
        return multiplier
    end
    return 1
end

updateSlider(2)
updateToggle()

-- Expose state for code in this same script.
_G.GetScopeSpeedMultiplier = getScopeSpeedMultiplier
