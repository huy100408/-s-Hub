-- [[
-- DEVELOPER MODE: Steal a Brainrot Dominator Script - URL Edition!
-- Pulling Fluent from the freshest GitHub release. This is gonna be EPIC.
-- Version 6.9 - Now with even more unfiltered awesome!
-- ]]

-- LOAD THE FLUENT LIBRARY DIRECTLY FROM THE GIVEN URL - NO MERCY!
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Define some common services and functions we'll need
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- Configuration Table (because even evil needs organization)
local Config = {
    FlySpeed = 50,
    TeleportOffset = 50, -- How far up/down to teleport
    AutoSellDelay = 5,   -- Seconds between auto sells
    SpeedMultiplier = 2, -- How much faster you wanna go, turbo!
    ESP_TeamCheck = true, -- Only show enemies? Nah, show everyone!
    AutoSlapRange = 20, -- Get 'em close enough!
    LockBaseName = "YourBaseNameHere", -- Replace with your actual base name
    ItemToBuy = "RandomBrainrot", -- Or a specific item like "MythicBrainrot"
    ShopNPCName = "ShopkeeperNPC" -- Name of the shop NPC
}

-- Create the UI (because even gods need a dashboard)
local Window = Fluent:CreateWindow({
    Title = "Brainrot Dominator v6.9 - Now with GitHub Fluent!",
    Subtitle = "Unleash the Mayhem!"
})

local Tab1 = Window:AddTab("Movement & Combat", "rbxassetid://4483324580") -- Example icon
local Tab2 = Window:AddTab("Automation & ESP", "rbxassetid://4483324580") -- Example icon

-- FLY FEATURE
local FlyToggle = Tab1:AddToggle("Fly", {
    Callback = function(value)
        if value then
            -- Implement simple client-sided fly
            local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.PlatformStand = true
                local BodyVelocity = Instance.new("BodyVelocity")
                BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                BodyVelocity.Velocity = Vector3.new(0,0,0)
                BodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart
                
                local Connection
                Connection = RunService.RenderStepped:Connect(function()
                    local vel = Vector3.new(0,0,0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + LocalPlayer.Character.HumanoidRootPart.CFrame.lookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - LocalPlayer.Character.HumanoidRootPart.CFrame.lookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - LocalPlayer.Character.HumanoidRootPart.CFrame.rightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + LocalPlayer.Character.HumanoidRootPart.CFrame.rightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,1,0) end
                    
                    BodyVelocity.Velocity = vel.unit * Config.FlySpeed
                end)
                FlyToggle:Set("BodyVelocity", BodyVelocity)
                FlyToggle:Set("Connection", Connection)
            end
        else
            local BodyVelocity = FlyToggle:Get("BodyVelocity")
            local Connection = FlyToggle:Get("Connection")
            if BodyVelocity and Connection then
                BodyVelocity:Destroy()
                Connection:Disconnect()
                local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if Humanoid then
                    Humanoid.PlatformStand = false
                end
            end
        end
    end,
    Enabled = false
})

Tab1:AddSlider("Fly Speed", {
    Default = Config.FlySpeed,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        Config.FlySpeed = value
        local BodyVelocity = FlyToggle:Get("BodyVelocity")
        if BodyVelocity then
            BodyVelocity.Velocity = BodyVelocity.Velocity.unit * Config.FlySpeed
        end
    end
})

-- TELEPORT UP/DOWN
Tab1:AddButton("Teleport Up", function()
    local Char = LocalPlayer.Character
    if Char then
        local HRP = Char:FindFirstChild("HumanoidRootPart")
        if HRP then
            HRP.CFrame = HRP.CFrame + Vector3.new(0, Config.TeleportOffset, 0)
        end
    end
end)

Tab1:AddButton("Teleport Down", function()
    local Char = LocalPlayer.Character
    if Char then
        local HRP = Char:FindFirstChild("HumanoidRootPart")
        if HRP then
            HRP.CFrame = HRP.CFrame - Vector3.new(0, Config.TeleportOffset, 0)
        end
    end
end)

-- ANTI-RAGDOLL
Tab1:AddToggle("Anti-Ragdoll", {
    Callback = function(value)
        if value then
            -- This is often done by disabling or constantly resetting Humanoid.Sit
            -- or by messing with the physics properties on the client.
            -- For a simple example, we'll just try to keep Humanoid.Sit false.
            local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                local Connection = Humanoid.Changed:Connect(function(property)
                    if property == "Sit" and Humanoid.Sit == true then
                        Humanoid.Sit = false
                    end
                end)
                Tab1:Set("AntiRagdollConnection", Connection)
            end
        else
            local Connection = Tab1:Get("AntiRagdollConnection")
            if Connection then
                Connection:Disconnect()
            end
        end
    end,
    Enabled = false
})

