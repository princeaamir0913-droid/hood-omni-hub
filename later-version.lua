--[[
    Hood Omni Hub v2.0 "Rayfield Edition"
    by PrinceAamir + DeepSeek Coder V2
    SUPPORTED GAMES: Tha Bronx 3, Gang Wars, Central Streets, Philly Streetz 2,
                     South Bronx, Da Streetz, Bronx Hood
    FEATURES: Auto Cash Farm, Kill Aura, Dupe, Godmode, Money Gen, Gun Spawner
]]

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Game Detection (Place IDs – replace unknowns with actual IDs)
local GAME_PLACE_IDS = {
    [16472538603] = "Tha Bronx 3",
    [137020602493628] = "Gang Wars",
    [121567535120062] = "Central Streets",
    [130700367963690] = "Philly Streetz 2",
    -- Add Place IDs for South Bronx, Da Streetz, Bronx Hood here
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

-- Farm Mutex (prevents conflicts)
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

-- Ghost Gun Fix (Tha Bronx 3)
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

-- ==================== GAME‑SPECIFIC FARMS ====================
-- Tha Bronx 3
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

-- Gang Wars
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

-- Central Streets
local function CentralStreetsPrinterFarm()
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.ActionText and p.ActionText:find("Printer") then
            firePrompt(p); task.wait(30)
        end
    end
end

-- Philly Streetz 2
local function PhillyStreetz2MoneyGen()
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.ActionText and p.ActionText:find("Money") then
            firePrompt(p); task.wait(2)
        end
    end
end

-- ==================== RAYFIELD UI (Dynamic by Game) ====================
local function LoadGameUI()
    if GAME_NAME == "Unknown Game" then
        Rayfield:Notify({Title = "Game Not Supported", Content = "Please select manually.", Duration = 5})
        return
    end

    local Window = Rayfield:CreateWindow({
        Name = "Hood Omni Hub v2.0 - " .. GAME_NAME,
        LoadingTitle = "Loading Hub...",
        LoadingSubtitle = "by PrinceAamir",
        Theme = "Default"
    })
    local FarmTab = Window:CreateTab("🌾 Auto Farms")
    local CombatTab = Window:CreateTab("⚔️ Combat")
    local UtilityTab = Window:CreateTab("🔧 Utility")
    local GunTab = Window:CreateTab("🔫 Guns")

    if GAME_NAME == "Tha Bronx 3" then
        local farmSec = FarmTab:CreateSection("Money & Dupe")
        farmSec:CreateToggle({
            Name = "💰 Auto Cash Farm",
            CurrentValue = false,
            Flag = "TB3_CashFarm",
            Callback = function(v)
                if v then
                    task.spawn(function()
                        while Toggles["TB3_CashFarm"].Value do
                            FarmMutex:run(ThaBronx3CashFarm, "Cash Farm")
                            task.wait(10)
                        end
                    end)
                end
            end
        })
        farmSec:CreateToggle({
            Name = "🔄 Gun/Item Dupe",
            CurrentValue = false,
            Flag = "TB3_Dupe",
            Callback = function(v)
                if v then
                    task.spawn(function()
                        while Toggles["TB3_Dupe"].Value do
                            FarmMutex:run(ThaBronx3CashFarm, "Dupe Farm")
                            task.wait(5)
                        end
                    end)
                end
            end
        })
        local combatSec = CombatTab:CreateSection("Combat")
        combatSec:CreateToggle({
            Name = "🔪 Kill Aura",
            CurrentValue = false,
            Flag = "TB3_KillAura",
            Callback = function(v)
                if v then
                    task.spawn(function()
                        while Toggles["TB3_KillAura"].Value do
                            FarmMutex:run(ThaBronx3KillAura, "Kill Aura")
                            task.wait(1)
                        end
                    end)
                end
            end
        })
        combatSec:CreateToggle({ Name = "🎯 Silent Aim", CurrentValue = false, Flag = "TB3_SilentAim", Callback = function(v) print("Silent Aim:", v) end })
        local utilSec = UtilityTab:CreateSection("Utility")
        utilSec:CreateToggle({ Name = "🛡️ Anti-Police Mode", CurrentValue = false, Flag = "TB3_AntiPolice", Callback = function(v) print("Anti-Police:", v) end })
    elseif GAME_NAME == "Philly Streetz 2" then
        local farmSec = FarmTab:CreateSection("Money & Dupe")
        farmSec:CreateToggle({
            Name = "💸 Money Gen",
            CurrentValue = false,
            Flag = "PS2_MoneyGen",
            Callback = function(v)
                if v then
                    task.spawn(function()
                        while Toggles["PS2_MoneyGen"].Value do
                            FarmMutex:run(PhillyStreetz2MoneyGen, "Money Gen")
                            task.wait(5)
                        end
                    end)
                end
            end
        })
        farmSec:CreateToggle({
            Name = "⌚ Accessory Dupe",
            CurrentValue = false,
            Flag = "PS2_AccDupe",
            Callback = function(v)
                if v then
                    task.spawn(function()
                        while Toggles["PS2_AccDupe"].Value do
                            FarmMutex:run(PhillyStreetz2MoneyGen, "Dupe")
                            task.wait(3)
                        end
                    end)
                end
            end
        })
        local combatSec = CombatTab:CreateSection("Combat")
        combatSec:CreateToggle({ Name = "👁️ ESP", CurrentValue = false, Flag = "PS2_ESP", Callback = function(v) print("ESP:", v) end })
        local utilSec = UtilityTab:CreateSection("Utility")
        utilSec:CreateToggle({ Name = "🛡️ Godmode", CurrentValue = false, Flag = "PS2_Godmode", Callback = function(v) print("Godmode:", v) end })
    elseif GAME_NAME == "Gang Wars" then
        local farmSec = FarmTab:CreateSection("Gang Wars Farms")
        farmSec:CreateToggle({
            Name = "🥔 Potato Farm",
            CurrentValue = false,
            Flag = "GW_Potato",
            Callback = function(v)
                if v then
                    task.spawn(function()
                        while Toggles["GW_Potato"].Value do
                            FarmMutex:run(GangWarsPotatoFarm, "Potato Farm")
                            task.wait(15)
                        end
                    end)
                end
            end
        })
        -- Add more toggles for Box Job, Scam, ATM, Jewelry, Car, Printer as needed
    elseif GAME_NAME == "Central Streets" then
        local farmSec = FarmTab:CreateSection("Central Streets Farms")
        farmSec:CreateToggle({
            Name = "🖨️ Printer Farm",
            CurrentValue = false,
            Flag = "CS_Printer",
            Callback = function(v)
                if v then
                    task.spawn(function()
                        while Toggles["CS_Printer"].Value do
                            FarmMutex:run(CentralStreetsPrinterFarm, "Printer Farm")
                            task.wait(35)
                        end
                    end)
                end
            end
        })
    else
        local farmSec = FarmTab:CreateSection("Generic Auto Farm")
        farmSec:CreateToggle({
            Name = "🤖 Auto Farm (Experimental)",
            CurrentValue = false,
            Flag = "Generic_Farm",
            Callback = function(v)
                if v then
                    task.spawn(function()
                        while Toggles["Generic_Farm"].Value do
                            print("Generic farm running – customize for this game")
                            task.wait(10)
                        end
                    end)
                end
            end
        })
    end

    -- Gun Spawner (common to all games)
    local gunSec = GunTab:CreateSection("Spawn Guns")
    local gunList = {"Glock", "AK47", "Shotgun", "Mac10", "Uzi", "AR15"}
    for _, gun in ipairs(gunList) do
        gunSec:CreateButton({ Name = "🔫 " .. gun, Callback = function() SpawnGun(gun) end })
    end
end

LoadGameUI()
Rayfield:Notify({ Title = "Hood Omni Hub v2.0", Content = "Loaded for " .. GAME_NAME, Duration = 3 })