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

-- Forward Raycast Params
local GlobalRayParams = RaycastParams.new()
GlobalRayParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRayParams.IgnoreWater = true

-- Reverse Raycast Params
local GlobalReverseRayParams = RaycastParams.new()
GlobalReverseRayParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalReverseRayParams.IgnoreWater = true

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

-- [[ UI LIBRARY ]] --
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- [[ SETTINGS TABLE ]] --
local Settings = {
    Master = false,
    TeamCheck = false,
    IgnorePrisoners = false, 
    ESPOptimizer = 1000, 
    ESPVisCheck = false,
    
    -- [[ PLAYER SETTINGS ]] --
    PlayerMaster = false,
    FlyEnabled = false, FlyMode = "Hold", FlySpeed = 150,
    NoclipEnabled = false, NoclipMode = "Hold",
    InfJumpEnabled = false,
    TPForwardEnabled = false, TPForwardStuds = 5,
    StatsEnabled = false, WalkSpeed = DefaultWS, JumpPower = DefaultJP,
    BhopEnabled = false, BhopSpeed = 5,

    -- [[ SPINBOT SETTINGS ]] --
    SpinbotEnabled = false,
    SpinbotPitch = "None",
    SpinbotYaw = "Clockwise",
    SpinbotSpeed = 10,

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
    AimMaster = false,
    AimbotEnabled = false,
    AimbotMode = "Hold",
    AimbotMouseBind = "Right Click",
    AimbotTeamCheck = false,
    AimIgnorePrisoners = false, 
    AimIgnoreForcefield = false,
    AimbotSmoothness = 0, 
    AimbotLockPart = "Head",
    AimbotVisCheck = false,
    AimbotWallbang = false,
    AimbotWallThickness = 2.0,
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
    
    -- [[ TRIGGERBOT SETTINGS ]] --
    TriggerbotEnabled = false,
    TriggerbotVisCheck = false,
    TriggerbotTeamCheck = false,
    TriggerbotDelay = 0,
    TriggerbotType = "Crosshair",

    -- [[ AIMBOT HIT TRACES ]] --
    AimHitTraces = false, 
    AimTraceColor = Color3.fromRGB(255, 0, 0), 
    AimTraceChroma = false,

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
    WatermarkEnabled = false
}

