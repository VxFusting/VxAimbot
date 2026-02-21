-- Simple Mouse Aimlock + Box ESP (concept / educational use only)
-- Hold Right Mouse Button → lock onto closest visible enemy head
-- Works in games like Arsenal / similar FPS (but detection risk is high in 2025–2026)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Basic Aimlock + ESP",
    LoadingTitle = "Mouse Aimlock",
    LoadingSubtitle = "Hold RMB to lock",
    ConfigurationSaving = { Enabled = false }
})

local Tab = Window:CreateTab("Main", 4483362458)

-- Settings
local Enabled        = false
local TeamCheck      = true
local WallCheck      = true
local AimPart        = "Head"
local Smoothness     = 0.14     -- 0.05 = very snappy, 0.30 = very smooth
local FOV            = 180
local Prediction     = 0.13     -- basic movement prediction

local ESP_Enabled    = false
local ESP_Color      = Color3.fromRGB(0, 255, 100)
local ESP_Thickness  = 1.5

-- Services
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInput      = game:GetService("UserInputService")
local Drawing        = game:GetService("Drawing")

local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()
local Camera         = workspace.CurrentCamera

local Aiming         = false

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness   = 2
fovCircle.NumSides    = 60
fovCircle.Radius      = FOV
fovCircle.Color       = Color3.fromRGB(220, 40, 40)
fovCircle.Filled      = false
fovCircle.Transparency = 0.85
fovCircle.Visible     = true
fovCircle.Position    = Vector2.new()

-- ESP Table
local ESP_Objects = {}

-- ────────────────────────────────────────
--   Core: Find closest visible enemy
-- ────────────────────────────────────────

local function isValidTarget(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    if TeamCheck then
        -- Arsenal-style team check (most common in 2025-2026 games)
        if player.Team == LocalPlayer.Team or player.TeamColor == LocalPlayer.TeamColor then
            return false
        end
    end
    
    return true
end

local function isVisible(targetPart)
    if not WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 5000
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character or game, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, rayParams)
    
    if result and result.Instance then
        -- If we hit the target directly → visible
        if result.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false -- something else blocked
    end
    
    return true -- no wall hit
end

local function getClosestEnemy()
    local closest = nil
    local closestDist = FOV + 1
    local mousePos = Vector2.new(Mouse.X, Mouse.Y + game:GetService("GuiService"):GetGuiInset().Y)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if not isValidTarget(player) then continue end
        
        local part = player.Character:FindFirstChild(AimPart)
        if not part then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        
        local screen2d = Vector2.new(screenPos.X, screenPos.Y)
        local distance = (screen2d - mousePos).Magnitude
        
        if distance < closestDist and isVisible(part) then
            closest = part
            closestDist = distance
        end
    end
    
    return closest
end

-- ────────────────────────────────────────
--   Mouse movement logic
-- ────────────────────────────────────────

UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aiming = true
    end
end)

UserInput.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aiming = false
    end
end)

RunService.RenderStepped:Connect(function(delta)
    -- Update FOV circle position (follows mouse)
    fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + game:GetService("GuiService"):GetGuiInset().Y)
    fovCircle.Radius = FOV
    
    if not Enabled or not Aiming then return end
    
    local targetPart = getClosestEnemy()
    if not targetPart then return end
    
    -- Very basic prediction (you can improve this a lot)
    local root = targetPart.Parent:FindFirstChild("HumanoidRootPart")
    local predictedPos = targetPart.Position
    if root and Prediction > 0 then
        predictedPos = predictedPos + (root.Velocity * Prediction)
    end
    
    local screenPos, visible = Camera:WorldToViewportPoint(predictedPos)
    if not visible then return end
    
    local current = Vector2.new(Mouse.X, Mouse.Y)
    local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
    
    local delta = (targetScreen - current) * Smoothness
    
    mousemoverel(delta.X, delta.Y)
end)

-- ────────────────────────────────────────
--   Very basic 2D Box ESP
-- ────────────────────────────────────────

local function createESP(player)
    if ESP_Objects[player] then return end
    
    local box = Drawing.new("Square")
    box.Thickness   = ESP_Thickness
    box.Filled      = false
    box.Transparency = 1
    box.Color       = ESP_Color
    box.Visible     = false
    
    local nameText = Drawing.new("Text")
    nameText.Size      = 13
    nameText.Center    = true
    nameText.Outline   = true
    nameText.Color     = ESP_Color
    nameText.Visible   = false
    
    ESP_Objects[player] = {Box = box, Name = nameText}
end

local function updateESP()
    if not ESP_Enabled then
        for _, obj in pairs(ESP_Objects) do
            obj.Box.Visible = false
            obj.Name.Visible = false
        end
        return
    end
    
    for player, drawings in pairs(ESP_Objects) do
        if not player or not player.Parent then
            drawings.Box:Remove()
            drawings.Name:Remove()
            ESP_Objects[player] = nil
            continue
        end
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            continue
        end
        
        local root = char.HumanoidRootPart
        local head = char.Head
        
        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            continue
        end
        
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
        local legPos  = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
        
        local height = math.abs(headPos.Y - legPos.Y)
        local width  = height * 0.55
        
        drawings.Box.Size     = Vector2.new(width, height)
        drawings.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
        drawings.Box.Visible  = true
        
        drawings.Name.Text    = string.format("%s [%.0f]", player.Name, (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
        drawings.Name.Position = Vector2.new(rootPos.X, rootPos.Y - height/2 - 16)
        drawings.Name.Visible = true
    end
end

-- Initialize ESP for existing & new players
for _, p in ipairs(Players:GetPlayers()) do
    createESP(p)
end
Players.PlayerAdded:Connect(createESP)

RunService.RenderStepped:Connect(updateESP)

-- ────────────────────────────────────────
--   UI Controls
-- ────────────────────────────────────────

Tab:CreateToggle({
    Name = "Aimlock Enabled (hold RMB)",
    CurrentValue = false,
    Callback = function(v)
        Enabled = v
        if not v then Aiming = false end
    end
})

Tab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) TeamCheck = v end
})

Tab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Callback = function(v) WallCheck = v end
})

Tab:CreateSlider({
    Name = "Smoothness",
    Range = {0.05, 0.40},
    Increment = 0.01,
    CurrentValue = 0.14,
    Callback = function(v) Smoothness = v end
})

Tab:CreateSlider({
    Name = "Field of View",
    Range = {60, 400},
    Increment = 10,
    CurrentValue = 180,
    Callback = function(v) FOV = v end
})

Tab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Callback = function(v) fovCircle.Visible = v end
})

Tab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = false,
    Callback = function(v) ESP_Enabled = v end
})

Tab:CreateLabel("Educational / testing use only.")
Tab:CreateLabel("Modern anticheats detect mouse movement patterns very quickly.")
