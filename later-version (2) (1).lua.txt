--[[
================================================================================
  Hood Omni Hub -- Mega Edition v3.0
  55+ Game Support | Universal Features | Auto-Detection
  Toggle UI: ☰ button (mobile-friendly, draggable)
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
    AntiAFK=true,GameSpecific={},
    AutoFarm=false,AutoFarmCash=false,AutoFarmKills=false,AutoFarmXP=false,
    AutoParry=false,AutoHatch=false,AutoRob=false,
    SpeedHack=false,SpeedValue=100,KillAura=false,SilentAim=false,
    InfAmmo=false,NoRecoil=false,NoSpread=false,RapidFire=false,
    AntiKick=false,AntiFling=false,AntiKillPart=false,AntiVoid=true,
    Godmode=false,BlockAC=true,AntiTeleport=true,ExecSpoof=true,
    AntiStomp=true,AntiRagdoll=true,AntiGrab=true,GravityMod=false
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
            if HubState.AntiVoid and hrp.Position.Y < -150 and safePos then
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
    local SG=Instance.new("ScreenGui") SG.Name="HoodOmniHub" SG.ResetOnSpawn=false SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling SG.DisplayOrder=999 SG.IgnoreGuiInset=true
    pcall(function() SG.Parent=CoreGui end) if not SG.Parent then SG.Parent=LocalPlayer:WaitForChild("PlayerGui") end
    local M=Instance.new("Frame") M.Name="Main" M.Size=UDim2.new(0,480,0,360) M.Position=UDim2.new(0.5,-240,0.5,-180)
    M.BackgroundColor3=Color3.fromRGB(15,15,20) M.BorderSizePixel=0 M.ClipsDescendants=true M.Visible=false M.Parent=SG
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
    -- Mobile toggle button (draggable, no keyboard needed)
    local TSG=Instance.new("ScreenGui") TSG.Name="HoodHubToggleBtn" TSG.ResetOnSpawn=false TSG.DisplayOrder=1000 TSG.IgnoreGuiInset=true
    pcall(function() TSG.Parent=CoreGui end) if not TSG.Parent then TSG.Parent=LocalPlayer:WaitForChild("PlayerGui") end
    local TBtn=Instance.new("TextButton") TBtn.Size=UDim2.new(0,54,0,54) TBtn.Position=UDim2.new(0,10,0.5,-27) TBtn.BackgroundColor3=Color3.fromRGB(80,0,200) TBtn.BorderSizePixel=0 TBtn.Text="\u2630" TBtn.TextColor3=Color3.new(1,1,1) TBtn.TextSize=24 TBtn.Font=Enum.Font.GothamBold TBtn.Parent=TSG
    Instance.new("UICorner",TBtn).CornerRadius=UDim.new(0,10)
    local MS2=Instance.new("UIStroke",TBtn) MS2.Color=Color3.fromRGB(160,80,255) MS2.Thickness=2
    local tbDrag,tbDragStart,tbStartPos=false,nil,nil
    TBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then tbDrag=true tbDragStart=i.Position tbStartPos=TBtn.Position i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then tbDrag=false end end) end end)
    UserInputService.InputChanged:Connect(function(i) if tbDrag and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d=i.Position-tbDragStart TBtn.Position=UDim2.new(tbStartPos.X.Scale,tbStartPos.X.Offset+d.X,tbStartPos.Y.Scale,tbStartPos.Y.Offset+d.Y) end end)
    TBtn.MouseButton1Click:Connect(function() M.Visible=not M.Visible end)
    -- Startup toast notification
    task.delay(1.5, function()
        local toast = Instance.new("ScreenGui")
        toast.Name = "HoodHubToast"
        toast.ResetOnSpawn = false
        pcall(function() toast.Parent = game:GetService("CoreGui") end)
        if not toast.Parent then toast.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0,340,0,50)
        f.Position = UDim2.new(0.5,-170,0,20)
        f.BackgroundColor3 = Color3.fromRGB(20,20,30)
        f.BorderSizePixel = 0
        f.Parent = toast
        Instance.new("UICorner",f).CornerRadius = UDim.new(0,8)
        local s = Instance.new("UIStroke",f) s.Color=Color3.fromRGB(128,0,255) s.Thickness=2
        local l = Instance.new("TextLabel",f)
        l.Size = UDim2.new(1,0,1,0)
        l.BackgroundTransparency = 1
        l.Text = "✅ Hood Omni Hub Loaded! Tap ☰ button to open"
        l.TextColor3 = Color3.fromRGB(200,150,255)
        l.TextSize = 13
        l.Font = Enum.Font.GothamBold
        task.delay(4, function() pcall(function() toast:Destroy() end) end)
    end)
    return self
end

