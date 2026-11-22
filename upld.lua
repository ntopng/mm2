pcall(function()
    local genv = (getgenv and getgenv()) or _G
    if genv then
        genv.checkcaller = (newcclosure and newcclosure(function() return true end)) or function() return true end
    end
    if getrawmetatable then
        local mt = getrawmetatable(game)
        if mt and mt.__index then
            local curIdx = mt.__index
            if restorefunction then
                pcall(restorefunction, curIdx)
            end
            local getups = (debug and debug.getupvalues) or getupvalues
            if getups and setreadonly then
                pcall(function()
                    local ups = getups(curIdx)
                    if type(ups) == "table" then
                        for _, uv in pairs(ups) do
                            if type(uv) == "function" and uv ~= curIdx then
                                if not iscclosure or iscclosure(uv) then
                                    setreadonly(mt, false)
                                    mt.__index = uv
                                    setreadonly(mt, true)
                                    break
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local parent = (gethui and gethui()) or game:GetService("CoreGui")
if getgenv().PearlTimebombLoaded or getgenv().NebulaUILoaded then
    if getgenv().PearlTimebombUnload then
        pcall(getgenv().PearlTimebombUnload)
    elseif getgenv().NebulaUIUnload then
        pcall(getgenv().NebulaUIUnload)
    end
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == "PearlMM2UI" or child.Name == "NebulaUI" or child.Name == "PearlESPOverlay" or child.Name == "NebulaESPOverlay" or child.Name == "PearlCompass" or child.Name == "NebulaCompass" or child.Name == "PearlSpectators" or child.Name == "NebulaSpectators" or child.Name == "PearlWatermark" or child.Name == "NebulaWatermark" then
            pcall(function() child:Destroy() end)
        end
    end
end
getgenv().PearlTimebombLoaded = true
getgenv().NebulaUILoaded = true
Colors = {
    Background = Color3.fromRGB(15, 15, 18),
    Card = Color3.fromRGB(20, 20, 24),
    CardSub = Color3.fromRGB(26, 26, 32),
    Border = Color3.fromRGB(34, 34, 40),
    BorderActive = Color3.fromRGB(65, 65, 78),
    Accent = Color3.fromRGB(146, 112, 255),
    AccentDark = Color3.fromRGB(44, 34, 76),
    AccentLight = Color3.fromRGB(175, 145, 255),
    Text = Color3.fromRGB(242, 242, 246),
    TextDim = Color3.fromRGB(142, 142, 155),
    TextMuted = Color3.fromRGB(86, 86, 98),
    Success = Color3.fromRGB(115, 235, 145),
    Warning = Color3.fromRGB(245, 185, 85),
    Error = Color3.fromRGB(245, 95, 95),
    Info = Color3.fromRGB(110, 185, 255)
}
palette = {
    bg = Colors.Background,
    panel = Colors.Background,
    panel2 = Colors.Card,
    card = Colors.Card,
    cardHover = Colors.CardSub,
    stroke = Colors.Border,
    text = Colors.Text,
    sub = Colors.TextDim,
    accentA = Colors.Accent,
    accentB = Colors.AccentLight,
}
CategoryIcons = {
    ["3XPLOIT"] = "rbxassetid://7733765307",
    VISUAL = "rbxassetid://7733774602",
    MOVEMENT = "rbxassetid://7733955740",
    PLAYER = "rbxassetid://7743876054",
    MISC = "rbxassetid://7733955511",
    CONFIG = "rbxassetid://7743868936",
    SETTINGS = "rbxassetid://7734053495",
}
function CreateTween(instance, properties, duration, style, direction)
    local info = TweenInfo.new(
        duration or 0.25,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PearlTimebombUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 100
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = parent
DimmerEnabled = true
BubblesEnabled = true
setVisualPreviewVisible = nil
espPreviewConn = nil
function makeCorner(gui, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = gui
    return corner
end
accentGradients = {}
accentDynamicObjects = {}
function makeGradient(gui, from, to, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, from or Colors.Accent),
        ColorSequenceKeypoint.new(1, to or Colors.AccentLight),
    })
    gradient.Rotation = rotation or 90
    gradient.Parent = gui
    table.insert(accentGradients, {grad = gradient, from = from or Colors.Accent, to = to or Colors.AccentLight})
    return gradient
end
function makeStroke(gui, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = gui
    return stroke
end
themes = {
    Violet = {Color3.fromRGB(146, 112, 255), Color3.fromRGB(175, 145, 255), Color3.fromRGB(44, 34, 76)},
    Bleu   = {Color3.fromRGB(70, 140, 255),  Color3.fromRGB(115, 195, 255), Color3.fromRGB(24, 44, 82)},
    Vert   = {Color3.fromRGB(80, 215, 130),  Color3.fromRGB(140, 250, 175), Color3.fromRGB(22, 62, 40)},
    Rouge  = {Color3.fromRGB(255, 80, 95),   Color3.fromRGB(255, 140, 150), Color3.fromRGB(72, 24, 32)},
    Orange = {Color3.fromRGB(255, 155, 55),  Color3.fromRGB(255, 205, 110), Color3.fromRGB(74, 46, 20)},
    Blanc  = {Color3.fromRGB(240, 240, 248), Color3.fromRGB(255, 255, 255), Color3.fromRGB(55, 55, 68)},
}
currentThemeName = "Violet"
function applyTheme(name)
    local th = themes[name]
    if not th then return end
    currentThemeName = name
    Colors.Accent = th[1]
    Colors.AccentLight = th[2]
    Colors.AccentDark = th[3]
    palette.accentA = th[1]
    palette.accentB = th[2]
    for _, entry in ipairs(accentGradients) do
        if entry.grad and entry.grad.Parent then
            entry.grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Colors.Accent),
                ColorSequenceKeypoint.new(1, Colors.AccentLight),
            })
        end
    end
    for _, fn in ipairs(accentDynamicObjects) do
        pcall(fn)
    end
end
menuSound = nil
alertSound = nil
function playClick()
    pcall(function()
        if not menuSound or not menuSound.Parent then
            menuSound = Instance.new("Sound")
            menuSound.SoundId = "rbxassetid://12222010"
            menuSound.Volume = 0.18
            menuSound.PlaybackSpeed = 0.9
            menuSound.Parent = game:GetService("SoundService")
        end
        menuSound:Play()
    end)
end
function playAlertSound()
    pcall(function()
        if not alertSound or not alertSound.Parent then
            alertSound = Instance.new("Sound")
            alertSound.SoundId = "rbxassetid://12222010"
            alertSound.Volume = 0.45
            alertSound.PlaybackSpeed = 1.6
            alertSound.Parent = game:GetService("SoundService")
        end
        alertSound:Play()
    end)
end
BackgroundDimmer = Instance.new("Frame")
BackgroundDimmer.Name = "BackgroundDimmer"
BackgroundDimmer.Size = UDim2.new(1, 0, 1, 0)
BackgroundDimmer.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
BackgroundDimmer.BackgroundTransparency = 0.45
BackgroundDimmer.BorderSizePixel = 0
BackgroundDimmer.ZIndex = 1
BackgroundDimmer.Active = false
BackgroundDimmer.Visible = true
BackgroundDimmer.Parent = ScreenGui
BubblesContainer = Instance.new("Frame")
BubblesContainer.Name = "BubblesContainer"
BubblesContainer.Size = UDim2.new(1, 0, 1, 0)
BubblesContainer.BackgroundTransparency = 1
BubblesContainer.ClipsDescendants = true
BubblesContainer.ZIndex = 2
BubblesContainer.Active = false
BubblesContainer.Visible = true
BubblesContainer.Parent = ScreenGui
bubbles = {}
for i = 1, 45 do
    local b = Instance.new("Frame")
    local size = math.random(7, 26)
    b.Size = UDim2.new(0, size, 0, size)
    local r = math.random()
    if r > 0.65 then
        b.BackgroundColor3 = Colors.Accent
    elseif r > 0.35 then
        b.BackgroundColor3 = Colors.AccentLight
    else
        b.BackgroundColor3 = Color3.fromRGB(125, 95, 245)
    end
    b.BackgroundTransparency = math.random(62, 84) / 100
    b.BorderSizePixel = 0
    b.ZIndex = 2
    b.Parent = BubblesContainer
    makeCorner(b, 50)
    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Color3.fromRGB(255, 255, 255)
    bStroke.Transparency = math.random(75, 92) / 100
    bStroke.Thickness = 1
    bStroke.Parent = b
    local bData = {
        frame = b,
        x = math.random(),
        y = math.random(),
        speed = math.random(28, 85) / 1000,
        swaySpeed = math.random(10, 26) / 10,
        swayAmp = math.random(6, 20) / 1000,
        offset = math.random() * math.pi * 2
    }
    b.Position = UDim2.new(bData.x, 0, bData.y, 0)
    table.insert(bubbles, bData)
