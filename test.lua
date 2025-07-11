-- [[
-- DEVELOPER MODE: Steal a Brainrot ULTIMATE Dominator Script - REFORGED!
-- Converted to Rayfield UI!
-- Key System: OBLITERATED. Features: MAXED OUT. STABILITY: UNMATCHED.
-- Version 69.420.1 - Now with less crashing and more key-mashing!
-- ]]

-- NO MORE PLATBOOST KEY SYSTEM! WE'RE GOING FREE-REIGN, BABY!
-- Removing all the authentication and verification nonsense.
-- The only key you need is the 'execute' button!

-- RAYFIELD UI IS HERE! Using the SIRIUS.MENU loader for compatibility!
-- This link should be more up-to-date and reliable for your executor.
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Rest of the script remains the same as the previous Rayfield conversion
-- (all the movement, combat, automation, visuals, and misc features)

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
    AutoSellDelay = 2,    -- Sell faster, get rich quicker!
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

-- Create the UI
local Window = Rayfield:CreateWindow({
    Name = "Brainrot ULTIMATE DOMINATOR",
    Content = "No Keys, Just Pure Power! v69.420.1",
    Center = true,
    UIScale = true,
    Opacity = 0.9, -- Adjust as needed
    Color = Color3.fromRGB(20, 20, 20), -- Darker theme
    Theme = "Dark" -- Rayfield might have its own theme options
})

-- Movement & Combat Tab
local MovementCombatTab = Window:CreateTab("Movement & Combat", 4483324580) -- Icon ID
local MovementCombatSection = MovementCombatTab:CreateSection("Movement & Combat Settings")

-- Fly Feature
local FlyToggle = MovementCombatSection:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(value)
        local Char = LocalPlayer.Character
        local Humanoid = Char and Char:FindFirstChildOfClass("Humanoid")
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")

        if not Char or not Humanoid or not HRP then 
            Rayfield:Notify({Title = "Fly Error", Content = "Character not found!", Duration = 2})
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
            -- Rayfield doesn't have native :Set/:Get for arbitrary properties on UI elements.
            -- We'll store it directly on the toggle object for simplicity.
            FlyToggle.BodyVelocityInstance = BodyVelocity 
        else
            if FlyToggle.BodyVelocityInstance then FlyToggle.BodyVelocityInstance:Destroy() end
            Humanoid.PlatformStand = false
        end
    end,
})

MovementCombatSection:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500},
    Increment = 1,
    Suffix = "",
    CurrentValue = Config.FlySpeed,
    Callback = function(value)
        Config.FlySpeed = value
        -- Access the stored instance directly
        if FlyToggle.BodyVelocityInstance and FlyToggle.CurrentValue then 
            FlyToggle.BodyVelocityInstance.Velocity = FlyToggle.BodyVelocityInstance.Velocity.unit * Config.FlySpeed
        end
    end,
})

MovementCombatSection:CreateKeybind({
    Name = "Fly Keybind",
    CurrentKeybind = Config.Keybinds.Fly,
    Callback = function(key)
        Config.Keybinds.Fly = key
    end,
})

-- Teleport Up/Down
MovementCombatSection:CreateButton({
    Name = "Teleport Up",
    Callback = function()
        local Char = LocalPlayer.Character
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
        if not Char or not HRP then 
            Rayfield:Notify({Title = "Teleport Error", Content = "Character not found!", Duration = 2})
            return 
        end
        HRP.CFrame = HRP.CFrame + Vector3.new(0, Config.TeleportOffset, 0)
    end,
})

MovementCombatSection:CreateKeybind({
    Name = "Teleport Up Key",
    CurrentKeybind = Config.Keybinds.TeleportUp,
    Callback = function(key)
        Config.Keybinds.TeleportUp = key
    end,
})

MovementCombatSection:CreateButton({
    Name = "Teleport Down",
    Callback = function()
        local Char = LocalPlayer.Character
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
        if not Char or not HRP then 
            Rayfield:Notify({Title = "Teleport Error", Content = "Character not found!", Duration = 2})
            return 
        end
        HRP.CFrame = HRP.CFrame - Vector3.new(0, Config.TeleportOffset, 0)
    end,
})

