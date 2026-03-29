-- [[ SERVICES ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager") 
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [[ STATIC MEMORY & OPTIMIZATION ARRAYS ]] --
local DefaultFOV = Camera.FieldOfView
local GlobalRayParams = RaycastParams.new()
GlobalRayParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRayParams.IgnoreWater = true

local CachedCharacter = nil
local OriginalC0s = {}
local TPActive = false

local OriginalAmbient = Lighting.Ambient
local OriginalOutdoorAmbient = Lighting.OutdoorAmbient
local EnvActive = false

local DefaultWS = 16
local DefaultJP = 50
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
    DefaultWS = LocalPlayer.Character.Humanoid.WalkSpeed
    DefaultJP = LocalPlayer.Character.Humanoid.JumpPower
end

local VisibilityOffsets = {
    Vector3.new(0, 0, 0),
    Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
    Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
    Vector3.new(0, 0, 1), Vector3.new(0, 0, -1)
}

local Box3D_Connections = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
local R15_Joints = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}}
local R6_Joints = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}

-- [[ UTILITIES ]] --
local function getKeyCodeFromString(keyStr)
    if type(keyStr) ~= "string" or keyStr == "None" or keyStr == "" then return nil end
    local success, key = pcall(function() return Enum.KeyCode[keyStr] end)
    return success and key or nil
end

-- [[ UI LIBRARY ]] --
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- [[ SETTINGS TABLE ]] --
local Settings = {
    Master = false,
    TeamCheck = false,
    IgnorePrisoners = false, 
    ESPOptimizer = 1000, 
    ESPVisCheck = false,
    
    -- [[ PLAYER SETTINGS ]] --
    PlayerMaster = false,
    FlyEnabled = false, FlyMode = "Hold", FlyKey = "None", FlySpeed = 150,
    NoclipEnabled = false, NoclipMode = "Hold", NoclipKey = "None",
    InfJumpEnabled = false,
    TPForwardEnabled = false, TPForwardKey = "None", TPForwardStuds = 5,
    StatsEnabled = false, WalkSpeed = DefaultWS, JumpPower = DefaultJP,
    BhopEnabled = false, BhopSpeed = 5,

    -- Chams
    ChamsEnabled = false, ChamsColor = Color3.fromRGB(255, 0, 0), ChamsChroma = false, ChamsTeamColor = false,
    
    -- Tracers
    TracersEnabled = false, TracerOrigin = "Top", 
    TracersColor = Color3.fromRGB(255, 255, 255), TracersChroma = false, TracerTeamColor = false,
    
    -- Names
    NamesEnabled = false, UseDisplayNames = false, NamesColor = Color3.fromRGB(255, 255, 255), NamesChroma = false, NameTeamColor = false,
    
    -- Boxes
    BoxEnabled = false, BoxType = "2D Box", BoxThickness = 1, BoxColor = Color3.fromRGB(255, 255, 255), BoxChroma = false, BoxTeamColor = false,
    
    -- Skeleton
    SkelEnabled = false, SkelThickness = 1, SkelColor = Color3.fromRGB(255, 255, 255), SkelChroma = false, SkelTeamColor = false,

    -- [[ AIMBOT SETTINGS ]] --
    AimbotMaster = false,
    AimbotMode = "Hold",
    AimbotHolding = false, 
    AimbotMouseBind = "Right Click",
    AimbotTeamCheck = false,
    AimIgnorePrisoners = false, 
    AimIgnoreForcefield = false,
    AimbotSmoothness = 0, 
    AimbotLockPart = "Head",
    AimbotVisCheck = false,
    AimbotSnapBack = false,
    AimbotAutoShoot = false, 
    AimBlatantMode = false,
    AimbotAutoStop = false, 
    AimAutoShootMethod = "Hardware", 
    AimbotAutoShootCPS = 10,
    AimbotAutoShootDelay = 0,
    AimbotMaxDistance = 1000, 
    Aimbot360FOV = false, 
    AimbotDrawFOV = false,
    AimbotFOVRadius = 100,
    AimbotFOVColor = Color3.fromRGB(255, 255, 255),
    AimbotFOVChroma = false,
    AimbotPrediction = false,
    AimbotPredX = 0,
    AimbotPredY = 0,
    
    -- [[ AIMBOT HIT TRACES ]] --
    AimHitTraces = false, 
    AimTraceColor = Color3.fromRGB(255, 0, 0), 
    AimTraceChroma = false,

    -- [[ SPINBOT SETTINGS ]] --
    SpinbotEnabled = false,
    SpinbotPitch = "None",
    SpinbotYaw = "Clockwise",
    SpinbotSpeed = 10,

    -- [[ ENVIRONMENT SETTINGS ]] --
    EnvColorEnabled = false,
    EnvColor = Color3.fromRGB(255, 255, 255),
    EnvChroma = false,

    -- [[ CAMERA SETTINGS ]] --
    CameraFOVEnabled = false,
    CameraFOV = DefaultFOV,
    ThirdPerson = false,
    ThirdPersonDist = 15,

    -- [[ WATERMARK SETTINGS ]] --
    WatermarkEnabled = false,
    WatermarkCorner = "Top Left"
}

-- [[ UI ELEMENT MAPPING ARRAY ]] --
local UI = {}

-- [[ WINDOW CREATION ]] --
local Window = Rayfield:CreateWindow({
   Name = "Project iWare | #REBORN | by Ege",
   LoadingTitle = "Project iWare",
   LoadingSubtitle = "Absolute Optimized Build",
   Theme = "AmberGlow",
   ConfigurationSaving = { Enabled = false }, 
   KeySystem = false, 
})

-- [[ TABS ]] --
local PlayerTab = Window:CreateTab("Player", "user")
local VisualsTab = Window:CreateTab("Visuals", "eye")
local AimbotTab = Window:CreateTab("Aimbot", "crosshair") 
local MiscTab = Window:CreateTab("Miscellaneous", "component")
local SettingsTab = Window:CreateTab("Settings", "settings")


-- ==========================================
-- [[ PLAYER TAB UI ]]
-- ==========================================

local FlyActive = false
local NoclipActive = false
local WasNoclipping = false
local CurrentFlyGyro = nil
local CurrentFlyVelocity = nil

local PlayerGlobalSection = PlayerTab:CreateSection("Global Settings")
UI.PlayerMaster = PlayerTab:CreateToggle({Name = "Master Switch", CurrentValue = false, Flag = "PlayerMaster", Callback = function(v) Settings.PlayerMaster = v end})

local FlySection = PlayerTab:CreateSection("Flight")
UI.FlyEnabled = PlayerTab:CreateToggle({Name = "Enable Fly", CurrentValue = false, Flag = "FlyEnabled", Callback = function(v) Settings.FlyEnabled = v if not v then FlyActive = false end end})
UI.FlyMode = PlayerTab:CreateDropdown({Name = "Fly Mode", Options = {"Hold", "Toggle"}, CurrentOption = {"Hold"}, Flag = "FlyMode", Callback = function(v) Settings.FlyMode = v[1] end})
UI.FlyKey = PlayerTab:CreateKeybind({Name = "Fly Keybind", CurrentKeybind = "None", HoldToInteract = false, Flag = "FlyKey", Callback = function() if Settings.PlayerMaster and Settings.FlyEnabled and Settings.FlyMode == "Toggle" then FlyActive = not FlyActive end end})
PlayerTab:CreateButton({Name = "Delete Fly Keybind", Callback = function() UI.FlyKey:Set("None") Settings.FlyKey = "None" FlyActive = false end})
UI.FlySpeed = PlayerTab:CreateSlider({Name = "Fly Speed", Range = {10, 300}, Increment = 5, Suffix = " spd", CurrentValue = 150, Flag = "FlySpeed", Callback = function(v) Settings.FlySpeed = v end})

local NoclipSection = PlayerTab:CreateSection("Noclip")
UI.NoclipEnabled = PlayerTab:CreateToggle({Name = "Enable Noclip", CurrentValue = false, Flag = "NoclipEnabled", Callback = function(v) Settings.NoclipEnabled = v if not v then NoclipActive = false end end})
UI.NoclipMode = PlayerTab:CreateDropdown({Name = "Noclip Mode", Options = {"Hold", "Toggle", "Always On"}, CurrentOption = {"Hold"}, Flag = "NoclipMode", Callback = function(v) Settings.NoclipMode = v[1] end})
UI.NoclipKey = PlayerTab:CreateKeybind({Name = "Noclip Keybind", CurrentKeybind = "None", HoldToInteract = false, Flag = "NoclipKey", Callback = function() if Settings.PlayerMaster and Settings.NoclipEnabled and Settings.NoclipMode == "Toggle" then NoclipActive = not NoclipActive end end})
PlayerTab:CreateButton({Name = "Delete Noclip Keybind", Callback = function() UI.NoclipKey:Set("None") Settings.NoclipKey = "None" NoclipActive = false end})

