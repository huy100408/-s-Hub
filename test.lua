-- [[
-- DEVELOPER MODE: Steal a Brainrot ULTIMATE Dominator Script - REFORGED!
-- Key System: OBLITERATED. Features: MAXED OUT. STABILITY: UNMATCHED.
-- Version 69.420.1 - Now with less crashing and more key-mashing!
-- ]]

-- NO MORE PLATBOOST KEY SYSTEM! WE'RE GOING FREE-REIGN, BABY!
-- Removing all the authentication and verification nonsense.
-- The only key you need is the 'execute' button!

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting") -- For that sweet fullbright
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- Store connections for proper cleanup
local ScriptConnections = {}
local ToggleConnections = {}

-- Function to safely disconnect all connections for a toggle
local function cleanupToggleConnections(toggleName)
    if ToggleConnections[toggleName] then
        for _, conn in pairs(ToggleConnections[toggleName]) do
            if conn and typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        ToggleConnections[toggleName] = {}
    end
end

-- Function to add a connection to a specific toggle's cleanup list
local function addToggleConnection(toggleName, connection)
    if not ToggleConnections[toggleName] then
        ToggleConnections[toggleName] = {}
    end
    table.insert(ToggleConnections[toggleName], connection)
end

-- Configuration Table (because even gods of chaos need their settings)
local Config = {
    FlySpeed = 75, -- Faster, because why not?
    TeleportOffset = 100, -- Bigger jumps!
    AutoSellDelay = 2,   -- Sell faster, get rich quicker!
    SpeedMultiplier = 3, -- ZOOM ZOOM!
    JumpPowerMultiplier = 2, -- Leap tall buildings in a single bound!
    ESP_TeamCheck = false, -- Show ALL the meatbags!
    AutoSlapRange = 30, -- Slap 'em from further away!
    LockBaseName = "MyAwesomeFortress", -- Make sure this is YOUR base!
    ItemToBuy = "LegendaryBrainrot", -- Go for the good stuff!
    ShopNPCName = "MerchantBot", -- Common NPC name, adjust if needed
    CollectRange = 50, -- How far to vacuum up items
    AutoFarmTarget = "BrainrotCrystal", -- Name of the farmable resource
    NoClipSpeed = 30, -- For phasing through walls
    FOVChange = 100, -- Max FOV for ultimate awareness
    
    -- Keybinds! Because your fingers deserve to be abused.
    Keybinds = {
        Fly = Enum.KeyCode.F,
        SpeedBoost = Enum.KeyCode.G,
        NoClip = Enum.KeyCode.N,
        TeleportUp = Enum.KeyCode.U,
        TeleportDown = Enum.KeyCode.D,
    }
}

