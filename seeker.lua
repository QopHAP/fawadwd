local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local reloadBlockConn = nil      -- для подключения к AnimationPlayed
local charAddedConn = nil        -- для смены персонажа

-- Останавливает уже играющие анимации перезарядки
local function stopReloadAnimations(humanoid)
    if not humanoid then return end
    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        local animId = track.Animation and track.Animation.AnimationId or ""
        if animId:lower():find("reload") or animId:lower():find("pump") then
            track:Stop(0)
        end
    end
end

-- Обработчик запуска новой анимации
local function onAnimationPlayed(animationTrack)
    local animId = animationTrack.Animation and animationTrack.Animation.AnimationId or ""
    if animId:lower():find("reload") or animId:lower():find("pump") then
        animationTrack:Stop(0)   -- сразу обрываем
    end
end

-- Настраивает блокировку для текущего Humanoid
local function setupBlocker()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if reloadBlockConn then reloadBlockConn:Disconnect() end
    reloadBlockConn = humanoid.AnimationPlayed:Connect(onAnimationPlayed)

    -- Если анимация уже играет – остановить
    stopReloadAnimations(humanoid)
end

-- Включаем блокировку
local function startBlocking()
    if charAddedConn then charAddedConn:Disconnect() end
    charAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            if reloadBlockConn then reloadBlockConn:Disconnect() end
            reloadBlockConn = hum.AnimationPlayed:Connect(onAnimationPlayed)
            stopReloadAnimations(hum)
        end
    end)
    setupBlocker()
    print("[NoReload] Анимации перезарядки отключены")
end

-- Выключаем блокировку
local function stopBlocking()
    if reloadBlockConn then reloadBlockConn:Disconnect() end
    if charAddedConn then charAddedConn:Disconnect() end
    reloadBlockConn = nil
    charAddedConn = nil
    print("[NoReload] Блокировка снята")
end

-- Экспорт для меню (аналогично вашей структуре)
return {
    Init = function(SeekGroup)
        SeekGroup:AddToggle("NoReloadToggle", {
            Text = "Отключить анимацию перезарядки",
            Default = false,
            Callback = function(v)
                if v then
                    startBlocking()
                else
                    stopBlocking()
                end
            end
        })
    end
}
