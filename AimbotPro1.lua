local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "ModernTemplate"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- ⚙️ CONFIGURAÇÕES
local Config = {
    AimbotAtivo = false,
    MiraAoTocar = true,
    MiraSempre = false,
    IgnorarEquipe = true,
    DistanciaMax = 1000,
    Suavidade = 5,
    FOV = 120
}

-- 📦 ÁREA DE CONTEÚDO
local content = Instance.new("Frame")
content.BackgroundTransparency = 1

-- 🎛️ SISTEMA DE CAMPO DE DIGITAÇÃO
local function CriarEntrada(nome, valorMin, valorMax, valorInicial, funcaoAplicar)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 38) -- Menor altura
    holder.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 7)

    local rotulo = Instance.new("TextLabel")
    rotulo.Size = UDim2.new(0, 110, 1, 0)
    rotulo.Position = UDim2.new(0, 8, 0, 0)
    rotulo.BackgroundTransparency = 1
    rotulo.Font = Enum.Font.Gotham
    rotulo.TextColor3 = Color3.new(1,1,1)
    rotulo.TextSize = 13
    rotulo.Text = nome
    rotulo.Parent = holder

    local entrada = Instance.new("TextBox")
    entrada.Size = UDim2.new(0, 65, 0, 24)
    entrada.Position = UDim2.new(0, 125, 0.5, -12)
    entrada.BackgroundColor3 = Color3.fromRGB(45,45,45)
    entrada.Font = Enum.Font.GothamBold
    entrada.TextColor3 = Color3.new(1,1,1)
    entrada.TextSize = 14
    entrada.Text = tostring(valorInicial)
    entrada.ClearTextOnFocus = false
    Instance.new("UICorner", entrada).CornerRadius = UDim.new(0,5)
    entrada.Parent = holder

    entrada.FocusLost:Connect(function()
        local numero = tonumber(entrada.Text)
        if numero then
            numero = math.floor(math.clamp(numero, valorMin, valorMax))
            entrada.Text = tostring(numero)
            funcaoAplicar(numero)
        else
            entrada.Text = tostring(valorInicial)
        end
    end)

    holder.Parent = content
end

-- 🎯 SISTEMA DE MIRA
local function PegarAlvoMaisProximo()
    if not player.Character then return nil end
    local centroTela = Camera.ViewportSize / 2
    local melhorAlvo, menorDistancia = nil, Config.FOV

    for _, jogador in pairs(Players:GetPlayers()) do
        if jogador == player then continue end
        if not jogador.Character then continue end
        local hum = jogador.Character:FindFirstChildWhichIsA("Humanoid")
        local cabeca = jogador.Character:FindFirstChild("Head")
        if not hum or not cabeca or hum.Health <= 0 then continue end
        if Config.IgnorarEquipe and jogador.Team == player.Team then continue end

        local distJogador = (cabeca.Position - Camera.CFrame.Position).Magnitude
        if distJogador > Config.DistanciaMax then continue end
        local posTela = Camera:WorldToScreenPoint(cabeca.Position)
        local distanciaNaTela = (Vector2.new(posTela.X, posTela.Y) - centroTela).Magnitude

        if distanciaNaTela < menorDistancia then
            menorDistancia = distanciaNaTela
            melhorAlvo = cabeca
        end
    end
    return melhorAlvo
end

-- ✅ LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    if not Config.AimbotAtivo then return end
    local estaTocando = #UIS:GetTouches() > 0
    local deveMirar = Config.MiraSempre or (Config.MiraAoTocar and estaTocando)
    if deveMirar then
        local alvo = PegarAlvoMaisProximo()
        if alvo then
            local novaDirecao = CFrame.new(Camera.CFrame.Position, alvo.Position)
            Camera.CFrame = Camera.CFrame:Lerp(novaDirecao, 1 / Config.Suavidade)
        end
    end
end)

--------------------------------------------------
-- INTERFACE REDUZIDA
--------------------------------------------------

local openButton = Instance.new("TextButton")
openButton.Parent = gui
openButton.Size = UDim2.fromOffset(45, 45) -- Menor botão de abrir
openButton.Position = UDim2.new(0, 12, 0.5, -22)
openButton.Text = "☰"
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 20
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", openButton).CornerRadius = UDim.new(1, 0)

