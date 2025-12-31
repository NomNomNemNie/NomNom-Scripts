return function(ctx, misc)
	local Services = ctx.Services
	local State = ctx.State
	local httpGet = ctx.httpGet

	local M = {}

	local Aimbot = nil
	local Aimbot_Settings = nil
	local Aimbot_DeveloperSettings = nil
	local Aimbot_FOV = nil
	local _loadedOnce = false

	local function showRobloxNotification(title, text)
		return misc.showRobloxNotification(title, text)
	end

	local function loadAimbot()
		local success, result = pcall(function()
			if typeof(httpGet) == "function" then
				return loadstring(httpGet("https://raw.githubusercontent.com/Exunys/Roblox-Functions-Library/main/Library.lua"))()
			end
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Roblox-Functions-Library/main/Library.lua"))()
		end)
		if not success then
			warn("Failed to load Functions Library:", result)
			return false
		end

		success, result = pcall(function()
			if typeof(httpGet) == "function" then
				return loadstring(httpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()
			end
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()
		end)
		if not success then
			warn("Failed to load Aimbot:", result)
			return false
		end

		Aimbot = result
		Aimbot_Settings = Aimbot.Settings
		Aimbot_DeveloperSettings = Aimbot.DeveloperSettings
		Aimbot_FOV = Aimbot.FOVSettings
		return true
	end

	local function _normalizeLockMode(v)
		if v == 1 or v == 2 then return v end
		if typeof(v) == "string" then
			if v == "CFrame" then return 1 end
			if v == "mousemoverel" then return 2 end
		end
		return 1
	end

	local function _normalizeTriggerKey(v)
		if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
			return v.Name
		end
		if typeof(v) == "string" and v ~= "" then
			return v
		end
		return "MB2"
	end

	local function applySettings()
		if not Aimbot_Settings then return end

		Aimbot_Settings.Enabled = State.AimbotEnabled or false
		Aimbot_Settings.WallCheck = State.AimbotWallCheck or false
		Aimbot_Settings.AliveCheck = (State.AimbotAliveCheck ~= false)
		Aimbot_Settings.TeamCheck = (State.AimbotTeamCheck ~= false)
		Aimbot_Settings.Toggle = State.AimbotToggle or false
		Aimbot_Settings.OffsetToMoveDirection = State.AimbotOffsetToMoveDirection or false
		Aimbot_Settings.OffsetIncrement = State.AimbotOffsetIncrement or 10
		Aimbot_Settings.Sensitivity = State.AimbotSensitivity or 0
		Aimbot_Settings.Sensitivity2 = State.AimbotSensitivity2 or 1
		Aimbot_Settings.LockMode = _normalizeLockMode(State.AimbotLockMode)
		Aimbot_Settings.LockPart = State.AimbotLockPart or "Head"
		Aimbot_Settings.TriggerKey = _normalizeTriggerKey(State.AimbotTriggerKey)

		if Aimbot_DeveloperSettings then
			Aimbot_DeveloperSettings.UpdateMode = State.AimbotUpdateMode or "RenderStepped"
			Aimbot_DeveloperSettings.TeamCheckOption = State.AimbotTeamCheckOption or "TeamColor"
			Aimbot_DeveloperSettings.RainbowSpeed = State.AimbotRainbowSpeed or 1
		end

		if Aimbot_FOV then
			Aimbot_FOV.Visible = (State.AimbotFOVVisible ~= false)
			Aimbot_FOV.Radius = State.AimbotFOVRadius or 100
			Aimbot_FOV.NumSides = State.AimbotFOVNumSides or 60
			Aimbot_FOV.Filled = State.AimbotFOVFilled or false
			Aimbot_FOV.Transparency = State.AimbotFOVTransparency or 0.5
			Aimbot_FOV.Thickness = State.AimbotFOVThickness or 1
			Aimbot_FOV.Color = State.AimbotFOVColor or Color3.fromRGB(255, 255, 255)
			Aimbot_FOV.Rainbow = State.AimbotFOVRainbow or false
			Aimbot_FOV.LockedColor = State.AimbotFOVLockedColor or Color3.fromRGB(255, 70, 70)
			if Aimbot_FOV.OutlineColor then
				Aimbot_FOV.OutlineColor = State.AimbotFOVOutlineColor or Color3.fromRGB(0, 0, 0)
			end
			if Aimbot_FOV.RainbowRGB then
				Aimbot_FOV.RainbowRGB = State.AimbotFOVRainbowRGB or false
			end
			if Aimbot_FOV.RainbowOutlineRGB then
				Aimbot_FOV.RainbowOutlineRGB = State.AimbotFOVRainbowOutlineRGB or false
			end
		end
	end

	local function ensureLoaded()
		if _loadedOnce then return true end
		if not Aimbot then
			if not loadAimbot() then
				return false
			end
		end
		applySettings()
		if Aimbot and Aimbot.Load then
			pcall(function() Aimbot.Load() end)
		end
		_loadedOnce = true
		return true
	end

	function M.setAimbot(on)
		State.AimbotEnabled = (on == true)
		if not ensureLoaded() then return end
		if Aimbot_Settings then
			Aimbot_Settings.Enabled = State.AimbotEnabled
		end
		showRobloxNotification("Aimbot", State.AimbotEnabled and "Enabled" or "Disabled")
	end

	function M.setTeamCheck(on)
		State.AimbotTeamCheck = (on == true)
		if Aimbot_Settings then Aimbot_Settings.TeamCheck = State.AimbotTeamCheck end
	end

	function M.setWallCheck(on)
		State.AimbotWallCheck = (on == true)
		if Aimbot_Settings then Aimbot_Settings.WallCheck = State.AimbotWallCheck end
	end

	function M.setAliveCheck(on)
		State.AimbotAliveCheck = (on == true)
		if Aimbot_Settings then Aimbot_Settings.AliveCheck = State.AimbotAliveCheck end
	end

	function M.setToggle(on)
		State.AimbotToggle = (on == true)
		if Aimbot_Settings then Aimbot_Settings.Toggle = State.AimbotToggle end
	end

	function M.setOffsetToMoveDirection(on)
		State.AimbotOffsetToMoveDirection = (on == true)
		if Aimbot_Settings then Aimbot_Settings.OffsetToMoveDirection = State.AimbotOffsetToMoveDirection end
	end

	function M.setOffsetIncrement(value)
		State.AimbotOffsetIncrement = math.clamp(tonumber(value) or 10, 1, 30)
		if Aimbot_Settings then Aimbot_Settings.OffsetIncrement = State.AimbotOffsetIncrement end
	end

	function M.setSensitivity(value)
		State.AimbotSensitivity = math.clamp(tonumber(value) or 0, 0, 1)
		if Aimbot_Settings then Aimbot_Settings.Sensitivity = State.AimbotSensitivity end
	end

	function M.setSensitivity2(value)
		State.AimbotSensitivity2 = math.clamp(tonumber(value) or 1, 0, 5)
		if Aimbot_Settings then Aimbot_Settings.Sensitivity2 = State.AimbotSensitivity2 end
	end

	function M.setLockMode(mode)
		State.AimbotLockMode = _normalizeLockMode(mode)
		if Aimbot_Settings then Aimbot_Settings.LockMode = State.AimbotLockMode end
	end

	function M.setLockPart(part)
		State.AimbotLockPart = part or "Head"
		if Aimbot_Settings then Aimbot_Settings.LockPart = State.AimbotLockPart end
	end

	function M.setTriggerKey(key)
		State.AimbotTriggerKey = key
		if Aimbot_Settings then Aimbot_Settings.TriggerKey = _normalizeTriggerKey(State.AimbotTriggerKey) end
	end

	function M.setUpdateMode(mode)
		State.AimbotUpdateMode = mode or "RenderStepped"
		if Aimbot_DeveloperSettings then Aimbot_DeveloperSettings.UpdateMode = State.AimbotUpdateMode end
	end

	function M.setTeamCheckOption(option)
		State.AimbotTeamCheckOption = option or "TeamColor"
		if Aimbot_DeveloperSettings then Aimbot_DeveloperSettings.TeamCheckOption = State.AimbotTeamCheckOption end
	end

	function M.setRainbowSpeed(speed)
		State.AimbotRainbowSpeed = math.clamp(tonumber(speed) or 1, 0.5, 3)
		if Aimbot_DeveloperSettings then Aimbot_DeveloperSettings.RainbowSpeed = State.AimbotRainbowSpeed end
	end

	function M.setFOVVisible(on)
		State.AimbotFOVVisible = (on == true)
		if Aimbot_FOV then Aimbot_FOV.Visible = State.AimbotFOVVisible end
	end

	function M.setFOVRadius(radius)
		State.AimbotFOVRadius = math.clamp(tonumber(radius) or 100, 0, 720)
		if Aimbot_FOV then Aimbot_FOV.Radius = State.AimbotFOVRadius end
	end

	function M.setFOVNumSides(sides)
		State.AimbotFOVNumSides = math.clamp(tonumber(sides) or 60, 3, 128)
		if Aimbot_FOV then Aimbot_FOV.NumSides = State.AimbotFOVNumSides end
	end

	function M.setFOVFilled(on)
		State.AimbotFOVFilled = (on == true)
		if Aimbot_FOV then Aimbot_FOV.Filled = State.AimbotFOVFilled end
	end

	function M.setFOVTransparency(value)
		State.AimbotFOVTransparency = math.clamp(tonumber(value) or 0.5, 0, 1)
		if Aimbot_FOV then Aimbot_FOV.Transparency = State.AimbotFOVTransparency end
	end

	function M.setFOVThickness(value)
		State.AimbotFOVThickness = math.clamp(tonumber(value) or 1, 0, 10)
		if Aimbot_FOV then Aimbot_FOV.Thickness = State.AimbotFOVThickness end
	end

	function M.setFOVColor(color)
		State.AimbotFOVColor = color or Color3.fromRGB(255, 255, 255)
		if Aimbot_FOV then Aimbot_FOV.Color = State.AimbotFOVColor end
	end

	function M.setFOVRainbow(on)
		State.AimbotFOVRainbow = (on == true)
		if Aimbot_FOV then Aimbot_FOV.Rainbow = State.AimbotFOVRainbow end
	end

	function M.setFOVLockedColor(color)
		State.AimbotFOVLockedColor = color or Color3.fromRGB(255, 70, 70)
		if Aimbot_FOV then Aimbot_FOV.LockedColor = State.AimbotFOVLockedColor end
	end

	function M.setFOVOutlineColor(color)
		State.AimbotFOVOutlineColor = color or Color3.fromRGB(0, 0, 0)
		if Aimbot_FOV and Aimbot_FOV.OutlineColor then Aimbot_FOV.OutlineColor = State.AimbotFOVOutlineColor end
	end

	function M.setFOVRainbowRGB(on)
		State.AimbotFOVRainbowRGB = (on == true)
		if Aimbot_FOV and Aimbot_FOV.RainbowRGB then Aimbot_FOV.RainbowRGB = State.AimbotFOVRainbowRGB end
	end

	function M.setFOVRainbowOutlineRGB(on)
		State.AimbotFOVRainbowOutlineRGB = (on == true)
		if Aimbot_FOV and Aimbot_FOV.RainbowOutlineRGB then Aimbot_FOV.RainbowOutlineRGB = State.AimbotFOVRainbowOutlineRGB end
	end

	function M.blacklistPlayer(playerName)
		if not ensureLoaded() then return end
		pcall(Aimbot.Blacklist, Aimbot, playerName)
		showRobloxNotification("Blacklist", playerName)
	end

	function M.whitelistPlayer(playerName)
		if not ensureLoaded() then return end
		pcall(Aimbot.Whitelist, Aimbot, playerName)
		showRobloxNotification("Whitelist", playerName)
	end

	function M.refresh()
		if not ensureLoaded() then return end
		if Aimbot and Aimbot.Restart then
			Aimbot.Restart()
			showRobloxNotification("Aimbot", "Refreshed")
		end
	end

	function M.unload()
		if Aimbot and Aimbot.Exit then
			Aimbot:Exit()
		end
		Aimbot = nil
		Aimbot_Settings = nil
		Aimbot_DeveloperSettings = nil
		Aimbot_FOV = nil
		_loadedOnce = false
		showRobloxNotification("Aimbot", "Unloaded")
	end

	pcall(function()
		ensureLoaded()
	end)

	return M
end
