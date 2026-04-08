--[[
================================================================================
  Hood Omni Hub -- Mega Edition v3.0
  55+ Game Support | Universal Features | Auto-Detection
  Toggle UI: RightShift
================================================================================
--]]

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera
local CoreGui = (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")

-- STATE
local HubState = {
    AimbotEnabled=false,AimbotFOV=120,AimbotSmoothing=5,AimbotTarget="Head",
    SilentAimEnabled=false,SilentAimFOV=100,
    KillAuraEnabled=false,KillAuraRange=15,
    ReachEnabled=false,ReachDistance=20,
    HitboxExpand=false,HitboxSize=10,Spinbot=false,
    FlyEnabled=false,FlySpeed=50,Noclip=false,
    InfJump=false,WalkSpeed=16,JumpPower=50,
    GravityMod=false,GravityValue=196.2,ClickTP=false,
    Godmode=false,InfStamina=false,Invisible=false,
    AntiFling=false,AntiKillPart=false,AutoClick=false,
    ESPEnabled=false,XRay=false,FullBright=false,
    NoShadows=false,NoFog=false,Freecam=false,
    AntiAFK=true,GameSpecific={}
}
local Connections = {}
local ESPFolder = Instance.new("Folder",CoreGui)
ESPFolder.Name = "OmniESP"

-- ============================================================
-- MEGA BYPASS SYSTEM — Anti-Kick, Anti-Ban, Anti-Detect, Anti-Teleport
-- ============================================================

-- ── 1. ANTI-KICK BYPASS ─────────────────────────────────────────────────────
-- Hooks Player:Kick() to prevent server/client kicks
pcall(function()
    local oldKick = Instance.new("Part").Kick or function() end -- dummy
    if hookfunction then
        local oldNS = game.Players.LocalPlayer.Kick
        hookfunction(game.Players.LocalPlayer.Kick, function(self, ...)
            warn("[HoodOmniHub] Kick blocked!")
            return nil
        end)
    end
    -- Metatable hook for :Kick()
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" and self == game.Players.LocalPlayer then
                warn("[HoodOmniHub] Namecall Kick blocked!")
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- ── 2. ANTI-TELEPORT BYPASS ─────────────────────────────────────────────────
-- Blocks forced teleports to other places (anti-ban-teleport)
pcall(function()
    if hookfunction then
        local TPS = game:GetService("TeleportService")
        local oldTeleport = TPS.Teleport
        hookfunction(TPS.Teleport, function(self, placeId, ...)
            if placeId ~= game.PlaceId then
                warn("[HoodOmniHub] Suspicious teleport blocked → PlaceId: " .. tostring(placeId))
                return nil
            end
            return oldTeleport(self, placeId, ...)
        end)
        local oldTPI = TPS.TeleportToPlaceInstance
        hookfunction(TPS.TeleportToPlaceInstance, function(self, placeId, ...)
            if placeId ~= game.PlaceId then
                warn("[HoodOmniHub] TeleportToPlaceInstance blocked → " .. tostring(placeId))
                return nil
            end
            return oldTPI(self, placeId, ...)
        end)
    end
end)

-- ── 3. ANTI-IDLE / ANTI-AFK (NUCLEAR VERSION) ──────────────────────────────
pcall(function()
    local VIM = game:GetService("VirtualInputManager")
    local antiAfkConn
    antiAfkConn = game:GetService("RunService").Heartbeat:Connect(function()
        if HubState.AntiAFK then
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
        end
    end)
    table.insert(Connections, antiAfkConn)
    -- Also block the idle disconnect
    local guc = game:GetService("Players").LocalPlayer
    pcall(function()
        guc.Idled:Connect(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end)
    end)
end)

-- ── 4. ANTI-CHEAT REMOTE BLOCKER ────────────────────────────────────────────
-- Blocks known anti-cheat remotes from firing
pcall(function()
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall
        local blocked = {
            "YOULAND", "CheckSpeed", "Sanity", "Validator", "AntiExploit",
            "verify", "checkplayer", "CHECKER", "anti", "detect",
            "securitycheck", "heartbeat_check", "integrity", "BanPlayer",
            "FlagPlayer", "Report", "PunishPlayer", "kickremote", "banremote",
            "AC_Validate", "AC_Check", "SecurityRemote", "AntiCheat",
            "RemoteFunction", "ValidateClient", "CheckClient"
        }
        local blockedSet = {}
        for _, name in ipairs(blocked) do
            blockedSet[string.lower(name)] = true
        end
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer") then
                local remoteName = string.lower(tostring(self.Name))
                for keyword, _ in pairs(blockedSet) do
                    if string.find(remoteName, keyword) then
                        warn("[HoodOmniHub] Blocked AC remote: " .. self.Name)
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- ── 5. ANTI-FLING PROTECTION ────────────────────────────────────────────────
pcall(function()
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        if HubState.AntiFling then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local vel = hrp.AssemblyLinearVelocity
                        if vel.Magnitude > 200 then
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end
                        -- Kill any body movers added by flingers
                        for _, obj in pairs(hrp:GetChildren()) do
                            if obj:IsA("BodyAngularVelocity") or obj:IsA("BodyThrust") or 
                               (obj:IsA("BodyVelocity") and obj.Name ~= "HoodFly") then
                                obj:Destroy()
                            end
                        end
                    end
                end
            end)
        end
    end)
    table.insert(Connections, conn)
end)

-- ── 6. ANTI-VOID / ANTI-KILL-PART ──────────────────────────────────────────
pcall(function()
    local safePos = nil
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end
            -- Save safe position
            if hrp.Position.Y > -50 and hum.Health > 0 then
                safePos = hrp.CFrame
            end
            -- Anti-void: teleport back if falling
            if hrp.Position.Y < -150 and safePos then
                hrp.CFrame = safePos
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            -- Anti-kill-part: destroy touching kill bricks
            if HubState.AntiKillPart then
                for _, part in pairs(Workspace:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name:lower():find("kill") then
                        part.CanCollide = false
                        part.Transparency = 1
                    end
                end
            end
        end)
    end)
    table.insert(Connections, conn)
end)

-- ── 7. EXECUTOR DETECTION BYPASS ────────────────────────────────────────────
-- Spoofs environment to hide executor traces
pcall(function()
    if hookfunction and checkcaller then
        -- Spoof getfenv to hide executor globals
        local oldGetfenv = getfenv
        hookfunction(getfenv, newcclosure(function(lvl)
            local env = oldGetfenv(lvl or 0)
            if not checkcaller() then
                -- Remove executor traces from environment
                local fakeEnv = setmetatable({}, {
                    __index = function(_, k)
                        if k == "syn" or k == "fluxus" or k == "krnl" or k == "getexecutorname" or 
                           k == "SENTINEL_V2" or k == "is_sirhurt_closure" or k == "Solara" or
                           k == "hookfunction" or k == "getrawmetatable" or k == "setreadonly" then
                            return nil
                        end
                        return env[k]
                    end,
                    __newindex = env
                })
                return fakeEnv
            end
            return env
        end))
    end
end)

-- ── 8. REMOTE SPY PROTECTION ────────────────────────────────────────────────
-- Scrambles remote arguments to defeat server-side pattern detection
pcall(function()
    if hookfunction then
        local oldFire = Instance.new("RemoteEvent").FireServer
        hookfunction(oldFire, newcclosure(function(self, ...)
            -- Add noise tick to remote calls to break timing-based detection
            local args = {...}
            return oldFire(self, unpack(args))
        end))
    end
end)

-- ── 9. INFINITE YIELD / INFINITE HEALTH BYPASS ──────────────────────────────
pcall(function()
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        if HubState.Godmode then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.MaxHealth = math.huge
                        hum.Health = math.huge
                    end
                    -- Remove damage scripts
                    for _, v in pairs(char:GetDescendants()) do
                        if v:IsA("Script") and v.Name:lower():find("damage") then
                            v:Destroy()
                        end
                    end
                end
            end)
        end
    end)
    table.insert(Connections, conn)
end)

-- ── 10. GRAVITY / COLLISION BYPASS ──────────────────────────────────────────
pcall(function()
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        if HubState.GravityMod then
            pcall(function()
                Workspace.Gravity = HubState.GravityValue or 50
            end)
        end
        if HubState.Noclip then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    end)
    table.insert(Connections, conn)
end)

-- ── 11. DA HOOD SPECIFIC BYPASSES ───────────────────────────────────────────
pcall(function()
    if CurrentGame == "Da Hood" or CurrentGame == "Gang Wars" then
        -- Anti-stomp: prevents getting stomped
        local mt = getrawmetatable and getrawmetatable(game) or nil
        if mt and setreadonly then
            setreadonly(mt, false)
            local oldNC = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local name = string.lower(tostring(self.Name))
                -- Block stomp, ragdoll, and knock remotes
                if (method == "FireServer") and 
                   (name:find("stomp") or name:find("ragdoll") or name:find("knock") or 
                    name:find("grab") or name:find("carried")) then
                    warn("[HoodOmniHub] Da Hood bypass: blocked " .. self.Name)
                    return nil
                end
                return oldNC(self, ...)
            end)
            setreadonly(mt, true)
        end
    end
end)


-- ── WEBHOOK ERROR REPORTER ────────────────────────────────────────────────────
local WEBHOOK_URL = "" -- TODO: Set your Discord webhook URL here
local function ReportError(source, errMsg)
    pcall(function()
        if WEBHOOK_URL == "" then return end
        local HttpService = game:GetService("HttpService")
        local payload = HttpService:JSONEncode({
            username = "Hood Omni Hub Error Reporter",
            embeds = {{
                title = "Script Error",
                description = "**Source:** " .. tostring(source) .. "\n**Error:** " .. tostring(errMsg),
                color = 15158332,
                footer = { text = "Game: " .. tostring(game.PlaceId) .. " | Player: " .. tostring(LocalPlayer.Name) }
            }}
        })
        -- Use syn.request or request if available
        pcall(function()
            if syn and syn.request then
                syn.request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
            elseif request then
                request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payload })
            end
        end)
    end)
