-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local ServerTab = Window:CreateTab("Server & Pets", 4483362458)


local avatarImageLabel = Instance.new("ImageLabel", loadingGui)
avatarImageLabel.Size = UDim2.new(0, 100, 0, 100)
avatarImageLabel.Position = UDim2.new(1, -110, 1, -110)
avatarImageLabel.BackgroundTransparency = 1
avatarImageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
avatarImageLabel.ScaleType = Enum.ScaleType.Fit
avatarImageLabel.ZIndex = 10

local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size100x100

local content, isReady = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
if isReady then
	avatarImageLabel.Image = content
end

-- Loading Screen (Black & Gold, shaking)
local loadingGui = Instance.new("ScreenGui", game.CoreGui)
loadingGui.IgnoreGuiInset = true
loadingGui.ResetOnSpawn = false

local backgroundImage = Instance.new("ImageLabel", loadingGui)
backgroundImage.Size = UDim2.new(1, 0, 1, 0)
backgroundImage.Position = UDim2.new(0, 0, 0, 0)
backgroundImage.BackgroundTransparency = 1
backgroundImage.Image = "rbxassetid://86086568995775"
backgroundImage.ScaleType = Enum.ScaleType.Crop
backgroundImage.ZIndex = 0


local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(0, 300, 0, 50)
title.Position = UDim2.new(0.5, -150, 0.5, -50)
title.BackgroundTransparency = 1
title.Text = "🔥 WELCOME 🔥"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextScaled = true
title.Font = Enum.Font.GothamBold

local usernameLabel = Instance.new("TextLabel", frame)
usernameLabel.Size = UDim2.new(0, 300, 0, 50)
usernameLabel.Position = UDim2.new(0.5, -150, 0.5, 10)
usernameLabel.BackgroundTransparency = 1
usernameLabel.Text = "Hello, " .. player.DisplayName
usernameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
usernameLabel.TextScaled = true
usernameLabel.Font = Enum.Font.GothamBold

-- Shake animation
task.spawn(function()
	for i=1, 20 do
		frame.Position = UDim2.new(0, math.random(-5,5), 0, math.random(-5,5))
		task.wait(0.05)
	end
end)

task.wait(3)
loadingGui:Destroy()

-- Welcome Popup GUI
local welcomeGui = Instance.new("ScreenGui", game.CoreGui)
welcomeGui.IgnoreGuiInset = true
welcomeGui.ResetOnSpawn = false

local popupFrame = Instance.new("Frame", welcomeGui)
popupFrame.Size = UDim2.new(0, 400, 0, 100)
popupFrame.Position = UDim2.new(1, 0, 0.8, 0) -- Start offscreen (right side)
popupFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
popupFrame.BackgroundTransparency = 0.3
popupFrame.BorderSizePixel = 0
popupFrame.AnchorPoint = Vector2.new(1, 0)
popupFrame.ZIndex = 20

local welcomeLabel = Instance.new("TextLabel", popupFrame)
welcomeLabel.Size = UDim2.new(1, 0, 1, 0)
welcomeLabel.BackgroundTransparency = 1
welcomeLabel.Text = "🎉 Welcome, " .. player.DisplayName .. "!"
welcomeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
welcomeLabel.TextScaled = true
welcomeLabel.Font = Enum.Font.GothamBold
welcomeLabel.ZIndex = 21

-- Tween in
local TweenService = game:GetService("TweenService")
local inTween = TweenService:Create(popupFrame, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Position = UDim2.new(0.95, 0, 0.8, 0) -- Slide into bottom right
})
inTween:Play()

-- Wait then slide out and destroy
task.delay(4, function()
	local outTween = TweenService:Create(popupFrame, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(1.2, 0, 0.8, 0) -- Slide out to the right
	})
	outTween:Play()
	outTween.Completed:Wait()
	welcomeGui:Destroy()
end)


-- Rayfield UI load
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "🔥 Nicuse HUB",
	LoadingTitle = "Nicuse HUB",
	LoadingSubtitle = "Loading interface...",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "WashedzHub",
		FileName = "Config"
	},
	Discord = { Enabled = false },
	KeySystem = true,
	KeySettings = {
		Title = "Nicuse HUB",
		Subtitle = "Enter your key",
		Note = "Key = Nicuse123",
		FileName = "WashedzKey",
		SaveKey = true,
		GrabKeyFromSite = false,
		Key = { "Nicuse123" }
	},
	Theme = "Bloom"
})

