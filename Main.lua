if _G.__NOMNOM_HUB_LOADED then return end
_G.__NOMNOM_HUB_LOADED = true

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")

local _lastProgressPct = nil
local loadingGui, loadingDim, loadingCard, loadingFill, loadingPctLabel, loadingStatusLabel, loadingBarBg
local loadingClosedEvent = Instance.new("BindableEvent")
local loadingClosing = false

local _displayPct = 0
local _targetPct = 0
local _progressStatus = ""
local _progressConn = nil
local _doneRequested = false

local loadingDetailLabel, loadingSpinner
local uncPercent, uncResultStr, uncChecked, uncResultShown, uncResultLabel
local uncLiveResults = {}
local uncChecking = false
local _minTotalLoadingSeconds = 3.8
local _loadingStartedAt = os.clock()

local LOADING_STEPS = {
	{ pct = 1, name = "Boot" },
	{ pct = 5, name = "Environment check" },
	{ pct = 12, name = "Loading modules" },
	{ pct = 28, name = "Modules fetched" },
	{ pct = 40, name = "Modules initialized" },
	{ pct = 50, name = "Controller init" },
	{ pct = 62, name = "Fluent loaded" },
	{ pct = 75, name = "Building UI" },
	{ pct = 95, name = "UNC environment" },
	{ pct = 100, name = "Done" },
}

