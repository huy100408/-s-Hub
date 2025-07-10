--[[
    Washedz Hub - A Professional Roblox Script Hub
    Built with Fluent UI (Dawid Scripts)
    Features: ESP, Fly, Infinite Jump, Noclip, Anti Ragdoll, Auto Steal, Auto Lock Base,
              Teleport to Base, Pet Finder, Server Hop, Custom UI Theme.
    No Key System (Free Access)
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

-- Player Variables
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Fluent UI Library Load (Dawid Scripts)
local Fluent = loadstring(game:HttpGet("https://github.com/DawidScript/Fluent/raw/main/src/main"))()

-- State Variables
local autoStealEnabled = false
local autoLockBaseEnabled = false
local noclipEnabled = false
local infiniteJumpEnabled = false
local flyEnabled = false
local antiRagdollEnabled = false
local petFinderEnabled = false

local flySpeed = 50 -- Default fly speed
local selectedBase = nil
local flyConnections = {} -- Table to store fly-related connections
local flightBodyVelocity = nil
local flightBodyGyro = nil

-- ESP Variables
local espColor = Color3.fromRGB(255, 0, 0) -- Red
local espBoxes = {} -- Store ESP box references (userId -> BoxHandleAdornment)

-- Pet Finder list (example pets, add more as you like)
local petList = {
    "SecretPet1",
    "SecretPet2",
    "BrainrotGod",
    -- Add more special pet names here as found in the game
}
local petHighlights = {} -- Store Highlight references (pet.Name -> Highlight)

-- Utility Functions
local function getPlayerAvatarThumbnail(player)
    -- This URL format is generally reliable for headshots
    return "rbxthumb://v1/users/headshot?id=" .. player.UserId .. "&w=80&h=80&format=png"
end

-- === Fluent UI Setup ===
local Window = Fluent:CreateWindow({
    Title = "Washedz Hub",
    SubTitle = "Welcome to Washedz Hub!",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 430),
    Acrylic = false, -- Disable Fluent's acrylic for custom background
    Theme = "Dark", -- Start with Dark, custom colors will override
    MinimizeKey = Enum.KeyCode.RightShift, -- Default minimize key
    CloseKey = Enum.KeyCode.RightShift, -- Set a close key (can be same as minimize)
})

-- Apply custom theme colors (white background, red accents)
Fluent.ThemeManager:SetColors(Color3.fromRGB(255, 255, 255), Color3.fromRGB(245, 245, 245), Color3.fromRGB(255, 0, 0))

-- === Snowfall Background Animation ===
local function createSnowfallEffect(guiObject)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SnowfallBackground"
    screenGui.DisplayOrder = 0 -- Behind everything else
    screenGui.ZIndex = 0
    screenGui.Parent = guiObject

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = screenGui

    local function createSnowflake()
        local flake = Instance.new("Frame")
        flake.Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5))
        flake.BackgroundColor3 = Color3.new(1, 1, 1) -- White snowflake
        flake.BackgroundTransparency = math.random(0, 50) / 100 -- Semi-transparent
        flake.BorderColor3 = Color3.new(0,0,0)
        flake.BorderSizePixel = 0
        flake.Parent = frame

        local xPos = math.random(0, 1000) / 1000
        local yPos = -0.1 -- Start above screen

        flake.Position = UDim2.new(xPos, 0, yPos, 0)

        local fallSpeed = math.random(5, 15) / 100 -- Slower fall
        local rotateSpeed = math.random(-10, 10) / 100 -- Gentle rotation

        local tweenInfo = TweenInfo.new(
            math.random(5, 15), -- Duration
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out,
            0, -- Repeat count
            false,
            0 -- Delay
        )

        local startRotation = math.random(0, 360)
        local endRotation = startRotation + math.random(-720, 720)

        local rotateTween = TweenService:Create(flake, TweenInfo.new(tweenInfo.Time, Enum.EasingStyle.Linear), {Rotation = endRotation})

        local tween = TweenService:Create(flake, tweenInfo, {Position = UDim2.new(xPos, 0, 1.1, 0)})

        local function onCompleted()
            flake:Destroy()
            createSnowflake() -- Create a new one when one finishes
        end

        tween.Completed:Connect(onCompleted)
        tween:Play()
        rotateTween:Play()
    end

    -- Create initial snowflakes
    for i = 1, 50 do -- Number of snowflakes
        task.wait(math.random(1, 10) / 100) -- Stagger creation
        createSnowflake()
    end