local StealTab = Window:CreateTab("Nicuse HELPER🔥", 4483362458)

-- Variables for speed
local speedSlow = 0
local speedFast = 0

-- Speed sliders
StealTab:CreateSlider({
	Name = "Speed Boost (Slow)",
	Range = {0, 6},
	Increment = 1,
	Suffix = "",
	CurrentValue = 0,
	Callback = function(value)
		speedSlow = value
	end,
})

StealTab:CreateSlider({
	Name = "Speed Boost (Fast)",
	Range = {0, 20},
	Increment = 1,
	Suffix = "",
	CurrentValue = 0,
	Callback = function(value)
		speedFast = value
	end,
})

-- Speed movement
local function speedBoost()
	local character = player.Character or player.CharacterAdded:Wait()
	local hum = character:WaitForChild("Humanoid")
	local hrp = character:WaitForChild("HumanoidRootPart")

	RunService:BindToRenderStep("SpeedBoost", Enum.RenderPriority.Character.Value, function()
		if (speedSlow > 0 or speedFast > 0) and hum.MoveDirection.Magnitude > 0 then
			local speed = speedFast > 0 and speedFast or speedSlow
			hrp.CFrame = hrp.CFrame + hum.MoveDirection * speed * 0.06
		end
	end)
end

if player.Character then speedBoost() end
player.CharacterAdded:Connect(speedBoost)

-- Fly Toggle (faster and stable)
local flyActive = false
local flyBodyPosition
local flyBodyGyro

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
			flyBodyPosition.Position = hrp.Position + camCF.LookVector * 15 -- faster fly distance
			flyBodyGyro.CFrame = camCF
		end)
	end
end

StealTab:CreateButton({
	Name = "Fly (Toggle)",
	Callback = toggleFly,
})

-- Tween to Middle (smooth and proper)
local function tweenToMiddle()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal = {CFrame = CFrame.new(0, 10, 0)} -- Y=10 to avoid fall
		local tween = TweenService:Create(hrp, tweenInfo, goal)
		tween:Play()
	end
end

StealTab:CreateButton({
	Name = "Teleport to Middle (Tween)",
	Callback = tweenToMiddle,
})

-- Change this to your actual base location in the game:
local BASE_POSITION = Vector3.new(100, 10, 100)

local function tweenToBase()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal = {CFrame = CFrame.new(BASE_POSITION)}
		local tween = TweenService:Create(hrp, tweenInfo, goal)
		tween:Play()
	end
end

StealTab:CreateButton({
	Name = "Tween to Base (Slow)",
	Callback = tweenToBase,
})

-- Float toggle
local floatActive = false
local floatPart
local floatConnection

local function toggleFloat()
	if floatActive then
		floatActive = false
		if floatPart then
			floatPart:Destroy()
			floatPart = nil
		end
		if floatConnection then
			floatConnection:Disconnect()
			floatConnection = nil
		end
	else
		floatActive = true
		floatPart = Instance.new("Part")
		floatPart.Size = Vector3.new(3, 0.2, 3)
		floatPart.Anchored = true
		floatPart.CanCollide = false
		floatPart.Transparency = 1
		floatPart.Name = "WashedzFloat"
		floatPart.Parent = workspace

		floatConnection = RunService.RenderStepped:Connect(function()
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				floatPart.Position = player.Character.HumanoidRootPart.Position - Vector3.new(0, 3, 0)
			end
		end)
	end
end

StealTab:CreateButton({
	Name = "Float (Toggle)",
	Callback = toggleFloat,
})

-- Stop All button to stop everything
StealTab:CreateButton({
	Name = "Stop All",
	Callback = function()
		-- Stop fly
		flyActive = false
		if flyBodyPosition then flyBodyPosition:Destroy() flyBodyPosition = nil end
		if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
		RunService:UnbindFromRenderStep("FlyControl")

		-- Stop float
		floatActive = false
		if floatPart then floatPart:Destroy() floatPart = nil end
		if floatConnection then floatConnection:Disconnect() floatConnection = nil end

		-- Stop speed
		speedSlow = 0
		speedFast = 0
		RunService:UnbindFromRenderStep("SpeedBoost")

		-- Remove ESP
		for _, billboard in pairs(game:GetService("Players"):GetPlayers()) do
			if billboard and billboard.Character and billboard.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = billboard.Character.HumanoidRootPart
				for _, child in pairs(hrp:GetChildren()) do
					if child:IsA("BillboardGui") then
						child:Destroy()
					end
				end
			end
		end
	end,
})

