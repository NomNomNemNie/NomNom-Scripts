-- visual.lua

return function(ctx, misc)
    local Services = ctx.Services
    local Players = Services.Players
    local RunService = Services.RunService
    local CAS = Services.CAS
    local UIS = Services.UIS
    local State = ctx.State
    local Player = ctx.Player
    local playerGui = ctx.playerGui
    local PLACE_ID = ctx.PLACE_ID
    local JOB_ID = ctx.JOB_ID

    local M = {}

    local function getLocalHumanoid() return misc.getLocalHumanoid() end
    local function getLocalHRP() return misc.getLocalHRP() end
    local function getPlayerByName(name) return misc.getPlayerByName(name) end
    local function showRobloxNotification(a, b) return misc.showRobloxNotification(a, b) end

    -- Stats overlay
    local statsGui, statsFrame, statsTitle, fpsLabel, pingLabel, playersLabel, placeLabel, jobLabel, uptimeLabel, execLabel
    local statsConn, dragConnBegan, dragConnChanged, dragConnEnded
    local function ensureStatsPanel()
        if statsGui and statsGui.Parent then return end

        statsGui = Instance.new("ScreenGui")
        statsGui.Name = "NomNom_StatsPanel"
        statsGui.ResetOnSpawn = false
        statsGui.Parent = playerGui

        statsFrame = Instance.new("Frame")
        statsFrame.Name = "Panel"
        statsFrame.Size = UDim2.fromOffset(300, 160)
        statsFrame.Position = UDim2.fromOffset(10, 10)
        statsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        statsFrame.BackgroundTransparency = 0.2
        statsFrame.BorderSizePixel = 0
        statsFrame.Active = true
        statsFrame.Parent = statsGui

        statsTitle = Instance.new("TextLabel")
        statsTitle.BackgroundTransparency = 1
        statsTitle.Position = UDim2.fromOffset(0, 6)
        statsTitle.Size = UDim2.fromOffset(300, 20)
        statsTitle.Font = Enum.Font.GothamBold
        statsTitle.TextSize = 20
        statsTitle.TextXAlignment = Enum.TextXAlignment.Center
        statsTitle.TextColor3 = Color3.new(1, 1, 1)
        statsTitle.Text = "Stats"
        statsTitle.Parent = statsFrame

        execLabel = Instance.new("TextLabel")
        execLabel.Name = "Executor"
        execLabel.BackgroundTransparency = 1
        execLabel.Position = UDim2.fromOffset(10, 32)
        execLabel.Size = UDim2.fromOffset(280, 16)
        execLabel.Font = Enum.Font.SourceSansBold
        execLabel.TextSize = 14
        execLabel.TextXAlignment = Enum.TextXAlignment.Left
        execLabel.TextColor3 = Color3.new(1, 1, 1)
        execLabel.Text = "Executor: ?"
        execLabel.Parent = statsFrame

        fpsLabel = Instance.new("TextLabel")
        fpsLabel.BackgroundTransparency = 1
        fpsLabel.Position = UDim2.fromOffset(10, 50)
        fpsLabel.Size = UDim2.fromOffset(280, 16)
        fpsLabel.Font = Enum.Font.SourceSansBold
        fpsLabel.TextSize = 14
        fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
        fpsLabel.TextColor3 = Color3.new(1, 1, 1)
        fpsLabel.Text = "FPS: ?"
        fpsLabel.Parent = statsFrame

        pingLabel = Instance.new("TextLabel")
        pingLabel.BackgroundTransparency = 1
        pingLabel.Position = UDim2.fromOffset(10, 68)
        pingLabel.Size = UDim2.fromOffset(280, 16)
        pingLabel.Font = Enum.Font.SourceSansBold
        pingLabel.TextSize = 14
        pingLabel.TextXAlignment = Enum.TextXAlignment.Left
        pingLabel.TextColor3 = Color3.new(1, 1, 1)
        pingLabel.Text = "Ping: ?"
        pingLabel.Parent = statsFrame

        playersLabel = Instance.new("TextLabel")
        playersLabel.BackgroundTransparency = 1
        playersLabel.Position = UDim2.fromOffset(10, 86)
        playersLabel.Size = UDim2.fromOffset(280, 16)
        playersLabel.Font = Enum.Font.SourceSansBold
        playersLabel.TextSize = 14
        playersLabel.TextXAlignment = Enum.TextXAlignment.Left
        playersLabel.TextColor3 = Color3.new(1, 1, 1)
        playersLabel.Text = "Players: ?"
        playersLabel.Parent = statsFrame

        uptimeLabel = Instance.new("TextLabel")
        uptimeLabel.Name = "Uptime"
        uptimeLabel.BackgroundTransparency = 1
        uptimeLabel.Position = UDim2.fromOffset(10, 104)
        uptimeLabel.Size = UDim2.fromOffset(280, 16)
        uptimeLabel.Font = Enum.Font.SourceSansBold
        uptimeLabel.TextSize = 14
        uptimeLabel.TextXAlignment = Enum.TextXAlignment.Left
        uptimeLabel.TextColor3 = Color3.new(1, 1, 1)
        uptimeLabel.Text = "Uptime: ?"
        uptimeLabel.Parent = statsFrame

        placeLabel = Instance.new("TextLabel")
        placeLabel.BackgroundTransparency = 1
        placeLabel.Position = UDim2.fromOffset(10, 122)
        placeLabel.Size = UDim2.fromOffset(252, 16)
        placeLabel.Font = Enum.Font.SourceSansBold
        placeLabel.TextSize = 14
        placeLabel.TextXAlignment = Enum.TextXAlignment.Left
        placeLabel.TextColor3 = Color3.new(1, 1, 1)
        placeLabel.Text = "Place: ?"
        placeLabel.Parent = statsFrame
        local placeCopy = Instance.new("TextButton")
        placeCopy.Name = "CopyPlace"
        placeCopy.BackgroundTransparency = 1
        placeCopy.Position = UDim2.fromOffset(268, 122)
        placeCopy.Size = UDim2.fromOffset(22, 16)
        placeCopy.Font = Enum.Font.SourceSansBold
        placeCopy.TextSize = 14
        placeCopy.TextColor3 = Color3.new(1, 1, 1)
        placeCopy.Text = "⧉"
        placeCopy.Parent = statsFrame
        placeCopy.MouseButton1Click:Connect(function()
            pcall(function()
                if setclipboard then
                    setclipboard(tostring(PLACE_ID))
                    showRobloxNotification("Copy", "PlaceId copied")
                end
            end)
        end)

        jobLabel = Instance.new("TextLabel")
        jobLabel.Name = "Job"
        jobLabel.BackgroundTransparency = 1
        jobLabel.Position = UDim2.fromOffset(10, 140)
        jobLabel.Size = UDim2.fromOffset(252, 16)
        jobLabel.Font = Enum.Font.SourceSansBold
        jobLabel.TextSize = 14
        jobLabel.TextXAlignment = Enum.TextXAlignment.Left
        jobLabel.TextColor3 = Color3.new(1, 1, 1)
        jobLabel.Text = "Job: ?"
        jobLabel.Parent = statsFrame
        local jobCopy = Instance.new("TextButton")
        jobCopy.Name = "CopyJob"
        jobCopy.BackgroundTransparency = 1
        jobCopy.Position = UDim2.fromOffset(268, 140)
        jobCopy.Size = UDim2.fromOffset(22, 16)
        jobCopy.Font = Enum.Font.SourceSansBold
        jobCopy.TextSize = 14
        jobCopy.TextColor3 = Color3.new(1, 1, 1)
        jobCopy.Text = "⧉"
        jobCopy.Parent = statsFrame
        jobCopy.MouseButton1Click:Connect(function()
            pcall(function()
                if setclipboard then
                    setclipboard(tostring(JOB_ID))
                    showRobloxNotification("Copy", "JobId copied")
                end
            end)
        end)

        local dragging = false
        local dragStart = nil
        local startPos = nil

        if dragConnBegan then pcall(function() dragConnBegan:Disconnect() end) end
        if dragConnChanged then pcall(function() dragConnChanged:Disconnect() end) end
        if dragConnEnded then pcall(function() dragConnEnded:Disconnect() end) end

        dragConnBegan = statsFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = statsFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        dragConnChanged = UIS.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - dragStart
            statsFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end)

        dragConnEnded = UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    function M.setOverlayEnabled(on)
        ensureStatsPanel()
        local enabled = (on == true)
        State.StatsEnabled = enabled
        statsGui.Enabled = enabled

        if statsConn then
            pcall(function() statsConn:Disconnect() end)
            statsConn = nil
        end

        if not enabled then return end
        local last = os.clock()
        local frames = 0
        local startedAt = State.JoinedAt
        local execName = "Unknown"
        pcall(function()
            if identifyexecutor then
                execName = tostring(identifyexecutor())
            elseif getexecutorname then
                execName = tostring(getexecutorname())
            end
        end)
        statsConn = RunService.RenderStepped:Connect(function()
            frames += 1
            local now = os.clock()
            if (now - last) >= 1 then
                local fps = math.floor(frames / (now - last))
                frames = 0
                last = now
                if fpsLabel then fpsLabel.Text = "FPS: " .. tostring(fps) end
                local pingText = "Ping: ?"

                pcall(function()
                    local Stats = game:GetService("Stats")
                    local item = Stats.Network.ServerStatsItem["Data Ping"]
                    pingText = "Ping: " .. tostring(item:GetValueString())
                end)
                if pingLabel then pingLabel.Text = pingText end
                if playersLabel then playersLabel.Text = "Players: " .. tostring(#Players:GetPlayers()) end
                if placeLabel then placeLabel.Text = "Place: " .. tostring(PLACE_ID) end
                pcall(function()
                    local job = statsFrame and statsFrame:FindFirstChild("Job")
                    if job and job:IsA("TextLabel") then
                        job.Text = "Job: " .. tostring(JOB_ID)
                    end
                    local uptime = statsFrame and statsFrame:FindFirstChild("Uptime")
                    if uptime and uptime:IsA("TextLabel") then
                        uptime.Text = "Uptime: " .. tostring(math.floor(now - startedAt)) .. "s"
                    end
                    local ex = statsFrame and statsFrame:FindFirstChild("Executor")
                    if ex and ex:IsA("TextLabel") then
                        ex.Text = "Executor: " .. tostring(execName)
                    end
                end)
            end
        end)
    end

    -- View / camera
    local viewLoopConn = nil
    local currentViewTarget = nil
    local currentViewPlr = nil
    local viewSavedCamType = nil
    local viewSavedCamSubject = nil
    local viewSavedCamCFrame = nil
    local viewDiedConn = nil
    local viewChangedConn = nil

    local function clearViewConnections()
        if viewDiedConn then pcall(function() viewDiedConn:Disconnect() end) viewDiedConn = nil end
        if viewChangedConn then pcall(function() viewChangedConn:Disconnect() end) viewChangedConn = nil end
        currentViewPlr = nil
        currentViewTarget = nil
    end

    local function applyViewCameraSubject()
        local cam = workspace.CurrentCamera
        if not cam then return end
        if State.ViewEnabled then
            local plr = currentViewPlr
            local char = plr and plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                cam.CameraSubject = hum
                return
            end
            local head = char and char:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                cam.CameraSubject = head
                return
            end
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:IsA("BasePart") then
                cam.CameraSubject = hrp
                return
            end
        end
        local hum = getLocalHumanoid()
        if hum then
            cam.CameraSubject = hum
        end
    end

    local function ensureViewSubject(name)
        if typeof(name) ~= "string" or name == "" then
            clearViewConnections()
            local hum = getLocalHumanoid()
            local cam = workspace.CurrentCamera
            if cam and hum then cam.CameraSubject = hum end
            return
        end
        if not State.ViewEnabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        if currentViewTarget ~= name then
            clearViewConnections()
            currentViewTarget = name
            currentViewPlr = getPlayerByName(name)
            if currentViewPlr then
                viewDiedConn = currentViewPlr.CharacterAdded:Connect(function()
                    task.wait(0.05)
                    pcall(applyViewCameraSubject)
                end)
                viewChangedConn = cam:GetPropertyChangedSignal("CameraSubject"):Connect(function()
                    pcall(applyViewCameraSubject)
                end)
            end
        end
        pcall(applyViewCameraSubject)
    end

    function M.setViewEnabled(on)
        State.ViewEnabled = (on == true)
        if viewLoopConn then pcall(function() viewLoopConn:Disconnect() end) viewLoopConn = nil end
        if not State.ViewEnabled then
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam then
                    if viewSavedCamType ~= nil then cam.CameraType = viewSavedCamType end
                    if viewSavedCamSubject ~= nil then cam.CameraSubject = viewSavedCamSubject end
                    if viewSavedCamCFrame ~= nil then cam.CFrame = viewSavedCamCFrame end
                end
            end)
            viewSavedCamType = nil
            viewSavedCamSubject = nil
            viewSavedCamCFrame = nil
            pcall(function() ensureViewSubject(nil) end)
            return
        end
        pcall(function() M.setFixcam(false) end)
        pcall(function() M.setFreecam(false) end)
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                viewSavedCamType = cam.CameraType
                viewSavedCamSubject = cam.CameraSubject
                viewSavedCamCFrame = cam.CFrame
                cam.CameraType = Enum.CameraType.Custom
            end
        end)
        pcall(function() ensureViewSubject(State.ViewTargetName) end)
        viewLoopConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam and cam.CameraType ~= Enum.CameraType.Custom then
                    cam.CameraType = Enum.CameraType.Custom
                end
                ensureViewSubject(State.ViewTargetName)
            end)
        end)
    end

    task.spawn(function()
        while true do
            if State.ViewEnabled then
                pcall(function() ensureViewSubject(State.ViewTargetName) end)
            end
            task.wait(0.1)
        end
    end)

    function M.setViewTarget(name)
        State.ViewTargetName = name
        pcall(function() ensureViewSubject(name) end)
    end

    local fixcamConn = nil
    function M.setFixcam(on)
        State.FixcamEnabled = (on == true)
        if fixcamConn then pcall(function() fixcamConn:Disconnect() end) fixcamConn = nil end
        if State.FixcamEnabled then
            fixcamConn = RunService.RenderStepped:Connect(function()
                local cam = workspace.CurrentCamera
                local hum = getLocalHumanoid()
                if cam and hum and cam.CameraSubject ~= hum then
                    cam.CameraSubject = hum
                end
            end)
        end
    end

    local originalLighting = nil
    function M.setFullbright(on)
        State.FullbrightEnabled = (on == true)
        local Lighting = game:GetService("Lighting")
        if State.FullbrightEnabled then
            if not originalLighting then
                originalLighting = {
                    Brightness = Lighting.Brightness,
                    ClockTime = Lighting.ClockTime,
                    FogEnd = Lighting.FogEnd,
                    GlobalShadows = Lighting.GlobalShadows
                }
            end
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            if originalLighting then
                Lighting.Brightness = originalLighting.Brightness
                Lighting.ClockTime = originalLighting.ClockTime
                Lighting.FogEnd = originalLighting.FogEnd
                Lighting.GlobalShadows = originalLighting.GlobalShadows
            end
        end
    end

    -- Freecam
    local freecamConn = nil
    local freecamCf = nil
    local freecamYaw = 0
    local freecamPitch = 0
    local freecamMouseConn = nil
    local freecamRmbDownConn = nil
    local freecamRmbUpConn = nil
    local freecamRmbDown = false
    local freecamOldMouseBehavior = nil
    local freecamOldMouseIconEnabled = nil
    local freecamFreezeRestore = nil
    local freecamFrozen = false

    local freecamSinkBound = false
    local function freecamSinkAction()
        return Enum.ContextActionResult.Sink
    end

    local function setFreecamInputSink(on)
        if on and not freecamSinkBound then
            freecamSinkBound = true
            pcall(function()
                CAS:BindActionAtPriority("NomNom_FreecamSink", freecamSinkAction, false, 9999,
                    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                    Enum.KeyCode.Space, Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift
                )
            end)
        elseif (not on) and freecamSinkBound then
            freecamSinkBound = false
            pcall(function() CAS:UnbindAction("NomNom_FreecamSink") end)
        end
    end

    local function setFreezeLocalCharacter(freeze)
        local hum = getLocalHumanoid()
        local hrp = getLocalHRP()
        if not hum or not hrp then return end
        if freeze then
            if freecamFreezeRestore then return end
            freecamFreezeRestore = {
                PlatformStand = hum.PlatformStand,
                AutoRotate = hum.AutoRotate,
                Anchored = hrp.Anchored,
            }
            pcall(function() hum.PlatformStand = true end)
            pcall(function() hum.AutoRotate = false end)
            pcall(function() hrp.Anchored = true end)
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        else
            if not freecamFreezeRestore then return end
            pcall(function() hrp.Anchored = freecamFreezeRestore.Anchored end)
            pcall(function() hum.PlatformStand = freecamFreezeRestore.PlatformStand end)
            pcall(function() hum.AutoRotate = freecamFreezeRestore.AutoRotate end)
            freecamFreezeRestore = nil
        end
    end

    function M.setFreecam(on)
        State.FreecamEnabled = (on == true)
        if freecamConn then pcall(function() freecamConn:Disconnect() end) freecamConn = nil end
        if freecamMouseConn then pcall(function() freecamMouseConn:Disconnect() end) freecamMouseConn = nil end
        if freecamRmbDownConn then pcall(function() freecamRmbDownConn:Disconnect() end) freecamRmbDownConn = nil end
        if freecamRmbUpConn then pcall(function() freecamRmbUpConn:Disconnect() end) freecamRmbUpConn = nil end
        freecamRmbDown = false
        local cam = workspace.CurrentCamera
        if not cam then return end
        if not State.FreecamEnabled then
            pcall(function() setFreezeLocalCharacter(false) end)
            pcall(function() setFreecamInputSink(false) end)
            pcall(function()
                UIS.MouseBehavior = Enum.MouseBehavior.Default
                UIS.MouseIconEnabled = true
            end)
            pcall(function() cam.CameraType = Enum.CameraType.Custom end)
            return
        end
        pcall(function() setFreezeLocalCharacter(false) end)
        pcall(function() setFreecamInputSink(true) end)

        freecamCf = cam.CFrame
        local _, y, _ = cam.CFrame:ToOrientation()
        freecamYaw = y
        freecamPitch = 0
        local freecamZoom = 0
        freecamOldMouseBehavior = UIS.MouseBehavior
        freecamOldMouseIconEnabled = UIS.MouseIconEnabled

        pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
        pcall(function()
            UIS.MouseBehavior = Enum.MouseBehavior.Default
            UIS.MouseIconEnabled = true
        end)
        local speed = 60
        freecamRmbDownConn = UIS.InputBegan:Connect(function(input)
            if not State.FreecamEnabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                freecamRmbDown = true
                pcall(function()
                    UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
                    UIS.MouseIconEnabled = false
                end)
            end
        end)
        freecamRmbUpConn = UIS.InputEnded:Connect(function(input)
            if not State.FreecamEnabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                freecamRmbDown = false
                pcall(function()
                    UIS.MouseBehavior = freecamOldMouseBehavior or Enum.MouseBehavior.Default
                    UIS.MouseIconEnabled = (freecamOldMouseIconEnabled ~= nil) and freecamOldMouseIconEnabled or true
                end)
            end
        end)
        freecamMouseConn = UIS.InputChanged:Connect(function(input)
            if not State.FreecamEnabled then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement and freecamRmbDown then
                freecamYaw -= input.Delta.X * 0.0025
                freecamPitch = math.clamp(freecamPitch - input.Delta.Y * 0.0025, -1.4, 1.4)
            end
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                freecamZoom = math.clamp(freecamZoom - input.Position.Z * 2, -80, 30)
            end
        end)
        freecamConn = RunService.RenderStepped:Connect(function(dt)
            if not State.FreecamEnabled then return end

            local move = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0,0,-1) end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0,0,1) end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1,0,0) end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move -= Vector3.new(1,0,0) end
            if UIS:IsKeyDown(Enum.KeyCode.E) then move += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.Q) then move -= Vector3.new(0,1,0) end
            if freecamFrozen then return end
            local rot = CFrame.fromOrientation(freecamPitch, freecamYaw, 0)
            freecamCf = CFrame.new(freecamCf.Position) * rot
            freecamCf = freecamCf + (freecamCf:VectorToWorldSpace(move) * speed * dt)
            cam.CFrame = freecamCf * CFrame.new(0, 0, freecamZoom)
        end)
    end

    -- ESP / Tracers
    local espObjects = {}
    local espInfoConn = nil
    local espInfoObjects = {}
    local espPlayerAddedConn = nil
    local espPlayerRemovingConn = nil
    local espCharAddedConns = {}

    local function clearEsp()
        if espPlayerAddedConn then pcall(function() espPlayerAddedConn:Disconnect() end) espPlayerAddedConn = nil end
        if espPlayerRemovingConn then pcall(function() espPlayerRemovingConn:Disconnect() end) espPlayerRemovingConn = nil end
        for plr, c in pairs(espCharAddedConns) do
            if c then pcall(function() c:Disconnect() end) end
            espCharAddedConns[plr] = nil
        end
        if espInfoConn then
            pcall(function() espInfoConn:Disconnect() end)
            espInfoConn = nil
        end
        for plr, hl in pairs(espObjects) do
            if hl then pcall(function() hl:Destroy() end) end
            espObjects[plr] = nil
        end
        for plr, gui in pairs(espInfoObjects) do
            if gui then pcall(function() gui:Destroy() end) end
            espInfoObjects[plr] = nil
        end
        pcall(function()
            for _, d in ipairs(workspace:GetDescendants()) do
                if d and d:IsA("Highlight") and d.Name == "NomNom_ESP" then
                    pcall(function() d:Destroy() end)
                elseif d and d:IsA("BillboardGui") and d.Name == "NomNom_ESPInfo" then
                    pcall(function() d:Destroy() end)
                end
            end
        end)
    end

    local applyEspForPlayer
    local function getHpRatio(h, m)
        local hp = tonumber(h) or 0
        local max = tonumber(m) or 100
        if max <= 0 then max = 100 end
        return math.clamp(hp / max, 0, 1), hp, max
    end

    local function hpColor(ratio)
        local r = math.floor(255 * (1 - ratio))
        local g = math.floor(255 * ratio)
        return Color3.fromRGB(r, g, 0)
    end

    local function getBestCharPart(char)
        if not char then return nil end
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then return hrp end
        local pp = char.PrimaryPart
        if pp and pp:IsA("BasePart") then return pp end
        local anyPart = char:FindFirstChildWhichIsA("BasePart", true)
        if anyPart and anyPart:IsA("BasePart") then return anyPart end
        return nil
    end

    local function ensureEspGui(plr, adornee)
        local existing = espInfoObjects[plr]
        if existing and existing.Parent then
            existing.Adornee = adornee
            pcall(function()
                if adornee and existing.Parent ~= adornee then
                    existing.Parent = adornee
                end
            end)
            return existing
        end
        local bb = Instance.new("BillboardGui")
        bb.Name = "NomNom_ESPInfo"
        bb.AlwaysOnTop = true
        bb.Adornee = adornee
        bb.Size = UDim2.fromOffset(200, 60)
        bb.StudsOffset = Vector3.new(0, 5.5, 0)
        bb.ResetOnSpawn = false
        bb.Parent = adornee

        local frame = Instance.new("Frame")
        frame.Name = "Bg"
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Size = UDim2.fromScale(1, 1)
        frame.Parent = bb

        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 8)
        bgCorner.Parent = frame

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 2)
        layout.Parent = frame

        local stats = Instance.new("TextLabel")
        stats.Name = "Stats"
        stats.BackgroundTransparency = 1
        stats.Size = UDim2.new(1, 0, 0, 16)
        stats.Font = Enum.Font.SourceSansBold
        stats.TextSize = 14
        stats.TextWrapped = true
        stats.TextColor3 = Color3.fromRGB(255, 255, 255)
        stats.TextStrokeTransparency = 0
        stats.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        stats.LayoutOrder = 1
        stats.Parent = frame

        local name = Instance.new("TextLabel")
        name.Name = "Name"
        name.BackgroundTransparency = 1
        name.Size = UDim2.new(1, 0, 0, 22)
        name.Font = Enum.Font.SourceSansBold
        name.TextSize = 18
        name.TextWrapped = false
        name.TextColor3 = Color3.fromRGB(255, 255, 255)
        name.TextStrokeTransparency = 0
        name.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        name.LayoutOrder = 2
        name.Parent = frame

        local info = Instance.new("TextLabel")
        info.Name = "Info"
        info.BackgroundTransparency = 1
        info.Size = UDim2.new(1, 0, 0, 16)
        info.Font = Enum.Font.SourceSansBold
        info.TextSize = 14
        info.TextWrapped = true
        info.TextColor3 = Color3.fromRGB(255, 255, 255)
        info.TextStrokeTransparency = 0
        info.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        info.LayoutOrder = 3
        info.Parent = frame

        local hpBg = Instance.new("Frame")
        hpBg.Name = "HpBar"
        hpBg.BackgroundTransparency = 0.35
        hpBg.BorderSizePixel = 0
        hpBg.Size = UDim2.new(1, -10, 0, 6)
        hpBg.LayoutOrder = 4
        hpBg.Parent = frame

        local hpCorner = Instance.new("UICorner")
        hpCorner.CornerRadius = UDim.new(0, 6)
        hpCorner.Parent = hpBg

        local hpFill = Instance.new("Frame")
        hpFill.Name = "Fill"
        hpFill.BackgroundTransparency = 0
        hpFill.BorderSizePixel = 0
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.Parent = hpBg

        local hpFillCorner = Instance.new("UICorner")
        hpFillCorner.CornerRadius = UDim.new(0, 6)
        hpFillCorner.Parent = hpFill

        espInfoObjects[plr] = bb
        return bb
    end

    local function updateEspGui(plr, hum, hrp)
        local char = plr.Character
        if not char then return end
        local head = getBestCharPart(char) or hrp
        if not head then return end

        local ratio, hp, maxHp = getHpRatio(hum and hum.Health, hum and hum.MaxHealth)
        local dist = 0
        local localHrp = getLocalHRP()
        local distPart = hrp or head
        if localHrp and distPart and distPart:IsA("BasePart") then
            dist = math.floor((localHrp.Position - distPart.Position).Magnitude)
        end

        local bb = ensureEspGui(plr, head)
        pcall(function()
            local base = 5.5
            local extra = math.clamp((tonumber(dist) or 0) / 60, 0, 10)
            bb.StudsOffset = Vector3.new(0, base + extra, 0)
        end)
        local frame = bb:FindFirstChild("Bg")
        local stats = frame and frame:FindFirstChild("Stats")
        local nameLbl = frame and frame:FindFirstChild("Name")
        local info = frame and frame:FindFirstChild("Info")
        local hpBg = frame and frame:FindFirstChild("HpBar")
        local hpFill = hpBg and hpBg:FindFirstChild("Fill")

        if frame then
            frame.BackgroundColor3 = hpColor(ratio)
        end

        if stats and stats:IsA("TextLabel") then
            local ls = plr:FindFirstChild("leaderstats")
            local text = ""
            if ls then
                for _, v in ipairs(ls:GetChildren()) do
                    if v and v:IsA("ValueBase") then
                        text ..= tostring(v.Name) .. ":" .. tostring(v.Value) .. " "
                    end
                end
            end
            if text == "" then text = " " end
            stats.Text = text
        end

        if nameLbl and nameLbl:IsA("TextLabel") then
            local display = (plr.DisplayName and tostring(plr.DisplayName)) or plr.Name
            nameLbl.Text = string.format("%s (@%s)", display, plr.Name)
        end

        local pct = math.floor((ratio * 100) + 0.5)
        if info and info:IsA("TextLabel") then
            info.Text = "HP: " .. pct .. "% | " .. dist .. "m"
        end
        if hpBg and hpFill and hpFill:IsA("Frame") then
            hpBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            hpFill.BackgroundColor3 = hpColor(ratio)
            hpFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
        end

        if frame and stats and nameLbl and info then
            local padX, padY = 12, 6
            local spacing = 4

            local function max3(a, b, c)
                local m = a
                if b > m then m = b end
                if c > m then m = c end
                return m
            end
            local w = max3(stats.TextBounds.X, nameLbl.TextBounds.X, info.TextBounds.X) + padX * 2
            local barH = (hpBg and hpBg:IsA("Frame")) and hpBg.AbsoluteSize.Y or 6
            local h = stats.TextBounds.Y + nameLbl.TextBounds.Y + info.TextBounds.Y + barH + padY * 2 + spacing * 3
            bb.Size = UDim2.fromOffset(w, h)
        end
    end

    applyEspForPlayer = function(plr)
        if not State.PlayerEspEnabled then return end
        if not plr or plr == Player then return false end
        local char = plr.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local part = getBestCharPart(char)
        if not part then return false end

        local hl = espObjects[plr]
        if not (hl and hl.Parent) then
            hl = Instance.new("Highlight")
            hl.Name = "NomNom_ESP"
            hl.FillTransparency = 1
            hl.OutlineTransparency = 0
            hl.OutlineColor = State.EspOutlineColor or Color3.fromRGB(255, 255, 255)
            hl.Adornee = char
            hl.Parent = char
            espObjects[plr] = hl
        else
            hl.Adornee = char
        end
        pcall(function()
            hl.OutlineColor = State.EspOutlineColor or Color3.fromRGB(255, 255, 255)
            hl.OutlineTransparency = 0
            hl.FillTransparency = 1
        end)
        updateEspGui(plr, hum, (hrp and hrp:IsA("BasePart")) and hrp or part)
        return true
    end

    function M.setPlayerEsp(on)
        State.PlayerEspEnabled = (on == true)

        if not State.PlayerEspEnabled then
            if espPlayerAddedConn then pcall(function() espPlayerAddedConn:Disconnect() end) espPlayerAddedConn = nil end
            if espPlayerRemovingConn then pcall(function() espPlayerRemovingConn:Disconnect() end) espPlayerRemovingConn = nil end
            for plr, c in pairs(espCharAddedConns) do
                if c then pcall(function() c:Disconnect() end) end
                espCharAddedConns[plr] = nil
            end
            clearEsp()
            return
        end

        if espPlayerAddedConn then pcall(function() espPlayerAddedConn:Disconnect() end) espPlayerAddedConn = nil end
        if espPlayerRemovingConn then pcall(function() espPlayerRemovingConn:Disconnect() end) espPlayerRemovingConn = nil end
        for plr, c in pairs(espCharAddedConns) do
            if c then pcall(function() c:Disconnect() end) end
            espCharAddedConns[plr] = nil
        end

        local function kickstartEsp(plr)
            if not plr or plr == Player then return end
            task.spawn(function()
                for _ = 1, 40 do
                    if not State.PlayerEspEnabled then return end
                    if not plr or not plr.Parent then return end
                    local ok, applied = pcall(function()
                        return applyEspForPlayer(plr)
                    end)
                    if ok and applied then
                        return
                    end
                    task.wait(0.1)
                end
            end)
        end

        espPlayerAddedConn = Players.PlayerAdded:Connect(function(plr)
            if plr == Player then return end
            if espCharAddedConns[plr] then pcall(function() espCharAddedConns[plr]:Disconnect() end) end
            espCharAddedConns[plr] = plr.CharacterAdded:Connect(function()
                kickstartEsp(plr)
            end)
            kickstartEsp(plr)
        end)

        espPlayerRemovingConn = Players.PlayerRemoving:Connect(function(plr)
            if espCharAddedConns[plr] then pcall(function() espCharAddedConns[plr]:Disconnect() end) end
            espCharAddedConns[plr] = nil
            pcall(function()
                local hl = espObjects[plr]
                if hl then hl:Destroy() end
                local bb = espInfoObjects[plr]
                if bb then bb:Destroy() end
                espObjects[plr] = nil
                espInfoObjects[plr] = nil
            end)
        end)

        for _, plr in ipairs(Players:GetPlayers()) do
            kickstartEsp(plr)
            if plr ~= Player then
                if espCharAddedConns[plr] then pcall(function() espCharAddedConns[plr]:Disconnect() end) end
                espCharAddedConns[plr] = plr.CharacterAdded:Connect(function()
                    kickstartEsp(plr)
                end)
            end
        end

        if espInfoConn then pcall(function() espInfoConn:Disconnect() end) espInfoConn = nil end
        espInfoConn = RunService.Heartbeat:Connect(function()
            if not State.PlayerEspEnabled then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player then
                    pcall(function() applyEspForPlayer(plr) end)
                end
            end
        end)
    end

    local tracerBeams = {}
    local tracerConn = nil

    local function clearTracers()
        for plr, beamData in pairs(tracerBeams) do
            if beamData then
                pcall(function() if beamData.Beam then beamData.Beam:Destroy() end end)
                pcall(function() if beamData.A0 then beamData.A0:Destroy() end end)
                pcall(function() if beamData.A1 then beamData.A1:Destroy() end end)
            end
            tracerBeams[plr] = nil
        end
    end

    local function applyTracerForPlayer(plr)
        if not State.TracersEnabled then return end
        if not plr or plr == Player then return end
        local localHrp = getLocalHRP()
        local targetHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not localHrp or not targetHrp then return end
        if tracerBeams[plr] and tracerBeams[plr].Beam and tracerBeams[plr].Beam.Parent then
            tracerBeams[plr].A0.Parent = localHrp
            tracerBeams[plr].A1.Parent = targetHrp
            return
        end
        local a0 = Instance.new("Attachment")
        a0.Name = "NomNom_TracerA0"
        a0.Parent = localHrp
        local a1 = Instance.new("Attachment")
        a1.Name = "NomNom_TracerA1"
        a1.Parent = targetHrp
        local beam = Instance.new("Beam")
        beam.Name = "NomNom_Tracer"
        beam.Attachment0 = a0
        beam.Attachment1 = a1
        beam.Width0 = 0.05
        beam.Width1 = 0.05
        beam.FaceCamera = true
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        beam.Transparency = NumberSequence.new(0)
        beam.Parent = a0
        tracerBeams[plr] = { Beam = beam, A0 = a0, A1 = a1 }
    end

    function M.setTracers(on)
        State.TracersEnabled = (on == true)
        if tracerConn then
            pcall(function() tracerConn:Disconnect() end)
            tracerConn = nil
        end
        if not State.TracersEnabled then
            clearTracers()
            return
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            pcall(function() applyTracerForPlayer(plr) end)

            if plr ~= Player then
                plr.CharacterAdded:Connect(function()
                    task.wait(0.2)
                    pcall(function() applyTracerForPlayer(plr) end)
                end)
            end
        end
        tracerConn = RunService.Heartbeat:Connect(function()
            if not State.TracersEnabled then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player then
                    pcall(function() applyTracerForPlayer(plr) end)
                end
            end
        end)
    end

    function M.buildPlayerNameList()
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player then
                table.insert(list, plr.Name)
            end
        end
        table.sort(list)
        return list
    end

    return M
end
