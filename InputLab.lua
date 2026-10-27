--[[
  InputLab (RageLiteとは別の、単独で動く実験ツール)
  偽の入力を送って「視点が回るか」「体の向きもついてくるか」を測ります。
  使い方: ゲームに入って実行 → 画面を触らずに、A〜Eのボタンを1つずつ押す → 状態欄の結果を見る
  結果は自動でクリップボードにもコピーされます。
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

------------------------------------------------------------ 後始末(再実行しても重ならない)
local env = (getgenv and getgenv()) or _G
for _, c in ipairs(env.IL_CONN or {}) do pcall(function() c:Disconnect() end) end
env.IL_CONN = {}
local function track(c) table.insert(env.IL_CONN, c) return c end
env.IL_ON, env.IL_DELTA, env.IL_RMB = false, Vector2.zero, false

local pg = lp:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("InputLab")
if old then old:Destroy() end

local DURATION = 0.6      -- 1回のテストで偽の入力を送る時間(秒)
local AMOUNTS = {200, 600, 1500}   -- マウス/指で動かす合計ピクセル
local amountIdx = 2

------------------------------------------------------------ 表示
local gui = Instance.new("ScreenGui")
gui.Name = "InputLab"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = pg

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(230, 330)
win.Position = UDim2.fromOffset(10, 50)
win.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
win.BorderSizePixel = 0
win.Parent = gui
local wc = Instance.new("UICorner")
wc.CornerRadius = UDim.new(0, 8)
wc.Parent = win

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Text = "InputLab (ここをドラッグ)"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Parent = win

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -8, 0, 190)
list.Position = UDim2.fromOffset(4, 26)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = win
local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 3)
lay.Parent = list

local statBox = Instance.new("ScrollingFrame")
statBox.Size = UDim2.new(1, -8, 0, 96)
statBox.Position = UDim2.fromOffset(4, 222)
statBox.BackgroundColor3 = Color3.new(0, 0, 0)
statBox.BackgroundTransparency = 0.3
statBox.BorderSizePixel = 0
statBox.ScrollBarThickness = 3
statBox.CanvasSize = UDim2.new()
statBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
statBox.Parent = win

local stat = Instance.new("TextLabel")
stat.Size = UDim2.new(1, -6, 0, 0)
stat.Position = UDim2.fromOffset(3, 2)
stat.AutomaticSize = Enum.AutomaticSize.Y
stat.BackgroundTransparency = 1
stat.TextColor3 = Color3.new(1, 1, 1)
stat.TextWrapped = true
stat.TextXAlignment = Enum.TextXAlignment.Left
stat.TextYAlignment = Enum.TextYAlignment.Top
stat.TextSize = 11
stat.Font = Enum.Font.Gotham
stat.Text = "準備OK。画面を触らずに、ボタンを1つずつ押してください。"
stat.Parent = statBox

local lastOut = ""
local function say(t)
    lastOut = tostring(t)
    stat.Text = lastOut
    statBox.CanvasPosition = Vector2.zero
    if setclipboard then pcall(setclipboard, lastOut) end
end

local function addBtn(text, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 26)
    b.BackgroundColor3 = Color3.fromRGB(55, 90, 150)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = list
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b
    b.Activated:Connect(function() fn(b) end)
    return b
end

-- ドラッグ移動
local dragging, dStart, wStart
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dStart, wStart = true, i.Position, win.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
track(UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - dStart
        win.Position = UDim2.new(wStart.X.Scale, wStart.X.Offset + d.X, wStart.Y.Scale, wStart.Y.Offset + d.Y)
    end
end))

------------------------------------------------------------ フック(ゲームが「マウスの移動量」「右クリック中か」を聞いてきたら、偽の答えを返す)
local hookOk = false
pcall(function()
    if not (hookmetamethod and getnamecallmethod and checkcaller and newcclosure) then return end
    if not env.IL_HOOKED then
        env.IL_HOOKED = true
        local oldNc
        oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if env.IL_ON and not checkcaller() then
                if m == "GetMouseDelta" then return env.IL_DELTA end
                if m == "IsMouseButtonPressed" and env.IL_RMB then
                    local ut = ...
                    if ut == Enum.UserInputType.MouseButton2 then return true end
                end
            end
            return oldNc(self, ...)
        end))
    end
    hookOk = true
