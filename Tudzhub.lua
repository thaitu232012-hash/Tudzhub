-- Tú bloxfruits
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local runService = game:GetService("RunService")
local virtualInput = game:GetService("VirtualInputManager")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local httpService = game:GetService("HttpService")
local userInputService = game:GetService("UserInputService")
local teleportService = game:GetService("TeleportService")

-- ANTI-BAN + TỐI ƯU 
pcall(function()
    game:GetService("NetworkClient"):SetOutgoingKBPSLimit(999999)
    settings().Network.AllowSleep = false
    setfflag("HumanoidVerticalVelocity", true)
end)

-- KIỂM TRA GAME BLOX FRUITS
if game.PlaceId ~= 2753915549 and game.PlaceId ~= 4442272183 and game.PlaceId ~= 7449423635 then
    print("Game không hỗ trợ. Chỉ chạy trên Blox Fruits.")
    return
end

-- ====== THAM SỐ ======
local Settings = {
    TweenSpeed = 350,
    BypassTeleport = true,
    UpY = false,
    SameY = false
}

-- ====== BIẾN TRẠNG THÁI ======
local status = {
    farm = false,
    boss = false,
    raid = false,
    magnet = false,
    teleport = false,
    fruit = false,
    event = false,
    beli = false,
    stats = false,
    sell = false,
    sea = false,
    race = false,
    raceAutoUp = false
}
local shouldTween = true
local _B = true -- Dùng cho BringEnemy

-- ====== HÀM FARM CỦA W-AZEOX (GIỮ NGUYÊN) ======
local function getMonster(includeBoss, includeEvent)
    local list = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            local name = v.Name:lower()
            if name:find("marine") or name:find("pirate") or name:find("bandit") or name:find("skeleton") or name:find("zombie") or name:find("snow") then
                table.insert(list, v)
            end
            if includeBoss and (name:find("boss") or name:find("dragon") or name:find("law") or name:find("doffy") or name:find("rayleigh") or name:find("mihawk")) then
                table.insert(list, v)
            end
            if includeEvent and (name:find("event") or name:find("halloween") or name:find("christmas") or name:find("gift")) then
                table.insert(list, v)
            end
        end
    end
    if #list == 0 then return nil end
    table.sort(list, function(a, b)
        local d1 = a.HumanoidRootPart and a.HumanoidRootPart.Position:Distance(root.Position) or math.huge
        local d2 = b.HumanoidRootPart and b.HumanoidRootPart.Position:Distance(root.Position) or math.huge
        return d1 < d2
    end)
    return list[1]
end

local function getMagnet()
    local best = nil
    local bestDist = math.huge
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("magnet") or v.Name:lower():find("fragment") or v.Name:lower():find("beli") or v.Name:lower():find("gem")) then
            local dist = v.Position:Distance(root.Position)
            if dist < bestDist then
                bestDist = dist
                best = v
            end
        end
    end
    return best
end

-- HÀM TẤN CÔNG (GIỐNG W-AZEOX)
local function attack(target)
    pcall(function()
        local t = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
        if t then
            root.CFrame = t.CFrame * CFrame.new(0, 0, -5)
            wait(0.06)
            virtualInput:SendKeyEvent(true, "J", false, game)
            wait(0.06)
            virtualInput:SendKeyEvent(false, "J", false, game)
            for i = 1, 5 do
                virtualInput:SendKeyEvent(true, tostring(i), false, game)
                wait(0.03)
                virtualInput:SendKeyEvent(false, tostring(i), false, game)
            end
            virtualInput:SendKeyEvent(true, "Z", false, game)
            wait(0.04)
            virtualInput:SendKeyEvent(false, "Z", false, game)
            virtualInput:SendKeyEvent(true, "X", false, game)
            wait(0.04)
            virtualInput:SendKeyEvent(false, "X", false, game)
        end
    end)
end

-- ====== HÀM TELEPORT BYPASS (CỦA W-AZEOX) ======
local block = Instance.new("Part", workspace)
block.Size = Vector3.new(1, 1, 1)
block.Name = "DeAnhTuBlock"
block.Anchored = true
block.CanCollide = false
block.CanTouch = false
block.Transparency = 1

task.spawn(function()
    while task.wait() do
        if block and block.Parent == workspace then
            if shouldTween then
                getgenv().OnFarm = true
            else
                getgenv().OnFarm = false
            end
        else
            getgenv().OnFarm = false
        end
    end
end)

