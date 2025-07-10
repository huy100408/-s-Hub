-- Part 1/5: Setup, services, variables, Rayfield init & base UI

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

-- State Variables
local autoStealEnabled = false
local autoLockBaseEnabled = false
local noclipEnabled = false
local infiniteJumpEnabled = false
local flyEnabled = false
local antiRagdollEnabled = false
local petFinderEnabled = false

local flySpeed = 16 -- default fly speed low for anti-cheat
local selectedBase = nil

-- ESP Variables
local espEnabled = false
local espColor = Color3.fromRGB(255, 0, 0) -- red
local espBoxes = {}

-- Pet Finder list (example pets, add more as you like)
local petList = {
    "SecretPet1",
    "SecretPet2",
    "BrainrotGod",
    "PetA",
    "PetB"
}

-- Utility Functions
local function getPlayerAvatarThumbnail(player)
    local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size80x80)
    return content
end

-- Create Rayfield Window (white background, red accent)
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
    KeySystem = false, -- No key system
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

-- Small Player Avatar and Name UI (bottom left)
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "PlayerInfoGui"

local AvatarFrame = Instance.new("Frame", ScreenGui)
AvatarFrame.BackgroundTransparency = 0.2
AvatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AvatarFrame.BorderSizePixel = 1
AvatarFrame.Position = UDim2.new(0, 10, 1, -100)
AvatarFrame.Size = UDim2.new(0, 80, 0, 80)
AvatarFrame.ZIndex = 10

local AvatarImage = Instance.new("ImageLabel", AvatarFrame)
AvatarImage.Size = UDim2.new(1, 0, 1, 0)
AvatarImage.Position = UDim2.new(0,0,0,0)
AvatarImage.BackgroundTransparency = 1
AvatarImage.Image = getPlayerAvatarThumbnail(localPlayer)

local UsernameLabel = Instance.new("TextLabel", ScreenGui)
UsernameLabel.Position = UDim2.new(0, 10, 1, -20)
UsernameLabel.Size = UDim2.new(0, 80, 0, 20)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.TextColor3 = Color3.fromRGB(0,0,0)
UsernameLabel.Font = Enum.Font.Gotham
UsernameLabel.TextSize = 14
UsernameLabel.Text = localPlayer.Name
UsernameLabel.TextWrapped = true
UsernameLabel.ZIndex = 10

-- Update avatar & name on respawn
localPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    AvatarImage.Image = getPlayerAvatarThumbnail(localPlayer)
    UsernameLabel.Text = localPlayer.Name
end)

-- Part 2/5: ESP, Auto Steal, Auto Lock Base, Noclip & Infinite Jump

-- ======= ESP =======
local function createESPBox(player)
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESPBox"
    box.Adornee = nil
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Transparency = 0.5
    box.Color3 = espColor
    box.Size = Vector3.new(4, 6, 4) -- approx player size
    box.Parent = game.CoreGui
    return box
end

local function updateESP()
    -- Clear old boxes
    for _, box in pairs(espBoxes) do
        if box and box.Parent then box:Destroy() end
    end
    espBoxes = {}

    if not espEnabled then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local box = createESPBox(plr.Character.HumanoidRootPart)
            box.Adornee = plr.Character.HumanoidRootPart
            table.insert(espBoxes, box)
        end
    end
end

-- Update ESP every 1 second
task.spawn(function()
    while true do
        task.wait(1)
        pcall(updateESP)
    end
end)

-- ======= Auto Steal =======
local function autoSteal()
    if not autoStealEnabled then return end
    local plrChar = localPlayer.Character
    if not plrChar or not plrChar:FindFirstChild("HumanoidRootPart") then return end

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

-- Auto steal loop
task.spawn(function()
    while true do
        task.wait(3) -- wait 3 seconds to reduce anticheat suspicion
        if autoStealEnabled then
            pcall(autoSteal)
        end
    end
end)

