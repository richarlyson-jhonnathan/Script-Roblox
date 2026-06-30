--[[
    Script LUA/LUAU para Roblox Mobile (Delta Executor)
    Aimbot com Wallhack e GUI Mobile-Friendly.
    AVISO: Wallhacks são detectáveis e podem levar a banimentos. Use por sua conta e risco.
    Requer funções de acesso à câmera e de desenho.
]]

-- === MÓDULOS ESSENCIAIS ===
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- === FUNÇÕES NECESSÁRIAS DO SEU EXPLORE/FRAMEWORK ===
local Draw = {
    Line = function(startPos, endPos, thickness, color) 
        if startPos and endPos then 
            print("Draw.Line", startPos, endPos, thickness, color) 
        end 
    end,
    Box = function(position, size, thickness, color) 
        if position and size then 
            print("Draw.Box", position, size, thickness, color) 
        end 
    end,
    Text = function(text, font, size, position, color, outline) 
        if text and position then 
            print("Draw.Text", text, font, size, position, color, outline) 
        end 
    end,
    Skeleton = function(bones, thickness, color) 
        if bones then 
            print("Draw.Skeleton", bones, thickness, color) 
        end 
    end,
}

local function worldToScreen(position)
    local camera = workspace.CurrentCamera
    if camera then
        local success, vec2 = pcall(function() return camera:WorldToScreenPoint(position) end)
        if success and vec2 and vec2.Z > 0.01 then
            return Vector2.new(vec2.X, vec2.Y)
        end
    end
    return nil
end

-- === CONFIGURAÇÕES DO AIMBOT ===
local AimbotConfig = {
    Enabled = false,
    InstantAim = true,
    IgnoreTeam = false,

    AimKey = Enum.KeyCode.Button1,
    AimKeyMode = "Hold",

    FOV = 25,
    TargetType = "Head",
    MaxDistance = 400,

    DrawFOV = true,
    DrawCrosshair = true,
    DrawTargetInfo = true,

    CrosshairType = "Cross",
    CrosshairSize = 5,

    FOVColor = Color3.fromRGB(200, 200, 200),
    CrosshairColor = Color3.fromRGB(255, 255, 255),
    TargetInfoColor = Color3.fromRGB(255, 255, 0),
}

-- === CONFIGURAÇÕES DA GUI (MOBILE-FRIENDLY) ===
local GUIConfig = {
    MenuEnabled = true,
    MenuShow = true,
    MenuX = 10,
    MenuY = 100,
    MenuWidth = 380,
    MenuHeight = 600,

    ButtonX = 10,
    ButtonY = 10,
    ButtonSize = UDim2.new(0, 120, 0, 40),
}

-- === REFERÊNCIAS GLOBÁIS ===
local PlayersService = game:GetService("Players")
local LocalPlayer = PlayersService.LocalPlayer
local GuiService = LocalPlayer:WaitForChild("PlayerGui")

-- === ESTADO DO AIMBOT E DA GUI ===
local IsAimKeyPressed = false
local AimToggleState = false
local CurrentTarget = nil
local CurrentTargetScreenPos = nil
local IsDraggingMenu = false
local DragOffset = Vector2.new(0, 0)

-- === CRIAÇÃO DA GUI PRINCIPAL E BOTÃO DE CONTROLE ===
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "MobileAimbot_GUI"
mainGui.Enabled = true
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.ResetOnSpawn = false
mainGui.Parent = GuiService

local menuToggleButton = Instance.new("TextButton")
menuToggleButton.Name = "MenuToggleButton"
menuToggleButton.Size = GUIConfig.ButtonSize
menuToggleButton.Position = UDim2.new(0, GUIConfig.ButtonX, 0, GUIConfig.ButtonY)
menuToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
menuToggleButton.Text = "Abrir Menu"
menuToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
menuToggleButton.Font = Enum.Font.SourceSansBold
menuToggleButton.TextScaled = true
menuToggleButton.Parent = mainGui

local menuFrame = nil

