-- aimbot.lua

return function(ctx, misc)
    local Services = ctx.Services
    local Players = Services.Players
    local RunService = Services.RunService
    local UIS = Services.UIS
    local GuiService = Services.GuiService
    local State = ctx.State
    local Player = ctx.Player

    local M = {}

    local function getEnv()
        local ok, env = pcall(function()
            if typeof(getgenv) == "function" then
                return getgenv()
            end
            return nil
        end)
        if ok then return env end
        return nil
    end

    local function resolveDrawing()
        local d = rawget(_G, "Drawing")
        if typeof(d) == "table" and typeof(d.new) == "function" then
            return d
        end
        local env = getEnv()
        if typeof(env) == "table" then
            local ed = rawget(env, "Drawing")
            if typeof(ed) == "table" and typeof(ed.new) == "function" then
                return ed
            end
        end
        return nil
    end

    local function resolveMouseMoveRel()
        local fn = rawget(_G, "mousemoverel")
        if typeof(fn) == "function" then
            return fn
        end
        local env = getEnv()
        if typeof(env) == "table" then
            local efn = rawget(env, "mousemoverel")
            if typeof(efn) == "function" then
                return efn
            end
        end
        return nil
    end

    local function getGuiInset()
        if GuiService and GuiService.GetGuiInset then
            local inset = GuiService:GetGuiInset()
            if typeof(inset) == "Vector2" then
                return inset
            end
        end
        return Vector2.zero
    end

    local function getMouseViewportPosition()
        local inset = getGuiInset()
        local pos = UIS:GetMouseLocation()
        return pos - inset
    end

    local aimConn = nil
    local inputConnBegan = nil
    local inputConnEnded = nil
    local currentUpdateMode = "RenderStepped"
    local triggerHeld = false
    local fovCircle = nil
    local fovOutline = nil

    local function newDrawingCircle()
        local d = resolveDrawing()
        if not d then return nil end
        local c = d.new("Circle")
        c.Visible = false
        c.Radius = 120
        c.Thickness = 1
        c.NumSides = 64
        c.Filled = false
        c.Color = Color3.fromRGB(255, 255, 255)
        c.Transparency = 1
        return c
    end

    local config = {
        Enabled = State.AimbotEnabled == true,
        WallCheck = State.AimbotWallCheck == true,
        AliveCheck = State.AimbotAliveCheck ~= false,
        TeamCheck = State.AimbotTeamCheck ~= false,
        TeamCheckOption = State.AimbotTeamCheckOption or "Team",
        UpdateMode = State.AimbotUpdateMode or "RenderStepped",
        TriggerSource = State.AimbotTriggerSource or "MouseButton2",
        LockOn = State.AimbotLockOn == true,
        Sensitivity = 1,
        MousemoverSensitivity = tonumber(State.AimbotMousemoverSensitivity) or 1,
        LockMode = State.AimbotLockMode or "CFrame",
        UseCFrame = State.AimbotUseCFrame ~= false,
        AimPart = State.AimbotAimPart or "Head",
        Prediction = tonumber(State.AimbotPrediction) or 0,
        TriggerKey = State.AimbotTriggerKey or Enum.KeyCode.E,
        Username = State.AimbotUsername,
        Blacklist = State.AimbotBlacklist or {},
        Whitelist = State.AimbotWhitelist or {},
        FOV = {
            Enabled = State.AimbotFOVEnabled == true,
            RainbowColor = State.AimbotFOVRainbowColor == true,
            Filled = State.AimbotFOVFilled == true,
            Visible = State.AimbotFOVVisible ~= false,
            RainbowOutlineColor = State.AimbotFOVRainbowOutlineColor == true,
            Color = State.AimbotFOVColor or Color3.fromRGB(255, 255, 255),
            OutlineColor = State.AimbotFOVOutlineColor or Color3.fromRGB(255, 255, 255),
            LockedColor = State.AimbotFOVLockedColor or Color3.fromRGB(255, 80, 80),
            Radius = tonumber(State.AimbotFOVRadius) or 120,
            NumSides = tonumber(State.AimbotFOVSides) or 64,
            Transparency = tonumber(State.AimbotFOVTransparency) or 0.4,
            Thickness = tonumber(State.AimbotFOVThickness) or 1,
        },
    }

    local function isWhitelisted(name)
        if typeof(config.Whitelist) ~= "table" then return true end
        if next(config.Whitelist) == nil then return true end
        local lower = string.lower(tostring(name or ""))
        for k, v in pairs(config.Whitelist) do
            if v and string.lower(tostring(k)) == lower then return true end
        end
        return false
    end

    local function isBlacklisted(name)
        if typeof(config.Blacklist) ~= "table" then return false end
        local lower = string.lower(tostring(name or ""))
        for k, v in pairs(config.Blacklist) do
            if v and string.lower(tostring(k)) == lower then return true end
        end
        return false
    end

    local function getAimPartFromCharacter(char)
        if not char then return nil end
        if typeof(config.AimPart) == "string" then
            local part = char:FindFirstChild(config.AimPart)
            if part and part:IsA("BasePart") then
                return part
            end
        end
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then return hrp end
        return nil
    end

    local function isTargetValid(plr)
        if not plr or plr == Player then return false end
        if isBlacklisted(plr.Name) then return false end
        if not isWhitelisted(plr.Name) then return false end
        if config.TeamCheck and Player then
            if config.TeamCheckOption == "TeamColor" then
                if Player.Team and plr.Team and Player.TeamColor == plr.TeamColor then return false end
            else
                if Player.Team and plr.Team and Player.Team == plr.Team then return false end
            end
        end
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if config.AliveCheck then
            if not hum or hum.Health <= 0 then
                return false
            end
        end
        return true
    end

    local function wallCheck(fromPos, toPart)
        if not config.WallCheck then return true end
        if not toPart then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local char = Player and Player.Character
        if char then
            params.FilterDescendantsInstances = { char }
        end
        local dir = (toPart.Position - fromPos)
        local result = workspace:Raycast(fromPos, dir, params)
        if not result then return true end
        return result.Instance:IsDescendantOf(toPart.Parent)
    end

    local function getBestTarget()
        local cam = workspace.CurrentCamera
        if not cam then return nil end

        local mousePos = getMouseViewportPosition()
        local maxDist = math.huge
        if config.FOV and config.FOV.Enabled == true then
            maxDist = (config.FOV.Radius or 0)
        end
        local bestPart = nil
        local bestDist = nil

        for _, plr in ipairs(Players:GetPlayers()) do
            if isTargetValid(plr) then
                local part = getAimPartFromCharacter(plr.Character)
                if part then
                    local viewportPos, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(viewportPos.X, viewportPos.Y) - mousePos).Magnitude
                        if dist <= maxDist then
                            if not bestDist or dist < bestDist then
                                if wallCheck(cam.CFrame.Position, part) then
                                    bestDist = dist
                                    bestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end

        return bestPart
    end

    local function rotateCharacterToward(targetPos)
        local char = Player and Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp:IsA("BasePart") then return end
        local look = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
        if (look - hrp.Position).Magnitude < 0.01 then return end
        hrp.CFrame = CFrame.new(hrp.Position, look)
    end

    local function aimAt(part, delta)
        local cam = workspace.CurrentCamera
        if not cam or not part then return end

        local targetPos = part.Position
        local pred = tonumber(config.Prediction) or 0
        if pred ~= 0 then
            local vel = part.AssemblyLinearVelocity or Vector3.zero
            targetPos = targetPos + (vel * pred)
        end

        local viewportPos, onScreen = cam:WorldToViewportPoint(targetPos)
        local moveRel = resolveMouseMoveRel()
        if onScreen and typeof(moveRel) == "function" then
            local mousePos = getMouseViewportPosition()
            local diff = Vector2.new(viewportPos.X, viewportPos.Y) - mousePos
            local sens = math.max(tonumber(config.MousemoverSensitivity) or 1, 0)
            local dx = diff.X * sens
            local dy = diff.Y * sens
            if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
                return
            end
            dx = (dx >= 0) and math.floor(dx + 0.5) or math.ceil(dx - 0.5)
            dy = (dy >= 0) and math.floor(dy + 0.5) or math.ceil(dy - 0.5)
            moveRel(dx, dy)
        end

        if config.LockOn then
            pcall(rotateCharacterToward, targetPos)
        end
    end

    local function destroyFov()
        if fovCircle then pcall(function() fovCircle.Visible = false fovCircle:Remove() end) end
        if fovOutline then pcall(function() fovOutline.Visible = false fovOutline:Remove() end) end
        fovCircle = nil
        fovOutline = nil
    end

    local function updateFovVisual(isLocked)
        if not config.FOV.Enabled or not config.FOV.Visible then
            if fovCircle then fovCircle.Visible = false end
            if fovOutline then fovOutline.Visible = false end
            return
        end
        if not fovCircle then fovCircle = newDrawingCircle() end
        if not fovOutline then fovOutline = newDrawingCircle() end
        if not fovCircle or not fovOutline then return end

        local pos = UIS:GetMouseLocation()
        local t = os.clock()
        local innerColor = config.FOV.Color
        local outlineColor = config.FOV.OutlineColor
        if config.FOV.RainbowColor then
            innerColor = Color3.fromHSV((t % 5) / 5, 1, 1)
        end
        if config.FOV.RainbowOutlineColor then
            outlineColor = Color3.fromHSV((t % 5) / 5, 1, 1)
        end
        if isLocked then
            innerColor = config.FOV.LockedColor or innerColor
        end

        fovCircle.Visible = true
        fovCircle.Position = pos
        fovCircle.Radius = config.FOV.Radius or 120
        fovCircle.NumSides = config.FOV.NumSides or 64
        fovCircle.Filled = config.FOV.Filled == true
        fovCircle.Thickness = config.FOV.Thickness or 1
        fovCircle.Color = innerColor
        fovCircle.Transparency = config.FOV.Transparency or 0.4

        fovOutline.Visible = true
        fovOutline.Position = pos
        fovOutline.Radius = (config.FOV.Radius or 120) + 1
        fovOutline.NumSides = config.FOV.NumSides or 64
        fovOutline.Filled = false
        fovOutline.Thickness = (config.FOV.Thickness or 1) + 1
        fovOutline.Color = outlineColor
        fovOutline.Transparency = config.FOV.Transparency or 0.4
    end

    local function stopLoop()
        if aimConn then
            pcall(function() aimConn:Disconnect() end)
            aimConn = nil
        end
        destroyFov()
        if inputConnBegan then pcall(function() inputConnBegan:Disconnect() end) end
        if inputConnEnded then pcall(function() inputConnEnded:Disconnect() end) end
        inputConnBegan = nil
        inputConnEnded = nil
        triggerHeld = false
    end

    local function startLoop()
        stopLoop()
        if not config.Enabled then return end
        local updateSignal = RunService.RenderStepped
        if config.UpdateMode == "Heartbeat" then
            updateSignal = RunService.Heartbeat
        elseif config.UpdateMode == "Stepped" then
            updateSignal = RunService.Stepped
        end
        currentUpdateMode = config.UpdateMode

        inputConnBegan = UIS.InputBegan:Connect(function(input, gp)
            if config.TriggerSource == "MouseButton2" then
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    triggerHeld = true
                    return
                end
                return
            end
            if gp then return end
            if config.TriggerSource == "Keybind" then
                if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode == config.TriggerKey then
                    triggerHeld = true
                    return
                end
            end
        end)

        inputConnEnded = UIS.InputEnded:Connect(function(input, gp)
            if config.TriggerSource == "MouseButton2" then
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    triggerHeld = false
                    return
                end
                return
            end
            if gp then return end
            if config.TriggerSource == "Keybind" then
                if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode == config.TriggerKey then
                    triggerHeld = false
                    return
                end
            end
        end)

        aimConn = updateSignal:Connect(function(dt)
            if not config.Enabled then return end
            local active = (triggerHeld == true)
            if not active then
                updateFovVisual(false)
                return
            end
            local part = getBestTarget()
            updateFovVisual(part ~= nil)
            if part then
                pcall(aimAt, part, dt)
            end
        end)
    end

    local function applyState()
        State.AimbotEnabled = config.Enabled
        State.AimbotWallCheck = config.WallCheck
        State.AimbotAliveCheck = config.AliveCheck
        State.AimbotTeamCheck = config.TeamCheck
        State.AimbotTeamCheckOption = config.TeamCheckOption
        State.AimbotUpdateMode = config.UpdateMode
        State.AimbotTriggerSource = config.TriggerSource
        State.AimbotLockOn = config.LockOn
        State.AimbotSensitivity = 1
        State.AimbotMousemoverSensitivity = config.MousemoverSensitivity
        State.AimbotLockMode = config.LockMode
        State.AimbotUseCFrame = config.UseCFrame
        State.AimbotAimPart = config.AimPart
        State.AimbotPrediction = config.Prediction
        State.AimbotTriggerKey = config.TriggerKey
        State.AimbotUsername = config.Username
        State.AimbotBlacklist = config.Blacklist
        State.AimbotWhitelist = config.Whitelist
        State.AimbotFOVEnabled = config.FOV.Enabled
        State.AimbotFOVRainbowColor = config.FOV.RainbowColor
        State.AimbotFOVFilled = config.FOV.Filled
        State.AimbotFOVVisible = config.FOV.Visible
        State.AimbotFOVRainbowOutlineColor = config.FOV.RainbowOutlineColor
        State.AimbotFOVColor = config.FOV.Color
        State.AimbotFOVOutlineColor = config.FOV.OutlineColor
        State.AimbotFOVLockedColor = config.FOV.LockedColor
        State.AimbotFOVRadius = config.FOV.Radius
        State.AimbotFOVSides = config.FOV.NumSides
        State.AimbotFOVTransparency = config.FOV.Transparency
        State.AimbotFOVThickness = config.FOV.Thickness
    end

    function M.Enable()
        config.Enabled = true
        applyState()
        startLoop()
    end

    function M.Disable()
        config.Enabled = false
        applyState()
        stopLoop()
    end

    function M.IsEnabled()
        return config.Enabled == true
    end

    function M.SetConfig(cfg)
        if typeof(cfg) ~= "table" then return end
        if cfg.Enabled ~= nil then config.Enabled = (cfg.Enabled == true) end
        if typeof(cfg.WallCheck) == "boolean" then config.WallCheck = cfg.WallCheck end
        if typeof(cfg.AliveCheck) == "boolean" then config.AliveCheck = cfg.AliveCheck end
        if typeof(cfg.TeamCheck) == "boolean" then config.TeamCheck = cfg.TeamCheck end
        if typeof(cfg.TeamCheckOption) == "string" then config.TeamCheckOption = cfg.TeamCheckOption end
        if typeof(cfg.UpdateMode) == "string" then config.UpdateMode = cfg.UpdateMode end
        if typeof(cfg.TriggerSource) == "string" then config.TriggerSource = cfg.TriggerSource end
        if typeof(cfg.LockOn) == "boolean" then config.LockOn = cfg.LockOn end
        if typeof(cfg.Sensitivity) == "number" then config.Sensitivity = 1 end
        if typeof(cfg.MousemoverSensitivity) == "number" then config.MousemoverSensitivity = math.clamp(cfg.MousemoverSensitivity, 0, 10) end
        if typeof(cfg.LockMode) == "string" then config.LockMode = cfg.LockMode end
        if typeof(cfg.UseCFrame) == "boolean" then config.UseCFrame = cfg.UseCFrame end
        if typeof(cfg.AimPart) == "string" then config.AimPart = cfg.AimPart end
        if typeof(cfg.Prediction) == "number" then config.Prediction = math.clamp(cfg.Prediction, -1, 1) end
        if cfg.TriggerKey then
            if typeof(cfg.TriggerKey) == "EnumItem" and cfg.TriggerKey.EnumType == Enum.KeyCode then
                config.TriggerKey = cfg.TriggerKey
            elseif typeof(cfg.TriggerKey) == "string" and Enum.KeyCode[cfg.TriggerKey] then
                config.TriggerKey = Enum.KeyCode[cfg.TriggerKey]
            end
        end
        if typeof(cfg.Username) == "string" then config.Username = cfg.Username end
        if typeof(cfg.Blacklist) == "table" then config.Blacklist = cfg.Blacklist end
        if typeof(cfg.Whitelist) == "table" then config.Whitelist = cfg.Whitelist end
        if typeof(cfg.FOV) == "table" then
            local f = cfg.FOV
            if f.Enabled ~= nil then config.FOV.Enabled = (f.Enabled == true) end
            if typeof(f.RainbowColor) == "boolean" then config.FOV.RainbowColor = f.RainbowColor end
            if typeof(f.Filled) == "boolean" then config.FOV.Filled = f.Filled end
            if typeof(f.Visible) == "boolean" then config.FOV.Visible = f.Visible end
            if typeof(f.RainbowOutlineColor) == "boolean" then config.FOV.RainbowOutlineColor = f.RainbowOutlineColor end
            if typeof(f.Color) == "Color3" then config.FOV.Color = f.Color end
            if typeof(f.OutlineColor) == "Color3" then config.FOV.OutlineColor = f.OutlineColor end
            if typeof(f.LockedColor) == "Color3" then config.FOV.LockedColor = f.LockedColor end
            if typeof(f.Radius) == "number" then config.FOV.Radius = math.clamp(f.Radius, 0, 1000) end
            if typeof(f.NumSides) == "number" then config.FOV.NumSides = math.clamp(f.NumSides, 3, 128) end
            if typeof(f.Transparency) == "number" then config.FOV.Transparency = math.clamp(f.Transparency, 0, 1) end
            if typeof(f.Thickness) == "number" then config.FOV.Thickness = math.clamp(f.Thickness, 0, 10) end
        end
        applyState()
        if config.Enabled then
            startLoop()
        end
    end

    M.enable = M.Enable
    M.disable = M.Disable
    M.setConfig = M.SetConfig

    if config.Enabled then
        startLoop()
    end

    return M
end
