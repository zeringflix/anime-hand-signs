-- Client entry: wires the HUD (Client.HUD) to data and input. M1/E/R/train, notifications, gates, mood, celebrations.
-- The client predicts visuals only; every number shown comes back from the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local SC = require(ReplicatedStorage.Shared:WaitForChild("SystemsConfig"))
local Client = script.Parent
local U = require(Client.UIKit)
local V = require(Client.VFX)
local Anim = require(Client.Anim)
local Looks = require(Client.Looks)
local Menus = require(Client.Menus)
local HUDView = require(Client.HUD)
local Assets = require(ReplicatedStorage.Shared:WaitForChild("Assets"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local fmt = Config.Format
local C = Color3.fromRGB

local function fmtMult(m: number): string
	if m < 100 then return (string.format("%.2f", m):gsub("%.?0+$", "")) end
	return fmt(m)
end
local function clock(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", s // 60, s % 60)
end

---------------------------------------------------------------- sounds (Roblox built-in content only)
local function sfx(id: string, vol: number?, pitch: number?)
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/" .. id
	s.Volume = vol or 0.5
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
	task.delay(4, function() if s.Parent then s:Destroy() end end)
end

---------------------------------------------------------------- root gui + scaling
local gui = U.new("ScreenGui", {Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui")})
local uiScale = U.new("UIScale", {Parent = gui})
local function rescale()
	local vp = workspace.CurrentCamera.ViewportSize
	uiScale.Scale = math.clamp(math.min(vp.X / 1500, vp.Y / 820), 0.5, 1.25)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local E = HUDView.Build(gui)
for _, b in {E.Attack, E.AbilityE, E.AbilityR} do b.Badge.Visible = not isTouch end

local ctx: any = {Gui = gui, Action = Remotes.Action, EquipSign = Remotes.EquipSign, TeleportStage = Remotes.TeleportStage, Profile = nil}

---------------------------------------------------------------- toasts + celebrations
local toastHolder = U.new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -40, 0, 146), Size = UDim2.fromOffset(600, 200), BackgroundTransparency = 1, Parent = gui})
U.new("UIListLayout", {HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 4), Parent = toastHolder})
local function toast(text: string, color: Color3?)
	local t = U.text({Text = text, Size = UDim2.fromOffset(600, 34), TextColor3 = color or Color3.new(1, 1, 1), Stroke = 3, Parent = toastHolder})
	U.pop(t, 0.5)
	task.delay(2.2, function()
		U.tween(t, 0.4, {TextTransparency = 1})
		local s = t:FindFirstChildOfClass("UIStroke")
		if s then U.tween(s, 0.4, {Transparency = 1}) end
		task.wait(0.45)
		t:Destroy()
	end)
end
ctx.Toast = toast

local celebrateFrame = U.new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(780, 190), BackgroundTransparency = 1, Visible = false, Parent = gui, ZIndex = 8})
local celTitle = U.text({Text = "", Size = UDim2.new(1, 0, 0, 92), Stroke = 5, ZIndex = 8, Parent = celebrateFrame})
local celSub = U.text({Text = "", Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 0, 40), Stroke = 3, ZIndex = 8, Parent = celebrateFrame})
local celSub2 = U.text({Text = "", Position = UDim2.fromOffset(0, 140), Size = UDim2.new(1, 0, 0, 34), Stroke = 3, ZIndex = 8, TextColor3 = C(255, 235, 120), Parent = celebrateFrame})
local celToken = 0
local function celebrate(title: string, sub: string?, color: Color3?, sub2: string?)
	celToken += 1
	local my = celToken
	celTitle.Text = title
	celTitle.TextColor3 = color or C(255, 220, 60)
	celSub.Text = sub or ""
	celSub2.Text = sub2 or ""
	celebrateFrame.Visible = true
	U.pop(celebrateFrame, 0.3)
	task.delay(2.8, function() if celToken == my then celebrateFrame.Visible = false end end)
end
ctx.Celebrate = celebrate

