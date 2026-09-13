-- language: Lua, target: Roblox (Delta / Solara / Script-Ware / Wave) — PC + mobile
-- BTC Admin Panel v1.8 — kill module, remote scanner, mobile-tuned, Discord card
-- GitHub-loadable: loadstring(game:HttpGet("..."))()
-- discord: https://discord.gg/57mYmMwRuH

return (function()

local function unhex(h)
    return (h:gsub("%x%x", function(c) return string.char(tonumber(c, 16)) end))
end

local N = {
    PANEL   = unhex("4254435f50616e656c"),
    ESP_TAG = unhex("4254435f4553505f546167"),
    HL      = unhex("4254435f484c"),
    FLY_BV  = unhex("4254435f466c79"),
    FLY_GY  = unhex("4254435f466c794779726f"),
}

local S = {
    version = unhex("312e38"),
    flags   = {},
    conns   = {},
    tabs    = {},
    silent  = {
        enabled = false, remotes = {}, teamCheck = false,
        fov = 200, predict = true, target = nil, old = nil,
    },
    kill    = {
        remote      = nil,
        argKind     = "Player",   -- Player | Character | HumanoidRootPart | Head
        loop        = false,
        rate        = 10,
        jitter      = true,
        target      = nil,
        candidates  = {},
    },
    clean   = { hide = true },
    saved   = {},
    discord = unhex("68747470733a2f2f646973636f72642e67672f35376d596d4d77527548"),
}

local ref = setmetatable({ v = S }, {
    __index = function(t, k) return rawget(t, "v")[k] end,
})

local function bind(fn)
    local r = ref
    return function(...) return fn(r, ...) end
end

local function track(c, tag)
    S.conns[#S.conns + 1] = { c = c, t = tag or 0 }
    return c
end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local Lighting   = game:GetService("Lighting")
local Workspace  = game:GetService("Workspace")
local HttpSvc    = game:GetService("HttpService")
local CoreGui    = game:GetService("CoreGui")
local Teleport   = game:GetService("TeleportService")
local VUser      = game:GetService("VirtualUser")
local Replicated = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- mobile detection
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- mobile-tuned sizing
local SCALE   = IS_MOBILE and 0.85 or 1
local PANEL_W = math.floor(560 * (IS_MOBILE and 1.05 or 1))
local PANEL_H = math.floor(380 * (IS_MOBILE and 1.15 or 1))
local BTN_H   = IS_MOBILE and 34 or 28
local TXT_S   = IS_MOBILE and 13 or 12
local SEC_S   = IS_MOBILE and 12 or 11
local TAB_W   = IS_MOBILE and 110 or 120

pcall(function()
    local old = CoreGui:FindFirstChild(N.PANEL)
    if old then old:Destroy() end
end)

local GUI = Instance.new("ScreenGui")
GUI.Name = N.PANEL
GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local ok = pcall(function() GUI.Parent = CoreGui end)
if not ok or not GUI.Parent then
    GUI.Parent = LP:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
Main.Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local mstroke = Instance.new("UIStroke", Main)
mstroke.Color = Color3.fromRGB(60, 60, 70); mstroke.Thickness = 1

-- custom drag (works on mobile + PC)
do
    local dragging, dragStart, startPos = false, nil, nil
    local function beginDrag(input)
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
    local function moveDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    local function endDrag() dragging = false end

    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch then
            moveDrag(input)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            endDrag()
        end
    end)
end

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 34)
Top.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Top.BorderSizePixel = 0
Top.Parent = Main
Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 220, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BTC  ·  v" .. S.version
Title.TextColor3 = Color3.fromRGB(120, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
CloseBtn.Text = "x"
CloseBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Top
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 28)
MinBtn.Position = UDim2.new(1, -74, 0, 3)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Top
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, TAB_W, 1, -34)
Sidebar.Position = UDim2.new(0, 0, 0, 34)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SLayout = Instance.new("UIListLayout", Sidebar)
SLayout.SortOrder = Enum.SortOrder.LayoutOrder
SLayout.Padding = UDim.new(0, 4)

local SPad = Instance.new("UIPadding", Sidebar)
SPad.PaddingTop = UDim.new(0, 8)
SPad.PaddingLeft = UDim.new(0, 6)
SPad.PaddingRight = UDim.new(0, 6)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -(TAB_W + 6), 1, -44)
Content.Position = UDim2.new(0, TAB_W + 2, 0, 38)
Content.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Content.BorderSizePixel = 0
Content.Parent = Main
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 8)

