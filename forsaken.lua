-- ==================== 第 1 段：加载库 + 服务 + 体力模块 ====================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- 体力模块
local originalDefaults = {}
local SprintingModule = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Character"):WaitForChild("Game"):WaitForChild("Sprinting")
local function GetModule() return require(SprintingModule) end

local function CaptureDefaults()
    local m = GetModule()
    originalDefaults.MaxStamina = m.MaxStamina
    originalDefaults.StaminaGain = m.StaminaGain
    originalDefaults.StaminaLoss = m.StaminaLoss
    originalDefaults.SprintSpeed = m.SprintSpeed
end
CaptureDefaults()

local StaminaSettings = {
    MaxStamina = 100,
    StaminaGain = 25,
    StaminaLoss = 10,
    SprintSpeed = 28,
    InfiniteGain = 9999
}
local SettingToggles = {
    MaxStamina = false,
    StaminaGain = false,
    StaminaLoss = false,
    SprintSpeed = false
}
local bai = { Spr = false }
local staminaConn = nil

task.spawn(function()
    while true do
        local m = GetModule()
        for key, value in pairs(StaminaSettings) do
            if SettingToggles[key] then
                m[key] = value
            end
        end
        task.wait(0.5)
    end
end)-- ==================== 第 2 段：透视区 - 发电机 + 玩家 ESP 函数 ====================
local generatorsEnabled = false
local killersESPToggle = false
local survivorsESPToggle = false
local itemESPEnabled = false

local killersFolder = Workspace:WaitForChild("Players"):WaitForChild("Killers")
local survivorsFolder = Workspace:WaitForChild("Players"):WaitForChild("Survivors")

-- 发电机 ESP 循环
task.spawn(function()
    while task.wait(0.5) do
        if generatorsEnabled then
            pcall(function()
                local gameMap = workspace:FindFirstChild("Map")
                if gameMap and gameMap:FindFirstChild("Ingame") and gameMap.Ingame:FindFirstChild("Map") then
                    for _, v in pairs(gameMap.Ingame.Map:GetChildren()) do
                        if v.Name == "Generator" then
                            if not v:FindFirstChild("gen_esp") then
                                local hl = Instance.new("Highlight", v)
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Name = "gen_esp"
                                hl.OutlineTransparency = 0
                                hl.FillTransparency = 0.3
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillColor = Color3.fromRGB(255, 255, 51)
                            end
                            if v:FindFirstChild("gen_esp") and v:FindFirstChild("Progress") then
                                local progressValue = math.floor(v.Progress.Value)
                                v.gen_esp.FillColor = (progressValue >= 100) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 51)
                                if not v:FindFirstChild("nametag") then
                                    local bb = Instance.new("BillboardGui", v)
                                    bb.Size = UDim2.new(4, 0, 1, 0)
                                    bb.AlwaysOnTop = true
                                    bb.Name = "nametag"
                                    local text = Instance.new("TextLabel", bb)
                                    text.TextStrokeTransparency = 0
                                    text.Text = "发电机 (" .. progressValue .. "%)"
                                    text.TextSize = 15
                                    text.BackgroundTransparency = 1
                                    text.Size = UDim2.new(1, 0, 1, 0)
                                    text.TextColor3 = Color3.fromRGB(255, 255, 255)
                                else
                                    v.nametag.TextLabel.Text = "发电机 (" .. progressValue .. "%)"
                                end
                            end
                        end
                    end
                end
            end)
        else
            pcall(function()
                local gameMap = workspace:FindFirstChild("Map")
                if gameMap and gameMap:FindFirstChild("Ingame") and gameMap.Ingame:FindFirstChild("Map") then
                    for _, v in pairs(gameMap.Ingame.Map:GetChildren()) do
                        if v.Name == "Generator" then
                            if v:FindFirstChild("gen_esp") then v.gen_esp:Destroy() end
                            if v:FindFirstChild("nametag") then v.nametag:Destroy() end
                        end
                    end
                end
            end)
        end
    end
end)

-- 玩家 ESP：附着名字牌
local function attachBillboard(model, color)
    if model:FindFirstChild("ESP_NameBillboard") then return end
    local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_NameBillboard"
    billboard.Adornee = head
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.Parent = model
    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextScaled = false
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.Text = "加载中..."
    label.Parent = billboard
end

