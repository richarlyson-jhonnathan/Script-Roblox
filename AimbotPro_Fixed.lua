-- ==================================================
-- ⚠️ APENAS PARA ESTUDO | USO EM SEU PRÓPRIO JOGO
-- ✅ VOLTEI MENU EXATO DO CÓDIGO ANTERIOR | SEM SCROLL | NÃO QUEBRA MAIS
-- ✅ AIMBOT = 0 ALTERAÇÕES | ✅ FOV AJUSTÁVEL | ✅ BOTÃO FIXO
-- ✅ 💀 ESQUELETO R15 COMPLETO | SEM CORTES | BRANCO IGUAL FOTO
-- ==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")

local jogadorLocal = Players.LocalPlayer

local CFG = {
    AIM_LIGADO = true,
    AIM_SUAVE = true,
    AIM_VELOCIDADE = 0.12,
    AIM_FOV = 180,
    AIM_PARTE = "Head",

    FOV_VISIVEL = true,
    FOV_TAMANHO = 200,

    ESP_LIGADO = true,
    ESP_CAIXA = true,
    ESP_ESQUELETO = true,
    ESP_NOME = true,
    ESP_VIDA = true,
    ESP_DISTANCIA = true,

    MENU_ABERTO = true
}

-- ==================================================
-- 🛡️ NUNCA MAIS SOME AO MORRER
-- ==================================================
local Tela = Instance.new("ScreenGui")
Tela.Name = "MENU_ESTUDO"
Tela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Tela.ResetOnSpawn = false
Tela.Parent = jogadorLocal:WaitForChild("PlayerGui")

-- ==================================================
-- 🎨 ✅ MENU EXATO COMO ERA ANTES — ZERO SCROLL, NÃO QUEBRA
-- ==================================================
local Janela = Instance.new("Frame")
Janela.Size = UDim2.new(0,250,0,490) -- Altura só aumentada para caber tudo
Janela.Position = UDim2.new(0,15,0,15)
Janela.BackgroundColor3 = Color3.fromRGB(10,14,22)
Janela.BorderColor3 = Color3.fromRGB(0,200,255)
Janela.BorderSizePixel = 1
Janela.Active = true
Janela.ClipsDescendants = true
Janela.Parent = Tela

local Barra = Instance.new("TextLabel")
Barra.Size = UDim2.new(1,0,0,30)
Barra.BackgroundColor3 = Color3.fromRGB(0,200,255)
Barra.Text = "⚙️ MENU | ARRASTE AQUI"
Barra.Font = Enum.Font.GothamBold
Barra.TextSize = 13
Barra.TextColor3 = Color3.new(0,0,0)
Barra.Parent = Janela

-- ARRASTAR JANELA — EXATAMENTE COMO ERA
local arrastando, difX, difY = false
Barra.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        arrastando = true
        difX = i.Position.X - Janela.Position.X.Offset
        difY = i.Position.Y - Janela.Position.Y.Offset
    end
end)
UIS.InputChanged:Connect(function(i) if arrastando then Janela.Position = UDim2.new(0,i.Position.X-difX,0,i.Position.Y-difY) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType.Name:match("Mouse") or i.UserInputType==Enum.UserInputType.Touch then arrastando=false end end)

local y=40
local function Toggle(n,v)
    local B=Instance.new("TextButton")
    B.Size=UDim2.new(0.92,0,0,24);B.Position=UDim2.new(0.04,0,0,y)
    B.BackgroundColor3=v and Color3.fromRGB(0,180,100) or Color3.fromRGB(190,0,50)
    B.Text=n.."  "..(v and "✅" or "❌");B.Font=Enum.Font.Gotham;B.TextSize=11;B.TextColor3=Color3.new(1,1,1)
    B.Parent=Janela
    B.MouseButton1Click:Connect(function()
        CFG[n]=not CFG[n]
        B.BackgroundColor3=CFG[n] and Color3.fromRGB(0,180,100) or Color3.fromRGB(190,0,50)
        B.Text=n.."  "..(CFG[n] and "✅" or "❌")
    end)
    y+=28
