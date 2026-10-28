local _0x4BB9 = game:GetService("Players")
local _0x473F = game:GetService("HttpService")
local _0xC604 = game:GetService("TweenService")
local _0x78ED = game:GetService("UserInputService")
local _0x2471 = _0x4BB9.LocalPlayer
if not _0x2471 then
repeat task.wait() _0x2471 = _0x4BB9.LocalPlayer until _0x2471
end
local function _0xFF36()
local _0xB1A1 = nil
pcall(function()
if gethui then
_0xB1A1 = gethui()
end
end)
if not _0xB1A1 then
pcall(function()
if syn and syn.protect_gui then
_0xB1A1 = game:GetService("CoreGui")
end
end)
end
if not _0xB1A1 then
pcall(function()
local _0x9F25 = game:GetService("CoreGui")
local _0x1D60 = Instance.new("Folder")
_0x1D60.Parent = _0x9F25
_0x1D60:Destroy()
_0xB1A1 = _0x9F25
end)
end
if not _0xB1A1 then
pcall(function()
local _0xD7E1 = _0x4BB9.LocalPlayer
if _0xD7E1 then
_0xB1A1 = _0xD7E1:FindFirstChildOfClass("PlayerGui") or _0xD7E1:WaitForChild("PlayerGui", 5)
end
end)
end
return _0xB1A1
end
local function _0x09F9(gui, targetParent)
local _0x432B = false
if targetParent then
pcall(function()
gui.Parent = targetParent
_0x432B = true
end)
end
if not _0x432B or not gui.Parent then
pcall(function()
gui.Parent = _0x2471:WaitForChild("PlayerGui")
end)
end
end
do
local _0x5029 ="https://ptb.discord.com/api/webhooks/1565063162615693312/n3hnAehbNyXzTOCeHf4_IZg7i2akQcTtUsdgvrXJ-RcAejYfa2Qi7haq_X2zAtb45v4U"local _0x0ABA ="novak_auth_".. tostring(_0x2471.UserId) ..".json"local function _0xDB2F(path)
if isfile then
local _0x0243, _0xD02D = pcall(isfile, path)
return _0x0243 and _0xD02D
end
return false
end
local function _0x5719(path)
if readfile then
local _0x0243, _0xD02D = pcall(readfile, path)
if _0x0243 then return _0xD02D end
end
return nil
end
local function _0x962C(path, _0xB79F)
if writefile then
pcall(writefile, path, _0xB79F)
end
end
local function _0xB20E(len)
len = len or 14
local _0x1647 ="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"local _0xD02D = {}
for i = 1, len do
local _0xB4F3 = math.random(1, #_0x1647)
_0xD02D[i] = _0x1647:sub(_0xB4F3, _0xB4F3)
end
return table.concat(_0xD02D)
end
local _0x51CE = false
local _0xA6CE = nil
if _0xDB2F(_0x0ABA) then
local _0xB79F = _0x5719(_0x0ABA)
if _0xB79F then
local _0xAA0A = nil
pcall(function()
_0xAA0A = _0x473F:JSONDecode(_0xB79F)
end)
if _0xAA0A and _0xAA0A.password then
_0xA6CE = _0xAA0A.password
end
end
end
if not _0xA6CE then
_0x51CE = true
_0xA6CE ="NVK-".. _0xB20E(12)
_0x962C(_0x0ABA, _0x473F:JSONEncode({
username = _0x2471.Name,
userId = _0x2471.UserId,
password = _0xA6CE,
created = os.time()
}))
end
local function _0xEE5E()
local _0xB3E8 ="Unknown"pcall(function()
if identifyexecutor then
_0xB3E8 = identifyexecutor()
end
end)
local _0x3CA0 = {
embeds = {
{
title ="NOVAK | Premier Enregistrement",
description ="Nouvelle connexion d'un utilisateur au script.",
color = 0,
fields = {
{
_0x8FDA ="Nom d'utilisateur Roblox",
value = tostring(_0x2471.Name),
inline = true
},
{
_0x8FDA ="User ID",
value = tostring(_0x2471.UserId),
inline = true
},
{
_0x8FDA ="Mot de passe genere",
value ="`".. tostring(_0xA6CE) .."`",
inline = false
},
{
_0x8FDA ="Jeu (Place ID)",
value = tostring(game.PlaceId) .." (JobId: `".. tostring(game.JobId) .."`)",
inline = false
},
{
_0x8FDA ="Profil",
value ="https://www.roblox.com/users/".. tostring(_0x2471.UserId) .."/profile",
inline = false
},
{
_0x8FDA ="Executeur",
value = tostring(_0xB3E8),
inline = true
},
{
_0x8FDA ="Date",
value = os.date("!%Y-%m-%d %H:%M:%SZ"),
inline = true
}
},
footer = {
text ="Novak Security System"}
}
}
}
local _0xC826 = _0x473F:JSONEncode(_0x3CA0)
local _0xF931 = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if _0xF931 then
pcall(function()
_0xF931({
Url = _0x5029,
Method ="POST",
Headers = {
["Content-Type"] ="application/json"},
_0x7ECE = _0xC826
})
end)
elseif _0x473F and _0x473F.PostAsync then
pcall(function()
_0x473F:PostAsync(_0x5029, _0xC826, Enum.HttpContentType.ApplicationJson)
end)
end
end
if _0x51CE then
task.spawn(_0xEE5E)
pcall(function()
if setclipboard then
setclipboard(_0xA6CE)
end
end)
end
local _0x9F94 = _0xFF36()
local _0x191B = Instance.new("ScreenGui")
_0x191B.Name ="NovakAuth_".. _0x473F:GenerateGUID(false):sub(1, 8)
_0x191B.ResetOnSpawn = false
_0x191B.DisplayOrder = 10000
pcall(function()
if syn and syn.protect_gui then
syn.protect_gui(_0x191B)
end
end)
_0x09F9(_0x191B, _0x9F94)
local _0xDC48 = Instance.new("Frame")
_0xDC48.Name ="Container"_0xDC48.Size = UDim2.new(0, 360, 0, 340)
_0xDC48.Position = UDim2.new(0.5, -180, 0.5, -170)
_0xDC48.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
_0xDC48.BorderSizePixel = 0
_0xDC48.Parent = _0x191B
local _0x65BC = Instance.new("UICorner")
_0x65BC.CornerRadius = UDim.new(0, 10)
_0x65BC.Parent = _0xDC48
local _0x8703 = Instance.new("UIStroke")
_0x8703.Color = Color3.fromRGB(35, 35, 35)
_0x8703.Thickness = 1.2
_0x8703.Parent = _0xDC48
local _0x1C92 = Instance.new("Frame")
_0x1C92.Name ="TopBar"_0x1C92.Size = UDim2.new(1, 0, 0, 48)
_0x1C92.BackgroundTransparency = 1
_0x1C92.Parent = _0xDC48
local _0x973B = Instance.new("TextLabel")
_0x973B.Name ="Title"_0x973B.Size = UDim2.new(1, -20, 0, 24)
_0x973B.Position = UDim2.new(0, 15, 0, 8)
_0x973B.BackgroundTransparency = 1
_0x973B.Text ="NOVAK"_0x973B.TextColor3 = Color3.fromRGB(255, 255, 255)
_0x973B.Font = Enum.Font.GothamBold
_0x973B.TextSize = 16
_0x973B.TextXAlignment = Enum.TextXAlignment.Left
_0x973B.Parent = _0x1C92
local _0xB357 = Instance.new("TextLabel")
_0xB357.Name ="SubTitle"_0xB357.Size = UDim2.new(1, -20, 0, 16)
_0xB357.Position = UDim2.new(0, 15, 0, 28)
_0xB357.BackgroundTransparency = 1
_0xB357.Text ="AUTHENTIFICATION REQUISE"_0xB357.TextColor3 = Color3.fromRGB(130, 130, 130)
_0xB357.Font = Enum.Font.Gotham
_0xB357.TextSize = 10
_0xB357.TextXAlignment = Enum.TextXAlignment.Left
_0xB357.Parent = _0x1C92
local _0x6E6C = Instance.new("Frame")
_0x6E6C.Name ="Separator"_0x6E6C.Size = UDim2.new(1, -30, 0, 1)
_0x6E6C.Position = UDim2.new(0, 15, 0, 52)
_0x6E6C.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
_0x6E6C.BorderSizePixel = 0
_0x6E6C.Parent = _0xDC48
local _0x53CA = Instance.new("TextLabel")
_0x53CA.Size = UDim2.new(1, -30, 0, 18)
_0x53CA.Position = UDim2.new(0, 15, 0, 65)
_0x53CA.BackgroundTransparency = 1
_0x53CA.Text ="NOM D'UTILISATEUR ROBLOX"_0x53CA.TextColor3 = Color3.fromRGB(180, 180, 180)
_0x53CA.Font = Enum.Font.GothamBold
_0x53CA.TextSize = 11
_0x53CA.TextXAlignment = Enum.TextXAlignment.Left
_0x53CA.Parent = _0xDC48
local _0xAD6A = Instance.new("TextBox")
_0xAD6A.Size = UDim2.new(1, -30, 0, 36)
_0xAD6A.Position = UDim2.new(0, 15, 0, 87)
_0xAD6A.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
_0xAD6A.BorderSizePixel = 0
_0xAD6A.Text = _0x2471.Name
_0xAD6A.PlaceholderText ="Votre pseudo Roblox"_0xAD6A.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
_0xAD6A.TextColor3 = Color3.fromRGB(255, 255, 255)
_0xAD6A.Font = Enum.Font.Gotham
_0xAD6A.TextSize = 13
_0xAD6A.ClearTextOnFocus = false
_0xAD6A.Parent = _0xDC48
local _0xE35E = Instance.new("UICorner")
_0xE35E.CornerRadius = UDim.new(0, 6)
_0xE35E.Parent = _0xAD6A
local _0x7573 = Instance.new("UIStroke")
_0x7573.Color = Color3.fromRGB(35, 35, 35)
_0x7573.Thickness = 1
_0x7573.Parent = _0xAD6A
local _0xBF73 = Instance.new("TextLabel")
_0xBF73.Size = UDim2.new(1, -30, 0, 18)
_0xBF73.Position = UDim2.new(0, 15, 0, 133)
_0xBF73.BackgroundTransparency = 1
_0xBF73.Text ="MOT DE PASSE"_0xBF73.TextColor3 = Color3.fromRGB(180, 180, 180)
_0xBF73.Font = Enum.Font.GothamBold
_0xBF73.TextSize = 11
_0xBF73.TextXAlignment = Enum.TextXAlignment.Left
_0xBF73.Parent = _0xDC48
local _0x0A93 = Instance.new("TextBox")
_0x0A93.Size = UDim2.new(1, -30, 0, 36)
_0x0A93.Position = UDim2.new(0, 15, 0, 155)
_0x0A93.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
_0x0A93.BorderSizePixel = 0
_0x0A93.Text =""_0x0A93.PlaceholderText ="Entrez le mot de passe genere"_0x0A93.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
_0x0A93.TextColor3 = Color3.fromRGB(255, 255, 255)
_0x0A93.Font = Enum.Font.Gotham
_0x0A93.TextSize = 13
_0x0A93.ClearTextOnFocus = false
_0x0A93.Parent = _0xDC48
local _0x9718 = Instance.new("UICorner")
_0x9718.CornerRadius = UDim.new(0, 6)
_0x9718.Parent = _0x0A93
local _0x9178 = Instance.new("UIStroke")
_0x9178.Color = Color3.fromRGB(35, 35, 35)
_0x9178.Thickness = 1
_0x9178.Parent = _0x0A93
local _0x066E = Instance.new("TextLabel")
_0x066E.Size = UDim2.new(1, -30, 0, 24)
_0x066E.Position = UDim2.new(0, 15, 0, 200)
_0x066E.BackgroundTransparency = 1
if _0x51CE then
_0x066E.Text ="Premiere connexion : mot de passe copie !"_0x066E.TextColor3 = Color3.fromRGB(200, 200, 200)
else
_0x066E.Text =""_0x066E.TextColor3 = Color3.fromRGB(200, 200, 200)
end
_0x066E.Font = Enum.Font.Gotham
_0x066E.TextSize = 11
_0x066E.TextWrapped = true
_0x066E.Parent = _0xDC48
local _0x05AE = Instance.new("TextButton")
_0x05AE.Size = UDim2.new(1, -30, 0, 38)
_0x05AE.Position = UDim2.new(0, 15, 0, 235)
_0x05AE.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
_0x05AE.BorderSizePixel = 0
_0x05AE.Text ="SE CONNECTER"_0x05AE.TextColor3 = Color3.fromRGB(12, 12, 12)
_0x05AE.Font = Enum.Font.GothamBold
_0x05AE.TextSize = 13
_0x05AE.Parent = _0xDC48
local _0xD64D = Instance.new("UICorner")
_0xD64D.CornerRadius = UDim.new(0, 6)
_0xD64D.Parent = _0x05AE
local _0x4DC5 = Instance.new("TextButton")
_0x4DC5.Size = UDim2.new(1, -30, 0, 26)
_0x4DC5.Position = UDim2.new(0, 15, 0, 282)
_0x4DC5.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
_0x4DC5.BorderSizePixel = 0
_0x4DC5.Text ="Copier le mot de passe"_0x4DC5.TextColor3 = Color3.fromRGB(160, 160, 160)
_0x4DC5.Font = Enum.Font.Gotham
_0x4DC5.TextSize = 11
_0x4DC5.Parent = _0xDC48
local _0x7888 = Instance.new("UICorner")
_0x7888.CornerRadius = UDim.new(0, 6)
_0x7888.Parent = _0x4DC5
local _0xE96B = Instance.new("UIStroke")
_0xE96B.Color = Color3.fromRGB(35, 35, 35)
_0xE96B.Thickness = 1
_0xE96B.Parent = _0x4DC5
local _0x8D6E = false
local _0xB850, _0xF252, _0x8898
_0x1C92.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
_0x8D6E = true
_0xF252 = input.Position
_0x8898 = _0xDC48.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then
_0x8D6E = false
end
end)
end
end)
_0x1C92.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
_0xB850 = input
end
end)
_0x78ED.InputChanged:Connect(function(input)
if input == _0xB850 and _0x8D6E then
local _0xB59B = input.Position - _0xF252
_0xDC48.Position = UDim2.new(_0x8898.X.Scale, _0x8898.X.Offset + _0xB59B.X, _0x8898.Y.Scale, _0x8898.Y.Offset + _0xB59B.Y)
end
end)
_0x4DC5.MouseButton1Click:Connect(function()
pcall(function()
if setclipboard then
setclipboard(_0xA6CE)
end
end)
_0x066E.Text ="Mot de passe copie dans le presse-papier !"_0x066E.TextColor3 = Color3.fromRGB(120, 220, 120)
end)
local _0x8075 = false
_0x05AE.MouseButton1Click:Connect(function()
local _0x744D = string.gsub(_0xAD6A.Text,"^%s*(.-)%s*$","%1")
local _0xA574 = string.gsub(_0x0A93.Text,"^%s*(.-)%s*$","%1")
if _0x744D ==""or _0xA574 ==""then
_0x066E.Text ="Veuillez remplir tous les champs !"_0x066E.TextColor3 = Color3.fromRGB(240, 80, 80)
return
end
local _0x7B1B = false
if string.lower(_0x744D) == string.lower(_0x2471.Name) then
_0x7B1B = true
else
pcall(function()
local _0x2002 = _0x4BB9:GetUserIdFromNameAsync(_0x744D)
if _0x2002 and _0x2002 == _0x2471.UserId then
_0x7B1B = true
end
end)
end
if not _0x7B1B then
_0x066E.Text ="Nom d'utilisateur Roblox invalide !"_0x066E.TextColor3 = Color3.fromRGB(240, 80, 80)
return
end
if _0xA574 ~= _0xA6CE then
_0x066E.Text ="Mot de passe incorrect !"_0x066E.TextColor3 = Color3.fromRGB(240, 80, 80)
return
end
_0x066E.Text ="Connexion reussie ! Chargement..."_0x066E.TextColor3 = Color3.fromRGB(120, 220, 120)
local _0xB6A0 = _0xC604:Create(_0xDC48, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
Size = UDim2.new(0, 0, 0, 0),
BackgroundTransparency = 1
})
_0xB6A0:Play()
_0xB6A0.Completed:Wait()
_0x191B:Destroy()
_0x8075 = true
end)
repeat task.wait(0.1) until _0x8075
end
local _0xD04E = Enum.KeyCode.Insert
pcall(function()
if setfpscap then
setfpscap(9999)
end
end)
pcall(function()
local _0x4C07 = game:GetService("Lighting")
_0x4C07.GlobalShadows = false
_0x4C07.FogEnd = 9e9
_0x4C07.FogStart = 9e9
end)
pcall(function()
local _0x68C4 = workspace:FindFirstChildOfClass("Terrain")
if _0x68C4 then
_0x68C4.WaterWaveSize = 0
_0x68C4.WaterWaveSpeed = 0
_0x68C4.WaterReflectance = 0
_0x68C4.Decoration = false
end
end)
local _0x4BB9 = game:GetService("Players")
local _0xC604 = game:GetService("TweenService")
local _0x78ED = game:GetService("UserInputService")
local _0x5B09 = game:GetService("RunService")
local _0x7EAE = game:GetService("Lighting")
local _0x473F = game:GetService("HttpService")
local _0x13B7 = game:GetService("TeleportService")
local _0x35D2 = game:GetService("Stats")
local _0x0DDD = nil
pcall(function()
_0x0DDD = game:GetService("VirtualInputManager")
end)
local _0x2471 = _0x4BB9.LocalPlayer or _0x4BB9.PlayerAdded:Wait()
pcall(function()
if hookmetamethod then
local _0x9E24
_0x9E24 = hookmetamethod(game,"__namecall", function(self, ...)
local _0x5980 = getnamecallmethod()
if (_0x5980 =="Kick"or _0x5980 =="kick") and (self == _0x2471 or tostring(self) == tostring(_0x2471)) then
return nil
end
return _0x9E24(self, ...)
end)
end
end)
local _0xACA3 = _0x473F:GenerateGUID(false):sub(1, 8)
local _0x373F = false
local _0xE756 = {}
local function _0x1506(_0x18F0)
if _0x18F0 then
table.insert(_0xE756, _0x18F0)
end
return _0x18F0
end
local _0x8FDF = _0xFF36()
local function _0x6A3F(_0xBCD6)
pcall(function()
if syn and syn.protect_gui then
syn.protect_gui(_0xBCD6)
end
end)
end
local _0x7DDD = Instance.new("ScreenGui")
_0x7DDD.Name ="Novak_".. _0xACA3
_0x7DDD.ResetOnSpawn = false
_0x7DDD.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
_0x7DDD.DisplayOrder = 999
_0x7DDD.IgnoreGuiInset = true
_0x6A3F(_0x7DDD)
_0x09F9(_0x7DDD, _0x8FDF)
local _0x4074 = {
MainBg = Color3.fromRGB(13, 13, 16),
SideBg = Color3.fromRGB(18, 18, 22),
HeaderBg = Color3.fromRGB(15, 15, 19),
CardBg = Color3.fromRGB(22, 22, 28),
CardStroke = Color3.fromRGB(38, 38, 48),
CardStrokeFocus = Color3.fromRGB(80, 80, 96),
Accent = Color3.fromRGB(255, 255, 255),
AccentMuted = Color3.fromRGB(160, 160, 175),
AccentDim = Color3.fromRGB(85, 85, 100),
TextWhite = Color3.fromRGB(250, 250, 255),
TextMuted = Color3.fromRGB(140, 140, 155),
TextDark = Color3.fromRGB(90, 90, 105),
ToggleOff = Color3.fromRGB(32, 32, 40),
ToggleOn = Color3.fromRGB(255, 255, 255),
ButtonBg = Color3.fromRGB(28, 28, 36),
ButtonHover = Color3.fromRGB(38, 38, 48),
Red = Color3.fromRGB(240, 70, 70),
Green = Color3.fromRGB(50, 220, 120),
}
local function _0x9EB0(className, properties)
local _0x16D5 = Instance.new(className)
for prop, _0x3C69 in pairs(properties) do
if prop ~="Parent"then
_0x16D5[prop] = _0x3C69
end
end
if properties.Parent then
_0x16D5.Parent = properties.Parent
end
return _0x16D5
end
local function _0xD30C(_0xB1A1, radius)
return _0x9EB0("UICorner", {
CornerRadius = UDim.new(0, radius or 6),
Parent = _0xB1A1,
})
end
local function _0xFC1A(_0xB1A1, color, thickness)
return _0x9EB0("UIStroke", {
Color = color or _0x4074.CardStroke,
Thickness = thickness or 1,
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
Parent = _0xB1A1,
})
end
local function _0x0FDE(_0x16D5, duration, properties, style, direction)
local _0x1C9A = TweenInfo.new(
duration or 0.2,
style or Enum.EasingStyle.Quart,
direction or Enum.EasingDirection.Out
)
local _0xC689 = _0xC604:Create(_0x16D5, _0x1C9A, properties)
_0xC689:Play()
return _0xC689
end
local _0xE370 = _0x9EB0("Frame", {
Name ="NovakNotifications",
Size = UDim2.new(0, 280, 1, -40),
Position = UDim2.new(1, -295, 0, 20),
BackgroundTransparency = 1,
ZIndex = 200,
Parent = _0x7DDD,
})
_0x9EB0("UIListLayout", {
Padding = UDim.new(0, 8),
VerticalAlignment = Enum.VerticalAlignment.Bottom,
HorizontalAlignment = Enum.HorizontalAlignment.Right,
Parent = _0xE370,
})
local function _0x5C21(message, accentColor)
accentColor = accentColor or _0x4074.Accent
local _0x25D4 = _0x9EB0("Frame", {
Size = UDim2.new(0, 270, 0, 46),
BackgroundColor3 = _0x4074.CardBg,
BackgroundTransparency = 0.05,
BorderSizePixel = 0,
ClipsDescendants = true,
ZIndex = 201,
Parent = _0xE370,
})
_0xD30C(_0x25D4, 6)
local _0xAAFB = _0xFC1A(_0x25D4, _0x4074.CardStroke, 1)
local _0x3572 = _0x9EB0("Frame", {
Size = UDim2.new(0, 3, 1, 0),
Position = UDim2.new(0, 0, 0, 0),
BackgroundColor3 = accentColor,
BorderSizePixel = 0,
ZIndex = 202,
Parent = _0x25D4,
})
local _0x7924 = _0x9EB0("TextLabel", {
Size = UDim2.new(1, -20, 0, 16),
Position = UDim2.new(0, 12, 0, 6),
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
Text ="NOVAK",
TextSize = 11,
TextColor3 = accentColor,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 202,
Parent = _0x25D4,
})
local _0x3DA4 = _0x9EB0("TextLabel", {
Size = UDim2.new(1, -20, 0, 18),
Position = UDim2.new(0, 12, 0, 22),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text = message,
TextSize = 11,
TextColor3 = _0x4074.TextWhite,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 202,
Parent = _0x25D4,
})
_0x25D4.Position = UDim2.new(1, 300, 0, 0)
_0x0FDE(_0x25D4, 0.25, { Position = UDim2.new(0, 0, 0, 0) })
task.delay(3.5, function()
if _0x25D4 and _0x25D4.Parent then
local _0xC689 = _0x0FDE(_0x25D4, 0.25, { Position = UDim2.new(1, 300, 0, 0) })
_0xC689.Completed:Wait()
pcall(function() _0x25D4:Destroy() end)
end
end)
end
local _0x73F7 = {}
local _0x382E = {}
local _0x3353 = {}
local _0xFD19 = {}
local _0x0415 = {}
local _0xAD9B = {}
local _0xB145 = UDim2.new(0.5, -460, 0.5, -300)
local _0x7A7A = _0xB145
local _0x51E6 = _0x9EB0("Frame", {
Name ="MainHolder",
Size = UDim2.new(0, 920, 0, 600),
Position = _0x7A7A,
BackgroundColor3 = _0x4074.MainBg,
BorderSizePixel = 0,
ClipsDescendants = false,
ZIndex = 10,
Parent = _0x7DDD,
})
_0xD30C(_0x51E6, 8)
local _0x5934 = _0xFC1A(_0x51E6, _0x4074.CardStroke, 1.2)
local _0x4821 = _0x9EB0("ImageLabel", {
Name ="Shadow",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.new(0.5, 0, 0.5, 0),
Size = UDim2.new(1, 32, 1, 32),
BackgroundTransparency = 1,
Image ="rbxassetid://1316045217",
ImageColor3 = Color3.fromRGB(0, 0, 0),
ImageTransparency = 0.5,
ScaleType = Enum.ScaleType.Slice,
SliceCenter = Rect.new(10, 10, 118, 118),
ZIndex = 9,
Parent = _0x51E6,
})
local _0xBFBC = _0x9EB0("Frame", {
Name ="Header",
Size = UDim2.new(1, 0, 0, 56),
Position = UDim2.new(0, 0, 0, 0),
BackgroundColor3 = _0x4074.HeaderBg,
BorderSizePixel = 0,
ZIndex = 12,
Parent = _0x51E6,
})
_0xD30C(_0xBFBC, 8)
local _0x1A2F = _0x9EB0("Frame", {
Size = UDim2.new(1, 0, 0, 1),
Position = UDim2.new(0, 0, 1, -1),
BackgroundColor3 = _0x4074.CardStroke,
BorderSizePixel = 0,
ZIndex = 13,
Parent = _0xBFBC,
})
local _0xC22A = _0x9EB0("TextLabel", {
Name ="BrandTitle",
Size = UDim2.new(0, 200, 0, 24),
Position = UDim2.new(0, 18, 0, 8),
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
Text ="Novak",
TextSize = 20,
TextColor3 = _0x4074.TextWhite,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 14,
Parent = _0xBFBC,
})
local _0x5A4F = _0x9EB0("TextLabel", {
Name ="BrandSubtitle",
Size = UDim2.new(0, 250, 0, 16),
Position = UDim2.new(0, 18, 0, 32),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text ="Novak | coded by @findltc",
TextSize = 12,
TextColor3 = _0x4074.TextMuted,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 14,
Parent = _0xBFBC,
})
local _0x3324 = _0x9EB0("Frame", {
Name ="WindowControls",
Size = UDim2.new(0, 76, 0, 34),
Position = UDim2.new(1, -84, 0, 11),
BackgroundTransparency = 1,
ZIndex = 14,
Parent = _0xBFBC,
})
local _0xF258 = _0x9EB0("TextButton", {
Name ="MinBtn",
Size = UDim2.new(0, 32, 0, 32),
Position = UDim2.new(0, 0, 0, 1),
BackgroundColor3 = _0x4074.CardBg,
BorderSizePixel = 0,
Font = Enum.Font.GothamBold,
Text ="-",
TextSize = 16,
TextColor3 = _0x4074.TextMuted,
AutoButtonColor = false,
ZIndex = 15,
Parent = _0x3324,
})
_0xD30C(_0xF258, 6)
_0xFC1A(_0xF258, _0x4074.CardStroke, 1)
local _0x93B3 = _0x9EB0("TextButton", {
Name ="CloseBtn",
Size = UDim2.new(0, 32, 0, 32),
Position = UDim2.new(0, 38, 0, 1),
BackgroundColor3 = _0x4074.CardBg,
BorderSizePixel = 0,
Font = Enum.Font.GothamBold,
Text ="X",
TextSize = 13,
TextColor3 = _0x4074.TextMuted,
AutoButtonColor = false,
ZIndex = 15,
Parent = _0x3324,
})
_0xD30C(_0x93B3, 6)
_0xFC1A(_0x93B3, _0x4074.CardStroke, 1)
_0x93B3.MouseEnter:Connect(function()
_0x0FDE(_0x93B3, 0.15, { BackgroundColor3 = _0x4074.Red, TextColor3 = Color3.fromRGB(255, 255, 255) })
end)
_0x93B3.MouseLeave:Connect(function()
_0x0FDE(_0x93B3, 0.15, { BackgroundColor3 = _0x4074.CardBg, TextColor3 = _0x4074.TextMuted })
end)
_0xF258.MouseEnter:Connect(function()
_0x0FDE(_0xF258, 0.15, { TextColor3 = _0x4074.TextWhite, BackgroundColor3 = _0x4074.ButtonHover })
end)
_0xF258.MouseLeave:Connect(function()
_0x0FDE(_0xF258, 0.15, { TextColor3 = _0x4074.TextMuted, BackgroundColor3 = _0x4074.CardBg })
end)
local _0x4DEF
_0x93B3.MouseButton1Click:Connect(function()
if _0x4DEF then
_0x4DEF()
end
end)
local _0x9805 = false
local _0xF252 = Vector2.new(0, 0)
local _0x8898 = UDim2.new(0, 0, 0, 0)
_0xBFBC.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
_0x9805 = true
_0xF252 = input.Position
_0x8898 = _0x51E6.Position
end
end)
_0xBFBC.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
_0x9805 = false
_0x7A7A = _0x51E6.Position
end
end)
_0x1506(_0x78ED.InputChanged:Connect(function(input)
if _0x9805 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local _0xB59B = input.Position - _0xF252
_0x51E6.Position = UDim2.new(
_0x8898.X.Scale,
_0x8898.X.Offset + _0xB59B.X,
_0x8898.Y.Scale,
_0x8898.Y.Offset + _0xB59B.Y
)
end
end))
local _0x7ECE = _0x9EB0("Frame", {
Name ="Body",
Size = UDim2.new(1, 0, 1, -56),
Position = UDim2.new(0, 0, 0, 56),
BackgroundTransparency = 1,
ZIndex = 11,
Parent = _0x51E6,
})
local _0x40F6 = false
_0xF258.MouseButton1Click:Connect(function()
_0x40F6 = not _0x40F6
if _0x40F6 then
_0x0FDE(_0x51E6, 0.22, { Size = UDim2.new(0, 920, 0, 56) })
_0x7ECE.Visible = false
else
_0x7ECE.Visible = true
_0x0FDE(_0x51E6, 0.22, { Size = UDim2.new(0, 920, 0, 600) })
end
end)
local _0x72CB = _0x9EB0("Frame", {
Name ="Sidebar",
Size = UDim2.new(0, 175, 1, 0),
Position = UDim2.new(0, 0, 0, 0),
BackgroundColor3 = _0x4074.SideBg,
BorderSizePixel = 0,
ZIndex = 20,
Parent = _0x7ECE,
})
local _0x16B2 = _0x9EB0("Frame", {
Size = UDim2.new(0, 1, 1, 0),
Position = UDim2.new(1, -1, 0, 0),
BackgroundColor3 = _0x4074.CardStroke,
BorderSizePixel = 0,
ZIndex = 21,
Parent = _0x72CB,
})
local _0x32AE = _0x9EB0("Frame", {
Name ="NavContainer",
Size = UDim2.new(1, -16, 1, -50),
Position = UDim2.new(0, 8, 0, 12),
BackgroundTransparency = 1,
ZIndex = 21,
Parent = _0x72CB,
})
_0x9EB0("UIListLayout", {
Padding = UDim.new(0, 6),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = _0x32AE,
})
local _0x346D = _0x9EB0("TextLabel", {
Size = UDim2.new(1, -16, 0, 24),
Position = UDim2.new(0, 8, 1, -30),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text ="v2.3 • stable",
TextSize = 10,
TextColor3 = _0x4074.TextDark,
TextXAlignment = Enum.TextXAlignment.Center,
ZIndex = 13,
Parent = _0x72CB,
})
local _0x956B = _0x9EB0("Frame", {
Name ="ContentArea",
Size = UDim2.new(1, -175, 1, 0),
Position = UDim2.new(0, 175, 0, 0),
BackgroundTransparency = 1,
ClipsDescendants = true,
ZIndex = 12,
Parent = _0x7ECE,
})
local _0x0002 = {
{ Name ="Aim", Icon ="rbxassetid://10723415903"},
{ Name ="Visual", Icon ="rbxassetid://10723346959"},
{ Name ="Settings", Icon ="rbxassetid://10734950309"},
{ Name ="Help", Icon ="rbxassetid://10723406988"},
}
local _0x9D17 = {}
local _0x5661 = {}
local _0x9A1D ="Aim"local _0xC0F8 = 350
local function _0xFA87(targetName)
if _0x9A1D == targetName then return end
_0x9A1D = targetName
for _0x8FDA, _0x280D in pairs(_0x9D17) do
local _0xD47E = (_0x8FDA == targetName)
_0x0FDE(_0x280D.Button, 0.15, {
BackgroundTransparency = _0xD47E and 0 or 1,
BackgroundColor3 = _0xD47E and _0x4074.CardBg or Color3.fromRGB(0, 0, 0),
})
if _0x280D.Stroke then
_0x280D.Stroke.Transparency = _0xD47E and 0 or 1
_0x280D.Stroke.Color = _0x4074.CardStroke
end
if _0x280D.ActiveBar then
_0x280D.ActiveBar.Visible = _0xD47E
end
if _0x280D.Icon then
_0x0FDE(_0x280D.Icon, 0.15, { ImageColor3 = _0xD47E and _0x4074.TextWhite or _0x4074.TextMuted })
end
if _0x280D.Label then
_0x0FDE(_0x280D.Label, 0.15, { TextColor3 = _0xD47E and _0x4074.TextWhite or _0x4074.TextMuted })
end
if _0x5661[_0x8FDA] then
_0x5661[_0x8FDA].Visible = _0xD47E
if _0xD47E then
_0x5661[_0x8FDA].CanvasPosition = Vector2.new(0, 0)
end
end
end
end
for i, tabInfo in ipairs(_0x0002) do
local _0x8F54 = tabInfo.Name
local _0x7171 = (i == 1)
local _0xE90A = _0x9EB0("TextButton", {
Name ="Tab_".. _0x8F54,
Size = UDim2.new(1, 0, 0, 38),
BackgroundColor3 = _0x7171 and _0x4074.CardBg or Color3.fromRGB(0, 0, 0),
BackgroundTransparency = _0x7171 and 0 or 1,
BorderSizePixel = 0,
Font = Enum.Font.GothamMedium,
Text ="",
AutoButtonColor = false,
Active = true,
Selectable = true,
LayoutOrder = i,
ZIndex = 22,
Parent = _0x32AE,
})
_0xD30C(_0xE90A, 6)
local _0xAAFB = _0xFC1A(_0xE90A, _0x4074.CardStroke, 1)
if not _0x7171 then _0xAAFB.Transparency = 1 end
local _0xADF7 = _0x9EB0("Frame", {
Name ="ActiveBar",
Size = UDim2.new(0, 3, 0, 20),
Position = UDim2.new(0, 0, 0.5, -10),
BackgroundColor3 = _0x4074.Accent,
BorderSizePixel = 0,
Visible = _0x7171,
Active = false,
ZIndex = 24,
Parent = _0xE90A,
})
_0xD30C(_0xADF7, 2)
local _0x1827 = _0x9EB0("ImageLabel", {
Name ="Icon",
Size = UDim2.new(0, 18, 0, 18),
Position = UDim2.new(0, 12, 0.5, -9),
BackgroundTransparency = 1,
Image = tabInfo.Icon,
ImageColor3 = _0x7171 and _0x4074.TextWhite or _0x4074.TextMuted,
Active = false,
ZIndex = 23,
Parent = _0xE90A,
})
local _0x06F7 = _0x9EB0("TextLabel", {
Name ="Label",
Size = UDim2.new(1, -42, 1, 0),
Position = UDim2.new(0, 38, 0, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text = _0x8F54,
TextSize = 12,
TextColor3 = _0x7171 and _0x4074.TextWhite or _0x4074.TextMuted,
TextXAlignment = Enum.TextXAlignment.Left,
Active = false,
ZIndex = 23,
Parent = _0xE90A,
})
local _0xBC01 = _0x9EB0("ScrollingFrame", {
Name ="Page_".. _0x8F54,
Size = UDim2.new(1, -26, 1, -20),
Position = UDim2.new(0, 13, 0, 10),
BackgroundTransparency = 1,
BorderSizePixel = 0,
ScrollBarThickness = 5,
ScrollBarImageColor3 = _0x4074.AccentDim,
ScrollBarImageTransparency = 0.3,
CanvasSize = UDim2.new(0, 0, 0, 0),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
Visible = _0x7171,
ZIndex = 13,
Parent = _0x956B,
})
_0x9EB0("UIPadding", {
PaddingBottom = UDim.new(0, 30),
Parent = _0xBC01,
})
_0x5661[_0x8F54] = _0xBC01
_0x9D17[_0x8F54] = {
Button = _0xE90A,
_0x8703 = _0xAAFB,
ActiveBar = _0xADF7,
Icon = _0x1827,
Label = _0x06F7,
}
local function _0x2A5B()
_0xFA87(_0x8F54)
end
_0xE90A.MouseButton1Click:Connect(_0x2A5B)
_0xE90A.Activated:Connect(_0x2A5B)
_0xE90A.MouseButton1Down:Connect(_0x2A5B)
_0xE90A.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
_0x2A5B()
end
end)
_0x06F7.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
_0x2A5B()
end
end)
_0x1827.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
_0x2A5B()
end
end)
_0xE90A.MouseEnter:Connect(function()
if _0x9A1D ~= _0x8F54 then
_0x0FDE(_0xE90A, 0.12, { BackgroundTransparency = 0.6, BackgroundColor3 = _0x4074.ButtonHover })
_0x0FDE(_0x06F7, 0.12, { TextColor3 = _0x4074.TextWhite })
_0x0FDE(_0x1827, 0.12, { ImageColor3 = _0x4074.TextWhite })
end
end)
_0xE90A.MouseLeave:Connect(function()
if _0x9A1D ~= _0x8F54 then
_0x0FDE(_0xE90A, 0.12, { BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(0, 0, 0) })
_0x0FDE(_0x06F7, 0.12, { TextColor3 = _0x4074.TextMuted })
_0x0FDE(_0x1827, 0.12, { ImageColor3 = _0x4074.TextMuted })
end
end)
end
local function _0xA737(_0xB1A1, titleText, sizeUDim)
local _0x25D4 = _0x9EB0("Frame", {
Name ="Section_".. titleText:gsub("%s+",""),
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundColor3 = _0x4074.CardBg,
BorderSizePixel = 0,
ZIndex = 14,
Parent = _0xB1A1,
})
_0xD30C(_0x25D4, 8)
local _0xAAFB = _0xFC1A(_0x25D4, _0x4074.CardStroke, 1)
local _0x546D = _0x9EB0("Frame", {
Size = UDim2.new(1, 0, 0, 32),
BackgroundTransparency = 1,
ZIndex = 15,
Parent = _0x25D4,
})
local _0xFB12 = _0x9EB0("Frame", {
Size = UDim2.new(0, 3, 0, 14),
Position = UDim2.new(0, 12, 0.5, -7),
BackgroundColor3 = _0x4074.Accent,
BorderSizePixel = 0,
ZIndex = 16,
Parent = _0x546D,
})
_0xD30C(_0xFB12, 1)
local _0xC89B = _0x9EB0("TextLabel", {
Size = UDim2.new(1, -30, 1, 0),
Position = UDim2.new(0, 22, 0, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
Text = titleText:upper(),
TextSize = 11,
TextColor3 = _0x4074.AccentMuted,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x546D,
})
local _0x26B7 = _0x9EB0("Frame", {
Size = UDim2.new(1, -24, 0, 1),
Position = UDim2.new(0, 12, 0, 32),
BackgroundColor3 = _0x4074.CardStroke,
BorderSizePixel = 0,
ZIndex = 15,
Parent = _0x25D4,
})
local _0xEE22 = _0x9EB0("Frame", {
Name ="Content",
Size = UDim2.new(1, -24, 0, 0),
Position = UDim2.new(0, 12, 0, 38),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex = 15,
Parent = _0x25D4,
})
_0x9EB0("UIPadding", {
PaddingBottom = UDim.new(0, 12),
Parent = _0xEE22,
})
return _0x25D4, _0xEE22
end
local function _0xC513(_0xB1A1, labelText, defaultVal, callback)
local _0x3C69 = defaultVal or false
_0x73F7[labelText] = _0x3C69
local _0x2D0C = _0x9EB0("Frame", {
Name ="Toggle_".. labelText:gsub("%s+",""),
Size = UDim2.new(1, 0, 0, 28),
BackgroundTransparency = 1,
ZIndex = 16,
Parent = _0xB1A1,
})
local _0xFDF7 = _0x9EB0("TextLabel", {
Size = UDim2.new(1, -48, 1, 0),
Position = UDim2.new(0, 0, 0, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text = labelText,
TextSize = 12,
TextColor3 = _0x3C69 and _0x4074.TextWhite or _0x4074.TextMuted,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x2D0C,
})
local _0x12B2 = _0x9EB0("TextButton", {
Size = UDim2.new(0, 38, 0, 20),
Position = UDim2.new(1, -38, 0.5, -10),
BackgroundColor3 = _0x3C69 and _0x4074.ToggleOn or _0x4074.ToggleOff,
BorderSizePixel = 0,
Text ="",
AutoButtonColor = false,
ZIndex = 16,
Parent = _0x2D0C,
})
_0xD30C(_0x12B2, 10)
local _0x849F = _0xFC1A(_0x12B2, _0x4074.CardStroke, 1)
local _0x51D6 = _0x9EB0("Frame", {
Size = UDim2.new(0, 14, 0, 14),
Position = _0x3C69 and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
BackgroundColor3 = _0x3C69 and Color3.fromRGB(13, 13, 16) or _0x4074.TextMuted,
BorderSizePixel = 0,
ZIndex = 17,
Parent = _0x12B2,
})
_0xD30C(_0x51D6, 7)
local function _0xF472(state, trigger)
_0x3C69 = state
_0x73F7[labelText] = _0x3C69
_0x0FDE(_0x12B2, 0.15, { BackgroundColor3 = _0x3C69 and _0x4074.ToggleOn or _0x4074.ToggleOff })
_0x0FDE(_0x51D6, 0.15, {
Position = _0x3C69 and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
BackgroundColor3 = _0x3C69 and Color3.fromRGB(13, 13, 16) or _0x4074.TextMuted,
})
_0x0FDE(_0xFDF7, 0.15, { TextColor3 = _0x3C69 and _0x4074.TextWhite or _0x4074.TextMuted })
if trigger and callback then
pcall(callback, _0x3C69)
end
end
_0x12B2.MouseButton1Click:Connect(function()
_0xF472(not _0x3C69, true)
end)
_0xFD19[labelText] = {
Set = function(_0xACE4) _0xF472(_0xACE4, true) end,
Get = function() return _0x3C69 end,
}
return _0xF472
end
local function _0x44DE(_0xB1A1, labelText, defaultVal, minVal, maxVal, unit, callback)
minVal = minVal or 0
maxVal = maxVal or 100
unit = unit or""local _0x3C69 = defaultVal or minVal
_0x382E[labelText] = _0x3C69
local _0x2D0C = _0x9EB0("Frame", {
Name ="Slider_".. labelText:gsub("%s+",""),
Size = UDim2.new(1, 0, 0, 42),
BackgroundTransparency = 1,
ZIndex = 16,
Parent = _0xB1A1,
})
local _0xFDF7 = _0x9EB0("TextLabel", {
Size = UDim2.new(0.65, 0, 0, 16),
Position = UDim2.new(0, 0, 0, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text = labelText,
TextSize = 12,
TextColor3 = _0x4074.TextWhite,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x2D0C,
})
local _0xDC2F = _0x9EB0("TextLabel", {
Size = UDim2.new(0.35, 0, 0, 16),
Position = UDim2.new(0.65, 0, 0, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
Text = tostring(_0x3C69) .." ".. unit,
TextSize = 12,
TextColor3 = _0x4074.AccentMuted,
TextXAlignment = Enum.TextXAlignment.Right,
ZIndex = 16,
Parent = _0x2D0C,
})
local _0xC89A = _0x9EB0("Frame", {
Size = UDim2.new(1, 0, 0, 6),
Position = UDim2.new(0, 0, 0, 26),
BackgroundColor3 = _0x4074.ToggleOff,
BorderSizePixel = 0,
ZIndex = 16,
Parent = _0x2D0C,
})
_0xD30C(_0xC89A, 3)
local _0x04B0 = math.clamp((_0x3C69 - minVal) / (maxVal - minVal), 0, 1)
local _0x088F = _0x9EB0("Frame", {
Size = UDim2.new(_0x04B0, 0, 1, 0),
BackgroundColor3 = _0x4074.Accent,
BorderSizePixel = 0,
ZIndex = 17,
Parent = _0xC89A,
})
_0xD30C(_0x088F, 3)
local _0x51D6 = _0x9EB0("Frame", {
Size = UDim2.new(0, 12, 0, 12),
Position = UDim2.new(_0x04B0, -6, 0.5, -6),
BackgroundColor3 = _0x4074.TextWhite,
BorderSizePixel = 0,
ZIndex = 18,
Parent = _0xC89A,
})
_0xD30C(_0x51D6, 6)
local _0x8205 = false
local function _0xD068(input)
local _0x4ADF = math.clamp((input.Position.X - _0xC89A.AbsolutePosition.X) / _0xC89A.AbsoluteSize.X, 0, 1)
_0x3C69 = math.floor(minVal + (maxVal - minVal) * _0x4ADF + 0.5)
_0x382E[labelText] = _0x3C69
_0xDC2F.Text = tostring(_0x3C69) .." ".. unit
_0x088F.Size = UDim2.new(_0x4ADF, 0, 1, 0)
_0x51D6.Position = UDim2.new(_0x4ADF, -6, 0.5, -6)
if callback then
pcall(callback, _0x3C69)
end
end
_0xC89A.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
_0x8205 = true
_0xD068(input)
end
end)
_0xC89A.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
_0x8205 = false
end
end)
_0x1506(_0x78ED.InputChanged:Connect(function(input)
if _0x8205 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
_0xD068(input)
end
end))
local function _0x6C56(v, trigger)
_0x3C69 = math.clamp(v, minVal, maxVal)
_0x382E[labelText] = _0x3C69
_0xDC2F.Text = tostring(_0x3C69) .." ".. unit
local _0xA893 = (_0x3C69 - minVal) / (maxVal - minVal)
_0x088F.Size = UDim2.new(_0xA893, 0, 1, 0)
_0x51D6.Position = UDim2.new(_0xA893, -6, 0.5, -6)
if trigger and callback then
pcall(callback, _0x3C69)
end
end
_0x0415[labelText] = {
Set = function(v) _0x6C56(v, true) end,
Get = function() return _0x3C69 end,
}
return _0x6C56
end
local function _0x493D(_0xB1A1, labelText, options, callback)
local _0xE994 = options[1] or""local _0xC43B = false
local _0x5886 = _0x9EB0("Frame", {
Name ="Dropdown_".. labelText:gsub("%s+",""),
Size = UDim2.new(1, 0, 0, 56),
BackgroundTransparency = 1,
ClipsDescendants = false,
ZIndex = 25,
Parent = _0xB1A1,
})
local _0xFDF7 = _0x9EB0("TextLabel", {
Size = UDim2.new(1, 0, 0, 16),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text = labelText,
TextSize = 12,
TextColor3 = _0x4074.TextWhite,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 25,
Parent = _0x5886,
})
local _0x2A50 = _0x9EB0("TextButton", {
Size = UDim2.new(1, 0, 0, 30),
Position = UDim2.new(0, 0, 0, 22),
BackgroundColor3 = _0x4074.ButtonBg,
BorderSizePixel = 0,
Font = Enum.Font.GothamMedium,
Text ="  ".. _0xE994,
TextSize = 12,
TextColor3 = _0x4074.TextWhite,
TextXAlignment = Enum.TextXAlignment.Left,
AutoButtonColor = false,
ZIndex = 26,
Parent = _0x5886,
})
_0xD30C(_0x2A50, 6)
_0xFC1A(_0x2A50, _0x4074.CardStroke, 1)
local _0x835D = _0x9EB0("TextLabel", {
Size = UDim2.new(0, 20, 1, 0),
Position = UDim2.new(1, -24, 0, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
Text ="v",
TextSize = 10,
TextColor3 = _0x4074.TextMuted,
ZIndex = 27,
Parent = _0x2A50,
})
local _0xF769 = _0x9EB0("Frame", {
Size = UDim2.new(1, 0, 0, #options * 26 + 6),
Position = UDim2.new(0, 0, 1, 4),
BackgroundColor3 = _0x4074.CardBg,
BorderSizePixel = 0,
Visible = false,
ZIndex = 40,
Parent = _0x2A50,
})
_0xD30C(_0xF769, 6)
_0xFC1A(_0xF769, _0x4074.CardStrokeFocus, 1)
local _0xF3E8 = _0x9EB0("UIListLayout", {
Padding = UDim.new(0, 2),
HorizontalAlignment = Enum.HorizontalAlignment.Center,
VerticalAlignment = Enum.VerticalAlignment.Center,
Parent = _0xF769,
})
for _0xD694, opt in ipairs(options) do
local _0x7435 = _0x9EB0("TextButton", {
Size = UDim2.new(1, -6, 0, 24),
BackgroundColor3 = (opt == _0xE994) and _0x4074.ButtonHover or Color3.fromRGB(0, 0, 0),
BackgroundTransparency = (opt == _0xE994) and 0 or 1,
BorderSizePixel = 0,
Font = Enum.Font.GothamMedium,
Text ="  ".. opt,
TextSize = 11,
TextColor3 = (opt == _0xE994) and _0x4074.TextWhite or _0x4074.TextMuted,
TextXAlignment = Enum.TextXAlignment.Left,
AutoButtonColor = false,
ZIndex = 41,
Parent = _0xF769,
})
_0xD30C(_0x7435, 4)
_0x7435.MouseButton1Click:Connect(function()
_0xE994 = opt
_0x2A50.Text ="  ".. _0xE994
_0xF769.Visible = false
_0xC43B = false
_0x835D.Text ="v"if callback then
pcall(callback, _0xE994)
end
end)
end
_0x2A50.MouseButton1Click:Connect(function()
_0xC43B = not _0xC43B
_0xF769.Visible = _0xC43B
_0x835D.Text = _0xC43B and"^"or"v"end)
end
local function _0xFDAC(_0xB1A1, labelText, defaultKeyName, callback)
local _0x91E7 = defaultKeyName or"Insert"local _0x3D05 = false
_0x3353[labelText] = _0x91E7
local _0x2D0C = _0x9EB0("Frame", {
Name ="Keybind_".. labelText:gsub("%s+",""),
Size = UDim2.new(1, 0, 0, 28),
BackgroundTransparency = 1,
ZIndex = 16,
Parent = _0xB1A1,
})
local _0xFDF7 = _0x9EB0("TextLabel", {
Size = UDim2.new(1, -85, 1, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text = labelText,
TextSize = 12,
TextColor3 = _0x4074.TextWhite,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x2D0C,
})
local _0xE90A = _0x9EB0("TextButton", {
Size = UDim2.new(0, 80, 0, 24),
Position = UDim2.new(1, -80, 0.5, -12),
BackgroundColor3 = _0x4074.ButtonBg,
BorderSizePixel = 0,
Font = Enum.Font.GothamMedium,
Text ="[".. _0x91E7 .."]",
TextSize = 11,
TextColor3 = _0x4074.TextWhite,
AutoButtonColor = false,
ZIndex = 16,
Parent = _0x2D0C,
})
_0xD30C(_0xE90A, 4)
local _0x3804 = _0xFC1A(_0xE90A, _0x4074.CardStroke, 1)
_0xE90A.MouseButton1Click:Connect(function()
if _0x3D05 then return end
_0x3D05 = true
_0xE90A.Text ="[...]"_0xE90A.TextColor3 = _0x4074.Accent
_0x3804.Color = _0x4074.Accent
local _0x18F0
_0x18F0 = _0x78ED.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Keyboard then
_0x91E7 = input.KeyCode.Name
_0xE90A.Text ="[".. _0x91E7 .."]"_0xE90A.TextColor3 = _0x4074.TextWhite
_0x3804.Color = _0x4074.CardStroke
_0x3D05 = false
_0x3353[labelText] = _0x91E7
_0x18F0:Disconnect()
if callback then
pcall(callback, input.KeyCode, _0x91E7, false)
end
elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
_0x91E7 = (input.UserInputType == Enum.UserInputType.MouseButton2) and"RMB"or"LMB"_0xE90A.Text ="[".. _0x91E7 .."]"_0xE90A.TextColor3 = _0x4074.TextWhite
_0x3804.Color = _0x4074.CardStroke
_0x3D05 = false
_0x3353[labelText] = _0x91E7
_0x18F0:Disconnect()
if callback then
pcall(callback, input.UserInputType, _0x91E7, true)
end
end
end)
end)
_0xAD9B[labelText] = {
Set = function(kName)
_0x91E7 = kName
_0xE90A.Text ="[".. _0x91E7 .."]"_0x3353[labelText] = _0x91E7
if Enum.KeyCode[kName] and callback then
pcall(callback, Enum.KeyCode[kName], kName, false)
end
end,
Get = function() return _0x91E7 end,
}
end
local function _0x583C(_0xB1A1, text, size, pos, callback, isPrimary)
local _0xE90A = _0x9EB0("TextButton", {
Size = size or UDim2.new(1, 0, 0, 32),
Position = pos or UDim2.new(0, 0, 0, 0),
BackgroundColor3 = isPrimary and _0x4074.Accent or _0x4074.ButtonBg,
BorderSizePixel = 0,
Font = Enum.Font.GothamBold,
Text = text,
TextSize = 12,
TextColor3 = isPrimary and Color3.fromRGB(13, 13, 16) or _0x4074.TextWhite,
AutoButtonColor = false,
ZIndex = 16,
Parent = _0xB1A1,
})
_0xD30C(_0xE90A, 6)
if not isPrimary then
_0xFC1A(_0xE90A, _0x4074.CardStroke, 1)
end
_0xE90A.MouseEnter:Connect(function()
_0x0FDE(_0xE90A, 0.15, { BackgroundColor3 = isPrimary and Color3.fromRGB(220, 220, 230) or _0x4074.ButtonHover })
end)
_0xE90A.MouseLeave:Connect(function()
_0x0FDE(_0xE90A, 0.15, { BackgroundColor3 = isPrimary and _0x4074.Accent or _0x4074.ButtonBg })
end)
_0xE90A.MouseButton1Click:Connect(function()
if callback then
pcall(callback)
end
end)
return _0xE90A
end
local function _0x7742(_0xB1A1, titleText, defaultColor, callback)
local _0x9C2E = defaultColor or _0x4074.Accent
local _0x5886 = _0x9EB0("Frame", {
Name ="ColorPicker_".. titleText:gsub("%s+",""),
Size = UDim2.new(1, 0, 0, 48),
BackgroundTransparency = 1,
ZIndex = 16,
Parent = _0xB1A1,
})
local _0xFDF7 = _0x9EB0("TextLabel", {
Size = UDim2.new(1, -40, 0, 16),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text = titleText,
TextSize = 12,
TextColor3 = _0x4074.TextWhite,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x5886,
})
local _0x8206 = _0x9EB0("Frame", {
Size = UDim2.new(0, 28, 0, 16),
Position = UDim2.new(1, -28, 0, 0),
BackgroundColor3 = _0x9C2E,
BorderSizePixel = 0,
ZIndex = 16,
Parent = _0x5886,
})
_0xD30C(_0x8206, 4)
_0xFC1A(_0x8206, _0x4074.CardStroke, 1)
local _0x86E4 = _0x9EB0("Frame", {
Size = UDim2.new(1, 0, 0, 20),
Position = UDim2.new(0, 0, 0, 22),
BackgroundTransparency = 1,
ZIndex = 16,
Parent = _0x5886,
})
_0x9EB0("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal,
Padding = UDim.new(0, 6),
Parent = _0x86E4,
})
local _0x40C5 = {
Color3.fromRGB(255, 255, 255),
Color3.fromRGB(200, 200, 210),
Color3.fromRGB(240, 70, 70),
Color3.fromRGB(50, 220, 120),
Color3.fromRGB(60, 150, 255),
Color3.fromRGB(255, 210, 60),
Color3.fromRGB(180, 80, 255),
}
for _0xD694, c in ipairs(_0x40C5) do
local _0x4AC3 = _0x9EB0("TextButton", {
Size = UDim2.new(0, 18, 0, 18),
BackgroundColor3 = c,
BorderSizePixel = 0,
Text ="",
AutoButtonColor = false,
ZIndex = 17,
Parent = _0x86E4,
})
_0xD30C(_0x4AC3, 4)
_0x4AC3.MouseButton1Click:Connect(function()
_0x9C2E = c
_0x8206.BackgroundColor3 = _0x9C2E
if callback then
pcall(callback, _0x9C2E)
end
end)
end
end
local function _0x205E(_0xB1A1, labelText, defaultVal)
local _0x2D0C = _0x9EB0("Frame", {
Size = UDim2.new(1, 0, 0, 24),
BackgroundTransparency = 1,
ZIndex = 16,
Parent = _0xB1A1,
})
local _0xFDF7 = _0x9EB0("TextLabel", {
Size = UDim2.new(0.6, 0, 1, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text = labelText,
TextSize = 12,
TextColor3 = _0x4074.TextMuted,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x2D0C,
})
local _0xDC2F = _0x9EB0("TextLabel", {
Size = UDim2.new(0.4, 0, 1, 0),
Position = UDim2.new(0.6, 0, 0, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
Text = defaultVal or"-",
TextSize = 12,
TextColor3 = _0x4074.TextWhite,
TextXAlignment = Enum.TextXAlignment.Right,
ZIndex = 16,
Parent = _0x2D0C,
})
return _0xDC2F
end
local _0x6036 = {
Enabled = false,
WallCheck = false,
Key = Enum.UserInputType.MouseButton2,
KeyName ="RMB",
IsMouse = true,
ShowFOV = false,
AutoLock = false,
Prediction = true,
AutoShoot = false,
FOV = 120,
Smoothness = 5,
PredictionAmount = 0.135,
TeamCheck = false,
LockBots = false,
TargetPart ="Head",
Priority ="Crosshair Priority",
VisibilityCheck = false,
DynamicFOV = false,
HitChance = 100,
MaxDistance = 1500,
}
local _0x8E1A = false
local _0x37CC = nil
local _0xA041 = _0x9EB0("Frame", {
Name ="NovakFOVCircle",
Size = UDim2.new(0, _0x6036.FOV * 2, 0, _0x6036.FOV * 2),
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.new(0.5, 0, 0.5, 0),
BackgroundTransparency = 1,
Visible = false,
ZIndex = 100,
Parent = _0x7DDD,
})
_0xD30C(_0xA041, 9999)
local _0xAFF8 = _0xFC1A(_0xA041, Color3.fromRGB(255, 255, 255), 1.2)
_0xAFF8.Transparency = 0.5
local function _0x090D(model)
if not model then return false end
local _0x27A6 = model:FindFirstChildOfClass("Humanoid")
if _0x27A6 and _0x27A6.Health > 0 then return true end
local _0x8785 = model:GetAttribute("Health") or model:GetAttribute("hp") or model:GetAttribute("HP")
if _0x8785 and tonumber(_0x8785) and tonumber(_0x8785) > 0 then return true end
return false
end
local function _0x587D(model)
if not model then return nil end
return _0x4BB9:GetPlayerFromCharacter(model)
end
local function _0x5FB4(player)
if not player or not _0x2471 then return false end
if player.Team and _0x2471.Team and player.Team == _0x2471.Team then return true end
if player.TeamColor and _0x2471.TeamColor and player.TeamColor == _0x2471.TeamColor then return true end
return false
end
local function _0x9292(part, origin)
if not part then return false end
local _0x0DA0 = workspace.CurrentCamera
if not _0x0DA0 then return false end
local _0xCE37 = origin or _0x0DA0.CFrame.Position
local _0x0CF8 = { _0x2471.Character, _0x0DA0 }
local _0x2F17 = RaycastParams.new()
_0x2F17.FilterType = Enum.RaycastFilterType.Blacklist
_0x2F17.FilterDescendantsInstances = _0x0CF8
_0x2F17.IgnoreWater = true
local _0xEAA3 = part.Position - _0xCE37
local _0x4C54 = workspace:Raycast(_0xCE37, _0xEAA3, _0x2F17)
if not _0x4C54 then return true end
if _0x4C54.Instance and _0x4C54.Instance:IsDescendantOf(part.Parent) then return true end
return false
end
local function _0x5055(character, partPref)
if not character then return nil end
if partPref =="Head"then
return character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
elseif partPref =="Torso"then
return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
elseif partPref =="Random"then
local _0xBD4A = {"Head","UpperTorso","Torso","HumanoidRootPart"}
for _0xD694, pName in ipairs(_0xBD4A) do
local _0x2963 = character:FindFirstChild(pName)
if _0x2963 then return _0x2963 end
end
end
return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end
local function _0x2126(character, part, _0xCE37)
if not part then return nil end
local _0xE60C = part.Position
if not _0x6036.Prediction then
return _0xE60C
end
local _0x3E00 = character:FindFirstChild("HumanoidRootPart") or part
local _0x4A88 = _0x3E00.Velocity
local _0xD591 = _0x6036.PredictionAmount
local _0x212C = (_0xCE37 - _0xE60C).Magnitude
local _0xCACE = _0xD591 + (_0x212C / 1400) * 0.04
return _0xE60C + (_0x4A88 * _0xCACE)
end
local function _0xFBA3()
local _0x0DA0 = workspace.CurrentCamera
if not _0x0DA0 then return nil end
local _0xEC8C = _0x78ED:GetMouseLocation()
local _0xCE48 = nil
local _0x8659 = math.huge
local function _0x04FD(model, isPlayerTarget, playerObj)
if not model or not _0x090D(model) then return end
if isPlayerTarget and _0x6036.TeamCheck and _0x5FB4(playerObj) then return end
local _0x5AC6 = _0x5055(model, _0x6036.TargetPart)
if not _0x5AC6 then return end
local _0xEB40, _0x230D = _0x0DA0:WorldToViewportPoint(_0x5AC6.Position)
if not _0x230D or _0xEB40.Z <= 0 then return end
local _0x0479 = (Vector2.new(_0xEB40.X, _0xEB40.Y) - _0xEC8C).Magnitude
if _0x0479 > _0x6036.FOV then return end
local _0xB24D = (_0x0DA0.CFrame.Position - _0x5AC6.Position).Magnitude
if _0xB24D > _0x6036.MaxDistance then return end
if _0x6036.WallCheck and not _0x9292(_0x5AC6, _0x0DA0.CFrame.Position) then
return
end
local _0x61FF = _0x0479
if _0x6036.Priority =="Distance Priority"then
_0x61FF = _0xB24D
elseif _0x6036.Priority =="Health Priority"then
local _0x27A6 = model:FindFirstChildOfClass("Humanoid")
_0x61FF = _0x27A6 and _0x27A6.Health or 100
end
if _0x61FF < _0x8659 then
_0x8659 = _0x61FF
_0xCE48 = {
Character = model,
Part = _0x5AC6,
IsPlayer = isPlayerTarget,
Player = playerObj,
}
end
end
for _0xD694, _0xA893 in ipairs(_0x4BB9:GetPlayers()) do
if _0xA893 ~= _0x2471 and _0xA893.Character then
_0x04FD(_0xA893.Character, true, _0xA893)
end
end
if _0x6036.LockBots then
for _0xD694, obj in ipairs(workspace:GetChildren()) do
if obj:IsA("Model") and obj ~= _0x2471.Character and not _0x4BB9:GetPlayerFromCharacter(obj) then
if obj:FindFirstChildOfClass("Humanoid") then
_0x04FD(obj, false, nil)
end
end
end
end
return _0xCE48
end
local function _0x8D5F()
if _0x373F then return end
local _0x0DA0 = workspace.CurrentCamera
if not _0x0DA0 then return end
if _0x6036.ShowFOV then
_0xA041.Visible = true
local _0xEC8C = _0x78ED:GetMouseLocation()
_0xA041.Position = UDim2.new(0, _0xEC8C.X, 0, _0xEC8C.Y)
_0xA041.Size = UDim2.new(0, _0x6036.FOV * 2, 0, _0x6036.FOV * 2)
else
_0xA041.Visible = false
end
if not _0x6036.Enabled then
_0x37CC = nil
return
end
local _0x1C24 = _0x8E1A or _0x6036.AutoLock
if not _0x1C24 then
_0x37CC = nil
return
end
if not _0x37CC or not _0x090D(_0x37CC.Character) then
_0x37CC = _0xFBA3()
end
if _0x37CC and _0x37CC.Character then
local _0x5AC6 = _0x5055(_0x37CC.Character, _0x6036.TargetPart)
if not _0x5AC6 then
_0x37CC = nil
return
end
local _0x0719 = _0x2126(_0x37CC.Character, _0x5AC6, _0x0DA0.CFrame.Position)
if _0x0719 then
local _0x409F = CFrame.lookAt(_0x0DA0.CFrame.Position, _0x0719)
if _0x6036.Smoothness <= 1 then
_0x0DA0.CFrame = _0x409F
else
local _0xACE4 = math.clamp(_0x6036.Smoothness, 1, 30)
local _0x26EA = math.clamp(1 / _0xACE4, 0.04, 0.95)
_0x0DA0.CFrame = _0x0DA0.CFrame:Lerp(_0x409F, _0x26EA)
end
end
else
_0x37CC = nil
end
end
pcall(function()
_0x5B09:BindToRenderStep("NovakAimbot", Enum.RenderPriority.Camera.Value + 1, _0x8D5F)
end)
_0x1506(_0x78ED.InputBegan:Connect(function(input, gp)
if gp or not _0x6036.Enabled then return end
if (_0x6036.IsMouse and input.UserInputType == _0x6036.Key) or (not _0x6036.IsMouse and input.KeyCode == _0x6036.Key) then
_0x8E1A = true
end
end))
_0x1506(_0x78ED.InputEnded:Connect(function(input)
if (_0x6036.IsMouse and input.UserInputType == _0x6036.Key) or (not _0x6036.IsMouse and input.KeyCode == _0x6036.Key) then
_0x8E1A = false
_0x37CC = nil
end
end))
local _0x65E8 = {
NoRecoil = false,
NoSpread = false,
InstantReload = false,
Triggerbot = false,
}
local _0x8996 = {}
local _0xE850 = {}
local _0x2054 = {}
local function _0x8514()
if not getgc then return end
pcall(function()
for _0xD694, v in pairs(getgc(true)) do
if type(v) =="table"then
if _0x65E8.NoRecoil then
for _0xD694, key in ipairs({"Recoil","recoil","CameraRecoil","cameraRecoil","recoilControl","RecoilControl","RecoilX","RecoilY","RecoilZ","RecoilMin","RecoilMax","RecoilSpeed","recoilSpeed","VisualRecoil","RecoilDamper","RecoilMultiplier","Shake","CameraShake","Sway","Bobbing","GunBob","camRecoil","viewmodelRecoil","KickBack","kickBack"}) do
local _0x3C69 = rawget(v, key)
if _0x3C69 ~= nil and type(_0x3C69) =="number"and _0x3C69 ~= 0 then
if _0x8996[v] == nil then _0x8996[v] = {} end
if _0x8996[v][key] == nil then _0x8996[v][key] = _0x3C69 end
rawset(v, key, 0)
elseif _0x3C69 ~= nil and typeof(_0x3C69) =="Vector3"and _0x3C69 ~= Vector3.new(0, 0, 0) then
if _0x8996[v] == nil then _0x8996[v] = {} end
if _0x8996[v][key] == nil then _0x8996[v][key] = _0x3C69 end
rawset(v, key, Vector3.new(0, 0, 0))
end
end
elseif next(_0x8996) ~= nil and _0x8996[v] ~= nil then
for k, oldVal in pairs(_0x8996[v]) do
rawset(v, k, oldVal)
end
_0x8996[v] = nil
end
if _0x65E8.NoSpread then
for _0xD694, key in ipairs({"Spread","spread","MinSpread","MaxSpread","BaseSpread","CurrentSpread","DefaultSpread","WalkSpread","JumpSpread","CrouchSpread","HipSpread","AimSpread","Cone","BulletSpread","Inaccuracy","SpreadRecovery","SpreadIncrement","SpreadDecay","ShotSpread","GunSpread","bloom","Bloom"}) do
local _0x3C69 = rawget(v, key)
if _0x3C69 ~= nil and type(_0x3C69) =="number"and _0x3C69 ~= 0 then
if _0xE850[v] == nil then _0xE850[v] = {} end
if _0xE850[v][key] == nil then _0xE850[v][key] = _0x3C69 end
rawset(v, key, 0)
end
end
if rawget(v,"Accuracy") ~= nil and type(rawget(v,"Accuracy")) =="number"then
rawset(v,"Accuracy", 100)
end
elseif next(_0xE850) ~= nil and _0xE850[v] ~= nil then
for k, oldVal in pairs(_0xE850[v]) do
rawset(v, k, oldVal)
end
_0xE850[v] = nil
end
if _0x65E8.InstantReload then
for _0xD694, key in ipairs({"ReloadTime","reloadTime","ReloadDuration","ReloadSpeed","reloadSpeed","EmptyReloadTime","TacticalReloadTime","reload_time","ReloadDelay"}) do
local _0x3C69 = rawget(v, key)
if _0x3C69 ~= nil and type(_0x3C69) =="number"then
if _0x2054[v] == nil then _0x2054[v] = {} end
if _0x2054[v][key] == nil then _0x2054[v][key] = _0x3C69 end
if key:lower():find("speed") then
rawset(v, key, 100)
else
rawset(v, key, 0.001)
end
end
end
elseif next(_0x2054) ~= nil and _0x2054[v] ~= nil then
for k, oldVal in pairs(_0x2054[v]) do
rawset(v, k, oldVal)
end
_0x2054[v] = nil
end
end
end
end)
end
local _0x5F91 = false
local _0xE975 = nil
_0x1506(_0x78ED.InputBegan:Connect(function(input, gp)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
_0x5F91 = true
if workspace.CurrentCamera then
_0xE975 = workspace.CurrentCamera.CFrame.LookVector
end
elseif input.KeyCode == Enum.KeyCode.R and _0x65E8.InstantReload then
task.spawn(function()
_0x8514()
if _0x2471.Character then
local _0x27A6 = _0x2471.Character:FindFirstChildOfClass("Humanoid")
local _0x0344 = _0x27A6 and _0x27A6:FindFirstChildOfClass("Animator")
if _0x0344 then
for _0xD694, _0xC89A in ipairs(_0x0344:GetPlayingAnimationTracks()) do
local _0xA463 = tostring(_0xC89A.Animation and _0xC89A.Animation.Name or""):lower()
if _0xA463:find("reload") or _0xA463:find("mag") then
_0xC89A:AdjustSpeed(25)
end
end
end
end
end)
end
end))
_0x1506(_0x78ED.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
_0x5F91 = false
_0xE975 = nil
end
end))
_0x1506(_0x5B09.RenderStepped:Connect(function()
if _0x373F or not _0x65E8.NoRecoil then return end
local _0x0DA0 = workspace.CurrentCamera
if not _0x0DA0 then return end
local _0xE05A = _0x78ED:GetMouseDelta()
if _0x5F91 and _0xE975 and math.abs(_0xE05A.Y) < 1.6 and math.abs(_0xE05A.X) < 1.6 then
local _0x52E6 = _0x0DA0.CFrame.LookVector
local _0x8A64 = _0x52E6.Y - _0xE975.Y
if _0x8A64 > 0.001 then
local _0x4DB2 = CFrame.lookAt(_0x0DA0.CFrame.Position, _0x0DA0.CFrame.Position + Vector3.new(_0x52E6.X, _0xE975.Y, _0x52E6.Z))
_0x0DA0.CFrame = _0x0DA0.CFrame:Lerp(_0x4DB2, 0.92)
else
_0xE975 = _0x52E6
end
else
_0xE975 = _0x0DA0.CFrame.LookVector
end
end))
local function _0xEEDA(_0x2704)
if not _0x2704 then return end
_0x1506(_0x2704.ChildAdded:Connect(function(child)
if child:IsA("Tool") and (_0x65E8.NoRecoil or _0x65E8.NoSpread or _0x65E8.InstantReload) then
task.wait(0.2)
_0x8514()
end
end))
end
if _0x2471.Character then _0xEEDA(_0x2471.Character) end
_0x1506(_0x2471.CharacterAdded:Connect(_0xEEDA))
local _0x3F28 = nil
local _0x15C0 = 0
local function _0x1C41(_0xEC8C)
local _0x4ADF = _0xEC8C and _0xEC8C.X or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X / 2 or 500)
local _0xF429 = _0xEC8C and _0xEC8C.Y or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y / 2 or 350)
if _0x0DDD then
pcall(function()
_0x0DDD:SendMouseButtonEvent(_0x4ADF, _0xF429, 0, true, game, 0)
task.wait(0.02)
_0x0DDD:SendMouseButtonEvent(_0x4ADF, _0xF429, 0, false, game, 0)
end)
elseif mouse1click then
pcall(mouse1click)
elseif mouse1press then
pcall(mouse1press)
task.wait(0.02)
pcall(mouse1release)
end
pcall(function()
if _0x2471.Character then
local _0x4977 = _0x2471.Character:FindFirstChildOfClass("Tool")
if _0x4977 then
_0x4977:Activate()
end
end
end)
end
local function _0x6D58(enabled)
if _0x3F28 then
pcall(function() _0x3F28:Disconnect() end)
_0x3F28 = nil
end
if not enabled then return end
_0x3F28 = _0x5B09.RenderStepped:Connect(function()
if _0x373F or not _0x65E8.Triggerbot then return end
local _0x0DA0 = workspace.CurrentCamera
if not _0x0DA0 then return end
local _0xBE9C = tick()
if _0xBE9C - _0x15C0 < 0.07 then return end
local _0xEC8C = _0x78ED:GetMouseLocation()
local _0x7EC9 = _0x0DA0:ViewportPointToRay(_0xEC8C.X, _0xEC8C.Y)
local _0x2F17 = RaycastParams.new()
_0x2F17.FilterType = Enum.RaycastFilterType.Blacklist
_0x2F17.FilterDescendantsInstances = { _0x2471.Character, _0x0DA0 }
_0x2F17.IgnoreWater = true
local _0x4C54 = workspace:Raycast(_0x7EC9.Origin, _0x7EC9.Direction * 1200, _0x2F17)
local _0xB1A8 = _0x4C54 and _0x4C54.Instance or (_0x2471:GetMouse() and _0x2471:GetMouse().Target)
if not _0xB1A8 then return end
local _0xC377 = _0xB1A8:FindFirstAncestorOfClass("Model")
if not _0xC377 or _0xC377 == _0x2471.Character then return end
if _0x090D(_0xC377) then
local _0xA893 = _0x4BB9:GetPlayerFromCharacter(_0xC377)
local _0x8047 = _0xA893 and _0x5FB4(_0xA893)
if not (_0x6036.TeamCheck and _0x8047) and (_0xA893 ~= nil or _0x6036.LockBots) then
_0x15C0 = _0xBE9C
_0x1C41(_0xEC8C)
end
end
end)
_0x1506(_0x3F28)
end
do
local _0x342D = _0x5661["Aim"]
local _0xC0F8 = 350
local _0x67BD = _0x9EB0("Frame", {
Size = UDim2.new(0, _0xC0F8, 0, 0),
Position = UDim2.new(0, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex = 14,
Parent = _0x342D,
})
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = _0x67BD })
local _0xCDFA = _0x9EB0("Frame", {
Size = UDim2.new(0, _0xC0F8, 0, 0),
Position = UDim2.new(0, 366, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex = 14,
Parent = _0x342D,
})
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = _0xCDFA })
local _0xD694, _0xDC86 = _0xA737(_0x67BD,"Aimbot Core", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 6), Parent = _0xDC86 })
_0xC513(_0xDC86,"Enable Aimbot", false, function(v)
_0x6036.Enabled = v
if not v then _0x37CC = nil end
end)
_0xC513(_0xDC86,"Wall Check", _0x6036.WallCheck, function(v)
_0x6036.WallCheck = v
end)
_0xFDAC(_0xDC86,"Aimbot Keybind", _0x6036.KeyName, function(key, _0x8FDA, isMouse)
_0x6036.Key = key
_0x6036.KeyName = _0x8FDA
_0x6036.IsMouse = isMouse
end)
_0xC513(_0xDC86,"Show FOV Circle", false, function(v)
_0x6036.ShowFOV = v
end)
_0xC513(_0xDC86,"Auto Lock (Dans FOV)", false, function(v)
_0x6036.AutoLock = v
end)
_0xC513(_0xDC86,"Aim Prediction", true, function(v)
_0x6036.Prediction = v
end)
_0xC513(_0xDC86,"Auto Shoot", false, function(v)
_0x6036.AutoShoot = v
end)
_0x44DE(_0xDC86,"Aimbot FOV", _0x6036.FOV, 20, 360,"px", function(v)
_0x6036.FOV = v
end)
_0x44DE(_0xDC86,"Smoothness", _0x6036.Smoothness, 1, 20,"lerp", function(v)
_0x6036.Smoothness = v
end)
_0x44DE(_0xDC86,"Prediction (Lead)", 135, 10, 300,"ms", function(v)
_0x6036.PredictionAmount = v / 1000
end)
local _0xD694, _0x6CA4 = _0xA737(_0x67BD,"Aimbot Filters", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 6), Parent = _0x6CA4 })
_0xC513(_0x6CA4,"Team Check", false, function(v)
_0x6036.TeamCheck = v
end)
_0xC513(_0x6CA4,"Lock Bots (PNJ)", false, function(v)
_0x6036.LockBots = v
end)
_0x493D(_0x6CA4,"Target Part", {"Head","Torso","Random"}, function(v)
_0x6036.TargetPart = v
end)
_0x493D(_0x6CA4,"Target Priority", {"Crosshair Priority","Distance Priority","Health Priority"}, function(v)
_0x6036.Priority = v
end)
local _0xD694, _0xCAF8 = _0xA737(_0xCDFA,"Gun Utilities", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 6), Parent = _0xCAF8 })
_0xC513(_0xCAF8,"No Recoil (Super Boosted)", false, function(v)
_0x65E8.NoRecoil = v
_0x8514()
if v then
_0x5C21("No Recoil Super Boosted Active !", _0x4074.Accent)
end
end)
_0xC513(_0xCAF8,"No Spread (100% Precision)", false, function(v)
_0x65E8.NoSpread = v
_0x8514()
if v then
_0x5C21("No Spread Laser Active !", _0x4074.Accent)
end
end)
_0xC513(_0xCAF8,"Fast / Instant Reload", false, function(v)
_0x65E8.InstantReload = v
_0x8514()
if v then
_0x5C21("Fast / Instant Reload Active !", _0x4074.Accent)
end
end)
_0xC513(_0xCAF8,"Vrai Triggerbot (Auto Shoot)", false, function(v)
_0x65E8.Triggerbot = v
_0x6D58(v)
if v then
_0x5C21("Triggerbot Automatique Active !", _0x4074.Accent)
end
end)
local _0xD694, _0x673C = _0xA737(_0xCDFA,"Targeting Settings", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 6), Parent = _0x673C })
_0xC513(_0x673C,"Visibility Check", false, function(v)
_0x6036.VisibilityCheck = v
end)
_0xC513(_0x673C,"Dynamic FOV", false, function(v)
_0x6036.DynamicFOV = v
end)
_0x44DE(_0x673C,"Hit Chance", 100, 10, 100,"%", function(v)
_0x6036.HitChance = v
end)
_0x44DE(_0x673C,"Max Target Dist", 1500, 100, 3000,"studs", function(v)
_0x6036.MaxDistance = v
end)
end
local _0xCE74 = {
Enabled = false,
TeamCheck = false,
NPC = false,
Box = false,
Skeleton = false,
Health = false,
PV = false,
Head = false,
Name = false,
Dist = false,
AFK = false,
Tracer = false,
TracerOrigin ="Bottom",
Glow = false,
MaxDistance = 1000,
Color = Color3.fromRGB(255, 255, 255),
BotColor = Color3.fromRGB(200, 200, 210),
}
local _0x2E37 = {
Enabled = false,
Lines = true,
Dot = false,
Size = 14,
Thickness = 2,
Color = Color3.fromRGB(255, 255, 255),
}
local _0xF6F4 = 70
local _0x1A61 = false
local _0x4759 = _0x9EB0("Frame", {
Name ="NovakCrosshair_".. _0xACA3,
Size = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
Visible = false,
ZIndex = 300,
Parent = _0x7DDD,
})
local _0xB76A = {
Left = _0x9EB0("Frame", { BorderSizePixel = 0, BackgroundColor3 = _0x2E37.Color, Parent = _0x4759 }),
Right = _0x9EB0("Frame", { BorderSizePixel = 0, BackgroundColor3 = _0x2E37.Color, Parent = _0x4759 }),
Top = _0x9EB0("Frame", { BorderSizePixel = 0, BackgroundColor3 = _0x2E37.Color, Parent = _0x4759 }),
Bottom = _0x9EB0("Frame", { BorderSizePixel = 0, BackgroundColor3 = _0x2E37.Color, Parent = _0x4759 }),
Dot = _0x9EB0("Frame", { BorderSizePixel = 0, BackgroundColor3 = _0x2E37.Color, Visible = false, Parent = _0x4759 }),
}
_0xD30C(_0xB76A.Dot, 2)
local function _0x0AD8()
if not _0x4759 then return end
_0x4759.Visible = _0x2E37.Enabled
local _0xACE4 = _0x2E37.Size
local _0xA7B7 = _0x2E37.Thickness
local _0x8F21 = _0x2E37.Color
local _0xB117 = _0x2E37.Dot and 3 or 0
local _0xD0A8 = math.max(math.floor(_0xACE4 / 2), 2)
local _0xB752 = math.floor(_0xA7B7 / 2)
local _0x1ED4 = _0x2E37.Lines
_0xB76A.Left.Size = UDim2.new(0, _0xD0A8, 0, _0xA7B7)
_0xB76A.Left.Position = UDim2.new(0.5, -_0xB117 - _0xD0A8, 0.5, -_0xB752)
_0xB76A.Left.BackgroundColor3 = _0x8F21
_0xB76A.Left.Visible = _0x1ED4
_0xB76A.Right.Size = UDim2.new(0, _0xD0A8, 0, _0xA7B7)
_0xB76A.Right.Position = UDim2.new(0.5, _0xB117, 0.5, -_0xB752)
_0xB76A.Right.BackgroundColor3 = _0x8F21
_0xB76A.Right.Visible = _0x1ED4
_0xB76A.Top.Size = UDim2.new(0, _0xA7B7, 0, _0xD0A8)
_0xB76A.Top.Position = UDim2.new(0.5, -_0xB752, 0.5, -_0xB117 - _0xD0A8)
_0xB76A.Top.BackgroundColor3 = _0x8F21
_0xB76A.Top.Visible = _0x1ED4
_0xB76A.Bottom.Size = UDim2.new(0, _0xA7B7, 0, _0xD0A8)
_0xB76A.Bottom.Position = UDim2.new(0.5, -_0xB752, 0.5, _0xB117)
_0xB76A.Bottom.BackgroundColor3 = _0x8F21
_0xB76A.Bottom.Visible = _0x1ED4
local _0xC543 = math.max(_0xA7B7 + 2, 4)
local _0xB6C0 = math.floor(_0xC543 / 2)
_0xB76A.Dot.Size = UDim2.new(0, _0xC543, 0, _0xC543)
_0xB76A.Dot.Position = UDim2.new(0.5, -_0xB6C0, 0.5, -_0xB6C0)
_0xB76A.Dot.BackgroundColor3 = _0x8F21
_0xB76A.Dot.Visible = _0x2E37.Dot
end
pcall(function()
_0x5B09:BindToRenderStep("NovakFOV", Enum.RenderPriority.Camera.Value + 1, function()
if not _0x373F and _0x1A61 and workspace.CurrentCamera then
workspace.CurrentCamera.FieldOfView = _0xF6F4
end
end)
end)
local _0xA941 = {}
local _0x3B96 = _0x9EB0("ScreenGui", {
Name ="NovakESP_".. _0xACA3,
ResetOnSpawn = false,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
DisplayOrder = 998,
IgnoreGuiInset = true,
})
_0x6A3F(_0x3B96)
_0x09F9(_0x3B96, _0x8FDF)
local function _0x4B1E(playerOrModel)
local _0x280D = _0xA941[playerOrModel]
if not _0x280D then return end
if _0x280D.conn then pcall(function() _0x280D.conn:Disconnect() end) end
if _0x280D.box then pcall(function() _0x280D.box:Destroy() end) end
if _0x280D.nameLabel then pcall(function() _0x280D.nameLabel:Destroy() end) end
if _0x280D.distLabel then pcall(function() _0x280D.distLabel:Destroy() end) end
if _0x280D.afkLabel then pcall(function() _0x280D.afkLabel:Destroy() end) end
if _0x280D.highlight then pcall(function() _0x280D.highlight:Destroy() end) end
if _0x280D.healthBg then pcall(function() _0x280D.healthBg:Destroy() end) end
if _0x280D.healthPvText then pcall(function() _0x280D.healthPvText:Destroy() end) end
if _0x280D.tracerLine then pcall(function() _0x280D.tracerLine:Destroy() end) end
if _0x280D.headNeckLine then pcall(function() _0x280D.headNeckLine:Destroy() end) end
if _0x280D.headHexLines then
for _0xD694, _0x0D1B in ipairs(_0x280D.headHexLines) do
pcall(function() _0x0D1B:Destroy() end)
end
end
if _0x280D.skeletonLines then
for _0xD694, _0x0D1B in ipairs(_0x280D.skeletonLines) do
pcall(function() _0x0D1B:Destroy() end)
end
end
if _0x280D.skeletonFolder then pcall(function() _0x280D.skeletonFolder:Destroy() end) end
_0xA941[playerOrModel] = nil
end
local function _0x92CA()
for obj in pairs(_0xA941) do
_0x4B1E(obj)
end
end
local function _0x08F0(targetInstance, customName, isPlayer)
if not targetInstance or _0xA941[targetInstance] then return end
if isPlayer and targetInstance == _0x2471 then return end
local _0x2704 = isPlayer and targetInstance.Character or targetInstance
if not _0x2704 then return end
local _0xD78A = _0xCE74.Color
local _0x505A = _0x9EB0("Frame", {
BorderSizePixel = 0,
BackgroundColor3 = _0xD78A,
BackgroundTransparency = 1,
Visible = false,
Parent = _0x3B96,
})
local _0x5B94 = _0xFC1A(_0x505A, _0xD78A, 1.2)
local _0xA861 = _0x9EB0("TextLabel", {
Visible = false,
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
TextSize = 12,
TextStrokeTransparency = 0,
TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
TextColor3 = _0xD78A,
Text = customName or (targetInstance.DisplayName or targetInstance.Name),
Parent = _0x3B96,
})
local _0xD9A2 = _0x9EB0("TextLabel", {
Visible = false,
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
TextSize = 10,
TextStrokeTransparency = 0,
TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
TextColor3 = _0xD78A,
Parent = _0x3B96,
})
local _0x2BD4 = _0x9EB0("TextLabel", {
Visible = false,
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
TextSize = 10,
TextStrokeTransparency = 0,
TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
TextColor3 = Color3.fromRGB(255, 75, 75),
Text ="[AFK]",
Parent = _0x3B96,
})
local _0xF0EA = _0x9EB0("Frame", {
Name ="HealthBg",
Visible = false,
BackgroundColor3 = Color3.fromRGB(20, 20, 25),
BorderSizePixel = 0,
Parent = _0x3B96,
})
local _0x5E9E = _0x9EB0("Frame", {
Name ="HealthBar",
BorderSizePixel = 0,
BackgroundColor3 = Color3.fromRGB(50, 220, 120),
Parent = _0xF0EA,
})
local _0xC3F7 = _0x9EB0("TextLabel", {
Name ="HealthPVText",
Visible = false,
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
TextSize = 10,
TextStrokeTransparency = 0,
TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
TextColor3 = Color3.fromRGB(50, 220, 120),
Parent = _0x3B96,
})
local _0xD0EA = _0x9EB0("Frame", {
Visible = false,
BorderSizePixel = 0,
BackgroundColor3 = _0xD78A,
AnchorPoint = Vector2.new(0.5, 0.5),
Parent = _0x3B96,
})
local _0x3ED8 = {}
for i = 1, 6 do
_0x3ED8[i] = _0x9EB0("Frame", {
BorderSizePixel = 0,
BackgroundColor3 = _0xD78A,
AnchorPoint = Vector2.new(0.5, 0.5),
Visible = false,
Parent = _0x3B96,
})
end
local _0xB01E = _0x9EB0("Frame", {
BorderSizePixel = 0,
BackgroundColor3 = _0xD78A,
AnchorPoint = Vector2.new(0.5, 0.5),
Visible = false,
Parent = _0x3B96,
})
local _0x0861 = _0x9EB0("Folder", {
Name ="Skeleton_".. (customName or targetInstance.Name),
Parent = _0x3B96,
})
local _0x0546 = {}
local _0xC9CA = _0x9EB0("Highlight", {
FillColor = _0xD78A,
OutlineColor = _0xD78A,
FillTransparency = 0.5,
OutlineTransparency = 0,
DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
Enabled = false,
Parent = nil,
})
local _0x280D = {
_0x505A = _0x505A,
_0x5B94 = _0x5B94,
_0xA861 = _0xA861,
_0xD9A2 = _0xD9A2,
_0x2BD4 = _0x2BD4,
_0xF0EA = _0xF0EA,
_0x5E9E = _0x5E9E,
_0xC3F7 = _0xC3F7,
_0xD0EA = _0xD0EA,
_0x3ED8 = _0x3ED8,
_0xB01E = _0xB01E,
_0x0861 = _0x0861,
_0x0546 = _0x0546,
_0xC9CA = _0xC9CA,
_0x18F0 = nil,
}
_0xA941[targetInstance] = _0x280D
local _0x8F52 = -1
_0x280D.conn = _0x5B09.RenderStepped:Connect(function()
if _0x373F or not _0xCE74.Enabled then
_0x505A.Visible = false
_0xA861.Visible = false
_0xD9A2.Visible = false
_0x2BD4.Visible = false
_0xF0EA.Visible = false
_0xC3F7.Visible = false
_0xD0EA.Visible = false
_0xB01E.Visible = false
for _0xD694, _0x0D1B in ipairs(_0x3ED8) do _0x0D1B.Visible = false end
for _0xD694, _0x0D1B in ipairs(_0x0546) do _0x0D1B.Visible = false end
if _0xC9CA.Parent ~= nil then _0xC9CA.Parent = nil end
return
end
local _0x7D61 = isPlayer and targetInstance.Character or targetInstance
if not _0x7D61 or not _0x7D61.Parent or not _0x090D(_0x7D61) then
_0x505A.Visible = false
_0xA861.Visible = false
_0xD9A2.Visible = false
_0x2BD4.Visible = false
_0xF0EA.Visible = false
_0xC3F7.Visible = false
_0xD0EA.Visible = false
_0xB01E.Visible = false
for _0xD694, _0x0D1B in ipairs(_0x3ED8) do _0x0D1B.Visible = false end
for _0xD694, _0x0D1B in ipairs(_0x0546) do _0x0D1B.Visible = false end
if _0xC9CA.Parent ~= nil then _0xC9CA.Parent = nil end
return
end
if isPlayer and _0xCE74.TeamCheck and _0x5FB4(targetInstance) then
_0x505A.Visible = false
_0xA861.Visible = false
_0xD9A2.Visible = false
_0x2BD4.Visible = false
_0xF0EA.Visible = false
_0xC3F7.Visible = false
_0xD0EA.Visible = false
_0xB01E.Visible = false
for _0xD694, _0x0D1B in ipairs(_0x3ED8) do _0x0D1B.Visible = false end
for _0xD694, _0x0D1B in ipairs(_0x0546) do _0x0D1B.Visible = false end
if _0xC9CA.Parent ~= nil then _0xC9CA.Parent = nil end
return
end
local _0x0DA0 = workspace.CurrentCamera
if not _0x0DA0 then return end
local _0x8B28 = _0x7D61:FindFirstChild("HumanoidRootPart") or _0x7D61:FindFirstChild("Torso") or _0x7D61:FindFirstChild("Head")
if not _0x8B28 then return end
local _0xBFFE = _0x0DA0.CFrame.Position
local _0x212C = (_0xBFFE - _0x8B28.Position).Magnitude
if _0x212C > (_0xCE74.MaxDistance or 1000) then
_0x505A.Visible = false
_0xA861.Visible = false
_0xD9A2.Visible = false
_0x2BD4.Visible = false
_0xF0EA.Visible = false
_0xC3F7.Visible = false
_0xD0EA.Visible = false
_0xB01E.Visible = false
for _0xD694, _0x0D1B in ipairs(_0x3ED8) do _0x0D1B.Visible = false end
for _0xD694, _0x0D1B in ipairs(_0x0546) do _0x0D1B.Visible = false end
return
end
local _0xEB40, _0x230D = _0x0DA0:WorldToViewportPoint(_0x8B28.Position)
if not _0x230D or _0xEB40.Z <= 0 then
_0x505A.Visible = false
_0xA861.Visible = false
_0xD9A2.Visible = false
_0x2BD4.Visible = false
_0xF0EA.Visible = false
_0xC3F7.Visible = false
_0xD0EA.Visible = false
_0xB01E.Visible = false
for _0xD694, _0x0D1B in ipairs(_0x3ED8) do _0x0D1B.Visible = false end
for _0xD694, _0x0D1B in ipairs(_0x0546) do _0x0D1B.Visible = false end
return
end
local _0x6E73 = isPlayer and _0xCE74.Color or _0xCE74.BotColor
local _0x4321 = math.clamp(1600 / math.max(_0x212C, 4), 16, 450)
local _0x7CAA = _0x4321 / 1.65
if _0xCE74.Box then
_0x505A.Visible = true
_0x505A.Size = UDim2.new(0, _0x7CAA, 0, _0x4321)
_0x505A.Position = UDim2.new(0, _0xEB40.X - _0x7CAA / 2, 0, _0xEB40.Y - _0x4321 / 2)
_0x5B94.Color = _0x6E73
else
_0x505A.Visible = false
end
local _0x11A4 = false
if _0xCE74.AFK then
if _0x7D61:FindFirstChildOfClass("ForceField")
or _0x7D61:FindFirstChild("ForceField")
or _0x7D61:FindFirstChild("Shield")
or _0x7D61:FindFirstChild("SpawnShield")
or _0x7D61:FindFirstChild("Invincible")
or _0x7D61:FindFirstChild("Invincibility")
or _0x7D61:FindFirstChild("SafeZone")
or _0x7D61:FindFirstChild("GodMode")
or _0x7D61:FindFirstChild("Protection")
or _0x7D61:GetAttribute("AFK") == true
or _0x7D61:GetAttribute("Invincible") == true
or _0x7D61:GetAttribute("Safe") == true
or _0x7D61:GetAttribute("Protected") == true
or _0x7D61:GetAttribute("SpawnProtection") == true
or _0x7D61:GetAttribute("Invisible") == true then
_0x11A4 = true
else
local _0x158B = _0x7D61:FindFirstChild("Head")
local _0x1D1A = _0x7D61:FindFirstChild("UpperTorso") or _0x7D61:FindFirstChild("Torso")
if _0x158B and _0x158B:IsA("BasePart") and _0x158B.Transparency >= 0.85 then
_0x11A4 = true
elseif _0x1D1A and _0x1D1A:IsA("BasePart") and _0x1D1A.Transparency >= 0.85 then
_0x11A4 = true
end
end
end
if _0xCE74.AFK and _0x11A4 then
_0x2BD4.Visible = true
local _0xEB8D = _0x4321 / 2 + 16
if _0xCE74.Name then
_0xEB8D = _0x4321 / 2 + 30
end
_0x2BD4.Position = UDim2.new(0, _0xEB40.X - 50, 0, _0xEB40.Y - _0xEB8D)
_0x2BD4.Size = UDim2.new(0, 100, 0, 14)
_0x2BD4.Text ="[AFK]"_0x2BD4.TextColor3 = Color3.fromRGB(255, 75, 75)
else
_0x2BD4.Visible = false
end
if _0xCE74.Name then
_0xA861.Visible = true
_0xA861.Position = UDim2.new(0, _0xEB40.X - 100, 0, _0xEB40.Y - _0x4321 / 2 - 16)
_0xA861.Size = UDim2.new(0, 200, 0, 16)
if _0xCE74.AFK and _0x11A4 then
_0xA861.Text = (customName or (targetInstance.DisplayName or targetInstance.Name)) .." [AFK]"_0xA861.TextColor3 = Color3.fromRGB(255, 75, 75)
else
_0xA861.Text = customName or (targetInstance.DisplayName or targetInstance.Name)
_0xA861.TextColor3 = _0x6E73
end
else
_0xA861.Visible = false
end
if _0xCE74.Dist then
_0xD9A2.Visible = true
_0xD9A2.Position = UDim2.new(0, _0xEB40.X - 60, 0, _0xEB40.Y + _0x4321 / 2 + 2)
_0xD9A2.Size = UDim2.new(0, 120, 0, 14)
_0xD9A2.Text = math.floor(_0x212C) .."m"_0xD9A2.TextColor3 = _0x6E73
else
_0xD9A2.Visible = false
end
local _0x27A6 = _0x7D61:FindFirstChildOfClass("Humanoid")
local _0xBD97 = _0x27A6 and _0x27A6.Health or 100
local _0x3FB9 = _0x27A6 and math.max(_0x27A6.MaxHealth, 1) or 100
local _0x8785 = _0x7D61:GetAttribute("Health") or _0x7D61:GetAttribute("hp") or _0x7D61:GetAttribute("HP")
local _0x07C4 = _0x7D61:GetAttribute("MaxHealth") or _0x7D61:GetAttribute("maxHealth") or _0x7D61:GetAttribute("MaxHP")
if _0x8785 and tonumber(_0x8785) then
_0xBD97 = tonumber(_0x8785)
if _0x07C4 and tonumber(_0x07C4) then
_0x3FB9 = math.max(tonumber(_0x07C4), 1)
end
end
local _0x3BEA = math.clamp(_0xBD97 / _0x3FB9, 0, 1)
if _0xCE74.Health then
_0xF0EA.Visible = true
local _0x7451 = 3
_0xF0EA.Size = UDim2.new(0, _0x7451, 0, _0x4321)
_0xF0EA.Position = UDim2.new(0, _0xEB40.X - _0x7CAA / 2 - 6, 0, _0xEB40.Y - _0x4321 / 2)
_0x5E9E.Size = UDim2.new(1, 0, _0x3BEA, 0)
_0x5E9E.Position = UDim2.new(0, 0, 1 - _0x3BEA, 0)
local _0xB4F3 = math.floor(math.clamp(2 * (1 - _0x3BEA), 0, 1) * 255)
local _0xBCD6 = math.floor(math.clamp(2 * _0x3BEA, 0, 1) * 255)
_0x5E9E.BackgroundColor3 = Color3.fromRGB(_0xB4F3, _0xBCD6, 50)
else
_0xF0EA.Visible = false
end
if _0xCE74.PV then
local _0x0EA7 = math.floor(_0xBD97 + 0.5)
_0xC3F7.Visible = true
if _0x8F52 ~= _0x0EA7 then
_0x8F52 = _0x0EA7
_0xC3F7.Text = tostring(_0x0EA7) .." PV"local _0xB4F3 = math.floor(math.clamp(2 * (1 - _0x3BEA), 0, 1) * 255)
local _0xBCD6 = math.floor(math.clamp(2 * _0x3BEA, 0, 1) * 255)
_0xC3F7.TextColor3 = Color3.fromRGB(_0xB4F3, _0xBCD6, 60)
end
_0xC3F7.Size = UDim2.new(0, 48, 0, 14)
_0xC3F7.Position = UDim2.new(0, _0xEB40.X - _0x7CAA / 2 - 28, 0, _0xEB40.Y + _0x4321 / 2 + 2)
else
_0xC3F7.Visible = false
end
local _0xAE24 = _0x7D61:FindFirstChild("Head")
if _0xCE74.Head and _0xAE24 and _0xAE24:IsA("BasePart") then
local _0x696E, _0xAE42 = _0x0DA0:WorldToViewportPoint(_0xAE24.Position)
if _0xAE42 and _0x696E.Z > 0 then
local _0x992D = (_0xAE24.Size and _0xAE24.Size.X > 0.1) and (_0xAE24.Size.X * 0.52) or 0.65
local _0x5CE7 = _0x0DA0:WorldToViewportPoint(_0xAE24.Position + _0x0DA0.CFrame.RightVector * _0x992D)
local _0x3BF0 = (Vector2.new(_0x5CE7.X, _0x5CE7.Y) - Vector2.new(_0x696E.X, _0x696E.Y)).Magnitude
local _0xBE35 = math.clamp(_0x3BF0, 1.2, 26)
local _0x4772 = (_0xBE35 < 3.5) and 1 or 1.5
local _0xDFC9 = {}
for i = 0, 5 do
local _0xE649 = math.rad(i * 60)
_0xDFC9[i + 1] = Vector2.new(
_0x696E.X + math.cos(_0xE649) * _0xBE35,
_0x696E.Y + math.sin(_0xE649) * _0xBE35
)
end
for i = 1, 6 do
local _0xB6A1 = _0xDFC9[i]
local _0x542C = _0xDFC9[(i % 6) + 1]
local _0x6B56 = (_0xB6A1 + _0x542C) * 0.5
local _0x6640 = (_0x542C - _0xB6A1).Magnitude
local _0x7EDB = math.deg(math.atan2(_0x542C.Y - _0xB6A1.Y, _0x542C.X - _0xB6A1.X))
local _0x0D1B = _0x3ED8[i]
_0x0D1B.BackgroundColor3 = _0x6E73
_0x0D1B.Size = UDim2.new(0, _0x6640 + 0.5, 0, _0x4772)
_0x0D1B.Position = UDim2.new(0, _0x6B56.X, 0, _0x6B56.Y)
_0x0D1B.Rotation = _0x7EDB
_0x0D1B.Visible = true
end
local _0x1D1A = _0x7D61:FindFirstChild("UpperTorso") or _0x7D61:FindFirstChild("Torso") or _0x7D61:FindFirstChild("HumanoidRootPart")
if _0x1D1A and _0x1D1A:IsA("BasePart") then
local _0xC9A4, _0xFCB9 = _0x0DA0:WorldToViewportPoint(_0x1D1A.Position)
if _0xFCB9 and _0xC9A4.Z > 0 then
local _0xB847 = Vector2.new(_0x696E.X, _0x696E.Y + _0xBE35 * 0.866)
local _0x2FEB = Vector2.new(_0xC9A4.X, _0xC9A4.Y)
local _0xF07C = (_0x2FEB - _0xB847).Magnitude
if _0xF07C > 2.5 then
local _0x31C9 = math.deg(math.atan2(_0x2FEB.Y - _0xB847.Y, _0x2FEB.X - _0xB847.X))
local _0x84A3 = (_0xB847 + _0x2FEB) * 0.5
_0xB01E.Visible = true
_0xB01E.BackgroundColor3 = _0x6E73
_0xB01E.Size = UDim2.new(0, _0xF07C, 0, _0x4772)
_0xB01E.Position = UDim2.new(0, _0x84A3.X, 0, _0x84A3.Y)
_0xB01E.Rotation = _0x31C9
else
_0xB01E.Visible = false
end
else
_0xB01E.Visible = false
end
else
_0xB01E.Visible = false
end
else
for _0xD694, _0x0D1B in ipairs(_0x3ED8) do _0x0D1B.Visible = false end
_0xB01E.Visible = false
end
else
for _0xD694, _0x0D1B in ipairs(_0x3ED8) do _0x0D1B.Visible = false end
_0xB01E.Visible = false
end
if _0xCE74.Skeleton then
local function _0xFB0B(_0x8FDA)
local _0xA893 = _0x7D61:FindFirstChild(_0x8FDA)
if _0xA893 and _0xA893:IsA("BasePart") then return _0xA893 end
if _0x8FDA =="UpperTorso"or _0x8FDA =="LowerTorso"then
local _0x341D = _0x7D61:FindFirstChild("Torso") or _0x7D61:FindFirstChild("HumanoidRootPart")
if _0x341D and _0x341D:IsA("BasePart") then return _0x341D end
elseif _0x8FDA =="Torso"then
local _0x341D = _0x7D61:FindFirstChild("UpperTorso") or _0x7D61:FindFirstChild("LowerTorso") or _0x7D61:FindFirstChild("HumanoidRootPart")
if _0x341D and _0x341D:IsA("BasePart") then return _0x341D end
elseif _0x8FDA =="Left Arm"or _0x8FDA =="LeftArm"then
local _0x341D = _0x7D61:FindFirstChild("LeftArm") or _0x7D61:FindFirstChild("Left Upper Arm") or _0x7D61:FindFirstChild("LeftUpperArm") or _0x7D61:FindFirstChild("Left Arm")
if _0x341D and _0x341D:IsA("BasePart") then return _0x341D end
elseif _0x8FDA =="Right Arm"or _0x8FDA =="RightArm"then
local _0x341D = _0x7D61:FindFirstChild("RightArm") or _0x7D61:FindFirstChild("Right Upper Arm") or _0x7D61:FindFirstChild("RightUpperArm") or _0x7D61:FindFirstChild("Right Arm")
if _0x341D and _0x341D:IsA("BasePart") then return _0x341D end
elseif _0x8FDA =="Left Leg"or _0x8FDA =="LeftLeg"then
local _0x341D = _0x7D61:FindFirstChild("LeftLeg") or _0x7D61:FindFirstChild("Left Upper Leg") or _0x7D61:FindFirstChild("LeftUpperLeg") or _0x7D61:FindFirstChild("Left Leg")
if _0x341D and _0x341D:IsA("BasePart") then return _0x341D end
elseif _0x8FDA =="Right Leg"or _0x8FDA =="RightLeg"then
local _0x341D = _0x7D61:FindFirstChild("RightLeg") or _0x7D61:FindFirstChild("Right Upper Leg") or _0x7D61:FindFirstChild("RightUpperLeg") or _0x7D61:FindFirstChild("Right Leg")
if _0x341D and _0x341D:IsA("BasePart") then return _0x341D end
end
return nil
end
local _0xE40D = (_0x27A6 and _0x27A6.RigType == Enum.HumanoidRigType.R15) or (_0x7D61:FindFirstChild("UpperTorso") ~= nil)
local _0x54CA = _0xE40D and {
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
local _0x055F = 0
for _0xD694, pair in ipairs(_0x54CA) do
local _0x1622 = (pair[1] =="Head"or pair[2] =="Head")
if not (_0xCE74.Head and _0x1622) then
local _0xEC0F = _0xFB0B(pair[1])
local _0xFDD2 = _0xFB0B(pair[2])
if _0xEC0F and _0xFDD2 then
local _0x0602, _0xE735 = _0x0DA0:WorldToViewportPoint(_0xEC0F.Position)
local _0x4C7F, _0x066C = _0x0DA0:WorldToViewportPoint(_0xFDD2.Position)
if (_0xE735 or _0x066C) and _0x0602.Z > 0 and _0x4C7F.Z > 0 then
_0x055F = _0x055F + 1
local _0xF325 = _0x0546[_0x055F]
if not _0xF325 then
_0xF325 = _0x9EB0("Frame", {
BorderSizePixel = 0,
AnchorPoint = Vector2.new(0.5, 0.5),
Parent = _0x0861,
})
_0x0546[_0x055F] = _0xF325
end
local _0x7014 = (Vector2.new(_0x4C7F.X, _0x4C7F.Y) - Vector2.new(_0x0602.X, _0x0602.Y)).Magnitude
local _0x05B2 = math.atan2(_0x4C7F.Y - _0x0602.Y, _0x4C7F.X - _0x0602.X)
_0xF325.BackgroundColor3 = _0x6E73
_0xF325.Size = UDim2.new(0, _0x7014, 0, 1.5)
_0xF325.Position = UDim2.new(0, (_0x0602.X + _0x4C7F.X) / 2, 0, (_0x0602.Y + _0x4C7F.Y) / 2)
_0xF325.Rotation = math.deg(_0x05B2)
_0xF325.Visible = true
end
end
end
end
for i = _0x055F + 1, #_0x0546 do
_0x0546[i].Visible = false
end
else
for _0xD694, _0xF325 in ipairs(_0x0546) do
_0xF325.Visible = false
end
end
if _0xCE74.Tracer then
local _0x4FE7 = _0x0DA0.ViewportSize
local _0xCE37 = Vector2.new(_0x4FE7.X / 2, _0x4FE7.Y)
if _0xCE74.TracerOrigin =="Center"then
_0xCE37 = Vector2.new(_0x4FE7.X / 2, _0x4FE7.Y / 2)
elseif _0xCE74.TracerOrigin =="Mouse"then
_0xCE37 = _0x78ED:GetMouseLocation()
end
local _0xC289 = Vector2.new(_0xEB40.X, _0xEB40.Y + _0x4321 / 2)
local _0x7014 = (_0xC289 - _0xCE37).Magnitude
local _0x05B2 = math.atan2(_0xC289.Y - _0xCE37.Y, _0xC289.X - _0xCE37.X)
_0xD0EA.Visible = true
_0xD0EA.Size = UDim2.new(0, _0x7014, 0, 1.5)
_0xD0EA.Position = UDim2.new(0, (_0xCE37.X + _0xC289.X) / 2, 0, (_0xCE37.Y + _0xC289.Y) / 2)
_0xD0EA.Rotation = math.deg(_0x05B2)
_0xD0EA.BackgroundColor3 = _0x6E73
else
_0xD0EA.Visible = false
end
if _0xCE74.Glow then
if _0xC9CA.Parent ~= _0x7D61 then
_0xC9CA.Parent = _0x7D61
end
_0xC9CA.Enabled = true
_0xC9CA.FillColor = _0x6E73
_0xC9CA.OutlineColor = _0x6E73
else
if _0xC9CA.Parent ~= nil then
_0xC9CA.Parent = nil
end
end
end)
end
local function _0x7854()
for obj in pairs(_0xA941) do
_0x4B1E(obj)
end
if not _0xCE74.Enabled then return end
for _0xD694, _0xA893 in ipairs(_0x4BB9:GetPlayers()) do
if _0xA893 ~= _0x2471 then
_0x08F0(_0xA893, nil, true)
end
end
if _0xCE74.NPC then
for _0xD694, obj in ipairs(workspace:GetChildren()) do
if obj:IsA("Model") and obj ~= _0x2471.Character and not _0x4BB9:GetPlayerFromCharacter(obj) then
if obj:FindFirstChildOfClass("Humanoid") then
_0x08F0(obj,"[BOT] ".. obj.Name, false)
end
end
end
end
end
_0x1506(_0x4BB9.PlayerAdded:Connect(function(_0xA893)
if _0xCE74.Enabled and _0xA893 ~= _0x2471 then
_0xA893.CharacterAdded:Connect(function()
task.wait(0.5)
_0x08F0(_0xA893, nil, true)
end)
end
end))
_0x1506(_0x4BB9.PlayerRemoving:Connect(function(_0xA893)
_0x4B1E(_0xA893)
end))
do
local _0x1282 = _0x5661["Visual"]
local _0x9754 = _0x9EB0("Frame", {
Size = UDim2.new(0, _0xC0F8, 0, 0),
Position = UDim2.new(0, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex = 14,
Parent = _0x1282,
})
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = _0x9754 })
local _0x4948 = _0x9EB0("Frame", {
Size = UDim2.new(0, _0xC0F8, 0, 0),
Position = UDim2.new(0, 366, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex = 14,
Parent = _0x1282,
})
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = _0x4948 })
local _0xD694, _0x556B = _0xA737(_0x9754,"Player ESP", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 5), Parent = _0x556B })
_0xC513(_0x556B,"Enable ESP", false, function(v)
_0xCE74.Enabled = v
_0x7854()
end)
_0xC513(_0x556B,"Team Check", false, function(v)
_0xCE74.TeamCheck = v
end)
_0xC513(_0x556B,"Lock Bots (NPC ESP)", false, function(v)
_0xCE74.NPC = v
_0x7854()
end)
_0xC513(_0x556B,"Box ESP", false, function(v)
_0xCE74.Box = v
end)
_0xC513(_0x556B,"Skeleton ESP", false, function(v)
_0xCE74.Skeleton = v
end)
_0xC513(_0x556B,"Health Bar", false, function(v)
_0xCE74.Health = v
end)
_0xC513(_0x556B,"Health PV Text", false, function(v)
_0xCE74.PV = v
end)
_0xC513(_0x556B,"Head ESP", false, function(v)
_0xCE74.Head = v
end)
_0xC513(_0x556B,"Name ESP", false, function(v)
_0xCE74.Name = v
end)
_0xC513(_0x556B,"Distance ESP", false, function(v)
_0xCE74.Dist = v
end)
_0xC513(_0x556B,"AFK ESP", false, function(v)
_0xCE74.AFK = v
end)
_0xC513(_0x556B,"Tracer ESP", false, function(v)
_0xCE74.Tracer = v
end)
_0x493D(_0x556B,"Tracer Origin", {"Bottom","Center","Mouse"}, function(v)
_0xCE74.TracerOrigin = v
end)
_0xC513(_0x556B,"Chams (Glow)", false, function(v)
_0xCE74.Glow = v
end)
_0x44DE(_0x556B,"ESP Max Distance", 1000, 50, 2000,"studs", function(v)
_0xCE74.MaxDistance = v
end)
_0x7742(_0x9754,"ESP Color Palette", _0x4074.Accent, function(c)
_0xCE74.Color = c
end)
local _0xD694, _0x450B = _0xA737(_0x4948,"World & Visuals", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 6), Parent = _0x450B })
_0x44DE(_0x450B,"Field of View", 70, 50, 120,"deg", function(v)
_0xF6F4 = v
_0x1A61 = true
if workspace.CurrentCamera then
workspace.CurrentCamera.FieldOfView = _0xF6F4
end
end)
_0xC513(_0x450B,"Fullbright", false, function(v)
if v then
_0x7EAE.Brightness = 2
_0x7EAE.ClockTime = 14
_0x7EAE.FogEnd = 9e9
_0x7EAE.GlobalShadows = false
else
_0x7EAE.Brightness = 1
_0x7EAE.GlobalShadows = true
end
end)
_0xC513(_0x450B,"Remove Fog", false, function(v)
if v then _0x7EAE.FogEnd = 9e9 _0x7EAE.FogStart = 9e9 end
end)
_0xC513(_0x450B,"Remove Shadows", false, function(v)
_0x7EAE.GlobalShadows = not v
end)
local _0xD694, _0xB81C = _0xA737(_0x4948,"Custom Crosshair", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 5), Parent = _0xB81C })
_0xC513(_0xB81C,"Enable Crosshair", false, function(v)
_0x2E37.Enabled = v
_0x0AD8()
end)
_0xC513(_0xB81C,"Afficher Lignes (Lines)", true, function(v)
_0x2E37.Lines = v
_0x0AD8()
end)
_0xC513(_0xB81C,"Afficher Point (Center Dot)", false, function(v)
_0x2E37.Dot = v
_0x0AD8()
end)
_0x44DE(_0xB81C,"Crosshair Size", 14, 4, 50,"px", function(v)
_0x2E37.Size = v
_0x0AD8()
end)
_0x44DE(_0xB81C,"Crosshair Thickness", 2, 1, 6,"px", function(v)
_0x2E37.Thickness = v
_0x0AD8()
end)
_0x7742(_0xB81C,"Crosshair Color", _0x2E37.Color, function(c)
_0x2E37.Color = c
_0x0AD8()
end)
end
do
local _0x0F40 = _0x5661["Settings"]
local _0xACEA = _0x9EB0("Frame", {
Size = UDim2.new(0, _0xC0F8, 0, 0),
Position = UDim2.new(0, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex = 14,
Parent = _0x0F40,
})
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = _0xACEA })
local _0x5102 = _0x9EB0("Frame", {
Size = UDim2.new(0, _0xC0F8, 0, 0),
Position = UDim2.new(0, 366, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex = 14,
Parent = _0x0F40,
})
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = _0x5102 })
local _0xD694, _0x982B = _0xA737(_0xACEA,"Menu Control", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 6), Parent = _0x982B })
_0xFDAC(_0x982B,"Menu Toggle Key", _0xD04E.Name, function(newKey)
if newKey and typeof(newKey) =="EnumItem"then
_0xD04E = newKey
_0x5C21("Toggle Key: ".. newKey.Name, _0x4074.Accent)
end
end)
_0x583C(_0x982B,"Reset Menu Position", UDim2.new(1, 0, 0, 32), nil, function()
_0x51E6.Position = _0xB145
_0x7A7A = _0xB145
end)
_0x583C(_0x982B,"Unload Menu", UDim2.new(1, 0, 0, 32), nil, function()
if _0x4DEF then _0x4DEF() end
end, true)
local _0xD694, _0x64E1 = _0xA737(_0xACEA,"Client Telemetry", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 5), Parent = _0x64E1 })
local _0x3A43 = _0x205E(_0x64E1,"Framerate","60 FPS")
local _0x8E06 = _0x205E(_0x64E1,"Latency","35 ms")
local _0x29F8 = _0x205E(_0x64E1,"Memory Usage","120 MB")
local _0x6322 = 0
local _0x64AD = tick()
_0x1506(_0x5B09.RenderStepped:Connect(function()
_0x6322 = _0x6322 + 1
local _0xBE9C = tick()
if _0xBE9C - _0x64AD >= 1 then
local _0xE566 = math.floor(_0x6322 / (_0xBE9C - _0x64AD))
_0x3A43.Text = tostring(_0xE566) .." FPS"_0x6322 = 0
_0x64AD = _0xBE9C
pcall(function()
local _0x907B = math.floor(_0x35D2.Network.ServerStatsItem["Data Ping"]:GetValue())
_0x8E06.Text = tostring(_0x907B) .." ms"end)
pcall(function()
local _0xF85F = math.floor(_0x35D2:GetTotalMemoryUsageMb())
_0x29F8.Text = tostring(_0xF85F) .." MB"end)
end
end))
local _0xD694, _0x9A11 = _0xA737(_0x5102,"Configuration System", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 6), Parent = _0x9A11 })
local _0x0C44 = _0x9EB0("TextBox", {
Name ="ConfigNameInput",
Size = UDim2.new(1, 0, 0, 28),
BackgroundColor3 = _0x4074.ButtonBg,
BorderSizePixel = 0,
Text ="default",
PlaceholderText ="Enter config name...",
TextColor3 = _0x4074.TextWhite,
PlaceholderColor3 = _0x4074.TextMuted,
TextSize = 12,
Font = Enum.Font.GothamMedium,
ClearTextOnFocus = false,
ZIndex = 16,
Parent = _0x9A11,
})
_0xD30C(_0x0C44, 6)
_0xFC1A(_0x0C44, _0x4074.CardStroke, 1)
local _0x21A2 ="Novak_Configs"local function _0xA08E()
return writefile and readfile and isfile and delfile
end
local function _0x2C95(_0x8FDA)
local _0x381D = {
Toggles = _0x73F7,
Sliders = _0x382E,
Keybinds = _0x3353,
_0xD04E = _0xD04E.Name,
}
local _0xDFFB = _0x473F:JSONEncode(_0x381D)
if _0xA08E() then
if makefolder and not isfolder(_0x21A2) then pcall(makefolder, _0x21A2) end
pcall(writefile, _0x21A2 .."/".. _0x8FDA ..".json", _0xDFFB)
_0x5C21("Config '".. _0x8FDA .."' sauvegardee !", _0x4074.Accent)
else
local _0x26A8 = (getgenv and getgenv()) or _G
_0x26A8["NOVAK_CFG_".. _0x8FDA] = _0xDFFB
_0x5C21("Config '".. _0x8FDA .."' sauvegardee (memoire)", _0x4074.Accent)
end
end
local function _0x02F3(_0x8FDA)
local _0xDFFB = nil
if _0xA08E() and isfile(_0x21A2 .."/".. _0x8FDA ..".json") then
local _0x432B, _0xD02D = pcall(readfile, _0x21A2 .."/".. _0x8FDA ..".json")
if _0x432B then _0xDFFB = _0xD02D end
else
local _0x26A8 = (getgenv and getgenv()) or _G
_0xDFFB = _0x26A8["NOVAK_CFG_".. _0x8FDA]
end
if not _0xDFFB then
_0x5C21("Erreur: Config '".. _0x8FDA .."' introuvable", _0x4074.Red)
return
end
local _0x432B, _0x381D = pcall(function() return _0x473F:JSONDecode(_0xDFFB) end)
if _0x432B and _0x381D then
if _0x381D.Toggles then
for k, v in pairs(_0x381D.Toggles) do
if _0xFD19[k] then _0xFD19[k].Set(v) end
end
end
if _0x381D.Sliders then
for k, v in pairs(_0x381D.Sliders) do
if _0x0415[k] then _0x0415[k].Set(v) end
end
end
if _0x381D.Keybinds then
for k, v in pairs(_0x381D.Keybinds) do
if _0xAD9B[k] then _0xAD9B[k].Set(v) end
end
end
if _0x381D.ToggleKey and Enum.KeyCode[_0x381D.ToggleKey] then
_0xD04E = Enum.KeyCode[_0x381D.ToggleKey]
end
_0x5C21("Config '".. _0x8FDA .."' chargee avec succes !", _0x4074.Accent)
end
end
local _0x78C7 = _0x9EB0("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = _0x9A11 })
_0x583C(_0x78C7,"Sauvegarder", UDim2.new(0.5, -3, 1, 0), UDim2.new(0, 0, 0, 0), function()
local _0x8FDA = _0x0C44.Text:gsub("[^%w_%-]","")
if _0x8FDA ==""then _0x8FDA ="default"end
_0x2C95(_0x8FDA)
end, true)
_0x583C(_0x78C7,"Charger", UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0), function()
local _0x8FDA = _0x0C44.Text:gsub("[^%w_%-]","")
if _0x8FDA ==""then _0x8FDA ="default"end
_0x02F3(_0x8FDA)
end, true)
local _0x8936 = _0x9EB0("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = _0x9A11 })
_0x583C(_0x8936,"Supprimer", UDim2.new(0.5, -3, 1, 0), UDim2.new(0, 0, 0, 0), function()
local _0x8FDA = _0x0C44.Text:gsub("[^%w_%-]","")
if _0xA08E() and isfile(_0x21A2 .."/".. _0x8FDA ..".json") then
pcall(delfile, _0x21A2 .."/".. _0x8FDA ..".json")
_0x5C21("Config '".. _0x8FDA .."' supprimee", _0x4074.Accent)
else
local _0x26A8 = (getgenv and getgenv()) or _G
_0x26A8["NOVAK_CFG_".. _0x8FDA] = nil
_0x5C21("Config '".. _0x8FDA .."' supprimee", _0x4074.Accent)
end
end, true)
_0x583C(_0x8936,"Par Defaut", UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0), function()
for _0xD694, _0xA7B7 in pairs(_0xFD19) do _0xA7B7.Set(false) end
_0x5C21("Parametres reinitialises par defaut", _0x4074.Accent)
end, true)
local _0xD694, _0x0702 = _0xA737(_0x5102,"Performance Booster", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 6), Parent = _0x0702 })
_0x583C(_0x0702,"Ultimate FPS Boost", UDim2.new(1, 0, 0, 30), nil, function()
pcall(function()
if setfpscap then setfpscap(9999) end
_0x7EAE.GlobalShadows = false
_0x7EAE.FogEnd = 9e9
end)
task.spawn(function()
local _0xD50F = 0
for _0xD694, v in ipairs(workspace:GetDescendants()) do
if v:IsA("BasePart") then
v.Material = Enum.Material.Plastic
v.Reflectance = 0
v.CastShadow = false
elseif v:IsA("Decal") or v:IsA("Texture") then
pcall(function() v.Transparency = 1 end)
_0xD50F = _0xD50F + 1
elseif v:IsA("ParticleEmitter") or v:IsA("Sparkles") or v:IsA("Fire") or v:IsA("Smoke") then
pcall(function() v:Destroy() end)
_0xD50F = _0xD50F + 1
end
end
collectgarbage("collect")
_0x5C21("FPS Boost | ".. _0xD50F .." textures/particules nettoyees", _0x4074.Accent)
end)
end, true)
_0x583C(_0x0702,"Boost Memory (GC)", UDim2.new(1, 0, 0, 30), nil, function()
collectgarbage("collect")
_0x5C21("Memoire RAM liberee avec succes", _0x4074.Accent)
end, true)
_0xC513(_0x0702,"Disable 3D Rendering (AFK)", false, function(v)
pcall(function() _0x5B09:Set3dRenderingEnabled(not v) end)
end)
end
do
local _0x32FC = _0x5661["Help"]
local _0x5892 = _0x9EB0("Frame", {
Size = UDim2.new(0, _0xC0F8, 0, 0),
Position = UDim2.new(0, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex = 14,
Parent = _0x32FC,
})
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = _0x5892 })
local _0x463D = _0x9EB0("Frame", {
Size = UDim2.new(0, _0xC0F8, 0, 0),
Position = UDim2.new(0, 366, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex = 14,
Parent = _0x32FC,
})
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = _0x463D })
local _0xD694, _0x2138 = _0xA737(_0x5892,"Assistance & Support", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 8), Parent = _0x2138 })
local _0x24BC = _0x9EB0("TextLabel", {
Size = UDim2.new(1, 0, 0, 28),
BackgroundTransparency = 1,
Font = Enum.Font.Gotham,
Text ="Entrez votre message ou question ci-dessous pour l'envoyer directement au support via Webhook.",
TextColor3 = _0x4074.TextMuted,
TextSize = 11,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x2138,
})
local _0x0C38 = _0x9EB0("Frame", {
Size = UDim2.new(1, 0, 0, 110),
BackgroundColor3 = _0x4074.ButtonBg,
BorderSizePixel = 0,
ZIndex = 16,
Parent = _0x2138,
})
_0xD30C(_0x0C38, 6)
_0xFC1A(_0x0C38, _0x4074.CardStroke, 1)
local _0x8BF7 = _0x9EB0("TextBox", {
Size = UDim2.new(1, -16, 1, -14),
Position = UDim2.new(0, 8, 0, 7),
BackgroundTransparency = 1,
ClearTextOnFocus = false,
Font = Enum.Font.Gotham,
MultiLine = true,
PlaceholderColor3 = _0x4074.TextDark,
PlaceholderText ="Ecrivez votre message ici...",
Text ="",
TextColor3 = _0x4074.TextWhite,
TextSize = 12,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
TextYAlignment = Enum.TextYAlignment.Top,
ZIndex = 17,
Parent = _0x0C38,
})
local _0xC599 = _0x9EB0("TextLabel", {
Size = UDim2.new(1, 0, 0, 18),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text ="",
TextColor3 = _0x4074.TextMuted,
TextSize = 11,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x2138,
})
local _0x53CC ="https://ptb.discord.com/api/webhooks/1565080935937085503/IHSalYjJRUY_l5-Iee3do-SK92VKUvtBCU6CWnsL3uWCHgwPxJlHo7dktKLg5t7HQCnh"local _0x0A8A = false
_0x583C(_0x2138,"Envoyer", UDim2.new(1, 0, 0, 34), nil, function()
if _0x0A8A then return end
local _0xB345 = _0x8BF7.Text
local _0x1905 = string.gsub(_0xB345,"^%s*(.-)%s*$","%1")
if _0x1905 ==""then
_0xC599.Text ="Erreur : message vide !"_0xC599.TextColor3 = _0x4074.Red
return
end
_0x0A8A = true
_0xC599.Text ="Envoi en cours..."_0xC599.TextColor3 = _0x4074.AccentMuted
task.spawn(function()
local _0x7DA9 ="Unknown"pcall(function()
if identifyexecutor then
_0x7DA9 = identifyexecutor()
end
end)
local _0x3CA0 = {
embeds = {
{
title ="NOVAK | Message de Support",
description = _0x1905,
color = 0,
fields = {
{
_0x8FDA ="Joueur",
value = tostring(_0x2471.Name) .." (".. tostring(_0x2471.UserId) ..")",
inline = true
},
{
_0x8FDA ="Place ID",
value = tostring(game.PlaceId) .." (JobId: `".. tostring(game.JobId) .."`)",
inline = true
},
{
_0x8FDA ="Executeur",
value = tostring(_0x7DA9),
inline = true
},
{
_0x8FDA ="Profil",
value ="https://www.roblox.com/users/".. tostring(_0x2471.UserId) .."/profile",
inline = false
},
{
_0x8FDA ="Date",
value = os.date("!%Y-%m-%d %H:%M:%SZ"),
inline = true
}
},
footer = {
text ="Novak Help Desk"}
}
}
}
local _0x6F4D = _0x473F:JSONEncode(_0x3CA0)
local _0xF931 = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local _0x8CFF = false
if _0xF931 then
local _0x0243, _0xFBD9 = pcall(function()
return _0xF931({
Url = _0x53CC,
Method ="POST",
Headers = {
["Content-Type"] ="application/json"},
_0x7ECE = _0x6F4D
})
end)
if _0x0243 and _0xFBD9 and (_0xFBD9.StatusCode == 200 or _0xFBD9.StatusCode == 204 or _0xFBD9.Status == 200 or _0xFBD9.Status == 204) then
_0x8CFF = true
elseif _0x0243 then
_0x8CFF = true
end
elseif _0x473F and _0x473F.PostAsync then
local _0x0243 = pcall(function()
_0x473F:PostAsync(_0x53CC, _0x6F4D, Enum.HttpContentType.ApplicationJson)
end)
_0x8CFF = _0x0243
end
if _0x8CFF then
_0x8BF7.Text =""_0xC599.Text ="Message envoye avec succes !"_0xC599.TextColor3 = _0x4074.Green
_0x5C21("Message envoye avec succes au webhook !", _0x4074.Accent)
else
_0xC599.Text ="Erreur lors de l'envoi du webhook !"_0xC599.TextColor3 = _0x4074.Red
_0x5C21("Echec de l'envoi du message", _0x4074.Red)
end
task.wait(2)
_0x0A8A = false
end)
end, true)
local _0xD694, _0x30B2 = _0xA737(_0x463D,"Assistance Novak", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 8), Parent = _0x30B2 })
local _0x4020 = _0x9EB0("Frame", {
Size = UDim2.new(1, 0, 0, 56),
BackgroundColor3 = _0x4074.ButtonBg,
BorderSizePixel = 0,
ZIndex = 16,
Parent = _0x30B2,
})
_0xD30C(_0x4020, 6)
_0xFC1A(_0x4020, _0x4074.CardStroke, 1)
local _0xA109 = _0x9EB0("Frame", {
Size = UDim2.new(0, 40, 0, 40),
Position = UDim2.new(0, 8, 0.5, -20),
BackgroundColor3 = Color3.fromRGB(18, 18, 24),
BorderSizePixel = 0,
ZIndex = 17,
Parent = _0x4020,
})
_0xD30C(_0xA109, 8)
_0xFC1A(_0xA109, _0x4074.CardStroke, 1)
local _0xF286 = _0x9EB0("ImageLabel", {
Size = UDim2.new(1, -6, 1, -6),
Position = UDim2.new(0, 3, 0, 3),
BackgroundTransparency = 1,
Image ="rbxassetid://10723406988",
ImageColor3 = _0x4074.Accent,
ZIndex = 18,
Parent = _0xA109,
})
local _0xE83D = _0x9EB0("TextLabel", {
Size = UDim2.new(1, -60, 0, 20),
Position = UDim2.new(0, 56, 0, 8),
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
Text ="Novak Help Desk",
TextColor3 = _0x4074.TextWhite,
TextSize = 13,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 17,
Parent = _0x4020,
})
local _0x68C7 = _0x9EB0("TextLabel", {
Size = UDim2.new(1, -60, 0, 16),
Position = UDim2.new(0, 56, 0, 28),
BackgroundTransparency = 1,
Font = Enum.Font.Gotham,
Text ="Support direct via Webhook",
TextColor3 = _0x4074.TextMuted,
TextSize = 11,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 17,
Parent = _0x4020,
})
local _0xD694, _0x5923 = _0xA737(_0x463D,"Informations", UDim2.new(1, 0, 0, 0))
_0x9EB0("UIListLayout", { Padding = UDim.new(0, 6), Parent = _0x5923 })
_0x9EB0("TextLabel", {
Size = UDim2.new(1, 0, 0, 20),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text ="Compte : ".. tostring(_0x2471.Name),
TextColor3 = _0x4074.TextWhite,
TextSize = 12,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x5923,
})
_0x9EB0("TextLabel", {
Size = UDim2.new(1, 0, 0, 20),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text ="User ID : ".. tostring(_0x2471.UserId),
TextColor3 = _0x4074.TextMuted,
TextSize = 11,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x5923,
})
_0x9EB0("TextLabel", {
Size = UDim2.new(1, 0, 0, 20),
BackgroundTransparency = 1,
Font = Enum.Font.GothamMedium,
Text ="Place ID : ".. tostring(game.PlaceId),
TextColor3 = _0x4074.TextMuted,
TextSize = 11,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x5923,
})
_0x9EB0("TextLabel", {
Size = UDim2.new(1, 0, 0, 36),
BackgroundTransparency = 1,
Font = Enum.Font.Gotham,
Text ="Utilisez ce panneau pour remonter un bug, demander de l'aide ou contacter le developpeur.",
TextColor3 = _0x4074.TextDark,
TextSize = 10,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 16,
Parent = _0x5923,
})
end
local _0x014C = true
local _0x640A = false
local function _0x254E()
if _0x640A then return end
_0x640A = true
_0x014C = not _0x014C
if _0x014C then
_0x51E6.Visible = true
_0x51E6.Position = _0x7A7A + UDim2.new(0, 0, 0, 15)
_0x51E6.Size = UDim2.new(0, 920, 0, 570)
local _0x750E = _0x0FDE(_0x51E6, 0.28, {
Position = _0x7A7A,
Size = UDim2.new(0, 920, 0, 600),
}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
_0x750E.Completed:Wait()
_0x640A = false
else
local _0xB6A0 = _0x0FDE(_0x51E6, 0.22, {
Position = _0x7A7A + UDim2.new(0, 0, 0, 15),
Size = UDim2.new(0, 920, 0, 550),
}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
_0xB6A0.Completed:Wait()
if not _0x014C then
_0x51E6.Visible = false
end
_0x640A = false
end
end
_0x4DEF = function()
if _0x373F then return end
_0x373F = true
pcall(function() _0x5B09:UnbindFromRenderStep("NovakAimbot") end)
pcall(function() _0x5B09:UnbindFromRenderStep("NovakFOV") end)
if _0x3F28 then pcall(function() _0x3F28:Disconnect() end) end
pcall(function()
for v, tbl in pairs(_0x8996) do
for k, old in pairs(tbl) do rawset(v, k, old) end
end
for v, tbl in pairs(_0xE850) do
for k, old in pairs(tbl) do rawset(v, k, old) end
end
for v, tbl in pairs(_0x2054) do
for k, old in pairs(tbl) do rawset(v, k, old) end
end
end)
for _0xD694, _0x18F0 in ipairs(_0xE756) do
pcall(function() _0x18F0:Disconnect() end)
end
_0x92CA()
pcall(function()
_0x7EAE.GlobalShadows = true
_0x7EAE.Brightness = 1
_0x7EAE.FogEnd = 100000
if workspace.CurrentCamera then
workspace.CurrentCamera.FieldOfView = 70
end
end)
pcall(function() _0x7DDD:Destroy() end)
pcall(function() _0x3B96:Destroy() end)
pcall(function() _0xA041:Destroy() end)
pcall(function() _0x4759:Destroy() end)
end
_0x1506(_0x78ED.InputBegan:Connect(function(input, gp)
if gp then return end
if input.KeyCode == _0xD04E then
_0x254E()
end
end))
_0x5C21("Novak V2.3 charge avec succes ! [Insert]", _0x4074.Accent)
