-------------------------------------------------
-- RAYFIELD LOAD
-------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-------------------------------------------------
-- WINDOW
-------------------------------------------------
local Window = Rayfield:CreateWindow({
	Name = "Tian's Window",
	LoadingTitle = "Powered by will",
	LoadingSubtitle = "by Tian",
	Theme = "Amethyst",
	ToggleUIKeybind = "K",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "TianHub",
		FileName = "Hub"
	},
	KeySystem = false
})

Rayfield:Notify({
	Title = "Welcome",
	Content = "System Loaded",
	Duration = 3
})

-------------------------------------------------
-- SERVICES
-------------------------------------------------
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

-------------------------------------------------
-- VARIABLES
-------------------------------------------------
local flying = false
local flySpeed = 60
local acceleration = 6
local currentVelocity = Vector3.zero
local noclip = false
local freecam = false
local desiredWalkSpeed = 16
local desiredJumpPower = 50
local desiredFOV = cam.FieldOfView

local align, velocity, attach, flyConn, noclipConn, freecamConn
local yaw, pitch, lastMouse

-------------------------------------------------
-- MOVEMENT TAB
-------------------------------------------------
local MoveTab = Window:CreateTab("Movement", 4483362458)
MoveTab:CreateSection("Fly & Movement")

-------------------------------------------------
-- FLY SYSTEM
-------------------------------------------------
local function startFly()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")

	hum:ChangeState(Enum.HumanoidStateType.Physics)

	attach = Instance.new("Attachment", hrp)

	align = Instance.new("AlignOrientation")
	align.Attachment0 = attach
	align.Responsiveness = 100
	align.MaxTorque = math.huge
	align.Parent = hrp

	velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attach
	velocity.MaxForce = math.huge
	velocity.Parent = hrp

	currentVelocity = Vector3.zero

	flyConn = RunService.RenderStepped:Connect(function(dt)
		if not flying then return end

		align.CFrame = cam.CFrame

		local dir = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end

		local target = Vector3.zero
		if dir.Magnitude > 0 then
			target = dir.Unit * flySpeed
		end

		currentVelocity = currentVelocity:Lerp(target, math.clamp(acceleration * dt, 0, 1))
		velocity.VectorVelocity = currentVelocity
	end)
end

local function stopFly()
	if flyConn then flyConn:Disconnect() end
	if align then align:Destroy() end
	if velocity then velocity:Destroy() end
	if attach then attach:Destroy() end

	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

MoveTab:CreateToggle({
	Name = "Fly",
	CurrentValue = false,
	Callback = function(v)
		flying = v
		if v then
			startFly()
			Rayfield:Notify({Title="Fly", Content="Enabled", Duration=2})
		else
			stopFly()
			Rayfield:Notify({Title="Fly", Content="Disabled", Duration=2})
		end
	end
})

MoveTab:CreateSlider({
	Name = "Fly Speed",
	Range = {10, 200},
	Increment = 5,
	CurrentValue = flySpeed,
	Callback = function(v)
		flySpeed = v
	end
})

-------------------------------------------------
-- WALK & JUMP
-------------------------------------------------
MoveTab:CreateSlider({
	Name = "WalkSpeed",
	Range = {8, 100},
	Increment = 1,
	CurrentValue = desiredWalkSpeed,
	Callback = function(v)
		desiredWalkSpeed = v
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = v end
	end
})

MoveTab:CreateSlider({
	Name = "JumpPower",
	Range = {20, 150},
	Increment = 5,
	CurrentValue = desiredJumpPower,
	Callback = function(v)
		desiredJumpPower = v
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = v
			hum.JumpHeight = v / 2
		end
	end
})

player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	task.wait(0.2)
	hum.WalkSpeed = desiredWalkSpeed
	hum.UseJumpPower = true
	hum.JumpPower = desiredJumpPower
	hum.JumpHeight = desiredJumpPower / 2
end)

-------------------------------------------------
-- FOV
-------------------------------------------------
MoveTab:CreateSlider({
	Name = "FOV",
	Range = {50, 120},
	Increment = 1,
	CurrentValue = desiredFOV,
	Callback = function(v)
		desiredFOV = v
		cam.FieldOfView = v
	end
})

RunService.RenderStepped:Connect(function()
	if cam.FieldOfView ~= desiredFOV then
		cam.FieldOfView = desiredFOV
	end
end)

