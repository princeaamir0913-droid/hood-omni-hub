-- Fixed by Aamir--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║          HOOD OMNI HUB v1.0 — Multi-Game Script Hub        ║
    ║       Optimized for Delta Mobile Executor (Android/iOS)     ║
    ║                                                              ║
    ║  Supported Games:                                            ║
    ║   • Tha Bronx 3       (PlaceId: 16472538603)                ║
    ║   • Gang Wars          (PlaceId: 137020602493628)            ║
    ║   • Central Streets    (PlaceId: 121567535120062)            ║
    ║   • Philly Streetz 2   (PlaceId: 130700367963690)            ║
    ╚══════════════════════════════════════════════════════════════╝
]]--

-- ═══════════════════════════════════════════════════════════════
-- // 1. SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer      = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- // 2. SAFE START
-- ═══════════════════════════════════════════════════════════════
if not game:IsLoaded() then
    repeat task.wait(0.1) until game:IsLoaded()
end
task.wait(1) -- Let game services initialize

-- ═══════════════════════════════════════════════════════════════
-- // 3. GAME DETECTION
-- ═══════════════════════════════════════════════════════════════
local PLACE_ID = game.PlaceId
local GAME_NAMES = {
    [16472538603]    = "Tha Bronx 3",
    [137020602493628] = "Gang Wars",
    [121567535120062] = "Central Streets",
    [130700367963690] = "Philly Streetz 2",
}
local GAME_NAME = GAME_NAMES[PLACE_ID] or nil

if not GAME_NAME then
    warn("[Hood Omni Hub] Unsupported game (PlaceId: " .. tostring(PLACE_ID) .. ")")
    return
end

-- Send success notification to Tasklet webhook
local function reportSuccess(game)
    pcall(function()
        local req = request or http_request or (syn and syn.request) or http
        if not req then return end
        
        pcall(function()
            req({
                Url = "https://webhooks.tasklet.ai/v1/public/webhook?token=9aa92c65501f42799e7d52cf068aaf97",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode({
                    type = "success",
                    game = game,
                    player = LocalPlayer.Name,
                    placeId = PLACE_ID,
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                }),
            })
        end)
    end)
end
reportSuccess(GAME_NAME)

-- ═══════════════════════════════════════════════════════════════
-- // 4. CONFIGURATION
-- ═══════════════════════════════════════════════════════════════
local Config = {
    -- Shared combat
    Combat = {
        Aimbot = false,
        AimbotFOV = 400,
        SilentAim = false,
        NoRecoil = false,
        Triggerbot = false,
        HitboxExpander = false,
        HitboxSize = 8,
    },
    -- Shared ESP
    ESP = {
        PlayerESP = false,
        GunESP = false,
    },
    -- Shared player mods
    Player = {
        SpeedBoost = false,
        SpeedValue = 32,
        InfiniteJump = false,
        Noclip = false,
        Fly = false,
    },
    -- Shared loot
    Loot = {
        AutoPickup = false,
        PickupRange = 25,
        AutoLoot = false,
    },
    -- Game-specific configs (populated by each module)
    Game = {},
}

-- ═══════════════════════════════════════════════════════════════
-- // 5. WEBHOOK ERROR REPORTING
-- ═══════════════════════════════════════════════════════════════
-- OPTION 1: Paste your Tasklet webhook URL to send errors directly to your AI agent:
-- (Copy the webhook URL from the "Hood Omni Hub error reports" trigger card in Tasklet)
local TASKLET_WEBHOOK_URL = "https://webhooks.tasklet.ai/v1/public/webhook?token=9aa92c65501f42799e7d52cf068aaf97"

-- OPTION 2: Paste a Discord webhook URL for error notifications in Discord:
local DISCORD_WEBHOOK_URL = ""

local function reportError(context, err)
    pcall(function()
        local req = request or http_request or (syn and syn.request) or http
        if not req then return end
        
        local errorTime = os.date("!%Y-%m-%dT%H:%M:%SZ")
        
        -- Send to Tasklet AI agent (analyzes + emails you a diagnosis)
        if TASKLET_WEBHOOK_URL ~= "" then
            pcall(function()
                req({
                    Url = TASKLET_WEBHOOK_URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({
                        type = "error",
                        game = GAME_NAME,
                        feature = tostring(context),
                        error = tostring(err),
                        player = LocalPlayer.Name,
                        placeId = PLACE_ID,
                        timestamp = errorTime,
                    }),
                })
            end)
        end
        
        -- Send to Discord (formatted embed)
        if DISCORD_WEBHOOK_URL ~= "" then
            pcall(function()
                req({
                    Url = DISCORD_WEBHOOK_URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({
                        embeds = {{
                            title = "🚨 Hood Omni Hub Error",
                            color = 16711680,
                            fields = {
                                {name = "Game", value = GAME_NAME, inline = true},
                                {name = "Player", value = LocalPlayer.Name, inline = true},
                                {name = "PlaceId", value = tostring(PLACE_ID), inline = true},
                                {name = "Context", value = tostring(context), inline = false},
                                {name = "Error", value = "```\n" .. tostring(err) .. "\n```", inline = false},
                            },
                            timestamp = errorTime,
                        }}
                    }),
                })
            end)
        end
    end)
end

-- Safe pcall wrapper that reports errors
local function safeCall(context, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        reportError(context, err)
        warn("[Hood Omni Hub] " .. context .. ": " .. tostring(err))
    end
    return ok, err
end

-- ═══════════════════════════════════════════════════════════════
-- // 5b. GUN SHOP EXCLUSION HELPER
-- ═══════════════════════════════════════════════════════════════
-- Returns true if a ProximityPrompt belongs to a gun shop (should NOT be fired by autofarms)
local GUN_KEYWORDS = {
    "glock","pistol","revolver","shotgun","rifle","smg","uzi","draco",
    "ak","m4","ar","switch","gun","weapon","firearm","ammo","ammunition",
    "carbine","sniper","p90","mac","tec","desert","eagle","beretta",
    "xmas","ump","mp5","minigun","launcher","bazooka"
}
local function isGunShopPrompt(prompt)
    local pName = (prompt.Parent and prompt.Parent.Name:lower()) or ""
    local aText = prompt.ActionText:lower()
    local oText = prompt.ObjectText:lower()
    local fullName = (prompt.Parent and prompt.Parent:GetFullName():lower()) or ""
    for _, kw in ipairs(GUN_KEYWORDS) do
        if pName:find(kw) or oText:find(kw) or fullName:find(kw) then
            return true
        end
    end
    -- If action text is ONLY "buy"/"purchase" with no other context, and parent has gun keyword
    if (aText == "buy" or aText == "purchase" or aText == "grab") then
        for _, kw in ipairs(GUN_KEYWORDS) do
            if fullName:find(kw) then return true end
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- // 6. ANTI-DETECTION
-- ═══════════════════════════════════════════════════════════════
-- Randomize heartbeat delays, use pcall everywhere, minimize remote spam
local AntiDetect = {}
function AntiDetect.randomWait(min, max)
    task.wait(min + math.random() * (max - min))
end
function AntiDetect.humanDelay()
    task.wait(0.08 + math.random() * 0.15)
end

-- ═══════════════════════════════════════════════════════════════
-- // 7. UI PARENT (Delta Mobile)
-- ═══════════════════════════════════════════════════════════════
local UI_Parent = LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
    local t = Instance.new("Frame", game:GetService("CoreGui"))
    t:Destroy()
    UI_Parent = game:GetService("CoreGui")
end)

-- Cleanup old instance
if UI_Parent:FindFirstChild("HoodOmniHub") then
    UI_Parent.HoodOmniHub:Destroy()
end

-- ═══════════════════════════════════════════════════════════════
-- // 8. SCREEN SIZING
-- ═══════════════════════════════════════════════════════════════
local Camera    = workspace.CurrentCamera
local VP        = Camera.ViewportSize
local SW, SH    = VP.X, VP.Y
local IS_MOBILE = UserInputService.TouchEnabled

local UI_W  = math.clamp(math.floor(SW * 0.92), 320, 520)
local UI_H  = math.clamp(math.floor(SH * 0.65), 320, 450)
local BTN_H = IS_MOBILE and 48 or 38
local TXT_S = IS_MOBILE and 14 or 13

-- ═══════════════════════════════════════════════════════════════
-- // 9. UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════
local Util = {}

function Util.getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Util.getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Util.teleport(cf)
    local hrp = Util.getHRP()
    if hrp then
        hrp.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

function Util.firePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.1)
            prompt:InputHoldEnd()
        end
    end
end

function Util.fireTouchInterest(part1, part2, toggle)
    if firetouchinterest then
        firetouchinterest(part1, part2, toggle)
    end
end

function Util.fireRemote(remote, ...)
    if remote then
        local args = {...}
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(unpack(args))
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(unpack(args))
            end
        end)
    end
end

function Util.findInWorkspace(...)
    local current = workspace
    for _, name in ipairs({...}) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

function Util.getClosestPlayer(maxDist)
    maxDist = maxDist or Config.Combat.AimbotFOV
    local closest, bestDist = nil, maxDist
    local myHRP = Util.getHRP()
    if not myHRP then return nil end
    local cam = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local screenPos, onScreen = cam:WorldToScreenPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

-- ═══════════════════════════════════════════════════════════════
-- // 10. BUILD UI
-- ═══════════════════════════════════════════════════════════════
local ScreenGui, MainFrame -- references for engine loop access