task.spawn(function()
    local a = game.Players.LocalPlayer
    repeat task.wait() until a.Character and a.Character.PrimaryPart
    block.CFrame = a.Character.PrimaryPart.CFrame
    while task.wait() do
        pcall(function()
            if getgenv().OnFarm then
                if block and block.Parent == workspace then
                    local b = a.Character and a.Character.PrimaryPart
                    if b and (b.Position - block.Position).Magnitude <= 200 then
                        b.CFrame = block.CFrame
                    else
                        block.CFrame = b.CFrame
                    end
                end
                local c = a.Character
                if c then
                    for d, e in pairs(c:GetChildren()) do
                        if e:IsA("BasePart") then e.CanCollide = false end
                    end
                end
            else
                local c = a.Character
                if c then
                    for d, e in pairs(c:GetChildren()) do
                        if e:IsA("BasePart") then e.CanCollide = true end
                    end
                end
            end
        end)
    end
end)

local function _tp(target)
    local gg
    if typeof(target) == "Vector3" then
        gg = CFrame.new(target)
    elseif typeof(target) == "CFrame" then
        gg = target
    else
        gg = target and target.CFrame
    end
    if not gg then return end

    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = character.HumanoidRootPart

    pcall(function()
        if Settings.BypassTeleport then
            local spawns = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("PlayerSpawns")
            if spawns then
                local bestSpawn = nil
                local bestDist = math.huge
                for _, spawn in pairs(spawns:GetDescendants()) do
                    if spawn:IsA("Model") and spawn:FindFirstChild("Part") then
                        local dist = (spawn.Part.Position - gg.Position).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            bestSpawn = spawn
                        end
                    end
                end
                if bestSpawn and bestDist < (gg.Position - rootPart.Position).Magnitude then
                    rootPart.CFrame = bestSpawn.Part.CFrame
                    task.wait(0.3)
                end
            end
        end
    end)

    local distance = (gg.Position - rootPart.Position).Magnitude
    local tweenInfo = TweenInfo.new(distance / Settings.TweenSpeed, Enum.EasingStyle.Linear)
    local tween = tweenService:Create(block, tweenInfo, {CFrame = gg})

    if humanoid.Sit == true then
        block.CFrame = CFrame.new(block.Position.X, gg.Y, block.Position.Z)
    end

    tween:Play()
    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if not shouldTween then
                tween:Cancel()
                break
            end
            task.wait(0.1)
        end
    end)
    return tween
end

local function teleport(pos)
    if shouldTween then
        _tp(pos)
    else
        pcall(function()
            if type(pos) == "CFrame" then
                root.CFrame = pos * CFrame.new(0, 0, -2)
            elseif type(pos) == "Vector3" then
                root.CFrame = CFrame.new(pos) * CFrame.new(0, 0, -2)
            elseif type(pos) == "Instance" then
                local p = pos:FindFirstChild("HumanoidRootPart") or pos:FindFirstChild("Torso")
                if p then root.CFrame = p.CFrame * CFrame.new(0, 0, -2) end
            end
            wait(0.1)
        end)
    end
end