-- [[ WINDOW CREATION ]] --
local Window = Library:CreateWindow({
    Title = 'peekachu',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- [[ TABS ]] --
local Tabs = {
    Player = Window:AddTab('Player'),
    Visuals = Window:AddTab('Visuals'),
    Aimbot = Window:AddTab('Aimbot'),
    Misc = Window:AddTab('Miscellaneous'),
    Settings = Window:AddTab('Settings & UI'),
}

-- ==========================================
-- [[ PLAYER TAB UI ]]
-- ==========================================

local FlyActive = false
local NoclipActive = false
local WasNoclipping = false
local CurrentFlyGyro = nil
local CurrentFlyVelocity = nil

local PlayerMasterGroup = Tabs.Player:AddLeftGroupbox("Global Settings")
PlayerMasterGroup:AddToggle("PlayerMaster", {Text = "Master Switch", Default = false, Callback = function(v) Settings.PlayerMaster = v end})

local FlySection = Tabs.Player:AddLeftGroupbox("Flight")
FlySection:AddToggle("FlyEnabled", {Text = "Enable Fly", Default = false, Callback = function(v) Settings.FlyEnabled = v if not v then FlyActive = false end end})
FlySection:AddDropdown("FlyMode", {Values = {"Hold", "Toggle"}, Default = 1, Text = "Fly Mode", Callback = function(v) Settings.FlyMode = v end})
FlySection:AddLabel("Fly Keybind"):AddKeyPicker("FlyKey", {Default = 'None', SyncToggleState = false, Mode = 'Toggle', Text = "Fly Keybind"})
Options.FlyKey:OnClick(function() if Settings.PlayerMaster and Settings.FlyEnabled and Settings.FlyMode == "Toggle" then FlyActive = not FlyActive end end)
FlySection:AddSlider("FlySpeed", {Text = "Fly Speed", Default = 150, Min = 10, Max = 300, Rounding = 0, Suffix = " spd", Callback = function(v) Settings.FlySpeed = v end})

local NoclipSection = Tabs.Player:AddLeftGroupbox("Noclip")
NoclipSection:AddToggle("NoclipEnabled", {Text = "Enable Noclip", Default = false, Callback = function(v) Settings.NoclipEnabled = v if not v then NoclipActive = false end end})
NoclipSection:AddDropdown("NoclipMode", {Values = {"Hold", "Toggle", "Always On"}, Default = 1, Text = "Noclip Mode", Callback = function(v) Settings.NoclipMode = v end})
NoclipSection:AddLabel("Noclip Keybind"):AddKeyPicker("NoclipKey", {Default = 'None', SyncToggleState = false, Mode = 'Toggle', Text = "Noclip Keybind"})
Options.NoclipKey:OnClick(function() if Settings.PlayerMaster and Settings.NoclipEnabled and Settings.NoclipMode == "Toggle" then NoclipActive = not NoclipActive end end)

local SpinbotSection = Tabs.Player:AddLeftGroupbox("Spinbot")
SpinbotSection:AddToggle("SpinbotEnabled", {Text = "Enable Spinbot", Default = false, Callback = function(v) Settings.SpinbotEnabled = v end})
SpinbotSection:AddDropdown("SpinbotPitch", {Values = {"None", "Sky", "Ground"}, Default = 1, Text = "Face Direction (Pitch)", Callback = function(v) Settings.SpinbotPitch = v end})
SpinbotSection:AddDropdown("SpinbotYaw", {Values = {"Clockwise", "Counter-Clockwise", "Jitter"}, Default = 1, Text = "Spin Direction (Yaw)", Callback = function(v) Settings.SpinbotYaw = v end})
SpinbotSection:AddSlider("SpinbotSpeed", {Text = "Spin Speed", Default = 10, Min = 1, Max = 100, Rounding = 0, Suffix = " °/f", Callback = function(v) Settings.SpinbotSpeed = v end})

local JumpSection = Tabs.Player:AddRightGroupbox("Jumping")
JumpSection:AddToggle("InfJumpEnabled", {Text = "Infinite Jump", Default = false, Callback = function(v) Settings.InfJumpEnabled = v end})

local TPWallSection = Tabs.Player:AddRightGroupbox("Teleportation")
TPWallSection:AddToggle("TPForwardEnabled", {Text = "Enable Teleport Behind Walls", Default = false, Callback = function(v) Settings.TPForwardEnabled = v end})
TPWallSection:AddLabel("Teleport Keybind"):AddKeyPicker("TPForwardKey", {Default = 'None', SyncToggleState = false, Mode = 'Toggle', Text = "Teleport Forward Key"})
Options.TPForwardKey:OnClick(function()
    if Settings.PlayerMaster and Settings.TPForwardEnabled then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -Settings.TPForwardStuds) end
    end
end)
TPWallSection:AddSlider("TPForwardStuds", {Text = "Teleport Distance", Default = 5, Min = 1, Max = 100, Rounding = 0, Suffix = " studs", Callback = function(v) Settings.TPForwardStuds = v end})

local StatsSection = Tabs.Player:AddRightGroupbox("Value Multipliers")
StatsSection:AddToggle("StatsEnabled", {Text = "Enable Multipliers", Default = false, Callback = function(v) 
    Settings.StatsEnabled = v 
    if not v then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = DefaultWS; hum.JumpPower = DefaultJP end
    end
end})
StatsSection:AddSlider("WalkSpeed", {Text = "Walk Speed", Default = DefaultWS, Min = 0, Max = 500, Rounding = 0, Suffix = " ws", Callback = function(v) Settings.WalkSpeed = v end})
StatsSection:AddSlider("JumpPower", {Text = "Jump Power", Default = DefaultJP, Min = 0, Max = 500, Rounding = 0, Suffix = " jp", Callback = function(v) Settings.JumpPower = v end})
StatsSection:AddButton({Text = "Reset Values", Func = function() 
    Settings.WalkSpeed = DefaultWS
    Settings.JumpPower = DefaultJP
    Options.WalkSpeed:SetValue(DefaultWS)
    Options.JumpPower:SetValue(DefaultJP)
end})

local BhopSection = Tabs.Player:AddRightGroupbox("Bunny Hop")
BhopSection:AddToggle("BhopEnabled", {Text = "Enable Bunny Hop", Default = false, Callback = function(v) Settings.BhopEnabled = v end})
BhopSection:AddSlider("BhopSpeed", {Text = "Bunny Hop Speed", Default = 5, Min = 1, Max = 50, Rounding = 0, Suffix = " pwr", Callback = function(v) Settings.BhopSpeed = v end})


-- ==========================================
-- [[ VISUALS TAB UI ]]
-- ==========================================

local VisMasterGroup = Tabs.Visuals:AddLeftGroupbox("Global Settings")
VisMasterGroup:AddToggle("Master", {Text = "Master Switch", Default = false, Callback = function(v) Settings.Master = v end})

local VisSettingsGroup = Tabs.Visuals:AddLeftGroupbox("Visuals Settings")
VisSettingsGroup:AddToggle("TeamCheck", {Text = "Team Check", Default = false, Callback = function(v) Settings.TeamCheck = v end})

if game.PlaceId == 606849621 then
    VisSettingsGroup:AddToggle("IgnorePrisoners", {Text = "Ignore Prisoners", Default = false, Callback = function(v) Settings.IgnorePrisoners = v end}) 
end

VisSettingsGroup:AddSlider("ESPOptimizer", {Text = "ESP Optimizer", Default = 1000, Min = 100, Max = 10000, Rounding = 0, Suffix = " studs", Callback = function(v) Settings.ESPOptimizer = v end}) 
VisSettingsGroup:AddToggle("ESPVisCheck", {Text = "Visibility Check", Default = false, Callback = function(v) Settings.ESPVisCheck = v end})

local CameraSection = Tabs.Visuals:AddLeftGroupbox("Camera & Screen")
CameraSection:AddToggle("CameraFOVEnabled", {
    Text = "Enable FOV Changer", 
    Default = false, 
    Callback = function(v) 
        Settings.CameraFOVEnabled = v 
        if not v then Camera.FieldOfView = DefaultFOV end
    end
})
CameraSection:AddSlider("CameraFOV", {Text = "Field of View", Default = DefaultFOV, Min = 10, Max = 120, Rounding = 0, Suffix = "°", Callback = function(v) Settings.CameraFOV = v end})

local ChamsSection = Tabs.Visuals:AddLeftGroupbox("Chams")
ChamsSection:AddToggle("ChamsEnabled", {Text = "Enable Chams", Default = false, Callback = function(v) Settings.ChamsEnabled = v end})
ChamsSection:AddLabel("Chams Color"):AddColorPicker("ChamsColor", {Default = Color3.fromRGB(255, 0, 0), Callback = function(v) Settings.ChamsColor = v end})
ChamsSection:AddToggle("ChamsChroma", {Text = "Chroma", Default = false, Callback = function(v) Settings.ChamsChroma = v end})
ChamsSection:AddToggle("ChamsTeamColor", {Text = "Prefer Team Color", Default = false, Callback = function(v) Settings.ChamsTeamColor = v end})

local TracerSection = Tabs.Visuals:AddLeftGroupbox("Tracers")
TracerSection:AddToggle("TracersEnabled", {Text = "Enable Tracers", Default = false, Callback = function(v) Settings.TracersEnabled = v end})
TracerSection:AddDropdown("TracerOrigin", {Values = {"Top", "Center", "Bottom"}, Default = 1, Text = "Tracer Origin", Callback = function(v) Settings.TracerOrigin = v end})
TracerSection:AddLabel("Tracer Color"):AddColorPicker("TracersColor", {Default = Color3.fromRGB(255, 255, 255), Callback = function(v) Settings.TracersColor = v end})
TracerSection:AddToggle("TracersChroma", {Text = "Chroma", Default = false, Callback = function(v) Settings.TracersChroma = v end})
TracerSection:AddToggle("TracerTeamColor", {Text = "Prefer Team Color", Default = false, Callback = function(v) Settings.TracerTeamColor = v end})

local SkelSection = Tabs.Visuals:AddRightGroupbox("Skeleton")
SkelSection:AddToggle("SkelEnabled", {Text = "Enable Skeleton", Default = false, Callback = function(v) Settings.SkelEnabled = v end})
SkelSection:AddSlider("SkelThickness", {Text = "Skeleton Thickness", Default = 1, Min = 1, Max = 5, Rounding = 0, Suffix = "px", Callback = function(v) Settings.SkelThickness = v end})
SkelSection:AddLabel("Skeleton Color"):AddColorPicker("SkelColor", {Default = Color3.fromRGB(255, 255, 255), Callback = function(v) Settings.SkelColor = v end})
SkelSection:AddToggle("SkelChroma", {Text = "Chroma", Default = false, Callback = function(v) Settings.SkelChroma = v end})
SkelSection:AddToggle("SkelTeamColor", {Text = "Prefer Team Color", Default = false, Callback = function(v) Settings.SkelTeamColor = v end})

local NameSection = Tabs.Visuals:AddRightGroupbox("Names")
NameSection:AddToggle("NamesEnabled", {Text = "Enable Names", Default = false, Callback = function(v) Settings.NamesEnabled = v end})
NameSection:AddToggle("UseDisplayNames", {Text = "Prefer Display Names", Default = false, Callback = function(v) Settings.UseDisplayNames = v end})
NameSection:AddLabel("Name Color"):AddColorPicker("NamesColor", {Default = Color3.fromRGB(255, 255, 255), Callback = function(v) Settings.NamesColor = v end})
NameSection:AddToggle("NamesChroma", {Text = "Chroma", Default = false, Callback = function(v) Settings.NamesChroma = v end})
NameSection:AddToggle("NameTeamColor", {Text = "Prefer Team Color", Default = false, Callback = function(v) Settings.NameTeamColor = v end})

local BoxSection = Tabs.Visuals:AddRightGroupbox("Boxes")
BoxSection:AddToggle("BoxEnabled", {Text = "Enable Boxes", Default = false, Callback = function(v) Settings.BoxEnabled = v end})
BoxSection:AddDropdown("BoxType", {Values = {"2D Box", "3D Box"}, Default = 1, Text = "Box Type", Callback = function(v) Settings.BoxType = v end})
BoxSection:AddSlider("BoxThickness", {Text = "Box Thickness", Default = 1, Min = 1, Max = 3, Rounding = 0, Suffix = "px", Callback = function(v) Settings.BoxThickness = v end})
BoxSection:AddLabel("Box Color"):AddColorPicker("BoxColor", {Default = Color3.fromRGB(255, 255, 255), Callback = function(v) Settings.BoxColor = v end})
BoxSection:AddToggle("BoxChroma", {Text = "Chroma", Default = false, Callback = function(v) Settings.BoxChroma = v end})
BoxSection:AddToggle("BoxTeamColor", {Text = "Prefer Team Color", Default = false, Callback = function(v) Settings.BoxTeamColor = v end})

local TPSection = Tabs.Visuals:AddRightGroupbox("Third Person")
TPSection:AddToggle("ThirdPerson", {
    Text = "Third Person", 
    Default = false, 
    Callback = function(v) 
        if v and not TPActive then
            OriginalCamMode = LocalPlayer.CameraMode
            OriginalMinZoom = LocalPlayer.CameraMinZoomDistance
            OriginalMaxZoom = LocalPlayer.CameraMaxZoomDistance
        end
        Settings.ThirdPerson = v 
    end
})
TPSection:AddSlider("ThirdPersonDist", {Text = "Third Person Distance", Default = 15, Min = 5, Max = 100, Rounding = 0, Suffix = " studs", Callback = function(v) Settings.ThirdPersonDist = v end})


-- ==========================================
-- [[ AIMBOT TAB UI ]]
-- ==========================================

local AimMasterGroup = Tabs.Aimbot:AddLeftGroupbox("Global Settings")
AimMasterGroup:AddToggle("AimMaster", {Text = "Master Switch", Default = false, Callback = function(v) Settings.AimMaster = v end})

local AimSettingsGroup = Tabs.Aimbot:AddLeftGroupbox("Aimbot Settings")
AimSettingsGroup:AddToggle("AimbotEnabled", {Text = "Enable Aimbot", Default = false, Callback = function(v) Settings.AimbotEnabled = v end})
AimSettingsGroup:AddDropdown("AimbotMode", {Values = {"Hold", "Toggle", "Always On"}, Default = 1, Text = "Aimbot Mode", Callback = function(v) Settings.AimbotMode = v end})
AimSettingsGroup:AddDropdown("AimbotMouseBind", {Values = {"None", "Left Click", "Right Click", "Middle Click"}, Default = 3, Text = "Mouse Bind", Callback = function(v) Settings.AimbotMouseBind = v end})
AimSettingsGroup:AddLabel("Keyboard Bind"):AddKeyPicker("AimbotKey", {Default = 'None', SyncToggleState = false, Mode = 'Hold', Text = "Keyboard Bind"})

local AimTargetingSection = Tabs.Aimbot:AddLeftGroupbox("Targeting & Checks")
AimTargetingSection:AddDropdown("AimbotLockPart", {Values = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}, Default = 1, Text = "Lock Part", Callback = function(v) Settings.AimbotLockPart = v end})
AimTargetingSection:AddSlider("AimbotSmoothness", {Text = "Smoothing", Default = 0, Min = 0, Max = 20, Rounding = 0, Suffix = "x", Callback = function(v) Settings.AimbotSmoothness = v end})
AimTargetingSection:AddSlider("AimbotMaxDistance", {Text = "Lock Range", Default = 1000, Min = 100, Max = 10000, Rounding = 0, Suffix = " studs", Callback = function(v) Settings.AimbotMaxDistance = v end}) 
AimTargetingSection:AddToggle("AimbotVisCheck", {Text = "Visibility Check", Default = false, Callback = function(v) Settings.AimbotVisCheck = v end}) 
AimTargetingSection:AddToggle("AimbotSnapBack", {Text = "Snap Back Camera", Default = false, Callback = function(v) Settings.AimbotSnapBack = v end})
AimTargetingSection:AddToggle("AimbotTeamCheck", {Text = "Team Check", Default = false, Callback = function(v) Settings.AimbotTeamCheck = v end})
AimTargetingSection:AddToggle("AimIgnoreForcefield", {Text = "Ignore Forcefields", Default = false, Callback = function(v) Settings.AimIgnoreForcefield = v end})