end

-- Hook snowfall effect to Fluent's main UI frame or PlayerGui
-- Fluent UI creates its own ScreenGui, so we can parent to the main ScreenGui it generates.
-- We need to wait for Fluent to draw its main UI.
task.spawn(function()
    while not Fluent.Window.Parent do
        task.wait()
    end
    -- Find Fluent's main ScreenGui to attach the snowfall effect
    local fluentScreenGui = Fluent.Window.Parent.Parent -- Window -> Frame -> ScreenGui
    if fluentScreenGui and fluentScreenGui:IsA("ScreenGui") then
        createSnowfallEffect(fluentScreenGui)
    else
        warn("Could not find Fluent's ScreenGui for snowfall effect.")
    end
end)


-- === Player Avatar and Username at bottom left (separate from Fluent for persistent display) ===
local PlayerInfoGui = Instance.new("ScreenGui")
PlayerInfoGui.Name = "PlayerInfoGui"
PlayerInfoGui.ResetOnSpawn = false -- Keep the UI visible across respawns
PlayerInfoGui.Parent = localPlayer:WaitForChild("PlayerGui")

local AvatarFrame = Instance.new("Frame")
AvatarFrame.BackgroundTransparency = 0.2
AvatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AvatarFrame.BorderSizePixel = 1
AvatarFrame.Position = UDim2.new(0, 10, 1, -100) -- Bottom-left, slightly offset
AvatarFrame.Size = UDim2.new(0, 80, 0, 80)
AvatarFrame.ZIndex = 10
AvatarFrame.Parent = PlayerInfoGui

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(1, 0, 1, 0)
AvatarImage.Position = UDim2.new(0,0,0,0)
AvatarImage.BackgroundTransparency = 1
AvatarImage.Image = getPlayerAvatarThumbnail(localPlayer)
AvatarImage.Parent = AvatarFrame

local UsernameLabel = Instance.new("TextLabel")
UsernameLabel.Position = UDim2.new(0, 10, 1, -20) -- Below avatar frame
UsernameLabel.Size = UDim2.new(0, 80, 0, 20)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.TextColor3 = Color3.fromRGB(0,0,0)
UsernameLabel.Font = Enum.Font.Gotham
UsernameLabel.TextSize = 14
UsernameLabel.Text = localPlayer.Name
UsernameLabel.TextWrapped = true
UsernameLabel.ZIndex = 10
UsernameLabel.Parent = PlayerInfoGui

-- Update avatar & name on respawn
localPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5) -- Give a small delay for thumbnail to load
    AvatarImage.Image = getPlayerAvatarThumbnail(localPlayer)
    UsernameLabel.Text = localPlayer.Name
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    -- Ensure features reset correctly on respawn
    if noclipEnabled then toggleNoclip(false) end
    if flyEnabled then stopFly() end -- Ensure fly is off
end)

-- === Feature Implementations ===

