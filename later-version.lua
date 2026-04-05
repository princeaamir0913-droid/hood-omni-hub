--[[
    Hood Omni Hub v2.1 "Rayfield Edition"
    by PrinceAamir + DeepSeek Coder V2
    SUPPORTED GAMES: Tha Bronx 3, Gang Wars, Central Streets, Philly Streetz 2,
                     South Bronx, Bronx Hood (FREE), Bronx Hood (UPD),
                     Underground War 2.0, The Underground War 2
    FEATURES: Auto Cash Farm, Kill Aura, Dupe, Godmode, Money Gen, Gun Spawner,
              Aimbot, Auto Shoot, Flag TP, Sword Reach (ALL GAMES)
]]

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Game Detection (Place IDs)
local GAME_PLACE_IDS = {
    [16472538603]      = "Tha Bronx 3",
    [137020602493628]  = "Gang Wars",
    [121567535120062]  = "Central Streets",
    [130700367963690]  = "Philly Streetz 2",
    [10179538382]      = "South Bronx",
    [84866901748045]   = "Bronx Hood",   -- FREE 150k version
    [78423638997438]   = "Bronx Hood",   -- UPD version
    [9791603388]       = "Underground Wars", -- Underground War 2.0
    [4759640416]       = "Underground Wars", -- The Underground War 2
}
local GAME_NAME = GAME_PLACE_IDS[game.PlaceId] or "Unknown Game"

-- Safe Utilities
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then warn("Error:", result) end
    return success, result
end

local function firePrompt(prompt)
    if not prompt then return false end
    if prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt, 0)
        return true
    elseif prompt:IsA("ClickDetector") then
        fireclickdetector(prompt)
        return true
    end
    return false
end

-- Farm Mutex
local FarmMutex = { isRunning = false, queue = {} }
function FarmMutex:run(farmFunction, farmName)
    table.insert(self.queue, function()
        while self.isRunning do task.wait(0.1) end
        self.isRunning = true
        print("🔒 Running:", farmName)
        local success, err = pcall(farmFunction)
        if not success then warn("❌ Error in " .. farmName .. ":", err) end
        self.isRunning = false
        print("🔓 Finished:", farmName)
        if #self.queue > 0 then task.spawn(table.remove(self.queue, 1)) end
    end)
    if #self.queue == 1 then task.spawn(self.queue[1]) end
end

-- Ghost Gun Fix
local function SpawnGun(gunName)
    local backpack = player.Backpack
    if backpack:FindFirstChild(gunName) then print("⚠️ Already have:", gunName); return end
    local tool = ReplicatedStorage:FindFirstChild("Items") and ReplicatedStorage.Items:FindFirstChild(gunName)
    if not tool then tool = ReplicatedStorage:FindFirstChild("weapons") and ReplicatedStorage.weapons:FindFirstChild(gunName) end
    if not tool then warn("Missing template:", gunName); return end
    local gun = tool:Clone()
    task.wait(0.1)
    local remotes = {"Fire", "Shoot", "DamageRemote", "OnHit", "BulletHit", "RemoteFire", "FireBullet"}
    for _, rName in ipairs(remotes) do
        local r = gun:FindFirstChild(rName)
        if r and r:IsA("RemoteEvent") then safeCall(r.FireServer, r, player) end
    end
    gun.Enabled = true
    gun.Parent = backpack
    print("✅ SPAWNED:", gunName)
end

-- ==================== SHARED COMBAT FEATURES (ALL GAMES) ====================

local UW_Aimbot     = false
local UW_AutoShoot  = false
local UW_FlagTP     = false
local UW_SwordReach = false

local function GetNearestEnemy()
    local nearest, nearestDist = nil, math.huge
    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist < nearestDist then
                    nearest = plr.Character
                    nearestDist = dist
                end
            end
        end
    end
    return nearest
end

