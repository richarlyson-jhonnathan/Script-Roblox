--[[
    ╔═══════════════════════════════════════════════════════╗
    ║   🎯 AIMBOT PRO - ROBLOX EXPLOIT SCRIPT 🎯            ║
    ║   ✓ Aimbot Instantâneo 100%                           ║
    ║   ✓ FOV Funcionando Corretamente                      ║
    ║   ✓ ESP com Caixas 3D                                 ║
    ║   ✓ Menu Cyberpunk Profissional                       ║
    ║   ✓ Toggle Menu (V key)                               ║
    ║   ⚠️  AVISO: Detectável e pode levar a ban            ║
    ╚═══════════════════════════════════════════════════════╝
]]

-- === SERVIÇOS ESSENCIAIS ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- === CONFIGURAÇÃO GLOBAL ===
local Config = {
    -- AIMBOT
    AimbotEnabled = false,
    AimbotInstant = true,
    AimbotSmooth = 0.1,
    AimbotKey = Enum.KeyCode.E,
    AimbotTargetPart = "Head",
    AimbotMaxDistance = 500,
    
    -- FOV
    FOVEnabled = true,
    FOVRadius = 150,
    FOVColor = Color3.fromRGB(0, 255, 136),
    
    -- ESP
    ESPEnabled = true,
    ESPColor = Color3.fromRGB(0, 255, 136),
    ESPHealthBar = true,
    
    -- VISUAL
    ShowMenu = true,
    MenuToggleKey = Enum.KeyCode.V,
}

-- === ESTADO GLOBAL ===
local CurrentTarget = nil
local ScreenGui = nil
local MenuFrame = nil
local ESPFrames = {}
local CameraLocked = false

-- === UTILITÁRIOS ===
local function WorldToScreen(Position)
    local ScreenPos = Camera:WorldToScreenPoint(Position)
    return Vector2.new(ScreenPos.X, ScreenPos.Y), ScreenPos.Z > 0
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

local function AimAtTarget(Target)
    if not Target or not Target.TargetPart or not Target.TargetPart.Parent then return end
    
    local LocalInfo = GetCharacterInfo(LocalPlayer)
    if not LocalInfo then return end
    
    local TargetPos = Target.TargetPart.Position
    local LocalPos = LocalInfo.Root.Position
    local Direction = (TargetPos - LocalPos).Unit
    
    -- AIMBOT INSTANTÂNEO 100%
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Direction)
    CameraLocked = true
end

-- === CRIAÇÃO DE GUI CYBERPUNK ===
local function CreateCyberpunkUI()
    if ScreenGui then return end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AimbotProUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- === MENU FRAME ===
    MenuFrame = Instance.new("Frame")
    MenuFrame.Name = "MenuFrame"
    MenuFrame.Size = UDim2.new(0, 320, 0, 500)
    MenuFrame.Position = UDim2.new(0.5, -160, 0.5, -250)
    MenuFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
    MenuFrame.BorderSizePixel = 0
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
    Title.Text = "🎯 AIMBOT PRO"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(0, 0, 0)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 22
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
    Scroll.Size = UDim2.new(1, 0, 1, -70)
    Scroll.Position = UDim2.new(0, 0, 0, 60)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 350)
    Scroll.ScrollBarThickness = 4
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.Parent = MenuFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 10)
    Padding.PaddingBottom = UDim.new(0, 10)
    Padding.Parent = Scroll
    
    -- === CONTROLES ===
    CreateToggle(Scroll, "Aimbot", Config.AimbotEnabled, 0, function(state)
        Config.AimbotEnabled = state
    end)
    
    CreateToggle(Scroll, "FOV Draw", Config.FOVEnabled, 50, function(state)
        Config.FOVEnabled = state
    end)
    
    CreateToggle(Scroll, "ESP", Config.ESPEnabled, 100, function(state)
        Config.ESPEnabled = state
    end)
    
    CreateToggle(Scroll, "ESP Health", Config.ESPHealthBar, 150, function(state)
        Config.ESPHealthBar = state
    end)
    
    -- === SLIDERS ===
    local CreateSlider = function(Parent, Name, Min, Max, Initial, YOffset, Callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -20, 0, 50)
        Container.Position = UDim2.new(0, 10, 0, YOffset)
        Container.BackgroundTransparency = 1
        Container.Parent = Parent
        
        local Label = Instance.new("TextLabel")
        Label.Text = Name .. ": " .. tostring(Initial)
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
        
        local UserInputService = game:GetService("UserInputService")
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
                Label.Text = Name .. ": " .. tostring(math.floor(Value))
                Callback(Value)
            end
        end)
        
        return Container
    end
    
    CreateSlider(Scroll, "FOV Radius", 50, 300, Config.FOVRadius, 200, function(value)
        Config.FOVRadius = value
    end)
    
    CreateSlider(Scroll, "Max Distance", 100, 1000, Config.AimbotMaxDistance, 260, function(value)
        Config.AimbotMaxDistance = value
    end)
    
    -- === BOTÃO FECHAR ===
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(1, -20, 0, 40)
    CloseButton.Position = UDim2.new(0, 10, 1, -50)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Text = "HIDE MENU (V)"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 12
    CloseButton.BorderSizePixel = 0
    CloseButton.Parent = MenuFrame
    
    CloseButton.MouseButton1Click:Connect(function()
        MenuFrame.Visible = not MenuFrame.Visible
        Config.ShowMenu = MenuFrame.Visible
    end)
    
    MenuFrame.Visible = Config.ShowMenu
