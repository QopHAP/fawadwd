local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local InfAmmoConn = nil
local MAX_AMMO = 2
local ReloadConnection = nil

local function StopReloadAnimation()
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end

    -- Отключаем все анимации перезарядки
    for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
        if track.Animation and track.Animation.AnimationId:find("reload") or 
           track.Animation and track.Animation.AnimationId:find("Reload") then
            track:Stop()
            track:AdjustSpeed(0)
        end
    end
end

local function StartInfAmmo()
    if InfAmmoConn then InfAmmoConn:Disconnect() end
    
    -- Основная логика бесконечных патронов
    LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
    
    InfAmmoConn = LocalPlayer:GetAttributeChangedSignal("SeekerAmmo"):Connect(function()
        local current = LocalPlayer:GetAttribute("SeekerAmmo")
        if current and current < MAX_AMMO then
            task.wait(0.03) -- очень быстрое восстановление
            LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
            
            -- Убираем анимацию перезарядки
            StopReloadAnimation()
        end
    end)

    -- Дополнительная защита от анимации перезарядки
    if ReloadConnection then ReloadConnection:Disconnect() end
    ReloadConnection = RunService.Heartbeat:Connect(function()
        if LocalPlayer:GetAttribute("SeekerAmmo") == MAX_AMMO then
            StopReloadAnimation()
        end
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