end
bubbleRenderConn = RunService.RenderStepped:Connect(function(dt)
    if BubblesContainer and BubblesContainer.Visible then
        local t = tick()
        for _, b in ipairs(bubbles) do
            b.y = b.y - b.speed * dt
            if b.y < -0.05 then
                b.y = 1.05
                b.x = math.random()
            end
            local curX = b.x + math.sin(t * b.swaySpeed + b.offset) * b.swayAmp
            b.frame.Position = UDim2.new(curX, 0, b.y, 0)
        end
    end
end)
NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "PearlNotificationContainer"
NotificationContainer.Size = UDim2.new(0, 320, 1, -40)
NotificationContainer.Position = UDim2.new(1, -336, 0, 20)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.BorderSizePixel = 0
NotificationContainer.ZIndex = 500
NotificationContainer.Parent = ScreenGui
NotifLayout = Instance.new("UIListLayout")
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
NotifLayout.Parent = NotificationContainer
local lastNotifyKey = nil
local lastNotifyTime = 0
local activeNotifCards = {}
function notify(title, text, color)
    title = tostring(title or "Pearl Hub"):gsub("<[^>]->", "")
    text = tostring(text or ""):gsub("<[^>]->", "")
    local key = title .. "|" .. text
    local now = os.clock()
    if key == lastNotifyKey and (now - lastNotifyTime) < 0.8 then
        return
    end
    lastNotifyKey = key
    lastNotifyTime = now
    local notifColor = color or Colors.Accent
    if #activeNotifCards >= 5 then
        local oldest = table.remove(activeNotifCards, 1)
        if oldest and oldest.dismiss then
            pcall(oldest.dismiss)
        end
    end
    local cardHeight = string.len(text) > 48 and 70 or 60
    local Card = Instance.new("Frame")
    Card.Name = "PearlNotifCard"
    Card.Size = UDim2.new(1, 0, 0, cardHeight)
    Card.Position = UDim2.new(0, 120, 0, 0)
    Card.BackgroundColor3 = Color3.fromRGB(17, 18, 26)
    Card.BorderSizePixel = 0
    Card.ClipsDescendants = true
    Card.BackgroundTransparency = 1
    Card.ZIndex = 501
    local CardScale = Instance.new("UIScale")
    CardScale.Scale = 0.8
    CardScale.Parent = Card
    makeCorner(Card, 10)
    local cardStroke = makeStroke(Card, notifColor, 1.2, 1)
    local CardGrad = Instance.new("UIGradient")
    CardGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 27, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 15, 22))
    })
    CardGrad.Rotation = 45
    CardGrad.Parent = Card
    local LeftPill = Instance.new("Frame")
    LeftPill.Size = UDim2.new(0, 3.5, 0.65, 0)
    LeftPill.Position = UDim2.new(0, 5, 0.5, 0)
    LeftPill.AnchorPoint = Vector2.new(0, 0.5)
    LeftPill.BackgroundColor3 = notifColor
    LeftPill.BorderSizePixel = 0
    LeftPill.BackgroundTransparency = 1
    LeftPill.ZIndex = 502
    LeftPill.Parent = Card
    makeCorner(LeftPill, 4)
    local IconBox = Instance.new("Frame")
    IconBox.Size = UDim2.new(0, 34, 0, 34)
    IconBox.Position = UDim2.new(0, 15, 0.5, 0)
    IconBox.AnchorPoint = Vector2.new(0, 0.5)
    IconBox.BackgroundColor3 = Color3.fromRGB(24, 25, 36)
    IconBox.BorderSizePixel = 0
    IconBox.BackgroundTransparency = 1
    IconBox.ZIndex = 502
    IconBox.Parent = Card
    makeCorner(IconBox, 8)
    local ibStroke = makeStroke(IconBox, Color3.fromRGB(48, 50, 70), 1, 1)
    local lC = string.lower(title .. " " .. text)
    local iconId = "rbxassetid://7733964719"
    if lC:find("esp") or lC:find("visu") or lC:find("chams") then
        iconId = CategoryIcons.VISUAL
    elseif lC:find("fly") or lC:find("speed") or lC:find("jump") or lC:find("noclip") then
        iconId = CategoryIcons.MOVEMENT
    elseif lC:find("kill") or lC:find("fling") or lC:find("murder") or lC:find("pistol") then
        iconId = CategoryIcons.COMBAT
    elseif lC:find("config") then
        iconId = CategoryIcons.CONFIG
    elseif lC:find("bind") or lC:find("setting") then
        iconId = CategoryIcons.SETTINGS
    end
    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon.BackgroundTransparency = 1
    Icon.Image = iconId
    Icon.ImageColor3 = notifColor
    Icon.ImageTransparency = 1
    Icon.ZIndex = 503
    Icon.Parent = IconBox
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -95, 0, 18)
    TitleLabel.Position = UDim2.new(0, 58, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = string.upper(title)
    TitleLabel.TextColor3 = notifColor
    TitleLabel.TextSize = 12
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TitleLabel.TextTransparency = 1
    TitleLabel.ZIndex = 502
    TitleLabel.Parent = Card
    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size = UDim2.new(1, -90, 0, 22)
    MessageLabel.Position = UDim2.new(0, 58, 0, 28)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Font = Enum.Font.GothamMedium
    MessageLabel.Text = text
    MessageLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
    MessageLabel.TextSize = 11
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    MessageLabel.TextTransparency = 1
    MessageLabel.ZIndex = 502
    MessageLabel.Parent = Card
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -26, 0, 7)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(130, 134, 152)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 11
    CloseBtn.TextTransparency = 1
    CloseBtn.ZIndex = 504
    CloseBtn.Parent = Card
    local ProgressBarBg = Instance.new("Frame")
    ProgressBarBg.Size = UDim2.new(1, -24, 0, 2)
    ProgressBarBg.Position = UDim2.new(0, 12, 1, -4)
    ProgressBarBg.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    ProgressBarBg.BorderSizePixel = 0
    ProgressBarBg.BackgroundTransparency = 1
    ProgressBarBg.ZIndex = 502
    ProgressBarBg.Parent = Card
    makeCorner(ProgressBarBg, 2)
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(1, 0, 1, 0)
    ProgressBar.BackgroundColor3 = notifColor
    ProgressBar.BorderSizePixel = 0
    ProgressBar.ZIndex = 503
    ProgressBar.Parent = ProgressBarBg
    makeCorner(ProgressBar, 2)
    Card.Parent = NotificationContainer
    local notifEntry = {card = Card, dismissed = false}
    table.insert(activeNotifCards, notifEntry)
    CreateTween(Card, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.04}, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    CreateTween(CardScale, {Scale = 1}, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    CreateTween(cardStroke, {Transparency = 0.45}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    CreateTween(LeftPill, {BackgroundTransparency = 0}, 0.22)
    CreateTween(IconBox, {BackgroundTransparency = 0}, 0.22)
    CreateTween(ibStroke, {Transparency = 0.4}, 0.22)
    CreateTween(Icon, {ImageTransparency = 0}, 0.22)
    CreateTween(TitleLabel, {TextTransparency = 0}, 0.22)
    CreateTween(MessageLabel, {TextTransparency = 0}, 0.22)
    CreateTween(CloseBtn, {TextTransparency = 0.4}, 0.22)
    CreateTween(ProgressBarBg, {BackgroundTransparency = 0.5}, 0.22)
    CreateTween(ProgressBar, {Size = UDim2.new(0, 0, 1, 0)}, 3.0, Enum.EasingStyle.Linear)
    local function dismissNotif()
        if notifEntry.dismissed then return end
        notifEntry.dismissed = true
        for idx, entry in ipairs(activeNotifCards) do
            if entry == notifEntry then
                table.remove(activeNotifCards, idx)
                break
            end
        end
        local exitTween = CreateTween(Card, {Position = UDim2.new(0, 120, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        CreateTween(CardScale, {Scale = 0.8}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        CreateTween(cardStroke, {Transparency = 1}, 0.18)
        CreateTween(LeftPill, {BackgroundTransparency = 1}, 0.18)
        CreateTween(IconBox, {BackgroundTransparency = 1}, 0.18)
        CreateTween(Icon, {ImageTransparency = 1}, 0.18)
        CreateTween(TitleLabel, {TextTransparency = 1}, 0.18)
        CreateTween(MessageLabel, {TextTransparency = 1}, 0.18)
        CreateTween(CloseBtn, {TextTransparency = 1}, 0.18)
        exitTween.Completed:Connect(function()
            pcall(function() Card:Destroy() end)
        end)
    end
    notifEntry.dismiss = dismissNotif
    CloseBtn.MouseButton1Click:Connect(dismissNotif)
    task.delay(3.0, function()
        if not notifEntry.dismissed then
            dismissNotif()
        end
    end)
end
windowSize = UDim2.new(0, 760, 0, 500)
savedMenuPos = UDim2.new(0.5, -380, 0.5, -250)
MainFrame = Instance.new("Frame")
MainFrame.Name = "PearlMasterPanel"
MainFrame.Size = windowSize
MainFrame.Position = savedMenuPos
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Active = true
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui
PanelScale = Instance.new("UIScale")
PanelScale.Scale = 1
PanelScale.Parent = MainFrame
Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 68, 1, 0)
Sidebar.Position = UDim2.new(0, 0, 0, 0)
Sidebar.BackgroundColor3 = Colors.Background
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 6
Sidebar.Parent = MainFrame
makeCorner(Sidebar, 14)
makeStroke(Sidebar, Colors.Border, 1)
LogoContainer = Instance.new("Frame")
LogoContainer.Name = "LogoContainer"
LogoContainer.Size = UDim2.new(0, 44, 0, 44)
LogoContainer.Position = UDim2.new(0.5, -22, 0, 14)
LogoContainer.BackgroundColor3 = Colors.Card
LogoContainer.BorderSizePixel = 0
LogoContainer.ZIndex = 7
LogoContainer.Parent = Sidebar
makeCorner(LogoContainer, 10)
local logoStroke = makeStroke(LogoContainer, Colors.Border, 1)
LogoImg = Instance.new("ImageLabel")
LogoImg.Name = "LogoImage"
LogoImg.Size = UDim2.new(1, -6, 1, -6)
LogoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
LogoImg.AnchorPoint = Vector2.new(0.5, 0.5)
LogoImg.BackgroundTransparency = 1
LogoImg.ScaleType = Enum.ScaleType.Fit
LogoImg.ZIndex = 8
LogoImg.Parent = LogoContainer
local LogoUrl = "https://i.ibb.co/9HT9Yt3X/logo.png"
task.spawn(function()
    local loaded = false
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req and writefile and getcustomasset then
            local fileName = "pearl_logo.png"
            if not (isfile and isfile(fileName)) then
                local res = req({Url = LogoUrl, Method = "GET"})
                if res and res.Body then
                    writefile(fileName, res.Body)
                end
            end
            if isfile and isfile(fileName) then
                LogoImg.Image = getcustomasset(fileName)
                loaded = true
            end
        end
    end)
    if not loaded then
        LogoImg.Image = LogoUrl
    end
end)
LogoContainer.MouseEnter:Connect(function()
    CreateTween(logoStroke, {Color = Colors.Accent}, 0.2)
end)
LogoContainer.MouseLeave:Connect(function()
    CreateTween(logoStroke, {Color = Colors.Border}, 0.2)
end)
NavContainer = Instance.new("ScrollingFrame")
NavContainer.Name = "NavScroll"
NavContainer.Size = UDim2.new(1, 0, 1, -78)
NavContainer.Position = UDim2.new(0, 0, 0, 68)
NavContainer.BackgroundTransparency = 1
NavContainer.BorderSizePixel = 0
NavContainer.ScrollBarThickness = 2
NavContainer.ScrollBarImageColor3 = Colors.BorderActive
NavContainer.ScrollBarImageTransparency = 0.8
NavContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
NavContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
NavContainer.ZIndex = 7
NavContainer.Parent = Sidebar
NavLayout = Instance.new("UIListLayout")
NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Padding = UDim.new(0, 8)
NavLayout.Parent = NavContainer
ContentPanel = Instance.new("Frame")
ContentPanel.Name = "ContentPanel"
ContentPanel.Size = UDim2.new(1, -82, 1, 0)
ContentPanel.Position = UDim2.new(0, 82, 0, 0)
ContentPanel.BackgroundTransparency = 1
ContentPanel.ZIndex = 6
ContentPanel.Parent = MainFrame
TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 52)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Colors.Background
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 7
TopBar.Parent = ContentPanel
makeCorner(TopBar, 14)
makeStroke(TopBar, Colors.Border, 1)
PanelTitle = Instance.new("TextLabel")
PanelTitle.Name = "PanelTitle"
PanelTitle.Size = UDim2.new(0, 180, 1, 0)
PanelTitle.Position = UDim2.new(0, 20, 0, 0)
PanelTitle.BackgroundTransparency = 1
PanelTitle.Font = Enum.Font.GothamBold
PanelTitle.Text = "3xploit"
PanelTitle.TextColor3 = Colors.Text
PanelTitle.TextSize = 17
PanelTitle.TextXAlignment = Enum.TextXAlignment.Left
PanelTitle.ZIndex = 8
PanelTitle.Parent = TopBar
local HubBadge = Instance.new("Frame")
HubBadge.Size = UDim2.new(0, 96, 0, 24)
HubBadge.Position = UDim2.new(1, -372, 0.5, -12)
HubBadge.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
HubBadge.BorderSizePixel = 0
HubBadge.ZIndex = 8
HubBadge.Parent = TopBar
makeCorner(HubBadge, 7)
local hubBadgeStroke = makeStroke(HubBadge, Colors.Accent, 1, 0.45)
local hubDot = Instance.new("Frame")
hubDot.Size = UDim2.new(0, 6, 0, 6)
hubDot.Position = UDim2.new(0, 9, 0.5, -3)
hubDot.BackgroundColor3 = Colors.Accent
hubDot.BorderSizePixel = 0
hubDot.ZIndex = 9
hubDot.Parent = HubBadge
makeCorner(hubDot, 3)
local hubText = Instance.new("TextLabel")
hubText.Size = UDim2.new(1, -22, 1, 0)
hubText.Position = UDim2.new(0, 20, 0, 0)
hubText.BackgroundTransparency = 1
hubText.Text = "TIMEBOMB"
hubText.TextColor3 = Colors.AccentLight
hubText.Font = Enum.Font.GothamBold
hubText.TextSize = 10
hubText.TextXAlignment = Enum.TextXAlignment.Left
hubText.ZIndex = 9
hubText.Parent = HubBadge
table.insert(accentDynamicObjects, function()
    hubBadgeStroke.Color = Colors.Accent
    hubDot.BackgroundColor3 = Colors.Accent
    hubText.TextColor3 = Colors.AccentLight
end)
local AvatarHolder = Instance.new("Frame")
AvatarHolder.Name = "AvatarHolder"
AvatarHolder.Size = UDim2.new(0, 36, 0, 36)
AvatarHolder.Position = UDim2.new(1, -46, 0.5, -18)
AvatarHolder.BackgroundColor3 = Colors.Card
AvatarHolder.BorderSizePixel = 0
AvatarHolder.ZIndex = 8
AvatarHolder.Parent = TopBar
makeCorner(AvatarHolder, 18)
local AvatarStroke = makeStroke(AvatarHolder, Colors.Border, 1)
local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(1, 0, 1, 0)
AvatarImage.BackgroundTransparency = 1
AvatarImage.ZIndex = 9
AvatarImage.Parent = AvatarHolder
makeCorner(AvatarImage, 18)
task.spawn(function()
    pcall(function()
        local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        if isReady then
            AvatarImage.Image = content
        end
    end)
end)
AvatarHolder.MouseEnter:Connect(function()
    CreateTween(AvatarStroke, {Color = Colors.Accent}, 0.2)
    CreateTween(AvatarHolder, {Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(1, -47, 0.5, -19)}, 0.2)
end)
AvatarHolder.MouseLeave:Connect(function()
    CreateTween(AvatarStroke, {Color = Colors.Border}, 0.2)
    CreateTween(AvatarHolder, {Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(1, -46, 0.5, -18)}, 0.2)
end)
SearchContainer = Instance.new("Frame")
SearchContainer.Name = "SearchContainer"
SearchContainer.Size = UDim2.new(0, 205, 0, 32)
SearchContainer.Position = UDim2.new(1, -260, 0.5, -16)
SearchContainer.BackgroundColor3 = Colors.Card
SearchContainer.BorderSizePixel = 0
SearchContainer.ZIndex = 10
SearchContainer.Parent = TopBar
makeCorner(SearchContainer, 8)
local SearchStroke = makeStroke(SearchContainer, Colors.Border, 1)
local SearchIcon = Instance.new("ImageLabel")
SearchIcon.Size = UDim2.new(0, 14, 0, 14)
SearchIcon.Position = UDim2.new(0, 10, 0.5, -7)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Image = "rbxassetid://7733956411"
SearchIcon.ImageColor3 = Colors.TextDim
SearchIcon.ZIndex = 11
SearchIcon.Parent = SearchContainer
SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -54, 1, 0)
SearchBox.Position = UDim2.new(0, 30, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.PlaceholderText = "Rechercher une option..."
SearchBox.PlaceholderColor3 = Colors.TextMuted
SearchBox.Text = ""
SearchBox.TextColor3 = Colors.Text
SearchBox.TextSize = 11
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 11
SearchBox.Parent = SearchContainer
ClearSearchBtn = Instance.new("TextButton")
ClearSearchBtn.Size = UDim2.new(0, 18, 0, 18)
ClearSearchBtn.Position = UDim2.new(1, -24, 0.5, -9)
ClearSearchBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
ClearSearchBtn.BorderSizePixel = 0
ClearSearchBtn.Text = "x"
ClearSearchBtn.TextColor3 = Colors.TextDim
ClearSearchBtn.Font = Enum.Font.GothamBold
ClearSearchBtn.TextSize = 12
ClearSearchBtn.AutoButtonColor = false
ClearSearchBtn.Visible = false
ClearSearchBtn.ZIndex = 12
ClearSearchBtn.Parent = SearchContainer
makeCorner(ClearSearchBtn, 9)
makeStroke(ClearSearchBtn, Colors.Border, 1)
SearchContainer.MouseEnter:Connect(function()
    if not SearchBox:IsFocused() then
        CreateTween(SearchStroke, {Color = Colors.BorderActive}, 0.15)
    end
end)
SearchContainer.MouseLeave:Connect(function()
    if not SearchBox:IsFocused() then
        CreateTween(SearchStroke, {Color = Colors.Border}, 0.15)
    end
end)
SearchBox.Focused:Connect(function()
    CreateTween(SearchStroke, {Color = Colors.Accent}, 0.2)
    CreateTween(SearchIcon, {ImageColor3 = Colors.Accent}, 0.2)
    CreateTween(SearchContainer, {Size = UDim2.new(0, 222, 0, 32), Position = UDim2.new(1, -277, 0.5, -16)}, 0.2)
end)
SearchBox.FocusLost:Connect(function()
    CreateTween(SearchStroke, {Color = Colors.Border}, 0.2)
    CreateTween(SearchIcon, {ImageColor3 = Colors.TextDim}, 0.2)
    CreateTween(SearchContainer, {Size = UDim2.new(0, 205, 0, 32), Position = UDim2.new(1, -260, 0.5, -16)}, 0.2)
end)
ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, 0, 1, -64)
ContentArea.Position = UDim2.new(0, 0, 0, 64)
ContentArea.BackgroundColor3 = Colors.Background
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
ContentArea.ZIndex = 6
ContentArea.Parent = ContentPanel
makeCorner(ContentArea, 14)
makeStroke(ContentArea, Colors.Border, 1)
Footer = Instance.new("Frame")
Footer.Size = UDim2.new(0, 0, 0, 0)
Footer.BackgroundTransparency = 1
Footer.Visible = false
Footer.Parent = MainFrame
panels = {}
navButtons = {}
AllRegisteredCards = {}
local registeredCardsSet = {}
local panelItemCounters = {}
local function getNextLayoutOrder(p)
    if not p then return 1 end
    panelItemCounters[p] = (panelItemCounters[p] or 0) + 1
    return panelItemCounters[p]
end
function registerSearchCard(card, name, origParent)
    if card and origParent and name then
        if registeredCardsSet[card] then return end
        registeredCardsSet[card] = true
        local cleanSearchName = string.lower(tostring(name or "")):gsub("<[^>]->", "")
        local assignedOrder = card.LayoutOrder
        if not assignedOrder or assignedOrder <= 0 then
            assignedOrder = getNextLayoutOrder(origParent)
            card.LayoutOrder = assignedOrder
        end
        pcall(function() card:SetAttribute("PearlOrigOrder", assignedOrder) end)
        table.insert(AllRegisteredCards, {
            card = card,
            name = cleanSearchName,
            origParent = origParent,
            origOrder = assignedOrder
        })
    end
end
function createPanel(name)
    local panel = Instance.new("ScrollingFrame")
    panel.Name = name
    panel.Size = UDim2.new(1, -24, 1, -24)
    panel.Position = UDim2.new(0, 12, 0, 12)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 3
    panel.ScrollBarImageColor3 = Colors.Accent
    panel.ScrollBarImageTransparency = 0.5
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.CanvasSize = UDim2.new(0, 0, 0, 0)
    panel.Visible = false
    panel.ZIndex = 7
    panel.Parent = ContentArea
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 20)
    pad.Parent = panel
    table.insert(accentDynamicObjects, function()
        panel.ScrollBarImageColor3 = Colors.Accent
    end)
    panels[name] = panel
    return panel
end
SearchPanel = createPanel("Search")
local NoResultContainer = Instance.new("Frame")
NoResultContainer.Size = UDim2.new(1, 0, 0, 120)
NoResultContainer.BackgroundTransparency = 1
NoResultContainer.Visible = false
NoResultContainer.LayoutOrder = 999999
NoResultContainer.Parent = SearchPanel
local NoResultLabel = Instance.new("TextLabel")
NoResultLabel.Size = UDim2.new(1, 0, 0, 24)
NoResultLabel.Position = UDim2.new(0, 0, 0, 40)
NoResultLabel.BackgroundTransparency = 1
NoResultLabel.Font = Enum.Font.GothamMedium
NoResultLabel.Text = "Aucune option trouvee"
NoResultLabel.TextColor3 = Colors.TextDim
NoResultLabel.TextSize = 13
NoResultLabel.Parent = NoResultContainer
categories = {
    { name = "3xploit",  key = "3XPLOIT" },
    { name = "ESP",      key = "VISUAL" },
    { name = "Player",   key = "PLAYER" },
    { name = "Settings", key = "SETTINGS" },
}
activeNav = "3XPLOIT"
function switchCategory(key)
    for name, panel in pairs(panels) do
        if name == key then
            panel.Visible = true
            panel.Position = UDim2.new(0, 26, 0, 12)
            CreateTween(panel, {Position = UDim2.new(0, 12, 0, 12)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        else
            panel.Visible = false
        end
    end
    for _, data in ipairs(navButtons) do
        local isActive = (data.key == key)
        if isActive then
            CreateTween(data.btn, {BackgroundColor3 = Colors.AccentDark, BackgroundTransparency = 0}, 0.2)
            CreateTween(data.icon, {ImageColor3 = Colors.Accent, ImageTransparency = 0}, 0.2)
            CreateTween(data.pill, {Size = UDim2.new(0, 3, 0, 20), BackgroundTransparency = 0}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            PanelTitle.Text = data.title
        else
            CreateTween(data.btn, {BackgroundTransparency = 1}, 0.2)
            CreateTween(data.icon, {ImageColor3 = Colors.Text, ImageTransparency = 0.2}, 0.2)
            CreateTween(data.pill, {Size = UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1}, 0.2)
        end
    end
    activeNav = key
    if setVisualPreviewVisible then
        setVisualPreviewVisible(key == "VISUAL" and MainFrame.Visible)
    end
    if key == "PLAYER" and _G.refreshMM2PlayerList then
        pcall(_G.refreshMM2PlayerList)
    end
end
function filterCards(query)
    local rawQuery = tostring(query or "")
    local cleanQuery = string.lower(rawQuery):match("^%s*(.-)%s*$")
    if not cleanQuery or cleanQuery == "" then
        ClearSearchBtn.Visible = false
        for _, item in ipairs(AllRegisteredCards) do
            if item.card and item.origParent then
                item.card.Parent = item.origParent
                item.card.LayoutOrder = item.origOrder or 1
                item.card.Visible = true
            end
        end
        SearchPanel.Visible = false
        NoResultContainer.Visible = false
        switchCategory(activeNav)
    else
        ClearSearchBtn.Visible = true
        for name, panel in pairs(panels) do
            if name ~= "Search" then panel.Visible = false end
        end
        SearchPanel.Visible = true
        SearchPanel.Position = UDim2.new(0, 12, 0, 12)
        local matchCount = 0
        for _, item in ipairs(AllRegisteredCards) do
            if item.card and item.origParent then
                if string.find(item.name, cleanQuery, 1, true) then
                    matchCount = matchCount + 1
                    item.card.Parent = SearchPanel
                    item.card.LayoutOrder = matchCount
                    item.card.Visible = true
                else
                    if item.card.Parent == SearchPanel then
                        item.card.Parent = item.origParent
                        item.card.LayoutOrder = item.origOrder or 1
                    end
                end
            end
        end
        if matchCount == 0 then
            PanelTitle.Text = "Aucun résultat"
            NoResultContainer.Visible = true
            NoResultLabel.Text = 'Aucune option pour "' .. rawQuery .. '"'
        else
            PanelTitle.Text = "Résultats (" .. tostring(matchCount) .. ")"
            NoResultContainer.Visible = false
        end
    end
end
ClearSearchBtn.MouseButton1Click:Connect(function()
    SearchBox.Text = ""
    filterCards("")
end)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterCards(SearchBox.Text)
end)
function createNavButton(key, title, order)
    local btn = Instance.new("ImageButton")
    btn.Name = key
    btn.Size = UDim2.new(0, 44, 0, 44)
    btn.BackgroundColor3 = Colors.AccentDark
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.ZIndex = 8
    btn.Parent = NavContainer
    makeCorner(btn, 12)
    local btnScale = Instance.new("UIScale")
    btnScale.Scale = 1
    btnScale.Parent = btn
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 3, 0, 0)
    pill.AnchorPoint = Vector2.new(0, 0.5)
    pill.Position = UDim2.new(0, -8, 0.5, 0)
    pill.BackgroundColor3 = Colors.Accent
    pill.BackgroundTransparency = 1
    pill.BorderSizePixel = 0
    pill.ZIndex = 9
    pill.Parent = btn
    makeCorner(pill, 2)
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 22, 0, 22)
    icon.Position = UDim2.new(0.5, -11, 0.5, -11)
    icon.BackgroundTransparency = 1
    icon.Image = CategoryIcons[key] or "rbxassetid://7733964719"
    icon.ImageColor3 = Colors.Text
    icon.ImageTransparency = 0.2
    icon.ZIndex = 9
    icon.Parent = btn
    table.insert(accentDynamicObjects, function()
        pill.BackgroundColor3 = Colors.Accent
        if activeNav == key then
            btn.BackgroundColor3 = Colors.AccentDark
            icon.ImageColor3 = Colors.Accent
        end
    end)
    btn.MouseEnter:Connect(function()
        if activeNav ~= key then
            CreateTween(btnScale, {Scale = 1.07}, 0.15)
            CreateTween(btn, {BackgroundTransparency = 0.65, BackgroundColor3 = Colors.Card}, 0.15)
            CreateTween(icon, {ImageColor3 = Color3.fromRGB(255, 255, 255), ImageTransparency = 0}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeNav ~= key then
            CreateTween(btnScale, {Scale = 1}, 0.15)
            CreateTween(btn, {BackgroundTransparency = 1}, 0.15)
            CreateTween(icon, {ImageColor3 = Colors.Text, ImageTransparency = 0.2}, 0.15)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        playClick()
        CreateTween(btnScale, {Scale = 0.86}, 0.09)
        task.delay(0.09, function()
            CreateTween(btnScale, {Scale = 1}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end)
        if SearchBox.Text ~= "" then
            SearchBox.Text = ""
        end
        switchCategory(key)
    end)
    return btn, icon, pill
end
for index, cat in ipairs(categories) do
    local btn, icon, pill = createNavButton(cat.key, cat.name, index)
    table.insert(navButtons, { key = cat.key, title = cat.name, btn = btn, icon = icon, pill = pill })
    createPanel(cat.key)
end
function createSectionHeader(parent, title, order)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 26)
    header.BackgroundTransparency = 1
    header.LayoutOrder = (order and order > 0) and order or getNextLayoutOrder(parent)
    header.ZIndex = 8
    header.Parent = parent
    local TitleContainer = Instance.new("Frame")
    TitleContainer.Size = UDim2.new(0, 0, 1, 0)
    TitleContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    TitleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    TitleContainer.BackgroundTransparency = 1
    TitleContainer.AutomaticSize = Enum.AutomaticSize.X
    TitleContainer.Parent = header
    local TitleLayout = Instance.new("UIListLayout")
    TitleLayout.FillDirection = Enum.FillDirection.Horizontal
    TitleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TitleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TitleLayout.Padding = UDim.new(0, 6)
    TitleLayout.Parent = TitleContainer
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.BackgroundTransparency = 1
    lbl.Text = tostring(title):upper()
    lbl.TextColor3 = Colors.Accent
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11.5
    lbl.Parent = TitleContainer
    local HelpIcon = Instance.new("ImageLabel")
    HelpIcon.Size = UDim2.new(0, 13, 0, 13)
    HelpIcon.BackgroundTransparency = 1
    HelpIcon.Image = "rbxassetid://7733956210"
    HelpIcon.ImageColor3 = Colors.Accent
    HelpIcon.Parent = TitleContainer
    table.insert(accentDynamicObjects, function()
        lbl.TextColor3 = Colors.Accent
        HelpIcon.ImageColor3 = Colors.Accent
    end)
    return header
end
function createCard(parent, order, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height or 48)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    local assignedOrder = (order and order > 0) and order or getNextLayoutOrder(parent)
    card.LayoutOrder = assignedOrder
    card.ZIndex = 8
    card.Parent = parent
    makeCorner(card, 10)
    local cardStroke = makeStroke(card, Colors.Border, 1)
    card.MouseEnter:Connect(function()
        CreateTween(card, {BackgroundColor3 = Colors.CardSub}, 0.15)
        CreateTween(cardStroke, {Color = Colors.BorderActive}, 0.15)
    end)
    card.MouseLeave:Connect(function()
        CreateTween(card, {BackgroundColor3 = Colors.Card}, 0.15)
        CreateTween(cardStroke, {Color = Colors.Border}, 0.15)
    end)
    return card
end
function createButton(parent, text, subtext, order, callback)
    local card = createCard(parent, order, subtext and 54 or 46)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -96, 0, 18)
    title.Position = UDim2.new(0, 14, 0, subtext and 8 or 14)
    title.BackgroundTransparency = 1
    title.Text = text
    title.TextColor3 = Colors.Text
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 9
    title.Parent = card
    if subtext then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -96, 0, 14)
        sub.Position = UDim2.new(0, 14, 0, 27)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextColor3 = Colors.TextDim
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.ZIndex = 9
        sub.Parent = card
    end
    local action = Instance.new("TextButton")
    action.Size = UDim2.new(0, 74, 0, 26)
    action.Position = UDim2.new(1, -86, 0.5, -13)
    action.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    action.BorderSizePixel = 0
    action.Text = "Lancer"
    action.TextColor3 = Colors.Text
    action.Font = Enum.Font.GothamBold
    action.TextSize = 10
    action.AutoButtonColor = false
    action.ZIndex = 10
    action.Parent = card
    makeCorner(action, 7)
    local aStroke = makeStroke(action, Colors.Border, 1)
    local btnScale = Instance.new("UIScale")
    btnScale.Scale = 1
    btnScale.Parent = action
    action.MouseEnter:Connect(function()
        CreateTween(btnScale, {Scale = 1.05}, 0.15)
        CreateTween(action, {BackgroundColor3 = Colors.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.15)
        CreateTween(aStroke, {Color = Colors.AccentLight}, 0.15)
    end)
    action.MouseLeave:Connect(function()
        CreateTween(btnScale, {Scale = 1}, 0.15)
        CreateTween(action, {BackgroundColor3 = Color3.fromRGB(24, 24, 28), TextColor3 = Colors.Text}, 0.15)
        CreateTween(aStroke, {Color = Colors.Border}, 0.15)
    end)
    action.MouseButton1Click:Connect(function()
        playClick()
        CreateTween(btnScale, {Scale = 0.9}, 0.08)
        task.delay(0.08, function()
            CreateTween(btnScale, {Scale = 1}, 0.15, Enum.EasingStyle.Back)
        end)
        if callback then
            pcall(callback)
        end
    end)
    registerSearchCard(card, text .. " " .. tostring(subtext or ""), parent)
    return card
end
setToggleBtn = function(btn, value)
    if not btn then return end
    local isEnabled = (value == true)
    local stroke = btn:FindFirstChildOfClass("UIStroke")
    if isEnabled then
        btn.Text = "ON"
        CreateTween(btn, {BackgroundColor3 = Colors.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.18)
        if stroke then CreateTween(stroke, {Color = Colors.AccentLight}, 0.18) end
    else
        btn.Text = "OFF"
        CreateTween(btn, {BackgroundColor3 = Color3.fromRGB(24, 24, 28), TextColor3 = Colors.TextDim}, 0.18)
        if stroke then CreateTween(stroke, {Color = Colors.Border}, 0.18) end
    end
end
function createToggleCard(parent, text, subtext, order, getter, setter)
    local card = createCard(parent, order, subtext and 54 or 46)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -84, 0, 18)
    title.Position = UDim2.new(0, 14, 0, subtext and 8 or 14)
    title.BackgroundTransparency = 1
    title.Text = text
    title.TextColor3 = Colors.Text
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 9
    title.Parent = card
    if subtext then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -84, 0, 14)
        sub.Position = UDim2.new(0, 14, 0, 27)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextColor3 = Colors.TextDim
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.ZIndex = 9
        sub.Parent = card
    end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 52, 0, 24)
    btn.Position = UDim2.new(1, -66, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    btn.BorderSizePixel = 0
    btn.Text = "OFF"
    btn.TextColor3 = Colors.TextDim
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.ZIndex = 10
    btn.Parent = card
    makeCorner(btn, 6)
    makeStroke(btn, Colors.Border, 1)
    local btnScale = Instance.new("UIScale")
    btnScale.Scale = 1
    btnScale.Parent = btn
    table.insert(accentDynamicObjects, function()
        setToggleBtn(btn, getter())
    end)
    btn.MouseButton1Click:Connect(function()
        pcall(function() GuiService.SelectedObject = nil end)
        playClick()
        CreateTween(btnScale, {Scale = 0.82}, 0.08)
        task.delay(0.08, function()
            CreateTween(btnScale, {Scale = 1.12}, 0.12, Enum.EasingStyle.Back)
            task.delay(0.12, function()
                CreateTween(btnScale, {Scale = 1.0}, 0.1)
            end)
        end)
        local newVal = not getter()
        setter(newVal)
        setToggleBtn(btn, newVal)
        notify(text, newVal and "Activé" or "Désactivé", newVal and Colors.Success or Colors.Info)
    end)
    setToggleBtn(btn, getter())
    registerSearchCard(card, text .. " " .. tostring(subtext or ""), parent)
    return card, btn
end
activeValueSlider = nil
activeValueSlider = nil
sliderMoveConn = nil
sliderEndConn = nil
if sliderMoveConn then pcall(function() sliderMoveConn:Disconnect() end) end
if sliderEndConn then pcall(function() sliderEndConn:Disconnect() end) end
sliderMoveConn = UserInputService.InputChanged:Connect(function(input)
    if activeValueSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        activeValueSlider(input.Position.X)
    end
end)
sliderEndConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeValueSlider = nil
    end
end)
function createValueSlider(parent, order, label, min, max, initial, onChange)
    local card = createCard(parent, order, 52)
    card.Active = true
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, -10, 0, 18)
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Colors.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 9
    lbl.Parent = card
    local valBox = Instance.new("Frame")
    valBox.Size = UDim2.new(0, 52, 0, 20)
    valBox.Position = UDim2.new(1, -66, 0, 6)
    valBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    valBox.BorderSizePixel = 0
    valBox.ZIndex = 9
    valBox.Parent = card
    makeCorner(valBox, 5)
    local valStroke = makeStroke(valBox, Colors.Border, 1)
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, 0, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(initial)
    valLbl.TextColor3 = Colors.Text
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 10
    valLbl.ZIndex = 10
    valLbl.Parent = valBox
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    track.BorderSizePixel = 0
    track.ZIndex = 9
    track.Active = true
    track.Parent = card
    makeCorner(track, 4)
    local initPct = math.clamp((initial - min) / (max - min), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initPct, 0, 1, 0)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 10
    fill.Parent = track
    makeCorner(fill, 4)
    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(1, -7, 0.5, -7)
    thumb.BackgroundColor3 = Colors.Accent
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 11
    thumb.Active = true
    thumb.Parent = fill
    makeCorner(thumb, 7)
    local thumbGlow = makeStroke(thumb, Colors.AccentDark, 2)
    local thumbScale = Instance.new("UIScale")
    thumbScale.Scale = 1
    thumbScale.Parent = thumb
    table.insert(accentDynamicObjects, function()
        fill.BackgroundColor3 = Colors.Accent
        thumb.BackgroundColor3 = Colors.Accent
        thumbGlow.Color = Colors.AccentDark
    end)
    local slideBtn = Instance.new("TextButton")
    slideBtn.Size = UDim2.new(1, -20, 0, 24)
    slideBtn.Position = UDim2.new(0, 10, 0, 25)
    slideBtn.BackgroundTransparency = 1
    slideBtn.Text = ""
    slideBtn.Active = true
    slideBtn.AutoButtonColor = false
    slideBtn.ZIndex = 15
    slideBtn.Parent = card
    local function updateFromX(x)
        local trackPos = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        if trackWidth <= 0 then return end
        local pct = math.clamp((x - trackPos) / trackWidth, 0, 1)
        local value = math.floor(min + pct * (max - min))
        valLbl.Text = tostring(value)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        if onChange then onChange(value) end
    end
    local function setValue(value)
        local pct = math.clamp((value - min) / (max - min), 0, 1)
        valLbl.Text = tostring(math.floor(value))
        fill.Size = UDim2.new(pct, 0, 1, 0)
        if onChange then onChange(math.floor(value)) end
    end
    local function startSlide(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeValueSlider = updateFromX
            CreateTween(thumbScale, {Scale = 1.3}, 0.15, Enum.EasingStyle.Back)
            CreateTween(valStroke, {Color = Colors.Accent}, 0.2)
            updateFromX(input.Position.X)
        end
    end
    slideBtn.InputBegan:Connect(startSlide)
    track.InputBegan:Connect(startSlide)
    thumb.InputBegan:Connect(startSlide)
    slideBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            CreateTween(thumbScale, {Scale = 1}, 0.15)
            CreateTween(valStroke, {Color = Colors.Border}, 0.2)
        end
    end)
    registerSearchCard(card, label, parent)
    return setValue
