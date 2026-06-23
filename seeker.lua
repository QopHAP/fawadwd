local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local stopReloadConn = nil
local animConnections = {}
local charAddedConn = nil
local viewmodel = nil

-- Улучшенное определение анимации перезарядки
local function isReloadAnimation(animTrack)
    if not animTrack or not animTrack.Animation then return false end
    local animId = animTrack.Animation.AnimationId or ""
    local name = (animTrack.Name or ""):lower()
    local lowerId = animId:lower()
    
    return name:find("reload") or name:find("pump") or name:find("recharge") or
           lowerId:find("reload") or lowerId:find("pump") or lowerId:find("recharge")
end

-- ========== СТОП АНИМАЦИИ (убрать перезарядку) ==========
local function stopReloadAnims()
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            for _, track in pairs(descendant:GetPlayingAnimationTracks()) do
                if isReloadAnimation(track) then
                    track:Stop(0)
                    track:AdjustSpeed(0)
                end
            end
        elseif descendant:IsA("Animator") then
            for _, track in pairs(descendant:GetPlayingAnimationTracks()) do
                if isReloadAnimation(track) then
                    track:Stop(0)
                    track:AdjustSpeed(0)
                end
            end
        end
    end
end

local function onAnimationPlayed(track)
    if isReloadAnimation(track) then
        track:Stop(0)
        track:AdjustSpeed(0)
    end
end

local function hookAnimators()
    local char = LocalPlayer.Character
    if not char then return end
    for _, conn in ipairs(animConnections) do conn:Disconnect() end
    table.clear(animConnections)

    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local conn = descendant.AnimationPlayed:Connect(onAnimationPlayed)
            table.insert(animConnections, conn)
        end
    end
end

-- ========== БЕСКОНЕЧНАЯ ПЕРЕЗАРЯДКА (мгновенно) ==========
local function instantReload()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            local name = v.Name:lower()
            if name:find("ammo") or name:find("clip") or name:find("magazine") or name:find("bullets") then
                v.Value = 9999
            end
        end
    end
end

local function speedUpReload(track)
    if isReloadAnimation(track) then
        track:AdjustSpeed(50) -- очень быстро
    end
end

local function onAnimationPlayedSpeed(track)
    if isReloadAnimation(track) then
        task.defer(function()
            track:AdjustSpeed(50)
        end)
    end
end

-- ========== Общие функции ==========
local function disableReloadFeatures()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Viewmodel
    for _, vm in ipairs({workspace:FindFirstChild("Viewmodel"), char:FindFirstChild("Viewmodel")}) do
        if vm then
            if vm:GetAttribute("ReloadEnabled") ~= nil then vm:SetAttribute("ReloadEnabled", false) end
            if vm:FindFirstChild("EnableReload") then vm.EnableReload.Value = false end
            if vm:FindFirstChild("Reload") then vm.Reload.Value = false end
        end
    end
end

local stopMode = true -- true = остановить анимацию, false = мгновенная
local isEnabled = false

local function startAntiReload(mode)
    stopMode = (mode == "stop")
    -- очистка старых
    if stopReloadConn then stopReloadConn:Disconnect() end
    if charAddedConn then charAddedConn:Disconnect() end

    if stopMode then
        hookAnimators()
        stopReloadAnims()
        disableReloadFeatures()
    else
        -- мгновенный режим
        hookAnimators()
    end

    charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        if stopMode then
            hookAnimators()
            stopReloadAnims()
            disableReloadFeatures()
        end
    end)

    stopReloadConn = RunService.Heartbeat:Connect(function()
        if stopMode then
            stopReloadAnims()
            disableReloadFeatures()
        else
            instantReload()
        end
    end)

    print("[AntiReload] Включён режим:", stopMode and "Полная остановка анимации" or "Мгновенная перезарядка + бесконечные патроны")
end

local function stopAntiReload()
    if stopReloadConn then stopReloadConn:Disconnect() end
    if charAddedConn then charAddedConn:Disconnect() end
    for _, conn in ipairs(animConnections) do conn:Disconnect() end
    table.clear(animConnections)
    print("[AntiReload] Отключено")
end

-- ========== Экспорт в меню ==========
return {
    Init = function(SeekGroup)
        SeekGroup:AddToggle("NoReloadToggle", {
            Text = "Убрать анимацию перезарядки",
            Default = false,
            Callback = function(v)
                if v then
                    isEnabled = true
                    startAntiReload("stop")
                else
                    if not SeekGroup:FindFirstChild("InstantReloadToggle") or not SeekGroup.InstantReloadToggle.CurrentValue then
                        stopAntiReload()
                    end
                    isEnabled = false
                end
            end
        })

        SeekGroup:AddToggle("InstantReloadToggle", {
            Text = "Бесконечная перезарядка + патроны",
            Default = false,
            Callback = function(v)
                if v then
                    isEnabled = true
                    startAntiReload("speed")
                else
                    if not SeekGroup:FindFirstChild("NoReloadToggle") or not SeekGroup.NoReloadToggle.CurrentValue then
                        stopAntiReload()
                    end
                    isEnabled = false
                end
            end
        })
    end
}
