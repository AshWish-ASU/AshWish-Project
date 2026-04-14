-- Load the ultra-sleek Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LogService = game:GetService("LogService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- Device Detection
local isPC = UserInputService.KeyboardEnabled
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

---------------------------------------------------------
-- RAYFIELD PROMPT KILLER
---------------------------------------------------------
task.spawn(function()
    task.wait(4)
    pcall(function()
        local containers = {CoreGui}
        if gethui then table.insert(containers, gethui()) end
        for _, container in pairs(containers) do
            for _, obj in pairs(container:GetDescendants()) do
                if obj:IsA("TextLabel") and string.find(string.lower(obj.Text), "outdated") then
                    local promptFrame = obj:FindFirstAncestorWhichIsA("Frame")
                    if promptFrame then promptFrame:Destroy() end
                end
            end
        end
    end)
end)

---------------------------------------------------------
-- CORE VARIABLES & STATE SAVER
---------------------------------------------------------
local sessionStartTime = os.time() 
local isFarming = false
local startLevel = 0
local startTime = 0
local PeakLevelsPerHour = 0
local Toggles = {}
Toggles.RelockOnRespawn = true

-- Optimizations
local mFloor = math.floor
local v3New = Vector3.new
local cfNew = CFrame.new

-- Hardcoded Webhooks & Switches
local UserWebhookURL = "https://discord.com/api/webhooks/1485790793833906329/QsnuKoZQvFtu-bm3w_hyuuwoHl7eAxU7F-4ls9wDgzwGE99tORY4zbuUUI_HZDBQThSh"
local DiscordID = "<@1453603930209648670>"
local KillSwitchURL = "https://raw.githubusercontent.com/AshWish-ASU/AshWish-Project/main/status.txt"

---------------------------------------------------------
-- ADVANCED FPS BOOSTER ENGINE
---------------------------------------------------------
local function AdvancedFPSBoost()
    pcall(function()
        settings().Rendering.QualityLevel = 1
        settings().Network.IncomingReplicationLag = 0
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0

        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
            Terrain.Decoration = false
        end

        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end

        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
            elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj:Destroy()
            end
        end
    end)
end

---------------------------------------------------------
-- GITHUB REMOTE KILL-SWITCH
---------------------------------------------------------
task.spawn(function()
    while task.wait(30) do 
        pcall(function()
            local noCacheUrl = KillSwitchURL .. "?nocache=" .. HttpService:GenerateGUID(false)
            local statusText = ""
            
            local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
            if httprequest then
                local res = httprequest({
                    Url = noCacheUrl,
                    Method = "GET",
                    Headers = {
                        ["Cache-Control"] = "no-cache, no-store, must-revalidate",
                        ["Pragma"] = "no-cache",
                        ["Expires"] = "0"
                    }
                })
                if res and res.Body then statusText = res.Body end
            else
                statusText = game:HttpGet(noCacheUrl)
            end
            
            if statusText and statusText ~= "" then
                local cleanStatus = string.gsub(statusText, "%s+", "")
                if string.find(cleanStatus:upper(), "STOP") then
                    isFarming = false
                    localPlayer:Kick("Cloud Kill-Switch Activated")
                end
            end
        end)
    end
end)

local shouldResumeFarm = false
pcall(function()
    if isfile and readfile and isfile("ROTEX_HopState.txt") then
        local state = readfile("ROTEX_HopState.txt")
        if state and string.find(state, "resume_farm") then
            shouldResumeFarm = true
            if writefile then writefile("ROTEX_HopState.txt", "idle") end 
        end
    end
end)

local function WriteHopState()
    pcall(function() if writefile then writefile("ROTEX_HopState.txt", "resume_farm") end end)
end

---------------------------------------------------------
-- DISCORD EMERGENCY PING FUNCTION
---------------------------------------------------------
local function SendEmergencyPing(title, reason, color)
    if UserWebhookURL == "" then return end
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if httprequest then
        pcall(function()
            httprequest({
                Url = UserWebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    ["content"] = DiscordID .. " Emergency Alert",
                    ["embeds"] = {{
                        ["title"] = title,
                        ["description"] = reason,
                        ["color"] = color,
                        ["fields"] = {{["name"] = "Account", ["value"] = localPlayer.Name, ["inline"] = true}}
                    }}
                })
            })
        end)
    end
end

local function FormatSessionTime(seconds)
    local days = mFloor(seconds / 86400)
    seconds = seconds % 86400
    local hours = mFloor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = mFloor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02dd %02dh %02dm %02ds", days, hours, minutes, secs)
end

local sharedVisualColor = Color3.fromRGB(255, 50, 50)
local rainbowVisuals = false

RunService.RenderStepped:Connect(function()
    if rainbowVisuals then sharedVisualColor = Color3.fromHSV(os.clock() % 4 / 4, 1, 1) end
end)

local function FormatNum(value)
    local n = tonumber(value) or 0
    n = mFloor(n)
    local formatted = tostring(n)
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if (k==0) then break end
    end
    return formatted
end

local function ParseNumber(str)
    str = string.lower(string.gsub(str, "[, ]", ""))
    local mult = 1
    if string.find(str, "k$") then mult = 1000; str = string.gsub(str, "k$", "") end
    if string.find(str, "m$") then mult = 1000000; str = string.gsub(str, "m$", "") end
    if string.find(str, "b$") then mult = 1000000000; str = string.gsub(str, "b$", "") end
    local num = tonumber(str)
    return num and (num * mult) or 0
end

---------------------------------------------------------
-- NETWORK INTERCEPTOR
---------------------------------------------------------
local KillAuraTargetHrp = nil
local FixedTargetPos = Vector3.new(255.390686, 267.746063, 1106.12268)

if hookmetamethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, arg1, ...)
        local method = getnamecallmethod()
        if tostring(method) == "FireServer" and tostring(self) == "WaterbeamEvent" then
            if type(arg1) == "table" and arg1.action == "throw" then
                if (Toggles.NormalKillAura or Toggles.AttachKillAura) and KillAuraTargetHrp then
                    return oldNamecall(self, {["action"] = "throw", ["destination"] = KillAuraTargetHrp.Position})
                elseif Toggles.GodFarm then
                    return oldNamecall(self, {["action"] = "throw", ["destination"] = FixedTargetPos})
                end
            end
        end
        return oldNamecall(self, arg1, ...)
    end)
end

---------------------------------------------------------
-- DEDICATED TOOL ENFORCER
---------------------------------------------------------
task.spawn(function()
    while task.wait(0.05) do
        if Toggles.GodFarm or Toggles.NormalKillAura or Toggles.AttachKillAura then
            pcall(function()
                local char = localPlayer.Character
                if char then
                    local backpack = localPlayer:FindFirstChild("Backpack")
                    local tool = char:FindFirstChild("Waterbeam") or (backpack and backpack:FindFirstChild("Waterbeam"))
                    if tool then
                        if tool.Parent ~= char then
                            char:FindFirstChild("Humanoid"):EquipTool(tool)
                        end
                        tool:Activate()
                    end
                end
            end)
        end
    end
end)

---------------------------------------------------------
-- GLOBAL TIME & EXECUTION TRACKER
---------------------------------------------------------
local execCount = 1
local firstTime = os.time()

pcall(function()
    if isfile and readfile and writefile then
        if isfile("ROTEX_Executions.txt") then
            execCount = tonumber(readfile("ROTEX_Executions.txt")) or 0
            execCount = execCount + 1
        end
        writefile("ROTEX_Executions.txt", tostring(execCount))
        
        if isfile("ROTEX_FirstTime.txt") then
            firstTime = tonumber(readfile("ROTEX_FirstTime.txt")) or os.time()
        else
            writefile("ROTEX_FirstTime.txt", tostring(firstTime))
        end
    end
end)

