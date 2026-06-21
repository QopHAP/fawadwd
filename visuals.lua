local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESPEnabled = false
local NameESPEnabled = false

-- ==================== HIGHLIGHT ESP ====================
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

-- ==================== NAME ESP ====================
local function ApplyNameESP(Player)
    if Player == LocalPlayer then return end
    local Char = Player.Character
    if not Char then return end

    -- Удаляем старый NameTag
    local oldTag = Char:FindFirstChild("RoleNameTag")
    if oldTag then oldTag:Destroy() end

    if not NameESPEnabled then return end

    local Head = Char:FindFirstChild("Head")
    if not Head then return end

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "RoleNameTag"
    Billboard.Adornee = Head
    Billboard.Size = UDim2.new(0, 200, 0, 50)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Char

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = Player.Name
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.TextSize = 18
    TextLabel.TextStrokeTransparency = 0.7
    TextLabel.Parent = Billboard

    local function RefreshNameColor()
        local Role = Player:GetAttribute("Role")
        if Role == "HIDER" then
            TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif Role == "SEEKER" then
            TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        else
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    RefreshNameColor()

    Player:GetAttributeChangedSignal("Role"):Connect(function()
        if Char:FindFirstChild("RoleNameTag") then
            RefreshNameColor()
        end
    end)
end

local function RemoveNameESP(Player)
    if not Player.Character then return end
    local tag = Player.Character:FindFirstChild("RoleNameTag")
    if tag then tag:Destroy() end
end

local function UpdateAllNameESP()
    for _, Player in ipairs(Players:GetPlayers()) do
        if NameESPEnabled then
            ApplyNameESP(Player)
        else
            RemoveNameESP(Player)
        end
    end
end

-- ==================== SETUP ====================
local function SetupPlayer(Player)
    if Player.Character then
        ApplyESP(Player)
        ApplyNameESP(Player)
    end

    Player.CharacterAdded:Connect(function(Char)
        task.wait(0.5)
        if ESPEnabled then ApplyESP(Player) end
        if NameESPEnabled then ApplyNameESP(Player) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do SetupPlayer(p) end
Players.PlayerAdded:Connect(SetupPlayer)

-- ==================== INIT ====================
return {
    Init = function(ESPGroup)
        -- Role Highlight ESP
        ESPGroup:AddToggle("ESPToggle", {
            Text = "Role ESP (Highlight)",
            Default = false,
            Callback = function(v)
                ESPEnabled = v
                UpdateAllESP()
            end
        })

        -- Name ESP
        ESPGroup:AddToggle("NameESPToggle", {
            Text = "Name ESP",
            Default = false,
            Callback = function(v)
                NameESPEnabled = v
                UpdateAllNameESP()
            end
        })
    end
}
