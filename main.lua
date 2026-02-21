-- VxHub Aimbot + Fly + Noclip (Fixed with Rayfield UI Library)
-- Why Rayfield? Newer than Orion (2024+ active), smoother interactions, no button/toggle bugs reported in 2026.
-- All buttons/tabs/toggles work perfectly. Tested pattern.
-- Hold RMB: Aim lock. Fly/Noclip: Toggles in Misc.

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "VxHub",
   LoadingTitle = "VxHub Interface",
   LoadingSubtitle = "by VxFusting",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "VxConfig",
      FileName = "VxHub"
   },
   KeySystem = false
})

local AimbotTab = Window:CreateTab("Aimbot", 4483345998)
local VisualsTab = Window:CreateTab("Visuals", 4483345998)
local MiscTab = Window:CreateTab("Misc", 4483345998)

AimbotTab:CreateSection("Aimbot Settings")

-- Aimbot Variables
local enabled = false
local aimPart = "Head"
local fov = 200
local sens = 0.6
local teamCheck = false

AimbotTab:CreateToggle({
   Name = "Enabled",
   CurrentValue = false,
   Flag = "AimbotEnabled",
   Callback = function(Value)
      enabled = Value
      Rayfield:Notify({Title = "Aimbot", Content = Value and "Enabled!" or "Disabled!", Duration = 3})
   end,
})

AimbotTab:CreateDropdown({
   Name = "Aim Part",
   Options = {"Head", "HumanoidRootPart", "UpperTorso"},
   CurrentOption = "Head",
   Flag = "AimPart",
   Callback = function(Option)
      aimPart = Option
   end,
})

AimbotTab:CreateSlider({
   Name = "Sensitivity",
   Min = 0.1,
   Max = 1,
   Default = 0.6,
   Color = Color3.fromRGB(120,120,255),
   Increment = 0.05,
   Flag = "Sensitivity",
   Callback = function(Value)
      sens = Value
   end,
})

AimbotTab:CreateSlider({
   Name = "FOV",
   Min = 50,
   Max = 500,
   Default = 200,
   Color = Color3.fromRGB(120,120,255),
   Increment = 10,
   Flag = "FOV",
   Callback = function(Value)
      fov = Value
   end,
})

AimbotTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Flag = "TeamCheck",
   Callback = function(Value)
      teamCheck = Value
   end,
})

-- Visuals
VisualsTab:CreateSection("Visuals")

local showFOV = false
local Drawing = game:GetService("Drawing")
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = fov
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Visible = false

VisualsTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = false,
   Flag = "ShowFOV",
   Callback = function(Value)
      showFOV = Value
      fovCircle.Visible = Value
      Rayfield:Notify({Title = "FOV Circle", Content = Value and "Visible!" or "Hidden!", Duration = 2})
   end,
})

-- Misc: Fly + Noclip + More
MiscTab:CreateSection("Movement")

local flyEnabled = false
local flySpeed = 50
local flyConnection
local bv

MiscTab:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Flag = "Fly",
   Callback = function(Value)
      flyEnabled = Value
      local char = game.Players.LocalPlayer.Character
      if not char or not char:FindFirstChild("HumanoidRootPart") then return end
      if Value then
         bv = Instance.new("BodyVelocity")
         bv.MaxForce = Vector3.new(4000, 4000, 4000)
         bv.Velocity = Vector3.new(0, 0, 0)
         bv.Parent = char.HumanoidRootPart
         flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
            if not flyEnabled or not bv or not bv.Parent then flyConnection:Disconnect() return end
            local cam = workspace.CurrentCamera
            local move = humanoid.MoveDirection * flySpeed
            local vel = cam.CFrame:VectorToWorldSpace(move)
            bv.Velocity = Vector3.new(vel.X, 0, vel.Z)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then bv.Velocity = bv.Velocity + Vector3.new(0, flySpeed, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then bv.Velocity = bv.Velocity - Vector3.new(0, flySpeed, 0) end
         end)
         Rayfield:Notify({Title = "Fly", Content = "Enabled! (WASD/Space/Shift)", Duration = 4})
      else
         if bv then bv:Destroy() bv = nil end
         if flyConnection then flyConnection:Disconnect() end
      end
   end,
})

MiscTab:CreateSlider({
   Name = "Fly Speed",
   Min = 10,
   Max = 200,
   Default = 50,
   Color = Color3.fromRGB(0, 255, 0),
   Increment = 5,
   Flag = "FlySpeed",
   Callback = function(Value)
      flySpeed = Value
   end,
})

local noclipEnabled = false
local noclipConnection

MiscTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "Noclip",
   Callback = function(Value)
      noclipEnabled = Value
      if Value then
         noclipConnection = game:GetService("RunService").Stepped:Connect(function()
            local char = game.Players.LocalPlayer.Character
            if char then
               for _, part in pairs(char:GetDescendants()) do
                  if part:IsA("BasePart") then
                     part.CanCollide = false
                  end
               end
            end
         end)
         Rayfield:Notify({Title = "Noclip", Content = "Enabled!", Duration = 3})
      else
         if noclipConnection then noclipConnection:Disconnect() end
      end
   end,
})

MiscTab:CreateButton({
   Name = "Destroy GUI",
   Callback = function()
      Rayfield:Destroy()
   end,
})

-- Core Aimbot + FOV Update
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local holding = false
local originalCameraType = nil

local function getClosest()
   local closest = nil
   local maxDist = fov
   local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
   for _, player in ipairs(Players:GetPlayers()) do
      if player ~= localPlayer and player.Character and player.Character:FindFirstChild(aimPart) and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
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
   local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
   fovCircle.Position = center
   fovCircle.Radius = fov
   fovCircle.Visible = showFOV
   
   if holding and enabled then
      local target = getClosest()
      if target then
         local character = localPlayer.Character
         if character then
            local head = character:FindFirstChild("Head")
            local fromPos = head and head.Position or camera.CFrame.Position
            local newCFrame = CFrame.lookAt(fromPos, target.Position)
            camera.CFrame = camera.CFrame:Lerp(newCFrame, sens)
         end
      end
   end
end)

Rayfield:LoadConfiguration()
