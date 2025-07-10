-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Rayfield Library Load
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/venixgg/Rayfield/main/source"))()

-- State Variables (Centralized)
local autoStealEnabled = false
local autoLockBaseEnabled = false
local noclipEnabled = false
local infiniteJumpEnabled = false
local flyEnabled = false
local antiRagdollEnabled = false
local petFinderEnabled = false

local flySpeed = 50 -- Default fly speed
local selectedBase = nil

-- ESP Variables
local espEnabled = false
local espColor = Color3.fromRGB(255, 0, 0) -- red
local espBoxes = {} -- Store ESP box references

-- Pet Finder list (example pets, add more as you like)
local petList = {
    "SecretPet1",
    "SecretPet2",
    "BrainrotGod",
    "PetA",
    "PetB"
}

--- Utility Functions
local function getPlayerAvatarThumbnail(player)
    -- Asynchronously get thumbnail, but for simplicity, we'll return the standard URL
    -- Rayfield's ImageLabel might handle this better directly with the URL format
    return "rbxthumb://v1/users/headshot?id=" .. player.UserId .. "&w=80&h=80&format=png"
end

--- Rayfield UI Setup
local Window = Rayfield:CreateWindow({
    Name = "YourHubName",
    LoadingTitle = "Welcome To YourHubName",
    LoadingSubtitle = "Loading features...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "YourHubNameConfig",
        FileName = "UserConfig",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
    IntroEnabled = false,
    SaveConfig = true,
    Theme = {
        Background = Color3.fromRGB(255,255,255),
        Accent = Color3.fromRGB(255,0,0),
        SectionBackground = Color3.fromRGB(245,245,245),
        Toggle = Color3.fromRGB(255,0,0),
        ToggleBackground = Color3.fromRGB(255,255,255),
        TextBoxBackground = Color3.fromRGB(255,255,255),
        TextColor = Color3.fromRGB(0,0,0),
    }
})

-- Create Tabs
local MainTab = Window:CreateTab("Main")
local ESPTab = Window:CreateTab("ESP")
local MiscTab = Window:CreateTab("Misc")
local PetFinderTab = Window:CreateTab("Pet Finder")
local ServerHopTab = Window:CreateTab("Server Hop")

--- Small Player Avatar and Name UI (bottom left)
-- Using a standard ScreenGui as Rayfield is for the main hub.
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
end)

--- Feature Implementations

-- ======= ESP =======
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
        box.Transparency = 0.5
        box.Size = Vector3.new(4, 6, 4) -- approx player size
        box.Parent = game.CoreGui -- Parent to CoreGui for better visibility and persistence
        espBoxes[player.UserId] = box
    end
    box.Color3 = espColor
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
            if espEnabled then
                createOrUpdateESPBox(plr)
            else
                removeESPBox(plr)
            end
        else
            removeESPBox(plr) -- Clean up if player character is gone
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

-- Periodically update ESP
RunService.Stepped:Connect(function()
    if espEnabled then
        updateAllESP()
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if espEnabled and player ~= localPlayer then
            createOrUpdateESPBox(player)
        end
    end)
    if espEnabled and player ~= localPlayer and player.Character then
        createOrUpdateESPBox(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPBox(player)
end)