-- ESP Player Names toggle
local espEnabled = false
local espBillboards = {}

local function toggleESP()
	if espEnabled then
		for _, billboard in pairs(espBillboards) do
			if billboard and billboard.Parent then
				billboard:Destroy()
			end
		end
		espBillboards = {}
		espEnabled = false
	else
		espEnabled = true
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = plr.Character.HumanoidRootPart
				local billboard = Instance.new("BillboardGui", hrp)
				billboard.Size = UDim2.new(0, 120, 0, 40)
				billboard.Adornee = hrp
				billboard.AlwaysOnTop = true

				local label = Instance.new("TextLabel", billboard)
				label.BackgroundTransparency = 1
				label.Size = UDim2.new(1, 0, 1, 0)
				label.Text = plr.DisplayName
				label.TextColor3 = Color3.new(1, 1, 1)
				label.TextStrokeColor3 = Color3.new(0, 0, 0)
				label.TextScaled = true

				table.insert(espBillboards, billboard)
			end
		end
	end
end

StealTab:CreateButton({
	Name = "ESP Player Names (Toggle)",
	Callback = toggleESP,
})

-- MY SCRIPTS TAB
local MyScriptsTab = Window:CreateTab("Main script🔥🤭", 4483362458)

MyScriptsTab:CreateButton({
	Name = "Washed Steal a Brainrot",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/washedz/WASHEDZ-/refs/heads/main/WASHEDZ%20HUG"))()
	end,
})

utility tab 
local UtilityTab = Window:CreateTab("Utility 🛠️", 4483362458)

UtilityTab:CreateButton({
	Name = "🌐 Server Hop",
	Callback = function()
		local HttpService = game:GetService("HttpService")
		local TeleportService = game:GetService("TeleportService")
		local Players = game:GetService("Players")
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
					TeleportService:TeleportToPlaceInstance(PlaceID, server.id, Players.LocalPlayer)
					return
				end
			end
		end

		TPToNewServer()
	end,
})

local petList = {}
local success, result = pcall(function()
	return game:GetService("ReplicatedStorage"):WaitForChild("Models"):WaitForChild("Animals"):GetChildren()
end)

if success then
	for _, pet in ipairs(result) do
		table.insert(petList, pet.Name)
	end
else
	warn("Could not load pets:", result)
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
					Rayfield:Notify({
						Title = "Pet Finder",
						Content = "No selected pets found.",
						Duration = 3
					})
				else
					Rayfield:Notify({
						Title = "Pet Finder",
						Content = table.concat(results, "\n"),
						Duration = 5
					})
				end
			end
		end)()
	end
})

-- INFO TAB
local InfoTab = Window:CreateTab("Info", 4483362458)

InfoTab:CreateButton({ Name = "Made by WASHEDZ", Callback = function() end })
InfoTab:CreateButton({ Name = "Updates soon in Discord 🤭", Callback = function() end })

-- Logo button top right corner
local logo = Instance.new("ImageButton")
logo.Size = UDim2.new(0, 50, 0, 50)
logo.Position = UDim2.new(1, -60, 0, 10)
logo.BackgroundColor3 = Color3.new(0, 0, 0)
logo.BorderSizePixel = 0
logo.Image = "rbxassetid://12890657087" -- replace with your gold-black logo asset id
logo.Parent = game.CoreGui

local bypassLabel = Instance.new("TextLabel", game.CoreGui)
bypassLabel.Size = UDim2.new(1, 0, 0, 60)
bypassLabel.Position = UDim2.new(0, 0, 0, 0)
bypassLabel.BackgroundColor3 = Color3.new(0, 0, 0)
bypassLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
bypassLabel.Text = "BYPASSING SYSTEM"
bypassLabel.TextScaled = true
bypassLabel.Font = Enum.Font.GothamBold
bypassLabel.TextStrokeTransparency = 0
bypassLabel.Visible = false
bypassLabel.ZIndex = 10

logo.MouseButton1Click:Connect(function()
	bypassLabel.Visible = true
	task.delay(3, function()
		bypassLabel.Visible = false
	end)
end)
