-- ======================== visuals.lua ========================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESPEnabled = false
local NameESPEnabled = false

-- ---------- Highlight ESP ----------
local function ApplyHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    -- Удаляем старый Highlight, если есть
    local old = char:FindFirstChild("RoleHighlight")
    if old then old:Destroy() end

    -- Создаём новый Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "RoleHighlight"
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0

    -- Функция обновления цвета по роли
    local function UpdateColor()
        local role = player:GetAttribute("Role")
        if role == "SEEKER" then
            highlight.FillColor = Color3.fromRGB(255, 0, 0)   -- красный
        elseif role == "HIDER" then
            highlight.FillColor = Color3.fromRGB(0, 255, 0)   -- зелёный
        else
            highlight.FillColor = Color3.fromRGB(255, 255, 255) -- белый (лобби)
        end
    end

    UpdateColor()
    highlight.Parent = char

    -- Следим за изменением роли
    local roleChangedConn
    roleChangedConn = player:GetAttributeChangedSignal("Role"):Connect(function()
        if ESPEnabled and char and char.Parent then
            UpdateColor()
        else
            -- Если ESP выключен или персонаж удалён, отключаем прослушку
            if roleChangedConn then roleChangedConn:Disconnect() end
        end
    end)

    -- Если персонаж удаляется, чистим подключение
    char.AncestryChanged:Connect(function()
        if not char.Parent then
            if roleChangedConn then roleChangedConn:Disconnect() end
        end
    end)
end

local function RemoveHighlight(player)
    local char = player.Character
    if char then
        local hl = char:FindFirstChild("RoleHighlight")
        if hl then hl:Destroy() end
    end
end

local function UpdateAllHighlights()
    for _, player in ipairs(Players:GetPlayers()) do
        if ESPEnabled then
            ApplyHighlight(player)
        else
            RemoveHighlight(player)
        end
    end
end

-- ---------- Name ESP ----------
local function ApplyNameTag(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    if not NameESPEnabled then return end

    -- Удаляем старый тег
    local oldTag = char:FindFirstChild("RoleNameTag")
    if oldTag then oldTag:Destroy() end

    local head = char:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RoleNameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.TextStrokeTransparency = 0.7
    label.Parent = billboard

    local function UpdateNameColor()
        local role = player:GetAttribute("Role")
        if role == "SEEKER" then
            label.TextColor3 = Color3.fromRGB(255, 0, 0)
        elseif role == "HIDER" then
            label.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    UpdateNameColor()

    -- Обновление цвета при смене роли
    player:GetAttributeChangedSignal("Role"):Connect(function()
        if char:FindFirstChild("RoleNameTag") then
            UpdateNameColor()
        end
    end)
end

local function RemoveNameTag(player)
    local char = player.Character
    if char then
        local tag = char:FindFirstChild("RoleNameTag")
        if tag then tag:Destroy() end
    end
end

local function UpdateAllNameTags()
    for _, player in ipairs(Players:GetPlayers()) do
        if NameESPEnabled then
            ApplyNameTag(player)
        else
            RemoveNameTag(player)
        end
    end
end

-- ---------- Обработка игроков ----------
local function SetupPlayer(player)
    -- При пересоздании персонажа применяем ESP заново
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPEnabled then ApplyHighlight(player) end
        if NameESPEnabled then ApplyNameTag(player) end
    end)

    -- Если персонаж уже есть, применяем сразу
    if player.Character then
        if ESPEnabled then ApplyHighlight(player) end
        if NameESPEnabled then ApplyNameTag(player) end
    end
end

-- Подключаем существующих и новых игроков
for _, p in ipairs(Players:GetPlayers()) do
    SetupPlayer(p)
end
Players.PlayerAdded:Connect(SetupPlayer)

-- ---------- Экспорт для главного скрипта ----------
return {
    Init = function(espGroup)
        -- Переключатель Highlight ESP
        espGroup:AddToggle("ESPToggle", {
            Text = "Role ESP (Highlight)",
            Default = false,
            Callback = function(v)
                ESPEnabled = v
                UpdateAllHighlights()
            end
        })

        -- Переключатель Name ESP
        espGroup:AddToggle("NameESPToggle", {
            Text = "Name ESP",
            Default = false,
            Callback = function(v)
                NameESPEnabled = v
                UpdateAllNameTags()
            end
        })
    end
}
