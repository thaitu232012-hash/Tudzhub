--[[
	Nuke Hub v3 | Merge a Nuke!
	Auto-merge farming | Animation-free launching | Base ESP + overhead timers | Auto base lock | HUD
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer

-- Fallback for running without live-reload: own STATE with the same interface.
-- Re-executing kills the previous run's loops (they poll the OLD state table).
if not STATE then
	if _G.NukeHubState then
		_G.NukeHubState.dead = true
		for _, c in ipairs(_G.NukeHubState.conns or {}) do pcall(function() c:Disconnect() end) end
	end
	local st = { conns = {}, cleanups = {}, dead = false }
	_G.NukeHubState = st
	STATE = {
		connect = function(sig, fn)
			local c = sig:Connect(fn)
			table.insert(st.conns, c)
			return c
		end,
		onCleanup = function(fn) table.insert(st.cleanups, fn) end,
		alive = function() return not st.dead end,
		namecallHook = function() end,
	}
end

local Net = require(game.ReplicatedStorage.Packages.Remotes)
local nc = require(game.ReplicatedStorage.Controllers.NukeController)
local dc = require(game.ReplicatedStorage.Controllers.DataController)
local FF = require(game.ReplicatedStorage.UserGenerated.FastFlags)
local CommanderData = require(game.ReplicatedStorage.Shared.CommanderData)
local cc = require(game.ReplicatedStorage.Controllers.CommanderController)
local UpgradeConfig = require(game.ReplicatedStorage.Shared.UpgradeConfig)

nc:WaitUntilReady()

local hrp = function()
	local c = lp.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local TR = {
	tab_farm = "Auto-Merge & Auto Base-Lock",
	tab_launch = "Auto-Farm",
	tab_info = "Info",
	tab_settings = "Settings",
	status_title = "Status",
	status_wait = "Waiting...",
	merge_done = "Merge #%d: T%d → T%d (held)",
	merge_no_pair = "T%d held without pair — dropping it, merging others.",
	merge_wait_pair = "Waiting for pair... (held T%d, %d nukes on base)",
	merge_wait_new = "Waiting for new pairs... (%d nukes on base)",
	merge_picked = "Picked up T%d, merging...",
	pickup_fail = "Pickup keeps failing. Waiting 5 sec...",
	err = "Error: %s",
	auto_merge = "Auto-Merge",
	auto_merge_desc = "Picks up and merges nukes in pairs automatically",
	started = "Running...",
	off = "Off",
	delay_slider = "Step delay (sec)",
	autolock_p = "Auto Base-Lock",
	autolock_toggle = "Auto base locking",
	autolock_desc = "Locks your base when protection expires",
	locked_more = "🔒 Locked for another %s",
	lock_request = "Sending lock request...",
	base_not_found = "Base not found",
	afarm_desc0 = "Pick nukes and targets.",
	afarm_started = "Auto-farm started",
	afarm_stopped = "Auto-farm stopped",
	no_nukes_sel = "No nukes selected",
	no_targets_sel = "No targets selected",
	launching = "Launching %s → %s",
	no_nukes_wait = "No available nukes, waiting...",
	dd_nukes = "Which nukes to launch",
	dd_nukes_none = "No free nukes",
	dd_multi = "Select several",
	dd_targets = "Where to launch",
	dd_targets_desc = "City + all commanders (pick yours)",
	city = "City (center)",
	pickup_fail2 = "Failed to pick up nuke",
	cooldown = "⏳ Cooldown: %s left",
	wait_merge_busy = "Waiting for Auto-Merge to put down the nuke...",
	wait_launch_busy = "Waiting for Auto-Launch to finish...",
	no_held = "No nuke in hands",
	rejected = "❌ Rejected by server",
	toggle_afarm = "Auto-Farm",
	toggle_afarm_desc = "Launches selected nukes at selected targets in turn",
	esp_info_title = "Bases & players",
	esp_info_desc = "Billboards over bases and heads: owner name, nukes, lock timer.",
	esp_on = "ESP enabled",
	esp_hide = "Hide original lock status",
	esp_hide_desc = "Shield-forcefield, base badge, timers and markers",
	esp_free = "Free",
	esp_open = "🔓 Open",
	esp_nukes = "Nukes: %d · Max T%d",
	profile = "Profile",
	info_cash = "💰 Cash:",
	info_rb = "🔄 Rebirths: %d · Max nuke: T%d",
	info_nukes = "🎒 Nukes: on base %d · held %s · flying %d",
	info_season = "🌍 Season: tier %s · XP %s",
	author = "Created by himk1n",
	loaded_t = "Nuke Hub v3 loaded",
	loaded_c = "K — toggle menu.",
}

local function L(key, ...)
	local v = TR[key]
	if v == nil then return key end
	if select("#", ...) > 0 then return string.format(v, ...) end
	return v
end

local S = {
	autoMerge = false,
	mergeDelay = 0.5,
	mergesDone = 0,
	espOn = false,
	hideOriginal = true,
	selNukes = {},
	selTargets = {},
	autoFarm = false,
	autoUpgrade = false,
	autoUpKeys = {},
}

_G.NukeHubS = S

local nukeMap = {}
local targetMap = {}
local espFolder = nil
local baseBills = {}
local nameCache = {}
local mergeToggleObj = nil

local FONT_MAIN = Enum.Font.GothamBlack

local function serverNow()
	return Workspace:GetServerTimeNow()
end

local function profile()
	local ok, d = pcall(function()
		return dc.Get("Data").Data
	end)
	if ok then return d end
	return {}
end

local BIG_SUF = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }
local function fmtBig(v)
	if type(v) == "number" then return string.format("%.2f", v) end
	local m, e = tostring(v):match("^([%-%.%d]+)|([%-%d]+)$")
	if not m then return tostring(v) end
	m, e = tonumber(m) or 0, tonumber(e) or 0
	if e < 0 then return string.format("%.4f", m * 10 ^ e) end
	local idx = math.floor(e / 3) + 1
	if idx < 1 or idx > #BIG_SUF then return string.format("%ge%d", m, e) end
	return string.format("%.2f%s", m * 10 ^ (e % 3), BIG_SUF[idx])
end

local baseFloorTop
local function floorTopY()
	if baseFloorTop then return baseFloorTop end
	local ok, y = pcall(function()
		for _, b in ipairs(Workspace.Bases:GetChildren()) do
			if b:GetAttribute("OwnerUserId") == lp.UserId then
				local f = b:FindFirstChild("Floor")
				if f and f:IsA("BasePart") then return f.Position.Y + f.Size.Y / 2 end
			end
		end
	end)
	if ok and type(y) == "number" then
		baseFloorTop = y
		return y
	end
	return nil
end

local function teleportTo(pos, offset)
	local h = hrp()
	if not h then return end
	if offset then
		h.CFrame = CFrame.new(pos + offset)
		return
	end
	local ang = math.random() * math.pi * 2
	local flat = Vector3.new(math.cos(ang), 0, math.sin(ang)) * 7
	local y = floorTopY()
	if y then
		h.CFrame = CFrame.new(pos.X + flat.X, y + 4, pos.Z + flat.Z)
	else
		h.CFrame = CFrame.new(pos + Vector3.new(math.random(-2, 2), 2, math.random(-2, 2)))
	end
end

local function dropHeld()
	local h = hrp()
	if h then Net.Drop:FireServer(h.CFrame) end
end

local function myPlaced()
	local out = {}
	for _, j in ipairs(nc:GetNukes(lp)) do
		if j.State == 1 and j.Instance and j.Instance.Parent and not j.Locked then
			table.insert(out, j)
		end
	end
	table.sort(out, function(a, b) return a.Tier < b.Tier end)
	return out
end

local function shortId(id)
	local s = tostring(id)
	return #s > 6 and s:sub(-6) or s
end

local function mmss(sec)
	sec = math.max(0, math.floor(sec))
	local h = math.floor(sec / 3600)
	if h > 0 then
		return string.format("%d:%02d:%02d", h, math.floor(sec / 60) % 60, sec % 60)
	end
	return string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
end

local nameCache = {}
local namePending = {}

local function ownerName(uid)
	if uid == nil then return "?" end
	if uid == lp.UserId then return lp.DisplayName end
	if nameCache[uid] then return nameCache[uid] end
	local pl = Players:GetPlayerByUserId(uid)
	if pl then
		nameCache[uid] = pl.DisplayName
		return pl.DisplayName
	end
	if namePending[uid] then
		return "id:" .. tostring(uid)
	end
	namePending[uid] = true
	task.spawn(function()
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, uid)
		if ok and name and type(name) == "string" and #name > 0 then
			nameCache[uid] = name
		else
			nameCache[uid] = "id:" .. tostring(uid)
		end
		namePending[uid] = nil
	end)
	return "id:" .. tostring(uid)
