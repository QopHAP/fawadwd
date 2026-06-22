-- ======================== visuals.lua ========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESPEnabled = false
local NameESPEnabled = false
local TracersEnabled = false

local tracerLines = {} -- Таблица для хранения линий-трейсеров
local renderConnection = nil -- Ссылка на подключение RenderStepped

-- ---------- Вспомогательная функция для очистки всех ESP элементов ----------
local function ClearAllESP()
    -- Удаляем Highlight
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hl = char:FindFirstChild("RoleHighlight")
                if hl then hl:Destroy() end
                local tag = char:FindFirstChild("RoleNameTag")
                if tag then tag:Destroy() end
            end
        end
    end

    -- Удаляем все трейсеры
    for _, line in pairs(tracerLines) do
        line:Remove()
    end
    tracerLines = {}
end

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

-- ---------- Tracers (Новая функция) ----------
local function UpdateTracers()
    if not TracersEnabled then return end

    local localChar = LocalPlayer.Character
    if not localChar then return end

    -- Используем позицию камеры как начало луча (ваши глаза)
    local origin = Camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head then
                    local targetPos = head.Position
                    -- Создаём или обновляем линию для этого игрока
                    local line = tracerLines[player]
                    if not line then
                        line = Drawing.new("Line")
                        line.Thickness = 1.5
                        line.Color = Color3.fromRGB(255, 255, 255) -- Белый цвет по умолчанию
                        line.Transparency = 0.7
                        tracerLines[player] = line
                    end

                    -- Обновляем координаты линии
                    local vector, onScreen = Camera:WorldToScreenPoint(origin)
                    if onScreen then
                        line.From = Vector2.new(vector.X, vector.Y)
                    else
                        -- Если камера не видит начало, просто ставим в центр экрана
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    end

                    local vector2, onScreen2 = Camera:WorldToScreenPoint(targetPos)
                    if onScreen2 then
                        line.To = Vector2.new(vector2.X, vector2.Y)
                    else
                        -- Если цель не видна, линия всё равно рисуется, но уходит за край экрана
                        line.To = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    end

                    -- Обновляем цвет в зависимости от роли
                    local role = player:GetAttribute("Role")
                    if role == "SEEKER" then
                        line.Color = Color3.fromRGB(255, 0, 0)   -- красный
                    elseif role == "HIDER" then
                        line.Color = Color3.fromRGB(0, 255, 0)   -- зелёный
                    else
                        line.Color = Color3.fromRGB(255, 255, 255) -- белый (лобби)
                    end

                    line.Visible = true
                end
            end
        end
    end

    -- Удаляем линии для игроков, которые вышли или у которых нет персонажа/головы
    for player, line in pairs(tracerLines) do
        if not player or not player.Character or not player.Character:FindFirstChild("Head") then
            line:Remove()
            tracerLines[player] = nil
        end
    end
end

local function ToggleTracers(state)
    TracersEnabled = state
    if state then
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(UpdateTracers)
        end
    else
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        -- Удаляем все линии
        for _, line in pairs(tracerLines) do
            line:Remove()
        end
        tracerLines = {}
    end
end

-- ---------- Обработка игроков ----------
local function SetupPlayer(player)
    -- При пересоздании персонажа применяем ESP заново
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPEnabled then ApplyHighlight(player) end
        if NameESPEnabled then ApplyNameTag(player) end
        -- Трейсеры обновляются автоматически в цикле
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
                if not v and not NameESPEnabled and not TracersEnabled then
                    ClearAllESP() -- Если всё выключено, очищаем всё
                end
            end
        })

        -- Переключатель Name ESP
        espGroup:AddToggle("NameESPToggle", {
            Text = "Name ESP",
            Default = false,
            Callback = function(v)
                NameESPEnabled = v
                UpdateAllNameTags()
                if not v and not ESPEnabled and not TracersEnabled then
                    ClearAllESP()
                end
            end
        })

        -- НОВЫЙ переключатель Tracers
        espGroup:AddToggle("TracersToggle", {
            Text = "Tracers (Линии к игрокам)",
            Default = false,
            Callback = function(v)
                ToggleTracers(v)
                if not v and not ESPEnabled and not NameESPEnabled then
                    ClearAllESP()
                end
            end
        })
    end
}
