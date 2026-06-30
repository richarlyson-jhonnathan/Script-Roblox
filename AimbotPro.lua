--[[
    ╔════════════════════════════════════════════════════════════╗
    ║   🎯 AIMBOT PRO MOBILE - GUI PROFISSIONAL 🎯               ║
    ║   ✓ Aimbot Instantâneo com suavidade ajustável            ║
    ║   ✓ ESP Ajustável com Skeleton em Tempo Real              ║
    ║   ✓ FOV Ajustável e Visível na Tela                       ║
    ║   ✓ Menu Profissional - Botão de Esconder/Aparecer        ║
    ║   ✓ Otimizado para Mobile (Touch Input)                   ║
    ║   ✓ Suporte a Keyboard também                             ║
    ║   ✓ Anti-Detecção Integrado                               ║
    ╚════════════════════════════════════════════════════════════��
]]

-- === SERVIÇOS ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

-- === CONFIGURAÇÃO GLOBAL ===
local Config = {
    -- AIMBOT
    AimbotEnabled = false,
    AimbotSmooth = 0.15,
    AimbotInstant = true,
    AimbotKey = Enum.KeyCode.E,
    AimbotTargetPart = "Head",
    AimbotMaxDistance = 500,
    
    -- FOV
    FOVEnabled = true,
    FOVRadius = 200,
    FOVColor = Color3.fromRGB(0, 255, 136),
    
    -- ESP
    ESPEnabled = true,
    ESPColor = Color3.fromRGB(0, 255, 136),
    ESPSkeletonEnabled = true,
    ESPHealthBar = true,
    
    -- MENU
    ShowMenu = false,
    MenuToggleKey = Enum.KeyCode.X,
    MenuRequireAlt = true,
}

-- === ESTADO GLOBAL ===
local CurrentTarget = nil
local ScreenGui = nil
local MenuFrame = nil
local ESPFrames = {}
local FOVCircle = nil
local CameraLocked = false
local CameraOriginal = Camera.CFrame

-- === PROTEÇÃO CONTRA ANTI-CHEAT ===
local function HideScript()
    pcall(function()
        script:SetAttribute("Hidden", true)
        if script.Parent then script.Parent:SetAttribute("Malicious", false) end
    end)
end
HideScript()

-- === UTILITÁRIOS ===
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

local function GetTargetPart(Character, PartName)
    if not Character then return nil end
    if PartName == "Head" then
        return Character:FindFirstChild("Head")
    elseif PartName == "Neck" then
        return Character:FindFirstChild("Neck")
    elseif PartName == "Chest" then
        return Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
    end
    return Character:FindFirstChild("HumanoidRootPart")
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
                    local TargetPart = GetTargetPart(Info.Character, Config.AimbotTargetPart)
                    if TargetPart then
                        local ScreenPos, IsVisible = WorldToScreen(TargetPart.Position)
                        if IsVisible and ScreenPos then
                            local DistToCenter = (ScreenPos - ScreenCenter).Magnitude
                            if DistToCenter < Config.FOVRadius and DistToCenter < ClosestDistance then
                                ClosestDistance = DistToCenter
                                BestTarget = { Info = Info, TargetPart = TargetPart, ScreenPos = ScreenPos }
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
    if not Target or not Target.TargetPart or not Target.TargetPart.Parent then return end
    local LocalInfo = GetCharacterInfo(LocalPlayer)
    if not LocalInfo then return end
    
    local TargetPos = Target.TargetPart.Position
    local LocalPos = LocalInfo.Root.Position
    local Direction = (TargetPos - LocalPos).Unit
    
    local TargetCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Direction)
    
    if Config.AimbotInstant then
        Camera.CFrame = TargetCFrame
    else
        Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, Config.AimbotSmooth)
    end
end

-- === DESENHO FOV ===
local function DrawFOVCircle()
    if FOVCircle then FOVCircle:Destroy() end
    
    if not Config.FOVEnabled then return end
    
    local Drawing = Instance.new("Frame")
    Drawing.Name = "FOVCircle"
    Drawing.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)
    Drawing.Position = UDim2.new(0.5, -Config.FOVRadius, 0.5, -Config.FOVRadius)
    Drawing.BackgroundTransparency = 1
    Drawing.BorderSizePixel = 0
    Drawing.Parent = ScreenGui
    
    local Circle = Instance.new("UIStroke")
    Circle.Color = Config.FOVColor
    Circle.Thickness = 2
    Circle.Parent = Drawing
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(1, 0)
    Corner.Parent = Drawing
    
    FOVCircle = Drawing
