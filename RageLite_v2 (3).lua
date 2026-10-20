--[[
  RageLite 完成版 v2 (1ファイル)
  中身: UI → チーム判別 → 本体 → 定期帰還 → ESP/エイムボット/サイレントエイム
  入り直してから、このファイルだけを実行してください。
  各ブロックは do ... end で区切ってあります。
]]

------------------------------------------------------------
-- ① パート1: メニュー本体
------------------------------------------------------------
do
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local SCALE = 0.75   -- UIの大きさ(0.6〜1.0)

local env = (getgenv and getgenv()) or _G
for _, k in ipairs({"RL_CONN", "RL_C1", "RL_C2"}) do
    for _, c in ipairs(env[k] or {}) do pcall(function() c:Disconnect() end) end
end
env.RL_CONN, env.RL_TOKEN2, env.RL_TOKEN3, env.RL_HOME = {}, nil, nil, nil
local function track(c) table.insert(env.RL_CONN, c) return c end
for _, n in ipairs({"FreeCamView", "RL_Fire", "RL_Restore", "RL_Fly", "RL_Save"}) do
    pcall(function() RunService:UnbindFromRenderStep(n) end)
end
local pg = lp:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("RageLite")
if old then old:Destroy() end
local og = workspace:FindFirstChild("RL_Ghost")
if og then og:Destroy() end

local S = {rage = false, auto = true, mode = "TP検知", delay = 3, tp = true, team = true,
    cd = false, div = 4, fc = false, speed = 60}
local R = {}
local FC = {pos = Vector3.zero, yaw = 0, pitch = 0, up = false, down = false, cf = nil}
local ST = {attacking = false, autoStarted = false, lastSet = nil}

-- 保存された設定を読み込む(UIを作る前に反映するので、メニューの表示にも効く)
local SAVE_FILE = "RageLite_settings.json"
local SAVE_KEYS = {"mode", "delay", "tp", "team", "cd", "div", "speed", "part", "predict", "depth",
    "view", "unk", "home", "homeEvery", "esp", "hpbar", "nameDist", "fovCircle", "aim", "aimSpeed",
    "aimFov", "aimWall", "sa", "saChance", "aimPart", "saPart", "bodyFollow", "autosave", "espWeapon", "avoidReflect", "walk", "walkSpeed", "saScreenRay", "saHold",
    "prio", "reflectMode", "infJump", "knife", "knifeDist", "knifeStay", "knifeWait", "animFast",
    "fireN", "lagAnim", "lagFx", "lagBullet", "lagHit", "lagSelf"}
local SAVE_LOADED = false
pcall(function()
    if not (isfile and readfile and isfile(SAVE_FILE)) then return end
    local data = game:GetService("HttpService"):JSONDecode(readfile(SAVE_FILE))
    if type(data) ~= "table" then return end
    for _, k in ipairs(SAVE_KEYS) do
        local v = data[k]
        local tv = type(v)
        if v ~= nil and (tv == "boolean" or tv == "number" or tv == "string") then
            if S[k] == nil or type(S[k]) == tv then S[k] = v end
        end
    end
    SAVE_LOADED = true
end)

local function U(n) return math.max(1, math.floor(n * SCALE + 0.5)) end
local TS = math.max(9, U(13))
local C = {
    bg = Color3.fromRGB(16, 16, 22), side = Color3.fromRGB(22, 22, 30),
    panel = Color3.fromRGB(28, 28, 38), row = Color3.fromRGB(36, 36, 48),
    text = Color3.fromRGB(235, 235, 240), dim = Color3.fromRGB(140, 140, 155),
    acc = Color3.fromRGB(225, 60, 70), off = Color3.fromRGB(70, 70, 84),
    btn = Color3.fromRGB(48, 48, 66),
}
local function corner(o, r)
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = o
end
local function round(o)
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = o
end
local function txt(parent, text, size, color, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size
    l.TextColor3 = color
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local gui = Instance.new("ScreenGui")
gui.Name = "RageLite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = pg

local W, HEAD, SIDE, STAT, BODY = U(430), U(40), U(46), U(42), U(250)
local FULL_H = HEAD + BODY + STAT

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(W, FULL_H)
win.Position = UDim2.new(1, -W - 10, 0, 40)
win.BackgroundColor3 = C.bg
win.BorderSizePixel = 0
win.Active = true
win.Parent = gui
corner(win, 8)

local head = Instance.new("Frame")
head.Size = UDim2.new(1, 0, 0, HEAD)
head.BackgroundColor3 = C.side
head.BorderSizePixel = 0
head.Parent = win
corner(head, 8)

local title = txt(head, "Combat", math.max(11, U(16)), C.text)
title.Font = Enum.Font.GothamBold
title.Size = UDim2.new(0.5, 0, 0, U(20))
title.Position = UDim2.fromOffset(U(10), U(4))

local sub = txt(head, "自動照準・RAGEBOT", math.max(8, U(11)), C.dim)
sub.Size = UDim2.new(0.5, 0, 0, U(14))
sub.Position = UDim2.fromOffset(U(10), U(22))

local quick = Instance.new("TextButton")
quick.Size = UDim2.fromOffset(U(70), U(24))
quick.Position = UDim2.new(1, -U(28) - U(70) - U(10), 0.5, -U(12))
quick.TextColor3 = C.text
quick.Font = Enum.Font.GothamBold
quick.TextSize = TS
quick.Parent = head
corner(quick, 6)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(U(26), U(24))
minBtn.Position = UDim2.new(1, -U(26) - U(6), 0.5, -U(12))
minBtn.BackgroundColor3 = C.btn
minBtn.Text = "–"
minBtn.TextColor3 = C.text
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = TS + 2
minBtn.Parent = head
corner(minBtn, 6)

local side = Instance.new("Frame")
side.Size = UDim2.fromOffset(SIDE, BODY)
side.Position = UDim2.fromOffset(0, HEAD)
side.BackgroundColor3 = C.side
side.BorderSizePixel = 0
side.Parent = win

local content = Instance.new("Frame")
content.Size = UDim2.fromOffset(W - SIDE, BODY)
content.Position = UDim2.fromOffset(SIDE, HEAD)
content.BackgroundTransparency = 1
content.Parent = win

local statBox = Instance.new("ScrollingFrame")
statBox.Size = UDim2.new(1, -U(10), 0, STAT - U(6))
statBox.Position = UDim2.fromOffset(U(5), HEAD + BODY + U(3))
statBox.BackgroundColor3 = C.side
statBox.BorderSizePixel = 0
statBox.ScrollBarThickness = 2
statBox.CanvasSize = UDim2.new()
statBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
statBox.Parent = win
corner(statBox, 6)

local statLbl = txt(statBox, "読み込み中...", math.max(8, TS - 1), C.text)
statLbl.Size = UDim2.new(1, -8, 0, 0)
statLbl.Position = UDim2.fromOffset(5, 2)
statLbl.AutomaticSize = Enum.AutomaticSize.Y
statLbl.TextWrapped = true
statLbl.TextYAlignment = Enum.TextYAlignment.Top
local function say(t) statLbl.Text = tostring(t) statBox.CanvasPosition = Vector2.zero end

local TABS = {"戦闘", "視点", "調査", "ESP"}
local TITLES = {"Combat", "View", "Debug", "ESP / Aim"}
local SUBS = {"自動照準・RAGEBOT", "視点操作・飛行 / フリー", "開始・チームの調査", "ESP・エイムボット・サイレントエイム"}
local HEADERS = {{"General", "Strategy"}, {"View", "Controls"}, {"Debug", "Settings"}, {"Visual", "Aim"}}

local MAP = {
    ["RAGE"] = {1, 1}, ["自動開始"] = {1, 1}, ["開始の検知"] = {1, 1}, ["開始待ち(秒)"] = {1, 1},
    ["チームチェック"] = {1, 1}, ["チーム不明時"] = {1, 1}, ["CD短縮"] = {1, 1}, ["CD倍率"] = {1, 1},
    ["狙う部位"] = {1, 2}, ["先読み"] = {1, 2}, ["足元TP"] = {1, 2}, ["TPの深さ"] = {1, 2},
    ["定期スポーン帰還"] = {1, 2}, ["帰還間隔"] = {1, 2},
    ["視点操作"] = {2, 1}, ["視点モード"] = {2, 1}, ["視点の速さ"] = {2, 1},
    ["▲ 上昇(押しっぱなし)"] = {2, 2}, ["▼ 下降(押しっぱなし)"] = {2, 2},
    ["開始シグナル調査"] = {3, 1}, ["チーム調査"] = {3, 1},
    ["ESP"] = {4, 1}, ["体力バー"] = {4, 1}, ["名前・距離"] = {4, 1}, ["FOV円"] = {4, 1},
    ["エイムボット"] = {4, 2}, ["エイム速度"] = {4, 2}, ["エイムFOV"] = {4, 2}, ["壁チェック"] = {4, 2},
    ["サイレントエイム"] = {4, 2}, ["SA命中率"] = {4, 2},
    ["エイム部位"] = {4, 2}, ["体も追従"] = {4, 2}, ["SA部位"] = {4, 2},
    ["自動保存"] = {3, 2}, ["設定を保存"] = {3, 2}, ["設定を初期化"] = {3, 2},
    ["足速度変更"] = {1, 2}, ["足の速さ"] = {1, 2}, ["武器表示"] = {4, 1}, ["反射回避"] = {4, 2}, ["反射調査"] = {3, 1},
    ["画面レイ変更"] = {4, 2}, ["撃つ間だけ"] = {4, 2}, ["SA調査"] = {3, 1},
    ["優先順位"] = {1, 1}, ["反射検知"] = {4, 2},
    ["ナイフモード"] = {1, 2}, ["ナイフ距離"] = {1, 2}, ["ナイフ滞在"] = {1, 2}, ["ナイフ待機"] = {1, 2},
    ["無限ジャンプ"] = {1, 2}, ["アニメ高速"] = {1, 2}, ["連射回数"] = {1, 2},
    ["他人のアニメ停止"] = {3, 2}, ["自分のアニメ停止"] = {3, 2}, ["エフェクト削除"] = {3, 2},
    ["弾の描画を消す"] = {3, 2}, ["ヒット演出を消す"] = {3, 2}, ["ラグ調査"] = {3, 1},
}

local pages, tabBtns, cols, count = {}, {}, {}, {}

local function showTab(n)
    for i, p in ipairs(pages) do
        p.Visible = (i == n)
        tabBtns[i].BackgroundColor3 = (i == n) and C.panel or C.side
        tabBtns[i].TextColor3 = (i == n) and C.acc or C.dim
    end
    title.Text, sub.Text = TITLES[n], SUBS[n]
end

for t = 1, 4 do
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(1, -U(6), 0, U(40))
    tb.Position = UDim2.fromOffset(U(3), U(6) + (t - 1) * (U(40) + U(4)))
    tb.Text = TABS[t]
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = TS
    tb.Parent = side
    corner(tb, 6)
    tabBtns[t] = tb
    tb.Activated:Connect(function() showTab(t) end)

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Parent = content
    pages[t] = page
    cols[t] = {}
    for c = 1, 2 do
        local sf = Instance.new("ScrollingFrame")
        sf.Size = UDim2.new(0.5, -U(6), 1, -U(8))
        sf.Position = UDim2.new(c == 1 and 0 or 0.5, c == 1 and U(4) or U(2), 0, U(4))
        sf.BackgroundColor3 = C.panel
        sf.BorderSizePixel = 0
        sf.ScrollBarThickness = 2
        sf.ScrollingDirection = Enum.ScrollingDirection.Y
        sf.CanvasSize = UDim2.new()
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.Parent = page
        corner(sf, 6)
        local lay = Instance.new("UIListLayout")
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, U(4))
        lay.Parent = sf
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft, pad.PaddingRight = UDim.new(0, U(4)), UDim.new(0, U(4))
        pad.PaddingTop, pad.PaddingBottom = UDim.new(0, U(4)), UDim.new(0, U(4))
        pad.Parent = sf
        local h = txt(sf, HEADERS[t][c], TS, C.dim)
        h.Font = Enum.Font.GothamBold
        h.Size = UDim2.new(1, 0, 0, U(16))
        h.LayoutOrder = 0
        cols[t][c] = sf
        count[sf] = 0
    end