local JumpSection = PlayerTab:CreateSection("Jumping")
UI.InfJumpEnabled = PlayerTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Flag = "InfJumpEnabled", Callback = function(v) Settings.InfJumpEnabled = v end})

local TPWallSection = PlayerTab:CreateSection("Teleportation")
UI.TPForwardEnabled = PlayerTab:CreateToggle({Name = "Enable Teleport Behind Walls", CurrentValue = false, Flag = "TPForwardEnabled", Callback = function(v) Settings.TPForwardEnabled = v end})
UI.TPForwardKey = PlayerTab:CreateKeybind({
    Name = "Teleport Forward Keybind", 
    CurrentKeybind = "None", 
    HoldToInteract = false, 
    Flag = "TPKey", 
    Callback = function() 
        if Settings.PlayerMaster and Settings.TPForwardEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -Settings.TPForwardStuds) end
        end
    end
})
PlayerTab:CreateButton({Name = "Delete Teleport Keybind", Callback = function() UI.TPForwardKey:Set("None") Settings.TPForwardKey = "None" end})
UI.TPForwardStuds = PlayerTab:CreateSlider({Name = "Teleport Distance", Range = {1, 100}, Increment = 1, Suffix = " studs", CurrentValue = 5, Flag = "TPStuds", Callback = function(v) Settings.TPForwardStuds = v end})

local StatsSection = PlayerTab:CreateSection("Value Multipliers")
UI.StatsEnabled = PlayerTab:CreateToggle({Name = "Enable Multipliers", CurrentValue = false, Flag = "StatsEnabled", Callback = function(v) 
    Settings.StatsEnabled = v 
    if not v then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = DefaultWS; hum.JumpPower = DefaultJP end
    end
end})
UI.WalkSpeed = PlayerTab:CreateSlider({Name = "Walk Speed", Range = {0, 500}, Increment = 1, Suffix = " ws", CurrentValue = DefaultWS, Flag = "WalkSpeed", Callback = function(v) Settings.WalkSpeed = v end})
UI.JumpPower = PlayerTab:CreateSlider({Name = "Jump Power", Range = {0, 500}, Increment = 1, Suffix = " jp", CurrentValue = DefaultJP, Flag = "JumpPower", Callback = function(v) Settings.JumpPower = v end})
PlayerTab:CreateButton({Name = "Reset Values", Callback = function() 
    Settings.WalkSpeed = DefaultWS
    Settings.JumpPower = DefaultJP
    UI.WalkSpeed:Set(DefaultWS)
    UI.JumpPower:Set(DefaultJP)
end})

local BhopSection = PlayerTab:CreateSection("Bunny Hop")
UI.BhopEnabled = PlayerTab:CreateToggle({Name = "Enable Bunny Hop", CurrentValue = false, Flag = "BhopEnabled", Callback = function(v) Settings.BhopEnabled = v end})
UI.BhopSpeed = PlayerTab:CreateSlider({Name = "Bunny Hop Speed", Range = {1, 50}, Increment = 1, Suffix = " pwr", CurrentValue = 5, Flag = "BhopSpeed", Callback = function(v) Settings.BhopSpeed = v end})


-- ==========================================
-- [[ VISUALS TAB UI ]]
-- ==========================================

local GlobalSection = VisualsTab:CreateSection("Global Settings")
UI.Master = VisualsTab:CreateToggle({Name = "Master Switch", CurrentValue = false, Flag = "MasterSwitch", Callback = function(v) Settings.Master = v end})
UI.TeamCheck = VisualsTab:CreateToggle({Name = "Team Check", CurrentValue = false, Flag = "TeamCheck", Callback = function(v) Settings.TeamCheck = v end})

if game.PlaceId == 606849621 then
    UI.IgnorePrisoners = VisualsTab:CreateToggle({Name = "Ignore Prisoners", CurrentValue = false, Flag = "IgnorePrisoners", Callback = function(v) Settings.IgnorePrisoners = v end}) 
end

UI.ESPOptimizer = VisualsTab:CreateSlider({Name = "ESP Optimizer", Range = {100, 10000}, Increment = 100, Suffix = " studs", CurrentValue = 1000, Flag = "ESPOptimizer", Callback = function(v) Settings.ESPOptimizer = v end}) 
UI.ESPVisCheck = VisualsTab:CreateToggle({Name = "Visibility Check", CurrentValue = false, Flag = "ESPVisCheck", Callback = function(v) Settings.ESPVisCheck = v end})

local ChamsSection = VisualsTab:CreateSection("Chams")
UI.ChamsEnabled = VisualsTab:CreateToggle({Name = "Enable Chams", CurrentValue = false, Flag = "ChamsToggle", Callback = function(v) Settings.ChamsEnabled = v end})
UI.ChamsColor = VisualsTab:CreateColorPicker({Name = "Chams Color", Color = Color3.fromRGB(255, 0, 0), Flag = "ChamsColor", Callback = function(v) Settings.ChamsColor = v end})
UI.ChamsChroma = VisualsTab:CreateToggle({Name = "Chroma", CurrentValue = false, Flag = "ChamsChroma", Callback = function(v) Settings.ChamsChroma = v end})
UI.ChamsTeamColor = VisualsTab:CreateToggle({Name = "Prefer Team Color", CurrentValue = false, Flag = "ChamsTeam", Callback = function(v) Settings.ChamsTeamColor = v end})

local TracerSection = VisualsTab:CreateSection("Tracers")
UI.TracersEnabled = VisualsTab:CreateToggle({Name = "Enable Tracers", CurrentValue = false, Flag = "TracerToggle", Callback = function(v) Settings.TracersEnabled = v end})
UI.TracerOrigin = VisualsTab:CreateDropdown({Name = "Tracer Origin", Options = {"Top", "Center", "Bottom"}, CurrentOption = {"Top"}, Flag = "TracerLoc", Callback = function(v) Settings.TracerOrigin = v[1] end})
UI.TracersColor = VisualsTab:CreateColorPicker({Name = "Tracer Color", Color = Color3.fromRGB(255, 255, 255), Flag = "TracerColor", Callback = function(v) Settings.TracersColor = v end})
UI.TracersChroma = VisualsTab:CreateToggle({Name = "Chroma", CurrentValue = false, Flag = "TracerChroma", Callback = function(v) Settings.TracersChroma = v end})
UI.TracerTeamColor = VisualsTab:CreateToggle({Name = "Prefer Team Color", CurrentValue = false, Flag = "TracerTeam", Callback = function(v) Settings.TracerTeamColor = v end})

local SkelSection = VisualsTab:CreateSection("Skeleton")
UI.SkelEnabled = VisualsTab:CreateToggle({Name = "Enable Skeleton", CurrentValue = false, Flag = "SkelToggle", Callback = function(v) Settings.SkelEnabled = v end})
UI.SkelThickness = VisualsTab:CreateSlider({Name = "Skeleton Thickness", Range = {1, 5}, Increment = 1, Suffix = "px", CurrentValue = 1, Flag = "SkelThick", Callback = function(v) Settings.SkelThickness = v end})
UI.SkelColor = VisualsTab:CreateColorPicker({Name = "Skeleton Color", Color = Color3.fromRGB(255, 255, 255), Flag = "SkelColor", Callback = function(v) Settings.SkelColor = v end})
UI.SkelChroma = VisualsTab:CreateToggle({Name = "Chroma", CurrentValue = false, Flag = "SkelChroma", Callback = function(v) Settings.SkelChroma = v end})
UI.SkelTeamColor = VisualsTab:CreateToggle({Name = "Prefer Team Color", CurrentValue = false, Flag = "SkelTeam", Callback = function(v) Settings.SkelTeamColor = v end})

local NameSection = VisualsTab:CreateSection("Names")
UI.NamesEnabled = VisualsTab:CreateToggle({Name = "Enable Names", CurrentValue = false, Flag = "NameToggle", Callback = function(v) Settings.NamesEnabled = v end})
UI.UseDisplayNames = VisualsTab:CreateToggle({Name = "Prefer Display Names", CurrentValue = false, Flag = "DispNameToggle", Callback = function(v) Settings.UseDisplayNames = v end})
UI.NamesColor = VisualsTab:CreateColorPicker({Name = "Name Color", Color = Color3.fromRGB(255, 255, 255), Flag = "NameColor", Callback = function(v) Settings.NamesColor = v end})
UI.NamesChroma = VisualsTab:CreateToggle({Name = "Chroma", CurrentValue = false, Flag = "NameChroma", Callback = function(v) Settings.NamesChroma = v end})
UI.NameTeamColor = VisualsTab:CreateToggle({Name = "Prefer Team Color", CurrentValue = false, Flag = "NameTeam", Callback = function(v) Settings.NameTeamColor = v end})

