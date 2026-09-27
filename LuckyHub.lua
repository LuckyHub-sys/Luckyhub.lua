--========================================================
-- LUCKY HUB
-- AUTO STEAL + AUTO RETURN
-- GOD MODE
-- NOCLIP
-- SPEED SLIDER
-- MOBILE + PC
-- FPS BOOST REMOVED
--========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--========================================================
-- CONFIG
--========================================================

local MIN_SPEED = 16
local MAX_SPEED = 850
local SPEED = 350

local RETURN_HEIGHT = 2

local TEMPLE_NAME = "Titan Temple"
local SAFEZONE_NAME = "SafeZone"

local TEMPLE_DISTANCE = 8
local TEMPLE_EGG_RADIUS = 180

local EGG_APPROACH_DISTANCE = 5
local EGG_PICKUP_DISTANCE = 2.5

local SAFEZONE_DISTANCE = 8

local MOVE_TIMEOUT = 25
local PICKUP_VERIFY_TIMEOUT = 2

--========================================================
-- SETTINGS
--========================================================

local AUTO_STEAL = false
local AUTO_RETURN = false
local GOD_MODE = false
local NOCLIP = false

--========================================================
-- STATE
--========================================================

local Character
local Humanoid
local HRP

local moving = false
local missionRunning = false

local currentEgg = nil

local oldAutoRotate = true

local connectedPrompts = {}

local godConnections = {}

--========================================================
-- CHARACTER
--========================================================

local function setupCharacter(character)

	Character = character

	Humanoid =
		character:WaitForChild(
			"Humanoid",
			10
		)

	HRP =
		character:WaitForChild(
			"HumanoidRootPart",
			10
		)

	if Humanoid then
		oldAutoRotate =
			Humanoid.AutoRotate
	end
end

if Player.Character then
	setupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(
	function(character)

		task.wait(0.5)

		setupCharacter(character)

		if GOD_MODE then
			task.wait(0.2)
			enableGodMode()
		end
	end
)

--========================================================
-- GOD MODE
--========================================================

local function disconnectGod()

	for _, connection in ipairs(
		godConnections
	) do

		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(godConnections)
end

function enableGodMode()

	disconnectGod()

	if not Character
		or not Humanoid
		or not Humanoid.Parent then
		return
	end

	GOD_MODE = true

	local humanoid = Humanoid

	-- Jangan mengubah WalkSpeed.
	-- Player tetap bisa lari.

	pcall(function()
		humanoid:SetStateEnabled(
			Enum.HumanoidStateType.Dead,
			false
		)
	end)

	-- Pertahankan HP.
	if humanoid.Health <= 0 then
		humanoid.Health =
			humanoid.MaxHealth
	end

	local healthConnection =
		humanoid.HealthChanged:Connect(
			function(health)

				if not GOD_MODE then
					return
				end

				if not humanoid.Parent then
					return
				end

				if health <= 0 then

					humanoid.Health =
						humanoid.MaxHealth
				end
			end
		)

	table.insert(
		godConnections,
		healthConnection
	)

	local stateConnection =
		humanoid.StateChanged:Connect(
			function(_, newState)

				if not GOD_MODE then
					return
				end

				if newState ==
					Enum.HumanoidStateType.Dead then

					pcall(function()

						humanoid:SetStateEnabled(
							Enum.HumanoidStateType.Dead,
							false
						)

						humanoid.Health =
							humanoid.MaxHealth
					end)
				end
			end
		)

	table.insert(
		godConnections,
		stateConnection
	)
end

function disableGodMode()

	GOD_MODE = false

	disconnectGod()

	if Humanoid
		and Humanoid.Parent then

		pcall(function()

			Humanoid:SetStateEnabled(
				Enum.HumanoidStateType.Dead,
				true
			)
		end)
	end
end

--========================================================
-- NOCLIP
--========================================================

local function updateNoClip()

	if not Character
		or not Character.Parent then
		return
	end

	for _, object in ipairs(
		Character:GetDescendants()
	) do

		if object:IsA("BasePart") then

			if object.Name ~= "HumanoidRootPart" then

				object.CanCollide =
					not NOCLIP
			end
		end
	end
