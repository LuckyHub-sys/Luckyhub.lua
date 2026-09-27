--========================================================
-- LUCKY HUB
-- AUTO STEAL
-- AUTO RETURN
-- GOD MODE
-- NOCLIP
-- SPEED
-- MOBILE + PC
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
local PICKUP_DELAY = 0.15

--========================================================
-- SETTINGS
--========================================================

local AUTO_STEAL = false
local AUTO_RETURN = false
local GOD_MODE = false
local NOCLIP = false

--========================================================
-- CHARACTER
--========================================================

local Character = nil
local Humanoid = nil
local HRP = nil

local oldAutoRotate = true

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

		-- Membantu mencegah death karena
		-- lepasnya bagian character.
		pcall(function()

			Humanoid.BreakJointsOnDeath =
				false

			Humanoid.RequiresNeck =
				false
		end)
	end
end

if Player.Character then
	setupCharacter(
		Player.Character
	)
end

--========================================================
-- STATES
--========================================================

local moving = false
local missionRunning = false

local currentEgg = nil

local connectedPrompts = {}

--========================================================
-- GOD MODE VARIABLES
--========================================================

local godConnections = {}

local godLastHealth = nil
local godDamageTaken = false

--========================================================
-- NOCLIP VARIABLES
--========================================================

local savedCollision =
	{}

--========================================================
-- GOD MODE DISCONNECT
--========================================================

local function disconnectGodConnections()

	for _, connection in ipairs(
		godConnections
	) do

		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(
		godConnections
	)
end

--========================================================
-- GOD MODE
--========================================================

local function enableGodMode()

	disconnectGodConnections()

	if not Character
		or not Character.Parent
		or not Humanoid
		or not Humanoid.Parent then

		return
	end

	GOD_MODE =
		true

	godDamageTaken =
		false

	godLastHealth =
		Humanoid.Health

	--====================================================
	-- INITIAL PROTECTION
	--====================================================

	pcall(function()

		Humanoid.BreakJointsOnDeath =
			false

		Humanoid.RequiresNeck =
			false

		Humanoid:SetStateEnabled(
			Enum.HumanoidStateType.Dead,
			false
		)
	end)

	if Humanoid.Health <= 0 then

		Humanoid.Health =
			Humanoid.MaxHealth
	end

	--====================================================
	-- HEALTH MONITOR
	--====================================================

	local healthConnection =
		Humanoid.HealthChanged:Connect(
			function(newHealth)

				if not GOD_MODE then
					return
				end

				if not Humanoid
					or not Humanoid.Parent then

					return
				end

				local previousHealth =
					godLastHealth
					or Humanoid.MaxHealth

				if newHealth < previousHealth then

					godDamageTaken =
						true
				end

				godLastHealth =
					newHealth

				-- Jangan biarkan HP sampai 0.
				if newHealth <= 0 then

					Humanoid.Health =
						Humanoid.MaxHealth

					godLastHealth =
						Humanoid.MaxHealth
				end
			end
		)

	table.insert(
		godConnections,
		healthConnection
	)

	--====================================================
	-- DEATH STATE MONITOR
	--====================================================

	local stateConnection =
		Humanoid.StateChanged:Connect(
			function(_, newState)

				if not GOD_MODE then
					return
				end

				if newState ==
					Enum.HumanoidStateType.Dead then

					pcall(function()

						Humanoid:SetStateEnabled(
							Enum.HumanoidStateType.Dead,
							false
						)

						Humanoid.Health =
							Humanoid.MaxHealth

						godLastHealth =
							Humanoid.MaxHealth
					end)
				end
			end
		)

	table.insert(
		godConnections,
		stateConnection
	)

	--====================================================
	-- CONTINUOUS PROTECTION
	--====================================================

	local heartbeatConnection =
		RunService.Heartbeat:Connect(
			function()

				if not GOD_MODE then
					return
				end

				if not Character
					or not Character.Parent
					or not Humanoid
					or not Humanoid.Parent then

					return
				end

				pcall(function()

					Humanoid:SetStateEnabled(
						Enum.HumanoidStateType.Dead,
						false
					)

					Humanoid.BreakJointsOnDeath =
						false

					Humanoid.RequiresNeck =
						false
				end)

				if Humanoid.Health <= 0 then

					Humanoid.Health =
						Humanoid.MaxHealth

					godLastHealth =
						Humanoid.MaxHealth
				end
			end
		)

	table.insert(
		godConnections,
		heartbeatConnection
	)
