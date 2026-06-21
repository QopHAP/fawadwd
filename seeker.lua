local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local InfAmmoConn = nil
local MAX_AMMO = 2

local function StartInfAmmo()
    if InfAmmoConn then InfAmmoConn:Disconnect() end
    LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
    InfAmmoConn = LocalPlayer:GetAttributeChangedSignal("SeekerAmmo"):Connect(function()
        local current = LocalPlayer:GetAttribute("SeekerAmmo")
        if current and current < MAX_AMMO then
            task.wait(0.05)
            LocalPlayer:SetAttribute("SeekerAmmo", MAX_AMMO)
        end
    end)
end

local function StopInfAmmo()
    if InfAmmoConn then InfAmmoConn:Disconnect() InfAmmoConn = nil end
end

return {
    Init = function(SeekGroup)
        SeekGroup:AddToggle("InfAmmoToggle", {
            Text = "Бесконечные патроны",
            Default = false,
            Callback = function(v)
                if v then StartInfAmmo() else StopInfAmmo() end
            end
        })
    end
}