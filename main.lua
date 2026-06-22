-- ======================== ROLE ESP - MAIN LOADER ========================
local repo = "https://raw.githubusercontent.com/QopHAP/fawadwd/main/"

-- Загружаем библиотеку
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

-- ==================== ВКЛАДКИ ====================
local VisualsTab   = Window:AddTab("Visuals", "eye")
local AimbotTab    = Window:AddTab("Aimbot", "crosshair")
local SeekTab      = Window:AddTab("Seeker/Hider", "shield")   -- переименовано
local MovementTab  = Window:AddTab("Movement", "move")
local TeleportTab  = Window:AddTab("Teleport", "location")
local SettingsTab  = Window:AddTab("Settings", "settings")

-- ==================== ГРУППЫ ====================
local ESPGroup      = VisualsTab:AddLeftGroupbox("ESP")
local AimbotGroup   = AimbotTab:AddLeftGroupbox("Aimbot")
local AimbotGroup2  = AimbotTab:AddRightGroupbox("Настройки")
local SeekGroup     = SeekTab:AddLeftGroupbox("Дробовик")
local MovementGroup = MovementTab:AddLeftGroupbox("Movement Features")
local TeleportGroup = TeleportTab:AddLeftGroupbox("Teleport Locations")
local ThemeGroup    = SettingsTab:AddRightGroupbox("Тема")

-- ==================== SAFE MOD (добавлено в TeleportGroup) ====================
local startY = nil   -- запоминаем начальную Y

local function teleportToSafeHeight()
    local char = game.Players.LocalPlayer.Character
    if not char then
        warn("[SafeMod] Персонаж не найден")
        return
    end

    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not root then
        warn("[SafeMod] Не найдена часть для телепортации")
        return
    end

    -- Если начальная Y ещё не запомнена, запоминаем текущую
    if startY == nil then
        startY = root.Position.Y
        print("[SafeMod] Запомнена начальная Y =", startY)
    end

    -- Новая позиция: X и Z остаются текущими, Y = startY + 70
    local newPos = Vector3.new(root.Position.X, startY + 70, root.Position.Z)
    root.CFrame = CFrame.new(newPos)
    print("[SafeMod] Телепортирован на Y =", startY + 70)
end

-- Добавляем кнопку Safe mod в группу Teleport
TeleportGroup:AddButton({
    Text = "Safe mod (подняться на +70)",
    Callback = teleportToSafeHeight
})

-- ==================== ЗАГРУЗКА МОДУЛЕЙ ====================
local function LoadModule(name)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(repo .. name .. ".lua"))()
    end)
    if not success then
        warn("[Role ESP] Не удалось загрузить модуль: " .. name .. " | Ошибка: " .. tostring(result))
        return {}
    end
    return result or {}
end

local Visuals   = LoadModule("visuals")
local Aimbot    = LoadModule("aimbot")
local Seeker    = LoadModule("seeker")
local Movement  = LoadModule("movement")
local Teleport  = LoadModule("teleport")
local Settings  = LoadModule("settings")

-- Инициализация модулей
Visuals.Init(ESPGroup)
Aimbot.Init(AimbotGroup, AimbotGroup2)
Seeker.Init(SeekGroup)   -- в этом модуле теперь только переключатель анимации
Movement.Init(MovementGroup)
Teleport.Init(TeleportGroup)
Settings.Init(ThemeGroup, SettingsTab)

-- Уведомление
Library:Notify({
    Title = "Role ESP",
    Description = "Скрипт успешно загружен!\nRightShift — открыть меню",
    Duration = 6,
})