-- 更新名字牌文本
local function updateBillboardText(model)
    local billboard = model:FindFirstChild("ESP_NameBillboard")
    if not billboard then return end
    local label = billboard:FindFirstChild("NameLabel")
    if not label then return end
    local actorText = model:GetAttribute("ActorDisplayName") or "???"
    local skinText = model:GetAttribute("SkinNameDisplay")
    if actorText == "Noli" and model:GetAttribute("IsFakeNoli") == true then
        actorText = actorText .. " (假的)"
    end
    local displayText = actorText
    if skinText and tostring(skinText) ~= "" then
        displayText = displayText .. " | " .. skinText
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local hp = math.floor(humanoid.Health)
        local maxhp = math.floor(humanoid.MaxHealth)
        displayText = string.format("%s (生命值: %d/%d)", displayText, hp, maxhp)
    end
    label.Text = displayText
end-- ==================== 第 3 段：透视区 - 扫描 + 物品 ESP ====================
-- 为模型创建 ESP
local function setupModel(model, isKiller)
    if not model:IsA("Model") or not model:FindFirstChildOfClass("Humanoid") then return end
    local color = isKiller and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0)
    attachBillboard(model, color)
    updateBillboardText(model)
    if not model:FindFirstChild("ESP_Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
        highlight.OutlineColor = color
        highlight.Adornee = model
        highlight.Parent = model
    end
    model:GetAttributeChangedSignal("ActorDisplayName"):Connect(function() updateBillboardText(model) end)
    model:GetAttributeChangedSignal("SkinNameDisplay"):Connect(function() updateBillboardText(model) end)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:GetPropertyChangedSignal("Health"):Connect(function() updateBillboardText(model) end)
        humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function() updateBillboardText(model) end)
    end
end

-- 扫描文件夹
local function scanFolder(folder, isKiller)
    for _, model in ipairs(folder:GetChildren()) do
        setupModel(model, isKiller)
    end
end

task.spawn(function()
    while true do
        scanFolder(killersFolder, true)
        scanFolder(survivorsFolder, false)
        task.wait(5)
    end
end)

-- 新加入的模型
local function handleChildAdded(folder, isKiller)
    folder.ChildAdded:Connect(function(child)
        task.spawn(function()
            repeat task.wait() until child:IsDescendantOf(folder)
            local timeout = 3
            local timer = 0
            while (not child:FindFirstChild("Head") and not child:FindFirstChildWhichIsA("BasePart")) or not child:FindFirstChildOfClass("Humanoid") do
                task.wait(0.1)
                timer += 0.1
                if timer > timeout then return end
            end
            task.wait(0.2)
            setupModel(child, isKiller)
        end)
    end)
end
handleChildAdded(killersFolder, true)
handleChildAdded(survivorsFolder, false)

-- 实时开关名字牌
RunService.RenderStepped:Connect(function()
    for _, folderData in pairs({
        {folder = killersFolder, toggle = killersESPToggle},
        {folder = survivorsFolder, toggle = survivorsESPToggle},
    }) do
        for _, model in ipairs(folderData.folder:GetChildren()) do
            local bb = model:FindFirstChild("ESP_NameBillboard")
            local hl = model:FindFirstChild("ESP_Highlight")
            if bb then bb.Enabled = folderData.toggle end
            if hl then hl.Enabled = folderData.toggle end
        end
    end
end)

-- 物品 ESP
local colorByName = { BloxyCola = Color3.fromRGB(255, 140, 0), Medkit = Color3.fromRGB(255, 100, 255) }
local espParts = {}
local itemPartEspTrigger = nil

local function createNameTag(part, tagName, color)
    if part:FindFirstChild("ESP_Billboard") then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Parent = part
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0
    textLabel.Text = tagName
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 10
    textLabel.Parent = billboard
end

local function createBoxESP(part)
    if not part or not part:IsA("BasePart") then return end
    if part.Name ~= "ItemRoot" or not part.Parent then return end
    local tagName = part.Parent.Name
    local color = colorByName[tagName] or Color3.fromRGB(255, 255, 255)
    if part:FindFirstChild(tagName.."_PESP") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = tagName.."_PESP"
    box.Adornee = part
    box.Size = part.Size
    box.Transparency = 0.5
    box.Color3 = color
    box.ZIndex = 0
    box.AlwaysOnTop = true
    box.Parent = part
    createNameTag(part, tagName, color)
    table.insert(espParts, tagName)
end

