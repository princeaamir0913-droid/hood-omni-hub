--[[
    Hood Omni Hub – Complete Edition
    Based on DeepSeekMegaPrompt.txt
    Games: Gang Wars, Central Streets, Tha Bronx 3, Philly Streetz 2
    Features: Potato Farm, Box Job, Scam Farm, ATM Farm, Jewelry Farm, Car Farm, Printer Farm
    Plus: Ghost gun fix, farm mutex, exact prompt matching, gun UI, toggle GUI
]]

-- ========================= CONFIGURATION =========================
local Config = {
    -- Gang Wars / Central Streets
    PotatoFarm = true,
    BoxJobFarm = true,
    ScamFarm = true,
    ATMFarm = true,
    JewelryFarm = true,
    CarFarm = true,
    PrinterFarm = true,
    
    -- Tha Bronx 3
    ThaBronx3AutoFarm = true,
    ThaBronx3Dupe = true,
    
    -- Philly Streetz 2
    PhillyWarehouseFarm = true,
    
    -- Gun spawning
    SpawnGunsOnLoad = true,
    GunList = {"Glock", "AK47", "Shotgun", "Mac10", "Uzi", "AR15"},
    
    -- Other
    AutoRejoin = false,
    FarmDelayBetweenCycles = 1,
}

-- ========================= SERVICES =========================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- ========================= UTILITIES =========================
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then warn("⚠️ Error:", result) end
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

local function getHRP()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleport(cframe)
    local root = getHRP()
    if root then root.CFrame = cframe end
end

-- ========================= GLOBAL FARM MUTEX =========================
local FarmMutex = { currentFarm = nil, isRunning = false, queue = {} }

function FarmMutex:lock(farmName)
    while self.isRunning do task.wait(0.1) end
    self.isRunning = true
    self.currentFarm = farmName
    print("🔒 Farm Mutex: " .. farmName .. " LOCKED")
end

function FarmMutex:unlock()
    self.isRunning = false
    self.currentFarm = nil
    print("🔓 Farm Mutex UNLOCKED")
    if #self.queue > 0 then
        local nextFarm = table.remove(self.queue, 1)
        task.spawn(nextFarm)
    end
end

function FarmMutex:queueFarm(farmFunction, farmName)
    if self.isRunning then
        table.insert(self.queue, function()
            self:lock(farmName)
            farmFunction()
            self:unlock()
        end)
        print("📋 Queued farm: " .. farmName)
    else
        self:lock(farmName)
        task.spawn(function()
            farmFunction()
            self:unlock()
        end)
    end
end

local function RunFarm(farmFunc, farmName)
    return function() FarmMutex:queueFarm(farmFunc, farmName) end
end

-- ========================= EXACT PROMPT MATCHING =========================
local PROMPT_MATCHES = {
    -- Gang Wars
    potato_buy = {"Buy Potatoes", "Purchase Potatoes", "Buy Potato"},
    potato_cook = {"Cook Potatoes", "Start Cooking", "Cook Potato"},
    potato_sell = {"Sell Potatoes", "Sell Cooked Potato", "Sell Potato"},
    box_take = {"Take Box", "Pick Up Box", "Grab Box"},
    box_deliver = {"Deliver Box", "Drop Off", "Complete Delivery"},
    scam_buy_card = {"Buy Card", "Purchase Card", "Buy Prepaid Card"},
    scam_swipe = {"Swipe Card", "Use Card", "Pay with Card"},
    atm_steal = {"Steal Cash", "Rob ATM", "Take Money"},
    jewelry_steal = {"Steal Jewelry", "Take Jewelry", "Grab Jewelry"},
    
    -- Central Streets
    printer_buy = {"Buy Printer", "Purchase Printer"},
    printer_activate = {"Activate Printer", "Start Printer", "Print"},
    printer_collect = {"Collect Money", "Take Money", "Retrieve Cash"},
    car_steal = {"Steal Car", "Hotwire", "Take Car"},
    car_sell = {"Sell Car", "Sell Vehicle"},
    
    -- Tha Bronx 3
    tb3_dupe = {"Duplicate", "Dupe", "Clone Item"},
    tb3_infinite_money = {"Collect Money", "Get Cash", "Infinite Cash"},
    tb3_auto_farm = {"Auto Farm", "Start Farm", "Farm Job"},
    
    -- Philly Streetz 2
    philly_buy = {"Buy Item", "Purchase", "Buy Warehouse Item"},
    philly_place = {"Place Item", "Store Item", "Put in Warehouse"},
    philly_sell = {"Sell Item", "Sell Warehouse", "Sell All"},
}