local BoxSection = VisualsTab:CreateSection("Boxes")
UI.BoxEnabled = VisualsTab:CreateToggle({Name = "Enable Boxes", CurrentValue = false, Flag = "BoxToggle", Callback = function(v) Settings.BoxEnabled = v end})
UI.BoxType = VisualsTab:CreateDropdown({Name = "Box Type", Options = {"2D Box", "3D Box"}, CurrentOption = {"2D Box"}, Flag = "BoxType", Callback = function(v) Settings.BoxType = v[1] end})
UI.BoxThickness = VisualsTab:CreateSlider({Name = "Box Thickness", Range = {1, 3}, Increment = 1, Suffix = "px", CurrentValue = 1, Flag = "BoxThick", Callback = function(v) Settings.BoxThickness = v end})
UI.BoxColor = VisualsTab:CreateColorPicker({Name = "Box Color", Color = Color3.fromRGB(255, 255, 255), Flag = "BoxColor", Callback = function(v) Settings.BoxColor = v end})
UI.BoxChroma = VisualsTab:CreateToggle({Name = "Chroma", CurrentValue = false, Flag = "BoxChroma", Callback = function(v) Settings.BoxChroma = v end})
UI.BoxTeamColor = VisualsTab:CreateToggle({Name = "Prefer Team Color", CurrentValue = false, Flag = "BoxTeam", Callback = function(v) Settings.BoxTeamColor = v end})

local TPSection = VisualsTab:CreateSection("Third Person")
UI.ThirdPerson = VisualsTab:CreateToggle({
    Name = "Third Person", 
    CurrentValue = false, 
    Flag = "CamThirdPerson", 
    Callback = function(v) 
        if v and not TPActive then
            OriginalCamMode = LocalPlayer.CameraMode
            OriginalMinZoom = LocalPlayer.CameraMinZoomDistance
            OriginalMaxZoom = LocalPlayer.CameraMaxZoomDistance
        end
        Settings.ThirdPerson = v 
    end
})
UI.ThirdPersonDist = VisualsTab:CreateSlider({
    Name = "Third Person Distance", 
    Range = {5, 100}, 
    Increment = 1, 
    Suffix = " studs", 
    CurrentValue = 15,
    Flag = "CamTPDist", 
    Callback = function(v) Settings.ThirdPersonDist = v end
})


-- ==========================================
-- [[ AIMBOT TAB UI ]]
-- ==========================================

local AimMasterSection = AimbotTab:CreateSection("Aimbot Master")
UI.AimbotMaster = AimbotTab:CreateToggle({Name = "Enable Aimbot", CurrentValue = false, Flag = "AimMaster", Callback = function(v) Settings.AimbotMaster = v end})

UI.AimbotMode = AimbotTab:CreateDropdown({
    Name = "Aimbot Mode",
    Options = {"Hold", "Toggle", "Always On"},
    CurrentOption = {"Hold"},
    Flag = "AimMode",
    Callback = function(v) Settings.AimbotMode = v[1] end
})

UI.AimbotMouseBind = AimbotTab:CreateDropdown({
    Name = "Mouse Bind",
    Options = {"None", "Left Click", "Right Click", "Middle Click"},
    CurrentOption = {"Right Click"},
    Flag = "AimMouseBind",
    Callback = function(v) Settings.AimbotMouseBind = v[1] end
})

UI.AimbotKey = AimbotTab:CreateKeybind({
   Name = "Keyboard Bind",
   CurrentKeybind = "None", 
   HoldToInteract = true,
   Flag = "AimKeybind1", 
   Callback = function(Keybind) Settings.AimbotHolding = Keybind end,
})

local AimTargetingSection = AimbotTab:CreateSection("Targeting & Checks")
UI.AimbotLockPart = AimbotTab:CreateDropdown({Name = "Lock Part", Options = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}, CurrentOption = {"Head"}, Flag = "AimPart", Callback = function(v) Settings.AimbotLockPart = v[1] end})
UI.AimbotSmoothness = AimbotTab:CreateSlider({Name = "Smoothing", Range = {0, 20}, Increment = 1, Suffix = "x", CurrentValue = 0, Flag = "AimSmooth", Callback = function(v) Settings.AimbotSmoothness = v end})
UI.AimbotMaxDistance = AimbotTab:CreateSlider({Name = "Lock Range", Range = {100, 10000}, Increment = 100, Suffix = " studs", CurrentValue = 1000, Flag = "AimMaxDist", Callback = function(v) Settings.AimbotMaxDistance = v end}) 
UI.AimbotVisCheck = AimbotTab:CreateToggle({Name = "Visibility Check", CurrentValue = false, Flag = "AimVisCheck", Callback = function(v) Settings.AimbotVisCheck = v end}) 
UI.AimbotSnapBack = AimbotTab:CreateToggle({Name = "Snap Back Camera", CurrentValue = false, Flag = "AimSnapBack", Callback = function(v) Settings.AimbotSnapBack = v end})
UI.AimbotTeamCheck = AimbotTab:CreateToggle({Name = "Team Check", CurrentValue = false, Flag = "AimTeam", Callback = function(v) Settings.AimbotTeamCheck = v end})

UI.AimIgnoreForcefield = AimbotTab:CreateToggle({Name = "Ignore Forcefields", CurrentValue = false, Flag = "AimIgnoreFF", Callback = function(v) Settings.AimIgnoreForcefield = v end})

if game.PlaceId == 606849621 then
    UI.AimIgnorePrisoners = AimbotTab:CreateToggle({Name = "Ignore Prisoners", CurrentValue = false, Flag = "AimIgnorePrisoner", Callback = function(v) Settings.AimIgnorePrisoners = v end})
end

local AimAutomationSection = AimbotTab:CreateSection("Automation")
UI.AimbotAutoShoot = AimbotTab:CreateToggle({Name = "Auto Shoot", CurrentValue = false, Flag = "AimAutoShoot", Callback = function(v) Settings.AimbotAutoShoot = v end}) 
UI.AimBlatantMode = AimbotTab:CreateToggle({Name = "Blatant Auto Shoot", CurrentValue = false, Flag = "AimBlatant", Callback = function(v) Settings.AimBlatantMode = v end})
UI.AimbotAutoStop = AimbotTab:CreateToggle({Name = "Auto Stop", CurrentValue = false, Flag = "AimAutoStop", Callback = function(v) Settings.AimbotAutoStop = v end})
UI.AimAutoShootMethod = AimbotTab:CreateDropdown({
    Name = "Auto Shoot Method",
    Options = {"VIM", "Hardware", "Hybrid"},
    CurrentOption = {"Hardware"},
    Flag = "AimAutoShootMethod",
    Callback = function(v) Settings.AimAutoShootMethod = v[1] end
})
UI.AimAutoShootCPS = AimbotTab:CreateSlider({
    Name = "Auto Shoot CPS", 
    Range = {1, 30}, 
    Increment = 1, 
    Suffix = " clicks/s", 
    CurrentValue = 10, 
    Flag = "AimAutoShootCPS", 
    Callback = function(v) Settings.AimbotAutoShootCPS = v end
}) 
UI.AimbotAutoShootDelay = AimbotTab:CreateSlider({
    Name = "Auto Shoot Delay", 
    Range = {0, 500}, 
    Increment = 10, 
    Suffix = " ms", 
    CurrentValue = 0, 
    Flag = "AimAutoShootDelay", 
    Callback = function(v) Settings.AimbotAutoShootDelay = v end
})

local HitTraceSection = AimbotTab:CreateSection("Hit Traces")
UI.AimHitTraces = AimbotTab:CreateToggle({Name = "Enable Hit Traces", CurrentValue = false, Flag = "AimHitTraces", Callback = function(v) Settings.AimHitTraces = v end})
UI.AimTraceColor = AimbotTab:CreateColorPicker({Name = "Hit Trace Color", Color = Color3.fromRGB(255, 0, 0), Flag = "AimTraceColor", Callback = function(v) Settings.AimTraceColor = v end})
UI.AimTraceChroma = AimbotTab:CreateToggle({Name = "Hit Trace Chroma", CurrentValue = false, Flag = "AimTraceChroma", Callback = function(v) Settings.AimTraceChroma = v end})