end

--========================================================
-- DISABLE GOD MODE
--========================================================

local function disableGodMode()

	GOD_MODE =
		false

	disconnectGodConnections()

	if Humanoid
		and Humanoid.Parent then

		pcall(function()

			Humanoid:SetStateEnabled(
				Enum.HumanoidStateType.Dead,
				true
			)

			Humanoid.BreakJointsOnDeath =
				true

			Humanoid.RequiresNeck =
				true
		end)

		-- Kalau menerima damage ketika God Mode
		-- aktif, matikan God Mode = mati.
		if godDamageTaken then

			task.defer(
				function()

					if Humanoid
						and Humanoid.Parent then

						Humanoid.Health =
							0
					end
				end
			)
		end
	end

	godLastHealth =
		nil

	godDamageTaken =
		false
end

--========================================================
-- NOCLIP ENABLE
--========================================================

local function enableNoClip()

	if not Character
		or not Character.Parent then
		return
	end

	table.clear(
		savedCollision
	)

	for _, object in ipairs(
		Character:GetDescendants()
	) do

		if object:IsA("BasePart") then

			savedCollision[object] =
				object.CanCollide

			object.CanCollide =
				false
		end
	end
end

--========================================================
-- NOCLIP DISABLE
--========================================================

local function disableNoClip()

	for part, oldValue in pairs(
		savedCollision
	) do

		if part
			and part.Parent then

			part.CanCollide =
				oldValue
		end
	end

	table.clear(
		savedCollision
	)
end

--========================================================
-- NOCLIP LOOP
--========================================================

RunService.Stepped:Connect(
	function()

		if not NOCLIP then
			return
		end

		if not Character
			or not Character.Parent then

			return
		end

		for _, object in ipairs(
			Character:GetDescendants()
		) do

			if object:IsA("BasePart") then

				if not savedCollision[object] then

					savedCollision[object] =
						object.CanCollide
				end

				object.CanCollide =
					false
			end
		end
	end
)

--========================================================
-- CHARACTER ADDED
--========================================================

Player.CharacterAdded:Connect(
	function(character)

		task.wait(0.5)

		setupCharacter(
			character
		)

		if NOCLIP then

			task.wait(0.1)

			enableNoClip()
		end

		if GOD_MODE then

			task.wait(0.2)

			enableGodMode()
		end
	end
)

--========================================================
-- FIND OBJECT
--========================================================

local function findNamedObject(
	name
)

	local object =
		Workspace:FindFirstChild(
			name,
			true
		)

	if object then
		return object
	end

	local wanted =
		string.lower(name)

	for _, descendant in ipairs(
		Workspace:GetDescendants()
	) do

		if string.lower(
			descendant.Name
		) == wanted then

			return descendant
		end
	end

	return nil
end

--========================================================
-- GET PART
--========================================================

local function getPart(
	object
)

	if not object then
		return nil
	end

	if object:IsA(
		"BasePart"
	) then

		return object
	end

	if object:IsA(
		"Model"
	) then

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
-- SAFEZONE
--========================================================

local function findSafeZone()

	local object =
		findNamedObject(
			SAFEZONE_NAME
		)

	return getPart(
		object
	)
end

--========================================================
-- TITAN TEMPLE
--========================================================