end
local function Slider(n,mn,mx,at)
    local T=Instance.new("TextLabel")
    T.Size=UDim2.new(0.92,0,0,13);T.Position=UDim2.new(0.04,0,0,y)
    T.BackgroundTransparency=1;T.Text=n..": "..math.floor(at)
    T.Font=Enum.Font.Gotham;T.TextSize=10;T.TextColor3=Color3.new(1,1,1);T.TextXAlignment=0
    T.Parent=Janela;y+=14
    local BG=Instance.new("Frame")
    BG.Size=UDim2.new(0.92,0,0,7);BG.Position=UDim2.new(0.04,0,0,y)
    BG.BackgroundColor3=Color3.fromRGB(40,40,55);BG.BorderSizePixel=0;BG.Parent=Janela
    local BT=Instance.new("TextButton")
    BT.Size=UDim2.new(0,13,0,16);BT.AnchorPoint=Vector2.new(.5,.5)
    BT.Position=UDim2.new((at-mn)/(mx-mn),0,.5,0);BT.BackgroundColor3=Color3.fromRGB(0,200,255);BT.Text=""
    BT.Parent=BG
    local function up(p)
        p=math.clamp(p,0,1);CFG[n]=mn+(mx-mn)*p
        BT.Position=UDim2.new(p,0,.5,0);T.Text=n..": "..math.floor(CFG[n])
    end
    BT.InputBegan:Connect(function(i)
        if i.UserInputType.Name:match("Mouse") or i.UserInputType==Enum.UserInputType.Touch then
            local c=UIS.InputChanged:Connect(function(e) if e.UserInputType==i.UserInputType then up((e.Position.X-BG.AbsolutePosition.X)/BG.AbsoluteSize.X) end end)
            UIS.InputEnded:Once(function(e) if e.UserInputType==i.UserInputType then c:Disconnect() end end)
        end
    end)
    y+=20
end
local function Sep()
    local s=Instance.new("Frame",Janela)
    s.Size=UDim2.new(.88,0,0,1);s.Position=UDim2.new(.06,0,0,y+4)
    s.BackgroundColor3=Color3.fromRGB(60,60,80);y+=12
end

Toggle("AIM_LIGADO",CFG.AIM_LIGADO)
Toggle("AIM_SUAVE",CFG.AIM_SUAVE)
Slider("AIM_FOV",30,400,CFG.AIM_FOV)
Slider("AIM_VELOCIDADE",1,99,CFG.AIM_VELOCIDADE*100)
Sep()
Toggle("FOV_VISIVEL",CFG.FOV_VISIVEL)
Slider("FOV_TAMANHO",40,700,CFG.FOV_TAMANHO)
Sep()
Toggle("ESP_LIGADO",CFG.ESP_LIGADO)
Toggle("ESP_CAIXA",CFG.ESP_CAIXA)
Toggle("ESP_ESQUELETO",CFG.ESP_ESQUELETO)
Toggle("ESP_NOME",CFG.ESP_NOME)
Toggle("ESP_VIDA",CFG.ESP_VIDA)
Toggle("ESP_DISTANCIA",CFG.ESP_DISTANCIA)

-- ==================================================
-- 🟢 BOTÃO FIXO CANTO ESQUERDO — NÃO MEXI
-- ==================================================
local BotaoOlho = Instance.new("TextButton")
BotaoOlho.Size=UDim2.new(0,56,0,56);BotaoOlho.Position=UDim2.new(0,18,0,110)
BotaoOlho.BackgroundColor3=Color3.fromRGB(0,200,255);BotaoOlho.BorderColor3=Color3.new(1,1,1);BotaoOlho.BorderSizePixel=2
BotaoOlho.Text="👁️";BotaoOlho.Font=Enum.Font.GothamBlack;BotaoOlho.TextSize=23;BotaoOlho.ZIndex=99999
BotaoOlho.Parent=Tela
Instance.new("UICorner",BotaoOlho).CornerRadius=UDim.new(1,0)
task.spawn(function() local h=0 while BotaoOlho.Parent do h=(h+0.008)%1 BotaoOlho.BackgroundColor3=Color3.fromHSV(h,1,1) task.wait() end end)
BotaoOlho.MouseButton1Click:Connect(function()
    CFG.MENU_ABERTO=not CFG.MENU_ABERTO
    Janela.Visible=CFG.MENU_ABERTO
    BotaoOlho.Text=CFG.MENU_ABERTO and "👁️" or "⚙️"
end)