end

local function colFor(label)
    local m = MAP[label] or {1, 1}
    local sf = cols[m[1]][m[2]]
    count[sf] += 1
    return sf, count[sf]
end

local minimized = false
minBtn.Activated:Connect(function()
    minimized = not minimized
    side.Visible, content.Visible, statBox.Visible = not minimized, not minimized, not minimized
    win.Size = UDim2.fromOffset(W, minimized and HEAD or FULL_H)
    minBtn.Text = minimized and "＋" or "–"
end)

local dragging, sliding, dStart, wStart = false, false, nil, nil
head.InputBegan:Connect(function(i)
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

local function newRow(label, h, isBtn)
    local sf, order = colFor(label)
    local row = Instance.new(isBtn and "TextButton" or "Frame")
    row.Size = UDim2.new(1, 0, 0, h)
    row.BackgroundColor3 = C.row
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    if isBtn then row.Text = "" row.AutoButtonColor = false end
    row.Parent = sf
    corner(row, 5)
    return row
end

local function rowLabel(row, label)
    local l = txt(row, label, TS, C.text)
    l.Size = UDim2.new(1, -U(48), 1, 0)
    l.Position = UDim2.fromOffset(U(7), 0)
    return l
end

local function addToggle(label, key, onChange)
    local row = newRow(label, U(28), true)
    rowLabel(row, label)
    local sw = Instance.new("Frame")
    sw.Size = UDim2.fromOffset(U(30), U(16))
    sw.Position = UDim2.new(1, -U(36), 0.5, -U(8))
    sw.Parent = row
    round(sw)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(U(12), U(12))
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = sw
    round(knob)
    local function refresh()
        sw.BackgroundColor3 = S[key] and C.acc or C.off
        knob.Position = S[key] and UDim2.new(1, -U(14), 0.5, -U(6)) or UDim2.new(0, U(2), 0.5, -U(6))
    end
    R[key] = refresh
    refresh()
    row.Activated:Connect(function()
        S[key] = not S[key]
        refresh()
        if onChange then onChange(S[key]) end
    end)
end

local function addCycle(label, values, key, fmt, onChange)
    local function idxOf()
        for i, v in ipairs(values) do if v == S[key] then return i end end
        return 1
    end

    if #values > 2 and type(values[1]) == "number" then
        local row = newRow(label, U(40), false)
        local l = txt(row, label, TS, C.text)
        l.Size = UDim2.new(0.6, 0, 0, U(18))
        l.Position = UDim2.fromOffset(U(7), U(3))
        local v = txt(row, "", TS, C.acc, Enum.TextXAlignment.Right)
        v.Font = Enum.Font.GothamBold
        v.Size = UDim2.new(0.4, -U(7), 0, U(18))
        v.Position = UDim2.new(0.6, 0, 0, U(3))

        local hit = Instance.new("TextButton")
        hit.Text = ""
        hit.BackgroundTransparency = 1
        hit.Size = UDim2.new(1, -U(18), 0, U(18))
        hit.Position = UDim2.fromOffset(U(9), U(20))
        hit.Parent = row
        local trk = Instance.new("Frame")
        trk.Size = UDim2.new(1, 0, 0, U(4))
        trk.Position = UDim2.new(0, 0, 0.5, -U(2))
        trk.BackgroundColor3 = C.off
        trk.BorderSizePixel = 0
        trk.Parent = hit
        round(trk)
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = C.acc
        fill.BorderSizePixel = 0
        fill.Parent = trk
        round(fill)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(U(10), U(10))
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Parent = trk
        round(knob)

        local function refresh()
            local t = (idxOf() - 1) / math.max(1, #values - 1)
            fill.Size = UDim2.new(t, 0, 1, 0)
            knob.Position = UDim2.new(t, -U(5), 0.5, -U(5))
            v.Text = fmt(S[key])
        end
        refresh()

        local mine = false
        local function setFromX(x)
            local t = math.clamp((x - hit.AbsolutePosition.X) / math.max(1, hit.AbsoluteSize.X), 0, 1)
            local nv = values[math.floor(t * (#values - 1) + 0.5) + 1]
            if nv ~= S[key] then
                S[key] = nv
                refresh()
                if onChange then onChange(nv) end
            end
        end
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                mine, sliding = true, true
                setFromX(i.Position.X)
                i.Changed:Connect(function()
                    if i.UserInputState == Enum.UserInputState.End then mine, sliding = false, false end
                end)
            end
        end)
        track(UIS.InputChanged:Connect(function(i)
            if mine and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
                setFromX(i.Position.X)
            end
        end))
    else
        local row = newRow(label, U(28), true)
        rowLabel(row, label)
        local box = txt(row, "", math.max(8, TS - 1), C.text, Enum.TextXAlignment.Center)
        box.BackgroundTransparency = 0
        box.BackgroundColor3 = C.btn
        box.Size = UDim2.fromOffset(U(64), U(20))
        box.Position = UDim2.new(1, -U(70), 0.5, -U(10))
        corner(box, 5)
        local idx = idxOf()
        local function refresh() box.Text = fmt(S[key]) .. " ▾" end
        refresh()
        row.Activated:Connect(function()
            idx = idx % #values + 1
            S[key] = values[idx]
            refresh()
            if onChange then onChange(S[key]) end
        end)
    end
end

local function addAction(label, fn)
    local row = newRow(label, U(28), true)
    row.Text = label
    row.TextColor3 = C.text
    row.Font = Enum.Font.GothamBold
    row.TextSize = TS
    row.BackgroundColor3 = C.btn
    row.Activated:Connect(fn)
    return row
end

local function addHold(label, key)
    local row = addAction(label, function() end)
    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then FC[key] = true end
    end)
    row.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then FC[key] = false end
    end)
end

local function release()
    local char = lp.Character
    local h = char and char:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand = false end
    local r = char and char:FindFirstChild("HumanoidRootPart")
    if r then r.CanCollide = true end
end

local function refreshQuick()
    quick.Text = S.rage and "RAGE ON" or "RAGE OFF"
    quick.BackgroundColor3 = S.rage and C.acc or C.off
end

local function setRage(on)
    S.rage = on
    if R.rage then R.rage() end
    refreshQuick()
    if not on then release() ST.attacking = false ST.lastSet = nil end
end

local function manualRage(on)
    ST.autoStarted = false
    setRage(on)
    if not on then
        S.auto = false
        if R.auto then R.auto() end
        say("停止")
    end
end
quick.Activated:Connect(function() manualRage(not S.rage) end)
refreshQuick()

local function teammate(plr)
    if lp.Team and plr.Team then return lp.Team == plr.Team end
    local a, b = lp:GetAttribute("Team"), plr:GetAttribute("Team")
    if a ~= nil and b ~= nil then return a == b end
    return false
end

local function closest()
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local best, bd
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if p ~= lp and h and h.Health > 0 and r and not (S.team and teammate(p)) then
            local d = (r.Position - root.Position).Magnitude
            if not bd or d < bd then best, bd = c, d end
        end
    end
    return best
end

showTab(1)

env.RL = {
    S = S, R = R, FC = FC, ST = ST, say = say, track = track, lp = lp,
    addToggle = addToggle, addCycle = addCycle, addAction = addAction, addHold = addHold,
    release = release, setRage = setRage, manualRage = manualRage, closest = closest,
    isDragging = function() return dragging or sliding end,
    save = {file = SAVE_FILE, keys = SAVE_KEYS, loaded = SAVE_LOADED},
}
end

------------------------------------------------------------
-- ② チーム判別
------------------------------------------------------------
do
local Players = game:GetService("Players")

local env = (getgenv and getgenv()) or _G
local RL = env.RL
if not RL then warn("パート1が実行されていません") return end

local S, lp, say = RL.S, RL.lp, RL.say
S.unk = S.unk or "狙わない"
S.prio = S.prio or "体力"

local ATTR = {"Team", "team", "TeamId", "TeamID", "TeamName", "TeamColor", "Side", "Squad", "Alliance"}

local function fromAttrs(inst)
    for _, k in ipairs(ATTR) do
        local v = inst:GetAttribute(k)
        if v ~= nil then return k .. "=" .. tostring(v) end
    end
end

local function fromValue(inst)
    if not inst then return end
    local v = inst:FindFirstChild("Team") or inst:FindFirstChild("TeamName")
    if v and v:IsA("ValueBase") and v.Value ~= nil then
        return "V=" .. tostring(v.Value)
    end
end

local function teamOf(p)
    if p.Team then return "Team:" .. p.Team.Name end
    if not p.Neutral then return "Color:" .. tostring(p.TeamColor) end
    local c = p.Character
    return fromAttrs(p) or (c and fromAttrs(c)) or fromValue(p) or fromValue(c)
end

local function isEnemy(p)
    local mine, theirs = teamOf(lp), teamOf(p)
    if mine == nil or theirs == nil then
        return S.unk == "敵扱い"
    end
    return mine ~= theirs
end

local lastT, lastR = 0, nil
local function closestEnemy()
    local now = tick()
    if now - lastT < 0.05 then return lastR end   -- 毎フレーム何度も呼ばれるので、少しだけ覚えておく
    lastT = now
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not root then lastR = nil return end
    local best, bhp, bd
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if p ~= lp and h and h.Health > 0 and r and (not S.team or isEnemy(p)) then
            local d = (r.Position - root.Position).Magnitude
            if S.prio == "体力" then
                -- 体力が一番少ない敵。同じなら近い方
                if not best or h.Health < bhp or (h.Health == bhp and d < bd) then
                    best, bhp, bd = c, h.Health, d
                end
            elseif not bd or d < bd then
                best, bhp, bd = c, h.Health, d
            end
        end
    end
    lastR = best
    return best
end

RL.closest = closestEnemy
RL.isEnemy = isEnemy

RL.addCycle("チーム不明時", {"狙わない", "敵扱い"}, "unk", function(v) return v end)
RL.addCycle("優先順位", {"体力", "近さ"}, "prio", function(v) return v end)
RL.addAction("チーム調査", function()
    local lines = {"自分: " .. tostring(teamOf(lp))}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local t = teamOf(p)
            local kind = (t == nil) and "不明" or (isEnemy(p) and "敵" or "味方")
            table.insert(lines, p.Name .. ": " .. tostring(t) .. " → " .. kind)
        end
    end
    local out = table.concat(lines, "\n")
    say(out)
    if setclipboard then pcall(setclipboard, out) end
end)
end

------------------------------------------------------------
-- ③ パート2: 本体(攻撃・視点・復帰・ロビー検知)
------------------------------------------------------------
do
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local env = (getgenv and getgenv()) or _G
local RL = env.RL
if not RL then warn("パート1が実行されていません") return end

local S, R, FC, ST, say, track, lp = RL.S, RL.R, RL.FC, RL.ST, RL.say, RL.track, RL.lp
local addToggle, addCycle, addAction, addHold = RL.addToggle, RL.addCycle, RL.addAction, RL.addHold
local release, setRage, manualRage, closest = RL.release, RL.setRage, RL.manualRage, RL.closest

local STOP_WAIT = 3

S.part = S.part or "胴体"
if S.predict == nil then S.predict = true end
S.depth = S.depth or 6
S.view = S.view or "飛行"

for _, n in ipairs({"FreeCamView", "RL_Fire", "RL_Restore", "RL_Fly", "RL_Save"}) do
    pcall(function() RunService:UnbindFromRenderStep(n) end)
end

local target
local function getTarget()
    if target and target.Parent then
        local h = target:FindFirstChildOfClass("Humanoid")
        local r = target:FindFirstChild("HumanoidRootPart")
        if h and h.Health > 0 and r then return target end
    end
    target = closest()
    return target
end

local function aimPoint(enemy)
    local part
    if S.part == "頭" then part = enemy:FindFirstChild("Head") end
    part = part or enemy:FindFirstChild("UpperTorso") or enemy:FindFirstChild("Torso")
        or enemy:FindFirstChild("HumanoidRootPart")
    local pos = part.Position
    if S.predict then
        local r = enemy:FindFirstChild("HumanoidRootPart")
        local ping = 0
        pcall(function() ping = lp:GetNetworkPing() end)
        if r then pos = pos + r.AssemblyLinearVelocity * (ping + 0.03) end
    end
    return pos
end

local function placeUnder(root, enemy, aim)
    local er = enemy.HumanoidRootPart
    root.CFrame = CFrame.lookAt(er.Position - Vector3.new(0, S.depth, 0), aim)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    ST.lastSet = root.Position
end

-- CD短縮
env.CD_ORIG3 = env.CD_ORIG3 or {}
local KEYS = {"ShootCooldown","AttackCooldown","HeavyAttackCooldown","BurstCooldown",
    "Cooldown","QuickShotCooldown","DashCooldown","ChargeReleaseCooldown"}

local function applyCD()
    local lib
    for _, m in ipairs(RS:GetDescendants()) do
        if m:IsA("ModuleScript") and m.Name == "ItemLibrary" then
            local ok, r = pcall(require, m)
            if ok and type(r) == "table" and type(r.Items) == "table" then lib = r break end
        end
    end
    if not lib then say("ItemLibraryなし") return end
    local n = 0
    for name, item in pairs(lib.Items) do
        if type(item) == "table" then
            for _, k in ipairs(KEYS) do
                local v = rawget(item, k)
                if type(v) == "number" then
                    env.CD_ORIG3[name] = env.CD_ORIG3[name] or {}
                    if env.CD_ORIG3[name][k] == nil and v > 0 and v < 60 then env.CD_ORIG3[name][k] = v end
                    local base = env.CD_ORIG3[name][k]
                    if base then
                        if setreadonly then pcall(setreadonly, item, false) end
                        if pcall(rawset, item, k, S.cd and base / S.div or base) then n = n + 1 end
                    end
                end
            end
        end
    end
    say("CD " .. (S.cd and "短縮" or "戻した") .. ": " .. n .. "件 1/" .. S.div)
end

-- 視点(飛行 / フリー)
local ghost, ghostRoot, ghostHum, gpos

local function getMoveVector()
    local ok, v = pcall(function()
        local pm = require(lp.PlayerScripts:WaitForChild("PlayerModule"))
        return pm:GetControls():GetMoveVector()
    end)
    if ok and typeof(v) == "Vector3" then return v end
    local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if h then
        local cf, d = workspace.CurrentCamera.CFrame, h.MoveDirection
        return Vector3.new(d:Dot(cf.RightVector), 0, -d:Dot(cf.LookVector))
    end
    return Vector3.zero
end

local function viewPos()
    if not S.fc then return nil end
    if S.view == "フリー" then return FC.pos end
    return gpos
end

local function defaultStart()
    if target and target.Parent then
        local r = target:FindFirstChild("HumanoidRootPart")
        if r then return r.Position + Vector3.new(0, 6, 0) end
    end
    return workspace.CurrentCamera.CFrame.Position
end

local function stopView()
    FC.cf = nil
    if ghost then ghost:Destroy() end
    ghost, ghostRoot, ghostHum, gpos = nil, nil, nil, nil
    local cam = workspace.CurrentCamera
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then cam.CameraSubject = hum end
    cam.CameraType = Enum.CameraType.Custom
end

local function failFC(msg)
    S.fc = false
    if R.fc then R.fc() end
    say(msg)
end

local function startFly(at)
    local char = lp.Character
    if not char then failFC("キャラがいません") return end
    char.Archivable = true
    local g = char:Clone()
    if not g then failFC("分身を作れませんでした") return end
    for _, d in ipairs(g:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Tool") then
            d:Destroy()
        elseif d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
        end
    end
    local gr = g:FindFirstChild("HumanoidRootPart")
    local gh = g:FindFirstChildOfClass("Humanoid")
    if not gr or not gh then g:Destroy() failFC("分身を作れませんでした") return end
    gh.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    g.Name = "RL_Ghost"
    gpos = at or defaultStart()
    gr.CFrame = CFrame.new(gpos)
    g.Parent = workspace
    ghost, ghostRoot, ghostHum = g, gr, gh
    local cam = workspace.CurrentCamera
    cam.CameraSubject = gh
    cam.CameraType = Enum.CameraType.Custom
end

local function startFree(at)
    local cam = workspace.CurrentCamera
    FC.pos = at or defaultStart()
    FC.pitch, FC.yaw = cam.CFrame:ToOrientation()
    cam.CameraType = Enum.CameraType.Scriptable
end

local function startView(at)
    if S.view == "フリー" then startFree(at) else startFly(at) end
end

RunService:BindToRenderStep("RL_Fly", Enum.RenderPriority.Camera.Value - 1, function(dt)
    if not S.fc or S.view ~= "飛行" or not ghost or not ghost.Parent then return end
    local cam = workspace.CurrentCamera
    if cam.CameraSubject ~= ghostHum then cam.CameraSubject = ghostHum end
    if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
    local cf = cam.CFrame
    local mv = getMoveVector()
    local move = cf.RightVector * mv.X + cf.LookVector * (-mv.Z)
    if FC.up then move += Vector3.new(0, 1, 0) end
    if FC.down then move -= Vector3.new(0, 1, 0) end
    gpos += move * S.speed * dt
    local flat = Vector3.new(move.X, 0, move.Z)
    local look = flat.Magnitude > 0.05 and flat.Unit or ghostRoot.CFrame.LookVector
    ghostRoot.CFrame = CFrame.lookAt(gpos, gpos + look)
end)

RunService:BindToRenderStep("FreeCamView", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not S.fc or S.view ~= "フリー" then return end
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    local rot = CFrame.fromOrientation(FC.pitch, FC.yaw, 0)
    local mv = getMoveVector()
    local move = rot.RightVector * mv.X + rot.LookVector * (-mv.Z)
    if FC.up then move += Vector3.new(0, 1, 0) end
    if FC.down then move -= Vector3.new(0, 1, 0) end
    FC.pos += move * S.speed * dt
    FC.cf = CFrame.new(FC.pos) * rot
    cam.CFrame = FC.cf
end)

RunService:BindToRenderStep("RL_Save", Enum.RenderPriority.Camera.Value + 2, function()
    if S.fc and S.view == "飛行" then FC.cf = workspace.CurrentCamera.CFrame end
end)

RunService:BindToRenderStep("RL_Fire", 1000, function()
    if not S.rage or S.knife then return end
    pcall(function()
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return end
        local enemy = getTarget()
        if not enemy then return end
        local aim = aimPoint(enemy)
        if S.tp and not S.knife then placeUnder(root, enemy, aim) end
        local head = char:FindFirstChild("Head")
        local origin = head and head.Position or root.Position
        workspace.CurrentCamera.CFrame = CFrame.lookAt(origin, aim)
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and not (S.avoidReflect and RL.isDeflecting and RL.isDeflecting(enemy)) then
            for _ = 1, (S.fireN or 2) do tool:Activate() end
        end
    end)
end)

RunService:BindToRenderStep("RL_Restore", 2000, function()
    if S.fc and FC.cf then workspace.CurrentCamera.CFrame = FC.cf end
end)

track(UIS.InputChanged:Connect(function(i, processed)
    if not S.fc or S.view ~= "フリー" or RL.isDragging() then return end
    local half = workspace.CurrentCamera.ViewportSize.X / 2
    if i.UserInputType == Enum.UserInputType.Touch and not processed and i.Position.X > half then
        FC.yaw -= i.Delta.X * 0.006
        FC.pitch = math.clamp(FC.pitch - i.Delta.Y * 0.006, -1.5, 1.5)
    elseif i.UserInputType == Enum.UserInputType.MouseMovement
        and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        FC.yaw -= i.Delta.X * 0.004
        FC.pitch = math.clamp(FC.pitch - i.Delta.Y * 0.004, -1.5, 1.5)
    end
end))

-- 戻る位置(奈落対策)
local ignoreUntil = 0
local enemySince, tpAt, noEnemy, lastPos, lastSafe

local function safePoint()
    local p = viewPos()
    if p then
        local list = {lp.Character}
        if ghost then table.insert(list, ghost) end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = list
        local hit = workspace:Raycast(p + Vector3.new(0, 2, 0), Vector3.new(0, -400, 0), params)
        if hit then
            if hit.Distance <= 14 then return p end
            return hit.Position + Vector3.new(0, 4, 0)
        end
    end
    if lastSafe then return lastSafe.Position + Vector3.new(0, 3, 0) end
end

local function doReturn(root)
    release()
    local pt = safePoint()
    if pt then
        root.CFrame = CFrame.new(pt)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        lastPos = root.Position
        say(viewPos() and "撃破 → 視点の位置へ戻った" or "撃破 → 初期地点へ戻った")
    end
    ST.attacking, ST.lastSet = false, nil
end

local function endMatch(msg)
    ST.autoStarted = false
    setRage(false)
    target = nil
    ignoreUntil = tick() + 10
    tpAt, enemySince, noEnemy = nil, nil, nil
    say(msg)
end

-- 開始の合図を調べる記録
local logs, watching = {}, false
local function addLog(t)
    if not watching then return end
    table.insert(logs, 1, string.format("%d %s", tick() % 1000, t))
    if #logs > 30 then table.remove(logs) end
end
local function watch(inst, name)
    pcall(function()
        track(inst.AttributeChanged:Connect(function(a)
            addLog(name .. "." .. a .. "=" .. tostring(inst:GetAttribute(a)))
        end))
    end)
end
watch(lp, "player") watch(workspace, "workspace") watch(RS, "RS")
track(lp:GetPropertyChangedSignal("Team"):Connect(function() addLog("Team=" .. tostring(lp.Team)) end))
local cnt = 0
for _, d in ipairs(RS:GetDescendants()) do
    if d:IsA("ValueBase") and cnt < 200 then
        cnt += 1
        track(d.Changed:Connect(function(v) addLog(d.Name .. "=" .. tostring(v)) end))
    end
end

-- メニュー
addToggle("RAGE", "rage", function(on) manualRage(on) end)
addToggle("自動開始", "auto")
addCycle("開始の検知", {"TP検知", "敵出現"}, "mode", function(v) return v end)
addCycle("開始待ち(秒)", {0, 1, 2, 3, 5, 8}, "delay", function(v) return v .. "秒" end)
addCycle("狙う部位", {"胴体", "頭"}, "part", function(v) return v end)
addToggle("先読み", "predict")
addToggle("足元TP", "tp", function(on) if not on then release() end end)
addCycle("TPの深さ", {2, 4, 6, 10}, "depth", function(v) return v .. "st" end)
addToggle("チームチェック", "team")
addToggle("CD短縮", "cd", function()
    local ok, err = pcall(applyCD)
    if not ok then say("エラー: " .. tostring(err)) end
end)
addCycle("CD倍率", {2, 4, 10, 20}, "div", function(v) return "1/" .. v end, function()
    if S.cd then pcall(applyCD) end
end)
addToggle("視点操作", "fc", function(on) if on then startView() else stopView() end end)
addCycle("視点モード", {"飛行", "フリー"}, "view", function(v) return v end, function()
    if S.fc then
        local p = viewPos()
        stopView()
        startView(p)
    end
end)
addHold("▲ 上昇(押しっぱなし)", "up")
addHold("▼ 下降(押しっぱなし)", "down")
addCycle("視点の速さ", {30, 60, 120, 250}, "speed", function(v) return tostring(v) end)
addAction("開始シグナル調査", function()
    if not watching then
        watching, logs = true, {}
        say("記録中… 試合が始まった直後に、もう一度押してください")
    else
        watching = false
        local out = #logs > 0 and table.concat(logs, "\n") or "変化なし"
        say(out)
        if setclipboard then pcall(setclipboard, out) end
    end
end)

-- メインループ
local function startAuto(why)
    ST.autoStarted = true
    enemySince, tpAt, noEnemy = nil, nil, nil
    setRage(true)
    say("試合開始 → RAGE発動(" .. why .. ")")
end

track(RunService.Heartbeat:Connect(function()
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        enemySince, lastPos, ST.lastSet = nil, nil, nil
        if S.fc then S.fc = false if R.fc then R.fc() end stopView() end
        if ST.autoStarted and S.rage then ST.autoStarted = false setRage(false) end
        ST.attacking, target = false, nil
        return
    end

    if S.rage and ST.attacking and ST.lastSet and (root.Position - ST.lastSet).Magnitude > 50 then
        endMatch("試合終了(ロビーへ移動) → RAGE無効")
        lastPos = root.Position
        return
    end
    if S.rage and not ST.attacking and not ST.lastSet and lastPos
        and (root.Position - lastPos).Magnitude > 80 then
        endMatch("試合終了(ロビーへ移動) → RAGE無効")
        lastPos = root.Position
        return
    end

    if not ST.attacking and hum.FloorMaterial ~= Enum.Material.Air then lastSafe = root.CFrame end
    if lastSafe and not ST.attacking and not ST.lastSet and root.Position.Y < lastSafe.Position.Y - 150 then
        root.CFrame = lastSafe + Vector3.new(0, 5, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        release()
        lastPos = root.Position
        say("奈落から復帰")
    end

    if not S.rage and tick() > ignoreUntil and lastPos and (root.Position - lastPos).Magnitude > 80 then
        tpAt = tick()
    end
    lastPos = root.Position

    if S.auto and not S.rage and tick() > ignoreUntil then
        local e = closest()
        if S.mode == "敵出現" then
            if e then
                enemySince = enemySince or tick()
                if tick() - enemySince >= S.delay then startAuto("敵出現") end
            else
                enemySince = nil
            end
        else
            if tpAt and e and tick() - tpAt >= S.delay then startAuto("TP検知") end
            if tpAt and tick() - tpAt > 60 then tpAt = nil end
        end
    end

    if not S.rage then ST.attacking, target = false, nil return end
    local ok, err = pcall(function()
        local enemy = getTarget()
        if not enemy then
            if ST.attacking then doReturn(root) end
            noEnemy = noEnemy or tick()
            if ST.autoStarted and tick() - noEnemy > STOP_WAIT then
                ST.autoStarted = false
                setRage(false)
                say("敵がいない → 待機")
            end
            return
        end
        noEnemy = nil
        ST.attacking = true

        if S.tp and not S.knife then
            hum.PlatformStand = true
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
            placeUnder(root, enemy, aimPoint(enemy))
        end

        if S.animFast then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:AdjustSpeed(5) end
            end
        end
        say("攻撃中: " .. enemy.Name .. " (" .. S.part .. ")" .. (S.fc and " [" .. S.view .. "]" or ""))
    end)
    if not ok then say("エラー: " .. tostring(err)) end
end))
end

------------------------------------------------------------
-- ④ 定期スポーン帰還
------------------------------------------------------------
do
local RunService = game:GetService("RunService")

local env = (getgenv and getgenv()) or _G
local RL = env.RL
if not RL then warn("パート1が実行されていません") return end

local S, ST, lp, say, track, release = RL.S, RL.ST, RL.lp, RL.say, RL.track, RL.release

if S.home == nil then S.home = true end
S.homeEvery = S.homeEvery or 3
local STAY = 0.3   -- 着地を待つ最大秒数(地面に着いたらすぐ戻る)

local home
local token = tick()
env.RL_HOME = token

local function spawnFallback()
    local sp = lp.RespawnLocation
    if sp and sp.Parent then return sp.Position + Vector3.new(0, 4, 0) end
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("SpawnLocation") then return d.Position + Vector3.new(0, 4, 0) end
    end
end

track(RunService.Heartbeat:Connect(function()
    if S.rage or ST.attacking then return end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root and hum and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        home = root.Position + Vector3.new(0, 3, 0)
    end
end))

task.spawn(function()
    local last = tick()
    while env.RL_HOME == token do
        task.wait(0.1)
        if S.home and S.rage and ST.attacking and S.tp and not S.knife and tick() - last >= S.homeEvery then
            last = tick()
            pcall(function()
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not root then return end
                local pt = home or spawnFallback()
                if not pt then return end

                S.tp = false
                ST.lastSet = nil
                release()
                root.CFrame = CFrame.new(pt)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                say("スポーン地点へ帰還")

                local t0 = tick()
                repeat
                    task.wait()
                until (hum and hum.FloorMaterial ~= Enum.Material.Air) or tick() - t0 > STAY
            end)
            S.tp = true
        end
    end
end)

RL.getHome = function() return home or spawnFallback() end
RL.addToggle("定期スポーン帰還", "home")
RL.addCycle("帰還間隔", {2, 3, 5, 10}, "homeEvery", function(v) return v .. "秒" end)
RL.say("読み込み中…")
end

------------------------------------------------------------
-- ⑤ ESP(体力・武器) / エイムボット / サイレントエイム / 反射回避 / 足の速さ / 設定保存
------------------------------------------------------------
do
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local env = (getgenv and getgenv()) or _G
local RL = env.RL
if not RL then warn("先にメイン部分を実行してください") return end

local S, R, lp, say, track = RL.S, RL.R, RL.lp, RL.say, RL.track
local pg = lp:WaitForChild("PlayerGui")

local DEF = {esp = true, hpbar = true, nameDist = true, espWeapon = true, fovCircle = true,
    aim = false, aimSpeed = 0.2, aimFov = 200, aimWall = false,
    sa = false, saChance = 100, saScreenRay = false, saHold = true,
    aimPart = "胴体", saPart = "胴体", bodyFollow = true,
    avoidReflect = true, walk = false, walkSpeed = 50,
    reflectMode = "検知", infJump = false, knife = false, knifeDist = 4, knifeStay = 0.05, knifeWait = 3,
    animFast = false, fireN = 2, lagAnim = true, lagFx = true, lagBullet = true, lagHit = true, lagSelf = false}
for k, v in pairs(DEF) do if S[k] == nil then S[k] = v end end

pcall(function() RunService:UnbindFromRenderStep("RL_Aim") end)
local oldg = pg:FindFirstChild("RL_ESP")
if oldg then oldg:Destroy() end

local egui = Instance.new("ScreenGui")
egui.Name = "RL_ESP"
egui.ResetOnSpawn = false
egui.IgnoreGuiInset = true
egui.DisplayOrder = 900
egui.Parent = pg

------------------------------------------------------------ 共通
local function enemy(p)
    if not S.team then return true end
    if RL.isEnemy then return RL.isEnemy(p) end
    return not (lp.Team and p.Team and lp.Team == p.Team)
end

local function alive(p)
    local c = p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if h and h.Health > 0 and r then return c, h, r end
end

local function aimPart(c, name)
    if name == "頭" then
        local h = c:FindFirstChild("Head")
        if h then return h end
    end
    return c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") or c:FindFirstChild("HumanoidRootPart")
end

------------------------------------------------------------ 武器の判別 / 刀の反射(デフレクト)の検知
local itemSet
local function loadItems()
    if itemSet then return itemSet end
    itemSet = {}
    pcall(function()
        for _, m in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if m:IsA("ModuleScript") and m.Name == "ItemLibrary" then
                local lib = require(m)
                if type(lib) == "table" and type(lib.Items) == "table" then
                    for name in pairs(lib.Items) do itemSet[tostring(name)] = true end
                end
            end
        end
    end)
    return itemSet
end

-- 敵が持っている武器の名前(Tool → キャラの子 → 属性 → 子孫 の順に探す)
local function weaponName(p, c)
    local tool = c:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    local items = loadItems()
    for _, d in ipairs(c:GetChildren()) do
        if items[d.Name] then return d.Name end
    end
    for _, inst in ipairs({c, p}) do
        for k, v in pairs(inst:GetAttributes()) do
            if type(v) == "string" then
                local kl = k:lower()
                if items[v] or kl:find("weapon", 1, true) or kl:find("equipped", 1, true)
                    or kl:find("item", 1, true) then
                    return v
                end
            end
        end
    end
    for _, d in ipairs(c:GetDescendants()) do
        if items[d.Name] and (d:IsA("Model") or d:IsA("BasePart") or d:IsA("Folder")) then
            return d.Name
        end
    end
    return "-"
end

-- 0.25秒だけ結果を覚えておく(毎フレーム調べると重いため)
local wcache = setmetatable({}, {__mode = "k"})
local function weaponOf(p, c)
    local e = wcache[c]
    local now = tick()
    if e and now - e.t < 0.25 then return e.n end
    local n = weaponName(p, c)
    wcache[c] = {n = n, t = now}
    return n
end

local WORDS = {"deflect", "parry", "reflect", "block", "guard", "counter"}
local function hasWord(n)
    n = tostring(n):lower()
    for _, w in ipairs(WORDS) do
        if n:find(w, 1, true) then return true end
    end
    return false
end
local function truthy(v) return v == true or (type(v) == "number" and v > 0) end

-- 刀を持っていて、反射中らしい印(属性・値・子の名前・アニメ名)があれば true
local function isDeflecting(c, p)
    p = p or Players:GetPlayerFromCharacter(c)
    if not p then return false end
    if not weaponOf(p, c):lower():find("katana", 1, true) then return false end
    if S.reflectMode == "刀持ち全員" then return true end

    local tool = c:FindFirstChildOfClass("Tool")
    local list = tool and {c, p, tool} or {c, p}
    for _, inst in ipairs(list) do
        for k, v in pairs(inst:GetAttributes()) do
            if (hasWord(k) and truthy(v)) or (type(v) == "string" and hasWord(v)) then return true end
        end
    end
    for _, d in ipairs(c:GetChildren()) do
        if hasWord(d.Name) and (not d:IsA("ValueBase") or truthy(d.Value)) then return true end
    end
    local hum = c:FindFirstChildOfClass("Humanoid")
    local an = hum and hum:FindFirstChildOfClass("Animator")
    if an then
        for _, t in ipairs(an:GetPlayingAnimationTracks()) do
            local a = t.Animation
            if hasWord(t.Name) or (a and hasWord(a.Name)) then return true end
        end
    end
    return false
end

-- RAGE側(撃つ処理)からも使えるように公開
RL.isDeflecting = function(c, p) return isDeflecting(c, p) end

local deflecting = {}   -- [キャラ] = HumanoidRootPart (反射中の敵)

------------------------------------------------------------ ESP + 体力 + 武器
local ents = {}

local function drop(p)
    local e = ents[p]
    if e then
        pcall(function() e.hl:Destroy() end)
        pcall(function() e.bb:Destroy() end)
        ents[p] = nil
    end
end

local function mkLabel(parent, y, size, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 0, 13)
    l.Position = UDim2.fromOffset(0, y)
    l.Font = font
    l.TextSize = size
    l.TextColor3 = Color3.new(1, 1, 1)
    l.TextStrokeTransparency = 0.4
    l.Parent = parent
    return l
end

local function make(p, c, head)
    local hl = Instance.new("Highlight")
    hl.Adornee = c
    hl.FillTransparency = 0.55
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = egui

    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(120, 52)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Parent = egui

    local nameL = mkLabel(bb, 0, 12, Enum.Font.GothamBold)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.fromOffset(0, 15)
    bar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    bar.BorderSizePixel = 0
    bar.Parent = bb

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local hpL = mkLabel(bb, 22, 11, Enum.Font.Gotham)
    local wL = mkLabel(bb, 36, 11, Enum.Font.GothamBold)

    ents[p] = {char = c, hl = hl, bb = bb, nameL = nameL, bar = bar, fill = fill, hpL = hpL, wL = wL}
    return ents[p]
end

local lastSlow = 0
track(RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    local now = tick()
    local slow = now - lastSlow > 0.1
    if slow then lastSlow = now end
    if not (S.esp or S.hpbar or S.nameDist or S.espWeapon) then
        for p in pairs(ents) do drop(p) end
        return
    end
    for p in pairs(ents) do
        if not p.Parent then drop(p) end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local c, h, r = nil, nil, nil
            if enemy(p) then c, h, r = alive(p) end
            if not c then
                drop(p)
            else
                local head = c:FindFirstChild("Head") or r
                local e = ents[p]
                if e and e.char ~= c then drop(p) e = nil end
                if not e then e = make(p, c, head) end

                local ratio = math.clamp(h.Health / math.max(1, h.MaxHealth), 0, 1)
                local col = Color3.fromHSV(ratio * 0.33, 0.9, 0.95)

                e.hl.Enabled = S.esp
                e.hl.FillColor = col

                e.bb.Enabled = S.hpbar or S.nameDist or S.espWeapon
                e.nameL.Visible = S.nameDist
                e.bar.Visible = S.hpbar
                e.hpL.Visible = S.hpbar
                e.wL.Visible = S.espWeapon
                if S.nameDist and slow then
                    local dist = math.floor((head.Position - cam.CFrame.Position).Magnitude)
                    e.nameL.Text = string.format("%s  [%dm]", p.DisplayName, dist)
                end
                if S.hpbar then
                    e.fill.Size = UDim2.new(ratio, 0, 1, 0)
                    e.fill.BackgroundColor3 = col
                    e.hpL.Text = math.floor(h.Health) .. " / " .. math.floor(h.MaxHealth)
                end
                if S.espWeapon and slow then
                    local w = weaponOf(p, c)
                    if S.avoidReflect and isDeflecting(c, p) then
                        e.wL.Text = w .. "  ⚔反射中"
                        e.wL.TextColor3 = Color3.fromRGB(255, 90, 90)
                    else
                        e.wL.Text = w
                        e.wL.TextColor3 = Color3.fromRGB(255, 225, 120)
                    end
                end
            end
        end
    end
end))

------------------------------------------------------------ エイム(対象の選び方)
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude

local function visible(cam, part, c)
    rp.FilterDescendantsInstances = {lp.Character, c}
    local o = cam.CFrame.Position
    return workspace:Raycast(o, part.Position - o, rp) == nil
end

-- FOVの円の中の敵から選ぶ(反射中の敵は除く)。優先順位は「体力が少ない→近い」か「画面の中心に近い」
local function pick(cam, name)
    local vs = cam.ViewportSize
    local center = Vector2.new(vs.X / 2, vs.Y / 2)
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local best, b1, b2
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and enemy(p) then
            local c, h, r = alive(p)
            if c and not deflecting[c] then
                local part = aimPart(c, name)
                if part then
                    local sp, on = cam:WorldToViewportPoint(part.Position)
                    if on then
                        local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if sd <= S.aimFov and (not S.aimWall or visible(cam, part, c)) then
                            local wd = myRoot and (r.Position - myRoot.Position).Magnitude or sd
                            local s1, s2
                            if S.prio == "体力" then s1, s2 = h.Health, wd else s1, s2 = sd, 0 end
                            if not best or s1 < b1 or (s1 == b1 and s2 < b2) then
                                best, b1, b2 = part, s1, s2
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- FOVの円
local circle = Instance.new("Frame")
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Parent = egui
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(1, 0)
cc.Parent = circle
local cs = Instance.new("UIStroke")
cs.Color = Color3.new(1, 1, 1)
cs.Thickness = 1
cs.Transparency = 0.4
cs.Parent = circle

local rotOff = false
local pmod

RunService:BindToRenderStep("RL_Aim", Enum.RenderPriority.Camera.Value + 3, function()
    local cam = workspace.CurrentCamera
    local active = not S.rage and not S.fc

    -- 反射中の敵を調べる
    deflecting = {}
    local avoid = {}
    if S.avoidReflect and (S.aim or S.sa) and active then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and enemy(p) then
                local c, _, r = alive(p)
                if c and isDeflecting(c, p) then
                    deflecting[c] = r
                    table.insert(avoid, r.Position)
                end
            end
        end
    end

    local aimT, saT
    if active then
        if S.aim then aimT = pick(cam, S.aimPart) end
        if S.sa then
            saT = (aimT and S.saPart == S.aimPart) and aimT or pick(cam, S.saPart)
        end
    end

    -- サイレントエイム用の情報(フックの中では重い処理をしないため、ここで用意)
    if not pmod or not pmod.Parent then
        local ps = lp:FindFirstChild("PlayerScripts")
        pmod = ps and ps:FindFirstChild("PlayerModule")
    end
    if S.sa and active and (saT or #avoid > 0) then
        env.RL_SA = {pos = saT and saT.Position, cam = cam.CFrame.Position, camObj = cam,
            avoid = avoid, pm = pmod}
    else
        env.RL_SA = nil
    end

    -- エイムボットの狙う位置(反射中の敵が照準の近くにいたら、そこから離れる方向へ)
    local aimPos = aimT and aimT.Position
    if S.aim and active and next(deflecting) then
        local vs = cam.ViewportSize
        local center = Vector2.new(vs.X / 2, vs.Y / 2)
        for _, r in pairs(deflecting) do
            local sp, on = cam:WorldToViewportPoint(r.Position)
            if on and (Vector2.new(sp.X, sp.Y) - center).Magnitude < 150 then
                local side = sp.X >= center.X and -1 or 1
                aimPos = r.Position + cam.CFrame.RightVector * side * 15
                break
            end
        end
    end

    -- エイムボット(視点と体を少しずつ向ける)
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if aimPos then
        local cf = cam.CFrame
        cam.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, aimPos), S.aimSpeed)
        if S.bodyFollow and root and hum then
            local flat = Vector3.new(aimPos.X, root.Position.Y, aimPos.Z)
            if (flat - root.Position).Magnitude > 0.5 then
                hum.AutoRotate = false
                rotOff = true
                root.CFrame = CFrame.lookAt(root.Position, flat)
            end
        elseif rotOff and hum then
            hum.AutoRotate = true
            rotOff = false
        end
    elseif rotOff and hum then
        hum.AutoRotate = true
        rotOff = false
    end

    circle.Visible = S.fovCircle and (S.aim or S.sa)
    circle.Size = UDim2.fromOffset(S.aimFov * 2, S.aimFov * 2)
end)

------------------------------------------------------------ サイレントエイム(弾の向きだけ変える)
local saOk = false
local HAS_CS = getcallingscript ~= nil

-- 撃っている間だけ書き換える(画面を押している間 + 直後0.2秒)
local UIS = game:GetService("UserInputService")
local held, lastUp = 0, 0
local function isFireInput(i)
    return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1
end
track(UIS.InputBegan:Connect(function(i) if isFireInput(i) then held += 1 end end))
track(UIS.InputEnded:Connect(function(i)
    if isFireInput(i) then held = math.max(0, held - 1) lastUp = tick() end
end))
local function firing() return held > 0 or tick() - lastUp < 0.2 end

-- カメラ・視点まわりの名前のスクリプトからの呼び出しは書き換えない
local BAD = {"camera", "viewmodel", "view", "cam", "neck", "look", "movement"}
local function badName(n)
    n = tostring(n):lower()
    for _, w in ipairs(BAD) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

-- 呼び出し元の記録(SA調査用)
local dbgOn, dbg = false, {}

-- 呼び出し元がカメラ用のスクリプト(PlayerModule)なら true(視界が乱れるのを防ぐ)
local function fromCore(callScript, pm)
    if callScript == nil then return true end
    local x, n = callScript, 0
    while x and n < 12 do
        if x == pm or badName(x.Name) then return true end
        x = x.Parent
        n += 1
    end
    return false
end

-- 弾の向きを決める(redirect=敵へ向ける / avoid=反射中の敵からそらす)
local function steer(o, dir, sa, redirect)
    local d = dir
    if redirect then
        local to = sa.pos - o
        d = to.Unit * math.max(dir.Magnitude, to.Magnitude + 5)
    end
    local len = d.Magnitude
    local u = d.Unit
    for _, ap in ipairs(sa.avoid) do
        local v = ap - o
        local t = math.clamp(v:Dot(u), 0, len)
        if v.Magnitude > 3 and (ap - (o + u * t)).Magnitude < 8 then
            local perp = Vector3.new(-u.Z, 0, u.X)
            perp = perp.Magnitude > 0.01 and perp.Unit or Vector3.new(1, 0, 0)
            local side = perp:Dot(v) >= 0 and -1 or 1
            u = (u + perp * side * 0.7).Unit
            d = u * len
        end
    end
    return d
end

env.RL_SA_FN = function(self, m, callScript, ...)
    if dbgOn and (m == "Raycast" or m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList"
        or m == "FindPartOnRayWithWhitelist" or m == "ViewportPointToRay" or m == "ScreenPointToRay") then
        local key = callScript or "?"
        local t = dbg[key]
        if not t then t = {} dbg[key] = t end
        t[m] = (t[m] or 0) + 1
    end
    local sa = env.RL_SA
    if not sa or not S.sa then return end
    if S.saHold and not firing() then return end
    if HAS_CS and fromCore(callScript, sa.pm) then return end
    local redirect = sa.pos ~= nil and math.random(100) <= S.saChance
    if not redirect and #sa.avoid == 0 then return end

    if self == workspace then
        if m == "Raycast" then
            local o, d = ...
            if typeof(o) == "Vector3" and typeof(d) == "Vector3" and d.Magnitude >= 30
                and (o - sa.cam).Magnitude < 25 and (HAS_CS or d.Magnitude >= 100) then
                local args = table.pack(...)
                args[2] = steer(o, d, sa, redirect)
                return "args", args
            end
        elseif m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList" or m == "FindPartOnRayWithWhitelist" then
            local ray = ...
            if typeof(ray) == "Ray" and ray.Direction.Magnitude >= 30
                and (ray.Origin - sa.cam).Magnitude < 25 and (HAS_CS or ray.Direction.Magnitude >= 100) then
                local args = table.pack(...)
                args[1] = Ray.new(ray.Origin, steer(ray.Origin, ray.Direction, sa, redirect))
                return "args", args
            end
        end
    elseif S.saScreenRay and HAS_CS and redirect and self == sa.camObj
        and (m == "ScreenPointToRay" or m == "ViewportPointToRay") then
        return "ret", Ray.new(sa.cam, steer(sa.cam, sa.pos - sa.cam, sa, true).Unit)
    end
end

local RAYM = {Raycast = true, FindPartOnRay = true, FindPartOnRayWithIgnoreList = true,
    FindPartOnRayWithWhitelist = true, ViewportPointToRay = true, ScreenPointToRay = true}

pcall(function()
    if not (hookmetamethod and getnamecallmethod and newcclosure and checkcaller) then return end
    if not env.RL_SA_HOOKED then
        env.RL_SA_HOOKED = true
        local old
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local m = getnamecallmethod()
            -- 高速パス: レイ関係のメソッドで、サイレントエイム/調査が有効なときだけ処理する
            -- (ゲームの全ての呼び出しを通るので、ここが重いとラグの原因になる)
            if RAYM[m] and (env.RL_SA or env.RL_SA_DBG) then
                local fn = env.RL_SA_FN
                if fn and not checkcaller() then
                    local callScript
                    if getcallingscript then
                        local okc, cs2 = pcall(getcallingscript)
                        if okc then callScript = cs2 end
                    end
                    local ok, kind, payload = pcall(fn, self, m, callScript, ...)
                    if setnamecallmethod then setnamecallmethod(m) end
                    if ok and kind == "args" then
                        return old(self, table.unpack(payload, 1, payload.n))
                    elseif ok and kind == "ret" then
                        return payload
                    end
                end
            end
            return old(self, ...)
        end))
    end
    saOk = true
end)

