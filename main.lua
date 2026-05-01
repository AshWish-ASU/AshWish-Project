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
    if #trackerData.Logs == 0 then return 1000 end
    local sum = 0
    local count = math.min(#trackerData.Logs, 5)
    for i = 1, count do sum = sum + (tonumber(trackerData.Logs[i]) or 0) end
    return sum / count
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

local function GetMagicTool()
    local hasFireball = false
    local hasSnowball = false

    local char = localPlayer.Character
    local bp = localPlayer:FindFirstChild("Backpack")

    if char then
        for _, item in pairs(char:GetChildren()) do
            if item:IsA("Tool") then
                local n = string.lower(item.Name)
                if string.find(n, "fireball") then hasFireball = true end
                if string.find(n, "snowball") then hasSnowball = true end
            end
        end
    end
    
    if bp and not hasFireball then
        for _, item in pairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local n = string.lower(item.Name)
                if string.find(n, "fireball") then hasFireball = true end
                if string.find(n, "snowball") then hasSnowball = true end
            end
        end
    end

    if hasFireball then return "Fireball" end
    if hasSnowball then return "Snowball" end
    return nil
end

local function GetClosestDummy()
    local closestDummy = nil
    local shortestDist = math.huge
    local char = localPlayer.Character
    local myPos = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position
    
    local mapFolder = workspace:FindFirstChild("Map")
    local dummysFolder = mapFolder and mapFolder:FindFirstChild("dummys")

    if myPos and dummysFolder then
        for _, dummy in pairs(dummysFolder:GetChildren()) do
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
local function SendWebhookPing(title, desc, color, pingUsers, isDailyReport, isExecution)
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

    if isExecution then
        table.insert(payload.embeds[1].fields, {["name"] = "Total Executions", ["value"] = tostring(trackerData.TotalExecutions), ["inline"] = true})
        table.insert(payload.embeds[1].fields, {["name"] = "Lifetime Farmed", ["value"] = FormatLifetime(trackerData.LifetimeFarmingSeconds), ["inline"] = true})
    else
        table.insert(payload.embeds[1].fields, {["name"] = "Time Farmed Session", ["value"] = tStr, ["inline"] = true})
        table.insert(payload.embeds[1].fields, {["name"] = "Current LPH", ["value"] = string.format("%.1f", lph), ["inline"] = true})
    end

    if isDailyReport then
        local dailyGain = trackerData.LevelsGained
        local histAvg = GetHistoricalAverage()
        local rating = "Average"
        
        if dailyGain > (histAvg * 1.1) then rating = "Above Average"
        elseif dailyGain < (histAvg * 0.9) then rating = "Below Average"
        end

        table.insert(payload.embeds[1].fields, {["name"] = "24 Hour Gain", ["value"] = tostring(dailyGain), ["inline"] = true})
        table.insert(payload.embeds[1].fields, {["name"] = "Daily Rating", ["value"] = rating, ["inline"] = true})
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

-- FIRE INITIAL EXECUTION WEBHOOK
task.spawn(function()
    task.wait(2)
    SendWebhookPing("🚀 SCRIPT EXECUTED", "Level Masters Script has been successfully Executed.", tonumber(0x8A2BE2), false, false, true)
end)

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
                SendWebhookPing("📅 24 HOUR FARM REPORT", "A full 24 hours of grinding has been completed", tonumber(0x00FFFF), true, true, false)
                table.insert(trackerData.Logs, 1, trackerData.LevelsGained)
                if #trackerData.Logs > 10 then table.remove(trackerData.Logs, 11) end
                trackerData.FarmingSeconds = 0
                trackerData.LevelsGained = 0
            end

            if trackerData.FarmingSeconds % 60 == 0 then SaveTrackerData() end

            local currentLvlPerSec = sessionFarmingSeconds > 0 and (sessionLevelsGained / sessionFarmingSeconds) or 0
            local lpm = currentLvlPerSec * 60
            local lph = currentLvlPerSec * 3600
            
            statsLabel.Text = string.format("Status: ACTIVE\n\nTime Farmed This Session: %s\nLevels Gained: %s\nLPM: %.1f\nLPH: %.1f", 
                tStr, FormatNum(sessionLevelsGained), lpm, lph)
        else
            statsLabel.Text = string.format("Status: IDLE\n\nTime Farmed This Session: %s\nLevels Gained: %s\nLPM: 0.0\nLPH: 0.0", 
                tStr, FormatNum(sessionLevelsGained))
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

-- TABS
local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)
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

