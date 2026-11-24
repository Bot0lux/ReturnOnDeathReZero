local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- Config
local TEXT_ON = "Return on Death:On"
local TEXT_OFF = "Return on Death:Off"
local LOOKBACK_SECONDS = 3
local DECAL_ID = "108076229359983"
local SOUND_ID = "rbxassetid://82659851472919"
local ANIM_R15 = "88129916109334"
local ANIM_R6 = "129423030"
local R6_START_TIME = 0.65
local R15_START_TIME = 0

-- Respawn Config
local RESPAWN_MSG_1 = "What happened...?"
local RESPAWN_DECAL_1 = "84378782157822"

local RESPAWN_MSG_2 = "Huh... I'm still here."
local RESPAWN_DECAL_2 = "110917638721451"

local RESPAWN_MSG_3 = "Not again..."
local RESPAWN_DECAL_3 = "112896119444512"

local RESPAWN_MSG_4 = "Did I just die?"
local RESPAWN_DECAL_4 = "75755410973596"

local RESPAWN_MSG_5 = "I'm back."
local RESPAWN_DECAL_5 = "92622438153415"

local function getIcon(id)
	local clean = tostring(id):gsub("^rbxassetid://", ""):match("%d+")
	if not clean or clean == "0" then
		return nil
	end
	return "rbxthumb://type=Asset&id=" .. clean .. "&w=150&h=150"
end

local function notify(title, text, duration, icon)
	pcall(function()
		local opts = {
			Title = title,
			Text = text,
			Duration = duration or 3
		}
		if icon then
			opts.Icon = icon
		end
		StarterGui:SetCore("SendNotification", opts)
	end)
end