local function findTemple()

	local object =
		findNamedObject(
			TEMPLE_NAME
		)

	return getPart(
		object
	)
end

--========================================================
-- EGG PROMPT
--========================================================

local function isEggPrompt(
	prompt
)

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

	if prompt.Parent then

		text =
			text
			.. " "
			.. string.lower(
				prompt.Parent.Name
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
-- PROMPT POSITION
--========================================================

local function getPromptPosition(
	prompt
)

	if not prompt
		or not prompt.Parent then

		return nil
	end

	local parent =
		prompt.Parent

	if parent:IsA(
		"BasePart"
	) then

		return parent.Position
	end

	if parent:IsA(
		"Attachment"
	) then

		return parent.WorldPosition
	end

	local part =
		getPart(parent)

	if part then
		return part.Position
	end

	local ancestor =
		parent:FindFirstAncestorWhichIsA(
			"BasePart"
		)

	if ancestor then
		return ancestor.Position
	end

	return nil
end

--========================================================
-- FIND EGG
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

	local closest =
		nil

	local closestDistance =
		math.huge

	for _, object in ipairs(
		Workspace:GetDescendants()
	) do

		if object:IsA(
			"ProximityPrompt"
		)
		and isEggPrompt(object)
		then

			local position =
				getPromptPosition(
					object
				)

			if position then

				local templeDistance =
					(
						position
						- templePosition
					).Magnitude

				if templeDistance
					<= TEMPLE_EGG_RADIUS then

					local playerDistance =
						(
							position
							- HRP.Position
						).Magnitude

					if playerDistance
						< closestDistance then

						closestDistance =
							playerDistance

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

	moving =
		false

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

	moving =
		true

	local startTime =
		os.clock()

	local reached =
		false

	while moving
		and Character
		and Character.Parent
		and HRP
		and HRP.Parent
		and Humanoid
		and Humanoid.Parent
		and os.clock() - startTime
			< timeout do

		local offset =
			targetPosition
			- HRP.Position

		local distance =
			offset.Magnitude

		if distance
			<= distanceLimit then

			reached =
				true

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
			direction
			* SPEED

		RunService.Heartbeat:Wait()
	end

	stopMovement()

	return reached
end

--========================================================
-- RETURN SAFEZONE
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

local function activatePrompt(
	prompt
)

	if not prompt
		or not prompt.Parent then

		return false
	end

	local position =
		getPromptPosition(
			prompt
		)

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

	missionRunning =
		true

	--====================================================
	-- TEMPLE
	--====================================================

	local temple =
		findTemple()

	if not temple then

		missionRunning =
			false

		return
	end

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

	--====================================================
	-- EGG
	--====================================================

	local egg =
		findEggPrompt()

	if not egg then

		missionRunning =
			false

		return
	end

	currentEgg =
		egg

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

	--====================================================
	-- APPROACH EGG
	--====================================================

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

	--====================================================
	-- PICKUP
	--====================================================

	if egg
		and egg.Parent
		and HRP
		and HRP.Parent then

		task.wait(
			PICKUP_DELAY
		)

		activatePrompt(
			egg
		)
	end

	currentEgg =
		nil

	--====================================================
	-- RETURN
	--====================================================

	if AUTO_RETURN then

		returnToSafeZone()
	end

	missionRunning =
		false
end

--========================================================
-- PROMPT CONNECTION
--========================================================

local function connectPrompt(
	prompt
)

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

		connectPrompt(
			object
		)
	end
end

Workspace.DescendantAdded:Connect(
	function(object)

		if object:IsA(
			"ProximityPrompt"
		) then

			connectPrompt(
				object
			)
		end
	end
)

--========================================================
-- REMOVE OLD UI
--========================================================

local oldGui =
	PlayerGui:FindFirstChild(
		"LuckyHubUI"
	)

if oldGui then
	oldGui:Destroy()
end

--========================================================
-- SCREEN GUI
--========================================================

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

DragHandle.Active =
	true

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
	Instance.new(
		"UICorner"
	)

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
	Instance.new(
		"TextLabel"
	)

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
		Instance.new(
			"TextButton"
		)

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
		Instance.new(
			"UICorner"
		)

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

local NoClipButton =
	createButton(
		"NoClip",
		"NOCLIP : OFF",
		188
	)

--========================================================
-- SPEED LABEL
--========================================================

local SpeedLabel =
	Instance.new(
		"TextLabel"
	)

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
		228
	)

