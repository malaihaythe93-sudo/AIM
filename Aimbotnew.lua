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
    SessionTimerActive = false
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

-- FPS Counter
RunService.RenderStepped:Connect(function()
    CurrentFPS = math.floor(1 / RunService.RenderStepped:Wait())
end)

-- Ping Detection
spawn(function()
    while true do
        local Start = tick()
        game:HttpGet("https://google.com")
        CurrentPing = math.floor((tick() - Start) * 1000)
        task.wait(5)
    end
end)

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
            -- Kiểm tra nếu là admin (thường có tag hoặc username đặc biệt)
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
    _G.EngineConfig.FPSCounterActive = false
    _G.EngineConfig.PingDisplayActive = false
    _G.EngineConfig.PlayerCountActive = false
    _G.EngineConfig.SessionTimerActive = false
    FOVCircle.Visible = false
    print("⚠️ PANIC MODE ACTIVATED - Tất cả tính năng đã bị tắt!")
end

-- Hotkey Panic Button (Default: F6)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        PanicMode()
    end
end)

-- =============== WINDOW & TABS ===============
local Window = OrionLib:MakeWindow({
    Name = "🚀 Full Exploit Sandbox Hub", 
    HidePremium = true, 
    SaveConfig = false,
    IntroText = "Đang Đồng Bộ Hóa Hệ Thống..."
})

local CombatTab = Window:MakeTab({ Name = "Combat (Chiến Đấu)", Icon = "" })

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

local VisualTab = Window:MakeTab({ Name = "Visual & Hitbox", Icon = "" })

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

local UtilityTab = Window:MakeTab({ Name = "Weapon & Player", Icon = "" })

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

OrionLib:Init()