local Minimized = false
MinBtn.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    Main.Size = Minimized and UDim2.new(0, PANEL_W, 0, 34) or UDim2.new(0, PANEL_W, 0, PANEL_H)
    Sidebar.Visible = not Minimized
    Content.Visible = not Minimized
end)

local function MakeTab(name)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, BTN_H + 2)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    Btn.Text = "  " .. name
    Btn.TextColor3 = Color3.fromRGB(190, 190, 200)
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = TXT_S
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.BorderSizePixel = 0
    Btn.Parent = Sidebar
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -12, 1, -12)
    Page.Position = UDim2.new(0, 6, 0, 6)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 95)
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.Parent = Content

    local L = Instance.new("UIListLayout", Page)
    L.SortOrder = Enum.SortOrder.LayoutOrder
    L.Padding = UDim.new(0, 6)

    local P = Instance.new("UIPadding", Page)
    P.PaddingTop = UDim.new(0, 4)
    P.PaddingLeft = UDim.new(0, 4)
    P.PaddingRight = UDim.new(0, 4)
    P.PaddingBottom = UDim.new(0, 4)

    S.tabs[name] = { Btn = Btn, Page = Page }

    Btn.MouseButton1Click:Connect(function()
        for n, t in pairs(S.tabs) do
            t.Page.Visible = (n == name)
            t.Btn.BackgroundColor3 = (n == name) and Color3.fromRGB(45, 45, 58) or Color3.fromRGB(30, 30, 38)
            t.Btn.TextColor3 = (n == name) and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(190, 190, 200)
        end
    end)

    return Page
end

local function MakeLabel(parent, text)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, 0, 0, 20)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Color3.fromRGB(150, 150, 165)
    L.Font = Enum.Font.GothamMedium
    L.TextSize = SEC_S
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = parent
    return L
end

local function MakeSection(parent, text)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, 0, 0, 24)
    L.BackgroundTransparency = 1
    L.Text = string.upper(text)
    L.TextColor3 = Color3.fromRGB(120, 200, 255)
    L.Font = Enum.Font.GothamBold
    L.TextSize = SEC_S
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = parent
    return L
end

local function MakeButton(parent, text, cb)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 0, BTN_H)
    B.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    B.Text = text
    B.TextColor3 = Color3.fromRGB(210, 210, 220)
    B.Font = Enum.Font.GothamMedium
    B.TextSize = TXT_S
    B.BorderSizePixel = 0
    B.Parent = parent
    Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)

    B.MouseEnter:Connect(function()
        Tween:Create(B, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(45, 45, 58) }):Play()
    end)
    B.MouseLeave:Connect(function()
        Tween:Create(B, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(30, 30, 40) }):Play()
    end)

    B.MouseButton1Click:Connect(function()
        local ok, err = pcall(cb)
        if not ok then warn("[BTC] button error: " .. tostring(err)) end
    end)
    return B
end

local function MakeToggle(parent, text, default, cb)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, 0, 0, BTN_H)
    Holder.BackgroundTransparency = 1
    Holder.Parent = parent

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(0.65, 0, 1, 0)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = Color3.fromRGB(210, 210, 220)
    L.Font = Enum.Font.GothamMedium
    L.TextSize = TXT_S
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = Holder

    local T = Instance.new("Frame")
    T.Size = UDim2.new(0, 44, 0, 22)
    T.Position = UDim2.new(1, -44, 0.5, -11)
    T.BackgroundColor3 = default and Color3.fromRGB(60, 140, 240) or Color3.fromRGB(50, 50, 60)
    T.BorderSizePixel = 0
    T.Parent = Holder
    Instance.new("UICorner", T).CornerRadius = UDim.new(1, 0)

    local D = Instance.new("Frame")
    D.Size = UDim2.new(0, 18, 0, 18)
    D.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    D.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    D.BorderSizePixel = 0
    D.Parent = T
    Instance.new("UICorner", D).CornerRadius = UDim.new(1, 0)

    local State = default
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 1, 0)
    B.BackgroundTransparency = 1
    B.Text = ""
    B.Parent = Holder

    B.MouseButton1Click:Connect(function()
        State = not State
        Tween:Create(T, TweenInfo.new(0.15), {
            BackgroundColor3 = State and Color3.fromRGB(60, 140, 240) or Color3.fromRGB(50, 50, 60)
        }):Play()
        Tween:Create(D, TweenInfo.new(0.15), {
            Position = State and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }):Play()
        local ok, err = pcall(cb, State)
        if not ok then warn("[BTC] toggle error: " .. tostring(err)) end
    end)

    return function() return State end