-- ==================================================
-- == FUNÇÕES AUXILIARES DE CRIAÇÃO DE ELEMENTOS GUI ==
-- ==================================================

local function createSection(parent, title, yPos, height)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, -10, 0, height)
    section.Position = UDim2.new(0, 5, 0, yPos)
    section.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    section.BorderColor3 = Color3.fromRGB(50, 50, 50)
    section.BorderSizePixel = 1
    section.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = title
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.SourceSansSemibold
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.BackgroundTransparency = 1
    label.Parent = section
    
    return section
end

local function createToggleSwitch(parent, label, initialValue, position, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.5, -5, 0, 35)
    container.Position = position
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderColor3 = Color3.fromRGB(50, 50, 50)
    container.BorderSizePixel = 1
    container.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Text = label .. ": " .. (initialValue and "ON" or "OFF")
    labelText.Size = UDim2.new(0.6, 0, 1, 0)
    labelText.Position = UDim2.new(0, 5, 0, 0)
    labelText.TextColor3 = Color3.fromRGB(220, 220, 220)
    labelText.Font = Enum.Font.SourceSans
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.TextYAlignment = Enum.TextYAlignment.Center
    labelText.BackgroundTransparency = 1
    labelText.Parent = container
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0.4, 0, 1, 0)
    toggleButton.Position = UDim2.new(0.6, 0, 0, 0)
    toggleButton.BackgroundColor3 = initialValue and Color3.fromRGB(70, 200, 70) or Color3.fromRGB(150, 70, 70)
    toggleButton.Text = ""
    toggleButton.Parent = container
    
    toggleButton.MouseButton1Click:Connect(function()
        local newValue = not initialValue
        initialValue = newValue
        labelText.Text = label .. ": " .. (newValue and "ON" or "OFF")
        toggleButton.BackgroundColor3 = newValue and Color3.fromRGB(70, 200, 70) or Color3.fromRGB(150, 70, 70)
        callback(newValue)
    end)
    
    return container
end

local function createDropdown(parent, label, options, initialValue, position, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.5, -5, 0, 35)
    container.Position = position
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderColor3 = Color3.fromRGB(50, 50, 50)
    container.BorderSizePixel = 1
    container.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Text = label
    labelText.Size = UDim2.new(0.6, 0, 1, 0)
    labelText.Position = UDim2.new(0, 5, 0, 0)
    labelText.TextColor3 = Color3.fromRGB(220, 220, 220)
    labelText.Font = Enum.Font.SourceSans
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.TextYAlignment = Enum.TextYAlignment.Center
    labelText.BackgroundTransparency = 1
    labelText.Parent = container
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Size = UDim2.new(0.4, 0, 1, 0)
    dropdownButton.Position = UDim2.new(0.6, 0, 0, 0)
    dropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    dropdownButton.Text = initialValue
    dropdownButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    dropdownButton.Font = Enum.Font.SourceSans
    dropdownButton.TextScaled = true
    dropdownButton.Parent = container
    
    local dropdownMenu = Instance.new("Frame")
    dropdownMenu.Size = UDim2.new(1, 0, 0, 0)
    dropdownMenu.Position = UDim2.new(0, 0, 1, 0)
    dropdownMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    dropdownMenu.BorderColor3 = Color3.fromRGB(60, 60, 60)
    dropdownMenu.BorderSizePixel = 1
    dropdownMenu.Visible = false
    dropdownMenu.Parent = container
    
    local currentMenuHeight = 0
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 25)
        optionButton.Position = UDim2.new(0, 0, 0, currentMenuHeight)
        optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        optionButton.Text = option
        optionButton.TextColor3 = Color3.fromRGB(220, 220, 220)
        optionButton.Font = Enum.Font.SourceSans
        optionButton.TextScaled = true
        optionButton.Parent = dropdownMenu
        
        optionButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = option
            initialValue = option
            dropdownMenu.Visible = false
            callback(option)
        end)
        
        currentMenuHeight = currentMenuHeight + 25
    end
    
    dropdownMenu.Size = UDim2.new(1, 0, 0, currentMenuHeight)
    
    dropdownButton.MouseButton1Click:Connect(function() 
        dropdownMenu.Visible = not dropdownMenu.Visible 
    end)
    
    return container
