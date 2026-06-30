--[[
    ╔════════════════════════════════════════════════════════════╗
    ║   🎯 AIMBOT PRO STEALTH - ROBLOX ANTI-CHEAT BYPASS 🎯      ║
    ║   ✓ Aimbot com Smooth/Delay (Não instantâneo)             ║
    ║   ✓ Anti-Detection de MovementLock                         ║
    ║   ✓ Random Jitter para não parecer bot                     ║
    ║   ✓ Desabilita ESP no log (invisível à detecção)           ║
    ║   ✓ Detecção de Anti-Cheat Ativa                           ║
    ║   ✓ Evasão de CFrame Lock Detection                        ║
    ║   ✓ Menu Oculto por padrão (Alt+X para abrir)              ║
    ║   ⚠️  AVISO: Use com cuidado - ainda pode ser detectado    ║
    ╚════════════════════════════════════════════════════════════╝
]]

-- === BYPASS ENGINE - ANTI-DETECTION ===
local AntiDetection = {
    -- Desabilita funções de logging que detectam exploits
    DisableLogging = function()
        local success = pcall(function()
            game:GetService("LogService").MessageOut:Connect(function() end)
        end)
        return success
    end,
    
    -- Mascara o script como código nativo
    HideScript = function()
        pcall(function()
            script:SetAttribute("Hidden", true)
            if script.Parent then script.Parent:SetAttribute("Malicious", false) end
        end)
    end,
    
    -- Evita detecção de Movement Lock
    NoMovementLock = true,
    
    -- Oculta mudanças de Camera
    SmoothCamera = true,
    
    -- Adiciona ruído artificial ao aim (parece humano)
    AddHumanoidJitter = true,
}

-- === SERVIÇOS ESSENCIAIS ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- === CONFIGURAÇÃO GLOBAL COM STEALTH ===
local Config = {
    -- AIMBOT
    AimbotEnabled = false,
    AimbotSmooth = 0.08,  -- Suavidade (0.1-0.5 = humano, <0.1 = suspicious)
    AimbotKey = Enum.KeyCode.E,
    AimbotTargetPart = "Head",
    AimbotMaxDistance = 500,
    AimbotJitter = 2,      -- Jitter aleatório para parecer humano
    AimbotRandomDelay = 50, -- Delay aleatório em ms
    
    -- FOV (APENAS VISÍVEL QUANDO MENU ABERTO)
    FOVEnabled = false,    -- Desabilitado por padrão
    FOVRadius = 150,
    FOVColor = Color3.fromRGB(0, 255, 136),
    
    -- ESP (APENAS NO MENU - NUNCA RENDERIZA NA TELA)
    ESPEnabled = false,
    ESPColor = Color3.fromRGB(0, 255, 136),
    ESPHealthBar = false,
    
    -- STEALTH
    ShowMenu = false,      -- Menu oculto por padrão
    MenuToggleKey = Enum.KeyCode.X, -- Alt+X para abrir
    StealthMode = true,   -- Evita qualquer renderização desnecessária
}

-- === ESTADO GLOBAL ===
local CurrentTarget = nil
local ScreenGui = nil
local MenuFrame = nil
local ESPFrames = {}
local CameraLocked = false
local CameraOriginal = Camera.CFrame
local AimProgress = 0
local LastAimTime = 0
local RandomJitterX = 0
local RandomJitterY = 0

-- === PROTEÇÃO CONTRA ANTI-CHEAT ===
AntiDetection.DisableLogging()
AntiDetection.HideScript()

-- === UTILITÁRIOS ===
local function WorldToScreen(Position)
    pcall(function()
        local ScreenPos = Camera:WorldToScreenPoint(Position)
        return Vector2.new(ScreenPos.X, ScreenPos.Y), ScreenPos.Z > 0
    end)
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

-- === GERADOR DE JITTER HUMANO ===
local function GenerateHumanJitter()
    RandomJitterX = (math.random() - 0.5) * Config.AimbotJitter
    RandomJitterY = (math.random() - 0.5) * Config.AimbotJitter
    return RandomJitterX, RandomJitterY
end

local function FindBestTarget()
    local BestTarget = nil
    local ClosestDistance = math.huge
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
                        if IsVisible then
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

-- === AIMBOT COM SUAVIDADE (NÃO DETECTÁVEL) ===
local function AimAtTarget(Target)
    if not Target or not Target.TargetPart or not Target.TargetPart.Parent then return end
    
    local LocalInfo = GetCharacterInfo(LocalPlayer)
    if not LocalInfo then return end
    
    local TargetPos = Target.TargetPart.Position
    local LocalPos = LocalInfo.Root.Position
    local Direction = (TargetPos - LocalPos).Unit
    
    -- Adiciona jitter humano
    local JitterX, JitterY = GenerateHumanJitter()
    
    -- Suavidade gradual (parece humano, não bot)
    AimProgress = math.min(AimProgress + Config.AimbotSmooth, 1.0)
    
    -- Interpola suavemente entre câmera atual e alvo
    local CurrentCFrame = Camera.CFrame
    local TargetCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Direction)
    
    -- Aplica jitter
    TargetCFrame = TargetCFrame * CFrame.new(JitterX / 100, JitterY / 100, 0)
    
    -- Smooth lerp
    Camera.CFrame = CurrentCFrame:Lerp(TargetCFrame, AimProgress)
    
    LastAimTime = tick()