---------------------------------------------------------------- hatch animation
ctx.HatchAnimation = function(eggId: string, petId: string)
	local egg = SC.Eggs[eggId]
	local def = SC.Pets[petId]
	local overlay = U.new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 20, Parent = gui})
	local eggF = U.new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(160, 200), BackgroundColor3 = egg.Color, ZIndex = 21, Parent = overlay})
	U.corner(90).Parent = eggF
	U.stroke(6).Parent = eggF
	sfx("clickfast.wav", 0.4)
	for i = 1, 10 do
		eggF.Rotation = (i % 2 == 0 and 1 or -1) * (6 + i * 1.5)
		task.wait(0.09 + i * 0.01)
	end
	eggF:Destroy()
	sfx("electronicpingshort.wav", 0.6, 0.8)
	local vp = Menus.PetViewport(overlay, petId, UDim2.fromOffset(300, 300), UDim2.new(0.5, -150, 0.45, -170))
	vp.ZIndex = 21
	U.pop(vp, 0.2)
	local rc = SC.RarityColor[def.Rarity]
	U.text({Text = def.Name, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.45, 140), Size = UDim2.fromOffset(600, 60), Stroke = 4, ZIndex = 21, Parent = overlay})
	U.text({Text = string.upper(def.Rarity) .. "   +" .. fmt(def.Boost) .. " BOOST", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.45, 200), Size = UDim2.fromOffset(600, 40),
		TextColor3 = rc == SC.RarityColor.Secret and C(255, 255, 255) or rc, Stroke = 3, ZIndex = 21, Parent = overlay})
	task.delay(2.2, function() overlay:Destroy() end)
end