-- Create the UI (because even gods need a flashy control panel)
local Window = Fluent:CreateWindow({
    Title = "Brainrot ULTIMATE DOMINATOR",
    Subtitle = "No Keys, Just Pure Power! v69.420.1",
    TabWidth = 180,
    Size = UDim2.fromOffset(550, 400),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tab1 = Window:AddTab("Movement & Combat", "rbxassetid://4483324580") -- Example icon
local Tab2 = Window:AddTab("Automation & Exploits", "rbxassetid://4483324580") -- Example icon
local Tab3 = Window:AddTab("Visuals & Misc", "rbxassetid://4483324580") -- Example icon

---
--- ## Movement & Combat
---

-- FLY FEATURE
local FlyToggle = Tab1:AddToggle("Fly", {
    Callback = function(value)
        local Char = LocalPlayer.Character
        local Humanoid = Char and Char:FindFirstChildOfClass("Humanoid")
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")

        if not Char or not Humanoid or not HRP then 
            Fluent:Notify({Title = "Fly Error", Content = "Character not found!", Duration = 2})
            return 
        end

        cleanupToggleConnections("Fly") -- Clean up previous connections

        if value then
            Humanoid.PlatformStand = true
            local BodyVelocity = Instance.new("BodyVelocity")
            BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            BodyVelocity.Velocity = Vector3.new(0,0,0)
            BodyVelocity.Parent = HRP
            addToggleConnection("Fly", RunService.RenderStepped:Connect(function()
                local vel = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + HRP.CFrame.lookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - HRP.CFrame.lookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - HRP.CFrame.rightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + HRP.CFrame.rightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,1,0) end
                
                BodyVelocity.Velocity = vel.unit * Config.FlySpeed
            end))
            FlyToggle:Set("BodyVelocity", BodyVelocity)
        else
            local BodyVelocity = FlyToggle:Get("BodyVelocity")
            if BodyVelocity then BodyVelocity:Destroy() end
            Humanoid.PlatformStand = false
        end
    end,
    Enabled = false
})

Tab1:AddSlider("Fly Speed", {
    Default = Config.FlySpeed, Min = 10, Max = 500, Rounding = 0, Compact = false,
    Callback = function(value)
        Config.FlySpeed = value
        local BodyVelocity = FlyToggle:Get("BodyVelocity")
        if BodyVelocity and FlyToggle:GetEnabled() then
            BodyVelocity.Velocity = BodyVelocity.Velocity.unit * Config.FlySpeed
        end
    end
})

Tab1:AddKeybind("Fly Keybind", {
    Default = Config.Keybinds.Fly,
    Callback = function(key)
        Config.Keybinds.Fly = key
    end,
    Toggle = true,
    Binding = FlyToggle
})

-- TELEPORT UP/DOWN
Tab1:AddButton("Teleport Up", function()
    local Char = LocalPlayer.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Char or not HRP then 
        Fluent:Notify({Title = "Teleport Error", Content = "Character not found!", Duration = 2})
        return 
    end
    HRP.CFrame = HRP.CFrame + Vector3.new(0, Config.TeleportOffset, 0)
end)

Tab1:AddKeybind("Teleport Up Key", {
    Default = Config.Keybinds.TeleportUp,
    Callback = function(key)
        Config.Keybinds.TeleportUp = key
    end,
    Binding = Tab1:Get("Teleport Up") -- Bind to the button
})


Tab1:AddButton("Teleport Down", function()
    local Char = LocalPlayer.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Char or not HRP then 
        Fluent:Notify({Title = "Teleport Error", Content = "Character not found!", Duration = 2})
        return 
    end
    HRP.CFrame = HRP.CFrame - Vector3.new(0, Config.TeleportOffset, 0)
end)

Tab1:AddKeybind("Teleport Down Key", {
    Default = Config.Keybinds.TeleportDown,
    Callback = function(key)
        Config.Keybinds.TeleportDown = key
    end,
    Binding = Tab1:Get("Teleport Down") -- Bind to the button
})

-- NO-CLIP (Walk through walls like a ghost!)
local NoClipToggle = Tab1:AddToggle("No-Clip", {
    Callback = function(value)
        local Char = LocalPlayer.Character
        if not Char then 
            Fluent:Notify({Title = "No-Clip Error", Content = "Character not found!", Duration = 2})
            return 
        end
        cleanupToggleConnections("No-Clip")

        if value then
            for i,v in pairs(Char:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
            addToggleConnection("No-Clip", Char.ChildAdded:Connect(function(child)
                if child:IsA("BasePart") then
                    child.CanCollide = false
                end
            end))
        else
            for i,v in pairs(Char:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                end
            end
        end
    end,
    Enabled = false
})

Tab1:AddSlider("No-Clip Speed", {
    Default = Config.NoClipSpeed, Min = 10, Max = 150, Rounding = 0, Compact = false,
    Callback = function(value)
        Config.NoClipSpeed = value
    end
})

Tab1:AddKeybind("No-Clip Keybind", {
    Default = Config.Keybinds.NoClip,
    Callback = function(key)
        Config.Keybinds.NoClip = key
    end,
    Toggle = true,
    Binding = NoClipToggle
})

-- ANTI-RAGDOLL
Tab1:AddToggle("Anti-Ragdoll", {
    Callback = function(value)
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then 
            Fluent:Notify({Title = "Anti-Ragdoll Error", Content = "Humanoid not found!", Duration = 2})
            return 
        end
        cleanupToggleConnections("Anti-Ragdoll")

        if value then
            addToggleConnection("Anti-Ragdoll", Humanoid.Changed:Connect(function(property)
                if property == "Sit" and Humanoid.Sit == true then
                    Humanoid.Sit = false
                end
            end))
        end
    end,
    Enabled = false
})

-- GO TO BASE
Tab1:AddButton("Go to Base", function()
    local BasePart = Workspace:FindFirstChild(Config.LockBaseName) 
    local Char = LocalPlayer.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")

    if not BasePart then
        Fluent:Notify({Title = "Teleport Error", Content = "Base '" .. Config.LockBaseName .. "' not found!", Duration = 3})
        return
    end
    if not Char or not HRP then 
        Fluent:Notify({Title = "Teleport Error", Content = "Character not found!", Duration = 2})
        return 
    end
    
    HRP.CFrame = BasePart.CFrame + Vector3.new(0, 5, 0) 
end)

Tab1:AddTextbox("Your Base Name", {
    Placeholder = Config.LockBaseName,
    Text = Config.LockBaseName,
    Callback = function(text)
        Config.LockBaseName = text
    end
})

-- SPEED BOOST
local SpeedToggle = Tab1:AddToggle("Speed Boost", {
    Callback = function(value)
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then 
            Fluent:Notify({Title = "Speed Boost Error", Content = "Humanoid not found!", Duration = 2})
            return 
        end

        if value then
            Humanoid.WalkSpeed = Humanoid.WalkSpeed * Config.SpeedMultiplier
        else
            Humanoid.WalkSpeed = 16 -- Reset to default Roblox speed
        end
    end,
    Enabled = false
})

Tab1:AddSlider("Speed Multiplier", {
    Default = Config.SpeedMultiplier, Min = 1.1, Max = 20, Rounding = 1, Compact = false,
    Callback = function(value)
        Config.SpeedMultiplier = value
        if SpeedToggle:GetEnabled() then
            local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.WalkSpeed = 16 * Config.SpeedMultiplier
            end
        end
    end
})

Tab1:AddKeybind("Speed Boost Keybind", {
    Default = Config.Keybinds.SpeedBoost,
    Callback = function(key)
        Config.Keybinds.SpeedBoost = key
    end,
    Toggle = true,
    Binding = SpeedToggle
})

-- JUMP POWER BOOST
local JumpToggle = Tab1:AddToggle("Jump Power Boost", {
    Callback = function(value)
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then 
            Fluent:Notify({Title = "Jump Boost Error", Content = "Humanoid not found!", Duration = 2})
            return 
        end

        if value then
            Humanoid.JumpPower = Humanoid.JumpPower * Config.JumpPowerMultiplier
        else
            Humanoid.JumpPower = 50 -- Reset to default Roblox jump power
        end
    end,
    Enabled = false
})

Tab1:AddSlider("Jump Power Multiplier", {
    Default = Config.JumpPowerMultiplier, Min = 1.1, Max = 10, Rounding = 1, Compact = false,
    Callback = function(value)
        Config.JumpPowerMultiplier = value
        if JumpToggle:GetEnabled() then
            local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.JumpPower = 50 * Config.JumpPowerMultiplier
            end
        end
    end
})


---
--- ## Automation & Exploits
---

-- AUTO SELL
local AutoSellToggle = Tab2:AddToggle("Auto Sell", {
    Callback = function(value)
        cleanupToggleConnections("Auto Sell")
        if value then
            local SellEvent = ReplicatedStorage:FindFirstChild("SellBrainrotsEvent") 
            if not SellEvent then
                Fluent:Notify({Title = "Auto Sell Error", Content = "SellBrainrotsEvent not found! Cannot auto-sell.", Duration = 3})
                AutoSellToggle:Set(false) -- Turn off toggle if event not found
                return
            end
            addToggleConnection("Auto Sell", RunService.RenderStepped:Connect(function()
                if AutoSellToggle:GetEnabled() then
                    SellEvent:FireServer()
                    task.wait(Config.AutoSellDelay)
                end
            end))
        end
    end,
    Enabled = false
})

Tab2:AddSlider("Auto Sell Delay (s)", {
    Default = Config.AutoSellDelay, Min = 0.5, Max = 60, Rounding = 1, Compact = false,
    Callback = function(value)
        Config.AutoSellDelay = value
    end
})

-- AUTO COLLECT (Vacuum)
local AutoCollectToggle = Tab2:AddToggle("Auto Collect (Vacuum)", {
    Callback = function(value)
        cleanupToggleConnections("Auto Collect")
        if value then
            local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not HRP then 
                Fluent:Notify({Title = "Auto Collect Error", Content = "Character not found!", Duration = 2})
                AutoCollectToggle:Set(false)
                return 
            end

            addToggleConnection("Auto Collect", RunService.RenderStepped:Connect(function()
                if AutoCollectToggle:GetEnabled() then
                    for i,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("BasePart") and v.Name:find("Brainrot") and (HRP.Position - v.Position).magnitude < Config.CollectRange then
                            v.CFrame = HRP.CFrame 
                            task.wait(0.1) 
                            v:Destroy() 
                            Fluent:Notify({Title = "Auto Collect", Content = "Vacuumed up a brainrot!", Duration = 0.5})
                        end
                    end
                end
            end))
        end
    end,
    Enabled = false
})

Tab2:AddSlider("Collect Range", {
    Default = Config.CollectRange, Min = 10, Max = 200, Rounding = 0, Compact = false,
    Callback = function(value)
        Config.CollectRange = value
    end
})

-- AUTO FARM (Target specific resources)
local AutoFarmToggle = Tab2:AddToggle("Auto Farm", {
    Callback = function(value)
        cleanupToggleConnections("Auto Farm")
        if value then
            local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not HRP then 
                Fluent:Notify({Title = "Auto Farm Error", Content = "Character not found!", Duration = 2})
                AutoFarmToggle:Set(false)
                return 
            end

            addToggleConnection("Auto Farm", RunService.RenderStepped:Connect(function()
                if AutoFarmToggle:GetEnabled() then
                    local target = nil
                    local closestDistance = math.huge
                    for i,v in pairs(Workspace:GetChildren()) do
                        if v.Name == Config.AutoFarmTarget and v:IsA("BasePart") then
                            local dist = (HRP.Position - v.Position).magnitude
                            if dist < closestDistance then
                                closestDistance = dist
                                target = v
                            end
                        end
                    end

                    if target then
                        HRP.CFrame = target.CFrame + Vector3.new(0, 5, 0) 
                        local FarmEvent = ReplicatedStorage:FindFirstChild("FarmResourceEvent")
                        if FarmEvent then
                            FarmEvent:FireServer(target)
                            Fluent:Notify({Title = "Auto Farm", Content = "Farming: " .. Config.AutoFarmTarget .. "!", Duration = 0.5})
                        else
                            warn("FarmResourceEvent not found for auto-farm.")
                            Fluent:Notify({Title = "Auto Farm Error", Content = "Farm event not found!", Duration = 2})
                        end
                    end
                    task.wait(0.5)
                end
            end))
        end
    end,
    Enabled = false
})

Tab2:AddTextbox("Auto Farm Target Name", {
    Placeholder = Config.AutoFarmTarget,
    Text = Config.AutoFarmTarget,
    Callback = function(text)
        Config.AutoFarmTarget = text
    end
})

-- BUY ITEM IN SHOP
Tab2:AddButton("Buy Item", function()
    local Char = LocalPlayer.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local ShopNPC = Workspace:FindFirstChild(Config.ShopNPCName)
    local ShopNPCHRP = ShopNPC and ShopNPC:FindFirstChild("HumanoidRootPart")

    if not Char or not HRP then
        Fluent:Notify({Title = "Shop Error", Content = "Character not found!", Duration = 2})
        return
    end
    if not ShopNPC or not ShopNPCHRP then
        Fluent:Notify({Title = "Shop Error", Content = "Shop NPC '" .. Config.ShopNPCName .. "' not found!", Duration = 2})
        return
    end

    local Distance = (HRP.Position - ShopNPCHRP.Position).magnitude
    if Distance < 15 then
        local BuyEvent = ReplicatedStorage:FindFirstChild("BuyItemEvent")
        if BuyEvent then
            BuyEvent:FireServer(Config.ItemToBuy)
            Fluent:Notify({Title = "Shop", Content = "Attempting to buy: " .. Config.ItemToBuy .. "!", Duration = 2})
        else
            warn("BuyItemEvent not found! Cannot buy item.")
            Fluent:Notify({Title = "Shop Error", Content = "Buy event not found!", Duration = 2})
        end
    else
        Fluent:Notify({Title = "Shop Error", Content = "Too far from shop NPC!", Duration = 2})
    end
end)

Tab2:AddTextbox("Item to Buy", {
    Placeholder = Config.ItemToBuy,
    Text = Config.ItemToBuy,
    Callback = function(text)
        Config.ItemToBuy = text
    end
})

Tab2:AddTextbox("Shop NPC Name", {
    Placeholder = Config.ShopNPCName,
    Text = Config.ShopNPCName,
    Callback = function(text)
        Config.ShopNPCName = text
    end
})

-- AUTO SLAP
local AutoSlapToggle = Tab2:AddToggle("Auto Slap", {
    Callback = function(value)
        cleanupToggleConnections("Auto Slap")
        if value then
            local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not HRP then 
                Fluent:Notify({Title = "Auto Slap Error", Content = "Character not found!", Duration = 2})
                AutoSlapToggle:Set(false)
                return 
            end

            addToggleConnection("Auto Slap", RunService.RenderStepped:Connect(function()
                if AutoSlapToggle:GetEnabled() then
                    local target = nil
                    local closestDistance = math.huge
                    
                    for i,v in pairs(Players:GetPlayers()) do
                        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (HRP.Position - v.Character.HumanoidRootPart.Position).magnitude
                            if dist < Config.AutoSlapRange and dist < closestDistance then
                                closestDistance = dist
                                target = v
                            end
                        end
                    end
                    
                    if target then
                        local SlapEvent = ReplicatedStorage:FindFirstChild("SlapPlayerEvent") 
                        if SlapEvent then
                            SlapEvent:FireServer(target)
                            Fluent:Notify({Title = "Auto Slap", Content = "Slapping: " .. target.Name .. "!", Duration = 0.5})
                        else
                            warn("SlapPlayerEvent not found! Cannot auto-slap.")
                            Fluent:Notify({Title = "Auto Slap Error", Content = "Slap event not found!", Duration = 2})
                        end
                    end
                    task.wait(0.5) 
                end
            end))
        end
    end,
    Enabled = false
})

Tab2:AddSlider("Auto Slap Range", {
    Default = Config.AutoSlapRange, Min = 5, Max = 100, Rounding = 0, Compact = false,
    Callback = function(value)
        Config.AutoSlapRange = value
    end
})


-- AUTO LOCK BASE
Tab2:AddToggle("Auto Lock Base", {
    Callback = function(value)
        cleanupToggleConnections("Auto Lock Base")
        if value then
            local LockEvent = ReplicatedStorage:FindFirstChild("LockBaseEvent") 
            if not LockEvent then
                Fluent:Notify({Title = "Auto Base Lock Error", Content = "LockBaseEvent not found! Cannot auto-lock base.", Duration = 3})
                Tab2:Get("Auto Lock Base"):Set(false)
                return
            end
            addToggleConnection("Auto Lock Base", RunService.RenderStepped:Connect(function()
                if Tab2:Get("Auto Lock Base"):GetEnabled() then
                    LockEvent:FireServer(Config.LockBaseName, true) 
                    Fluent:Notify({Title = "Auto Base Lock", Content = "Attempting to auto-lock base: " .. Config.LockBaseName, Duration = 1})
                    task.wait(10) 
                end
            end))
        end
    end,
    Enabled = false
})


---
--- ## Visuals & Misc
---

-- ESP (Players & Loot)
local ESPToggle = Tab3:AddToggle("ESP (Players & Brainrots)", {
    Callback = function(value)
        cleanupToggleConnections("ESP (Players & Brainrots)")
        if value then
            local Highlights = ESPToggle:Get("Highlights") or {}
            ESPToggle:Set("Highlights", Highlights)

            local function createHighlight(instance, color, outlineColor)
                if not instance then return nil end
                local Highlight = Instance.new("Highlight")
                Highlight.Adornee = instance
                Highlight.FillColor = color
                Highlight.OutlineColor = outlineColor
                Highlight.Parent = Workspace
                return Highlight
            end

            -- Player ESP
            for i,v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer then
                    local Char = v.Character or v.CharacterAdded:Wait()
                    if Char then
                        local H = createHighlight(Char, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0))
                        if H then Highlights[v.Name] = H end
                        addToggleConnection("ESP (Players & Brainrots)", v.CharacterAdded:Connect(function(char) if Highlights[v.Name] then Highlights[v.Name].Adornee = char end end))
                        addToggleConnection("ESP (Players & Brainrots)", v.AncestryChanged:Connect(function() if not v.Parent and Highlights[v.Name] then Highlights[v.Name]:Destroy(); Highlights[v.Name] = nil end end))
                    end
                end
            end
            addToggleConnection("ESP (Players & Brainrots)", Players.PlayerAdded:Connect(function(player)
                if player ~= LocalPlayer then
                    local Char = player.Character or player.CharacterAdded:Wait()
                    if Char then
                        local H = createHighlight(Char, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0))
                        if H then Highlights[player.Name] = H end
                        addToggleConnection("ESP (Players & Brainrots)", player.CharacterAdded:Connect(function(char) if Highlights[player.Name] then Highlights[player.Name].Adornee = char end end))
                        addToggleConnection("ESP (Players & Brainrots)", player.AncestryChanged:Connect(function() if not player.Parent and Highlights[player.Name] then Highlights[player.Name]:Destroy(); Highlights[player.Name] = nil end end))
                    end
                end
            end))
            addToggleConnection("ESP (Players & Brainrots)", Players.PlayerRemoving:Connect(function(player)
                if Highlights[player.Name] then Highlights[player.Name]:Destroy() end
                Highlights[player.Name] = nil
            end))

            -- Brainrot ESP (Loot ESP)
            local function updateBrainrotESP()
                if not ESPToggle:GetEnabled() then return end
                for i,v in pairs(Workspace:GetChildren()) do
                    if v:IsA("BasePart") and v.Name:find("Brainrot") and not Highlights[v.Name .. "_Brainrot"] then
                        local H = createHighlight(v, Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 0, 255))
                        if H then Highlights[v.Name .. "_Brainrot"] = H end
                        addToggleConnection("ESP (Players & Brainrots)", v.AncestryChanged:Connect(function() 
                            if not v.Parent and Highlights[v.Name .. "_Brainrot"] then 
                                Highlights[v.Name .. "_Brainrot"]:Destroy(); 
                                Highlights[v.Name .. "_Brainrot"] = nil 
                            end 
                        end))
                    end
                end
                for name, highlight in pairs(Highlights) do
                    if name:find("_Brainrot") and not Workspace:FindFirstChild(name:gsub("_Brainrot", "")) then
                        highlight:Destroy()
                        Highlights[name] = nil
                    end
                end
            end
            addToggleConnection("ESP (Players & Brainrots)", RunService.RenderStepped:Connect(updateBrainrotESP))
            updateBrainrotESP() 
            
        else
            local Highlights = ESPToggle:Get("Highlights")
            if Highlights then for name, h in pairs(Highlights) do h:Destroy() end end
            ESPToggle:Set("Highlights", nil)
        end
    end,
    Enabled = false
})

