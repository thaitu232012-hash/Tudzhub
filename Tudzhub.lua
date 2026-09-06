--Tudzhub-bloxfruits
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local virtualInput = game:GetService("VirtualInputManager")
local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

pcall(function()
    game:GetService("NetworkClient"):SetOutgoingKBPSLimit(999999)
    settings().Network.AllowSleep = false
end)

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
    sea = false
}

local function getMonster(includeBoss, includeEvent)
    local list = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            local name = v.Name:lower()
            if name:find("marine") or name:find("pirate") or name:find("bandit") or name:find("skeleton") or name:find("zombie") then
                table.insert(list, v)
            end
            if includeBoss and (name:find("boss") or name:find("dragon") or name:find("law") or name:find("doffy")) then
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

local function attack(target)
    pcall(function()
        local t = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
        if t then
            root.CFrame = t.CFrame * CFrame.new(0, 0, -5)
            wait(0.08)
            virtualInput:SendKeyEvent(true, "J", false, game)
            wait(0.08)
            virtualInput:SendKeyEvent(false, "J", false, game)
            for i = 1, 5 do
                virtualInput:SendKeyEvent(true, tostring(i), false, game)
                wait(0.04)
                virtualInput:SendKeyEvent(false, tostring(i), false, game)
            end
            virtualInput:SendKeyEvent(true, "Z", false, game)
            wait(0.05)
            virtualInput:SendKeyEvent(false, "Z", false, game)
            virtualInput:SendKeyEvent(true, "X", false, game)
            wait(0.05)
            virtualInput:SendKeyEvent(false, "X", false, game)
        end
    end)
end

local function teleport(pos)
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

spawn(function()
    while true do
        wait(0.2)
        if status.farm then
            local target = getMonster(false, false)
            if target then attack(target) end
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
                wait(0.08)
                virtualInput:SendKeyEvent(true, "E", false, game)
                wait(0.08)
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
                wait(0.08)
                virtualInput:SendKeyEvent(true, "E", false, game)
                wait(0.08)
                virtualInput:SendKeyEvent(false, "E", false, game)
            end
        end
        if status.stats then
            pcall(function()
                for _, s in pairs({"Melee", "Defense", "Sword", "Fruit", "Gun"}) do
                    replicatedStorage:WaitForChild("Remotes"):WaitForChild("StatIncrease"):InvokeServer(s)
                    wait(0.5)
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
    end
end)

-- TẠO GUI CÓ TAB
local gui = Instance.new("ScreenGui")
gui.Name = "DeAnhTuHub"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 450, 0, 500)
main.Position = UDim2.new(0.5, -225, 0.5, -250)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
main.BackgroundTransparency = 0.05
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 255, 255)
main.Active = true
main.Draggable = true
main.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
title.Text = "ĐỆ ANH TÚ HUB"
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = main

-- KHUNG CHỨA TAB
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 35)
tabFrame.Position = UDim2.new(0, 0, 0, 40)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = main

-- KHUNG CHỨA NỘI DUNG TỪNG TAB
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -80)
contentFrame.Position = UDim2.new(0, 0, 0, 75)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = main

local function createTab(name, color, contentCallback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, 0, 1, 0)
    btn.Position = UDim2.new(#tabFrame:GetChildren() * 0.2, 0, 0, 0)
    btn.BackgroundColor3 = color or Color3.fromRGB(30, 30, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = tabFrame
    btn.MouseButton1Click:Connect(function()
        contentFrame:ClearAllChildren()
        contentCallback()
    end)
    return btn
end

local function createToggle(text, key, colorOn)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 35)
    btn.Position = UDim2.new(0.075, 0, 0, 10 + #contentFrame:GetChildren() * 42)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.Text = text .. " OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = contentFrame
    btn.MouseButton1Click:Connect(function()
        status[key] = not status[key]
        local state = status[key] and "ON" or "OFF"
        btn.Text = text .. " " .. state
        btn.BackgroundColor3 = status[key] and colorOn or Color3.fromRGB(40, 40, 60)
    end)
    return btn
end

local function createTeleportBtn(text, pos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.4, 0, 0, 30)
    btn.Position = UDim2.new(0.075 + (#contentFrame:GetChildren() % 2) * 0.45, 0, 0, 10 + math.floor(#contentFrame:GetChildren() / 2) * 38)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = contentFrame
    btn.MouseButton1Click:Connect(function()
        teleport(pos)
    end)
    return btn
end

-- TAB 1: FARM
createTab("FARM", Color3.fromRGB(0, 100, 0), function()
    createToggle("Auto Farm", "farm", Color3.fromRGB(0, 180, 0))
    createToggle("Auto Boss", "boss", Color3.fromRGB(200, 0, 0))
    createToggle("Auto Raid", "raid", Color3.fromRGB(0, 0, 200))
    createToggle("Auto Magnet", "magnet", Color3.fromRGB(200, 200, 0))
end)

-- TAB 2: TELEPORT
createTab("TELEPORT", Color3.fromRGB(0, 100, 200), function()
    createToggle("Auto Teleport", "teleport", Color3.fromRGB(0, 200, 200))
    createTeleportBtn("🏝 Jungle", Vector3.new(-2000, 100, 1000))
    createTeleportBtn("🏜 Desert", Vector3.new(-3000, 100, 2000))
    createTeleportBtn("❄ Snow", Vector3.new(2000, 100, -2000))
    createTeleportBtn("🌋 Volcano", Vector3.new(3000, 100, -1000))
    createTeleportBtn("☁ Sky", Vector3.new(0, 500, 0))
    createTeleportBtn("🌊 Sea", Vector3.new(0, 0, 3000))
end)

-- TAB 3: UTILITY
createTab("UTILITY", Color3.fromRGB(150, 100, 0), function()
    createToggle("Auto Fruit", "fruit", Color3.fromRGB(255, 100, 255))
    createToggle("Auto Event", "event", Color3.fromRGB(255, 150, 0))
    createToggle("Auto Beli", "beli", Color3.fromRGB(0, 200, 100))
    createToggle("Auto Stats", "stats", Color3.fromRGB(100, 200, 255))
    createToggle("Auto Sell", "sell", Color3.fromRGB(200, 100, 0))
    createToggle("Auto Sea Beast", "sea", Color3.fromRGB(0, 100, 200))
end)

-- TAB 4: SETTINGS
createTab("SETTINGS", Color3.fromRGB(100, 0, 100), function()
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.5, 0, 0, 40)
    closeBtn.Position = UDim2.new(0.25, 0, 0.3, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeBtn.Text = "ĐÓNG GUI"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.Parent = contentFrame
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
        for k, v in pairs(status) do status[k] = false end
    end)
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 0.6, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "ĐỆ ANH TÚ HUB v3.0 - ANTI-BAN"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.Parent = contentFrame
end)
