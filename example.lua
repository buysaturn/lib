--[[
    Saturn UI Library — Usage Example & Cheat Template
    Loadable via raw URL or local file
--]]

-- Local load (for development/testing on executor):
-- local SaturnLib = loadstring(readfile("liba/saturn_library.lua"))()

-- Web load (production):
-- local SaturnLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/buysaturn/saturn.github.io/main/liba/saturn_library.lua"))()

local SaturnLib = loadstring(readfile and readfile("liba/saturn_library.lua") or game:HttpGet("https://raw.githubusercontent.com/buysaturn/saturn.github.io/main/liba/saturn_library.lua"))()

-- 1. Create Main Window
local Window = SaturnLib:CreateWindow({
    Title = "Saturn",
    SubTitle = "Roblox Edition v1.0",
    SizeX = 640,
    SizeY = 430,
    ToggleKey = Enum.KeyCode.Insert, -- Key to show/hide menu
    BadgeText = "Active • 24h Free Key"
})

-- 2. Create Tabs (matching layout sketch)
local MainTab = Window:CreateTab({ Name = "Main" })
local VisualsTab = Window:CreateTab({ Name = "Visuals" })
local FreeTab = Window:CreateTab({ Name = "Free" })
local ConfigTab = Window:CreateTab({ Name = "Config" })

-- ====================================================================
-- TAB 1: MAIN (Aimbot & Combat)
-- ====================================================================
local AimSection = MainTab:CreateSection("Aimbot Settings")

AimSection:CreateToggle({
    Name = "Enable Aimbot",
    Default = false,
    Flag = "Aimbot_Enabled",
    Callback = function(state)
        print("[Saturn] Aimbot state:", state)
    end
})

AimSection:CreateKeybind({
    Name = "Aim Key",
    Default = Enum.KeyCode.E,
    Flag = "Aimbot_Key",
    Callback = function(key)
        print("[Saturn] Aim Key set to:", key.Name)
    end
})

AimSection:CreateDropdown({
    Name = "Target Hitbox",
    Options = { "Head", "UpperTorso", "HumanoidRootPart" },
    Default = "Head",
    Flag = "Aimbot_Hitbox",
    Callback = function(selected)
        print("[Saturn] Target hitbox:", selected)
    end
})

AimSection:CreateSlider({
    Name = "Smoothness",
    Min = 1,
    Max = 20,
    Default = 6,
    Decimals = 1,
    Suffix = "x",
    Flag = "Aimbot_Smooth",
    Callback = function(val)
        -- adjust smooth factor
    end
})

AimSection:CreateSlider({
    Name = "FOV Radius",
    Min = 20,
    Max = 360,
    Default = 90,
    Suffix = "px",
    Flag = "Aimbot_FOV",
    Callback = function(val)
        -- adjust FOV circle
    end
})

local TriggerSection = MainTab:CreateSection("Triggerbot")
TriggerSection:CreateToggle({
    Name = "Auto Fire on Crosshair",
    Default = false,
    Flag = "Trigger_Enabled",
    Callback = function(state)
        print("[Saturn] Triggerbot:", state)
    end
})

-- ====================================================================
-- TAB 2: VISUALS (ESP & Chams)
-- ====================================================================
local EspSection = VisualsTab:CreateSection("Player ESP")

EspSection:CreateToggle({
    Name = "Box ESP",
    Default = true,
    Flag = "ESP_Box",
    Callback = function(state)
        print("[Saturn] Box ESP:", state)
    end
})

EspSection:CreateToggle({
    Name = "Name & Distance",
    Default = true,
    Flag = "ESP_Names",
    Callback = function(state)
        print("[Saturn] Name ESP:", state)
    end
})

EspSection:CreateColorPicker({
    Name = "ESP Box Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "ESP_Color",
    Callback = function(color)
        print("[Saturn] ESP Color changed:", color)
    end
})

EspSection:CreateSlider({
    Name = "Max Render Distance",
    Min = 100,
    Max = 2500,
    Default = 1000,
    Suffix = "m",
    Flag = "ESP_Distance",
    Callback = function(val)
        -- set ESP distance
    end
})

-- ====================================================================
-- TAB 3: FREE (Player Modifications)
-- ====================================================================
local PlayerSection = FreeTab:CreateSection("Movement Modifications")

PlayerSection:CreateSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 120,
    Default = 16,
    Suffix = " spd",
    Flag = "Player_Speed",
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
})

PlayerSection:CreateSlider({
    Name = "JumpPower",
    Min = 50,
    Max = 250,
    Default = 50,
    Suffix = " pwr",
    Flag = "Player_Jump",
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = val end
    end
})

PlayerSection:CreateToggle({
    Name = "Infinite Jump",
    Default = false,
    Flag = "Player_InfJump",
    Callback = function(state)
        print("[Saturn] Infinite Jump:", state)
    end
})

PlayerSection:CreateButton({
    Name = "Reset Character",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
})

-- ====================================================================
-- TAB 4: CONFIG (Management)
-- ====================================================================
local SettingsSection = ConfigTab:CreateSection("Interface & Script")

SettingsSection:CreateButton({
    Name = "Unload Saturn Menu",
    Callback = function()
        if game.CoreGui:FindFirstChild("SaturnLibGui") then
            game.CoreGui.SaturnLibGui:Destroy()
        end
        SaturnLib:Notify({
            Title = "Saturn",
            Content = "Interface unloaded cleanly.",
            Duration = 2
        })
    end
})

-- Welcome Notification
SaturnLib:Notify({
    Title = "Saturn",
    Content = "Menu initialized. Press [INSERT] to toggle.",
    Duration = 3.5
})
