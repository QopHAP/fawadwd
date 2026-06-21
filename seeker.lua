local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local MAX_AMMO = 9999  -- ← Изменили с 2 на 9999
local InfAmmoConn = nil
local ReloadConnection = nil

local function StopReloadAnimation()
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end

    for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
        local animId = track.Animation and track.Animation.AnimationId or ""
        if animId:lower():find("reload") or animId:lower():find("reloading") or animId:lower():find("pump") then
            track:Stop(0)
            track:AdjustSpeed(0)
        end
    end
end

local function StartInfAmmo()
    if InfAmmoConn then InfAmmoConn:Disconnect() end
    if ReloadConnection then ReloadConnection:Disconnect() end

    -- Ставим очень большое количество патронов
    LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)

    InfAmmoConn = LocalPlayer:GetAttributeChangedSignal("SeekerAmmo"):Connect(function()
        local current = LocalPlayer:GetAttribute("SeekerAmmo")
        if current and current < MAX_AMMO then
            task.wait(0.02)
            LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
            StopReloadAnimation()
        end
    end)

    -- Постоянная защита
    ReloadConnection = RunService.Heartbeat:Connect(function()
        if LocalPlayer:GetAttribute("SeekerAmmo") < MAX_AMMO then
            LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
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
            Text = "Бесконечные патроны (9999)",
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
            Text = "Поставить 9999 патронов (разово)",
            Func = function()
                LocalPlayer:SetAttribute("SeekerAmmo", 9999)
                StopReloadAnimation()
            end
        })
    end
}
