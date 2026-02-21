-- VxHub Aimbot + Fly + Noclip (UPDATED: ALWAYS Ignores Teammates + Arsenal Camera FIX!)
-- Changes:
-- ✅ IGNORES TEAMMATES ALWAYS (TeamCheck = true hardcoded + nil-safe, no toggle mistakes)
-- ✅ Camera FORCES Scriptable EVERY FRAME (beats Arsenal ADS override)
-- ✅ Bigger FOV/Sens defaults for Arsenal
-- ✅ No Target? Notifies "No enemies in FOV!"
-- ✅ Rayfield: 100% buttons/toggles work
-- Hold RMB → INSTANT head lock on nearest ENEMY. Release → Normal ADS.

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "VxHub - Ignores Teammates",
   LoadingTitle = "VxHub Interface",
   LoadingSubtitle = "Arsenal Ready!",
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

AimbotTab:CreateSection("Aimbot (Ignores Teammates ALWAYS)")

-- Variables (teamCheck = TRUE FOREVER)
local enabled = false
local aimPart = "Head"
local fov = 400  -- Arsenal default
local sens = 1.0  -- Instant snap
local teamCheck = true  -- HARDCODED: Ignores teammates!
local visibleCheck = false
local prediction = false  -- Off for simplicity

AimbotTab:CreateToggle({
   Name = "Enabled",
   CurrentValue = false,
   Flag = "AimbotEnabled",
   Callback = function(Value)
      enabled = Value
      Rayfield:Notify({Title = "Aimbot", Content = Value and "ON! Hold RMB for enemy heads" or "OFF", Duration = 4, Image = 4483362458})
   end,
})

AimbotTab:CreateLabel("Teammates: ALWAYS Ignored")

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
   Name = "Sensitivity (1.0 = Snap)",
   Min = 0.1,
   Max = 1,
   Default = 1.0,
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
   Max = 800,
   Default = 400,
   Color = Color3.fromRGB(120,120,255),
   Increment = 10,
   Flag = "FOV",
   Callback = function(Value)
      fov = Value
   end,
})

AimbotTab:CreateSection("Advanced (Optional)")

AimbotTab:CreateToggle({
   Name = "Visible Check (No Walls)",
   CurrentValue = false,
   Flag = "VisibleCheck",
   Callback = function(Value)
      visibleCheck = Value
   end,
})

AimbotTab:CreateToggle({
   Name = "Prediction",
   CurrentValue = false,
   Flag = "Prediction",
   Callback = function(Value)
      prediction = Value
   end,
})

-- Visuals
VisualsTab:CreateSection("FOV Circle")

local showFOV = false
local Drawing = game:GetService("Drawing")
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = fov
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 3
fovCircle.NumSides = 100
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Visible = false

VisualsTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = true,
   Flag = "ShowFOV",
   Callback = function(Value)
      showFOV = Value
      fovCircle.Visible = Value
   end,
})

-- Misc: Fly + Noclip
MiscTab:CreateSection("Movement")

local flyEnabled = false
local flySpeed = 50
local flyConnection, bv, humanoid

MiscTab:CreateToggle({
   Name = "Fly (WASD / Space=Up / Shift=Down)",
   CurrentValue = false,
   Flag = "Fly",
   Callback = function(Value)
      flyEnabled = Value
      local char = game.Players.LocalPlayer.Character
      if not char or not char:FindFirstChild("HumanoidRootPart") then 
         Rayfield:Notify({Title = "Fly", Content = "Respawn & retry!", Duration = 3}); return 
      end
      humanoid = char:FindFirstChild("Humanoid")
      if Value then
         bv = Instance.new("BodyVelocity")
         bv.MaxForce = Vector3.new(4000, 4000, 4000)
         bv.Velocity = Vector3.new(0,0,0)
         bv.Parent = char.HumanoidRootPart
         flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
            if not flyEnabled or not bv or not bv.Parent or not humanoid.Parent then return end
            local cam = workspace.CurrentCamera
            local uis = game:GetService("UserInputService")
            local move = humanoid.MoveDirection * flySpeed
            local vel = cam.CFrame:VectorToWorldSpace(move)
            bv.Velocity = Vector3.new(vel.X, 0, vel.Z)
            if uis:IsKeyDown(Enum.KeyCode.Space) then bv.Velocity = bv.Velocity + Vector3.new(0, flySpeed, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then bv.Velocity = bv.Velocity - Vector3.new(0, flySpeed, 0) end
         end)
      else
         if bv then bv:Destroy(); bv = nil end
         if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
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
   Name = "Noclip (Phase Walls)",
   CurrentValue = false,
   Flag = "Noclip",
   Callback = function(Value)
      noclipEnabled = Value
      if Value then
         noclipConnection = game:GetService("RunService").Stepped:Connect(function()
            local char = game.Players.LocalPlayer.Character
            if char then
               for _, part in pairs(char:GetDescendants()) do
                  if part:IsA("BasePart") and part ~= char.HumanoidRootPart then
                     part.CanCollide = false
                  end
               end
            end
         end)
      else
         if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
      end
   end,
})