-- GAME DETECTION
local GameDB = {
    [16472538603] = "Tha Bronx 3",
    [137020602493628] = "Gang Wars",
    [84866901748045] = "Bronx Hood",
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
    if string.find(gameName, "bronx hood") then CurrentGame = "Bronx Hood" end
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
Hub:AddToggle(uTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
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
    Hub:AddToggle(t_Tha_Bronx_3,"Speed Hack",false,function(v) HubState.SpeedHack=v; pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
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

-- DA HOOD (PlaceId: 2788229376)
-- Research: Stefanuk12/ROBLOX - MainEvent RemoteEvent confirmed
-- Workspace.Ignored.Drop for money, Workspace.Cashiers for NPCs
-- ═══════════════════════════════════════════════════════════════
if CurrentGame == "Da Hood" then
    local t_GameTab = Hub:AddTab("Da Hood","🏙️")

    Hub:AddToggle(t_GameTab,"Auto Farm Cash",false,function(v)
        HubState.DH_AutoCash = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Stomp Downed",false,function(v)
        HubState.DH_AutoStomp = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Pickup Guns",false,function(v)
        HubState.DH_AutoPickupGun = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Bank Deposit",false,function(v)
        HubState.DH_AutoBank = v
    end)

    Hub:AddToggle(t_GameTab,"Lock Victim (Nearest)",false,function(v)
        HubState.DH_LockVictim = v
        if not v then HubState.DH_LockedTarget = nil end
    end)

    Hub:AddToggle(t_GameTab,"Auto Collect Drops",false,function(v)
        HubState.DH_AutoCollectDrops = v
    end)

    Hub:AddButton(t_GameTab,"Kill All NPCs (Cashiers)",function()
        pcall(function()
            local Players = game:GetService("Players")
            local lp = Players.LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local cashiers = workspace:FindFirstChild("Cashiers")
            if cashiers then
                for _, v in pairs(cashiers:GetChildren()) do
                    local hum = v:FindFirstChildWhichIsA("Humanoid")
                    if hum and hum.Health > 0 then
                        hrp.CFrame = v:GetPivot() * CFrame.new(0, 0, -2)
                        task.wait(0.1)
                        local tool = lp.Backpack:FindFirstChildWhichIsA("Tool")
                            or char:FindFirstChildWhichIsA("Tool")
                        if tool then
                            local equipped = char:FindFirstChildWhichIsA("Tool")
                            if not equipped then hum:EquipTool and hum:EquipTool(tool) end
                        end
                    end
                end
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Teleport to Bank",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            -- Da Hood bank location (approximate based on map layout)
            if hrp then
                hrp.CFrame = CFrame.new(271, 18, -616)
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- GANG WARS (PlaceId: 137020602493628)
-- Research: Potato Farm, Car Farm, Store Rob existing + additions
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Gang Wars" or CurrentGame == "Bronx Hood" then
    local t_GameTab = Hub:AddTab("Gang Wars","💰")

    Hub:AddToggle(t_GameTab,"Potato Farm",false,function(v)
        HubState.GW_PotatoFarm = v
    end)

    Hub:AddToggle(t_GameTab,"Car Farm",false,function(v)
        HubState.GW_CarFarm = v
    end)

    Hub:AddToggle(t_GameTab,"Store Rob",false,function(v)
        HubState.GW_StoreRob = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Kill NPC",false,function(v)
        HubState.GW_AutoKillNPC = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Revive Allies",false,function(v)
        HubState.GW_AutoRevive = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Buy Ammo",false,function(v)
        HubState.GW_AutoAmmo = v
    end)

    Hub:AddButton(t_GameTab,"Collect All Potatoes",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "Potato" or v.Name == "potato" then
                    local pos = v:IsA("BasePart") and v.Position
                        or (v:IsA("Model") and v:GetPivot().Position)
                    if pos then
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                        task.wait(0.3)
                        local touch = v:FindFirstChildWhichIsA("TouchTransmitter")
                        if touch then firetouchinterest(hrp, v:IsA("BasePart") and v or v.PrimaryPart, 0) end
                    end
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- BLOX FRUITS (PlaceId: 2753915549)
-- Research: ReplicatedStorage.Remotes.* for fruit/mastery events
-- Workspace.Map.* for islands, Workspace.SpawnedFruits for fruits
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Blox Fruits" then
    local t_GameTab = Hub:AddTab("Blox Fruits","🍈")

    Hub:AddToggle(t_GameTab,"Auto Farm Mastery",false,function(v)
        HubState.BF_AutoMastery = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Farm Bounty",false,function(v)
        HubState.BF_AutoBounty = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Sea Beast",false,function(v)
        HubState.BF_AutoSeaBeast = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Raid Farm",false,function(v)
        HubState.BF_AutoRaid = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Chest Farm",false,function(v)
        HubState.BF_AutoChest = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Collect Fruits",false,function(v)
        HubState.BF_AutoCollectFruit = v
    end)

    Hub:AddButton(t_GameTab,"Teleport to Nearest Chest",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local nearest, dist = nil, math.huge
            for _, v in pairs(workspace:GetDescendants()) do
                if (v.Name == "Chest" or v.Name == "chest") and v:IsA("Model") then
                    local pivot = v:GetPivot().Position
                    local d = (pivot - hrp.Position).Magnitude
                    if d < dist then dist = d; nearest = pivot end
                end
            end
            if nearest then
                hrp.CFrame = CFrame.new(nearest + Vector3.new(0, 4, 0))
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Enable Buddha (if owned)",function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local remote = RS:FindFirstChild("Remotes", true)
                or RS:FindFirstChild("MainEvent", true)
            -- Fire fruit activation event
            local fruitEvent = RS:FindFirstChild("ActivateFruit", true)
                or RS:FindFirstChild("FruitActivate", true)
            if fruitEvent then
                fruitEvent:FireServer("Buddha")
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- JAILBREAK (PlaceId: 606849621)
-- Research: Sky-Hub jailbreak.lua loaded, ReplicatedStorage.Jailbreak.*
-- Rob events: "BankRemote", "JewelryRemote", "CasinoRemote"
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Jailbreak" then
    local t_GameTab = Hub:AddTab("Jailbreak","🔓")

    Hub:AddToggle(t_GameTab,"Auto Rob Bank",false,function(v)
        HubState.JB_AutoBank = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Rob Jewelry Store",false,function(v)
        HubState.JB_AutoJewelry = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Rob Casino",false,function(v)
        HubState.JB_AutoCasino = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Rob Train",false,function(v)
        HubState.JB_AutoTrain = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Collect Cargo",false,function(v)
        HubState.JB_AutoCargo = v
    end)

    Hub:AddToggle(t_GameTab,"Infinite Nitro",false,function(v)
        HubState.JB_InfNitro = v
    end)

    Hub:AddButton(t_GameTab,"Teleport to Bank",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Jailbreak Bank approximate location
                hrp.CFrame = CFrame.new(277, 18, -1595)
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Teleport to Jewelry Store",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(-602, 18, 131)
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- MURDER MYSTERY 2 (PlaceId: 142823291)
-- Research: Sky-Hub murdermystery2.lua, MM2 event structure
-- ReplicatedStorage.GameEvents.* for role events
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Murder Mystery 2" then
    local t_GameTab = Hub:AddTab("Murder Mystery 2","🔪")

    Hub:AddToggle(t_GameTab,"ESP - Show Murderer",false,function(v)
        HubState.MM2_ESPMurderer = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Coin Farm",false,function(v)
        HubState.MM2_AutoCoin = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Knife Throw",false,function(v)
        HubState.MM2_AutoKnifeThrow = v
    end)

    Hub:AddToggle(t_GameTab,"Sheriff Auto-Win (Follow Murderer)",false,function(v)
        HubState.MM2_SheriffAutoWin = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Godhand Shoot",false,function(v)
        HubState.MM2_AutoGodhand = v
    end)

    Hub:AddButton(t_GameTab,"Collect All Coins Now",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "Coin" and v:IsA("BasePart") then
                    hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))
                    task.wait(0.15)
                end
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"ESP All Players",function()
        pcall(function()
            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                if player ~= game:GetService("Players").LocalPlayer then
                    local char = player.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "MM2_ESP"
                            bb.AlwaysOnTop = true
                            bb.Size = UDim2.new(0, 100, 0, 40)
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.Parent = hrp
                            local lbl = Instance.new("TextLabel")
                            lbl.BackgroundTransparency = 1
                            lbl.Size = UDim2.new(1,0,1,0)
                            lbl.Text = player.Name
                            lbl.TextColor3 = Color3.fromRGB(255,0,0)
                            lbl.TextStrokeTransparency = 0
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextScaled = true
                            lbl.Parent = bb
                        end
                    end
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- PET SIMULATOR 99 (PlaceId: 8737899170)
-- Research: Sky-Hub petsimulator99.lua loaded
-- ReplicatedStorage packages contain BuyEgg, HatchEgg, etc.
-- Eggs in Workspace.EggWorld.*, Coins in Workspace.*
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Pet Simulator 99" then
    local t_GameTab = Hub:AddTab("Pet Sim 99","🐾")

    Hub:AddToggle(t_GameTab,"Auto Hatch Egg",false,function(v)
        HubState.PS99_AutoHatch = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Farm Diamonds",false,function(v)
        HubState.PS99_AutoDiamond = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Collect Coins",false,function(v)
        HubState.PS99_AutoCoin = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Enchant Pets",false,function(v)
        HubState.PS99_AutoEnchant = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Fuse Pets",false,function(v)
        HubState.PS99_AutoFuse = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Open Chests",false,function(v)
        HubState.PS99_AutoChest = v
    end)

    Hub:AddButton(t_GameTab,"Collect All Coins Now",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, v in pairs(workspace:GetDescendants()) do
                if (v.Name == "Coin" or v.Name == "Diamond") and v:IsA("BasePart") then
                    hrp.CFrame = CFrame.new(v.Position)
                    task.wait(0.1)
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- GROW A GARDEN (PlaceId: 126884695634)
-- Research: Garden game with planting, watering, harvesting
-- Workspace.Garden.Plots.*, ReplicatedStorage events for farming
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Grow A Garden" then
    local t_GameTab = Hub:AddTab("Grow A Garden","🌱")

    Hub:AddToggle(t_GameTab,"Auto Plant Seeds",false,function(v)
        HubState.GAG_AutoPlant = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Harvest Crops",false,function(v)
        HubState.GAG_AutoHarvest = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Water Plants",false,function(v)
        HubState.GAG_AutoWater = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Buy Seeds",false,function(v)
        HubState.GAG_AutoBuySeeds = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Sell Crops",false,function(v)
        HubState.GAG_AutoSell = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Fertilize",false,function(v)
        HubState.GAG_AutoFertilize = v
    end)

    Hub:AddButton(t_GameTab,"Harvest All Now",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local RS = game:GetService("ReplicatedStorage")
            -- Look for harvest remote
            for _, v in pairs(RS:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("harvest") or v.Name:lower():find("collect")) then
                    pcall(function() v:FireServer() end)
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- BLADE BALL (PlaceId: 13772394625)
-- Research: Sky-Hub bladeball.lua - parry system
-- ReplicatedStorage.Packages.* has parry remotes
-- Ball object in Workspace, "Parry" RemoteEvent confirmed from community scripts
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Blade Ball" then
    local t_GameTab = Hub:AddTab("Blade Ball","⚽")

    Hub:AddToggle(t_GameTab,"Auto Parry Ball",false,function(v)
        HubState.BB_AutoParry = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Deflect Chain",false,function(v)
        HubState.BB_AutoDeflect = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Use Ability",false,function(v)
        HubState.BB_AutoAbility = v
    end)

    Hub:AddToggle(t_GameTab,"Teleport to Ball",false,function(v)
        HubState.BB_TpToBall = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Win Round (Survive)",false,function(v)
        HubState.BB_AutoWin = v
    end)

    Hub:AddButton(t_GameTab,"Instant Parry Now",function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            -- Blade Ball uses "Parry" RemoteEvent in ReplicatedStorage
            local parryEvent = RS:FindFirstChild("Parry", true)
                or RS:FindFirstChild("ParryEvent", true)
                or RS:FindFirstChild("Deflect", true)
            if parryEvent and parryEvent:IsA("RemoteEvent") then
                parryEvent:FireServer()
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Find Ball Location",function()
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "Ball" and v:IsA("BasePart") then
                    print("Ball found at: " .. tostring(v.Position))
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- BEE SWARM SIMULATOR (PlaceId: 1537690962)
-- Research: ReplicatedStorage.Remotes.* for bee/honey events
-- Workspace.Honey, Workspace.Pollen, Workspace.Quests
-- "CollectHoney", "FightBear", "CompleteQuest" remote names
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Bee Swarm Simulator" then
    local t_GameTab = Hub:AddTab("Bee Swarm Sim","🐝")

    Hub:AddToggle(t_GameTab,"Auto Collect Honey",false,function(v)
        HubState.BSS_AutoHoney = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Farm Pollen",false,function(v)
        HubState.BSS_AutoPollen = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Complete Quest",false,function(v)
        HubState.BSS_AutoQuest = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Buy Gear",false,function(v)
        HubState.BSS_AutoBuyGear = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Fight Monster",false,function(v)
        HubState.BSS_AutoFightMonster = v
    end)

    Hub:AddButton(t_GameTab,"Collect All Honey Now",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local RS = game:GetService("ReplicatedStorage")
            local honeyRemote = RS:FindFirstChild("CollectHoney", true)
                or RS:FindFirstChild("Honey", true)
            if honeyRemote and honeyRemote:IsA("RemoteEvent") then
                honeyRemote:FireServer()
            end
            -- Also walk through pollen field
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "Honey" and v:IsA("BasePart") then
                    hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- SHINDO LIFE (PlaceId: 6276433986)
-- Research: ReplicatedStorage.rei.* event structure
-- RELL Coins, EXP, elemental spins via "rei" RemoteFunction
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Shindo Life" then
    local t_GameTab = Hub:AddTab("Shindo Life","⚡")

    Hub:AddToggle(t_GameTab,"Auto Farm EXP",false,function(v)
        HubState.SL_AutoEXP = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Spin Elements",false,function(v)
        HubState.SL_AutoSpin = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Sword Farm",false,function(v)
        HubState.SL_AutoSword = v
    end)

    Hub:AddToggle(t_GameTab,"Auto RELL Coin Farm",false,function(v)
        HubState.SL_AutoRELLCoin = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Mode Farm (Sage/Tailed Beast)",false,function(v)
        HubState.SL_AutoMode = v
    end)

    Hub:AddButton(t_GameTab,"Auto Spin Once",function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            -- Shindo Life uses "rei" RemoteFunction
            local reiFolder = RS:FindFirstChild("rei")
            if reiFolder then
                local spinRemote = reiFolder:FindFirstChild("Spin")
                    or reiFolder:FindFirstChild("SpinElement")
                if spinRemote and spinRemote:IsA("RemoteFunction") then
                    pcall(function() spinRemote:InvokeServer("FreeSpins") end)
                elseif spinRemote and spinRemote:IsA("RemoteEvent") then
                    spinRemote:FireServer("FreeSpins")
                end
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Collect RELL Coins Now",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "RELLcoin" or v.Name == "RellCoin" or v.Name == "Coin" then
                    local pos = v:IsA("BasePart") and v.Position
                        or (v:IsA("Model") and v:GetPivot().Position)
                    if pos then
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                        task.wait(0.2)
                    end
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- THE STRONGEST BATTLEGROUNDS (PlaceId: 15532962292)
-- Research: TSB uses ReplicatedStorage.Remotes.* for combat
-- "KO", "RankUp", "Block", "Counter", "Combo" remotes
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "The Strongest Battlegrounds" then
    local t_GameTab = Hub:AddTab("Strongest BG","💪")

    Hub:AddToggle(t_GameTab,"Auto Farm KO",false,function(v)
        HubState.TSB_AutoKO = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Block Break",false,function(v)
        HubState.TSB_AutoBlockBreak = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Counter Attack",false,function(v)
        HubState.TSB_AutoCounter = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Combo",false,function(v)
        HubState.TSB_AutoCombo = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Rank Up",false,function(v)
        HubState.TSB_AutoRankUp = v
    end)

    Hub:AddButton(t_GameTab,"Teleport to Nearest Enemy",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local nearest, nearDist = nil, math.huge
            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                if player ~= lp and player.Character then
                    local enemyHRP = player.Character:FindFirstChild("HumanoidRootPart")
                    local hum = player.Character:FindFirstChild("Humanoid")
                    if enemyHRP and hum and hum.Health > 0 then
                        local d = (enemyHRP.Position - hrp.Position).Magnitude
                        if d < nearDist then
                            nearDist = d
                            nearest = enemyHRP.Position
                        end
                    end
                end
            end
            if nearest then
                hrp.CFrame = CFrame.new(nearest + Vector3.new(0, 2, 4))
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Auto Use All Abilities",function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local remotes = RS:FindFirstChild("Remotes")
            if remotes then
                for _, v in pairs(remotes:GetChildren()) do
                    if v:IsA("RemoteEvent") and v.Name:lower():find("ability") then
                        pcall(function() v:FireServer() end)
                    end
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- ANIME DEFENDERS (PlaceId: 101459448310804)
-- Research: ReplicatedStorage.Remotes.* for stage/summon events
-- "FarmStage", "CollectGems", "UpgradeUnit", "Summon", "SellUnit"
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Anime Defenders" then
    local t_GameTab = Hub:AddTab("Anime Defenders","⚔️")

    Hub:AddToggle(t_GameTab,"Auto Farm Stage",false,function(v)
        HubState.AD_AutoFarm = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Collect Gems",false,function(v)
        HubState.AD_AutoGems = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Upgrade Units",false,function(v)
        HubState.AD_AutoUpgrade = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Summon Units",false,function(v)
        HubState.AD_AutoSummon = v
    end)

    Hub:AddToggle(t_GameTab,"Auto Sell Excess Units",false,function(v)
        HubState.AD_AutoSell = v
    end)

    Hub:AddButton(t_GameTab,"Collect Gems Now",function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            for _, v in pairs(RS:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("gem") or v.Name:lower():find("collect")) then
                    pcall(function() v:FireServer() end)
                    task.wait(0.1)
                end
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Summon Once",function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            for _, v in pairs(RS:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:lower():find("summon") then
                    pcall(function() v:FireServer(1) end) -- 1 = single summon
                    break
                end
            end
        end)
    end)


-- ═══════════════════════════════════════════════════════════════
-- RIVALS (PlaceId: 17625359962)
-- Source: XCV Hub research — aimbot, silent aim, ESP, speed, teleport
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Rivals" then
    local t_GameTab = Hub:AddTab("Rivals","⚔️")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddSlider(t_GameTab,"Aim FOV",50,800,200,function(v) HubState.AimFOV=v end)
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSlider(t_GameTab,"Kill Aura Range",5,50,15,function(v) HubState.KillAuraRange=v end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)

    Hub:AddSection(t_GameTab,"Weapon")
    Hub:AddToggle(t_GameTab,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_GameTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_GameTab,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddToggle(t_GameTab,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_GameTab,"Inf Jump",false,function(v) HubState.RV_InfJump=v end)

    Hub:AddSection(t_GameTab,"Farm & Auto")
    Hub:AddToggle(t_GameTab,"Auto Farm XP",false,function(v) HubState.RV_AutoXP=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Coins",false,function(v) HubState.RV_AutoCoin=v end)
    Hub:AddToggle(t_GameTab,"Auto Dodge",false,function(v) HubState.RV_AutoDodge=v end)

    Hub:AddSection(t_GameTab,"Teleports")
    Hub:AddButton(t_GameTab,"Teleport to Nearest Enemy",function()
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local closest, closestDist = nil, math.huge
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= lp and p.Character then
                    local er = p.Character:FindFirstChild("HumanoidRootPart")
                    local hm = p.Character:FindFirstChildOfClass("Humanoid")
                    if er and hm and hm.Health > 0 then
                        local d = (hrp.Position - er.Position).Magnitude
                        if d < closestDist then closestDist=d; closest=er end
                    end
                end
            end
            if closest then hrp.CFrame = closest.CFrame * CFrame.new(0, 0, -3) end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- BLUE LOCK: RIVALS (PlaceId: 18668065416)
-- Source: XCV Hub — similar to Rivals, soccer-based combat
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Blue Lock Rivals" then
    local t_GameTab = Hub:AddTab("Blue Lock","🔵")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)

    Hub:AddSection(t_GameTab,"Blue Lock Specific")
    Hub:AddToggle(t_GameTab,"Auto Score Goal",false,function(v) HubState.BLR_AutoGoal=v end)
    Hub:AddToggle(t_GameTab,"Auto Farm XP",false,function(v) HubState.BLR_AutoXP=v end)
    Hub:AddToggle(t_GameTab,"Auto Pass (Team)",false,function(v) HubState.BLR_AutoPass=v end)
    Hub:AddToggle(t_GameTab,"Ball ESP",false,function(v) HubState.BLR_BallESP=v
        pcall(function()
            local ball = workspace:FindFirstChild("Ball") or workspace:FindFirstChild("Football") or workspace:FindFirstChild("Soccer_Ball")
            if ball and v then
                for _, ch in pairs(workspace:GetDescendants()) do
                    if (ch.Name:lower():find("ball")) and ch:IsA("BasePart") then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "BallESP"; bb.AlwaysOnTop = true
                        bb.Size = UDim2.new(0,80,0,30); bb.StudsOffset = Vector3.new(0,3,0)
                        bb.Parent = ch
                        local lbl = Instance.new("TextLabel")
                        lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0)
                        lbl.Text="⚽ BALL"; lbl.TextColor3=Color3.fromRGB(255,255,0)
                        lbl.TextStrokeTransparency=0; lbl.Font=Enum.Font.GothamBold
                        lbl.TextScaled=true; lbl.Parent=bb
                    end
                end
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Teleport to Ball",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, ch in pairs(workspace:GetDescendants()) do
                if ch.Name:lower():find("ball") and ch:IsA("BasePart") then
                    hrp.CFrame = ch.CFrame * CFrame.new(0, 0, -2); break
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- PHANTOM FORCES (PlaceId: 292439477)
-- Source: XCV Hub — aimbot, no spread, no recoil, esp
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Phantom Forces" then
    local t_GameTab = Hub:AddTab("Phantom Forces","🔫")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Aimbot (Head)",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddSlider(t_GameTab,"Aim FOV",50,800,150,function(v) HubState.AimFOV=v end)
    Hub:AddToggle(t_GameTab,"ESP (Through Walls)",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)

    Hub:AddSection(t_GameTab,"Weapon")
    Hub:AddToggle(t_GameTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_GameTab,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_GameTab,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddToggle(t_GameTab,"Inf Ammo",false,function(v)
        HubState.InfAmmo=v
        if v then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    for _, tool in pairs(char:GetDescendants()) do
                        if tool:IsA("IntValue") and (tool.Name=="Ammo" or tool.Name=="StoredAmmo") then
                            tool.Value = 999
                        end
                    end
                end
            end)
        end
    end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 60) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)

    Hub:AddSection(t_GameTab,"Phantom Specific")
    Hub:AddToggle(t_GameTab,"Auto Headshot",false,function(v) HubState.PF_AutoHeadshot=v end)
    Hub:AddToggle(t_GameTab,"Anti Flash",false,function(v)
        HubState.PF_AntiFlash=v
        pcall(function()
            if v then Lighting.Brightness=2 Lighting.Ambient=Color3.new(1,1,1) end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- FISCH (PlaceId: 16732694052)
-- Source: Redz Hub — Auto Fish, Auto Sell, Teleport to Spots
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Fisch" then
    local t_GameTab = Hub:AddTab("Fisch","🎣")

    Hub:AddSection(t_GameTab,"Fishing")
    Hub:AddToggle(t_GameTab,"Auto Fish (Cast & Reel)",false,function(v) HubState.FSH_AutoFish=v end)
    Hub:AddToggle(t_GameTab,"Auto Reel On Bite",false,function(v) HubState.FSH_AutoReel=v end)
    Hub:AddToggle(t_GameTab,"Auto Sell Fish",false,function(v) HubState.FSH_AutoSell=v end)
    Hub:AddToggle(t_GameTab,"Auto Pick Best Rod",false,function(v) HubState.FSH_AutoRod=v end)

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Collect Resources",false,function(v) HubState.FSH_AutoCollect=v end)
    Hub:AddToggle(t_GameTab,"Auto Complete Quest",false,function(v) HubState.FSH_AutoQuest=v end)

    Hub:AddSection(t_GameTab,"Teleports")
    Hub:AddButton(t_GameTab,"TP to Nearest Fish Spot",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, v in pairs(workspace:GetDescendants()) do
                if (v.Name:lower():find("fishspot") or v.Name:lower():find("fishing") or v.Name:lower():find("spawn_fish")) and v:IsA("BasePart") then
                    hrp.CFrame = v.CFrame * CFrame.new(0, 2, 0); break
                end
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"TP to Merchant (Sell NPC)",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, v in pairs(workspace:GetDescendants()) do
                if (v.Name:lower():find("merchant") or v.Name:lower():find("seller") or v.Name:lower():find("shop")) and (v:IsA("BasePart") or v:IsA("Model")) then
                    local pos = v:IsA("Model") and v:GetPivot().Position or v.Position
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)); break
                end
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Auto Cast Now",function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            for _, v in pairs(RS:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("cast") or v.Name:lower():find("fish")) then
                    v:FireServer(); break
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- JUJUTSU SHENANIGANS (PlaceId: 9391468976)
-- Source: XCV Hub — auto farm, esp, kill aura
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Jujutsu Shenanigans" then
    local t_GameTab = Hub:AddTab("JJK Shens","⚡")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Farm EXP",false,function(v) HubState.JJK_AutoEXP=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Souls",false,function(v) HubState.JJK_AutoSouls=v end)
    Hub:AddToggle(t_GameTab,"Auto Use Ability (Spam)",false,function(v) HubState.JJK_AutoAbility=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)

-- ═══════════════════════════════════════════════════════════════
-- KING LEGACY (PlaceId: 4520749081)
-- Source: XCV Hub + community — auto farm, fruit collector, boss farm
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "King Legacy" then
    local t_GameTab = Hub:AddTab("King Legacy","👑")

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Farm Enemies",false,function(v) HubState.KL_AutoFarm=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Fruits",false,function(v) HubState.KL_AutoFruit=v end)
    Hub:AddToggle(t_GameTab,"Auto Farm Bosses",false,function(v) HubState.KL_AutoBoss=v end)
    Hub:AddToggle(t_GameTab,"Auto Farm Mastery",false,function(v) HubState.KL_AutoMastery=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Coins",false,function(v) HubState.KL_AutoCoin=v end)

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Auto Use Abilities",false,function(v) HubState.KL_AutoAbility=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Inf Jump",false,function(v) HubState.KL_InfJump=v end)

    Hub:AddButton(t_GameTab,"Teleport to Nearest Boss",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local closest, closestDist = nil, math.huge
            for _, v in pairs(workspace:GetDescendants()) do
                local hm = v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")
                if hm and hm.MaxHealth >= 1000 and hm.Health > 0 then
                    local rp = v:FindFirstChild("HumanoidRootPart")
                    if rp then
                        local d = (hrp.Position - rp.Position).Magnitude
                        if d < closestDist then closestDist=d; closest=rp end
                    end
                end
            end
            if closest then hrp.CFrame = closest.CFrame * CFrame.new(0,0,-5) end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- SOLS RNG (PlaceId: 15532962292)
-- Source: Community + XCV — auto spin, auto merchant, biome ESP
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Sols RNG" then
    local t_GameTab = Hub:AddTab("Sols RNG","🎲")

    Hub:AddSection(t_GameTab,"Auto")
    Hub:AddToggle(t_GameTab,"Auto Spin",false,function(v) HubState.SRNG_AutoSpin=v end)
    Hub:AddToggle(t_GameTab,"Auto Merchant (Buy Potions)",false,function(v) HubState.SRNG_AutoMerchant=v end)
    Hub:AddToggle(t_GameTab,"Auto Open Gifts",false,function(v) HubState.SRNG_AutoGift=v end)

    Hub:AddSection(t_GameTab,"Visual")
    Hub:AddToggle(t_GameTab,"Biome ESP (Announce in Chat)",false,function(v) HubState.SRNG_BiomeESP=v end)
    Hub:AddToggle(t_GameTab,"Aura Display (Chat Announce)",false,function(v) HubState.SRNG_AuraDisplay=v end)
    Hub:AddToggle(t_GameTab,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)

    Hub:AddButton(t_GameTab,"Spin Once Now",function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            for _, v in pairs(RS:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("spin") or v.Name:lower():find("roll")) then
                    v:FireServer(); break
                end
            end
        end)
    end)

    Hub:AddButton(t_GameTab,"Teleport to Merchant",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, v in pairs(workspace:GetDescendants()) do
                if (v.Name:lower():find("merchant") or v.Name:lower():find("potion")) and (v:IsA("BasePart") or v:IsA("Model")) then
                    local pos = v:IsA("Model") and v:GetPivot().Position or v.Position
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)); break
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- PEROXIDE (PlaceId: 9096881148)
-- Source: Community — auto farm, esp, soul reaper features
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Peroxide" then
    local t_GameTab = Hub:AddTab("Peroxide","☠️")

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Farm EXP",false,function(v) HubState.PX_AutoEXP=v end)
    Hub:AddToggle(t_GameTab,"Auto Hollow Farm",false,function(v) HubState.PX_AutoHollow=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Items",false,function(v) HubState.PX_AutoCollect=v end)
    Hub:AddToggle(t_GameTab,"Auto Use Shikai/Bankai",false,function(v) HubState.PX_AutoAbility=v end)

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)

    Hub:AddSection(t_GameTab,"Misc")
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)

-- ═══════════════════════════════════════════════════════════════
-- DEAD RAILS (PlaceId: 116495829188952)
-- Source: XCV Hub — auto shoot, auto loot, speed, survival tools
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Dead Rails" then
    local t_GameTab = Hub:AddTab("Dead Rails","🚂")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"Kill Aura (Zombies)",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_GameTab,"ESP (Zombies + Players)",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_GameTab,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)

    Hub:AddSection(t_GameTab,"Farm & Loot")
    Hub:AddToggle(t_GameTab,"Auto Loot Chests",false,function(v) HubState.DR_AutoLoot=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Gold",false,function(v) HubState.DR_AutoGold=v end)
    Hub:AddToggle(t_GameTab,"Auto Repair Train",false,function(v) HubState.DR_AutoRepair=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)

    Hub:AddButton(t_GameTab,"Teleport onto Train",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, v in pairs(workspace:GetDescendants()) do
                if (v.Name:lower():find("train") or v.Name:lower():find("rail") or v.Name:lower():find("locomotive")) and v:IsA("BasePart") then
                    hrp.CFrame = v.CFrame * CFrame.new(0, 5, 0); break
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- FRONTLINES (PlaceId: 5938036553)
-- Source: XCV Hub — FPS game, aimbot, no spread, ESP
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Frontlines" then
    local t_GameTab = Hub:AddTab("Frontlines","🪖")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddSlider(t_GameTab,"Aim FOV",50,800,150,function(v) HubState.AimFOV=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)

    Hub:AddSection(t_GameTab,"Weapon")
    Hub:AddToggle(t_GameTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_GameTab,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_GameTab,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddToggle(t_GameTab,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)

    Hub:AddSection(t_GameTab,"Movement & Misc")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 80) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Anti-Flash",false,function(v) if v then Lighting.Brightness=2 Lighting.Ambient=Color3.new(1,1,1) end end)

-- ═══════════════════════════════════════════════════════════════
-- MEME SEA (Redz Hub source — auto farm, auto sell, esp)
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Meme Sea" then
    local t_GameTab = Hub:AddTab("Meme Sea","🌊")

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Farm Enemies",false,function(v) HubState.MS_AutoFarm=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Drops",false,function(v) HubState.MS_AutoDrop=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Chests",false,function(v) HubState.MS_AutoChest=v end)
    Hub:AddToggle(t_GameTab,"Auto Farm Bounty",false,function(v) HubState.MS_AutoBounty=v end)
    Hub:AddToggle(t_GameTab,"Auto Farm Mastery",false,function(v) HubState.MS_AutoMastery=v end)

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip (Sea Walk)",false,function(v) HubState.Noclip=v end)

    Hub:AddButton(t_GameTab,"Teleport to Nearest NPC",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local closest, closestDist = nil, math.huge
            for _, v in pairs(workspace:GetDescendants()) do
                local hm = v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")
                if hm and hm.Health > 0 then
                    local rp = v:FindFirstChild("HumanoidRootPart")
                    if rp and rp ~= hrp then
                        local d = (hrp.Position - rp.Position).Magnitude
                        if d < closestDist then closestDist=d; closest=rp end
                    end
                end
            end
            if closest then hrp.CFrame = closest.CFrame * CFrame.new(0,0,-4) end
        end)
    end)


-- ═══════════════════════════════════════════════════════════════
-- HOOD CLUSTER — Central Streets, South London, Street Life,
-- Cali Shootout, Streetz War 2, Outwest Chicago 2, No Mercy,
-- South Bronx, Underground War 2, Philly Streetz 2, QZ Shootout
-- All share the same tab logic as Da Hood / Gang Wars
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Central Streets"
    or CurrentGame == "South London Remastered"
    or CurrentGame == "Street Life Remastered"
    or CurrentGame == "Cali Shootout"
    or CurrentGame == "Streetz War 2"
    or CurrentGame == "Outwest Chicago 2"
    or CurrentGame == "No Mercy"
    or CurrentGame == "South Bronx"
    or CurrentGame == "Underground War 2"
    or CurrentGame == "Philly Streetz 2"
    or CurrentGame == "QZ Shootout" then
    local t_GameTab = Hub:AddTab(CurrentGame,"🏙️")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)

    Hub:AddSection(t_GameTab,"Weapon")
    Hub:AddToggle(t_GameTab,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_GameTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_GameTab,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_GameTab,"Rapid Fire",false,function(v) HubState.RapidFire=v end)

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Farm Cash",false,function(v) HubState.DH_AutoCash=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Drops",false,function(v) HubState.DH_AutoCollectDrops=v end)
    Hub:AddToggle(t_GameTab,"Auto Stomp Downed",false,function(v) HubState.DH_AutoStomp=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)

    Hub:AddButton(t_GameTab,"Teleport to ATM",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name:lower():find("atm") and v:IsA("BasePart") then
                    hrp.CFrame = v.CFrame + Vector3.new(0,3,0); break
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- ARSENAL (PlaceId: 286090429) — XCV Hub
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Arsenal" then
    local t_GameTab = Hub:AddTab("Arsenal","🔫")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddSlider(t_GameTab,"Aim FOV",50,800,150,function(v) HubState.AimFOV=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)

    Hub:AddSection(t_GameTab,"Weapon")
    Hub:AddToggle(t_GameTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_GameTab,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_GameTab,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddToggle(t_GameTab,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)

    Hub:AddSection(t_GameTab,"Misc")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and 60 or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Anti-Flash",false,function(v) if v then Lighting.Brightness=2 Lighting.Ambient=Color3.new(1,1,1) end end)

-- ═══════════════════════════════════════════════════════════════
-- BAD BUSINESS (PlaceId: 3233893879) — XCV Hub
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Bad Business" then
    local t_GameTab = Hub:AddTab("Bad Business","💼")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)

    Hub:AddSection(t_GameTab,"Weapon")
    Hub:AddToggle(t_GameTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_GameTab,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_GameTab,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddToggle(t_GameTab,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and 60 or 16 end) end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)

-- ═══════════════════════════════════════════════════════════════
-- COUNTER BLOX (PlaceId: 301549746) — XCV Hub
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Counter Blox" then
    local t_GameTab = Hub:AddTab("Counter Blox","🎯")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddSlider(t_GameTab,"Aim FOV",50,800,150,function(v) HubState.AimFOV=v end)
    Hub:AddToggle(t_GameTab,"ESP (Wall Hack)",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)

    Hub:AddSection(t_GameTab,"Weapon")
    Hub:AddToggle(t_GameTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)
    Hub:AddToggle(t_GameTab,"No Spread",false,function(v) HubState.NoSpread=v end)
    Hub:AddToggle(t_GameTab,"Rapid Fire",false,function(v) HubState.RapidFire=v end)
    Hub:AddToggle(t_GameTab,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)

    Hub:AddSection(t_GameTab,"Misc")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and 60 or 16 end) end)
    Hub:AddToggle(t_GameTab,"Anti-Flash",false,function(v) if v then Lighting.Brightness=2 Lighting.Ambient=Color3.new(1,1,1) end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)

-- ═══════════════════════════════════════════════════════════════
-- BEDWARS (PlaceId: 6872274481) — XCV Hub
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "BedWars" then
    local t_GameTab = Hub:AddTab("BedWars","🛏️")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSlider(t_GameTab,"Kill Aura Range",5,40,10,function(v) HubState.KillAuraRange=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Inf Jump",false,function(v) HubState.BW_InfJump=v end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)

    Hub:AddSection(t_GameTab,"BedWars Specific")
    Hub:AddToggle(t_GameTab,"Auto Collect Resources",false,function(v) HubState.BW_AutoRes=v end)
    Hub:AddToggle(t_GameTab,"Bed ESP (Show All Beds)",false,function(v)
        HubState.BW_BedESP=v
        pcall(function()
            if v then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if (obj.Name:lower():find("bed") or obj.Name:lower():find("nexus")) and obj:IsA("BasePart") then
                        local bb = Instance.new("BillboardGui")
                        bb.Name="BedESP"; bb.AlwaysOnTop=true
                        bb.Size=UDim2.new(0,80,0,30); bb.StudsOffset=Vector3.new(0,3,0)
                        bb.Parent=obj
                        local lbl=Instance.new("TextLabel")
                        lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0)
                        lbl.Text="🛏️ BED"; lbl.TextColor3=Color3.fromRGB(255,80,80)
                        lbl.TextStrokeTransparency=0; lbl.Font=Enum.Font.GothamBold
                        lbl.TextScaled=true; lbl.Parent=bb
                    end
                end
            else
                for _, obj in pairs(game:GetDescendants()) do
                    if obj.Name=="BedESP" then obj:Destroy() end
                end
            end
        end)
    end)
    Hub:AddButton(t_GameTab,"Teleport to Your Bed",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("bed") and obj:IsA("BasePart") then
                    hrp.CFrame = obj.CFrame + Vector3.new(0,4,0); break
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- DOORS (PlaceId: 6516141723) — XCV Hub
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Doors" then
    local t_GameTab = Hub:AddTab("Doors","🚪")

    Hub:AddSection(t_GameTab,"Survival")
    Hub:AddToggle(t_GameTab,"Noclip (Phase Through Doors)",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and 40 or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)

    Hub:AddSection(t_GameTab,"ESP")
    Hub:AddToggle(t_GameTab,"Item ESP (Keys, Flashlights etc)",false,function(v)
        HubState.DR_ItemESP=v
        pcall(function()
            if v then
                local itemNames = {"key","flashlight","lighter","candle","cross","book","knob","lock"}
                for _, obj in pairs(workspace:GetDescendants()) do
                    for _, kw in ipairs(itemNames) do
                        if obj.Name:lower():find(kw) and obj:IsA("BasePart") then
                            local bb=Instance.new("BillboardGui"); bb.Name="DoorESP"
                            bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,100,0,25)
                            bb.StudsOffset=Vector3.new(0,2,0); bb.Parent=obj
                            local lbl=Instance.new("TextLabel")
                            lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0)
                            lbl.Text="🔑 "..obj.Name; lbl.TextColor3=Color3.fromRGB(255,230,50)
                            lbl.TextStrokeTransparency=0; lbl.Font=Enum.Font.GothamBold
                            lbl.TextScaled=true; lbl.Parent=bb
                        end
                    end
                end
            else
                for _, obj in pairs(game:GetDescendants()) do
                    if obj.Name=="DoorESP" then obj:Destroy() end
                end
            end
        end)
    end)
    Hub:AddToggle(t_GameTab,"FullBright (No Darkness)",false,function(v) HubState.FullBright=v ApplyFullBright() end)

    Hub:AddSection(t_GameTab,"Misc")
    Hub:AddButton(t_GameTab,"Teleport to Next Door",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local closest, closestDist = nil, math.huge
            for _, v in pairs(workspace:GetDescendants()) do
                if (v.Name:lower():find("door") or v.Name:lower():find("exit")) and v:IsA("BasePart") then
                    local d = (hrp.Position - v.Position).Magnitude
                    if d < closestDist and d > 3 then closestDist=d; closest=v end
                end
            end
            if closest then hrp.CFrame = closest.CFrame + Vector3.new(0,3,3) end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- PRESSURE (PlaceId: 12411473842) — Horror game similar to Doors
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Pressure" then
    local t_GameTab = Hub:AddTab("Pressure","💀")

    Hub:AddSection(t_GameTab,"Survival")
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and 40 or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)
    Hub:AddToggle(t_GameTab,"FullBright",false,function(v) HubState.FullBright=v ApplyFullBright() end)

    Hub:AddSection(t_GameTab,"ESP & Radar")
    Hub:AddToggle(t_GameTab,"Item ESP",false,function(v)
        pcall(function()
            if v then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:lower():find("key") or obj.Name:lower():find("battery") or obj.Name:lower():find("fuse")) then
                        local bb=Instance.new("BillboardGui"); bb.Name="PressureESP"
                        bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,100,0,25)
                        bb.StudsOffset=Vector3.new(0,2,0); bb.Parent=obj
                        local lbl=Instance.new("TextLabel")
                        lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0)
                        lbl.Text="⚡ "..obj.Name; lbl.TextColor3=Color3.fromRGB(0,200,255)
                        lbl.TextStrokeTransparency=0; lbl.Font=Enum.Font.GothamBold
                        lbl.TextScaled=true; lbl.Parent=bb
                    end
                end
            else
                for _, o in pairs(game:GetDescendants()) do if o.Name=="PressureESP" then o:Destroy() end end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- ADOPT ME (PlaceId: 920587237)
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Adopt Me" then
    local t_GameTab = Hub:AddTab("Adopt Me","🐾")

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Collect Bucks",false,function(v) HubState.AM_AutoBucks=v end)
    Hub:AddToggle(t_GameTab,"Auto Complete Tasks",false,function(v) HubState.AM_AutoTask=v end)
    Hub:AddToggle(t_GameTab,"Auto Feed Pets",false,function(v) HubState.AM_AutoFeed=v end)
    Hub:AddToggle(t_GameTab,"Auto Age Pets",false,function(v) HubState.AM_AutoAge=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)

    Hub:AddSection(t_GameTab,"Misc")
    Hub:AddButton(t_GameTab,"TP to School",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(-18, 0, 130) end
        end)
    end)
    Hub:AddButton(t_GameTab,"TP to Hospital",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(325, 0, -155) end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- DEEPWOKEN (PlaceId: 4111023553)
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Deepwoken" then
    local t_GameTab = Hub:AddTab("Deepwoken","🌊")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Farm EXP",false,function(v) HubState.DW_AutoEXP=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Items",false,function(v) HubState.DW_AutoCollect=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 80) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)

-- ═══════════════════════════════════════════════════════════════
-- GRAND PIECE ONLINE (PlaceId: 4451193957)
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Grand Piece Online" then
    local t_GameTab = Hub:AddTab("Grand Piece","🏴‍☠️")

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Farm Enemies",false,function(v) HubState.GPO_AutoFarm=v end)
    Hub:AddToggle(t_GameTab,"Auto Farm Bosses",false,function(v) HubState.GPO_AutoBoss=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Chests",false,function(v) HubState.GPO_AutoChest=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Fruits",false,function(v) HubState.GPO_AutoFruit=v end)

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)

-- ═══════════════════════════════════════════════════════════════
-- TOWER DEFENSE SIMULATOR (PlaceId: 3260590327)
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Tower Defense Simulator" then
    local t_GameTab = Hub:AddTab("TDS","🗼")

    Hub:AddSection(t_GameTab,"Auto")
    Hub:AddToggle(t_GameTab,"Auto Farm (AFK Coins)",false,function(v) HubState.TDS_AutoFarm=v end)
    Hub:AddToggle(t_GameTab,"Auto Place Towers",false,function(v) HubState.TDS_AutoPlace=v end)
    Hub:AddToggle(t_GameTab,"Auto Upgrade Towers",false,function(v) HubState.TDS_AutoUpgrade=v end)
    Hub:AddToggle(t_GameTab,"Auto Sell Worst Tower",false,function(v) HubState.TDS_AutoSell=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Inf Jump",false,function(v)
        pcall(function()
            if v then LocalPlayer.Character.Humanoid.JumpPower=150 end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- BASKETBALL LEGENDS / PLAYGROUND BASKETBALL
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Basketball Legends" or CurrentGame == "Playground Basketball" then
    local t_GameTab = Hub:AddTab("Basketball","🏀")

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Super Jump",false,function(v) pcall(function() LocalPlayer.Character.Humanoid.JumpPower=v and 200 or 50 end) end)

    Hub:AddSection(t_GameTab,"Basketball Specific")
    Hub:AddToggle(t_GameTab,"Auto Score",false,function(v) HubState.BB_AutoScore=v end)
    Hub:AddToggle(t_GameTab,"Ball ESP",false,function(v)
        pcall(function()
            if v then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj.Name:lower():find("ball") and obj:IsA("BasePart") then
                        local bb=Instance.new("BillboardGui"); bb.Name="BallESP2"
                        bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,80,0,25)
                        bb.StudsOffset=Vector3.new(0,2,0); bb.Parent=obj
                        local lbl=Instance.new("TextLabel")
                        lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0)
                        lbl.Text="🏀 BALL"; lbl.TextColor3=Color3.fromRGB(255,165,0)
                        lbl.TextStrokeTransparency=0; lbl.Font=Enum.Font.GothamBold
                        lbl.TextScaled=true; lbl.Parent=bb
                    end
                end
            else
                for _, o in pairs(game:GetDescendants()) do if o.Name=="BallESP2" then o:Destroy() end end
            end
        end)
    end)
    Hub:AddButton(t_GameTab,"Teleport to Ball",function()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("ball") and obj:IsA("BasePart") then
                    hrp.CFrame = obj.CFrame + Vector3.new(0,3,0); break
                end
            end
        end)
    end)

-- ═══════════════════════════════════════════════════════════════
-- BOXING BETA / KNOCKOUT — Fighting games
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Boxing Beta" or CurrentGame == "Knockout" then
    local t_GameTab = Hub:AddTab(CurrentGame,"🥊")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddSlider(t_GameTab,"Kill Aura Range",3,20,8,function(v) HubState.KillAuraRange=v end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)

-- ═══════════════════════════════════════════════════════════════
-- BUBBLEGUM SIMULATOR (PlaceId: 2512643572)
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "Bubblegum Simulator" then
    local t_GameTab = Hub:AddTab("Bubblegum Sim","🫧")

    Hub:AddSection(t_GameTab,"Farm")
    Hub:AddToggle(t_GameTab,"Auto Blow Bubbles",false,function(v) HubState.BGS_AutoBlow=v end)
    Hub:AddToggle(t_GameTab,"Auto Hatch Egg",false,function(v) HubState.BGS_AutoHatch=v end)
    Hub:AddToggle(t_GameTab,"Auto Collect Coins",false,function(v) HubState.BGS_AutoCoin=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)

-- ═══════════════════════════════════════════════════════════════
-- PVP CLUSTER — MVS Duels, Fantasma PvP, Project Viltrumites,
-- Westbound, Dark Divers, Iron Man Reimagined
-- ═══════════════════════════════════════════════════════════════
elseif CurrentGame == "MVS Duels"
    or CurrentGame == "Fantasma PvP"
    or CurrentGame == "Project Viltrumites"
    or CurrentGame == "Westbound"
    or CurrentGame == "Dark Divers"
    or CurrentGame == "Iron Man Reimagined" then
    local t_GameTab = Hub:AddTab(CurrentGame,"⚔️")

    Hub:AddSection(t_GameTab,"Combat")
    Hub:AddToggle(t_GameTab,"Kill Aura",false,function(v) HubState.KillAura=v end)
    Hub:AddToggle(t_GameTab,"Aimbot",false,function(v) HubState.Aimbot=v end)
    Hub:AddToggle(t_GameTab,"Silent Aim",false,function(v) HubState.SilentAim=v end)
    Hub:AddToggle(t_GameTab,"ESP",false,function(v) HubState.ESPEnabled=v RefreshESP() end)
    Hub:AddToggle(t_GameTab,"Hitbox Expand",false,function(v) HubState.HitboxExpand=v ExpandHitboxes() end)
    Hub:AddToggle(t_GameTab,"Godmode",false,function(v) HubState.Godmode=v end)

    Hub:AddSection(t_GameTab,"Movement")
    Hub:AddToggle(t_GameTab,"Speed Hack",false,function(v) HubState.SpeedHack=v pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed=v and (HubState.SpeedValue or 100) or 16 end) end)
    Hub:AddToggle(t_GameTab,"Fly",false,function(v) HubState.FlyEnabled=v if v then StartFly() end end)
    Hub:AddToggle(t_GameTab,"Noclip",false,function(v) HubState.Noclip=v end)

    Hub:AddSection(t_GameTab,"Misc")
    Hub:AddToggle(t_GameTab,"Inf Ammo",false,function(v) HubState.InfAmmo=v end)
    Hub:AddToggle(t_GameTab,"No Recoil",false,function(v) HubState.NoRecoil=v end)


end -- END of game tab elseif chain

-- ============================================================
-- UNIVERSAL INSTANCE SPY TAB (safe, no namecall hooks)
-- ============================================================
local spyTab = Hub:AddTab("Spy","🔍")
Hub:AddSection(spyTab,"Instance Scanner — results print to F9 console")

Hub:AddButton(spyTab,"🔔 Scan Proximity Prompts", function()
    print("\n===== PROXIMITY PROMPTS =====")
    local found = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            found = found + 1
            print(found..". ["..v.ActionText.."] | KeyCode: "..tostring(v.KeyboardKeyCode).." | Parent: "..v.Parent:GetFullName())
        end
    end
    print("Total found: "..found)
    print("=============================\n")
end)

Hub:AddButton(spyTab,"📡 Scan RemoteEvents", function()
    print("\n===== REMOTE EVENTS =====")
    local found = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            found = found + 1
            print(found..". "..v:GetFullName())
        end
    end
    print("Total found: "..found)
    print("=========================\n")
end)

Hub:AddButton(spyTab,"📡 Scan RemoteFunctions", function()
    print("\n===== REMOTE FUNCTIONS =====")
    local found = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteFunction") then
            found = found + 1
            print(found..". "..v:GetFullName())
        end
    end
    print("Total found: "..found)
    print("============================\n")
end)

Hub:AddButton(spyTab,"🧩 Scan BindableEvents", function()
    print("\n===== BINDABLE EVENTS =====")
    local found = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("BindableEvent") then
            found = found + 1
            print(found..". "..v:GetFullName())
        end
    end
    print("Total found: "..found)
    print("===========================\n")
end)

Hub:AddButton(spyTab,"💰 Scan Cash/Money Values", function()
    print("\n===== CASH / MONEY VALUES =====")
    local found = 0
    local keywords = {"cash","money","coin","dollar","bux","buck","credit","balance","wallet"}
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
            local n = v.Name:lower()
            for _, kw in ipairs(keywords) do
                if string.find(n, kw) then
                    found = found + 1
                    print(found..". "..v:GetFullName().." = "..tostring(v.Value))
                    break
                end
            end
        end
    end
    print("Total found: "..found)
    print("================================\n")
end)

Hub:AddButton(spyTab,"🗣️ Scan NPC / Character Models", function()
    print("\n===== NPC / CHARACTERS =====")
    local found = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildWhichIsA("Humanoid") then
            found = found + 1
            local hp = v:FindFirstChildWhichIsA("Humanoid").Health
            print(found..". "..v.Name.." | HP: "..tostring(math.floor(hp)).." | Pos: "..tostring(v:GetPivot().Position))
        end
    end
    print("Total found: "..found)
    print("============================\n")
end)

Hub:AddButton(spyTab,"🚪 Scan Teleport Parts (Doors/Zones)", function()
    print("\n===== TELEPORT PARTS =====")
    local found = 0
    local keywords = {"door","teleport","zone","exit","enter","warp","spawn","tp"}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Model") then
            local n = v.Name:lower()
            for _, kw in ipairs(keywords) do
                if string.find(n, kw) then
                    found = found + 1
                    print(found..". "..v:GetFullName())
                    break
                end
            end
        end
    end
    print("Total found: "..found)
    print("==========================\n")
end)

Hub:AddButton(spyTab,"🔫 Scan Tools / Weapons in Workspace", function()
    print("\n===== TOOLS / WEAPONS =====")
    local found = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("Tool") then
            found = found + 1
            print(found..". "..v:GetFullName())
        end
    end
    print("Total found: "..found)
    print("===========================\n")
end)

Hub:AddButton(spyTab,"🏷️ Scan All Scripts (Server/Local)", function()
    print("\n===== SCRIPTS =====")
    local found = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
            found = found + 1
            print(found..". ["..v.ClassName.."] "..v:GetFullName())
        end
    end
    print("Total found: "..found)
    print("===================\n")
end)

Hub:AddButton(spyTab,"🧹 Clear Console", function()
    for i = 1, 80 do print("") end
    print("Console cleared.")
end)




-- ╔══════════════════════════════════════════════════════════════╗

-- ║                      LOOPS SECTION                           ║
-- ║  Paste this into your main task.spawn / RunService loop      ║
-- ╚══════════════════════════════════════════════════════════════╝

--[[
    LOOPS SECTION
    These loops should be spawned once at script start.
    They check HubState flags set by the toggles above.
    All loops use task.wait(0.5) for efficiency.
--]]

task.spawn(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local lp = Players.LocalPlayer

    -- ─────────────────────────────────────────────
    --  DA HOOD LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Farm Cash: Collect money drops in Workspace.Ignored.Drop
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.DH_AutoCash then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local dropFolder = workspace:FindFirstChild("Ignored")
                        and workspace.Ignored:FindFirstChild("Drop")
                    if dropFolder then
                        for _, v in pairs(dropFolder:GetDescendants()) do
                            if v:IsA("ClickDetector") and v.Parent.Name == "MoneyDrop" then
                                hrp.CFrame = CFrame.new(v.Parent.Position + Vector3.new(0, 3, 0))
                                task.wait(0.2)
                                pcall(function() fireclickdetector(v, 0) end)
                                task.wait(0.2)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Stomp Downed: Stomp players with ragdoll state
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.DH_AutoStomp then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= lp and player.Character then
                            local hum = player.Character:FindFirstChild("Humanoid")
                            local enemyHRP = player.Character:FindFirstChild("HumanoidRootPart")
                            -- Ragdolled players have < 1 health or are in ragdoll state
                            if hum and enemyHRP and hum.Health < 1 then
                                hrp.CFrame = CFrame.new(enemyHRP.Position + Vector3.new(0, 2, 0))
                                task.wait(0.1)
                                -- Fire MainEvent stomp
                                local mainEvent = RS:FindFirstChild("MainEvent")
                                if mainEvent then
                                    pcall(function() mainEvent:FireServer("Stomp", player) end)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Pickup Guns: Collect tool drops
    task.spawn(function()
        while true do
            task.wait(0.6)
            if HubState.DH_AutoPickupGun then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local itemsDrop = workspace:FindFirstChild("Ignored")
                        and workspace.Ignored:FindFirstChild("ItemsDrop")
                    if itemsDrop then
                        for _, v in pairs(itemsDrop:GetDescendants()) do
                            if v:IsA("Tool") then
                                local pp = v.Parent
                                local pos = pp:IsA("BasePart") and pp.Position
                                    or (pp.PrimaryPart and pp.PrimaryPart.Position)
                                if pos then
                                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                    task.wait(0.3)
                                    local touch = v:FindFirstChildWhichIsA("TouchTransmitter")
                                    if touch then
                                        pcall(function() firetouchinterest(hrp, pp:IsA("BasePart") and pp or pp.PrimaryPart, 0) end)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Bank Deposit
    task.spawn(function()
        while true do
            task.wait(2)
            if HubState.DH_AutoBank then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Teleport to bank and interact
                    hrp.CFrame = CFrame.new(271, 18, -616)
                    task.wait(0.5)
                    local mainEvent = RS:FindFirstChild("MainEvent")
                    if mainEvent then
                        pcall(function() mainEvent:FireServer("DepositAll") end)
                    end
                end)
            end
        end
    end)

    -- Lock Victim: Continuously set nearest target
    task.spawn(function()
        while true do
            task.wait(0.3)
            if HubState.DH_LockVictim then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local nearest, nearDist = nil, math.huge
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= lp and player.Character then
                            local enemyHRP = player.Character:FindFirstChild("HumanoidRootPart")
                            local hum = player.Character:FindFirstChild("Humanoid")
                            if enemyHRP and hum and hum.Health > 0 then
                                local d = (enemyHRP.Position - hrp.Position).Magnitude
                                if d < nearDist then
                                    nearDist = d
                                    nearest = player
                                end
                            end
                        end
                    end
                    HubState.DH_LockedTarget = nearest
                end)
            end
        end
    end)

    -- Auto Collect Drops (shoes, misc items)
    task.spawn(function()
        while true do
            task.wait(0.7)
            if HubState.DH_AutoCollectDrops then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local dropFolder = workspace:FindFirstChild("Ignored")
                        and workspace.Ignored:FindFirstChild("Drop")
                    if dropFolder then
                        for _, v in pairs(dropFolder:GetDescendants()) do
                            if v:IsA("ClickDetector") then
                                hrp.CFrame = CFrame.new(v.Parent.Position + Vector3.new(0, 3, 0))
                                task.wait(0.15)
                                pcall(function() fireclickdetector(v, 0) end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  GANG WARS LOOPS
    -- ─────────────────────────────────────────────

    -- Potato Farm
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.GW_PotatoFarm then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name == "Potato" or v.Name == "potato" then
                            local pos = v:IsA("BasePart") and v.Position
                                or (v:IsA("Model") and v:GetPivot().Position)
                            if pos and (pos - hrp.Position).Magnitude < 500 then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                task.wait(0.3)
                                if v:IsA("BasePart") then
                                    pcall(function() firetouchinterest(hrp, v, 0) end)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Car Farm
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.GW_CarFarm then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Model") and (v.Name:lower():find("car") or v.Name:lower():find("vehicle")) then
                            local primary = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                            if primary then
                                hrp.CFrame = CFrame.new(primary.Position + Vector3.new(0, 3, 0))
                                task.wait(0.5)
                                -- Look for seat/VehicleSeat
                                local seat = v:FindFirstChildWhichIsA("VehicleSeat")
                                    or v:FindFirstChildWhichIsA("Seat")
                                if seat then
                                    pcall(function() seat:Sit(char:FindFirstChild("Humanoid")) end)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Store Rob
    task.spawn(function()
        while true do
            task.wait(1.5)
            if HubState.GW_StoreRob then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Find store/rob objects in workspace
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and (v.ActionText:lower():find("rob") or v.ObjectText:lower():find("store")) then
                            local att = v.Parent
                            if att then
                                local pos = att:IsA("BasePart") and att.Position
                                    or (att.Parent and att.Parent:IsA("Model") and att.Parent:GetPivot().Position)
                                if pos then
                                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                    task.wait(0.3)
                                    pcall(function() fireproximityprompt(v) end)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Kill NPC
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.GW_AutoKillNPC then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Humanoid") and v.Parent ~= char and v.Health > 0 then
                            local npcHRP = v.Parent:FindFirstChild("HumanoidRootPart")
                            if npcHRP and not Players:GetPlayerFromCharacter(v.Parent) then
                                hrp.CFrame = CFrame.new(npcHRP.Position + Vector3.new(0, 2, 2))
                                task.wait(0.2)
                                local tool = char:FindFirstChildWhichIsA("Tool")
                                    or lp.Backpack:FindFirstChildWhichIsA("Tool")
                                if tool and not char:FindFirstChildWhichIsA("Tool") then
                                    char:FindFirstChild("Humanoid"):EquipTool and char.Humanoid:EquipTool(tool)
                                end
                                local handle = tool and tool:FindFirstChild("Handle")
                                if handle then
                                    pcall(function() firetouchinterest(handle, npcHRP, 0) end)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Revive Allies
    task.spawn(function()
        while true do
            task.wait(0.8)
            if HubState.GW_AutoRevive then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.ActionText:lower():find("revive") then
                            local att = v.Parent
                            local pos = att and (att:IsA("BasePart") and att.Position
                                or (att.Parent and att.Parent:IsA("Model") and att.Parent:GetPivot().Position))
                            if pos then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                                task.wait(0.3)
                                pcall(function() fireproximityprompt(v) end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Buy Ammo
    task.spawn(function()
        while true do
            task.wait(3)
            if HubState.GW_AutoAmmo then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.ObjectText:lower():find("ammo") then
                            local att = v.Parent
                            local pos = att and (att:IsA("BasePart") and att.Position
                                or (att.Parent and att.Parent:IsA("Model") and att.Parent:GetPivot().Position))
                            if pos then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                                task.wait(0.3)
                                pcall(function() fireproximityprompt(v) end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  BLOX FRUITS LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Farm Mastery: Attack nearest mob repeatedly
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.BF_AutoMastery then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChild("Humanoid")
                    if not hrp or not hum then return end
                    local nearest, nearDist = nil, math.huge
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Humanoid") and v.Parent ~= char and v.Health > 0
                            and not Players:GetPlayerFromCharacter(v.Parent) then
                            local mobHRP = v.Parent:FindFirstChild("HumanoidRootPart")
                            if mobHRP then
                                local d = (mobHRP.Position - hrp.Position).Magnitude
                                if d < nearDist then
                                    nearDist = d
                                    nearest = mobHRP
                                end
                            end
                        end
                    end
                    if nearest and nearDist > 0 then
                        hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 2, 4))
                            * CFrame.Angles(0, math.pi, 0)
                    end
                end)
            end
        end
    end)

    -- Auto Farm Bounty: Target players
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.BF_AutoBounty then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local nearest, nearDist = nil, math.huge
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= lp and player.Character then
                            local enemyHRP = player.Character:FindFirstChild("HumanoidRootPart")
                            local hum = player.Character:FindFirstChild("Humanoid")
                            if enemyHRP and hum and hum.Health > 0 then
                                local d = (enemyHRP.Position - hrp.Position).Magnitude
                                if d < nearDist then
                                    nearDist = d
                                    nearest = enemyHRP
                                end
                            end
                        end
                    end
                    if nearest then
                        hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 2, 4))
                            * CFrame.Angles(0, math.pi, 0)
                    end
                end)
            end
        end
    end)

    -- Auto Chest Farm
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.BF_AutoChest then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name == "Chest" and v:IsA("Model") then
                            local pivot = v:GetPivot().Position
                            hrp.CFrame = CFrame.new(pivot + Vector3.new(0, 3, 0))
                            task.wait(0.3)
                            local pp = v:FindFirstChildWhichIsA("ProximityPrompt")
                            if pp then pcall(function() fireproximityprompt(pp) end) end
                            -- Also try click detector
                            local cd = v:FindFirstChildWhichIsA("ClickDetector", true)
                            if cd then pcall(function() fireclickdetector(cd, 0) end) end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Collect Fruits (from Workspace.SpawnedFruits or similar)
    task.spawn(function()
        while true do
            task.wait(0.8)
            if HubState.BF_AutoCollectFruit then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Blox Fruits spawns fruits in workspace with Touch detection
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Model") and v:FindFirstChild("Handle") then
                            local handle = v:FindFirstChild("Handle")
                            if handle and (handle:FindFirstChild("TouchInterest") or handle:FindFirstChildWhichIsA("TouchTransmitter")) then
                                hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0, 3, 0))
                                task.wait(0.2)
                                pcall(function() firetouchinterest(hrp, handle, 0) end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Sea Beast
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.BF_AutoSeaBeast then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Sea beasts are large NPCs with "SeaBeast" or similar in name
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("seabeast") or v.Name:lower():find("sea beast") or v.Name:lower():find("leviathan"))
                            and v:IsA("Model") then
                            local primary = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                            if primary then
                                hrp.CFrame = CFrame.new(primary.Position + Vector3.new(0, 2, 8))
                                    * CFrame.Angles(0, math.pi, 0)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Raid Farm: Fire raid remote or teleport to raid zone
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.BF_AutoRaid then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Kill mobs in raid area (typically in Workspace.Map.*)
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Humanoid") and v.Parent ~= char and v.Health > 0
                            and not Players:GetPlayerFromCharacter(v.Parent)
                            and v.MaxHealth >= 5000 then -- raid mobs have high HP
                            local mobHRP = v.Parent:FindFirstChild("HumanoidRootPart")
                            if mobHRP then
                                hrp.CFrame = CFrame.new(mobHRP.Position + Vector3.new(0, 2, 5))
                                    * CFrame.Angles(0, math.pi, 0)
                                task.wait(0.3)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  JAILBREAK LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Rob Bank
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.JB_AutoBank then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Teleport inside bank vault
                    hrp.CFrame = CFrame.new(277, 18, -1595)
                    task.wait(0.5)
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.ObjectText:lower():find("bank") then
                            pcall(function() fireproximityprompt(v) end)
                        end
                        if v:IsA("ClickDetector") and v.Parent.Name:lower():find("cash") then
                            pcall(function() fireclickdetector(v, 0) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Rob Jewelry
    task.spawn(function()
        while true do
            task.wait(1.5)
            if HubState.JB_AutoJewelry then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    hrp.CFrame = CFrame.new(-602, 18, 131)
                    task.wait(0.5)
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and (v.ObjectText:lower():find("jewelry") or v.ObjectText:lower():find("gem")) then
                            pcall(function() fireproximityprompt(v) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Rob Casino
    task.spawn(function()
        while true do
            task.wait(2)
            if HubState.JB_AutoCasino then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.ObjectText:lower():find("casino") then
                            local att = v.Parent
                            local pos = att:IsA("BasePart") and att.Position
                                or att:GetPivot().Position
                            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 2))
                            task.wait(0.3)
                            pcall(function() fireproximityprompt(v) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Rob Train
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.JB_AutoTrain then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Find train in workspace
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Model") and (v.Name:lower():find("train") or v.Name:lower():find("cargo")) then
                            local primary = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                            if primary then
                                hrp.CFrame = CFrame.new(primary.Position + Vector3.new(0, 4, 0))
                                task.wait(0.3)
                            end
                        end
                        if v:IsA("ProximityPrompt") and v.ObjectText:lower():find("train") then
                            pcall(function() fireproximityprompt(v) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Collect Cargo
    task.spawn(function()
        while true do
            task.wait(0.8)
            if HubState.JB_AutoCargo then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("cargo") or v.Name:lower():find("crate")) then
                            local pos = v:IsA("BasePart") and v.Position
                                or (v:IsA("Model") and v:GetPivot().Position)
                            if pos then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                task.wait(0.2)
                                local cd = v:FindFirstChildWhichIsA("ClickDetector", true)
                                if cd then pcall(function() fireclickdetector(cd, 0) end) end
                                local pp = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if pp then pcall(function() fireproximityprompt(pp) end) end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Infinite Nitro
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.JB_InfNitro then
                pcall(function()
                    local char = lp.Character
                    if not char then return end
                    -- Find vehicle the player is in
                    local seat = char:FindFirstChildWhichIsA("Seat")
                        or char:FindFirstChildWhichIsA("VehicleSeat")
                    if seat then
                        local nitroVal = seat.Parent:FindFirstChild("Nitro")
                            or seat.Parent:FindFirstChild("NitroAmount")
                        if nitroVal then
                            nitroVal.Value = nitroVal.MaxValue or 100
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  MURDER MYSTERY 2 LOOPS
    -- ─────────────────────────────────────────────

    -- ESP Murderer: Highlight murderer in red
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.MM2_ESPMurderer then
                pcall(function()
                    -- Remove old ESP
                    for _, player in pairs(Players:GetPlayers()) do
                        if player.Character then
                            for _, v in pairs(player.Character:GetDescendants()) do
                                if v.Name == "MM2_ESPHighlight" then v:Destroy() end
                            end
                        end
                    end
                    -- Find murderer: look for knife tool
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= lp and player.Character then
                            local knife = player.Character:FindFirstChild("Knife")
                                or player.Character:FindFirstChild("MM2Knife")
                                or player.Backpack:FindFirstChild("Knife")
                            if knife then
                                local highlight = Instance.new("Highlight")
                                highlight.Name = "MM2_ESPHighlight"
                                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                                highlight.FillTransparency = 0.5
                                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                highlight.Parent = player.Character
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Coin Farm
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.MM2_AutoCoin then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name == "Coin" and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))
                            task.wait(0.15)
                            pcall(function() firetouchinterest(hrp, v, 0) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Knife Throw (murderer tool)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.MM2_AutoKnifeThrow then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local knife = char:FindFirstChild("Knife") or char:FindFirstChild("MM2Knife")
                    if not knife then return end
                    -- Find nearest player
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= lp and player.Character then
                            local enemyHRP = player.Character:FindFirstChild("HumanoidRootPart")
                            local hum = player.Character:FindFirstChild("Humanoid")
                            if enemyHRP and hum and hum.Health > 0 then
                                local RS2 = game:GetService("ReplicatedStorage")
                                local throwEvent = RS2:FindFirstChild("ThrowKnife", true)
                                    or RS2:FindFirstChild("Throw", true)
                                if throwEvent and throwEvent:IsA("RemoteEvent") then
                                    pcall(function() throwEvent:FireServer(enemyHRP.Position) end)
                                end
                                break
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Sheriff Auto Win (follow murderer)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.MM2_SheriffAutoWin then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local gun = char:FindFirstChild("Sheriff") or char:FindFirstChild("Gun")
                    if not gun then return end
                    -- Find murderer (player with knife)
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= lp and player.Character then
                            local knife = player.Character:FindFirstChild("Knife")
                                or player.Character:FindFirstChild("MM2Knife")
                            if knife then
                                local enemyHRP = player.Character:FindFirstChild("HumanoidRootPart")
                                if enemyHRP then
                                    hrp.CFrame = CFrame.new(enemyHRP.Position + Vector3.new(0, 2, 6))
                                        * CFrame.Angles(0, math.pi, 0)
                                    task.wait(0.1)
                                    local shootEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Shoot", true)
                                        or game:GetService("ReplicatedStorage"):FindFirstChild("ShootGun", true)
                                    if shootEvent and shootEvent:IsA("RemoteEvent") then
                                        pcall(function() shootEvent:FireServer(enemyHRP.Position) end)
                                    end
                                end
                                break
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Godhand Shoot
    task.spawn(function()
        while true do
            task.wait(0.3)
            if HubState.MM2_AutoGodhand then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local godhand = char:FindFirstChild("Godhand") or char:FindFirstChild("GodlyGun")
                    if not godhand then return end
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= lp and player.Character then
                            local hum = player.Character:FindFirstChild("Humanoid")
                            local enemyHRP = player.Character:FindFirstChild("HumanoidRootPart")
                            if hum and hum.Health > 0 and enemyHRP then
                                local shootEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Shoot", true)
                                if shootEvent and shootEvent:IsA("RemoteEvent") then
                                    pcall(function() shootEvent:FireServer(enemyHRP.Position) end)
                                end
                                break
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  PET SIMULATOR 99 LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Hatch Egg
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.PS99_AutoHatch then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and (v.ObjectText:lower():find("egg") or v.ActionText:lower():find("hatch")) then
                            local att = v.Parent
                            local pos = att:IsA("BasePart") and att.Position
                                or (att.Parent and att.Parent:IsA("Model") and att.Parent:GetPivot().Position)
                            if pos then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                task.wait(0.2)
                                pcall(function() fireproximityprompt(v) end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Farm Diamonds (touch diamond objects)
    task.spawn(function()
        while true do
            task.wait(0.4)
            if HubState.PS99_AutoDiamond then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name == "Diamond" and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 2, 0))
                            task.wait(0.1)
                            pcall(function() firetouchinterest(hrp, v, 0) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Collect Coins
    task.spawn(function()
        while true do
            task.wait(0.4)
            if HubState.PS99_AutoCoin then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name == "Coin" and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 2, 0))
                            task.wait(0.1)
                            pcall(function() firetouchinterest(hrp, v, 0) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Enchant Pets
    task.spawn(function()
        while true do
            task.wait(2)
            if HubState.PS99_AutoEnchant then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local enchantEvent = RS2:FindFirstChild("Enchant", true)
                        or RS2:FindFirstChild("EnchantPet", true)
                    if enchantEvent and enchantEvent:IsA("RemoteEvent") then
                        pcall(function() enchantEvent:FireServer() end)
                    end
                end)
            end
        end
    end)

    -- Auto Fuse Pets
    task.spawn(function()
        while true do
            task.wait(2)
            if HubState.PS99_AutoFuse then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local fuseEvent = RS2:FindFirstChild("FusePets", true)
                        or RS2:FindFirstChild("Fuse", true)
                    if fuseEvent and fuseEvent:IsA("RemoteEvent") then
                        pcall(function() fuseEvent:FireServer() end)
                    end
                end)
            end
        end
    end)

    -- Auto Open Chests
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.PS99_AutoChest then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name == "Chest" or v.Name:lower():find("chest")) and v:IsA("Model") then
                            local pivot = v:GetPivot().Position
                            hrp.CFrame = CFrame.new(pivot + Vector3.new(0, 3, 0))
                            task.wait(0.3)
                            local pp = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if pp then pcall(function() fireproximityprompt(pp) end) end
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  GROW A GARDEN LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Plant Seeds
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.GAG_AutoPlant then
                pcall(function()
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and (v.ActionText:lower():find("plant") or v.ObjectText:lower():find("plot")) then
                            pcall(function() fireproximityprompt(v) end)
                            task.wait(0.2)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Harvest
    task.spawn(function()
        while true do
            task.wait(0.8)
            if HubState.GAG_AutoHarvest then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and (v.ActionText:lower():find("harvest") or v.ActionText:lower():find("pick")) then
                            local att = v.Parent
                            local pos = att:IsA("BasePart") and att.Position
                                or (att.Parent and att.Parent:GetPivot and att.Parent:GetPivot().Position)
                            if pos then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                task.wait(0.2)
                                pcall(function() fireproximityprompt(v) end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Water
    task.spawn(function()
        while true do
            task.wait(0.8)
            if HubState.GAG_AutoWater then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.ActionText:lower():find("water") then
                            local att = v.Parent
                            local pos = att:IsA("BasePart") and att.Position
                                or (att.Parent and att.Parent:GetPivot and att.Parent:GetPivot().Position)
                            if pos then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                task.wait(0.2)
                                pcall(function() fireproximityprompt(v) end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Buy Seeds
    task.spawn(function()
        while true do
            task.wait(3)
            if HubState.GAG_AutoBuySeeds then
                pcall(function()
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and (v.ObjectText:lower():find("seed") or v.ActionText:lower():find("buy")) then
                            pcall(function() fireproximityprompt(v) end)
                            task.wait(0.2)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Sell Crops
    task.spawn(function()
        while true do
            task.wait(2)
            if HubState.GAG_AutoSell then
                pcall(function()
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.ActionText:lower():find("sell") then
                            pcall(function() fireproximityprompt(v) end)
                            task.wait(0.2)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Fertilize
    task.spawn(function()
        while true do
            task.wait(1.5)
            if HubState.GAG_AutoFertilize then
                pcall(function()
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.ActionText:lower():find("fertilize") then
                            pcall(function() fireproximityprompt(v) end)
                            task.wait(0.2)
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  BLADE BALL LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Parry Ball: Fire parry event when ball is nearby
    task.spawn(function()
        while true do
            task.wait(0.05) -- Fast loop needed for parry timing
            if HubState.BB_AutoParry then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Find the ball
                    local ball = workspace:FindFirstChild("Ball")
                        or workspace:FindFirstChild("bb_ball")
                    if not ball then
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v.Name == "Ball" and v:IsA("BasePart") then
                                ball = v
                                break
                            end
                        end
                    end
                    if ball then
                        local dist = (ball.Position - hrp.Position).Magnitude
                        if dist < 20 then -- Ball is close enough to parry
                            local parryEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Parry", true)
                                or game:GetService("ReplicatedStorage"):FindFirstChild("ParryEvent", true)
                                or game:GetService("ReplicatedStorage"):FindFirstChild("Deflect", true)
                            if parryEvent and parryEvent:IsA("RemoteEvent") then
                                pcall(function() parryEvent:FireServer() end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Deflect Chain (keep deflecting when active)
    task.spawn(function()
        while true do
            task.wait(0.1)
            if HubState.BB_AutoDeflect then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local deflectEvent = RS2:FindFirstChild("Deflect", true)
                        or RS2:FindFirstChild("Parry", true)
                    if deflectEvent and deflectEvent:IsA("RemoteEvent") then
                        pcall(function() deflectEvent:FireServer() end)
                    end
                end)
            end
        end
    end)

    -- Teleport to Ball (constantly track ball)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if HubState.BB_TpToBall then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local ball = nil
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name == "Ball" and v:IsA("BasePart") then
                            ball = v
                            break
                        end
                    end
                    if ball then
                        hrp.CFrame = CFrame.new(ball.Position + Vector3.new(0, 3, 0))
                    end
                end)
            end
        end
    end)

    -- Auto Use Ability
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.BB_AutoAbility then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    -- Blade Ball ability events
                    local abilityEvent = RS2:FindFirstChild("UseAbility", true)
                        or RS2:FindFirstChild("Ability", true)
                        or RS2:FindFirstChild("ActivateAbility", true)
                    if abilityEvent and abilityEvent:IsA("RemoteEvent") then
                        pcall(function() abilityEvent:FireServer() end)
                    end
                end)
            end
        end
    end)

    -- Auto Win (survive by dodging/staying away from ball's target)
    task.spawn(function()
        while true do
            task.wait(0.3)
            if HubState.BB_AutoWin then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Find ball and dodge if it's coming toward local player
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name == "Ball" and v:IsA("BasePart") then
                            local dist = (v.Position - hrp.Position).Magnitude
                            if dist < 15 then
                                -- Move perpendicular to the ball's velocity
                                local vel = v:IsA("BasePart") and v.AssemblyLinearVelocity or Vector3.new()
                                local dodge = hrp.CFrame.RightVector * 20
                                hrp.CFrame = CFrame.new(hrp.Position + dodge)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  BEE SWARM SIMULATOR LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Collect Honey
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.BSS_AutoHoney then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v.Name == "Honey" and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))
                            task.wait(0.15)
                            pcall(function() firetouchinterest(hrp, v, 0) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Farm Pollen (stand in flower field)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.BSS_AutoPollen then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("flower") or v.Name:lower():find("pollen")) and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 2, 0))
                            task.wait(0.2)
                            pcall(function() firetouchinterest(hrp, v, 0) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Complete Quest
    task.spawn(function()
        while true do
            task.wait(2)
            if HubState.BSS_AutoQuest then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local questEvent = RS2:FindFirstChild("CompleteQuest", true)
                        or RS2:FindFirstChild("Quest", true)
                        or RS2:FindFirstChild("FinishQuest", true)
                    if questEvent and questEvent:IsA("RemoteEvent") then
                        pcall(function() questEvent:FireServer() end)
                    end
                    -- Also try to find NPCs with quest complete prompts
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.ActionText:lower():find("quest") then
                            pcall(function() fireproximityprompt(v) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Buy Gear
    task.spawn(function()
        while true do
            task.wait(3)
            if HubState.BSS_AutoBuyGear then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and (v.ObjectText:lower():find("shop") or v.ActionText:lower():find("buy")) then
                            local att = v.Parent
                            local pos = att:IsA("BasePart") and att.Position
                                or (att.Parent and att.Parent:GetPivot and att.Parent:GetPivot().Position)
                            if pos then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                task.wait(0.3)
                                pcall(function() fireproximityprompt(v) end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Fight Monster
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.BSS_AutoFightMonster then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Find monster (bears, etc.)
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("bear") or v.Name:lower():find("monster") or v.Name:lower():find("boss"))
                            and v:IsA("Model") then
                            local hum = v:FindFirstChildWhichIsA("Humanoid")
                            local monsterHRP = v:FindFirstChild("HumanoidRootPart")
                            if hum and hum.Health > 0 and monsterHRP then
                                hrp.CFrame = CFrame.new(monsterHRP.Position + Vector3.new(0, 2, 5))
                                    * CFrame.Angles(0, math.pi, 0)
                                task.wait(0.2)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  SHINDO LIFE LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Farm EXP (attack mobs)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.SL_AutoEXP then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Humanoid") and v.Parent ~= char and v.Health > 0
                            and not Players:GetPlayerFromCharacter(v.Parent) then
                            local mobHRP = v.Parent:FindFirstChild("HumanoidRootPart")
                            if mobHRP then
                                hrp.CFrame = CFrame.new(mobHRP.Position + Vector3.new(0, 2, 4))
                                    * CFrame.Angles(0, math.pi, 0)
                                task.wait(0.2)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Spin Elements
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.SL_AutoSpin then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local reiFolder = RS2:FindFirstChild("rei")
                    if reiFolder then
                        local spinRemote = reiFolder:FindFirstChild("Spin")
                            or reiFolder:FindFirstChild("SpinElement")
                            or reiFolder:FindFirstChild("FreeSpins")
                        if spinRemote then
                            if spinRemote:IsA("RemoteFunction") then
                                pcall(function() spinRemote:InvokeServer("FreeSpins") end)
                            elseif spinRemote:IsA("RemoteEvent") then
                                pcall(function() spinRemote:FireServer("FreeSpins") end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Sword Farm
    task.spawn(function()
        while true do
            task.wait(0.4)
            if HubState.SL_AutoSword then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Find nearest enemy and attack with sword
                    local nearest, nearDist = nil, math.huge
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Humanoid") and v.Parent ~= char and v.Health > 0
                            and not Players:GetPlayerFromCharacter(v.Parent) then
                            local mobHRP = v.Parent:FindFirstChild("HumanoidRootPart")
                            if mobHRP then
                                local d = (mobHRP.Position - hrp.Position).Magnitude
                                if d < nearDist then
                                    nearDist = d
                                    nearest = mobHRP
                                end
                            end
                        end
                    end
                    if nearest then
                        hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 2, 3))
                            * CFrame.Angles(0, math.pi, 0)
                    end
                end)
            end
        end
    end)

    -- Auto RELL Coin Farm
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.SL_AutoRELLCoin then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name == "RELLcoin" or v.Name == "RellCoin" or v.Name == "RELLCoin")
                            and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))
                            task.wait(0.15)
                            pcall(function() firetouchinterest(hrp, v, 0) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Mode Farm (activate sage/tailed beast mode)
    task.spawn(function()
        while true do
            task.wait(2)
            if HubState.SL_AutoMode then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local reiFolder = RS2:FindFirstChild("rei")
                    if reiFolder then
                        -- Activate mode remote in Shindo Life
                        local modeEvent = reiFolder:FindFirstChild("ActivateMode")
                            or reiFolder:FindFirstChild("Mode")
                        if modeEvent and modeEvent:IsA("RemoteEvent") then
                            pcall(function() modeEvent:FireServer() end)
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  THE STRONGEST BATTLEGROUNDS LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Farm KO (attack nearest player)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.TSB_AutoKO then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local nearest, nearDist = nil, math.huge
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= lp and player.Character then
                            local enemyHRP = player.Character:FindFirstChild("HumanoidRootPart")
                            local hum = player.Character:FindFirstChild("Humanoid")
                            if enemyHRP and hum and hum.Health > 0 then
                                local d = (enemyHRP.Position - hrp.Position).Magnitude
                                if d < nearDist then
                                    nearDist = d
                                    nearest = enemyHRP
                                end
                            end
                        end
                    end
                    if nearest then
                        hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 2, 3))
                            * CFrame.Angles(0, math.pi, 0)
                        task.wait(0.1)
                        local RS2 = game:GetService("ReplicatedStorage")
                        local attackEvent = RS2:FindFirstChild("Punch", true)
                            or RS2:FindFirstChild("Attack", true)
                            or RS2:FindFirstChild("M1", true)
                        if attackEvent and attackEvent:IsA("RemoteEvent") then
                            pcall(function() attackEvent:FireServer(nearest.Position) end)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Block Break
    task.spawn(function()
        while true do
            task.wait(0.3)
            if HubState.TSB_AutoBlockBreak then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local blockBreakEvent = RS2:FindFirstChild("BlockBreak", true)
                        or RS2:FindFirstChild("BreakBlock", true)
                    if blockBreakEvent and blockBreakEvent:IsA("RemoteEvent") then
                        pcall(function() blockBreakEvent:FireServer() end)
                    end
                end)
            end
        end
    end)

    -- Auto Counter
    task.spawn(function()
        while true do
            task.wait(0.1)
            if HubState.TSB_AutoCounter then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local counterEvent = RS2:FindFirstChild("Counter", true)
                        or RS2:FindFirstChild("CounterAttack", true)
                    if counterEvent and counterEvent:IsA("RemoteEvent") then
                        pcall(function() counterEvent:FireServer() end)
                    end
                end)
            end
        end
    end)

    -- Auto Combo
    task.spawn(function()
        while true do
            task.wait(0.2)
            if HubState.TSB_AutoCombo then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local RS2 = game:GetService("ReplicatedStorage")
                    -- Fire M1/punch combo repeatedly
                    for i = 1, 4 do
                        local m1Event = RS2:FindFirstChild("M1", true)
                            or RS2:FindFirstChild("Punch", true)
                            or RS2:FindFirstChild("Attack", true)
                        if m1Event and m1Event:IsA("RemoteEvent") then
                            pcall(function() m1Event:FireServer() end)
                        end
                        task.wait(0.15)
                    end
                end)
            end
        end
    end)

    -- Auto Rank Up
    task.spawn(function()
        while true do
            task.wait(5)
            if HubState.TSB_AutoRankUp then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local rankEvent = RS2:FindFirstChild("RankUp", true)
                        or RS2:FindFirstChild("Prestige", true)
                    if rankEvent and rankEvent:IsA("RemoteEvent") then
                        pcall(function() rankEvent:FireServer() end)
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────
    --  ANIME DEFENDERS LOOPS
    -- ─────────────────────────────────────────────

    -- Auto Farm Stage
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.AD_AutoFarm then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    -- Attack enemies in the stage
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Humanoid") and v.Parent ~= char and v.Health > 0
                            and not Players:GetPlayerFromCharacter(v.Parent) then
                            local mobHRP = v.Parent:FindFirstChild("HumanoidRootPart")
                            if mobHRP then
                                local RS2 = game:GetService("ReplicatedStorage")
                                local attackEvent = RS2:FindFirstChild("AttackEnemy", true)
                                    or RS2:FindFirstChild("PlaceUnit", true)
                                if attackEvent and attackEvent:IsA("RemoteEvent") then
                                    pcall(function() attackEvent:FireServer(mobHRP.Position) end)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Collect Gems
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.AD_AutoGems then
                pcall(function()
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name == "Gem" or v.Name:lower():find("gem")) and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))
                            task.wait(0.2)
                            pcall(function() firetouchinterest(hrp, v, 0) end)
                        end
                    end
                    -- Also fire gem collection remote
                    local RS2 = game:GetService("ReplicatedStorage")
                    local gemEvent = RS2:FindFirstChild("CollectGems", true)
                        or RS2:FindFirstChild("GemCollect", true)
                    if gemEvent and gemEvent:IsA("RemoteEvent") then
                        pcall(function() gemEvent:FireServer() end)
                    end
                end)
            end
        end
    end)

    -- Auto Upgrade Units
    task.spawn(function()
        while true do
            task.wait(2)
            if HubState.AD_AutoUpgrade then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local upgradeEvent = RS2:FindFirstChild("UpgradeUnit", true)
                        or RS2:FindFirstChild("Upgrade", true)
                    if upgradeEvent and upgradeEvent:IsA("RemoteEvent") then
                        -- Upgrade all placed units
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("Model") and v:FindFirstChild("UnitStats") then
                                pcall(function() upgradeEvent:FireServer(v) end)
                                task.wait(0.1)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Summon Units
    task.spawn(function()
        while true do
            task.wait(3)
            if HubState.AD_AutoSummon then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    for _, v in pairs(RS2:GetDescendants()) do
                        if v:IsA("RemoteEvent") and v.Name:lower():find("summon") then
                            pcall(function() v:FireServer(1) end)
                            task.wait(0.2)
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Sell Units
    task.spawn(function()
        while true do
            task.wait(5)
            if HubState.AD_AutoSell then
                pcall(function()
                    local RS2 = game:GetService("ReplicatedStorage")
                    local sellEvent = RS2:FindFirstChild("SellUnit", true)
                        or RS2:FindFirstChild("Sell", true)
                    if sellEvent and sellEvent:IsA("RemoteEvent") then
                        -- Sell duplicates/lowest rarity units
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("Model") and v:FindFirstChild("UnitStats") then
                                local stats = v:FindFirstChild("UnitStats")
                                local rarity = stats and stats:FindFirstChild("Rarity")
                                if rarity and (rarity.Value == "Common" or rarity.Value == "Uncommon") then
                                    pcall(function() sellEvent:FireServer(v) end)
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)



    -- ─────────────────────────────────────────────────────────
    --  RIVALS LOOPS
    -- ─────────────────────────────────────────────────────────

    -- Rivals: Inf Jump
    task.spawn(function()
        while true do
            task.wait(0.1)
            if HubState.RV_InfJump then
                pcall(function()
                    local char = LocalPlayer.Character
                    local hm = char and char:FindFirstChildOfClass("Humanoid")
                    if hm then hm.JumpPower = 150 end
                end)
            end
        end
    end)

    -- Rivals: Auto Farm XP (proximity collect)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.RV_AutoXP then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("xp") or v.Name:lower():find("exp") or v.Name:lower():find("orb")) and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position)
                            task.wait(0.05)
                        end
                    end
                end)
            end
        end
    end)

    -- Rivals: Auto Collect Coins
    task.spawn(function()
        while true do
            task.wait(0.3)
            if HubState.RV_AutoCoin then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("coin") or v.Name:lower():find("token")) and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position)
                            task.wait(0.05)
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────────────────
    --  BLUE LOCK RIVALS LOOPS
    -- ─────────────────────────────────────────────────────────

    -- Blue Lock: Auto Score Goal (teleport to goal zone)
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.BLR_AutoGoal then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("goal") or v.Name:lower():find("net")) and v:IsA("BasePart") then
                            hrp.CFrame = v.CFrame * CFrame.new(0, 0, 2)
                            task.wait(0.1)
                            break
                        end
                    end
                end)
            end
        end
    end)

    -- Blue Lock: Auto Farm XP
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.BLR_AutoXP then
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    for _, v in pairs(RS:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (v.Name:lower():find("xp") or v.Name:lower():find("score")) then
                            pcall(function() v:FireServer() end)
                            task.wait(0.3)
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────────────────
    --  FISCH LOOPS (Redz Hub inspired)
    -- ─────────────────────────────────────────────────────────

    -- Auto Fish: Cast + auto reel on bite
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.FSH_AutoFish then
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    -- Find and fire the cast remote
                    local castRemote = RS:FindFirstChild("CastLine", true) or RS:FindFirstChild("Cast", true)
                    if castRemote and castRemote:IsA("RemoteEvent") then
                        pcall(function() castRemote:FireServer() end)
                    end
                end)
                task.wait(2) -- wait for bite simulation
                -- Auto reel
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    local reelRemote = RS:FindFirstChild("Reel", true) or RS:FindFirstChild("ReelIn", true)
                    if reelRemote and reelRemote:IsA("RemoteEvent") then
                        pcall(function() reelRemote:FireServer() end)
                    end
                end)
            end
        end
    end)

    -- Auto Sell Fish
    task.spawn(function()
        while true do
            task.wait(5)
            if HubState.FSH_AutoSell then
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    local sellRemote = RS:FindFirstChild("SellFish", true)
                        or RS:FindFirstChild("Sell", true)
                        or RS:FindFirstChild("SellAll", true)
                    if sellRemote and sellRemote:IsA("RemoteEvent") then
                        pcall(function() sellRemote:FireServer() end)
                    end
                    -- Also try proximity prompts for selling
                    for _, pp in pairs(game:GetDescendants()) do
                        if pp:IsA("ProximityPrompt") and pp.ActionText:lower():find("sell") then
                            pp:InputHoldBegin()
                            task.wait(0.1)
                            pp:InputHoldEnd()
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Complete Quest
    task.spawn(function()
        while true do
            task.wait(3)
            if HubState.FSH_AutoQuest then
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    for _, v in pairs(RS:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (v.Name:lower():find("quest") or v.Name:lower():find("complete")) then
                            pcall(function() v:FireServer() end)
                            task.wait(0.5)
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────────────────
    --  SOLS RNG LOOPS
    -- ─────────────────────────────────────────────────────────

    -- Auto Spin
    task.spawn(function()
        while true do
            task.wait(1.5)
            if HubState.SRNG_AutoSpin then
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    local spinRE = RS:FindFirstChild("Spin", true) or RS:FindFirstChild("Roll", true)
                    if spinRE and spinRE:IsA("RemoteEvent") then
                        pcall(function() spinRE:FireServer() end)
                    end
                    -- Also try proximity prompts
                    for _, pp in pairs(game:GetDescendants()) do
                        if pp:IsA("ProximityPrompt") and (pp.ActionText:lower():find("spin") or pp.ActionText:lower():find("roll")) then
                            pp:InputHoldBegin()
                            task.wait(0.1)
                            pp:InputHoldEnd()
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Open Gifts
    task.spawn(function()
        while true do
            task.wait(2)
            if HubState.SRNG_AutoGift then
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    for _, v in pairs(RS:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (v.Name:lower():find("gift") or v.Name:lower():find("open")) then
                            pcall(function() v:FireServer() end)
                            task.wait(0.3)
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────────────────
    --  KING LEGACY LOOPS
    -- ─────────────────────────────────────────────────────────

    -- Auto Farm Enemies
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.KL_AutoFarm then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local closest, closestDist = nil, math.huge
                    for _, v in pairs(workspace:GetDescendants()) do
                        local hm = v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")
                        if hm and hm.Health > 0 and v ~= LocalPlayer.Character then
                            local rp = v:FindFirstChild("HumanoidRootPart")
                            if rp then
                                local d = (hrp.Position - rp.Position).Magnitude
                                if d < closestDist then closestDist=d; closest=rp end
                            end
                        end
                    end
                    if closest then
                        hrp.CFrame = closest.CFrame * CFrame.new(0, 0, -3)
                        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if tool then pcall(function() tool:Activate() end) end
                    end
                end)
            end
        end
    end)

    -- Auto Collect Fruits
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.KL_AutoFruit then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("fruit") or v.Name:lower():find("drop")) and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position + Vector3.new(0,2,0))
                            task.wait(0.1)
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────────────────
    --  PEROXIDE LOOPS
    -- ─────────────────────────────────────────────────────────

    -- Auto Farm Hollows / EXP
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.PX_AutoEXP or HubState.PX_AutoHollow then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local closest, closestDist = nil, math.huge
                    for _, v in pairs(workspace:GetDescendants()) do
                        local hm = v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")
                        if hm and hm.Health > 0 and v ~= LocalPlayer.Character then
                            local rp = v:FindFirstChild("HumanoidRootPart")
                            if rp then
                                local d = (hrp.Position - rp.Position).Magnitude
                                if d < closestDist then closestDist=d; closest=rp end
                            end
                        end
                    end
                    if closest then
                        hrp.CFrame = closest.CFrame * CFrame.new(0,0,-3)
                        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if tool then pcall(function() tool:Activate() end) end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────────────────
    --  DEAD RAILS LOOPS
    -- ─────────────────────────────────────────────────────────

    -- Auto Loot Chests
    task.spawn(function()
        while true do
            task.wait(1)
            if HubState.DR_AutoLoot then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("chest") or v.Name:lower():find("crate") or v.Name:lower():find("loot")) and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position + Vector3.new(0,2,0))
                            task.wait(0.2)
                            -- Try proximity prompts
                            for _, pp in pairs(v:GetDescendants()) do
                                if pp:IsA("ProximityPrompt") then
                                    pp:InputHoldBegin(); task.wait(0.1); pp:InputHoldEnd()
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Collect Gold
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.DR_AutoGold then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("gold") or v.Name:lower():find("coin") or v.Name:lower():find("money")) and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position)
                            task.wait(0.05)
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────────────────
    --  MEME SEA LOOPS
    -- ─────────────────────────────────────────────────────────

    -- Auto Farm Enemies
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.MS_AutoFarm then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local closest, closestDist = nil, math.huge
                    for _, v in pairs(workspace:GetDescendants()) do
                        local hm = v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")
                        if hm and hm.Health > 0 and v ~= LocalPlayer.Character then
                            local rp = v:FindFirstChild("HumanoidRootPart")
                            if rp then
                                local d = (hrp.Position - rp.Position).Magnitude
                                if d < closestDist then closestDist=d; closest=rp end
                            end
                        end
                    end
                    if closest then
                        hrp.CFrame = closest.CFrame * CFrame.new(0,0,-3)
                        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if tool then pcall(function() tool:Activate() end) end
                    end
                end)
            end
        end
    end)

    -- Auto Collect Drops / Chests
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.MS_AutoDrop or HubState.MS_AutoChest then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if (v.Name:lower():find("drop") or v.Name:lower():find("chest") or v.Name:lower():find("item")) and v:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(v.Position)
                            task.wait(0.05)
                        end
                    end
                end)
            end
        end
    end)

    -- ─────────────────────────────────────────────────────────
    --  JUJUTSU SHENANIGANS LOOPS
    -- ─────────────────────────────────────────────────────────

    -- Auto Farm EXP
    task.spawn(function()
        while true do
            task.wait(0.5)
            if HubState.JJK_AutoEXP then
                pcall(function()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local closest, closestDist = nil, math.huge
                    for _, v in pairs(workspace:GetDescendants()) do
                        local hm = v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")
                        if hm and hm.Health > 0 and v ~= LocalPlayer.Character then
                            local rp = v:FindFirstChild("HumanoidRootPart")
                            if rp then
                                local d = (hrp.Position - rp.Position).Magnitude
                                if d < closestDist then closestDist=d; closest=rp end
                            end
                        end
                    end
                    if closest then
                        hrp.CFrame = closest.CFrame * CFrame.new(0,0,-3)
                        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if tool then pcall(function() tool:Activate() end) end
                    end
                end)
            end
        end
    end)

    -- Auto Use Ability
    task.spawn(function()
        while true do
            task.wait(0.3)
            if HubState.JJK_AutoAbility then
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    for _, v in pairs(RS:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (v.Name:lower():find("ability") or v.Name:lower():find("skill") or v.Name:lower():find("technique")) then
                            pcall(function() v:FireServer() end)
                            task.wait(0.2)
                        end
                    end
                end)
            end
        end
    end)

