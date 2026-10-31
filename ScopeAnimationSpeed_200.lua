-- Scope / ADS / Camera Animation Speed Controller
-- 200 candidate name patterns. Only Animator-based AnimationTracks are affected.
-- This does NOT rewrite game modules or TweenService-based camera/FOV transitions.
-- Untested in your executor/game build; use only in your own private test environment.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local CANDIDATES = {
    "scope",
    "scopeanim",
    "scopeanimation",
    "scopetrack",
    "scopetween",
    "scopetransition",
    "scopein",
    "scopeout",
    "scopeenter",
    "scopeexit",
    "scoping",
    "scopinganim",
    "scopinganimation",
    "scopingtrack",
    "scopingtween",
    "scopingtransition",
    "scopingin",
    "scopingout",
    "scopingenter",
    "scopingexit",
    "scoped",
    "scopedanim",
    "scopedanimation",
    "scopedtrack",
    "scopedtween",
    "scopedtransition",
    "scopedin",
    "scopedout",
    "scopedenter",
    "scopedexit",
    "aim",
    "aimanim",
    "aimanimation",
    "aimtrack",
    "aimtween",
    "aimtransition",
    "aimin",
    "aimout",
    "aimenter",
    "aimexit",
    "aiming",
    "aiminganim",
    "aiminganimation",
    "aimingtrack",
    "aimingtween",
    "aimingtransition",
    "aimingin",
    "aimingout",
    "aimingenter",
    "aimingexit",
    "ads",
    "adsanim",
    "adsanimation",
    "adstrack",
    "adstween",
    "adstransition",
    "adsin",
    "adsout",
    "adsenter",
    "adsexit",
    "sight",
    "sightanim",
    "sightanimation",
    "sighttrack",
    "sighttween",
    "sighttransition",
    "sightin",
    "sightout",
    "sightenter",
    "sightexit",
    "sighted",
    "sightedanim",
    "sightedanimation",
    "sightedtrack",
    "sightedtween",
    "sightedtransition",
    "sightedin",
    "sightedout",
    "sightedenter",
    "sightedexit",
    "zoom",
    "zoomanim",
    "zoomanimation",
    "zoomtrack",
    "zoomtween",
    "zoomtransition",
    "zoomin",
    "zoomout",
    "zoomenter",
    "zoomexit",
    "camera",
    "cameraanim",
    "cameraanimation",
    "cameratrack",
    "cameratween",
    "cameratransition",
    "camerain",
    "cameraout",
    "cameraenter",
    "cameraexit",
    "viewmodel",
    "viewmodelanim",
    "viewmodelanimation",
    "viewmodeltrack",
    "viewmodeltween",
    "viewmodeltransition",
    "viewmodelin",
    "viewmodelout",
    "viewmodelenter",
    "viewmodelexit",
    "view_model",
    "view_modelanim",
    "view_modelanimation",
    "view_modeltrack",
    "view_modeltween",
    "view_modeltransition",
    "view_modelin",
    "view_modelout",
    "view_modelenter",
    "view_modelexit",
    "weapon",
    "weaponanim",
    "weaponanimation",
    "weapontrack",
    "weapontween",
    "weapontransition",
    "weaponin",
    "weaponout",
    "weaponenter",
    "weaponexit",
    "gun",
    "gunanim",
    "gunanimation",
    "guntrack",
    "guntween",
    "guntransition",
    "gunin",
    "gunout",
    "gunenter",
    "gunexit",
    "rifle",
    "rifleanim",
    "rifleanimation",
    "rifletrack",
    "rifletween",
    "rifletransition",
    "riflein",
    "rifleout",
    "rifleenter",
    "rifleexit",
    "sniper",
    "sniperanim",
    "sniperanimation",
    "snipertrack",
    "snipertween",
    "snipertransition",
    "sniperin",
    "sniperout",
    "sniperenter",
    "sniperexit",
    "optic",
    "opticanim",
    "opticanimation",
    "optictrack",
    "optictween",
    "optictransition",
    "opticin",
    "opticout",
    "opticenter",
    "opticexit",
    "reticle",
    "reticleanim",
    "reticleanimation",
    "reticletrack",
    "reticletween",
    "reticletransition",
    "reticlein",
    "reticleout",
    "reticleenter",
    "reticleexit",
    "crosshair",
    "crosshairanim",
    "crosshairanimation",
    "crosshairtrack",
    "crosshairtween",
    "crosshairtransition",
    "crosshairin",
    "crosshairout",
    "crosshairenter",
    "crosshairexit",
    "firstperson",
    "firstpersonanim",
    "firstpersonanimation",
    "firstpersontrack",
    "firstpersontween",
    "firstpersontransition",
    "firstpersonin",
    "firstpersonout",
    "firstpersonenter",
    "firstpersonexit"
}

local ENABLED = true
local MULTIPLIER = 2
local tracked = {}
local connections = {}
local gui, statusLabel, speedLabel, listLabel

local function candidateMatch(track)
    local anim = track.Animation
    if not anim then return false end

    local name = string.lower(anim.Name or "")
    local id = string.lower(anim.AnimationId or "")

    if name == "" then
        return false
    end

    -- Exact candidate-name match first.
    for _, candidate in ipairs(CANDIDATES) do
        if name == candidate then
            return true
        end
    end

    -- Also accept candidate terms embedded in longer descriptive names.
    for _, candidate in ipairs(CANDIDATES) do
        if #candidate >= 3 and string.find(name, candidate, 1, true) then
            return true
        end
    end

    -- Animation IDs are intentionally not guessed or modified.
    return false