end

local ActiveDrag = nil
UIS.InputChanged:Connect(function(input)
    if ActiveDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
        ActiveDrag(input)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then ActiveDrag = nil end
end)

local function MakeSlider(parent, text, min, max, default, cb)
    local H = Instance.new("Frame")
    H.Size = UDim2.new(1, 0, 0, 44)
    H.BackgroundTransparency = 1
    H.Parent = parent

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, 0, 0, 18)
    L.BackgroundTransparency = 1
    L.Text = text .. ": " .. tostring(default)
    L.TextColor3 = Color3.fromRGB(210, 210, 220)
    L.Font = Enum.Font.GothamMedium
    L.TextSize = TXT_S
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = H

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 0, 10)
    Bar.Position = UDim2.new(0, 0, 0, 26)
    Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Bar.BorderSizePixel = 0
    Bar.Parent = H
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(60, 140, 240)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.Position = UDim2.new((default - min) / (max - min), -9, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    Knob.BorderSizePixel = 0
    Knob.Parent = Bar
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local function Update(input)
        local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * rel)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, -9, 0.5, -9)
        L.Text = text .. ": " .. tostring(v)
        pcall(cb, v)
    end

    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 1, 0)
    B.BackgroundTransparency = 1
    B.Text = ""
    B.Parent = Bar

    local touchDragging = false

    B.MouseButton1Down:Connect(function()
        ActiveDrag = Update
        Update({ Position = UIS:GetMouseLocation() })
    end)

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchDragging = true
            Update(input)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if touchDragging and input.UserInputType == Enum.UserInputType.Touch then
            Update(input)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchDragging = false
        end
    end)

    return L
end

local function MakePlayerPicker(parent, labelText, onPick)
    local Picker = Instance.new("TextButton")
    Picker.Size = UDim2.new(1, 0, 0, BTN_H)
    Picker.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    Picker.Text = labelText .. ": none"
    Picker.TextColor3 = Color3.fromRGB(220, 220, 230)
    Picker.Font = Enum.Font.GothamMedium
    Picker.TextSize = TXT_S
    Picker.BorderSizePixel = 0
    Picker.Parent = parent
    Instance.new("UICorner", Picker).CornerRadius = UDim.new(0, 6)

    local ListHolder = Instance.new("Frame")
    ListHolder.Size = UDim2.new(1, 0, 0, 0)
    ListHolder.BackgroundTransparency = 1
    ListHolder.ClipsDescendants = true
    ListHolder.Parent = parent

    local LL = Instance.new("UIListLayout", ListHolder)
    LL.SortOrder = Enum.SortOrder.LayoutOrder
    LL.Padding = UDim.new(0, 4)

    local open = false
    local currentTarget = nil

    local function Rebuild()
        for _, c in pairs(ListHolder:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local n = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                n = n + 1
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, 0, 0, BTN_H - 2)
                row.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
                row.Text = p.Name
                row.TextColor3 = Color3.fromRGB(200, 200, 210)
                row.Font = Enum.Font.GothamMedium
                row.TextSize = TXT_S
                row.BorderSizePixel = 0
                row.Parent = ListHolder
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                row.MouseButton1Click:Connect(function()
                    currentTarget = p
                    Picker.Text = labelText .. ": " .. p.Name
                    open = false
                    ListHolder.Size = UDim2.new(1, 0, 0, 0)
                    pcall(onPick, p)
                end)
            end
        end
        ListHolder.Size = UDim2.new(1, 0, 0, n * (BTN_H + 2))
    end

    Picker.MouseButton1Click:Connect(function()
        open = not open
        if open then Rebuild()
        else ListHolder.Size = UDim2.new(1, 0, 0, 0) end
    end)

    Players.PlayerRemoving:Connect(function(p)
        if currentTarget == p then
            currentTarget = nil
            Picker.Text = labelText .. ": none"
        end
    end)

    return Picker
end