local function GetTimeUsedString()
    local t = os.time() - firstTime
    local y = mFloor(t / 31536000)
    t = t % 31536000
    local mo = mFloor(t / 2592000)
    t = t % 2592000
    local w = mFloor(t / 604800)
    t = t % 604800
    local d = mFloor(t / 86400)
    t = t % 86400
    local h = mFloor(t / 3600)
    t = t % 3600
    local mi = mFloor(t / 60)
    local s = t % 60
    return string.format("%02d/%02d/%02d/%02d/%02d/%02d/%02d", y, mo, w, d, h, mi, s)
end

---------------------------------------------------------
-- DUMMY KNOWLEDGE DATABASE
---------------------------------------------------------
local dummyData = {
    {Name = "TrainingDummy1", Req = 1, Mult = 1}, 
    {Name = "TrainingDummy2", Req = 250, Mult = 2}, 
    {Name = "TrainingDummy3", Req = 500, Mult = 3},
    {Name = "TrainingDummy4", Req = 1000, Mult = 4}, 
    {Name = "TrainingDummy5", Req = 2000, Mult = 5}, 
    {Name = "TrainingDummy6", Req = 4000, Mult = 6},
    {Name = "TrainingDummy7", Req = 8000, Mult = 7}, 
    {Name = "TrainingDummy8", Req = 16000, Mult = 8}, 
    {Name = "TrainingDummy9", Req = 26000, Mult = 9},
    {Name = "TrainingDummy10", Req = 36000, Mult = 10}
}

local function getLevel()
    local level = 0
    pcall(function() level = localPlayer.leaderstats.Level.Value end)
    return level
end

---------------------------------------------------------
-- PERSISTENT 24-HOUR LEVEL TRACKER
---------------------------------------------------------
local webhookQueue = {}
local processingQueue = false

local function ProcessWebhookQueue()
    if processingQueue or #webhookQueue == 0 then return end
    processingQueue = true
    task.spawn(function()
        while #webhookQueue > 0 do
            local item = table.remove(webhookQueue, 1)
            local success, retryCount = false, 0
            while not success and retryCount < 5 do
                local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
                if not httprequest then break end
                local res, err = pcall(function()
                    return httprequest({Url = item.Url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(item.Data)})
                end)
                if res and res.StatusCode then
                    if res.StatusCode == 204 or res.StatusCode == 200 then success = true
                    elseif res.StatusCode == 429 or (res.StatusCode >= 500 and res.StatusCode <= 599) then task.wait(30) retryCount = retryCount + 1
                    else break end
                else
                    task.wait(5) retryCount = retryCount + 1
                end
            end
        end
        processingQueue = false
    end)
end

local function SendSystemWebhook(titleStr, descStr, colorHex, fieldsTable)
    if UserWebhookURL == "" then return end
    local data = {
        ["username"] = localPlayer.Name .. " System",
        ["embeds"] = {{["title"] = titleStr, ["description"] = descStr, ["color"] = tonumber(colorHex), ["fields"] = fieldsTable or {}, ["footer"] = {["text"] = "AshWish Autonomous System - " .. os.date("%I:%M:%S %p")}}}
    }
    table.insert(webhookQueue, {Url = UserWebhookURL, Data = data})
    ProcessWebhookQueue()
end

local trackerFileName = "ROTEX_LevelAnalytics.json"
local trackerData = { FarmingSeconds = 0, LevelsGained = 0, LifetimeLevelsGained = 0, Logs = {} }

pcall(function()
    if isfile and readfile and isfile(trackerFileName) then
        local loadedData = HttpService:JSONDecode(readfile(trackerFileName))
        if loadedData then
            trackerData.FarmingSeconds = loadedData.FarmingSeconds or 0
            trackerData.LevelsGained = loadedData.LevelsGained or 0
            trackerData.LifetimeLevelsGained = loadedData.LifetimeLevelsGained or 0
            trackerData.Logs = (loadedData.Logs and type(loadedData.Logs[1]) ~= "string") and loadedData.Logs or {}
        end
    end
end)

local function SaveTrackerData() pcall(function() if writefile then writefile(trackerFileName, HttpService:JSONEncode(trackerData)) end end) end

local function GetHistoricalAverage()
    if #trackerData.Logs == 0 then return 1000 end
    local sum = 0
    local count = math.min(#trackerData.Logs, 5)
    for i = 1, count do sum = sum + (tonumber(trackerData.Logs[i]) or 0) end
    return sum / count
end

local function GetPerformanceRating(projectedGain, historicalAverage)
    if historicalAverage <= 0 then historicalAverage = 1000 end
    local ratio = projectedGain / historicalAverage
    if ratio >= 1.50 then return "GOD TIER" elseif ratio >= 1.10 then return "CRUSHING IT" elseif ratio >= 0.85 then return "CONSISTENT" elseif ratio >= 0.50 then return "SLUGGISH" else return "BROKEN AFK" end
end

local rollingGains = {}
local rollingSum = 0

---------------------------------------------------------
-- THE SOLID BLACK STAT TRACKER UI
---------------------------------------------------------
if CoreGui:FindFirstChild("SleekStatTracker") then CoreGui.SleekStatTracker:Destroy() end

local trackerGui = Instance.new("ScreenGui")
trackerGui.Name = "SleekStatTracker"
trackerGui.IgnoreGuiInset = true 
trackerGui.Parent = CoreGui

local trackerFrame = Instance.new("Frame")
trackerFrame.Size = UDim2.new(0, 280, 0, 105) 
trackerFrame.Position = UDim2.new(1, -290, 0, 10) 
trackerFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
trackerFrame.BorderSizePixel = 0
trackerFrame.Active = true
trackerFrame.Draggable = true
trackerFrame.Parent = trackerGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = trackerFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 80)
stroke.Thickness = 2
stroke.Parent = trackerFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, 0, 1, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.TextSize = 13
statsLabel.Font = Enum.Font.GothamMedium 
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Text = "Status: Idle\n\nWaiting to start..."
statsLabel.Parent = trackerFrame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 10)
padding.Parent = statsLabel

task.spawn(function()
    while task.wait(1) do
        if not statsLabel or not statsLabel.Parent then break end
        local sessionElapsed = os.time() - sessionStartTime
        local timeFarmedStr = FormatSessionTime(sessionElapsed)

        if isFarming then
            local currentLevel = getLevel()
            local levelsGained = currentLevel - startLevel
            local elapsedSeconds = os.time() - startTime
            local levelsPerMin = (elapsedSeconds / 60) > 0 and mFloor(levelsGained / (elapsedSeconds / 60)) or 0
            local levelsPerHr = (elapsedSeconds / 3600) > 0 and mFloor(levelsGained / (elapsedSeconds / 3600)) or 0

            statsLabel.Text = string.format(
                "Status: ACTIVE\n\nTime Farmed This Session: %s\nLVL Gained: +%s\nLVL / Min: %s\nLVL / Hr:  %s",
                timeFarmedStr, FormatNum(levelsGained), FormatNum(levelsPerMin), FormatNum(levelsPerHr)
            )
        else
            statsLabel.Text = string.format("Status: IDLE\n\nTime Farmed This Session: %s\nWaiting to start...", timeFarmedStr)
        end
    end
end)

