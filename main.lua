print("AshWish Executed! Loading UI...")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
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
local isPC = UserInputService.KeyboardEnabled
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

task.spawn(function()
    task.wait(4)
    pcall(function()
        local containers = {CoreGui}
        if gethui then table.insert(containers, gethui()) end
        for _, c in pairs(containers) do
            for _, obj in pairs(c:GetDescendants()) do
                if obj:IsA("TextLabel") and string.find(string.lower(obj.Text), "outdated") then
                    local p = obj:FindFirstAncestorWhichIsA("Frame")
                    if p then p:Destroy() end
                end
            end
        end
    end)
end)

local sessionStartTime = os.time() 
local isFarming = false
local startLevel = 0
local startTime = 0
local PeakLevelsPerHour = 0
local Toggles = {RelockOnRespawn = true}
local mFloor = math.floor
local v3New = Vector3.new
local cfNew = CFrame.new
local UserWebhookURL = "https://discord.com/api/webhooks/1485790793833906329/QsnuKoZQvFtu-bm3w_hyuuwoHl7eAxU7F-4ls9wDgzwGE99tORY4zbuUUI_HZDBQThSh"
local DiscordID = "<@1453603930209648670>"
local KillSwitchURL = "https://raw.githubusercontent.com/AshWish-ASU/AshWish-Project/main/status.txt"

local function AdvancedFPSBoost()
    pcall(function()
        settings().Rendering.QualityLevel = 1
        settings().Network.IncomingReplicationLag = 0
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        local t = workspace:FindFirstChildOfClass("Terrain")
        if t then t.WaterWaveSize=0; t.WaterWaveSpeed=0; t.WaterReflectance=0; t.WaterTransparency=0; t.Decoration=false end
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = false end
        end
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then obj.Material = Enum.Material.SmoothPlastic; obj.Reflectance = 0; obj.CastShadow = false
            elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj:Destroy() end
        end
    end)
end

task.spawn(function()
    while task.wait(30) do 
        pcall(function()
            local statusText = ""
            local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
            if httprequest then
                local res = httprequest({Url = KillSwitchURL.."?nocache="..HttpService:GenerateGUID(false), Method = "GET", Headers = {["Cache-Control"]="no-cache, no-store", ["Pragma"]="no-cache"}})
                if res and res.Body then statusText = res.Body end
            else
                statusText = game:HttpGet(KillSwitchURL.."?nocache="..HttpService:GenerateGUID(false))
            end
            if statusText and statusText ~= "" and string.find(string.gsub(statusText, "%s+", ""):upper(), "STOP") then
                isFarming = false
                localPlayer:Kick("Cloud Kill-Switch Activated")
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

local function WriteHopState() pcall(function() if writefile then writefile("ROTEX_HopState.txt", "resume_farm") end end) end

local function SendEmergencyPing(title, reason, color)
    if UserWebhookURL == "" then return end
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if httprequest then
        pcall(function()
            httprequest({Url = UserWebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode({["content"] = DiscordID .. " Emergency Alert", ["embeds"] = {{["title"] = title, ["description"] = reason, ["color"] = color, ["fields"] = {{["name"] = "Account", ["value"] = localPlayer.Name, ["inline"] = true}}}}})})
        end)
    end
end

local function FormatSessionTime(seconds)
    local d = mFloor(seconds / 86400); seconds = seconds % 86400
    local h = mFloor(seconds / 3600); seconds = seconds % 3600
    local m = mFloor(seconds / 60); local s = seconds % 60
    return string.format("%02dd %02dh %02dm %02ds", d, h, m, s)
end

local sharedVisualColor = Color3.fromRGB(255, 50, 50)
local rainbowVisuals = false
RunService.RenderStepped:Connect(function() if rainbowVisuals then sharedVisualColor = Color3.fromHSV(os.clock() % 4 / 4, 1, 1) end end)

local function FormatNum(value)
    local n = mFloor(tonumber(value) or 0)
    local formatted = tostring(n)
    local k
    while true do formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2"); if (k==0) then break end end
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

local KillAuraTargetHrp = nil
local FixedTargetPos = Vector3.new(255.390686, 267.746063, 1106.12268)

if hookmetamethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, arg1, ...)
        local method = getnamecallmethod()
        if tostring(method) == "FireServer" and tostring(self) == "WaterbeamEvent" and type(arg1) == "table" and arg1.action == "throw" then
            if (Toggles.NormalKillAura or Toggles.AttachKillAura) and KillAuraTargetHrp then return oldNamecall(self, {["action"] = "throw", ["destination"] = KillAuraTargetHrp.Position})
            elseif Toggles.GodFarm then return oldNamecall(self, {["action"] = "throw", ["destination"] = FixedTargetPos}) end
        end
        return oldNamecall(self, arg1, ...)
    end)
end

task.spawn(function()
    while task.wait(0.05) do
        if Toggles.GodFarm or Toggles.NormalKillAura or Toggles.AttachKillAura then
            pcall(function()
                local char = localPlayer.Character
                if char then
                    local tool = char:FindFirstChild("Waterbeam") or (localPlayer:FindFirstChild("Backpack") and localPlayer.Backpack:FindFirstChild("Waterbeam"))
                    if tool then
                        if tool.Parent ~= char then char:FindFirstChild("Humanoid"):EquipTool(tool) end
                        tool:Activate()
                    end
                end
            end)
        end
    end
end)

local execCount, firstTime = 1, os.time()
pcall(function()
    if isfile and readfile and writefile then
        if isfile("ROTEX_Executions.txt") then execCount = (tonumber(readfile("ROTEX_Executions.txt")) or 0) + 1 end
        writefile("ROTEX_Executions.txt", tostring(execCount))
        if isfile("ROTEX_FirstTime.txt") then firstTime = tonumber(readfile("ROTEX_FirstTime.txt")) or os.time()
        else writefile("ROTEX_FirstTime.txt", tostring(firstTime)) end
    end
end)

local function GetTimeUsedString()
    local t = os.time() - firstTime
    local y = mFloor(t / 31536000); t = t % 31536000
    local mo = mFloor(t / 2592000); t = t % 2592000
    local w = mFloor(t / 604800); t = t % 604800
    local d = mFloor(t / 86400); t = t % 86400
    local h = mFloor(t / 3600); t = t % 3600
    local mi = mFloor(t / 60); local s = t % 60
    return string.format("%02d/%02d/%02d/%02d/%02d/%02d/%02d", y, mo, w, d, h, mi, s)
end