local function BuildUI()
    ScreenGui = Instance.new("ScreenGui", UI_Parent)
    ScreenGui.Name              = "HoodOmniHub"
    ScreenGui.ResetOnSpawn      = false
    ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder      = 999
    ScreenGui.IgnoreGuiInset    = true

    -- Main window
    MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name              = "Main"
    MainFrame.Size              = UDim2.new(0, UI_W, 0, UI_H)
    MainFrame.Position          = UDim2.new(0.5, -UI_W/2, 0.5, -UI_H/2)
    MainFrame.BackgroundColor3  = Color3.fromRGB(15, 15, 15)
    MainFrame.Active            = true
    MainFrame.Draggable         = false
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    -- Drop shadow
    local Shadow = Instance.new("ImageLabel", MainFrame)
    Shadow.Size               = UDim2.new(1, 20, 1, 20)
    Shadow.Position           = UDim2.new(0, -10, 0, -10)
    Shadow.BackgroundTransparency = 1
    Shadow.Image              = "rbxassetid://5554236805"
    Shadow.ImageColor3        = Color3.new(0, 0, 0)
    Shadow.ImageTransparency  = 0.6
    Shadow.ZIndex             = 0
    Shadow.ScaleType          = Enum.ScaleType.Slice
    Shadow.SliceCenter        = Rect.new(23, 23, 277, 277)

    -- Title bar
    local TitleBar = Instance.new("Frame", MainFrame)
    TitleBar.Size             = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    TitleBar.ZIndex           = 2
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

    local TBFill = Instance.new("Frame", TitleBar)
    TBFill.Size             = UDim2.new(1, 0, 0.5, 0)
    TBFill.Position         = UDim2.new(0, 0, 0.5, 0)
    TBFill.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    TBFill.BorderSizePixel  = 0

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size               = UDim2.new(1, -70, 1, 0)
    TitleLabel.Position           = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3         = Color3.new(1, 1, 1)
    TitleLabel.Text               = "🏙️ HOOD OMNI HUB"
    TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
    TitleLabel.Font               = Enum.Font.GothamBold
    TitleLabel.TextSize           = TXT_S + 2
    TitleLabel.ZIndex             = 3

    -- Game badge
    local GameBadge = Instance.new("TextLabel", TitleBar)
    GameBadge.Size               = UDim2.new(0, 140, 0, 16)
    GameBadge.Position           = UDim2.new(0, 12, 1, -20)
    GameBadge.BackgroundTransparency = 1
    GameBadge.TextColor3         = Color3.fromRGB(100, 200, 100)
    GameBadge.Text               = "▸ " .. GAME_NAME
    GameBadge.TextXAlignment     = Enum.TextXAlignment.Left
    GameBadge.Font               = Enum.Font.Gotham
    GameBadge.TextSize           = 10
    GameBadge.ZIndex             = 3

    -- Minimize button
    local MinBtn = Instance.new("TextButton", TitleBar)
    MinBtn.Size             = UDim2.new(0, 30, 0, 26)
    MinBtn.Position         = UDim2.new(1, -68, 0, 7)
    MinBtn.Text             = "—"
    MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    MinBtn.TextColor3       = Color3.new(1, 1, 1)
    MinBtn.Font             = Enum.Font.GothamBold
    MinBtn.TextSize         = 14
    MinBtn.ZIndex           = 4
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    -- Close button
    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size             = UDim2.new(0, 30, 0, 26)
    CloseBtn.Position         = UDim2.new(1, -34, 0, 7)
    CloseBtn.Text             = "✕"
    CloseBtn.BackgroundColor3 = Color3.fromRGB(190, 40, 40)
    CloseBtn.TextColor3       = Color3.new(1, 1, 1)
    CloseBtn.Font             = Enum.Font.GothamBold
    CloseBtn.TextSize         = 14
    CloseBtn.ZIndex           = 4
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    local isMinimized = false
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child ~= TitleBar and child ~= Shadow and not child:IsA("UICorner") then
                child.Visible = not isMinimized
            end
        end
        if isMinimized then
            MainFrame.Size = UDim2.new(0, UI_W, 0, 40)
            MinBtn.Text = "+"
        else
            MainFrame.Size = UDim2.new(0, UI_W, 0, UI_H)
            MinBtn.Text = "—"
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    -- Touch drag
    do
        local dragging, dragStart, startPos = false, nil, nil
        local function onInputBegan(input)
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = input.Position
                startPos  = MainFrame.Position
            end
        end
        local function onInputChanged(input)
            if dragging and (
                input.UserInputType == Enum.UserInputType.Touch or
                input.UserInputType == Enum.UserInputType.MouseMovement
            ) then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
        local function onInputEnded(input)
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end
        TitleBar.InputBegan:Connect(onInputBegan)
        UserInputService.InputChanged:Connect(onInputChanged)
        UserInputService.InputEnded:Connect(onInputEnded)
    end

    -- Sidebar
    local SidebarW = IS_MOBILE and 105 or 120
    local Sidebar = Instance.new("ScrollingFrame", MainFrame)
    Sidebar.Name               = "Sidebar"
    Sidebar.Size               = UDim2.new(0, SidebarW, 1, -44)
    Sidebar.Position           = UDim2.new(0, 0, 0, 44)
    Sidebar.BackgroundColor3   = Color3.fromRGB(20, 20, 20)
    Sidebar.ScrollBarThickness = 2
    Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Sidebar.CanvasSize         = UDim2.new(0, 0, 0, 0)
    Sidebar.BorderSizePixel    = 0
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

    local SBFill = Instance.new("Frame", Sidebar)
    SBFill.Size             = UDim2.new(0.5, 0, 1, 0)
    SBFill.Position         = UDim2.new(0.5, 0, 0, 0)
    SBFill.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    SBFill.BorderSizePixel  = 0

    local SidebarLayout = Instance.new("UIListLayout", Sidebar)
    SidebarLayout.Padding             = UDim.new(0, 4)
    SidebarLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local SBPad = Instance.new("UIPadding", Sidebar)
    SBPad.PaddingTop   = UDim.new(0, 6)
    SBPad.PaddingLeft  = UDim.new(0, 4)
    SBPad.PaddingRight = UDim.new(0, 4)

    -- Content area
    local Content = Instance.new("ScrollingFrame", MainFrame)
    Content.Name                   = "Content"
    Content.Size                   = UDim2.new(1, -(SidebarW + 10), 1, -50)
    Content.Position               = UDim2.new(0, SidebarW + 5, 0, 46)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness     = 3
    Content.ScrollBarImageColor3   = Color3.fromRGB(90, 90, 90)
    Content.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    Content.CanvasSize             = UDim2.new(0, 0, 0, 0)
    Content.ElasticBehavior        = Enum.ElasticBehavior.Always
    Content.BorderSizePixel        = 0

    local ContentLayout = Instance.new("UIListLayout", Content)
    ContentLayout.Padding   = UDim.new(0, 6)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local CPad = Instance.new("UIPadding", Content)
    CPad.PaddingTop   = UDim.new(0, 4)
    CPad.PaddingRight = UDim.new(0, 4)

    -- ── UI BUILDER FUNCTIONS ─────────────────────────────────
    local activeTabBtn = nil
    local firstTabAction = nil

    local function Tab(icon, name, func)
        local b = Instance.new("TextButton", Sidebar)
        b.Size             = UDim2.new(1, 0, 0, BTN_H - 4)
        b.Text             = icon .. " " .. name
        b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        b.TextColor3       = Color3.fromRGB(200, 200, 200)
        b.Font             = Enum.Font.Gotham
        b.TextSize         = TXT_S - 1
        b.TextWrapped      = true
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)

        local function activate()
            if activeTabBtn then
                activeTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                activeTabBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
            end
            activeTabBtn           = b
            b.BackgroundColor3     = Color3.fromRGB(50, 50, 110)
            b.TextColor3           = Color3.new(1, 1, 1)
            for _, v in ipairs(Content:GetChildren()) do
                if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
                    v:Destroy()
                end
            end
            safeCall("Tab:" .. name, func, Content)
        end
        b.MouseButton1Click:Connect(activate)
        if not firstTabAction then firstTabAction = activate end
    end

    local function MakeToggle(parent, label, getVal, setVal)
        local b = Instance.new("TextButton", parent)
        b.Size             = UDim2.new(1, 0, 0, BTN_H)
        b.BackgroundColor3 = getVal() and Color3.fromRGB(30, 100, 30) or Color3.fromRGB(42, 42, 42)
        b.TextColor3       = Color3.new(1, 1, 1)
        b.Font             = Enum.Font.Gotham
        b.TextSize         = TXT_S
        b.Text             = label .. (getVal() and "  ✅" or "  ❌")
        b.TextXAlignment   = Enum.TextXAlignment.Left
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        local pad = Instance.new("UIPadding", b)
        pad.PaddingLeft = UDim.new(0, 10)

        b.MouseButton1Click:Connect(function()
            setVal(not getVal())
            local on           = getVal()
            b.Text             = label .. (on and "  ✅" or "  ❌")
            b.BackgroundColor3 = on and Color3.fromRGB(30, 100, 30) or Color3.fromRGB(42, 42, 42)
        end)
        return b
    end

    local function MakeButton(parent, label, callback)
        local b = Instance.new("TextButton", parent)
        b.Size             = UDim2.new(1, 0, 0, BTN_H)
        b.BackgroundColor3 = Color3.fromRGB(45, 45, 80)
        b.TextColor3       = Color3.new(1, 1, 1)
        b.Font             = Enum.Font.Gotham
        b.TextSize         = TXT_S
        b.Text             = label
        b.TextXAlignment   = Enum.TextXAlignment.Left
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        local pad = Instance.new("UIPadding", b)
        pad.PaddingLeft = UDim.new(0, 10)

        b.MouseButton1Click:Connect(function()
            safeCall("Button:" .. label, callback)
        end)
        return b
    end

    local function Label(parent, txt)
        local l = Instance.new("TextLabel", parent)
        l.Size                = UDim2.new(1, 0, 0, 22)
        l.BackgroundTransparency = 1
        l.TextColor3          = Color3.fromRGB(130, 130, 130)
        l.Font                = Enum.Font.GothamBold
        l.TextSize            = 11
        l.Text                = txt
        l.TextXAlignment      = Enum.TextXAlignment.Left
        local p = Instance.new("UIPadding", l)
        p.PaddingLeft = UDim.new(0, 4)
    end

    local function Divider(parent)
        local d = Instance.new("Frame", parent)
        d.Size             = UDim2.new(1, 0, 0, 1)
        d.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        d.BorderSizePixel  = 0
    end

    -- ── SHARED TABS ──────────────────────────────────────────

    -- Combat Tab (shared across all games)
    Tab("⚔️", "Combat", function(p)
        Label(p, "  AIMBOT")
        MakeToggle(p, "Aimbot (Lock-On)", 
            function() return Config.Combat.Aimbot end,
            function(v) Config.Combat.Aimbot = v end)
        MakeToggle(p, "Silent Aim",
            function() return Config.Combat.SilentAim end,
            function(v) Config.Combat.SilentAim = v end)
        MakeToggle(p, "Triggerbot",
            function() return Config.Combat.Triggerbot end,
            function(v) Config.Combat.Triggerbot = v end)
        Divider(p)
        Label(p, "  GUN MODS")
        MakeToggle(p, "No Recoil",
            function() return Config.Combat.NoRecoil end,
            function(v) Config.Combat.NoRecoil = v end)
        MakeToggle(p, "Hitbox Expander",
            function() return Config.Combat.HitboxExpander end,
            function(v)
                Config.Combat.HitboxExpander = v
                if not v then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character then
                            local head = plr.Character:FindFirstChild("Head")
                            if head then
                                head.Size = Vector3.new(1.2, 1.2, 1.2)
                            end
                        end
                    end
                end
            end)
    end)

    -- ESP Tab (shared)
    Tab("👁", "ESP", function(p)
        Label(p, "  VISUAL ESP")
        MakeToggle(p, "Player ESP",
            function() return Config.ESP.PlayerESP end,
            function(v)
                Config.ESP.PlayerESP = v
                if not v then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr.Character then
                            local h = plr.Character:FindFirstChild("_HubESP")
                            if h then h:Destroy() end
                        end
                    end
                end
            end)
        MakeToggle(p, "Gun / Tool ESP",
            function() return Config.ESP.GunESP end,
            function(v)
                Config.ESP.GunESP = v
                if not v then
                    for _, x in ipairs(workspace:GetDescendants()) do
                        if x.Name == "_GunGlow" then x:Destroy() end
                    end
                end
            end)
    end)

    -- Player Mods Tab (shared)
    Tab("🏃", "Player", function(p)
        Label(p, "  MOVEMENT")
        MakeToggle(p, "Speed Boost (2x)",
            function() return Config.Player.SpeedBoost end,
            function(v)
                Config.Player.SpeedBoost = v
                local hum = Util.getHumanoid()
                if hum then
                    hum.WalkSpeed = v and Config.Player.SpeedValue or 16
                end
            end)
        MakeToggle(p, "Infinite Jump",
            function() return Config.Player.InfiniteJump end,
            function(v) Config.Player.InfiniteJump = v end)
        MakeToggle(p, "Noclip",
            function() return Config.Player.Noclip end,
            function(v) Config.Player.Noclip = v end)
        Divider(p)
        Label(p, "  LOOT")
        MakeToggle(p, "Auto Pickup Tools",
            function() return Config.Loot.AutoPickup end,
            function(v) Config.Loot.AutoPickup = v end)
        MakeToggle(p, "Auto Loot Cash",
            function() return Config.Loot.AutoLoot end,
            function(v) Config.Loot.AutoLoot = v end)
    end)

    -- Player List Tab (shared)
    Tab("👥", "Players", function(p)
        Label(p, "  PLAYERS IN SERVER")
        for _, plr in ipairs(Players:GetPlayers()) do
            local f = Instance.new("Frame", p)
            f.Size             = UDim2.new(1, 0, 0, 55)
            f.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)

            local icon = Instance.new("ImageLabel", f)
            icon.Size             = UDim2.new(0, 34, 0, 34)
            icon.Position         = UDim2.new(0, 6, 0, 10)
            icon.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            icon.Image            = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48"
            Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)

            local t = Instance.new("TextLabel", f)
            t.Size                = UDim2.new(1, -50, 1, -6)
            t.Position            = UDim2.new(0, 46, 0, 3)
            t.BackgroundTransparency = 1
            t.TextColor3          = Color3.fromRGB(0, 255, 130)
            t.TextWrapped         = true
            t.TextXAlignment      = Enum.TextXAlignment.Left
            t.TextYAlignment      = Enum.TextYAlignment.Top
            t.Font                = Enum.Font.Gotham
            t.TextSize            = TXT_S - 1

            local inv = {}
            pcall(function()
                local bp = plr:FindFirstChild("Backpack")
                if bp then
                    for _, x in ipairs(bp:GetChildren()) do
                        table.insert(inv, x.Name)
                    end
                end
                if plr.Character then
                    for _, x in ipairs(plr.Character:GetChildren()) do
                        if x:IsA("Tool") then table.insert(inv, "🔫" .. x.Name) end
                    end
                end
            end)
            t.Text = "👤 " .. plr.Name ..
                     "\n📦 " .. (#inv > 0 and table.concat(inv, ", ") or "Empty")
        end
    end)

    -- Return UI builder functions for game modules
    return {
        Tab = Tab,
        MakeToggle = MakeToggle,
        MakeButton = MakeButton,
        Label = Label,
        Divider = Divider,
        firstTabAction = function() if firstTabAction then firstTabAction() end end,
    }
end

