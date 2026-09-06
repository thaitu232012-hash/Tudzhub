-- Tudzhub
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local VirtualInput = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

-- ====== CÀI ĐẶT ======
local Settings = {
    TweenSpeed = 350,
    BypassTP = true,
    UpY = false,
    SameY = false
}

-- ====== BIẾN ======
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

-- ====== HÀM CHÍNH ======
local function getMonster(includeBoss, includeEvent)
    local list = {}
    for _, v in pairs(Workspace:GetDescendants()) do
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
    for _, v in pairs(Workspace:GetDescendants()) do
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

local function attack(target)
    pcall(function()
        local t = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
        if t then
            root.CFrame = t.CFrame * CFrame.new(0, 0, -5)
            task.wait(0.06)
            VirtualInput:SendKeyEvent(true, "J", false, game)
            task.wait(0.06)
            VirtualInput:SendKeyEvent(false, "J", false, game)
            for i = 1, 5 do
                VirtualInput:SendKeyEvent(true, tostring(i), false, game)
                task.wait(0.03)
                VirtualInput:SendKeyEvent(false, tostring(i), false, game)
            end
            VirtualInput:SendKeyEvent(true, "Z", false, game)
            task.wait(0.04)
            VirtualInput:SendKeyEvent(false, "Z", false, game)
            VirtualInput:SendKeyEvent(true, "X", false, game)
            task.wait(0.04)
            VirtualInput:SendKeyEvent(false, "X", false, game)
        end
    end)
end

local block = Instance.new("Part", Workspace)
block.Size = Vector3.new(1, 1, 1)
block.Name = "TudzhubBlock"
block.Anchored = true
block.CanCollide = false
block.CanTouch = false
block.Transparency = 1

task.spawn(function()
    while task.wait() do
        if block and block.Parent == Workspace then
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
                if block and block.Parent == Workspace then
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

local function teleport(pos)
    if shouldTween then
        pcall(function()
            local targetCF = pos
            if type(pos) == "Vector3" then targetCF = CFrame.new(pos) end
            if type(pos) == "CFrame" then targetCF = pos end
            if type(pos) == "Instance" then
                local p = pos:FindFirstChild("HumanoidRootPart") or pos:FindFirstChild("Torso")
                if p then targetCF = p.CFrame end
            end
            local distance = (targetCF.Position - root.Position).Magnitude
            local tweenInfo = TweenInfo.new(distance / Settings.TweenSpeed, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(block, tweenInfo, {CFrame = targetCF})
            tween:Play()
            task.spawn(function()
                while tween.PlaybackState == Enum.PlaybackState.Playing do
                    if not shouldTween then tween:Cancel() break end
                    task.wait(0.1)
                end
            end)
        end)
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
            task.wait(0.1)
        end)
    end
end

-- VÒNG LẶP CHÍNH
task.spawn(function()
    while true do
        task.wait(0.15)
        if status.farm then
            local target = getMonster(false, false)
            if target then attack(target) end
        end
        if status.boss then
            local target = getMonster(true, false)
            if target then attack(target) end
        end
        if status.raid then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and (v.Name:lower():find("portal") or v.Name:lower():find("raid")) then
                    local p = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
                    if p then
                        teleport(p)
                        task.wait(0.2)
                        VirtualInput:SendKeyEvent(true, "E", false, game)
                        task.wait(0.1)
                        VirtualInput:SendKeyEvent(false, "E", false, game)
                    end
                end
            end
        end
        if status.magnet then
            local item = getMagnet()
            if item then
                teleport(item)
                task.wait(0.06)
                VirtualInput:SendKeyEvent(true, "E", false, game)
                task.wait(0.06)
                VirtualInput:SendKeyEvent(false, "E", false, game)
            end
        end
        if status.teleport then
            local target = getMonster(false, false) or getMonster(true, false)
            if target then teleport(target) end
        end
        if status.fruit then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and (v.Name:lower():find("fruit") or v.Name:lower():find("apple") or v.Name:lower():find("buddha")) then
                    teleport(v)
                    task.wait(0.2)
                    VirtualInput:SendKeyEvent(true, "E", false, game)
                    task.wait(0.1)
                    VirtualInput:SendKeyEvent(false, "E", false, game)
                    break
                end
            end
        end
        if status.event then
            local target = getMonster(false, true) or getMonster(true, true)
            if target then
                teleport(target)
                task.wait(0.2)
                if target:FindFirstChild("Humanoid") then
                    attack(target)
                else
                    VirtualInput:SendKeyEvent(true, "E", false, game)
                    task.wait(0.1)
                    VirtualInput:SendKeyEvent(false, "E", false, game)
                end
            end
        end
        if status.beli then
            local target = getMonster(false, false)
            if target then attack(target) end
            local item = getMagnet()
            if item then
                teleport(item)
                task.wait(0.06)
                VirtualInput:SendKeyEvent(true, "E", false, game)
                task.wait(0.06)
                VirtualInput:SendKeyEvent(false, "E", false, game)
            end
        end
        if status.stats then
            pcall(function()
                for _, s in pairs({"Melee", "Defense", "Sword", "Fruit", "Gun"}) do
                    ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StatIncrease"):InvokeServer(s)
                    task.wait(0.4)
                end
            end)
        end
        if status.sell then
            pcall(function()
                for _, v in pairs(player.Backpack:GetChildren()) do
                    if v:IsA("Tool") then
                        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Sell"):InvokeServer(v)
                        task.wait(0.3)
                    end
                end
            end)
        end
        if status.sea then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and (v.Name:lower():find("seabeast") or v.Name:lower():find("sea beast")) then
                    local p = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
                    if p then
                        teleport(p)
                        task.wait(0.2)
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
                        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UpgradeRace"):InvokeServer()
                        task.wait(0.5)
                    end
                end)
            end
        end
        if status.raceAutoUp then
            pcall(function()
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UpgradeRace"):InvokeServer()
                task.wait(0.5)
            end)
        end
    end
end)