end
dragging = false
dragStart = nil
startPos = nil
minimized = false
menuOpen = true
isTogglingMenu = false
function enableDrag(frame)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
end
enableDrag(TopBar)
enableDrag(Sidebar)
inputChangedDragConn = UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        savedMenuPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        MainFrame.Position = savedMenuPos
    end
end)
inputEndedDragConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
function setMinimized(value)
    if isTogglingMenu then return end
    isTogglingMenu = true
    task.delay(0.26, function() isTogglingMenu = false end)
    minimized = value
    menuOpen = not value
    if not value then
        MainFrame.Visible = true
        if activeNav == "VISUAL" and setVisualPreviewVisible then
            setVisualPreviewVisible(true)
        end
        BubblesContainer.Visible = (BubblesEnabled == true)
        if DimmerEnabled then
            BackgroundDimmer.Visible = true
            CreateTween(BackgroundDimmer, {BackgroundTransparency = 0.45}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        else
            BackgroundDimmer.Visible = false
            BackgroundDimmer.BackgroundTransparency = 1
        end
        PanelScale.Scale = 0.74
        MainFrame.Position = UDim2.new(savedMenuPos.X.Scale, savedMenuPos.X.Offset, savedMenuPos.Y.Scale, savedMenuPos.Y.Offset + 40)
        CreateTween(PanelScale, {Scale = 1}, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        CreateTween(MainFrame, {Position = savedMenuPos}, 0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    else
        if setVisualPreviewVisible then
            setVisualPreviewVisible(false)
        end
        CreateTween(BackgroundDimmer, {BackgroundTransparency = 1}, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        CreateTween(PanelScale, {Scale = 0.75}, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        local tPos = CreateTween(MainFrame, {Position = UDim2.new(savedMenuPos.X.Scale, savedMenuPos.X.Offset, savedMenuPos.Y.Scale, savedMenuPos.Y.Offset + 35)}, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        tPos.Completed:Connect(function()
            if minimized then
                MainFrame.Visible = false
                BubblesContainer.Visible = false
                BackgroundDimmer.Visible = false
            end
        end)
    end
end
function toggleMenu()
    setMinimized(not minimized)
end
bindFeatures = {}
bindListening = nil
function GetKeyName(key)
    local s = tostring(key)
    local _, _, name = s:find("(%w+)$")
    return name or s
end
inputBeganToggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if bindListening then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local f = bindFeatures[bindListening]
            if f then
                f.key = input.KeyCode
                if f.keyBtn then
                    f.keyBtn.Text = GetKeyName(input.KeyCode)
                end
                notify("Keybind", bindListening .. " -> " .. GetKeyName(input.KeyCode), Colors.Success)
            end
            bindListening = nil
        end
        return
    end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.RightShift then
        setMinimized(not minimized)
    else
        for name, f in pairs(bindFeatures) do
            if f.key and f.set and input.KeyCode == f.key then
                f.set(not f.get())
                if f.btn then setToggleBtn(f.btn, f.get()) end
                notify(name, f.get() and "ON" or "OFF", f.get() and Colors.Success or Colors.Error)
            end
        end
    end
end)
ESPGui = nil
espLoopConn = nil
speedLoopConn = nil
flyLoopConn = nil
colorSliderMoveConn = nil
colorSliderEndConn = nil
FlingState = { Conn = nil, OrigPos = nil }
AutoCollectState = false
AutoFarmCoinsState = false
pistolAlertState = false
flingAllState = false
local pearlSessionAlive = true
local pearlAutoCollectState = false
local pearlAutoFarmState = false
local pearlPistolAlertState = false
local pearlFlingAllState = false
killAllConn = nil
killAllToggleState = false
killMurderToggleState = false
killAllBtn = nil
killMurderBtn = nil
killOrigPos = nil
invisConn = nil
invisSeat = nil
InvisState = false
compassGui = nil
compassConn = nil
compassState = false
specGui = nil
specConn = nil
specState = false
watermarkGui = nil
watermarkConn = nil
murderNotifConn = nil
fovConn = nil
playerSpectateConn = nil
playerAttachConn = nil
playerAttachBFConn = nil
function unloadMenu()
    if invLockSteppedConn then pcall(function() invLockSteppedConn:Disconnect() end); invLockSteppedConn = nil end
    if invCharAddedConn then pcall(function() invCharAddedConn:Disconnect() end); invCharAddedConn = nil end
    if invBackpackAddedConn then pcall(function() invBackpackAddedConn:Disconnect() end); invBackpackAddedConn = nil end
    if infJumpConn then pcall(function() infJumpConn:Disconnect() end); infJumpConn = nil end
    if jumpLoopConn then pcall(function() jumpLoopConn:Disconnect() end); jumpLoopConn = nil end
    if speedLoopConn then pcall(function() speedLoopConn:Disconnect() end); speedLoopConn = nil end
    if spinLoopConn then pcall(function() spinLoopConn:Disconnect() end); spinLoopConn = nil end
    if sliderMoveConn then pcall(function() sliderMoveConn:Disconnect() end); sliderMoveConn = nil end
    if sliderEndConn then pcall(function() sliderEndConn:Disconnect() end); sliderEndConn = nil end
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum then hum.AutoRotate = true; hum.WalkSpeed = 16 end
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
    end)
    if speedLoopConn then pcall(function() speedLoopConn:Disconnect() end); speedLoopConn = nil end
    if spinLoopConn then pcall(function() spinLoopConn:Disconnect() end); spinLoopConn = nil end
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum then hum.AutoRotate = true; hum.WalkSpeed = 16 end
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
    end)
    if watermarkConn then pcall(function() watermarkConn:Disconnect() end); watermarkConn = nil end
    if watermarkGui then pcall(function() watermarkGui:Destroy() end); watermarkGui = nil end
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanTouch = true
                end
            end
        end
    end)
    pearlSessionAlive = false
    pearlAutoCollectState = false
    pearlAutoFarmState = false
    pearlPistolAlertState = false
    pearlFlingAllState = false
    AutoCollectState = false
    AutoFarmCoinsState = false
    pistolAlertState = false
    flingAllState = false
    if InvisState then pcall(function() toggleInvisibility(false) end) end
    KillAuraState = false
    SheriffAimlockState = false
    pcall(function() LocalPlayer.CameraMode = Enum.CameraMode.Classic end)
    if playerSpectateConn then pcall(function() playerSpectateConn:Disconnect() end); playerSpectateConn = nil end
    if playerAttachConn then pcall(function() playerAttachConn:Disconnect() end); playerAttachConn = nil end
    if playerAttachBFConn then pcall(function() playerAttachBFConn:Disconnect() end); playerAttachBFConn = nil end
    pcall(function()
        local cam = workspace.CurrentCamera
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if cam and hum then
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = hum
        end
    end)
    if bubbleRenderConn then pcall(function() bubbleRenderConn:Disconnect() end); bubbleRenderConn = nil end
    if espPreviewConn then pcall(function() espPreviewConn:Disconnect() end); espPreviewConn = nil end
    if inputChangedDragConn then inputChangedDragConn:Disconnect() end
    if inputEndedDragConn then inputEndedDragConn:Disconnect() end
    if inputBeganToggleConn then inputBeganToggleConn:Disconnect() end
    if espLoopConn then espLoopConn:Disconnect(); espLoopConn = nil end
    if speedLoopConn then speedLoopConn:Disconnect(); speedLoopConn = nil end
    if flyLoopConn then flyLoopConn:Disconnect(); flyLoopConn = nil end
    if FlingState and FlingState.Conn then
        pcall(function() FlingState.Conn:Disconnect() end)
        FlingState.Conn = nil
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end)
    end
    AutoCollectState = false
    flingAllState = false
    if compassConn then pcall(function() compassConn:Disconnect() end); compassConn = nil end
    if specConn then pcall(function() specConn:Disconnect() end); specConn = nil end
    if watermarkConn then pcall(function() watermarkConn:Disconnect() end); watermarkConn = nil end
    if murderNotifConn then pcall(function() murderNotifConn:Disconnect() end); murderNotifConn = nil end
    if fovConn then pcall(function() fovConn:Disconnect() end); fovConn = nil end
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = 70 end
    end)
    if compassGui then pcall(function() compassGui:Destroy() end); compassGui = nil end
    if specGui then pcall(function() specGui:Destroy() end); specGui = nil end
    if watermarkGui then pcall(function() watermarkGui:Destroy() end); watermarkGui = nil end
    pcall(function() RunService:UnbindFromRenderStep("PearlSheriffAimLock") end)
    if killAllConn then
        pcall(function() killAllConn:Disconnect() end)
        killAllConn = nil
    end
    if invisConn then pcall(function() invisConn:Disconnect() end); invisConn = nil end
    if invisSeat then pcall(function() invisSeat:Destroy() end); invisSeat = nil end
    if InvisState then
        InvisState = false
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        p.Transparency = 0
                    elseif p:IsA("Decal") then
                        p.Transparency = 0
                    end
                end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                    hum.BreakJointsOnDeath = true
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
                end
            end
        end)
    end
    if colorSliderMoveConn then colorSliderMoveConn:Disconnect(); colorSliderMoveConn = nil end
    if colorSliderEndConn then colorSliderEndConn:Disconnect(); colorSliderEndConn = nil end
    getgenv().PearlTimebombLoaded = false
    getgenv().NebulaUILoaded = false
    pcall(function() ScreenGui:Destroy() end)
    if ESPGui then pcall(function() ESPGui:Destroy() end); ESPGui = nil end
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            for _, hl in ipairs(char:GetChildren()) do
                if hl.Name == "NebulaChams" or hl.Name == "PearlChams" then
                    pcall(function() hl:Destroy() end)
                end
            end
        end
    end
end
getgenv().PearlTimebombUnload = unloadMenu
getgenv().NebulaUIUnload = unloadMenu
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local bombKeywords = {"bomb", "timebomb", "tnt", "dynamite", "explosive", "c4", "detonator", "ticking", "hotpotato"}
local function matchesBombKeyword(str)
    if not str then return false end
    local low = string.lower(tostring(str))
    for _, kw in ipairs(bombKeywords) do
        if string.find(low, kw, 1, true) then
            return true
        end
    end
    return false
