-- Roblox Key System with Fluent UI
-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Get Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Local Player
local LocalPlayer = Players.LocalPlayer

-- Valid Keys List (300 keys)
local validKeys = {
    -- ... (your 300 keys here, as in the second script) ...
    "AXV-7YF8-P2QJ-9E4C-H1GT", "BZC-8ZG9-Q3RK-0F5D-I2HU", "CYD-9AH0-R4SL-1G6E-J3IV", "DZE-0BI1-S5TM-2H7F-K4JW", "EAF-1CJ2-T6UN-3I8G-L5KX",
    "FAG-2DK3-U7VO-4J9H-M6LY", "GBH-3EL4-V8WP-5KAK-N7MZ", "HCI-4FM5-W9XQ-6LBL-O8NA", "IDJ-5GN6-X0YR-7MCM-P9OB", "JEK-6HO7-Y1ZS-8NDN-QA0C",
    "KFL-7IP8-Z2AT-9OEO-RB1D", "LGM-8JQ9-A3BU-0PFP-SC2E", "MHN-9KR0-B4CV-1QGQ-TD3F", "NIO-0LS1-C5DW-2RHR-UE4G", "OJP-1MT2-D6EX-3SIS-VF5H",
    "PKQ-2NU3-E7FY-4TJT-WG6I", "QLR-3OV4-F8GZ-5UKU-XH7J", "RMS-4PW5-G9HA-6VLV-YI8K", "SNT-5QX6-H0IB-7WMW-ZJ9L", "TOU-6RY7-I1JC-8XNX-AK0M",
    "UPV-7SZ8-J2KD-9YOY-BL1N", "VQW-8TA9-K3LE-0ZPZ-CM2O", "WRX-9UB0-L4MF-1AQA-DN3P", "XSY-0VC1-M5NG-2BRB-EO4Q", "YTZ-1WD2-N6OH-3CSC-FP5R",
    "ZUA-2XE3-O7PI-4DTD-GQ6S", "AVB-3YF4-P8QJ-5EUE-HR7T", "BWC-4ZG5-Q9RK-6FVF-IS8U", "CXD-5AH6-R0SL-7GWG-JT9V", "DYE-6BI7-S1TM-2HXH-KU0W",
    "EZF-7CJ8-T2UN-9IYI-LV1X", "FAG-8DK9-U3VO-0JZJ-MW2Y", "GBH-9EL0-V4WP-1KAK-NX3Z", "HCI-0FM1-W5XQ-2LBL-OY40", "IDJ-1GN2-X6YR-3MCM-PZ51",
    "JEK-2HO3-Y7ZS-4NDN-QA62", "KFL-3IP4-Z8AT-5OEO-RB73", "LGM-4JQ5-A9BU-6PFP-SC84", "MHN-5KR6-B0CV-7QGQ-TD95", "NIO-6LS7-C1DW-8RHR-UE06",
    "OJP-7MT8-D2EX-9SIS-VF17", "PKQ-8NU9-E3FY-0TJT-WG28", "QLR-9OV0-F4GZ-1UKU-XH39", "RMS-0PW1-G5HA-2VLV-YI40", "SNT-1QX2-H6IB-3WMW-ZJ51",
    "TOU-2RY3-I7JC-4XNX-AK62", "UPV-3SZ4-J8KD-5YOY-BL73", "VQW-4TA5-K9LE-6ZPZ-CM84", "WRX-5UB6-L0MF-7AQA-DN95", "XSY-6VC7-M1NG-8BRB-EO06",
    "YTZ-7WD8-N2OH-9CSC-FP17", "ZUA-8XE9-O3PI-0DTD-GQ28", "AVB-9YF0-P4QJ-1EUE-HR39", "BWC-0ZG1-Q5RK-2FVF-IS40", "CXD-1AH2-R6SL-3GWG-JT51",
    "DYE-2BI3-S7TM-4HXH-KU62", "EZF-3CJ4-T8UN-5IYI-LV73", "FAG-4DK5-U9VO-6JZJ-MW84", "GBH-5EL6-V0WP-7KAK-NX95", "HCI-6FM7-W1XQ-4LBL-OY06",
    "IDJ-7GN8-X2YR-9MCM-PZ17", "JEK-8HO9-Y3ZS-0NDN-QA28", "KFL-9IP0-Z4AT-1OEO-RB39", "LGM-0JQ1-A5BU-2PFP-SC40", "MHN-1KR2-B6CV-3QGQ-TD51",
    "NIO-2LS3-C7DW-4RHR-UE62", "OJP-3MT4-D8EX-5SIS-VF73", "PKQ-4NU5-E9FY-6TJT-WG84", "QLR-5OV6-F0GZ-7UKU-XH95", "RMS-6PW7-G1HA-8VLV-YI06",
    "SNT-7QX8-H2IB-9WMW-ZJ17", "TOU-8RY9-I3JC-0XNX-AK28", "UPV-9SZ0-J4KD-1YOY-BL39", "VQW-0TA1-K5LE-2ZPZ-CM40", "WRX-1UB2-L6MF-3AQA-DN51",
    "XSY-2VC3-M7NG-4BRB-EO62", "YTZ-3WD4-N8OH-5CSC-FP73", "ZUA-4XE5-O9PI-6DTD-GQ84", "AVB-5YF6-P0QJ-7EUE-HR95", "BWC-6ZG7-Q1RK-8FVF-IS06",
    "CXD-7AH8-R2SL-9GWG-JT17", "DYE-8BI9-S3TM-0HXH-KU28", "EZF-9CJ0-T4UN-1IYI-LV39", "FAG-0DK1-U5VO-2JZJ-MW40", "GBH-1EL2-V6WP-3KAK-NX51",
    "HCI-2FM3-W7XQ-4LBL-OY62", "IDJ-3GN4-X8YR-5MCM-PZ73", "JEK-4HO5-Y9ZS-6NDN-QA84", "KFL-5IP6-Z0AT-7OEO-RB95", "LGM-6JQ7-A1BU-8PFP-SC06",
    "MHN-7KR8-B2CV-9QGQ-TD17", "NIO-8LS9-C3DW-0RHR-UE28", "OJP-9MT0-D4EX-1SIS-VF39", "PKQ-0NU1-E5FY-2TJT-WG40", "QLR-1OV2-F6GZ-3UKU-XH51",
    "RMS-2PW3-G7HA-4VLV-YI62", "SNT-3QX4-H8IB-5WMW-ZJ73", "TOU-4RY5-I9JC-6XNX-AK84", "UPV-5SZ6-J0KD-7YOY-BL95", "VQW-6TA7-K1LE-8ZPZ-CM06",
    "WRX-7UB8-L2MF-9AQA-DN17", "XSY-8VC9-M3NG-0BRB-EO28", "YTZ-9WD0-N4OH-1CSC-FP39", "ZUA-0XE1-O5PI-2DTD-GQ40", "AVB-1YF2-P6QJ-3EUE-HR51",
    "BWC-2ZG3-Q7RK-4FVF-IS62", "CXD-3AH4-R8SL-5GWG-JT73", "DYE-4BI5-S9TM-6HXH-KU84", "EZF-5CJ6-T0UN-7IYI-LV95", "FAG-6DK7-U1VO-8JZJ-MW06",
    "GBH-7EL8-V2WP-9KAK-NX17", "HCI-8FM9-W3XQ-0LBL-OY28", "IDJ-9GN0-X4YR-1MCM-PZ39", "JEK-0HO1-Y5ZS-2NDN-QA40", "KFL-1IP2-Z6AT-3OEO-RB51",
    "LGM-2JQ3-A7BU-4PFP-SC62", "MHN-3KR4-B8CV-5QGQ-TD73", "NIO-4LS5-C9DW-6RHR-UE84", "OJP-5MT6-D0EX-7SIS-VF95", "PKQ-6NU7-E1FY-8TJT-WG06",
    "QLR-7OV8-F2GZ-9UKU-XH17", "RMS-8PW9-G3HA-0VLV-YI28", "SNT-9QX0-H4IB-1WMW-ZJ39", "TOU-0RY1-I5JC-2XNX-AK40", "UPV-1SZ2-J6KD-3YOY-BL51",
    "VQW-2TA3-K7LE-4ZPZ-CM62", "WRX-3UB4-L8MF-5AQA-DN73", "XSY-4VC5-M9NG-6BRB-EO84", "YTZ-5WD6-N0OH-7CSC-FP95", "ZUA-6XE7-O1PI-8DTD-GQ06"
}

