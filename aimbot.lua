return {
    Init = function(AimbotGroup, AimbotGroup2)
        local AimbotEnabled = false
        local SilentAimEnabled = true
        local AimbotFOV = 200
        local AimbotSmoothing = 0.15

        AimbotGroup:AddToggle("AimbotToggle", {Text = "Aimbot (только для Seeker)", Default = false, Callback = function(v) AimbotEnabled = v end})
        AimbotGroup:AddToggle("SilentAimToggle", {Text = "Silent Aim", Default = true, Callback = function(v) SilentAimEnabled = v end})

        AimbotGroup2:AddSlider("FOVSlider", {Text = "FOV радиус", Default = 200, Min = 50, Max = 800, Rounding = 0, Suffix = "px", Callback = function(v) AimbotFOV = v end})
        AimbotGroup2:AddSlider("SmoothSlider", {Text = "Плавность", Default = 15, Min = 1, Max = 100, Rounding = 0, Suffix = "%", Callback = function(v) AimbotSmoothing = v/100 end})
    end
}