-------------------------------------------------
-- NOCLIP
-------------------------------------------------
local function setNoclip(state)
	noclip = state
	if state then
		noclipConn = RunService.Stepped:Connect(function()
			local char = player.Character
			if char then
				for _,v in pairs(char:GetDescendants()) do
					if v:IsA("BasePart") then
						v.CanCollide = false
					end
				end
			end
		end)
	else
		if noclipConn then noclipConn:Disconnect() end
	end
end

MoveTab:CreateToggle({
	Name = "Noclip",
	CurrentValue = false,
	Callback = function(v)
		setNoclip(v)
		Rayfield:Notify({Title="Noclip", Content=v and "Enabled" or "Disabled", Duration=2})
	end
})

-------------------------------------------------
-- FREECAM
-------------------------------------------------
MoveTab:CreateSection("Freecam")

local function startFreecam()
	freecam = true
	cam.CameraType = Enum.CameraType.Scriptable
	local cf = cam.CFrame
	yaw, pitch = cf:ToOrientation()
	lastMouse = UIS:GetMouseLocation()
	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter

	freecamConn = RunService.RenderStepped:Connect(function(dt)
		local mouse = UIS:GetMouseLocation()
		local delta = mouse - lastMouse
		lastMouse = mouse

		yaw -= math.rad(delta.X * 0.25)
		pitch = math.clamp(pitch - math.rad(delta.Y * 0.25), -math.rad(89), math.rad(89))

		local move = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0,0,-1) end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0,0,1) end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1,0,0) end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1,0,0) end
		if UIS:IsKeyDown(Enum.KeyCode.E) then move += Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.Q) then move += Vector3.new(0,-1,0) end

		local speed = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 4 or 1
		local rot = CFrame.fromOrientation(pitch, yaw, 0)
		cam.CFrame = CFrame.new(cam.CFrame.Position + rot:VectorToWorldSpace(move) * speed) * rot
	end)
end

local function stopFreecam()
	freecam = false
	if freecamConn then freecamConn:Disconnect() end
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	cam.CameraType = Enum.CameraType.Custom
end

MoveTab:CreateToggle({
	Name = "Freecam",
	CurrentValue = false,
	Callback = function(v)
		if v then startFreecam() else stopFreecam() end
		Rayfield:Notify({Title="Freecam", Content=v and "Enabled" or "Disabled", Duration=2})
	end
})

-------------------------------------------------
-- KEYBINDS
-------------------------------------------------
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Enum.KeyCode.F then
		flying = not flying
		if flying then startFly() else stopFly() end
		Rayfield:Notify({Title="Fly", Content=flying and "Enabled" or "Disabled", Duration=2})
	end

	if input.KeyCode == Enum.KeyCode.N then
		setNoclip(not noclip)
		Rayfield:Notify({Title="Noclip", Content=noclip and "Enabled" or "Disabled", Duration=2})
	end

	if input.KeyCode == Enum.KeyCode.C then
		if freecam then stopFreecam() else startFreecam() end
		Rayfield:Notify({Title="Freecam", Content=freecam and "Disabled" or "Enabled", Duration=2})
	end
end)

-------------------------------------------------
-- WALKS TAB
-------------------------------------------------
local WalkTab = Window:CreateTab("Walks", 4483362458)
WalkTab:CreateSection("R15 Walk Styles")

local WalkStyles = {
	Default = {Walk = 507777826, Run = 507767714},
	Zombie = {Walk = 616168032, Run = 616163682},
	Pirate = {Walk = 750781874, Run = 750783738},
	Woman = {Walk = 616146177, Run = 616140816},
	Stylish = {Walk = 616136790, Run = 616139451},
	Elder = {Walk = 616168032, Run = 616163682},
	Knight = {Walk = 657552124, Run = 657564596},
	Robot = {Walk = 616088211, Run = 616091570}
}

local function setWalkStyle(style)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.RigType ~= Enum.HumanoidRigType.R15 then return end
	local animate = char:FindFirstChild("Animate")
	if not animate then return end

	animate.walk.WalkAnim.AnimationId = "rbxassetid://"..style.Walk
	animate.run.RunAnim.AnimationId = "rbxassetid://"..style.Run
end

for name, style in pairs(WalkStyles) do
	WalkTab:CreateButton({
		Name = name.." Walk",
		Callback = function()
			setWalkStyle(style)
		end
	})
end

-------------------------------------------------
-- TOOLS TAB
-------------------------------------------------
local ToolTab = Window:CreateTab("Tool", 4483362458)
ToolTab:CreateSection("TP Tool")
ToolTab:CreateSection("Jerk")
ToolTab:CreateSection("Bang")
ToolTab:CreateSection("Invis")
