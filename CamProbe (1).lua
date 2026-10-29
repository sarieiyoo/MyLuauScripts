--[[
  CamProbe (RageLiteとは別の、単独で動く実験ツール)
  ゲームが「視点の角度」を覚えている変数を探して、それを書き換えたとき
  視点と体の向きが一緒に回るかを測ります。

  手順:
   1. 「1 今の向きを記録」を押す(画面を触らない)
   2. 指で視点を回す(右でも左でもOK。タイトルの「いまの回転」が 30〜150 くらいになったら止める)
   3. 「2 変化した値を探す」を押す → 候補が出る
   4. 「3 候補を書き換えテスト」を押す → 視点と体が回るか、結果が出る
   5. 回らなければ「次の候補」を押して、3をもう一度
  結果はクリップボードにも自動でコピーされます。
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
for _, c in ipairs(env.CP_CONN or {}) do pcall(function() c:Disconnect() end) end
env.CP_CONN = {}
local function track(c) table.insert(env.CP_CONN, c) return c end

local pg = lp:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("CamProbe")
if old then old:Destroy() end

------------------------------------------------------------ 表示
local gui = Instance.new("ScreenGui")
gui.Name = "CamProbe"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = pg

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(240, 330)
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
title.Text = "CamProbe (ここをドラッグ)"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Parent = win

local list = Instance.new("Frame")
list.Size = UDim2.new(1, -8, 0, 128)
list.Position = UDim2.fromOffset(4, 26)
list.BackgroundTransparency = 1
list.Parent = win
local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 3)
lay.Parent = list

local statBox = Instance.new("ScrollingFrame")
statBox.Size = UDim2.new(1, -8, 0, 168)
statBox.Position = UDim2.fromOffset(4, 158)
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
stat.Text = "準備OK。1 → 指で視点を回す(タイトルの「いまの回転」が30〜150になるまで) → 2 → 3 の順に押してください。"
stat.Parent = statBox

local function say(t)
    stat.Text = tostring(t)
    statBox.CanvasPosition = Vector2.zero
    if setclipboard then pcall(setclipboard, tostring(t)) end
end

local function addBtn(text, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 24)
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
end

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

------------------------------------------------------------ 測る(視点と体の向き)
local function yawOf(v) return math.deg(math.atan2(-v.X, -v.Z)) end
local function diff(a, b) return (b - a + 180) % 360 - 180 end

local function snapDir()
    local cam = workspace.CurrentCamera
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local cl = cam.CFrame.LookVector
    return {cy = yawOf(cl), by = root and yawOf(root.CFrame.LookVector) or nil}
end

------------------------------------------------------------ ゲームのメモリから、数値を集める
-- 表: 文字のキーの数値(キー80個以下の表だけ) / 関数: ゲームのスクリプトの関数の、数値の外側変数(upvalue)
local MAX_ENTRIES = 120000

local function readEntry(e)
    if e.kind == "t" then
        local ok, v = pcall(rawget, e.ref, e.key)
        return ok and v or nil
    else
        local ok, a, b = pcall(debug.getupvalue, e.ref, e.key)
        if not ok then return nil end
        return (type(a) == "number") and a or b
    end
end

local function writeEntry(e, v)
    if e.kind == "t" then
        return pcall(rawset, e.ref, e.key, v)
    else
        return pcall(debug.setupvalue, e.ref, e.key, v)
    end
end

local function ownerOf(e)
    if e.kind == "u" then
        local label = "?"
        pcall(function()
            local sc = rawget(getfenv(e.ref), "script")
            if typeof(sc) == "Instance" then label = sc:GetFullName() end
        end)
        return "関数のupvalue #" .. tostring(e.key) .. " / " .. label
    end
    local keys, n = {}, 0
    pcall(function()
        for k in next, e.ref do
            n += 1
            if n <= 8 then table.insert(keys, tostring(k)) end
        end
    end)
    return "表[" .. table.concat(keys, ",") .. "] のキー " .. tostring(e.key)
end

local snap1, snapDirA, cands, sel = nil, nil, {}, 1

-- 記録したあと、視点がどれだけ回ったかを、タイトルにリアルタイムで出す
track(game:GetService("RunService").RenderStepped:Connect(function()
    if snapDirA and snap1 then
        title.Text = string.format("CamProbe  いまの回転 %+.0f°", diff(snapDirA.cy, snapDir().cy))
    end
end))

local function collect()
    local data = {}
    local gc = getgc(true)
    for _, v in ipairs(gc) do
        if #data >= MAX_ENTRIES then break end
        local tv = type(v)
        if tv == "table" then
            pcall(function()
                local buf, n = {}, 0
                for k, val in next, v do
                    n += 1
                    if n > 80 then return end
                    if type(k) == "string" and type(val) == "number" and val == val and math.abs(val) < 1e5 then
                        buf[#buf + 1] = {kind = "t", ref = v, key = k, val = val}
                    end
                end
                for _, e in ipairs(buf) do data[#data + 1] = e end
            end)
        elseif tv == "function" then
            pcall(function()
                if islclosure and not islclosure(v) then return end
                if isexecutorclosure and isexecutorclosure(v) then return end
                local ups = debug.getupvalues(v)
                for idx, up in pairs(ups) do
                    if type(up) == "number" and up == up and math.abs(up) < 1e5 then
                        data[#data + 1] = {kind = "u", ref = v, key = idx, val = up}
                    end
                end
            end)
        end
    end
    return data
end

------------------------------------------------------------ ボタン
addBtn("1 今の向きを記録", function()
    if not (getgc and debug and debug.getupvalues) then
        say("このDeltaは getgc / debug.getupvalues に対応していないので、この調査はできません")
        return
    end
    say("記録中…(少し重くなります)")
    task.spawn(function()
        snapDirA = snapDir()
        snap1 = collect()
        say(string.format("記録しました(%d個の数値)。\n画面の右側を指でスワイプして、視点を回してください。タイトルの「いまの回転」が30〜150(マイナスでも可)になったら、「2 変化した値を探す」を押してください。", #snap1))
    end)
end)

addBtn("2 変化した値を探す", function()
    if not snap1 then say("先に「1 今の向きを記録」を押してください") return end
    local nowDir = snapDir()
    local dyaw = diff(snapDirA.cy, nowDir.cy)
    if math.abs(dyaw) < 10 then say("視点がほとんど回っていません(" .. string.format("%.1f", dyaw) .. "°)。画面の右側を指でスワイプして、「いまの回転」が30〜150になってから、もう一度押してください。") return end
    local er, ed = math.abs(math.rad(dyaw)), math.abs(dyaw)
    local found = {}
    for _, e in ipairs(snap1) do
        local cur = readEntry(e)
        if type(cur) == "number" then
            local d = math.abs(cur - e.val)
            if d > 1e-6 then
                local sr, sd = math.abs(d - er) / er, math.abs(d - ed) / ed
                local score, unit = sr, "rad"
                if sd < sr then score, unit = sd, "deg" end
                if score < 0.2 then
                    found[#found + 1] = {e = e, score = score, unit = unit, old = e.val, cur = cur}
                end
            end
        end
    end
    table.sort(found, function(a, b) return a.score < b.score end)
    cands, sel = found, 1
    local lines = {string.format("視点の変化: %+.1f° / 候補 %d個", dyaw, #found)}
    for i = 1, math.min(#found, 8) do
        local c = found[i]
        table.insert(lines, string.format("%d) %s  %s  %.3f→%.3f (%s)", i, ownerOf(c.e), "", c.old, c.cur, c.unit))
    end
    if #found == 0 then
        table.insert(lines, "候補なし。視点の角度を、ゲームが別の形(行列など)で持っている可能性があります。")
    else
        table.insert(lines, "「3 候補を書き換えテスト」を押してください。")
    end
    say(table.concat(lines, "\n"))
end)

addBtn("3 候補を書き換えテスト", function()
    local c = cands[sel]
    if not c then say("候補がありません。先に「2 変化した値を探す」を押してください") return end
    task.spawn(function()
        local before = snapDir()
        local orig = readEntry(c.e)
        if type(orig) ~= "number" then say("この候補はもう読めません。次の候補を試してください") return end
        local step = (c.unit == "rad") and math.rad(30) or 30
        local ok = writeEntry(c.e, orig + step)
        task.wait(0.4)
        local after = snapDir()
        writeEntry(c.e, orig)   -- 元に戻す
        local dc = diff(before.cy, after.cy)
        local db = (before.by and after.by) and diff(before.by, after.by) or nil
        local moved = math.abs(dc) > 2
        local followed = db ~= nil and math.abs(db) > 2 and math.abs(db) > math.abs(dc) * 0.5
        say(table.concat({
            string.format("候補 %d/%d: %s", sel, #cands, ownerOf(c.e)),
            "書き込み: " .. (ok and "成功" or "失敗") .. string.format(" (+%s %s)", tostring(step), c.unit),
            string.format("視点: %+.1f° → %s", dc, moved and "回った" or "変化なし"),
            db and string.format("体: %+.1f° → %s", db, (not moved) and "-" or (followed and "ついてきた" or "置いていかれた")) or "体: 測れません",
            "(値は元に戻しました)",
        }, "\n"))
    end)
end)

addBtn("次の候補", function()
    if #cands == 0 then say("候補がありません") return end
    sel = sel % #cands + 1
    local c = cands[sel]
    say(string.format("候補 %d/%d に切り替えました\n%s\n%.3f→%.3f (%s)\n「3 候補を書き換えテスト」を押してください。",
        sel, #cands, ownerOf(c.e), c.old, c.cur, c.unit))
end)