---------------------------------------------------------------- offline popup
local function offlinePopup(amount: number, secs: number)
	local f = U.new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(460, 250), BackgroundColor3 = C(60, 50, 100), ZIndex = 15, Parent = gui})
	U.corner(18).Parent = f
	U.stroke(5, C(20, 15, 35), Enum.ApplyStrokeMode.Border).Parent = f
	U.text({Text = "WHILE YOU WERE AWAY", Position = UDim2.fromOffset(10, 14), Size = UDim2.new(1, -20, 0, 44), ZIndex = 15, Stroke = 3, Parent = f})
	U.text({Text = string.format("%dh %dm of shadow training", secs // 3600, (secs % 3600) // 60), Position = UDim2.fromOffset(10, 62), Size = UDim2.new(1, -20, 0, 26), TextColor3 = C(210, 210, 240), ZIndex = 15, Parent = f})
	U.text({Text = "+" .. fmt(amount) .. " HAND SIGNS", Position = UDim2.fromOffset(10, 96), Size = UDim2.new(1, -20, 0, 54), TextColor3 = C(120, 255, 110), ZIndex = 15, Stroke = 4, Parent = f})
	local b = U.button({Text = "CLAIM", Color = C(70, 210, 90), Size = UDim2.fromOffset(220, 60), Position = UDim2.new(0.5, -110, 1, -76), Parent = f})
	b.ZIndex = 15
	U.pop(f)
	b.MouseButton1Click:Connect(function()
		Menus.Act("ClaimOffline")
		sfx("electronicpingshort.wav", 0.6)
		f:Destroy()
	end)
end

Menus.Init(ctx)
task.spawn(function() -- lobby hub (issue #14); isolated so a lobby error can't break core UI
	local ok, err = pcall(function() require(Client:WaitForChild("Lobby")).Init(ctx) end)
	if not ok then warn("[Lobby] init failed:", err) end
end)
Looks.Start()
Anim.Start()

---------------------------------------------------------------- menu wiring
local function open(id: string) sfx("electronicpingshort.wav", 0.25, 1.4); Menus.Open(id) end
E.SignsButton.MouseButton1Click:Connect(function() open("Signs") end)
for id, b in E.Grid do b.MouseButton1Click:Connect(function() open(id) end) end
for id, b in E.TopIcons do b.MouseButton1Click:Connect(function() open(id) end) end
E.Promo.Visible = SC.DevProducts.Boost15.Id ~= 0
E.Promo.MouseButton1Click:Connect(function() Menus.Act("BuyProduct", "Boost15") end)
for key in {PackSmall = 1, PackMedium = 1, PackLarge = 1} do
	E.Packs[key .. "Button"].MouseButton1Click:Connect(function() Menus.Act("BuyProduct", key) end)
end
E.OPAuto.MouseButton1Click:Connect(function()
	local p = ctx.Profile
	if p and p.Passes and p.Passes.AutoClicker then
		local on = not (p.Settings and p.Settings.AutoTrain == false)
		Menus.Act("Setting", "AutoTrain", not on)
	else
		Menus.Act("BuyPass", "AutoClicker")
	end
end)
E.FreeAuto.MouseButton1Click:Connect(function()
	local r = Menus.Act("FreeAuto")
	if r and r.ok then toast("Free Auto Clicker ON for " .. clock(SC.FreeAuto.ActiveSeconds) .. "!", C(120, 255, 110)) end
end)

---------------------------------------------------------------- equipped sign -> E / R buttons
local ELEMENT_ICON = {fireball = "\u{1F525}", phoenix = "\u{1F525}", rasengan = "\u{1F300}", clones = "\u{1F465}", snakes = "\u{1F40D}", shadow = "\u{1F311}", shadowhands = "\u{1F311}",
	chidori = "\u{26A1}", lightningburst = "\u{26A1}", log = "\u{1FAB5}", flicker = "\u{1F4A8}", flamebeam = "\u{1F409}", flamewave = "\u{1F525}", summon = "\u{1F438}", earthwall = "\u{1FAA8}",
	waterwall = "\u{1F30A}", waterdragon = "\u{1F409}", gust = "\u{1F32C}", rasenshuriken = "\u{1F4A0}", senbon = "\u{26A1}", giantrasengan = "\u{1F300}", kirin = "\u{1F329}",
	blackflame = "\u{1F5A4}", susanoo = "\u{1F6E1}", planetary = "\u{1FA90}", beastbomb = "\u{1F4A5}"}
local cooldownEnds: {[string]: {Ends: number, Duration: number}} = {}
local function currentSign() return Config.HandSigns[player:GetAttribute("Equipped") or "Tiger"] or Config.HandSigns.Tiger end
local function refreshAbilities()
	local s = currentSign()
	for _, pair in {{E.AbilityE, s.E}, {E.AbilityR, s.R}} do
		local b, j = pair[1], Config.Jutsu[pair[2]]
		b.Name.Text = j.Short
		b.Icon.Image = (Assets.SignIcons and Assets.SignIcons[s.Id]) or Assets.Icon(Assets.JutsuIcon[j.Vfx] or "Chakra")
	end
	-- one emblem motif: the equipped hand sign's icon on ATTACK, E and R (issue #14)
	if Assets.SignIcons and Assets.SignIcons[s.Id] then E.Attack.Icon.Image = Assets.SignIcons[s.Id] end
end
player:GetAttributeChangedSignal("Equipped"):Connect(function()
	refreshAbilities()
	local s = currentSign()
	toast("Equipped " .. s.Name .. ":  E " .. Config.Jutsu[s.E].Short .. "  /  R " .. Config.Jutsu[s.R].Short, s.Color)
	Menus.Refresh()
end)
refreshAbilities()

---------------------------------------------------------------- training (batched taps, LihFolk: Tap Simulator teardown)
local pendingTrain = 0
local predicted = 0
local lastTrain = 0
local function estimateGain(): number
	local p = ctx.Profile
	local up = 1 + ((p and p.Upgrades and p.Upgrades.SignsPerClick) or 0)
	return up * (player:GetAttribute("Multiplier") or 1) * (player:GetAttribute("RebirthMult") or 1)
end
local function head(): Vector3?
	local c = player.Character
	local h = c and c:FindFirstChild("Head") :: BasePart?
	return h and h.Position
end
local function train()
	local now = os.clock()
	if now - lastTrain < 1 / Config.Economy.MaxTrainsPerSecond then return end
	lastTrain = now
	pendingTrain += 1
	local g = estimateGain()
	predicted += g
	Anim.Train()
	local h = head()
	if h and not V.Reduced then V.FloatText(h + Vector3.new(math.random(-20, 20) / 10, 1.5, 0), "+" .. fmt(g) .. " \u{1F590}", C(110, 200, 255), 38) end
	sfx("clickfast.wav", 0.12, 1 + math.random() * 0.2)
	E.BigScale.Scale = 1.08
	U.tween(E.BigScale, 0.15, {Scale = 1})
end
task.spawn(function()
	while true do
		task.wait(0.2)
		if pendingTrain > 0 then
			Remotes.Train:FireServer(pendingTrain)
			pendingTrain = 0
		end
	end
end)

---------------------------------------------------------------- combat input
local enemiesFolder = workspace:WaitForChild("Enemies")
local function nearestEnemy(range: number): Model?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not r then return nil end
	local best, bd = nil, range
	for _, m in enemiesFolder:GetChildren() do
		local er = m:FindFirstChild("HumanoidRootPart") :: BasePart?
		if er and (m:GetAttribute("Hp") or 1) > 0 then
			local d = (er.Position - r.Position).Magnitude
			if d < bd then best, bd = m, d end
		end
	end
	return best
end
local function face(target: Model?)
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tr = target and target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if r and tr then
		local flat = Vector3.new(tr.Position.X, r.Position.Y, tr.Position.Z)
		if (flat - r.Position).Magnitude > 0.5 then r.CFrame = CFrame.lookAt(r.Position, flat) end
	end
end

local lastAttack = 0
local function attack()
	local now = os.clock()
	if now - lastAttack < 0.32 then return end
	local target = nearestEnemy(18)
	if not target then return end
	lastAttack = now
	face(target)
	Remotes.Attack:FireServer()
	sfx("swordslash.wav", 0.3, 1.1 + math.random() * 0.2)
end
-- one click = +1 training, and a punch when an enemy is in reach ("Click to attack!")
local function primary() train(); attack() end

local function cast(slot: string)
	local s = currentSign()
	local jid = slot == "E" and s.E or s.R
	local cd = cooldownEnds[jid]
	if cd and workspace:GetServerTimeNow() < cd.Ends - 0.1 then return end
	local j = Config.Jutsu[jid]
	face(nearestEnemy(j.Range > 0 and j.Range or 30))
	Remotes.Cast:FireServer(slot)
	sfx("swordlunge.wav", 0.35)
end

E.Attack.Button.MouseButton1Click:Connect(primary)
E.AbilityE.Button.MouseButton1Click:Connect(function() cast("E") end)
E.AbilityR.Button.MouseButton1Click:Connect(function() cast("R") end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if not Menus.IsOpen() then primary() end
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then cast("E")
	elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then cast("R")
	elseif input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonL2 then train()
	elseif input.KeyCode == Enum.KeyCode.ButtonR2 then primary()
	elseif input.KeyCode == Enum.KeyCode.ButtonB and Menus.IsOpen() then Menus.Close()
	end
end)
UserInputService.TouchTapInWorld:Connect(function(_pos, processed)
	if not processed and not Menus.IsOpen() then primary() end
end)

---------------------------------------------------------------- server -> client
Remotes.Vfx.OnClientEvent:Connect(function(kind, ...)
	if kind == "Knock" then
		local vel = ...
		local c = player.Character
		local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r and typeof(vel) == "Vector3" then
			r.AssemblyLinearVelocity = vel
			V.Shake(1.5)
		end
		return
	end
	V.Dispatch(kind, ...)
end)
Remotes.DamageNumber.OnClientEvent:Connect(function(pos: Vector3, amount: number)
	V.FloatText(pos + Vector3.new(0, 3, 0), fmt(amount), C(255, 235, 80), 44)
end)

local menuSig = ""
local function sigOf(p)
	local copy = table.clone(p)
	copy.ServerTime = nil
	copy.LifetimeHandSigns = nil
	copy.SessionStart = nil
	return HttpService:JSONEncode(copy)
end

local updateGates
local serverOffset = 0 -- os.time() on server minus local os.time()
Remotes.Profile.OnClientEvent:Connect(function(json: string)
	local ok, p = pcall(HttpService.JSONDecode, HttpService, json)
	if not ok then return end
	ctx.Profile = p
	serverOffset = (p.ServerTime or os.time()) - os.time()
	local reduced = p.Settings and p.Settings.ReduceEffects == true
	local hide = p.Settings and p.Settings.HideOtherPets == true
	if V.Reduced ~= reduced or Looks.HideOthers ~= hide then
		V.Reduced = reduced; Looks.Reduced = reduced; Looks.HideOthers = hide
		Looks.Refresh()
	end
	updateGates()
	local s = sigOf(p)
	if s ~= menuSig then menuSig = s; Menus.Refresh() end
end)

Remotes.Notify.OnClientEvent:Connect(function(kind: string, payload: any)
	if kind == "LevelUp" then
		celebrate("LEVEL UP!", "Level " .. payload, C(255, 220, 60))
		sfx("electronicpingshort.wav", 0.6, 1.2)
	elseif kind == "SignUnlocked" then
		local s = Config.HandSigns[payload]
		if s then
			celebrate("NEW HAND SIGN!", string.upper(s.Name) .. "  (x" .. fmt(s.Multiplier) .. ")", s.Color, "E: " .. Config.Jutsu[s.E].Name .. "   R: " .. Config.Jutsu[s.R].Name)
			sfx("electronicpingshort.wav", 0.7, 0.7)
			toast("Open HAND SIGNS to equip " .. s.Name, C(120, 255, 140))
		end
	elseif kind == "StageCleared" then
		celebrate("STAGE CLEARED!", "Grab your Trophies on the pad!", C(120, 255, 120), payload.Stage < Config.StageCount and ("Stage " .. payload.Stage + 1 .. " unlocked") or "You beat the Divine Chakra Master!")
		sfx("electronicpingshort.wav", 0.7, 1)
	elseif kind == "PadClaimed" then
		toast("+" .. fmt(payload.Amount) .. " \u{1F3C6} Trophies!", C(255, 220, 80))
		sfx("electronicpingshort.wav", 0.5, 1.5)
	elseif kind == "NoTarget" then
		toast("No enemy in range for " .. tostring(payload), C(255, 160, 160))
	elseif kind == "Cooldown" then
		cooldownEnds[payload.Jutsu] = {Ends = payload.Ends, Duration = payload.Duration}
	elseif kind == "CooldownSync" then
		for id, ends in payload do
			local j = Config.Jutsu[id]
			cooldownEnds[id] = {Ends = ends, Duration = j and j.Cooldown or 1}
		end
	elseif kind == "Rebirth" then
		celebrate("REBIRTH!", "Rebirths: " .. payload, C(200, 120, 255), "Training multiplier x" .. (1 + payload * 0.75))
		sfx("electronicpingshort.wav", 0.7, 0.6)
	elseif kind == "BossPhase" then
		celebrate(payload == 3 and "FINAL PHASE!" or "PHASE " .. payload .. "!", "The Divine Chakra Master grows stronger", C(255, 200, 80))
		V.Shake(2)
	elseif kind == "Offline" then
		offlinePopup(payload.Amount, payload.Seconds)
	end
end)

---------------------------------------------------------------- gates (per-player view of the shared course)
local course = workspace:WaitForChild("StageCourse")
function updateGates()
	local highest = player:GetAttribute("Highest") or 1
	local kills = ctx.Profile and ctx.Profile.StageKills or {}
	for i = 1, Config.StageCount do
		local sf = course:FindFirstChild(string.format("Stage%02d", i))
		local barrier = sf and sf:FindFirstChild("Gate") and sf.Gate:FindFirstChild("Barrier") :: BasePart?
		if barrier then
			local open = highest > i
			barrier.CanCollide = not open -- client-side only; the server's gate guard is the real check
			barrier.Transparency = open and 0.72 or 0.3
			local txt
			if open then txt = "OPEN \u{2192}"
			elseif i > highest then txt = "\u{1F512} LOCKED"
			else
				local left = Config.Economy.KillsToClear - (kills[tostring(i)] or 0)
				txt = left <= 0 and "STAGE CLEARED!" or (left .. " LEFT")
			end
			for _, g in {barrier:FindFirstChild("FrontGui"), barrier:FindFirstChild("BackGui")} do
				local l = g and g:FindFirstChild("Left", true) :: TextLabel?
				if l then l.Text = txt end
			end
		end
	end
end
course.ChildAdded:Connect(function() task.wait(1); updateGates() end)
player:GetAttributeChangedSignal("Highest"):Connect(function() updateGates() end)

---------------------------------------------------------------- per-frame HUD
local shownSigns = 0
player:GetAttributeChangedSignal("HandSigns"):Connect(function() predicted = 0 end)
RunService.RenderStepped:Connect(function(dt)
	local real = (player:GetAttribute("HandSigns") or 0) + predicted
	shownSigns = shownSigns + (real - shownSigns) * math.min(1, dt * 12)
	if math.abs(real - shownSigns) < 1 then shownSigns = real end
	E.BigCount.Text = fmt(shownSigns) .. " Hand Signs"
	E.Trophies.Text = fmt(player:GetAttribute("Trophies") or 0)
	E.RebirthCount.Text = tostring(player:GetAttribute("Rebirths") or 0)
	local p = ctx.Profile
	E.Multiplier.Text = "Multiplier: x" .. fmtMult(player:GetAttribute("Multiplier") or 1)
	E.PetsMult.Text = "Pets: x" .. fmtMult(p and p.PetMult or 1)
	E.RebirthMult.Text = "Rebirths: x" .. fmtMult(player:GetAttribute("RebirthMult") or 1)
	local xp, need = player:GetAttribute("XP") or 0, player:GetAttribute("XPNeed") or 1
	E.LevelText.Text = "Level " .. (player:GetAttribute("Level") or 1)
	E.XPText.Text = fmt(xp) .. " / " .. fmt(need)
	E.LevelFill.Size = E.LevelFill.Size:Lerp(UDim2.fromScale(math.clamp(xp / need, 0, 1), 1), math.min(1, dt * 10))

	-- cooldown overlays
	local now = workspace:GetServerTimeNow()
	local s = currentSign()
	for _, pair in {{E.AbilityE, s.E}, {E.AbilityR, s.R}} do
		local b, cd = pair[1], cooldownEnds[pair[2]]
		local left = cd and (cd.Ends - now) or 0
		if left > 0 then
			b.Cd.Size = UDim2.fromScale(1, math.clamp(left / cd.Duration, 0, 1))
			b.CdText.Text = string.format(left < 10 and "%.1f" or "%d", left)
		else
			b.Cd.Size = UDim2.fromScale(1, 0)
			b.CdText.Text = ""
		end
	end
	E.Attack.Cd.Size = UDim2.fromScale(1, math.clamp((0.32 - (os.clock() - lastAttack)) / 0.32, 0, 1))
end)

-- slower HUD bits: objective, boss bar, packs, timers, rebirth %
task.spawn(function()
	while true do
		task.wait(0.2)
		local p = ctx.Profile
		local inStage = player:GetAttribute("InStage") or 1
		local highest = player:GetAttribute("Highest") or 1
		local serverNow = os.time() + serverOffset
		local pendingPad = p and p.PendingPads and p.PendingPads[tostring(inStage)]
		if pendingPad then E.Banner.Text = "Stage cleared! Step on the Trophy pad!"
		elseif inStage < highest then E.Banner.Text = "Head through the gate to Stage " .. highest .. "!"
		else E.Banner.Text = "Defeat the enemies! Click to attack!" end

		local boss
		for _, m in enemiesFolder:GetChildren() do
			if m:GetAttribute("Boss") and m:GetAttribute("Stage") == inStage and (m:GetAttribute("Hp") or 0) > 0 then boss = m break end
		end
		E.Boss.Visible = boss ~= nil
		if boss then
			local hp, mx = boss:GetAttribute("Hp") or 0, boss:GetAttribute("MaxHp") or 1
			E.BossName.Text = string.upper(boss:GetAttribute("EnemyName") or "Boss")
			E.BossFill.Size = UDim2.fromScale(math.clamp(hp / mx, 0, 1), 1)
			E.BossHp.Text = (hp / mx > 0.99 and (string.upper(boss:GetAttribute("EnemyName") or "BOSS") .. " IS HERE!") or (fmt(math.ceil(hp)) .. " / " .. fmt(mx)))
		end

		-- packs show what they'd give right now
		local g = estimateGain()
		for key, dp in SC.DevProducts do
			local l = E.Packs[key]
			if l then l.Text = "+" .. fmt(g * (dp :: any).Clicks) end
		end
		-- boost timer
		local boostLeft = (p and p.BoostUntil or 0) - serverNow
		E.BoostLabel.Text = boostLeft > 0 and ("x2 Hand Signs " .. clock(boostLeft)) or ""
		-- rebirth readiness
		local cost = p and p.RebirthCost or SC.RebirthCost(player:GetAttribute("Rebirths") or 0)
		local pct = math.clamp(math.floor((player:GetAttribute("HandSigns") or 0) / cost * 100), 0, 100)
		E.RebirthTag.Text = pct .. "%"
		E.RebirthTag.TextColor3 = pct >= 100 and C(130, 255, 120) or C(255, 255, 255)
		-- daily reward dot
		E.DailyDot.Visible = p ~= nil and (serverNow - (p.LastDaily or 0)) >= SC.DailyCooldown
		-- auto clickers
		local ownsOP = p and p.Passes and p.Passes.AutoClicker
		E.OPAutoLabel.Text = ownsOP and ((p.Settings and p.Settings.AutoTrain == false) and "OFF" or "ON") or (SC.GamePasses.AutoClicker.Id == 0 and "SOON" or "BUY")
		local activeLeft = (p and p.FreeAutoUntil or 0) - serverNow
		local readyIn = (p and p.FreeAutoReady or 0) - serverNow
		if activeLeft > 0 then
			E.FreeAutoLabel.Text = clock(activeLeft)
			E.FreeAuto.BackgroundColor3 = C(70, 200, 90)
			E.FreeAutoFill.Size = UDim2.fromScale(activeLeft / SC.FreeAuto.ActiveSeconds, 1)
		elseif readyIn > 0 then
			E.FreeAutoLabel.Text = clock(readyIn)
			E.FreeAuto.BackgroundColor3 = C(90, 90, 105)
			E.FreeAutoFill.Size = UDim2.fromScale(1 - readyIn / SC.FreeAuto.CooldownSeconds, 1)
		else
			E.FreeAutoLabel.Text = "CLAIM"
			E.FreeAuto.BackgroundColor3 = C(70, 200, 90)
			E.FreeAutoFill.Size = UDim2.fromScale(1, 1)
		end
	end
end)

---------------------------------------------------------------- per-stage atmosphere (biome mood without darkening enemies)
local MOOD = {
	leaf = {C(200, 225, 255), C(120, 150, 200), C(255, 255, 255), 1.0}, wind = {C(255, 225, 240), C(230, 160, 200), C(255, 245, 250), 1.2},
	earth = {C(255, 225, 180), C(220, 150, 90), C(255, 245, 230), 1.4}, water = {C(190, 230, 235), C(110, 170, 180), C(240, 255, 255), 1.8},
	ice = {C(230, 245, 255), C(170, 210, 240), C(240, 250, 255), 1.6}, lightning = {C(180, 190, 230), C(90, 100, 160), C(235, 240, 255), 2.0},
	fire = {C(255, 190, 150), C(200, 90, 50), C(255, 235, 220), 1.8}, spirit = {C(190, 230, 220), C(90, 140, 140), C(235, 255, 250), 2.0},
	moon = {C(170, 180, 230), C(80, 90, 160), C(225, 230, 255), 2.0}, poison = {C(200, 230, 160), C(110, 140, 60), C(245, 255, 230), 2.0},
	steel = {C(215, 220, 230), C(140, 150, 170), C(250, 250, 255), 1.2}, shadow = {C(190, 175, 215), C(100, 80, 130), C(240, 235, 250), 1.8},
	crystal = {C(220, 190, 255), C(130, 80, 200), C(245, 235, 255), 1.8}, chakra = {C(190, 230, 255), C(80, 160, 230), C(235, 250, 255), 1.6},
	nature = {C(220, 245, 190), C(150, 190, 100), C(250, 255, 240), 1.2}, light = {C(255, 245, 215), C(255, 210, 140), C(255, 252, 240), 1.0},
	void = {C(170, 120, 230), C(70, 30, 120), C(240, 225, 255), 2.4}, divine = {C(255, 240, 200), C(255, 200, 120), C(255, 250, 235), 1.0},
}
local lastMoodStage = 0
local function applyMood()
	local s = player:GetAttribute("InStage") or 1
	if s == lastMoodStage then return end
	lastMoodStage = s
	local st = Config.Stages[s]
	local m = MOOD[st and st.Element or "leaf"] or MOOD.leaf
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then U.tween(atm, 1.5, {Color = m[1], Decay = m[2], Haze = m[4]}) end
	local cc = Lighting:FindFirstChild("StageGrade")
	if cc then U.tween(cc, 1.5, {TintColor = m[3]}) end
	if s > 1 then toast("STAGE " .. s .. " - " .. string.upper(st.Name), st.Gate) end
end
player:GetAttributeChangedSignal("InStage"):Connect(applyMood)
applyMood()
updateGates()