local dummyData = {{Name="TrainingDummy1",Req=1,Mult=1},{Name="TrainingDummy2",Req=250,Mult=2},{Name="TrainingDummy3",Req=500,Mult=3},{Name="TrainingDummy4",Req=1000,Mult=4},{Name="TrainingDummy5",Req=2000,Mult=5},{Name="TrainingDummy6",Req=4000,Mult=6},{Name="TrainingDummy7",Req=8000,Mult=7},{Name="TrainingDummy8",Req=16000,Mult=8},{Name="TrainingDummy9",Req=26000,Mult=9},{Name="TrainingDummy10",Req=36000,Mult=10}}
local function getLevel() local lvl = 0; pcall(function() lvl = localPlayer.leaderstats.Level.Value end); return lvl end

local webhookQueue, processingQueue = {}, false
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
                local res = pcall(function() return httprequest({Url=item.Url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=HttpService:JSONEncode(item.Data)}) end)
                if type(res)=="table" and (res.StatusCode==204 or res.StatusCode==200) then success = true else task.wait(5); retryCount=retryCount+1 end
            end
        end
        processingQueue = false
    end)
end

local function SendSystemWebhook(tStr, dStr, col, fields)
    if UserWebhookURL=="" then return end
    table.insert(webhookQueue, {Url = UserWebhookURL, Data = {["username"] = localPlayer.Name .. " System", ["embeds"] = {{["title"]=tStr, ["description"]=dStr, ["color"]=tonumber(col), ["fields"]=fields or {}, ["footer"]={["text"]="AshWish Autonomous System - "..os.date("%I:%M:%S %p")}}}}})
    ProcessWebhookQueue()
end

local trackerFileName = "ROTEX_LevelAnalytics.json"
local trackerData = {FarmingSeconds=0, LevelsGained=0, LifetimeLevelsGained=0, Logs={}}
pcall(function()
    if isfile and readfile and isfile(trackerFileName) then
        local d = HttpService:JSONDecode(readfile(trackerFileName))
        if d then trackerData.FarmingSeconds=d.FarmingSeconds or 0; trackerData.LevelsGained=d.LevelsGained or 0; trackerData.LifetimeLevelsGained=d.LifetimeLevelsGained or 0; trackerData.Logs=(type(d.Logs[1])~="string") and d.Logs or {} end
    end
end)
local function SaveTrackerData() pcall(function() if writefile then writefile(trackerFileName, HttpService:JSONEncode(trackerData)) end end) end

local function GetHistoricalAverage()
    if #trackerData.Logs == 0 then return 1000 end
    local sum = 0; local count = math.min(#trackerData.Logs, 5)
    for i = 1, count do sum = sum + (tonumber(trackerData.Logs[i]) or 0) end
    return sum / count
end

local function GetPerformanceRating(proj, hist)
    if hist <= 0 then hist = 1000 end
    local r = proj / hist
    if r>=1.50 then return "GOD TIER" elseif r>=1.10 then return "CRUSHING IT" elseif r>=0.85 then return "CONSISTENT" elseif r>=0.50 then return "SLUGGISH" else return "BROKEN AFK" end
end

local rollingGains, rollingSum = {}, 0

if CoreGui:FindFirstChild("SleekStatTracker") then CoreGui.SleekStatTracker:Destroy() end
local trackerGui = Instance.new("ScreenGui"); trackerGui.Name = "SleekStatTracker"; trackerGui.IgnoreGuiInset = true; trackerGui.Parent = CoreGui
local trackerFrame = Instance.new("Frame"); trackerFrame.Size = UDim2.new(0,280,0,105); trackerFrame.Position = UDim2.new(1,-290,0,10); trackerFrame.BackgroundColor3 = Color3.fromRGB(10,10,10); trackerFrame.BorderSizePixel = 0; trackerFrame.Active = true; trackerFrame.Draggable = true; trackerFrame.Parent = trackerGui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,6); corner.Parent = trackerFrame
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(80,80,80); stroke.Thickness = 2; stroke.Parent = trackerFrame
local statsLabel = Instance.new("TextLabel"); statsLabel.Size = UDim2.new(1,0,1,0); statsLabel.BackgroundTransparency = 1; statsLabel.TextColor3 = Color3.fromRGB(255,255,255); statsLabel.TextSize = 13; statsLabel.Font = Enum.Font.GothamMedium; statsLabel.TextXAlignment = Enum.TextXAlignment.Left; statsLabel.TextYAlignment = Enum.TextYAlignment.Top; statsLabel.Text = "Status: Idle\n\nWaiting to start..."; statsLabel.Parent = trackerFrame
local padding = Instance.new("UIPadding"); padding.PaddingLeft = UDim.new(0,10); padding.PaddingTop = UDim.new(0,10); padding.Parent = statsLabel

task.spawn(function()
    while task.wait(1) do
        if not statsLabel or not statsLabel.Parent then break end
        local tStr = FormatSessionTime(os.time() - sessionStartTime)
        if isFarming then
            local lvl = getLevel()
            local lg = lvl - startLevel
            local es = os.time() - startTime
            local lpm = (es/60)>0 and mFloor(lg/(es/60)) or 0
            local lph = (es/3600)>0 and mFloor(lg/(es/3600)) or 0
            statsLabel.Text = string.format("Status: ACTIVE\n\nTime Farmed This Session: %s\nLVL Gained: +%s\nLVL / Min: %s\nLVL / Hr:  %s", tStr, FormatNum(lg), FormatNum(lpm), FormatNum(lph))
        else
            statsLabel.Text = string.format("Status: IDLE\n\nTime Farmed This Session: %s\nWaiting to start...", tStr)
        end
    end
end)

