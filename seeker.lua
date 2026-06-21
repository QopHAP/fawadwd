local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local MAX_AMMO = 9999
local InfAmmoConn = nil
local ReloadConnection = nil
local StopReloadConn = nil

-- Получаем текущее оружие (если доступно)
local function getWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        -- Ищем атрибуты или значения, отвечающие за патроны
        return tool
    end
    return nil
end

-- Остановка всех анимаций перезарядки (улучшенная)
local function StopReloadAnimation()
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end

    -- Останавливаем все анимации, содержащие "reload" или "pump"
    for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
        local animId = track.Animation and track.Animation.AnimationId or ""
        local lower = animId:lower()
        if lower:find("reload") or lower:find("reload") or lower:find("pump") then
            track:Stop(0)
            track:AdjustSpeed(0) -- замораживаем скорость на случай, если анимация не остановится
        end
    end

    -- Дополнительно: отключаем звуки перезарядки (если есть)
    for _, sound in pairs(Character:GetDescendants()) do
        if sound:IsA("Sound") and sound.Name and sound.Name:lower():find("reload") then
            sound:Stop()
        end
    end
end

-- Функция, восстанавливающая патроны
local function RefillAmmo()
    -- Восстанавливаем атрибут игрока
    local current = LocalPlayer:GetAttribute("SeekerAmmo")
    if current and current < MAX_AMMO then
        LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
    end

    -- Также пробуем восстановить патроны в самом оружии (если они хранятся там)
    local weapon = getWeapon()
    if weapon then
        -- Пример: если у оружия есть свойство "Ammo" или атрибут
        local ammo = weapon:GetAttribute("Ammo")
        if ammo and ammo < MAX_AMMO then
            weapon:SetAttribute("Ammo", MAX_AMMO)
        end
        -- Если патроны хранятся в числовом значении (например, weapon.Ammo.Value)
        if weapon:FindFirstChild("Ammo") and weapon.Ammo:IsA("NumberValue") then
            if weapon.Ammo.Value < MAX_AMMO then
                weapon.Ammo.Value = MAX_AMMO
            end
        end
    end

    -- Останавливаем анимацию перезарядки в любом случае
    StopReloadAnimation()
end

local function StartInfAmmo()
    if InfAmmoConn then InfAmmoConn:Disconnect() end
    if ReloadConnection then ReloadConnection:Disconnect() end
    if StopReloadConn then StopReloadConn:Disconnect() end

    -- Первоначальная установка
    RefillAmmo()

    -- Отслеживаем изменение атрибута патронов у игрока
    InfAmmoConn = LocalPlayer:GetAttributeChangedSignal("SeekerAmmo"):Connect(function()
        RefillAmmo()
    end)

    -- Постоянная защита в каждом кадре (надёжнее)
    ReloadConnection = RunService.Heartbeat:Connect(function()
        RefillAmmo()
    end)

    -- Отдельно останавливаем анимацию перезарядки даже если она запускается между кадрами
    StopReloadConn = RunService.Stepped:Connect(function()
        StopReloadAnimation()
    end)

    print("[InfAmmo] Активен (патроны: " .. MAX_AMMO .. ")")
end

local function StopInfAmmo()
    if InfAmmoConn then InfAmmoConn:Disconnect() InfAmmoConn = nil end
    if ReloadConnection then ReloadConnection:Disconnect() ReloadConnection = nil end
    if StopReloadConn then StopReloadConn:Disconnect() StopReloadConn = nil end
    print("[InfAmmo] Выключен")
end

return {
    Init = function(SeekGroup)
        SeekGroup:AddToggle("InfAmmoToggle", {
            Text = "Бесконечные патроны + без перезарядки",
            Default = false,
            Callback = function(v)
                if v then
                    StartInfAmmo()
                else
                    StopInfAmmo()
                end
            end
        })

        SeekGroup:AddButton({
            Text = "Восстановить патроны (9999) сейчас",
            Func = function()
                RefillAmmo()
            end
        })
    end
}
