-- controller.lua

return function(ctx, deps)
    local State = ctx.State
    local misc = deps.misc
    local movement = deps.movement
    local visual = deps.visual
    local combat = deps.combat

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