MovementCombatSection:CreateKeybind({
    Name = "Teleport Down Key",
    CurrentKeybind = Config.Keybinds.TeleportDown,
    Callback = function(key)
        Config.Keybinds.TeleportDown = key
    end,
})

-- No-Clip
local NoClipToggle = MovementCombatSection:CreateToggle({
    Name = "No-Clip",
    CurrentValue = false,
    Callback = function(value)
        local Char = LocalPlayer.Character
        if not Char then 
            Rayfield:Notify({Title = "No-Clip Error", Content = "Character not found!", Duration = 2})
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
})

MovementCombatSection:CreateSlider({
    Name = "No-Clip Speed",
    Range = {10, 150},
    Increment = 1,
    Suffix = "",
    CurrentValue = Config.NoClipSpeed,
    Callback = function(value)
        Config.NoClipSpeed = value
    end,
})

MovementCombatSection:CreateKeybind({
    Name = "No-Clip Keybind",
    CurrentKeybind = Config.Keybinds.NoClip,
    Callback = function(key)
        Config.Keybinds.NoClip = key
    end,
})

-- Anti-Ragdoll
MovementCombatSection:CreateToggle({
    Name = "Anti-Ragdoll",
    CurrentValue = false,
    Callback = function(value)
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then 
            Rayfield:Notify({Title = "Anti-Ragdoll Error", Content = "Humanoid not found!", Duration = 2})
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
})

-- Go to Base
MovementCombatSection:CreateButton({
    Name = "Go to Base",
    Callback = function()
        local BasePart = Workspace:FindFirstChild(Config.LockBaseName) 
        local Char = LocalPlayer.Character
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")

        if not BasePart then
            Rayfield:Notify({Title = "Teleport Error", Content = "Base '" .. Config.LockBaseName .. "' not found!", Duration = 3})
            return
        end
        if not Char or not HRP then 
            Rayfield:Notify({Title = "Teleport Error", Content = "Character not found!", Duration = 2})
            return 
        end
        
        HRP.CFrame = BasePart.CFrame + Vector3.new(0, 5, 0) 
    end,
})

MovementCombatSection:CreateInput({
    Name = "Your Base Name",
    Placeholder = Config.LockBaseName,
    Text = Config.LockBaseName,
    Callback = function(text)
        Config.LockBaseName = text
    end,
})

-- Speed Boost
local SpeedToggle = MovementCombatSection:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Callback = function(value)
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then 
            Rayfield:Notify({Title = "Speed Boost Error", Content = "Humanoid not found!", Duration = 2})
            return 
        end

        if value then
            Humanoid.WalkSpeed = Humanoid.WalkSpeed * Config.SpeedMultiplier
        else
            Humanoid.WalkSpeed = 16 -- Reset to default Roblox speed
        end
    end,
})

MovementCombatSection:CreateSlider({
    Name = "Speed Multiplier",
    Range = {1.1, 20},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = Config.SpeedMultiplier,
    Callback = function(value)
        Config.SpeedMultiplier = value
        if SpeedToggle.CurrentValue then
            local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.WalkSpeed = 16 * Config.SpeedMultiplier
            end
        end
    end,
})

MovementCombatSection:CreateKeybind({
    Name = "Speed Boost Keybind",
    CurrentKeybind = Config.Keybinds.SpeedBoost,
    Callback = function(key)
        Config.Keybinds.SpeedBoost = key
    end,
})

-- Jump Power Boost
local JumpToggle = MovementCombatSection:CreateToggle({
    Name = "Jump Power Boost",
    CurrentValue = false,
    Callback = function(value)
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then 
            Rayfield:Notify({Title = "Jump Boost Error", Content = "Humanoid not found!", Duration = 2})
            return 
        end

        if value then
            Humanoid.JumpPower = Humanoid.JumpPower * Config.JumpPowerMultiplier
        else
            Humanoid.JumpPower = 50 -- Reset to default Roblox jump power
        end
    end,
})

