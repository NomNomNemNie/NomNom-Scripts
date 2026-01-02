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
	local _aimAssistConn = nil
	local _prevMouseBehavior = nil
	local _toggleInputConn = nil
	local _triggerInputBeganConn = nil
	local _triggerInputEndedConn = nil
	local _triggerHeld = false
	local _forcedMouseLock = false
	local _mouseBehaviorBeforeForce = nil
	local _toggleAimOn = false
	local _aimAssistBindName = "NomNom_AimbotAimAssist"
	local _restartQueued = false

	local function showRobloxNotification(title, text)
		return misc.showRobloxNotification(title, text)
	end

	local function requestRestart()
		if _restartQueued then return end
		_restartQueued = true
		task.delay(0.05, function()
			_restartQueued = false
			if Aimbot and Aimbot.Restart then
				pcall(function() Aimbot.Restart() end)
			end
		end)
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
		-- Exunys Aimbot-V3 expects an EnumItem (KeyCode or UserInputType)
		if typeof(v) == "EnumItem" then
			if v.EnumType == Enum.KeyCode then
				if v == Enum.KeyCode.MouseButton1 then return Enum.UserInputType.MouseButton1 end
				if v == Enum.KeyCode.MouseButton2 then return Enum.UserInputType.MouseButton2 end
				if v == Enum.KeyCode.MouseButton3 then return Enum.UserInputType.MouseButton3 end
				return v
			end
			if v.EnumType == Enum.UserInputType then
				return v
			end
		end
		if typeof(v) == "string" and v ~= "" then
			local s = tostring(v)
			if s == "RMB" or s == "MouseRight" or s == "RightMouse" or s == "RightMouseButton" then return Enum.UserInputType.MouseButton2 end
			if s == "LMB" or s == "MouseLeft" or s == "LeftMouse" or s == "LeftMouseButton" then return Enum.UserInputType.MouseButton1 end
			if s == "MMB" or s == "MouseMiddle" or s == "MiddleMouse" or s == "MiddleMouseButton" then return Enum.UserInputType.MouseButton3 end
			if s == "MB1" or s == "MouseButton1" then return Enum.UserInputType.MouseButton1 end
			if s == "MB2" or s == "MouseButton2" then return Enum.UserInputType.MouseButton2 end
			if s == "MB3" or s == "MouseButton3" then return Enum.UserInputType.MouseButton3 end
			local kc = Enum.KeyCode[s]
			if kc then return kc end
		end
		return Enum.UserInputType.MouseButton2
	end

	local function applySettings()
		if not Aimbot_Settings then return end

		Aimbot_Settings.Enabled = State.AimbotEnabled or false
		State.AimbotWallCheck = false
		Aimbot_Settings.WallCheck = false
		Aimbot_Settings.AliveCheck = (State.AimbotAliveCheck ~= false)
		Aimbot_Settings.TeamCheck = (State.AimbotTeamCheck ~= false)
		Aimbot_Settings.Toggle = State.AimbotToggleMode or false
		Aimbot_Settings.OffsetToMoveDirection = State.AimbotOffsetToMoveDirection or false
		Aimbot_Settings.OffsetIncrement = State.AimbotOffsetIncrement or 10
		Aimbot_Settings.Sensitivity = State.AimbotSensitivity or 0
		Aimbot_Settings.Sensitivity2 = State.AimbotSensitivity2 or 1
		Aimbot_Settings.LockMode = _normalizeLockMode(State.AimbotLockMode)
		Aimbot_Settings.LockPart = State.AimbotLockPart or "Head"
		Aimbot_Settings.TriggerKey = _normalizeTriggerKey(State.AimbotTriggerKey)
		if Aimbot_Settings.LockOn ~= nil then
			Aimbot_Settings.LockOn = (State.AimbotLockOn == true)
		end
		if Aimbot_Settings.Prediction ~= nil and State.AimbotPrediction ~= nil then
			Aimbot_Settings.Prediction = State.AimbotPrediction
		end

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
			local fovRainbow = (State.AimbotFOVRainbow ~= nil and State.AimbotFOVRainbow) or (State.AimbotFOVRainbowColor == true)
			local fovOutlineRainbow = (State.AimbotFOVRainbowOutlineRGB ~= nil and State.AimbotFOVRainbowOutlineRGB) or (State.AimbotFOVRainbowOutlineColor == true)
			Aimbot_FOV.Rainbow = fovRainbow or false
			if Aimbot_FOV.RainbowColor ~= nil then
				Aimbot_FOV.RainbowColor = fovRainbow or false
			end
			if Aimbot_FOV.RainbowOutlineColor ~= nil then
				Aimbot_FOV.RainbowOutlineColor = fovOutlineRainbow or false
			end
			Aimbot_FOV.LockedColor = State.AimbotFOVLockedColor or Color3.fromRGB(255, 70, 70)
			if Aimbot_FOV.OutlineColor then
				Aimbot_FOV.OutlineColor = State.AimbotFOVOutlineColor or Color3.fromRGB(0, 0, 0)
			end
			if Aimbot_FOV.RainbowRGB then
				Aimbot_FOV.RainbowRGB = fovRainbow or false
			end
			if Aimbot_FOV.RainbowOutlineRGB then
				Aimbot_FOV.RainbowOutlineRGB = fovOutlineRainbow or false
			end
		end
	end

	local function _getClosestTargetInFov()
		local Players = Services and Services.Players
		if not Players then return nil end
		local cam = workspace and workspace.CurrentCamera
		if not cam then return nil end
		local localPlayer = Players.LocalPlayer
		if not localPlayer then return nil end

		local mousePos = nil
		pcall(function()
			local vp = cam.ViewportSize
			local UIS = Services and Services.UIS
			if UIS and typeof(UIS.GetMouseLocation) == "function" then
				mousePos = UIS:GetMouseLocation()
			else
				mousePos = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
			end
		end)
		if not mousePos then return nil end

		local radius = tonumber(State.AimbotFOVRadius) or 120
		local bestPlr, bestDist = nil, math.huge

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= localPlayer then
				local char = plr.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if char and hum and hum.Health > 0 then
					local okTeam = true
					if State.AimbotTeamCheck == true then
						pcall(function()
							if State.AimbotTeamCheckOption == "TeamColor" then
								okTeam = (plr.TeamColor ~= localPlayer.TeamColor)
							else
								okTeam = (plr.Team ~= localPlayer.Team)
							end
						end)
					end

					if okTeam then
						local partName = tostring(State.AimbotLockPart or "Head")
						local part = char:FindFirstChild(partName) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
						if part then
							local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
							if onScreen and screenPos.Z > 0 then
								local d = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
								if d <= radius and d < bestDist then
									bestDist = d
									bestPlr = plr
								end
							end
						end
					end
				end
			end
		end

		return bestPlr
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

		-- Lock mouse to center only while actually aiming at a valid target.
		pcall(function()
			local UIS = Services and Services.UIS
			local RunService = Services and Services.RunService
			local Players = Services and Services.Players
			if typeof(UIS) ~= "Instance" or typeof(RunService) ~= "Instance" or typeof(Players) ~= "Instance" then return end

			if _aimAssistConn then _aimAssistConn:Disconnect() end
			if _toggleInputConn then _toggleInputConn:Disconnect() end
			if _triggerInputBeganConn then _triggerInputBeganConn:Disconnect() end
			if _triggerInputEndedConn then _triggerInputEndedConn:Disconnect() end
			_forcedMouseLock = false
			_mouseBehaviorBeforeForce = nil
			_toggleAimOn = false
			_triggerHeld = false
			_prevMouseBehavior = UIS.MouseBehavior

			_toggleInputConn = nil

			_triggerInputBeganConn = UIS.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if State.AimbotEnabled ~= true then return end
				local key = _normalizeTriggerKey(State.AimbotTriggerKey)
				if typeof(key) ~= "EnumItem" then return end

				local matches = false
				if key.EnumType == Enum.UserInputType then
					matches = (input.UserInputType == key)
				elseif key.EnumType == Enum.KeyCode then
					matches = (input.KeyCode == key)
				end
				if not matches then return end

				if State.AimbotToggleMode == true then
					_toggleAimOn = not _toggleAimOn
				else
					_triggerHeld = true
				end
			end)

			_triggerInputEndedConn = UIS.InputEnded:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if State.AimbotEnabled ~= true then return end
				if State.AimbotToggleMode == true then return end

				local key = _normalizeTriggerKey(State.AimbotTriggerKey)
				if typeof(key) ~= "EnumItem" then return end

				local matches = false
				if key.EnumType == Enum.UserInputType then
					matches = (input.UserInputType == key)
				elseif key.EnumType == Enum.KeyCode then
					matches = (input.KeyCode == key)
				end
				if not matches then return end

				_triggerHeld = false
			end)

			pcall(function()
				RunService:UnbindFromRenderStep(_aimAssistBindName)
			end)
			_aimAssistConn = nil

			RunService:BindToRenderStep(_aimAssistBindName, Enum.RenderPriority.Camera.Value + 1, function()

				local rawLockMode = State.AimbotLockMode
				local lockMode = _normalizeLockMode(rawLockMode)
				local useCFrame = false
				if rawLockMode ~= nil then
					useCFrame = (lockMode == 1)
				else
					useCFrame = (State.AimbotUseCFrame == true)
				end

				local aiming = false
				local targetPlr = nil
				local wantLock = false
				local triggerActive = false
				if State.AimbotEnabled == true then
					if State.AimbotToggleMode == true then
						triggerActive = (_toggleAimOn == true)
					else
						triggerActive = (_triggerHeld == true)
					end
				end

				if triggerActive then
					targetPlr = _getClosestTargetInFov()
					aiming = (targetPlr ~= nil)
				end

				local shouldAim = (triggerActive and aiming)
				wantLock = (shouldAim and lockMode == 1 and useCFrame)

				if wantLock then
					if not _forcedMouseLock then
						_forcedMouseLock = true
						_mouseBehaviorBeforeForce = UIS.MouseBehavior
					end
					if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
						UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
					end
				else
					if _forcedMouseLock then
						if _mouseBehaviorBeforeForce and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
							UIS.MouseBehavior = _mouseBehaviorBeforeForce
						end
						_forcedMouseLock = false
						_mouseBehaviorBeforeForce = nil
					end
				end

				-- Keep character facing the same target while aiming.
				if shouldAim and State.AimbotLockOn == true and targetPlr then
					local char = Players.LocalPlayer and Players.LocalPlayer.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					local tchar = targetPlr.Character
					local tpart = tchar and (tchar:FindFirstChild("HumanoidRootPart") or tchar:FindFirstChild("Head"))
					if hrp and tpart then
						local pos = hrp.Position
						local look = Vector3.new(tpart.Position.X, pos.Y, tpart.Position.Z)
						hrp.CFrame = CFrame.new(pos, look)
					end
				end
			end)
		end)

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
		State.AimbotWallCheck = false
		if Aimbot_Settings then Aimbot_Settings.WallCheck = false end
	end

	function M.setAliveCheck(on)
		State.AimbotAliveCheck = (on == true)
		if Aimbot_Settings then Aimbot_Settings.AliveCheck = State.AimbotAliveCheck end
	end

	function M.setToggle(on)
		State.AimbotToggleMode = (on == true)
		if Aimbot_Settings then Aimbot_Settings.Toggle = State.AimbotToggleMode end
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
		State.AimbotSensitivity2 = math.clamp(tonumber(value) or 2, 2, 10)
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

	function M.setLockOn(on)
		State.AimbotLockOn = (on == true)
		if Aimbot_Settings and Aimbot_Settings.LockOn ~= nil then
			Aimbot_Settings.LockOn = State.AimbotLockOn
		end
	end

	function M.setPrediction(value)
		State.AimbotPrediction = tonumber(value) or 0
		if Aimbot_Settings and Aimbot_Settings.Prediction ~= nil then
			Aimbot_Settings.Prediction = State.AimbotPrediction
		end
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
		requestRestart()
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
		if Aimbot_FOV then
			if Aimbot_FOV.Rainbow ~= nil then Aimbot_FOV.Rainbow = State.AimbotFOVRainbow end
			if Aimbot_FOV.RainbowColor ~= nil then Aimbot_FOV.RainbowColor = State.AimbotFOVRainbow end
			if Aimbot_FOV.RainbowRGB ~= nil then Aimbot_FOV.RainbowRGB = State.AimbotFOVRainbow end
		end
		requestRestart()
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
		requestRestart()
	end

	function M.setFOVRainbowOutlineRGB(on)
		State.AimbotFOVRainbowOutlineRGB = (on == true)
		if Aimbot_FOV and Aimbot_FOV.RainbowOutlineRGB then Aimbot_FOV.RainbowOutlineRGB = State.AimbotFOVRainbowOutlineRGB end
		if Aimbot_FOV and Aimbot_FOV.RainbowOutlineColor ~= nil then Aimbot_FOV.RainbowOutlineColor = State.AimbotFOVRainbowOutlineRGB end
		requestRestart()
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
		pcall(function()
			local UIS = Services and Services.UIS
			local RunService = Services and Services.RunService
			if _aimAssistConn then _aimAssistConn:Disconnect() end
			_aimAssistConn = nil
			if RunService then
				pcall(function()
					RunService:UnbindFromRenderStep(_aimAssistBindName)
				end)
			end
			if _toggleInputConn then _toggleInputConn:Disconnect() end
			_toggleInputConn = nil
			if _triggerInputBeganConn then _triggerInputBeganConn:Disconnect() end
			_triggerInputBeganConn = nil
			if _triggerInputEndedConn then _triggerInputEndedConn:Disconnect() end
			_triggerInputEndedConn = nil
			if UIS and _forcedMouseLock then
				if _mouseBehaviorBeforeForce and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
					UIS.MouseBehavior = _mouseBehaviorBeforeForce
				end
			end
			_forcedMouseLock = false
			_mouseBehaviorBeforeForce = nil
			_toggleAimOn = false
		end)
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
