--[[
    Saturn UI Library — Minimalist Dark Cheat Interface
    Matches Saturn Visual Identity (Matte Black, Clean Borders, Dynamic Elements)
    Designed for external/internal scripts on Luau (Roblox)
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local SaturnLib = {
    Flags = {},
    Themes = {
        Background = Color3.fromRGB(14, 14, 19),
        BackgroundTransparency = 0.15,
        Sidebar = Color3.fromRGB(11, 11, 15),
        Section = Color3.fromRGB(16, 16, 22),
        SectionTransparency = 0.35,
        Element = Color3.fromRGB(22, 22, 30),
        ElementTransparency = 0.35,
        ElementHover = Color3.fromRGB(30, 30, 42),
        Border = Color3.fromRGB(255, 255, 255),
        BorderTransparency = 0.88,
        Text = Color3.fromRGB(245, 245, 250),
        TextDim = Color3.fromRGB(140, 140, 155),
        Accent = Color3.fromRGB(255, 255, 255),
        AccentDim = Color3.fromRGB(200, 200, 210),
    },
    CurrentTab = nil,
    ToggleKey = Enum.KeyCode.RightShift,
    IsOpen = true,
}

-- Safe modern font resolver
local function getFont(weight)
    local hasBuilder = pcall(function() return Enum.Font.BuilderSans end)
    if hasBuilder then
        if weight == "Bold" then
            return Enum.Font.BuilderSansBold
        elseif weight == "Medium" then
            return Enum.Font.BuilderSansMedium
        else
            return Enum.Font.BuilderSans
        end
    else
        if weight == "Bold" then
            return Enum.Font.GothamBold
        elseif weight == "Medium" then
            return Enum.Font.GothamMedium
        else
            return Enum.Font.Gotham
        end
    end
end

-- Typography: Montserrat via FontFace (falls back to the enum font above)
local FONT_FAMILY = "rbxasset://fonts/families/Montserrat.json"

local function applyFont(obj, weight)
    local weightEnum = Enum.FontWeight.Regular
    if weight == "Bold" then
        weightEnum = Enum.FontWeight.Bold
    elseif weight == "Medium" then
        weightEnum = Enum.FontWeight.Medium
    elseif weight == "SemiBold" then
        weightEnum = Enum.FontWeight.SemiBold
    end
    local ok = pcall(function()
        obj.FontFace = Font.new(FONT_FAMILY, weightEnum)
    end)
    if not ok then
        obj.Font = getFont(weight)
    end
end

-- Safe GUI container
local function getGuiParent()
    if gethui then
        return gethui()
    elseif syn and syn.protect_gui then
        local gui = Instance.new("Folder")
        syn.protect_gui(gui)
        gui.Parent = CoreGui
        return gui
    elseif CoreGui:FindFirstChild("RobloxGui") then
        return CoreGui
    else
        return LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Download / Cache Saturn Icon
local function getSaturnIcon()
    local ICON_FILE = "saturn_logo.png"
    local ICON_URL = "https://raw.githubusercontent.com/buysaturn/saturn.github.io/main/saturn.png"
    local success, asset = pcall(function()
        if writefile and readfile and isfile and getcustomasset then
            if not isfile(ICON_FILE) then
                local data = game:HttpGet(ICON_URL)
                writefile(ICON_FILE, data)
            end
            return getcustomasset(ICON_FILE)
        end
    end)
    if success and asset then
        return asset
    end
    return "rbxassetid://10747373176"
end

-- Utility: Make UI draggable
local function makeDraggable(topbar, frame)
    local dragging = false
    local dragInput, dragStart, startPos
    local moved = 0

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = 0
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            moved = math.max(moved, math.abs(delta.X) + math.abs(delta.Y))
            TweenService:Create(frame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            }):Play()
        end
    end)

    -- Lets click handlers tell a drag apart from a plain click
    return {
        WasDragged = function()
            return moved > 4
        end
    }
end

-- Notification System
function SaturnLib:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Saturn"
    local content = opts.Content or ""
    local duration = opts.Duration or 3

    local notifyGui = CoreGui:FindFirstChild("SaturnNotifyGui")
    if not notifyGui then
        notifyGui = Instance.new("ScreenGui")
        notifyGui.Name = "SaturnNotifyGui"
        notifyGui.ResetOnSpawn = false
        notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notifyGui.Parent = getGuiParent()
    end

    local notifyHolder = notifyGui:FindFirstChild("NotifyHolder")
    if not notifyHolder then
        notifyHolder = Instance.new("Frame")
        notifyHolder.Name = "NotifyHolder"
        notifyHolder.AnchorPoint = Vector2.new(1, 1)
        notifyHolder.Position = UDim2.new(1, -20, 1, -20)
        notifyHolder.Size = UDim2.new(0, 280, 1, -40)
        notifyHolder.BackgroundTransparency = 1
        notifyHolder.Parent = notifyGui

        local layout = Instance.new("UIListLayout")
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)
        layout.Parent = notifyHolder
    end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = SaturnLib.Themes.Background
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Position = UDim2.new(1, 50, 0, 0)
    card.Parent = notifyHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = SaturnLib.Themes.Border
    stroke.Transparency = SaturnLib.Themes.BorderTransparency
    stroke.Parent = card

    local tLabel = Instance.new("TextLabel")
    tLabel.Position = UDim2.new(0, 14, 0, 10)
    tLabel.Size = UDim2.new(1, -28, 0, 16)
    tLabel.BackgroundTransparency = 1
    applyFont(tLabel, "Bold")
    tLabel.Text = title
    tLabel.TextColor3 = SaturnLib.Themes.Text
    tLabel.TextSize = 13
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.Parent = card

    local cLabel = Instance.new("TextLabel")
    cLabel.Position = UDim2.new(0, 14, 0, 28)
    cLabel.Size = UDim2.new(1, -28, 0, 22)
    cLabel.BackgroundTransparency = 1
    applyFont(cLabel, "Medium")
    cLabel.Text = content
    cLabel.TextColor3 = SaturnLib.Themes.TextDim
    cLabel.TextSize = 12
    cLabel.TextXAlignment = Enum.TextXAlignment.Left
    cLabel.TextWrapped = true
    cLabel.Parent = card

    -- Slide in
    TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05
    }):Play()

    task.delay(duration, function()
        local out = TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        out:Play()
        out.Completed:Connect(function()
            card:Destroy()
        end)
    end)
end

