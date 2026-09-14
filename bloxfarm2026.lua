--[[
    Blox Fruits Auto-Farm — 2026 Update
    Android Executor Build
    Author: KAKU for He
    Max Level: 2800 (Third Sea endgame)
    Loadstring-ready
--]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui        = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════
local Config = {
    AttackStyle       = "Melee",
    AutoClickDelay    = 0.08,
    SkillCooldowns    = true,
    BringMobs         = true,
    BringRadius       = 140,
    FarmRadius        = 70,

    -- Movement
    BaseWalkSpeed     = 16,        -- restored when speed toggle is off
    SpeedValue        = 120,       -- set when speed toggle on
    WalkOnWater       = false,
    SafeTP            = true,
    TPOffset          = 6,

    -- Mass damage
    MassDamage        = false,     -- server-trust hitbox expand
    MassRange         = 30,        -- studs added to hitbox

    -- Quest
    AutoQuest         = true,
    AutoNextQuest     = true,
    AutoMastery       = false,

    -- UI
    UIOpen            = true,
    Minimized         = false,
}

-- ═══════════════════════════════════════════════
-- QUEST DATA — 2026 PATCH
-- (First / Second / Third Sea, extended to 2800)
-- ═══════════════════════════════════════════════
local QuestData = {
    -- First Sea
    {lv=1,    mobs={"Bandit","Monkey"},                       island="Starter Island"},
    {lv=10,   mobs={"Monkey","Bandit [Lv. 5]"},               island="Starter Island"},
    {lv=15,   mobs={"The Musician"},                          island="Starter Island"},
    {lv=30,   mobs={"Reborn Skeleton","Living Zombie"},       island="Marine Fort"},
    {lv=60,   mobs={"Pirate","Brute"},                        island="Kingdom of Rose"},
    {lv=90,   mobs={"Snow Bandit","Snow Bandit [Lv. 65]"},    island="Frost Island"},
    {lv=120,  mobs={"Desert Bandit","Desert Officer"},        island="Desert Island"},
    {lv=200,  mobs={"Sky Bandit","Dark Master"},              island="Skylands"},
    {lv=300,  mobs={"Military Soldier","Military Spy"},        island="Fountain City"},
    {lv=450,  mobs={"Magma Ninja","Lava Pirate"},             island="Magma Village"},
    -- Second Sea
    {lv=625,  mobs={"Sea Soldier","Water Fighter"},           island="Underwater City"},
    {lv=750,  mobs={"Living Zombie","Demonic Soul"},          island="Cursed Ship"},
    {lv=1000, mobs={"Reborn Skeleton","Living Zombie"},       island="Haunted Castle"},
    {lv=1250, mobs={"Fighter","Sky Bandit"},                  island="Upper Skylands"},
    {lv=1500, mobs={"Dragon Crew Warrior","Dragon Crew Archer"}, island="Hydra Island"},
    -- Third Sea (current era)
    {lv=1750, mobs={"Forest Pirate","Mythological Pirate"},   island="Great Tree"},
    {lv=2000, mobs={"Cursed Skeleton","Pirate Millionaire"},  island="Castle on the Sea"},
    {lv=2250, mobs={"Ghost","Ghost [Lv. 2100]"},              island="Haunted Ship"},
    {lv=2450, mobs={"Candy Pirate","Candy Rebel"},            island="Cake Land"},
    {lv=2550, mobs={"Reborn Skeleton","Living Zombie"},       island="Haunted Castle"},
    {lv=2650, mobs={"Snow Lurker","Snow Trooper"},            island="Frost Island"},
    {lv=2700, mobs={"Pirate","Brute"},                        island="Kingdom of Rose"},
    {lv=2750, mobs={"Fishman","Fishman Captain"},             island="Fishman Island"},
    {lv=2800, mobs={"Cursed Skeleton","Pirate Millionaire"},  island="Castle on the Sea"},
}

-- ═══════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════
local State = {
    Running      = false,
    CurrentQuest = nil,
    Target       = nil,
    Session      = 0,
}

-- ═══════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 3,
        })
    end)
end

local function getLevel()
    local ok, lv = pcall(function() return LP.Data.Level.Value end)
    return ok and lv or 1
end