---------------------------------------------------------
-- RAYFIELD MAIN WINDOW 
---------------------------------------------------------
local Window = Rayfield:CreateWindow({
   Name = "AshWish",
   LoadingTitle = "AshWish Loading",
   LoadingSubtitle = "Optimized Clean",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local AutoFarmTab   = Window:CreateTab("Auto Farming", 4483362458)
local ProtectionTab = Window:CreateTab("Protection", 4483362458)
local CombatTab     = Window:CreateTab("Combat", 4483362458)
local TrollTab      = Window:CreateTab("Troll", 4483362458)
local AnalyticsTab  = Window:CreateTab("Level Analytics", 4483362458)
local TeleportTab   = Window:CreateTab("Teleport", 4483362458)
local PlayerTab     = Window:CreateTab("Player Settings", 4483362458)
local WebhookTab    = Window:CreateTab("Discord Webhooks", 4483362458)
local MiscTab       = Window:CreateTab("Misc", 4483362458)

---------------------------------------------------------
-- 1. AUTO FARMING TAB
---------------------------------------------------------
local farmingThread = nil
local bossConnection = nil

local function TeleportToBestDummy()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local playerLevel = getLevel()
    local bestDummyData = nil
    
    for i = #dummyData, 1, -1 do
        if playerLevel >= dummyData[i].Req then bestDummyData = dummyData[i]; break end
    end

    if bestDummyData then
        local obj = workspace:FindFirstChild("dummies") and workspace.dummies:FindFirstChild(bestDummyData.Name)
        if obj and obj:FindFirstChild("HumanoidRootPart") then
            local dummyHrp = obj:FindFirstChild("HumanoidRootPart")
            if (hrp.Position - dummyHrp.Position).Magnitude > 15 then
                hrp.CFrame = dummyHrp.CFrame * cfNew(0, 0, 4)
            end
            hrp.CFrame = CFrame.lookAt(hrp.Position, v3New(dummyHrp.Position.X, hrp.Position.Y, dummyHrp.Position.Z))
        end
    end
end

AutoFarmTab:CreateSection("Auto Farm")

local FarmToggleObj
FarmToggleObj = AutoFarmTab:CreateToggle({
   Name = "Auto Farm All",
   CurrentValue = false,
   Flag = "FarmToggle",
   Callback = function(Value)
        Toggles.GodFarm = Value
        isFarming = Value
        if Value then
            startLevel = getLevel()
            startTime = os.time()
            
            pcall(function()
                local npcFolder = workspace:FindFirstChild("Boss") and workspace.Boss:FindFirstChild("NPC") or workspace:FindFirstChild("NPC")
                if npcFolder then
                    bossConnection = npcFolder.ChildAdded:Connect(function(obj)
                        if Toggles.GodFarm and string.match(obj.Name:upper(), "BOSS") then
                            local hum = obj:WaitForChild("Humanoid", 2)
                            if hum and hum.Health > 0 then
                                ReplicatedStorage.DamageEvent:FireServer({["multiply"] = 1, ["action"] = "hit", ["enemyHum"] = hum})
                            end
                        end
                    end)
                end
            end)

            farmingThread = task.spawn(function()
                while Toggles.GodFarm do
                    local char = localPlayer.Character
                    local playerLevel = getLevel()

                    local bestDummyData = nil
                    for i = #dummyData, 1, -1 do
                        if playerLevel >= dummyData[i].Req then bestDummyData = dummyData[i]; break end
                    end

                    local targetsToHit = {}
                    
                    if bestDummyData then
                        local obj = workspace:FindFirstChild("dummies") and workspace.dummies:FindFirstChild(bestDummyData.Name)
                        if obj and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            local dummyHrp = obj:FindFirstChild("HumanoidRootPart")
                            
                            if hrp and dummyHrp and Toggles.AutoTeleport then
                                if (hrp.Position - dummyHrp.Position).Magnitude > 15 then
                                    hrp.CFrame = dummyHrp.CFrame * cfNew(0, 0, 4)
                                end
                                hrp.CFrame = CFrame.lookAt(hrp.Position, v3New(dummyHrp.Position.X, hrp.Position.Y, dummyHrp.Position.Z))
                            end
                            table.insert(targetsToHit, {hum = obj.Humanoid, mult = bestDummyData.Mult})
                        end
                    end

                    pcall(function()
                        local npcFolder = workspace:FindFirstChild("Boss") and workspace.Boss:FindFirstChild("NPC") or workspace:FindFirstChild("NPC")
                        if npcFolder then
                            for _, obj in ipairs(npcFolder:GetChildren()) do
                                if string.match(obj.Name:upper(), "BOSS") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 then
                                    table.insert(targetsToHit, {hum = obj.Humanoid, mult = 1})
                                end
                            end
                        end
                    end)

                    for _, target in ipairs(targetsToHit) do
                        if target.hum.Health > 0 then
                            task.spawn(function()
                                pcall(function()
                                    ReplicatedStorage.DamageEvent:FireServer({["multiply"] = target.mult, ["action"] = "hit", ["enemyHum"] = target.hum})
                                end)
                            end)
                        end
                    end
                    
                    task.wait(math.random(5, 10) / 100) 
                end
            end)
        else
            if farmingThread then task.cancel(farmingThread); farmingThread = nil end
            if bossConnection then bossConnection:Disconnect(); bossConnection = nil end
        end
   end,
})

local TeleportToggleObj
TeleportToggleObj = AutoFarmTab:CreateToggle({
   Name = "Auto Teleport To Dummy",
   CurrentValue = false,
   Flag = "TeleportToggle",
   Callback = function(Value) 
       Toggles.AutoTeleport = Value 
       if Value then TeleportToBestDummy() end
   end,
})

---------------------------------------------------------
-- 2. PROTECTION TAB
---------------------------------------------------------
ProtectionTab:CreateSection("Network & Client Safety")

local AutoReconnectToggleObj
AutoReconnectToggleObj = ProtectionTab:CreateToggle({
    Name = "Instant Auto Reconnect",
    CurrentValue = false, 
    Flag = "AutoReconnectToggle",
    Callback = function(Value)
        Toggles.AutoReconnect = Value
    end,
})

local AntiLagToggleObj
AntiLagToggleObj = ProtectionTab:CreateToggle({
    Name = "Anti Lag Server Hop",
    CurrentValue = false,
    Flag = "AntiLagToggle",
    Callback = function(Value)
        Toggles.AntiLag = Value
        if Value then
            task.spawn(function()
                while Toggles.AntiLag do
                    pcall(function()
                        local pingString = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
                        local currentPing = tonumber(string.match(pingString, "%d+"))
                        if currentPing and currentPing >= 750 then
                            SendEmergencyPing("SEVERE LAG - HOPPING SERVERS", "Ping spiked. The script is automatically hopping.", tonumber(0x800080))
                            WriteHopState()
                            task.wait(1)
                            TeleportService:Teleport(game.PlaceId, localPlayer)
                        end
                    end)
                    task.wait(5)
                end
            end)
        end
    end,
})

local AntiModToggleObj
AntiModToggleObj = ProtectionTab:CreateToggle({
    Name = "Anti Mod Server Hop",
    CurrentValue = false,
    Flag = "AntiModToggle",
    Callback = function(Value)
        Toggles.AntiMod = Value
    end,
})

local AntiAfkToggleObj
AntiAfkToggleObj = ProtectionTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false, 
    Flag = "AntiCheatFix",
    Callback = function(Value)
        Toggles.VirtualTap = Value
    end,
})

local FpsBoosterBtnObj
FpsBoosterBtnObj = ProtectionTab:CreateButton({
    Name = "FPS Booster",
    Callback = function()
        AdvancedFPSBoost()
        Rayfield:Notify({Title = "FPS Boosted", Content = "All heavy rendering systems disabled.", Duration = 3})
    end,
})

localPlayer.Idled:Connect(function()
    if Toggles.VirtualTap then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game)
    end
end)

Players.PlayerAdded:Connect(function(plr)
    if Toggles.AntiMod then
        if plr:GetRankInGroup(game.CreatorId) > 0 or string.match(plr.Name:lower(), "admin") then
            SendEmergencyPing("MOD DETECTED", "Developer joined the lobby. Emergency hop.", tonumber(0xFF0000))
            WriteHopState()
            task.wait(1)
            TeleportService:Teleport(game.PlaceId, localPlayer)
        end
    end
end)

