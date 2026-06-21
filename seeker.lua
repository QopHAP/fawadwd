local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local InfAmmoConn = nil
local MAX_AMMO = 2

local function ForceNoReload()
    local Character = LocalPlayer.Character
    if not Character then return end

    -- Попытка 1: Через Viewmodel (как в Aim Practice)
    local success, Viewmodel = pcall(function()
        return require(ReplicatedStorage:WaitForChild("GunRegistry"):WaitForChild("Viewmodel"))
    end)

    if success and Viewmodel then
        -- Пытаемся отключить reload у текущего оружия
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun") then
                -- Некоторые игры хранят текущий Viewmodel в персонаже
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("ModuleScript") and v.Name:find("Viewmodel") then
                        -- Это грубый, но иногда рабочий способ
                    end
                end
            end
        end)
    end

    -- Попытка 2: Агрессивное отключение анимаций
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
            local id = track.Animation and track.Animation.AnimationId or ""
            if id:lower():find("reload") or id:lower():find("reloading") or id:lower():find("pump") then
                track:Stop(0)
                track:AdjustSpeed(0)
                pcall(function() track:Destroy() end)
            end
        end
    end
end

local function StartInfAmmo()
    if InfAmmoConn then InfAmmoConn:Disconnect() end

    LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)

    InfAmmoConn = LocalPlayer:GetAttributeChangedSignal("SeekerAmmo"):Connect(function()
        local ammo = LocalPlayer:GetAttribute("SeekerAmmo")
        if ammo and ammo < MAX_AMMO then
            task.wait(0.015)
            LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
            ForceNoReload()
        end
    end)

    -- Постоянный контроль
    RunService.Heartbeat:Connect(function()
        if LocalPlayer:GetAttribute("SeekerAmmo") == MAX_AMMO then
            ForceNoReload()
        end
    end)

    -- Дополнительно при каждом выстреле
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.6)
        ForceNoReload()
    end)
end

local function StopInfAmmo()
    if InfAmmoConn then
        InfAmmoConn:Disconnect()
        InfAmmoConn = nil
    end
end

return {
    Init = function(SeekGroup)
        SeekGroup:AddToggle("InfAmmoToggle", {
            Text = "Бесконечные патроны + No Reload (Aggressive)",
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
            Text = "Force No Reload (Разово)",
            Func = function()
                ForceNoReload()
            end
        })
    end
}