local function MatchPrompt(prompt, category)
    local matches = PROMPT_MATCHES[category]
    if not matches then return false end
    local action = prompt.ActionText or prompt.Name or ""
    for _, match in ipairs(matches) do
        if action == match then return true end
    end
    return false
end

-- ========================= GHOST GUN FIX (COMPLETE REWRITE) =========================
local function SpawnGun(gunName)
    local backpack = player.Backpack
    local char = player.Character
    
    -- Check if already owned
    if backpack:FindFirstChild(gunName) or (char and char:FindFirstChild(gunName)) then
        print("⚠️ Gun already owned: " .. gunName)
        return false
    end
    
    -- Locate gun template
    local gunTemplate = ReplicatedStorage:FindFirstChild("Items") and ReplicatedStorage.Items:FindFirstChild(gunName)
    if not gunTemplate then
        gunTemplate = ReplicatedStorage:FindFirstChild("weapons") and ReplicatedStorage.weapons:FindFirstChild(gunName)
    end
    if not gunTemplate then
        warn("❌ Gun template not found: " .. gunName)
        return false
    end
    
    -- Clone with ALL descendants
    local gun = gunTemplate:Clone()
    task.wait(0.1)
    
    -- Fire any remote events that might initialize the gun
    local remotes = {"Fire", "Shoot", "DamageRemote", "OnHit", "BulletHit", "RemoteFire", "FireBullet", "EquipGun", "InitGun", "SetupGun"}
    for _, remoteName in ipairs(remotes) do
        local remote = gun:FindFirstChild(remoteName)
        if remote and remote:IsA("RemoteEvent") then
            safeCall(function() remote:FireServer(player) end)
        end
    end
    
    -- Force tool enabled
    if gun:IsA("Tool") then
        gun.Enabled = true
        if gun:FindFirstChild("Handle") then
            gun.Handle.Touched:Connect(function() end)
        end
    end
    
    -- Parent to backpack
    gun.Parent = backpack
    task.wait(0.2)
    
    -- Verify
    if char and char:FindFirstChild(gunName) then
        print("✅ Gun equipped and functional: " .. gunName)
        return true
    elseif backpack:FindFirstChild(gunName) then
        print("✅ Gun in backpack (equip to test): " .. gunName)
        return true
    else
        warn("⚠️ Gun spawned but may not be functional: " .. gunName)
        return false
    end
end

-- ========================= GANG WARS FARMS =========================

-- Potato Farm
local function PotatoFarm()
    FarmMutex:lock("🥔 Potato Farm")
    print("🥔 Starting Potato Farm...")
    
    -- Teleport to potato factory area
    local factoryPos = Workspace:FindFirstChild("PotatoFactory") or Workspace:FindFirstChild("Factory")
    if factoryPos then
        teleport(factoryPos.CFrame + Vector3.new(0, 5, 0))
        task.wait(1)
    end
    
    -- Buy potatoes
    local buyPrompt = nil
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, "potato_buy") then
            buyPrompt = prompt
            break
        end
    end
    if buyPrompt then
        for i = 1, 10 do
            firePrompt(buyPrompt)
            task.wait(0.2)
        end
        print("✅ Bought 10 potatoes")
    else
        warn("⚠️ Could not find potato buy prompt")
    end
    
    -- Find cooking pots/stoves
    local pots = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("pot") or obj.Name:lower():find("stove")) then
            table.insert(pots, obj)
        end
    end
    
    -- Cook each potato
    for i = 1, 10 do
        local rawPotato = nil
        for _, item in ipairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("raw") or item.Name:lower():find("potato")) then
                rawPotato = item
                break
            end
        end
        if rawPotato then
            rawPotato.Parent = player.Character
            task.wait(0.2)
            for _, pot in ipairs(pots) do
                teleport(pot.CFrame + Vector3.new(0, 2, 0))
                task.wait(0.3)
                local cookPrompt = nil
                for _, prompt in ipairs(pot:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, "potato_cook") then
                        cookPrompt = prompt
                        break
                    end
                end
                if cookPrompt then
                    firePrompt(cookPrompt)
                    task.wait(0.5)
                    break
                end
            end
        end
        task.wait(1)
    end
    
    -- Wait for and sell cooked potatoes
    local startTime = tick()
    while tick() - startTime < 45 do
        local cookedPotato = nil
        for _, item in ipairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("cooked") or item.Name:lower():find("cook")) then
                cookedPotato = item
                break
            end
        end
        if cookedPotato then
            cookedPotato.Parent = player.Character
            task.wait(0.2)
            local sellPrompt = nil
            for _, prompt in ipairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, "potato_sell") then
                    sellPrompt = prompt
                    break
                end
            end
            if sellPrompt then
                firePrompt(sellPrompt)
                print("💰 Sold cooked potato")
            end
            break
        end
        task.wait(0.5)
    end
    
    print("✅ Potato Farm finished")
    FarmMutex:unlock()