-- ======= Auto Lock Base =======
local function autoLockBase()
    if not autoLockBaseEnabled or not selectedBase then return end
    local plrChar = localPlayer.Character
    if not plrChar or not plrChar:FindFirstChild("HumanoidRootPart") then return end

    -- Teleport to base (fly to base)
    local targetPos = selectedBase.DeliveryHitbox.Position + Vector3.new(0,5,0)
    pcall(function()
        plrChar.HumanoidRootPart.CFrame = CFrame.new(targetPos)
    end)
end

task.spawn(function()
    while true do
        task.wait(1.5)
        if autoLockBaseEnabled then
            pcall(autoLockBase)
        end
    end
end)

-- ======= Noclip & Infinite Jump =======
local function noclipToggle(state)
    noclipEnabled = state
    if noclipEnabled then
        RunService.Stepped:Connect(function()
            if noclipEnabled then
                for _, part in pairs(localPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        -- Reset CanCollide when disabled
        for _, part in pairs(localPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Infinite Jump Handler
local function onJumpRequest()
    if infiniteJumpEnabled then
        local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

UserInputService.JumpRequest:Connect(onJumpRequest)

-- Disable noclip on respawn
localPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if noclipEnabled then noclipToggle(false) end
end)

-- ======= UI Toggles & Controls =======
MainTab:CreateToggle({
    Name = "Auto Steal",
    CurrentValue = false,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
    end,
})

MainTab:CreateToggle({
    Name = "Auto Lock Base",
    CurrentValue = false,
    Flag = "AutoLockBaseToggle",
    Callback = function(value)
        autoLockBaseEnabled = value
    end,
})

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(value)
        noclipToggle(value)
    end,
})

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = function(value)
        infiniteJumpEnabled = value
    end,
})

MainTab:CreateToggle({
    Name = "Anti Ragdoll",
    CurrentValue = false,
    Flag = "AntiRagdollToggle",
    Callback = function(value)
        antiRagdollEnabled = value
    end,
})

-- Base selection dropdown
local baseNames = {}
for _, base in pairs(Workspace.Plots:GetChildren()) do
    if base:FindFirstChild("DeliveryHitbox") then
        table.insert(baseNames, base.Name)
    end
end

MainTab:CreateDropdown({
    Name = "Select Base",
    Options = baseNames,
    CurrentOption = baseNames[1],
    Flag = "BaseSelectDropdown",
    Callback = function(option)
        selectedBase = Workspace.Plots:FindFirstChild(option)
    end,
})

-- Teleport To Base Button
MainTab:CreateButton({
    Name = "Teleport To Base",
    Callback = function()
        if selectedBase and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            localPlayer.Character.HumanoidRootPart.CFrame = selectedBase.DeliveryHitbox.CFrame + Vector3.new(0,5,0)
        end
    end,
})

-- Part 3/5: Fly, ESP UI, Pet Finder, Server Hop

-- ======= Fly System =======
local flySpeed = 50 -- default speed, adjustable by slider
local flying = false
local bodyVelocity = nil
local bodyGyro = nil

local function startFly()
    if flying or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    flying = true
    local hrp = localPlayer.Character.HumanoidRootPart

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    local input = {W=false, A=false, S=false, D=false, Q=false, E=false}

    local function updateFly()
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
            moveDirection = moveDirection + Vector3.new(0,1,0)
        end
        if input.E then
            moveDirection = moveDirection - Vector3.new(0,1,0)
        end

        bodyVelocity.Velocity = moveDirection.Unit * flySpeed
        bodyGyro.CFrame = camCF
    end

    local connection1, connection2

    connection1 = UserInputService.InputBegan:Connect(function(inputObj, gameProcessed)
        if gameProcessed then return end
        if inputObj.KeyCode == Enum.KeyCode.W then input.W = true end
        if inputObj.KeyCode == Enum.KeyCode.A then input.A = true end
        if inputObj.KeyCode == Enum.KeyCode.S then input.S = true end
        if inputObj.KeyCode == Enum.KeyCode.D then input.D = true end
        if inputObj.KeyCode == Enum.KeyCode.Q then input.Q = true end
        if inputObj.KeyCode == Enum.KeyCode.E then input.E = true end
        updateFly()
    end)

    connection2 = UserInputService.InputEnded:Connect(function(inputObj, gameProcessed)
        if inputObj.KeyCode == Enum.KeyCode.W then input.W = false end
        if inputObj.KeyCode == Enum.KeyCode.A then input.A = false end
        if inputObj.KeyCode == Enum.KeyCode.S then input.S = false end
        if inputObj.KeyCode == Enum.KeyCode.D then input.D = false end
        if inputObj.KeyCode == Enum.KeyCode.Q then input.Q = false end
        if inputObj.KeyCode == Enum.KeyCode.E then input.E = false end
        updateFly()
    end)

    -- Fly update loop
    spawn(function()
        while flying do
            updateFly()
            task.wait()
        end
    end)

    return function()
        flying = false
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        connection1:Disconnect()
        connection2:Disconnect()
    end
