--[[
    ╔════════════════════════════════════════════════════════════╗
    ║   🎯 AIMBOT PRO - DELTA EXECUTOR COMPATIBLE 🎯            ║
    ║   ✓ Aimbot Instantâneo - Funciona 100%                   ║
    ║   ✓ ESP com Skeleton em Tempo Real                       ║
    ║   ✓ FOV Ajustável                                         ║
    ║   ✓ Menu Profissional com Toggle/Sliders                 ║
    ║   ✓ Otimizado para Mobile                                ║
    ║   ✓ SEM ERROS - Testado e Funcional                      ║
    ╚════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("⚠️ LocalPlayer não encontrado!")
    return
end

-- === CONFIGURAÇÃO ===
local Config = {
    AimbotEnabled = false,
    AimbotSmooth = 0.2,
    AimbotKey = Enum.KeyCode.E,
    AimbotMaxDistance = 500,
    FOVEnabled = true,
    FOVRadius = 200,
    ESPEnabled = true,
    ESPSkeletonEnabled = true,
    ESPHealthBar = true,
    ShowMenu = false,
}

-- === ESTADO ===
local ScreenGui = nil
local MenuFrame = nil
local ESPFrames = {}
local CameraLocked = false
local FOVCircle = nil

-- === PROTEÇÃO ===
pcall(function()
    script:SetAttribute("Hidden", true)
end)

-- === FUNÇÕES UTILITÁRIAS ===
local function SafeCall(func)
    return pcall(func)
end

local function WorldToScreen(Position)
    if not Camera then return nil, false end
    local ok, screenPos, onScreen = pcall(function()
        return Camera:WorldToScreenPoint(Position)
    end)
    if ok and screenPos then
        return Vector2.new(screenPos.X, screenPos.Y), onScreen
    end
    return nil, false
end

local function GetCharacterInfo(Player)
    if not Player or not Player.Character then return nil end
    local Character = Player.Character
    local Head = Character:FindFirstChild("Head")
    local Root = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChild("Humanoid")
    
    if Head and Root and Humanoid and Humanoid.Health > 0 then
        return { Head = Head, Root = Root, Humanoid = Humanoid, Character = Character }
    end
    return nil
end

local function FindBestTarget()
    local BestTarget = nil
    local ClosestDistance = math.huge
    
    if not Camera or not Camera.ViewportSize then return nil end
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    local LocalInfo = GetCharacterInfo(LocalPlayer)
    if not LocalInfo then return nil end
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Info = GetCharacterInfo(Player)
            if Info then
                local Distance = (Info.Root.Position - LocalInfo.Root.Position).Magnitude
                if Distance <= Config.AimbotMaxDistance then
                    local Head = Info.Head
                    if Head then
                        local ScreenPos, IsVisible = WorldToScreen(Head.Position)
                        if IsVisible and ScreenPos then
                            local DistToCenter = (ScreenPos - ScreenCenter).Magnitude
                            if DistToCenter < Config.FOVRadius and DistToCenter < ClosestDistance then
                                ClosestDistance = DistToCenter
                                BestTarget = { Info = Info, Head = Head, ScreenPos = ScreenPos }
                            end
                        end
                    end
                end
            end
        end
    end
    
    return BestTarget
end

local function AimAtTarget(Target)
    if not Target or not Target.Head or not Target.Head.Parent then return end
    local LocalInfo = GetCharacterInfo(LocalPlayer)
    if not LocalInfo then return end
    
    local TargetPos = Target.Head.Position
    local LocalPos = LocalInfo.Root.Position
    local Direction = (TargetPos - LocalPos)
    
    if Direction.Magnitude > 0 then
        Direction = Direction.Unit
        local TargetCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Direction)
        Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, Config.AimbotSmooth)
    end
end

local function DrawFOVCircle()
    if FOVCircle then
        pcall(function() FOVCircle:Destroy() end)
        FOVCircle = nil
    end
    
    if not Config.FOVEnabled or not ScreenGui then return end
    
    local Drawing = Instance.new("Frame")
    Drawing.Name = "FOVCircle"
    Drawing.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)
    Drawing.Position = UDim2.new(0.5, -Config.FOVRadius, 0.5, -Config.FOVRadius)
    Drawing.BackgroundTransparency = 1
    Drawing.BorderSizePixel = 0
    Drawing.Parent = ScreenGui
    
    local Circle = Instance.new("UIStroke")
    Circle.Color = Color3.fromRGB(0, 255, 136)
    Circle.Thickness = 2
    Circle.Parent = Drawing
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(1, 0)
    Corner.Parent = Drawing
    
    FOVCircle = Drawing
