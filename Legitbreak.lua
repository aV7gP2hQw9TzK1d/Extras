-- Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

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
local autoSprintEnabled = false

-- AIMBOT LOGIC
local aimbotEnabled = false
local aimbotCircle = nil
local rightMouseDown = false

-- UI Library Setup
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/memejames/elerium-v2-ui-library/main/Library", true))()
local window = library:AddWindow("Legitbreak | ALPHA v0.7", {
	main_color = Color3.fromRGB(255, 0, 0),
	min_size = Vector2.new(250, 290),
	can_resize = false,
})
local Main = window:AddTab("Main")
Main:Show()
Main:AddLabel("🔑 | Features")

-- Create circle UI
local function createAimbotCircle()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimbotGUI"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.IgnoreGuiInset = true

    local circle = Instance.new("Frame")
    circle.Name = "AimbotCircle"
    circle.Size = UDim2.new(0, 150, 0, 150)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Parent = screenGui

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = circle

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0.5, 0)
    uicorner.Parent = circle

    return screenGui
end

-- Get closest target inside circle
local function getClosestTarget()
    local closest = nil
    local shortestDist = math.huge
    local mousePos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local myTeam = player.Team.Name

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- Only target enemy teams
            local otherTeam = otherPlayer.Team.Name
            if otherTeam ~= myTeam and otherTeam ~= "Prisoner" then
                local hrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local delta = Vector2.new(screenPos.X, screenPos.Y) - mousePos
                    if delta.Magnitude <= 75 then
                        if delta.Magnitude < shortestDist then
                            closest = hrp
                            shortestDist = delta.Magnitude
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- Right mouse detection
UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = true
    end
end)

UserInputService.InputEnded:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = false
    end
end)

-- Switch for aimbot
Main:AddSwitch("Aimbot", function(bool)
    aimbotEnabled = bool

    if bool then
        aimbotCircle = createAimbotCircle()
    else
        if aimbotCircle then
            aimbotCircle:Destroy()
            aimbotCircle = nil
        end
    end
end)

-- Aimlock logic
RunService.RenderStepped:Connect(function()
    if aimbotEnabled and rightMouseDown then
        local targetHRP = getClosestTarget()
        if targetHRP then
            -- Smooth snap camera to the target's Torso/UpperTorso
            local targetPos = targetHRP.Position
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end
end)


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

-- 🔥 FAKE HITBOX LOGIC
local function addFakeHitbox(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and not char:FindFirstChild("FakeHitbox") then
        local hitbox = Instance.new("Part")
        hitbox.Name = "FakeHitbox"
        hitbox.Size = Vector3.new(12, 12, 12)
        hitbox.Transparency = 0.5 -- for testing (set to 1 later)
        hitbox.Color = Color3.fromRGB(255, 0, 0)
        hitbox.CanCollide = false
        hitbox.Massless = true
        hitbox.Anchored = false
        hitbox.Parent = char

        -- Use a Motor6D instead of WeldConstraint for proper alignment
        local motor = Instance.new("Motor6D")
        motor.Name = "HitboxMotor"
        motor.Part0 = hrp
        motor.Part1 = hitbox
        motor.C0 = CFrame.new() -- keep centered
        motor.Parent = hrp
    end
end


local function removeFakeHitbox(char)
	local fake = char:FindFirstChild("FakeHitbox")
	if fake then fake:Destroy() end
end

local function resetEnemyFakeHitboxes()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			removeFakeHitbox(otherPlayer.Character)
		end
	end
end

-- Visual update loop
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
						addFakeHitbox(char)
					else
						removeFakeHitbox(char)
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
			resetEnemyFakeHitboxes()
		end
		updateEnemyVisuals()
	end
end)

-- WalkSpeed Lock
local walkspeedSwitch = nil
walkspeedSwitch = Main:AddSwitch("Auto Sprint", function(state)
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	if not hum then return end

	if state then
		walkspeedLocked = true
		hum.WalkSpeed = 24
		if walkspeedConnection then walkspeedConnection:Disconnect() end
		walkspeedConnection = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if walkspeedLocked and hum.WalkSpeed ~= 24 then
				hum.WalkSpeed = 24
			end
		end)
	else
		walkspeedLocked = false
		if walkspeedConnection then
			walkspeedConnection:Disconnect()
			walkspeedConnection = nil
		end
		hum.WalkSpeed = 16
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
	if not bool then resetEnemyFakeHitboxes() end
end)

-- AIR JUMP LOGIC
local humanoid = character:WaitForChild("Humanoid")
local jumpPressed = false

player.CharacterAdded:Connect(function(char)
	humanoid = char:WaitForChild("Humanoid")
end)

UserInputService.JumpRequest:Connect(function()
	if not airJumpEnabled then return end
	if jumpPressed then return end
	jumpPressed = true

	if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
		jumpPressed = false
	end
end)

Main:AddSwitch("Air Jump", function(bool)
	airJumpEnabled = bool
end):Set(false)

-- NPC Kill Logic
local function isPlayerCharacter(humanoid)
	local character = humanoid.Parent
	if not character then return false end
	local plr = Players:GetPlayerFromCharacter(character)
	return plr ~= nil
end

local function isActiveBoss(humanoid)
	local parent = humanoid.Parent
	while parent do
		if parent.Name == "ActiveBoss" then
			return true
		end
		parent = parent.Parent
	end
	return false
end

local function killAllNPCs()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Humanoid") 
		and not isPlayerCharacter(descendant) 
		and not isActiveBoss(descendant) then
			descendant.Health = 0
		end
	end
end

Main:AddButton("Kill All NPC", function()
	killAllNPCs()
end)

-- Money Earned tracker
local moneyEarned = 0
local moneyLabel = Main:AddLabel("💰 | Money Earned: $0")

local leaderstats = player:WaitForChild("leaderstats")
local money = leaderstats:WaitForChild("Money")
local lastMoney = money.Value

local function formatNumber(n)
	return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function updateMoneyLabel()
	moneyLabel.Text = "💰 | Money Earned: $" .. formatNumber(moneyEarned)
end

money:GetPropertyChangedSignal("Value"):Connect(function()
	local newMoney = money.Value
	local diff = newMoney - lastMoney

	if diff > 0 then
		moneyEarned = moneyEarned + diff
		updateMoneyLabel()
	end

	lastMoney = newMoney
end)
