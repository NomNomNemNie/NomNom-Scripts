-- loader.lua

if _G.__NOMNOM_AUTH ~= true then
    return
end

if _G.__NOMNOM_LOADED then return end
_G.__NOMNOM_LOADED = true

if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("NomNom Universal")
print("[NomNom Universal] Starting initialization... [0%]")

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")

print("[NomNom Universal] Getting player... [30%]")

local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = Player:WaitForChild("PlayerGui")
local PLACE_ID = game.PlaceId
local JOB_ID = game.JobId

print("[NomNom Universal] Services initialized [40%]")
print("[NomNom Universal] Loading configuration... [50%]")

local State = {
    DesyncEnabled = false,
    DesyncButtonLocked = false,
    DesyncKey = Enum.KeyCode.F7,

    BaseSize = UDim2.fromOffset(480, 400),
    CurrentScale = 1,
    LastPos = UDim2.fromOffset(400, 200),
    ToggleKey = Enum.KeyCode.RightControl,
    ListeningKey = false,
    IsBusy = false,
    ToggleCooldown = 0.35,
    keyValidated = false,

    FlyKey = Enum.KeyCode.Unknown,
    NoclipKey = Enum.KeyCode.Unknown,
    ClickTpKey = Enum.KeyCode.Unknown,
    LoopGotoKey = Enum.KeyCode.Unknown,
    FreecamKey = Enum.KeyCode.Unknown,
    OrbitKey = Enum.KeyCode.Unknown,

    FlyEnabled = false,
    NoclipEnabled = false,
    ClickTpEnabled = false,
    LoopGotoEnabled = false,
    FreecamEnabled = false,
    FixcamEnabled = false,
    AntiAfkEnabled = true,
    StatsEnabled = true,
    ViewEnabled = false,
    AirwalkEnabled = false,
    FloatEnabled = false,
    PlayerEspEnabled = false,
    TracersEnabled = false,
    FullbrightEnabled = false,
    OrbitEnabled = false,

    OrbitSpeed = 25,
    OrbitDistance = 10,

    FlySpeed = 60,
    FloatSpeed = 60,

    DesiredWalkSpeed = 16,
    DesiredJumpPower = 50,
    BaseWalkSpeed = 16,
    BaseJumpPower = 50,
    ApplyWalkSpeed = false,
    ApplyJumpPower = false,
    ApplyMovementStats = false,

    ClickTpMethod = "Instant",
    ClickTpTweenTime = 0.6,
    activeClickTpTween = nil,

    GotoTargetName = nil,
    ViewTargetName = nil,
    GotoMethod = "TP",
    GotoTweenTime = 1,
    activeGotoTween = nil,

    LoopGotoInterval = 0.05,

    DesyncMethod = "Respawn",
    RESET_SCRIPT_URL = "https://pastebin.com/raw/MjRWTtLf",
    DEFAULT_AUTOEXEC_URL = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/main/Loader",

    AutoExecEnabled = false,
    AutoExecUrl = "",

    AutoSaveConfigEnabled = true,

    CONFIG_FILE = "NomNom Universal For - " .. tostring(Player and Player.Name or "Player") .. ".json",
    UiReady = false,
    SuppressAllNotifications = true,
    SuppressToggleNotifications = true,
    JoinedAt = os.clock(),
}

local function loadUiLibs(ctx)
    if ctx.UiLibs then return ctx.UiLibs end
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    ctx.UiLibs = { Fluent = Fluent, SaveManager = SaveManager, InterfaceManager = InterfaceManager }
    return ctx.UiLibs
end

local ctx = {
    Services = {
        Players = Players,
        TeleportService = TeleportService,
        HttpService = HttpService,
        UIS = UIS,
        TweenService = TweenService,
        RunService = RunService,
        CAS = CAS,
    },
    Player = Player,
    playerGui = playerGui,
    PLACE_ID = PLACE_ID,
    JOB_ID = JOB_ID,
    State = State,
    loadUiLibs = loadUiLibs,
}

-- load main.lua
local function loadModule(path)
    if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(path) then
        return loadstring(readfile(path))()
    end
    error("Missing readfile or file: " .. tostring(path))
end

local main = loadModule("Main.lua")
main(ctx)