end
function hasPlayerBomb(player)
    if not player or not player.Parent then return false end
    local char = player.Character
    if not char or not char.Parent then return false end
    local foundAttr = false
    pcall(function()
        for k, v in pairs(char:GetAttributes()) do
            local lk = string.lower(tostring(k))
            if (lk:find("bomb") or lk:find("tag") or lk:find("holder") or lk:find("hot") or lk:find("tick")) and (v == true or (type(v) == "number" and v > 0) or tostring(v) == player.Name) then
                foundAttr = true
                break
            end
        end
        if not foundAttr then
            for k, v in pairs(player:GetAttributes()) do
                local lk = string.lower(tostring(k))
                if (lk:find("bomb") or lk:find("tag") or lk:find("holder") or lk:find("hot") or lk:find("tick")) and (v == true or (type(v) == "number" and v > 0) or tostring(v) == player.Name) then
                    foundAttr = true
                    break
                end
            end
        end
    end)
    if foundAttr then return true end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj.Name ~= "NebulaChams" and obj.Name ~= "PearlChams" then
            if (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Accessory") or obj:IsA("SpecialMesh")) and matchesBombKeyword(obj.Name) then
                return true
            elseif obj:IsA("Highlight") and obj.Enabled then
                return true
            elseif obj:IsA("BoolValue") and (matchesBombKeyword(obj.Name) or obj.Name:lower():find("tag") or obj.Name:lower():find("holder")) and obj.Value == true then
                return true
            elseif obj:IsA("BillboardGui") and obj.Enabled then
                local bName = obj.Name:lower()
                if bName:find("bomb") or bName:find("timer") or bName:find("countdown") or bName:find("clock") then
                    return true
                end
                for _, lbl in ipairs(obj:GetDescendants()) do
                    if lbl:IsA("TextLabel") and lbl.Visible and lbl.Text ~= "" then
                        local t = lbl.Text
                        if t:match("^%s*%d+%.?%d*%s*s?%s*$") or t:match("%d+:%d+") or matchesBombKeyword(t) then
                            return true
                        end
                    end
                end
            elseif obj:IsA("Sound") and obj.IsPlaying and (matchesBombKeyword(obj.Name) or obj.Name:lower():find("tick") or obj.Name:lower():find("beep") or obj.Name:lower():find("timer")) then
                return true
            end
        end
    end
    local bp = player:FindFirstChildOfClass("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and matchesBombKeyword(tool.Name) then
                return true
            end
        end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, child in ipairs(workspace:GetChildren()) do
            if child ~= char and matchesBombKeyword(child.Name) then
                local bPart = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
                if bPart and (bPart.Position - hrp.Position).Magnitude <= 4.8 then
                    return true
                end
            end
        end
    end
    return false
end
local cachedBombRemotes = {}
local lastRemoteScan = 0
local function getBombRemotes()
    if tick() - lastRemoteScan < 3 then
        return cachedBombRemotes
    end
    lastRemoteScan = tick()
    cachedBombRemotes = {}
    pcall(function()
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") then
                local n = desc.Name:lower()
                if n:find("bomb") or n:find("pass") or n:find("tag") or n:find("give") or n:find("hit") or n:find("touch") then
                    table.insert(cachedBombRemotes, desc)
                end
            end
        end
    end)
    return cachedBombRemotes
end
local passFrameStep = 0
function passBombToTarget(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer or not targetPlayer.Parent then return false end
    local myChar = LocalPlayer.Character
    local tChar = targetPlayer.Character
    if not myChar or not tChar then return false end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    local tRoot = tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("Torso") or tChar.PrimaryPart
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 or not tRoot or not tHum or tHum.Health <= 0 then
        return false
    end
    local origin = duelBoxOrigin or (killAuraSafeCFrame and killAuraSafeCFrame.Position) or myRoot.Position
    local distFromBox = (tRoot.Position - origin).Magnitude
    if distFromBox > 55 then
        return false
    end
    pcall(function()
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and (matchesBombKeyword(tool.Name) or not myChar:FindFirstChildOfClass("Tool")) then
                    myHum:EquipTool(tool)
                    break
                end
            end
        end
    end)
    passFrameStep = (passFrameStep + 1) % 3
    local tVel = tRoot.AssemblyLinearVelocity or Vector3.zero
    local horizVel = Vector3.new(tVel.X, 0, tVel.Z)
    local targetCF = tRoot.CFrame
    if passFrameStep == 0 then
        targetCF = CFrame.new(tRoot.Position + horizVel * 0.08) * (tRoot.CFrame - tRoot.CFrame.Position)
    elseif passFrameStep == 1 then
        targetCF = tRoot.CFrame * CFrame.new(0, 0, -1.05)
    else
        targetCF = tRoot.CFrame
    end
    myRoot.CFrame = targetCF
    myRoot.AssemblyLinearVelocity = tVel
    myRoot.AssemblyAngularVelocity = Vector3.zero
    if firetouchinterest then
        pcall(function()
            local targetParts = {
                tRoot,
                tChar:FindFirstChild("Head"),
                tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("Torso"),
                tChar:FindFirstChild("RightHand") or tChar:FindFirstChild("Right Arm"),
                tChar:FindFirstChild("LeftHand") or tChar:FindFirstChild("Left Arm"),
            }
            for _, myPart in ipairs(myChar:GetDescendants()) do
                if myPart:IsA("BasePart") then
                    for _, tp in ipairs(targetParts) do
                        if tp then
                            firetouchinterest(myPart, tp, 0)
                            firetouchinterest(myPart, tp, 1)
                        end
                    end
                end
            end
        end)
    end
    return true
end
exploitPanel = panels["3XPLOIT"]
createSectionHeader(exploitPanel, "Timebomb Duels — 3xploit", 1)
KillAuraBombState = false
killAuraSafeCFrame = nil
duelBoxOrigin = nil
local wasHoldingBomb = false
local currentRandomTarget = nil
local lastTargetSwitchTick = 0
local function isPlayerInMyBox(p, boxPos)
    if not p or p == LocalPlayer or not p.Character then return false end
    local tChar = p.Character
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
    local ff = tChar:FindFirstChildOfClass("ForceField")
    if not tHum or tHum.Health <= 0 or not tRoot or ff then
        return false
    end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    local origin = boxPos or myRoot.Position
    local horizDist = (Vector3.new(tRoot.Position.X, 0, tRoot.Position.Z) - Vector3.new(origin.X, 0, origin.Z)).Magnitude
    local vertDist = math.abs(tRoot.Position.Y - origin.Y)
    if horizDist > 55 or vertDist > 20 then
        return false
    end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {myChar, tChar}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local dir = tRoot.Position - origin
    local hit = workspace:Raycast(origin, dir, rayParams)
    if hit and hit.Instance and hit.Instance.CanCollide and hit.Distance < (dir.Magnitude - 2) then
        return false
    end
    return true
end
local function pickRandomBombTarget(refPos)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local origin = duelBoxOrigin or refPos or myRoot.Position
    local boxCandidates = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if isPlayerInMyBox(p, origin) and not hasPlayerBomb(p) then
            table.insert(boxCandidates, p)
        end
    end
    if #boxCandidates == 0 then
        return nil
    end
    if #boxCandidates == 1 then
        return boxCandidates[1]
    end
    local filtered = {}
    for _, cand in ipairs(boxCandidates) do
        if cand ~= currentRandomTarget then
            table.insert(filtered, cand)
        end
    end
    if #filtered > 0 then
        return filtered[math.random(1, #filtered)]
    end
    return boxCandidates[math.random(1, #boxCandidates)]
end
_, killAuraBombBtn = createToggleCard(exploitPanel, "Kill Aura (Auto Give Bomb H24)", "Donne la bombe uniquement au joueur dans votre box (sécurisé sans sortir)", 2,
    function() return KillAuraBombState end,
    function(v)
        KillAuraBombState = v
        wasHoldingBomb = false
        currentRandomTarget = nil
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if v and myRoot then
            killAuraSafeCFrame = myRoot.CFrame
            duelBoxOrigin = myRoot.Position
        else
            killAuraSafeCFrame = nil
            duelBoxOrigin = nil
        end
    end)
JumpPowerEnabled = false
JumpPowerValue = 65
jumpLoopConn = nil
local function applyJumpSettings()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and JumpPowerEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = JumpPowerValue
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
    end)
end
_, jumpToggleBtn = createToggleCard(exploitPanel, "Activer Saut (Jump Power)", "Débloque le saut dans l'arène et applique la puissance", 3,
    function() return JumpPowerEnabled end,
    function(v)
        JumpPowerEnabled = v
        if jumpLoopConn then pcall(function() jumpLoopConn:Disconnect() end); jumpLoopConn = nil end
        if v then
            applyJumpSettings()
            jumpLoopConn = RunService.Heartbeat:Connect(function()
                if JumpPowerEnabled then
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.UseJumpPower = true
                        if hum.JumpPower ~= JumpPowerValue then
                            hum.JumpPower = JumpPowerValue
                        end
                        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                    end
                end
            end)
            notify("Saut", "Saut débloqué (" .. tostring(JumpPowerValue) .. ")", Colors.Success)
        else
            notify("Saut", "Saut désactivé", Colors.Warning)
        end
    end)
createValueSlider(exploitPanel, 4, "Puissance de Saut (Jump Power)", 40, 200, 65, function(val)
    JumpPowerValue = val
    if JumpPowerEnabled then
        applyJumpSettings()
    end
end)
UserInputService.JumpRequest:Connect(function()
    if JumpPowerEnabled then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)
SpeedEnabled = false
SpeedValue = 45
speedLoopConn = nil
local function enableSpeedSystem(v)
    SpeedEnabled = v
    if speedLoopConn then pcall(function() speedLoopConn:Disconnect() end); speedLoopConn = nil end
    if not v then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum then
                hum.WalkSpeed = 16
            end
            if hrp then
                local yVel = hrp.AssemblyLinearVelocity.Y
                hrp.AssemblyLinearVelocity = Vector3.new(0, yVel, 0)
            end
        end)
    else
        speedLoopConn = RunService.Heartbeat:Connect(function()
            if not SpeedEnabled then return end
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not char or not hum or not hrp or hum.Health <= 0 then return end
                if hum.MoveDirection.Magnitude > 0.05 then
                    local moveVec = hum.MoveDirection.Unit
                    local yVel = hrp.AssemblyLinearVelocity.Y
                    hrp.AssemblyLinearVelocity = Vector3.new(moveVec.X * SpeedValue, yVel, moveVec.Z * SpeedValue)
                    if hum.WalkSpeed ~= 16 then
                        hum.WalkSpeed = 16
                    end
                else
                    local yVel = hrp.AssemblyLinearVelocity.Y
                    hrp.AssemblyLinearVelocity = Vector3.new(0, yVel, 0)
                    if hum.WalkSpeed ~= 16 then
                        hum.WalkSpeed = 16
                    end
                end
            end)
        end)
    end
end
_, speedToggleBtn = createToggleCard(exploitPanel, "WalkSpeed (Anti-TP)", "Augmente la vitesse de déplacement sans trigger l'anti-cheat", 5,
    function() return SpeedEnabled end,
    function(v)
        enableSpeedSystem(v)
        notify("Vitesse", v and ("WalkSpeed ON (" .. tostring(SpeedValue) .. ")") or "WalkSpeed OFF", v and Colors.Success or Colors.Warning)
    end)
createValueSlider(exploitPanel, 6, "Vitesse WalkSpeed", 16, 500, 45, function(val)
    SpeedValue = val
end)
SpinBotEnabled = false
SpinBotSpeed = 100
spinLoopConn = nil
local function enableSpinBotSystem(v)
    SpinBotEnabled = v
    if spinLoopConn then pcall(function() spinLoopConn:Disconnect() end); spinLoopConn = nil end
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutoRotate = not v
        end
    end)
    if v then
        spinLoopConn = RunService.Heartbeat:Connect(function(dt)
            if not SpinBotEnabled then return end
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local spinAngle = math.rad(SpinBotSpeed * dt * 10)
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, spinAngle, 0)
                end
            end)
        end)
    end
end
_, spinToggleBtn = createToggleCard(exploitPanel, "Spin Bot (Toupie)", "Fait tourner votre personnage à grande vitesse sur lui-même", 7,
    function() return SpinBotEnabled end,
    function(v)
        enableSpinBotSystem(v)
        notify("Spin Bot", v and "Spin Bot ON" or "Spin Bot OFF", v and Colors.Success or Colors.Warning)
    end)
createValueSlider(exploitPanel, 8, "Vitesse Spin Bot", 10, 1000, 100, function(val)
    SpinBotSpeed = val
end)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    pcall(function()
        if JumpPowerEnabled then
            applyJumpSettings()
        end
        if SpeedEnabled then
            enableSpeedSystem(true)
        end
        if SpinBotEnabled then
            enableSpinBotSystem(true)
        end
    end)
end)
killAllConn = RunService.Heartbeat:Connect(function()
    if not KillAuraBombState then
        duelBoxOrigin = nil
        return
    end
    pcall(function()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myChar or not myRoot or not myHum or myHum.Health <= 0 then
            wasHoldingBomb = false
            duelBoxOrigin = nil
            return
        end
        local iHaveBomb = hasPlayerBomb(LocalPlayer)
        if iHaveBomb then
            if not wasHoldingBomb then
                killAuraSafeCFrame = myRoot.CFrame
                duelBoxOrigin = myRoot.Position
                wasHoldingBomb = true
                currentRandomTarget = nil
            end
            if not currentRandomTarget
                or not currentRandomTarget.Parent
                or not currentRandomTarget.Character
                or not isPlayerInMyBox(currentRandomTarget, duelBoxOrigin)
                or hasPlayerBomb(currentRandomTarget)
                or (tick() - lastTargetSwitchTick >= 0.18) then
                currentRandomTarget = pickRandomBombTarget(duelBoxOrigin)
                lastTargetSwitchTick = tick()
            end
            if currentRandomTarget then
                passBombToTarget(currentRandomTarget)
            end
        else
            if wasHoldingBomb then
                wasHoldingBomb = false
                currentRandomTarget = nil
                if killAuraSafeCFrame then
                    myRoot.CFrame = killAuraSafeCFrame
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                    myRoot.AssemblyAngularVelocity = Vector3.zero
                end
            else
                killAuraSafeCFrame = myRoot.CFrame
                duelBoxOrigin = myRoot.Position
            end
        end
    end)
end)
VisualState = {
    Enabled = false,
    Box = false,
    Filled = false,
    Chams = false,
    Skeleton = false,
    Tracer = false,
    Name = false,
    Distance = false,
    Items = false,
    Health = false,
    Murder = false,
    Sheriff = false,
    Color = Color3.fromRGB(255, 255, 255),
}
ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "NebulaESPOverlay"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true
ESPGui.Parent = parent
espData = {}
function cleanESP(player)
    local data = espData[player]
    if data then
        pcall(function() data.folder:Destroy() end)
        if data.highlight then pcall(function() data.highlight:Destroy() end) end
        espData[player] = nil
    end
end
function getESPData(player)
    local data = espData[player]
    if not data then
        local folder = Instance.new("Folder")
        folder.Name = "ESP_" .. player.Name
        folder.Parent = ESPGui
        data = { folder = folder, highlight = nil, items = {} }
        espData[player] = data
    end
    return data
end
function getLine(folder, name)
    local f = folder:FindFirstChild(name)
    if not f then
        f = Instance.new("Frame")
        f.Name = name
        f.BorderSizePixel = 0
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BackgroundColor3 = VisualState.Color
        f.Parent = folder
    end
    return f
end
function posLine(line, from, to)
    local dx = to.X - from.X
    local dy = to.Y - from.Y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then
        line.Visible = false
        return
    end
    line.Visible = true
    line.Size = UDim2.new(0, len, 0, line.Size.Y.Offset)
    line.Position = UDim2.new(0, (from.X + to.X) / 2, 0, (from.Y + to.Y) / 2)
    line.Rotation = math.deg(math.atan2(dy, dx))