end)

------------------------------------------------------------ 偽の入力を、ゲームの入力処理へ直接渡す
-- 本物の入力ではないので、画面はスマホ用のまま。ゲームがつないでいる処理(getconnections)を直接呼ぶ。
local function fire(sig, ...)
    if not getconnections then return 0 end
    local args = table.pack(...)
    local n = 0
    for _, c in ipairs(getconnections(sig)) do
        n += 1
        local ok = pcall(function() c:Fire(table.unpack(args, 1, args.n)) end)
        if not ok then
            pcall(function()
                if c.Function then c.Function(table.unpack(args, 1, args.n)) end
            end)
        end
    end
    return n
end

local function mkInput(ut, state, kc, delta, pos)
    return {UserInputType = ut, UserInputState = state, KeyCode = kc or Enum.KeyCode.Unknown,
        Delta = delta or Vector3.zero, Position = pos or Vector3.zero}
end

------------------------------------------------------------ 測る(視点と体の向き)
local function yawOf(v) return math.deg(math.atan2(-v.X, -v.Z)) end
local function diff(a, b) return (b - a + 180) % 360 - 180 end

local function snap()
    local cam = workspace.CurrentCamera
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local cl = cam.CFrame.LookVector
    return {cy = yawOf(cl), cp = math.deg(math.asin(math.clamp(cl.Y, -1, 1))),
        by = root and yawOf(root.CFrame.LookVector) or nil}
end

local busy = false

-- name: 方式の名前 / begin: 開始時の処理 / step: 毎フレームの処理(dx = そのフレームで動かすピクセル) / finish: 終了時の処理
local function runTest(name, begin, step, finish)
    if busy then return end
    if not getconnections and name ~= "B" then
        say("このDeltaは getconnections に対応していないので、この方式は使えません")
        return
    end
    busy = true
    say("テスト中: " .. name .. "(画面を触らないでください)")
    local a = snap()
    local amount = AMOUNTS[amountIdx]
    local counts = {}
    begin(counts)
    local t0, last = tick(), tick()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local now = tick()
        local dt = now - last
        last = now
        if now - t0 >= DURATION then
            conn:Disconnect()
            return
        end
        step(amount * dt / DURATION, counts)
    end)
    task.delay(DURATION + 0.5, function()
        finish(counts)
        local b = snap()
        local dc = diff(a.cy, b.cy)
        local dp = b.cp - a.cp
        local db = (a.by and b.by) and diff(a.by, b.by) or nil
        local moved = math.abs(dc) > 2 or math.abs(dp) > 2
        local followed = db ~= nil and math.abs(db) > 2 and math.abs(db) > math.abs(dc) * 0.5
        local lines = {
            "方式: " .. name,
            string.format("視点: 横 %+.1f° / 縦 %+.1f° → %s", dc, dp, moved and "回った" or "変化なし"),
            db and string.format("体: 横 %+.1f° → %s", db,
                (not moved) and "-" or (followed and "ついてきた" or "置いていかれた")) or "体: 測れません",
            string.format("偽の入力を渡せた接続の数: %s", counts.n and tostring(counts.n) or "-"),
        }
        say(table.concat(lines, "\n"))
        busy = false
    end)
end

------------------------------------------------------------ 実験の方式
local UT = Enum.UserInputType
local US = Enum.UserInputState

-- A: マウスの動き(InputChanged)を、ゲームの入力処理へ渡す
addBtn("A マウス移動(InputChanged)", function()
    runTest("A マウス移動", function(c) c.n = 0 end, function(dx, c)
        c.n = fire(UIS.InputChanged, mkInput(UT.MouseMovement, US.Change, nil, Vector3.new(dx, 0, 0), Vector3.new(500, 300, 0)), false)
    end, function() end)
end)

-- B: ゲームが GetMouseDelta / IsMouseButtonPressed で聞いてきたら、偽の答えを返す(右クリック中の扱い)
addBtn("B マウス差分フック", function()
    if not hookOk then say("このDeltaは hookmetamethod に対応していません") return end
    runTest("B", function(c)
        env.IL_ON, env.IL_RMB = true, true
        c.n = "フック"
    end, function(dx)
        env.IL_DELTA = Vector2.new(dx, 0)
    end, function()
        env.IL_ON, env.IL_RMB, env.IL_DELTA = false, false, Vector2.zero
    end)
end)