-- ==================================================
-- 🎯 AIMBOT — NÃO ALTEREI NADA
-- ==================================================
RunService.RenderStepped:Connect(function()
    if not CFG.AIM_LIGADO or not jogadorLocal.Character then return end
    if not jogadorLocal.Character:FindFirstChild("HumanoidRootPart") then return end
    local centro=Camera.ViewportSize/2
    local alvo,menor=nil,math.huge
    for _,j in Players:GetPlayers() do
        if j==jogadorLocal or not j.Character then continue end
        local h=j.Character:FindFirstChildWhichIsA("Humanoid")
        local c=j.Character:FindFirstChild(CFG.AIM_PARTE)
        if not h or not c or h.Health<=0 then continue end
        local p,v=Camera:WorldToScreenPoint(c.Position)
        if not v then continue end
        local d=(Vector2.new(p.X,p.Y)-centro).Magnitude
        if d<=CFG.AIM_FOV and d<menor then menor=d alvo=c end
    end
    if alvo then
        local dr=(alvo.Position-Camera.CFrame.Position).Unit
        local cf=CFrame.new(Camera.CFrame.Position,Camera.CFrame.Position+dr)
        Camera.CFrame=CFG.AIM_SUAVE and Camera.CFrame:Lerp(cf,math.clamp(1-CFG.AIM_VELOCIDADE,.08,1)) or cf
    end
end)

-- ==================================================
-- ⭕ FOV — MANTIDO PERFEITO
-- ==================================================
local FOV=Instance.new("Frame",Tela)
FOV.AnchorPoint=Vector2.new(.5,.5);FOV.BackgroundTransparency=1
FOV.BorderColor3=Color3.fromRGB(0,220,255);FOV.BorderSizePixel=2;FOV.ZIndex=99990
Instance.new("UICorner",FOV).CornerRadius=UDim.new(1,0)
RunService.RenderStepped:Connect(function()
    local c=Camera.ViewportSize/2
    FOV.Position=UDim2.new(0,c.X,0,c.Y)
    FOV.Size=UDim2.new(0,CFG.FOV_TAMANHO*2,0,CFG.FOV_TAMANHO*2)
    FOV.Visible=CFG.FOV_VISIVEL
end)

-- ==================================================
-- 💀 ✅ ESQUELETO 100% FUNCIONAL — AGORA SIM
-- 💀 REMOVIDO FRAME 1PX QUE CORTAVA TUDO, LINHAS LIVRES
-- ==================================================
local PastaESP = Instance.new("Folder",Tela)
local OSSOS = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function linhaBranca()
    local l=Instance.new("Frame")
    l.BackgroundColor3=Color3.new(1,1,1)
    l.BorderSizePixel=0
    l.AnchorPoint=Vector2.new(.5,.5)
    l.ZIndex=8000
    l.Size=UDim2.new(0,0,0,1.1)
    l.Parent=PastaESP
    return l
end