local function envCheckForThisScript()
	local results = {}
	local function add(name, ok)
		results[#results + 1] = { name = name, ok = not not ok }
	end

	add("game:HttpGet", typeof(game.HttpGet) == "function" or typeof(game.HttpGet) == "function")
	add("HttpService:GetAsync", HttpService and typeof(HttpService.GetAsync) == "function")
	local req = nil
	pcall(function()
		if syn and typeof(syn.request) == "function" then
			req = syn.request
		elseif typeof(request) == "function" then
			req = request
		elseif http_request and typeof(http_request) == "function" then
			req = http_request
		end
	end)
	add("request (optional)", typeof(req) == "function")

	add("readfile", typeof(readfile) == "function")
	add("writefile", typeof(writefile) == "function")
	add("isfile", typeof(isfile) == "function")
	add("isfolder", typeof(isfolder) == "function")
	add("makefolder", typeof(makefolder) == "function")
	add("delfile", typeof(delfile) == "function")

	local pass, total = 0, #results
	local missing = {}
	for _, r in ipairs(results) do
		if r.ok then
			pass += 1
		else
			missing[#missing + 1] = r.name
		end
	end

	return pass, total, missing
end

local function _tween(obj, tweenInfo, props)
	if not obj then return end
	local tw = TweenService:Create(obj, tweenInfo, props)
	tw:Play()
	return tw
end

-- Silent UNC environment check (no prints/warns). Returns passes, fails, undefined and a details table.
local function runUncCheck()
	local passes, fails, undefined = 0, 0, 0
	local running = 0
	local results = {}

	-- prepare live results and mark checking
	uncLiveResults = {}
	uncChecking = true

	local function getGlobal(path)
		local value = getfenv and getfenv(0) or _G
		while value ~= nil and path ~= "" do
			local name, nextValue = string.match(path, "^([^.]+)%.?(.*)$")
			if not name then break end
			value = value[name]
			path = nextValue
		end
		return value
	end

	local function test(name, aliases, callback)
		running += 1
		-- insert a placeholder line so many items show immediately
		local placeholderIndex = #uncLiveResults + 1
		pcall(function()
			table.insert(uncLiveResults, "[ ] " .. tostring(name) .. " - running")
			if loadingDetailLabel then setLoadingUi(math.floor(_displayPct + 0.5), _progressStatus) end
		end)
		task.spawn(function()
			local entry = { name = name, ok = nil, message = nil, aliases_missing = {} }
			if not callback then
				entry.ok = nil
			else
				if not getGlobal(name) then
					fails += 1
					entry.ok = false
					entry.message = "missing"
				else
					local ok, message = pcall(callback)
					if ok then
						passes += 1
						entry.ok = true
						entry.message = message
					else
						fails += 1
						entry.ok = false
						entry.message = tostring(message)
					end
				end
			end

			for _, alias in ipairs(aliases or {}) do
				if getGlobal(alias) == nil then
					table.insert(entry.aliases_missing, alias)
				end
			end
			if #entry.aliases_missing > 0 then
				undefined += 1
			end
			results[#results + 1] = entry
			-- push a human-friendly line into live results and refresh UI
			local statusSym = "[?]"
			if entry.ok == true then statusSym = "[x]" elseif entry.ok == false then statusSym = "[ ]" end
			local line = statusSym .. " " .. tostring(entry.name) .. (entry.message and (" - " .. tostring(entry.message)) or "")
			-- replace placeholder if present
			pcall(function()
				if placeholderIndex and uncLiveResults[placeholderIndex] then
					uncLiveResults[placeholderIndex] = line
				else
					table.insert(uncLiveResults, line)
				end
			end)
			pcall(function()
				if loadingDetailLabel then
					-- call setLoadingUi to rebuild the full details text
					setLoadingUi(math.floor(_displayPct + 0.5), _progressStatus)
				end
			end)
			running -= 1
		end)
	end

	-- Minimal set of tests (mirrors original but silent). Keep this reasonably small for loader speed.
	test("getgc", {}, function()
		local ok = pcall(function() local g = getgc() end)
		assert(ok, "getgc unavailable")
	end)
	test("getgenv", {}, function()
		local ok = pcall(function() getgenv().__TEST = true getgenv().__TEST = nil end)
		assert(ok, "getgenv failed")
	end)
	test("getrenv", {}, function()
		local ok = pcall(function() assert(_G ~= getrenv()._G) end)
		if not ok then return "identical_G" end
	end)
	test("loadstring", {}, function()
		if typeof(loadstring) ~= "function" then error("no loadstring") end
	end)
	test("crypt.generatekey", {}, function()
		if typeof(crypt) ~= "table" or typeof(crypt.generatekey) ~= "function" then error("no crypt") end
	end)

	-- Additional silent checks: common executor features and IO capabilities
	test("request/syn.request", {"request", "http_request", "syn.request"}, function()
		-- don't actually perform network calls; just check presence
		if typeof(request) ~= "function" and not (syn and typeof(syn.request) == "function") and typeof(http_request) ~= "function" then error("no request") end
	end)
	test("setclipboard", {"setclipboard"}, function()
		if typeof(setclipboard) ~= "function" then error("no setclipboard") end
	end)
	test("file IO", {"readfile", "writefile", "isfile", "isfolder", "delfile"}, function()
		-- ensure basic IO functions exist (don't call them)
		if typeof(readfile) ~= "function" and typeof(writefile) ~= "function" and typeof(isfile) ~= "function" then error("no basic io") end
	end)
	test("identifyexecutor", {"identifyexecutor", "getexecutor"}, function()
		if typeof(identifyexecutor) ~= "function" and typeof(getexecutor) ~= "function" then error("no identifyexecutor") end
	end)
	test("protect gui", {"syn.protect_gui"}, function()
		if not (syn and typeof(syn.protect_gui) == "function") then error("no protect_gui") end
	end)
	-- Extra presence checks to surface more detailed info
	test("hookfunction", {"hookfunction"}, function()
		if typeof(hookfunction) ~= "function" then error("no hookfunction") end
	end)
	test("hookmetamethod", {"hookmetamethod"}, function()
		if typeof(hookmetamethod) ~= "function" then error("no hookmetamethod") end
	end)
	test("getloadedmodules", {"getloadedmodules"}, function()
		if typeof(getloadedmodules) ~= "function" then error("no getloadedmodules") end
	end)
	test("queue_on_teleport", {"queue_on_teleport", "syn.queue_on_teleport"}, function()
		if typeof(queue_on_teleport) ~= "function" and not (syn and typeof(syn.queue_on_teleport) == "function") then error("no queue_on_teleport") end
	end)
	test("is_sirhurt_closure", {"is_sirhurt_closure"}, function()
		if typeof(is_sirhurt_closure) ~= "function" then error("no is_sirhurt_closure") end
	end)

	-- Wait for tests to finish (with timeout)
	local t0 = os.clock()
	while running > 0 and os.clock() - t0 < 6 do task.wait(0.05) end

	-- mark checking finished
	uncChecking = false

	return passes, fails, undefined, results
end

local function setLoadingUi(pct, text)
	pcall(function()
		if not loadingGui then
			local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
			if not pg then return end
			loadingGui = Instance.new("ScreenGui")
			loadingGui.Name = "NomNom_Loading"
			loadingGui.IgnoreGuiInset = true
			loadingGui.ResetOnSpawn = false
			loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			loadingGui.Parent = pg

			loadingDim = Instance.new("Frame")
			loadingDim.Name = "Dim"
			loadingDim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			loadingDim.BackgroundTransparency = 1
			loadingDim.BorderSizePixel = 0
			loadingDim.Size = UDim2.fromScale(1, 1)
			loadingDim.Parent = loadingGui

			loadingCard = Instance.new("Frame")
			loadingCard.Name = "Card"
			loadingCard.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			loadingCard.BackgroundTransparency = 1
			loadingCard.BorderSizePixel = 0
			loadingCard.Size = UDim2.fromOffset(420, 200)
			loadingCard.AnchorPoint = Vector2.new(0.5, 0.5)
			loadingCard.Position = UDim2.fromScale(0.5, 0.52)
			loadingCard.Parent = loadingDim

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 12)
			corner.Parent = loadingCard

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(60, 60, 60)
			stroke.Thickness = 1
			stroke.Transparency = 1
			stroke.Parent = loadingCard

			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.BackgroundTransparency = 1
			title.Text = "NomNom Universal"
			title.Font = Enum.Font.GothamBold
			title.TextSize = 20
			title.TextColor3 = Color3.fromRGB(235, 235, 235)
			title.TextTransparency = 1
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Size = UDim2.new(1, -40, 0, 28)
			title.Position = UDim2.fromOffset(20, 16)
			title.Parent = loadingCard

			loadingPctLabel = Instance.new("TextLabel")
			loadingPctLabel.Name = "Pct"
			loadingPctLabel.BackgroundTransparency = 1
			loadingPctLabel.Text = "0%"
			loadingPctLabel.Font = Enum.Font.GothamSemibold
			loadingPctLabel.TextSize = 18
			loadingPctLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
			loadingPctLabel.TextTransparency = 1
			loadingPctLabel.TextXAlignment = Enum.TextXAlignment.Right
			loadingPctLabel.Size = UDim2.new(1, -40, 0, 28)
			loadingPctLabel.Position = UDim2.fromOffset(20, 16)
			loadingPctLabel.Parent = loadingCard

			loadingStatusLabel = Instance.new("TextLabel")
			loadingStatusLabel.Name = "Status"
			loadingStatusLabel.BackgroundTransparency = 1
			loadingStatusLabel.Text = "Boot"
			loadingStatusLabel.Font = Enum.Font.Gotham
			loadingStatusLabel.TextSize = 14
			loadingStatusLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
			loadingStatusLabel.TextTransparency = 1
			loadingStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
			loadingStatusLabel.Size = UDim2.new(1, -40, 0, 20)
			loadingStatusLabel.Position = UDim2.fromOffset(20, 46)
			loadingStatusLabel.Parent = loadingCard

			loadingSpinner = Instance.new("TextLabel")
			loadingSpinner.Name = "Spinner"
			loadingSpinner.BackgroundTransparency = 1
			loadingSpinner.Text = "|"
			loadingSpinner.Font = Enum.Font.Gotham
			loadingSpinner.TextSize = 14
			loadingSpinner.TextColor3 = Color3.fromRGB(190, 190, 190)
			loadingSpinner.TextTransparency = 1
			loadingSpinner.TextXAlignment = Enum.TextXAlignment.Left
			loadingSpinner.Size = UDim2.fromOffset(10, 20)
			loadingSpinner.Position = UDim2.fromOffset(10, 46)
			loadingSpinner.Parent = loadingCard

			loadingDetailLabel = Instance.new("TextLabel")
			loadingDetailLabel.Name = "Details"
			loadingDetailLabel.BackgroundTransparency = 1
			loadingDetailLabel.Text = ""
			loadingDetailLabel.Font = Enum.Font.Gotham
			loadingDetailLabel.TextSize = 12
			loadingDetailLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			loadingDetailLabel.TextTransparency = 1
			loadingDetailLabel.TextXAlignment = Enum.TextXAlignment.Left
			loadingDetailLabel.TextYAlignment = Enum.TextYAlignment.Top
			loadingDetailLabel.RichText = false
			loadingDetailLabel.TextWrapped = true
			loadingDetailLabel.Size = UDim2.new(1, -40, 0, 60)
			loadingDetailLabel.Position = UDim2.fromOffset(20, 104)
			loadingDetailLabel.Parent = loadingCard
			loadingCard.ClipsDescendants = true

			loadingBarBg = Instance.new("Frame")
			loadingBarBg.Name = "BarBg"
			loadingBarBg.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
			loadingBarBg.BackgroundTransparency = 1
			loadingBarBg.BorderSizePixel = 0
			loadingBarBg.Size = UDim2.new(1, -40, 0, 14)
			loadingBarBg.Position = UDim2.fromOffset(20, 80)
			loadingBarBg.Parent = loadingCard
			local barCorner = Instance.new("UICorner")
			barCorner.CornerRadius = UDim.new(0, 8)
			barCorner.Parent = loadingBarBg

			loadingFill = Instance.new("Frame")
			loadingFill.Name = "BarFill"
			loadingFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			loadingFill.BackgroundTransparency = 1
			loadingFill.BorderSizePixel = 0
			loadingFill.Size = UDim2.fromScale(0, 1)
			loadingFill.Parent = loadingBarBg
			local fillCorner = Instance.new("UICorner")
			fillCorner.CornerRadius = UDim.new(0, 8)
			fillCorner.Parent = loadingFill

			local tiIn = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			_tween(loadingDim, tiIn, { BackgroundTransparency = 0.35 })
			_tween(loadingCard, tiIn, { BackgroundTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) })
			_tween(stroke, tiIn, { Transparency = 0.2 })
			_tween(title, tiIn, { TextTransparency = 0 })
			_tween(loadingPctLabel, tiIn, { TextTransparency = 0 })
			_tween(loadingStatusLabel, tiIn, { TextTransparency = 0 })
			_tween(loadingSpinner, tiIn, { TextTransparency = 0 })
			_tween(loadingBarBg, tiIn, { BackgroundTransparency = 0 })
			_tween(loadingFill, tiIn, { BackgroundTransparency = 0 })
			_tween(loadingDetailLabel, tiIn, { TextTransparency = 0 })
		end

		local p = math.clamp(tonumber(pct) or 0, 0, 100)
		if loadingPctLabel then
			loadingPctLabel.Text = tostring(p) .. "%"
		end
		if loadingStatusLabel then
			loadingStatusLabel.Text = tostring(text or "")
		end
		if loadingSpinner then
			local frames = { "|", "/", "-", "\\" }
			local idx = (math.floor(os.clock() * 10) % #frames) + 1
			loadingSpinner.Text = frames[idx]
		end
		-- Build details: core steps + live UNC checks (if running)
		if loadingDetailLabel then
			local function refreshDetails()
				local lines = {}
				for _, s in ipairs(LOADING_STEPS) do
					local mark = (p >= s.pct) and "[x]" or "[ ]"
					local cur = (text ~= nil and tostring(text) ~= "" and tostring(text) == s.name) and " >" or ""
					table.insert(lines, mark .. " " .. s.name .. cur)
				end
				if uncChecking or (uncLiveResults and #uncLiveResults > 0) then
					table.insert(lines, "")
					table.insert(lines, "UNC Checks:")
					for _, l in ipairs(uncLiveResults) do
						table.insert(lines, l)
					end
				end
				loadingDetailLabel.Text = table.concat(lines, "\n")
			end
			pcall(refreshDetails)
		end
		if loadingFill then
			loadingFill:TweenSize(UDim2.fromScale(p / 100, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.22, true)
		end
		if _doneRequested and p >= 100 and loadingGui and not loadingClosing then
			loadingClosing = true
			local g = loadingGui
			local dim = loadingDim
			local card = loadingCard
			local tiOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

			local function performFadeAndDestroy()
				pcall(function()
					_tween(dim, tiOut, { BackgroundTransparency = 1 })
					_tween(card, tiOut, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.52) })
					for _, d in ipairs(card:GetDescendants()) do
						if d:IsA("TextLabel") then
							pcall(function() _tween(d, tiOut, { TextTransparency = 1 }) end)
						elseif d:IsA("UIStroke") then
							pcall(function() _tween(d, tiOut, { Transparency = 1 }) end)
						elseif d:IsA("Frame") then
							if d.Name == "BarBg" or d.Name == "BarFill" then
								pcall(function() _tween(d, tiOut, { BackgroundTransparency = 1 }) end)
							end
						end
					end
				end)
					task.delay(0.38, function()
						pcall(function() g:Destroy() end)
						loadingGui, loadingDim, loadingCard, loadingFill, loadingPctLabel, loadingStatusLabel, loadingBarBg, loadingDetailLabel, loadingSpinner, uncResultLabel = nil
						loadingClosing = false
						pcall(function() loadingClosedEvent:Fire() end)
					end)
			end

			if uncChecked and not uncResultShown then
				uncResultShown = true
				pcall(function()
					local slideTime = 0.28
					-- slide the checklist out (upwards) and fade it
					if loadingDetailLabel and card then
						pcall(function()
							_tween(loadingDetailLabel, TweenInfo.new(slideTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, Position = UDim2.fromOffset(20, -80) })
						end)
					end
					task.wait(slideTime + 0.04)
					-- clear the checklist/table so overlay has clean space
					pcall(function()
						if loadingDetailLabel then loadingDetailLabel.Text = "" end
					end)
					-- create a shadowed result label (shadow behind + main label)
					local shadowLabel
					if card then
						pcall(function()
							shadowLabel = Instance.new("TextLabel")
							shadowLabel.Name = "UNCResultShadow"
							shadowLabel.BackgroundTransparency = 1
							shadowLabel.Font = Enum.Font.GothamSemibold
							shadowLabel.TextSize = 22
							shadowLabel.Size = UDim2.new(1, -40, 0, 48)
							shadowLabel.Position = UDim2.fromOffset(22, 106)
							shadowLabel.TextXAlignment = Enum.TextXAlignment.Center
							shadowLabel.TextYAlignment = Enum.TextYAlignment.Center
							shadowLabel.TextTransparency = 1
							shadowLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
							shadowLabel.Parent = card
						end)
						pcall(function()
							if not uncResultLabel then
								uncResultLabel = Instance.new("TextLabel")
								uncResultLabel.Name = "UNCResult"
								uncResultLabel.BackgroundTransparency = 1
								uncResultLabel.Font = Enum.Font.GothamSemibold
								uncResultLabel.TextSize = 22
								uncResultLabel.Size = UDim2.new(1, -40, 0, 48)
								uncResultLabel.Position = UDim2.fromOffset(20, 104)
								uncResultLabel.TextXAlignment = Enum.TextXAlignment.Center
								uncResultLabel.TextYAlignment = Enum.TextYAlignment.Center
								uncResultLabel.TextTransparency = 1
								uncResultLabel.Parent = card
							end
						end)
					end
					-- populate and style
					if uncResultLabel then
						uncResultLabel.Text = tostring(uncResultStr or "UNC")
						if uncPercent then
							if uncPercent > 75 then
								uncResultLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
							elseif uncPercent > 25 then
								uncResultLabel.TextColor3 = Color3.fromRGB(240, 200, 60)
							else
								uncResultLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
							end
						else
							uncResultLabel.TextColor3 = Color3.fromRGB(120, 160, 255)
						end
						if shadowLabel then shadowLabel.Text = uncResultLabel.Text end
						_tween(uncResultLabel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
						if shadowLabel then _tween(shadowLabel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.35 }) end
					end
				end)
				-- hold for a bit longer (show result) then fade out
				task.delay(3.5, function()
					performFadeAndDestroy()
				end)
			else
				performFadeAndDestroy()
			end

		end
	end)
end

local function logProgress(pct, text)
	local p = math.clamp(tonumber(pct) or 0, 0, 100)
	if _lastProgressPct == p then return end
	_lastProgressPct = p
	if _lastProgressPct == 1 and _displayPct <= 0 then
		_loadingStartedAt = os.clock()
	end
	_targetPct = p
	_progressStatus = tostring(text or "")
	if p >= 100 then
		_doneRequested = true
	end

	-- Ensure UI exists immediately and status updates right away
	setLoadingUi(math.floor(_displayPct + 0.5), _progressStatus)

	if not _progressConn then
		_progressConn = RunService.RenderStepped:Connect(function(dt)
			if loadingClosing then return end
			local cur = _displayPct
			local tgt = _targetPct
			local elapsed = math.max(0, os.clock() - _loadingStartedAt)
			local minCap = math.clamp((elapsed / _minTotalLoadingSeconds) * 100, 0, 100)
			local allowed = math.min(tgt, minCap)
			if cur < allowed then
				local rate = 22 -- percent per second (slow / fake-heavy)
				local step = rate * math.clamp(dt, 0, 0.05)
				local extra = math.clamp((allowed - cur) * 0.08, 0, 2.4)
				cur = math.min(allowed, cur + step + extra)
				_displayPct = cur
			end
			setLoadingUi(math.floor(_displayPct + 0.5), _progressStatus)
			if _doneRequested and _displayPct >= 100 then
				if _progressConn then
					_progressConn:Disconnect()
					_progressConn = nil
				end
				setLoadingUi(100, _progressStatus)
			end
		end)
	end
end

logProgress(1, "Boot")

do
	local pass, total, missing = envCheckForThisScript()
	local status = "Environment check (" .. tostring(pass) .. "/" .. tostring(total) .. ")"
	logProgress(5, "Environment check")
	if #missing > 0 then
		-- show short missing list in the details panel without printing to console
		local maxShow = 4
		local shown = {}
		for i = 1, math.min(#missing, maxShow) do
			shown[#shown + 1] = missing[i]
		end
		local suffix = (#missing > maxShow) and (" +" .. tostring(#missing - maxShow)) or ""
		setLoadingUi(math.floor(_displayPct + 0.5), status .. " - Missing: " .. table.concat(shown, ", ") .. suffix)
	else
		setLoadingUi(math.floor(_displayPct + 0.5), status)
	end
end

local function httpGet(url)
	local ok, body = pcall(function()
		if typeof(game.HttpGet) == "function" then
			return game:HttpGet(url)
		end
		error("no game:HttpGet")
	end)
	if ok and typeof(body) == "string" then return body end

	ok, body = pcall(function()
		if HttpService and typeof(HttpService.GetAsync) == "function" then
			return HttpService:GetAsync(url)
		end
		error("no HttpService:GetAsync")
	end)
	if ok and typeof(body) == "string" then return body end

	local req
	pcall(function()
		if syn and typeof(syn.request) == "function" then
			req = syn.request
		elseif typeof(request) == "function" then
			req = request
		elseif http_request and typeof(http_request) == "function" then
			req = http_request
		end
	end)
	if typeof(req) == "function" then
		local resp = req({ Url = url, Method = "GET" })
		if typeof(resp) == "table" and typeof(resp.Body) == "string" then return resp.Body end
		if typeof(resp) == "table" and typeof(resp.body) == "string" then return resp.body end
	end

	error("HTTP GET failed")
end

local function compileLua(src, chunkName)
	if typeof(src) ~= "string" then error("compileLua: source is not string") end
	chunkName = chunkName or "=chunk"
	if typeof(loadstring) == "function" then
		local fn, err = loadstring(src)
		if typeof(fn) == "function" then return fn end
		error("loadstring failed: " .. tostring(err or "unknown"))
	end
	if typeof(load) == "function" then
		local fn, err = load(src, chunkName)
		if typeof(fn) == "function" then return fn end
		error("load failed: " .. tostring(err or "unknown"))
	end
	error("Missing loadstring/load")
end

local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = Player:WaitForChild("PlayerGui")
local PLACE_ID = game.PlaceId
local JOB_ID = game.JobId

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
	FreecamSpeed = 60,

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

	EspOutlineColor = Color3.fromRGB(255, 255, 255),
	EspOutlineColorHex = "FFFFFF",

	CONFIG_FILE = "NomNom Universal For - " .. tostring(Player and Player.Name or "Player") .. ".json",
	UiReady = false,
	SuppressAllNotifications = true,
	SuppressToggleNotifications = true,
	JoinedAt = os.clock(),
}

local _PRISTINE_STATE = nil
pcall(function()
	local n = {}
	for k, v in pairs(State) do
		if typeof(v) == "table" then
			local sub = {}
			for kk, vv in pairs(v) do sub[kk] = vv end
			n[k] = sub
		else
			n[k] = v
		end
	end
	_PRISTINE_STATE = n
end)

pcall(function()
	local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		State.BaseWalkSpeed = hum.WalkSpeed
		State.BaseJumpPower = hum.JumpPower
		State.DesiredWalkSpeed = hum.WalkSpeed
		State.DesiredJumpPower = hum.JumpPower
	end
end)

local function _color3ToHex(c)
	if typeof(c) ~= "Color3" then return nil end
	local r = math.clamp(math.floor(c.R * 255 + 0.5), 0, 255)
	local g = math.clamp(math.floor(c.G * 255 + 0.5), 0, 255)
	local b = math.clamp(math.floor(c.B * 255 + 0.5), 0, 255)
	return string.format("%02X%02X%02X", r, g, b)
end

local function _hexToColor3(hex)
	if typeof(hex) ~= "string" then return nil end
	hex = hex:gsub("#", "")
	if #hex ~= 6 then return nil end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if not r or not g or not b then return nil end
	return Color3.fromRGB(r, g, b)
end

pcall(function()
	if readfile and isfile and isfile(State.CONFIG_FILE) then
		local raw = readfile(State.CONFIG_FILE)
		local ok, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
		if ok and typeof(cfg) == "table" and typeof(cfg.EspOutlineColorHex) == "string" then
			State.EspOutlineColorHex = cfg.EspOutlineColorHex
			local c = _hexToColor3(State.EspOutlineColorHex)
			if c then State.EspOutlineColor = c end
		end
	end
end)

local _DEFAULT_STATE = nil
local function _shallowClone(t)
	local n = {}
	for k, v in pairs(t) do
		if typeof(v) == "table" then
			local sub = {}
			for kk, vv in pairs(v) do sub[kk] = vv end
			n[k] = sub
		else
			n[k] = v
		end
	end
	return n
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
	httpGet = httpGet,
}

local moduleUrls = {
	["Misc.lua"] = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/Features/Misc.lua",
	["Movement.lua"] = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/Features/Movement.lua",
	["Visual.lua"] = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/Features/Visual.lua",
	["Controller.lua"] = "https://raw.githubusercontent.com/NomNomNemNie/NomNom-Scripts/refs/heads/Features/Controller.lua",
	["Combat.lua"] = "",
}

local function loadRemoteModule(path)
	local url = moduleUrls[path]
	if typeof(url) ~= "string" or url == "" then return nil end
	local src = httpGet(url)
	local factory = compileLua(src, url)()
	return factory
end

logProgress(12, "Loading modules")

local miscFactory = loadRemoteModule("Misc.lua")
local movementFactory = loadRemoteModule("Movement.lua")
local visualFactory = loadRemoteModule("Visual.lua")
local controllerFactory = loadRemoteModule("Controller.lua")
local combatFactory = loadRemoteModule("Combat.lua")

logProgress(28, "Modules fetched")

if not miscFactory or not movementFactory or not visualFactory or not controllerFactory then
	error("Failed to load required modules (Misc/Movement/Visual/Controller)")
end

local misc = miscFactory(ctx)
local movement = movementFactory(ctx, misc)
local visual = visualFactory(ctx, misc)
local combat = combatFactory and combatFactory(ctx, misc) or nil
local controller = controllerFactory(ctx, { misc = misc, movement = movement, visual = visual, combat = combat })

logProgress(40, "Modules initialized")

pcall(function() if misc and misc.init then misc.init() end end)
pcall(function() if controller and controller.init then controller.init() end end)

pcall(function()
	if typeof(State.EspOutlineColorHex) == "string" then
		local c = _hexToColor3(State.EspOutlineColorHex)
		if c then State.EspOutlineColor = c end
	end
	if typeof(State.EspOutlineColor) == "Color3" then
		State.EspOutlineColorHex = _color3ToHex(State.EspOutlineColor) or State.EspOutlineColorHex
	end
end)

if not _DEFAULT_STATE then
	_DEFAULT_STATE = _shallowClone(State)
end

logProgress(50, "Controller init")

local Fluent = compileLua(httpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"), "Fluent")()
local SaveManager = compileLua(httpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"), "Fluent_SaveManager")()
local InterfaceManager = compileLua(httpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"), "Fluent_InterfaceManager")()

logProgress(62, "Fluent loaded")

local Window
local Options

local _suppressUiNotify = true

local function uiNotify(title, content, duration)
	if _suppressUiNotify then return end
	pcall(function()
		Fluent:Notify({
			Title = tostring(title or "NomNom"),
			Content = tostring(content or ""),
			Duration = tonumber(duration) or 4,
		})
	end)
end

local function uiNotifyToggle(name, enabled)
	if _suppressUiNotify then return end
	uiNotify(tostring(name), (enabled and "Enabled") or "Disabled", 3)
end

local function uiNotifyAction(name, text)
	if _suppressUiNotify then return end
	uiNotify(tostring(name), tostring(text or "Running"), 3)
end

pcall(function()
	if misc and typeof(misc.showRobloxNotification) == "function" then
		misc.showRobloxNotification = function(title, text)
			uiNotify(title, text, 3)
		end
	end
end)

-- Patch config save/load to include ESP color hex (the upstream config does not save colors)
pcall(function()
	if misc and typeof(misc.saveUserConfig) == "function" then
		local oldSave = misc.saveUserConfig
		misc.saveUserConfig = function(...)
			pcall(oldSave, ...)
			pcall(function()
				if not writefile then return end
				local cfg = {}
				if readfile and isfile and isfile(State.CONFIG_FILE) then
					local raw = readfile(State.CONFIG_FILE)
					local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
					if ok and typeof(decoded) == "table" then cfg = decoded end
				end
				cfg.EspOutlineColorHex = State.EspOutlineColorHex or (State.EspOutlineColor and _color3ToHex(State.EspOutlineColor))
				writefile(State.CONFIG_FILE, HttpService:JSONEncode(cfg))
			end)
		end
	end
	if misc and typeof(misc.loadUserConfig) == "function" then
		local oldLoad = misc.loadUserConfig
		misc.loadUserConfig = function(...)
			pcall(oldLoad, ...)
			pcall(function()
				if readfile and isfile and isfile(State.CONFIG_FILE) then
					local raw = readfile(State.CONFIG_FILE)
					local ok, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
					if ok and typeof(cfg) == "table" and typeof(cfg.EspOutlineColorHex) == "string" then
						State.EspOutlineColorHex = cfg.EspOutlineColorHex
						local c = _hexToColor3(State.EspOutlineColorHex)
						if c then State.EspOutlineColor = c end
					end
				end
			end)
		end
	end
end)

local function applyEspColorToExisting()
	local c = State.EspOutlineColor
	if typeof(c) ~= "Color3" then return end
	pcall(function()
		for _, d in ipairs(workspace:GetDescendants()) do
			if d and d:IsA("Highlight") and d.Name == "NomNom_ESP" then
				d.OutlineColor = c
				d.OutlineTransparency = 0
				d.FillTransparency = 1
				pcall(function() d.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
			end
		end
	end)
end

local espEnsureConn = nil
local function startEspEnsureLoop()
	if espEnsureConn then return end
	espEnsureConn = RunService.Heartbeat:Connect(function()
		if not State.PlayerEspEnabled then return end
		local col = State.EspOutlineColor or Color3.fromRGB(255, 255, 255)
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= Player then
				local char = plr.Character
				if char then
					local hl = char:FindFirstChild("NomNom_ESP")
					if not hl then
						pcall(function()
							hl = Instance.new("Highlight")
							hl.Name = "NomNom_ESP"
							hl.FillTransparency = 1
							hl.OutlineTransparency = 0
							hl.OutlineColor = col
							pcall(function() hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
							hl.Adornee = char
							hl.Parent = char
						end)
					else
						pcall(function()
							hl.FillTransparency = 1
							hl.OutlineTransparency = 0
							hl.OutlineColor = col
							pcall(function() hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
							hl.Adornee = char
						end)
					end
				end
			end
		end
	end)
end

local function stopEspEnsureLoop()
	if espEnsureConn then pcall(function() espEnsureConn:Disconnect() end) espEnsureConn = nil end
end

-- Override controller notification helpers to Fluent notifications
pcall(function()
	controller.notifyToggle = function(name, enabled)
		uiNotifyToggle(name, enabled)
	end
	controller.notifyAction = function(name, text)
		uiNotifyAction(name, text)
	end
	controller.notifyButton = function(name, text)
		uiNotifyAction(name, text)
	end
end)

-- Override ESP to enforce outline + allow color
pcall(function()
	local oldSetPlayerEsp = controller.setPlayerEsp
	controller.setPlayerEsp = function(v)
		local r = oldSetPlayerEsp and oldSetPlayerEsp(v)
		if State.PlayerEspEnabled then
			startEspEnsureLoop()
		else
			stopEspEnsureLoop()
		end
		task.defer(applyEspColorToExisting)
		return r
	end
end)

-- Freecam with adjustable speed (override controller.setFreecam)
do
	local freecamConn, freecamMouseConn, freecamRmbDownConn, freecamRmbUpConn
	local freecamRmbDown = false
	local freecamYaw, freecamPitch
	local freecamCf
	local freecamZoom = 0
	local freecamOldMouseBehavior, freecamOldMouseIconEnabled
	local function stopFreecam()
		if freecamConn then pcall(function() freecamConn:Disconnect() end) freecamConn = nil end
		if freecamMouseConn then pcall(function() freecamMouseConn:Disconnect() end) freecamMouseConn = nil end
		if freecamRmbDownConn then pcall(function() freecamRmbDownConn:Disconnect() end) freecamRmbDownConn = nil end
		if freecamRmbUpConn then pcall(function() freecamRmbUpConn:Disconnect() end) freecamRmbUpConn = nil end
		freecamRmbDown = false
		local cam = workspace.CurrentCamera
		if cam then
			pcall(function() cam.CameraType = Enum.CameraType.Custom end)
		end
		pcall(function()
			UIS.MouseBehavior = freecamOldMouseBehavior or Enum.MouseBehavior.Default
			UIS.MouseIconEnabled = (freecamOldMouseIconEnabled ~= nil) and freecamOldMouseIconEnabled or true
		end)
	end
	local function startFreecam()
		stopFreecam()
		local cam = workspace.CurrentCamera
		if not cam then return end
		freecamCf = cam.CFrame
		local _, y, _ = cam.CFrame:ToOrientation()
		freecamYaw = y
		freecamPitch = 0
		freecamZoom = 0
		freecamOldMouseBehavior = UIS.MouseBehavior
		freecamOldMouseIconEnabled = UIS.MouseIconEnabled
		pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
		pcall(function()
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			UIS.MouseIconEnabled = true
		end)
		freecamRmbDownConn = UIS.InputBegan:Connect(function(input)
			if not State.FreecamEnabled then return end
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				freecamRmbDown = true
				pcall(function()
					UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
					UIS.MouseIconEnabled = false
				end)
			end
		end)
		freecamRmbUpConn = UIS.InputEnded:Connect(function(input)
			if not State.FreecamEnabled then return end
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				freecamRmbDown = false
				pcall(function()
					UIS.MouseBehavior = freecamOldMouseBehavior or Enum.MouseBehavior.Default
					UIS.MouseIconEnabled = (freecamOldMouseIconEnabled ~= nil) and freecamOldMouseIconEnabled or true
				end)
			end
		end)
		freecamMouseConn = UIS.InputChanged:Connect(function(input)
			if not State.FreecamEnabled then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement and freecamRmbDown then
				freecamYaw -= input.Delta.X * 0.0025
				freecamPitch = math.clamp(freecamPitch - input.Delta.Y * 0.0025, -1.4, 1.4)
			end
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				freecamZoom = math.clamp(freecamZoom - input.Position.Z * 2, -80, 30)
			end
		end)
		freecamConn = RunService.RenderStepped:Connect(function(dt)
			if not State.FreecamEnabled then return end
			local speed = math.clamp(tonumber(State.FreecamSpeed) or 60, 1, 500)
			local move = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0, 0, -1) end
			if UIS:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0, 1) end
			if UIS:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1, 0, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.A) then move -= Vector3.new(1, 0, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.E) then move += Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.Q) then move -= Vector3.new(0, 1, 0) end
			local rot = CFrame.fromOrientation(freecamPitch, freecamYaw, 0)
			freecamCf = CFrame.new(freecamCf.Position) * rot
			freecamCf = freecamCf + (freecamCf:VectorToWorldSpace(move) * speed * dt)
			cam.CFrame = freecamCf * CFrame.new(0, 0, freecamZoom)
		end)
	end
	pcall(function()
		controller.setFreecam = function(on)
			State.FreecamEnabled = (on == true)
			if not State.FreecamEnabled then
				stopFreecam()
				return
			end
			startFreecam()
		end
	end)
end

local function createUiOnce()
	if Window then return end
	Window = Fluent:CreateWindow({
		Title = "NomNom",
		SubTitle = "Universal",
		TabWidth = 160,
		Size = UDim2.fromOffset(580, 460),
		Acrylic = true,
		Theme = "Dark",
		MinimizeKey = Enum.KeyCode.RightControl,
	})

	local function resolveTab(ret)
		if typeof(ret) == "table" then return ret end
		if typeof(ret) == "number" and typeof(Window) == "table" then
			local t
			pcall(function() t = Window.Tabs and Window.Tabs[ret] end)
			if typeof(t) == "table" then return t end
		end
		return nil
	end

	local function addTabCompat(title, icon)
		local ret
		pcall(function() ret = Window:AddTab({ Title = title, Icon = icon }) end)
		local tab = resolveTab(ret)
		if tab then return tab end

		pcall(function() ret = Window:AddTab({ Title = title }) end)
		tab = resolveTab(ret)
		if tab then return tab end

		pcall(function() ret = Window:AddTab(title, icon) end)
		tab = resolveTab(ret)
		if tab then return tab end

		pcall(function() ret = Window:AddTab(title) end)
		tab = resolveTab(ret)
		if tab then return tab end

		return nil
	end

	local Tabs = {
		Main = addTabCompat("Main", "home"),
		Movement = addTabCompat("Movement", "move"),
		Visuals = addTabCompat("Visuals", "eye"),
		Misc = addTabCompat("Misc", "box"),
		Config = addTabCompat("Config", "file"),
		Settings = addTabCompat("Settings", "settings"),
	}
	if not Tabs.Main or not Tabs.Movement or not Tabs.Visuals or not Tabs.Misc or not Tabs.Config or not Tabs.Settings then
		error("Fluent AddTab failed (multi-tab)")
	end

	local MainTab = Tabs.Main
	local MovementTab = Tabs.Movement
	local VisualsTab = Tabs.Visuals
	local MiscTab = Tabs.Misc
	local ConfigTab = Tabs.Config
	local SettingsTab = Tabs.Settings

	local function forceResetLoop()
		uiNotifyAction("Force Reset", "Starting")
		local maxTries = 10
		for i = 1, maxTries do
			local prevChar = Player.Character
			pcall(function()
				if controller.respawnCharacter then
					controller.respawnCharacter()
				else
					local hum = prevChar and prevChar:FindFirstChildOfClass("Humanoid")
					if hum then hum.Health = 0 end
				end
			end)
			local ok = false
			local t0 = os.clock()
			while os.clock() - t0 < 2.5 do
				if Player.Character and Player.Character ~= prevChar then
					ok = true
					break
				end
				task.wait(0.1)
			end
			if ok then
				uiNotifyAction("Force Reset", "Success")
				return
			end
			uiNotifyAction("Force Reset", "Retry " .. tostring(i) .. "/" .. tostring(maxTries))
			task.wait(0.2)
		end
		uiNotifyAction("Force Reset", "Failed")
	end

	Options = Fluent.Options
	pcall(function() controller.setFluentOptions(Options) end)

	local gotoDropdown
	local viewDropdown

	local function refreshDropdowns()
		local names = {}
		pcall(function() names = controller.buildPlayerNameList() end)
		pcall(function() if gotoDropdown then gotoDropdown:SetValues(names) end end)
		pcall(function() if viewDropdown then viewDropdown:SetValues(names) end end)
	end

	Players.PlayerAdded:Connect(function() task.defer(refreshDropdowns) end)
	Players.PlayerRemoving:Connect(function() task.defer(refreshDropdowns) end)

	MainTab:AddParagraph({ Title = "NomNom", Content = "Loaded" })

	local DesyncToggle = MainTab:AddToggle("NomNom_Desync", { Title = "Desync", Default = State.DesyncEnabled })
	DesyncToggle:OnChanged(function(v)
		pcall(function()
			if controller.getSuppressDesyncOptionCallback and controller.getSuppressDesyncOptionCallback() then return end
			local ok = controller.setDesyncEnabled(v)
			if ok == false then
				pcall(function()
					if controller.setSuppressDesyncOptionCallback then controller.setSuppressDesyncOptionCallback(true) end
					Options.NomNom_Desync:SetValue(State.DesyncEnabled)
					if controller.setSuppressDesyncOptionCallback then controller.setSuppressDesyncOptionCallback(false) end
				end)
			end
		end)
		pcall(function() controller.notifyToggle("Desync", State.DesyncEnabled) end)
	end)

	MainTab:AddDropdown("NomNom_DesyncMethod", {
		Title = "Desync Method",
		Values = { "Respawn", "Rejoin" },
		Default = State.DesyncMethod,
		Callback = function(v)
			if typeof(v) == "string" then State.DesyncMethod = v end
		end,
	})

	MainTab:AddKeybind("NomNom_DesyncKeybind", {
		Title = "Keybind (Desync)",
		Mode = "Toggle",
		Default = State.DesyncKey.Name,
		Callback = function(Value)
			if Value then
				pcall(function() controller.toggleDesync() end)
				pcall(function()
					if Options.NomNom_Desync then
						if controller.setSuppressDesyncOptionCallback then controller.setSuppressDesyncOptionCallback(true) end
						Options.NomNom_Desync:SetValue(State.DesyncEnabled)
						if controller.setSuppressDesyncOptionCallback then controller.setSuppressDesyncOptionCallback(false) end
					end
				end)
			end
		end,
		ChangedCallback = function(New)
			pcall(function()
				controller.setKeybindUnique("Desync", "NomNom_DesyncKeybind", New, function(k) State.DesyncKey = k end, function() return State.DesyncKey end)
			end)
		end,
	})

	MainTab:AddButton({ Title = "Rejoin", Callback = function() uiNotifyAction("Rejoin", "Rejoining"); pcall(function() controller.rejoin() end) end })
	MainTab:AddButton({ Title = "Server Hop", Callback = function() uiNotifyAction("Server Hop", "Hopping"); pcall(function() controller.serverHop() end) end })
	MainTab:AddButton({ Title = "Force Reset", Callback = function() task.spawn(forceResetLoop) end })

	MovementTab:AddToggle("NomNom_ApplyMovementStats", { Title = "Movability", Default = State.ApplyMovementStats }):OnChanged(function(v)
			pcall(function() controller.setMovementStats(v) end)
			uiNotifyToggle("Movability", State.ApplyMovementStats)
		end)

	MovementTab:AddSlider("NomNom_WalkSpeed", { Title = "Walk Speed", Min = 1, Max = 10000, Rounding = 1, Default = State.DesiredWalkSpeed, Callback = function(v)
			State.DesiredWalkSpeed = v
			State.ApplyWalkSpeed = true
			pcall(function() controller.setMovementStats(true) end)
		end })

	MovementTab:AddSlider("NomNom_JumpPower", { Title = "Jump Power", Min = 1, Max = 10000, Rounding = 1, Default = State.DesiredJumpPower, Callback = function(v)
			State.DesiredJumpPower = v
			State.ApplyJumpPower = true
			pcall(function() controller.setMovementStats(true) end)
		end })

	MovementTab:AddButton({ Title = "Reset Walk + Jump", Callback = function()
		pcall(function() controller.resetWalkJump() end)
		pcall(function() controller.setMovementStats(false) end)
		pcall(function()
			local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = State.BaseWalkSpeed
				hum.JumpPower = State.BaseJumpPower
			end
		end)
		uiNotifyAction("Movement", "Reset Walk + Jump")
	end })

	MovementTab:AddToggle("NomNom_Fly", { Title = "Fly", Default = State.FlyEnabled }):OnChanged(function(v)
			pcall(function() controller.setFly(v) end)
			uiNotifyToggle("Fly", State.FlyEnabled)
		end)

	MovementTab:AddKeybind("NomNom_FlyKey", {
			Title = "Keybind (Fly)",
			Mode = "Toggle",
			Default = State.FlyKey.Name,
			Callback = function(Value)
				pcall(function() controller.setFly(Value == true) end)
				pcall(function() controller.setFluentOptionValue("NomNom_Fly", State.FlyEnabled) end)
			end,
			ChangedCallback = function(New)
				pcall(function() controller.setKeybindUnique("Fly", "NomNom_FlyKey", New, function(k) State.FlyKey = k end, function() return State.FlyKey end) end)
			end
		})

	MovementTab:AddSlider("NomNom_FlySpeed", { Title = "Fly Speed", Min = 20, Max = 1000, Rounding = 0, Default = State.FlySpeed, Callback = function(v) State.FlySpeed = v end })

	MovementTab:AddToggle("NomNom_Noclip", { Title = "Noclip", Default = State.NoclipEnabled }):OnChanged(function(v)
			pcall(function() controller.setNoclip(v) end)
			uiNotifyToggle("Noclip", State.NoclipEnabled)
		end)

	MovementTab:AddKeybind("NomNom_NoclipKey", {
			Title = "Keybind (Noclip)",
			Mode = "Toggle",
			Default = State.NoclipKey.Name,
			Callback = function(Value)
				pcall(function() controller.setNoclip(Value == true) end)
				pcall(function() controller.setFluentOptionValue("NomNom_Noclip", State.NoclipEnabled) end)
			end,
			ChangedCallback = function(New)
				pcall(function() controller.setKeybindUnique("Noclip", "NomNom_NoclipKey", New, function(k) State.NoclipKey = k end, function() return State.NoclipKey end) end)
			end
		})

	MovementTab:AddToggle("NomNom_ClickTp", { Title = "Click TP", Default = State.ClickTpEnabled }):OnChanged(function(v)
			pcall(function() controller.setClickTp(v) end)
			uiNotifyToggle("Click TP", State.ClickTpEnabled)
		end)

	MovementTab:AddKeybind("NomNom_ClickTpKey", {
			Title = "Keybind (Click TP)",
			Mode = "Toggle",
			Default = State.ClickTpKey.Name,
			Callback = function(Value)
				pcall(function() controller.setClickTp(Value == true) end)
				pcall(function() controller.setFluentOptionValue("NomNom_ClickTp", State.ClickTpEnabled) end)
			end,
			ChangedCallback = function(New)
				pcall(function() controller.setKeybindUnique("Click TP", "NomNom_ClickTpKey", New, function(k) State.ClickTpKey = k end, function() return State.ClickTpKey end) end)
			end
		})

	MovementTab:AddDropdown("NomNom_ClickTpMethod", { Title = "Click TP Method", Values = { "Instant", "Smooth" }, Default = State.ClickTpMethod, Callback = function(v) if typeof(v) == "string" then State.ClickTpMethod = v end end })
	MovementTab:AddSlider("NomNom_ClickTpTweenTime", { Title = "Click TP Tween", Min = 0.05, Max = 10, Rounding = 2, Default = State.ClickTpTweenTime, Callback = function(v) State.ClickTpTweenTime = v end })

	gotoDropdown = MovementTab:AddDropdown("NomNom_GotoTarget", { Title = "Target Player", Values = controller.buildPlayerNameList(), Default = State.GotoTargetName, Callback = function(v) State.GotoTargetName = v end })
	MovementTab:AddDropdown("NomNom_GotoMethod", { Title = "Goto Method", Values = { "TP", "Tween" }, Default = State.GotoMethod, Callback = function(v) if typeof(v) == "string" then State.GotoMethod = v end end })
	MovementTab:AddSlider("NomNom_GotoTweenTime", { Title = "Goto Tween", Min = 0.05, Max = 10, Rounding = 2, Default = State.GotoTweenTime, Callback = function(v) State.GotoTweenTime = v end })

	MovementTab:AddToggle("NomNom_Goto", { Title = "Goto", Default = State.LoopGotoEnabled }):OnChanged(function(v)
			State.LoopGotoEnabled = (v == true)
			pcall(function() controller.setGoto(v) end)
			uiNotifyToggle("Goto", State.LoopGotoEnabled)
		end)

	MovementTab:AddKeybind("NomNom_LoopGotoKey", {
			Title = "Keybind (Goto)",
			Mode = "Toggle",
			Default = State.LoopGotoKey.Name,
			Callback = function(Value)
				pcall(function() controller.setGoto(Value == true) end)
				pcall(function() controller.setFluentOptionValue("NomNom_Goto", State.LoopGotoEnabled) end)
			end,
			ChangedCallback = function(New)
				pcall(function() controller.setKeybindUnique("Goto", "NomNom_LoopGotoKey", New, function(k) State.LoopGotoKey = k end, function() return State.LoopGotoKey end) end)
			end
		})

	MovementTab:AddToggle("NomNom_Orbit", { Title = "Orbit", Default = State.OrbitEnabled }):OnChanged(function(v)
			pcall(function() controller.setOrbit(v) end)
			uiNotifyToggle("Orbit", State.OrbitEnabled)
		end)

	MovementTab:AddKeybind("NomNom_OrbitKey", {
			Title = "Keybind (Orbit)",
			Mode = "Toggle",
			Default = State.OrbitKey.Name,
			Callback = function(Value)
				pcall(function() controller.setOrbit(Value == true) end)
				pcall(function() controller.setFluentOptionValue("NomNom_Orbit", State.OrbitEnabled) end)
			end,
			ChangedCallback = function(New)
				pcall(function() controller.setKeybindUnique("Orbit", "NomNom_OrbitKey", New, function(k) State.OrbitKey = k end, function() return State.OrbitKey end) end)
			end
		})

	MovementTab:AddSlider("NomNom_OrbitSpeed", { Title = "Orbit Speed", Min = 1, Max = 100, Rounding = 1, Default = State.OrbitSpeed, Callback = function(v) State.OrbitSpeed = v end })
	MovementTab:AddSlider("NomNom_OrbitDistance", { Title = "Orbit Distance", Min = 1, Max = 500, Rounding = 1, Default = State.OrbitDistance, Callback = function(v) State.OrbitDistance = v end })

	MovementTab:AddToggle("NomNom_Airwalk", { Title = "Airwalk", Default = State.AirwalkEnabled }):OnChanged(function(v)
			pcall(function() controller.setAirwalk(v) end)
			uiNotifyToggle("Airwalk", State.AirwalkEnabled)
		end)

	MovementTab:AddToggle("NomNom_Float", { Title = "Float", Default = State.FloatEnabled }):OnChanged(function(v)
			pcall(function() controller.setFloat(v) end)
			uiNotifyToggle("Float", State.FloatEnabled)
		end)

	VisualsTab:AddToggle("NomNom_View", { Title = "View", Default = State.ViewEnabled }):OnChanged(function(v)
			pcall(function() controller.setViewEnabled(v) end)
			uiNotifyToggle("View", State.ViewEnabled)
		end)

	viewDropdown = VisualsTab:AddDropdown("NomNom_ViewTarget", { Title = "View Player", Values = controller.buildPlayerNameList(), Default = State.ViewTargetName, Callback = function(v)
			State.ViewTargetName = v
			pcall(function() controller.setViewTarget(v) end)
		end })

	VisualsTab:AddToggle("NomNom_PlayerESP", { Title = "Player ESP", Default = State.PlayerEspEnabled }):OnChanged(function(v)
			pcall(function() controller.setPlayerEsp(v) end)
			uiNotifyToggle("Player ESP", State.PlayerEspEnabled)
		end)

	VisualsTab:AddColorpicker("NomNom_EspColor", {
		Title = "ESP Color",
		Default = State.EspOutlineColor or Color3.fromRGB(255, 255, 255),
		Callback = function(c)
			State.EspOutlineColor = c
			State.EspOutlineColorHex = _color3ToHex(c) or State.EspOutlineColorHex
			applyEspColorToExisting()
			pcall(function()
				if State.AutoSaveConfigEnabled then
					controller.saveUserConfig()
				end
			end)
		end,
	})

	VisualsTab:AddToggle("NomNom_Tracers", { Title = "Tracers", Default = State.TracersEnabled }):OnChanged(function(v)
			pcall(function() controller.setTracers(v) end)
			uiNotifyToggle("Tracers", State.TracersEnabled)
		end)

	VisualsTab:AddToggle("NomNom_Fullbright", { Title = "Fullbright", Default = State.FullbrightEnabled }):OnChanged(function(v)
			pcall(function() controller.setFullbright(v) end)
			uiNotifyToggle("Fullbright", State.FullbrightEnabled)
		end)

	VisualsTab:AddToggle("NomNom_Freecam", { Title = "Freecam", Default = State.FreecamEnabled }):OnChanged(function(v)
			pcall(function() controller.setFreecam(v) end)
			uiNotifyToggle("Freecam", State.FreecamEnabled)
		end)

	VisualsTab:AddSlider("NomNom_FreecamSpeed", { Title = "Freecam Speed", Min = 1, Max = 500, Rounding = 0, Default = State.FreecamSpeed, Callback = function(v) State.FreecamSpeed = v end })

	VisualsTab:AddKeybind("NomNom_FreecamKey", {
			Title = "Keybind (Freecam)",
			Mode = "Toggle",
			Default = State.FreecamKey.Name,
			Callback = function(Value)
				pcall(function() controller.setFreecam(Value == true) end)
				pcall(function() controller.setFluentOptionValue("NomNom_Freecam", State.FreecamEnabled) end)
			end,
			ChangedCallback = function(New)
				pcall(function() controller.setKeybindUnique("Freecam", "NomNom_FreecamKey", New, function(k) State.FreecamKey = k end, function() return State.FreecamKey end) end)
			end
		})

	VisualsTab:AddButton({ Title = "Fixcam", Callback = function()
		pcall(function() controller.setFixcam(true) end)
		uiNotifyAction("Fixcam", "Fixed cam")
	end })

	MiscTab:AddToggle("NomNom_AntiAFK", { Title = "Anti-AFK", Default = State.AntiAfkEnabled }):OnChanged(function(v)
			pcall(function() controller.setAntiAfk(v) end)
			uiNotifyToggle("Anti-AFK", State.AntiAfkEnabled)
		end)

	MiscTab:AddToggle("NomNom_StatsOverlay", { Title = "Stats", Default = State.StatsEnabled }):OnChanged(function(v)
		pcall(function() controller.setOverlayEnabled(v) end)
		uiNotifyToggle("Stats", State.StatsEnabled)
	end)

	ConfigTab:AddParagraph({ Title = "Config", Content = "Auto-save file: " .. tostring(State.CONFIG_FILE) })
	ConfigTab:AddToggle("NomNom_AutoSave", { Title = "Auto Save Config", Default = State.AutoSaveConfigEnabled }):OnChanged(function(v)
		State.AutoSaveConfigEnabled = (v == true)
		uiNotifyToggle("Auto Save", State.AutoSaveConfigEnabled)
		pcall(function() controller.saveUserConfig() end)
	end)
	ConfigTab:AddToggle("NomNom_AutoExec", { Title = "Auto Execute Script", Default = State.AutoExecEnabled }):OnChanged(function(v)
			State.AutoExecEnabled = (v == true)
			uiNotifyToggle("Auto Exec", State.AutoExecEnabled)
			pcall(function()
				if State.AutoSaveConfigEnabled then
					controller.saveUserConfig()
				end
			end)
		end)

	-- Keep reset button at the bottom and do NOT touch character respawn/desync state to avoid resets
	ConfigTab:AddButton({ Title = "Reset Config", Callback = function()
		_suppressUiNotify = true
		pcall(function()
			if delfile and isfile and isfile(State.CONFIG_FILE) then
				delfile(State.CONFIG_FILE)
			end
		end)
		pcall(function()
			local baseWS = State.BaseWalkSpeed
			local baseJP = State.BaseJumpPower
			local cfgFile = State.CONFIG_FILE
			if _PRISTINE_STATE then
				for k, v in pairs(_PRISTINE_STATE) do
					State[k] = (typeof(v) == "table") and _shallowClone(v) or v
				end
			end
			State.CONFIG_FILE = cfgFile
			State.BaseWalkSpeed = baseWS
			State.BaseJumpPower = baseJP
			State.DesiredWalkSpeed = baseWS
			State.DesiredJumpPower = baseJP
			State.AutoExecEnabled = false
			State.AutoSaveConfigEnabled = true
			State.EspOutlineColor = Color3.fromRGB(255, 255, 255)
			State.EspOutlineColorHex = "FFFFFF"
		end)

		pcall(function() controller.setFly(false) end)
		pcall(function() controller.setNoclip(false) end)
		pcall(function() controller.setClickTp(false) end)
		pcall(function() controller.setLoopGoto(false) end)
		pcall(function() controller.setOrbit(false) end)
		pcall(function() controller.setAirwalk(false) end)
		pcall(function() controller.setFloat(false) end)
		pcall(function() controller.setViewEnabled(false) end)
		pcall(function() controller.setPlayerEsp(false) end)
		pcall(function() controller.setTracers(false) end)
		pcall(function() controller.setFullbright(false) end)
		pcall(function() controller.setFreecam(false) end)
		pcall(function() controller.setAntiAfk(true) end)
		pcall(function() controller.setOverlayEnabled(true) end)
		pcall(function() controller.setMovementStats(false) end)

		pcall(function()
			if Options then
				if Options.NomNom_AutoExec then Options.NomNom_AutoExec:SetValue(State.AutoExecEnabled) end
				if Options.NomNom_AutoSave then Options.NomNom_AutoSave:SetValue(State.AutoSaveConfigEnabled) end
				if Options.NomNom_Fly then Options.NomNom_Fly:SetValue(State.FlyEnabled) end
				if Options.NomNom_Noclip then Options.NomNom_Noclip:SetValue(State.NoclipEnabled) end
				if Options.NomNom_ClickTP then Options.NomNom_ClickTP:SetValue(State.ClickTpEnabled) end
				if Options.NomNom_LoopGoto then Options.NomNom_LoopGoto:SetValue(State.LoopGotoEnabled) end
				if Options.NomNom_Orbit then Options.NomNom_Orbit:SetValue(State.OrbitEnabled) end
				if Options.NomNom_Airwalk then Options.NomNom_Airwalk:SetValue(State.AirwalkEnabled) end
				if Options.NomNom_Float then Options.NomNom_Float:SetValue(State.FloatEnabled) end
				if Options.NomNom_View then Options.NomNom_View:SetValue(State.ViewEnabled) end
				if Options.NomNom_PlayerESP then Options.NomNom_PlayerESP:SetValue(State.PlayerEspEnabled) end
				if Options.NomNom_Tracers then Options.NomNom_Tracers:SetValue(State.TracersEnabled) end
				if Options.NomNom_Fullbright then Options.NomNom_Fullbright:SetValue(State.FullbrightEnabled) end
				if Options.NomNom_Freecam then Options.NomNom_Freecam:SetValue(State.FreecamEnabled) end
				if Options.NomNom_AntiAFK then Options.NomNom_AntiAFK:SetValue(State.AntiAfkEnabled) end
				if Options.NomNom_StatsOverlay then Options.NomNom_StatsOverlay:SetValue(State.StatsEnabled) end
				if Options.NomNom_EspColor and typeof(Options.NomNom_EspColor.SetValue) == "function" then
					Options.NomNom_EspColor:SetValue(State.EspOutlineColor)
				end
			end
		end)

		pcall(function() controller.saveUserConfig() end)
		_suppressUiNotify = false
		uiNotifyAction("Config", "Reset config")
	end })

		SaveManager:SetLibrary(Fluent)
		InterfaceManager:SetLibrary(Fluent)
		SaveManager:IgnoreThemeSettings()
		SaveManager:SetIgnoreIndexes({})
		InterfaceManager:SetFolder("NomNomNemNie")
		SaveManager:SetFolder("NomNomNemNie/Configs")
		InterfaceManager:BuildInterfaceSection(SettingsTab)
		SaveManager:BuildConfigSection(SettingsTab)

	task.defer(refreshDropdowns)

	pcall(function()
		if typeof(Window) == "table" and typeof(Window.SelectTab) == "function" then
			Window:SelectTab(1)
		end
	end)
	_suppressUiNotify = false
end

-- Run UNC environment check quietly and surface summary in loading UI
pcall(function()
	-- report an intermediate step
	logProgress(75, "Building UI")
	local passes, fails, undef, details = runUncCheck()
	local total = (passes + fails)
	local pct = 95
	local summary = ""
	if total > 0 then
		summary = tostring(passes) .. " out of " .. tostring(total) .. " tests"
	else
		summary = "No tests run"
	end
	-- store UNC summary and percent for later overlay
	uncChecked = true
	if total > 0 then
		uncPercent = math.floor((passes / total) * 100 + 0.5)
	else
		uncPercent = nil
	end
	if total == 0 then
		uncResultStr = "Executor"
	else
		if uncPercent > 75 then
			uncResultStr = "Good (" .. tostring(uncPercent) .. "%)"
		elseif uncPercent > 25 then
			uncResultStr = "Mid (" .. tostring(uncPercent) .. "%)"
		else
			uncResultStr = "Bad (" .. tostring(uncPercent) .. "%)"
		end
	end
	logProgress(pct, "UNC environment")
	setLoadingUi(pct, "UNC: " .. summary)
end)


logProgress(100, "Done")
pcall(function()
	if loadingGui then
		-- wait for the loadingClosedEvent to fire (fired after fade+Destroy)
		loadingClosedEvent.Event:Wait()
		-- be extra-safe: wait until object is truly gone (small timeout)
		local t0 = os.clock()
		while loadingGui and os.clock() - t0 < 2 do task.wait(0.03) end
	end
end)

createUiOnce()

pcall(function()
	_suppressUiNotify = true
	controller.setAntiAfk(State.AntiAfkEnabled)
	controller.setOverlayEnabled(State.StatsEnabled)
	controller.setMovementStats(State.ApplyMovementStats)
	_suppressUiNotify = false
end)

pcall(function()
	if SaveManager.LoadAutoloadConfig then
		_suppressUiNotify = true
		SaveManager:LoadAutoloadConfig()
		_suppressUiNotify = false
	end
end)
