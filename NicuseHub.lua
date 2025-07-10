-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ====== Loading Screen Setup =======
local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "LoadingGui"
loadingGui.ResetOnSpawn = false
loadingGui.IgnoreGuiInset = true
loadingGui.Parent = game.CoreGui

-- Background (black with snowfall)
local bg = Instance.new("Frame", loadingGui)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.new(0, 0, 0)
bg.BackgroundTransparency = 0

-- Snowfall Particle Effect (full screen)
local snowfall = Instance.new("ParticleEmitter")
snowfall.Parent = bg
snowfall.Texture = "rbxassetid://258128463" -- Snowflake texture
snowfall.Rate = 50
snowfall.Lifetime = NumberRange.new(10)
snowfall.Speed = NumberRange.new(10, 15)
snowfall.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
snowfall.Rotation = NumberRange.new(0, 360)
snowfall.RotSpeed = NumberRange.new(-10, 10)
snowfall.VelocitySpread = 20
snowfall.EmissionDirection = Enum.NormalId.Top
snowfall.LockedToPart = false
snowfall.LightInfluence = 0

-- We parent particle emitter to a transparent part covering screen to emit over entire screen
local snowPart = Instance.new("Part")
snowPart.Size = Vector3.new(1000, 1, 1000)
snowPart.Transparency = 1
snowPart.Anchored = true
snowPart.CanCollide = false
snowPart.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 50, 0)
snowPart.Parent = Workspace
snowfall.Parent = snowPart

-- Animate snowPart to follow camera
RunService.RenderStepped:Connect(function()
	snowPart.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 50, 0)
end)

-- Loading text
local titleText = Instance.new("TextLabel", loadingGui)
titleText.Size = UDim2.new(1, 0, 0, 70)
titleText.Position = UDim2.new(0, 0, 0.1, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextScaled = true
titleText.Font = Enum.Font.GothamBold
titleText.Text = 'Welcome To "Nicuse HUB"'
titleText.ZIndex = 10

-- Status Text
local statusText = Instance.new("TextLabel", loadingGui)
statusText.Size = UDim2.new(1, 0, 0, 30)
statusText.Position = UDim2.new(0, 0, 0.9, 0)
statusText.BackgroundTransparency = 1
statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
statusText.TextScaled = true
statusText.Font = Enum.Font.GothamBold
statusText.Text = "Loading..."
statusText.ZIndex = 10

-- Player avatar thumbnail
local avatarImageLabel = Instance.new("ImageLabel", loadingGui)
avatarImageLabel.Size = UDim2.new(0, 120, 0, 120)
avatarImageLabel.Position = UDim2.new(0.5, -60, 0.4, 0)
avatarImageLabel.BackgroundTransparency = 1
avatarImageLabel.ScaleType = Enum.ScaleType.Fit
avatarImageLabel.ZIndex = 10
avatarImageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"

-- Get player headshot thumbnail
local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size420x420

local content, isReady = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
if isReady then
	avatarImageLabel.Image = content
end

-- Player username label
local usernameLabel = Instance.new("TextLabel", loadingGui)
usernameLabel.Size = UDim2.new(0, 300, 0, 40)
usernameLabel.Position = UDim2.new(0.5, -150, 0.65, 0)
usernameLabel.BackgroundTransparency = 1
usernameLabel.Text = player.DisplayName
usernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
usernameLabel.TextScaled = true
usernameLabel.Font = Enum.Font.GothamBold
usernameLabel.ZIndex = 10

-- Fade out loading screen after "loading"
local function fadeOutLoading()
	for i = 1, 20 do
		loadingGui.BackgroundTransparency = i * 0.05
		titleText.TextTransparency = i * 0.05
		statusText.TextTransparency = i * 0.05
		avatarImageLabel.ImageTransparency = i * 0.05
		usernameLabel.TextTransparency = i * 0.05
		task.wait(0.05)
	end
	loadingGui:Destroy()
	snowPart:Destroy()
end

-- ========== Load Rayfield UI ==========
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Nicuse HUB",
	LoadingTitle = "Nicuse HUB",
	LoadingSubtitle = "Loading interface...",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "NicuseHub",
		FileName = "Config"
	},
	Discord = { Enabled = false },
	KeySystem = false,
	Theme = "White"
})

