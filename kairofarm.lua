--[[
    Blox Fruits Auto-Farm — kairo edition
    made by kairo dev
    Android Executor Build
    Max Level: 2800 | Sea 1 / 2 / 3 auto-detect
--]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP     = Players.LocalPlayer
local CommF  = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")

-- ═══════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════
local Config = {
    AttackStyle       = "Melee",
    AttackDelay       = 0.12,
    TargetMode        = "Nearest",
    BringMobs         = true,
    BringRadius       = 150,
    FarmMode          = "Normal",     -- "Normal" | "Up" | "Down"

    BaseWalkSpeed     = 16,
    SpeedValue        = 120,
    SpeedOn           = false,
    WalkOnWater       = false,
    SafeTP            = true,

    MassDamage        = false,
    MassRange         = 25,

    AutoQuest         = true,
    AutoNextQuest     = true,
    SkillSpam         = true,
}

-- ═══════════════════════════════════════════════
-- SEA DETECTION
-- ═══════════════════════════════════════════════
local function getSea()
    -- Sea determined by player's current map ID
    local ok, sea = pcall(function()
        local map = LP.Data:FindFirstChild("Map") or LP:FindFirstChild("Map")
        if map then return map.Value end
        -- fallback: read from PlayerGui or a shared value
        return LP:GetAttribute("Sea") or 1
    end)
    if ok and sea then return sea end

    -- Fallback: infer from current level
    local lv = 1
    pcall(function() lv = LP.Data.Level.Value end)
    if lv >= 1500 then return 3
    elseif lv >= 700 then return 2
    else return 1 end
end

-- ═══════════════════════════════════════════════
-- TELEPORT LOCATIONS PER SEA
-- ═══════════════════════════════════════════════
local Sea1Locs = {
    ["Starter Island"]  = Vector3.new(0, 10, 0),
    ["Marine Fort"]     = Vector3.new(-2600, 20, 1500),
    ["Kingdom of Rose"] = Vector3.new(-400, 30, 3500),
    ["Frost Island"]    = Vector3.new(1200, 30, -1200),
    ["Desert Island"]   = Vector3.new(1000, 30, 2500),
    ["Skylands"]        = Vector3.new(-800, 1000, -1800),
    ["Fountain City"]   = Vector3.new(5200, 50, 3200),
    ["Magma Village"]   = Vector3.new(-5000, 30, -3000),
}

local Sea2Locs = {
    ["Underwater City"] = Vector3.new(-4000, -200, 5000),
    ["Cursed Ship"]     = Vector3.new(900, 30, 3800),
    ["Haunted Castle"]  = Vector3.new(-9500, 100, 5900),
    ["Upper Skylands"]  = Vector3.new(-7800, 1500, -5500),
    ["Hydra Island"]    = Vector3.new(5600, 60, -2200),
    ["Great Tree"]      = Vector3.new(2700, 100, -500),
    ["Castle on Sea"]   = Vector3.new(-5000, 100, 3000),
}

local Sea3Locs = {
    ["Haunted Ship"]    = Vector3.new(-6500, 80, 4000),
    ["Cake Land"]       = Vector3.new(-1200, 80, -1000),
    ["Fishman Island"]  = Vector3.new(-3000, 50, -6000),
    ["Castle on Sea"]   = Vector3.new(-5000, 100, 3000),
    ["Great Tree"]      = Vector3.new(2700, 100, -500),
    ["Hydra Island"]    = Vector3.new(5600, 60, -2200),
    ["Port Town"]       = Vector3.new(-300, 40, 1500),
}

local SeaSwitch = {
    [1] = Vector3.new(0, 10, 0),
    [2] = Vector3.new(1000, 30, 2500),
    [3] = Vector3.new(-300, 40, 1500),
}

-- ═══════════════════════════════════════════════
-- QUEST DATA
-- ═══════════════════════════════════════════════
local QuestData = {
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
    {lv=625,  mobs={"Sea Soldier","Water Fighter"},           island="Underwater City"},
    {lv=750,  mobs={"Living Zombie","Demonic Soul"},          island="Cursed Ship"},
    {lv=1000, mobs={"Reborn Skeleton","Living Zombie"},       island="Haunted Castle"},
    {lv=1250, mobs={"Fighter","Sky Bandit"},                  island="Upper Skylands"},
    {lv=1500, mobs={"Dragon Crew Warrior","Dragon Crew Archer"}, island="Hydra Island"},
    {lv=1750, mobs={"Forest Pirate","Mythological Pirate"},   island="Great Tree"},
    {lv=2000, mobs={"Cursed Skeleton","Pirate Millionaire"},  island="Castle on Sea"},
    {lv=2250, mobs={"Ghost","Ghost [Lv. 2100]"},              island="Haunted Ship"},
    {lv=2450, mobs={"Candy Pirate","Candy Rebel"},            island="Cake Land"},
    {lv=2550, mobs={"Reborn Skeleton","Living Zombie"},       island="Haunted Castle"},
    {lv=2650, mobs={"Snow Lurker","Snow Trooper"},            island="Frost Island"},
    {lv=2700, mobs={"Pirate","Brute"},                        island="Kingdom of Rose"},
    {lv=2750, mobs={"Fishman","Fishman Captain"},             island="Fishman Island"},
    {lv=2800, mobs={"Cursed Skeleton","Pirate Millionaire"},  island="Castle on Sea"},
}

-- ═══════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════
local State = { Running = false, Target = nil, Session = 0 }

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

local function getRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function getHumanoid()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function hasQuest()
    local ok, has = pcall(function() return LP.PlayerGui.Main.Quest.Visible end)
    return ok and has or false
end

-- ═══════════════════════════════════════════════
-- WALK ON WATER / SPEED
-- ═══════════════════════════════════════════════
local function applyWalkOnWater()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Config.WalkOnWater then
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0) end
    else
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
    end