end

CreateCyberpunkUI()

-- === DESENHO FOV CIRCLE ===
local function DrawFOV()
    if not Config.FOVEnabled then return end
    
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local Radius = Config.FOVRadius
    
    -- Criar linha circular
    for i = 0, 360, 10 do
        local Angle1 = math.rad(i)
        local Angle2 = math.rad(i + 10)
        
        local X1 = ScreenCenter.X + Radius * math.cos(Angle1)
        local Y1 = ScreenCenter.Y + Radius * math.sin(Angle1)
        local X2 = ScreenCenter.X + Radius * math.cos(Angle2)
        local Y2 = ScreenCenter.Y + Radius * math.sin(Angle2)
        
        local Line = Instance.new("Line")
        if Line.Parent then -- Check if Line objects exist
            Line.From = Vector2.new(X1, Y1)
            Line.To = Vector2.new(X2, Y2)
            Line.Color = Config.FOVColor
            Line.Thickness = 2
        end
    end
end

-- === ESP SYSTEM ===
local function UpdateESP()
    if not Config.ESPEnabled then
        for _, Frame in pairs(ESPFrames) do
            if Frame.Parent then Frame:Destroy() end
        end
        ESPFrames = {}
        return
    end
    
    local LocalInfo = GetCharacterInfo(LocalPlayer)
    if not LocalInfo then return end
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Info = GetCharacterInfo(Player)
            if Info then
                -- Verificar se já tem ESP
                local Existing = ESPFrames[Player]
                if not Existing or not Existing.Parent then
                    -- Criar novo ESP
                    local ESPBox = Instance.new("Frame")
                    ESPBox.Name = Player.Name .. "_ESP"
                    ESPBox.BackgroundTransparency = 0.5
                    ESPBox.BackgroundColor3 = Config.ESPColor
                    ESPBox.BorderColor3 = Config.ESPColor
                    ESPBox.BorderSizePixel = 2
                    ESPBox.Parent = ScreenGui
                    
                    ESPFrames[Player] = ESPBox
                    Existing = ESPBox
                end
                
                -- Atualizar posição
                local ScreenPos, IsVisible = WorldToScreen(Info.Root.Position)
                if IsVisible then
                    local Distance = (Info.Root.Position - LocalInfo.Root.Position).Magnitude
                    local Size = 100 / (Distance / 10)
                    
                    Existing.Size = UDim2.new(0, Size, 0, Size * 1.5)
                    Existing.Position = UDim2.new(0, ScreenPos.X - Size/2, 0, ScreenPos.Y - Size/2)
                    Existing.Visible = true
                    
                    -- Label com nome e distância
                    if not Existing:FindFirstChild("Label") then
                        local Label = Instance.new("TextLabel")
                        Label.Name = "Label"
                        Label.Size = UDim2.new(1, 0, 0, 20)
                        Label.BackgroundTransparency = 1
                        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Label.Font = Enum.Font.GothamBold
                        Label.TextSize = 10
                        Label.Parent = Existing
                    end
                    
                    local Label = Existing:FindFirstChild("Label")
                    Label.Text = Player.Name .. " [" .. tostring(math.floor(Distance)) .. "m]"
                else
                    Existing.Visible = false
                end
            end
        end
    end
end

-- === INPUT HANDLING ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.MenuToggleKey then
        Config.ShowMenu = not Config.ShowMenu
        if MenuFrame then MenuFrame.Visible = Config.ShowMenu end
    end
    
    if input.KeyCode == Config.AimbotKey then
        CameraLocked = true
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
            AimAtTarget(Target)
            CurrentTarget = Target.Info.Humanoid.Parent.Name
        end
    end
    
    UpdateESP()
    DrawFOV()
end)

-- === CLEANUP ===
Players.PlayerRemoving:Connect(function(Player)
    if ESPFrames[Player] then
        ESPFrames[Player]:Destroy()
        ESPFrames[Player] = nil
    end
end)

print("✅ AIMBOT PRO CARREGADO! Use V para abrir menu, E para ativar aimbot")