task.spawn(function()
    local reconnecting = false
    local function forceRejoin()
        if reconnecting then return end
        reconnecting = true
        SendEmergencyPing("DISCONNECT - REJOINING", "Error detected. Aggressively re-routing to a new server.", tonumber(0xFFA500))
        WriteHopState()
        
        task.spawn(function()
            while task.wait(5) do
                pcall(function() 
                    TeleportService:Teleport(game.PlaceId, localPlayer) 
                end)
            end
        end)
    end

    pcall(function()
        GuiService.ErrorMessageChanged:Connect(function()
            if Toggles.AutoReconnect then
                local err = GuiService:GetErrorCode()
                if err and err.Value ~= 0 then forceRejoin() end
            end
        end)
    end)
    
    pcall(function()
        CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
            if Toggles.AutoReconnect and child.Name == "ErrorPrompt" then forceRejoin() end
        end)
    end)

    pcall(function()
        LogService.MessageOut:Connect(function(Message, Type)
            if Toggles.AutoReconnect and Type == Enum.MessageType.MessageError then
                local lowerMsg = string.lower(Message)
                if string.find(lowerMsg, "disconnect") or string.find(lowerMsg, "kicked") then
                    forceRejoin()
                end
            end
        end)
    end)
end)

---------------------------------------------------------
-- 3. COMBAT TAB 
---------------------------------------------------------
local espThread = nil
local espObjects = {}
local hitboxSize = 10
local hitboxThread = nil
local originalSizes = {}

CombatTab:CreateSection("Hitbox")

local function RestoreHitboxes()
    for char, data in pairs(originalSizes) do
        pcall(function()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then 
                hrp.Size = data.Size
                hrp.Transparency = data.Transparency
                hrp.CanCollide = data.CanCollide
                if hrp:FindFirstChild("HitboxOutline") then hrp.HitboxOutline:Destroy() end
            end
        end)
    end
    originalSizes = {}
end

CombatTab:CreateInput({
    Name = "Hitbox Size",
    PlaceholderText = "Type size",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then hitboxSize = val end
    end,
})

CombatTab:CreateToggle({
    Name = "Enable Hitbox Expander",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        if Value then
            hitboxThread = task.spawn(function()
                while true do
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= localPlayer and plr.Character then
                            local char = plr.Character
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                if not originalSizes[char] then 
                                    originalSizes[char] = {Size = hrp.Size, Transparency = hrp.Transparency, CanCollide = hrp.CanCollide} 
                                end
                                pcall(function()
                                    hrp.Size = v3New(hitboxSize, hitboxSize, hitboxSize)
                                    hrp.Transparency = 0.8
                                    hrp.CanCollide = false
                                    
                                    if not hrp:FindFirstChild("HitboxOutline") then
                                        local outline = Instance.new("SelectionBox")
                                        outline.Name = "HitboxOutline"
                                        outline.Adornee = hrp
                                        outline.LineThickness = 0.05
                                        outline.Color3 = Color3.fromRGB(255, 255, 255)
                                        outline.SurfaceTransparency = 0.9 
                                        outline.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
                                        outline.Parent = hrp
                                    end
                                end)
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else
            if hitboxThread then task.cancel(hitboxThread); hitboxThread = nil end
            RestoreHitboxes()
        end
    end,
})

CombatTab:CreateSection("Kill Aura")

local selectedAuraPlayer = nil
local auraThread = nil

local AuraDropdown = CombatTab:CreateDropdown({
    Name = "Select Target",
    Options = {"None"},
    CurrentOption = {"None"},
    MultipleOptions = false,
    Callback = function(Option) selectedAuraPlayer = Option[1] end,
})

CombatTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer then table.insert(list, plr.Name) end
        end
        if #list == 0 then table.insert(list, "None") end
        AuraDropdown:Refresh(list, true)
    end,
})

local function ManageKillAura()
    if Toggles.NormalKillAura or Toggles.AttachKillAura then
        if auraThread then task.cancel(auraThread) end
        auraThread = task.spawn(function()
            while Toggles.NormalKillAura or Toggles.AttachKillAura do
                if selectedAuraPlayer and selectedAuraPlayer ~= "None" then
                    local targetPlr = Players:FindFirstChild(selectedAuraPlayer)
                    if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") and targetPlr.Character:FindFirstChild("Humanoid") and targetPlr.Character.Humanoid.Health > 0 then
                        
                        KillAuraTargetHrp = targetPlr.Character.HumanoidRootPart
                        local char = localPlayer.Character
                        local myHrp = char and char:FindFirstChild("HumanoidRootPart")

                        if Toggles.AttachKillAura and myHrp then
                            myHrp.CFrame = KillAuraTargetHrp.CFrame * cfNew(0, 15, 0)
                            myHrp.CFrame = CFrame.lookAt(myHrp.Position, KillAuraTargetHrp.Position)
                        end

                        pcall(function()
                            ReplicatedStorage.DamageEvent:FireServer({
                                ["multiply"] = 1, 
                                ["action"] = "hit", 
                                ["enemyHum"] = targetPlr.Character.Humanoid
                            })
                        end)
                    else
                        KillAuraTargetHrp = nil
                    end
                else
                    KillAuraTargetHrp = nil
                end
                task.wait(0.1)
            end
        end)
    else
        KillAuraTargetHrp = nil
        if auraThread then task.cancel(auraThread); auraThread = nil end
    end
end

CombatTab:CreateToggle({
    Name = "Normal Kill Aura",
    CurrentValue = false,
    Flag = "NormalAuraToggle",
    Callback = function(Value)
        Toggles.NormalKillAura = Value
        ManageKillAura()
    end,
})

CombatTab:CreateToggle({
    Name = "Attach Kill Aura",
    CurrentValue = false,
    Flag = "AttachAuraToggle",
    Callback = function(Value)
        Toggles.AttachKillAura = Value
        ManageKillAura()
    end,
})

task.spawn(function()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then table.insert(list, plr.Name) end
    end
    if #list == 0 then table.insert(list, "None") end
    AuraDropdown:Refresh(list, true)
end)

CombatTab:CreateSection("ESP")

local function ClearEsp()
    for _, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end
    espObjects = {}
end

CombatTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "EspToggle",
    Callback = function(Value)
        if Value then
            espThread = task.spawn(function()
                while true do
                    ClearEsp()
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                            local char = plr.Character
                            local hum = char:FindFirstChild("Humanoid")
                            
                            pcall(function()
                                local highlight = Instance.new("Highlight")
                                highlight.Adornee = char
                                highlight.FillColor = sharedVisualColor
                                highlight.OutlineColor = sharedVisualColor
                                highlight.FillTransparency = 0.5
                                highlight.OutlineTransparency = 0
                                highlight.Parent = char
                                table.insert(espObjects, highlight)
                            end)

                            pcall(function()
                                local bgui = Instance.new("BillboardGui")
                                bgui.Name = "EspInfo"
                                bgui.Adornee = char:FindFirstChild("Head") or char.HumanoidRootPart
                                bgui.Size = UDim2.new(0, 100, 0, 40)
                                bgui.StudsOffset = Vector3.new(0, 2.5, 0)
                                bgui.AlwaysOnTop = true

                                local txt = Instance.new("TextLabel")
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.BackgroundTransparency = 1
                                txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                                txt.TextStrokeTransparency = 0 
                                txt.TextSize = 11
                                txt.Font = Enum.Font.GothamBold
                                
                                local lvl = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Level") and plr.leaderstats.Level.Value or 0
                                local hp = hum and math.floor(hum.Health) or 0
                                local maxHp = hum and math.floor(hum.MaxHealth) or 0

                                txt.Text = string.format("Lv. %s %s\nHP: %s / %s", FormatNum(lvl), plr.Name, FormatNum(hp), FormatNum(maxHp))
                                txt.Parent = bgui
                                bgui.Parent = char
                                table.insert(espObjects, bgui)
                            end)
                        end
                    end
                    task.wait(1) 
                end
            end)
        else
            if espThread then task.cancel(espThread); espThread = nil end
            ClearEsp()
        end
    end,
})

CombatTab:CreateToggle({
    Name = "Rainbow ESP Color",
    CurrentValue = false,
    Flag = "RainbowEspToggle",
    Callback = function(Value)
        rainbowVisuals = Value
        if not Value then sharedVisualColor = Color3.fromRGB(255, 50, 50) end
    end,
})

CombatTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 50, 50),
    Flag = "EspColorPicker",
    Callback = function(Value)
        if not rainbowVisuals then sharedVisualColor = Value end
    end,
})