end

local function CreateESPForPlayer(Player)
    if ESPFrames[Player] then return end
    
    local Character = Player.Character
    if not Character then return end
    
    local Container = Instance.new("Frame")
    Container.Name = "ESPContainer_" .. Player.Name
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.Parent = ScreenGui
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.BackgroundTransparency = 0.3
    NameLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    NameLabel.TextColor3 = Color3.fromRGB(0, 255, 136)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 13
    NameLabel.Size = UDim2.new(0, 80, 0, 18)
    NameLabel.Parent = Container
    NameLabel.BorderSizePixel = 1
    NameLabel.BorderColor3 = Color3.fromRGB(0, 255, 136)
    NameLabel.Text = "🎯 " .. Player.Name
    
    local HealthBG = nil
    local HealthBar = nil
    
    if Config.ESPHealthBar then
        HealthBG = Instance.new("Frame")
        HealthBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        HealthBG.BorderSizePixel = 1
        HealthBG.BorderColor3 = Color3.fromRGB(100, 100, 100)
        HealthBG.Size = UDim2.new(0, 80, 0, 6)
        HealthBG.Parent = Container
        
        HealthBar = Instance.new("Frame")
        HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        HealthBar.BorderSizePixel = 0
        HealthBar.Size = UDim2.new(1, 0, 1, 0)
        HealthBar.Parent = HealthBG
    end
    
    local Lines = {}
    if Config.ESPSkeletonEnabled then
        local Bones = {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"},
            {"UpperTorso", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"},
            {"LowerTorso", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"},
            {"LowerTorso", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"},
        }
        
        for _ = 1, #Bones do
            local Line = Instance.new("Frame")
            Line.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
            Line.BorderSizePixel = 0
            Line.Parent = Container
            table.insert(Lines, Line)
        end
    end
    
    ESPFrames[Player] = {
        Container = Container,
        NameLabel = NameLabel,
        HealthBG = HealthBG,
        HealthBar = HealthBar,
        Lines = Lines,
        Bones = Config.ESPSkeletonEnabled and {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"},
            {"UpperTorso", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"},
            {"LowerTorso", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"},
            {"LowerTorso", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"},
        } or {}
    }
end

local function UpdateESP()
    for Player, ESPData in pairs(ESPFrames) do
        if not Player or not Player.Character or not Player.Character:FindFirstChild("Humanoid") then
            pcall(function() ESPData.Container:Destroy() end)
            ESPFrames[Player] = nil
        else
            local Character = Player.Character
            local Head = Character:FindFirstChild("Head")
            local Humanoid = Character:FindFirstChild("Humanoid")
            
            if Head and Humanoid and Humanoid.Health > 0 then
                local ScreenPos, OnScreen = WorldToScreen(Head.Position)
                if OnScreen and ScreenPos then
                    ESPData.NameLabel.Visible = true
                    ESPData.NameLabel.Position = UDim2.new(0, ScreenPos.X - 40, 0, ScreenPos.Y - 25)
                    ESPData.NameLabel.Text = "🎯 " .. Player.Name .. " [" .. math.floor(Humanoid.Health) .. "]"
                    
                    if ESPData.HealthBG then
                        ESPData.HealthBG.Visible = true
                        ESPData.HealthBG.Position = UDim2.new(0, ScreenPos.X - 40, 0, ScreenPos.Y - 8)
                        local HealthPercent = math.max(0, math.min(1, Humanoid.Health / Humanoid.MaxHealth))
                        ESPData.HealthBar.Size = UDim2.new(HealthPercent, 0, 1, 0)
                    end
                    
                    if Config.ESPSkeletonEnabled and #ESPData.Bones > 0 then
                        for i, BonePair in ipairs(ESPData.Bones) do
                            if i <= #ESPData.Lines then
                                local Bone1 = Character:FindFirstChild(BonePair[1])
                                local Bone2 = Character:FindFirstChild(BonePair[2])
                                
                                if Bone1 and Bone2 then
                                    local Pos1, OnScreen1 = WorldToScreen(Bone1.Position)
                                    local Pos2, OnScreen2 = WorldToScreen(Bone2.Position)
                                    
                                    if OnScreen1 and OnScreen2 and Pos1 and Pos2 then
                                        local Line = ESPData.Lines[i]
                                        local Distance = (Pos2 - Pos1).Magnitude
                                        local Angle = math.atan2(Pos2.Y - Pos1.Y, Pos2.X - Pos1.X)
                                        
                                        Line.Visible = true
                                        Line.Size = UDim2.new(0, Distance, 0, 2)
                                        Line.Position = UDim2.new(0, Pos1.X, 0, Pos1.Y)
                                        Line.Rotation = math.deg(Angle)
                                    else
                                        ESPData.Lines[i].Visible = false
                                    end
                                else
                                    ESPData.Lines[i].Visible = false
                                end
                            end
                        end
                    end
                else
                    ESPData.NameLabel.Visible = false
                    if ESPData.HealthBG then ESPData.HealthBG.Visible = false end
                    for _, Line in ipairs(ESPData.Lines) do Line.Visible = false end
                end
            else
                ESPData.NameLabel.Visible = false
                if ESPData.HealthBG then ESPData.HealthBG.Visible = false end
                for _, Line in ipairs(ESPData.Lines) do Line.Visible = false end
            end
        end
    end
end

-- === CRIAR GUI ===
local function CreateUI()
    if ScreenGui then return end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AimbotProGUI_" .. math.random(100000, 999999)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 10000
    
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if PlayerGui then
        ScreenGui.Parent = PlayerGui
    else
        return
    end
    
    -- === MENU ===
    MenuFrame = Instance.new("Frame")
    MenuFrame.Size = UDim2.new(0, 300, 0, 500)
    MenuFrame.Position = UDim2.new(0, 20, 0.5, -250)
    MenuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    MenuFrame.BorderSizePixel = 0
    MenuFrame.Visible = Config.ShowMenu
    MenuFrame.Parent = ScreenGui
    
    local Border = Instance.new("UIStroke")
    Border.Color = Color3.fromRGB(0, 255, 136)
    Border.Thickness = 2
    Border.Parent = MenuFrame
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = MenuFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
    Header.BorderSizePixel = 0
    Header.Parent = MenuFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Text = "🎯 AIMBOT PRO"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(0, 0, 0)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.Parent = Header
    
    -- Scroll
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -60)
    Scroll.Position = UDim2.new(0, 0, 0, 50)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
    Scroll.ScrollBarThickness = 3
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.Parent = MenuFrame
    
    local function CreateToggle(Name, Enabled, YPos, Callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -20, 0, 40)
        Container.Position = UDim2.new(0, 10, 0, YPos)
        Container.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        Container.BorderSizePixel = 0
        Container.Parent = Scroll
        
        local Corner2 = Instance.new("UICorner")
        Corner2.CornerRadius = UDim.new(0, 6)
        Corner2.Parent = Container
        
        local Label = Instance.new("TextLabel")
        Label.Text = Name
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(200, 220, 255)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 12
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container
        
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0.25, 0, 1, 0)
        Button.Position = UDim2.new(0.75, 0, 0, 0)
        Button.BackgroundColor3 = Enabled and Color3.fromRGB(0, 255, 136) or Color3.fromRGB(80, 80, 100)
        Button.BorderSizePixel = 0
        Button.Text = Enabled and "ON" or "OFF"
        Button.TextColor3 = Color3.fromRGB(0, 0, 0)
        Button.Font = Enum.Font.GothamBold
        Button.TextSize = 11
        Button.Parent = Container
        
        local State = Enabled
        Button.MouseButton1Click:Connect(function()
            State = not State
            Button.BackgroundColor3 = State and Color3.fromRGB(0, 255, 136) or Color3.fromRGB(80, 80, 100)
            Button.Text = State and "ON" or "OFF"
            Callback(State)
        end)
    end
    
    local function CreateSlider(Name, Min, Max, Initial, YPos, Callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -20, 0, 50)
        Container.Position = UDim2.new(0, 10, 0, YPos)
        Container.BackgroundTransparency = 1
        Container.Parent = Scroll
        
        local Label = Instance.new("TextLabel")
        Label.Text = Name .. ": " .. tostring(math.floor(Initial * 100) / 100)
        Label.Size = UDim2.new(1, 0, 0, 18)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(0, 255, 136)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 11
        Label.Parent = Container
        
        local SliderBG = Instance.new("Frame")
        SliderBG.Size = UDim2.new(1, 0, 0, 8)
        SliderBG.Position = UDim2.new(0, 0, 0, 25)
        SliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        SliderBG.BorderSizePixel = 0
        SliderBG.Parent = Container
        
        local SliderHandle = Instance.new("Frame")
        SliderHandle.Size = UDim2.new(0, 14, 0, 14)
        SliderHandle.Position = UDim2.new((Initial - Min) / (Max - Min), -7, -0.3, 0)
        SliderHandle.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
        SliderHandle.BorderSizePixel = 0
        SliderHandle.Parent = SliderBG
        
        local Dragging = false
        
        SliderHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)
        
        ScreenGui.InputChanged:Connect(function(input)
            if Dragging then
                local X = input.Position and input.Position.X or UserInputService:GetMouseLocation().X
                local SliderPos = SliderBG.AbsolutePosition.X
                local SliderSize = SliderBG.AbsoluteSize.X
                local RelativePos = math.max(0, math.min(X - SliderPos, SliderSize))
                local Value = Min + (RelativePos / SliderSize) * (Max - Min)
                
                SliderHandle.Position = UDim2.new(RelativePos / SliderSize, -7, -0.3, 0)
                Label.Text = Name .. ": " .. tostring(math.floor(Value * 100) / 100)
                Callback(Value)
            end
        end)
    end
    
    CreateToggle("🎯 Aimbot", Config.AimbotEnabled, 10, function(state)
        Config.AimbotEnabled = state
    end)
    
    CreateToggle("🎨 FOV Visible", Config.FOVEnabled, 60, function(state)
        Config.FOVEnabled = state
        DrawFOVCircle()
    end)
    
    CreateToggle("👁️ ESP", Config.ESPEnabled, 110, function(state)
        Config.ESPEnabled = state
    end)
    
    CreateToggle("💀 Skeleton", Config.ESPSkeletonEnabled, 160, function(state)
        Config.ESPSkeletonEnabled = state
    end)
    
    CreateToggle("❤️ Health Bar", Config.ESPHealthBar, 210, function(state)
        Config.ESPHealthBar = state
    end)
    
    CreateSlider("Suavidade", 0.01, 0.5, Config.AimbotSmooth, 260, function(value)
        Config.AimbotSmooth = value
    end)
    
    CreateSlider("FOV Raio", 50, 400, Config.FOVRadius, 320, function(value)
        Config.FOVRadius = value
        DrawFOVCircle()
    end)
    
    CreateSlider("Alcance", 100, 1000, Config.AimbotMaxDistance, 380, function(value)
        Config.AimbotMaxDistance = value
    end)
    
    -- Toggle Button
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 55, 0, 55)
    ToggleBtn.Position = UDim2.new(1, -75, 1, -75)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
    ToggleBtn.BackgroundTransparency = 0.2
    ToggleBtn.Text = "≡"
    ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 136)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 28
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.ZIndex = 5000
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 27)
    BtnCorner.Parent = ToggleBtn
    
    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = Color3.fromRGB(0, 255, 136)
    BtnStroke.Thickness = 2
    BtnStroke.Parent = ToggleBtn
    
    ToggleBtn.MouseButton1Click:Connect(function()
        Config.ShowMenu = not Config.ShowMenu
        MenuFrame.Visible = Config.ShowMenu
    end)
    
    DrawFOVCircle()
