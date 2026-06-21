-- ======================== ROLE ESP - MAIN LOADER ========================
local repo = "https://raw.githubusercontent.com/QopHAP/fawadwd/main/"

-- Загружаем библиотеку с оригинального источника
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Role ESP",
    Footer = "Hider / Seeker",
    ToggleKeybind = Enum.KeyCode.RightShift,
    Center = true,
    AutoShow = true,
    Resizable = false,
})

-- Вкладки
local VisualsTab    = Window:AddTab("Visuals", "eye")
local AimbotTab     = Window:AddTab("Aimbot", "crosshair")
local SeekTab       = Window:AddTab("Seeker", "shield")
local MovementTab   = Window:AddTab("Movement", "move")
local TeleportTab   = Window:AddTab("Teleport", "location")
local SettingsTab   = Window:AddTab("Settings", "settings")

-- Группы
local ESPGroup      = VisualsTab:AddLeftGroupbox("ESP")
local AimbotGroup   = AimbotTab:AddLeftGroupbox("Aimbot")
local AimbotGroup2  = AimbotTab:AddRightGroupbox("Настройки")
local SeekGroup     = SeekTab:AddLeftGroupbox("Дробовик")
local MovementGroup = MovementTab:AddLeftGroupbox("Movement Features")
local TeleportGroup = TeleportTab:AddLeftGroupbox("Teleport Locations")
local ThemeGroup    = SettingsTab:AddRightGroupbox("Тема")

-- Функция загрузки модулей
local function LoadModule(name)
    return loadstring(game:HttpGet(repo .. name .. ".lua"))()
end

-- Загружаем модули
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
    Description = "Скрипт успешно загружен!\nRightShift — открыть меню",
    Duration = 6,
})