---------------------------------------------------------
-- 4. TROLL TAB (Master Optimization Engine)
---------------------------------------------------------

-- GLOBAL RENDER STEPPED ENGINE (Improves FPS)
local orbitAngle = 0
local randomOrbitAngle = 0
local trollTargetPlayer = "None"
local randomOrbitTarget = nil

RunService.Stepped:Connect(function()
    if Toggles.Noclip then
        local char = localPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(11)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if rainbowVisuals then sharedVisualColor = Color3.fromHSV(os.clock() % 4 / 4, 1, 1) end
    
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        if Toggles.SeizureSpin then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(math.random(1, 360)), math.rad(math.random(1, 360)), math.rad(math.random(1, 360)))
        end
        
        if Toggles.JitterWalk then
            hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-1, 1) * 0.5, 0, math.random(-1, 1) * 0.5)
        end
    end

    if trollTargetPlayer and trollTargetPlayer ~= "None" then
        local target = Players:FindFirstChild(trollTargetPlayer)
        local targetChar = target and target.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

        if targetHrp and hrp then
            if Toggles.UFOOrbit then
                orbitAngle = orbitAngle + 0.4
                local radius = 5
                local offset = Vector3.new(math.cos(orbitAngle) * radius, 0, math.sin(orbitAngle) * radius)
                hrp.CFrame = CFrame.lookAt(targetHrp.Position + offset, targetHrp.Position)
            end
            
            if Toggles.BangPlayer then
                local offsetZ = 1.5 + (math.sin(tick() * 15) * 4) 
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, offsetZ)
            end
            
            if Toggles.FollowBehind then
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end

    if Toggles.OrbitRandom and randomOrbitTarget then
        local randHrp = randomOrbitTarget.Character and randomOrbitTarget.Character:FindFirstChild("HumanoidRootPart")
        if randHrp and hrp then
            randomOrbitAngle = randomOrbitAngle + 0.4
            local radius = 5
            local offset = Vector3.new(math.cos(randomOrbitAngle) * radius, 0, math.sin(randomOrbitAngle) * radius)
            hrp.CFrame = CFrame.lookAt(randHrp.Position + offset, randHrp.Position)
        end
    end
end)

TrollTab:CreateSection("Fake Badges (Client-Sided)")

local currentFakeRank = "None"
local fakeRankGui = nil

local rankImages = {
    ["Rank 1-10 Badge"] = "rbxassetid://13321938624",
    ["Rank 11-30 Badge"] = "rbxassetid://13321938398",
    ["Rank 31-70 Badge"] = "rbxassetid://13321938232",
    ["Rank 71-100 Badge"] = "rbxassetid://13321938751"
}

local function applyFakeRank()
    task.spawn(function()
        pcall(function()
            if currentFakeRank == "None" then
                if fakeRankGui then fakeRankGui:Destroy() end
                return
            end

            local char = localPlayer.Character
            if not char then return end
            
            local head = char:WaitForChild("Head", 5)
            if not head then return end

            if fakeRankGui then fakeRankGui:Destroy() end

            fakeRankGui = Instance.new("BillboardGui")
            fakeRankGui.Name = "FakeRankBadge"
            fakeRankGui.Adornee = head
            fakeRankGui.Size = UDim2.new(3, 0, 3, 0)
            fakeRankGui.StudsOffset = Vector3.new(0, 4, 0)
            fakeRankGui.AlwaysOnTop = true
            fakeRankGui.MaxDistance = 250

            local img = Instance.new("ImageLabel")
            img.Parent = fakeRankGui
            img.Size = UDim2.new(1, 0, 1, 0)
            img.BackgroundTransparency = 1
            img.Image = rankImages[currentFakeRank] or ""
            img.ScaleType = Enum.ScaleType.Fit 

            fakeRankGui.Parent = head
        end)
    end)
end

localPlayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        task.wait(2)
        applyFakeRank()
    end)
end)

TrollTab:CreateDropdown({
    Name = "Fake Leaderboard Badge (Client-Sided)",
    Options = {"None", "Rank 1-10 Badge", "Rank 11-30 Badge", "Rank 31-70 Badge", "Rank 71-100 Badge"},
    CurrentOption = {"None"},
    MultipleOptions = false,
    Flag = "FakeRankBadgeDropdown",
    Callback = function(Option)
        currentFakeRank = Option[1]
        applyFakeRank()
    end,
})

TrollTab:CreateSection("Target Selection")

local TrollDropdown = TrollTab:CreateDropdown({
    Name = "Select Target",
    Options = {"None"},
    CurrentOption = {"None"},
    MultipleOptions = false,
    Callback = function(Option) trollTargetPlayer = Option[1] end,
})

TrollTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer then table.insert(list, plr.Name) end
        end
        if #list == 0 then table.insert(list, "None") end
        TrollDropdown:Refresh(list, true)
    end,
})

TrollTab:CreateSection("Annoy Players")

TrollTab:CreateToggle({
    Name = "Orbit Target",
    CurrentValue = false,
    Flag = "OrbitToggle",
    Callback = function(Value)
        Toggles.UFOOrbit = Value
    end,
})

TrollTab:CreateToggle({
    Name = "Bang Player",
    CurrentValue = false,
    Flag = "BangToggle",
    Callback = function(Value)
        Toggles.BangPlayer = Value
    end,
})

TrollTab:CreateToggle({
    Name = "Follow Behind Target",
    CurrentValue = false,
    Flag = "FollowBehindToggle",
    Callback = function(Value)
        Toggles.FollowBehind = Value
    end,
})

TrollTab:CreateSection("Server Annoyances")

