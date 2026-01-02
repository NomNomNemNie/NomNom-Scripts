-- misc.lua

return function(ctx)
    local Services = ctx.Services
    local Players = Services.Players
    local TeleportService = Services.TeleportService
    local HttpService = Services.HttpService
    local UIS = Services.UIS
    local TweenService = Services.TweenService
    local RunService = Services.RunService
    local CAS = Services.CAS
    local Player = ctx.Player
    local playerGui = ctx.playerGui
    local PLACE_ID = ctx.PLACE_ID
    local JOB_ID = ctx.JOB_ID
    local State = ctx.State

    local M = {}

    local function loadUserConfig()
        pcall(function()
            if readfile and isfile and isfile(State.CONFIG_FILE) then
                local raw = readfile(State.CONFIG_FILE)
                local ok, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
                if not ok or typeof(cfg) ~= "table" then return end

                if typeof(cfg.EspOutlineColorHex) == "string" then State.EspOutlineColorHex = cfg.EspOutlineColorHex end

                if typeof(cfg.DesyncMethod) == "string" then State.DesyncMethod = cfg.DesyncMethod end
                if typeof(cfg.AutoExecEnabled) == "boolean" then State.AutoExecEnabled = cfg.AutoExecEnabled end
                if typeof(cfg.AutoExecUrl) == "string" then State.AutoExecUrl = cfg.AutoExecUrl end
                if typeof(cfg.AutoSaveConfigEnabled) == "boolean" then State.AutoSaveConfigEnabled = cfg.AutoSaveConfigEnabled end
                if typeof(cfg.ToggleKeyName) == "string" and Enum.KeyCode[cfg.ToggleKeyName] then State.ToggleKey = Enum.KeyCode[cfg.ToggleKeyName] end
                if typeof(cfg.DesyncKeyName) == "string" and Enum.KeyCode[cfg.DesyncKeyName] then State.DesyncKey = Enum.KeyCode[cfg.DesyncKeyName] end
                if typeof(cfg.FlyKeyName) == "string" and Enum.KeyCode[cfg.FlyKeyName] then State.FlyKey = Enum.KeyCode[cfg.FlyKeyName] end
                if typeof(cfg.NoclipKeyName) == "string" and Enum.KeyCode[cfg.NoclipKeyName] then State.NoclipKey = Enum.KeyCode[cfg.NoclipKeyName] end
                if typeof(cfg.ClickTpKeyName) == "string" and Enum.KeyCode[cfg.ClickTpKeyName] then State.ClickTpKey = Enum.KeyCode[cfg.ClickTpKeyName] end
                if typeof(cfg.LoopGotoKeyName) == "string" and Enum.KeyCode[cfg.LoopGotoKeyName] then State.LoopGotoKey = Enum.KeyCode[cfg.LoopGotoKeyName] end
                if typeof(cfg.FreecamKeyName) == "string" and Enum.KeyCode[cfg.FreecamKeyName] then State.FreecamKey = Enum.KeyCode[cfg.FreecamKeyName] end
                if typeof(cfg.OrbitKeyName) == "string" and Enum.KeyCode[cfg.OrbitKeyName] then State.OrbitKey = Enum.KeyCode[cfg.OrbitKeyName] end
                if typeof(cfg.AimbotKeyName) == "string" and Enum.KeyCode[cfg.AimbotKeyName] then State.AimbotKey = Enum.KeyCode[cfg.AimbotKeyName] end
                if typeof(cfg.AimbotTriggerKeyName) == "string" then
                    if Enum.UserInputType[cfg.AimbotTriggerKeyName] then
                        local uit = Enum.UserInputType[cfg.AimbotTriggerKeyName]
                        if uit == Enum.UserInputType.MouseButton1 or uit == Enum.UserInputType.MouseButton2 or uit == Enum.UserInputType.MouseButton3 then
                            State.AimbotTriggerKey = uit
                        end
                    elseif Enum.KeyCode[cfg.AimbotTriggerKeyName] then
                        State.AimbotTriggerKey = Enum.KeyCode[cfg.AimbotTriggerKeyName]
                    end
                end

                if typeof(cfg.CurrentScale) == "number" then State.CurrentScale = cfg.CurrentScale end
                if typeof(cfg.LastPosX) == "number" and typeof(cfg.LastPosY) == "number" then State.LastPos = UDim2.fromOffset(cfg.LastPosX, cfg.LastPosY) end

                if typeof(cfg.FlyEnabled) == "boolean" then State.FlyEnabled = cfg.FlyEnabled end
                if typeof(cfg.NoclipEnabled) == "boolean" then State.NoclipEnabled = cfg.NoclipEnabled end
                if typeof(cfg.ClickTpEnabled) == "boolean" then State.ClickTpEnabled = cfg.ClickTpEnabled end
                if typeof(cfg.LoopGotoEnabled) == "boolean" then State.LoopGotoEnabled = cfg.LoopGotoEnabled end
                if typeof(cfg.FreecamEnabled) == "boolean" then State.FreecamEnabled = cfg.FreecamEnabled end
                if typeof(cfg.FixcamEnabled) == "boolean" then State.FixcamEnabled = cfg.FixcamEnabled end
                if typeof(cfg.AntiAfkEnabled) == "boolean" then State.AntiAfkEnabled = cfg.AntiAfkEnabled end
                if typeof(cfg.StatsEnabled) == "boolean" then State.StatsEnabled = cfg.StatsEnabled end
                if typeof(cfg.ViewEnabled) == "boolean" then State.ViewEnabled = cfg.ViewEnabled end
                if typeof(cfg.AirwalkEnabled) == "boolean" then State.AirwalkEnabled = cfg.AirwalkEnabled end
                if typeof(cfg.FloatEnabled) == "boolean" then State.FloatEnabled = cfg.FloatEnabled end
                if typeof(cfg.PlayerEspEnabled) == "boolean" then State.PlayerEspEnabled = cfg.PlayerEspEnabled end
                if typeof(cfg.TracersEnabled) == "boolean" then State.TracersEnabled = cfg.TracersEnabled end
                if typeof(cfg.FullbrightEnabled) == "boolean" then State.FullbrightEnabled = cfg.FullbrightEnabled end
                if typeof(cfg.OrbitEnabled) == "boolean" then State.OrbitEnabled = cfg.OrbitEnabled end

                if typeof(cfg.OrbitSpeed) == "number" then State.OrbitSpeed = cfg.OrbitSpeed end
                if typeof(cfg.OrbitDistance) == "number" then State.OrbitDistance = cfg.OrbitDistance end
                if typeof(cfg.DesiredWalkSpeed) == "number" then State.DesiredWalkSpeed = cfg.DesiredWalkSpeed end
                if typeof(cfg.DesiredJumpPower) == "number" then State.DesiredJumpPower = cfg.DesiredJumpPower end
                if typeof(cfg.ApplyWalkSpeed) == "boolean" then State.ApplyWalkSpeed = cfg.ApplyWalkSpeed end
                if typeof(cfg.ApplyJumpPower) == "boolean" then State.ApplyJumpPower = cfg.ApplyJumpPower end
                if typeof(cfg.ApplyMovementStats) == "boolean" then State.ApplyMovementStats = cfg.ApplyMovementStats end
                if typeof(cfg.ClickTpMethod) == "string" then State.ClickTpMethod = cfg.ClickTpMethod end
                if typeof(cfg.ClickTpTweenTime) == "number" then State.ClickTpTweenTime = cfg.ClickTpTweenTime end
                if typeof(cfg.GotoMethod) == "string" then State.GotoMethod = cfg.GotoMethod end
                if typeof(cfg.GotoTweenTime) == "number" then State.GotoTweenTime = cfg.GotoTweenTime end
                if typeof(cfg.LoopGotoInterval) == "number" then State.LoopGotoInterval = cfg.LoopGotoInterval end
                if typeof(cfg.ViewTargetName) == "string" then State.ViewTargetName = cfg.ViewTargetName end
                if typeof(cfg.GotoTargetName) == "string" then State.GotoTargetName = cfg.GotoTargetName end
                if typeof(cfg.FlySpeed) == "number" then State.FlySpeed = cfg.FlySpeed end
                if typeof(cfg.FloatSpeed) == "number" then State.FloatSpeed = cfg.FloatSpeed end

                if typeof(cfg.DesyncEnabled) == "boolean" then State.DesyncEnabled = cfg.DesyncEnabled end
            end
        end)
        return true
    end

    local function saveUserConfig()
        pcall(function()
            if not writefile then return end
            local cfg = {
                EspOutlineColorHex = State.EspOutlineColorHex,
                DesyncMethod = State.DesyncMethod,
                AutoExecEnabled = State.AutoExecEnabled,
                AutoExecUrl = State.AutoExecUrl,
                AutoSaveConfigEnabled = State.AutoSaveConfigEnabled,
                ToggleKeyName = State.ToggleKey and State.ToggleKey.Name or nil,
                DesyncKeyName = State.DesyncKey and State.DesyncKey.Name or nil,
                FlyKeyName = State.FlyKey and State.FlyKey.Name or nil,
                NoclipKeyName = State.NoclipKey and State.NoclipKey.Name or nil,
                ClickTpKeyName = State.ClickTpKey and State.ClickTpKey.Name or nil,
                LoopGotoKeyName = State.LoopGotoKey and State.LoopGotoKey.Name or nil,
                FreecamKeyName = State.FreecamKey and State.FreecamKey.Name or nil,
                OrbitKeyName = State.OrbitKey and State.OrbitKey.Name or nil,
                AimbotKeyName = State.AimbotKey and State.AimbotKey.Name or nil,
                AimbotTriggerKeyName = State.AimbotTriggerKey and State.AimbotTriggerKey.Name or nil,

                CurrentScale = State.CurrentScale,
                LastPosX = (State.LastPos and State.LastPos.X and State.LastPos.X.Offset) or nil,
                LastPosY = (State.LastPos and State.LastPos.Y and State.LastPos.Y.Offset) or nil,

                FlyEnabled = State.FlyEnabled,
                NoclipEnabled = State.NoclipEnabled,
                ClickTpEnabled = State.ClickTpEnabled,
                LoopGotoEnabled = State.LoopGotoEnabled,
                FreecamEnabled = State.FreecamEnabled,
                FixcamEnabled = State.FixcamEnabled,
                AntiAfkEnabled = State.AntiAfkEnabled,
                StatsEnabled = State.StatsEnabled,
                ViewEnabled = State.ViewEnabled,
                AirwalkEnabled = State.AirwalkEnabled,
                FloatEnabled = State.FloatEnabled,
                PlayerEspEnabled = State.PlayerEspEnabled,
                TracersEnabled = State.TracersEnabled,
                FullbrightEnabled = State.FullbrightEnabled,
                OrbitEnabled = State.OrbitEnabled,

                OrbitSpeed = State.OrbitSpeed,
                OrbitDistance = State.OrbitDistance,
                DesiredWalkSpeed = State.DesiredWalkSpeed,
                DesiredJumpPower = State.DesiredJumpPower,
                ApplyWalkSpeed = State.ApplyWalkSpeed,
                ApplyJumpPower = State.ApplyJumpPower,
                ApplyMovementStats = State.ApplyMovementStats,
                ClickTpMethod = State.ClickTpMethod,
                ClickTpTweenTime = State.ClickTpTweenTime,
                GotoMethod = State.GotoMethod,
                GotoTweenTime = State.GotoTweenTime,
                LoopGotoInterval = State.LoopGotoInterval,
                ViewTargetName = State.ViewTargetName,
                GotoTargetName = State.GotoTargetName,
                FlySpeed = State.FlySpeed,
                FloatSpeed = State.FloatSpeed,
                DesyncEnabled = State.DesyncEnabled,
            }

            writefile(State.CONFIG_FILE, HttpService:JSONEncode(cfg))
        end)
    end

    M.saveUserConfig = saveUserConfig
    M.loadUserConfig = loadUserConfig

    pcall(function()
        loadUserConfig()
    end)

    task.spawn(function()
        while task.wait(2) do
            if State.AutoSaveConfigEnabled then
                pcall(saveUserConfig)
            end
        end
    end)

    local _notifyCoreSeq, _notifyCoreLatest
    local _notifyToggleSeq, _notifyToggleLatest

    local function showRobloxNotification(title, text)
        local t = tostring(title)
        if (not State.UiReady) and t ~= "NomNom" then
            return
        end
        if State.SuppressAllNotifications and t ~= "NomNom" then
            return
        end
        _notifyCoreSeq = (_notifyCoreSeq or 0) + 1
        _notifyCoreLatest = _notifyCoreLatest or {}
        local token = _notifyCoreSeq
        _notifyCoreLatest[t] = token
        task.delay(0.6, function()
            if _notifyCoreLatest and _notifyCoreLatest[t] == token then
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = title,
                        Text = text,
                        Duration = 3,
                    })
                end)
            end
        end)
    end
    M.showRobloxNotification = showRobloxNotification

    local function notifyToggle(name, enabled)
        if State.SuppressToggleNotifications then return end
        local n = tostring(name)
        local state = (enabled and "Enabled") or "Disabled"
        _notifyToggleSeq = (_notifyToggleSeq or 0) + 1
        _notifyToggleLatest = _notifyToggleLatest or {}
        local token = _notifyToggleSeq
        _notifyToggleLatest[n] = token
        task.delay(0.6, function()
            if _notifyToggleLatest and _notifyToggleLatest[n] == token then
                showRobloxNotification(n, state)
            end
        end)
    end
    M.notifyToggle = notifyToggle

    local function notifyButton(name, text)
        local msg = (text ~= nil) and tostring(text) or "Clicked"
        showRobloxNotification(tostring(name), msg)
    end
    M.notifyButton = notifyButton

    local function notifyAction(title, actionText)
        local msg = (actionText ~= nil) and tostring(actionText) or ""
        if msg == "" then
            msg = "Running"
        end
        showRobloxNotification(tostring(title), msg)
    end
    M.notifyAction = notifyAction

    State.keyValidated = true

    local FluentOptions
    local SuppressDesyncOptionCallback = false
    M.setFluentOptions = function(opts) FluentOptions = opts end
    M.setSuppressDesyncOptionCallback = function(v) SuppressDesyncOptionCallback = v end
    M.getSuppressDesyncOptionCallback = function() return SuppressDesyncOptionCallback end

    local function setFluentOptionValue(optionKey, value)
        pcall(function()
            if FluentOptions and FluentOptions[optionKey] then
                FluentOptions[optionKey]:SetValue(value)
            end
        end)
    end
    M.setFluentOptionValue = setFluentOptionValue

    local _keybindActionForKey = {}
    local function _normalizeKeyCode(v)
        if typeof(v) == "EnumItem" then
            if v.EnumType == Enum.KeyCode then
                return v
            end
            if v.EnumType == Enum.UserInputType then
                if v == Enum.UserInputType.MouseButton1 or v == Enum.UserInputType.MouseButton2 or v == Enum.UserInputType.MouseButton3 then
                    return v
                end
            end
        end
        if typeof(v) == "string" and v ~= "" then
            local s = tostring(v)
            if s == "MB1" or s == "MouseButton1" then return Enum.UserInputType.MouseButton1 end
            if s == "MB2" or s == "MouseButton2" then return Enum.UserInputType.MouseButton2 end
            if s == "MB3" or s == "MouseButton3" then return Enum.UserInputType.MouseButton3 end
            local uit = Enum.UserInputType[s]
            if uit and (uit == Enum.UserInputType.MouseButton1 or uit == Enum.UserInputType.MouseButton2 or uit == Enum.UserInputType.MouseButton3) then
                return uit
            end
            if Enum.KeyCode[s] then
                return Enum.KeyCode[s]
            end
        end
        return nil
    end

    local function _keybindId(k)
        if typeof(k) ~= "EnumItem" then return nil end
        if k.EnumType == Enum.KeyCode then
            return "KC:" .. k.Name
        end
        if k.EnumType == Enum.UserInputType then
            return "UIT:" .. k.Name
        end
        return nil
    end

    local function setKeybindUnique(actionName, optionKey, newValue, setKeyFn, getKeyFn)
        actionName = tostring(actionName)
        local newKey = _normalizeKeyCode(newValue)
        if not newKey then return end
        local oldKey = getKeyFn()
        if newKey == Enum.KeyCode.Escape then
            newKey = Enum.KeyCode.Unknown
        end

        local oldKeyId = _keybindId(oldKey)
        if oldKeyId and oldKey ~= Enum.KeyCode.Unknown then
            if _keybindActionForKey[oldKeyId] == actionName then
                _keybindActionForKey[oldKeyId] = nil
            end
        end

        if newKey == Enum.KeyCode.Unknown then
            setKeyFn(Enum.KeyCode.Unknown)
            return
        end

        local newKeyId = _keybindId(newKey)
        if not newKeyId then return end

        local existingAction = _keybindActionForKey[newKeyId]
        if existingAction and existingAction ~= actionName then
            showRobloxNotification("Keybind", "Key already used")
            local revert = (oldKey and typeof(oldKey) == "EnumItem") and oldKey.Name or "Unknown"
            pcall(function() setFluentOptionValue(optionKey, revert) end)
            if oldKey and typeof(oldKey) == "EnumItem" then
                setKeyFn(oldKey)
            end
            if oldKeyId and oldKey ~= Enum.KeyCode.Unknown then
                _keybindActionForKey[oldKeyId] = actionName
            end
            return
        end

        _keybindActionForKey[newKeyId] = actionName
        setKeyFn(newKey)
    end
    M.setKeybindUnique = setKeybindUnique

    local toggleDesync

    local rejoin
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if UIS:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.Unknown then return end

        if input.KeyCode == State.DesyncKey then
            pcall(function()
                if toggleDesync then
                    toggleDesync()
                end
            end)

            pcall(function()
                if FluentOptions and FluentOptions.NomNom_Desync then
                    SuppressDesyncOptionCallback = true
                    FluentOptions.NomNom_Desync:SetValue(State.DesyncEnabled)
                    SuppressDesyncOptionCallback = false
                end
            end)
        end
    end)

    local function respawnCharacter()
        local oldCharacter = Player.Character
        pcall(function()
            if oldCharacter then
                local humanoid = oldCharacter:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                else
                    oldCharacter:BreakJoints()
                end
            end
        end)

        pcall(function()
            Player:LoadCharacter()
        end)

        pcall(function()
            local newChar = Player.CharacterAdded:Wait()
            newChar:WaitForChild("HumanoidRootPart", 5)
        end)
    end
    M.respawnCharacter = respawnCharacter

    local function runResetScript()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(State.RESET_SCRIPT_URL))()
        end)
        if not ok then
            showRobloxNotification("Desync", "Reset script failed")
        end
    end
    M.runResetScript = runResetScript

    local function getCharacterRootCFrame()
      local character = Player.Character
      if not character then return nil end
      local hrp = character:FindFirstChild("HumanoidRootPart")
      if not hrp then return nil end
      return hrp.CFrame
    end
    M.getCharacterRootCFrame = getCharacterRootCFrame

    local function setCharacterRootCFrame(cf)
        if typeof(cf) ~= "CFrame" then return end
        local character = Player.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        pcall(function()
            hrp.CFrame = cf
        end)
    end
    M.setCharacterRootCFrame = setCharacterRootCFrame

    local function getLocalHumanoid()
        local c = Player.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end
    M.getLocalHumanoid = getLocalHumanoid

    local function getLocalHRP()
        local c = Player.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    M.getLocalHRP = getLocalHRP

    local function _extractUsernameFromPlayerEntry(name)
        if typeof(name) ~= "string" then return nil end
        local s = tostring(name)
        local extracted = s:match("%(@([^%)]+)%)%s*$")
        if typeof(extracted) == "string" and extracted ~= "" then
            return extracted
        end
        return s
    end

    local function getPlayerByName(name)
        local uname = _extractUsernameFromPlayerEntry(name)
        if typeof(uname) ~= "string" or uname == "" then return nil end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name == uname then
                return plr
            end
        end
        return nil
    end
    M.getPlayerByName = getPlayerByName

    local function getAliveTargetRoot(name)
        local plr = getPlayerByName(name)
        if not plr or not plr.Character then return nil end
        return plr.Character:FindFirstChild("HumanoidRootPart")
    end
    M.getAliveTargetRoot = getAliveTargetRoot

    local antiAfkConn = nil
    local function setAntiAfk(on)
        State.AntiAfkEnabled = (on == true)
        if antiAfkConn then
            pcall(function() antiAfkConn:Disconnect() end)
            antiAfkConn = nil
        end
        if State.AntiAfkEnabled then
            local vu = nil
            pcall(function() vu = game:GetService("VirtualUser") end)
            local vim = nil
            pcall(function() vim = game:GetService("VirtualInputManager") end)
            antiAfkConn = Player.Idled:Connect(function()
                pcall(function()
                    if vu then
                        vu:CaptureController()
                        vu:ClickButton2(Vector2.new())
                    elseif vim then
                        vim:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                        task.wait(0.05)
                        vim:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    end
                end)
            end)
        end
    end
    M.setAntiAfk = setAntiAfk

    Player.CharacterAdded:Connect(function(char)
        task.defer(function()
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    State.BaseWalkSpeed = hum.WalkSpeed
                    State.BaseJumpPower = hum.JumpPower
                end)
            end
        end)
    end)

    local function clampPos(pos,size)
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        return UDim2.fromOffset(
            math.clamp(pos.X.Offset, 6, vp.X - size.X.Offset - 6),
            math.clamp(pos.Y.Offset, 6, vp.Y - size.Y.Offset - 6)
        )
    end
    M.clampPos = clampPos

    local function queueAutoExec()
        if not State.AutoExecEnabled then return end
        local url = nil
        if typeof(State.AutoExecUrl) == "string" and State.AutoExecUrl ~= "" then
            url = State.AutoExecUrl
        else
            pcall(function()
                local env = getgenv and getgenv() or nil
                if typeof(env) == "table" then
                    if typeof(env.NomNomUniversalUrl) == "string" and env.NomNomUniversalUrl ~= "" then
                        url = env.NomNomUniversalUrl
                    elseif typeof(env.NomNomUrl) == "string" and env.NomNomUrl ~= "" then
                        url = env.NomNomUrl
                    elseif typeof(env.ScriptUrl) == "string" and env.ScriptUrl ~= "" then
                        url = env.ScriptUrl
                    end
                end
            end)
        end
        if typeof(url) ~= "string" or url == "" then
            url = State.DEFAULT_AUTOEXEC_URL
        end
        if typeof(url) ~= "string" or url == "" then
            pcall(function()
                if State.notifyAction then
                    State.notifyAction("Auto Exec", "Missing URL")
                end
            end)
            return
        end

        local queuedScript = string.format([[ 
            if getgenv().__TEMP_AUTOEXEC_TEST__ then return end
            getgenv().__TEMP_AUTOEXEC_TEST__ = true
            pcall(function()
                loadstring(game:HttpGet(%q))()
            end)
        ]], url)

        local queueFn = nil
        pcall(function()
            if syn and typeof(syn.queue_on_teleport) == "function" then
                queueFn = syn.queue_on_teleport
            elseif typeof(queue_on_teleport) == "function" then
                queueFn = queue_on_teleport
            elseif fluxus and typeof(fluxus.queue_on_teleport) == "function" then
                queueFn = fluxus.queue_on_teleport
            end
        end)

        if typeof(queueFn) ~= "function" then
            pcall(function()
                if State.UiReady then
                    showRobloxNotification("Auto Exec", "Executor missing queue_on_teleport")
                end
            end)
            return
        end

        pcall(function()
            queueFn(queuedScript)
        end)
    end
    M.queueAutoExec = queueAutoExec

    pcall(queueAutoExec)

    local function waitForHumanoidRootPart(timeoutSeconds)
        local start = os.clock()
        while true do
            local character = Player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp then
                return hrp
            end
            if timeoutSeconds and (os.clock() - start) >= timeoutSeconds then
                return nil
            end
            task.wait(0.05)
        end
    end
    M.waitForHumanoidRootPart = waitForHumanoidRootPart

    local function waitForCharacterDeath(timeoutSeconds)
        local character = Player.Character
        if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        if humanoid.Health <= 0 then return true end

        local died = false
        local conn
        conn = humanoid.Died:Connect(function()
            died = true
            if conn then conn:Disconnect() end
        end)

        local start = os.clock()
        while not died do
            if timeoutSeconds and (os.clock() - start) >= timeoutSeconds then
                if conn then conn:Disconnect() end
                return false
            end
            task.wait(0.05)
            if humanoid.Health <= 0 then
                if conn then conn:Disconnect() end
                return true
            end
        end

        return true
    end
    M.waitForCharacterDeath = waitForCharacterDeath

    local function buildTeleportData()
        return {
            autoExecute = true,
            keyValidated = State.keyValidated,
            CurrentScale = State.CurrentScale,
            ToggleKeyName = State.ToggleKey.Name,
            DesyncKeyName = State.DesyncKey.Name,
            DesyncMethod = State.DesyncMethod,
            AutoExecEnabled = State.AutoExecEnabled,
            AutoExecUrl = State.AutoExecUrl,
            LastPosX = State.LastPos.X.Offset,
            LastPosY = State.LastPos.Y.Offset,
        }
    end
    M.buildTeleportData = buildTeleportData

    local function serverHop()
        local cursor = nil
        for _ = 1, 30 do
            local url = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
            if cursor then
                url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
            end

            local body
            local ok = pcall(function()
                body = game:HttpGet(url)
            end)
            if not ok or not body then
                return
            end

            local data
            local okDecode = pcall(function()
                data = HttpService:JSONDecode(body)
            end)
            if not okDecode or typeof(data) ~= "table" then
                return
            end
            for _,server in ipairs(data.data or {}) do
                if server.playing < server.maxPlayers and server.id ~= JOB_ID then
                    pcall(queueAutoExec)
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, Player, buildTeleportData())
                    return
                end
            end

            cursor = data.nextPageCursor
            if not cursor then
                return
            end
            task.wait(0.1)
        end
    end
    M.serverHop = serverHop

    local function runMethodThenApplyDesync(targetEnabled)
        task.spawn(function()
            local useRejoin = (State.DesyncMethod == "Rejoin")
            if useRejoin then
                pcall(function()
                    setfflag("NextGenReplicatorEnabledWrite4", targetEnabled and "true" or "false")
                end)
                showRobloxNotification("Desync", targetEnabled and "Enabled" or "Disabled")
                task.delay(0.1, function()
                    local start = os.clock()
                    while typeof(rejoin) ~= "function" do
                        if (os.clock() - start) >= 3 then
                            return
                        end
                        task.wait(0.05)
                    end
                    pcall(rejoin)
                end)
                return
            end

            if targetEnabled then
                local waypoint = getCharacterRootCFrame()
                if not waypoint then
                    showRobloxNotification("Desync", "No HRP")
                    return
                end

                local farX = waypoint.Position.X
                for _ = 1, 10 do
                    setCharacterRootCFrame(CFrame.new(farX, 1e8, farX))
                    task.wait(0.1)
                end
                for _ = 1, 10 do
                    runResetScript()
                    task.wait(0.1)
                end
                if not waitForCharacterDeath(6) then
                    showRobloxNotification("Desync", "Timeout")
                    return
                end

                pcall(function()
                    setfflag("NextGenReplicatorEnabledWrite4", "true")
                end)
                showRobloxNotification("Desync", "Enabled")
                respawnCharacter()
                waitForHumanoidRootPart(3)
                for _ = 1, 10 do
                    setCharacterRootCFrame(waypoint)
                    task.wait(0.1)
                end
            else
                local waypoint = getCharacterRootCFrame()

                pcall(function()
                    setfflag("NextGenReplicatorEnabledWrite4", "false")
                end)
                showRobloxNotification("Desync", "Disabled")
                runResetScript()
                waitForHumanoidRootPart(3)

                if waypoint then
                    for _ = 1, 5 do
                        setCharacterRootCFrame(waypoint)
                        task.wait(0.1)
                    end
                end
            end
        end)
    end
    M.runMethodThenApplyDesync = runMethodThenApplyDesync

    rejoin = function()
        local data = nil
        pcall(function()
            if typeof(buildTeleportData) == "function" then
                data = buildTeleportData()
            end
        end)

        pcall(queueAutoExec)

        local ok, err = pcall(function()
            if data ~= nil then
                TeleportService:TeleportToPlaceInstance(PLACE_ID, JOB_ID, Player, data)
            else
                TeleportService:TeleportToPlaceInstance(PLACE_ID, JOB_ID, Player)
            end
        end)
        if ok then return end

        local ok2, err2 = pcall(function()
            if data ~= nil then
                TeleportService:Teleport(PLACE_ID, Player, data)
            else
                TeleportService:Teleport(PLACE_ID, Player)
            end
        end)
        if not ok2 then
            showRobloxNotification("Rejoin", tostring(err2 or err or "Failed"))
        end
    end
    M.rejoin = rejoin

    local function lockDesyncButton(lock)
        State.DesyncButtonLocked = lock
    end

    local function setDesyncEnabled(target)
        if State.DesyncButtonLocked then
            return false
        end
        local targetEnabled = (target == true)
        if targetEnabled == State.DesyncEnabled then return end
        lockDesyncButton(true)
        task.delay(6.5, function()
            lockDesyncButton(false)
        end)

        State.DesyncEnabled = targetEnabled
        pcall(function()
            runMethodThenApplyDesync(targetEnabled)
        end)
        pcall(function()
            if FluentOptions and FluentOptions.NomNom_Desync then
                SuppressDesyncOptionCallback = true
                FluentOptions.NomNom_Desync:SetValue(State.DesyncEnabled)
                SuppressDesyncOptionCallback = false
            end
        end)
    end
    M.setDesyncEnabled = setDesyncEnabled

    toggleDesync = function()
        setDesyncEnabled(not State.DesyncEnabled)
    end
    M.toggleDesync = toggleDesync

    M.init = function() end

    return M
end
