-- ======================== ROLE ESP - MAIN LOADER ========================
local repo = "https://raw.githubusercontent.com/QopHAP/fawadwd/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()  -- Если у тебя нет Library.lua, оставь как было раньше
-- Загружаем библиотеку с оригинального источника
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

@@ -54,6 +55,6 @@ Settings.Init(ThemeGroup, SettingsTab)

Library:Notify({
    Title = "Role ESP",
    Description = "Скрипт загружен с GitHub!\nRightShift — открыть меню",
    Description = "Скрипт успешно загружен!\nRightShift — открыть меню",
    Duration = 6,
})