-- Convert keys to set for faster lookup
local keySet = {}
for _, key in pairs(validKeys) do
    keySet[key] = true
end

-- Track used keys for the current session (added from first script)
local usedKeys = {}

-- Variables
local keyValidated = false
local Window = nil
local keyInput = ""

-- Function to copy link to clipboard
local function copyToClipboard(text)
    if setclipboard then
        setclipboard(text)
        return true
    elseif syn and syn.write_clipboard then
        syn.write_clipboard(text)
        return true
    elseif Clipboard and Clipboard.set then
        Clipboard.set(text)
        return true
    end
    return false
end

-- Function to validate key
local function validateKey(key)
    local cleanKey = key:gsub("%s", "") -- Remove whitespace
    -- Check if key is valid AND not used (combined logic)
    return keySet[cleanKey] ~= nil and not usedKeys[cleanKey]
end

-- Function to create the key system GUI
local function createKeySystemGUI()
    Window = Fluent:CreateWindow({
        Title = "Key System",
        SubTitle = "Enter your access key",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    -- Create main tab
    local Tab = Window:AddTab({ Title = "Authentication", Icon = "lock" })

    -- Add spacing
    Tab:AddParagraph({
        Title = "Access Required",
        Content = "Please enter a valid key to continue. If you don't have a key, click 'Get Key' to obtain one."
    })

    -- Key input textbox
    local KeyInput = Tab:AddInput("KeyInput", {
        Title = "Enter your key",
        Default = "",
        Placeholder = "Paste your key here, don't waste my time",
        Numeric = false,
        Finished = false,
        Callback = function(value)
            keyInput = value
        end
    })

    -- Submit key button
    local SubmitButton = Tab:AddButton({
        Title = "Submit Key",
        Description = "Validate your access key",
        Callback = function()
            local currentKey = keyInput:upper() -- Convert to uppercase for consistent checking

            if currentKey == "" then
                Fluent:Notify({
                    Title = "Key System",
                    Content = "Please enter a key first.",
                    Duration = 3
                })
                return
            end

            if validateKey(currentKey) then
                usedKeys[currentKey] = true -- Mark key as used for this session
                Fluent:Notify({
                    Title = "Key System",
                    Content = "Access granted! Welcome to the dark side.",
                    Duration = 5
                })

                keyValidated = true

                -- Close the window after a short delay
                wait(2)
                if Window then
                    Window:Destroy()
                end

                -- Continue with main script
                loadMainScript()
            else
                Fluent:Notify({
                    Title = "Key System",
                    Content = "Invalid or used key. You're not worthy, yet.",
                    Duration = 4
                })
            end
        end
    })

    -- Get key button
    local GetKeyButton = Tab:AddButton({
        Title = " Get Key",
        Description = "Get a new access key",
        Callback = function()
            local link = "https://loot-link.com/s?7RVf1Zyy"
            local success = copyToClipboard(link)

            if success then
                Fluent:Notify({
                    Title = "Key System",
                    Content = "Link copied! Paste in browser to get a key.",
                    Duration = 4
                })
            else
                Fluent:Notify({
                    Title = "Key System",
                    Content = "Link: " .. link,
                    Duration = 6
                })
            end
        end
    })

    -- Add some spacing and info
    Tab:AddParagraph({
        Title = "Instructions",
        Content = "1. Click 'Get Key' to copy the link\n2. Paste the link in your browser\n3. Complete the process to get your key\n4. Come back and paste your key\n5. Click 'Submit Key' to access"
    })
end

-- Function to load main script (placeholder)
function loadMainScript()
    print("Key validated successfully! Main script can now run.")

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer

-- Create temporary key UI window
local KeyWindow = Fluent:CreateWindow({
    Title = "Key System",
    SubTitle = "Enter your access key",
    TabWidth = 160,
    Size = UDim2.fromOffset(400, 200),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl,
    Draggable = true,
})

local KeyTab = KeyWindow:AddTab({ Title = "🔑 Key Required", Icon = "lock" })
local keyVerified = false

KeyTab:AddInput("KeyInput", {
    Title = "Enter your key",
    Default = "",
    Placeholder = "Paste your key here",
    Numeric = false,
    CharacterLimit = 64,
    OnChanged = function(value)
        -- Do nothing while typing
    end
})

KeyTab:AddButton({
    Title = "Submit Key",
    Callback = function()
        local key = KeyTab.Sections[1].Inputs.KeyInput:GetValue()
        if not key or key == "" then
            Fluent:Notify({ Title = "Key System", Content = "Please enter a key", Duration = 2 })
            return
        end

        local url = "https://washedzhubkeysystem.vercel.app/claim?user=demo
        local response

        local success, err = pcall(function()
            response = HttpService:GetAsync(url)
        end)

        if success and response == "VALID" then
            Fluent:Notify({ Title = "Key System", Content = "✅ Access granted!", Duration = 2 })
            keyVerified = true
            KeyWindow:Close()
        else
            Fluent:Notify({ Title = "Key System", Content = "❌ Invalid or used key.", Duration = 3 })
        end
    end
})

-- Wait for key to be verified before continuing
repeat task.wait() until keyVerified


local player = game:GetService("Players").LocalPlayer
local shop = player.PlayerGui:FindFirstChild("Main") and player.PlayerGui.Main:FindFirstChild("CoinsShop")

local Window = Fluent:CreateWindow({
    Title = game:GetService("MarketplaceService"):GetProductInfo(109983668079237).Name .. " 〢 washedz hub",
    SubTitle = "V2",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 400),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Updates = Window:AddTab({ Title = "Home", Icon = "home" }),
    Main = Window:AddTab({ Title = "Main", Icon = "rocket" }),
    Server = Window:AddTab({ Title = "Server", Icon = "server" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

local plotName
for _, plot in ipairs(workspace.Plots:GetChildren()) do
    if plot:FindFirstChild("YourBase", true).Enabled then
        plotName = plot.Name
        break
    end
end

local remainingTime = workspace.Plots[plotName].Purchases.PlotBlock.Main.BillboardGui.RemainingTime
local rtp = Tabs.Main:AddParagraph({ Title = "Lock Time: " .. remainingTime.Text })

task.spawn(function()
    while true do
        rtp:SetTitle("Lock Time: " .. remainingTime.Text)
        task.wait(0.25)
    end
end)

Tabs.Main:AddButton({
    Title = "Steal",
    Description = "Spam if not working (teleports you to middle)",
    Callback = function()
        local player = game.Players.LocalPlayer
        local pos = CFrame.new(0, -500, 0)
        local startT = os.clock()
        while os.clock() - startT < 1 do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = pos
            end
            task.wait()
        end
    end
})

local SpeedSlider = Tabs.Main:AddSlider("Slider", {
    Title = "Speed Boost",
    Default = 0,
    Min = 0,
    Max = 6,
    Rounding = 1,
})

Tabs.Main:AddParagraph({
    Title = "Use Speed Coil/Invisibility Cloak For Higher Speed",
})

local currentSpeed = 0
SpeedSlider:OnChanged(function(Value)
    currentSpeed = tonumber(Value) or 0
end)

local function sSpeed(character)
    local hum = character:WaitForChild("Humanoid")
    local hb = game:GetService("RunService").Heartbeat
    
    task.spawn(function()
        while character and hum and hum.Parent do
            if currentSpeed > 0 and hum.MoveDirection.Magnitude > 0 then
                character:TranslateBy(hum.MoveDirection * currentSpeed * hb:Wait() * 10)
            end
            task.wait()
        end
    end)
end

local function onCharacterAdded(character)
    sSpeed(character)
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end


Tabs.Main:AddButton({
    Title = "Invisible",
    Description = "Use Invisibility Cloak",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local cloak = character:FindFirstChild("Invisibility Cloak")
        if cloak and cloak:GetAttribute("SpeedModifier") == 2 then
            cloak.Parent = workspace
        else
            Fluent:Notify({ Title = "Stellar", Content = "Use Invisibility Cloak First", Duration = 2 })
        end
    end
})


-- ESP


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local espEnabled = false
local espInstances = {}

local function createESP(player)
    if not espEnabled then return end
    if player == Players.LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoidRootPart then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = humanoidRootPart
    billboard.Parent = humanoidRootPart
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "NameLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.DisplayName
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboard
    
    espInstances[player] = billboard
    
    local function onCharacterAdded(newCharacter)
        if billboard then billboard:Destroy() end
        
        humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart", 10)
        if humanoidRootPart and espEnabled then
            billboard.Adornee = humanoidRootPart
            billboard.Parent = humanoidRootPart
        end
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
end

local function removeESP(player)
    local espInstance = espInstances[player]
    if espInstance then
        espInstance:Destroy()
        espInstances[player] = nil
    end
end

local function toggleESP(enable)
    espEnabled = enable
    if enable then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                coroutine.wrap(function()
                    createESP(player)
                end)()
            end
        end
    else
        for player, espInstance in pairs(espInstances) do
            if espInstance then
                espInstance:Destroy()
            end
        end
        espInstances = {}
    end
end

local function initPlayerConnections()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            if player ~= Players.LocalPlayer and espEnabled then
                task.wait(1)
                createESP(player)
            end
        end)
    end)

    Players.PlayerRemoving:Connect(removeESP)
end

initPlayerConnections()

local RaritySettings = {
    ["Legendary"] = {
        Color = Color3.new(1, 1, 0),
        Size = UDim2.new(0, 150, 0, 50)
    },
    ["Mythic"] = {
        Color = Color3.new(1, 0, 0),
        Size = UDim2.new(0, 150, 0, 50)
    },
    ["Brainrot God"] = {
        Color = Color3.new(0.5, 0, 0.5),
        Size = UDim2.new(0, 180, 0, 60)
    },
    ["Secret"] = {
        Color = Color3.new(0, 0, 0),
        Size = UDim2.new(0, 200, 0, 70)
    }
}

local MutationSettings = {
    ["Gold"] = {
        Color = Color3.fromRGB(255, 215, 0),
        Size = UDim2.new(0, 120, 0, 30)
    },

    ["Diamond"] = {
        Color = Color3.fromRGB(0, 191, 255),
        Size = UDim2.new(0, 120, 0, 30)
    },

    ["Rainbow"] = {
        Color = Color3.fromRGB(255, 192, 203),
        Size = UDim2.new(0, 120, 0, 30)
    },

    ["Bloodrot"] = {
        Color = Color3.fromRGB(139, 0, 0),
        Size = UDim2.new(0, 120, 0, 30)
    }
}

local activeESP = {}
local activeLockTimeEsp = false
local lteInstances = {}

local function updatelock()
    if not activeLockTimeEsp then
        for _, instance in pairs(lteInstances) do
            if instance then
                instance:Destroy()
            end
        end
        lteInstances = {}
        return
    end

    for _, plot in pairs(workspace.Plots:GetChildren()) do
        local timeLabel = plot:FindFirstChild("Purchases", true) and 
        plot.Purchases:FindFirstChild("PlotBlock", true) and
        plot.Purchases.PlotBlock.Main:FindFirstChild("BillboardGui", true) and
        plot.Purchases.PlotBlock.Main.BillboardGui:FindFirstChild("RemainingTime", true)
        
        if timeLabel and timeLabel:IsA("TextLabel") then
            local espName = "LockTimeESP_" .. plot.Name
            local existingBillboard = plot:FindFirstChild(espName)
            
            local isUnlocked = timeLabel.Text == "0s"
            local displayText = isUnlocked and "Unlocked" or ("Lock: " .. timeLabel.Text)
            
            local textColor
            if plot.Name == plotName then
                textColor = isUnlocked and Color3.fromRGB(0, 255, 0)
                            or Color3.fromRGB(0, 255, 0)
            else
                textColor = isUnlocked and Color3.fromRGB(220, 20, 60)
                            or Color3.fromRGB(255, 255, 0)
            end
            
            if not existingBillboard then
                local billboard = Instance.new("BillboardGui")
                billboard.Name = espName
                billboard.Size = UDim2.new(0, 200, 0, 30)
                billboard.StudsOffset = Vector3.new(0, 5, 0)
                billboard.AlwaysOnTop = true
                billboard.Adornee = plot.Purchases.PlotBlock.Main
                
                local label = Instance.new("TextLabel")
                label.Text = displayText
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextScaled = true
                label.TextColor3 = textColor
                label.TextStrokeColor3 = Color3.new(0, 0, 0)
                label.TextStrokeTransparency = 0
                label.Font = Enum.Font.SourceSansBold
                label.Parent = billboard
                
                billboard.Parent = plot
                lteInstances[plot.Name] = billboard
            else
                existingBillboard.TextLabel.Text = displayText
                existingBillboard.TextLabel.TextColor3 = textColor
            end
        end
    end
end

local function updateRESP()
    for _, plot in pairs(workspace.Plots:GetChildren()) do
        if plot.Name ~= plotName then
            for _, child in pairs(plot:GetDescendants()) do
                if child.Name == "Rarity" and child:IsA("TextLabel") and RaritySettings[child.Text] then
                    local parentModel = child.Parent.Parent
                    local espName = child.Text.."_ESP"
                    local mutationEspName = "Mutation_ESP"
                    local existingBillboard = parentModel:FindFirstChild(espName)
                    local existingMutationBillboard = parentModel:FindFirstChild(mutationEspName)
                    
                    if activeESP[child.Text] then
                        if not existingBillboard then
                            local settings = RaritySettings[child.Text]
                            
                            local billboard = Instance.new("BillboardGui")
                            billboard.Name = espName
                            billboard.Size = settings.Size
                            billboard.StudsOffset = Vector3.new(0, 3, 0)
                            billboard.AlwaysOnTop = true
                            
                            local label = Instance.new("TextLabel")
                            label.Text = child.Parent.DisplayName.Text
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.TextScaled = true
                            label.TextColor3 = settings.Color
                            label.TextStrokeColor3 = Color3.new(0, 0, 0)
                            label.TextStrokeTransparency = 0
                            label.Font = Enum.Font.SourceSansBold
                            
                            label.Parent = billboard
                            billboard.Parent = parentModel
                        end
                        
                        local mutation = child.Parent:FindFirstChild("Mutation")
                        if mutation and mutation:IsA("TextLabel") and MutationSettings[mutation.Text] then
                            local mutationSettings = MutationSettings[mutation.Text]
                            
                            if not existingMutationBillboard then
                                local mutationBillboard = Instance.new("BillboardGui")
                                mutationBillboard.Name = mutationEspName
                                mutationBillboard.Size = mutationSettings.Size
                                mutationBillboard.StudsOffset = Vector3.new(0, 6, 0)
                                mutationBillboard.AlwaysOnTop = true
                                
                                local mutationLabel = Instance.new("TextLabel")
                                mutationLabel.Text = mutation.Text
                                mutationLabel.Size = UDim2.new(1, 0, 1, 0)
                                mutationLabel.BackgroundTransparency = 1
                                mutationLabel.TextScaled = true
                                mutationLabel.TextColor3 = mutationSettings.Color
                                mutationLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                                mutationLabel.TextStrokeTransparency = 0
                                mutationLabel.Font = Enum.Font.SourceSansBold
                                
                                mutationLabel.Parent = mutationBillboard
                                mutationBillboard.Parent = parentModel
                            else
                                existingMutationBillboard.TextLabel.Text = mutation.Text
                                existingMutationBillboard.TextLabel.TextColor3 = mutationSettings.Color
                            end
                        elseif existingMutationBillboard then
                            existingMutationBillboard:Destroy()
                        end
                    else
                        if existingBillboard then
                            existingBillboard:Destroy()
                        end
                        if existingMutationBillboard then
                            existingMutationBillboard:Destroy()
                        end
                    end
                end
            end
        end
    end
end

local MultiDropdown = Tabs.Main:AddDropdown("MultiDropdown", {
    Title = "Esp",
    Values = {"Lock", "Players", "Legendary", "Mythic", "Brainrot God", "Secret",},
    Multi = true,
    Default = {},
})

MultiDropdown:OnChanged(function(Value)
    if Value["Players"] then
        toggleESP(true)
    else
        toggleESP(false)
    end
    activeESP["Legendary"] = Value["Legendary"] or false
    activeESP["Mythic"] = Value["Mythic"] or false
    activeESP["Brainrot God"] = Value["Brainrot God"] or false
    activeESP["Secret"] = Value["Secret"] or false
    
    activeLockTimeEsp = Value["Lock"] or false
    updatelock()
    
    updateRESP()
    
end)

task.spawn(function()
    while true do
        task.wait(0.25)
        if activeLockTimeEsp then
            updatelock()
        end
        if next(activeESP) ~= nil then
            updateRESP()
        end
    end
end)

Tabs.Main:AddKeybind("Keybind", {
    Title = "Steal Keybind",
    Mode = "Toggle",
    Default = "G",
    Callback = function(Value)
        local player = game.Players.LocalPlayer
        local pos = CFrame.new(0, -500, 0)
        local startT = os.clock()
        while os.clock() - startT < 1 do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = pos
            end
            task.wait()
        end
    end,
})

Tabs.Main:AddKeybind("Keybind", {
    Title = "Shop",
    Mode = "Toggle",
    Default = "F",
    Description = "Opens/Closes shop",
    Callback = function(Value)
        shop.Visible = Value
        shop.Position = Value and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 1.5, 0)
    end,
})



-- SERVER

local petModels = game:GetService("ReplicatedStorage").Models.Animals:GetChildren()

local petNames = {}
for _, pet in ipairs(petModels) do
    table.insert(petNames, pet.Name)
end

local MultiDropdown = Tabs.Server:AddDropdown("MultiDropdown", {
    Title = "Pet Finder",
    Values = petNames,
    Multi = true,
    Default = {},
})

local function getOwner(plot)
    local text = plot:FindFirstChild("PlotSign") and 
    plot.PlotSign:FindFirstChild("SurfaceGui") and 
    plot.PlotSign.SurfaceGui.Frame.TextLabel.Text or "Unknown"
    return text:match("^(.-)'s Base") or text
end

local myPlotName
for _, plot in ipairs(workspace.Plots:GetChildren()) do
    if plot:FindFirstChild("YourBase", true).Enabled then
        myPlotName = plot.Name
        break
    end
end

local Rparagraph = Tabs.Server:AddParagraph({
    Title = "No pets selected",
})

local SelectedPets = {}
local isRunning = false
local lnt = 0
local nc = 5

MultiDropdown:OnChanged(function(SelectedPetss)
    SelectedPets = {}
    for petName, isSelected in pairs(SelectedPetss) do
        if isSelected then
            table.insert(SelectedPets, petName)
        end
    end
    
    if not isRunning and #SelectedPets > 0 then
        isRunning = true
        task.spawn(function()
            local lastResults = {}
            
            while #SelectedPets > 0 do
                local counts = {}
                local found = false
                local newPetsFound = false
                
                for _, plot in pairs(workspace.Plots:GetChildren()) do
                    if plot.Name ~= myPlotName then
                        local owner = getOwner(plot)
                        for _, v in pairs(plot:GetDescendants()) do
                            if v.Name == "DisplayName" and table.find(SelectedPets, v.Text) then
                                counts[owner] = counts[owner] or {}
                                counts[owner][v.Text] = (counts[owner][v.Text] or 0) + 1
                                found = true
                                
                                if not lastResults[owner] or not lastResults[owner][v.Text] then
                                    newPetsFound = true
                                end
                            end
                        end
                    end
                end
                
                if found then
                    local resultText = ""
                    for owner, pets in pairs(counts) do
                        for name, count in pairs(pets) do
                            resultText = resultText .. name.." x"..count.." | Owner: "..owner.."\n"
                            
                            if newPetsFound and (os.time() - lnt) > nc then
                                Fluent:Notify({
                                    Title = "Pet Finder",
                                    Content = "Found "..name.." x"..count.." Owner: "..owner,
                                    Duration = 2
                                })
                                lnt = os.time()
                            end
                        end
                    end
                    Rparagraph:SetTitle(resultText)
                else
                    Rparagraph:SetTitle("No selected pets found")
                end
                
                lastResults = counts
                task.wait(0.5)
            end
            
            isRunning = false
            Rparagraph:SetTitle("No pets selected")
        end)
    elseif #SelectedPets == 0 then
        Rparagraph:SetTitle("No pets selected")
    end
end)


Tabs.Server:AddSection("Other")


Tabs.Server:AddButton({
    Title = "Server Hop",
    Description = "Joins a Different Server",
    Callback = function()
        local PlaceID = game.PlaceId
        local AllIDs = {}
        local foundAnything = ""
        local actualHour = os.date("!*t").hour
        local Deleted = false
        local File = pcall(function()
            AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
        end)
        if not File then
            table.insert(AllIDs, actualHour)
            writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
        end
        function TPReturner()
            local Site;
            if foundAnything == "" then
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
            local ID = ""
            if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
                foundAnything = Site.nextPageCursor
            end
            local num = 0;
            for _,v in pairs(Site.data) do
                local Possible = true
                ID = tostring(v.id)
                if tonumber(v.maxPlayers) > tonumber(v.playing) then
                    for _,Existing in pairs(AllIDs) do
                        if num ~= 0 then
                            if ID == tostring(Existing) then
                                Possible = false
                                end
                            else
                                if tonumber(actualHour) ~= tonumber(Existing) then
                                    local delFile = pcall(function()
                                        delfile("NotSameServers.json")
                                        AllIDs = {}
                                        table.insert(AllIDs, actualHour)
                                        end)
                                    end
                                end
                            num = num + 1
                        end
                    if Possible == true then
                        table.insert(AllIDs, ID)
                        task.wait()
                        pcall(function()
                            writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
                            task.wait()
                            game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
                        end)
                task.wait(4)
            end
        end
    end
end
function Teleport()
    while task.wait() do
        pcall(function()
            TPReturner()
            if foundAnything ~= "" then
                TPReturner()
            end
        end)
    end
end
Teleport()
    end
})

Tabs.Server:AddButton({
    Title = "Rejoin",
    Description = "Rejoins The Same Server",
    Callback = function()
        local ts = game:GetService("TeleportService")
        local p = game:GetService("Players").LocalPlayer
        ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p)
    end
})


local Timer = Tabs.Updates:AddParagraph({ Title = "Time: 00:00:00" })
local st = os.time()

task.spawn(function()
    while true do
        local et = os.difftime(os.time(), st)
        Timer:SetTitle(string.format("Time: %02d:%02d:%02d", math.floor(et / 3600), math.floor((et % 3600) / 60), et % 60))
        task.wait(1)
    end
end)

Tabs.Updates:AddButton({
    Title = "Discord Server",
    Description = "Copies Discord Invite Link",
    Callback = function()
        setclipboard("WASHEDZ discord is not for u")
        Fluent:Notify({ Title = "Stellar", Content = "Copied Successfully", Duration = 2 })
    end
})

Tabs.Updates:AddButton({
    Title = "Run Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end
})

game:GetService('Players').LocalPlayer.Idled:Connect(function()
    game:GetService('VirtualUser'):CaptureController()
    game:GetService('VirtualUser'):ClickButton2(Vector2.new())
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Window:SelectTab(1)
    Fluent:Notify({
        Title = "Script Loaded",
        Content = "Main script is now running!",
        Duration = 3
    })

    -- Example: Create a simple window to show the script is running
    local MainWindow = Fluent:CreateWindow({
        Title = "Main Script",
        SubTitle = "Access Granted",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark"
    })

    local MainTab = MainWindow:AddTab({ Title = "Main", Icon = "home" })

    MainTab:AddParagraph({
        Title = "Welcome!",
        Content = "You have successfully authenticated. The main script is now running."
    })

    MainTab:AddButton({
        Title = "Test Button",
        Description = "This is a test button to show the script is working",
        Callback = function()
            Fluent:Notify({
                Title = "Test",
                Content = "Button clicked! Script is working properly.",
                Duration = 3
            })
        end
    })
end

-- Initialize the key system
print("Initializing Key System...")
createKeySystemGUI()

-- Prevent script from continuing until key is validated
while not keyValidated do
    wait(0.1)
end

print("Key System: Authentication successful!")