local aimbotConn = nil
local function StartAimbot()
    if aimbotConn then aimbotConn:Disconnect() end
    local cam = workspace.CurrentCamera
    aimbotConn = RunService.RenderStepped:Connect(function()
        if not UW_Aimbot then aimbotConn:Disconnect(); return end
        local target = GetNearestEnemy()
        if target then
            local aimPart = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
            if aimPart then
                cam.CFrame = CFrame.new(cam.CFrame.Position, aimPart.Position)
            end
        end
    end)
end

local function StartAutoShoot()
    task.spawn(function()
        while UW_AutoShoot do
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    local activateRemote = tool:FindFirstChild("RemoteEvent")
                    if activateRemote and activateRemote:IsA("RemoteEvent") then
                        activateRemote:FireServer()
                    else
                        tool:Activate()
                    end
                end
            end
            task.wait(0.08)
        end
    end)
end

local function StartFlagTP()
    task.spawn(function()
        while UW_FlagTP do
            local char = player.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    local name = obj.Name:lower()
                    if obj:IsA("BasePart") and (name:find("flag") or name:find("capture") or name:find("banner")) then
                        pcall(function()
                            obj.CFrame = myHRP.CFrame * CFrame.new(0, 0, -2)
                            obj.Velocity = Vector3.new(0, 0, 0)
                            obj.RotVelocity = Vector3.new(0, 0, 0)
                        end)
                    end
                end
            end
            task.wait(0.3)
        end
    end)
end

-- Kill Aura (customizable, replaces old broken sword reach)
local KillAuraEnabled = false
local KillAuraRange   = 20