task.spawn(function()
    while task.wait(0.05) do
        if Toggles.ServerSpooker then
            local plrs = Players:GetPlayers()
            if #plrs > 1 then
                local randomPlr = plrs[math.random(1, #plrs)]
                if randomPlr ~= localPlayer and randomPlr.Character and randomPlr.Character:FindFirstChild("HumanoidRootPart") then
                    local char = localPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = randomPlr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                    end
                end
            end
        end
    end
end)

TrollTab:CreateToggle({
    Name = "Flicker Around Map",
    CurrentValue = false,
    Flag = "ServerSpookerToggle",
    Callback = function(Value)
        Toggles.ServerSpooker = Value
    end,
})

local randomOrbitTarget = nil
local randomOrbitAngle = 0
task.spawn(function()
    while task.wait(3) do
        if Toggles.OrbitRandom then
            local plrs = Players:GetPlayers()
            if #plrs > 1 then
                randomOrbitTarget = plrs[math.random(1, #plrs)]
                if randomOrbitTarget == localPlayer then randomOrbitTarget = nil end
            end
        else
            randomOrbitTarget = nil
        end
    end
end)

TrollTab:CreateToggle({
    Name = "Orbit Random Players",
    CurrentValue = false,
    Flag = "OrbitRandomToggle",
    Callback = function(Value)
        Toggles.OrbitRandom = Value
    end,
})

TrollTab:CreateSection("Self Trolls")

TrollTab:CreateToggle({
    Name = "Fast Spin",
    CurrentValue = false,
    Flag = "SeizureSpinToggle",
    Callback = function(Value)
        Toggles.SeizureSpin = Value
    end,
})

TrollTab:CreateToggle({
    Name = "Jitter Walk",
    CurrentValue = false,
    Flag = "JitterWalkToggle",
    Callback = function(Value)
        Toggles.JitterWalk = Value
    end,
})

TrollTab:CreateToggle({
    Name = "Enable Noclip (Client-Sided)",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(Value)
        Toggles.Noclip = Value
    end,
})

task.spawn(function()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then table.insert(list, plr.Name) end
    end
    if #list == 0 then table.insert(list, "None") end
    TrollDropdown:Refresh(list, true)
end)

---------------------------------------------------------
-- 5. LEVEL ANALYTICS TAB
---------------------------------------------------------
local CustomTargetLevel = 0
local CustomTargetHours = 0

local LiveStatsPara = AnalyticsTab:CreateParagraph({
    Title = "Live Analytics Projections",
    Content = "Loading live data..."
})

AnalyticsTab:CreateSection("Goal Calculator")
local GoalResultPara = AnalyticsTab:CreateParagraph({Title = "Estimated Time", Content = "Awaiting input..."})

local displaySecondsToTarget = 0 
AnalyticsTab:CreateInput({
    Name = "Target Level",
    PlaceholderText = "e.g. 1000000 or 1m",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) 
        CustomTargetLevel = ParseNumber(Text)
        displaySecondsToTarget = 0 
    end,
})

AnalyticsTab:CreateSection("Time Calculator")
local TimeMachinePara = AnalyticsTab:CreateParagraph({Title = "Projected Level", Content = "Awaiting input..."})

AnalyticsTab:CreateInput({
    Name = "Hours to Farm",
    PlaceholderText = "e.g. 72 or 10",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) 
        CustomTargetHours = ParseNumber(Text)
    end,
})

AnalyticsTab:CreateSection("History")

if #trackerData.Logs == 0 then
    AnalyticsTab:CreateParagraph({
        Title = "No History Yet",
        Content = "Finish a full 24 hours of Auto Farming to generate a log."
    })
else
    for i, pastLevels in ipairs(trackerData.Logs) do
        local val = type(pastLevels) == "number" and pastLevels or tonumber(pastLevels) or 0
        AnalyticsTab:CreateParagraph({
            Title = "Day " .. tostring(i) .. " History",
            Content = "Levels Gained: " .. FormatNum(val)
        })
    end
end

local lastTrackedLevel = 0
local badPerformanceSeconds = 0
local displaySecondsToMilestone = 0

task.spawn(function()
    while task.wait(1) do
        local currentLvl = getLevel()
        
        if isFarming then
            if lastTrackedLevel == 0 or currentLvl < lastTrackedLevel then lastTrackedLevel = currentLvl end

            local diff = currentLvl - lastTrackedLevel
            if diff > 5 then diff = 0 end

            if diff > 0 then
                trackerData.LevelsGained = trackerData.LevelsGained + diff
                trackerData.LifetimeLevelsGained = trackerData.LifetimeLevelsGained + diff
                lastTrackedLevel = currentLvl
            end

            table.insert(rollingGains, diff)
            rollingSum = rollingSum + diff
            if #rollingGains > 300 then
                rollingSum = rollingSum - table.remove(rollingGains, 1)
            end

            trackerData.FarmingSeconds = trackerData.FarmingSeconds + 1
            if trackerData.FarmingSeconds % 60 == 0 then SaveTrackerData() end
        else
            lastTrackedLevel = 0
        end

        local hrs = mFloor(trackerData.FarmingSeconds / 3600)
        local mins = mFloor((trackerData.FarmingSeconds % 3600) / 60)
        local secs = trackerData.FarmingSeconds % 60

        local currentGain = trackerData.LevelsGained
        local currentLvlPerSec = 0
        if trackerData.FarmingSeconds > 0 then currentLvlPerSec = currentGain / trackerData.FarmingSeconds end

        local projected24h = currentLvlPerSec * 86400
        local currentRating = GetPerformanceRating(projected24h, GetHistoricalAverage())

        if isFarming and (currentRating == "BROKEN AFK" or currentRating == "SLUGGISH") then
            badPerformanceSeconds = badPerformanceSeconds + 1
            if badPerformanceSeconds == 300 then
                SendSystemWebhook("Efficiency Drop Detected", "Performance has dropped to " .. currentRating .. " for 5 straight minutes. Check your server!", 0xFF0000)
                SendEmergencyPing("EFFICIENCY DROP DETECTED", "Performance has dropped to " .. currentRating .. " for 5 straight minutes. The script may be broken or you might be stuck.", tonumber(0xFF0000))
            end
        elseif isFarming then
            badPerformanceSeconds = 0
        end

        if trackerData.FarmingSeconds >= 86400 then
            local fields = {
                {["name"] = "Player", ["value"] = localPlayer.Name, ["inline"] = false},
                {["name"] = "Official Rating", ["value"] = currentRating, ["inline"] = false},
                {["name"] = "24H Gain", ["value"] = "+" .. FormatNum(trackerData.LevelsGained), ["inline"] = true},
                {["name"] = "Peak Speed", ["value"] = FormatNum(PeakLevelsPerHour) .. " Lvl/Hr", ["inline"] = true},
                {["name"] = "Lifetime Levels", ["value"] = FormatNum(trackerData.LifetimeLevelsGained), ["inline"] = false}
            }
            SendSystemWebhook("Daily Recap: Another 24 hours of relentless grinding completed.", "Daily stats have been logged and reset.", 0xFFD700, fields)

            table.insert(trackerData.Logs, 1, trackerData.LevelsGained)
            if #trackerData.Logs > 15 then table.remove(trackerData.Logs, 16) end 
            
            trackerData.FarmingSeconds = 0
            trackerData.LevelsGained = 0
            PeakLevelsPerHour = 0
            rollingSum = 0
            rollingGains = {}
            SaveTrackerData()
        end

        local sustainedLPH = 0
        if #rollingGains > 0 then
            sustainedLPH = mFloor((rollingSum / #rollingGains) * 3600)
        end
        if sustainedLPH > PeakLevelsPerHour then PeakLevelsPerHour = sustainedLPH end

        local projected1Week = projected24h * 7
        local projected1Month = projected24h * 30
        local projected3Months = projected24h * 90
        local projected6Months = projected24h * 180

        local milestoneStep = 10000
        local nextMilestone = math.ceil((currentLvl + 1) / milestoneStep) * milestoneStep
        local levelsToMilestone = nextMilestone - currentLvl
        
        -- SMOOTH COUNTDOWN LOGIC FOR MILESTONE
        local actualSecondsToMilestone = currentLvlPerSec > 0 and (levelsToMilestone / currentLvlPerSec) or 0
        if displaySecondsToMilestone == 0 or math.abs(displaySecondsToMilestone - actualSecondsToMilestone) > 15 then
            displaySecondsToMilestone = actualSecondsToMilestone
        elseif isFarming and currentLvlPerSec > 0 then
            displaySecondsToMilestone = displaySecondsToMilestone - 1
            if displaySecondsToMilestone < 0 then displaySecondsToMilestone = 0 end
        end

        local function FormatTimeFriendly(totalSeconds)
            if totalSeconds <= 0 or totalSeconds == math.huge then return "Calculating..." end
            local d = mFloor(totalSeconds / 86400)
            local h = mFloor((totalSeconds % 86400) / 3600)
            local m = mFloor((totalSeconds % 3600) / 60)
            local s = mFloor(totalSeconds % 60)
            if d > 0 then return string.format("%d Days, %d Hours, %d Mins", d, h, m) end
            if h > 0 then return string.format("%d Hours, %d Mins, %d Secs", h, m, s) end
            return string.format("%d Mins, %d Secs", m, s)
        end

        LiveStatsPara:Set({
            Title = "Live Analytics Projections",
            Content = string.format(
                "Time Farmed Today: %02d:%02d:%02d\n" ..
                "Levels Gained: %s\n" ..
                "Lifetime Levels: %s\n\n" ..
                "Status: %s\n" ..
                "Peak Speed: %s Levels / Hr\n\n" ..
                "Projections:\n" ..
                "- 1 Day: +%s\n" ..
                "- 1 Week: +%s\n" ..
                "- 1 Month: +%s\n" ..
                "- 3 Months: +%s\n" ..
                "- 6 Months: +%s\n\n" ..
                "Next Level Milestone: %s\n%s",
                hrs, mins, secs, FormatNum(currentGain), FormatNum(trackerData.LifetimeLevelsGained),
                currentRating, FormatNum(PeakLevelsPerHour),
                FormatNum(projected24h), FormatNum(projected1Week), FormatNum(projected1Month),
                FormatNum(projected3Months), FormatNum(projected6Months),
                FormatNum(nextMilestone), FormatTimeFriendly(displaySecondsToMilestone)
            )
        })

        -- SMOOTH COUNTDOWN LOGIC FOR CUSTOM TARGET
        if isFarming and CustomTargetLevel > currentLvl then
            local targetLevelsNeeded = CustomTargetLevel - currentLvl
            local actualTargetTime = currentLvlPerSec > 0 and (targetLevelsNeeded / currentLvlPerSec) or 0
            
            if displaySecondsToTarget == 0 or math.abs(displaySecondsToTarget - actualTargetTime) > 15 then
                displaySecondsToTarget = actualTargetTime
            else
                displaySecondsToTarget = displaySecondsToTarget - 1
                if displaySecondsToTarget < 0 then displaySecondsToTarget = 0 end
            end
            
            GoalResultPara:Set({Title = "Time to Level " .. FormatNum(CustomTargetLevel), Content = FormatTimeFriendly(displaySecondsToTarget)})
        elseif CustomTargetLevel > 0 then
            displaySecondsToTarget = 0
            GoalResultPara:Set({Title = "Estimated Time", Content = "Start farming to calculate ETA."})
        end

        if isFarming and CustomTargetHours > 0 then
            local projectedLevel = currentLvl + mFloor(currentLvlPerSec * (CustomTargetHours * 3600))
            TimeMachinePara:Set({Title = "Projection Level in " .. CustomTargetHours .. "h", Content = "Level " .. FormatNum(projectedLevel)})
        elseif CustomTargetHours > 0 then
            TimeMachinePara:Set({Title = "Projected Level", Content = "Start farming to calculate projection."})
        end
    end
end)

---------------------------------------------------------
-- 6. DISCORD WEBHOOKS TAB 
---------------------------------------------------------
local hasSentUserExecutionLog = false 

WebhookTab:CreateParagraph({
    Title = "Auto Webhook is ACTIVE",
    Content = "Your stats are automatically being sent every 10 minutes to your Discord."
})

local function SendUserWebhook()
    local currentLevel = getLevel()
    local levelsGained = isFarming and (currentLevel - startLevel) or 0
    
    local levelsPerMin = 0
    local levelsPerHr = 0
    
    if isFarming and startTime > 0 then
        local elapsedSeconds = os.time() - startTime
        local elapsedMinutes = elapsedSeconds / 60
        local elapsedHours = elapsedSeconds / 3600
        
        levelsPerMin = elapsedMinutes > 0 and mFloor(levelsGained / elapsedMinutes) or 0
        levelsPerHr = elapsedHours > 0 and mFloor(levelsGained / elapsedHours) or 0
    end

    local embedsTable = {}

    if not hasSentUserExecutionLog then
        table.insert(embedsTable, {
            ["title"] = "INIT AshWish Script Executed",
            ["description"] = "A user just injected the script.",
            ["color"] = tonumber(0x00AFFF), 
            ["fields"] = {
                {["name"] = "Player Info", ["value"] = localPlayer.Name, ["inline"] = true},
                {["name"] = "Local Executions", ["value"] = tostring(execCount), ["inline"] = true},
                {["name"] = "Device", ["value"] = isPC and "PC" or "Mobile", ["inline"] = true},
                {["name"] = "Time Used", ["value"] = GetTimeUsedString(), ["inline"] = false}
            },
            ["footer"] = {["text"] = "Execution Log - " .. os.date("%I:%M:%S %p")}
        })
        hasSentUserExecutionLog = true 
    end

    table.insert(embedsTable, {
        ["title"] = "Auto Farm Stats",
        ["description"] = "Here is your latest progress update!",
        ["color"] = tonumber(0x00FF00), 
        ["fields"] = {
            {["name"] = "Player", ["value"] = localPlayer.Name, ["inline"] = false},
            {["name"] = "Current Level", ["value"] = FormatNum(currentLevel), ["inline"] = true},
            {["name"] = "Levels Gained since you started grinding", ["value"] = "+" .. FormatNum(levelsGained), ["inline"] = false},
            {["name"] = "Levels / Min", ["value"] = FormatNum(levelsPerMin), ["inline"] = true},
            {["name"] = "Levels / Hour", ["value"] = FormatNum(levelsPerHr), ["inline"] = true},
            {["name"] = "Peak Levels / Hr", ["value"] = FormatNum(PeakLevelsPerHour), ["inline"] = true},
            {["name"] = "Status", ["value"] = isFarming and "Active" or "Idle", ["inline"] = false}
        },
        ["footer"] = {["text"] = "AshWish UI - Update Time: " .. os.date("%I:%M:%S %p")}
    })

    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if httprequest then
        pcall(function()
            httprequest({
                Url = UserWebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    ["username"] = localPlayer.Name .. " AshWish System", 
                    ["embeds"] = embedsTable
                })
            })
        end)
    end
end

task.spawn(function()
    task.wait(5) 
    SendUserWebhook() 
    while true do
        task.wait(600) 
        SendUserWebhook()
    end
end)

WebhookTab:CreateButton({
   Name = "Test Webhook Now",
   Callback = function()
       SendUserWebhook()
   end,
})

---------------------------------------------------------
-- 7. TELEPORT TAB
---------------------------------------------------------
TeleportTab:CreateSection("Refresh Player List")

local selectedTeleportPlayer = nil

local TeleportDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = {"None"},
    CurrentOption = {"None"},
    MultipleOptions = false,
    Callback = function(Option)
        selectedTeleportPlayer = Option[1]
    end,
})