-- C: 右スティック(コントローラー)
addBtn("C 右スティック(Gamepad)", function()
    runTest("C 右スティック", function(c) c.n = 0 end, function(_, c)
        c.n = fire(UIS.InputChanged, mkInput(UT.Gamepad1, US.Change, Enum.KeyCode.Thumbstick2, Vector3.zero, Vector3.new(1, 0, 0)), false)
    end, function(c)
        fire(UIS.InputChanged, mkInput(UT.Gamepad1, US.Change, Enum.KeyCode.Thumbstick2, Vector3.zero, Vector3.zero), false)
    end)
end)

-- D: 指でなぞる(TouchStarted / TouchMoved / TouchEnded)
local touch
addBtn("D 指(TouchMoved)", function()
    runTest("D 指", function(c)
        touch = mkInput(UT.Touch, US.Begin, nil, Vector3.zero, Vector3.new(700, 300, 0))
        fire(UIS.TouchStarted, touch, false)
        c.n = fire(UIS.InputBegan, touch, false)
    end, function(dx, c)
        touch.UserInputState = US.Change
        touch.Delta = Vector3.new(dx, 0, 0)
        touch.Position = touch.Position + Vector3.new(dx, 0, 0)
        fire(UIS.TouchMoved, touch, false)
        c.n = fire(UIS.InputChanged, touch, false)
    end, function()
        touch.UserInputState = US.End
        touch.Delta = Vector3.zero
        fire(UIS.TouchEnded, touch, false)
        fire(UIS.InputEnded, touch, false)
    end)
end)

-- E: 指のなぞり(TouchPan)
addBtn("E 指(TouchPan)", function()
    local total = 0
    runTest("E TouchPan", function(c)
        total = 0
        c.n = fire(UIS.TouchPan, {Vector2.new(700, 300)}, Vector2.zero, Vector2.zero, US.Begin, false)
    end, function(dx, c)
        total += dx
        c.n = fire(UIS.TouchPan, {Vector2.new(700 + total, 300)}, Vector2.new(total, 0), Vector2.new(dx * 60, 0), US.Change, false)
    end, function()
        fire(UIS.TouchPan, {Vector2.new(700 + total, 300)}, Vector2.new(total, 0), Vector2.zero, US.End, false)
    end)
end)

-- 動かす量
addBtn("量: " .. AMOUNTS[amountIdx], function(b)
    amountIdx = amountIdx % #AMOUNTS + 1
    b.Text = "量: " .. AMOUNTS[amountIdx]
end)

-- 誰が入力を受け取っているか(ゲームのスクリプト名)
addBtn("接続調査(入力を読む所)", function()
    if not getconnections then say("getconnections に対応していません") return end
    local lines = {}
    for _, name in ipairs({"InputBegan", "InputChanged", "InputEnded", "TouchStarted", "TouchMoved", "TouchEnded", "TouchPan"}) do
        local ok, conns = pcall(function() return getconnections(UIS[name]) end)
        if ok and conns then
            local owners = {}
            for _, c in ipairs(conns) do
                local label = "?"
                pcall(function()
                    local f = c.Function
                    if f then
                        local sc = rawget(getfenv(f), "script")
                        if typeof(sc) == "Instance" then label = sc:GetFullName() end
                    end
                end)
                owners[label] = (owners[label] or 0) + 1
            end
            local parts = {}
            for k, v in pairs(owners) do table.insert(parts, k .. " x" .. v) end
            table.sort(parts)
            table.insert(lines, string.format("%s (%d): %s", name, #conns, table.concat(parts, ", ")))
        else
            table.insert(lines, name .. ": 取得できません")
        end
    end
    say(table.concat(lines, "\n"))
end)

addBtn("結果をもう一度コピー", function()
    if setclipboard then pcall(setclipboard, lastOut) end
    say(lastOut .. "\n(コピーしました)")
end)

if not getconnections then
    say("注意: getconnections に対応していないので、A・C・D・E は使えません。Bだけ試せます。")
end