end

local stopFlyFunc = nil

MainTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(value)
        if value then
            stopFlyFunc = startFly()
        else
            if stopFlyFunc then stopFlyFunc() end
        end
    end,
})

MainTab:CreateSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 150,
    Default = 50,
    Increment = 1,
    Flag = "FlySpeedSlider",
    Callback = function(value)
        flySpeed = value
    end,
})

-- ======= ESP Tab UI =======
ESPTab:CreateToggle({
    Name = "Toggle ESP",
    CurrentValue = espEnabled,
    Flag = "ESPToggle",
    Callback = function(value)
        espEnabled = value
        updateESP()
    end,
})

ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Default = espColor,
    Flag = "ESPColorPicker",
    Callback = function(color)
        espColor = color
        updateESP()
    end,
})

-- ======= Pet Finder =======
local function findPets()
    for _, pet in pairs(Workspace.Pets:GetChildren()) do
        if pet:FindFirstChild("HumanoidRootPart") then
            -- Highlight pet (could create a BillboardGui or Box)
            -- Simple example: change color
            if pet:FindFirstChildWhichIsA("BasePart") then
                pet:FindFirstChildWhichIsA("BasePart").Color = Color3.fromRGB(0,255,0)
            end
        end
    end
end

PetTab:CreateButton({
    Name = "Find Pets",
    Callback = function()
        findPets()
    end,
})

-- ======= Server Hop =======
ServerTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local PlaceId = game.PlaceId
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local Servers = {}

        local function getServers(cursor)
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
            if cursor then
                url = url .. "&cursor=" .. cursor
            end
            local response = game:HttpGet(url)
            return HttpService:JSONDecode(response)
        end

        spawn(function()
            local cursor = nil
            while true do
                local data = getServers(cursor)
                if data and data.data then
                    for _, server in pairs(data.data) do
                        if server.playing < server.maxPlayers then
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
            else
                warn("No available servers found.")
            end
        end)
    end,
})

-- Part 4/5: Player avatar UI, Anti Ragdoll, Noclip, Infinite Jump, Teleport to Base

-- ======= Player Avatar and Username UI =======
local function createPlayerInfoUI()
    local infoFrame = Rayfield:CreateWindow({
        Name = "Player Info",
        LoadingTitle = "Loading Player Data...",
        LoadingSubtitle = "Please wait",
        ConfigurationSaving = {
            Enabled = false,
        },
        IntroEnabled = false,
        IntroText = "",
        IntroImage = "",
        HidePremium = true,
    })

    local infoTab = infoFrame:CreateTab("Info")

    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. localPlayer.UserId .. "&width=80&height=80&format=png"
    local avatarLabel = infoTab:CreateLabel("Avatar & Name")

    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(0, 80, 0, 80)
    avatarImage.Position = UDim2.new(0, 10, 0, 10)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = avatarUrl
    avatarImage.Parent = infoTab.Content

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 150, 0, 20)
    nameLabel.Position = UDim2.new(0, 100, 0, 35)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.Text = localPlayer.Name
    nameLabel.Parent = infoTab.Content

    -- Keep small, positioned bottom-left or bottom center of screen, adjust as needed
    infoFrame:SetVisible(false)
    return infoFrame
end

local playerInfoUI = createPlayerInfoUI()
playerInfoUI:SetVisible(true)

