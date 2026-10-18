local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

local CFG = {
    Enabled = false,
    UseTP = true,        -- 足元TP + 仰向け
    UseAnimSpeed = true, -- アニメ高速化
    UseCooldown = true,  -- クールダウン短縮
    Depth = 6,
    AimPart = "Head",
    MaxDist = 2000,
    Speed = 5,
    CooldownDiv = 5,
}

local origVals = {}

local function closestEnemy()
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local best, bd
    for _, h in ipairs(workspace:GetDescendants()) do
        if h:IsA("Humanoid") and h.Health > 0 then
            local c = h.Parent
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if c ~= lp.Character and r then
                local d = (r.Position - root.Position).Magnitude
                if d <= CFG.MaxDist and (not bd or d < bd) then
                    best, bd = c, d
                end
            end
        end
    end
    return best
end

local function patchCooldowns(tool)
    if not tool or origVals[tool] then return end
    origVals[tool] = {}
    local keys = {"cooldown", "firerate", "delay", "reload", "interval", "rate"}
    local function match(n)
        n = n:lower()
        for _, k in ipairs(keys) do
            if n:find(k) then return true end
        end
    end
    for name, v in pairs(tool:GetAttributes()) do
        if type(v) == "number" and match(name) then
            origVals[tool][{tool, name}] = v
            tool:SetAttribute(name, v / CFG.CooldownDiv)
        end
    end
    for _, d in ipairs(tool:GetDescendants()) do
        if (d:IsA("NumberValue") or d:IsA("IntValue")) and match(d.Name) then
            origVals[tool][d] = d.Value
            d.Value = d.Value / CFG.CooldownDiv
        end
    end
end

local function restoreCooldowns()
    for tool, map in pairs(origVals) do
        for k, v in pairs(map) do
            pcall(function()
                if typeof(k) == "table" then k[1]:SetAttribute(k[2], v)
                else k.Value = v end
            end)
        end
    end
    origVals = {}
end

local function speedAnims(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
            t:AdjustSpeed(CFG.Speed)
        end
    end
end

local function shoot(char)
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        if CFG.UseCooldown then patchCooldowns(tool) end
        pcall(function() tool:Activate() end)
    end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local c = cam.ViewportSize / 2
        vim:SendTouchEvent(1, 0, c.X, c.Y)
        vim:SendTouchEvent(1, 2, c.X, c.Y)
    end)
end

RunService.Heartbeat:Connect(function()
    if not CFG.Enabled then return end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local enemy = closestEnemy()
    if not enemy then return end
    local er = enemy.HumanoidRootPart
    local aim = enemy:FindFirstChild(CFG.AimPart) or er

    if CFG.UseTP then
        hum.PlatformStand = true
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
        local pos = er.Position - Vector3.new(0, CFG.Depth, 0)
        root.CFrame = CFrame.lookAt(pos, aim.Position)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, aim.Position)

    if CFG.UseAnimSpeed then speedAnims(char) end
    shoot(char)
end)

------------------------------------------------------------
-- UI
------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "RageMenu"
gui.ResetOnSpawn = false
local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(190, 210)
frame.Position = UDim2.new(0, 15, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 34)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "RAGEBOT"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -20, 1, -44)
body.Position = UDim2.fromOffset(10, 38)
body.BackgroundTransparency = 1
body.Parent = frame

local layout = Instance.new("UIListLayout", body)
layout.Padding = UDim.new(0, 6)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(28, 24)
minBtn.Position = UDim2.new(1, -34, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = frame
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local minimized = false
minBtn.Activated:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    frame.Size = minimized and UDim2.fromOffset(190, 34) or UDim2.fromOffset(190, 210)
    minBtn.Text = minimized and "+" or "-"
end)

local ON_COLOR = Color3.fromRGB(40, 150, 60)
local OFF_COLOR = Color3.fromRGB(150, 40, 40)

local function makeToggle(label, key, onChange, big)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, big and 42 or 32)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = big and 16 or 13
    b.Parent = body
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local function refresh()
        b.Text = label .. ": " .. (CFG[key] and "ON" or "OFF")
        b.BackgroundColor3 = CFG[key] and ON_COLOR or OFF_COLOR
    end
    b.Activated:Connect(function()
        CFG[key] = not CFG[key]
        refresh()
        if onChange then onChange(CFG[key]) end
    end)
    refresh()
end

makeToggle("RAGEBOT", "Enabled", function(on)
    if not on then
        restoreCooldowns()
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end, true)
makeToggle("足元TP", "UseTP", function(on)
    if not on then
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end)
makeToggle("アニメ高速", "UseAnimSpeed")
makeToggle("CD短縮", "UseCooldown", function(on)
    if not on then restoreCooldowns() end
end)

-- ドラッグ移動(タイトル部分をスワイプ)
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos = true, i.Position, frame.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
