--[[
    Underground War 2.0 Script
    Game: Underground War 2.0 ⚔️ [NUKE]
    PlaceId: 9791603388
    
    Features:
    - Auto Game Detection
    - Auto Dig
    - Kill Aura
    - ESP (Player highlights)
    - Aimbot / Silent Aim
    - Sword Reach Modifier
    - Auto Upgrade (weapons/stats)
    - Auto Shoot
    - Toggle GUI
]]

-- ========================= GAME DETECTION =========================
local PLACE_ID = 9791603388
local GAME_NAME = "Underground War 2.0"

if game.PlaceId ~= PLACE_ID then
    -- Try to detect by game name
    local marketplaceService = game:GetService("MarketplaceService")
    local success, info = pcall(function()
        return marketplaceService:GetProductInfo(game.PlaceId)
    end)
    
    if success and info and info.Name then
        if not (info.Name:lower():find("underground") and info.Name:lower():find("war")) then
            warn("⚠️ This script is for " .. GAME_NAME .. " (PlaceId: " .. PLACE_ID .. ")")
            warn("⚠️ Detected game: " .. info.Name .. " (PlaceId: " .. game.PlaceId .. ")")
            warn("⚠️ Script may not work correctly in this game.")
        else
            print("✅ Detected: " .. info.Name .. " (variant/update of Underground War)")
        end
    else
        warn("⚠️ Could not verify game. Expected " .. GAME_NAME .. " (PlaceId: " .. PLACE_ID .. ")")
    end
else
    print("✅ Game detected: " .. GAME_NAME)
end

-- ========================= SERVICES =========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ========================= CONFIG =========================
local Config = {
    -- Features
    AutoDig = true,
    KillAura = true,
    ESP = true,
    Aimbot = false,
    SilentAim = true,
    SwordReach = true,
    AutoUpgrade = true,
    AutoShoot = false,
    
    -- Settings
    KillAuraRange = 15,
    SwordReachLength = 25,
    AimbotFOV = 250,
    ESPColor = Color3.fromRGB(255, 0, 0),
    ESPTeamCheck = true,
    DigSpeed = 0.1,
    AutoShootDelay = 0.15,
}

-- ========================= UTILITIES =========================
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then warn("⚠️ Error:", result) end
    return success, result
end

local function getHRP()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(plr)
    local char = plr.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isEnemy(plr)
    if plr == player then return false end
    if not Config.ESPTeamCheck then return true end
    return plr.Team ~= player.Team
end