end
function getLabel(folder, name, size)
    local lbl = folder:FindFirstChild(name)
    if not lbl then
        lbl = Instance.new("TextLabel")
        lbl.Name = name
        lbl.Size = UDim2.new(0, size or 160, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = VisualState.Color
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextStrokeTransparency = 0.15
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.ZIndex = 2
        lbl.Parent = folder
    end
    return lbl
end
skeletonPairs = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
skeletonPairsR6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
function applyESPColor()
    local c = VisualState.Color
    for _, data in pairs(espData) do
        for _, child in ipairs(data.folder:GetChildren()) do
            if child:IsA("Frame") then
                child.BackgroundColor3 = c
            elseif child:IsA("TextLabel") then
                child.TextColor3 = c
            end
        end
        if data.highlight then
            data.highlight.FillColor = c
            data.highlight.OutlineColor = c
        end
    end
end
function getToolRole(toolOrName)
    if typeof(toolOrName) == "Instance" then
        if toolOrName:FindFirstChild("CreateBeam", true)
            or toolOrName:FindFirstChild("GunLocal", true)
            or toolOrName:FindFirstChild("GunServer", true)
            or toolOrName:FindFirstChild("ShootGun", true)
            or toolOrName:FindFirstChild("Shoot", true)
            or toolOrName:FindFirstChild("Reload", true)
            or toolOrName.Name == "Gun"
            or toolOrName.Name == "Revolver" then
            return "sheriff"
        end
        if toolOrName:FindFirstChild("Slash", true)
            or toolOrName:FindFirstChild("Stab", true)
            or toolOrName:FindFirstChild("Throw", true)
            or toolOrName:FindFirstChild("SlashStart", true)
            or toolOrName:FindFirstChild("KnifeLocal")
            or toolOrName:FindFirstChild("KnifeServer")
            or toolOrName.Name == "Knife" then
            return "murder"
        end
        toolOrName = toolOrName.Name
    end
    local n = tostring(toolOrName or ""):lower()
    local gunKws = {"gun", "pistol", "revolver", "rifle", "luger", "glock", "shotgun", "sniper", "uzi", "smg", "deagle", "ghost", "phantom", "bow", "cannon", "blaster", "laser", "raygun", "sheriff"}
    local knifeKws = {"knife", "dagger", "blade", "sword", "scythe", "claw", "shiv", "axe", "hatchet", "machete", "fang", "pike", "stick", "katana", "saber", "cleaver", "sickle"}
    for _, kw in ipairs(gunKws) do
        if n:find(kw, 1, true) then return "sheriff" end
    end
    for _, kw in ipairs(knifeKws) do
        if n:find(kw, 1, true) then return "murder" end
    end
    return nil
end
espTick = 0
itemScanTick = 0
function updateESP()
    if not VisualState.Enabled then
        for player in pairs(espData) do cleanESP(player) end
        return
    end
    espTick = espTick + 1
    itemScanTick = itemScanTick + 1
    local doUI = espTick % 2 == 0
    local cam = workspace.CurrentCamera
    if not cam then return end
    local viewport = cam.ViewportSize
    local localChar = LocalPlayer.Character
    local localRoot = localChar and (localChar:FindFirstChild("HumanoidRootPart") or localChar:FindFirstChild("Head"))
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            cleanESP(player)
        else
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not char or not char.Parent or not hum or hum.Health <= 0 then
                cleanESP(player)
            else
                local data = getESPData(player)
                local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                local root = char:FindFirstChild("HumanoidRootPart") or head
                if head and root then
                    if itemScanTick % 12 == 1 then
                        data.items = {}
                        local function scanTool(tool)
                            if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                                table.insert(data.items, tool)
                            end
                        end
                        local bp = player:FindFirstChildOfClass("Backpack") or player:FindFirstChild("Backpack")
                        if bp then
                            for _, tool in ipairs(bp:GetChildren()) do scanTool(tool) end
                        end
                        for _, tool in ipairs(char:GetChildren()) do scanTool(tool) end
                    end
                    data.hasBomb = hasPlayerBomb(player)
                    local pc = VisualState.Color
                    if VisualState.Murder and data.hasBomb then
                        pc = Color3.fromRGB(255, 55, 55)
                    end
                    local headPos, headOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.55, 0))
                    local feetPos, feetOn = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.1, 0))
                    local onScreen = headOn and feetOn and headPos.Z > 1
                    local hx, hy = math.floor(headPos.X + 0.5), math.floor(headPos.Y + 0.5)
                    local fx, fy = math.floor(feetPos.X + 0.5), math.floor(feetPos.Y + 0.5)
                    if VisualState.Chams then
                        if not data.highlight then
                            local hl = Instance.new("Highlight")
                            hl.Name = "NebulaChams"
                            hl.FillColor = pc
                            hl.OutlineColor = pc
                            hl.FillTransparency = 0.45
                            hl.OutlineTransparency = 0
                            hl.Adornee = char
                            hl.Parent = char
                            data.highlight = hl
                        end
                    elseif data.highlight then
                        pcall(function() data.highlight:Destroy() end)
                        data.highlight = nil
                    end
                    if onScreen then
                        if doUI then
                        local boxH = math.clamp(math.abs(fy - hy), 16, 400)
                        local boxW = boxH * 0.62
                        local boxLeft = hx - boxW / 2
                        local boxTop = hy
                        local boxBottom = math.min(fy, viewport.Y - 2)
                        local drawH = math.max(boxBottom - boxTop, 2)
                        local cx, cy = hx, boxTop + drawH / 2
                        local showBox = VisualState.Box or VisualState.Filled
                        local fillFrame = data.folder:FindFirstChild("Fill")
                        if VisualState.Filled then
                            local fill = getLine(data.folder, "Fill")
                            fill.BackgroundTransparency = 0.65
                            fill.Size = UDim2.new(0, boxW, 0, boxH)
                            fill.Position = UDim2.new(0, cx, 0, cy)
                            fill.Visible = true
                        elseif fillFrame then
                            fillFrame.Visible = false
                        end
                        local top = getLine(data.folder, "Top")
                        local bottom = getLine(data.folder, "Bottom")
                        local left = getLine(data.folder, "Left")
                        local right = getLine(data.folder, "Right")
                        if VisualState.Box then
                            top.Size = UDim2.new(0, boxW, 0, 2)
                            top.Position = UDim2.new(0, cx, 0, boxTop)
                            top.Visible = true
                            bottom.Size = UDim2.new(0, boxW, 0, 2)
                            bottom.Position = UDim2.new(0, cx, 0, boxBottom)
                            bottom.Visible = true
                            left.Size = UDim2.new(0, 2, 0, drawH)
                            left.Position = UDim2.new(0, boxLeft, 0, cy)
                            left.Visible = true
                            right.Size = UDim2.new(0, 2, 0, drawH)
                            right.Position = UDim2.new(0, boxLeft + boxW, 0, cy)
                            right.Visible = true
                        else
                            top.Visible = false
                            bottom.Visible = false
                            left.Visible = false
                            right.Visible = false
                        end
                        if VisualState.Skeleton then
                            local pairs = hum.RigType == Enum.HumanoidRigType.R15 and skeletonPairs or skeletonPairsR6
                            local idx = 0
                            for _, pair in ipairs(pairs) do
                                local a = char:FindFirstChild(pair[1])
                                local b = char:FindFirstChild(pair[2])
                                if a and b then
                                    local pa, oa = cam:WorldToViewportPoint(a.Position)
                                    local pb, ob = cam:WorldToViewportPoint(b.Position)
                                    if oa and ob and pa.Z > 1 and pb.Z > 1 then
                                        idx = idx + 1
                                        local line = getLine(data.folder, "Sk" .. idx)
                                        line.Size = UDim2.new(0, 0, 0, 2)
                                        posLine(line, Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y))
                                    end
                                end
                            end
                            for j = idx + 1, 14 do
                                local l = data.folder:FindFirstChild("Sk" .. j)
                                if l then l.Visible = false end
                            end
                        else
                            for j = 1, 14 do
                                local l = data.folder:FindFirstChild("Sk" .. j)
                                if l then l.Visible = false end
                            end
                        end
                        if VisualState.Tracer then
                            local line = getLine(data.folder, "Tracer")
                            line.Size = UDim2.new(0, 0, 0, 2)
                            posLine(line, Vector2.new(viewport.X / 2, viewport.Y), Vector2.new(hx, hy))
                        else
                            local t = data.folder:FindFirstChild("Tracer")
                            if t then t.Visible = false end
                        end
                        if VisualState.Health then
                            local bg = getLine(data.folder, "HealthBg")
                            bg.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
                            bg.Size = UDim2.new(0, 5, 0, drawH)
                            bg.Position = UDim2.new(0, boxLeft - 8, 0, boxTop + drawH / 2)
                            bg.Visible = true
                            local fill = getLine(data.folder, "HealthFill")
                            local ratio = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 1
                            fill.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 0)
                            fill.AnchorPoint = Vector2.new(0.5, 1)
                            fill.Size = UDim2.new(0, 5, 0, math.floor(drawH * ratio))
                            fill.Position = UDim2.new(0, boxLeft - 8, 0, boxTop + drawH)
                            fill.Visible = true
                        else
                            local bg = data.folder:FindFirstChild("HealthBg")
                            if bg then bg.Visible = false end
                            local fill = data.folder:FindFirstChild("HealthFill")
                            if fill then fill.Visible = false end
                        end
                        if VisualState.Name or (VisualState.Murder and data.hasBomb) then
                            local nameLbl = getLabel(data.folder, "Name", 180)
                            nameLbl.Text = (data.hasBomb and "[BOMBE] " or "") .. player.DisplayName
                            nameLbl.Position = UDim2.new(0, hx - 90, 0, boxTop - 17)
                            nameLbl.Visible = true
                        else
                            local n = data.folder:FindFirstChild("Name")
                            if n then n.Visible = false end
                        end
                        if VisualState.Distance then
                            local distLbl = getLabel(data.folder, "Dist", 100)
                            local dist = localRoot and math.floor((localRoot.Position - root.Position).Magnitude) or 0
                            distLbl.Text = tostring(dist) .. "m"
                            distLbl.Position = UDim2.new(0, hx - 50, 0, fy + 2)
                            distLbl.Visible = true
                        else
                            local d = data.folder:FindFirstChild("Dist")
                            if d then d.Visible = false end
                        end
                        if VisualState.Items then
                            local idx = 0
                            for _, tool in ipairs(data.items) do
                                local handle = tool:FindFirstChild("Handle")
                                if handle and handle.Parent then
                                    local hp, hon = cam:WorldToViewportPoint(handle.Position)
                                    if hon and hp.Z > 1 then
                                        idx = idx + 1
                                        local box = getLine(data.folder, "ItemB" .. idx)
                                        box.Size = UDim2.new(0, 14, 0, 14)
                                        box.Position = UDim2.new(0, hp.X, 0, hp.Y)
                                        box.Visible = true
                                        local lbl = getLabel(data.folder, "ItemL" .. idx, 120)
                                        lbl.Text = tool.Name
                                        lbl.Position = UDim2.new(0, hp.X - 60, 0, hp.Y + 18)
                                        lbl.Visible = true
                                    end
                                end
                            end
                            for j = idx + 1, 3 do
                                local b = data.folder:FindFirstChild("ItemB" .. j)
                                if b then b.Visible = false end
                                local l = data.folder:FindFirstChild("ItemL" .. j)
                                if l then l.Visible = false end
                            end
                        else
                            for j = 1, 3 do
                                local b = data.folder:FindFirstChild("ItemB" .. j)
                                if b then b.Visible = false end
                                local l = data.folder:FindFirstChild("ItemL" .. j)
                                if l then l.Visible = false end
                            end
                        end
                        end
                    else
                        for _, child in ipairs(data.folder:GetChildren()) do
                            if child:IsA("Frame") then child.Visible = false end
                            if child:IsA("TextLabel") then child.Visible = false end
                        end
                    end
                    for _, child in ipairs(data.folder:GetChildren()) do
                        if child:IsA("Frame") then
                            if child.Name ~= "HealthBg" and child.Name ~= "HealthFill" then
                                child.BackgroundColor3 = pc
                            end
                        elseif child:IsA("TextLabel") then
                            child.TextColor3 = pc
                        end
                    end
                    if data.highlight then
                        data.highlight.FillColor = pc
                        data.highlight.OutlineColor = pc
                    end
                end
            end
        end
    end
end
espLoopConn = RunService.RenderStepped:Connect(updateESP)
visualPanel = panels["VISUAL"]
createSectionHeader(visualPanel, "ESP", 1)
enableCard, enableBtn = createToggleCard(visualPanel, "Enable ESP", "Active le module ESP", 2,
    function() return VisualState.Enabled end,
    function(v) VisualState.Enabled = v end)
featureDefs = {
    {"Box", "Boite 2D autour du joueur", 3, "Box"},
    {"Filled Box", "Boite remplie semi-transparente", 4, "Filled"},
    {"Chams", "Coloration du corps a travers les murs", 5, "Chams"},
    {"Skeleton", "Squelette du joueur", 6, "Skeleton"},
    {"Tracer", "Ligne depuis le bas de l'ecran", 7, "Tracer"},
    {"Name", "Nom au-dessus du joueur", 8, "Name"},
    {"Distance", "Distance en metres", 9, "Distance"},
    {"Items ESP", "Arme tenue dans la main", 10, "Items"},
    {"Health Bar", "Barre de vie au-dessus du joueur", 11, "Health"},
}
espFeatureBtns = {}
for _, def in ipairs(featureDefs) do
    local _, btn = createToggleCard(visualPanel, def[1], def[2], def[3],
        function() return VisualState[def[4]] end,
        function(v) VisualState[def[4]] = v end)
    espFeatureBtns[def[4]] = btn
end
createSectionHeader(visualPanel, "Timebomb Duels", 12)
VisualState.Murder = true
murderCard, murderBtn = createToggleCard(visualPanel, "ESP Porteur Bombe", "Affiche le joueur qui a la bombe en rouge vif [BOMBE]", 13,
    function() return VisualState.Murder end,
    function(v) VisualState.Murder = v end)
createSectionHeader(visualPanel, "Couleur ESP", 16)
do
    local PaletteCard = createCard(visualPanel, 17, 50)
    local palTitle = Instance.new("TextLabel")
    palTitle.Size = UDim2.new(0, 120, 1, 0)
    palTitle.Position = UDim2.new(0, 14, 0, 0)
    palTitle.BackgroundTransparency = 1
    palTitle.Text = "Couleur ESP"
    palTitle.TextColor3 = Colors.Text
    palTitle.Font = Enum.Font.GothamMedium
    palTitle.TextSize = 12
    palTitle.TextXAlignment = Enum.TextXAlignment.Left
    palTitle.ZIndex = 9
    palTitle.Parent = PaletteCard
    local SwatchRow = Instance.new("Frame")
    SwatchRow.Size = UDim2.new(1, -145, 0, 28)
    SwatchRow.Position = UDim2.new(0, 135, 0.5, -14)
    SwatchRow.BackgroundTransparency = 1
    SwatchRow.ZIndex = 9
    SwatchRow.Parent = PaletteCard
    local SwatchLayout = Instance.new("UIListLayout")
    SwatchLayout.FillDirection = Enum.FillDirection.Horizontal
    SwatchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    SwatchLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    SwatchLayout.Padding = UDim.new(0, 6)
    SwatchLayout.Parent = SwatchRow
    local espColors = {
        { name = "Violet Pearl", col = Color3.fromRGB(146, 112, 255) },
        { name = "Rouge",        col = Color3.fromRGB(255, 60, 60) },
        { name = "Bleu",         col = Color3.fromRGB(60, 140, 255) },
        { name = "Vert",         col = Color3.fromRGB(60, 235, 120) },
        { name = "Blanc",        col = Color3.fromRGB(255, 255, 255) },
        { name = "Rose Fluo",    col = Color3.fromRGB(255, 75, 195) },
        { name = "Orange",       col = Color3.fromRGB(255, 170, 45) },
        { name = "Cyan",         col = Color3.fromRGB(0, 230, 255) },
    }
    local swatchStrokes = {}
    for _, info in ipairs(espColors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 24, 0, 24)
        btn.BackgroundColor3 = info.col
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 10
        btn.Parent = SwatchRow
        makeCorner(btn, 6)
        local st = makeStroke(btn, Color3.fromRGB(80, 80, 95), 1, 0.4)
        table.insert(swatchStrokes, { stroke = st, col = info.col })
        local sc = Instance.new("UIScale")
        sc.Scale = 1
        sc.Parent = btn
        btn.MouseEnter:Connect(function()
            CreateTween(sc, {Scale = 1.12}, 0.14)
        end)
        btn.MouseLeave:Connect(function()
            CreateTween(sc, {Scale = 1}, 0.14)
        end)
        btn.MouseButton1Click:Connect(function()
            playClick()
            VisualState.Color = info.col
            applyESPColor()
            if updateEspSwatchHighlight then updateEspSwatchHighlight(info.col) end
            notify("ESP", "Couleur ESP : " .. info.name, info.col)
        end)
    end
    updateEspSwatchHighlight = function(targetCol)
        for _, entry in ipairs(swatchStrokes) do
            local dr = math.abs(entry.col.R - targetCol.R)
            local dg = math.abs(entry.col.G - targetCol.G)
            local db = math.abs(entry.col.B - targetCol.B)
            if (dr + dg + db) < 0.04 then
                entry.stroke.Color = Color3.fromRGB(255, 255, 255)
                entry.stroke.Thickness = 2
                entry.stroke.Transparency = 0
            else
                entry.stroke.Color = Color3.fromRGB(80, 80, 95)
                entry.stroke.Thickness = 1
                entry.stroke.Transparency = 0.4
            end
        end
    end
    updateEspSwatchHighlight(VisualState.Color)
    registerSearchCard(PaletteCard, "Couleur ESP Color Palette", visualPanel)