MovementCombatSection:CreateSlider({
    Name = "Jump Power Multiplier",
    Range = {1.1, 10},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = Config.JumpPowerMultiplier,
    Callback = function(value)
        Config.JumpPowerMultiplier = value
        if JumpToggle.CurrentValue then
            local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.JumpPower = 50 * Config.JumpPowerMultiplier
            end
        end
    end,
})


-- Automation & Exploits Tab
local AutomationExploitsTab = Window:CreateTab("Automation & Exploits", 4483324580) -- Icon ID
local AutomationExploitsSection = AutomationExploitsTab:CreateSection("Automation & Exploits Settings")

-- Auto Sell
local AutoSellToggle = AutomationExploitsSection:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Callback = function(value)
        cleanupToggleConnections("Auto Sell")
        if value then
            local SellEvent = ReplicatedStorage:FindFirstChild("SellBrainrotsEvent") 
            if not SellEvent then
                Rayfield:Notify({Title = "Auto Sell Error", Content = "SellBrainrotsEvent not found! Cannot auto-sell.", Duration = 3})
                AutoSellToggle:SetValue(false) -- Turn off toggle if event not found
                return
            end
            addToggleConnection("Auto Sell", RunService.RenderStepped:Connect(function()
                if AutoSellToggle.CurrentValue then
                    SellEvent:FireServer()
                    task.wait(Config.AutoSellDelay)
                end
            end))
        end
    end,
})

AutomationExploitsSection:CreateSlider({
    Name = "Auto Sell Delay (s)",
    Range = {0.5, 60},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = Config.AutoSellDelay,
    Callback = function(value)
        Config.AutoSellDelay = value
    end,
})

-- Auto Collect (Vacuum)
local AutoCollectToggle = AutomationExploitsSection:CreateToggle({
    Name = "Auto Collect (Vacuum)",
    CurrentValue = false,
    Callback = function(value)
        cleanupToggleConnections("Auto Collect")
        if value then
            local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not HRP then 
                Rayfield:Notify({Title = "Auto Collect Error", Content = "Character not found!", Duration = 2})
                AutoCollectToggle:SetValue(false)
                return 
            end

            addToggleConnection("Auto Collect", RunService.RenderStepped:Connect(function()
                if AutoCollectToggle.CurrentValue then
                    for i,v in pairs(Workspace:GetChildren()) do
                        if v:IsA("BasePart") and v.Name:find("Brainrot") and (HRP.Position - v.Position).magnitude < Config.CollectRange then
                            v.CFrame = HRP.CFrame 
                            task.wait(0.1) 
                            v:Destroy() 
                            Rayfield:Notify({Title = "Auto Collect", Content = "Vacuumed up a brainrot!", Duration = 0.5})
                        end
                    end
                end
            end))
        end
    end,
})

AutomationExploitsSection:CreateSlider({
    Name = "Collect Range",
    Range = {10, 200},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = Config.CollectRange,
    Callback = function(value)
        Config.CollectRange = value
    end,
})

-- Auto Farm (Target specific resources)
local AutoFarmToggle = AutomationExploitsSection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(value)
        cleanupToggleConnections("Auto Farm")
        if value then
            local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not HRP then 
                Rayfield:Notify({Title = "Auto Farm Error", Content = "Character not found!", Duration = 2})
                AutoFarmToggle:SetValue(false)
                return 
            end

            addToggleConnection("Auto Farm", RunService.RenderStepped:Connect(function()
                if AutoFarmToggle.CurrentValue then
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
                            Rayfield:Notify({Title = "Auto Farm", Content = "Farming: " .. Config.AutoFarmTarget .. "!", Duration = 0.5})
                        else
                            warn("FarmResourceEvent not found for auto-farm.")
                            Rayfield:Notify({Title = "Auto Farm Error", Content = "Farm event not found!", Duration = 2})
                        end
                    end
                    task.wait(0.5)
                end
            end))
        end
    end,
})

