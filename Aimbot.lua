-- aimbot.lua

return function(ctx, misc)
    local Services = ctx.Services
    local Players = Services.Players
    local RunService = Services.RunService
    local UIS = Services.UIS
    local State = ctx.State
    local Player = ctx.Player

    local M = {}

    local aimConn = nil

    local config = {
        Enabled = State.AimbotEnabled == true,
        TeamCheck = State.AimbotTeamCheck ~= false,
        FOVRadius = tonumber(State.AimbotFOVRadius) or 120,
        Smoothness = tonumber(State.AimbotSmoothness) or 0.35,
        AimPart = State.AimbotAimPart or "Head",
        Prediction = tonumber(State.AimbotPrediction) or 0,
    }

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
        if config.TeamCheck and Player and Player.Team and plr.Team and plr.Team == Player.Team then
            return false
        end
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            return false
        end
        return true
    end

    local function getBestTarget()
        local cam = workspace.CurrentCamera
        if not cam then return nil end

        local mousePos = UIS:GetMouseLocation()
        local bestPart = nil
        local bestDist = nil

        for _, plr in ipairs(Players:GetPlayers()) do
            if isTargetValid(plr) then
                local part = getAimPartFromCharacter(plr.Character)
                if part then
                    local viewportPos, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(viewportPos.X, viewportPos.Y) - mousePos).Magnitude
                        if dist <= (config.FOVRadius or 0) then
                            if not bestDist or dist < bestDist then
                                bestDist = dist
                                bestPart = part
                            end
                        end
                    end
                end
            end
        end

        return bestPart
    end

    local function aimAt(part)
        local cam = workspace.CurrentCamera
        if not cam or not part then return end

        local targetPos = part.Position
        local pred = tonumber(config.Prediction) or 0
        if pred ~= 0 then
            local vel = part.AssemblyLinearVelocity or Vector3.zero
            targetPos = targetPos + (vel * pred)
        end

        local smooth = math.clamp(tonumber(config.Smoothness) or 0.35, 0, 1)
        local desired = CFrame.new(cam.CFrame.Position, targetPos)
        cam.CFrame = cam.CFrame:Lerp(desired, smooth)
    end

    local function stopLoop()
        if aimConn then
            pcall(function() aimConn:Disconnect() end)
            aimConn = nil
        end
    end

    local function startLoop()
        stopLoop()
        if not config.Enabled then return end
        aimConn = RunService.RenderStepped:Connect(function()
            if not config.Enabled then return end
            local part = getBestTarget()
            if part then
                pcall(aimAt, part)
            end
        end)
    end

    local function applyState()
        State.AimbotEnabled = config.Enabled
        State.AimbotTeamCheck = config.TeamCheck
        State.AimbotFOVRadius = config.FOVRadius
        State.AimbotSmoothness = config.Smoothness
        State.AimbotAimPart = config.AimPart
        State.AimbotPrediction = config.Prediction
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
        if typeof(cfg.TeamCheck) == "boolean" then config.TeamCheck = cfg.TeamCheck end
        if typeof(cfg.FOVRadius) == "number" then config.FOVRadius = math.clamp(cfg.FOVRadius, 0, 1000) end
        if typeof(cfg.Smoothness) == "number" then config.Smoothness = math.clamp(cfg.Smoothness, 0, 1) end
        if typeof(cfg.AimPart) == "string" then config.AimPart = cfg.AimPart end
        if typeof(cfg.Prediction) == "number" then config.Prediction = math.clamp(cfg.Prediction, -1, 1) end
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