------------------------------------------------------------ 足の速さ(ゲームに戻されても追従する)
local ST = RL.ST
local origWS, lastHum
local function applyWalk()
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum then return end
    if hum ~= lastHum then lastHum, origWS = hum, nil end
    if S.walk then
        if not origWS then origWS = hum.WalkSpeed end
        if hum.WalkSpeed ~= S.walkSpeed then hum.WalkSpeed = S.walkSpeed end
        -- ゲームがWalkSpeedを上書きしても、横方向の速度を直接そろえる(ダブルジャンプ中も維持)
        local md = hum.MoveDirection
        if root and md.Magnitude > 0.1 and not hum.PlatformStand and not ST.attacking then
            local v = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(md.X * S.walkSpeed, v.Y, md.Z * S.walkSpeed)
        end
    elseif origWS then
        hum.WalkSpeed = origWS
        origWS = nil
    end
end
-- 物理計算の直前(Stepped)と直後(Heartbeat)の両方で適用する
track(RunService.Stepped:Connect(applyWalk))
track(RunService.Heartbeat:Connect(applyWalk))

------------------------------------------------------------ 無限ジャンプ
local lastJ = 0
local function doJump()
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 or hum.PlatformStand then return end
    lastJ = tick()
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local v = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(hum.JumpPower, 50), v.Z)
end
track(UIS.JumpRequest:Connect(function()
    if S.infJump and tick() - lastJ > 0.12 then doJump() end
end))
-- ジャンプボタンを押しっぱなしのときも、空中で繰り返す
track(RunService.Heartbeat:Connect(function()
    if not S.infJump or ST.attacking then return end
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Jump and hum.FloorMaterial == Enum.Material.Air and tick() - lastJ > 0.4 then
        doJump()
    end
end))