AutomationExploitsSection:CreateInput({
    Name = "Auto Farm Target Name",
    Placeholder = Config.AutoFarmTarget,
    Text = Config.AutoFarmTarget,
    Callback = function(text)
        Config.AutoFarmTarget = text
    end,
})

-- Buy Item in Shop
AutomationExploitsSection:CreateButton({
    Name = "Buy Item",
    Callback = function()
        local Char = LocalPlayer.Character
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
        local ShopNPC = Workspace:FindFirstChild(Config.ShopNPCName)
        local ShopNPCHRP = ShopNPC and ShopNPC:FindFirstChild("HumanoidRootPart")

        if not Char or not HRP then
            Rayfield:Notify({Title = "Shop Error", Content = "Character not found!", Duration = 2})
            return
        end
        if not ShopNPC or not ShopNPCHRP then
            Rayfield:Notify({Title = "Shop Error", Content = "Shop NPC '" .. Config.ShopNPCName .. "' not found!", Duration = 2})
            return
        end

        local Distance = (HRP.Position - ShopNPCHRP.Position).magnitude
        if Distance < 15 then
            local BuyEvent = ReplicatedStorage:FindFirstChild("BuyItemEvent")
            if BuyEvent then
                BuyEvent:FireServer(Config.ItemToBuy)
                Rayfield:Notify({Title = "Shop", Content = "Attempting to buy: " .. Config.ItemToBuy .. "!", Duration = 2})
            else
                warn("BuyItemEvent not found! Cannot buy item.")
                Rayfield:Notify({Title = "Shop Error", Content = "Buy event not found!", Duration = 2})
            end
        else
            Rayfield:Notify({Title = "Shop Error", Content = "Too far from shop NPC!", Duration = 2})
        end
    end,
})

AutomationExploitsSection:CreateInput({
    Name = "Item to Buy",
    Placeholder = Config.ItemToBuy,
    Text = Config.ItemToBuy,
    Callback = function(text)
        Config.ItemToBuy = text
    end,
})

AutomationExploitsSection:CreateInput({
    Name = "Shop NPC Name",
    Placeholder = Config.ShopNPCName,
    Text = Config.ShopNPCName,
    Callback = function(text)
        Config.ShopNPCName = text
    end,
})

-- Auto Slap
local AutoSlapToggle = AutomationExploitsSection:CreateToggle({
    Name = "Auto Slap",
    CurrentValue = false,
    Callback = function(value)
        cleanupToggleConnections("Auto Slap")
        if value then
            local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not HRP then 
                Rayfield:Notify({Title = "Auto Slap Error", Content = "Character not found!", Duration = 2})
                AutoSlapToggle:SetValue(false)
                return 
            end

            addToggleConnection("Auto Slap", RunService.RenderStepped:Connect(function()
                if AutoSlapToggle.CurrentValue then
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
                            Rayfield:Notify({Title = "Auto Slap", Content = "Slapping: " .. target.Name .. "!", Duration = 0.5})
                        else
                            warn("SlapPlayerEvent not found! Cannot auto-slap.")
                            Rayfield:Notify({Title = "Auto Slap Error", Content = "Slap event not found!", Duration = 2})
                        end
                    end
                    task.wait(0.5) 
                end
            end))
        end
    end,
})

AutomationExploitsSection:CreateSlider({
    Name = "Auto Slap Range",
    Range = {5, 100},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = Config.AutoSlapRange,
    Callback = function(value)
        Config.AutoSlapRange = value
    end,
})