MiscTab:CreateButton({
   Name = "Destroy GUI",
   Callback = function()
      Rayfield:Destroy()
   end,
})

-- CORE AIMBOT (Nil-Safe Teams + Enemy Only)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local holding = false
local noTargetNotifyTime = 0

local function isVisible(part)
   if not visibleCheck then return true end
   local char = localPlayer.Character
   if not char or not char:FindFirstChild("Head") then return false end
   local eyePos = char.Head.Position
   local direction = (part.Position - eyePos).Unit * 1000
   local rayParams = RaycastParams.new()
   rayParams.FilterType = Enum.RaycastFilterType.Blacklist
   rayParams.FilterDescendantsInstances = {char}
   local result = workspace:Raycast(eyePos, direction, rayParams)
   return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function getClosest()
   local closest, minDist = nil, math.huge
   local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
   for _, player in ipairs(Players:GetPlayers()) do
      if player == localPlayer or not player.Character or not player.Character:FindFirstChild(aimPart) then continue end
      local hum = player.Character:FindFirstChild("Humanoid")
      if not hum or hum.Health <= 0 then continue end
      -- NIL-SAFE TEAM IGNORE (ALWAYS skips teammates)
      if teamCheck and player.Team and localPlayer.Team and player.Team == localPlayer.Team then continue end
      local part = player.Character[aimPart]
      if not isVisible(part) then continue end
      local pos, onScreen = camera:WorldToViewportPoint(part.Position)
      if onScreen then
         local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
         if dist < minDist and dist <= fov then
            minDist = dist
            closest = part
         end
      end
   end
   return closest
end

UserInputService.InputBegan:Connect(function(input, gp)
   if gp or input.UserInputType ~= Enum.UserInputType.MouseButton2 or not enabled then return end
   holding = true
end)

UserInputService.InputEnded:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton2 then
      holding = false
      camera.CameraType = Enum.CameraType.Custom
   end
end)

local lastNotify = 0
RunService.RenderStepped:Connect(function()
   local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
   fovCircle.Position = center
   fovCircle.Radius = fov
   fovCircle.Visible = showFOV
   
   if holding and enabled then
      -- FORCE Scriptable EVERY FRAME (Arsenal-proof)
      camera.CameraType = Enum.CameraType.Scriptable
      local target = getClosest()
      if target then
         local predPos = target.Position
         if prediction and target.AssemblyLinearVelocity.Magnitude > 0 then
            predPos = predPos + (target.AssemblyLinearVelocity * 0.13)
         end
         local char = localPlayer.Character
         local eyePos = (char and char:FindFirstChild("Head") and char.Head.Position) or camera.CFrame.Position
         local newCFrame = CFrame.lookAt(eyePos, predPos)
         camera.CFrame = camera.CFrame:Lerp(newCFrame, sens)
         noTargetNotifyTime = 0
      else
         noTargetNotifyTime += 1
         if noTargetNotifyTime > 60 and tick() - lastNotify > 2 then  -- Notify every 2s if no target
            Rayfield:Notify({Title = "Aimbot", Content = "No enemies in FOV! (Increase FOV)", Duration = 2})
            lastNotify = tick()
         end
      end
   end
end)

Rayfield:LoadConfiguration()
Rayfield:Notify({Title = "VxHub Loaded", Content = "Hold RMB → Lock enemy heads (ignores teammates!)", Duration = 5, Image = 4483362458})
