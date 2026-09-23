-- SERENITY HUB // SHARED UI V12.6
-- Public shared UI library for current and future Serenity game modules.
-- Game-specific logic stays in each game module; this file owns the shared UI.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Library = {}

Library.Version = "12.6"
Library.APIVersion = 1
Library.DiscordInvite = "https://discord.gg/ccsvkN7Pp"

local Theme = {
    BG = Color3.fromRGB(12,15,19),
    BG2 = Color3.fromRGB(17,21,26),
    Sidebar = Color3.fromRGB(20,25,31),
    Panel = Color3.fromRGB(25,30,37),
    Panel2 = Color3.fromRGB(31,37,45),
    Panel3 = Color3.fromRGB(37,44,53),
    Hover = Color3.fromRGB(44,52,62),
    Stroke = Color3.fromRGB(60,70,82),
    StrokeSoft = Color3.fromRGB(46,55,65),
    Text = Color3.fromRGB(244,247,250),
    TextSoft = Color3.fromRGB(201,209,218),
    TextDim = Color3.fromRGB(145,156,168),
    Icon = Color3.fromRGB(188,198,207),
    Cyan = Color3.fromRGB(31,210,234),
    CyanDark = Color3.fromRGB(20,158,198),
    Mint = Color3.fromRGB(58,222,174),
    Lavender = Color3.fromRGB(157,138,255),
    Warning = Color3.fromRGB(245,203,94),
    Danger = Color3.fromRGB(235,105,120),
    Track = Color3.fromRGB(55,64,75),
    White = Color3.fromRGB(250,252,253),
}

local Icons = {
    Dashboard = "rbxassetid://10723424646",
    Farm = "rbxassetid://10723425539",
    Upgrades = "rbxassetid://10734963191",
    Quests = "rbxassetid://10709782582",
    Others = "rbxassetid://10734950309",
    Settings = "rbxassetid://14007344336",
    minimize = "rbxassetid://10734895698",
    close = "rbxassetid://10709798174",
    chevron = "rbxassetid://10709790948",
}

local function New(className, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        if key ~= "Parent" then
            object[key] = value
        end
    end
    object.Parent = props and props.Parent or nil
    return object
end

local function Round(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
        Parent = parent,
    })
end

local function Stroke(parent, color, transparency, thickness)
    return New("UIStroke", {
        Color = color or Theme.Stroke,
        Transparency = transparency == nil and .65 or transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function Tween(object, duration, props, style, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or .16,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        props
    )
    tween:Play()
    return tween
end

local function Glass(parent, topTransparency, bottomTransparency)
    return New("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(44,52,62)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(19,24,30)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, topTransparency or .47),
            NumberSequenceKeypoint.new(1, bottomTransparency or .73),
        }),
        Parent = parent,
    })
end

local function Icon(parent, name, props)
    props = props or {}
    return New("ImageLabel", {
        BackgroundTransparency = 1,
        Image = Icons[name] or name or "",
        ImageColor3 = props.Color or Theme.Icon,
        ImageTransparency = props.Transparency or 0,
        Position = props.Position or UDim2.new(),
        Size = props.Size or UDim2.fromOffset(16,16),
        AnchorPoint = props.AnchorPoint or Vector2.zero,
        ZIndex = props.ZIndex or 1,
        Parent = parent,
    })
end

local function Overlay(parent, callback, z)
    local button = New("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1,1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = z or (parent.ZIndex + 20),
        Parent = parent,
    })
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    return button
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function copyText(text)
    text = tostring(text or "")

    local candidates = {
        rawget(_G, "setclipboard"),
        rawget(_G, "toclipboard"),
        rawget(_G, "writeclipboard"),
    }

    if getgenv then
        local env = getgenv()
        table.insert(candidates, env and env.setclipboard)
        table.insert(candidates, env and env.toclipboard)
        table.insert(candidates, env and env.writeclipboard)
    end

    for _, fn in ipairs(candidates) do
        if type(fn) == "function" then
            local ok = pcall(fn, text)
            if ok then
                return true
            end
        end
    end

    return false
end

local function getPlayerHeadshot(userId)
    local ok, image = pcall(function()
        local content = Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size150x150
        )
        return content
    end)

    return ok and image or ""
end

local function getGameIcon(universeId)
    universeId = tonumber(universeId) or tonumber(game.GameId) or 0
    if universeId <= 0 then
        universeId = tonumber(game.PlaceId) or 0
    end

    return ("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(universeId)
end

local function getExperienceName(fallback)
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
    end)

    if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
        return info.Name
    end

    return fallback or "Current Experience"
end