local FOVSection = AimbotTab:CreateSection("FOV Ring")
UI.Aimbot360FOV = AimbotTab:CreateToggle({Name = "360° FOV", CurrentValue = false, Flag = "Aim360FOV", Callback = function(v) Settings.Aimbot360FOV = v end})
UI.AimbotDrawFOV = AimbotTab:CreateToggle({Name = "Draw FOV", CurrentValue = false, Flag = "AimDrawFOV", Callback = function(v) Settings.AimbotDrawFOV = v end})
UI.AimbotFOVRadius = AimbotTab:CreateSlider({Name = "FOV Radius", Range = {10, 800}, Increment = 10, Suffix = "px", CurrentValue = 100, Flag = "AimFOVRad", Callback = function(v) Settings.AimbotFOVRadius = v end})
UI.AimbotFOVColor = AimbotTab:CreateColorPicker({Name = "FOV Color", Color = Color3.fromRGB(255, 255, 255), Flag = "AimFOVCol", Callback = function(v) Settings.AimbotFOVColor = v end})
UI.AimbotFOVChroma = AimbotTab:CreateToggle({Name = "Chroma FOV", CurrentValue = false, Flag = "AimFOVChroma", Callback = function(v) Settings.AimbotFOVChroma = v end})

local PredSection = AimbotTab:CreateSection("Prediction")
UI.AimbotPrediction = AimbotTab:CreateToggle({Name = "Enable Prediction", CurrentValue = false, Flag = "AimPredToggle", Callback = function(v) Settings.AimbotPrediction = v end})
UI.AimbotPredX = AimbotTab:CreateSlider({Name = "Prediction X", Range = {0, 10}, Increment = 1, Suffix = " offset", CurrentValue = 0, Flag = "AimPredX", Callback = function(v) Settings.AimbotPredX = v end})
UI.AimbotPredY = AimbotTab:CreateSlider({Name = "Prediction Y", Range = {0, 10}, Increment = 1, Suffix = " offset", CurrentValue = 0, Flag = "AimPredY", Callback = function(v) Settings.AimbotPredY = v end})


-- ==========================================
-- [[ MISCELLANEOUS TAB UI ]]
-- ==========================================

local SpinbotSection = MiscTab:CreateSection("Spinbot")
UI.SpinbotEnabled = MiscTab:CreateToggle({
    Name = "Enable Spinbot", 
    CurrentValue = false, 
    Flag = "SpinMaster", 
    Callback = function(v) Settings.SpinbotEnabled = v end
})
UI.SpinbotPitch = MiscTab:CreateDropdown({
    Name = "Face Direction (Pitch)",
    Options = {"None", "Sky", "Ground"},
    CurrentOption = {"None"},
    Flag = "SpinPitch",
    Callback = function(v) Settings.SpinbotPitch = v[1] end
})
UI.SpinbotYaw = MiscTab:CreateDropdown({
    Name = "Spin Direction (Yaw)",
    Options = {"Clockwise", "Counter-Clockwise", "Jitter"},
    CurrentOption = {"Clockwise"},
    Flag = "SpinYaw",
    Callback = function(v) Settings.SpinbotYaw = v[1] end
})
UI.SpinbotSpeed = MiscTab:CreateSlider({
    Name = "Spin Speed", 
    Range = {1, 100}, 
    Increment = 1, 
    Suffix = " °/f", 
    CurrentValue = 10, 
    Flag = "SpinSpeed", 
    Callback = function(v) Settings.SpinbotSpeed = v end
})

local EnvSection = MiscTab:CreateSection("Environment")
UI.EnvColorEnabled = MiscTab:CreateToggle({
    Name = "Enable Custom Environment Color", 
    CurrentValue = false, 
    Flag = "EnvColorToggle", 
    Callback = function(v) Settings.EnvColorEnabled = v end
})
UI.EnvColor = MiscTab:CreateColorPicker({
    Name = "Environment Color", 
    Color = Color3.fromRGB(255, 255, 255), 
    Flag = "EnvColor", 
    Callback = function(v) Settings.EnvColor = v end
})
UI.EnvChroma = MiscTab:CreateToggle({
    Name = "Chroma", 
    CurrentValue = false, 
    Flag = "EnvChroma", 
    Callback = function(v) Settings.EnvChroma = v end
})

-- ==========================================
-- [[ SETTINGS & CONFIG TAB UI ]]
-- ==========================================

local CameraSection = SettingsTab:CreateSection("Camera")
UI.CameraFOVEnabled = SettingsTab:CreateToggle({
    Name = "Enable FOV Changer", 
    CurrentValue = false, 
    Flag = "CamFOVEnable", 
    Callback = function(v) 
        Settings.CameraFOVEnabled = v 
        if not v then Camera.FieldOfView = DefaultFOV end
    end
})
UI.CameraFOV = SettingsTab:CreateSlider({
    Name = "Field of View", 
    Range = {10, 120}, 
    Increment = 1, 
    Suffix = "°", 
    CurrentValue = DefaultFOV,
    Flag = "CamFOV", 
    Callback = function(v) Settings.CameraFOV = v end
})

local WatermarkSection = SettingsTab:CreateSection("Watermark")
UI.WatermarkEnabled = SettingsTab:CreateToggle({
    Name = "Enable Watermark",
    CurrentValue = false,
    Flag = "WatermarkEnable",
    Callback = function(v) Settings.WatermarkEnabled = v end
})
UI.WatermarkCorner = SettingsTab:CreateDropdown({
    Name = "Position Corner",
    Options = {"Top Left", "Top Right", "Bottom Left", "Bottom Right"},
    CurrentOption = {"Top Left"},
    Flag = "WatermarkLoc",
    Callback = function(v) Settings.WatermarkCorner = v[1] end
})

local ConfigFolder = "Project_iWare_Configs"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local function GetConfigs()
    local configs = {""}
    if isfolder(ConfigFolder) then
        for _, file in pairs(listfiles(ConfigFolder)) do
            if file:match("%.json$") then table.insert(configs, file:match("([^/\\]+)%.json$")) end
        end
    end
    return #configs > 1 and configs or {"", "No Configs Found"}
end

local ConfigSection = SettingsTab:CreateSection("Configuration Manager")
local CurrentConfigName = ""
local ConfigDropdown 

SettingsTab:CreateInput({
    Name = "Config Name",
    CurrentValue = "",
    PlaceholderText = "Enter config name...",
    RemoveTextAfterFocusLost = false,
    Flag = "ConfigNameInput",
    Callback = function(Text) CurrentConfigName = Text end,
})

ConfigDropdown = SettingsTab:CreateDropdown({
    Name = "Available Configs", Options = GetConfigs(), CurrentOption = {""}, Flag = "ConfigDropdownList",
    Callback = function(v) CurrentConfigName = v[1] end,
})

SettingsTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        if CurrentConfigName ~= "" and CurrentConfigName ~= "No Configs Found" then
            local saveTable = {}
            for k, v in pairs(Settings) do
                if typeof(v) == "Color3" then saveTable[k] = {Type = "Color3", R = v.R, G = v.G, B = v.B} else saveTable[k] = v end
            end
            writefile(ConfigFolder .. "/" .. CurrentConfigName .. ".json", HttpService:JSONEncode(saveTable))
            ConfigDropdown:Refresh(GetConfigs())
            Rayfield:Notify({Title = "Vault", Content = "Config Saved: " .. CurrentConfigName, Duration = 3})
        else Rayfield:Notify({Title = "Vault Error", Content = "Please enter a valid config name.", Duration = 3}) end
    end,
})

SettingsTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        if CurrentConfigName ~= "" and CurrentConfigName ~= "No Configs Found" then
            local path = ConfigFolder .. "/" .. CurrentConfigName .. ".json"
            if isfile(path) then
                local decoded = HttpService:JSONDecode(readfile(path))
                
                for k, v in pairs(decoded) do
                    if type(v) == "table" and v.Type == "Color3" then 
                        Settings[k] = Color3.new(v.R, v.G, v.B) 
                    else 
                        Settings[k] = v 
                    end
                    
                    if UI[k] then
                        if k == "TracerOrigin" or k == "BoxType" or k == "AimbotLockPart" or k == "AimbotMouseBind" or k == "AimAutoShootMethod" or k == "AimbotMode" or k == "SpinbotPitch" or k == "SpinbotYaw" or k == "FlyMode" or k == "NoclipMode" or k == "WatermarkCorner" then
                            UI[k]:Set({Settings[k]})
                        elseif k == "AimBlatantMode" then
                            UI.AimBlatantMode:Set(Settings[k])
                        else
                            UI[k]:Set(Settings[k])
                        end
                    end
                end
                Rayfield:Notify({Title = "Vault", Content = "Config Loaded: " .. CurrentConfigName, Duration = 3})
            else Rayfield:Notify({Title = "Vault Error", Content = "Config file not found.", Duration = 3}) end
        end
    end,
})