local function enableItemESP()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "ItemRoot" then createBoxESP(v) end
    end
    if not itemPartEspTrigger then
        itemPartEspTrigger = workspace.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") and part.Name == "ItemRoot" then createBoxESP(part) end
        end)
    end
end

local function disableItemESP()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "ItemRoot" then
            if v:FindFirstChild("ESP_Billboard") then v:FindFirstChild("ESP_Billboard"):Destroy() end
            local tagName = v.Parent and v.Parent.Name
            if tagName and v:FindFirstChild(tagName.."_PESP") then v:FindFirstChild(tagName.."_PESP"):Destroy() end
        end
    end
    espParts = {}
    if itemPartEspTrigger then itemPartEspTrigger:Disconnect(); itemPartEspTrigger = nil end
end-- ==================== 第 4 段：修电箱 - Flow 辅助函数 ====================
local vu2 = { autoRepairActive = false }
local vu4 = { repairCheckInterval = 1.5 }

local flow = { on = false, nodeDelay = 0, lineDelay = 0.4 }

local function flowKey(n) return n.row.."-"..n.col end

local function flowNeighbour(r1,c1,r2,c2)
    if r2==r1-1 and c2==c1 then return"up" end
    if r2==r1+1 and c2==c1 then return"down" end
    if r2==r1 and c2==c1-1 then return"left" end
    if r2==r1 and c2==c1+1 then return"right" end
    return false
end

local function flowOrder(path, endpoints)
    if not path or #path == 0 then return path end
    local lookup = {}
    for _, n in ipairs(path) do lookup[flowKey(n)] = n end
    local start
    for _, ep in ipairs(endpoints or {}) do
        for _, n in ipairs(path) do
            if n.row == ep.row and n.col == ep.col then start = { row = ep.row, col = ep.col }; break end
        end
        if start then break end
    end
    if not start then
        for _, n in ipairs(path) do
            local nb = 0
            for _, d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
                if lookup[(n.row+d[1]).."-"..(n.col+d[2])] then nb = nb + 1 end
            end
            if nb == 1 then start = { row = n.row, col = n.col }; break end
        end
    end
    if not start then start = { row = path[1].row, col = path[1].col } end
    local pool, ordered = {}, {}
    for _, n in ipairs(path) do pool[flowKey(n)] = { row = n.row, col = n.col } end
    local cur = start
    table.insert(ordered, { row = cur.row, col = cur.col })
    pool[flowKey(cur)] = nil
    while next(pool) do
        local moved = false
        for k, node in pairs(pool) do
            if flowNeighbour(cur.row, cur.col, node.row, node.col) then
                table.insert(ordered, { row = node.row, col = node.col })
                pool[k] = nil; cur = node; moved = true; break
            end
        end
        if not moved then break end
    end
    return ordered
end

local function flowSolve(puzzle)
    if not puzzle or not puzzle.Solution then return end
    local indices = {}
    for i = 1, #puzzle.Solution do indices[i] = i end
    for i = #indices, 2, -1 do
        local j = math.random(1, i)
        indices[i], indices[j] = indices[j], indices[i]
    end
    for _, ci in ipairs(indices) do
        local solution = puzzle.Solution[ci]
        if not solution then continue end
        local ordered = flowOrder(solution, puzzle.targetPairs[ci])
        if not ordered or #ordered == 0 then continue end
        puzzle.paths[ci] = {}
        for _, node in ipairs(ordered) do
            table.insert(puzzle.paths[ci], { row = node.row, col = node.col })
            puzzle:updateGui()
            task.wait(flow.nodeDelay)
        end
        task.wait(flow.lineDelay)
        puzzle:checkForWin()
    end
end

local hooked = false
local function setupFlowHook()
    if hooked then return end
    local modFolder = ReplicatedStorage:FindFirstChild("Modules")
    local miniFolder = modFolder and modFolder:FindFirstChild("Minigames")
    local fgFolder = miniFolder and miniFolder:FindFirstChild("FlowGameManager")
    local fgModule = fgFolder and fgFolder:FindFirstChild("FlowGame")
    if fgModule then
        local ok, FG = pcall(require, fgModule)
        if ok and FG and FG.new then
            local orig = FG.new
            FG.new = function(...)
                local p = orig(...)
                if flow.on then
                    task.spawn(function() task.wait(0.3); flowSolve(p) end)
                end
                return p
            end
            hooked = true
        end
    end