if game.PlaceId == 606849621 then
    AimTargetingSection:AddToggle("AimIgnorePrisoners", {Text = "Ignore Prisoners", Default = false, Callback = function(v) Settings.AimIgnorePrisoners = v end})
end

local FOVSection = Tabs.Aimbot:AddLeftGroupbox("FOV Ring")
FOVSection:AddToggle("Aimbot360FOV", {Text = "360° FOV", Default = false, Callback = function(v) Settings.Aimbot360FOV = v end})
FOVSection:AddToggle("AimbotDrawFOV", {Text = "Draw FOV", Default = false, Callback = function(v) Settings.AimbotDrawFOV = v end})
FOVSection:AddSlider("AimbotFOVRadius", {Text = "FOV Radius", Default = 100, Min = 10, Max = 800, Rounding = 0, Suffix = "px", Callback = function(v) Settings.AimbotFOVRadius = v end})
FOVSection:AddLabel("FOV Color"):AddColorPicker("AimbotFOVColor", {Default = Color3.fromRGB(255, 255, 255), Callback = function(v) Settings.AimbotFOVColor = v end})
FOVSection:AddToggle("AimbotFOVChroma", {Text = "Chroma FOV", Default = false, Callback = function(v) Settings.AimbotFOVChroma = v end})

local TriggerbotSection = Tabs.Aimbot:AddRightGroupbox("Triggerbot")
TriggerbotSection:AddToggle("TriggerbotEnabled", {Text = "Enable Triggerbot", Default = false, Callback = function(v) 
    if v and Settings.AimbotAutoShoot then
        Toggles.AimbotAutoShoot:SetValue(false)
    end
    Settings.TriggerbotEnabled = v 
end})
TriggerbotSection:AddToggle("TriggerbotVisCheck", {Text = "Visibility Check", Default = false, Callback = function(v) Settings.TriggerbotVisCheck = v end})
TriggerbotSection:AddToggle("TriggerbotTeamCheck", {Text = "Team Check", Default = false, Callback = function(v) Settings.TriggerbotTeamCheck = v end})
TriggerbotSection:AddDropdown("TriggerbotType", {Values = {"Crosshair", "Cursor"}, Default = 1, Text = "Trigger Type", Callback = function(v) Settings.TriggerbotType = v end})
TriggerbotSection:AddSlider("TriggerbotDelay", {Text = "Trigger Delay", Default = 0, Min = 0, Max = 500, Rounding = 0, Suffix = " ms", Callback = function(v) Settings.TriggerbotDelay = v end})

