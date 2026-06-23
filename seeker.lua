local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local stopReloadConn = nil
local animConnections = {}
local charAddedConn = nil
local viewmodel = nil

-- ---------- Вспомогательная функция определения анимации перезарядки ----------
local function isReloadAnimation(animTrack)
    if not animTrack or not animTrack.Animation then return false end
    local animId = animTrack.Animation.AnimationId or ""
    local name = animTrack.Name or ""
    local lower = (animId .. name):lower()
    return lower:find("reload") or lower:find("pump") or lower:find("recharging") or lower:find("reload")
end

-- ---------- Режим "Убрать анимацию" (полная остановка) ----------
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

-- ---------- Режим "Бесконечная перезарядка" (ускорение анимации) ----------
local function speedUpReloadAnimation(track)
    if isReloadAnimation(track) then
        track:AdjustSpeed(20)   -- ускоряем в 20 раз (мгновенно)
    end
end

local function speedUpAllReloadAnims()
    local char = LocalPlayer.Character
    if not char then return end
    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            for _, track in pairs(descendant:GetPlayingAnimationTracks()) do
                if isReloadAnimation(track) then
                    track:AdjustSpeed(20)
                end
            end
        elseif descendant:IsA("Animator") then
            for _, track in pairs(descendant:GetChildren()) do
                if track:IsA("AnimationTrack") and track.IsPlaying then
                    if isReloadAnimation(track) then
                        track:AdjustSpeed(20)
                    end
                end
            end
        end
    end
end

local function onAnimationPlayedSpeed(track)
    if isReloadAnimation(track) then
        track:AdjustSpeed(20)
    end
end

local function hookAllAnimatorsSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    for _, conn in ipairs(animConnections) do
        conn:Disconnect()
    end
    table.clear(animConnections)
    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local conn = descendant.AnimationPlayed:Connect(onAnimationPlayedSpeed)
            table.insert(animConnections, conn)
        end
    end
end

-- ---------- Переменные для управления режимами ----------
local stopMode = false   -- true = отключать анимацию, false = ускорять
local isEnabled = false

local function startBlocking(mode)
    stopMode = (mode == "stop")   -- "stop" или "speed"
    if stopReloadConn then stopReloadConn:Disconnect() end
    if charAddedConn then charAddedConn:Disconnect() end

    if stopMode then
        hookAllAnimators()
        stopAllReloadAnims()
        disableViewmodelReload()
    else
        hookAllAnimatorsSpeed()
        speedUpAllReloadAnims()
    end

    charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.1)
        if stopMode then
            hookAllAnimators()
            stopAllReloadAnims()
            disableViewmodelReload()
        else
            hookAllAnimatorsSpeed()
            speedUpAllReloadAnims()
        end
    end)

    stopReloadConn = RunService.Heartbeat:Connect(function()
        if stopMode then
            stopAllReloadAnims()
            if not viewmodel or not viewmodel.Parent then
                disableViewmodelReload()
            end
        else
            speedUpAllReloadAnims()
        end
    end)

    print("[AntiReload] Режим включен: " .. (stopMode and "остановка анимации" or "ускорение (бесконечная перезарядка)"))
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
    isEnabled = false
    print("[AntiReload] Все режимы отключены")
end

-- ---------- Экспорт для меню ----------
return {
    Init = function(SeekGroup)
        -- Переключатель "Убрать анимацию перезарядки" (старый)
        SeekGroup:AddToggle("NoReloadToggle", {
            Text = "Убрать анимацию перезарядки",
            Default = false,
            Callback = function(v)
                if v then
                    isEnabled = true
                    startBlocking("stop")
                else
                    if isEnabled then
                        -- Если другой режим включён, не выключаем полностью
                        -- Но для простоты отключаем всё, если оба выключены
                        if not SeekGroup:FindFirstChild("InstantReloadToggle") or not SeekGroup.InstantReloadToggle.CurrentValue then
                            stopBlocking()
                        end
                    end
                    isEnabled = false
                end
            end
        })

        -- Переключатель "Бесконечная перезарядка" (ускорение)
        SeekGroup:AddToggle("InstantReloadToggle", {
            Text = "Бесконечная перезарядка (мгновенно)",
            Default = false,
            Callback = function(v)
                if v then
                    isEnabled = true
                    startBlocking("speed")
                else
                    if isEnabled then
                        if not SeekGroup:FindFirstChild("NoReloadToggle") or not SeekGroup.NoReloadToggle.CurrentValue then
                            stopBlocking()
                        end
                    end
                    isEnabled = false
                end
            end
        })
    end
}