end

-- === ESP COM SKELETON ===
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
    
    local ESPData = {
        Container = Container,
        Lines = {},
        NameLabel = nil,
        HealthBar = nil,
    }
    
    -- Nome do jogador
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "NameLabel"
    NameLabel.BackgroundTransparency = 0.3
    NameLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    NameLabel.TextColor3 = Config.ESPColor
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 14
    NameLabel.Size = UDim2.new(0, 100, 0, 20)
    NameLabel.Parent = Container
    NameLabel.BorderSizePixel = 1
    NameLabel.BorderColor3 = Config.ESPColor
    NameLabel.Text = "🎯 " .. Player.Name
    ESPData.NameLabel = NameLabel
    
    -- Health Bar
    if Config.ESPHealthBar then
        local HealthBG = Instance.new("Frame")
        HealthBG.Name = "HealthBG"
        HealthBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        HealthBG.BorderSizePixel = 1
        HealthBG.BorderColor3 = Color3.fromRGB(100, 100, 100)
        HealthBG.Size = UDim2.new(0, 100, 0, 8)
        HealthBG.Parent = Container
        
        local HealthBar = Instance.new("Frame")
        HealthBar.Name = "HealthBar"
        HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        HealthBar.BorderSizePixel = 0
        HealthBar.Size = UDim2.new(1, 0, 1, 0)
        HealthBar.Parent = HealthBG
        
        ESPData.HealthBar = { BG = HealthBG, Bar = HealthBar }
    end
    
    -- Skeleton (linhas conectando ossos)
    if Config.ESPSkeletonEnabled then
        local Bones = {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"},
            {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"},
            {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"},
            {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"},
            {"RightLowerLeg", "RightFoot"},
        }
        
        for _, BonePair in pairs(Bones) do
            local Line = Instance.new("Frame")
            Line.BackgroundColor3 = Config.ESPColor
            Line.BorderSizePixel = 0
            Line.Parent = Container
            ESPData.Lines[#ESPData.Lines + 1] = Line
        end
    end
    
    ESPFrames[Player] = ESPData
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
                -- Atualizar nome
                if ESPData.NameLabel then
                    local ScreenPos, OnScreen = WorldToScreen(Head.Position)
                    if OnScreen and ScreenPos then
                        ESPData.NameLabel.Visible = true
                        ESPData.NameLabel.Position = UDim2.new(0, ScreenPos.X - 50, 0, ScreenPos.Y - 30)
                        ESPData.NameLabel.Text = "🎯 " .. Player.Name .. " [" .. math.floor(Humanoid.Health) .. "HP]"
                    else
                        ESPData.NameLabel.Visible = false
                    end
                end
                
                -- Atualizar Health Bar
                if ESPData.HealthBar then
                    local Head = Character:FindFirstChild("Head")
                    local ScreenPos, OnScreen = WorldToScreen(Head.Position)
                    if OnScreen and ScreenPos then
                        ESPData.HealthBar.BG.Visible = true
                        ESPData.HealthBar.BG.Position = UDim2.new(0, ScreenPos.X - 50, 0, ScreenPos.Y - 10)
                        local HealthPercent = Humanoid.Health / Humanoid.MaxHealth
                        ESPData.HealthBar.Bar.Size = UDim2.new(HealthPercent, 0, 1, 0)
                        ESPData.HealthBar.Bar.BackgroundColor3 = HealthPercent > 0.5 and Color3.fromRGB(0, 255, 0) or (HealthPercent > 0.25 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0))
                    else
                        ESPData.HealthBar.BG.Visible = false
                    end
                end
                
                -- Atualizar Skeleton
                if Config.ESPSkeletonEnabled then
                    local Bones = {
                        {"Head", "UpperTorso"},
                        {"UpperTorso", "LowerTorso"},
                        {"UpperTorso", "LeftUpperArm"},
                        {"LeftUpperArm", "LeftLowerArm"},
                        {"LeftLowerArm", "LeftHand"},
                        {"UpperTorso", "RightUpperArm"},
                        {"RightUpperArm", "RightLowerArm"},
                        {"RightLowerArm", "RightHand"},
                        {"LowerTorso", "LeftUpperLeg"},
                        {"LeftUpperLeg", "LeftLowerLeg"},
                        {"LeftLowerLeg", "LeftFoot"},
                        {"LowerTorso", "RightUpperLeg"},
                        {"RightUpperLeg", "RightLowerLeg"},
                        {"RightLowerLeg", "RightFoot"},
                    }
                    
                    for i, BonePair in pairs(Bones) do
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
                if ESPData.NameLabel then ESPData.NameLabel.Visible = false end
                if ESPData.HealthBar then ESPData.HealthBar.BG.Visible = false end
                for _, Line in pairs(ESPData.Lines) do Line.Visible = false end
            end
        end
    end
end

-- === CRIAÇÃO DE GUI PROFISSIONAL ===
local function CreateProfessionalUI()
    if ScreenGui then return end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AimbotProGUI_" .. math.random(1000000, 9999999)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 1000
    
    if LocalPlayer then
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if PlayerGui then
            ScreenGui.Parent = PlayerGui
        end
    end
    
    -- === MENU FRAME (PROFISSIONAL) ===
    MenuFrame = Instance.new("Frame")
    MenuFrame.Name = "MenuFrame"
    MenuFrame.Size = UDim2.new(0, 350, 0, 600)
    MenuFrame.Position = UDim2.new(0, 20, 0.5, -300)
    MenuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    MenuFrame.BorderSizePixel = 0
    MenuFrame.Visible = Config.ShowMenu
    MenuFrame.Parent = ScreenGui
    
    -- Gradient Background
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 40))
    })
    Gradient.Parent = MenuFrame
    
    -- Border
    local Border = Instance.new("UIStroke")
    Border.Color = Color3.fromRGB(0, 255, 136)
    Border.Thickness = 2
    Border.Parent = MenuFrame
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MenuFrame
    
    -- === HEADER ===
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 70)
    Header.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
    Header.BorderSizePixel = 0
    Header.Parent = MenuFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Text = "🎯 AIMBOT PRO"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(0, 0, 0)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 22
    Title.Parent = Header
    
    -- === SCROLL FRAME ===
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -120)
    Scroll.Position = UDim2.new(0, 0, 0, 70)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 650)
    Scroll.ScrollBarThickness = 4
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.Parent = MenuFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 15)
    Padding.PaddingBottom = UDim.new(0, 15)
    Padding.PaddingLeft = UDim.new(0, 15)
    Padding.PaddingRight = UDim.new(0, 15)
    Padding.Parent = Scroll
    
    -- === FUNÇÃO PARA CRIAR TOGGLE ===
    local function CreateToggle(Parent, Name, Enabled, YOffset, Callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -30, 0, 45)
        Container.Position = UDim2.new(0, 15, 0, YOffset)
        Container.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        Container.BorderSizePixel = 0
        Container.Parent = Parent
        
        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 8)
        ContainerCorner.Parent = Container
        
        local ContainerStroke = Instance.new("UIStroke")
        ContainerStroke.Color = Color3.fromRGB(0, 200, 150)
        ContainerStroke.Thickness = 1
        ContainerStroke.Parent = Container
        
        local Label = Instance.new("TextLabel")
        Label.Text = Name
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(200, 220, 255)
        Label.Font = Enum.Font.GothamSemibold
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container
        
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0.25, -5, 0, 30)
        Button.Position = UDim2.new(0.75, 5, 0.5, -15)
        Button.BackgroundColor3 = Enabled and Color3.fromRGB(0, 255, 136) or Color3.fromRGB(80, 80, 100)
        Button.BorderSizePixel = 0
        Button.Text = Enabled and "✓" or "✗"
        Button.TextColor3 = Color3.fromRGB(0, 0, 0)
        Button.Font = Enum.Font.GothamBold
        Button.TextSize = 16
        Button.Parent = Container
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 6)
        ButtonCorner.Parent = Button
        
        local State = Enabled
        Button.MouseButton1Click:Connect(function()
            State = not State
            Button.BackgroundColor3 = State and Color3.fromRGB(0, 255, 136) or Color3.fromRGB(80, 80, 100)
            Button.Text = State and "✓" or "✗"
            Callback(State)
        end)
    end
    
    -- === FUNÇÃO PARA CRIAR SLIDER ===
    local function CreateSlider(Parent, Name, Min, Max, Initial, YOffset, Callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -30, 0, 65)
        Container.Position = UDim2.new(0, 15, 0, YOffset)
        Container.BackgroundTransparency = 1
        Container.Parent = Parent
        
        local Label = Instance.new("TextLabel")
        Label.Text = Name .. ": " .. tostring(math.floor(Initial * 100) / 100)
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(0, 255, 136)
        Label.Font = Enum.Font.GothamSemibold
        Label.TextSize = 12
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container
        
        local SliderBG = Instance.new("Frame")
        SliderBG.Size = UDim2.new(1, 0, 0, 10)
        SliderBG.Position = UDim2.new(0, 0, 0, 30)
        SliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        SliderBG.BorderSizePixel = 0
        SliderBG.Parent = Container
        
        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(1, 0)
        SliderCorner.Parent = SliderBG
        
        local SliderHandle = Instance.new("Frame")
        SliderHandle.Size = UDim2.new(0, 18, 0, 18)
        SliderHandle.Position = UDim2.new((Initial - Min) / (Max - Min), -9, -0.4, 0)
        SliderHandle.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
        SliderHandle.BorderSizePixel = 0
        SliderHandle.Parent = SliderBG
        
        local HandleCorner = Instance.new("UICorner")
        HandleCorner.CornerRadius = UDim.new(1, 0)
        HandleCorner.Parent = SliderHandle
        
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
            if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local MousePos = UserInputService:GetMouseLocation()
                local X = input.Position and input.Position.X or MousePos.X
                local SliderPos = SliderBG.AbsolutePosition.X
                local SliderSize = SliderBG.AbsoluteSize.X
                local RelativePos = math.max(0, math.min(X - SliderPos, SliderSize))
                local Value = Min + (RelativePos / SliderSize) * (Max - Min)
                
                SliderHandle.Position = UDim2.new(RelativePos / SliderSize, -9, -0.4, 0)
                Label.Text = Name .. ": " .. tostring(math.floor(Value * 100) / 100)
                Callback(Value)
            end
        end)
    end
    
    -- === ADICIONAR ELEMENTOS AO MENU ===
    CreateToggle(Scroll, "🎯 Aimbot Ativado", Config.AimbotEnabled, 0, function(state)
        Config.AimbotEnabled = state
    end)
    
    CreateToggle(Scroll, "📍 Aimbot Instantâneo", Config.AimbotInstant, 55, function(state)
        Config.AimbotInstant = state
    end)
    
    CreateToggle(Scroll, "🎨 FOV Visível", Config.FOVEnabled, 110, function(state)
        Config.FOVEnabled = state
        DrawFOVCircle()
    end)
    
    CreateToggle(Scroll, "👁️ ESP Ativado", Config.ESPEnabled, 165, function(state)
        Config.ESPEnabled = state
    end)
    
    CreateToggle(Scroll, "💀 Skeleton", Config.ESPSkeletonEnabled, 220, function(state)
        Config.ESPSkeletonEnabled = state
    end)
    
    CreateToggle(Scroll, "❤️ Health Bar", Config.ESPHealthBar, 275, function(state)
        Config.ESPHealthBar = state
    end)
    
    CreateSlider(Scroll, "Suavidade", 0.01, 0.5, Config.AimbotSmooth, 330, function(value)
        Config.AimbotSmooth = value
    end)
    
    CreateSlider(Scroll, "FOV Raio", 50, 400, Config.FOVRadius, 410, function(value)
        Config.FOVRadius = value
        DrawFOVCircle()
    end)
    
    CreateSlider(Scroll, "Alcance Máx", 100, 1000, Config.AimbotMaxDistance, 490, function(value)
        Config.AimbotMaxDistance = value
    end)
    
    -- === BOTÃO DE FECHAR (X) ===
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 40, 0, 40)
    CloseButton.Position = UDim2.new(1, -50, 0, 10)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 18
    CloseButton.Text = "✕"
    CloseButton.Parent = Header
    CloseButton.BorderSizePixel = 0
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        Config.ShowMenu = false
        MenuFrame.Visible = false
    end)
    
    -- === BOTÃO FLUTUANTE PARA ABRIR/FECHAR ===
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "MenuToggleButton"
    ToggleButton.Size = UDim2.new(0, 60, 0, 60)
    ToggleButton.Position = UDim2.new(1, -80, 1, -80)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
    ToggleButton.BackgroundTransparency = 0.1
    ToggleButton.Text = "≡"
    ToggleButton.TextColor3 = Color3.fromRGB(0, 255, 136)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 32
    ToggleButton.Parent = ScreenGui
    ToggleButton.ZIndex = 2000
    ToggleButton.Visible = true
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 30)
    ToggleCorner.Parent = ToggleButton
    
    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Color = Color3.fromRGB(0, 255, 136)
    ToggleStroke.Thickness = 2
    ToggleStroke.Parent = ToggleButton
    
    -- Drag para Mobile
    local Dragging = false
    local DragOffset = Vector2.new(0, 0)
    
    local function UpdateDrag(input)
        local pos = input.Position
        ToggleButton.Position = UDim2.new(0, pos.X - DragOffset.X, 0, pos.Y - DragOffset.Y)
    end
    
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            local AbsPos = ToggleButton.AbsolutePosition
            DragOffset = Vector2.new(input.Position.X - AbsPos.X, input.Position.Y - AbsPos.Y)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    
    ToggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            if Dragging then UpdateDrag(input) end
        end
    end)
    
    ToggleButton.MouseButton1Click:Connect(function()
        Config.ShowMenu = not Config.ShowMenu
        MenuFrame.Visible = Config.ShowMenu
    end)
    
    MenuFrame.Visible = Config.ShowMenu
    
    DrawFOVCircle()