local AimAutomationSection = Tabs.Aimbot:AddRightGroupbox("Automation")
AimAutomationSection:AddToggle("AimbotAutoShoot", {Text = "Auto Shoot", Default = false, Callback = function(v) 
    if v and Settings.TriggerbotEnabled then
        Toggles.TriggerbotEnabled:SetValue(false)
    end
    Settings.AimbotAutoShoot = v 
end}) 
AimAutomationSection:AddToggle("AimBlatantMode", {Text = "Blatant Auto Shoot", Default = false, Callback = function(v) Settings.AimBlatantMode = v end})
AimAutomationSection:AddToggle("AimbotAutoStop", {Text = "Auto Stop", Default = false, Callback = function(v) Settings.AimbotAutoStop = v end})
AimAutomationSection:AddDropdown("AimAutoShootMethod", {Values = {"VIM", "Hardware", "Hybrid"}, Default = 2, Text = "Auto Shoot Method", Callback = function(v) Settings.AimAutoShootMethod = v end})
AimAutomationSection:AddSlider("AimbotAutoShootCPS", {Text = "Auto Shoot CPS", Default = 10, Min = 1, Max = 30, Rounding = 0, Suffix = " clicks/s", Callback = function(v) Settings.AimbotAutoShootCPS = v end}) 
AimAutomationSection:AddSlider("AimbotAutoShootDelay", {Text = "Auto Shoot Delay", Default = 0, Min = 0, Max = 500, Rounding = 0, Suffix = " ms", Callback = function(v) Settings.AimbotAutoShootDelay = v end})