end

RunService.Stepped:Connect(
	function()

		if NOCLIP then
			updateNoClip()
		end
	end
)

--========================================================
-- FIND OBJECT
--========================================================

local function findNamedObject(name)

	local exact =
		Workspace:FindFirstChild(
			name,
			true
		)

	if exact then
		return exact
	end

	local wanted =
		string.lower(name)

	for _, object in ipairs(
		Workspace:GetDescendants()
	) do

		if string.lower(
			object.Name
		) == wanted then

			return object
		end
	end

	return nil
end

--========================================================
-- GET PART
--========================================================

local function getPart(object)

	if not object then
		return nil
	end

	if object:IsA("BasePart") then
		return object
	end

	if object:IsA("Model") then

		if object.PrimaryPart then
			return object.PrimaryPart
		end

		return object:FindFirstChildWhichIsA(
			"BasePart",
			true
		)
	end

	return nil
end

--========================================================
-- FIND SAFEZONE
--========================================================

local function findSafeZone()

	local object =
		findNamedObject(
			SAFEZONE_NAME
		)

	return getPart(object)
end

--========================================================
-- FIND TITAN TEMPLE
--========================================================

local function findTemple()

	local object =
		findNamedObject(
			TEMPLE_NAME
		)

	return getPart(object)
end

--========================================================
-- FIND EGG PROMPT
--========================================================

local function isEggPrompt(prompt)

	if not prompt
		or not prompt:IsA(
			"ProximityPrompt"
		) then

		return false
	end

	local text =
		string.lower(
			(prompt.Name or "")
			.. " "
			.. (prompt.ActionText or "")
			.. " "
			.. (prompt.ObjectText or "")
		)

	local parent =
		prompt.Parent

	if parent then

		text =
			text
			.. " "
			.. string.lower(
				parent.Name
			)
	end

	return string.find(
		text,
		"egg",
		1,
		true
	) ~= nil
end

--========================================================
-- GET PROMPT POSITION
--========================================================

local function getPromptPosition(prompt)

	if not prompt then
		return nil
	end

	local parent =
		prompt.Parent

	if not parent then
		return nil
	end

	if parent:IsA("BasePart") then
		return parent.Position
	end

	if parent:IsA("Attachment") then
		return parent.WorldPosition
	end

	if parent:IsA("Model") then

		local part =
			getPart(parent)

		if part then
			return part.Position
		end
	end

	local ancestorPart =
		parent:FindFirstAncestorWhichIsA(
			"BasePart"
		)

	if ancestorPart then
		return ancestorPart.Position
	end

	return nil
end

--========================================================
-- FIND EGG IN TEMPLE
--========================================================

local function findEggPrompt()

	if not HRP
		or not HRP.Parent then
		return nil
	end

	local temple =
		findTemple()

	if not temple then
		return nil
	end

	local templePosition =
		temple.Position

	local closest = nil
	local closestDistance = math.huge

	for _, object in ipairs(
		Workspace:GetDescendants()
	) do

		if object:IsA(
			"ProximityPrompt"
		)
		and isEggPrompt(object)
		then

			local position =
				getPromptPosition(object)

			if position then

				local distanceFromTemple =
					(
						position
						- templePosition
					).Magnitude

				if distanceFromTemple
					<= TEMPLE_EGG_RADIUS then

					local distanceFromPlayer =
						(
							position
							- HRP.Position
						).Magnitude

					if distanceFromPlayer
						< closestDistance then

						closestDistance =
							distanceFromPlayer

						closest =
							object
					end
				end
			end
		end
	end

	return closest
end

--========================================================
-- STOP MOVEMENT
--========================================================

local function stopMovement()

	moving = false

	if Humanoid
		and Humanoid.Parent then

		Humanoid:Move(
			Vector3.zero,
			false
		)
	end

	if HRP
		and HRP.Parent then

		local velocity =
			HRP.AssemblyLinearVelocity

		HRP.AssemblyLinearVelocity =
			Vector3.new(
				0,
				velocity.Y,
				0
			)
	end