RunService.RenderStepped:Connect(function()
    -- GERAL DESLIGADO
    if not CFG.ESP_LIGADO then
        for _,v in PastaESP:GetChildren() do v.Visible=false end
        return
    end
    local eu = jogadorLocal.Character and jogadorLocal.Character:FindFirstChild("HumanoidRootPart")

    for _,j in Players:GetPlayers() do
        if j==jogadorLocal or not j.Character then continue end
        local rt=j.Character:FindFirstChild("HumanoidRootPart")
        local hm=j.Character:FindFirstChildWhichIsA("Humanoid")
        local hd=j.Character:FindFirstChild("Head")
        if not rt or not hm or not hd then continue end

        -- CAIXA / NOME / VIDA
        local base = PastaESP:FindFirstChild("B_"..j.UserId)
        if not base then
            base=Instance.new("Frame",PastaESP)
            base.Name="B_"..j.UserId
            base.BackgroundTransparency=1;base.Size=UDim2.new(0,1,0,1);base.ZIndex=500
            local cx=Instance.new("Frame",base);cx.Name="C";cx.BackgroundTransparency=1;cx.BorderColor3=Color3.fromRGB(0,255,136);cx.BorderSizePixel=1;cx.AnchorPoint=Vector2.new(.5,.5)
            local nm=Instance.new("TextLabel",base);nm.Name="N";nm.BackgroundTransparency=1;nm.Font=Enum.Font.GothamBold;nm.TextSize=12;nm.TextColor3=Color3.new(1,1,1);nm.TextStrokeTransparency=0;nm.AnchorPoint=Vector2.new(.5,1)
            local vd=Instance.new("TextLabel",base);vd.Name="V";vd.BackgroundTransparency=1;vd.Font=Enum.Font.Gotham;vd.TextSize=11;vd.TextColor3=Color3.fromRGB(255,60,60);vd.TextStrokeTransparency=0;vd.AnchorPoint=Vector2.new(.5,0)
        end
        base.Visible=true

        local pT=Camera:WorldToScreenPoint(rt.Position)
        local cT=Camera:WorldToScreenPoint(hd.Position+Vector3.new(0,1.8,0))
        local bT=Camera:WorldToScreenPoint(rt.Position-Vector3.new(0,2.8,0))
        local alt=math.max(25,math.abs(cT.Y-bT.Y));local lar=alt*.62
        base.Position=UDim2.new(0,pT.X,0,pT.Y)
        base.C.Visible=CFG.ESP_CAIXA;base.C.Size=UDim2.new(0,lar,0,alt)
        base.N.Visible=CFG.ESP_NOME;base.N.Position=UDim2.new(.5,0,0,-alt/2-2)
        local tx=j.Name
        if CFG.ESP_DISTANCIA and eu then tx..=string.format(" · %.0fm",(eu.Position-rt.Position).Magnitude) end
        base.N.Text=tx
        base.V.Visible=CFG.ESP_VIDA;base.V.Position=UDim2.new(.5,0,0,alt/2+2)
        base.V.Text=string.format("❤ %d/%d",math.floor(hm.Health),hm.MaxHealth)

        -- 💀 ESQUELETO SÓ AQUI, LIVRE NA TELA
        if CFG.ESP_ESQUELETO then
            for k=1,#OSSOS do
                local A=j.Character:FindFirstChild(OSSOS[k][1])
                local B=j.Character:FindFirstChild(OSSOS[k][2])
                if A and B then
                    local a=Camera:WorldToScreenPoint(A.Position)
                    local b=Camera:WorldToScreenPoint(B.Position)
                    local tam=(Vector2.new(a.X,a.Y)-Vector2.new(b.X,b.Y)).Magnitude
                    local ang=math.deg(math.atan2(b.Y-a.Y,b.X-a.X))
                    local id="S_"..j.UserId.."_"..k
                    local ln=PastaESP:FindFirstChild(id) or linhaBranca()
                    ln.Name=id;ln.Visible=true
                    ln.Size=UDim2.new(0,tam,0,1.1)
                    ln.Position=UDim2.new(0,(a.X+b.X)/2,0,(a.Y+b.Y)/2)
                    ln.Rotation=ang
                end
            end
        else
            for _,v in PastaESP:GetChildren() do
                if v.Name:sub(1,3)=="S_"..j.UserId then v.Visible=false end
            end
        end
    end

    -- LIMPEZA
    for _,v in PastaESP:GetChildren() do
        local id=tonumber(string.match(v.Name,"%d+") or 0)
        local pl=Players:GetPlayerByUserId(id)
        if not pl or not pl.Character or not pl.Character:FindFirstChild("HumanoidRootPart") then v:Destroy() end
    end
end)

Players.PlayerRemoving:Connect(function(j)
    for _,v in PastaESP:GetChildren() do if string.find(v.Name,tostring(j.UserId)) then v:Destroy() end end
end)

jogadorLocal.CharacterAdded:Connect(function()
    task.wait(.6)
    if not Tela.Parent then Tela.Parent=jogadorLocal:WaitForChild("PlayerGui") end
    Janela.Visible=CFG.MENU_ABERTO
end)