end

local function createSlider(parent, label, minVal, maxVal, initialVal, position, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 40)
    container.Position = position
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderColor3 = Color3.fromRGB(50, 50, 50)
    container.BorderSizePixel = 1
    container.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Text = label .. ": " .. string.format("%.2f", initialVal)
    labelText.Size = UDim2.new(1, 0, 0, 18)
    labelText.Position = UDim2.new(0, 5, 0, 0)
    labelText.TextColor3 = Color3.fromRGB(220, 220, 220)
    labelText.Font = Enum.Font.SourceSans
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.TextYAlignment = Enum.TextYAlignment.Center
    labelText.BackgroundTransparency = 1
    labelText.Parent = container
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Size = UDim2.new(1, -10, 0, 12)
    sliderBar.Position = UDim2.new(0, 5, 0, 18)
    sliderBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    sliderBar.BackgroundTransparency = 0.3
    sliderBar.Parent = container
    
    local sliderHandle = Instance.new("Frame")
    sliderHandle.Name = "SliderHandle"
    sliderHandle.Size = UDim2.new(0, 20, 1, 0)
    local initialHandlePos = (initialVal - minVal) / (maxVal - minVal) * (sliderBar.Size.X.Offset - sliderHandle.Size.X.Offset)
    sliderHandle.Position = UDim2.new(0, initialHandlePos, 0, 0)
    sliderHandle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    sliderHandle.BorderColor3 = Color3.fromRGB(255, 255, 255)
    sliderHandle.BorderSizePixel = 1
    sliderHandle.Parent = sliderBar
    
    local isSliding = false
    
    sliderHandle.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            isSliding = true 
            DragOffset = input.Position - sliderHandle.AbsolutePosition
        end 
    end)
    
    sliderBar.InputEnded:Connect(function() 
        isSliding = false 
    end)
    
    mainGui.InputChanged:Connect(function(input) 
        if isSliding and input.UserInputType == Enum.UserInputType.MouseMovement then 
            local currentX = input.Position.X - sliderBar.AbsolutePosition.X - DragOffset.X
            local percentage = math.max(0, math.min(1, currentX / (sliderBar.Size.X.Offset - sliderHandle.Size.X.Offset)))
            local value = minVal + (maxVal - minVal) * percentage
            sliderHandle.Position = UDim2.new(0, percentage * (sliderBar.Size.X.Offset - sliderHandle.Size.X.Offset), 0, 0)
            labelText.Text = label .. ": " .. string.format("%.2f", value)
            callback(value)
        end 
    end)
    
    return container
end

local function createColorPickerButton(parent, label, initialColor, position, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.5, -5, 0, 35)
    container.Position = position
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderColor3 = Color3.fromRGB(50, 50, 50)
    container.BorderSizePixel = 1
    container.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Text = label
    labelText.Size = UDim2.new(0.6, 0, 1, 0)
    labelText.Position = UDim2.new(0, 5, 0, 0)
    labelText.TextColor3 = Color3.fromRGB(220, 220, 220)
    labelText.Font = Enum.Font.SourceSans
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.TextYAlignment = Enum.TextYAlignment.Center
    labelText.BackgroundTransparency = 1
    labelText.Parent = container
    
    local colorPreview = Instance.new("Frame")
    colorPreview.Name = "ColorPreview"
    colorPreview.Size = UDim2.new(0.4, 0, 1, 0)
    colorPreview.Position = UDim2.new(0.6, 0, 0, 0)
    colorPreview.BackgroundColor3 = initialColor
    colorPreview.Parent = container
    
    colorPreview.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local presetColors = { 
                Color3.fromRGB(255, 100, 100), 
                Color3.fromRGB(100, 255, 100), 
                Color3.fromRGB(100, 100, 255), 
                Color3.fromRGB(255, 255, 100), 
                Color3.fromRGB(255, 100, 255), 
                Color3.fromRGB(100, 255, 255)
            }
            local foundIndex = -1
            for i, c in ipairs(presetColors) do 
                if c == initialColor then 
                    foundIndex = i 
                    break 
                end 
            end
            local nextColor = foundIndex ~= -1 and foundIndex < #presetColors and presetColors[foundIndex + 1] or presetColors[1]
            colorPreview.BackgroundColor3 = nextColor
            initialColor = nextColor
            callback(nextColor)
        end
    end)
    
    return container