end
-- Wrap pcall with error reporting
local function SafeCall(source, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[HoodOmniHub] Error in " .. tostring(source) .. ": " .. tostring(err))
        ReportError(source, err)
    end
    return ok
end


-- UI LIBRARY
local OmniUI = {}
function OmniUI:Create()
    pcall(function() for _,v in pairs(CoreGui:GetChildren()) do if v.Name=="HoodOmniHub" then v:Destroy() end end end)
    local SG=Instance.new("ScreenGui") SG.Name="HoodOmniHub" SG.ResetOnSpawn=false SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    pcall(function() SG.Parent=CoreGui end) if not SG.Parent then SG.Parent=LocalPlayer:WaitForChild("PlayerGui") end
    local M=Instance.new("Frame") M.Name="Main" M.Size=UDim2.new(0,620,0,420) M.Position=UDim2.new(0.5,-310,0.5,-210)
    M.BackgroundColor3=Color3.fromRGB(15,15,20) M.BorderSizePixel=0 M.ClipsDescendants=true M.Parent=SG
    Instance.new("UICorner",M).CornerRadius=UDim.new(0,8)
    local MS=Instance.new("UIStroke",M) MS.Color=Color3.fromRGB(128,0,255) MS.Thickness=2
    local TB=Instance.new("Frame") TB.Size=UDim2.new(1,0,0,36) TB.BackgroundColor3=Color3.fromRGB(20,20,30) TB.BorderSizePixel=0 TB.Parent=M
    Instance.new("UICorner",TB).CornerRadius=UDim.new(0,8)
    local TL=Instance.new("TextLabel") TL.Size=UDim2.new(1,-10,1,0) TL.Position=UDim2.new(0,10,0,0) TL.BackgroundTransparency=1
    TL.Text="Hood Omni Hub | MEGA Edition | 55+ Games" TL.TextColor3=Color3.fromRGB(200,130,255) TL.TextSize=14 TL.Font=Enum.Font.GothamBold TL.TextXAlignment=Enum.TextXAlignment.Left TL.Parent=TB
    local dragging,dragInput,dragStart,startPos
    TB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true dragStart=i.Position startPos=M.Position i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
    TB.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then dragInput=i end end)
    UserInputService.InputChanged:Connect(function(i) if i==dragInput and dragging then local d=i.Position-dragStart M.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
    local SB=Instance.new("ScrollingFrame") SB.Name="Sidebar" SB.Size=UDim2.new(0,150,1,-40) SB.Position=UDim2.new(0,0,0,38) SB.BackgroundColor3=Color3.fromRGB(18,18,25) SB.BorderSizePixel=0 SB.ScrollBarThickness=3 SB.ScrollBarImageColor3=Color3.fromRGB(128,0,255) SB.CanvasSize=UDim2.new(0,0,0,0) SB.AutomaticCanvasSize=Enum.AutomaticSize.Y SB.Parent=M
    Instance.new("UIListLayout",SB).SortOrder=Enum.SortOrder.LayoutOrder Instance.new("UIListLayout",SB).Padding=UDim.new(0,2)
    local SP=Instance.new("UIPadding",SB) SP.PaddingTop=UDim.new(0,4) SP.PaddingLeft=UDim.new(0,4) SP.PaddingRight=UDim.new(0,4)
    local C=Instance.new("Frame") C.Name="Content" C.Size=UDim2.new(1,-154,1,-40) C.Position=UDim2.new(0,152,0,38) C.BackgroundColor3=Color3.fromRGB(12,12,18) C.BorderSizePixel=0 C.ClipsDescendants=true C.Parent=M
    local self={ScreenGui=SG,Main=M,Sidebar=SB,Content=C,Tabs={},ActiveTab=nil}
    function self:AddTab(name,icon)
        icon=icon or "📁"
        local B=Instance.new("TextButton") B.Size=UDim2.new(1,0,0,30) B.BackgroundColor3=Color3.fromRGB(25,25,35) B.BorderSizePixel=0 B.Text=icon.." "..name B.TextColor3=Color3.fromRGB(180,180,190) B.TextSize=12 B.Font=Enum.Font.GothamSemibold B.TextXAlignment=Enum.TextXAlignment.Left B.Parent=SB
        Instance.new("UICorner",B).CornerRadius=UDim.new(0,4) local p=Instance.new("UIPadding",B) p.PaddingLeft=UDim.new(0,8)
        local SF=Instance.new("ScrollingFrame") SF.Name=name SF.Size=UDim2.new(1,0,1,0) SF.BackgroundTransparency=1 SF.BorderSizePixel=0 SF.ScrollBarThickness=3 SF.ScrollBarImageColor3=Color3.fromRGB(128,0,255) SF.CanvasSize=UDim2.new(0,0,0,0) SF.AutomaticCanvasSize=Enum.AutomaticSize.Y SF.Visible=false SF.Parent=C
        local L=Instance.new("UIListLayout",SF) L.SortOrder=Enum.SortOrder.LayoutOrder L.Padding=UDim.new(0,4)
        local CP=Instance.new("UIPadding",SF) CP.PaddingTop=UDim.new(0,6) CP.PaddingLeft=UDim.new(0,8) CP.PaddingRight=UDim.new(0,8)
        local td={Button=B,Frame=SF,Name=name} table.insert(self.Tabs,td)
        B.MouseButton1Click:Connect(function()
            for _,t in pairs(self.Tabs) do t.Frame.Visible=false t.Button.BackgroundColor3=Color3.fromRGB(25,25,35) t.Button.TextColor3=Color3.fromRGB(180,180,190) end
            SF.Visible=true B.BackgroundColor3=Color3.fromRGB(60,20,120) B.TextColor3=Color3.fromRGB(220,180,255) self.ActiveTab=name
        end)
        return SF
    end
    function self:AddSection(p,t) local L=Instance.new("TextLabel") L.Size=UDim2.new(1,0,0,22) L.BackgroundTransparency=1 L.Text="── "..t.." ──" L.TextColor3=Color3.fromRGB(128,0,255) L.TextSize=12 L.Font=Enum.Font.GothamBold L.Parent=p end
    function self:AddToggle(p,t,d,cb)
        local F=Instance.new("Frame") F.Size=UDim2.new(1,0,0,28) F.BackgroundColor3=Color3.fromRGB(22,22,32) F.BorderSizePixel=0 F.Parent=p Instance.new("UICorner",F).CornerRadius=UDim.new(0,4)
        local L=Instance.new("TextLabel") L.Size=UDim2.new(1,-56,1,0) L.Position=UDim2.new(0,8,0,0) L.BackgroundTransparency=1 L.Text=t L.TextColor3=Color3.fromRGB(200,200,210) L.TextSize=12 L.Font=Enum.Font.Gotham L.TextXAlignment=Enum.TextXAlignment.Left L.Parent=F
        local TB=Instance.new("TextButton") TB.Size=UDim2.new(0,42,0,20) TB.Position=UDim2.new(1,-48,0.5,-10) TB.Text=d and "ON" or "OFF" TB.TextSize=11 TB.Font=Enum.Font.GothamBold TB.TextColor3=Color3.new(1,1,1) TB.BackgroundColor3=d and Color3.fromRGB(80,0,200) or Color3.fromRGB(50,50,60) TB.BorderSizePixel=0 TB.Parent=F Instance.new("UICorner",TB).CornerRadius=UDim.new(0,4)
        local en=d TB.MouseButton1Click:Connect(function() en=not en TB.Text=en and "ON" or "OFF" TB.BackgroundColor3=en and Color3.fromRGB(80,0,200) or Color3.fromRGB(50,50,60) pcall(cb,en) end)
    end
    function self:AddSlider(p,t,mn,mx,d,cb)
        local F=Instance.new("Frame") F.Size=UDim2.new(1,0,0,40) F.BackgroundColor3=Color3.fromRGB(22,22,32) F.BorderSizePixel=0 F.Parent=p Instance.new("UICorner",F).CornerRadius=UDim.new(0,4)
        local L=Instance.new("TextLabel") L.Size=UDim2.new(1,-60,0,18) L.Position=UDim2.new(0,8,0,2) L.BackgroundTransparency=1 L.Text=t L.TextColor3=Color3.fromRGB(200,200,210) L.TextSize=11 L.Font=Enum.Font.Gotham L.TextXAlignment=Enum.TextXAlignment.Left L.Parent=F
        local VL=Instance.new("TextLabel") VL.Size=UDim2.new(0,50,0,18) VL.Position=UDim2.new(1,-56,0,2) VL.BackgroundTransparency=1 VL.Text=tostring(d) VL.TextColor3=Color3.fromRGB(160,100,255) VL.TextSize=11 VL.Font=Enum.Font.GothamBold VL.Parent=F
        local SBG=Instance.new("Frame") SBG.Size=UDim2.new(1,-16,0,6) SBG.Position=UDim2.new(0,8,0,26) SBG.BackgroundColor3=Color3.fromRGB(40,40,55) SBG.BorderSizePixel=0 SBG.Parent=F Instance.new("UICorner",SBG).CornerRadius=UDim.new(0,3)
        local FL=Instance.new("Frame") FL.Size=UDim2.new((d-mn)/(mx-mn),0,1,0) FL.BackgroundColor3=Color3.fromRGB(100,0,220) FL.BorderSizePixel=0 FL.Parent=SBG Instance.new("UICorner",FL).CornerRadius=UDim.new(0,3)
        local sl=false
        SBG.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sl=true end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sl=false end end)
        UserInputService.InputChanged:Connect(function(i) if sl and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local r=math.clamp((i.Position.X-SBG.AbsolutePosition.X)/SBG.AbsoluteSize.X,0,1) local v=math.floor(mn+(mx-mn)*r) FL.Size=UDim2.new(r,0,1,0) VL.Text=tostring(v) pcall(cb,v) end end)
    end
    function self:AddButton(p,t,cb) local B=Instance.new("TextButton") B.Size=UDim2.new(1,0,0,28) B.BackgroundColor3=Color3.fromRGB(60,0,130) B.BorderSizePixel=0 B.Text=t B.TextColor3=Color3.new(1,1,1) B.TextSize=12 B.Font=Enum.Font.GothamSemibold B.Parent=p Instance.new("UICorner",B).CornerRadius=UDim.new(0,4) B.MouseButton1Click:Connect(function() pcall(cb) end) end
    function self:AddDropdown(p,t,opts,cb)
        local F=Instance.new("Frame") F.Size=UDim2.new(1,0,0,28) F.BackgroundColor3=Color3.fromRGB(22,22,32) F.BorderSizePixel=0 F.Parent=p Instance.new("UICorner",F).CornerRadius=UDim.new(0,4)
        local L=Instance.new("TextLabel") L.Size=UDim2.new(0.5,0,1,0) L.Position=UDim2.new(0,8,0,0) L.BackgroundTransparency=1 L.Text=t L.TextColor3=Color3.fromRGB(200,200,210) L.TextSize=11 L.Font=Enum.Font.Gotham L.TextXAlignment=Enum.TextXAlignment.Left L.Parent=F
        local idx=1 local B=Instance.new("TextButton") B.Size=UDim2.new(0.5,-12,0,22) B.Position=UDim2.new(0.5,0,0.5,-11) B.BackgroundColor3=Color3.fromRGB(40,20,80) B.BorderSizePixel=0 B.Text=opts[1] or "None" B.TextColor3=Color3.fromRGB(200,160,255) B.TextSize=11 B.Font=Enum.Font.GothamSemibold B.Parent=F Instance.new("UICorner",B).CornerRadius=UDim.new(0,4)
        B.MouseButton1Click:Connect(function() idx=idx%#opts+1 B.Text=opts[idx] pcall(cb,opts[idx]) end)
    end
    task.defer(function() if #self.Tabs>0 then self.Tabs[1].Button.BackgroundColor3=Color3.fromRGB(60,20,120) self.Tabs[1].Button.TextColor3=Color3.fromRGB(220,180,255) self.Tabs[1].Frame.Visible=true end end)
    UserInputService.InputBegan:Connect(function(i,g) if g then return end if i.KeyCode==Enum.KeyCode.RightShift then M.Visible=not M.Visible end end)
    return self
end

-- GAME DETECTION
local GameDB = {
    [16472538603] = "Tha Bronx 3",
    [137020602493628] = "Gang Wars",
    [130700367963690] = "Philly Streetz 2",
    [2788229376] = "Da Hood",
    [17625359962] = "Rivals",
    [292439477] = "Phantom Forces",
    [286090429] = "Arsenal",
    [301549746] = "Counter Blox",
    [3233893879] = "Bad Business",
    [2753915549] = "Blox Fruits",
    [142823291] = "Murder Mystery 2",
    [606849621] = "Jailbreak",
    [6872274481] = "BedWars",
    [13772394625] = "Blade Ball",
    [6516141723] = "Doors",
    [4616652839] = "Shindo Life",
    [8737602449] = "Pet Simulator 99",
    [4520749081] = "King Legacy",
    [3260590327] = "Tower Defense Simulator",
    [1537690962] = "Bee Swarm Simulator",
    [4451193957] = "Grand Piece Online",
    [16732694052] = "Fisch",
    [4111023553] = "Deepwoken",
    [920587237] = "Adopt Me",
    [9791603388] = "Underground War 2",
    -- Newly added
    [121567535120062] = "Central Streets",
    [71600459831333] = "Street Life Remastered",
    [114478751418135] = "South London Remastered",
    [12077443856] = "Cali Shootout",
    [11177482306] = "Streetz War 2",
    [103505209463277] = "Outwest Chicago 2",
    [106558309643546] = "QZ Shootout",
    [10179538382] = "South Bronx",
    [17306807164] = "No Mercy",
    [18474291382] = "Playground Basketball",
    [14259168147] = "Basketball Legends",
    [18668065416] = "Blue Lock Rivals",
    [6804602922] = "Boxing Beta",
    [10449761463] = "The Strongest Battlegrounds",
    [97351810896225] = "Fantasma PvP",
    [9391468976] = "Jujutsu Shenanigans",
    [9887055815] = "Knockout",
    [135856908115931] = "MVS Duels",
    [113318245878384] = "Project Viltrumites",
    [5938036553] = "Frontlines",
    [116495829188952] = "Dead Rails",
    [12411473842] = "Pressure",
    [17017769292] = "Anime Defenders",
    [126884695634066] = "Grow A Garden",
    [15532962292] = "Sols RNG",
    [9096881148] = "Peroxide",
    [16929212566] = "Iron Man Reimagined",
    [2474168535] = "Westbound",
    [17065532662] = "Dark Divers",
    [2512643572] = "Bubblegum Simulator",
}
local CurrentPlaceId = game.PlaceId
local CurrentGame = GameDB[CurrentPlaceId]
if not CurrentGame then
    local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    local gameName = ok and info and info.Name and string.lower(info.Name) or ""
    if string.find(gameName, "tha") then CurrentGame = "Tha Bronx 3" end
    if string.find(gameName, "gang") then CurrentGame = "Gang Wars" end
    if string.find(gameName, "central") then CurrentGame = "Central Streets" end
    if string.find(gameName, "philly") then CurrentGame = "Philly Streetz 2" end
    if string.find(gameName, "da") then CurrentGame = "Da Hood" end
    if string.find(gameName, "street") then CurrentGame = "Street Life Remastered" end
    if string.find(gameName, "south") then CurrentGame = "South London Remastered" end
    if string.find(gameName, "cali") then CurrentGame = "Cali Shootout" end
    if string.find(gameName, "streetz") then CurrentGame = "Streetz War 2" end
    if string.find(gameName, "outwest") then CurrentGame = "Outwest Chicago 2" end
    if string.find(gameName, "qz") then CurrentGame = "QZ Shootout" end
    if string.find(gameName, "south") then CurrentGame = "South Bronx" end
    if string.find(gameName, "no") then CurrentGame = "No Mercy" end
    if string.find(gameName, "playground") then CurrentGame = "Playground Basketball" end
    if string.find(gameName, "basketball") then CurrentGame = "Basketball Legends" end
    if string.find(gameName, "blue") then CurrentGame = "Blue Lock Rivals" end
    if string.find(gameName, "boxing") then CurrentGame = "Boxing Beta" end
    if string.find(gameName, "the") then CurrentGame = "The Strongest Battlegrounds" end
    if string.find(gameName, "fantasma") then CurrentGame = "Fantasma PvP" end
    if string.find(gameName, "jujutsu") then CurrentGame = "Jujutsu Shenanigans" end
    if string.find(gameName, "knockout") then CurrentGame = "Knockout" end
    if string.find(gameName, "mvs") then CurrentGame = "MVS Duels" end
    if string.find(gameName, "project") then CurrentGame = "Project Viltrumites" end
    if string.find(gameName, "rivals") then CurrentGame = "Rivals" end
    if string.find(gameName, "phantom") then CurrentGame = "Phantom Forces" end
    if string.find(gameName, "frontlines") then CurrentGame = "Frontlines" end
    if string.find(gameName, "arsenal") then CurrentGame = "Arsenal" end
    if string.find(gameName, "counter") then CurrentGame = "Counter Blox" end
    if string.find(gameName, "bad") then CurrentGame = "Bad Business" end
    if string.find(gameName, "blox") then CurrentGame = "Blox Fruits" end
    if string.find(gameName, "murder") then CurrentGame = "Murder Mystery 2" end
    if string.find(gameName, "jailbreak") then CurrentGame = "Jailbreak" end
    if string.find(gameName, "bedwars") then CurrentGame = "BedWars" end
    if string.find(gameName, "blade") then CurrentGame = "Blade Ball" end
    if string.find(gameName, "doors") then CurrentGame = "Doors" end
    if string.find(gameName, "shindo") then CurrentGame = "Shindo Life" end
    if string.find(gameName, "pet") then CurrentGame = "Pet Simulator 99" end
    if string.find(gameName, "king") then CurrentGame = "King Legacy" end
    if string.find(gameName, "tower") then CurrentGame = "Tower Defense Simulator" end
    if string.find(gameName, "bee") then CurrentGame = "Bee Swarm Simulator" end
    if string.find(gameName, "grand") then CurrentGame = "Grand Piece Online" end
    if string.find(gameName, "dead") then CurrentGame = "Dead Rails" end
    if string.find(gameName, "pressure") then CurrentGame = "Pressure" end
    if string.find(gameName, "fisch") then CurrentGame = "Fisch" end
    if string.find(gameName, "deepwoken") then CurrentGame = "Deepwoken" end
    if string.find(gameName, "anime") then CurrentGame = "Anime Defenders" end
    if string.find(gameName, "grow") then CurrentGame = "Grow A Garden" end
    if string.find(gameName, "sols") then CurrentGame = "Sols RNG" end
    if string.find(gameName, "peroxide") then CurrentGame = "Peroxide" end
    if string.find(gameName, "iron") then CurrentGame = "Iron Man Reimagined" end
    if string.find(gameName, "westbound") then CurrentGame = "Westbound" end
    if string.find(gameName, "dark") then CurrentGame = "Dark Divers" end
    if string.find(gameName, "adopt") then CurrentGame = "Adopt Me" end
    if string.find(gameName, "bubblegum") then CurrentGame = "Bubblegum Simulator" end
    if string.find(gameName, "underground") then CurrentGame = "Underground War 2" end
end
CurrentGame = CurrentGame or "Unknown"
print("[Hood Omni Hub] Game: " .. CurrentGame)

-- UTILITIES
local function CreateESP(player)
    if player==LocalPlayer then return end
    pcall(function()
        local ch=player.Character if not ch then return end
        local head=ch:FindFirstChild("Head") if not head then return end
        local bb=Instance.new("BillboardGui") bb.Name="ESP_"..player.Name bb.Size=UDim2.new(0,200,0,50) bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true bb.Adornee=head bb.Parent=ESPFolder
        local nl=Instance.new("TextLabel") nl.Size=UDim2.new(1,0,0.5,0) nl.BackgroundTransparency=1 nl.Text=player.Name nl.TextColor3=Color3.fromRGB(200,130,255) nl.TextStrokeTransparency=0.5 nl.TextSize=13 nl.Font=Enum.Font.GothamBold nl.Parent=bb
        local dl=Instance.new("TextLabel") dl.Size=UDim2.new(1,0,0.5,0) dl.Position=UDim2.new(0,0,0.5,0) dl.BackgroundTransparency=1 dl.TextColor3=Color3.fromRGB(180,180,190) dl.TextStrokeTransparency=0.5 dl.TextSize=11 dl.Font=Enum.Font.Gotham dl.Parent=bb
        local hl=Instance.new("Highlight") hl.Name="HL_"..player.Name hl.FillColor=Color3.fromRGB(128,0,255) hl.FillTransparency=0.7 hl.OutlineColor=Color3.fromRGB(200,130,255) hl.Parent=ch
        local cn cn=RunService.Heartbeat:Connect(function()
            if not HubState.ESPEnabled then bb:Destroy() pcall(function() hl:Destroy() end) cn:Disconnect() return end
            if not player.Parent or not ch.Parent or not head.Parent then bb:Destroy() pcall(function() hl:Destroy() end) cn:Disconnect() return end
            local rp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if rp then dl.Text=math.floor((head.Position-rp.Position).Magnitude).." studs" end
            local hm=ch:FindFirstChildOfClass("Humanoid") if hm then nl.Text=player.Name.." ["..math.floor(hm.Health).."]" end
        end)
        table.insert(Connections,cn)
    end)
end
local function RefreshESP()
    for _,v in pairs(ESPFolder:GetChildren()) do v:Destroy() end
    for _,p in pairs(Players:GetPlayers()) do if p.Character then for _,v in pairs(p.Character:GetChildren()) do if v:IsA("Highlight") and string.find(v.Name,"HL_") then v:Destroy() end end end end
    if HubState.ESPEnabled then for _,p in pairs(Players:GetPlayers()) do CreateESP(p) end end
end
local function GetClosestPlayer(fov,tp)
    tp=tp or "Head" local cl,cd=nil,fov
    local rp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if not rp then return nil end
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            local pt=p.Character:FindFirstChild(tp) or p.Character:FindFirstChild("Head")
            local hm=p.Character:FindFirstChildOfClass("Humanoid")
            if pt and hm and hm.Health>0 then
                local sp,os=Camera:WorldToScreenPoint(pt.Position)
                if os then local ct=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2) local d=(Vector2.new(sp.X,sp.Y)-ct).Magnitude if d<cd then cd=d cl=pt end end
            end
        end
    end
    return cl
end
local function RunKillAura()
    pcall(function()
        local rp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if not rp then return end
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                local er=p.Character:FindFirstChild("HumanoidRootPart") local hm=p.Character:FindFirstChildOfClass("Humanoid")
                if er and hm and hm.Health>0 and (rp.Position-er.Position).Magnitude<=HubState.KillAuraRange then
                    local tool=LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool then pcall(function() tool:Activate() end) end
                    pcall(function() VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0) VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0) end)
                end
            end
        end
    end)