------------------------------------------------------------ ナイフモード(背後へ一瞬テレポート → 初期地点で待機)
pcall(function() RunService:UnbindFromRenderStep("RL_Knife") end)
local K = {state = "wait", t = tick(), enemy = nil, origin = nil}

local function findKnife()
    local char = lp.Character
    if not char then return end
    local cur = char:FindFirstChildOfClass("Tool")
    if cur and cur.Name:lower():find("knife", 1, true) then return cur, true end
    local bp = lp:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("knife", 1, true) then return t, false end
        end
    end
end

local function goHome(root)
    local home = (RL.getHome and RL.getHome()) or K.origin
    if home then
        root.CFrame = CFrame.new(home)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

track(RunService.Heartbeat:Connect(function()
    if not (S.rage and S.knife) then
        K.state, K.t, K.enemy = "wait", tick(), nil
        return
    end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    -- ナイフを持っていなければ持つ
    local kn, equipped = findKnife()
    if kn and not equipped then pcall(function() hum:EquipTool(kn) end) end

    if K.state == "wait" then
        if tick() - K.t >= S.knifeWait then
            local e = RL.closest()
            local er = e and e:FindFirstChild("HumanoidRootPart")
            if er and not (S.avoidReflect and isDeflecting(e)) then
                K.origin = root.Position
                K.state, K.t, K.enemy = "strike", tick(), e
            end
        end
    else
        local e = K.enemy
        local er = e and e:FindFirstChild("HumanoidRootPart")
        local eh = e and e:FindFirstChildOfClass("Humanoid")
        if not er or not eh or eh.Health <= 0 or tick() - K.t > S.knifeStay then
            goHome(root)
            K.state, K.t, K.enemy = "wait", tick(), nil
        else
            -- 敵の背後(向いている方向の反対側)。ナイフが背中に届く距離
            local pos = er.Position - er.CFrame.LookVector * S.knifeDist
            root.CFrame = CFrame.lookAt(pos, Vector3.new(er.Position.X, pos.Y, er.Position.Z))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end
end))