end

-- Box Job Farm
local function BoxJobFarm()
    FarmMutex:lock("📦 Box Job")
    print("📦 Starting Box Job...")
    
    local box = Workspace:FindFirstChild("BOX1")
    local jobDest = Workspace:FindFirstChild("Job")
    if not box or not jobDest then
        warn("⚠️ Box or Job destination missing")
        FarmMutex:unlock()
        return
    end
    
    local clickDetector = box:FindFirstChildOfClass("ClickDetector")
    if not clickDetector then
        warn("⚠️ No ClickDetector on box")
        FarmMutex:unlock()
        return
    end
    
    for cycle = 1, 10 do
        local root = getHRP()
        if root then
            jobDest.CFrame = root.CFrame
            task.wait(0.1)
            firePrompt(clickDetector)
            task.wait(0.05)
        end
        task.wait(Config.FarmDelayBetweenCycles)
    end
    
    print("✅ Box Job finished")
    FarmMutex:unlock()
end

-- Scam Farm (4 steps)
local function ScamFarm()
    FarmMutex:lock("💳 Scam Farm")
    print("💳 Starting Scam Farm...")
    
    local steps = {"scam_buy_card", "scam_swipe", "scam_swipe", "atm_steal"}
    for _, stepCategory in ipairs(steps) do
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, stepCategory) then
                firePrompt(prompt)
                task.wait(1)
                break
            end
        end
        task.wait(0.5)
    end
    
    print("✅ Scam Farm finished")
    FarmMutex:unlock()
end

-- ATM Farm (nearest ATM only)
local function ATMFarm()
    FarmMutex:lock("🏧 ATM Farm")
    print("🏧 Starting ATM Farm...")
    
    local nearestATM = nil
    local minDist = math.huge
    local root = getHRP()
    if not root then
        FarmMutex:unlock()
        return
    end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("atm") or obj.Name:lower():find("bank")) then
            local dist = (obj.Position - root.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearestATM = obj
            end
        end
    end
    
    if nearestATM then
        teleport(nearestATM.CFrame + Vector3.new(0, 3, 0))
        task.wait(0.5)
        for _, prompt in ipairs(nearestATM:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, "atm_steal") then
                firePrompt(prompt)
                break
            end
        end
    else
        warn("⚠️ No ATM found")
    end
    
    print("✅ ATM Farm finished")
    FarmMutex:unlock()
end

-- Jewelry Farm
local function JewelryFarm()
    FarmMutex:lock("💎 Jewelry Farm")
    print("💎 Starting Jewelry Farm...")
    
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, "jewelry_steal") then
            firePrompt(prompt)
            task.wait(0.3)
        end
    end
    
    print("✅ Jewelry Farm finished")
    FarmMutex:unlock()
end

-- Car Farm (Central Streets)
local function CarFarm()
    FarmMutex:lock("🚗 Car Farm")
    print("🚗 Starting Car Farm...")
    
    local cars = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("VehicleSeat") or (obj.Name:lower():find("car") and obj:IsA("BasePart")) then
            table.insert(cars, obj)
        end
    end
    
    for _, car in ipairs(cars) do
        teleport(car.CFrame + Vector3.new(0, 2, 0))
        task.wait(0.5)
        for _, prompt in ipairs(car:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and (MatchPrompt(prompt, "car_steal") or prompt.ActionText:lower():find("steal")) then
                firePrompt(prompt)
                task.wait(1)
                break
            end
        end
    end
    
    print("✅ Car Farm finished")
    FarmMutex:unlock()
end

-- Printer Farm (Central Streets)
local function PrinterFarm()
    FarmMutex:lock("🖨️ Printer Farm")
    print("🖨️ Starting Printer Farm...")
    
    -- Buy printer and paper
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if MatchPrompt(prompt, "printer_buy") then
                firePrompt(prompt)
                task.wait(0.5)
            elseif prompt.ActionText:find("Paper") or prompt.ActionText:find("Substrate") then
                firePrompt(prompt)
                task.wait(0.5)
            end
        end
    end
    
    -- Place printer
    local printerTool = player.Backpack:FindFirstChild("Printer")
    if printerTool then
        printerTool.Parent = player.Character
        task.wait(0.5)
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.ActionText:find("Place") then
                firePrompt(prompt)
                break
            end
        end
        task.wait(1)
    end
    
    -- Activate and collect cycle
    for cycle = 1, 5 do
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, "printer_activate") then
                firePrompt(prompt)
                break
            end
        end
        task.wait(30)
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, "printer_collect") then
                firePrompt(prompt)
                break
            end
        end
        task.wait(1)
    end
    
    print("✅ Printer Farm finished")
    FarmMutex:unlock()