local main = Instance.new("Frame")
main.Parent = gui
main.Size = UDim2.fromOffset(440, 355) -- Diminuído
main.Position = UDim2.new(0.5, -220, 0.5, -177)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Parent = main
stroke.Thickness = 2

local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue += dt * 0.15
    if hue > 1 then hue = 0 end
    stroke.Color = Color3.fromHSV(hue, 1, 1)
end)

local title = Instance.new("TextLabel")
title.Parent = main
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "MODERN UI TEMPLATE"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1, 1, 1)

local dragging = false
local dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local sidebar = Instance.new("Frame")
sidebar.Parent = main
sidebar.Position = UDim2.fromOffset(8, 40)
sidebar.Size = UDim2.fromOffset(110, 305) -- Menor barra lateral
sidebar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
Instance.new("UICorner", sidebar)

local layoutSide = Instance.new("UIListLayout")
layoutSide.Parent = sidebar
layoutSide.Padding = UDim.new(0, 5)

local function Tab(text)
    local btn = Instance.new("TextButton")
    btn.Parent = sidebar
    btn.Size = UDim2.new(1, -8, 0, 30)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Instance.new("UICorner", btn)
end

Tab("Visuals")
Tab("Jogador")
Tab("World")
Tab("Configurações")
Tab("Config")

content.Parent = main
content.Position = UDim2.fromOffset(128, 40)
content.Size = UDim2.fromOffset(300, 305)

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = content
listLayout.Padding = UDim.new(0, 8)

local function BotaoAlternar(nome, funcaoAcao)
    local holder = Instance.new("Frame")
    holder.Parent = content
    holder.Size = UDim2.new(1, 0, 0, 34) -- Menor altura
    holder.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Instance.new("UICorner", holder)

    local rotulo = Instance.new("TextLabel")
    rotulo.Parent = holder
    rotulo.Size = UDim2.new(0.7, 0, 1, 0)
    rotulo.BackgroundTransparency = 1
    rotulo.Text = nome
    rotulo.Font = Enum.Font.Gotham
    rotulo.TextColor3 = Color3.new(1, 1, 1)
    rotulo.TextSize = 14

    local botao = Instance.new("TextButton")
    botao.Parent = holder
    botao.Size = UDim2.fromOffset(50, 22)
    botao.Position = UDim2.new(1, -60, 0.5, -11)
    botao.Text = "OFF"
    botao.Font = Enum.Font.GothamBold
    botao.TextColor3 = Color3.new(1, 1, 1)
    botao.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
    Instance.new("UICorner", botao).CornerRadius = UDim.new(1, 0)

    local ativo = false
    botao.MouseButton1Click:Connect(function()
        ativo = not ativo
        botao.Text = ativo and "ON" or "OFF"
        TweenService:Create(botao, TweenInfo.new(0.2), {
            BackgroundColor3 = ativo and Color3.fromRGB(90, 180, 255) or Color3.fromRGB(170, 60, 60)
        }):Play()
        funcaoAcao(ativo)
    end)
end

-- ✅ ADICIONA CONFIGURAÇÕES
BotaoAlternar("Aimbot", function(v) Config.AimbotAtivo = v end)
BotaoAlternar("Mira ao tocar", function(v) Config.MiraAoTocar = v end)
BotaoAlternar("Mira sempre ligado", function(v) Config.MiraSempre = v end)
BotaoAlternar("Ignorar Equipe", function(v) Config.IgnorarEquipe = v end)

CriarEntrada("Distância Máx", 50, 3000, Config.DistanciaMax, function(v) Config.DistanciaMax = v end)
CriarEntrada("Suavidade", 1, 50, Config.Suavidade, function(v) Config.Suavidade = v end)
CriarEntrada("FOV", 20, 500, Config.FOV, function(v) Config.FOV = v end)

-- Abrir/fechar
local visivel = true
openButton.MouseButton1Click:Connect(function()
    visivel = not visivel
    if visivel then
        main.Visible = true
        TweenService:Create(main, TweenInfo.new(0.25), {Size = UDim2.fromOffset(440, 355)}):Play()
    else
        local animacao = TweenService:Create(main, TweenInfo.new(0.25), {Size = UDim2.fromOffset(0, 0)})
        animacao:Play()
        animacao.Completed:Wait()
        main.Visible = false
    end
end)
