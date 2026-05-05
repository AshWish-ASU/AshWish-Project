-- [[ LEVEL MASTERS SCRIPT | V1.00 ]]
-- BRANDING: BY: ASH

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local LogService = game:GetService("LogService")
local localPlayer = Players.LocalPlayer

local mFloor = math.floor
local isPC = UserInputService.KeyboardEnabled

-- ==========================================
-- VARIABLES & TRACKING
-- ==========================================
local sessionStartTime = os.time()
local isFarming = false
local autoFarmStartTime = 0
local startLevel = 0
local lastTrackedLevel = 0
local sessionLevelsGained = 0
local sessionFarmingSeconds = 0
local Toggles = {AutoFarmAll = false, AutoReconnect = false, AntiAFK = false, EspToggle = false, RainbowEsp = false}

-- Discord Configuration
local DiscordPingIDs = "<@1020630748807577683> <@1453603930209648670>"
local UserWebhookURL = "https://discord.com/api/webhooks/1499550784424251453/C5rL13FC4L79uwCR4NmpO5P0KHF6toKGyYBxnzhrdBe9P3t_mGdq-z0SB5Qvz5aICh5h"

-- Dummy Target Locations
local DummyLocations = {
    Vector3.new(-594.7495727539062, -157.31495666503906, 879.1777954101562),
    Vector3.new(-627.1295166015625, -157.2369842529297, 910.9793090820312),
    Vector3.new(-640.8036499023438, -156.70159912109375, 897.5853881835938),
    Vector3.new(-622.4554443359375, -157.4154052734375, 786.8030395507812),
    Vector3.new(-612.2915649414062, -155.93222045898438, 766.2567749023438),
    Vector3.new(-639.3341674804688, -157.77249145507812, 769.9412841796875)
}
local ActiveDummyTarget = nil

-- Cached Remotes & Folders for Extreme Optimization
local hitRemote = ReplicatedStorage:WaitForChild("Events", 5) and ReplicatedStorage.Events:WaitForChild("Hit", 5)
local fbStorage = ReplicatedStorage:FindFirstChild("FireballReplicatedStorage")
local fbRemote = fbStorage and fbStorage:FindFirstChild("RemoteEvent")
local sbRemote = fbStorage and fbStorage:FindFirstChild("RemoteEvent1")

local mapFolder = workspace:WaitForChild("Map", 5)
local dummysFolder = mapFolder and mapFolder:WaitForChild("dummys", 5)

-- Analytics Data Save
local trackerFileName = "LM_LevelAnalytics.json"
local trackerData = {FarmingSeconds = 0, LevelsGained = 0, Logs = {}, TotalExecutions = 0, LifetimeFarmingSeconds = 0}
pcall(function()
    if isfile and readfile and isfile(trackerFileName) then
        local savedData = HttpService:JSONDecode(readfile(trackerFileName))
        if savedData then
            for k, v in pairs(savedData) do trackerData[k] = v end
        end
    end
end)

local function SaveTrackerData() 
    pcall(function() if writefile then writefile(trackerFileName, HttpService:JSONEncode(trackerData)) end end) 
end

-- Update execution count
trackerData.TotalExecutions = trackerData.TotalExecutions + 1
SaveTrackerData()

