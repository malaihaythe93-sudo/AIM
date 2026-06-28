local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

_G.EngineConfig = {
    AimbotActive = false,
    SilentAimActive = false,
    SmoothActive = false,
    ESPActive = false,
    HitboxActive = false,
    WeaponModActive = false,
    AimFOV = 150,
    SmoothValue = 5,
    HitboxSize = 2,
    HitboxPart = "HumanoidRootPart",
    TeamCheck = true,
    AdminDetectionActive = false,
    SpectatorWarningActive = false,
    PanicButtonActive = false,
    AutoHideActive = false,
    FPSCounterActive = false,
    PingDisplayActive = false,
    PlayerCountActive = false,
    SessionTimerActive = false,
    DistanceESPActive = false,
    HealthBarESPActive = false,
    BoxESPActive = false,
    NameTagESPActive = false,
    BoneESPActive = false,
    PredictionAimActive = false,
    NoRecoilActive = false,
    KillDeathStatsActive = false,
    ConfigSaveActive = false,
    AutoUpdateActive = false
}

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- =============== STATS TRACKING ===============
local SessionStartTime = tick()
local AdminList = {}
local SpectatorList = {}
local CurrentFPS = 0
local CurrentPing = 0
local KillCount = 0
local DeathCount = 0
local ESPCache = {}

-- FPS Counter
RunService.RenderStepped:Connect(function()
    CurrentFPS = math.floor(1 / RunService.RenderStepped:Wait())
end)

-- Ping Detection
spawn(function()
    while true do
        local Start = tick()
        pcall(function()
            game:HttpGet("https://google.com")
        end)
        CurrentPing = math.floor((tick() - Start) * 1000)
        task.wait(5)
    end
end)

-- Death Tracking
if LocalPlayer.Character then
    local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if Humanoid then
        Humanoid.Died:Connect(function()
            DeathCount = DeathCount + 1
        end)
    end
end

-- =============== FOV CIRCLE ===============
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 65, 65)
FOVCircle.Thickness = 2
FOVCircle.NumSides = 60
FOVCircle.Radius = _G.EngineConfig.AimFOV
FOVCircle.Filled = false
FOVCircle.Visible = false

RunService.RenderStepped:Connect(function()
    local ViewportSize = Camera.ViewportSize
    FOVCircle.Position = Vector2.new(ViewportSize.X / 2, ViewportSize.Y / 2)
    FOVCircle.Radius = _G.EngineConfig.AimFOV
    FOVCircle.Visible = (_G.EngineConfig.AimbotActive or _G.EngineConfig.SilentAimActive)
end)

-- =============== GET CLOSEST TARGET ===============
local function GetClosestTarget()
    local CurrentTarget = nil
    local ShortestDistance = _G.EngineConfig.AimFOV

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Head") then
            if _G.EngineConfig.TeamCheck and Player.Team == LocalPlayer.Team then 
                continue 
            end
            if Player.Character:FindFirstChildOfClass("Humanoid") and Player.Character.Humanoid.Health <= 0 then 
                continue 
            end

            local Point, OnScreen = Camera:WorldToViewportPoint(Player.Character.Head.Position)
            
            if OnScreen then
                local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local Distance = (Vector2.new(Point.X, Point.Y) - ScreenCenter).Magnitude
                
                if Distance < ShortestDistance then
                    CurrentTarget = Player
                    ShortestDistance = Distance
                end
            end
        end
    end
    return CurrentTarget
end

-- =============== AIMBOT ===============
RunService.RenderStepped:Connect(function()
    if _G.EngineConfig.AimbotActive then
        local Target = GetClosestTarget()
        if Target and Target.Character and Target.Character:FindFirstChild("Head") then
            local TargetCFrame = CFrame.new(Camera.CFrame.Position, Target.Character.Head.Position)
            if _G.EngineConfig.SmoothActive then
                Camera.CFrame = Camera.CFrame:lerp(TargetCFrame, 1 / _G.EngineConfig.SmoothValue)
            else
                Camera.CFrame = TargetCFrame
            end
        end
    end
end)