-- 背後にいる間に、敵の方を向いてナイフを振る
RunService:BindToRenderStep("RL_Knife", 1001, function()
    if not (S.rage and S.knife and K.state == "strike" and K.enemy) then return end
    pcall(function()
        local char = lp.Character
        local er = K.enemy:FindFirstChild("HumanoidRootPart")
        if not char or not er then return end
        local head = char:FindFirstChild("Head")
        workspace.CurrentCamera.CFrame = CFrame.lookAt(head and head.Position or er.Position, er.Position)
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() tool:Activate() end
    end)
end)

------------------------------------------------------------ ラグ対策(エフェクト・弾・ヒット演出・他人のアニメ)
local FX_CLASS = {ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true, Sparkles = true}
local BULLET_WORDS = {"bullet", "projectile", "tracer", "arrow", "casing", "pellet", "slug"}
local HIT_WORDS = {"headshot", "hitmarker", "hiteffect", "hitfx", "hitspark", "impact", "crit", "blood", "splat", "damage"}
local GUI_WORDS = {"hitmarker", "headshot", "crit", "damage"}

local function nameHas(n, words)
    n = tostring(n):lower()
    if n:find("hitbox", 1, true) then return false end
    for _, w in ipairs(words) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

local function inCharacter(inst)
    local m = inst:FindFirstAncestorOfClass("Model")
    return m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil
end

-- 削除はせず無効化する(ゲームのスクリプトが:Emit()などを呼んでもエラーにならないように)
local function killFx(inst)
    pcall(function()
        inst.Enabled = false
        if inst:IsA("ParticleEmitter") then
            inst.Rate = 0
            inst.Transparency = NumberSequence.new(1)
            inst.Size = NumberSequence.new(0)
        end
    end)
end

local function handle(inst)
    local cls = inst.ClassName
    local pn = inst.Parent and inst.Parent.Name or ""
    if FX_CLASS[cls] then
        if S.lagFx
            or (S.lagBullet and nameHas(pn, BULLET_WORDS))
            or (S.lagHit and (nameHas(inst.Name, HIT_WORDS) or nameHas(pn, HIT_WORDS))) then
            killFx(inst)
        end
        return
    end
    if inst:IsA("BasePart") then
        if inCharacter(inst) then return end
        if (S.lagBullet and (nameHas(inst.Name, BULLET_WORDS) or nameHas(pn, BULLET_WORDS)))
            or (S.lagHit and (nameHas(inst.Name, HIT_WORDS) or nameHas(pn, HIT_WORDS))) then
            inst.Transparency = 1
        end
    elseif (cls == "BillboardGui" or cls == "SurfaceGui") and S.lagHit and nameHas(inst.Name, HIT_WORDS) then
        inst.Enabled = false
    end
