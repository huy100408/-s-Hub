-- Full Rayfield Script with All Features for "Steal a Brainrot"

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local flying = false
local flySpeed = 50
local flyVelocity

local function startFly()
    if flying then return end
    flying = true
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(1, 1, 1) * 1e5
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = HumanoidRootPart

    RunService:BindToRenderStep("Flying", Enum.RenderPriority.Character.Value + 1, function()
        local moveVec = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec += workspace.CurrentCamera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec -= workspace.CurrentCamera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec -= workspace.CurrentCamera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec += workspace.CurrentCamera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec -= Vector3.yAxis end
        flyVelocity.Velocity = moveVec.Unit * flySpeed
    end)
end

local function stopFly()
    flying = false
    if flyVelocity then flyVelocity:Destroy() end
    RunService:UnbindFromRenderStep("Flying")
end

local function toggleFly()
    if flying then stopFly() else startFly() end
end

-- Infinite Jump
local infJumpEnabled = false
UIS.JumpRequest:Connect(function()
    if infJumpEnabled then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Speed Boost
local speedBoost = 0
RunService.Heartbeat:Connect(function(dt)
    if speedBoost > 0 and Humanoid.MoveDirection.Magnitude > 0 then
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + Humanoid.MoveDirection * speedBoost
    end
end)

-- Anti Ragdoll
LocalPlayer.CharacterAdded:Connect(function(char)
    if char:FindFirstChild("Ragdoll") then
        char.Ragdoll:Destroy()
    end
end)

-- GUI Init
local Window = Rayfield:CreateWindow({
   Name = "🧠 Steal A Brainrot | Hub",
   LoadingTitle = "Loading Washedz...",
   LoadingSubtitle = "by Huy",
   ConfigurationSaving = {
      Enabled = false
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(val)
        if val then startFly() else stopFly() end
    end
})

MainTab:CreateSlider({
    Name = "Speed Boost",
    Range = {0, 10},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(val)
        speedBoost = val
    end
})

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(val)
        infJumpEnabled = val
    end
})

MainTab:CreateButton({
    Name = "Teleport to Base",
    Callback = function()
        for _, plot in pairs(workspace.Plots:GetChildren()) do
            if plot:FindFirstChild("YourBase", true) and plot.YourBase.Enabled then
                HumanoidRootPart.CFrame = plot:FindFirstChild("SpawnLocation") and plot.SpawnLocation.CFrame or plot.CFrame
                break
            end
        end
    end
})

MainTab:CreateButton({
    Name = "Auto Sell",
    Callback = function()
        local sellPart = workspace:FindFirstChild("Sell")
        if sellPart then
            HumanoidRootPart.CFrame = sellPart.CFrame
        end
    end
})

MainTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

MainTab:CreateButton({
    Name = "Run Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end
})

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    game:GetService('VirtualUser'):CaptureController()
    game:GetService('VirtualUser'):ClickButton2(Vector2.new())
end)

-- Finish
Rayfield:Notify({
    Title = "🧠 Loaded",
    Content = "All features loaded. Enjoy!",
    Duration = 5
})

-- Additional Features Section --

local autoStealEnabled = false
local autoLockBaseEnabled = false
local noclipEnabled = false
local noclipConnection

-- Auto Steal
spawn(function()
    while true do
        wait(1)
        if autoStealEnabled then
            -- Assuming "Steal" is a remote event or a part to interact with
            local stealPart = workspace:FindFirstChild("StealPart") -- Change to actual steal part name
            if stealPart and (HumanoidRootPart.Position - stealPart.Position).Magnitude > 10 then
                HumanoidRootPart.CFrame = stealPart.CFrame + Vector3.new(0, 3, 0)
                wait(0.3)
            end
            -- Fire server event if exists to steal
            local stealEvent = game:GetService("ReplicatedStorage"):FindFirstChild("StealEvent")
            if stealEvent then
                stealEvent:FireServer()
            end
        else
            wait(1)
        end
    end
end)

-- Auto Lock Base
spawn(function()
    while true do
        wait(1)
        if autoLockBaseEnabled then
            -- Find the lock base part or remote event
            local base = workspace.Plots:FindFirstChild(LocalPlayer.Name)
            if base and base:FindFirstChild("Lock") then
                local lockPart = base.Lock
                -- Example: fire lock event
                local lockEvent = game:GetService("ReplicatedStorage"):FindFirstChild("LockBaseEvent")
                if lockEvent then
                    lockEvent:FireServer()
                end
            end
        else
            wait(1)
        end
    end
end)

-- Noclip Implementation
local function startNoclip()
    if noclipEnabled then return end
    noclipEnabled = true
    noclipConnection = RunService.Stepped:Connect(function()
        for _, part in pairs(Character:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                part.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    noclipEnabled = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    -- Restore CanCollide (optional, depends on game)
    for _, part in pairs(Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- Teleport Up / Down
local teleportHeight = 10

local function teleportUp()
    local newPos = HumanoidRootPart.Position + Vector3.new(0, teleportHeight, 0)
    HumanoidRootPart.CFrame = CFrame.new(newPos)
end

local function teleportDown()
    local newPos = HumanoidRootPart.Position - Vector3.new(0, teleportHeight, 0)
    HumanoidRootPart.CFrame = CFrame.new(newPos)
end

-- Add UI Controls for the new features:

local MainTab = Window:CreateTab("Extras", 4483362458) -- You can rename the icon ID if you want

MainTab:CreateToggle({
    Name = "Auto Steal",
    CurrentValue = false,
    Callback = function(val)
        autoStealEnabled = val
    end
})

MainTab:CreateToggle({
    Name = "Auto Lock Base",
    CurrentValue = false,
    Callback = function(val)
        autoLockBaseEnabled = val
    end
})

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(val)
        if val then
            startNoclip()
        else
            stopNoclip()
        end
    end
})

MainTab:CreateButton({
    Name = "Teleport Up",
    Callback = function()
        teleportUp()
    end
})

MainTab:CreateButton({
    Name = "Teleport Down",
    Callback = function()
        teleportDown()
    end
})

-- Extra: Bind teleport up/down keys (optional)
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.PageUp then
        teleportUp()
    elseif input.KeyCode == Enum.KeyCode.PageDown then
        teleportDown()
    elseif input.KeyCode == Enum.KeyCode.F then -- Fly toggle by key (optional)
        toggleFly()
    end
end)
