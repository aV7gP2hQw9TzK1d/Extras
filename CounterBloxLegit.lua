-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer

-- Circle UI (always hidden)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimCircleGui"
screenGui.Parent = game:GetService("CoreGui")
screenGui.IgnoreGuiInset = true

local circle = Instance.new("Frame")
circle.Name = "AimCircle"
circle.Size = UDim2.new(0, 40, 0, 40)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.new(0.5, 0, 0.5, 0)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 0
circle.Visible = false -- permanently invisible
circle.Parent = screenGui

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.new(1, 1, 1) -- white
stroke.Parent = circle

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0.5, 0)
uicorner.Parent = circle

-- Aim settings
local leftClickDown = false
local aimSpeed = 0.1 -- smaller is slower, adjust for smoothness
local aimRadius = 20 -- half of circle size

-- ESP settings
local espEnabled = false
local highlights = {}
local aimbotEnabled = false

-- Head hitbox resizer settings
local resizeEnabled = false
local resizeInterval = 2
local resizeSize = Vector3.new(12, 12, 12)
local lastResizeTime = 0

-- Helper function: get closest enemy target inside circle (head as round)
local function getClosestTarget()
    local closest = nil
    local shortestDist = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Team ~= player.Team and otherPlayer.Character and otherPlayer.Character:FindFirstChild("Head") then
            local head = otherPlayer.Character.Head
            local headRadius = (head.Size.X + head.Size.Y)/4 -- approx radius
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local delta = Vector2.new(screenPos.X, screenPos.Y) - screenCenter
                if delta.Magnitude <= aimRadius + headRadius and delta.Magnitude < shortestDist then
                    closest = head
                    shortestDist = delta.Magnitude
                end
            end
        end
    end

    return closest
end

-- Function to add highlight to a single player
local function addHighlightToPlayer(otherPlayer)
    if otherPlayer.Character and not highlights[otherPlayer] then
        local highlight = Instance.new("Highlight")
        highlight.Name = "EnemyESP"
        highlight.Adornee = otherPlayer.Character
        highlight.FillColor = Color3.fromRGB(0, 255, 0) -- green fill
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- white outline
        highlight.OutlineTransparency = 0
        highlight.Parent = Camera
        highlights[otherPlayer] = highlight

        -- Re-attach highlight on respawn
        otherPlayer.CharacterAdded:Connect(function(newChar)
            if espEnabled then
                if highlights[otherPlayer] then
                    highlights[otherPlayer]:Destroy()
                    highlights[otherPlayer] = nil
                end
                addHighlightToPlayer(otherPlayer)
            end
        end)
    end
end

-- Function to update ESP for all enemy players
local function updateESP()
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Team ~= player.Team then
            addHighlightToPlayer(otherPlayer)
        end
    end

    -- Remove highlights for players who left or changed team
    for p, highlight in pairs(highlights) do
        if not p.Parent or not p.Character or p.Team == player.Team then
            highlight:Destroy()
            highlights[p] = nil
        end
    end
end

-- Function to resize enemy hitboxes
local function resizeEnemyHitboxes()
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Team ~= player.Team and otherPlayer.Character then
            local headHB = otherPlayer.Character:FindFirstChild("HeadHB")
            if headHB and headHB:IsA("BasePart") then
                headHB.Size = resizeSize
            end
        end
    end
end

-- Input detection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        leftClickDown = true

    elseif input.KeyCode == Enum.KeyCode.F1 then
        aimbotEnabled = not aimbotEnabled
        print("Aimbot: " .. (aimbotEnabled and "ON" or "OFF"))

    elseif input.KeyCode == Enum.KeyCode.F2 then
        espEnabled = not espEnabled
        print("ESP: " .. (espEnabled and "ON" or "OFF"))
        if not espEnabled then
            for _, highlight in pairs(highlights) do
                highlight:Destroy()
            end
            highlights = {}
        else
            updateESP()
        end

    elseif input.KeyCode == Enum.KeyCode.F3 then
        resizeEnabled = not resizeEnabled
        print("HeadHB Resizer: " .. (resizeEnabled and "ON" or "OFF"))
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        leftClickDown = false
    end
end)

-- Render loop
RunService.RenderStepped:Connect(function(delta)
    if aimbotEnabled and leftClickDown then
        local target = getClosestTarget()
        if target then
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, target.Position)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, aimSpeed)
        end
    end

    if espEnabled then
        updateESP()
    end

    if resizeEnabled and tick() - lastResizeTime >= resizeInterval then
        resizeEnemyHitboxes()
        lastResizeTime = tick()
    end
end)

-- Player added/removed listeners for dynamic ESP + resizer
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if espEnabled then
            addHighlightToPlayer(p)
        end
        if resizeEnabled then
            task.wait(1) -- give time to load
            resizeEnemyHitboxes()
        end
    end)
end)

Players.PlayerRemoving:Connect(function(playerRemoved)
    if highlights[playerRemoved] then
        highlights[playerRemoved]:Destroy()
        highlights[playerRemoved] = nil
    end
end)

-- Initial ESP for existing players
if espEnabled then
    updateESP()
end