-- Discord card — prominent, attractive
local function MakeDiscordCard(parent)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, 0, 0, 76)
    Card.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    Card.BorderSizePixel = 0
    Card.Parent = parent
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 10)

    local glow = Instance.new("UIStroke", Card)
    glow.Color = Color3.fromRGB(120, 140, 255)
    glow.Thickness = 1.5
    glow.Transparency = 0.2

    -- slow pulse
    task.spawn(function()
        while Card.Parent do
            Tween:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { Transparency = 0.6 }):Play()
            task.wait(1.2)
            Tween:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { Transparency = 0.1 }):Play()
            task.wait(1.2)
        end
    end)

    local Logo = Instance.new("TextLabel")
    Logo.Size = UDim2.new(0, 56, 1, 0)
    Logo.Position = UDim2.new(0, 8, 0, 0)
    Logo.BackgroundTransparency = 1
    Logo.Text = "◈"
    Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    Logo.Font = Enum.Font.GothamBold
    Logo.TextSize = 34
    Logo.Parent = Card

    local Head = Instance.new("TextLabel")
    Head.Size = UDim2.new(1, -140, 0, 26)
    Head.Position = UDim2.new(0, 64, 0, 12)
    Head.BackgroundTransparency = 1
    Head.Text = "JOIN BTC COMMUNITY"
    Head.TextColor3 = Color3.fromRGB(255, 255, 255)
    Head.Font = Enum.Font.GothamBold
    Head.TextSize = 14
    Head.TextXAlignment = Enum.TextXAlignment.Left
    Head.Parent = Card

    local Sub = Instance.new("TextLabel")
    Sub.Size = UDim2.new(1, -140, 0, 18)
    Sub.Position = UDim2.new(0, 64, 0, 36)
    Sub.BackgroundTransparency = 1
    Sub.Text = "discord.gg/57mYmMwRuH"
    Sub.TextColor3 = Color3.fromRGB(225, 230, 255)
    Sub.Font = Enum.Font.GothamMedium
    Sub.TextSize = 11
    Sub.TextXAlignment = Enum.TextXAlignment.Left
    Sub.Parent = Card

    local Join = Instance.new("TextButton")
    Join.Size = UDim2.new(0, 100, 0, 34)
    Join.Position = UDim2.new(1, -110, 0.5, -17)
    Join.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Join.Text = "JOIN"
    Join.TextColor3 = Color3.fromRGB(88, 101, 242)
    Join.Font = Enum.Font.GothamBold
    Join.TextSize = 13
    Join.BorderSizePixel = 0
    Join.Parent = Card
    Instance.new("UICorner", Join).CornerRadius = UDim.new(0, 8)

    Join.MouseEnter:Connect(function()
        Tween:Create(Join, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(240, 240, 255) }):Play()
    end)
    Join.MouseLeave:Connect(function()
        Tween:Create(Join, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }):Play()
    end)

    Join.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(ref.discord) end
        pcall(function()
            GuiService:OpenBrowserWindow(ref.discord)
        end)
        Join.Text = "COPIED"
        task.delay(1.5, function()
            if Join.Parent then Join.Text = "JOIN" end
        end)
    end)

    local copy = Instance.new("TextButton")
    copy.Size = UDim2.new(0, 0, 0, 0)
    copy.BackgroundTransparency = 1
    copy.Text = ""
    copy.Parent = Card

    return Card
end

local PlayerTab   = MakeTab("Player")
local TeleportTab = MakeTab("Teleport")
local CombatTab   = MakeTab("Combat")
local KillTab     = MakeTab("Kill")
local VisualTab   = MakeTab("Visual")
local WorldTab    = MakeTab("World")
local ServerTab   = MakeTab("Server")
local MiscTab     = MakeTab("Misc")

-- ============================================================
-- PLAYER
-- ============================================================

MakeSection(PlayerTab, "Character")

MakeButton(PlayerTab, "Reset Character", function()
    if LP.Character then LP.Character:BreakJoints() end
end)

MakeButton(PlayerTab, "Rejoin Server", function()
    Teleport:Teleport(game.PlaceId, LP)
end)

MakeSlider(PlayerTab, "WalkSpeed", 16, 500, 16, function(v)
    ref.flags.walk = v
    local c = LP.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
end)

MakeSlider(PlayerTab, "JumpPower", 50, 500, 50, function(v)
    ref.flags.jump = v
    local c = LP.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = v; h.UseJumpPower = true end
    end
end)

MakeToggle(PlayerTab, "Infinite Jump", false, function(s) ref.flags.infJump = s end)
MakeToggle(PlayerTab, "Noclip", false, function(s) ref.flags.noclip = s end)