local AutoWallSection = Tabs.Aimbot:AddRightGroupbox("Auto Wall")
AutoWallSection:AddToggle("AimbotWallbang", {Text = "Auto Wall", Default = false, Callback = function(v) Settings.AimbotWallbang = v end}) 
AutoWallSection:AddSlider("AimbotWallThickness", {Text = "Auto Wall Sensitivity", Default = 2.0, Min = 0.1, Max = 15.0, Rounding = 1, Suffix = " studs", Callback = function(v) Settings.AimbotWallThickness = v end})

local HitTraceSection = Tabs.Aimbot:AddRightGroupbox("Hit Traces")
HitTraceSection:AddToggle("AimHitTraces", {Text = "Enable Hit Traces", Default = false, Callback = function(v) Settings.AimHitTraces = v end})
HitTraceSection:AddLabel("Hit Trace Color"):AddColorPicker("AimTraceColor", {Default = Color3.fromRGB(255, 0, 0), Callback = function(v) Settings.AimTraceColor = v end})
HitTraceSection:AddToggle("AimTraceChroma", {Text = "Hit Trace Chroma", Default = false, Callback = function(v) Settings.AimTraceChroma = v end})

local PredSection = Tabs.Aimbot:AddRightGroupbox("Prediction")
PredSection:AddToggle("AimbotPrediction", {Text = "Enable Prediction", Default = false, Callback = function(v) Settings.AimbotPrediction = v end})
PredSection:AddSlider("AimbotPredX", {Text = "Prediction X", Default = 0, Min = 0, Max = 10, Rounding = 0, Suffix = " offset", Callback = function(v) Settings.AimbotPredX = v end})
PredSection:AddSlider("AimbotPredY", {Text = "Prediction Y", Default = 0, Min = 0, Max = 10, Rounding = 0, Suffix = " offset", Callback = function(v) Settings.AimbotPredY = v end})