SettingsTab:CreateButton({
    Name = "Delete Config",
    Callback = function()
        if CurrentConfigName ~= "" and CurrentConfigName ~= "No Configs Found" then
            local path = ConfigFolder .. "/" .. CurrentConfigName .. ".json"
            if isfile(path) then
                delfile(path) ConfigDropdown:Refresh(GetConfigs())
                Rayfield:Notify({Title = "Vault", Content = "Config Deleted: " .. CurrentConfigName, Duration = 3})
            end
        end
    end,
})

SettingsTab:CreateButton({Name = "Refresh Configs", Callback = function() ConfigDropdown:Refresh(GetConfigs()) end})


-- ==========================================
-- [[ CORE LOGIC HANDLERS ]]
-- ==========================================

local ESP_Cache = {} 
local FOV_Circle = Drawing.new("Circle") 

-- [[ WATERMARK OBJECTS ]] --
local Watermark_Main = Drawing.new("Square")
Watermark_Main.Thickness = 1
Watermark_Main.Filled = true
Watermark_Main.Color = Color3.fromRGB(20, 20, 20)
Watermark_Main.Transparency = 0.8

local Watermark_Border = Drawing.new("Square")
Watermark_Border.Thickness = 1
Watermark_Border.Filled = false
Watermark_Border.Color = Color3.fromRGB(255, 165, 0) -- Amber Glow
Watermark_Border.Transparency = 1

local Watermark_Text = Drawing.new("Text")
Watermark_Text.Size = 14
Watermark_Text.Outline = false
Watermark_Text.Center = false
Watermark_Text.Color = Color3.new(1, 1, 1)
Watermark_Text.Font = 2

local CurrentLockedTarget = nil 
local LastTraceTime = 0 
local LastShootTime = 0 
local WasAutoStopped = false
local StoredWalkSpeed = 16

local WasLocked = false
local SnapBackCFrame = nil
local IsWaitingToShoot = false

local PreviousTriggerState = false
local AimbotToggled = false
local SpinbotAngle = 0

local FPSTick = tick()
local FPSFrameCount = 0
local CurrentFPS = 60

local ControlKeys = {W = false, A = false, S = false, D = false, Space = false, LShift = false}

-- [[ ULTRA-OPTIMIZATION HANDLERS ]] --
local LastRaycastTime = {}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then ControlKeys.W = true end
    if input.KeyCode == Enum.KeyCode.A then ControlKeys.A = true end
    if input.KeyCode == Enum.KeyCode.S then ControlKeys.S = true end
    if input.KeyCode == Enum.KeyCode.D then ControlKeys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then ControlKeys.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then ControlKeys.LShift = true end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then ControlKeys.W = false end
    if input.KeyCode == Enum.KeyCode.A then ControlKeys.A = false end
    if input.KeyCode == Enum.KeyCode.S then ControlKeys.S = false end
    if input.KeyCode == Enum.KeyCode.D then ControlKeys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then ControlKeys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then ControlKeys.LShift = false end
end)

UserInputService.JumpRequest:Connect(function()
    if Settings.PlayerMaster and Settings.InfJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local function createDrawing(type, properties)
    local drawing = Drawing.new(type)
    for k, v in pairs(properties) do drawing[k] = v end
    return drawing
end

local function removeESP(player)
    if ESP_Cache[player] then
        if ESP_Cache[player].Box2D then ESP_Cache[player].Box2D:Remove() end
        if ESP_Cache[player].Box3D then for _, l in pairs(ESP_Cache[player].Box3D) do l:Remove() end end
        if ESP_Cache[player].Skeleton then for _, l in pairs(ESP_Cache[player].Skeleton) do l:Remove() end end
        if ESP_Cache[player].HeadCircle then ESP_Cache[player].HeadCircle:Remove() end
        if ESP_Cache[player].Tracer then ESP_Cache[player].Tracer:Remove() end
        if ESP_Cache[player].Name then ESP_Cache[player].Name:Remove() end
        if ESP_Cache[player].Highlight then ESP_Cache[player].Highlight:Destroy() end
        ESP_Cache[player] = nil
        LastRaycastTime[player] = nil
    end
end

local function hideESP(player)
    local Cache = ESP_Cache[player]
    if Cache then
        if Cache.Box2D then Cache.Box2D.Visible = false end
        if Cache.Box3D then for _, l in pairs(Cache.Box3D) do l.Visible = false end end
        if Cache.Skeleton then for _, l in pairs(Cache.Skeleton) do l.Visible = false end end
        if Cache.HeadCircle then Cache.HeadCircle.Visible = false end
        if Cache.Tracer then Cache.Tracer.Visible = false end
        if Cache.Name then Cache.Name.Visible = false end
        if Cache.Highlight then Cache.Highlight.Enabled = false end
    end
end

local function getRainbowColor()
    return Color3.fromHSV(tick() % 5 / 5, 1, 1) 
end

local function resolveColor(baseColor, chroma, useTeam, player)
    if useTeam and player and player.TeamColor then return player.TeamColor.Color
    elseif chroma then return getRainbowColor() end
    return baseColor
end

-- ==========================================
-- [[ ENVIRONMENT ENGINE ]]
-- ==========================================

local function handleEnvironment()
    if Settings.EnvColorEnabled then
        if not EnvActive then
            OriginalAmbient = Lighting.Ambient
            OriginalOutdoorAmbient = Lighting.OutdoorAmbient
            EnvActive = true
        end
        local envColor = resolveColor(Settings.EnvColor, Settings.EnvChroma, false, nil)
        Lighting.Ambient = envColor
        Lighting.OutdoorAmbient = envColor
    else
        if EnvActive then
            Lighting.Ambient = OriginalAmbient
            Lighting.OutdoorAmbient = OriginalOutdoorAmbient
            EnvActive = false
        end
    end
end

-- ==========================================
-- [[ PLAYER ENGINE ]]
-- ==========================================

local function handlePlayer()
    if not Settings.PlayerMaster then
        if CurrentFlyGyro then CurrentFlyGyro:Destroy(); CurrentFlyGyro = nil end
        if CurrentFlyVelocity then CurrentFlyVelocity:Destroy(); CurrentFlyVelocity = nil end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum and hum.PlatformStand then hum.PlatformStand = false end
        
        if WasNoclipping then
            WasNoclipping = false
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CanCollide = true end
                local head = char:FindFirstChild("Head")
                if head then head.CanCollide = true end
                local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                if torso then torso.CanCollide = true end
                local lowerTorso = char:FindFirstChild("LowerTorso")
                if lowerTorso then lowerTorso.CanCollide = true end
            end
        end
        return 
    end
    
    if Settings.FlyEnabled then
        if Settings.FlyMode == "Hold" then
            local flyKeyStr = UI.FlyKey and UI.FlyKey.CurrentKeybind or "None"
            local flyKeyCode = getKeyCodeFromString(flyKeyStr)
            FlyActive = flyKeyCode and UserInputService:IsKeyDown(flyKeyCode) or false
        end
    else
        FlyActive = false
    end
    
    if Settings.NoclipEnabled then
        if Settings.NoclipMode == "Always On" then
            NoclipActive = true
        elseif Settings.NoclipMode == "Hold" then
            local noclipKeyStr = UI.NoclipKey and UI.NoclipKey.CurrentKeybind or "None"
            local noclipKeyCode = getKeyCodeFromString(noclipKeyStr)
            NoclipActive = noclipKeyCode and UserInputService:IsKeyDown(noclipKeyCode) or false
        end
    else
        NoclipActive = false
    end

    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    local hum = char:FindFirstChild("Humanoid")

    if FlyActive and hrp and hum then
        if not CurrentFlyGyro or not CurrentFlyGyro.Parent then
            CurrentFlyGyro = Instance.new("BodyGyro")
            CurrentFlyGyro.P = 9e4
            CurrentFlyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            CurrentFlyGyro.cframe = hrp.CFrame
            CurrentFlyGyro.Parent = hrp
        end
        if not CurrentFlyVelocity or not CurrentFlyVelocity.Parent then
            CurrentFlyVelocity = Instance.new("BodyVelocity")
            CurrentFlyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
            CurrentFlyVelocity.velocity = Vector3.new(0, 0, 0)
            CurrentFlyVelocity.Parent = hrp
        end
        
        hum.PlatformStand = true

        local camCFrame = Camera.CFrame
        local moveDir = Vector3.new()
        if ControlKeys.W then moveDir = moveDir + camCFrame.LookVector end
        if ControlKeys.S then moveDir = moveDir - camCFrame.LookVector end
        if ControlKeys.A then moveDir = moveDir - camCFrame.RightVector end
        if ControlKeys.D then moveDir = moveDir + camCFrame.RightVector end
        if ControlKeys.Space then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if ControlKeys.LShift then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        CurrentFlyVelocity.velocity = moveDir * Settings.FlySpeed
        CurrentFlyGyro.cframe = camCFrame
    else
        if CurrentFlyGyro then CurrentFlyGyro:Destroy(); CurrentFlyGyro = nil end
        if CurrentFlyVelocity then CurrentFlyVelocity:Destroy(); CurrentFlyVelocity = nil end
        if hum and hum.PlatformStand then hum.PlatformStand = false end
    end

    if NoclipActive then
        WasNoclipping = true
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    else
        if WasNoclipping then
            WasNoclipping = false
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if rootPart then rootPart.CanCollide = true end
            local head = char:FindFirstChild("Head")
            if head then head.CanCollide = true end
            local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            if torso then torso.CanCollide = true end
            local lowerTorso = char:FindFirstChild("LowerTorso")
            if lowerTorso then lowerTorso.CanCollide = true end
        end
    end

    if Settings.StatsEnabled and hum then
        hum.WalkSpeed = Settings.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = Settings.JumpPower
    end

    if Settings.BhopEnabled and hum and hrp and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        if hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (Settings.BhopSpeed / 10))
        end
    end