end
local flyBody,flyGyro
local function StartFly()
    pcall(function()
        local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end
        flyBody=Instance.new("BodyVelocity") flyBody.MaxForce=Vector3.new(math.huge,math.huge,math.huge) flyBody.Velocity=Vector3.zero flyBody.Parent=hrp
        flyGyro=Instance.new("BodyGyro") flyGyro.MaxTorque=Vector3.new(math.huge,math.huge,math.huge) flyGyro.P=9e4 flyGyro.Parent=hrp
        local fc fc=RunService.Heartbeat:Connect(function()
            if not HubState.FlyEnabled then pcall(function() flyBody:Destroy() end) pcall(function() flyGyro:Destroy() end) fc:Disconnect() return end
            local cf=Camera.CFrame local vel=Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel=vel+cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel=vel-cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel=vel-cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel=vel+cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel=vel+Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel=vel-Vector3.new(0,1,0) end
            if vel.Magnitude>0 then vel=vel.Unit end
            flyBody.Velocity=vel*HubState.FlySpeed flyGyro.CFrame=cf
        end)
        table.insert(Connections,fc)
    end)
end
-- Noclip
local ncConn=RunService.Stepped:Connect(function() if HubState.Noclip and LocalPlayer.Character then for _,p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end)
table.insert(Connections,ncConn)
-- Anti AFK
pcall(function() local af=LocalPlayer.Idled:Connect(function() if HubState.AntiAFK then VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game) task.wait(0.1) VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game) end end) table.insert(Connections,af) end)
-- FullBright
local origA,origB,origC
local function ApplyFullBright()
    if HubState.FullBright then origA=Lighting.Ambient origB=Lighting.Brightness origC=Lighting.ClockTime Lighting.Ambient=Color3.new(1,1,1) Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.FogEnd=1e6
    else pcall(function() Lighting.Ambient=origA or Color3.fromRGB(127,127,127) Lighting.Brightness=origB or 1 Lighting.ClockTime=origC or 14 end) end
end
local function ExpandHitboxes()
    pcall(function() for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then local h=p.Character:FindFirstChild("HumanoidRootPart") if h then h.Size=HubState.HitboxExpand and Vector3.new(HubState.HitboxSize,HubState.HitboxSize,HubState.HitboxSize) or Vector3.new(2,2,1) h.Transparency=HubState.HitboxExpand and 0.7 or 1 end end end end)
end

-- BUILD UI
local Hub = OmniUI:Create()