local function GetHistoricalAverage()
    if #trackerData.Logs == 0 then return 0 end
    local sum = 0
    local validLogs = 0
    -- Only average the last 5 logs that had actual meaningful farming time (to prevent 2-minute test sessions from ruining the math)
    for i = 1, math.min(#trackerData.Logs, 5) do 
        local logVal = tonumber(trackerData.Logs[i]) or 0
        if logVal > 500 then -- Assuming 500 is a baseline for a real session
            sum = sum + logVal
            validLogs = validLogs + 1
        end
    end
    if validLogs == 0 then return 0 end
    return sum / validLogs
end

-- ==========================================
-- AUTO-RESUME LOGIC
-- ==========================================
local shouldResumeFarm = false
pcall(function()
    if isfile and readfile and isfile("LM_HopState.txt") then
        local state = readfile("LM_HopState.txt")
        if state and string.find(state, "resume_farm") then
            shouldResumeFarm = true
            if writefile then writefile("LM_HopState.txt", "idle") end 
        end
    end
end)

local function WriteHopState() 
    pcall(function() if writefile then writefile("LM_HopState.txt", "resume_farm") end end) 
end

-- ==========================================
-- OPTIMIZED UTILITY FUNCTIONS
-- ==========================================
local function OptimizeFPS()
    pcall(function()
        settings().Rendering.QualityLevel = 1
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 9e9
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then v:Destroy() end
        end
    end)
end

local function FormatNum(value)
    local n = mFloor(tonumber(value) or 0)
    local formatted = tostring(n)
    local k
    while true do formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2"); if k==0 then break end end
    return formatted
end

local function FormatSessionTime(seconds)
    local d = mFloor(seconds / 86400); seconds = seconds % 86400
    local h = mFloor(seconds / 3600); seconds = seconds % 3600
    local m = mFloor(seconds / 60); local s = seconds % 60
    return string.format("%02d:%02d:%02d:%02d", d, h, m, s)
end

local function FormatLifetime(secs)
    local y = mFloor(secs / 31536000); secs = secs % 31536000
    local mo = mFloor(secs / 2592000); secs = secs % 2592000
    local w = mFloor(secs / 604800); secs = secs % 604800
    local d = mFloor(secs / 86400); secs = secs % 86400
    local h = mFloor(secs / 3600); secs = secs % 3600
    local m = mFloor(secs / 60); local s = secs % 60
    return string.format("%02d:%02d:%02d:%02d:%02d:%02d:%02d", y, mo, w, d, h, m, s)
end

local function getLevel() 
    local lvl = 0 
    pcall(function() lvl = localPlayer.leaderstats.Level.Value end) 
    return lvl 
end

local function GetAndEquipMagicTool(allowSnowball)
    local char = localPlayer.Character
    local bp = localPlayer:FindFirstChild("Backpack")
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not bp or not hum then return nil end

    local fireballTool, snowballTool = nil, nil

    local function scanFolder(folder)
        for _, item in pairs(folder:GetChildren()) do
            if item:IsA("Tool") then
                local n = string.lower(item.Name)
                if string.find(n, "fireball") then fireballTool = item end
                if string.find(n, "snowball") then snowballTool = item end
            end
        end
    end

    scanFolder(char)
    if not fireballTool then scanFolder(bp) end

    local toolToUse = fireballTool or (allowSnowball and snowballTool)

    if toolToUse and toolToUse.Parent == bp then
        hum:EquipTool(toolToUse)
    end

    if toolToUse then
        if string.find(string.lower(toolToUse.Name), "fireball") then return "Fireball" end
        return "Snowball"
    end
    return nil
end

local function GetClosestDummy()
    if not dummysFolder then return nil end
    local closestDummy = nil
    local shortestDist = 50000 
    local myHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if myHrp then
        local myPos = myHrp.Position
        for _, dummy in ipairs(dummysFolder:GetChildren()) do
            local hrp = dummy:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - myPos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestDummy = dummy
                end
            end
        end
    end
    return closestDummy
end

-- ==========================================
-- DISCORD WEBHOOK ENGINE
-- ==========================================
local function SendWebhookPing(title, desc, color, pingUsers, reportType)
    if UserWebhookURL == "" then return end
    
    local platformStr = isPC and "PC Desktop" or "Mobile Device"
    local lph = sessionFarmingSeconds > 0 and ((sessionLevelsGained / sessionFarmingSeconds) * 3600) or 0
    local tStr = string.format("%02d:%02d:%02d", mFloor(sessionFarmingSeconds / 3600), mFloor((sessionFarmingSeconds % 3600) / 60), sessionFarmingSeconds % 60)

    local payload = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = desc,
            ["color"] = color,
            ["fields"] = {
                {["name"] = "Account", ["value"] = localPlayer.Name, ["inline"] = true},
                {["name"] = "Platform", ["value"] = platformStr, ["inline"] = true}
            }
        }}
    }
    
    local fields = payload.embeds[1].fields

    if reportType == "Execution" then
        table.insert(fields, {["name"] = "Total Executions", ["value"] = tostring(trackerData.TotalExecutions), ["inline"] = true})
        table.insert(fields, {["name"] = "Lifetime Farmed", ["value"] = FormatLifetime(trackerData.LifetimeFarmingSeconds), ["inline"] = true})
    elseif reportType == "Periodic" or reportType == "Daily" or reportType == "Disconnect" or reportType == "Rejoin" then
        table.insert(fields, {["name"] = "Time Farmed Session", ["value"] = tStr, ["inline"] = true})
        table.insert(fields, {["name"] = "Current LPH", ["value"] = string.format("%.1f", lph), ["inline"] = true})
        
        local currentGain = trackerData.LevelsGained
        local histAvg = GetHistoricalAverage()
        local rating = "Average"
        
        -- Smarter rating logic
        if histAvg > 0 then
            if currentGain > (histAvg * 1.1) then rating = "Above Average"
            elseif currentGain < (histAvg * 0.9) then rating = "Below Average"
            end
        else
            rating = "Establishing Baseline..."
        end

        table.insert(fields, {["name"] = "Current Rating", ["value"] = rating, ["inline"] = true})

        if reportType == "Daily" then
            table.insert(fields, {["name"] = "24 Hour Gain", ["value"] = tostring(currentGain), ["inline"] = true})
        end
    end

    if pingUsers then payload["content"] = DiscordPingIDs .. " **SYSTEM ALERT**" end

    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if httprequest then
        pcall(function()
            httprequest({
                Url = UserWebhookURL, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end
end

task.spawn(function()
    task.wait(2)
    SendWebhookPing("🚀 SCRIPT EXECUTED", "Level Masters Script has been successfully Executed.", tonumber(0x8A2BE2), false, "Execution")
end)

task.spawn(function()
    while task.wait(1) do
        -- Check every second, but only fire when perfectly aligned to 10 minutes
        if sessionFarmingSeconds > 0 and sessionFarmingSeconds % 600 == 0 then
             if Toggles.AutoFarmAll then
                 SendWebhookPing("⏱️ 10 MINUTE STATUS UPDATE", "Periodic progress report for the current session.", tonumber(0x00A2FF), false, "Periodic")
             end
        end
    end
end)

-- ==========================================
-- UI WINDOW SETUP
-- ==========================================
local Window = Rayfield:CreateWindow({
    Name = "Level Masters Script | v1.00", 
    LoadingTitle = "Level Masters Loading", 
    LoadingSubtitle = "By: Ash", 
    ConfigurationSaving = {Enabled=false}, 
    KeySystem = false
})

local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)
local AnalyticsTab = Window:CreateTab("Level Analytics", 4483362458)
local SecurityTab = Window:CreateTab("Security", 4483362458)
local PlayerTab = Window:CreateTab("Player Settings", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- ==========================================
-- TAB 1: AUTO FARM
-- ==========================================
AutoFarmTab:CreateSection("Combat Farm")

local lastMeleeHit = 0
local nextMagicCheck = 0
local cachedMagicType = nil
local customHitSpeed = 0.5 

local FarmToggleObj = AutoFarmTab:CreateToggle({
    Name = "Auto Farm All",
    CurrentValue = false,
    Flag = "AutoFarmAll",
    Callback = function(Value)
        Toggles.AutoFarmAll = Value
        isFarming = Value
        if Value then autoFarmStartTime = os.clock() end
        
        if Value then
            task.spawn(function()
                while Toggles.AutoFarmAll do
                    local now = os.clock()
                    
                    if now >= nextMagicCheck then
                        local allowSnowball = (now - autoFarmStartTime) >= 6
                        cachedMagicType = GetAndEquipMagicTool(allowSnowball)
                        nextMagicCheck = now + 1
                    end
                    
                    if not ActiveDummyTarget then
                        ActiveDummyTarget = DummyLocations[math.random(1, #DummyLocations)]
                    end
                    
                    if now - lastMeleeHit >= customHitSpeed then
                        local closestDummy = GetClosestDummy()
                        if closestDummy then
                            local dummyHum = closestDummy:FindFirstChild("Humanoid")
                            if dummyHum and hitRemote then 
                                hitRemote:FireServer(dummyHum) 
                            end
                        end
                        lastMeleeHit = now
                    end
                    
                    if cachedMagicType == "Fireball" and fbRemote then
                        fbRemote:FireServer(ActiveDummyTarget)
                    elseif cachedMagicType == "Snowball" and sbRemote then
                        sbRemote:FireServer(ActiveDummyTarget)
                    end
                    
                    RunService.Heartbeat:Wait() 
                end
            end)
        end
    end,
})

local HitSpeedSliderObj = AutoFarmTab:CreateSlider({
    Name = "Melee Hit Cooldown",
    Range = {0.1, 1.0},
    Increment = 0.05,
    Suffix = "Seconds",
    CurrentValue = 0.5,
    Flag = "HitSpeedSlider",
    Callback = function(Value)
        customHitSpeed = Value
    end,
})

AutoFarmTab:CreateButton({
    Name = "Set Fastest Hit Speed",
    Callback = function()
        customHitSpeed = 0.1
        if HitSpeedSliderObj then
            HitSpeedSliderObj:Set(0.1)
        end
    end
})

AutoFarmTab:CreateButton({
    Name = "Reset Normal Hit Speed",
    Callback = function()
        customHitSpeed = 0.5
        if HitSpeedSliderObj then
            HitSpeedSliderObj:Set(0.5)
        end
    end
})

AutoFarmTab:CreateSection("Movement")

local TeleportToggleObj
TeleportToggleObj = AutoFarmTab:CreateToggle({
    Name = "Teleport To Dummy",
    CurrentValue = false,
    Flag = "AutoTeleport",
    Callback = function(Value)
        if Value then
            if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                ActiveDummyTarget = DummyLocations[math.random(1, #DummyLocations)]
                localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(ActiveDummyTarget) * CFrame.new(0, 0, 4)
            end
            task.spawn(function()
                task.wait(0.5)
                TeleportToggleObj:Set(false)
            end)
        end
    end,
})

-- ==========================================
-- TAB 2: LEVEL ANALYTICS
-- ==========================================
AnalyticsTab:CreateSection("Session Progress")
local SessionStatsPara = AnalyticsTab:CreateParagraph({Title = "Live Tracking", Content = "Waiting to start..."})

AnalyticsTab:CreateSection("Future Projections")
local ProjPara = AnalyticsTab:CreateParagraph({Title = "Level Estimations", Content = "Waiting to start..."})

-- ==========================================
-- BLACK STAT TRACKER UI
-- ==========================================
if CoreGui:FindFirstChild("LM_StatTracker") then CoreGui.LM_StatTracker:Destroy() end
local trackerGui = Instance.new("ScreenGui")
trackerGui.Name = "LM_StatTracker"
trackerGui.IgnoreGuiInset = true
trackerGui.Parent = CoreGui

local trackerFrame = Instance.new("Frame")
trackerFrame.Size = UDim2.new(0, 280, 0, 115)
trackerFrame.Position = UDim2.new(1, -290, 0, 10)
trackerFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
trackerFrame.BorderSizePixel = 0
trackerFrame.Active = true
trackerFrame.Draggable = true
trackerFrame.Parent = trackerGui

local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = trackerFrame
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(80, 80, 80); stroke.Thickness = 2; stroke.Parent = trackerFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, 0, 1, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.TextSize = 13
statsLabel.Font = Enum.Font.GothamMedium
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Text = "Status: IDLE\n\nWaiting to start"
statsLabel.Parent = trackerFrame

local padding = Instance.new("UIPadding"); padding.PaddingLeft = UDim.new(0, 10); padding.PaddingTop = UDim.new(0, 10); padding.Parent = statsLabel

task.spawn(function()
    while task.wait(1) do
        local currentLvl = getLevel()
        local tStr = FormatSessionTime(os.time() - sessionStartTime)
        
        if isFarming then
            if lastTrackedLevel == 0 or currentLvl < lastTrackedLevel then lastTrackedLevel = currentLvl end
            local diff = currentLvl - lastTrackedLevel
            if diff > 0 then 
                sessionLevelsGained = sessionLevelsGained + diff
                trackerData.LevelsGained = trackerData.LevelsGained + diff
            end
            
            lastTrackedLevel = currentLvl
            sessionFarmingSeconds = sessionFarmingSeconds + 1
            trackerData.FarmingSeconds = trackerData.FarmingSeconds + 1
            trackerData.LifetimeFarmingSeconds = trackerData.LifetimeFarmingSeconds + 1

            if trackerData.FarmingSeconds >= 86400 then
                SendWebhookPing("📅 24 HOUR FARM REPORT", "A full 24 hours of grinding has been completed.", tonumber(0x00FFFF), true, "Daily")
                table.insert(trackerData.Logs, 1, trackerData.LevelsGained)
                if #trackerData.Logs > 10 then table.remove(trackerData.Logs, 11) end
                trackerData.FarmingSeconds = 0
                trackerData.LevelsGained = 0
            end

            if trackerData.FarmingSeconds % 60 == 0 then SaveTrackerData() end

            local currentLvlPerSec = sessionFarmingSeconds > 0 and (sessionLevelsGained / sessionFarmingSeconds) or 0
            local lpm = currentLvlPerSec * 60
            local lph = currentLvlPerSec * 3600
            
            statsLabel.Text = string.format("Status: ACTIVE\n\nTime Farmed This Session: %s\nLevels Gained: %s\nLPM: %.1f\nLPH: %.1f", tStr, FormatNum(sessionLevelsGained), lpm, lph)
            SessionStatsPara:Set({Title = "Live Tracking", Content = string.format("Time Farmed: %s\nLevels Gained: %s\nLPM: %.1f\nLPH: %.1f", tStr, FormatNum(sessionLevelsGained), lpm, lph)})
            ProjPara:Set({Title = "Future Projections", Content = string.format("1 Day Gain: %s\n3 Days Gain: %s\n1 Week Gain: %s\n1 Month Gain: %s", FormatNum(lph * 24), FormatNum(lph * 72), FormatNum(lph * 168), FormatNum(lph * 720))})
        else
            statsLabel.Text = string.format("Status: IDLE\n\nTime Farmed This Session: %s\nLevels Gained: %s\nLPM: 0.0\nLPH: 0.0", tStr, FormatNum(sessionLevelsGained))
        end
    end
end)

-- ==========================================
-- TAB 3: SECURITY
-- ==========================================
SecurityTab:CreateSection("Connection Protections")

local ReconToggleObj = SecurityTab:CreateToggle({Name = "Auto Reconnect Server", CurrentValue = false, Flag = "Recon", Callback = function(Value) Toggles.AutoReconnect = Value end})
local AAFKToggleObj = SecurityTab:CreateToggle({Name = "Anti AFK", CurrentValue = false, Flag = "AAFK", Callback = function(Value) Toggles.AntiAFK = Value end})

SecurityTab:CreateSection("Performance Optimization")
SecurityTab:CreateButton({
    Name = "Activate FPS Booster",
    Callback = function()
        OptimizeFPS()
    end
})

localPlayer.Idled:Connect(function() if Toggles.AntiAFK then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end end)

task.spawn(function()
    local reconnecting = false
    local function forceRejoin() 
        if reconnecting then return end
        reconnecting = true
        SendWebhookPing("🚨 DISCONNECT DETECTED", "Account lost connection. Attempting to rejoin.", tonumber(0xFFA500), true, "Disconnect")
        WriteHopState()
        task.spawn(function() while task.wait(1) do pcall(function() TeleportService:Teleport(game.PlaceId, localPlayer) end) end end) 
    end
    pcall(function() GuiService.ErrorMessageChanged:Connect(function() if Toggles.AutoReconnect then local err = GuiService:GetErrorCode(); if err and err.Value ~= 0 then forceRejoin() end end end) end)
    pcall(function() CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child) if Toggles.AutoReconnect and child.Name == "ErrorPrompt" then forceRejoin() end end) end)
    pcall(function() LogService.MessageOut:Connect(function(Message, Type) if Toggles.AutoReconnect and Type == Enum.MessageType.MessageError then local lMsg = string.lower(Message); if string.find(lMsg, "disconnect") or string.find(lMsg, "kicked") then forceRejoin() end end end) end)
end)

-- ==========================================
-- TAB 4: PLAYER SETTINGS
-- ==========================================
PlayerTab:CreateSection("Movement Modifications")

local customWalkSpeed = 16
local customJumpPower = 50
local enforceMovement = false
local isResetting = false

local wsSlider = PlayerTab:CreateSlider({Name = "Walkspeed", Range = {1, 500}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Flag = "WalkspeedSlider", Callback = function(Value) customWalkSpeed = Value; if not isResetting then enforceMovement = true end end})
local jpSlider = PlayerTab:CreateSlider({Name = "Jump Power", Range = {1, 500}, Increment = 1, Suffix = "Power", CurrentValue = 50, Flag = "JumpPowerSlider", Callback = function(Value) customJumpPower = Value; if not isResetting then enforceMovement = true end end})

PlayerTab:CreateButton({
    Name = "Reset Speed and Jump Power",
    Callback = function()
        isResetting = true
        enforceMovement = false
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then 
            local hum = localPlayer.Character.Humanoid
            hum.WalkSpeed = 16; hum.UseJumpPower = false; hum.JumpPower = 50 
        end
        task.spawn(function() wsSlider:Set(16); jpSlider:Set(50); task.wait(0.1); isResetting = false end)
    end
})

task.spawn(function() 
    while task.wait(0.1) do 
        if enforceMovement and localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then 
            local hum = localPlayer.Character.Humanoid
            hum.WalkSpeed = customWalkSpeed; hum.UseJumpPower = true; hum.JumpPower = customJumpPower 
        end 
    end 
end)

-- ==========================================
-- TAB 5: ESP 
-- ==========================================
ESPTab:CreateSection("Player Visuals")

local espThread = nil
local espObjects = {}
local sharedVisualColor = Color3.fromRGB(255, 50, 50)

local function ClearEsp() 
    for _, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end
    espObjects = {} 
end

ESPTab:CreateToggle({
    Name = "Enable Player ESP",
    CurrentValue = false,
    Flag = "EspToggle",
    Callback = function(Value)
        Toggles.EspToggle = Value
        if Value then
            espThread = task.spawn(function()
                while Toggles.EspToggle do
                    ClearEsp()
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") then
                            local char = plr.Character
                            local hum = char.Humanoid
                            
                            local hl = char:FindFirstChild("ESP_Highlight")
                            if not hl then
                                hl = Instance.new("Highlight", char)
                                hl.Name = "ESP_Highlight"
                                hl.FillTransparency = 0.5
                                table.insert(espObjects, hl)
                            end
                            hl.FillColor = sharedVisualColor
                            hl.OutlineColor = sharedVisualColor
                            
                            local bgui = char.Head:FindFirstChild("ESP_UI")
                            local txt
                            if not bgui then
                                bgui = Instance.new("BillboardGui", char.Head)
                                bgui.Name = "ESP_UI"
                                bgui.Size = UDim2.new(0, 150, 0, 50)
                                bgui.StudsOffset = Vector3.new(0, 3, 0)
                                bgui.AlwaysOnTop = true
                                
                                txt = Instance.new("TextLabel", bgui)
                                txt.Name = "ESP_Text"
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.BackgroundTransparency = 1
                                txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                                txt.TextSize = 13
                                txt.Font = Enum.Font.GothamBold
                                table.insert(espObjects, bgui)
                            else
                                txt = bgui.ESP_Text
                            end
                            
                            local hp = mFloor(hum.Health)
                            local maxHp = mFloor(hum.MaxHealth)
                            local pLevel = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Level") and plr.leaderstats.Level.Value or 0
                            txt.Text = string.format("%s\nLevel: %s\n%s / %s", plr.Name, FormatNum(pLevel), FormatNum(hp), FormatNum(maxHp))
                        end
                    end
                    task.wait(0.5) 
                end
            end)
        else 
            ClearEsp() 
        end
    end
})

ESPTab:CreateToggle({Name = "Rainbow ESP Colors", CurrentValue = false, Flag = "RainbowEsp", Callback = function(Value) Toggles.RainbowEsp = Value end})

RunService.RenderStepped:Connect(function() 
    if Toggles.RainbowEsp then sharedVisualColor = Color3.fromHSV(os.clock() % 4 / 4, 1, 1) else sharedVisualColor = Color3.fromRGB(255, 50, 50) end 
end)

-- ==========================================
-- TAB 6: MISC
-- ==========================================
MiscTab:CreateSection("Utility Actions")
MiscTab:CreateButton({Name = "Open / Close UI Tracker", Callback = function() if trackerGui then trackerGui.Enabled = not trackerGui.Enabled end end})
MiscTab:CreateButton({Name = "Execute Infinite Yield", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Infinite-yield-73483"))() end})
MiscTab:CreateButton({Name = "Destroy Script and UI", Callback = function() isFarming = false; Toggles = {}; ClearEsp(); if trackerGui then trackerGui:Destroy() end; Rayfield:Destroy() end})

-- ==========================================
-- AUTO RESUME EXECUTION
-- ==========================================
if shouldResumeFarm then
    task.spawn(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        char:WaitForChild("HumanoidRootPart", 9e9)
        
        task.wait(7) 
        
        -- Engage Auto-Resume Protections
        OptimizeFPS()
        
        -- Explicitly lock speed to safe defaults so it doesn't instantly flag upon rejoin
        customHitSpeed = 0.5
        if HitSpeedSliderObj then HitSpeedSliderObj:Set(0.5) end
        
        pcall(function() if FarmToggleObj then FarmToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if TeleportToggleObj then TeleportToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if ReconToggleObj then ReconToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if AAFKToggleObj then AAFKToggleObj:Set(true) end end)
        
        SendWebhookPing("🔄 REJOIN SUCCESSFUL", "Account has fully reconnected and resumed farming after the 7s delay.", tonumber(0x00FF00), false, "Rejoin")
        
        -- Auto Hide UI
        if Window and Window.Hide then Window:Hide() end
    end)
end