-- ====== VÒNG LẶP CHÍNH (GIỮ NGUYÊN CƠ CHẾ W-AZEOX) ======
spawn(function()
    while true do
        wait(0.15)
        if status.farm then
            local target = getMonster(false, false)
            if target then 
                attack(target)
                -- Bring Enemy (giống W-Azeox, giữ quái ở gần)
                pcall(function()
                    if target and target:FindFirstChild("HumanoidRootPart") then
                        target.HumanoidRootPart.CanCollide = false
                        target.Humanoid.WalkSpeed = 0
                        target.Humanoid.JumpPower = 0
                    end
                end)
            end
        end
        if status.boss then
            local target = getMonster(true, false)
            if target then attack(target) end
        end
        if status.raid then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and (v.Name:lower():find("portal") or v.Name:lower():find("raid")) then
                    local p = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
                    if p then
                        teleport(p)
                        wait(0.2)
                        virtualInput:SendKeyEvent(true, "E", false, game)
                        wait(0.1)
                        virtualInput:SendKeyEvent(false, "E", false, game)
                    end
                end
            end
        end
        if status.magnet then
            local item = getMagnet()
            if item then
                teleport(item)
                wait(0.06)
                virtualInput:SendKeyEvent(true, "E", false, game)
                wait(0.06)
                virtualInput:SendKeyEvent(false, "E", false, game)
            end
        end
        if status.teleport then
            local target = getMonster(false, false) or getMonster(true, false)
            if target then teleport(target) end
        end
        if status.fruit then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and (v.Name:lower():find("fruit") or v.Name:lower():find("apple") or v.Name:lower():find("buddha")) then
                    teleport(v)
                    wait(0.2)
                    virtualInput:SendKeyEvent(true, "E", false, game)
                    wait(0.1)
                    virtualInput:SendKeyEvent(false, "E", false, game)
                    break
                end
            end
        end
        if status.event then
            local target = getMonster(false, true) or getMonster(true, true)
            if target then
                teleport(target)
                wait(0.2)
                if target:FindFirstChild("Humanoid") then
                    attack(target)
                else
                    virtualInput:SendKeyEvent(true, "E", false, game)
                    wait(0.1)
                    virtualInput:SendKeyEvent(false, "E", false, game)
                end
            end
        end
        if status.beli then
            local target = getMonster(false, false)
            if target then attack(target) end
            local item = getMagnet()
            if item then
                teleport(item)
                wait(0.06)
                virtualInput:SendKeyEvent(true, "E", false, game)
                wait(0.06)
                virtualInput:SendKeyEvent(false, "E", false, game)
            end
        end
        if status.stats then
            pcall(function()
                for _, s in pairs({"Melee", "Defense", "Sword", "Fruit", "Gun"}) do
                    replicatedStorage:WaitForChild("Remotes"):WaitForChild("StatIncrease"):InvokeServer(s)
                    wait(0.4)
                end
            end)
        end
        if status.sell then
            pcall(function()
                for _, v in pairs(player.Backpack:GetChildren()) do
                    if v:IsA("Tool") then
                        replicatedStorage:WaitForChild("Remotes"):WaitForChild("Sell"):InvokeServer(v)
                        wait(0.3)
                    end
                end
            end)
        end
        if status.sea then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and (v.Name:lower():find("seabeast") or v.Name:lower():find("sea beast")) then
                    local p = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
                    if p then
                        teleport(p)
                        wait(0.2)
                        attack(v)
                    end
                end
            end
        end
        if status.race then
            local target = getMonster(false, false)
            if target then 
                attack(target)
                pcall(function()
                    local progress = player:FindFirstChild("RaceProgress") or player:FindFirstChild("Data") and player.Data:FindFirstChild("RaceProgress")
                    if progress and progress.Value >= 100 then
                        replicatedStorage:WaitForChild("Remotes"):WaitForChild("UpgradeRace"):InvokeServer()
                        wait(0.5)
                    end
                end)
            end
        end
        if status.raceAutoUp then
            pcall(function()
                replicatedStorage:WaitForChild("Remotes"):WaitForChild("UpgradeRace"):InvokeServer()
                wait(0.5)
            end)
        end
    end
end)

-- ====== HÀM TỰ ĐỘNG CẬP NHẬT ======
local function autoUpdate()
    pcall(function()
        local currentVersion = "V6.0"
        local url = "https://raw.githubusercontent.com/thaitu232012-hash/Tudzhub/main/version.txt"
        local newVersion = game:HttpGet(url)
        if newVersion and newVersion ~= currentVersion then
            print("Địt mẹ mày, có bản cập nhật mới. Tải về...")
            local newScript = game:HttpGet("https://raw.githubusercontent.com/thaitu232012-hash/Tudzhub/main/Tudzhub.lua")
            if newScript then
                loadstring(newScript)()
                return
            end
        end
    end)
end

-- ====== GUI FLUENT (NHƯNG BỎ HOTKEY) ======
local Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-modded/releases/download/1.5.1/FluentPro"))()
Fluent:SetTheme("Dark")

local Window = Fluent:CreateWindow({
    Title = "ĐỆ ANH TÚ HUB V6",
    SubTitle = "Bấm nút là chạy - Farm như W-Azeox",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 440),
    Acrylic = false,
    Theme = "Dark",
})

local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "rbxassetid://7733960981" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "lucide/locate" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "lucide/waves" }),
    Race = Window:AddTab({ Title = "Race", Icon = "rbxassetid://11162889532" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "lucide/info" })
}

-- ====== TAB FARM (BẤM NÚT LÀ CHẠY) ======
Tabs.Farm:AddSection("Auto Farm - Bấm nút bật/tắt")

local farmToggle = Tabs.Farm:AddToggle("⚔️ Auto Farm", { Title = "Farm quái thường", Default = false })
farmToggle:OnChanged(function(value) 
    status.farm = value 
    if value then print("Đã bật Farm, địt mẹ mày.") else print("Đã tắt Farm.") end
end)

local bossToggle = Tabs.Farm:AddToggle("👑 Auto Boss", { Title = "Farm Boss", Default = false })
bossToggle:OnChanged(function(value) 
    status.boss = value 
    if value then print("Đã bật Boss.") end
end)

