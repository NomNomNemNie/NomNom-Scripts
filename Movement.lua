-- movement.lua

return function(ctx, misc)
    local Services = ctx.Services
    local UIS = Services.UIS
    local TweenService = Services.TweenService
    local RunService = Services.RunService
    local Players = Services.Players
    local State = ctx.State
    local Player = ctx.Player

    local M = {}

    local function getLocalHumanoid()
        return misc.getLocalHumanoid()
    end
    local function getLocalHRP()
        return misc.getLocalHRP()
    end
    local function getAliveTargetRoot(name)
        return misc.getAliveTargetRoot(name)
    end
    local function showRobloxNotification(a,b)
        return misc.showRobloxNotification(a,b)
    end

    -- Fly
    local flyConn = nil
    local flyOldAutoRotate = nil
    local flyHoldPos = nil
    local flyHoldBP = nil
    function M.setFly(on)
        State.FlyEnabled = (on == true)
        if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
        local hum = getLocalHumanoid()
        local hrp = getLocalHRP()
        if not State.FlyEnabled then
            if flyHoldBP then pcall(function() flyHoldBP:Destroy() end) flyHoldBP = nil end
            flyHoldPos = nil
            if hum and flyOldAutoRotate ~= nil then
                pcall(function() hum.AutoRotate = flyOldAutoRotate end)
            end
            flyOldAutoRotate = nil
            pcall(function()
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end)
            return
        end
        if not hum or not hrp then return end
        pcall(function() if hum.SeatPart then hum.Sit = false end end)
        if flyOldAutoRotate == nil then
            flyOldAutoRotate = hum.AutoRotate
        end
        pcall(function() hum.AutoRotate = false end)
        if not flyHoldBP then
            flyHoldBP = Instance.new("BodyPosition")
            flyHoldBP.Name = "NomNom_FlyHold"
            flyHoldBP.MaxForce = Vector3.new(0, 1e9, 0)
            flyHoldBP.P = 2e4
            flyHoldBP.D = 1e3
            flyHoldBP.Position = hrp.Position
            flyHoldBP.Parent = hrp
        end
        flyHoldPos = hrp.Position

        flyConn = RunService.RenderStepped:Connect(function(dt)
            if not State.FlyEnabled then return end
            local curHrp = getLocalHRP()
            local cam = workspace.CurrentCamera
            if not curHrp or not cam then return end
            local speed = math.clamp(tonumber(State.FlySpeed) or 60, 20, 1000)
            if not flyHoldBP or flyHoldBP.Parent ~= curHrp then
                pcall(function()
                    if flyHoldBP then flyHoldBP.Parent = curHrp end
                end)
            end
            flyHoldPos = curHrp.Position

            local forward = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            if forward.Magnitude > 0 then forward = forward.Unit end
            if right.Magnitude > 0 then right = right.Unit end
            local move = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then move += forward end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move -= forward end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move += right end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move -= right end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
            if move.Magnitude > 0 then
                move = move.Unit
                local delta = move * speed * math.clamp(dt, 0, 0.05)
                pcall(function()
                    curHrp.AssemblyLinearVelocity = Vector3.zero
                    curHrp.AssemblyAngularVelocity = Vector3.zero
                    curHrp.CFrame = curHrp.CFrame + delta
                end)
                flyHoldPos = curHrp.Position
                if flyHoldBP then flyHoldBP.Position = flyHoldPos end
            else
                if flyHoldBP and flyHoldPos then
                    flyHoldBP.Position = Vector3.new(curHrp.Position.X, flyHoldPos.Y, curHrp.Position.Z)
                end
            end
        end)
    end

    -- Airwalk
    local airwalkPart = nil
    local airwalkConn = nil
    function M.setAirwalk(on)
        State.AirwalkEnabled = (on == true)
        if airwalkConn then pcall(function() airwalkConn:Disconnect() end) airwalkConn = nil end
        if airwalkPart then pcall(function() airwalkPart:Destroy() end) airwalkPart = nil end
        if not State.AirwalkEnabled then return end
        airwalkPart = Instance.new("Part")
        airwalkPart.Name = "NomNom_Airwalk"
        airwalkPart.Anchored = true
        airwalkPart.CanCollide = true
        airwalkPart.Size = Vector3.new(10, 1, 10)
        airwalkPart.Transparency = 1
        airwalkPart.Parent = workspace
        airwalkConn = RunService.RenderStepped:Connect(function()
            if not State.AirwalkEnabled or not airwalkPart then return end
            local hrp = getLocalHRP()
            if not hrp then return end
            airwalkPart.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 3.5, hrp.Position.Z)
        end)
    end

    -- Noclip
    local noclipConn = nil
    local noclipRestore = {}
    function M.setNoclip(on)
        State.NoclipEnabled = (on == true)
        if noclipConn then pcall(function() noclipConn:Disconnect() end) noclipConn = nil end
        if not State.NoclipEnabled then
            for part, old in pairs(noclipRestore) do
                if part and part.Parent and part:IsA("BasePart") then
                    pcall(function() part.CanCollide = old end)
                end
            end
            noclipRestore = {}
            return
        end
        noclipConn = RunService.Stepped:Connect(function()
            local c = Player.Character
            if not c then return end
            for _, v in ipairs(c:GetDescendants()) do
                if v:IsA("BasePart") then
                    if noclipRestore[v] == nil then
                        noclipRestore[v] = v.CanCollide
                    end
                    v.CanCollide = false
                end
            end
        end)
    end

    -- Click TP
    local clickTpConn = nil
    function M.setClickTp(on)
        State.ClickTpEnabled = (on == true)
        if clickTpConn then pcall(function() clickTpConn:Disconnect() end) clickTpConn = nil end
        if not State.ClickTpEnabled then
            if State.activeClickTpTween then
                pcall(function() State.activeClickTpTween:Cancel() end)
                State.activeClickTpTween = nil
            end
            return
        end
        showRobloxNotification("Click TP", "Enabled")
        clickTpConn = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            local mousePos = UIS:GetMouseLocation()
            local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = { Player.Character }
            local result = workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
            if result and result.Position then
                local hrp = getLocalHRP()
                if hrp then
                    if State.activeClickTpTween then
                        pcall(function() State.activeClickTpTween:Cancel() end)
                        State.activeClickTpTween = nil
                    end
                    local dest = CFrame.new(result.Position + Vector3.new(0, 3, 0))
                    if State.ClickTpMethod == "Smooth" then
                        local speed = math.clamp(tonumber(State.ClickTpTweenTime) or 60, 1, 5000)
                        local dist = (hrp.Position - dest.Position).Magnitude
                        local t = math.clamp(dist / speed, 0.05, 10)
                        pcall(function()
                            State.activeClickTpTween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = dest })
                            State.activeClickTpTween:Play()
                        end)
                    else
                        pcall(function() hrp.CFrame = dest end)
                    end
                end
            end
        end)
    end

    -- Goto
    local function doGoto(name)
        local targetRoot = getAliveTargetRoot(name)
        local hrp = getLocalHRP()
        if not targetRoot or not hrp then return end

        local dest = targetRoot.CFrame * CFrame.new(0, 0, 2)
        local hum = getLocalHumanoid()
        if hum and hum.SeatPart then
            pcall(function() hum.Sit = false end)
            task.wait(0.1)
        end
        if State.activeGotoTween then
            pcall(function() State.activeGotoTween:Cancel() end)
            State.activeGotoTween = nil
        end
        if State.GotoMethod == "Tween" then
            local speed = math.clamp(tonumber(State.GotoTweenTime) or 60, 1, 5000)
            local dist = (hrp.Position - dest.Position).Magnitude
            local t = math.clamp(dist / speed, 0.05, 10)
            pcall(function()
                State.activeGotoTween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = dest })
                State.activeGotoTween:Play()
            end)
        else
            pcall(function() hrp.CFrame = dest end)
        end

        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    local loopGotoThread = nil
    function M.setGoto(on)
        State.LoopGotoEnabled = (on == true)
        if not State.LoopGotoEnabled then
            if State.activeGotoTween then
                pcall(function() State.activeGotoTween:Cancel() end)
                State.activeGotoTween = nil
            end
            return
        end

        if loopGotoThread then
            return
        end
        if typeof(State.GotoTargetName) == "string" then
            pcall(function() doGoto(State.GotoTargetName) end)
        end
        loopGotoThread = task.spawn(function()
            while State.LoopGotoEnabled do
                if typeof(State.GotoTargetName) == "string" then
                    pcall(function() doGoto(State.GotoTargetName) end)
                end
                task.wait(math.clamp(State.LoopGotoInterval, 0.05, 10))
            end
            loopGotoThread = nil
        end)
    end

    -- Orbit
    local orbitThread = nil
    function M.setOrbit(on)
        State.OrbitEnabled = (on == true)
        if not State.OrbitEnabled then
            return
        end
        if orbitThread then
            return
        end
        orbitThread = task.spawn(function()
            local angle = 0
            while State.OrbitEnabled do
                local targetRoot = (typeof(State.GotoTargetName) == "string") and getAliveTargetRoot(State.GotoTargetName) or nil
                local hrp = getLocalHRP()
                if targetRoot and hrp then
                    local dist = math.clamp(tonumber(State.OrbitDistance) or 10, 1, 500)
                    local spd = math.clamp(tonumber(State.OrbitSpeed) or 25, 1, 100)
                    angle += (spd * math.pi / 180)
                    local offset = Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
                    pcall(function()
                        hrp.CFrame = CFrame.new(targetRoot.Position + offset, targetRoot.Position)
                    end)
                end
                task.wait(0.03)
            end
            orbitThread = nil
        end)
    end

    -- ViewTargetName used by visual module; keep setter in controller/UI.

    -- Float
    local floatConn = nil
    local floatForce = nil
    function M.setFloat(on)
        State.FloatEnabled = (on == true)
        if floatConn then pcall(function() floatConn:Disconnect() end) floatConn = nil end
        if floatForce then pcall(function() floatForce:Destroy() end) floatForce = nil end
        local hrp = getLocalHRP()
        if not State.FloatEnabled or not hrp then return end
        floatForce = Instance.new("BodyPosition")
        floatForce.MaxForce = Vector3.new(0, 1e9, 0)
        floatForce.P = 2e4
        floatForce.D = 1e3
        floatForce.Position = hrp.Position
        floatForce.Parent = hrp
        local height = 6
        floatConn = RunService.RenderStepped:Connect(function(dt)
            if not State.FloatEnabled or not floatForce then return end
            local cur = getLocalHRP()
            if not cur then return end
            local spd = math.clamp(tonumber(State.FloatSpeed) or 60, 20, 1000)
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                height = height + (spd * math.clamp(dt, 0, 0.05))
            elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                height = height - (spd * math.clamp(dt, 0, 0.05))
            end
            height = math.clamp(height, 0, 500)
            floatForce.Position = Vector3.new(cur.Position.X, cur.Position.Y + height, cur.Position.Z)
        end)
		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
    end

    -- Movement stats: WalkSpeed implemented as collision-aware CFrame walk using multiplier
    local loopJumpPowerConn = nil
    local cframeWalkConn = nil

    local function stopCframeWalk()
        if cframeWalkConn then
            pcall(function() cframeWalkConn:Disconnect() end)
            cframeWalkConn = nil
        end
    end

    local function startCframeWalk()
        stopCframeWalk()
        if not (State.ApplyMovementStats and State.ApplyWalkSpeed) then return end

        cframeWalkConn = RunService.RenderStepped:Connect(function(dt)
            if not (State.ApplyMovementStats and State.ApplyWalkSpeed) then return end
            local hum = getLocalHumanoid()
            local hrp = getLocalHRP()
            if not hum or not hrp then return end

            local base = tonumber(State.BaseWalkSpeed)
            if not base or base <= 0 then
                base = tonumber(hum.WalkSpeed) or 16
            end
            local mult = tonumber(State.DesiredWalkSpeed) or 1
            local desired = base * mult
            local extra = math.max(0, desired - base)
            if extra <= 0 then return end

            local md = hum.MoveDirection
            if md.Magnitude <= 0.05 then return end

            local step = extra * math.clamp(dt, 0, 0.05)
            if step <= 0 then return end
            local dir = md.Unit * step

            if not State.NoclipEnabled then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Blacklist
                params.FilterDescendantsInstances = { Player.Character }
                params.IgnoreWater = true

                local origin = hrp.Position
                local result = workspace:Raycast(origin, dir, params)
                if result then
                    local safe = math.max(0, (result.Distance or 0) - 1.25)
                    if safe <= 0 then
                        return
                    end
                    dir = md.Unit * safe
                end
            end

            pcall(function()
                hrp.CFrame = hrp.CFrame + dir
            end)
        end)
    end

    local function startLoopJumpPower()
        if loopJumpPowerConn then return end
        loopJumpPowerConn = RunService.Heartbeat:Connect(function()
            local hum = getLocalHumanoid()
            if State.ApplyMovementStats and State.ApplyJumpPower and hum then
                local base = tonumber(State.BaseJumpPower)
                if not base or base <= 0 then
                    base = tonumber(hum.JumpPower) or 50
                end
                local mult = tonumber(State.DesiredJumpPower) or 1
                pcall(function() hum.JumpPower = base * mult end)
            end
        end)
    end

    function M.startLoops()
        task.defer(function()
            pcall(function()
                local hum = getLocalHumanoid()
                if hum then
                    State.BaseWalkSpeed = tonumber(hum.WalkSpeed) or State.BaseWalkSpeed
                    State.BaseJumpPower = tonumber(hum.JumpPower) or State.BaseJumpPower
                end
            end)
            pcall(startCframeWalk)
            pcall(startLoopJumpPower)
        end)
    end

    function M.resetWalkJump()
        local baseWS = tonumber(State.BaseWalkSpeed) or 16
        local baseJP = tonumber(State.BaseJumpPower) or 50
        State.DesiredWalkSpeed = 1
        State.DesiredJumpPower = 1
        State.ApplyWalkSpeed = false
        State.ApplyJumpPower = false
        State.ApplyMovementStats = false
        pcall(stopCframeWalk)
        pcall(function()
            local hum = getLocalHumanoid()
            if hum then
                hum.WalkSpeed = baseWS
                hum.JumpPower = baseJP
            end
        end)
    end

    return M
end
