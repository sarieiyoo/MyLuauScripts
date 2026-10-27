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
    "aimFov", "aimWall", "sa", "saChance", "aimPart", "saPart", "bodyFollow", "autosave", "espWeapon", "avoidReflect", "walk", "walkSpeed", "saScreenRay", "saHold", "aimWhen",
    "prio", "reflectMode", "infJump", "knife", "knifeBack", "knifeDown", "knifeStay", "knifeWait", "knifeFace", "knifePredict", "animFast",
    "fireN", "lagAnim", "lagFx", "lagBullet", "lagHit", "lagSelf", "espRank", "knifeFar", "fakeInput", "knifeSpin", "knifeAbility", "abilityMode", "abilityDelay", "abilityHold", "abilityLead",
    "farHome", "farHomeDist", "followPredict", "meleePre", "bodyFly", "flySpeed", "sameMatch", "matchDist", "cheaterSpeed", "cheaterH", "cheaterSpin"}
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
local function say(t)
    t = tostring(t)
    if statLbl.Text == t then return end
    statLbl.Text = t
    statBox.CanvasPosition = Vector2.zero
end

local TABS = {"戦闘", "視点", "調査", "ESP", "エモ"}
local TITLES = {"Combat", "View", "Debug", "ESP / Aim", "Emotes"}
local SUBS = {"自動照準・RAGEBOT", "視点操作・飛行 / フリー", "開始・チームの調査", "ESP・エイムボット・サイレントエイム", "エモート70個以上"}
local HEADERS = {{"General", "Strategy"}, {"View", "Controls"}, {"Debug", "Settings"}, {"Visual", "Aim"}, {"Emotes", "More"}}

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
    ["優先順位"] = {1, 1}, ["反射検知"] = {4, 2}, ["エイム条件"] = {4, 2}, ["スコープ調査"] = {3, 1},
    ["ナイフモード"] = {1, 2}, ["ナイフ後方"] = {1, 2}, ["ナイフ地下"] = {1, 2}, ["ナイフ向き"] = {1, 2}, ["ナイフ予測"] = {1, 2}, ["ナイフ滞在"] = {1, 2}, ["ナイフ待機"] = {1, 2},
    ["無限ジャンプ"] = {1, 2}, ["アニメ高速"] = {1, 2}, ["連射回数"] = {1, 2},
    ["ランク表示"] = {4, 1}, ["ナイフ帰還距離"] = {1, 2}, ["入力偽装攻撃"] = {1, 2}, ["敵情報調査"] = {3, 1},
    ["視点ブンブン"] = {1, 2}, ["背中で能力ボタン"] = {1, 2}, ["ボタン一覧"] = {3, 1},
    ["能力入力"] = {1, 2}, ["能力先押し"] = {1, 2}, ["能力タイミング"] = {1, 2}, ["能力長押し"] = {1, 2}, ["右クリックテスト"] = {3, 1},
    ["チーターモード"] = {1, 2}, ["チーター速度"] = {1, 2}, ["チーター高さ"] = {1, 2}, ["チーター視点ブンブン"] = {1, 2},
    ["遠方帰還"] = {1, 2}, ["遠方の座標"] = {1, 2}, ["追従予測"] = {1, 2}, ["近接の先行攻撃"] = {1, 2},
    ["体で飛ぶ"] = {2, 1}, ["体の飛行速度"] = {2, 1},
    ["エモート停止"] = {5, 1}, ["エモート方式"] = {5, 1}, ["体の形式調査"] = {5, 1}, ["INMUのエモートをコピー"] = {5, 1}, ["ゲームのエモート"] = {5, 1}, ["ゲームのエモート再生"] = {5, 1}, ["Broke"] = {5, 1}, ["Tornado"] = {5, 1}, ["Yokoyure Step"] = {5, 1}, ["Invisible"] = {5, 1}, ["Original Gangnam Style"] = {5, 1}, ["HOT Spinning Cat"] = {5, 1}, ["Good Boy Dog"] = {5, 1}, ["Tall Giant"] = {5, 1}, ["Mega Poop"] = {5, 1}, ["Wave"] = {5, 1}, ["Point"] = {5, 1}, ["Dance"] = {5, 1}, ["Dance 2"] = {5, 1}, ["Dance 3"] = {5, 1}, ["Laugh"] = {5, 1}, ["Cheer"] = {5, 1}, ["Floss Dance"] = {5, 1}, ["Zombie"] = {5, 1}, ["Robot"] = {5, 1}, ["Dolphin Dance"] = {5, 1}, ["Monkey"] = {5, 1}, ["Dorky Dance"] = {5, 1}, ["Tantrum"] = {5, 1}, ["Dizzy"] = {5, 1}, ["Godlike"] = {5, 1}, ["Hero Landing"] = {5, 1}, ["Swan Dance"] = {5, 1}, ["Old Town Road"] = {5, 1}, ["Panini Dance"] = {5, 1}, ["Break Dance"] = {5, 1}, ["Top Rock"] = {5, 1}, ["Cha Cha"] = {5, 1}, ["Samba"] = {5, 1}, ["Line Dance"] = {5, 1}, ["Twirl"] = {5, 1}, ["Side to Side"] = {5, 1}, ["Power Blast"] = {5, 1}, ["Shuffle"] = {5, 1}, ["Rock On"] = {5, 1}, ["Fancy Feet"] = {5, 1}, ["Get Out"] = {5, 2}, ["Fishing"] = {5, 2}, ["Bodybuilder"] = {5, 2}, ["Jacks"] = {5, 2}, ["Louder"] = {5, 2}, ["Sneaky"] = {5, 2}, ["Swish"] = {5, 2}, ["Greatest"] = {5, 2}, ["Idol"] = {5, 2}, ["Cower"] = {5, 2}, ["Confused"] = {5, 2}, ["Beckon"] = {5, 2}, ["Baby Dance"] = {5, 2}, ["Block Partier"] = {5, 2}, ["Air Dance"] = {5, 2}, ["Tree"] = {5, 2}, ["Skibidi Laser Spin"] = {5, 2}, ["Shrek Roar"] = {5, 2}, ["Mini Kong"] = {5, 2}, ["NBA Monster Dunk"] = {5, 2}, ["The Zabb"] = {5, 2}, ["SpongeBob Imagination"] = {5, 2}, ["TMNT Dance"] = {5, 2}, ["Wanna Play"] = {5, 2}, ["Super Charge"] = {5, 2}, ["Boxing Punch"] = {5, 2}, ["Show Dem Wrists"] = {5, 2}, ["Wake Up Call"] = {5, 2}, ["Sturdy Dance"] = {5, 2}, ["Mean Girls Dance"] = {5, 2}, ["Breaking"] = {5, 2}, ["d4vd Backflip"] = {5, 2}, ["Cartwheel"] = {5, 2}, ["Air Guitar Slide"] = {5, 2}, ["Rolling Stones Guitar"] = {5, 2}, ["Piano Hands"] = {5, 2}, ["Yungblud High Kick"] = {5, 2}, ["Bones Dance"] = {5, 2}, ["GloRilla Dance"] = {5, 2}, ["Fashion Roadkill"] = {5, 2},
    ["同じ試合のみ"] = {1, 1}, ["対象距離"] = {1, 1},
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

for t = 1, 5 do
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

local S, lp, say, ST = RL.S, RL.lp, RL.say, RL.ST
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

-- 同じ試合の相手だけを対象にする(ロビーサーバーで、ほかの試合をしている人を狙わないため)
-- ① 自分の基準位置から「対象距離」より遠い人は除く ② 試合・部屋を表す属性が自分と違う人は除く
if S.sameMatch == nil then S.sameMatch = true end
if S.matchDist == nil then S.matchDist = 600 end
local MKEYS = {"match", "arena", "room", "session", "lobby"}
local function matchAttrs(inst, out)
    for k, v in pairs(inst:GetAttributes()) do
        local kl = k:lower()
        for _, w in ipairs(MKEYS) do
            if kl:find(w, 1, true) then out[k] = tostring(v) break end
        end
    end
end
local function inMatch(p)
    if not S.sameMatch then return true end
    local c = p.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not r then return false end
    local base = ST.ref
    if S.matchDist > 0 and base and (r.Position - base).Magnitude > S.matchDist then return false end
    local a, b = {}, {}
    matchAttrs(lp, a)
    matchAttrs(p, b)
    for k, v in pairs(a) do
        if b[k] ~= nil and b[k] ~= v then return false end
    end
    return true
end
RL.inMatch = inMatch

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
        if p ~= lp and h and h.Health > 0 and r and (not S.team or isEnemy(p))
            and inMatch(p)
            and not (S.avoidReflect and RL.isDeflecting and RL.isDeflecting(c, p)) then
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
RL.addToggle("同じ試合のみ", "sameMatch")
RL.addCycle("対象距離", {150, 300, 600, 1000, 0}, "matchDist", function(v) return v == 0 and "無制限" or (v .. "st") end)
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
        if h and h.Health > 0 and r
            and not (S.avoidReflect and RL.isDeflecting and RL.isDeflecting(target)) then
            return target
        end
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