end-- ==================== 第 5 段：修电箱 - 自动修机循环 ====================
local function findNearestGenerator()
    local character = LP.Character
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local generators = {}
    local map = workspace:FindFirstChild("Map")
    if map then
        local ingame = map:FindFirstChild("Ingame")
        if ingame then
            local mapFolder = ingame:FindFirstChild("Map")
            if mapFolder then
                for _, obj in pairs(mapFolder:GetChildren()) do
                    if obj.Name == "Generator" then table.insert(generators, obj) end
                end
            end
        end
    end
    local nearest, nearestDist = nil, math.huge
    for _, gen in pairs(generators) do
        local part = gen:FindFirstChildWhichIsA("BasePart")
        if part then
            local dist = (root.Position - part.Position).Magnitude
            if dist < nearestDist then nearest, nearestDist = gen, dist end
        end
    end
    return nearest
end

local function repairGenerator(generator)
    if not generator then return false end
    local remotes = generator:FindFirstChild("Remotes")
    if remotes then
        local re = remotes:FindFirstChild("RE")
        if re and re:IsA("RemoteEvent") then re:FireServer(); return true end
    end
    return false
end

spawn(function()
    while wait() do
        if vu2.autoRepairActive then
            local generator = findNearestGenerator()
            if generator then
                repairGenerator(generator)
                wait(vu4.repairCheckInterval)
            end
        end
        wait(0.1)
    end
end)-- ==================== 第 6 段：WindUI 界面（上）====================
WindUI:Popup({
    Title = "殺脚本 | 被遗弃",
    Content = "体力 / 透视 / 修电箱",
    Buttons = {{ Title = "进入", Callback = function() createMainWindow() end }}
})