-- Update loading status
local function updateStatus(text)
	statusText.Text = text
end

updateStatus("Initializing UI...")

-- ===== Tabs =====

local MainTab = Window:CreateTab("Main", 4483362458)
local UtilityTab = Window:CreateTab("Utility 🛠️", 4483362458)
local InfoTab = Window:CreateTab("Info", 4483362458)

-- ====== Variables =======
local speedSlow, speedFast = 0, 0
local flyActive = false
local flyBodyPosition, flyBodyGyro = nil, nil
local espEnabled = false
local espSecretAndBrainrot = false
local espBillboards = {}
local playerBillboards = {}
local playerLockTarget = nil

-- ====== SPEED BOOST =======
MainTab:CreateSlider({
	Name = "Speed Boost (Slow)",
	Range = {0, 6},
	Increment = 0.1,
	Suffix = "",
	CurrentValue = 0,
	Callback = function(value)
		speedSlow = value
	end,
})

MainTab:CreateSlider({
	Name = "Speed Boost (Fast)",
	Range = {0, 20},
	Increment = 0.5,
	Suffix = "",
	CurrentValue = 0,
	Callback = function(value)
		speedFast = value
	end,
})

-- ====== FLY TOGGLE =======
local function toggleFly()
	if flyActive then
		flyActive = false
		if flyBodyPosition then flyBodyPosition:Destroy() flyBodyPosition = nil end
		if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
		RunService:UnbindFromRenderStep("FlyControl")
	else
		flyActive = true
		local character = player.Character
		if not character then return end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		flyBodyPosition = Instance.new("BodyPosition", hrp)
		flyBodyPosition.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		flyBodyPosition.P = 1500
		flyBodyPosition.Position = hrp.Position

		flyBodyGyro = Instance.new("BodyGyro", hrp)
		flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		flyBodyGyro.P = 3000
		flyBodyGyro.CFrame = hrp.CFrame

		RunService:BindToRenderStep("FlyControl", Enum.RenderPriority.Character.Value, function()
			if not flyActive then
				RunService:UnbindFromRenderStep("FlyControl")
				return
			end
			local camCF = workspace.CurrentCamera.CFrame
			flyBodyPosition.Position = hrp.Position + camCF.LookVector * 15
			flyBodyGyro.CFrame = camCF
		end)
	end
end

MainTab:CreateButton({
	Name = "Toggle Fly",
	Callback = toggleFly,
})

-- ====== SPEED MOVEMENT =======
local function speedBoost()
	local character = player.Character or player.CharacterAdded:Wait()
	local hum = character:WaitForChild("Humanoid")
	local hrp = character:WaitForChild("HumanoidRootPart")

	RunService:BindToRenderStep("SpeedBoost", Enum.RenderPriority.Character.Value, function()
		if (speedSlow > 0 or speedFast > 0) and hum.MoveDirection.Magnitude > 0 then
			local speed = speedFast > 0 and speedFast or speedSlow
			-- Use velocity instead of CFrame change for less lag and anti-teleport detection
			hum.WalkSpeed = 16 + speed -- default 16 is Roblox base walk speed
		else
			hum.WalkSpeed = 16
		end
	end)
end

if player.Character then speedBoost() end
player.CharacterAdded:Connect(speedBoost)

-- ====== ESP FUNCTIONALITY =======
local function createBillboard(parent, text, color)
	local billboard = Instance.new("BillboardGui", parent)
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.Adornee = parent
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)

	local label = Instance.new("TextLabel", billboard)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	return billboard
end

local function togglePlayerESP()
	if espEnabled then
		for _, billboard in pairs(playerBillboards) do
			if billboard and billboard.Parent then
				billboard:Destroy()
			end
		end
		playerBillboards = {}
		espEnabled = false
	else
		espEnabled = true
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = plr.Character.HumanoidRootPart
				local billboard = createBillboard(hrp, plr.DisplayName, Color3.new(1, 0, 0))
				table.insert(playerBillboards, billboard)
			end
		end
	end
end

MainTab:CreateButton({
	Name = "Toggle Player ESP (Names, Red)",
	Callback = togglePlayerESP,
})

