getgenv().fsociety = {
    SilentAim = false, FOV = 220, Prediction = 0.14, TargetPart = "Head", TeamCheck = true, VisibleCheck = true, ShowFOV = true, FOVColor = Color3.fromRGB(0, 170, 255),
    WalkSpeed = 16, JumpPower = 50, DashSpeed = 300, DashHack = false,
    FastAttack = false, AttackSpeedMS = 10,
    Hitbox = false, HitboxSize = Vector3.new(22, 22, 22),
    ESP = false, AntiStun = false, LockOn = false, LockTarget = nil,
    Invisible = false, NoClip = false, AutoHaki = false,
}

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VU = game:GetService("VirtualUser")
local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local WS = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = WS.CurrentCamera
local Mouse = LP:GetMouse()

local hud = Drawing.new("Text")
hud.Size = 15
hud.Color = Color3.fromRGB(0, 255, 255)
hud.Outline = true
hud.Position = Vector2.new(10, 10)
hud.Visible = true

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 3
fovCircle.Color = fsociety.FOVColor
fovCircle.Filled = false

local function GetClosestPlayer()
    local closest, minDist = nil, math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y + 36)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr \~= LP and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if fsociety.TeamCheck and plr.Team == LP.Team then continue end
            local char = plr.Character
            local part = char:FindFirstChild(fsociety.TargetPart) or char.HumanoidRootPart
            if not part then continue end
            local screenPos, onScreen = Cam:WorldToViewportPoint(part.Position)
            if not onScreen then continue end
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if dist > fsociety.FOV then continue end
            if fsociety.VisibleCheck then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LP.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local result = WS:Raycast(Cam.CFrame.Position, (part.Position - Cam.CFrame.Position).Unit * 999, rayParams)
                if not (result and result.Instance:IsDescendantOf(char)) then continue end
            end
            if dist < minDist then minDist = dist closest = plr end
        end
    end
    return closest
end

local mtOld = hookmetamethod(game, "__index", function(self, idx)
    if fsociety.SilentAim and self == Mouse and idx == "Hit" then
        local tgt = GetClosestPlayer()
        if tgt and tgt.Character and tgt.Character:FindFirstChild(fsociety.TargetPart) then
            local part = tgt.Character[fsociety.TargetPart]
            local pred = part.Position + part.AssemblyLinearVelocity * fsociety.Prediction
            return CFrame.new(pred)
        end
    end
    return mtOld(self, idx)
end)

local fastAttackConn
local function StartFastAttack()
    if fastAttackConn then return end
    fastAttackConn = RS.RenderStepped:Connect(function()
        if fsociety.FastAttack then
            VU:ClickButton1(Vector2.new(Mouse.X, Mouse.Y))
            task.wait(fsociety.AttackSpeedMS / 1000)
        else
            fastAttackConn:Disconnect()
            fastAttackConn = nil
        end
    end)
end

local function ServerHopPVP()
    local success, response = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sort=Desc&limit=100")
    end)
    if not success then return end
    local data = HS:JSONDecode(response)
    local valid = {}
    for _, s in ipairs(data.data) do
        if s.playing >= 5 and s.playing <= 25 and s.id \~= game.JobId then
            table.insert(valid, s)
        end
    end
    if #valid > 0 then
        local chosen = valid[math.random(1, #valid)]
        TS:TeleportToPlaceInstance(game.PlaceId, chosen.id, LP)
    end
end

RS.RenderStepped:Connect(function()
    hud.Text = string.format("fsociety hub\nWalk: %d | Jump: %d | Dash: %d | Attack: %dms\nSilent:%s | ESP:%s | Hitbox:%s | Hop:V",
        fsociety.WalkSpeed, fsociety.JumpPower, fsociety.DashSpeed, fsociety.AttackSpeedMS,
        fsociety.SilentAim and "ON" or "OFF", fsociety.ESP and "ON" or "OFF", fsociety.Hitbox and "ON" or "OFF")

    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        hum.WalkSpeed = fsociety.DashHack and fsociety.DashSpeed or fsociety.WalkSpeed
        hum.JumpPower = fsociety.JumpPower
    end

    fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
    fovCircle.Visible = fsociety.SilentAim and fsociety.ShowFOV
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.Q then fsociety.SilentAim = not fsociety.SilentAim
    elseif k == Enum.KeyCode.E then fsociety.FastAttack = not fsociety.FastAttack if fsociety.FastAttack then StartFastAttack() end
    elseif k == Enum.KeyCode.V then ServerHopPVP()
    elseif k == Enum.KeyCode.B then fsociety.DashHack = not fsociety.DashHack
    elseif k == Enum.KeyCode.F1 then fsociety.WalkSpeed = math.clamp(fsociety.WalkSpeed + 10, 0, 600)
    elseif k == Enum.KeyCode.F2 then fsociety.WalkSpeed = math.clamp(fsociety.WalkSpeed - 10, 0, 600)
    elseif k == Enum.KeyCode.F3 then fsociety.JumpPower = math.clamp(fsociety.JumpPower + 10, 0, 600)
    elseif k == Enum.KeyCode.F4 then fsociety.JumpPower = math.clamp(fsociety.JumpPower - 10, 0, 600)
    elseif k == Enum.KeyCode.F5 then fsociety.DashSpeed = math.clamp(fsociety.DashSpeed + 10, 0, 600)
    elseif k == Enum.KeyCode.F6 then fsociety.DashSpeed = math.clamp(fsociety.DashSpeed - 10, 0, 600)
    elseif k == Enum.KeyCode.F7 then fsociety.AttackSpeedMS = math.clamp(fsociety.AttackSpeedMS + 5, 0, 300)
    elseif k == Enum.KeyCode.F8 then fsociety.AttackSpeedMS = math.clamp(fsociety.AttackSpeedMS - 5, 0, 300)
    end
end)

local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/fsctyhub/fsociety-hub/refs/heads/main/fsociety.lua"))()
end)

if not success then
    warn(err)
end
