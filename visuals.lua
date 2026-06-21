local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESPEnabled = false

local function ApplyESP(Player)
    if Player == LocalPlayer then return end
    local Char = Player.Character
    if not Char then return end
    local old = Char:FindFirstChild("RoleESP")
    if old then old:Destroy() end
    if not ESPEnabled then return end

    local Highlight = Instance.new("Highlight")
    Highlight.Name = "RoleESP"
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.FillTransparency = 0.5
    Highlight.OutlineTransparency = 0
    Highlight.Parent = Char

    local function RefreshColor()
        local Role = Player:GetAttribute("Role")
        if Role == "HIDER" then
            Highlight.FillColor = Color3.fromRGB(0, 255, 0)
            Highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
        elseif Role == "SEEKER" then
            Highlight.FillColor = Color3.fromRGB(255, 0, 0)
            Highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        else
            Highlight.FillColor = Color3.fromRGB(255, 255, 255)
            Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        end
    end
    RefreshColor()

    Player:GetAttributeChangedSignal("Role"):Connect(function()
        if Char:FindFirstChild("RoleESP") == Highlight then RefreshColor() end
    end)
end

local function RemoveESP(Player)
    if not Player.Character then return end
    local h = Player.Character:FindFirstChild("RoleESP")
    if h then h:Destroy() end
end

local function UpdateAllESP()
    for _, Player in ipairs(Players:GetPlayers()) do
        if ESPEnabled then ApplyESP(Player) else RemoveESP(Player) end
    end
end

local function SetupPlayer(Player)
    if Player.Character then ApplyESP(Player) end
    Player.CharacterAdded:Connect(function(Char)
        task.wait(0.5)
        if ESPEnabled then ApplyESP(Player) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do SetupPlayer(p) end
Players.PlayerAdded:Connect(SetupPlayer)

return {
    Init = function(ESPGroup)
        ESPGroup:AddToggle("ESPToggle", {
            Text = "Role ESP",
            Default = false,
            Callback = function(v)
                ESPEnabled = v
                UpdateAllESP()
            end
        })
    end
}