-- ======= Auto Steal =======
local function autoStealLoop()
    while true do
        task.wait(3) -- Wait 3 seconds to reduce anticheat suspicion
        if autoStealEnabled then
            local plrChar = localPlayer.Character
            if plrChar and plrChar:FindFirstChild("HumanoidRootPart") then
                local hrp = plrChar.HumanoidRootPart
                for _, plot in pairs(Workspace.Plots:GetChildren()) do
                    if plot:FindFirstChild("AnimalPodiums") then
                        for _, podium in pairs(plot.AnimalPodiums:GetChildren()) do
                            local dist = (podium:GetPivot().Position - hrp.Position).Magnitude
                            if dist < 20 then -- 20 studs range to steal
                                pcall(function()
                                    ReplicatedStorage.Packages.Net["RE/StealService/DeliverySteal"]:FireServer()
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end
task.spawn(autoStealLoop)

-- ======= Auto Lock Base =======
local function autoLockBaseLoop()
    while true do
        task.wait(1.5)
        if autoLockBaseEnabled and selectedBase and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local plrChar = localPlayer.Character
            local targetPos = selectedBase.DeliveryHitbox.Position + Vector3.new(0,5,0)
            pcall(function()
                plrChar.HumanoidRootPart.CFrame = CFrame.new(targetPos)
            end)
        end
    end
end
task.spawn(autoLockBaseLoop)

-- ======= Noclip =======
local noclipConnection = nil

local function toggleNoclip(state)
    noclipEnabled = state
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    if noclipEnabled then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = localPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        })
    else
        local char = localPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Disable noclip on respawn
localPlayer.CharacterAdded:Connect(function(char)
    if noclipEnabled then
        toggleNoclip(false) -- Force disable on respawn
        -- Update UI toggle visually if Rayfield allows
        -- Rayfield's toggle state might need to be set programmatically here
    end
end)

-- ======= Infinite Jump =======
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ======= Anti Ragdoll =======
RunService.Stepped:Connect(function()
    if antiRagdollEnabled and localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll or humanoid:GetState() == Enum.HumanoidStateType.Physics then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)

-- ======= Fly System =======
local flightBodyVelocity = nil
local flightBodyGyro = nil
local flyConnections = {}

local function startFly()
    if flying or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    flying = true
    local hrp = localPlayer.Character.HumanoidRootPart

    localPlayer.Character.Humanoid.PlatformStand = true -- Prevent walking/falling

    flightBodyVelocity = Instance.new("BodyVelocity")
    flightBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flightBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flightBodyVelocity.Parent = hrp

    flightBodyGyro = Instance.new("BodyGyro")
    flightBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flightBodyGyro.CFrame = hrp.CFrame
    flightBodyGyro.Parent = hrp

    local input = {W=false, A=false, S=false, D=false, Q=false, E_Up=false, E_Toggle=false} -- Renamed E to E_Up to avoid conflict with toggle key

    flyConnections.inputBegan = UserInputService.InputBegan:Connect(function(inputObj, gameProcessed)
        if gameProcessed then return end
        if inputObj.KeyCode == Enum.KeyCode.W then input.W = true end
        if inputObj.KeyCode == Enum.KeyCode.A then input.A = true end
        if inputObj.KeyCode == Enum.KeyCode.S then input.S = true end
        if inputObj.KeyCode == Enum.KeyCode.D then input.D = true end
        if inputObj.KeyCode == Enum.KeyCode.Q then input.Q = true end
        if inputObj.KeyCode == Enum.KeyCode.E then input.E_Up = true end -- E for upward movement
    end)

    flyConnections.inputEnded = UserInputService.InputEnded:Connect(function(inputObj, gameProcessed)
        if inputObj.KeyCode == Enum.KeyCode.W then input.W = false end
        if inputObj.KeyCode == Enum.KeyCode.A then input.A = false end
        if inputObj.KeyCode == Enum.KeyCode.S then input.S = false end
        if inputObj.KeyCode == Enum.KeyCode.D then input.D = false end
        if inputObj.KeyCode == Enum.KeyCode.Q then input.Q = false end
        if inputObj.KeyCode == Enum.KeyCode.E then input.E_Up = false end
    end)

    flyConnections.heartbeat = RunService.Heartbeat:Connect(function()
        if not flying then return end
        local moveDirection = Vector3.new(0,0,0)
        local camCF = workspace.CurrentCamera.CFrame

        if input.W then
            moveDirection = moveDirection + camCF.LookVector
        end
        if input.S then
            moveDirection = moveDirection - camCF.LookVector
        end
        if input.A then
            moveDirection = moveDirection - camCF.RightVector
        end
        if input.D then
            moveDirection = moveDirection + camCF.RightVector
        end
        if input.Q then
            moveDirection = moveDirection + Vector3.new(0,1,0) -- Up
        end
        if input.E_Up then -- E for downward movement
            moveDirection = moveDirection - Vector3.new(0,1,0) -- Down
        end

        flightBodyVelocity.Velocity = moveDirection.Unit * flySpeed
        flightBodyGyro.CFrame = camCF
    end)