TeleportTab:CreateButton({
    Name = "Refresh Players",
    Callback = function()
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer then
                table.insert(list, plr.Name)
            end
        end
        if #list == 0 then table.insert(list, "None") end
        TeleportDropdown:Refresh(list, true)
    end,
})

TeleportTab:CreateSection("Teleport Action")

TeleportTab:CreateButton({
    Name = "Teleport to Selected Player",
    Callback = function()
        if selectedTeleportPlayer and selectedTeleportPlayer ~= "None" then
            local targetChar = Players:FindFirstChild(selectedTeleportPlayer) and Players:FindFirstChild(selectedTeleportPlayer).Character
            local myChar = localPlayer.Character
            
            if targetChar and myChar and targetChar:FindFirstChild("HumanoidRootPart") and myChar:FindFirstChild("HumanoidRootPart") then
                myChar.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame * cfNew(0, 0, 3)
            end
        end
    end,
})

task.spawn(function()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then table.insert(list, plr.Name) end
    end
    if #list == 0 then table.insert(list, "None") end
    TeleportDropdown:Refresh(list, true)
end)

---------------------------------------------------------
-- 8. PLAYER SETTINGS TAB
---------------------------------------------------------
PlayerTab:CreateSection("Player Movement")

local customWalkSpeed = 16
local customJumpPower = 50
local enforceMovement = false

local wsSlider = PlayerTab:CreateSlider({
    Name = "Walkspeed",
    Range = {1, 500},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkspeedSlider",
    Callback = function(Value)
        if not enforceMovement then return end 
        customWalkSpeed = Value
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            localPlayer.Character.Humanoid.WalkSpeed = Value
        end
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
        if not enforceMovement then return end 
        customJumpPower = Value
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            localPlayer.Character.Humanoid.UseJumpPower = true
            localPlayer.Character.Humanoid.JumpPower = Value
        end
    end,
})

wsSlider.Callback = function(Value)
    customWalkSpeed = Value
    enforceMovement = true
end

jpSlider.Callback = function(Value)
    customJumpPower = Value
    enforceMovement = true
end

PlayerTab:CreateButton({
    Name = "Reset Speed and Jump Power",
    Callback = function()
        enforceMovement = false
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            local hum = localPlayer.Character.Humanoid
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        task.spawn(function()
            wsSlider:Set(16)
            jpSlider:Set(50)
            enforceMovement = false 
        end)
    end,
})

