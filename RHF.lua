local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/memejames/elerium-v2-ui-library/main/Library", true))()

local window = library:AddWindow("Legacy | RHF | UNRELEASED", {
	main_color = Color3.fromRGB(65 ,65, 65),
	min_size = Vector2.new(250, 260),
	can_resize = false,
})

local AR = window:AddTab("Main")
AR:Show()

-- // SERVICES
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer

---------------------------------------------------------------------
-- Position Saver [F] [Z]
---------------------------------------------------------------------
AR:AddButton("Position Saver [F] [Z]", function()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local savedCFrame = nil

    player.CharacterAdded:Connect(function(char)
        character = char
        humanoidRootPart = char:WaitForChild("HumanoidRootPart")
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F then
            if savedCFrame == nil then
                savedCFrame = humanoidRootPart.CFrame
                warn("CFrame saved!")
            else
                humanoidRootPart.CFrame = savedCFrame
                warn("Teleported to saved CFrame!")
            end
        elseif input.KeyCode == Enum.KeyCode.Z then
            savedCFrame = nil
            warn("Saved CFrame cleared!")
        end
    end)
end)

---------------------------------------------------------------------
-- KillBoundary Remover
---------------------------------------------------------------------
AR:AddButton("KillBoundary Remover", function()
    task.spawn(function()
        while true do
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == "KillBoundary" then
                    obj:Destroy()
                    print("Deleted KillBoundary:", obj:GetFullName())
                end
            end
            task.wait(1)
        end
    end)
end)

---------------------------------------------------------------------
-- Shooter ESP (Persistent Highlight)
---------------------------------------------------------------------
AR:AddButton("Shooter ESP", function()
    local weapons = {"AK47","UZI","M4","Shotgun","Pistol"}
    local highlightedPlayers = {} -- Track who is already highlighted

    local function hasWeapon(character)
        for _, name in ipairs(weapons) do
            if character:FindFirstChild(name) then
                return true
            end
        end
        return false
    end

    local function highlightCharacter(character)
        if not character then return end
        local plr = Players:GetPlayerFromCharacter(character)
        if plr == player then return end
        if character:FindFirstChild("WeaponHighlight") then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "WeaponHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Parent = character
    end

    RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") and not highlightedPlayers[plr] then
                if hasWeapon(char) then
                    highlightCharacter(char)
                    highlightedPlayers[plr] = true -- mark as highlighted
                    -- Cleanup on death
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.Died:Connect(function()
                            highlightedPlayers[plr] = nil
                        end)
                    end
                end
            end
        end
    end)
end)


---------------------------------------------------------------------
-- Wall Clipper [V]
---------------------------------------------------------------------
AR:AddButton("Wall Clipper [V]", function()
    local character = player.Character or player.CharacterAdded:Wait()
    player.CharacterAdded:Connect(function(char) character = char end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.V then
            if character and character:FindFirstChild("HumanoidRootPart") then
                local hrp = character.HumanoidRootPart
                hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
            end
        end
    end)
end)

---------------------------------------------------------------------
-- Ragdoll Dash
---------------------------------------------------------------------
AR:AddButton("Ragdoll Dash [Q]", function()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    player.CharacterAdded:Connect(function(char)
        character = char
        humanoidRootPart = char:WaitForChild("HumanoidRootPart")
    end)

    local dashPower = 80
    local dashDelay = 0.2
    local canDash = true
    local dashToggle = true

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Q then
            if dashToggle and canDash then
                canDash = false
                task.wait(dashDelay)

                local bv = Instance.new("BodyVelocity")
                bv.Velocity = humanoidRootPart.CFrame.LookVector * dashPower
                bv.MaxForce = Vector3.new(100000,100000,100000)
                bv.Parent = humanoidRootPart

                Debris:AddItem(bv, 0.2)

                task.wait(0.5)
                canDash = true
            end
            dashToggle = not dashToggle
        end
    end)
end)

---------------------------------------------------------------------
-- Universal ESP Toggle
---------------------------------------------------------------------
-- Global ESP flag
local ESPEnabled = false
local highlights = {} -- track all Highlight instances
local LocalPlayer = player

AR:AddSwitch("ESP", function(bool)
    ESPEnabled = bool

    -- Function to highlight a character
    local function highlightCharacter(character)
        if not character then return end
        if Players:GetPlayerFromCharacter(character) == LocalPlayer then return end
        if character:FindFirstChild("UniversalHighlight") then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "UniversalHighlight"
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Parent = character

        highlights[character] = highlight
    end

    -- Function to remove all highlights
    local function removeAllHighlights()
        for char, hl in pairs(highlights) do
            if hl and hl.Parent then
                hl:Destroy()
            end
        end
        highlights = {}
    end

    if ESPEnabled then
        -- Highlight existing characters
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                highlightCharacter(plr.Character)
            end
        end
    else
        removeAllHighlights()
    end
end)

-- Handle new players and respawns
local function onCharacterAdded(char)
    task.wait(1) -- wait for HumanoidRootPart
    if ESPEnabled then
        highlightCharacter(char)
    end
end

local function onPlayerAdded(plr)
    plr.CharacterAdded:Connect(onCharacterAdded)
end

-- Connect existing players
for _, plr in ipairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(onCharacterAdded)
end

-- Connect new players joining
Players.PlayerAdded:Connect(onPlayerAdded)
