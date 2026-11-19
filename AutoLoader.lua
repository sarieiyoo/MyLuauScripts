--[[
  AutoLoader (単独で動く、新しいスクリプト)
  1回実行すると:
   1. 下のURLのスクリプトを読み込む
   2. 別のサーバーへ移動しても、自動でもう一度読み込む(移動のたびに、ずっと繰り返す)

  止める:   writefile("AutoLoader_off", "1")
  再開する: このスクリプトをもう一度実行する(止めるフラグも消えます)
]]

local URL = "https://api.polsec.net/loader/f1741ef3a2610ac7/78c2720d864f3b30"
local BOOT_FILE = "AutoLoader_boot.lua"
local OFF_FILE = "AutoLoader_off"

local Players = game:GetService("Players")
local env = (getgenv and getgenv()) or _G
local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)

local function toast(text)
    pcall(function()
        local g = Instance.new("ScreenGui")
        g.ResetOnSpawn = false
        g.DisplayOrder = 1000
        g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        local t = Instance.new("TextLabel")
        t.Size = UDim2.fromOffset(320, 50)
        t.Position = UDim2.new(0.5, -160, 0, 70)
        t.BackgroundColor3 = Color3.new(0, 0, 0)
        t.BackgroundTransparency = 0.25
        t.TextColor3 = Color3.new(1, 1, 1)
        t.TextSize = 14
        t.TextWrapped = true
        t.Text = text
        t.Parent = g
        task.delay(4, function() g:Destroy() end)
    end)
end

-- サーバーを移動するたびに実行される、起動用のコード(ファイルに保存して、移動のたびに読む)
local BOOT = [==[
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(2)

local URL = "__URL__"
local env = (getgenv and getgenv()) or _G

local function toast(text)
    pcall(function()
        local g = Instance.new("ScreenGui")
        g.ResetOnSpawn = false
        g.DisplayOrder = 1000
        g.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local t = Instance.new("TextLabel")
        t.Size = UDim2.fromOffset(320, 50)
        t.Position = UDim2.new(0.5, -160, 0, 70)
        t.BackgroundColor3 = Color3.new(0, 0, 0)
        t.BackgroundTransparency = 0.25
        t.TextColor3 = Color3.new(1, 1, 1)
        t.TextSize = 14
        t.TextWrapped = true
        t.Text = text
        t.Parent = g
        task.delay(4, function() g:Destroy() end)
    end)
end

-- 止めるフラグがあれば、何もしない(次の予約もしない)
if isfile and isfile("AutoLoader_off") then return end

-- 次の移動のために、もう一度予約する(同じサーバーで二重に予約しない)
local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if q and env.AL_QUEUED_JOB ~= game.JobId then
    env.AL_QUEUED_JOB = game.JobId
    q('loadstring(readfile("AutoLoader_boot.lua"))()')
end

-- 同じサーバーでは、1回だけ読み込む
if env.AL_LOADED_JOB == game.JobId then
    toast("自動読み込み: このサーバーでは、もう読み込み済みです")
    return
end
env.AL_LOADED_JOB = game.JobId

-- ダウンロード(通信の失敗だけ、3回までやり直す)
local src, getErr
for i = 1, 3 do
    local ok, res = pcall(function() return game:HttpGet(URL, true) end)
    if ok and type(res) == "string" and #res > 0 then src = res break end
    getErr = res
    task.wait(2)
end
if not src then
    env.AL_LOADED_JOB = nil
    toast("自動読み込み: ダウンロードに失敗 " .. tostring(getErr):sub(1, 80))
    return
end

local f, compileErr = loadstring(src)
if not f then
    toast("自動読み込み: 読み込みエラー " .. tostring(compileErr):sub(1, 80))
    return
end

-- 実行は1回だけ(途中でエラーになっても、やり直さない。二重に実行されるのを防ぐため)
local ok, runErr = pcall(f)
if ok then
    toast("自動読み込み: スクリプトを読み込みました")
else
    toast("自動読み込み: 実行中にエラー " .. tostring(runErr):sub(1, 80))
end
]==]

local bootCode = (BOOT:gsub("__URL__", function() return URL end))

-- 止めるフラグが残っていたら消す(もう一度実行した = 再開したい、ということ)
if isfile and delfile then
    pcall(function() if isfile(OFF_FILE) then delfile(OFF_FILE) end end)
end

local saved = false
if writefile then
    saved = pcall(function() writefile(BOOT_FILE, bootCode) end)
end

if not saved then
    -- ファイルに保存できないとき: 次の1回の移動だけ読み込む(繰り返しはできない)
    if q then
        pcall(q, 'loadstring(game:HttpGet("' .. URL .. '", true))()')
        toast("AutoLoader: 保存できませんでした。次の移動の1回だけ読み込みます")
    else
        toast("AutoLoader: 保存も予約もできません。今回だけ読み込みます")
    end
elseif not q then
    toast("AutoLoader: queue_on_teleport が使えません。今回だけ読み込みます")
else
    toast("AutoLoader: 設定しました(サーバーを移動しても、自動で読み込みます)")
end

-- 今すぐ読み込む(起動用のコードと同じものを、そのまま実行する)
local runNow, err = loadstring(bootCode)
if runNow then
    task.spawn(runNow)
else
    toast("AutoLoader: 読み込みエラー " .. tostring(err):sub(1, 80))
end