end

-- ==================================================
-- == CRIAÇÃO DA GUI DE MENU E SEUS ELEMENTOS ==
-- ==================================================

local function createMenuUI()
    if not menuFrame then
        menuFrame = Instance.new("Frame")
        menuFrame.Name = "MobileAimbot_MenuFrame"
        menuFrame.Size = UDim2.new(0, GUIConfig.MenuWidth, 0, GUIConfig.MenuHeight)
        menuFrame.Position = UDim2.new(0, GUIConfig.MenuX, 0, GUIConfig.MenuY)
        menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        menuFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
        menuFrame.BorderSizePixel = 2
        menuFrame.Visible = GUIConfig.MenuShow
        menuFrame.Parent = mainGui

        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 30)
        titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        titleBar.BorderColor3 = Color3.fromRGB(50, 50, 50)
        titleBar.BorderSizePixel = 1
        titleBar.Parent = menuFrame
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Text = "Wallhack Aimbot"
        titleLabel.Size = UDim2.new(1, 0, 1, 0)
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Center
        titleLabel.TextScaled = true
        titleLabel.BackgroundTransparency = 1
        titleLabel.Parent = titleBar
        
        titleBar.InputBegan:Connect(function(input) 
            if input.UserInputType == Enum.UserInputType.MouseButton1 then 
                IsDraggingMenu = true 
                DragOffset = input.Position - menuFrame.AbsolutePosition 
            end 
        end)
        
        titleBar.InputEnded:Connect(function() 
            IsDraggingMenu = false 
        end)

        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "ScrollFrame"
        scrollFrame.Size = UDim2.new(1, 0, 1, -40)
        scrollFrame.Position = UDim2.new(0, 0, 0, 30)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 900)
        scrollFrame.ScrollBarThickness = 6
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.Parent = menuFrame

        local currentY = 5

        local sectionAimbot = createSection(scrollFrame, "Aimbot", currentY, 400)
        currentY = currentY + sectionAimbot.Size.Y.Offset + 10

        createToggleSwitch(sectionAimbot, "Ativar Aimbot", AimbotConfig.Enabled, UDim2.new(0, 5, 0, 30), function(state) AimbotConfig.Enabled = state end)
        createToggleSwitch(sectionAimbot, "Ignorar Time", AimbotConfig.IgnoreTeam, UDim2.new(0.5, -5, 0, 30), function(state) AimbotConfig.IgnoreTeam = state end)
        createDropdown(sectionAimbot, "Modo Tecla", {"Hold", "Toggle"}, AimbotConfig.AimKeyMode, UDim2.new(0, 5, 0, 65), function(value) AimbotConfig.AimKeyMode = value end)
        createDropdown(sectionAimbot, "Alvo", {"Head", "Chest", "Legs", "Root"}, AimbotConfig.TargetType, UDim2.new(0.5, -5, 0, 65), function(value) AimbotConfig.TargetType = value end)
        createSlider(sectionAimbot, "FOV", 1, 60, AimbotConfig.FOV, UDim2.new(0, 5, 0, 100), function(value) AimbotConfig.FOV = value end)
        createSlider(sectionAimbot, "Distância Máx.", 50, 800, AimbotConfig.MaxDistance, UDim2.new(0, 5, 0, 145), function(value) AimbotConfig.MaxDistance = value end)
        createToggleSwitch(sectionAimbot, "Desenhar FOV", AimbotConfig.DrawFOV, UDim2.new(0, 5, 0, 190), function(state) AimbotConfig.DrawFOV = state end)
        createToggleSwitch(sectionAimbot, "Desenhar Mira", AimbotConfig.DrawCrosshair, UDim2.new(0.5, -5, 0, 190), function(state) AimbotConfig.DrawCrosshair = state end)
        createToggleSwitch(sectionAimbot, "Info Alvo", AimbotConfig.DrawTargetInfo, UDim2.new(0, 5, 0, 225), function(state) AimbotConfig.DrawTargetInfo = state end)
        createDropdown(sectionAimbot, "Tipo de Mira", {"Cross", "Dot", "Circle"}, AimbotConfig.CrosshairType, UDim2.new(0.5, -5, 0, 225), function(value) AimbotConfig.CrosshairType = value end)
        createSlider(sectionAimbot, "Tamanho Mira", 2, 20, AimbotConfig.CrosshairSize, UDim2.new(0, 5, 0, 260), function(value) AimbotConfig.CrosshairSize = value end)

        local sectionColors = createSection(scrollFrame, "Cores", currentY, 150)
        currentY = currentY + sectionColors.Size.Y.Offset + 10
        
        createColorPickerButton(sectionColors, "Cor FOV", AimbotConfig.FOVColor, UDim2.new(0, 5, 0, 30), function(newColor) AimbotConfig.FOVColor = newColor end)
        createColorPickerButton(sectionColors, "Cor Mira", AimbotConfig.CrosshairColor, UDim2.new(0.5, -5, 0, 30), function(newColor) AimbotConfig.CrosshairColor = newColor end)
        createColorPickerButton(sectionColors, "Cor Info", AimbotConfig.TargetInfoColor, UDim2.new(0, 5, 0, 65), function(newColor) AimbotConfig.TargetInfoColor = newColor end)

        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, currentY + 100)
    end

    if menuFrame then
        menuFrame.Visible = GUIConfig.MenuShow
        menuFrame.Position = UDim2.new(0, GUIConfig.MenuX, 0, GUIConfig.MenuY)
    end
