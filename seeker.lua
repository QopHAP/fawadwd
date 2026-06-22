local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local stopReloadConn = nil     -- для Heartbeat
local animConnections = {}     -- для всех AnimationPlayed
local charAddedConn = nil
local viewmodel = nil

-- ---------- Функция для монет ----------
local function giveInfiniteCoins()
    local player = LocalPlayer
    if not player then return end

    -- 1) Пытаемся найти RemoteFunction SetCurrency в ServerStorage
    local serverStorage = game:GetService("ServerStorage")
    local setCurrency = serverStorage:FindFirstChild("SetCurrency")

    if setCurrency and setCurrency:IsA("RemoteFunction") then
        -- Вызываем с огромным числом
        local success, result = pcall(function()
            return setCurrency:InvokeServer(player, "Coins", 999999999)
        end)
        if success then
            print("[Coins] Успешно выдано: " .. tostring(result))
            -- Можно показать уведомление, если есть библиотека уведомлений
        else
            warn("[Coins] Ошибка при вызове SetCurrency: " .. tostring(result))
            -- Пробуем запасной вариант
            player:SetAttribute("Coins", 999999999)
            print("[Coins] Установлен локальный атрибут Coins (может не сохраниться)")
        end
    else
        -- Если RemoteFunction нет, пробуем установить атрибут напрямую
        player:SetAttribute("Coins", 999999999)
        print("[Coins] SetCurrency не найден, установлен локальный атрибут Coins")
    end
end

-- ---------- Блокировка перезарядки (ваш код) ----------
local function isReloadAnimation(animTrack)
    if not animTrack or not animTrack.Animation then return false end
    local animId = animTrack.Animation.AnimationId or ""
    local name = animTrack.Name or ""
    local lower = (animId .. name):lower()
    return lower:find("reload") or lower:find("pump") or lower:find("recharging") or lower:find("reload")
end

local function stopAnimationOnObject(obj)
    if obj:IsA("Humanoid") then
        for _, track in pairs(obj:GetPlayingAnimationTracks()) do
            if isReloadAnimation(track) then
                track:Stop(0)
                track:AdjustSpeed(0)
            end
        end
    elseif obj:IsA("Animator") then
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

local function stopAllReloadAnims()
    local char = LocalPlayer.Character
    if not char then return end
    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("Humanoid") or descendant:IsA("Animator") then
            stopAnimationOnObject(descendant)
        end
    end
end

local function onAnimationPlayed(track)
    if isReloadAnimation(track) then
        track:Stop(0)
        track:AdjustSpeed(0)
    end
end

local function hookAllAnimators()
    local char = LocalPlayer.Character
    if not char then return end
    for _, conn in ipairs(animConnections) do
        conn:Disconnect()
    end
    table.clear(animConnections)
    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local conn = descendant.AnimationPlayed:Connect(onAnimationPlayed)
            table.insert(animConnections, conn)
        end
    end
end

local function disableViewmodelReload()
    local possibleViewmodels = {
        workspace:FindFirstChild("Viewmodel"),
        LocalPlayer:FindFirstChild("Viewmodel"),
        LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Viewmodel"),
        workspace:FindFirstChild("AimPracticeVM")
    }
    for _, vm in ipairs(possibleViewmodels) do
        if vm then
            if vm:IsA("Model") and vm:FindFirstChild("Humanoid") then
                if vm:GetAttribute("ReloadEnabled") ~= nil then
                    vm:SetAttribute("ReloadEnabled", false)
                end
                if vm.EnableReload ~= nil then
                    vm.EnableReload = false
                end
            end
            viewmodel = vm
            break
        end
    end
end

local function startBlocking()
    if stopReloadConn then stopReloadConn:Disconnect() end
    if charAddedConn then charAddedConn:Disconnect() end
    hookAllAnimators()
    stopAllReloadAnims()
    disableViewmodelReload()
    charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.1)
        hookAllAnimators()
        stopAllReloadAnims()
        disableViewmodelReload()
    end)
    stopReloadConn = RunService.Heartbeat:Connect(function()
        stopAllReloadAnims()
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

-- ---------- Экспорт для меню ----------
return {
    Init = function(SeekGroup)
        -- Существующий переключатель для блокировки перезарядки
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

        -- Новая кнопка для монет
        SeekGroup:AddButton({
            Text = "Выдать бесконечные монеты",
            Callback = function()
                giveInfiniteCoins()
                -- Можно также показать уведомление, если библиотека поддерживает
                -- Library:Notify({ Title = "Coins", Description = "Монеты выданы!", Duration = 3 })
            end
        })
    end
}