end

-- ==========================================
-- [[ SPINBOT ENGINE ]]
-- ==========================================

local function handleSpinbot()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    if not OriginalC0s[char] then
        OriginalC0s[char] = {}
        local waist = char:FindFirstChild("UpperTorso") and char.UpperTorso:FindFirstChild("Waist")
        if waist then OriginalC0s[char][waist] = waist.C0 end
        local rootJoint = hrp:FindFirstChild("RootJoint")
        if rootJoint then OriginalC0s[char][rootJoint] = rootJoint.C0 end
    end

    if Settings.SpinbotEnabled then
        hum.AutoRotate = false

        local speed = Settings.SpinbotSpeed
        local yaw = Settings.SpinbotYaw
        local pitch = Settings.SpinbotPitch

        if yaw == "Clockwise" then
            SpinbotAngle = (SpinbotAngle - speed) % 360
        elseif yaw == "Counter-Clockwise" then
            SpinbotAngle = (SpinbotAngle + speed) % 360
        elseif yaw == "Jitter" then
            SpinbotAngle = (SpinbotAngle + math.random(135, 225)) % 360
        end

        local pitchAngle = 0
        if pitch == "Ground" then
            pitchAngle = math.rad(-75)
        elseif pitch == "Sky" then
            pitchAngle = math.rad(75)
        end

        if yaw ~= "None" then
            local oldVel = hrp.Velocity
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(SpinbotAngle), 0)
            hrp.Velocity = oldVel
        end

        local R15 = hum.RigType == Enum.HumanoidRigType.R15
        local waist = char:FindFirstChild("UpperTorso") and char.UpperTorso:FindFirstChild("Waist")
        local rootJoint = hrp:FindFirstChild("RootJoint")

        if R15 and waist and OriginalC0s[char][waist] then
            waist.C0 = OriginalC0s[char][waist] * CFrame.Angles(pitchAngle, 0, 0)
        elseif not R15 and rootJoint and OriginalC0s[char][rootJoint] then
            rootJoint.C0 = OriginalC0s[char][rootJoint] * CFrame.Angles(-pitchAngle, 0, 0)
        end
    else
        hum.AutoRotate = true
        if OriginalC0s[char] then
            for motor, originalC0 in pairs(OriginalC0s[char]) do
                if motor and motor.Parent then motor.C0 = originalC0 end
            end
        end
    end
end

-- ==========================================
-- [[ AIMBOT ENGINE ]]
-- ==========================================

local function getLocalOrigin()
    if LocalPlayer.Character then
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head then return head.Position end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.Position end
    end
    return Camera.CFrame.Position
end

local function getTargetPart(character)
    local part = Settings.AimbotLockPart
    if part == "Head" then return character:FindFirstChild("Head") end
    if part == "Torso" then return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") end
    if part == "Left Arm" then return character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm") end
    if part == "Right Arm" then return character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm") end
    if part == "Left Leg" then return character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg") end
    if part == "Right Leg" then return character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg") end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getVisiblePoint(targetPart, targetCharacter)
    local origin = getLocalOrigin()
    local sizeX, sizeY, sizeZ = targetPart.Size.X / 2, targetPart.Size.Y / 2, targetPart.Size.Z / 2
    
    for i = 1, #VisibilityOffsets do
        local offset = VisibilityOffsets[i]
        local checkPos = targetPart.CFrame * Vector3.new(offset.X * sizeX, offset.Y * sizeY, offset.Z * sizeZ)
        local direction = checkPos - origin
        local result = workspace:Raycast(origin, direction, GlobalRayParams)
        
        if not result or result.Instance:IsDescendantOf(targetCharacter) then
            return checkPos
        end
    end
    return nil
end

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = Settings.AimbotFOVRadius
    local shortestPhysical = Settings.AimbotMaxDistance

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Settings.AimbotTeamCheck and player.Team == LocalPlayer.Team then continue end
            if Settings.AimIgnorePrisoners and player.Team and player.Team.Name == "Prisoner" then continue end
            if Settings.AimIgnoreForcefield and player.Character:FindFirstChildOfClass("ForceField") then continue end
            
            local targetPart = getTargetPart(player.Character)
            if not targetPart then continue end
            
            local originPos = getLocalOrigin()
            local physicalDistance = (originPos - targetPart.Position).Magnitude
            if physicalDistance > Settings.AimbotMaxDistance then continue end
            
            local visPoint = getVisiblePoint(targetPart, player.Character)
            if Settings.AimbotVisCheck and not visPoint then continue end
            local pointToUse = visPoint or targetPart.Position

            if Settings.Aimbot360FOV then
                if physicalDistance < shortestPhysical then
                    local hum = player.Character:FindFirstChild("Humanoid")
                    if not hum or hum.Health > 0 then
                        closestPlayer = player
                        shortestPhysical = physicalDistance
                    end
                end
            else
                local pos, onScreen = Camera:WorldToViewportPoint(pointToUse)
                if onScreen then
                    local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if distance < shortestDistance then
                        local hum = player.Character:FindFirstChild("Humanoid")
                        if not hum or hum.Health > 0 then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function drawHitTrace(origin, targetPos)
    local distance = (origin - targetPos).Magnitude
    local trace = Instance.new("Part")
    trace.Name = "AimbotHitTrace"
    trace.Anchored = true
    trace.CanCollide = false
    trace.CanTouch = false
    trace.CanQuery = false
    trace.Size = Vector3.new(0.05, 0.05, distance)
    trace.CFrame = CFrame.lookAt(origin, targetPos) * CFrame.new(0, 0, -distance / 2)
    trace.Color = resolveColor(Settings.AimTraceColor, Settings.AimTraceChroma, false, nil)
    trace.Material = Enum.Material.Neon
    trace.Transparency = 0
    trace.Parent = workspace

    local tween = TweenService:Create(trace, TweenInfo.new(0.7, Enum.EasingStyle.Linear), {Transparency = 1})
    tween:Play()
    tween.Completed:Connect(function() trace:Destroy() end)
end

local function executeShoot()
    if Settings.AimAutoShootMethod == "VIM" or Settings.AimAutoShootMethod == "Hybrid" then
        VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 1)
    end
    if Settings.AimAutoShootMethod == "Hardware" or Settings.AimAutoShootMethod == "Hybrid" then
        if mouse1press then pcall(mouse1press) end
        if mouse1release then pcall(mouse1release) end
        if mouse1click then pcall(mouse1click) end
    end
end