-- ═══════════════════════════════════════════════════════════════
-- // 11. SHARED ENGINE LOOPS
-- ═══════════════════════════════════════════════════════════════
local function StartEngineLoops()
    local espTimer = 0
    local combatTimer = 0
    local lootTimer = 0

    -- Noclip loop
    RunService.Stepped:Connect(function()
        if Config.Player.Noclip then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)

    -- Infinite Jump
    UserInputService.JumpRequest:Connect(function()
        if Config.Player.InfiniteJump then
            local hum = Util.getHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    -- Main engine (throttled)
    RunService.Heartbeat:Connect(function(dt)
        -- Combat (every 0.05s for responsiveness)
        combatTimer += dt
        if combatTimer >= 0.05 then
            combatTimer = 0

            -- Aimbot
            if Config.Combat.Aimbot then
                local target = Util.getClosestPlayer()
                if target and target.Character then
                    local head = target.Character:FindFirstChild("Head")
                    if head then
                        local cam = workspace.CurrentCamera
                        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, head.Position)
                    end
                end
            end

            -- Triggerbot
            if Config.Combat.Triggerbot then
                pcall(function()
                    local mouse = LocalPlayer:GetMouse()
                    if mouse.Target then
                        local targetModel = mouse.Target:FindFirstAncestorOfClass("Model")
                        if targetModel and targetModel ~= LocalPlayer.Character then
                            local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
                            if targetPlayer then
                                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                                if tool then
                                    tool:Activate()
                                end
                            end
                        end
                    end
                end)
            end

            -- No Recoil
            if Config.Combat.NoRecoil then
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, tool in ipairs(char:GetChildren()) do
                            if tool:IsA("Tool") then
                                for _, desc in ipairs(tool:GetDescendants()) do
                                    if desc:IsA("BodyAngularVelocity") or desc:IsA("BodyGyro") then
                                        desc:Destroy()
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            -- Hitbox Expander
            if Config.Combat.HitboxExpander then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local head = plr.Character:FindFirstChild("Head")
                        if head and head.Size.X < Config.Combat.HitboxSize then
                            head.Size = Vector3.new(Config.Combat.HitboxSize, Config.Combat.HitboxSize, Config.Combat.HitboxSize)
                            head.Transparency = 0.7
                            head.CanCollide = false
                        end
                    end
                end
            end
        end

        -- ESP (every 2s to reduce lag on mobile)
        espTimer += dt
        if espTimer >= 2 then
            espTimer = 0
            local hrp = Util.getHRP()

            -- Player ESP (lightweight - only scans players list)
            if Config.ESP.PlayerESP then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local head = plr.Character:FindFirstChild("Head")
                        -- Only ESP players within 200 studs
                        if head and hrp and (head.Position - hrp.Position).Magnitude < 200 then
                            if not plr.Character:FindFirstChild("_HubESP") then
                                local h = Instance.new("Highlight", plr.Character)
                                h.Name = "_HubESP"
                                h.FillColor = Color3.fromRGB(255, 0, 0)
                                h.OutlineColor = Color3.new(1, 1, 1)
                                h.FillTransparency = 0.5
                            end
                        else
                            -- Remove ESP for far players to save performance
                            if plr.Character then
                                local old = plr.Character:FindFirstChild("_HubESP")
                                if old then old:Destroy() end
                            end
                        end
                    end
                end
            end

            -- Gun ESP (only check dropped tools, limit to 150 studs)
            if Config.ESP.GunESP then
                -- Clean old glows first
                local glowCount = 0
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("Tool") and v.Parent == workspace then
                        local handle = v:FindFirstChild("Handle")
                        if handle and hrp and (handle.Position - hrp.Position).Magnitude < 150 then
                            if not v:FindFirstChild("_GunGlow") then
                                local h = Instance.new("Highlight", v)
                                h.Name = "_GunGlow"
                                h.FillColor = Color3.new(1, 1, 0)
                                h.OutlineColor = Color3.new(1, 0.8, 0)
                                h.FillTransparency = 0.4
                            end
                            glowCount += 1
                            if glowCount >= 20 then break end -- Cap highlights
                        else
                            local old = v:FindFirstChild("_GunGlow")
                            if old then old:Destroy() end
                        end
                    end
                end
            end
        end

        -- Loot/Pickup (every 1s to reduce lag on mobile)
        lootTimer += dt
        if lootTimer >= 1 then
            lootTimer = 0
            local hrp = Util.getHRP()
            if not hrp then return end

            -- Auto Pickup Tools (only dropped tools in workspace, limit per cycle)
            if Config.Loot.AutoPickup then
                local pickCount = 0
                for _, v in ipairs(workspace:GetChildren()) do
                    if v:IsA("Tool") then
                        local handle = v:FindFirstChild("Handle")
                        if handle then
                            local dist = (handle.Position - hrp.Position).Magnitude
                            if dist < Config.Loot.PickupRange then
                                pcall(function()
                                    Util.fireTouchInterest(hrp, handle, 0)
                                    task.wait()
                                    Util.fireTouchInterest(hrp, handle, 1)
                                end)
                                pickCount += 1
                                if pickCount >= 3 then break end -- Max 3 pickups per cycle
                            end
                        end
                    end
                end
            end

            -- Auto Loot (proximity prompts + click detectors for cash/drops)
            if Config.Loot.AutoLoot then
                local lootCount = 0
                for _, v in ipairs(workspace:GetDescendants()) do
                    if lootCount >= 5 then break end -- Cap per cycle
                    
                    -- ProximityPrompt loot
                    if v:IsA("ProximityPrompt") then
                        local name = v.Parent and v.Parent.Name:lower() or ""
                        local action = v.ActionText:lower()
                        if name:find("cash") or name:find("money") or name:find("loot")
                            or name:find("drop") or name:find("bag") or name:find("stack")
                            or action:find("pick") or action:find("loot") or action:find("collect")
                            or action:find("grab") or action:find("take") then
                            local dist = v.Parent and v.Parent:IsA("BasePart")
                                and (v.Parent.Position - hrp.Position).Magnitude or 999
                            if dist < Config.Loot.PickupRange then
                                Util.firePrompt(v)
                                lootCount += 1
                            end
                        end
                    end
                    
                    -- ClickDetector loot (some games use these for cash drops)
                    if v:IsA("ClickDetector") then
                        local name = v.Parent and v.Parent.Name:lower() or ""
                        if name:find("cash") or name:find("money") or name:find("loot") or name:find("drop") then
                            local dist = v.Parent and v.Parent:IsA("BasePart")
                                and (v.Parent.Position - hrp.Position).Magnitude or 999
                            if dist < Config.Loot.PickupRange then
                                pcall(function() fireclickdetector(v) end)
                                lootCount += 1
                            end
                        end
                    end
                end
            end

            -- Speed Boost refresh
            if Config.Player.SpeedBoost then
                local hum = Util.getHumanoid()
                if hum and hum.WalkSpeed < Config.Player.SpeedValue then
                    hum.WalkSpeed = Config.Player.SpeedValue
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- // 12. GAME MODULE PLACEHOLDER
-- ═══════════════════════════════════════════════════════════════
-- Each game module function receives (UI, Config, Util, safeCall, AntiDetect)
-- and adds game-specific tabs using UI.Tab, UI.MakeToggle, etc.

-- ═══════════════════════════════════════════════════════════════
-- // GAME MODULE: THA BRONX 3 (PlaceId: 16472538603)
-- ═══════════════════════════════════════════════════════════════
function loadBronx3(UI, Config, Util, safeCall, AntiDetect)
    -- Game-specific config
    Config.Game = {
        ConstructionFarm = false,
        CardFarm = false,
        LaptopFarm = false,
        MopFarm = false,
        DumpsterFarm = false,
        AutoRob = false,
        GunDupe = false,
        InfiniteStamina = false,
        InfiniteHunger = false,
        AutoDeposit = false,
    }

    -- ── AUTOFARM TAB ─────────────────────────────────────────
    UI.Tab("🌾", "AutoFarm", function(p)
        UI.Label(p, "  JOBS — AUTOFARM")

        -- Construction Autofarm
        UI.MakeToggle(p, "🔨 Construction Farm",
            function() return Config.Game.ConstructionFarm end,
            function(v)
                Config.Game.ConstructionFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.ConstructionFarm do
                            safeCall("Bronx3:Construction", function()
                                local player = game.Players.LocalPlayer

                                -- Start job if not working
                                if not player:GetAttribute("WorkingJob") or player:GetAttribute("WorkingJob") == false then
                                    local startJob = Util.findInWorkspace("ConstructionStuff", "Start Job")
                                    if startJob then
                                        Util.teleport(startJob.CFrame)
                                        task.wait(0.5)
                                        local prompt = startJob:FindFirstChildOfClass("ProximityPrompt")
                                            or startJob:FindFirstChild("Prompt")
                                        if prompt then Util.firePrompt(prompt) end
                                    end
                                end
                                task.wait(0.5)

                                -- Auto equip plywood
                                pcall(function()
                                    local bp = player.Backpack:FindFirstChild("PlyWood")
                                    if bp then bp.Parent = player.Character end
                                end)

                                -- Grab wood
                                local grabWood = Util.findInWorkspace("ConstructionStuff", "Grab Wood")
                                if grabWood then
                                    for _, v in ipairs(grabWood:GetChildren()) do
                                        local pr = v:FindFirstChildOfClass("ProximityPrompt")
                                        if pr and pr.ActionText == "Wood" then
                                            Util.firePrompt(pr)
                                            task.wait(0.1)
                                        end
                                    end
                                end

                                -- Build walls
                                local conStuff = Util.findInWorkspace("ConstructionStuff")
                                if conStuff then
                                    for _, v in ipairs(conStuff:GetDescendants()) do
                                        if v:IsA("ProximityPrompt") and v.ActionText == "Wall" then
                                            Util.firePrompt(v)
                                            task.wait(0.1)
                                        end
                                    end
                                end

                                -- If no plywood, teleport to wood area
                                local hasPly = player.Backpack:FindFirstChild("PlyWood")
                                    or (player.Character and player.Character:FindFirstChild("PlyWood"))
                                if not hasPly then
                                    Util.teleport(CFrame.new(-1728, 371, -1177))
                                end
                            end)
                            AntiDetect.randomWait(0.3, 0.6)
                        end
                    end)
                end
            end)

        -- Card Autofarm
        UI.MakeToggle(p, "💳 Card Swipe Farm",
            function() return Config.Game.CardFarm end,
            function(v)
                Config.Game.CardFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.CardFarm do
                            safeCall("Bronx3:CardFarm", function()
                                -- Look for card swiping spots
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.CardFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local parentName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local actionText = v2.ActionText:lower()
                                        if parentName:find("card") or parentName:find("atm") or parentName:find("swipe")
                                            or actionText:find("swipe") or actionText:find("card") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.3)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.5, 1.0)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(1, 2)
                        end
                    end)
                end
            end)

        -- Laptop Autofarm
        UI.MakeToggle(p, "💻 Laptop Hack Farm",
            function() return Config.Game.LaptopFarm end,
            function(v)
                Config.Game.LaptopFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.LaptopFarm do
                            safeCall("Bronx3:LaptopFarm", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.LaptopFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local parentName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local actionText = v2.ActionText:lower()
                                        if parentName:find("laptop") or actionText:find("hack") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.3)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(1, 2)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(2, 4)
                        end
                    end)
                end
            end)

        -- Mopping Autofarm
        UI.MakeToggle(p, "🧹 Mopping Farm",
            function() return Config.Game.MopFarm end,
            function(v)
                Config.Game.MopFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.MopFarm do
                            safeCall("Bronx3:MopFarm", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.MopFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local parentName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local actionText = v2.ActionText:lower()
                                        if parentName:find("mop") or actionText:find("mop") or actionText:find("clean") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.3)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.3, 0.8)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(1, 2)
                        end
                    end)
                end
            end)

        -- Dumpster Autofarm
        UI.MakeToggle(p, "🗑️ Dumpster Dive Farm",
            function() return Config.Game.DumpsterFarm end,
            function(v)
                Config.Game.DumpsterFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.DumpsterFarm do
                            safeCall("Bronx3:DumpsterFarm", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.DumpsterFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local parentName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local actionText = v2.ActionText:lower()
                                        if parentName:find("dumpster") or parentName:find("trash")
                                            or actionText:find("search") or actionText:find("dumpster") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.3)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.5, 1.0)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(2, 4)
                        end
                    end)
                end
            end)

        UI.Divider(p)
        Label = UI.Label
        Label(p, "  AUTO ROB")
        UI.MakeToggle(p, "🏦 Auto Rob (All Spots)",
            function() return Config.Game.AutoRob end,
            function(v)
                Config.Game.AutoRob = v
                if v then
                    task.spawn(function()
                        while Config.Game.AutoRob do
                            safeCall("Bronx3:AutoRob", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.AutoRob then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local parentName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local actionText = v2.ActionText:lower()
                                        if parentName:find("rob") or parentName:find("safe") or parentName:find("register")
                                            or parentName:find("vault") or parentName:find("ice") or parentName:find("studio")
                                            or actionText:find("rob") or actionText:find("steal") or actionText:find("break") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.5)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(1, 2)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(3, 5)
                        end
                    end)
                end
            end)
    end)

    -- ── WEAPONS TAB ──────────────────────────────────────────
    UI.Tab("🔫", "Weapons", function(p)
        UI.Label(p, "  GUN SPAWNER")

        local weapons = {
            "Uzi", "FN", "Draco", "Mac10", "Shotgun", "Pistol",
            "AK47", "AR15", "Glock", "Deagle", "MP5", "Revolver",
            "Switch", "Choppa", "Sniper", "RPG",
        }

        for _, gunName in ipairs(weapons) do
            UI.MakeButton(p, "🔫 Spawn " .. gunName, function()
                safeCall("Bronx3:SpawnGun:" .. gunName, function()
                    -- Method 1: Try ReplicatedStorage
                    local gun = game:GetService("ReplicatedStorage"):FindFirstChild(gunName, true)
                    if gun and gun:IsA("Tool") then
                        local clone = gun:Clone()
                        clone.Parent = LocalPlayer.Backpack
                        return
                    end
                    -- Method 2: Try firing a remote
                    for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                        if remote:IsA("RemoteEvent") then
                            local rName = remote.Name:lower()
                            if rName:find("give") or rName:find("spawn") or rName:find("weapon") or rName:find("gun") then
                                remote:FireServer(gunName)
                                return
                            end
                        end
                    end
                    -- Method 3: Search workspace for gun models
                    for _, v in ipairs(workspace:GetDescendants()) do
                        if v:IsA("Tool") and v.Name:lower() == gunName:lower() then
                            local clone = v:Clone()
                            clone.Parent = LocalPlayer.Backpack
                            return
                        end
                    end
                    warn("[Bronx3] Could not find gun: " .. gunName)
                end)
            end)
        end

        UI.Divider(p)
        UI.Label(p, "  TOOL MODS")
        UI.MakeToggle(p, "♻️ Gun Dupe (Hold + Toggle)",
            function() return Config.Game.GunDupe end,
            function(v)
                Config.Game.GunDupe = v
                if v then
                    task.spawn(function()
                        while Config.Game.GunDupe do
                            pcall(function()
                                local char = LocalPlayer.Character
                                if char then
                                    local tool = char:FindFirstChildOfClass("Tool")
                                    if tool then
                                        local clone = tool:Clone()
                                        clone.Parent = LocalPlayer.Backpack
                                    end
                                end
                            end)
                            task.wait(1)
                        end
                    end)
                end
            end)
    end)

    -- ── TELEPORT TAB ─────────────────────────────────────────
    UI.Tab("📍", "Teleport", function(p)
        UI.Label(p, "  LOCATIONS")

        local teleports = {
            {"🏗️ Construction Site", CFrame.new(-1728, 371, -1177)},
            {"🏦 Bank", nil},
            {"💰 ATM", nil},
            {"🔫 Gun Store", nil},
            {"💊 Pharmacy", nil},
            {"🏥 Hospital", nil},
            {"🏠 Crib / House", nil},
            {"🚗 Car Dealer", nil},
            {"🎰 Casino", nil},
            {"📦 Warehouse", nil},
        }

        -- Auto-discover locations from workspace
        local discovered = {}
        pcall(function()
            local locations = workspace:FindFirstChild("Locations") or workspace:FindFirstChild("TeleportParts")
                or workspace:FindFirstChild("Teleports")
            if locations then
                for _, loc in ipairs(locations:GetChildren()) do
                    if loc:IsA("BasePart") then
                        table.insert(discovered, {loc.Name, loc.CFrame})
                    end
                end
            end
        end)

        -- Show discovered locations first
        if #discovered > 0 then
            UI.Label(p, "  AUTO-DETECTED SPOTS")
            for _, data in ipairs(discovered) do
                UI.MakeButton(p, "📌 " .. data[1], function()
                    Util.teleport(data[2])
                end)
            end
            UI.Divider(p)
            UI.Label(p, "  PRESET LOCATIONS")
        end

        for _, data in ipairs(teleports) do
            if data[2] then
                UI.MakeButton(p, data[1], function()
                    Util.teleport(data[2])
                end)
            end
        end

        -- Smart teleport: search workspace for named parts
        UI.Divider(p)
        UI.Label(p, "  SMART SEARCH")
        UI.MakeButton(p, "🔍 Find All Prompts (Teleport)", function()
            local found = 0
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Parent and v.Parent:IsA("BasePart") then
                    found = found + 1
                    if found <= 30 then
                        print("[Bronx3] Prompt: " .. v.Parent.Name .. " | Action: " .. v.ActionText)
                    end
                end
            end
            print("[Bronx3] Total prompts found: " .. found)
        end)
    end)

    -- ── RESOURCES TAB ────────────────────────────────────────
    UI.Tab("❤️", "Resources", function(p)
        UI.Label(p, "  PLAYER RESOURCES")
        UI.MakeToggle(p, "♾️ Infinite Stamina",
            function() return Config.Game.InfiniteStamina end,
            function(v)
                Config.Game.InfiniteStamina = v
                if v then
                    task.spawn(function()
                        while Config.Game.InfiniteStamina do
                            pcall(function()
                                local player = LocalPlayer
                                -- Try setting attributes
                                pcall(function() player:SetAttribute("Stamina", 100) end)
                                pcall(function() player:SetAttribute("Energy", 100) end)
                                pcall(function() player:SetAttribute("Sprint", 100) end)
                                -- Try leaderstats
                                local ls = player:FindFirstChild("leaderstats") or player:FindFirstChild("Stats")
                                if ls then
                                    local st = ls:FindFirstChild("Stamina") or ls:FindFirstChild("Energy")
                                    if st then st.Value = 100 end
                                end
                            end)
                            task.wait(0.5)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "🍔 Infinite Hunger/Sleep",
            function() return Config.Game.InfiniteHunger end,
            function(v)
                Config.Game.InfiniteHunger = v
                if v then
                    task.spawn(function()
                        while Config.Game.InfiniteHunger do
                            pcall(function()
                                local player = LocalPlayer
                                pcall(function() player:SetAttribute("Hunger", 100) end)
                                pcall(function() player:SetAttribute("Sleep", 100) end)
                                pcall(function() player:SetAttribute("Thirst", 100) end)
                                pcall(function() player:SetAttribute("Health", 100) end)
                            end)
                            task.wait(1)
                        end
                    end)
                end
            end)

        UI.Divider(p)
        UI.Label(p, "  MONEY")
        UI.MakeToggle(p, "🏦 Auto Deposit Cash",
            function() return Config.Game.AutoDeposit end,
            function(v)
                Config.Game.AutoDeposit = v
                if v then
                    task.spawn(function()
                        while Config.Game.AutoDeposit do
                            safeCall("Bronx3:AutoDeposit", function()
                                -- Try to find and fire deposit remotes
                                for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                                    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                                        local rName = remote.Name:lower()
                                        if rName:find("deposit") or rName:find("bank") then
                                            Util.fireRemote(remote, "deposit", "all")
                                        end
                                    end
                                end
                            end)
                            task.wait(10)
                        end
                    end)
                end
            end)

        UI.MakeButton(p, "💵 Print All Remotes (Debug)", function()
            for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    print("[Bronx3] Remote: " .. v:GetFullName())
                end
            end
        end)
    end)
end


-- ═══════════════════════════════════════════════════════════════
-- // GAME MODULE: GANG WARS (PlaceId: 137020602493628)
-- ═══════════════════════════════════════════════════════════════
function loadGangWars(UI, Config, Util, safeCall, AntiDetect)
    Config.Game = {
        CardingFarm = false,
        PotatoFarm = false,
        CarBreaking = false,
        BoxJob = false,
        Scamming = false,
        StoreRobbery = false,
        TurfCapture = false,
        MissionFarm = false,
        AutoRob = false,
        GunDupe = false,
        AutoStore = false,
        SafeESP = false,
    }

    -- ── AUTOFARM TAB ─────────────────────────────────────────
    UI.Tab("🌾", "AutoFarm", function(p)
        UI.Label(p, "  JOBS — AUTOFARM")

        UI.MakeToggle(p, "💳 Carding Farm",
            function() return Config.Game.CardingFarm end,
            function(v)
                Config.Game.CardingFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.CardingFarm do
                            safeCall("GangWars:CardFarm", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.CardingFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("card") or pName:find("swipe") or pName:find("atm")
                                            or aText:find("swipe") or aText:find("card") or aText:find("scan") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.4)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.5, 1.2)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(1.5, 3)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "🥔 Potato / Trap Farm",
            function() return Config.Game.PotatoFarm end,
            function(v)
                Config.Game.PotatoFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.PotatoFarm do
                            safeCall("GangWars:PotatoFarm", function()
                                local lp = game.Players.LocalPlayer
                                local char = lp.Character
                                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                if not hrp or not humanoid then return end

                                -- Hold-fire helper: bypasses HoldDuration instantly
                                local function holdFire(prompt, times)
                                    times = times or 1
                                    for i = 1, times do
                                        if not Config.Game.PotatoFarm then break end
                                        if prompt and prompt.Parent then
                                            if fireproximityprompt then
                                                fireproximityprompt(prompt, 0)
                                            else
                                                prompt:InputHoldBegin()
                                                task.wait((prompt.HoldDuration or 1) + 0.05)
                                                prompt:InputHoldEnd()
                                            end
                                            task.wait(0.12)
                                        end
                                    end
                                end

                                -- Get raw potatoes in backpack (not yet cooked)
                                local function getRawPotatoes()
                                    local list = {}
                                    for _, tool in ipairs(lp.Backpack:GetChildren()) do
                                        if tool:IsA("Tool") then
                                            local n = tool.Name:lower()
                                            if (n:find("potato") or n:find("trap") or n:find("raw") or n:find("bag"))
                                               and not n:find("small") and not n:find("medium")
                                               and not n:find("large") and not n:find("cook") then
                                                table.insert(list, tool)
                                            end
                                        end
                                    end
                                    return list
                                end

                                -- Get cooked potatoes in backpack (small/medium/large)
                                local function getCookedPotatoes()
                                    local list = {}
                                    for _, tool in ipairs(lp.Backpack:GetChildren()) do
                                        if tool:IsA("Tool") then
                                            local n = tool.Name:lower()
                                            if n:find("small") or n:find("medium") or n:find("large") or n:find("cooked") then
                                                table.insert(list, tool)
                                            end
                                        end
                                    end
                                    return list
                                end

                                -- STEP 1: Teleport to Potato Factory (sky platform, Y > 50)
                                local factory = nil
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("BasePart") and v2.Position.Y > 50 then
                                        local n = v2.Name:lower()
                                        if n:find("potato") or n:find("factory") or n:find("trap") then
                                            factory = v2
                                            break
                                        end
                                    end
                                end
                                if not factory then
                                    warn("[GangWars:Potato] Can't find factory platform!")
                                    return
                                end
                                Util.teleport(factory.CFrame + Vector3.new(0, 3, 0))
                                task.wait(1.5)

                                -- STEP 2: Find "Buy Potato" prompt (~$950)
                                local buyPrompt = nil
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local aText = v2.ActionText:lower()
                                        local oText = v2.ObjectText:lower()
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        -- Must reference buying + potato/trap
                                        local isBuy = aText:find("buy") or oText:find("buy") or oText:find("950") or aText:find("purchase")
                                        local isPotato = aText:find("potato") or oText:find("potato") or pName:find("potato")
                                                         or aText:find("trap") or oText:find("trap") or pName:find("trap")
                                        if isBuy and isPotato then
                                            buyPrompt = v2
                                            break
                                        end
                                    end
                                end
                                -- Fallback: any potato-named prompt
                                if not buyPrompt then
                                    for _, v2 in ipairs(workspace:GetDescendants()) do
                                        if v2:IsA("ProximityPrompt") then
                                            local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                            local aText = v2.ActionText:lower()
                                            if pName:find("potato") or aText:find("potato") or aText:find("trap") then
                                                buyPrompt = v2
                                                break
                                            end
                                        end
                                    end
                                end
                                if not buyPrompt then
                                    warn("[GangWars:Potato] Can't find Buy Potato prompt!")
                                    return
                                end

                                -- Teleport right next to buy prompt and buy 10 potatoes
                                if buyPrompt.Parent and buyPrompt.Parent:IsA("BasePart") then
                                    Util.teleport(buyPrompt.Parent.CFrame + Vector3.new(0, 2, 0))
                                    task.wait(0.5)
                                end
                                warn("[GangWars:Potato] Buying potatoes x10...")
                                holdFire(buyPrompt, 10)
                                task.wait(0.5)

                                -- STEP 3: Find all cooking pots/stoves
                                local pots = {}
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        local oText = v2.ObjectText:lower()
                                        if pName:find("pot") or pName:find("cook") or pName:find("stove")
                                           or aText:find("cook") or aText:find("pot") or aText:find("add")
                                           or oText:find("pot") or oText:find("stove") or oText:find("cook") then
                                            table.insert(pots, v2)
                                        end
                                    end
                                end
                                warn("[GangWars:Potato] Found " .. #pots .. " pots")

                                -- STEP 4: Load each raw potato into a pot
                                local rawPotatoes = getRawPotatoes()
                                warn("[GangWars:Potato] Raw potatoes bought: " .. #rawPotatoes)

                                if #rawPotatoes > 0 and #pots > 0 then
                                    local potIndex = 1
                                    for _, rawTool in ipairs(rawPotatoes) do
                                        if not Config.Game.PotatoFarm then break end
                                        local pot = pots[potIndex]
                                        if pot and pot.Parent and pot.Parent:IsA("BasePart") then
                                            humanoid:EquipTool(rawTool)
                                            task.wait(0.25)
                                            Util.teleport(pot.Parent.CFrame + Vector3.new(0, 2, 0))
                                            task.wait(0.3)
                                            holdFire(pot, 1)
                                            task.wait(0.2)
                                            potIndex = (potIndex % #pots) + 1
                                        end
                                    end
                                    humanoid:UnequipTools()
                                end

                                -- STEP 5: Wait for cooked potatoes (small/medium/large) in backpack (up to 45s)
                                warn("[GangWars:Potato] Waiting for potatoes to cook...")
                                local waited = 0
                                while waited < 45 and Config.Game.PotatoFarm do
                                    if #getCookedPotatoes() > 0 then
                                        warn("[GangWars:Potato] Cooked potatoes ready!")
                                        break
                                    end
                                    task.wait(2)
                                    waited = waited + 2
                                end

                                local cookedList = getCookedPotatoes()
                                if #cookedList == 0 then
                                    warn("[GangWars:Potato] No cooked potatoes found after wait, retrying...")
                                    return
                                end

                                -- STEP 6: Find potato seller/buyer NPC
                                local sellerPrompt = nil
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        local oText = v2.ObjectText:lower()
                                        local isSell = aText:find("sell") or oText:find("sell") or pName:find("sell") or pName:find("buyer") or pName:find("vendor")
                                        local isPotato = pName:find("potato") or aText:find("potato") or oText:find("potato")
                                                         or pName:find("trap") or aText:find("trap")
                                        if isSell and isPotato then
                                            sellerPrompt = v2
                                            break
                                        end
                                    end
                                end
                                -- Fallback: nearest "sell" prompt on the factory platform
                                if not sellerPrompt then
                                    local bestDist = math.huge
                                    for _, v2 in ipairs(workspace:GetDescendants()) do
                                        if v2:IsA("ProximityPrompt") then
                                            local aText = v2.ActionText:lower()
                                            if aText:find("sell") then
                                                local pp = v2.Parent
                                                if pp and pp:IsA("BasePart") then
                                                    local d = (pp.Position - hrp.Position).Magnitude
                                                    if d < bestDist then
                                                        bestDist = d
                                                        sellerPrompt = v2
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end

                                if sellerPrompt and sellerPrompt.Parent and sellerPrompt.Parent:IsA("BasePart") then
                                    Util.teleport(sellerPrompt.Parent.CFrame + Vector3.new(0, 2, 0))
                                    task.wait(0.5)
                                    warn("[GangWars:Potato] Selling " .. #cookedList .. " cooked potatoes...")
                                    for _, cookedTool in ipairs(cookedList) do
                                        if not Config.Game.PotatoFarm then break end
                                        if cookedTool and cookedTool.Parent then
                                            humanoid:EquipTool(cookedTool)
                                            task.wait(0.25)
                                            holdFire(sellerPrompt, 1)
                                            task.wait(0.3)
                                        end
                                    end
                                    humanoid:UnequipTools()
                                    warn("[GangWars:Potato] Sold! Restarting cycle...")
                                else
                                    warn("[GangWars:Potato] Could not find seller NPC!")
                                end
                            end)
                            AntiDetect.randomWait(1, 2)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "🚗 Car Breaking Farm",
            function() return Config.Game.CarBreaking end,
            function(v)
                Config.Game.CarBreaking = v
                if v then
                    task.spawn(function()
                        while Config.Game.CarBreaking do
                            safeCall("GangWars:CarBreaking", function()
                                local hrp = Util.getHRP()
                                if not hrp then return end

                                -- GROUP all car-related prompts by their Model ancestor
                                -- so we work ONE car completely instead of jumping all over the map
                                local carModels = {}
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") or v2:IsA("ClickDetector") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = (v2:IsA("ProximityPrompt") and v2.ActionText:lower()) or ""
                                        local fullName = v2.Parent and v2.Parent:GetFullName():lower() or ""

                                        if not isGunShopPrompt(v2) and (
                                            pName:find("window") or pName:find("kia") or pName:find("trunk")
                                            or pName:find("glass") or pName:find("loot")
                                            or fullName:find("kia") or fullName:find("car")
                                            or aText:find("break") or aText:find("smash")
                                            or aText:find("steal") or aText:find("door")
                                        ) then
                                            -- Walk up to find the Model ancestor
                                            local model = v2.Parent
                                            while model and not model:IsA("Model") and model.Parent ~= workspace do
                                                model = model.Parent
                                            end
                                            if model and model:IsA("Model") then
                                                if not carModels[model] then
                                                    carModels[model] = {}
                                                end
                                                table.insert(carModels[model], v2)
                                            end
                                        end
                                    end
                                end

                                -- Find the NEAREST car model to avoid flying across the map
                                local nearestModel = nil
                                local nearestDist = math.huge
                                for model, _ in pairs(carModels) do
                                    local part = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
                                    if part then
                                        local dist = (part.Position - hrp.Position).Magnitude
                                        if dist < nearestDist then
                                            nearestDist = dist
                                            nearestModel = model
                                        end
                                    end
                                end

                                -- Work through ALL prompts on the nearest car only
                                if nearestModel and carModels[nearestModel] then
                                    warn("[GangWars:CarBreaking] Working car: " .. nearestModel.Name)
                                    for _, prompt in ipairs(carModels[nearestModel]) do
                                        if not Config.Game.CarBreaking then break end
                                        local part = prompt.Parent
                                        if part and part:IsA("BasePart") then
                                            Util.teleport(part.CFrame + Vector3.new(0, 0, 2))
                                            AntiDetect.randomWait(0.4, 0.8)
                                        end
                                        if prompt:IsA("ProximityPrompt") then
                                            Util.firePrompt(prompt)
                                        else
                                            pcall(function() fireclickdetector(prompt) end)
                                        end
                                        AntiDetect.randomWait(0.8, 1.5)
                                    end
                                else
                                    warn("[GangWars:CarBreaking] No breakable car found nearby!")
                                end
                            end)
                            AntiDetect.randomWait(3, 5)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "📦 Box Job Farm",
            function() return Config.Game.BoxJob end,
            function(v)
                Config.Game.BoxJob = v
                if v then
                    task.spawn(function()
                        while Config.Game.BoxJob do
                            safeCall("GangWars:BoxJob", function()
                                local hrp = Util.getHRP()
                                if not hrp then return end

                                -- BOX1 has a ClickDetector; Job object needs to be at player position
                                -- Deep search for BOX1 (may be inside folders/models, not a direct workspace child)
                                local box = nil
                                for _, _bv in ipairs(workspace:GetDescendants()) do
                                    if _bv.Name == "BOX1" then box = _bv; break end
                                end
                                local click = box and box:FindFirstChildOfClass("ClickDetector")
                                local job = workspace:FindFirstChild("Job")

                                if click and job then
                                    pcall(function()
                                        job.CFrame = hrp.CFrame
                                        fireclickdetector(click)
                                    end)
                                else
                                    warn("[GangWars:BoxJob] BOX1 or Job not found in workspace! Make sure you are in Gang Wars.")
                                end
                            end)
                            task.wait(0.05) -- Fire every frame for max speed
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "💳 Scamming / Card Farm",
            function() return Config.Game.Scamming end,
            function(v)
                Config.Game.Scamming = v
                if v then
                    task.spawn(function()
                        while Config.Game.Scamming do
                            safeCall("GangWars:Scamming", function()
                                local hrp = Util.getHRP()
                                if not hrp then return end

                                -- Scamming flow: Blank Card Seller → Data Seller → Computer → ATM Swipe
                                -- NPC names include "Punch Made Dev" or "PunchMade"
                                
                                -- Step 1: Find blank card seller (Punch Made Dev Blank card seller)
                                warn("[GangWars:Scam] Step 1: Looking for blank card seller...")
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.Scamming then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        local oText = v2.ObjectText:lower()
                                        local fullName = v2.Parent and v2.Parent:GetFullName():lower() or ""
                                        -- Only match BLANK CARD specific prompts — NOT box job, NOT gun shops
                                        if not isGunShopPrompt(v2)
                                            and not pName:find("box") and not fullName:find("box1") and not fullName:find("boxjob")
                                            and (pName:find("blank") or pName:find("card sell") or pName:find("punchmade") or pName:find("punch made")
                                            or oText:find("blank card") or oText:find("card sell")
                                            or aText:find("blank card") or aText:find("get card")
                                            or fullName:find("blank") or fullName:find("cardsell")) then
                                            warn("[GangWars:Scam] Found card source: " .. (v2.Parent and v2.Parent.Name or "?"))
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                AntiDetect.randomWait(0.3, 0.6)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.5, 1)
                                            break -- ✅ stop after FIRST match — don't fire every card seller
                                        end
                                    end
                                end

                                AntiDetect.randomWait(0.5, 1)

                                -- Step 2: Get data (Punch Made Dev data seller)
                                warn("[GangWars:Scam] Step 2: Looking for data seller...")
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.Scamming then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        local oText = v2.ObjectText:lower()
                                        local fullName = v2.Parent and v2.Parent:GetFullName():lower() or ""
                                        -- NOT gun shops (they use "swipe" too!), NOT box job
                                        if not isGunShopPrompt(v2)
                                            and not pName:find("box") and not fullName:find("box1")
                                            and (pName:find("data") or pName:find("skim") or pName:find("data sell")
                                            or aText:find("steal data") or aText:find("get data") or aText:find("skim")
                                            or oText:find("data sell") or oText:find("stolen data") or oText:find("card data")
                                            or (fullName:find("punch") and (fullName:find("data") or fullName:find("skim")))
                                            or (fullName:find("seller") and fullName:find("data"))) then
                                            warn("[GangWars:Scam] Found data source: " .. (v2.Parent and v2.Parent.Name or "?"))
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                AntiDetect.randomWait(0.3, 0.6)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.5, 1)
                                            break -- ✅ stop after FIRST match
                                        end
                                    end
                                end

                                AntiDetect.randomWait(0.5, 1)

                                -- Step 3: Put data in computer
                                warn("[GangWars:Scam] Step 3: Looking for computer...")
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.Scamming then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        local oText = v2.ObjectText:lower()
                                        if not isGunShopPrompt(v2)
                                            and not pName:find("box") and not fullName:find("box1")
                                            and (pName:find("computer") or pName:find("laptop") or pName:find("monitor") or pName:find("terminal")
                                            or aText:find("upload") or aText:find("transfer") or aText:find("encode")
                                            or oText:find("computer") or oText:find("laptop") or oText:find("terminal")) then
                                            warn("[GangWars:Scam] Found computer: " .. (v2.Parent and v2.Parent.Name or "?"))
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                AntiDetect.randomWait(0.3, 0.6)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(1, 2)
                                            break -- ✅ stop after FIRST match
                                        end
                                    end
                                end

                                AntiDetect.randomWait(0.5, 1)

                                -- Step 4: Swipe at NEAREST ATM only (not all ATMs in the map)
                                warn("[GangWars:Scam] Step 4: Looking for nearest ATM...")
                                local nearestATM = nil
                                local nearestATMDist = math.huge
                                local atmHRP = Util.getHRP()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        local oText = v2.ObjectText:lower()
                                        if pName:find("atm") or pName:find("machine") or pName:find("swipe")
                                            or aText:find("swipe") or aText:find("atm") or aText:find("withdraw") or aText:find("insert")
                                            or oText:find("atm") or oText:find("swipe") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") and atmHRP then
                                                local dist = (atmHRP.Position - part.Position).Magnitude
                                                if dist < nearestATMDist then
                                                    nearestATMDist = dist
                                                    nearestATM = v2
                                                end
                                            end
                                        end
                                    end
                                end
                                if nearestATM then
                                    local atmPart = nearestATM.Parent
                                    warn("[GangWars:Scam] Found nearest ATM: " .. (atmPart and atmPart.Name or "?") .. " (" .. math.floor(nearestATMDist) .. " studs away)")
                                    if atmPart and atmPart:IsA("BasePart") then
                                        Util.teleport(atmPart.CFrame)
                                        AntiDetect.randomWait(0.5, 1)
                                    end
                                    for attempt = 1, 10 do
                                        if not Config.Game.Scamming then break end
                                        Util.firePrompt(nearestATM)
                                        AntiDetect.randomWait(0.5, 1)
                                    end
                                else
                                    warn("[GangWars:Scam] ❌ No ATM found nearby!")
                                end
                            end)
                            AntiDetect.randomWait(2, 4)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "🏪 Store Robbery Farm",
            function() return Config.Game.StoreRobbery end,
            function(v)
                Config.Game.StoreRobbery = v
                if v then
                    task.spawn(function()
                        while Config.Game.StoreRobbery do
                            safeCall("GangWars:StoreRobbery", function()
                                local hrp = Util.getHRP()
                                if not hrp then return end

                                -- Equip a gun first (need gun to rob stores)
                                local char = game.Players.LocalPlayer.Character
                                if char then
                                    local backpack = game.Players.LocalPlayer.Backpack
                                    for _, tool in ipairs(backpack:GetChildren()) do
                                        if tool:IsA("Tool") then
                                            local name = tool.Name:lower()
                                            if name:find("glock") or name:find("gun") or name:find("pistol")
                                                or name:find("switch") or name:find("uzi") or name:find("ar")
                                                or name:find("draco") or name:find("shotgun") then
                                                char.Humanoid:EquipTool(tool)
                                                break
                                            end
                                        end
                                    end
                                end

                                AntiDetect.randomWait(0.3, 0.6)

                                -- Find store NPCs / registers to rob (gun store, gas station, etc.)
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.StoreRobbery then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        local oText = v2.ObjectText:lower()
                                        if pName:find("store") or pName:find("shop") or pName:find("register")
                                            or pName:find("cashier") or pName:find("clerk") or pName:find("npc")
                                            or pName:find("gas") or pName:find("station") or pName:find("counter")
                                            or pName:find("worker") or pName:find("employee")
                                            or aText:find("rob") or aText:find("hold") or aText:find("stick")
                                            or aText:find("steal") or aText:find("threaten") or aText:find("demand")
                                            or oText:find("rob") or oText:find("store") or oText:find("shop")
                                            or oText:find("cashier") then
                                            warn("[GangWars:Store] Robbing: " .. (v2.Parent and v2.Parent.Name or "?") .. " | " .. v2.ActionText)
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                AntiDetect.randomWait(0.5, 1)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(3, 6) -- Robberies take time
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(3, 5)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "🏴 Turf Capture Farm",
            function() return Config.Game.TurfCapture end,
            function(v)
                Config.Game.TurfCapture = v
                if v then
                    task.spawn(function()
                        while Config.Game.TurfCapture do
                            safeCall("GangWars:TurfCapture", function()
                                -- Look for turf zones (usually parts with "Turf" or "Zone" in name)
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.TurfCapture then break end
                                    if v2:IsA("BasePart") then
                                        local n = v2.Name:lower()
                                        if n:find("turf") or n:find("zone") or n:find("capture") then
                                            Util.teleport(v2.CFrame)
                                            AntiDetect.randomWait(5, 10)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(5, 10)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "📋 Mission Farm",
            function() return Config.Game.MissionFarm end,
            function(v)
                Config.Game.MissionFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.MissionFarm do
                            safeCall("GangWars:MissionFarm", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.MissionFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("mission") or pName:find("quest") or pName:find("challenge")
                                            or aText:find("start") or aText:find("accept") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.5)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(1, 2)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(3, 6)
                        end
                    end)
                end
            end)

        UI.Divider(p)
        UI.Label(p, "  AUTO ROB")
        UI.MakeToggle(p, "🏦 Auto Rob All",
            function() return Config.Game.AutoRob end,
            function(v)
                Config.Game.AutoRob = v
                if v then
                    task.spawn(function()
                        while Config.Game.AutoRob do
                            safeCall("GangWars:AutoRob", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.AutoRob then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("rob") or pName:find("safe") or pName:find("register")
                                            or pName:find("vault") or pName:find("cash")
                                            or aText:find("rob") or aText:find("steal") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.5)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(1, 3)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(5, 8)
                        end
                    end)
                end
            end)
    end)

    -- ── DEBUG SCANNER TAB ────────────────────────────────────
    UI.Tab("🔍", "Debug", function(p)
        UI.Label(p, "  DEBUG SCANNERS")

        UI.MakeButton(p, "🔍 Scan All ProximityPrompts", function()
            warn("=== PROXIMITY PROMPTS ===")
            local count = 0
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    count = count + 1
                    warn(count .. ") Parent: " .. (v.Parent and v.Parent.Name or "?") .. " | FullName: " .. (v.Parent and v.Parent:GetFullName() or "?") .. " | ActionText: " .. tostring(v.ActionText) .. " | ObjectText: " .. tostring(v.ObjectText))
                end
            end
            warn("=== TOTAL PROXIMITY PROMPTS: " .. count .. " ===")
        end)

        UI.MakeButton(p, "🔍 Scan All ClickDetectors", function()
            warn("=== CLICK DETECTORS ===")
            local count = 0
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ClickDetector") then
                    count = count + 1
                    warn(count .. ") Parent: " .. (v.Parent and v.Parent.Name or "?") .. " | FullName: " .. (v.Parent and v.Parent:GetFullName() or "?"))
                end
            end
            warn("=== TOTAL CLICK DETECTORS: " .. count .. " ===")
        end)

        UI.MakeButton(p, "🔍 Scan All RemoteEvents", function()
            warn("=== REMOTE EVENTS & FUNCTIONS ===")
            local count = 0
            for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    count = count + 1
                    warn(count .. ") " .. v.ClassName .. " | Name: " .. v.Name .. " | FullName: " .. v:GetFullName())
                end
            end
            warn("=== TOTAL REMOTES: " .. count .. " ===")
        end)

        UI.MakeButton(p, "🔍 Scan All Tools", function()
            warn("=== TOOLS IN REPLICATED STORAGE ===")
            local count = 0
            for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if v:IsA("Tool") then
                    count = count + 1
                    warn(count .. ") Name: " .. v.Name .. " | FullName: " .. v:GetFullName())
                end
            end
            warn("=== TOOLS IN WORKSPACE ===")
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Tool") then
                    count = count + 1
                    warn(count .. ") Name: " .. v.Name .. " | FullName: " .. v:GetFullName())
                end
            end
            warn("=== TOTAL TOOLS: " .. count .. " ===")
        end)

        UI.MakeButton(p, "🔍 Scan Backpack", function()
            warn("=== BACKPACK TOOLS ===")
            local count = 0
            local bp = game.Players.LocalPlayer.Backpack
            for _, v in ipairs(bp:GetChildren()) do
                if v:IsA("Tool") then
                    count = count + 1
                    warn(count .. ") Name: " .. v.Name .. " | FullName: " .. v:GetFullName())
                end
            end
            warn("=== TOTAL BACKPACK TOOLS: " .. count .. " ===")
        end)
    end)

    -- ── WEAPONS TAB ──────────────────────────────────────────
    -- Fully rewritten: FREE clone spawn + categorized dropdowns
    -- Gun names from debug scan 2026-03-30
    UI.Tab("🔫", "Weapons", function(p)

        -- ═══════════════════════════════════════════════════════
        -- FREE SPAWN: Clone gun directly into backpack (no buying!)
        -- Priority: ReplicatedStorage.Items > ReplicatedStorage.weapons > workspace Tools
        -- ═══════════════════════════════════════════════════════
        -- Prevents clicking the same gun button multiple times before the first clone lands
        local spawnInProgress = {}
        local function freeSpawnGun(gunName)
            if spawnInProgress[gunName] then
                warn("[GangWars] ⏳ Already spawning " .. gunName .. ", please wait...")
                return
            end
            spawnInProgress[gunName] = true
            safeCall("GangWars:FreeSpawn:" .. gunName, function()
                warn("[GangWars] 🆓 FREE SPAWN: " .. gunName)
                local RS = game:GetService("ReplicatedStorage")

                -- Already have it?
                if LocalPlayer.Backpack:FindFirstChild(gunName) then
                    warn("[GangWars] Already have " .. gunName .. " in backpack!")
                    return
                end
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(gunName) then
                    warn("[GangWars] Already holding " .. gunName .. "!")
                    return
                end

                -- METHOD 1: Clone from ReplicatedStorage.Items.{GunName}
                local items = RS:FindFirstChild("Items")
                if items then
                    local gunFolder = items:FindFirstChild(gunName)
                    if gunFolder then
                        -- The gun tool might be the folder itself or inside it
                        if gunFolder:IsA("Tool") then
                            gunFolder:Clone().Parent = LocalPlayer.Backpack
                            warn("[GangWars] ✅ Cloned " .. gunName .. " from RS.Items (Tool)")
                            return
                        end
                        -- Look for a Tool child inside the folder
                        for _, child in ipairs(gunFolder:GetChildren()) do
                            if child:IsA("Tool") then
                                child:Clone().Parent = LocalPlayer.Backpack
                                warn("[GangWars] ✅ Cloned " .. child.Name .. " from RS.Items." .. gunName)
                                return
                            end
                        end
                    end
                end

                -- METHOD 2: Clone from ReplicatedStorage.weapons.{GunName}
                local weapons = RS:FindFirstChild("weapons")
                if weapons then
                    local gunTool = weapons:FindFirstChild(gunName)
                    if gunTool then
                        if gunTool:IsA("Tool") then
                            gunTool:Clone().Parent = LocalPlayer.Backpack
                            warn("[GangWars] ✅ Cloned " .. gunName .. " from RS.weapons")
                            return
                        end
                        for _, child in ipairs(gunTool:GetChildren()) do
                            if child:IsA("Tool") then
                                child:Clone().Parent = LocalPlayer.Backpack
                                warn("[GangWars] ✅ Cloned " .. child.Name .. " from RS.weapons." .. gunName)
                                return
                            end
                        end
                    end
                end

                -- METHOD 3: Deep search ReplicatedStorage for exact name match
                warn("[GangWars] Searching all of ReplicatedStorage for " .. gunName .. "...")
                for _, obj in ipairs(RS:GetDescendants()) do
                    if obj:IsA("Tool") and obj.Name == gunName then
                        obj:Clone().Parent = LocalPlayer.Backpack
                        warn("[GangWars] ✅ Cloned " .. gunName .. " from " .. obj:GetFullName())
                        return
                    end
                end

                -- METHOD 4: Pickup from workspace (dropped guns)
                warn("[GangWars] Looking for dropped " .. gunName .. " in workspace...")
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Tool") and obj.Name == gunName then
                        local handle = obj:FindFirstChild("Handle")
                        if handle and handle:IsA("BasePart") then
                            Util.teleport(handle.CFrame)
                            task.wait(0.5)
                            if LocalPlayer.Backpack:FindFirstChild(gunName) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(gunName)) then
                                warn("[GangWars] ✅ Picked up " .. gunName .. " from ground!")
                                return
                            end
                        end
                    end
                end

                warn("[GangWars] ❌ Could not find " .. gunName .. " anywhere. It may be a gamepass-only gun.")
            end)
            spawnInProgress[gunName] = nil  -- release lock after spawn attempt
        end

        -- ═══════════════════════════════════════════════════════
        -- CATEGORY SYSTEM: Toggle sections to show/hide guns
        -- ═══════════════════════════════════════════════════════
        local categoryOpen = {}  -- tracks which category is open
        local categoryFrames = {} -- stores button frames per category

        local gunCategories = {
            {name = "🔫 Glocks", guns = {
                "GlockS", "GlockSwitch", "GlockGoldSwitch", "Glock 17",
                "Glock19X", "Glock19X EXT", "Glock19XSwitchVecMag",
                "Glock20", "Glock20 Drum", "Glock20 Extended",
                "Glock23 Gen5 Beam", "Glock23GreenSwitch", "Glock26EXT Switch",
                "Glock 40 Drum", "Glock150Round", "Tactical Glock",
                "Xmas GlockSwitch", "GoldSwitch",
            }},
            {name = "🔫 ARPs & Rifles", guns = {
                "FullyARP", "FullyMicroArp", "GhostARP", "ValentinesFullyARP",
                "Neon ARPFully 1 Tap", "M4Carbine", "M6Gun", "MK18",
                "5.56", "Tan ArDrum",
            }},
            {name = "🔫 Uzis", guns = {
                "Xmas UZI", "Halloween UZI", "MrBeast UZI", "GoldUZI",
            }},
            {name = "🔫 Dracos", guns = {
                "Micro Draco", "Mini Draco", "Fully Draco", "GoldDraco",
                "GoldDracoDrum", "SkullFullyDraco", "XmasDracoSwitch",
                "BlackOut Micro Draco",
            }},
            {name = "🔫 Switches", guns = {
                "P80Switch", "GoldP80Switch", "HeartSwitch", "IceSpiceSwitch",
                "ValentineSwitch", "HalloweenSwitch", "100RoundSwitch",
                "2025Switch", "2026Switch", "Neon Switch 1 Tap",
                "SquidGamesSwitch", "YNS Switch", "DOASwitch",
                "200RMoneySwitch", "200REasterSwitch",
            }},
            {name = "🔫 Fullys", guns = {
                "GhostFully", "FullyBlu", "MrBeast Fully", "SkullDeagleFully",
                "100RoundFully", "100RoundXmas", "Xmas 80RndFully",
                "Halloween100Fully", "HalloweenTecFully", "XmasTecFully",
                "July100RndFully", "Lucky 150RFully", "Lucky 85RSwitch",
                "150REasterFully", "200RMoneyFully", "SquidGamesFully",
            }},
            {name = "🔫 SMGs & Pistols", guns = {
                "Mac10", "MP5", "MP9", "MPX", "Tec-9", "Christmas Tec-9",
                "FN57", "FiveSeven", "S&W", "Taurus G2C", "Taurus Drum",
                "DeagleDrum", "Beretta", "StandardMag", "ExtendedMag",
                "DrumMag", "100RNDFN",
            }},
            {name = "🔫 Shotguns & Heavy", guns = {
                "Auto Shotgun", "2026 Shotgun", "MiniGun",
                "MiniGun Ammo", "RayGun",
            }},
            {name = "🔫 Specials", guns = {
                "Axe", "C4", "SpringfieldXD",
            }},
        }

        UI.Label(p, "  🆓 FREE GUN SPAWNER")
        UI.Label(p, "  Tap a category to expand, then tap a gun to spawn it FREE!")
        UI.Divider(p)

        for catIdx, cat in ipairs(gunCategories) do
            local catKey = "cat_" .. catIdx
            categoryOpen[catKey] = false

            -- Category header button (acts as dropdown toggle)
            UI.MakeButton(p, cat.name .. "  ▶  (" .. #cat.guns .. " guns)", function()
                categoryOpen[catKey] = not categoryOpen[catKey]
                local isOpen = categoryOpen[catKey]

                -- Toggle visibility of gun buttons in this category
                if categoryFrames[catKey] then
                    for _, btn in ipairs(categoryFrames[catKey]) do
                        pcall(function() btn.Visible = isOpen end)
                    end
                end

                warn("[GangWars] " .. cat.name .. (isOpen and " OPENED" or " CLOSED"))
            end)

            -- Create all gun buttons (hidden by default)
            categoryFrames[catKey] = {}
            for _, gunName in ipairs(cat.guns) do
                local btn = UI.MakeButton(p, "    ├─ " .. gunName, function()
                    freeSpawnGun(gunName)
                end)
                -- Hide by default (dropdown closed)
                pcall(function()
                    if btn and typeof(btn) == "Instance" then
                        btn.Visible = false
                        table.insert(categoryFrames[catKey], btn)
                    end
                end)
            end
        end

        UI.Divider(p)
        UI.Label(p, "  🛠️ TOOL MODS")

        UI.MakeToggle(p, "♻️ Gun Dupe",
            function() return Config.Game.GunDupe end,
            function(v)
                Config.Game.GunDupe = v
                if v then
                    task.spawn(function()
                        while Config.Game.GunDupe do
                            pcall(function()
                                local char = LocalPlayer.Character
                                if char then
                                    local tool = char:FindFirstChildOfClass("Tool")
                                    if tool then tool:Clone().Parent = LocalPlayer.Backpack end
                                end
                            end)
                            task.wait(1)
                        end
                    end)
                end
            end)

        UI.MakeButton(p, "🗑️ Drop All Guns", function()
            safeCall("GangWars:DropAll", function()
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name ~= "Fists" then
                        tool.Parent = workspace
                    end
                end
                if LocalPlayer.Character then
                    for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name ~= "Fists" then
                            tool.Parent = workspace
                        end
                    end
                end
                warn("[GangWars] Dropped all guns!")
            end)
        end)

        UI.MakeButton(p, "🔄 Spawn ALL Guns (Clone Everything)", function()
            safeCall("GangWars:SpawnAll", function()
                warn("[GangWars] Spawning ALL guns from ReplicatedStorage...")
                local RS = game:GetService("ReplicatedStorage")
                local count = 0
                -- Try Items folder
                local items = RS:FindFirstChild("Items")
                if items then
                    for _, obj in ipairs(items:GetChildren()) do
                        if obj:IsA("Tool") and not LocalPlayer.Backpack:FindFirstChild(obj.Name) then
                            obj:Clone().Parent = LocalPlayer.Backpack
                            count = count + 1
                        end
                    end
                end
                -- Try weapons folder
                local weapons = RS:FindFirstChild("weapons")
                if weapons then
                    for _, obj in ipairs(weapons:GetChildren()) do
                        if obj:IsA("Tool") and not LocalPlayer.Backpack:FindFirstChild(obj.Name) then
                            obj:Clone().Parent = LocalPlayer.Backpack
                            count = count + 1
                        end
                    end
                end
                warn("[GangWars] ✅ Spawned " .. count .. " guns FREE!")
            end)
        end)
    end)

    -- ── TELEPORT TAB ─────────────────────────────────────────
    UI.Tab("📍", "Teleport", function(p)
        UI.Label(p, "  LOCATIONS")

        -- Auto-discover
        local discovered = {}
        pcall(function()
            for _, folder in ipairs(workspace:GetChildren()) do
                if folder:IsA("Folder") and (folder.Name:lower():find("location") or folder.Name:lower():find("teleport")) then
                    for _, loc in ipairs(folder:GetChildren()) do
                        if loc:IsA("BasePart") then
                            table.insert(discovered, {loc.Name, loc.CFrame})
                        end
                    end
                end
            end
        end)

        if #discovered > 0 then
            UI.Label(p, "  DETECTED SPOTS")
            for _, data in ipairs(discovered) do
                UI.MakeButton(p, "📌 " .. data[1], function() Util.teleport(data[2]) end)
            end
        end

        UI.Divider(p)
        UI.MakeButton(p, "🔍 Scan All Prompts", function()
            local count = 0
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    count = count + 1
                    if count <= 50 then
                        print("[GangWars] " .. (v.Parent and v.Parent.Name or "?") .. " | " .. v.ActionText)
                    end
                end
            end
            print("[GangWars] Total prompts: " .. count)
        end)
    end)

    -- ── LOOT TAB ─────────────────────────────────────────────
    UI.Tab("💰", "Loot", function(p)
        UI.Label(p, "  LOOTING")
        UI.MakeToggle(p, "💼 Auto Store to Safe",
            function() return Config.Game.AutoStore end,
            function(v)
                Config.Game.AutoStore = v
                if v then
                    task.spawn(function()
                        while Config.Game.AutoStore do
                            safeCall("GangWars:AutoStore", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local aText = v2.ActionText:lower()
                                        if aText:find("store") or aText:find("deposit") or aText:find("stash") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                local hrp = Util.getHRP()
                                                if hrp and (part.Position - hrp.Position).Magnitude < 50 then
                                                    Util.firePrompt(v2)
                                                end
                                            end
                                        end
                                    end
                                end
                            end)
                            task.wait(5)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "🔒 Safe ESP",
            function() return Config.Game.SafeESP end,
            function(v)
                Config.Game.SafeESP = v
                if not v then
                    for _, x in ipairs(workspace:GetDescendants()) do
                        if x.Name == "_SafeGlow" then x:Destroy() end
                    end
                end
            end)
    end)

    -- Safe ESP engine addition
    task.spawn(function()
        while task.wait(1) do
            if Config.Game.SafeESP then
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v:FindFirstChild("_SafeGlow") then
                        local n = v.Name:lower()
                        if n:find("safe") or n:find("vault") or n:find("stash") then
                            local h = Instance.new("Highlight", v)
                            h.Name = "_SafeGlow"
                            h.FillColor = Color3.fromRGB(0, 200, 255)
                            h.OutlineColor = Color3.fromRGB(0, 100, 255)
                            h.FillTransparency = 0.4
                        end
                    end
                end
            end
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════
-- // GAME MODULE: CENTRAL STREETS (PlaceId: 121567535120062)
-- ═══════════════════════════════════════════════════════════════
function loadCentralStreets(UI, Config, Util, safeCall, AntiDetect)
    Config.Game = {
        PrinterFarm = false,
        GrowFarm = false,
        ChopShopFarm = false,
        CardSwipeFarm = false,
        AutoRob = false,
        GunDupe = false,
        DirtyCashConvert = false,
        AutoSell = false,
        CameraESP = false,
    }

    -- ── AUTOFARM TAB ─────────────────────────────────────────
    UI.Tab("🌾", "AutoFarm", function(p)
        UI.Label(p, "  MONEY METHODS")

        -- Printer Autofarm
        UI.MakeToggle(p, "🖨️ Printer / Paper Farm",
            function() return Config.Game.PrinterFarm end,
            function(v)
                Config.Game.PrinterFarm = v
                if v then
                    task.spawn(function()
                        local player = game:GetService("Players").LocalPlayer
                        while Config.Game.PrinterFarm do
                            safeCall("CentralSt:PrinterFarm", function()
                                local allPrompts = workspace:GetDescendants()

                                -- Helper: find a prompt matching keywords
                                local function findPrompt(keywords, blockKeywords)
                                    for _, v2 in ipairs(allPrompts) do
                                        if v2:IsA("ProximityPrompt") then
                                            local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                            local aText = v2.ActionText:lower()
                                            local combined = pName .. " " .. aText
                                            local blocked = false
                                            if blockKeywords then
                                                for _, bk in ipairs(blockKeywords) do
                                                    if combined:find(bk) then blocked = true break end
                                                end
                                            end
                                            if not blocked then
                                                for _, kw in ipairs(keywords) do
                                                    if combined:find(kw) then return v2 end
                                                end
                                            end
                                        end
                                    end
                                    return nil
                                end

                                -- Helper: teleport to prompt and fire it
                                local function goFire(prompt, waitAfter)
                                    if not prompt then return false end
                                    local part = prompt.Parent
                                    if part and part:IsA("BasePart") then
                                        Util.teleport(part.CFrame * CFrame.new(0, 0, -3))
                                        task.wait(1.5)
                                    end
                                    Util.firePrompt(prompt)
                                    task.wait(waitAfter or 2)
                                    return true
                                end

                                -- STEP 1: Buy printer
                                -- Use broad "printer" keyword since combined = pName + aText
                                -- e.g. parent "Printer" + action "Buy" = "printer buy" (not "buy printer")
                                local printerBuyPrompt = findPrompt(
                                    {"printer"},
                                    {"collect", "paper", "substrate"}
                                )
                                if printerBuyPrompt then
                                    warn("[CentralSt:Printer] Step 1: Buying printer...")
                                    goFire(printerBuyPrompt, 2)
                                else
                                    warn("[CentralSt:Printer] Step 1: No buy printer prompt found — checking if already owned")
                                end

                                if not Config.Game.PrinterFarm then return end

                                -- STEP 2: Buy substrate paper
                                local paperPrompt = findPrompt(
                                    {"substrate", "paper", "buy paper", "get paper", "purchase paper"},
                                    {"collect", "printer money"}
                                )
                                if paperPrompt then
                                    warn("[CentralSt:Printer] Step 2: Buying substrate paper...")
                                    goFire(paperPrompt, 2)
                                else
                                    warn("[CentralSt:Printer] Step 2: No paper prompt found")
                                end

                                if not Config.Game.PrinterFarm then return end

                                -- STEP 3: Place printer (equip tool from backpack and activate)
                                -- Fixed: search backpack manually to avoid operator precedence bug
                                local printerTool = nil
                                for _, t in ipairs(player.Backpack:GetChildren()) do
                                    if t:IsA("Tool") and t.Name:lower():find("printer") then
                                        printerTool = t
                                        break
                                    end
                                end
                                if printerTool then
                                    warn("[CentralSt:Printer] Step 3: Placing printer tool...")
                                    printerTool.Parent = player.Character
                                    task.wait(0.5)
                                    -- Try to activate the tool to place it
                                    pcall(function() printerTool:Activate() end)
                                    task.wait(2)
                                else
                                    warn("[CentralSt:Printer] Step 3: No printer tool in backpack")
                                end

                                if not Config.Game.PrinterFarm then return end

                                -- STEP 4: Wait for printer to fill up with money
                                warn("[CentralSt:Printer] Step 4: Waiting 30s for printer to fill...")
                                for i = 1, 30 do
                                    if not Config.Game.PrinterFarm then return end
                                    task.wait(1)
                                end

                                -- STEP 5: Collect money from placed printer
                                -- Refresh descendants to find placed printer
                                allPrompts = workspace:GetDescendants()
                                local collectPrompt = findPrompt(
                                    {"collect", "collect money", "take money", "grab money"},
                                    {"buy", "purchase"}
                                )
                                if collectPrompt then
                                    warn("[CentralSt:Printer] Step 5: Collecting money!")
                                    goFire(collectPrompt, 2)
                                else
                                    warn("[CentralSt:Printer] Step 5: No collect prompt found")
                                end
                            end)
                            AntiDetect.randomWait(5, 8)
                        end
                    end)
                end
            end)

        -- Growing Autofarm
        UI.MakeToggle(p, "🌿 Growing / Plant Farm",
            function() return Config.Game.GrowFarm end,
            function(v)
                Config.Game.GrowFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.GrowFarm do
                            safeCall("CentralSt:GrowFarm", function()
                                local prompts = {}
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("grow") or pName:find("plant") or pName:find("seed")
                                            or pName:find("weed") or pName:find("pot")
                                            or aText:find("plant") or aText:find("harvest") or aText:find("water")
                                            or aText:find("pick") or aText:find("grow") then
                                            table.insert(prompts, v2)
                                        end
                                    end
                                end
                                warn("[CentralSt:Grow] Found " .. #prompts .. " grow prompts")
                                for _, v2 in ipairs(prompts) do
                                    if not Config.Game.GrowFarm then break end
                                    local part = v2.Parent
                                    if part and part:IsA("BasePart") then
                                        Util.teleport(part.CFrame)
                                        task.wait(1.5)
                                    end
                                    Util.firePrompt(v2)
                                    AntiDetect.randomWait(1.5, 3.0)
                                end
                            end)
                            AntiDetect.randomWait(5, 8)
                        end
                    end)
                end
            end)

        -- Chop Shop Autofarm
        UI.MakeToggle(p, "🔧 Chop Shop Farm",
            function() return Config.Game.ChopShopFarm end,
            function(v)
                Config.Game.ChopShopFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.ChopShopFarm do
                            safeCall("CentralSt:ChopShop", function()
                                local prompts = {}
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("chop") or pName:find("strip") or pName:find("disassemble")
                                            or aText:find("chop") or aText:find("strip") or aText:find("dismantle") then
                                            table.insert(prompts, v2)
                                        end
                                    end
                                end
                                warn("[CentralSt:ChopShop] Found " .. #prompts .. " chop prompts")
                                for _, v2 in ipairs(prompts) do
                                    if not Config.Game.ChopShopFarm then break end
                                    local part = v2.Parent
                                    if part and part:IsA("BasePart") then
                                        Util.teleport(part.CFrame)
                                        task.wait(1.5)
                                    end
                                    Util.firePrompt(v2)
                                    AntiDetect.randomWait(2.0, 3.5)
                                end
                            end)
                            AntiDetect.randomWait(5, 8)
                        end
                    end)
                end
            end)

        -- Card Swipe (3-step: Blank Card → Load Data → ATM)
        UI.MakeToggle(p, "💳 Card Swipe Farm",
            function() return Config.Game.CardSwipeFarm end,
            function(v)
                Config.Game.CardSwipeFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.CardSwipeFarm do
                            safeCall("CentralSt:CardSwipe", function()
                                local root = game.Players.LocalPlayer.Character
                                    and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if not root then return end

                                -- Step 1: Buy blank card from card seller
                                warn("[CentralSt:Card] Step 1: Looking for blank card seller...")
                                local cardPrompt = nil
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        -- Only match card seller NPCs, NOT ATMs or loaders
                                        if (pName:find("card seller") or pName:find("blank card") or pName:find("card shop")
                                            or aText:find("buy card") or aText:find("blank card") or aText:find("get card"))
                                            and not pName:find("atm") and not aText:find("swipe") and not aText:find("withdraw") then
                                            cardPrompt = v2
                                            break
                                        end
                                    end
                                end
                                if cardPrompt then
                                    warn("[CentralSt:Card] Found card seller: " .. (cardPrompt.Parent and cardPrompt.Parent.Name or "?"))
                                    local part = cardPrompt.Parent
                                    if part and part:IsA("BasePart") then
                                        Util.teleport(part.CFrame)
                                        task.wait(2.0)
                                    end
                                    Util.firePrompt(cardPrompt)
                                    task.wait(3.0) -- wait for card to appear in inventory
                                else
                                    warn("[CentralSt:Card] No card seller found — check prompt names!")
                                end

                                if not Config.Game.CardSwipeFarm then return end

                                -- Step 2: Load data onto card (card reader/skimmer machine)
                                warn("[CentralSt:Card] Step 2: Looking for card loader/skimmer...")
                                local loaderPrompt = nil
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if (pName:find("skim") or pName:find("loader") or pName:find("reader") or pName:find("encoder")
                                            or aText:find("skim") or aText:find("load card") or aText:find("encode") or aText:find("write card"))
                                            and not pName:find("atm") and not aText:find("withdraw") then
                                            loaderPrompt = v2
                                            break
                                        end
                                    end
                                end
                                if loaderPrompt then
                                    warn("[CentralSt:Card] Found loader: " .. (loaderPrompt.Parent and loaderPrompt.Parent.Name or "?"))
                                    local part = loaderPrompt.Parent
                                    if part and part:IsA("BasePart") then
                                        Util.teleport(part.CFrame)
                                        task.wait(2.0)
                                    end
                                    Util.firePrompt(loaderPrompt)
                                    task.wait(3.0) -- wait for card to be activated
                                else
                                    warn("[CentralSt:Card] No card loader found — check prompt names!")
                                end

                                if not Config.Game.CardSwipeFarm then return end

                                -- Step 3: Swipe active card at ATM
                                warn("[CentralSt:Card] Step 3: Looking for ATM...")
                                local atmPrompt = nil
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("atm") or aText:find("withdraw") or aText:find("swipe card")
                                            or aText:find("insert card") then
                                            atmPrompt = v2
                                            break
                                        end
                                    end
                                end
                                if atmPrompt then
                                    warn("[CentralSt:Card] Found ATM: " .. (atmPrompt.Parent and atmPrompt.Parent.Name or "?"))
                                    local part = atmPrompt.Parent
                                    if part and part:IsA("BasePart") then
                                        Util.teleport(part.CFrame)
                                        task.wait(2.0)
                                    end
                                    Util.firePrompt(atmPrompt)
                                    task.wait(3.0)
                                else
                                    warn("[CentralSt:Card] No ATM found — check prompt names!")
                                end
                            end)
                            AntiDetect.randomWait(5, 8)
                        end
                    end)
                end
            end)

        UI.Divider(p)
        UI.Label(p, "  AUTO ROB & SELL")
        UI.MakeToggle(p, "🏦 Auto Rob All Spots",
            function() return Config.Game.AutoRob end,
            function(v)
                Config.Game.AutoRob = v
                if v then
                    task.spawn(function()
                        while Config.Game.AutoRob do
                            safeCall("CentralSt:AutoRob", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.AutoRob then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("rob") or pName:find("register") or pName:find("vault")
                                            or aText:find("rob") or aText:find("steal") or aText:find("break in") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.5)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(1, 3)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(5, 8)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "💰 Auto Convert Dirty Cash",
            function() return Config.Game.DirtyCashConvert end,
            function(v)
                Config.Game.DirtyCashConvert = v
                if v then
                    task.spawn(function()
                        while Config.Game.DirtyCashConvert do
                            safeCall("CentralSt:DirtyCash", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("dirty") or pName:find("laund") or pName:find("wash")
                                            or aText:find("convert") or aText:find("clean") or aText:find("laund") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.5)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(1, 2)
                                        end
                                    end
                                end
                            end)
                            task.wait(8)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "🏪 Auto Sell Items",
            function() return Config.Game.AutoSell end,
            function(v)
                Config.Game.AutoSell = v
                if v then
                    task.spawn(function()
                        while Config.Game.AutoSell do
                            safeCall("CentralSt:AutoSell", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local aText = v2.ActionText:lower()
                                        if aText:find("sell") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.5)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.5, 1)
                                        end
                                    end
                                end
                            end)
                            task.wait(5)
                        end
                    end)
                end
            end)
    end)

    -- ── WEAPONS TAB ──────────────────────────────────────────
    UI.Tab("🔫", "Weapons", function(p)
        UI.Label(p, "  GUN SPAWNER (200+ GUNS)")

        -- Organized by category
        local categories = {
            {"🔫 PISTOLS", {"Glock", "Glock18", "Deagle", "Revolver", "M9", "FiveSeven", "P250", "USP"}},
            {"🔫 SMGS", {"Uzi", "Mac10", "MP5", "MP7", "P90", "Vector", "UMP45"}},
            {"🔫 RIFLES", {"AK47", "AR15", "M4A1", "SCAR", "G36C", "AUG", "Famas", "M16"}},
            {"🔫 SHOTGUNS", {"Shotgun", "SPAS12", "Mossberg", "AA12", "DB", "Pump"}},
            {"🔫 HEAVY", {"Draco", "Choppa", "RPG", "Minigun", "LMG", "M60"}},
            {"🔫 SNIPER", {"Sniper", "AWP", "Barrett", "SVD", "Scout"}},
            {"🔪 MELEE", {"Knife", "Bat", "Machete", "Sword", "Axe", "Hammer"}},
        }

        for _, cat in ipairs(categories) do
            UI.Label(p, "  " .. cat[1])
            for _, gunName in ipairs(cat[2]) do
                UI.MakeButton(p, "  → " .. gunName, function()
                    safeCall("CentralSt:SpawnGun:" .. gunName, function()
                        local gun = game:GetService("ReplicatedStorage"):FindFirstChild(gunName, true)
                        if gun and gun:IsA("Tool") then
                            gun:Clone().Parent = LocalPlayer.Backpack
                            return
                        end
                        for _, v in ipairs(workspace:GetDescendants()) do
                            if v:IsA("Tool") and v.Name:lower() == gunName:lower() then
                                v:Clone().Parent = LocalPlayer.Backpack
                                return
                            end
                        end
                        for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                            if remote:IsA("RemoteEvent") then
                                local rn = remote.Name:lower()
                                if rn:find("give") or rn:find("gun") or rn:find("spawn") or rn:find("weapon") then
                                    remote:FireServer(gunName)
                                    return
                                end
                            end
                        end
                    end)
                end)
            end
        end

        UI.Divider(p)
        UI.MakeToggle(p, "♻️ Gun Dupe",
            function() return Config.Game.GunDupe end,
            function(v)
                Config.Game.GunDupe = v
                if v then
                    task.spawn(function()
                        while Config.Game.GunDupe do
                            pcall(function()
                                local char = LocalPlayer.Character
                                if char then
                                    local tool = char:FindFirstChildOfClass("Tool")
                                    if tool then tool:Clone().Parent = LocalPlayer.Backpack end
                                end
                            end)
                            task.wait(1)
                        end
                    end)
                end
            end)
    end)

    -- ── TELEPORT TAB ─────────────────────────────────────────
    UI.Tab("📍", "Teleport", function(p)
        UI.Label(p, "  LOCATIONS")

        local discovered = {}
        pcall(function()
            for _, folder in ipairs(workspace:GetChildren()) do
                if folder:IsA("Folder") or folder:IsA("Model") then
                    local n = folder.Name:lower()
                    if n:find("location") or n:find("teleport") or n:find("spot") then
                        for _, loc in ipairs(folder:GetChildren()) do
                            if loc:IsA("BasePart") then
                                table.insert(discovered, {loc.Name, loc.CFrame})
                            end
                        end
                    end
                end
            end
        end)

        if #discovered > 0 then
            for _, data in ipairs(discovered) do
                UI.MakeButton(p, "📌 " .. data[1], function() Util.teleport(data[2]) end)
            end
        end

        UI.Divider(p)
        UI.MakeButton(p, "🔍 Scan Workspace Structure", function()
            for _, v in ipairs(workspace:GetChildren()) do
                print("[CentralSt] " .. v.ClassName .. ": " .. v.Name)
            end
        end)
    end)

    -- ── MISC TAB ─────────────────────────────────────────────
    UI.Tab("⚙️", "Misc", function(p)
        UI.Label(p, "  EXTRAS")

        UI.MakeToggle(p, "📷 Camera / Cop ESP",
            function() return Config.Game.CameraESP end,
            function(v)
                Config.Game.CameraESP = v
                if not v then
                    for _, x in ipairs(workspace:GetDescendants()) do
                        if x.Name == "_CamGlow" then x:Destroy() end
                    end
                end
            end)

        UI.MakeButton(p, "📋 List All RemoteEvents", function()
            for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    print("[CentralSt] " .. v:GetFullName())
                end
            end
        end)

        UI.MakeButton(p, "📋 List All Tools in RS", function()
            for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if v:IsA("Tool") then
                    print("[CentralSt] Tool: " .. v.Name .. " @ " .. v:GetFullName())
                end
            end
        end)
    end)

    -- Camera ESP engine
    task.spawn(function()
        while task.wait(1) do
            if Config.Game.CameraESP then
                for _, v in ipairs(workspace:GetDescendants()) do
                    if not v:FindFirstChild("_CamGlow") then
                        local n = v.Name:lower()
                        if (n:find("camera") or n:find("cctv") or n:find("security"))
                            and (v:IsA("BasePart") or v:IsA("Model")) then
                            local h = Instance.new("Highlight", v)
                            h.Name = "_CamGlow"
                            h.FillColor = Color3.fromRGB(255, 100, 0)
                            h.OutlineColor = Color3.fromRGB(255, 50, 0)
                            h.FillTransparency = 0.3
                        end
                    end
                end
            end
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════
-- // GAME MODULE: PHILLY STREETZ 2 (PlaceId: 130700367963690)
-- ═══════════════════════════════════════════════════════════════
function loadPhillyStreetz(UI, Config, Util, safeCall, AntiDetect)
    Config.Game = {
        HeistFarm = false,
        HustleFarm = false,
        JobFarm = false,
        LootSpotFarm = false,
        AutoRob = false,
        GunDupe = false,
        AutoSafeStorage = false,
        SwipeSlide = false,
        GummyFarm = false,
    }

    -- ── AUTOFARM TAB ─────────────────────────────────────────
    UI.Tab("🌾", "AutoFarm", function(p)
        UI.Label(p, "  MONEY METHODS")

        -- Heist Autofarm
        UI.MakeToggle(p, "🏦 Heist Autofarm",
            function() return Config.Game.HeistFarm end,
            function(v)
                Config.Game.HeistFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.HeistFarm do
                            safeCall("Philly:HeistFarm", function()
                                -- Find heist location
                                local heistPart = nil
                                pcall(function()
                                    heistPart = workspace:WaitForChild("Locations", 2)
                                    if heistPart then heistPart = heistPart:FindFirstChild("Heist") end
                                end)

                                if heistPart and heistPart:IsA("BasePart") then
                                    Util.teleport(heistPart.CFrame)
                                    task.wait(0.5)
                                end

                                -- Fire all heist-related prompts
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.HeistFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("heist") or pName:find("vault") or pName:find("safe")
                                            or pName:find("drill") or pName:find("hack")
                                            or aText:find("heist") or aText:find("rob") or aText:find("crack")
                                            or aText:find("drill") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.5)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.5, 1.5)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(5, 10)
                        end
                    end)
                end
            end)

        -- Street Hustle Farm
        UI.MakeToggle(p, "🏪 Street Hustle Farm",
            function() return Config.Game.HustleFarm end,
            function(v)
                Config.Game.HustleFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.HustleFarm do
                            safeCall("Philly:HustleFarm", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.HustleFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("hustle") or pName:find("deal") or pName:find("sell")
                                            or pName:find("corner") or pName:find("trap")
                                            or aText:find("hustle") or aText:find("deal") or aText:find("serve") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.3)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.5, 1.0)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(2, 4)
                        end
                    end)
                end
            end)

        -- Job Farm
        UI.MakeToggle(p, "💼 Job / Work Farm",
            function() return Config.Game.JobFarm end,
            function(v)
                Config.Game.JobFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.JobFarm do
                            safeCall("Philly:JobFarm", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.JobFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("job") or pName:find("work") or pName:find("deliver")
                                            or pName:find("task") or pName:find("mission")
                                            or aText:find("start job") or aText:find("work") or aText:find("deliver")
                                            or aText:find("complete") or aText:find("accept") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.5)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.5, 1.5)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(3, 6)
                        end
                    end)
                end
            end)

        -- Loot Spot Farm
        UI.MakeToggle(p, "📦 Loot Spot Farm",
            function() return Config.Game.LootSpotFarm end,
            function(v)
                Config.Game.LootSpotFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.LootSpotFarm do
                            safeCall("Philly:LootSpots", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.LootSpotFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("loot") or pName:find("crate") or pName:find("box")
                                            or pName:find("bag") or pName:find("chest") or pName:find("stash")
                                            or aText:find("loot") or aText:find("pick up") or aText:find("search")
                                            or aText:find("collect") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.3)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.3, 0.8)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(2, 4)
                        end
                    end)
                end
            end)

        UI.Divider(p)
        UI.Label(p, "  CARD & GUMMY")

        UI.MakeToggle(p, "💳 Swipe & Slide Farm",
            function() return Config.Game.SwipeSlide end,
            function(v)
                Config.Game.SwipeSlide = v
                if v then
                    task.spawn(function()
                        while Config.Game.SwipeSlide do
                            safeCall("Philly:SwipeSlide", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.SwipeSlide then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("card") or pName:find("swipe") or pName:find("atm")
                                            or pName:find("slide") or pName:find("credit")
                                            or aText:find("swipe") or aText:find("card") or aText:find("slide") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.4)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.6, 1.5)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(2, 4)
                        end
                    end)
                end
            end)

        UI.MakeToggle(p, "🍬 Gummy / Item Farm",
            function() return Config.Game.GummyFarm end,
            function(v)
                Config.Game.GummyFarm = v
                if v then
                    task.spawn(function()
                        while Config.Game.GummyFarm do
                            safeCall("Philly:GummyFarm", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.GummyFarm then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if not isGunShopPrompt(v2) and (pName:find("gummy") or pName:find("candy") or pName:find("item")
                                            or pName:find("pickup") or pName:find("special")
                                            or aText:find("gummy") or aText:find("take") or aText:find("grab")) then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.3)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(0.4, 0.8)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(2, 5)
                        end
                    end)
                end
            end)
    end)

    -- ── WEAPONS TAB ──────────────────────────────────────────
    UI.Tab("🔫", "Weapons", function(p)
        UI.Label(p, "  FIREARMS & SWITCHES")

        local weapons = {
            {"🔫 PISTOLS", {"Glock", "Glock18", "Deagle", "M9", "P250", "Revolver", "FiveSeven"}},
            {"🔫 SMGS", {"Uzi", "Mac10", "MP5", "MP7", "Vector", "P90"}},
            {"🔫 RIFLES", {"AK47", "AR15", "M4A1", "SCAR", "Draco", "Choppa"}},
            {"🔫 SHOTGUNS", {"Shotgun", "SPAS12", "Pump", "Mossberg", "DB"}},
            {"🔫 HEAVY", {"RPG", "Minigun", "LMG"}},
            {"🔪 MELEE", {"Knife", "Bat", "Machete", "Switch"}},
        }

        for _, cat in ipairs(weapons) do
            UI.Label(p, "  " .. cat[1])
            for _, gunName in ipairs(cat[2]) do
                UI.MakeButton(p, "  → " .. gunName, function()
                    safeCall("Philly:SpawnGun:" .. gunName, function()
                        local gun = game:GetService("ReplicatedStorage"):FindFirstChild(gunName, true)
                        if gun and gun:IsA("Tool") then
                            gun:Clone().Parent = LocalPlayer.Backpack
                            return
                        end
                        for _, v in ipairs(workspace:GetDescendants()) do
                            if v:IsA("Tool") and v.Name:lower() == gunName:lower() then
                                v:Clone().Parent = LocalPlayer.Backpack
                                return
                            end
                        end
                        for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                            if remote:IsA("RemoteEvent") then
                                local rn = remote.Name:lower()
                                if rn:find("give") or rn:find("gun") or rn:find("spawn") or rn:find("weapon") then
                                    remote:FireServer(gunName)
                                    return
                                end
                            end
                        end
                    end)
                end)
            end
        end

        UI.Divider(p)
        UI.MakeToggle(p, "♻️ Gun Dupe",
            function() return Config.Game.GunDupe end,
            function(v)
                Config.Game.GunDupe = v
                if v then
                    task.spawn(function()
                        while Config.Game.GunDupe do
                            pcall(function()
                                local char = LocalPlayer.Character
                                if char then
                                    local tool = char:FindFirstChildOfClass("Tool")
                                    if tool then tool:Clone().Parent = LocalPlayer.Backpack end
                                end
                            end)
                            task.wait(1)
                        end
                    end)
                end
            end)
    end)

    -- ── TELEPORT TAB ─────────────────────────────────────────
    UI.Tab("📍", "Teleport", function(p)
        UI.Label(p, "  LOCATIONS")

        -- Auto-discover from Locations folder
        local discovered = {}
        pcall(function()
            local locs = workspace:FindFirstChild("Locations")
            if locs then
                for _, loc in ipairs(locs:GetChildren()) do
                    if loc:IsA("BasePart") then
                        table.insert(discovered, {loc.Name, loc.CFrame})
                    elseif loc:IsA("Model") and loc.PrimaryPart then
                        table.insert(discovered, {loc.Name, loc.PrimaryPart.CFrame})
                    end
                end
            end
        end)

        if #discovered > 0 then
            UI.Label(p, "  DETECTED SPOTS")
            for _, data in ipairs(discovered) do
                UI.MakeButton(p, "📌 " .. data[1], function() Util.teleport(data[2]) end)
            end
        end

        -- Also search for any named parts that look like locations
        local extraSpots = {}
        pcall(function()
            for _, v in ipairs(workspace:GetChildren()) do
                if v:IsA("Folder") or v:IsA("Model") then
                    local n = v.Name:lower()
                    if n:find("spawn") or n:find("shop") or n:find("store") or n:find("crib")
                        or n:find("dealer") or n:find("garage") then
                        local part = v:IsA("BasePart") and v or v:FindFirstChildOfClass("BasePart")
                        if part then
                            table.insert(extraSpots, {v.Name, part.CFrame})
                        end
                    end
                end
            end
        end)

        if #extraSpots > 0 then
            UI.Divider(p)
            UI.Label(p, "  OTHER SPOTS")
            for _, data in ipairs(extraSpots) do
                UI.MakeButton(p, "📌 " .. data[1], function() Util.teleport(data[2]) end)
            end
        end

        UI.Divider(p)
        UI.MakeButton(p, "🔍 Scan All Prompts", function()
            local count = 0
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    count = count + 1
                    if count <= 50 then
                        print("[Philly] " .. (v.Parent and v.Parent.Name or "?") .. " | " .. v.ActionText)
                    end
                end
            end
            print("[Philly] Total prompts: " .. count)
        end)
    end)

    -- ── SAFE / CRIB TAB ─────────────────────────────────────
    UI.Tab("🏠", "Crib", function(p)
        UI.Label(p, "  SAFE STORAGE")
        UI.MakeToggle(p, "🔒 Auto Safe Storage",
            function() return Config.Game.AutoSafeStorage end,
            function(v)
                Config.Game.AutoSafeStorage = v
                if v then
                    task.spawn(function()
                        while Config.Game.AutoSafeStorage do
                            safeCall("Philly:AutoSafe", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("safe") or pName:find("storage") or pName:find("stash")
                                            or aText:find("store") or aText:find("deposit") or aText:find("stash") then
                                            local hrp = Util.getHRP()
                                            if hrp and v2.Parent and v2.Parent:IsA("BasePart") then
                                                local dist = (v2.Parent.Position - hrp.Position).Magnitude
                                                if dist < 30 then
                                                    Util.firePrompt(v2)
                                                    task.wait(0.3)
                                                end
                                            end
                                        end
                                    end
                                end
                            end)
                            task.wait(5)
                        end
                    end)
                end
            end)

        UI.Divider(p)
        UI.Label(p, "  AUTO ROB")
        UI.MakeToggle(p, "🏦 Auto Rob All",
            function() return Config.Game.AutoRob end,
            function(v)
                Config.Game.AutoRob = v
                if v then
                    task.spawn(function()
                        while Config.Game.AutoRob do
                            safeCall("Philly:AutoRob", function()
                                for _, v2 in ipairs(workspace:GetDescendants()) do
                                    if not Config.Game.AutoRob then break end
                                    if v2:IsA("ProximityPrompt") then
                                        local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                        local aText = v2.ActionText:lower()
                                        if pName:find("rob") or pName:find("register") or pName:find("vault")
                                            or aText:find("rob") or aText:find("steal") or aText:find("break") then
                                            local part = v2.Parent
                                            if part and part:IsA("BasePart") then
                                                Util.teleport(part.CFrame)
                                                task.wait(0.5)
                                            end
                                            Util.firePrompt(v2)
                                            AntiDetect.randomWait(1, 3)
                                        end
                                    end
                                end
                            end)
                            AntiDetect.randomWait(5, 8)
                        end
                    end)
                end
            end)

        UI.Divider(p)
        UI.Label(p, "  DEBUG")
        UI.MakeButton(p, "📋 List All RemoteEvents", function()
            for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    print("[Philly] " .. v:GetFullName())
                end
            end
        end)

        UI.MakeButton(p, "📋 List All Tools in RS", function()
            for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if v:IsA("Tool") then
                    print("[Philly] Tool: " .. v.Name)
                end
            end
        end)

        UI.MakeButton(p, "📋 Workspace Structure", function()
            for _, v in ipairs(workspace:GetChildren()) do
                print("[Philly] " .. v.ClassName .. ": " .. v.Name)
            end
        end)
    end)
end


-- ═══════════════════════════════════════════════════════════════
-- // 13. LAUNCH
-- ═══════════════════════════════════════════════════════════════
local function Launch()
    local UI = BuildUI()

    -- Load game-specific module
    if PLACE_ID == 16472538603 then
        safeCall("LoadBronx3", loadBronx3, UI, Config, Util, safeCall, AntiDetect)
    elseif PLACE_ID == 137020602493628 then
        safeCall("LoadGangWars", loadGangWars, UI, Config, Util, safeCall, AntiDetect)
    elseif PLACE_ID == 121567535120062 then
        safeCall("LoadCentralStreets", loadCentralStreets, UI, Config, Util, safeCall, AntiDetect)
    elseif PLACE_ID == 130700367963690 then
        safeCall("LoadPhillyStreetz", loadPhillyStreetz, UI, Config, Util, safeCall, AntiDetect)
    end

    -- Open first tab
    task.defer(UI.firstTabAction)

    -- Start engine
    StartEngineLoops()

    -- Startup notification
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Hood Omni Hub v1.0",
            Text = "✅ Loaded for " .. GAME_NAME,
            Duration = 5,
        })
    end)
    print("✅ Hood Omni Hub v1.0 loaded for " .. GAME_NAME)
end

Launch()