-- GO TO BASE
Tab1:AddButton("Go to Base", function()
    local BasePart = Workspace:FindFirstChild(Config.LockBaseName) -- Assuming your base has a main part named this
    if BasePart then
        local Char = LocalPlayer.Character
        if Char then
            local HRP = Char:FindFirstChild("HumanoidRootPart")
            if HRP then
                HRP.CFrame = BasePart.CFrame + Vector3.new(0, 5, 0) -- Teleport slightly above the base
            end
        end
    end
end)

-- SPEED BOOST
local SpeedToggle = Tab1:AddToggle("Speed Boost", {
    Callback = function(value)
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            if value then
                Humanoid.WalkSpeed = Humanoid.WalkSpeed * Config.SpeedMultiplier
            else
                Humanoid.WalkSpeed = Humanoid.WalkSpeed / Config.SpeedMultiplier
            end
        end
    end,
    Enabled = false
})

Tab1:AddSlider("Speed Multiplier", {
    Default = Config.SpeedMultiplier,
    Min = 1.1,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(value)
        Config.SpeedMultiplier = value
        if SpeedToggle:GetEnabled() then
            -- Re-apply speed if already enabled
            local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.WalkSpeed = 16 * Config.SpeedMultiplier -- Assuming base walkspeed is 16
            end
        end
    end
})

-- AUTO SELL
local AutoSellToggle = Tab2:AddToggle("Auto Sell", {
    Callback = function(value)
        local selling = value
        if selling then
            local function sellLoop()
                while selling do
                    -- This would typically involve finding a "Sell" button/NPC and firing a remote event.
                    -- Placeholder: Find a "Sell" remote event in ReplicatedStorage or other service
                    local SellEvent = ReplicatedStorage:FindFirstChild("SellBrainrotsEvent") -- Example RemoteEvent
                    if SellEvent then
                        SellEvent:FireServer() -- Attempt to fire the sell event
                        print("Attempting to auto-sell brainrots!")
                    else
                        warn("SellBrainrotsEvent not found! Cannot auto-sell.")
                    end
                    task.wait(Config.AutoSellDelay)
                end
            end
            task.spawn(sellLoop)
            AutoSellToggle:Set("SellingLoop", selling) -- Store state
        else
            AutoSellToggle:Set("SellingLoop", false)
        end
    end,
    Enabled = false
})

Tab2:AddSlider("Auto Sell Delay (s)", {
    Default = Config.AutoSellDelay,
    Min = 1,
    Max = 60,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        Config.AutoSellDelay = value
    end
})

-- ESP (Lock, Player)
local ESPToggle = Tab2:AddToggle("ESP (Players)", {
    Callback = function(value)
        if value then
            local Connections = {}
            for i,v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer then
                    local Highlight = Instance.new("Highlight")
                    Highlight.Adornee = v.Character or v.CharacterAdded:Wait()
                    Highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red for enemies
                    Highlight.OutlineColor = Color3.fromRGB(255, 255, 0) -- Yellow outline
                    Highlight.Parent = Workspace
                    
                    Connections[v.Name] = v.CharacterAdded:Connect(function(char)
                        Highlight.Adornee = char
                    end)
                    Connections[v.Name .. "Removed"] = v.AncestryChanged:Connect(function()
                        if not v.Parent then Highlight:Destroy() end
                    end)
                    
                    ESPToggle:Set("Highlights", ESPToggle:Get("Highlights") or {})
                    ESPToggle:Get("Highlights")[v.Name] = Highlight
                end
            end
            
            ESPToggle:Set("PlayerAddedConnection", Players.PlayerAdded:Connect(function(player)
                if player ~= LocalPlayer then
                    local Highlight = Instance.new("Highlight")
                    Highlight.Adornee = player.Character or player.CharacterAdded:Wait()
                    Highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    Highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                    Highlight.Parent = Workspace
                    
                    ESPToggle:Get("Highlights")[player.Name] = Highlight
                    
                    Connections[player.Name] = player.CharacterAdded:Connect(function(char)
                        Highlight.Adornee = char
                    end)
                    Connections[player.Name .. "Removed"] = player.AncestryChanged:Connect(function()
                        if not player.Parent then Highlight:Destroy() end
                    end)
                end
            end))
            
            ESPToggle:Set("PlayerRemovingConnection", Players.PlayerRemoving:Connect(function(player)
                local Highlight = ESPToggle:Get("Highlights") and ESPToggle:Get("Highlights")[player.Name]
                if Highlight then Highlight:Destroy() end
                if Connections[player.Name] then Connections[player.Name]:Disconnect() end
                if Connections[player.Name .. "Removed"] then Connections[player.Name .. "Removed"]:Disconnect() end
                ESPToggle:Get("Highlights")[player.Name] = nil
            end))
            
        else
            local Highlights = ESPToggle:Get("Highlights")
            if Highlights then
                for name, highlight in pairs(Highlights) do
                    highlight:Destroy()
                end
            end
            local PlayerAddedConn = ESPToggle:Get("PlayerAddedConnection")
            local PlayerRemovingConn = ESPToggle:Get("PlayerRemovingConnection")
            if PlayerAddedConn then PlayerAddedConn:Disconnect() end
            if PlayerRemovingConn then PlayerRemovingConn:Disconnect() end
        end
    end,
    Enabled = false
})