MakeToggle(PlayerTab, "Fly", false, function(s)
    ref.flags.fly = s
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp then return end
    if s then
        if hum then hum.PlatformStand = true end
        local bv = hrp:FindFirstChild(N.FLY_BV)
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = N.FLY_BV
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.Velocity = Vector3.zero
            bv.Parent = hrp
        end
        local gy = hrp:FindFirstChild(N.FLY_GY)
        if not gy then
            gy = Instance.new("BodyGyro")
            gy.Name = N.FLY_GY
            gy.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            gy.P = 1000
            gy.Parent = hrp
        end
        local speed = 60
        track(RunService.Heartbeat:Connect(bind(function(r)
            if not r.flags.fly then return end
            local char = LP.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local b = root:FindFirstChild(N.FLY_BV)
            local g = root:FindFirstChild(N.FLY_GY)
            if not b or not g then return end
            local cam = Workspace.CurrentCamera
            local m = Vector3.zero
            -- keyboard
            if UIS:IsKeyDown(Enum.KeyCode.W) then m = m + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then m = m - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then m = m - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then m = m + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then m = m + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then m = m - Vector3.new(0, 1, 0) end
            -- mobile: on-screen joystick is not accessible; use camera look + touch joystick via Humanoid
            if IS_MOBILE and r.flags.fly then
                local hum2 = char:FindFirstChildOfClass("Humanoid")
                if hum2 then
                    local dir = hum2.MoveDirection
                    if dir.Magnitude > 0.05 then
                        m = m + cam.CFrame.LookVector * dir.Z + cam.CFrame.RightVector * dir.X
                    end
                end
            end
            b.Velocity = m.Magnitude > 0 and m.Unit * speed or Vector3.zero
            g.CFrame = cam.CFrame
        end)), 3)
    else
        if hum then hum.PlatformStand = false end
        if hrp then
            local a = hrp:FindFirstChild(N.FLY_BV); if a then a:Destroy() end
            local b = hrp:FindFirstChild(N.FLY_GY); if b then b:Destroy() end
        end
    end
end)

MakeSection(PlayerTab, "Target")
MakePlayerPicker(PlayerTab, "Target", function(p) ref.flags.target = p end)

MakeButton(PlayerTab, "Spectate", function()
    local t = ref.flags.target
    if t and t.Character then
        Workspace.CurrentCamera.CameraSubject = t.Character:FindFirstChildOfClass("Humanoid")
    end
end)

MakeButton(PlayerTab, "Goto Target", function()
    local t = ref.flags.target
    if t and t.Character and LP.Character then
        local th = t.Character:FindFirstChild("HumanoidRootPart")
        if th then LP.Character:MoveTo(th.Position + Vector3.new(0, 3, 0)) end
    end
end)

-- ============================================================
-- TELEPORT
-- ============================================================

MakeSection(TeleportTab, "Player Teleport")
MakePlayerPicker(TeleportTab, "TP target", function(p) ref.flags.tpTarget = p end)
MakeButton(TeleportTab, "Teleport To Selected", function()
    local t = ref.flags.tpTarget
    if t and t.Character and LP.Character then
        local th = t.Character:FindFirstChild("HumanoidRootPart")
        if th then LP.Character:MoveTo(th.Position + Vector3.new(0, 3, 0)) end
    end
end)

MakeSection(TeleportTab, "Waypoints")
MakeButton(TeleportTab, "Save Slot 1", function()
    if LP.Character then ref.flags.wp1 = LP.Character.HumanoidRootPart.CFrame end
end)
MakeButton(TeleportTab, "Load Slot 1", function()
    if ref.flags.wp1 and LP.Character then LP.Character.HumanoidRootPart.CFrame = ref.flags.wp1 end
end)
MakeButton(TeleportTab, "Save Slot 2", function()
    if LP.Character then ref.flags.wp2 = LP.Character.HumanoidRootPart.CFrame end
end)
MakeButton(TeleportTab, "Load Slot 2", function()
    if ref.flags.wp2 and LP.Character then LP.Character.HumanoidRootPart.CFrame = ref.flags.wp2 end
end)

-- ============================================================
-- KILL TAB
-- ============================================================

MakeSection(KillTab, "Target")
MakePlayerPicker(KillTab, "Kill target", function(p)
    ref.kill.target = p
end)