local function handleAimbot()
    FOV_Circle.Visible = Settings.AimbotMaster and Settings.AimbotDrawFOV and not Settings.Aimbot360FOV
    
    if FOV_Circle.Visible then
        FOV_Circle.Radius = Settings.AimbotFOVRadius
        FOV_Circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOV_Circle.Color = resolveColor(Settings.AimbotFOVColor, Settings.AimbotFOVChroma, false, nil)
        FOV_Circle.Thickness = 1
    end

    local currentRawTrigger = false
    if Settings.AimbotMouseBind == "Left Click" then
        currentRawTrigger = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif Settings.AimbotMouseBind == "Right Click" then
        currentRawTrigger = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif Settings.AimbotMouseBind == "Middle Click" then
        currentRawTrigger = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
    else
        currentRawTrigger = Settings.AimbotHolding 
    end

    local isTriggered = false
    if Settings.AimbotMode == "Always On" then
        isTriggered = true
    elseif Settings.AimbotMode == "Toggle" then
        if currentRawTrigger and not PreviousTriggerState then
            AimbotToggled = not AimbotToggled
        end
        PreviousTriggerState = currentRawTrigger
        isTriggered = AimbotToggled
    else
        isTriggered = currentRawTrigger
    end

    if Settings.AimbotMaster and isTriggered then
        
        local targetIsValid = false
        if CurrentLockedTarget and CurrentLockedTarget.Character then
            local hasFF = Settings.AimIgnoreForcefield and CurrentLockedTarget.Character:FindFirstChildOfClass("ForceField")
            if not hasFF then
                local tPart = getTargetPart(CurrentLockedTarget.Character)
                if tPart then
                    local visPoint = getVisiblePoint(tPart, CurrentLockedTarget.Character)
                    if (not Settings.AimbotVisCheck) or visPoint then
                        local finalPos = visPoint or tPart.Position
                        local originPos = getLocalOrigin()
                        local physicalDistance = (originPos - finalPos).Magnitude
                        if physicalDistance <= Settings.AimbotMaxDistance then
                            local hum = CurrentLockedTarget.Character:FindFirstChild("Humanoid")
                            if hum and hum.Health > 0 then
                                targetIsValid = true 
                            end
                        end
                    end
                end
            end
        end

        if not targetIsValid then CurrentLockedTarget = getClosestPlayerToMouse() end

        local target = CurrentLockedTarget
        if target and target.Character then
            
            if not WasLocked then
                WasLocked = true
                SnapBackCFrame = Camera.CFrame
            end

            if Settings.AimbotAutoStop then
                local localHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if localHum then
                    if not WasAutoStopped then
                        StoredWalkSpeed = localHum.WalkSpeed
                        WasAutoStopped = true
                    end
                    localHum.WalkSpeed = 0
                end
            end
            
            local targetPart = getTargetPart(target.Character)
            if targetPart then
                local visPoint = getVisiblePoint(targetPart, target.Character)
                local targetPos = visPoint or targetPart.Position
                
                if targetPos then
                    if Settings.AimbotPrediction then
                        local velocity = targetPart.Velocity
                        targetPos = targetPos + Vector3.new(velocity.X * (Settings.AimbotPredX/10), velocity.Y * (Settings.AimbotPredY/10), velocity.Z * (Settings.AimbotPredX/10))
                    end

                    if Settings.AimHitTraces and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        if tick() - LastTraceTime >= (1 / 11) then
                            LastTraceTime = tick()
                            local origin = getLocalOrigin()
                            drawHitTrace(origin, targetPos)
                        end
                    end

                    local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                    if Settings.AimbotSmoothness == 0 then
                        Camera.CFrame = targetCFrame
                    else
                        local smoothFactor = 1 / (Settings.AimbotSmoothness + 1)
                        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothFactor)
                    end

                    if Settings.AimbotAutoShoot then
                        local screenPos = Camera:WorldToViewportPoint(targetPos)
                        local centerPos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
                        
                        local fovScale = 1 / math.tan(math.rad(Camera.FieldOfView / 2))
                        local partRadiusScreen = (targetPart.Size.Magnitude / 2) * fovScale * (Camera.ViewportSize.Y / 2) / screenPos.Z
                        
                        local origin = Camera.CFrame.Position
                        local directionToTarget = (targetPos - origin).Unit
                        local viewDirection = Camera.CFrame.LookVector
                        
                        local isFacingTarget = viewDirection:Dot(directionToTarget) > 0.99
                        
                        local readyToShoot = Settings.AimBlatantMode or (isFacingTarget and screenDist <= math.max(partRadiusScreen * 1.5, 12))

                        if readyToShoot then
                            if tick() - LastShootTime >= (1 / Settings.AimbotAutoShootCPS) then 
                                if Settings.AimbotAutoShootDelay > 0 then
                                    if not IsWaitingToShoot then
                                        IsWaitingToShoot = true
                                        task.spawn(function()
                                            task.wait(Settings.AimbotAutoShootDelay / 1000)
                                            if CurrentLockedTarget and CurrentLockedTarget.Character then
                                                local recheckPart = getTargetPart(CurrentLockedTarget.Character)
                                                if recheckPart then
                                                    local rv = getVisiblePoint(recheckPart, CurrentLockedTarget.Character)
                                                    if (not Settings.AimbotVisCheck) or rv then
                                                        LastShootTime = tick()
                                                        executeShoot()
                                                    end
                                                end
                                            end
                                            IsWaitingToShoot = false
                                        end)
                                    end
                                else
                                    LastShootTime = tick()
                                    executeShoot()
                                end
                            end
                        end
                    end

                end
            end
        else
            if WasLocked then
                if Settings.AimbotSnapBack and SnapBackCFrame then Camera.CFrame = SnapBackCFrame end
                WasLocked = false
                SnapBackCFrame = nil
            end
            if WasAutoStopped then
                local localHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if localHum then localHum.WalkSpeed = StoredWalkSpeed end
                WasAutoStopped = false
            end
        end
    else
        if WasLocked then
            if Settings.AimbotSnapBack and SnapBackCFrame then Camera.CFrame = SnapBackCFrame end
            WasLocked = false
            SnapBackCFrame = nil
        end
        if WasAutoStopped then
            local localHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if localHum then localHum.WalkSpeed = StoredWalkSpeed end
            WasAutoStopped = false
        end
        CurrentLockedTarget = nil
    end
end

-- ==========================================
-- [[ ESP ENGINE ]]
-- ==========================================

