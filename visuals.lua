-- ======================== visuals.lua ========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Состояния
local ESPEnabled = false      -- Highlight (3D)
local NameESPEnabled = false
local TracersEnabled = false
local BoxEnabled = false
local MaxDistance = 1000

-- Таблицы для объектов рисования (по игроку)
local Drawings = {}           -- player -> { box, name, tracer }
local renderConnection = nil

-- ---------- Вспомогательная функция получения цвета по роли ----------
local function GetRoleColor(player)
    local role = player:GetAttribute("Role")
    if role == "SEEKER" then
        return Color3.fromRGB(255, 0, 0)   -- красный
    elseif role == "HIDER" then
        return Color3.fromRGB(0, 255, 0)   -- зелёный
    else
        return Color3.fromRGB(255, 255, 255) -- белый (лобби)
    end
end

-- ---------- Создание / обновление ESP для одного игрока (2D) ----------
local function UpdatePlayerESP(player)
    -- Инициализируем записи, если их нет
    if not Drawings[player] then
        Drawings[player] = {
            box = Drawing.new("Square"),
            name = Drawing.new("Text"),
            tracer = Drawing.new("Line"),
        }
        local d = Drawings[player]
        -- Настройки бокса
        d.box.Thickness = 2
        d.box.Filled = false
        d.box.Transparency = 1
        -- Настройки имени
        d.name.Size = 15
        d.name.Center = true
        d.name.Outline = true
        d.name.Color = Color3.fromRGB(255, 255, 255)
        -- Настройки трейсера
        d.tracer.Thickness = 1.5
        d.tracer.Transparency = 0.7
    end

    local d = Drawings[player]
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local head = char and char:FindFirstChild("Head")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    -- Проверка валидности
    if not char or not root or not head or not hum or hum.Health <= 0 then
        d.box.Visible = false
        d.name.Visible = false
        d.tracer.Visible = false
        return
    end

    -- Расстояние до игрока
    local distance = (Camera.CFrame.Position - root.Position).Magnitude
    if distance > MaxDistance then
        d.box.Visible = false
        d.name.Visible = false
        d.tracer.Visible = false
        return
    end

    -- Вычисляем позиции на экране
    local topPos, onScreenTop = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 3, 0))
    local bottomPos, onScreenBottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

    if not onScreenTop or not onScreenBottom then
        d.box.Visible = false
        d.name.Visible = false
        d.tracer.Visible = false
        return
    end

    -- Размеры бокса
    local height = math.abs(topPos.Y - bottomPos.Y)
    local width = height / 2.1   -- как в том скрипте

    -- Цвет для всех элементов
    local color = GetRoleColor(player)

    -- ---- Box ----
    if BoxEnabled then
        d.box.Size = Vector2.new(width, height)
        d.box.Position = Vector2.new(topPos.X - width/2, topPos.Y)
        d.box.Color = color
        d.box.Visible = true
    else
        d.box.Visible = false
    end

    -- ---- Name (с дистанцией) ----
    if NameESPEnabled then
        d.name.Text = string.format("%s [%dm]", player.Name, math.floor(distance))
        d.name.Position = Vector2.new(topPos.X, topPos.Y - 22)
        d.name.Visible = true
    else
        d.name.Visible = false
    end

    -- ---- Tracer (от нижней части экрана к центру тела) ----
    if TracersEnabled then
        local centerPos, onScreenCenter = Camera:WorldToViewportPoint(root.Position)
        if onScreenCenter then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To = Vector2.new(centerPos.X, centerPos.Y)
            d.tracer.Color = color
            d.tracer.Visible = true
        else
            d.tracer.Visible = false
        end
    else
        d.tracer.Visible = false
    end
end

-- ---------- Обновление всех игроков ----------
local function UpdateAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            UpdatePlayerESP(player)
        end
    end

    -- Чистим записи для игроков, которые вышли или не имеют персонажа
    for player, d in pairs(Drawings) do
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            d.box:Remove()
            d.name:Remove()
            d.tracer:Remove()
            Drawings[player] = nil
        end
    end
end

-- ---------- Функция включения/выключения рендера ----------
local function UpdateRenderConnection()
    if BoxEnabled or TracersEnabled or NameESPEnabled then
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(UpdateAllPlayers)
        end
    else
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        -- Удаляем все объекты рисования
        for _, d in pairs(Drawings) do
            d.box:Remove()
            d.name:Remove()
            d.tracer:Remove()
        end
        Drawings = {}
    end
end

-- ---------- Highlight ESP (3D) – оставлен как есть ----------
local function ApplyHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    local old = char:FindFirstChild("RoleHighlight")
    if old then old:Destroy() end

    local highlight = Instance.new("Highlight")
    highlight.Name = "RoleHighlight"
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0

    local function UpdateColor()
        highlight.FillColor = GetRoleColor(player)
    end

    UpdateColor()
    highlight.Parent = char

    local roleChangedConn
    roleChangedConn = player:GetAttributeChangedSignal("Role"):Connect(function()
        if ESPEnabled and char and char.Parent then
            UpdateColor()
        else
            if roleChangedConn then roleChangedConn:Disconnect() end
        end
    end)

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

-- ---------- Обработка новых игроков и пересоздания персонажа ----------
local function SetupPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPEnabled then ApplyHighlight(player) end
        -- 2D ESP обновляется автоматически в цикле
    end)

    if player.Character then
        if ESPEnabled then ApplyHighlight(player) end
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    SetupPlayer(p)
end
Players.PlayerAdded:Connect(SetupPlayer)

-- ---------- Экспорт для главного скрипта ----------
return {
    Init = function(espGroup)
        -- Переключатель Highlight (3D)
        espGroup:AddToggle("ESPToggle", {
            Text = "Role ESP (Highlight)",
            Default = false,
            Callback = function(v)
                ESPEnabled = v
                UpdateAllHighlights()
            end
        })

        -- Переключатель Name ESP (2D с дистанцией)
        espGroup:AddToggle("NameESPToggle", {
            Text = "Name ESP (с дистанцией)",
            Default = false,
            Callback = function(v)
                NameESPEnabled = v
                UpdateRenderConnection()
            end
        })

        -- Переключатель Tracers (линии к телу)
        espGroup:AddToggle("TracersToggle", {
            Text = "Tracers (линии к телу)",
            Default = false,
            Callback = function(v)
                TracersEnabled = v
                UpdateRenderConnection()
            end
        })

        -- Переключатель Box (прямоугольник)
        espGroup:AddToggle("BoxToggle", {
            Text = "Box (прямоугольник вокруг тела)",
            Default = false,
            Callback = function(v)
                BoxEnabled = v
                UpdateRenderConnection()
            end
        })

        -- Настройка максимальной дистанции
        espGroup:AddSlider("MaxDistanceSlider", {
            Text = "Max Distance",
            Default = 1000,
            Min = 100,
            Max = 2000,
            Increment = 50,
            Callback = function(v)
                MaxDistance = v
            end
        })
    end
}