local raidToggle = Tabs.Farm:AddToggle("🚪 Auto Raid", { Title = "Tự động vào Raid", Default = false })
raidToggle:OnChanged(function(value) 
    status.raid = value 
    if value then print("Đã bật Raid.") end
end)

local magnetToggle = Tabs.Farm:AddToggle("🧲 Auto Magnet", { Title = "Nhặt Magnet/Fragment", Default = false })
magnetToggle:OnChanged(function(value) 
    status.magnet = value 
    if value then print("Đã bật Magnet.") end
end)

-- ====== TAB TELEPORT ======
Tabs.Teleport:AddSection("Teleport - Bấm là bay")
local tpLocations = {
    {"🏝 Jungle", Vector3.new(-2000, 100, 1000)},
    {"🏜 Desert", Vector3.new(-3000, 100, 2000)},
    {"❄ Snow", Vector3.new(2000, 100, -2000)},
    {"🌋 Volcano", Vector3.new(3000, 100, -1000)},
    {"☁ Sky", Vector3.new(0, 500, 0)},
    {"🌊 Sea", Vector3.new(0, 0, 3000)}
}
for _, loc in pairs(tpLocations) do
    Tabs.Teleport:AddButton(loc[1], function() 
        teleport(loc[2]) 
        print("Đã teleport đến " .. loc[1])
    end)
end

-- ====== TAB UTILITY ======
Tabs.Utility:AddSection("Utility")
local fruitToggle = Tabs.Utility:AddToggle("🍎 Auto Fruit", { Title = "Tìm và nhặt Fruit", Default = false })
fruitToggle:OnChanged(function(value) status.fruit = value end)

local eventToggle = Tabs.Utility:AddToggle("🎁 Auto Event", { Title = "Sự kiện", Default = false })
eventToggle:OnChanged(function(value) status.event = value end)

local beliToggle = Tabs.Utility:AddToggle("💰 Auto Beli", { Title = "Farm Beli", Default = false })
beliToggle:OnChanged(function(value) status.beli = value end)

local statsToggle = Tabs.Utility:AddToggle("📈 Auto Stats", { Title = "Tự nâng Stats", Default = false })
statsToggle:OnChanged(function(value) status.stats = value end)

local sellToggle = Tabs.Utility:AddToggle("🛒 Auto Sell", { Title = "Tự bán đồ", Default = false })
sellToggle:OnChanged(function(value) status.sell = value end)

local seaToggle = Tabs.Utility:AddToggle("🐉 Auto Sea Beast", { Title = "Farm Sea Beast", Default = false })
seaToggle:OnChanged(function(value) status.sea = value end)

-- ====== TAB RACE ======
Tabs.Race:AddSection("Race (Tộc)")
local raceToggle = Tabs.Race:AddToggle("🧬 Auto Farm Race", { Title = "Farm điểm tộc", Default = false })
raceToggle:OnChanged(function(value) status.race = value end)

local raceUpToggle = Tabs.Race:AddToggle("⬆️ Auto Upgrade Race", { Title = "Tự nâng tộc", Default = false })
raceUpToggle:OnChanged(function(value) status.raceAutoUp = value end)

Tabs.Race:AddButton("🔁 Reset Race", function()
    pcall(function()
        replicatedStorage:WaitForChild("Remotes"):WaitForChild("ResetRace"):InvokeServer()
        print("Reset Race thành công, địt mẹ mày.")
    end)
end)

-- ====== TAB SETTINGS ======
Tabs.Settings:AddSection("Cài đặt")
local tweenToggle = Tabs.Settings:AddToggle("🚀 Bật Tween (Bay nhanh)", { Title = "Tween", Default = true })
tweenToggle:OnChanged(function(value) 
    shouldTween = value 
    if value then print("Bật Tween.") else print("Tắt Tween.") end
end)

Tabs.Settings:AddButton("❌ Đóng GUI", function()
    Window:Destroy()
    for k, v in pairs(status) do status[k] = false end
    print("Đã đóng GUI, địt mẹ mày.")
end)

Tabs.Settings:AddParagraph("Thông tin", { Title = "Version", Content = "V6.0 - Bấm nút chạy, Farm như W-Azeox" })

-- ====== KHÔNG CÓ HOTKEY, CHỈ BẤM NÚT ======

-- ====== ANTI-BAN (GIỐNG W-AZEOX) ======
spawn(function()
    while true do
        if not status.farm and not status.boss and not status.ra
