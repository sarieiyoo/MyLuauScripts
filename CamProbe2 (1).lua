--[[
  CamProbe2 (RageLiteとは別の、単独で動く調査ツール)
  ゲームの「視点」と「体の向き」を決めている場所を探します。結果はクリップボードにも自動でコピーされます。

  すぐ分かる調査(押すだけ):
    A スクリプト一覧 / B 毎フレーム動く所 / C 体の向きの調査
  角度の変数を探す(比率で探す方法):
    R1 基準を記録 → 指で視点を回す(タイトルの「いまの回転」が30以上) → R2 記録
    → もっと回す(R2のときと30%以上ちがう角度) → R3 判定 → 候補を書き換えテスト
  ベクトルの変数を探す(視点の向きそのものが入っている変数):
    E ベクトルを探す → 候補を書き換えテスト
  このゲームでは視点と体の向きを MechanicsController が決めている可能性が高いので、
    M(中身の調査) / R1M・EM(MechanicsControllerだけを調べる版) を先に試してください
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
for _, c in ipairs(env.CP2_CONN or {}) do pcall(function() c:Disconnect() end) end
env.CP2_CONN = {}
local function track(c) table.insert(env.CP2_CONN, c) return c end

local pg = lp:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("CamProbe2")
if old then old:Destroy() end

------------------------------------------------------------ 表示
local gui = Instance.new("ScreenGui")
gui.Name = "CamProbe2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = pg

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(250, 380)
win.Position = UDim2.fromOffset(10, 40)
win.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
win.BorderSizePixel = 0
win.Parent = gui
local wc = Instance.new("UICorner")
wc.CornerRadius = UDim.new(0, 8)
wc.Parent = win

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Text = "CamProbe2 (ここをドラッグ)"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Parent = win

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -8, 0, 176)
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
statBox.Size = UDim2.new(1, -8, 0, 168)
statBox.Position = UDim2.fromOffset(4, 208)
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
stat.Text = "準備OK。A・B・C は押すだけで調べられます。"
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

-- 視点の横の向きを、一周しても途切れないように足し上げていく(いまの回転 = acc - 基準)
local acc, prevY = 0, nil
local accBase = nil
track(RunService.RenderStepped:Connect(function()
    local y = yawOf(workspace.CurrentCamera.CFrame.LookVector)
    if prevY then acc += diff(prevY, y) end
    prevY = y
    if accBase then
        title.Text = string.format("CamProbe2  いまの回転 %+.0f°", acc - accBase)
    end
end))

local function snapDir()
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    return {cy = yawOf(workspace.CurrentCamera.CFrame.LookVector),
        by = root and yawOf(root.CFrame.LookVector) or nil}
end

local function report(head, before, after, extra)
    local dc = diff(before.cy, after.cy)
    local db = (before.by and after.by) and diff(before.by, after.by) or nil
    local moved = math.abs(dc) > 2
    local followed = db ~= nil and math.abs(db) > 2 and math.abs(db) > math.abs(dc) * 0.5
    local lines = {head}
    for _, l in ipairs(extra or {}) do table.insert(lines, l) end
    table.insert(lines, string.format("視点: %+.1f° → %s", dc, moved and "回った" or "変化なし"))
    table.insert(lines, db and string.format("体: %+.1f° → %s", db,
        (not moved) and "-" or (followed and "ついてきた" or "置いていかれた")) or "体: 測れません")
    return table.concat(lines, "\n")
end

------------------------------------------------------------ 持ち主(スクリプト名)を調べる
local function scriptOf(f)
    local label = "?"
    pcall(function()
        local sc = rawget(getfenv(f), "script")
        if typeof(sc) == "Instance" then label = sc:GetFullName() end
    end)
    return label
end

local function short(path)
    return (tostring(path):gsub("^Players%.[^%.]+%.", ""))
end

local MECH = "MechanicsController"

local function findScript(name)
    local ps = lp:FindFirstChild("PlayerScripts")
    if not ps then return nil end
    for _, d in ipairs(ps:GetDescendants()) do
        if d.Name == name and (d:IsA("ModuleScript") or d:IsA("LocalScript")) then return d end
    end
end


------------------------------------------------------------ A / B / C: 押すだけの調査
local HOT = {"camera", "look", "view", "input", "aim", "rotate", "mouse", "first", "person", "cam", "char", "move", "control", "touch"}
local function hot(name)
    name = name:lower()
    for _, w in ipairs(HOT) do
        if name:find(w, 1, true) then return true end
    end
    return false
end

addBtn("A スクリプト一覧", function()
    local lines, n = {}, 0
    local function scan(root, label)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("LocalScript") or d:IsA("ModuleScript") then
                n += 1
                if n <= 120 then
                    table.insert(lines, (hot(d.Name) and "★ " or "  ") .. label .. short(d:GetFullName()))
                end
            end
        end
    end
    local ps = lp:FindFirstChild("PlayerScripts")
    if ps then scan(ps, "") end
    scan(pg, "[Gui] ")
    if lp.Character then scan(lp.Character, "[Char] ") end
    table.insert(lines, 1, string.format("スクリプト %d個 (★=視点・入力・移動に関係しそうな名前)", n))
    say(table.concat(lines, "\n"))
end)

addBtn("B 毎フレーム動く所", function()
    if not getconnections then say("getconnections に対応していません") return end
    local lines = {}
    for _, name in ipairs({"RenderStepped", "Heartbeat", "Stepped"}) do
        local ok, conns = pcall(function() return getconnections(RunService[name]) end)
        if ok and conns then
            local owners = {}
            for _, c in ipairs(conns) do
                local f
                pcall(function() f = c.Function end)
                local label = f and short(scriptOf(f)) or "?"
                owners[label] = (owners[label] or 0) + 1
            end
            local parts = {}
            for k, v in pairs(owners) do table.insert(parts, k .. " x" .. v) end
            table.sort(parts)
            table.insert(lines, string.format("%s (%d)", name, #conns))
            for _, p in ipairs(parts) do table.insert(lines, "  " .. p) end
        end
    end
    say(table.concat(lines, "\n"))
end)

addBtn("C 体の向きの調査", function()
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    local lines = {}
    if hum then
        table.insert(lines, "AutoRotate: " .. tostring(hum.AutoRotate))
        table.insert(lines, "PlatformStand: " .. tostring(hum.PlatformStand))
        table.insert(lines, "RigType: " .. tostring(hum.RigType))
    end
    table.insert(lines, "CameraType: " .. tostring(cam.CameraType))
    table.insert(lines, "CameraSubject: " .. (cam.CameraSubject and cam.CameraSubject.ClassName or "なし"))
    table.insert(lines, "MouseBehavior: " .. tostring(UIS.MouseBehavior))
    pcall(function()
        local ugs = UserSettings():GetService("UserGameSettings")
        table.insert(lines, "RotationType: " .. tostring(ugs.RotationType))
    end)
    if root then
        local found = {}
        for _, d in ipairs(root:GetDescendants()) do
            local cn = d.ClassName
            if cn:find("Align") or cn:find("Gyro") or cn:find("Body") or cn:find("Constraint") or cn:find("Orientation") then
                table.insert(found, cn .. ":" .. d.Name)
            end
        end
        for _, d in ipairs(char:GetChildren()) do
            if d:IsA("Script") or d:IsA("LocalScript") then table.insert(found, "スクリプト:" .. d.Name) end
        end
        table.insert(lines, "体の向きを決めていそうなもの: " .. (#found > 0 and table.concat(found, ", ") or "なし"))
    end
    say(table.concat(lines, "\n"))
end)

addBtn("M Mechanicsの中身", function()
    if not (getgc and debug and debug.getupvalues) then say("getgc / debug.getupvalues に対応していません") return end
    local sc = findScript(MECH)
    if not sc then say(MECH .. " が見つかりません") return end
    task.spawn(function()
        local full = sc:GetFullName()
        local lines = {"== " .. short(full) .. " =="}
        local okm, mod = pcall(require, sc)
        if okm and type(mod) == "table" then
            table.insert(lines, "[モジュールの中身]")
            local keys = {}
            for k, v in next, mod do
                local tv = typeof(v)
                local desc = tv
                if tv == "number" or tv == "string" or tv == "boolean" or tv == "Vector3" or tv == "Vector2" or tv == "CFrame" then
                    desc = tv .. "=" .. tostring(v):sub(1, 40)
                end
                keys[#keys + 1] = tostring(k) .. ": " .. desc
            end
            table.sort(keys)
            for i = 1, math.min(#keys, 60) do lines[#lines + 1] = "  " .. keys[i] end
        else
            table.insert(lines, "require できませんでした")
        end
        local HINT = {"yaw", "pitch", "look", "angle", "rot", "cam", "aim", "dir", "mouse", "delta", "sens", "turn", "face", "view", "orient", "tilt"}
        local nf, hints = 0, {}
        table.insert(lines, "[関数(最大25個)]")
        for _, f in ipairs(getgc()) do
            if type(f) == "function" then
                pcall(function()
                    if islclosure and not islclosure(f) then return end
                    if isexecutorclosure and isexecutorclosure(f) then return end
                    if scriptOf(f) ~= full then return end
                    nf += 1
                    local name = (debug.info and debug.info(f, "n")) or "?"
                    local consts, ups = {}, {}
                    if debug.getconstants then
                        for _, c in pairs(debug.getconstants(f)) do
                            if type(c) == "string" and #c > 1 and #c < 26 then
                                consts[#consts + 1] = c
                                local cl = c:lower()
                                for _, w in ipairs(HINT) do
                                    if cl:find(w, 1, true) then hints[c] = true end
                                end
                            end
                        end
                    end
                    for idx, up in pairs(debug.getupvalues(f)) do
                        local tv = typeof(up)
                        if tv == "number" or tv == "Vector3" or tv == "Vector2" or tv == "CFrame" then
                            ups[#ups + 1] = "#" .. idx .. "=" .. tostring(up):sub(1, 36)
                        end
                    end
                    if nf <= 25 then
                        lines[#lines + 1] = string.format("fn %s: 定数[%s] 変数[%s]", tostring(name),
                            table.concat(consts, ","):sub(1, 150), table.concat(ups, " "):sub(1, 150))
                    end
                end)
            end
        end
        local hs = {}
        for h in pairs(hints) do hs[#hs + 1] = h end
        table.sort(hs)
        table.insert(lines, string.format("関数の数: %d", nf))
        table.insert(lines, "手がかりの文字(視点・向きに関係しそうな定数): " .. (#hs > 0 and table.concat(hs, ", ") or "なし"))
        say(table.concat(lines, "\n"))
    end)
end)

------------------------------------------------------------ メモリから集める(表の数値・関数の外側変数)
local MAX_ENTRIES = 120000

local function readEntry(e)
    if e.kind == "t" then
        local ok, v = pcall(rawget, e.ref, e.key)
        return ok and v or nil
    else
        local ok, a, b = pcall(debug.getupvalue, e.ref, e.key)
        if not ok then return nil end
        if type(a) == "string" then return b end
        return a
    end
end

local function writeEntry(e, v)
    if e.kind == "t" then return pcall(rawset, e.ref, e.key, v) end
    return pcall(debug.setupvalue, e.ref, e.key, v)
end

local function ownerOf(e)
    if e.kind == "u" then
        return "関数のupvalue #" .. tostring(e.key) .. " / " .. short(scriptOf(e.ref))
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

-- accept(値) が真のものだけ集める
local function collect(accept)
    local data = {}
    for _, v in ipairs(getgc(true)) do
        if #data >= MAX_ENTRIES then break end
        local tv = type(v)
        if tv == "table" then
            pcall(function()
                local buf, n = {}, 0
                for k, val in next, v do
                    n += 1
                    if n > 80 then return end
                    if type(k) == "string" and accept(val) then
                        buf[#buf + 1] = {kind = "t", ref = v, key = k, val = val}
                    end
                end
                for _, e in ipairs(buf) do data[#data + 1] = e end
            end)
        elseif tv == "function" then
            pcall(function()
                if islclosure and not islclosure(v) then return end
                if isexecutorclosure and isexecutorclosure(v) then return end
                for idx, up in pairs(debug.getupvalues(v)) do
                    if accept(up) then data[#data + 1] = {kind = "u", ref = v, key = idx, val = up} end
                end
            end)
        end
    end
    return data
end

-- MechanicsController のモジュールの表(3階層まで)と、そのスクリプトの関数の外側変数(とその中の表)だけを集める
local function collectMech(accept)
    local sc = findScript(MECH)
    if not sc then return nil end
    local full = sc:GetFullName()
    local data, seen = {}, {}
    local function addTable(t, depth)
        if seen[t] or #data >= MAX_ENTRIES then return end
        seen[t] = true
        local n = 0
        pcall(function()
            for k, val in next, t do
                n += 1
                if n > 300 then break end
                if type(k) == "string" and accept(val) then
                    data[#data + 1] = {kind = "t", ref = t, key = k, val = val, mech = true}
                end
                if depth > 0 and type(val) == "table" then addTable(val, depth - 1) end
            end
        end)
    end
    pcall(function()
        local mod = require(sc)
        if type(mod) == "table" then addTable(mod, 3) end
    end)
    for _, f in ipairs(getgc()) do
        if type(f) == "function" then
            pcall(function()
                if islclosure and not islclosure(f) then return end
                if isexecutorclosure and isexecutorclosure(f) then return end
                if scriptOf(f) ~= full then return end
                for idx, up in pairs(debug.getupvalues(f)) do
                    if accept(up) then data[#data + 1] = {kind = "u", ref = f, key = idx, val = up, mech = true} end
                    if type(up) == "table" then addTable(up, 3) end
                end
            end)
        end
    end
    return data
end

local function needGc()
    if getgc and debug and debug.getupvalues then return true end
    say("このDeltaは getgc / debug.getupvalues に対応していないので、この調査はできません")
    return false
end

------------------------------------------------------------ R: 比率で探す
-- 視点を2回、別の量だけ回して、「変化量 ÷ 回した角度」が同じになる値を探す(単位が何でも見つかる)
local base, d1, cands, sel, kind = nil, nil, {}, 1, nil
local acc1

local function isNum(v) return type(v) == "number" and v == v and math.abs(v) < 1e5 end

local function recordBase(label, collectFn)
    if not needGc() then return end
    say("記録中…(少し重くなります)")
    task.spawn(function()
        accBase = acc
        local data = collectFn(isNum)
        if not data then say(MECH .. " が見つかりません") return end
        base = data
        d1, cands = nil, {}
        say(string.format("%s: 記録しました(%d個)。\n指で視点を回して、タイトルの「いまの回転」が30以上(マイナスでも可)になったら、R2を押してください。", label, #base))
    end)
end
addBtn("R1M 基準を記録(Mechanicsだけ)", function() recordBase("Mechanicsだけ", collectMech) end)
addBtn("R1 基準を記録(全体)", function() recordBase("全体", collect) end)

addBtn("R2 記録(1回目)", function()
    if not base then say("先にR1を押してください") return end
    acc1 = acc - accBase
    if math.abs(acc1) < 30 then say(string.format("回転が足りません(%+.0f°)。30以上まで回してください。", acc1)) return end
    d1 = {}
    for i, e in ipairs(base) do
        local cur = readEntry(e)
        d1[i] = (type(cur) == "number") and (cur - e.val) or 0
    end
    say(string.format("1回目を記録しました(回転 %+.0f°)。\nさらに回して、R2のときより30%%以上ちがう角度にしてから、R3を押してください。", acc1))
end)

addBtn("R3 判定", function()
    if not d1 then say("先にR2を押してください") return end
    local acc2 = acc - accBase
    if math.abs(acc2) < 30 or math.abs(acc2 - acc1) < 0.3 * math.abs(acc1) then
        say(string.format("1回目(%+.0f°)と今(%+.0f°)の差が小さいです。もっと回してから、もう一度R3を押してください。", acc1, acc2))
        return
    end
    local found = {}
    for i, e in ipairs(base) do
        local v1 = d1[i]
        if v1 ~= 0 then
            local cur = readEntry(e)
            if type(cur) == "number" then
                local v2 = cur - e.val
                -- 整数だけの変化(回数を数えるカウンター)は除く
                local integerOnly = (v1 == math.floor(v1)) and (v2 == math.floor(v2))
                if v2 ~= 0 and not integerOnly then
                    local k1, k2 = v1 / acc1, v2 / acc2
                    local score = math.abs(k1 - k2) / math.max(math.abs(k1), math.abs(k2))
                    if score < 0.12 then
                        found[#found + 1] = {e = e, score = score, k = k2, old = e.val, cur = cur}
                    end
                end
            end
        end
    end
    table.sort(found, function(a, b) return a.score < b.score end)
    -- MechanicsController 由来の候補を先頭に(順番はそのまま)
    local function isMech(e)
        if e.mech then return true end
        return e.kind == "u" and scriptOf(e.ref):find(MECH, 1, true) ~= nil
    end
    local first, rest = {}, {}
    for _, c in ipairs(found) do
        if isMech(c.e) then first[#first + 1] = c else rest[#rest + 1] = c end
    end
    for _, c in ipairs(rest) do first[#first + 1] = c end
    found = first
    cands, sel, kind = found, 1, "ratio"
    local lines = {string.format("1回目 %+.0f° / 今 %+.0f° / 候補 %d個", acc1, acc2, #found)}
    for i = 1, math.min(#found, 8) do
        local c = found[i]
        local unit = (math.abs(math.abs(c.k) - 1) < 0.1 and "度") or (math.abs(math.abs(c.k) - math.rad(1)) < 0.002 and "rad") or "その他"
        table.insert(lines, string.format("%d) %s%s\n   1度あたり %.5f (%s)", i, c.e.mech and "★Mech " or "", ownerOf(c.e), c.k, unit))
    end
    if #found == 0 then
        table.insert(lines, "候補なし。角度が数値ではなく、ベクトルなどの形で入っている可能性があります。Eを試してください。")
    else
        table.insert(lines, "「候補を書き換えテスト」を押してください。")
    end
    say(table.concat(lines, "\n"))
end)

------------------------------------------------------------ E: ベクトルで探す
-- 視点の向きそのもの(Vector3 / CFrame)が入っている変数を探す
local function runVec(label, collectFn)
    if not needGc() then return end
    say("探しています…(少し重くなります)")
    task.spawn(function()
        local look = workspace.CurrentCamera.CFrame.LookVector
        local function accept(v)
            local tv = typeof(v)
            if tv == "Vector3" then
                local m = v.Magnitude
                return m > 0.9 and m < 1.1 and v.Unit:Dot(look) > 0.995
            elseif tv == "CFrame" then
                return v.LookVector:Dot(look) > 0.995
            end
            return false
        end
        local data = collectFn(accept)
        if not data then say(MECH .. " が見つかりません") return end
        for _, e in ipairs(data) do e.vt = typeof(e.val) end
        cands, sel, kind = data, 1, "vector"
        local lines = {string.format("%s: 視点の向きと一致するベクトルの変数: %d個", label, #data)}
        for i = 1, math.min(#data, 8) do
            lines[#lines + 1] = string.format("%d) %s (%s)", i, ownerOf(data[i]), data[i].vt)
        end
        if #data > 0 then lines[#lines + 1] = "「候補を書き換えテスト」を押してください。" end
        say(table.concat(lines, "\n"))
    end)
end
addBtn("EM ベクトル(Mechanicsだけ)", function() runVec("Mechanicsだけ", collectMech) end)
addBtn("E ベクトル(全体)", function() runVec("全体", collect) end)

------------------------------------------------------------ 書き換えテスト
addBtn("候補を書き換えテスト", function()
    local c = cands[sel]
    if not c then say("候補がありません") return end
    task.spawn(function()
        local e = c.e or c
        local orig = readEntry(e)
        if orig == nil then say("この候補はもう読めません。次の候補を試してください") return end
        local newv, desc
        if kind == "ratio" then
            if type(orig) ~= "number" then say("この候補はもう読めません") return end
            newv = orig + c.k * 30
            desc = string.format("+30°分 (%+.4f)", c.k * 30)
        else
            local rot = CFrame.Angles(0, math.rad(30), 0)
            if typeof(orig) == "Vector3" then
                newv = rot:VectorToWorldSpace(orig)
            else
                newv = CFrame.new(orig.Position) * rot * (orig - orig.Position)
            end
            desc = "横に+30°回した値"
        end
        local before = snapDir()
        local ok = writeEntry(e, newv)
        task.wait(0.15)
        local mid = snapDir()
        task.wait(0.3)
        local after = snapDir()
        writeEntry(e, orig)   -- 元に戻す
        local text = report(
            string.format("候補 %d/%d: %s", sel, #cands, ownerOf(e)),
            before, (math.abs(diff(before.cy, after.cy)) >= math.abs(diff(before.cy, mid.cy))) and after or mid,
            {"書き込み: " .. (ok and "成功" or "失敗") .. " / " .. desc})
        say(text .. "\n(値は元に戻しました)")
    end)
end)

addBtn("次の候補", function()
    if #cands == 0 then say("候補がありません") return end
    sel = sel % #cands + 1
    local c = cands[sel]
    local e = c.e or c
    say(string.format("候補 %d/%d に切り替えました\n%s\n「候補を書き換えテスト」を押してください。", sel, #cands, ownerOf(e)))
end)
