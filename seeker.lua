local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local InfAmmoConn = nil
local MAX_AMMO = 2
local ReloadConnection = nil

-- Более агрессивное отключение анимации перезарядки
local function StopReloadAnimation()
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end

    for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
        local animId = track.Animation and track.Animation.AnimationId or ""
        if animId:lower():find("reload") or animId:lower():find("reloading") then
            track:Stop()
            track:AdjustSpeed(0)
            track:Destroy() -- агрессивнее
        end
    end
end

local function StartInfAmmo()
    if InfAmmoConn then InfAmmoConn:Disconnect() end
    if ReloadConnection then ReloadConnection:Disconnect() end

    -- Основное восстановление патронов
    LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
    
    InfAmmoConn = LocalPlayer:GetAttributeChangedSignal("SeekerAmmo"):Connect(function()
        local current = LocalPlayer:GetAttribute("SeekerAmmo")
        if current and current < MAX_AMMO then
            task.wait(0.02) -- очень быстро
            LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
            StopReloadAnimation()
        end
    end)

    -- Постоянный контроль каждые 0.1 секунды
    ReloadConnection = RunService.Heartbeat:Connect(function()
        if LocalPlayer:GetAttribute("SeekerAmmo") == MAX_AMMO then
            StopReloadAnimation()
        end
    end)

    -- Дополнительная защита
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        StopReloadAnimation()
    end)
end

local function StopInfAmmo()
    if InfAmmoConn then 
        InfAmmoConn:Disconnect() 
        InfAmmoConn = nil 
    end
    if ReloadConnection then 
        ReloadConnection:Disconnect() 
        ReloadConnection = nil 
    end
end

return {
    Init = function(SeekGroup)
        SeekGroup:AddToggle("InfAmmoToggle", {
            Text = "Бесконечные патроны + No Reload",
            Default = false,
            Callback = function(v)
                if v then 
                    StartInfAmmo() 
                else 
                    StopInfAmmo() 
                end
            end
        })
    end
}