end

createMenuUI()

menuToggleButton.MouseButton1Click:Connect(function()
    GUIConfig.MenuShow = not GUIConfig.MenuShow
    if menuFrame then
        menuFrame.Visible = GUIConfig.MenuShow
    end
    menuToggleButton.Text = GUIConfig.MenuShow and "Fechar Menu" or "Abrir Menu"
end)

-- ==================================================
-- == FUNÇÕES DO AIMBOT ==
-- ==================================================

local function getLocalPlayerInfo()
    local player = PlayersService.LocalPlayer
    if player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
        return player, player.Character
    end
    return nil, nil
end

local function getPlayerTeam(player)
    if player and player.Team then 
        return player.Team 
    end
    if player then
        for _, child in ipairs(player:GetChildren()) do
            if child:IsA("ObjectValue") and child.Name == "Team" then 
                return child.Value 
            end
            if child:IsA("StringValue") and child.Name == "Team" then 
                return child.Value 
            end
        end
    end
    return nil
end

local function getTargetPart(character, targetType)
    if not character then return nil end
    
    if targetType == "Head" then
        local head = character:FindFirstChild("Head")
        if head then return head end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name:lower():find("head") then 
                return part 
            end
        end
    elseif targetType == "Chest" then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                local nameLower = part.Name:lower()
                if nameLower:find("torso") or nameLower:find("chest") or nameLower:find("spine") then 
                    return part 
                end
            end
        end
    elseif targetType == "Legs" then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                local nameLower = part.Name:lower()
                if nameLower:find("leg") or nameLower:find("foot") then 
                    return part 
                end
            end
        end
    end
    
    return character:FindFirstChild("HumanoidRootPart")
end