end

local function applySpeed()
    local hum = getHumanoid()
    if not hum then return end
    hum.WalkSpeed = Config.SpeedOn and Config.SpeedValue or Config.BaseWalkSpeed
end

-- ═══════════════════════════════════════════════
-- TELEPORT (staged, safe)
-- ═══════════════════════════════════════════════
local function teleportTo(pos)
    local myRoot = getRoot()
    if not myRoot then return end
    if Config.SafeTP then
        local startPos = myRoot.Position
        for i = 1, 8 do
            local t = i / 8
            myRoot.CFrame = CFrame.new(startPos:Lerp(pos, t))
            task.wait(0.05)
        end
    else
        myRoot.CFrame = CFrame.new(pos)
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
    local myRoot = getRoot()
    if not myRoot then return false end
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
            local nm = npc.Name
            if nm:find("Quest") or nm:find("Giver") or nm:find(questInfo.island) then
                local root = npc:FindFirstChild("HumanoidRootPart")
                myRoot.CFrame = root.CFrame * CFrame.new(0, 0, 5)
                task.wait(0.5)
                pcall(function() CommF:Invoke("CommF_", { "Quest", npc.Name }) end)
                task.wait(0.3)
                local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                if prompt then pcall(function() fireproximityprompt(prompt) end) end
                return true
            end
        end
    end
    return false
end

-- ═══════════════════════════════════════════════
-- TARGET DETECTION
-- ═══════════════════════════════════════════════
local function findTarget(mobNames)
    local myRoot = getRoot()
    if not myRoot then return nil end
    local best, bestVal = nil, math.huge

    if Config.TargetMode == "Player" then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local h = plr.Character:FindFirstChildOfClass("Humanoid")
                local r = plr.Character:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 then
                    local d = (r.Position - myRoot.Position).Magnitude
                    if d < bestVal then best, bestVal = plr.Character, d end
                end
            end
        end
        return best, bestVal
    end

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
                    if Config.TargetMode == "Lowest HP" then
                        if hum.Health < bestVal then best, bestVal = obj, hum.Health end
                    else
                        if d < bestVal then best, bestVal = obj, d end
                    end
                end
            end
        end
    end
    return best, bestVal
end