end

--========================================================
-- STRAIGHT MOVEMENT
--========================================================

local function moveStraightTo(
	targetPosition,
	distanceLimit,
	timeout
)

	if moving then
		return false
	end

	if not HRP
		or not Humanoid
		or not HRP.Parent
		or not Humanoid.Parent then

		return false
	end

	moving = true

	local startTime =
		os.clock()

	local success = false

	while moving
		and Character
		and Character.Parent
		and HRP
		and HRP.Parent
		and Humanoid
		and Humanoid.Parent
		and os.clock() - startTime
			< timeout do

		local current =
			HRP.Position

		local offset =
			targetPosition - current

		local distance =
			offset.Magnitude

		if distance <= distanceLimit then

			success = true
			break
		end

		local direction =
			offset.Unit

		Humanoid.WalkSpeed =
			SPEED

		Humanoid:Move(
			direction,
			false
		)

		HRP.AssemblyLinearVelocity =
			direction * SPEED

		RunService.Heartbeat:Wait()
	end

	stopMovement()

	return success
end

--========================================================
-- RETURN TO SAFEZONE
--========================================================

local function returnToSafeZone()

	if not AUTO_RETURN then
		return
	end

	if not HRP
		or not HRP.Parent then
		return
	end

	local safeZone =
		findSafeZone()

	if not safeZone then
		return
	end

	local target =
		safeZone.Position
		+ Vector3.new(
			0,
			RETURN_HEIGHT,
			0
		)

	moveStraightTo(
		target,
		SAFEZONE_DISTANCE,
		MOVE_TIMEOUT
	)
end

--========================================================
-- ACTIVATE PROMPT
--========================================================

local function activatePrompt(prompt)

	if not prompt
		or not prompt.Parent then

		return false
	end

	local position =
		getPromptPosition(prompt)

	if position
		and HRP
		and HRP.Parent then

		local distance =
			(
				position
				- HRP.Position
			).Magnitude

		if distance
			> EGG_PICKUP_DISTANCE then

			return false
		end
	end

	-- Normal Roblox ProximityPrompt interaction.
	-- Tidak menggunakan executor-only fire functions.
	local success =
		pcall(
			function()

				prompt:InputHoldBegin()

				task.wait(
					math.max(
						prompt.HoldDuration,
						0.05
					)
				)

				prompt:InputHoldEnd()
			end
		)

	return success
end

--========================================================
-- AUTO STEAL
--========================================================

local function autoStealMission()

	if missionRunning then
		return
	end

	if not AUTO_STEAL then
		return
	end

	if not Character
		or not Character.Parent
		or not HRP
		or not HRP.Parent then

		return
	end

	missionRunning = true

	------------------------------------------------
	-- FIND TEMPLE
	------------------------------------------------

	local temple =
		findTemple()

	if not temple then

		missionRunning =
			false

		return
	end

	------------------------------------------------
	-- GO TO TEMPLE
	------------------------------------------------

	local templeTarget =
		temple.Position
		+ Vector3.new(
			0,
			RETURN_HEIGHT,
			0
		)

	moveStraightTo(
		templeTarget,
		TEMPLE_DISTANCE,
		MOVE_TIMEOUT
	)

	if not AUTO_STEAL then

		missionRunning =
			false

		return
	end

	------------------------------------------------
	-- FIND EGG
	------------------------------------------------

	local egg =
		findEggPrompt()

	if not egg then

		missionRunning =
			false

		return
	end

	currentEgg =
		egg

	------------------------------------------------
	-- GO TO EGG
	------------------------------------------------

	local eggPosition =
		getPromptPosition(
			egg
		)

	if not eggPosition then

		currentEgg =
			nil

		missionRunning =
			false

		return
	end

	moveStraightTo(
		eggPosition,
		EGG_APPROACH_DISTANCE,
		MOVE_TIMEOUT
	)

	if not AUTO_STEAL then

		currentEgg =
			nil

		missionRunning =
			false

		return
	end

	------------------------------------------------
	-- PICKUP
	------------------------------------------------

	if HRP
		and HRP.Parent
		and egg
		and egg.Parent then

		activatePrompt(
			egg
		)

		task.wait(
			PICKUP_VERIFY_TIMEOUT
		)
	end

	currentEgg =
		nil

	------------------------------------------------
	-- RETURN
	------------------------------------------------

	if AUTO_RETURN then
		returnToSafeZone()
	end

	missionRunning =
		false
