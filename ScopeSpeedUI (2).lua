-- ScopeSpeedUI.lua
-- Local animation-speed helper for a private Roblox/LuaU test environment.
-- It watches Animators under the local character and CurrentCamera.
-- NOTE: Without the game's weapon code, this cannot identify scope-only tracks.
-- It may speed up other local character/viewmodel animations as well.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("ScopeSpeedUI")
if oldGui then
    oldGui:Destroy()
end

local enabled = false
local multiplier = 2
local minimized = false

local FULL_SIZE = UDim2.fromOffset(270, 184)
local MIN_SIZE = UDim2.fromOffset(270, 42)

local gui = Instance.new("ScreenGui")
gui.Name = "ScopeSpeedUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = FULL_SIZE
frame.Position = UDim2.new(0, 18, 0, 110)
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

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -94, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "SCOPE / ANIMATION SPEED"
title.TextColor3 = Color3.fromRGB(240, 243, 250)
title.TextSize = 13
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
status.Size = UDim2.fromOffset(140, 26)
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
toggle.Size = UDim2.fromOffset(96, 30)
toggle.Position = UDim2.new(1, -108, 0, -2)
toggle.BackgroundColor3 = Color3.fromRGB(75, 80, 92)
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Text = "OFF"
toggle.TextSize = 13
toggle.Font = Enum.Font.GothamBold
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
sliderButton.Size = UDim2.new(1, 0, 1, 24)
sliderButton.Position = UDim2.fromOffset(0, -7)
sliderButton.BackgroundTransparency = 1
sliderButton.Text = ""
sliderButton.AutoButtonColor = false
sliderButton.Parent = sliderBack

-- Keep original speeds so OFF restores the pre-modification speed.
local originalSpeeds = {}
local watchedAnimators = {}
local animatorConnections = {}

local function applyTrackSpeed(track)
    if not track then
        return
    end

    if originalSpeeds[track] == nil then
        local ok, currentSpeed = pcall(function()
            return track.Speed
        end)
        originalSpeeds[track] = (ok and currentSpeed) or 1
    end

    local baseSpeed = originalSpeeds[track]
    local targetSpeed = enabled and (baseSpeed * multiplier) or baseSpeed

    pcall(function()
        track:AdjustSpeed(targetSpeed)
    end)
end

local function updateAllPlayingTracks()
    for animator in pairs(watchedAnimators) do
        if animator.Parent then
            local ok, tracks = pcall(function()
                return animator:GetPlayingAnimationTracks()
            end)
            if ok and tracks then
                for _, track in ipairs(tracks) do
                    applyTrackSpeed(track)
                end
            end
        end
    end
end

local function watchAnimator(animator)
    if not animator:IsA("Animator") or watchedAnimators[animator] then
        return
    end

    watchedAnimators[animator] = true
    animatorConnections[animator] = animator.AnimationPlayed:Connect(function(track)
        applyTrackSpeed(track)
    end)

    local ok, tracks = pcall(function()
        return animator:GetPlayingAnimationTracks()
    end)
    if ok and tracks then
        for _, track in ipairs(tracks) do
            applyTrackSpeed(track)
        end
    end
end

local function isRelevantRoot(instance)
    local character = player.Character
    local camera = Workspace.CurrentCamera

    return (character and (instance == character or instance:IsDescendantOf(character)))
        or (camera and (instance == camera or instance:IsDescendantOf(camera)))
end

local function scanRoot(root)
    if not root then
        return
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("Animator") then
            watchAnimator(descendant)
        end
    end
end

local function watchRoot(root)
    if not root then
        return
    end

    scanRoot(root)
    root.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Animator") then
            watchAnimator(descendant)
        end
    end)
end

local function refreshRoots()
    scanRoot(player.Character)
    scanRoot(Workspace.CurrentCamera)
end

watchRoot(player.Character)
watchRoot(Workspace.CurrentCamera)

player.CharacterAdded:Connect(function(character)
    watchRoot(character)
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    watchRoot(Workspace.CurrentCamera)
end)

local function updateSlider(value)
    multiplier = math.clamp(math.floor(value + 0.5), 2, 500)
    local alpha = (multiplier - 2) / 498
    sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
    valueLabel.Text = "倍率: " .. multiplier .. "x"
    if enabled then
        updateAllPlayingTracks()
    end
end

local function updateToggle()
    status.Text = enabled and "Status: ON" or "Status: OFF"
    toggle.Text = enabled and "ON" or "OFF"
    toggle.BackgroundColor3 = enabled
        and Color3.fromRGB(35, 145, 95)
        or Color3.fromRGB(75, 80, 92)
    updateAllPlayingTracks()
end

toggle.Activated:Connect(function()
    enabled = not enabled
    updateToggle()
end)

minimizeButton.Activated:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    frame.Size = minimized and MIN_SIZE or FULL_SIZE
    minimizeButton.Text = minimized and "+" or "—"
end)

local sliderDragging = false

local function setSliderFromX(screenX)
    local width = sliderBack.AbsoluteSize.X
    if width <= 0 then
        return
    end
    local alpha = math.clamp((screenX - sliderBack.AbsolutePosition.X) / width, 0, 1)
    updateSlider(2 + alpha * 498)
end

sliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        setSliderFromX(input.Position.X)
    end
end)

-- Drag the panel from the header, except when pressing minimize.
local dragging = false
local dragInput
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        local p = input.Position
        local bPos = minimizeButton.AbsolutePosition
        local bSize = minimizeButton.AbsoluteSize
        local overMinimize = p.X >= bPos.X and p.X <= bPos.X + bSize.X
            and p.Y >= bPos.Y and p.Y <= bPos.Y + bSize.Y

        if not overMinimize then
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
        setSliderFromX(input.Position.X)
    end

    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local camera = Workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize
            local x = startPosition.X.Offset + delta.X
            local y = startPosition.Y.Offset + delta.Y

            if viewport then
                x = math.clamp(x, 0, math.max(0, viewport.X - frame.AbsoluteSize.X))
                y = math.clamp(y, 0, math.max(0, viewport.Y - frame.AbsoluteSize.Y))
            end
            frame.Position = UDim2.fromOffset(x, y)
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

updateSlider(2)
updateToggle()

-- Public getter for any compatible local scope controller in this script environment.
_G.GetScopeSpeedMultiplier = function()
    return enabled and multiplier or 1
end