-- =============== SILENT AIM ===============
local RawMetatable = getrawmetatable(game)
local OldIndex = RawMetatable.__index
setreadonly(RawMetatable, false)

RawMetatable.__index = newcclosure(function(Object, Key)
    if _G.EngineConfig.SilentAimActive and Object == LocalPlayer:GetMouse() and (Key == "Hit" or Key == "Target") then
        local Target = GetClosestTarget()
        if Target and Target.Character and Target.Character:FindFirstChild("Head") then
            return (Key == "Hit" and Target.Character.Head.CFrame or Target.Character.Head)
        end
    end
    return OldIndex(Object, Key)
end)
setreadonly(RawMetatable, true)

-- =============== ADMIN DETECTION ===============
local function DetectAdmins()
    AdminList = {}
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if Player:FindFirstChild("leaderstats") then
                for _, v in pairs(Player.leaderstats:GetChildren()) do
                    if v.Name:lower():find("admin") or v.Name:lower():find("mod") then
                        table.insert(AdminList, Player.Name)
                    end
                end
            end
        end
    end
    return AdminList
end

-- =============== SPECTATOR DETECTION ===============
local function DetectSpectators()
    SpectatorList = {}
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character == nil then
            table.insert(SpectatorList, Player.Name)
        end
    end
    return SpectatorList
end

-- =============== DISTANCE ESP ===============
local function CreateDistanceESP()
    spawn(function()
        while _G.EngineConfig.DistanceESPActive do
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Head") then
                    if _G.EngineConfig.TeamCheck and Player.Team == LocalPlayer.Team then continue end
                    
                    local Distance = (LocalPlayer.Character.Head.Position - Player.Character.Head.Position).Magnitude
                    local Point, OnScreen = Camera:WorldToViewportPoint(Player.Character.Head.Position)
                    
                    if OnScreen then
                        if not ESPCache[Player] then
                            ESPCache[Player] = Drawing.new("Text")
                        end
                        
                        local TextDraw = ESPCache[Player]
                        TextDraw.Text = math.floor(Distance) .. "m"
                        TextDraw.Position = Vector2.new(Point.X, Point.Y)
                        TextDraw.Color = Color3.fromRGB(0, 255, 0)
                        TextDraw.Size = 18
                        TextDraw.Visible = true
                    end
                end
            end
            task.wait(0.1)
        end
        for _, Draw in pairs(ESPCache) do
            pcall(function() Draw:Remove() end)
        end
        ESPCache = {}
    end)
end