end

local function updateLabels()
    if statusLabel then
        statusLabel.Text = ENABLED and "状態: ON" or "状態: OFF"
    end
    if speedLabel then
        speedLabel.Text = "速度: " .. tostring(MULTIPLIER) .. "x"
    end
    local count = 0
    for _ in pairs(tracked) do count += 1 end
    if listLabel then
        listLabel.Text = "検出・追跡中: " .. tostring(count) .. " tracks"
    end
end

local function applyTrack(track)
    if not track or not track.IsPlaying or not candidateMatch(track) then
        return
    end

    local entry = tracked[track]
    if not entry then
        local original = 1
        pcall(function()
            original = track.Speed
        end)
        entry = { originalSpeed = original }
        tracked[track] = entry
    end

    if ENABLED then
        pcall(function()
            track:AdjustSpeed(entry.originalSpeed * MULTIPLIER)
        end)
    else
        pcall(function()
            track:AdjustSpeed(entry.originalSpeed)
        end)
    end
end

local function rescanAnimator(animator)
    if not animator or not animator:IsA("Animator") then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        applyTrack(track)
    end
    if not connections[animator] then
        connections[animator] = animator.AnimationPlayed:Connect(function(track)
            task.defer(function()
                applyTrack(track)
                updateLabels()
            end)
        end)
    end
end

local function scanRoot(root)
    if not root then return end
    if root:IsA("Animator") then
        rescanAnimator(root)
    end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Animator") then
            rescanAnimator(obj)
        end
    end
end

local function rescanAll()
    local character = LocalPlayer.Character
    local camera = Workspace.CurrentCamera
    scanRoot(character)
    scanRoot(camera)
    updateLabels()
end

local function setEnabled(value)
    ENABLED = value
    rescanAll()
    for track, entry in pairs(tracked) do
        if track and track.Parent then
            pcall(function()
                if ENABLED then
                    track:AdjustSpeed(entry.originalSpeed * MULTIPLIER)
                else
                    track:AdjustSpeed(entry.originalSpeed)
                end
            end)
        end
    end
    updateLabels()
end

local function setMultiplier(value)
    MULTIPLIER = math.clamp(math.floor(value + 0.5), 2, 500)
    rescanAll()
    for track, entry in pairs(tracked) do
        if track and track.Parent and ENABLED then
            pcall(function()
                track:AdjustSpeed(entry.originalSpeed * MULTIPLIER)
            end)
        end
    end
    updateLabels()
end

-- GUI
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
gui = Instance.new("ScreenGui")
gui.Name = "ScopeAnimationSpeed200"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(270, 190)
frame.Position = UDim2.new(0, 18, 0, 90)
frame.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local header = Instance.new("TextButton")
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Color3.fromRGB(42, 46, 58)
header.Text = "Animation Speed ×200  |  drag"
header.TextColor3 = Color3.new(1,1,1)
header.Font = Enum.Font.GothamBold
header.TextSize = 12
header.Parent = frame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 30)
toggle.Position = UDim2.fromOffset(10, 42)
toggle.BackgroundColor3 = Color3.fromRGB(45, 120, 75)
toggle.Text = "ON / OFF"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 13
toggle.Parent = frame
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 7)

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.fromOffset(10, 78)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

speedLabel = statusLabel:Clone()
speedLabel.Position = UDim2.fromOffset(10, 101)
speedLabel.Parent = frame

local slider = Instance.new("TextBox")
slider.Size = UDim2.new(1, -20, 0, 28)
slider.Position = UDim2.fromOffset(10, 128)
slider.BackgroundColor3 = Color3.fromRGB(48, 52, 63)
slider.TextColor3 = Color3.new(1,1,1)
slider.PlaceholderText = "速度を入力 (2～500)"
slider.Text = "2"
slider.ClearTextOnFocus = false
slider.Font = Enum.Font.Gotham
slider.TextSize = 12
slider.Parent = frame
Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 6)

listLabel = statusLabel:Clone()
listLabel.Position = UDim2.fromOffset(10, 160)
listLabel.Size = UDim2.new(1, -20, 0, 18)
listLabel.TextSize = 10
listLabel.Parent = frame

toggle.MouseButton1Click:Connect(function()
    setEnabled(not ENABLED)
    toggle.BackgroundColor3 = ENABLED and Color3.fromRGB(45,120,75) or Color3.fromRGB(130,55,55)
end)

slider.FocusLost:Connect(function()
    local value = tonumber(slider.Text)
    if value then
        setMultiplier(value)
    else
        slider.Text = tostring(MULTIPLIER)
    end
    slider.Text = tostring(MULTIPLIER)
end)

-- Drag window by header
local UserInputService = game:GetService("UserInputService")
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    scanRoot(character)
    updateLabels()
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.wait(0.2)
    scanRoot(Workspace.CurrentCamera)
    updateLabels()
end)

-- Initial scan and periodic rescan for animators created later.
rescanAll()
task.spawn(function()
    while gui.Parent do
        task.wait(2)
        rescanAll()
    end
end)

updateLabels()