end

local function getBaseInfo(base)
	local locked = base:GetAttribute("BaseLocked")
	local lockEnds = base:GetAttribute("LockEndsAt") or 0
	local count, maxT = 0, 0
	local nf = base:FindFirstChild("Nukes")
	if nf then
		for _, n in ipairs(nf:GetChildren()) do
			count += 1
			maxT = math.max(maxT, tonumber(n:GetAttribute("Tier")) or 0)
		end
	end
	return {
		owner = base:GetAttribute("OwnerUserId"),
		locked = locked,
		left = math.max(0, lockEnds - serverNow()),
		count = count,
		maxTier = maxT,
	}
end

local baseInfoCache = {}
local baseInfoValid = false

local function getBaseInfoCached(base)
	if baseInfoValid and baseInfoCache[base] then
		return baseInfoCache[base]
	end
	baseInfoValid = false
	local info = getBaseInfo(base)
	baseInfoCache[base] = info
	return info
end

local baseInfoLastUpdate = 0

local function getBaseInfoCached(base)
	if os.clock() - baseInfoLastUpdate < 2 then
		if baseInfoCache[base] then
			return baseInfoCache[base]
		end
	end
	baseInfoLastUpdate = os.clock()
	table.clear(baseInfoCache)
	for _, b in ipairs(workspace.Bases:GetChildren()) do
		if b:IsA("Model") then
			baseInfoCache[b] = getBaseInfo(b)
		end
	end
	return baseInfoCache[base]