end

--========================================================
-- PROMPT CONNECTION
--========================================================

local function connectPrompt(prompt)

	if connectedPrompts[prompt] then
		return
	end

	connectedPrompts[prompt] =
		true

	prompt.AncestryChanged:Connect(
		function(_, parent)

			if not parent then
				connectedPrompts[prompt] =
					nil
			end
		end
	)
end

for _, object in ipairs(
	Workspace:GetDescendants()
) do

	if object:IsA(
		"ProximityPrompt"
	) then

		connectPrompt(object)
	end
end

Workspace.DescendantAdded:Connect(
	function(object)

		if object:IsA(
			"ProximityPrompt"
		) then

			connectPrompt(object)
		end
	end
)

--========================================================
-- UI
--========================================================

local oldGui =
	PlayerGui:FindFirstChild(
		"LuckyHubUI"
	)

if oldGui then
	oldGui:Destroy()
end

local ScreenGui =
	Instance.new("ScreenGui")

ScreenGui.Name =
	"LuckyHubUI"

ScreenGui.ResetOnSpawn =
	false

ScreenGui.IgnoreGuiInset =
	true

ScreenGui.ZIndexBehavior =
	Enum.ZIndexBehavior.Sibling

ScreenGui.DisplayOrder =
	999

ScreenGui.Parent =
	PlayerGui

--========================================================
-- MAIN
--========================================================

local Main =
	Instance.new("Frame")

Main.Name =
	"Main"

Main.Size =
	UDim2.fromOffset(
		270,
		270
	)

Main.Position =
	UDim2.new(
		0.5,
		-135,
		0.5,
		-135
	)

Main.BackgroundColor3 =
	Color3.fromRGB(
		24,
		24,
		28
	)

Main.BorderSizePixel =
	0

Main.Active =
	false

Main.ZIndex =
	10

Main.Parent =
	ScreenGui

local MainCorner =
	Instance.new("UICorner")

MainCorner.CornerRadius =
	UDim.new(
		0,
		14
	)

MainCorner.Parent =
	Main

local Stroke =
	Instance.new("UIStroke")

Stroke.Thickness =
	1.5

Stroke.Color =
	Color3.fromRGB(
		210,
		165,
		60
	)

Stroke.Parent =
	Main

--========================================================
-- TITLE
--========================================================

local Title =
	Instance.new("TextLabel")

Title.Size =
	UDim2.new(
		1,
		-70,
		0,
		38
	)

Title.Position =
	UDim2.fromOffset(
		12,
		4
	)

Title.BackgroundTransparency =
	1

Title.Text =
	"LUCKY HUB"

Title.TextSize =
	19

Title.Font =
	Enum.Font.GothamBold

Title.TextColor3 =
	Color3.fromRGB(
		240,
		195,
		70
	)

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.ZIndex =
	20

Title.Parent =
	Main

--========================================================
-- DRAG HANDLE
--========================================================

local DragHandle =
	Instance.new("TextButton")

DragHandle.Size =
	UDim2.new(
		1,
		-55,
		0,
		42
	)

DragHandle.Position =
	UDim2.fromOffset(
		0,
		0
	)

DragHandle.BackgroundTransparency =
	1

DragHandle.Text =
	""

DragHandle.AutoButtonColor =
	false

DragHandle.ZIndex =
	25

DragHandle.Parent =
	Main

--========================================================
-- CLOSE
--========================================================

local Close =
	Instance.new("TextButton")

Close.Size =
	UDim2.fromOffset(
		32,
		32
	)

Close.Position =
	UDim2.new(
		1,
		-40,
		0,
		6
	)

Close.BackgroundColor3 =
	Color3.fromRGB(
		55,
		45,
		30
	)