local Window = Rayfield:CreateWindow({Name = "AshWish", LoadingTitle = "AshWish Loading", LoadingSubtitle = "Optimized Clean", ConfigurationSaving = {Enabled=false}, KeySystem = false})
local AutoFarmTab = Window:CreateTab("Auto Farming", 4483362458)
local ProtectionTab = Window:CreateTab("Protection", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local TrollTab = Window:CreateTab("Troll", 4483362458)
local AnalyticsTab = Window:CreateTab("Level Analytics", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local PlayerTab = Window:CreateTab("Player Settings", 4483362458)
local WebhookTab = Window:CreateTab("Discord Webhooks", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

local farmingThread, bossConnection = nil, nil
local function TeleportToBestDummy()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pLvl = getLevel()
    local bD = nil
    for i=#dummyData,1,-1 do if pLvl>=dummyData[i].Req then bD=dummyData[i]; break end end
    if bD then
        local obj = workspace:FindFirstChild("dummies") and workspace.dummies:FindFirstChild(bD.Name)
        if obj and obj:FindFirstChild("HumanoidRootPart") then
            local dHrp = obj.HumanoidRootPart
            if (hrp.Position - dHrp.Position).Magnitude > 15 then hrp.CFrame = dHrp.CFrame * cfNew(0,0,4) end
            hrp.CFrame = CFrame.lookAt(hrp.Position, v3New(dHrp.Position.X, hrp.Position.Y, dHrp.Position.Z))
        end
    end
end

AutoFarmTab:CreateSection("Auto Farm")
local FarmToggleObj = AutoFarmTab:CreateToggle({Name="Auto Farm All", CurrentValue=false, Flag="FarmToggle", Callback=function(Value)
    Toggles.GodFarm = Value; isFarming = Value
    if Value then
        startLevel = getLevel(); startTime = os.time()
        pcall(function()
            local npcFolder = workspace:FindFirstChild("Boss") and workspace.Boss:FindFirstChild("NPC") or workspace:FindFirstChild("NPC")
            if npcFolder then bossConnection = npcFolder.ChildAdded:Connect(function(obj) if Toggles.GodFarm and string.match(obj.Name:upper(), "BOSS") then local hum = obj:WaitForChild("Humanoid", 2); if hum and hum.Health>0 then ReplicatedStorage.DamageEvent:FireServer({["multiply"]=1, ["action"]="hit", ["enemyHum"]=hum}) end end end) end
        end)
        farmingThread = task.spawn(function()
            while Toggles.GodFarm do
                local char = localPlayer.Character
                local pLvl = getLevel()
                local bD = nil
                for i=#dummyData,1,-1 do if pLvl>=dummyData[i].Req then bD=dummyData[i]; break end end
                local targs = {}
                if bD then
                    local obj = workspace:FindFirstChild("dummies") and workspace.dummies:FindFirstChild(bD.Name)
                    if obj and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and Toggles.AutoTeleport then
                            if (hrp.Position - obj.HumanoidRootPart.Position).Magnitude > 15 then hrp.CFrame = obj.HumanoidRootPart.CFrame * cfNew(0,0,4) end
                            hrp.CFrame = CFrame.lookAt(hrp.Position, v3New(obj.HumanoidRootPart.Position.X, hrp.Position.Y, obj.HumanoidRootPart.Position.Z))
                        end
                        table.insert(targs, {hum=obj.Humanoid, mult=bD.Mult})
                    end
                end
                pcall(function()
                    local npcFolder = workspace:FindFirstChild("Boss") and workspace.Boss:FindFirstChild("NPC") or workspace:FindFirstChild("NPC")
                    if npcFolder then for _,obj in ipairs(npcFolder:GetChildren()) do if string.match(obj.Name:upper(), "BOSS") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health>0 then table.insert(targs, {hum=obj.Humanoid, mult=1}) end end end
                end)
                for _,targ in ipairs(targs) do if targ.hum.Health>0 then task.spawn(function() pcall(function() ReplicatedStorage.DamageEvent:FireServer({["multiply"]=targ.mult, ["action"]="hit", ["enemyHum"]=targ.hum}) end) end) end end
                task.wait(math.random(5,10)/100) 
            end
        end)
    else
        if farmingThread then task.cancel(farmingThread); farmingThread=nil end
        if bossConnection then bossConnection:Disconnect(); bossConnection=nil end
    end
end})

local TeleportToggleObj = AutoFarmTab:CreateToggle({Name="Auto Teleport To Dummy", CurrentValue=false, Flag="TeleportToggle", Callback=function(Value) Toggles.AutoTeleport = Value; if Value then TeleportToBestDummy() end end})

ProtectionTab:CreateSection("Network & Client Safety")
local AutoReconnectToggleObj = ProtectionTab:CreateToggle({Name="Instant Auto Reconnect", CurrentValue=false, Flag="AutoReconnectToggle", Callback=function(Value) Toggles.AutoReconnect = Value end})
local AntiLagToggleObj = ProtectionTab:CreateToggle({Name="Anti Lag Server Hop", CurrentValue=false, Flag="AntiLagToggle", Callback=function(Value) Toggles.AntiLag = Value; if Value then task.spawn(function() while Toggles.AntiLag do pcall(function() local pingStr = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString(); local curPing = tonumber(string.match(pingStr, "%d+")); if curPing and curPing>=750 then SendEmergencyPing("SEVERE LAG - HOPPING SERVERS", "Ping spiked.", tonumber(0x800080)); WriteHopState(); task.wait(1); TeleportService:Teleport(game.PlaceId, localPlayer) end end); task.wait(5) end end) end end})
local AntiModToggleObj = ProtectionTab:CreateToggle({Name="Anti Mod Server Hop", CurrentValue=false, Flag="AntiModToggle", Callback=function(Value) Toggles.AntiMod = Value end})
local AntiAfkToggleObj = ProtectionTab:CreateToggle({Name="Anti AFK", CurrentValue=false, Flag="AntiCheatFix", Callback=function(Value) Toggles.VirtualTap = Value end})
ProtectionTab:CreateButton({Name="FPS Booster", Callback=function() AdvancedFPSBoost(); Rayfield:Notify({Title="FPS Boosted", Content="All heavy rendering systems disabled.", Duration=3}) end})

localPlayer.Idled:Connect(function() if Toggles.VirtualTap then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()); VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game) end end)
Players.PlayerAdded:Connect(function(plr) if Toggles.AntiMod then if plr:GetRankInGroup(game.CreatorId)>0 or string.match(plr.Name:lower(), "admin") then SendEmergencyPing("MOD DETECTED", "Developer joined.", tonumber(0xFF0000)); WriteHopState(); task.wait(1); TeleportService:Teleport(game.PlaceId, localPlayer) end end end)

task.spawn(function()
    local reconnecting = false
    local function forceRejoin() if reconnecting then return end; reconnecting = true; SendEmergencyPing("DISCONNECT - REJOINING", "Error detected.", tonumber(0xFFA500)); WriteHopState(); task.spawn(function() while task.wait(5) do pcall(function() TeleportService:Teleport(game.PlaceId, localPlayer) end) end end) end
    pcall(function() GuiService.ErrorMessageChanged:Connect(function() if Toggles.AutoReconnect then local err = GuiService:GetErrorCode(); if err and err.Value ~= 0 then forceRejoin() end end end) end)
    pcall(function() CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child) if Toggles.AutoReconnect and child.Name == "ErrorPrompt" then forceRejoin() end end) end)
    pcall(function() LogService.MessageOut:Connect(function(Message, Type) if Toggles.AutoReconnect and Type == Enum.MessageType.MessageError then local lMsg = string.lower(Message); if string.find(lMsg, "disconnect") or string.find(lMsg, "kicked") then forceRejoin() end end end) end)
end)