function Library.Create(options)
    options = options or {}

    local width, height = options.Width or 850, options.Height or 520
    local sidebarOpen, sidebarClosed = options.SidebarWidth or 210, 70
    local logoId = options.Logo or "rbxthumb://type=Asset&id=89023606689629&w=420&h=420"
    local discordInvite = options.DiscordInvite or Library.DiscordInvite
    local showTopProfile = options.ShowTopProfile ~= false
    local premiumMotion = options.PremiumMotion ~= false

    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    local old = CoreGui:FindFirstChild("SerenityHubUI")
        or (playerGui and playerGui:FindFirstChild("SerenityHubUI"))

    if old then
        old:Destroy()
    end

    local gui = New("ScreenGui", {
        Name = "SerenityHubUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    pcall(function()
        gui.Parent = CoreGui
    end)

    if not gui.Parent then
        gui.Parent = player:WaitForChild("PlayerGui")
    end

    local main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(width,height),
        BackgroundColor3 = Theme.BG,
        BackgroundTransparency = .14,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 10,
        Parent = gui,
    })
    Round(main, 18)
    Glass(main, .22, .45)

    local mainStroke = Stroke(main, Theme.Cyan, .58, 1)
    local edge = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Theme.Cyan),
            ColorSequenceKeypoint.new(.36,Theme.Mint),
            ColorSequenceKeypoint.new(.72,Theme.Lavender),
            ColorSequenceKeypoint.new(1,Theme.Cyan),
        }),
        Parent = mainStroke,
    })

    task.spawn(function()
        while edge.Parent do
            edge.Rotation = 0
            Tween(
                edge,
                8,
                {Rotation = 360},
                Enum.EasingStyle.Linear
            ).Completed:Wait()
        end
    end)

    if premiumMotion then
        task.spawn(function()
            while mainStroke.Parent do
                Tween(
                    mainStroke,
                    2.8,
                    {Transparency = .46},
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut
                ).Completed:Wait()

                if not mainStroke.Parent then
                    break
                end

                Tween(
                    mainStroke,
                    2.8,
                    {Transparency = .66},
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut
                ).Completed:Wait()
            end
        end)
    end

    local topbar = New("Frame", {
        BackgroundColor3 = Theme.BG2,
        BackgroundTransparency = .27,
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,62),
        ClipsDescendants = true,
        ZIndex = 12,
        Parent = main,
    })
    Glass(topbar, .34, .62)

    New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14,9),
        Size = UDim2.fromOffset(44,44),
        ScaleType = Enum.ScaleType.Fit,
        Image = logoId,
        ImageColor3 = Theme.White,
        ZIndex = 14,
        Parent = topbar,
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(74,0),
        Size = UDim2.new(1, showTopProfile and -390 or -180, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "SERENITY HUB",
        TextColor3 = Theme.Text,
        TextSize = 23,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 14,
        Parent = topbar,
    })

    local accent = New("Frame", {
        BackgroundColor3 = Theme.Cyan,
        BackgroundTransparency = .18,
        BorderSizePixel = 0,
        Position = UDim2.new(0,0,1,-1),
        Size = UDim2.new(1,0,0,1),
        ZIndex = 14,
        Parent = topbar,
    })

    local accentGradient = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Theme.Cyan),
            ColorSequenceKeypoint.new(.45,Theme.Mint),
            ColorSequenceKeypoint.new(.76,Theme.Lavender),
            ColorSequenceKeypoint.new(1,Theme.Cyan),
        }),
        Offset = Vector2.new(-1,0),
        Parent = accent,
    })

    if premiumMotion then
        task.spawn(function()
            while accentGradient.Parent do
                accentGradient.Offset = Vector2.new(-1,0)
                Tween(
                    accentGradient,
                    5.5,
                    {Offset = Vector2.new(1,0)},
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut
                ).Completed:Wait()
                task.wait(1.3)
            end
        end)
    end

    local sheen = New("Frame", {
        BackgroundColor3 = Theme.White,
        BackgroundTransparency = .76,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(-150,0),
        Size = UDim2.fromOffset(120,62),
        ZIndex = 13,
        Parent = topbar,
    })

    New("UIGradient", {
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,1),
            NumberSequenceKeypoint.new(.50,.80),
            NumberSequenceKeypoint.new(1,1),
        }),
        Parent = sheen,
    })

    if premiumMotion then
        task.spawn(function()
            while sheen.Parent do
                sheen.Position = UDim2.fromOffset(-150,0)
                Tween(
                    sheen,
                    3.8,
                    {Position = UDim2.new(1,30,0,0)},
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut
                ).Completed:Wait()
                task.wait(4.0)
            end
        end)
    else
        sheen.Visible = false
    end

    local profileChip

    if showTopProfile then
        profileChip = New("Frame", {
            AnchorPoint = Vector2.new(1,.5),
            Position = UDim2.new(1,-102,.5,0),
            Size = UDim2.fromOffset(198,42),
            BackgroundColor3 = Theme.Panel,
            BackgroundTransparency = .64,
            BorderSizePixel = 0,
            ZIndex = 15,
            Parent = topbar,
        })
        Round(profileChip, 12)
        local profileStroke = Stroke(profileChip, Theme.StrokeSoft, .78, 1)
        Glass(profileChip, .50, .76)

        profileChip.MouseEnter:Connect(function()
            Tween(profileChip,.14,{BackgroundTransparency=.52})
            Tween(profileStroke,.14,{Color=Theme.Mint,Transparency=.58})
        end)

        profileChip.MouseLeave:Connect(function()
            Tween(profileChip,.14,{BackgroundTransparency=.64})
            Tween(profileStroke,.14,{Color=Theme.StrokeSoft,Transparency=.78})
        end)

        local avatarWrap = New("Frame", {
            Position = UDim2.fromOffset(6,5),
            Size = UDim2.fromOffset(32,32),
            BackgroundColor3 = Theme.Panel2,
            BackgroundTransparency = .35,
            BorderSizePixel = 0,
            ZIndex = 16,
            Parent = profileChip,
        })
        Round(avatarWrap, 999)
        Stroke(avatarWrap, Theme.Cyan, .62, 1)

        local avatar = New("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(2,2),
            Size = UDim2.fromOffset(28,28),
            Image = "",
            ZIndex = 17,
            Parent = avatarWrap,
        })
        Round(avatar, 999)

        task.spawn(function()
            local image = getPlayerHeadshot(player.UserId)
            if avatar.Parent then
                avatar.Image = image
            end
        end)

        local presence = New("Frame", {
            AnchorPoint = Vector2.new(.5,.5),
            Position = UDim2.new(1,-3,1,-3),
            Size = UDim2.fromOffset(7,7),
            BackgroundColor3 = Theme.Mint,
            BorderSizePixel = 0,
            ZIndex = 19,
            Parent = avatarWrap,
        })
        Round(presence,999)
        Stroke(presence,Theme.BG,.12,1)

        New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(47,4),
            Size = UDim2.new(1,-53,0,18),
            Font = Enum.Font.GothamMedium,
            Text = player.DisplayName,
            TextColor3 = Theme.Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 16,
            Parent = profileChip,
        })

        New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(47,21),
            Size = UDim2.new(1,-53,0,15),
            Font = Enum.Font.Gotham,
            Text = "@" .. player.Name,
            TextColor3 = Theme.TextDim,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 16,
            Parent = profileChip,
        })
    end

    local Window

    local function topButton(iconName, offset, callback)
        local holder = New("Frame", {
            AnchorPoint = Vector2.new(1,.5),
            Position = UDim2.new(1,offset,.5,0),
            Size = UDim2.fromOffset(36,36),
            BackgroundColor3 = Theme.Panel2,
            BackgroundTransparency = .73,
            ZIndex = 15,
            Parent = topbar,
        })
        Round(holder,11)
        Stroke(holder,Theme.StrokeSoft,.84,1)

        local image = Icon(holder,iconName,{
            AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromScale(.5,.5),
            Size=UDim2.fromOffset(17,17),
            ZIndex=16
        })

        local hit = Overlay(holder,callback)

        hit.MouseEnter:Connect(function()
            Tween(holder,.12,{BackgroundTransparency=.48})
            Tween(image,.12,{ImageColor3=Theme.Cyan})
        end)

        hit.MouseLeave:Connect(function()
            Tween(holder,.12,{BackgroundTransparency=.73})
            Tween(image,.12,{ImageColor3=Theme.Icon})
        end)
    end

    local body = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0,62),
        Size = UDim2.new(1,0,1,-62),
        ZIndex = 11,
        Parent = main,
    })

    local sidebar = New("Frame", {
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = .30,
        Size = UDim2.new(0,sidebarOpen,1,0),
        ClipsDescendants = true,
        ZIndex = 12,
        Parent = body,
    })
    Glass(sidebar,.40,.66)

    local content = New("Frame", {
        BackgroundColor3 = Theme.BG,
        BackgroundTransparency = .40,
        Position = UDim2.fromOffset(sidebarOpen,0),
        Size = UDim2.new(1,-sidebarOpen,1,0),
        ClipsDescendants = true,
        ZIndex = 12,
        Parent = body,
    })

    local sideHeader = New("Frame", {
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = .60,
        Position = UDim2.fromOffset(9,11),
        Size = UDim2.new(1,-18,0,60),
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = sidebar,
    })
    Round(sideHeader,15)
    Stroke(sideHeader,Theme.StrokeSoft,.75,1)
    Glass(sideHeader,.46,.73)

    local sideLogo = New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8,8),
        Size = UDim2.fromOffset(44,44),
        ScaleType = Enum.ScaleType.Fit,
        Image = logoId,
        ImageColor3 = Theme.White,
        ZIndex = 14,
        Parent = sideHeader,
    })

    local sideBrand = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(64,0),
        Size = UDim2.fromOffset(122,60),
        Font = Enum.Font.GothamBold,
        Text = "SERENITY HUB",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = sideHeader,
    })

    local collapse = New("Frame", {
        AnchorPoint = Vector2.new(1,.5),
        Position = UDim2.new(1,-8,.5,0),
        Size = UDim2.fromOffset(28,28),
        BackgroundColor3 = Theme.Panel2,
        BackgroundTransparency = .58,
        ZIndex = 15,
        Parent = sideHeader,
    })
    Round(collapse,9)
    Stroke(collapse,Theme.StrokeSoft,.82,1)

    local collapseIcon = Icon(collapse,"chevron",{
        AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(.5,.5),
        Size=UDim2.fromOffset(14,14),
        ZIndex=16
    })
    collapseIcon.Rotation = 90

    local nav = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8,82),
        Size = UDim2.new(1,-16,1,-94),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        ZIndex = 13,
        Parent = sidebar,
    })

    New("UIListLayout", {
        Padding=UDim.new(0,7),
        SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=nav
    })

    local status = New("Frame", {
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = .58,
        AnchorPoint = Vector2.new(0,1),
        Position = UDim2.new(0,14,1,-8),
        Size = UDim2.new(1,-28,0,30),
        ClipsDescendants = true,
        ZIndex = 30,
        Parent = content,
    })
    Round(status,9)
    Stroke(status,Theme.StrokeSoft,.76,1)
    Glass(status,.52,.74)

    local statusPulse = New("Frame", {
        AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromOffset(14,15),
        Size=UDim2.fromOffset(8,8),
        BackgroundColor3=Theme.Mint,
        BackgroundTransparency=.70,
        ZIndex=30,
        Parent=status
    })
    Round(statusPulse,999)

    local statusDot = New("Frame", {
        Position=UDim2.fromOffset(10,11),
        Size=UDim2.fromOffset(8,8),
        BackgroundColor3=Theme.Mint,
        ZIndex=31,
        Parent=status
    })
    Round(statusDot,999)

    if premiumMotion then
        task.spawn(function()
            while statusPulse.Parent do
                statusPulse.Size = UDim2.fromOffset(8,8)
                statusPulse.BackgroundTransparency = .58
                Tween(
                    statusPulse,
                    1.7,
                    {Size=UDim2.fromOffset(19,19),BackgroundTransparency=1},
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.Out
                ).Completed:Wait()
                task.wait(.25)
            end
        end)
    end

    local statusText = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(27,0),
        Size = UDim2.new(1,-34,1,0),
        Font = Enum.Font.GothamMedium,
        Text = "READY",
        TextColor3 = Theme.TextSoft,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 31,
        Parent = status,
    })

    local pageHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14,9),
        Size = UDim2.new(1,-28,1,-50),
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = content,
    })

    local pages, navItems, current = {}, {}, nil
    local pageOrder = 0
    local sidebarOpenState = true

    Window = {
        Theme = Theme,
        Gui = gui,
        Main = main,
        Items = {},
        Pages = pages,
        Width = width,
        Height = height,
        DiscordInvite = discordInvite,
        Player = player,
        ProfileChip = profileChip,
        GameIcon = getGameIcon(game.GameId),
        PremiumMotion = premiumMotion,
    }

    function Window:AddPage(name, iconName)
        pageOrder += 1

        local page = New("CanvasGroup", {
            Name=name,
            BackgroundTransparency=1,
            Size=UDim2.fromScale(1,1),
            Position=UDim2.fromOffset(0,0),
            GroupTransparency=0,
            Visible=false,
            ZIndex=14,
            Parent=pageHolder
        })

        pages[name] = page

        local tab = New("Frame", {
            LayoutOrder = pageOrder,
            BackgroundColor3 = Theme.Panel2,
            BackgroundTransparency = .90,
            Size = UDim2.new(1,0,0,44),
            ClipsDescendants = true,
            ZIndex = 14,
            Parent = nav,
        })
        Round(tab,12)

        local tabStroke = Stroke(tab,Theme.StrokeSoft,1,1)
        Glass(tab,.56,.84)

        local rail = New("Frame", {
            BackgroundColor3=Theme.Cyan,
            BackgroundTransparency=1,
            Position=UDim2.new(0,4,.5,-11),
            Size=UDim2.fromOffset(3,22),
            ZIndex=15,
            Parent=tab
        })
        Round(rail,999)

        local image = Icon(tab,iconName or name,{
            Position=UDim2.fromOffset(16,14),
            Size=UDim2.fromOffset(16,16),
            ZIndex=16
        })

        local label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(47,0),
            Size = UDim2.new(1,-54,1,0),
            Font = Enum.Font.GothamMedium,
            Text = name,
            TextColor3 = Theme.TextSoft,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 16,
            Parent = tab,
        })

        local hit = Overlay(tab,function()
            Window:SwitchPage(name)
        end)

        hit.MouseEnter:Connect(function()
            if current ~= name then
                Tween(tab,.12,{BackgroundTransparency=.76})
            end
        end)

        hit.MouseLeave:Connect(function()
            if current ~= name then
                Tween(tab,.12,{BackgroundTransparency=.90})
            end
        end)

        navItems[name] = {Row=tab,Stroke=tabStroke,Line=rail,Icon=image,Label=label}

        if not current then
            Window:SwitchPage(name)
        end

        return page
    end

    function Window:SwitchPage(name)
        if not pages[name] then
            return
        end

        local previous = current
        current = name

        for pageName, page in pairs(pages) do
            if pageName == name then
                page.Visible = true
                if premiumMotion and previous ~= name then
                    page.GroupTransparency = 1
                    page.Position = UDim2.fromOffset(8,0)
                    Tween(page,.18,{GroupTransparency=0,Position=UDim2.fromOffset(0,0)})
                else
                    page.GroupTransparency = 0
                    page.Position = UDim2.fromOffset(0,0)
                end
            else
                page.Visible = false
            end
        end

        for itemName, item in pairs(navItems) do
            local selected = itemName == name
            Tween(item.Row,.16,{BackgroundTransparency=selected and .58 or .90})
            Tween(item.Line,.16,{BackgroundTransparency=selected and 0 or 1})
            Tween(item.Icon,.16,{ImageColor3=selected and Theme.Cyan or Theme.Icon})
            Tween(item.Label,.16,{TextColor3=selected and Theme.Text or Theme.TextSoft})
            item.Stroke.Color = selected and Theme.Cyan or Theme.StrokeSoft
            item.Stroke.Transparency = selected and .55 or 1
        end
    end

    function Window:SetSidebar(open)
        sidebarOpenState = open == true
        local widthNow = sidebarOpenState and sidebarOpen or sidebarClosed

        Tween(sidebar,.20,{Size=UDim2.new(0,widthNow,1,0)})
        Tween(content,.20,{Position=UDim2.fromOffset(widthNow,0),Size=UDim2.new(1,-widthNow,1,0)})

        sideBrand.Visible = sidebarOpenState
        sideLogo.Visible = sidebarOpenState

        if sidebarOpenState then
            Tween(collapse,.16,{Position=UDim2.new(1,-8,.5,0)})
            collapseIcon.Rotation = 90
            sideHeader.Size = UDim2.new(1,-18,0,60)
        else
            Tween(collapse,.16,{Position=UDim2.new(.5,14,.5,0)})
            collapseIcon.Rotation = -90
            sideHeader.Size = UDim2.new(1,-18,0,52)
        end

        for _, item in pairs(navItems) do
            item.Label.Visible = sidebarOpenState
            item.Icon.Position = sidebarOpenState
                and UDim2.fromOffset(16,14)
                or UDim2.new(.5,-8,.5,-8)
        end
    end

    Overlay(collapse,function()
        Window:SetSidebar(not sidebarOpenState)
    end)

    local function makePageScroll(page)
        local scroll = page:FindFirstChild("Scroll")
        if scroll then
            return scroll
        end

        scroll = New("ScrollingFrame", {
            Name = "Scroll",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1,1),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Stroke,
            ZIndex = 14,
            Parent = page,
        })

        local grid = New("UIGridLayout", {
            CellPadding = UDim2.fromOffset(12,12),
            CellSize = UDim2.new(.5,-6,0,420),
            FillDirectionMaxCells = 2,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = scroll,
        })

        grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.fromOffset(0,grid.AbsoluteContentSize.Y + 10)
        end)

        return scroll
    end

    function Window:Section(page, title, right)
        local scroll = makePageScroll(page)

        local section = New("Frame", {
            Name = title,
            LayoutOrder = right and 2 or 1,
            BackgroundColor3 = Theme.Panel,
            BackgroundTransparency = .72,
            BorderSizePixel = 0,
            Size = UDim2.new(.5,-6,0,420),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 15,
            Parent = scroll,
        })
        Round(section,15)
        Stroke(section,Theme.StrokeSoft,.72,1)
        Glass(section,.57,.82)

        New("UIPadding", {
            PaddingTop=UDim.new(0,13),PaddingBottom=UDim.new(0,13),
            PaddingLeft=UDim.new(0,13),PaddingRight=UDim.new(0,13),Parent=section
        })

        New("UIListLayout", {Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder,Parent=section})

        New("TextLabel", {
            LayoutOrder = 0,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,24),
            Font = Enum.Font.GothamMedium,
            Text = title,
            TextColor3 = Theme.Text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 16,
            Parent = section,
        })

        return section
    end

    local controlOrder = 10

    local function baseRow(parent, height)
        controlOrder += 1
        local row = New("Frame", {
            LayoutOrder = controlOrder,
            BackgroundColor3 = Theme.Panel2,
            BackgroundTransparency = .78,
            BorderSizePixel = 0,
            Size = UDim2.new(1,0,0,height or 46),
            ZIndex = 16,
            Parent = parent,
        })
        Round(row,12)
        local rowStroke = Stroke(row,Theme.StrokeSoft,.82,1)
        Glass(row,.64,.86)

        row.MouseEnter:Connect(function()
            Tween(row,.12,{BackgroundTransparency=.70})
            Tween(rowStroke,.12,{Color=Theme.Cyan,Transparency=.65})
        end)
        row.MouseLeave:Connect(function()
            Tween(row,.12,{BackgroundTransparency=.78})
            Tween(rowStroke,.12,{Color=Theme.StrokeSoft,Transparency=.82})
        end)

        return row
    end

    function Window:GameCard(parent, opts)
        opts = opts or {}
        local row = baseRow(parent, opts.Height or 132)
        local color = opts.Accent or Theme.Cyan

        local line = New("Frame", {BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.fromOffset(0,0),Size=UDim2.new(0,3,1,0),ZIndex=17,Parent=row})
        Round(line,999)

        local imageHolder = New("Frame", {
            BackgroundColor3=Theme.Panel3,BackgroundTransparency=.40,BorderSizePixel=0,
            Position=UDim2.fromOffset(13,13),Size=UDim2.fromOffset(82,82),ZIndex=17,Parent=row,
        })
        Round(imageHolder,11)
        Stroke(imageHolder,color,.62,1)

        local image = New("ImageLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-4,1,-4),
            Image=opts.Image or getGameIcon(opts.UniverseId or game.GameId),ScaleType=Enum.ScaleType.Crop,ZIndex=18,Parent=imageHolder,
        })
        Round(image,10)

        New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(108,12),Size=UDim2.new(1,-121,0,17),
            Font=Enum.Font.GothamBold,Text=opts.Kicker or "CURRENT GAME",TextColor3=color,TextSize=9,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row,
        })

        local title = New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(108,31),Size=UDim2.new(1,-121,0,28),
            Font=Enum.Font.GothamBold,Text=opts.Title or opts.GameName or "Loading...",TextColor3=Theme.Text,TextSize=15,
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=17,Parent=row,
        })

        local description = New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(108,61),Size=UDim2.new(1,-121,0,34),
            Font=Enum.Font.Gotham,Text=opts.Description or "Supported by Serenity Hub",TextColor3=Theme.TextSoft,TextSize=10,
            TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=17,Parent=row,
        })

        local state = New("TextLabel", {
            AnchorPoint=Vector2.new(1,1),BackgroundColor3=color,BackgroundTransparency=.87,
            Position=UDim2.new(1,-12,1,-11),Size=UDim2.fromOffset(88,23),Font=Enum.Font.GothamMedium,
            Text=opts.Status or "SUPPORTED",TextColor3=color,TextSize=9,ZIndex=17,Parent=row,
        })
        Round(state,999)
        Stroke(state,color,.55,1)

        if not opts.Title and not opts.GameName then
            task.spawn(function()
                local experienceName = getExperienceName(opts.FallbackName)
                if title.Parent then title.Text = experienceName end
            end)
        end

        return {
            Row=row,Image=image,Title=title,Description=description,Status=state,
            SetTitle=function(_,value) title.Text=tostring(value or "") end,
            SetDescription=function(_,value) description.Text=tostring(value or "") end,
            SetStatus=function(_,value) state.Text=tostring(value or "") end,
        }
    end

    function Window:PlayerCard(parent, opts)
        opts = opts or {}
        local row = baseRow(parent, opts.Height or 112)
        local accentColor = opts.Accent or Theme.Mint

        local line = New("Frame", {BackgroundColor3=accentColor,BorderSizePixel=0,Position=UDim2.fromOffset(0,0),Size=UDim2.new(0,3,1,0),ZIndex=17,Parent=row})
        Round(line,999)

        local avatarHolder = New("Frame", {
            BackgroundColor3=Theme.Panel3,BackgroundTransparency=.40,BorderSizePixel=0,
            Position=UDim2.fromOffset(13,18),Size=UDim2.fromOffset(64,64),ZIndex=17,Parent=row,
        })
        Round(avatarHolder,999)
        Stroke(avatarHolder,accentColor,.56,1)

        local avatar = New("ImageLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-4,1,-4),
            Image="",ScaleType=Enum.ScaleType.Crop,ZIndex=18,Parent=avatarHolder,
        })
        Round(avatar,999)

        task.spawn(function()
            local image = getPlayerHeadshot(player.UserId)
            if avatar.Parent then avatar.Image = image end
        end)

        New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(93,15),Size=UDim2.new(1,-106,0,16),
            Font=Enum.Font.GothamBold,Text=opts.Kicker or "PLAYER",TextColor3=accentColor,TextSize=9,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row,
        })

        local displayName = New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(93,33),Size=UDim2.new(1,-106,0,24),
            Font=Enum.Font.GothamMedium,Text=opts.DisplayName or player.DisplayName,TextColor3=Theme.Text,TextSize=14,
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=17,Parent=row,
        })

        local username = New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(93,57),Size=UDim2.new(1,-106,0,18),
            Font=Enum.Font.Gotham,Text=opts.Username or ("@" .. player.Name),TextColor3=Theme.TextSoft,TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=17,Parent=row,
        })

        local note = New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(93,77),Size=UDim2.new(1,-106,0,17),
            Font=Enum.Font.GothamMedium,Text=opts.Note or "Serenity user",TextColor3=accentColor,TextSize=9,
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=17,Parent=row,
        })

        return {Row=row,Avatar=avatar,DisplayName=displayName,Username=username,Note=note}
    end

    function Window:CopyDiscordInvite()
        local ok = copyText(discordInvite)
        if ok then
            Window:Notify("Discord","Invite copied to your clipboard.",true)
        else
            Window:Notify("Discord","Clipboard access is not available in this environment.",false)
        end
        return ok
    end

    function Window:CommunityCard(parent, opts)
        opts = opts or {}
        local row = baseRow(parent, opts.Height or 118)
        local color = opts.Accent or Theme.Lavender

        local line = New("Frame", {BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.fromOffset(0,0),Size=UDim2.new(0,3,1,0),ZIndex=17,Parent=row})
        Round(line,999)

        New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,0,18),
            Font=Enum.Font.GothamBold,Text=opts.Kicker or "COMMUNITY",TextColor3=color,TextSize=9,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row,
        })

        New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(14,30),Size=UDim2.new(1,-28,0,27),
            Font=Enum.Font.GothamBold,Text=opts.Title or "Join Discord for more updates",TextColor3=Theme.Text,TextSize=15,
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=17,Parent=row,
        })

        New("TextLabel", {
            BackgroundTransparency=1,Position=UDim2.fromOffset(14,57),Size=UDim2.new(1,-145,0,45),
            Font=Enum.Font.Gotham,Text=opts.Description or "Get update notes, fixes, supported-game news and Serenity Hub announcements.",
            TextColor3=Theme.TextSoft,TextSize=10,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top,ZIndex=17,Parent=row,
        })

        local copy = New("Frame", {
            AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-12,1,-12),Size=UDim2.fromOffset(120,34),
            BackgroundColor3=Theme.Panel3,BackgroundTransparency=.48,ZIndex=17,Parent=row,
        })
        Round(copy,10)
        Stroke(copy,color,.64,1)

        local label = New("TextLabel", {
            BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamMedium,
            Text=opts.ButtonText or "Copy Discord Invite",TextColor3=Theme.Text,TextSize=9,ZIndex=18,Parent=copy,
        })

        local hit = Overlay(copy,function() Window:CopyDiscordInvite() end)
        hit.MouseEnter:Connect(function()
            Tween(copy,.12,{BackgroundTransparency=.30})
            Tween(label,.12,{TextColor3=color})
        end)
        hit.MouseLeave:Connect(function()
            Tween(copy,.12,{BackgroundTransparency=.48})
            Tween(label,.12,{TextColor3=Theme.Text})
        end)

        return row
    end

    function Window:Hero(parent, kicker, title, description, accentName)
        local row = baseRow(parent,112)
        local color = accentName == "mint" and Theme.Mint
            or accentName == "lavender" and Theme.Lavender
            or Theme.Cyan

        local line = New("Frame", {BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.fromOffset(0,0),Size=UDim2.new(0,3,1,0),ZIndex=17,Parent=row})
        Round(line,999)

        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,0,18),Font=Enum.Font.GothamBold,Text=kicker or "",TextColor3=color,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row})
        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(14,31),Size=UDim2.new(1,-28,0,30),Font=Enum.Font.GothamBold,Text=title or "",TextColor3=Theme.Text,TextSize=18,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row})
        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(14,65),Size=UDim2.new(1,-28,0,35),Font=Enum.Font.Gotham,Text=description or "",TextColor3=Theme.TextSoft,TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=17,Parent=row})
        return row
    end

    function Window:Paragraph(parent, title, text)
        local row = baseRow(parent,74)
        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,18),Font=Enum.Font.GothamMedium,Text=title,TextColor3=Theme.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row})
        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(12,29),Size=UDim2.new(1,-24,1,-36),Font=Enum.Font.Gotham,Text=text,TextColor3=Theme.TextSoft,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=17,Parent=row})
        return row
    end

    function Window:Live(parent, title, value, height)
        local row = baseRow(parent,height or 58)
        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-24,0,16),Font=Enum.Font.GothamMedium,Text=title,TextColor3=Theme.TextDim,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row})
        local label = New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(12,24),Size=UDim2.new(1,-24,1,-28),Font=Enum.Font.GothamMedium,Text=tostring(value or "--"),TextColor3=Theme.Text,TextSize=13,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=17,Parent=row})
        return label
    end

    function Window:Toggle(parent, key, title, default, callback)
        local row = baseRow(parent,48)
        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-72,1,0),Font=Enum.Font.GothamMedium,Text=title,TextColor3=Theme.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row})

        local track = New("Frame", {AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-12,.5,0),Size=UDim2.fromOffset(42,22),BackgroundColor3=Theme.Track,BackgroundTransparency=.20,ZIndex=17,Parent=row})
        Round(track,999)
        local knob = New("Frame", {AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,11,.5,0),Size=UDim2.fromOffset(16,16),BackgroundColor3=Theme.TextDim,ZIndex=18,Parent=track})
        Round(knob,999)

        local state = default == true
        local item = {}

        function item:Set(v,silent)
            state = v == true
            Tween(track,.13,{BackgroundColor3=state and Theme.CyanDark or Theme.Track,BackgroundTransparency=state and .03 or .20})
            Tween(knob,.13,{Position=state and UDim2.new(1,-11,.5,0) or UDim2.new(0,11,.5,0),BackgroundColor3=state and Theme.White or Theme.TextDim})
            if not silent and callback then callback(state) end
        end

        function item:Get() return state end
        Overlay(row,function() item:Set(not state,false) end)
        item:Set(state,true)
        Window.Items[key] = item
        return item
    end

    function Window:Button(parent, title, callback, danger)
        local row = baseRow(parent,46)
        New("TextLabel", {BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamMedium,Text=title,TextColor3=danger and Theme.Danger or Theme.Text,TextSize=13,ZIndex=17,Parent=row})
        local hit = Overlay(row,callback)
        hit.MouseEnter:Connect(function() Tween(row,.12,{BackgroundTransparency=.58}) end)
        hit.MouseLeave:Connect(function() Tween(row,.12,{BackgroundTransparency=.78}) end)
        return row
    end

    function Window:Dropdown(parent, key, title, values, default, callback)
        local row = baseRow(parent,50)
        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(12,0),Size=UDim2.new(.53,-12,1,0),Font=Enum.Font.GothamMedium,Text=title,TextColor3=Theme.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row})

        local valueLabel = New("TextLabel", {AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-12,.5,0),Size=UDim2.new(.45,0,0,30),BackgroundColor3=Theme.Panel3,BackgroundTransparency=.48,Font=Enum.Font.GothamMedium,Text=tostring(default or values[1]),TextColor3=Theme.Cyan,TextSize=12,ZIndex=17,Parent=row})
        Round(valueLabel,9)
        Stroke(valueLabel,Theme.StrokeSoft,.78,1)

        local value = default or values[1]
        local item = {}
        function item:Set(v,silent)
            local found = false
            for _, option in ipairs(values) do if option == v then found = true break end end
            if not found then return false end
            value = v
            valueLabel.Text = tostring(v)
            if not silent and callback then callback(v) end
            return true
        end
        function item:Get() return value end
        Overlay(row,function()
            local index = table.find(values,value) or 1
            index = (index % #values) + 1
            item:Set(values[index],false)
        end)
        Window.Items[key] = item
        return item
    end

    function Window:Slider(parent, key, title, minValue, maxValue, default, callback, suffix)
        local row = baseRow(parent,64)
        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(12,4),Size=UDim2.new(.65,-12,0,24),Font=Enum.Font.GothamMedium,Text=title,TextColor3=Theme.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=row})
        local valueLabel = New("TextLabel", {BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,4),Size=UDim2.fromOffset(100,24),Font=Enum.Font.GothamMedium,TextColor3=Theme.Cyan,TextSize=12,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=17,Parent=row})
        local bar = New("Frame", {Position=UDim2.fromOffset(12,40),Size=UDim2.new(1,-24,0,8),BackgroundColor3=Theme.Track,BackgroundTransparency=.10,ZIndex=17,Parent=row})
        Round(bar,999)
        local fill = New("Frame", {BackgroundColor3=Theme.Cyan,Size=UDim2.new(0,0,1,0),ZIndex=18,Parent=bar})
        Round(fill,999)

        local value = math.clamp(tonumber(default) or minValue,minValue,maxValue)
        local item = {}
        function item:Set(v,silent)
            value = math.clamp(tonumber(v) or value,minValue,maxValue)
            local alpha = (value-minValue)/(maxValue-minValue)
            fill.Size = UDim2.new(alpha,0,1,0)
            valueLabel.Text = tostring(math.floor(value+.5)) .. (suffix or "")
            if not silent and callback then callback(value) end
        end
        function item:Get() return value end

        local dragging = false
        local function fromX(x)
            local alpha = math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
            item:Set(minValue+(maxValue-minValue)*alpha,false)
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging=true
                fromX(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                fromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging=false end
        end)

        item:Set(value,true)
        Window.Items[key] = item
        return item
    end

    function Window:SetStatus(text, mode)
        statusText.Text = tostring(text or "READY")
        statusDot.BackgroundColor3 = mode == "error" and Theme.Danger
            or mode == "warning" and Theme.Warning
            or mode == "idle" and Theme.TextDim
            or Theme.Mint
    end

    function Window:Notify(title,text,good)
        local toast = New("Frame", {
            AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-18),Size=UDim2.fromOffset(310,82),
            BackgroundColor3=Theme.Panel,BackgroundTransparency=.18,ZIndex=220,Parent=gui
        })
        Round(toast,14)
        Stroke(toast,good==false and Theme.Danger or Theme.Cyan,.50,1)
        Glass(toast,.35,.62)

        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(13,9),Size=UDim2.new(1,-26,0,22),Font=Enum.Font.GothamMedium,Text=tostring(title or "SERENITY HUB"),TextColor3=Theme.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=221,Parent=toast})
        New("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromOffset(13,33),Size=UDim2.new(1,-26,1,-42),Font=Enum.Font.Gotham,Text=tostring(text or ""),TextColor3=Theme.TextSoft,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=221,Parent=toast})

        toast.Position = UDim2.new(1,330,1,-18)
        Tween(toast,.22,{Position=UDim2.new(1,-18,1,-18)})
        task.delay(3.2,function()
            if toast.Parent then
                Tween(toast,.18,{Position=UDim2.new(1,330,1,-18)}).Completed:Wait()
                toast:Destroy()
            end
        end)
    end

    local launcher = New("Frame", {
        AnchorPoint = Vector2.new(.5,.5),Position = UDim2.fromScale(.08,.50),Size = UDim2.fromOffset(64,64),
        BackgroundColor3 = Theme.Panel,BackgroundTransparency = .14,Visible = false,ZIndex = 205,Parent = gui,
    })
    Round(launcher,999)
    Stroke(launcher,Theme.Cyan,.35,1)
    Glass(launcher,.25,.55)

    New("ImageLabel", {
        AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(42,42),
        BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Image=logoId,ImageColor3=Theme.White,ZIndex=206,Parent=launcher
    })

    local launcherHit = Overlay(launcher,nil,207)
    makeDraggable(launcherHit,launcher)
    launcherHit.MouseEnter:Connect(function() Tween(launcher,.14,{BackgroundTransparency=.04,Size=UDim2.fromOffset(68,68)}) end)
    launcherHit.MouseLeave:Connect(function() Tween(launcher,.14,{BackgroundTransparency=.14,Size=UDim2.fromOffset(64,64)}) end)

    local minimized = false

    function Window:Minimize()
        if minimized then return end
        minimized = true
        Tween(main,.18,{Size=UDim2.fromOffset(width*.92,height*.92),BackgroundTransparency=.55}).Completed:Wait()
        main.Visible = false
        launcher.Visible = true
    end

    function Window:Restore()
        if not minimized then return end
        minimized = false
        launcher.Visible = false
        main.Visible = true
        main.Size = UDim2.fromOffset(width*.92,height*.92)
        Tween(main,.20,{Size=UDim2.fromOffset(width,height),BackgroundTransparency=.14})
    end

    launcherHit.MouseButton1Click:Connect(function()
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            Window:Restore()
        end
    end)

    function Window:Close()
        if gui then gui:Destroy() end
    end

    topButton("close",-16,function() Window:Close() end)
    topButton("minimize",-58,function() Window:Minimize() end)
    makeDraggable(topbar,main)

    function Window:Open()
        main.Visible = true
        main.Size = UDim2.fromOffset(94,60)
        main.BackgroundTransparency = .60
        Tween(main,.20,{Size=UDim2.fromOffset(width,60),BackgroundTransparency=.24}).Completed:Wait()
        Tween(main,.24,{Size=UDim2.fromOffset(width,height),BackgroundTransparency=.14})
    end

    return Window
end

return Library