end

local function stopFly()
    flying = false
    if flightBodyVelocity then flightBodyVelocity:Destroy() end
    if flightBodyGyro then flightBodyGyro:Destroy() end
    for _, conn in pairs(flyConnections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    flyConnections = {}
    if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
        localPlayer.Character.Humanoid.PlatformStand = false -- Re-enable walking/falling
    end
end

-- Toggle with UI or keybind if desired (here we tie to UI toggle)
localPlayer.CharacterAdded:Connect(function(char)
    -- On respawn, ensure fly is off and components are removed
    if flying then
        stopFly()
        -- Ensure the UI toggle also updates if it's still active from previous life
        -- This might require a direct update to the Rayfield toggle if it persists its state
    end
end)

-- ======= Pet Finder =======
local petHighlights = {} -- Store highlight references

local function updatePetHighlights()
    for _, pet in pairs(Workspace.Pets:GetChildren()) do
        if pet:IsA("Model") and pet:FindFirstChild("HumanoidRootPart") then
            if petFinderEnabled then
                local highlight = petHighlights[pet.Name]
                if not highlight or not highlight.Parent then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "Highlight"
                    highlight.Adornee = pet
                    highlight.FillColor = Color3.new(0, 1, 0) -- Green for pets
                    highlight.OutlineColor = Color3.new(1, 1, 1)
                    highlight.Parent = pet
                    petHighlights[pet.Name] = highlight
                end
            else
                local highlight = petHighlights[pet.Name]
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
                petHighlights[pet.Name] = nil
            end
        end
    end

    -- Clean up highlights for pets that are no longer in workspace.Pets
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
RunService.Stepped:Connect(function()
    if petFinderEnabled then
        updatePetHighlights()
    end
end)

-- ======= Server Hop =======
local function initiateServerHop()
    local PlaceId = game.PlaceId
    local Servers = {}

    local function getServers(cursor)
        local success, result = pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
            if cursor then
                url = url .. "&cursor=" .. cursor
            end
            local response = game:HttpGet(url)
            return HttpService:JSONDecode(response)
        end)
        if not success then
            warn("Failed to get servers:", result)
            return nil
        end
        return result
    end

    spawn(function()
        local cursor = nil
        while true do
            local data = getServers(cursor)
            if data and data.data then
                for _, server in pairs(data.data) do
                    -- Only consider servers that are not full and not the current server
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(Servers, server.id)
                    end
                end
                cursor = data.nextPageCursor
                if not cursor then break end
            else
                break
            end
        end

        if #Servers > 0 then
            local serverToJoin = Servers[math.random(1, #Servers)]
            TeleportService:TeleportToPlaceInstance(PlaceId, serverToJoin, localPlayer)
            Rayfield:Notify({
                Title = "Server Hop",
                Content = "Attempting to hop to a new server...",
                Duration = 5,
                Image = 4483362458,
            })
        else
            warn("No available servers found for hopping.")
            Rayfield:Notify({
                Title = "Server Hop Failed",
                Content = "No available servers found.",
                Duration = 5,
                Image = 4483362458,
            })
        end
    end)
end

--- Rayfield UI Controls

-- Main Tab
MainTab:CreateToggle({
    Name = "Auto Steal",
    CurrentValue = autoStealEnabled,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
    end,
})

-- Base selection dropdown (populate only once or refresh if bases change dynamically)
local baseNames = {}
for _, base in pairs(Workspace.Plots:GetChildren()) do
    if base:FindFirstChild("DeliveryHitbox") then
        table.insert(baseNames, base.Name)
    end
end
table.sort(baseNames) -- Sort alphabetically

MainTab:CreateDropdown({
    Name = "Select Base",
    Options = baseNames,
    CurrentOption = baseNames[1] or "No Bases Found",
    Flag = "BaseSelectDropdown",
    Callback = function(option)
        selectedBase = Workspace.Plots:FindFirstChild(option)
    end,
})

-- Initialize selectedBase with the default option
if #baseNames > 0 then
    selectedBase = Workspace.Plots:FindFirstChild(baseNames[1])
end

MainTab:CreateToggle({
    Name = "Auto Lock Base",
    CurrentValue = autoLockBaseEnabled,
    Flag = "AutoLockBaseToggle",
    Callback = function(value)
        autoLockBaseEnabled = value
    end,
})

MainTab:CreateButton({
    Name = "Teleport To Selected Base",
    Callback = function()
        if selectedBase and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            localPlayer.Character.HumanoidRootPart.CFrame = selectedBase.DeliveryHitbox.CFrame + Vector3.new(0,5,0)
        else
            Rayfield:Notify({
                Title = "Teleport Error",
                Content = "No base selected or character not found.",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = noclipEnabled,
    Flag = "NoclipToggle",
    Callback = function(value)
        toggleNoclip(value)
    end,
})

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = infiniteJumpEnabled,
    Flag = "InfiniteJumpToggle",
    Callback = function(value)
        infiniteJumpEnabled = value
    end,
})

MainTab:CreateToggle({
    Name = "Anti Ragdoll",
    CurrentValue = antiRagdollEnabled,
    Flag = "AntiRagdollToggle",
    Callback = function(value)
        antiRagdollEnabled = value
    end,
})

MainTab:CreateToggle({
    Name = "Fly",
    CurrentValue = flyEnabled,
    Flag = "FlyToggle",
    Callback = function(value)
        flyEnabled = value
        if value then
            startFly()
        else
            stopFly()
        end
    end,
})

MainTab:CreateSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 150,
    Default = flySpeed,
    Increment = 1,
    Flag = "FlySpeedSlider",
    Callback = function(value)
        flySpeed = value
    end,
})

