local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local stopReloadConn = nil     -- для Heartbeat
local animConnections = {}     -- для всех AnimationPlayed
local charAddedConn = nil
local viewmodel = nil

-- Функция, которая проверяет, является ли анимация "перезарядкой"
local function isReloadAnimation(animTrack)
    if not animTrack or not animTrack.Animation then return false end
    local animId = animTrack.Animation.AnimationId or ""
    local name = animTrack.Name or ""
    local lower = (animId .. name):lower()
    -- Список ключевых слов, характерных для перезарядки
    return lower:find("reload") or lower:find("pump") or lower:find("recharging") or lower:find("reload")
end

-- Останавливаем анимацию на любом объекте (Humanoid или Animator)
local function stopAnimationOnObject(obj)
    if obj:IsA("Humanoid") then
        for _, track in pairs(obj:GetPlayingAnimationTracks()) do
            if isReloadAnimation(track) then
                track:Stop(0)
                track:AdjustSpeed(0)  -- замораживаем на всякий
            end
        end
    elseif obj:IsA("Animator") then
        -- У Animator нет GetPlayingAnimationTracks, используем другой способ
        -- Попробуем перебрать все анимационные треки через :GetChildren()
        for _, track in pairs(obj:GetChildren()) do
            if track:IsA("AnimationTrack") and track.IsPlaying then
                if isReloadAnimation(track) then
                    track:Stop(0)
                    track:AdjustSpeed(0)
                end
            end
        end
    end
end

-- Остановка всех анимаций перезарядки во всём персонаже
local function stopAllReloadAnims()
    local char = LocalPlayer.Character
    if not char then return end

    -- Проверяем всех потомков на наличие Humanoid или Animator
    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("Humanoid") or descendant:IsA("Animator") then
            stopAnimationOnObject(descendant)
        end
    end
end

-- Перехват новых анимаций
local function onAnimationPlayed(track)
    if isReloadAnimation(track) then
        track:Stop(0)
        track:AdjustSpeed(0)
    end
end

-- Подключаемся ко всем Animator и Humanoid в персонаже
local function hookAllAnimators()
    local char = LocalPlayer.Character
    if not char then return end

    -- Отключаем старые подключения
    for _, conn in ipairs(animConnections) do
        conn:Disconnect()
    end
    table.clear(animConnections)

    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local conn = descendant.AnimationPlayed:Connect(onAnimationPlayed)
            table.insert(animConnections, conn)
        elseif descendant:IsA("Animator") then
            -- У Animator нет AnimationPlayed, но можно отслеживать загрузку анимаций через :GetAnimationTrack
            -- Однако проще положиться на Heartbeat
        end
    end
end

-- Попытка найти Viewmodel и отключить перезарядку на уровне модели
local function disableViewmodelReload()
    -- Ищем Viewmodel: возможно, он находится в ReplicatedStorage, или в Workspace, или как дочерний объект персонажа
    local possibleViewmodels = {
        workspace:FindFirstChild("Viewmodel"),
        LocalPlayer:FindFirstChild("Viewmodel"),
        LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Viewmodel"),
        workspace:FindFirstChild("AimPracticeVM")  -- из game.lua
    }
    for _, vm in ipairs(possibleViewmodels) do
        if vm then
            -- Если у Viewmodel есть свойство или метод для отключения перезарядки
            if vm:IsA("Model") and vm:FindFirstChild("Humanoid") then
                -- Может быть, у него есть атрибут "ReloadEnabled"
                if vm:GetAttribute("ReloadEnabled") ~= nil then
                    vm:SetAttribute("ReloadEnabled", false)
                end
                -- Или есть свойство "EnableReload"
                if vm.EnableReload ~= nil then
                    vm.EnableReload = false
                end
            end
            viewmodel = vm
            break
        end
    end
end

-- Основная функция включения
local function startBlocking()
    if stopReloadConn then stopReloadConn:Disconnect() end
    if charAddedConn then charAddedConn:Disconnect() end

    -- Первоначальная настройка
    hookAllAnimators()
    stopAllReloadAnims()
    disableViewmodelReload()

    -- Следим за появлением нового персонажа
    charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.1) -- даём время загрузиться
        hookAllAnimators()
        stopAllReloadAnims()
        disableViewmodelReload()
    end)

    -- Постоянная проверка (каждый кадр)
    stopReloadConn = RunService.Heartbeat:Connect(function()
        stopAllReloadAnims()
        -- Если Viewmodel не найден, пробуем снова
        if not viewmodel or not viewmodel.Parent then
            disableViewmodelReload()
        end
    end)

    print("[AntiReload] Анимация перезарядки полностью отключена")
end

local function stopBlocking()
    if stopReloadConn then stopReloadConn:Disconnect() end
    if charAddedConn then charAddedConn:Disconnect() end
    for _, conn in ipairs(animConnections) do
        conn:Disconnect()
    end
    table.clear(animConnections)
    stopReloadConn = nil
    charAddedConn = nil
    viewmodel = nil
    print("[AntiReload] Блокировка выключена")
end

-- Экспорт для вашего меню
return {
    Init = function(SeekGroup)
        SeekGroup:AddToggle("NoReloadToggle", {
            Text = "Убрать анимацию перезарядки",
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