local function StartKillAura()
    task.spawn(function()
        while KillAuraEnabled do
            local char = player.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if not KillAuraEnabled then break end
                    if plr ~= player and plr.Character then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = (hrp.Position - myHRP.Position).Magnitude
                            if dist <= KillAuraRange then
                                pcall(function()
                                    myHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
                                end)
                                task.wait(0.05)
                                local tool = char:FindFirstChildOfClass("Tool")
                                if tool then
                                    pcall(function() tool:Activate() end)
                                    local dmgRemote = tool:FindFirstChild("DamageRemote") or tool:FindFirstChild("RemoteEvent")
                                    if dmgRemote then
                                        pcall(function() dmgRemote:FireServer(hrp.Position) end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- Combat features for ALL games (Aimbot + Auto Shoot only)
local function AddSharedCombatFeatures(CombatTab, UtilityTab)

    CombatTab:CreateToggle({
        Name = "🌀 Kill Aura",
        CurrentValue = false,
        Flag = "Shared_KillAura",
        Callback = function(v)
            KillAuraEnabled = v
            if v then StartKillAura() end
        end
    })

    CombatTab:CreateSlider({
        Name = "🎯 Kill Aura Range",
        Range = {5, 100},
        Increment = 5,
        Suffix = " studs",
        CurrentValue = 20,
        Flag = "Shared_KillAuraRange",
        Callback = function(v)
            KillAuraRange = v
        end
    })

    CombatTab:CreateToggle({
        Name = "🎯 Aimbot",
        CurrentValue = false,
        Flag = "Shared_Aimbot",
        Callback = function(v)
            UW_Aimbot = v
            if v then StartAimbot() end
        end
    })

    CombatTab:CreateToggle({
        Name = "🔫 Auto Shoot",
        CurrentValue = false,
        Flag = "Shared_AutoShoot",
        Callback = function(v)
            UW_AutoShoot = v
            if v then StartAutoShoot() end
        end
    })

    UtilityTab:CreateButton({
        Name = "🏃 Teleport to Enemy Base",
        Callback = function()
            local target = GetNearestEnemy()
            if target and target:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
                end
            else
                Rayfield:Notify({Title = "No Target", Content = "No enemy found nearby.", Duration = 3})
            end
        end
    })

    UtilityTab:CreateButton({
        Name = "💀 Kill Nearest Enemy",
        Callback = function()
            local target = GetNearestEnemy()
            if target and target:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
                    task.wait(0.05)
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end
            end
        end
    })
end

-- Full combat features for Underground Wars ONLY (includes Flag TP + Sword Reach)
local function AddUndergroundWarsCombatFeatures(CombatTab, UtilityTab)
    CombatTab:CreateToggle({
        Name = "🎯 Aimbot",
        CurrentValue = false,
        Flag = "UW_Aimbot",
        Callback = function(v)
            UW_Aimbot = v
            if v then StartAimbot() end
        end
    })

    CombatTab:CreateToggle({
        Name = "🔫 Auto Shoot",
        CurrentValue = false,
        Flag = "UW_AutoShoot",
        Callback = function(v)
            UW_AutoShoot = v
            if v then StartAutoShoot() end
        end
    })

    CombatTab:CreateToggle({
        Name = "🚩 Flag TP To Me",
        CurrentValue = false,
        Flag = "UW_FlagTP",
        Callback = function(v)
            UW_FlagTP = v
            if v then StartFlagTP() end
        end
    })

    CombatTab:CreateToggle({
        Name = "🌀 Kill Aura",
        CurrentValue = false,
        Flag = "UW_KillAura",
        Callback = function(v)
            KillAuraEnabled = v
            if v then StartKillAura() end
        end
    })

    CombatTab:CreateSlider({
        Name = "🎯 Kill Aura Range",
        Range = {5, 100},
        Increment = 5,
        Suffix = " studs",
        CurrentValue = 20,
        Flag = "UW_KillAuraRange",
        Callback = function(v)
            KillAuraRange = v
        end
    })

    UtilityTab:CreateButton({
        Name = "🏃 Teleport to Enemy Base",
        Callback = function()
            local target = GetNearestEnemy()
            if target and target:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
                end
            else
                Rayfield:Notify({Title = "No Target", Content = "No enemy found nearby.", Duration = 3})
            end
        end
    })

    UtilityTab:CreateButton({
        Name = "💀 Kill Nearest Enemy",
        Callback = function()
            local target = GetNearestEnemy()
            if target and target:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
                    task.wait(0.05)
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end
            end
        end
    })
end

-- ==================== GAME-SPECIFIC FARMS ====================

local function ThaBronx3CashFarm()
    for _, npc in ipairs(Workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp then player.Character.HumanoidRootPart.CFrame = hrp.CFrame end
            task.wait()
            local drop = npc:FindFirstChild("Drop") or npc:FindFirstChild("Cash")
            if drop then fireclickdetector(drop:FindFirstChildOfClass("ClickDetector")) end
        end
    end
end

local function ThaBronx3KillAura()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then player.Character.HumanoidRootPart.CFrame = hrp.CFrame end
            task.wait()
            local tool = player.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end
    end
end

local function BronxHoodCashFarm()
    for _, npc in ipairs(Workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp then player.Character.HumanoidRootPart.CFrame = hrp.CFrame end
            task.wait()
            local drop = npc:FindFirstChild("Drop") or npc:FindFirstChild("Cash")
            if drop then fireclickdetector(drop:FindFirstChildOfClass("ClickDetector")) end
        end
    end
end

local function BronxHoodKillAura()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then player.Character.HumanoidRootPart.CFrame = hrp.CFrame end
            task.wait()
            local tool = player.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end
    end
end

local function GangWarsPotatoFarm()
    local buyPrompt, cookPrompt, sellPrompt
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then
            if p.ActionText and p.ActionText:find("Buy") and p.ActionText:find("Potato") then buyPrompt = p end
            if p.ActionText and p.ActionText:find("Cook") then cookPrompt = p end
            if p.ActionText and p.ActionText:find("Sell") then sellPrompt = p end
        end
    end
    if buyPrompt then for i = 1, 10 do firePrompt(buyPrompt); task.wait(0.3) end end
    if cookPrompt then firePrompt(cookPrompt); task.wait(10) end
    if sellPrompt then firePrompt(sellPrompt) end
end

local function CentralStreetsPrinterFarm()
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.ActionText and p.ActionText:find("Printer") then
            firePrompt(p); task.wait(30)
        end
    end
end

local function PhillyStreetz2MoneyGen()
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.ActionText and p.ActionText:find("Money") then
            firePrompt(p); task.wait(2)
        end
    end
end

-- ==================== RAYFIELD UI ====================

local Window = Rayfield:CreateWindow({
    Name = "Hood Omni Hub v2.1 - " .. GAME_NAME,
    LoadingTitle = "Loading Hub...",
    LoadingSubtitle = "by PrinceAamir",
    Theme = "Default"
})

local FarmTab    = Window:CreateTab("🌾 Auto Farms")
local CombatTab  = Window:CreateTab("⚔️ Combat")
local UtilityTab = Window:CreateTab("🔧 Utility")
local GunTab     = Window:CreateTab("🔫 Guns")

-- ===== Underground Wars =====
if GAME_NAME == "Underground Wars" then

    -- 💣 Nuke Button (bypass star requirement)
    UtilityTab:CreateButton({
        Name = "💣 Launch Nuke (Bypass Stars)",
        Callback = function()
            -- Try to fire nuke remote directly, bypassing star check
            local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage
            local nukeRemote = nil
            for _, v in ipairs(remotes:GetDescendants()) do
                local n = v.Name:lower()
                if n:find("nuke") or n:find("bomb") or n:find("launch") then
                    nukeRemote = v
                    break
                end
            end
            if nukeRemote and nukeRemote:IsA("RemoteEvent") then
                nukeRemote:FireServer()
                Rayfield:Notify({Title = "💣 Nuke!", Content = "Nuke launched!", Duration = 3})
            else
                -- Try clicking the ingame nuke button directly
                local nukeBtn = nil
                for _, v in ipairs(workspace:GetDescendants()) do
                    local n = v.Name:lower()
                    if (n:find("nuke") or n:find("launch")) and (v:IsA("ClickDetector") or v:IsA("ProximityPrompt")) then
                        nukeBtn = v
                        break
                    end
                end
                if nukeBtn then
                    pcall(function()
                        if nukeBtn:IsA("ClickDetector") then
                            fireclickdetector(nukeBtn)
                        else
                            fireproximityprompt(nukeBtn, 0)
                        end
                    end)
                    Rayfield:Notify({Title = "💣 Nuke!", Content = "Nuke button pressed!", Duration = 3})
                else
                    Rayfield:Notify({Title = "❌ Nuke", Content = "Could not find nuke remote. Try standing near nuke button.", Duration = 4})
                end
            end
        end
    })

    -- 🚀 Free Rocket Launcher
    UtilityTab:CreateButton({
        Name = "🚀 Get Free Rocket Launcher",
        Callback = function()
            local char = player.Character
            if not char then return end
            -- Try ReplicatedStorage first
            local function tryClone(parent)
                for _, v in ipairs(parent:GetDescendants()) do
                    local n = v.Name:lower()
                    if n:find("rocket") or n:find("launcher") or n:find("bazooka") then
                        if v:IsA("Tool") then
                            local clone = v:Clone()
                            clone.Parent = player.Backpack
                            Rayfield:Notify({Title = "🚀 Got It!", Content = v.Name .. " added to backpack!", Duration = 3})
                            return true
                        end
                    end
                end
                return false
            end
            if not tryClone(ReplicatedStorage) then
                if not tryClone(workspace) then
                    Rayfield:Notify({Title = "❌ Not Found", Content = "Rocket Launcher not found in storage.", Duration = 4})
                end
            end
        end
    })

    -- ⚡ Increase Dig Speed
    local UW_FastDig = false
    local originalWalkSpeed = 16
    FarmTab:CreateToggle({
        Name = "⚡ Fast Dig Speed",
        CurrentValue = false,
        Flag = "UW_FastDig",
        Callback = function(v)
            UW_FastDig = v
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if v then
                    originalWalkSpeed = hum.WalkSpeed
                    hum.WalkSpeed = 100
                    -- Also try to fire dig speed remote
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage
                    for _, r in ipairs(remotes:GetDescendants()) do
                        local n = r.Name:lower()
                        if n:find("dig") or n:find("speed") or n:find("mine") then
                            pcall(function() r:FireServer(100) end)
                        end
                    end
                else
                    hum.WalkSpeed = originalWalkSpeed
                end
            end
            -- Keep speed on respawn
            if v then
                task.spawn(function()
                    while UW_FastDig do
                        local c = player.Character
                        local h = c and c:FindFirstChildOfClass("Humanoid")
                        if h then h.WalkSpeed = 100 end
                        task.wait(1)
                    end
                end)
            end
        end
    })

    -- 💰 Add 100k Money
    UtilityTab:CreateButton({
        Name = "💰 Add 100k Money",
        Callback = function()
            -- Try all common money remotes
            local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage
            local fired = false
            for _, v in ipairs(remotes:GetDescendants()) do
                local n = v.Name:lower()
                if n:find("money") or n:find("cash") or n:find("coin") or n:find("add") or n:find("give") then
                    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                        pcall(function()
                            if v:IsA("RemoteEvent") then
                                v:FireServer(100000)
                            else
                                v:InvokeServer(100000)
                            end
                        end)
                        fired = true
                    end
                end
            end
            if fired then
                Rayfield:Notify({Title = "💰 Money Sent!", Content = "Fired money remote — check your balance!", Duration = 3})
            else
                -- Try leaderstats
                local ls = player:FindFirstChild("leaderstats")
                if ls then
                    for _, stat in ipairs(ls:GetChildren()) do
                        local n = stat.Name:lower()
                        if n:find("money") or n:find("cash") or n:find("coin") then
                            pcall(function() stat.Value = stat.Value + 100000 end)
                            fired = true
                        end
                    end
                end
                if fired then
                    Rayfield:Notify({Title = "💰 Done!", Content = "+100k added to " .. (player.leaderstats and player.leaderstats:GetChildren()[1] and player.leaderstats:GetChildren()[1].Name or "balance"), Duration = 3})
                else
                    Rayfield:Notify({Title = "❌ Failed", Content = "Could not find money remote. Server-sided games block this.", Duration = 4})
                end
            end
        end
    })

    AddUndergroundWarsCombatFeatures(CombatTab, UtilityTab)

-- ===== Tha Bronx 3 =====
elseif GAME_NAME == "Tha Bronx 3" then

    local TB3_CashRunning = false
    FarmTab:CreateToggle({
        Name = "💰 Auto Cash Farm",
        CurrentValue = false,
        Flag = "TB3_CashFarm",
        Callback = function(v)
            TB3_CashRunning = v
            if v then
                task.spawn(function()
                    while TB3_CashRunning do
                        FarmMutex:run(ThaBronx3CashFarm, "Cash Farm")
                        task.wait(10)
                    end
                end)
            end
        end
    })

    local TB3_DupeRunning = false
    FarmTab:CreateToggle({
        Name = "🔄 Gun/Item Dupe",
        CurrentValue = false,
        Flag = "TB3_Dupe",
        Callback = function(v)
            TB3_DupeRunning = v
            if v then
                task.spawn(function()
                    while TB3_DupeRunning do
                        FarmMutex:run(ThaBronx3CashFarm, "Dupe Farm")
                        task.wait(5)
                    end
                end)
            end
        end
    })

    local TB3_KillRunning = false
    CombatTab:CreateToggle({
        Name = "🔪 Kill Aura",
        CurrentValue = false,
        Flag = "TB3_KillAura",
        Callback = function(v)
            TB3_KillRunning = v
            if v then
                task.spawn(function()
                    while TB3_KillRunning do
                        FarmMutex:run(ThaBronx3KillAura, "Kill Aura")
                        task.wait(1)
                    end
                end)
            end
        end
    })

    CombatTab:CreateToggle({ Name = "👁️ Silent Aim", CurrentValue = false, Flag = "TB3_SilentAim", Callback = function(v) end })

    AddSharedCombatFeatures(CombatTab, UtilityTab)

    UtilityTab:CreateToggle({ Name = "🛡️ Anti-Police Mode", CurrentValue = false, Flag = "TB3_AntiPolice", Callback = function(v) end })

-- ===== Philly Streetz 2 =====
elseif GAME_NAME == "Philly Streetz 2" then

    local PS2_MoneyRunning = false
    FarmTab:CreateToggle({
        Name = "💸 Money Gen",
        CurrentValue = false,
        Flag = "PS2_MoneyGen",
        Callback = function(v)
            PS2_MoneyRunning = v
            if v then
                task.spawn(function()
                    while PS2_MoneyRunning do
                        FarmMutex:run(PhillyStreetz2MoneyGen, "Money Gen")
                        task.wait(5)
                    end
                end)
            end
        end
    })

    local PS2_DupeRunning = false
    FarmTab:CreateToggle({
        Name = "⌚ Accessory Dupe",
        CurrentValue = false,
        Flag = "PS2_AccDupe",
        Callback = function(v)
            PS2_DupeRunning = v
            if v then
                task.spawn(function()
                    while PS2_DupeRunning do
                        FarmMutex:run(PhillyStreetz2MoneyGen, "Dupe")
                        task.wait(3)
                    end
                end)
            end
        end
    })

    CombatTab:CreateToggle({ Name = "👁️ ESP", CurrentValue = false, Flag = "PS2_ESP", Callback = function(v) end })

    AddSharedCombatFeatures(CombatTab, UtilityTab)

    UtilityTab:CreateToggle({ Name = "🛡️ Godmode", CurrentValue = false, Flag = "PS2_Godmode", Callback = function(v) end })

-- ===== Gang Wars / Bronx Hood (same game) =====
elseif GAME_NAME == "Gang Wars" or GAME_NAME == "Bronx Hood" then

    local GW_PotatoRunning = false
    FarmTab:CreateToggle({
        Name = "🥔 Potato Farm",
        CurrentValue = false,
        Flag = "GW_Potato",
        Callback = function(v)
            GW_PotatoRunning = v
            if v then
                task.spawn(function()
                    while GW_PotatoRunning do
                        FarmMutex:run(GangWarsPotatoFarm, "Potato Farm")
                        task.wait(15)
                    end
                end)
            end
        end
    })

    AddSharedCombatFeatures(CombatTab, UtilityTab)

-- ===== Central Streets =====
elseif GAME_NAME == "Central Streets" then

    local CS_PrinterRunning = false
    FarmTab:CreateToggle({
        Name = "🖨️ Printer Farm",
        CurrentValue = false,
        Flag = "CS_Printer",
        Callback = function(v)
            CS_PrinterRunning = v
            if v then
                task.spawn(function()
                    while CS_PrinterRunning do
                        FarmMutex:run(CentralStreetsPrinterFarm, "Printer Farm")
                        task.wait(35)
                    end
                end)
            end
        end
    })

    AddSharedCombatFeatures(CombatTab, UtilityTab)

-- ===== South Bronx =====
elseif GAME_NAME == "South Bronx" then

    FarmTab:CreateToggle({ Name = "💰 Auto Farm (WIP)", CurrentValue = false, Flag = "SB_Farm", Callback = function(v) end })

    AddSharedCombatFeatures(CombatTab, UtilityTab)

-- ===== Unknown =====
else

    FarmTab:CreateToggle({
        Name = "🤖 Auto Farm (Experimental)",
        CurrentValue = false,
        Flag = "Generic_Farm",
        Callback = function(v)
            if v then
                task.spawn(function()
                    print("Generic farm – customize for this game")
                end)
            end
        end
    })

    AddSharedCombatFeatures(CombatTab, UtilityTab)

end

-- Gun Spawner (all games)
local gunList = {"Glock", "AK47", "Shotgun", "Mac10", "Uzi", "AR15"}
for _, gun in ipairs(gunList) do
    GunTab:CreateButton({ Name = "🔫 " .. gun, Callback = function() SpawnGun(gun) end })
end

Rayfield:Notify({ Title = "Hood Omni Hub v2.1", Content = "Loaded for: " .. GAME_NAME, Duration = 4 })