end

local claimablesCache = {}
local claimablesValid = false

local function getClaimables()
	if claimablesValid then return claimablesCache end
	claimablesValid = true
	local r = {}
	pcall(function()
		local ups = getupvalues(cc.SpawnNewClaimable)
		local tbl = ups and ups[1]
		if type(tbl) ~= "table" then return end
		for id, data in pairs(tbl) do
			if type(data) == "table" and data.Model and data.Model.Parent then
				local ct = data.CommanderType
				local cd = CommanderData[ct]
				local name = cd and cd.DisplayName or ct or "Commander"
				table.insert(r, { id = id, name = name, type = ct, model = data.Model, pos = data.Model:GetPivot().Position })
			end
		end
	end)
	table.sort(r, function(a, b) return a.name < b.name end)
	claimablesCache = r
	return r
end

local function getTargetPos(label)
	if label == L("city") then
		local cm = Workspace:FindFirstChild("CityModel") or Workspace:FindFirstChild("City")
		if cm and cm:IsA("Model") then
			local _, size = cm:GetBoundingBox()
			local pivot = cm:GetPivot().Position
			return Vector3.new(pivot.X, pivot.Y - size.Y / 2 + 5, pivot.Z)
		end
		return Vector3.new(0, 10, 0)
	end
	-- Commander: label = "DisplayName | ❤ HP | Rarity", find the spawned one of this type
	local displayName = label:match("^([^|]+)") 
	if displayName then
		displayName = displayName:gsub("%s+$", "")
		for _, c in ipairs(getClaimables()) do
			if c.name == displayName then return c.pos end
		end
	end
	return nil
end

-- Hide original lock UI: FF flag + forcefield parts.
-- Parts are written ONCE (ffTouched cache) — repeated property writes every tick caused FPS dips.
local ffTouched = {}

local function applyHide()
	for _, base in ipairs(Workspace.Bases:GetChildren()) do
		local ff = base:FindFirstChild("Forcefield")
		if ff then
			for _, p in ipairs(ff:GetDescendants()) do
				if p:IsA("BasePart") and not ffTouched[p] then
					ffTouched[p] = true
					p.LocalTransparencyModifier = 1
				end
			end
		end
	end