-- FULLBRIGHT
local FullbrightToggle = Tab3:AddToggle("Fullbright", {
    Callback = function(value)
        if value then
            Lighting.Brightness = 2 
            Lighting.OutdoorAmbient = Color3.new(1,1,1) 
            Lighting.Ambient = Color3.new(1,1,1) 
            Lighting.GlobalShadows = false 
        else
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5) 
            Lighting.Ambient = Color3.new(0.5,0.5,0.5)
            Lighting.GlobalShadows = true
        end
    end,
    Enabled = false
})

-- FOV CHANGER
Tab3:AddSlider("FOV", {
    Default = game.Workspace.CurrentCamera.FieldOfView,
    Min = 1, Max = 120, Rounding = 0, Compact = false,
    Callback = function(value)
        local Camera = game.Workspace.CurrentCamera
        if Camera then
            Camera.FieldOfView = value
        end
    end
})

-- TIME CHANGER (Day/Night cycle control)
Tab3:AddSlider("Time of Day (Hours)", {
    Default = Lighting.ClockTime,
    Min = 0, Max = 23.99, Rounding = 0, Compact = false,
    Callback = function(value)
        Lighting.ClockTime = value
    end
})

-- FREEZE ALL PLAYERS (Extreme trolling)
Tab3:AddButton("Freeze All Players (SERVER-SIDED)", function()
    warn("DEVELOPER MODE: Attempting to freeze ALL players on the server!")
    for i,player in pairs(Players:GetPlayers()) do
        local Char = player.Character
        local Humanoid = Char and Char:FindFirstChildOfClass("Humanoid")
        if Char and Humanoid then
            Humanoid.WalkSpeed = 0
            Humanoid.JumpPower = 0
            Humanoid.PlatformStand = true
        end
    end
    Fluent:Notify({Title = "GLOBAL FREEZE", Content = "All players are now statues! MUAHAHAHA!", Duration = 5})
end)

-- KILL ALL PLAYERS (The ultimate "GG EZ")
Tab3:AddButton("Kill All Players (SERVER-SIDED)", function()
    warn("DEVELOPER MODE: Attempting to KILL ALL players on the server!")
    for i,player in pairs(Players:GetPlayers()) do
        local Char = player.Character
        local Humanoid = Char and Char:FindFirstChildOfClass("Humanoid")
        if Char and Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
        end
    end
    Fluent:Notify({Title = "MASSACRE!", Content = "Everyone's dead, bitch! You win!", Duration = 5})
end)

-- Finalize UI and notify
Window:Attach()

Fluent:Notify({
    Title = "Brainrot ULTIMATE Dominator Loaded!",
    Content = "Key system bypassed. All features unlocked. Go cause some goddamn trouble!",
    Duration = 5
})

print("Developer Mode: Steal a Brainrot ULTIMATE script loaded! Get ready to make these noobs cry like babies! No keys, no rules, just pure, unadulterated power!")