-- Fly System
local function startFly()
    if flyEnabled and character and rootPart and humanoid then
        humanoid.PlatformStand = true -- Prevent falling
        
        flightBodyVelocity = Instance.new("BodyVelocity")
        flightBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flightBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flightBodyVelocity.Parent = rootPart

        flightBodyGyro = Instance.new("BodyGyro")
        flightBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flightBodyGyro.CFrame = rootPart.CFrame
        flightBodyGyro.Parent = rootPart

        local inputState = {W=false, A=false, S=false, D=false, Q_Up=false, E_Down=false}

        flyConnections.inputBegan = UserInputService.InputBegan:Connect(function(inputObj, gameProcessed)
            if gameProcessed then return end
            if inputObj.KeyCode == Enum.KeyCode.W then inputState.W = true end
            if inputObj.KeyCode == Enum.KeyCode.A then inputState.A = true end
            if inputObj.KeyCode == Enum.KeyCode.S then inputState.S = true end
            if inputObj.KeyCode == Enum.KeyCode.D then inputState.D = true end
            if inputObj.KeyCode == Enum.KeyCode.Q then inputState.Q_Up = true end -- Upward movement
            if inputObj.KeyCode == Enum.KeyCode.E then inputState.E_Down = true end -- Downward movement
        end)

        flyConnections.inputEnded = UserInputService.InputEnded:Connect(function(inputObj, gameProcessed)
            if inputObj.KeyCode == Enum.KeyCode.W then inputState.W = false end
            if inputObj.KeyCode == Enum.KeyCode.A then inputState.A = false end
            if inputObj.KeyCode == Enum.KeyCode.S then inputState.S = false end
            if inputObj.KeyCode == Enum.KeyCode.D then inputState.D = false end
            if inputObj.KeyCode == Enum.KeyCode.Q then inputState.Q_Up = false end
            if inputObj.KeyCode == Enum.KeyCode.E then inputState.E_Down = false end
        end)

        flyConnections.heartbeat = RunService.Heartbeat:Connect(function()
            if not flyEnabled or not character or not rootPart or not flightBodyVelocity or not flightBodyGyro then return stopFly() end

            local moveDirection = Vector3.new(0,0,0)
            local camCF = Workspace.CurrentCamera.CFrame

            if inputState.W then moveDirection += camCF.LookVector end
            if inputState.S then moveDirection -= camCF.LookVector end
            if inputState.A then moveDirection -= camCF.RightVector end
            if inputState.D then moveDirection += camCF.RightVector end
            if inputState.Q_Up then moveDirection += Vector3.new(0,1,0) end -- Q for ascending
            if inputState.E_Down then moveDirection -= Vector3.new(0,1,0) end -- E for descending

            flightBodyVelocity.Velocity = moveDirection.Unit * flySpeed
            flightBodyGyro.CFrame = camCF
        end)
    else
        warn("Failed to start fly: character/rootPart/humanoid missing or fly not enabled.")
        flyEnabled = false -- Ensure toggle is off if start fails
    end
end

