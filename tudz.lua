local myScriptCode = [[
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local CACHE_FILE = "rivals_settings.json"

local DefaultSettings = {
    ESP_Enabled = true,
    ESP_Highlight = true,
    ESP_Name = true,
    ESP_Studs = true,
    ESP_Tracer = false,
    ESP_BoxTransparency = 0.5,
    ESP_MaxDistance = 500,
    Aimbot_Enabled = true,
    Aimbot_FOVRadius = 100,
    Aimbot_WallCheck = false,
    Aimbot_Smoothness = 1,
    Triggerbot_Enabled = true,
    Triggerbot_MaxDistance = 1000,
    Triggerbot_FOVRadius = 50,
    InfJump_Enabled = false,
    DeviceSpoofer_Active = nil,
}

local function loadSettings()
    local ok, result = pcall(function()
        if isfile and isfile(CACHE_FILE) then
            local raw = readfile(CACHE_FILE)
            local decoded = HttpService:JSONDecode(raw)
            for k, v in pairs(DefaultSettings) do
                if decoded[k] == nil then decoded[k] = v end
            end
            return decoded
        end
    end)
    if ok and result then return result end
    local t = {}
    for k, v in pairs(DefaultSettings) do t[k] = v end
    return t
end

local function saveSettings(s)
    pcall(function()
        if writefile then
            writefile(CACHE_FILE, HttpService:JSONEncode(s))
        end
    end)
end

local Settings = loadSettings()

if Settings.ESP_Tracer == nil and Settings.ESP_Snapline ~= nil then
    Settings.ESP_Tracer = Settings.ESP_Snapline
end
Settings.ESP_Snapline = nil
Settings.ESP_BoxColor = Color3.fromRGB(255, 255, 255)
Settings.Triggerbot_MaxDistance = 1000

local SetControlsRemote = nil
pcall(function()
    SetControlsRemote = ReplicatedStorage
        :WaitForChild("Remotes", 5)
        :WaitForChild("Replication", 5)
        :WaitForChild("Fighter", 5)
        :WaitForChild("SetControls", 5)
end)

local function spoofDevice(deviceValue)
    if not SetControlsRemote then return end
    pcall(function()
        SetControlsRemote:FireServer("MouseKeyboard")
        task.wait(0.3)
        SetControlsRemote:FireServer(deviceValue)
    end)
end

local function reapplySpooferOnLoad()
    if Settings.DeviceSpoofer_Active then
        task.wait(1.5)
        spoofDevice(Settings.DeviceSpoofer_Active)
        saveSettings(Settings)
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(child)
        if child.Name == "HumanoidRootPart" then
            reapplySpooferOnLoad()
        end
    end)
end)

if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    reapplySpooferOnLoad()
end

local function isVoteScreenActive()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local mainGui = playerGui:FindFirstChild("MainGUI")
    if not mainGui then return false end
    local mainFrame = mainGui:FindFirstChild("MainFrame")
    if not mainFrame then return false end
    local duelInterface1 = mainFrame:FindFirstChild("DuelInterface")
    if not duelInterface1 then return false end
    local duelInterface2 = duelInterface1:FindFirstChild("DuelInterface")
    if not duelInterface2 then return false end
    local voting = duelInterface2:FindFirstChild("Voting")
    if not voting then return false end
    if voting.Visible then return true end
    local maps = voting:FindFirstChild("Maps")
    if not maps then return false end
    if maps.Visible then return true end
    local mapsList = maps:FindFirstChild("MapsList")
    if not mapsList then return false end
    return true
end

local function isInActiveRound()
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    if isVoteScreenActive() then return false end
    return true
end