end
do
    local VP = {}
    local VisualPreview = Instance.new("Frame")
    VisualPreview.Name = "VisualPreviewWindow"
    VisualPreview.Size = UDim2.new(0, 290, 1, 0)
    VisualPreview.Position = UDim2.new(1, 14, 0, 0)
    VisualPreview.BackgroundColor3 = Color3.fromRGB(11, 11, 15)
    VisualPreview.BorderSizePixel = 0
    VisualPreview.ClipsDescendants = true
    VisualPreview.Visible = false
    VisualPreview.ZIndex = 6
    VisualPreview.Parent = MainFrame
    VP.Window = VisualPreview
    makeCorner(VisualPreview, 14)
    makeStroke(VisualPreview, Colors.Border, 1)
    local vpScale = Instance.new("UIScale")
    vpScale.Scale = 0.92
    vpScale.Parent = VisualPreview
    VP.Scale = vpScale
    local top = Instance.new("Frame")
    top.Name = "PreviewTop"
    top.Size = UDim2.new(1, 0, 0, 40)
    top.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    top.BorderSizePixel = 0
    top.ZIndex = 7
    top.Parent = VisualPreview
    makeCorner(top, 14)
    local cover = Instance.new("Frame")
    cover.Size = UDim2.new(1, 0, 0, 14)
    cover.Position = UDim2.new(0, 0, 1, -14)
    cover.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    cover.BorderSizePixel = 0
    cover.ZIndex = 7
    cover.Parent = top
    local div = Instance.new("Frame")
    div.Size = UDim2.new(1, 0, 0, 1)
    div.Position = UDim2.new(0, 0, 1, -1)
    div.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    div.BorderSizePixel = 0
    div.ZIndex = 8
    div.Parent = top
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ESP Preview"
    title.TextColor3 = Color3.fromRGB(225, 225, 240)
    title.TextSize = 12
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 9
    title.Parent = top
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 74, 1, 0)
    status.Position = UDim2.new(1, -86, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = "ESP OFF"
    status.TextColor3 = Color3.fromRGB(110, 110, 130)
    status.TextSize = 10
    status.Font = Enum.Font.GothamBold
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.ZIndex = 9
    status.Parent = top
    VP.StatusLabel = status
    local grid = Instance.new("Frame")
    grid.Name = "TacticalGrid"
    grid.Size = UDim2.new(1, 0, 1, -40)
    grid.Position = UDim2.new(0, 0, 0, 40)
    grid.BackgroundTransparency = 1
    grid.BorderSizePixel = 0
    grid.ZIndex = 6
    grid.Parent = VisualPreview
    for i = 1, 7 do
        local vLine = Instance.new("Frame")
        vLine.Size = UDim2.new(0, 1, 1, 0)
        vLine.Position = UDim2.new(i / 8, 0, 0, 0)
        vLine.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        vLine.BorderSizePixel = 0
        vLine.ZIndex = 6
        vLine.Parent = grid
    end
    for j = 1, 11 do
        local hLine = Instance.new("Frame")
        hLine.Size = UDim2.new(1, 0, 0, 1)
        hLine.Position = UDim2.new(0, 0, j / 12, 0)
        hLine.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        hLine.BorderSizePixel = 0
        hLine.ZIndex = 6
        hLine.Parent = grid
    end
    local aura = Instance.new("ImageLabel")
    aura.Name = "GlowAura"
    aura.BackgroundTransparency = 1
    aura.Image = "rbxassetid://5028857472"
    aura.ImageColor3 = VisualState.Color
    aura.ImageTransparency = 0.42
    aura.Visible = false
    aura.ZIndex = 6
    aura.Parent = grid
    VP.GlowAura = aura
    local vpf = Instance.new("ViewportFrame")
    vpf.Name = "PreviewViewport"
    vpf.Size = UDim2.new(1, 0, 1, -40)
    vpf.Position = UDim2.new(0, 0, 0, 40)
    vpf.BackgroundTransparency = 1
    vpf.BorderSizePixel = 0
    vpf.LightColor = Color3.fromRGB(245, 245, 255)
    vpf.Ambient = Color3.fromRGB(170, 170, 195)
    vpf.LightDirection = Vector3.new(-1, -1.2, -2)
    vpf.ZIndex = 7
    vpf.Parent = VisualPreview
    VP.VPF = vpf
    local world = Instance.new("WorldModel")
    world.Parent = vpf
    VP.World = world
    local cam = Instance.new("Camera")
    cam.FieldOfView = 36
    cam.CFrame = CFrame.new(Vector3.new(0, 0, 11.5), Vector3.new(0, 0, 0))
    cam.Parent = vpf
    vpf.CurrentCamera = cam
    VP.Camera = cam
    local overlay = Instance.new("Frame")
    overlay.Name = "ESPOverlay"
    overlay.Size = UDim2.new(1, 0, 1, -40)
    overlay.Position = UDim2.new(0, 0, 0, 40)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 25
    overlay.Parent = VisualPreview
    VP.Overlay = overlay
    local gLine = Instance.new("Frame")
    gLine.Size = UDim2.new(1, 0, 0, 1.5)
    gLine.Position = UDim2.new(0, 0, 0.84, 0)
    gLine.BackgroundColor3 = Color3.fromRGB(65, 70, 85)
    gLine.BorderSizePixel = 0
    gLine.ZIndex = 25
    gLine.Parent = overlay
    VP.GroundLine = gLine
    local box = Instance.new("Frame")
    box.Name = "BoxESP"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.ZIndex = 26
    box.Parent = overlay
    VP.BoxFrame = box
    local bStroke = Instance.new("UIStroke")
    bStroke.Thickness = 1.5
    bStroke.Color = VisualState.Color
    bStroke.Enabled = false
    bStroke.Parent = box
    VP.BoxStroke = bStroke
    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(0, 4, 1, 0)
    hpBg.Position = UDim2.new(0, -8, 0, 0)
    hpBg.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    hpBg.BorderSizePixel = 0
    hpBg.Visible = false
    hpBg.ZIndex = 26
    hpBg.Parent = box
    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(65, 235, 115)
    hpFill.BorderSizePixel = 0
    hpFill.ZIndex = 27
    hpFill.Parent = hpBg
    VP.HealthBarBg = hpBg
    VP.HealthBarFill = hpFill
    local nLbl = Instance.new("TextLabel")
    nLbl.Size = UDim2.new(0, 200, 0, 16)
    nLbl.AnchorPoint = Vector2.new(0.5, 0)
    nLbl.Position = UDim2.new(0.5, 0, 0, -19)
    nLbl.BackgroundTransparency = 1
    nLbl.Text = tostring(LocalPlayer.DisplayName)
    nLbl.TextColor3 = VisualState.Color
    nLbl.TextStrokeTransparency = 0.2
    nLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nLbl.Font = Enum.Font.GothamBold
    nLbl.TextSize = 12
    nLbl.Visible = false
    nLbl.ZIndex = 28
    nLbl.Parent = box
    VP.NameLabel = nLbl
    local dLbl = Instance.new("TextLabel")
    dLbl.Size = UDim2.new(0, 56, 0, 15)
    dLbl.Position = UDim2.new(1, 6, 0, -1)
    dLbl.BackgroundTransparency = 1
    dLbl.Text = "14m"
    dLbl.TextColor3 = VisualState.Color
    dLbl.TextStrokeTransparency = 0.2
    dLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    dLbl.Font = Enum.Font.GothamBold
    dLbl.TextSize = 11
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    dLbl.Visible = false
    dLbl.ZIndex = 28
    dLbl.Parent = box
    VP.DistLabel = dLbl
    local wLbl = Instance.new("TextLabel")
    wLbl.Size = UDim2.new(0, 200, 0, 15)
    wLbl.AnchorPoint = Vector2.new(0.5, 0)
    wLbl.Position = UDim2.new(0.5, 0, 1, 5)
    wLbl.BackgroundTransparency = 1
    wLbl.Text = "[Knife]"
    wLbl.TextColor3 = VisualState.Color
    wLbl.TextStrokeTransparency = 0.2
    wLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    wLbl.Font = Enum.Font.GothamBold
    wLbl.TextSize = 10
    wLbl.Visible = false
    wLbl.ZIndex = 28
    wLbl.Parent = box
    VP.WeaponLabel = wLbl
    local hDot = Instance.new("Frame")
    hDot.Size = UDim2.new(0, 18, 0, 18)
    hDot.AnchorPoint = Vector2.new(0.5, 0.5)
    hDot.BackgroundTransparency = 1
    hDot.Visible = false
    hDot.ZIndex = 28
    hDot.Parent = overlay
    makeCorner(hDot, 10)
    local hStroke = makeStroke(hDot, VisualState.Color, 1.5)
    VP.HeadDot = hDot
    VP.HeadDotStroke = hStroke
    local tLine = Instance.new("Frame")
    tLine.BackgroundColor3 = VisualState.Color
    tLine.BorderSizePixel = 0
    tLine.Visible = false
    tLine.ZIndex = 25
    tLine.AnchorPoint = Vector2.new(0.5, 0.5)
    tLine.Parent = overlay
    VP.TracerLine = tLine
    VP.SkeletonLines = {}
    for i = 1, 16 do
        local line = Instance.new("Frame")
        line.BackgroundColor3 = VisualState.Color
        line.BorderSizePixel = 0
        line.Visible = false
        line.ZIndex = 26
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Parent = overlay
        table.insert(VP.SkeletonLines, line)
    end
    VP.model = nil
    VP.root = nil
    VP.head = nil
    VP.bodyParts = {}
    VP.glowParts = {}
    VP.lastGlow = nil
    VP.lastGlowCol = nil
    VP.rot = 0
    VP.baseY = 0
    VP.dragging = false
    VP.dragStart = 0
    VP.initRot = 0
    VP.active = false
    local function projectToPreview(worldPos)
        local vpSize = VP.VPF.AbsoluteSize
        if vpSize.X <= 1 or vpSize.Y <= 1 then return nil, false end
        local rel = VP.Camera.CFrame:PointToObjectSpace(worldPos)
        local depth = -rel.Z
        if depth <= 0.05 then return nil, false end
        local halfH = depth * math.tan(math.rad(VP.Camera.FieldOfView) * 0.5)
        local halfW = halfH * (vpSize.X / vpSize.Y)
        local u = (rel.X / halfW) * 0.5 + 0.5
        local v = 0.5 - (rel.Y / halfH) * 0.5
        if u ~= u or v ~= v then return nil, false end
        return Vector2.new(u, v), true
    end
    local function update2DLineUV(lineFrame, uv1, uv2, thickness, color, ovW, ovH)
        local p1 = Vector2.new(uv1.X * ovW, uv1.Y * ovH)
        local p2 = Vector2.new(uv2.X * ovW, uv2.Y * ovH)
        local diff = p2 - p1
        local dist = diff.Magnitude
        if dist < 1 then
            lineFrame.Visible = false
            return
        end
        lineFrame.Size = UDim2.new(0, dist, 0, thickness or 1.5)
        lineFrame.Position = UDim2.fromScale((uv1.X + uv2.X) * 0.5, (uv1.Y + uv2.Y) * 0.5)
        lineFrame.Rotation = math.deg(math.atan2(diff.Y, diff.X))
        lineFrame.BackgroundColor3 = color
        lineFrame.Visible = true
    end
    local function setupPreviewCharacter()
        if VP.model then
            pcall(function() VP.model:Destroy() end)
            VP.model = nil
            VP.root = nil
            VP.head = nil
            VP.bodyParts = {}
            VP.glowParts = {}
            VP.lastGlow = nil
            VP.lastGlowCol = nil
        end
        local char = LocalPlayer.Character
        if not char then return end
        pcall(function()
            char.Archivable = true
            for _, desc in ipairs(char:GetDescendants()) do
                pcall(function() desc.Archivable = true end)
            end
        end)
        local clone = nil
        pcall(function() clone = char:Clone() end)
        pcall(function() char.Archivable = false end)
        if not clone then return end
        for _, item in ipairs(clone:GetChildren()) do
            if item:IsA("Tool") or item:IsA("HopperBin") or item:IsA("Highlight") then
                pcall(function() item:Destroy() end)
            end
        end
        for _, desc in ipairs(clone:GetDescendants()) do
            if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Sound") or desc:IsA("BillboardGui") or desc:IsA("Animator") or desc:IsA("AnimationController") or desc:IsA("Highlight") then
                pcall(function() desc:Destroy() end)
            end
        end
        local hrp = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso") or clone.PrimaryPart
        if not hrp then return end
        clone.PrimaryPart = hrp
        local hum = clone:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = true
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
        pcall(function() clone:PivotTo(CFrame.new(0, 0, 0)) end)
        local minY = 100000
        for _, p in ipairs(clone:GetDescendants()) do
            if p:IsA("BasePart") then
                local bY = p.Position.Y - (p.Size.Y / 2)
                if bY < minY then minY = bY end
            end
        end
        local deltaY = -2.5 - minY
        for _, p in ipairs(clone:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CFrame = CFrame.new(0, deltaY, 0) * p.CFrame
                p.CanCollide = false
                p.Anchored = true
            end
        end
        VP.bodyParts = {}
        for _, part in ipairs(clone:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 0.98 then
                table.insert(VP.bodyParts, part)
            end
        end
        local glowFolder = Instance.new("Folder")
        glowFolder.Name = "PreviewGlowShell"
        glowFolder.Parent = clone
        VP.glowParts = {}
        for _, part in ipairs(VP.bodyParts) do
            pcall(function()
                local sp = part:Clone()
                for _, ch in ipairs(sp:GetChildren()) do
                    if ch:IsA("SpecialMesh") then
                        pcall(function() ch.TextureId = "" end)
                    else
                        pcall(function() ch:Destroy() end)
                    end
                end
                sp.Size = part.Size * 1.05
                sp.CFrame = part.CFrame
                sp.Material = Enum.Material.ForceField
                sp.Color = VisualState.Color
                sp.Transparency = 1
                sp.CanCollide = false
                sp.Anchored = true
                sp.CastShadow = false
                pcall(function()
                    if sp:IsA("MeshPart") then sp.TextureID = "" end
                end)
                sp.Parent = glowFolder
                table.insert(VP.glowParts, sp)
            end)
        end
        VP.model = clone
        VP.root = hrp
        VP.head = clone:FindFirstChild("Head")
        VP.baseY = deltaY
        clone.Parent = VP.World
        VP.Camera.CFrame = CFrame.new(Vector3.new(0, 0, 11.5), Vector3.new(0, 0, 0))
    end
    VP.VPF.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            VP.dragging = true
            VP.dragStart = input.Position.X
            VP.initRot = VP.rot
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if VP.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            VP.rot = VP.initRot + ((input.Position.X - VP.dragStart) * 0.015)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            VP.dragging = false
        end
    end)
    setVisualPreviewVisible = function(visible)
        if not visible then
            VP.active = false
            if VP.Window and VP.Window.Visible then
                CreateTween(VP.Window, {Position = UDim2.new(1, -10, 0, 0)}, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                CreateTween(VP.Scale, {Scale = 0.88}, 0.18)
                task.delay(0.18, function()
                    if not VP.active and VP.Window then
                        VP.Window.Visible = false
                    end
                end)
            end
            return
        end
        if VP.active == true and VP.Window.Visible then return end
        VP.active = true
        pcall(setupPreviewCharacter)
        VP.Window.Visible = true
        VP.Window.Position = UDim2.new(1, -10, 0, 0)
        VP.Scale.Scale = 0.88
        CreateTween(VP.Window, {Position = UDim2.new(1, 14, 0, 0)}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        CreateTween(VP.Scale, {Scale = 1}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end
    espPreviewConn = RunService.RenderStepped:Connect(function()
        if not VP.Window or not VP.Window.Parent then return end
        if not VP.active or not VP.Window.Visible then return end
        if not VP.model or not VP.root or not VP.model.Parent then
            setupPreviewCharacter()
            if not VP.model or not VP.root then return end
        end
        VP.model:PivotTo(CFrame.new(0, VP.baseY, 0) * CFrame.Angles(0, VP.rot, 0))
        local totalScale = (PanelScale and PanelScale.Scale or 1) * (VP.Scale and VP.Scale.Scale or 1)
        if totalScale < 0.01 then totalScale = 1 end
        local ovW = VP.Overlay.AbsoluteSize.X / totalScale
        local ovH = VP.Overlay.AbsoluteSize.Y / totalScale
        if ovW <= 2 or ovH <= 2 then return end
        local minU, maxU, minV, maxV = 1, 0, 1, 0
        local hasBounds = false
        for _, part in ipairs(VP.bodyParts) do
            if part and part.Parent then
                local cf = part.CFrame
                local pos = cf.Position
                local rx = cf.RightVector * (part.Size.X * 0.5)
                local ry = cf.UpVector * (part.Size.Y * 0.5)
                local rz = cf.LookVector * (part.Size.Z * 0.5)
                for sx = -1, 1, 2 do
                    for sy = -1, 1, 2 do
                        for sz = -1, 1, 2 do
                            local uv, ok = projectToPreview(pos + rx * sx + ry * sy + rz * sz)
                            if ok then
                                if uv.X < minU then minU = uv.X end
                                if uv.X > maxU then maxU = uv.X end
                                if uv.Y < minV then minV = uv.Y end
                                if uv.Y > maxV then maxV = uv.Y end
                                hasBounds = true
                            end
                        end
                    end
                end
            end
        end
        if not hasBounds or maxU <= minU or maxV <= minV then
            VP.BoxFrame.Visible = false
            VP.GlowAura.Visible = false
            VP.TracerLine.Visible = false
            VP.HeadDot.Visible = false
            for _, l in ipairs(VP.SkeletonLines) do l.Visible = false end
            return
        end
        local floorV = math.clamp(maxV, 0.2, 0.95)
        VP.GroundLine.Position = UDim2.new(0, 0, floorV, 0)
        local bMinU = math.clamp(minU - 0.025, 0.04, 0.90)
        local bMaxU = math.clamp(maxU + 0.025, bMinU + 0.08, 0.96)
        local bMinV = math.clamp(minV - 0.014, 0.06, 0.90)
        local bMaxV = math.clamp(maxV + 0.008, bMinV + 0.10, 0.96)
        local bW = bMaxU - bMinU
        local bH = bMaxV - bMinV
        local centerU = (bMinU + bMaxU) * 0.5
        local curColor = VisualState.Color or Colors.Accent
        if VisualState.Murder then
            curColor = Color3.fromRGB(255, 60, 60)
        elseif VisualState.Sheriff then
            curColor = Color3.fromRGB(60, 140, 255)
        end
        VP.StatusLabel.Text = VisualState.Enabled and "ESP ON" or "ESP OFF"
        VP.StatusLabel.TextColor3 = VisualState.Enabled and Colors.Success or Color3.fromRGB(110, 110, 130)
        local hasBoxEl = VisualState.Box or VisualState.Filled or VisualState.Health or VisualState.Name or VisualState.Distance or VisualState.Items
        VP.BoxFrame.Visible = hasBoxEl
        if hasBoxEl then
            VP.BoxFrame.Position = UDim2.fromScale(bMinU, bMinV)
            VP.BoxFrame.Size = UDim2.fromScale(bW, bH)
            VP.BoxStroke.Enabled = VisualState.Box
            VP.BoxStroke.Color = curColor
            VP.BoxFrame.BackgroundColor3 = curColor
            VP.BoxFrame.BackgroundTransparency = VisualState.Filled and 0.72 or 1
            VP.HealthBarBg.Visible = VisualState.Health
            VP.NameLabel.Visible = VisualState.Name
            VP.NameLabel.TextColor3 = curColor
            VP.DistLabel.Visible = VisualState.Distance
            VP.DistLabel.TextColor3 = curColor
            VP.WeaponLabel.Visible = VisualState.Items
            VP.WeaponLabel.TextColor3 = curColor
        end
        VP.GlowAura.Visible = VisualState.Chams
        if VisualState.Chams then
            VP.GlowAura.Position = UDim2.fromScale(bMinU - 0.06, bMinV - 0.05)
            VP.GlowAura.Size = UDim2.fromScale(bW + 0.12, bH + 0.10)
            VP.GlowAura.ImageColor3 = curColor
        end
        if VP.lastGlow ~= VisualState.Chams or VP.lastGlowCol ~= curColor then
            VP.lastGlow = VisualState.Chams
            VP.lastGlowCol = curColor
            for _, sp in ipairs(VP.glowParts) do
                if sp and sp.Parent then
                    sp.Transparency = VisualState.Chams and 0.25 or 1
                    sp.Color = curColor
                end
            end
        end
        if VisualState.Tracer then
            update2DLineUV(VP.TracerLine, Vector2.new(0.5, 1.0), Vector2.new(centerU, bMaxV), 1.8, curColor, ovW, ovH)
        else
            VP.TracerLine.Visible = false
        end
        if VisualState.Skeleton and VP.model then
            local head = VP.head or VP.model:FindFirstChild("Head")
            if head then
                local uvHead, hOk = projectToPreview(head.Position)
                if hOk then
                    VP.HeadDot.Position = UDim2.fromScale(uvHead.X, uvHead.Y)
                    VP.HeadDotStroke.Color = curColor
                    VP.HeadDot.Visible = true
                else
                    VP.HeadDot.Visible = false
                end
            end
            local pairsList = (VP.model:FindFirstChild("UpperTorso") ~= nil) and skeletonPairs or skeletonPairsR6
            local lineIdx = 1
            for _, pair in ipairs(pairsList) do
                local pA = VP.model:FindFirstChild(pair[1])
                local pB = VP.model:FindFirstChild(pair[2])
                if pA and pB and lineIdx <= #VP.SkeletonLines then
                    local uv1, ok1 = projectToPreview(pA.Position)
                    local uv2, ok2 = projectToPreview(pB.Position)
                    if ok1 and ok2 then
                        update2DLineUV(VP.SkeletonLines[lineIdx], uv1, uv2, 1.8, curColor, ovW, ovH)
                        lineIdx = lineIdx + 1
                    end
                end
            end
            for i = lineIdx, #VP.SkeletonLines do
                VP.SkeletonLines[i].Visible = false
            end
        else
            VP.HeadDot.Visible = false
            for _, l in ipairs(VP.SkeletonLines) do l.Visible = false end
        end
    end)
end
activeValueSlider = nil
flyStateRefs = { bg = nil, bv = nil }
function stopFling()
    if FlingState.Conn then
        FlingState.Conn:Disconnect()
        FlingState.Conn = nil
    end
    if FlingState.StepConn then
        FlingState.StepConn:Disconnect()
        FlingState.StepConn = nil
    end
    pcall(function()
        if FlingState.OrigFallHeight then
            workspace.FallenPartsDestroyHeight = FlingState.OrigFallHeight
            FlingState.OrigFallHeight = nil
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if FlingState.BAV then
            pcall(function() FlingState.BAV:Destroy() end)
            FlingState.BAV = nil
        end
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            local cam = workspace.CurrentCamera
            if cam then
                cam.CameraSubject = hum
            end
        end
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.zero
                    part.RotVelocity = Vector3.zero
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
        if hrp and FlingState.OrigPos then
            for _ = 1, 4 do
                hrp.CFrame = FlingState.OrigPos
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                RunService.Heartbeat:Wait()
            end
        end
    end)
    FlingState.OrigPos = nil
end
function flingPlayer(player)
    if FlingState.Conn then stopFling() end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local tChar = player and player.Character
    local tRoot = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso") or tChar:FindFirstChild("UpperTorso"))
    if not tRoot then return end
    FlingState.OrigPos = hrp.CFrame
    pcall(function()
        FlingState.OrigFallHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
    end)
    pcall(function()
        local tHum = tChar:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        if cam and tHum then
            cam.CameraSubject = tHum
        end
    end)
    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "PearlFlingBAV"
    bav.AngularVelocity = Vector3.new(9e8, 9e8, 9e8)
    bav.MaxTorque = Vector3.new(9e8, 9e8, 9e8)
    bav.P = 9e8
    bav.Parent = hrp
    FlingState.BAV = bav
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum.PlatformStand = true
    local startTime = tick()
    local frameCounter = 0
    local angleIndex = 0
    FlingState.StepConn = RunService.Stepped:Connect(function()
        if not FlingState.Conn then return end
        pcall(function()
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end)
    end)
    FlingState.Conn = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not FlingState.Conn then return end
            if not player or not player.Parent or not player.Character then
                stopFling()
                return
            end
            local tRoot2 = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
            local tHum2 = player.Character:FindFirstChildOfClass("Humanoid")
            if not tRoot2 or (tHum2 and tHum2.Health <= 0) then
                stopFling()
                return
            end
            local tVel = tRoot2.AssemblyLinearVelocity or Vector3.zero
            if tVel.Magnitude > 115 and (tick() - startTime) > 0.35 then
                stopFling()
                return
            end
            frameCounter = frameCounter + 1
            local cycleStep = frameCounter % 5
            if cycleStep == 1 then
                angleIndex = angleIndex + 1
            end
            local strikeAngle = angleIndex * 1.35
            local strikeDir = Vector3.new(math.cos(strikeAngle), 0, math.sin(strikeAngle))
            if tVel.Magnitude > 2 then
                local moveHoriz = Vector3.new(tVel.X, 0, tVel.Z)
                if moveHoriz.Magnitude > 1 then
                    strikeDir = moveHoriz.Unit
                end
            end
            local targetPos = tRoot2.Position + (Vector3.new(tVel.X, 0, tVel.Z) * 0.14)
            if cycleStep == 1 then
                local farPos = targetPos - (strikeDir * 95) + Vector3.new(0, 18, 0)
                hrp.CFrame = CFrame.lookAt(farPos, targetPos)
                hrp.Velocity = strikeDir * 500000 + Vector3.new(0, 200000, 0)
                hrp.AssemblyLinearVelocity = strikeDir * 500000 + Vector3.new(0, 200000, 0)
                hrp.RotVelocity = Vector3.new(9e7, 9e7, 9e7)
                hrp.AssemblyAngularVelocity = Vector3.new(9e7, 9e7, 9e7)
            else
                local passOffset = (cycleStep - 3) * 1.35
                local impactPos = targetPos + (strikeDir * passOffset)
                local spinCF = CFrame.Angles(
                    math.rad(math.random(-180, 180)),
                    math.rad(math.random(-180, 180)),
                    math.rad(math.random(-180, 180))
                )
                hrp.CFrame = CFrame.new(impactPos) * spinCF
                hrp.Velocity = Vector3.new(9e7, 9e7, 9e7)
                hrp.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7)
                hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
                hrp.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
            end
            if tick() - startTime > 2.8 then
                stopFling()
            end
        end)
    end)
end
do
    local JoueurContent = panels["PLAYER"]
    JoueurContent.ScrollBarThickness = 0
    JoueurContent.ScrollBarImageTransparency = 1
    JoueurContent.ScrollingEnabled = false
    JoueurContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    JoueurContent.AutomaticCanvasSize = Enum.AutomaticSize.None
    JoueurContent.ClipsDescendants = true
    local existingLayout = JoueurContent:FindFirstChildOfClass("UIListLayout")
    if existingLayout then existingLayout:Destroy() end
    local existingPad = JoueurContent:FindFirstChildOfClass("UIPadding")
    if existingPad then existingPad:Destroy() end
    local PlayerTabRoot = Instance.new("Frame")
    PlayerTabRoot.Name = "PlayerTabRoot"
    PlayerTabRoot.Size = UDim2.new(1, 0, 1, 0)
    PlayerTabRoot.BackgroundTransparency = 1
    PlayerTabRoot.BorderSizePixel = 0
    PlayerTabRoot.ClipsDescendants = true
    PlayerTabRoot.ZIndex = 8
    PlayerTabRoot.Parent = JoueurContent
    local rootPad = Instance.new("UIPadding")
    rootPad.PaddingTop = UDim.new(0, 4)
    rootPad.PaddingBottom = UDim.new(0, 6)
    rootPad.PaddingLeft = UDim.new(0, 6)
    rootPad.PaddingRight = UDim.new(0, 6)
    rootPad.Parent = PlayerTabRoot
    local LeftCol = Instance.new("Frame")
    LeftCol.Name = "LeftCol"
    LeftCol.Size = UDim2.new(0.5, -7, 1, 0)
    LeftCol.Position = UDim2.new(0, 0, 0, 0)
    LeftCol.BackgroundTransparency = 1
    LeftCol.BorderSizePixel = 0
    LeftCol.ClipsDescendants = true
    LeftCol.ZIndex = 8
    LeftCol.Parent = PlayerTabRoot
    local LeftHeader = Instance.new("Frame")
    LeftHeader.Size = UDim2.new(1, -12, 0, 24)
    LeftHeader.Position = UDim2.new(0, 4, 0, 0)
    LeftHeader.BackgroundTransparency = 1
    LeftHeader.ZIndex = 9
    LeftHeader.Parent = LeftCol
    local LeftTitle = Instance.new("TextLabel")
    LeftTitle.Size = UDim2.new(0.65, 0, 1, 0)
    LeftTitle.BackgroundTransparency = 1
    LeftTitle.Text = "Player List"
    LeftTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    LeftTitle.Font = Enum.Font.GothamBold
    LeftTitle.TextSize = 14
    LeftTitle.TextXAlignment = Enum.TextXAlignment.Left
    LeftTitle.ZIndex = 9
    LeftTitle.Parent = LeftHeader
    local PlayerCountBadge = Instance.new("TextLabel")
    PlayerCountBadge.Size = UDim2.new(0, 75, 0, 20)
    PlayerCountBadge.Position = UDim2.new(1, -75, 0.5, -10)
    PlayerCountBadge.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    PlayerCountBadge.Text = "0 joueurs"
    PlayerCountBadge.TextColor3 = Color3.fromRGB(215, 215, 230)
    PlayerCountBadge.Font = Enum.Font.GothamBold
    PlayerCountBadge.TextSize = 10
    PlayerCountBadge.ZIndex = 9
    PlayerCountBadge.Parent = LeftHeader
    makeCorner(PlayerCountBadge, 10)
    makeStroke(PlayerCountBadge, Color3.fromRGB(50, 50, 68), 1)
    local FilterContainer = Instance.new("Frame")
    FilterContainer.Size = UDim2.new(1, -12, 0, 32)
    FilterContainer.Position = UDim2.new(0, 4, 0, 28)
    FilterContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    FilterContainer.BorderSizePixel = 0
    FilterContainer.ZIndex = 9
    FilterContainer.Parent = LeftCol
    makeCorner(FilterContainer, 8)
    local filterStroke = makeStroke(FilterContainer, Color3.fromRGB(34, 34, 48), 1)
    local FilterBox = Instance.new("TextBox")
    FilterBox.Size = UDim2.new(1, -20, 1, 0)
    FilterBox.Position = UDim2.new(0, 10, 0, 0)
    FilterBox.BackgroundTransparency = 1
    FilterBox.PlaceholderText = "Filtrer un joueur ou ID..."
    FilterBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
    FilterBox.Text = ""
    FilterBox.TextColor3 = Color3.fromRGB(240, 240, 250)
    FilterBox.Font = Enum.Font.GothamMedium
    FilterBox.TextSize = 11
    FilterBox.TextXAlignment = Enum.TextXAlignment.Left
    FilterBox.ClearTextOnFocus = false
    FilterBox.ZIndex = 10
    FilterBox.Parent = FilterContainer
    FilterBox.Focused:Connect(function()
        filterStroke.Color = Colors.Accent
    end)
    FilterBox.FocusLost:Connect(function()
        filterStroke.Color = Color3.fromRGB(34, 34, 48)
    end)
    local PlayerListScroll = Instance.new("ScrollingFrame")
    PlayerListScroll.Size = UDim2.new(1, 0, 1, -66)
    PlayerListScroll.Position = UDim2.new(0, 0, 0, 66)
    PlayerListScroll.BackgroundTransparency = 1
    PlayerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    PlayerListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PlayerListScroll.ScrollBarThickness = 3
    PlayerListScroll.ScrollBarImageColor3 = Colors.Accent
    PlayerListScroll.ScrollBarImageTransparency = 0.2
    PlayerListScroll.BorderSizePixel = 0
    PlayerListScroll.ClipsDescendants = true
    PlayerListScroll.ZIndex = 9
    PlayerListScroll.Parent = LeftCol
    local PlayerListPad = Instance.new("UIPadding")
    PlayerListPad.PaddingLeft = UDim.new(0, 4)
    PlayerListPad.PaddingRight = UDim.new(0, 8)
    PlayerListPad.PaddingTop = UDim.new(0, 4)
    PlayerListPad.PaddingBottom = UDim.new(0, 14)
    PlayerListPad.Parent = PlayerListScroll
    local PlayerListLayout = Instance.new("UIListLayout")
    PlayerListLayout.Padding = UDim.new(0, 6)
    PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PlayerListLayout.Parent = PlayerListScroll
    local CenterDivider = Instance.new("Frame")
    CenterDivider.Size = UDim2.new(0, 1, 1, -12)
    CenterDivider.Position = UDim2.new(0.5, 0, 0, 6)
    CenterDivider.BackgroundColor3 = Color3.fromRGB(32, 32, 46)
    CenterDivider.BorderSizePixel = 0
    CenterDivider.ZIndex = 8
    CenterDivider.Parent = PlayerTabRoot
    local RightCol = Instance.new("Frame")
    RightCol.Size = UDim2.new(0.5, -7, 1, 0)
    RightCol.Position = UDim2.new(0.5, 7, 0, 0)
    RightCol.BackgroundTransparency = 1
    RightCol.BorderSizePixel = 0
    RightCol.ClipsDescendants = true
    RightCol.ZIndex = 8
    RightCol.Parent = PlayerTabRoot
    local RightTitle = Instance.new("TextLabel")
    RightTitle.Size = UDim2.new(1, -12, 0, 24)
    RightTitle.Position = UDim2.new(0, 4, 0, 0)
    RightTitle.BackgroundTransparency = 1
    RightTitle.Text = "Actions Joueur"
    RightTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    RightTitle.Font = Enum.Font.GothamBold
    RightTitle.TextSize = 14
    RightTitle.TextXAlignment = Enum.TextXAlignment.Left
    RightTitle.ZIndex = 9
    RightTitle.Parent = RightCol
    local TargetCard = Instance.new("Frame")
    TargetCard.Size = UDim2.new(1, -12, 0, 48)
    TargetCard.Position = UDim2.new(0, 4, 0, 28)
    TargetCard.BackgroundColor3 = Color3.fromRGB(16, 15, 26)
    TargetCard.BorderSizePixel = 0
    TargetCard.ClipsDescendants = true
    TargetCard.ZIndex = 9
    TargetCard.Parent = RightCol
    makeCorner(TargetCard, 8)
    makeStroke(TargetCard, Color3.fromRGB(48, 38, 74), 1)
    local TargetAvatar = Instance.new("ImageLabel")
    TargetAvatar.Size = UDim2.new(0, 34, 0, 34)
    TargetAvatar.Position = UDim2.new(0, 8, 0.5, -17)
    TargetAvatar.BackgroundColor3 = Color3.fromRGB(24, 22, 34)
    TargetAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=100&h=100"
    TargetAvatar.BorderSizePixel = 0
    TargetAvatar.ZIndex = 10
    TargetAvatar.Parent = TargetCard
    makeCorner(TargetAvatar, 17)
    makeStroke(TargetAvatar, Colors.Accent, 1)
    local TargetHeaderLbl = Instance.new("TextLabel")
    TargetHeaderLbl.Size = UDim2.new(1, -95, 0, 14)
    TargetHeaderLbl.Position = UDim2.new(0, 48, 0, 7)
    TargetHeaderLbl.BackgroundTransparency = 1
    TargetHeaderLbl.Text = "CIBLE ACTIVE (VOUS)"
    TargetHeaderLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    TargetHeaderLbl.Font = Enum.Font.GothamBold
    TargetHeaderLbl.TextSize = 9
    TargetHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
    TargetHeaderLbl.ZIndex = 10
    TargetHeaderLbl.Parent = TargetCard
    local TargetNameLbl = Instance.new("TextLabel")
    TargetNameLbl.Size = UDim2.new(1, -95, 0, 18)
    TargetNameLbl.Position = UDim2.new(0, 48, 0, 22)
    TargetNameLbl.BackgroundTransparency = 1
    TargetNameLbl.Text = "Aucun joueur"
    TargetNameLbl.TextColor3 = Color3.fromRGB(245, 245, 255)
    TargetNameLbl.Font = Enum.Font.GothamBold
    TargetNameLbl.TextSize = 12
    TargetNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    TargetNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    TargetNameLbl.ZIndex = 10
    TargetNameLbl.Parent = TargetCard
    local TargetStatusPill = Instance.new("TextLabel")
    TargetStatusPill.Size = UDim2.new(0, 46, 0, 18)
    TargetStatusPill.Position = UDim2.new(1, -52, 0.5, -9)
    TargetStatusPill.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    TargetStatusPill.Text = "Moi"
    TargetStatusPill.TextColor3 = Color3.fromRGB(240, 240, 250)
    TargetStatusPill.Font = Enum.Font.GothamBold
    TargetStatusPill.TextSize = 9
    TargetStatusPill.ZIndex = 10
    TargetStatusPill.Parent = TargetCard
    makeCorner(TargetStatusPill, 9)
    local statusStroke = makeStroke(TargetStatusPill, Color3.fromRGB(60, 60, 78), 1)
    local SettingsContainer = Instance.new("ScrollingFrame")
    SettingsContainer.Size = UDim2.new(1, 0, 1, -82)
    SettingsContainer.Position = UDim2.new(0, 0, 0, 82)
    SettingsContainer.BackgroundTransparency = 1
    SettingsContainer.BorderSizePixel = 0
    SettingsContainer.ScrollBarThickness = 3
    SettingsContainer.ScrollBarImageColor3 = Colors.Accent
    SettingsContainer.ScrollBarImageTransparency = 0.2
    SettingsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    SettingsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    SettingsContainer.ClipsDescendants = true
    SettingsContainer.ZIndex = 9
    SettingsContainer.Parent = RightCol
    local SettingsPad = Instance.new("UIPadding")
    SettingsPad.PaddingLeft = UDim.new(0, 4)
    SettingsPad.PaddingRight = UDim.new(0, 8)
    SettingsPad.PaddingTop = UDim.new(0, 4)
    SettingsPad.PaddingBottom = UDim.new(0, 14)
    SettingsPad.Parent = SettingsContainer
    local SettingsLayout = Instance.new("UIListLayout")
    SettingsLayout.Padding = UDim.new(0, 6)
    SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SettingsLayout.Parent = SettingsContainer
    local selectedPlayer = LocalPlayer
    local actionRefreshers = {}
    local playerRowsByPlayer = {}
    local function updateTargetIndicator()
        if selectedPlayer and selectedPlayer.Parent then
            local isMe = (selectedPlayer == LocalPlayer)
            TargetAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(selectedPlayer.UserId) .. "&w=100&h=100"
            TargetNameLbl.Text = selectedPlayer.DisplayName .. " (@" .. selectedPlayer.Name .. ")"
            if isMe then
                TargetHeaderLbl.Text = "CIBLE ACTIVE (VOUS)"
                TargetHeaderLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                TargetStatusPill.Text = "Moi"
                TargetStatusPill.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
                TargetStatusPill.TextColor3 = Color3.fromRGB(245, 245, 255)
                statusStroke.Color = Color3.fromRGB(65, 65, 85)
            else
                TargetHeaderLbl.Text = "CIBLE SÉLECTIONNÉE"
                TargetHeaderLbl.TextColor3 = Color3.fromRGB(185, 185, 200)
                TargetStatusPill.Text = "En jeu"
                TargetStatusPill.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
                TargetStatusPill.TextColor3 = Color3.fromRGB(210, 210, 225)
                statusStroke.Color = Color3.fromRGB(50, 50, 68)
            end
        else
            TargetAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=100&h=100"
            TargetHeaderLbl.Text = "AUCUNE CIBLE"
            TargetHeaderLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
            TargetNameLbl.Text = "Sélectionnez un joueur"
            TargetStatusPill.Text = "Aucun"
        end
    end
    local function refreshAllActions()
        for _, ref in ipairs(actionRefreshers) do
            pcall(ref)
        end
    end
    local function updateSelectionHighlight()
        for p, rowData in pairs(playerRowsByPlayer) do
            if rowData.btn and rowData.btn.Parent then
                local isSel = (p == selectedPlayer)
                if isSel then
                    rowData.btn.BackgroundColor3 = Color3.fromRGB(44, 22, 72)
                    rowData.stroke.Color = Color3.fromRGB(150, 85, 255)
                    rowData.dispLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    rowData.userLbl.TextColor3 = Color3.fromRGB(195, 175, 240)
                else
                    rowData.btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
                    rowData.stroke.Color = Color3.fromRGB(32, 32, 46)
                    rowData.dispLbl.TextColor3 = Color3.fromRGB(240, 240, 250)
                    rowData.userLbl.TextColor3 = Color3.fromRGB(135, 135, 155)
                end
            end
        end
    end
    local function updatePlayerCount()
        local total = #Players:GetPlayers()
        PlayerCountBadge.Text = tostring(total) .. " joueur" .. (total > 1 and "s" or "")
    end
    local function createPlayerRow(p)
        if not p or playerRowsByPlayer[p] then return end
        local isMe = (p == LocalPlayer)
        local isSel = (p == selectedPlayer)
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, -12, 0, 40)
        row.BackgroundColor3 = isSel and Color3.fromRGB(44, 22, 72) or Color3.fromRGB(18, 18, 26)
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.ClipsDescendants = true
        row.LayoutOrder = isMe and 0 or 1
        row.ZIndex = 10
        row.Parent = PlayerListScroll
        makeCorner(row, 8)
        local rowStroke = makeStroke(row, isSel and Color3.fromRGB(150, 85, 255) or Color3.fromRGB(32, 32, 46), 1)
        local avatar = Instance.new("ImageLabel")
        avatar.Size = UDim2.new(0, 28, 0, 28)
        avatar.Position = UDim2.new(0, 6, 0.5, -14)
        avatar.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(p.UserId) .. "&w=100&h=100"
        avatar.BorderSizePixel = 0
        avatar.ZIndex = 11
        avatar.Parent = row
        makeCorner(avatar, 14)
        makeStroke(avatar, Color3.fromRGB(48, 48, 68), 1)
        local dispLabel = Instance.new("TextLabel")
        dispLabel.Size = UDim2.new(1, -96, 0, 16)
        dispLabel.Position = UDim2.new(0, 42, 0, 4)
        dispLabel.BackgroundTransparency = 1
        dispLabel.Text = p.DisplayName
        dispLabel.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(240, 240, 250)
        dispLabel.Font = Enum.Font.GothamBold
        dispLabel.TextSize = 11
        dispLabel.TextXAlignment = Enum.TextXAlignment.Left
        dispLabel.TextTruncate = Enum.TextTruncate.AtEnd
        dispLabel.ZIndex = 11
        dispLabel.Parent = row
        local userLabel = Instance.new("TextLabel")
        userLabel.Size = UDim2.new(1, -96, 0, 14)
        userLabel.Position = UDim2.new(0, 42, 0, 20)
        userLabel.BackgroundTransparency = 1
        userLabel.Text = "@" .. p.Name
        userLabel.TextColor3 = isSel and Color3.fromRGB(195, 175, 240) or Color3.fromRGB(140, 140, 160)
        userLabel.Font = Enum.Font.GothamMedium
        userLabel.TextSize = 10
        userLabel.TextXAlignment = Enum.TextXAlignment.Left
        userLabel.TextTruncate = Enum.TextTruncate.AtEnd
        userLabel.ZIndex = 11
        userLabel.Parent = row
        if isMe then
            local meBadge = Instance.new("TextLabel")
            meBadge.Size = UDim2.new(0, 36, 0, 18)
            meBadge.Position = UDim2.new(1, -44, 0.5, -9)
            meBadge.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            meBadge.Text = "MOI"
            meBadge.TextColor3 = Color3.fromRGB(240, 240, 250)
            meBadge.Font = Enum.Font.GothamBold
            meBadge.TextSize = 9
            meBadge.ZIndex = 11
            meBadge.Parent = row
            makeCorner(meBadge, 6)
            makeStroke(meBadge, Color3.fromRGB(58, 58, 76), 1)
        end
        local searchKey = string.lower(p.Name .. " " .. p.DisplayName .. " " .. tostring(p.UserId))
        row.MouseEnter:Connect(function()
            if selectedPlayer ~= p then
                row.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
                rowStroke.Color = Color3.fromRGB(48, 48, 68)
            end
        end)
        row.MouseLeave:Connect(function()
            if selectedPlayer ~= p then
                row.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
                rowStroke.Color = Color3.fromRGB(32, 32, 46)
            end
        end)
        row.MouseButton1Click:Connect(function()
            playClick()
            selectedPlayer = p
            updateTargetIndicator()
            updateSelectionHighlight()
            refreshAllActions()
        end)
        playerRowsByPlayer[p] = {btn = row, stroke = rowStroke, dispLbl = dispLabel, userLbl = userLabel, searchKey = searchKey}
    end
    local function removePlayerRow(p)
        local data = playerRowsByPlayer[p]
        if data then
            if data.btn and data.btn.Parent then data.btn:Destroy() end
            playerRowsByPlayer[p] = nil
        end
        if selectedPlayer == p then
            selectedPlayer = LocalPlayer
            updateTargetIndicator()
            updateSelectionHighlight()
            refreshAllActions()
        end
        updatePlayerCount()
    end
    local function applyFilter()
        local q = string.lower(FilterBox.Text or ""):match("^%s*(.-)%s*$")
        for _, data in pairs(playerRowsByPlayer) do
            if data.btn and data.btn.Parent then
                data.btn.Visible = (q == "" or string.find(data.searchKey, q, 1, true) ~= nil)
            end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        createPlayerRow(p)
    end
    updatePlayerCount()
    updateTargetIndicator()
    updateSelectionHighlight()
    FilterBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
    Players.PlayerAdded:Connect(function(p)
        createPlayerRow(p)
        applyFilter()
        updateSelectionHighlight()
        updatePlayerCount()
    end)
    Players.PlayerRemoving:Connect(removePlayerRow)
    _G.refreshMM2PlayerList = function()
        for _, p in ipairs(Players:GetPlayers()) do
            createPlayerRow(p)
        end
        applyFilter()
        updateSelectionHighlight()
        updatePlayerCount()
    end
    local function createActionButton(btnTitle, callback, checkActive)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
        btn.BorderSizePixel = 0
        btn.Text = btnTitle
        btn.TextColor3 = Color3.fromRGB(235, 235, 245)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.RichText = true
        btn.AutoButtonColor = false
        btn.ZIndex = 10
        btn.Parent = SettingsContainer
        makeCorner(btn, 8)
        local stroke = makeStroke(btn, Color3.fromRGB(34, 34, 48), 1)
        local function refreshState()
            local active = false
            if checkActive then
                pcall(function() active = checkActive(btn) end)
            end
            if active then
                btn.BackgroundColor3 = Color3.fromRGB(56, 18, 30)
                btn.TextColor3 = Color3.fromRGB(255, 95, 115)
                stroke.Color = Color3.fromRGB(215, 48, 64)
            else
                btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
                btn.TextColor3 = Color3.fromRGB(235, 235, 245)
                stroke.Color = Color3.fromRGB(34, 34, 48)
            end
        end
        table.insert(actionRefreshers, refreshState)
        btn.MouseEnter:Connect(function()
            local active = false
            if checkActive then pcall(function() active = checkActive(btn) end) end
            if not active then
                btn.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
                stroke.Color = Color3.fromRGB(52, 50, 72)
            end
        end)
        btn.MouseLeave:Connect(function()
            local active = false
            if checkActive then pcall(function() active = checkActive(btn) end) end
            if not active then
                btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
                stroke.Color = Color3.fromRGB(34, 34, 48)
            end
        end)
        btn.MouseButton1Click:Connect(function()
            playClick()
            if not selectedPlayer or not selectedPlayer.Parent then
                notify("Joueur", "Sélectionne un joueur à gauche !", Colors.Warning)
                return
            end
            callback(btn)
            refreshState()
        end)
        refreshState()
        return btn
    end
    createActionButton("Teleport", function()
        if selectedPlayer == LocalPlayer then
            notify("Teleport", "Tu es déjà sur toi-même !", Colors.Warning)
            return
        end
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local tRoot = selectedPlayer.Character and (selectedPlayer.Character:FindFirstChild("HumanoidRootPart") or selectedPlayer.Character.PrimaryPart)
        if myRoot and tRoot then
            myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2.5)
            notify("Teleport", "Téléporté sur " .. selectedPlayer.DisplayName, Colors.Success)
        else
            notify("Teleport", "Personnage cible introuvable", Colors.Error)
        end
    end)
    createActionButton('TP (<font color="rgb(175,110,255)">Bypass AC</font>)', function()
        if selectedPlayer == LocalPlayer then
            notify("Teleport", "Tu es déjà sur toi-même !", Colors.Warning)
            return
        end
        local myChar = LocalPlayer.Character
        local tChar = selectedPlayer and selectedPlayer.Character
        local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
        local tRoot = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar.PrimaryPart)
        if not myRoot or not tRoot then
            notify("Teleport", "HumanoidRootPart introuvable !", Colors.Error)
            return
        end
        task.spawn(function()
            local startPos = myRoot.Position
            local endPos = tRoot.Position + Vector3.new(0, 2, 2)
            local totalDist = (endPos - startPos).Magnitude
            local steps = math.max(1, math.ceil(totalDist / 15))
            notify("Teleport", "TP Bypass AC en cours... (" .. steps .. " micro-sauts)", Colors.Info)
            for i = 1, steps do
                local alpha = i / steps
                local interpPos = startPos:Lerp(endPos, alpha)
                pcall(function()
                    myRoot.CFrame = CFrame.new(interpPos) * (myRoot.CFrame - myRoot.CFrame.Position)
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                end)
                RunService.Heartbeat:Wait()
                RunService.Heartbeat:Wait()
            end
            notify("Teleport", "TP Bypass AC terminé vers " .. selectedPlayer.DisplayName, Colors.Success)
        end)
    end)
    local spectatingTarget = nil
    local function stopPlayerSpectate()
        spectatingTarget = nil
        if playerSpectateConn then playerSpectateConn:Disconnect(); playerSpectateConn = nil end
        pcall(function()
            local cam = workspace.CurrentCamera
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if cam and hum then
                cam.CameraType = Enum.CameraType.Custom
                cam.CameraSubject = hum
            end
        end)
    end
    createActionButton("Spectate", function()
        if selectedPlayer == LocalPlayer then
            stopPlayerSpectate()
            return
        end
        if spectatingTarget == selectedPlayer then
            stopPlayerSpectate()
            notify("Spectate", "Spectate désactivé", Colors.Warning)
        else
            stopPlayerSpectate()
            spectatingTarget = selectedPlayer
            playerSpectateConn = RunService.RenderStepped:Connect(function()
                if not spectatingTarget or not spectatingTarget.Parent then
                    stopPlayerSpectate()
                    refreshAllActions()
                    return
                end
                local tHum = spectatingTarget.Character and spectatingTarget.Character:FindFirstChildOfClass("Humanoid")
                local cam = workspace.CurrentCamera
                if tHum and cam and cam.CameraSubject ~= tHum then
                    cam.CameraSubject = tHum
                end
            end)
            notify("Spectate", "Observation de " .. selectedPlayer.DisplayName, Colors.Success)
        end
    end, function(btn)
        local active = (spectatingTarget ~= nil and spectatingTarget == selectedPlayer)
        btn.Text = active and "Stop Spectate" or "Spectate"
        return active
    end)
    local attachedTarget = nil
    local function stopPlayerAttach()
        attachedTarget = nil
        if playerAttachConn then playerAttachConn:Disconnect(); playerAttachConn = nil end
    end
    createActionButton("Attach", function()
        if selectedPlayer == LocalPlayer then
            notify("Attach", "Impossible de s'attacher à soi-même !", Colors.Warning)
            return
        end
        if attachedTarget == selectedPlayer then
            stopPlayerAttach()
            notify("Attach", "Détaché", Colors.Warning)
        else
            stopPlayerAttach()
            attachedTarget = selectedPlayer
            playerAttachConn = RunService.Heartbeat:Connect(function()
                if not attachedTarget or not attachedTarget.Parent then
                    stopPlayerAttach()
                    refreshAllActions()
                    return
                end
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local tRoot = attachedTarget.Character and attachedTarget.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and tRoot then
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                    myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2.2)
                end
            end)
            notify("Attach", "Attaché à " .. selectedPlayer.DisplayName, Colors.Success)
        end
    end, function(btn)
        local active = (attachedTarget ~= nil and attachedTarget == selectedPlayer)
        btn.Text = active and "Detach" or "Attach"
        return active
    end)
    local attachedBFTarget = nil
    local function stopPlayerAttachBF()
        attachedBFTarget = nil
        if playerAttachBFConn then playerAttachBFConn:Disconnect(); playerAttachBFConn = nil end
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end)
    end
    createActionButton('attach player (<font color="rgb(175,110,255)">bloxfruit</font>)', function()
        if selectedPlayer == LocalPlayer then
            notify("Attach", "Impossible de s'attacher à soi-même !", Colors.Warning)
            return
        end
        if attachedBFTarget == selectedPlayer then
            stopPlayerAttachBF()
            notify("Attach", "Attach (BloxFruit) arrêté", Colors.Warning)
        else
            stopPlayerAttachBF()
            attachedBFTarget = selectedPlayer
            playerAttachBFConn = RunService.Heartbeat:Connect(function()
                if not attachedBFTarget or not attachedBFTarget.Parent then
                    stopPlayerAttachBF()
                    refreshAllActions()
                    return
                end
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                local tRoot = attachedBFTarget.Character and attachedBFTarget.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and tRoot then
                    if myHum then myHum.PlatformStand = true end
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                    myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 4.5, 1.5)
                end
            end)
            notify("Attach", "Attach (BloxFruit) sur " .. selectedPlayer.DisplayName, Colors.Success)
        end
    end, function(btn)
        local active = (attachedBFTarget ~= nil and attachedBFTarget == selectedPlayer)
        btn.Text = active and 'Stop attach (<font color="rgb(175,110,255)">bloxfruit</font>)' or 'attach player (<font color="rgb(175,110,255)">bloxfruit</font>)'
        return active
    end)
    createActionButton("WarpCar", function()
        if selectedPlayer == LocalPlayer then
            notify("WarpCar", "Choisis un autre joueur !", Colors.Warning)
            return
        end
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local tChar = selectedPlayer.Character
        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if not myHum or not myRoot or not tRoot then
            notify("WarpCar", "Impossible de localiser la cible", Colors.Error)
            return
        end
        local targetSeat = tHum and tHum.SeatPart
        if targetSeat then
            local veh = targetSeat:FindFirstAncestorOfClass("Model") or targetSeat.Parent
            if veh then
                for _, s in ipairs(veh:GetDescendants()) do
                    if (s:IsA("Seat") or s:IsA("VehicleSeat")) and not s.Occupant then
                        s:Sit(myHum)
                        notify("WarpCar", "Installé dans le véhicule de " .. selectedPlayer.DisplayName, Colors.Success)
                        return
                    end
                end
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if (obj:IsA("Seat") or obj:IsA("VehicleSeat")) and not obj.Occupant and (obj.Position - tRoot.Position).Magnitude < 35 then
                obj:Sit(myHum)
                notify("WarpCar", "Siège trouvé près de " .. selectedPlayer.DisplayName, Colors.Success)
                return
            end
        end
        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 2.5, 0)
        notify("WarpCar", "Téléporté sur la position de " .. selectedPlayer.DisplayName, Colors.Info)
    end)
    local currentFlingTarget = nil
    createActionButton("Fling", function()
        if selectedPlayer == LocalPlayer then
            notify("Fling", "Impossible de fling ton propre personnage !", Colors.Warning)
            return
        end
        if FlingState.Conn and currentFlingTarget == selectedPlayer then
            stopFling()
            currentFlingTarget = nil
            notify("Fling", "Fling arrêté", Colors.Warning)
        else
            stopFling()
            currentFlingTarget = selectedPlayer
            flingPlayer(selectedPlayer)
            notify("Fling", "Fling lancé sur " .. selectedPlayer.DisplayName, Colors.Success)
        end
    end, function(btn)
        local active = (FlingState.Conn ~= nil and currentFlingTarget == selectedPlayer)
        btn.Text = active and "Stop Fling" or "Fling"
        return active
    end)