local espThread, espObjects, hitboxSize, hitboxThread, originalSizes = nil, {}, 10, nil, {}
CombatTab:CreateSection("Hitbox")
local function RestoreHitboxes() for char, data in pairs(originalSizes) do pcall(function() local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp then hrp.Size = data.Size; hrp.Transparency = data.Transparency; hrp.CanCollide = data.CanCollide; if hrp:FindFirstChild("HitboxOutline") then hrp.HitboxOutline:Destroy() end end end) end; originalSizes = {} end
CombatTab:CreateInput({Name="Hitbox Size", PlaceholderText="Type size", RemoveTextAfterFocusLost=false, Callback=function(Text) local val=tonumber(Text); if val then hitboxSize=val end end})
CombatTab:CreateToggle({Name="Enable Hitbox Expander", CurrentValue=false, Flag="HitboxToggle", Callback=function(Value) if Value then hitboxThread=task.spawn(function() while true do for _,plr in ipairs(Players:GetPlayers()) do if plr~=localPlayer and plr.Character then local char=plr.Character; local hrp=char:FindFirstChild("HumanoidRootPart"); if hrp then if not originalSizes[char] then originalSizes[char]={Size=hrp.Size, Transparency=hrp.Transparency, CanCollide=hrp.CanCollide} end; pcall(function() hrp.Size=v3New(hitboxSize,hitboxSize,hitboxSize); hrp.Transparency=0.8; hrp.CanCollide=false; if not hrp:FindFirstChild("HitboxOutline") then local ol=Instance.new("SelectionBox"); ol.Name="HitboxOutline"; ol.Adornee=hrp; ol.LineThickness=0.05; ol.Color3=Color3.fromRGB(255,255,255); ol.SurfaceTransparency=0.9; ol.SurfaceColor3=Color3.fromRGB(255,255,255); ol.Parent=hrp end end) end end end; task.wait(0.1) end end) else if hitboxThread then task.cancel(hitboxThread); hitboxThread=nil end; RestoreHitboxes() end end})

