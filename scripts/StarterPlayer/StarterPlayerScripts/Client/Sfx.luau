-- Sfx (client): every sound in the game goes through here (owner 2026-11-02: new SFX, sounds for everything).
-- Sources are licensed only: Roblox-provided Pro Sound Effects / APM Music library assets ("Courtesy of ...")
-- and sounds that ship with the Roblox client (rbxasset://sounds). No user-uploaded rips.
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local M = {}
-- name = {id, volume, pitch, pitchJitter}
M.Lib = {
	Click = {"rbxasset://sounds/electronicpingshort.wav", 0.22, 1.9, 0.05},
	Open = {"rbxassetid://9112872239", 0.45, 1.5, 0.05},            -- PSE small bubble pop
	Close = {"rbxassetid://9112872239", 0.35, 1.15, 0.05},
	Hover = {"rbxasset://sounds/electronicpingshort.wav", 0.07, 2.6, 0.06},
	Train = {"rbxasset://sounds/clickfast.wav", 0.12, 1.1, 0.2},
	Swing = {"rbxassetid://9120728815", 0.35, 1.15, 0.12},           -- PSE whoosh heavy punches
	Hit = {"rbxassetid://9117969717", 0.45, 1.05, 0.12},             -- PSE punch kit beefy hit
	HitTaken = {"rbxassetid://9117969687", 0.5, 0.85, 0.08},
	Fire = {"rbxassetid://9114442751", 0.5, 1, 0.08},                -- PSE fire whoosh
	Lightning = {"rbxassetid://9114277757", 0.45, 1.1, 0.08},        -- PSE electric zaps
	Water = {"rbxassetid://9125703168", 0.5, 1, 0.1},                -- PSE water splash
	Magic = {"rbxassetid://9116394545", 0.4, 1.25, 0.08},            -- PSE magic glow chimes
	Boom = {"rbxassetid://9117969878", 0.7, 0.55, 0.06},             -- PSE beefy hit, pitched down = deep boom
	Poof = {"rbxassetid://9112872244", 0.45, 1.6, 0.1},              -- PSE bubble pop, pitched up = cartoon poof
	Coins = {"rbxassetid://9113728049", 0.45, 1.1, 0},               -- PSE cash register
	Buy = {"rbxassetid://9113728049", 0.5, 1, 0},
	Reward = {"rbxassetid://9116394545", 0.55, 1, 0},
	Win = {"rbxassetid://1839881844", 0.45, 1, 0},                   -- APM "Spinning Around (b)" sting
	LevelUp = {"rbxassetid://9047103106", 0.4, 1, 0},                -- APM "All It Takes Sting 2"
	Rebirth = {"rbxassetid://9116395089", 0.6, 0.9, 0},
	Teleport = {"rbxassetid://9116394876", 0.5, 1.35, 0},
	GateOpen = {"rbxassetid://9116394545", 0.45, 0.8, 0},
	EggShake = {"rbxasset://sounds/clickfast.wav", 0.35, 0.9, 0.15},
	Error = {"rbxasset://sounds/electronicpingshort.wav", 0.3, 0.55, 0},
}
-- jutsu VFX family -> sound
M.JutsuSound = {
	fireball = "Fire", phoenix = "Fire", flamebeam = "Fire", flamewave = "Fire", blackflame = "Fire", beastbomb = "Fire",
	chidori = "Lightning", lightningburst = "Lightning", senbon = "Lightning", kirin = "Lightning",
	waterwall = "Water", waterdragon = "Water",
	rasengan = "Magic", giantrasengan = "Magic", rasenshuriken = "Magic", gust = "Swing", clones = "Poof", log = "Poof",
	flicker = "Swing", summon = "Poof", snakes = "Swing", shadow = "Magic", shadowhands = "Magic", earthwall = "Boom",
	susanoo = "Magic", planetary = "Boom",
}

local folder = Instance.new("SoundGroup")
folder.Name = "SFX"
folder.Volume = 1
folder.Parent = SoundService
M.Group = folder

local last: {[string]: number} = {}
local function make(name: string, parent: Instance, volMul: number?): Sound?
	local d = M.Lib[name]
	if not d then return nil end
	-- tiny per-sound throttle so spam (M1, damage) never stacks into noise
	local now = os.clock()
	if last[name] and now - last[name] < 0.045 then return nil end
	last[name] = now
	local s = Instance.new("Sound")
	s.SoundId = d[1]
	s.Volume = d[2] * (volMul or 1)
	s.PlaybackSpeed = d[3] + (d[4] > 0 and (math.random() * 2 - 1) * d[4] or 0)
	s.SoundGroup = folder
	s.Parent = parent
	return s
end

function M.Play(name: string, volMul: number?)
	local s = make(name, SoundService, volMul)
	if not s then return end
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
	Debris:AddItem(s, 8)
end

-- 3D sound at a world position (jutsu, hits, explosions)
function M.PlayAt(name: string, pos: Vector3, volMul: number?)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = workspace.Terrain
	local s = make(name, a, volMul)
	if not s then a:Destroy() return end
	s.RollOffMinDistance = 12
	s.RollOffMaxDistance = 160
	s:Play()
	Debris:AddItem(a, 8)
end

function M.Jutsu(vfx: string?, pos: Vector3?)
	local n = (vfx and M.JutsuSound[vfx]) or "Magic"
	if pos then M.PlayAt(n, pos) else M.Play(n) end
end

return M