local function findBestTarget()
    local bestTargetPart = nil
    local bestTargetPlayer = nil
    local closestScreenDist = math.huge
    local camera = workspace.CurrentCamera
    
    if not camera then return nil, nil, nil end
    
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local fovRadius = AimbotConfig.FOV * (camera.ViewportSize.X / 100)

    local player, character = getLocalPlayerInfo()
    if not player or not character then return nil, nil, nil end
    
    local localTeam = getPlayerTeam(player)

    for _, otherPlayer in ipairs(PlayersService:GetPlayers()) do
        if otherPlayer ~= player then
            local otherCharacter = otherPlayer.Character
            if otherCharacter and otherCharacter:FindFirstChild("Humanoid") and otherCharacter:FindFirstChild("HumanoidRootPart") then
                local otherTeam = getPlayerTeam(otherPlayer)

                if not AimbotConfig.IgnoreTeam or (localTeam ~= otherTeam or otherTeam == nil) then
                    local rootPart = otherCharacter:FindFirstChild("HumanoidRootPart")
                    if rootPart and (rootPart.Position - character.HumanoidRootPart.Position).Magnitude <= AimbotConfig.MaxDistance then
                        local targetPart = getTargetPart(otherCharacter, AimbotConfig.TargetType)
                        if targetPart then
                            local targetScreenPos = worldToScreen(targetPart.Position)
                            if targetScreenPos then
                                local distToCenter = (targetScreenPos - screenCenter).Magnitude
                                if distToCenter < fovRadius then
                                    if distToCenter < closestScreenDist then
                                        closestScreenDist = distToCenter
                                        bestTargetPart = targetPart
                                        bestTargetPlayer = otherPlayer
                                        CurrentTargetScreenPos = targetScreenPos
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTargetPart, bestTargetPlayer, CurrentTargetScreenPos
end

local function aimAt(targetPart, targetPlayer, targetScreenPos)
    local player, character = getLocalPlayerInfo()
    if not player or not character or not targetPart or not targetPart.Parent or not targetPart.Parent.Parent then 
        return 
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local targetPosition = targetPart.Position
    local characterPosition = character.HumanoidRootPart.Position
    local direction = (targetPosition - characterPosition).Unit
    local newCameraCFrame = CFrame.new(characterPosition, characterPosition + direction)

    if camera.CFrame then 
        camera.CFrame = newCameraCFrame
    elseif camera.CoordinateFrame then 
        camera.CoordinateFrame = newCameraCFrame 
    end

    CurrentTarget = targetPlayer
end

-- ==================================================
-- == LOOP PRINCIPAL E CONTROLE DE ENTRADA (MOBILE) ==
-- ==================================================