local function getRandomRespawnEntry()
	local entries = {
		{ msg = RESPAWN_MSG_1, decal = RESPAWN_DECAL_1 },
		{ msg = RESPAWN_MSG_2, decal = RESPAWN_DECAL_2 },
		{ msg = RESPAWN_MSG_3, decal = RESPAWN_DECAL_3 },
		{ msg = RESPAWN_MSG_4, decal = RESPAWN_DECAL_4 },
		{ msg = RESPAWN_MSG_5, decal = RESPAWN_DECAL_5 }
	}
	local pool = {}
	for _, entry in ipairs(entries) do
		if type(entry.msg) == "string" and entry.msg ~= "" then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		return nil
	end
	local chosen = pool[math.random(1, #pool)]
	local icon = getIcon(chosen.decal) or getIcon(DECAL_ID)
	return chosen.msg, icon
end

notify("ReturnOnDeath", "Made by Bot Lux", 3, getIcon(DECAL_ID))

local lastDeathCFrame = nil
local returnOnDeathEnabled = false
local positionHistory = {}
local guiDestroyed = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ReturnOnDeathGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 185, 0, 90)
mainFrame.Position = UDim2.new(0.5, -92, 0.05, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ReturnOnDeathButton"
toggleButton.Size = UDim2.new(1, 0, 0, 40)
toggleButton.Position = UDim2.new(0, 0, 0, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = TEXT_OFF
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Parent = mainFrame

local deleteButton = Instance.new("TextButton")
deleteButton.Name = "DeleteButton"
deleteButton.Size = UDim2.new(1, 0, 0, 40)
deleteButton.Position = UDim2.new(0, 0, 0, 45)
deleteButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteButton.Text = "Delete"
deleteButton.Font = Enum.Font.GothamBold
deleteButton.TextSize = 16
deleteButton.Parent = mainFrame

local yesButton = Instance.new("TextButton")
yesButton.Size = UDim2.new(0.5, -5, 0, 30)
yesButton.Position = UDim2.new(0, 0, 1, 5)
yesButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
yesButton.Text = "Yes"
yesButton.Visible = false
yesButton.Parent = mainFrame

local noButton = Instance.new("TextButton")
noButton.Size = UDim2.new(0.5, -5, 0, 30)
noButton.Position = UDim2.new(0.5, 5, 1, 5)
noButton.BackgroundColor3 = Color3.fromRGB(150, 150, 0)
noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noButton.Text = "No"
noButton.Visible = false
noButton.Parent = mainFrame

toggleButton.MouseButton1Click:Connect(function()
	returnOnDeathEnabled = not returnOnDeathEnabled
	toggleButton.Text = returnOnDeathEnabled and TEXT_ON or TEXT_OFF
end)

deleteButton.MouseButton1Click:Connect(function()
	yesButton.Visible = true
	noButton.Visible = true
end)

yesButton.MouseButton1Click:Connect(function()
	returnOnDeathEnabled = false
	guiDestroyed = true
	toggleButton.Text = TEXT_OFF
	notify("ReturnOnDeath", "Removed", 2)
	task.wait(2)
	screenGui:Destroy()
end)

noButton.MouseButton1Click:Connect(function()
	yesButton.Visible = false
	noButton.Visible = false
end)

task.spawn(function()
	while not guiDestroyed and screenGui.Parent do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local now = os.clock()
			table.insert(positionHistory, { t = now, cf = hrp.CFrame })
			while #positionHistory > 0 and now - positionHistory[1].t > LOOKBACK_SECONDS do
				table.remove(positionHistory, 1)
			end
		end
		task.wait(0.1)
	end
end)

local function resolveAnimId(rawId)
	local clean = tostring(rawId):gsub("^rbxassetid://", "")
	local resolved = "rbxassetid://" .. clean
	if type(game.GetObjects) == "function" then
		local ok, objs = pcall(function()
			return game:GetObjects("rbxassetid://" .. clean)
		end)
		if ok and objs and #objs > 0 then
			local obj = objs[1]
			if obj:IsA("Animation") and obj.AnimationId ~= "" then
				resolved = obj.AnimationId
			else
				local innerAnim = obj:FindFirstChildOfClass("Animation")
				if innerAnim and innerAnim.AnimationId ~= "" then
					resolved = innerAnim.AnimationId
				end
			end
		end
	end
	return resolved
end

local function playFeedback(hum, hrp)
	local msg, icon = getRandomRespawnEntry()
	if msg then
		notify("ReturnOnDeath", msg, 3, icon)
	end

	if SOUND_ID ~= "" and hrp then
		local sound = Instance.new("Sound")
		sound.SoundId = SOUND_ID
		sound.Looped = false
		sound.Parent = hrp
		sound:Play()
		Debris:AddItem(sound, 6)
	end

	local isR6 = hum.RigType == Enum.HumanoidRigType.R6
	local rawAnim = isR6 and ANIM_R6 or ANIM_R15
	local startTime = isR6 and R6_START_TIME or R15_START_TIME

	if rawAnim ~= "" and hum then
		local animId = resolveAnimId(rawAnim)
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		pcall(function()
			local animator = hum:FindFirstChildOfClass("Animator") or hum
			local track = animator:LoadAnimation(anim)
			track.Priority = Enum.AnimationPriority.Action4
			track.Looped = false
			track:Play()

			if startTime > 0 then
				task.spawn(function()
					local elapsed = 0
					while track.Length <= 0 and elapsed < 2 do
						elapsed += task.wait(0.05)
					end
					if track.IsPlaying and track.Length > 0 then
						track.TimePosition = math.clamp(startTime, 0, math.max(0, track.Length - 0.05))
					end
				end)
			end
		end)
	end
end

local function returnToPosition(targetCFrame, char)
	local hum = char:WaitForChild("Humanoid", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hum or not hrp then
		return
	end

	task.wait(0.2)
	if guiDestroyed or not returnOnDeathEnabled then
		return
	end

	hrp.CFrame = targetCFrame
	playFeedback(hum, hrp)
end

local function setupCharacter(char)
	local humanoid = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")

	humanoid.Died:Connect(function()
		if returnOnDeathEnabled then
			lastDeathCFrame = hrp.CFrame
		end
	end)
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(function(char)
	setupCharacter(char)
	if guiDestroyed or not returnOnDeathEnabled then
		return
	end

	local target = (#positionHistory > 0 and positionHistory[1].cf) or lastDeathCFrame
	if target then
		returnToPosition(target, char)
	end
end)

local dragging, dragInput, dragStart, startPos

local function updateInput(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

toggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

toggleButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateInput(input)
	end
end)