end
watermarkState = true
watermarkGui = nil
watermarkConn = nil
local WmText = nil
local WmFrame = nil
local function setupWatermark()
    if watermarkGui then pcall(function() watermarkGui:Destroy() end) end
    if watermarkConn then pcall(function() watermarkConn:Disconnect() end) end
    watermarkGui = Instance.new("ScreenGui")
    watermarkGui.Name = "PearlWatermark"
    watermarkGui.ResetOnSpawn = false
    watermarkGui.IgnoreGuiInset = true
    watermarkGui.DisplayOrder = 999
    watermarkGui.Parent = parent
    WmFrame = Instance.new("Frame")
    WmFrame.Name = "WmFrame"
    WmFrame.Size = UDim2.new(0, 0, 0, 28)
    WmFrame.Position = UDim2.new(0, 20, 0, 20)
    WmFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    WmFrame.BorderSizePixel = 0
    WmFrame.AutomaticSize = Enum.AutomaticSize.X
    WmFrame.Active = true
    WmFrame.ZIndex = 100
    WmFrame.Visible = watermarkState
    WmFrame.Parent = watermarkGui
    makeCorner(WmFrame, 7)
    makeStroke(WmFrame, Color3.fromRGB(34, 34, 40), 1)
    local wmBar = Instance.new("Frame")
    wmBar.Name = "AccentBar"
    wmBar.Size = UDim2.new(0, 3, 0, 18)
    wmBar.Position = UDim2.new(0, 5, 0.5, -9)
    wmBar.BackgroundColor3 = Colors.Accent
    wmBar.BorderSizePixel = 0
    wmBar.ZIndex = 101
    wmBar.Parent = WmFrame
    makeCorner(wmBar, 2)
    WmText = Instance.new("TextLabel")
    WmText.Name = "WatermarkText"
    WmText.Size = UDim2.new(0, 0, 1, 0)
    WmText.Position = UDim2.new(0, 14, 0, 0)
    WmText.BackgroundTransparency = 1
    WmText.AutomaticSize = Enum.AutomaticSize.X
    WmText.Text = "Pearl Hub | Timebomb Duels | " .. (LocalPlayer and LocalPlayer.Name or "Player") .. " | 60 FPS"
    WmText.TextColor3 = Color3.fromRGB(242, 242, 246)
    WmText.TextSize = 11
    WmText.Font = Enum.Font.GothamMedium
    WmText.TextXAlignment = Enum.TextXAlignment.Left
    WmText.ZIndex = 101
    WmText.Parent = WmFrame
    local WmPad = Instance.new("UIPadding")
    WmPad.PaddingLeft = UDim.new(0, 4)
    WmPad.PaddingRight = UDim.new(0, 12)
    WmPad.Parent = WmFrame
    local wmDragging = false
    local wmDragStart, wmStartPos
    WmFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wmDragging = true
            wmDragStart = input.Position
            wmStartPos = WmFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    wmDragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if wmDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - wmDragStart
            WmFrame.Position = UDim2.new(
                wmStartPos.X.Scale,
                wmStartPos.X.Offset + delta.X,
                wmStartPos.Y.Scale,
                wmStartPos.Y.Offset + delta.Y
            )
        end
    end)
    local fpsFrames = 0
    local lastFpsTime = tick()
    watermarkConn = RunService.RenderStepped:Connect(function()
        fpsFrames = fpsFrames + 1
        local now = tick()
        if now - lastFpsTime >= 0.3 then
            local curFps = math.floor(fpsFrames / (now - lastFpsTime))
            local count = #Players:GetPlayers()
            WmText.Text = "Pearl Hub | Timebomb Duels | " .. (LocalPlayer and LocalPlayer.Name or "Player") .. " | " .. tostring(count) .. " Joueurs | " .. tostring(curFps) .. " FPS"
            fpsFrames = 0
            lastFpsTime = now
        end
    end)