-- ==========================================
-- [[ MISCELLANEOUS TAB UI ]]
-- ==========================================

local EnvSection = Tabs.Misc:AddLeftGroupbox("Environment")
EnvSection:AddToggle("EnvColorEnabled", {Text = "Enable Custom Environment Color", Default = false, Callback = function(v) Settings.EnvColorEnabled = v end})
EnvSection:AddLabel("Environment Color"):AddColorPicker("EnvColor", {Default = Color3.fromRGB(255, 255, 255), Callback = function(v) Settings.EnvColor = v end})
EnvSection:AddToggle("EnvChroma", {Text = "Chroma", Default = false, Callback = function(v) Settings.EnvChroma = v end})

-- ==========================================
-- [[ SETTINGS & CONFIG TAB UI ]]
-- ==========================================

local WatermarkSection = Tabs.Settings:AddLeftGroupbox("Watermark")
WatermarkSection:AddToggle("WatermarkEnabled", {
    Text = "Enable Watermark", 
    Default = false, 
    Callback = function(v) 
        Settings.WatermarkEnabled = v 
        Library:SetWatermarkVisibility(v)
    end
})

-- Library/Menu System
local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload Menu', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'K', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind

-- Setup LinoriaLib's Native Theme & Save Managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('peekachu')
SaveManager:SetFolder('peekachu/configs')

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- Apply default accent color (Yellow) after loading the themes
if Options.AccentColor then
    Options.AccentColor:SetValueRGB(Color3.fromRGB(255, 255, 0))
end

-- ==========================================
-- [[ CORE LOGIC HANDLERS ]]
-- ==========================================

local ESP_Cache = {} 
local FOV_Circle = Drawing.new("Circle") 

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

local LastTriggerTime = 0
local IsWaitingToTrigger = false

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

-- Safely retrieves and caches character parts without spamming FindFirstChild
local function getCachedPart(player, partName)
    local cache = ESP_Cache[player]
    if not cache or not player.Character then return nil end
    
    if cache.Character ~= player.Character then
        cache.Character = player.Character
        cache.Parts = {} 
    end
    
    if cache.Parts[partName] then return cache.Parts[partName] end
    
    local part = player.Character:FindFirstChild(partName)
    if part then cache.Parts[partName] = part end
    return part
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
-- [[ SMART RAYCASTING ENGINE ]]
-- ==========================================

-- We pool RaycastParams to strictly avoid massive GC lag spikes caused by re-allocating them in a loop
local AdvancedRayParams = RaycastParams.new()
local ReusableFilterList = {} 

local function advancedRaycast(origin, direction, rayParams)
    table.clear(ReusableFilterList)
    if rayParams.FilterDescendantsInstances then
        for i = 1, #rayParams.FilterDescendantsInstances do
            ReusableFilterList[i] = rayParams.FilterDescendantsInstances[i]
        end
    end

    AdvancedRayParams.FilterType = rayParams.FilterType
    AdvancedRayParams.IgnoreWater = rayParams.IgnoreWater
    
    for i = 1, 8 do
        AdvancedRayParams.FilterDescendantsInstances = ReusableFilterList
        local result = workspace:Raycast(origin, direction, AdvancedRayParams)
        
        if result and result.Instance:IsA("BasePart") then
            -- Skip parts with transparency > 0 and <= 0.50 (windows, barriers, invisible walls) to prevent blocking
            if AdvancedRayParams.FilterType == Enum.RaycastFilterType.Exclude and (result.Instance.Transparency > 0 and result.Instance.Transparency <= 0.50) then
                -- However, if the hit is actually a player/humanoid, we MUST NOT skip it!
                local model = result.Instance:FindFirstAncestorOfClass("Model")
                if model and model:FindFirstChild("Humanoid") then
                    return result 
                end
                
                table.insert(ReusableFilterList, result.Instance)
            else
                return result
            end
        else
            return result
        end
    end
    return nil
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
            FlyActive = Options.FlyKey and Options.FlyKey:GetState() or false
        end
    else
        FlyActive = false
    end
    
    if Settings.NoclipEnabled then
        if Settings.NoclipMode == "Always On" then
            NoclipActive = true
        elseif Settings.NoclipMode == "Hold" then
            NoclipActive = Options.NoclipKey and Options.NoclipKey:GetState() or false
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
        if hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            local currentVel = hrp.Velocity
            local speedMultiplier = DefaultWS + (Settings.BhopSpeed * 5)
            hrp.Velocity = Vector3.new(moveDir.X * speedMultiplier, currentVel.Y, moveDir.Z * speedMultiplier)
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

    if Settings.PlayerMaster and Settings.SpinbotEnabled then
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
-- [[ AIMBOT & TRIGGERBOT ENGINE ]]
-- ==========================================