local function getHumanoid()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function getRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function hasQuest()
    local ok, has = pcall(function()
        return LP.PlayerGui.Main.Quest.Visible
    end)
    return ok and has or false
end

-- ═══════════════════════════════════════════════
-- WALK ON WATER
-- ═══════════════════════════════════════════════
local function applyWalkOnWater()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if Config.WalkOnWater then
        -- Neutralize buoyancy by pushing humanoid state to Running on water
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0)
        end
    else
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
    end
end

-- ═══════════════════════════════════════════════
-- SPEED
-- ═══════════════════════════════════════════════
local function applySpeed()
    local hum = getHumanoid()
    if not hum then return end
    hum.WalkSpeed = Config.BaseWalkSpeed
    -- When speed toggle is on, apply SpeedValue
    if Config._SpeedOn then
        hum.WalkSpeed = Config.SpeedValue
    end
end

-- ═══════════════════════════════════════════════
-- QUEST LOGIC
-- ═══════════════════════════════════════════════
local function pickQuestForLevel(lv)
    local chosen = QuestData[1]
    for _, q in ipairs(QuestData) do
        if lv >= q.lv then chosen = q end
    end
    return chosen
end

local function acceptQuest(questInfo)
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:IsA("Model") then
            local nm = npc.Name
            if nm:find("Quest") or nm:find(questInfo.island) then
                local root = npc:FindFirstChild("HumanoidRootPart")
                local myRoot = getRoot()
                if root and myRoot then
                    myRoot.CFrame = root.CFrame * CFrame.new(0, 0, Config.TPOffset)
                    task.wait(0.4)
                    local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        fireproximityprompt(prompt)
                        task.wait(0.3)
                    end
                    return true
                end
            end
        end
    end
    return false
end

-- ═══════════════════════════════════════════════
-- MOB DETECTION
-- ═══════════════════════════════════════════════
local function findMob(mobNames)
    local closest, closestDist = nil, math.huge
    local myRoot = getRoot()
    if not myRoot then return nil end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local matched = false
                for _, mn in ipairs(mobNames) do
                    if obj.Name:find(mn, 1, true) then matched = true break end
                end
                if matched then
                    local d = (root.Position - myRoot.Position).Magnitude
                    if d < closestDist then closest, closestDist = obj, d end
                end
            end
        end
    end
    return closest, closestDist
end

-- ═══════════════════════════════════════════════
-- ATTACK
-- ═══════════════════════════════════════════════
local function equipToolForStyle(style)
    local char = LP.Character
    if not char then return end

    local tool = nil
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if style == "Melee" and (n:find("combat") or n:find("black leg") or n:find("electro") or n:find("dragon talon") or n:find("superhuman") or n:find("death step")) then
                tool = t
            elseif style == "Sword" and (n:find("sword") or n:find("blade") or n:find("katana") or n:find("cutlass") or n:find("saber") or n:find("cursed dual")) then
                tool = t
            elseif style == "BloxFruit" and (n:find("fruit") or n:find("dragon") or n:find("kitsune") or n:find("leopard") or n:find("dough") or n:find("venom") or n:find("control")) then
                tool = t
            elseif style == "Gun" and (n:find("gun") or n:find("slingshot") or n:find("pistol") or n:find("rifle") or n:find("bizarre")) then
                tool = t
            end
            if tool then break end
        end
    end
    if not tool then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then tool = t break end
        end
    end
    if tool and tool.Parent ~= char then
        pcall(function() tool.Parent = char end)
    end
end

local function fireSkills()
    for _, key in ipairs({"Z","X","C","V","F"}) do
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        end)
        task.wait(0.08)
    end
end

local function attackMob(mob)
    if not mob then return end
    local myRoot = getRoot()
    local mobRoot = mob:FindFirstChild("HumanoidRootPart")
    if not myRoot or not mobRoot then return end

    myRoot.CFrame = CFrame.lookAt(myRoot.Position, mobRoot.Position)
    equipToolForStyle(Config.AttackStyle)

    -- Mass-damage mode: expand hitbox client-side before firing
    if Config.MassDamage then
        local char = LP.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                    d.Size = d.Size + Vector3.new(Config.MassRange, Config.MassRange, Config.MassRange)
                end
            end
        end
    end

    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)

    if Config.SkillCooldowns then fireSkills() end