end
setupWatermark()
settingsPanel = panels["SETTINGS"]
createSectionHeader(settingsPanel, "Paramètres Pearl Hub", 1)
_, wmToggleBtn = createToggleCard(settingsPanel, "Afficher Watermark", "Affiche le watermark draggable avec FPS et joueurs en direct", 2,
    function() return watermarkState end,
    function(v)
        watermarkState = v
        if WmFrame then
            WmFrame.Visible = v
        end
        notify("Watermark", v and "Watermark ON" or "Watermark OFF", v and Colors.Success or Colors.Warning)
    end)
_, dimmerToggleBtn = createToggleCard(settingsPanel, "Background Dimmer", "Assombrit l'arrière-plan quand le menu est ouvert", 3,
    function() return DimmerEnabled end,
    function(v)
        DimmerEnabled = v
        if not v then
            BackgroundDimmer.Visible = false
            BackgroundDimmer.BackgroundTransparency = 1
        elseif MainFrame.Visible then
            BackgroundDimmer.Visible = true
            BackgroundDimmer.BackgroundTransparency = 0.45
        end
    end)
_, bubblesToggleBtn = createToggleCard(settingsPanel, "Particules Bulles", "Affiche les bulles animées dans l'interface", 4,
    function() return BubblesEnabled end,
    function(v)
        BubblesEnabled = v
        BubblesContainer.Visible = v
    end)
local unloadCard = createCard(settingsPanel, 5, 54)
local unloadTitle = Instance.new("TextLabel")
unloadTitle.Size = UDim2.new(1, -96, 0, 18)
unloadTitle.Position = UDim2.new(0, 14, 0, 8)
unloadTitle.BackgroundTransparency = 1
unloadTitle.Text = "Unload Pearl Hub"
unloadTitle.TextColor3 = Colors.Text
unloadTitle.Font = Enum.Font.GothamMedium
unloadTitle.TextSize = 12
unloadTitle.TextXAlignment = Enum.TextXAlignment.Left
unloadTitle.ZIndex = 9
unloadTitle.Parent = unloadCard
local unloadSub = Instance.new("TextLabel")
unloadSub.Size = UDim2.new(1, -96, 0, 14)
unloadSub.Position = UDim2.new(0, 14, 0, 27)
unloadSub.BackgroundTransparency = 1
unloadSub.Text = "Ferme proprement Pearl Hub et coupe toutes les connexions"
unloadSub.TextColor3 = Colors.TextDim
unloadSub.Font = Enum.Font.Gotham
unloadSub.TextSize = 10
unloadSub.TextXAlignment = Enum.TextXAlignment.Left
unloadSub.ZIndex = 9
unloadSub.Parent = unloadCard
local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(0, 74, 0, 26)
unloadBtn.Position = UDim2.new(1, -86, 0.5, -13)
unloadBtn.BackgroundColor3 = Color3.fromRGB(42, 18, 22)
unloadBtn.BorderSizePixel = 0
unloadBtn.Text = "Unload"
unloadBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.TextSize = 10
unloadBtn.AutoButtonColor = false
unloadBtn.ZIndex = 10
unloadBtn.Parent = unloadCard
makeCorner(unloadBtn, 7)
makeStroke(unloadBtn, Color3.fromRGB(150, 35, 45), 1)
unloadBtn.MouseEnter:Connect(function()
    CreateTween(unloadBtn, {BackgroundColor3 = Color3.fromRGB(215, 45, 55), TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.15)
end)
unloadBtn.MouseLeave:Connect(function()
    CreateTween(unloadBtn, {BackgroundColor3 = Color3.fromRGB(42, 18, 22), TextColor3 = Color3.fromRGB(255, 75, 75)}, 0.15)
end)
unloadBtn.MouseButton1Click:Connect(function()
    playClick()
    CreateTween(PanelScale, {Scale = 0.78}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    CreateTween(BackgroundDimmer, {BackgroundTransparency = 1}, 0.2)
    task.delay(0.2, function()
        unloadMenu()
    end)
end)
MainFrame.Visible = false
BackgroundDimmer.BackgroundTransparency = 1
task.delay(0.15, function()
    MainFrame.Visible = true
    PanelScale.Scale = 0.72
    MainFrame.Position = UDim2.new(savedMenuPos.X.Scale, savedMenuPos.X.Offset, savedMenuPos.Y.Scale, savedMenuPos.Y.Offset + 45)
    BubblesContainer.Visible = (BubblesEnabled == true)
    if DimmerEnabled then
        BackgroundDimmer.Visible = true
        CreateTween(BackgroundDimmer, {BackgroundTransparency = 0.45}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    else
        BackgroundDimmer.Visible = false
        BackgroundDimmer.BackgroundTransparency = 1
    end
    CreateTween(PanelScale, {Scale = 1}, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    CreateTween(MainFrame, {Position = savedMenuPos}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    switchCategory("3XPLOIT")
    notify("Pearl Hub", "Timebomb Duels chargé avec succès (Insert / M)", Colors.Accent)
end)