local function getLocalOrigin()
    if LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- By adding a 1.5 stud vertical offset to the HRP, we create a stable
            -- "phantom head" position that doesn't swing wildly during Spinbot.
            return hrp.Position + Vector3.new(0, 1.5, 0)
        end
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head then return head.Position end
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

local CachedAimbotRayParams = RaycastParams.new()
CachedAimbotRayParams.FilterType = Enum.RaycastFilterType.Exclude
CachedAimbotRayParams.IgnoreWater = true

local CachedAimbotReverseParams = RaycastParams.new()
CachedAimbotReverseParams.FilterType = Enum.RaycastFilterType.Exclude
CachedAimbotReverseParams.IgnoreWater = true

local function getVisiblePoint(targetPart, targetCharacter, checkWallbang)
    local origin = getLocalOrigin()
    local sizeX, sizeY, sizeZ = targetPart.Size.X / 2, targetPart.Size.Y / 2, targetPart.Size.Z / 2
    
    if checkWallbang and Settings.AimbotWallbang then
        CachedAimbotReverseParams.FilterDescendantsInstances = {targetCharacter, LocalPlayer.Character}
    end

    for i = 1, #VisibilityOffsets do
        local offset = VisibilityOffsets[i]
        local checkPos = targetPart.CFrame * Vector3.new(offset.X * sizeX, offset.Y * sizeY, offset.Z * sizeZ)
        local direction = checkPos - origin
        
        CachedAimbotRayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        local result = advancedRaycast(origin, direction, CachedAimbotRayParams)
        
        if not result or result.Instance:IsDescendantOf(targetCharacter) then
            return checkPos
        end
        
        -- Reverse Raycast Check (Auto Wall)
        if checkWallbang and Settings.AimbotWallbang then
            local reverseResult = advancedRaycast(checkPos, -direction, CachedAimbotReverseParams)
            
            if result and reverseResult then
                local thickness = (result.Position - reverseResult.Position).Magnitude
                if thickness <= Settings.AimbotWallThickness then
                    return checkPos 
                end
            end
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
            
            -- Call respects Auto Wall
            local visPoint = getVisiblePoint(targetPart, player.Character, true)
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

-- Used for fast triggerbot caching
local triggerbotRayParams = RaycastParams.new()
local triggerbotFilter = {}

local function handleTriggerbot()
    if not Settings.AimMaster or not Settings.TriggerbotEnabled then return end

    local origin, direction
    if Settings.TriggerbotType == "Crosshair" then
        local center = Camera.ViewportSize / 2
        local ray = Camera:ViewportPointToRay(center.X, center.Y)
        origin = ray.Origin
        direction = ray.Direction * 1000
    else
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        origin = ray.Origin
        direction = ray.Direction * 1000
    end

    if Settings.TriggerbotVisCheck then
        triggerbotRayParams.FilterType = Enum.RaycastFilterType.Exclude
        triggerbotRayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    else
        table.clear(triggerbotFilter)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then table.insert(triggerbotFilter, p.Character) end
        end
        triggerbotRayParams.FilterType = Enum.RaycastFilterType.Include
        triggerbotRayParams.FilterDescendantsInstances = triggerbotFilter
    end
    triggerbotRayParams.IgnoreWater = true

    local result = advancedRaycast(origin, direction, triggerbotRayParams)

    if result and result.Instance then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 then
            local targetPlayer = Players:GetPlayerFromCharacter(model)
            
            if targetPlayer and targetPlayer ~= LocalPlayer then
                if Settings.TriggerbotTeamCheck and targetPlayer.Team == LocalPlayer.Team then return end
                if Settings.AimIgnorePrisoners and targetPlayer.Team and targetPlayer.Team.Name == "Prisoner" then return end
                if Settings.AimIgnoreForcefield and model:FindFirstChildOfClass("ForceField") then return end

                local currentRate = 1 / math.max(1, Settings.AimbotAutoShootCPS)
                if tick() - LastTriggerTime >= currentRate then
                    if Settings.TriggerbotDelay > 0 then
                        if not IsWaitingToTrigger then
                            IsWaitingToTrigger = true
                            task.spawn(function()
                                task.wait(Settings.TriggerbotDelay / 1000)
                                LastTriggerTime = tick()
                                executeShoot()
                                IsWaitingToTrigger = false
                            end)
                        end
                    else
                        LastTriggerTime = tick()
                        executeShoot()
                    end
                end
            end
        end
    end