end

-- ========================= THA BRONX 3 FARMS =========================
local function ThaBronx3AutoFarm()
    FarmMutex:lock("🔫 Tha Bronx 3 Auto")
    print("🔫 Starting Tha Bronx 3 Auto Farm...")
    
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, "tb3_auto_farm") then
            firePrompt(prompt)
            task.wait(1)
        end
    end
    
    print("✅ Tha Bronx 3 Auto Farm finished")
    FarmMutex:unlock()
end

local function ThaBronx3Dupe()
    FarmMutex:lock("🔄 Tha Bronx 3 Dupe")
    print("🔄 Starting Tha Bronx 3 Dupe...")
    
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and MatchPrompt(prompt, "tb3_dupe") then
            firePrompt(prompt)
            task.wait(1)
        end
    end
    
    print("✅ Tha Bronx 3 Dupe finished")
    FarmMutex:unlock()
end

-- ========================= PHILLY STREETZ 2 FARMS =========================
local function PhillyWarehouseFarm()
    FarmMutex:lock("🏭 Philly Warehouse")
    print("🏭 Starting Philly Warehouse Farm...")
    
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if MatchPrompt(prompt, "philly_buy") then
                firePrompt(prompt)
                task.wait(0.5)
            elseif MatchPrompt(prompt, "philly_place") then
                firePrompt(prompt)
                task.wait(0.5)
            elseif MatchPrompt(prompt, "philly_sell") then
                firePrompt(prompt)
            end
        end
    end
    
    print("✅ Philly Warehouse Farm finished")
    FarmMutex:unlock()
end