-- ====== TẠO GUI ======
local gui = Instance.new("ScreenGui")
gui.Name = "Tudzhub"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 400, 0, 500)
main.Position = UDim2.new(0.5, -200, 0.5, -250)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
main.BackgroundTransparency = 0.05
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 200, 255)
main.Active = true
main.Draggable = true
main.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
title.Text = "Tudzhub (Fix Delta)"
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -45)
scroll.Position = UDim2.new(0, 0, 0, 40)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 700)
scroll.ScrollBarThickness = 6
scroll.Parent = main

local yPos = 10
local function createBtn(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 35)
    btn.Position = UDim2.new(0.075, 0, 0, yPos)
    btn.BackgroundColor3 = color or Color3.fromRGB(40, 40, 60)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scroll
    btn.MouseButton1Click:Connect(callback)
    yPos = yPos + 42
    return btn
end

local function toggle(key, btn, name, colorOn)
    status[key] = not status[key]
    local state = status[key] and "ON" or "OFF"
    btn.Text = "[" .. name .. "] " .. state
    btn.BackgroundColor3 = status[key] and colorOn or Color3.fromRGB(40, 40, 60)
end

local farmBtn = createBtn("[FARM] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("farm", farmBtn, "FARM", Color3.fromRGB(0, 180, 0))
end)

local bossBtn = createBtn("[BOSS] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("boss", bossBtn, "BOSS", Color3.fromRGB(200, 0, 0))
end)

local raidBtn = createBtn("[RAID] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("raid", raidBtn, "RAID", Color3.fromRGB(0, 0, 200))
end)

local magnetBtn = createBtn("[MAGNET] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("magnet", magnetBtn, "MAGNET", Color3.fromRGB(200, 200, 0))
end)

local teleportBtn = createBtn("[TELEPORT] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("teleport", teleportBtn, "TELEPORT", Color3.fromRGB(0, 200, 200))
end)

local fruitBtn = createBtn("[FRUIT] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("fruit", fruitBtn, "FRUIT", Color3.fromRGB(255, 100, 255))
end)

local eventBtn = createBtn("[EVENT] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("event", eventBtn, "EVENT", Color3.fromRGB(255, 150, 0))
end)

local beliBtn = createBtn("[BELI] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("beli", beliBtn, "BELI", Color3.fromRGB(0, 200, 100))
end)

local statsBtn = createBtn("[STATS] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("stats", statsBtn, "STATS", Color3.fromRGB(100, 200, 255))
end)

local sellBtn = createBtn("[SELL] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("sell", sellBtn, "SELL", Color3.fromRGB(200, 100, 0))
end)

local seaBtn = createBtn("[SEA BEAST] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("sea", seaBtn, "SEA BEAST", Color3.fromRGB(0, 100, 200))
end)

local raceBtn = createBtn("[RACE FARM] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("race", raceBtn, "RACE FARM", Color3.fromRGB(200, 0, 200))
end)

local raceUpBtn = createBtn("[RACE UP] OFF", Color3.fromRGB(40, 40, 60), function()
    toggle("raceAutoUp", raceUpBtn, "RACE UP", Color3.fromRGB(0, 200, 200))
end)

createBtn("[CLOSE GUI]", Color3.fromRGB(150, 0, 0), function()
    gui:Destroy()
    for k, v in pairs(status) do status[k] = false end
end)

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 22)
footer.Position = UDim2.new(0, 0, 0.95, 0)
footer.BackgroundTransparency = 1
footer.Text = "Tudzhub v1 - Fix Delta"
footer.TextColor3 = Color3.fromRGB(0, 255, 0)
footer.TextScaled = true
footer.Font = Enum.Font.SourceSansBold
footer.Parent = main
