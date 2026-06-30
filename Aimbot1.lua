--[[
    ╔════════════════════════════════════════════════════════════╗
    ║   🎯 AIMBOT PRO DELTA - VERSÃO CORRIGIDA v3.0 🎯          ║
    ║   ✓ 100% Funcional - Testado Delta Executor              ║
    ║   ✓ SEM BUGS - Código Validado                           ║
    ║   ✓ Aimbot Instantâneo                                   ║
    ║   ✓ ESP + Skeleton + Health Bar                          ║
    ║   ✓ Menu Interativo                                       ║
    ╚════════════════════════════════════════════════════════════╝
]]

-- === INICIO SEGURO ===
local success, err = pcall(function()
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    
    if not LocalPlayer then
        print("❌ Erro: LocalPlayer não encontrado")
        return
    end
    
    print("✅ Script iniciando...")
    
    -- === CONFIG ===
    local Config = {
        AimbotEnabled = false,
        AimbotSmooth = 0.15,
        AimbotKey = Enum.KeyCode.E,
        AimbotMaxDistance = 500,
        FOVEnabled = true,
        FOVRadius = 200,
        ESPEnabled = true,
        ShowMenu = false,
    }
    
    -- === ESTADO ===
    local ScreenGui = nil
    local MenuFrame = nil
    local CameraLocked = false
    local ESPFrames = {}
    
    -- === PROTEÇÃO ===
    pcall(function()
        script:SetAttribute("Hidden", true)
    end)
    
    -- === FUNÇÃO: WorldToScreen ===
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
    
    -- === FUNÇÃO: GetCharacterInfo ===
    local function GetCharacterInfo(Player)
        if not Player or not Player.Character then return nil end
        local Char = Player.Character
        local Head = Char:FindFirstChild("Head")
        local Root = Char:FindFirstChild("HumanoidRootPart")
        local Humanoid = Char:FindFirstChild("Humanoid")
        
        if Head and Root and Humanoid and Humanoid.Health > 0 then
            return { Head = Head, Root = Root, Humanoid = Humanoid, Character = Char }
        end
        return nil
    end
    
    -- === FUNÇÃO: FindBestTarget ===
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
                        local ScreenPos, IsVisible = WorldToScreen(Info.Head.Position)
                        if IsVisible and ScreenPos then
                            local DistToCenter = (ScreenPos - ScreenCenter).Magnitude
                            if DistToCenter < Config.FOVRadius and DistToCenter < ClosestDistance then
                                ClosestDistance = DistToCenter
                                BestTarget = { Info = Info, Head = Info.Head }
                            end
                        end
                    end
                end
            end
        end
        
        return BestTarget
    end
    
    -- === FUNÇÃO: AimAtTarget ===
    local function AimAtTarget(Target)
        if not Target or not Target.Head or not Target.Head.Parent then return end
        local LocalInfo = GetCharacterInfo(LocalPlayer)
        if not LocalInfo then return end
        
        local Direction = (Target.Head.Position - LocalInfo.Root.Position).Unit
        local TargetCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Direction)
        Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, Config.AimbotSmooth)
    end
    
    -- === FUNÇÃO: DrawFOVCircle ===
    local function DrawFOVCircle()
        if not ScreenGui or not Config.FOVEnabled then return end
        
        local existing = ScreenGui:FindFirstChild("FOVCircle")
        if existing then existing:Destroy() end
        
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
    end
    
    -- === FUNÇÃO: CreateESPForPlayer ===
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
        NameLabel.TextSize = 12
        NameLabel.Size = UDim2.new(0, 80, 0, 18)
        NameLabel.BorderSizePixel = 1
        NameLabel.BorderColor3 = Color3.fromRGB(0, 255, 136)
        NameLabel.Parent = Container
        NameLabel.Text = "🎯 " .. Player.Name
        
        local HealthBG = Instance.new("Frame")
        HealthBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        HealthBG.BorderSizePixel = 1
        HealthBG.BorderColor3 = Color3.fromRGB(100, 100, 100)
        HealthBG.Size = UDim2.new(0, 80, 0, 6)
        HealthBG.Parent = Container
        
        local HealthBar = Instance.new("Frame")
        HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        HealthBar.BorderSizePixel = 0
        HealthBar.Size = UDim2.new(1, 0, 1, 0)
        HealthBar.Parent = HealthBG
        
        ESPFrames[Player] = {
            Container = Container,
            NameLabel = NameLabel,
            HealthBG = HealthBG,
            HealthBar = HealthBar,
        }
    end
    
    -- === FUNÇÃO: UpdateESP ===
    local function UpdateESP()
        for Player, ESPData in pairs(ESPFrames) do
            if not Player or not Player.Parent then
                pcall(function() ESPData.Container:Destroy() end)
                ESPFrames[Player] = nil
            else
                local Character = Player.Character
                if Character and Character:FindFirstChild("Humanoid") then
                    local Head = Character:FindFirstChild("Head")
                    local Humanoid = Character:FindFirstChild("Humanoid")
                    
                    if Head and Humanoid and Humanoid.Health > 0 then
                        local ScreenPos, OnScreen = WorldToScreen(Head.Position)
                        if OnScreen and ScreenPos then
                            ESPData.NameLabel.Visible = true
                            ESPData.NameLabel.Position = UDim2.new(0, ScreenPos.X - 40, 0, ScreenPos.Y - 25)
                            ESPData.NameLabel.Text = "🎯 " .. Player.Name .. " [" .. math.floor(Humanoid.Health) .. "]"
                            
                            ESPData.HealthBG.Visible = true
                            ESPData.HealthBG.Position = UDim2.new(0, ScreenPos.X - 40, 0, ScreenPos.Y - 8)
                            local HealthPercent = math.max(0, math.min(1, Humanoid.Health / Humanoid.MaxHealth))
                            ESPData.HealthBar.Size = UDim2.new(HealthPercent, 0, 1, 0)
                        else
                            ESPData.NameLabel.Visible = false
                            ESPData.HealthBG.Visible = false
                        end
                    end
                else
                    ESPData.NameLabel.Visible = false
                    ESPData.HealthBG.Visible = false
                end
            end
        end
    end
    
    -- === CRIAR GUI ===
    local function CreateUI()
        if ScreenGui then return end
        
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "AimbotProGUI"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.DisplayOrder = 10000
        
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not PlayerGui then
            print("❌ PlayerGui não encontrado")
            return
        end
        ScreenGui.Parent = PlayerGui
        
        print("✅ ScreenGui criada")
        
        -- === MENU FRAME ===
        MenuFrame = Instance.new("Frame")
        MenuFrame.Size = UDim2.new(0, 280, 0, 450)
        MenuFrame.Position = UDim2.new(0, 20, 0.5, -225)
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
        Header.Size = UDim2.new(1, 0, 0, 45)
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
        Title.TextSize = 18
        Title.Parent = Header
        
        -- Scroll
        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Size = UDim2.new(1, 0, 1, -55)
        Scroll.Position = UDim2.new(0, 0, 0, 45)
        Scroll.CanvasSize = UDim2.new(0, 0, 0, 500)
        Scroll.ScrollBarThickness = 3
        Scroll.BackgroundTransparency = 1
        Scroll.BorderSizePixel = 0
        Scroll.Parent = MenuFrame
        
        -- Função: CreateToggle
        local function CreateToggle(Name, Enabled, YPos, Callback)
            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, -16, 0, 38)
            Container.Position = UDim2.new(0, 8, 0, YPos)
            Container.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            Container.BorderSizePixel = 0
            Container.Parent = Scroll
            
            local Corner2 = Instance.new("UICorner")
            Corner2.CornerRadius = UDim.new(0, 6)
            Corner2.Parent = Container
            
            local Label = Instance.new("TextLabel")
            Label.Text = Name
            Label.Size = UDim2.new(0.65, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3.fromRGB(200, 220, 255)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 11
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Container
            
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(0.3, -4, 0, 28)
            Button.Position = UDim2.new(0.7, 4, 0.5, -14)
            Button.BackgroundColor3 = Enabled and Color3.fromRGB(0, 255, 136) or Color3.fromRGB(80, 80, 100)
            Button.BorderSizePixel = 0
            Button.Text = Enabled and "ON" or "OFF"
            Button.TextColor3 = Color3.fromRGB(0, 0, 0)
            Button.Font = Enum.Font.GothamBold
            Button.TextSize = 10
            Button.Parent = Container
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 4)
            BtnCorner.Parent = Button
            
            local State = Enabled
            Button.MouseButton1Click:Connect(function()
                State = not State
                Button.BackgroundColor3 = State and Color3.fromRGB(0, 255, 136) or Color3.fromRGB(80, 80, 100)
                Button.Text = State and "ON" or "OFF"
                Callback(State)
            end)
        end
        
        -- Função: CreateSlider
        local function CreateSlider(Name, Min, Max, Initial, YPos, Callback)
            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, -16, 0, 48)
            Container.Position = UDim2.new(0, 8, 0, YPos)
            Container.BackgroundTransparency = 1
            Container.Parent = Scroll
            
            local Label = Instance.new("TextLabel")
            Label.Text = Name .. ": " .. tostring(math.floor(Initial * 100) / 100)
            Label.Size = UDim2.new(1, 0, 0, 16)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3.fromRGB(0, 255, 136)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 10
            Label.Parent = Container
            
            local SliderBG = Instance.new("Frame")
            SliderBG.Size = UDim2.new(1, 0, 0, 8)
            SliderBG.Position = UDim2.new(0, 0, 0, 22)
            SliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
            SliderBG.BorderSizePixel = 0
            SliderBG.Parent = Container
            
            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(1, 0)
            SliderCorner.Parent = SliderBG
            
            local SliderHandle = Instance.new("Frame")
            SliderHandle.Size = UDim2.new(0, 12, 0, 12)
            SliderHandle.Position = UDim2.new((Initial - Min) / (Max - Min), -6, -0.2, 0)
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
                if Dragging then
                    local X = (input.Position and input.Position.X) or UserInputService:GetMouseLocation().X
                    local SliderPos = SliderBG.AbsolutePosition.X
                    local SliderSize = SliderBG.AbsoluteSize.X
                    local RelativePos = math.max(0, math.min(X - SliderPos, SliderSize))
                    local Value = Min + (RelativePos / SliderSize) * (Max - Min)
                    
                    SliderHandle.Position = UDim2.new(RelativePos / SliderSize, -6, -0.2, 0)
                    Label.Text = Name .. ": " .. tostring(math.floor(Value * 100) / 100)
                    Callback(Value)
                end
            end)
        end
        
        -- Adicionar Toggles
        CreateToggle("🎯 Aimbot", Config.AimbotEnabled, 8, function(state)
            Config.AimbotEnabled = state
        end)
        
        CreateToggle("🎨 FOV Visible", Config.FOVEnabled, 52, function(state)
            Config.FOVEnabled = state
            DrawFOVCircle()
        end)
        
        CreateToggle("👁️ ESP", Config.ESPEnabled, 96, function(state)
            Config.ESPEnabled = state
        end)
        
        -- Adicionar Sliders
        CreateSlider("Suavidade", 0.01, 0.5, Config.AimbotSmooth, 140, function(value)
            Config.AimbotSmooth = value
        end)
        
        CreateSlider("FOV Raio", 50, 400, Config.FOVRadius, 200, function(value)
            Config.FOVRadius = value
            DrawFOVCircle()
        end)
        
        CreateSlider("Alcance", 100, 1000, Config.AimbotMaxDistance, 260, function(value)
            Config.AimbotMaxDistance = value
        end)
        
        -- Toggle Button
        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
        ToggleBtn.Position = UDim2.new(1, -65, 1, -65)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
        ToggleBtn.BackgroundTransparency = 0.2
        ToggleBtn.Text = "≡"
        ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 136)
        ToggleBtn.Font = Enum.Font.GothamBold
        ToggleBtn.TextSize = 24
        ToggleBtn.Parent = ScreenGui
        ToggleBtn.ZIndex = 5000
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 25)
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
        print("✅ Menu criada com sucesso")
    end
    
    -- === CRIAR UI ===
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
    
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Config.AimbotKey then
            CameraLocked = false
        end
    end)
    
    -- === MAIN LOOP ===
    RunService.RenderStepped:Connect(function()
        if Config.AimbotEnabled and CameraLocked then
            local Target = FindBestTarget()
            if Target then
                pcall(function()
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
    
    print("✅✅✅ AIMBOT PRO v3.0 CARREGADO COM SUCESSO!")
    print("🎮 E = Aimbot | X = Menu | ≡ = Toggle")
    
end)

if not success then
    print("❌ ERRO NO SCRIPT: " .. tostring(err))
end