local FarmToggleObj = AutoFarmTab:CreateToggle({
    Name = "Auto Farm All",
    CurrentValue = false,
    Flag = "AutoFarmAll",
    Callback = function(Value)
        Toggles.AutoFarmAll = Value
        isFarming = Value
        
        if Value then
            task.spawn(function()
                task.wait(1) 
                while Toggles.AutoFarmAll do
                    pcall(function()
                        local now = os.clock()
                        
                        -- Caching Engine: Only checks inventory once every 2 seconds
                        if now >= nextMagicCheck then
                            cachedMagicType = GetMagicTool()
                            nextMagicCheck = now + 2
                        end
                        
                        -- 1. Auto Hit (0.4s cooldown enforced)
                        if now - lastMeleeHit >= 0.4 then
                            local closestDummy = GetClosestDummy()
                            if closestDummy then
                                local dummyHum = closestDummy:FindFirstChild("Humanoid")
                                if dummyHum then ReplicatedStorage.Events.Hit:FireServer(dummyHum) end
                            end
                            lastMeleeHit = now
                        end
                        
                        -- 2. Auto Magic (Targeted Projectiles)
                        if not ActiveDummyTarget then
                            ActiveDummyTarget = DummyLocations[math.random(1, #DummyLocations)]
                        end
                        
                        if cachedMagicType == "Fireball" and ReplicatedStorage:FindFirstChild("FireballReplicatedStorage") then
                            ReplicatedStorage.FireballReplicatedStorage.RemoteEvent:FireServer(ActiveDummyTarget)
                        elseif cachedMagicType == "Snowball" and ReplicatedStorage:FindFirstChild("SnowballReplicatedStorage") then
                            ReplicatedStorage.SnowballReplicatedStorage.RemoteEvent:FireServer(ActiveDummyTarget)
                        end
                    end)
                    task.wait(0.05) 
                end
            end)
        end
    end,
})

AutoFarmTab:CreateSection("Movement")

local TeleportToggleObj
TeleportToggleObj = AutoFarmTab:CreateToggle({
    Name = "Teleport To Dummy",
    CurrentValue = false,
    Flag = "AutoTeleport",
    Callback = function(Value)
        if Value then
            pcall(function()
                if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    ActiveDummyTarget = DummyLocations[math.random(1, #DummyLocations)]
                    localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(ActiveDummyTarget) * CFrame.new(0, 0, 4)
                end
            end)
            task.spawn(function()
                task.wait(0.5)
                TeleportToggleObj:Set(false)
            end)
        end
    end,
})

-- ==========================================
-- TAB 2: SECURITY
-- ==========================================
SecurityTab:CreateSection("Connection Protections")

local ReconToggleObj = SecurityTab:CreateToggle({
    Name = "Auto Reconnect Server",
    CurrentValue = false,
    Flag = "Recon",
    Callback = function(Value) Toggles.AutoReconnect = Value end
})

local AAFKToggleObj = SecurityTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AAFK",
    Callback = function(Value) Toggles.AntiAFK = Value end
})

SecurityTab:CreateSection("Performance Optimization")

SecurityTab:CreateButton({
    Name = "Activate FPS Booster",
    Callback = function()
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
})

localPlayer.Idled:Connect(function() 
    if Toggles.AntiAFK then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end 
end)

task.spawn(function()
    local reconnecting = false
    local function forceRejoin() 
        if reconnecting then return end
        reconnecting = true
        SendWebhookPing("🚨 DISCONNECT DETECTED", "Account lost connection. Attempting to rejoin.", tonumber(0xFFA500), true, false, false)
        WriteHopState()
        task.spawn(function() while task.wait(1) do pcall(function() TeleportService:Teleport(game.PlaceId, localPlayer) end) end end) 
    end
    
    pcall(function() GuiService.ErrorMessageChanged:Connect(function() if Toggles.AutoReconnect then local err = GuiService:GetErrorCode(); if err and err.Value ~= 0 then forceRejoin() end end end) end)
    pcall(function() CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child) if Toggles.AutoReconnect and child.Name == "ErrorPrompt" then forceRejoin() end end) end)
    pcall(function() LogService.MessageOut:Connect(function(Message, Type) if Toggles.AutoReconnect and Type == Enum.MessageType.MessageError then local lMsg = string.lower(Message); if string.find(lMsg, "disconnect") or string.find(lMsg, "kicked") then forceRejoin() end end end) end)
end)

