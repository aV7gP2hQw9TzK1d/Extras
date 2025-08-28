-- Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Character tracking
local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char) character = char end)

-- Feature toggles
local noclipEnabled = false
local highlightEnabled = false
local resizeEnabled = false
local airJumpEnabled = false -- NEW: Air jump toggle
local currentTeam = player.Team
local partsToNoclip = {"UpperTorso", "LowerTorso", "HumanoidRootPart"}

-- UI Library Setup
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/memejames/elerium-v2-ui-library/main/Library", true))()
local window = library:AddWindow("Legitbreak | ALPHA v0.1", {
	main_color = Color3.fromRGB(255, 0, 0),
	min_size = Vector2.new(250, 250),
	can_resize = false,
})
local Main = window:AddTab("Main")
Main:Show()
Main:AddLabel("Features")

-- NoClip logic
local function setNoclipState(state)
	for _, partName in ipairs(partsToNoclip) do
		local part = character:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			part.CanCollide = state
		end
	end
end

RunService.Stepped:Connect(function()
	if noclipEnabled then
		setNoclipState(false)
	end
end)

Main:AddSwitch("NoClip", function(bool)
	noclipEnabled = bool
	if not bool then
		setNoclipState(true)
	end
end):Set(false)

-- ESP & Billboard logic
local function addHighlight(target, color)
	if target and not target:FindFirstChild("Highlight") then
		local hl = Instance.new("Highlight")
		hl.Name = "Highlight"
		hl.FillColor = color
		hl.OutlineColor = Color3.new(1, 1, 1)
		hl.OutlineTransparency = 0
		hl.Parent = target
	end
end

local function addBillboard(target, name, highlightColor)
	if not target:FindFirstChild("DisplayNameBillboard") then
		local head = target:FindFirstChild("Head")
		if head then
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "DisplayNameBillboard"
			billboard.Size = UDim2.new(0, 150, 0, 32)
			billboard.StudsOffset = Vector3.new(0, 3, 0)
			billboard.AlwaysOnTop = true
			billboard.Adornee = head
			billboard.Parent = target

			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.TextColor3 = highlightColor
			textLabel.TextStrokeTransparency = 0.5
			textLabel.Text = name
			textLabel.Font = Enum.Font.SourceSansBold
			textLabel.TextScaled = true
			textLabel.Parent = billboard
		end
	end
end

local function removeAllHighlightsAndBillboards()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local char = otherPlayer.Character
			if char then
				local hl = char:FindFirstChild("Highlight")
				if hl then hl:Destroy() end
				local bb = char:FindFirstChild("DisplayNameBillboard")
				if bb then bb:Destroy() end
			end
		end
	end
end

local function resetEnemyHumanoidRootParts()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local char = otherPlayer.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.Size = Vector3.new(2, 2, 2) end
			end
		end
	end
end

local function updateEnemyVisuals()
	local myTeam = player.Team
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Team and otherPlayer.Team ~= myTeam then
			if otherPlayer.Team.Name ~= "Prisoner" then
				local char = otherPlayer.Character
				if char then
					if highlightEnabled then
						addHighlight(char, otherPlayer.Team.TeamColor.Color)
						addBillboard(char, otherPlayer.DisplayName, otherPlayer.Team.TeamColor.Color)
					end
					if resizeEnabled then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp then hrp.Size = Vector3.new(12, 12, 12) end
					end
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	if highlightEnabled or resizeEnabled then
		if player.Team ~= currentTeam then
			currentTeam = player.Team
			removeAllHighlightsAndBillboards()
			resetEnemyHumanoidRootParts()
		end
		updateEnemyVisuals()
	end
end)

Main:AddSwitch("ESP", function(bool)
	highlightEnabled = bool
	currentTeam = player.Team
	if not bool then removeAllHighlightsAndBillboards() end
end)

Main:AddSwitch("Extend Hitboxes", function(bool)
	resizeEnabled = bool
	currentTeam = player.Team
	if not bool then resetEnemyHumanoidRootParts() end
end)

-- AIR JUMP LOGIC
local humanoid = character:WaitForChild("Humanoid")
local jumpPressed = false

-- Update humanoid on respawn
player.CharacterAdded:Connect(function(char)
	humanoid = char:WaitForChild("Humanoid")
end)

-- Jump detection
UserInputService.JumpRequest:Connect(function()
	if not airJumpEnabled then return end -- Only works when toggle is on
	if jumpPressed then return end -- Prevent spam while holding
	jumpPressed = true

	if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- Reset jumpPressed when space released
UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
		jumpPressed = false
	end
end)

-- Air jump toggle in UI
Main:AddSwitch("Air Jump", function(bool)
	airJumpEnabled = bool
end):Set(false)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Function to check if a humanoid belongs to a player
local function isPlayerCharacter(humanoid)
    local character = humanoid.Parent
    if not character then return false end
    local player = Players:GetPlayerFromCharacter(character)
    return player ~= nil
end

-- Function to kill all NPCs
local function killAllNPCs()
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") and not isPlayerCharacter(descendant) then
            descendant.Health = 0
        end
    end
end

-- Button calls the function
Main:AddButton("Kill All NPC", function()
    killAllNPCs()
end)