local function ShowStartup()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local oldStartup = playerGui:FindFirstChild("StartupOverlay")
    if oldStartup then oldStartup:Destroy() end

    local startupGui = Instance.new("ScreenGui")
    startupGui.Name = "StartupOverlay"
    startupGui.ResetOnSpawn = false
    startupGui.IgnoreGuiInset = true
    startupGui.DisplayOrder = 1000
    startupGui.Parent = playerGui

    local lightingBlur = Instance.new("BlurEffect")
    lightingBlur.Name = "StartupBlur"
    lightingBlur.Size = 18
    lightingBlur.Parent = Lighting

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.18
    overlay.BorderSizePixel = 0
    overlay.Parent = startupGui

    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(430, 300)
    card.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    card.BorderSizePixel = 0
    card.Parent = overlay
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(45, 45, 45)
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.15
    cardStroke.Parent = card

    local startupImage = Instance.new("ImageLabel")
    startupImage.Size = UDim2.new(0, 100, 0, 100)
    startupImage.Position = UDim2.new(0.5, -50, 0, 8)
    startupImage.BackgroundTransparency = 1
    startupImage.Image = "https://raw.githubusercontent.com/thaitu232012-hash/Tudzhub/refs/heads/main/IMG_20260907_004831.jpg"
    startupImage.ScaleType = Enum.ScaleType.Fit
    startupImage.ZIndex = 102
    startupImage.Parent = card

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.new(0.5, 0, 0.55, 0)
    title.Size = UDim2.new(1, -40, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Tudzhub Controls"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 25
    title.Font = Enum.Font.GothamBold
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
    subtitle.Position = UDim2.new(0.5, 0, 0.70, 0)
    subtitle.Size = UDim2.new(1, -40, 0, 28)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Press Right Control to open the menu"
    subtitle.TextColor3 = Color3.fromRGB(165, 165, 165)
    subtitle.TextSize = 16
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.Parent = card

    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.new(0.5, 0, 0.82, 0)
    line.Size = UDim2.new(0.72, 0, 0, 1)
    line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    line.BorderSizePixel = 0
    line.Parent = card

    local credit = Instance.new("TextLabel")
    credit.AnchorPoint = Vector2.new(0.5, 0.5)
    credit.Position = UDim2.new(0.5, 0, 0.92, 0)
    credit.Size = UDim2.new(1, -40, 0, 25)
    credit.BackgroundTransparency = 1
    credit.Text = "by tudzhub"
    credit.TextColor3 = Color3.fromRGB(125, 125, 125)
    credit.TextSize = 14
    credit.Font = Enum.Font.GothamMedium
    credit.Parent = card

    task.delay(3, function()
        if not startupGui.Parent then return end
        local fade = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(overlay, fade, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(card,    fade, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(title,   fade, { TextTransparency = 1 }):Play()
        TweenService:Create(subtitle,fade, { TextTransparency = 1 }):Play()
        TweenService:Create(credit,  fade, { TextTransparency = 1 }):Play()
        TweenService:Create(line,    fade, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(startupImage, fade, { ImageTransparency = 1 }):Play()
        task.wait(0.5)
        if lightingBlur.Parent then lightingBlur:Destroy() end
        if startupGui.Parent then startupGui:Destroy() end
    end)
end

ShowStartup()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MenuGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local BackgroundFrame = Instance.new("Frame")
BackgroundFrame.Size = UDim2.fromScale(1, 1)
BackgroundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BackgroundFrame.BackgroundTransparency = 0.45
BackgroundFrame.BorderSizePixel = 0
BackgroundFrame.Visible = false
BackgroundFrame.ZIndex = 100
BackgroundFrame.Parent = ScreenGui

local MenuFrame = Instance.new("Frame")
MenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MenuFrame.Size = UDim2.fromOffset(390, 0)
MenuFrame.Position = UDim2.fromScale(0.5, 0.5)
MenuFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MenuFrame.BorderSizePixel = 0
MenuFrame.Visible = false
MenuFrame.ZIndex = 101
MenuFrame.Parent = ScreenGui

Instance.new("UICorner", MenuFrame).CornerRadius = UDim.new(0, 14)

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Color = Color3.fromRGB(42, 42, 42)
MenuStroke.Thickness = 1
MenuStroke.Transparency = 0.1
MenuStroke.Parent = MenuFrame

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, -40, 0, 42)
MenuTitle.Position = UDim2.new(0, 20, 0, 12)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "Tudzhub Controls"
MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 25
MenuTitle.TextXAlignment = Enum.TextXAlignment.Left
MenuTitle.ZIndex = 102
MenuTitle.Parent = MenuFrame

local MenuSubtitle = Instance.new("TextLabel")
MenuSubtitle.Size = UDim2.new(1, -40, 0, 20)
MenuSubtitle.Position = UDim2.new(0, 20, 0, 45)
MenuSubtitle.BackgroundTransparency = 1
MenuSubtitle.Text = "Triggerbot, ESP and Aimbot"
MenuSubtitle.TextColor3 = Color3.fromRGB(105, 105, 105)
MenuSubtitle.Font = Enum.Font.GothamMedium
MenuSubtitle.TextSize = 13
MenuSubtitle.TextXAlignment = Enum.TextXAlignment.Left
MenuSubtitle.ZIndex = 102
MenuSubtitle.Parent = MenuFrame

local MenuImage = Instance.new("ImageLabel")
MenuImage.Size = UDim2.new(1, -40, 0, 100)
MenuImage.Position = UDim2.new(0, 20, 0, 70)
MenuImage.BackgroundTransparency = 1
MenuImage.Image = "https://raw.githubusercontent.com/thaitu232012-hash/Tudzhub/refs/heads/main/IMG_20260907_004831.jpg"
MenuImage.ScaleType = Enum.ScaleType.Fit
MenuImage.ZIndex = 102
MenuImage.Parent = MenuFrame

local ToggleContainer = Instance.new("Frame")
ToggleContainer.Size = UDim2.new(1, -30, 0, 0)
ToggleContainer.Position = UDim2.new(0, 15, 0, 180)
ToggleContainer.BackgroundTransparency = 1
ToggleContainer.BorderSizePixel = 0
ToggleContainer.AutomaticSize = Enum.AutomaticSize.Y
ToggleContainer.ZIndex = 103
ToggleContainer.Parent = MenuFrame

local ToggleList = Instance.new("UIListLayout")
ToggleList.Padding = UDim.new(0, 5)
ToggleList.SortOrder = Enum.SortOrder.LayoutOrder
ToggleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
ToggleList.Parent = ToggleContainer

local SYNC_DURATION = 0.22
local SYNC_STYLE    = Enum.EasingStyle.Quint
local SYNC_DIR      = Enum.EasingDirection.Out
local SYNC_TWEEN    = TweenInfo.new(SYNC_DURATION, SYNC_STYLE, SYNC_DIR)

local toggleButtons  = {}
local espChildren    = {}
local aimbotChildren = {}
local updateFOVVisual   = nil
local updateFOVPosition = nil

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function makeIndicator(parent)
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.fromOffset(9, 9)
    indicator.Position = UDim2.new(1, -23, 0.5, -4.5)
    indicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = parent.ZIndex + 1
    indicator.Parent = parent
    makeCorner(indicator, 5)
    return indicator
end

local function syncMenuHeight(targetContainerH)
    TweenService:Create(MenuFrame, SYNC_TWEEN, {
        Size = UDim2.new(0, 390, 0, 180 + targetContainerH + 15)
    }):Play()
end

local function recalcMenuHeight()
    task.defer(function()
        task.wait(0.05)
        local h = ToggleContainer.AbsoluteSize.Y
        if h > 0 then
            MenuFrame.Size = UDim2.new(0, 390, 0, 180 + h + 15)
        end
    end)
end

local function updateAllSubToggles()
    for _, update in ipairs(espChildren)    do update() end
    for _, update in ipairs(aimbotChildren) do update() end
    if updateFOVVisual   then updateFOVVisual()   end
    if updateFOVPosition then updateFOVPosition() end
end

local function createMasterToggle(name, getState, setState, order)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -6, 0, 39)
    button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.LayoutOrder = order
    button.ZIndex = 104
    button.Parent = ToggleContainer
    makeCorner(button, 9)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -45, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(235, 235, 235)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 105
    label.Parent = button

    local indicator = makeIndicator(button)

    local function updateVisual()
        indicator.BackgroundColor3 = getState()
            and Color3.fromRGB(0, 190, 85)
            or  Color3.fromRGB(100, 100, 100)
    end

    button.MouseButton1Click:Connect(function()
        setState(not getState())
        updateVisual()
        updateAllSubToggles()
        saveSettings(Settings)
    end)

    updateVisual()
    toggleButtons[button] = updateVisual
    return button
end

local function createChildGroup(name, masterGetter, list, order, children)
    local group = Instance.new("Frame")
    group.Size = UDim2.new(1, -8, 0, 0)
    group.BackgroundTransparency = 1
    group.BorderSizePixel = 0
    group.AutomaticSize = Enum.AutomaticSize.Y
    group.LayoutOrder = order
    group.ZIndex = 103
    group.Parent = ToggleContainer

    local branch = Instance.new("Frame")
    branch.Size = UDim2.new(0, 2, 1, 0)
    branch.Position = UDim2.new(0, 22, 0, 0)
    branch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    branch.BorderSizePixel = 0
    branch.ZIndex = 104
    branch.Parent = group
    makeCorner(branch, 1)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -48, 0, 0)
    content.Position = UDim2.new(0, 42, 0, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.ZIndex = 105
    content.Parent = group

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local groupData = {
        Group        = group,
        Branch       = branch,
        Content      = content,
        Layout       = layout,
        MasterGetter = masterGetter,
    }
    children[groupData] = true
    return groupData
end

local function createChildToggle(name, getState, setState, masterGetter, list, parentGroup, order)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 32)
    button.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.LayoutOrder = order
    button.ZIndex = 105
    button.Parent = parentGroup.Content
    makeCorner(button, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -42, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(205, 205, 205)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 106
    label.Parent = button

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.fromOffset(8, 8)
    indicator.Position = UDim2.new(1, -20, 0.5, -4)
    indicator.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 106
    indicator.Parent = button
    makeCorner(indicator, 4)

    local function updateVisual()
        local masterEnabled = masterGetter()
        local state = getState()
        if not masterEnabled then
            button.BackgroundColor3    = Color3.fromRGB(16, 16, 16)
            label.TextColor3           = Color3.fromRGB(65, 65, 65)
            indicator.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            parentGroup.Branch.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        else
            button.BackgroundColor3    = Color3.fromRGB(23, 23, 23)
            label.TextColor3           = Color3.fromRGB(205, 205, 205)
            indicator.BackgroundColor3 = state
                and Color3.fromRGB(0, 190, 85)
                or  Color3.fromRGB(95, 95, 95)
            parentGroup.Branch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end

    button.MouseButton1Click:Connect(function()
        if not masterGetter() then return end
        setState(not getState())
        updateVisual()
        saveSettings(Settings)
    end)

    updateVisual()
    toggleButtons[button] = updateVisual
    table.insert(list, updateVisual)
    return button
end

local function createChildSlider(name, getMaster, parentGroup, order)
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 47)
    wrapper.BackgroundTransparency = 1
    wrapper.BorderSizePixel = 0
    wrapper.LayoutOrder = order
    wrapper.ZIndex = 105
    wrapper.Parent = parentGroup.Content

    local content = Instance.new("Frame")
    content.Size = UDim2.fromScale(1, 1)
    content.BackgroundTransparency = 1
    content.ZIndex = 105
    content.Parent = wrapper

    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, 0, 0, 18)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = name .. ": " .. tostring(Settings.Aimbot_FOVRadius)
    sliderLabel.TextColor3 = Color3.fromRGB(205, 205, 205)
    sliderLabel.Font = Enum.Font.GothamMedium
    sliderLabel.TextSize = 13
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.ZIndex = 106
    sliderLabel.Parent = content

    local sliderLine = Instance.new("Frame")
    sliderLine.Size = UDim2.new(1, -12, 0, 4)
    sliderLine.Position = UDim2.new(0, 6, 0, 29)
    sliderLine.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    sliderLine.BorderSizePixel = 0
    sliderLine.ZIndex = 105
    sliderLine.Parent = content
    makeCorner(sliderLine, 2)

    local sliderHandle = Instance.new("TextButton")
    sliderHandle.Size = UDim2.fromOffset(16, 16)
    sliderHandle.Position = UDim2.new(0, -8, 0, 23)
    sliderHandle.BackgroundColor3 = Color3.fromRGB(170, 170, 170)
    sliderHandle.BorderSizePixel = 0
    sliderHandle.Text = ""
    sliderHandle.AutoButtonColor = false
    sliderHandle.ZIndex = 107