Close.BorderSizePixel =
	0

Close.Text =
	"X"

Close.TextSize =
	15

Close.Font =
	Enum.Font.GothamBold

Close.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

Close.AutoButtonColor =
	true

Close.Active =
	true

Close.Selectable =
	true

Close.ZIndex =
	30

Close.Parent =
	Main

local CloseCorner =
	Instance.new("UICorner")

CloseCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

CloseCorner.Parent =
	Close

--========================================================
-- STATUS
--========================================================

local Status =
	Instance.new("TextLabel")

Status.Size =
	UDim2.new(
		1,
		-20,
		0,
		25
	)

Status.Position =
	UDim2.fromOffset(
		10,
		39
	)

Status.BackgroundTransparency =
	1

Status.Text =
	"Ready"

Status.TextSize =
	12

Status.Font =
	Enum.Font.Gotham

Status.TextColor3 =
	Color3.fromRGB(
		185,
		185,
		185
	)

Status.ZIndex =
	20

Status.Parent =
	Main

--========================================================
-- BUTTON CREATOR
--========================================================

local function createButton(
	name,
	text,
	y
)

	local button =
		Instance.new("TextButton")

	button.Name =
		name

	button.Size =
		UDim2.new(
			1,
			-30,
			0,
			36
		)

	button.Position =
		UDim2.fromOffset(
			15,
			y
		)

	button.BackgroundColor3 =
		Color3.fromRGB(
			42,
			42,
			48
		)

	button.BorderSizePixel =
		0

	button.Text =
		text

	button.TextSize =
		13

	button.Font =
		Enum.Font.GothamBold

	button.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)

	button.AutoButtonColor =
		true

	button.Active =
		true

	button.Selectable =
		true

	button.ZIndex =
		30

	button.Parent =
		Main

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(
			0,
			9
		)

	corner.Parent =
		button

	return button
end

--========================================================
-- BUTTONS
--========================================================

local AutoStealButton =
	createButton(
		"AutoSteal",
		"AUTO STEAL : OFF",
		68
	)

local AutoReturnButton =
	createButton(
		"AutoReturn",
		"AUTO RETURN : OFF",
		108
	)

local GodModeButton =
	createButton(
		"GodMode",
		"GOD MODE : OFF",
		148
	)

--========================================================
-- SPEED LABEL
--========================================================

local SpeedLabel =
	Instance.new("TextLabel")

SpeedLabel.Size =
	UDim2.new(
		1,
		-30,
		0,
		22
	)

SpeedLabel.Position =
	UDim2.fromOffset(
		15,
		190
	)

SpeedLabel.BackgroundTransparency =
	1

SpeedLabel.Text =
	"SPEED : "
		.. tostring(SPEED)

SpeedLabel.TextSize =
	12

SpeedLabel.Font =
	Enum.Font.GothamBold

SpeedLabel.TextColor3 =
	Color3.fromRGB(
		210,
		210,
		210
	)

SpeedLabel.TextXAlignment =
	Enum.TextXAlignment.Left

SpeedLabel.ZIndex =
	20

SpeedLabel.Parent =
	Main

--========================================================
-- SPEED SLIDER
--========================================================

local Slider =
	Instance.new("Frame")

Slider.Size =
	UDim2.new(
		1,
		-30,
		0,
		8
	)

Slider.Position =
	UDim2.fromOffset(
		15,
		222
	)

Slider.BackgroundColor3 =
	Color3.fromRGB(
		55,
		55,
		60
	)

Slider.BorderSizePixel =
	0

Slider.ZIndex =
	20

Slider.Parent =
	Main

local SliderCorner =
	Instance.new("UICorner")

SliderCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

SliderCorner.Parent =
	Slider

local Fill =
	Instance.new("Frame")

Fill.Size =
	UDim2.new(
		(
			SPEED - MIN_SPEED
		) / (
			MAX_SPEED - MIN_SPEED
		),
		0,
		1,
		0
	)

Fill.BackgroundColor3 =
	Color3.fromRGB(
		210,
		165,
		60
	)

