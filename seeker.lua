local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local stopReloadConn = nil
local animConnections = {}
local charAddedConn = nil
local viewmodel = nil

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

-- ---------- Safe mod: телепорт на Y = 70 ----------
local function teleportToSafeHeight()
    local char = LocalPlayer.Character
    if not char then
        warn("[SafeMod] Персонаж не найден")
        return
    end

    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not root then
        warn("[SafeMod] Не найдена часть для телепортации")
        return
    end

    local currentPos = root.Position
    local newPos = Vector3.new(currentPos.X, 70, currentPos.Z)
    root.CFrame = CFrame.new(newPos)
    print("[SafeMod] Телепортирован на Y = 70")
end

-- ---------- Экспорт для меню ----------
return {
    Init = function(SeekGroup)
        -- Переключатель для блокировки перезарядки
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

        -- Новая кнопка Safe mod
        SeekGroup:AddButton({
            Text = "Safe mod (подняться на Y=70)",
            Callback = function()
                teleportToSafeHeight()
                -- Если у вас есть библиотека уведомлений, можно добавить:
                -- Library:Notify({ Title = "Safe Mod", Description = "Телепорт выполнен!", Duration = 2 })
            end
        })
    end
}