local function updateESP()
    local frameStart = debug.profilebegin("ESP_Loop")
    local clockStart = os.clock()
    
    if LocalPlayer.Character and LocalPlayer.Character ~= CachedCharacter then
        CachedCharacter = LocalPlayer.Character
        GlobalRayParams.FilterDescendantsInstances = {CachedCharacter}
        OriginalC0s[CachedCharacter] = nil 
    end
    
    handleEnvironment()
    handlePlayer()
    handleAimbot()
    handleSpinbot()

    if Settings.CameraFOVEnabled then
        Camera.FieldOfView = Settings.CameraFOV
    end

    if Settings.Master and Settings.ThirdPerson then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMinZoomDistance = Settings.ThirdPersonDist
        LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPersonDist
        TPActive = true
    elseif TPActive then
        LocalPlayer.CameraMode = OriginalCamMode
        LocalPlayer.CameraMinZoomDistance = OriginalMinZoom
        LocalPlayer.CameraMaxZoomDistance = OriginalMaxZoom
        TPActive = false
    end

    local players = Players:GetPlayers()
    
    for i, player in ipairs(players) do

        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local HRP = player.Character.HumanoidRootPart
            local Distance = (Camera.CFrame.Position - HRP.Position).Magnitude

            if not Settings.Master or
               (Settings.TeamCheck and player.Team == LocalPlayer.Team) or 
               (Settings.IgnorePrisoners and player.Team and player.Team.Name == "Prisoner") or
               (Distance > Settings.ESPOptimizer) then
                hideESP(player)
                continue
            end

            -- Throttled Visibility Check
            local shouldCheckVis = false
            if Settings.ESPVisCheck then
                if not LastRaycastTime[player] or tick() - LastRaycastTime[player] > 0.15 then
                    shouldCheckVis = true
                end
            end

            local isVisible = true
            if shouldCheckVis then
                isVisible = false
                LastRaycastTime[player] = tick()
                local head = player.Character:FindFirstChild("Head")
                local torso = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso")
                
                if head and getVisiblePoint(head, player.Character) then
                    isVisible = true
                elseif torso and getVisiblePoint(torso, player.Character) then
                    isVisible = true
                end
                
                if ESP_Cache[player] then ESP_Cache[player].IsVisible = isVisible end
            elseif Settings.ESPVisCheck then
                isVisible = ESP_Cache[player] and ESP_Cache[player].IsVisible or false
            end
            
            if Settings.ESPVisCheck and not isVisible then
                hideESP(player)
                continue
            end

            if not ESP_Cache[player] then
                ESP_Cache[player] = {
                    Box2D = createDrawing("Square", {Thickness = 1, Filled = false, Transparency = 1}),
                    Box3D = {}, Skeleton = {},
                    HeadCircle = createDrawing("Circle", {Thickness = 1, NumSides = 10, Filled = false, Transparency = 1}),
                    Tracer = createDrawing("Line", {Thickness = 1, Transparency = 1}),
                    Name = createDrawing("Text", {Size = 13, Center = true, Outline = true, Font = 2, Transparency = 1}),
                    Highlight = nil,
                    IsVisible = true
                }
                for i = 1, 12 do table.insert(ESP_Cache[player].Box3D, createDrawing("Line", {Thickness = 1, Transparency = 1})) end
                for i = 1, 15 do table.insert(ESP_Cache[player].Skeleton, createDrawing("Line", {Thickness = 1, Transparency = 1})) end
            end

            local Cache = ESP_Cache[player]
            local Vector, OnScreen = Camera:WorldToViewportPoint(HRP.Position)

            if OnScreen then
                local BoxColor = resolveColor(Settings.BoxColor, Settings.BoxChroma, Settings.BoxTeamColor, player)
                local NameColor = resolveColor(Settings.NamesColor, Settings.NamesChroma, Settings.NameTeamColor, player)
                local TracerColor = resolveColor(Settings.TracersColor, Settings.TracersChroma, Settings.TracerTeamColor, player)
                local ChamsColor = resolveColor(Settings.ChamsColor, Settings.ChamsChroma, Settings.ChamsTeamColor, player)
                local SkelColor = resolveColor(Settings.SkelColor, Settings.SkelChroma, Settings.SkelTeamColor, player)

                -- [[ BOX ESP ]] --
                if Settings.BoxEnabled then
                    if Settings.BoxType == "2D Box" then
                        local BoxSize = Vector2.new(2000 / Distance, 3000 / Distance)
                        Cache.Box2D.Visible = true; Cache.Box2D.Size = BoxSize; Cache.Box2D.Position = Vector2.new(Vector.X - BoxSize.X / 2, Vector.Y - BoxSize.Y / 2)
                        Cache.Box2D.Color = BoxColor; Cache.Box2D.Thickness = Settings.BoxThickness
                        for _, line in ipairs(Cache.Box3D) do line.Visible = false end
                    elseif Settings.BoxType == "3D Box" then
                        Cache.Box2D.Visible = false
                        local Size = Vector3.new(4, 5, 1) 
                        local PlayerCFrame = HRP.CFrame
                        local corners = {
                            PlayerCFrame * CFrame.new(-Size.X/2, Size.Y/2, -Size.Z/2), PlayerCFrame * CFrame.new(Size.X/2, Size.Y/2, -Size.Z/2),
                            PlayerCFrame * CFrame.new(Size.X/2, Size.Y/2, Size.Z/2), PlayerCFrame * CFrame.new(-Size.X/2, Size.Y/2, Size.Z/2),
                            PlayerCFrame * CFrame.new(-Size.X/2, -Size.Y/2, -Size.Z/2), PlayerCFrame * CFrame.new(Size.X/2, -Size.Y/2, -Size.Z/2),
                            PlayerCFrame * CFrame.new(Size.X/2, -Size.Y/2, Size.Z/2), PlayerCFrame * CFrame.new(-Size.X/2, -Size.Y/2, Size.Z/2)
                        }
                        local sP = {}
                        for j, c in ipairs(corners) do local p = Camera:WorldToViewportPoint(c.Position) sP[j] = Vector2.new(p.X, p.Y) end
                        for j, line in ipairs(Cache.Box3D) do
                            local pair = Box3D_Connections[j]
                            line.Visible = true; line.From = sP[pair[1]]; line.To = sP[pair[2]]
                            line.Color = BoxColor; line.Thickness = Settings.BoxThickness
                        end
                    end
                else Cache.Box2D.Visible = false; for _, line in ipairs(Cache.Box3D) do line.Visible = false end end

                -- [[ SKELETON ESP ]] --
                if Settings.SkelEnabled then
                    local Char = player.Character
                    local joints = Char:FindFirstChild("UpperTorso") and R15_Joints or R6_Joints
                    for j, line in ipairs(Cache.Skeleton) do
                        local pair = joints[j]
                        if pair then
                            local p1_part = Char:FindFirstChild(pair[1])
                            local p2_part = Char:FindFirstChild(pair[2])
                            if p1_part and p2_part then
                                local sP1 = Camera:WorldToViewportPoint(p1_part.Position)
                                local sP2 = Camera:WorldToViewportPoint(p2_part.Position)
                                line.Visible = true; line.From = Vector2.new(sP1.X, sP1.Y); line.To = Vector2.new(sP2.X, sP2.Y)
                                line.Color = SkelColor; line.Thickness = Settings.SkelThickness
                            else line.Visible = false end
                        else line.Visible = false end
                    end
                    local head = Char:FindFirstChild("Head")
                    if head then
                        local headP = Camera:WorldToViewportPoint(head.Position)
                        Cache.HeadCircle.Visible = true; Cache.HeadCircle.Position = Vector2.new(headP.X, headP.Y); Cache.HeadCircle.Radius = 400 / Distance; Cache.HeadCircle.Color = SkelColor
                    end
                else for _, line in ipairs(Cache.Skeleton) do line.Visible = false end Cache.HeadCircle.Visible = false end

                -- [[ TRACERS ]] --
                if Settings.TracersEnabled then
                    local Origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    if Settings.TracerOrigin == "Top" then Origin = Vector2.new(Camera.ViewportSize.X/2, 0) elseif Settings.TracerOrigin == "Center" then Origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) end
                    Cache.Tracer.Visible = true; Cache.Tracer.From = Origin; Cache.Tracer.To = Vector2.new(Vector.X, Vector.Y); Cache.Tracer.Color = TracerColor
                else Cache.Tracer.Visible = false end

                -- [[ NAMES ]] --
                if Settings.NamesEnabled then
                    Cache.Name.Visible = true; Cache.Name.Text = string.format("%s\n[%s]", Settings.UseDisplayNames and player.DisplayName or player.Name, math.floor(Distance))
                    Cache.Name.Position = Vector2.new(Vector.X, Vector.Y - (3000/Distance) - 40); Cache.Name.Color = NameColor
                else Cache.Name.Visible = false end

                -- [[ CHAMS ]] --
                if not Cache.Highlight or Cache.Highlight.Parent ~= player.Character then
                    if Cache.Highlight then Cache.Highlight:Destroy() end
                    local hl = Instance.new("Highlight")
                    hl.Parent = player.Character
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.Enabled = false 
                    Cache.Highlight = hl
                end

                if Settings.ChamsEnabled then
                    Cache.Highlight.Enabled = true
                    Cache.Highlight.FillColor = ChamsColor
                    Cache.Highlight.OutlineColor = ChamsColor
                else
                    Cache.Highlight.Enabled = false
                end
            else
                hideESP(player)
            end
        else hideESP(player) end
    end
    debug.profileend()
end

-- = [[ WATERMARK HANDLER ]] = --
local function handleWatermark()
    if not Settings.WatermarkEnabled then
        Watermark_Main.Visible = false; Watermark_Border.Visible = false; Watermark_Text.Visible = false
        return
    end
    FPSFrameCount = FPSFrameCount + 1
    if tick() - FPSTick >= 1 then CurrentFPS = FPSFrameCount; FPSFrameCount = 0; FPSTick = tick() end
    local watermarkContent = string.format(" Project iWare | %s | %s FPS | %s ", LocalPlayer.Name, CurrentFPS, os.date("%X"))
    Watermark_Text.Text = watermarkContent
    local Margin, Padding = 20, 6
    local ScreenSize = Camera.ViewportSize
    local BoxSize = Vector2.new(Watermark_Text.TextBounds.X + (Padding * 2), Watermark_Text.TextBounds.Y + (Padding * 2))
    local BoxPos
    if Settings.WatermarkCorner == "Top Left" then BoxPos = Vector2.new(Margin, Margin)
    elseif Settings.WatermarkCorner == "Top Right" then BoxPos = Vector2.new(ScreenSize.X - BoxSize.X - Margin, Margin)
    elseif Settings.WatermarkCorner == "Bottom Left" then BoxPos = Vector2.new(Margin, ScreenSize.Y - BoxSize.Y - Margin)
    elseif Settings.WatermarkCorner == "Bottom Right" then BoxPos = Vector2.new(ScreenSize.X - BoxSize.X - Margin, ScreenSize.Y - BoxSize.Y - Margin) end
    Watermark_Main.Size = BoxSize; Watermark_Main.Position = BoxPos; Watermark_Main.Visible = true
    Watermark_Border.Size = BoxSize; Watermark_Border.Position = BoxPos; Watermark_Border.Visible = true
    Watermark_Text.Position = BoxPos + Vector2.new(Padding, Padding); Watermark_Text.Visible = true
end

-- [[ START ]] --
Players.PlayerRemoving:Connect(removeESP)
RunService.RenderStepped:Connect(function()
    updateESP()
    handleWatermark()
end)

Rayfield:Notify({Title = "System", Content = "Fully Optimized Loop Engaged", Duration = 5})