Fill.BorderSizePixel =
	0

Fill.ZIndex =
	21

Fill.Parent =
	Slider

local FillCorner =
	Instance.new("UICorner")

FillCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

FillCorner.Parent =
	Fill

--========================================================
-- SPEED SLIDER BUTTON
--========================================================

local SliderButton =
	Instance.new("TextButton")

SliderButton.Size =
	UDim2.fromOffset(
		30,
		30
	)

SliderButton.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)

SliderButton.Position =
	UDim2.new(
		(
			SPEED - MIN_SPEED
		) / (
			MAX_SPEED - MIN_SPEED
		),
		0,
		0.5,
		0
	)

SliderButton.BackgroundColor3 =
	Color3.fromRGB(
		235,
		195,
		80
	)

SliderButton.BorderSizePixel =
	0

SliderButton.Text =
	""

SliderButton.ZIndex =
	30

SliderButton.Parent =
	Slider

local SliderButtonCorner =
	Instance.new("UICorner")

SliderButtonCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

SliderButtonCorner.Parent =
	SliderButton

--========================================================
-- SPEED SLIDER
--========================================================

local function setSpeedFromInput(
	input
)

	local absolute =
		Slider.AbsolutePosition

	local size =
		Slider.AbsoluteSize

	if size.X <= 0 then
		return
	end

	local x =
		input.Position.X
		- absolute.X

	local percent =
		math.clamp(
			x / size.X,
			0,
			1
		)

	SPEED =
		math.floor(
			MIN_SPEED
			+ (
				MAX_SPEED
				- MIN_SPEED
			) * percent
		)

	Fill.Size =
		UDim2.new(
			percent,
			0,
			1,
			0
		)

	SliderButton.Position =
		UDim2.new(
			percent,
			0,
			0.5,
			0
		)

	SpeedLabel.Text =
		"SPEED : "
		.. tostring(SPEED)
end

local sliderDragging =
	false

SliderButton.InputBegan:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			sliderDragging =
				true

			setSpeedFromInput(
				input
			)
		end
	end
)

Slider.InputBegan:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			sliderDragging =
				true

			setSpeedFromInput(
				input
			)
		end
	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if not sliderDragging then
			return
		end

		if input.UserInputType
			== Enum.UserInputType.MouseMovement
			or input.UserInputType
			== Enum.UserInputType.Touch then

			setSpeedFromInput(
				input
			)
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			sliderDragging =
				false
		end
	end
)

--========================================================
-- AUTO STEAL BUTTON
--========================================================

AutoStealButton.Activated:Connect(
	function()

		AUTO_STEAL =
			not AUTO_STEAL

		if AUTO_STEAL then

			AutoStealButton.Text =
				"AUTO STEAL : ON"

			Status.Text =
				"Auto Steal enabled"

			task.spawn(
				autoStealMission
			)

		else

			AutoStealButton.Text =
				"AUTO STEAL : OFF"

			Status.Text =
				"Auto Steal disabled"

			missionRunning =
				false

			currentEgg =
				nil

			stopMovement()
		end
	end
)

--========================================================
-- AUTO RETURN BUTTON
--========================================================

AutoReturnButton.Activated:Connect(
	function()

		AUTO_RETURN =
			not AUTO_RETURN

		if AUTO_RETURN then

			AutoReturnButton.Text =
				"AUTO RETURN : ON"

			Status.Text =
				"Auto Return enabled"

		else

			AutoReturnButton.Text =
				"AUTO RETURN : OFF"

			Status.Text =
				"Auto Return disabled"
		end
	end
)

--========================================================
-- GOD MODE BUTTON
--========================================================

GodModeButton.Activated:Connect(
	function()

		GOD_MODE =
			not GOD_MODE

		if GOD_MODE then

			GodModeButton.Text =
				"GOD MODE : ON"

			Status.Text =
				"God Mode enabled"

			enableGodMode()

		else

			GodModeButton.Text =
				"GOD MODE : OFF"

			Status.Text =
				"God Mode disabled"

			disableGodMode()
		end
	end
)