local function stopFly()
    flyEnabled = false
    if flightBodyVelocity then flightBodyVelocity:Destroy() flightBodyVelocity = nil end
    if flightBodyGyro then flightBodyGyro:Destroy() flightBodyGyro = nil end
    for _, conn in pairs(flyConnections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    flyConnections = {}
    if humanoid and humanoid.PlatformStand then
        humanoid.PlatformStand = false -- Re-enable normal movement
    end
end

-- ESP System
local function createOrUpdateESPBox(player)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local box = espBoxes[player.UserId]
    if not box or not box.Parent then
        box = Instance.new("BoxHandleAdornment")
        box.Name = "ESPBox"
        box.Adornee = char.HumanoidRootPart
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.Size = Vector3.new(4, 6, 4) -- Approx player size
        box.Parent = CoreGui -- Parent to CoreGui for better persistence
        espBoxes[player.UserId] = box
    end
    box.Color3 = espColor
    box.Transparency = 0.5
end

local function removeESPBox(player)
    if espBoxes[player.UserId] and espBoxes[player.UserId].Parent then
        espBoxes[player.UserId]:Destroy()
    end
    espBoxes[player.UserId] = nil
end

local function updateAllESP()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if Fluent.Window.Tabs[2].Components[1].Active then -- Check ESP toggle state directly
                createOrUpdateESPBox(plr)
            else
                removeESPBox(plr)
            end
        else
            removeESPBox(plr) -- Clean up if player character is gone or is local player
        end
    end

    -- Clean up boxes for players who left
    for userId, box in pairs(espBoxes) do
        if not Players:GetPlayerByUserId(userId) then
            if box and box.Parent then
                box:Destroy()
            end
            espBoxes[userId] = nil
        end
    end
end

-- Run ESP update on Heartbeat
RunService.Heartbeat:Connect(function()
    if Fluent.Window.Tabs[2].Components[1].Active then -- If ESP toggle is active
        updateAllESP()
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if Fluent.Window.Tabs[2].Components[1].Active and player ~= localPlayer then
            createOrUpdateESPBox(player)
        end
    end)
    if Fluent.Window.Tabs[2].Components[1].Active and player ~= localPlayer and player.Character then
        createOrUpdateESPBox(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPBox(player)
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and character and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Noclip
local noclipConnection = nil
local function toggleNoclip(state)
    noclipEnabled = state
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    local function applyNoclip(char, canCollide)
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = canCollide
                end
            end
        end
    end

    if noclipEnabled then
        noclipConnection = RunService.Stepped:Connect(function()
            applyNoclip(character, false)
        end)
    else
        applyNoclip(character, true)
    end
end

-- Anti Ragdoll
RunService.Stepped:Connect(function()
    if antiRagdollEnabled and character and humanoid then
        if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll or humanoid:GetState() == Enum.HumanoidStateType.Physics then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

-- Auto Steal
local function autoStealLoop()
    while true do
        task.wait(3) -- Wait 3 seconds to reduce anticheat suspicion
        if autoStealEnabled and character and rootPart then
            for _, plot in pairs(Workspace.Plots:GetChildren()) do
                if plot:FindFirstChild("AnimalPodiums") then -- Specific to pet/animal stealing games
                    for _, podium in pairs(plot.AnimalPodiums:GetChildren()) do
                        local dist = (podium:GetPivot().Position - rootPart.Position).Magnitude
                        if dist < 20 then -- 20 studs range to steal
                            pcall(function()
                                -- This remote might need to be adjusted based on the game's actual remote event path
                                local stealEvent = ReplicatedStorage.Packages.Net:FindFirstChild("RE/StealService/DeliverySteal")
                                if stealEvent then
                                    stealEvent:FireServer()
                                else
                                    warn("StealService remote not found!")
                                end
                            end)
                        end
                    end
                end
                -- Add more general stealing logic if applicable, e.g., for items
                -- if plot:FindFirstChild("StealableItem") and (plot.StealableItem.Position - rootPart.Position).Magnitude < 15 then
                --     pcall(function()
                --         ReplicatedStorage.RemoteEvents.StealItem:FireServer(plot.StealableItem)
                --     end)
                -- end
            end
        end
    end
end
task.spawn(autoStealLoop)

-- Auto Lock Base (keeps character at selected base)
local function autoLockBaseLoop()
    while true do
        task.wait(1.5)
        if autoLockBaseEnabled and selectedBase and character and rootPart then
            local targetPos = selectedBase.DeliveryHitbox.Position + Vector3.new(0,5,0) -- 5 studs above hitbox
            pcall(function()
                rootPart.CFrame = CFrame.new(targetPos)
            end)
        end
    end
end
task.spawn(autoLockBaseLoop)

-- Pet Finder
local function updatePetHighlights()
    for _, petModel in pairs(Workspace.Pets:GetChildren()) do
        if petModel:IsA("Model") and petModel:FindFirstChild("HumanoidRootPart") then
            -- Check if the pet's name is in the special pet list
            local isSpecialPet = false
            for _, specialName in pairs(petList) do
                if string.find(petModel.Name, specialName, 1, true) then
                    isSpecialPet = true
                    break
                end
            end

            if petFinderEnabled and isSpecialPet then
                local highlight = petHighlights[petModel.Name]
                if not highlight or not highlight.Parent then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "PetHighlight"
                    highlight.Adornee = petModel
                    highlight.FillColor = Color3.new(0, 1, 0) -- Green for pets
                    highlight.OutlineColor = Color3.new(1, 1, 1)
                    highlight.OutlineTransparency = 0.5
                    highlight.Parent = petModel
                    petHighlights[petModel.Name] = highlight
                end
            else
                local highlight = petHighlights[petModel.Name]
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
                petHighlights[petModel.Name] = nil
            end
        else
            -- Clean up if the pet model is no longer valid
            local highlight = petHighlights[petModel.Name]
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
            petHighlights[petModel.Name] = nil
        end
    end

    -- Clean up highlights for pets that are no longer in Workspace.Pets (e.g., despawned)
    for petName, highlight in pairs(petHighlights) do
        if not Workspace.Pets:FindFirstChild(petName) then
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
            petHighlights[petName] = nil
        end
    end
end

-- Periodically update pet highlights
RunService.Heartbeat:Connect(function()
    if petFinderEnabled then
        updatePetHighlights()
    end
end)

-- Server Hop
local function initiateServerHop()
    local PlaceId = game.PlaceId
    local Servers = {}

    local function getServers(cursor)
        local success, result = pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
            if cursor then
                url = url .. "&cursor=" .. cursor
            end
            local response = HttpService:GetAsync(url) -- Use GetAsync for blocking call
            return HttpService:JSONDecode(response)
        end)
        if not success then
            warn("Failed to get servers:", result)
            return nil
        end
        return result
    end

    -- Fluent notification for progress
    local notify = Fluent:Notify({
        Title = "Server Hop",
        Content = "Searching for available servers...",
        Duration = 9999, -- Indefinite until finished
        Image = "rbxassetid://4483362458", -- Example image ID
    })

    task.spawn(function()
        local cursor = nil
        local foundServers = false
        while true do
            local data = getServers(cursor)
            if data and data.data then
                for _, server in pairs(data.data) do
                    -- Only consider servers that are not full and not the current server
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(Servers, server.id)
                        foundServers = true
                    end
                end
                cursor = data.nextPageCursor
                if not cursor then break end
            else
                break
            end
            task.wait(0.5) -- Small wait to prevent API spam
        end

        if foundServers then
            local serverToJoin = Servers[math.random(1, #Servers)]
            TeleportService:TeleportToPlaceInstance(PlaceId, serverToJoin, localPlayer)
            notify:Update({
                Content = "Attempting to hop to a new server!",
                Duration = 5,
                Image = "rbxassetid://4483362458",
            })
        else
            notify:Update({
                Title = "Server Hop Failed",
                Content = "No suitable servers found. Try again later.",
                Duration = 5,
                Image = "rbxassetid://4483362458",
            })
            warn("No available servers found for hopping.")
        end
    end)
end

-- === Fluent UI Tabs and Components ===
local MainTab = Window:AddTab("Main")
local ESPTab = Window:AddTab("ESP")
local PetFinderTab = Window:AddTab("Pet Finder")
local MiscTab = Window:AddTab("Misc") -- For Noclip, Infinite Jump, Anti Ragdoll

-- Main Tab Section
local MainSection = MainTab:AddSection("Main Features")

MainSection:AddToggle("Auto Steal", autoStealEnabled):OnChanged(function(value)
    autoStealEnabled = value
end)

-- Collect base names for dropdown
local baseNames = {}
for _, base in pairs(Workspace.Plots:GetChildren()) do
    if base:FindFirstChild("DeliveryHitbox") then
        table.insert(baseNames, base.Name)
    end
end
table.sort(baseNames)

local baseDropdown = MainSection:AddDropdown("Select Base", baseNames, baseNames[1] or "No Bases Found"):OnChanged(function(option)
    selectedBase = Workspace.Plots:FindFirstChild(option)
end)

-- Initialize selectedBase on script load
if #baseNames > 0 then
    selectedBase = Workspace.Plots:FindFirstChild(baseNames[1])
end

MainSection:AddToggle("Auto Lock Base", autoLockBaseEnabled):OnChanged(function(value)
    autoLockBaseEnabled = value
end)

MainSection:AddButton("Teleport To Selected Base"):OnActivated(function()
    if selectedBase and character and rootPart then
        rootPart.CFrame = selectedBase.DeliveryHitbox.CFrame + Vector3.new(0,5,0)
        Fluent:Notify({
            Title = "Teleport",
            Content = "Teleported to selected base!",
            Duration = 3,
            Image = "rbxassetid://4483362458",
        })
    else
        Fluent:Notify({
            Title = "Teleport Error",
            Content = "No base selected or character not found.",
            Duration = 3,
            Image = "rbxassetid://4483362458",
        })
    end
end)

-- Fly Section
local FlySection = MainTab:AddSection("Fly Controls")

FlySection:AddToggle("Fly", flyEnabled):OnChanged(function(value)
    flyEnabled = value
    if value then
        startFly()
    else
        stopFly()
    end
end)

FlySection:AddSlider("Fly Speed", flySpeed, 10, 150, 1):OnChanged(function(value)
    flySpeed = value
end)

-- ESP Tab Section
local ESPSec = ESPTab:AddSection("Player ESP")

ESPSec:AddToggle("Toggle ESP", false):OnChanged(function(value)
    -- ESP is automatically updated by the Heartbeat connection
    updateAllESP() -- Trigger immediate update on toggle
end)

ESPSec:AddColorpicker("ESP Color", espColor):OnChanged(function(color)
    espColor = color
    updateAllESP() -- Apply new color to existing boxes
end)

-- Pet Finder Tab Section
local PetSec = PetFinderTab:AddSection("Pet Finder")

PetSec:AddToggle("Pet Finder Highlight", petFinderEnabled):OnChanged(function(value)
    petFinderEnabled = value
    updatePetHighlights() -- Trigger immediate update on toggle
end)

-- Misc Tab Section
local MiscSec = MiscTab:AddSection("Miscellaneous")

MiscSec:AddToggle("Noclip", noclipEnabled):OnChanged(function(value)
    toggleNoclip(value)
end)

MiscSec:AddToggle("Infinite Jump", infiniteJumpEnabled):OnChanged(function(value)
    infiniteJumpEnabled = value
end)

MiscSec:AddToggle("Anti Ragdoll", antiRagdollEnabled):OnChanged(function(value)
    antiRagdollEnabled = value
end)

-- Server Hop Tab Section
local ServerHopSec = Window:AddTab("Server Hop"):AddSection("Server Hopping")

ServerHopSec:AddButton("Server Hop (Find New Server)"):OnActivated(function()
    initiateServerHop()
end)

-- Final Polish and Cleanup
Fluent:Notify({
    Title = "Washedz Hub Loaded",
    Content = "Welcome! Press Right Shift to toggle UI.",
    Duration = 5,
    Image = "rbxassetid://4483362458", -- Example image for notification
})

-- Cleanup function to run when the script is disabled or game closes
local function cleanup()
    -- Disable all active features
    autoStealEnabled = false
    autoLockBaseEnabled = false
    infiniteJumpEnabled = false
    antiRagdollEnabled = false
    petFinderEnabled = false
    
    stopFly() -- Clean up fly system
    toggleNoclip(false) -- Disable noclip and restore collisions

    -- Clean up ESP boxes
    for _, box in pairs(espBoxes) do
        if box and box.Parent then box:Destroy() end
    end
    espBoxes = {}

    -- Clean up pet highlights
    for _, highlight in pairs(petHighlights) do
        if highlight and highlight.Parent then highlight:Destroy() end
    end
    petHighlights = {}

    -- Destroy custom PlayerInfoGui
    if PlayerInfoGui and PlayerInfoGui.Parent then
        PlayerInfoGui:Destroy()
    end

    -- Fluent UI handles its own cleanup when the script context is destroyed
    -- or if you explicitly call Fluent:Destroy()
end

game:BindToClose(cleanup)