end

-- ═══════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════
local function farmLoop()
    while State.Running do
        local mySession = State.Session
        local lv = getLevel()
        local questInfo = pickQuestForLevel(lv)
        State.CurrentQuest = questInfo

        if Config.AutoQuest and not hasQuest() then
            acceptQuest(questInfo)
            task.wait(1)
        end

        local mob, dist = findMob(questInfo.mobs)
        if mob then
            State.Target = mob
            local myRoot = getRoot()
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if myRoot and mobRoot and dist > 8 then
                local dir = (mobRoot.Position - myRoot.Position).Unit
                myRoot.CFrame = myRoot.CFrame + dir * math.min(dist - 4, 15)
            end
            attackMob(mob)
        elseif Config.BringMobs then
            local myRoot = getRoot()
            if myRoot then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        local root = obj:FindFirstChild("HumanoidRootPart")
                        if hum and root and hum.Health > 0 then
                            local matched = false
                            for _, mn in ipairs(questInfo.mobs) do
                                if obj.Name:find(mn, 1, true) then matched = true break end
                            end
                            if matched then
                                local d = (root.Position - myRoot.Position).Magnitude
                                if d <= Config.BringRadius then
                                    root.CFrame = myRoot.CFrame * CFrame.new(0, 0, -6)
                                end
                            end
                        end
                    end
                end
            end
        end

        if Config.AutoNextQuest then
            local newLv = getLevel()
            if newLv > lv then
                notify("Blox Farm", "Level up! " .. newLv, 2)
            end
        end

        if State.Session ~= mySession then break end
        task.wait(Config.AutoClickDelay)
    end
end

-- ═══════════════════════════════════════════════
-- UI (minimizable)
-- ═══════════════════════════════════════════════
local UI = {}