CombatTab:CreateSection("Kill Aura")
local selectedAuraPlayer, auraThread = nil, nil
local AuraDropdown = CombatTab:CreateDropdown({Name="Select Target", Options={"None"}, CurrentOption={"None"}, MultipleOptions=false, Callback=function(Option) selectedAuraPlayer = Option[1] end})
CombatTab:CreateButton({Name="Refresh Player List", Callback=function() local list = {}; for _, plr in ipairs(Players:GetPlayers()) do if plr~=localPlayer then table.insert(list, plr.Name) end end; if #list==0 then table.insert(list, "None") end; AuraDropdown:Refresh(list, true) end})

local function ManageKillAura()
    if Toggles.NormalKillAura or Toggles.AttachKillAura then
        if auraThread then task.cancel(auraThread) end
        auraThread = task.spawn(function()
            while Toggles.NormalKillAura or Toggles.AttachKillAura do
                if selectedAuraPlayer and selectedAuraPlayer ~= "None" then
                    local targ = Players:FindFirstChild(selectedAuraPlayer)
                    if targ and targ.Character and targ.Character:FindFirstChild("HumanoidRootPart") and targ.Character:FindFirstChild("Humanoid") and targ.Character.Humanoid.Health>0 then
                        KillAuraTargetHrp = targ.Character.HumanoidRootPart
                        local myHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if Toggles.AttachKillAura and myHrp then myHrp.CFrame = KillAuraTargetHrp.CFrame * cfNew(0,15,0); myHrp.CFrame = CFrame.lookAt(myHrp.Position, KillAuraTargetHrp.Position) end
                        pcall(function() ReplicatedStorage.DamageEvent:FireServer({["multiply"]=1, ["action"]="hit", ["enemyHum"]=targ.Character.Humanoid}) end)
                    else KillAuraTargetHrp = nil end
                else KillAuraTargetHrp = nil end
                task.wait(0.1)
            end
        end)
    else KillAuraTargetHrp = nil; if auraThread then task.cancel(auraThread); auraThread = nil end end
end

CombatTab:CreateToggle({Name="Normal Kill Aura", CurrentValue=false, Flag="NormalAuraToggle", Callback=function(Value) Toggles.NormalKillAura = Value; ManageKillAura() end})
CombatTab:CreateToggle({Name="Attach Kill Aura", CurrentValue=false, Flag="AttachAuraToggle", Callback=function(Value) Toggles.AttachKillAura = Value; ManageKillAura() end})
task.spawn(function() local list={}; for _, plr in ipairs(Players:GetPlayers()) do if plr~=localPlayer then table.insert(list, plr.Name) end end; if #list==0 then table.insert(list, "None") end; AuraDropdown:Refresh(list, true) end)

CombatTab:CreateSection("ESP")
local function ClearEsp() for _, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end; espObjects = {} end
CombatTab:CreateToggle({Name="Player ESP", CurrentValue=false, Flag="EspToggle", Callback=function(Value) if Value then espThread=task.spawn(function() while true do ClearEsp(); for _, plr in ipairs(Players:GetPlayers()) do if plr~=localPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then local char=plr.Character; local hum=char:FindFirstChild("Humanoid"); pcall(function() local hl=Instance.new("Highlight"); hl.Adornee=char; hl.FillColor=sharedVisualColor; hl.OutlineColor=sharedVisualColor; hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Parent=char; table.insert(espObjects, hl) end); pcall(function() local bgui=Instance.new("BillboardGui"); bgui.Name="EspInfo"; bgui.Adornee=char:FindFirstChild("Head") or char.HumanoidRootPart; bgui.Size=UDim2.new(0,100,0,40); bgui.StudsOffset=Vector3.new(0,2.5,0); bgui.AlwaysOnTop=true; local txt=Instance.new("TextLabel"); txt.Size=UDim2.new(1,0,1,0); txt.BackgroundTransparency=1; txt.TextColor3=Color3.fromRGB(255,255,255); txt.TextStrokeTransparency=0; txt.TextSize=11; txt.Font=Enum.Font.GothamBold; local lvl=plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Level") and plr.leaderstats.Level.Value or 0; local hp=hum and math.floor(hum.Health) or 0; local maxHp=hum and math.floor(hum.MaxHealth) or 0; txt.Text=string.format("Lv. %s %s\nHP: %s / %s", FormatNum(lvl), plr.Name, FormatNum(hp), FormatNum(maxHp)); txt.Parent=bgui; bgui.Parent=char; table.insert(espObjects, bgui) end) end end; task.wait(1) end end) else if espThread then task.cancel(espThread); espThread=nil end; ClearEsp() end end})
CombatTab:CreateToggle({Name="Rainbow ESP Color", CurrentValue=false, Flag="RainbowEspToggle", Callback=function(Value) rainbowVisuals = Value; if not Value then sharedVisualColor = Color3.fromRGB(255,50,50) end end})
CombatTab:CreateColorPicker({Name="ESP Color", Color=Color3.fromRGB(255,50,50), Flag="EspColorPicker", Callback=function(Value) if not rainbowVisuals then sharedVisualColor = Value end end})

---------------------------------------------------------
-- 4. TROLL TAB
---------------------------------------------------------
local orbitAngle, randomOrbitAngle, trollTargetPlayer, randomOrbitTarget = 0, 0, "None", nil

TrollTab:CreateSection("Fake Badges (Client-Sided)")
local currentFakeRank, fakeRankGui = "None", nil
local rankImages = {["Rank 1-10 Badge"]="rbxassetid://13321938624", ["Rank 11-30 Badge"]="rbxassetid://13321938398", ["Rank 31-70 Badge"]="rbxassetid://13321938232", ["Rank 71-100 Badge"]="rbxassetid://13321938751"}
local function applyFakeRank() task.spawn(function() pcall(function() if currentFakeRank=="None" then if fakeRankGui then fakeRankGui:Destroy() end; return end; local char=localPlayer.Character; if not char then return end; local head=char:WaitForChild("Head",5); if not head then return end; if fakeRankGui then fakeRankGui:Destroy() end; fakeRankGui=Instance.new("BillboardGui"); fakeRankGui.Name="FakeRankBadge"; fakeRankGui.Adornee=head; fakeRankGui.Size=UDim2.new(3,0,3,0); fakeRankGui.StudsOffset=Vector3.new(0,4,0); fakeRankGui.AlwaysOnTop=true; fakeRankGui.MaxDistance=250; local img=Instance.new("ImageLabel"); img.Parent=fakeRankGui; img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1; img.Image=rankImages[currentFakeRank] or ""; img.ScaleType=Enum.ScaleType.Fit; fakeRankGui.Parent=head end) end) end
localPlayer.CharacterAdded:Connect(function(char) task.spawn(function() task.wait(2); applyFakeRank() end) end)
TrollTab:CreateDropdown({Name="Fake Leaderboard Badge (Client-Sided)", Options={"None","Rank 1-10 Badge","Rank 11-30 Badge","Rank 31-70 Badge","Rank 71-100 Badge"}, CurrentOption={"None"}, MultipleOptions=false, Flag="FakeRankBadgeDropdown", Callback=function(Option) currentFakeRank = Option[1]; applyFakeRank() end})

TrollTab:CreateSection("Target Selection")
local TrollDropdown = TrollTab:CreateDropdown({Name="Select Target", Options={"None"}, CurrentOption={"None"}, MultipleOptions=false, Callback=function(Option) trollTargetPlayer = Option[1] end})
TrollTab:CreateButton({Name="Refresh Player List", Callback=function() local list={}; for _,plr in ipairs(Players:GetPlayers()) do if plr~=localPlayer then table.insert(list, plr.Name) end end; if #list==0 then table.insert(list, "None") end; TrollDropdown:Refresh(list, true) end})

TrollTab:CreateSection("Annoy Players")
TrollTab:CreateToggle({Name="Orbit Target", CurrentValue=false, Flag="OrbitToggle", Callback=function(Value) Toggles.UFOOrbit = Value end})
TrollTab:CreateToggle({Name="Bang Player", CurrentValue=false, Flag="BangToggle", Callback=function(Value) Toggles.BangPlayer = Value end})
TrollTab:CreateToggle({Name="Follow Behind Target", CurrentValue=false, Flag="FollowBehindToggle", Callback=function(Value) Toggles.FollowBehind = Value end})

TrollTab:CreateSection("Server Annoyances")
task.spawn(function() while task.wait(0.05) do if Toggles.ServerSpooker then local plrs=Players:GetPlayers(); if #plrs>1 then local rPlr=plrs[math.random(1,#plrs)]; if rPlr~=localPlayer and rPlr.Character and rPlr.Character:FindFirstChild("HumanoidRootPart") then local char=localPlayer.Character; if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = rPlr.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,2) end end end end end end)
TrollTab:CreateToggle({Name="Flicker Around Map", CurrentValue=false, Flag="ServerSpookerToggle", Callback=function(Value) Toggles.ServerSpooker = Value end})
task.spawn(function() while task.wait(3) do if Toggles.OrbitRandom then local plrs=Players:GetPlayers(); if #plrs>1 then randomOrbitTarget=plrs[math.random(1,#plrs)]; if randomOrbitTarget==localPlayer then randomOrbitTarget=nil end end else randomOrbitTarget=nil end end end)
TrollTab:CreateToggle({Name="Orbit Random Players", CurrentValue=false, Flag="OrbitRandomToggle", Callback=function(Value) Toggles.OrbitRandom = Value end})

TrollTab:CreateSection("Self Trolls")
TrollTab:CreateToggle({Name="Fast Spin", CurrentValue=false, Flag="SeizureSpinToggle", Callback=function(Value) Toggles.SeizureSpin = Value end})
TrollTab:CreateToggle({Name="Jitter Walk", CurrentValue=false, Flag="JitterWalkToggle", Callback=function(Value) Toggles.JitterWalk = Value end})
TrollTab:CreateToggle({Name="Enable Noclip", CurrentValue=false, Flag="NoclipToggle", Callback=function(Value) Toggles.Noclip = Value end})

RunService.Stepped:Connect(function()
    if Toggles.Noclip then
        local char = localPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(11) end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if rainbowVisuals then sharedVisualColor = Color3.fromHSV(os.clock()%4/4, 1, 1) end
    local char = localPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if Toggles.SeizureSpin then hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(math.random(1,360)), math.rad(math.random(1,360)), math.rad(math.random(1,360))) end
        if Toggles.JitterWalk then hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-1,1)*0.5, 0, math.random(-1,1)*0.5) end
    end
    if trollTargetPlayer and trollTargetPlayer ~= "None" then
        local target = Players:FindFirstChild(trollTargetPlayer); local tHrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if tHrp and hrp then
            if Toggles.UFOOrbit then orbitAngle=orbitAngle+0.4; hrp.CFrame = CFrame.lookAt(tHrp.Position + Vector3.new(math.cos(orbitAngle)*5, 0, math.sin(orbitAngle)*5), tHrp.Position) end
            if Toggles.BangPlayer then hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 1.5+(math.sin(tick()*15)*4)) end
            if Toggles.FollowBehind then hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3) end
        end
    end
    if Toggles.OrbitRandom and randomOrbitTarget then
        local rHrp = randomOrbitTarget.Character and randomOrbitTarget.Character:FindFirstChild("HumanoidRootPart")
        if rHrp and hrp then randomOrbitAngle=randomOrbitAngle+0.4; hrp.CFrame = CFrame.lookAt(rHrp.Position + Vector3.new(math.cos(randomOrbitAngle)*5, 0, math.sin(randomOrbitAngle)*5), rHrp.Position) end
    end
end)

---------------------------------------------------------
-- 5. LEVEL ANALYTICS TAB
---------------------------------------------------------
local CustomTargetLevel, CustomTargetHours = 0, 0
local LiveStatsPara = AnalyticsTab:CreateParagraph({Title="Live Analytics Projections", Content="Loading live data..."})
AnalyticsTab:CreateSection("Goal Calculator")
local GoalResultPara = AnalyticsTab:CreateParagraph({Title="Estimated Time", Content="Awaiting input..."})
AnalyticsTab:CreateInput({Name="Target Level", PlaceholderText="e.g. 1000000 or 1m", RemoveTextAfterFocusLost=false, Callback=function(Text) CustomTargetLevel=ParseNumber(Text) end})
AnalyticsTab:CreateSection("Time Calculator")
local TimeMachinePara = AnalyticsTab:CreateParagraph({Title="Projected Level", Content="Awaiting input..."})
AnalyticsTab:CreateInput({Name="Hours to Farm", PlaceholderText="e.g. 72 or 10", RemoveTextAfterFocusLost=false, Callback=function(Text) CustomTargetHours=ParseNumber(Text) end})

AnalyticsTab:CreateSection("History")
if #trackerData.Logs == 0 then AnalyticsTab:CreateParagraph({Title="No History Yet", Content="Finish a full 24 hours of Auto Farming to generate a log."})
else for i, pastLevels in ipairs(trackerData.Logs) do AnalyticsTab:CreateParagraph({Title="Day "..tostring(i).." History", Content="Levels Gained: "..FormatNum(tonumber(pastLevels) or 0)}) end end

local lastTrackedLevel, badPerformanceSeconds, displaySecondsToMilestone = 0, 0, 0
task.spawn(function()
    while task.wait(1) do
        local currentLvl = getLevel()
        if isFarming then
            if lastTrackedLevel==0 or currentLvl<lastTrackedLevel then lastTrackedLevel=currentLvl end
            local diff = currentLvl - lastTrackedLevel; if diff>5 then diff=0 end
            if diff>0 then trackerData.LevelsGained=trackerData.LevelsGained+diff; trackerData.LifetimeLevelsGained=trackerData.LifetimeLevelsGained+diff; lastTrackedLevel=currentLvl end
            table.insert(rollingGains, diff); rollingSum=rollingSum+diff; if #rollingGains>300 then rollingSum=rollingSum-table.remove(rollingGains, 1) end
            trackerData.FarmingSeconds=trackerData.FarmingSeconds+1; if trackerData.FarmingSeconds%60==0 then SaveTrackerData() end
        else lastTrackedLevel=0 end

        local hrs=mFloor(trackerData.FarmingSeconds/3600); local mins=mFloor((trackerData.FarmingSeconds%3600)/60); local secs=trackerData.FarmingSeconds%60
        local currentLvlPerSec = trackerData.FarmingSeconds>0 and (trackerData.LevelsGained/trackerData.FarmingSeconds) or 0
        local projected24h = currentLvlPerSec * 86400
        local currentRating = GetPerformanceRating(projected24h, GetHistoricalAverage())

        if isFarming and (currentRating=="BROKEN AFK" or currentRating=="SLUGGISH") then badPerformanceSeconds=badPerformanceSeconds+1; if badPerformanceSeconds==300 then SendSystemWebhook("Efficiency Drop Detected", "Performance dropped. Check server!", 0xFF0000); SendEmergencyPing("EFFICIENCY DROP DETECTED", "Performance dropped. Script may be stuck.", tonumber(0xFF0000)) end elseif isFarming then badPerformanceSeconds=0 end

        if trackerData.FarmingSeconds >= 86400 then
            SendSystemWebhook("Daily Recap: Auto Farm", "Daily stats logged.", 0xFFD700, {{["name"]="Player", ["value"]=localPlayer.Name, ["inline"]=false}, {["name"]="Rating", ["value"]=currentRating, ["inline"]=false}, {["name"]="24H Gain", ["value"]="+"..FormatNum(trackerData.LevelsGained), ["inline"]=true}, {["name"]="Peak Speed", ["value"]=FormatNum(PeakLevelsPerHour).." Lvl/Hr", ["inline"]=true}, {["name"]="Lifetime Levels", ["value"]=FormatNum(trackerData.LifetimeLevelsGained), ["inline"]=false}})
            table.insert(trackerData.Logs, 1, trackerData.LevelsGained); if #trackerData.Logs>15 then table.remove(trackerData.Logs, 16) end 
            trackerData.FarmingSeconds=0; trackerData.LevelsGained=0; PeakLevelsPerHour=0; rollingSum=0; rollingGains={}; SaveTrackerData()
        end

        local sustainedLPH = #rollingGains>0 and mFloor((rollingSum/#rollingGains)*3600) or 0; if sustainedLPH>PeakLevelsPerHour then PeakLevelsPerHour=sustainedLPH end
        local mStep=10000; local nextMilestone=math.ceil((currentLvl+1)/mStep)*mStep; local actSecs = currentLvlPerSec>0 and ((nextMilestone-currentLvl)/currentLvlPerSec) or 0
        if displaySecondsToMilestone==0 or math.abs(displaySecondsToMilestone-actSecs)>15 then displaySecondsToMilestone=actSecs elseif isFarming and currentLvlPerSec>0 then displaySecondsToMilestone=math.max(0, displaySecondsToMilestone-1) end

        local function FormatTimeFriendly(ts) if ts<=0 or ts==math.huge then return "Calculating..." end; local d=mFloor(ts/86400); local h=mFloor((ts%86400)/3600); local m=mFloor((ts%3600)/60); local s=mFloor(ts%60); if d>0 then return string.format("%d Days, %d Hours, %d Mins",d,h,m) elseif h>0 then return string.format("%d Hours, %d Mins, %d Secs",h,m,s) else return string.format("%d Mins, %d Secs",m,s) end end

        LiveStatsPara:Set({Title="Live Analytics Projections", Content=string.format("Time Farmed Today: %02d:%02d:%02d\nLevels Gained: %s\nLifetime Levels: %s\n\nStatus: %s\nPeak Speed: %s Levels / Hr\n\nProjections:\n- 1 Day: +%s\n- 1 Week: +%s\n- 1 Month: +%s\n\nNext Level Milestone: %s\n%s", hrs, mins, secs, FormatNum(trackerData.LevelsGained), FormatNum(trackerData.LifetimeLevelsGained), currentRating, FormatNum(PeakLevelsPerHour), FormatNum(projected24h), FormatNum(projected24h*7), FormatNum(projected24h*30), FormatNum(nextMilestone), FormatTimeFriendly(displaySecondsToMilestone))})

        if isFarming and CustomTargetLevel>currentLvl then local actTargTime = currentLvlPerSec>0 and ((CustomTargetLevel-currentLvl)/currentLvlPerSec) or 0; if displaySecondsToTarget==0 or math.abs(displaySecondsToTarget-actTargTime)>15 then displaySecondsToTarget=actTargTime else displaySecondsToTarget=math.max(0, displaySecondsToTarget-1) end; GoalResultPara:Set({Title="Time to Level "..FormatNum(CustomTargetLevel), Content=FormatTimeFriendly(displaySecondsToTarget)}) elseif CustomTargetLevel>0 then displaySecondsToTarget=0; GoalResultPara:Set({Title="Estimated Time", Content="Start farming to calculate ETA."}) end
        if isFarming and CustomTargetHours>0 then TimeMachinePara:Set({Title="Projection Level in "..CustomTargetHours.."h", Content="Level "..FormatNum(currentLvl+mFloor(currentLvlPerSec*(CustomTargetHours*3600)))}) elseif CustomTargetHours>0 then TimeMachinePara:Set({Title="Projected Level", Content="Start farming to calculate projection."}) end
    end
end)

---------------------------------------------------------
-- 6. DISCORD WEBHOOKS TAB 
---------------------------------------------------------
local hasSentUserExecutionLog = false 
WebhookTab:CreateParagraph({Title="Auto Webhook is ACTIVE", Content="Your stats are automatically being sent every 10 minutes to your Discord."})
local function SendUserWebhook()
    local curLvl = getLevel(); local lvlGain = isFarming and (curLvl - startLevel) or 0; local es = isFarming and (os.time() - startTime) or 0
    local lpm = (es/60)>0 and mFloor(lvlGain/(es/60)) or 0; local lph = (es/3600)>0 and mFloor(lvlGain/(es/3600)) or 0
    local embeds = {}
    if not hasSentUserExecutionLog then table.insert(embeds, {["title"]="INIT AshWish Script Executed", ["color"]=tonumber(0x00AFFF), ["fields"]={{["name"]="Player", ["value"]=localPlayer.Name, ["inline"]=true}, {["name"]="Executions", ["value"]=tostring(execCount), ["inline"]=true}}, ["footer"]={["text"]="Execution Log - "..os.date("%I:%M:%S %p")}}); hasSentUserExecutionLog = true end
    table.insert(embeds, {["title"]="Auto Farm Stats", ["color"]=tonumber(0x00FF00), ["fields"]={{["name"]="Player", ["value"]=localPlayer.Name, ["inline"]=false}, {["name"]="Current Level", ["value"]=FormatNum(curLvl), ["inline"]=true}, {["name"]="Levels Gained", ["value"]="+"..FormatNum(lvlGain), ["inline"]=false}, {["name"]="Levels/Min", ["value"]=FormatNum(lpm), ["inline"]=true}, {["name"]="Levels/Hr", ["value"]=FormatNum(lph), ["inline"]=true}}, ["footer"]={["text"]="AshWish UI - "..os.date("%I:%M:%S %p")}})
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if httprequest then pcall(function() httprequest({Url=UserWebhookURL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=HttpService:JSONEncode({["username"]=localPlayer.Name.." System", ["embeds"]=embeds})}) end) end
end
task.spawn(function() task.wait(5); SendUserWebhook(); while true do task.wait(600); SendUserWebhook() end end)
WebhookTab:CreateButton({Name="Test Webhook Now", Callback=function() SendUserWebhook() end})

---------------------------------------------------------
-- 7. TELEPORT TAB
---------------------------------------------------------
TeleportTab:CreateSection("Refresh Player List")
local selectedTeleportPlayer = nil
local TeleportDropdown = TeleportTab:CreateDropdown({Name="Select Player", Options={"None"}, CurrentOption={"None"}, MultipleOptions=false, Callback=function(Option) selectedTeleportPlayer = Option[1] end})
TeleportTab:CreateButton({Name="Refresh Players", Callback=function() local list={}; for _, plr in ipairs(Players:GetPlayers()) do if plr~=localPlayer then table.insert(list, plr.Name) end end; if #list==0 then table.insert(list, "None") end; TeleportDropdown:Refresh(list, true) end})
TeleportTab:CreateSection("Teleport Action")
TeleportTab:CreateButton({Name="Teleport to Selected Player", Callback=function() if selectedTeleportPlayer and selectedTeleportPlayer~="None" then local tChar=Players:FindFirstChild(selectedTeleportPlayer) and Players:FindFirstChild(selectedTeleportPlayer).Character; local myChar=localPlayer.Character; if tChar and myChar and tChar:FindFirstChild("HumanoidRootPart") and myChar:FindFirstChild("HumanoidRootPart") then myChar.HumanoidRootPart.CFrame = tChar.HumanoidRootPart.CFrame * cfNew(0,0,3) end end end})
task.spawn(function() local list={}; for _, plr in ipairs(Players:GetPlayers()) do if plr~=localPlayer then table.insert(list, plr.Name) end end; if #list==0 then table.insert(list, "None") end; TeleportDropdown:Refresh(list, true) end)

---------------------------------------------------------
-- 8. PLAYER SETTINGS TAB
---------------------------------------------------------
PlayerTab:CreateSection("Player Movement")
local customWalkSpeed, customJumpPower, enforceMovement = 16, 50, false
local wsSlider = PlayerTab:CreateSlider({Name="Walkspeed", Range={1,500}, Increment=1, Suffix="Speed", CurrentValue=16, Flag="WalkspeedSlider", Callback=function(Value) if not enforceMovement then return end; customWalkSpeed=Value; if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then localPlayer.Character.Humanoid.WalkSpeed = Value end end})
local jpSlider = PlayerTab:CreateSlider({Name="Jump Power", Range={1,500}, Increment=1, Suffix="Power", CurrentValue=50, Flag="JumpPowerSlider", Callback=function(Value) if not enforceMovement then return end; customJumpPower=Value; if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then localPlayer.Character.Humanoid.UseJumpPower=true; localPlayer.Character.Humanoid.JumpPower=Value end end})
wsSlider.Callback = function(Value) customWalkSpeed=Value; enforceMovement=true end
jpSlider.Callback = function(Value) customJumpPower=Value; enforceMovement=true end
PlayerTab:CreateButton({Name="Reset Speed and Jump Power", Callback=function() enforceMovement=false; if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then local hum=localPlayer.Character.Humanoid; hum.WalkSpeed=16; hum.JumpPower=50 end; task.spawn(function() wsSlider:Set(16); jpSlider:Set(50); enforceMovement=false end) end})
task.spawn(function() while task.wait(0.1) do if enforceMovement and localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then local hum=localPlayer.Character.Humanoid; if hum.WalkSpeed<=16 or hum.WalkSpeed==customWalkSpeed then hum.WalkSpeed=customWalkSpeed end; hum.UseJumpPower=true; hum.JumpPower=customJumpPower end end end)

PlayerTab:CreateSection("Avatar Modifications (Client-Sided)")
PlayerTab:CreateToggle({Name="Fake Korblox", CurrentValue=false, Flag="FakeKorbloxToggle", Callback=function(Value)
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
                    fake.Size = Vector3.new(1, 2, 1) 
                    fake.Anchored = false
                    fake.CanCollide = false
                    fake.Massless = true
                    fake.Transparency = 0
                    
                    local mesh = fake:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh")
                    mesh.MeshType = Enum.MeshType.FileMesh 
                    mesh.MeshId = "rbxassetid://11142517551"
                    mesh.TextureId = "rbxassetid://11142513476"
                    mesh.Scale = Vector3.new(1, 1, 1)
                    mesh.Parent = fake
                    
                    local weld = fake:FindFirstChildOfClass("WeldConstraint") or Instance.new("WeldConstraint")
                    weld.Part0 = rightUpperLeg
                    weld.Part1 = fake
                    weld.Parent = fake
                    
                    fake.CFrame = rightUpperLeg.CFrame * CFrame.new(0, -0.25, 0)
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
end})

PlayerTab:CreateToggle({Name="Fake Headless", CurrentValue=false, Flag="FakeHeadlessToggle", Callback=function(Value) pcall(function() local char=localPlayer.Character; if char and char:FindFirstChild("Head") then if Value then char.Head.Transparency=1; if char.Head:FindFirstChild("face") then char.Head.face.Transparency=1 end else char.Head.Transparency=0; if char.Head:FindFirstChild("face") then char.Head.face.Transparency=0 end end end end) end})

---------------------------------------------------------
-- 9. MISC TAB
---------------------------------------------------------
MiscTab:CreateButton({Name="Hide or Show Black Tracker UI", Callback=function() if trackerGui then trackerGui.Enabled = not trackerGui.Enabled end end})
MiscTab:CreateButton({Name="Destroy Script and UI", Callback=function() isFarming=false; Toggles={}; if farmingThread then task.cancel(farmingThread); farmingThread=nil end; if espThread then task.cancel(espThread); espThread=nil end; if auraThread then task.cancel(auraThread); auraThread=nil end; if hitboxThread then task.cancel(hitboxThread); hitboxThread=nil end; if bossConnection then bossConnection:Disconnect(); bossConnection=nil end; ClearEsp(); RestoreHitboxes(); if fakeRankGui then pcall(function() fakeRankGui:Destroy() end) end; if trackerGui then trackerGui:Destroy() end; Rayfield:Destroy() end})
MiscTab:CreateButton({Name="Infinite Yield", Callback=function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Infinite-yield-73483"))() end})
MiscTab:CreateButton({Name="Server Hop", Callback=function() local PlaceID=game.PlaceId; local AllIDs={}; pcall(function() local Site=HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/'..PlaceID..'/servers/Public?sortOrder=Asc&limit=100')); for _, server in pairs(Site.data) do if server.playing<server.maxPlayers and server.id~=game.JobId then table.insert(AllIDs, server.id) end end end); if #AllIDs>0 then local randomServer=AllIDs[math.random(1,#AllIDs)]; TeleportService:TeleportToPlaceInstance(PlaceID, randomServer, localPlayer) end end})
MiscTab:CreateButton({Name="Rejoin Same Server", Callback=function() Rayfield:Notify({Title="Rejoining", Content="Routing back...", Duration=3}); TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer) end})
if isPC then local altClickTP=false; MiscTab:CreateToggle({Name="Left Alt Left Click TP", CurrentValue=false, Flag="AltClickTPToggle", Callback=function(Value) altClickTP=Value end}); UserInputService.InputBegan:Connect(function(input, gameProcessed) if altClickTP and input.UserInputType==Enum.UserInputType.MouseButton1 then if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then local targetPos=mouse.Hit.Position; localPlayer.Character.HumanoidRootPart.CFrame = cfNew(targetPos.X, targetPos.Y+3, targetPos.Z) end end end end) end

Rayfield:Notify({Title = "AshWish Injected", Content = "All failsafes active.", Duration = 5, Image = 4483362458})

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
        
        -- SMART WAIT
        local timeOut = 0
        while timeOut < 40 do
            local bp = localPlayer:FindFirstChild("Backpack")
            if char:FindFirstChild("Waterbeam") or (bp and bp:FindFirstChild("Waterbeam")) then break end
            task.wait(0.5); timeOut = timeOut + 1
        end
        task.wait(2.5) 
        
        pcall(function() if FarmToggleObj then FarmToggleObj:Set(true) end end); task.wait(0.2)
        pcall(function() if TeleportToggleObj then TeleportToggleObj:Set(true) end end); task.wait(0.2)
        pcall(function() if AntiAfkToggleObj then AntiAfkToggleObj:Set(true) end end); task.wait(0.2)
        pcall(function() if AutoReconnectToggleObj then AutoReconnectToggleObj:Set(true) end end); task.wait(0.2)
        pcall(function() if AntiLagToggleObj then AntiLagToggleObj:Set(true) end end); task.wait(0.2)
        pcall(function() if AntiModToggleObj then AntiModToggleObj:Set(true) end end)
        AdvancedFPSBoost()
        
        task.wait(15)
        pcall(function()
            local containers = {CoreGui, localPlayer:WaitForChild("PlayerGui")}
            if gethui then table.insert(containers, gethui()) end
            for _, c in pairs(containers) do if c then for _, gui in pairs(c:GetChildren()) do if gui:IsA("ScreenGui") then local main = gui:FindFirstChild("Main") or gui:FindFirstChild("Rayfield"); if main and main:IsA("Frame") and main.Size.Y.Offset > 100 then main.Visible = false end end end end end
            task.wait(1)
            local vim = game:GetService("VirtualInputManager"); local cam = workspace.CurrentCamera; local centerX, centerY = cam.ViewportSize.X/2, cam.ViewportSize.Y/2
            vim:SendTouchEvent(1, 0, centerX, centerY); task.wait(0.1); vim:SendTouchEvent(1, 1, centerX, centerY)
        end)
    end)
end