--========================================================
-- MINI BALL
--========================================================

local Mini =
	Instance.new("TextButton")

Mini.Name =
	"MiniBall"

Mini.Size =
	UDim2.fromOffset(
		52,
		52
	)

Mini.AnchorPoint =
	Vector2.new(
		0,
		0.5
	)

Mini.Position =
	UDim2.new(
		0,
		10,
		0.5,
		0
	)

Mini.BackgroundColor3 =
	Color3.fromRGB(
		35,
		35,
		40
	)

Mini.BorderSizePixel =
	0

Mini.Text =
	"LUCKY"

Mini.TextSize =
	10

Mini.Font =
	Enum.Font.GothamBold

Mini.TextColor3 =
	Color3.fromRGB(
		235,
		190,
		70
	)

Mini.Visible =
	false

Mini.Active =
	true

Mini.Selectable =
	true

Mini.ZIndex =
	50

Mini.Parent =
	ScreenGui

local MiniCorner =
	Instance.new("UICorner")

MiniCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

MiniCorner.Parent =
	Mini

local MiniStroke =
	Instance.new("UIStroke")

MiniStroke.Thickness =
	1.5

MiniStroke.Color =
	Color3.fromRGB(
		210,
		165,
		60
	)

MiniStroke.Parent =
	Mini

--========================================================
-- CLOSE / OPEN
--========================================================

Close.Activated:Connect(
	function()

		Main.Visible =
			false

		Mini.Visible =
			true
	end
)

Mini.Activated:Connect(
	function()

		Main.Visible =
			true

		Mini.Visible =
			false
	end
)

--========================================================
-- DRAG UI
--========================================================

local dragging =
	false

local dragStart =
	nil

local startPosition =
	nil

local function updateDrag(
	input
)

	if not dragStart
		or not startPosition then

		return
	end

	local delta =
		input.Position
		- dragStart

	Main.Position =
		UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset
				+ delta.X,

			startPosition.Y.Scale,
			startPosition.Y.Offset
				+ delta.Y
		)
end

DragHandle.InputBegan:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			dragging =
				true

			dragStart =
				input.Position

			startPosition =
				Main.Position
		end
	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if not dragging then
			return
		end

		if input.UserInputType
			== Enum.UserInputType.MouseMovement
			or input.UserInputType
			== Enum.UserInputType.Touch then

			updateDrag(
				input
			)
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			dragging =
				false
		end
	end
)

--========================================================
-- SPEED APPLY
--========================================================

RunService.Heartbeat:Connect(
	function()

		if Humanoid
			and Humanoid.Parent then

			if not moving then

				Humanoid.WalkSpeed =
					SPEED
			end
		end
	end
)

--========================================================
-- STATUS LOOP
--========================================================

task.spawn(
	function()

		while ScreenGui
			and ScreenGui.Parent do

			if missionRunning then

				if currentEgg then

					Status.Text =
						"Getting egg..."

				else

					Status.Text =
						"Auto Steal running..."
				end

			elseif GOD_MODE then

				Status.Text =
					"God Mode : ON"

			elseif AUTO_STEAL then

				Status.Text =
					"Auto Steal : ON"

			elseif AUTO_RETURN then

				Status.Text =
					"Auto Return : ON"

			else

				Status.Text =
					"Ready"
			end

			task.wait(
				0.25
			)
		end
	end
)

--========================================================
-- AUTO STEAL LOOP
--========================================================

task.spawn(
	function()

		while ScreenGui
			and ScreenGui.Parent do

			if AUTO_STEAL
				and not missionRunning then

				task.spawn(
					autoStealMission
				)
			end

			task.wait(
				0.5
			)
		end
	end
)

--========================================================
-- RESPAWN
--========================================================

Player.CharacterAdded:Connect(
	function(character)

		task.wait(
			0.5
		)

		setupCharacter(
			character
		)

		if GOD_MODE then

			task.wait(
				0.2
			)

			enableGodMode()
		end
	end
)

--========================================================
-- READY
--========================================================

Status.Text =
	"Ready"

print(
	"[LuckyHub] Loaded successfully"
)
