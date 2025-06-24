--// Cache

local select = select
local pcall, getgenv, next, Vector2, mathclamp, type, mousemoverel = select(1, pcall, getgenv, next, Vector2.new, math.clamp, type, mousemoverel or (Input and Input.MouseMove))

--// Preventing Multiple Processes

pcall(function()
	getgenv().Aimbot.Functions:Exit()
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

local RequiredDistance, Typing, Running, Animation, ServiceConnections = 2000, false, false, nil, {}


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
	LockPart = "NewHead", "Head" 
}

Environment.FOVSettings = {
	Enabled = true,
	Visible = true,
	Amount = 50,
	Color = Color3.fromRGB(255, 255, 255),
	LockedColor = Color3.fromRGB(255, 70, 70),
	Transparency = 5,
	Sides = 3,
	Thickness = 1,
	Filled = false
}

Environment.FOVCircle = Drawing.new("Circle")


local function CancelLock()
	Environment.Locked = nil
	if Animation then Animation:Cancel() end
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
end

local function GetClosestPlayer()
	if not Environment.Locked then
		RequiredDistance = (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000)

		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer then
				if v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
					if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
					if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
					if Environment.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[Environment.Settings.LockPart].Position}, v.Character:GetDescendants())) > 0 then continue end

					local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
					local Distance = (Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2(Vector.X, Vector.Y)).Magnitude

					if Distance < RequiredDistance and OnScreen then
						RequiredDistance = Distance
						Environment.Locked = v
					end
				end
			end
		end
	elseif (Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2(Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).X, Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).Y)).Magnitude > RequiredDistance then
		CancelLock()
	end
end


ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)


local function Load()
	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
			Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
			Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
			Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
			Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
			Environment.FOVCircle.Color = Environment.FOVSettings.Color
			Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
			Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
			Environment.FOVCircle.Position = Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
		else
			Environment.FOVCircle.Visible = false
		end

		if Running and Environment.Settings.Enabled then
			GetClosestPlayer()

			if Environment.Locked then
				if Environment.Settings.ThirdPerson then
					Environment.Settings.ThirdPersonSensitivity = mathclamp(Environment.Settings.ThirdPersonSensitivity, 0.1, 5)

					local Vector = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
					mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity)
				else
					if Environment.Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)})
						Animation:Play()
					else
						Camera.CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
					end
				end

			Environment.FOVCircle.Color = Environment.FOVSettings.LockedColor

			end
		end
	end)

	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
		if not Typing then
			pcall(function()
				if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							CancelLock()
						end
					else
						Running = true
					end
				end
			end)

			pcall(function()
				if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							CancelLock()
						end
					else
						Running = true
					end
				end
			end)
		end
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if not Typing then
			if not Environment.Settings.Toggle then
				pcall(function()
					if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
						Running = false; CancelLock()
					end
				end)

				pcall(function()
					if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
						Running = false; CancelLock()
					end
				end)
			end
		end
	end)
end



Environment.Functions = {}

function Environment.Functions:Exit()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	if Environment.FOVCircle.Remove then Environment.FOVCircle:Remove() end

	getgenv().Aimbot.Functions = nil
	getgenv().Aimbot = nil
	
	Load = nil; GetClosestPlayer = nil; CancelLock = nil
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
		Amount = 1,
		Color = Color3.fromRGB(255, 255, 255),
		LockedColor = Color3.fromRGB(255, 70, 70),
		Transparency = 1,
		Sides = 60,
		Thickness = .25,
		Filled = false
	}
end



Load()


local Gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
Gui.Name = "AimbotUI"
Gui.ResetOnSpawn = false


local Frame = Instance.new("Frame", Gui)
Frame.Size = UDim2.new(0, 240, 0, 250)
Frame.Position = UDim2.new(0, 15, 0, 100)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Visible = true


local Title = Instance.new("TextLabel", Frame)
Title.Text = "⚙ Aimbot Settings"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 16
Title.Font = Enum.Font.SourceSansBold


local function CreateToggle(name, default, callback, y)
	local toggle = Instance.new("TextButton", Frame)
	toggle.Size = UDim2.new(1, -10, 0, 24)
	toggle.Position = UDim2.new(0, 5, 0, y)
	toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.TextSize = 14
	toggle.Font = Enum.Font.SourceSans
	toggle.Text = name .. ": " .. (default and "ON" or "OFF")

	local state = default
	toggle.MouseButton1Click:Connect(function()
		state = not state
		toggle.Text = name .. ": " .. (state and "ON" or "OFF")
		callback(state)
	end)

	return y + 26
end

local function CreateSlider(name, min, max, default, callback, y)
	local label = Instance.new("TextLabel", Frame)
	label.Size = UDim2.new(1, -10, 0, 20)
	label.Position = UDim2.new(0, 5, 0, y)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 14
	label.Font = Enum.Font.SourceSans
	label.Text = name .. ": " .. tostring(default)

	local slider = Instance.new("TextButton", Frame)
	slider.Size = UDim2.new(1, -10, 0, 20)
	slider.Position = UDim2.new(0, 5, 0, y + 20)
	slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	slider.Text = ""
	slider.AutoButtonColor = false

	local dragging = false
	local fill = Instance.new("Frame", slider)
	fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BorderSizePixel = 0

	local function update(input)
		local x = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(x, 0, 1, 0)
		local value = math.floor((min + (max - min) * x) * 100) / 100
		label.Text = name .. ": " .. tostring(value)
		callback(value)
	end

	slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)
	slider.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			update(input)
		end
	end)

	update({ Position = Vector2.new(slider.AbsolutePosition.X + slider.AbsoluteSize.X * ((default - min) / (max - min)), 0) })

	return y + 48
end


local function CreateDropdown(name, options, default, callback, y)
	local dropdown = Instance.new("TextButton", Frame)
	dropdown.Size = UDim2.new(1, -10, 0, 24)
	dropdown.Position = UDim2.new(0, 5, 0, y)
	dropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	dropdown.TextColor3 = Color3.new(1, 1, 1)
	dropdown.TextSize = 14
	dropdown.Font = Enum.Font.SourceSans
	dropdown.Text = name .. ": " .. default

	local index = table.find(options, default) or 1
	dropdown.MouseButton1Click:Connect(function()
		index = index + 1
		if index > #options then index = 1 end
		dropdown.Text = name .. ": " .. options[index]
		callback(options[index])
	end)

	return y + 26
end

UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == Enum.KeyCode.RightShift then
		Frame.Visible = not Frame.Visible
	end
end)


local y = 32
y = CreateToggle("Enable Aimbot", Environment.Settings.Enabled, function(v)
	Environment.Settings.Enabled = v
end, y)

y = CreateToggle("Team Check", Environment.Settings.TeamCheck, function(v)
	Environment.Settings.TeamCheck = v
end, y)

y = CreateToggle("Wall Check", Environment.Settings.WallCheck, function(v)
	Environment.Settings.WallCheck = v
end, y)

y = CreateSlider("FOV", 20, 300, Environment.FOVSettings.Amount, function(v)
	Environment.FOVSettings.Amount = v
end, y)

y = CreateSlider("Sensitivity", 0, 1, Environment.Settings.Sensitivity, function(v)
	Environment.Settings.Sensitivity = v
end, y)

y = CreateDropdown("Lock Part", { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" }, Environment.Settings.LockPart, function(v)
	Environment.Settings.LockPart = v
end, y)

print("[Aimbot Menu] Loaded with interactive GUI.")
