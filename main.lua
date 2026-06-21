-- ======================== ROLE ESP - MAIN LOADER ========================
local repo = "https://raw.githubusercontent.com/ТВОЙ_НИК/RoleESP-Script/main/"  -- ← ИЗМЕНИ НА СВОЙ

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()  -- если библиотека тоже на гитхабе
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Role ESP",
    Footer = "Hider / Seeker",
    ToggleKeybind = Enum.KeyCode.RightShift,
    Center = true,
    AutoShow = true,
    Resizable = false,
})

-- Создаём вкладки и группы
local VisualsTab    = Window:AddTab("Visuals", "eye")
local AimbotTab     = Window:AddTab("Aimbot", "crosshair")
local SeekTab       = Window:AddTab("Seeker", "shield")
local MovementTab   = Window:AddTab("Movement", "move")
local TeleportTab   = Window:AddTab("Teleport", "location")
local SettingsTab   = Window:AddTab("Settings", "settings")

local ESPGroup      = VisualsTab:AddLeftGroupbox("ESP")
local AimbotGroup   = AimbotTab:AddLeftGroupbox("Aimbot")
local AimbotGroup2  = AimbotTab:AddRightGroupbox("Настройки")
local SeekGroup     = SeekTab:AddLeftGroupbox("Дробовик")
local MovementGroup = MovementTab:AddLeftGroupbox("Movement Features")
local TeleportGroup = TeleportTab:AddLeftGroupbox("Teleport Locations")
local ThemeGroup    = SettingsTab:AddRightGroupbox("Тема")

-- Загрузка модулей
local function LoadModule(name)
    return loadstring(game:HttpGet(repo .. name .. ".lua"))()
end

local Visuals   = LoadModule("visuals")
local Aimbot    = LoadModule("aimbot")
local Seeker    = LoadModule("seeker")
local Movement  = LoadModule("movement")
local Teleport  = LoadModule("teleport")
local Settings  = LoadModule("settings")

-- Инициализация
Visuals.Init(ESPGroup)
Aimbot.Init(AimbotGroup, AimbotGroup2)
Seeker.Init(SeekGroup)
Movement.Init(MovementGroup)
Teleport.Init(TeleportGroup)
Settings.Init(ThemeGroup, SettingsTab)

Library:Notify({
    Title = "Role ESP",
    Description = "Скрипт успешно загружен с GitHub",
    Duration = 6,
})