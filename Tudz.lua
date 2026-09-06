-- Tudzhub Blox Fruits
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

pcall(function()
    game:GetService("NetworkClient"):SetOutgoingKBPSLimit(999999)
    settings().Network.AllowSleep = false
end)

local autoFarm = false
local autoBoss = false
local autoRaid = false
local autoMagnet = false

local function getMonster(includeBoss)
    local list = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            local name = v.Name:lower()
            if name:find("marine") or name:find("pirate") or name:find("bandit") or name:find("skeleton") then
                table.insert(list, v)
            end
            if includeBoss and (name:find("boss") or name:find("dragon") or name:find("law")) then
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

local function attack(target)
    pcall(function()
        local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
        if targetRoot then
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -5)
            wait(0.1)
            virtualInput:SendKeyEvent(true, "J", false, game)
            wait(0.1)
            virtualInput:SendKeyEvent(false, "J", false, game)
            for i = 1, 4 do
                virtualInput:SendKeyEvent(true, tostring(i), false, game)
                wait(0.05)
                virtualInput:SendKeyEvent(false, tostring(i), false, game)
            end
        end
    end)
end

spawn(function()
    while true do
        wait(0.3)
        if autoFarm then
            local target = getMonster(false)
            if target then attack(target) end
        end
        if autoBoss then
            local target = getMonster(true)
            if target then attack(target) end
        end
        if autoRaid then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and (v.Name:lower():find("portal") or v.Name:lower():find("raid")) then
                    local p = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
                    if p then
                        root.CFrame = p.CFrame * CFrame.new(0, 0, -2)
                        wait(0.2)
                        virtualInput:SendKeyEvent(true, "E", false, game)
                        wait(0.1)
                        virtualInput:SendKeyEvent(false, "E", false, game)
                    end
                end
            end
        end
        if autoMagnet then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and (v.Name:lower():find("magnet") or v.Name:lower():find("fragment") or v.Name:lower():find("beli")) then
                    if v.Position:Distance(root.Position) < 50 then
                        root.CFrame = v.CFrame * CFrame.new(0, 0, -2)
                        wait(0.1)
                        virtualInput:SendKeyEvent(true, "E", false, game)
                        wait(0.1)
                        virtualInput:SendKeyEvent(false, "E", false, game)
                    end
                end
            end
        end
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "TuHub"
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 400)
frame.Position = UDim2.new(0.5, -175, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "TU HUB"
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.BackgroundColor3 = Color3.fromRGB(0, 50, 80)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

local y = 50
local function addBtn(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 35)
    btn.Position = UDim2.new(0.1, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
    y = y + 45
    return btn
end

local farmBtn = addBtn("[FARM] OFF", function()
    autoFarm = not autoFarm
    farmBtn.Text = autoFarm and "[FARM] ON" or "[FARM] OFF"
    farmBtn.BackgroundColor3 = autoFarm and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(40, 40, 60)
end)

local bossBtn = addBtn("[BOSS] OFF", function()
    autoBoss = not autoBoss
    bossBtn.Text = autoBoss and "[BOSS] ON" or "[BOSS] OFF"
    bossBtn.BackgroundColor3 = autoBoss and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(40, 40, 60)
end)

local raidBtn = addBtn("[RAID] OFF", function()
    autoRaid = not autoRaid
    raidBtn.Text = autoRaid and "[RAID] ON" or "[RAID] OFF"
    raidBtn.BackgroundColor3 = autoRaid and Color3.fromRGB(0, 0, 200) or Color3.fromRGB(40, 40, 60)
end)

local magnetBtn = addBtn("[MAGNET] OFF", function()
    autoMagnet = not autoMagnet
    magnetBtn.Text = autoMagnet and "[MAGNET] ON" or "[MAGNET] OFF"
    magnetBtn.BackgroundColor3 = autoMagnet and Color3.fromRGB(200, 200, 0) or Color3.fromRGB(40, 40, 60)
end)

addBtn("CLOSE", function()
    gui:Destroy()
    autoFarm = false
    autoBoss = false
    autoRaid = false
    autoMagnet = false
end)