task.spawn(function()
    while task.wait(0.1) do
        if enforceMovement and localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            local hum = localPlayer.Character.Humanoid
            if hum.WalkSpeed <= 16 or hum.WalkSpeed == customWalkSpeed then
                hum.WalkSpeed = customWalkSpeed
            end
            hum.UseJumpPower = true
            hum.JumpPower = customJumpPower
        end
    end
end)

PlayerTab:CreateSection("Avatar Modifications")

PlayerTab:CreateToggle({
    Name = "Fake Korblox",
    CurrentValue = false,
    Flag = "FakeKorbloxToggle",
    Callback = function(Value)
        pcall(function()
            local char = localPlayer.Character
            if char then
                local rightLowerLeg = char:FindFirstChild("RightLowerLeg")
                local rightFoot = char:FindFirstChild("RightFoot")
                local rightUpperLeg = char:FindFirstChild("RightUpperLeg")

                if rightUpperLeg then
                    if Value then
                        if rightLowerLeg then rightLowerLeg.Transparency = 1 end
                        if rightFoot then rightFoot.Transparency = 1 end
                        rightUpperLeg.Transparency = 1
                        
                        local fake = char:FindFirstChild("FakeKorbloxMeshPart") or Instance.new("Part")
                        fake.Name = "FakeKorbloxMeshPart"
                        fake.Size = Vector3.new(0.5, 1, 0.5)
                        fake.Anchored = false
                        fake.CanCollide = false
                        fake.Massless = true
                        fake.Transparency = 0
                        fake.CFrame = rightUpperLeg.CFrame * CFrame.new(0, -0.2, 0)
                        
                        local mesh = fake:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh")
                        mesh.MeshType = Enum.MeshType.FileMesh 
                        mesh.MeshId = "rbxassetid://139607718"
                        mesh.Scale = Vector3.new(1, 1, 1)
                        mesh.Parent = fake
                        
                        local weld = fake:FindFirstChildOfClass("WeldConstraint") or Instance.new("WeldConstraint")
                        weld.Part0 = rightUpperLeg
                        weld.Part1 = fake
                        weld.Parent = fake
                        
                        fake.Parent = char
                    else
                        if rightLowerLeg then rightLowerLeg.Transparency = 0 end
                        if rightFoot then rightFoot.Transparency = 0 end
                        rightUpperLeg.Transparency = 0
                        local fake = char:FindFirstChild("FakeKorbloxMeshPart")
                        if fake then fake:Destroy() end
                    end
                end
            end
        end)
    end,
})

PlayerTab:CreateToggle({
    Name = "Fake Headless (Client-Sided)",
    CurrentValue = false,
    Flag = "FakeHeadlessToggle",
    Callback = function(Value)
        pcall(function()
            local char = localPlayer.Character
            if char and char:FindFirstChild("Head") then
                if Value then
                    char.Head.Transparency = 1
                    if char.Head:FindFirstChild("face") then char.Head.face.Transparency = 1 end
                else
                    char.Head.Transparency = 0
                    if char.Head:FindFirstChild("face") then char.Head.face.Transparency = 0 end
                end
            end
        end)
    end,
})

---------------------------------------------------------
-- 9. MISC TAB
---------------------------------------------------------
local altClickTP = false

MiscTab:CreateButton({
   Name = "Hide or Show Black Tracker UI",
   Callback = function()
       if trackerGui then trackerGui.Enabled = not trackerGui.Enabled end
   end,
})

MiscTab:CreateButton({
   Name = "Destroy Script and UI",
   Callback = function()
       isFarming = false
       Toggles = {}
       
       if farmingThread then task.cancel(farmingThread); farmingThread = nil end
       if espThread then task.cancel(espThread); espThread = nil end
       if auraThread then task.cancel(auraThread); auraThread = nil end
       if hitboxThread then task.cancel(hitboxThread); hitboxThread = nil end
       if bossConnection then bossConnection:Disconnect(); bossConnection = nil end
       
       ClearEsp()
       RestoreHitboxes()
       if fakeRankGui then pcall(function() fakeRankGui:Destroy() end) end
       
       if trackerGui then trackerGui:Destroy() end
       Rayfield:Destroy()
   end,
})

MiscTab:CreateButton({
   Name = "Infinite Yield",
   Callback = function()
       loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Infinite-yield-73483"))()
   end,
})

MiscTab:CreateButton({
   Name = "Server Hop",
   Callback = function()
       local PlaceID = game.PlaceId
       local AllIDs = {}
       pcall(function()
           local Site = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
           for _, server in pairs(Site.data) do
               if server.playing < server.maxPlayers and server.id ~= game.JobId then
                   table.insert(AllIDs, server.id)
               end
           end
       end)
       if #AllIDs > 0 then
           local randomServer = AllIDs[math.random(1, #AllIDs)]
           TeleportService:TeleportToPlaceInstance(PlaceID, randomServer, localPlayer)
       end
   end,
})

MiscTab:CreateButton({
   Name = "Rejoin Same Server",
   Callback = function()
       Rayfield:Notify({Title = "Rejoining", Content = "Routing back to current public lobby...", Duration = 3})
       TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
   end,
})

if isPC then
    MiscTab:CreateToggle({
       Name = "Left Alt Left Click TP",
       CurrentValue = false,
       Flag = "AltClickTPToggle",
       Callback = function(Value)
           altClickTP = Value
       end,
    })

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if altClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
                if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local targetPos = mouse.Hit.Position
                    localPlayer.Character.HumanoidRootPart.CFrame = cfNew(targetPos.X, targetPos.Y + 3, targetPos.Z)
                end
            end
        end
    end)
end

Rayfield:Notify({
    Title = "AshWish Injected",
    Content = "All failsafes active and running.",
    Duration = 5,
    Image = 4483362458,
})

---------------------------------------------------------
-- POST-EXECUTION AUTO RESUME FIX
---------------------------------------------------------
if shouldResumeFarm then
    task.spawn(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        char:WaitForChild("HumanoidRootPart", 15)
        local leaderstats = localPlayer:WaitForChild("leaderstats", 15)
        if leaderstats then leaderstats:WaitForChild("Level", 15) end
        workspace:WaitForChild("dummies", 15)
        
        -- Wait 5 seconds to ensure Waterbeam fully loads into inventory
        task.wait(5) 
        
        -- Automatically toggle EVERY option in Auto Farming & Protection back ON
        pcall(function() if FarmToggleObj then FarmToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if TeleportToggleObj then TeleportToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if AntiAfkToggleObj then AntiAfkToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if AutoReconnectToggleObj then AutoReconnectToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if AntiLagToggleObj then AntiLagToggleObj:Set(true) end end)
        task.wait(0.2)
        pcall(function() if AntiModToggleObj then AntiModToggleObj:Set(true) end end)
        
        -- Advanced Engine Optimizer Trigger
        AdvancedFPSBoost()
        
        -- Wait 15 seconds, then safely hide the Rayfield UI and wake up the Waterbeam
        task.wait(15)
        pcall(function()
            -- Cleanly hide the Rayfield UI. We ONLY target the Main frame and avoid touching the toggle button.
            local containers = {CoreGui, localPlayer:WaitForChild("PlayerGui")}
            if gethui then table.insert(containers, gethui()) end
            
            for _, container in pairs(containers) do
                if container then
                    for _, gui in pairs(container:GetChildren()) do
                        if gui:IsA("ScreenGui") then
                            local main = gui:FindFirstChild("Main") or gui:FindFirstChild("Rayfield")
                            if main and main:IsA("Frame") and main.Size.Y.Offset > 100 then 
                                main.Visible = false
                            end
                        end
                    end
                end
            end
            
            task.wait(1)
            
            local vim = game:GetService("VirtualInputManager")
            local cam = workspace.CurrentCamera
            local centerX = cam.ViewportSize.X / 2
            local centerY = cam.ViewportSize.Y / 2
            
            vim:SendTouchEvent(1, 0, centerX, centerY) 
            task.wait(0.1)
            vim:SendTouchEvent(1, 1, centerX, centerY)
        end)
    end)
end