-- ═══════════════════════════════════════════════
-- COLLECT MOBS AROUND PLAYER
-- ═══════════════════════════════════════════════
local function collectMobs(mobNames)
    local myRoot = getRoot()
    if not myRoot then return 0 end
    local count = 0
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
                    if d <= Config.BringRadius then
                        root.CFrame = myRoot.CFrame * CFrame.new(0, 0, -6)
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

-- ═══════════════════════════════════════════════
-- TOOL + ATTACK
-- ═══════════════════════════════════════════════
local function equipToolForStyle(style)
    local char = LP.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    local tool = nil
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if style == "Melee" and (n:find("combat") or n:find("black leg") or n:find("electro") or n:find("dragon talon") or n:find("superhuman") or n:find("death step") or n:find("sanguine")) then
                tool = t
            elseif style == "Sword" and (n:find("sword") or n:find("blade") or n:find("katana") or n:find("cutlass") or n:find("saber") or n:find("cursed dual") or n:find("dark dagger") or n:find("trident")) then
                tool = t
            elseif style == "BloxFruit" and (n:find("fruit") or n:find("dragon") or n:find("kitsune") or n:find("leopard") or n:find("dough") or n:find("venom") or n:find("control") or n:find("portal") or n:find("mammoth")) then
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
    if tool and hum:GetChildren()[1] ~= tool then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.05)
    end
    return tool
end

local function realAttack(mob, tool)
    if not mob or not tool then return end
    local myRoot = getRoot()
    local mobRoot = mob:FindFirstChild("HumanoidRootPart")
    if not myRoot or not mobRoot then return end

    myRoot.CFrame = CFrame.lookAt(myRoot.Position, mobRoot.Position)

    if Config.MassDamage then
        local char = LP.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                    d.Size = Vector3.new(Config.MassRange, Config.MassRange, Config.MassRange)
                end
            end
        end
    end

    pcall(function() tool:Activate() end)
    pcall(function() CommF:Invoke("CommF_", { "Click" }) end)

    if Config.SkillSpam then
        for _, key in ipairs({"Z","X","C","V","F"}) do
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                task.wait(0.02)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
            end)
            task.wait(0.06)
        end
    end
end

-- ═══════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════
local function farmLoop()
    while State.Running do
        local mySession = State.Session
        local lv = getLevel()
        local questInfo = pickQuestForLevel(lv)

        if Config.AutoQuest and not hasQuest() then
            acceptQuest(questInfo)
            task.wait(1)
        end

        -- Collect nearby mobs every tick if enabled
        if Config.BringMobs then
            collectMobs(questInfo.mobs)
        end

        local mob, dist = findTarget(questInfo.mobs)
        if mob then
            State.Target = mob
            local myRoot = getRoot()
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if myRoot and mobRoot then
                -- Farm mode movement
                if Config.FarmMode == "Up" then
                    myRoot.CFrame = mobRoot.CFrame * CFrame.new(0, 8, 0)
                elseif Config.FarmMode == "Down" then
                    myRoot.CFrame = mobRoot.CFrame * CFrame.new(0, -6, 0)
                elseif dist > 12 then
                    local dir = (mobRoot.Position - myRoot.Position).Unit
                    myRoot.CFrame = myRoot.CFrame + dir * math.min(dist - 8, 15)
                end
            end
            local tool = equipToolForStyle(Config.AttackStyle)
            realAttack(mob, tool)
        end

        if State.Session ~= mySession then break end
        task.wait(Config.AttackDelay)
    end
end

