-- [[ LEVEL MASTERY SCRIPT ]]
-- BRANDING: BY ASH
-- ENGINE: MAXIMUM OVERDRIVE INTEGRATED

if _G.LevelMasteryRunning then _G.LevelMasteryRunning = false; task.wait(0.5) end
_G.LevelMasteryRunning = true

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
local localPlayer = Players.LocalPlayer

-- Micro-Optimizations (Bypassing Global Environment)
local mFloor = math.floor
local mRand = math.random
local mMin = math.min
local osClock = os.clock
local osTime = os.time
local tWait = task.wait
local tSpawn = task.spawn
local cfNew = CFrame.new
local v3New = Vector3.new
local sLower = string.lower
local sFind = string.find
local sFormat = string.format
local sGsub = string.gsub
local tInsert = table.insert
local tClear = table.clear
local isPC = UserInputService.KeyboardEnabled

pcall(function()
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    
    mt.__index = newcclosure(function(self, key)
        if not checkcaller() and self:IsA("Humanoid") then
            if key == "WalkSpeed" then return 16 end
            if key == "JumpPower" then return 50 end
        end
        return oldIndex(self, key)
    end)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and (method == "Kick" or method == "kick") and self == localPlayer then
            return nil 
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

local sessionStartTime = osTime()
local isFarming, autoFarmStartTime = false, 0
local startLevel, lastTrackedLevel = 0, 0
local sessionLevelsGained, sessionFarmingSeconds = 0, 0
local Toggles = {AutoFarmCombat = false, AutoReconnect = false, AntiAFK = false, EspToggle = false, RainbowEsp = false}

local DiscordPingIDs = "<@1020630748807577683> <@1453603930209648670>"
local UserWebhookURL = "https://discord.com/api/webhooks/1499550784424251453/C5rL13FC4L79uwCR4NmpO5P0KHF6toKGyYBxnzhrdBe9P3t_mGdq-z0SB5Qvz5aICh5h"

local DummyLocations = {
    v3New(-594.7495727539062, -157.31495666503906, 879.1777954101562),
    v3New(-627.1295166015625, -157.2369842529297, 910.9793090820312),
    v3New(-640.8036499023438, -156.70159912109375, 897.5853881835938),
    v3New(-622.4554443359375, -157.4154052734375, 786.8030395507812),
    v3New(-612.2915649414062, -155.93222045898438, 766.2567749023438),
    v3New(-639.3341674804688, -157.77249145507812, 769.9412841796875)
}
local ActiveDummyTarget = nil

local eventsFolder = ReplicatedStorage:WaitForChild("Events", 5)
local hitRemote = eventsFolder and eventsFolder:WaitForChild("Hit", 5)
local fbStorage = ReplicatedStorage:FindFirstChild("FireballReplicatedStorage")
local fbRemote = fbStorage and fbStorage:FindFirstChild("RemoteEvent")
local sbRemote = fbStorage and fbStorage:FindFirstChild("RemoteEvent1")
local mapFolder = workspace:WaitForChild("Map", 5)
local dummysFolder = mapFolder and mapFolder:WaitForChild("dummys", 5)

local trackerFileName = "LM_LevelAnalytics.json"
local trackerData = {FarmingSeconds = 0, LevelsGained = 0, Logs = {}, TotalExecutions = 0, LifetimeFarmingSeconds = 0}
pcall(function()
    if isfile and readfile and isfile(trackerFileName) then
        local savedData = HttpService:JSONDecode(readfile(trackerFileName))
        if savedData then for k, v in pairs(savedData) do trackerData[k] = v end end
    end
end)
local function SaveTrackerData() pcall(function() if writefile then writefile(trackerFileName, HttpService:JSONEncode(trackerData)) end end) end

trackerData.TotalExecutions = trackerData.TotalExecutions + 1
SaveTrackerData()

local function GetHistoricalAverageLPH()
    if #trackerData.Logs == 0 then return 0 end
    local sum, validLogs = 0, 0
    for i = 1, mMin(#trackerData.Logs, 5) do 
        local dailyGain = tonumber(trackerData.Logs[i]) or 0
        if dailyGain > 500 then sum = sum + (dailyGain / 24); validLogs = validLogs + 1 end
    end
    return validLogs > 0 and (sum / validLogs) or 0
end

local shouldResumeFarm = false
pcall(function()
    if isfile and readfile and isfile("LM_HopState.txt") then
        if sFind(readfile("LM_HopState.txt"), "resume_farm") then
            shouldResumeFarm = true
            if writefile then writefile("LM_HopState.txt", "idle") end 
        end
    end
end)

local function WriteHopState() pcall(function() if writefile then writefile("LM_HopState.txt", "resume_farm") end end) end

local cachedDummies = {}
tSpawn(function()
    while _G.LevelMasteryRunning and tWait(1) do
        if dummysFolder then
            tClear(cachedDummies)
            local children = dummysFolder:GetChildren()
            for i = 1, #children do
                local dummy = children[i]
                local hrp = dummy:FindFirstChild("HumanoidRootPart")
                local hum = dummy:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then 
                    tInsert(cachedDummies, {Hum = hum, Hrp = hrp}) 
                end
            end
        end
    end
end)

local function GetClosestDummy()
    local closest, shortestDist = nil, 50000 
    local char = localPlayer.Character
    if not char then return nil end
    local myHrp = char:FindFirstChild("HumanoidRootPart")
    
    if myHrp then
        local myPos = myHrp.Position
        for i = 1, #cachedDummies do
            local dummy = cachedDummies[i]
            local dist = (dummy.Hrp.Position - myPos).Magnitude
            if dist < shortestDist then shortestDist = dist; closest = dummy end
        end
    end
    return closest
end

local function OptimizeFPS()
    pcall(function()
        settings().Rendering.QualityLevel = 1
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 9e9
        local desc = workspace:GetDescendants()
        for i = 1, #desc do
            local v = desc[i]
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then v:Destroy() end
        end
    end)
end

local function FormatNum(v)
    local formatted = tostring(mFloor(tonumber(v) or 0))
    while true do local k; formatted, k = sGsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2"); if k == 0 then break end end
    return formatted
end

local function FormatTime(secs, formatType)
    if formatType == "Session" then return sFormat("%02d:%02d:%02d:%02d", mFloor(secs/86400), mFloor((secs%86400)/3600), mFloor((secs%3600)/60), secs%60)
    elseif formatType == "Lifetime" then return sFormat("%02d:%02d:%02d:%02d:%02d:%02d:%02d", mFloor(secs/31536000), mFloor((secs%31536000)/2592000), mFloor((secs%2592000)/604800), mFloor((secs%86400)/86400), mFloor((secs%86400)/3600), mFloor((secs%3600)/60), secs%60) end
end

local function getLevel() local lvl = 0; pcall(function() lvl = localPlayer.leaderstats.Level.Value end); return lvl end

local function GetAndEquipMagicTool(allowSnowball)
    local char = localPlayer.Character
    local bp = localPlayer:FindFirstChild("Backpack")
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not bp or not hum then return nil end
    
    local function scan(f)
        local children = f:GetChildren()
        for i = 1, #children do
            local item = children[i]
            if item:IsA("Tool") then
                local n = sLower(item.Name)
                if sFind(n, "fireball") then return item, "Fireball"
                elseif allowSnowball and sFind(n, "snowball") then return item, "Snowball" end
            end
        end
        return nil, nil
    end
    
    local tool, tType = scan(char)
    if not tool then tool, tType = scan(bp) end
    if tool and tool.Parent == bp then hum:EquipTool(tool) end
    return tType
end

local function SendWebhookPing(title, desc, color, pingUsers, reportType)
    if UserWebhookURL == "" then return end
    local lph = sessionFarmingSeconds > 0 and ((sessionLevelsGained / sessionFarmingSeconds) * 3600) or 0
    local payload = {
        ["embeds"] = {{
            ["title"] = title, ["description"] = desc, ["color"] = color,
            ["fields"] = {
                {["name"] = "Account", ["value"] = localPlayer.Name, ["inline"] = true},
                {["name"] = "Platform", ["value"] = isPC and "PC Desktop" or "Mobile Device", ["inline"] = true}
            }
        }}
    }
    local fields = payload.embeds[1].fields

    if reportType == "Execution" then
        tInsert(fields, {["name"] = "Total Executions", ["value"] = tostring(trackerData.TotalExecutions), ["inline"] = true})
        tInsert(fields, {["name"] = "Lifetime Farmed", ["value"] = FormatTime(trackerData.LifetimeFarmingSeconds, "Lifetime"), ["inline"] = true})
    else
        tInsert(fields, {["name"] = "Session Uptime", ["value"] = FormatTime(sessionFarmingSeconds, "Session"), ["inline"] = true})
        tInsert(fields, {["name"] = "Current LPH", ["value"] = sFormat("%.1f", lph), ["inline"] = true})
        local histAvgLPH = GetHistoricalAverageLPH()
        local rating = "Establishing Baseline..."
        if histAvgLPH > 0 then rating = lph > (histAvgLPH * 1.1) and "Above Average" or (lph < (histAvgLPH * 0.9) and "Below Average" or "Average") end
        tInsert(fields, {["name"] = "Current Rating", ["value"] = rating, ["inline"] = true})
        if reportType == "Daily" then tInsert(fields, {["name"] = "24 Hour Gain", ["value"] = "+" .. tostring(trackerData.LevelsGained), ["inline"] = true}) end
        if reportType == "Periodic" then tInsert(fields, {["name"] = "Current Level", ["value"] = FormatNum(getLevel()), ["inline"] = true}) end
    end

    if pingUsers then payload["content"] = DiscordPingIDs .. " **System Alert**" end
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if httprequest then tSpawn(function() pcall(function() httprequest({Url = UserWebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)}) end) end) end
end

tSpawn(function() tWait(2); if _G.LevelMasteryRunning then SendWebhookPing("Script Executed", "Level Mastery Script has been successfully Executed.", tonumber(0x8A2BE2), false, "Execution") end end)

localPlayer.CharacterAdded:Connect(function(char)
    if not _G.LevelMasteryRunning then return end
    if Toggles.AutoFarmCombat then
        tSpawn(function()
            local hrp = char:WaitForChild("HumanoidRootPart", 10)
            if hrp and ActiveDummyTarget then
                tWait(1.5) 
                hrp.CFrame = cfNew(ActiveDummyTarget) * cfNew(0, 0, 4)
            end
        end)
    end
end)

local Window = Rayfield:CreateWindow({Name = "Level Mastery Script", LoadingTitle = "Loading Script", LoadingSubtitle = "By Ash", ConfigurationSaving = {Enabled=false}, KeySystem = false})

local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)
local AnalyticsTab = Window:CreateTab("Level Analytics", 4483362458)
local SecurityTab = Window:CreateTab("Security", 4483362458)
local PlayerTab = Window:CreateTab("Player Settings", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

AutoFarmTab:CreateSection("Auto Farm")

local lastMeleeHit, nextMagicCheck, cachedMagicType = 0, 0, nil
local OverdriveSpeed = 0.05 

local FarmCombatToggleObj = AutoFarmTab:CreateToggle({
    Name = "Auto Farm Dummy",
    CurrentValue = false, Flag = "AutoFarmCombat",
    Callback = function(Value)
        Toggles.AutoFarmCombat = Value
        isFarming = Value
        if Value then 
            autoFarmStartTime = osClock()
            tSpawn(function()
                while _G.LevelMasteryRunning and Toggles.AutoFarmCombat do
                    local now = osClock()
                    local char = localPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if not ActiveDummyTarget then ActiveDummyTarget = DummyLocations[mRand(1, #DummyLocations)] end
                    
                    if hrp and ActiveDummyTarget then
                        if (hrp.Position - ActiveDummyTarget).Magnitude > 8 then
                            hrp.CFrame = cfNew(ActiveDummyTarget) * cfNew(0, 0, 4)
                        end
                    end
                    
                    local closest = GetClosestDummy()
                    if closest then
                        if now - lastMeleeHit >= OverdriveSpeed then
                            if hitRemote then hitRemote:FireServer(closest.Hum) end
                            lastMeleeHit = now
                        end
                        if now >= nextMagicCheck then
                            cachedMagicType = GetAndEquipMagicTool(true)
                            nextMagicCheck = now + 1
                        end
                        if cachedMagicType == "Fireball" and fbRemote then fbRemote:FireServer(ActiveDummyTarget)
                        elseif cachedMagicType == "Snowball" and sbRemote then sbRemote:FireServer(ActiveDummyTarget) end
                    else
                        ActiveDummyTarget = DummyLocations[mRand(1, #DummyLocations)]
                    end
                    tWait()
                end
            end)
        end
    end,
})

local HitSpeedSliderObj = AutoFarmTab:CreateSlider({
    Name = "Overdrive Hit Speed", Range = {0.0, 1.0}, Increment = 0.01, Suffix = "s", CurrentValue = 0.05, Flag = "HitSpeedSlider",
    Callback = function(Value) OverdriveSpeed = Value end,
})

AutoFarmTab:CreateButton({
    Name = "Set Max Hit Speed", 
    Callback = function() 
        OverdriveSpeed = 0
        if HitSpeedSliderObj then HitSpeedSliderObj:Set(0) end
        Rayfield:Notify({Title = "Speed Alert", Content = "Running At Max Speed", Duration = 3})
    end
})

AutoFarmTab:CreateButton({
    Name = "Instant Max Grind", 
    Callback = function() 
        OverdriveSpeed = 0
        if HitSpeedSliderObj then HitSpeedSliderObj:Set(0) end
        if FarmCombatToggleObj then FarmCombatToggleObj:Set(true) end
        
        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            ActiveDummyTarget = DummyLocations[mRand(1, #DummyLocations)]
            hrp.CFrame = cfNew(ActiveDummyTarget) * cfNew(0, 0, 4)
        end
        Rayfield:Notify({Title = "Overdrive Enabled", Content = "Speed Maxed, Script Running, And Teleported To Target", Duration = 3})
    end
})

AutoFarmTab:CreateSection("Movement")
local TeleportToggleObj = AutoFarmTab:CreateToggle({
    Name = "Teleport To Dummy", CurrentValue = false, Flag = "AutoTeleport",
    Callback = function(Value)
        if Value then
            local char = localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                ActiveDummyTarget = DummyLocations[mRand(1, #DummyLocations)]
                hrp.CFrame = cfNew(ActiveDummyTarget) * cfNew(0, 0, 4)
            end
            tSpawn(function() tWait(0.5); TeleportToggleObj:Set(false) end)
        end
    end,
})

AnalyticsTab:CreateSection("Session Progress")
AnalyticsTab:CreateSection("Future Projections")

if CoreGui:FindFirstChild("LM_StatTracker") then CoreGui.LM_StatTracker:Destroy() end
local trackerGui = Instance.new("ScreenGui"); trackerGui.Name = "LM_StatTracker"; trackerGui.IgnoreGuiInset = true; trackerGui.Parent = CoreGui
local trackerFrame = Instance.new("Frame"); trackerFrame.Size = UDim2.new(0, 280, 0, 115); trackerFrame.Position = UDim2.new(1, -290, 0, 10); trackerFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10); trackerFrame.Active = true; trackerFrame.Draggable = true; trackerFrame.Parent = trackerGui
local statsLabel = Instance.new("TextLabel"); statsLabel.Size = UDim2.new(1, 0, 1, 0); statsLabel.BackgroundTransparency = 1; statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255); statsLabel.TextSize = 13; statsLabel.Font = Enum.Font.GothamMedium; statsLabel.TextXAlignment = Enum.TextXAlignment.Left; statsLabel.TextYAlignment = Enum.TextYAlignment.Top; statsLabel.Text = "Status: Idle\n\nWaiting To Start"; statsLabel.Parent = trackerFrame
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = trackerFrame
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(80, 80, 80); stroke.Thickness = 2; stroke.Parent = trackerFrame
local padding = Instance.new("UIPadding"); padding.PaddingLeft = UDim.new(0, 10); padding.PaddingTop = UDim.new(0, 10); padding.Parent = statsLabel

tSpawn(function()
    while _G.LevelMasteryRunning and tWait(1) do
        local cur = getLevel(); local tStr = FormatTime(osTime() - sessionStartTime, "Session")
        if isFarming then
            if lastTrackedLevel == 0 or cur < lastTrackedLevel then lastTrackedLevel = cur end
            local d = cur - lastTrackedLevel; if d > 0 then sessionLevelsGained = sessionLevelsGained + d; trackerData.LevelsGained = trackerData.LevelsGained + d end
            lastTrackedLevel = cur; sessionFarmingSeconds = sessionFarmingSeconds + 1; trackerData.FarmingSeconds = trackerData.FarmingSeconds + 1; trackerData.LifetimeFarmingSeconds = trackerData.LifetimeFarmingSeconds + 1
            
            if sessionFarmingSeconds > 0 and sessionFarmingSeconds % 600 == 0 then SendWebhookPing("10 Minute Update", "Periodic Report", tonumber(0x00A2FF), false, "Periodic") end
            if trackerData.FarmingSeconds >= 86400 then SendWebhookPing("24 Hour Report", "Daily Grind Done", tonumber(0x00FFFF), true, "Daily"); tInsert(trackerData.Logs, 1, trackerData.LevelsGained); trackerData.FarmingSeconds = 0; trackerData.LevelsGained = 0 end
            if trackerData.FarmingSeconds % 60 == 0 then SaveTrackerData() end
            
            local lps = sessionFarmingSeconds > 0 and (sessionLevelsGained / sessionFarmingSeconds) or 0
            statsLabel.Text = sFormat("Status: Active\n\nSession Time: %s\nLevels Gained: %s\nLPM: %.1f\nLPH: %.1f", tStr, FormatNum(sessionLevelsGained), lps*60, lps*3600)
        else statsLabel.Text = sFormat("Status: Idle\n\nSession Time: %s\nLevels Gained: %s\nLPM: 0.0\nLPH: 0.0", tStr, FormatNum(sessionLevelsGained)) end
    end
end)

SecurityTab:CreateSection("Connection Protections")
_G.ReconToggleObj = SecurityTab:CreateToggle({Name = "Auto Reconnect Server", CurrentValue = false, Flag = "Recon", Callback = function(V) Toggles.AutoReconnect = V end})
_G.AAFKToggleObj = SecurityTab:CreateToggle({Name = "Anti AFK", CurrentValue = false, Flag = "AAFK", Callback = function(V) Toggles.AntiAFK = V end})

SecurityTab:CreateSection("Performance Optimization")
SecurityTab:CreateButton({Name = "Activate FPS Booster", Callback = function() OptimizeFPS() end})

localPlayer.Idled:Connect(function() if _G.LevelMasteryRunning and Toggles.AntiAFK then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end end)
tSpawn(function() local r = false; local function fj() if r or not _G.LevelMasteryRunning then return end; r = true; SendWebhookPing("Disconnect", "Rejoining", tonumber(0xFFA500), true, "Disconnect"); WriteHopState(); tSpawn(function() while _G.LevelMasteryRunning and tWait(1) do TeleportService:Teleport(game.PlaceId, localPlayer) end end) end; GuiService.ErrorMessageChanged:Connect(fj); CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(fj) end)

PlayerTab:CreateSection("Movement Modifications")
local ws, jp, enM, isRes = 16, 50, false, false
local wsSl = PlayerTab:CreateSlider({Name = "Walk Speed", Range={1,500}, Increment=1, CurrentValue=16, Flag="WS", Callback=function(v) ws=v; if not isRes then enM=true end end})
local jpSl = PlayerTab:CreateSlider({Name = "Jump Power", Range={1,500}, Increment=1, CurrentValue=50, Flag="JP", Callback=function(v) jp=v; if not isRes then enM=true end end})
PlayerTab:CreateButton({Name="Reset Stats", Callback=function() isRes=true; enM=false; if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then local h=localPlayer.Character.Humanoid; h.WalkSpeed=16; h.JumpPower=50 end; wsSl:Set(16); jpSl:Set(50); tWait(0.1); isRes=false end})
tSpawn(function() while _G.LevelMasteryRunning and tWait(0.1) do if enM and localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then local h=localPlayer.Character.Humanoid; h.WalkSpeed=ws; h.UseJumpPower=true; h.JumpPower=jp end end end)

ESPTab:CreateSection("Player Visuals")
local espObjects, sharedVisualColor = {}, Color3.fromRGB(255, 50, 50)
ESPTab:CreateToggle({Name="Player ESP", CurrentValue=false, Flag="Esp", Callback=function(v) Toggles.EspToggle=v; if not v then for i = 1, #espObjects do pcall(function() espObjects[i]:Destroy() end) end; tClear(espObjects) end end})
ESPTab:CreateToggle({Name="Rainbow ESP", CurrentValue=false, Flag="RE", Callback=function(v) Toggles.RainbowEsp=v end})

RunService.RenderStepped:Connect(function() if _G.LevelMasteryRunning and Toggles.RainbowEsp then sharedVisualColor = Color3.fromHSV(osClock()%4/4, 1, 1) end end)
tSpawn(function() 
    while _G.LevelMasteryRunning and tWait(0.5) do 
        if Toggles.EspToggle then 
            local pls = Players:GetPlayers()
            for i = 1, #pls do 
                local p = pls[i]
                if p ~= localPlayer and p.Character and p.Character:FindFirstChild("Head") then 
                    local c=p.Character
                    local hl=c:FindFirstChild("ESP_Highlight") or Instance.new("Highlight", c)
                    hl.Name="ESP_Highlight"; hl.FillTransparency=0.5; hl.FillColor=sharedVisualColor; hl.OutlineColor=sharedVisualColor
                    if not hl.Parent then tInsert(espObjects, hl) end
                    
                    local bg=c.Head:FindFirstChild("ESP_UI") or Instance.new("BillboardGui", c.Head)
                    bg.Name="ESP_UI"; bg.Size=UDim2.new(0,150,0,50); bg.AlwaysOnTop=true
                    
                    local tx=bg:FindFirstChild("T") or Instance.new("TextLabel", bg)
                    tx.Name="T"; tx.Size=UDim2.new(1,0,1,0); tx.BackgroundTransparency=1; tx.TextColor3=Color3.fromRGB(255,255,255); tx.Font=Enum.Font.GothamBold; tx.TextSize=13
                    if not bg.Parent then tInsert(espObjects, bg) end
                    
                    tx.Text=sFormat("%s\nLevel: %s\n%d/%d", p.Name, FormatNum(p:FindFirstChild("leaderstats") and p.leaderstats:FindFirstChild("Level").Value or 0), mFloor(c.Humanoid.Health), mFloor(c.Humanoid.MaxHealth)) 
                end 
            end 
        end 
    end 
end)

MiscTab:CreateSection("Utility Actions")
MiscTab:CreateButton({Name="Toggle Tracker", Callback=function() trackerGui.Enabled = not trackerGui.Enabled end})
MiscTab:CreateButton({Name="Infinite Yield", Callback=function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Infinite-yield-73483"))() end})

MiscTab:CreateButton({
    Name="Destroy UI", 
    Callback=function() 
        _G.LevelMasteryRunning = false
        isFarming = false 
        Toggles = {}
        for i = 1, #espObjects do pcall(function() espObjects[i]:Destroy() end) end
        if trackerGui then trackerGui:Destroy() end
        Rayfield:Destroy() 
    end
})

if shouldResumeFarm then
    tSpawn(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 9e9)
        tWait(6.5) 
        
        OptimizeFPS()
        OverdriveSpeed = 0
        pcall(function() if HitSpeedSliderObj then HitSpeedSliderObj:Set(0) end end)
        
        pcall(function() 
            if _G.ReconToggleObj then _G.ReconToggleObj:Set(true) end; tWait(0.2); 
            if _G.AAFKToggleObj then _G.AAFKToggleObj:Set(true) end; tWait(0.2); 
            if FarmCombatToggleObj then FarmCombatToggleObj:Set(true) end; tWait(0.2); 
            if TeleportToggleObj then TeleportToggleObj:Set(true) end 
        end)
        
        SendWebhookPing("Rejoin Successful", "Account Has Fully Reconnected And Resumed Master Farming After The Delay", tonumber(0x00FF00), false, "Rejoin")
        if Window and Window.Hide then Window:Hide() end
    end)
end