-- ======= Anti Ragdoll =======
local antiragdoll = false
MainTab:CreateToggle({
    Name = "Anti Ragdoll",
    CurrentValue = false,
    Flag = "AntiRagdollToggle",
    Callback = function(value)
        antiragdoll = value
    end,
})

game:GetService("RunService").Stepped:Connect(function()
    if antiragdoll and localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll or humanoid:GetState() == Enum.HumanoidStateType.Physics then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)

-- ======= Noclip =======
local noclipEnabled = false
MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(value)
        noclipEnabled = value
    end,
})

local function noclipLoop()
    game:GetService("RunService").Stepped:Connect(function()
        if noclipEnabled and localPlayer.Character then
            for _, part in pairs(localPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        elseif localPlayer.Character then
            for _, part in pairs(localPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)
end

noclipLoop()

-- Disable noclip on respawn to avoid detection
localPlayer.CharacterAdded:Connect(function(character)
    noclipEnabled = false
end)

-- ======= Infinite Jump =======
local infiniteJumpEnabled = false
MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = function(value)
        infiniteJumpEnabled = value
    end,
})

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
            localPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ======= Teleport To Base =======
local teleportToBaseEnabled = false
MainTab:CreateToggle({
    Name = "Teleport to Base",
    CurrentValue = false,
    Flag = "TeleportToBaseToggle",
    Callback = function(value)
        teleportToBaseEnabled = value
    end,
})

task.spawn(function()
    while task.wait(0.1) do
        if teleportToBaseEnabled and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local base = nil
            for _, plot in pairs(workspace.Plots:GetChildren()) do
                if plot:FindFirstChild("YourBase", true) and plot:FindFirstChild("YourBase", true).Enabled then
                    base = plot:FindFirstChild("DeliveryHitbox")
                end
            end
            if base then
                local hrp = localPlayer.Character.HumanoidRootPart
                hrp.CFrame = CFrame.new(base.Position.X, hrp.Position.Y, base.Position.Z)
            end
        end
    end
end)

-- Part 5/5: Pet Finder, Server Hop, ESP, Auto Steal, Fly Speed slider, UI polish and cleanup

-- ======= Pet Finder =======
local petFinderEnabled = false
MainTab:CreateToggle({
    Name = "Pet Finder",
    CurrentValue = false,
    Flag = "PetFinderToggle",
    Callback = function(value)
        petFinderEnabled = value
    end,
})

local function highlightPets()
    for _, pet in pairs(workspace.Pets:GetChildren()) do
        if pet:IsA("Model") and pet:FindFirstChild("HumanoidRootPart") then
            if petFinderEnabled then
                if not pet:FindFirstChild("Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "Highlight"
                    hl.Adornee = pet
                    hl.FillColor = Color3.new(1, 0, 0)
                    hl.OutlineColor = Color3.new(1, 1, 1)
                    hl.Parent = pet
                end
            else
                local hl = pet:FindFirstChild("Highlight")
                if hl then hl:Destroy() end
            end
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        highlightPets()
    end
end)

-- ======= Server Hop =======
local serverHopEnabled = false
MainTab:CreateToggle({
    Name = "Server Hop",
    CurrentValue = false,
    Flag = "ServerHopToggle",
    Callback = function(value)
        serverHopEnabled = value
        if serverHopEnabled then
            -- Simple server hop by teleporting to same place
            local TeleportService = game:GetService("TeleportService")
            local PlaceId = game.PlaceId
            TeleportService:Teleport(PlaceId, localPlayer)
        end
    end,
})

-- ======= ESP =======
local espEnabled = false
MainTab:CreateToggle({
    Name = "ESP (All Except You)",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(value)
        espEnabled = value
        if espEnabled then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= localPlayer then
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        if not player.Character:FindFirstChild("ESPBox") then
                            local box = Instance.new("BoxHandleAdornment")
                            box.Name = "ESPBox"
                            box.Adornee = player.Character.HumanoidRootPart
                            box.AlwaysOnTop = true
                            box.ZIndex = 10
                            box.Size = Vector3.new(4, 6, 4)
                            box.Transparency = 0.5
                            box.Color3 = Color3.new(1, 0, 0)
                            box.Parent = player.Character.HumanoidRootPart
                        end
                    end
                end
            end
        else
            for _, player in pairs(game.Players:GetPlayers()) do
                if player.Character then
                    local box = player.Character:FindFirstChild("ESPBox")
                    if box then
                        box:Destroy()
                    end
                end
            end
        end
    end,
})