-- ==========================================
-- TAB 3: PLAYER SETTINGS
-- ==========================================
PlayerTab:CreateSection("Movement Modifications")

local customWalkSpeed = 16
local customJumpPower = 50
local enforceMovement = false
local isResetting = false

local wsSlider = PlayerTab:CreateSlider({
    Name = "Walkspeed",
    Range = {1, 500},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkspeedSlider",
    Callback = function(Value)
        customWalkSpeed = Value
        if not isResetting then enforceMovement = true end
    end,
})

local jpSlider = PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {1, 500},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        customJumpPower = Value
        if not isResetting then enforceMovement = true end
    end,
})

PlayerTab:CreateButton({
    Name = "Reset Speed and Jump Power",
    Callback = function()
        isResetting = true
        enforceMovement = false
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then 
            local hum = localPlayer.Character.Humanoid
            hum.WalkSpeed = 16
            hum.UseJumpPower = false 
            hum.JumpPower = 50 
        end
        task.spawn(function()
            wsSlider:Set(16)
            jpSlider:Set(50)
            task.wait(0.1)
            isResetting = false
        end)
    end
})

task.spawn(function() 
    while task.wait(0.1) do 
        if enforceMovement and localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then 
            local hum = localPlayer.Character.Humanoid
            hum.WalkSpeed = customWalkSpeed
            hum.UseJumpPower = true
            hum.JumpPower = customJumpPower 
        end 
    end 
end)

-- ==========================================
-- TAB 4: ESP
-- ==========================================
ESPTab:CreateSection("Player Visuals")

local espThread, espObjects = nil, {}
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
                        if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                            pcall(function()
                                local hl = Instance.new("Highlight", plr.Character)
                                hl.FillColor = sharedVisualColor; hl.OutlineColor = sharedVisualColor; hl.FillTransparency = 0.5
                                table.insert(espObjects, hl)
                                
                                local bgui = Instance.new("BillboardGui", plr.Character.Head)
                                bgui.Size = UDim2.new(0, 150, 0, 50); bgui.StudsOffset = Vector3.new(0, 3, 0); bgui.AlwaysOnTop = true
                                
                                local txt = Instance.new("TextLabel", bgui)
                                txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                                txt.TextSize = 13; txt.Font = Enum.Font.GothamBold
                                
                                local hum = plr.Character:FindFirstChild("Humanoid")
                                local hp = hum and mFloor(hum.Health) or 0
                                local maxHp = hum and mFloor(hum.MaxHealth) or 0
                                local pLevel = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Level") and plr.leaderstats.Level.Value or 0
                                
                                txt.Text = string.format("%s\nLevel: %s\n%s / %s", plr.Name, FormatNum(pLevel), FormatNum(hp), FormatNum(maxHp))
                                table.insert(espObjects, bgui)
                            end)
                        end
                    end
                    task.wait(1)
                end
            end)
        else ClearEsp() end
    end
})

ESPTab:CreateToggle({
    Name = "Rainbow ESP Colors",
    CurrentValue = false,
    Flag = "RainbowEsp",
    Callback = function(Value) Toggles.RainbowEsp = Value end
})

RunService.RenderStepped:Connect(function() 
    if Toggles.RainbowEsp then sharedVisualColor = Color3.fromHSV(os.clock() % 4 / 4, 1, 1) else sharedVisualColor = Color3.fromRGB(255, 50, 50) end 
end)

-- ==========================================
-- TAB 5: MISC
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
        
        -- STRICT 20 SECOND WAIT TO ENSURE FULL GAME LOAD
        task.wait(20) 
        
        pcall(function() if FarmToggleObj then FarmToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if TeleportToggleObj then TeleportToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if ReconToggleObj then ReconToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if AAFKToggleObj then AAFKToggleObj:Set(true) end end)
        
        SendWebhookPing("🔄 REJOIN SUCCESSFUL", "Account has fully reconnected and resumed farming after the 20s delay.", tonumber(0x00FF00), false, false, false)
    end)
end