-- =============== HEALTH BAR ESP ===============
local function CreateHealthBarESP()
    spawn(function()
        while _G.EngineConfig.HealthBarESPActive do
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Head") then
                    if _G.EngineConfig.TeamCheck and Player.Team == LocalPlayer.Team then continue end
                    
                    local Humanoid = Player.Character:FindFirstChild("Humanoid")
                    if Humanoid then
                        local Point, OnScreen = Camera:WorldToViewportPoint(Player.Character.Head.Position)
                        
                        if OnScreen then
                            local HealthPercent = Humanoid.Health / Humanoid.MaxHealth
                            
                            if not ESPCache[Player .. "_health"] then
                                ESPCache[Player .. "_health"] = Drawing.new("Rectangle")
                            end
                            
                            local BarDraw = ESPCache[Player .. "_health"]
                            BarDraw.Width = 50
                            BarDraw.Height = 5
                            BarDraw.Position = Vector2.new(Point.X - 25, Point.Y + 30)
                            BarDraw.Color = Color3.fromRGB(255, 0, 0)
                            BarDraw.Filled = true
                            BarDraw.Visible = true
                            
                            if not ESPCache[Player .. "_health_fill"] then
                                ESPCache[Player .. "_health_fill"] = Drawing.new("Rectangle")
                            end
                            
                            local FillDraw = ESPCache[Player .. "_health_fill"]
                            FillDraw.Width = 50 * HealthPercent
                            FillDraw.Height = 5
                            FillDraw.Position = Vector2.new(Point.X - 25, Point.Y + 30)
                            FillDraw.Color = Color3.fromRGB(0, 255, 0)
                            FillDraw.Filled = true
                            FillDraw.Visible = true
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============== BOX ESP ===============
local function CreateBoxESP()
    spawn(function()
        while _G.EngineConfig.BoxESPActive do
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Head") then
                    if _G.EngineConfig.TeamCheck and Player.Team == LocalPlayer.Team then continue end
                    
                    local Head = Player.Character.Head
                    local Point, OnScreen = Camera:WorldToViewportPoint(Head.Position)
                    
                    if OnScreen then
                        if not ESPCache[Player .. "_box"] then
                            ESPCache[Player .. "_box"] = Drawing.new("Square")
                        end
                        
                        local BoxDraw = ESPCache[Player .. "_box"]
                        BoxDraw.Size = 50
                        BoxDraw.Position = Vector2.new(Point.X - 25, Point.Y - 25)
                        BoxDraw.Color = Color3.fromRGB(255, 255, 0)
                        BoxDraw.Thickness = 2
                        BoxDraw.Filled = false
                        BoxDraw.Visible = true
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============== NAME TAG ESP ===============
local function CreateNameTagESP()
    spawn(function()
        while _G.EngineConfig.NameTagESPActive do
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Head") then
                    if _G.EngineConfig.TeamCheck and Player.Team == LocalPlayer.Team then continue end
                    
                    local Point, OnScreen = Camera:WorldToViewportPoint(Player.Character.Head.Position)
                    
                    if OnScreen then
                        if not ESPCache[Player .. "_name"] then
                            ESPCache[Player .. "_name"] = Drawing.new("Text")
                        end
                        
                        local NameDraw = ESPCache[Player .. "_name"]
                        NameDraw.Text = Player.Name
                        NameDraw.Position = Vector2.new(Point.X, Point.Y - 40)
                        NameDraw.Color = Color3.fromRGB(255, 255, 255)
                        NameDraw.Size = 16
                        NameDraw.Visible = true
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============== BONE ESP ===============
local function CreateBoneESP()
    spawn(function()
        while _G.EngineConfig.BoneESPActive do
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer and Player.Character then
                    if _G.EngineConfig.TeamCheck and Player.Team == LocalPlayer.Team then continue end
                    
                    for _, Part in pairs(Player.Character:GetChildren()) do
                        if Part:IsA("BasePart") then
                            local Point, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                            
                            if OnScreen then
                                local CacheKey = Player .. "_" .. Part.Name
                                if not ESPCache[CacheKey] then
                                    ESPCache[CacheKey] = Drawing.new("Circle")
                                end
                                
                                local BoneDraw = ESPCache[CacheKey]
                                BoneDraw.Radius = 3
                                BoneDraw.Position = Vector2.new(Point.X, Point.Y)
                                BoneDraw.Color = Color3.fromRGB(0, 0, 255)
                                BoneDraw.Filled = true
                                BoneDraw.Visible = true
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============== PREDICTION AIM ===============
local function GetPredictionTarget()
    local Target = GetClosestTarget()
    if Target and Target.Character then
        local Head = Target.Character.Head
        local Humanoid = Target.Character:FindFirstChild("Humanoid")
        
        if Humanoid and Humanoid.Parent:FindFirstChild("Humanoid") then
            local Velocity = Head.AssemblyLinearVelocity
            local Distance = (LocalPlayer.Character.Head.Position - Head.Position).Magnitude
            local PredictedPos = Head.Position + (Velocity * (Distance / 100))
            
            return CFrame.new(Camera.CFrame.Position, PredictedPos)
        end
    end
    return nil
end

RunService.RenderStepped:Connect(function()
    if _G.EngineConfig.PredictionAimActive then
        local PredictedCFrame = GetPredictionTarget()
        if PredictedCFrame then
            if _G.EngineConfig.SmoothActive then
                Camera.CFrame = Camera.CFrame:lerp(PredictedCFrame, 1 / _G.EngineConfig.SmoothValue)
            else
                Camera.CFrame = PredictedCFrame
            end
        end
    end
end)

-- =============== NO RECOIL ===============
RunService.RenderStepped:Connect(function()
    if _G.EngineConfig.NoRecoilActive then
        local Tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if Tool then
            for _, v in pairs(Tool:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    if v.Name:lower():find("recoil") or v.Name:lower():find("kick") then
                        v.Value = 0
                    end
                end
            end
        end
    end
end)

-- =============== KILL/DEATH STATS ===============
local function DisplayKDStats()
    OrionLib:MakeNotification({
        Name = "📊 K/D Stats",
        Content = "Kills: " .. KillCount .. " | Deaths: " .. DeathCount .. " | Ratio: " .. (DeathCount > 0 and math.floor(KillCount / DeathCount * 100) / 100 or KillCount),
        Image = "rbxassetid://4483345998",
        Time = 5
    })
end

-- =============== CONFIG SAVE/LOAD ===============
local ConfigData = {}

local function SaveConfig(ConfigName)
    ConfigData[ConfigName] = {
        AimbotActive = _G.EngineConfig.AimbotActive,
        SilentAimActive = _G.EngineConfig.SilentAimActive,
        SmoothActive = _G.EngineConfig.SmoothActive,
        SmoothValue = _G.EngineConfig.SmoothValue,
        AimFOV = _G.EngineConfig.AimFOV,
        DistanceESPActive = _G.EngineConfig.DistanceESPActive,
        HealthBarESPActive = _G.EngineConfig.HealthBarESPActive,
        BoxESPActive = _G.EngineConfig.BoxESPActive,
        NoRecoilActive = _G.EngineConfig.NoRecoilActive,
        TeamCheck = _G.EngineConfig.TeamCheck
    }
    
    OrionLib:MakeNotification({
        Name = "💾 Config Saved",
        Content = "Config '" .. ConfigName .. "' đã được lưu!",
        Image = "rbxassetid://4483345998",
        Time = 3
    })
end

local function LoadConfig(ConfigName)
    if ConfigData[ConfigName] then
        local Config = ConfigData[ConfigName]
        _G.EngineConfig.AimbotActive = Config.AimbotActive
        _G.EngineConfig.SilentAimActive = Config.SilentAimActive
        _G.EngineConfig.SmoothActive = Config.SmoothActive
        _G.EngineConfig.SmoothValue = Config.SmoothValue
        _G.EngineConfig.AimFOV = Config.AimFOV
        _G.EngineConfig.DistanceESPActive = Config.DistanceESPActive
        _G.EngineConfig.HealthBarESPActive = Config.HealthBarESPActive
        _G.EngineConfig.BoxESPActive = Config.BoxESPActive
        _G.EngineConfig.NoRecoilActive = Config.NoRecoilActive
        _G.EngineConfig.TeamCheck = Config.TeamCheck
        
        OrionLib:MakeNotification({
            Name = "📂 Config Loaded",
            Content = "Config '" .. ConfigName .. "' đã được tải!",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    else
        OrionLib:MakeNotification({
            Name = "❌ Error",
            Content = "Config '" .. ConfigName .. "' không tồn tại!",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
end

-- =============== AUTO UPDATE ===============
local ScriptVersion = "2.0"
local function CheckForUpdates()
    OrionLib:MakeNotification({
        Name = "🔄 Update Check",
        Content = "Phiên bản hiện tại: " .. ScriptVersion,
        Image = "rbxassetid://4483345998",
        Time = 3
    })
end

-- =============== PANIC BUTTON ===============
local function PanicMode()
    _G.EngineConfig.AimbotActive = false
    _G.EngineConfig.SilentAimActive = false
    _G.EngineConfig.SmoothActive = false
    _G.EngineConfig.ESPActive = false
    _G.EngineConfig.HitboxActive = false
    _G.EngineConfig.WeaponModActive = false
    _G.EngineConfig.AdminDetectionActive = false
    _G.EngineConfig.SpectatorWarningActive = false
    _G.EngineConfig.DistanceESPActive = false
    _G.EngineConfig.HealthBarESPActive = false
    _G.EngineConfig.BoxESPActive = false
    _G.EngineConfig.NameTagESPActive = false
    _G.EngineConfig.BoneESPActive = false
    _G.EngineConfig.PredictionAimActive = false
    _G.EngineConfig.NoRecoilActive = false
    FOVCircle.Visible = false
    
    for _, Draw in pairs(ESPCache) do
        pcall(function() Draw:Remove() end)
    end
    ESPCache = {}
    
    print("⚠️ PANIC MODE ACTIVATED - Tất cả tính năng đã bị tắt!")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        PanicMode()
    end
end)

-- =============== WINDOW & TABS ===============
local Window = OrionLib:MakeWindow({
    Name = "🚀 Full Exploit Sandbox Hub v2.0", 
    HidePremium = true, 
    SaveConfig = false,
    IntroText = "Đang Đồng Bộ Hóa Hệ Thống..."
})

local CombatTab = Window:MakeTab({ Name = "Combat (Chiến Đấu)", Icon = "⚔️" })

CombatTab:AddToggle({
	Name = "Bật Cam-Lock Aimbot (Khóa Camera)",
	Default = false,
	Callback = function(Value) _G.EngineConfig.AimbotActive = Value end
})

CombatTab:AddToggle({
	Name = "Bật Chế Độ Aim Mượt (Smooth Aim)",
	Default = false,
	Callback = function(Value) _G.EngineConfig.SmoothActive = Value end
})

CombatTab:AddSlider({
	Name = "Hệ Số Mượt (Smoothness)",
	Min = 1, Max = 25, Default = 5, Increment = 1,
	Callback = function(Value) _G.EngineConfig.SmoothValue = Value end    
})

CombatTab:AddParagraph("---","---")

CombatTab:AddToggle({
	Name = "Bật Silent Aim (Bẻ Hướng Đạn Vô Hình)",
	Default = false,
	Callback = function(Value) _G.EngineConfig.SilentAimActive = Value end
})

CombatTab:AddToggle({
	Name = "🎯 Prediction Aim (Dự Đoán Vị Trí)",
	Default = false,
	Callback = function(Value) _G.EngineConfig.PredictionAimActive = Value end
})

CombatTab:AddSlider({
	Name = "Phạm Vi Vòng Quét FOV",
	Min = 50, Max = 600, Default = 150, Increment = 10,
	Callback = function(Value) _G.EngineConfig.AimFOV = Value end    
})

CombatTab:AddToggle({
	Name = "Kiểm Tra Đồng Đội (Team Check)",
	Default = true,
	Callback = function(Value) _G.EngineConfig.TeamCheck = Value end
})

local VisualTab = Window:MakeTab({ Name = "Visual & Hitbox", Icon = "👁️" })

VisualTab:AddToggle({
	Name = "Hiển Thị Vị Trí Xuyên Tường (Highlight ESP)",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.ESPActive = Value
        if not Value then
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("EngineESP") then
                    player.Character.EngineESP:Destroy()
                end
            end
        else
            spawn(function()
                while _G.EngineConfig.ESPActive do
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character and not player.Character:FindFirstChild("EngineESP") then
                            if _G.EngineConfig.TeamCheck and player.Team == LocalPlayer.Team then 
                                continue 
                            end
                            
                            local Highlight = Instance.new("Highlight")
                            Highlight.Name = "EngineESP"
                            Highlight.FillColor = Color3.fromRGB(255, 0, 127)
                            Highlight.FillTransparency = 0.4
                            Highlight.Adornee = player.Character
                            Highlight.Parent = player.Character
                        end
                    end
                    task.wait(1.5)
                end
            end)
        end
	end
})

VisualTab:AddToggle({
	Name = "📏 Distance ESP (Khoảng Cách)",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.DistanceESPActive = Value
        if Value then
            CreateDistanceESP()
        end
	end
})

VisualTab:AddToggle({
	Name = "❤️ Health Bar ESP (Thanh Máu)",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.HealthBarESPActive = Value
        if Value then
            CreateHealthBarESP()
        end
	end
})

VisualTab:AddToggle({
	Name = "📦 Box ESP (Khung Quanh)",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.BoxESPActive = Value
        if Value then
            CreateBoxESP()
        end
	end
})

VisualTab:AddToggle({
	Name = "🏷️ Name Tag ESP (Tên Player)",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.NameTagESPActive = Value
        if Value then
            CreateNameTagESP()
        end
	end
})

VisualTab:AddToggle({
	Name = "🦴 Bone ESP (Xương)",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.BoneESPActive = Value
        if Value then
            CreateBoneESP()
        end
	end
})

VisualTab:AddParagraph("---","---")

VisualTab:AddToggle({
	Name = "Kích Hoạt Mở Rộng Hitbox Vô Hình",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.HitboxActive = Value
        spawn(function()
            while _G.EngineConfig.HitboxActive do
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(_G.EngineConfig.HitboxPart) then
                        if _G.EngineConfig.TeamCheck and player.Team == LocalPlayer.Team then 
                            continue 
                        end
                        
                        local Part = player.Character[_G.EngineConfig.HitboxPart]
                        Part.Size = Vector3.new(_G.EngineConfig.HitboxSize, _G.EngineConfig.HitboxSize, _G.EngineConfig.HitboxSize)
                        Part.Transparency = 0.6
                        Part.Color = Color3.fromRGB(255, 255, 0)
                        Part.CanCollide = false
                    end
                end
                task.wait(1)
            end
        end)
	end
})

VisualTab:AddSlider({
	Name = "Độ Rộng Ma Trận Hitbox",
	Min = 2, Max = 25, Default = 2, Increment = 1,
	Callback = function(Value) _G.EngineConfig.HitboxSize = Value end    
})

VisualTab:AddDropdown({
	Name = "Tâm Điểm Áp Dụng Hitbox",
	Default = "HumanoidRootPart",
	Options = {"HumanoidRootPart", "Head", "Torso"},
	Callback = function(Value) _G.EngineConfig.HitboxPart = Value end
})

local UtilityTab = Window:MakeTab({ Name = "Weapon & Player", Icon = "🔫" })

UtilityTab:AddToggle({
	Name = "🔧 No Recoil (Loại Bỏ Giật)",
	Default = false,
	Callback = function(Value) _G.EngineConfig.NoRecoilActive = Value end
})

UtilityTab:AddToggle({
	Name = "Triệt Tiêu Độ Giật & Độ Lệch Tâm Súng",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.WeaponModActive = Value
        spawn(function()
            while _G.EngineConfig.WeaponModActive do
                local Tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if Tool then
                    for _, v in pairs(Tool:GetDescendants()) do
                        if v:IsA("NumberValue") or v:IsA("IntValue") then
                            if v.Name:lower():find("recoil") or v.Name:lower():find("kick") or v.Name:lower():find("spread") then
                                v.Value = 0
                            end
                        end
                    end
                end
                task.wait(1.5)
            end
        end)
	end
})

UtilityTab:AddParagraph("---","---")

UtilityTab:AddSlider({
	Name = "Tốc Độ Di Chuyển (WalkSpeed)",
	Min = 16, Max = 150, Default = 16, Increment = 2,
	Callback = function(Value)
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
	end    
})

UtilityTab:AddSlider({
	Name = "Lực Nhảy (JumpHeight)",
	Min = 7.2, Max = 50, Default = 7.2, Increment = 1,
	Callback = function(Value)
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpHeight = Value
        end
	end    
})

-- =============== ANTI-CHEAT TAB ===============
local AntiCheatTab = Window:MakeTab({ Name = "🚨 Anti-Cheat", Icon = "⚠️" })

AntiCheatTab:AddParagraph("⚡ Panic Button", "Bấm F6 để tắt tất cả tính năng ngay lập tức!")

AntiCheatTab:AddButton({
	Name = "🚨 Kích Hoạt Panic Mode (Tắt Tất Cả)",
	Callback = function()
		PanicMode()
        OrionLib:MakeNotification({
            Name = "Panic Mode",
            Content = "Tất cả tính năng đã bị tắt!",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
	end
})

AntiCheatTab:AddParagraph("---","---")

AntiCheatTab:AddToggle({
	Name = "🔍 Phát Hiện Admin",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.AdminDetectionActive = Value
        if Value then
            spawn(function()
                while _G.EngineConfig.AdminDetectionActive do
                    local Admins = DetectAdmins()
                    if #Admins > 0 then
                        for _, AdminName in pairs(Admins) do
                            OrionLib:MakeNotification({
                                Name = "⚠️ ADMIN ALERT",
                                Content = "Admin phát hiện: " .. AdminName,
                                Image = "rbxassetid://4483345998",
                                Time = 5
                            })
                        end
                    end
                    task.wait(5)
                end
            end)
        end
	end
})

AntiCheatTab:AddToggle({
	Name = "👁️ Cảnh Báo Spectator",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.SpectatorWarningActive = Value
        if Value then
            spawn(function()
                local LastSpectators = {}
                while _G.EngineConfig.SpectatorWarningActive do
                    local Spectators = DetectSpectators()
                    if #Spectators > 0 then
                        for _, SpecName in pairs(Spectators) do
                            if not table.find(LastSpectators, SpecName) then
                                OrionLib:MakeNotification({
                                    Name = "👁️ SPECTATOR WARNING",
                                    Content = "Người xem phát hiện: " .. SpecName,
                                    Image = "rbxassetid://4483345998",
                                    Time = 5
                                })
                            end
                        end
                    end
                    LastSpectators = Spectators
                    task.wait(3)
                end
            end)
        end
	end
})

AntiCheatTab:AddParagraph("---","---")

AntiCheatTab:AddButton({
	Name = "📋 Xem Danh Sách Admin Hiện Tại",
	Callback = function()
		local Admins = DetectAdmins()
        if #Admins == 0 then
            OrionLib:MakeNotification({
                Name = "Admin List",
                Content = "Không có admin nào phát hiện",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        else
            OrionLib:MakeNotification({
                Name = "Admin List",
                Content = "Admins: " .. table.concat(Admins, ", "),
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        end
	end
})

AntiCheatTab:AddButton({
	Name = "👁️ Xem Danh Sách Spectator",
	Callback = function()
		local Spectators = DetectSpectators()
        if #Spectators == 0 then
            OrionLib:MakeNotification({
                Name = "Spectator List",
                Content = "Không có spectator nào",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        else
            OrionLib:MakeNotification({
                Name = "Spectator List",
                Content = "Spectators: " .. table.concat(Spectators, ", "),
                Image = "rbxassetid://4483345998",
                Time = 5
            })
        end
	end
})

-- =============== STATS & INFO TAB ===============
local StatsTab = Window:MakeTab({ Name = "📊 Stats & Info", Icon = "📈" })

StatsTab:AddToggle({
	Name = "📊 FPS Counter",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.FPSCounterActive = Value
        if Value then
            spawn(function()
                while _G.EngineConfig.FPSCounterActive do
                    print("📊 FPS: " .. CurrentFPS .. " | Ping: " .. CurrentPing .. "ms")
                    task.wait(1)
                end
            end)
        end
	end
})

StatsTab:AddToggle({
	Name = "📡 Ping Display",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.PingDisplayActive = Value
        if Value then
            OrionLib:MakeNotification({
                Name = "Ping Monitor",
                Content = "Đang theo dõi ping...",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
	end
})

StatsTab:AddToggle({
	Name = "👥 Player Count",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.PlayerCountActive = Value
        if Value then
            spawn(function()
                while _G.EngineConfig.PlayerCountActive do
                    local PlayerCount = #Players:GetPlayers()
                    print("👥 Players in server: " .. PlayerCount)
                    task.wait(2)
                end
            end)
        end
	end
})

StatsTab:AddToggle({
	Name = "⏱️ Session Timer",
	Default = false,
	Callback = function(Value)
		_G.EngineConfig.SessionTimerActive = Value
        if Value then
            spawn(function()
                while _G.EngineConfig.SessionTimerActive do
                    local ElapsedTime = tick() - SessionStartTime
                    local Minutes = math.floor(ElapsedTime / 60)
                    local Seconds = math.floor(ElapsedTime % 60)
                    print("⏱️ Session Time: " .. Minutes .. "m " .. Seconds .. "s")
                    task.wait(1)
                end
            end)
        end
	end
})

StatsTab:AddParagraph("---","---")

StatsTab:AddButton({
	Name = "📊 Hiển Thị Thông Tin Hiện Tại",
	Callback = function()
		local PlayerCount = #Players:GetPlayers()
        local ElapsedTime = tick() - SessionStartTime
        local Minutes = math.floor(ElapsedTime / 60)
        local Seconds = math.floor(ElapsedTime % 60)
        
        OrionLib:MakeNotification({
            Name = "📊 Server Stats",
            Content = "FPS: " .. CurrentFPS .. " | Ping: " .. CurrentPing .. "ms | Players: " .. PlayerCount .. " | Time: " .. Minutes .. "m " .. Seconds .. "s",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
	end
})

StatsTab:AddButton({
	Name = "🎮 Local Player Info",
	Callback = function()
		local PlayerName = LocalPlayer.Name
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        local Health = Humanoid and Humanoid.Health or 0
        local MaxHealth = Humanoid and Humanoid.MaxHealth or 0
        
        OrionLib:MakeNotification({
            Name = "🎮 Player Info",
            Content = "Name: " .. PlayerName .. " | Health: " .. math.floor(Health) .. "/" .. math.floor(MaxHealth),
            Image = "rbxassetid://4483345998",
            Time = 5
        })
	end
})

-- =============== CONFIG & UPDATES TAB ===============
local ConfigTab = Window:MakeTab({ Name = "💾 Config & Updates", Icon = "⚙️" })

ConfigTab:AddParagraph("Save Config", "Lưu các cấu hình của bạn để sử dụng sau")

ConfigTab:AddTextbox({
	Name = "Tên Config",
	Default = "MyConfig",
	TextDisappear = false,
	Callback = function(Value)
		_G.ConfigName = Value
	end	
})

ConfigTab:AddButton({
	Name = "💾 Lưu Config",
	Callback = function()
		if _G.ConfigName and _G.ConfigName ~= "" then
			SaveConfig(_G.ConfigName)
		end
	end
})

ConfigTab:AddParagraph("---","---")

ConfigTab:AddButton({
	Name = "📂 Tải Config",
	Callback = function()
		if _G.ConfigName and _G.ConfigName ~= "" then
			LoadConfig(_G.ConfigName)
		end
	end
})

ConfigTab:AddParagraph("---","---")

ConfigTab:AddButton({
	Name = "📋 Danh Sách Config",
	Callback = function()
		local ConfigList = ""
		for Name, _ in pairs(ConfigData) do
			ConfigList = ConfigList .. Name .. " | "
		end
		
		if ConfigList == "" then
			ConfigList = "Không có config nào"
		end
		
		OrionLib:MakeNotification({
			Name = "Config List",
			Content = ConfigList,
			Image = "rbxassetid://4483345998",
			Time = 5
		})
	end
})

ConfigTab:AddParagraph("---","---")

ConfigTab:AddButton({
	Name = "🔄 Kiểm Tra Cập Nhật",
	Callback = function()
		CheckForUpdates()
	end
})

ConfigTab:AddButton({
	Name = "📊 Xem K/D Stats",
	Callback = function()
		DisplayKDStats()
	end
})

OrionLib:Init()