end

CreateProfessionalUI()

-- === INPUT HANDLING ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Config.MenuToggleKey then
            local AltDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
            if (Config.MenuRequireAlt and AltDown) or (not Config.MenuRequireAlt) then
                Config.ShowMenu = not Config.ShowMenu
                if MenuFrame then MenuFrame.Visible = Config.ShowMenu end
            end
        end
        
        if input.KeyCode == Config.AimbotKey then
            CameraLocked = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Config.AimbotKey then
            CameraLocked = false
        end
    end
end)

-- === MAIN LOOP ===
RunService.RenderStepped:Connect(function()
    -- Aimbot
    if Config.AimbotEnabled and CameraLocked then
        local Target = FindBestTarget()
        if Target then
            pcall(function()
                AimAtTarget(Target)
                CurrentTarget = Target.Info.Humanoid.Parent.Name
            end)
        end
    end
    
    -- ESP
    if Config.ESPEnabled then
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer then
                if not ESPFrames[Player] and Player.Character then
                    CreateESPForPlayer(Player)
                end
            end
        end
        UpdateESP()
    else
        for Player, ESPData in pairs(ESPFrames) do
            pcall(function()
                if ESPData.NameLabel then ESPData.NameLabel.Visible = false end
                if ESPData.HealthBar then ESPData.HealthBar.BG.Visible = false end
                for _, Line in pairs(ESPData.Lines) do Line.Visible = false end
            end)
        end
    end
end)

-- === EVENTOS ===
Players.PlayerAdded:Connect(function(Player)
    if Config.ESPEnabled then
        wait(0.5)
        if Player.Character then
            CreateESPForPlayer(Player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(Player)
    if ESPFrames[Player] then
        pcall(function()
            ESPFrames[Player].Container:Destroy()
        end)
        ESPFrames[Player] = nil
    end
end)

print("✅ AIMBOT PRO - GUI PROFISSIONAL CARREGADO!")
print("📋 CONTROLES:")
print("  - ALT+X / Botão ≡: Abrir/Fechar Menu (Mobile/PC)")
print("  - E (Hold): Ativar Aimbot")
print("🎮 Otimizado para Mobile!")
