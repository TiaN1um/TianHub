-------------------------------------------------
-- RAYFIELD LOAD
-------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/TiaN1um/TianHub/main/fixed.lua"))()


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
-- FIXED FREECAM
-------------------------------------------------
local freecamSpeed = 1

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

        yaw = yaw - math.rad(delta.X * 0.25)
        pitch = math.clamp(pitch - math.rad(delta.Y * 0.25), -math.rad(89), math.rad(89))

        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0,0,-1) end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0,0,1) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.E) then move += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then move += Vector3.new(0,-1,0) end

        local speed = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and freecamSpeed*4 or freecamSpeed
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

-- TP Tool
ToolTab:CreateSection("TP Tool")
ToolTab:CreateButton({
    Name = "Teleport To Mouse",
    Callback = function()
        local mouse = player:GetMouse()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and mouse then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
            Rayfield:Notify({Title="TP Tool", Content="Teleported!", Duration=2})
        end
    end
})

-- Jerk (small shake effect)
ToolTab:CreateSection("Jerk")
ToolTab:CreateButton({
    Name = "Jerk Yourself",
    Callback = function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local original = hrp.CFrame
            for i=1,5 do
                hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-2,2),0,math.random(-2,2))
                task.wait(0.05)
            end
            hrp.CFrame = original
            Rayfield:Notify({Title="Jerk", Content="Jerked!", Duration=2})
        end
    end
})

-- Bang (launch upward)
ToolTab:CreateSection("Bang")
ToolTab:CreateButton({
    Name = "Bang Jump",
    Callback = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            hum.JumpPower = 150
            task.wait(0.1)
            hum.JumpPower = desiredJumpPower -- reset to slider value
            Rayfield:Notify({Title="Bang", Content="Launched!", Duration=2})
        end
    end
})

-- Invis (client-sided)
ToolTab:CreateSection("Invis")
ToolTab:CreateButton({
    Name = "Toggle Invis",
    Callback = function()
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = part.Transparency == 1 and 0 or 1
                elseif part:IsA("Decal") then
                    part.Transparency = part.Transparency == 1 and 0 or 1
                end
            end
            Rayfield:Notify({Title="Invis", Content="Toggled!", Duration=2})
        end
    end
})

-------------------------------------------------
-- PLAYER INTERACTION TAB
-------------------------------------------------
local PlayerTab = Window:CreateTab("Player Interaction", 4483362458)
PlayerTab:CreateSection("Interact With Players")

-- Helper: get player list excluding local player
local function getOtherPlayers()
	local list = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player then table.insert(list, p.Name) end
	end
	return list
end

-- Teleport To Player
PlayerTab:CreateDropdown({
	Name = "Teleport To Player",
	Options = getOtherPlayers(),
	CurrentOption = "",
	Callback = function(targetName)
		local target = Players:FindFirstChild(targetName)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if target and hrp and target.Character then
			local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
			if targetHRP then
				hrp.CFrame = targetHRP.CFrame + Vector3.new(0,3,0)
				Rayfield:Notify({Title="Player Interaction", Content="Teleported to "..targetName, Duration=2})
			end
		end
	end
})

-- Bring Player
PlayerTab:CreateDropdown({
	Name = "Bring Player",
	Options = getOtherPlayers(),
	CurrentOption = "",
	Callback = function(targetName)
		local target = Players:FindFirstChild(targetName)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if target and hrp and target.Character then
			local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
			if targetHRP then
				targetHRP.CFrame = hrp.CFrame + Vector3.new(0,0,3)
				Rayfield:Notify({Title="Player Interaction", Content="Brought "..targetName.." to you", Duration=2})
			end
		end
	end
})

-- Send Message / Chat (local only)
PlayerTab:CreateTextbox({
	Name = "Send Message",
	PlaceholderText = "Type a message...",
	Callback = function(msg)
		game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer(msg,"All")
		Rayfield:Notify({Title="Chat", Content="Message sent!", Duration=2})
	end
})

-- Knockback (visual only)
PlayerTab:CreateDropdown({
	Name = "Knockback Player",
	Options = getOtherPlayers(),
	CurrentOption = "",
	Callback = function(targetName)
		local target = Players:FindFirstChild(targetName)
		if target and target.Character then
			local hrp = target.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Velocity = Vector3.new(0,50,0) -- launch up
				Rayfield:Notify({Title="Knockback", Content="Knocked "..targetName.."!", Duration=2})
			end
		end
	end
})

-- Emote / Dance
local DanceAnimations = {
	Wave = 616159429,
	Dance1 = 616163198,
	Dance2 = 616163996,
	Dance3 = 616164223
}

PlayerTab:CreateDropdown({
	Name = "Dance / Emote",
	Options = {"Wave","Dance1","Dance2","Dance3"},
	CurrentOption = "",
	Callback = function(animName)
		local animId = DanceAnimations[animName]
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and animId then
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://"..animId
			local track = hum:LoadAnimation(anim)
			track:Play()
			Rayfield:Notify({Title="Emote", Content="Playing "..animName, Duration=2})
		end
	end
})

-- Freeze Player (local only, visual)
PlayerTab:CreateDropdown({
	Name = "Freeze Player (local)",
	Options = getOtherPlayers(),
	CurrentOption = "",
	Callback = function(targetName)
		local target = Players:FindFirstChild(targetName)
		if target and target.Character then
			for _, v in pairs(target.Character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Anchored = true
				end
			end
			Rayfield:Notify({Title="Freeze", Content=targetName.." frozen locally", Duration=2})
		end
	end
})

-- Unfreeze Player
PlayerTab:CreateDropdown({
	Name = "Unfreeze Player",
	Options = getOtherPlayers(),
	CurrentOption = "",
	Callback = function(targetName)
		local target = Players:FindFirstChild(targetName)
		if target and target.Character then
			for _, v in pairs(target.Character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Anchored = false
				end
			end
			Rayfield:Notify({Title="Freeze", Content=targetName.." unfrozen", Duration=2})
		end
	end
})

-- Team Swap (local only, if game allows)
PlayerTab:CreateDropdown({
	Name = "Switch Team",
	Options = {"Red","Blue","Green","Yellow"}, -- Replace with your game's team names
	CurrentOption = "",
	Callback = function(teamName)
		local t = game:GetService("Teams"):FindFirstChild(teamName)
		if t then
			player.Team = t
			Rayfield:Notify({Title="Team Swap", Content="Switched to "..teamName, Duration=2})
		end
	end
})

-- Auto-update player dropdowns
local function updatePlayerDropdowns()
	for _, section in pairs(PlayerTab.Sections) do
		if section.Type == "Dropdown" then
			section:SetOptions(getOtherPlayers())
		end
	end
end
Players.PlayerAdded:Connect(updatePlayerDropdowns)
Players.PlayerRemoving:Connect(updatePlayerDropdowns)
updatePlayerDropdowns()