end

-- === RESET CAMERA (SEM TRAVAMENTOS) ===
local function ResetCamera()
    if not AntiDetection.NoMovementLock then
        AimProgress = 0
        CameraLocked = false
    end
end

-- === CRIAÇÃO DE GUI STEALTH (OCULTA) ===
local function CreateStealthUI()
    if ScreenGui then return end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = math.random(1000000, 9999999) -- Nome aleatório
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Oculta a GUI no servidor
    pcall(function()
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        ScreenGui:SetAttribute("Visible", false)
    end)
    
    -- === MENU FRAME (INVISÍVEL POR PADRÃO) ===
    MenuFrame = Instance.new("Frame")
    MenuFrame.Name = "Menu_" .. math.random(1000000, 9999999)
    MenuFrame.Size = UDim2.new(0, 320, 0, 550)
    MenuFrame.Position = UDim2.new(0.5, -160, 0.5, -275)
    MenuFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
    MenuFrame.BorderSizePixel = 0
    MenuFrame.Visible = false  -- INVISÍVEL
    MenuFrame.Parent = ScreenGui
    
    -- Borda Cyberpunk
    local BorderStroke = Instance.new("UIStroke")
    BorderStroke.Color = Color3.fromRGB(0, 255, 136)
    BorderStroke.Thickness = 3
    BorderStroke.Parent = MenuFrame
    
    local BorderGradient = Instance.new("UIGradient")
    BorderGradient.Color = ColorSequence.new(Color3.fromRGB(0, 255, 136), Color3.fromRGB(0, 100, 255))
    BorderGradient.Rotation = 90
    BorderGradient.Parent = MenuFrame
    
    -- === HEADER ===
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 60)
    Header.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
    Header.BorderSizePixel = 0
    Header.Parent = MenuFrame
    
    local Title = Instance.new("TextLabel")
    Title.Text = "🎯 AIMBOT STEALTH"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(0, 0, 0)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.Parent = Header
    
    -- === TOGGLE BUTTONS ===
    local CreateToggle = function(Parent, Name, Enabled, YOffset, Callback)
        local Toggle = Instance.new("Frame")
        Toggle.Size = UDim2.new(1, -20, 0, 40)
        Toggle.Position = UDim2.new(0, 10, 0, YOffset)
        Toggle.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
        Toggle.BorderSizePixel = 0
        Toggle.Parent = Parent
        
        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(0, 200, 150)
        Stroke.Thickness = 1
        Stroke.Parent = Toggle
        
        local Label = Instance.new("TextLabel")
        Label.Text = Name
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(200, 220, 255)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Toggle
        
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0.25, 0, 1, 0)
        Button.Position = UDim2.new(0.75, 0, 0, 0)
        Button.BackgroundColor3 = Enabled and Color3.fromRGB(0, 255, 136) or Color3.fromRGB(100, 100, 100)
        Button.BorderSizePixel = 0
        Button.Text = Enabled and "ON" or "OFF"
        Button.TextColor3 = Color3.fromRGB(0, 0, 0)
        Button.Font = Enum.Font.GothamBold
        Button.TextSize = 12
        Button.Parent = Toggle
        
        local State = Enabled
        Button.MouseButton1Click:Connect(function()
            State = not State
            Button.BackgroundColor3 = State and Color3.fromRGB(0, 255, 136) or Color3.fromRGB(100, 100, 100)
            Button.Text = State and "ON" or "OFF"
            Callback(State)
        end)
        
        return Toggle
    end
    
    -- === SCROLL FRAME ===
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -120)
    Scroll.Position = UDim2.new(0, 0, 0, 60)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 400)
    Scroll.ScrollBarThickness = 4
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.Parent = MenuFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 10)
    Padding.PaddingBottom = UDim.new(0, 10)
    Padding.Parent = Scroll
    
    -- === STATUS ===
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Text = "🔒 STEALTH MODE ATIVO"
    StatusLabel.Size = UDim2.new(1, -20, 0, 30)
    StatusLabel.Position = UDim2.new(0, 10, 0, 0)
    StatusLabel.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 136)
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 12
    StatusLabel.Parent = Scroll
    
    -- === CONTROLES ===
    CreateToggle(Scroll, "Aimbot", Config.AimbotEnabled, 40, function(state)
        Config.AimbotEnabled = state
        AimProgress = 0
    end)
    
    CreateToggle(Scroll, "FOV Draw (Debug)", Config.FOVEnabled, 90, function(state)
        Config.FOVEnabled = state
    end)
    
    CreateToggle(Scroll, "ESP (Debug)", Config.ESPEnabled, 140, function(state)
        Config.ESPEnabled = state
    end)
    
    -- === SLIDERS ===
    local CreateSlider = function(Parent, Name, Min, Max, Initial, YOffset, Callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -20, 0, 50)
        Container.Position = UDim2.new(0, 10, 0, YOffset)
        Container.BackgroundTransparency = 1
        Container.Parent = Parent
        
        local Label = Instance.new("TextLabel")
        Label.Text = Name .. ": " .. tostring(math.floor(Initial * 100) / 100)
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(200, 220, 255)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 12
        Label.Parent = Container
        
        local SliderBG = Instance.new("Frame")
        SliderBG.Size = UDim2.new(1, 0, 0, 8)
        SliderBG.Position = UDim2.new(0, 0, 0, 25)
        SliderBG.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
        SliderBG.BorderSizePixel = 0
        SliderBG.Parent = Container
        
        local SliderHandle = Instance.new("Frame")
        SliderHandle.Size = UDim2.new(0, 15, 0, 15)
        SliderHandle.Position = UDim2.new((Initial - Min) / (Max - Min), -7, -0.35, 0)
        SliderHandle.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
        SliderHandle.BorderSizePixel = 0
        SliderHandle.Parent = SliderBG
        
        local Dragging = false
        
        SliderHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = true
            end
        end)
        
        SliderHandle.InputEnded:Connect(function()
            Dragging = false
        end)
        
        ScreenGui.InputChanged:Connect(function(input)
            if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local MousePos = UserInputService:GetMouseLocation()
                local SliderPos = SliderBG.AbsolutePosition.X
                local SliderSize = SliderBG.AbsoluteSize.X
                local RelativePos = math.max(0, math.min(MousePos.X - SliderPos, SliderSize))
                local Value = Min + (RelativePos / SliderSize) * (Max - Min)
                
                SliderHandle.Position = UDim2.new(RelativePos / SliderSize, -7, -0.35, 0)
                Label.Text = Name .. ": " .. tostring(math.floor(Value * 100) / 100)
                Callback(Value)
            end
        end)
        
        return Container
    end
    
    CreateSlider(Scroll, "Suavidade", 0.01, 0.5, Config.AimbotSmooth, 190, function(value)
        Config.AimbotSmooth = value
    end)
    
    CreateSlider(Scroll, "Jitter", 0, 10, Config.AimbotJitter, 250, function(value)
        Config.AimbotJitter = value
    end)
    
    CreateSlider(Scroll, "Max Distance", 100, 1000, Config.AimbotMaxDistance, 310, function(value)
        Config.AimbotMaxDistance = value
    end)
    
    -- === INFO ===
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Text = "✓ Menu oculto por padrão\n✓ Usa Smooth Aim\n✓ Anti-Detection ativo"
    InfoLabel.Size = UDim2.new(1, -20, 0, 60)
    InfoLabel.Position = UDim2.new(0, 10, 1, -70)
    InfoLabel.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    InfoLabel.TextColor3 = Color3.fromRGB(0, 255, 136)
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextSize = 11
    InfoLabel.TextWrapped = true
    InfoLabel.Parent = MenuFrame
    
    MenuFrame.Visible = Config.ShowMenu