end

local function handleAimbot()
    FOV_Circle.Visible = Settings.AimMaster and Settings.AimbotEnabled and Settings.AimbotDrawFOV and not Settings.Aimbot360FOV
    
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
        currentRawTrigger = Options.AimbotKey and Options.AimbotKey:GetState() or false 
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

    if Settings.AimMaster and Settings.AimbotEnabled and isTriggered then
        
        local targetIsValid = false
        if CurrentLockedTarget and CurrentLockedTarget.Character then
            local hasFF = Settings.AimIgnoreForcefield and CurrentLockedTarget.Character:FindFirstChildOfClass("ForceField")
            if not hasFF then
                local tPart = getTargetPart(CurrentLockedTarget.Character)
                if tPart then
                    local visPoint = getVisiblePoint(tPart, CurrentLockedTarget.Character, true)
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
                local visPoint = getVisiblePoint(targetPart, target.Character, true)
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
                                                    local rv = getVisiblePoint(recheckPart, CurrentLockedTarget.Character, true)
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
    handleTriggerbot()
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

            if not ESP_Cache[player] then
                ESP_Cache[player] = {
                    Box2D = createDrawing("Square", {Thickness = 1, Filled = false, Transparency = 1}),
                    Box3D = {}, Skeleton = {},
                    HeadCircle = createDrawing("Circle", {Thickness = 1, NumSides = 10, Filled = false, Transparency = 1}),
                    Tracer = createDrawing("Line", {Thickness = 1, Transparency = 1}),
                    Name = createDrawing("Text", {Size = 13, Center = true, Outline = true, Font = 2, Transparency = 1}),
                    Highlight = nil,
                    IsVisible = true,
                    Character = nil,
                    Parts = {}
                }
                for j = 1, 12 do table.insert(ESP_Cache[player].Box3D, createDrawing("Line", {Thickness = 1, Transparency = 1})) end
                for j = 1, 15 do table.insert(ESP_Cache[player].Skeleton, createDrawing("Line", {Thickness = 1, Transparency = 1})) end
            end

            local isVisible = true
            if shouldCheckVis then
                isVisible = false
                LastRaycastTime[player] = tick()
                
                local head = getCachedPart(player, "Head")
                local torso = getCachedPart(player, "UpperTorso") or getCachedPart(player, "Torso")
                
                if head and getVisiblePoint(head, player.Character, false) then
                    isVisible = true
                elseif torso and getVisiblePoint(torso, player.Character, false) then
                    isVisible = true
                end
                
                ESP_Cache[player].IsVisible = isVisible
            elseif Settings.ESPVisCheck then
                isVisible = ESP_Cache[player].IsVisible or false
            end
            
            if Settings.ESPVisCheck and not isVisible then
                hideESP(player)
                continue
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
                    local joints = player.Character:FindFirstChild("UpperTorso") and R15_Joints or R6_Joints
                    for j, line in ipairs(Cache.Skeleton) do
                        local pair = joints[j]
                        if pair then
                            local p1_part = getCachedPart(player, pair[1])
                            local p2_part = getCachedPart(player, pair[2])
                            if p1_part and p2_part then
                                local sP1 = Camera:WorldToViewportPoint(p1_part.Position)
                                local sP2 = Camera:WorldToViewportPoint(p2_part.Position)
                                line.Visible = true; line.From = Vector2.new(sP1.X, sP1.Y); line.To = Vector2.new(sP2.X, sP2.Y)
                                line.Color = SkelColor; line.Thickness = Settings.SkelThickness
                            else line.Visible = false end
                        else line.Visible = false end
                    end
                    local head = getCachedPart(player, "Head")
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

-- [[ START ]] --
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    updateESP()
    
    if Settings.WatermarkEnabled then
        FPSFrameCount = FPSFrameCount + 1
        if tick() - FPSTick >= 1 then 
            CurrentFPS = FPSFrameCount
            FPSFrameCount = 0 
            FPSTick = tick() 
        end
        
        Library:SetWatermark((' peekachu | %s | %s FPS | %s '):format(
            LocalPlayer.Name,
            CurrentFPS,
            os.date("%X")
        ))
    end
end)

Library:Notify("System: peekachu Loaded Successfully", 5)