SpeedLabel.BackgroundTransparency =
	1

SpeedLabel.Text =
	"SPEED : "
		.. tostring(
			SPEED
		)

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
	Instance.new(
		"Frame"
	)

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
		255
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
	Instance.new(
		"UICorner"
	)

SliderCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

SliderCorner.Parent =
	Slider

local Fill =
	Instance.new(
		"Frame"
	)

local initialPercent =
	math.clamp(
		(
			SPEED
			- MIN_SPEED
		)
		/
		(
			MAX_SPEED
			- MIN_SPEED
		),
		0,
		1
	)

Fill.Size =
	UDim2.new(
		initialPercent,
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
	Instance.new(
		"UICorner"
	)

FillCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

FillCorner.Parent =
	Fill

local SliderButton =
	Instance.new(
		"TextButton"
	)

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
		initialPercent,
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
--========================================================
-- SPEED SLIDER INPUT
--========================================================

local sliderDragging =
	false

local function setSpeedFromInput(
	input
)

	local sliderSize =
		Slider.AbsoluteSize

	if sliderSize.X <= 0 then
		return
	end

	local x =
		input.Position.X
		- Slider.AbsolutePosition.X

	local percent =
		math.clamp(
			x / sliderSize.X,
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
		.. tostring(
			SPEED
		)
end

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

		if GOD_MODE then

			GodModeButton.Text =
				"GOD MODE : OFF"

			Status.Text =
				"God Mode disabled"

			disableGodMode()

		else

			GodModeButton.Text =
				"GOD MODE : ON"

			Status.Text =
				"God Mode enabled"

			enableGodMode()
		end
	end
)

--========================================================
-- NOCLIP BUTTON
--========================================================

NoClipButton.Activated:Connect(
	function()

		NOCLIP =
			not NOCLIP

		if NOCLIP then

			NoClipButton.Text =
				"NOCLIP : ON"

			Status.Text =
				"NoClip enabled"

			enableNoClip()

		else

			NoClipButton.Text =
				"NOCLIP : OFF"

			Status.Text =
				"NoClip disabled"

			disableNoClip()
		end
	end
)

--========================================================
-- MINI BALL
--========================================================

local Mini =
	Instance.new(
		"TextButton"
	)

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
	Instance.new(
		"UICorner"
	)

MiniCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

MiniCorner.Parent =
	Mini

local MiniStroke =
	Instance.new(
		"UIStroke"
	)

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
-- APPLY SPEED
--========================================================

RunService.Heartbeat:Connect(
	function()

		if Humanoid
			and Humanoid.Parent
			and not moving then

			Humanoid.WalkSpeed =
				SPEED
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

			elseif NOCLIP then

				Status.Text =
					"NoClip : ON"

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
-- CLEANUP
--========================================================

ScreenGui.AncestryChanged:Connect(
	function(
		_,
		parent
	)

		if parent then
			return
		end

		missionRunning =
			false

		moving =
			false

		AUTO_STEAL =
			false

		AUTO_RETURN =
			false

		if NOCLIP then

			NOCLIP =
				false

			disableNoClip()
		end

		if GOD_MODE then

			GOD_MODE =
				false

			disconnectGodConnections()
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
local SliderButtonCorner =
	Instance.new(
		"UICorner"
	)

SliderButtonCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

SliderButtonCorner.Parent =
	SliderButton
