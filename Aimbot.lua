return function(ctx, misc)
	local Services = ctx.Services
	local RunService = Services.RunService
	local State = ctx.State
	local Player = ctx.Player

	local M = {}

	local Aimbot = nil
	local Aimbot_Settings = nil
	local Aimbot_DeveloperSettings = nil
	local Aimbot_FOV = nil

	local function showRobloxNotification(title, text)
		return misc.showRobloxNotification(title, text)
	end

	local function loadAimbot()
		local success, result = pcall(function()
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Roblox-Functions-Library/main/Library.lua"))()
		end)
		
		if not success then
			warn("Failed to load Functions Library:", result)
			return false
		end
		
		success, result = pcall(function()
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

	local function applySettings()
		if not Aimbot_Settings then return end
		
		Aimbot_Settings.Enabled = State.AimbotEnabled or false
		Aimbot_Settings.WallCheck = State.AimbotWallCheck or false
		Aimbot_Settings.AliveCheck = State.AimbotAliveCheck or true
		Aimbot_Settings.TeamCheck = State.AimbotTeamCheck or true
		Aimbot_Settings.Toggle = State.AimbotToggle or false
		Aimbot_Settings.OffsetToMoveDirection = State.AimbotOffsetToMoveDirection or false
		Aimbot_Settings.OffsetIncrement = State.AimbotOffsetIncrement or 10
		Aimbot_Settings.Sensitivity = State.AimbotSensitivity or 0
		Aimbot_Settings.Sensitivity2 = State.AimbotSensitivity2 or 1
		Aimbot_Settings.LockMode = State.AimbotLockMode or 1
		Aimbot_Settings.LockPart = State.AimbotLockPart or "Head"
		Aimbot_Settings.TriggerKey = State.AimbotTriggerKey or "MB2"
		
		Aimbot_DeveloperSettings.UpdateMode = State.AimbotUpdateMode or "RenderStepped"
		Aimbot_DeveloperSettings.TeamCheckOption = State.AimbotTeamCheckOption or "TeamColor"
		Aimbot_DeveloperSettings.RainbowSpeed = State.AimbotRainbowSpeed or 1
		
		Aimbot_FOV.Visible = State.AimbotFOVVisible or true
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

	function M.setAimbot(on)
		State.AimbotEnabled = (on == true)
		if not Aimbot then
			if not loadAimbot() then
				warn("Failed to load Aimbot")
				return
			end
			applySettings()
			if Aimbot and Aimbot.Load then
				Aimbot.Load()
			end
		end
		if Aimbot_Settings then
			Aimbot_Settings.Enabled = State.AimbotEnabled
		end
		showRobloxNotification("Aimbot", State.AimbotEnabled and "Enabled" or "Disabled")
	end

	function M.setTeamCheck(on)
		State.AimbotTeamCheck = (on == true)
		if Aimbot_Settings then
			Aimbot_Settings.TeamCheck = State.AimbotTeamCheck
		end
	end

	function M.setWallCheck(on)
		State.AimbotWallCheck = (on == true)
		if Aimbot_Settings then
			Aimbot_Settings.WallCheck = State.AimbotWallCheck
		end
	end

	function M.setAliveCheck(on)
		State.AimbotAliveCheck = (on == true)
		if Aimbot_Settings then
			Aimbot_Settings.AliveCheck = State.AimbotAliveCheck
		end
	end

	function M.setToggle(on)
		State.AimbotToggle = (on == true)
		if Aimbot_Settings then
			Aimbot_Settings.Toggle = State.AimbotToggle
		end
	end

	function M.setOffsetToMoveDirection(on)
		State.AimbotOffsetToMoveDirection = (on == true)
		if Aimbot_Settings then
			Aimbot_Settings.OffsetToMoveDirection = State.AimbotOffsetToMoveDirection
		end
	end

	function M.setOffsetIncrement(value)
		State.AimbotOffsetIncrement = math.clamp(tonumber(value) or 10, 1, 30)
		if Aimbot_Settings then
			Aimbot_Settings.OffsetIncrement = State.AimbotOffsetIncrement
		end
	end

	function M.setSensitivity(value)
		State.AimbotSensitivity = math.clamp(tonumber(value) or 0, 0, 1)
		if Aimbot_Settings then
			Aimbot_Settings.Sensitivity = State.AimbotSensitivity
		end
	end

	function M.setSensitivity2(value)
		State.AimbotSensitivity2 = math.clamp(tonumber(value) or 1, 0, 5)
		if Aimbot_Settings then
			Aimbot_Settings.Sensitivity2 = State.AimbotSensitivity2
		end
	end

	function M.setLockMode(mode)
		if mode == "CFrame" or mode == 1 then
			State.AimbotLockMode = 1
		elseif mode == "mousemoverel" or mode == 2 then
			State.AimbotLockMode = 2
		end
		if Aimbot_Settings then
			Aimbot_Settings.LockMode = State.AimbotLockMode
		end
	end

	function M.setLockPart(part)
		State.AimbotLockPart = part or "Head"
		if Aimbot_Settings then
			Aimbot_Settings.LockPart = State.AimbotLockPart
		end
	end

	function M.setTriggerKey(key)
		State.AimbotTriggerKey = key or "MB2"
		if Aimbot_Settings then
			Aimbot_Settings.TriggerKey = State.AimbotTriggerKey
		end
	end

	function M.setUpdateMode(mode)
		State.AimbotUpdateMode = mode or "RenderStepped"
		if Aimbot_DeveloperSettings then
			Aimbot_DeveloperSettings.UpdateMode = State.AimbotUpdateMode
		end
	end

	function M.setTeamCheckOption(option)
		State.AimbotTeamCheckOption = option or "TeamColor"
		if Aimbot_DeveloperSettings then
			Aimbot_DeveloperSettings.TeamCheckOption = State.AimbotTeamCheckOption
		end
	end

	function M.setRainbowSpeed(speed)
		State.AimbotRainbowSpeed = math.clamp(tonumber(speed) or 1, 0.5, 3)
		if Aimbot_DeveloperSettings then
			Aimbot_DeveloperSettings.RainbowSpeed = State.AimbotRainbowSpeed
		end
	end

	function M.setFOVVisible(on)
		State.AimbotFOVVisible = (on == true)
		if Aimbot_FOV then
			Aimbot_FOV.Visible = State.AimbotFOVVisible
		end
	end

	function M.setFOVRadius(radius)
		State.AimbotFOVRadius = math.clamp(tonumber(radius) or 100, 10, 500)
		if Aimbot_FOV then
			Aimbot_FOV.Radius = State.AimbotFOVRadius
		end
	end

	function M.setFOVNumSides(sides)
		State.AimbotFOVNumSides = math.clamp(tonumber(sides) or 60, 3, 60)
		if Aimbot_FOV then
			Aimbot_FOV.NumSides = State.AimbotFOVNumSides
		end
	end

	function M.setFOVFilled(on)
		State.AimbotFOVFilled = (on == true)
		if Aimbot_FOV then
			Aimbot_FOV.Filled = State.AimbotFOVFilled
		end
	end

	function M.setFOVTransparency(value)
		State.AimbotFOVTransparency = math.clamp(tonumber(value) or 0.5, 0, 1)
		if Aimbot_FOV then
			Aimbot_FOV.Transparency = State.AimbotFOVTransparency
		end
	end

	function M.setFOVThickness(value)
		State.AimbotFOVThickness = math.clamp(tonumber(value) or 1, 1, 5)
		if Aimbot_FOV then
			Aimbot_FOV.Thickness = State.AimbotFOVThickness
		end
	end

	function M.setFOVColor(color)
		State.AimbotFOVColor = color or Color3.fromRGB(255, 255, 255)
		if Aimbot_FOV then
			Aimbot_FOV.Color = State.AimbotFOVColor
		end
	end

	function M.setFOVRainbow(on)
		State.AimbotFOVRainbow = (on == true)
		if Aimbot_FOV then
			Aimbot_FOV.Rainbow = State.AimbotFOVRainbow
		end
	end

	function M.setFOVLockedColor(color)
		State.AimbotFOVLockedColor = color or Color3.fromRGB(255, 70, 70)
		if Aimbot_FOV then
			Aimbot_FOV.LockedColor = State.AimbotFOVLockedColor
		end
	end

	function M.setFOVOutlineColor(color)
		State.AimbotFOVOutlineColor = color or Color3.fromRGB(0, 0, 0)
		if Aimbot_FOV and Aimbot_FOV.OutlineColor then
			Aimbot_FOV.OutlineColor = State.AimbotFOVOutlineColor
		end
	end

	function M.setFOVRainbowRGB(on)
		State.AimbotFOVRainbowRGB = (on == true)
		if Aimbot_FOV and Aimbot_FOV.RainbowRGB then
			Aimbot_FOV.RainbowRGB = State.AimbotFOVRainbowRGB
		end
	end

	function M.setFOVRainbowOutlineRGB(on)
		State.AimbotFOVRainbowOutlineRGB = (on == true)
		if Aimbot_FOV and Aimbot_FOV.RainbowOutlineRGB then
			Aimbot_FOV.RainbowOutlineRGB = State.AimbotFOVRainbowOutlineRGB
		end
	end

	function M.blacklistPlayer(playerName)
		if not Aimbot then return end
		pcall(Aimbot.Blacklist, Aimbot, playerName)
		showRobloxNotification("Blacklist", playerName)
	end

	function M.whitelistPlayer(playerName)
		if not Aimbot then return end
		pcall(Aimbot.Whitelist, Aimbot, playerName)
		showRobloxNotification("Whitelist", playerName)
	end

	function M.refresh()
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
		showRobloxNotification("Aimbot", "Unloaded")
	end

	return M
end