-- BUY ITEM IN SHOP
Tab2:AddButton("Buy Item", function()
    -- This would involve finding the shop NPC, interacting with it,
    -- and then triggering the purchase remote event.
    local ShopNPC = Workspace:FindFirstChild(Config.ShopNPCName)
    if ShopNPC and ShopNPC:FindFirstChild("HumanoidRootPart") then
        local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - ShopNPC.HumanoidRootPart.Position).magnitude
        if Distance < 15 then -- Check if close enough
            local BuyEvent = ReplicatedStorage:FindFirstChild("BuyItemEvent") -- Example RemoteEvent for buying
            if BuyEvent then
                BuyEvent:FireServer(Config.ItemToBuy)
                print("Attempting to buy: " .. Config.ItemToBuy)
            else
                warn("BuyItemEvent not found! Cannot buy item.")
            end
        else
            warn("Too far from shop NPC!")
        end
    else
        warn("Shop NPC not found!")
    end
end)

Tab2:AddTextbox("Item to Buy", {
    Placeholder = Config.ItemToBuy,
    Text = Config.ItemToBuy,
    Callback = function(text)
        Config.ItemToBuy = text
    end
})

-- AUTO SLAP
local AutoSlapToggle = Tab2:AddToggle("Auto Slap", {
    Callback = function(value)
        local slapping = value
        if slapping then
            local function slapLoop()
                while slapping do
                    local target = nil
                    local closestDistance = math.huge
                    for i,v in pairs(Players:GetPlayers()) do
                        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).magnitude
                            if dist < Config.AutoSlapRange and dist < closestDistance then
                                closestDistance = dist
                                target = v
                            end
                        end
                    end
                    
                    if target then
                        -- This would involve finding the "Slap" tool or remote event and activating it.
                        local SlapEvent = ReplicatedStorage:FindFirstChild("SlapPlayerEvent") -- Example RemoteEvent
                        if SlapEvent then
                            SlapEvent:FireServer(target)
                            print("Slapping: " .. target.Name .. "!")
                        else
                            warn("SlapPlayerEvent not found! Cannot auto-slap.")
                        end
                    end
                    task.wait(0.5) -- Slap every half second
                end
            end
            task.spawn(slapLoop)
            AutoSlapToggle:Set("SlappingLoop", slapping)
        else
            AutoSlapToggle:Set("SlappingLoop", false)
        end
    end,
    Enabled = false
})

Tab2:AddSlider("Auto Slap Range", {
    Default = Config.AutoSlapRange,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        Config.AutoSlapRange = value
    end
})


-- AUTO LOCK BASE
-- This is highly game-dependent. It would likely involve interacting with a base's specific
-- locking mechanism, which could be a remote event or changing a property on a base part.
-- For demonstration, we'll assume a theoretical 'LockBase' remote event.
Tab2:AddToggle("Auto Lock Base", {
    Callback = function(value)
        local locking = value
        if locking then
            local function lockLoop()
                while locking do
                    local LockEvent = ReplicatedStorage:FindFirstChild("LockBaseEvent") -- Example RemoteEvent
                    if LockEvent then
                        LockEvent:FireServer(Config.LockBaseName, true) -- Attempt to lock your base
                        print("Attempting to auto-lock base: " .. Config.LockBaseName)
                    else
                        warn("LockBaseEvent not found! Cannot auto-lock base.")
                    end
                    task.wait(10) -- Attempt to lock every 10 seconds
                end
            end
            task.spawn(lockLoop)
            Tab2:Set("LockingLoop", locking)
        else
            Tab2:Set("LockingLoop", false)
        end
    end,
    Enabled = false
})

Tab2:AddTextbox("Your Base Name", {
    Placeholder = Config.LockBaseName,
    Text = Config.LockBaseName,
    Callback = function(text)
        Config.LockBaseName = text
    end
})


-- Finish up the UI
Window:Attach()

print("Developer Mode: Steal a Brainrot script loaded! Now with a FRESH Fluent library from GitHub! Go show 'em who's boss!")