game.Players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= localPlayer then
        player.CharacterAdded:Connect(function(char)
            task.wait(1)
            if char:FindFirstChild("HumanoidRootPart") and not char:FindFirstChild("ESPBox") then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ESPBox"
                box.Adornee = char.HumanoidRootPart
                box.AlwaysOnTop = true
                box.ZIndex = 10
                box.Size = Vector3.new(4, 6, 4)
                box.Transparency = 0.5
                box.Color3 = Color3.new(1, 0, 0)
                box.Parent = char.HumanoidRootPart
            end
        end)
    end
end)

-- ======= Auto Steal =======
local autoStealEnabled = false
MainTab:CreateToggle({
    Name = "Auto Steal",
    CurrentValue = false,
    Flag = "AutoStealToggle",
    Callback = function(value)
        autoStealEnabled = value
    end,
})

-- Basic auto steal logic, steal pets from nearby bases after selecting a base
task.spawn(function()
    while task.wait(1) do
        if autoStealEnabled and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, plot in pairs(workspace.Plots:GetChildren()) do
                if plot:FindFirstChild("YourBase", true) and plot:FindFirstChild("YourBase", true).Enabled then
                    -- Steal from others (simple example)
                    local stealEvent = game.ReplicatedStorage.Packages.Net:FindFirstChild("RE/StealService/DeliverySteal")
                    if stealEvent then
                        pcall(function()
                            stealEvent:FireServer()
                        end)
                    end
                end
            end
        end
    end
end)

-- ======= Fly Speed Slider =======
local flySpeed = 16
MainTab:CreateSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 100,
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = flySpeed,
    Flag = "FlySpeedSlider",
    Callback = function(value)
        flySpeed = value
    end,
})

-- ======= Fly Feature =======
local flying = false
local flightBodyVelocity = nil
local flightBodyGyro = nil

local function startFly()
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        flightBodyVelocity = Instance.new("BodyVelocity")
        flightBodyVelocity.Velocity = Vector3.new(0,0,0)
        flightBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flightBodyVelocity.Parent = hrp

        flightBodyGyro = Instance.new("BodyGyro")
        flightBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flightBodyGyro.Parent = hrp
    end
end

local function stopFly()
    if flightBodyVelocity then
        flightBodyVelocity:Destroy()
        flightBodyVelocity = nil
    end
    if flightBodyGyro then
        flightBodyGyro:Destroy()
        flightBodyGyro = nil
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.E then
            flying = not flying
            if flying then
                startFly()
            else
                stopFly()
            end
        end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if flying and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = localPlayer.Character.HumanoidRootPart
        local direction = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + workspace.CurrentCamera.CFrame.RightVector
        end
        direction = Vector3.new(direction.X, 0, direction.Z).Unit * flySpeed
        flightBodyVelocity.Velocity = direction + Vector3.new(0, 0, 0)
        flightBodyGyro.CFrame = workspace.CurrentCamera.CFrame
    end
end)

-- ======= UI Polish =======
Rayfield:Notify({
    Title = "Loaded",
    Content = "Welcome to Hub Name!",
    Duration = 5,
    Image = 4483362458,
})

-- ======= Cleanup =======
local function cleanup()
    flying = false
    stopFly()
    espEnabled = false
    petFinderEnabled = false
    autoStealEnabled = false
    serverHopEnabled = false
    noclipEnabled = false
    infiniteJumpEnabled = false
    teleportToBaseEnabled = false
    antiragdoll = false
    playerInfoUI:SetVisible(false)
end

-- Call cleanup on unload if needed
game:BindToClose(cleanup)