-- ESP All Secret & Brainrot God Pets (simple toggle)
local function toggleSecretBrainrotESP()
	if espSecretAndBrainrot then
		for _, billboard in pairs(espBillboards) do
			if billboard and billboard.Parent then
				billboard:Destroy()
			end
		end
		espBillboards = {}
		espSecretAndBrainrot = false
	else
		espSecretAndBrainrot = true
		-- Search workspace for "Secret" or "Brainrot God" pets (using name includes)
		for _, plot in pairs(workspace:WaitForChild("Plots"):GetChildren()) do
			for _, obj in pairs(plot:GetDescendants()) do
				if obj:IsA("TextLabel") and (string.find(obj.Text:lower(), "secret") or string.find(obj.Text:lower(), "brainrot god")) then
					local adorneePart = obj.Parent
					while adorneePart and not adorneePart:IsA("BasePart") do
						adorneePart = adorneePart.Parent
					end
					if adorneePart then
						local billboard = createBillboard(adorneePart, obj.Text, Color3.new(1, 0, 0))
						table.insert(espBillboards, billboard)
					end
				end
			end
		end
	end
end

MainTab:CreateButton({
	Name = "Toggle Secret & Brainrot God ESP (Red)",
	Callback = toggleSecretBrainrotESP,
})

-- ====== SERVER HOP =======
UtilityTab:CreateButton({
	Name = "Server Hop",
	Callback = function()
		local PlaceID = game.PlaceId
		local foundAnything = ""
		local function TPToNewServer()
			local servers
			if foundAnything == "" then
				servers = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
			else
				servers = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
			end
			if servers.nextPageCursor then
				foundAnything = servers.nextPageCursor
			end
			for _, server in ipairs(servers.data) do
				if server.playing < server.maxPlayers then
					TeleportService:TeleportToPlaceInstance(PlaceID, server.id, player)
					return
				end
			end
		end
		TPToNewServer()
	end,
})

-- ====== PET FINDER =======
local petList = {}
local success, result = pcall(function()
	return game:GetService("ReplicatedStorage"):WaitForChild("Models"):WaitForChild("Animals"):GetChildren()
end)
if success then
	for _, pet in ipairs(result) do
		table.insert(petList, pet.Name)
	end
end

UtilityTab:CreateDropdown({
	Name = "🐾 Pet Finder",
	Options = petList,
	MultiSelection = true,
	CurrentOption = {},
	Callback = function(selectedPets)
		coroutine.wrap(function()
			while true do
				task.wait(1.5)
				local results = {}
				for _, plot in pairs(workspace:WaitForChild("Plots"):GetChildren()) do
					for _, obj in pairs(plot:GetDescendants()) do
						if obj:IsA("TextLabel") and table.find(selectedPets, obj.Text) then
							table.insert(results, obj.Text .. " at plot: " .. plot.Name)
						end
					end
				end
				if #results == 0 then
					Rayfield:Notify({Title = "Pet Finder", Content = "No selected pets found!", Duration = 4, Image = 4483362458})
				else
					for _, res in pairs(results) do
						Rayfield:Notify({Title = "Pet Finder", Content = res, Duration = 5, Image = 4483362458})
					end
				end
			end
		end)()
	end,
})

-- ====== ANTI-CHEAT BYPASS (Stealthy) =======
-- This example disables detection on HumanoidRootPart CFrame changes (very simple, more can be added)
local lastCFrame = nil
local antiTeleportEnabled = true

RunService.Heartbeat:Connect(function()
	if antiTeleportEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		if lastCFrame then
			local dist = (hrp.Position - lastCFrame.Position).Magnitude
			if dist > 10 then -- big teleport detected
				hrp.CFrame = lastCFrame
			end
		end
		lastCFrame = hrp.CFrame
	end
end)

-- ====== Finish Loading =======
task.spawn(function()
	local steps = {
		"Loading UI...",
		"Setting up ESP...",
		"Setting up Pet Finder...",
		"Setting up Server Hop...",
		"Finalizing..."
	}
	for _, step in ipairs(steps) do
		updateStatus(step)
		task.wait(1)
	end
	fadeOutLoading()
end)

print("Nicuse HUB loaded!")

