-- main.lua

return function(ctx)
    local State = ctx.State
    local moduleUrls = {
        ["Misc.lua"] = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/Features/Misc.lua",
        ["Movement.lua"] = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/Features/Movement.lua",
        ["Visual.lua"] = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/Features/Visual.lua",
        ["Combat.lua"] = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/Features/Combat.lua",
        ["Controller.lua"] = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/Features/Controller.lua",
        ["UI.lua"] = nil,
    }

    local function loadModule(path)
        -- 100% online: all modules must be mapped to a URL
        local url = moduleUrls[path]
        if typeof(url) ~= "string" or url == "" then
            error("Missing URL for module: " .. tostring(path))
        end

        local ok, src = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and typeof(src) == "string" then
            return loadstring(src)()
        end

        error("Failed to fetch module: " .. tostring(path))
    end

    local misc = loadModule("Misc.lua")(ctx)
    local movement = loadModule("Movement.lua")(ctx, misc)
    local visual = loadModule("Visual.lua")(ctx, misc)
    local combat = loadModule("Combat.lua")(ctx, misc)
    local controller = loadModule("Controller.lua")(ctx, {
        misc = misc,
        movement = movement,
        visual = visual,
        combat = combat
    })
    local ui = loadModule("UI.lua")(ctx, controller, misc)

    if misc.init then misc.init() end
    if controller.init then controller.init() end
    if ui.init then ui.init() end

    print("[NomNom Universal] ✓ Features ready [80%]")
    print("[NomNom Universal] ✓ UI loading... [90%]")
    print("[NomNom Universal] ✓ Script fully loaded and ready! [100%]")
end