-- 当たり判定を消す(部品の一覧は覚えておく。毎フレーム全部を調べ直さない)
local ccChar, ccParts
local function noCollide(char)
    if ccChar ~= char then
        ccChar, ccParts = char, {}
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then ccParts[#ccParts + 1] = d end
        end
    end
    for i = 1, #ccParts do
        local part = ccParts[i]
        if part.CanCollide then part.CanCollide = false end
    end
end

-- 敵の真下へ。通信の遅れの分だけ、敵の動く先を読んで合わせる(ずっと真下にいるため)
local function placeUnder(root, enemy, aim)
    local er = enemy.HumanoidRootPart
    local base = er.Position
    if S.followPredict then
        local ping = 0
        pcall(function() ping = lp:GetNetworkPing() end)
        base = base + er.AssemblyLinearVelocity * (ping + 0.03)
    end
    root.CFrame = CFrame.lookAt(base - Vector3.new(0, S.depth, 0), aim)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    ST.lastSet = root.Position
end
RL.placeUnder = placeUnder
RL.getTarget = getTarget

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
    if not S.rage or S.knife or S.cheater then return end
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

-- 遠方の待機場所(座標500000など。毎回少しずらす)
local function newFarPoint()
    local d = S.farHomeDist or 500000
    return Vector3.new(d + math.random(-5000, 5000), 5000, d + math.random(-5000, 5000))
end

local function doReturn(root)
    release()
    local pt
    if S.farHome then
        pt = newFarPoint()
        ST.farHold = pt
    else
        ST.farHold = nil
        pt = safePoint()
    end
    if pt then
        root.CFrame = CFrame.new(pt)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        lastPos = root.Position
        say(S.farHome and "撃破 → 遠方へ退避" or (viewPos() and "撃破 → 視点の位置へ戻った" or "撃破 → 初期地点へ戻った"))
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
    if S.rage and not S.knife and not ST.attacking and not ST.lastSet and lastPos
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

    if S.auto and not S.rage and not S.cheater and tick() > ignoreUntil then
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

    if not S.rage or S.cheater then ST.attacking, target = false, nil return end
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
            noCollide(char)
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
    aim = false, aimSpeed = 0.2, aimFov = 200, aimWall = false, aimWhen = "常に",
    sa = false, saChance = 100, saScreenRay = false, saHold = true,
    aimPart = "胴体", saPart = "胴体", bodyFollow = true,
    avoidReflect = true, walk = false, walkSpeed = 50,
    reflectMode = "刀持ち全員", infJump = false, knife = false, knifeBack = 4, knifeDown = 0, knifeStay = 0.1, knifeWait = 3,
    knifeFace = "攻撃時だけ向く", knifePredict = true,
    knifeFar = 5000, fakeInput = true, espRank = true,
    farHome = true, farHomeDist = 500000, followPredict = true, meleePre = true, bodyFly = false, flySpeed = 60,
    cheater = false, cheaterSpeed = 500000, cheaterH = "奈落", cheaterSpin = true, knifeSpin = true, knifeAbility = true,
    abilityMode = "両方", abilityDelay = 0.02, abilityHold = 0.05, abilityLead = 0.1,
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

------------------------------------------------------------ 武器の判別 / ランク / 刀の反射(デフレクト)の検知
local itemSet, itemNorm
local function norm(n) return (tostring(n):lower():gsub("[^%w]", "")) end

-- 武器の名前リスト(ゲームのItemLibraryが読めなくても使えるように、既知の名前も入れておく)
local KNOWN = {"Crossbow", "Grenade Launcher", "Medkit", "Jump Pad", "Spear", "Flashbang", "Elixir",
    "Subspace Tripmine", "Flamethrower", "Grenade", "Satchel", "Warpstone", "Wildcat", "Grappler", "Scythe",
    "Permafrost", "Slingshot", "Battle Axe", "Distortion", "Flare Gun", "Molotov", "Knife", "Fists", "Spray",
    "Shotgun", "Revolver", "Trowel", "Riot Shield", "Assault Rifle", "Sniper", "Energy Pistols", "Daggers",
    "Shorty", "Scepter", "Glast Shard", "Maul", "Chainsaw", "Warper", "Freeze Ray", "Exogun", "Minigun",
    "Paintball Gun", "RNG Dice", "Energy Rifle", "Katana", "RPG", "Bow", "Uzi", "Smoke Grenade",
    "Burst Rifle", "Handgun", "Gunblade", "Glass Cannon", "War Horn"}

local function loadItems()
    if itemSet then return itemNorm end
    itemSet, itemNorm = {}, {}
    for _, n in ipairs(KNOWN) do itemSet[n] = true itemNorm[norm(n)] = n end
    pcall(function()
        for _, m in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if m:IsA("ModuleScript") and m.Name == "ItemLibrary" then
                local lib = require(m)
                if type(lib) == "table" and type(lib.Items) == "table" then
                    for name in pairs(lib.Items) do
                        itemSet[tostring(name)] = true
                        itemNorm[norm(name)] = tostring(name)
                    end
                end
            end
        end
    end)
    return itemNorm
end

local W_NAMES = {"Weapon", "EquippedWeapon", "CurrentWeapon", "ActiveWeapon", "Equipped", "EquippedItem",
    "CurrentItem", "Item", "Held", "HeldItem", "Holding", "Tool", "Wep"}
local W_KEYS = {"weapon", "equipped", "equip", "held", "holding", "tool", "gun", "wep", "item"}

local function keyIsWeapon(k)
    k = tostring(k):lower()
    for _, w in ipairs(W_KEYS) do
        if k:find(w, 1, true) then return true end
    end
    return false
end

-- 値(文字列 / インスタンス)から武器の名前を取り出す
local function resolve(v)
    local nn = loadItems()
    if typeof(v) == "Instance" then
        if nn[norm(v.Name)] then return nn[norm(v.Name)] end
        for _, d in ipairs(v:GetDescendants()) do
            if nn[norm(d.Name)] then return nn[norm(d.Name)] end
        end
        local f = v:GetChildren()[1]
        if (v:IsA("Folder") or v:IsA("Configuration")) and f then return f.Name end
        return v.Name
    elseif type(v) == "string" and v ~= "" then
        return nn[norm(v)] or v
    end
end

-- ワークスペース内にある「武器の名前のモデル/パーツ」を覚えておく(キャラの外に置かれた武器も見つけるため)
local itemObjs = {}   -- [Instance] = 武器名
local function trackItem(inst)
    if inst:IsA("Model") or inst:IsA("BasePart") or inst:IsA("Tool") or inst:IsA("Accessory") then
        local n = loadItems()[norm(inst.Name)]
        if n then itemObjs[inst] = n end
    end
end
loadItems()
track(workspace.DescendantAdded:Connect(function(inst) pcall(trackItem, inst) end))
track(workspace.DescendantRemoving:Connect(function(inst) itemObjs[inst] = nil end))
task.spawn(function()
    local n = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        pcall(trackItem, d)
        n += 1
        if n % 400 == 0 then task.wait() end
    end
end)

local function posOf(inst)
    if inst:IsA("Model") then
        local ok, cf = pcall(function() return inst:GetPivot() end)
        return ok and cf.Position or nil
    elseif inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Tool") then
        local h = inst:FindFirstChild("Handle")
        return h and h.Position
    end
end

-- 持ち主のキャラ(Humanoidのあるモデル)
local function owner(inst)
    local x = inst.Parent
    while x and x ~= workspace do
        if x:IsA("Model") and x:FindFirstChildOfClass("Humanoid") then return x end
        x = x.Parent
    end
end

-- キャラの近く(9stud以内)にある武器モデル
local function nearbyItem(c)
    local root = c:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local cam = workspace.CurrentCamera
    local best, bd
    for inst, name in pairs(itemObjs) do
        if inst.Parent and not (cam and inst:IsDescendantOf(cam)) then
            local ow = owner(inst)
            if ow == nil or ow == c then
                local ip = posOf(inst)
                if ip then
                    local d = (ip - root.Position).Magnitude
                    if d < 9 and (not bd or d < bd) then best, bd = name, d end
                end
            end
        end
    end
    return best
end

-- 再生中のアニメの名前から武器を当てる(例: "Katana_Idle" → Katana)。長く一致した名前を優先
local function fromAnims(c)
    local nn = loadItems()
    local hum = c:FindFirstChildOfClass("Humanoid")
    local an = hum and hum:FindFirstChildOfClass("Animator")
    if not an then return end
    local best, bl
    for _, t in ipairs(an:GetPlayingAnimationTracks()) do
        local texts = {norm(t.Name)}
        local a = t.Animation
        if a then table.insert(texts, norm(a.Name)) end
        for _, tx in ipairs(texts) do
            for key, name in pairs(nn) do
                if #key >= 3 and tx:find(key, 1, true) and (not bl or #key > bl) then
                    best, bl = name, #key
                end
            end
        end
    end
    return best
end

-- 敵が持っている武器の名前。Tool → Weapon等の値 → 属性 → 値オブジェクト → キャラのモデル
-- → キャラの近くの武器モデル → 再生中アニメの名前、の順に探す
local function weaponName(p, c)
    local nn = loadItems()
    local tool = c:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end

    -- ① Weapon / Equipped などの名前の子や値
    for _, holder in ipairs({c, p}) do
        for _, n in ipairs(W_NAMES) do
            local d = holder:FindFirstChild(n)
            if d then
                local r
                if d:IsA("ValueBase") then r = resolve(d.Value) else r = resolve(d) end
                if r and r ~= n then return r end
            end
        end
    end
    -- ② 属性(武器っぽい名前のキー、または値が武器名)
    for _, holder in ipairs({c, p}) do
        for k, v in pairs(holder:GetAttributes()) do
            if type(v) == "string" and v ~= "" and (nn[norm(v)] or keyIsWeapon(k)) then
                return resolve(v)
            end
        end
    end
    -- ③ プレイヤー/キャラの下にある値オブジェクト
    local function vals(folder, depth)
        for _, d in ipairs(folder:GetChildren()) do
            if d:IsA("ValueBase") then
                local v = d.Value
                if (type(v) == "string" and (nn[norm(v)] or (keyIsWeapon(d.Name) and v ~= "")))
                    or (typeof(v) == "Instance" and keyIsWeapon(d.Name)) then
                    return resolve(v)
                end
            elseif depth > 0 and (d:IsA("Folder") or d:IsA("Configuration")) then
                local r = vals(d, depth - 1)
                if r then return r end
            end
        end
    end
    local r = vals(p, 2) or vals(c, 1)
    if r then return r end
    -- ④ キャラについている武器モデル(名前が同じ、または武器名を含む)
    for _, d in ipairs(c:GetDescendants()) do
        local key = norm(d.Name)
        local n = nn[key]
        if n and (d:IsA("Model") or d:IsA("BasePart") or d:IsA("Folder") or d:IsA("Accessory")) then return n end
        if d.Name == "Handle" and d.Parent and nn[norm(d.Parent.Name)] then return nn[norm(d.Parent.Name)] end
        if #key >= 5 and (d:IsA("Model") or d:IsA("Folder") or d:IsA("Accessory") or d:IsA("Tool")) then
            for k2, nm in pairs(nn) do
                if #k2 >= 5 and key:find(k2, 1, true) then return nm end
            end
        end
    end
    -- ⑤ キャラの近くにある武器モデル(キャラの外に置かれている場合)
    local near = nearbyItem(c)
    if near then return near end
    -- ⑥ 再生中のアニメの名前
    return fromAnims(c) or "-"
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

-- 相手のランク。Elo/Division/Tier/Rank などの名前の値・属性を、プレイヤーの下(3階層)、
-- キャラの下(2階層)、ReplicatedStorage内の「プレイヤー名/ユーザーIDのフォルダ」から探す。
-- グループのランク(名前や置き場所に group / role を含むもの)は除く。Eloを一番優先する。
-- 見つからなければ、頭上の名前表示などの文字(Gold, Diamond など)を探す
local RANK_KEYS = {"elo", "mmr", "rating", "division", "tier", "league", "rank", "trophy", "prestige", "level", "grade"}
local TIER_WORDS = {"bronze", "silver", "gold", "platinum", "diamond", "master", "grandmaster", "challenger",
    "legend", "nemesis", "unreal", "elite", "champion", "iron", "emerald", "ruby"}
local SKIP = {PlayerGui = true, Backpack = true, PlayerScripts = true, StarterGear = true}

local function rankOf(p, c)
    local found, seen = {}, {}
    local function consider(k, v, ctx)
        local tv = type(v)
        if tv ~= "number" and tv ~= "string" then return end
        local kl = tostring(k):lower()
        local cl = ctx:lower()
        -- グループのランク・役職は対象外(キー名だけでなく、入っているフォルダ名も見る)
        if kl:find("group", 1, true) or kl:find("role", 1, true)
            or cl:find("group", 1, true) or cl:find("role", 1, true) then return end
        for i, w in ipairs(RANK_KEYS) do
            if kl:find(w, 1, true) then
                local txt = tostring(k) .. " " .. tostring(tv == "number" and math.floor(v) or v)
                if not seen[txt] then
                    seen[txt] = true
                    table.insert(found, {i = i, t = txt})
                end
                return
            end
        end
    end
    local function scan(inst, depth, ctx)
        for k, v in pairs(inst:GetAttributes()) do consider(k, v, ctx) end
        for _, d in ipairs(inst:GetChildren()) do
            if d:IsA("ValueBase") then
                consider(d.Name, d.Value, ctx)
                for k, v in pairs(d:GetAttributes()) do consider(k, v, ctx) end
            elseif depth > 0 and not SKIP[d.Name] and not d:IsA("Tool") and not d:IsA("BasePart")
                and not d:IsA("Humanoid") then
                scan(d, depth - 1, ctx .. "/" .. d.Name)
            end
        end
    end
    scan(p, 3, "")
    if c then scan(c, 2, "") end

    local rs = game:GetService("ReplicatedStorage")
    local function look(parent)
        local d = parent:FindFirstChild(p.Name) or parent:FindFirstChild(tostring(p.UserId))
        if d then scan(d, 2, "") end
    end
    look(rs)
    for _, f in ipairs(rs:GetChildren()) do
        if f:IsA("Folder") or f:IsA("Configuration") then look(f) end
    end

    if #found > 0 then
        table.sort(found, function(a, b) return a.i < b.i end)
        return found[1].t .. (found[2] and (" / " .. found[2].t) or "")
    end
    if c then
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("TextLabel") then
                local t = d.Text:lower()
                for _, w in ipairs(TIER_WORDS) do
                    if t:find(w, 1, true) then return d.Text end
                end
            end
        end
    end
    return "-"
end

local rcache = setmetatable({}, {__mode = "k"})
local function rankCached(p, c)
    local e = rcache[p]
    local now = tick()
    if e and now - e.t < 1 then return e.v end
    local v = rankOf(p, c)
    rcache[p] = {v = v, t = now}
    return v
end

-- 刀の反射(デフレクト)
local WORDS = {"deflect", "parry", "reflect", "block", "guard", "counter"}
local function hasWord(n)
    n = tostring(n):lower()
    for _, w in ipairs(WORDS) do
        if n:find(w, 1, true) then return true end
    end
    return false
end
local function truthy(v) return v == true or (type(v) == "number" and v > 0) end

-- 反射中なら true。
--   「刀持ち全員」: 刀を持っている敵は全員、反射する前提で避ける
--   「アニメ」   : 刀を持っていて、動作アニメ(Action以上)を再生中なら反射中とみなす
--   「検知」     : 反射中らしい印(属性・値・子の名前・アニメ名)があるときだけ
local function isDeflecting(c, p)
    p = p or Players:GetPlayerFromCharacter(c)
    if not p then return false end
    local w = weaponOf(p, c):lower()
    local known = w ~= "-"
    if known and not w:find("katana", 1, true) then return false end
    if S.reflectMode == "刀持ち全員" then return known end

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
            if known and S.reflectMode == "アニメ" then
                local pv = t.Priority.Value
                if pv >= 2 and pv < 1000 then return true end
            end
        end
    end
    return false
end

-- RAGE側(撃つ処理)や対象選びからも使えるように公開
RL.isDeflecting = function(c, p) return isDeflecting(c, p) end

local deflecting = {}   -- [キャラ] = HumanoidRootPart (反射中の敵)

-- 敵のデータ構造を書き出す(武器・ランクの見つけ方を合わせるための調査用)
local function dumpEnemy()
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and enemy(p) then target = p break end
    end
    if not target then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then target = p break end
        end
    end
    if not target then say("調べる相手がいません") return end
    local p, c = target, target.Character
    local lines = {"相手: " .. p.Name}
    local function attrs(inst, label)
        for k, v in pairs(inst:GetAttributes()) do
            table.insert(lines, label .. " attr " .. tostring(k) .. "=" .. tostring(v))
        end
    end
    local function tree(inst, label, depth)
        for _, d in ipairs(inst:GetChildren()) do
            local extra = ""
            if d:IsA("ValueBase") then extra = "=" .. tostring(d.Value) end
            table.insert(lines, label .. " " .. d.Name .. ":" .. d.ClassName .. extra)
            attrs(d, label .. "/" .. d.Name)
            if depth > 0 and (d:IsA("Folder") or d:IsA("Configuration")) then tree(d, label .. "/" .. d.Name, depth - 1) end
        end
    end
    attrs(p, "player")
    attrs(c, "char")
    tree(p, "player", 2)
    tree(c, "char", 0)
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then table.insert(lines, "char text: " .. d.Text) end
    end
    local hum2 = c:FindFirstChildOfClass("Humanoid")
    local an2 = hum2 and hum2:FindFirstChildOfClass("Animator")
    if an2 then
        for _, t in ipairs(an2:GetPlayingAnimationTracks()) do
            local a = t.Animation
            table.insert(lines, "anim: " .. t.Name .. " [" .. (a and a.AnimationId or "") .. "] " .. t.Priority.Name)
        end
    end
    local rootc = c:FindFirstChild("HumanoidRootPart")
    if rootc then
        local cnt = 0
        for inst, nm in pairs(itemObjs) do
            if inst.Parent and cnt < 6 then
                local ip = posOf(inst)
                if ip and (ip - rootc.Position).Magnitude < 12 then
                    cnt += 1
                    table.insert(lines, "近くの武器モデル: " .. inst:GetFullName() .. " = " .. nm)
                end
            end
        end
    end
    local rsv = game:GetService("ReplicatedStorage")
    for _, f in ipairs(rsv:GetChildren()) do
        local d = f:FindFirstChild(p.Name) or f:FindFirstChild(tostring(p.UserId))
        if d then
            table.insert(lines, "ReplicatedStorage内: " .. d:GetFullName())
            attrs(d, "rs")
            tree(d, "rs", 1)
        end
    end
    table.insert(lines, "武器判定: " .. weaponName(p, c))
    table.insert(lines, "ランク判定: " .. rankOf(p, c))
    local mine = lp.Character
    if mine then
        table.insert(lines, "自分の武器判定: " .. weaponName(lp, mine))
        for _, d in ipairs(mine:GetChildren()) do
            if d:IsA("Tool") then table.insert(lines, "自分のTool: " .. d.Name) end
        end
        local bp = lp:FindFirstChild("Backpack")
        if bp then
            for _, d in ipairs(bp:GetChildren()) do table.insert(lines, "バックパック: " .. d.Name .. ":" .. d.ClassName) end
        end
    end
    local out = table.concat(lines, "\n")
    if #lines > 90 then out = table.concat(lines, "\n", 1, 90) .. "\n…(省略)" end
    say(out)
    if setclipboard then pcall(setclipboard, table.concat(lines, "\n")) end
end

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
    bb.Size = UDim2.fromOffset(120, 66)
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
    local rL = mkLabel(bb, 49, 11, Enum.Font.Gotham)
    rL.TextColor3 = Color3.fromRGB(150, 210, 255)

    ents[p] = {char = c, hl = hl, bb = bb, nameL = nameL, bar = bar, fill = fill, hpL = hpL, wL = wL, rL = rL}
    return ents[p]
end

local lastSlow = 0
track(RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    local now = tick()
    local slow = now - lastSlow > 0.1
    if slow then lastSlow = now end
    if not (S.esp or S.hpbar or S.nameDist or S.espWeapon or S.espRank) then
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

                e.bb.Enabled = S.hpbar or S.nameDist or S.espWeapon or S.espRank
                e.nameL.Visible = S.nameDist
                e.bar.Visible = S.hpbar
                e.hpL.Visible = S.hpbar
                e.wL.Visible = S.espWeapon
                e.rL.Visible = S.espRank
                if S.nameDist and slow then
                    local dist = math.floor((head.Position - cam.CFrame.Position).Magnitude)
                    e.nameL.Text = string.format("%s  [%dm]", p.DisplayName, dist)
                end
                if S.hpbar then
                    e.fill.Size = UDim2.new(ratio, 0, 1, 0)
                    e.fill.BackgroundColor3 = col
                    e.hpL.Text = math.floor(h.Health) .. " / " .. math.floor(h.MaxHealth)
                end
                if S.espRank and slow then
                    e.rL.Text = "ランク: " .. rankCached(p, c)
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
        if p ~= lp and enemy(p) and (not RL.inMatch or RL.inMatch(p)) then
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

-- スコープ(ADS)中かどうかの判定。次のどれかなら「スコープ中」
--   ① 属性に scope / aiming / zoom / ads を含む名前で、値が真のもの
--   ② 視野角(FOV)が、普段(最近の最大値)より8度以上小さい
--   ③ 右クリックを押している
local UISv = game:GetService("UserInputService")
local fovBase, scopeWhy = 70, ""
local SCOPE_KEYS = {"scope", "aiming", "zoom"}
local function trackFov(cam, dt)
    fovBase = math.max(cam.FieldOfView, fovBase - dt * 0.5)
end
local function isScoped(cam)
    for _, inst in ipairs({lp, lp.Character}) do
        if inst then
            for k, v in pairs(inst:GetAttributes()) do
                local kl = k:lower()
                local hit = kl == "ads" or kl == "isads"
                for _, w in ipairs(SCOPE_KEYS) do
                    if kl:find(w, 1, true) then hit = true end
                end
                if hit and (v == true or (type(v) == "number" and v > 0)) then
                    scopeWhy = "属性 " .. k
                    return true
                end
            end
        end
    end
    if cam.FieldOfView < fovBase - 8 then
        scopeWhy = string.format("視野角 %.0f (普段 %.0f)", cam.FieldOfView, fovBase)
        return true
    end
    if UISv:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        scopeWhy = "右クリック"
        return true
    end
    scopeWhy = ""
    return false
end

-- スコープの判定を見る(スコープをのぞいた状態で押す)
local function scopeReport()
    local cam = workspace.CurrentCamera
    local on = isScoped(cam)
    local out = string.format("スコープ判定: %s %s\n視野角 %.1f / 普段 %.1f",
        on and "中" or "していない", on and ("(" .. scopeWhy .. ")") or "", cam.FieldOfView, fovBase)
    say(out)
    if setclipboard then pcall(setclipboard, out) end
end

local rotOff = false
local pmod

RunService:BindToRenderStep("RL_Aim", Enum.RenderPriority.Camera.Value + 3, function(dt)
    local cam = workspace.CurrentCamera
    local active = not S.rage and not S.fc
    trackFov(cam, dt)
    -- エイムボットの作動条件(常に / スコープ中のみ)
    local gate = (S.aimWhen ~= "スコープ中のみ") or isScoped(cam)

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
        if S.aim and gate then aimT = pick(cam, S.aimPart) end
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
    if S.aim and gate and active and next(deflecting) then
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
            -- 体の向き = 今の視点の向き(横方向)。次の物理計算の前後でも、下の処理が合わせ直す
            local lv = cam.CFrame.LookVector
            local flat = Vector3.new(lv.X, 0, lv.Z)
            if flat.Magnitude > 0.05 then
                RL.ST.aimFace, RL.ST.aimFaceT = flat.Unit, tick()
                hum.AutoRotate = false
                rotOff = true
                root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
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
            if m == "IsMouseButtonPressed" and env.RL_RMB and not checkcaller() then
                local ut = ...
                if ut == Enum.UserInputType.MouseButton2 then return true end
            end
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

------------------------------------------------------------ ナイフモード(背後へ一瞬テレポート → 能力ボタンで刺す → マップから遠く離れたランダムな場所で待機)
pcall(function() RunService:UnbindFromRenderStep("RL_Knife") end)
local K = {state = "wait", t = tick(), enemy = nil, far = nil, base = nil, lastEquip = 0, pressed = false,
    rmbDown = false, rmbDone = false, rmbT = 0, lastAtk = 0, hits = 0, tries = 0, hp0 = nil}

-- マップの外(上空)の、毎回ちがうランダムな場所
local function farPoint(base)
    local a = math.random() * math.pi * 2
    local r = S.knifeFar * (0.6 + math.random() * 0.4)
    local up = S.knifeFar * (0.3 + math.random() * 0.5)
    return Vector3.new(base.X + math.cos(a) * r, base.Y + up, base.Z + math.sin(a) * r)
end

-- 360°どの向きでもランダム(毎フレーム変える)
local function randRot()
    return CFrame.Angles((math.random() - 0.5) * math.pi, math.random() * math.pi * 2, 0)
end

-- 位置を pt にする。face があればその方向を向く / なければ「視点ブンブン」ON=ランダム、OFF=今のまま
local function place(root, pt, face)
    local rot
    if face and (face - pt).Magnitude > 0.1 then
        rot = CFrame.lookAt(pt, face) - pt
    else
        rot = S.knifeSpin and randRot() or (root.CFrame - root.Position)
    end
    root.CFrame = CFrame.new(pt) * rot
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

-- 刺す位置: 敵の向きの反対側へ「後方」stud、下へ「地下」stud。動いている敵には先読みを入れる
local function strikeTarget(er)
    local base = er.Position
    if S.knifePredict then
        local ping = 0
        pcall(function() ping = lp:GetNetworkPing() end)
        base = base + er.AssemblyLinearVelocity * (ping + 0.05)
    end
    return base - er.CFrame.LookVector * S.knifeBack - Vector3.new(0, S.knifeDown, 0)
end

local function applyStrike(root, er)
    local face = (S.knifeFace == "攻撃時だけ向く") and er.Position or nil
    place(root, strikeTarget(er), face)
end

-- 入力を偽装して、ゲームの「クリック」の処理を直接呼ぶ(押す=down true / 離す=down false)
local function fakeButton(inputType, down)
    if not getconnections then return end
    local obj = {UserInputType = inputType,
        UserInputState = down and Enum.UserInputState.Begin or Enum.UserInputState.End,
        KeyCode = Enum.KeyCode.Unknown, Position = Vector3.zero, Delta = Vector3.zero}
    for _, cn in ipairs(getconnections(down and UIS.InputBegan or UIS.InputEnded)) do
        pcall(function() cn:Fire(obj, false) end)
    end
end

local function fakeClick(inputType)
    fakeButton(inputType, true)
    fakeButton(inputType, false)
end

local function attack(char)
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
    if S.fakeInput then pcall(fakeClick, Enum.UserInputType.MouseButton1) end
end

-- 攻撃は0.08秒おき(毎フレーム送ると、ゲーム側のクールダウンでかえって通らないことがある)
local function tryAttack(char)
    if tick() - K.lastAtk < 0.08 then return end
    K.lastAtk = tick()
    attack(char)
end

-- 画面のボタンを、名前や文字で探して押す
local function ourGui(d) return d:FindFirstAncestor("RageLite") or d:FindFirstAncestor("RL_ESP") end

local function pressWords(words)
    if not getconnections then return false end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("GuiButton") and not ourGui(d) then
            local t = d.Name:lower()
            if d:IsA("TextButton") then t = t .. " " .. d.Text:lower() end
            for _, ch in ipairs(d:GetDescendants()) do
                if ch:IsA("TextLabel") then t = t .. " " .. ch.Text:lower() end
            end
            for _, w in ipairs(words) do
                if t:find(w, 1, true) then
                    for _, sig in ipairs({d.Activated, d.MouseButton1Click, d.MouseButton1Down}) do
                        pcall(function()
                            for _, cn in ipairs(getconnections(sig)) do cn:Fire() end
                        end)
                    end
                    return true
                end
            end
        end
    end
    return false
end

-- 能力(ナイフの特殊攻撃 = PCの右クリック)
local ABILITY_WORDS = {"ability", "heavy", "skill", "能力"}
local okV, VIM = pcall(function() return game:GetService("VirtualInputManager") end)
if not okV then VIM = nil end

-- 右クリックを押す/離す。方式: 偽装(ゲームの入力処理を直接呼ぶ) / マウス(本物の入力を送る)
-- 押している間は、ゲームが「右クリック中か」を調べたときも「押している」と答える(フック)
local function rmbSet(down)
    if S.abilityMode ~= "マウスのみ" then pcall(fakeButton, Enum.UserInputType.MouseButton2, down) end
    if S.abilityMode ~= "偽装のみ" and VIM then
        pcall(function()
            local vs = workspace.CurrentCamera.ViewportSize
            VIM:SendMouseButtonEvent(vs.X / 2, vs.Y / 2, 1, down, game, 0)
        end)
    end
    env.RL_RMB = down
end

-- 能力のテスト(3秒後に右クリックを1回押す。ナイフを持って、敵の近くで試す)
local function testRMB()
    say("3秒後に右クリックを送ります…")
    task.delay(3, function()
        rmbSet(true)
        task.wait(S.abilityHold)
        rmbSet(false)
        say("右クリックを送りました (" .. S.abilityMode .. ")")
    end)
end

local function equipKnife(char, hum)
    if tick() - K.lastEquip < 1 then return end
    if weaponOf(lp, char):lower():find("knife", 1, true) then return end
    K.lastEquip = tick()
    local bp = lp:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("knife", 1, true) then
                pcall(function() hum:EquipTool(t) end)
                return
            end
        end
    end
    pcall(pressWords, {"knife", "ナイフ"})
end

-- 今見えているボタンの名前を一覧にする(能力ボタンの名前を調べる用)
local function listButtons()
    local lines = {}
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("GuiButton") and not ourGui(d) and d.AbsoluteSize.X > 0 then
            local t = d:IsA("TextButton") and d.Text or ""
            for _, ch in ipairs(d:GetDescendants()) do
                if ch:IsA("TextLabel") and ch.Text ~= "" then t = t .. " " .. ch.Text end
            end
            table.insert(lines, d.Name .. (t ~= "" and (" [" .. t .. "]") or ""))
            if #lines >= 40 then break end
        end
    end
    local out = #lines > 0 and table.concat(lines, "\n") or "見えているボタンなし"
    say(out)
    if setclipboard then pcall(setclipboard, out) end
end

-- 刺している間は、物理計算の直前(Stepped)にも位置を合わせ直す(サーバーに届く位置を安定させる)
track(RunService.Stepped:Connect(function()
    if not (S.rage and S.knife and K.state == "strike" and K.enemy) then return end
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local er = K.enemy:FindFirstChild("HumanoidRootPart")
    if root and er then pcall(applyStrike, root, er) end
end))

track(RunService.Heartbeat:Connect(function()
    if not (S.rage and S.knife) or S.cheater then
        if K.rmbDown then pcall(rmbSet, false) K.rmbDown = false end
        env.RL_RMB = false
        ST.knifeFar = false
        K.state, K.t, K.enemy, K.far, K.base = "wait", tick(), nil, nil, nil
        return
    end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    K.base = K.base or root.Position   -- 「マップから離れる」基準(ナイフモードを始めた場所)
    ST.knifeFar = K.far ~= nil and K.state ~= "strike"
    ST.lastSet = nil
    equipKnife(char, hum)

    if K.state == "wait" then
        if K.far then
            place(root, K.far)
        elseif S.knifeSpin then
            place(root, root.Position)
        end
        if tick() - K.t >= S.knifeWait then
            local e = RL.closest()
            if e and e:FindFirstChild("HumanoidRootPart") then
                local eh0 = e:FindFirstChildOfClass("Humanoid")
                K.enemy, K.pressed, K.hp0 = e, false, eh0 and eh0.Health
                K.rmbDown, K.rmbDone = false, false
                if S.knifeAbility and S.abilityLead > 0 then
                    -- 移動の「abilityLead」秒前に、先に能力(右クリック)を押し始める
                    K.state, K.t = "prep", tick()
                    K.rmbDown, K.rmbT = true, tick()
                    pcall(pressWords, ABILITY_WORDS)
                    rmbSet(true)
                else
                    K.state, K.t = "strike", tick()
                end
            end
        end
    elseif K.state == "prep" then
        -- 能力を先に押したまま、今の場所(遠い待機場所)で待つ。時間が来たら背後へ移動
        if K.far then
            place(root, K.far)
        elseif S.knifeSpin then
            place(root, root.Position)
        end
        local e = K.enemy
        local er = e and e:FindFirstChild("HumanoidRootPart")
        local eh = e and e:FindFirstChildOfClass("Humanoid")
        if not er or not eh or eh.Health <= 0 then
            if K.rmbDown then rmbSet(false) K.rmbDown = false end
            K.state, K.t, K.enemy = "wait", tick(), nil
        elseif tick() - K.t >= S.abilityLead then
            K.state, K.t = "strike", tick()
        end
    else
        local e = K.enemy
        local er = e and e:FindFirstChild("HumanoidRootPart")
        local eh = e and e:FindFirstChildOfClass("Humanoid")
        -- 能力を使うときは、押す・離すが終わるまで背後にいる時間を延ばす
        local lead = (S.knifeAbility and S.abilityLead > 0) and S.abilityLead or 0
        local stay = S.knifeStay
        if S.knifeAbility then
            stay = math.max(stay, (lead > 0 and 0 or S.abilityDelay) + S.abilityHold + 0.03)
        end
        if not er or not eh or eh.Health <= 0 or tick() - K.t > stay then
            if K.rmbDown then rmbSet(false) K.rmbDown = false end   -- 離し忘れ防止
            -- 命中したかを0.4秒後に確かめて、状態欄に出す(設定を調整するときの目安)
            if e and eh then
                local hp0 = K.hp0
                task.delay(0.4, function()
                    local h2 = e:FindFirstChildOfClass("Humanoid")
                    local hit = (not h2) or h2.Health <= 0 or (hp0 ~= nil and h2.Health < hp0)
                    K.tries += 1
                    if hit then K.hits += 1 end
                    say(string.format("ナイフ: 命中 %d / %d", K.hits, K.tries))
                end)
            end
            K.far = farPoint(K.base)
            K.state, K.t, K.enemy = "wait", tick(), nil
            place(root, K.far)
        else
            applyStrike(root, er)
            if S.knifeAbility then
                local el = tick() - K.t
                if not K.rmbDown and not K.rmbDone and el >= S.abilityDelay then
                    K.rmbDown, K.rmbT = true, tick()
                    pcall(pressWords, ABILITY_WORDS)   -- 画面に能力ボタンがあれば、それも押す
                    rmbSet(true)
                end
                if K.rmbDown and tick() - K.rmbT >= lead + S.abilityHold then
                    rmbSet(false)
                    K.rmbDown, K.rmbDone = false, true
                end
            end
            -- 能力の最中は通常攻撃を止める(能力が上書きされないように)
            if not S.knifeAbility or K.rmbDone then tryAttack(char) end
        end
    end
end))

-- 描画の直前: 刺す間は敵の方へ視点を向ける(設定による) / それ以外は360°ランダムに振る
-- (視点操作の「飛行」「フリー」がONなら、画面は自由視点のままで、ゲームから見た向きだけが変わる)
RunService:BindToRenderStep("RL_Knife", 1001, function()
    if not (S.rage and S.knife) then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        local striking = K.state == "strike" and K.enemy
        if striking and S.knifeFace == "攻撃時だけ向く" then
            local er = K.enemy:FindFirstChild("HumanoidRootPart")
            if er then cam.CFrame = CFrame.lookAt(cam.CFrame.Position, er.Position) end
        elseif S.knifeSpin then
            cam.CFrame = CFrame.new(cam.CFrame.Position) * randRot()
        end
        if striking and lp.Character and (not S.knifeAbility or K.rmbDone) then tryAttack(lp.Character) end
    end)
end)

------------------------------------------------------------ レイジボット補助(追従・遠方帰還・近接の先行攻撃・体の飛行・エモート)
local FC = RL.FC

-- 自分の「基準の位置」: 遠方で待機しているとき以外の、一番新しい位置(同じ試合の判定に使う)
local refPos
track(RunService.Heartbeat:Connect(function()
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if root and not ST.farHold and not ST.knifeFar then refPos = root.Position end
    ST.ref = refPos
end))

-- 敵を倒したあと、遠方(座標500000など)で待機する。敵が出たら攻撃へ、RAGEがOFFなら元の場所へ戻る
track(RunService.Heartbeat:Connect(function()
    local pt = ST.farHold
    if not pt then return end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then ST.farHold = nil return end
    if ST.lastSet then ST.farHold = nil return end   -- 敵の足元へ移動した
    if S.rage and not ST.attacking then
        root.CFrame = CFrame.new(pt)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    else
        ST.farHold = nil
        if not S.rage then
            local home = RL.getHome and RL.getHome()
            if home then
                root.CFrame = CFrame.new(home)
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end))

-- 敵の真下にずっといる: 物理計算の直前(Stepped)にも、敵の最新位置(先読み込み)へ合わせ直す
track(RunService.Stepped:Connect(function()
    if not (S.rage and S.tp) or S.knife or not ST.attacking then return end
    if not (RL.getTarget and RL.placeUnder) then return end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local enemyChar = RL.getTarget()
    if not root or not enemyChar or not enemyChar:FindFirstChild("HumanoidRootPart") then return end
    pcall(function()
        local look = enemyChar:FindFirstChild("UpperTorso") or enemyChar.HumanoidRootPart
        RL.placeUnder(root, enemyChar, look.Position)
    end)
end))

-- 近接武器(チェンソーなど)は、レイジボットが待機している間も攻撃アニメを出し続ける
local MELEE = {"chainsaw", "knife", "katana", "scythe", "battle axe", "battleaxe", "maul", "spear",
    "fists", "trowel", "riot shield", "glast shard"}
local function isMelee(tool)
    local n = tool.Name:lower()
    for _, w in ipairs(MELEE) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

local lastPre = 0
track(RunService.Heartbeat:Connect(function()
    if not S.meleePre or S.knife or not (S.rage or S.auto) then return end
    if ST.attacking then return end   -- 敵がいるときは、通常のレイジボットが攻撃する
    local char = lp.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool or not isMelee(tool) then return end
    if tick() - lastPre < 0.12 then return end
    lastPre = tick()
    pcall(function() tool:Activate() end)
    if S.fakeInput then
        pcall(fakeButton, Enum.UserInputType.MouseButton1, true)
        pcall(fakeButton, Enum.UserInputType.MouseButton1, false)
    end
end))

-- 体で飛ぶ(スティックでカメラの向きへ、▲▼ボタンで上下)
local ctrl, flyOn = nil, false
local function moveVec()
    if not ctrl then
        pcall(function()
            local ps = lp:FindFirstChild("PlayerScripts")
            local pm = ps and ps:FindFirstChild("PlayerModule")
            if pm then ctrl = require(pm):GetControls() end
        end)
    end
    if ctrl then
        local ok, v = pcall(function() return ctrl:GetMoveVector() end)
        if ok and typeof(v) == "Vector3" then return v end
    end
    return Vector3.zero
end

track(RunService.Stepped:Connect(function()
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if S.bodyFly and not ST.attacking and not S.knife and not ST.farHold and not S.cheater then
        flyOn = true
        hum.PlatformStand = true
        local cf = workspace.CurrentCamera.CFrame
        local mv = moveVec()
        local dir = cf.RightVector * mv.X + cf.LookVector * (-mv.Z)
        if FC.up then dir += Vector3.new(0, 1, 0) end
        if FC.down then dir -= Vector3.new(0, 1, 0) end
        if dir.Magnitude > 1 then dir = dir.Unit end
        root.AssemblyLinearVelocity = dir * S.flySpeed
        root.AssemblyAngularVelocity = Vector3.zero
        local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if flat.Magnitude > 0.01 then
            root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
        end
    elseif flyOn then
        flyOn = false
        if not S.rage then hum.PlatformStand = false end
    end
end))

-- エモート(体の形式R6/R15に合わせる / ロビーに表示されている自分のモデルにも再生 / 移動・飛行でも止まらない)
local emoteIds, emoteNames = {}, {}   -- ゲーム自身が持っているエモート
pcall(function()
    for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if d:IsA("Animation") and d.AnimationId ~= "" and #emoteIds < 80 then
            local full = d:GetFullName():lower()
            if full:find("emote", 1, true) or full:find("dance", 1, true)
                or full:find("inmu", 1, true) or full:find("king", 1, true) then
                table.insert(emoteIds, d.AnimationId)
                table.insert(emoteNames, string.format("%d %s", #emoteIds, d.Name))
            end
        end
    end
end)
if #emoteNames == 0 then emoteNames = {"(見つからない)"} end
if S.emoteSel == nil then S.emoteSel = emoteNames[1] end

-- {名前, ID, R6用のID}。R6用のIDがあるものは「標準のエモート」、ないものはカタログのエモート(R15専用)
-- IDはRobloxの開発者フォーラムの一覧と、Robloxの標準のアニメから
local EMOTES = {
    {"Broke", "101672274288790"},
    {"Tornado", "82995540773684"},
    {"Yokoyure Step", "98233060516583"},
    {"Invisible", "110348711077449"},
    {"Original Gangnam Style", "116468071022853"},
    {"HOT Spinning Cat", "75739251269771"},
    {"Good Boy Dog", "100737291015384"},
    {"Tall Giant", "126672040102655"},
    {"Mega Poop", "94631974697172"},
    {"Wave", "507770239", "128777973"},
    {"Point", "507770453", "128853357"},
    {"Dance", "507771019", "182435998"},
    {"Dance 2", "507776043", "182491037"},
    {"Dance 3", "507777268", "182491065"},
    {"Laugh", "507770818", "129423131"},
    {"Cheer", "507770677", "129423030"},
    {"Floss Dance", "5917570207"},
    {"Zombie", "4212496830"},
    {"Robot", "3576721660"},
    {"Dolphin Dance", "5938365243"},
    {"Monkey", "3716636630"},
    {"Dorky Dance", "4212499637"},
    {"Tantrum", "5104374556"},
    {"Dizzy", "3934986896"},
    {"Godlike", "3823158750"},
    {"Hero Landing", "5104377791"},
    {"Swan Dance", "7466048475"},
    {"Old Town Road", "5938394742"},
    {"Panini Dance", "5915781665"},
    {"Break Dance", "5915773992"},
    {"Top Rock", "3570535774"},
    {"Cha Cha", "6865013133"},
    {"Samba", "6869813008"},
    {"Line Dance", "4049646104"},
    {"Twirl", "3716633898"},
    {"Side to Side", "3762641826"},
    {"Power Blast", "4849497510"},
    {"Shuffle", "4391208058"},
    {"Rock On", "5915782672"},
    {"Fancy Feet", "3934988903"},
    {"Get Out", "3934984583"},
    {"Fishing", "3994129128"},
    {"Bodybuilder", "3994130516"},
    {"Jacks", "3570649048"},
    {"Louder", "3576751796"},
    {"Sneaky", "3576754235"},
    {"Swish", "3821527813"},
    {"Greatest", "3762654854"},
    {"Idol", "4102317848"},
    {"Cower", "4940597758"},
    {"Confused", "4940592718"},
    {"Beckon", "5230615437"},
    {"Baby Dance", "4272484885"},
    {"Block Partier", "6865011755"},
    {"Air Dance", "4646302011"},
    {"Tree", "4049634387"},
    {"Skibidi Laser Spin", "103102322875221"},
    {"Shrek Roar", "18524331128"},
    {"Mini Kong", "17000058939"},
    {"NBA Monster Dunk", "117511481049460"},
    {"The Zabb", "71389516735424"},
    {"SpongeBob Imagination", "18443268949"},
    {"TMNT Dance", "18665886405"},
    {"Wanna Play", "16646438742"},
    {"Super Charge", "10478368365"},
    {"Boxing Punch", "7202896732"},
    {"Show Dem Wrists", "7202898984"},
    {"Wake Up Call", "7202900159"},
    {"Sturdy Dance", "17746270218"},
    {"Mean Girls Dance", "15963348695"},
    {"Breaking", "18526338976"},
    {"d4vd Backflip", "15694504637"},
    {"Cartwheel", "10370929905"},
    {"Air Guitar Slide", "14353417553"},
    {"Rolling Stones Guitar", "18148839527"},
    {"Piano Hands", "16553249658"},
    {"Yungblud High Kick", "14022978026"},
    {"Bones Dance", "15689314578"},
    {"GloRilla Dance", "15689315657"},
    {"Fashion Roadkill", "73683655527605"},
}


local emoteTracks, emoteSpec, emoteChar, emoteGen = {}, nil, nil, 0
local emoteSet = setmetatable({}, {__mode = "k"})
if S.emoteMethod == nil then S.emoteMethod = "自動" end

local function stopEmote()
    emoteGen += 1
    for _, e in ipairs(emoteTracks) do pcall(function() e.tr:Stop(0.1) end) end
    emoteTracks, emoteSpec = {}, nil
    say("エモートを止めました")
end

-- 自分の体のアニメーター一覧: 本体 + ロビーなどに表示されている自分のモデル(名前が同じ)
local function myAnimators()
    local list, seen = {}, {}
    local function add(model)
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum or seen[model] then return end
        seen[model] = true
        local an = hum:FindFirstChildOfClass("Animator")
        if not an then
            an = Instance.new("Animator")
            an.Parent = hum
        end
        table.insert(list, {model = model, hum = hum, an = an})
    end
    if lp.Character then add(lp.Character) end
    local nm, dn = lp.Name:lower(), lp.DisplayName:lower()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Humanoid") then
            local m = d.Parent
            if m and m ~= lp.Character then
                local mn = m.Name:lower()
                if mn == nm or mn == dn then add(m) end
            end
        end
    end
    return list
end

local function rigName(hum)
    return hum.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"
end

local KSP = game:GetService("KeyframeSequenceProvider")

-- アニメを読み込む。方式は「エモート方式」で選べる(自動なら次の順に全部試す)
--   標準のエモート: IDで直接 → 標準API → アセット登録 → (IDで直接)
--   カタログのエモート: 標準API(Humanoid:PlayEmoteAndGetAnimTrackById) → アセット登録 → IDで直接
-- 失敗した理由は log に残して、状態欄に出す
local function loadFor(t, spec)
    local hum, an = t.hum, t.an
    local log = {}
    local method = S.emoteMethod or "自動"
    local function allow(name) return method == "自動" or method == name end

    local function ready(tr)
        local t0 = tick()
        while tr.Length == 0 and tick() - t0 < 1.5 do task.wait() end
        return tr.Length > 0
    end
    local function try(label, fn)
        local ok, tr = pcall(fn)
        if not ok then
            table.insert(log, label .. ": エラー " .. tostring(tr):sub(1, 70))
            return nil
        end
        if not tr then
            table.insert(log, label .. ": 失敗")
            return nil
        end
        if not ready(tr) then
            table.insert(log, label .. ": 長さ0(読み込めず)")
            pcall(function() tr:Stop(0) end)
            return nil
        end
        return tr
    end
    local function byId(label, rbx)
        return try(label, function()
            local a = Instance.new("Animation")
            a.AnimationId = rbx
            return an:LoadAnimation(a)
        end)
    end
    -- アセットの中身を取り出して、このクライアントだけで使えるアニメとして登録する(権限のないアニメも読める)
    local function byAsset(label, id)
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
        if not ok or not objs then
            table.insert(log, label .. ": GetObjects失敗")
            return nil
        end
        for _, o in ipairs(objs) do
            local seq = (o:IsA("KeyframeSequence") and o) or o:FindFirstChildWhichIsA("KeyframeSequence", true)
            if seq then
                local tr = try(label .. "(登録)", function()
                    local hash = KSP:RegisterKeyframeSequence(seq)
                    local a = Instance.new("Animation")
                    a.AnimationId = hash
                    return an:LoadAnimation(a)
                end)
                if tr then return tr end
            end
            local inner = (o:IsA("Animation") and o) or o:FindFirstChildWhichIsA("Animation", true)
            if inner then
                local tr = try(label .. "(中のAnimation)", function() return an:LoadAnimation(inner) end)
                if tr then return tr end
            end
        end
        table.insert(log, label .. ": 中身にアニメが無い")
        return nil
    end

    if spec.raw then
        local tr = byId("直接", spec.raw)
        return tr, (not tr) and "読み込めませんでした" or nil, log
    end

    local id = spec.id
    local r6 = hum.RigType == Enum.HumanoidRigType.R6
    if r6 then
        if not spec.r6 then return nil, "R6の体では使えません(R15専用のエモート)", log end
        id = spec.r6
    end
    local std = spec.r6 ~= nil
    local rbx = "rbxassetid://" .. id

    local tr
    if std and allow("直接") then tr = byId("直接", rbx) end
    if not tr and not r6 and allow("標準API") then
        tr = try("標準API", function()
            local ok, a, b = pcall(function() return hum:PlayEmoteAndGetAnimTrackById(tonumber(id)) end)
            if ok and a then return b end
            error(ok and "対応していない/使えないエモート" or tostring(a))
        end)
    end
    if not tr and allow("アセット登録") then tr = byAsset("アセット", id) end
    if not tr and not std and allow("直接") then tr = byId("直接", rbx) end
    return tr, (not tr) and "読み込めませんでした" or nil, log
end

local function startEmote(e)
    local spec = (e.raw or e.name) and e or {name = e[1], id = e[2], r6 = e[3]}
    stopEmote()
    emoteSpec = spec
    emoteChar = lp.Character
    local gen = emoteGen
    task.spawn(function()
        say("読み込み中: " .. spec.name)
        local n, lastErr, rigs, allLog = 0, nil, {}, {}
        for _, t in ipairs(myAnimators()) do
            local tr, err, lg = loadFor(t, spec)
            if lg then
                for _, l in ipairs(lg) do table.insert(allLog, rigName(t.hum) .. " " .. l) end
            end
            if gen ~= emoteGen then
                if tr then pcall(function() tr:Stop(0) end) end
                return
            end
            if tr then
                tr.Priority = Enum.AnimationPriority.Action4
                tr.Looped = true
                tr:AdjustWeight(1, 0)
                if not tr.IsPlaying then tr:Play(0.1) end
                emoteSet[tr] = true
                table.insert(emoteTracks, {tr = tr, t = t})
                n += 1
                table.insert(rigs, rigName(t.hum))
            else
                lastErr = err
            end
        end
        if n == 0 then
            emoteSpec = nil
            local msg = spec.name .. ": " .. tostring(lastErr or "自分の体が見つかりません")
            if #allLog > 0 then msg = msg .. "\n" .. table.concat(allLog, "\n") end
            say(msg)
            if setclipboard then pcall(setclipboard, msg) end
        else
            say(string.format("エモート: %s (%s / %d体)", spec.name, table.concat(rigs, ","), n))
        end
    end)
end

-- 移動・ジャンプ・飛行でも止まらないように、止められたら毎フレーム再生し直す。リスポーンしたら読み込み直す
local respawnWait = 0
track(RunService.Heartbeat:Connect(function()
    if not emoteSpec or #emoteTracks == 0 then return end
    local ch = lp.Character
    if ch ~= emoteChar then
        if ch and tick() - respawnWait > 1 then
            respawnWait = tick()
            local spec = emoteSpec
            task.delay(0.8, function()
                if emoteSpec == spec then startEmote(spec) end
            end)
        end
        return
    end
    for _, e in ipairs(emoteTracks) do
        local tr = e.tr
        if tr then
            pcall(function()
                if not tr.IsPlaying then tr:Play(0.1) end
                if tr.WeightCurrent < 0.99 then tr:AdjustWeight(1, 0) end
                if tr.Priority ~= Enum.AnimationPriority.Action4 then tr.Priority = Enum.AnimationPriority.Action4 end
            end)
        end
    end
end))

-- ゲームが持っているエモートを再生(体の形式は最初から合っている)
local function playEmote()
    local idx
    for i, n in ipairs(emoteNames) do if n == S.emoteSel then idx = i end end
    local id = idx and emoteIds[idx]
    if not id then say("ゲームのエモートが見つかりません") return end
    startEmote({name = tostring(S.emoteSel), raw = id})
end

-- 名前に inmu を含むプレイヤーが再生中のエモートをコピー
local function copyInmu()
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and (p.Name .. " " .. p.DisplayName):lower():find("inmu", 1, true) then
            target = p
            break
        end
    end
    if not target or not target.Character then say("INMUという名前のプレイヤーがいません") return end
    local hum = target.Character:FindFirstChildOfClass("Humanoid")
    local an = hum and hum:FindFirstChildOfClass("Animator")
    if not an then say("相手のアニメーターが見つかりません") return end
    for _, tk in ipairs(an:GetPlayingAnimationTracks()) do
        local a = tk.Animation
        local pv = tk.Priority.Value
        if a and a.AnimationId ~= "" and pv >= 2 and pv < 1000 then
            startEmote({name = "INMUのエモート", raw = a.AnimationId})
            return
        end
    end
    say("INMUは今、エモートを再生していません")
end

-- 体の形式の調査(R6かR15か、必要な部品があるか、ロビーに自分のモデルがあるか)
local function rigReport()
    local lines = {}
    for _, t in ipairs(myAnimators()) do
        local m = t.model
        local motors = 0
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("Motor6D") then motors += 1 end
        end
        table.insert(lines, string.format("%s: %s / UpperTorso=%s Torso=%s / Motor6D=%d / %s",
            m:GetFullName(), rigName(t.hum), tostring(m:FindFirstChild("UpperTorso") ~= nil),
            tostring(m:FindFirstChild("Torso") ~= nil), motors,
            (m == lp.Character) and "本体" or "表示用のモデル"))
    end
    if #lines == 0 then lines = {"自分の体が見つかりません"} end
    table.insert(lines, "ゲームのエモート: " .. (#emoteIds) .. "個")
    local out = table.concat(lines, "\n")
    say(out)
    if setclipboard then pcall(setclipboard, out) end
end


------------------------------------------------------------ チーターモード(視点ブンブン + 超高速で奈落を移動 → OFFで元の場所へ戻る)
pcall(function() RunService:UnbindFromRenderStep("RL_Cheat") end)
local CH = {origin = nil, pos = nil, dir = nil, t = 0, char = nil}
local CH_RANGE = 1000000   -- 原点からこれ以上離れない(これより遠いと、座標の精度が落ちて不安定になる)

-- 移動する高さ。「奈落」はマップの下(落下で消える高さの少し上)、「上空」はマップの上
local function chHeight(origin)
    if S.cheaterH == "上空" then return origin.Y + 3000 end
    local fp = workspace.FallenPartsDestroyHeight
    return math.max(fp + 80, origin.Y - 3000)
end

local function chStart()
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        S.cheater = false
        if R.cheater then R.cheater() end
        say("キャラがいません")
        return
    end
    if S.rage then RL.setRage(false) end   -- レイジボットと同時には動かさない
    CH.origin, CH.pos, CH.dir, CH.t, CH.char = root.Position, nil, nil, 0, lp.Character
    say("チーターモードON")
end

local function chStop()
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root and CH.origin then
        root.CFrame = CFrame.new(CH.origin + Vector3.new(0, 3, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if hum and not S.bodyFly then hum.PlatformStand = false end
    CH.pos, CH.dir = nil, nil
    say("チーターモードOFF → 元の場所へ戻りました")
end

track(RunService.Heartbeat:Connect(function(dt)
    if not S.cheater then return end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    -- リスポーンしたら、その場所を新しい「元の場所」にして続ける
    if CH.char ~= char then
        CH.char, CH.origin, CH.pos, CH.dir = char, root.Position, nil, nil
    end
    CH.pos = CH.pos or root.Position

    -- 0.5〜1.5秒ごとに、ランダムな向きへ(原点から離れすぎていたら、原点のほうへ)
    CH.t -= dt
    if not CH.dir or CH.t <= 0 then
        CH.t = 0.5 + math.random()
        local d = Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1)
        if d.Magnitude < 0.1 then d = Vector3.new(1, 0, 0) end
        local off = Vector3.new(CH.pos.X - CH.origin.X, 0, CH.pos.Z - CH.origin.Z)
        if off.Magnitude > CH_RANGE then
            d = (-off).Unit + d.Unit * 0.3
        end
        CH.dir = d.Unit
    end

    local y = chHeight(CH.origin)
    CH.pos = Vector3.new(CH.pos.X, y, CH.pos.Z) + CH.dir * (S.cheaterSpeed * dt)
    hum.PlatformStand = true
    root.CFrame = CFrame.new(CH.pos) * (S.cheaterSpin and randRot() or CFrame.new())
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end))

-- 視点ブンブン: 描画の直前に、視点を360°ランダムな向きにする(視点操作の「飛行」「フリー」がONなら、画面は自由視点のまま)
RunService:BindToRenderStep("RL_Cheat", 1002, function()
    if not (S.cheater and S.cheaterSpin) then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        cam.CFrame = CFrame.new(cam.CFrame.Position) * randRot()
    end)
end)

------------------------------------------------------------ エイムボット: 体の向きの合わせ直し
-- ゲームが体の向きを上書きしても置いていかれないように、物理計算の前(Stepped)と後(Heartbeat)にも合わせる
local function applyAimFace()
    local f = ST.aimFace
    if not f or tick() - (ST.aimFaceT or 0) > 0.1 or S.cheater then return end
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return end
    if hum then hum.AutoRotate = false end
    root.CFrame = CFrame.lookAt(root.Position, root.Position + f)
end
track(RunService.Stepped:Connect(applyAimFace))
track(RunService.Heartbeat:Connect(applyAimFace))

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
        if pv >= 2 and pv < 1000 and not emoteSet[t] then pcall(function() t:Stop(0) end) end
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
RL.addToggle("ランク表示", "espRank")
RL.addToggle("FOV円", "fovCircle")
RL.addToggle("エイムボット", "aim")
RL.addCycle("エイム条件", {"常に", "スコープ中のみ"}, "aimWhen", function(v) return v end)
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
RL.addCycle("反射検知", {"検知", "アニメ", "刀持ち全員"}, "reflectMode", function(v) return v end)
RL.addToggle("ナイフモード", "knife")
RL.addCycle("ナイフ後方", {0, 2, 3, 4, 6, 8, 10, 12}, "knifeBack", function(v) return v .. "st" end)
RL.addCycle("ナイフ地下", {0, 2, 4, 6, 8, 10, 12}, "knifeDown", function(v) return v .. "st" end)
RL.addCycle("ナイフ向き", {"攻撃時だけ向く", "向かない"}, "knifeFace", function(v) return v end)
RL.addToggle("ナイフ予測", "knifePredict")
RL.addCycle("ナイフ滞在", {0.05, 0.1, 0.2, 0.3}, "knifeStay", function(v) return v .. "秒" end)
RL.addCycle("ナイフ待機", {1, 2, 3, 5}, "knifeWait", function(v) return v .. "秒" end)
RL.addCycle("ナイフ帰還距離", {1000, 5000, 20000, 50000}, "knifeFar", function(v) return v .. "st" end)
RL.addToggle("入力偽装攻撃", "fakeInput")
RL.addToggle("視点ブンブン", "knifeSpin")
RL.addToggle("背中で能力ボタン", "knifeAbility")
RL.addCycle("能力入力", {"両方", "偽装のみ", "マウスのみ"}, "abilityMode", function(v) return v end)
RL.addCycle("能力先押し", {0, 0.05, 0.1, 0.2, 0.3}, "abilityLead", function(v) return v .. "秒前" end)
RL.addCycle("能力タイミング", {0, 0.02, 0.05, 0.1}, "abilityDelay", function(v) return v .. "秒" end)
RL.addCycle("能力長押し", {0.03, 0.05, 0.1, 0.2}, "abilityHold", function(v) return v .. "秒" end)
RL.addToggle("無限ジャンプ", "infJump")
RL.addToggle("アニメ高速", "animFast")
RL.addCycle("連射回数", {1, 2, 3}, "fireN", function(v) return v .. "回" end)
RL.addToggle("他人のアニメ停止", "lagAnim")
RL.addToggle("自分のアニメ停止", "lagSelf")
RL.addToggle("エフェクト削除", "lagFx", function(on) if on then sweep() end end)
RL.addToggle("弾の描画を消す", "lagBullet", function(on) if on then sweep() end end)
RL.addToggle("ヒット演出を消す", "lagHit", function(on) if on then sweep() end end)
RL.addAction("ラグ調査", lagReport)
RL.addAction("敵情報調査", dumpEnemy)
RL.addAction("スコープ調査", scopeReport)
RL.addAction("ボタン一覧", listButtons)
RL.addAction("右クリックテスト", testRMB)
RL.addToggle("チーターモード", "cheater", function(on) if on then chStart() else chStop() end end)
RL.addCycle("チーター速度", {50000, 100000, 500000, 1000000}, "cheaterSpeed", function(v) return v .. "st/秒" end)
RL.addCycle("チーター高さ", {"奈落", "上空"}, "cheaterH", function(v) return v end)
RL.addToggle("チーター視点ブンブン", "cheaterSpin")
RL.addToggle("遠方帰還", "farHome")
RL.addCycle("遠方の座標", {100000, 500000, 1000000}, "farHomeDist", function(v) return tostring(v) end)
RL.addToggle("追従予測", "followPredict")
RL.addToggle("近接の先行攻撃", "meleePre")
RL.addToggle("体で飛ぶ", "bodyFly")
RL.addCycle("体の飛行速度", {30, 60, 120, 250}, "flySpeed", function(v) return tostring(v) end)
RL.addAction("エモート停止", stopEmote)
RL.addCycle("エモート方式", {"自動", "標準API", "アセット登録", "直接"}, "emoteMethod", function(v) return v end)
RL.addAction("体の形式調査", rigReport)
RL.addAction("INMUのエモートをコピー", copyInmu)
RL.addCycle("ゲームのエモート", emoteNames, "emoteSel", function(v) return v end)
RL.addAction("ゲームのエモート再生", playEmote)
for _, e in ipairs(EMOTES) do
    RL.addAction(e[1], function() startEmote(e) end)
end
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