-- ═══════════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════════
local function createUI()
    local g = Instance.new("ScreenGui")
    g.Name = "kairo_ui"
    g.ResetOnSpawn = false
    g.Parent = LP:WaitForChild("PlayerGui")

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 310, 0, 470)
    Main.Position = UDim2.new(0, 20, 0, 60)
    Main.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = g
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", Main).Color = Color3.fromRGB(60, 60, 90)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 42)
    Title.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    Title.Text = "  kairo farm"
    Title.TextColor3 = Color3.fromRGB(240, 240, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 15
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Main
    Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 12)

    local Min = Instance.new("TextButton")
    Min.Size = UDim2.new(0, 28, 0, 28)
    Min.Position = UDim2.new(1, -96, 0, 7)
    Min.BackgroundColor3 = Color3.fromRGB(50, 50, 68)
    Min.Text = "—"
    Min.TextColor3 = Color3.fromRGB(220, 220, 240)
    Min.Font = Enum.Font.GothamBold
    Min.TextSize = 16
    Min.Parent = Title
    Instance.new("UICorner", Min).CornerRadius = UDim.new(0, 6)

    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 28, 0, 28)
    Close.Position = UDim2.new(1, -34, 0, 7)
    Close.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
    Close.Text = "X"
    Close.TextColor3 = Color3.fromRGB(255, 220, 220)
    Close.Font = Enum.Font.GothamBold
    Close.TextSize = 14
    Close.Parent = Title
    Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -80)
    Scroll.Position = UDim2.new(0, 0, 0, 44)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 6
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 110)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.Parent = Main

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Scroll

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 8)
    Pad.PaddingLeft = UDim.new(0, 8)
    Pad.PaddingRight = UDim.new(0, 8)
    Pad.PaddingBottom = UDim.new(0, 8)
    Pad.Parent = Scroll

    local Credit = Instance.new("TextLabel")
    Credit.Size = UDim2.new(1, 0, 0, 22)
    Credit.Position = UDim2.new(0, 0, 1, -24)
    Credit.BackgroundTransparency = 1
    Credit.Text = "made by kairo dev"
    Credit.TextColor3 = Color3.fromRGB(140, 140, 170)
    Credit.Font = Enum.Font.GothamMedium
    Credit.TextSize = 11
    Credit.Parent = Main

    local function makeCategory(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  " .. text
        lbl.TextColor3 = Color3.fromRGB(120, 200, 255)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = Scroll
    end

    local function makeButton(text, callback, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = color or Color3.fromRGB(40, 40, 56)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(230, 230, 245)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = Scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local function makeToggle(text, default, onChange)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundTransparency = 1
        row.Parent = Scroll

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
        btn.Size = UDim2.new(0.24, 0, 0.85, 0)
        btn.Position = UDim2.new(0.76, 0, 0.075, 0)
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
        return btn
    end

    local function makeDropdown(text, options, onChange)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundTransparency = 1
        row.Parent = Scroll

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        btn.Text = text .. ": " .. options[1]
        btn.TextColor3 = Color3.fromRGB(230, 230, 245)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local idx = 1
        btn.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            btn.Text = text .. ": " .. options[idx]
            onChange(options[idx])
        end)
        return btn
    end

    -- ─── FARM ───
    makeCategory("FARM")
    local StartBtn = makeButton("START FARM", function() end, Color3.fromRGB(40, 160, 90))
    StartBtn.MouseButton1Click:Connect(function()
        State.Running = not State.Running
        if State.Running then
            State.Session = State.Session + 1
            StartBtn.Text = "STOP FARM"
            StartBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            notify("kairo", "Farm ON. Lv " .. getLevel(), 2)
            task.spawn(farmLoop)
        else
            StartBtn.Text = "START FARM"
            StartBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
            notify("kairo", "Farm OFF.", 2)
        end
    end)
    makeDropdown("Style", {"Melee","Sword","BloxFruit","Gun"}, function(v) Config.AttackStyle = v end)
    makeDropdown("Target", {"Nearest","Lowest HP","Player"}, function(v) Config.TargetMode = v end)
    makeDropdown("Farm Mode", {"Normal","Up","Down"}, function(v) Config.FarmMode = v end)

    -- ─── QUEST ───
    makeCategory("QUEST")
    makeToggle("Auto Quest",      Config.AutoQuest,     function(v) Config.AutoQuest = v end)
    makeToggle("Auto Next Quest", Config.AutoNextQuest, function(v) Config.AutoNextQuest = v end)

    -- ─── COMBAT ───
    makeCategory("COMBAT")
    makeToggle("Collect Mobs", Config.BringMobs,  function(v) Config.BringMobs = v end)
    makeToggle("Mass Damage",  Config.MassDamage, function(v) Config.MassDamage = v end)
    makeToggle("Skill Spam",   Config.SkillSpam,  function(v) Config.SkillSpam = v end)

    -- ─── MOVEMENT ───
    makeCategory("MOVEMENT")
    makeToggle("Walk on Water", Config.WalkOnWater, function(v)
        Config.WalkOnWater = v
        applyWalkOnWater()
    end)
    makeToggle("Speed (120)", Config.SpeedOn, function(v)
        Config.SpeedOn = v
        applySpeed()
    end)
    makeToggle("Safe Teleport", Config.SafeTP, function(v) Config.SafeTP = v end)

    -- ─── SEA / TELEPORT ───
    makeCategory("SEA")
    local currentSea = getSea()
    local SeaLabel = Instance.new("TextLabel")
    SeaLabel.Size = UDim2.new(1, 0, 0, 22)
    SeaLabel.BackgroundTransparency = 1
    SeaLabel.Text = "  Detected: Sea " .. currentSea
    SeaLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
    SeaLabel.Font = Enum.Font.GothamMedium
    SeaLabel.TextSize = 11
    SeaLabel.TextXAlignment = Enum.TextXAlignment.Left
    SeaLabel.Parent = Scroll

    -- Teleport to sea switch points
    makeButton("Teleport to Sea 1", function()
        if currentSea < 1 then return end
        notify("kairo", "Teleporting to Sea 1", 2)
        task.spawn(function() teleportTo(SeaSwitch[1]) end)
    end, Color3.fromRGB(50, 70, 120))
    makeButton("Teleport to Sea 2", function()
        if currentSea < 2 then notify("kairo", "Sea 2 locked", 2) return end
        notify("kairo", "Teleporting to Sea 2", 2)
        task.spawn(function() teleportTo(SeaSwitch[2]) end)
    end, Color3.fromRGB(50, 90, 130))
    makeButton("Teleport to Sea 3", function()
        if currentSea < 3 then notify("kairo", "Sea 3 locked", 2) return end
        notify("kairo", "Teleporting to Sea 3", 2)
        task.spawn(function() teleportTo(SeaSwitch[3]) end)
    end, Color3.fromRGB(50, 110, 140))

    -- Location teleport within sea
    makeCategory("LOCATIONS")
    local locs = currentSea == 3 and Sea3Locs or (currentSea == 2 and Sea2Locs or Sea1Locs)
    local names = {}
    for k, _ in pairs(locs) do table.insert(names, k) end
    table.sort(names)
    local selected = names[1]
    makeDropdown("Location", names, function(v) selected = v end)
    makeButton("Teleport Now", function()
        local pos = locs[selected]
        if pos then
            notify("kairo", "Teleporting to " .. selected, 2)
            task.spawn(function() teleportTo(pos) end)
        end
    end, Color3.fromRGB(60, 100, 180))

    -- ─── MIN / CLOSE ───
    local minState = false
    Min.MouseButton1Click:Connect(function()
        minState = not minState
        Scroll.Visible = not minState
        Credit.Visible = not minState
        Main.Size = minState and UDim2.new(0, 310, 0, 42) or UDim2.new(0, 310, 0, 470)
        Min.Text = minState and "+" or "—"
    end)
    Close.MouseButton1Click:Connect(function() g.Enabled = false end)

    local Reopen = Instance.new("TextButton")
    Reopen.Size = UDim2.new(0, 52, 0, 52)
    Reopen.Position = UDim2.new(0, 20, 0, 60)
    Reopen.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
    Reopen.Text = "kairo"
    Reopen.TextColor3 = Color3.fromRGB(255, 255, 255)
    Reopen.Font = Enum.Font.GothamBold
    Reopen.TextSize = 12
    Reopen.Visible = false
    Reopen.Parent = g
    Instance.new("UICorner", Reopen).CornerRadius = UDim.new(0, 26)
    Reopen.MouseButton1Click:Connect(function()
        g.Enabled = true
        Reopen.Visible = false
    end)
    g:GetPropertyChangedSignal("Enabled"):Connect(function()
        Reopen.Visible = not g.Enabled
    end)
end

LP.CharacterAdded:Connect(function()
    task.wait(2)
    applyWalkOnWater()
    applySpeed()
end)

createUI()
notify("kairo", "Loaded. Lv " .. getLevel() .. " | Sea " .. getSea(), 3)
