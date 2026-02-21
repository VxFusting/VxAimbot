local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "VxHub",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "VxConfig"
})

local AimbotTab = Window:MakeTab({
    Name = "Aimbot",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local VisualsTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local MiscTab = Window:MakeTab({
    Name = "Misc",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Aimbot Variables
local enabled = false
local aimPart = "Head"
local fov = 200
local sens = 0.6
local teamCheck = false

-- Aimbot Elements
AimbotTab:AddToggle({
    Name = "Enabled",
    Default = false,
    Callback = function(Value)
        enabled = Value
    end
})

AimbotTab:AddDropdown({
    Name = "Aim Part",
    Default = "Head",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    Callback = function(Value)
        aimPart = Value
    end
})

AimbotTab:AddSlider({
    Name = "Sensitivity",
    Min = 0.1,
    Max = 1,
    Default = 0.6,
    Increment = 0.05,
    ValueName = "",
    Callback = function(Value)
        sens = Value
    end
})

AimbotTab:AddSlider({
    Name = "FOV",
    Min = 50,
    Max = 500,
    Default = 200,
    Increment = 10,
    ValueName = "pixels",
    Callback = function(Value)
        fov = Value
    end
})

AimbotTab:AddToggle({
    Name = "Team Check",
    Default = false,
    Callback = function(Value)
        teamCheck = Value
    end
})

-- Visuals
local showFOV = false
local Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/RandomAdamYT/DarkHub/master/Loadstring"))() or game:GetService("Drawing") -- Fallback if no external
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Radius = fov
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 1
fovCircle.NumSides = 100
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)

VisualsTab:AddToggle({
    Name = "Show FOV Circle",
    Default = false,
    Callback = function(Value)
        showFOV = Value
        fovCircle.Visible = Value
    end
})

-- Misc
MiscTab:AddButton({
    Name = "Destroy GUI",
    Callback = function()
        OrionLib:Destroy()
    end
})

MiscTab:AddToggle({
    Name = "Example Toggle",
    Default = false,
    Callback = function(Value)
        print("Example Toggle:", Value)
    end
})

MiscTab:AddSlider({
    Name = "Example Slider",
    Min = 1,
    Max = 100,
    Default = 50,
    Callback = function(Value)
        print("Example Slider:", Value)
    end
})

-- Core Aimbot Logic
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local holding = false
local originalCameraType = nil

function getClosest()
    local closest = nil
    local maxDist = fov
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild(aimPart) and player.Character.Humanoid and player.Character.Humanoid.Health > 0 then
            if teamCheck and player.Team == localPlayer.Team then continue end
            local part = player.Character[aimPart]
            local pos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < maxDist then
                    maxDist = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 and enabled then
        holding = true
        originalCameraType = camera.CameraType
        camera.CameraType = Enum.CameraType.Scriptable
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = false
        if originalCameraType then
            camera.CameraType = originalCameraType
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if showFOV then
        fovCircle.Radius = fov
        fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    end
    if holding and enabled then
        local target = getClosest()
        if target then
            local character = localPlayer.Character
            if character then
                local head = character:FindFirstChild("Head")
                if head then
                    -- Set position to local head for first-person compatibility
                    local newCFrame = CFrame.lookAt(head.Position, target.Position)
                    camera.CFrame = camera.CFrame:Lerp(newCFrame, sens)
                else
                    -- Fallback to current position
                    local newCFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
                    camera.CFrame = camera.CFrame:Lerp(newCFrame, sens)
                end
            end
        end
    end
end)

OrionLib:Init()
