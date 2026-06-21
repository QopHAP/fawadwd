-- ======================== MAIN LOADER ========================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Library:CreateWindow({
    Title = "Role ESP",
    Footer = "Hider / Seeker",
    ToggleKeybind = Enum.KeyCode.RightShift,
    Center = true,
    AutoShow = true,
    Resizable = false,
})

-- Вкладки
local VisualsTab   = Window:AddTab("Visuals", "eye")
local AimbotTab    = Window:AddTab("Aimbot", "crosshair")
local SeekTab      = Window:AddTab("Seeker", "shield")
local MovementTab  = Window:AddTab("Movement", "move")
local TeleportTab  = Window:AddTab("Teleport", "location")
local SettingsTab  = Window:AddTab("Settings", "settings")

-- Группы
local ESPGroup      = VisualsTab:AddLeftGroupbox("ESP")
local AimbotGroup   = AimbotTab:AddLeftGroupbox("Aimbot")
local AimbotGroup2  = AimbotTab:AddRightGroupbox("Настройки")
local SeekGroup     = SeekTab:AddLeftGroupbox("Дробовик")
local MovementGroup = MovementTab:AddLeftGroupbox("Movement Features")
local TeleportGroup = TeleportTab:AddLeftGroupbox("Teleport Locations")
local ThemeGroup    = SettingsTab:AddRightGroupbox("Тема")

-- Загрузка модулей
local Visuals   = loadstring(game:HttpGet("https://yourdomain.com/visuals.lua"))()   -- замени на свой хост или используй require
local Aimbot    = loadstring(game:HttpGet("https://yourdomain.com/aimbot.lua"))() 
local Seeker    = loadstring(game:HttpGet("https://yourdomain.com/seeker.lua"))() 
local Movement  = loadstring(game:HttpGet("https://yourdomain.com/movement.lua"))() 
local Teleport  = loadstring(game:HttpGet("https://yourdomain.com/teleport.lua"))() 
local Settings  = loadstring(game:HttpGet("https://yourdomain.com/settings.lua"))() 

Visuals.Init(ESPGroup)
Aimbot.Init(AimbotGroup, AimbotGroup2)
Seeker.Init(SeekGroup)
Movement.Init(MovementGroup)
Teleport.Init(TeleportGroup)
Settings.Init(ThemeGroup, SettingsTab)

Library:Notify({
    Title = "Role ESP",
    Description = "Меню успешно загружено!\nRightShift — открыть меню",
    Duration = 6,
})