local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ==================== ПЕРЕМЕННЫЕ ====================
local InfiniteJumpEnabled = false
local NoClipEnabled = false
local NoclipConnection = nil

local FlyEnabled = false
local FlySpeed = 50
local bg, bv, flyingConn

local SpeedHackEnabled = false
local SpeedHackValue = 50
local OriginalWalkSpeed = 16

-- ==================== INFINITE JUMP ====================
UserInputService.JumpRequest:Connect(function()
    if not InfiniteJumpEnabled then return end
    local Char = LocalPlayer.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if Hum and Hum.Health > 0 then
        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ==================== NOCLIP ====================
local function StartNoClip()
    if NoclipConnection then NoclipConnection:Disconnect() end
    NoclipConnection = RunService.Stepped:Connect(function()
        if not NoClipEnabled then return end
        local Char = LocalPlayer.Character
        if Char then
            for _, part in pairs(Char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function StopNoClip()
    if NoclipConnection then 
        NoclipConnection:Disconnect() 
        NoclipConnection = nil 
    end
    local Char = LocalPlayer.Character
    if Char then
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ==================== FLY ====================
local function StartFly()
    local Char = LocalPlayer.Character
    if not Char then return end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    if not (Root and Hum) then return end

    Hum.PlatformStand = true
    if Char:FindFirstChild("Animate") then Char.Animate.Disabled = true end

    bg = Instance.new("BodyGyro", Root)
    bg.P = 90000
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = Root.CFrame

    bv = Instance.new("BodyVelocity", Root)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0.1, 0)

    flyingConn = RunService.RenderStepped:Connect(function()
        if not FlyEnabled then return end
        local moveDir = Vector3.new()
        local Cam = workspace.CurrentCamera

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            bv.Velocity = moveDir * FlySpeed
            bg.CFrame = Cam.CFrame * CFrame.Angles(-math.rad(5), 0, 0)
        else
            bv.Velocity = Vector3.new(0,0,0)
        end
    end)
end

local function StopFly()
    if flyingConn then flyingConn:Disconnect() flyingConn = nil end
    if bg then bg:Destroy() bg = nil end
    if bv then bv:Destroy() bv = nil end

    local Char = LocalPlayer.Character
    if Char then
        local Hum = Char:FindFirstChildOfClass("Humanoid")
        if Hum then Hum.PlatformStand = false end
        if Char:FindFirstChild("Animate") then Char.Animate.Disabled = false end
    end
end

-- ==================== SPEED HACK ====================
local function ApplySpeedHack()
    local Char = LocalPlayer.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if Hum then
        Hum.WalkSpeed = SpeedHackValue
    end
end

local function StartSpeedHack()
    SpeedHackEnabled = true
    OriginalWalkSpeed = 16 -- стандартная скорость

    -- Применяем сразу
    ApplySpeedHack()

    -- Обновляем при респавне
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if SpeedHackEnabled then
            ApplySpeedHack()
        end
    end)
end

local function StopSpeedHack()
    SpeedHackEnabled = false
    local Char = LocalPlayer.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if Hum then
        Hum.WalkSpeed = OriginalWalkSpeed
    end
end

-- ==================== ИНИЦИАЛИЗАЦИЯ GUI ====================
return {
    Init = function(MovementGroup)
        -- Infinite Jump
        MovementGroup:AddToggle("InfiniteJumpToggle", {
            Text = "Infinite Jump", 
            Default = false, 
            Callback = function(v) InfiniteJumpEnabled = v end
        })

        -- NoClip
        MovementGroup:AddToggle("NoClipToggle", {
            Text = "NoClip", 
            Default = false, 
            Callback = function(v) 
                NoClipEnabled = v 
                if v then StartNoClip() else StopNoClip() end 
            end
        })

        -- Fly
        MovementGroup:AddToggle("FlyToggle", {
            Text = "Fly",
            Default = false,
            Callback = function(v)
                FlyEnabled = v
                if v then StartFly() else StopFly() end
            end
        })

        MovementGroup:AddSlider("FlySpeedSlider", {
            Text = "Fly Speed",
            Default = 50,
            Min = 1,
            Max = 300,
            Rounding = 0,
            Callback = function(v) FlySpeed = v end
        })

        -- ==================== SPEED HACK ====================
        MovementGroup:AddToggle("SpeedHackToggle", {
            Text = "Speed Hack",
            Default = false,
            Callback = function(v)
                if v then
                    StartSpeedHack()
                else
                    StopSpeedHack()
                end
            end
        })

        MovementGroup:AddSlider("SpeedHackSlider", {
            Text = "WalkSpeed",
            Default = 50,
            Min = 16,
            Max = 500,
            Rounding = 0,
            Callback = function(v)
                SpeedHackValue = v
                if SpeedHackEnabled then
                    ApplySpeedHack()
                end
            end
        })
    end
}