local function getClosestPlayer(maxDist)
    local closest = nil
    local minDist = maxDist or math.huge
    local root = getHRP()
    if not root then return nil end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and isAlive(plr) and isEnemy(plr) then
            local enemyRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                local dist = (enemyRoot.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest, minDist
end

-- ========================= ESP =========================
local espFolder = Instance.new("Folder")
espFolder.Name = "UW2_ESP"
espFolder.Parent = game.CoreGui

local function createESP(plr)
    if plr == player then return end
    
    local function applyESP()
        local char = plr.Character
        if not char then return end
        
        -- Remove old ESP
        local oldHighlight = char:FindFirstChild("UW2_Highlight")
        if oldHighlight then oldHighlight:Destroy() end
        local oldLabel = char:FindFirstChild("UW2_Billboard")
        if oldLabel then oldLabel:Destroy() end
        
        if not Config.ESP then return end
        if Config.ESPTeamCheck and not isEnemy(plr) then return end
        
        -- Highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "UW2_Highlight"
        highlight.Adornee = char
        highlight.FillColor = Config.ESPColor
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0.3
        highlight.Parent = char
        
        -- Billboard with name + distance
        local head = char:FindFirstChild("Head")
        if head then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "UW2_Billboard"
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Adornee = head
            billboard.Parent = char
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.Text = plr.Name
            nameLabel.TextScaled = true
            nameLabel.Parent = billboard
            
            local distLabel = Instance.new("TextLabel")
            distLabel.Name = "DistLabel"
            distLabel.Size = UDim2.new(1, 0, 0.5, 0)
            distLabel.Position = UDim2.new(0, 0, 0.5, 0)
            distLabel.BackgroundTransparency = 1
            distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            distLabel.TextStrokeTransparency = 0.5
            distLabel.TextScaled = true
            distLabel.Parent = billboard
            
            -- Update distance
            task.spawn(function()
                while billboard and billboard.Parent and char and char.Parent do
                    local root = getHRP()
                    local enemyRoot = char:FindFirstChild("HumanoidRootPart")
                    if root and enemyRoot then
                        local dist = math.floor((root.Position - enemyRoot.Position).Magnitude)
                        distLabel.Text = "[" .. dist .. " studs]"
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
    
    applyESP()
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        applyESP()
    end)
end

-- Initialize ESP for all players
for _, plr in ipairs(Players:GetPlayers()) do
    task.spawn(createESP, plr)
end
Players.PlayerAdded:Connect(function(plr)
    task.spawn(createESP, plr)
end)

-- ========================= KILL AURA =========================
local killAuraConnection = nil

local function startKillAura()
    if killAuraConnection then return end
    killAuraConnection = RunService.Heartbeat:Connect(function()
        if not Config.KillAura then return end
        local root = getHRP()
        if not root then return end
        
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then return end
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and isAlive(plr) and isEnemy(plr) then
                local enemyChar = plr.Character
                local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
                if enemyRoot then
                    local dist = (enemyRoot.Position - root.Position).Magnitude
                    if dist <= Config.KillAuraRange then
                        -- Try to damage via tool
                        local handle = tool:FindFirstChild("Handle")
                        if handle then
                            firetouchinterest(handle, enemyRoot, 0)
                            task.wait()
                            firetouchinterest(handle, enemyRoot, 1)
                        end
                        
                        -- Try remote events
                        for _, remote in ipairs(tool:GetDescendants()) do
                            if remote:IsA("RemoteEvent") then
                                safeCall(function()
                                    remote:FireServer(enemyChar, enemyRoot.Position)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ========================= SWORD REACH =========================
local function applySwordReach()
    local char = player.Character
    if not char then return end
    
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local handle = tool:FindFirstChild("Handle")
            if handle and Config.SwordReach then
                handle.Size = Vector3.new(1, 1, Config.SwordReachLength)
                handle.Transparency = 1
                handle.Massless = true
                handle.CanCollide = false
            end
        end
    end
end

-- Monitor equipped tools for reach
player.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and Config.SwordReach then
            task.wait(0.1)
            applySwordReach()
        end
    end)
end)

-- ========================= AIMBOT / SILENT AIM =========================
local aimTarget = nil

local function getAimbotTarget()
    local closest = nil
    local minAngle = Config.AimbotFOV
    local root = getHRP()
    if not root then return nil end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and isAlive(plr) and isEnemy(plr) then
            local enemyChar = plr.Character
            local head = enemyChar and enemyChar:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local mousePos = Vector2.new(mouse.X, mouse.Y)
                    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                    local angle = (mousePos - targetPos).Magnitude
                    if angle < minAngle then
                        minAngle = angle
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

-- Aimbot render step
local aimbotConnection = nil
local function startAimbot()
    if aimbotConnection then return end
    aimbotConnection = RunService.RenderStepped:Connect(function()
        if not Config.Aimbot then return end
        
        local target = getAimbotTarget()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end)
end

-- Silent Aim hook
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if Config.SilentAim and (method == "FireServer" or method == "InvokeServer") then
        local target = getAimbotTarget()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                for i, arg in ipairs(args) do
                    if typeof(arg) == "Vector3" then
                        args[i] = head.Position
                    elseif typeof(arg) == "CFrame" then
                        args[i] = head.CFrame
                    end
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

-- ========================= AUTO DIG =========================
local autoDigConnection = nil

local function startAutoDig()
    if autoDigConnection then return end
    autoDigConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoDig then return end
        
        local char = player.Character
        if not char then return end
        
        -- Find dig tool (shovel/pickaxe)
        local digTool = nil
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("shovel") or name:find("pick") or name:find("dig") then
                    digTool = tool
                    break
                end
            end
        end
        
        if not digTool then
            -- Try to equip from backpack
            for _, tool in ipairs(player.Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local name = tool.Name:lower()
                    if name:find("shovel") or name:find("pick") or name:find("dig") then
                        tool.Parent = char
                        task.wait(0.1)
                        digTool = tool
                        break
                    end
                end
            end
        end
        
        if digTool then
            -- Activate dig tool (simulate click)
            safeCall(function() digTool:Activate() end)
            
            -- Fire any dig remotes
            for _, remote in ipairs(digTool:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    safeCall(function()
                        local root = getHRP()
                        if root then
                            remote:FireServer(root.Position - Vector3.new(0, 3, 0))
                        end
                    end)
                end
            end
        end
        
        task.wait(Config.DigSpeed)
    end)
end

-- ========================= AUTO UPGRADE =========================
local function autoUpgrade()
    while Config.AutoUpgrade do
        -- Look for upgrade buttons/prompts
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local action = (obj.ActionText or obj.Name):lower()
                if action:find("upgrade") or action:find("level") or action:find("improve") or action:find("enhance") then
                    local root = getHRP()
                    local promptParent = obj.Parent
                    if root and promptParent and promptParent:IsA("BasePart") then
                        local dist = (root.Position - promptParent.Position).Magnitude
                        if dist < 30 then
                            safeCall(function() fireproximityprompt(obj, 0) end)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
        
        -- Try upgrade remotes
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local name = remote.Name:lower()
                if name:find("upgrade") or name:find("levelup") or name:find("improve") then
                    safeCall(function()
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer()
                        else
                            remote:InvokeServer()
                        end
                    end)
                    task.wait(0.5)
                end
            end
        end
        
        task.wait(3)
    end
end

-- ========================= AUTO SHOOT =========================
local autoShootConnection = nil

local function startAutoShoot()
    if autoShootConnection then return end
    autoShootConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoShoot then return end
        
        local char = player.Character
        if not char then return end
        
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end
        
        local toolName = tool.Name:lower()
        if toolName:find("sword") or toolName:find("shovel") or toolName:find("pick") then return end
        
        local target = getAimbotTarget()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                -- Activate tool (shoot)
                safeCall(function() tool:Activate() end)
                
                -- Fire shooting remotes
                for _, remote in ipairs(tool:GetDescendants()) do
                    if remote:IsA("RemoteEvent") then
                        safeCall(function()
                            remote:FireServer(head.Position, head.CFrame)
                        end)
                    end
                end
            end
        end
        
        task.wait(Config.AutoShootDelay)
    end)
end

-- ========================= TOGGLE GUI =========================
local function CreateGUI()
    -- Destroy existing
    local existing = game.CoreGui:FindFirstChild("UW2_Hub")
    if existing then existing:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UW2_Hub"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game.CoreGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 420)
    mainFrame.Position = UDim2.new(0, 15, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Text = "⚔️ Underground War 2.0 Hub"
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = titleBar
    
    -- Close/minimize button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "—"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    local minimized = false
    closeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _, child in ipairs(mainFrame:GetChildren()) do
            if child ~= titleBar and child:IsA("GuiObject") then
                child.Visible = not minimized
            end
        end
        mainFrame.Size = minimized and UDim2.new(0, 280, 0, 40) or UDim2.new(0, 280, 0, 420)
        closeBtn.Text = minimized and "+" or "—"
    end)
    
    -- Scroll frame for toggles
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -50)
    scrollFrame.Position = UDim2.new(0, 10, 0, 45)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 100)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = mainFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = scrollFrame
    
    -- Toggle creator function
    local function createToggle(name, configKey, description)
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(1, 0, 0, 40)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        toggleFrame.BorderSizePixel = 0
        toggleFrame.Parent = scrollFrame
        
        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(0, 6)
        tCorner.Parent = toggleFrame
        
        local label = Instance.new("TextLabel")
        label.Text = name
        label.Size = UDim2.new(0.65, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.Parent = toggleFrame
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 50, 0, 24)
        toggleBtn.Position = UDim2.new(1, -60, 0.5, -12)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 11
        toggleBtn.Parent = toggleFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = toggleBtn
        
        local function updateVisual()
            if Config[configKey] then
                toggleBtn.Text = "ON"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
                toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                toggleBtn.Text = "OFF"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
                toggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        end
        
        updateVisual()
        
        toggleBtn.MouseButton1Click:Connect(function()
            Config[configKey] = not Config[configKey]
            updateVisual()
            print("🔄 " .. name .. ": " .. (Config[configKey] and "ON" or "OFF"))
        end)
        
        return toggleFrame
    end
    
    -- Create all toggles
    createToggle("⛏️ Auto Dig", "AutoDig", "Automatically digs tunnels")
    createToggle("💀 Kill Aura", "KillAura", "Damages nearby enemies")
    createToggle("👁️ ESP", "ESP", "See players through walls")
    createToggle("🎯 Aimbot", "Aimbot", "Lock onto enemy heads")
    createToggle("🔫 Silent Aim", "SilentAim", "Bullets hit closest enemy")
    createToggle("⚔️ Sword Reach", "SwordReach", "Extended melee range")
    createToggle("⬆️ Auto Upgrade", "AutoUpgrade", "Auto upgrade weapons/stats")
    createToggle("💥 Auto Shoot", "AutoShoot", "Auto fire at enemies")
    
    -- Update canvas size
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    
    -- Toggle GUI visibility with Right Ctrl
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
    
    print("✅ GUI loaded! Press Right Ctrl to toggle visibility.")
    return screenGui