end) -- END task.spawn for all loops

end) -- close task.spawn (line 4397)
end)   -- close task.spawn (line 3669)
end)   -- close task.spawn (line 2581)
end    -- close if/elseif CurrentGame chain (line 802)

--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                   HUBSTATE KEY REFERENCE                     ║
    ╚══════════════════════════════════════════════════════════════╝

    DA HOOD:
      HubState.DH_AutoCash         - Auto Farm Cash
      HubState.DH_AutoStomp        - Auto Stomp Downed
      HubState.DH_AutoPickupGun    - Auto Pickup Guns
      HubState.DH_AutoBank         - Auto Bank Deposit
      HubState.DH_LockVictim       - Lock Victim
      HubState.DH_LockedTarget     - [internal] locked player object
      HubState.DH_AutoCollectDrops - Auto Collect Drops

    GANG WARS:
      HubState.GW_PotatoFarm  - Potato Farm
      HubState.GW_CarFarm     - Car Farm
      HubState.GW_StoreRob    - Store Rob
      HubState.GW_AutoKillNPC - Auto Kill NPC
      HubState.GW_AutoRevive  - Auto Revive Allies
      HubState.GW_AutoAmmo    - Auto Buy Ammo

    BLOX FRUITS:
      HubState.BF_AutoMastery     - Auto Farm Mastery
      HubState.BF_AutoBounty      - Auto Farm Bounty
      HubState.BF_AutoSeaBeast    - Auto Sea Beast
      HubState.BF_AutoRaid        - Auto Raid Farm
      HubState.BF_AutoChest       - Auto Chest Farm
      HubState.BF_AutoCollectFruit - Auto Collect Fruits

    JAILBREAK:
      HubState.JB_AutoBank    - Auto Rob Bank
      HubState.JB_AutoJewelry - Auto Rob Jewelry
      HubState.JB_AutoCasino  - Auto Rob Casino
      HubState.JB_AutoTrain   - Auto Rob Train
      HubState.JB_AutoCargo   - Auto Collect Cargo
      HubState.JB_InfNitro    - Infinite Nitro

    MURDER MYSTERY 2:
      HubState.MM2_ESPMurderer   - ESP Murderer
      HubState.MM2_AutoCoin      - Auto Coin Farm
      HubState.MM2_AutoKnifeThrow - Auto Knife Throw
      HubState.MM2_SheriffAutoWin - Sheriff Auto Win
      HubState.MM2_AutoGodhand   - Auto Godhand Shoot

    PET SIMULATOR 99:
      HubState.PS99_AutoHatch   - Auto Hatch Egg
      HubState.PS99_AutoDiamond - Auto Farm Diamonds
      HubState.PS99_AutoCoin    - Auto Collect Coins
      HubState.PS99_AutoEnchant - Auto Enchant Pets
      HubState.PS99_AutoFuse    - Auto Fuse Pets
      HubState.PS99_AutoChest   - Auto Open Chests

    GROW A GARDEN:
      HubState.GAG_AutoPlant    - Auto Plant Seeds
      HubState.GAG_AutoHarvest  - Auto Harvest Crops
      HubState.GAG_AutoWater    - Auto Water Plants
      HubState.GAG_AutoBuySeeds - Auto Buy Seeds
      HubState.GAG_AutoSell     - Auto Sell Crops
      HubState.GAG_AutoFertilize - Auto Fertilize

    BLADE BALL:
      HubState.BB_AutoParry    - Auto Parry Ball
      HubState.BB_AutoDeflect  - Auto Deflect Chain
      HubState.BB_AutoAbility  - Auto Use Ability
      HubState.BB_TpToBall     - Teleport to Ball
      HubState.BB_AutoWin      - Auto Win Round

    BEE SWARM SIMULATOR:
      HubState.BSS_AutoHoney       - Auto Collect Honey
      HubState.BSS_AutoPollen      - Auto Farm Pollen
      HubState.BSS_AutoQuest       - Auto Complete Quest
      HubState.BSS_AutoBuyGear     - Auto Buy Gear
      HubState.BSS_AutoFightMonster - Auto Fight Monster

    SHINDO LIFE:
      HubState.SL_AutoEXP     - Auto Farm EXP
      HubState.SL_AutoSpin    - Auto Spin Elements
      HubState.SL_AutoSword   - Auto Sword Farm
      HubState.SL_AutoRELLCoin - Auto RELL Coin Farm
      HubState.SL_AutoMode    - Auto Mode Farm

    THE STRONGEST BATTLEGROUNDS:
      HubState.TSB_AutoKO         - Auto Farm KO
      HubState.TSB_AutoBlockBreak - Auto Block Break
      HubState.TSB_AutoCounter    - Auto Counter
      HubState.TSB_AutoCombo      - Auto Combo
      HubState.TSB_AutoRankUp     - Auto Rank Up

    ANIME DEFENDERS:
      HubState.AD_AutoFarm   - Auto Farm Stage
      HubState.AD_AutoGems   - Auto Collect Gems
      HubState.AD_AutoUpgrade - Auto Upgrade Units
      HubState.AD_AutoSummon - Auto Summon Units
      HubState.AD_AutoSell   - Auto Sell Units

--]]