end

local function restoreForcefields()
	for p in pairs(ffTouched) do
		if p.Parent then p.LocalTransparencyModifier = 0 end
	end
	table.clear(ffTouched)
end

local function hideOriginals(on)
	pcall(function()
		FF.Get("BaseStatus.Enabled").Value = not on
	end)
	local markers = lp.PlayerGui:FindFirstChild("BaseTargetMarkers")
	if markers then markers.Enabled = not on end
	if on then
		applyHide()
	else
		restoreForcefields()
	end
end

local espFolder = nil
local baseBills = {}

local function ensureEspFolder()
	if espFolder and espFolder.Parent then return espFolder end
	local cam = Workspace.CurrentCamera
	local old = cam and cam:FindFirstChild("_NukeHubESP")
	if old then old:Destroy() end
	espFolder = Instance.new("Folder")
	espFolder.Name = "_NukeHubESP"
	espFolder.Parent = cam
	baseBills = {}
	return espFolder
end

local function makeEspBill(size, parent)
	local bb = Instance.new("BillboardGui")
	bb.Size = size
	bb.AlwaysOnTop = false
	bb.MaxDistance = 500

	local f = Instance.new("Frame")
	f.Name = "Frame"
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.fromRGB(15, 15, 23)
	f.BackgroundTransparency = 0.12
	f.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = f

	local tl = Instance.new("TextLabel")
	tl.Name = "TextLabel"
	tl.Size = UDim2.new(1, -16, 1, -10)
	tl.Position = UDim2.fromOffset(10, 5)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamMedium
	tl.TextSize = 12
	tl.RichText = true
	tl.TextWrapped = true
	tl.TextColor3 = Color3.fromRGB(235, 235, 245)
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.TextYAlignment = Enum.TextYAlignment.Center
	tl.Parent = f

	f.Parent = bb
	bb.Parent = parent
	return bb
end

local function ensureBaseBill(base)
	local bb = baseBills[base]
	if bb and bb.Parent then return bb end
	bb = makeEspBill(UDim2.fromOffset(170, 62), ensureEspFolder())
	bb.Adornee = base
	bb.StudsOffset = Vector3.new(0, 20, 0)
	baseBills[base] = bb
	return bb
end

local function updateBaseBills()
	for _, base in ipairs(Workspace.Bases:GetChildren()) do
		if not base:IsA("Model") then continue end
		local info = getBaseInfoCached(base)
		if info.owner == lp.UserId then
			if baseBills[base] then
				baseBills[base]:Destroy()
				baseBills[base] = nil
			end
			continue
		end
		local bb = ensureBaseBill(base)
		local title
		if info.owner == nil then
			title = string.format('<font color="#9a9aa8"><i>%s</i></font>', L("esp_free"))
		else
			title = string.format('<b><font color="%s">%s</font></b>', "#ffd75f", ownerName(info.owner))
		end
		local lockLine
		if info.locked then
			lockLine = string.format('<font color="#ff5050">🔒 %s</font>', mmss(info.left))
		else
			lockLine = string.format('<font color="#50ff88"><b>%s</b></font>', L("esp_open"))
		end
		bb.Frame.TextLabel.Text = table.concat({
			title,
			string.format('<font color="#b8b8c6">%s</font>', L("esp_nukes", info.count, info.maxTier)),
			lockLine,
		}, "\n")
	end
	for base, bb in pairs(baseBills) do
		if not base.Parent then bb:Destroy(); baseBills[base] = nil end
	end
end

local function clearEsp()
	for base in pairs(baseBills) do baseBills[base]:Destroy() end
	table.clear(baseBills)
	if espFolder then espFolder:Destroy() espFolder = nil end
end

task.spawn(function()
	while STATE.alive() do
		if S.espOn then
			pcall(updateBaseBills)
			task.wait(1)
		else
			task.wait(0.5)
		end
	end
end)

local hideApplied = false

local function applyHideOnEnable()
	if not S.hideOriginal then
		hideApplied = false
		return
	end
	if hideApplied then return end
	hideApplied = true
	pcall(function()
		FF.Get("BaseStatus.Enabled").Value = false
	end)
	pcall(applyHide)