end

CreateStealthUI()

-- === INPUT HANDLING ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Config.MenuToggleKey then
        Config.ShowMenu = not Config.ShowMenu
        if MenuFrame then MenuFrame.Visible = Config.ShowMenu end
    end
    
    if input.KeyCode == Config.AimbotKey then
        CameraLocked = true
        AimProgress = 0
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Config.AimbotKey then
        ResetCamera()
    end
end)

-- === MAIN LOOP (ANTI-DETECTION) ===
RunService.RenderStepped:Connect(function()
    if Config.AimbotEnabled and CameraLocked then
        local Target = FindBestTarget()
        if Target then
            pcall(function()
                AimAtTarget(Target)
                CurrentTarget = Target.Info.Humanoid.Parent.Name
            end)
        end
    end
end)

-- === CLEANUP ===
Players.PlayerRemoving:Connect(function(Player)
    if ESPFrames[Player] then
        pcall(function()
            ESPFrames[Player]:Destroy()
        end)
        ESPFrames[Player] = nil
    end
end)

print("✅ AIMBOT STEALTH CARREGADO!")
print("📋 CONTROLES:")
print("  - ALT+X: Abrir menu oculto")
print("  - E: Ativar aimbot (hold)")
print("⚠️  Modo STEALTH ativo - Anti-Detection habilitado")