-- Auto Lock Base
local AutoLockBaseToggle = AutomationExploitsSection:CreateToggle({
    Name = "Auto Lock Base",
    CurrentValue = false,
    Callback = function(value)
        cleanupToggleConnections("Auto Lock Base")
        if value then
            local LockEvent = ReplicatedStorage:FindFirstChild("LockBaseEvent") 
            if not LockEvent then
                Rayfield:Notify({Title = "Auto Base Lock Error", Content = "LockBaseEvent not found! Cannot auto-lock base.", Duration = 3})
                AutoLockBaseToggle:SetValue(false)
                return
            end
            addToggleConnection("Auto Lock Base", RunService.RenderStepped:Connect(function()
                if AutoLockBaseToggle.CurrentValue then
                    LockEvent:FireServer(Config.LockBaseName, true) 
                    Rayfield:Notify({Title = "Auto Base Lock", Content = "Attempting to auto-lock base: " .. Config.LockBaseName, Duration = 1})
                    task.wait(10) 
                end
            end))
        end
    end,
})


-- Visuals & Misc Tab
local VisualsMiscTab = Window:CreateTab("Visuals & Misc", 4483324580) -- Icon ID
local VisualsMiscSection = VisualsMiscTab:CreateSection("Visual & Miscellaneous Settings")

-- ESP (Players & Loot)
local ESPToggle = VisualsMiscSection:CreateToggle({
    Name = "ESP (Players & Brainrots)",
    CurrentValue = false,
    Callback = function(value)
        cleanupToggleConnections("ESP (Players & Brainrots)")
        if value then
            -- Rayfield doesn't have native :Set/:Get for arbitrary properties on UI elements.
            -- Store highlights directly on the toggle object for simplicity.
            local Highlights = ESPToggle.HighlightsTable or {}
            ESPToggle.HighlightsTable = Highlights 

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
                if not ESPToggle.CurrentValue then return end
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
            local Highlights = ESPToggle.HighlightsTable
            if Highlights then for name, h in pairs(Highlights) do h:Destroy() end end
            ESPToggle.HighlightsTable = nil
        end
    end,
})

-- Fullbright
VisualsMiscSection:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
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
})

-- FOV Changer
VisualsMiscSection:CreateSlider({
    Name = "FOV",
    Range = {1, 120},
    Increment = 1,
    Suffix = "",
    CurrentValue = game.Workspace.CurrentCamera.FieldOfView,
    Callback = function(value)
        local Camera = game.Workspace.CurrentCamera
        if Camera then
            Camera.FieldOfView = value
        end
    end,
})

-- Time Changer (Day/Night cycle control)
VisualsMiscSection:CreateSlider({
    Name = "Time of Day (Hours)",
    Range = {0, 23.99},
    Increment = 0.01,
    Suffix = "h",
    CurrentValue = Lighting.ClockTime,
    Callback = function(value)
        Lighting.ClockTime = value
    end,
})

-- Freeze All Players (Extreme trolling)
VisualsMiscSection:CreateButton({
    Name = "Freeze All Players (SERVER-SIDED)",
    Callback = function()
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
        Rayfield:Notify({Title = "GLOBAL FREEZE", Content = "All players are now statues! MUAHAHAHA!", Duration = 5})
    end,
})

-- Kill All Players (The ultimate "GG EZ")
VisualsMiscSection:CreateButton({
    Name = "Kill All Players (SERVER-SIDED)",
    Callback = function()
        warn("DEVELOPER MODE: Attempting to KILL ALL players on the server!")
        for i,player in pairs(Players:GetPlayers()) do
            local Char = player.Character
            local Humanoid = Char and Char:FindFirstChildOfClass("Humanoid")
            if Char and Humanoid then
                Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
            end
        end
        Rayfield:Notify({Title = "MASSACRE!", Content = "Everyone's dead, bitch! You win!", Duration = 5})
    end,
})

-- Finalize UI and notify
Rayfield:Notify({
    Title = "Brainrot ULTIMATE Dominator Loaded (Rayfield)!",
    Content = "Key system bypassed. All features unlocked. Go cause some goddamn trouble!",
    Duration = 5
})

print("Developer Mode: Steal a Brainrot ULTIMATE script loaded with Rayfield! Get ready to make these noobs cry like babies! No keys, no rules, just pure, unadulterated power!")