end

-- ========================= START EVERYTHING =========================
print("═══════════════════════════════════════")
print("⚔️ Underground War 2.0 Hub Loading...")
print("═══════════════════════════════════════")

-- Start systems
CreateGUI()
startKillAura()
startAimbot()
startAutoDig()
startAutoShoot()

-- Start auto upgrade in background
task.spawn(autoUpgrade)

-- Apply sword reach on current tools
task.spawn(function()
    task.wait(1)
    applySwordReach()
end)

print("═══════════════════════════════════════")
print("✅ All systems loaded!")
print("⛏️ Auto Dig: " .. (Config.AutoDig and "ON" or "OFF"))
print("💀 Kill Aura: " .. (Config.KillAura and "ON" or "OFF"))
print("👁️ ESP: " .. (Config.ESP and "ON" or "OFF"))
print("🎯 Aimbot: " .. (Config.Aimbot and "ON" or "OFF"))
print("🔫 Silent Aim: " .. (Config.SilentAim and "ON" or "OFF"))
print("⚔️ Sword Reach: " .. (Config.SwordReach and "ON" or "OFF"))
print("⬆️ Auto Upgrade: " .. (Config.AutoUpgrade and "ON" or "OFF"))
print("💥 Auto Shoot: " .. (Config.AutoShoot and "ON" or "OFF"))
print("═══════════════════════════════════════")
print("Press Right Ctrl to toggle GUI")
print("═══════════════════════════════════════")