end

local function anyLag() return S.lagFx or S.lagBullet or S.lagHit end

track(workspace.DescendantAdded:Connect(function(inst)
    if anyLag() then pcall(handle, inst) end
end))

-- すでにあるものも処理する(少しずつ進めてカクつかせない)
local function sweep()
    task.spawn(function()
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            pcall(handle, d)
            n += 1
            if n % 400 == 0 then task.wait() end
        end
    end)
end
if anyLag() then sweep() end

-- ヒットマーカー・ダメージ表示などの画面UI
track(pg.DescendantAdded:Connect(function(inst)
    if not S.lagHit or not inst:IsA("GuiObject") then return end
    if not nameHas(inst.Name, GUI_WORDS) then return end
    if inst:FindFirstAncestor("RageLite") or inst:FindFirstAncestor("RL_ESP") then return end
    pcall(function()
        inst.Visible = false
        if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then inst.ImageTransparency = 1 end
    end)
end))

-- 銃などの動作アニメ(優先度がAction以上のもの)を止める。歩く・走る等は止めない
local function stopAction(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local an = hum and hum:FindFirstChildOfClass("Animator")
    if not an then return end
    for _, t in ipairs(an:GetPlayingAnimationTracks()) do
        local pv = t.Priority.Value
        if pv >= 2 and pv < 1000 then pcall(function() t:Stop(0) end) end
    end
end

local ltoken = tick()
env.RL_LAG_TOKEN = ltoken
task.spawn(function()
    while env.RL_LAG_TOKEN == ltoken do
        task.wait(0.15)
        if S.lagAnim or S.lagSelf then
            for _, p in ipairs(Players:GetPlayers()) do
                local c = p.Character
                if c and ((p ~= lp and S.lagAnim) or (p == lp and S.lagSelf)) then
                    pcall(stopAction, c)
                end
            end
        end
    end
end)

-- ラグの原因を調べる(5秒間、何がどれだけ生成されるか数える)
local lagBusy = false
local function lagReport()
    if lagBusy then return end
    lagBusy = true
    say("5秒間、生成されるものを数えます…")
    local byClass, byName = {}, {}
    local frames, t0 = 0, tick()
    local c1 = workspace.DescendantAdded:Connect(function(d)
        byClass[d.ClassName] = (byClass[d.ClassName] or 0) + 1
        byName[d.Name] = (byName[d.Name] or 0) + 1
    end)
    local c2 = RunService.RenderStepped:Connect(function() frames += 1 end)
    task.delay(5, function()
        c1:Disconnect()
        c2:Disconnect()
        lagBusy = false
        local secs = tick() - t0
        local cnt = {emit = 0, trail = 0, beam = 0, sound = 0, part = 0, light = 0}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") then cnt.emit += 1
            elseif d:IsA("Trail") then cnt.trail += 1
            elseif d:IsA("Beam") then cnt.beam += 1
            elseif d:IsA("Sound") then cnt.sound += 1
            elseif d:IsA("BasePart") then cnt.part += 1
            elseif d:IsA("Light") then cnt.light += 1 end
        end
        local tracks = 0
        for _, p in ipairs(Players:GetPlayers()) do
            local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            local an = hum and hum:FindFirstChildOfClass("Animator")
            if an then tracks += #an:GetPlayingAnimationTracks() end
        end
        local function top(set, n)
            local arr = {}
            for k, v in pairs(set) do table.insert(arr, {k = k, v = v}) end
            table.sort(arr, function(a, b) return a.v > b.v end)
            local out = {}
            for i = 1, math.min(n, #arr) do
                out[i] = arr[i].k .. " x" .. string.format("%.1f", arr[i].v / secs) .. "/秒"
            end
            return table.concat(out, ", ")
        end
        local ping = 0
        pcall(function() ping = lp:GetNetworkPing() * 1000 end)
        local lines = {
            string.format("FPS %.0f / ping %.0fms", frames / secs, ping),
            string.format("パーツ %d / 粒子 %d / 軌跡 %d / ビーム %d / 音 %d / 光 %d",
                cnt.part, cnt.emit, cnt.trail, cnt.beam, cnt.sound, cnt.light),
            "再生中アニメ(全員): " .. tracks,
            "生成/秒(種類): " .. top(byClass, 6),
            "生成/秒(名前): " .. top(byName, 8),
        }
        local out = table.concat(lines, "\n")
        say(out)
        if setclipboard then pcall(setclipboard, out) end
    end)
end

------------------------------------------------------------ 反射の調査(刀の反射を見つけるための記録)
local rec, recData = false, nil
track(RunService.Heartbeat:Connect(function()
    if not rec then return end
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p ~= lp and p.Character
        if c then
            local tool = c:FindFirstChildOfClass("Tool")
            if tool then
                recData.tools[tool.Name] = true
                for k, v in pairs(tool:GetAttributes()) do recData.attrs["tool." .. k .. "=" .. tostring(v)] = true end
            end
            for k, v in pairs(c:GetAttributes()) do recData.attrs["char." .. k .. "=" .. tostring(v)] = true end
            local hum = c:FindFirstChildOfClass("Humanoid")
            local an = hum and hum:FindFirstChildOfClass("Animator")
            if an then
                for _, t in ipairs(an:GetPlayingAnimationTracks()) do
                    local a = t.Animation
                    recData.anims[t.Name .. " [" .. (a and a.AnimationId or "") .. "]"] = true
                end
            end
        end
    end
end))

local function listOf(set, title, lines, limit)
    local arr = {}
    for k in pairs(set) do table.insert(arr, k) end
    table.sort(arr)
    table.insert(lines, "== " .. title .. " ==")
    for i = 1, math.min(#arr, limit) do table.insert(lines, arr[i]) end
end

------------------------------------------------------------ メニュー
RL.addToggle("ESP", "esp")
RL.addToggle("体力バー", "hpbar")
RL.addToggle("名前・距離", "nameDist")
RL.addToggle("武器表示", "espWeapon")
RL.addToggle("FOV円", "fovCircle")
RL.addToggle("エイムボット", "aim")
RL.addCycle("エイム部位", {"頭", "胴体"}, "aimPart", function(v) return v end)
RL.addToggle("体も追従", "bodyFollow")
RL.addCycle("エイム速度", {0.05, 0.1, 0.2, 0.35, 0.6, 1}, "aimSpeed",
    function(v) return math.floor(v * 100 + 0.5) .. "%" end)
RL.addCycle("エイムFOV", {60, 120, 200, 350, 800}, "aimFov", function(v) return tostring(v) end)
RL.addToggle("壁チェック", "aimWall")
RL.addToggle("サイレントエイム", "sa", function(on)
    if on and not saOk then say("このDeltaはフック非対応: サイレントエイム使用不可") end
end)
RL.addCycle("SA部位", {"頭", "胴体"}, "saPart", function(v) return v end)
RL.addCycle("SA命中率", {25, 50, 75, 100}, "saChance", function(v) return v .. "%" end)
RL.addToggle("撃つ間だけ", "saHold")
RL.addToggle("画面レイ変更", "saScreenRay")
RL.addToggle("反射回避", "avoidReflect")
RL.addCycle("反射検知", {"検知", "刀持ち全員"}, "reflectMode", function(v) return v end)
RL.addToggle("ナイフモード", "knife")
RL.addCycle("ナイフ距離", {3, 4, 5, 6, 8}, "knifeDist", function(v) return v .. "st" end)
RL.addCycle("ナイフ滞在", {0.05, 0.1, 0.2}, "knifeStay", function(v) return v .. "秒" end)
RL.addCycle("ナイフ待機", {1, 2, 3, 5}, "knifeWait", function(v) return v .. "秒" end)
RL.addToggle("無限ジャンプ", "infJump")
RL.addToggle("アニメ高速", "animFast")
RL.addCycle("連射回数", {1, 2, 3}, "fireN", function(v) return v .. "回" end)
RL.addToggle("他人のアニメ停止", "lagAnim")
RL.addToggle("自分のアニメ停止", "lagSelf")
RL.addToggle("エフェクト削除", "lagFx", function(on) if on then sweep() end end)
RL.addToggle("弾の描画を消す", "lagBullet", function(on) if on then sweep() end end)
RL.addToggle("ヒット演出を消す", "lagHit", function(on) if on then sweep() end end)
RL.addAction("ラグ調査", lagReport)
RL.addToggle("足速度変更", "walk")
RL.addCycle("足の速さ", {16, 24, 32, 50, 80, 120, 200}, "walkSpeed", function(v) return tostring(v) end)
RL.addAction("SA調査", function()
    if not dbgOn then
        dbgOn, dbg = true, {}
        env.RL_SA_DBG = true
        say("記録中… 視界がおかしくなる操作をして、もう一度押してください")
    else
        dbgOn = false
        env.RL_SA_DBG = false
        local rows = {}
        for key, t in pairs(dbg) do
            local name = "?"
            if typeof(key) == "Instance" then
                local okn, full = pcall(function() return key:GetFullName() end)
                name = okn and full or key.Name
            end
            for m, n in pairs(t) do table.insert(rows, {n = n, s = name .. " : " .. m .. " x" .. n}) end
        end
        table.sort(rows, function(a, b) return a.n > b.n end)
        local lines = {}
        for i = 1, math.min(#rows, 20) do table.insert(lines, rows[i].s) end
        local out = #lines > 0 and table.concat(lines, "\n") or "記録なし"
        say(out)
        if setclipboard then pcall(setclipboard, out) end
    end
end)
RL.addAction("反射調査", function()
    if not rec then
        rec, recData = true, {tools = {}, attrs = {}, anims = {}}
        say("記録中… 敵が刀で反射を使ったあと、もう一度押してください")
    else
        rec = false
        local lines = {}
        listOf(recData.tools, "持っていた武器", lines, 10)
        listOf(recData.attrs, "属性(変化したものが両方出ます)", lines, 25)
        listOf(recData.anims, "再生されたアニメ", lines, 25)
        local out = table.concat(lines, "\n")
        say(out)
        if setclipboard then pcall(setclipboard, out) end
    end
end)

------------------------------------------------------------ 設定の保存
if S.autosave == nil then S.autosave = true end
local SV = RL.save
local lastSaved

local function collect()
    local t = {}
    for _, k in ipairs(SV.keys) do
        if S[k] ~= nil then t[k] = S[k] end
    end
    return t
end

local function doSave(manual)
    if not writefile then
        if manual then say("このDeltaはファイル保存に対応していません") end
        return false
    end
    local ok, js = pcall(function() return HttpService:JSONEncode(collect()) end)
    if not ok then return false end
    if js == lastSaved and not manual then return true end
    local ok2 = pcall(writefile, SV.file, js)
    if ok2 then
        lastSaved = js
        if manual then say("設定を保存しました") end
    elseif manual then
        say("保存に失敗しました")
    end
    return ok2
end

local stoken = tick()
env.RL_SAVE_TOKEN = stoken
task.spawn(function()
    while env.RL_SAVE_TOKEN == stoken do
        task.wait(2)
        if S.autosave then pcall(doSave, false) end
    end
end)

RL.addToggle("自動保存", "autosave")
RL.addAction("設定を保存", function() doSave(true) end)
RL.addAction("設定を初期化", function()
    S.autosave = false
    if R.autosave then R.autosave() end
    local done = false
    if delfile and isfile and isfile(SV.file) then done = pcall(delfile, SV.file) end
    if not done and writefile then done = pcall(writefile, SV.file, "{}") end
    say(done and "保存した設定を消しました。入り直すと初期設定に戻ります" or "消せませんでした")
end)

say((saOk and "準備OK" or "準備OK(サイレントエイムは非対応)")
    .. (SV.loaded and " / 保存した設定を読み込みました" or ""))
end