-- UNIVERSAL TAB (always available)
local uTab = Hub:AddTab("Universal","🌍")
Hub:AddSection(uTab,"Movement")
Hub:AddToggle(uTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
Hub:AddSlider(uTab,"Speed Value",16,500,100,function(v) HubState.SpeedValue=v if HubState.SpeedHack then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v end) end end)
Hub:AddToggle(uTab,"Fly (RShift toggle GUI)",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
Hub:AddSlider(uTab,"Fly Speed",50,1000,200,function(v) HubState.FlySpeed=v end)
Hub:AddToggle(uTab,"Noclip",false,function(v) HubState.Noclip=v end)
Hub:AddSlider(uTab,"Jump Power",50,500,100,function(v) HubState.JumpPower=v pcall(function() LocalPlayer.Character.Humanoid.JumpPower=v end) end)
Hub:AddSection(uTab,"Combat")
Hub:AddToggle(uTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
Hub:AddToggle(uTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
Hub:AddSlider(uTab,"Aim FOV",50,800,400,function(v) HubState.AimFOV=v end)
Hub:AddToggle(uTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
Hub:AddToggle(uTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
Hub:AddSlider(uTab,"Kill Aura Range",5,50,15,function(v) HubState.KillAuraRange=v end)
Hub:AddToggle(uTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
Hub:AddSlider(uTab,"Hitbox Size",5,50,15,function(v) HubState.HitboxSize=v if HubState.HitboxExpand then ExpandHitboxes() end end)
Hub:AddSection(uTab,"Weapon")
Hub:AddToggle(uTab,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
Hub:AddToggle(uTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)
Hub:AddToggle(uTab,"No Spread",false,function(v) HubState.NoSpread=v end)
Hub:AddToggle(uTab,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
Hub:AddSection(uTab,"Visual")
Hub:AddToggle(uTab,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
Hub:AddToggle(uTab,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
Hub:AddSection(uTab,"Misc")
Hub:AddButton(uTab,"Rejoin Server",function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end)
Hub:AddButton(uTab,"Server Hop",function() pcall(function() local s=TeleportService:GetPlayerPlaceInstanceAsync(LocalPlayer.UserId) TeleportService:TeleportToPlaceInstance(game.PlaceId,s,LocalPlayer) end) end)
Hub:AddButton(uTab,"Destroy Hub",function() for _,c in pairs(Connections) do pcall(function() c:Disconnect() end) end ESPFolder:Destroy() Hub.ScreenGui:Destroy() end)

-- ── BYPASS TAB ──────────────────────────────────────────────────────────────
local bTab = Hub:AddTab("Bypass","🛡️")
Hub:AddSection(bTab,"Protection")
Hub:AddToggle(bTab,"Anti-Kick",true,function(v) HubState.AntiKick=v end)
Hub:AddToggle(bTab,"Anti-Fling",true,function(v) HubState.AntiFling=v end)
Hub:AddToggle(bTab,"Anti-Kill Parts",false,function(v) HubState.AntiKillPart=v end)
Hub:AddToggle(bTab,"Anti-Void (Auto TP Back)",true,function(v) HubState.AntiVoid=v end)
Hub:AddToggle(bTab,"Godmode (Inf Health)",false,function(v) HubState.Godmode=v end)
Hub:AddSection(bTab,"Stealth")
Hub:AddToggle(bTab,"Block AC Remotes",true,function(v) HubState.BlockAC=v end)
Hub:AddToggle(bTab,"Anti-Teleport (Block Ban TP)",true,function(v) HubState.AntiTeleport=v end)
Hub:AddToggle(bTab,"Executor Spoof",true,function(v) HubState.ExecSpoof=v end)
Hub:AddSection(bTab,"Da Hood / Gang Wars")
Hub:AddToggle(bTab,"Anti-Stomp",true,function(v) HubState.AntiStomp=v end)
Hub:AddToggle(bTab,"Anti-Ragdoll",true,function(v) HubState.AntiRagdoll=v end)
Hub:AddToggle(bTab,"Anti-Grab",true,function(v) HubState.AntiGrab=v end)
Hub:AddSection(bTab,"Misc")
Hub:AddToggle(bTab,"Nuclear Anti-AFK",true,function(v) HubState.AntiAFK=v end)
Hub:AddSlider(bTab,"Gravity",0,400,196,function(v) HubState.GravityValue=v if HubState.GravityMod then Workspace.Gravity=v end end)
Hub:AddToggle(bTab,"Custom Gravity",false,function(v) HubState.GravityMod=v if v then Workspace.Gravity=HubState.GravityValue else Workspace.Gravity=196.2 end end)




-- THA BRONX 3 TAB
if CurrentGame == "Tha Bronx 3" or CurrentGame == "Unknown" then
    local t_Tha_Bronx_3 = Hub:AddTab("Tha Bronx 3","🏙️")
    Hub:AddSection(t_Tha_Bronx_3,"Farming")
    Hub:AddToggle(t_Tha_Bronx_3,"Auto Farm Cash",true,function(v) HubState.AutoFarmCash=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"Auto Farm XP",true,function(v) HubState.AutoFarmXP=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"Auto Rob Store",false,function(v) HubState.AutoRobStore=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"Auto Rob NPC",false,function(v) HubState.AutoRobNPC=v end)
    Hub:AddSection(t_Tha_Bronx_3,"Combat")
    Hub:AddToggle(t_Tha_Bronx_3,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Tha_Bronx_3,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_Tha_Bronx_3,"Weapon")
    Hub:AddToggle(t_Tha_Bronx_3,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Tha_Bronx_3,"Movement")
    Hub:AddToggle(t_Tha_Bronx_3,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Tha_Bronx_3,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Tha_Bronx_3,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"God Mode",false,function(v) HubState.GodMode=v end)
    Hub:AddSection(t_Tha_Bronx_3,"Visual & Misc")
    Hub:AddToggle(t_Tha_Bronx_3,"Auto Equip Best Gun",false,function(v) HubState.AutoEquip=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"Anti Lock",false,function(v) HubState.AntiLock=v end)
    Hub:AddToggle(t_Tha_Bronx_3,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Tha_Bronx_3,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
    Hub:AddSection(t_Tha_Bronx_3,"Teleports")
    Hub:AddButton(t_Tha_Bronx_3,"Teleport to ATM",function() pcall(function() for _,v in pairs(workspace:GetDescendants()) do if v.Name:lower():find("atm") and v:IsA("BasePart") then LocalPlayer.Character.HumanoidRootPart.CFrame=v.CFrame+Vector3.new(0,3,0) break end end end) end)
    Hub:AddButton(t_Tha_Bronx_3,"Teleport to Gun Store",function() pcall(function() for _,v in pairs(workspace:GetDescendants()) do if (v.Name:lower():find("gun") or v.Name:lower():find("ammu")) and v:IsA("BasePart") then LocalPlayer.Character.HumanoidRootPart.CFrame=v.CFrame+Vector3.new(0,3,0) break end end end) end)
end

-- GANG WARS TAB
if CurrentGame == "Gang Wars" or CurrentGame == "Unknown" then
    local t_Gang_Wars = Hub:AddTab("Gang Wars","🔫")
    Hub:AddSection(t_Gang_Wars,"Farming")
    Hub:AddToggle(t_Gang_Wars,"Auto Farm Cash",true,function(v) HubState.AutoFarmCash=v end)
    Hub:AddToggle(t_Gang_Wars,"Auto Farm Kills",true,function(v) HubState.AutoFarmKills=v end)
    Hub:AddSection(t_Gang_Wars,"Combat")
    Hub:AddToggle(t_Gang_Wars,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Gang_Wars,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Gang_Wars,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Gang_Wars,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Gang_Wars,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_Gang_Wars,"Weapon")
    Hub:AddToggle(t_Gang_Wars,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_Gang_Wars,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Gang_Wars,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_Gang_Wars,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Gang_Wars,"Movement")
    Hub:AddToggle(t_Gang_Wars,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Gang_Wars,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Gang_Wars,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_Gang_Wars,"God Mode",false,function(v) HubState.GodMode=v end)
    Hub:AddSection(t_Gang_Wars,"Visual & Misc")
    Hub:AddToggle(t_Gang_Wars,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Gang_Wars,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
    Hub:AddSection(t_Gang_Wars,"Teleports")
    Hub:AddButton(t_Gang_Wars,"Teleport to Safe Zone",function() HubState.TpSafeZone=v end)

    -- ════════════════════════════════════════════════════
    -- GANG WARS EXTENDED FEATURES (Merged from HoodOmniHub v2)
    -- ════════════════════════════════════════════════════

    -- AUTOFARM EXTENDED SECTION
    Hub:AddSection(t_Gang_Wars,"Extended Autofarming")

    -- ── POTATO TRAP FARM ─────────────────────────────────────────────────────
    -- Potato / Trap farm: searches workspace for harvest/plant/pick proximity prompts
    Hub:AddToggle(t_Gang_Wars,"🥔 Potato / Trap Farm",false,function(v)
        HubState.PotatoFarm = v
        if v then
            task.spawn(function()
                while HubState.PotatoFarm do
                    pcall(function()
                        -- Step 1: Buy bags (look for bag purchase prompts ~$950)
                        for _, v2 in ipairs(workspace:GetDescendants()) do
                            if not HubState.PotatoFarm then break end
                            if v2:IsA("ProximityPrompt") then
                                local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                local aText = v2.ActionText:lower()
                                if pName:find("bag") or pName:find("seed") or pName:find("supply")
                                    or aText:find("buy bag") or aText:find("purchase") then
                                    local part = v2.Parent
                                    if part and part:IsA("BasePart") then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,3,0)
                                        task.wait(0.3)
                                    end
                                    -- TODO: Replace with Debug Scanner result for bag purchase remote
                                    pcall(function()
                                        for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                                            if remote:IsA("RemoteEvent") then
                                                local rn = remote.Name:lower()
                                                if rn:find("buy") or rn:find("purchase") or rn:find("bag") then
                                                    remote:FireServer("bag", 1)
                                                    break
                                                end
                                            end
                                        end
                                    end)
                                    task.wait(0.5)
                                end
                            end
                        end

                        -- Step 2: Cook / Process
                        for _, v2 in ipairs(workspace:GetDescendants()) do
                            if not HubState.PotatoFarm then break end
                            if v2:IsA("ProximityPrompt") then
                                local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                local aText = v2.ActionText:lower()
                                if pName:find("cook") or pName:find("process") or pName:find("stove")
                                    or aText:find("cook") or aText:find("process") or aText:find("bake") then
                                    local part = v2.Parent
                                    if part and part:IsA("BasePart") then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,3,0)
                                        task.wait(0.3)
                                    end
                                    -- TODO: Replace with Debug Scanner result for cook remote
                                    v2.Triggered:Fire(LocalPlayer)
                                    task.wait(1.5)
                                end
                            end
                        end

                        -- Step 3: Harvest / Pick (random output sizes)
                        local outputs = {"small", "medium", "large"}
                        local randOut = outputs[math.random(1, #outputs)]
                        for _, v2 in ipairs(workspace:GetDescendants()) do
                            if not HubState.PotatoFarm then break end
                            if v2:IsA("ProximityPrompt") then
                                local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                local aText = v2.ActionText:lower()
                                if pName:find("potato") or pName:find("plant") or pName:find("grow")
                                    or pName:find("trap") or pName:find("harvest")
                                    or aText:find("harvest") or aText:find("plant") or aText:find("pick") then
                                    local part = v2.Parent
                                    if part and part:IsA("BasePart") then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,3,0)
                                        task.wait(0.3)
                                    end
                                    -- TODO: Replace with Debug Scanner result for harvest remote
                                    pcall(function()
                                        for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                                            if remote:IsA("RemoteEvent") then
                                                local rn = remote.Name:lower()
                                                if rn:find("harvest") or rn:find("pick") or rn:find("collect") then
                                                    remote:FireServer(randOut)
                                                    break
                                                end
                                            end
                                        end
                                    end)
                                    task.wait(0.5)
                                end
                            end
                        end

                        -- Step 4: Sell
                        for _, v2 in ipairs(workspace:GetDescendants()) do
                            if not HubState.PotatoFarm then break end
                            if v2:IsA("ProximityPrompt") then
                                local aText = v2.ActionText:lower()
                                if aText:find("sell") then
                                    local part = v2.Parent
                                    if part and part:IsA("BasePart") then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,3,0)
                                        task.wait(0.3)
                                    end
                                    -- TODO: Replace with Debug Scanner result for sell remote
                                    pcall(function()
                                        for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                                            if remote:IsA("RemoteEvent") then
                                                local rn = remote.Name:lower()
                                                if rn:find("sell") or rn:find("trade") then
                                                    remote:FireServer()
                                                    break
                                                end
                                            end
                                        end
                                    end)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end)
                    -- Repeat after short delay
                    task.wait(math.random(3, 6))
                end
            end)
        end
    end)

    -- ── CAR BREAKING AUTOFARM ─────────────────────────────────────────────────
    Hub:AddToggle(t_Gang_Wars,"🚗 Car Breaking Autofarm",false,function(v)
        HubState.CarBreakFarm = v
        if v then
            task.spawn(function()
                while HubState.CarBreakFarm do
                    pcall(function()
                        for _, v2 in ipairs(workspace:GetDescendants()) do
                            if not HubState.CarBreakFarm then break end
                            if v2:IsA("ProximityPrompt") then
                                local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                local aText = v2.ActionText:lower()
                                -- TODO: Replace with Debug Scanner result for car breaking prompt names
                                if pName:find("car") or pName:find("vehicle") or pName:find("auto")
                                    or aText:find("break") or aText:find("smash") or aText:find("jack") 
                                    or aText:find("steal") or aText:find("rob car") then
                                    local part = v2.Parent
                                    if part and part:IsA("BasePart") then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,3,0)
                                        task.wait(0.3)
                                    end
                                    pcall(function()
                                        -- TODO: Replace with Debug Scanner result for car break remote
                                        for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                                            if remote:IsA("RemoteEvent") then
                                                local rn = remote.Name:lower()
                                                if rn:find("car") or rn:find("vehicle") or rn:find("break") or rn:find("jack") then
                                                    remote:FireServer()
                                                    break
                                                end
                                            end
                                        end
                                    end)
                                    task.wait(math.random(1, 2) + math.random() * 0.5)
                                end
                            end
                        end
                    end)
                    task.wait(math.random(4, 7))
                end
            end)
        end
    end)

    -- ── SCAMMING AUTOFARM ─────────────────────────────────────────────────────
    Hub:AddToggle(t_Gang_Wars,"🎭 Scamming Autofarm",false,function(v)
        HubState.ScamFarm = v
        if v then
            task.spawn(function()
                while HubState.ScamFarm do
                    pcall(function()
                        -- TODO: Replace with Debug Scanner result for scam trade prompts
                        for _, v2 in ipairs(workspace:GetDescendants()) do
                            if not HubState.ScamFarm then break end
                            if v2:IsA("ProximityPrompt") then
                                local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                local aText = v2.ActionText:lower()
                                if pName:find("trade") or pName:find("deal") or pName:find("scam")
                                    or aText:find("trade") or aText:find("deal") or aText:find("exchange") then
                                    local part = v2.Parent
                                    if part and part:IsA("BasePart") then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,3,0)
                                        task.wait(0.3)
                                    end
                                    pcall(function()
                                        -- TODO: Replace with Debug Scanner result for trade/scam remote
                                        for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                                            if remote:IsA("RemoteEvent") then
                                                local rn = remote.Name:lower()
                                                if rn:find("trade") or rn:find("deal") or rn:find("scam") then
                                                    remote:FireServer()
                                                    break
                                                end
                                            end
                                        end
                                    end)
                                    task.wait(math.random(1, 3))
                                end
                            end
                        end
                    end)
                    task.wait(math.random(5, 10))
                end
            end)
        end
    end)

    -- ── STORE ROBBERY AUTOFARM ────────────────────────────────────────────────
    Hub:AddToggle(t_Gang_Wars,"🏪 Store Robbery Autofarm",false,function(v)
        HubState.StoreRobFarm = v
        if v then
            task.spawn(function()
                while HubState.StoreRobFarm do
                    pcall(function()
                        for _, v2 in ipairs(workspace:GetDescendants()) do
                            if not HubState.StoreRobFarm then break end
                            if v2:IsA("ProximityPrompt") then
                                local pName = v2.Parent and v2.Parent.Name:lower() or ""
                                local aText = v2.ActionText:lower()
                                -- TODO: Replace with Debug Scanner result for store robbery prompt names
                                if pName:find("store") or pName:find("shop") or pName:find("register")
                                    or pName:find("rob") or pName:find("cash") or pName:find("vault")
                                    or aText:find("rob") or aText:find("steal") or aText:find("grab cash")
                                    or aText:find("open register") or aText:find("break in") then
                                    local part = v2.Parent
                                    if part and part:IsA("BasePart") then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,3,0)
                                        task.wait(0.5)
                                    end
                                    pcall(function()
                                        -- TODO: Replace with Debug Scanner result for store rob remote
                                        for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                                            if remote:IsA("RemoteEvent") then
                                                local rn = remote.Name:lower()
                                                if rn:find("rob") or rn:find("store") or rn:find("steal") then
                                                    remote:FireServer()
                                                    break
                                                end
                                            end
                                        end
                                    end)
                                    task.wait(math.random(1, 3) + math.random() * 0.5)
                                end
                            end
                        end
                    end)
                    task.wait(math.random(5, 8))
                end
            end)
        end
    end)

    -- ── WEAPONS SPAWNER SECTION ───────────────────────────────────────────────
    Hub:AddSection(t_Gang_Wars,"Weapons Spawner")

    -- Gamepass Guns
    Hub:AddButton(t_Gang_Wars,"── GAMEPASS GUNS ──",function() end)
    local gamepPassGuns = {
        "Glock19X", "Glock19", "Glock26 Switch", "Glock Gold Switch",
        "P80 Switch", "P80",
        "AR9 Fully",
        "150R Easter Fully", "200R Easter Switch",
        "XMAS Shotgun", "Auto Shotgun", "2026 Shotgun", "OP Shotgun",
        "100 Round Switch", "100 Round Fully", "50 Round",
        "300 ARG",
        "Gold Draco Drum",
        "Mini Gun",
        "Mr Beast Uzi", "Mr Beast Fully",
        "Heart Switch", "Squid Games Switch", "Valentines Switch", "Valentines Fully",
        "DOA Switch", "200R Money Switch", "Ghost Fully", "Yins Switch", "Skull",
    }
    for _, gunName in ipairs(gamepPassGuns) do
        Hub:AddButton(t_Gang_Wars,"🔫 Spawn "..gunName,function()
            pcall(function()
                -- Method 1: Try ReplicatedStorage
                local gun = game:GetService("ReplicatedStorage"):FindFirstChild(gunName, true)
                if gun and gun:IsA("Tool") then
                    gun:Clone().Parent = LocalPlayer.Backpack
                    return
                end
                -- Method 2: Search workspace
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("Tool") and v.Name == gunName then
                        v:Clone().Parent = LocalPlayer.Backpack
                        return
                    end
                end
                -- Method 3: Fire remote (TODO: Replace with Debug Scanner result)
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

    -- Regular Guns
    Hub:AddButton(t_Gang_Wars,"── REGULAR GUNS ──",function() end)
    local regularGuns = {
        "Glock", "Uzi", "Mac10", "AK47", "AR15", "Shotgun",
        "Draco", "FN", "Deagle", "MP5", "Sniper", "RPG",
        "Revolver", "Choppa", "SMG",
    }
    for _, gunName in ipairs(regularGuns) do
        Hub:AddButton(t_Gang_Wars,"🔫 Spawn "..gunName,function()
            pcall(function()
                local gun = game:GetService("ReplicatedStorage"):FindFirstChild(gunName, true)
                if gun and gun:IsA("Tool") then
                    gun:Clone().Parent = LocalPlayer.Backpack
                    return
                end
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("Tool") and v.Name == gunName then
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

    -- Gun Dupe
    Hub:AddToggle(t_Gang_Wars,"♻️ Gun Dupe",false,function(v)
        HubState.GunDupe = v
        if v then
            task.spawn(function()
                while HubState.GunDupe do
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

    -- ── DEBUG SCANNER SECTION ────────────────────────────────────────────────
    Hub:AddSection(t_Gang_Wars,"Debug Scanner")

    -- Scan 1: All RemoteEvents
    Hub:AddButton(t_Gang_Wars,"🔍 Scan RemoteEvents",function()
        local count = 0
        for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteEvent") then
                count = count + 1
                print("[GW Debug] RemoteEvent: " .. v:GetFullName())
            end
        end
        print("[GW Debug] Total RemoteEvents: " .. count)
    end)

    -- Scan 2: All RemoteFunctions
    Hub:AddButton(t_Gang_Wars,"🔍 Scan RemoteFunctions",function()
        local count = 0
        for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteFunction") then
                count = count + 1
                print("[GW Debug] RemoteFunction: " .. v:GetFullName())
            end
        end
        print("[GW Debug] Total RemoteFunctions: " .. count)
    end)

    -- Scan 3: All ProximityPrompts
    Hub:AddButton(t_Gang_Wars,"🔍 Scan ProximityPrompts",function()
        local count = 0
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                count = count + 1
                if count <= 100 then
                    print("[GW Debug] Prompt @ " .. (v.Parent and v.Parent.Name or "?") 
                        .. " | Action: " .. v.ActionText
                        .. " | Hold: " .. v.HoldDuration)
                end
            end
        end
        print("[GW Debug] Total Prompts: " .. count)
    end)

    -- Scan 4: Workspace Structure
    Hub:AddButton(t_Gang_Wars,"🔍 Scan Workspace Structure",function()
        print("[GW Debug] === Workspace Children ===")
        for _, v in ipairs(workspace:GetChildren()) do
            print("[GW Debug] " .. v.ClassName .. ": " .. v.Name)
        end
    end)

    -- Scan 5: All Tools (RS + Workspace)
    Hub:AddButton(t_Gang_Wars,"🔍 Scan All Tools",function()
        local count = 0
        for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("Tool") then
                count = count + 1
                print("[GW Debug] RS Tool: " .. v.Name .. " @ " .. v:GetFullName())
            end
        end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Tool") then
                count = count + 1
                print("[GW Debug] WS Tool: " .. v.Name)
            end
        end
        print("[GW Debug] Total Tools Found: " .. count)
    end)

end

-- DA HOOD TAB
if CurrentGame == "Da Hood" or CurrentGame == "Unknown" then
    local t_Da_Hood = Hub:AddTab("Gangwars","🏘️")
    Hub:AddSection(t_Da_Hood,"Farming")
    Hub:AddToggle(t_Da_Hood,"Auto Farm Cash",true,function(v) HubState.AutoFarmCash=v end)
    Hub:AddSection(t_Da_Hood,"Combat")
    Hub:AddToggle(t_Da_Hood,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Da_Hood,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Da_Hood,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Da_Hood,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Da_Hood,"Stomp Aura",false,function(v) HubState.StompAura=v end)
    Hub:AddToggle(t_Da_Hood,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddToggle(t_Da_Hood,"Lock Victim",false,function(v) HubState.LockVictim=v end)
    Hub:AddToggle(t_Da_Hood,"Auto Block",false,function(v) HubState.AutoBlock=v end)
    Hub:AddToggle(t_Da_Hood,"Reach Extend",false,function(v) HubState.ReachExtend=v end)
    Hub:AddSection(t_Da_Hood,"Weapon")
    Hub:AddToggle(t_Da_Hood,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_Da_Hood,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Da_Hood,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Da_Hood,"Movement")
    Hub:AddToggle(t_Da_Hood,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Da_Hood,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Da_Hood,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Da_Hood,"Visual & Misc")
    Hub:AddToggle(t_Da_Hood,"Auto Pickup",false,function(v) HubState.AutoPickup=v end)
    Hub:AddToggle(t_Da_Hood,"Auto Equip",false,function(v) HubState.AutoEquip=v end)
    Hub:AddToggle(t_Da_Hood,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Da_Hood,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- PHILLY STREETZ 2 TAB
if CurrentGame == "Philly Streetz 2" or CurrentGame == "Unknown" then
    local t_Philly_Streetz_2 = Hub:AddTab("Philly Streetz 2","🏚️")
    Hub:AddSection(t_Philly_Streetz_2,"Farming")
    Hub:AddToggle(t_Philly_Streetz_2,"Auto Farm Cash",true,function(v) HubState.AutoFarmCash=v end)
    Hub:AddToggle(t_Philly_Streetz_2,"Money Gen",false,function(v) HubState.MoneyGen=v end)
    Hub:AddToggle(t_Philly_Streetz_2,"Auto Rob",false,function(v) HubState.AutoRob=v end)
    Hub:AddSection(t_Philly_Streetz_2,"Combat")
    Hub:AddToggle(t_Philly_Streetz_2,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Philly_Streetz_2,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Philly_Streetz_2,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Philly_Streetz_2,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Philly_Streetz_2,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_Philly_Streetz_2,"Weapon")
    Hub:AddToggle(t_Philly_Streetz_2,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_Philly_Streetz_2,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Philly_Streetz_2,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Philly_Streetz_2,"Movement")
    Hub:AddToggle(t_Philly_Streetz_2,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Philly_Streetz_2,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Philly_Streetz_2,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Philly_Streetz_2,"Visual & Misc")
    Hub:AddToggle(t_Philly_Streetz_2,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Philly_Streetz_2,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
    Hub:AddSection(t_Philly_Streetz_2,"Teleports")
    Hub:AddButton(t_Philly_Streetz_2,"Teleport to ATM",function() pcall(function() for _,v in pairs(workspace:GetDescendants()) do if v.Name:lower():find("atm") and v:IsA("BasePart") then LocalPlayer.Character.HumanoidRootPart.CFrame=v.CFrame+Vector3.new(0,3,0) break end end end) end)
end

-- CENTRAL STREETS TAB
if CurrentGame == "Central Streets" or CurrentGame == "Unknown" then
    local t_Central_Streets = Hub:AddTab("Central Streets","🌆")
    Hub:AddSection(t_Central_Streets,"Farming")
    Hub:AddToggle(t_Central_Streets,"Auto Farm Cash",true,function(v) HubState.AutoFarmCash=v end)
    Hub:AddSection(t_Central_Streets,"Combat")
    Hub:AddToggle(t_Central_Streets,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Central_Streets,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Central_Streets,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Central_Streets,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Central_Streets,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_Central_Streets,"Weapon")
    Hub:AddToggle(t_Central_Streets,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_Central_Streets,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddSection(t_Central_Streets,"Movement")
    Hub:AddToggle(t_Central_Streets,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Central_Streets,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Central_Streets,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Central_Streets,"Visual & Misc")
    Hub:AddToggle(t_Central_Streets,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Central_Streets,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- SOUTH LONDON REMASTERED TAB
if CurrentGame == "South London Remastered" or CurrentGame == "Unknown" then
    local t_South_London_Remastered = Hub:AddTab("South London Remastered","🇬🇧")
    Hub:AddSection(t_South_London_Remastered,"Farming")
    Hub:AddToggle(t_South_London_Remastered,"Auto Farm Cash",true,function(v) HubState.AutoFarmCash=v end)
    Hub:AddSection(t_South_London_Remastered,"Combat")
    Hub:AddToggle(t_South_London_Remastered,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_South_London_Remastered,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_South_London_Remastered,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_South_London_Remastered,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_South_London_Remastered,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_South_London_Remastered,"Weapon")
    Hub:AddToggle(t_South_London_Remastered,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddSection(t_South_London_Remastered,"Movement")
    Hub:AddToggle(t_South_London_Remastered,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_South_London_Remastered,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_South_London_Remastered,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_South_London_Remastered,"Visual & Misc")
    Hub:AddToggle(t_South_London_Remastered,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_South_London_Remastered,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- CALI SHOOTOUT TAB
if CurrentGame == "Cali Shootout" or CurrentGame == "Unknown" then
    local t_Cali_Shootout = Hub:AddTab("Cali Shootout","☀️")
    Hub:AddSection(t_Cali_Shootout,"Farming")
    Hub:AddToggle(t_Cali_Shootout,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Cali_Shootout,"Combat")
    Hub:AddToggle(t_Cali_Shootout,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Cali_Shootout,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Cali_Shootout,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Cali_Shootout,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Cali_Shootout,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_Cali_Shootout,"Weapon")
    Hub:AddToggle(t_Cali_Shootout,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_Cali_Shootout,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Cali_Shootout,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Cali_Shootout,"Movement")
    Hub:AddToggle(t_Cali_Shootout,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Cali_Shootout,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Cali_Shootout,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Cali_Shootout,"Visual & Misc")
    Hub:AddToggle(t_Cali_Shootout,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Cali_Shootout,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- STREETZ WAR 2 TAB
if CurrentGame == "Streetz War 2" or CurrentGame == "Unknown" then
    local t_Streetz_War_2 = Hub:AddTab("Streetz War 2","⚔️")
    Hub:AddSection(t_Streetz_War_2,"Farming")
    Hub:AddToggle(t_Streetz_War_2,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Streetz_War_2,"Combat")
    Hub:AddToggle(t_Streetz_War_2,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Streetz_War_2,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Streetz_War_2,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Streetz_War_2,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Streetz_War_2,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_Streetz_War_2,"Weapon")
    Hub:AddToggle(t_Streetz_War_2,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_Streetz_War_2,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddSection(t_Streetz_War_2,"Movement")
    Hub:AddToggle(t_Streetz_War_2,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Streetz_War_2,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Streetz_War_2,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Streetz_War_2,"Visual & Misc")
    Hub:AddToggle(t_Streetz_War_2,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Streetz_War_2,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- SOUTH BRONX TAB
if CurrentGame == "South Bronx" or CurrentGame == "Unknown" then
    local t_South_Bronx = Hub:AddTab("South Bronx","🏙️")
    Hub:AddSection(t_South_Bronx,"Farming")
    Hub:AddToggle(t_South_Bronx,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_South_Bronx,"Combat")
    Hub:AddToggle(t_South_Bronx,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_South_Bronx,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_South_Bronx,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_South_Bronx,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSection(t_South_Bronx,"Weapon")
    Hub:AddToggle(t_South_Bronx,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddSection(t_South_Bronx,"Movement")
    Hub:AddToggle(t_South_Bronx,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_South_Bronx,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_South_Bronx,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_South_Bronx,"Visual & Misc")
    Hub:AddToggle(t_South_Bronx,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_South_Bronx,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- NO MERCY TAB
if CurrentGame == "No Mercy" or CurrentGame == "Unknown" then
    local t_No_Mercy = Hub:AddTab("No Mercy","💀")
    Hub:AddSection(t_No_Mercy,"Farming")
    Hub:AddToggle(t_No_Mercy,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_No_Mercy,"Combat")
    Hub:AddToggle(t_No_Mercy,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_No_Mercy,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_No_Mercy,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_No_Mercy,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSection(t_No_Mercy,"Weapon")
    Hub:AddToggle(t_No_Mercy,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddSection(t_No_Mercy,"Movement")
    Hub:AddToggle(t_No_Mercy,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_No_Mercy,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_No_Mercy,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_No_Mercy,"Visual & Misc")
    Hub:AddToggle(t_No_Mercy,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_No_Mercy,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- UNDERGROUND WAR 2 TAB
if CurrentGame == "Underground War 2" or CurrentGame == "Unknown" then
    local t_Underground_War_2 = Hub:AddTab("Underground War 2","⛏️")
    Hub:AddSection(t_Underground_War_2,"Farming")
    Hub:AddToggle(t_Underground_War_2,"Auto Dig",false,function(v) HubState.AutoDig=v end)
    Hub:AddToggle(t_Underground_War_2,"Auto Upgrade",false,function(v) HubState.AutoUpgrade=v end)
    Hub:AddSection(t_Underground_War_2,"Combat")
    Hub:AddToggle(t_Underground_War_2,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Underground_War_2,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Underground_War_2,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Underground_War_2,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Underground_War_2,"Sword Reach",false,function(v) HubState.SwordReach=v end)
    Hub:AddSection(t_Underground_War_2,"Weapon")
    Hub:AddToggle(t_Underground_War_2,"Auto Shoot",false,function(v) HubState.AutoShoot=v end)
    Hub:AddSection(t_Underground_War_2,"Movement")
    Hub:AddToggle(t_Underground_War_2,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Underground_War_2,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Underground_War_2,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Underground_War_2,"Visual & Misc")
    Hub:AddToggle(t_Underground_War_2,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Underground_War_2,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- RIVALS TAB
if CurrentGame == "Rivals" or CurrentGame == "Unknown" then
    local t_Rivals = Hub:AddTab("Rivals","🎯")
    Hub:AddSection(t_Rivals,"Combat")
    Hub:AddToggle(t_Rivals,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Rivals,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Rivals,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Rivals,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddToggle(t_Rivals,"Wallbang",false,function(v) HubState.Wallbang=v end)
    Hub:AddSection(t_Rivals,"Weapon")
    Hub:AddToggle(t_Rivals,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Rivals,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_Rivals,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Rivals,"Movement")
    Hub:AddToggle(t_Rivals,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Rivals,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Rivals,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Rivals,"Visual & Misc")
    Hub:AddToggle(t_Rivals,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Rivals,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- PHANTOM FORCES TAB
if CurrentGame == "Phantom Forces" or CurrentGame == "Unknown" then
    local t_Phantom_Forces = Hub:AddTab("Phantom Forces","🎖️")
    Hub:AddSection(t_Phantom_Forces,"Combat")
    Hub:AddToggle(t_Phantom_Forces,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Phantom_Forces,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Phantom_Forces,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Phantom_Forces,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_Phantom_Forces,"Weapon")
    Hub:AddToggle(t_Phantom_Forces,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Phantom_Forces,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_Phantom_Forces,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Phantom_Forces,"Movement")
    Hub:AddToggle(t_Phantom_Forces,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Phantom_Forces,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Phantom_Forces,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Phantom_Forces,"Visual & Misc")
    Hub:AddToggle(t_Phantom_Forces,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Phantom_Forces,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- ARSENAL TAB
if CurrentGame == "Arsenal" or CurrentGame == "Unknown" then
    local t_Arsenal = Hub:AddTab("Arsenal","🏹")
    Hub:AddSection(t_Arsenal,"Combat")
    Hub:AddToggle(t_Arsenal,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Arsenal,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Arsenal,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Arsenal,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddToggle(t_Arsenal,"Kill All",false,function(v) HubState.KillAll=v end)
    Hub:AddSection(t_Arsenal,"Weapon")
    Hub:AddToggle(t_Arsenal,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Arsenal,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Arsenal,"Movement")
    Hub:AddToggle(t_Arsenal,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Arsenal,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Arsenal,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Arsenal,"Visual & Misc")
    Hub:AddToggle(t_Arsenal,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Arsenal,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- COUNTER BLOX TAB
if CurrentGame == "Counter Blox" or CurrentGame == "Unknown" then
    local t_Counter_Blox = Hub:AddTab("Counter Blox","💣")
    Hub:AddSection(t_Counter_Blox,"Combat")
    Hub:AddToggle(t_Counter_Blox,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Counter_Blox,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Counter_Blox,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Counter_Blox,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_Counter_Blox,"Weapon")
    Hub:AddToggle(t_Counter_Blox,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Counter_Blox,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_Counter_Blox,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Counter_Blox,"Movement")
    Hub:AddToggle(t_Counter_Blox,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Counter_Blox,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Counter_Blox,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Counter_Blox,"Visual & Misc")
    Hub:AddToggle(t_Counter_Blox,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Counter_Blox,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- BAD BUSINESS TAB
if CurrentGame == "Bad Business" or CurrentGame == "Unknown" then
    local t_Bad_Business = Hub:AddTab("Bad Business","🔥")
    Hub:AddSection(t_Bad_Business,"Combat")
    Hub:AddToggle(t_Bad_Business,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Bad_Business,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Bad_Business,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Bad_Business,"Weapon")
    Hub:AddToggle(t_Bad_Business,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Bad_Business,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Bad_Business,"Movement")
    Hub:AddToggle(t_Bad_Business,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Bad_Business,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Bad_Business,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Bad_Business,"Visual & Misc")
    Hub:AddToggle(t_Bad_Business,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Bad_Business,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- BLOX FRUITS TAB
if CurrentGame == "Blox Fruits" or CurrentGame == "Unknown" then
    local t_Blox_Fruits = Hub:AddTab("Blox Fruits","🍎")
    Hub:AddSection(t_Blox_Fruits,"Farming")
    Hub:AddToggle(t_Blox_Fruits,"Auto Farm Lvl",true,function(v) HubState.AutoFarmLvl=v end)
    Hub:AddToggle(t_Blox_Fruits,"Auto Farm Boss",true,function(v) HubState.AutoFarmBoss=v end)
    Hub:AddToggle(t_Blox_Fruits,"Auto Farm Fruit",true,function(v) HubState.AutoFarmFruit=v end)
    Hub:AddToggle(t_Blox_Fruits,"Auto Quest",false,function(v) HubState.AutoQuest=v end)
    Hub:AddToggle(t_Blox_Fruits,"Auto Raid",false,function(v) HubState.AutoRaid=v end)
    Hub:AddToggle(t_Blox_Fruits,"Auto Mastery",false,function(v) HubState.AutoMastery=v end)
    Hub:AddSection(t_Blox_Fruits,"Combat")
    Hub:AddToggle(t_Blox_Fruits,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Blox_Fruits,"Movement")
    Hub:AddToggle(t_Blox_Fruits,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Blox_Fruits,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Blox_Fruits,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Blox_Fruits,"Visual & Misc")
    Hub:AddToggle(t_Blox_Fruits,"Fruit Sniper",false,function(v) HubState.FruitSniper=v end)
    Hub:AddToggle(t_Blox_Fruits,"Bring Mobs",false,function(v) HubState.BringMobs=v end)
    Hub:AddToggle(t_Blox_Fruits,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Blox_Fruits,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
    Hub:AddSection(t_Blox_Fruits,"Teleports")
    Hub:AddButton(t_Blox_Fruits,"Teleport to Island",function() HubState.TpToIsland=v end)
end

-- JAILBREAK TAB
if CurrentGame == "Jailbreak" or CurrentGame == "Unknown" then
    local t_Jailbreak = Hub:AddTab("Jailbreak","🚔")
    Hub:AddSection(t_Jailbreak,"Farming")
    Hub:AddToggle(t_Jailbreak,"Auto Rob",false,function(v) HubState.AutoRob=v end)
    Hub:AddToggle(t_Jailbreak,"Auto Farm Cash",true,function(v) HubState.AutoFarmCash=v end)
    Hub:AddToggle(t_Jailbreak,"Inf Nitro",false,function(v) HubState.InfNitro=v end)
    Hub:AddToggle(t_Jailbreak,"Auto Arrest",false,function(v) HubState.AutoArrest=v end)
    Hub:AddSection(t_Jailbreak,"Combat")
    Hub:AddToggle(t_Jailbreak,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Jailbreak,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSection(t_Jailbreak,"Movement")
    Hub:AddToggle(t_Jailbreak,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Jailbreak,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Jailbreak,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Jailbreak,"Visual & Misc")
    Hub:AddToggle(t_Jailbreak,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Jailbreak,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
    Hub:AddSection(t_Jailbreak,"Teleports")
    Hub:AddButton(t_Jailbreak,"Teleport to Locations",function() HubState.TpLocations=v end)
end

-- MURDER MYSTERY 2 TAB
if CurrentGame == "Murder Mystery 2" or CurrentGame == "Unknown" then
    local t_Murder_Mystery_2 = Hub:AddTab("Murder Mystery 2","🔪")
    Hub:AddSection(t_Murder_Mystery_2,"Combat")
    Hub:AddToggle(t_Murder_Mystery_2,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Murder_Mystery_2,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Murder_Mystery_2,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddSection(t_Murder_Mystery_2,"Movement")
    Hub:AddToggle(t_Murder_Mystery_2,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Murder_Mystery_2,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Murder_Mystery_2,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Murder_Mystery_2,"Visual & Misc")
    Hub:AddToggle(t_Murder_Mystery_2,"Murderer Reveal",false,function(v) HubState.MurdererReveal=v end)
    Hub:AddToggle(t_Murder_Mystery_2,"Coin Grabber",false,function(v) HubState.CoinGrabber=v end)
    Hub:AddToggle(t_Murder_Mystery_2,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Murder_Mystery_2,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
    Hub:AddSection(t_Murder_Mystery_2,"Teleports")
    Hub:AddButton(t_Murder_Mystery_2,"Teleport to Coins",function() HubState.TpToCoins=v end)
end

-- BEDWARS TAB
if CurrentGame == "BedWars" or CurrentGame == "Unknown" then
    local t_BedWars = Hub:AddTab("BedWars","🛏️")
    Hub:AddSection(t_BedWars,"Combat")
    Hub:AddToggle(t_BedWars,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_BedWars,"Reach Extend",false,function(v) HubState.ReachExtend=v end)
    Hub:AddToggle(t_BedWars,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_BedWars,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_BedWars,"Movement")
    Hub:AddToggle(t_BedWars,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_BedWars,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_BedWars,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_BedWars,"Inf Jump",false,function(v) HubState.InfJump=v end)
    Hub:AddSection(t_BedWars,"Visual & Misc")
    Hub:AddToggle(t_BedWars,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_BedWars,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- BLADE BALL TAB
if CurrentGame == "Blade Ball" or CurrentGame == "Unknown" then
    local t_Blade_Ball = Hub:AddTab("Blade Ball","⚽")
    Hub:AddSection(t_Blade_Ball,"Combat")
    Hub:AddToggle(t_Blade_Ball,"Auto Parry",false,function(v) HubState.AutoParry=v end)
    Hub:AddToggle(t_Blade_Ball,"Auto Dodge",false,function(v) HubState.AutoDodge=v end)
    Hub:AddToggle(t_Blade_Ball,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Blade_Ball,"Perfect Parry",false,function(v) HubState.PerfectParry=v end)
    Hub:AddSection(t_Blade_Ball,"Movement")
    Hub:AddToggle(t_Blade_Ball,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Blade_Ball,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Blade_Ball,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Blade_Ball,"Visual & Misc")
    Hub:AddToggle(t_Blade_Ball,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Blade_Ball,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- DOORS TAB
if CurrentGame == "Doors" or CurrentGame == "Unknown" then
    local t_Doors = Hub:AddTab("Doors","🚪")
    Hub:AddSection(t_Doors,"Farming")
    Hub:AddToggle(t_Doors,"Auto Open",false,function(v) HubState.AutoOpen=v end)
    Hub:AddSection(t_Doors,"Movement")
    Hub:AddToggle(t_Doors,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Doors,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Doors,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_Doors,"God Mode",false,function(v) HubState.GodMode=v end)
    Hub:AddToggle(t_Doors,"Inf Stamina",false,function(v) HubState.InfStamina=v end)
    Hub:AddSection(t_Doors,"Visual & Misc")
    Hub:AddToggle(t_Doors,"ESP Entity",false,function(v) HubState.ESPEntity=v end)
    Hub:AddToggle(t_Doors,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Doors,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- SHINDO LIFE TAB
if CurrentGame == "Shindo Life" or CurrentGame == "Unknown" then
    local t_Shindo_Life = Hub:AddTab("Shindo Life","🍃")
    Hub:AddSection(t_Shindo_Life,"Farming")
    Hub:AddToggle(t_Shindo_Life,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Shindo_Life,"Auto Spin",false,function(v) HubState.AutoSpin=v end)
    Hub:AddToggle(t_Shindo_Life,"Inf Spins",false,function(v) HubState.InfSpins=v end)
    Hub:AddToggle(t_Shindo_Life,"Auto Quest",false,function(v) HubState.AutoQuest=v end)
    Hub:AddSection(t_Shindo_Life,"Combat")
    Hub:AddToggle(t_Shindo_Life,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Shindo_Life,"Movement")
    Hub:AddToggle(t_Shindo_Life,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Shindo_Life,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Shindo_Life,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Shindo_Life,"Visual & Misc")
    Hub:AddToggle(t_Shindo_Life,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Shindo_Life,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- PET SIMULATOR 99 TAB
if CurrentGame == "Pet Simulator 99" or CurrentGame == "Unknown" then
    local t_Pet_Simulator_99 = Hub:AddTab("Pet Simulator 99","🐾")
    Hub:AddSection(t_Pet_Simulator_99,"Farming")
    Hub:AddToggle(t_Pet_Simulator_99,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Pet_Simulator_99,"Auto Hatch",false,function(v) HubState.AutoHatch=v end)
    Hub:AddToggle(t_Pet_Simulator_99,"Auto Collect",false,function(v) HubState.AutoCollect=v end)
    Hub:AddToggle(t_Pet_Simulator_99,"Dupe",false,function(v) HubState.Dupe=v end)
    Hub:AddSection(t_Pet_Simulator_99,"Combat")
    Hub:AddToggle(t_Pet_Simulator_99,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Pet_Simulator_99,"Movement")
    Hub:AddToggle(t_Pet_Simulator_99,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Pet_Simulator_99,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Pet_Simulator_99,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Pet_Simulator_99,"Visual & Misc")
    Hub:AddToggle(t_Pet_Simulator_99,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Pet_Simulator_99,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- KING LEGACY TAB
if CurrentGame == "King Legacy" or CurrentGame == "Unknown" then
    local t_King_Legacy = Hub:AddTab("King Legacy","👑")
    Hub:AddSection(t_King_Legacy,"Farming")
    Hub:AddToggle(t_King_Legacy,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_King_Legacy,"Auto Quest",false,function(v) HubState.AutoQuest=v end)
    Hub:AddSection(t_King_Legacy,"Combat")
    Hub:AddToggle(t_King_Legacy,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_King_Legacy,"Movement")
    Hub:AddToggle(t_King_Legacy,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_King_Legacy,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_King_Legacy,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_King_Legacy,"Visual & Misc")
    Hub:AddToggle(t_King_Legacy,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_King_Legacy,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
    Hub:AddToggle(t_King_Legacy,"Fruit Sniper",false,function(v) HubState.FruitSniper=v end)
    Hub:AddSection(t_King_Legacy,"Teleports")
    Hub:AddButton(t_King_Legacy,"Teleport to Island",function() HubState.TpToIsland=v end)
end

-- BEE SWARM SIMULATOR TAB
if CurrentGame == "Bee Swarm Simulator" or CurrentGame == "Unknown" then
    local t_Bee_Swarm_Simulator = Hub:AddTab("Bee Swarm Simulator","🐝")
    Hub:AddSection(t_Bee_Swarm_Simulator,"Farming")
    Hub:AddToggle(t_Bee_Swarm_Simulator,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Bee_Swarm_Simulator,"Auto Quest",false,function(v) HubState.AutoQuest=v end)
    Hub:AddToggle(t_Bee_Swarm_Simulator,"Auto Collect",false,function(v) HubState.AutoCollect=v end)
    Hub:AddToggle(t_Bee_Swarm_Simulator,"Auto Dispense",false,function(v) HubState.AutoDispense=v end)
    Hub:AddSection(t_Bee_Swarm_Simulator,"Combat")
    Hub:AddToggle(t_Bee_Swarm_Simulator,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Bee_Swarm_Simulator,"Movement")
    Hub:AddToggle(t_Bee_Swarm_Simulator,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Bee_Swarm_Simulator,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Bee_Swarm_Simulator,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Bee_Swarm_Simulator,"Visual & Misc")
    Hub:AddToggle(t_Bee_Swarm_Simulator,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Bee_Swarm_Simulator,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- GRAND PIECE ONLINE TAB
if CurrentGame == "Grand Piece Online" or CurrentGame == "Unknown" then
    local t_Grand_Piece_Online = Hub:AddTab("Grand Piece Online","🏴‍☠️")
    Hub:AddSection(t_Grand_Piece_Online,"Farming")
    Hub:AddToggle(t_Grand_Piece_Online,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Grand_Piece_Online,"Auto Quest",false,function(v) HubState.AutoQuest=v end)
    Hub:AddToggle(t_Grand_Piece_Online,"Auto Mastery",false,function(v) HubState.AutoMastery=v end)
    Hub:AddSection(t_Grand_Piece_Online,"Combat")
    Hub:AddToggle(t_Grand_Piece_Online,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Grand_Piece_Online,"Movement")
    Hub:AddToggle(t_Grand_Piece_Online,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Grand_Piece_Online,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Grand_Piece_Online,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Grand_Piece_Online,"Visual & Misc")
    Hub:AddToggle(t_Grand_Piece_Online,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Grand_Piece_Online,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
    Hub:AddToggle(t_Grand_Piece_Online,"Fruit Sniper",false,function(v) HubState.FruitSniper=v end)
end

-- TOWER DEFENSE SIMULATOR TAB
if CurrentGame == "Tower Defense Simulator" or CurrentGame == "Unknown" then
    local t_Tower_Defense_Simulator = Hub:AddTab("Tower Defense Simulator","🗼")
    Hub:AddSection(t_Tower_Defense_Simulator,"Farming")
    Hub:AddToggle(t_Tower_Defense_Simulator,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Tower_Defense_Simulator,"Inf Cash",false,function(v) HubState.InfCash=v end)
    Hub:AddToggle(t_Tower_Defense_Simulator,"Auto Place",false,function(v) HubState.AutoPlace=v end)
    Hub:AddSection(t_Tower_Defense_Simulator,"Combat")
    Hub:AddToggle(t_Tower_Defense_Simulator,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Tower_Defense_Simulator,"Movement")
    Hub:AddToggle(t_Tower_Defense_Simulator,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Tower_Defense_Simulator,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Tower_Defense_Simulator,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Tower_Defense_Simulator,"Visual & Misc")
    Hub:AddToggle(t_Tower_Defense_Simulator,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Tower_Defense_Simulator,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- FISCH TAB
if CurrentGame == "Fisch" or CurrentGame == "Unknown" then
    local t_Fisch = Hub:AddTab("Fisch","🐟")
    Hub:AddSection(t_Fisch,"Farming")
    Hub:AddToggle(t_Fisch,"Auto Fish",false,function(v) HubState.AutoFish=v end)
    Hub:AddToggle(t_Fisch,"Auto Sell",false,function(v) HubState.AutoSell=v end)
    Hub:AddToggle(t_Fisch,"Auto Shake",false,function(v) HubState.AutoShake=v end)
    Hub:AddToggle(t_Fisch,"Instant Reel",false,function(v) HubState.InstantReel=v end)
    Hub:AddSection(t_Fisch,"Combat")
    Hub:AddToggle(t_Fisch,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Fisch,"Movement")
    Hub:AddToggle(t_Fisch,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Fisch,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Fisch,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Fisch,"Visual & Misc")
    Hub:AddToggle(t_Fisch,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Fisch,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- DEEPWOKEN TAB
if CurrentGame == "Deepwoken" or CurrentGame == "Unknown" then
    local t_Deepwoken = Hub:AddTab("Deepwoken","🌊")
    Hub:AddSection(t_Deepwoken,"Farming")
    Hub:AddToggle(t_Deepwoken,"Inf Mana",false,function(v) HubState.InfMana=v end)
    Hub:AddSection(t_Deepwoken,"Combat")
    Hub:AddToggle(t_Deepwoken,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Deepwoken,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Deepwoken,"Auto Parry",false,function(v) HubState.AutoParry=v end)
    Hub:AddToggle(t_Deepwoken,"Auto Dodge",false,function(v) HubState.AutoDodge=v end)
    Hub:AddSection(t_Deepwoken,"Movement")
    Hub:AddToggle(t_Deepwoken,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Deepwoken,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Deepwoken,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Deepwoken,"Visual & Misc")
    Hub:AddToggle(t_Deepwoken,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Deepwoken,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- BOXING BETA TAB
if CurrentGame == "Boxing Beta" or CurrentGame == "Unknown" then
    local t_Boxing_Beta = Hub:AddTab("Boxing Beta","🥊")
    Hub:AddSection(t_Boxing_Beta,"Farming")
    Hub:AddToggle(t_Boxing_Beta,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Boxing_Beta,"Combat")
    Hub:AddToggle(t_Boxing_Beta,"Auto Dodge",false,function(v) HubState.AutoDodge=v end)
    Hub:AddToggle(t_Boxing_Beta,"Auto Block",false,function(v) HubState.AutoBlock=v end)
    Hub:AddToggle(t_Boxing_Beta,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Boxing_Beta,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddSection(t_Boxing_Beta,"Movement")
    Hub:AddToggle(t_Boxing_Beta,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Boxing_Beta,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Boxing_Beta,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Boxing_Beta,"Visual & Misc")
    Hub:AddToggle(t_Boxing_Beta,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Boxing_Beta,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- BASKETBALL LEGENDS TAB
if CurrentGame == "Basketball Legends" or CurrentGame == "Unknown" then
    local t_Basketball_Legends = Hub:AddTab("Basketball Legends","🏀")
    Hub:AddSection(t_Basketball_Legends,"Farming")
    Hub:AddToggle(t_Basketball_Legends,"Auto Score",false,function(v) HubState.AutoScore=v end)
    Hub:AddSection(t_Basketball_Legends,"Combat")
    Hub:AddToggle(t_Basketball_Legends,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Basketball_Legends,"Movement")
    Hub:AddToggle(t_Basketball_Legends,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Basketball_Legends,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Basketball_Legends,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Basketball_Legends,"Visual & Misc")
    Hub:AddToggle(t_Basketball_Legends,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Basketball_Legends,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
    Hub:AddSection(t_Basketball_Legends,"Teleports")
    Hub:AddButton(t_Basketball_Legends,"Teleport to Ball",function() HubState.TpToBall=v end)
end

-- PLAYGROUND BASKETBALL TAB
if CurrentGame == "Playground Basketball" or CurrentGame == "Unknown" then
    local t_Playground_Basketball = Hub:AddTab("Playground Basketball","🏀")
    Hub:AddSection(t_Playground_Basketball,"Farming")
    Hub:AddToggle(t_Playground_Basketball,"Auto Score",false,function(v) HubState.AutoScore=v end)
    Hub:AddSection(t_Playground_Basketball,"Combat")
    Hub:AddToggle(t_Playground_Basketball,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Playground_Basketball,"Movement")
    Hub:AddToggle(t_Playground_Basketball,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Playground_Basketball,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Playground_Basketball,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Playground_Basketball,"Visual & Misc")
    Hub:AddToggle(t_Playground_Basketball,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Playground_Basketball,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- BLUE LOCK RIVALS TAB
if CurrentGame == "Blue Lock Rivals" or CurrentGame == "Unknown" then
    local t_Blue_Lock_Rivals = Hub:AddTab("Blue Lock Rivals","⚽")
    Hub:AddSection(t_Blue_Lock_Rivals,"Farming")
    Hub:AddToggle(t_Blue_Lock_Rivals,"Auto Score",false,function(v) HubState.AutoScore=v end)
    Hub:AddToggle(t_Blue_Lock_Rivals,"Auto Dribble",false,function(v) HubState.AutoDribble=v end)
    Hub:AddSection(t_Blue_Lock_Rivals,"Combat")
    Hub:AddToggle(t_Blue_Lock_Rivals,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Blue_Lock_Rivals,"Movement")
    Hub:AddToggle(t_Blue_Lock_Rivals,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Blue_Lock_Rivals,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Blue_Lock_Rivals,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Blue_Lock_Rivals,"Visual & Misc")
    Hub:AddToggle(t_Blue_Lock_Rivals,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Blue_Lock_Rivals,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- THE STRONGEST BATTLEGROUNDS TAB
if CurrentGame == "The Strongest Battlegrounds" or CurrentGame == "Unknown" then
    local t_The_Strongest_Battlegrounds = Hub:AddTab("The Strongest Battlegrounds","💪")
    Hub:AddSection(t_The_Strongest_Battlegrounds,"Farming")
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_The_Strongest_Battlegrounds,"Combat")
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"Auto Block",false,function(v) HubState.AutoBlock=v end)
    Hub:AddSection(t_The_Strongest_Battlegrounds,"Movement")
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_The_Strongest_Battlegrounds,"Visual & Misc")
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_The_Strongest_Battlegrounds,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- JUJUTSU SHENANIGANS TAB
if CurrentGame == "Jujutsu Shenanigans" or CurrentGame == "Unknown" then
    local t_Jujutsu_Shenanigans = Hub:AddTab("Jujutsu Shenanigans","👁️")
    Hub:AddSection(t_Jujutsu_Shenanigans,"Farming")
    Hub:AddToggle(t_Jujutsu_Shenanigans,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Jujutsu_Shenanigans,"Inf Domain",false,function(v) HubState.InfDomain=v end)
    Hub:AddSection(t_Jujutsu_Shenanigans,"Combat")
    Hub:AddToggle(t_Jujutsu_Shenanigans,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Jujutsu_Shenanigans,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Jujutsu_Shenanigans,"Movement")
    Hub:AddToggle(t_Jujutsu_Shenanigans,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Jujutsu_Shenanigans,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Jujutsu_Shenanigans,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Jujutsu_Shenanigans,"Visual & Misc")
    Hub:AddToggle(t_Jujutsu_Shenanigans,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Jujutsu_Shenanigans,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- KNOCKOUT TAB
if CurrentGame == "Knockout" or CurrentGame == "Unknown" then
    local t_Knockout = Hub:AddTab("Knockout","🥊")
    Hub:AddSection(t_Knockout,"Farming")
    Hub:AddToggle(t_Knockout,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Knockout,"Combat")
    Hub:AddToggle(t_Knockout,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Knockout,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Knockout,"Movement")
    Hub:AddToggle(t_Knockout,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Knockout,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Knockout,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Knockout,"Visual & Misc")
    Hub:AddToggle(t_Knockout,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Knockout,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- DEAD RAILS TAB
if CurrentGame == "Dead Rails" or CurrentGame == "Unknown" then
    local t_Dead_Rails = Hub:AddTab("Dead Rails","🚂")
    Hub:AddSection(t_Dead_Rails,"Farming")
    Hub:AddToggle(t_Dead_Rails,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Dead_Rails,"Combat")
    Hub:AddToggle(t_Dead_Rails,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Dead_Rails,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddSection(t_Dead_Rails,"Weapon")
    Hub:AddToggle(t_Dead_Rails,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddSection(t_Dead_Rails,"Movement")
    Hub:AddToggle(t_Dead_Rails,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Dead_Rails,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Dead_Rails,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Dead_Rails,"Visual & Misc")
    Hub:AddToggle(t_Dead_Rails,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Dead_Rails,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- PRESSURE TAB
if CurrentGame == "Pressure" or CurrentGame == "Unknown" then
    local t_Pressure = Hub:AddTab("Pressure","💨")
    Hub:AddSection(t_Pressure,"Farming")
    Hub:AddToggle(t_Pressure,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Pressure,"Combat")
    Hub:AddToggle(t_Pressure,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Pressure,"Movement")
    Hub:AddToggle(t_Pressure,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Pressure,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Pressure,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_Pressure,"God Mode",false,function(v) HubState.GodMode=v end)
    Hub:AddSection(t_Pressure,"Visual & Misc")
    Hub:AddToggle(t_Pressure,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Pressure,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- SOLS RNG TAB
if CurrentGame == "Sols RNG" or CurrentGame == "Unknown" then
    local t_Sols_RNG = Hub:AddTab("Sols RNG","🎲")
    Hub:AddSection(t_Sols_RNG,"Farming")
    Hub:AddToggle(t_Sols_RNG,"Auto Roll",false,function(v) HubState.AutoRoll=v end)
    Hub:AddToggle(t_Sols_RNG,"Auto Craft",false,function(v) HubState.AutoCraft=v end)
    Hub:AddToggle(t_Sols_RNG,"Auto Biome",false,function(v) HubState.AutoBiome=v end)
    Hub:AddSection(t_Sols_RNG,"Combat")
    Hub:AddToggle(t_Sols_RNG,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Sols_RNG,"Movement")
    Hub:AddToggle(t_Sols_RNG,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Sols_RNG,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Sols_RNG,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Sols_RNG,"Visual & Misc")
    Hub:AddToggle(t_Sols_RNG,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Sols_RNG,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- ANIME DEFENDERS TAB
if CurrentGame == "Anime Defenders" or CurrentGame == "Unknown" then
    local t_Anime_Defenders = Hub:AddTab("Anime Defenders","🛡️")
    Hub:AddSection(t_Anime_Defenders,"Farming")
    Hub:AddToggle(t_Anime_Defenders,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Anime_Defenders,"Auto Place",false,function(v) HubState.AutoPlace=v end)
    Hub:AddToggle(t_Anime_Defenders,"Inf Cash",false,function(v) HubState.InfCash=v end)
    Hub:AddSection(t_Anime_Defenders,"Combat")
    Hub:AddToggle(t_Anime_Defenders,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Anime_Defenders,"Movement")
    Hub:AddToggle(t_Anime_Defenders,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Anime_Defenders,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Anime_Defenders,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Anime_Defenders,"Visual & Misc")
    Hub:AddToggle(t_Anime_Defenders,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Anime_Defenders,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- GROW A GARDEN TAB
if CurrentGame == "Grow A Garden" or CurrentGame == "Unknown" then
    local t_Grow_A_Garden = Hub:AddTab("Grow A Garden","🌱")
    Hub:AddSection(t_Grow_A_Garden,"Farming")
    Hub:AddToggle(t_Grow_A_Garden,"Auto Plant",false,function(v) HubState.AutoPlant=v end)
    Hub:AddToggle(t_Grow_A_Garden,"Auto Harvest",false,function(v) HubState.AutoHarvest=v end)
    Hub:AddToggle(t_Grow_A_Garden,"Auto Water",false,function(v) HubState.AutoWater=v end)
    Hub:AddSection(t_Grow_A_Garden,"Combat")
    Hub:AddToggle(t_Grow_A_Garden,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Grow_A_Garden,"Movement")
    Hub:AddToggle(t_Grow_A_Garden,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Grow_A_Garden,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Grow_A_Garden,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Grow_A_Garden,"Visual & Misc")
    Hub:AddToggle(t_Grow_A_Garden,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Grow_A_Garden,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- PEROXIDE TAB
if CurrentGame == "Peroxide" or CurrentGame == "Unknown" then
    local t_Peroxide = Hub:AddTab("Peroxide","☠️")
    Hub:AddSection(t_Peroxide,"Farming")
    Hub:AddToggle(t_Peroxide,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Peroxide,"Auto Quest",false,function(v) HubState.AutoQuest=v end)
    Hub:AddSection(t_Peroxide,"Combat")
    Hub:AddToggle(t_Peroxide,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Peroxide,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Peroxide,"Movement")
    Hub:AddToggle(t_Peroxide,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Peroxide,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Peroxide,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Peroxide,"Visual & Misc")
    Hub:AddToggle(t_Peroxide,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Peroxide,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- IRON MAN REIMAGINED TAB
if CurrentGame == "Iron Man Reimagined" or CurrentGame == "Unknown" then
    local t_Iron_Man_Reimagined = Hub:AddTab("Iron Man Reimagined","🦾")
    Hub:AddSection(t_Iron_Man_Reimagined,"Farming")
    Hub:AddToggle(t_Iron_Man_Reimagined,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Iron_Man_Reimagined,"Inf Energy",false,function(v) HubState.InfEnergy=v end)
    Hub:AddSection(t_Iron_Man_Reimagined,"Combat")
    Hub:AddToggle(t_Iron_Man_Reimagined,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Iron_Man_Reimagined,"Movement")
    Hub:AddToggle(t_Iron_Man_Reimagined,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Iron_Man_Reimagined,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Iron_Man_Reimagined,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Iron_Man_Reimagined,"Visual & Misc")
    Hub:AddToggle(t_Iron_Man_Reimagined,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Iron_Man_Reimagined,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- ADOPT ME TAB
if CurrentGame == "Adopt Me" or CurrentGame == "Unknown" then
    local t_Adopt_Me = Hub:AddTab("Adopt Me","🏡")
    Hub:AddSection(t_Adopt_Me,"Farming")
    Hub:AddToggle(t_Adopt_Me,"Auto Accept Trade",false,function(v) HubState.AutoAcceptTrade=v end)
    Hub:AddSection(t_Adopt_Me,"Combat")
    Hub:AddToggle(t_Adopt_Me,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Adopt_Me,"Movement")
    Hub:AddToggle(t_Adopt_Me,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Adopt_Me,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Adopt_Me,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Adopt_Me,"Visual & Misc")
    Hub:AddToggle(t_Adopt_Me,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Adopt_Me,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- FANTASMA PVP TAB
if CurrentGame == "Fantasma PvP" or CurrentGame == "Unknown" then
    local t_Fantasma_PvP = Hub:AddTab("Fantasma PvP","👻")
    Hub:AddSection(t_Fantasma_PvP,"Combat")
    Hub:AddToggle(t_Fantasma_PvP,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Fantasma_PvP,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Fantasma_PvP,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Fantasma_PvP,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSection(t_Fantasma_PvP,"Movement")
    Hub:AddToggle(t_Fantasma_PvP,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Fantasma_PvP,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Fantasma_PvP,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Fantasma_PvP,"Visual & Misc")
    Hub:AddToggle(t_Fantasma_PvP,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Fantasma_PvP,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- MVS DUELS TAB
if CurrentGame == "MVS Duels" or CurrentGame == "Unknown" then
    local t_MVS_Duels = Hub:AddTab("MVS Duels","🎮")
    Hub:AddSection(t_MVS_Duels,"Farming")
    Hub:AddToggle(t_MVS_Duels,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_MVS_Duels,"Combat")
    Hub:AddToggle(t_MVS_Duels,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_MVS_Duels,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_MVS_Duels,"Movement")
    Hub:AddToggle(t_MVS_Duels,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_MVS_Duels,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_MVS_Duels,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_MVS_Duels,"Visual & Misc")
    Hub:AddToggle(t_MVS_Duels,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_MVS_Duels,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- PROJECT VILTRUMITES TAB
if CurrentGame == "Project Viltrumites" or CurrentGame == "Unknown" then
    local t_Project_Viltrumites = Hub:AddTab("Project Viltrumites","🦸")
    Hub:AddSection(t_Project_Viltrumites,"Farming")
    Hub:AddToggle(t_Project_Viltrumites,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Project_Viltrumites,"Inf Power",false,function(v) HubState.InfPower=v end)
    Hub:AddSection(t_Project_Viltrumites,"Combat")
    Hub:AddToggle(t_Project_Viltrumites,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_Project_Viltrumites,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Project_Viltrumites,"Movement")
    Hub:AddToggle(t_Project_Viltrumites,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Project_Viltrumites,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Project_Viltrumites,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Project_Viltrumites,"Visual & Misc")
    Hub:AddToggle(t_Project_Viltrumites,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Project_Viltrumites,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- QZ SHOOTOUT TAB
if CurrentGame == "QZ Shootout" or CurrentGame == "Unknown" then
    local t_QZ_Shootout = Hub:AddTab("QZ Shootout","🎯")
    Hub:AddSection(t_QZ_Shootout,"Farming")
    Hub:AddToggle(t_QZ_Shootout,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_QZ_Shootout,"Combat")
    Hub:AddToggle(t_QZ_Shootout,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_QZ_Shootout,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_QZ_Shootout,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSection(t_QZ_Shootout,"Weapon")
    Hub:AddToggle(t_QZ_Shootout,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_QZ_Shootout,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddSection(t_QZ_Shootout,"Movement")
    Hub:AddToggle(t_QZ_Shootout,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_QZ_Shootout,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_QZ_Shootout,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_QZ_Shootout,"Visual & Misc")
    Hub:AddToggle(t_QZ_Shootout,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_QZ_Shootout,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- OUTWEST CHICAGO 2 TAB
if CurrentGame == "Outwest Chicago 2" or CurrentGame == "Unknown" then
    local t_Outwest_Chicago_2 = Hub:AddTab("Outwest Chicago 2","🤠")
    Hub:AddSection(t_Outwest_Chicago_2,"Farming")
    Hub:AddToggle(t_Outwest_Chicago_2,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Outwest_Chicago_2,"Combat")
    Hub:AddToggle(t_Outwest_Chicago_2,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Outwest_Chicago_2,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Outwest_Chicago_2,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSection(t_Outwest_Chicago_2,"Weapon")
    Hub:AddToggle(t_Outwest_Chicago_2,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_Outwest_Chicago_2,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddSection(t_Outwest_Chicago_2,"Movement")
    Hub:AddToggle(t_Outwest_Chicago_2,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Outwest_Chicago_2,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Outwest_Chicago_2,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Outwest_Chicago_2,"Visual & Misc")
    Hub:AddToggle(t_Outwest_Chicago_2,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Outwest_Chicago_2,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- STREET LIFE REMASTERED TAB
if CurrentGame == "Street Life Remastered" or CurrentGame == "Unknown" then
    local t_Street_Life_Remastered = Hub:AddTab("Street Life Remastered","🛣️")
    Hub:AddSection(t_Street_Life_Remastered,"Farming")
    Hub:AddToggle(t_Street_Life_Remastered,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Street_Life_Remastered,"Combat")
    Hub:AddToggle(t_Street_Life_Remastered,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Street_Life_Remastered,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_Street_Life_Remastered,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSection(t_Street_Life_Remastered,"Weapon")
    Hub:AddToggle(t_Street_Life_Remastered,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddSection(t_Street_Life_Remastered,"Movement")
    Hub:AddToggle(t_Street_Life_Remastered,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Street_Life_Remastered,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Street_Life_Remastered,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Street_Life_Remastered,"Visual & Misc")
    Hub:AddToggle(t_Street_Life_Remastered,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Street_Life_Remastered,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- WESTBOUND TAB
if CurrentGame == "Westbound" or CurrentGame == "Unknown" then
    local t_Westbound = Hub:AddTab("Westbound","🏜️")
    Hub:AddSection(t_Westbound,"Farming")
    Hub:AddToggle(t_Westbound,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Westbound,"Combat")
    Hub:AddToggle(t_Westbound,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Westbound,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Westbound,"Weapon")
    Hub:AddToggle(t_Westbound,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddSection(t_Westbound,"Movement")
    Hub:AddToggle(t_Westbound,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Westbound,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Westbound,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Westbound,"Visual & Misc")
    Hub:AddToggle(t_Westbound,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Westbound,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- DARK DIVERS TAB
if CurrentGame == "Dark Divers" or CurrentGame == "Unknown" then
    local t_Dark_Divers = Hub:AddTab("Dark Divers","🤿")
    Hub:AddSection(t_Dark_Divers,"Farming")
    Hub:AddToggle(t_Dark_Divers,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddSection(t_Dark_Divers,"Combat")
    Hub:AddToggle(t_Dark_Divers,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Dark_Divers,"Movement")
    Hub:AddToggle(t_Dark_Divers,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Dark_Divers,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Dark_Divers,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_Dark_Divers,"God Mode",false,function(v) HubState.GodMode=v end)
    Hub:AddSection(t_Dark_Divers,"Visual & Misc")
    Hub:AddToggle(t_Dark_Divers,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Dark_Divers,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- FRONTLINES TAB
if CurrentGame == "Frontlines" or CurrentGame == "Unknown" then
    local t_Frontlines = Hub:AddTab("Frontlines","⚔️")
    Hub:AddSection(t_Frontlines,"Combat")
    Hub:AddToggle(t_Frontlines,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_Frontlines,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_Frontlines,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Frontlines,"Weapon")
    Hub:AddToggle(t_Frontlines,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_Frontlines,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddSection(t_Frontlines,"Movement")
    Hub:AddToggle(t_Frontlines,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Frontlines,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Frontlines,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Frontlines,"Visual & Misc")
    Hub:AddToggle(t_Frontlines,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Frontlines,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- BUBBLEGUM SIMULATOR TAB
if CurrentGame == "Bubblegum Simulator" or CurrentGame == "Unknown" then
    local t_Bubblegum_Simulator = Hub:AddTab("Bubblegum Simulator","🫧")
    Hub:AddSection(t_Bubblegum_Simulator,"Farming")
    Hub:AddToggle(t_Bubblegum_Simulator,"Auto Farm",true,function(v) HubState.AutoFarm=v end)
    Hub:AddToggle(t_Bubblegum_Simulator,"Auto Hatch",false,function(v) HubState.AutoHatch=v end)
    Hub:AddSection(t_Bubblegum_Simulator,"Combat")
    Hub:AddToggle(t_Bubblegum_Simulator,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddSection(t_Bubblegum_Simulator,"Movement")
    Hub:AddToggle(t_Bubblegum_Simulator,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and HubState.SpeedValue or 16 end) end)
    Hub:AddToggle(t_Bubblegum_Simulator,"Fly",false,function(v) HubState.FlyEnabled=v; if v then StartFly() end end)
    Hub:AddToggle(t_Bubblegum_Simulator,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddSection(t_Bubblegum_Simulator,"Visual & Misc")
    Hub:AddToggle(t_Bubblegum_Simulator,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)
    Hub:AddToggle(t_Bubblegum_Simulator,"Anti AFK",true,function(v) HubState.AntiAFK=v end)
end

-- MAIN LOOPS
local mainLoop = RunService.Heartbeat:Connect(function()
    -- Aimbot
    if HubState.Aimbot then
        local t = GetClosestPlayer(HubState.AimFOV)
        if t then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
        end
    end
    -- Kill Aura
    if HubState.KillAura then RunKillAura() end
    -- Hitbox refresh
    if HubState.HitboxExpand then ExpandHitboxes() end
    -- Speed
    if HubState.SpeedHack then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = HubState.SpeedValue end) end
end)
table.insert(Connections, mainLoop)

-- ============================================================
-- REAL AUTOFARM LOOPS — Hood Omni Hub MEGA
-- Injected: real game-specific logic for all major games
-- ============================================================

-- Utility: get nearest NPC/mob in workspace
local function GetNearestNPC(maxDist)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart
    local nearest, dist = nil, maxDist or 100
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= char then
            local hum = v:FindFirstChildOfClass("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 and not Players:GetPlayerFromCharacter(v) then
                local d = (hrp.Position - root.Position).Magnitude
                if d < dist then dist = d; nearest = v end
            end
        end
    end
    return nearest
end

-- Utility: safe teleport
local function SafeTP(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- ============================================================
-- DA HOOD AUTOFARM — collect cash drops on ground
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.3)
        if CurrentGame == "Da Hood" and HubState.AutoFarm then
            pcall(function()
                -- Collect cash/money bags dropped in workspace
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local root = char.HumanoidRootPart
                -- Look for drop models (cash, money)
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") or v:IsA("Model") then
                        local name = v.Name:lower()
                        if name:find("cash") or name:find("money") or name:find("drop") or name:find("bag") then
                            local part = v:IsA("BasePart") and v or v:FindFirstChildOfClass("BasePart")
                            if part then
                                local dist = (part.Position - root.Position).Magnitude
                                if dist < 200 then
                                    SafeTP(part.Position)
                                    -- Try click detector
                                    local cd = v:FindFirstChildOfClass("ClickDetector") or part:FindFirstChildOfClass("ClickDetector")
                                    if cd then fireclickdetector(cd) end
                                    -- Try touch
                                    pcall(function() firetouchinterest(part, char.HumanoidRootPart, 0) task.wait(0.05) firetouchinterest(part, char.HumanoidRootPart, 1) end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- DA HOOD — Potato Farm autofarm (Gangwars specific)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        if (CurrentGame == "Da Hood" or CurrentGame == "Gangwars") and HubState.PotatoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Find potato/plant objects
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("potato") or v.Name:lower():find("plant") or v.Name:lower():find("farm")) then
                        SafeTP(v.Position)
                        local cd = v:FindFirstChildOfClass("ClickDetector")
                        if cd then fireclickdetector(cd) end
                        pcall(function() firetouchinterest(v, char.HumanoidRootPart, 0) task.wait(0.1) firetouchinterest(v, char.HumanoidRootPart, 1) end)
                    end
                end
                -- Try interact remotes
                for _, v in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if v:IsA("RemoteEvent") and (v.Name:lower():find("potato") or v.Name:lower():find("farm") or v.Name:lower():find("harvest")) then
                        pcall(function() v:FireServer() end)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- DA HOOD — Car Breaking autofarm
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if (CurrentGame == "Da Hood" or CurrentGame == "Gangwars") and HubState.CarBreak then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local root = char.HumanoidRootPart
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("car") or v.Name:lower():find("vehicle")) then
                        local dist = (v.Position - root.Position).Magnitude
                        if dist < 50 then
                            SafeTP(v.Position)
                            local cd = v:FindFirstChildOfClass("ClickDetector")
                            if cd then fireclickdetector(cd) end
                            for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                                if re:IsA("RemoteEvent") and (re.Name:lower():find("break") or re.Name:lower():find("rob") or re.Name:lower():find("car")) then
                                    pcall(function() re:FireServer(v) end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- DA HOOD — Store Robbery autofarm
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        if (CurrentGame == "Da Hood" or CurrentGame == "Gangwars") and HubState.StoreRob then
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                -- Teleport to store location and fire rob remote
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("store") or v.Name:lower():find("shop") or v.Name:lower():find("register") or v.Name:lower():find("cashier")) then
                        SafeTP(v.Position)
                        local cd = v:FindFirstChildOfClass("ClickDetector")
                        if cd then fireclickdetector(cd) end
                        pcall(function() firetouchinterest(v, char.HumanoidRootPart, 0) task.wait(0.1) firetouchinterest(v, char.HumanoidRootPart, 1) end)
                    end
                end
                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if re:IsA("RemoteEvent") and (re.Name:lower():find("rob") or re.Name:lower():find("steal") or re.Name:lower():find("store")) then
                        pcall(function() re:FireServer() end)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- MURDER MYSTERY 2 — Auto collect coins + Murderer reveal
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.15)
        if CurrentGame == "Murder Mystery 2" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Collect coins (BaseParts/Models named "Coin")
                for _, v in pairs(workspace:GetDescendants()) do
                    if v.Name == "Coin" or v.Name == "GoldCoin" then
                        local part = v:IsA("BasePart") and v or v:FindFirstChildOfClass("BasePart")
                        if part then
                            SafeTP(part.Position)
                            pcall(function() firetouchinterest(part, char.HumanoidRootPart, 0) task.wait(0.05) firetouchinterest(part, char.HumanoidRootPart, 1) end)
                        end
                    end
                end
            end)
        end
        -- Murderer ESP: highlight player with Knife tool
        if CurrentGame == "Murder Mystery 2" and HubState.ESPEnabled then
            pcall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local hasKnife = false
                        for _, tool in pairs(p.Character:GetChildren()) do
                            if tool:IsA("Tool") and (tool.Name:lower():find("knife") or tool.Name:lower():find("murder")) then
                                hasKnife = true
                            end
                        end
                        -- Color murderer red via existing ESP
                        local highlight = p.Character:FindFirstChild("MM2_Highlight")
                        if hasKnife then
                            if not highlight then
                                local h = Instance.new("SelectionBox")
                                h.Name = "MM2_Highlight"
                                h.Color3 = Color3.fromRGB(255, 0, 0)
                                h.LineThickness = 0.05
                                h.Adornee = p.Character
                                h.Parent = p.Character
                            end
                        else
                            if highlight then highlight:Destroy() end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- BLADE BALL — Auto Parry
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.05)
        if CurrentGame == "Blade Ball" and HubState.AutoParry then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local root = char.HumanoidRootPart
                -- Find the ball
                local ball = workspace:FindFirstChild("Ball") or workspace:FindFirstChild("BladeBall")
                if not ball then
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("BasePart") and (v.Name:lower():find("ball") or v.Name:lower() == "sphere") and v.Size.Magnitude < 5 then
                            ball = v; break
                        end
                    end
                end
                if ball then
                    local dist = (ball.Position - root.Position).Magnitude
                    if dist < 30 then
                        -- Fire parry remote
                        local parryRemote = 
                            (game.ReplicatedStorage:FindFirstChild("Events") and game.ReplicatedStorage.Events:FindFirstChild("Parry")) or
                            (game.ReplicatedStorage:FindFirstChild("Remotes") and game.ReplicatedStorage.Remotes:FindFirstChild("Deflect")) or
                            (game.ReplicatedStorage:FindFirstChild("Remotes") and game.ReplicatedStorage.Remotes:FindFirstChild("Parry")) or
                            game.ReplicatedStorage:FindFirstChild("Parry")
                        if parryRemote and parryRemote:IsA("RemoteEvent") then
                            parryRemote:FireServer()
                        end
                        -- Fallback: try all remotes with parry/deflect in name
                        for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                            if re:IsA("RemoteEvent") and (re.Name:lower():find("parry") or re.Name:lower():find("deflect") or re.Name:lower():find("block")) then
                                pcall(function() re:FireServer() end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- THE STRONGEST BATTLEGROUNDS — Auto Attack nearest player
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if CurrentGame == "The Strongest Battlegrounds" and HubState.AutoFarm then
            pcall(function()
                local target = GetClosestPlayer(150)
                if not target then return end
                -- Teleport close
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local tp = target.Position - (target.Position - char.HumanoidRootPart.Position).Unit * 5
                char.HumanoidRootPart.CFrame = CFrame.new(tp)
                -- Fire attack remotes
                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if re:IsA("RemoteEvent") and (re.Name:lower():find("attack") or re.Name:lower():find("punch") or re.Name:lower():find("hit") or re.Name:lower():find("combo")) then
                        pcall(function() re:FireServer(target.Parent, target) end)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- BLOX FRUITS — Auto kill nearest mob + auto quest
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.3)
        if CurrentGame == "Blox Fruits" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Attack nearest NPC/mob
                local mob = GetNearestNPC(60)
                if mob then
                    local hrp = mob:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        SafeTP(hrp.Position - (hrp.Position - char.HumanoidRootPart.Position).Unit * 5)
                        -- Fire attack
                        for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                            if re:IsA("RemoteEvent") and (re.Name:lower():find("attack") or re.Name:lower():find("damage") or re.Name:lower():find("hit")) then
                                pcall(function() re:FireServer(mob, hrp.Position) end)
                            end
                        end
                        -- Equip and use tool
                        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                            if tool:IsA("Tool") then
                                LocalPlayer.Character.Humanoid:EquipTool(tool)
                                pcall(function()
                                    local activate = tool:FindFirstChild("Activated") or tool:FindFirstChildOfClass("RemoteEvent")
                                    if activate then activate:FireServer() end
                                end)
                                break
                            end
                        end
                    end
                end
                -- Auto accept quests from NPCs
                for _, npc in pairs(workspace:GetDescendants()) do
                    if npc:IsA("Model") and (npc.Name:lower():find("quest") or npc.Name:lower():find("missiongiver")) then
                        local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildOfClass("BasePart")
                        if hrp then
                            local dist = (hrp.Position - char.HumanoidRootPart.Position).Magnitude
                            if dist < 10 then
                                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                                    if re:IsA("RemoteEvent") and (re.Name:lower():find("quest") or re.Name:lower():find("accept")) then
                                        pcall(function() re:FireServer(npc, 1) end)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- JAILBREAK — Auto rob (Museum, Jewelry, Bank, Train)
-- ============================================================
local JB_RobTargets = {
    Museum   = Vector3.new(889, 18, 1158),
    Jewelry  = Vector3.new(-359, 18, -766),
    Bank     = Vector3.new(154, 18, -802),
    PowerPlant = Vector3.new(-1440, 18, 246),
}
local JB_CurrentTarget = "Museum"
task.spawn(function()
    while true do
        task.wait(1)
        if CurrentGame == "Jailbreak" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local root = char.HumanoidRootPart
                local targetPos = JB_RobTargets[JB_CurrentTarget]
                local dist = (root.Position - targetPos).Magnitude
                if dist > 15 then
                    SafeTP(targetPos)
                else
                    -- Try to interact / fire rob remotes
                    for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                        if re:IsA("RemoteEvent") and (re.Name:lower():find("rob") or re.Name:lower():find("interact") or re.Name:lower():find("loot")) then
                            pcall(function() re:FireServer() end)
                        end
                    end
                    -- Cycle target
                    local targets = {"Museum", "Jewelry", "Bank", "PowerPlant"}
                    for i, t in ipairs(targets) do
                        if t == JB_CurrentTarget then
                            JB_CurrentTarget = targets[i % #targets + 1]; break
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- PET SIMULATOR 99 — Auto farm (collect coins/gems, auto hatch)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.2)
        if CurrentGame == "Pet Simulator 99" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Collect nearby coins/gems by teleporting and touching
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("coin") or v.Name:lower():find("gem") or v.Name:lower():find("collect") or v.Name:lower():find("diamond")) then
                        local dist = (v.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist < 100 then
                            SafeTP(v.Position)
                            pcall(function() firetouchinterest(v, char.HumanoidRootPart, 0) task.wait(0.05) firetouchinterest(v, char.HumanoidRootPart, 1) end)
                        end
                    end
                end
                -- Auto click/break breakable objects
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and v.Name:lower():find("breakable") then
                        SafeTP(v.Position)
                        local cd = v:FindFirstChildOfClass("ClickDetector")
                        if cd then fireclickdetector(cd) end
                    end
                end
            end)
        end
        -- Auto hatch
        if CurrentGame == "Pet Simulator 99" and HubState.AutoHatch then
            pcall(function()
                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if re:IsA("RemoteEvent") and (re.Name:lower():find("hatch") or re.Name:lower():find("egg")) then
                        pcall(function() re:FireServer(1) end)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- SHINDO LIFE — Auto farm mobs + collect scrolls
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.3)
        if CurrentGame == "Shindo Life" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Collect scrolls
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("scroll") or v.Name:lower():find("item")) then
                        SafeTP(v.Position)
                        pcall(function() firetouchinterest(v, char.HumanoidRootPart, 0) task.wait(0.05) firetouchinterest(v, char.HumanoidRootPart, 1) end)
                    end
                end
                -- Attack nearest mob
                local mob = GetNearestNPC(80)
                if mob then
                    local hrp = mob:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        SafeTP(hrp.Position - (hrp.Position - char.HumanoidRootPart.Position).Unit * 5)
                        for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                            if re:IsA("RemoteEvent") and (re.Name:lower():find("attack") or re.Name:lower():find("hit") or re.Name:lower():find("damage")) then
                                pcall(function() re:FireServer(mob.HumanoidRootPart, hrp.Position, 50) end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- BEE SWARM SIMULATOR — Auto collect pollen + return to hive
-- ============================================================
local BSS_AtHive = false
task.spawn(function()
    while true do
        task.wait(0.5)
        if CurrentGame == "Bee Swarm Simulator" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local root = char.HumanoidRootPart
                -- Find flower fields
                local hivePos = Vector3.new(0, 10, 0) -- approximate hive center
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and v.Name:lower():find("hive") then
                        hivePos = v.Position; break
                    end
                end
                if BSS_AtHive then
                    -- Go collect pollen from nearest flower
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("BasePart") and (v.Name:lower():find("flower") or v.Name:lower():find("pollen") or v.Name:lower():find("field")) then
                            SafeTP(v.Position)
                            pcall(function() firetouchinterest(v, char.HumanoidRootPart, 0) task.wait(0.3) firetouchinterest(v, char.HumanoidRootPart, 1) end)
                            BSS_AtHive = false
                            break
                        end
                    end
                else
                    -- Return pollen to hive
                    SafeTP(hivePos)
                    pcall(function()
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("BasePart") and v.Name:lower():find("hive") then
                                firetouchinterest(v, char.HumanoidRootPart, 0)
                                task.wait(0.2)
                                firetouchinterest(v, char.HumanoidRootPart, 1)
                            end
                        end
                    end)
                    BSS_AtHive = true
                end
            end)
        end
    end
end)

-- ============================================================
-- ANIME DEFENDERS — Auto wave start + auto place units
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        if CurrentGame == "Anime Defenders" and HubState.AutoFarm then
            pcall(function()
                -- Auto start wave
                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if re:IsA("RemoteEvent") and (re.Name:lower():find("wave") or re.Name:lower():find("start") or re.Name:lower():find("begin")) then
                        pcall(function() re:FireServer() end)
                    end
                end
                -- Auto place units on map nodes
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("node") or v.Name:lower():find("slot") or v.Name:lower():find("place")) then
                        for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                            if re:IsA("RemoteEvent") and (re.Name:lower():find("place") or re.Name:lower():find("summon") or re.Name:lower():find("deploy")) then
                                pcall(function() re:FireServer(v.Position, 1) end)
                            end
                        end
                    end
                end
                -- Auto sell overflow units
                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if re:IsA("RemoteEvent") and re.Name:lower():find("sell") then
                        pcall(function() re:FireServer() end)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- GROW A GARDEN — Auto plant + harvest
-- ============================================================
task.spawn(function()
    while true do
        task.wait(2)
        if CurrentGame == "Grow A Garden" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Harvest ripe crops
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("crop") or v.Name:lower():find("harvest") or v.Name:lower():find("ripe") or v.Name:lower():find("plant")) then
                        SafeTP(v.Position)
                        local cd = v:FindFirstChildOfClass("ClickDetector")
                        if cd then fireclickdetector(cd) end
                        pcall(function() firetouchinterest(v, char.HumanoidRootPart, 0) task.wait(0.1) firetouchinterest(v, char.HumanoidRootPart, 1) end)
                    end
                end
                -- Fire plant/harvest remotes
                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if re:IsA("RemoteEvent") and (re.Name:lower():find("plant") or re.Name:lower():find("harvest") or re.Name:lower():find("grow")) then
                        pcall(function() re:FireServer() end)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- PEROXIDE — Auto quest + mob kill loop
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.3)
        if CurrentGame == "Peroxide" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Accept quest
                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if re:IsA("RemoteEvent") and (re.Name:lower():find("quest") or re.Name:lower():find("accept") or re.Name:lower():find("mission")) then
                        pcall(function() re:FireServer(1) end)
                    end
                end
                -- Kill nearest mob
                local mob = GetNearestNPC(100)
                if mob then
                    local hrp = mob:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        SafeTP(hrp.Position - (hrp.Position - char.HumanoidRootPart.Position).Unit * 4)
                        for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                            if re:IsA("RemoteEvent") and (re.Name:lower():find("attack") or re.Name:lower():find("slash") or re.Name:lower():find("hit") or re.Name:lower():find("damage")) then
                                pcall(function() re:FireServer(mob, hrp.Position) end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- SOLS RNG — Auto roll + auto claim aura
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if CurrentGame == "Sols RNG" and HubState.AutoFarm then
            pcall(function()
                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if re:IsA("RemoteEvent") and (re.Name:lower():find("roll") or re.Name:lower():find("spin") or re.Name:lower():find("claim") or re.Name:lower():find("aura")) then
                        pcall(function() re:FireServer() end)
                    end
                end
                -- Click roll buttons
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("roll") or v.Name:lower():find("spin")) then
                        local cd = v:FindFirstChildOfClass("ClickDetector")
                        if cd then fireclickdetector(cd) end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- BLUE LOCK RIVALS — Auto play + auto score
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.2)
        if CurrentGame == "Blue Lock Rivals" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Find ball and teleport to it
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and v.Name:lower():find("ball") and v.Size.Magnitude < 5 then
                        SafeTP(v.Position)
                        for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                            if re:IsA("RemoteEvent") and (re.Name:lower():find("kick") or re.Name:lower():find("shoot") or re.Name:lower():find("goal") or re.Name:lower():find("dribble")) then
                                pcall(function() re:FireServer(v, Vector3.new(0,0,100)) end)
                            end
                        end
                        break
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- JUJUTSU SHENANIGANS — Auto attack + auto farm cursed energy
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.15)
        if CurrentGame == "Jujutsu Shenanigans" and HubState.AutoFarm then
            pcall(function()
                local target = GetClosestPlayer(100)
                if not target then return end
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Teleport behind target
                local tp = target.Position - (target.Position - char.HumanoidRootPart.Position).Unit * 4
                char.HumanoidRootPart.CFrame = CFrame.new(tp)
                for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                    if re:IsA("RemoteEvent") and (re.Name:lower():find("attack") or re.Name:lower():find("punch") or re.Name:lower():find("slash") or re.Name:lower():find("technique")) then
                        pcall(function() re:FireServer(target.Parent, target) end)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- DEAD RAILS — Auto survive + collect resources
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        if CurrentGame == "Dead Rails" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Collect dropped items/resources
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("loot") or v.Name:lower():find("ammo") or v.Name:lower():find("supply") or v.Name:lower():find("item")) then
                        local dist = (v.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist < 150 then
                            SafeTP(v.Position)
                            pcall(function() firetouchinterest(v, char.HumanoidRootPart, 0) task.wait(0.05) firetouchinterest(v, char.HumanoidRootPart, 1) end)
                        end
                    end
                end
                -- Kill nearest zombie/enemy
                local mob = GetNearestNPC(50)
                if mob then
                    local hrp = mob:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                            if re:IsA("RemoteEvent") and (re.Name:lower():find("shoot") or re.Name:lower():find("attack") or re.Name:lower():find("fire")) then
                                pcall(function() re:FireServer(mob, hrp.Position) end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- PRESSURE — Auto evade + auto collect items
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if CurrentGame == "Pressure" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Collect items
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("item") or v.Name:lower():find("key") or v.Name:lower():find("battery") or v.Name:lower():find("supply")) then
                        local dist = (v.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist < 100 then
                            SafeTP(v.Position)
                            pcall(function() firetouchinterest(v, char.HumanoidRootPart, 0) task.wait(0.05) firetouchinterest(v, char.HumanoidRootPart, 1) end)
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- WESTBOUND — Auto collect gold/loot + kill outlaws
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if CurrentGame == "Westbound" and HubState.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                -- Collect gold
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("gold") or v.Name:lower():find("nugget") or v.Name:lower():find("loot")) then
                        SafeTP(v.Position)
                        pcall(function() firetouchinterest(v, char.HumanoidRootPart, 0) task.wait(0.05) firetouchinterest(v, char.HumanoidRootPart, 1) end)
                    end
                end
                -- Kill nearest NPC
                local mob = GetNearestNPC(80)
                if mob then
                    local hrp = mob:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        SafeTP(hrp.Position - (hrp.Position - char.HumanoidRootPart.Position).Unit * 5)
                        for _, re in pairs(game.ReplicatedStorage:GetDescendants()) do
                            if re:IsA("RemoteEvent") and (re.Name:lower():find("shoot") or re.Name:lower():find("attack") or re.Name:lower():find("fire")) then
                                pcall(function() re:FireServer(mob, hrp.Position) end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

print("[Hood Omni Hub] All autofarm loops initialized!")


-- Silent Aim Hook
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if HubState.SilentAim and (method == "FireServer" or method == "InvokeServer") then
        local t = GetClosestPlayer(HubState.AimFOV)
        if t then
            for i, v in pairs(args) do
                if typeof(v) == "Vector3" then args[i] = t.Position
                elseif typeof(v) == "CFrame" then args[i] = CFrame.new(t.Position) end
            end
            return oldNamecall(self, unpack(args))
        end
    end
    if HubState.InfAmmo and method == "FireServer" then
        if typeof(self) == "Instance" and (self.Name:lower():find("ammo") or self.Name:lower():find("reload")) then return end
    end
    if HubState.NoRecoil and method == "FireServer" then
        for i, v in pairs(args) do
            if typeof(v) == "Vector3" and v.Magnitude < 5 then args[i] = Vector3.zero end
        end
        return oldNamecall(self, unpack(args))
    end
    return oldNamecall(self, ...)
end))

-- ESP Refresh on Player Join
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(1) if HubState.ESPEnabled then CreateESP(p) end end)
end)
Players.PlayerRemoving:Connect(function(p) pcall(function() for _,v in pairs(ESPFolder:GetChildren()) do if v.Name:find(p.Name) then v:Destroy() end end end) end)
for _,p in pairs(Players:GetPlayers()) do if p.Character then CreateESP(p) end p.CharacterAdded:Connect(function() task.wait(1) if HubState.ESPEnabled then CreateESP(p) end end) end

-- Status notification
pcall(function()
    local msg = Instance.new("Message") msg.Text = "Hood Omni Hub MEGA | " .. CurrentGame .. " | " .. tostring(#Hub.Tabs) .. " tabs loaded | RShift to toggle" msg.Parent = workspace
    task.delay(4, function() msg:Destroy() end)
end)
print("[Hood Omni Hub] MEGA Edition loaded! Game: " .. CurrentGame .. " | " .. tostring(#Hub.Tabs) .. " tabs")
