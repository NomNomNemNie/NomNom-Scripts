-- controller.lua

return function(ctx, deps)
    local State = ctx.State
    local misc = deps.misc
    local movement = deps.movement
    local visual = deps.visual
    local combat = deps.combat
    local aimbot = deps.aimbot

    local C = {}

    function C.init() end

    function C.setDesyncEnabled(v)
        return misc.setDesyncEnabled and misc.setDesyncEnabled(v)
    end
    function C.toggleDesync()
        return misc.toggleDesync and misc.toggleDesync()
    end

    function C.rejoin()
        return misc.rejoin and misc.rejoin()
    end
    function C.serverHop()
        return misc.serverHop and misc.serverHop()
    end
    function C.runResetScript()
        return misc.runResetScript and misc.runResetScript()
    end

    -- Movement
    function C.setFly(v) return movement.setFly and movement.setFly(v) end
    function C.setNoclip(v) return movement.setNoclip and movement.setNoclip(v) end
    function C.setClickTp(v) return movement.setClickTp and movement.setClickTp(v) end
    function C.setGoto(v) return movement.setGoto and movement.setGoto(v) end
    function C.setOrbit(v) return movement.setOrbit and movement.setOrbit(v) end
    function C.setAirwalk(v) return movement.setAirwalk and movement.setAirwalk(v) end
    function C.setFloat(v) return movement.setFloat and movement.setFloat(v) end
    function C.setMovementStats(apply)
        if apply ~= nil then State.ApplyMovementStats = (apply == true) end
        return movement.startLoops and movement.startLoops()
    end
    function C.resetWalkJump()
        if movement.resetWalkJump then movement.resetWalkJump() end
    end

    -- Visual
    function C.setViewEnabled(v) return visual.setViewEnabled and visual.setViewEnabled(v) end
    function C.setViewTarget(name) return visual.setViewTarget and visual.setViewTarget(name) end
    function C.setFixcam(v) return visual.setFixcam and visual.setFixcam(v) end
    function C.setFullbright(v) return visual.setFullbright and visual.setFullbright(v) end
    function C.setFreecam(v) return visual.setFreecam and visual.setFreecam(v) end
    function C.setPlayerEsp(v) return visual.setPlayerEsp and visual.setPlayerEsp(v) end
    function C.setTracers(v) return visual.setTracers and visual.setTracers(v) end
    function C.setOverlayEnabled(v) return visual.setOverlayEnabled and visual.setOverlayEnabled(v) end
    function C.buildPlayerNameList() return visual.buildPlayerNameList and visual.buildPlayerNameList() or {} end

    -- Aimbot
    function C.setAimbotEnabled(v) return aimbot and aimbot.setAimbot and aimbot.setAimbot(v) end
    function C.blacklistAimbotPlayer(name) return aimbot and aimbot.blacklistPlayer and aimbot.blacklistPlayer(name) end
    function C.whitelistAimbotPlayer(name) return aimbot and aimbot.whitelistPlayer and aimbot.whitelistPlayer(name) end
    function C.refreshAimbot() return aimbot and aimbot.refresh and aimbot.refresh() end
    function C.unloadAimbot() return aimbot and aimbot.unload and aimbot.unload() end

    function C.setAimbotConfig(cfg)
        if typeof(cfg) ~= "table" then return end

        -- Aliases from legacy/UI schema used by .vscode/Code.lua
        if cfg.ToggleMode ~= nil and cfg.Toggle == nil then cfg.Toggle = (cfg.ToggleMode == true) end
        if cfg.AimPart ~= nil and cfg.LockPart == nil then cfg.LockPart = cfg.AimPart end
        if cfg.MousemoverSensitivity ~= nil and cfg.Sensitivity2 == nil then cfg.Sensitivity2 = cfg.MousemoverSensitivity end
        if cfg.TeamCheckOption ~= nil and cfg.TeamCheckOption ~= "TeamColor" and cfg.TeamCheckOption ~= "Team" then
            cfg.TeamCheckOption = tostring(cfg.TeamCheckOption)
        end

        if typeof(cfg.FOV) == "table" then
            local f = cfg.FOV
            if f.Visible ~= nil and cfg.FOVVisible == nil then cfg.FOVVisible = (f.Visible == true) end
            if f.Enabled ~= nil and cfg.FOVVisible == nil then cfg.FOVVisible = (f.Enabled == true) end
            if f.Radius ~= nil and cfg.FOVRadius == nil then cfg.FOVRadius = f.Radius end
            if f.NumSides ~= nil and cfg.FOVNumSides == nil then cfg.FOVNumSides = f.NumSides end
            if f.Sides ~= nil and cfg.FOVNumSides == nil then cfg.FOVNumSides = f.Sides end
            if f.Filled ~= nil and cfg.FOVFilled == nil then cfg.FOVFilled = (f.Filled == true) end
            if f.Transparency ~= nil and cfg.FOVTransparency == nil then cfg.FOVTransparency = f.Transparency end
            if f.Thickness ~= nil and cfg.FOVThickness == nil then cfg.FOVThickness = f.Thickness end
            if f.Color ~= nil and cfg.FOVColor == nil then cfg.FOVColor = f.Color end
            if f.LockedColor ~= nil and cfg.FOVLockedColor == nil then cfg.FOVLockedColor = f.LockedColor end
            if f.OutlineColor ~= nil and cfg.FOVOutlineColor == nil then cfg.FOVOutlineColor = f.OutlineColor end

            if f.Rainbow ~= nil and cfg.FOVRainbow == nil then cfg.FOVRainbow = (f.Rainbow == true) end
            if f.RainbowColor ~= nil and cfg.FOVRainbow == nil then cfg.FOVRainbow = (f.RainbowColor == true) end
            if f.RainbowRGB ~= nil and cfg.FOVRainbowRGB == nil then cfg.FOVRainbowRGB = (f.RainbowRGB == true) end
            if f.RainbowOutlineRGB ~= nil and cfg.FOVRainbowOutlineRGB == nil then cfg.FOVRainbowOutlineRGB = (f.RainbowOutlineRGB == true) end
            if f.RainbowOutlineColor ~= nil and cfg.FOVRainbowOutlineRGB == nil then cfg.FOVRainbowOutlineRGB = (f.RainbowOutlineColor == true) end
        end

        if cfg.TeamCheck ~= nil and aimbot and aimbot.setTeamCheck then aimbot.setTeamCheck(cfg.TeamCheck == true) end
        if cfg.WallCheck ~= nil and aimbot and aimbot.setWallCheck then aimbot.setWallCheck(cfg.WallCheck == true) end
        if cfg.AliveCheck ~= nil and aimbot and aimbot.setAliveCheck then aimbot.setAliveCheck(cfg.AliveCheck == true) end
        if cfg.Toggle ~= nil and aimbot and aimbot.setToggle then aimbot.setToggle(cfg.Toggle == true) end
        if cfg.OffsetToMoveDirection ~= nil and aimbot and aimbot.setOffsetToMoveDirection then aimbot.setOffsetToMoveDirection(cfg.OffsetToMoveDirection == true) end

        if cfg.OffsetIncrement ~= nil and aimbot and aimbot.setOffsetIncrement then aimbot.setOffsetIncrement(cfg.OffsetIncrement) end
        if cfg.Sensitivity ~= nil and aimbot and aimbot.setSensitivity then aimbot.setSensitivity(cfg.Sensitivity) end
        if cfg.Sensitivity2 ~= nil and aimbot and aimbot.setSensitivity2 then aimbot.setSensitivity2(cfg.Sensitivity2) end

        if cfg.LockMode ~= nil and aimbot and aimbot.setLockMode then aimbot.setLockMode(cfg.LockMode) end
        if cfg.LockPart ~= nil and aimbot and aimbot.setLockPart then aimbot.setLockPart(cfg.LockPart) end
        if cfg.TriggerKey ~= nil and aimbot and aimbot.setTriggerKey then aimbot.setTriggerKey(cfg.TriggerKey) end

        if cfg.UpdateMode ~= nil and aimbot and aimbot.setUpdateMode then aimbot.setUpdateMode(cfg.UpdateMode) end
        if cfg.TeamCheckOption ~= nil and aimbot and aimbot.setTeamCheckOption then aimbot.setTeamCheckOption(cfg.TeamCheckOption) end
        if cfg.RainbowSpeed ~= nil and aimbot and aimbot.setRainbowSpeed then aimbot.setRainbowSpeed(cfg.RainbowSpeed) end

        if cfg.FOVVisible ~= nil and aimbot and aimbot.setFOVVisible then aimbot.setFOVVisible(cfg.FOVVisible == true) end
        if cfg.FOVRadius ~= nil and aimbot and aimbot.setFOVRadius then aimbot.setFOVRadius(cfg.FOVRadius) end
        if cfg.FOVNumSides ~= nil and aimbot and aimbot.setFOVNumSides then aimbot.setFOVNumSides(cfg.FOVNumSides) end
        if cfg.FOVFilled ~= nil and aimbot and aimbot.setFOVFilled then aimbot.setFOVFilled(cfg.FOVFilled == true) end
        if cfg.FOVTransparency ~= nil and aimbot and aimbot.setFOVTransparency then aimbot.setFOVTransparency(cfg.FOVTransparency) end
        if cfg.FOVThickness ~= nil and aimbot and aimbot.setFOVThickness then aimbot.setFOVThickness(cfg.FOVThickness) end
        if cfg.FOVColor ~= nil and aimbot and aimbot.setFOVColor then aimbot.setFOVColor(cfg.FOVColor) end
        if cfg.FOVRainbow ~= nil and aimbot and aimbot.setFOVRainbow then aimbot.setFOVRainbow(cfg.FOVRainbow == true) end
        if cfg.FOVLockedColor ~= nil and aimbot and aimbot.setFOVLockedColor then aimbot.setFOVLockedColor(cfg.FOVLockedColor) end
        if cfg.FOVOutlineColor ~= nil and aimbot and aimbot.setFOVOutlineColor then aimbot.setFOVOutlineColor(cfg.FOVOutlineColor) end
        if cfg.FOVRainbowRGB ~= nil and aimbot and aimbot.setFOVRainbowRGB then aimbot.setFOVRainbowRGB(cfg.FOVRainbowRGB == true) end
        if cfg.FOVRainbowOutlineRGB ~= nil and aimbot and aimbot.setFOVRainbowOutlineRGB then aimbot.setFOVRainbowOutlineRGB(cfg.FOVRainbowOutlineRGB == true) end
    end

    -- Misc toggles
    function C.setAntiAfk(v) return misc.setAntiAfk and misc.setAntiAfk(v) end

    -- Notify helpers (used by UI)
    function C.notifyToggle(name, enabled) return misc.notifyToggle and misc.notifyToggle(name, enabled) end
    function C.notifyAction(name, text) return misc.notifyAction and misc.notifyAction(name, text) end
    function C.setFluentOptionValue(k, v) return misc.setFluentOptionValue and misc.setFluentOptionValue(k, v) end
    function C.setFluentOptions(opts) return misc.setFluentOptions and misc.setFluentOptions(opts) end
    function C.setSuppressDesyncOptionCallback(v) return misc.setSuppressDesyncOptionCallback and misc.setSuppressDesyncOptionCallback(v) end
    function C.getSuppressDesyncOptionCallback() return misc.getSuppressDesyncOptionCallback and misc.getSuppressDesyncOptionCallback() end
    function C.setKeybindUnique(...) return misc.setKeybindUnique and misc.setKeybindUnique(...) end

    -- Config helpers
    function C.saveUserConfig() return misc.saveUserConfig and misc.saveUserConfig() end
    function C.loadUserConfig() return misc.loadUserConfig and misc.loadUserConfig() end

    -- Place/job copy (stats panel uses constants in visual)
    function C.respawnCharacter() return misc.respawnCharacter and misc.respawnCharacter() end

    return C
end
