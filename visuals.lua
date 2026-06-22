-- ======================== visuals.lua ========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESPEnabled = false
local NameESPEnabled = false
local TracersEnabled = false
local BoxEnabled = false

local tracerLines = {}      -- таблица: игрок -> линия
local boxLines = {}         -- таблица: игрок -> { line1, line2, line3, line4 }
local renderConnection = nil

-- ---------- Вспомогательная функция очистки ----------
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

    -- Удаляем трейсеры
    for _, line in pairs(tracerLines) do
        line:Remove()
    end
    tracerLines = {}

    -- Удаляем боксы
    for _, lines in pairs(boxLines) do
        for _, line in ipairs(lines) do
            line:Remove()
        end
    end
    boxLines = {}
end

-- ---------- Highlight ESP ----------
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
        local role = player:GetAttribute("Role")
        if role == "SEEKER" then
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
        elseif role == "HIDER" then
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
        else
            highlight.FillColor = Color3.fromRGB(255, 255, 255)
        end
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

-- ---------- Name ESP ----------
local function ApplyNameTag(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    if not NameESPEnabled then return end

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

-- ---------- Tracers (к телу) ----------
local function UpdateTracers()
    if not TracersEnabled then return end
    local localChar = LocalPlayer.Character
    if not localChar then return end

    local origin = Camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                if root then
                    local targetPos = root.Position
                    local line = tracerLines[player]
                    if not line then
                        line = Drawing.new("Line")
                        line.Thickness = 1.5
                        line.Transparency = 0.7
                        tracerLines[player] = line
                    end

                    local startVec, onScreen = Camera:WorldToScreenPoint(origin)
                    if onScreen then
                        line.From = Vector2.new(startVec.X, startVec.Y)
                    else
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    end

                    local endVec, onScreen2 = Camera:WorldToScreenPoint(targetPos)
                    if onScreen2 then
                        line.To = Vector2.new(endVec.X, endVec.Y)
                    else
                        line.To = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    end

                    local role = player:GetAttribute("Role")
                    if role == "SEEKER" then
                        line.Color = Color3.fromRGB(255, 0, 0)
                    elseif role == "HIDER" then
                        line.Color = Color3.fromRGB(0, 255, 0)
                    else
                        line.Color = Color3.fromRGB(255, 255, 255)
                    end
                    line.Visible = true
                end
            end
        end
    end

    -- Чистим линии для игроков без тела
    for player, line in pairs(tracerLines) do
        if not player or not player.Character or not (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")) then
            line:Remove()
            tracerLines[player] = nil
        end
    end
end

-- ---------- Box ESP (прямоугольник вокруг тела) ----------
local function UpdateBoxes()
    if not BoxEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                if root then
                    -- Получаем размеры и позицию
                    local size = root.Size
                    local pos = root.Position
                    -- Вычисляем углы прямоугольника в 3D (приблизительно)
                    local halfSize = size / 2
                    local corners = {
                        pos + Vector3.new(-halfSize.X, -halfSize.Y, 0),
                        pos + Vector3.new( halfSize.X, -halfSize.Y, 0),
                        pos + Vector3.new( halfSize.X,  halfSize.Y, 0),
                        pos + Vector3.new(-halfSize.X,  halfSize.Y, 0),
                    }

                    -- Конвертируем в экранные координаты
                    local screenCorners = {}
                    for i, corner in ipairs(corners) do
                        local vec, onScreen = Camera:WorldToScreenPoint(corner)
                        if onScreen then
                            screenCorners[i] = Vector2.new(vec.X, vec.Y)
                        else
                            -- Если точка за экраном, ставим её в центр (или пропускаем)
                            screenCorners[i] = nil
                        end
                    end

                    -- Если хотя бы одна точка не видна, можно не рисовать, либо рисовать урезанный прямоугольник
                    -- Для простоты рисуем только если все 4 точки видны
                    if screenCorners[1] and screenCorners[2] and screenCorners[3] and screenCorners[4] then
                        -- Создаём или обновляем 4 линии
                        local lines = boxLines[player]
                        if not lines then
                            lines = {}
                            for i = 1, 4 do
                                local line = Drawing.new("Line")
                                line.Thickness = 1.5
                                line.Transparency = 0.6
                                lines[i] = line
                            end
                            boxLines[player] = lines
                        end

                        -- Рисуем прямоугольник
                        lines[1].From = screenCorners[1]
                        lines[1].To   = screenCorners[2]
                        lines[2].From = screenCorners[2]
                        lines[2].To   = screenCorners[3]
                        lines[3].From = screenCorners[3]
                        lines[3].To   = screenCorners[4]
                        lines[4].From = screenCorners[4]
                        lines[4].To   = screenCorners[1]

                        -- Цвет по роли
                        local role = player:GetAttribute("Role")
                        local color
                        if role == "SEEKER" then
                            color = Color3.fromRGB(255, 0, 0)
                        elseif role == "HIDER" then
                            color = Color3.fromRGB(0, 255, 0)
                        else
                            color = Color3.fromRGB(255, 255, 255)
                        end
                        for _, line in ipairs(lines) do
                            line.Color = color
                            line.Visible = true
                        end
                    else
                        -- Если не все точки видны, скрываем линии
                        local lines = boxLines[player]
                        if lines then
                            for _, line in ipairs(lines) do
                                line.Visible = false
                            end
                        end
                    end
                end
            end
        end
    end

    -- Чистим боксы для игроков без тела
    for player, lines in pairs(boxLines) do
        if not player or not player.Character or not (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")) then
            for _, line in ipairs(lines) do
                line:Remove()
            end
            boxLines[player] = nil
        end
    end
end

-- ---------- Общий цикл обновления ----------
local function OnRender()
    if TracersEnabled then UpdateTracers() end
    if BoxEnabled then UpdateBoxes() end
end

local function ToggleTracers(state)
    TracersEnabled = state
    if state then
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(OnRender)
        end
    else
        for _, line in pairs(tracerLines) do
            line:Remove()
        end
        tracerLines = {}
    end
end

local function ToggleBox(state)
    BoxEnabled = state
    if state then
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(OnRender)
        end
    else
        for _, lines in pairs(boxLines) do
            for _, line in ipairs(lines) do
                line:Remove()
            end
        end
        boxLines = {}
    end
end

-- Если все ESP выключены, отключаем рендер
local function CheckRenderConnection()
    if ESPEnabled or NameESPEnabled or TracersEnabled or BoxEnabled then
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(OnRender)
        end
    else
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
    end
end

-- ---------- Обработка игроков ----------
local function SetupPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPEnabled then ApplyHighlight(player) end
        if NameESPEnabled then ApplyNameTag(player) end
    end)

    if player.Character then
        if ESPEnabled then ApplyHighlight(player) end
        if NameESPEnabled then ApplyNameTag(player) end
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    SetupPlayer(p)
end
Players.PlayerAdded:Connect(SetupPlayer)

-- ---------- Экспорт ----------
return {
    Init = function(espGroup)
        espGroup:AddToggle("ESPToggle", {
            Text = "Role ESP (Highlight)",
            Default = false,
            Callback = function(v)
                ESPEnabled = v
                UpdateAllHighlights()
                CheckRenderConnection()
            end
        })

        espGroup:AddToggle("NameESPToggle", {
            Text = "Name ESP",
            Default = false,
            Callback = function(v)
                NameESPEnabled = v
                UpdateAllNameTags()
                CheckRenderConnection()
            end
        })

        espGroup:AddToggle("TracersToggle", {
            Text = "Tracers (линии к телу)",
            Default = false,
            Callback = function(v)
                ToggleTracers(v)
                CheckRenderConnection()
            end
        })

        espGroup:AddToggle("BoxToggle", {
            Text = "Box (прямоугольник вокруг тела)",
            Default = false,
            Callback = function(v)
                ToggleBox(v)
                CheckRenderConnection()
            end
        })
    end
}