-- ESP Tab
ESPTab:CreateToggle({
    Name = "Toggle ESP",
    CurrentValue = espEnabled,
    Flag = "ESPToggle",
    Callback = function(value)
        espEnabled = value
        updateAllESP() -- Trigger an immediate update
    end,
})

ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Default = espColor,
    Flag = "ESPColorPicker",
    Callback = function(color)
        espColor = color
        updateAllESP() -- Apply new color to existing boxes
    end,
})

-- Pet Finder Tab
PetFinderTab:CreateToggle({
    Name = "Enable Pet Finder Highlight",
    CurrentValue = petFinderEnabled,
    Flag = "PetFinderToggle",
    Callback = function(value)
        petFinderEnabled = value
        updatePetHighlights() -- Trigger an immediate update
    end,
})

-- Server Hop Tab
ServerHopTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        initiateServerHop()
    end,
})

--- UI Polish and Cleanup
Rayfield:Notify({
    Title = "YourHubName Loaded",
    Content = "Welcome! All features are ready.",
    Duration = 5,
    Image = 4483362458, -- Placeholder image, replace with your own
})

local function cleanup()
    -- Stop all active loops and remove created instances
    stopFly()
    toggleNoclip(false)
    espEnabled = false
    updateAllESP() -- Clean up ESP boxes
    petFinderEnabled = false
    updatePetHighlights() -- Clean up pet highlights

    -- Destroy custom UI elements
    if PlayerInfoGui and PlayerInfoGui.Parent then
        PlayerInfoGui:Destroy()
    end

    -- Rayfield UI will handle its own cleanup on close/unload
end

-- Bind cleanup to game close
game:BindToClose(cleanup)