end

task.spawn(function()
	while STATE.alive() do
		if S.hideOriginal then
			applyHideOnEnable()
			task.wait(0.5)
		else
			hideApplied = false
			task.wait(0.5)
		end
	end
end)

STATE.onCleanup(function()
	S.autoMerge = false
	S.autoFarm = false
	S.espOn = false
	clearEsp()
	pcall(hideOriginals, false)
end)

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
	Title = "Nuke Hub",
	Icon = "radiation",
	Author = "Merge a Nuke!",
	Folder = "NukeHub",
	Size = UDim2.fromOffset(560, 430),
	Transparent = true,
	Theme = "Dark",
	ToggleKey = Enum.KeyCode.K,
})

local TabFarm = Window:Tab({ Title = L("tab_farm"), Icon = "hammer" })
local TabLaunch = Window:Tab({ Title = L("tab_launch"), Icon = "rocket" })
local TabEsp = Window:Tab({ Title = "ESP", Icon = "eye" })
local TabSettings = Window:Tab({ Title = L("tab_settings"), Icon = "settings" })

Window:SelectTab(1)

local farmStatus = TabFarm:Paragraph({ Title = L("status_title"), Desc = L("status_wait") })
local function setFarm(txt)
	pcall(function() farmStatus:SetDesc(txt) end)
end

local mergeFails = 0

-- Hands arbiter: Auto-Merge and Auto-Launch share the one held nuke slot,
-- so each atomic action (pickup/merge/drop/launch) claims the hands first.
local handOwner
local function claimHand(who)
	if handOwner == nil then
		handOwner = who
		return true
	end
	return false
end
local function releaseHand(who)
	if handOwner == who then handOwner = nil end
end

