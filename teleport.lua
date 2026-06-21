return {
    Init = function(TeleportGroup)
        local function TeleportTo(x, y, z)
            local Char = game.Players.LocalPlayer.Character
            local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
            if HRP then
                HRP.CFrame = CFrame.new(x, y, z)
            end
        end

        TeleportGroup:AddButton({Text = "Lobby", Func = function() TeleportTo(517.70, 171.47, 47.04) end})
        TeleportGroup:AddLabel("Телепорт в лобби (основная зона)")
    end
}