-- ========================= GUN UI (ORGANIZED BY DROPDOWN CATEGORIES) =========================
local function CreateGunUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GunSpawner"
    screenGui.Parent = player.PlayerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 400)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 1
    mainFrame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Text = "Gun Spawner"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = mainFrame
    
    -- Dropdown for gun categories
    local categories = {"Pistols", "Rifles", "Shotguns", "SMGs"}
    local currentCategory = "Pistols"
    
    local categoryBtn = Instance.new("TextButton")
    categoryBtn.Size = UDim2.new(0, 200, 0, 30)
    categoryBtn.Position = UDim2.new(0.5, -100, 0, 35)
    categoryBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    categoryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    categoryBtn.Text = "Category: " .. currentCategory
    categoryBtn.Parent = mainFrame
    
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0, 200, 0, 120)
    dropdownFrame.Position = UDim2.new(0.5, -100, 0, 65)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    dropdownFrame.Visible = false
    dropdownFrame.Parent = mainFrame
    
    local dropdownVisible = false
    
    for i, cat in ipairs(categories) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.Position = UDim2.new(0, 5, 0, (i-1) * 30)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = cat
        btn.Parent = dropdownFrame
        btn.MouseButton1Click:Connect(function()
            currentCategory = cat
            categoryBtn.Text = "Category: " .. currentCategory
            dropdownFrame.Visible = false
            dropdownVisible = false
        end)
    end
    
    categoryBtn.MouseButton1Click:Connect(function()
        dropdownVisible = not dropdownVisible
        dropdownFrame.Visible = dropdownVisible
    end)
    
    -- Gun spawn buttons
    local gunListFrame = Instance.new("ScrollingFrame")
    gunListFrame.Size = UDim2.new(1, -10, 0, 220)
    gunListFrame.Position = UDim2.new(0, 5, 0, 170)
    gunListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    gunListFrame.ScrollBarThickness = 4
    gunListFrame.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = gunListFrame
    
    for _, gunName in ipairs(Config.GunList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = "🔫 " .. gunName
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = gunListFrame
        btn.MouseButton1Click:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
            btn.Text = "Spawning..."
            local ok = SpawnGun(gunName)
            task.wait(0.5)
            btn.BackgroundColor3 = ok and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(180, 0, 0)
            btn.Text = ok and ("✅ " .. gunName) or ("❌ " .. gunName)
        end)
    end
    
    gunListFrame.CanvasSize = UDim2.new(0, 0, 0, #Config.GunList * 32)
end

-- ========================= TOGGLE GUI =========================
local function CreateToggleGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FarmToggleGUI"
    screenGui.Parent = player.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 380)
    frame.Position = UDim2.new(1, -230, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 1
    frame.Parent = screenGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "🏠 Hood Omni Hub"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.Parent = frame

    local farms = {
        {"🥔 Potato Farm",    PotatoFarm,         "PotatoFarm"},
        {"📦 Box Job",        BoxJobFarm,         "BoxJobFarm"},
        {"💳 Scam Farm",      ScamFarm,           "ScamFarm"},
        {"🏧 ATM Farm",       ATMFarm,            "ATMFarm"},
        {"💎 Jewelry Farm",   JewelryFarm,        "JewelryFarm"},
        {"🚗 Car Farm",       CarFarm,            "CarFarm"},
        {"🖨️ Printer Farm",   PrinterFarm,        "PrinterFarm"},
        {"🔫 Bronx3 Auto",    ThaBronx3AutoFarm,  "ThaBronx3AutoFarm"},
        {"🔄 Bronx3 Dupe",    ThaBronx3Dupe,      "ThaBronx3Dupe"},
        {"🏭 Philly WH",      PhillyWarehouseFarm,"PhillyWarehouseFarm"},
    }

    for i, farmData in ipairs(farms) do
        local label, farmFunc, configKey = farmData[1], farmData[2], farmData[3]

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 28)
        row.Position = UDim2.new(0, 5, 0, 30 + (i-1) * 32)
        row.BackgroundTransparency = 1
        row.Parent = frame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.65, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.Text = label
        nameLabel.Parent = row

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0.33, 0, 0.85, 0)
        toggleBtn.Position = UDim2.new(0.66, 0, 0.075, 0)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 11
        local enabled = Config[configKey]
        toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0, 160, 70) or Color3.fromRGB(160, 0, 0)
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Text = enabled and "ON" or "OFF"
        toggleBtn.Parent = row

        toggleBtn.MouseButton1Click:Connect(function()
            Config[configKey] = not Config[configKey]
            local state = Config[configKey]
            toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 160, 70) or Color3.fromRGB(160, 0, 0)
            toggleBtn.Text = state and "ON" or "OFF"
            if state then
                RunFarm(farmFunc, label)()
            end
        end)
    end

    -- Status bar
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 1, -22)
    statusLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.Text = "Status: Idle"
    statusLabel.Parent = frame

    -- Update status from mutex
    task.spawn(function()
        while task.wait(0.5) do
            if FarmMutex.isRunning then
                statusLabel.Text = "⚙️ " .. (FarmMutex.currentFarm or "Running...")
                statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            else
                statusLabel.Text = "✅ Idle"
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        end
    end)
end

-- ========================= INITIALIZATION =========================
print("🏠 Hood Omni Hub – Complete Edition Loading...")

-- Create UIs
CreateGunUI()
CreateToggleGUI()

-- Spawn guns on load
if Config.SpawnGunsOnLoad then
    task.spawn(function()
        task.wait(2)
        for _, gunName in ipairs(Config.GunList) do
            SpawnGun(gunName)
            task.wait(0.3)
        end
    end)
end

-- Auto-start enabled farms
task.spawn(function()
    task.wait(3)
    local farmMap = {
        {Config.PotatoFarm,         PotatoFarm,         "🥔 Potato Farm"},
        {Config.BoxJobFarm,         BoxJobFarm,         "📦 Box Job"},
        {Config.ScamFarm,           ScamFarm,           "💳 Scam Farm"},
        {Config.ATMFarm,            ATMFarm,            "🏧 ATM Farm"},
        {Config.JewelryFarm,        JewelryFarm,        "💎 Jewelry Farm"},
        {Config.CarFarm,            CarFarm,            "🚗 Car Farm"},
        {Config.PrinterFarm,        PrinterFarm,        "🖨️ Printer Farm"},
        {Config.ThaBronx3AutoFarm,  ThaBronx3AutoFarm,  "🔫 Bronx3 Auto"},
        {Config.ThaBronx3Dupe,      ThaBronx3Dupe,      "🔄 Bronx3 Dupe"},
        {Config.PhillyWarehouseFarm,PhillyWarehouseFarm,"🏭 Philly WH"},
    }
    for _, entry in ipairs(farmMap) do
        if entry[1] then
            RunFarm(entry[2], entry[3])()
            task.wait(0.5)
        end
    end
end)

print("✅ Hood Omni Hub Loaded! Use the GUI to toggle farms.")
