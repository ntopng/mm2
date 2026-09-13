Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
HttpService = game:GetService("HttpService")
TeleportService = game:GetService("TeleportService")
ProximityPromptService = game:GetService("ProximityPromptService")
UserService = game:GetService("UserService")
LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local isKeyVerified = false

_OrigLighting = {
    GlobalShadows = Lighting.GlobalShadows,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    ClockTime = Lighting.ClockTime,
    ExposureCompensation = Lighting.ExposureCompensation
}
_OrigWalkSpeed = nil
_OrigJumpPower = nil
_OrigJumpHeight = nil
_OrigUseJumpPower = nil

pcall(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        _OrigWalkSpeed = hum.WalkSpeed
        _OrigJumpPower = hum.JumpPower
        _OrigJumpHeight = hum.JumpHeight
        _OrigUseJumpPower = hum.UseJumpPower
    end
end)
Camera = workspace.CurrentCamera
Lighting = game:GetService("Lighting")


_G.Aimlock_Enabled = false
_G.Aimlock_Key = Enum.KeyCode.E
_G.Aimlock_KeyName = "E"
_G.Aimlock_HoldMode = false
_G.Aimlock_IsHeld = false
_G.Aimlock_FOV = 150
_G.Aimlock_TargetPart = "Head"
_G.Aimlock_Wallcheck = true
_G.Aimlock_ShowFOV = true
_G.Aimlock_Smoothness = 1
_G.Aimlock_Prediction = true
_G.Aimlock_PredictionBoost = 1.0
_G.Aimlock_PingCompensation = true
_G.Aimlock_StickyTarget = nil
_G.Aimlock_TargetNPCs = false

Aimlock_Enabled = false
Aimlock_Key = Enum.KeyCode.E
Aimlock_KeyName = "E"
Aimlock_HoldMode = false
Aimlock_IsHeld = false
Aimlock_FOV = 150
Aimlock_TargetPart = "Head"
Aimlock_Wallcheck = true
Aimlock_ShowFOV = true
Aimlock_Smoothness = 1
Aimlock_Prediction = true
Aimlock_PredictionBoost = 1.0
Aimlock_PingCompensation = true
Aimlock_TargetNPCs = false
currentLockedTarget = nil
currentLockedChar = nil
currentLockedPart = nil

SilentAimCircle = nil
if Drawing and Drawing.new then
    pcall(function()
        SilentAimCircle = Drawing.new("Circle")
        SilentAimCircle.Visible = false
        SilentAimCircle.Thickness = 1.5
        SilentAimCircle.Color = Color3.fromRGB(60, 160, 255)
        SilentAimCircle.Radius = SilentAim_FOV
        SilentAimCircle.Filled = false
        SilentAimCircle.Transparency = 1
        SilentAimCircle.NumSides = 64
    end)
end

local cachedAimNPCs = {}
local lastAimNPCScan = 0
local function getAimNPCList()
    local now = tick()
    if now - lastAimNPCScan < 0.4 then
        return cachedAimNPCs
    end
    lastAimNPCScan = now
    local list = {}
    local function scan(inst, depth)
        if not inst or depth > 3 then return end
        for _, obj in ipairs(inst:GetChildren()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("Head")
                if hum and hum.Health > 0 and root then
                    table.insert(list, obj)
                else
                    scan(obj, depth + 1)
                end
            elseif obj:IsA("Folder") then
                scan(obj, depth + 1)
            end
        end
    end
    scan(workspace, 1)
    cachedAimNPCs = list
    return list
end

function isPlayerVisibleAim(targetChar, tPart)
    if not LocalPlayer.Character or not targetChar or not tPart then return true end
    local cam = workspace.CurrentCamera
    local origin = cam and cam.CFrame.Position
    if not origin then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, targetChar, cam}
    params.IgnoreWater = true
    local res = workspace:Raycast(origin, (tPart.Position - origin), params)
    return res == nil
end

_G.Aimlock_TeamCheck = true
Aimlock_TeamCheck = true

function isTargetStillValid(target, expectedChar)
    if not target or not target.Parent or target == LocalPlayer then return false end
    if typeof(target) == "Instance" and target:IsA("Player") then
        local teamCheckEnabled = (_G.Aimlock_TeamCheck ~= nil and _G.Aimlock_TeamCheck) or (Aimlock_TeamCheck ~= nil and Aimlock_TeamCheck) or (V and V.ESPTeamCheck)
        if teamCheckEnabled then
            if target.Team and LocalPlayer.Team and target.Team == LocalPlayer.Team then return false end
            if target.TeamColor and LocalPlayer.TeamColor and target.TeamColor == LocalPlayer.TeamColor then return false end
        end
        if IsWhitelisted and IsWhitelisted(target) then return false end
    end
    local char = (typeof(target) == "Instance" and target:IsA("Model") and target) or (target.Character)
    if not char or not char.Parent or not char:IsDescendantOf(workspace) then return false end
    if expectedChar and char ~= expectedChar then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.Parent or hum.Health <= 0 then return false end
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.Physics then return false end
    local targetPartName = _G.Aimlock_TargetPart or Aimlock_TargetPart or "Head"
    local part = char:FindFirstChild(targetPartName) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not part or not part.Parent or not part:IsDescendantOf(workspace) then return false end
    return true, part
end

function getAimlockTarget()
    local mouseLoc = UserInputService:GetMouseLocation()
    local bestTarget, bestPart = nil, nil
    local fovRad = _G.Aimlock_FOV or Aimlock_FOV or 150
    local shortestDist = fovRad
    local targetPartName = _G.Aimlock_TargetPart or Aimlock_TargetPart or "Head"
    local wallcheck = (_G.Aimlock_Wallcheck ~= nil and _G.Aimlock_Wallcheck) or Aimlock_Wallcheck
    local cam = workspace.CurrentCamera
    if not cam then return nil, nil end
    local teamCheckEnabled = (_G.Aimlock_TeamCheck ~= nil and _G.Aimlock_TeamCheck) or (Aimlock_TeamCheck ~= nil and Aimlock_TeamCheck) or (V and V.ESPTeamCheck)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:IsDescendantOf(workspace) then
            local isTeam = false
            if teamCheckEnabled then
                if p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                    isTeam = true
                elseif p.TeamColor and LocalPlayer.TeamColor and p.TeamColor == LocalPlayer.TeamColor then
                    isTeam = true
                end
            elseif p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                isTeam = true
            end
            if not isTeam and not (IsWhitelisted and IsWhitelisted(p)) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Parent and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                    local part = p.Character:FindFirstChild(targetPartName) or p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("UpperTorso")
                    if part and part:IsDescendantOf(workspace) then
                        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen and screenPos.Z > 0 then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
                            if dist < shortestDist then
                                if not wallcheck or isPlayerVisibleAim(p.Character, part) then
                                    shortestDist = dist
                                    bestTarget = p
                                    bestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if _G.Aimlock_TargetNPCs or Aimlock_TargetNPCs then
        local npcs = getAimNPCList()
        for _, npc in ipairs(npcs) do
            if npc and npc.Parent and npc:IsDescendantOf(workspace) and npc ~= LocalPlayer.Character then
                local hum = npc:FindFirstChildOfClass("Humanoid")
                if hum and hum.Parent and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                    local part = npc:FindFirstChild(targetPartName) or npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso") or npc:FindFirstChild("UpperTorso")
                    if part and part:IsDescendantOf(workspace) then
                        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen and screenPos.Z > 0 then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
                            if dist < shortestDist then
                                if not wallcheck or isPlayerVisibleAim(npc, part) then
                                    shortestDist = dist
                                    bestTarget = npc
                                    bestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestTarget, bestPart
end

if _G.NebulaAimlockConn then pcall(function() _G.NebulaAimlockConn:Disconnect() end); _G.NebulaAimlockConn = nil end
if _G.NebulaAimlockInputBeganConn then pcall(function() _G.NebulaAimlockInputBeganConn:Disconnect() end); _G.NebulaAimlockInputBeganConn = nil end
if _G.NebulaAimlockInputEndedConn then pcall(function() _G.NebulaAimlockInputEndedConn:Disconnect() end); _G.NebulaAimlockInputEndedConn = nil end

_G.NebulaAimlockConn = RunService.RenderStepped:Connect(function()
    local isEnabled = (_G.Aimlock_Enabled or Aimlock_Enabled)
    local isShowFOV = (_G.Aimlock_ShowFOV ~= nil and _G.Aimlock_ShowFOV) or Aimlock_ShowFOV
    local fovRad = _G.Aimlock_FOV or Aimlock_FOV or 150

    if SilentAimCircle then
        SilentAimCircle.Visible = isEnabled and isShowFOV
        SilentAimCircle.Position = UserInputService:GetMouseLocation()
        SilentAimCircle.Radius = fovRad
    end

    local activeLock = false
    if _G.Aimlock_HoldMode or Aimlock_HoldMode then
        activeLock = isEnabled and (_G.Aimlock_IsHeld or Aimlock_IsHeld)
    else
        activeLock = isEnabled
    end

    if activeLock then
        local valid, validPart = isTargetStillValid(currentLockedTarget, currentLockedChar)
        if not valid then
            currentLockedTarget = nil
            currentLockedChar = nil
            currentLockedPart = nil
            local newTarget, newPart = getAimlockTarget()
            if newTarget and newPart then
                currentLockedTarget = newTarget
                currentLockedChar = (typeof(newTarget) == "Instance" and newTarget:IsA("Model") and newTarget) or newTarget.Character
                currentLockedPart = newPart
            end
        else
            currentLockedPart = validPart
        end

        if currentLockedTarget and currentLockedPart and workspace.CurrentCamera then
            local cam = workspace.CurrentCamera
            local targetPos = currentLockedPart.Position
            
            if _G.Aimlock_Prediction or Aimlock_Prediction then
                local targetChar = (typeof(currentLockedTarget) == "Instance" and currentLockedTarget:IsA("Model") and currentLockedTarget) or (currentLockedTarget and currentLockedTarget.Character)
                local rootPart = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("Head"))
                if rootPart then
                    local rawVel = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.zero
                    if rawVel.Magnitude < 250 then
                        local shotDist = (cam.CFrame.Position - targetPos).Magnitude
                        local bulletSpeed = 1000
                        local travelTime = math.min((shotDist / bulletSpeed), 0.18)
                        local boost = (_G.Aimlock_PredictionBoost or Aimlock_PredictionBoost or 1.0)
                        local velY = math.clamp(rawVel.Y, -30, 30)
                        local velX = math.clamp(rawVel.X, -100, 100)
                        local velZ = math.clamp(rawVel.Z, -100, 100)
                        local lead = Vector3.new(velX, velY * 0.1, velZ) * travelTime * boost
                        targetPos = targetPos + lead
                    end
                end
            end

            local smooth = _G.Aimlock_Smoothness or Aimlock_Smoothness or 1
            local camPos = cam.CFrame.Position
            local diff = targetPos - camPos
            if diff.Magnitude > 0.5 then
                local targetCF = CFrame.lookAt(camPos, targetPos)
                local rx, ry, rz = targetCF:ToOrientation()
                if math.abs(rx) < math.rad(82) then
                    if smooth <= 1 then
                        cam.CFrame = targetCF
                    else
                        cam.CFrame = cam.CFrame:Lerp(targetCF, math.clamp(1 / smooth, 0.08, 1))
                    end
                end
            end
        end
    else
        currentLockedTarget = nil
        currentLockedChar = nil
        currentLockedPart = nil
    end
end)

_G.NebulaAimlockInputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local lockKey = _G.Aimlock_Key or Aimlock_Key
    local isTargetKey = false

    if typeof(lockKey) == "EnumItem" then
        if input.KeyCode == lockKey or input.UserInputType == lockKey then
            isTargetKey = true
        end
    end

    if isTargetKey then
        if _G.Aimlock_HoldMode or Aimlock_HoldMode then
            _G.Aimlock_IsHeld = true
            Aimlock_IsHeld = true
        else
            _G.Aimlock_Enabled = not (_G.Aimlock_Enabled or Aimlock_Enabled)
            Aimlock_Enabled = _G.Aimlock_Enabled
            if not Aimlock_Enabled then
                currentLockedTarget = nil
                currentLockedChar = nil
                currentLockedPart = nil
            end
            notify("Aimlock", "Aimlock " .. (Aimlock_Enabled and "ACTIVÉ" or "DÉSACTIVÉ"), Aimlock_Enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
        end
    end
end)

_G.NebulaAimlockInputEndedConn = UserInputService.InputEnded:Connect(function(input, gpe)
    local lockKey = _G.Aimlock_Key or Aimlock_Key
    local isTargetKey = false
    if typeof(lockKey) == "EnumItem" then
        if input.KeyCode == lockKey or input.UserInputType == lockKey then
            isTargetKey = true
        end
    end
    if isTargetKey and (_G.Aimlock_HoldMode or Aimlock_HoldMode) then
        _G.Aimlock_IsHeld = false
        Aimlock_IsHeld = false
        currentLockedTarget = nil
        currentLockedChar = nil
        currentLockedPart = nil
    end
end)

function serverHop()
    task.spawn(function()
        pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
            local res = game:HttpGet(url)
            local data = HttpService:JSONDecode(res)
            for _, srv in ipairs(data.data) do
                if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                    return
                end
            end
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end)
end

function rejoinServer()
    if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

Nebula = {
    Version ="1.0",
    Open = true,
    TeleportPoints = {}
}

flick_script = [[
Players = game:GetService("Players")
RunService = game:GetService("RunService")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")

LocalPlayer = Players.LocalPlayer
local ESP_Enabled = false
local ESPDistance_Enabled = false
local Skeleton_Enabled = false
local Tracer_Enabled = false
local HealthBar_Enabled = false
local HealthPV_Enabled = false
Aimlock_Enabled = false
local ESP_Objects = {}
local ESP_Connections = {}
local FOV_RADIUS = 150
local PredictionBoost = 1.2
local PredictionTravelTime = 0.08
local PredictionDistanceFactor = 1 / 1800
local fovCircle = nil
local fovCrosshair = nil
local draggingSlider = false
local camera = workspace.CurrentCamera
local aimlockConnection = nil
local AimlockKey = Enum.UserInputType.MouseButton1
local waitingForKey = false
local isMouseButton = true
local guiVisible = true
local fovCircleVisible = false
local currentTarget = nil

local Whitelist = {}
local WhitelistDropdownOpen = false
local WhitelistDropdown = nil

dragging = false
local dragStartPos = nil
local frameStartPos = nil

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name ="EternalFlick_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = game:GetService("CoreGui")

BackgroundDimmer = Instance.new("Frame")
BackgroundDimmer.Name = "BackgroundDimmer"
BackgroundDimmer.Size = UDim2.new(1, 0, 1, 0)
BackgroundDimmer.Position = UDim2.new(0, 0, 0, 0)
BackgroundDimmer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BackgroundDimmer.BackgroundTransparency = 0.2
BackgroundDimmer.BorderSizePixel = 0
BackgroundDimmer.ZIndex = 1
BackgroundDimmer.Active = false
BackgroundDimmer.Parent = ScreenGui

BubblesContainer = Instance.new("Frame")
BubblesContainer.Name = "BubblesContainer"
BubblesContainer.Size = UDim2.new(1, 0, 1, 0)
BubblesContainer.Position = UDim2.new(0, 0, 0, 0)
BubblesContainer.BackgroundTransparency = 1
BubblesContainer.ClipsDescendants = true
BubblesContainer.ZIndex = 2
BubblesContainer.Active = false
BubblesContainer.Parent = ScreenGui

bubbles = {}
numBubbles = 26
for i = 1, numBubbles do
    local b = Instance.new("Frame")
    local size = math.random(8, 26)
    b.Size = UDim2.new(0, size, 0, size)
    b.BackgroundColor3 = (math.random() > 0.45) and Color3.fromRGB(60, 160, 255) or Color3.fromRGB(120, 200, 255)
    b.BackgroundTransparency = math.random(60, 85) / 100
    b.BorderSizePixel = 0
    b.ZIndex = 2
    b.Parent = BubblesContainer
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = b
    local bs = Instance.new("UIStroke")
    bs.Color = Color3.fromRGB(255, 255, 255)
    bs.Transparency = math.random(75, 92) / 100
    bs.Thickness = 1
    bs.Parent = b
    local bubbleData = {
        frame = b,
        x = math.random(),
        y = math.random(),
        speed = math.random(35, 95) / 1000,
        swaySpeed = math.random(12, 28) / 10,
        swayAmp = math.random(6, 20) / 1000,
        offset = math.random() * math.pi * 2
    }
    b.Position = UDim2.new(bubbleData.x, 0, bubbleData.y, 0)
    table.insert(bubbles, bubbleData)
end

RunService.RenderStepped:Connect(function(dt)
    if not guiVisible then return end
    local t = tick()
    for _, b in ipairs(bubbles) do
        b.y = b.y + b.speed * dt
        if b.y > 1.05 then
            b.y = -0.05
            b.x = math.random()
        end
        local curX = b.x + math.sin(t * b.swaySpeed + b.offset) * b.swayAmp
        b.frame.Position = UDim2.new(curX, 0, b.y, 0)
    end
end)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 420)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui

local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0, 12)
MainFrameCorner.Parent = MainFrame

local MainFrameStroke = Instance.new("UIStroke")
MainFrameStroke.Color = Color3.fromRGB(40, 40, 58)
MainFrameStroke.Thickness = 1.5
MainFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainFrameStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundTransparency = 1
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(1, 0, 0, 2)
AccentBar.Position = UDim2.new(0, 0, 0, 0)
AccentBar.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
AccentBar.BorderSizePixel = 0
AccentBar.Parent = TitleBar

Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 110, 1, -2)
Sidebar.Position = UDim2.new(0, 0, 0, 2)
Sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarStroke = Instance.new("UIStroke")
SidebarStroke.Color = Color3.fromRGB(30, 30, 40)
SidebarStroke.Thickness = 1
SidebarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SidebarStroke.Parent = Sidebar

local SidebarHeader = Instance.new("Frame")
SidebarHeader.Size = UDim2.new(1, 0, 0, 56)
SidebarHeader.Position = UDim2.new(0, 0, 0, 0)
SidebarHeader.BackgroundTransparency = 1
SidebarHeader.BorderSizePixel = 0
SidebarHeader.Parent = Sidebar

local SidebarHeaderSep = Instance.new("Frame")
SidebarHeaderSep.Size = UDim2.new(1, 0, 0, 1)
SidebarHeaderSep.Position = UDim2.new(0, 0, 1, -1)
SidebarHeaderSep.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
SidebarHeaderSep.BorderSizePixel = 0
SidebarHeaderSep.Parent = SidebarHeader

local TitleLine1 = Instance.new("TextLabel")
TitleLine1.Size = UDim2.new(1, -10, 0, 18)
TitleLine1.Position = UDim2.new(0, 10, 0, 10)
TitleLine1.BackgroundTransparency = 1
TitleLine1.Text ="ETERNAL"
TitleLine1.TextColor3 = Color3.fromRGB(60, 160, 255)
TitleLine1.Font = Enum.Font.Code
TitleLine1.TextSize = 13
TitleLine1.TextXAlignment = Enum.TextXAlignment.Left
TitleLine1.Parent = SidebarHeader

local TitleLine2 = Instance.new("TextLabel")
TitleLine2.Size = UDim2.new(1, -10, 0, 16)
TitleLine2.Position = UDim2.new(0, 10, 0, 28)
TitleLine2.BackgroundTransparency = 1
TitleLine2.Text ="FLICK"
TitleLine2.TextColor3 = Color3.fromRGB(60, 160, 255)
TitleLine2.Font = Enum.Font.Code
TitleLine2.TextSize = 13
TitleLine2.TextXAlignment = Enum.TextXAlignment.Left
TitleLine2.Parent = SidebarHeader

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(1, -10, 0, 12)
VersionLabel.Position = UDim2.new(0, 10, 0, 42)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text ="v2.0"
VersionLabel.TextColor3 = Color3.fromRGB(50, 50, 65)
VersionLabel.Font = Enum.Font.Code
VersionLabel.TextSize = 11
VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
VersionLabel.Parent = SidebarHeader

local NavMenu = Instance.new("Frame")
NavMenu.Size = UDim2.new(1, -12, 0, 128)
NavMenu.Position = UDim2.new(0, 6, 0, 60)
NavMenu.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
NavMenu.BorderSizePixel = 0
NavMenu.Parent = Sidebar

local NavMenuCorner = Instance.new("UICorner")
NavMenuCorner.CornerRadius = UDim.new(0, 8)
NavMenuCorner.Parent = NavMenu

local NavMenuStroke = Instance.new("UIStroke")
NavMenuStroke.Color = Color3.fromRGB(38, 38, 54)
NavMenuStroke.Thickness = 1
NavMenuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
NavMenuStroke.Parent = NavMenu

local NavMenuPad = Instance.new("UIPadding")
NavMenuPad.PaddingTop = UDim.new(0, 4)
NavMenuPad.PaddingBottom = UDim.new(0, 4)
NavMenuPad.PaddingLeft = UDim.new(0, 4)
NavMenuPad.PaddingRight = UDim.new(0, 4)
NavMenuPad.Parent = NavMenu

local NavMenuLayout = Instance.new("UIListLayout")
NavMenuLayout.Padding = UDim.new(0, 3)
NavMenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavMenuLayout.Parent = NavMenu

local AimNavBtn = Instance.new("TextButton")
AimNavBtn.Size = UDim2.new(1, 0, 0, 34)
AimNavBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
AimNavBtn.BackgroundTransparency = 0.88
AimNavBtn.BorderSizePixel = 0
AimNavBtn.Text ="AIM"
AimNavBtn.TextColor3 = Color3.fromRGB(60, 160, 255)
AimNavBtn.Font = Enum.Font.Code
AimNavBtn.TextSize = 12
AimNavBtn.TextXAlignment = Enum.TextXAlignment.Left
AimNavBtn.LayoutOrder = 1
AimNavBtn.Parent = NavMenu
local AimNavCorner = Instance.new("UICorner")
AimNavCorner.CornerRadius = UDim.new(0, 6)
AimNavCorner.Parent = AimNavBtn

local AimNavAccent = Instance.new("Frame")
AimNavAccent.Size = UDim2.new(0, 2, 1, 0)
AimNavAccent.Position = UDim2.new(0, 0, 0, 0)
AimNavAccent.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
AimNavAccent.BorderSizePixel = 0
AimNavAccent.Parent = AimNavBtn

local AimNavPad = Instance.new("UIPadding")
AimNavPad.PaddingLeft = UDim.new(0, 14)
AimNavPad.Parent = AimNavBtn

local VisualNavBtn = Instance.new("TextButton")
VisualNavBtn.Size = UDim2.new(1, 0, 0, 34)
VisualNavBtn.BackgroundTransparency = 1
VisualNavBtn.BorderSizePixel = 0
VisualNavBtn.Text ="VISUAL"
VisualNavBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
VisualNavBtn.Font = Enum.Font.Code
VisualNavBtn.TextSize = 12
VisualNavBtn.TextXAlignment = Enum.TextXAlignment.Left
VisualNavBtn.LayoutOrder = 2
VisualNavBtn.Parent = NavMenu
local VisualNavCorner = Instance.new("UICorner")
VisualNavCorner.CornerRadius = UDim.new(0, 6)
VisualNavCorner.Parent = VisualNavBtn

local VisualNavAccent = Instance.new("Frame")
VisualNavAccent.Size = UDim2.new(0, 2, 1, 0)
VisualNavAccent.Position = UDim2.new(0, 0, 0, 0)
VisualNavAccent.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
VisualNavAccent.BorderSizePixel = 0
VisualNavAccent.Visible = false
VisualNavAccent.Parent = VisualNavBtn

local VisualNavPad = Instance.new("UIPadding")
VisualNavPad.PaddingLeft = UDim.new(0, 14)
VisualNavPad.Parent = VisualNavBtn

local WhitelistNavBtn = Instance.new("TextButton")
WhitelistNavBtn.Size = UDim2.new(1, 0, 0, 34)
WhitelistNavBtn.BackgroundTransparency = 1
WhitelistNavBtn.BorderSizePixel = 0
WhitelistNavBtn.Text ="WHITELIST"
WhitelistNavBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
WhitelistNavBtn.Font = Enum.Font.Code
WhitelistNavBtn.TextSize = 12
WhitelistNavBtn.TextXAlignment = Enum.TextXAlignment.Left
WhitelistNavBtn.LayoutOrder = 3
WhitelistNavBtn.Parent = NavMenu
local WhitelistNavCorner = Instance.new("UICorner")
WhitelistNavCorner.CornerRadius = UDim.new(0, 6)
WhitelistNavCorner.Parent = WhitelistNavBtn

local WhitelistNavAccent = Instance.new("Frame")
WhitelistNavAccent.Size = UDim2.new(0, 2, 1, 0)
WhitelistNavAccent.Position = UDim2.new(0, 0, 0, 0)
WhitelistNavAccent.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
WhitelistNavAccent.BorderSizePixel = 0
WhitelistNavAccent.Visible = false
WhitelistNavAccent.Parent = WhitelistNavBtn

local WhitelistNavPad = Instance.new("UIPadding")
WhitelistNavPad.PaddingLeft = UDim.new(0, 14)
WhitelistNavPad.Parent = WhitelistNavBtn

AccountBlock = Instance.new("Frame")
AccountBlock.Size = UDim2.new(1, 0, 0, 92)
AccountBlock.Position = UDim2.new(0, 0, 1, -92)
AccountBlock.BackgroundTransparency = 1
AccountBlock.Parent = Sidebar

AvatarRing = Instance.new("Frame")
AvatarRing.Size = UDim2.new(0, 46, 0, 46)
AvatarRing.Position = UDim2.new(0.5, -23, 0, 4)
AvatarRing.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
AvatarRing.BorderSizePixel = 0
AvatarRing.Parent = AccountBlock
local AvatarRingCorner = Instance.new("UICorner")
AvatarRingCorner.CornerRadius = UDim.new(1, 0)
AvatarRingCorner.Parent = AvatarRing
local AvatarRingStroke = Instance.new("UIStroke")
AvatarRingStroke.Color = Color3.fromRGB(60, 160, 255)
AvatarRingStroke.Thickness = 2
AvatarRingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
AvatarRingStroke.Parent = AvatarRing

AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(1, -4, 1, -4)
AvatarImage.Position = UDim2.new(0, 2, 0, 2)
AvatarImage.BackgroundTransparency = 1
AvatarImage.BorderSizePixel = 0
AvatarImage.ScaleType = Enum.ScaleType.Crop
AvatarImage.Parent = AvatarRing
local AvatarImageCorner = Instance.new("UICorner")
AvatarImageCorner.CornerRadius = UDim.new(1, 0)
AvatarImageCorner.Parent = AvatarImage

pcall(function()
    local thumb = game:GetService("Thumbnails"):GetPlayerThumbnail(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    if thumb and thumb ~= "" then
        AvatarImage.Image = thumb
    end
end)

AccountName = Instance.new("TextLabel")
AccountName.Size = UDim2.new(1, -8, 0, 16)
AccountName.Position = UDim2.new(0, 4, 0, 54)
AccountName.BackgroundTransparency = 1
AccountName.Text = LocalPlayer.DisplayName or LocalPlayer.Name
AccountName.TextColor3 = Color3.fromRGB(210, 210, 220)
AccountName.Font = Enum.Font.Code
AccountName.TextSize = 10
AccountName.TextXAlignment = Enum.TextXAlignment.Center
AccountName.TextTruncate = Enum.TextTruncate.AtEnd
AccountName.Parent = AccountBlock

AccountUser = Instance.new("TextLabel")
AccountUser.Size = UDim2.new(1, -8, 0, 13)
AccountUser.Position = UDim2.new(0, 4, 0, 70)
AccountUser.BackgroundTransparency = 1
AccountUser.Text = "@" .. LocalPlayer.Name
AccountUser.TextColor3 = Color3.fromRGB(70, 70, 90)
AccountUser.Font = Enum.Font.Code
AccountUser.TextSize = 9
AccountUser.TextXAlignment = Enum.TextXAlignment.Center
AccountUser.TextTruncate = Enum.TextTruncate.AtEnd
AccountUser.Parent = AccountBlock

local InsertHint = Instance.new("TextLabel")
InsertHint.Size = UDim2.new(1, -10, 0, 14)
InsertHint.Position = UDim2.new(0, 5, 0, 0)
InsertHint.BackgroundTransparency = 1
InsertHint.Text ="INSERT = show/hide"
InsertHint.TextColor3 = Color3.fromRGB(38, 38, 52)
InsertHint.Font = Enum.Font.Code
InsertHint.TextSize = 9
InsertHint.TextXAlignment = Enum.TextXAlignment.Center
InsertHint.Parent = AccountBlock

ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -118, 1, -2)
ContentArea.Position = UDim2.new(0, 114, 0, 2)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local AimPanel = Instance.new("ScrollingFrame")
AimPanel.Size = UDim2.new(1, 0, 1, -30)
AimPanel.Position = UDim2.new(0, 0, 0, 0)
AimPanel.BackgroundTransparency = 1
AimPanel.BorderSizePixel = 0
AimPanel.ScrollBarThickness = 3
AimPanel.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
AimPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
AimPanel.Visible = true
AimPanel.Parent = ContentArea

local AimPanelLayout = Instance.new("UIListLayout")
AimPanelLayout.Padding = UDim.new(0, 0)
AimPanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
AimPanelLayout.Parent = AimPanel

local AimPanelPad = Instance.new("UIPadding")
AimPanelPad.PaddingTop = UDim.new(0, 12)
AimPanelPad.PaddingLeft = UDim.new(0, 12)
AimPanelPad.PaddingRight = UDim.new(0, 12)
AimPanelPad.Parent = AimPanel

local VisualPanel = Instance.new("ScrollingFrame")
VisualPanel.Size = UDim2.new(1, 0, 1, -30)
VisualPanel.Position = UDim2.new(0, 0, 0, 0)
VisualPanel.BackgroundTransparency = 1
VisualPanel.BorderSizePixel = 0
VisualPanel.ScrollBarThickness = 3
VisualPanel.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
VisualPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
VisualPanel.Visible = false
VisualPanel.Parent = ContentArea

local VisualPanelLayout = Instance.new("UIListLayout")
VisualPanelLayout.Padding = UDim.new(0, 0)
VisualPanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
VisualPanelLayout.Parent = VisualPanel

local VisualPanelPad = Instance.new("UIPadding")
VisualPanelPad.PaddingTop = UDim.new(0, 12)
VisualPanelPad.PaddingLeft = UDim.new(0, 12)
VisualPanelPad.PaddingRight = UDim.new(0, 12)
VisualPanelPad.Parent = VisualPanel

local WhitelistPanel = Instance.new("ScrollingFrame")
WhitelistPanel.Size = UDim2.new(1, 0, 1, -30)
WhitelistPanel.Position = UDim2.new(0, 0, 0, 0)
WhitelistPanel.BackgroundTransparency = 1
WhitelistPanel.BorderSizePixel = 0
WhitelistPanel.ScrollBarThickness = 3
WhitelistPanel.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
WhitelistPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
WhitelistPanel.Visible = false
WhitelistPanel.Parent = ContentArea

local WhitelistPanelLayout = Instance.new("UIListLayout")
WhitelistPanelLayout.Padding = UDim.new(0, 0)
WhitelistPanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
WhitelistPanelLayout.Parent = WhitelistPanel

local WhitelistPanelPad = Instance.new("UIPadding")
WhitelistPanelPad.PaddingTop = UDim.new(0, 12)
WhitelistPanelPad.PaddingLeft = UDim.new(0, 12)
WhitelistPanelPad.PaddingRight = UDim.new(0, 12)
WhitelistPanelPad.Parent = WhitelistPanel

local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, 0, 0, 28)
Footer.Position = UDim2.new(0, 0, 0, 1)
Footer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Footer.BorderSizePixel = 0
Footer.Parent = MainFrame

local FooterSep = Instance.new("Frame")
FooterSep.Size = UDim2.new(1, 0, 0, 1)
FooterSep.Position = UDim2.new(0, 0, 0, 0)
FooterSep.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
FooterSep.BorderSizePixel = 0
FooterSep.Parent = Footer

local FooterDot = Instance.new("Frame")
FooterDot.Size = UDim2.new(0, 6, 0, 6)
FooterDot.Position = UDim2.new(0, 10, 0.5, -3)
FooterDot.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
FooterDot.BorderSizePixel = 0
FooterDot.Parent = Footer
local FooterDotCorner = Instance.new("UICorner")
FooterDotCorner.CornerRadius = UDim.new(1, 0)
FooterDotCorner.Parent = FooterDot

local FooterLabel = Instance.new("TextLabel")
FooterLabel.Size = UDim2.new(0, 160, 1, 0)
FooterLabel.Position = UDim2.new(0, 22, 0, 0)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Text ="ETERNAL FLICK"
FooterLabel.TextColor3 = Color3.fromRGB(60, 160, 255)
FooterLabel.Font = Enum.Font.Code
FooterLabel.TextSize = 11
FooterLabel.TextXAlignment = Enum.TextXAlignment.Left
FooterLabel.Parent = Footer

local function createSectionLabel(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.TextColor3 = Color3.fromRGB(60, 160, 255)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order or 0
    lbl.Parent = parent
    return lbl
end

local function createRow(parent, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 0
    row.Parent = parent
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.Position = UDim2.new(0, 0, 1, -1)
    sep.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    sep.BorderSizePixel = 0
    sep.Parent = row
    return row
end

local function addRowLabel(row, text, subtext)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 0, 18)
    lbl.Position = UDim2.new(0, 0, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    if subtext then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(0.6, 0, 0, 13)
        sub.Position = UDim2.new(0, 0, 0, 24)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextColor3 = Color3.fromRGB(55, 55, 70)
        sub.Font = Enum.Font.Code
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = row
    end
end

local function createToggleInRow(row)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 42, 0, 22)
    track.Position = UDim2.new(1, -42, 0.5, -11)
    track.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    track.BorderSizePixel = 0
    track.Parent = row
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 11)
    tc.Parent = track
    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 18, 0, 18)
    thumb.Position = UDim2.new(0, 2, 0.5, -9)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    local thc = Instance.new("UICorner")
    thc.CornerRadius = UDim.new(1, 0)
    thc.Parent = thumb
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text =""
    btn.Parent = track
    return track, thumb, btn
end

local function AnimateToggle(track, thumb, enabled)
    if not track or not thumb then return end
    local thumbPos = enabled and UDim2.new(0, 22, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    local trackColor = enabled and Color3.fromRGB(60, 160, 255) or Color3.fromRGB(55, 55, 65)
    TweenService:Create(thumb, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = thumbPos}):Play()
    TweenService:Create(track, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = trackColor}):Play()
end

local function startDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
        frameStartPos = MainFrame.Position
    end
end

local function onDrag(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
        local newX = frameStartPos.X.Offset + delta.X
        local newY = frameStartPos.Y.Offset + delta.Y
        MainFrame.Position = UDim2.new(frameStartPos.X.Scale, newX, frameStartPos.Y.Scale, newY)
    end
end

local function stopDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end

TitleBar.InputBegan:Connect(startDrag)
UserInputService.InputChanged:Connect(onDrag)
UserInputService.InputEnded:Connect(stopDrag)

local function IsPlayerVisible(targetCharacter)
    if not LocalPlayer.Character then return false end
    local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    local targetHead = targetCharacter:FindFirstChild("Head")
    if not localRoot or not targetRoot then return false end
    local targetPart = targetHead or targetRoot
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    local raycastResult = workspace:Raycast(localRoot.Position, (targetPart.Position - localRoot.Position), raycastParams)
    return raycastResult == nil
end

local function GetDistance(player)
    if not LocalPlayer.Character or not player.Character then return nil end
    local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot or not targetRoot then return nil end
    return math.floor((localRoot.Position - targetRoot.Position).Magnitude)
end

local function IsInFOV(player)
    if not player.Character or not camera then return false end
    local head = player.Character:FindFirstChild("Head")
    if not head then return false end
    local mouseLoc = UserInputService:GetMouseLocation()
    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
    if onScreen and screenPos.Z > 0 then
        local dx = screenPos.X - mouseLoc.X
        local dy = screenPos.Y - mouseLoc.Y
        local dist = math.sqrt(dx*dx + dy*dy)
        return dist <= FOV_RADIUS
    end
    return false
end

local function IsWhitelisted(player)
    for _, wl in ipairs(Whitelist) do
        if wl == player then return true end
    end
    return false
end

local function UpdateESPColor(highlight, isVisible, isInFOV, isWhitelisted)
    if isWhitelisted then
        highlight.FillColor = Color3.fromRGB(220, 220, 255)
        highlight.OutlineColor = Color3.fromRGB(180, 180, 220)
        highlight.FillTransparency = 0.2
        highlight.OutlineTransparency = 0.05
    elseif isVisible and isInFOV then
        highlight.FillColor = Color3.fromRGB(0, 200, 50)
        highlight.OutlineColor = Color3.fromRGB(0, 150, 30)
        highlight.FillTransparency = 0.25
        highlight.OutlineTransparency = 0.05
    elseif isVisible then
        highlight.FillColor = Color3.fromRGB(20, 50, 200)
        highlight.OutlineColor = Color3.fromRGB(15, 40, 160)
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 0.1
    else
        highlight.FillColor = Color3.fromRGB(180, 30, 30)
        highlight.OutlineColor = Color3.fromRGB(140, 20, 20)
        highlight.FillTransparency = 0.35
        highlight.OutlineTransparency = 0.15
    end
end

local function UpdateNameColor(nameText, distanceText, isVisible, isInFOV, isWhitelisted)
    local col
    if isWhitelisted then
        col = Color3.fromRGB(255, 255, 255)
    elseif isVisible and isInFOV then
        col = Color3.fromRGB(0, 220, 80)
    elseif isVisible then
        col = Color3.fromRGB(20, 100, 220)
    else
        col = Color3.fromRGB(200, 40, 40)
    end
    nameText.TextColor3 = col
    if distanceText then distanceText.TextColor3 = Color3.fromRGB(255, 255, 255) end
end

local ESPTrack, ESPThumb, ESPBtn = nil, nil, nil
local ESPDistTrack, ESPDistThumb, ESPDistBtn = nil, nil, nil
local FOVCircleTrack, FOVCircleThumb, FOVCircleBtn = nil, nil, nil
local HealthBarTrack, HealthBarThumb, HealthBarBtn = nil, nil, nil
local HealthPVTrack, HealthPVThumb, HealthPVBtn = nil, nil, nil
local SkeletonTrack, SkeletonThumb, SkeletonBtn = nil, nil, nil
local TracerTrack, TracerThumb, TracerBtn = nil, nil, nil

local function RefreshESP()
    if ESP_Enabled then
        for player, data in pairs(ESP_Objects) do
            if data and data.Billboard and data.Billboard.Parent then
                if data.DistanceFrame then
                    data.DistanceFrame.Visible = ESPDistance_Enabled
                end
                if data.HealthBar then
                    data.HealthBar.Visible = HealthBar_Enabled
                end
                if data.HealthPV then
                    data.HealthPV.Visible = HealthPV_Enabled or (V and V.ESPPV)
                end
            end
        end
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESP_Objects[player] then return end
    
    local function OnCharacterAdded(character)
        if not ESP_Enabled or not character or not character.Parent then return end
        
        local oldData = ESP_Objects[player]
        if oldData then
            if oldData.Highlight then oldData.Highlight:Destroy() end
            if oldData.Billboard then oldData.Billboard:Destroy() end
            if oldData.UpdateConnection then oldData.UpdateConnection:Disconnect() end
            if oldData.DistanceFrame then oldData.DistanceFrame:Destroy() end
            if oldData.SkeletonFolder then oldData.SkeletonFolder:Destroy() end
            ESP_Objects[player] = nil
        end
        
        local humanoid, rootPart, head
        for i = 1, 10 do
            humanoid = character:FindFirstChild("Humanoid")
            rootPart = character:FindFirstChild("HumanoidRootPart")
            head = character:FindFirstChild("Head")
            if humanoid and rootPart then break end
            task.wait(0.1)
        end
        if not humanoid or not rootPart then return end
        
        local highlight = Instance.new("Highlight")
        highlight.Name ="ESP_Highlight"
        highlight.FillColor = Color3.fromRGB(180, 30, 30)
        highlight.OutlineColor = Color3.fromRGB(140, 20, 20)
        highlight.FillTransparency = 0.35
        highlight.OutlineTransparency = 0.15
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = character
        highlight.Parent = character

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name ="ESP_NameTag"
        billboardGui.Size = UDim2.new(0, 200, 0, 28)
        billboardGui.StudsOffset = Vector3.new(0, 2.2, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.LightInfluence = 0
        billboardGui.MaxDistance = 300
        billboardGui.Adornee = head or rootPart
        billboardGui.Parent = character

        local nameBg = Instance.new("Frame")
        nameBg.Size = UDim2.new(1, -10, 1, 0)
        nameBg.Position = UDim2.new(0, 9, 0, 0)
        nameBg.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
        nameBg.BackgroundTransparency = 0.45
        nameBg.BorderSizePixel = 0
        nameBg.Parent = billboardGui
        local nameBgCorner = Instance.new("UICorner")
        nameBgCorner.CornerRadius = UDim.new(0, 4)
        nameBgCorner.Parent = nameBg

        local mainContainer = Instance.new("Frame")
        mainContainer.Name ="mainContainer"
        mainContainer.Size = UDim2.new(1, -10, 1, 0)
        mainContainer.Position = UDim2.new(0, 9, 0, 0)
        mainContainer.BackgroundTransparency = 1
        mainContainer.Parent = billboardGui

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name ="NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 4, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(200, 40, 40)
        nameLabel.TextStrokeTransparency = 0.4
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Text = player.Name
        nameLabel.Font = Enum.Font.Code
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.Parent = mainContainer

        local distanceFrame = nil
        local distanceText = nil
        if ESPDistance_Enabled then
            distanceFrame = Instance.new("Frame")
            distanceFrame.Size = UDim2.new(1, -10, 0, 14)
            distanceFrame.Position = UDim2.new(0, 9, 1, -14)
            distanceFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
            distanceFrame.BackgroundTransparency = 0.45
            distanceFrame.BorderSizePixel = 0
            distanceFrame.Parent = billboardGui
            local dfc = Instance.new("UICorner")
            dfc.CornerRadius = UDim.new(0, 4)
            dfc.Parent = distanceFrame
            distanceText = Instance.new("TextLabel")
            distanceText.Size = UDim2.new(1, 0, 1, 0)
            distanceText.BackgroundTransparency = 1
            distanceText.TextColor3 = Color3.fromRGB(255, 255, 255)
            distanceText.TextStrokeTransparency = 0.4
            distanceText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            distanceText.Font = Enum.Font.Code
            distanceText.TextSize = 10
            distanceText.Text = (GetDistance(player) or"?") .."m"
            distanceText.TextXAlignment = Enum.TextXAlignment.Center
            distanceText.TextYAlignment = Enum.TextYAlignment.Center
            distanceText.Parent = distanceFrame
        end

        local healthBarBg = Instance.new("Frame")
        healthBarBg.Name ="ESP_HealthBarBg"
        healthBarBg.Size = UDim2.new(0, 5, 0, 28)
        healthBarBg.Position = UDim2.new(0, 1, 0, 0)
        healthBarBg.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
        healthBarBg.BackgroundTransparency = 0.15
        healthBarBg.BorderSizePixel = 0
        healthBarBg.ZIndex = 3
        healthBarBg.Visible = HealthBar_Enabled
        healthBarBg.Parent = billboardGui

        local healthBarStroke = Instance.new("UIStroke")
        healthBarStroke.Color = Color3.fromRGB(255, 255, 255)
        healthBarStroke.Thickness = 1
        healthBarStroke.Transparency = 0.6
        healthBarStroke.Parent = healthBarBg

        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.AnchorPoint = Vector2.new(0.5, 1)
        healthFill.Position = UDim2.new(0.5, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = healthBarBg

        local healthPvLabel = Instance.new("TextLabel")
        healthPvLabel.Name = "ESP_HealthPV"
        healthPvLabel.Size = UDim2.new(0, 42, 0, 12)
        healthPvLabel.Position = UDim2.new(0, -18, 1, 2)
        healthPvLabel.BackgroundTransparency = 1
        healthPvLabel.Font = Enum.Font.GothamBold
        healthPvLabel.TextSize = 9
        healthPvLabel.TextColor3 = Color3.fromRGB(0, 230, 120)
        healthPvLabel.TextStrokeTransparency = 0.5
        healthPvLabel.Text = "100 PV"
        healthPvLabel.Visible = HealthPV_Enabled or (V and V.ESPPV)
        healthPvLabel.Parent = healthBarBg

        local function UpdateESPVisuals()
            if not ESP_Enabled or not character.Parent or not LocalPlayer.Character then return end
            local isVisible = IsPlayerVisible(character)
            local isInFOV = IsInFOV(player)
            local isWhitelisted = IsWhitelisted(player)
            UpdateESPColor(highlight, isVisible, isInFOV, isWhitelisted)
            UpdateNameColor(nameLabel, distanceText, isVisible, isInFOV, isWhitelisted)
            if humanoid and healthFill then
                local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                healthFill.Size = UDim2.new(1, 0, ratio, 0)
                healthFill.BackgroundColor3 = Color3.fromRGB(
                    math.floor(220 * (1 - ratio)),
                    math.floor(200 * ratio) + 40,
                    40
                )
            end
            if humanoid and healthPvLabel then
                healthPvLabel.Visible = (HealthPV_Enabled or (V and V.ESPPV)) and (healthBarBg.Visible or ESP_Enabled)
                if healthPvLabel.Visible then
                    local curHp = math.max(0, math.floor(humanoid.Health))
                    healthPvLabel.Text = curHp .. " PV"
                    local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                    healthPvLabel.TextColor3 = Color3.fromRGB(
                        math.floor(255 * (1 - ratio)),
                        math.floor(255 * ratio),
                        60
                    )
                end
            end
            if ESPDistance_Enabled and distanceText then
                local dist = GetDistance(player)
                if dist then distanceText.Text = dist .."m"end
            end
        end

        local updateConnection
        updateConnection = RunService.RenderStepped:Connect(UpdateESPVisuals)

        ESP_Objects[player] = {
            Highlight = highlight,
            Billboard = billboardGui,
            UpdateConnection = updateConnection,
            Character = character,
            DistanceFrame = distanceFrame,
            HealthBar = healthBarBg,
            HealthPV = healthPvLabel,
            mainContainer = mainContainer,
            nameLabel = nameLabel
        }
    end
    
    if player.Character and player.Character.Parent then
        OnCharacterAdded(player.Character)
    end
    local conn = player.CharacterAdded:Connect(OnCharacterAdded)
    ESP_Connections[player] = conn
end

local function CleanPlayer(player)
    local data = ESP_Objects[player]
    if not data then return end
    if data.Highlight then data.Highlight:Destroy() end
    if data.Billboard then data.Billboard:Destroy() end
    if data.UpdateConnection then data.UpdateConnection:Disconnect() end
    if data.DistanceFrame then data.DistanceFrame:Destroy() end
    if data.SkeletonFolder then data.SkeletonFolder:Destroy() end
    ESP_Objects[player] = nil
end

local function ClearESP()
    for player in pairs(ESP_Objects) do CleanPlayer(player) end
    for player, conn in pairs(ESP_Connections) do 
        if conn then 
            conn:Disconnect() 
        end 
    end
    ESP_Connections = {}
end

local function ToggleESP()
    ESP_Enabled = not ESP_Enabled
    AnimateToggle(ESPTrack, ESPThumb, ESP_Enabled)
    if ESP_Enabled then
        ClearESP()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then CreateESP(plr) end
        end
    else
        ClearESP()
    end
end

local function ToggleESPDistance()
    ESPDistance_Enabled = not ESPDistance_Enabled
    AnimateToggle(ESPDistTrack, ESPDistThumb, ESPDistance_Enabled)
    RefreshESP()
end

local function ToggleHealthBar()
    HealthBar_Enabled = not HealthBar_Enabled
    AnimateToggle(HealthBarTrack, HealthBarThumb, HealthBar_Enabled)
    RefreshESP()
end

local function ToggleHealthPV()
    HealthPV_Enabled = not HealthPV_Enabled
    V.ESPPV = HealthPV_Enabled
    AnimateToggle(HealthPVTrack, HealthPVThumb, HealthPV_Enabled)
    RefreshESP()
end

local function ToggleSkeleton()
    Skeleton_Enabled = not Skeleton_Enabled
    AnimateToggle(SkeletonTrack, SkeletonThumb, Skeleton_Enabled)
end

local function ToggleTracer()
    Tracer_Enabled = not Tracer_Enabled
    AnimateToggle(TracerTrack, TracerThumb, Tracer_Enabled)
end

local espOverlayGui = nil
local espOverlayConnection = nil
local ESP_LINE_THICKNESS = 2

local function GetOverlayGui()
    if espOverlayGui and espOverlayGui.Parent then return espOverlayGui end
    local gui = Instance.new("ScreenGui")
    gui.Name ="ESP_OverlayGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    if gethui then gui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent = game:GetService("CoreGui")
    else gui.Parent = game:GetService("CoreGui") end
    espOverlayGui = gui
    return gui
end

local function GetSkeletonJoints(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
        return {
            {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
            {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
            {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
            {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
            {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"}
        }
    end
    return {
        {"Head","Torso"},
        {"Torso","Left Arm"}, {"Torso","Right Arm"},
        {"Torso","Left Leg"}, {"Torso","Right Leg"}
    }
end

local function PositionLineFrame(line, cache, from, to)
    local x1 = math.floor(from.X + 0.5)
    local y1 = math.floor(from.Y + 0.5)
    local x2 = math.floor(to.X + 0.5)
    local y2 = math.floor(to.Y + 0.5)
    if x1 == x2 and y1 == y2 then
        line.Visible = false
        return
    end
    if cache and cache.X1 == x1 and cache.Y1 == y1 and cache.X2 == x2 and cache.Y2 == y2 then
        if not line.Visible then line.Visible = true end
        return
    end
    line.Size = UDim2.new(0, math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2), 0, ESP_LINE_THICKNESS)
    line.Position = UDim2.new(0, (x1 + x2) / 2, 0, (y1 + y2) / 2)
    line.Rotation = math.deg(math.atan2(y2 - y1, x2 - x1))
    line.Visible = true
    if cache then
        cache.X1, cache.Y1, cache.X2, cache.Y2 = x1, y1, x2, y2
    end
end

local function GetOrCreateLine(data, index)
    local line = data.SkeletonLines[index]
    if not line then
        line = Instance.new("Frame")
        line.BorderSizePixel = 0
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.Parent = data.SkeletonFolder
        data.SkeletonLines[index] = line
        data.LineCaches[index] = {}
    end
    return line, data.LineCaches[index]
end

local function HideESPOverlayLines(data)
    if data.SkeletonLines then
        for _, line in ipairs(data.SkeletonLines) do line.Visible = false end
    end
    if data.TracerLine then data.TracerLine.Visible = false end
end

local espOverlayTick = 0

local function UpdateESPOverlays()
    if not camera then return end

    local drawSkeleton = Skeleton_Enabled
    local drawTracer = Tracer_Enabled

    if not drawSkeleton and not drawTracer then
        for _, data in pairs(ESP_Objects) do
            if data then HideESPOverlayLines(data) end
        end
        return
    end

    espOverlayTick = espOverlayTick + 1
    if espOverlayTick % 2 ~= 0 then return end

    local viewportSize = camera.ViewportSize
    local localRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head"))

    for player, data in pairs(ESP_Objects) do
        if not data or not data.Character or not data.Character.Parent then
            if data then HideESPOverlayLines(data) end
            continue
        end

        if not data.SkeletonFolder then
            local folder = Instance.new("Folder")
            folder.Name ="ESP_OverlayLines"
            folder.Parent = GetOverlayGui()
            data.SkeletonFolder = folder
            data.SkeletonLines = {}
            data.LineCaches = {}
            data.Joints = GetSkeletonJoints(data.Character)
        end

        local character = data.Character
        local head = character:FindFirstChild("Head")
        local root = character:FindFirstChild("HumanoidRootPart")
        local anchor = head or root
        if not anchor then
            HideESPOverlayLines(data)
            continue
        end

        local anchorPos, anchorOnScreen = camera:WorldToViewportPoint(anchor.Position)
        if not anchorOnScreen or anchorPos.Z <= 0 then
            HideESPOverlayLines(data)
            continue
        end

        if localRoot and (localRoot.Position - anchor.Position).Magnitude > 400 then
            HideESPOverlayLines(data)
            continue
        end

        if drawSkeleton then
            local lineIdx = 0
            for _, pair in ipairs(data.Joints) do
                local partA = character:FindFirstChild(pair[1])
                local partB = character:FindFirstChild(pair[2])
                if partA and partB then
                    local posA, onScreenA = camera:WorldToViewportPoint(partA.Position)
                    local posB, onScreenB = camera:WorldToViewportPoint(partB.Position)
                    if onScreenA and onScreenB and posA.Z > 0 and posB.Z > 0 then
                        lineIdx = lineIdx + 1
                        local line, cache = GetOrCreateLine(data, lineIdx)
                        PositionLineFrame(line, cache, Vector2.new(posA.X, posA.Y), Vector2.new(posB.X, posB.Y))
                    end
                end
            end
            for i = lineIdx + 1, #data.SkeletonLines do
                data.SkeletonLines[i].Visible = false
            end
        else
            for _, line in ipairs(data.SkeletonLines) do line.Visible = false end
        end

        if drawTracer then
            local pos, onScreen = camera:WorldToViewportPoint(anchor.Position)
            if onScreen and pos.Z > 0 then
                if not data.TracerLine then
                    data.TracerLine = Instance.new("Frame")
                    data.TracerLine.BorderSizePixel = 0
                    data.TracerLine.AnchorPoint = Vector2.new(0.5, 0.5)
                    data.TracerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    data.TracerLine.Parent = data.SkeletonFolder
                    data.TracerCache = {}
                end
                PositionLineFrame(data.TracerLine, data.TracerCache, Vector2.new(viewportSize.X / 2, viewportSize.Y), Vector2.new(pos.X, pos.Y))
            elseif data.TracerLine then
                data.TracerLine.Visible = false
            end
        elseif data.TracerLine then
            data.TracerLine.Visible = false
        end
    end
end

espOverlayConnection = RunService.RenderStepped:Connect(UpdateESPOverlays)

createSectionLabel(AimPanel,"Aimlock", 1)

local aimRow = createRow(AimPanel, 2)
addRowLabel(aimRow,"Aimlock","Maintenir pour activer")

local HoldBadge = Instance.new("TextLabel")
HoldBadge.Size = UDim2.new(0, 36, 0, 16)
HoldBadge.Position = UDim2.new(1, -88, 0.5, -8)
HoldBadge.BackgroundColor3 = Color3.fromRGB(22, 18, 0)
HoldBadge.Text ="HOLD"
HoldBadge.TextColor3 = Color3.fromRGB(255, 160, 0)
HoldBadge.Font = Enum.Font.Code
HoldBadge.TextSize = 9
HoldBadge.BorderSizePixel = 0
HoldBadge.Parent = aimRow
local HoldCorner = Instance.new("UICorner")
HoldCorner.CornerRadius = UDim.new(0, 3)
HoldCorner.Parent = HoldBadge
local HoldStroke = Instance.new("UIStroke")
HoldStroke.Color = Color3.fromRGB(80, 55, 0)
HoldStroke.Thickness = 1
HoldStroke.Parent = HoldBadge

local AimlockTrack, AimlockThumb, AimlockBtn = createToggleInRow(aimRow)
AimlockTrack.Position = UDim2.new(1, -42, 0.5, -11)

local keyRow = createRow(AimPanel, 3)
addRowLabel(keyRow,"Clic Aimlock")

local KeyButton = Instance.new("TextButton")
KeyButton.Size = UDim2.new(0, 80, 0, 24)
KeyButton.Position = UDim2.new(1, -82, 0.5, -12)
KeyButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
KeyButton.BorderSizePixel = 0
KeyButton.Text ="M1"
KeyButton.TextColor3 = Color3.fromRGB(60, 160, 255)
KeyButton.Font = Enum.Font.Code
KeyButton.TextSize = 12
KeyButton.Parent = keyRow
local KBCorner = Instance.new("UICorner")
KBCorner.CornerRadius = UDim.new(0, 5)
KBCorner.Parent = KeyButton
local KBStroke = Instance.new("UIStroke")
KBStroke.Color = Color3.fromRGB(35, 35, 52)
KBStroke.Thickness = 1
KBStroke.Parent = KeyButton

createSectionLabel(AimPanel,"FOV", 4)

local fovSliderRow = Instance.new("Frame")
fovSliderRow.Size = UDim2.new(1, 0, 0, 52)
fovSliderRow.BackgroundTransparency = 1
fovSliderRow.LayoutOrder = 5
fovSliderRow.Parent = AimPanel

local FOVTitleLabel = Instance.new("TextLabel")
FOVTitleLabel.Size = UDim2.new(0.6, 0, 0, 14)
FOVTitleLabel.Position = UDim2.new(0, 0, 0, 4)
FOVTitleLabel.BackgroundTransparency = 1
FOVTitleLabel.Text ="Taille du FOV"
FOVTitleLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
FOVTitleLabel.Font = Enum.Font.Code
FOVTitleLabel.TextSize = 11
FOVTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVTitleLabel.Parent = fovSliderRow

local FOVValLabel = Instance.new("TextLabel")
FOVValLabel.Size = UDim2.new(0.4, 0, 0, 14)
FOVValLabel.Position = UDim2.new(0.6, 0, 0, 4)
FOVValLabel.BackgroundTransparency = 1
FOVValLabel.Text ="150px"
FOVValLabel.TextColor3 = Color3.fromRGB(60, 160, 255)
FOVValLabel.Font = Enum.Font.Code
FOVValLabel.TextSize = 11
FOVValLabel.TextXAlignment = Enum.TextXAlignment.Right
FOVValLabel.Parent = fovSliderRow

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, 0, 0, 4)
SliderTrack.Position = UDim2.new(0, 0, 0, 28)
SliderTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = fovSliderRow
local SliderTrackCorner = Instance.new("UICorner")
SliderTrackCorner.CornerRadius = UDim.new(1, 0)
SliderTrackCorner.Parent = SliderTrack

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new((FOV_RADIUS - 30) / 270, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack
local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(1, 0)
SliderFillCorner.Parent = SliderFill

local SliderThumb = Instance.new("Frame")
SliderThumb.Size = UDim2.new(0, 13, 0, 13)
SliderThumb.Position = UDim2.new((FOV_RADIUS - 30) / 270, -6, 0.5, -6)
SliderThumb.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
SliderThumb.BorderSizePixel = 0
SliderThumb.Parent = SliderTrack
local SliderThumbCorner = Instance.new("UICorner")
SliderThumbCorner.CornerRadius = UDim.new(1, 0)
SliderThumbCorner.Parent = SliderThumb
local SliderThumbStroke = Instance.new("UIStroke")
SliderThumbStroke.Color = Color3.fromRGB(255, 255, 255)
SliderThumbStroke.Thickness = 2
SliderThumbStroke.Parent = SliderThumb

local fovCircleRow = createRow(AimPanel, 6)
addRowLabel(fovCircleRow,"Afficher le cercle FOV","Montre la zone d'aimlock")
FOVCircleTrack, FOVCircleThumb, FOVCircleBtn = createToggleInRow(fovCircleRow)

createSectionLabel(VisualPanel,"ESP", 1)

local espRow = createRow(VisualPanel, 2)
addRowLabel(espRow,"ESP Joueurs","Highlight + Nametag")
ESPTrack, ESPThumb, ESPBtn = createToggleInRow(espRow)

local espDistRow = createRow(VisualPanel, 3)
addRowLabel(espDistRow,"ESP Distance","Afficher la distance (m)")
ESPDistTrack, ESPDistThumb, ESPDistBtn = createToggleInRow(espDistRow)

local healthBarRow = createRow(VisualPanel, 4)
addRowLabel(healthBarRow,"ESP Health Bar","Barre de vie au-dessus du nametag")
HealthBarTrack, HealthBarThumb, HealthBarBtn = createToggleInRow(healthBarRow)

local healthPvRow = createRow(VisualPanel, 5)
addRowLabel(healthPvRow,"Afficher PV","Affiche les PV numeriques sous la barre")
HealthPVTrack, HealthPVThumb, HealthPVBtn = createToggleInRow(healthPvRow)

local skeletonRow = createRow(VisualPanel, 6)
addRowLabel(skeletonRow,"ESP Skeleton","Squelette du joueur à travers les murs")
SkeletonTrack, SkeletonThumb, SkeletonBtn = createToggleInRow(skeletonRow)

local tracerRow = createRow(VisualPanel, 7)
addRowLabel(tracerRow,"ESP Tracer","Ligne depuis le bas de l'écran")
TracerTrack, TracerThumb, TracerBtn = createToggleInRow(tracerRow)

createSectionLabel(WhitelistPanel,"Whitelist", 1)

local whitelistInfoRow = createRow(WhitelistPanel, 2)
addRowLabel(whitelistInfoRow,"Joueurs Whitelistés","ESP blanc - Aimlock ignoré")

local whitelistDisplayRow = createRow(WhitelistPanel, 3)
addRowLabel(whitelistDisplayRow,"Whitelist actuelle","")

local WhitelistDisplayLabel = Instance.new("TextLabel")
WhitelistDisplayLabel.Size = UDim2.new(1, -20, 0, 36)
WhitelistDisplayLabel.Position = UDim2.new(0, 10, 0.5, -18)
WhitelistDisplayLabel.BackgroundTransparency = 1
WhitelistDisplayLabel.Text ="Aucun"
WhitelistDisplayLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
WhitelistDisplayLabel.Font = Enum.Font.Code
WhitelistDisplayLabel.TextSize = 11
WhitelistDisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
WhitelistDisplayLabel.TextWrapped = true
WhitelistDisplayLabel.Parent = whitelistDisplayRow

local whitelistSelectRow = createRow(WhitelistPanel, 4)
addRowLabel(whitelistSelectRow,"Ajouter/Retirer","Cliquez sur un joueur")

local PlayerDropdownButton = Instance.new("TextButton")
PlayerDropdownButton.Size = UDim2.new(0, 160, 0, 32)
PlayerDropdownButton.Position = UDim2.new(1, -170, 0.5, -16)
PlayerDropdownButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
PlayerDropdownButton.BorderSizePixel = 0
PlayerDropdownButton.Text ="Sélectionner..."
PlayerDropdownButton.TextColor3 = Color3.fromRGB(140, 140, 160)
PlayerDropdownButton.Font = Enum.Font.Code
PlayerDropdownButton.TextSize = 11
PlayerDropdownButton.Parent = whitelistSelectRow
local PDCorner = Instance.new("UICorner")
PDCorner.CornerRadius = UDim.new(0, 5)
PDCorner.Parent = PlayerDropdownButton

local function UpdateWhitelistDisplay()
    local playersList = {}
    for _, player in ipairs(Whitelist) do
        table.insert(playersList, player.Name)
    end
    if #playersList == 0 then
        WhitelistDisplayLabel.Text ="Aucun"
        WhitelistDisplayLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
    else
        WhitelistDisplayLabel.Text = table.concat(playersList,",")
        WhitelistDisplayLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    end
end

local function CreatePlayerDropdown()
    if WhitelistDropdown then WhitelistDropdown:Destroy() end
    
    WhitelistDropdown = Instance.new("Frame")
    WhitelistDropdown.Size = UDim2.new(0, 160, 0, 150)
    WhitelistDropdown.Position = UDim2.new(1, -170, 0, 36)
    WhitelistDropdown.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    WhitelistDropdown.BorderSizePixel = 0
    WhitelistDropdown.ClipsDescendants = true
    WhitelistDropdown.Visible = false
    WhitelistDropdown.Parent = whitelistSelectRow
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 5)
    dropdownCorner.Parent = WhitelistDropdown
    
    local dropdownStroke = Instance.new("UIStroke")
    dropdownStroke.Color = Color3.fromRGB(40, 40, 55)
    dropdownStroke.Thickness = 1
    dropdownStroke.Parent = WhitelistDropdown
    
    local scroller = Instance.new("ScrollingFrame")
    scroller.Size = UDim2.new(1, 0, 1, 0)
    scroller.BackgroundTransparency = 1
    scroller.BorderSizePixel = 0
    scroller.ScrollBarThickness = 3
    scroller.Parent = WhitelistDropdown
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 0)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroller
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
            btn.BorderSizePixel = 0
            btn.Text = player.Name
            btn.TextColor3 = Color3.fromRGB(200, 200, 220)
            btn.Font = Enum.Font.Code
            btn.TextSize = 11
            btn.Parent = scroller
            
            local isWhitelisted = false
            for _, wl in ipairs(Whitelist) do
                if wl == player then isWhitelisted = true break end
            end
            
            if isWhitelisted then
                btn.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
                btn.TextColor3 = Color3.fromRGB(0, 200, 80)
                btn.Text ="[]".. player.Name
            end
            
            btn.MouseButton1Click:Connect(function()
                local found = false
                for i, wl in ipairs(Whitelist) do
                    if wl == player then
                        table.remove(Whitelist, i)
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(Whitelist, player)
                end
                UpdateWhitelistDisplay()
                RefreshESP()
                WhitelistDropdown.Visible = false
                WhitelistDropdownOpen = false
            end)
            
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            end)
            btn.MouseLeave:Connect(function()
                local isWl = false
                for _, wl in ipairs(Whitelist) do
                    if wl == player then isWl = true break end
                end
                if isWl then
                    btn.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
                end
            end)
        end
    end
end

PlayerDropdownButton.MouseButton1Click:Connect(function()
    if WhitelistDropdownOpen then
        WhitelistDropdown.Visible = false
        WhitelistDropdownOpen = false
    else
        if WhitelistDropdown then WhitelistDropdown:Destroy() end
        CreatePlayerDropdown()
        WhitelistDropdown.Visible = true
        WhitelistDropdownOpen = true
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and WhitelistDropdownOpen then
        local mousePos = input.Position
        local dropdownPos = WhitelistDropdown and WhitelistDropdown.AbsolutePosition
        local dropdownSize = WhitelistDropdown and WhitelistDropdown.AbsoluteSize
        if dropdownPos and dropdownSize then
            if not (mousePos.X >= dropdownPos.X and mousePos.X <= dropdownPos.X + dropdownSize.X and
                    mousePos.Y >= dropdownPos.Y and mousePos.Y <= dropdownPos.Y + dropdownSize.Y) then
                WhitelistDropdown.Visible = false
                WhitelistDropdownOpen = false
            end
        end
    end
end)

local function SwitchToAim()
    AimPanel.Visible = true
    VisualPanel.Visible = false
    WhitelistPanel.Visible = false
    AimNavBtn.BackgroundTransparency = 0.88
    AimNavBtn.TextColor3 = Color3.fromRGB(60, 160, 255)
    AimNavAccent.Visible = true
    VisualNavBtn.BackgroundTransparency = 1
    VisualNavBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
    VisualNavAccent.Visible = false
    WhitelistNavBtn.BackgroundTransparency = 1
    WhitelistNavBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
    WhitelistNavAccent.Visible = false
end

local function SwitchToVisual()
    AimPanel.Visible = false
    VisualPanel.Visible = true
    WhitelistPanel.Visible = false
    AimNavBtn.BackgroundTransparency = 1
    AimNavBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
    AimNavAccent.Visible = false
    VisualNavBtn.BackgroundTransparency = 0.88
    VisualNavBtn.TextColor3 = Color3.fromRGB(60, 160, 255)
    VisualNavAccent.Visible = true
    WhitelistNavBtn.BackgroundTransparency = 1
    WhitelistNavBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
    WhitelistNavAccent.Visible = false
end

local function SwitchToWhitelist()
    AimPanel.Visible = false
    VisualPanel.Visible = false
    WhitelistPanel.Visible = true
    AimNavBtn.BackgroundTransparency = 1
    AimNavBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
    AimNavAccent.Visible = false
    VisualNavBtn.BackgroundTransparency = 1
    VisualNavBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
    VisualNavAccent.Visible = false
    WhitelistNavBtn.BackgroundTransparency = 0.88
    WhitelistNavBtn.TextColor3 = Color3.fromRGB(60, 160, 255)
    WhitelistNavAccent.Visible = true
end

AimNavBtn.MouseButton1Click:Connect(SwitchToAim)
VisualNavBtn.MouseButton1Click:Connect(SwitchToVisual)
WhitelistNavBtn.MouseButton1Click:Connect(SwitchToWhitelist)

local function CreateFOVCircle()
    if fovCircle then
        if fovCircle.Parent then fovCircle.Parent:Destroy() end
        fovCircle = nil
    end
    if fovCrosshair then
        if fovCrosshair.Parent then fovCrosshair.Parent:Destroy() end
        fovCrosshair = nil
    end
    
    local circleGui = Instance.new("ScreenGui")
    circleGui.Name ="FOVCircleGui"
    circleGui.ResetOnSpawn = false
    circleGui.IgnoreGuiInset = true
    circleGui.Parent = ScreenGui
    
    fovCircle = Instance.new("Frame")
    fovCircle.Size = UDim2.new(0, FOV_RADIUS * 2, 0, FOV_RADIUS * 2)
    fovCircle.Position = UDim2.new(0.5, -FOV_RADIUS, 0.5, -FOV_RADIUS)
    fovCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fovCircle.BackgroundTransparency = 0.85
    fovCircle.BorderSizePixel = 2
    fovCircle.BorderColor3 = Color3.fromRGB(0, 0, 0)
    fovCircle.Parent = circleGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = fovCircle
    
    fovCrosshair = Instance.new("Frame")
    fovCrosshair.Size = UDim2.new(0, 20, 0, 2)
    fovCrosshair.Position = UDim2.new(0.5, -10, 0.5, -1)
    fovCrosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fovCrosshair.BorderSizePixel = 1
    fovCrosshair.BorderColor3 = Color3.fromRGB(0, 0, 0)
    fovCrosshair.Parent = circleGui
    
    local crosshairVertical = Instance.new("Frame")
    crosshairVertical.Size = UDim2.new(0, 2, 0, 20)
    crosshairVertical.Position = UDim2.new(0.5, -1, 0.5, -10)
    crosshairVertical.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshairVertical.BorderSizePixel = 1
    crosshairVertical.BorderColor3 = Color3.fromRGB(0, 0, 0)
    crosshairVertical.Parent = circleGui
    
    return circleGui
end

local fovCircleGui = CreateFOVCircle()
fovCircleGui.Enabled = false

local function SetFOVCircleVisible(visible)
    fovCircleVisible = visible
    if fovCircleGui then
        fovCircleGui.Enabled = visible
    end
end

local function ToggleFOVCircle()
    SetFOVCircleVisible(not fovCircleVisible)
    AnimateToggle(FOVCircleTrack, FOVCircleThumb, fovCircleVisible)
end

local function UpdateFOVCircle()
    if fovCircle and fovCircle.Parent then
        fovCircle.Size = UDim2.new(0, FOV_RADIUS * 2, 0, FOV_RADIUS * 2)
        fovCircle.Position = UDim2.new(0.5, -FOV_RADIUS, 0.5, -FOV_RADIUS)
    end
    FOVValLabel.Text = FOV_RADIUS .."px"
    local pct = (FOV_RADIUS - 30) / 270
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    SliderThumb.Position = UDim2.new(pct, -6, 0.5, -6)
end

local function UpdateFOVFromMouse(mousePos)
    local trackPos = SliderTrack.AbsolutePosition.X
    local trackWidth = SliderTrack.AbsoluteSize.X
    if trackWidth > 0 then
        local pct = math.clamp((mousePos.X - trackPos) / trackWidth, 0, 1)
        FOV_RADIUS = math.floor(30 + pct * 270)
        UpdateFOVCircle()
    end
end

local function onSliderInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        UpdateFOVFromMouse(input.Position)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingSlider = false end
        end)
    end
end

SliderThumb.InputBegan:Connect(onSliderInputBegan)
SliderTrack.InputBegan:Connect(onSliderInputBegan)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        UpdateFOVFromMouse(input.Position)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
end)

local function GetBestTarget()
    if not Aimlock_Enabled or not LocalPlayer.Character or not camera then return nil end
    local mouseLoc = UserInputService:GetMouseLocation()
    local bestTarget, bestDist = nil, FOV_RADIUS
    local teamCheckEnabled = (_G.Aimlock_TeamCheck ~= nil and _G.Aimlock_TeamCheck) or (Aimlock_TeamCheck ~= nil and Aimlock_TeamCheck) or (V and V.ESPTeamCheck)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if IsWhitelisted and IsWhitelisted(player) then continue end
            local isTeam = false
            if teamCheckEnabled then
                if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    isTeam = true
                elseif player.TeamColor and LocalPlayer.TeamColor and player.TeamColor == LocalPlayer.TeamColor then
                    isTeam = true
                end
            elseif player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                isTeam = true
            end
            if isTeam then continue end
            local head = player.Character:FindFirstChild("Head")
            local hum = player.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                if not IsPlayerVisible(player.Character) then continue end
                local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen and screenPos.Z > 0 then
                    local dx = screenPos.X - mouseLoc.X
                    local dy = screenPos.Y - mouseLoc.Y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist <= FOV_RADIUS and dist < bestDist then
                        bestDist = dist
                        bestTarget = player
                    end
                end
            end
        end
    end
    return bestTarget
end

local function IsTargetStillValid(target)
    if not target or not target.Parent then return false end
    if target == LocalPlayer then return false end
    local teamCheckEnabled = (_G.Aimlock_TeamCheck ~= nil and _G.Aimlock_TeamCheck) or (Aimlock_TeamCheck ~= nil and Aimlock_TeamCheck) or (V and V.ESPTeamCheck)
    if teamCheckEnabled and target:IsA("Player") then
        if target.Team and LocalPlayer.Team and target.Team == LocalPlayer.Team then return false end
        if target.TeamColor and LocalPlayer.TeamColor and target.TeamColor == LocalPlayer.TeamColor then return false end
    end
    if not target.Character or not target.Character.Parent then return false end
    local head = target.Character:FindFirstChild("Head")
    local hum = target.Character:FindFirstChild("Humanoid")
    if not head or not hum or hum.Health <= 0 then return false end
    return true
end

local function GetPredictedTargetPosition(target)
    if not target or not target.Character then return nil, nil end
    local head = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
    if not head then return nil, nil end
    local targetPos = head.Position
    local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local targetVelocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.new()
        if targetVelocity then
            local shotDistance = (camera.CFrame.Position - targetPos).Magnitude
            local travelTime = PredictionTravelTime + shotDistance * PredictionDistanceFactor
            local lead = Vector3.new(targetVelocity.X, 0, targetVelocity.Z) * travelTime * PredictionBoost
            if lead.Magnitude > 18 then lead = lead.Unit * 18 end
            targetPos = targetPos + lead
        end
    end
    return targetPos, head
end

local function Aimlock()
    if not Aimlock_Enabled then return end
    if not IsTargetStillValid(currentTarget) then
        currentTarget = GetBestTarget()
    end
    if IsTargetStillValid(currentTarget) and currentTarget.Character then
        local targetPos = GetPredictedTargetPosition(currentTarget)
        if targetPos then
            local currentPos = camera.CFrame.Position
            if (targetPos - currentPos).Magnitude > 0.5 then
                local targetCFrame = CFrame.lookAt(currentPos, targetPos, camera.CFrame.UpVector)
                camera.CFrame = targetCFrame
            end
        end
    else
        currentTarget = nil
    end
end

local function StartAimlock()
    if aimlockConnection then aimlockConnection:Disconnect(); aimlockConnection = nil end
    if Aimlock_Enabled then aimlockConnection = RunService:BindToRenderStep("NebulaAimlock", 250, Aimlock) end
end

local function ToggleAimlock()
    Aimlock_Enabled = not Aimlock_Enabled
    AnimateToggle(AimlockTrack, AimlockThumb, Aimlock_Enabled)
    if Aimlock_Enabled then
        StartAimlock()
    else
        if aimlockConnection then aimlockConnection:Disconnect(); aimlockConnection = nil end
    end
end

AimlockBtn.MouseButton1Click:Connect(ToggleAimlock)

local function GetKeyName(key)
    if typeof(key) =="EnumItem"then
        if key == Enum.UserInputType.MouseButton1 then return"M1"
        elseif key == Enum.UserInputType.MouseButton2 then return"M2"
        elseif key == Enum.UserInputType.MouseButton3 then return"M3"
        else return string.sub(tostring(key), 10) end
    end
    return tostring(key)
end

KeyButton.MouseButton1Click:Connect(function()
    waitingForKey = true
    KeyButton.Text ="..."
    KeyButton.TextColor3 = Color3.fromRGB(255, 170, 0)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if waitingForKey then
        local key, isMouse = nil, false
        if input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode; isMouse = false
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then key = Enum.UserInputType.MouseButton1; isMouse = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then key = Enum.UserInputType.MouseButton2; isMouse = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then key = Enum.UserInputType.MouseButton3; isMouse = true
        end
        if key then
            AimlockKey = key; isMouseButton = isMouse
            KeyButton.Text = GetKeyName(key)
            KeyButton.TextColor3 = Color3.fromRGB(60, 160, 255)
            waitingForKey = false
        end
        return
    end
    local function isMouseOverMenu()
        if BloxFruitsPanel and BloxFruitsPanel.Visible then
            local mp = UserInputService:GetMouseLocation()
            local pos = BloxFruitsPanel.AbsolutePosition
            local size = BloxFruitsPanel.AbsoluteSize
            return mp.X >= pos.X and mp.X <= pos.X + size.X and mp.Y >= pos.Y and mp.Y <= pos.Y + size.Y
        end
        return false
    end
    if not waitingForKey then
        local pressed = false
        if isMouseButton and AimlockKey then
            if input.UserInputType == AimlockKey then pressed = true end
        elseif not isMouseButton and AimlockKey then
            if input.KeyCode == AimlockKey then pressed = true end
        end
        if pressed and not Aimlock_Enabled and not isMouseOverMenu() then ToggleAimlock() end

    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not waitingForKey then
        local released = false
        if isMouseButton and AimlockKey then
            if input.UserInputType == AimlockKey then released = true end
        elseif not isMouseButton and AimlockKey then
            if input.KeyCode == AimlockKey then released = true end
        end
        if released and Aimlock_Enabled and not isMouseOverMenu() then ToggleAimlock() end
    end
end)

Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    if ESP_Enabled and player ~= LocalPlayer then CreateESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    CleanPlayer(player)
    for i, wl in ipairs(Whitelist) do
        if wl == player then
            table.remove(Whitelist, i)
            UpdateWhitelistDisplay()
            break
        end
    end
    if ESP_Connections[player] then 
        ESP_Connections[player]:Disconnect() 
        ESP_Connections[player] = nil 
    end
end)

ESPBtn.MouseButton1Click:Connect(ToggleESP)
ESPDistBtn.MouseButton1Click:Connect(ToggleESPDistance)
FOVCircleBtn.MouseButton1Click:Connect(ToggleFOVCircle)
HealthBarBtn.MouseButton1Click:Connect(ToggleHealthBar)
HealthPVBtn.MouseButton1Click:Connect(ToggleHealthPV)
SkeletonBtn.MouseButton1Click:Connect(ToggleSkeleton)
TracerBtn.MouseButton1Click:Connect(ToggleTracer)

AnimateToggle(ESPTrack, ESPThumb, false)
AnimateToggle(ESPDistTrack, ESPDistThumb, false)
AnimateToggle(FOVCircleTrack, FOVCircleThumb, false)
AnimateToggle(HealthBarTrack, HealthBarThumb, false)
AnimateToggle(HealthPVTrack, HealthPVThumb, false)
AnimateToggle(SkeletonTrack, SkeletonThumb, false)
AnimateToggle(TracerTrack, TracerThumb, false)
AnimateToggle(AimlockTrack, AimlockThumb, false)

SwitchToAim()
]]

murder_mystery = [[
Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existingGui = playerGui:FindFirstChild("UpdateGui")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name ="UpdateGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local blur = Instance.new("BlurEffect")
blur.Name ="BackgroundBlur"
blur.Size = 0
blur.Parent = screenGui

local darkOverlay = Instance.new("Frame")
darkOverlay.Name ="DarkOverlay"
darkOverlay.Size = UDim2.new(1, 0, 1, 0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
darkOverlay.BackgroundTransparency = 1
darkOverlay.BorderSizePixel = 0
darkOverlay.ZIndex = 0
darkOverlay.Parent = screenGui

local mainContainer = Instance.new("Frame")
mainContainer.Name ="MainContainer"
mainContainer.Size = UDim2.new(0, 420, 0, 210)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.BorderSizePixel = 0
mainContainer.ZIndex = 1
mainContainer.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name ="MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 19)
mainFrame.BackgroundTransparency = 1
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 1
mainFrame.Parent = mainContainer

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 255, 255)
uiStroke.Transparency = 0.93
uiStroke.Thickness = 0.5
uiStroke.Parent = mainFrame

local shadow = Instance.new("ImageLabel")
shadow.Name ="Shadow"
shadow.Size = UDim2.new(1, 24, 1, 24)
shadow.Position = UDim2.new(0, -12, 0, -12)
shadow.BackgroundTransparency = 1
shadow.Image ="rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.65
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.ZIndex = 0
shadow.Parent = mainFrame

local accentGlow = Instance.new("Frame")
accentGlow.Name ="AccentGlow"
accentGlow.Size = UDim2.new(0, 4, 1, -20)
accentGlow.Position = UDim2.new(0, 0, 0, 10)
accentGlow.BackgroundColor3 = Color3.fromRGB(140, 120, 255)
accentGlow.BorderSizePixel = 0
accentGlow.ZIndex = 2
accentGlow.Parent = mainFrame

local accentGlowCorner = Instance.new("UICorner")
accentGlowCorner.CornerRadius = UDim.new(1, 0)
accentGlowCorner.Parent = accentGlow

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 180, 255))
})
accentGradient.Rotation = 180
accentGradient.Parent = accentGlow

local contentFrame = Instance.new("Frame")
contentFrame.Name ="ContentFrame"
contentFrame.Size = UDim2.new(1, -32, 1, -28)
contentFrame.Position = UDim2.new(0, 22, 0, 16)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ZIndex = 1
contentFrame.Parent = mainFrame

local headerFrame = Instance.new("Frame")
headerFrame.Name ="HeaderFrame"
headerFrame.Size = UDim2.new(1, 0, 0, 28)
headerFrame.BackgroundTransparency = 1
headerFrame.BorderSizePixel = 0
headerFrame.Parent = contentFrame

local dotIndicator = Instance.new("Frame")
dotIndicator.Name ="DotIndicator"
dotIndicator.Size = UDim2.new(0, 6, 0, 6)
dotIndicator.Position = UDim2.new(0, 0, 0, 4)
dotIndicator.BackgroundColor3 = Color3.fromRGB(140, 120, 255)
dotIndicator.BorderSizePixel = 0
dotIndicator.Parent = headerFrame

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dotIndicator

local titleLabel = Instance.new("TextLabel")
titleLabel.Name ="TitleLabel"
titleLabel.Size = UDim2.new(0, 100, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text ="NOTIFICATION"
titleLabel.TextColor3 = Color3.fromRGB(160, 165, 190)
titleLabel.TextSize = 10
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextTransparency = 1
titleLabel.Parent = headerFrame

local versionLabel = Instance.new("TextLabel")
versionLabel.Name ="VersionLabel"
versionLabel.Size = UDim2.new(1, 0, 0, 30)
versionLabel.Position = UDim2.new(0, 0, 0, 32)
versionLabel.BackgroundTransparency = 1
versionLabel.Text ="Information"
versionLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
versionLabel.TextSize = 22
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.TextTransparency = 1
versionLabel.Parent = contentFrame

local messageLabel = Instance.new("TextLabel")
messageLabel.Name ="MessageLabel"
messageLabel.Size = UDim2.new(1, 0, 0, 72)
messageLabel.Position = UDim2.new(0, 0, 0, 68)
messageLabel.BackgroundTransparency = 1
messageLabel.Text ="Options pas ajouté"
messageLabel.TextColor3 = Color3.fromRGB(135, 140, 165)
messageLabel.TextSize = 12
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.TextWrapped = true
messageLabel.LineHeight = 1.55
messageLabel.TextTransparency = 1
messageLabel.Parent = contentFrame

local divider = Instance.new("Frame")
divider.Name ="Divider"
divider.Size = UDim2.new(1, 0, 0, 1)
divider.Position = UDim2.new(0, 0, 0, 148)
divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider.BackgroundTransparency = 0.95
divider.BorderSizePixel = 0
divider.Parent = contentFrame

local closeButton = Instance.new("TextButton")
closeButton.Name ="CloseButton"
closeButton.Size = UDim2.new(0, 90, 0, 30)
closeButton.Position = UDim2.new(0, 0, 0, 158)
closeButton.BackgroundColor3 = Color3.fromRGB(140, 120, 255)
closeButton.BackgroundTransparency = 0.88
closeButton.BorderSizePixel = 0
closeButton.Text ="Compris"
closeButton.TextColor3 = Color3.fromRGB(210, 210, 230)
closeButton.TextSize = 11
closeButton.Font = Enum.Font.GothamBold
closeButton.TextTransparency = 1
closeButton.AutoButtonColor = false
closeButton.ZIndex = 1
closeButton.Parent = contentFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 5)
buttonCorner.Parent = closeButton

local buttonGradient = Instance.new("UIGradient")
buttonGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 160, 245))
})
buttonGradient.Rotation = 90
buttonGradient.Parent = closeButton

local isClosing = false

local function closeGui()
    if isClosing then return end
    isClosing = true

    TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = 0 }):Play()
    TweenService:Create(darkOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    
    local fadeOut = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
    local scaleOut = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = UDim2.new(0, 380, 0, 185) })
    local posOut = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0.52, 0) })

    for _, element in pairs(contentFrame:GetChildren()) do
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            TweenService:Create(element, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
        end
    end

    TweenService:Create(accentGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(uiStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Transparency = 1 }):Play()
    TweenService:Create(dotIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()

    fadeOut:Play()
    scaleOut:Play()
    posOut:Play()

    posOut.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

TweenService:Create(blur, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = 8 }):Play()
TweenService:Create(darkOverlay, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = 0.45 }):Play()

local fadeIn = TweenService:Create(mainFrame, tweenInfo, { BackgroundTransparency = 0.3 })
local scaleIn = TweenService:Create(mainContainer, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(0, 420, 0, 210) })
local posIn = TweenService:Create(mainContainer, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) })

mainContainer.Size = UDim2.new(0, 370, 0, 175)
mainContainer.Position = UDim2.new(0.5, 0, 0.52, 0)

local allTextElements = {}
for _, element in pairs(contentFrame:GetChildren()) do
    if element:IsA("TextLabel") or element:IsA("TextButton") then
        table.insert(allTextElements, element)
    end
end
table.insert(allTextElements, titleLabel)
table.insert(allTextElements, dotIndicator)

fadeIn:Play()
scaleIn:Play()
posIn:Play()

for i, element in ipairs(allTextElements) do
    task.delay(i * 0.05, function()
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            TweenService:Create(element, tweenInfo, { TextTransparency = 0 }):Play()
        elseif element.Name =="DotIndicator"then
            TweenService:Create(element, tweenInfo, { BackgroundTransparency = 0 }):Play()
        end
    end)
end

closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.78,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
    TweenService:Create(buttonGradient, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 140, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 180, 255))
        })
    }):Play()
end)

closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.88,
        TextColor3 = Color3.fromRGB(210, 210, 230)
    }):Play()
    TweenService:Create(buttonGradient, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 120, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 160, 245))
        })
    }):Play()
end)

closeButton.MouseButton1Click:Connect(closeGui)
]]

grow_garden = [[
Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existingGui = playerGui:FindFirstChild("UpdateGui")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name ="UpdateGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local blur = Instance.new("BlurEffect")
blur.Name ="BackgroundBlur"
blur.Size = 0
blur.Parent = screenGui

local darkOverlay = Instance.new("Frame")
darkOverlay.Name ="DarkOverlay"
darkOverlay.Size = UDim2.new(1, 0, 1, 0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
darkOverlay.BackgroundTransparency = 1
darkOverlay.BorderSizePixel = 0
darkOverlay.ZIndex = 0
darkOverlay.Parent = screenGui

local mainContainer = Instance.new("Frame")
mainContainer.Name ="MainContainer"
mainContainer.Size = UDim2.new(0, 420, 0, 210)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.BorderSizePixel = 0
mainContainer.ZIndex = 1
mainContainer.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name ="MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 19)
mainFrame.BackgroundTransparency = 1
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 1
mainFrame.Parent = mainContainer

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 255, 255)
uiStroke.Transparency = 0.93
uiStroke.Thickness = 0.5
uiStroke.Parent = mainFrame

local shadow = Instance.new("ImageLabel")
shadow.Name ="Shadow"
shadow.Size = UDim2.new(1, 24, 1, 24)
shadow.Position = UDim2.new(0, -12, 0, -12)
shadow.BackgroundTransparency = 1
shadow.Image ="rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.65
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.ZIndex = 0
shadow.Parent = mainFrame

local accentGlow = Instance.new("Frame")
accentGlow.Name ="AccentGlow"
accentGlow.Size = UDim2.new(0, 4, 1, -20)
accentGlow.Position = UDim2.new(0, 0, 0, 10)
accentGlow.BackgroundColor3 = Color3.fromRGB(140, 120, 255)
accentGlow.BorderSizePixel = 0
accentGlow.ZIndex = 2
accentGlow.Parent = mainFrame

local accentGlowCorner = Instance.new("UICorner")
accentGlowCorner.CornerRadius = UDim.new(1, 0)
accentGlowCorner.Parent = accentGlow

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 180, 255))
})
accentGradient.Rotation = 180
accentGradient.Parent = accentGlow

local contentFrame = Instance.new("Frame")
contentFrame.Name ="ContentFrame"
contentFrame.Size = UDim2.new(1, -32, 1, -28)
contentFrame.Position = UDim2.new(0, 22, 0, 16)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ZIndex = 1
contentFrame.Parent = mainFrame

local headerFrame = Instance.new("Frame")
headerFrame.Name ="HeaderFrame"
headerFrame.Size = UDim2.new(1, 0, 0, 28)
headerFrame.BackgroundTransparency = 1
headerFrame.BorderSizePixel = 0
headerFrame.Parent = contentFrame

local dotIndicator = Instance.new("Frame")
dotIndicator.Name ="DotIndicator"
dotIndicator.Size = UDim2.new(0, 6, 0, 6)
dotIndicator.Position = UDim2.new(0, 0, 0, 4)
dotIndicator.BackgroundColor3 = Color3.fromRGB(140, 120, 255)
dotIndicator.BorderSizePixel = 0
dotIndicator.Parent = headerFrame

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dotIndicator

local titleLabel = Instance.new("TextLabel")
titleLabel.Name ="TitleLabel"
titleLabel.Size = UDim2.new(0, 100, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text ="NOTIFICATION"
titleLabel.TextColor3 = Color3.fromRGB(160, 165, 190)
titleLabel.TextSize = 10
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextTransparency = 1
titleLabel.Parent = headerFrame

local versionLabel = Instance.new("TextLabel")
versionLabel.Name ="VersionLabel"
versionLabel.Size = UDim2.new(1, 0, 0, 30)
versionLabel.Position = UDim2.new(0, 0, 0, 32)
versionLabel.BackgroundTransparency = 1
versionLabel.Text ="Information"
versionLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
versionLabel.TextSize = 22
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.TextTransparency = 1
versionLabel.Parent = contentFrame

local messageLabel = Instance.new("TextLabel")
messageLabel.Name ="MessageLabel"
messageLabel.Size = UDim2.new(1, 0, 0, 72)
messageLabel.Position = UDim2.new(0, 0, 0, 68)
messageLabel.BackgroundTransparency = 1
messageLabel.Text ="Options pas ajouté"
messageLabel.TextColor3 = Color3.fromRGB(135, 140, 165)
messageLabel.TextSize = 12
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.TextWrapped = true
messageLabel.LineHeight = 1.55
messageLabel.TextTransparency = 1
messageLabel.Parent = contentFrame

local divider = Instance.new("Frame")
divider.Name ="Divider"
divider.Size = UDim2.new(1, 0, 0, 1)
divider.Position = UDim2.new(0, 0, 0, 148)
divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider.BackgroundTransparency = 0.95
divider.BorderSizePixel = 0
divider.Parent = contentFrame

local closeButton = Instance.new("TextButton")
closeButton.Name ="CloseButton"
closeButton.Size = UDim2.new(0, 90, 0, 30)
closeButton.Position = UDim2.new(0, 0, 0, 158)
closeButton.BackgroundColor3 = Color3.fromRGB(140, 120, 255)
closeButton.BackgroundTransparency = 0.88
closeButton.BorderSizePixel = 0
closeButton.Text ="Compris"
closeButton.TextColor3 = Color3.fromRGB(210, 210, 230)
closeButton.TextSize = 11
closeButton.Font = Enum.Font.GothamBold
closeButton.TextTransparency = 1
closeButton.AutoButtonColor = false
closeButton.ZIndex = 1
closeButton.Parent = contentFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 5)
buttonCorner.Parent = closeButton

local buttonGradient = Instance.new("UIGradient")
buttonGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 160, 245))
})
buttonGradient.Rotation = 90
buttonGradient.Parent = closeButton

local isClosing = false

local function closeGui()
    if isClosing then return end
    isClosing = true

    TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = 0 }):Play()
    TweenService:Create(darkOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    
    local fadeOut = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
    local scaleOut = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = UDim2.new(0, 380, 0, 185) })
    local posOut = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0.52, 0) })

    for _, element in pairs(contentFrame:GetChildren()) do
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            TweenService:Create(element, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
        end
    end

    TweenService:Create(accentGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(uiStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Transparency = 1 }):Play()
    TweenService:Create(dotIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()

    fadeOut:Play()
    scaleOut:Play()
    posOut:Play()

    posOut.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

TweenService:Create(blur, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = 8 }):Play()
TweenService:Create(darkOverlay, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = 0.45 }):Play()

local fadeIn = TweenService:Create(mainFrame, tweenInfo, { BackgroundTransparency = 0.3 })
local scaleIn = TweenService:Create(mainContainer, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(0, 420, 0, 210) })
local posIn = TweenService:Create(mainContainer, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) })

mainContainer.Size = UDim2.new(0, 370, 0, 175)
mainContainer.Position = UDim2.new(0.5, 0, 0.52, 0)

local allTextElements = {}
for _, element in pairs(contentFrame:GetChildren()) do
    if element:IsA("TextLabel") or element:IsA("TextButton") then
        table.insert(allTextElements, element)
    end
end
table.insert(allTextElements, titleLabel)
table.insert(allTextElements, dotIndicator)

fadeIn:Play()
scaleIn:Play()
posIn:Play()

for i, element in ipairs(allTextElements) do
    task.delay(i * 0.05, function()
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            TweenService:Create(element, tweenInfo, { TextTransparency = 0 }):Play()
        elseif element.Name =="DotIndicator"then
            TweenService:Create(element, tweenInfo, { BackgroundTransparency = 0 }):Play()
        end
    end)
end

closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.78,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
    TweenService:Create(buttonGradient, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 140, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 180, 255))
        })
    }):Play()
end)

closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.88,
        TextColor3 = Color3.fromRGB(210, 210, 230)
    }):Play()
    TweenService:Create(buttonGradient, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 120, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 160, 245))
        })
    }):Play()
end)

closeButton.MouseButton1Click:Connect(closeGui)
]]

tsunami_brainrot = [[
Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existingGui = playerGui:FindFirstChild("UpdateGui")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name ="UpdateGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local blur = Instance.new("BlurEffect")
blur.Name ="BackgroundBlur"
blur.Size = 0
blur.Parent = screenGui

local darkOverlay = Instance.new("Frame")
darkOverlay.Name ="DarkOverlay"
darkOverlay.Size = UDim2.new(1, 0, 1, 0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
darkOverlay.BackgroundTransparency = 1
darkOverlay.BorderSizePixel = 0
darkOverlay.ZIndex = 0
darkOverlay.Parent = screenGui

local mainContainer = Instance.new("Frame")
mainContainer.Name ="MainContainer"
mainContainer.Size = UDim2.new(0, 420, 0, 210)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.BorderSizePixel = 0
mainContainer.ZIndex = 1
mainContainer.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name ="MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 19)
mainFrame.BackgroundTransparency = 1
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 1
mainFrame.Parent = mainContainer

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 255, 255)
uiStroke.Transparency = 0.93
uiStroke.Thickness = 0.5
uiStroke.Parent = mainFrame

local shadow = Instance.new("ImageLabel")
shadow.Name ="Shadow"
shadow.Size = UDim2.new(1, 24, 1, 24)
shadow.Position = UDim2.new(0, -12, 0, -12)
shadow.BackgroundTransparency = 1
shadow.Image ="rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.65
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.ZIndex = 0
shadow.Parent = mainFrame

local accentGlow = Instance.new("Frame")
accentGlow.Name ="AccentGlow"
accentGlow.Size = UDim2.new(0, 4, 1, -20)
accentGlow.Position = UDim2.new(0, 0, 0, 10)
accentGlow.BackgroundColor3 = Color3.fromRGB(140, 120, 255)
accentGlow.BorderSizePixel = 0
accentGlow.ZIndex = 2
accentGlow.Parent = mainFrame

local accentGlowCorner = Instance.new("UICorner")
accentGlowCorner.CornerRadius = UDim.new(1, 0)
accentGlowCorner.Parent = accentGlow

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 180, 255))
})
accentGradient.Rotation = 180
accentGradient.Parent = accentGlow

local contentFrame = Instance.new("Frame")
contentFrame.Name ="ContentFrame"
contentFrame.Size = UDim2.new(1, -32, 1, -28)
contentFrame.Position = UDim2.new(0, 22, 0, 16)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ZIndex = 1
contentFrame.Parent = mainFrame

local headerFrame = Instance.new("Frame")
headerFrame.Name ="HeaderFrame"
headerFrame.Size = UDim2.new(1, 0, 0, 28)
headerFrame.BackgroundTransparency = 1
headerFrame.BorderSizePixel = 0
headerFrame.Parent = contentFrame

local dotIndicator = Instance.new("Frame")
dotIndicator.Name ="DotIndicator"
dotIndicator.Size = UDim2.new(0, 6, 0, 6)
dotIndicator.Position = UDim2.new(0, 0, 0, 4)
dotIndicator.BackgroundColor3 = Color3.fromRGB(140, 120, 255)
dotIndicator.BorderSizePixel = 0
dotIndicator.Parent = headerFrame

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dotIndicator

local titleLabel = Instance.new("TextLabel")
titleLabel.Name ="TitleLabel"
titleLabel.Size = UDim2.new(0, 100, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text ="NOTIFICATION"
titleLabel.TextColor3 = Color3.fromRGB(160, 165, 190)
titleLabel.TextSize = 10
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextTransparency = 1
titleLabel.Parent = headerFrame

local versionLabel = Instance.new("TextLabel")
versionLabel.Name ="VersionLabel"
versionLabel.Size = UDim2.new(1, 0, 0, 30)
versionLabel.Position = UDim2.new(0, 0, 0, 32)
versionLabel.BackgroundTransparency = 1
versionLabel.Text ="Information"
versionLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
versionLabel.TextSize = 22
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.TextTransparency = 1
versionLabel.Parent = contentFrame

local messageLabel = Instance.new("TextLabel")
messageLabel.Name ="MessageLabel"
messageLabel.Size = UDim2.new(1, 0, 0, 72)
messageLabel.Position = UDim2.new(0, 0, 0, 68)
messageLabel.BackgroundTransparency = 1
messageLabel.Text ="Options pas ajouté"
messageLabel.TextColor3 = Color3.fromRGB(135, 140, 165)
messageLabel.TextSize = 12
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.TextWrapped = true
messageLabel.LineHeight = 1.55
messageLabel.TextTransparency = 1
messageLabel.Parent = contentFrame

local divider = Instance.new("Frame")
divider.Name ="Divider"
divider.Size = UDim2.new(1, 0, 0, 1)
divider.Position = UDim2.new(0, 0, 0, 148)
divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider.BackgroundTransparency = 0.95
divider.BorderSizePixel = 0
divider.Parent = contentFrame

local closeButton = Instance.new("TextButton")
closeButton.Name ="CloseButton"
closeButton.Size = UDim2.new(0, 90, 0, 30)
closeButton.Position = UDim2.new(0, 0, 0, 158)
closeButton.BackgroundColor3 = Color3.fromRGB(140, 120, 255)
closeButton.BackgroundTransparency = 0.88
closeButton.BorderSizePixel = 0
closeButton.Text ="Compris"
closeButton.TextColor3 = Color3.fromRGB(210, 210, 230)
closeButton.TextSize = 11
closeButton.Font = Enum.Font.GothamBold
closeButton.TextTransparency = 1
closeButton.AutoButtonColor = false
closeButton.ZIndex = 1
closeButton.Parent = contentFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 5)
buttonCorner.Parent = closeButton

local buttonGradient = Instance.new("UIGradient")
buttonGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 160, 245))
})
buttonGradient.Rotation = 90
buttonGradient.Parent = closeButton

local isClosing = false

local function closeGui()
    if isClosing then return end
    isClosing = true

    TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = 0 }):Play()
    TweenService:Create(darkOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    
    local fadeOut = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
    local scaleOut = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = UDim2.new(0, 380, 0, 185) })
    local posOut = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0.52, 0) })

    for _, element in pairs(contentFrame:GetChildren()) do
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            TweenService:Create(element, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
        end
    end

    TweenService:Create(accentGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(uiStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Transparency = 1 }):Play()
    TweenService:Create(dotIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()

    fadeOut:Play()
    scaleOut:Play()
    posOut:Play()

    posOut.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

TweenService:Create(blur, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = 8 }):Play()
TweenService:Create(darkOverlay, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = 0.45 }):Play()

local fadeIn = TweenService:Create(mainFrame, tweenInfo, { BackgroundTransparency = 0.3 })
local scaleIn = TweenService:Create(mainContainer, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(0, 420, 0, 210) })
local posIn = TweenService:Create(mainContainer, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) })

mainContainer.Size = UDim2.new(0, 370, 0, 175)
mainContainer.Position = UDim2.new(0.5, 0, 0.52, 0)

local allTextElements = {}
for _, element in pairs(contentFrame:GetChildren()) do
    if element:IsA("TextLabel") or element:IsA("TextButton") then
        table.insert(allTextElements, element)
    end
end
table.insert(allTextElements, titleLabel)
table.insert(allTextElements, dotIndicator)

fadeIn:Play()
scaleIn:Play()
posIn:Play()

for i, element in ipairs(allTextElements) do
    task.delay(i * 0.05, function()
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            TweenService:Create(element, tweenInfo, { TextTransparency = 0 }):Play()
        elseif element.Name =="DotIndicator"then
            TweenService:Create(element, tweenInfo, { BackgroundTransparency = 0 }):Play()
        end
    end)
end

closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.78,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
    TweenService:Create(buttonGradient, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 140, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 180, 255))
        })
    }):Play()
end)

closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.88,
        TextColor3 = Color3.fromRGB(210, 210, 230)
    }):Play()
    TweenService:Create(buttonGradient, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 120, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 160, 245))
        })
    }):Play()
end)

closeButton.MouseButton1Click:Connect(closeGui)
]]

V = {}
C = { All = {} }
Cache = { Distances = {}, FPSBoost = {}, Lighting = nil, PostEffects = {} }
ConfigRegistry = {}

Keybinds = {
    Fly = Enum.KeyCode.F,
    Noclip = Enum.KeyCode.V,
    Invisible = Enum.KeyCode.C,
    DesyncFly = Enum.KeyCode.G,
    ESP = Enum.KeyCode.E,
    Speed = Enum.KeyCode.R,
    Respawn = Enum.KeyCode.B,
    Menu = Enum.KeyCode.Insert,
    Freecam = Enum.KeyCode.X,
    VehicleFly = Enum.KeyCode.H,
    VehicleBoost = Enum.KeyCode.T,
    InstantBrake = Enum.KeyCode.N,
    VehicleSeatTP = Enum.KeyCode.J,
    VehicleAutoFlip = Enum.KeyCode.K,
    VehicleExplode = Enum.KeyCode.L,
    VehiclePropulse = Enum.KeyCode.P
}

KeybindCallbacks = {}
KeybindButtons = {}
KeybindSystem = { Binding = false, BindingName = nil, BindingBtn = nil }

V.INVISIBILITY_POSITION = Vector3.new(0, 100000, 0)
V.FOV = 70

DefaultConfig = {
    KeyboardLayout = "AZERTY",
    CurrentTheme = "Violet Void",
    Speed = 16, SpeedEnabled = false, SpeedMethod = "Humanoid", Jump = 50, JumpEnabled = false, 
    WallClimb = false, AutoBhop = false, SuperJumpCharge = false, InfiniteStamina = false,
    Fly = false, FlySpeed = 150, DesyncFly = false, DesyncFlySpeed = 150,
    AntiRagdoll = false, Noclip = false, NoAnim = false, Invis = false, InfJump = false, AntiVoid = false, Godmode = false,
    InstInteract = false, InfRange = false,
    ESP = false, ESPSelf = false, ESPTeamCheck = false, ESPBox = false, ESPFilled = false, ESPName = false, ESPDist = false,
    ESPSkeleton = false, ESPHealth = false, ESPPV = false, ESPWeapon = false, ESPDropped = false, ESPTracerOrigin ="Bottom",
    BulletTracers = false, OffScreenArrows = false, GrappleHook = false, SitAir = false,
    FreecamTPTargetMode = "Ground", FreecamCharVisible = false,
    VehicleSpeed = 1, VehicleFly = false, VehicleFlySpeed = 150, VehicleNoclip = false, VehicleBoost = false, VehicleBoostMode = "Camera", VehicleJumpPower = 80, VehicleAutoJump = true, VehicleExplodeEnabled = false,
    Ghost = false,
    KeybindHUD = false, UITransparency = 3, AccentColor ="Blue", Streamproof = false,
    NebulaChatNotifs = true, RobloxChatNotifs = false,
    ChatTranslator = false, UncensoredChat = false, PlayerJoinLeaveNotifs = false,
    Fullbright = false, FPSBoost = false,
    Force1st = false, Force3rd = false, UnlockZoom = false,
    FOV = 70,
    AntiAFK = false, Notif = true, Watermark = true,
    BubblesEnabled = true, DimmerEnabled = true, DimmerOpacity = 80,
    XRay = false, XRayTransparency = 65, XRayKeepFloor = true, XRayHideDecals = true, XRayStyle = "Murs Propres"
}

function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end
function getHumanoid()
    local char = getCharacter()
    return char:WaitForChild("Humanoid")
end
function getRoot()
    local char = getCharacter()
    return char:WaitForChild("HumanoidRootPart")
end
Players = game:GetService("Players")
RunService = game:GetService("RunService")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")

LocalPlayer = Players.LocalPlayer

local parent = (gethui and gethui()) or game:GetService("CoreGui")

if getgenv().BloxFruitsUILoaded then
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == "BloxFruitsUI" or child.Name == "NebulaUpdateUI" or child.Name == "NebulaFreecamMenu" or child.Name == "NebulaFreecamCrosshair" then
            child:Destroy()
        end
    end
    if V then
        if C and C.All then
            for _, conn in ipairs(C.All) do
                pcall(function() conn:Disconnect() end)
            end
            C.All = {}
        end
        if V.FreecamConn then V.FreecamConn:Disconnect() V.FreecamConn = nil end
        if V.FreecamInputConn then V.FreecamInputConn:Disconnect() V.FreecamInputConn = nil end
        if V.FreecamMenuConn then V.FreecamMenuConn:Disconnect() V.FreecamMenuConn = nil end
        if V.FreecamTeleportConn then V.FreecamTeleportConn:Disconnect() V.FreecamTeleportConn = nil end
        if V.UnifiedInputConn then V.UnifiedInputConn:Disconnect() V.UnifiedInputConn = nil end
        if V.ToggleKeyConn then V.ToggleKeyConn:Disconnect() V.ToggleKeyConn = nil end
        if V.RailHWheelConn then V.RailHWheelConn:Disconnect() V.RailHWheelConn = nil end
        if V.RailHHeartbeatConn then V.RailHHeartbeatConn:Disconnect() V.RailHHeartbeatConn = nil end
        if V.InspectorClickConn then V.InspectorClickConn:Disconnect() V.InspectorClickConn = nil end
        if V.RailFollowConn then V.RailFollowConn:Disconnect() V.RailFollowConn = nil end
        V.RailAttached = nil
        if V.HitboxConn then V.HitboxConn:Disconnect() V.HitboxConn = nil end
        if V.BhopConn then V.BhopConn:Disconnect() V.BhopConn = nil end
        if V.VehicleBoostHoldConn then V.VehicleBoostHoldConn:Disconnect() V.VehicleBoostHoldConn = nil end
        if V.VehicleBoostEndConn then V.VehicleBoostEndConn:Disconnect() V.VehicleBoostEndConn = nil end
        if xrayConn then xrayConn:Disconnect() xrayConn = nil end
        if restoreXRay then
            pcall(restoreXRay)
        else
            if origXRayTransparencies then
                for part, orig in pairs(origXRayTransparencies) do
                    if part and part.Parent then pcall(function() part.Transparency = orig end) end
                end
                origXRayTransparencies = {}
            end
            if origMaterials then
                for part, mat in pairs(origMaterials) do
                    if part and part.Parent then pcall(function() part.Material = mat end) end
                end
                origMaterials = {}
            end
            if origDecalTransparencies then
                for dec, orig in pairs(origDecalTransparencies) do
                    if dec and dec.Parent then pcall(function() dec.Transparency = orig end) end
                end
                origDecalTransparencies = {}
            end
        end
        V.Freecam = false
    end
end
getgenv().BloxFruitsUILoaded = true

theme = {
    text = Color3.fromRGB(235, 235, 242),
    sub = Color3.fromRGB(130, 134, 152),
    panel = Color3.fromRGB(14, 15, 22),
    panel2 = Color3.fromRGB(18, 19, 28),
    card = Color3.fromRGB(23, 24, 35),
    cardHover = Color3.fromRGB(31, 33, 47),
    border = Color3.fromRGB(44, 46, 62),
    accent = Color3.fromRGB(145, 120, 255),
    accent2 = Color3.fromRGB(90, 160, 255),
    danger = Color3.fromRGB(220, 60, 60),
}

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NebulaUpdateUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = parent

function makeCorner(gui, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = gui
    return corner
end

function makeStroke(gui, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or theme.border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = gui
    return stroke
end

function makeGradient(gui, from, to, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, from),
        ColorSequenceKeypoint.new(1, to),
    })
    gradient.Rotation = rotation or 90
    gradient.Parent = gui
    return gradient
end


BackgroundDimmer = Instance.new("Frame")
BackgroundDimmer.Name = "BackgroundDimmer"
BackgroundDimmer.Size = UDim2.new(1, 0, 1, 0)
BackgroundDimmer.Position = UDim2.new(0, 0, 0, 0)
BackgroundDimmer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BackgroundDimmer.BackgroundTransparency = 0.2
BackgroundDimmer.BorderSizePixel = 0
BackgroundDimmer.ZIndex = 1
BackgroundDimmer.Active = false
BackgroundDimmer.Parent = ScreenGui

BubblesContainer = Instance.new("Frame")
BubblesContainer.Name = "BubblesContainer"
BubblesContainer.Size = UDim2.new(1, 0, 1, 0)
BubblesContainer.Position = UDim2.new(0, 0, 0, 0)
BubblesContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BubblesContainer.BackgroundTransparency = 1
BubblesContainer.ClipsDescendants = true
BubblesContainer.ZIndex = 2
BubblesContainer.Active = false
BubblesContainer.Parent = ScreenGui

bubbles = {}
numBubbles = 60

for i = 1, numBubbles do
    local b = Instance.new("Frame")
    local size = math.random(7, 30)
    b.Size = UDim2.new(0, size, 0, size)
    local randCol = math.random()
    if randCol > 0.65 then
        b.BackgroundColor3 = theme.accent
    elseif randCol > 0.35 then
        b.BackgroundColor3 = Color3.fromRGB(175, 145, 255)
    else
        b.BackgroundColor3 = Color3.fromRGB(125, 95, 245)
    end
    b.BackgroundTransparency = math.random(55, 80) / 100
    b.BorderSizePixel = 0
    b.ZIndex = 2
    b.Parent = BubblesContainer
    makeCorner(b, 50)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = math.random(70, 90) / 100
    stroke.Thickness = 1
    stroke.Parent = b

    local bubbleData = {
        frame = b,
        x = math.random(),
        y = math.random(),
        speed = math.random(30, 95) / 1000,
        swaySpeed = math.random(10, 28) / 10,
        swayAmp = math.random(6, 22) / 1000,
        offset = math.random() * math.pi * 2
    }
    b.Position = UDim2.new(bubbleData.x, 0, bubbleData.y, 0)
    table.insert(bubbles, bubbleData)
end

menuSound = nil

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

NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 300, 1, -24)
NotificationContainer.Position = UDim2.new(1, -316, 0, 12)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ZIndex = 50
NotificationContainer.Parent = ScreenGui

NotifLayout = Instance.new("UIListLayout")
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
NotifLayout.Parent = NotificationContainer

initStep = "notify"
function notify(title, text, color)
    if type(title) == "string" then title = string.gsub(title, "<[^>]->", "") end
    if type(text) == "string" then text = string.gsub(text, "<[^>]->", "") end
    color = color or theme.accent

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 300, 0, 56)
    card.Position = UDim2.new(0, 320, 0, 0)
    card.BackgroundColor3 = theme.panel
    card.BackgroundTransparency = 0.04
    card.BorderSizePixel = 0
    card.ZIndex = 51
    card.Parent = NotificationContainer
    makeCorner(card, 10)
    makeStroke(card, theme.border, 1)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 2, 1, 0)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.ZIndex = 52
    bar.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -24, 0, 16)
    titleLabel.Position = UDim2.new(0, 14, 0, 7)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 52
    titleLabel.Parent = card

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -24, 0, 16)
    textLabel.Position = UDim2.new(0, 14, 0, 25)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = theme.sub
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 10
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    textLabel.ZIndex = 52
    textLabel.Parent = card

    TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

    task.delay(3, function()
        pcall(function()
            TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0, 320, 0, 0)}):Play()
        end)
        task.delay(0.3, function()
            pcall(function() card:Destroy() end)
        end)
    end)
end


defaultWindowSize = UDim2.new(0, 780, 0, 530)
defaultWindowPos = UDim2.new(0.5, -390, 0.5, -265)

Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = defaultWindowSize
Panel.Position = defaultWindowPos
Panel.BackgroundColor3 = theme.panel
Panel.BackgroundTransparency = 0
Panel.BorderSizePixel = 0
Panel.ClipsDescendants = true
Panel.Visible = false
Panel.Active = true
Panel.ZIndex = 5
Panel.Parent = ScreenGui
makeCorner(Panel, 14)
makeStroke(Panel, theme.border, 1.2)

PanelScale = Instance.new("UIScale")
PanelScale.Scale = 1
PanelScale.Parent = Panel

BloxFruitsPanel = Panel

Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 195, 1, 0)
Sidebar.Position = UDim2.new(0, 0, 0, 0)
Sidebar.BackgroundColor3 = theme.panel2
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 6
Sidebar.Parent = Panel
makeCorner(Sidebar, 14)

SidebarDivider = Instance.new("Frame")
SidebarDivider.Name = "SidebarDivider"
SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
SidebarDivider.BackgroundColor3 = theme.border
SidebarDivider.BackgroundTransparency = 0.4
SidebarDivider.BorderSizePixel = 0
SidebarDivider.ZIndex = 7
SidebarDivider.Parent = Sidebar

LogoFrame = Instance.new("Frame")
LogoFrame.Name = "LogoFrame"
LogoFrame.Size = UDim2.new(1, 0, 0, 56)
LogoFrame.Position = UDim2.new(0, 0, 0, 0)
LogoFrame.BackgroundTransparency = 1
LogoFrame.ZIndex = 7
LogoFrame.Parent = Sidebar

Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, -20, 0, 24)
Logo.Position = UDim2.new(0, 14, 0, 12)
Logo.BackgroundTransparency = 1
Logo.Text = "NEBULA"
Logo.TextColor3 = theme.accent
Logo.Font = Enum.Font.GothamBlack
Logo.TextSize = 20
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.ZIndex = 8
Logo.Parent = LogoFrame

LogoSub = Instance.new("TextLabel")
LogoSub.Size = UDim2.new(1, -20, 0, 14)
LogoSub.Position = UDim2.new(0, 14, 0, 36)
LogoSub.BackgroundTransparency = 1
LogoSub.Text = "ROBLOX HUB v2.0"
LogoSub.TextColor3 = theme.sub
LogoSub.Font = Enum.Font.Code
LogoSub.TextSize = 9
LogoSub.TextXAlignment = Enum.TextXAlignment.Left
LogoSub.ZIndex = 8
LogoSub.Parent = LogoFrame

LogoSep = Instance.new("Frame")
LogoSep.Size = UDim2.new(1, -20, 0, 1)
LogoSep.Position = UDim2.new(0, 10, 1, -1)
LogoSep.BackgroundColor3 = theme.border
LogoSep.BackgroundTransparency = 0.5
LogoSep.BorderSizePixel = 0
LogoSep.ZIndex = 7
LogoSep.Parent = LogoFrame

NavScroll = Instance.new("ScrollingFrame")
NavScroll.Name = "NavScroll"
NavScroll.Size = UDim2.new(1, -12, 1, -146)
NavScroll.Position = UDim2.new(0, 6, 0, 62)
NavScroll.BackgroundTransparency = 1
NavScroll.BorderSizePixel = 0
NavScroll.ScrollBarThickness = 3
NavScroll.ScrollBarImageColor3 = theme.border
NavScroll.ScrollBarImageTransparency = 0.3
NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
NavScroll.ZIndex = 7
NavScroll.Parent = Sidebar

NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 4)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavScroll

NavPad = Instance.new("UIPadding")
NavPad.PaddingTop = UDim.new(0, 4)
NavPad.PaddingBottom = UDim.new(0, 6)
NavPad.PaddingLeft = UDim.new(0, 2)
NavPad.PaddingRight = UDim.new(0, 4)
NavPad.Parent = NavScroll

AccountBlock = Instance.new("Frame")
AccountBlock.Name = "AccountBlock"
AccountBlock.Size = UDim2.new(1, -12, 0, 68)
AccountBlock.Position = UDim2.new(0, 6, 1, -74)
AccountBlock.BackgroundColor3 = theme.card
AccountBlock.BorderSizePixel = 0
AccountBlock.ZIndex = 7
AccountBlock.Parent = Sidebar
makeCorner(AccountBlock, 10)
makeStroke(AccountBlock, theme.border, 1)

AvatarRing = Instance.new("Frame")
AvatarRing.Name = "AvatarRing"
AvatarRing.Size = UDim2.new(0, 42, 0, 42)
AvatarRing.Position = UDim2.new(0, 8, 0.5, -21)
AvatarRing.BackgroundColor3 = theme.cardHover
AvatarRing.BorderSizePixel = 0
AvatarRing.ZIndex = 8
AvatarRing.Parent = AccountBlock
makeCorner(AvatarRing, 50)
makeStroke(AvatarRing, theme.accent, 1.5, 0.2)

AvatarImage = Instance.new("ImageLabel")
AvatarImage.Name = "AvatarImage"
AvatarImage.Size = UDim2.new(1, -4, 1, -4)
AvatarImage.Position = UDim2.new(0, 2, 0, 2)
AvatarImage.BackgroundTransparency = 1
AvatarImage.BorderSizePixel = 0
AvatarImage.ScaleType = Enum.ScaleType.Crop
AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
AvatarImage.ZIndex = 9
AvatarImage.Parent = AvatarRing
makeCorner(AvatarImage, 50)

pcall(function()
    local thumb = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    if thumb and thumb ~= "" then
        AvatarImage.Image = thumb
    end
end)

AccountName = Instance.new("TextLabel")
AccountName.Name = "AccountName"
AccountName.Size = UDim2.new(1, -62, 0, 16)
AccountName.Position = UDim2.new(0, 56, 0, 14)
AccountName.BackgroundTransparency = 1
AccountName.Text = LocalPlayer.DisplayName or LocalPlayer.Name
AccountName.TextColor3 = theme.text
AccountName.Font = Enum.Font.GothamBold
AccountName.TextSize = 11
AccountName.TextXAlignment = Enum.TextXAlignment.Left
AccountName.TextTruncate = Enum.TextTruncate.AtEnd
AccountName.ZIndex = 8
AccountName.Parent = AccountBlock

AccountUser = Instance.new("TextLabel")
AccountUser.Name = "AccountUser"
AccountUser.Size = UDim2.new(1, -62, 0, 14)
AccountUser.Position = UDim2.new(0, 56, 0, 32)
AccountUser.BackgroundTransparency = 1
AccountUser.Text = "@" .. LocalPlayer.Name
AccountUser.TextColor3 = theme.sub
AccountUser.Font = Enum.Font.Code
AccountUser.TextSize = 9
AccountUser.TextXAlignment = Enum.TextXAlignment.Left
AccountUser.TextTruncate = Enum.TextTruncate.AtEnd
AccountUser.ZIndex = 8
AccountUser.Parent = AccountBlock

StatusDot = Instance.new("Frame")
StatusDot.Name = "StatusDot"
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -14, 0, 8)
StatusDot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 9
StatusDot.Parent = AccountBlock
makeCorner(StatusDot, 50)

PanelHeader = Instance.new("Frame")
PanelHeader.Name = "PanelHeader"
PanelHeader.Size = UDim2.new(1, -195, 0, 44)
PanelHeader.Position = UDim2.new(0, 195, 0, 0)
PanelHeader.BackgroundTransparency = 1
PanelHeader.Active = true
PanelHeader.ZIndex = 8
PanelHeader.Parent = Panel

PanelTitle = Instance.new("TextLabel")
PanelTitle.Size = UDim2.new(0, 175, 1, 0)
PanelTitle.Position = UDim2.new(0, 16, 0, 0)
PanelTitle.BackgroundTransparency = 1
PanelTitle.Text = "MOVEMENT"
PanelTitle.TextColor3 = theme.text
PanelTitle.Font = Enum.Font.GothamBold
PanelTitle.TextSize = 14
PanelTitle.TextXAlignment = Enum.TextXAlignment.Left
PanelTitle.TextTruncate = Enum.TextTruncate.AtEnd
PanelTitle.ZIndex = 9
PanelTitle.Parent = PanelHeader

SearchContainer = Instance.new("Frame")
SearchContainer.Name = "SearchContainer"
SearchContainer.Size = UDim2.new(1, -290, 0, 26)
SearchContainer.Position = UDim2.new(0, 195, 0.5, -13)
SearchContainer.BackgroundColor3 = theme.card
SearchContainer.BorderSizePixel = 0
SearchContainer.ZIndex = 9
SearchContainer.Parent = PanelHeader
makeCorner(SearchContainer, 7)
makeStroke(SearchContainer, theme.border, 1)

SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 24, 1, 0)
SearchIcon.Position = UDim2.new(0, 2, 0, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "🔍"
SearchIcon.TextColor3 = theme.sub
SearchIcon.Font = Enum.Font.Gotham
SearchIcon.TextSize = 11
SearchIcon.ZIndex = 10
SearchIcon.Parent = SearchContainer

SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -50, 1, 0)
SearchBox.Position = UDim2.new(0, 26, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Text = ""
SearchBox.PlaceholderText = "Rechercher une option..."
SearchBox.PlaceholderColor3 = theme.sub
SearchBox.TextColor3 = theme.text
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.TextSize = 11
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 10
SearchBox.Parent = SearchContainer

ClearSearchBtn = Instance.new("TextButton")
ClearSearchBtn.Name = "ClearSearchBtn"
ClearSearchBtn.Size = UDim2.new(0, 20, 0, 20)
ClearSearchBtn.Position = UDim2.new(1, -22, 0.5, -10)
ClearSearchBtn.BackgroundTransparency = 1
ClearSearchBtn.Text = "✕"
ClearSearchBtn.TextColor3 = theme.sub
ClearSearchBtn.Font = Enum.Font.GothamBold
ClearSearchBtn.TextSize = 10
ClearSearchBtn.Visible = false
ClearSearchBtn.ZIndex = 10
ClearSearchBtn.Parent = SearchContainer

MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 26)
MinBtn.Position = UDim2.new(1, -66, 0.5, -13)
MinBtn.BackgroundColor3 = theme.card
MinBtn.BorderSizePixel = 0
MinBtn.Text = "-"
MinBtn.TextColor3 = theme.sub
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.ZIndex = 10
MinBtn.Parent = PanelHeader
makeCorner(MinBtn, 7)
makeStroke(MinBtn, theme.border, 1)

CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = theme.card
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = theme.sub
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.ZIndex = 10
CloseBtn.Parent = PanelHeader
makeCorner(CloseBtn, 7)
makeStroke(CloseBtn, theme.border, 1)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = theme.danger, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = theme.card, TextColor3 = theme.sub}):Play()
end)

HeaderDivider = Instance.new("Frame")
HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
HeaderDivider.Position = UDim2.new(0, 0, 1, -1)
HeaderDivider.BackgroundColor3 = theme.border
HeaderDivider.BackgroundTransparency = 0.5
HeaderDivider.BorderSizePixel = 0
HeaderDivider.ZIndex = 7
HeaderDivider.Parent = PanelHeader

ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -207, 1, -48)
ContentArea.Position = UDim2.new(0, 199, 0, 44)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 6
ContentArea.Parent = Panel

panels = {}
AllRegisteredCards = {}

function registerSearchCard(card, name, parent)
    if card and parent and name then
        local cleanSearchName = string.lower(tostring(name or "")):gsub("<[^>]->", "")
        table.insert(AllRegisteredCards, {
            card = card,
            name = cleanSearchName,
            origParent = parent,
            origOrder = card.LayoutOrder or 0
        })
    end
end

function createPanel(name)
    local panel = Instance.new("ScrollingFrame")
    panel.Name = name
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 3
    panel.ScrollBarImageColor3 = theme.border
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.CanvasSize = UDim2.new(1, 0, 0, 0)
    panel.Visible = false
    panel.ZIndex = 6
    panel.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.Parent = panel

    panels[name] = panel
    return panel
end

SearchPanel = createPanel("Search")

function filterCards(query)
    query = string.lower(tostring(query or "")):match("^%s*(.-)%s*$")
    if not query or query == "" then
        if ClearSearchBtn then ClearSearchBtn.Visible = false end
        for _, item in ipairs(AllRegisteredCards) do
            if item.card and item.card.Parent ~= item.origParent then
                item.card.Parent = item.origParent
                item.card.LayoutOrder = item.origOrder
                item.card.Visible = true
            end
        end
        if SearchPanel then SearchPanel.Visible = false end
        if switchCategory then switchCategory(currentCategory) end
    else
        if ClearSearchBtn then ClearSearchBtn.Visible = true end
        for name, panel in pairs(panels) do
            if name ~= "Search" then
                panel.Visible = false
            end
        end
        if SearchPanel then
            SearchPanel.Visible = true
            SearchPanel.Position = UDim2.new(0, 0, 0, 0)
        end

        local matchCount = 0
        for _, item in ipairs(AllRegisteredCards) do
            if item.card then
                if string.find(item.name, query, 1, true) then
                    item.card.Parent = SearchPanel
                    item.card.Visible = true
                    matchCount = matchCount + 1
                else
                    if item.card.Parent == SearchPanel then
                        item.card.Parent = item.origParent
                        item.card.LayoutOrder = item.origOrder
                    end
                end
            end
        end
        if matchCount == 0 then
            PanelTitle.Text = "AUCUN RÉSULTAT"
        else
            PanelTitle.Text = "RÉSULTATS (" .. matchCount .. ")"
        end
    end
end

if SearchBox then
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        filterCards(SearchBox.Text)
    end)
end

if ClearSearchBtn then
    ClearSearchBtn.MouseButton1Click:Connect(function()
        SearchBox.Text = ""
        filterCards("")
    end)
end

function createCard(parent, order, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height or 46)
    card.BackgroundColor3 = theme.card
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 0
    card.ZIndex = 7
    card.Parent = parent
    makeCorner(card, 10)
    makeStroke(card, theme.border, 1)

    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = theme.cardHover}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = theme.card}):Play()
    end)

    return card
end

function createSectionHeader(parent, title, order)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundTransparency = 1
    header.LayoutOrder = order or 0
    header.ZIndex = 7
    header.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = title:upper()
    lbl.TextColor3 = theme.accent
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 8
    lbl.Parent = header

    return header
end

function setToggleBtn(btn, value)
    if not btn then return end
    btn.Text = value and "ON" or "OFF"
    TweenService:Create(btn, TweenInfo.new(0.15), {
        BackgroundColor3 = value and theme.accent or theme.cardHover,
        TextColor3 = value and Color3.fromRGB(255, 255, 255) or theme.sub,
    }):Play()
end

function createToggleCard(parent, text, subtext, order, getter, setter)
    local card = createCard(parent, order, subtext and 54 or 44)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 16)
    title.Position = UDim2.new(0, 12, 0, subtext and 6 or 14)
    title.BackgroundTransparency = 1
    title.Text = text
    title.TextColor3 = theme.text
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 8
    title.Parent = card

    if subtext then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -80, 0, 13)
        sub.Position = UDim2.new(0, 12, 0, 24)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextColor3 = theme.sub
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 9
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.ZIndex = 8
        sub.Parent = card
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 58, 0, 28)
    btn.Position = UDim2.new(1, -70, 0.5, -14)
    btn.BackgroundColor3 = theme.cardHover
    btn.BorderSizePixel = 0
    btn.Text = "OFF"
    btn.TextColor3 = theme.sub
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.ZIndex = 9
    btn.Parent = card
    makeCorner(btn, 9)
    makeStroke(btn, theme.border, 1)

    btn.MouseButton1Click:Connect(function()
        playClick()
        local newVal = not getter()
        setter(newVal)
        setToggleBtn(btn, newVal)
        notify(text, newVal and "Activé" or "Désactivé", newVal and theme.accent or theme.danger)
    end)

    setToggleBtn(btn, getter())

    registerSearchCard(card, text, parent)

    return card, btn
end

categories = {
    { key = "Movement", title = "Movement" },
    { key = "Me", title = "Me" },
    { key = "Protection", title = "Protection" },
    { key = "ESP", title = "ESP" },
    { key = "Aim", title = "Aim" },
    { key = "Teleport", title = "Teleport" },
    { key = "Joueur", title = "Joueur" },
    { key = "Server", title = "Server" },
    { key = "Vehicle", title = "Vehicle" },
    { key = "Fun", title = "Fun" },
    { key = "Scripts", title = "Scripts" },
    { key = "Settings", title = "Settings" },
    { key = "Config", title = "Config" },
    { key = "Code", title = "Code" },
}

minimized = false
panelPos = defaultWindowPos
local setMinimized = nil
currentCategory = "Movement"
railButtons = {}

function switchCategory(key)
    currentCategory = key
    if SearchBox and SearchBox.Text ~= "" then
        SearchBox.Text = ""
        if ClearSearchBtn then ClearSearchBtn.Visible = false end
        for _, item in ipairs(AllRegisteredCards) do
            if item.card and item.card.Parent ~= item.origParent then
                item.card.Parent = item.origParent
                item.card.LayoutOrder = item.origOrder
                item.card.Visible = true
            end
        end
        if SearchPanel then SearchPanel.Visible = false end
    end
    for name, panel in pairs(panels) do
        if name == key then
            panel.Visible = true
            panel.Position = UDim2.new(0, 14, 0, 0)
            TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
            if key == "Joueur" and _G.refreshPlayerList then
                pcall(_G.refreshPlayerList)
            end
        else
            panel.Visible = false
        end
    end
    for _, cat in ipairs(categories) do
        local data = railButtons[cat.key]
        if data then
            local isActive = cat.key == key
            TweenService:Create(data.btn, TweenInfo.new(0.2), {
                BackgroundColor3 = isActive and theme.accent or Color3.fromRGB(24, 25, 36),
                TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or theme.sub,
            }):Play()
            if data.accent then
                data.accent.Visible = isActive
            end
        end
    end
    for _, cat in ipairs(categories) do
        if cat.key == key then
            PanelTitle.Text = cat.title
            break
        end
    end
end

function createCategoryButton(cat, index, parentContainer)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = (cat.key == currentCategory) and theme.accent or Color3.fromRGB(24, 25, 36)
    btn.BorderSizePixel = 0
    btn.Text = cat.title
    btn.TextColor3 = (cat.key == currentCategory) and Color3.fromRGB(255, 255, 255) or theme.sub
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = index
    btn.ZIndex = 8
    btn.Parent = parentContainer
    makeCorner(btn, 8)
    makeStroke(btn, theme.border, 1, 0.5)

    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft = UDim.new(0, 14)
    btnPad.Parent = btn

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 0.6, 0)
    accentBar.Position = UDim2.new(0, -10, 0.2, 0)
    accentBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    accentBar.BorderSizePixel = 0
    accentBar.Visible = (cat.key == currentCategory)
    accentBar.ZIndex = 9
    accentBar.Parent = btn
    makeCorner(accentBar, 2)

    local scale = Instance.new("UIScale")
    scale.Parent = btn

    btn.MouseEnter:Connect(function()
        if cat.key ~= currentCategory then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = theme.cardHover, TextColor3 = theme.text}):Play()
        end
        TweenService:Create(scale, TweenInfo.new(0.15), {Scale = 1.02}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if cat.key ~= currentCategory then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(24, 25, 36), TextColor3 = theme.sub}):Play()
        end
        TweenService:Create(scale, TweenInfo.new(0.15), {Scale = 1}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        playClick()
        if minimized then
            setMinimized(false)
        end
        switchCategory(cat.key)
    end)

    railButtons[cat.key] = { btn = btn, accent = accentBar, index = index }
    return btn
end

for index, cat in ipairs(categories) do
    createCategoryButton(cat, index, NavScroll)
    createPanel(cat.key)
end

ThemePalettes = {
    ["Cyan Neon"] = {
        name = "Cyan Neon",
        accent = Color3.fromRGB(0, 230, 255),
        accent2 = Color3.fromRGB(80, 180, 255),
        border = Color3.fromRGB(25, 65, 85),
        card = Color3.fromRGB(18, 24, 32),
        cardHover = Color3.fromRGB(24, 34, 46)
    },
    ["Crimson Blood"] = {
        name = "Crimson Blood",
        accent = Color3.fromRGB(255, 45, 75),
        accent2 = Color3.fromRGB(255, 95, 115),
        border = Color3.fromRGB(75, 25, 35),
        card = Color3.fromRGB(28, 18, 22),
        cardHover = Color3.fromRGB(40, 24, 30)
    },
    ["Emerald"] = {
        name = "Emerald",
        accent = Color3.fromRGB(34, 215, 120),
        accent2 = Color3.fromRGB(50, 240, 160),
        border = Color3.fromRGB(22, 65, 40),
        card = Color3.fromRGB(18, 26, 22),
        cardHover = Color3.fromRGB(24, 38, 30)
    },
    ["Ambre"] = {
        name = "Ambre",
        accent = Color3.fromRGB(255, 170, 35),
        accent2 = Color3.fromRGB(255, 205, 70),
        border = Color3.fromRGB(75, 50, 20),
        card = Color3.fromRGB(28, 22, 16),
        cardHover = Color3.fromRGB(42, 32, 22)
    },
    ["Violet Void"] = {
        name = "Violet Void",
        accent = Color3.fromRGB(145, 120, 255),
        accent2 = Color3.fromRGB(180, 150, 255),
        border = Color3.fromRGB(50, 42, 70),
        card = Color3.fromRGB(23, 24, 35),
        cardHover = Color3.fromRGB(31, 33, 47)
    }
}

function applyThemePalette(pName)
    local p = ThemePalettes[pName]
    if not p then return end
    theme.accent = p.accent
    theme.accent2 = p.accent2
    theme.border = p.border
    if p.card then theme.card = p.card end
    if p.cardHover then theme.cardHover = p.cardHover end
    V.CurrentTheme = pName
    V.AccentColor = p.accent

    if PanelTitle then PanelTitle.TextColor3 = p.accent end
    if Logo then Logo.TextColor3 = p.accent end
    if AvatarRing and AvatarRing:FindFirstChild("UIStroke") then
        AvatarRing.UIStroke.Color = p.accent
    end
    if Panel and Panel:FindFirstChild("UIStroke") then
        Panel.UIStroke.Color = p.border
    end
    if Sidebar and Sidebar:FindFirstChild("SidebarDivider") then
        Sidebar.SidebarDivider.BackgroundColor3 = p.border
    end
    local data = railButtons[currentCategory]
    if data and data.btn then
        data.btn.BackgroundColor3 = p.accent
    end
    notify("Theme", "Palette appliquée : " .. pName, p.accent)
end

function setAccentColor(col)
    theme.accent = col
    PanelTitle.TextColor3 = col
    Logo.TextColor3 = col
    if AvatarRing and AvatarRing:FindFirstChild("UIStroke") then
        AvatarRing.UIStroke.Color = col
    end
    local data = railButtons[currentCategory]
    if data and data.btn then
        data.btn.BackgroundColor3 = col
    end
end

ContentFrames = {}
for _, cat in ipairs(categories) do
    local panel = panels[cat.key]
    ContentFrames[cat.key] = panel
end

activeNSlider = nil

function createToggle(name, default, callback, parent, configKey)
    local card = createCard(parent, 0, 44)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 16)
    title.Position = UDim2.new(0, 12, 0, 14)
    title.BackgroundTransparency = 1
    title.RichText = true
    title.Text = name
    title.TextColor3 = theme.text
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 8
    title.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 52, 0, 24)
    btn.Position = UDim2.new(1, -62, 0.5, -12)
    btn.BackgroundColor3 = theme.cardHover
    btn.BorderSizePixel = 0
    btn.Text = "OFF"
    btn.TextColor3 = theme.sub
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.ZIndex = 9
    btn.Parent = card
    makeCorner(btn, 8)
    makeStroke(btn, theme.border, 1)

    local enabled = default or false
    if configKey then
        if V[configKey] ~= nil then
            enabled = (V[configKey] == true)
        else
            V[configKey] = enabled
        end
    end
    setToggleBtn(btn, enabled)

    local function setToggleState(value)
        enabled = (value == true)
        if configKey then
            V[configKey] = enabled
        end
        setToggleBtn(btn, enabled)
        pcall(callback, enabled)
    end

    local function toggleState()
        setToggleState(not enabled)
    end

    btn.MouseButton1Click:Connect(function()
        pcall(function() game:GetService("GuiService").SelectedObject = nil end)
        playClick()
        toggleState()
    end)

    if configKey then
        ConfigRegistry[configKey] = setToggleState
    end

    registerSearchCard(card, name, parent)

    return card, setToggleState, toggleState
end

function createSlider(name, min, max, default, callback, parent, configKey)
    local card = createCard(parent, 0, 52)

    if configKey then
        if V[configKey] ~= nil and type(V[configKey]) == "number" then
            default = V[configKey]
        else
            V[configKey] = default
        end
    end

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.6, -10, 0, 16)
    title.Position = UDim2.new(0, 12, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = theme.text
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 8
    title.Parent = card

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 40, 0, 16)
    valLbl.Position = UDim2.new(1, -52, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = theme.accent2
    valLbl.Font = Enum.Font.Code
    valLbl.TextSize = 10
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.ZIndex = 8
    valLbl.Parent = card

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 4)
    track.Position = UDim2.new(0, 12, 0, 38)
    track.BackgroundColor3 = theme.cardHover
    track.BorderSizePixel = 0
    track.ZIndex = 8
    track.Parent = card
    makeCorner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = theme.accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 9
    fill.Parent = track
    makeCorner(fill, 2)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 10, 0, 10)
    thumb.Position = UDim2.new((default - min) / (max - min), -5, 0.5, -5)
    thumb.BackgroundColor3 = theme.text
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 10
    thumb.Parent = track
    makeCorner(thumb, 5)

    local function updateFromX(x)
        local trackPos = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        if trackWidth <= 0 then return end
        local pct = math.clamp((x - trackPos) / trackWidth, 0, 1)
        local value = math.floor(min + pct * (max - min))
        valLbl.Text = tostring(value)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -5, 0.5, -5)
        if configKey then
            V[configKey] = value
        end
        pcall(callback, value)
    end

    local function setSliderValue(value)
        value = math.clamp(value, min, max)
        if configKey then
            V[configKey] = value
        end
        local pct = (value - min) / (max - min)
        valLbl.Text = tostring(value)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -5, 0.5, -5)
        pcall(callback, value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeNSlider = updateFromX
            updateFromX(input.Position.X)
        end
    end)
    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeNSlider = updateFromX
            updateFromX(input.Position.X)
        end
    end)

    if configKey then
        ConfigRegistry[configKey] = setSliderValue
    end

    registerSearchCard(card, name, parent)

    return card, setSliderValue
end

function createButton(name, callback, parent, customBtnText, isDanger)
    local card = createCard(parent, 0, 42)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 16)
    title.Position = UDim2.new(0, 12, 0, 13)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = theme.text
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 8
    title.Parent = card

    local isUnload = isDanger or (string.find(string.lower(name), "unload") ~= nil) or (customBtnText and string.lower(customBtnText) == "unload")
    local btnLabel = customBtnText or (isUnload and "Unload" or "Lancer")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 64, 0, 24)
    btn.Position = UDim2.new(1, -74, 0.5, -12)
    btn.BackgroundColor3 = isUnload and Color3.fromRGB(42, 18, 22) or theme.cardHover
    btn.BorderSizePixel = 0
    btn.Text = btnLabel
    btn.TextColor3 = isUnload and Color3.fromRGB(255, 75, 75) or theme.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.ZIndex = 9
    btn.Parent = card
    makeCorner(btn, 7)
    makeStroke(btn, isUnload and Color3.fromRGB(150, 35, 45) or theme.border, 1)

    btn.MouseEnter:Connect(function()
        if isUnload then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(215, 45, 55), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = theme.accent, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if isUnload then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(42, 18, 22), TextColor3 = Color3.fromRGB(255, 75, 75)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = theme.cardHover, TextColor3 = theme.text}):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        pcall(function() game:GetService("GuiService").SelectedObject = nil end)
        playClick()
        if callback then
            pcall(callback)
        end
    end)

    registerSearchCard(card, name, parent)

    return card, btn
end

function createLabel(text, parent)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 22)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(120, 120, 132)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 9
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 8
    Label.Parent = parent
    return Label
end

nSliderMoveConn = UserInputService.InputChanged:Connect(function(input)
    if activeNSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        activeNSlider(input.Position.X)
    end
end)
nSliderEndConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        activeNSlider = nil
    end
end)



savedWindowSize = defaultWindowSize
savedWindowPos = defaultWindowPos
menuOpen = true
isTogglingMenu = false

function toggleMenu(forceState)
    if not isKeyVerified and not _G.isKeyVerified then
        pcall(function() notify("Nebula", "Veuillez entrer une clé valide !", theme.danger) end)
        return
    end
    if isTogglingMenu then return end
    isTogglingMenu = true
    task.delay(0.25, function() isTogglingMenu = false end)

    if forceState ~= nil then
        menuOpen = forceState
    else
        menuOpen = not menuOpen
    end

    if menuOpen then
        minimized = false
        Panel.Visible = true
        Sidebar.Visible = true
        ContentArea.Visible = true
        PanelHeader.Size = UDim2.new(1, -195, 0, 44)
        PanelHeader.Position = UDim2.new(0, 195, 0, 0)
        PanelTitle.Text = currentCategory

        if V and V.BubblesEnabled then
            BubblesContainer.Visible = true
            BubblesContainer.BackgroundTransparency = 1
        else
            BubblesContainer.Visible = false
        end

        if V and V.DimmerEnabled then
            local targetTrans = 1 - ((V.DimmerOpacity or 80) / 100)
            BackgroundDimmer.Visible = true
            BackgroundDimmer.BackgroundTransparency = 1
            TweenService:Create(BackgroundDimmer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = targetTrans}):Play()
        else
            BackgroundDimmer.Visible = false
        end

        local restorePos = savedWindowPos or defaultWindowPos
        local restoreSize = savedWindowSize or defaultWindowSize
        Panel.Size = restoreSize
        Panel.Position = restorePos + UDim2.new(0, 0, 0, 16)
        PanelScale.Scale = 0.88
        TweenService:Create(PanelScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = restorePos
        }):Play()
    else
        minimized = false
        if BackgroundDimmer and BackgroundDimmer.Visible then
            TweenService:Create(BackgroundDimmer, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
        end
        TweenService:Create(PanelScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.85}):Play()
        TweenService:Create(Panel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = (savedWindowPos or defaultWindowPos) + UDim2.new(0, 0, 0, 16)
        }):Play()
        task.delay(0.2, function()
            if not menuOpen then
                Panel.Visible = false
                BubblesContainer.Visible = false
                BackgroundDimmer.Visible = false
            end
        end)
    end
end
_G.toggleNebulaMenu = toggleMenu

setMinimized = function(value)
    minimized = value
    if value then
        savedWindowSize = Panel.Size
        savedWindowPos = Panel.Position
        Sidebar.Visible = false
        ContentArea.Visible = false
        PanelHeader.Size = UDim2.new(1, 0, 1, 0)
        PanelHeader.Position = UDim2.new(0, 0, 0, 0)
        PanelTitle.Text = "NEBULA  |  " .. currentCategory

        BubblesContainer.Visible = false
        if BackgroundDimmer and BackgroundDimmer.Visible then
            TweenService:Create(BackgroundDimmer, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        end
        task.delay(0.2, function()
            if minimized then
                BackgroundDimmer.Visible = false
            end
        end)
        TweenService:Create(PanelScale, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(Panel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 230, 0, 44),
            Position = UDim2.new(0.5, -115, 1, -56)
        }):Play()
    else
        PanelHeader.Size = UDim2.new(1, -195, 0, 44)
        PanelHeader.Position = UDim2.new(0, 195, 0, 0)
        PanelTitle.Text = currentCategory
        Sidebar.Visible = true
        ContentArea.Visible = true

        if V and V.BubblesEnabled then
            BubblesContainer.Visible = true
            BubblesContainer.BackgroundTransparency = 1
        else
            BubblesContainer.Visible = false
        end

        if V and V.DimmerEnabled then
            local targetTrans = 1 - ((V.DimmerOpacity or 80) / 100)
            BackgroundDimmer.Visible = true
            BackgroundDimmer.BackgroundTransparency = 1
            TweenService:Create(BackgroundDimmer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = targetTrans}):Play()
        else
            BackgroundDimmer.Visible = false
        end

        local restorePos = savedWindowPos or defaultWindowPos
        local restoreSize = savedWindowSize or defaultWindowSize
        PanelScale.Scale = 0.92
        TweenService:Create(PanelScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(Panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = restoreSize,
            Position = restorePos
        }):Play()
    end
end

MinBtn.MouseButton1Click:Connect(function()
    playClick()
    setMinimized(not minimized)
end)
MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {BackgroundColor3 = theme.accent, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {BackgroundColor3 = theme.card, TextColor3 = theme.sub}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
    playClick()
    toggleMenu(false)
end)

bubbleRenderConn = RunService.RenderStepped:Connect(function(dt)
    if (menuOpen and not minimized and Panel.Visible) or (not isKeyVerified) then
        local t = tick()
        for _, b in ipairs(bubbles) do
            b.y = b.y + b.speed * dt
            if b.y > 1.05 then
                b.y = -0.05
                b.x = math.random()
            end
            local curX = b.x + math.sin(t * b.swaySpeed + b.offset) * b.swayAmp
            b.frame.Position = UDim2.new(curX, 0, b.y, 0)
        end
    end
end)

dragging = false
dragInput, dragStart, startPos = nil, nil, nil

function updateDrag(input)
    local delta = input.Position - dragStart
    Panel.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
    if not minimized then
        savedWindowPos = Panel.Position
    end
end

function enableDrag(frame)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Panel.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
end

enableDrag(PanelHeader)
enableDrag(LogoFrame)

dragConn = UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size = UDim2.new(0, 24, 0, 24)
ResizeHandle.Position = UDim2.new(1, -26, 1, -26)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.BorderSizePixel = 0
ResizeHandle.Text = ""
ResizeHandle.ZIndex = 15
ResizeHandle.Parent = Panel

resizing = false

ResizeHandle.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not minimized then
        resizing = true
    end
end)
resizeChangedConn = UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local newWidth = math.max(620, input.Position.X - Panel.AbsolutePosition.X)
        local newHeight = math.max(420, input.Position.Y - Panel.AbsolutePosition.Y)
        Panel.Size = UDim2.new(0, newWidth, 0, newHeight)
        savedWindowSize = Panel.Size
    end
end)
resizeEndedConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

function performFullUnload()
    pcall(function() RunService:UnbindFromRenderStep("NebulaAimlock") end)
    pcall(function() RunService:UnbindFromRenderStep("NebulaFreecam") end)

    _G.Aimlock_Enabled = false
    _G.Aimlock_IsHeld = false
    _G.Aimlock_ShowFOV = false
    if _G.NebulaAimlockConn then pcall(function() _G.NebulaAimlockConn:Disconnect() _G.NebulaAimlockConn = nil end) end
    if _G.NebulaAimlockInputBeganConn then pcall(function() _G.NebulaAimlockInputBeganConn:Disconnect() _G.NebulaAimlockInputBeganConn = nil end) end
    if _G.NebulaAimlockInputEndedConn then pcall(function() _G.NebulaAimlockInputEndedConn:Disconnect() _G.NebulaAimlockInputEndedConn = nil end) end
    if SilentAimCircle then
        pcall(function()
            SilentAimCircle.Visible = false
            if SilentAimCircle.Remove then SilentAimCircle:Remove()
            elseif SilentAimCircle.Destroy then SilentAimCircle:Destroy() end
            SilentAimCircle = nil
        end)
    end

    pcall(function()
        if V then
            if V.Fly and stopFly then pcall(stopFly) end
            if V.DesyncFly and stopDesyncFly then pcall(stopDesyncFly) end
            if V.Noclip and stopNoclip then pcall(stopNoclip) end
            if V.Invis and toggleInvisibility then pcall(function() toggleInvisibility(false) end) end
            if V.NoAnim and disableNoAnim then pcall(disableNoAnim) end
            if V.Flinging and stopFling then pcall(stopFling) end
            if V.Spectate and stopSpectate then pcall(stopSpectate) end
            if V.InfRange and toggleInfiniteRange then pcall(function() toggleInfiniteRange(false) end) end
            if V.FPSBoost and toggleFPSBooster then pcall(function() toggleFPSBooster(false) end) end
            if V.Fullbright and toggleFullbright then pcall(function() toggleFullbright(false) end) end
            if V.ClickTP and toggleClickTP then pcall(function() toggleClickTP(false) end) end
            if V.Godmode and toggleGodmode then pcall(function() toggleGodmode(false) end) end
            if V.Ghost and toggleGhost then pcall(function() toggleGhost(false) end) end
            if V.Freecam and SetFreecamToggle then pcall(function() SetFreecamToggle(false) end) end
            V.Fly = false
            V.DesyncFly = false
            V.Noclip = false
            V.Invis = false
            V.NoAnim = false
            V.Flinging = false
            V.Spectate = false
            V.InfRange = false
            V.FPSBoost = false
            V.Fullbright = false
            V.ClickTP = false
            V.Godmode = false
            V.Ghost = false
            V.Freecam = false
            V.Force3rd = false
            V.HitboxExtender = false
            V.AutoBhop = false
            V.InfiniteStamina = false
            V.AntiVoid = false
            V.AntiRagdoll = false
            V.AntiFling = false
            V.SpeedEnabled = false
            V.JumpEnabled = false
            V.CFrameSpeed = false
            V.VehicleFly = false
            V.VehicleNoclip = false
        end
    end)

    pcall(function()
        if godmodeCharConn then godmodeCharConn:Disconnect(); godmodeCharConn = nil end
        if godmodeHealthConn then godmodeHealthConn:Disconnect(); godmodeHealthConn = nil end
        if godmodeStateConn then godmodeStateConn:Disconnect(); godmodeStateConn = nil end
        if V and V.GodmodeConn then V.GodmodeConn:Disconnect(); V.GodmodeConn = nil end
        if V and V.GhostConn then V.GhostConn:Disconnect(); V.GhostConn = nil end
        if V and V.SuperJumpConn then V.SuperJumpConn:Disconnect(); V.SuperJumpConn = nil end
        if V and V.OffScreenConn then V.OffScreenConn:Disconnect(); V.OffScreenConn = nil end
        if V and V.SitAirConn then V.SitAirConn:Disconnect(); V.SitAirConn = nil end
        if V and V.GrappleTool then
            if V.GrappleTool.Parent == LocalPlayer.Character or V.GrappleTool.Parent == LocalPlayer.Backpack then
                V.GrappleTool:Destroy()
            end
            V.GrappleTool = nil
        end
        if cleanupOffScreenArrows then cleanupOffScreenArrows() end
        if V and V.Force3rdConn then V.Force3rdConn:Disconnect(); V.Force3rdConn = nil end
        if V and V.FlyNoclipConn then V.FlyNoclipConn:Disconnect(); V.FlyNoclipConn = nil end
        if V and V.DesyncFlyNoclipConn then V.DesyncFlyNoclipConn:Disconnect(); V.DesyncFlyNoclipConn = nil end
        if V and V.FreecamConn then V.FreecamConn:Disconnect(); V.FreecamConn = nil end
        if V and V.FreecamInputConn then V.FreecamInputConn:Disconnect(); V.FreecamInputConn = nil end
        if V and V.FreecamMenuConn then V.FreecamMenuConn:Disconnect(); V.FreecamMenuConn = nil end
        if V and V.FreecamTeleportConn then V.FreecamTeleportConn:Disconnect(); V.FreecamTeleportConn = nil end
        if V and V.FreecamTeleportConnEnd then V.FreecamTeleportConnEnd:Disconnect(); V.FreecamTeleportConnEnd = nil end
        if V and V.InvisConn then V.InvisConn:Disconnect(); V.InvisConn = nil end
        if V and V.NoAnimConn then V.NoAnimConn:Disconnect(); V.NoAnimConn = nil end
        if V and V.SpecConn then V.SpecConn:Disconnect(); V.SpecConn = nil end
        if V and V.FlingConn then V.FlingConn:Disconnect(); V.FlingConn = nil end
        if V and V.AntiRagdollConn then V.AntiRagdollConn:Disconnect(); V.AntiRagdollConn = nil end
        if V and V.AntiFlingConn then V.AntiFlingConn:Disconnect(); V.AntiFlingConn = nil end
        if V and V.AntiVoidConn then V.AntiVoidConn:Disconnect(); V.AntiVoidConn = nil end
        if setupInfiniteStamina then pcall(function() setupInfiniteStamina(false) end) end
        if V and V.InfiniteStaminaConn then V.InfiniteStaminaConn:Disconnect(); V.InfiniteStaminaConn = nil end
        if disconnectRobloxChat then pcall(disconnectRobloxChat) end
        if V and V.HitboxConn then V.HitboxConn:Disconnect(); V.HitboxConn = nil end
        if V and V.BhopConn then V.BhopConn:Disconnect(); V.BhopConn = nil end
        if V and V.AttachConn then V.AttachConn:Disconnect(); V.AttachConn = nil end
        if V and V.SpinConn then V.SpinConn:Disconnect(); V.SpinConn = nil end
        if V and V.InfRangeConn then V.InfRangeConn:Disconnect(); V.InfRangeConn = nil end
        if V and V.FPSConn then V.FPSConn:Disconnect(); V.FPSConn = nil end
        if V and V.AutoRejoinConn then V.AutoRejoinConn:Disconnect(); V.AutoRejoinConn = nil end
                if V and V.UnifiedInputConn then V.UnifiedInputConn:Disconnect(); V.UnifiedInputConn = nil end
        if V and V.InspectorClickConn then V.InspectorClickConn:Disconnect(); V.InspectorClickConn = nil end
        if V and V.VehicleBoostHoldConn then V.VehicleBoostHoldConn:Disconnect(); V.VehicleBoostHoldConn = nil end
        if V and V.VehicleBoostEndConn then V.VehicleBoostEndConn:Disconnect(); V.VehicleBoostEndConn = nil end
        if movementConn then movementConn:Disconnect(); movementConn = nil end
        if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
        if bubbleRenderConn then bubbleRenderConn:Disconnect(); bubbleRenderConn = nil end
        if dragConn then dragConn:Disconnect(); dragConn = nil end
        if resizeChangedConn then resizeChangedConn:Disconnect(); resizeChangedConn = nil end
        if resizeEndedConn then resizeEndedConn:Disconnect(); resizeEndedConn = nil end
        if nSliderMoveConn then nSliderMoveConn:Disconnect(); nSliderMoveConn = nil end
        if nSliderEndConn then nSliderEndConn:Disconnect(); nSliderEndConn = nil end

        if _G.NebulaAimlockConn then _G.NebulaAimlockConn:Disconnect(); _G.NebulaAimlockConn = nil end
        if _G.NebulaAimlockInputBeganConn then _G.NebulaAimlockInputBeganConn:Disconnect(); _G.NebulaAimlockInputBeganConn = nil end
        if _G.NebulaAimlockInputEndedConn then _G.NebulaAimlockInputEndedConn:Disconnect(); _G.NebulaAimlockInputEndedConn = nil end
        _G.Aimlock_Enabled = false
        _G.Aimlock_IsHeld = false
        if SilentAimCircle then
            pcall(function()
                SilentAimCircle.Visible = false
                SilentAimCircle:Remove()
            end)
            SilentAimCircle = nil
        end
        if ArrowGui then pcall(function() ArrowGui:Destroy() end) end
        if cleanupArrowESP then cleanupArrowESP() end

        for _, conn in pairs(C and C.All or {}) do
            pcall(function() conn:Disconnect() end)
        end
        if C then C.All = {} end
        for _, conn in pairs(V and V.Connections or {}) do
            pcall(function() conn:Disconnect() end)
        end
        if V then V.Connections = {} end
    end)

    pcall(function()
        if V then V.ESP = false end
        if clearESP then clearESP() end
        if ClearESP then ClearESP() end
        if ESPGui then ESPGui:Destroy() end
    end)

    pcall(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.CanCollide = false
                end
                for _, desc in pairs(p.Character:GetDescendants()) do
                    if desc:IsA("Highlight") or desc:IsA("SelectionBox") or desc:IsA("BoxHandleAdornment") then
                        desc:Destroy()
                    end
                end
            end
        end
    end)

    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum.AutoRotate = true
                hum.Sit = false
                if V and V.SpeedEnabled then
                    hum.WalkSpeed = _OrigWalkSpeed or 16
                end
                if V and V.JumpEnabled then
                    hum.JumpPower = 50
                end
                hum.RequiresNeck = true
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = false
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
                for _, obj in pairs(hrp:GetChildren()) do
                    if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("LinearVelocity") or obj:IsA("VectorForce") or obj:IsA("BodyAngularVelocity") then
                        obj:Destroy()
                    end
                end
            end
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                    if part.Name == "HumanoidRootPart" then
                        part.Transparency = 1
                        part.CanCollide = false
                    end
                end
            end
        end
    end)

    pcall(function()
        workspace.Gravity = 196.2
        if Camera then
            Camera.FieldOfView = 70
            Camera.CameraType = Enum.CameraType.Custom
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
        end
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 128
        LocalPlayer.CameraMinZoomDistance = 0.5
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        pcall(function() game:GetService("GuiService").SelectedObject = nil end)
    end)

    pcall(function()
        if _OrigLighting then
            Lighting.GlobalShadows = _OrigLighting.GlobalShadows
            Lighting.Brightness = _OrigLighting.Brightness
            Lighting.Ambient = _OrigLighting.Ambient
            Lighting.OutdoorAmbient = _OrigLighting.OutdoorAmbient
            Lighting.FogEnd = _OrigLighting.FogEnd
            Lighting.FogStart = _OrigLighting.FogStart
            Lighting.ClockTime = _OrigLighting.ClockTime
            Lighting.ExposureCompensation = _OrigLighting.ExposureCompensation
        end
    end)

    pcall(function()
        if ScreenGui then ScreenGui:Destroy() end
    end)
    pcall(function()
        for _, child in pairs(parentTarget:GetChildren()) do
            if child:IsA("ScreenGui") and (child.Name == "NebulaUpdateUI" or child.Name == "NebulaKeySystemUI" or child.Name == "EternalFlick_GUI" or child.Name == "NebulaFreecamMenu" or child.Name == "NebulaFreecamCrosshair" or child.Name == "NebulaPlayerInspector" or child.Name == "NebulaESP") then
                child:Destroy()
            end
        end
    end)

    getgenv().BloxFruitsUILoaded = false
    _G.NebulaLoaded = false
    _G.toggleNebulaMenu = nil
end
unloadMenu = performFullUnload
unloadNebula = performFullUnload

DISCORD_WEBHOOK_URL = "https://ptb.discord.com/api/webhooks/1535102102127517736/Cl_odQafhIPoqbObhLadq-d9kxOu83PM_hIAfx6QoZDbeo7Y_vGoJgtZPfV8v2OOij6N"
KEY_SALT = "NEBULA_SECURE_TOKEN_SALT_2026_V67"
KEY_FILE = "nebula_key.txt"
isKeyVerified = false
savedKeyOnDisk = nil
currentSessionToken = nil
activeValidationKey = nil
lastSentKey = nil
isSendingWebhook = false
lastKeyGenTimestamp = 0
KEY_COOLDOWN_SECONDS = 300

WHITELISTED_USERS = {
    ["gims_93bandit"] = true,
    ["myhackv2"] = true
}

function isPlayerWhitelisted()
    local uid = tostring(LocalPlayer.UserId)
    local uName = string.lower(tostring(LocalPlayer.Name))
    for entry, _ in pairs(WHITELISTED_USERS) do
        local clean = string.lower(tostring(entry)):gsub("^@", ""):gsub("%s+", "")
        if clean == uid or clean == uName then
            return true
        end
    end
    return false
end

function httpRelay(url, method, bodyStr)
    method = method or "GET"
    local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if req then
        local ok, res = pcall(function()
            return req({
                Url = url,
                Method = method,
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Accept"] = "application/json"
                },
                Body = bodyStr
            })
        end)
        if ok and res then
            if type(res) == "table" then
                return res.Body or res.body or ""
            elseif type(res) == "string" then
                return res
            end
        end
    end
    if method == "GET" and game and game.HttpGet then
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if ok and body then return body end
    end
    return nil
end

function computeSignature(userId, token)
    local raw = tostring(userId) .. ":" .. tostring(token) .. ":" .. KEY_SALT .. ":" .. tostring(tonumber(userId) * 47 + 101)
    local h1 = 0x811c9dc5
    local h2 = 0x5bd1e995
    for i = 1, #raw do
        local b = string.byte(raw, i)
        if bit32 then
            h1 = bit32.bxor((h1 * 33 + b) % 4294967296, 0x55555555)
            h2 = bit32.bxor((h2 * 37 + b) % 4294967296, 0xAAAAAAAA)
        else
            h1 = ((h1 * 33 + b) + 0x55555555) % 4294967296
            h2 = ((h2 * 37 + b) + 0xAAAAAAAA) % 4294967296
        end
    end
    local s1, s2
    if bit32 then
        s1 = string.format("%04X", bit32.band(h1, 0xFFFF))
        s2 = string.format("%04X", bit32.band(bit32.rshift(h1, 16), 0xFFFF))
    else
        s1 = string.format("%04X", math.floor(h1) % 65536)
        s2 = string.format("%04X", math.floor(h2) % 65536)
    end
    return s1 .. s2
end

function generateRandomToken()
    local chars = "0123456789ABCDEF"
    local t = ""
    for i = 1, 8 do
        local r = math.random(1, #chars)
        t = t .. string.sub(chars, r, r)
    end
    return t
end

function generateFreshKeyForUser(userId)
    math.randomseed(os.time() + tick() * 1000 + math.random(1000, 99999))
    local token = generateRandomToken()
    local sig = computeSignature(userId, token)
    local fullKey = "NEBULA-" .. string.sub(token, 1, 4) .. "-" .. string.sub(token, 5, 8) .. "-" .. string.sub(sig, 1, 4) .. "-" .. string.sub(sig, 5, 8)
    return fullKey, token
end

function verifyKeyFormatAndSignature(userId, keyStr)
    if not keyStr or type(keyStr) ~= "string" then return false end
    local clean = keyStr:gsub("%s+", ""):upper()
    local parts = {}
    for part in string.gmatch(clean, "[^-]+") do
        table.insert(parts, part)
    end
    if #parts ~= 5 then return false end
    if parts[1] ~= "NEBULA" then return false end
    local token = parts[2] .. parts[3]
    local sig = parts[4] .. parts[5]
    if #token ~= 8 or #sig ~= 8 then return false end
    local expectedSig = computeSignature(userId, token)
    if string.upper(sig) == string.upper(expectedSig) then
        return true, token
    end
    return false
end

function sendKeyWebhook(keyToSend)
    if not isPlayerWhitelisted() then return end
    if isSendingWebhook then return end
    if lastSentKey == keyToSend then return end
    isSendingWebhook = true
    lastSentKey = keyToSend

    pcall(function()
        local placeName = "Roblox Game"
        pcall(function()
            local mps = game:GetService("MarketplaceService")
            local info = mps:GetProductInfo(game.PlaceId)
            if info and info.Name then placeName = info.Name end
        end)
        local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(LocalPlayer.UserId) .. "&width=150&height=150&format=png"
        local payload = {
            username = "Nebula Key System",
            avatar_url = avatarUrl,
            embeds = {
                {
                    title = "Nouvelle Cle Aleatoire Generee (Whitelisted) - Nebula Hub",
                    description = "Un utilisateur whiteliste a demande une cle d'acces.",
                    color = 9522431,
                    fields = {
                        {
                            name = "Pseudo Roblox",
                            value = "**" .. tostring(LocalPlayer.Name) .. "** (@" .. tostring(LocalPlayer.DisplayName) .. ")",
                            inline = true
                        },
                        {
                            name = "UserId",
                            value = "`" .. tostring(LocalPlayer.UserId) .. "`",
                            inline = true
                        },
                        {
                            name = "Statut Whitelist",
                            value = "AUTORISE (Cle generee)",
                            inline = true
                        },
                        {
                            name = "Jeu",
                            value = tostring(placeName) .. " (`" .. tostring(game.PlaceId) .. "`)",
                            inline = false
                        },
                        {
                            name = "Cle Generee (A lui donner)",
                            value = "```" .. tostring(keyToSend) .. "```",
                            inline = false
                        },
                        {
                            name = "Profil Roblox",
                            value = "[Ouvrir le Profil](https://www.roblox.com/users/" .. tostring(LocalPlayer.UserId) .. "/profile)",
                            inline = true
                        }
                    },
                    thumbnail = {
                        url = avatarUrl
                    },
                    footer = {
                        text = "Nebula Hub - Whitelist Active"
                    },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            }
        }
        httpRelay(DISCORD_WEBHOOK_URL, "POST", HttpService:JSONEncode(payload))
    end)
    task.delay(3, function() isSendingWebhook = false end)
end

local hasSentLoadWebhook = false
function sendCheatLoadedWebhook()
    if hasSentLoadWebhook then return end
    hasSentLoadWebhook = true

    task.spawn(function()
        pcall(function()
            local headUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(LocalPlayer.UserId) .. "&width=150&height=150&format=png"
            local gameThumbUrl = nil
            local gameName = "Roblox Game"

            pcall(function()
                local mps = game:GetService("MarketplaceService")
                local pInfo = mps:GetProductInfo(game.PlaceId)
                if pInfo and pInfo.Name then
                    gameName = pInfo.Name
                end
            end)

            pcall(function()
                local headApi = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. tostring(LocalPlayer.UserId) .. "&size=150x150&format=Png&isCircular=false"
                local res = httpRelay(headApi, "GET")
                if res and #res > 0 then
                    local data = HttpService:JSONDecode(res)
                    if data and data.data and data.data[1] and data.data[1].imageUrl then
                        headUrl = data.data[1].imageUrl
                    end
                end
            end)

            pcall(function()
                if game.PlaceId and game.PlaceId > 0 then
                    local univApi = "https://apis.roblox.com/universes/v1/places/" .. tostring(game.PlaceId) .. "/universe"
                    local uRes = httpRelay(univApi, "GET")
                    if uRes and #uRes > 0 then
                        local uData = HttpService:JSONDecode(uRes)
                        if uData and uData.universeId then
                            local thumbApi = "https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=" .. tostring(uData.universeId) .. "&size=768x432&format=Png&isCircular=false"
                            local tRes = httpRelay(thumbApi, "GET")
                            if tRes and #tRes > 0 then
                                local tData = HttpService:JSONDecode(tRes)
                                if tData and tData.data and tData.data[1] and tData.data[1].thumbnails and tData.data[1].thumbnails[1] then
                                    gameThumbUrl = tData.data[1].thumbnails[1].imageUrl
                                end
                            end
                            if not gameThumbUrl then
                                local iconApi = "https://thumbnails.roblox.com/v1/games/icons?universeIds=" .. tostring(uData.universeId) .. "&size=512x512&format=Png&isCircular=false"
                                local iRes = httpRelay(iconApi, "GET")
                                if iRes and #iRes > 0 then
                                    local iData = HttpService:JSONDecode(iRes)
                                    if iData and iData.data and iData.data[1] and iData.data[1].imageUrl then
                                        gameThumbUrl = iData.data[1].imageUrl
                                    end
                                end
                            end
                        end
                    end
                end
            end)

            if not gameThumbUrl and game.PlaceId and game.PlaceId > 0 then
                pcall(function()
                    local pIconApi = "https://thumbnails.roblox.com/v1/places/gameicons?placeIds=" .. tostring(game.PlaceId) .. "&returnPolicy=PlaceHolder&size=512x512&format=Png&isCircular=false"
                    local piRes = httpRelay(pIconApi, "GET")
                    if piRes and #piRes > 0 then
                        local piData = HttpService:JSONDecode(piRes)
                        if piData and piData.data and piData.data[1] and piData.data[1].imageUrl then
                            gameThumbUrl = piData.data[1].imageUrl
                        end
                    end
                end)
            end

            local payload = {
                username = "Nebula Hub Loader",
                avatar_url = headUrl,
                embeds = {{
                    title = "🪐 Nebula Hub • Cheat Chargé !",
                    description = "Le cheat vient d'être chargé avec succès dans la partie.",
                    color = 9522431,
                    fields = {
                        {
                            name = "👤 Joueur",
                            value = "**" .. tostring(LocalPlayer.DisplayName) .. "** (@" .. tostring(LocalPlayer.Name) .. ")",
                            inline = true
                        },
                        {
                            name = "🆔 User ID",
                            value = "`" .. tostring(LocalPlayer.UserId) .. "`",
                            inline = true
                        },
                        {
                            name = "🎮 Jeu",
                            value = "**" .. tostring(gameName) .. "** (`" .. tostring(game.PlaceId) .. "`)",
                            inline = false
                        },
                        {
                            name = "🌐 Job ID",
                            value = "`" .. (game.JobId ~= "" and tostring(game.JobId) or "Serveur Inconnu / Solo") .. "`",
                            inline = false
                        },
                        {
                            name = "🔗 Profil Roblox",
                            value = "[Ouvrir le Profil](https://www.roblox.com/users/" .. tostring(LocalPlayer.UserId) .. "/profile)",
                            inline = true
                        },
                        {
                            name = "🕹️ Lien du Jeu",
                            value = "[Rejoindre le Jeu](https://www.roblox.com/games/" .. tostring(game.PlaceId) .. ")",
                            inline = true
                        }
                    },
                    thumbnail = headUrl and { url = headUrl } or nil,
                    image = gameThumbUrl and { url = gameThumbUrl } or nil,
                    footer = {
                        text = "Nebula Hub • Load Logger",
                        icon_url = headUrl
                    },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            }

            httpRelay(DISCORD_WEBHOOK_URL, "POST", HttpService:JSONEncode(payload))
        end)
    end)
end

pcall(function()
    if isfile and readfile and isfile(KEY_FILE) then
        local saved = readfile(KEY_FILE)
        if saved then
            local cleanSaved = tostring(saved):gsub("%s+", ""):upper()
            local valid = verifyKeyFormatAndSignature(LocalPlayer.UserId, cleanSaved)
            if valid then
                savedKeyOnDisk = cleanSaved
            end
        end
    end
end)

KeyGui = nil
function createKeySystemUI()
    if KeyGui then KeyGui:Destroy() end

    for _, c in ipairs(parent:GetChildren()) do
        if c.Name == "NebulaKeySystemUI" then
            c:Destroy()
        end
    end

    local whitelisted = isPlayerWhitelisted()
    if whitelisted and not activeValidationKey then
        if savedKeyOnDisk then
            activeValidationKey = savedKeyOnDisk
        else
            activeValidationKey, currentSessionToken = generateFreshKeyForUser(LocalPlayer.UserId)
            savedKeyOnDisk = activeValidationKey
            lastKeyGenTimestamp = os.time()
            pcall(function()
                if writefile then
                    writefile(KEY_FILE, activeValidationKey)
                end
            end)
            task.spawn(function()
                sendKeyWebhook(activeValidationKey)
            end)
        end
    end

    KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "NebulaKeySystemUI"
    KeyGui.ResetOnSpawn = false
    KeyGui.DisplayOrder = 100000
    KeyGui.IgnoreGuiInset = true
    KeyGui.Parent = parent

    local Dimmer = Instance.new("Frame")
    Dimmer.Name = "Dimmer"
    Dimmer.Size = UDim2.new(1, 0, 1, 0)
    Dimmer.Position = UDim2.new(0, 0, 0, 0)
    Dimmer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Dimmer.BackgroundTransparency = 0.35
    Dimmer.BorderSizePixel = 0
    Dimmer.Active = true
    Dimmer.Parent = KeyGui

    local Card = Instance.new("Frame")
    Card.Name = "Card"
    Card.Size = UDim2.new(0, 460, 0, 410)
    Card.Position = UDim2.new(0.5, -230, 0.5, -205)
    Card.BackgroundColor3 = Color3.fromRGB(14, 15, 22)
    Card.BorderSizePixel = 0
    Card.Active = true
    Card.ClipsDescendants = true
    Card.Parent = KeyGui
    makeCorner(Card, 14)
    makeStroke(Card, theme.border, 1.2, 0.2)

    local CardScale = Instance.new("UIScale")
    CardScale.Scale = 0.85
    CardScale.Parent = Card
    TweenService:Create(CardScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    local cardDragging, cardDragStart, cardStartPos = false, nil, nil
    Card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cardDragging = true
            cardDragStart = input.Position
            cardStartPos = Card.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    cardDragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if cardDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - cardDragStart
            Card.Position = UDim2.new(
                cardStartPos.X.Scale, cardStartPos.X.Offset + delta.X,
                cardStartPos.Y.Scale, cardStartPos.Y.Offset + delta.Y
            )
        end
    end)

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.Position = UDim2.new(0, 0, 0, 0)
    Header.BackgroundTransparency = 1
    Header.BorderSizePixel = 0
    Header.Parent = Card

    local AccentStripe = Instance.new("Frame")
    AccentStripe.Size = UDim2.new(0, 3, 0, 24)
    AccentStripe.Position = UDim2.new(0, 20, 0.5, -12)
    AccentStripe.BackgroundColor3 = whitelisted and theme.accent or theme.danger
    AccentStripe.BorderSizePixel = 0
    AccentStripe.Parent = Header
    makeCorner(AccentStripe, 2)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0, 180, 1, 0)
    TitleLabel.Position = UDim2.new(0, 32, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "NEBULA HUB"
    TitleLabel.TextColor3 = theme.text
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local Badge = Instance.new("Frame")
    Badge.Size = UDim2.new(0, 100, 0, 24)
    Badge.Position = UDim2.new(1, -120, 0.5, -12)
    Badge.BackgroundColor3 = Color3.fromRGB(22, 23, 34)
    Badge.BorderSizePixel = 0
    Badge.Parent = Header
    makeCorner(Badge, 6)
    makeStroke(Badge, whitelisted and theme.border or theme.danger, 1)

    local BadgeLabel = Instance.new("TextLabel")
    BadgeLabel.Size = UDim2.new(1, 0, 1, 0)
    BadgeLabel.BackgroundTransparency = 1
    BadgeLabel.Text = whitelisted and "WHITELISTED" or "NON-WHITELIST"
    BadgeLabel.TextColor3 = whitelisted and theme.accent or theme.danger
    BadgeLabel.Font = Enum.Font.GothamBold
    BadgeLabel.TextSize = 9
    BadgeLabel.Parent = Badge

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -40, 0, 1)
    Divider.Position = UDim2.new(0, 20, 0, 50)
    Divider.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    Divider.BorderSizePixel = 0
    Divider.Parent = Card

    local ProfileFrame = Instance.new("Frame")
    ProfileFrame.Size = UDim2.new(1, -40, 0, 56)
    ProfileFrame.Position = UDim2.new(0, 20, 0, 60)
    ProfileFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 28)
    ProfileFrame.BorderSizePixel = 0
    ProfileFrame.Parent = Card
    makeCorner(ProfileFrame, 10)
    makeStroke(ProfileFrame, theme.border, 1)

    local AvatarImg = Instance.new("ImageLabel")
    AvatarImg.Size = UDim2.new(0, 42, 0, 42)
    AvatarImg.Position = UDim2.new(0, 8, 0.5, -21)
    AvatarImg.BackgroundColor3 = Color3.fromRGB(24, 25, 36)
    AvatarImg.BorderSizePixel = 0
    AvatarImg.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(LocalPlayer.UserId) .. "&width=150&height=150&format=png"
    AvatarImg.Parent = ProfileFrame
    makeCorner(AvatarImg, 8)
    makeStroke(AvatarImg, whitelisted and theme.accent or theme.danger, 1)

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -64, 0, 18)
    NameLabel.Position = UDim2.new(0, 58, 0, 9)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = tostring(LocalPlayer.DisplayName) .. " (@" .. tostring(LocalPlayer.Name) .. ")"
    NameLabel.TextColor3 = theme.text
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 12
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = ProfileFrame

    local SubInfoLabel = Instance.new("TextLabel")
    SubInfoLabel.Size = UDim2.new(1, -64, 0, 16)
    SubInfoLabel.Position = UDim2.new(0, 58, 0, 28)
    SubInfoLabel.BackgroundTransparency = 1
    SubInfoLabel.Text = "UserId: " .. tostring(LocalPlayer.UserId) .. (whitelisted and " | Statut: Autorise" or " | Statut: Non autorise")
    SubInfoLabel.TextColor3 = whitelisted and theme.sub or theme.danger
    SubInfoLabel.Font = Enum.Font.Code
    SubInfoLabel.TextSize = 10
    SubInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubInfoLabel.Parent = ProfileFrame

    local NoticeBox = Instance.new("Frame")
    NoticeBox.Size = UDim2.new(1, -40, 0, 48)
    NoticeBox.Position = UDim2.new(0, 20, 0, 126)
    NoticeBox.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
    NoticeBox.BorderSizePixel = 0
    NoticeBox.Parent = Card
    makeCorner(NoticeBox, 8)
    makeStroke(NoticeBox, theme.border, 1)

    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -20, 1, -8)
    NoticeText.Position = UDim2.new(0, 10, 0, 4)
    NoticeText.BackgroundTransparency = 1
    if whitelisted then
        NoticeText.Text = "Compte @" .. tostring(LocalPlayer.Name) .. " Whiteliste ! Cliquez sur LOGIN pour ouvrir le menu Nebula."
    else
        NoticeText.Text = "Acces refuse : votre compte @" .. tostring(LocalPlayer.Name) .. " n'est pas dans la Whitelist."
    end
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextSize = 10
    NoticeText.TextWrapped = true
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.Parent = NoticeBox

    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -40, 0, 44)
    InputContainer.Position = UDim2.new(0, 20, 0, 184)
    InputContainer.BackgroundColor3 = Color3.fromRGB(18, 19, 28)
    InputContainer.BorderSizePixel = 0
    InputContainer.Parent = Card
    makeCorner(InputContainer, 8)
    local inputStroke = makeStroke(InputContainer, theme.border, 1)

    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(1, -20, 1, 0)
    KeyInput.Position = UDim2.new(0, 10, 0, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.Text = whitelisted and "WHITELIST-OK" or ""
    KeyInput.PlaceholderText = whitelisted and "WHITELIST-OK" or "Acces refuse - Non whiteliste"
    KeyInput.PlaceholderColor3 = Color3.fromRGB(90, 95, 115)
    KeyInput.TextColor3 = whitelisted and Color3.fromRGB(80, 220, 140) or Color3.fromRGB(255, 255, 255)
    KeyInput.Font = Enum.Font.Code
    KeyInput.TextSize = 12
    KeyInput.ClearTextOnFocus = false
    KeyInput.TextEditable = not whitelisted
    KeyInput.Active = not whitelisted
    KeyInput.Parent = InputContainer

    KeyInput:GetPropertyChangedSignal("Text"):Connect(function()
        if whitelisted and KeyInput.Text ~= "WHITELIST-OK" then
            KeyInput.Text = "WHITELIST-OK"
        end
    end)

    KeyInput.Focused:Connect(function()
        if whitelisted then
            KeyInput:ReleaseFocus()
            return
        end
        TweenService:Create(inputStroke, TweenInfo.new(0.2), { Color = theme.accent }):Play()
    end)
    KeyInput.FocusLost:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.2), { Color = theme.border }):Play()
    end)

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -40, 0, 18)
    StatusLabel.Position = UDim2.new(0, 20, 0, 234)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = theme.danger
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 11
    StatusLabel.Parent = Card

    pcall(function()
        if whitelisted then
            KeyInput.Text = "WHITELIST-OK"
            KeyInput.TextEditable = false
            KeyInput.Active = false
            StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 140)
            StatusLabel.Text = "Whitelist detectee ! Cliquez sur LOGIN."
        elseif savedKeyOnDisk and savedKeyOnDisk ~= "" then
            KeyInput.Text = savedKeyOnDisk
            StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 140)
            StatusLabel.Text = "Cle sauvegardee detectee ! Cliquez sur LOGIN."
        else
            if getclipboard then
                local clip = getclipboard()
                if clip and type(clip) == "string" then
                    local cleanClip = clip:gsub("%s+", "")
                    if #cleanClip >= 20 and string.sub(cleanClip, 1, 6) == "NEBULA" then
                        KeyInput.Text = cleanClip
                        StatusLabel.TextColor3 = Color3.fromRGB(80, 200, 255)
                        StatusLabel.Text = "Cle detectee dans le presse-papiers !"
                    end
                end
            end
        end
    end)

    local SubmitBtn = Instance.new("TextButton")
    SubmitBtn.Size = UDim2.new(1, -40, 0, 42)
    SubmitBtn.Position = UDim2.new(0, 20, 0, 256)
    SubmitBtn.BackgroundColor3 = whitelisted and theme.accent or Color3.fromRGB(55, 55, 65)
    SubmitBtn.BorderSizePixel = 0
    SubmitBtn.Text = "LOGIN (DEVERROUILLER)"
    SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitBtn.Font = Enum.Font.GothamBold
    SubmitBtn.TextSize = 12
    SubmitBtn.Parent = Card
    makeCorner(SubmitBtn, 8)

    local ActionRow = Instance.new("Frame")
    ActionRow.Size = UDim2.new(1, -40, 0, 36)
    ActionRow.Position = UDim2.new(0, 20, 0, 308)
    ActionRow.BackgroundTransparency = 1
    ActionRow.Parent = Card

    local AutoDropBtn = Instance.new("TextButton")
    AutoDropBtn.Size = UDim2.new(0.31, 0, 1, 0)
    AutoDropBtn.Position = UDim2.new(0, 0, 0, 0)
    AutoDropBtn.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
    AutoDropBtn.BorderSizePixel = 0
    AutoDropBtn.Text = "Coller presse-papiers"
    AutoDropBtn.TextColor3 = theme.text
    AutoDropBtn.Font = Enum.Font.GothamBold
    AutoDropBtn.TextSize = 10
    AutoDropBtn.Parent = ActionRow
    makeCorner(AutoDropBtn, 7)
    makeStroke(AutoDropBtn, theme.border, 1)

    local CopyIdBtn = Instance.new("TextButton")
    CopyIdBtn.Size = UDim2.new(0.31, 0, 1, 0)
    CopyIdBtn.Position = UDim2.new(0.345, 0, 0, 0)
    CopyIdBtn.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
    CopyIdBtn.BorderSizePixel = 0
    CopyIdBtn.Text = "Copier mon ID"
    CopyIdBtn.TextColor3 = theme.text
    CopyIdBtn.Font = Enum.Font.GothamBold
    CopyIdBtn.TextSize = 10
    CopyIdBtn.Parent = ActionRow
    makeCorner(CopyIdBtn, 7)
    makeStroke(CopyIdBtn, theme.border, 1)

    local CopyUsernameBtn = Instance.new("TextButton")
    CopyUsernameBtn.Size = UDim2.new(0.31, 0, 1, 0)
    CopyUsernameBtn.Position = UDim2.new(0.69, 0, 0, 0)
    CopyUsernameBtn.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
    CopyUsernameBtn.BorderSizePixel = 0
    CopyUsernameBtn.Text = "Copier mon @"
    CopyUsernameBtn.TextColor3 = theme.text
    CopyUsernameBtn.Font = Enum.Font.GothamBold
    CopyUsernameBtn.TextSize = 10
    CopyUsernameBtn.Parent = ActionRow
    makeCorner(CopyUsernameBtn, 7)
    makeStroke(CopyUsernameBtn, theme.border, 1)

    local function setupHover(btn)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = theme.cardHover }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(20, 21, 30) }):Play()
        end)
    end
    setupHover(AutoDropBtn)
    setupHover(CopyIdBtn)
    setupHover(CopyUsernameBtn)

    AutoDropBtn.MouseButton1Click:Connect(function()
        if whitelisted then return end
        pcall(function()
            if getclipboard then
                local clip = getclipboard()
                if clip and type(clip) == "string" then
                    KeyInput.Text = clip:gsub("%s+", "")
                    StatusLabel.TextColor3 = Color3.fromRGB(80, 200, 255)
                    StatusLabel.Text = "Cle collee depuis le presse-papiers !"
                end
            end
        end)
    end)

    CopyIdBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then
                setclipboard(tostring(LocalPlayer.UserId))
                StatusLabel.TextColor3 = Color3.fromRGB(80, 200, 255)
                StatusLabel.Text = "UserId copie dans le presse-papier !"
            end
        end)
    end)

    CopyUsernameBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then
                setclipboard("@" .. tostring(LocalPlayer.Name))
                StatusLabel.TextColor3 = Color3.fromRGB(80, 200, 255)
                StatusLabel.Text = "@" .. tostring(LocalPlayer.Name) .. " copie dans le presse-papier !"
            end
        end)
    end)

    local function checkAndUnlock()
        if not isPlayerWhitelisted() then
            StatusLabel.TextColor3 = theme.danger
            StatusLabel.Text = "Acces refuse : @" .. tostring(LocalPlayer.Name) .. " n'est pas dans la Whitelist !"
            TweenService:Create(inputStroke, TweenInfo.new(0.15), { Color = theme.danger }):Play()
            task.delay(2, function()
                LocalPlayer:Kick("Vous n'etes pas dans la Whitelist (@).\nContactez un administrateur.")
            end)
            return
        end

        isKeyVerified = true
        _G.isKeyVerified = true
        pcall(function() if sendCheatLoadedWebhook then sendCheatLoadedWebhook() end end)
        StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
        StatusLabel.Text = "Whitelist validee ! Chargement..."
        SubmitBtn.Text = "ACCES AUTORISE"
        SubmitBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)

        task.delay(0.25, function()
            TweenService:Create(CardScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.7 }):Play()
            TweenService:Create(Dimmer, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
            task.delay(0.25, function()
                if KeyGui then KeyGui:Destroy() KeyGui = nil end
                menuOpen = true
                Panel.Visible = true
                if V and V.BubblesEnabled then
                    BubblesContainer.Visible = true
                    BubblesContainer.BackgroundTransparency = 1
                else
                    BubblesContainer.Visible = false
                end
                if V and V.DimmerEnabled then
                    local targetTrans = 1 - ((V.DimmerOpacity or 80) / 100)
                    BackgroundDimmer.Visible = true
                    BackgroundDimmer.BackgroundTransparency = 1
                    TweenService:Create(BackgroundDimmer, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = targetTrans }):Play()
                else
                    BackgroundDimmer.Visible = false
                end
                PanelScale.Scale = 0.88
                Panel.Position = panelPos + UDim2.new(0, 0, 0, 16)
                TweenService:Create(PanelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
                TweenService:Create(Panel, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = panelPos }):Play()
                switchCategory("Movement")
                notify("Nebula Hub", "Bienvenue @" .. tostring(LocalPlayer.Name) .. " !", Color3.fromRGB(80, 200, 120))
            end)
        end)
    end

    SubmitBtn.MouseButton1Click:Connect(checkAndUnlock)
    KeyInput.FocusLost:Connect(function(enter)
        if enter then checkAndUnlock() end
    end)
end

task.delay(0.1, function()
    Panel.Visible = false
    menuOpen = false
    if BubblesContainer then BubblesContainer.Visible = true end
    createKeySystemUI()
end)

task.delay(0.3, function()
    if not isKeyVerified then return end
    pcall(function() if sendCheatLoadedWebhook then sendCheatLoadedWebhook() end end)
    notify("Nebula Hub", "Cle validee (Sauvegardee) !", Color3.fromRGB(80, 200, 120))
    menuOpen = true
    Panel.Visible = true
    if V and V.BubblesEnabled then
        BubblesContainer.Visible = true
        BubblesContainer.BackgroundTransparency = 1
    else
        BubblesContainer.Visible = false
    end
    if V and V.DimmerEnabled then
        local targetTrans = 1 - ((V.DimmerOpacity or 80) / 100)
        BackgroundDimmer.Visible = true
        BackgroundDimmer.BackgroundTransparency = 1
        TweenService:Create(BackgroundDimmer, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = targetTrans}):Play()
    else
        BackgroundDimmer.Visible = false
    end
    PanelScale.Scale = 0.88
    Panel.Position = panelPos + UDim2.new(0, 0, 0, 16)
    TweenService:Create(PanelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    TweenService:Create(Panel, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = panelPos}):Play()
    switchCategory("Movement")
end)

ChatContent = nil
SpyContent = ContentFrames["Spy"]
ProtectionContent = ContentFrames["Protection"]
MovementContent = ContentFrames["Movement"]
MeContent = ContentFrames["Me"]
ESPContent = ContentFrames["ESP"]
AimContent = ContentFrames["Aim"]
TeleportContent = ContentFrames["Teleport"]
JoueurContent = ContentFrames["Joueur"]
ServerContent = ContentFrames["Server"]
FunContent = ContentFrames["Fun"]
ScriptsContent = ContentFrames["Scripts"]
SettingsContent = ContentFrames["Settings"]
ConfigContent = ContentFrames["Config"]
VehicleContent = ContentFrames["Vehicle"]
CodeContent = ContentFrames["Code"]

initStep = "V defaults"
V.KeyboardLayout = "AZERTY"
V.Speed = 16
V.SpeedEnabled = false
V.SpeedMethod = "Humanoid"
V.Jump = 50
V.JumpEnabled = false
V.FlySpeed = 150
V.DesyncFlySpeed = 150
V.Fly = false
V.Noclip = false
V.InfJump = false
V.DesyncFly = false
V.CFrameSpeed = false
V.WallClimb = false
V.Invis = false
V.InvisConn = nil
V.Notif = true
V.AntiAFK = false
V.NoAnim = false
V.Spin = false
V.SpinSpeed = 100
V.Watermark = true
V.BubblesEnabled = true
V.DimmerEnabled = true
V.DimmerOpacity = 80
V.AntiRagdoll = false
V.InstInteract = false
V.InfRange = false
V.FPSBoost = false
V.Fullbright = false
V.XRay = false
V.XRayTransparency = 65
V.XRayKeepFloor = true
V.XRayHideDecals = true
V.XRayStyle = "Murs Propres"
V.ESP = false
V.ESPBox = false
V.ESPGlow = false
V.ESPFilled = false
V.ESPName = false
V.ESPDist = false
V.ESPSelf = false
V.ESPNPC = false
V.ESPTeamCheck = false
V.FreecamTPTargetMode = "Ground"
V.FreecamCharVisible = false
V.AntiFling = false
V.RapidFire = false
V.InfAmmo = false
V.FastReload = false
V.HitboxExtender = false
V.HitboxSize = 25
V.BodyHeightScale = 10
V.BodyWidthScale = 10
V.RightClickInspect = false
V.ESPTracer = false
V.ESPSkeleton = false
V.ESPHealth = false
V.ESPPV = false
V.ESPWeapon = false
V.ESPDropped = false
V.ESPTracerOrigin ="Bottom"
V.AutoBhop = false
V.AntiVoid = false
V.Godmode = false
V.Ghost = false
V.GhostConn = nil
V.WallClimb = false
V.SuperJumpCharge = false
V.SuperJumpConn = nil
V.BulletTracers = false
V.OffScreenArrows = false
V.OffScreenConn = nil
V.SitAir = false
V.SitAirConn = nil
V.GrappleHook = false
V.GrappleTool = nil
V.VehicleGhost = false
V.VehicleNitroFlame = false
V.VehicleExplodeEnabled = false
V.VehicleRampKey = Enum.KeyCode.U
V.VehicleSpeed = 1
V.VehicleFly = false
V.VehicleFlySpeed = 150
V.VehicleNoclip = false
V.VehicleBoostSpeed = 250
V.VehicleBoostMode = "Camera"
V.VehicleBoosting = false
V.KeybindHUD = false
V.UITransparency = 3
V.AccentColor = Color3.fromRGB(60, 160, 255)
V.ESPColor = Color3.fromRGB(145, 120, 255)
V.ESPObjects = {}
V.OrigAnim = nil
V.SelPlayer = nil
V.Spectate = false
V.SpecConn = nil
V.Attached = nil
V.NoAnimConn = nil
V.AttachConn = nil
V.SpinConn = nil
V.AntiRagdollConn = nil
V.Inst1 = nil
V.Inst2 = nil
V.Inf1 = nil
V.Inf2 = nil
V.InfRangeConn = nil
V.FPSBoost1 = nil
V.FPSBoost2 = nil
V.ToggleKeyConn = nil
V.ClickTP = false
V.ClickTPTool = nil
V.Flinging = false
V.FlingTarget = nil
V.FlingConn = nil
V.Freecam = false
V.FreecamSpeed = 50
V.FreecamConn = nil
V.AutoRejoin = false
V.AutoRejoinConn = nil
V.LagSwitch = false
V.LagSwitchConn = nil
V.LagSwitchOrigin = nil
V.Desync = false
V.DesyncConn = nil
V.DesyncOrigin = nil

initStep = "connexions base"
parentTarget = (gethui and gethui()) or game:GetService("CoreGui")

Debris = game:GetService("Debris")

function addConnection(conn)
    table.insert(C.All, conn)
end

V.AntiBlockConn = RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local parts = workspace:GetPartBoundsInBox(hrp.CFrame, Vector3.new(8, 8, 8))
                for _, part in ipairs(parts) do
                    local name = part.Name:lower()
                    local isBarrier = (name:match("block") or name:match("trap") or name:match("barrier") or name:match("anticheat")) and part.Size.Magnitude < 6
                    if isBarrier then
                        if part.Parent ~= char and not part:IsDescendantOf(char) then
                            part:Destroy()
                        end
                    end
                end
            end
        end
    end)
end)
addConnection(V.AntiBlockConn)

currentFPS = 60
frames = 0
lastTime = os.clock()
V.FPSConn = RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local currentTime = os.clock()
    if currentTime - lastTime >= 0.5 then
        currentFPS = math.floor(frames / (currentTime - lastTime))
        frames = 0
        lastTime = currentTime
    end
    if Camera.FieldOfView ~= V.FOV then
        Camera.FieldOfView = V.FOV
    end
end)
addConnection(V.FPSConn)

NotificationContainer = Instance.new("Frame")
NotificationContainer.Name ="NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 300, 1, -20)
NotificationContainer.Position = UDim2.new(1, -320, 0, 20)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Parent = ScreenGui

NotifList = Instance.new("UIListLayout")
NotifList.Padding = UDim.new(0, 10)
NotifList.VerticalAlignment = Enum.VerticalAlignment.Top
NotifList.Parent = NotificationContainer

lastNotifyKey = nil
lastNotifyTime = 0

function notify(title, text, color)
    if not V.Notif then return end
    if type(title) == "string" then title = string.gsub(title, "<[^>]->", "") end
    if type(text) == "string" then text = string.gsub(text, "<[^>]->", "") end
    local key = tostring(title) .. "|" .. tostring(text)
    if key == lastNotifyKey and os.clock() - lastNotifyTime < 1.5 then
        return
    end
    lastNotifyKey = key
    lastNotifyTime = os.clock()
    color = color or Color3.fromRGB(180, 180, 195)

    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(1, 0, 0, 60)
    NotifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    NotifFrame.BorderSizePixel = 0
    NotifFrame.BackgroundTransparency = 1
    NotifFrame.Parent = NotificationContainer

    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 8)
    NotifCorner.Parent = NotifFrame

    local NotifStroke = Instance.new("UIStroke")
    NotifStroke.Thickness = 1
    NotifStroke.Color = color
    NotifStroke.Transparency = 1
    NotifStroke.Parent = NotifFrame

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -20, 0, 20)
    TitleLbl.Position = UDim2.new(0, 10, 0, 8)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = title
    TitleLbl.TextColor3 = color
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 14
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.TextTransparency = 1
    TitleLbl.Parent = NotifFrame

    local TextLbl = Instance.new("TextLabel")
    TextLbl.Size = UDim2.new(1, -20, 0, 20)
    TextLbl.Position = UDim2.new(0, 10, 0, 30)
    TextLbl.BackgroundTransparency = 1
    TextLbl.Text = text
    TextLbl.TextColor3 = Color3.fromRGB(195, 195, 208)
    TextLbl.Font = Enum.Font.GothamMedium
    TextLbl.TextSize = 12
    TextLbl.TextXAlignment = Enum.TextXAlignment.Left
    TextLbl.TextTransparency = 1
    TextLbl.Parent = NotifFrame

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(NotifFrame, tweenInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(NotifStroke, tweenInfo, {Transparency = 0}):Play()
    TweenService:Create(TitleLbl, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(TextLbl, tweenInfo, {TextTransparency = 0}):Play()

    task.delay(3, function()
        local tweenOut = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        TweenService:Create(NotifFrame, tweenOut, {BackgroundTransparency = 1}):Play()
        TweenService:Create(NotifStroke, tweenOut, {Transparency = 1}):Play()
        TweenService:Create(TitleLbl, tweenOut, {TextTransparency = 1}):Play()
        TweenService:Create(TextLbl, tweenOut, {TextTransparency = 1}):Play()
        task.wait(0.6)
        NotifFrame:Destroy()
    end)
end

initStep = "definitions fonctions"
function toggleFlyAction(overrideState)
    local target = (overrideState ~= nil) and overrideState or (not V.Fly)
    if SetFlyToggle then
        SetFlyToggle(target)
    else
        if target then startFly() else stopFly() end
    end
end

function startFly()
    if V.DesyncFly and SetDesyncToggle then SetDesyncToggle(false) end
    V.Fly = true
    pcall(function()
        local char = getCharacter()
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        pcall(function()
            LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
        end)

        if V.FlyNoclipConn then V.FlyNoclipConn:Disconnect() V.FlyNoclipConn = nil end
        V.FlyNoclipConn = RunService.Stepped:Connect(function()
            if not V.Fly then
                if V.FlyNoclipConn then V.FlyNoclipConn:Disconnect() V.FlyNoclipConn = nil end
                return
            end
            local currentChar = LocalPlayer.Character
            if currentChar then
                for _, part in pairs(currentChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        addConnection(V.FlyNoclipConn)

        if humanoid then humanoid.PlatformStand = true end

        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name ="NebulaFlyGyro"
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e4
        bodyGyro.CFrame = Camera.CFrame
        bodyGyro.Parent = root

        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name ="NebulaFlyVel"
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = root

        local flyConn = RunService.RenderStepped:Connect(function()
            if not V.Fly or not root or not root.Parent then
                if bodyGyro then bodyGyro:Destroy() end
                if bodyVelocity then bodyVelocity:Destroy() end
                if humanoid then humanoid.PlatformStand = false end
                if V.FlyNoclipConn then V.FlyNoclipConn:Disconnect() V.FlyNoclipConn = nil end
                return
            end

            local camCF = Camera.CFrame
            local moveVector = Vector3.new(0, 0, 0)
            local speed = V.FlySpeed or 150

            if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
                moveVector = moveVector + camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
                moveVector = moveVector - camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
                moveVector = moveVector - camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
                moveVector = moveVector + camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVector = moveVector + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveVector = moveVector - Vector3.new(0, 1, 0)
            end

            bodyGyro.CFrame = camCF

            if moveVector.Magnitude > 0 then
                bodyVelocity.Velocity = moveVector.Unit * speed
            else
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
        addConnection(flyConn)
    end)
end

function stopFly()
    V.Fly = false
    if V.FlyNoclipConn then V.FlyNoclipConn:Disconnect() V.FlyNoclipConn = nil end
    pcall(function()
        local char = getCharacter()
        local root = char:FindFirstChild("HumanoidRootPart")
        for _, obj in pairs(root:GetChildren()) do
            if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then obj:Destroy() end
        end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        if not V.Noclip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end)
end

function startNoclip()
    V.Noclip = true
    local noclipConn = RunService.Stepped:Connect(function()
        if not V.Noclip then noclipConn:Disconnect() return end
        local char = getCharacter()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
    addConnection(noclipConn)
end

function stopNoclip()
    V.Noclip = false
    pcall(function()
        local char = getCharacter()
        if char and not V.Fly then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end)
end

invisSound = Instance.new("Sound")
invisSound.SoundId ="rbxassetid://942127495"
invisSound.Volume = 0.5
invisSound.Parent = game:GetService("Workspace")

INVISIBILITY_SAFE_POS = Vector3.new(-25.95, 84, 3537.55)

function toggleInvisibility(enabled)
    V.Invis = enabled
    task.spawn(function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            pcall(function() if invisSound then invisSound:Play() end end)

            local function setCharTransparency(character, transparency)
                for _, descendant in pairs(character:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        if descendant.Name == "HumanoidRootPart" then
                            descendant.Transparency = 1
                        else
                            descendant.Transparency = transparency
                        end
                    elseif descendant:IsA("Decal") then
                        descendant.Transparency = transparency
                    end
                end
            end

            if V.Invis then
                local savedPosition = hrp.CFrame

                char:MoveTo(INVISIBILITY_SAFE_POS)
                task.wait(0.15)

                local oldChair = workspace:FindFirstChild("invischair") or workspace:FindFirstChild("NebulaInvisChair")
                if oldChair then oldChair:Destroy() end

                local seat = Instance.new("Seat")
                seat.Name = "invischair"
                seat.Anchored = false
                seat.CanCollide = false
                seat.Transparency = 1
                seat.CastShadow = false
                seat.Position = INVISIBILITY_SAFE_POS
                seat.Parent = workspace

                local weld = Instance.new("Weld")
                weld.Part0 = seat
                weld.Part1 = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or hrp
                weld.Parent = seat

                task.wait()
                seat.CFrame = savedPosition

                setCharTransparency(char, 0.5)

                if V.InvisConn then V.InvisConn:Disconnect() end
                V.InvisConn = RunService.RenderStepped:Connect(function()
                    local c = LocalPlayer.Character
                    if not c or not V.Invis then return end
                    for _, part in pairs(c:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if part.Name == "HumanoidRootPart" then
                                if part.Transparency ~= 1 then part.Transparency = 1 end
                            else
                                if part.Transparency ~= 0.5 then part.Transparency = 0.5 end
                            end
                        elseif part:IsA("Decal") then
                            if part.Transparency ~= 0.5 then part.Transparency = 0.5 end
                        end
                    end
                end)
                addConnection(V.InvisConn)

                notify("Invisibility", "Mode Invisible Actif", Color3.fromRGB(80, 200, 120))
            else
                if V.InvisConn then V.InvisConn:Disconnect() V.InvisConn = nil end

                local invisChair = workspace:FindFirstChild("invischair") or workspace:FindFirstChild("NebulaInvisChair")
                if invisChair then
                    invisChair:Destroy()
                end

                setCharTransparency(char, 0)

                notify("Invisibility", "Mode Invisible Désactivé", Color3.fromRGB(255, 90, 90))
            end
        end)
    end)
end

addConnection(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if V and V.AntiRagdoll then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
            hum.PlatformStand = false
        end
    end
    local animate = char:FindFirstChild("Animate")
    if animate and not (V and V.NoAnim) then
        animate.Disabled = false
    end
end))

function startDesyncFly()
    if V.Fly then SetFlyToggle(false) end
    V.DesyncFly = true
    pcall(function()
        local char = getCharacter()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        humanoid.PlatformStand = true
        hrp.Anchored = true
        local lastPosition = hrp.Position

        if V.DesyncFlyNoclipConn then V.DesyncFlyNoclipConn:Disconnect() V.DesyncFlyNoclipConn = nil end
        V.DesyncFlyNoclipConn = RunService.Stepped:Connect(function()
            if not V.DesyncFly then
                if V.DesyncFlyNoclipConn then V.DesyncFlyNoclipConn:Disconnect() V.DesyncFlyNoclipConn = nil end
                return
            end
            local currentChar = LocalPlayer.Character
            if currentChar then
                for _, part in pairs(currentChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        addConnection(V.DesyncFlyNoclipConn)

        local desyncConn = RunService.Heartbeat:Connect(function(dt)
            if not V.DesyncFly then desyncConn:Disconnect() return end
            local cam = workspace.CurrentCamera
            local moveDirection = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then moveDirection = moveDirection + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then moveDirection = moveDirection - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then moveDirection = moveDirection - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then moveDirection = moveDirection + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

            local currentSpeed = V.DesyncFlySpeed or 150
            if moveDirection.Magnitude > 0 then
                lastPosition = lastPosition + (moveDirection.Unit * currentSpeed * dt)
                hrp.CFrame = CFrame.new(lastPosition, lastPosition + cam.CFrame.LookVector)
            end
        end)
        addConnection(desyncConn)
    end)
end

function stopDesyncFly()
    V.DesyncFly = false
    if V.DesyncFlyNoclipConn then V.DesyncFlyNoclipConn:Disconnect() V.DesyncFlyNoclipConn = nil end
    pcall(function()
        local hrp = getRoot()
        local humanoid = getHumanoid()
        hrp.Anchored = false
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)
end

function enableNoAnim()
    V.NoAnim = true
    local char = getCharacter()
    if not char then return end

    local animate = char:FindFirstChild("Animate")
    if animate then
        if not V.OrigAnim then
            V.OrigAnim = animate:Clone()
        end
        animate:Destroy()
    end

    if V.NoAnimConn then V.NoAnimConn:Disconnect() V.NoAnimConn = nil end
    V.NoAnimConn = RunService.RenderStepped:Connect(function()
        if not V.NoAnim then return end
        local char = getCharacter()
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end
        local animator = humanoid:FindFirstChild("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop()
            end
        end
    end)
    addConnection(V.NoAnimConn)
    notify("Me","No Animations ON", Color3.fromRGB(80, 200, 120))
end

function disableNoAnim()
    V.NoAnim = false
    if V.NoAnimConn then V.NoAnimConn:Disconnect() V.NoAnimConn = nil end

    local char = LocalPlayer.Character or getCharacter()
    if char then
        local animate = char:FindFirstChild("Animate")
        if not animate and V.OrigAnim then
            local newAnimate = V.OrigAnim:Clone()
            newAnimate.Parent = char
            V.OrigAnim = nil
        end
    end
    notify("Me","No Animations OFF", Color3.fromRGB(255, 90, 90))
end

function startSpectate(player)
    if V.Spectate then stopSpectate() end
    V.Spectate = true
    V.SelPlayer = player
    
    if V.SpecConn then V.SpecConn:Disconnect() end
    V.SpecConn = RunService.RenderStepped:Connect(function()
        if not V.Spectate or not V.SelPlayer or not V.SelPlayer.Parent then
            stopSpectate()
            return
        end
        if V.SelPlayer.Character then
            local hum = V.SelPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and Camera.CameraSubject ~= hum then
                Camera.CameraSubject = hum
            end
        end
    end)
    addConnection(V.SpecConn)
    notify("Spectate","Spectating".. player.Name, Color3.fromRGB(80, 200, 120))
end

function stopSpectate()
    V.Spectate = false
    V.SelPlayer = nil
    if V.SpecConn then V.SpecConn:Disconnect() V.SpecConn = nil end
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
        end
    end)
    notify("Spectate","Spectate OFF", Color3.fromRGB(255, 90, 90))
end

function startFling(player)
    if V.Flinging then return end
    V.Flinging = true
    V.FlingTarget = player
    local char = getCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hrp and hum then
        hum.PlatformStand = true
        local rotAngle = 0

        V.FlingConn = RunService.Heartbeat:Connect(function()
            if not V.Flinging or not V.FlingTarget or not V.FlingTarget.Character then
                stopFling()
                return
            end
            local tHrp = V.FlingTarget.Character:FindFirstChild("HumanoidRootPart") or V.FlingTarget.Character:FindFirstChild("Torso") or V.FlingTarget.Character:FindFirstChild("UpperTorso")
            if tHrp and hrp then
                pcall(function()
                    rotAngle = rotAngle + 100
                    
                    local offset = Vector3.new(math.sin(rotAngle) * 1.5, (rotAngle % 3) - 1, math.cos(rotAngle) * 1.5)
                    hrp.CFrame = tHrp.CFrame * CFrame.new(offset) * CFrame.Angles(math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)))
                    hrp.AssemblyAngularVelocity = Vector3.new(500000, 500000, 500000)
                    hrp.AssemblyLinearVelocity = Vector3.new(500000, 500000, 500000)

                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end)
            end
        end)
        addConnection(V.FlingConn)
        notify("Troll","Fling 100% Max Power ->".. player.Name, Color3.fromRGB(255, 80, 80))
    end
end

function stopFling()
    V.Flinging = false
    V.FlingTarget = nil
    if V.FlingConn then V.FlingConn:Disconnect() V.FlingConn = nil end
    pcall(function()
        local char = getCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if hrp then
            hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~="HumanoidRootPart"then
                    part.CanCollide = true
                end
            end
        end
    end)
    notify("Troll","Fling arrêté.", Color3.fromRGB(255, 80, 80))
end


movementConn = RunService.RenderStepped:Connect(function(dt)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp or humanoid.Health <= 0 then return end
        if humanoid.SeatPart or humanoid.Sit then return end

        if V.Freecam then
            humanoid.WalkSpeed = 0
            if humanoid.UseJumpPower then
                humanoid.JumpPower = 0
            else
                humanoid.JumpHeight = 0
            end
            hrp.AssemblyLinearVelocity = Vector3.zero
            return
        end

        if not UserInputService:GetFocusedTextBox() and not V.Fly and not V.DesyncFly then
            local isZ = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
            local isS = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)
            local isQ = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)
            local isD = UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)

            if isZ or isS or isQ or isD then
                local fwd = (isZ and -1 or 0) + (isS and 1 or 0)
                local side = (isD and 1 or 0) + (isQ and -1 or 0)
                local moveVec = Vector3.new(side, 0, fwd)
                if moveVec.Magnitude > 0 then
                    humanoid:Move(moveVec.Unit, true)
                end
            end
        end

        if V.JumpEnabled and V.Jump and V.Jump > 0 then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = V.Jump
        end

        if V.SpeedEnabled and V.Speed and V.Speed > 16 then
            local currentSpeed = V.Speed
            local method = V.SpeedMethod or "Anti-TP CFrame (Recommandé)"

            if humanoid.MoveDirection.Magnitude > 0.05 then
                local moveVec = humanoid.MoveDirection.Unit
                local yVel = hrp.AssemblyLinearVelocity.Y

                if method == "Anti-TP CFrame (Recommandé)" or method == "Velocity" or method == "CFrame (Bypass)" or method == "CFrame" then
                    hrp.AssemblyLinearVelocity = Vector3.new(moveVec.X * currentSpeed, yVel, moveVec.Z * currentSpeed)
                    
                    if humanoid.WalkSpeed ~= 16 and not V.VelocitySpoof then
                        humanoid.WalkSpeed = 16
                    end
                elseif method == "Humanoid" then
                    humanoid.WalkSpeed = currentSpeed
                elseif method == "VectorForce" then
                    hrp.AssemblyLinearVelocity = moveVec * (currentSpeed * 1.5)
                end
            else
                local yVel = hrp.AssemblyLinearVelocity.Y
                hrp.AssemblyLinearVelocity = Vector3.new(0, yVel, 0)
                if method == "Humanoid" and not V.VelocitySpoof and humanoid.WalkSpeed ~= 16 then
                    humanoid.WalkSpeed = 16
                end
            end
        end

        local isClimbForward = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
        local isClimbBackward = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)
        local isClimbLeft = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)
        local isClimbRight = UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)

        if V.WallClimb then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local fwdLook = hrp.CFrame.LookVector
            local checkOffsets = {Vector3.new(0, 0, 0), Vector3.new(0, 1.2, 0), Vector3.new(0, -1.2, 0)}
            local hitWallNormal = nil

            for _, offset in ipairs(checkOffsets) do
                local res = workspace:Raycast(hrp.Position + offset, fwdLook * 2.8, rayParams)
                if res and res.Instance and res.Instance.CanCollide and math.abs(res.Normal.Y) < 0.4 then
                    hitWallNormal = res.Normal
                    break
                end
            end

            if hitWallNormal then
                local _, currentYaw, _ = hrp.CFrame:ToOrientation()
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, currentYaw, 0)

                humanoid.PlatformStand = false
                humanoid.Sit = false

                local climbSpeed = (V.Speed and V.Speed > 16) and V.Speed or 32
                local wallRight = Vector3.new(0, 1, 0):Cross(hitWallNormal).Unit

                local climbVelY = 0
                if isClimbForward then
                    climbVelY = climbSpeed
                elseif isClimbBackward then
                    climbVelY = -climbSpeed
                end

                local climbVelX = 0
                local climbVelZ = 0
                if isClimbLeft then
                    local sideMove = -wallRight * (climbSpeed * 0.8)
                    climbVelX = climbVelX + sideMove.X
                    climbVelZ = climbVelZ + sideMove.Z
                elseif isClimbRight then
                    local sideMove = wallRight * (climbSpeed * 0.8)
                    climbVelX = climbVelX + sideMove.X
                    climbVelZ = climbVelZ + sideMove.Z
                end

                local stickForce = -Vector3.new(hitWallNormal.X, 0, hitWallNormal.Z).Unit * 3.5

                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    hrp.AssemblyLinearVelocity = Vector3.new(hitWallNormal.X * 28, 55, hitWallNormal.Z * 28)
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                else
                    if climbVelY ~= 0 or climbVelX ~= 0 or climbVelZ ~= 0 then
                        hrp.AssemblyLinearVelocity = Vector3.new(stickForce.X + climbVelX, climbVelY, stickForce.Z + climbVelZ)
                        humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
                    else
                        hrp.AssemblyLinearVelocity = Vector3.new(stickForce.X, 0.15, stickForce.Z)
                        humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
                    end
                end
            else
                if humanoid:GetState() == Enum.HumanoidStateType.Climbing then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
                local _, cy, _ = hrp.CFrame:ToOrientation()
                if math.abs(hrp.CFrame.LookVector.Y) > 0.15 or math.abs(hrp.CFrame.UpVector.Y - 1) > 0.05 then
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, cy, 0)
                end
            end
        end
    end)
end)
addConnection(movementConn)

antiRagdollCharConn = nil
lastStablePos = nil

function enforceAntiRagdollOnChar(char)
    if not char then return end
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            if hum.PlatformStand then hum.PlatformStand = false end
            hum.Sit = false
            hum.RequiresNeck = false
            hum.BreakJointsOnDeath = false
        end

        for _, obj in pairs(char:GetDescendants()) do
            if obj:IsA("Constraint") or obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity") or obj:IsA("BodyThrust") or obj:IsA("LinearVelocity") or obj:IsA("VectorForce") then
                if obj.Name ~= "GrappleBV" and obj.Name ~= "SuperJumpLaunch" and obj.Name ~= "FlyVel" and obj.Name ~= "VehFlyVel" then
                    pcall(function() obj:Destroy() end)
                end
            end
            if obj:IsA("Motor6D") and not obj.Enabled then
                obj.Enabled = true
            end
            if obj:IsA("BoolValue") or obj:IsA("StringValue") then
                local n = obj.Name:lower()
                if n:find("ragdoll") or n:find("stun") or n:find("knocked") or n:find("fall") or n:find("down") or n:find("rag") then
                    if obj:IsA("BoolValue") then obj.Value = false end
                end
            end
        end
    end)
end

function toggleAntiRagdoll(enabled)
    V.AntiRagdoll = enabled
    pcall(function()
        if V.AntiRagdollConn then V.AntiRagdollConn:Disconnect() V.AntiRagdollConn = nil end
        if antiRagdollCharConn then antiRagdollCharConn:Disconnect() antiRagdollCharConn = nil end
        lastStablePos = nil

        if enabled then
            enforceAntiRagdollOnChar(LocalPlayer.Character)

            V.AntiRagdollConn = RunService.RenderStepped:Connect(function()
                if not V.AntiRagdoll then return end
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    
                    if humanoid and hrp then
                        local moving = (humanoid.MoveDirection.Magnitude > 0)
                        local isSpecialMovement = V.Fly or V.DesyncFly or V.SuperJumpCharge or (V.GrappleTool and V.GrappleTool.Parent == char)

                        if humanoid.PlatformStand or humanoid.Sit then
                            humanoid.PlatformStand = false
                            humanoid.Sit = false
                            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                        end
                        
                        local state = humanoid:GetState()
                        if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.PlatformStanding or state == Enum.HumanoidStateType.Seated then
                            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                        end

                        if hrp.AssemblyAngularVelocity.Magnitude > 10 then
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end

                        if not isSpecialMovement and not V.SpeedEnabled then
                            if not moving then
                                if hrp.AssemblyLinearVelocity.Magnitude > 30 then
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(hrp.AssemblyLinearVelocity.Y, -15, 15), 0)
                                    if lastStablePos then
                                        hrp.CFrame = CFrame.new(lastStablePos.X, hrp.Position.Y, lastStablePos.Z) * hrp.CFrame.Rotation
                                    end
                                else
                                    lastStablePos = hrp.Position
                                end
                            else
                                lastStablePos = hrp.Position
                            end
                        end
                    end

                    for _, child in pairs(char:GetDescendants()) do
                        if child:IsA("BallSocketConstraint") or (child:IsA("Constraint") and child.Name:lower():find("ragdoll")) then
                            pcall(function() child:Destroy() end)
                        elseif child:IsA("BodyVelocity") or child:IsA("BodyAngularVelocity") or child:IsA("BodyThrust") then
                            if child.Name ~= "GrappleBV" and child.Name ~= "SuperJumpLaunch" and child.Name ~= "FlyVel" and child.Name ~= "VehFlyVel" then
                                pcall(function() child:Destroy() end)
                            end
                        elseif child:IsA("Motor6D") and not child.Enabled then
                            child.Enabled = true
                        elseif child:IsA("BoolValue") then
                            local n = child.Name:lower()
                            if n:find("ragdoll") or n:find("stun") or n:find("knocked") or n:find("down") or n:find("rag") then
                                if child.Value == true then child.Value = false end
                            end
                        end
                    end
                end)
            end)
            addConnection(V.AntiRagdollConn)

            antiRagdollCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                if V.AntiRagdoll then
                    task.wait(0.2)
                    enforceAntiRagdollOnChar(newChar)
                end
            end)
            addConnection(antiRagdollCharConn)

            notify("Protection", "Anti-Ragdoll + Zero Knockback (Immobile) ON", Color3.fromRGB(80, 200, 120))
        else
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
            end
            notify("Protection", "Anti-Ragdoll OFF", Color3.fromRGB(255, 90, 90))
        end
    end)
end
_G.toggleAntiRagdoll = toggleAntiRagdoll

function applyInstant(prompt)
    if V.InstInteract and prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 0
    end
end

function toggleInstantInteract(enabled)
    V.InstInteract = enabled
    if enabled then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then applyInstant(obj) end
        end
        V.Inst1 = workspace.DescendantAdded:Connect(function(obj) applyInstant(obj) end)
        V.Inst2 = ProximityPromptService.PromptShown:Connect(function(prompt) applyInstant(prompt) end)
        addConnection(V.Inst1)
        addConnection(V.Inst2)
        notify("Me","Instant Interact ON", Color3.fromRGB(80, 200, 120))
    else
        if V.Inst1 then V.Inst1:Disconnect() V.Inst1 = nil end
        if V.Inst2 then V.Inst2:Disconnect() V.Inst2 = nil end
        notify("Me","Instant Interact OFF (Rejoin to restore)", Color3.fromRGB(255, 90, 90))
    end
end

function applyInfiniteRange(prompt)
    if V.InfRange and prompt:IsA("ProximityPrompt") then
        if not Cache.Distances[prompt] then
            Cache.Distances[prompt] = {
                MaxActivationDistance = prompt.MaxActivationDistance,
                RequiresLineOfSight = prompt.RequiresLineOfSight
            }
        end
        prompt.MaxActivationDistance = 99999
        prompt.RequiresLineOfSight = false
    end
end

function toggleInfiniteRange(enabled)
    V.InfRange = enabled
    if enabled then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then applyInfiniteRange(obj) end
        end
        V.Inf1 = workspace.DescendantAdded:Connect(function(obj) applyInfiniteRange(obj) end)
        V.Inf2 = ProximityPromptService.PromptShown:Connect(function(prompt) applyInfiniteRange(prompt) end)
        V.InfRangeConn = RunService.RenderStepped:Connect(function()
            for prompt, _ in pairs(Cache.Distances) do
                if prompt and prompt.Parent then
                    prompt.MaxActivationDistance = 99999
                    prompt.RequiresLineOfSight = false
                else
                    Cache.Distances[prompt] = nil
                end
            end
        end)
        addConnection(V.Inf1)
        addConnection(V.Inf2)
        addConnection(V.InfRangeConn)
        notify("Me","Infinite Interact Range ON", Color3.fromRGB(80, 200, 120))
    else
        if V.Inf1 then V.Inf1:Disconnect() V.Inf1 = nil end
        if V.Inf2 then V.Inf2:Disconnect() V.Inf2 = nil end
        if V.InfRangeConn then V.InfRangeConn:Disconnect() V.InfRangeConn = nil end
        for prompt, data in pairs(Cache.Distances) do
            if prompt and prompt.Parent then
                prompt.MaxActivationDistance = data.MaxActivationDistance
                prompt.RequiresLineOfSight = data.RequiresLineOfSight
            end
        end
        Cache.Distances = {}
        notify("Me","Infinite Interact Range OFF", Color3.fromRGB(255, 90, 90))
    end
end

function applyFPSBoost(obj)
    if obj:IsA("BasePart") then
        if not Cache.FPSBoost[obj] then
            Cache.FPSBoost[obj] = {Material = obj.Material, Reflectance = obj.Reflectance}
        end
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        if not Cache.FPSBoost[obj] then
            Cache.FPSBoost[obj] = {Enabled = obj.Enabled}
        end
        obj.Enabled = false
    elseif obj:IsA("PostEffect") then
        if not Cache.FPSBoost[obj] then
            Cache.FPSBoost[obj] = {Enabled = obj.Enabled}
        end
        obj.Enabled = false
    end
end

function toggleFPSBooster(enabled)
    V.FPSBoost = enabled
    if enabled then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
        Lighting.FogStart = 0
        settings().Rendering.QualityLevel = 1

        for _, obj in pairs(workspace:GetDescendants()) do applyFPSBoost(obj) end
        for _, obj in pairs(Lighting:GetChildren()) do applyFPSBoost(obj) end

        V.FPSBoost1 = workspace.DescendantAdded:Connect(function(obj) applyFPSBoost(obj) end)
        V.FPSBoost2 = Lighting.ChildAdded:Connect(function(obj) applyFPSBoost(obj) end)
        notify("Server","FPS Booster ON", Color3.fromRGB(80, 200, 120))
    else
        if V.FPSBoost1 then V.FPSBoost1:Disconnect() V.FPSBoost1 = nil end
        if V.FPSBoost2 then V.FPSBoost2:Disconnect() V.FPSBoost2 = nil end

        for obj, data in pairs(Cache.FPSBoost) do
            if obj and obj.Parent then
                if obj:IsA("BasePart") then
                    obj.Material = data.Material
                    obj.Reflectance = data.Reflectance
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = data.Transparency
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("PostEffect") then
                    obj.Enabled = data.Enabled
                end
            end
        end
        Cache.FPSBoost = {}

        settings().Rendering.QualityLevel = Enum.RenderSettings.DefaultQualityLevel
        Lighting.GlobalShadows = true
        notify("Server","FPS Booster OFF", Color3.fromRGB(255, 90, 90))
    end
end

function toggleFullbright(enabled)
    V.Fullbright = enabled
    if enabled then
        Cache.Lighting = {
            GlobalShadows = Lighting.GlobalShadows,
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            ClockTime = Lighting.ClockTime,
            ExposureCompensation = Lighting.ExposureCompensation
        }
        Lighting.GlobalShadows = false
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.FogEnd = 1e6
        Lighting.FogStart = 0
        Lighting.ClockTime = 14
        Lighting.ExposureCompensation = 0

        Cache.PostEffects = {}
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
                Cache.PostEffects[v] = v.Enabled
                v.Enabled = false
            end
        end
        notify("Server","Fullbright ON", Color3.fromRGB(80, 200, 120))
    else
        if Cache.Lighting then
            Lighting.GlobalShadows = Cache.Lighting.GlobalShadows
            Lighting.Brightness = Cache.Lighting.Brightness
            Lighting.Ambient = Cache.Lighting.Ambient
            Lighting.OutdoorAmbient = Cache.Lighting.OutdoorAmbient
            Lighting.FogEnd = Cache.Lighting.FogEnd
            Lighting.FogStart = Cache.Lighting.FogStart
            Lighting.ClockTime = Cache.Lighting.ClockTime
            Lighting.ExposureCompensation = Cache.Lighting.ExposureCompensation
        end

        if Cache.PostEffects then
            for effect, state in pairs(Cache.PostEffects) do
                if effect and effect.Parent then
                    effect.Enabled = state
                end
            end
        end
        Cache.Lighting = nil
        Cache.PostEffects = nil
        notify("Server","Fullbright OFF", Color3.fromRGB(255, 90, 90))
    end
end

ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "NebulaESP"
ESPGui.ResetOnSpawn = false
ESPGui.DisplayOrder = 100
ESPGui.IgnoreGuiInset = true
ESPGui.Enabled = false
ESPGui.Parent = parentTarget

function clearESP()
    for player, obj in pairs(V.ESPObjects) do
        if obj.conn then obj.conn:Disconnect() end
        if obj.box then obj.box:Destroy() end
        if obj.nameLabel then obj.nameLabel:Destroy() end
        if obj.distLabel then obj.distLabel:Destroy() end
        if obj.highlight then obj.highlight:Destroy() end
        if obj.healthBg then obj.healthBg:Destroy() end
        if obj.healthPvText then obj.healthPvText:Destroy() end
        if obj.weaponLabel then obj.weaponLabel:Destroy() end
        if obj.skeletonFolder then obj.skeletonFolder:Destroy() end
        if obj.tracerLine then obj.tracerLine:Destroy() end
    end
    V.ESPObjects = {}
end

function createESPForCharacter(charInstance, customName)
    if not charInstance or V.ESPObjects[charInstance] then return end
    if charInstance == LocalPlayer.Character and not V.ESPSelf then return end

    local box = Instance.new("Frame")
    box.Visible = false
    box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = ESPGui

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1.5
    boxStroke.Parent = box

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Visible = false
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 13
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextColor3 = V.ESPColor
    nameLabel.Parent = ESPGui

    local distLabel = Instance.new("TextLabel")
    distLabel.Visible = false
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.TextSize = 12
    distLabel.TextStrokeTransparency = 0
    distLabel.TextColor3 = V.ESPColor
    distLabel.Parent = ESPGui

    local highlight = Instance.new("Highlight")
    highlight.FillColor = V.ESPColor
    highlight.OutlineColor = V.ESPColor
    highlight.FillTransparency = 0.5
    highlight.Enabled = false
    highlight.Parent = nil

    local healthBg = Instance.new("Frame")
    healthBg.Visible = false
    healthBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = ESPGui

    local healthBar = Instance.new("Frame")
    healthBar.BorderSizePixel = 0
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    healthBar.Parent = healthBg

    local healthPvText = Instance.new("TextLabel")
    healthPvText.Visible = false
    healthPvText.BackgroundTransparency = 1
    healthPvText.Font = Enum.Font.GothamBold
    healthPvText.TextSize = 10
    healthPvText.TextStrokeTransparency = 0
    healthPvText.TextColor3 = Color3.fromRGB(0, 230, 120)
    healthPvText.Parent = ESPGui

    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Visible = false
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.Font = Enum.Font.GothamMedium
    weaponLabel.TextSize = 11
    weaponLabel.TextStrokeTransparency = 0
    weaponLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
    weaponLabel.Parent = ESPGui

    local skeletonFolder = Instance.new("Folder")
    skeletonFolder.Name = "SkeletonLines_" .. (customName or charInstance.Name)
    skeletonFolder.Parent = ESPGui

    local tracerLine = Instance.new("Frame")
    tracerLine.Visible = false
    tracerLine.BorderSizePixel = 0
    tracerLine.BackgroundColor3 = V.ESPColor
    tracerLine.AnchorPoint = Vector2.new(0.5, 0.5)
    tracerLine.Parent = ESPGui

    V.ESPObjects[charInstance] = {
        box = box, boxStroke = boxStroke, nameLabel = nameLabel, distLabel = distLabel, highlight = highlight,
        healthBg = healthBg, healthBar = healthBar, healthPvText = healthPvText, weaponLabel = weaponLabel, skeletonFolder = skeletonFolder, tracerLine = tracerLine
    }

    local conn = RunService.RenderStepped:Connect(function()
        local char = charInstance
        if not char or not char.Parent or not V.ESP then
            box.Visible = false
            nameLabel.Visible = false
            distLabel.Visible = false
            highlight.Parent = nil
            healthBg.Visible = false
            healthPvText.Visible = false
            weaponLabel.Visible = false
            skeletonFolder:ClearAllChildren()
            tracerLine.Visible = false
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
        local head = char:FindFirstChild("Head") or hrp
        local hum = char:FindFirstChildOfClass("Humanoid")
        local localChar = LocalPlayer.Character
        if not hrp or not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
            box.Visible = false
            nameLabel.Visible = false
            distLabel.Visible = false
            highlight.Parent = nil
            healthBg.Visible = false
            healthPvText.Visible = false
            weaponLabel.Visible = false
            skeletonFolder:ClearAllChildren()
            tracerLine.Visible = false
            return
        end

        local localHrp = localChar.HumanoidRootPart
        local dist = (localHrp.Position - hrp.Position).Magnitude

        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen or screenPos.Z <= 0 then
            box.Visible = false
            nameLabel.Visible = false
            distLabel.Visible = false
            highlight.Parent = nil
            healthBg.Visible = false
            healthPvText.Visible = false
            weaponLabel.Visible = false
            for _, child in ipairs(skeletonFolder:GetChildren()) do
                child.Visible = false
            end
            tracerLine.Visible = false
            return
        end

        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local rawHeight = math.abs(headPos.Y - legPos.Y)
        
        local height = math.clamp(rawHeight, 20, 600)
        local width = height / 2.5

        local boxVisible = V.ESPBox or V.ESPFilled
        if boxVisible then
            box.Visible = true
            box.Size = UDim2.new(0, width, 0, height)
            box.Position = UDim2.new(0, screenPos.X - width/2, 0, screenPos.Y - height/2)
            boxStroke.Color = V.ESPColor
            boxStroke.Thickness = V.ESPBox and 1.5 or 0
            if V.ESPFilled then
                box.BackgroundColor3 = V.ESPColor
                box.BackgroundTransparency = 0.75
            else
                box.BackgroundTransparency = 1
            end
        else
            box.Visible = false
        end

        if V.ESPGlow then
            highlight.Parent = char
            highlight.FillColor = V.ESPColor
            highlight.OutlineColor = V.ESPColor
            highlight.Enabled = true
        else
            highlight.Parent = nil
        end

        if V.ESPName then
            nameLabel.Visible = true
            nameLabel.Text = customName or char.Name
            nameLabel.TextColor3 = V.ESPColor
            nameLabel.Size = UDim2.new(0, 200, 0, 20)
            nameLabel.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y - height/2 - 18)
        else
            nameLabel.Visible = false
        end

        if V.ESPDist then
            distLabel.Visible = true
            distLabel.Text = math.floor(dist) .."m"
            distLabel.TextColor3 = V.ESPColor
            distLabel.Size = UDim2.new(0, 200, 0, 20)
            distLabel.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y + height/2 + 2)
        else
            distLabel.Visible = false
        end

        if V.ESPHealth and hum then
            healthBg.Visible = true
            local barWidth = 4
            healthBg.Size = UDim2.new(0, barWidth, 0, height)
            healthBg.Position = UDim2.new(0, screenPos.X - width/2 - 7, 0, screenPos.Y - height/2)
            
            local healthPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            healthBar.Size = UDim2.new(1, 0, healthPct, 0)
            healthBar.Position = UDim2.new(0, 0, 1 - healthPct, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - healthPct)), math.floor(255 * healthPct), 50)
        else
            healthBg.Visible = false
        end

        if V.ESPPV and hum then
            healthPvText.Visible = true
            local curHp = math.floor(hum.Health + 0.5)
            local maxHp = math.max(hum.MaxHealth, 1)
            local hpRatio = math.clamp(curHp / maxHp, 0, 1)
            healthPvText.Text = tostring(curHp) .. " PV"
            healthPvText.Size = UDim2.new(0, 48, 0, 14)
            healthPvText.Position = UDim2.new(0, screenPos.X - width/2 - 28, 0, screenPos.Y + height/2 + 2)
            healthPvText.TextColor3 = Color3.fromRGB(math.floor(255 * (1 - hpRatio)), math.floor(255 * hpRatio), 60)
        else
            healthPvText.Visible = false
        end

        if (V.ESPPV or HealthPV_Enabled) and hum and (V.ESPHealth or V.ESP) then
            healthPvText.Visible = true
            local curHp = math.max(0, math.floor(hum.Health))
            healthPvText.Text = curHp .. " PV"
            healthPvText.Size = UDim2.new(0, 48, 0, 14)
            healthPvText.Position = UDim2.new(0, screenPos.X - width/2 - 28, 0, screenPos.Y + height/2 + 2)
            local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            healthPvText.TextColor3 = Color3.fromRGB(math.floor(255 * (1 - hpRatio)), math.floor(255 * hpRatio), 60)
        else
            healthPvText.Visible = false
        end

        if V.ESPWeapon then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                weaponLabel.Visible = true
                weaponLabel.Text ="[".. tool.Name .."]"
                weaponLabel.Size = UDim2.new(0, 200, 0, 16)
                weaponLabel.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y + height/2 + (V.ESPDist and 22 or 2))
            else
                weaponLabel.Visible = false
            end
        else
            weaponLabel.Visible = false
        end

        if V.ESPSkeleton and hum and onScreen and screenPos.Z > 0 then
            local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
            local joints = isR15 and {
                {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
                {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
                {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
                {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
                {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"}
            } or {
                {"Head","Torso"},
                {"Torso","Left Arm"}, {"Torso","Right Arm"},
                {"Torso","Left Leg"}, {"Torso","Right Leg"}
            }

            local existingLines = skeletonFolder:GetChildren()
            local lineIdx = 0
            local vp = Camera.ViewportSize
            
            for _, pair in ipairs(joints) do
                local p1Part = char:FindFirstChild(pair[1])
                local p2Part = char:FindFirstChild(pair[2])
                if p1Part and p2Part then
                    local p1Pos, onScreen1 = Camera:WorldToViewportPoint(p1Part.Position)
                    local p2Pos, onScreen2 = Camera:WorldToViewportPoint(p2Part.Position)
                    if onScreen1 and onScreen2 and p1Pos.Z > 0 and p2Pos.Z > 0 then
                        if p1Pos.X >= 0 and p1Pos.X <= vp.X and p1Pos.Y >= 0 and p1Pos.Y <= vp.Y and
                           p2Pos.X >= 0 and p2Pos.X <= vp.X and p2Pos.Y >= 0 and p2Pos.Y <= vp.Y then
                            lineIdx = lineIdx + 1
                            local line = existingLines[lineIdx]
                            if not line then
                                line = Instance.new("Frame")
                                line.BorderSizePixel = 0
                                line.AnchorPoint = Vector2.new(0.5, 0.5)
                                line.Parent = skeletonFolder
                            end
                            local distance = (Vector2.new(p2Pos.X, p2Pos.Y) - Vector2.new(p1Pos.X, p1Pos.Y)).Magnitude
                            local angle = math.atan2(p2Pos.Y - p1Pos.Y, p2Pos.X - p1Pos.X)
                            line.BackgroundColor3 = V.ESPColor
                            line.Size = UDim2.new(0, distance, 0, 1.5)
                            line.Position = UDim2.new(0, (p1Pos.X + p2Pos.X) / 2, 0, (p1Pos.Y + p2Pos.Y) / 2)
                            line.Rotation = math.deg(angle)
                            line.Visible = true
                        end
                    end
                end
            end
            
            for i = lineIdx + 1, #existingLines do
                existingLines[i].Visible = false
            end
        else
            for _, child in ipairs(skeletonFolder:GetChildren()) do
                child.Visible = false
            end
        end

        if V.ESPTracer and onScreen and screenPos.Z > 0 then
            local vp = Camera.ViewportSize
            local originPos = Vector2.new(vp.X / 2, vp.Y)
            if V.ESPTracerOrigin =="Center"then
                originPos = Vector2.new(vp.X / 2, vp.Y / 2)
            elseif V.ESPTracerOrigin =="Mouse"then
                originPos = UserInputService:GetMouseLocation()
            end
            local targetPos = Vector2.new(screenPos.X, screenPos.Y)
            if targetPos.X >= 0 and targetPos.X <= vp.X and targetPos.Y >= 0 and targetPos.Y <= vp.Y then
                local distance = (targetPos - originPos).Magnitude
                local angle = math.atan2(targetPos.Y - originPos.Y, targetPos.X - originPos.X)
                tracerLine.Visible = true
                tracerLine.Size = UDim2.new(0, distance, 0, 1.5)
                tracerLine.Position = UDim2.new(0, (originPos.X + targetPos.X) / 2, 0, (originPos.Y + targetPos.Y) / 2)
                tracerLine.Rotation = math.deg(angle)
                tracerLine.BackgroundColor3 = V.ESPColor
            else
                tracerLine.Visible = false
            end
        else
            tracerLine.Visible = false
        end
    end)
    V.ESPObjects[charInstance].conn = conn
end

function createESPForPlayer(player)
    if V.ESPObjects[player] then return end
    if player == LocalPlayer and not V.ESPSelf then return end

    local box = Instance.new("Frame")
    box.Visible = false
    box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = ESPGui

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1.5
    boxStroke.Parent = box

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Visible = false
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 13
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextColor3 = V.ESPColor
    nameLabel.Parent = ESPGui

    local distLabel = Instance.new("TextLabel")
    distLabel.Visible = false
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.TextSize = 12
    distLabel.TextStrokeTransparency = 0
    distLabel.TextColor3 = V.ESPColor
    distLabel.Parent = ESPGui

    local highlight = Instance.new("Highlight")
    highlight.FillColor = V.ESPColor
    highlight.OutlineColor = V.ESPColor
    highlight.FillTransparency = 0.5
    highlight.Enabled = false
    highlight.Parent = nil

    local healthBg = Instance.new("Frame")
    healthBg.Visible = false
    healthBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = ESPGui

    local healthBar = Instance.new("Frame")
    healthBar.BorderSizePixel = 0
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    healthBar.Parent = healthBg

    local healthPvText = Instance.new("TextLabel")
    healthPvText.Visible = false
    healthPvText.BackgroundTransparency = 1
    healthPvText.Font = Enum.Font.GothamBold
    healthPvText.TextSize = 10
    healthPvText.TextStrokeTransparency = 0
    healthPvText.TextColor3 = Color3.fromRGB(0, 230, 120)
    healthPvText.Parent = ESPGui

    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Visible = false
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.Font = Enum.Font.GothamMedium
    weaponLabel.TextSize = 11
    weaponLabel.TextStrokeTransparency = 0
    weaponLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
    weaponLabel.Parent = ESPGui

    local skeletonFolder = Instance.new("Folder")
    skeletonFolder.Name ="SkeletonLines_".. player.Name
    skeletonFolder.Parent = ESPGui

    local tracerLine = Instance.new("Frame")
    tracerLine.Visible = false
    tracerLine.BorderSizePixel = 0
    tracerLine.BackgroundColor3 = V.ESPColor
    tracerLine.AnchorPoint = Vector2.new(0.5, 0.5)
    tracerLine.Parent = ESPGui

    V.ESPObjects[player] = {
        box = box, boxStroke = boxStroke, nameLabel = nameLabel, distLabel = distLabel, highlight = highlight,
        healthBg = healthBg, healthBar = healthBar, healthPvText = healthPvText, weaponLabel = weaponLabel, skeletonFolder = skeletonFolder, tracerLine = tracerLine
    }

    local conn = RunService.RenderStepped:Connect(function()
        local char = player.Character
        local isTeam = false
        if V.ESPTeamCheck and player ~= LocalPlayer then
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                isTeam = true
            elseif player.TeamColor and LocalPlayer.TeamColor and player.TeamColor == LocalPlayer.TeamColor then
                isTeam = true
            end
        end
        if not char or not V.ESP or isTeam then
            box.Visible = false
            nameLabel.Visible = false
            distLabel.Visible = false
            highlight.Parent = nil
            healthBg.Visible = false
            if healthPvText then healthPvText.Visible = false end
            weaponLabel.Visible = false
            if skeletonFolder then
                for _, child in ipairs(skeletonFolder:GetChildren()) do
                    child.Visible = false
                end
            end
            if tracerLine then tracerLine.Visible = false end
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local localChar = LocalPlayer.Character
        if not hrp or not head or not hum or not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
            box.Visible = false
            nameLabel.Visible = false
            distLabel.Visible = false
            highlight.Parent = nil
            healthBg.Visible = false
            if healthPvText then healthPvText.Visible = false end
            weaponLabel.Visible = false
            if skeletonFolder then
                for _, child in ipairs(skeletonFolder:GetChildren()) do
                    child.Visible = false
                end
            end
            if tracerLine then tracerLine.Visible = false end
            return
        end

        local localHrp = localChar.HumanoidRootPart
        local dist = (localHrp.Position - hrp.Position).Magnitude

        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen or screenPos.Z <= 0 then
            box.Visible = false
            nameLabel.Visible = false
            distLabel.Visible = false
            highlight.Parent = nil
            healthBg.Visible = false
            if healthPvText then healthPvText.Visible = false end
            weaponLabel.Visible = false
            if skeletonFolder then
                for _, child in ipairs(skeletonFolder:GetChildren()) do
                    child.Visible = false
                end
            end
            if tracerLine then tracerLine.Visible = false end
            return
        end

        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local rawHeight = math.abs(headPos.Y - legPos.Y)
        
        local height = math.clamp(rawHeight, 20, 600)
        local width = height / 2.5

        local boxVisible = V.ESPBox or V.ESPFilled
        if boxVisible then
            box.Visible = true
            box.Size = UDim2.new(0, width, 0, height)
            box.Position = UDim2.new(0, screenPos.X - width/2, 0, screenPos.Y - height/2)
            boxStroke.Color = V.ESPColor
            boxStroke.Thickness = V.ESPBox and 1.5 or 0
            if V.ESPFilled then
                box.BackgroundColor3 = V.ESPColor
                box.BackgroundTransparency = 0.75
            else
                box.BackgroundTransparency = 1
            end
        else
            box.Visible = false
        end

        if V.ESPGlow then
            highlight.Parent = char
            highlight.FillColor = V.ESPColor
            highlight.OutlineColor = V.ESPColor
            highlight.Enabled = true
        else
            highlight.Parent = nil
        end

        if V.ESPName then
            nameLabel.Visible = true
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = V.ESPColor
            nameLabel.Size = UDim2.new(0, 200, 0, 20)
            nameLabel.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y - height/2 - 18)
        else
            nameLabel.Visible = false
        end

        if V.ESPDist then
            distLabel.Visible = true
            distLabel.Text = math.floor(dist) .."m"
            distLabel.TextColor3 = V.ESPColor
            distLabel.Size = UDim2.new(0, 200, 0, 20)
            distLabel.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y + height/2 + 2)
        else
            distLabel.Visible = false
        end

        if V.ESPHealth then
            healthBg.Visible = true
            local barWidth = 4
            healthBg.Size = UDim2.new(0, barWidth, 0, height)
            healthBg.Position = UDim2.new(0, screenPos.X - width/2 - 7, 0, screenPos.Y - height/2)
            
            local healthPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            healthBar.Size = UDim2.new(1, 0, healthPct, 0)
            healthBar.Position = UDim2.new(0, 0, 1 - healthPct, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - healthPct)), math.floor(255 * healthPct), 50)
        else
            healthBg.Visible = false
        end

        if (V.ESPPV or HealthPV_Enabled) and hum then
            healthPvText.Visible = true
            local curHp = math.floor(hum.Health + 0.5)
            local maxHp = math.max(hum.MaxHealth, 1)
            local hpRatio = math.clamp(curHp / maxHp, 0, 1)
            healthPvText.Text = tostring(curHp) .. " PV"
            healthPvText.Size = UDim2.new(0, 48, 0, 14)
            healthPvText.Position = UDim2.new(0, screenPos.X - width/2 - 28, 0, screenPos.Y + height/2 + 2)
            healthPvText.TextColor3 = Color3.fromRGB(math.floor(255 * (1 - hpRatio)), math.floor(255 * hpRatio), 60)
        else
            healthPvText.Visible = false
        end

        if V.ESPWeapon then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                weaponLabel.Visible = true
                weaponLabel.Text ="[".. tool.Name .."]"
                weaponLabel.Size = UDim2.new(0, 200, 0, 16)
                weaponLabel.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y + height/2 + (V.ESPDist and 22 or 2))
            else
                weaponLabel.Visible = false
            end
        else
            weaponLabel.Visible = false
        end

        if V.ESPSkeleton and hum and onScreen and screenPos.Z > 0 then
            local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
            local joints = isR15 and {
                {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
                {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
                {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
                {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
                {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"}
            } or {
                {"Head","Torso"},
                {"Torso","Left Arm"}, {"Torso","Right Arm"},
                {"Torso","Left Leg"}, {"Torso","Right Leg"}
            }

            local existingLines = skeletonFolder:GetChildren()
            local lineIdx = 0
            local vp = Camera.ViewportSize
            
            for _, pair in ipairs(joints) do
                local p1Part = char:FindFirstChild(pair[1])
                local p2Part = char:FindFirstChild(pair[2])
                if p1Part and p2Part then
                    local p1Pos, onScreen1 = Camera:WorldToViewportPoint(p1Part.Position)
                    local p2Pos, onScreen2 = Camera:WorldToViewportPoint(p2Part.Position)
                    if onScreen1 and onScreen2 and p1Pos.Z > 0 and p2Pos.Z > 0 then
                        if p1Pos.X >= 0 and p1Pos.X <= vp.X and p1Pos.Y >= 0 and p1Pos.Y <= vp.Y and
                           p2Pos.X >= 0 and p2Pos.X <= vp.X and p2Pos.Y >= 0 and p2Pos.Y <= vp.Y then
                            lineIdx = lineIdx + 1
                            local line = existingLines[lineIdx]
                            if not line then
                                line = Instance.new("Frame")
                                line.BorderSizePixel = 0
                                line.AnchorPoint = Vector2.new(0.5, 0.5)
                                line.Parent = skeletonFolder
                            end
                            local distance = (Vector2.new(p2Pos.X, p2Pos.Y) - Vector2.new(p1Pos.X, p1Pos.Y)).Magnitude
                            local angle = math.atan2(p2Pos.Y - p1Pos.Y, p2Pos.X - p1Pos.X)
                            line.BackgroundColor3 = V.ESPColor
                            line.Size = UDim2.new(0, distance, 0, 1.5)
                            line.Position = UDim2.new(0, (p1Pos.X + p2Pos.X) / 2, 0, (p1Pos.Y + p2Pos.Y) / 2)
                            line.Rotation = math.deg(angle)
                            line.Visible = true
                        end
                    end
                end
            end
            
            for i = lineIdx + 1, #existingLines do
                existingLines[i].Visible = false
            end
        else
            for _, child in ipairs(skeletonFolder:GetChildren()) do
                child.Visible = false
            end
        end

        if V.ESPTracer and onScreen and screenPos.Z > 0 then
            local vp = Camera.ViewportSize
            local originPos = Vector2.new(vp.X / 2, vp.Y)
            if V.ESPTracerOrigin =="Center"then
                originPos = Vector2.new(vp.X / 2, vp.Y / 2)
            elseif V.ESPTracerOrigin =="Mouse"then
                originPos = UserInputService:GetMouseLocation()
            end
            local targetPos = Vector2.new(screenPos.X, screenPos.Y)
            if targetPos.X >= 0 and targetPos.X <= vp.X and targetPos.Y >= 0 and targetPos.Y <= vp.Y then
                local distance = (targetPos - originPos).Magnitude
                local angle = math.atan2(targetPos.Y - originPos.Y, targetPos.X - originPos.X)
                tracerLine.Visible = true
                tracerLine.Size = UDim2.new(0, distance, 0, 1.5)
                tracerLine.Position = UDim2.new(0, (originPos.X + targetPos.X) / 2, 0, (originPos.Y + targetPos.Y) / 2)
                tracerLine.Rotation = math.deg(angle)
                tracerLine.BackgroundColor3 = V.ESPColor
            else
                tracerLine.Visible = false
            end
        else
            tracerLine.Visible = false
        end
    end)
    V.ESPObjects[player].conn = conn
end

function isNPCModel(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
    return (hum ~= nil and root ~= nil and hum.Health > 0)
end

function refreshESP()
    clearESP()
    if not V.ESP then return end
    for _, player in pairs(Players:GetPlayers()) do createESPForPlayer(player) end
    if V.ESPNPC then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isNPCModel(obj) then
                createESPForCharacter(obj, "[NPC] " .. obj.Name)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1.5)
        if V.ESP then
            for _, player in pairs(Players:GetPlayers()) do
                if not V.ESPObjects[player] then createESPForPlayer(player) end
            end
            if V.ESPNPC then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if isNPCModel(obj) and not V.ESPObjects[obj] then
                        createESPForCharacter(obj, "[NPC] " .. obj.Name)
                    end
                end
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    if _G.refreshPlayerList then _G.refreshPlayerList() end
    if V.ESP then
        task.wait(0.5)
        createESPForPlayer(p)
    end
end)
Players.PlayerRemoving:Connect(function(p)
    if _G.refreshPlayerList then _G.refreshPlayerList() end
    if V.SelPlayer == p then
        stopSpectate()
    end
    if V.ESPObjects[p] then
        if V.ESPObjects[p].conn then V.ESPObjects[p].conn:Disconnect() end
        if V.ESPObjects[p].box then V.ESPObjects[p].box:Destroy() end
        if V.ESPObjects[p].nameLabel then V.ESPObjects[p].nameLabel:Destroy() end
        if V.ESPObjects[p].distLabel then V.ESPObjects[p].distLabel:Destroy() end
        if V.ESPObjects[p].highlight then V.ESPObjects[p].highlight:Destroy() end
        if V.ESPObjects[p].healthBg then V.ESPObjects[p].healthBg:Destroy() end
        if V.ESPObjects[p].healthPvText then V.ESPObjects[p].healthPvText:Destroy() end
        if V.ESPObjects[p].weaponLabel then V.ESPObjects[p].weaponLabel:Destroy() end
        if V.ESPObjects[p].skeletonFolder then V.ESPObjects[p].skeletonFolder:Destroy() end
        if V.ESPObjects[p].tracerLine then V.ESPObjects[p].tracerLine:Destroy() end
        V.ESPObjects[p] = nil
    end
end)

function toggleClickTP(enabled)
    V.ClickTP = enabled
    if enabled then
        if V.ClickTPTool then V.ClickTPTool:Destroy() end
        V.ClickTPTool = Instance.new("Tool")
        V.ClickTPTool.Name ="Click TP Épée"
        V.ClickTPTool.RequiresHandle = true
        local handle = Instance.new("Part")
        handle.Name ="Handle"
        handle.Size = Vector3.new(1, 1, 3)
        handle.CanCollide = false
        handle.Transparency = 1
        handle.Parent = V.ClickTPTool
        
        V.ClickTPTool.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local char = getCharacter()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and mouse.Hit then
                hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end)
        V.ClickTPTool.Parent = LocalPlayer.Backpack
        notify("Fun","Épée Click TP ajoutée !", Color3.fromRGB(80, 200, 120))
    else
        if V.ClickTPTool then
            if V.ClickTPTool.Parent == LocalPlayer.Character then
                V.ClickTPTool:Destroy()
            elseif V.ClickTPTool.Parent == LocalPlayer.Backpack then
                V.ClickTPTool:Destroy()
            end
            V.ClickTPTool = nil
        end
        notify("Fun","Épée Click TP retirée.", Color3.fromRGB(255, 90, 90))
    end
end
initStep = "cablage Movement"
createLabel("CLAVIER AZERTY (ZQSD)", MovementContent)
createToggle("Deplacement Clavier AZERTY (ZQSD)", true, function(enabled)
    V.KeyboardLayout = enabled and "AZERTY" or "QWERTY"
    notify("Movement", enabled and "Touches AZERTY (Z:Avancer Q:Gauche S:Reculer D:Droite) ACTIVES" or "Mode QWERTY Actif", Color3.fromRGB(80, 200, 120))
end, MovementContent, "AZERTYLayout")
createLabel("SPEED & JUMP", MovementContent)
_, _, ToggleSpeed = createToggle("Enable Walk Speed", false, function(enabled)
    V.SpeedEnabled = enabled
    if not enabled then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum and not V.VelocitySpoof then hum.WalkSpeed = 16 end
            if hrp then
                local yVel = hrp.AssemblyLinearVelocity.Y
                hrp.AssemblyLinearVelocity = Vector3.new(0, yVel, 0)
            end
        end)
    end
    notify("Movement","Walk Speed ".. (enabled and "ON" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, MovementContent,"SpeedEnabled")
createSlider("Walk Speed", 16, 300, 16, function(val) V.Speed = val end, MovementContent,"Speed")

function createValueButton(parent, title, valueText, onChange, configKey)
    local card = createCard(parent, 0, 42)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.55, -10, 0, 16)
    titleLabel.Position = UDim2.new(0, 12, 0, 13)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.text
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 11
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = card

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, -10, 0, 16)
    valueLabel.Position = UDim2.new(0.55, 2, 0, 13)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = valueText
    valueLabel.TextColor3 = theme.accent2
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 10
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 64, 0, 24)
    btn.Position = UDim2.new(1, -74, 0.5, -12)
    btn.BackgroundColor3 = theme.cardHover
    btn.BorderSizePixel = 0
    btn.Text = "Changer"
    btn.TextColor3 = theme.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.Parent = card
    makeCorner(btn, 7)
    makeStroke(btn, theme.border, 1)
    btn.MouseButton1Click:Connect(function()
        playClick()
        if onChange then
            local newValue = onChange()
            if newValue then
                valueLabel.Text = tostring(newValue)
            end
        end
    end)

    if configKey then
        ConfigRegistry[configKey] = function(val)
            if val ~= nil then
                V[configKey] = val
                valueLabel.Text = tostring(val)
            end
        end
    end

    registerSearchCard(card, title, parent)

    return card, btn, valueLabel
end

speedMethodsList = {"Anti-TP CFrame (Recommandé)", "Humanoid", "Velocity", "VectorForce"}
currentSpeedMethodIdx = 1
speedMethodFrame, speedMethodBtnObj, speedMethodValue = createValueButton(MovementContent, "Speed Method", V.SpeedMethod, function()
    local foundIdx = table.find(speedMethodsList, V.SpeedMethod)
    if foundIdx then currentSpeedMethodIdx = foundIdx end
    currentSpeedMethodIdx = (currentSpeedMethodIdx % #speedMethodsList) + 1
    V.SpeedMethod = speedMethodsList[currentSpeedMethodIdx]
    notify("Movement","Méthode de vitesse : ".. V.SpeedMethod, Color3.fromRGB(80, 200, 120))
    return V.SpeedMethod
end, "SpeedMethod")

createToggle("Enable Jump Power", false, function(enabled)
    V.JumpEnabled = enabled
    if not enabled then
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if _OrigUseJumpPower ~= nil then
                    hum.UseJumpPower = _OrigUseJumpPower
                end
                if _OrigJumpPower then
                    hum.JumpPower = _OrigJumpPower
                else
                    hum.JumpPower = 50
                end
                if _OrigJumpHeight then
                    hum.JumpHeight = _OrigJumpHeight
                end
            end
        end)
    end
    notify("Movement","Jump Power ".. (enabled and "ON" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, MovementContent,"JumpEnabled")
createSlider("Jump Power", 50, 300, 50, function(val) V.Jump = val end, MovementContent,"Jump")

createToggle("Wall Climb (Spider)", false, function(enabled)
    V.WallClimb = enabled
    if not enabled then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                hum.PlatformStand = false
                hum.Sit = false
                local _, ry, _ = hrp.CFrame:ToOrientation()
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, ry, 0)
                if hum:GetState() == Enum.HumanoidStateType.Climbing then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
    notify("Movement","Wall Climb ".. (enabled and "ON" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, MovementContent,"WallClimb")

function setupInfiniteStamina(enabled)
    V.InfiniteStamina = enabled
    if V.InfiniteStaminaConn then
        V.InfiniteStaminaConn:Disconnect()
        V.InfiniteStaminaConn = nil
    end
    if V.InfiniteStaminaTask then
        task.cancel(V.InfiniteStaminaTask)
        V.InfiniteStaminaTask = nil
    end
    if V.InfiniteStaminaSubConns then
        for _, conn in ipairs(V.InfiniteStaminaSubConns) do
            pcall(function() conn:Disconnect() end)
        end
        V.InfiniteStaminaSubConns = nil
    end

    if enabled then
        V.InfiniteStaminaSubConns = {}
        local staminaKeywords = {
            "stamina", "energy", "sprint", "sprintenergy", "staminabar",
            "sprintvalue", "dashstamina", "runenergy", "endurance", "fatigue",
            "sprintstamina", "playerstamina"
        }

        local function isStaminaName(str)
            local s = string.lower(tostring(str))
            for _, kw in ipairs(staminaKeywords) do
                if string.find(s, kw, 1, true) then return true end
            end
            return false
        end

        local function lockObject(obj)
            if not obj then return end
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                if isStaminaName(obj.Name) then
                    local maxVal = obj:FindFirstChild("MaxValue") or obj:FindFirstChild("Max")
                    local target = (maxVal and maxVal.Value) or 100
                    pcall(function() obj.Value = target end)
                    local c = obj.Changed:Connect(function(newVal)
                        if not V.InfiniteStamina then return end
                        if newVal < target then
                            task.defer(function()
                                if V.InfiniteStamina and obj and obj.Parent then
                                    pcall(function() obj.Value = target end)
                                end
                            end)
                        end
                    end)
                    table.insert(V.InfiniteStaminaSubConns, c)
                end
            elseif obj:IsA("BoolValue") then
                local lowerName = string.lower(obj.Name)
                if lowerName == "exhausted" or lowerName == "tired" or lowerName == "outofbreath" then
                    pcall(function() obj.Value = false end)
                    local c = obj.Changed:Connect(function(newVal)
                        if not V.InfiniteStamina then return end
                        if newVal == true then
                            task.defer(function()
                                if V.InfiniteStamina and obj and obj.Parent then
                                    pcall(function() obj.Value = false end)
                                end
                            end)
                        end
                    end)
                    table.insert(V.InfiniteStaminaSubConns, c)
                end
            end
        end

        local function bindCharacter(char)
            if not char then return end
            pcall(function()
                local attrs = char:GetAttributes()
                for attrName, val in pairs(attrs) do
                    if isStaminaName(attrName) then
                        if type(val) == "number" then
                            char:SetAttribute(attrName, 100)
                        elseif type(val) == "boolean" and (string.find(string.lower(attrName), "tired") or string.find(string.lower(attrName), "exhaust")) then
                            char:SetAttribute(attrName, false)
                        end
                    end
                end
            end)

            local attrConn = char.AttributeChanged:Connect(function(attrName)
                if not V.InfiniteStamina then return end
                if isStaminaName(attrName) then
                    local cur = char:GetAttribute(attrName)
                    if type(cur) == "number" and cur < 100 then
                        char:SetAttribute(attrName, 100)
                    elseif type(cur) == "boolean" and cur == true and (string.find(string.lower(attrName), "tired") or string.find(string.lower(attrName), "exhaust")) then
                        char:SetAttribute(attrName, false)
                    end
                end
            end)
            table.insert(V.InfiniteStaminaSubConns, attrConn)

            for _, child in ipairs(char:GetChildren()) do
                lockObject(child)
                if child:IsA("Folder") or child:IsA("Configuration") or child.Name == "Stats" or child.Name == "Values" then
                    for _, sub in ipairs(child:GetChildren()) do
                        lockObject(sub)
                    end
                end
            end

            local childConn = char.ChildAdded:Connect(function(child)
                if not V.InfiniteStamina then return end
                lockObject(child)
                if child:IsA("Folder") or child:IsA("Configuration") then
                    for _, sub in ipairs(child:GetChildren()) do
                        lockObject(sub)
                    end
                end
            end)
            table.insert(V.InfiniteStaminaSubConns, childConn)
        end

        local char = LocalPlayer.Character
        if char then bindCharacter(char) end

        local charAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            task.wait(0.3)
            if V.InfiniteStamina then
                bindCharacter(newChar)
            end
        end)
        table.insert(V.InfiniteStaminaSubConns, charAddedConn)

        V.InfiniteStaminaTask = task.spawn(function()
            while V.InfiniteStamina do
                pcall(function()
                    local c = LocalPlayer.Character
                    if c then
                        for attr, val in pairs(c:GetAttributes()) do
                            if isStaminaName(attr) and type(val) == "number" and val < 100 then
                                c:SetAttribute(attr, 100)
                            end
                        end
                        for _, desc in ipairs(c:GetDescendants()) do
                            if (desc:IsA("NumberValue") or desc:IsA("IntValue")) and isStaminaName(desc.Name) then
                                local maxVal = desc:FindFirstChild("MaxValue") or desc:FindFirstChild("Max")
                                local target = (maxVal and maxVal.Value) or 100
                                if desc.Value < target then desc.Value = target end
                            elseif desc:IsA("BoolValue") and (desc.Name == "Exhausted" or desc.Name == "Tired") then
                                desc.Value = false
                            end
                        end
                    end
                    for attr, val in pairs(LocalPlayer:GetAttributes()) do
                        if isStaminaName(attr) and type(val) == "number" and val < 100 then
                            LocalPlayer:SetAttribute(attr, 100)
                        end
                    end
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    if pg then
                        for _, desc in ipairs(pg:GetDescendants()) do
                            if (desc:IsA("NumberValue") or desc:IsA("IntValue")) and isStaminaName(desc.Name) then
                                local maxVal = desc:FindFirstChild("MaxValue") or desc:FindFirstChild("Max")
                                local target = (maxVal and maxVal.Value) or 100
                                if desc.Value < target then desc.Value = target end
                            end
                        end
                    end
                end)
                task.wait(0.15)
            end
        end)

        notify("Movement", "Infinite Stamina ACTIVÉ (0 Lag)", Color3.fromRGB(80, 200, 120))
    else
        notify("Movement", "Infinite Stamina DÉSACTIVÉ", Color3.fromRGB(255, 90, 90))
    end
end
_G.setupInfiniteStamina = setupInfiniteStamina

createToggle("Infinite Stamina (Sprint Infini)", false, function(enabled)
    setupInfiniteStamina(enabled)
end, MovementContent, "InfiniteStamina")

superJumpPressTime = nil
superJumpChargeTask = nil
superJumpChargeRing = nil

function createChargeEffect(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        local a = Instance.new("Attachment")
        a.Name = "NebulaChargeAtt"
        a.Parent = hrp
        local p = Instance.new("ParticleEmitter")
        p.Name = "NebulaChargeParticles"
        p.Texture = "rbxassetid://29712167"
        p.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 50)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255))
        })
        p.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 2)
        })
        p.Transparency = NumberSequence.new(0.2, 0.8)
        p.Lifetime = NumberRange.new(0.3, 0.6)
        p.Rate = 50
        p.Speed = NumberRange.new(5, 15)
        p.SpreadAngle = Vector2.new(180, 180)
        p.Parent = a
    end)
end

function removeChargeEffect(char)
    if not char then return end
    pcall(function()
        for _, desc in pairs(char:GetDescendants()) do
            if desc.Name == "NebulaChargeAtt" or desc.Name == "NebulaChargeParticles" then
                desc:Destroy()
            end
        end
    end)
end

superJumpAnimTrack = nil
superJumpAnimObject = nil

function playChargeAnimation(hum)
    if not hum then return end
    pcall(function()
        if superJumpAnimTrack then
            superJumpAnimTrack:Stop()
            superJumpAnimTrack:Destroy()
            superJumpAnimTrack = nil
        end
        local anim = Instance.new("Animation")
        anim.AnimationId = (hum.RigType == Enum.RigType.R15) and "rbxassetid://282574440" or "rbxassetid://182436935"
        superJumpAnimObject = anim
        superJumpAnimTrack = hum:LoadAnimation(anim)
        if superJumpAnimTrack then
            superJumpAnimTrack.Priority = Enum.AnimationPriority.Action4
            superJumpAnimTrack.Looped = true
            superJumpAnimTrack:Play(0.15)
            superJumpAnimTrack:AdjustSpeed(0.5)
        end
    end)
end

function stopChargeAnimation()
    pcall(function()
        if superJumpAnimTrack then
            superJumpAnimTrack:Stop(0.1)
            superJumpAnimTrack:Destroy()
            superJumpAnimTrack = nil
        end
        if superJumpAnimObject then
            superJumpAnimObject:Destroy()
            superJumpAnimObject = nil
        end
    end)
end

function toggleSuperJumpCharge(enabled)
    V.SuperJumpCharge = enabled
    if V.SuperJumpConn then V.SuperJumpConn:Disconnect() V.SuperJumpConn = nil end
    if V.SuperJumpEndConn then V.SuperJumpEndConn:Disconnect() V.SuperJumpEndConn = nil end
    if superJumpChargeTask then task.cancel(superJumpChargeTask) superJumpChargeTask = nil end
    local char = LocalPlayer.Character
    removeChargeEffect(char)
    stopChargeAnimation()

    if enabled then
        V.SuperJumpConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.Space then
                local c = LocalPlayer.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp then return end
                
                superJumpPressTime = tick()
                createChargeEffect(c)
                playChargeAnimation(hum)
                
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
                
                if superJumpChargeTask then task.cancel(superJumpChargeTask) end
                superJumpChargeTask = task.spawn(function()
                    local origWalk = hum.WalkSpeed
                    while UserInputService:IsKeyDown(Enum.KeyCode.Space) and V.SuperJumpCharge do
                        hum.WalkSpeed = math.max(4, origWalk * 0.35)
                        task.wait(0.05)
                    end
                    hum.WalkSpeed = origWalk
                end)
            end
        end)
        addConnection(V.SuperJumpConn)

        V.SuperJumpEndConn = UserInputService.InputEnded:Connect(function(input, gpe)
            if input.KeyCode == Enum.KeyCode.Space and superJumpPressTime then
                local c = LocalPlayer.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local chargeTime = math.min(tick() - superJumpPressTime, 3)
                superJumpPressTime = nil
                removeChargeEffect(c)
                stopChargeAnimation()

                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                end

                if chargeTime >= 0.15 and hrp and hum then
                    local chargeRatio = math.clamp(chargeTime / 2.5, 0.1, 1)
                    local launchVelocity = 160 + (chargeRatio * 420)
                    
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "SuperJumpLaunch"
                    bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
                    bv.Velocity = Vector3.new(hrp.AssemblyLinearVelocity.X, launchVelocity, hrp.AssemblyLinearVelocity.Z)
                    bv.Parent = hrp
                    Debris:AddItem(bv, 0.45)
                    
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    notify("Movement", string.format("🚀 SAUT CATAPULTE ! (%d%% Puissance)", math.floor(chargeRatio * 100)), Color3.fromRGB(80, 200, 120))
                end
            end
        end)
        addConnection(V.SuperJumpEndConn)
        notify("Movement", "Super Jump Charge ACTIVÉ (Maintiens ESPACE)", Color3.fromRGB(80, 200, 120))
    else
        local c = LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        stopChargeAnimation()
        notify("Movement", "Super Jump Charge DÉSACTIVÉ", Color3.fromRGB(255, 90, 90))
    end
end
_G.toggleSuperJumpCharge = toggleSuperJumpCharge

createToggle("Super Jump Charge (Saut Catapulte)", false, function(enabled)
    toggleSuperJumpCharge(enabled)
end, MovementContent, "SuperJumpCharge")

createToggle("Auto-Bhop (Bunny Hop)", false, function(enabled)
    V.AutoBhop = enabled
    if V.BhopConn then V.BhopConn:Disconnect() V.BhopConn = nil end
    if enabled then
        V.BhopConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local state = hum:GetState()
                    local moving = hum.MoveDirection.Magnitude > 0
                    if moving and (state == Enum.HumanoidStateType.Running or (hum.FloorMaterial ~= Enum.Material.Air and state == Enum.HumanoidStateType.Landed)) then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end)
        addConnection(V.BhopConn)
    end
    notify("Movement","Auto-Bhop".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, MovementContent,"AutoBhop")



function cleanAndResetAllBodies()
    pcall(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and not V.HitboxExtender then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.Material = Enum.Material.Plastic
                    hrp.CanCollide = false
                end
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local orig = head:FindFirstChild("OriginalSize")
                    if orig and orig:IsA("Vector3Value") then
                        head.Size = orig.Value
                    elseif head:IsA("MeshPart") and head.MeshSize and head.MeshSize.Magnitude > 0 then
                        head.Size = head.MeshSize
                    else
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.RigType == Enum.HumanoidRigType.R15 then
                            head.Size = Vector3.new(1.2, 1.2, 1.2)
                        end
                    end
                end
            end
        end
    end)
end

cleanAndResetAllBodies()

if V.HitboxConn then V.HitboxConn:Disconnect() end
V.HitboxConn = RunService.RenderStepped:Connect(function()
    if V.HitboxExtender then
        pcall(function()
            local size = V.HitboxSize or 15
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(size, size, size)
                        hrp.Transparency = 0.65
                        hrp.Color = Color3.fromRGB(0, 145, 255)
                        hrp.Material = Enum.Material.Neon
                        hrp.CanCollide = false
                    end
                end
            end
        end)
    else
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Size ~= Vector3.new(2, 2, 1) or hrp.Transparency ~= 1) then
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 1
                        hrp.Material = Enum.Material.Plastic
                        hrp.CanCollide = false
                    end
                end
            end
        end)
    end
end)

createLabel("GRAVITY", MovementContent)
createSlider("Gravity", 0, 200, 196, function(val) workspace.Gravity = val end, MovementContent)

createLabel("FLIGHT", MovementContent)
_, SetFlyToggle, ToggleFly = createToggle("Fly (Normal)", false, function(enabled)
    if enabled then startFly() else stopFly() end
    notify("Movement","Fly".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, MovementContent,"Fly")
createSlider("Fly Speed (Vitesse 50-2000)", 50, 2000, 300, function(val) V.FlySpeed = val end, MovementContent,"FlySpeed")
_, SetDesyncToggle, ToggleDesync = createToggle("Fly (Desynch)", false, function(enabled)
    if enabled then startDesyncFly() else stopDesyncFly() end
    notify("Movement","Desync Fly".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, MovementContent,"DesyncFly")
createSlider("Fly Speed (Desync 50-2000)", 50, 2000, 300, function(val) V.DesyncFlySpeed = val end, MovementContent,"DesyncFlySpeed")

initStep = "cablage Me"
createLabel("BODY SCALE & HITBOX", MeContent)
createToggle("Hitbox Extender", false, function(enabled)
    V.HitboxExtender = enabled
    if not enabled then
        cleanAndResetAllBodies()
    end
    notify("Combat","Hitbox Extender".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, MeContent,"HitboxExtender")
createSlider("Hitbox Size (Taille)", 1, 50, 25, function(val) V.HitboxSize = val end, MeContent,"HitboxSize")

function updateBodyScale()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local scaleVal = V.BodyScale and (V.BodyScale / 10) or 1

        if char.ScaleTo then
            pcall(function() char:ScaleTo(scaleVal) end)
        end

        local hs = hum:FindFirstChild("BodyHeightScale") or Instance.new("NumberValue", hum)
        hs.Name ="BodyHeightScale"
        hs.Value = scaleVal

        local ws = hum:FindFirstChild("BodyWidthScale") or Instance.new("NumberValue", hum)
        ws.Name ="BodyWidthScale"
        ws.Value = scaleVal

        local ds = hum:FindFirstChild("BodyDepthScale") or Instance.new("NumberValue", hum)
        ds.Name ="BodyDepthScale"
        ds.Value = scaleVal

        local headScale = hum:FindFirstChild("HeadScale") or Instance.new("NumberValue", hum)
        headScale.Name ="HeadScale"
        headScale.Value = scaleVal

        hum.HipHeight = 2 * scaleVal

        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~="HumanoidRootPart"then
                if not part:FindFirstChild("OriginalSize") then
                    local origSize = Instance.new("Vector3Value", part)
                    origSize.Name ="OriginalSize"
                    origSize.Value = part.Size
                end
                local orig = part.OriginalSize.Value
                part.Size = Vector3.new(orig.X * scaleVal, orig.Y * scaleVal, orig.Z * scaleVal)
            end
        end
    end)
end

createSlider("Body Scale (Taille Globale)", 5, 30, 10, function(val)
    V.BodyScale = val
    updateBodyScale()
end, MeContent,"BodyScale")

initStep = "cablage Protection"
createLabel("DEFENSE & SAFETY", ProtectionContent)

function toggleAntiFling(enabled)
    V.AntiFling = enabled
    if enabled then
        V.AntiFlingConn = RunService.Stepped:Connect(function()
            if not V.AntiFling then return end
            pcall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        for _, part in pairs(player.Character:GetChildren()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end)
        addConnection(V.AntiFlingConn)
        notify("Protection","Anti-Fling ON (Sans collision)", Color3.fromRGB(80, 200, 120))
    else
        if V.AntiFlingConn then V.AntiFlingConn:Disconnect() V.AntiFlingConn = nil end
        notify("Protection","Anti-Fling OFF", Color3.fromRGB(255, 90, 90))
    end
end

createToggle("Anti-Fling (Protection Anti-Propulsion)", false, function(enabled)
    toggleAntiFling(enabled)
end, ProtectionContent,"AntiFling")

createToggle("Anti-Ragdoll (Protection Anti-Chute)", false, function(enabled) toggleAntiRagdoll(enabled) end, ProtectionContent,"AntiRagdoll")

godmodeCharConn = nil
godmodeHealthConn = nil
godmodeStateConn = nil

function setupGodmodeForChar(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 3) or char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    pcall(function()
        hum.RequiresNeck = false
        hum.BreakJointsOnDeath = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end)

    if godmodeHealthConn then godmodeHealthConn:Disconnect() godmodeHealthConn = nil end
    godmodeHealthConn = hum.HealthChanged:Connect(function(newHealth)
        if V.Godmode and newHealth < hum.MaxHealth then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hum.Health = hum.MaxHealth
            end)
        end
    end)

    if godmodeStateConn then godmodeStateConn:Disconnect() godmodeStateConn = nil end
    godmodeStateConn = hum.StateChanged:Connect(function(old, new)
        if V.Godmode and new == Enum.HumanoidStateType.Dead then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hum.Health = hum.MaxHealth
            end)
        end
    end)
end

function disableHazardParts()
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("TouchTransmitter") then
                local p = obj.Parent
                if p and p:IsA("BasePart") then
                    local n = p.Name:lower()
                    if n:find("kill") or n:find("lava") or n:find("acid") or n:find("dead") or n:find("death") or n:find("hazard") or n:find("spikes") or n:find("dmg") or n:find("damage") then
                        p.CanTouch = false
                    end
                end
            end
        end
    end)
end

function toggleGodmode(enabled)
    V.Godmode = enabled
    if V.GodmodeConn then V.GodmodeConn:Disconnect() V.GodmodeConn = nil end
    if godmodeHealthConn then godmodeHealthConn:Disconnect() godmodeHealthConn = nil end
    if godmodeStateConn then godmodeStateConn:Disconnect() godmodeStateConn = nil end
    if godmodeCharConn then godmodeCharConn:Disconnect() godmodeCharConn = nil end

    if enabled then
        setupGodmodeForChar(LocalPlayer.Character)
        disableHazardParts()

        V.GodmodeConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.RequiresNeck = false
                    hum.BreakJointsOnDeath = false
                    if hum.Health > 0 and hum.Health < hum.MaxHealth then
                        hum.Health = hum.MaxHealth
                    end
                    if hum:GetState() == Enum.HumanoidStateType.Dead then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        hum.Health = hum.MaxHealth
                    end
                end
            end)
        end)
        addConnection(V.GodmodeConn)

        godmodeCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            if V.Godmode then
                task.wait(0.3)
                setupGodmodeForChar(newChar)
                disableHazardParts()
            end
        end)
        addConnection(godmodeCharConn)
    else
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.RequiresNeck = true
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            end
        end)
    end
    notify("Protection","Godmode ".. (enabled and "ON (Invincible + Anti-Killparts)" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end

createToggle("Godmode (Invincible + Régèn)", false, function(enabled)
    toggleGodmode(enabled)
end, ProtectionContent,"Godmode")

createToggle("Anti-Void (Anti-Chute)", false, function(enabled)
    V.AntiVoid = enabled
    if V.AntiVoidConn then V.AntiVoidConn:Disconnect() V.AntiVoidConn = nil end
    if enabled then
        V.AntiVoidConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Position.Y < -400 then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                    hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
                end
            end)
        end)
        addConnection(V.AntiVoidConn)
    end
    notify("Protection","Anti-Void ".. (enabled and "ON" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, ProtectionContent,"AntiVoid")


createLabel("PLAYER PHYSICS", MeContent)

_, SetNoclipToggle, ToggleNoclip = createToggle("Noclip", false, function(enabled)
    if enabled then startNoclip() else stopNoclip() end
    notify("Me","Noclip".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, MeContent,"Noclip")

createToggle("No Animations", false, function(enabled)
    if enabled then enableNoAnim() else disableNoAnim() end
end, MeContent,"NoAnim")
_, SetInvisToggle, ToggleInvis = createToggle("Invisible", false, function(enabled) toggleInvisibility(enabled) end, MeContent,"Invis")

createToggle("Infinite Jump", false, function(enabled)
    V.InfJump = enabled
    if V.InfJumpConn then
        V.InfJumpConn:Disconnect()
        V.InfJumpConn = nil
    end
    if enabled then
        V.InfJumpConn = UserInputService.JumpRequest:Connect(function()
            if V.InfJump then
                pcall(function()
                    local hum = getHumanoid()
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            end
        end)
        addConnection(V.InfJumpConn)
    end
    notify("Me","Infinite Jump".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, MeContent,"InfJump")

createLabel("VISUALS & INTERACTIONS", MeContent)
createToggle("Instant Interact (Universal)", false, function(enabled) toggleInstantInteract(enabled) end, MeContent,"InstInteract")
createToggle("Infinite Interact Range", false, function(enabled) toggleInfiniteRange(enabled) end, MeContent,"InfRange")

createLabel("CAMERA", MeContent)
createSlider("FOV Changer", 70, 120, 70, function(val)
    V.FOV = val
end, MeContent,"FOV")

FreecamMenu = nil
FreecamMenuConn = nil
FreecamTeleportConn = nil
FreecamSelectedIndex = 1
FreecamMenuLabels = {}
FreecamCrosshair = nil
FreecamSavedPos = nil

initStep = "freecam"
function createFreecamCrosshair()
    if FreecamCrosshair then FreecamCrosshair:Destroy() end
FreecamCrosshair = Instance.new("ScreenGui")
FreecamCrosshair.Name ="NebulaFreecamCrosshair"
FreecamCrosshair.ResetOnSpawn = false
FreecamCrosshair.DisplayOrder = 100
FreecamCrosshair.Enabled = false
    FreecamCrosshair.Parent = parentTarget

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 6, 0, 6)
    Dot.Position = UDim2.new(0.5, -3, 0.5, -3)
    Dot.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
    Dot.BorderSizePixel = 0
    Dot.Parent = FreecamCrosshair
    
    local DCorner = Instance.new("UICorner")
    DCorner.CornerRadius = UDim.new(1, 0)
    DCorner.Parent = Dot

    local DS = Instance.new("UIStroke")
    DS.Color = Color3.fromRGB(0, 0, 0)
    DS.Thickness = 1.5
    DS.Parent = Dot
end
createFreecamCrosshair()

function teleportPlayerFromFreecam(mode, exitFreecam)
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local targetCF = nil
        if mode == "Ground" then
            local rayOrigin = Camera.CFrame.Position
            local rayDirection = Camera.CFrame.LookVector * 1500
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {char}
            local result = workspace:Raycast(rayOrigin, rayDirection, params)
            if result then
                targetCF = CFrame.new(result.Position + Vector3.new(0, 3.5, 0), result.Position + Vector3.new(0, 3.5, 0) + Camera.CFrame.LookVector * Vector3.new(1, 0, 1))
            else
                local downRay = workspace:Raycast(rayOrigin, Vector3.new(0, -2000, 0), params)
                if downRay then
                    targetCF = CFrame.new(downRay.Position + Vector3.new(0, 3.5, 0))
                else
                    targetCF = Camera.CFrame
                end
            end
        else
            targetCF = Camera.CFrame
        end

        V.FreecamOriginalCharCF = nil
        hrp.CFrame = targetCF
        hrp.Anchored = false
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)

        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = hum
        hum.WalkSpeed = V.SpeedEnabled and V.Speed or 16
        hum.JumpPower = V.JumpEnabled and V.Jump or 50
        hum.AutoRotate = true
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)

        V.FreecamCharVisible = true
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.Transparency = part:GetAttribute("_FreecamOrigTrans") or 0
                part.LocalTransparencyModifier = 0
            elseif part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = part:GetAttribute("_FreecamOrigTrans") or 0
            end
        end

        if exitFreecam then
            if SetFreecamToggle then SetFreecamToggle(false) else V.Freecam = false end
            notify("Freecam", "Téléporté (" .. (mode == "Ground" and "Sol" or "Caméra") .. ") - Freecam Fermée", Color3.fromRGB(80, 200, 120))
        else
            notify("Freecam", "Téléporté (" .. (mode == "Ground" and "Sol" or "Caméra") .. ") - Perso Visible", Color3.fromRGB(80, 200, 120))
        end
    end)
end

FreecamOptionsList = {
    {Name = "TP Perso -> Sol Vise (Safe)", Action = function()
        teleportPlayerFromFreecam("Ground", false)
    end},
    {Name = "TP Perso -> Position Camera", Action = function()
        teleportPlayerFromFreecam("Cam", false)
    end},
    {Name = "TP & Quitter Freecam", Action = function()
        teleportPlayerFromFreecam(V.FreecamTPTargetMode or "Ground", true)
    end},
    {Name = "Fermer Menu (Garder Freecam)", Action = function()
        if FreecamMenu then FreecamMenu.Enabled = false end
        notify("Freecam", "Menu masque. Appuie sur X pour quitter la Freecam.", Color3.fromRGB(180, 180, 195))
    end}
}

function updateFreecamMenuVisuals(hoverIndex)
    local activeIndex = hoverIndex or FreecamSelectedIndex
    for i, btn in ipairs(FreecamMenuLabels) do
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if i == activeIndex then
            btn.BackgroundColor3 = theme.accent
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = "  > " .. FreecamOptionsList[i].Name
            if stroke then stroke.Color = theme.accent end
        else
            btn.BackgroundColor3 = theme.card
            btn.TextColor3 = theme.text
            btn.Text = "    " .. FreecamOptionsList[i].Name
            if stroke then stroke.Color = theme.border end
        end
    end
end

function createFreecamMenu()
    if FreecamMenu then FreecamMenu:Destroy() end
    FreecamMenu = Instance.new("ScreenGui")
    FreecamMenu.Name = "NebulaFreecamMenu"
    FreecamMenu.ResetOnSpawn = false
    FreecamMenu.DisplayOrder = 999
    FreecamMenu.Enabled = false
    FreecamMenu.Parent = parentTarget

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 310, 0, 215)
    MainFrame.Position = UDim2.new(0, 30, 0.5, -107)
    MainFrame.BackgroundColor3 = theme.panel
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = FreecamMenu

    makeCorner(MainFrame, 12)
    makeStroke(MainFrame, theme.border, 1.2)

    local TopAccent = Instance.new("Frame")
    TopAccent.Size = UDim2.new(1, -24, 0, 2)
    TopAccent.Position = UDim2.new(0, 12, 0, 0)
    TopAccent.BackgroundColor3 = theme.accent
    TopAccent.BorderSizePixel = 0
    TopAccent.Parent = MainFrame
    makeCorner(TopAccent, 2)

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, -16, 0, 42)
    TitleBar.Position = UDim2.new(0, 8, 0, 8)
    TitleBar.BackgroundColor3 = theme.panel2
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    makeCorner(TitleBar, 8)
    makeStroke(TitleBar, theme.border, 1)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -16, 0, 18)
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "FREECAM"
    Title.TextColor3 = theme.accent
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local SubTitle = Instance.new("TextLabel")
    SubTitle.Size = UDim2.new(1, -16, 0, 14)
    SubTitle.Position = UDim2.new(0, 10, 0, 23)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "ZQSD: Voler  •  Entree / T: TP"
    SubTitle.TextColor3 = theme.sub
    SubTitle.Font = Enum.Font.GothamMedium
    SubTitle.TextSize = 10
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.Parent = TitleBar

    local ListFrame = Instance.new("Frame")
    ListFrame.Name = "List"
    ListFrame.Size = UDim2.new(1, -16, 1, -60)
    ListFrame.Position = UDim2.new(0, 8, 0, 56)
    ListFrame.BackgroundTransparency = 1
    ListFrame.Parent = MainFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = ListFrame

    FreecamMenuLabels = {}
    for i, opt in ipairs(FreecamOptionsList) do
        local btn = Instance.new("TextButton")
        btn.LayoutOrder = i
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = theme.card
        btn.AutoButtonColor = false
        btn.Text = "    " .. opt.Name
        btn.TextColor3 = theme.text
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        btn.Parent = ListFrame

        makeCorner(btn, 8)
        makeStroke(btn, theme.border, 1)

        btn.MouseEnter:Connect(function()
            updateFreecamMenuVisuals(i)
        end)
        btn.MouseLeave:Connect(function()
            updateFreecamMenuVisuals(nil)
        end)
        btn.MouseButton1Click:Connect(function()
            pcall(function() game:GetService("GuiService").SelectedObject = nil end)
            FreecamSelectedIndex = i
            opt.Action()
        end)

        table.insert(FreecamMenuLabels, btn)
    end

    updateFreecamMenuVisuals(nil)
end

createFreecamMenu()


_, SetFreecamToggle, ToggleFreecam = createToggle("Freecam", false, function(enabled)
    V.Freecam = enabled
    pcall(function() game:GetService("GuiService").SelectedObject = nil end)
    if enabled then
        V.FreecamFOV = V.FOV or 70
        V.FreecamCF = Camera.CFrame
        V.FreecamCharVisible = false
        local rx, ry, rz = V.FreecamCF:ToOrientation()
        V.FreecamPitch = rx
        V.FreecamYaw = ry
        
        Camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseIconEnabled = true
        if FreecamCrosshair then FreecamCrosshair.Enabled = true end
        
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                V.FreecamOriginalCharCF = hrp.CFrame
                hrp.CFrame = CFrame.new(hrp.Position.X, -500, hrp.Position.Z)
                hrp.Anchored = true
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum.AutoRotate = false end
            
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if not part:GetAttribute("_FreecamOrigTrans") then
                        part:SetAttribute("_FreecamOrigTrans", part.Transparency)
                    end
                    part.Transparency = 1
                    part.CanCollide = false
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    if not part:GetAttribute("_FreecamOrigTrans") then
                        part:SetAttribute("_FreecamOrigTrans", part.Transparency)
                    end
                    part.Transparency = 1
                end
            end
        end
        
        if V.FreecamInputConn then V.FreecamInputConn:Disconnect() end
        V.FreecamInputConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
                    local delta = input.Delta
                    V.FreecamYaw = V.FreecamYaw - delta.X * 0.004
                    V.FreecamPitch = math.clamp(V.FreecamPitch - delta.Y * 0.004, -math.rad(89.5), math.rad(89.5))
                end
            end
        end)
        addConnection(V.FreecamInputConn)
        
        V.FreecamConn = RunService.RenderStepped:Connect(function(dt)
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and not V.FreecamCharVisible then hrp.Anchored = true end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and not V.FreecamCharVisible then 
                    hum.WalkSpeed = 0 
                    hum.JumpPower = 0 
                    hum.AutoRotate = false 
                end
                if not V.FreecamCharVisible then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            part.Transparency = 1
                        elseif part:IsA("Decal") or part:IsA("Texture") then
                            part.Transparency = 1
                        end
                    end
                end
            end

            local moveVector = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Z) then
                moveVector = moveVector + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveVector = moveVector - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                moveVector = moveVector - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveVector = moveVector + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
                moveVector = moveVector + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
                moveVector = moveVector - Vector3.new(0, 1, 0)
            end
            
            local currentSpeed = V.FreecamSpeed or 60
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                currentSpeed = currentSpeed * 2.5
            end
            
            if moveVector.Magnitude > 0 then
                V.FreecamCF = V.FreecamCF + (moveVector.Unit * currentSpeed * dt)
            end

            local rotCFrame = CFrame.fromOrientation(V.FreecamPitch, V.FreecamYaw, 0)
            V.FreecamCF = CFrame.new(V.FreecamCF.Position) * rotCFrame
            Camera.CFrame = V.FreecamCF
            
            if Camera.FieldOfView ~= V.FreecamFOV then
                Camera.FieldOfView = V.FreecamFOV
            end
        end)
        addConnection(V.FreecamConn)
        
        if V.FreecamTeleportConn then V.FreecamTeleportConn:Disconnect() end
        V.FreecamTeleportConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        end)
        addConnection(V.FreecamTeleportConn)

        if V.FreecamTeleportConnEnd then V.FreecamTeleportConnEnd:Disconnect() end
        V.FreecamTeleportConnEnd = UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end)
        addConnection(V.FreecamTeleportConnEnd)

        if FreecamMenu then
            FreecamMenu.Enabled = true
            FreecamSelectedIndex = 1
            updateFreecamMenuVisuals(nil)
        end

        if V.FreecamMenuConn then V.FreecamMenuConn:Disconnect() end
        V.FreecamMenuConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if FreecamMenu and FreecamMenu.Enabled then
                local key = input.KeyCode
                if key == Enum.KeyCode.Down then
                    if FreecamSelectedIndex < #FreecamOptionsList then
                        FreecamSelectedIndex = FreecamSelectedIndex + 1
                    else
                        FreecamSelectedIndex = 1
                    end
                    updateFreecamMenuVisuals(nil)
                elseif key == Enum.KeyCode.Up then
                    if FreecamSelectedIndex > 1 then
                        FreecamSelectedIndex = FreecamSelectedIndex - 1
                    else
                        FreecamSelectedIndex = #FreecamOptionsList
                    end
                    updateFreecamMenuVisuals(nil)
                elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter or key == Enum.KeyCode.Right or key == Enum.KeyCode.T then
                    pcall(function() game:GetService("GuiService").SelectedObject = nil end)
                    if FreecamOptionsList[FreecamSelectedIndex] and FreecamOptionsList[FreecamSelectedIndex].Action then
                        FreecamOptionsList[FreecamSelectedIndex].Action()
                    end
                end
            end
        end)
        addConnection(V.FreecamMenuConn)

        notify("Me", "Freecam ON (Z/Q/S/D pour voler, Clic Droit = Regarder, Entree = TP)", Color3.fromRGB(80, 200, 120))
    else
        if V.FreecamConn then V.FreecamConn:Disconnect() V.FreecamConn = nil end
        if V.FreecamInputConn then V.FreecamInputConn:Disconnect() V.FreecamInputConn = nil end
        if V.FreecamMenuConn then V.FreecamMenuConn:Disconnect() V.FreecamMenuConn = nil end
        if V.FreecamTeleportConn then V.FreecamTeleportConn:Disconnect() V.FreecamTeleportConn = nil end
        if V.FreecamTeleportConnEnd then V.FreecamTeleportConnEnd:Disconnect() V.FreecamTeleportConnEnd = nil end
        
        Camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        if FreecamCrosshair then FreecamCrosshair.Enabled = false end
        pcall(function() game:GetService("GuiService").SelectedObject = nil end)
        
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if V.FreecamOriginalCharCF then
                    hrp.CFrame = V.FreecamOriginalCharCF
                    V.FreecamOriginalCharCF = nil
                end
                hrp.Anchored = false
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then 
                Camera.CameraSubject = hum
                hum.WalkSpeed = V.SpeedEnabled and V.Speed or 16
                hum.JumpPower = V.JumpEnabled and V.Jump or 50 
                hum.AutoRotate = true
                hum.PlatformStand = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                    part.Transparency = part:GetAttribute("_FreecamOrigTrans") or 0
                    part.LocalTransparencyModifier = 0
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = part:GetAttribute("_FreecamOrigTrans") or 0
                end
            end
        end
        
        if FreecamMenu then FreecamMenu.Enabled = false end
        
        notify("Me","Freecam OFF", Color3.fromRGB(255, 90, 90))
    end
end, MeContent,"Freecam")
createSlider("Freecam Speed", 10, 500, 50, function(val) V.FreecamSpeed = val end, MeContent,"FreecamSpeed")
createToggle("Freecam Cible TP : Sol (ON) / Caméra (OFF)", true, function(enabled)
    V.FreecamTPTargetMode = enabled and "Ground" or "Cam"
    notify("Freecam", "Cible TP Freecam : " .. (enabled and "Sol visé" or "Position Caméra"), Color3.fromRGB(80, 200, 120))
end, MeContent, "FreecamTPMode")



createLabel("ACTIONS", MeContent)

createButton("Outfit Random (Vêtements Aléatoires)", function()
    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        if not char then
            notify("Me","Attends ton personnage...", Color3.fromRGB(255, 165, 0))
            return
        end
        local shirts = {77851408, 59892631, 126099294, 152424424, 18301669, 26417861}
        local pants = {77851404, 59892641, 126099290, 152424416, 18301671, 26417863}
        local graphics = {65409772, 58556241, 71530370, 70601087, 70570051, 70570039}
        local hats = {1028619, 1662548, 1875633, 1048849, 1092204, 13928240, 13928249, 13928253, 13928256}
        local function randomColor()
            return Color3.fromHSV(math.random(), math.random() * 0.4 + 0.6, math.random() * 0.4 + 0.6)
        end
        local shirt = char:FindFirstChildOfClass("Shirt")
        if not shirt then
            shirt = Instance.new("Shirt")
            shirt.Parent = char
        end
        pcall(function()
            shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=" .. shirts[math.random(#shirts)]
        end)
        local pantsInst = char:FindFirstChildOfClass("Pants")
        if not pantsInst then
            pantsInst = Instance.new("Pants")
            pantsInst.Parent = char
        end
        pcall(function()
            pantsInst.PantsTemplate = "http://www.roblox.com/asset/?id=" .. pants[math.random(#pants)]
        end)
        local graphic = char:FindFirstChildOfClass("ShirtGraphic")
        if not graphic then
            graphic = Instance.new("ShirtGraphic")
            graphic.Parent = char
        end
        pcall(function()
            graphic.Graphic = "http://www.roblox.com/asset/?id=" .. graphics[math.random(#graphics)]
        end)
        local bodyColors = char:FindFirstChildOfClass("BodyColors")
        if bodyColors then
            bodyColors.HeadColor3 = randomColor()
            bodyColors.TorsoColor3 = randomColor()
            bodyColors.LeftArmColor3 = randomColor()
            bodyColors.RightArmColor3 = randomColor()
            bodyColors.LeftLegColor3 = randomColor()
            bodyColors.RightLegColor3 = randomColor()
        end
        for _, child in pairs(char:GetChildren()) do
            if child:IsA("Accessory") then
                child:Destroy()
            end
        end
        local newAcc = Instance.new("Accessory")
        newAcc.Name = "RandomHat"
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(1, 1, 1)
        handle.Parent = newAcc
        local hatId = hats[math.random(#hats)]
        pcall(function()
            handle.MeshId = "http://www.roblox.com/asset/?id=" .. hatId
            handle.TextureID = "http://www.roblox.com/asset/?id=" .. hatId
        end)
        newAcc.Parent = char
        notify("Me","Outfit random appliqué ! (vêtements + couleurs + chapeau)", Color3.fromRGB(80, 200, 120))
    end)
    if not ok then
        notify("Me","Erreur Outfit : " .. tostring(err), Color3.fromRGB(255, 90, 90))
    end
end, MeContent)





createButton("Reset Health (Full Vie)", function()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = hum.MaxHealth
            notify("Me", "Sante restauree au maximum !", Color3.fromRGB(80, 200, 120))
        else
            notify("Me", "Humanoid introuvable !", Color3.fromRGB(255, 90, 90))
        end
    end)
end, MeContent)

function respawnPlayer()
    notify("Me","Instant Respawn...", Color3.fromRGB(255, 165, 0))
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.BreakJointsOnDeath = true
                hum.Health = 0
            end
            
            local head = char:FindFirstChild("Head")
            local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
            if head and torso then
                local neck = head:FindFirstChild("Neck") or torso:FindFirstChild("Neck")
                if neck then
                    neck:Destroy()
                else
                    char:BreakJoints()
                end
            else
                char:BreakJoints()
            end
            
            task.spawn(function()
                task.wait(0.05)
                pcall(function() LocalPlayer:LoadCharacter() end)
            end)
        else
            pcall(function() LocalPlayer:LoadCharacter() end)
        end
    end)
end

createButton("Instant Respawn", function()
    notify("Me","Respawn Instantané...", Color3.fromRGB(255, 165, 0))
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.BreakJointsOnDeath = true
                hum.Health = 0
            end
            
            local head = char:FindFirstChild("Head")
            local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
            if head and torso then
                local neck = head:FindFirstChild("Neck") or torso:FindFirstChild("Neck")
                if neck then
                    neck:Destroy()
                else
                    char:BreakJoints()
                end
            else
                char:BreakJoints()
            end
            
            task.spawn(function()
                task.wait(0.05)
                pcall(function() LocalPlayer:LoadCharacter() end)
            end)
        else
            pcall(function() LocalPlayer:LoadCharacter() end)
        end
    end)
end, MeContent)

initStep = "cablage ESP"

origXRayTransparencies = origXRayTransparencies or {}
origMaterials = origMaterials or {}
origDecalTransparencies = origDecalTransparencies or {}
xrayConn = nil

local function isPlayerOrCharPart(part)
    if not part then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c and part:IsDescendantOf(c) then
            return true
        end
    end
    local m = part:FindFirstAncestorOfClass("Model")
    if m and m:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return false
end

local function isFloorOrGround(part)
    if not part or not part:IsA("BasePart") then return false end
    if part:IsA("Terrain") then return true end
    local name = string.lower(part.Name)
    if string.find(name, "floor") or string.find(name, "ground") or string.find(name, "sol") or string.find(name, "baseplate")
        or string.find(name, "road") or string.find(name, "street") or string.find(name, "route") or string.find(name, "pavement")
        or string.find(name, "grass") or string.find(name, "terrain") or string.find(name, "stairs") or string.find(name, "escalier")
        or string.find(name, "sidewalk") or string.find(name, "path") or string.find(name, "trottoir") then
        return true
    end
    local sz = part.Size
    if sz.Y <= 4 and (sz.X >= 18 or sz.Z >= 18) then
        return true
    end
    return false
end

function restoreXRay()
    if xrayConn then
        xrayConn:Disconnect()
        xrayConn = nil
    end
    if origXRayTransparencies then
        for part, orig in pairs(origXRayTransparencies) do
            if part and part.Parent then
                pcall(function() part.Transparency = orig end)
            end
        end
        origXRayTransparencies = {}
    end
    if origMaterials then
        for part, mat in pairs(origMaterials) do
            if part and part.Parent then
                pcall(function() part.Material = mat end)
            end
        end
        origMaterials = {}
    end
    if origDecalTransparencies then
        for dec, orig in pairs(origDecalTransparencies) do
            if dec and dec.Parent then
                pcall(function() dec.Transparency = orig end)
            end
        end
        origDecalTransparencies = {}
    end
end

local function applyPartXRay(obj, targetTrans, style, effKeepFloor, hideDecals)
    if not obj or not obj.Parent then return end
    if obj:IsA("BasePart") then
        if isPlayerOrCharPart(obj) then return end
        if effKeepFloor and isFloorOrGround(obj) then return end

        if origXRayTransparencies[obj] == nil then
            origXRayTransparencies[obj] = obj.Transparency
        end
        if origMaterials[obj] == nil then
            origMaterials[obj] = obj.Material
        end

        pcall(function()
            if origXRayTransparencies[obj] < targetTrans then
                obj.Transparency = targetTrans
            end
            if style == "Verre Lisse" then
                obj.Material = Enum.Material.SmoothPlastic
            elseif style == "ForceField" then
                obj.Material = Enum.Material.ForceField
            end
        end)
    elseif hideDecals and (obj:IsA("Decal") or obj:IsA("Texture")) then
        local p = obj.Parent
        if p and p:IsA("BasePart") and not isPlayerOrCharPart(p) then
            if not effKeepFloor or not isFloorOrGround(p) then
                if origDecalTransparencies[obj] == nil then
                    origDecalTransparencies[obj] = obj.Transparency
                end
                pcall(function() obj.Transparency = 1 end)
            end
        end
    end
end

function updateXRay()
    if not V.XRay then return end
    local targetTrans = (V.XRayTransparency or 65) / 100
    local style = V.XRayStyle or "Murs Propres"
    local keepFloor = (V.XRayKeepFloor ~= false)
    local effKeepFloor = keepFloor and (style ~= "Total X-Ray")
    local hideDecals = (V.XRayHideDecals ~= false)

    for part, orig in pairs(origXRayTransparencies) do
        if part and part.Parent and not isPlayerOrCharPart(part) then
            if effKeepFloor and isFloorOrGround(part) then
                pcall(function()
                    part.Transparency = orig
                    if origMaterials[part] then part.Material = origMaterials[part] end
                end)
            else
                pcall(function()
                    if orig < targetTrans then
                        part.Transparency = targetTrans
                    else
                        part.Transparency = orig
                    end
                    if style == "Verre Lisse" then
                        part.Material = Enum.Material.SmoothPlastic
                    elseif style == "ForceField" then
                        part.Material = Enum.Material.ForceField
                    elseif origMaterials[part] then
                        part.Material = origMaterials[part]
                    end
                end)
            end
        end
    end

    if hideDecals then
        for dec, orig in pairs(origDecalTransparencies) do
            if dec and dec.Parent then
                local p = dec.Parent
                if p and p:IsA("BasePart") and effKeepFloor and isFloorOrGround(p) then
                    pcall(function() dec.Transparency = orig end)
                else
                    pcall(function() dec.Transparency = 1 end)
                end
            end
        end
    else
        for dec, orig in pairs(origDecalTransparencies) do
            if dec and dec.Parent then
                pcall(function() dec.Transparency = orig end)
            end
        end
    end
end

function toggleXRay(enabled)
    V.XRay = enabled
    local targetTrans = (V.XRayTransparency or 65) / 100
    local style = V.XRayStyle or "Murs Propres"
    local keepFloor = (V.XRayKeepFloor ~= false)
    local effKeepFloor = keepFloor and (style ~= "Total X-Ray")
    local hideDecals = (V.XRayHideDecals ~= false)

    if enabled then
        task.spawn(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not V.XRay then break end
                applyPartXRay(obj, targetTrans, style, effKeepFloor, hideDecals)
            end
        end)

        if xrayConn then xrayConn:Disconnect() end
        xrayConn = workspace.DescendantAdded:Connect(function(obj)
            if not V.XRay then return end
            task.wait()
            if not V.XRay then return end
            local curStyle = V.XRayStyle or "Murs Propres"
            local curKeep = (V.XRayKeepFloor ~= false)
            local curEff = curKeep and (curStyle ~= "Total X-Ray")
            applyPartXRay(obj, (V.XRayTransparency or 65) / 100, curStyle, curEff, V.XRayHideDecals ~= false)
        end)
        notify("ESP", "X-Ray PRO ACTIVÉ (" .. tostring(V.XRayTransparency or 65) .. "% - " .. tostring(style) .. ")", Color3.fromRGB(80, 200, 120))
    else
        restoreXRay()
        notify("ESP", "X-Ray DÉSACTIVÉ", Color3.fromRGB(255, 90, 90))
    end
end

createLabel("ESP OPTIONS", ESPContent)
_, SetESPToggle, ToggleESP = createToggle("Enable ESP", false, function(enabled)
    V.ESP = enabled
    if ESPGui then ESPGui.Enabled = enabled end
    refreshESP()
end, ESPContent,"ESP")
createToggle("Team Check (Masquer Alliés)", false, function(enabled)
    V.ESPTeamCheck = enabled
    refreshESP()
end, ESPContent, "ESPTeamCheck")
createToggle("Box", false, function(enabled) V.ESPBox = enabled end, ESPContent,"ESPBox")
createToggle("Glow ESP", false, function(enabled) V.ESPGlow = enabled end, ESPContent,"ESPGlow")
createToggle("Filled Box", false, function(enabled) V.ESPFilled = enabled end, ESPContent,"ESPFilled")
createToggle("Name", false, function(enabled) V.ESPName = enabled end, ESPContent,"ESPName")
createToggle("Distance", false, function(enabled) V.ESPDist = enabled end, ESPContent,"ESPDist")
createToggle("Tracers ESP", false, function(enabled) V.ESPTracer = enabled end, ESPContent,"ESPTracer")
createToggle("Skeleton ESP", false, function(enabled) V.ESPSkeleton = enabled end, ESPContent,"ESPSkeleton")
createToggle("Health Bar ESP", false, function(enabled) V.ESPHealth = enabled end, ESPContent,"ESPHealth")
createToggle("Afficher PV", false, function(enabled)
    V.ESPPV = enabled
    HealthPV_Enabled = enabled
    if HealthPVTrack and HealthPVThumb then
        AnimateToggle(HealthPVTrack, HealthPVThumb, enabled)
    end
end, ESPContent, "ESPPV")
createToggle("Weapon / Held Item ESP", false, function(enabled) V.ESPWeapon = enabled end, ESPContent,"ESPWeapon")
createToggle("NPCs ESP (Entités / PNJ)", false, function(enabled)
    V.ESPNPC = enabled
    refreshESP()
end, ESPContent, "ESPNPC")
createToggle("X-Ray (Vision murs optimisée)", false, function(enabled)
    toggleXRay(enabled)
end, ESPContent, "XRay")
createToggle("Garder le Sol Solide (Anti-Vertige)", true, function(enabled)
    V.XRayKeepFloor = enabled
    if V.XRay and updateXRay then updateXRay() end
end, ESPContent, "XRayKeepFloor")
createToggle("Masquer Textures Flottantes (Clean)", true, function(enabled)
    V.XRayHideDecals = enabled
    if V.XRay and updateXRay then updateXRay() end
end, ESPContent, "XRayHideDecals")

local xrayStyles = {"Murs Propres", "Verre Lisse", "ForceField", "Total X-Ray"}
local styleCard, styleBtn
styleCard, styleBtn = createButton("Style Visuel X-Ray", function()
    local cur = V.XRayStyle or "Murs Propres"
    local idx = 1
    for i, s in ipairs(xrayStyles) do
        if s == cur then idx = i break end
    end
    idx = (idx % #xrayStyles) + 1
    local nextStyle = xrayStyles[idx]
    V.XRayStyle = nextStyle
    if styleBtn then styleBtn.Text = nextStyle end
    if V.XRay and updateXRay then updateXRay() end
    notify("X-Ray", "Style : " .. nextStyle, Color3.fromRGB(130, 100, 255))
end, ESPContent, V.XRayStyle or "Murs Propres")
if styleBtn then
    styleBtn.Size = UDim2.new(0, 95, 0, 24)
    styleBtn.Position = UDim2.new(1, -105, 0.5, -12)
end

ConfigRegistry["XRayStyle"] = function(val)
    if val and table.find(xrayStyles, val) then
        V.XRayStyle = val
        if styleBtn then styleBtn.Text = val end
        if V.XRay and updateXRay then updateXRay() end
    end
end

createSlider("X-Ray Transparence", 10, 95, 65, function(val)
    V.XRayTransparency = val
    if V.XRay and updateXRay then updateXRay() end
end, ESPContent, "XRayTransparency")

droppedItemsFolder = nil
function toggleDroppedItemsESP(enabled)
    V.ESPDropped = enabled
    if droppedItemsFolder then
        droppedItemsFolder:Destroy()
        droppedItemsFolder = nil
    end
    if enabled then
        droppedItemsFolder = Instance.new("Folder")
        droppedItemsFolder.Name ="NebulaDroppedItemsESP"
        droppedItemsFolder.Parent = ESPGui

        task.spawn(function()
            while V.ESPDropped do
                task.wait(1.5)
                if not droppedItemsFolder then break end
                droppedItemsFolder:ClearAllChildren()
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") or (obj:IsA("Part") and obj.Name:lower():find("item")) then
                        local handle = obj:FindFirstChild("Handle") or obj
                        if handle and handle:IsA("BasePart") then
                            local billboard = Instance.new("BillboardGui")
                            billboard.Size = UDim2.new(0, 100, 0, 20)
                            billboard.AlwaysOnTop = true
                            billboard.Adornee = handle
                            billboard.Parent = droppedItemsFolder
                            
                            local label = Instance.new("TextLabel")
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Text ="".. obj.Name
                            label.TextColor3 = Color3.fromRGB(255, 215, 0)
                            label.TextSize = 11
                            label.Font = Enum.Font.GothamBold
                            label.Parent = billboard
                        end
                    end
                end
            end
        end)
    end
end
createToggle("Dropped Items ESP", false, function(enabled) toggleDroppedItemsESP(enabled) end, ESPContent,"ESPDropped")

bloxFruitsLevelFolder = nil
function toggleBloxFruitsLevelESP(enabled)
    V.ESPBloxFruitsLevel = enabled
    if bloxFruitsLevelFolder then
        bloxFruitsLevelFolder:Destroy()
        bloxFruitsLevelFolder = nil
    end
    if enabled then
        bloxFruitsLevelFolder = Instance.new("Folder")
        bloxFruitsLevelFolder.Name = "NebulaBloxFruitsLevelESP"
        bloxFruitsLevelFolder.Parent = ESPGui or parentTarget

        task.spawn(function()
            while V.ESPBloxFruitsLevel do
                if not bloxFruitsLevelFolder then break end
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local char = player.Character
                        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                        if head then
                            local bb = bloxFruitsLevelFolder:FindFirstChild("BFLevel_" .. player.Name)
                            local levelText = "?"
                            local data = player:FindFirstChild("Data")
                            if data and data:FindFirstChild("Level") then
                                levelText = tostring(data.Level.Value)
                            else
                                local ls = player:FindFirstChild("leaderstats")
                                if ls and ls:FindFirstChild("Level") then
                                    levelText = tostring(ls.Level.Value)
                                else
                                    for _, desc in pairs(char:GetDescendants()) do
                                        if desc:IsA("TextLabel") and string.find(desc.Text, "Lv%s*%.?%s*%d+") then
                                            local lv = string.match(desc.Text, "Lv%s*%.?%s*(%d+)")
                                            if lv then levelText = lv break end
                                        end
                                    end
                                end
                            end

                            if not bb then
                                bb = Instance.new("BillboardGui")
                                bb.Name = "BFLevel_" .. player.Name
                                bb.Size = UDim2.new(0, 120, 0, 22)
                                bb.StudsOffset = Vector3.new(0, 3.2, 0)
                                bb.AlwaysOnTop = true
                                bb.Adornee = head
                                bb.Parent = bloxFruitsLevelFolder

                                local lbl = Instance.new("TextLabel")
                                lbl.Name = "LevelLabel"
                                lbl.Size = UDim2.new(1, 0, 1, 0)
                                lbl.BackgroundTransparency = 1
                                lbl.Text = "[Lv. " .. levelText .. "]"
                                lbl.TextColor3 = Color3.fromRGB(175, 110, 255)
                                lbl.TextSize = 12
                                lbl.Font = Enum.Font.GothamBold
                                lbl.TextStrokeTransparency = 0.2
                                lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                lbl.Parent = bb
                            else
                                bb.Adornee = head
                                local lbl = bb:FindFirstChild("LevelLabel")
                                if lbl then
                                    lbl.Text = "[Lv. " .. levelText .. "]"
                                end
                            end
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end
end
createToggle('Esp level (<font color="rgb(175,110,255)">Bloxfruit</font>)', false, function(enabled)
    toggleBloxFruitsLevelESP(enabled)
end, ESPContent, "ESPBloxFruitsLevel")

_G.getPlayerBloxFruit = function(player)
    local fruitName = nil
    local isPerm = false
    local invFruitList = {}
    if not player then return "Aucun", false, invFruitList end
    local data = player:FindFirstChild("Data")
    if data then
        local df = data:FindFirstChild("DevilFruit") or data:FindFirstChild("Fruit") or data:FindFirstChild("DevilFruitName")
        if df and df.Value and df.Value ~= "" and df.Value ~= "None" then
            fruitName = tostring(df.Value)
        end
        local permFolder = data:FindFirstChild("PermFruits") or data:FindFirstChild("PermanentFruits") or data:FindFirstChild("Perm") or data:FindFirstChild("Permanent") or data:FindFirstChild("OwnedFruits") or data:FindFirstChild("Perms")
        if permFolder and fruitName then
            local clean = string.gsub(string.gsub(fruitName, "%-.*$", ""), "%s*[Ff]ruit$", "")
            for _, ch in ipairs(permFolder:GetChildren()) do
                if string.find(string.lower(ch.Name), string.lower(clean)) or ch.Name == fruitName then
                    isPerm = true
                    break
                end
            end
        end
        if fruitName and data:GetAttribute("Perm" .. fruitName) == true then
            isPerm = true
        end
    end
    if player:GetAttribute("DevilFruit") then
        local dfAttr = tostring(player:GetAttribute("DevilFruit"))
        if dfAttr ~= "" and dfAttr ~= "None" then
            fruitName = fruitName or dfAttr
        end
    end
    if fruitName and (player:GetAttribute("IsPerm") == true or player:GetAttribute("Perm") == true or player:GetAttribute("Permanent") == true) then
        isPerm = true
    end
    local scanList = {}
    if player.Character then table.insert(scanList, player.Character) end
    local bp = player:FindFirstChild("Backpack")
    if bp then table.insert(scanList, bp) end
    for _, container in ipairs(scanList) do
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local rawItemName = item.Name
                local lowerItemName = string.lower(rawItemName)
                local isToolFruit = false
                local itemIsPerm = false
                if string.find(lowerItemName, "perm") or string.find(lowerItemName, "permanent") then
                    itemIsPerm = true
                    isToolFruit = true
                end
                if string.find(lowerItemName, "fruit") or string.find(lowerItemName, "devil") then
                    isToolFruit = true
                end
                if item:GetAttribute("Permanent") == true or item:GetAttribute("IsPermanent") == true or item:GetAttribute("Perm") == true or item:GetAttribute("IsPerm") == true then
                    itemIsPerm = true
                    isToolFruit = true
                end
                if item:FindFirstChild("Permanent") or item:FindFirstChild("Perm") or item:FindFirstChild("IsPermanent") then
                    itemIsPerm = true
                    isToolFruit = true
                end
                local tip = item.ToolTip
                if tip and (string.find(string.lower(tip), "fruit") or string.find(string.lower(tip), "perm")) then
                    isToolFruit = true
                    if string.find(string.lower(tip), "perm") then
                        itemIsPerm = true
                    end
                end
                if isToolFruit then
                    table.insert(invFruitList, {
                        name = rawItemName,
                        isPerm = itemIsPerm
                    })
                    if not fruitName then
                        fruitName = rawItemName
                        if itemIsPerm then isPerm = true end
                    elseif itemIsPerm and not isPerm then
                        local cleanEq = string.gsub(fruitName, "%-.*$", "")
                        if string.find(lowerItemName, string.lower(cleanEq)) then
                            isPerm = true
                        end
                    end
                end
            end
        end
    end
    if player == LocalPlayer and (not fruitName or not isPerm) then
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local rem = rs:FindFirstChild("Remotes")
            local comm = rem and rem:FindFirstChild("CommF_")
            if comm then
                local inv = comm:InvokeServer("getInventory")
                if type(inv) == "table" then
                    for _, it in pairs(inv) do
                        if type(it) == "table" then
                            local iname = tostring(it.Name or it.id or "")
                            local itype = tostring(it.Type or "")
                            local iperm = (itype == "Perm" or itype == "Permanent" or it.Permanent == true or string.find(string.lower(iname), "perm"))
                            if iperm and fruitName and string.find(string.lower(fruitName), string.lower(string.gsub(iname, "%-.*$", ""))) then
                                isPerm = true
                            end
                        end
                    end
                end
            end
        end)
    end
    local cleanName = "Aucun"
    if fruitName and fruitName ~= "" and fruitName ~= "None" then
        cleanName = fruitName
        local p1, p2 = string.match(fruitName, "^([%w]+)%-([%w]+)$")
        if p1 and string.lower(p1) == string.lower(p2) then
            cleanName = p1
        else
            cleanName = string.gsub(cleanName, "%s*[Ff]ruit$", "")
            cleanName = string.gsub(cleanName, "^[Ff]ruit%s*%-?%s*", "")
        end
    end
    return cleanName, isPerm, invFruitList
end
local getPlayerBloxFruit = _G.getPlayerBloxFruit

bloxFruitsFruitFolder = nil
function toggleBloxFruitsFruitESP(enabled)
    V.ESPBloxFruitsFruit = enabled
    if bloxFruitsFruitFolder then
        bloxFruitsFruitFolder:Destroy()
        bloxFruitsFruitFolder = nil
    end
    if enabled then
        bloxFruitsFruitFolder = Instance.new("Folder")
        bloxFruitsFruitFolder.Name = "NebulaBloxFruitsFruitESP"
        bloxFruitsFruitFolder.Parent = ESPGui or parentTarget

        task.spawn(function()
            local notifiedFruits = {}
            while V.ESPBloxFruitsFruit do
                if not bloxFruitsFruitFolder then break end
                local activeKeys = {}

                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local char = player.Character
                        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                        if head then
                            local playerKey = "BFPlFruit_" .. player.Name
                            activeKeys[playerKey] = true
                            local fruitName, isPerm, invList = getPlayerBloxFruit(player)
                            local dist = 0
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude)
                            end

                            local displayText = ""
                            if fruitName ~= "Aucun" then
                                if isPerm then
                                    displayText = '[' .. fruitName .. '] <font color="rgb(255,50,50)">perm</font>'
                                else
                                    displayText = '[' .. fruitName .. '] <font color="rgb(160,160,175)">[Physique]</font>'
                                end
                            elseif #invList > 0 then
                                local firstFruit = invList[1]
                                if firstFruit.isPerm then
                                    displayText = '[' .. firstFruit.name .. '] <font color="rgb(255,50,50)">perm</font>'
                                else
                                    displayText = '[' .. firstFruit.name .. '] <font color="rgb(160,160,175)">[Physique]</font>'
                                end
                            else
                                displayText = '<font color="rgb(150,150,165)">[Sans Fruit]</font>'
                            end

                            local extraInvText = ""
                            if #invList > 0 and fruitName ~= "Aucun" then
                                local listNames = {}
                                for _, itm in ipairs(invList) do
                                    if itm.isPerm then
                                        table.insert(listNames, itm.name .. ' <font color="rgb(255,50,50)">perm</font>')
                                    else
                                        table.insert(listNames, itm.name)
                                    end
                                end
                                extraInvText = "Sac: " .. table.concat(listNames, ", ")
                            end

                            local bb = bloxFruitsFruitFolder:FindFirstChild(playerKey)
                            if not bb then
                                bb = Instance.new("BillboardGui")
                                bb.Name = playerKey
                                bb.Size = UDim2.new(0, 190, 0, 42)
                                bb.StudsOffset = Vector3.new(0, 4.4, 0)
                                bb.AlwaysOnTop = true
                                bb.Adornee = head
                                bb.Parent = bloxFruitsFruitFolder

                                local titleLbl = Instance.new("TextLabel")
                                titleLbl.Name = "FruitTitle"
                                titleLbl.Size = UDim2.new(1, 0, 0, 18)
                                titleLbl.Position = UDim2.new(0, 0, 0, 0)
                                titleLbl.BackgroundTransparency = 1
                                titleLbl.RichText = true
                                titleLbl.Text = displayText
                                titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                                titleLbl.TextSize = 12
                                titleLbl.Font = Enum.Font.GothamBold
                                titleLbl.TextStrokeTransparency = 0.2
                                titleLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                titleLbl.Parent = bb

                                local distLbl = Instance.new("TextLabel")
                                distLbl.Name = "FruitDist"
                                distLbl.Size = UDim2.new(1, 0, 0, 14)
                                distLbl.Position = UDim2.new(0, 0, 0, 18)
                                distLbl.BackgroundTransparency = 1
                                distLbl.RichText = true
                                distLbl.Text = "[" .. tostring(dist) .. " studs]" .. (extraInvText ~= "" and (" | " .. extraInvText) or "")
                                distLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
                                distLbl.TextSize = 10
                                distLbl.Font = Enum.Font.GothamMedium
                                distLbl.TextStrokeTransparency = 0.2
                                distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                distLbl.Parent = bb
                            else
                                bb.Adornee = head
                                local titleLbl = bb:FindFirstChild("FruitTitle")
                                if titleLbl then
                                    titleLbl.Text = displayText
                                end
                                local distLbl = bb:FindFirstChild("FruitDist")
                                if distLbl then
                                    distLbl.Text = "[" .. tostring(dist) .. " studs]" .. (extraInvText ~= "" and (" | " .. extraInvText) or "")
                                end
                            end
                        end
                    end
                end

                local function checkGroundFruit(obj)
                    if not obj then return end
                    local isFruit = false
                    local fruitName = obj.Name
                    if obj:IsA("Tool") and (string.find(string.lower(fruitName), "fruit") or string.find(string.lower(fruitName), "devil")) then
                        isFruit = true
                    elseif obj:IsA("Model") and (string.find(string.lower(fruitName), "fruit") or string.find(string.lower(fruitName), "devil")) then
                        isFruit = true
                    elseif obj:IsA("BasePart") and (string.find(string.lower(fruitName), "fruit") or string.find(string.lower(fruitName), "devil")) then
                        isFruit = true
                    end
                    if isFruit then
                        local handle = obj:IsA("BasePart") and obj or (obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart"))
                        if handle then
                            local groundKey = "BFGndFruit_" .. (obj:GetDebugId() or (fruitName .. "_" .. tostring(handle.Position.X)))
                            activeKeys[groundKey] = true
                            if not notifiedFruits[groundKey] then
                                notifiedFruits[groundKey] = true
                                notify("Blox Fruits", "Fruit detecte au sol : " .. fruitName, Color3.fromRGB(175, 110, 255))
                            end
                            local dist = 0
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - handle.Position).Magnitude)
                            end
                            local bb = bloxFruitsFruitFolder:FindFirstChild(groundKey)
                            if not bb then
                                bb = Instance.new("BillboardGui")
                                bb.Name = groundKey
                                bb.Size = UDim2.new(0, 160, 0, 36)
                                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                                bb.AlwaysOnTop = true
                                bb.Adornee = handle
                                bb.Parent = bloxFruitsFruitFolder

                                local titleLbl = Instance.new("TextLabel")
                                titleLbl.Name = "FruitTitle"
                                titleLbl.Size = UDim2.new(1, 0, 0, 18)
                                titleLbl.Position = UDim2.new(0, 0, 0, 0)
                                titleLbl.BackgroundTransparency = 1
                                titleLbl.RichText = true
                                titleLbl.Text = '<font color="rgb(255,215,0)">[Sol] ' .. fruitName .. '</font>'
                                titleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                                titleLbl.TextSize = 12
                                titleLbl.Font = Enum.Font.GothamBold
                                titleLbl.TextStrokeTransparency = 0.2
                                titleLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                titleLbl.Parent = bb

                                local distLbl = Instance.new("TextLabel")
                                distLbl.Name = "FruitDist"
                                distLbl.Size = UDim2.new(1, 0, 0, 14)
                                distLbl.Position = UDim2.new(0, 0, 0, 18)
                                distLbl.BackgroundTransparency = 1
                                distLbl.Text = "[" .. tostring(dist) .. " studs]"
                                distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                                distLbl.TextSize = 10
                                distLbl.Font = Enum.Font.GothamMedium
                                distLbl.TextStrokeTransparency = 0.2
                                distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                distLbl.Parent = bb

                                local hl = Instance.new("Highlight")
                                hl.Name = "FruitHighlight"
                                hl.Adornee = obj
                                hl.FillColor = Color3.fromRGB(175, 110, 255)
                                hl.FillTransparency = 0.5
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.OutlineTransparency = 0.2
                                hl.Parent = bb
                            else
                                bb.Adornee = handle
                                local distLbl = bb:FindFirstChild("FruitDist")
                                if distLbl then
                                    distLbl.Text = "[" .. tostring(dist) .. " studs]"
                                end
                            end
                        end
                    end
                end

                for _, obj in pairs(workspace:GetChildren()) do
                    checkGroundFruit(obj)
                end
                local map = workspace:FindFirstChild("Map")
                if map then
                    for _, obj in pairs(map:GetChildren()) do
                        checkGroundFruit(obj)
                    end
                end

                for _, child in pairs(bloxFruitsFruitFolder:GetChildren()) do
                    if not activeKeys[child.Name] then
                        child:Destroy()
                    end
                end

                task.wait(1.2)
            end
        end)
    end
end
createToggle('Esp Fruit (<font color="rgb(175,110,255)">Bloxfruit</font>)', false, function(enabled)
    toggleBloxFruitsFruitESP(enabled)
end, ESPContent, "ESPBloxFruitsFruit")

arrowESPList = {}
ArrowGui = Instance.new("ScreenGui")
ArrowGui.Name = "NebulaArrowGui"
ArrowGui.ResetOnSpawn = false
ArrowGui.DisplayOrder = 9999
ArrowGui.IgnoreGuiInset = true
ArrowGui.Enabled = true
ArrowGui.Parent = parentTarget

function cleanupArrowESP()
    for _, arrow in pairs(arrowESPList) do
        pcall(function() arrow:Destroy() end)
    end
    arrowESPList = {}
end
_G.cleanupArrowESP = cleanupArrowESP

function toggleArrowESP(enabled)
    V.ArrowESP = enabled
    if V.ArrowESPConn then V.ArrowESPConn:Disconnect() V.ArrowESPConn = nil end
    cleanupArrowESP()

    if enabled then
        V.ArrowESPConn = RunService.RenderStepped:Connect(function()
            if not V.ArrowESP then return end
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHrp then
                for _, a in pairs(arrowESPList) do a.Visible = false end
                return
            end

            local vp = Camera.ViewportSize
            local screenCenter = Vector2.new(vp.X / 2, vp.Y / 2)
            local radius = 120

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local pHrp = player.Character:FindFirstChild("HumanoidRootPart")
                    local pHum = player.Character:FindFirstChildOfClass("Humanoid")
                    if pHrp and pHum and pHum.Health > 0 then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(pHrp.Position)

                        local arrow = arrowESPList[player]
                        if not arrow then
                            arrow = Instance.new("Frame")
                            arrow.Name = "ArrowESP_" .. player.Name
                            arrow.Size = UDim2.new(0, 16, 0, 16)
                            arrow.AnchorPoint = Vector2.new(0.5, 0.5)
                            arrow.BackgroundColor3 = V.ESPColor or Color3.fromRGB(255, 50, 75)
                            arrow.BorderSizePixel = 0
                            arrow.ZIndex = 50
                            arrow.Parent = ArrowGui

                            local corner = Instance.new("UICorner")
                            corner.CornerRadius = UDim.new(0, 4)
                            corner.Parent = arrow

                            local stroke = Instance.new("UIStroke")
                            stroke.Color = Color3.fromRGB(255, 255, 255)
                            stroke.Thickness = 1.2
                            stroke.Parent = arrow

                            local pointer = Instance.new("Frame")
                            pointer.Name = "Pointer"
                            pointer.Size = UDim2.new(0, 8, 0, 8)
                            pointer.Position = UDim2.new(0.5, -4, 0, -4)
                            pointer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            pointer.Rotation = 45
                            pointer.BorderSizePixel = 0
                            pointer.ZIndex = 51
                            pointer.Parent = arrow

                            local nameTag = Instance.new("TextLabel")
                            nameTag.Name = "NameTag"
                            nameTag.Size = UDim2.new(0, 110, 0, 14)
                            nameTag.Position = UDim2.new(0.5, -55, 1, 4)
                            nameTag.BackgroundTransparency = 1
                            nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
                            nameTag.TextStrokeTransparency = 0.2
                            nameTag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            nameTag.Font = Enum.Font.GothamBold
                            nameTag.TextSize = 10
                            nameTag.ZIndex = 52
                            nameTag.Parent = arrow

                            arrowESPList[player] = arrow
                        end

                        local color = V.ESPColor or Color3.fromRGB(255, 50, 75)
                        arrow.BackgroundColor3 = color

                        local targetScreenPos
                        if screenPos.Z < 0 then
                            targetScreenPos = Vector2.new(vp.X - screenPos.X, vp.Y - screenPos.Y)
                        else
                            targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                        end

                        local dir = (targetScreenPos - screenCenter).Unit
                        if dir.Magnitude == 0 or dir.X ~= dir.X then
                            dir = Vector2.new(0, 1)
                        end

                        local dist = math.floor((pHrp.Position - myHrp.Position).Magnitude)
                        local tag = arrow:FindFirstChild("NameTag")
                        if tag then
                            tag.Text = string.format("%s [%dm]", player.DisplayName, dist)
                        end

                        arrow.Position = UDim2.new(0, screenCenter.X + (dir.X * radius), 0, screenCenter.Y + (dir.Y * radius))
                        arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
                        arrow.Visible = true
                    else
                        if arrowESPList[player] then
                            arrowESPList[player].Visible = false
                        end
                    end
                end
            end
        end)
        addConnection(V.ArrowESPConn)
        notify("ESP", "Arrow ESP (Flèches Ennemis) ACTIVÉ", Color3.fromRGB(80, 200, 120))
    else
        notify("ESP", "Arrow ESP DÉSACTIVÉ", Color3.fromRGB(255, 90, 90))
    end
end
_G.toggleArrowESP = toggleArrowESP

createToggle("Arrow ESP (Flèches Ennemis)", false, function(enabled)
    toggleArrowESP(enabled)
end, ESPContent, "ArrowESP")

tracerOriginsList = {"Bottom","Center","Mouse"}
currentOriginIdx = 1
tracerOriginFrame, tracerBtnObj, tracerOriginValue = createValueButton(ESPContent, "Tracer Origin", V.ESPTracerOrigin, function()
    currentOriginIdx = (currentOriginIdx % #tracerOriginsList) + 1
    V.ESPTracerOrigin = tracerOriginsList[currentOriginIdx]
    notify("ESP","Origine des Tracers : ".. V.ESPTracerOrigin, Color3.fromRGB(80, 200, 120))
    return V.ESPTracerOrigin
end)

createLabel("COLOR PALETTE", ESPContent)
do
    local PaletteFrame = Instance.new("Frame")
    PaletteFrame.Size = UDim2.new(1, 0, 0, 40)
    PaletteFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    PaletteFrame.BorderSizePixel = 0
    PaletteFrame.Parent = ESPContent

    local PaletteCorner = Instance.new("UICorner")
    PaletteCorner.CornerRadius = UDim.new(0, 8)
    PaletteCorner.Parent = PaletteFrame

    local PaletteLayout = Instance.new("UIListLayout")
    PaletteLayout.FillDirection = Enum.FillDirection.Horizontal
    PaletteLayout.Padding = UDim.new(0, 6)
    PaletteLayout.Parent = PaletteFrame

    local PalettePadding = Instance.new("UIPadding")
    PalettePadding.PaddingLeft = UDim.new(0, 10)
    PalettePadding.PaddingTop = UDim.new(0, 7)
    PalettePadding.Parent = PaletteFrame

    local function createPaletteColor(color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 26, 0, 26)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text =""
        btn.Parent = PaletteFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = Color3.fromRGB(80, 80, 90)
        stroke.Transparency = 0.6
        stroke.Parent = btn

        btn.MouseButton1Click:Connect(function()
            V.ESPColor = color
            notify("ESP","Color changed", color)
        end)
    end

    createPaletteColor(Color3.fromRGB(255, 60, 60))
    createPaletteColor(Color3.fromRGB(60, 120, 255))
    createPaletteColor(Color3.fromRGB(60, 255, 100))
    createPaletteColor(Color3.fromRGB(255, 255, 255))
    createPaletteColor(Color3.fromRGB(180, 60, 255))
    createPaletteColor(Color3.fromRGB(145, 120, 255))
    createPaletteColor(Color3.fromRGB(255, 180, 60))
end

initStep = "cablage Aim"
createLabel("AIMBOT & CAMERA LOCK", AimContent)

_, SetAimlockToggle, ToggleAimlock = createToggle("Enable Aimlock (Verrouillage)", false, function(enabled)
    Aimlock_Enabled = enabled
    _G.Aimlock_Enabled = enabled
    if SilentAimCircle then SilentAimCircle.Visible = enabled and (_G.Aimlock_ShowFOV or Aimlock_ShowFOV) end
    notify("Aim", "Aimlock " .. (enabled and "ON" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, AimContent, "Aimlock")

createToggle("Hold Mode (Maintenir la touche)", false, function(enabled)
    Aimlock_HoldMode = enabled
    _G.Aimlock_HoldMode = enabled
end, AimContent, "AimlockHold")

AimlockKeyBtn = nil
do
    local AimKeyCard = createCard(AimContent, 0, 46)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Aimlock Keybind"
    title.TextColor3 = theme.text
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 8
    title.Parent = AimKeyCard

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 68, 0, 26)
    keyBtn.Position = UDim2.new(1, -78, 0.5, -13)
    keyBtn.BackgroundColor3 = theme.cardHover
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = "[" .. tostring(_G.Aimlock_KeyName or "E") .. "]"
    keyBtn.TextColor3 = theme.accent
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 10
    keyBtn.ZIndex = 9
    keyBtn.Parent = AimKeyCard
    makeCorner(keyBtn, 8)
    makeStroke(keyBtn, theme.border, 1)
    AimlockKeyBtn = keyBtn
    KeybindButtons["Aimlock"] = keyBtn

    local waitingAimKey = false
    keyBtn.MouseButton1Click:Connect(function()
        waitingAimKey = true
        keyBtn.Text = "[...]"
        keyBtn.TextColor3 = Color3.fromRGB(255, 170, 0)
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if waitingAimKey then
            local chosenKey, keyName = nil, nil
            if input.UserInputType == Enum.UserInputType.Keyboard then
                chosenKey = input.KeyCode
                keyName = string.sub(tostring(input.KeyCode), 14)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                chosenKey = Enum.UserInputType.MouseButton1
                keyName = "M1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                chosenKey = Enum.UserInputType.MouseButton2
                keyName = "M2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                chosenKey = Enum.UserInputType.MouseButton3
                keyName = "M3"
            end
            if chosenKey then
                _G.Aimlock_Key = chosenKey
                Aimlock_Key = chosenKey
                _G.Aimlock_KeyName = keyName
                Aimlock_KeyName = keyName
                keyBtn.Text = "[" .. keyName .. "]"
                keyBtn.TextColor3 = theme.accent
                waitingAimKey = false
                notify("Keybind", "Aimlock bind: " .. keyName, Color3.fromRGB(80, 200, 120))
            end
        end
    end)
end

aimPartFrame, aimPartBtnObj, aimPartValue = createValueButton(AimContent, "Target Part (Partie Visée)", "Head", function()
    local parts = {"Head", "HumanoidRootPart", "UpperTorso"}
    local current = _G.Aimlock_TargetPart or Aimlock_TargetPart or "Head"
    local idx = table.find(parts, current) or 1
    idx = (idx % #parts) + 1
    local newPart = parts[idx]
    _G.Aimlock_TargetPart = newPart
    Aimlock_TargetPart = newPart
    notify("Aim", "Cible: " .. newPart, Color3.fromRGB(80, 200, 120))
    return newPart
end)

createSlider("Aim Smoothness (1 = Instant)", 1, 10, 1, function(val)
    Aimlock_Smoothness = val
    _G.Aimlock_Smoothness = val
end, AimContent, "AimSmoothness")

createSlider("FOV Radius (Rayon du Cercle)", 30, 500, 150, function(val)
    Aimlock_FOV = val
    _G.Aimlock_FOV = val
    if SilentAimCircle then SilentAimCircle.Radius = val end
end, AimContent, "AimFOV")

createToggle("Wallcheck (Vérification Murs)", true, function(enabled)
    Aimlock_Wallcheck = enabled
    _G.Aimlock_Wallcheck = enabled
end, AimContent, "AimWallcheck")

createToggle("Team Check (Ignorer Allis)", true, function(enabled)
    Aimlock_TeamCheck = enabled
    _G.Aimlock_TeamCheck = enabled
    notify("Aim", "Aimlock Team Check " .. (enabled and "ON" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, AimContent, "AimTeamCheck")

createToggle("Show FOV Circle (Afficher Cercle)", true, function(enabled)
    Aimlock_ShowFOV = enabled
    _G.Aimlock_ShowFOV = enabled
    if SilentAimCircle then SilentAimCircle.Visible = (_G.Aimlock_Enabled or Aimlock_Enabled) and enabled end
end, AimContent, "AimShowFOV")

createToggle("Movement Prediction (Prédiction)", true, function(enabled)
    Aimlock_Prediction = enabled
    _G.Aimlock_Prediction = enabled
end, AimContent, "AimPrediction")

createSlider("Prediction Strength (Force 0.5x - 2.5x)", 5, 25, 10, function(val)
    local factor = val / 10
    Aimlock_PredictionBoost = factor
    _G.Aimlock_PredictionBoost = factor
end, AimContent, "AimPredStrength")

createToggle("Target NPCs (Cibler les PNJ)", false, function(enabled)
    Aimlock_TargetNPCs = enabled
    _G.Aimlock_TargetNPCs = enabled
end, AimContent, "AimTargetNPCs")

tracerColors = { Color3.fromRGB(180, 70, 255), Color3.fromRGB(0, 240, 255) }
tracerColorIdx = 1

function spawnNeonTracer(startPos, endPos)
    pcall(function()
        local dist = (endPos - startPos).Magnitude
        if dist < 0.5 then return end
        
        local part = Instance.new("Part")
        part.Name = "NebulaNeonBulletTracer"
        part.Anchored = true
        part.CanCollide = false
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        tracerColorIdx = (tracerColorIdx % #tracerColors) + 1
        part.Color = tracerColors[tracerColorIdx]
        part.Size = Vector3.new(0.08, 0.08, dist)
        part.CFrame = CFrame.lookAt((startPos + endPos) / 2, endPos)
        part.Parent = workspace

        local tw = TweenService:Create(part, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1,
            Size = Vector3.new(0.01, 0.01, dist)
        })
        tw:Play()
        task.delay(0.7, function()
            pcall(function() part:Destroy() end)
        end)
    end)
end
_G.spawnNeonTracer = spawnNeonTracer

local lastTracerTick = 0
local function fireBulletTracer()
    if not V.BulletTracers then return end
    local now = tick()
    if now - lastTracerTick < 0.04 then return end
    lastTracerTick = now

    local char = LocalPlayer.Character
    if not char then return end
    local cam = workspace.CurrentCamera

    local startPos = nil
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local muzzle = tool:FindFirstChild("Muzzle", true)
            or tool:FindFirstChild("Barrel", true)
            or tool:FindFirstChild("MuzzlePoint", true)
            or tool:FindFirstChild("FirePoint", true)
            or tool:FindFirstChild("Tip", true)
            or tool:FindFirstChild("Handle", true)
            or tool:FindFirstChildWhichIsA("BasePart", true)
        if muzzle then startPos = muzzle.Position end
    end
    if not startPos then
        local hand = char:FindFirstChild("RightHand")
            or char:FindFirstChild("Right Arm")
            or char:FindFirstChild("Head")
            or char:FindFirstChild("HumanoidRootPart")
        if hand then startPos = hand.Position end
    end
    if not startPos and cam then
        startPos = cam.CFrame.Position + (cam.CFrame.LookVector * 1.5)
    end
    if not startPos then return end

    local endPos = nil
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Hit then
        endPos = mouse.Hit.Position
    end
    if not endPos and cam then
        local mPos = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(mPos.X, mPos.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {char}
        local res = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if res then
            endPos = res.Position
        else
            endPos = ray.Origin + (ray.Direction * 600)
        end
    end

    if endPos then
        spawnNeonTracer(startPos, endPos)
    end
end

function hookBulletTracers()
    if V.BulletTracerClickConn then V.BulletTracerClickConn:Disconnect() V.BulletTracerClickConn = nil end
    if V.BulletTracerEquipConn then V.BulletTracerEquipConn:Disconnect() V.BulletTracerEquipConn = nil end
    if V.BulletTracerToolConn then V.BulletTracerToolConn:Disconnect() V.BulletTracerToolConn = nil end

    V.BulletTracerClickConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not V.BulletTracers then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if UserInputService:GetFocusedTextBox() then return end
            fireBulletTracer()
        end
    end)
    addConnection(V.BulletTracerClickConn)

    local function bindTool(tool)
        if not tool or not tool:IsA("Tool") then return end
        if V.BulletTracerToolConn then V.BulletTracerToolConn:Disconnect() V.BulletTracerToolConn = nil end
        V.BulletTracerToolConn = tool.Activated:Connect(function()
            if not V.BulletTracers then return end
            fireBulletTracer()
        end)
        addConnection(V.BulletTracerToolConn)
    end

    local char = LocalPlayer.Character
    if char then
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool then bindTool(currentTool) end
        V.BulletTracerEquipConn = char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then bindTool(child) end
        end)
        addConnection(V.BulletTracerEquipConn)
    end
end

function toggleBulletTracers(enabled)
    V.BulletTracers = enabled
    if V.BulletTracerClickConn then V.BulletTracerClickConn:Disconnect() V.BulletTracerClickConn = nil end
    if V.BulletTracerEquipConn then V.BulletTracerEquipConn:Disconnect() V.BulletTracerEquipConn = nil end
    if V.BulletTracerToolConn then V.BulletTracerToolConn:Disconnect() V.BulletTracerToolConn = nil end
    if enabled then
        hookBulletTracers()
        notify("Aim", "Bullet Tracers Néon (Violet/Cyan) ACTIVÉS", Color3.fromRGB(80, 200, 120))
    else
        notify("Aim", "Bullet Tracers Néon DÉSACTIVÉS", Color3.fromRGB(255, 90, 90))
    end
end
_G.toggleBulletTracers = toggleBulletTracers

createToggle("Bullet Tracers Néon (Violet/Cyan)", false, function(enabled)
    toggleBulletTracers(enabled)
end, AimContent, "BulletTracers")

initStep = "cablage Teleport/Joueur"
createLabel("WAYPOINTS", TeleportContent)
do
    local WaypointInputFrame = Instance.new("Frame")
    WaypointInputFrame.Size = UDim2.new(1, 0, 0, 40)
    WaypointInputFrame.BackgroundColor3 = Color3.fromRGB(20,20, 25)
    WaypointInputFrame.BorderSizePixel = 0
    WaypointInputFrame.Parent = TeleportContent

    local WaypointInputCorner = Instance.new("UICorner")
    WaypointInputCorner.CornerRadius = UDim.new(0, 8)
    WaypointInputCorner.Parent = WaypointInputFrame

    local WaypointNameBox = Instance.new("TextBox")
    WaypointNameBox.Size = UDim2.new(0.6, 0, 0, 30)
    WaypointNameBox.Position = UDim2.new(0, 8, 0.5, -15)
    WaypointNameBox.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    WaypointNameBox.BorderSizePixel = 0
    WaypointNameBox.PlaceholderText ="Nom du point..."
    WaypointNameBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
    WaypointNameBox.Text =""
    WaypointNameBox.TextColor3 = Color3.fromRGB(210, 210, 222)
    WaypointNameBox.Font = Enum.Font.GothamMedium
    WaypointNameBox.TextSize = 12
    WaypointNameBox.TextXAlignment = Enum.TextXAlignment.Left
    WaypointNameBox.Parent = WaypointInputFrame

    local WaypointNameBoxCorner = Instance.new("UICorner")
    WaypointNameBoxCorner.CornerRadius = UDim.new(0, 5)
    WaypointNameBoxCorner.Parent = WaypointNameBox

    local WaypointNamePadding = Instance.new("UIPadding")
    WaypointNamePadding.PaddingLeft = UDim.new(0, 8)
    WaypointNamePadding.Parent = WaypointNameBox

    local AddWaypointBtn = Instance.new("TextButton")
    AddWaypointBtn.Size = UDim2.new(0, 70, 0, 30)
    AddWaypointBtn.Position = UDim2.new(1, -78, 0.5, -15)
    AddWaypointBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    AddWaypointBtn.BorderSizePixel = 0
    AddWaypointBtn.Text ="Ajouter"
    AddWaypointBtn.TextColor3 = Color3.fromRGB(195, 195, 208)
    AddWaypointBtn.Font = Enum.Font.GothamMedium
    AddWaypointBtn.TextSize = 11
    AddWaypointBtn.Parent = WaypointInputFrame

    local AddWaypointBtnCorner = Instance.new("UICorner")
    AddWaypointBtnCorner.CornerRadius = UDim.new(0, 5)
    AddWaypointBtnCorner.Parent = AddWaypointBtn

    local WaypointList = Instance.new("ScrollingFrame")
    WaypointList.Size = UDim2.new(1, 0, 1, -55)
    WaypointList.Position = UDim2.new(0, 0, 0, 45)
    WaypointList.BackgroundTransparency = 1
    WaypointList.CanvasSize = UDim2.new(0, 0, 0, 0)
    WaypointList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    WaypointList.ScrollBarThickness = 2
    WaypointList.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 55)
    WaypointList.Parent = TeleportContent

    local WaypointListLayout = Instance.new("UIListLayout")
    WaypointListLayout.Padding = UDim.new(0, 5)
    WaypointListLayout.Parent = WaypointList

    local wpCounter = 1
    local function refreshWaypointList()
        for _, child in pairs(WaypointList:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for wpName, wpData in pairs(Nebula.TeleportPoints) do
            local wpFrame = Instance.new("Frame")
            wpFrame.Size = UDim2.new(1, 0, 0, 38)
            wpFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            wpFrame.BorderSizePixel = 0
            wpFrame.Parent = WaypointList

            local wpFrameCorner = Instance.new("UICorner")
            wpFrameCorner.CornerRadius = UDim.new(0, 8)
            wpFrameCorner.Parent = wpFrame

            local wpLabel = Instance.new("TextLabel")
            wpLabel.Size = UDim2.new(0.5, 0, 1, 0)
            wpLabel.Position = UDim2.new(0, 14, 0, 0)
            wpLabel.BackgroundTransparency = 1
            wpLabel.Text = wpData.Name
            wpLabel.TextColor3 = Color3.fromRGB(195, 195, 208)
            wpLabel.Font = Enum.Font.GothamMedium
            wpLabel.TextSize = 12
            wpLabel.TextXAlignment = Enum.TextXAlignment.Left
            wpLabel.Parent = wpFrame

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 55, 0, 26)
            tpBtn.Position = UDim2.new(1, -130, 0.5, -13)
            tpBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
            tpBtn.BorderSizePixel = 0
            tpBtn.Text ="TP"
            tpBtn.TextColor3 = Color3.fromRGB(170, 170, 182)
            tpBtn.Font = Enum.Font.GothamMedium
            tpBtn.TextSize = 10
            tpBtn.Parent = wpFrame

            local tpBtnCorner = Instance.new("UICorner")
            tpBtnCorner.CornerRadius = UDim.new(0, 5)
            tpBtnCorner.Parent = tpBtn

            tpBtn.MouseButton1Click:Connect(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(wpData.Position)
                    notify("Teleport","Teleported to".. wpData.Name, Color3.fromRGB(80, 200, 120))
                end
            end)

            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 60, 0, 26)
            delBtn.Position = UDim2.new(1, -65, 0.5, -13)
            delBtn.BackgroundColor3 = Color3.fromRGB(40, 22, 22)
            delBtn.BorderSizePixel = 0
            delBtn.Text ="Delete"
            delBtn.TextColor3 = Color3.fromRGB(170, 110, 110)
            delBtn.Font = Enum.Font.GothamMedium
            delBtn.TextSize = 10
            delBtn.Parent = wpFrame

            local delBtnCorner = Instance.new("UICorner")
            delBtnCorner.CornerRadius = UDim.new(0, 5)
            delBtnCorner.Parent = delBtn

            delBtn.MouseButton1Click:Connect(function()
                Nebula.TeleportPoints[wpName] = nil
                refreshWaypointList()
                notify("Teleport","Deleted".. wpData.Name, Color3.fromRGB(255, 90, 90))
            end)
        end
    end

    AddWaypointBtn.MouseButton1Click:Connect(function()
        local name = WaypointNameBox.Text
        if name ==""then
            name ="Point_".. wpCounter
            wpCounter = wpCounter + 1
        end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            Nebula.TeleportPoints[name .."_".. tostring(os.clock())] = {Position = char.HumanoidRootPart.Position, Name = name}
            WaypointNameBox.Text =""
            refreshWaypointList()
            notify("Teleport","Waypoint'".. name .."'added!", Color3.fromRGB(80, 200, 120))
        end
    end)
end

_G.teleportToPlayer = function(targetPlayer)
    if not targetPlayer then return end
    pcall(function()
        local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local tChar = targetPlayer.Character
        if not myChar or not tChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart
        local tRoot = tChar:FindFirstChild("HumanoidRootPart") or tChar.PrimaryPart
        if myRoot and tRoot then
            myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 2, 2)
            notify("Teleport", "Téléporté à " .. targetPlayer.DisplayName, Color3.fromRGB(80, 200, 120))
        end
    end)
end
local teleportToPlayer = _G.teleportToPlayer

_G.stopAttach = function()
    V.Attached = nil
    if V.AttachConn then
        pcall(function() V.AttachConn:Disconnect() end)
        V.AttachConn = nil
    end
    notify("Player", "Détaché du joueur", Color3.fromRGB(255, 90, 90))
end
local stopAttach = _G.stopAttach

_G.startAttach = function(player)
    if not player then return end
    if V.Attached then
        stopAttach()
    end
    V.Attached = player
    V.AttachConn = RunService.RenderStepped:Connect(function()
        pcall(function()
            if not V.Attached or not V.Attached.Parent then
                stopAttach()
                return
            end
            local myChar = LocalPlayer.Character
            local tChar = V.Attached.Character
            if myChar and tChar then
                local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                if myRoot and tRoot then
                    myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.2)
                end
            end
        end)
    end)
    addConnection(V.AttachConn)
    notify("Player", "Attaché à " .. player.DisplayName, Color3.fromRGB(80, 200, 120))
end
local startAttach = _G.startAttach

_G.toggleAttach = function(player)
    if V.Attached and (V.Attached == player or player == nil) then
        stopAttach()
    else
        startAttach(player)
    end
end

_G.stopAttachBloxFruit = function()
    V.AttachedBloxFruit = nil
    if V.AttachBloxFruitConn then
        pcall(function() V.AttachBloxFruitConn:Disconnect() end)
        V.AttachBloxFruitConn = nil
    end
    if V.AttachBloxFruitNoclip then
        pcall(function() V.AttachBloxFruitNoclip:Disconnect() end)
        V.AttachBloxFruitNoclip = nil
    end
    pcall(function()
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if myHum then
            myHum.PlatformStand = false
        end
    end)
    notify("Player", "Détaché (BloxFruit)", Color3.fromRGB(255, 90, 90))
end
local stopAttachBloxFruit = _G.stopAttachBloxFruit

_G.startAttachBloxFruit = function(targetPlayer)
    if not targetPlayer then return end
    if V.AttachedBloxFruit then
        stopAttachBloxFruit()
    end
    if V.Attached then
        if _G.stopAttach then _G.stopAttach() elseif stopAttach then stopAttach() end
    end

    V.AttachedBloxFruit = targetPlayer

    V.AttachBloxFruitNoclip = RunService.Stepped:Connect(function()
        if not V.AttachedBloxFruit then
            if V.AttachBloxFruitNoclip then
                pcall(function() V.AttachBloxFruitNoclip:Disconnect() end)
                V.AttachBloxFruitNoclip = nil
            end
            return
        end
        local myChar = LocalPlayer.Character
        if myChar then
            for _, part in ipairs(myChar:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
    addConnection(V.AttachBloxFruitNoclip)

    V.AttachBloxFruitConn = RunService.Heartbeat:Connect(function(dt)
        pcall(function()
            if not V.AttachedBloxFruit or not V.AttachedBloxFruit.Parent then
                stopAttachBloxFruit()
                return
            end
            local myChar = LocalPlayer.Character
            local tChar = V.AttachedBloxFruit.Character
            if not myChar or not tChar then return end

            local myRoot = myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart
            local myHum = myChar:FindFirstChildOfClass("Humanoid")
            local tRoot = tChar:FindFirstChild("HumanoidRootPart") or tChar.PrimaryPart
            local tHum = tChar:FindFirstChildOfClass("Humanoid")

            if not myRoot or not tRoot or (tHum and tHum.Health <= 0) then
                stopAttachBloxFruit()
                return
            end

            if myHum then
                myHum.PlatformStand = true
            end

            local targetCF = tRoot.CFrame * CFrame.new(0, 3, 2)
            local targetPos = targetCF.Position
            local diff = targetPos - myRoot.Position
            local dist = diff.Magnitude
            local flySpeed = 230

            if dist > 3 then
                local step = math.min(flySpeed * dt, dist)
                local dir = diff.Unit
                local newPos = myRoot.Position + dir * step
                myRoot.CFrame = CFrame.new(newPos, targetPos)
            else
                myRoot.CFrame = targetCF
            end

            if myRoot:IsA("BasePart") then
                myRoot.AssemblyLinearVelocity = Vector3.zero
                myRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end)
    addConnection(V.AttachBloxFruitConn)

    notify("Player", "Glisse (230) vers " .. targetPlayer.DisplayName .. "...", Color3.fromRGB(175, 110, 255))
end
local startAttachBloxFruit = _G.startAttachBloxFruit



_G.sitInSeat = function(hum, hrp, seat)
    if not hum or not hrp or not seat then return false end
    pcall(function()
        hum.Sit = false
        hum.PlatformStand = false
        local myChar = hum.Parent
        if myChar then
            for _, v in ipairs(myChar:GetDescendants()) do
                if v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("Snap") then
                    if v.Name == "SeatWeld" or (v.Part0 and (v.Part0:IsA("Seat") or v.Part0:IsA("VehicleSeat"))) or (v.Part1 and (v.Part1:IsA("Seat") or v.Part1:IsA("VehicleSeat"))) then
                        pcall(function() v:Destroy() end)
                    end
                end
            end
        end
        if seat:FindFirstChild("SeatWeld") then
            pcall(function() seat.SeatWeld:Destroy() end)
        end
    end)
    hrp.CFrame = seat.CFrame
    task.wait(0.01)
    pcall(function() seat:Sit(hum) end)
    task.wait(0.02)
    if hum.SeatPart ~= seat then
        pcall(function() seat:Sit(hum) end)
    end
    return hum.SeatPart == seat
end
local sitInSeat = _G.sitInSeat

_G.isSeatFree = function(seat)
    if not seat or not seat:IsA("BasePart") then return false end
    local occ = seat.Occupant
    if occ and occ.Parent and occ.Parent ~= LocalPlayer.Character then
        return false
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.SeatPart == seat then
                return false
            end
        end
    end
    return true
end
local isSeatFree = _G.isSeatFree

_G.warpToPlayerCar = function(targetPlayer)
    local success, err = pcall(function()
        if not targetPlayer then
            notify("Player", "Joueur introuvable !", Color3.fromRGB(255, 90, 90))
            return
        end

        local tChar = targetPlayer.Character
        if not tChar then
            notify("Player", targetPlayer.DisplayName .. " n'a pas de personnage !", Color3.fromRGB(255, 165, 0))
            return
        end

        local tHum = tChar:FindFirstChildOfClass("Humanoid")
        local tRoot = tChar:FindFirstChild("HumanoidRootPart") or tChar.PrimaryPart
        if not tHum or not tRoot then
            notify("Player", "Personnage de " .. targetPlayer.DisplayName .. " incomplet !", Color3.fromRGB(255, 165, 0))
            return
        end

        local tSeat = tHum.SeatPart
        if not tSeat then
            for _, child in ipairs(tChar:GetDescendants()) do
                if child:IsA("Weld") or child:IsA("WeldConstraint") then
                    local part0 = child.Part0
                    local part1 = child.Part1
                    if part0 and (part0:IsA("VehicleSeat") or part0:IsA("Seat")) then
                        tSeat = part0
                        break
                    elseif part1 and (part1:IsA("VehicleSeat") or part1:IsA("Seat")) then
                        tSeat = part1
                        break
                    end
                end
            end
        end

        if not tSeat then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                    if obj.Occupant == tHum then
                        tSeat = obj
                        break
                    elseif (obj.Position - tRoot.Position).Magnitude < 5 then
                        tSeat = obj
                        break
                    end
                end
            end
        end

        if not tSeat then
            notify("Player", targetPlayer.DisplayName .. " n'est pas dans un véhicule !", Color3.fromRGB(255, 165, 0))
            return
        end

        local veh = tSeat:FindFirstAncestorWhichIsA("Model") or tSeat.Parent
        if not veh then
            notify("Player", "Modèle de véhicule introuvable !", Color3.fromRGB(255, 90, 90))
            return
        end

        local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHum or not myHrp then return end

        local freeSeat = nil
        for _, obj in ipairs(veh:GetDescendants()) do
            if (obj:IsA("VehicleSeat") or obj:IsA("Seat")) and obj ~= tSeat then
                if isSeatFree(obj) then
                    freeSeat = obj
                    break
                end
            end
        end

        if freeSeat then
            if _G.sitInSeat then
                _G.sitInSeat(myHum, myHrp, freeSeat)
            else
                myHrp.CFrame = freeSeat.CFrame
                task.wait(0.03)
                pcall(function() freeSeat:Sit(myHum) end)
            end
            notify("Player", "TP dans la voiture de " .. targetPlayer.DisplayName .. " !", Color3.fromRGB(80, 200, 120))
        else
            local seatCF = tSeat.CFrame
            myHrp.CFrame = seatCF * CFrame.new(0, 4, 0)
            notify("Player", "Voiture de " .. targetPlayer.DisplayName .. " (1 place/Pleine) ! TP sur le véhicule.", Color3.fromRGB(255, 165, 0))
        end
    end)

    if not success then
        warn("[Nebula] Erreur WarpCar: " .. tostring(err))
        notify("Player", "Erreur lors du TP Voiture !", Color3.fromRGB(255, 90, 90))
    end
end
local warpToPlayerCar = _G.warpToPlayerCar

_G.carjackPlayer = function(targetPlayer)
    local success, err = pcall(function()
        if not targetPlayer then
            notify("Carjack", "Joueur introuvable !", Color3.fromRGB(255, 90, 90))
            return
        end
        if targetPlayer == LocalPlayer then
            notify("Carjack", "Tu ne peux pas voler ton propre véhicule !", Color3.fromRGB(255, 165, 0))
            return
        end

        local tChar = targetPlayer.Character
        if not tChar then
            notify("Carjack", targetPlayer.DisplayName .. " n'a pas de personnage !", Color3.fromRGB(255, 165, 0))
            return
        end

        local tHum = tChar:FindFirstChildOfClass("Humanoid")
        local tRoot = tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso") or tChar:FindFirstChild("UpperTorso")
        if not tHum or not tRoot then
            notify("Carjack", "Personnage de " .. targetPlayer.DisplayName .. " incomplet !", Color3.fromRGB(255, 165, 0))
            return
        end

        -- Rechercher le siège conducteur ou siège occupé par la cible (VehicleSeat ou Seat)
        local tSeat = tHum.SeatPart
        if not tSeat then
            for _, child in ipairs(tChar:GetDescendants()) do
                if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Snap") then
                    local part0 = child.Part0
                    local part1 = child.Part1
                    if part0 and (part0:IsA("VehicleSeat") or part0:IsA("Seat")) then
                        tSeat = part0
                        break
                    elseif part1 and (part1:IsA("VehicleSeat") or part1:IsA("Seat")) then
                        tSeat = part1
                        break
                    end
                end
            end
        end

        if not tSeat then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                    if obj.Occupant == tHum then
                        tSeat = obj
                        break
                    elseif (obj.Position - tRoot.Position).Magnitude < 6 then
                        tSeat = obj
                        break
                    end
                end
            end
        end

        if not tSeat then
            notify("Carjack", targetPlayer.DisplayName .. " n'est pas dans un véhicule ou bateau !", Color3.fromRGB(255, 165, 0))
            return
        end

        local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHum or not myHrp then
            notify("Carjack", "Ton personnage est incomplet !", Color3.fromRGB(255, 90, 90))
            return
        end

        notify("Carjack", "Éjection de " .. targetPlayer.DisplayName .. " et prise des commandes...", Color3.fromRGB(175, 110, 255))

        -- 1. Détruire toutes les soudures (SeatWeld) reliant la cible au siège
        for _, child in ipairs(tSeat:GetChildren()) do
            if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Snap") or child.Name == "SeatWeld" then
                pcall(function() child:Destroy() end)
            end
        end
        for _, child in ipairs(tChar:GetDescendants()) do
            if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Snap") then
                if child.Name == "SeatWeld" or child.Part0 == tSeat or child.Part1 == tSeat then
                    pcall(function() child:Destroy() end)
                end
            end
        end

        -- 2. Éjecter de force la cible du siège (désactivation Sit + impulsion pour le faire tomber)
        pcall(function()
            tHum.Sit = false
            tHum.PlatformStand = true
            tRoot.CFrame = tSeat.CFrame * CFrame.new(0, 7, -6)
            tRoot.AssemblyLinearVelocity = (tSeat.CFrame.LookVector * -35) + Vector3.new(0, 30, 0)
        end)
        task.delay(0.6, function()
            pcall(function() tHum.PlatformStand = false end)
        end)

        -- 3. Désasseoir le joueur local s'il était assis
        if myHum.Sit then
            myHum.Sit = false
            task.wait(0.04)
        end

        -- 4. TP instantané et s'asseoir directement à la place du conducteur
        myHrp.CFrame = tSeat.CFrame * CFrame.new(0, 1.2, 0)
        task.wait(0.02)
        pcall(function() tSeat:Sit(myHum) end)
        task.wait(0.05)

        if myHum.SeatPart ~= tSeat then
            if _G.sitInSeat then
                _G.sitInSeat(myHum, myHrp, tSeat)
            else
                pcall(function() tSeat:Sit(myHum) end)
            end
        end

        -- 5. Prendre le contrôle physique et démarrer le véhicule / bateau
        pcall(function()
            if tSeat:IsA("VehicleSeat") then
                tSeat.Throttle = 1
            end
            local vehModel = tSeat:FindFirstAncestorWhichIsA("Model") or tSeat.Parent
            local primary = vehModel and (vehModel.PrimaryPart or vehModel:FindFirstChild("HumanoidRootPart") or tSeat) or tSeat
            if primary and primary:IsA("BasePart") then
                primary.AssemblyLinearVelocity = tSeat.CFrame.LookVector * 55 + Vector3.new(0, 2, 0)
            end
        end)

        notify("Carjack", "Véhicule / Bateau volé à " .. targetPlayer.DisplayName .. " !", Color3.fromRGB(80, 200, 120))
    end)

    if not success then
        warn("[Nebula] Erreur Carjack: " .. tostring(err))
        notify("Carjack", "Erreur lors du carjack !", Color3.fromRGB(255, 90, 90))
    end
end
local carjackPlayer = _G.carjackPlayer


-- Configuration de JoueurContent en 2 colonnes epurees, ultra fluides et modernes
JoueurContent.ScrollBarThickness = 0
JoueurContent.AutomaticCanvasSize = Enum.AutomaticSize.None
JoueurContent.CanvasSize = UDim2.new(0, 0, 0, 0)

local existingLayout = JoueurContent:FindFirstChildOfClass("UIListLayout")
if existingLayout then existingLayout:Destroy() end
local existingPad = JoueurContent:FindFirstChildOfClass("UIPadding")
if existingPad then existingPad:Destroy() end

local PlayerTabRoot = Instance.new("Frame")
PlayerTabRoot.Name = "PlayerTabRoot"
PlayerTabRoot.Size = UDim2.new(1, 0, 1, 0)
PlayerTabRoot.BackgroundTransparency = 1
PlayerTabRoot.BorderSizePixel = 0
PlayerTabRoot.Parent = JoueurContent

local rootPad = Instance.new("UIPadding")
rootPad.PaddingTop = UDim.new(0, 8)
rootPad.PaddingBottom = UDim.new(0, 8)
rootPad.PaddingLeft = UDim.new(0, 12)
rootPad.PaddingRight = UDim.new(0, 12)
rootPad.Parent = PlayerTabRoot

-- Colonne Gauche (Player List)
local LeftCol = Instance.new("Frame")
LeftCol.Name = "LeftCol"
LeftCol.Size = UDim2.new(0.48, -10, 1, 0)
LeftCol.Position = UDim2.new(0, 0, 0, 0)
LeftCol.BackgroundTransparency = 1
LeftCol.BorderSizePixel = 0
LeftCol.Parent = PlayerTabRoot

local LeftTitle = Instance.new("TextLabel")
LeftTitle.Name = "LeftTitle"
LeftTitle.Size = UDim2.new(1, -8, 0, 26)
LeftTitle.Position = UDim2.new(0, 4, 0, 2)
LeftTitle.BackgroundTransparency = 1
LeftTitle.Text = "Player List"
LeftTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LeftTitle.Font = Enum.Font.GothamBold
LeftTitle.TextSize = 15
LeftTitle.TextXAlignment = Enum.TextXAlignment.Left
LeftTitle.Parent = LeftCol

local FilterContainer = Instance.new("Frame")
FilterContainer.Name = "FilterContainer"
FilterContainer.Size = UDim2.new(1, -8, 0, 30)
FilterContainer.Position = UDim2.new(0, 4, 0, 32)
FilterContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
FilterContainer.BorderSizePixel = 0
FilterContainer.Parent = LeftCol
makeCorner(FilterContainer, 6)
makeStroke(FilterContainer, Color3.fromRGB(32, 32, 46), 1)

local FilterBox = Instance.new("TextBox")
FilterBox.Name = "FilterBox"
FilterBox.Size = UDim2.new(1, -16, 1, 0)
FilterBox.Position = UDim2.new(0, 8, 0, 0)
FilterBox.BackgroundTransparency = 1
FilterBox.PlaceholderText = "Player filter"
FilterBox.PlaceholderColor3 = Color3.fromRGB(105, 105, 125)
FilterBox.Text = ""
FilterBox.TextColor3 = Color3.fromRGB(225, 225, 235)
FilterBox.Font = Enum.Font.GothamMedium
FilterBox.TextSize = 11
FilterBox.TextXAlignment = Enum.TextXAlignment.Left
FilterBox.ClearTextOnFocus = false
FilterBox.Parent = FilterContainer

local PlayerListScroll = Instance.new("ScrollingFrame")
PlayerListScroll.Name = "PlayerListScroll"
PlayerListScroll.Size = UDim2.new(1, 0, 1, -70)
PlayerListScroll.Position = UDim2.new(0, 0, 0, 68)
PlayerListScroll.BackgroundTransparency = 1
PlayerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerListScroll.ScrollBarThickness = 3
PlayerListScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 60, 95)
PlayerListScroll.BorderSizePixel = 0
PlayerListScroll.ClipsDescendants = true
PlayerListScroll.Parent = LeftCol

local PlayerListPad = Instance.new("UIPadding")
PlayerListPad.PaddingLeft = UDim.new(0, 4)
PlayerListPad.PaddingRight = UDim.new(0, 8)
PlayerListPad.PaddingTop = UDim.new(0, 4)
PlayerListPad.PaddingBottom = UDim.new(0, 8)
PlayerListPad.Parent = PlayerListScroll

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 8)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerListLayout.Parent = PlayerListScroll

PlayerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PlayerListScroll.CanvasSize = UDim2.new(0, 0, 0, PlayerListLayout.AbsoluteContentSize.Y + 16)
end)

-- Ligne de separation verticale centrale
local CenterDivider = Instance.new("Frame")
CenterDivider.Name = "CenterDivider"
CenterDivider.Size = UDim2.new(0, 1, 1, -8)
CenterDivider.Position = UDim2.new(0.48, 0, 0, 4)
CenterDivider.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
CenterDivider.BorderSizePixel = 0
CenterDivider.Parent = PlayerTabRoot

-- Colonne Droite (Settings)
local RightCol = Instance.new("Frame")
RightCol.Name = "RightCol"
RightCol.Size = UDim2.new(0.52, -10, 1, 0)
RightCol.Position = UDim2.new(0.48, 10, 0, 0)
RightCol.BackgroundTransparency = 1
RightCol.BorderSizePixel = 0
RightCol.Parent = PlayerTabRoot

local RightTitle = Instance.new("TextLabel")
RightTitle.Name = "RightTitle"
RightTitle.Size = UDim2.new(1, -8, 0, 26)
RightTitle.Position = UDim2.new(0, 4, 0, 2)
RightTitle.BackgroundTransparency = 1
RightTitle.Text = "Settings"
RightTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
RightTitle.Font = Enum.Font.GothamBold
RightTitle.TextSize = 15
RightTitle.TextXAlignment = Enum.TextXAlignment.Left
RightTitle.Parent = RightCol

local TargetIndicator = Instance.new("TextLabel")
TargetIndicator.Name = "TargetIndicator"
TargetIndicator.Size = UDim2.new(1, -8, 0, 18)
TargetIndicator.Position = UDim2.new(0, 4, 0, 30)
TargetIndicator.BackgroundTransparency = 1
TargetIndicator.Text = "Cible : Aucun joueur sélectionné"
TargetIndicator.TextColor3 = Color3.fromRGB(155, 140, 225)
TargetIndicator.Font = Enum.Font.GothamMedium
TargetIndicator.TextSize = 11
TargetIndicator.TextXAlignment = Enum.TextXAlignment.Left
TargetIndicator.TextTruncate = Enum.TextTruncate.AtEnd
TargetIndicator.Parent = RightCol

local SettingsContainer = Instance.new("Frame")
SettingsContainer.Name = "SettingsContainer"
SettingsContainer.Size = UDim2.new(1, 0, 1, -54)
SettingsContainer.Position = UDim2.new(0, 0, 0, 52)
SettingsContainer.BackgroundTransparency = 1
SettingsContainer.BorderSizePixel = 0
SettingsContainer.Parent = RightCol

local SettingsPad = Instance.new("UIPadding")
SettingsPad.PaddingLeft = UDim.new(0, 4)
SettingsPad.PaddingRight = UDim.new(0, 8)
SettingsPad.PaddingTop = UDim.new(0, 4)
SettingsPad.PaddingBottom = UDim.new(0, 8)
SettingsPad.Parent = SettingsContainer

local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.Padding = UDim.new(0, 8)
SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
SettingsLayout.Parent = SettingsContainer

local selectedPlayer = V.SelectedJoueurPlayer or LocalPlayer
local actionRefreshers = {}
local playerRowsByPlayer = {}

local function updateTargetIndicator()
    if selectedPlayer and selectedPlayer.Parent then
        if selectedPlayer == LocalPlayer then
            TargetIndicator.Text = "Cible : " .. selectedPlayer.DisplayName .. " (@" .. selectedPlayer.Name .. ") [Moi]"
            TargetIndicator.TextColor3 = Color3.fromRGB(120, 200, 255)
        else
            TargetIndicator.Text = "Cible : " .. selectedPlayer.DisplayName .. " (@" .. selectedPlayer.Name .. ")"
            TargetIndicator.TextColor3 = Color3.fromRGB(175, 145, 255)
        end
    else
        TargetIndicator.Text = "Cible : Aucun joueur sélectionné"
        TargetIndicator.TextColor3 = Color3.fromRGB(130, 130, 150)
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
                rowData.btn.BackgroundColor3 = Color3.fromRGB(46, 26, 76)
                rowData.stroke.Color = Color3.fromRGB(140, 75, 255)
                rowData.lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                rowData.btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
                rowData.stroke.Color = Color3.fromRGB(32, 32, 46)
                rowData.lbl.TextColor3 = (p == LocalPlayer) and Color3.fromRGB(140, 200, 255) or Color3.fromRGB(215, 215, 230)
            end
        end
    end
end

local function createPlayerRow(p)
    if not p or playerRowsByPlayer[p] then return end

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = (p == selectedPlayer) and Color3.fromRGB(46, 26, 76) or Color3.fromRGB(18, 18, 26)
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.ClipsDescendants = true
    row.LayoutOrder = (p == LocalPlayer) and 0 or 1
    row.Parent = PlayerListScroll
    makeCorner(row, 6)
    local rowStroke = makeStroke(row, (p == selectedPlayer) and Color3.fromRGB(140, 75, 255) or Color3.fromRGB(32, 32, 46), 1)

    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(1, -24, 1, 0)
    rowLabel.Position = UDim2.new(0, 12, 0, 0)
    rowLabel.BackgroundTransparency = 1
    local tag = (p == LocalPlayer) and " (Moi)" or ""
    rowLabel.Text = p.DisplayName .. " (@" .. p.Name .. ")" .. tag
    rowLabel.TextColor3 = (p == selectedPlayer) and Color3.fromRGB(255, 255, 255) or ((p == LocalPlayer) and Color3.fromRGB(140, 200, 255) or Color3.fromRGB(215, 215, 230))
    rowLabel.Font = Enum.Font.GothamBold
    rowLabel.TextSize = 11
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.TextTruncate = Enum.TextTruncate.AtEnd
    rowLabel.Parent = row

    local searchKey = string.lower(p.Name .. " " .. p.DisplayName .. " " .. tostring(p.UserId))

    row.MouseButton1Click:Connect(function()
        playClick()
        selectedPlayer = p
        V.SelectedJoueurPlayer = p
        _G.SelectedJoueurPlayer = p
        updateTargetIndicator()
        updateSelectionHighlight()
        refreshAllActions()
    end)

    playerRowsByPlayer[p] = {btn = row, stroke = rowStroke, lbl = rowLabel, searchKey = searchKey}
end

local function removePlayerRow(p)
    local data = playerRowsByPlayer[p]
    if data then
        if data.btn and data.btn.Parent then
            data.btn:Destroy()
        end
        playerRowsByPlayer[p] = nil
    end
    if selectedPlayer == p then
        selectedPlayer = LocalPlayer
        V.SelectedJoueurPlayer = LocalPlayer
        _G.SelectedJoueurPlayer = LocalPlayer
        updateTargetIndicator()
        updateSelectionHighlight()
        refreshAllActions()
    end
end

local function applyFilter()
    local q = string.lower(FilterBox.Text or ""):match("^%s*(.-)%s*$")
    for _, data in pairs(playerRowsByPlayer) do
        if data.btn and data.btn.Parent then
            if q == "" or string.find(data.searchKey, q, 1, true) then
                data.btn.Visible = true
            else
                data.btn.Visible = false
            end
        end
    end
end

-- Remplissage initial fluide avec TOUS les joueurs du serveur
for _, p in ipairs(Players:GetPlayers()) do
    createPlayerRow(p)
end
if not selectedPlayer or not selectedPlayer.Parent then
    selectedPlayer = LocalPlayer
    V.SelectedJoueurPlayer = LocalPlayer
    _G.SelectedJoueurPlayer = LocalPlayer
end
updateTargetIndicator()
updateSelectionHighlight()

FilterBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)

Players.PlayerAdded:Connect(function(p)
    createPlayerRow(p)
    applyFilter()
    updateSelectionHighlight()
end)

Players.PlayerRemoving:Connect(function(p)
    removePlayerRow(p)
end)

-- Creation des 5 boutons d'action (attach, spectate, teleport, WarpCar, fling)
-- Pas de coloration au survol de la souris, coloration uniquement a l'appui / actif
local function createActionButton(btnTitle, callback, checkActive)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    btn.BorderSizePixel = 0
    btn.Text = btnTitle
    btn.TextColor3 = Color3.fromRGB(220, 220, 235)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.RichText = true
    btn.AutoButtonColor = false
    btn.Parent = SettingsContainer
    makeCorner(btn, 6)
    local stroke = makeStroke(btn, Color3.fromRGB(32, 32, 46), 1)

    local function refreshState()
        local active = false
        if checkActive then
            pcall(function()
                active = checkActive(btn)
            end)
        end
        if active then
            btn.BackgroundColor3 = Color3.fromRGB(55, 20, 32)
            btn.TextColor3 = Color3.fromRGB(255, 95, 110)
            stroke.Color = Color3.fromRGB(210, 48, 62)
        else
            btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
            btn.TextColor3 = Color3.fromRGB(220, 220, 235)
            stroke.Color = Color3.fromRGB(32, 32, 46)
        end
    end

    table.insert(actionRefreshers, refreshState)

    btn.MouseButton1Down:Connect(function()
        local active = false
        if checkActive then
            pcall(function() active = checkActive(btn) end)
        end
        if not active then
            btn.BackgroundColor3 = Color3.fromRGB(38, 24, 60)
            stroke.Color = Color3.fromRGB(140, 75, 255)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)

    btn.MouseButton1Up:Connect(function()
        task.wait(0.08)
        refreshState()
    end)

    btn.MouseButton1Click:Connect(function()
        playClick()
        if not selectedPlayer or not selectedPlayer.Parent then
            notify("Player", "Veuillez sélectionner un joueur à gauche !", Color3.fromRGB(255, 165, 0))
            return
        end
        callback(btn)
        refreshState()
    end)

    refreshState()
    return btn
end

-- 1. Teleport
createActionButton("Teleport", function(btn)
    if selectedPlayer == LocalPlayer then
        notify("Teleport", "Vous êtes déjà sur vous-même !", Color3.fromRGB(255, 165, 0))
        return
    end
    if _G.teleportToPlayer then
        _G.teleportToPlayer(selectedPlayer)
    elseif teleportToPlayer then
        teleportToPlayer(selectedPlayer)
    end
end)

-- 2. Spectate
createActionButton("Spectate", function(btn)
    if selectedPlayer == LocalPlayer then
        stopSpectate()
        return
    end
    if V.Spectate and V.SelPlayer == selectedPlayer then
        stopSpectate()
    else
        if V.Spectate then stopSpectate() end
        startSpectate(selectedPlayer)
    end
end, function(btn)
    local active = (V.Spectate and V.SelPlayer == selectedPlayer)
    btn.Text = active and "Stop Spectate" or "Spectate"
    return active
end)

-- 3. Attach
createActionButton("Attach", function(btn)
    if selectedPlayer == LocalPlayer then
        notify("Attach", "Impossible de s'attacher à soi-même !", Color3.fromRGB(255, 165, 0))
        return
    end
    if V.Attached == selectedPlayer then
        if _G.stopAttach then _G.stopAttach() elseif stopAttach then stopAttach() end
    else
        if _G.startAttach then _G.startAttach(selectedPlayer) elseif startAttach then startAttach(selectedPlayer) end
    end
end, function(btn)
    local active = (V.Attached == selectedPlayer)
    btn.Text = active and "Detach" or "Attach"
    return active
end)

-- 4. Attach Player (BloxFruit)
createActionButton('attach player (<font color="rgb(175,110,255)">bloxfruit</font>)', function(btn)
    if selectedPlayer == LocalPlayer then
        notify("Attach", "Impossible de s'attacher à soi-même !", Color3.fromRGB(255, 165, 0))
        return
    end
    if V.AttachedBloxFruit == selectedPlayer then
        if _G.stopAttachBloxFruit then _G.stopAttachBloxFruit() elseif stopAttachBloxFruit then stopAttachBloxFruit() end
    else
        if _G.startAttachBloxFruit then _G.startAttachBloxFruit(selectedPlayer) elseif startAttachBloxFruit then startAttachBloxFruit(selectedPlayer) end
    end
end, function(btn)
    local active = (V.AttachedBloxFruit == selectedPlayer)
    btn.Text = active and 'Stop attach (<font color="rgb(175,110,255)">bloxfruit</font>)' or 'attach player (<font color="rgb(175,110,255)">bloxfruit</font>)'
    return active
end)

-- 4. WarpCar
createActionButton("WarpCar", function(btn)
    if selectedPlayer == LocalPlayer then
        notify("Player", "Vous êtes déjà dans votre session !", Color3.fromRGB(255, 165, 0))
        return
    end
    if _G.warpToPlayerCar then
        _G.warpToPlayerCar(selectedPlayer)
    elseif warpToPlayerCar then
        warpToPlayerCar(selectedPlayer)
    end
end)

-- 5. Fling
createActionButton("Fling", function(btn)
    if selectedPlayer == LocalPlayer then
        notify("Fling", "Impossible de fling son propre personnage !", Color3.fromRGB(255, 165, 0))
        return
    end
    if V.Flinging and V.FlingTarget == selectedPlayer then
        stopFling()
    else
        if V.Flinging then stopFling() end
        startFling(selectedPlayer)
    end
end, function(btn)
    local active = (V.Flinging and V.FlingTarget == selectedPlayer)
    btn.Text = active and "Stop Fling" or "Fling"
    return active
end)

_G.refreshPlayerList = function()
    for _, p in ipairs(Players:GetPlayers()) do
        createPlayerRow(p)
    end
    applyFilter()
    updateSelectionHighlight()
end


createLabel("SERVER ACTIONS & VISUALS", ServerContent)

skyPresets = {
    ["Purple Galaxy"] = {
        Bk ="rbxassetid://159454299", Dn ="rbxassetid://159454296", Ft ="rbxassetid://159454293",
        Lf ="rbxassetid://159454299", Rt ="rbxassetid://159454300", Up ="rbxassetid://159454288"
    },
    ["Vaporwave"] = {
        Bk ="rbxassetid://1417494402", Dn ="rbxassetid://1417494146", Ft ="rbxassetid://1417494253",
        Lf ="rbxassetid://1417494402", Rt ="rbxassetid://1417494499", Up ="rbxassetid://1417494643"
    }
}
skyList = {"Default","Purple Galaxy","Vaporwave"}
currentSkyIdx = 1
originalSkyObj = nil

function applyCustomSkybox(skyName)
    local Lighting = game:GetService("Lighting")
    local currentSky = Lighting:FindFirstChildOfClass("Sky")
    if not originalSkyObj and currentSky then originalSkyObj = currentSky:Clone() end
    
    if skyName =="Default"then
        if currentSky then currentSky:Destroy() end
        if originalSkyObj then originalSkyObj:Clone().Parent = Lighting end
        notify("Server","Skybox par défaut restaurée", Color3.fromRGB(80, 200, 120))
        return
    end

    if currentSky then currentSky:Destroy() end
    local newSky = Instance.new("Sky")
    newSky.Name ="NebulaCustomSky"
    local preset = skyPresets[skyName]
    if preset then
        newSky.SkyboxBk = preset.Bk
        newSky.SkyboxDn = preset.Dn
        newSky.SkyboxFt = preset.Ft
        newSky.SkyboxLf = preset.Lf
        newSky.SkyboxRt = preset.Rt
        newSky.SkyboxUp = preset.Up
        newSky.Parent = Lighting
        notify("Server","Skybox appliquée:".. skyName, Color3.fromRGB(80, 200, 120))
    end
end

skyBtnFrame, skyBtnObj, skyValue = createValueButton(ServerContent, "Custom Skybox", "Default", function()
    currentSkyIdx = (currentSkyIdx % #skyList) + 1
    local chosenSky = skyList[currentSkyIdx]
    applyCustomSkybox(chosenSky)
    return chosenSky
end)

createButton("Remove Map Particles & Smokes (FPS Boost)", function()
    local count = 0
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
                obj:Destroy()
                count = count + 1
            end
        end
    end)
    notify("Server", count .."particules et fumées supprimées !", Color3.fromRGB(80, 200, 120))
end, ServerContent)

createToggle("Player Join/Leave Toast Notifs", false, function(enabled)
    V.PlayerJoinLeaveNotifs = enabled
    notify("Server","Notifs Join/Leave".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, ServerContent,"PlayerJoinLeaveNotifs")
createButton("Rejoin Server", function()
    notify("Server","Rejoining server...", Color3.fromRGB(180, 180, 195))
    task.spawn(function()
        pcall(function()
            local target = { JobId = game.JobId }
            local ok, res = pcall(function()
                return game:HttpGet("https://games.roblox.com/v1/games/".. game.PlaceId .."/servers/Public?limit=100")
            end)
            if ok and res then
                local servers = HttpService:JSONDecode(res)
                if servers and servers.data then
                    for _, v in ipairs(servers.data) do
                        if v.playing < v.maxPlayers and v.id ~= game.JobId then
                            target = { JobId = v.id }
                            break
                        end
                    end
                end
            end
            task.wait(0.3)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target.JobId)
        end)
    end)
end, ServerContent)

isRejoining = false
function performRealAutoRejoin()
    if isRejoining then return end
    isRejoining = true

    task.spawn(function()
        notify("Auto Rejoin", "Déconnexion détectée ! Reconnexion automatique...", Color3.fromRGB(255, 165, 0))
        while true do
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
            task.wait(2.5)

            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
            task.wait(3.5)
        end
    end)
end

pcall(function()
    local GuiService = game:GetService("GuiService")
    GuiService.ErrorMessageChanged:Connect(function()
        if V.AutoRejoin then
            performRealAutoRejoin()
        end
    end)
end)

pcall(function()
    local coreGui = game:GetService("CoreGui")
    local promptGui = coreGui:WaitForChild("RobloxPromptGui", 3)
    if promptGui then
        local promptOverlay = promptGui:WaitForChild("promptOverlay", 3)
        if promptOverlay then
            promptOverlay.ChildAdded:Connect(function(child)
                if V.AutoRejoin and (child.Name == "ErrorPrompt" or child:FindFirstChild("ErrorMessageLabel")) then
                    performRealAutoRejoin()
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1.5)
        if V.AutoRejoin and not isRejoining then
            pcall(function()
                local coreGui = game:GetService("CoreGui")
                local promptGui = coreGui:FindFirstChild("RobloxPromptGui")
                if promptGui then
                    local overlay = promptGui:FindFirstChild("promptOverlay")
                    if overlay and overlay:FindFirstChild("ErrorPrompt") then
                        performRealAutoRejoin()
                    end
                end
            end)
        end
    end
end)

createToggle("Auto Rejoin (Vrai Reconnect Kick/Crash)", true, function(enabled)
    V.AutoRejoin = enabled
    notify("Server", "Auto Rejoin " .. (enabled and "ACTIVÉ (Infaillible)" or "DÉSACTIVÉ"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, ServerContent, "AutoRejoin")

createButton("Solo Server (Least Populated)", function()
    notify("Server","Recherche du serveur le plus vide...", Color3.fromRGB(180, 180, 195))
    task.spawn(function()
        pcall(function()
            local cursor =""
            local bestServer = nil
            local lowestPlayers = math.huge
            
            for page = 1, 3 do
                local url ="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
                if cursor ~=""then
                    url = url .."&cursor=".. cursor
                end
                
                local success, response = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet(url))
                end)
                
                if success and response and response.data then
                    for _, v in ipairs(response.data) do
                        if v.id ~= game.JobId and v.playing < v.maxPlayers then
                            if v.playing < lowestPlayers then
                                lowestPlayers = v.playing
                                bestServer = v
                            end
                            if lowestPlayers == 0 then
                                break
                            end
                        end
                    end
                    
                    if lowestPlayers == 0 and bestServer then
                        break
                    end
                    
                    if response.nextPageCursor then
                        cursor = response.nextPageCursor
                    else
                        break
                    end
                else
                    break
                end
            end
            
            if bestServer then
                notify("Server","Serveur trouvé avec".. lowestPlayers .."joueur(s). Téléportation...", Color3.fromRGB(80, 200, 120))
                TeleportService:TeleportToPlaceInstance(game.PlaceId, bestServer.id, LocalPlayer)
            else
                notify("Server","Aucun serveur disponible trouvé.", Color3.fromRGB(255, 90, 90))
            end
        end)
    end)
end, ServerContent)

createButton("Server Hop (Random)", function()
    notify("Server","Hopping server...", Color3.fromRGB(180, 180, 195))
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, v in ipairs(servers.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer)
                return
            end
        end
        notify("Server","No other server found.", Color3.fromRGB(255, 165, 0))
    end)
end, ServerContent)



createLabel("TIME & VISUALS", ServerContent)
createSlider("Time (0-24h)", 0, 24, 14, function(val)
    Lighting.ClockTime = val
end, ServerContent)

createToggle("Fullbright", false, function(enabled) toggleFullbright(enabled) end, ServerContent,"Fullbright")
createToggle("FPS Booster (Max Boost)", false, function(enabled) toggleFPSBooster(enabled) end, ServerContent,"FPSBoost")

createLabel("CAMERA", ServerContent)
createToggle("Force First Person", false, function(enabled)
    if enabled then
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    else
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
    end
    notify("Server","First Person".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, ServerContent,"Force1st")

createToggle("Force Third Person", false, function(enabled)
    V.Force3rd = enabled
    if V.Force3rdConn then V.Force3rdConn:Disconnect() V.Force3rdConn = nil end
    if enabled then
        pcall(function()
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            if LocalPlayer.CameraMaxZoomDistance < 100 then
                LocalPlayer.CameraMaxZoomDistance = 1000
            end
            LocalPlayer.CameraMinZoomDistance = 12
        end)
        V.Force3rdConn = RunService.RenderStepped:Connect(function()
            if not V.Force3rd then
                if V.Force3rdConn then V.Force3rdConn:Disconnect() V.Force3rdConn = nil end
                return
            end
            pcall(function()
                if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
                    LocalPlayer.CameraMode = Enum.CameraMode.Classic
                end
                if LocalPlayer.CameraMinZoomDistance < 10 then
                    LocalPlayer.CameraMinZoomDistance = 12
                end
                if LocalPlayer.CameraMaxZoomDistance < 50 then
                    LocalPlayer.CameraMaxZoomDistance = 1000
                end
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and Camera.CameraSubject ~= hum then
                        Camera.CameraSubject = hum
                    end
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier = 0
                        end
                    end
                end
            end)
        end)
        addConnection(V.Force3rdConn)
    else
        pcall(function()
            LocalPlayer.CameraMinZoomDistance = 0.5
            LocalPlayer.CameraMaxZoomDistance = 128
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
        end)
    end
    notify("Server","Third Person ".. (enabled and "ON (Vue 3ème Personne Parfaite)" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, ServerContent,"Force3rd")

createToggle("Unlock Camera Zoom", false, function(enabled)
    if enabled then
        LocalPlayer.CameraMaxZoomDistance = 1000
        LocalPlayer.CameraMinZoomDistance = 0.5
    else
        LocalPlayer.CameraMaxZoomDistance = 128
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
    notify("Server","Zoom Unlock".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, ServerContent,"UnlockZoom")

function tpToAimVehicleSeat(forced)
    if not forced and not V.VehicleSeatTP then return end
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        local targetVeh = nil
        local targetSeat = nil

        local mouse = LocalPlayer:GetMouse()
        local hit = mouse and mouse.Target
        if hit then
            if hit:IsA("VehicleSeat") or hit:IsA("Seat") then
                targetSeat = hit
                targetVeh = hit:FindFirstAncestorWhichIsA("Model") or hit.Parent
            else
                local curr = hit
                while curr and curr ~= workspace do
                    if curr:IsA("Model") then
                        for _, child in pairs(curr:GetDescendants()) do
                            if child:IsA("VehicleSeat") or child:IsA("Seat") then
                                targetSeat = child
                                targetVeh = curr
                                break
                            end
                        end
                    end
                    if targetSeat then break end
                    curr = curr.Parent
                end
            end
        end

        if not targetSeat then
            local closestDist = 70
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        targetSeat = obj
                        targetVeh = obj:FindFirstAncestorWhichIsA("Model") or obj.Parent
                    end
                end
            end
        end

        if not targetSeat then
            notify("Vehicle", "Vise un véhicule ou approche-toi d'un siège !", Color3.fromRGB(255, 165, 0))
            return
        end

        if _G.sitInSeat then
            _G.sitInSeat(hum, hrp, targetSeat)
        else
            hum.Sit = false
            hum.PlatformStand = false
            task.wait(0.02)
            hrp.CFrame = targetSeat.CFrame
            task.wait(0.04)
            pcall(function() targetSeat:Sit(hum) end)
        end
        notify("Vehicle", "TP Réussi dans le siège !", Color3.fromRGB(80, 200, 120))
    end)
end
_G.tpToAimVehicleSeat = tpToAimVehicleSeat

initStep = "cablage Vehicle/Fun"
createLabel("VEHICLE MODIFICATIONS", VehicleContent)

createButton("TP Véhicule Auto Seat (Touche J)", function()
    if _G.tpToAimVehicleSeat then
        _G.tpToAimVehicleSeat(true)
    end
end, VehicleContent)

createSlider("Vehicle Speed Multiplier", 1, 10, 1, function(val)
    V.VehicleSpeed = val
end, VehicleContent,"VehicleSpeed")

createToggle("Vehicle Fly", false, function(enabled)
    V.VehicleFly = enabled
    notify("Vehicle","Vehicle Fly".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, VehicleContent,"VehicleFly")
createSlider("Vehicle Fly Speed", 50, 500, 150, function(val) V.VehicleFlySpeed = val end, VehicleContent,"VehicleFlySpeed")

createSlider("Vehicle Boost Speed", 50, 1000, 250, function(val) V.VehicleBoostSpeed = val end, VehicleContent,"VehicleBoostSpeed")

vehicleBoostModesList = {"Camera", "Vehicle Front"}
currentVehicleBoostModeIdx = 1
vehBoostModeFrame, vehBoostModeBtnObj, vehBoostModeValue = createValueButton(VehicleContent, "Vehicle Boost Mode", V.VehicleBoostMode or "Camera", function()
    local foundIdx = table.find(vehicleBoostModesList, V.VehicleBoostMode)
    if foundIdx then currentVehicleBoostModeIdx = foundIdx end
    currentVehicleBoostModeIdx = (currentVehicleBoostModeIdx % #vehicleBoostModesList) + 1
    V.VehicleBoostMode = vehicleBoostModesList[currentVehicleBoostModeIdx]
    notify("Vehicle", "Mode de Boost : " .. V.VehicleBoostMode, Color3.fromRGB(80, 200, 120))
    return V.VehicleBoostMode
end, "VehicleBoostMode")

createToggle("Vehicle Noclip", false, function(enabled)
    V.VehicleNoclip = enabled
    notify("Vehicle","Vehicle Noclip".. (enabled and"ON"or"OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, VehicleContent,"VehicleNoclip")

function jumpCar(force)
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if not seat then
            notify("Vehicle", "Tu dois être dans un véhicule !", Color3.fromRGB(255, 165, 0))
            return
        end
        local veh = seat.Parent:IsA("Model") and seat.Parent or seat
        local primary = (veh:IsA("Model") and veh.PrimaryPart) or seat
        local jumpPower = force or V.VehicleJumpPower or 80

        local pos = primary.Position
        local rx, ry, rz = primary.CFrame:ToOrientation()
        local uprightCF = CFrame.new(pos) * CFrame.Angles(0, ry, 0)

        if veh:IsA("Model") and veh.PrimaryPart then
            veh:SetPrimaryPartCFrame(uprightCF)
        else
            primary.CFrame = uprightCF
        end

        for _, part in pairs(veh:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyAngularVelocity = Vector3.zero
                local curVel = part.AssemblyLinearVelocity
                part.AssemblyLinearVelocity = Vector3.new(curVel.X, jumpPower, curVel.Z)
            end
        end
        if seat:IsA("BasePart") then
            seat.AssemblyAngularVelocity = Vector3.zero
            local curVel = seat.AssemblyLinearVelocity
            seat.AssemblyLinearVelocity = Vector3.new(curVel.X, jumpPower, curVel.Z)
        end

        local existingStab = primary:FindFirstChild("NebulaJumpCarStabilizer")
        if existingStab then existingStab:Destroy() end

        local stabilizer = Instance.new("BodyGyro")
        stabilizer.Name = "NebulaJumpCarStabilizer"
        stabilizer.MaxTorque = Vector3.new(9e9, 0, 9e9)
        stabilizer.P = 2e5
        stabilizer.D = 1000
        stabilizer.CFrame = CFrame.Angles(0, ry, 0)
        stabilizer.Parent = primary

        task.spawn(function()
            local startTime = os.clock()
            while primary and primary.Parent and stabilizer and stabilizer.Parent and (os.clock() - startTime) < 4 do
                task.wait(0.03)
                
                local _, curY = primary.CFrame:ToOrientation()
                stabilizer.CFrame = CFrame.Angles(0, curY, 0)
                
                for _, part in pairs(veh:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.AssemblyAngularVelocity = Vector3.new(0, part.AssemblyAngularVelocity.Y, 0)
                    end
                end

                if (os.clock() - startTime) > 0.35 then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = { veh, char }
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    local hit = workspace:Raycast(primary.Position, Vector3.new(0, -6, 0), rayParams)
                    
                    if hit or (math.abs(primary.AssemblyLinearVelocity.Y) < 1.5 and (os.clock() - startTime) > 0.6) then
                        task.wait(0.2)
                        break
                    end
                end
            end
            if stabilizer and stabilizer.Parent then
                stabilizer:Destroy()
            end
        end)

        notify("Vehicle", "Jump Car (Stabilisé Air & Sol) !", Color3.fromRGB(80, 200, 120))
    end)
end
_G.jumpCar = jumpCar

function flipVehicle()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if not seat then
            notify("Vehicle","Tu dois être dans un véhicule !", Color3.fromRGB(255, 165, 0))
            return
        end
        local veh = seat.Parent:IsA("Model") and seat.Parent or seat
        local primary = (veh:IsA("Model") and veh.PrimaryPart) or seat

        local pos = primary.Position
        local rx, ry, rz = primary.CFrame:ToOrientation()
        local uprightCF = CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, ry, 0)

        if veh:IsA("Model") and veh.PrimaryPart then
            veh:SetPrimaryPartCFrame(uprightCF)
        else
            primary.CFrame = uprightCF
        end

        for _, part in pairs(veh:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end

        notify("Vehicle","Véhicule remis droit sur ses roues !", Color3.fromRGB(80, 200, 120))
    end)
end
_G.flipVehicle = flipVehicle

createButton("Jump Car (Faire Sauter le Véhicule)", function()
    jumpCar()
end, VehicleContent)

createSlider("Puissance Saut Véhicule (Jump Power)", 20, 300, 80, function(val)
    V.VehicleJumpPower = val
end, VehicleContent, "VehicleJumpPower")

createToggle("Auto Jump Car (Touche Espace en Voiture)", false, function(enabled)
    V.VehicleAutoJump = enabled
    notify("Vehicle", "Auto Jump Car " .. (enabled and "ON (Espace pour sauter)" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, VehicleContent, "VehicleAutoJump")

createButton("Remettre le Véhicule Droit (Auto-Flip)", function()
    flipVehicle()
end, VehicleContent)

createButton("Explode / Propulser Véhicule (Touche L)", function()
    explodeVehicle()
end, VehicleContent)

function explodeVehicle()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local seat = hum and hum.SeatPart

        if not seat then return end

        local veh = seat:FindFirstAncestorWhichIsA("Model") or seat.Parent
        if not veh then return end

        if not seat:IsA("VehicleSeat") then
            local driverSeat = nil
            for _, obj in ipairs(veh:GetDescendants()) do
                if obj:IsA("VehicleSeat") then
                    if _G.isSeatFree and _G.isSeatFree(obj) then
                        driverSeat = obj
                        break
                    end
                end
            end

            if driverSeat then
                if _G.sitInSeat then
                    _G.sitInSeat(hum, hrp, driverSeat)
                else
                    pcall(function() driverSeat:Sit(hum) end)
                end
                task.wait(0.03)
                seat = hum and hum.SeatPart
            end
        end

        if not seat or not seat:IsA("VehicleSeat") then return end

        notify("Vehicle", "Explode Véhicule !", Color3.fromRGB(255, 90, 90))

        local randX = math.random(-30000, 30000)
        local randY = math.random(20000, 45000)
        local randZ = math.random(-30000, 30000)
        local launchVel = Vector3.new(randX, randY, randZ)
        local launchRot = Vector3.new(math.random(-8000, 8000), math.random(-8000, 8000), math.random(-8000, 8000))

        pcall(function() hum.PlatformStand = true end)

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e12, 1e12, 1e12)
        bv.Velocity = launchVel
        bv.Parent = hrp

        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(1e12, 1e12, 1e12)
        bav.AngularVelocity = launchRot
        bav.Parent = hrp

        local bvSeat = Instance.new("BodyVelocity")
        bvSeat.MaxForce = Vector3.new(1e12, 1e12, 1e12)
        bvSeat.Velocity = launchVel
        bvSeat.Parent = seat

        Debris:AddItem(bv, 0.6)
        Debris:AddItem(bav, 0.6)
        Debris:AddItem(bvSeat, 0.6)

        task.spawn(function()
            local startTime = os.clock()
            while os.clock() - startTime < 0.6 do
                pcall(function()
                    if hrp and hrp.Parent then
                        hrp.AssemblyLinearVelocity = launchVel
                        hrp.AssemblyAngularVelocity = launchRot
                    end
                    if seat and seat.Parent then
                        seat.AssemblyLinearVelocity = launchVel
                        seat.AssemblyAngularVelocity = launchRot
                    end
                    for _, p in ipairs(veh:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.AssemblyLinearVelocity = launchVel
                            p.AssemblyAngularVelocity = launchRot
                        end
                    end
                end)
                task.wait(0.01)
            end
            task.wait(0.2)
            pcall(function() hum.PlatformStand = false end)
        end)
    end)
end
_G.explodeVehicle = explodeVehicle

task.spawn(function()
    local lastSeat = nil
    while task.wait(0.1) do
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local seat = hum and hum.SeatPart
            if seat then
                if seat ~= lastSeat then
                    lastSeat = seat
                    if V.VehicleExplodeEnabled == true then
                        explodeVehicle()
                    end
                end
            else
                lastSeat = nil
            end
        end)
    end
end)

function spawnInstantRamp()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local refCF = seat and seat.CFrame or hrp.CFrame
        local rampPos = refCF * CFrame.new(0, -1, -12) * CFrame.Angles(math.rad(28), 0, 0)

        local ramp = Instance.new("Part")
        ramp.Name = "Nebula_InstantRamp"
        ramp.Size = Vector3.new(14, 1, 24)
        ramp.CFrame = rampPos
        ramp.Anchored = true
        ramp.CanCollide = true
        ramp.Material = Enum.Material.Neon
        ramp.Color = Color3.fromRGB(140, 80, 255)
        ramp.Parent = workspace

        local stroke = Instance.new("SelectionBox")
        stroke.Color3 = Color3.fromRGB(0, 230, 255)
        stroke.Adornee = ramp
        stroke.Parent = ramp

        Debris:AddItem(ramp, 8)
        notify("Vehicle", "Tremplin Instantané déployé devant vous ! (U)", Color3.fromRGB(80, 200, 120))
    end)
end
_G.spawnInstantRamp = spawnInstantRamp

createButton("Instant Ramp Spawner (Touche U)", function()
    spawnInstantRamp()
end, VehicleContent)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.U then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart then
            spawnInstantRamp()
        end
    end
end)

addConnection(LocalPlayer.CharacterAdded:Connect(function()
    pcall(function()
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name == "Nebula_InstantRamp" then
                obj:Destroy()
            end
        end
    end)
end))

function toggleCarCarry()
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local targetVeh = nil
        local targetPos = V.Freecam and Camera.CFrame.Position or hrp.Position
        
        local rayOrigin = Camera.CFrame.Position
        local rayDirection = Camera.CFrame.LookVector * (V.Freecam and 2500 or 200)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {char}
        params.IgnoreWater = true
        
        local result = workspace:Raycast(rayOrigin, rayDirection, params)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorWhichIsA("Model")
            if model then
                local seat = model:FindFirstChildOfClass("VehicleSeat") or model:FindFirstChildOfClass("Seat")
                if seat or model:FindFirstChild("Drive") or model:FindFirstChild("Engine") then
                    targetVeh = model
                end
            end
        end

        if not targetVeh then
            local closestDist = V.Freecam and 300 or 60
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= char then
                    local seat = obj:FindFirstChildOfClass("VehicleSeat") or obj:FindFirstChildOfClass("Seat")
                    if seat then
                        local primary = obj.PrimaryPart or seat
                        local dist = (primary.Position - targetPos).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            targetVeh = obj
                        end
                    end
                end
            end
        end

        if not targetVeh then
            notify("Vehicle", V.Freecam and "Vise un véhicule avec la Freecam !" or "Approche-toi d'un véhicule (moins de 60 studs) !", Color3.fromRGB(255, 165, 0))
            return
        end

        local lookVec = Camera.CFrame.LookVector
        local launchVel = (lookVec * 450) + Vector3.new(0, 65, 0)
        local launchRot = Vector3.new(math.random(-35, 35), math.random(-25, 25), math.random(-35, 35))

        pcall(function()
            for _, part in pairs(targetVeh:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                    part.CanCollide = true
                    part.LocalTransparencyModifier = 0
                    part.AssemblyLinearVelocity = launchVel
                    part.AssemblyAngularVelocity = launchRot
                end
            end
        end)

        notify("Vehicle", "🚀 VÉHICULE PROJETÉ À SUPER VITESSE !", Color3.fromRGB(80, 200, 120))
    end)
end
_G.toggleCarCarry = toggleCarCarry

createButton("Propulser Véhicule Visé (Touche P)", function()
    toggleCarCarry()
end, VehicleContent)

function vehicleBoost()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if not seat then
            notify("Vehicle","Tu dois être dans un véhicule !", Color3.fromRGB(255, 165, 0))
            return
        end
        if V.VehicleBoostVel then
            pcall(function() V.VehicleBoostVel:Destroy() end)
            V.VehicleBoostVel = nil
        end
        local veh = seat.Parent:IsA("Model") and seat.Parent or seat
        local root = (veh:IsA("Model") and veh.PrimaryPart) or seat
        
        local mode = V.VehicleBoostMode or "Camera"
        local boostDir
        if mode == "Vehicle Front" then
            boostDir = root.CFrame.LookVector
            if boostDir.Magnitude < 0.001 then boostDir = seat.CFrame.LookVector end
        else
            boostDir = Camera.CFrame.LookVector
            if boostDir.Magnitude < 0.001 then boostDir = seat.CFrame.LookVector end
        end
        boostDir = boostDir.Unit
        local bv = Instance.new("BodyVelocity")
        bv.Name ="NebulaBoostVel"
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = boostDir * (V.VehicleBoostSpeed or 250)
        bv.Parent = root
        V.VehicleBoostVel = bv
        Debris:AddItem(bv, 1.2)
        V.VehicleBoostEnd = os.clock() + 1.2
        notify("Vehicle","BOOST (" .. mode .. ") !", Color3.fromRGB(80, 200, 120))
    end)
end
_G.vehicleBoost = vehicleBoost

function instantBrake()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if not seat then
            notify("Vehicle","Tu dois être dans un véhicule !", Color3.fromRGB(255, 165, 0))
            return
        end
        local veh = seat.Parent:IsA("Model") and seat.Parent or seat
        for _, part in pairs(veh:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
        if V.VehicleBoostVel then
            pcall(function() V.VehicleBoostVel:Destroy() end)
            V.VehicleBoostVel = nil
        end
        notify("Vehicle","Freinage instantané !", Color3.fromRGB(80, 200, 120))
    end)
end
_G.instantBrake = instantBrake

createButton("Vehicle Boost (Touche T)", function()
    vehicleBoost()
end, VehicleContent)
createButton("Freinage Instantané (Touche N)", function()
    instantBrake()
end, VehicleContent)

if V.VehicleBoostHoldConn then V.VehicleBoostHoldConn:Disconnect() end
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Space then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart and (V.VehicleAutoJump ~= false) then
            jumpCar(V.VehicleJumpPower or 80)
        end
    end
end)

V.VehicleBoostHoldConn = UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Keybinds.VehicleBoost then
        vehicleBoost()
        if V.VehicleBoostHoldTask then return end
        V.VehicleBoostHoldTask = task.spawn(function()
            while UserInputService:IsKeyDown(Keybinds.VehicleBoost) do
                task.wait(0.15)
                vehicleBoost()
            end
            V.VehicleBoostHoldTask = nil
        end)
    end
end)
if V.VehicleBoostEndConn then V.VehicleBoostEndConn:Disconnect() end
V.VehicleBoostEndConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Keybinds.VehicleBoost then
        if V.VehicleBoostHoldTask then
            task.cancel(V.VehicleBoostHoldTask)
            V.VehicleBoostHoldTask = nil
        end
    end
end)



task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local seat = hum and hum.SeatPart
            if seat and seat:IsA("VehicleSeat") then
                if not seat:GetAttribute("_NebulaOrigMaxSpeed") then
                    seat:SetAttribute("_NebulaOrigMaxSpeed", seat.MaxSpeed)
                    seat:SetAttribute("_NebulaOrigTorque", seat.Torque)
                end
                local origSpeed = seat:GetAttribute("_NebulaOrigMaxSpeed") or seat.MaxSpeed
                local origTorque = seat:GetAttribute("_NebulaOrigTorque") or seat.Torque

                if V.VehicleSpeed and V.VehicleSpeed > 1 then
                    seat.MaxSpeed = origSpeed * V.VehicleSpeed
                    seat.Torque = origTorque * V.VehicleSpeed

                    local isForward = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
                    local isBackward = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)

                    if isForward and not isBackward then
                        local lookVec = seat.CFrame.LookVector
                        local fwdDir = Vector3.new(lookVec.X, 0, lookVec.Z).Unit
                        local currentVel = seat.AssemblyLinearVelocity
                        local hSpeed = Vector3.new(currentVel.X, 0, currentVel.Z).Magnitude
                        if hSpeed < (40 * V.VehicleSpeed) then
                            seat.AssemblyLinearVelocity = currentVel + fwdDir * ((V.VehicleSpeed - 1) * 2)
                        end
                    elseif isBackward and not isForward then
                        local lookVec = seat.CFrame.LookVector
                        local bwdDir = -Vector3.new(lookVec.X, 0, lookVec.Z).Unit
                        local currentVel = seat.AssemblyLinearVelocity
                        local hSpeed = Vector3.new(currentVel.X, 0, currentVel.Z).Magnitude
                        if hSpeed < (40 * V.VehicleSpeed) then
                            seat.AssemblyLinearVelocity = currentVel + bwdDir * ((V.VehicleSpeed - 1) * 2)
                        end
                    end
                else
                    seat.MaxSpeed = origSpeed
                    seat.Torque = origTorque
                end
            end
        end)
        if V.VehicleFly then
            V._VehFlyCleanedUp = false
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local seat = hum and hum.SeatPart
                if seat then
                    local root = seat.Parent:IsA("Model") and (seat.Parent.PrimaryPart or seat) or seat
                    local vehModel = seat.Parent:IsA("Model") and seat.Parent or nil
                    
                    local bg = root:FindFirstChild("VehFlyGyro") or Instance.new("BodyGyro")
                    bg.Name ="VehFlyGyro"
                    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                    bg.P = 9e4
                    bg.D = 500
                    bg.CFrame = Camera.CFrame
                    bg.Parent = root
                    
                    local bv = root:FindFirstChild("VehFlyVel") or Instance.new("BodyVelocity")
                    bv.Name ="VehFlyVel"
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    bv.Parent = root
                    
                    local rootVel = root.AssemblyLinearVelocity
                    if vehModel then
                        for _, part in pairs(vehModel:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                part.AssemblyLinearVelocity = rootVel
                            end
                        end
                    end
                    
                    local camCF = Camera.CFrame
                    local moveDir = Vector3.new()
                    
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
                        moveDir = moveDir + camCF.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
                        moveDir = moveDir - camCF.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
                        moveDir = moveDir - camCF.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
                        moveDir = moveDir + camCF.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        moveDir = moveDir + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                        moveDir = moveDir - Vector3.new(0, 1, 0)
                    end
                    
                    if moveDir.Magnitude > 0 then
                        bv.Velocity = moveDir.Unit * (V.VehicleFlySpeed or 150)
                    else
                        bv.Velocity = Vector3.new(0, 0, 0)
                    end
                    bg.CFrame = camCF
                end
            end)
        elseif not V._VehFlyCleanedUp then
            V._VehFlyCleanedUp = true
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local seat = hum and hum.SeatPart
                if seat then
                    local root = seat.Parent:IsA("Model") and (seat.Parent.PrimaryPart or seat) or seat
                    if root:FindFirstChild("VehFlyGyro") then root.VehFlyGyro:Destroy() end
                    if root:FindFirstChild("VehFlyVel") then root.VehFlyVel:Destroy() end
                end
            end)
        end
        
        if V.VehicleNoclip then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local seat = hum and hum.SeatPart
                if seat then
                    local veh = seat.Parent
                    if veh then
                        for _, part in pairs(veh:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                    seat.CanCollide = false
                    if char then
                        for _, p in pairs(char:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    end
end)

createLabel("Fun", FunContent)
createToggle("Click TP (Épée)", false, function(enabled) toggleClickTP(enabled) end, FunContent,"ClickTP")

createToggle("Ragdoll Mode (Ragdoll Volontaire)", false, function(enabled)
    pcall(function()
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = enabled
            if enabled then
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                notify("Fun","Ragdoll Mode ACTIVÉ", Color3.fromRGB(80, 200, 120))
            else
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                notify("Fun","Ragdoll Mode DÉSACTIVÉ", Color3.fromRGB(255, 90, 90))
            end
        end
    end)
end, FunContent,"RagdollMode")

createSlider("Spin Bot Speed", 10, 1000, 100, function(val) V.SpinSpeed = val end, FunContent,"SpinSpeed")
createToggle("Spin Bot (Toupie)", false, function(enabled)
    V.Spin = enabled
    if enabled then
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.AutoRotate = false end

        V.SpinConn = RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local spinAngle = math.rad(V.SpinSpeed * dt * 10)
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, spinAngle, 0)
                end
            end)
        end)
        addConnection(V.SpinConn)
        notify("Fun","Spin Bot ON", Color3.fromRGB(80, 200, 120))
    else
        if V.SpinConn then V.SpinConn:Disconnect() V.SpinConn = nil end
        pcall(function()
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.AutoRotate = true end
        end)
        notify("Fun","Spin Bot OFF", Color3.fromRGB(255, 90, 90))
    end
end, FunContent,"Spin")

function createGrappleBeam(startAtt, endAtt)
    local beam = Instance.new("Beam")
    beam.Name = "GrappleRope"
    beam.Attachment0 = startAtt
    beam.Attachment1 = endAtt
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    beam.Width0 = 0.12
    beam.Width1 = 0.12
    beam.FaceCamera = true
    beam.Texture = "rbxassetid://29712167"
    beam.TextureSpeed = 2
    beam.Transparency = NumberSequence.new(0.1)
    beam.Parent = startAtt.Parent
    return beam
end

function toggleGrappleHook(enabled)
    V.GrappleHook = enabled
    if enabled then
        if V.GrappleTool then V.GrappleTool:Destroy() end
        local tool = Instance.new("Tool")
        tool.Name = "Grappin Spider-Man"
        tool.RequiresHandle = true
        
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.6, 0.6, 1.5)
        handle.CanCollide = false
        handle.Transparency = 0.3
        handle.Color = Color3.fromRGB(200, 30, 40)
        handle.Material = Enum.Material.Neon
        handle.Parent = tool

        local isGrappling = false
        tool.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            local mouseLoc = UserInputService:GetMouseLocation()
            local unitRay = Camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {char}
            local hitRes = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1500, rayParams)
            
            local targetPos = hitRes and hitRes.Position or (mouse.Hit and mouse.Hit.Position)
            if not targetPos then return end
            local startPos = hrp.Position
            local dist = (targetPos - startPos).Magnitude
            if dist < 4 or dist > 2000 then return end

            local hitPart = (hitRes and hitRes.Instance) or workspace.Terrain
            local endAtt = Instance.new("Attachment")
            endAtt.WorldPosition = targetPos
            endAtt.Parent = hitPart

            local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or hrp
            local startAtt = Instance.new("Attachment")
            startAtt.Parent = hand
            local beam = createGrappleBeam(startAtt, endAtt)

            if hrp:FindFirstChild("GrappleBV") then hrp.GrappleBV:Destroy() end
            
            local bv = Instance.new("BodyVelocity")
            bv.Name = "GrappleBV"
            bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
            local dir = (targetPos - startPos).Unit
            local pullSpeed = math.clamp(dist * 2.5, 90, 280)
            local ballisticDir = (dir + Vector3.new(0, 0.15, 0)).Unit
            bv.Velocity = ballisticDir * pullSpeed
            bv.Parent = hrp

            task.spawn(function()
                local startTime = tick()
                while (hrp.Position - targetPos).Magnitude > 6 and (tick() - startTime) < 2.5 and tool.Parent == char do
                    local curDir = (targetPos - hrp.Position).Unit
                    local curDist = (targetPos - hrp.Position).Magnitude
                    local speed = math.clamp(curDist * 2.8, 70, 260)
                    bv.Velocity = (curDir + Vector3.new(0, 0.08, 0)).Unit * speed
                    task.wait(0.02)
                end
                
                if hrp:FindFirstChild("GrappleBV") then
                    bv.Velocity = (Camera.CFrame.LookVector + Vector3.new(0, 0.5, 0)).Unit * 80
                    task.wait(0.12)
                    pcall(function() bv:Destroy() end)
                end
                pcall(function()
                    beam:Destroy()
                    startAtt:Destroy()
                    endAtt:Destroy()
                end)
            end)
        end)

        tool.Parent = LocalPlayer.Backpack
        V.GrappleTool = tool
        notify("Fun", "Grappin Spider-Man ajouté dans l'inventaire !", Color3.fromRGB(80, 200, 120))
    else
        if V.GrappleTool then
            if V.GrappleTool.Parent == LocalPlayer.Character or V.GrappleTool.Parent == LocalPlayer.Backpack then
                V.GrappleTool:Destroy()
            end
            V.GrappleTool = nil
        end
        notify("Fun", "Grappin Spider-Man retiré.", Color3.fromRGB(255, 90, 90))
    end
end
_G.toggleGrappleHook = toggleGrappleHook

createToggle("Grappin Universel (Spider-Man Rope)", false, function(enabled)
    toggleGrappleHook(enabled)
end, FunContent, "GrappleHook")

sitAirBP = nil
sitAirBG = nil

function toggleSitAir(enabled)
    V.SitAir = enabled
    if V.SitAirConn then V.SitAirConn:Disconnect() V.SitAirConn = nil end
    if sitAirBP then pcall(function() sitAirBP:Destroy() end) sitAirBP = nil end
    if sitAirBG then pcall(function() sitAirBG:Destroy() end) sitAirBG = nil end

    if enabled then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            hum.Sit = true
            hum:ChangeState(Enum.HumanoidStateType.Seated)

            local bp = Instance.new("BodyPosition")
            bp.Name = "NebulaSitAirBP"
            bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bp.D = 400
            bp.P = 1e4
            bp.Position = hrp.Position
            bp.Parent = hrp
            sitAirBP = bp

            local bg = Instance.new("BodyGyro")
            bg.Name = "NebulaSitAirBG"
            bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bg.D = 400
            bg.P = 1e4
            bg.CFrame = hrp.CFrame
            bg.Parent = hrp
            sitAirBG = bg

            V.SitAirConn = RunService.RenderStepped:Connect(function()
                if not V.SitAir then return end
                local c = LocalPlayer.Character
                local h = c and c:FindFirstChildOfClass("Humanoid")
                if h and not h.Sit then
                    h.Sit = true
                    h:ChangeState(Enum.HumanoidStateType.Seated)
                end
            end)
            addConnection(V.SitAirConn)
        end)
        notify("Fun", "Sit Air (Assis dans les airs) ACTIVÉ", Color3.fromRGB(80, 200, 120))
    else
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if hrp:FindFirstChild("NebulaSitAirBP") then hrp.NebulaSitAirBP:Destroy() end
                if hrp:FindFirstChild("NebulaSitAirBG") then hrp.NebulaSitAirBG:Destroy() end
            end
            if hum then
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
        notify("Fun", "Sit Air DÉSACTIVÉ", Color3.fromRGB(255, 90, 90))
    end
end
_G.toggleSitAir = toggleSitAir

createToggle("Sit Air (Assis dans les airs)", false, function(enabled)
    toggleSitAir(enabled)
end, FunContent, "SitAir")

do
    local waterPlatform = nil
    local waterWalkSteppedConn = nil
    local waterWalkHeartbeatConn = nil
    local waterWalkCharConn = nil
    local waterWalkDescendantConn = nil
    local cachedWaterParts = {}
    local lastWaterY = nil

    local function scanWaterParts()
        cachedWaterParts = {}
        pcall(function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local lName = string.lower(obj.Name)
                    if string.find(lName, "water") or string.find(lName, "ocean") or string.find(lName, "sea") or string.find(lName, "lake") or string.find(lName, "river") or obj.Material == Enum.Material.Water then
                        table.insert(cachedWaterParts, obj)
                    end
                end
            end
        end)
    end

    local function disableWaterTouch()
        pcall(function()
            for _, obj in pairs(cachedWaterParts) do
                if obj and obj.Parent then
                    obj.CanTouch = false
                end
            end
        end)
    end

    local function restoreWaterTouch()
        pcall(function()
            for _, obj in pairs(cachedWaterParts) do
                if obj and obj.Parent then
                    obj.CanTouch = true
                end
            end
        end)
    end

    local function findWaterY(hrp, hum)
        if hum and (hum:GetState() == Enum.HumanoidStateType.Swimming or hum.FloorMaterial == Enum.Material.Water) then
            lastWaterY = hrp.Position.Y + 1.2
            return lastWaterY
        end

        local rayP = RaycastParams.new()
        rayP.FilterType = RaycastFilterType.Exclude
        rayP.FilterDescendantsInstances = {LocalPlayer.Character, waterPlatform}
        rayP.IgnoreWater = false

        local skyRay = workspace:Raycast(Vector3.new(hrp.Position.X, hrp.Position.Y + 120, hrp.Position.Z), Vector3.new(0, -300, 0), rayP)
        if skyRay then
            if skyRay.Material == Enum.Material.Water then
                lastWaterY = skyRay.Position.Y
                return lastWaterY
            end
            local hitName = string.lower(skyRay.Instance.Name)
            if string.find(hitName, "water") or string.find(hitName, "ocean") or string.find(hitName, "sea") or string.find(hitName, "lake") or string.find(hitName, "river") then
                lastWaterY = skyRay.Position.Y
                return lastWaterY
            end
        end

        local downRay = workspace:Raycast(Vector3.new(hrp.Position.X, hrp.Position.Y + 5, hrp.Position.Z), Vector3.new(0, -80, 0), rayP)
        if downRay then
            if downRay.Material == Enum.Material.Water then
                lastWaterY = downRay.Position.Y
                return lastWaterY
            end
            local hitName = string.lower(downRay.Instance.Name)
            if string.find(hitName, "water") or string.find(hitName, "ocean") or string.find(hitName, "sea") or string.find(hitName, "lake") or string.find(hitName, "river") then
                lastWaterY = downRay.Position.Y
                return lastWaterY
            end
        end

        if #cachedWaterParts > 0 then
            for _, part in ipairs(cachedWaterParts) do
                if part and part.Parent then
                    local topY = part.Position.Y + (part.Size.Y / 2)
                    local distH = Vector2.new(hrp.Position.X - part.Position.X, hrp.Position.Z - part.Position.Z).Magnitude
                    if distH < math.max(part.Size.X, part.Size.Z) * 0.7 or math.max(part.Size.X, part.Size.Z) > 300 then
                        if hrp.Position.Y < (topY + 30) and hrp.Position.Y > (topY - 80) then
                            lastWaterY = topY
                            return lastWaterY
                        end
                    end
                end
            end
        end

        if hrp.Position.Y <= 25 and hrp.Position.Y >= -100 then
            return 0
        end

        return lastWaterY
    end

    local function stepWaterWalk()
        if not V.WaterWalk or not waterPlatform then return end
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            local waterY = findWaterY(hrp, hum)
            if waterY ~= nil then
                waterPlatform.CFrame = CFrame.new(hrp.Position.X, waterY - 2, hrp.Position.Z)
                waterPlatform.CanCollide = true

                if hum:GetState() == Enum.HumanoidStateType.Swimming or hum.FloorMaterial == Enum.Material.Water or hrp.Position.Y < (waterY + 1) then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    if hrp.Position.Y < (waterY + 1.5) then
                        hrp.CFrame = CFrame.new(hrp.Position.X, waterY + 3.2, hrp.Position.Z)
                        local curV = hrp.AssemblyLinearVelocity
                        if curV.Y < 0 then
                            hrp.AssemblyLinearVelocity = Vector3.new(curV.X, 0, curV.Z)
                        end
                    end
                end
            else
                waterPlatform.CFrame = CFrame.new(hrp.Position.X, -5000, hrp.Position.Z)
                waterPlatform.CanCollide = false
            end
        end)
    end

    local function toggleWaterWalk(enabled)
        V.WaterWalk = enabled
        if waterWalkSteppedConn then waterWalkSteppedConn:Disconnect() waterWalkSteppedConn = nil end
        if waterWalkHeartbeatConn then waterWalkHeartbeatConn:Disconnect() waterWalkHeartbeatConn = nil end
        if waterWalkCharConn then waterWalkCharConn:Disconnect() waterWalkCharConn = nil end
        if waterWalkDescendantConn then waterWalkDescendantConn:Disconnect() waterWalkDescendantConn = nil end
        if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end

        if enabled then
            scanWaterParts()
            disableWaterTouch()

            waterPlatform = Instance.new("Part")
            waterPlatform.Name = "NebulaWaterWalkPlatform"
            waterPlatform.Size = Vector3.new(120, 4, 120)
            waterPlatform.Transparency = 1
            waterPlatform.Anchored = true
            waterPlatform.CanCollide = true
            waterPlatform.Material = Enum.Material.SmoothPlastic
            waterPlatform.CustomPhysicalProperties = PhysicalProperties.new(0.7, 1.0, 0, 1.0, 1.0)
            waterPlatform.Parent = workspace

            pcall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
                end
            end)

            waterWalkSteppedConn = RunService.Stepped:Connect(stepWaterWalk)
            addConnection(waterWalkSteppedConn)

            waterWalkHeartbeatConn = RunService.Heartbeat:Connect(stepWaterWalk)
            addConnection(waterWalkHeartbeatConn)

            waterWalkCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                if V.WaterWalk then
                    task.wait(0.3)
                    pcall(function()
                        local hum = newChar:WaitForChild("Humanoid", 3)
                        if hum then
                            hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
                        end
                    end)
                end
            end)
            addConnection(waterWalkCharConn)

            waterWalkDescendantConn = workspace.DescendantAdded:Connect(function(obj)
                if V.WaterWalk and obj:IsA("BasePart") then
                    local lName = string.lower(obj.Name)
                    if string.find(lName, "water") or string.find(lName, "ocean") or string.find(lName, "sea") or obj.Material == Enum.Material.Water then
                        table.insert(cachedWaterParts, obj)
                        pcall(function() obj.CanTouch = false end)
                    end
                end
            end)
            addConnection(waterWalkDescendantConn)

            notify("Fun", "Marcher sur l'eau (Sans degats) ACTIVE", Color3.fromRGB(80, 200, 120))
        else
            restoreWaterTouch()
            pcall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
                end
            end)
            notify("Fun", "Marcher sur l'eau DESACTIVE", Color3.fromRGB(255, 90, 90))
        end
    end

    createToggle("Marcher sur l'eau (Sans degats)", false, function(enabled)
        toggleWaterWalk(enabled)
    end, FunContent, "WaterWalk")
end

createLabel("PRE-MADE SCRIPTS", ScriptsContent)
do
    local ScriptScroll = Instance.new("ScrollingFrame")
    ScriptScroll.Size = UDim2.new(1, 0, 1, -30)
    ScriptScroll.Position = UDim2.new(0, 0, 0, 30)
    ScriptScroll.BackgroundTransparency = 1
    ScriptScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScriptScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScriptScroll.ScrollBarThickness = 2
    ScriptScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 55)
    ScriptScroll.Parent = ScriptsContent

    local ScriptListLayout = Instance.new("UIListLayout")
    ScriptListLayout.Padding = UDim.new(0, 5)
    ScriptListLayout.Parent = ScriptScroll

    local function destroyGuiByName(guiName)
        for _, child in pairs(parentTarget:GetChildren()) do
            if child:IsA("ScreenGui") and child.Name == guiName then
                child:Destroy()
            end
        end
    end

    local ScriptsList = {
        { 
            Name ="Flick", 
            Code = flick_script, 
            Destroy = function() 
                destroyGuiByName("EternalFlick_GUI")
                if V.HitboxConn then V.HitboxConn:Disconnect() V.HitboxConn = nil end
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("Head") then
                        local h = p.Character.Head
                        local orig = h:FindFirstChild("OriginalSize")
                        if orig and orig:IsA("Vector3Value") then
                            h.Size = orig.Value
                        elseif h:IsA("MeshPart") and h.MeshSize and h.MeshSize.Magnitude > 0 then
                            h.Size = h.MeshSize
                        else
                            h.Size = Vector3.new(1.2, 1.2, 1.2)
                        end
                        h.Transparency = 0
                        h.CanCollide = false
                    end
                end
            end 
        },
        { 
            Name ="Murder Mystery",
            Code = murder_mystery, 
            Destroy = function() 
                destroyGuiByName("UpdateGui")
            end 
        },
        { 
            Name ="Grow Garden 2", 
            Code = grow_garden, 
            Destroy = function() 
                destroyGuiByName("UpdateGui")
                if _G.Nebula_OrigFogEnd then
                    Lighting.FogEnd = _G.Nebula_OrigFogEnd
                    Lighting.FogStart = _G.Nebula_OrigFogStart
                else
                    Lighting.FogEnd = 100000
                    Lighting.FogStart = 0
                end
            end 
        },
        { 
            Name ="Tsunami Brainrot", 
            Code = tsunami_brainrot, 
            Destroy = function() 
                destroyGuiByName("UpdateGui")
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("Humanoid") then
                        p.Character.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                    end
                end
            end 
        }
    }

        local function buildScriptRow(scriptData)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        row.BorderSizePixel = 0
        row.Parent = ScriptScroll
        makeCorner(row, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = scriptData.Name
        lbl.TextColor3 = Color3.fromRGB(195, 195, 208)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(0, 60, 0, 26)
        loadBtn.Position = UDim2.new(1, -130, 0.5, -13)
        loadBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
        loadBtn.BorderSizePixel = 0
        loadBtn.Text = "Load"
        loadBtn.TextColor3 = Color3.fromRGB(195, 195, 208)
        loadBtn.Font = Enum.Font.GothamMedium
        loadBtn.TextSize = 11
        loadBtn.Parent = row
        makeCorner(loadBtn, 5)

        local destBtn = Instance.new("TextButton")
        destBtn.Size = UDim2.new(0, 60, 0, 26)
        destBtn.Position = UDim2.new(1, -65, 0.5, -13)
        destBtn.BackgroundColor3 = Color3.fromRGB(40, 22, 22)
        destBtn.BorderSizePixel = 0
        destBtn.Text = "Destroy"
        destBtn.TextColor3 = Color3.fromRGB(170, 110, 110)
        destBtn.Font = Enum.Font.GothamMedium
        destBtn.TextSize = 10
        destBtn.Parent = row
        makeCorner(destBtn, 5)

        loadBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if executeCodeWithSandbox then
                    executeCodeWithSandbox(scriptData.Code)
                else
                    loadstring(scriptData.Code)()
                end
            end)
            notify("Scripts", scriptData.Name .. " loaded!", Color3.fromRGB(80, 200, 120))
        end)

        destBtn.MouseButton1Click:Connect(function()
            pcall(scriptData.Destroy)
            notify("Scripts", scriptData.Name .. " destroyed!", Color3.fromRGB(255, 90, 90))
        end)
    end

    for _, scriptData in ipairs(ScriptsList) do
        buildScriptRow(scriptData)
    end
end

initStep = "cablage Scripts/Settings"


function updateThemeAccent(col)
    V.AccentColor = col
    if setAccentColor then
        pcall(function() setAccentColor(col) end)
    end
    notify("Theme","Couleur d'accentuation mise à jour !", col)
end

do
    local KeybindHUDFrame = Instance.new("Frame")
    KeybindHUDFrame.Name ="NebulaKeybindHUD"
    KeybindHUDFrame.Size = UDim2.new(0, 200, 0, 230)
    KeybindHUDFrame.Position = UDim2.new(1, -210, 0.25, 0)
    KeybindHUDFrame.BackgroundColor3 = theme.panel
    KeybindHUDFrame.BackgroundTransparency = 0.05
    KeybindHUDFrame.BorderSizePixel = 0
    KeybindHUDFrame.Visible = false
    KeybindHUDFrame.Active = true
    KeybindHUDFrame.Draggable = true
    KeybindHUDFrame.Parent = ScreenGui

    makeCorner(KeybindHUDFrame, 12)
    makeStroke(KeybindHUDFrame, theme.border, 1.2)

    local khHeader = Instance.new("Frame")
    khHeader.Size = UDim2.new(1, -12, 0, 34)
    khHeader.Position = UDim2.new(0, 6, 0, 6)
    khHeader.BackgroundColor3 = theme.panel2
    khHeader.BorderSizePixel = 0
    khHeader.Parent = KeybindHUDFrame
    makeCorner(khHeader, 8)
    makeStroke(khHeader, theme.border, 1)

    local khTitle = Instance.new("TextLabel")
    khTitle.Size = UDim2.new(1, -16, 1, 0)
    khTitle.Position = UDim2.new(0, 10, 0, 0)
    khTitle.BackgroundTransparency = 1
    khTitle.Text = "KEYBINDS HUD"
    khTitle.TextColor3 = theme.accent
    khTitle.Font = Enum.Font.GothamBold
    khTitle.TextSize = 11
    khTitle.TextXAlignment = Enum.TextXAlignment.Left
    khTitle.Parent = khHeader

    local khContent = Instance.new("ScrollingFrame")
    khContent.Size = UDim2.new(1, -12, 1, -48)
    khContent.Position = UDim2.new(0, 6, 0, 44)
    khContent.BackgroundTransparency = 1
    khContent.BorderSizePixel = 0
    khContent.ScrollBarThickness = 2
    khContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    khContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    khContent.Parent = KeybindHUDFrame

    local khLayout = Instance.new("UIListLayout", khContent)
    khLayout.Padding = UDim.new(0, 4)

    createToggle("Keybind List Overlay", false, function(enabled)
        V.KeybindHUD = enabled
        KeybindHUDFrame.Visible = enabled
        if enabled then notify("Settings","Keybind HUD ON", Color3.fromRGB(80, 200, 120)) end
    end, SettingsContent,"KeybindHUD")

    task.spawn(function()
        while task.wait(0.2) do
            if V.KeybindHUD then
                for _, child in pairs(khContent:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end
                for name, key in pairs(Keybinds) do
                    local active = false
                    if name =="Fly"and V.Fly then active = true
                    elseif name =="Noclip"and V.Noclip then active = true
                    elseif name =="Invisible"and V.Invis then active = true
                    elseif name =="DesyncFly"and V.DesyncFly then active = true
                    elseif name =="ESP"and V.ESP then active = true
                    elseif name =="Speed"and V.SpeedEnabled then active = true
                    elseif name =="Freecam"and FreecamMenu and FreecamMenu.Enabled then active = true
                    end

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 26)
                    row.BackgroundColor3 = theme.card
                    row.BorderSizePixel = 0
                    row.Parent = khContent
                    makeCorner(row, 6)
                    makeStroke(row, theme.border, 1)

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.65, 0, 1, 0)
                    lbl.Position = UDim2.new(0, 8, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = name .." [".. key.Name .."]"
                    lbl.TextColor3 = theme.text
                    lbl.Font = Enum.Font.GothamMedium
                    lbl.TextSize = 10
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local statusBadge = Instance.new("TextLabel")
                    statusBadge.Size = UDim2.new(0, 42, 0, 18)
                    statusBadge.Position = UDim2.new(1, -48, 0.5, -9)
                    statusBadge.BackgroundColor3 = active and Color3.fromRGB(25, 55, 35) or theme.panel2
                    statusBadge.Text = active and "ON" or "OFF"
                    statusBadge.TextColor3 = active and Color3.fromRGB(80, 220, 120) or theme.sub
                    statusBadge.Font = Enum.Font.GothamBold
                    statusBadge.TextSize = 9
                    statusBadge.BorderSizePixel = 0
                    statusBadge.Parent = row
                    makeCorner(statusBadge, 4)
                    makeStroke(statusBadge, active and Color3.fromRGB(40, 90, 55) or theme.border, 1)
                end
            end
        end
    end)
end

createToggle("Bulles Animées (Background)", true, function(enabled)
    V.BubblesEnabled = enabled
    if BubblesContainer then
        BubblesContainer.Visible = enabled
    end
end, SettingsContent,"BubblesEnabled")

createToggle("Fond Sombre (Opacité / Dimmer)", true, function(enabled)
    V.DimmerEnabled = enabled
    if BackgroundDimmer then
        BackgroundDimmer.Visible = enabled
    end
end, SettingsContent,"DimmerEnabled")

createSlider("Opacité Fond Sombre (Dimmer)", 0, 100, 80, function(val)
    V.DimmerOpacity = val
    if BackgroundDimmer then
        BackgroundDimmer.BackgroundTransparency = 1 - (val / 100)
    end
end, SettingsContent,"DimmerOpacity")

createSlider("UI Opacity / Transparency", 0, 80, 0, function(val)
    V.UITransparency = val
    if BloxFruitsPanel then
        BloxFruitsPanel.BackgroundTransparency = val / 100
    end
end, SettingsContent,"UITransparency")



createLabel("SYSTEM", SettingsContent)

do
    local shiftLockEnabled = false
    local shiftLockActive = false
    local shiftLockConn = nil
    local shiftLockInputConn = nil
    local shiftLockDot = nil

    local function updateShiftLockState(active)
        shiftLockActive = active
        pcall(function()
            if shiftLockActive then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.AutoRotate = false end
                if not shiftLockDot then
                    shiftLockDot = Instance.new("Frame")
                    shiftLockDot.Name = "NebulaShiftLockDot"
                    shiftLockDot.Size = UDim2.new(0, 6, 0, 6)
                    shiftLockDot.AnchorPoint = Vector2.new(0.5, 0.5)
                    shiftLockDot.Position = UDim2.new(0.5, 0.5, 0.5, 0)
                    shiftLockDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    shiftLockDot.BorderSizePixel = 0
                    shiftLockDot.ZIndex = 9999
                    shiftLockDot.Parent = ScreenGui
                    makeCorner(shiftLockDot, 3)
                end
                shiftLockDot.Visible = true
            else
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.AutoRotate = true end
                if shiftLockDot then shiftLockDot.Visible = false end
            end
        end)
    end

    createToggle("Shift Lock (Any Games)", false, function(enabled)
        shiftLockEnabled = enabled
        pcall(function() LocalPlayer.DevEnableMouseLock = true end)

        if shiftLockConn then shiftLockConn:Disconnect() shiftLockConn = nil end
        if shiftLockInputConn then shiftLockInputConn:Disconnect() shiftLockInputConn = nil end

        if enabled then
            updateShiftLockState(true)

            shiftLockConn = RunService.RenderStepped:Connect(function()
                if not shiftLockEnabled then return end
                pcall(function()
                    LocalPlayer.DevEnableMouseLock = true
                    if shiftLockActive then
                        if not menuOpen and not UserInputService:GetFocusedTextBox() then
                            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                        end
                        local char = LocalPlayer.Character
                        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if hrp and hum then
                            hum.AutoRotate = false
                            local camLook = Camera.CFrame.LookVector
                            local flat = Vector3.new(camLook.X, 0, camLook.Z)
                            if flat.Magnitude > 0 then
                                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flat.Unit)
                            end
                        end
                    end
                end)
            end)
            addConnection(shiftLockConn)

            shiftLockInputConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
                    if shiftLockEnabled then
                        updateShiftLockState(not shiftLockActive)
                    end
                end
            end)
            addConnection(shiftLockInputConn)

            notify("Settings", "Shift Lock (Any Games) ON", Color3.fromRGB(80, 200, 120))
        else
            updateShiftLockState(false)
            if shiftLockDot then shiftLockDot:Destroy() shiftLockDot = nil end
            notify("Settings", "Shift Lock (Any Games) OFF", Color3.fromRGB(255, 90, 90))
        end
    end, SettingsContent, "ShiftLockAnyGames")
end

do
    local antiAfkConn = nil
    createToggle("Real Anti-AFK System", false, function(enabled)
        V.AntiAFK = enabled
        if enabled then
            local VirtualUser = game:GetService("VirtualUser")
            
            if antiAfkConn then antiAfkConn:Disconnect() end
            antiAfkConn = LocalPlayer.Idled:Connect(function()
                if V.AntiAFK then
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new(0, 0))
                    end)
                end
            end)
            addConnection(antiAfkConn)

            task.spawn(function()
                while V.AntiAFK do
                    task.wait(45)
                    if V.AntiAFK then
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                            task.wait(0.1)
                            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                        end)
                    end
                end
            end)

            notify("Settings","Real Anti-AFK System ON", Color3.fromRGB(80, 200, 120))
        else
            if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
            notify("Settings","Anti-AFK System OFF", Color3.fromRGB(255, 90, 90))
        end
    end, SettingsContent,"AntiAFK")
end

createToggle("Notifications", true, function(enabled)
    V.Notif = enabled
    if enabled then
        notify("Settings","Notifications ON", Color3.fromRGB(80, 200, 120))
    end
end, SettingsContent,"Notif")

do
    local WatermarkFrame = Instance.new("Frame")
    WatermarkFrame.Name = "WatermarkFrame"
    WatermarkFrame.AnchorPoint = Vector2.new(0.5, 0)
    WatermarkFrame.Position = UDim2.new(0.5, 0, 0, 10)
    WatermarkFrame.Size = UDim2.new(0, 0, 0, 24)
    WatermarkFrame.AutomaticSize = Enum.AutomaticSize.X
    WatermarkFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    WatermarkFrame.BackgroundTransparency = 0.15
    WatermarkFrame.BorderSizePixel = 0
    WatermarkFrame.ZIndex = 50
    WatermarkFrame.Visible = true
    WatermarkFrame.Parent = ScreenGui
    makeCorner(WatermarkFrame, 6)
    makeStroke(WatermarkFrame, Color3.fromRGB(45, 45, 62), 1)

    local watermarkPad = Instance.new("UIPadding")
    watermarkPad.PaddingLeft = UDim.new(0, 12)
    watermarkPad.PaddingRight = UDim.new(0, 12)
    watermarkPad.PaddingTop = UDim.new(0, 2)
    watermarkPad.PaddingBottom = UDim.new(0, 2)
    watermarkPad.Parent = WatermarkFrame

    local WatermarkLabel = Instance.new("TextLabel")
    WatermarkLabel.Name = "WatermarkLabel"
    WatermarkLabel.Size = UDim2.new(0, 0, 1, 0)
    WatermarkLabel.AutomaticSize = Enum.AutomaticSize.X
    WatermarkLabel.BackgroundTransparency = 1
    WatermarkLabel.RichText = true
    WatermarkLabel.Text = '<font color="rgb(145,120,255)"><b>NEBULA</b></font>  <font color="rgb(70,75,98)">|</font>  <font color="rgb(240,242,250)"><b>V2</b></font>  <font color="rgb(70,75,98)">|</font>  <font color="rgb(165,145,255)">-- FPS</font>  <font color="rgb(70,75,98)">|</font>  <font color="rgb(165,145,255)">-- ms</font>  <font color="rgb(70,75,98)">|</font>  <font color="rgb(140,146,168)">[Insert]</font>'
    WatermarkLabel.Font = Enum.Font.GothamMedium
    WatermarkLabel.TextSize = 11
    WatermarkLabel.ZIndex = 51
    WatermarkLabel.Parent = WatermarkFrame

    local function showWatermark(visible)
        if visible then
            WatermarkFrame.Visible = true
            TweenService:Create(WatermarkFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 10)}):Play()
        else
            TweenService:Create(WatermarkFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -35)}):Play()
            task.delay(0.25, function()
                if not V.Watermark then
                    WatermarkFrame.Visible = false
                end
            end)
        end
    end

    V.Watermark = true
    createToggle("Afficher Watermark", true, function(enabled)
        V.Watermark = enabled
        showWatermark(enabled)
        notify("Settings", "Watermark " .. (enabled and "ON" or "OFF"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
    end, SettingsContent, "ShowWatermark")

    local wmFrameCount = 0
    local wmLastTime = tick()
    local wmFPS = 60
    local wmPing = 0

    local wmConn = RunService.RenderStepped:Connect(function()
        wmFrameCount = wmFrameCount + 1
        local now = tick()
        if now - wmLastTime >= 0.4 then
            wmFPS = math.floor(wmFrameCount / (now - wmLastTime))
            wmFrameCount = 0
            wmLastTime = now

            pcall(function()
                local stats = game:GetService("Stats")
                local pingItem = stats and stats.Network and stats.Network.ServerStatsItem and stats.Network.ServerStatsItem["Data Ping"]
                if pingItem then
                    wmPing = math.floor(pingItem:GetValue())
                else
                    wmPing = math.floor(LocalPlayer:GetNetworkPing() * 1000)
                end
            end)

            if WatermarkLabel and WatermarkFrame and WatermarkFrame.Visible then
                local keyName = (Keybinds and Keybinds.Menu and Keybinds.Menu.Name) or "Insert"
                WatermarkLabel.Text = string.format('<font color="rgb(145,120,255)"><b>NEBULA</b></font>  <font color="rgb(70,75,98)">|</font>  <font color="rgb(240,242,250)"><b>V2</b></font>  <font color="rgb(70,75,98)">|</font>  <font color="rgb(165,145,255)">%d FPS</font>  <font color="rgb(70,75,98)">|</font>  <font color="rgb(165,145,255)">%d ms</font>  <font color="rgb(70,75,98)">|</font>  <font color="rgb(140,146,168)">[%s]</font>', wmFPS, wmPing, keyName)
            end
        end
    end)
    if C and C.All then table.insert(C.All, wmConn) end
end

do
    local MenuKeybindFrame = createCard(SettingsContent, 0, 44)

    local MenuKeyLabel = Instance.new("TextLabel")
    MenuKeyLabel.Size = UDim2.new(0.6, 0, 1, 0)
    MenuKeyLabel.Position = UDim2.new(0, 14, 0, 0)
    MenuKeyLabel.BackgroundTransparency = 1
    MenuKeyLabel.Text = "Menu Toggle Key"
    MenuKeyLabel.TextColor3 = theme.text
    MenuKeyLabel.Font = Enum.Font.GothamMedium
    MenuKeyLabel.TextSize = 12
    MenuKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    MenuKeyLabel.ZIndex = 8
    MenuKeyLabel.Parent = MenuKeybindFrame

    local MenuKeyBtn = Instance.new("TextButton")
    MenuKeyBtn.Size = UDim2.new(0, 84, 0, 26)
    MenuKeyBtn.Position = UDim2.new(1, -96, 0.5, -13)
    MenuKeyBtn.BackgroundColor3 = theme.cardHover
    MenuKeyBtn.BorderSizePixel = 0
    MenuKeyBtn.Text = Keybinds.Menu.Name
    MenuKeyBtn.TextColor3 = theme.accent
    MenuKeyBtn.Font = Enum.Font.GothamBold
    MenuKeyBtn.TextSize = 11
    MenuKeyBtn.ZIndex = 8
    MenuKeyBtn.Parent = MenuKeybindFrame

    makeCorner(MenuKeyBtn, 6)
    local menuBtnStroke = makeStroke(MenuKeyBtn, theme.border, 1)

    KeybindButtons["Menu"] = MenuKeyBtn

    MenuKeyBtn.MouseEnter:Connect(function()
        if not (KeybindSystem.Binding and KeybindSystem.BindingName == "Menu") then
            menuBtnStroke.Color = theme.accent
        end
    end)
    MenuKeyBtn.MouseLeave:Connect(function()
        if not (KeybindSystem.Binding and KeybindSystem.BindingName == "Menu") then
            menuBtnStroke.Color = theme.border
        end
    end)

    MenuKeyBtn.MouseButton1Click:Connect(function()
        pcall(function() game:GetService("GuiService").SelectedObject = nil end)
        KeybindSystem.Binding = true
        KeybindSystem.BindingName = "Menu"
        KeybindSystem.BindingBtn = MenuKeyBtn
        MenuKeyBtn.Text = "Press..."
        MenuKeyBtn.BackgroundColor3 = theme.accent
        MenuKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        menuBtnStroke.Color = theme.accent
    end)

    createLabel("CLAVIER & DISPOSITION", SettingsContent)
createToggle("Mode Clavier AZERTY (Touches ZQSD)", true, function(enabled)
    V.KeyboardLayout = enabled and "AZERTY" or "QWERTY"
    notify("Settings", enabled and "Clavier AZERTY (ZQSD) Verrouille" or "Clavier QWERTY Actif", Color3.fromRGB(80, 200, 120))
end, SettingsContent, "KeyboardLayoutSetting")
createLabel("KEYBINDS", SettingsContent)
    local function createKeybindButton(name, defaultKey, callback)
        local KeybindFrame = createCard(SettingsContent, 0, 44)

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.6, 0, 1, 0)
        Label.Position = UDim2.new(0, 14, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = name
        Label.TextColor3 = theme.text
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 12
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 8
        Label.Parent = KeybindFrame

        local KeyBtn = Instance.new("TextButton")
        KeyBtn.Size = UDim2.new(0, 84, 0, 26)
        KeyBtn.Position = UDim2.new(1, -96, 0.5, -13)
        KeyBtn.BackgroundColor3 = theme.cardHover
        KeyBtn.BorderSizePixel = 0
        KeyBtn.Text = Keybinds[name] and Keybinds[name].Name or defaultKey.Name
        KeyBtn.TextColor3 = theme.accent
        KeyBtn.Font = Enum.Font.GothamBold
        KeyBtn.TextSize = 11
        KeyBtn.ZIndex = 8
        KeyBtn.Parent = KeybindFrame

        makeCorner(KeyBtn, 6)
        local btnStroke = makeStroke(KeyBtn, theme.border, 1)

        KeybindCallbacks[name] = callback
        KeybindButtons[name] = KeyBtn

        KeyBtn.MouseEnter:Connect(function()
            if not (KeybindSystem.Binding and KeybindSystem.BindingName == name) then
                btnStroke.Color = theme.accent
            end
        end)
        KeyBtn.MouseLeave:Connect(function()
            if not (KeybindSystem.Binding and KeybindSystem.BindingName == name) then
                btnStroke.Color = theme.border
            end
        end)

        KeyBtn.MouseButton1Click:Connect(function()
            pcall(function() game:GetService("GuiService").SelectedObject = nil end)
            KeybindSystem.Binding = true
            KeybindSystem.BindingName = name
            KeybindSystem.BindingBtn = KeyBtn
            KeyBtn.Text = "Press..."
            KeyBtn.BackgroundColor3 = theme.accent
            KeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btnStroke.Color = theme.accent
        end)
    end

    createKeybindButton("Fly", Keybinds.Fly, function() toggleFlyAction() end)
    createKeybindButton("Noclip", Keybinds.Noclip, ToggleNoclip)
    createKeybindButton("Invisible", Keybinds.Invisible, ToggleInvis)
    createKeybindButton("DesyncFly", Keybinds.DesyncFly, ToggleDesync)
    createKeybindButton("ESP", Keybinds.ESP, ToggleESP)
    createKeybindButton("Speed", Keybinds.Speed, ToggleSpeed)
    createKeybindButton("Respawn", Keybinds.Respawn, respawnPlayer)
    createKeybindButton("Freecam", Keybinds.Freecam, ToggleFreecam)
    createKeybindButton("VehicleFly", Keybinds.VehicleFly, function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart then
            V.VehicleFly = not V.VehicleFly
            notify("Vehicle","Vehicle Fly".. (V.VehicleFly and"ON"or"OFF"), V.VehicleFly and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
        end
    end)
    createKeybindButton("VehicleBoost", Keybinds.VehicleBoost, function()
        vehicleBoost()
    end)
    createKeybindButton("InstantBrake", Keybinds.InstantBrake, function()
        instantBrake()
    end)
    createKeybindButton("VehicleSeatTP", Keybinds.VehicleSeatTP, function()
        if _G.tpToAimVehicleSeat then _G.tpToAimVehicleSeat(true) end
    end)
    createKeybindButton("VehicleAutoFlip", Keybinds.VehicleAutoFlip, function()
        if _G.flipVehicle then _G.flipVehicle() end
    end)
    createKeybindButton("VehicleExplode", Keybinds.VehicleExplode, function()
        if _G.explodeVehicle then _G.explodeVehicle() end
    end)
    createKeybindButton("VehiclePropulse", Keybinds.VehiclePropulse, function()
        if _G.toggleCarCarry then _G.toggleCarCarry() end
    end)
end

createLabel("UNLOAD", SettingsContent)
createButton("Unload le Hub", function()
    performFullUnload()
end, SettingsContent, "Unload", true)

initStep = "cablage Config/Code"
createLabel("CONFIGURATION", ConfigContent)
do
    local ConfigNameBox = Instance.new("TextBox")
    ConfigNameBox.Size = UDim2.new(1, 0, 0, 34)
    ConfigNameBox.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    ConfigNameBox.BorderSizePixel = 0
    ConfigNameBox.PlaceholderText ="Nom de la config (ex: Main)"
    ConfigNameBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
    ConfigNameBox.Text ="Default"
    ConfigNameBox.TextColor3 = Color3.fromRGB(210, 210, 222)
    ConfigNameBox.Font = Enum.Font.GothamMedium
    ConfigNameBox.TextSize = 12
    ConfigNameBox.TextXAlignment = Enum.TextXAlignment.Left
    ConfigNameBox.Parent = ConfigContent

    local ConfigNamePadding = Instance.new("UIPadding")
    ConfigNamePadding.PaddingLeft = UDim.new(0, 10)
    ConfigNamePadding.Parent = ConfigNameBox

    local ConfigNameCorner = Instance.new("UICorner")
    ConfigNameCorner.CornerRadius = UDim.new(0, 6)
    ConfigNameCorner.Parent = ConfigNameBox

    local ConfigListFrame = Instance.new("Frame")
    ConfigListFrame.Size = UDim2.new(1, 0, 0, 220)
    ConfigListFrame.Position = UDim2.new(0, 0, 0, 40)
    ConfigListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ConfigListFrame.BorderSizePixel = 0
    ConfigListFrame.Parent = ConfigContent

    local ConfigListFrameCorner = Instance.new("UICorner")
    ConfigListFrameCorner.CornerRadius = UDim.new(0, 8)
    ConfigListFrameCorner.Parent = ConfigListFrame

    local ConfigList = Instance.new("ScrollingFrame")
    ConfigList.Size = UDim2.new(1, 0, 1, 0)
    ConfigList.BackgroundTransparency = 1
    ConfigList.CanvasSize = UDim2.new(0, 0, 0, 0)
    ConfigList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ConfigList.ScrollBarThickness = 2
    ConfigList.Parent = ConfigListFrame

    local ConfigListLayout = Instance.new("UIListLayout")
    ConfigListLayout.Padding = UDim.new(0, 5)
    ConfigListLayout.Parent = ConfigList

    local ConfigListPadding = Instance.new("UIPadding")
    ConfigListPadding.PaddingTop = UDim.new(0, 5)
    ConfigListPadding.PaddingLeft = UDim.new(0, 5)
    ConfigListPadding.PaddingRight = UDim.new(0, 5)
    ConfigListPadding.Parent = ConfigList

    local function applyLoadedConfig(cfg, cfgName)
        pcall(function()
            for key, val in pairs(DefaultConfig) do
                if ConfigRegistry[key] then
                    pcall(ConfigRegistry[key], val)
                end
            end
            for key, setter in pairs(ConfigRegistry) do
                if cfg[key] ~= nil then
                    pcall(setter, cfg[key])
                end
            end
            if cfg.Keybinds and type(cfg.Keybinds) == "table" then
                local kb = cfg.Keybinds
                if kb.Fly and Enum.KeyCode[kb.Fly] then Keybinds.Fly = Enum.KeyCode[kb.Fly] end
                if kb.Noclip and Enum.KeyCode[kb.Noclip] then Keybinds.Noclip = Enum.KeyCode[kb.Noclip] end
                if kb.Invisible and Enum.KeyCode[kb.Invisible] then Keybinds.Invisible = Enum.KeyCode[kb.Invisible] end
                if kb.DesyncFly and Enum.KeyCode[kb.DesyncFly] then Keybinds.DesyncFly = Enum.KeyCode[kb.DesyncFly] end
                if kb.ESP and Enum.KeyCode[kb.ESP] then Keybinds.ESP = Enum.KeyCode[kb.ESP] end
                if kb.Speed and Enum.KeyCode[kb.Speed] then Keybinds.Speed = Enum.KeyCode[kb.Speed] end
                if kb.Respawn and Enum.KeyCode[kb.Respawn] then Keybinds.Respawn = Enum.KeyCode[kb.Respawn] end
                if kb.Menu and Enum.KeyCode[kb.Menu] then Keybinds.Menu = Enum.KeyCode[kb.Menu] end
                if kb.Freecam and Enum.KeyCode[kb.Freecam] then Keybinds.Freecam = Enum.KeyCode[kb.Freecam] end
                if kb.VehicleFly and Enum.KeyCode[kb.VehicleFly] then Keybinds.VehicleFly = Enum.KeyCode[kb.VehicleFly] end
                if kb.VehicleBoost and Enum.KeyCode[kb.VehicleBoost] then Keybinds.VehicleBoost = Enum.KeyCode[kb.VehicleBoost] end
                if kb.InstantBrake and Enum.KeyCode[kb.InstantBrake] then Keybinds.InstantBrake = Enum.KeyCode[kb.InstantBrake] end
                if kb.VehicleSeatTP and Enum.KeyCode[kb.VehicleSeatTP] then Keybinds.VehicleSeatTP = Enum.KeyCode[kb.VehicleSeatTP] end
                if kb.VehicleAutoFlip and Enum.KeyCode[kb.VehicleAutoFlip] then Keybinds.VehicleAutoFlip = Enum.KeyCode[kb.VehicleAutoFlip] end
                if kb.VehicleExplode and Enum.KeyCode[kb.VehicleExplode] then Keybinds.VehicleExplode = Enum.KeyCode[kb.VehicleExplode] end
                if kb.VehiclePropulse and Enum.KeyCode[kb.VehiclePropulse] then Keybinds.VehiclePropulse = Enum.KeyCode[kb.VehiclePropulse] end
                if kb.Aimlock then
                    local kName = tostring(kb.Aimlock)
                    _G.Aimlock_KeyName = kName
                    Aimlock_KeyName = kName
                    if kName == "M1" then
                        _G.Aimlock_Key = Enum.UserInputType.MouseButton1
                    elseif kName == "M2" then
                        _G.Aimlock_Key = Enum.UserInputType.MouseButton2
                    elseif kName == "M3" then
                        _G.Aimlock_Key = Enum.UserInputType.MouseButton3
                    elseif Enum.KeyCode[kName] then
                        _G.Aimlock_Key = Enum.KeyCode[kName]
                    end
                    Aimlock_Key = _G.Aimlock_Key
                    if AimlockKeyBtn then
                        AimlockKeyBtn.Text = "[" .. kName .. "]"
                    end
                end
                for name, btn in pairs(KeybindButtons) do
                    if Keybinds[name] then btn.Text = Keybinds[name].Name end
                end
            end
            if writefile then pcall(function() writefile("Nebula_LastConfig.txt", cfgName) end) end
            notify("Config", cfgName .. " chargée avec succès !", Color3.fromRGB(80, 200, 120))
        end)
    end

    local function refreshConfigList()
        pcall(function()
            for _, child in pairs(ConfigList:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
            end

            local discoveredConfigs = {}
            local configFiles = {}

            -- 1. Try listfiles with various argument styles
            if listfiles then
                local files = nil
                local ok, res = pcall(function() return listfiles("") end)
                if ok and type(res) == "table" then
                    files = res
                else
                    ok, res = pcall(function() return listfiles(".") end)
                    if ok and type(res) == "table" then
                        files = res
                    else
                        ok, res = pcall(function() return listfiles() end)
                        if ok and type(res) == "table" then
                            files = res
                        end
                    end
                end

                if files then
                    for _, filePath in ipairs(files) do
                        local fileName = string.match(filePath, "([^/\\]+)$") or filePath
                        local cfgName = string.match(fileName, "NebulaConfig_(.-)%.json")
                        if cfgName and cfgName ~= "" then
                            discoveredConfigs[cfgName] = true
                            configFiles[cfgName] = filePath
                        end
                    end
                end
            end

            -- 2. Fallback / supplementary index file
            pcall(function()
                if readfile and isfile and isfile("Nebula_ConfigIndex.json") then
                    local idxRaw = readfile("Nebula_ConfigIndex.json")
                    local ok, data = pcall(function() return HttpService:JSONDecode(idxRaw) end)
                    if ok and type(data) == "table" then
                        for _, name in ipairs(data) do
                            if type(name) == "string" and name ~= "" then
                                local fname = "NebulaConfig_" .. name .. ".json"
                                local fileExists = true
                                if isfile then
                                    local okCheck, exists = pcall(function() return isfile(fname) end)
                                    if okCheck then fileExists = exists end
                                end
                                if fileExists then
                                    discoveredConfigs[name] = true
                                    if not configFiles[name] then
                                        configFiles[name] = fname
                                    end
                                end
                            end
                        end
                    end
                end
            end)

            -- Also check default config file
            pcall(function()
                if isfile and isfile("NebulaConfig_Default.json") then
                    discoveredConfigs["Default"] = true
                    if not configFiles["Default"] then
                        configFiles["Default"] = "NebulaConfig_Default.json"
                    end
                end
            end)

            local hasConfigs = false
            for cfgName, _ in pairs(discoveredConfigs) do
                hasConfigs = true
                local filePath = configFiles[cfgName] or ("NebulaConfig_" .. cfgName .. ".json")
                local CfgFrame = Instance.new("Frame")
                CfgFrame.Size = UDim2.new(1, 0, 0, 38)
                CfgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                CfgFrame.BorderSizePixel = 0
                CfgFrame.Parent = ConfigList

                local CfgCorner = Instance.new("UICorner")
                CfgCorner.CornerRadius = UDim.new(0, 8)
                CfgCorner.Parent = CfgFrame

                local CfgLabel = Instance.new("TextLabel")
                CfgLabel.Size = UDim2.new(0.4, 0, 1, 0)
                CfgLabel.Position = UDim2.new(0, 10, 0, 0)
                CfgLabel.BackgroundTransparency = 1
                CfgLabel.Text = cfgName
                CfgLabel.TextColor3 = Color3.fromRGB(195, 195, 208)
                CfgLabel.Font = Enum.Font.GothamMedium
                CfgLabel.TextSize = 12
                CfgLabel.TextXAlignment = Enum.TextXAlignment.Left
                CfgLabel.Parent = CfgFrame

                local LoadBtn = Instance.new("TextButton")
                LoadBtn.Size = UDim2.new(0, 50, 0, 26)
                LoadBtn.Position = UDim2.new(1, -235, 0.5, -13)
                LoadBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
                LoadBtn.BorderSizePixel = 0
                LoadBtn.Text = "Load"
                LoadBtn.TextColor3 = Color3.fromRGB(195, 195, 208)
                LoadBtn.Font = Enum.Font.GothamMedium
                LoadBtn.TextSize = 11
                LoadBtn.Parent = CfgFrame

                local LoadCorner = Instance.new("UICorner")
                LoadCorner.CornerRadius = UDim.new(0, 5)
                LoadCorner.Parent = LoadBtn

                LoadBtn.MouseEnter:Connect(function()
                    TweenService:Create(LoadBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
                end)
                LoadBtn.MouseLeave:Connect(function()
                    TweenService:Create(LoadBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(26, 26, 32)}):Play()
                end)

                LoadBtn.MouseButton1Click:Connect(function()
                    local content = nil
                    if readfile then
                        local ok, data = pcall(function() return readfile(filePath) end)
                        if ok and data then
                            content = data
                        else
                            local ok2, data2 = pcall(function() return readfile("NebulaConfig_" .. cfgName .. ".json") end)
                            if ok2 and data2 then content = data2 end
                        end
                    end
                    if content then
                        local okDecode, cfg = pcall(function() return HttpService:JSONDecode(content) end)
                        if okDecode and type(cfg) == "table" then
                            applyLoadedConfig(cfg, cfgName)
                        else
                            notify("Config", "Erreur décodage JSON pour " .. cfgName, Color3.fromRGB(255, 90, 90))
                        end
                    else
                        notify("Config", "Impossible de lire " .. cfgName, Color3.fromRGB(255, 90, 90))
                    end
                end)

                local ExportBtn = Instance.new("TextButton")
                ExportBtn.Size = UDim2.new(0, 50, 0, 26)
                ExportBtn.Position = UDim2.new(1, -175, 0.5, -13)
                ExportBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
                ExportBtn.BorderSizePixel = 0
                ExportBtn.Text = "Export"
                ExportBtn.TextColor3 = Color3.fromRGB(195, 195, 208)
                ExportBtn.Font = Enum.Font.GothamMedium
                ExportBtn.TextSize = 11
                ExportBtn.Parent = CfgFrame

                local ExpCorner = Instance.new("UICorner")
                ExpCorner.CornerRadius = UDim.new(0, 5)
                ExpCorner.Parent = ExportBtn

                ExportBtn.MouseButton1Click:Connect(function()
                    local content = nil
                    if readfile then
                        local ok, data = pcall(function() return readfile(filePath) end)
                        if ok and data then content = data
                        else
                            local ok2, data2 = pcall(function() return readfile("NebulaConfig_" .. cfgName .. ".json") end)
                            if ok2 and data2 then content = data2 end
                        end
                    end
                    if content and setclipboard then
                        pcall(function() setclipboard(content) end)
                        notify("Config", "Config copiée dans le presse-papier !", Color3.fromRGB(80, 200, 120))
                    else
                        notify("Config", "Presse-papier non supporté ou fichier vide.", Color3.fromRGB(255, 90, 90))
                    end
                end)

                local UnloadBtn = Instance.new("TextButton")
                UnloadBtn.Size = UDim2.new(0, 50, 0, 26)
                UnloadBtn.Position = UDim2.new(1, -115, 0.5, -13)
                UnloadBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 22)
                UnloadBtn.BorderSizePixel = 0
                UnloadBtn.Text = "Unload"
                UnloadBtn.TextColor3 = Color3.fromRGB(255, 165, 0)
                UnloadBtn.Font = Enum.Font.GothamMedium
                UnloadBtn.TextSize = 11
                UnloadBtn.Parent = CfgFrame

                local UnloadCorner = Instance.new("UICorner")
                UnloadCorner.CornerRadius = UDim.new(0, 5)
                UnloadCorner.Parent = UnloadBtn

                UnloadBtn.MouseEnter:Connect(function()
                    TweenService:Create(UnloadBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 45, 30)}):Play()
                end)
                UnloadBtn.MouseLeave:Connect(function()
                    TweenService:Create(UnloadBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 30, 22)}):Play()
                end)

                UnloadBtn.MouseButton1Click:Connect(function()
                    for key, val in pairs(DefaultConfig) do
                        if ConfigRegistry[key] then
                            pcall(ConfigRegistry[key], val)
                        end
                    end
                    Keybinds.Fly = Enum.KeyCode.F
                    Keybinds.Noclip = Enum.KeyCode.V
                    Keybinds.Invisible = Enum.KeyCode.C
                    Keybinds.DesyncFly = Enum.KeyCode.G
                    Keybinds.ESP = Enum.KeyCode.E
                    Keybinds.Speed = Enum.KeyCode.R
                    Keybinds.Respawn = Enum.KeyCode.B
                    Keybinds.Menu = Enum.KeyCode.Insert
                    Keybinds.Freecam = Enum.KeyCode.X
                    Keybinds.VehicleFly = Enum.KeyCode.H
                    Keybinds.VehicleBoost = Enum.KeyCode.T
                    Keybinds.InstantBrake = Enum.KeyCode.N
                    _G.Aimlock_Key = Enum.KeyCode.E
                    _G.Aimlock_KeyName = "E"
                    Aimlock_Key = Enum.KeyCode.E
                    Aimlock_KeyName = "E"
                    if AimlockKeyBtn then AimlockKeyBtn.Text = "[E]" end
                    for name, btn in pairs(KeybindButtons) do
                        if Keybinds[name] then btn.Text = Keybinds[name].Name end
                    end
                    notify("Config", "Config déchargée (Paramètres par défaut) !", Color3.fromRGB(255, 165, 0))
                end)

                local DelBtn = Instance.new("TextButton")
                DelBtn.Size = UDim2.new(0, 50, 0, 26)
                DelBtn.Position = UDim2.new(1, -55, 0.5, -13)
                DelBtn.BackgroundColor3 = Color3.fromRGB(40, 22, 22)
                DelBtn.BorderSizePixel = 0
                DelBtn.Text = "Delete"
                DelBtn.TextColor3 = Color3.fromRGB(170, 110, 110)
                DelBtn.Font = Enum.Font.GothamMedium
                DelBtn.TextSize = 11
                DelBtn.Parent = CfgFrame

                local DelCorner = Instance.new("UICorner")
                DelCorner.CornerRadius = UDim.new(0, 5)
                DelCorner.Parent = DelBtn

                DelBtn.MouseEnter:Connect(function()
                    TweenService:Create(DelBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 30, 30)}):Play()
                end)
                DelBtn.MouseLeave:Connect(function()
                    TweenService:Create(DelBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 22, 22)}):Play()
                end)

                DelBtn.MouseButton1Click:Connect(function()
                    if delfile then
                        pcall(function() delfile(filePath) end)
                        pcall(function() delfile("NebulaConfig_" .. cfgName .. ".json") end)
                    end
                    pcall(function()
                        if readfile and isfile and isfile("Nebula_ConfigIndex.json") and writefile then
                            local idxRaw = readfile("Nebula_ConfigIndex.json")
                            local ok, data = pcall(function() return HttpService:JSONDecode(idxRaw) end)
                            if ok and type(data) == "table" then
                                local newIdx = {}
                                for _, n in ipairs(data) do
                                    if n ~= cfgName then table.insert(newIdx, n) end
                                end
                                writefile("Nebula_ConfigIndex.json", HttpService:JSONEncode(newIdx))
                            end
                        end
                    end)
                    notify("Config", cfgName .. " supprimée !", Color3.fromRGB(255, 90, 90))
                    pcall(refreshConfigList)
                end)
            end

            if not hasConfigs then
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 0, 30)
                lbl.BackgroundTransparency = 1
                lbl.Text = "No configs found"
                lbl.TextColor3 = Color3.fromRGB(120, 120, 132)
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 12
                lbl.Parent = ConfigList
            end
        end)
    end

    local function saveConfig(customName)
        local cfgName = customName or ConfigNameBox.Text
        if not cfgName or cfgName:gsub("%s+", "") == "" then cfgName = "Default" end
        cfgName = cfgName:gsub("[^%w_%-%s]", "")
        if cfgName == "" then cfgName = "Default" end
        local fileName = "NebulaConfig_" .. cfgName .. ".json"

        local success, err = pcall(function()
            local cfg = {}
            for key, val in pairs(DefaultConfig) do
                if V[key] ~= nil then
                    cfg[key] = V[key]
                else
                    cfg[key] = val
                end
            end
            for key, _ in pairs(ConfigRegistry) do
                if V[key] ~= nil then
                    cfg[key] = V[key]
                end
            end

            local function getBindName(bind, fallback)
                if typeof(bind) == "EnumItem" then
                    return bind.Name
                elseif type(bind) == "string" then
                    return bind
                end
                return fallback
            end

            cfg.Keybinds = {
                Fly = getBindName(Keybinds.Fly, "F"),
                Noclip = getBindName(Keybinds.Noclip, "V"),
                Invisible = getBindName(Keybinds.Invisible, "C"),
                DesyncFly = getBindName(Keybinds.DesyncFly, "G"),
                ESP = getBindName(Keybinds.ESP, "E"),
                Speed = getBindName(Keybinds.Speed, "R"),
                Respawn = getBindName(Keybinds.Respawn, "B"),
                Menu = getBindName(Keybinds.Menu, "Insert"),
                Freecam = getBindName(Keybinds.Freecam, "X"),
                VehicleFly = getBindName(Keybinds.VehicleFly, "H"),
                VehicleBoost = getBindName(Keybinds.VehicleBoost, "T"),
                InstantBrake = getBindName(Keybinds.InstantBrake, "N"),
                VehicleSeatTP = getBindName(Keybinds.VehicleSeatTP, "J"),
                VehicleAutoFlip = getBindName(Keybinds.VehicleAutoFlip, "K"),
                VehicleExplode = getBindName(Keybinds.VehicleExplode, "L"),
                VehiclePropulse = getBindName(Keybinds.VehiclePropulse, "P"),
                Aimlock = tostring(_G.Aimlock_KeyName or Aimlock_KeyName or "E")
            }

            if writefile then
                local encoded = HttpService:JSONEncode(cfg)
                writefile(fileName, encoded)
                pcall(function() writefile("Nebula_LastConfig.txt", cfgName) end)

                pcall(function()
                    local index = {}
                    if isfile and isfile("Nebula_ConfigIndex.json") and readfile then
                        local idxRaw = readfile("Nebula_ConfigIndex.json")
                        local ok, data = pcall(function() return HttpService:JSONDecode(idxRaw) end)
                        if ok and type(data) == "table" then index = data end
                    end
                    local found = false
                    for _, n in ipairs(index) do
                        if n == cfgName then found = true break end
                    end
                    if not found then table.insert(index, cfgName) end
                    writefile("Nebula_ConfigIndex.json", HttpService:JSONEncode(index))
                end)

                if not customName then
                    notify("Config", "Config '" .. cfgName .. "' sauvegardée avec succès !", Color3.fromRGB(80, 200, 120))
                end
                pcall(refreshConfigList)
            else
                if not customName then
                    notify("Config", "writefile non supporté par l'exécuteur.", Color3.fromRGB(255, 90, 90))
                end
            end
        end)

        if not success then
            notify("Config", "Erreur sauvegarde : " .. tostring(err):sub(1, 40), Color3.fromRGB(255, 90, 90))
        end
    end
    _G.saveNebulaConfig = saveConfig

    local function loadConfigByName(cfgName)
        local fileName = "NebulaConfig_" .. cfgName .. ".json"
        local content = nil
        if readfile then
            local ok, data = pcall(function() return readfile(fileName) end)
            if ok and data then content = data end
        end
        if content then
            local okDecode, cfg = pcall(function() return HttpService:JSONDecode(content) end)
            if okDecode and type(cfg) == "table" then
                applyLoadedConfig(cfg, cfgName)
            end
        end
    end
    _G.loadNebulaConfigByName = loadConfigByName

    createButton("Save Config", function() saveConfig() end, ConfigContent)

    createButton("Importer Config", function()
        local ImportGui = Instance.new("ScreenGui")
        ImportGui.Name = "NebulaImportGui"
        ImportGui.Parent = parentTarget
        
        local MainFrame = Instance.new("Frame")
        MainFrame.Size = UDim2.new(0, 300, 0, 300)
        MainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
        MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        MainFrame.BorderSizePixel = 0
        MainFrame.Parent = ImportGui
        local IC = Instance.new("UICorner", MainFrame)
        IC.CornerRadius = UDim.new(0, 8)

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 30)
        Title.BackgroundTransparency = 1
        Title.Text = "IMPORTER UNE CONFIG"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 14
        Title.Parent = MainFrame

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -20, 0, 20)
        NameLabel.Position = UDim2.new(0, 10, 0, 35)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = "Nom de la config:"
        NameLabel.TextColor3 = Color3.fromRGB(195, 195, 208)
        NameLabel.Font = Enum.Font.GothamMedium
        NameLabel.TextSize = 12
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = MainFrame

        local NameBox = Instance.new("TextBox")
        NameBox.Size = UDim2.new(1, -20, 0, 30)
        NameBox.Position = UDim2.new(0, 10, 0, 55)
        NameBox.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
        NameBox.TextColor3 = Color3.fromRGB(210, 210, 222)
        NameBox.Font = Enum.Font.GothamMedium
        NameBox.TextSize = 12
        NameBox.Text = "Imported"
        NameBox.TextXAlignment = Enum.TextXAlignment.Left
        NameBox.Parent = MainFrame
        local NCPad = Instance.new("UIPadding", NameBox)
        NCPad.PaddingLeft = UDim.new(0, 10)
        local NCCorner = Instance.new("UICorner", NameBox)
        NCCorner.CornerRadius = UDim.new(0, 6)

        local BoxLabel = Instance.new("TextLabel")
        BoxLabel.Size = UDim2.new(1, -20, 0, 20)
        BoxLabel.Position = UDim2.new(0, 10, 0, 95)
        BoxLabel.BackgroundTransparency = 1
        BoxLabel.Text = "Code JSON:"
        BoxLabel.TextColor3 = Color3.fromRGB(195, 195, 208)
        BoxLabel.Font = Enum.Font.GothamMedium
        BoxLabel.TextSize = 12
        BoxLabel.TextXAlignment = Enum.TextXAlignment.Left
        BoxLabel.Parent = MainFrame

        local Box = Instance.new("TextBox")
        Box.Size = UDim2.new(1, -20, 1, -190)
        Box.Position = UDim2.new(0, 10, 0, 115)
        Box.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
        Box.TextColor3 = Color3.fromRGB(255, 255, 255)
        Box.Font = Enum.Font.Code
        Box.TextSize = 12
        Box.TextWrapped = true
        Box.MultiLine = true
        Box.TextXAlignment = Enum.TextXAlignment.Left
        Box.TextYAlignment = Enum.TextYAlignment.Top
        Box.PlaceholderText = "Colle le code JSON ici..."
        Box.Parent = MainFrame
        local BC = Instance.new("UICorner", Box)
        BC.CornerRadius = UDim.new(0, 6)

        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Size = UDim2.new(0.5, -10, 0, 30)
        CloseBtn.Position = UDim2.new(0, 10, 1, -40)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
        CloseBtn.Text = "Annuler"
        CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.TextSize = 12
        CloseBtn.Parent = MainFrame
        local CC = Instance.new("UICorner", CloseBtn)
        CC.CornerRadius = UDim.new(0, 6)
        CloseBtn.MouseButton1Click:Connect(function() ImportGui:Destroy() end)

        local SaveBtn = Instance.new("TextButton")
        SaveBtn.Size = UDim2.new(0.5, -10, 0, 30)
        SaveBtn.Position = UDim2.new(0.5, 0, 1, -40)
        SaveBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
        SaveBtn.Text = "Sauvegarder"
        SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        SaveBtn.Font = Enum.Font.GothamBold
        SaveBtn.TextSize = 12
        SaveBtn.Parent = MainFrame
        local SC = Instance.new("UICorner", SaveBtn)
        SC.CornerRadius = UDim.new(0, 6)

        SaveBtn.MouseButton1Click:Connect(function()
            if writefile and Box.Text ~= "" then
                local cfgName = NameBox.Text
                if not cfgName or cfgName:gsub("%s+", "") == "" then cfgName = "Imported" end
                cfgName = cfgName:gsub("[^%w_%-%s]", "")
                if cfgName == "" then cfgName = "Imported" end
                local fileName = "NebulaConfig_" .. cfgName .. ".json"
                
                local ok, err = pcall(function()
                    writefile(fileName, Box.Text)
                    pcall(function()
                        local index = {}
                        if isfile and isfile("Nebula_ConfigIndex.json") and readfile then
                            local idxRaw = readfile("Nebula_ConfigIndex.json")
                            local ok2, data = pcall(function() return HttpService:JSONDecode(idxRaw) end)
                            if ok2 and type(data) == "table" then index = data end
                        end
                        local found = false
                        for _, n in ipairs(index) do
                            if n == cfgName then found = true break end
                        end
                        if not found then table.insert(index, cfgName) end
                        writefile("Nebula_ConfigIndex.json", HttpService:JSONEncode(index))
                    end)
                    notify("Config", "Config importée : " .. cfgName, Color3.fromRGB(80, 200, 120))
                    pcall(refreshConfigList)
                    ImportGui:Destroy()
                end)
                if not ok then
                    notify("Config", "Erreur import : " .. tostring(err):sub(1, 40), Color3.fromRGB(255, 90, 90))
                end
            else
                notify("Config", "Erreur: Ecriture non supportée ou vide.", Color3.fromRGB(255, 90, 90))
            end
        end)
    end, ConfigContent)

    pcall(refreshConfigList)
end

V.SolaraBypassEnabled = true
V.SpoofedExecutorName = "Matcha"
V.SpoofedExecutorVer = "v3.0.0"
V.AntiCrashSandbox = true
V.AntiTelemetryEnabled = true
V.LuaTurboBooster = true
V.VirtualSecurityIdentity = true
V.AutoBypassFilters = true

function applyGlobalSolaraBypass()
    pcall(function()
        local spoofName = V.SpoofedExecutorName or "Matcha"
        local spoofVer = V.SpoofedExecutorVer or "v3.0.0"
        local g = (getgenv and pcall(getgenv) and getgenv()) or _G

        pcall(function() if setreadonly then setreadonly(g, false) end end)
        pcall(function() if make_writeable then make_writeable(g) end end)

        pcall(function()
            if hookfunction and rawget(g, "identifyexecutor") then
                hookfunction(rawget(g, "identifyexecutor"), function() return spoofName, spoofVer end)
            end
            if hookfunction and rawget(g, "getexecutorname") then
                hookfunction(rawget(g, "getexecutorname"), function() return spoofName end)
            end
        end)

        g.identifyexecutor = function() return spoofName, spoofVer end
        g.getexecutorname = function() return spoofName end
        g.whatexecutor = g.identifyexecutor

        _G.identifyexecutor = g.identifyexecutor
        _G.getexecutorname = g.getexecutorname
        _G.whatexecutor = g.identifyexecutor

        if shared then
            shared.identifyexecutor = g.identifyexecutor
            shared.getexecutorname = g.getexecutorname
            shared.whatexecutor = g.identifyexecutor
        end

        pcall(function()
            local f = getfenv(0)
            if f then
                f.identifyexecutor = g.identifyexecutor
                f.getexecutorname = g.getexecutorname
                f.whatexecutor = g.identifyexecutor
            end
        end)

        if not g.checkcaller then g.checkcaller = function() return true end end
        if not g.isexecutorclosure then g.isexecutorclosure = function() return true end end
        if not g.isourclosure then g.isourclosure = function() return true end end
        if not g.newcclosure then g.newcclosure = function(f) return f end end
        if not g.cloneref then g.cloneref = function(r) return r end end
        if not g.clonefunction then g.clonefunction = function(f) return function(...) return f(...) end end end
        if not g.compareinstances then g.compareinstances = function(a, b) return a == b end end

        if not g.getrawmetatable then
            g.getrawmetatable = function(t)
                local ok, res = pcall(function() return (debug and debug.getmetatable and debug.getmetatable(t)) or getmetatable(t) end)
                return (ok and res) or {}
            end
        end
        if not g.setrawmetatable then
            g.setrawmetatable = function(t, mt)
                local ok, res = pcall(function() return (debug and debug.setmetatable and debug.setmetatable(t, mt)) or setmetatable(t, mt) end)
                return (ok and res) or t
            end
        end
        if not g.setreadonly then g.setreadonly = function(t, ro) return t end end
        if not g.isreadonly then g.isreadonly = function(t) return false end end
        if not g.make_writeable then g.make_writeable = function(t) return t end end
        if not g.make_readonly then g.make_readonly = function(t) return t end end
        if not g.hookfunction then g.hookfunction = function(o, n) return o end end
        if not g.replaceclosure then g.replaceclosure = function(o, n) return o end end
        if not g.hookmetamethod then
            g.hookmetamethod = function(obj, m, hook)
                local mt = g.getrawmetatable(obj)
                if mt and type(mt) == "table" then
                    local old = mt[m]
                    pcall(function() mt[m] = hook end)
                    return old or function() end
                end
                return function() end
            end
        end
        if not g.getnamecallmethod then g.getnamecallmethod = function() return "" end end
        if not g.setnamecallmethod then g.setnamecallmethod = function(m) end end

        if not g.getinstances then g.getinstances = function() return game:GetDescendants() end end
        if not g.getnilinstances then g.getnilinstances = function() return {} end end
        if not g.getscripts then
            g.getscripts = function()
                local s = {}
                for _, v in ipairs(game:GetDescendants()) do
                    if v:IsA("LocalScript") or v:IsA("ModuleScript") then table.insert(s, v) end
                end
                return s
            end
        end
        if not g.getrunningscripts then g.getrunningscripts = g.getscripts end
        if not g.getloadedmodules then g.getloadedmodules = function() return {} end end
        if not g.getgc then g.getgc = function() return {} end end
        if not g.getreg then g.getreg = function() return {} end end

        if not g.Drawing then
            g.Drawing = {
                new = function(dtype)
                    local obj = {
                        Visible = false,
                        ZIndex = 1,
                        Transparency = 1,
                        Color = Color3.new(1, 1, 1),
                        Remove = function() end,
                        Destroy = function() end
                    }
                    if dtype == "Line" then
                        obj.From = Vector2.new(0, 0)
                        obj.To = Vector2.new(0, 0)
                        obj.Thickness = 1
                    elseif dtype == "Circle" then
                        obj.Radius = 10
                        obj.Position = Vector2.new(0, 0)
                        obj.Thickness = 1
                        obj.Filled = false
                        obj.NumSides = 16
                    elseif dtype == "Square" then
                        obj.Size = Vector2.new(0, 0)
                        obj.Position = Vector2.new(0, 0)
                        obj.Thickness = 1
                        obj.Filled = false
                    elseif dtype == "Text" then
                        obj.Text = ""
                        obj.Size = 14
                        obj.Center = false
                        obj.Outline = false
                        obj.OutlineColor = Color3.new(0, 0, 0)
                        obj.Position = Vector2.new(0, 0)
                        obj.TextBounds = Vector2.new(0, 0)
                    end
                    return obj
                end,
                Fonts = { UI = 0, System = 1, Plex = 2, Monospace = 3 }
            }
        end

        if not g.fireclickdetector then
            g.fireclickdetector = function(cd)
                pcall(function()
                    if cd and cd:IsA("ClickDetector") and LocalPlayer then
                        cd.MouseClick:Fire(LocalPlayer)
                    end
                end)
            end
        end
        if not g.fireproximityprompt then
            g.fireproximityprompt = function(pp)
                pcall(function()
                    if pp and pp:IsA("ProximityPrompt") then
                        pp:InputHoldBegin()
                        task.wait(pp.HoldDuration or 0.1)
                        pp:InputHoldEnd()
                    end
                end)
            end
        end
        if not g.firetouchinterest then
            g.firetouchinterest = function(p1, p2)
                pcall(function() if p1 and p2 then p1.CFrame = p2.CFrame end end)
            end
        end

        if not g.setclipboard then
            g.setclipboard = function(t)
                local cl = rawget(getfenv(0), "setclipboard") or rawget(getfenv(0), "toclipboard")
                if cl then cl(tostring(t)) end
            end
        end
        if not g.toclipboard then g.toclipboard = g.setclipboard end
        if not g.getclipboard then g.getclipboard = function() return "" end end

        if not g.syn then
            g.syn = {
                request = g.request or rawget(getfenv(0), "request") or rawget(getfenv(0), "http_request"),
                protect_gui = function(gui)
                    pcall(function()
                        if gethui then gui.Parent = gethui()
                        elseif CoreGui then gui.Parent = CoreGui end
                    end)
                end,
                unprotect_gui = function(gui) end,
                is_cached = function() return false end,
                cache_replace = function() end,
                cache_invalidate = function() end,
                set_thread_identity = function(id) end,
                get_thread_identity = function() return 8 end,
                queue_on_teleport = function(code)
                    local q = rawget(getfenv(0), "queue_on_teleport")
                    if q then q(code) end
                end
            }
        end
        if not g.queue_on_teleport and g.syn then g.queue_on_teleport = g.syn.queue_on_teleport end
        if not g.getthreadidentity then g.getthreadidentity = function() return 8 end end
        if not g.setthreadidentity then g.setthreadidentity = function() end end

        if not g.crypt then
            local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
            local function b64encode(data)
                return ((data:gsub(".", function(x) 
                    local r,b="",x:byte()
                    for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and "1" or "0") end
                    return r
                end).."0000"):gsub("%d%d%d?%d?%d?", function(x)
                    if (#x < 6) then return "" end
                    local c=0
                    for i=1,6 do c=c+(x:sub(i,i)=="1" and 2^(6-i) or 0) end
                    return b64chars:sub(c+1,c+1)
                end)..({ "", "==", "=" })[#data%3+1])
            end
            local function b64decode(data)
                data = string.gsub(data, "[^"..b64chars.."=]", "")
                return (data:gsub(".", function(x)
                    if (x == "=") then return "" end
                    local r,f="",(b64chars:find(x)-1)
                    for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and "1" or "0") end
                    return r
                end):gsub("%d%d%d%d%d%d%d%d", function(x)
                    local c=0
                    for i=1,8 do c=c+(x:sub(i,i)=="1" and 2^(8-i) or 0) end
                    return string.char(c)
                end))
            end
            g.base64_encode = b64encode
            g.base64_decode = b64decode
            g.base64 = { encode = b64encode, decode = b64decode }
            g.crypt = {
                base64_encode = b64encode,
                base64_decode = b64decode,
                base64encode = b64encode,
                base64decode = b64decode,
                base64 = { encode = b64encode, decode = b64decode },
                encrypt = function(d) return d end,
                decrypt = function(d) return d end,
                generatebytes = function(len) return string.rep("x", len or 16) end,
                generatekey = function() return string.rep("k", 32) end,
                hash = function(d) return tostring(#d * 31337) end
            }
        end
    end)
end
applyGlobalSolaraBypass()

function buildVirtualExecutionChunk(rawCode)
    local spoofName = V.SpoofedExecutorName or "Matcha"
    local spoofVer = V.SpoofedExecutorVer or "v3.0.0"

    local cleanedCode = rawCode
    if V.AutoBypassFilters then
        cleanedCode = cleanedCode:gsub('([iI][dD][eE][nN][tT][iI][fF][yY][eE][xX][eE][cC][uU][tT][oO][rR]%s*%(%s*%))', '("' .. spoofName .. '", "' .. spoofVer .. '")')
        cleanedCode = cleanedCode:gsub('([gG][eE][tT][eE][xX][eE][cC][uU][tT][oO][rR][nN][aA][mM][eE]%s*%(%s*%))', '("' .. spoofName .. '")')
        cleanedCode = cleanedCode:gsub('([wW][hH][aA][tT][eE][xX][eE][cC][uU][tT][oO][rR]%s*%(%s*%))', '("' .. spoofName .. '", "' .. spoofVer .. '")')
    end

    local header = 'local __VIRT_NAME = "' .. spoofName .. '"\n'
    header = header .. 'local __VIRT_VER = "' .. spoofVer .. '"\n'
    header = header .. 'local identifyexecutor = function() return __VIRT_NAME, __VIRT_VER end\n'
    header = header .. 'local getexecutorname = function() return __VIRT_NAME end\n'
    header = header .. 'local whatexecutor = identifyexecutor\n'
    header = header .. 'local checkcaller = function() return true end\n'
    header = header .. 'local isexecutorclosure = function() return true end\n'
    header = header .. 'local isourclosure = isexecutorclosure\n'
    header = header .. 'local islclosure = function(f) return type(f) == "function" end\n'
    header = header .. 'local iscclosure = function(f) return false end\n'
    header = header .. 'local newcclosure = function(f) return f end\n'
    header = header .. 'local cloneref = function(r) return r end\n'
    header = header .. 'local clonefunction = function(f) return function(...) return f(...) end end\n'
    header = header .. 'local compareinstances = function(a, b) return a == b end\n'
    header = header .. 'local getgenv = function() local g = (rawget(_G, "getgenv") and _G.getgenv()) or _G; pcall(function() g.identifyexecutor = identifyexecutor g.getexecutorname = getexecutorname g.whatexecutor = identifyexecutor end); return g end\n'
    header = header .. 'local getrenv = function() return getgenv() end\n'
    header = header .. 'local getrawmetatable = getrawmetatable or function(t) return (debug and debug.getmetatable and debug.getmetatable(t)) or getmetatable(t) or {} end\n'
    header = header .. 'local setrawmetatable = setrawmetatable or function(t, mt) return (debug and debug.setmetatable and debug.setmetatable(t, mt)) or setmetatable(t, mt) or t end\n'
    header = header .. 'local setreadonly = setreadonly or make_writeable or function(t, b) return t end\n'
    header = header .. 'local isreadonly = isreadonly or function(t) return false end\n'
    header = header .. 'local make_writeable = make_writeable or function(t) return t end\n'
    header = header .. 'local make_readonly = make_readonly or function(t) return t end\n'
    header = header .. 'local hookfunction = hookfunction or replaceclosure or function(o, n) return o end\n'
    header = header .. 'local replaceclosure = hookfunction\n'
    header = header .. 'local hookmetamethod = hookmetamethod or function(o, m, h) local mt = getrawmetatable(o); if mt and type(mt) == "table" then local old = mt[m]; pcall(function() mt[m] = h end); return old or function() end end return function() end end\n'
    header = header .. 'local getnamecallmethod = getnamecallmethod or function() return "" end\n'
    header = header .. 'local setnamecallmethod = setnamecallmethod or function(m) end\n'
    header = header .. 'local getinstances = getinstances or function() return game:GetDescendants() end\n'
    header = header .. 'local getnilinstances = getnilinstances or function() return {} end\n'
    header = header .. 'local getscripts = getscripts or function() local s = {}; for _, v in ipairs(game:GetDescendants()) do if v:IsA("LocalScript") or v:IsA("ModuleScript") then table.insert(s, v) end end return s end\n'
    header = header .. 'local getrunningscripts = getscripts\n'
    header = header .. 'local getloadedmodules = getloadedmodules or function() return {} end\n'
    header = header .. 'local getgc = getgc or function() return {} end\n'
    header = header .. 'local getreg = getreg or function() return {} end\n'
    header = header .. 'local getthreadidentity = function() return 8 end\n'
    header = header .. 'local setthreadidentity = function(id) end\n'
    header = header .. 'local printidentity = function() print("Current identity is 8") end\n'
    header = header .. 'local gethui = gethui or function() return game:GetService("CoreGui") or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")) end\n'
    header = header .. 'local protectgui = protectgui or (syn and syn.protect_gui) or function(gui) pcall(function() if gethui then gui.Parent = gethui() end end) end\n'
    header = header .. 'local unprotectgui = unprotectgui or function(gui) end\n'
    header = header .. 'local fireclickdetector = fireclickdetector or function(cd) pcall(function() if cd and cd:IsA("ClickDetector") and LocalPlayer then cd.MouseClick:Fire(LocalPlayer) end end) end\n'
    header = header .. 'local fireproximityprompt = fireproximityprompt or function(pp) pcall(function() if pp and pp:IsA("ProximityPrompt") then pp:InputHoldBegin(); task.wait(pp.HoldDuration or 0.1); pp:InputHoldEnd() end end) end\n'
    header = header .. 'local firetouchinterest = firetouchinterest or function(p1, p2) pcall(function() if p1 and p2 then p1.CFrame = p2.CFrame end end) end\n'
    header = header .. 'local getcustomasset = getcustomasset or function(p) return "rbxasset://" .. tostring(p) end\n'
    header = header .. 'local rconsoleprint = rconsoleprint or function(t) print(t) end\n'
    header = header .. 'local rconsolewarn = rconsolewarn or function(t) warn(t) end\n'
    header = header .. 'local rconsoleerr = rconsoleerr or function(t) warn("[ERR] " .. tostring(t)) end\n'
    header = header .. 'local rconsoleclear = rconsoleclear or function() end\n'
    header = header .. 'local rconsolename = rconsolename or function(t) end\n'
    header = header .. 'local Drawing = (rawget(_G, "Drawing") or (getgenv and getgenv().Drawing))\n'
    header = header .. 'local crypt = (rawget(_G, "crypt") or (getgenv and getgenv().crypt))\n'
    header = header .. 'local syn = (rawget(_G, "syn") or (getgenv and getgenv().syn))\n'
    header = header .. 'local __orig_loadstring = loadstring\n'
    header = header .. 'local loadstring = function(c, cn) local w = (V and V.SolaraBypassEnabled and buildVirtualExecutionChunk and buildVirtualExecutionChunk(c)) or c; return __orig_loadstring(w, cn) end\n'

    return header .. cleanedCode
end

function executeCodeWithSandbox(codeToRun)
    if not codeToRun or codeToRun == "" or codeToRun:match("^%s*$") then
        notify("Code", "Aucun code a executer !", Color3.fromRGB(255, 165, 0))
        return false, "No code"
    end

    local startTime = tick()
    local finalChunk = codeToRun
    if V.SolaraBypassEnabled ~= false then
        finalChunk = buildVirtualExecutionChunk(codeToRun)
    end

    if V.LuaTurboBooster then
        pcall(function()
            collectgarbage("setpause", 90)
            collectgarbage("setstepmul", 250)
        end)
    end

    local func, err = loadstring(finalChunk)
    if not func then
        notify("Code", "Erreur Syntaxe : " .. tostring(err):sub(1, 60), Color3.fromRGB(255, 90, 90))
        return false, tostring(err)
    end

    local success, runtimeErr = true, nil
    if V.AntiCrashSandbox then
        success, runtimeErr = pcall(func)
    else
        func()
    end
    local elapsed = math.floor((tick() - startTime) * 1000)

    if success then
        notify("Code", "Execute avec succes (" .. tostring(elapsed) .. " ms) !", Color3.fromRGB(80, 200, 120))
        return true, "Succes (" .. tostring(elapsed) .. " ms)"
    else
        notify("Code", "Erreur Runtime : " .. tostring(runtimeErr):sub(1, 60), Color3.fromRGB(255, 90, 90))
        return false, tostring(runtimeErr)
    end
end

initStep = "cablage Code"
createLabel("EXECUTEUR VIRTUEL INDEPENDANT (2026)", CodeContent)
do
    local CodeBox = Instance.new("TextBox")
    CodeBox.Size = UDim2.new(1, 0, 0, 190)
    CodeBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    CodeBox.BorderSizePixel = 0
    CodeBox.Text = ""
    CodeBox.PlaceholderText = "Colle ton script ici (Moteur Virtuel 100% UNC - Bypass Solara integre)..."
    CodeBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
    CodeBox.TextColor3 = Color3.fromRGB(210, 210, 222)
    CodeBox.Font = Enum.Font.Code
    CodeBox.TextSize = 13
    CodeBox.TextWrapped = true
    CodeBox.MultiLine = true
    CodeBox.TextXAlignment = Enum.TextXAlignment.Left
    CodeBox.TextYAlignment = Enum.TextYAlignment.Top
    CodeBox.Parent = CodeContent
    makeCorner(CodeBox, 8)

    local CodeBoxPadding = Instance.new("UIPadding")
    CodeBoxPadding.PaddingLeft = UDim.new(0, 8)
    CodeBoxPadding.PaddingRight = UDim.new(0, 8)
    CodeBoxPadding.PaddingTop = UDim.new(0, 8)
    CodeBoxPadding.PaddingBottom = UDim.new(0, 8)
    CodeBoxPadding.Parent = CodeBox

    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Size = UDim2.new(1, 0, 0, 36)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = CodeContent

    local ButtonLayout = Instance.new("UIListLayout")
    ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
    ButtonLayout.Padding = UDim.new(0, 6)
    ButtonLayout.Parent = ButtonContainer

    local ExecBtn = Instance.new("TextButton")
    ExecBtn.Size = UDim2.new(0.4, -4, 1, 0)
    ExecBtn.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    ExecBtn.BorderSizePixel = 0
    ExecBtn.Text = "Executer (Moteur Virtuel)"
    ExecBtn.TextColor3 = Color3.fromRGB(180, 155, 255)
    ExecBtn.Font = Enum.Font.GothamBold
    ExecBtn.TextSize = 12
    ExecBtn.Parent = ButtonContainer
    makeCorner(ExecBtn, 8)
    makeStroke(ExecBtn, Color3.fromRGB(145, 120, 255), 1)

    local ClipBtn = Instance.new("TextButton")
    ClipBtn.Size = UDim2.new(0.35, -4, 1, 0)
    ClipBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    ClipBtn.BorderSizePixel = 0
    ClipBtn.Text = "Exec Clipboard"
    ClipBtn.TextColor3 = Color3.fromRGB(195, 195, 208)
    ClipBtn.Font = Enum.Font.GothamMedium
    ClipBtn.TextSize = 12
    ClipBtn.Parent = ButtonContainer
    makeCorner(ClipBtn, 8)
    makeStroke(ClipBtn, Color3.fromRGB(50, 50, 60), 0.8)

    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(0.25, -4, 1, 0)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(40, 22, 22)
    ClearBtn.BorderSizePixel = 0
    ClearBtn.Text = "Effacer"
    ClearBtn.TextColor3 = Color3.fromRGB(210, 120, 120)
    ClearBtn.Font = Enum.Font.GothamMedium
    ClearBtn.TextSize = 12
    ClearBtn.Parent = ButtonContainer
    makeCorner(ClearBtn, 8)
    makeStroke(ClearBtn, Color3.fromRGB(80, 40, 40), 0.8)

    local StatusCard = createCard(CodeContent, 0, 32)
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, -16, 1, 0)
    StatusText.Position = UDim2.new(0, 10, 0, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Statut : Pret | Moteur Virtuel Actif (" .. tostring(V.SpoofedExecutorName or "Matcha") .. " 100% UNC)"
    StatusText.TextColor3 = Color3.fromRGB(145, 120, 255)
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.TextSize = 11
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Parent = StatusCard

    ExecBtn.MouseButton1Click:Connect(function()
        playClick()
        local code = CodeBox.Text
        local ok, msg = executeCodeWithSandbox(code)
        if ok then
            StatusText.Text = "Statut : " .. msg
            StatusText.TextColor3 = Color3.fromRGB(80, 200, 120)
        else
            StatusText.Text = "Statut : " .. msg:sub(1, 60)
            StatusText.TextColor3 = Color3.fromRGB(255, 90, 90)
        end
    end)

    ClipBtn.MouseButton1Click:Connect(function()
        playClick()
        local clip = ""
        pcall(function()
            if getclipboard then clip = getclipboard()
            elseif syn and syn.getclipboard then clip = syn.getclipboard() end
        end)
        if clip == "" then
            clip = CodeBox.Text
        else
            CodeBox.Text = clip
        end
        local ok, msg = executeCodeWithSandbox(clip)
        if ok then
            StatusText.Text = "Clipboard : " .. msg
            StatusText.TextColor3 = Color3.fromRGB(80, 200, 120)
        else
            StatusText.Text = "Clipboard : " .. msg:sub(1, 60)
            StatusText.TextColor3 = Color3.fromRGB(255, 90, 90)
        end
    end)

    ClearBtn.MouseButton1Click:Connect(function()
        playClick()
        CodeBox.Text = ""
        StatusText.Text = "Statut : Editeur vide"
        StatusText.TextColor3 = Color3.fromRGB(180, 180, 195)
        notify("Code", "Texte efface.", Color3.fromRGB(180, 180, 195))
    end)
end

createLabel("SPOOF EXECUTOR 2026 & MOTEUR VIRTUEL", CodeContent)

createToggle("Moteur Virtuel External (Bypass Solara 100% UNC)", true, function(enabled)
    V.SolaraBypassEnabled = enabled
    if enabled then applyGlobalSolaraBypass() end
    notify("Moteur", "Moteur Virtuel External " .. (enabled and "ACTIVE" or "DESACTIVE"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, CodeContent, "SolaraBypassEnabled")

do
    local executorsList = {"Real", "Matcha", "Wave", "Madium"}
    local curIdx = 2
    createValueButton(CodeContent, "Spoofed Executor (Identite 2026)", V.SpoofedExecutorName or "Matcha", function()
        local found = table.find(executorsList, V.SpoofedExecutorName)
        if found then curIdx = found end
        curIdx = (curIdx % #executorsList) + 1
        V.SpoofedExecutorName = executorsList[curIdx]
        applyGlobalSolaraBypass()
        notify("Moteur", "Identite simulee : " .. V.SpoofedExecutorName, Color3.fromRGB(145, 120, 255))
        return V.SpoofedExecutorName
    end, "SpoofedExecutorName")
end

createLabel("SCRIPT BOOSTER & EXTERNAL ENGINE", CodeContent)

createToggle("Anti-Crash & Safe Sandbox", true, function(enabled)
    V.AntiCrashSandbox = enabled
    notify("Booster", "Sandbox Anti-Crash " .. (enabled and "ACTIVEE" or "DESACTIVEE"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, CodeContent, "AntiCrashSandbox")

createToggle("Virtual Security Identity (Level 8 Context)", true, function(enabled)
    V.VirtualSecurityIdentity = enabled
    notify("Booster", "Security Context Level 8 " .. (enabled and "ACTIVE" or "DESACTIVE"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, CodeContent, "VirtualSecurityIdentity")

createToggle("Auto-Bypass Incompatibilites (Source Sanitizer)", true, function(enabled)
    V.AutoBypassFilters = enabled
    notify("Booster", "Auto-Bypass Sanitizer " .. (enabled and "ACTIVE" or "DESACTIVE"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, CodeContent, "AutoBypassFilters")

createToggle("Bloqueur Telemetrie & Logs Externes", true, function(enabled)
    V.AntiTelemetryEnabled = enabled
    notify("Booster", "Anti-Telemetrie " .. (enabled and "ACTIVE" or "DESACTIVE"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, CodeContent, "AntiTelemetryEnabled")

createToggle("Lua Turbo Booster (Anti-Lag GC)", true, function(enabled)
    V.LuaTurboBooster = enabled
    if enabled then
        pcall(function()
            collectgarbage("setpause", 90)
            collectgarbage("setstepmul", 250)
        end)
    end
    notify("Booster", "Lua Turbo Booster " .. (enabled and "ACTIVE" or "DESACTIVE"), enabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 90, 90))
end, CodeContent, "LuaTurboBooster")

createLabel("SCRIPT HUB RAPIDE (1-CLIC MOTEUR VIRTUEL)", CodeContent)

createButton("Lancer Infinite Yield", function()
    notify("Hub", "Chargement d Infinite Yield...", Color3.fromRGB(145, 120, 255))
    task.spawn(function()
        pcall(function()
            local rawCode = game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
            local ok, err = executeCodeWithSandbox(rawCode)
            if ok then
                notify("Hub", "Infinite Yield charge !", Color3.fromRGB(80, 200, 120))
            else
                notify("Hub", "Erreur IY : " .. tostring(err):sub(1, 40), Color3.fromRGB(255, 90, 90))
            end
        end)
    end)
end, CodeContent, "Lancer")

createButton("Lancer Dark Dex V3 (Explorer)", function()
    notify("Hub", "Chargement de Dark Dex V3...", Color3.fromRGB(145, 120, 255))
    task.spawn(function()
        pcall(function()
            local rawCode = game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua")
            local ok, err = executeCodeWithSandbox(rawCode)
            if ok then
                notify("Hub", "Dark Dex V3 charge !", Color3.fromRGB(80, 200, 120))
            else
                notify("Hub", "Erreur Dex : " .. tostring(err):sub(1, 40), Color3.fromRGB(255, 90, 90))
            end
        end)
    end)
end, CodeContent, "Lancer")

createButton("Lancer SimpleSpy V3 (Remote Spy)", function()
    notify("Hub", "Chargement de SimpleSpy V3...", Color3.fromRGB(145, 120, 255))
    task.spawn(function()
        pcall(function()
            local rawCode = game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua")
            local ok, err = executeCodeWithSandbox(rawCode)
            if ok then
                notify("Hub", "SimpleSpy V3 charge !", Color3.fromRGB(80, 200, 120))
            else
                notify("Hub", "Erreur SimpleSpy : " .. tostring(err):sub(1, 40), Color3.fromRGB(255, 90, 90))
            end
        end)
    end)
end, CodeContent, "Lancer")


if V.UnifiedInputConn then V.UnifiedInputConn:Disconnect() end
V.UnifiedInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if KeybindSystem.Binding then
            local newKey = input.KeyCode
            local alreadyUsed = false
            for kName, kVal in pairs(Keybinds) do
                if kName ~= KeybindSystem.BindingName and kVal == newKey then
                    alreadyUsed = true
                    break
                end
            end

            if alreadyUsed then
                if KeybindSystem.BindingBtn and Keybinds[KeybindSystem.BindingName] then
                    KeybindSystem.BindingBtn.Text = Keybinds[KeybindSystem.BindingName].Name
                    KeybindSystem.BindingBtn.BackgroundColor3 = theme.cardHover
                    KeybindSystem.BindingBtn.TextColor3 = theme.accent
                    local s = KeybindSystem.BindingBtn:FindFirstChildOfClass("UIStroke")
                    if s then s.Color = theme.border end
                end
                notify("Settings","Key already used by another bind!", Color3.fromRGB(255, 90, 90))
            else
                Keybinds[KeybindSystem.BindingName] = newKey
                if KeybindSystem.BindingBtn then
                    KeybindSystem.BindingBtn.Text = newKey.Name
                    KeybindSystem.BindingBtn.BackgroundColor3 = theme.cardHover
                    KeybindSystem.BindingBtn.TextColor3 = theme.accent
                    local s = KeybindSystem.BindingBtn:FindFirstChildOfClass("UIStroke")
                    if s then s.Color = theme.border end
                end
                notify("Settings", KeybindSystem.BindingName .." set to ".. newKey.Name, Color3.fromRGB(80, 200, 120))
            end
            KeybindSystem.Binding = false
            KeybindSystem.BindingName = nil
            KeybindSystem.BindingBtn = nil
            return
        end

        local isMenuKey = (Keybinds and Keybinds.Menu and input.KeyCode == Keybinds.Menu) or (input.KeyCode == Enum.KeyCode.Insert)
        if isMenuKey then
            pcall(function() game:GetService("GuiService").SelectedObject = nil end)
            if not UserInputService:GetFocusedTextBox() then
                if toggleMenu then
                    toggleMenu()
                elseif _G.toggleNebulaMenu then
                    _G.toggleNebulaMenu()
                elseif Panel then
                    Panel.Visible = not Panel.Visible
                elseif BloxFruitsPanel then
                    BloxFruitsPanel.Visible = not BloxFruitsPanel.Visible
                end
            end
            return
        end

        if not gameProcessed then
            pcall(function() game:GetService("GuiService").SelectedObject = nil end)

            for name, key in pairs(Keybinds) do
                if name ~= "Menu" and input.KeyCode == key and KeybindCallbacks[name] then
                    local success, err = pcall(KeybindCallbacks[name])
                    if not success then
                        warn("Erreur Keybind ".. name ..": ".. tostring(err))
                    end
                    return
                end
            end
        end
    end
end)
addConnection(V.UnifiedInputConn)

if BloxFruitsPanel then BloxFruitsPanel.Visible = true end
notify("Nebula V2.0","Script loaded successfully!", Color3.fromRGB(80, 200, 120))

InspectorGui = nil
function openPlayerInspector(targetPlayer)
    if not targetPlayer then return end
    if InspectorGui then InspectorGui:Destroy() end

InspectorGui = Instance.new("ScreenGui")
InspectorGui.Name ="NebulaPlayerInspector"
InspectorGui.ResetOnSpawn = false
InspectorGui.DisplayOrder = 100
InspectorGui.Parent = parentTarget

    local CardFrame = Instance.new("Frame")
    CardFrame.Size = UDim2.new(0, 310, 0, 450)
    CardFrame.Position = UDim2.new(0.5, -155, 0.52, -225)
    CardFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    CardFrame.BackgroundTransparency = 1
    CardFrame.BorderSizePixel = 0
    CardFrame.Active = true
    CardFrame.Draggable = true
    CardFrame.Parent = InspectorGui

    local CardCorner = Instance.new("UICorner", CardFrame)
    CardCorner.CornerRadius = UDim.new(0, 14)

    local CardStroke = Instance.new("UIStroke", CardFrame)
    CardStroke.Color = V.AccentColor or Color3.fromRGB(60, 160, 255)
    CardStroke.Thickness = 1.5
    CardStroke.Transparency = 0.25

    TweenService:Create(CardFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 480),
        Position = UDim2.new(0.5, -170, 0.5, -240),
        BackgroundTransparency = 0.05
    }):Play()

    local TopBanner = Instance.new("Frame")
    TopBanner.Size = UDim2.new(1, 0, 0, 75)
    TopBanner.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    TopBanner.BorderSizePixel = 0
    TopBanner.Parent = CardFrame
    local tbc = Instance.new("UICorner", TopBanner)
    tbc.CornerRadius = UDim.new(0, 14)

    local BannerGradient = Instance.new("UIGradient", TopBanner)
    BannerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 24))
    })

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -34, 0, 10)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 30)
    CloseBtn.Text =""
    CloseBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = CardFrame
    local cbc = Instance.new("UICorner", CloseBtn)
    cbc.CornerRadius = UDim.new(0, 8)

    local function closeInspector()
        local tweenOut = TweenService:Create(CardFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 300, 0, 430),
            Position = UDim2.new(0.5, -150, 0.52, -215),
            BackgroundTransparency = 1
        })
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            InspectorGui:Destroy()
        end)
    end
    CloseBtn.MouseButton1Click:Connect(closeInspector)

    local AvatarImg = Instance.new("ImageLabel")
    AvatarImg.Size = UDim2.new(0, 56, 0, 56)
    AvatarImg.Position = UDim2.new(0, 16, 0, 10)
    AvatarImg.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    AvatarImg.BorderSizePixel = 0
    AvatarImg.Image ="rbxthumb://type=AvatarHeadShot&id=".. targetPlayer.UserId .."&w=150&h=150"
    AvatarImg.Parent = CardFrame
    local aic = Instance.new("UICorner", AvatarImg)
    aic.CornerRadius = UDim.new(1, 0)
    local ais = Instance.new("UIStroke", AvatarImg)
    ais.Color = V.AccentColor or Color3.fromRGB(60, 160, 255)
    ais.Thickness = 2

    local DisplayLabel = Instance.new("TextLabel")
    DisplayLabel.Size = UDim2.new(1, -125, 0, 20)
    DisplayLabel.Position = UDim2.new(0, 82, 0, 14)
    DisplayLabel.BackgroundTransparency = 1
    DisplayLabel.Text = targetPlayer.DisplayName
    DisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DisplayLabel.Font = Enum.Font.GothamBold
    DisplayLabel.TextSize = 14
    DisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DisplayLabel.Parent = CardFrame

    local UserLabel = Instance.new("TextLabel")
    UserLabel.Size = UDim2.new(1, -125, 0, 16)
    UserLabel.Position = UDim2.new(0, 82, 0, 34)
    UserLabel.BackgroundTransparency = 1
    UserLabel.Text ="@".. targetPlayer.Name
    UserLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
    UserLabel.Font = Enum.Font.GothamMedium
    UserLabel.TextSize = 11
    UserLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserLabel.Parent = CardFrame

    local function detectPlatform()
        if targetPlayer == LocalPlayer then
            if GuiService:IsTenFootInterface() or UserInputService.GamepadEnabled then
                return "Console (PlayStation/Xbox)"
            elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
                return "Mobile (iOS/Android)"
            elseif UserInputService.KeyboardEnabled or UserInputService.MouseEnabled then
                return "PC / Mac (Keyboard & Mouse)"
            end
        end

        local pg = targetPlayer:FindFirstChild("PlayerGui")
        if pg then
            if pg:FindFirstChild("TouchGui") or pg:FindFirstChild("TouchCameraControlFrame") or pg:FindFirstChild("MobileGui") or pg:FindFirstChild("TouchControls") then
                return "Mobile (iOS/Android)"
            end
            if pg:FindFirstChild("ConsoleGui") or pg:FindFirstChild("GamepadGui") or pg:FindFirstChild("XboxGui") or pg:FindFirstChild("PSGui") then
                return "Console (PlayStation/Xbox)"
            end
        end

        local char = targetPlayer.Character
        if char then
            if char:FindFirstChild("VRCharacter") or char:FindFirstChild("Left Hand") or char:FindFirstChild("LeftHandVR") then
                return "VR Headset"
            end
            for _, obj in pairs(char:GetChildren()) do
                local n = obj.Name:lower()
                if n:find("touch") or n:find("mobile") then return "Mobile (iOS/Android)"
                elseif n:find("console") or n:find("gamepad") or n:find("controller") then return "Console (Xbox/PS)"
                end
            end
        end

        local devAttr = targetPlayer:GetAttribute("Device") or targetPlayer:GetAttribute("Platform")
        if devAttr then return tostring(devAttr) end

        return "PC / Mac (Keyboard & Mouse)"
    end

    local PlatformBadge = Instance.new("TextLabel")
    PlatformBadge.Size = UDim2.new(0, 185, 0, 18)
    PlatformBadge.Position = UDim2.new(0, 82, 0, 52)
    PlatformBadge.BackgroundColor3 = Color3.fromRGB(28, 42, 65)
    PlatformBadge.Text = detectPlatform()
    PlatformBadge.TextColor3 = Color3.fromRGB(100, 200, 255)
    PlatformBadge.Font = Enum.Font.GothamBold
    PlatformBadge.TextSize = 9
    PlatformBadge.BorderSizePixel = 0
    PlatformBadge.Parent = CardFrame
    local pbc = Instance.new("UICorner", PlatformBadge)
    pbc.CornerRadius = UDim.new(0, 4)

    local InfoContainer = Instance.new("Frame")
    InfoContainer.Size = UDim2.new(1, -32, 0, 245)
    InfoContainer.Position = UDim2.new(0, 16, 0, 90)
    InfoContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    InfoContainer.BorderSizePixel = 0
    InfoContainer.Parent = CardFrame
    local icc = Instance.new("UICorner", InfoContainer)
    icc.CornerRadius = UDim.new(0, 10)

    local InfoList = Instance.new("UIListLayout", InfoContainer)
    InfoList.Padding = UDim.new(0, 5)

    local InfoPadding = Instance.new("UIPadding", InfoContainer)
    InfoPadding.PaddingTop = UDim.new(0, 8)
    InfoPadding.PaddingLeft = UDim.new(0, 10)
    InfoPadding.PaddingRight = UDim.new(0, 10)

    local valueLabels = {}
    local function addInfoRow(key, title, defaultValue)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundTransparency = 1
        row.Parent = InfoContainer

        local tLbl = Instance.new("TextLabel")
        tLbl.Size = UDim2.new(0.45, 0, 1, 0)
        tLbl.BackgroundTransparency = 1
        tLbl.Text = title
        tLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
        tLbl.Font = Enum.Font.GothamMedium
        tLbl.TextSize = 11
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Parent = row

        local vLbl = Instance.new("TextLabel")
        vLbl.Size = UDim2.new(0.55, 0, 1, 0)
        vLbl.Position = UDim2.new(0.45, 0, 0, 0)
        vLbl.BackgroundTransparency = 1
        vLbl.Text = tostring(defaultValue)
        vLbl.TextColor3 = Color3.fromRGB(230, 230, 245)
        vLbl.Font = Enum.Font.GothamBold
        vLbl.TextSize = 11
        vLbl.TextXAlignment = Enum.TextXAlignment.Right
        vLbl.Parent = row

        valueLabels[key] = vLbl
    end

    local rankInGroup = pcall(function() return targetPlayer:GetRankInGroup(game.CreatorId) end) and targetPlayer:GetRankInGroup(game.CreatorId) or"N/A"

    addInfoRow("UserId","ID Utilisateur:", targetPlayer.UserId)
        addInfoRow("AccountAge", "Âge du Compte:", targetPlayer.AccountAge .. " jours")
        addInfoRow("Health", "Santé (Health):", "Chargement...")
    addInfoRow("Speed","Vitesse (WalkSpeed):","Chargement...")
    addInfoRow("Distance","Distance:","Chargement...")
    addInfoRow("Tool","Objet en main:","Chargement...")
        addInfoRow("Team", "Équipe (Team):", targetPlayer.Team and targetPlayer.Team.Name or "Aucune")
        addInfoRow("Rank", "Rang Créateur:", rankInGroup)
        addInfoRow("Fruit", "Fruit Blox:", "Chargement...")

    local HealthBarBg = Instance.new("Frame")
    HealthBarBg.Size = UDim2.new(1, 0, 0, 6)
    HealthBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    HealthBarBg.BorderSizePixel = 0
    HealthBarBg.Parent = InfoContainer
    local hbgc = Instance.new("UICorner", HealthBarBg)
    hbgc.CornerRadius = UDim.new(1, 0)

    local HealthBarFill = Instance.new("Frame")
    HealthBarFill.Size = UDim2.new(1, 0, 1, 0)
    HealthBarFill.BackgroundColor3 = Color3.fromRGB(0, 230, 120)
    HealthBarFill.BorderSizePixel = 0
    HealthBarFill.Parent = HealthBarBg
    local hfc = Instance.new("UICorner", HealthBarFill)
    hfc.CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        while CardFrame.Parent and targetPlayer and targetPlayer.Parent do
            pcall(function()
                local char = targetPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist = (hrp and localHrp) and math.floor((localHrp.Position - hrp.Position).Magnitude) or"?"
                local tool = char and char:FindFirstChildOfClass("Tool")

                if hum then
                    local hp = math.floor(hum.Health)
                    local maxHp = math.floor(hum.MaxHealth)
                    valueLabels["Health"].Text = hp .."/".. maxHp
                    local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    TweenService:Create(HealthBarFill, TweenInfo.new(0.2), {
                        Size = UDim2.new(pct, 0, 1, 0),
                        BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - pct)), math.floor(255 * pct), 80)
                    }):Play()
                    valueLabels["Speed"].Text = math.floor(hum.WalkSpeed) .."studs/s"
                else
                    valueLabels["Health"].Text ="Mort / Inc"
                    valueLabels["Speed"].Text ="N/A"
                    HealthBarFill.Size = UDim2.new(0, 0, 1, 0)
                end

                valueLabels["Distance"].Text = dist .."m"
                valueLabels["Tool"].Text = tool and ("[".. tool.Name .."]") or"Aucun"
                valueLabels["Team"].Text = targetPlayer.Team and targetPlayer.Team.Name or"Aucune"
                if _G.getPlayerBloxFruit and valueLabels["Fruit"] then
                    local fName, fPerm = _G.getPlayerBloxFruit(targetPlayer)
                    if fName and fName ~= "Aucun" then
                        valueLabels["Fruit"].Text = fName .. (fPerm and " [PERM]" or " [Physique]")
                        valueLabels["Fruit"].TextColor3 = fPerm and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(175, 110, 255)
                    else
                        valueLabels["Fruit"].Text = "Aucun"
                        valueLabels["Fruit"].TextColor3 = Color3.fromRGB(150, 150, 160)
                    end
                end
            end)
            task.wait(0.1)
        end
    end)

    local ActionsContainer = Instance.new("Frame")
    ActionsContainer.Size = UDim2.new(1, -32, 0, 120)
    ActionsContainer.Position = UDim2.new(0, 16, 0, 345)
    ActionsContainer.BackgroundTransparency = 1
    ActionsContainer.Parent = CardFrame

    local ActionGrid = Instance.new("UIGridLayout", ActionsContainer)
    ActionGrid.CellSize = UDim2.new(0, 95, 0, 32)
    ActionGrid.CellPadding = UDim2.new(0, 8, 0, 8)

    local function createActionButton(initialText, defaultCol, activeCol, isActiveFunc, onClick)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = defaultCol
        btn.Text = initialText
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        btn.Parent = ActionsContainer

        local bc = Instance.new("UICorner", btn)
        bc.CornerRadius = UDim.new(0, 8)

        local bs = Instance.new("UIStroke", btn)
        bs.Color = Color3.fromRGB(255, 255, 255)
        bs.Transparency = 0.85
        bs.Thickness = 1

        local function updateButtonVisual()
            local isActive = isActiveFunc and isActiveFunc()
            local targetColor = isActive and activeCol or defaultCol
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        end

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 97, 0, 34)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 95, 0, 32)}):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            onClick(btn, updateButtonVisual)
            updateButtonVisual()
        end)

        updateButtonVisual()
        return btn
    end

    createActionButton("Teleport", Color3.fromRGB(30, 80, 150), Color3.fromRGB(50, 140, 250), nil, function(btn)
        if _G.teleportToPlayer then
            _G.teleportToPlayer(targetPlayer)
        elseif teleportToPlayer then
            teleportToPlayer(targetPlayer)
        end
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(80, 200, 120)}):Play()
        task.delay(0.3, function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 80, 150)}):Play() end)
    end)

    createActionButton("Spectate", Color3.fromRGB(30, 100, 75), Color3.fromRGB(220, 60, 60), function()
        return V.Spectate and V.SelPlayer == targetPlayer
    end, function(btn, refresh)
        if V.Spectate and V.SelPlayer == targetPlayer then
            stopSpectate()
            btn.Text ="Spectate"
        else
            if V.Spectate then stopSpectate() end
            startSpectate(targetPlayer)
            btn.Text ="Stop Spec"
        end
    end)

    createActionButton("Fling", Color3.fromRGB(150, 40, 40), Color3.fromRGB(240, 70, 70), function()
        return V.Flinging and V.FlingTarget == targetPlayer
    end, function(btn, refresh)
        if V.Flinging and V.FlingTarget == targetPlayer then
            stopFling()
            btn.Text ="Fling"
        else
            if V.Flinging then stopFling() end
            startFling(targetPlayer)
            btn.Text ="Stop Fling"
        end
    end)

    createActionButton("Attach", Color3.fromRGB(110, 50, 150), Color3.fromRGB(220, 60, 60), function()
        return V.Attached == targetPlayer
    end, function(btn, refresh)
        if _G.toggleAttach then
            _G.toggleAttach(targetPlayer)
        elseif V.Attached == targetPlayer then
            if _G.stopAttach then _G.stopAttach() elseif stopAttach then stopAttach() end
        else
            if _G.startAttach then _G.startAttach(targetPlayer) elseif startAttach then startAttach(targetPlayer) end
        end
        local isAtt = (V.Attached == targetPlayer)
        btn.Text = isAtt and "Detach" or "Attach"
        if refresh then refresh() end
    end)

    
    createActionButton("Copier ID", Color3.fromRGB(45, 45, 60), Color3.fromRGB(45, 45, 60), nil, function(btn)
        if setclipboard then
            setclipboard(tostring(targetPlayer.UserId))
            notify("Inspector","ID Utilisateur copié !", Color3.fromRGB(80, 200, 120))
        else
            notify("Inspector","Presse-papier non supporté", Color3.fromRGB(255, 90, 90))
        end
    end)

    createActionButton("Copier Outfit", Color3.fromRGB(130, 50, 160), Color3.fromRGB(130, 50, 160), nil, function(btn)
        pcall(function()
            local myChar = LocalPlayer.Character
            local tChar = targetPlayer.Character
            if not myChar or not tChar then return end

            for _, item in pairs(myChar:GetChildren()) do
                if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("CharacterMesh") then
                    item:Destroy()
                end
            end

            for _, item in pairs(tChar:GetChildren()) do
                if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("CharacterMesh") then
                    item:Clone().Parent = myChar
                end
            end

            local tHead = tChar:FindFirstChild("Head")
            local myHead = myChar:FindFirstChild("Head")
            if tHead and myHead then
                local tFace = tHead:FindFirstChildOfClass("Decal")
                local myFace = myHead:FindFirstChildOfClass("Decal")
                if tFace then
                    if myFace then myFace.Texture = tFace.Texture
                    else
                        local newFace = tFace:Clone()
                        newFace.Parent = myHead
                    end
                end
            end

            notify("Cosmetics","Tenue de ".. targetPlayer.Name .. " copiée !", Color3.fromRGB(80, 200, 120))
        end)
    end)

    createActionButton("Warp to Car", Color3.fromRGB(40, 110, 140), Color3.fromRGB(60, 160, 200), nil, function(btn)
        if _G.warpToPlayerCar then
            _G.warpToPlayerCar(targetPlayer)
        end
    end)
end

if V.InspectorClickConn then V.InspectorClickConn:Disconnect() end
V.InspectorClickConn = UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    if input.UserInputState ~= Enum.UserInputState.Begin then return end
    if not V.RightClickInspect then return end
    pcall(function()
        local mouseLoc = UserInputService:GetMouseLocation()
        local unitRay = Camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        if LocalPlayer.Character then
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        end
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model then
                local targetPlayer = Players:GetPlayerFromCharacter(model)
                if targetPlayer and targetPlayer ~= LocalPlayer then
                    openPlayerInspector(targetPlayer)
                end
            end
        end
    end)
end)

Players.PlayerAdded:Connect(function(p)
    if V.PlayerJoinLeaveNotifs then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title ="Joueur Rejoint",
            Text = p.DisplayName .."(@".. p.Name ..") a rejoint la partie.",
            Duration = 6,
            Icon ="rbxthumb://type=AvatarHeadShot&id=".. p.UserId .."&w=150&h=150"
        })
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if V.PlayerJoinLeaveNotifs then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title ="Joueur Quitté",
            Text = p.DisplayName .."(@".. p.Name ..") a quitté la partie.",
            Duration = 6,
            Icon ="rbxthumb://type=AvatarHeadShot&id=".. p.UserId .."&w=150&h=150"
        })
    end
end)


task.spawn(function()
    task.wait(1)
    pcall(function()
        if sendCheatLoadedWebhook then
            sendCheatLoadedWebhook()
        end
    end)
end)