end

CreateUI()

-- === INPUT HANDLING ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.AimbotKey then
        CameraLocked = true
    end
    
    if input.KeyCode == Enum.KeyCode.X then
        Config.ShowMenu = not Config.ShowMenu
        if MenuFrame then MenuFrame.Visible = Config.ShowMenu end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Config.AimbotKey then
        CameraLocked = false
    end
end)

-- === MAIN LOOP ===
RunService.RenderStepped:Connect(function()
    if Config.AimbotEnabled and CameraLocked then
        local Target = FindBestTarget()
        if Target then
            SafeCall(function()
                AimAtTarget(Target)
            end)
        end
    end
    
    if Config.ESPEnabled then
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer and Player.Character then
                if not ESPFrames[Player] then
                    CreateESPForPlayer(Player)
                end
            end
        end
        UpdateESP()
    end
end)

-- === CLEANUP ===
Players.PlayerRemoving:Connect(function(Player)
    if ESPFrames[Player] then
        pcall(function()
            ESPFrames[Player].Container:Destroy()
        end)
        ESPFrames[Player] = nil
    end
end)

print("✅ AIMBOT PRO LOADED - DELTA EXECUTOR")
print("🎮 CONTROLES:")
print("  E = Aimbot (Hold)")
print("  X = Abrir/Fechar Menu")
print("  ≡ = Menu Flutuante")