RunService.RenderStepped:Connect(function()
    if GUIConfig.MenuEnabled then
        if not mainGui then
            mainGui = Instance.new("ScreenGui")
            mainGui.Name = "MobileAimbot_GUI"
            mainGui.Enabled = true
            mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            mainGui.ResetOnSpawn = false
            mainGui.Parent = GuiService

            menuToggleButton = Instance.new("TextButton")
            menuToggleButton.Name = "MenuToggleButton"
            menuToggleButton.Size = GUIConfig.ButtonSize
            menuToggleButton.Position = UDim2.new(0, GUIConfig.ButtonX, 0, GUIConfig.ButtonY)
            menuToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
            menuToggleButton.Text = GUIConfig.MenuShow and "Fechar Menu" or "Abrir Menu"
            menuToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            menuToggleButton.Font = Enum.Font.SourceSansBold
            menuToggleButton.TextScaled = true
            menuToggleButton.Parent = mainGui

            menuToggleButton.MouseButton1Click:Connect(function()
                GUIConfig.MenuShow = not GUIConfig.MenuShow
                if menuFrame then menuFrame.Visible = GUIConfig.MenuShow end
                menuToggleButton.Text = GUIConfig.MenuShow and "Fechar Menu" or "Abrir Menu"
            end)
        end
        
        menuToggleButton.Visible = true
        menuToggleButton.Position = UDim2.new(0, GUIConfig.ButtonX, 0, GUIConfig.ButtonY)

        createMenuUI()

        if menuFrame then
            menuFrame.Visible = GUIConfig.MenuShow
            menuFrame.Position = UDim2.new(0, GUIConfig.MenuX, 0, GUIConfig.MenuY)
        end
    else
        if menuToggleButton then menuToggleButton.Visible = false end
        if menuFrame then menuFrame.Visible = false end
    end

    local player, character = getLocalPlayerInfo()
    if not player or not character then
        IsAimKeyPressed = false
        AimbotConfig.Enabled = false
        CurrentTarget = nil
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local currentAimKeyPressed = UserInputService:IsKeyDown(AimbotConfig.AimKey)
    if AimbotConfig.AimKeyMode == "Hold" then
        IsAimKeyPressed = currentAimKeyPressed
    elseif AimbotConfig.AimKeyMode == "Toggle" then
        if currentAimKeyPressed and not IsAimKeyPressed then
            AimToggleState = not AimToggleState
            AimbotConfig.Enabled = AimToggleState
        end
        IsAimKeyPressed = currentAimKeyPressed
    end

    if AimbotConfig.Enabled and IsAimKeyPressed then
        local targetPart, targetPlayer, targetScreenPos = findBestTarget()
        if targetPart then
            aimAt(targetPart, targetPlayer, targetScreenPos)
        else
            CurrentTarget = nil
        end
    else
        CurrentTarget = nil
    end

    if camera then
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

        if AimbotConfig.DrawFOV then
            Draw.Line(Vector2.new(screenCenter.X - AimbotConfig.FOV, screenCenter.Y), Vector2.new(screenCenter.X + AimbotConfig.FOV, screenCenter.Y), 2, AimbotConfig.FOVColor)
            Draw.Line(Vector2.new(screenCenter.X, screenCenter.Y - AimbotConfig.FOV), Vector2.new(screenCenter.X, screenCenter.Y + AimbotConfig.FOV), 2, AimbotConfig.FOVColor)
        end

        if AimbotConfig.DrawCrosshair then
            local size = AimbotConfig.CrosshairSize
            if AimbotConfig.CrosshairType == "Cross" then
                Draw.Line(Vector2.new(screenCenter.X - size, screenCenter.Y), Vector2.new(screenCenter.X + size, screenCenter.Y), 2, AimbotConfig.CrosshairColor)
                Draw.Line(Vector2.new(screenCenter.X, screenCenter.Y - size), Vector2.new(screenCenter.X, screenCenter.Y + size), 2, AimbotConfig.CrosshairColor)
            elseif AimbotConfig.CrosshairType == "Dot" then
                Draw.Box(Vector2.new(screenCenter.X - 1, screenCenter.Y - 1), Vector2.new(2, 2), 2, AimbotConfig.CrosshairColor)
            elseif AimbotConfig.CrosshairType == "Circle" then
                local radius = size
                local segments = 20
                for i = 0, segments do
                    local angle1 = (i / segments) * 2 * math.pi
                    local angle2 = ((i + 1) / segments) * 2 * math.pi
                    local x1 = screenCenter.X + radius * math.cos(angle1)
                    local y1 = screenCenter.Y + radius * math.sin(angle1)
                    local x2 = screenCenter.X + radius * math.cos(angle2)
                    local y2 = screenCenter.Y + radius * math.sin(angle2)
                    Draw.Line(Vector2.new(x1, y1), Vector2.new(x2, y2), 2, AimbotConfig.CrosshairColor)
                end
            end
        end

        if AimbotConfig.DrawTargetInfo and CurrentTarget then
            local targetScreenPos = CurrentTargetScreenPos
            if targetScreenPos then
                Draw.Text("ALVO: " .. CurrentTarget.Name, Enum.Font.SourceSansBold, 14, targetScreenPos, AimbotConfig.TargetInfoColor, true)
            end
        end
    end

    -- Arrastar o menu
    if IsDraggingMenu and menuFrame then
        local inputService = UserInputService
        local mouseLocation = inputService:GetMouseLocation()
        menuFrame.Position = UDim2.new(0, mouseLocation.X - DragOffset.X, 0, mouseLocation.Y - DragOffset.Y)
        GUIConfig.MenuX = menuFrame.Position.X.Offset
        GUIConfig.MenuY = menuFrame.Position.Y.Offset
    end
end)

print("✓ Aimbot script carregado com sucesso!")