MakeSection(KillTab, "Kill Remote Scanner")
MakeButton(KillTab, "Scan For Kill Remotes", function()
    local found = {}
    local patterns = { "kill", "damage", "hit", "attack", "take", "hurt", "die", "slay", "elim" }
    local function scan(root)
        if not root then return end
        for _, d in pairs(root:GetDescendants()) do
            if d:IsA("RemoteEvent") then
                local ln = string.lower(d.Name)
                for _, p in pairs(patterns) do
                    if string.find(ln, p, 1, true) then
                        found[#found+1] = d
                        break
                    end
                end
            end
        end
    end
    pcall(scan, Replicated)
    pcall(scan, Workspace)
    pcall(scan, LP)
    if LP.Character then pcall(scan, LP.Character) end
    ref.kill.candidates = found
    warn("[BTC] kill remotes found: " .. #found)
    for i, r in ipairs(found) do
        warn("  [" .. i .. "] " .. r:GetFullName())
    end
end)

MakeLabel(KillTab, "Use the button above, then check console")

MakeSection(KillTab, "Selected Remote")
local RemoteLabel = MakeLabel(KillTab, "remote: none")

MakeButton(KillTab, "Use First Found", function()
    if ref.kill.candidates[1] then
        ref.kill.remote = ref.kill.candidates[1]
        RemoteLabel.Text = "remote: " .. ref.kill.remote.Name
    end
end)

MakeButton(KillTab, "Cycle Remote", function()
    if #ref.kill.candidates == 0 then return end
    local cur = ref.kill.remote
    local idx = 1
    for i, r in ipairs(ref.kill.candidates) do
        if r == cur then idx = i + 1 break end
    end
    if idx > #ref.kill.candidates then idx = 1 end
    ref.kill.remote = ref.kill.candidates[idx]
    RemoteLabel.Text = "remote: " .. ref.kill.remote.Name
end)

MakeSection(KillTab, "Argument Shape")
MakeButton(KillTab, "Arg: Player", function()
    ref.kill.argKind = "Player"
end)
MakeButton(KillTab, "Arg: Character", function()
    ref.kill.argKind = "Character"
end)
MakeButton(KillTab, "Arg: HumanoidRootPart", function()
    ref.kill.argKind = "HumanoidRootPart"
end)
MakeButton(KillTab, "Arg: Head", function()
    ref.kill.argKind = "Head"
end)
MakeLabel(KillTab, "current: " .. ref.kill.argKind)

local function BuildArg(target, kind)
    if not target then return nil end
    if kind == "Player" then return target end
    if not target.Character then return nil end
    if kind == "Character" then return target.Character end
    if kind == "HumanoidRootPart" then return target.Character:FindFirstChild("HumanoidRootPart") end
    if kind == "Head" then return target.Character:FindFirstChild("Head") end
    return nil
end

MakeSection(KillTab, "Kill")
MakeButton(KillTab, "⚡ KILL TARGET", function()
    local r = ref.kill.remote
    local t = ref.kill.target
    if not r then
        warn("[BTC] no kill remote selected — run scanner first")
        return
    end
    if not t then
        warn("[BTC] no kill target selected")
        return
    end
    local arg = BuildArg(t, ref.kill.argKind)
    if not arg then
        warn("[BTC] arg build failed — target has no " .. ref.kill.argKind)
        return
    end
    pcall(function() r:FireServer(arg) end)
end)

MakeToggle(KillTab, "Loop Kill", false, function(s)
    ref.kill.loop = s
    if s then
        task.spawn(function()
            while ref.kill.loop do
                local r = ref.kill.remote
                local t = ref.kill.target
                if r and t then
                    local arg = BuildArg(t, ref.kill.argKind)
                    if arg then
                        pcall(function() r:FireServer(arg) end)
                    end
                end
                local base = 1 / (ref.kill.rate or 10)
                local wait = ref.kill.jitter and (base * (0.7 + math.random() * 0.6)) or base
                task.wait(wait)
            end
        end)
    end
end)

MakeSlider(KillTab, "Kill Rate / sec", 1, 30, 10, function(v)
    ref.kill.rate = v
end)

MakeToggle(KillTab, "Jitter Rate", true, function(s)
    ref.kill.jitter = s
end)

MakeLabel(KillTab, "If target doesn't die: try different Arg shape")
MakeLabel(KillTab, "or a different remote from the scanner")

-- ============================================================
-- COMBAT
-- ============================================================

MakeSection(CombatTab, "Aimbot (camera)")
MakeToggle(CombatTab, "Aimbot Enabled", false, function(s) ref.flags.aimbot = s end)
MakeToggle(CombatTab, "Team Check", false, function(s) ref.flags.aimTeam = s end)
MakeSlider(CombatTab, "FOV", 10, 500, 200, function(v) ref.flags.aimFov = v end)

local function SameTeam(a, b)
    local ta, tb = a.Team, b.Team
    if ta == nil or tb == nil then return false end
    return ta == tb
end

local function ClosestToCursor()
    local cam = Workspace.CurrentCamera
    local mp = UIS:GetMouseLocation()
    local best, bd = nil, math.huge
    local fov = ref.flags.aimFov or 200
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                if not (ref.flags.aimTeam and SameTeam(p, LP)) then
                    local sp, on = cam:WorldToViewportPoint(head.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                        if d < bd and d <= fov then
                            best, bd = p, d
                        end
                    end
                end
            end
        end
    end
    return best
end

track(RunService.Heartbeat:Connect(bind(function(r)
    if not r.flags.aimbot then return end
    local t = ClosestToCursor()
    if t and t.Character then
        local head = t.Character:FindFirstChild("Head")
        if head then
            local cam = Workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
        end
    end
end)), 5)

MakeSection(CombatTab, "Hitbox")
MakeSlider(CombatTab, "Hitbox Size", 1, 20, 1, function(v) ref.flags.hitboxSize = v end)
MakeToggle(CombatTab, "Hitbox Expander", false, function(s) ref.flags.hitbox = s end)

track(RunService.Heartbeat:Connect(bind(function(r)
    if not r.flags.hitbox then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local sz = r.flags.hitboxSize or 1
                hrp.Size = Vector3.new(sz, sz, sz)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            end
        end
    end
end)), 7)

-- ============================================================
-- VISUAL
-- ============================================================

MakeSection(VisualTab, "ESP")
MakeToggle(VisualTab, "Player ESP", false, function(s) ref.flags.esp = s end)
MakeToggle(VisualTab, "ESP Health", false, function(s) ref.flags.espHealth = s end)

track(RunService.Heartbeat:Connect(bind(function(r)
    if not r.flags.esp then
        for _, p in pairs(Players:GetPlayers()) do
            local tag = r.espTags and r.espTags[p]
            if tag then tag:Destroy(); r.espTags[p] = nil end
        end
        return
    end
    r.espTags = r.espTags or {}
    local cam = Workspace.CurrentCamera
    for _, p in pairs(Players:GetPlayers()) do
        local skip = (p == LP) or (not p.Character)
        local head, hrp
        if not skip then
            head = p.Character:FindFirstChild("Head")
            hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if not head or not hrp then skip = true end
        end
        if skip then
            local old = r.espTags[p]
            if old then old:Destroy(); r.espTags[p] = nil end
        else
            local tag = r.espTags[p]
            if not tag then
                tag = Instance.new("BillboardGui")
                tag.Name = N.ESP_TAG
                tag.Size = UDim2.new(0, 120, 0, 20)
                tag.StudsOffset = Vector3.new(0, 2.5, 0)
                tag.AlwaysOnTop = true
                tag.Parent = GUI
                local lbl = Instance.new("TextLabel")
                lbl.Name = "Lbl"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                lbl.TextStrokeTransparency = 0
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 13
                lbl.Parent = tag
                r.espTags[p] = tag
            end
            tag.Adornee = head
            local lbl = tag:FindFirstChild("Lbl")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if lbl and hum then
                if p.Team then lbl.TextColor3 = p.Team.TeamColor.Color end
                local dist = math.floor((cam.CFrame.Position - hrp.Position).Magnitude)
                local hp = r.flags.espHealth and ("  " .. math.floor(hum.Health) .. "hp") or ""
                lbl.Text = p.Name .. "  [" .. dist .. "m]" .. hp
            end
        end
    end
end)), 8)

MakeSection(VisualTab, "Chams")
MakeToggle(VisualTab, "Chams (Highlight)", false, function(s) ref.flags.chams = s end)

track(RunService.Heartbeat:Connect(bind(function(r)
    if not r.flags.chams then
        for _, p in pairs(Players:GetPlayers()) do
            local hl = r.chams and r.chams[p]
            if hl then hl:Destroy(); r.chams[p] = nil end
        end
        return
    end
    r.chams = r.chams or {}
    for _, p in pairs(Players:GetPlayers()) do
        local skip = (p == LP) or (not p.Character)
        if skip then
            local old = r.chams[p]
            if old then old:Destroy(); r.chams[p] = nil end
        elseif not r.chams[p] then
            local hl = Instance.new("Highlight")
            hl.Name = N.HL
            hl.FillColor = p.Team and p.Team.TeamColor.Color or Color3.fromRGB(255, 60, 60)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = GUI
            hl.Adornee = p.Character
            r.chams[p] = hl
        else
            r.chams[p].Adornee = p.Character
        end
    end
end)), 9)

MakeSection(VisualTab, "Lighting")
MakeToggle(VisualTab, "Fullbright", false, function(s)
    if s then
        ref.saved.brightness = Lighting.Brightness
        ref.saved.ambient = Lighting.Ambient
        ref.saved.outdoor = Lighting.OutdoorAmbient
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.FogEnd = 1e6
    else
        Lighting.Brightness = ref.saved.brightness or 1
        Lighting.Ambient = ref.saved.ambient or Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = ref.saved.outdoor or Color3.fromRGB(70, 70, 70)
    end
end)

MakeSlider(VisualTab, "Camera FOV", 70, 120, 70, function(v)
    Workspace.CurrentCamera.FieldOfView = v
end)

-- ============================================================
-- WORLD
-- ============================================================

MakeSection(WorldTab, "Physics")
MakeSlider(WorldTab, "Gravity", 0, 500, 196, function(v) Workspace.Gravity = v end)
MakeToggle(WorldTab, "Low Gravity", false, function(s)
    if s then
        ref.saved.gravity = Workspace.Gravity
        Workspace.Gravity = 50
    else
        Workspace.Gravity = ref.saved.gravity or 196
    end
end)

MakeToggle(WorldTab, "Freeze Time", false, function(s)
    ref.flags.freezeTime = s
    if s then ref.saved.clock = Lighting.ClockTime end
end)

track(RunService.Heartbeat:Connect(bind(function(r)
    if r.flags.freezeTime then
        Lighting.ClockTime = r.saved.clock or 14
    end
end)), 10)

-- ============================================================
-- SERVER
-- ============================================================

MakeSection(ServerTab, "Info")
local InfoLabel = MakeLabel(ServerTab, "Players: " .. #Players:GetPlayers())
MakeLabel(ServerTab, "PlaceId: " .. tostring(game.PlaceId))

MakeButton(ServerTab, "Refresh Player List", function()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do table.insert(list, p.Name) end
    InfoLabel.Text = "Players (" .. #list .. "): " .. table.concat(list, ", ")
end)

MakeButton(ServerTab, "Server Hop", function()
    local ok, servers = pcall(function()
        return HttpSvc:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)
    if ok and servers and servers.data then
        for _, s in pairs(servers.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                Teleport:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                return
            end
        end
    end
end)

MakeToggle(ServerTab, "Anti-AFK", false, function(s)
    ref.flags.antiAfk = s
    if s then
        track(LP.Idled:Connect(function()
            VUser:CaptureController()
            VUser:ClickButton2(Vector2.new())
        end), 12)
    end
end)

-- ============================================================
-- MISC
-- ============================================================

MakeSection(MiscTab, "Community")
MakeDiscordCard(MiscTab)

MakeSection(MiscTab, "Client")
MakeButton(MiscTab, "Copy JobId", function()
    if setclipboard then setclipboard(game.JobId) end
end)
MakeButton(MiscTab, "Copy PlaceId", function()
    if setclipboard then setclipboard(tostring(game.PlaceId)) end
end)

MakeButton(MiscTab, "Destroy Panel", function() GUI:Destroy() end)

-- ============================================================
-- BACKGROUND LOOPS
-- ============================================================

track(RunService.Heartbeat:Connect(bind(function(r)
    if r.flags.noclip and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
end)), 20)

UIS.JumpRequest:Connect(function()
    if ref.flags.infJump and LP.Character then
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

S.tabs["Player"].Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
S.tabs["Player"].Btn.TextColor3 = Color3.fromRGB(120, 200, 255)
S.tabs["Player"].Page.Visible = true

LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
        if ref.flags.walk then h.WalkSpeed = ref.flags.walk end
        if ref.flags.jump then h.JumpPower = ref.flags.jump; h.UseJumpPower = true end
    end
end)

local notif = Instance.new("TextLabel")
notif.Size = UDim2.new(0, 240, 0, 34)
notif.Position = UDim2.new(0.5, -120, 0, 12)
notif.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
notif.BackgroundTransparency = 0.1
notif.Text = "BTC v" .. S.version .. " loaded" .. (IS_MOBILE and " (mobile)" or "")
notif.TextColor3 = Color3.fromRGB(120, 200, 255)
notif.Font = Enum.Font.GothamBold
notif.TextSize = 13
notif.Parent = GUI
Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 6)
task.delay(3, function()
    Tween:Create(notif, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
    task.wait(0.6)
    notif:Destroy()
end)

end)()