local function createUI()
    local g = Instance.new("ScreenGui")
    g.Name = "KAKU_BloxFarm2026"
    g.ResetOnSpawn = false
    g.Parent = LP:WaitForChild("PlayerGui")
    UI.ScreenGui = g

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 270, 0, 460)
    Main.Position = UDim2.new(0, 20, 0, 80)
    Main.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = g
    UI.Main = Main
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 38)
    Title.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    Title.Text = "  KAKU Blox Farm 2026"
    Title.TextColor3 = Color3.fromRGB(230, 230, 245)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 15
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Main
    Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

    -- Minimize button
    local Min = Instance.new("TextButton")
    Min.Size = UDim2.new(0, 30, 0, 30)
    Min.Position = UDim2.new(1, -36, 0, 4)
    Min.BackgroundColor3 = Color3.fromRGB(50, 50, 68)
    Min.Text = "—"
    Min.TextColor3 = Color3.fromRGB(220, 220, 240)
    Min.Font = Enum.Font.GothamBold
    Min.TextSize = 16
    Min.Parent = Title
    Instance.new("UICorner", Min).CornerRadius = UDim.new(0, 6)

    -- Content container
    local Body = Instance.new("Frame")
    Body.Size = UDim2.new(1, 0, 1, -38)
    Body.Position = UDim2.new(0, 0, 0, 38)
    Body.BackgroundTransparency = 1
    Body.Parent = Main
    UI.Body = Body

    -- Minimize toggle
    local minState = false
    Min.MouseButton1Click:Connect(function()
        minState = not minState
        Config.Minimized = minState
        Body.Visible = not minState
        Main.Size = minState and UDim2.new(0, 270, 0, 38) or UDim2.new(0, 270, 0, 460)
        Min.Text = minState and "+" or "—"
    end)

    -- Close button
    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 30, 0, 30)
    Close.Position = UDim2.new(1, -70, 0, 4)
    Close.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
    Close.Text = "X"
    Close.TextColor3 = Color3.fromRGB(255, 220, 220)
    Close.Font = Enum.Font.GothamBold
    Close.TextSize = 14
    Close.Parent = Title
    Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)

    Close.MouseButton1Click:Connect(function()
        g.Enabled = false
        UI.Closed = true
    end)

    -- Floating reopen button (appears when closed)
    local Reopen = Instance.new("TextButton")
    Reopen.Size = UDim2.new(0, 50, 0, 50)
    Reopen.Position = UDim2.new(0, 20, 0, 80)
    Reopen.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
    Reopen.Text = "KAKU"
    Reopen.TextColor3 = Color3.fromRGB(255, 255, 255)
    Reopen.Font = Enum.Font.GothamBold
    Reopen.TextSize = 12
    Reopen.Visible = false
    Reopen.Parent = g
    Instance.new("UICorner", Reopen).CornerRadius = UDim.new(0, 25)

    Reopen.MouseButton1Click:Connect(function()
        g.Enabled = true
        UI.Closed = false
        Reopen.Visible = false
    end)

    -- Hide reopen when gui is enabled
    g:GetPropertyChangedSignal("Enabled"):Connect(function()
        Reopen.Visible = not g.Enabled
    end)

    -- Button factory
    local yPos = 10
    local function makeButton(text, onClick, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 36)
        btn.Position = UDim2.new(0.05, 0, 0, yPos)
        btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 60)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(230, 230, 245)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = Body
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        yPos = yPos + 42
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    local function makeToggle(text, default, onChange)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(0.9, 0, 0, 30)
        row.Position = UDim2.new(0.05, 0, 0, yPos)
        row.BackgroundTransparency = 1
        row.Parent = Body

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.25, 0, 0.85, 0)
        btn.Position = UDim2.new(0.75, 0, 0.075, 0)
        btn.BackgroundColor3 = default and Color3.fromRGB(40, 160, 90) or Color3.fromRGB(70, 70, 85)
        btn.Text = default and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local s = default
        btn.MouseButton1Click:Connect(function()
            s = not s
            btn.BackgroundColor3 = s and Color3.fromRGB(40, 160, 90) or Color3.fromRGB(70, 70, 85)
            btn.Text = s and "ON" or "OFF"
            onChange(s)
        end)
        yPos = yPos + 34
        return btn
    end

    -- Start/Stop
    local Toggle = makeButton("START FARM", function() end, Color3.fromRGB(40, 160, 90))
    Toggle.MouseButton1Click:Connect(function()
        State.Running = not State.Running
        if State.Running then
            State.Session = State.Session + 1
            Toggle.Text = "STOP FARM"
            Toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            notify("KAKU", "Farm ON. Lv " .. getLevel(), 2)
            task.spawn(farmLoop)
        else
            Toggle.Text = "START FARM"
            Toggle.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
            notify("KAKU", "Farm OFF.", 2)
        end
    end)

    -- Attack style cycle
    local Styles = {"Melee", "Sword", "BloxFruit", "Gun"}
    local si = 1
    for i, s in ipairs(Styles) do if s == Config.AttackStyle then si = i end end
    local StyleBtn = makeButton("Style: " .. Config.AttackStyle, function()
        si = si % #Styles + 1
        Config.AttackStyle = Styles[si]
        StyleBtn.Text = "Style: " .. Config.AttackStyle
    end)

    -- Toggles
    makeToggle("Auto Quest",        Config.AutoQuest,       function(v) Config.AutoQuest = v end)
    makeToggle("Auto Next Quest",   Config.AutoNextQuest,   function(v) Config.AutoNextQuest = v end)
    makeToggle("Bring Mobs",        Config.BringMobs,       function(v) Config.BringMobs = v end)
    makeToggle("Mass Damage",       Config.MassDamage,      function(v) Config.MassDamage = v end)
    makeToggle("Walk on Water",     Config.WalkOnWater,     function(v)
        Config.WalkOnWater = v
        applyWalkOnWater()
    end)
    makeToggle("Speed (120)",       false,                  function(v)
        Config._SpeedOn = v
        applySpeed()
    end)
    makeToggle("Safe Teleport",     Config.SafeTP,          function(v) Config.SafeTP = v end)
end

-- ═══════════════════════════════════════════════
-- CHARACTER RESPAWN HOOK
-- ═══════════════════════════════════════════════
LP.CharacterAdded:Connect(function()
    task.wait(2)
    applyWalkOnWater()
    applySpeed()
end)

-- ═══════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════
createUI()
notify("KAKU Blox Farm 2026", "Loaded. Lv " .. getLevel(), 3)