-- Create Main Window
function SaturnLib:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "Saturn"
    local SubTitleText = config.SubTitle or "v1.0"
    local SizeX = config.SizeX or 620
    local SizeY = config.SizeY or 420
    SaturnLib.ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift

    -- Blur strength (two stacked passes ≈ double-loaded look)
    local BLUR_STRENGTH = 48

    -- Clean old instances
    if CoreGui:FindFirstChild("SaturnLibGui") then
        CoreGui.SaturnLibGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SaturnLibGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = getGuiParent()

    -- Window Frame (Unified Minimalist Glass Card)
    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0, SizeX, 0, SizeY)
    Main.BackgroundColor3 = SaturnLib.Themes.Background
    Main.BackgroundTransparency = SaturnLib.Themes.BackgroundTransparency
    Main.BorderSizePixel = 0
    -- Clip children so nothing (scrollbars, section edges) bleeds through the rounded corners
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = SaturnLib.Themes.Border
    MainStroke.Transparency = SaturnLib.Themes.BorderTransparency
    MainStroke.Thickness = 1
    MainStroke.Parent = Main

    -- Deep Stacked Lighting Blur (multi-pass Gaussian)
    local Lighting = game:GetService("Lighting")
    for _, child in ipairs(Lighting:GetChildren()) do
        if child.Name:find("SaturnLibBlur") then
            child:Destroy()
        end
    end

    local Blur1 = Instance.new("BlurEffect")
    Blur1.Name = "SaturnLibBlur_1"
    Blur1.Size = 0
    Blur1.Parent = Lighting

    local Blur2 = Instance.new("BlurEffect")
    Blur2.Name = "SaturnLibBlur_2"
    Blur2.Size = 0
    Blur2.Parent = Lighting

    TweenService:Create(Blur1, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = BLUR_STRENGTH
    }):Play()
    TweenService:Create(Blur2, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = BLUR_STRENGTH
    }):Play()

    -- Content Body (faded as a group when minimizing; keeps children from bleeding on collapse)
    local Body = Instance.new("CanvasGroup")
    Body.Name = "Body"
    Body.Size = UDim2.new(1, 0, 1, 0)
    Body.BackgroundTransparency = 1
    Body.BorderSizePixel = 0
    Body.GroupTransparency = 0
    Body.Parent = Main

    -- Left Sidebar (Navigation) — Transparent to let Main's rounded corners & stroke render seamlessly
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundTransparency = 1
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Body

    local SidebarBorder = Instance.new("Frame")
    SidebarBorder.Name = "SidebarBorder"
    SidebarBorder.AnchorPoint = Vector2.new(1, 0)
    -- Inset so the divider never cuts through the rounded top/bottom corners
    SidebarBorder.Position = UDim2.new(1, 0, 0, 16)
    SidebarBorder.Size = UDim2.new(0, 1, 1, -32)
    SidebarBorder.BackgroundColor3 = SaturnLib.Themes.Border
    SidebarBorder.BackgroundTransparency = 0.92
    SidebarBorder.BorderSizePixel = 0
    SidebarBorder.Parent = Sidebar

    -- Top Brand Header
    local Brand = Instance.new("Frame")
    Brand.Name = "Brand"
    Brand.Size = UDim2.new(1, 0, 0, 52)
    Brand.BackgroundTransparency = 1
    Brand.Parent = Sidebar

    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.AnchorPoint = Vector2.new(0, 0.5)
    Logo.Position = UDim2.new(0, 16, 0.5, 0)
    Logo.Size = UDim2.new(0, 22, 0, 22)
    Logo.BackgroundTransparency = 1
    Logo.Image = getSaturnIcon()
    Logo.ScaleType = Enum.ScaleType.Fit
    Logo.Parent = Brand

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Position = UDim2.new(0, 46, 0, 12)
    Title.Size = UDim2.new(1, -50, 0, 18)
    Title.BackgroundTransparency = 1
    applyFont(Title, "Bold")
    Title.Text = TitleText
    Title.TextColor3 = SaturnLib.Themes.Text
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Brand

    local SubTitle = Instance.new("TextLabel")
    SubTitle.Name = "SubTitle"
    SubTitle.Position = UDim2.new(0, 46, 0, 28)
    SubTitle.Size = UDim2.new(1, -50, 0, 14)
    SubTitle.BackgroundTransparency = 1
    applyFont(SubTitle, "Medium")
    SubTitle.Text = SubTitleText
    SubTitle.TextColor3 = SaturnLib.Themes.TextDim
    SubTitle.TextSize = 10
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.Parent = Brand

    -- Tabs Scroll / List Container
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Position = UDim2.new(0, 8, 0, 56)
    TabContainer.Size = UDim2.new(1, -16, 1, -100)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    -- No clipping: the scroll frame edge was cutting thin side strokes off the tabs
    TabContainer.ClipsDescendants = false
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.Parent = Sidebar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.Parent = TabContainer

    -- Spacers keep the first/last tab stroke away from the scroll frame's clip edge
    local TabTopSpacer = Instance.new("Frame")
    TabTopSpacer.Name = "TopSpacer"
    TabTopSpacer.Size = UDim2.new(1, 0, 0, 4)
    TabTopSpacer.BackgroundTransparency = 1
    TabTopSpacer.BorderSizePixel = 0
    TabTopSpacer.LayoutOrder = -1
    TabTopSpacer.Parent = TabContainer

    local TabBottomSpacer = Instance.new("Frame")
    TabBottomSpacer.Name = "BottomSpacer"
    TabBottomSpacer.Size = UDim2.new(1, 0, 0, 8)
    TabBottomSpacer.BackgroundTransparency = 1
    TabBottomSpacer.BorderSizePixel = 0
    TabBottomSpacer.LayoutOrder = 99999
    TabBottomSpacer.Parent = TabContainer

    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y)
    end)

    -- Bottom User / Status Badge in Sidebar
    local BottomBadge = Instance.new("Frame")
    BottomBadge.Name = "BottomBadge"
    BottomBadge.AnchorPoint = Vector2.new(0, 1)
    BottomBadge.Position = UDim2.new(0, 10, 1, -10)
    BottomBadge.Size = UDim2.new(1, -20, 0, 32)
    BottomBadge.BackgroundColor3 = SaturnLib.Themes.Element
    BottomBadge.BackgroundTransparency = 0.45
    BottomBadge.BorderSizePixel = 0
    BottomBadge.Parent = Sidebar

    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 8)
    BadgeCorner.Parent = BottomBadge

    local BadgeStroke = Instance.new("UIStroke")
    BadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BadgeStroke.Color = SaturnLib.Themes.Border
    BadgeStroke.Transparency = 0.92
    BadgeStroke.Thickness = 1
    BadgeStroke.Parent = BottomBadge

    local BadgeDot = Instance.new("Frame")
    BadgeDot.AnchorPoint = Vector2.new(0, 0.5)
    BadgeDot.Position = UDim2.new(0, 10, 0.5, 0)
    BadgeDot.Size = UDim2.new(0, 6, 0, 6)
    BadgeDot.BackgroundColor3 = Color3.fromRGB(120, 230, 150)
    BadgeDot.BorderSizePixel = 0
    BadgeDot.Parent = BottomBadge

    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1, 0)
    DotCorner.Parent = BadgeDot

    local BadgeText = Instance.new("TextLabel")
    BadgeText.Position = UDim2.new(0, 22, 0, 0)
    BadgeText.Size = UDim2.new(1, -26, 1, 0)
    BadgeText.BackgroundTransparency = 1
    applyFont(BadgeText, "Medium")
    BadgeText.Text = config.BadgeText or "Active Session"
    BadgeText.TextColor3 = SaturnLib.Themes.TextDim
    BadgeText.TextSize = 11
    BadgeText.TextXAlignment = Enum.TextXAlignment.Left
    BadgeText.Parent = BottomBadge

    -- The status badge doubles as a drag handle
    makeDraggable(BottomBadge, Main)

    -- Top Bar on Right Side (Draggable & Control Buttons)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Position = UDim2.new(0, 160, 0, 0)
    TopBar.Size = UDim2.new(1, -160, 0, 44)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = Body

    makeDraggable(TopBar, Main)
    makeDraggable(Brand, Main)

    local CurrentTabLabel = Instance.new("TextLabel")
    CurrentTabLabel.Name = "CurrentTabLabel"
    CurrentTabLabel.Position = UDim2.new(0, 20, 0, 0)
    CurrentTabLabel.Size = UDim2.new(0, 250, 1, 0)
    CurrentTabLabel.BackgroundTransparency = 1
    applyFont(CurrentTabLabel, "Bold")
    CurrentTabLabel.Text = "MAIN"
    CurrentTabLabel.TextColor3 = SaturnLib.Themes.Text
    CurrentTabLabel.TextSize = 14
    CurrentTabLabel.TextXAlignment = Enum.TextXAlignment.Left
    CurrentTabLabel.Parent = TopBar

    -- Close Button (Clean ASCII 'X' matching Saturn Loader)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.Position = UDim2.new(1, -14, 0.5, 0)
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.BorderSizePixel = 0
    applyFont(CloseBtn, "Bold")
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
    CloseBtn.TextSize = 13
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = TopBar

    CloseBtn.MouseEnter:Connect(function()
        CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    CloseBtn.MouseLeave:Connect(function()
        CloseBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
    end)

    -- Minimize Button (collapses the window into the dynamic island)
    local CollapseBtn = Instance.new("TextButton")
    CollapseBtn.Name = "CollapseBtn"
    CollapseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CollapseBtn.Position = UDim2.new(1, -38, 0.5, 0)
    CollapseBtn.Size = UDim2.new(0, 24, 0, 24)
    CollapseBtn.BackgroundTransparency = 1
    CollapseBtn.BorderSizePixel = 0
    applyFont(CollapseBtn, "Bold")
    CollapseBtn.Text = "−"
    CollapseBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
    CollapseBtn.TextSize = 16
    CollapseBtn.AutoButtonColor = false
    CollapseBtn.Parent = TopBar

    CollapseBtn.MouseEnter:Connect(function()
        CollapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    CollapseBtn.MouseLeave:Connect(function()
        CollapseBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
    end)

    -- Content Area on Right Side
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Position = UDim2.new(0, 160, 0, 44)
    ContentContainer.Size = UDim2.new(1, -160, 1, -44)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = Body

    -- Dynamic Island (minimized state): fixed bottom-center pill
    local ISLAND_W = 190
    local ISLAND_H = 42
    local ISLAND_MARGIN = 28

    local Island = Instance.new("Frame")
    Island.Name = "Island"
    Island.AnchorPoint = Vector2.new(0.5, 1)
    Island.Position = UDim2.new(0.5, 0, 1, -ISLAND_MARGIN)
    Island.Size = UDim2.new(0, ISLAND_W, 0, ISLAND_H)
    Island.BackgroundColor3 = SaturnLib.Themes.Background
    Island.BackgroundTransparency = 0.05
    Island.BorderSizePixel = 0
    Island.Visible = false
    Island.ZIndex = 50
    Island.Parent = ScreenGui

    local IslandCorner = Instance.new("UICorner")
    IslandCorner.CornerRadius = UDim.new(1, 0)
    IslandCorner.Parent = Island

    local IslandStroke = Instance.new("UIStroke")
    IslandStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    IslandStroke.Color = SaturnLib.Themes.Border
    IslandStroke.Transparency = SaturnLib.Themes.BorderTransparency
    IslandStroke.Thickness = 1
    IslandStroke.Parent = Island

    local IslandIcon = Instance.new("ImageLabel")
    IslandIcon.Name = "Icon"
    IslandIcon.AnchorPoint = Vector2.new(0, 0.5)
    IslandIcon.Position = UDim2.new(0, 13, 0.5, 0)
    IslandIcon.Size = UDim2.new(0, 22, 0, 22)
    IslandIcon.BackgroundTransparency = 1
    IslandIcon.Image = Logo.Image
    IslandIcon.ScaleType = Enum.ScaleType.Fit
    IslandIcon.ZIndex = 51
    IslandIcon.Parent = Island

    local IslandTitle = Instance.new("TextLabel")
    IslandTitle.Name = "Title"
    IslandTitle.Position = UDim2.new(0, 43, 0, 0)
    IslandTitle.Size = UDim2.new(0, 60, 1, 0)
    IslandTitle.BackgroundTransparency = 1
    applyFont(IslandTitle, "Bold")
    IslandTitle.Text = TitleText
    IslandTitle.TextColor3 = SaturnLib.Themes.Text
    IslandTitle.TextSize = 13
    IslandTitle.TextXAlignment = Enum.TextXAlignment.Left
    IslandTitle.ZIndex = 51
    IslandTitle.Parent = Island

    local IslandFps = Instance.new("TextLabel")
    IslandFps.Name = "Fps"
    IslandFps.AnchorPoint = Vector2.new(1, 0.5)
    IslandFps.Position = UDim2.new(1, -15, 0.5, 0)
    IslandFps.Size = UDim2.new(0, 64, 0, 16)
    IslandFps.BackgroundTransparency = 1
    applyFont(IslandFps, "Medium")
    IslandFps.Text = "60 FPS"
    IslandFps.TextColor3 = SaturnLib.Themes.TextDim
    IslandFps.TextSize = 11
    IslandFps.TextXAlignment = Enum.TextXAlignment.Right
    IslandFps.ZIndex = 51
    IslandFps.Parent = Island

    -- Click surface (the island is fixed, not draggable)
    local IslandHit = Instance.new("TextButton")
    IslandHit.Name = "IslandHit"
    IslandHit.Size = UDim2.new(1, 0, 1, 0)
    IslandHit.BackgroundTransparency = 1
    IslandHit.BorderSizePixel = 0
    IslandHit.Text = ""
    IslandHit.AutoButtonColor = false
    IslandHit.ZIndex = 55
    IslandHit.Parent = Island

    IslandHit.MouseEnter:Connect(function()
        TweenService:Create(Island, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        }):Play()
    end)
    IslandHit.MouseLeave:Connect(function()
        TweenService:Create(Island, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.05
        }):Play()
    end)

    -- Live FPS counter (updates every 0.25s)
    local fpsAccum = 0
    local fpsFrames = 0
    RunService.RenderStepped:Connect(function(dt)
        fpsAccum = fpsAccum + dt
        fpsFrames = fpsFrames + 1
        if fpsAccum >= 0.25 then
            local fps = math.floor(fpsFrames / fpsAccum + 0.5)
            fpsAccum = 0
            fpsFrames = 0
            if IslandFps and IslandFps.Parent then
                IslandFps.Text = tostring(fps) .. " FPS"
            end
        end
    end)

    local Collapsed = false
    local RestorePosition = Main.Position
    local Transitioning = false

    local function fadeBody(target, duration)
        if Body:IsA("CanvasGroup") then
            TweenService:Create(Body, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                GroupTransparency = target
            }):Play()
        end
    end

    local function setBlur(size, duration)
        if Blur1 then
            TweenService:Create(Blur1, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = size
            }):Play()
        end
        if Blur2 then
            TweenService:Create(Blur2, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = size
            }):Play()
        end
    end

    -- Island center in ScreenGui space (fixed bottom-center, independent of window drag)
    local function getIslandCenter()
        local viewport = ScreenGui.AbsoluteSize
        if viewport.X <= 0 or viewport.Y <= 0 then
            local camera = workspace.CurrentCamera
            if camera then
                viewport = camera.ViewportSize
            end
        end
        return UDim2.fromOffset(viewport.X / 2, viewport.Y - ISLAND_MARGIN - ISLAND_H / 2)
    end

    local function collapseWindow()
        if Collapsed or Transitioning then
            return
        end
        Collapsed = true
        Transitioning = true
        SaturnLib.IsOpen = false
        RestorePosition = Main.Position

        Island.Visible = false
        Body.Visible = true
        fadeBody(1, 0.16)
        setBlur(0, 0.28)

        TweenService:Create(MainCorner, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            CornerRadius = UDim.new(1, 0)
        }):Play()

        -- Window flies into the fixed island at the bottom center
        local tween = TweenService:Create(Main, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = getIslandCenter(),
            Size = UDim2.new(0, ISLAND_W, 0, ISLAND_H),
            BackgroundTransparency = 0.05
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not Collapsed then
                return
            end
            Body.Visible = false
            Main.Visible = false
            Island.Visible = true
            Transitioning = false
        end)
    end

    local function expandWindow()
        if not Collapsed or Transitioning then
            return
        end
        Collapsed = false
        Transitioning = true
        SaturnLib.IsOpen = true

        Island.Visible = false
        Main.Visible = true
        Main.Position = getIslandCenter()
        Main.Size = UDim2.new(0, ISLAND_W, 0, ISLAND_H)
        Main.BackgroundTransparency = 0.05
        MainCorner.CornerRadius = UDim.new(1, 0)
        Body.Visible = true
        Body.GroupTransparency = 1
        fadeBody(0, 0.26)
        setBlur(BLUR_STRENGTH, 0.3)

        TweenService:Create(MainCorner, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            CornerRadius = UDim.new(0, 16)
        }):Play()

        -- Fly back to the exact spot where the menu was closed
        local tween = TweenService:Create(Main, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = RestorePosition,
            Size = UDim2.new(0, SizeX, 0, SizeY),
            BackgroundTransparency = SaturnLib.Themes.BackgroundTransparency
        })
        tween:Play()
        tween.Completed:Connect(function()
            if Collapsed then
                return
            end
            Transitioning = false
        end)
    end

    CollapseBtn.MouseButton1Click:Connect(collapseWindow)
    CloseBtn.MouseButton1Click:Connect(collapseWindow)
    IslandHit.MouseButton1Click:Connect(expandWindow)

    -- Toggle Hotkey handling (Right Shift always works, plus any custom ToggleKey):
    -- expanded -> flies into the dynamic island, island -> expands back
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if input.KeyCode ~= Enum.KeyCode.RightShift and input.KeyCode ~= SaturnLib.ToggleKey then
            return
        end
        if Transitioning then
            return
        end

        if not Main.Visible or Collapsed then
            SaturnLib:Toggle(true)
        else
            collapseWindow()
        end
    end)

    function SaturnLib:Toggle(state)
        if state == nil then
            SaturnLib.IsOpen = not SaturnLib.IsOpen
        else
            SaturnLib.IsOpen = state
        end

        if SaturnLib.IsOpen then
            Main.Visible = true
            if Collapsed then
                expandWindow()
            else
                TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, SizeX, 0, SizeY),
                    BackgroundTransparency = SaturnLib.Themes.BackgroundTransparency
                }):Play()
            end
            if Blur1 then
                TweenService:Create(Blur1, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = BLUR_STRENGTH
                }):Play()
            end
            if Blur2 then
                TweenService:Create(Blur2, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = BLUR_STRENGTH
                }):Play()
            end
        else
            if Collapsed then
                -- Full hide (API): drop the island and reset the window to its restore spot
                Collapsed = false
                Transitioning = false
                Island.Visible = false
                Main.Visible = false
                Main.Position = RestorePosition
                Main.Size = UDim2.new(0, SizeX, 0, SizeY)
                Main.BackgroundTransparency = SaturnLib.Themes.BackgroundTransparency
                MainCorner.CornerRadius = UDim.new(0, 16)
                setBlur(0, 0.2)
                return
            end
            local t = TweenService:Create(Main, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(0, SizeX, 0, 0),
                BackgroundTransparency = 1
            })
            t:Play()
            if Blur1 then
                TweenService:Create(Blur1, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    Size = 0
                }):Play()
            end
            if Blur2 then
                TweenService:Create(Blur2, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    Size = 0
                }):Play()
            end
            t.Completed:Connect(function()
                if not SaturnLib.IsOpen then
                    Main.Visible = false
                end
            end)
        end
    end

    local WindowObj = {
        ScreenGui = ScreenGui,
        Main = Main,
        Blur1 = Blur1,
        Blur2 = Blur2,
        Tabs = {},
    }

    function WindowObj:Destroy()
        if Blur1 then
            Blur1:Destroy()
        end
        if Blur2 then
            Blur2:Destroy()
        end
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end

    -- Minimize to the dynamic island / restore
    function WindowObj:Collapse()
        collapseWindow()
    end

    function WindowObj:Expand()
        expandWindow()
    end

    -- Create Tab
    function WindowObj:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or nil

        -- Tab Button in Sidebar
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = tabName .. "_Btn"
        TabBtn.Size = UDim2.new(1, 0, 0, 34)
        TabBtn.BackgroundColor3 = SaturnLib.Themes.Element
        TabBtn.BackgroundTransparency = 1
        TabBtn.BorderSizePixel = 0
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        TabBtn.Parent = TabContainer

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 8)
        TabCorner.Parent = TabBtn

        local TabStroke = Instance.new("UIStroke")
        TabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        TabStroke.Color = SaturnLib.Themes.Border
        TabStroke.Transparency = 1
        TabStroke.Thickness = 1
        TabStroke.Parent = TabBtn

        local TabIndicator = Instance.new("Frame")
        TabIndicator.Name = "Indicator"
        TabIndicator.AnchorPoint = Vector2.new(0, 0.5)
        TabIndicator.Position = UDim2.new(0, 6, 0.5, 0)
        TabIndicator.Size = UDim2.new(0, 3, 0, 0)
        TabIndicator.BackgroundColor3 = SaturnLib.Themes.Accent
        TabIndicator.BorderSizePixel = 0
        TabIndicator.Parent = TabBtn

        local IndCorner = Instance.new("UICorner")
        IndCorner.CornerRadius = UDim.new(1, 0)
        IndCorner.Parent = TabIndicator

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "Label"
        TabLabel.Position = UDim2.new(0, 16, 0, 0)
        TabLabel.Size = UDim2.new(1, -20, 1, 0)
        TabLabel.BackgroundTransparency = 1
        applyFont(TabLabel, "Medium")
        TabLabel.Text = tabName:upper()
        TabLabel.TextColor3 = SaturnLib.Themes.TextDim
        TabLabel.TextSize = 12
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabBtn

        -- Tab Page (Scrolling Frame inside ContentContainer)
        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = tabName .. "_Page"
        -- Inset from the window edge so the scrollbar never crosses the rounded corners
        TabPage.Size = UDim2.new(1, -6, 1, -8)
        TabPage.Position = UDim2.new(0, 0, 0, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabPage.Visible = false
        TabPage.Parent = ContentContainer

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 8)
        PagePadding.PaddingBottom = UDim.new(0, 18)
        PagePadding.PaddingLeft = UDim.new(0, 16)
        PagePadding.PaddingRight = UDim.new(0, 16)
        PagePadding.Parent = TabPage

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 18)
        PageLayout.Parent = TabPage

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 24)
        end)

        local TabObj = {
            Name = tabName,
            Button = TabBtn,
            Page = TabPage,
        }

        local function activateTab()
            for _, t in ipairs(WindowObj.Tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.15), {
                    BackgroundTransparency = 1
                }):Play()
                local s = t.Button:FindFirstChildOfClass("UIStroke")
                if s then
                    TweenService:Create(s, TweenInfo.new(0.15), {
                        Transparency = 1
                    }):Play()
                end
                TweenService:Create(t.Button.Label, TweenInfo.new(0.15), {
                    TextColor3 = SaturnLib.Themes.TextDim
                }):Play()
                TweenService:Create(t.Button.Indicator, TweenInfo.new(0.15), {
                    Size = UDim2.new(0, 3, 0, 0)
                }):Play()
            end

            TabPage.Visible = true
            CurrentTabLabel.Text = tabName:upper()
            TweenService:Create(TabBtn, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.4
            }):Play()
            if TabStroke then
                TweenService:Create(TabStroke, TweenInfo.new(0.15), {
                    Transparency = 0.90
                }):Play()
            end
            TweenService:Create(TabLabel, TweenInfo.new(0.15), {
                TextColor3 = SaturnLib.Themes.Text
            }):Play()
            TweenService:Create(TabIndicator, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 3, 0, 16)
            }):Play()
        end

        TabBtn.MouseButton1Click:Connect(activateTab)

        -- If first tab, auto activate
        if #WindowObj.Tabs == 0 then
            activateTab()
        end

        table.insert(WindowObj.Tabs, TabObj)

        -- Create Section (flat list style: title + divider, rows without card blocks)
        function TabObj:CreateSection(secTitle)
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = (secTitle or "Section") .. "_Section"
            SectionFrame.Size = UDim2.new(1, 0, 0, 24)
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.BorderSizePixel = 0
            SectionFrame.Parent = TabPage

            local SecHeader = Instance.new("Frame")
            SecHeader.Name = "Header"
            SecHeader.Size = UDim2.new(1, 0, 0, 22)
            SecHeader.BackgroundTransparency = 1
            SecHeader.Parent = SectionFrame

            local SecTitleLabel = Instance.new("TextLabel")
            SecTitleLabel.Position = UDim2.new(0, 0, 0, 0)
            SecTitleLabel.Size = UDim2.new(1, 0, 1, 0)
            SecTitleLabel.BackgroundTransparency = 1
            applyFont(SecTitleLabel, "Bold")
            SecTitleLabel.Text = (secTitle or "SECTION"):upper()
            SecTitleLabel.TextColor3 = SaturnLib.Themes.AccentDim
            SecTitleLabel.TextSize = 12
            SecTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            SecTitleLabel.Parent = SecHeader

            local SecHeaderLine = Instance.new("Frame")
            SecHeaderLine.Name = "HeaderLine"
            SecHeaderLine.Position = UDim2.new(0, 0, 0, 22)
            SecHeaderLine.Size = UDim2.new(1, 0, 0, 1)
            SecHeaderLine.BackgroundColor3 = SaturnLib.Themes.Border
            SecHeaderLine.BackgroundTransparency = 0.82
            SecHeaderLine.BorderSizePixel = 0
            SecHeaderLine.Parent = SectionFrame

            local SecContainer = Instance.new("Frame")
            SecContainer.Name = "Container"
            SecContainer.Position = UDim2.new(0, 0, 0, 27)
            SecContainer.Size = UDim2.new(1, 0, 0, 0)
            SecContainer.BackgroundTransparency = 1
            SecContainer.Parent = SectionFrame

            local SecLayout = Instance.new("UIListLayout")
            SecLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SecLayout.Padding = UDim.new(0, 6)
            SecLayout.Parent = SecContainer

            local function updateSecSize()
                local contentH = SecLayout.AbsoluteContentSize.Y
                SectionFrame.Size = UDim2.new(1, 0, 0, 27 + contentH)
                SecContainer.Size = UDim2.new(1, 0, 0, contentH)
            end

            SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSecSize)

            -- Row styling: one full-width rounded block per setting (same look as the active tab)
            local function styleRow(Item)
                Item.BackgroundColor3 = SaturnLib.Themes.Element
                Item.BackgroundTransparency = 0.40
                Item.BorderSizePixel = 0
                local stroke = Item:FindFirstChildOfClass("UIStroke")
                if stroke then
                    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    stroke.Color = SaturnLib.Themes.Border
                    stroke.Transparency = 0.90
                    stroke.Thickness = 1
                end
            end

            local SecObj = {}

            -- Toggle Control
            function SecObj:CreateToggle(opts)
                opts = opts or {}
                local name = opts.Name or "Toggle"
                local default = opts.Default or false
                local flag = opts.Flag or nil
                local callback = opts.Callback or function() end

                local state = default
                if flag then SaturnLib.Flags[flag] = state end

                local Item = Instance.new("TextButton")
                Item.Name = name .. "_Toggle"
                Item.Size = UDim2.new(1, 0, 0, 40)
                Item.BackgroundColor3 = SaturnLib.Themes.Element
                Item.BackgroundTransparency = SaturnLib.Themes.ElementTransparency
                Item.BorderSizePixel = 0
                Item.AutoButtonColor = false
                Item.Text = ""
                Item.Parent = SecContainer

                local ItemCorner = Instance.new("UICorner")
                ItemCorner.CornerRadius = UDim.new(0, 8)
                ItemCorner.Parent = Item

                local ItemStroke = Instance.new("UIStroke")
                ItemStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ItemStroke.Color = SaturnLib.Themes.Border
                ItemStroke.Transparency = 0.93
                ItemStroke.Thickness = 1
                ItemStroke.Parent = Item

                local Label = Instance.new("TextLabel")
                Label.Position = UDim2.new(0, 12, 0, 0)
                Label.Size = UDim2.new(1, -60, 1, 0)
                Label.BackgroundTransparency = 1
                applyFont(Label, "Medium")
                Label.Text = name
                Label.TextColor3 = SaturnLib.Themes.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Item

                local Switch = Instance.new("Frame")
                Switch.AnchorPoint = Vector2.new(1, 0.5)
                Switch.Position = UDim2.new(1, -10, 0.5, 0)
                Switch.Size = UDim2.new(0, 36, 0, 20)
                Switch.BackgroundColor3 = state and SaturnLib.Themes.Accent or Color3.fromRGB(35, 35, 48)
                Switch.BorderSizePixel = 0
                Switch.Parent = Item

                local SwitchCorner = Instance.new("UICorner")
                SwitchCorner.CornerRadius = UDim.new(1, 0)
                SwitchCorner.Parent = Switch

                local Circle = Instance.new("Frame")
                Circle.AnchorPoint = Vector2.new(0, 0.5)
                Circle.Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                Circle.Size = UDim2.new(0, 16, 0, 16)
                Circle.BackgroundColor3 = state and Color3.fromRGB(15, 15, 20) or Color3.fromRGB(120, 120, 135)
                Circle.BorderSizePixel = 0
                Circle.Parent = Switch

                local CircleCorner = Instance.new("UICorner")
                CircleCorner.CornerRadius = UDim.new(1, 0)
                CircleCorner.Parent = Circle

                local function setToggle(val)
                    state = val
                    if flag then SaturnLib.Flags[flag] = state end
                    TweenService:Create(Switch, TweenInfo.new(0.15), {
                        BackgroundColor3 = state and SaturnLib.Themes.Accent or Color3.fromRGB(35, 35, 48)
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.15), {
                        Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                        BackgroundColor3 = state and Color3.fromRGB(15, 15, 20) or Color3.fromRGB(120, 120, 135)
                    }):Play()
                    pcall(callback, state)
                end

                Item.MouseButton1Click:Connect(function()
                    setToggle(not state)
                end)

                if default then
                    pcall(callback, state)
                end

                styleRow(Item)

                return {
                    Set = setToggle,
                    Get = function() return state end
                }
            end

            -- Slider Control
            function SecObj:CreateSlider(opts)
                opts = opts or {}
                local name = opts.Name or "Slider"
                local min = opts.Min or 0
                local max = opts.Max or 100
                local default = opts.Default or min
                local suffix = opts.Suffix or ""
                local decimals = opts.Decimals or 0
                local flag = opts.Flag or nil
                local callback = opts.Callback or function() end

                local value = math.clamp(default, min, max)
                if flag then SaturnLib.Flags[flag] = value end

                local Item = Instance.new("Frame")
                Item.Name = name .. "_Slider"
                Item.Size = UDim2.new(1, 0, 0, 40)
                Item.BackgroundColor3 = SaturnLib.Themes.Element
                Item.BackgroundTransparency = SaturnLib.Themes.ElementTransparency
                Item.BorderSizePixel = 0
                Item.Parent = SecContainer

                local ItemCorner = Instance.new("UICorner")
                ItemCorner.CornerRadius = UDim.new(0, 8)
                ItemCorner.Parent = Item

                local ItemStroke = Instance.new("UIStroke")
                ItemStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ItemStroke.Color = SaturnLib.Themes.Border
                ItemStroke.Transparency = 0.93
                ItemStroke.Thickness = 1
                ItemStroke.Parent = Item

                local Label = Instance.new("TextLabel")
                Label.Position = UDim2.new(0, 12, 0, 6)
                Label.Size = UDim2.new(1, -70, 0, 16)
                Label.BackgroundTransparency = 1
                applyFont(Label, "Medium")
                Label.Text = name
                Label.TextColor3 = SaturnLib.Themes.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Item

                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.AnchorPoint = Vector2.new(1, 0)
                ValueLabel.Position = UDim2.new(1, -12, 0, 6)
                ValueLabel.Size = UDim2.new(0, 60, 0, 16)
                ValueLabel.BackgroundTransparency = 1
                applyFont(ValueLabel, "Bold")
                ValueLabel.Text = string.format("%." .. tostring(decimals) .. "f%s", value, suffix)
                ValueLabel.TextColor3 = SaturnLib.Themes.AccentDim
                ValueLabel.TextSize = 12
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValueLabel.Parent = Item

                local Bar = Instance.new("TextButton")
                Bar.Name = "Bar"
                Bar.Position = UDim2.new(0, 12, 0, 27)
                Bar.Size = UDim2.new(1, -24, 0, 6)
                Bar.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
                Bar.BorderSizePixel = 0
                Bar.AutoButtonColor = false
                Bar.Text = ""
                Bar.Parent = Item

                local BarCorner = Instance.new("UICorner")
                BarCorner.CornerRadius = UDim.new(1, 0)
                BarCorner.Parent = Bar

                local Fill = Instance.new("Frame")
                Fill.Name = "Fill"
                Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                Fill.BackgroundColor3 = SaturnLib.Themes.Accent
                Fill.BorderSizePixel = 0
                Fill.Parent = Bar

                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(1, 0)
                FillCorner.Parent = Fill

                local function updateSlider(input)
                    local barWidth = Bar.AbsoluteSize.X
                    local mouseX = input.Position.X - Bar.AbsolutePosition.X
                    local pct = math.clamp(mouseX / barWidth, 0, 1)
                    local rawVal = min + (pct * (max - min))
                    local factor = 10 ^ decimals
                    local rounded = math.floor(rawVal * factor + 0.5) / factor
                    value = rounded
                    if flag then SaturnLib.Flags[flag] = value end

                    ValueLabel.Text = string.format("%." .. tostring(decimals) .. "f%s", value, suffix)
                    Fill.Size = UDim2.new(pct, 0, 1, 0)
                    pcall(callback, value)
                end

                local sliding = false
                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        updateSlider(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input)
                    end
                end)

                pcall(callback, value)

                styleRow(Item)

                return {
                    Set = function(v)
                        value = math.clamp(v, min, max)
                        local pct = (value - min) / (max - min)
                        ValueLabel.Text = string.format("%." .. tostring(decimals) .. "f%s", value, suffix)
                        Fill.Size = UDim2.new(pct, 0, 1, 0)
                        if flag then SaturnLib.Flags[flag] = value end
                        pcall(callback, value)
                    end,
                    Get = function() return value end
                }
            end

            -- Dropdown Control
            function SecObj:CreateDropdown(opts)
                opts = opts or {}
                local name = opts.Name or "Dropdown"
                local options = opts.Options or {}
                local default = opts.Default or options[1] or "None"
                local flag = opts.Flag or nil
                local callback = opts.Callback or function() end

                local selected = default
                if flag then SaturnLib.Flags[flag] = selected end
                local isOpen = false

                local Item = Instance.new("Frame")
                Item.Name = name .. "_Dropdown"
                Item.Size = UDim2.new(1, 0, 0, 40)
                Item.BackgroundColor3 = SaturnLib.Themes.Element
                Item.BackgroundTransparency = SaturnLib.Themes.ElementTransparency
                Item.BorderSizePixel = 0
                Item.ClipsDescendants = true
                Item.Parent = SecContainer

                local ItemCorner = Instance.new("UICorner")
                ItemCorner.CornerRadius = UDim.new(0, 8)
                ItemCorner.Parent = Item

                local ItemStroke = Instance.new("UIStroke")
                ItemStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ItemStroke.Color = SaturnLib.Themes.Border
                ItemStroke.Transparency = 0.93
                ItemStroke.Thickness = 1
                ItemStroke.Parent = Item

                local HeaderBtn = Instance.new("TextButton")
                HeaderBtn.Size = UDim2.new(1, 0, 0, 40)
                HeaderBtn.BackgroundTransparency = 1
                HeaderBtn.Text = ""
                HeaderBtn.Parent = Item

                local Label = Instance.new("TextLabel")
                Label.Position = UDim2.new(0, 12, 0, 0)
                Label.Size = UDim2.new(0.5, -12, 1, 0)
                Label.BackgroundTransparency = 1
                applyFont(Label, "Medium")
                Label.Text = name
                Label.TextColor3 = SaturnLib.Themes.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = HeaderBtn

                local SelLabel = Instance.new("TextLabel")
                SelLabel.AnchorPoint = Vector2.new(1, 0)
                SelLabel.Position = UDim2.new(1, -30, 0, 0)
                SelLabel.Size = UDim2.new(0.5, -20, 1, 0)
                SelLabel.BackgroundTransparency = 1
                applyFont(SelLabel, "Bold")
                SelLabel.Text = tostring(selected)
                SelLabel.TextColor3 = SaturnLib.Themes.TextDim
                SelLabel.TextSize = 12
                SelLabel.TextXAlignment = Enum.TextXAlignment.Right
                SelLabel.Parent = HeaderBtn

                local Arrow = Instance.new("TextLabel")
                Arrow.AnchorPoint = Vector2.new(1, 0.5)
                Arrow.Position = UDim2.new(1, -10, 0.5, 0)
                Arrow.Size = UDim2.new(0, 16, 0, 16)
                Arrow.BackgroundTransparency = 1
                Arrow.Font = getFont("Bold")
                Arrow.Text = "▾"
                Arrow.TextColor3 = SaturnLib.Themes.TextDim
                Arrow.TextSize = 12
                Arrow.Parent = HeaderBtn

                local OptHolder = Instance.new("Frame")
                OptHolder.Position = UDim2.new(0, 8, 0, 40)
                OptHolder.Size = UDim2.new(1, -16, 0, #options * 28)
                OptHolder.BackgroundTransparency = 1
                OptHolder.Parent = Item

                local OptLayout = Instance.new("UIListLayout")
                OptLayout.SortOrder = Enum.SortOrder.LayoutOrder
                OptLayout.Padding = UDim.new(0, 2)
                OptLayout.Parent = OptHolder

                local function rebuild()
                    for _, c in ipairs(OptHolder:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local oBtn = Instance.new("TextButton")
                        oBtn.Size = UDim2.new(1, 0, 0, 26)
                        oBtn.BackgroundColor3 = (opt == selected) and Color3.fromRGB(35, 35, 48) or Color3.fromRGB(20, 20, 28)
                        oBtn.BackgroundTransparency = (opt == selected) and 0.55 or 1
                        oBtn.BorderSizePixel = 0
                        applyFont(oBtn, "Medium")
                        oBtn.Text = "  " .. tostring(opt)
                        oBtn.TextColor3 = (opt == selected) and SaturnLib.Themes.Accent or SaturnLib.Themes.TextDim
                        oBtn.TextSize = 11
                        oBtn.TextXAlignment = Enum.TextXAlignment.Left
                        oBtn.Parent = OptHolder

                        local oCorner = Instance.new("UICorner")
                        oCorner.CornerRadius = UDim.new(0, 6)
                        oCorner.Parent = oBtn

                        oBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            SelLabel.Text = tostring(selected)
                            if flag then SaturnLib.Flags[flag] = selected end
                            rebuild()
                            pcall(callback, selected)
                        end)
                    end
                end

                rebuild()

                local function toggleOpen()
                    isOpen = not isOpen
                    local targetH = isOpen and (40 + (#options * 28) + 8) or 40
                    Arrow.Text = isOpen and "▴" or "▾"
                    TweenService:Create(Item, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, targetH)
                    }):Play()
                    task.wait(0.2)
                    updateSecSize()
                end

                HeaderBtn.MouseButton1Click:Connect(toggleOpen)
                pcall(callback, selected)

                styleRow(Item)

                return {
                    Set = function(newOpt)
                        selected = newOpt
                        SelLabel.Text = tostring(selected)
                        if flag then SaturnLib.Flags[flag] = selected end
                        rebuild()
                        pcall(callback, selected)
                    end,
                    Refresh = function(newOpts)
                        options = newOpts or {}
                        OptHolder.Size = UDim2.new(1, -16, 0, #options * 28)
                        rebuild()
                        if isOpen then
                            Item.Size = UDim2.new(1, 0, 0, 40 + (#options * 28) + 8)
                            updateSecSize()
                        end
                    end
                }
            end

            -- Keybind Control
            function SecObj:CreateKeybind(opts)
                opts = opts or {}
                local name = opts.Name or "Keybind"
                local default = opts.Default or Enum.KeyCode.E
                local flag = opts.Flag or nil
                local callback = opts.Callback or function() end

                local key = default
                if flag then SaturnLib.Flags[flag] = key end
                local listening = false

                local Item = Instance.new("Frame")
                Item.Name = name .. "_Keybind"
                Item.Size = UDim2.new(1, 0, 0, 40)
                Item.BackgroundColor3 = SaturnLib.Themes.Element
                Item.BackgroundTransparency = SaturnLib.Themes.ElementTransparency
                Item.BorderSizePixel = 0
                Item.Parent = SecContainer

                local ItemCorner = Instance.new("UICorner")
                ItemCorner.CornerRadius = UDim.new(0, 8)
                ItemCorner.Parent = Item

                local ItemStroke = Instance.new("UIStroke")
                ItemStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ItemStroke.Color = SaturnLib.Themes.Border
                ItemStroke.Transparency = 0.93
                ItemStroke.Thickness = 1
                ItemStroke.Parent = Item

                local Label = Instance.new("TextLabel")
                Label.Position = UDim2.new(0, 12, 0, 0)
                Label.Size = UDim2.new(1, -100, 1, 0)
                Label.BackgroundTransparency = 1
                applyFont(Label, "Medium")
                Label.Text = name
                Label.TextColor3 = SaturnLib.Themes.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Item

                local KeyBtn = Instance.new("TextButton")
                KeyBtn.AnchorPoint = Vector2.new(1, 0.5)
                KeyBtn.Position = UDim2.new(1, -10, 0.5, 0)
                KeyBtn.Size = UDim2.new(0, 80, 0, 22)
                KeyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
                KeyBtn.BorderSizePixel = 0
                applyFont(KeyBtn, "Bold")
                KeyBtn.Text = key.Name
                KeyBtn.TextColor3 = SaturnLib.Themes.Text
                KeyBtn.TextSize = 11
                KeyBtn.AutoButtonColor = false
                KeyBtn.Parent = Item

                local KeyCorner = Instance.new("UICorner")
                KeyCorner.CornerRadius = UDim.new(0, 6)
                KeyCorner.Parent = KeyBtn

                KeyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KeyBtn.Text = "..."
                    KeyBtn.TextColor3 = SaturnLib.Themes.Accent
                end)

                UserInputService.InputBegan:Connect(function(input, processed)
                    if listening and not processed then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            key = input.KeyCode
                            KeyBtn.Text = key.Name
                            KeyBtn.TextColor3 = SaturnLib.Themes.Text
                            listening = false
                            if flag then SaturnLib.Flags[flag] = key end
                            pcall(callback, key)
                        end
                    end
                end)

                styleRow(Item)

                return {
                    Set = function(k)
                        key = k
                        KeyBtn.Text = key.Name
                        if flag then SaturnLib.Flags[flag] = key end
                        pcall(callback, key)
                    end,
                    Get = function() return key end
                }
            end

            -- Button Control
            function SecObj:CreateButton(opts)
                opts = opts or {}
                local name = opts.Name or "Button"
                local callback = opts.Callback or function() end

                local Item = Instance.new("TextButton")
                Item.Name = name .. "_Button"
                Item.Size = UDim2.new(1, 0, 0, 40)
                Item.BackgroundColor3 = SaturnLib.Themes.ElementHover
                Item.BackgroundTransparency = 1
                Item.BorderSizePixel = 0
                Item.AutoButtonColor = false
                Item.Text = ""
                Item.Parent = SecContainer

                local ItemCorner = Instance.new("UICorner")
                ItemCorner.CornerRadius = UDim.new(0, 8)
                ItemCorner.Parent = Item

                local ItemStroke = Instance.new("UIStroke")
                ItemStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ItemStroke.Color = SaturnLib.Themes.Border
                ItemStroke.Transparency = 0.93
                ItemStroke.Thickness = 1
                ItemStroke.Parent = Item

                local Label = Instance.new("TextLabel")
                Label.Position = UDim2.new(0, 12, 0, 0)
                Label.Size = UDim2.new(1, -24, 1, 0)
                Label.BackgroundTransparency = 1
                applyFont(Label, "Medium")
                Label.Text = name
                Label.TextColor3 = SaturnLib.Themes.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Item

                Item.MouseEnter:Connect(function()
                    TweenService:Create(Item, TweenInfo.new(0.15), {
                        BackgroundTransparency = 0.30
                    }):Play()
                end)

                Item.MouseLeave:Connect(function()
                    TweenService:Create(Item, TweenInfo.new(0.15), {
                        BackgroundTransparency = 0.40
                    }):Play()
                end)

                Item.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)

                styleRow(Item)

                return Item
            end

            -- ColorPicker Control
            function SecObj:CreateColorPicker(opts)
                opts = opts or {}
                local name = opts.Name or "Color Picker"
                local default = opts.Default or Color3.fromRGB(255, 255, 255)
                local flag = opts.Flag or nil
                local callback = opts.Callback or function() end

                local currentColor = default
                if flag then SaturnLib.Flags[flag] = currentColor end

                local Item = Instance.new("Frame")
                Item.Name = name .. "_ColorPicker"
                Item.Size = UDim2.new(1, 0, 0, 40)
                Item.BackgroundColor3 = SaturnLib.Themes.Element
                Item.BackgroundTransparency = SaturnLib.Themes.ElementTransparency
                Item.BorderSizePixel = 0
                Item.Parent = SecContainer

                local ItemCorner = Instance.new("UICorner")
                ItemCorner.CornerRadius = UDim.new(0, 8)
                ItemCorner.Parent = Item

                local ItemStroke = Instance.new("UIStroke")
                ItemStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ItemStroke.Color = SaturnLib.Themes.Border
                ItemStroke.Transparency = 0.93
                ItemStroke.Thickness = 1
                ItemStroke.Parent = Item

                local Label = Instance.new("TextLabel")
                Label.Position = UDim2.new(0, 12, 0, 0)
                Label.Size = UDim2.new(1, -60, 1, 0)
                Label.BackgroundTransparency = 1
                applyFont(Label, "Medium")
                Label.Text = name
                Label.TextColor3 = SaturnLib.Themes.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Item

                local Preview = Instance.new("TextButton")
                Preview.AnchorPoint = Vector2.new(1, 0.5)
                Preview.Position = UDim2.new(1, -10, 0.5, 0)
                Preview.Size = UDim2.new(0, 24, 0, 20)
                Preview.BackgroundColor3 = currentColor
                Preview.BorderSizePixel = 0
                Preview.Text = ""
                Preview.Parent = Item

                local PrevCorner = Instance.new("UICorner")
                PrevCorner.CornerRadius = UDim.new(0, 6)
                PrevCorner.Parent = Preview

                local palette = {
                    Color3.fromRGB(255, 255, 255),
                    Color3.fromRGB(255, 80, 80),
                    Color3.fromRGB(80, 180, 255),
                    Color3.fromRGB(120, 230, 150),
                    Color3.fromRGB(255, 210, 80),
                    Color3.fromRGB(190, 120, 255),
                }
                local palIndex = 1

                Preview.MouseButton1Click:Connect(function()
                    palIndex = (palIndex % #palette) + 1
                    currentColor = palette[palIndex]
                    Preview.BackgroundColor3 = currentColor
                    if flag then SaturnLib.Flags[flag] = currentColor end
                    pcall(callback, currentColor)
                end)

                styleRow(Item)

                return {
                    Set = function(c)
                        currentColor = c
                        Preview.BackgroundColor3 = currentColor
                        if flag then SaturnLib.Flags[flag] = currentColor end
                        pcall(callback, currentColor)
                    end,
                    Get = function() return currentColor end
                }
            end

            -- Textbox Control
            function SecObj:CreateTextBox(opts)
                opts = opts or {}
                local name = opts.Name or "Input"
                local placeholder = opts.Placeholder or "Type here..."
                local default = opts.Default or ""
                local flag = opts.Flag or nil
                local callback = opts.Callback or function() end

                local text = default
                if flag then SaturnLib.Flags[flag] = text end

                local Item = Instance.new("Frame")
                Item.Name = name .. "_TextBox"
                Item.Size = UDim2.new(1, 0, 0, 40)
                Item.BackgroundColor3 = SaturnLib.Themes.Element
                Item.BackgroundTransparency = SaturnLib.Themes.ElementTransparency
                Item.BorderSizePixel = 0
                Item.Parent = SecContainer

                local ItemCorner = Instance.new("UICorner")
                ItemCorner.CornerRadius = UDim.new(0, 8)
                ItemCorner.Parent = Item

                local ItemStroke = Instance.new("UIStroke")
                ItemStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ItemStroke.Color = SaturnLib.Themes.Border
                ItemStroke.Transparency = 0.93
                ItemStroke.Thickness = 1
                ItemStroke.Parent = Item

                local Label = Instance.new("TextLabel")
                Label.Position = UDim2.new(0, 12, 0, 0)
                Label.Size = UDim2.new(0.4, -12, 1, 0)
                Label.BackgroundTransparency = 1
                applyFont(Label, "Medium")
                Label.Text = name
                Label.TextColor3 = SaturnLib.Themes.Text
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Item

                local Input = Instance.new("TextBox")
                Input.AnchorPoint = Vector2.new(1, 0.5)
                Input.Position = UDim2.new(1, -10, 0.5, 0)
                Input.Size = UDim2.new(0.6, 0, 0, 24)
                Input.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                Input.BorderSizePixel = 0
                applyFont(Input, "Medium")
                Input.Text = default
                Input.PlaceholderText = placeholder
                Input.PlaceholderColor3 = SaturnLib.Themes.TextDim
                Input.TextColor3 = SaturnLib.Themes.Text
                Input.TextSize = 11
                Input.ClearTextOnFocus = false
                Input.Parent = Item

                local InputCorner = Instance.new("UICorner")
                InputCorner.CornerRadius = UDim.new(0, 6)
                InputCorner.Parent = Input

                Input.FocusLost:Connect(function()
                    text = Input.Text
                    if flag then SaturnLib.Flags[flag] = text end
                    pcall(callback, text)
                end)

                styleRow(Item)

                return {
                    Set = function(t)
                        text = t
                        Input.Text = t
                        if flag then SaturnLib.Flags[flag] = text end
                        pcall(callback, text)
                    end,
                    Get = function() return text end
                }
            end

            return SecObj
        end

        return TabObj
    end

    return WindowObj
end

return SaturnLib