local function mergeStep()
	local placedList = myPlaced()
	local groups, order = {}, {}
	for _, j in ipairs(placedList) do
		if not groups[j.Tier] then table.insert(order, j.Tier) end
		groups[j.Tier] = (groups[j.Tier] or 0) + 1
	end
	local held = nc:GetHeld(lp)
	if not held then
		local bt
		for _, t in ipairs(order) do
			if groups[t] >= 2 and (not bt or t < bt) then bt = t end
		end
		if not bt then
			setFarm(L("merge_wait_new", #placedList))
			return
		end
		local pick
		for _, j in ipairs(placedList) do
			if j.Tier == bt then pick = j break end
		end
		if not claimHand("merge") then
			setFarm(L("wait_launch_busy"))
			return
		end
		teleportTo(pick.Instance:GetPivot().Position)
		task.wait(0.4)
		Net.PickUp:FireServer(pick.Instance)
		task.wait(0.5)
		releaseHand("merge")
		held = nc:GetHeld(lp)
		if held then
			setFarm(L("merge_picked", bt))
		else
			mergeFails += 1
			if mergeFails >= 4 then
				setFarm(L("pickup_fail"))
				task.wait(5)
				mergeFails = 0
			end
		end
		return
	end
	local hp2 = hrp()
	local best, bd
	for _, j in ipairs(placedList) do
		if j.Tier == held.Tier and j.Id ~= held.Id then
			local d = hp2 and (j.Instance:GetPivot().Position - hp2.Position).Magnitude or 99999
			if not best or d < bd then best, bd = j, d end
		end
	end
	if best then
		if not claimHand("merge") then return end
		mergeFails = 0
		teleportTo(best.Instance:GetPivot().Position)
		task.wait(0.35)
		Net.MergeRequest:FireServer(best.Instance)
		S.mergesDone += 1
		setFarm(L("merge_done", S.mergesDone, held.Tier, held.Tier + 1))
		releaseHand("merge")
		return
	end
	local anyPair = false
	for _, t in ipairs(order) do
		if groups[t] >= 2 then anyPair = true break end
	end
	if anyPair then
		if not claimHand("merge") then return end
		setFarm(L("merge_no_pair", held.Tier))
		dropHeld()
		mergeFails = 0
		releaseHand("merge")
		task.wait(0.8)
	else
		setFarm(L("merge_wait_pair", held.Tier, #placedList))
	end
end

task.spawn(function()
	while STATE.alive() do
		if S.autoMerge then
			local ok, err = pcall(mergeStep)
			if not ok then setFarm(L("err", tostring(err))) end
		end
		local w = S.autoMerge and S.mergeDelay or 0.25
		if w < 0.2 then w = 0.2 end
		task.wait(w)
	end
end)

mergeToggleObj = TabFarm:Toggle({
	Title = L("auto_merge"),
	Desc = L("auto_merge_desc"),
	Value = false,
	Callback = function(v)
		S.autoMerge = v
		mergeFails = 0
		setFarm(v and L("started") or L("off"))
	end,
})

local delaySlider = TabFarm:Slider({
	Title = L("delay_slider"),
	Value = { Min = 0, Max = 3, Default = 1 },
	Step = 0.05,
	Callback = function(v) S.mergeDelay = v end,
})

local lockP = TabFarm:Paragraph({ Title = L("autolock_p"), Desc = L("off") })

_G.NH_AutoLock = false

local autoLockToggle = TabFarm:Toggle({
	Title = L("autolock_toggle"),
	Desc = L("autolock_desc"),
	Value = false,
	Callback = function(v)
		_G.NH_AutoLock = v
		if not v then
			pcall(function() lockP:SetDesc(L("off")) end)
		end
	end,
})

task.spawn(function()
	while STATE.alive() do
		if _G.NH_AutoLock then
			pcall(function()
				local mine
				for _, b in ipairs(Workspace.Bases:GetChildren()) do
					if b:GetAttribute("OwnerUserId") == lp.UserId then mine = b break end
				end
				if mine then
					if mine:GetAttribute("BaseLocked") == true then
						pcall(function() lockP:SetDesc(L("locked_more", mmss((mine:GetAttribute("LockEndsAt") or 0) - serverNow()))) end)
					else
						game.ReplicatedStorage.NukeRemotes.RequestLockBase:FireServer()
						pcall(function() lockP:SetDesc(L("lock_request")) end)
					end
				else
					pcall(function() lockP:SetDesc(L("base_not_found")) end)
				end
			end)
		end
		task.wait(2)
	end
end)

-- Auto-Upgrade: buys selected base upgrades when affordable
local BigNum = require(game.ReplicatedStorage.Shared.BigNum)
local UP_KEYS = {
	["Spawn Tier"] = "TIER",
	["Max Spawns"] = "MAX"
	["Lock Base"] = "LOCKBASE",
}
local UP_LEVEL_FIELD = { TIER = "tierLevel", MAX = "maxLevel", LOCKBASE = "lockBaseLevel" }

local function calcUpgradeCost(key, level)
	local cfg = UpgradeConfig[key]
	if not cfg then return BigNum.new(0) end
	local v3 = level - cfg.startLevel
	if not cfg.firstCost then
		return BigNum.new(cfg.baseCost) * BigNum.new(cfg.costMult ^ v3)
	end
	if v3 == 0 then
		return BigNum.new(cfg.firstCost)
	end
	v3 = v3 - 1
	return BigNum.new(cfg.baseCost) * BigNum.new(cfg.costMult ^ v3)
end

local autoUpToggle = TabFarm:Toggle({
	Title = "Auto-Upgrade",
	Desc = "Buys the selected upgrades automatically when you can afford them",
	Value = false,
	Callback = function(v)
		S.autoUpgrade = v
	end,
})

TabFarm:Dropdown({
	Title = "What to upgrade",
	Desc = "Select one or several (all three works too)",
	Values = { "Spawn Tier", "Max Spawns", "Lock Base" },
	Value = S.autoUpKeys,
	Multi = true,
	AllowNone = true,
	Callback = function(v) S.autoUpKeys = v end,
})

task.spawn(function()
	while STATE.alive() do
		if S.autoUpgrade and #S.autoUpKeys > 0 then
			pcall(function()
				local d = profile()
				local cash = BigNum.deserialize(d.cash)
				for _, lbl in ipairs(S.autoUpKeys) do
					local key = UP_KEYS[lbl]
					if key then
						local lvl = d[UP_LEVEL_FIELD[key]]
						local cfg = UpgradeConfig[key]
						if lvl and cfg and not (cfg.maxLevel and lvl >= cfg.maxLevel) then
							local cost = calcUpgradeCost(key, lvl)
							if cost and BigNum.gte(cash, cost) then
								game.ReplicatedStorage.NukeRemotes.PurchaseUpgrade:FireServer(key)
								task.wait(1)
							end
						end
					end
				end
			end)
			task.wait(2)
		else
			task.wait(1)
		end
	end
end)

local launchStatus = TabLaunch:Paragraph({ Title = L("toggle_afarm"), Desc = L("afarm_desc0") })
local function setLaunch(txt)
	pcall(function() launchStatus:SetDesc(txt) end)
end

local function refreshNukes()
	table.clear(nukeMap)
	local list = {}
	for _, j in ipairs(nc:GetNukes(lp)) do
		if j.State == 1 and j.Instance and not j.Locked then
			table.insert(list, j)
		end
	end
	table.sort(list, function(a, b) return a.Tier < b.Tier end)
	local tierNames = UpgradeConfig.TIER_NAMES
	local vals = {}
	for _, j in ipairs(list) do
		local name = (type(tierNames) == "table" and tierNames[j.Tier]) or ("Tier " .. tostring(j.Tier))
		local label = string.format("%s | T%d", name, j.Tier)
		nukeMap[label] = j
		table.insert(vals, label)
	end
	return vals
end

local function refreshTargets()
	table.clear(targetMap)
	local vals = { L("city") }
	targetMap[L("city")] = true
	local cmdList = {}
	for key, data in pairs(CommanderData) do
		if type(data) == "table" and data.DisplayName then
			local hp = data.Health or 0
			local hpStr = hp >= 1000000 and string.format("%.1fM", hp / 1000000) or hp >= 1000 and string.format("%.0fK", hp / 1000) or tostring(hp)
			local rarity = type(data.Rarity) == "table" and data.Rarity.DisplayName or "?"
			table.insert(cmdList, { label = string.format("%s | ❤ %s | %s", data.DisplayName, hpStr, rarity), key = key, hp = hp })
		end
	end
	table.sort(cmdList, function(a, b) return a.hp < b.hp end)
	for _, c in ipairs(cmdList) do
		targetMap[c.label] = c.key
		table.insert(vals, c.label)
	end
	return vals
end

local function pickUpNuke(j)
	if not j or not j.Instance or not j.Instance.Parent then return false end
	teleportTo(j.Instance:GetPivot().Position)
	task.wait(0.5)
	Net.PickUp:FireServer(j.Instance)
	task.wait(1)
	return nc:GetHeld(lp) ~= nil
end

local function launchOne(j, tgtPos, tgtLabel)
	local cdLeft = math.max(0, (tonumber(profile().nukeCdUntil) or 0) - serverNow())
	if cdLeft > 0 then
		return false, L("cooldown", mmss(cdLeft))
	end
	local held = nc:GetHeld(lp)
	if held and held.Id ~= j.Id then
		dropHeld()
		task.wait(0.8)
		held = nil
	end
	if not held then
		if not pickUpNuke(j) then return false, L("pickup_fail2") end
	end
	held = nc:GetHeld(lp)
	if not held then return false, L("no_held") end
	Net.LaunchConfirm:FireServer(tgtPos)
	task.wait(1.2)
	if nc:GetHeld(lp) then
		return false, L("rejected")
	end
	return true, string.format("✅ T%d → %s", held.Tier, tgtLabel)
end

-- 2. Toggle on/off
local farmLoopRunning = false
local function farmTick()
	local selNukes = S.selNukes or {}
	local selTargets = S.selTargets or {}
	if #selNukes == 0 then
		setLaunch(L("no_nukes_sel"))
		task.wait(2)
		return
	end
	if #selTargets == 0 then
		setLaunch(L("no_targets_sel"))
		task.wait(2)
		return
	end
	refreshNukes()
	local targetOrder = {}
	for _, label in ipairs(selTargets) do
		if label ~= L("city") then
			local pos = getTargetPos(label)
			if pos then table.insert(targetOrder, { label = label, pos = pos }) end
		end
	end
	for _, label in ipairs(selTargets) do
		if label == L("city") then
			table.insert(targetOrder, { label = label, pos = getTargetPos(label) })
		end
	end
	local didSomething = false
	for _, tgt in ipairs(targetOrder) do
		for _, nukeLabel in ipairs(selNukes) do
			if not S.autoFarm then return end
			local j = nukeMap[nukeLabel]
			if j and j.Instance and j.Instance.Parent then
				if claimHand("farm") then
					setLaunch(L("launching", nukeLabel, tgt.label))
					local ok, msg = launchOne(j, tgt.pos, tgt.label)
					releaseHand("farm")
					setLaunch(msg)
					didSomething = true
					if not S.autoFarm then return end
					task.wait(1)
				else
					setLaunch(L("wait_merge_busy"))
					task.wait(0.5)
				end
			end
		end
		if not S.autoFarm then return end
	end
	if not didSomething then
		setLaunch(L("no_nukes_wait"))
		task.wait(3)
	else
		task.wait(1)
	end
end

local function startFarmLoop()
	if farmLoopRunning then return end
	farmLoopRunning = true
	task.spawn(function()
		S.farmErr = ""
		setLaunch(L("afarm_started"))
		while S.autoFarm and STATE.alive() do
			S.farmBeat = os.clock()
			local okLoop, errLoop = pcall(farmTick)
			if not okLoop then
				S.farmErr = tostring(errLoop)
				task.wait(1)
			end
		end
farmLoopRunning = false
	end)
end

local afarmToggle = TabLaunch:Toggle({
	Title = L("toggle_afarm"),
	Desc = L("toggle_afarm_desc"),
	Value = false,
	Callback = function(v)
		S.autoFarm = v
		if v then
			startFarmLoop()
		else
			setLaunch(L("afarm_stopped"))
		end
	end,
})

_G.NH_SetAutoFarm = function(v)
	S.autoFarm = v and true or false
	if S.autoFarm then
		startFarmLoop()
	else
		setLaunch(L("afarm_stopped"))
	end
end

-- 3. Which nukes to launch
local nukeDD, targetDD

local lastNukeVals
local function buildNukeDD()
	local vals = refreshNukes()
	local sig = table.concat(vals, "\x1f")
	if sig == lastNukeVals and nukeDD and nukeDD.Parent ~= nil then return end
	lastNukeVals = sig
	if nukeDD then pcall(function() nukeDD:Destroy() end) end
	nukeDD = TabLaunch:Dropdown({
		Title = L("dd_nukes"),
		Desc = #vals == 0 and L("dd_nukes_none") or L("dd_multi"),
		Values = vals,
		Value = S.selNukes,
		Multi = true,
		AllowNone = true,
		Callback = function(v) S.selNukes = v end,
	})
end

-- 4. Where to launch
local function buildTargetDD()
	if targetDD then pcall(function() targetDD:Destroy() end) end
	local vals = refreshTargets()
	targetDD = TabLaunch:Dropdown({
		Title = L("dd_targets"),
		Desc = L("dd_targets_desc"),
		Values = vals,
		Value = S.selTargets,
		Multi = true,
		AllowNone = true,
		Callback = function(v) S.selTargets = v end,
	})
end

buildNukeDD()
buildTargetDD()

task.spawn(function()
	while STATE.alive() do
		task.wait(5)
		pcall(buildNukeDD)
	end
end)

local espInfoP = TabEsp:Paragraph({ Title = L("esp_info_title"), Desc = L("esp_info_desc") })

local espOnToggle = TabEsp:Toggle({
	Title = L("esp_on"),
	Value = false,
	Callback = function(v)
		S.espOn = v
		if not v then clearEsp() end
	end,
})

	local espHideToggle = TabEsp:Toggle({
		Title = L("esp_hide"),
		Desc = L("esp_hide_desc"),
		Value = true,
		Callback = function(v)
			S.hideOriginal = v
			if not v then
				pcall(hideOriginals, false)
			end
		end,
	})

	-- Settings: author
	TabSettings:Paragraph({ Title = "himk1n", Desc = L("author") })

WindUI:Notify({
	Title = L("loaded_t"),
	Content = L("loaded_c"),
	Duration = 5,
	Icon = "radiation",
})