function createMainWindow()
    local win = WindUI:CreateWindow({
        Title = "殺脚本 | 被遗弃",
        Author = "WindUI 版",
        Folder = "Forsaken",
        Size = UDim2.fromOffset(480, 700),
        Theme = "Dark",
        SideBarWidth = 180,
        ScrollBarEnabled = true,
    })
    win:Tag({ Title = "v1.0", Color = Color3.fromHex("#30ff6a") })
    win:EditOpenButton({ Title = "殺脚本", Draggable = true })

    -- ========== 体力区 ==========
    local tab1 = win:Tab({ Title = "体力区", Icon = "battery" })
    tab1:Paragraph({ Title = "体力管理", Desc = "兄弟原来你也和我一样是索尼克", Image = "battery-charging" })

    tab1:Toggle({
        Title = "无限体力", Default = false,
        Callback = function(state)
            bai.Spr = state
            local Sprinting = GetModule()
            if state then
                Sprinting.StaminaLoss = 0
                Sprinting.StaminaGain = StaminaSettings.InfiniteGain or 9999
                if staminaConn then staminaConn:Disconnect() end
                staminaConn = RunService.Heartbeat:Connect(function()
                    if not bai.Spr then return end
                    Sprinting.StaminaLoss = 0
                    Sprinting.StaminaGain = StaminaSettings.InfiniteGain or 9999
                end)
            else
                Sprinting.StaminaLoss = originalDefaults.StaminaLoss
                Sprinting.StaminaGain = originalDefaults.StaminaGain
                if staminaConn then staminaConn:Disconnect(); staminaConn = nil end
            end
        end
    })

    tab1:Toggle({
        Title = "启用体力大小", Default = false,
        Callback = function(v)
            SettingToggles.MaxStamina = v
            if not v then GetModule().MaxStamina = originalDefaults.MaxStamina end
        end
    })
    tab1:Slider({ Title = "体力大小", Value = { Min = 0, Max = 99999, Default = 100 },
        Callback = function(v) StaminaSettings.MaxStamina = v end })

    tab1:Toggle({
        Title = "启用体力恢复", Default = false,
        Callback = function(v)
            SettingToggles.StaminaGain = v
            if not v then GetModule().StaminaGain = originalDefaults.StaminaGain end
        end
    })
    tab1:Slider({ Title = "体力恢复", Value = { Min = 0, Max = 250, Default = 25 },
        Callback = function(v) StaminaSettings.StaminaGain = v end })

    tab1:Toggle({
        Title = "启用体力消耗", Default = false,
        Callback = function(v)
            SettingToggles.StaminaLoss = v
            if not v then GetModule().StaminaLoss = originalDefaults.StaminaLoss end
        end
    })
    tab1:Slider({ Title = "体力消耗", Value = { Min = 0, Max = 100, Default = 10 },
        Callback = function(v) StaminaSettings.StaminaLoss = v end })

    tab1:Toggle({
        Title = "启用奔跑速度", Default = false,
        Callback = function(v)
            SettingToggles.SprintSpeed = v
            if not v then GetModule().SprintSpeed = originalDefaults.SprintSpeed end
        end
    })
    tab1:Slider({ Title = "奔跑速度", Value = { Min = 0, Max = 200, Default = 28 },
        Callback = function(v) StaminaSettings.SprintSpeed = v end })-- ==================== 第 7 段：WindUI 界面（下）====================
    -- ========== 透视区 ==========
    local tab2 = win:Tab({ Title = "透视区", Icon = "eye" })
    tab2:Paragraph({ Title = "ESP透视", Desc = "高亮模式", Image = "eye" })

    tab2:Toggle({ Title = "发电机 ESP", Default = false,
        Callback = function(bool) generatorsEnabled = bool end })
    tab2:Toggle({ Title = "杀手 ESP", Default = false,
        Callback = function(v) killersESPToggle = v end })
    tab2:Toggle({ Title = "幸存者 ESP", Default = false,
        Callback = function(v) survivorsESPToggle = v end })
    tab2:Toggle({ Title = "物品 ESP", Default = false,
        Callback = function(v)
            itemESPEnabled = v
            if itemESPEnabled then enableItemESP() else disableItemESP() end
        end })

    -- ========== 修电箱 ==========
    local tab3 = win:Tab({ Title = "修电箱", Icon = "wrench" })
    tab3:Paragraph({ Title = "发电机系统", Desc = "里程碑的开始", Image = "battery-charging" })

    tab3:Toggle({ Title = "绘制修机", Default = false,
        Callback = function(on)
            flow.on = on
            if on and not hooked then setupFlowHook() end
        end })
    tab3:Slider({ Title = "节点速度 (秒)", Value = { Min = 0, Max = 1, Default = 0 },
        Callback = function(v) flow.nodeDelay = v end })
    tab3:Slider({ Title = "线暂停 (秒)", Value = { Min = 0, Max = 1, Default = 0.4 },
        Callback = function(v) flow.lineDelay = v end })
    tab3:Divider()

    tab3:Toggle({ Title = "自动修复发电机", Default = false,
        Callback = function(value) vu2.autoRepairActive = value end })

    tab3:Button({ Title = "完成所有发电机",
        Callback = function()
            pcall(function()
                local gameMap = workspace:FindFirstChild("Map")
                if not (gameMap and gameMap:FindFirstChild("Ingame") and gameMap.Ingame:FindFirstChild("Map")) then return end
                for _, v in ipairs(gameMap.Ingame.Map:GetChildren()) do
                    if v.Name == "Generator" and v:FindFirstChild("Progress") and v.Progress.Value < 100 then
                        local positions = v:FindFirstChild("Positions")
                        if positions then
                            local center = positions:FindFirstChild("Center")
                            local right = positions:FindFirstChild("Right")
                            local left = positions:FindFirstChild("Left")
                            if center and right and left then
                                local function occupied(pos)
                                    local folder = workspace:FindFirstChild("Players")
                                    local survivors = folder and folder:FindFirstChild("Survivors")
                                    if not survivors then return false end
                                    for _, sv in ipairs(survivors:GetChildren()) do
                                        if sv ~= LP and sv:FindFirstChild("HumanoidRootPart") then
                                            if (sv.HumanoidRootPart.Position - pos).Magnitude <= 6 then return true end
                                        end
                                    end
                                    return false
                                end
                                local cO = occupied(center.Position)
                                local rO = occupied(right.Position)
                                local lO = occupied(left.Position)
                                if not (cO and rO and lO) then
                                    local char = LP.Character
                                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        if not cO then hrp.CFrame = center.CFrame
                                        elseif not rO then hrp.CFrame = right.CFrame
                                        else hrp.CFrame = left.CFrame end
                                    end
                                    task.wait(0.2)
                                    local s2, r2 = pcall(function() return v.Remotes.RF:InvokeServer("Enter") end)
                                    if s2 and r2 == "fixing" then
                                        for _ = 1, 4 do
                                            if v.Progress.Value >= 100 then break end
                                            pcall(function() v.Remotes.RE:FireServer() end)
                                            task.wait(1.4)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end })
end

print("✅ 殺脚本 WindUI 版已加载（体力区 / 透视区 / 修电箱）")
