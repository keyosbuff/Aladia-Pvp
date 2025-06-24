--// Cache
local pcall, getgenv, next, type = pcall, getgenv, next, type
local Vector2 = Vector2.new
local mathclamp = math.clamp

local success, mousemoverel = pcall(function() return mousemoverel end)
mousemoverel = success and mousemoverel or function() end -- Fallback if unavailable

--// Preventing Multiple Processes
pcall(function()
	if getgenv().Aimbot and getgenv().Aimbot.Functions then
		getgenv().Aimbot.Functions:Exit()
	end
end)

--// Environment
getgenv().Aimbot = {}
local Environment = getgenv().Aimbot

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Variables
local RequiredDistance, Typing, Running, Animation, ServiceConnections = 2000, false, false, nil, {}

--// Settings
Environment.Settings = {
	Enabled = true,
	TeamCheck = false,
	AliveCheck = true,
	WallCheck = false,
	Sensitivity = 0,
	ThirdPerson = false,
	ThirdPersonSensitivity = 3,
	TriggerKey = "MouseButton2",
	Toggle = false,
	LockPart = "Head" -- <- Fixed from incorrect multiple value assignment
}

Environment.FOVSettings = {
	Enabled = true,
	Visible = true,
	Amount = 50,
	Color = Color3.fromRGB(255, 255, 255),
	LockedColor = Color3.fromRGB(255, 70, 70),
	Transparency = 1,
	Sides = 60,
	Thickness = 1,
	Filled = false
}

Environment.FOVCircle = Drawing.new("Circle")

--// Cancel Target Lock
local function CancelLock()
	Environment.Locked = nil
	if Animation then Animation:Cancel() end
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
end

--// Get Closest Player
local function GetClosestPlayer()
	if not Environment.Locked then
		RequiredDistance = Environment.FOVSettings.Amount or 2000

		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) then
				local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
				if not humanoid then continue end

				if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
				if Environment.Settings.AliveCheck and humanoid.Health <= 0 then continue end
				if Environment.Settings.WallCheck then
					local parts = Camera:GetPartsObscuringTarget({v.Character[Environment.Settings.LockPart].Position}, v.Character:GetDescendants())
					if #parts > 0 then continue end
				end

				local screenPos, onScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
				if not onScreen then continue end

				local distance = (Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2(screenPos.X, screenPos.Y)).Magnitude

				if distance < RequiredDistance then
					RequiredDistance = distance
					Environment.Locked = v
				end
			end
		end
	elseif Environment.Locked and Environment.Locked.Character then
		local pos = Environment.Locked.Character:FindFirstChild(Environment.Settings.LockPart)
		if pos then
			local dist = (Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) -
				Vector2(Camera:WorldToViewportPoint(pos.Position).X, Camera:WorldToViewportPoint(pos.Position).Y)).Magnitude
			if dist > RequiredDistance then
				CancelLock()
			end
		end
	end
end

--// Typing Detection
ServiceConnections.TypingStarted = UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)

ServiceConnections.TypingEnded = UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)

--// Main Loop
local function Load()
	ServiceConnections.RenderStep = RunService.RenderStepped:Connect(function()
		local fov = Environment.FOVCircle
		local settings = Environment.FOVSettings

		if settings.Enabled and Environment.Settings.Enabled then
			fov.Radius = settings.Amount
			fov.Thickness = settings.Thickness
			fov.Filled = settings.Filled
			fov.NumSides = settings.Sides
			fov.Color = settings.Color
			fov.Transparency = settings.Transparency
			fov.Visible = settings.Visible
			fov.Position = Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
		else
			fov.Visible = false
		end

		if Running and Environment.Settings.Enabled then
			GetClosestPlayer()

			if Environment.Locked and Environment.Locked.Character then
				local targetPart = Environment.Locked.Character:FindFirstChild(Environment.Settings.LockPart)
				if targetPart then
					local pos = targetPart.Position
					if Environment.Settings.ThirdPerson then
						local vec = Camera:WorldToViewportPoint(pos)
						Environment.Settings.ThirdPersonSensitivity = mathclamp(Environment.Settings.ThirdPersonSensitivity, 0.1, 5)
						mousemoverel((vec.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity,
									 (vec.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity)
					else
						if Environment.Settings.Sensitivity > 0 then
							Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
								{CFrame = CFrame.new(Camera.CFrame.Position, pos)})
							Animation:Play()
						else
							Camera.CFrame = CFrame.new(Camera.CFrame.Position, pos)
						end
					end

					Environment.FOVCircle.Color = Environment.FOVSettings.LockedColor
				end
			end
		end
	end)

	--// Input Began
	ServiceConnections.InputBegan = UserInputService.InputBegan:Connect(function(input)
		if Typing then return end

		local function CheckInput(trigger)
			if trigger == Environment.Settings.TriggerKey then
				if Environment.Settings.Toggle then
					Running = not Running
					if not Running then CancelLock() end
				else
					Running = true
				end
			end
		end

		if input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
			CheckInput(input.UserInputType.Name)
		elseif input.KeyCode.Name == Environment.Settings.TriggerKey then
			CheckInput(input.KeyCode.Name)
		end
	end)

	--// Input Ended
	ServiceConnections.InputEnded = UserInputService.InputEnded:Connect(function(input)
		if Typing then return end

		local function CheckRelease(trigger)
			if trigger == Environment.Settings.TriggerKey and not Environment.Settings.Toggle then
				Running = false
				CancelLock()
			end
		end

		if input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
			CheckRelease(input.UserInputType.Name)
		elseif input.KeyCode.Name == Environment.Settings.TriggerKey then
			CheckRelease(input.KeyCode.Name)
		end
	end)
end

--// Exit, Reset, Restart
Environment.Functions = {}

function Environment.Functions:Exit()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	if Environment.FOVCircle then
		Environment.FOVCircle:Remove()
	end

	getgenv().Aimbot = nil
end

function Environment.Functions:Restart()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end
	Load()
end

function Environment.Functions:ResetSettings()
	Environment.Settings = {
		Enabled = true,
		TeamCheck = true,
		AliveCheck = true,
		WallCheck = false,
		Sensitivity = 0.24,
		ThirdPerson = false,
		ThirdPersonSensitivity = 3,
		TriggerKey = "MouseButton2",
		Toggle = false,
		LockPart = "HumanoidRootPart"
	}

	Environment.FOVSettings = {
		Enabled = true,
		Visible = true,
		Amount = 80,
		Color = Color3.fromRGB(255, 255, 255),
		LockedColor = Color3.fromRGB(255, 70, 70),
		Transparency = 1,
		Sides = 60,
		Thickness = 1,
		Filled = false
	}
end

--// Load
Load()
