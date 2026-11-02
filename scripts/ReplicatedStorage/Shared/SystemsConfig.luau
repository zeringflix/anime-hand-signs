--!strict
-- Pets, eggs, auras, upgrades, rebirths, rewards, monetisation slots. Shared so the UI shows the same numbers the server uses.
local Config = require(script.Parent.Config)
local C = Color3.fromRGB
local S = {}

---------------------------------------------------------------- RARITIES
S.RarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}
S.RarityColor = {
	Common = C(200, 200, 200), Uncommon = C(90, 220, 90), Rare = C(70, 160, 255), Epic = C(190, 90, 255),
	Legendary = C(255, 190, 40), Mythic = C(255, 70, 120), Secret = C(30, 30, 30),
}

---------------------------------------------------------------- PETS
-- Boost is additive: total pet multiplier = 1 + sum(Boost) of equipped pets.
-- Shape drives the original part-built model (client): cat, dog, fox, spirit, serpent, golem, wolf, dragon, toad, beast
export type Pet = {Id: string, Name: string, Rarity: string, Boost: number, Shape: string, Color: Color3, Color2: Color3}
S.Pets = {} :: {[string]: Pet}
local function pet(id, name, rarity, boost, shape, c1, c2)
	S.Pets[id] = {Id = id, Name = name, Rarity = rarity, Boost = boost, Shape = shape, Color = c1, Color2 = c2}
	return id
end

-- Eggs: Stage = stage that must be unlocked; Cost in Trophies; Odds in percent (sum 100)
export type Egg = {Id: string, Name: string, Stage: number, Cost: number, Color: Color3, Odds: {{Pet: string, Chance: number}}}
S.EggOrder = {"Ninja", "Sakura", "Desert", "Forest", "Lightning", "Summoning", "Celestial", "Divine"}
local eggStages = {Ninja = 1, Sakura = 2, Desert = 3, Forest = 11, Lightning = 21, Summoning = 26, Celestial = 36, Divine = 46}
local eggColors = {Ninja = C(255, 150, 60), Sakura = C(255, 160, 210), Desert = C(235, 200, 120), Forest = C(70, 170, 90),
	Lightning = C(120, 200, 255), Summoning = C(255, 170, 60), Celestial = C(180, 200, 255), Divine = C(255, 220, 120)}
local eggPets = {
	Ninja = {
		{pet("NinjaCat", "Ninja Cat", "Common", 0.10, "cat", C(70, 70, 80), C(230, 60, 60)), 55},
		{pet("NinjaDog", "Ninja Dog", "Uncommon", 0.20, "dog", C(200, 150, 90), C(40, 40, 50)), 30},
		{pet("ChakraFox", "Chakra Fox", "Rare", 0.40, "fox", C(255, 140, 40), C(255, 240, 220)), 13},
		{pet("KitsuneKit", "Nine-Tail Kit", "Epic", 0.90, "fox", C(255, 100, 30), C(255, 60, 40)), 2},
	},
	Sakura = {
		{pet("BlossomBunny", "Blossom Bunny", "Common", 0.18, "cat", C(255, 210, 230), C(255, 130, 180)), 55},
		{pet("SakuraSpirit", "Sakura Spirit", "Uncommon", 0.35, "spirit", C(255, 170, 210), C(255, 255, 255)), 30},
		{pet("PetalFox", "Petal Fox", "Rare", 0.70, "fox", C(255, 150, 200), C(255, 255, 255)), 13},
		{pet("BlossomDragon", "Blossom Dragon", "Legendary", 2.0, "dragon", C(255, 140, 200), C(255, 230, 240)), 2},
	},
	Desert = {
		{pet("SandPup", "Sand Pup", "Common", 0.35, "dog", C(230, 200, 140), C(160, 120, 70)), 55},
		{pet("SandGolem", "Sand Golem", "Uncommon", 0.7, "golem", C(220, 180, 110), C(150, 110, 60)), 30},
		{pet("DuneSerpent", "Dune Serpent", "Rare", 1.4, "serpent", C(210, 160, 70), C(120, 80, 40)), 13},
		{pet("SunScorpion", "Sun Golem", "Epic", 3.0, "golem", C(255, 200, 60), C(255, 120, 30)), 2},
	},
	Forest = {
		{pet("MossToad", "Moss Toad", "Uncommon", 2.5, "toad", C(100, 170, 80), C(60, 110, 50)), 55},
		{pet("ForestSerpent", "Forest Serpent", "Rare", 5, "serpent", C(60, 150, 70), C(200, 230, 90)), 30},
		{pet("SpiritStag", "Spirit Wolf", "Epic", 10, "wolf", C(140, 255, 210), C(255, 255, 255)), 13},
		{pet("AncientTreant", "Ancient Golem", "Legendary", 25, "golem", C(90, 120, 60), C(150, 220, 90)), 2},
	},
	Lightning = {
		{pet("SparkCat", "Spark Cat", "Rare", 40, "cat", C(255, 240, 90), C(80, 160, 255)), 55},
		{pet("ThunderWolf", "Thunder Wolf", "Epic", 80, "wolf", C(90, 140, 255), C(255, 255, 140)), 30},
		{pet("StormDragon", "Storm Dragon", "Legendary", 180, "dragon", C(70, 110, 220), C(200, 240, 255)), 13},
		{pet("KirinBeast", "Kirin Beast", "Mythic", 500, "beast", C(200, 230, 255), C(120, 200, 255)), 2},
	},
	Summoning = {
		{pet("ToadCompanion", "Toad Companion", "Rare", 300, "toad", C(255, 150, 60), C(120, 60, 30)), 55},
		{pet("SlugSage", "Snail Sage", "Epic", 650, "spirit", C(150, 220, 255), C(255, 255, 255)), 30},
		{pet("GiantSerpent", "Giant Serpent", "Legendary", 1500, "serpent", C(150, 90, 200), C(230, 220, 120)), 13},
		{pet("HawkSummon", "Sky Hawk", "Mythic", 4000, "dragon", C(120, 80, 60), C(240, 230, 210)), 2},
	},
	Celestial = {
		{pet("StarCat", "Star Cat", "Epic", 6000, "cat", C(220, 220, 255), C(255, 230, 120)), 55},
		{pet("CelestialBeast", "Celestial Beast", "Legendary", 14000, "beast", C(200, 210, 255), C(255, 255, 255)), 30},
		{pet("MoonFox", "Moon Fox", "Mythic", 35000, "fox", C(190, 200, 255), C(120, 130, 230)), 13},
		{pet("CometDragon", "Comet Dragon", "Secret", 100000, "dragon", C(60, 70, 140), C(150, 230, 255)), 2},
	},
	Divine = {
		{pet("HaloPup", "Halo Pup", "Legendary", 150000, "dog", C(255, 245, 220), C(255, 210, 90)), 55},
		{pet("DivineWolf", "Divine Wolf", "Mythic", 400000, "wolf", C(255, 240, 200), C(255, 200, 60)), 30},
		{pet("DivineDragon", "Divine Dragon", "Mythic", 1000000, "dragon", C(255, 230, 150), C(255, 255, 255)), 13},
		{pet("SixPathsBeast", "Six Paths Beast", "Secret", 3000000, "beast", C(30, 20, 40), C(220, 160, 255)), 2},
	},
}
-- display names (owner concept sheet, issue #14); ids stay the same so saves/odds are untouched
local EGG_DISPLAY = {Ninja = "Leaf", Sakura = "Blossom", Desert = "Desert", Forest = "Storm", Lightning = "Shadow", Summoning = "Flame", Celestial = "Spirit", Divine = "Mythic"}
S.Eggs = {} :: {[string]: Egg}
for _, id in S.EggOrder do
	local stage = eggStages[id]
	local odds = {}
	for _, row in eggPets[id] do table.insert(odds, {Pet = row[1], Chance = row[2]}) end
	S.Eggs[id] = {Id = id, Name = (EGG_DISPLAY[id] or id) .. " Egg", Stage = stage, Cost = math.max(25, Config.Stages[stage].Trophies * 15), Color = eggColors[id], Odds = odds}
end
S.MaxPetsOwned = 60
S.BasePetSlots = 3

---------------------------------------------------------------- AURAS (training multiplier, x)
export type Aura = {Id: string, Name: string, Mult: number, Stage: number, Cost: number, Color: Color3, Color2: Color3, Style: string}
S.AuraOrder = {"Blue", "Sakura", "Wind", "Lightning", "Fire", "Cursed", "Golden", "Divine"}
local auraData = {
	Blue = {"Blue Chakra Aura", 1.5, 2, C(80, 170, 255), C(200, 240, 255), "flame"},
	Sakura = {"Sakura Aura", 2.5, 5, C(255, 150, 200), C(255, 230, 240), "petals"},
	Wind = {"Wind Aura", 4, 10, C(170, 255, 220), C(255, 255, 255), "swirl"},
	Lightning = {"Lightning Aura", 7, 16, C(130, 200, 255), C(255, 255, 255), "sparks"},
	Fire = {"Fire Aura", 12, 22, C(255, 120, 30), C(255, 220, 80), "flame"},
	Cursed = {"Cursed Aura", 20, 30, C(110, 30, 140), C(20, 10, 30), "swirl"},
	Golden = {"Golden Chakra Aura", 35, 39, C(255, 210, 60), C(255, 250, 200), "sparks"},
	Divine = {"Divine Chakra Aura", 60, 47, C(255, 245, 210), C(200, 160, 255), "petals"},
}
S.Auras = {} :: {[string]: Aura}
for _, id in S.AuraOrder do
	local d = auraData[id]
	S.Auras[id] = {Id = id, Name = d[1], Mult = d[2], Stage = d[3], Cost = Config.Stages[d[3]].Trophies * 60, Color = d[4], Color2 = d[5], Style = d[6]}
end

---------------------------------------------------------------- UPGRADES (Trophies)
export type Upgrade = {Id: string, Name: string, Desc: string, Base: number, Growth: number, Max: number}
S.UpgradeOrder = {"SignsPerClick", "JutsuDamage", "TrophyGain", "Cooldown", "PetBoost", "Offline", "PetSlots", "AutoTrain"}
S.Upgrades = {
	SignsPerClick = {Id = "SignsPerClick", Name = "Stronger Seals", Desc = "+1 base Hand Signs per click", Base = 20, Growth = 1.55, Max = 100},
	JutsuDamage = {Id = "JutsuDamage", Name = "Jutsu Power", Desc = "+20% damage for M1 and jutsu", Base = 40, Growth = 1.6, Max = 100},
	TrophyGain = {Id = "TrophyGain", Name = "Trophy Hunter", Desc = "+25% Trophies from everything", Base = 60, Growth = 1.7, Max = 60},
	Cooldown = {Id = "Cooldown", Name = "Quick Hands", Desc = "-4% jutsu cooldowns (max -40%)", Base = 100, Growth = 2.2, Max = 10},
	PetBoost = {Id = "PetBoost", Name = "Pet Trainer", Desc = "+10% pet multiplier", Base = 150, Growth = 1.8, Max = 50},
	Offline = {Id = "Offline", Name = "Shadow Training", Desc = "+25% offline earnings, +1h max", Base = 120, Growth = 2.0, Max = 8},
	PetSlots = {Id = "PetSlots", Name = "Pet Slot", Desc = "+1 pet equip slot", Base = 250, Growth = 4, Max = 3},
	AutoTrain = {Id = "AutoTrain", Name = "Auto Train", Desc = "Trains 2x per second for you", Base = 1500, Growth = 1, Max = 1},
}
function S.UpgradeCost(id: string, level: number): number
	local u = S.Upgrades[id]
	return math.floor(u.Base * u.Growth ^ level)
end

---------------------------------------------------------------- REBIRTH
function S.RebirthCost(rebirths: number): number
	return math.floor(2500 * 7 ^ rebirths)
end
S.RebirthResets = {"HandSigns"} -- everything else (stages, signs, pets, auras, upgrades, trophies, purchases) is kept

---------------------------------------------------------------- OFFLINE
S.OfflineTrainsPerSecond = 0.15
S.OfflineBaseMaxHours = 4

---------------------------------------------------------------- REWARDS
S.DailyCooldown = 20 * 3600
S.DailyStreakReset = 48 * 3600
function S.DailyReward(streak: number, highest: number): number
	return math.floor(Config.Stages[highest].Trophies * (10 + 5 * math.min(streak, 7)))
end
S.PlaytimeRewards = {{Minutes = 5, Mult = 8}, {Minutes = 15, Mult = 15}, {Minutes = 30, Mult = 30}, {Minutes = 60, Mult = 60}}
S.MilestoneStages = {5, 10, 15, 20, 25, 30, 35, 40, 45, 50}

-- Redeemable codes. Add real codes here when you announce them (no active codes are invented).
-- format: CODE = {Trophies = n, Expires = os.time() or 0}
S.Codes = {} :: {[string]: {Trophies: number, Expires: number}}

---------------------------------------------------------------- MONETISATION (set real ids from the Creator Dashboard; 0 = disabled)
S.GamePasses = {
	DoubleSigns = {Name = "2x Hand Signs", Id = 0},
	DoubleTrophies = {Name = "2x Trophies", Id = 0},
	ExtraPets = {Name = "+3 Pet Slots", Id = 0},
	VIP = {Name = "VIP (+25% everything)", Id = 0},
	AutoClicker = {Name = "OP Auto Clicker (5 trains/sec)", Id = 0},
	DoubleWinPad = {Name = "x2 Win Pad", Id = 0},
	ZoneGoldenDojo = {Name = "Golden Dojo (x8 zone)", Id = 0},
	ZoneThunderDome = {Name = "Thunder Dome (x25 zone)", Id = 0},
	ZoneDragonGate = {Name = "Dragon Gate (x50 zone)", Id = 0},
	ZoneSageThrone = {Name = "Sage Throne (x250 zone)", Id = 0},
}
S.DevProducts = {
	Boost15 = {Name = "2x Hand Signs (15 min)", Id = 0},
	PackSmall = {Name = "Hand Sign Pack S", Id = 0, Clicks = 500},
	PackMedium = {Name = "Hand Sign Pack M", Id = 0, Clicks = 3000},
	PackLarge = {Name = "Hand Sign Pack L", Id = 0, Clicks = 15000},
}
-- free auto clicker: runs for ActiveSeconds, then needs CooldownSeconds before it can be claimed again
S.FreeAuto = {ActiveSeconds = 180, CooldownSeconds = 420, TrainsPerSecond = 2}
S.OPAutoTrainsPerSecond = 5

-- Lobby training stations (issue #14). Structure mirrors +1 Anime Eyes' World 1 field: 13 zones, 9 won with
-- Rebirths, 4 Robux pass zones. Standing inside a zone multiplies training (GameService.StationMultiplier).
-- Theme = a model in ServerStorage.LobbyAssets.Stations, else a part build in LobbyBuilder.
-- PROPOSED DEFAULTS — owner to balance. Pass zones stay locked until real game passes exist (Id = 0 => "not available").
S.TrainingStations = {
	{Name = "Training Dummies", Mult = 2, Rebirths = 0, Theme = "Dummy", Color = C(120, 255, 130)},
	{Name = "Boxing Ring", Mult = 3, Rebirths = 2, Theme = "shrine", Color = C(255, 214, 90)},
	{Name = "Chakra Pool", Mult = 5, Rebirths = 6, Theme = "ChakraCircle", Color = C(90, 220, 255)},
	{Name = "Fire Forge", Mult = 7, Rebirths = 12, Theme = "furnace", Color = C(255, 150, 60)},
	{Name = "Golden Dojo", Mult = 8, Pass = "ZoneGoldenDojo", Robux = 99, Theme = "Dojo", Color = C(255, 210, 60)},
	{Name = "Scroll Temple", Mult = 10, Rebirths = 20, Theme = "ScrollAltar", Color = C(255, 200, 80)},
	{Name = "Storm Pagoda", Mult = 12, Rebirths = 28, Theme = "tower", Color = C(120, 200, 255)},
	{Name = "Gravity Seal", Mult = 20, Rebirths = 36, Theme = "portal", Color = C(190, 110, 255)},
	{Name = "Thunder Dome", Mult = 25, Pass = "ZoneThunderDome", Robux = 299, Theme = "dome", Color = C(140, 220, 255)},
	{Name = "Crimson Altar", Mult = 35, Rebirths = 44, Theme = "orb", Color = C(255, 80, 100)},
	{Name = "Void Totem", Mult = 40, Rebirths = 56, Theme = "Totem", Color = C(170, 120, 255)},
	{Name = "Dragon Gate", Mult = 50, Pass = "ZoneDragonGate", Robux = 699, Theme = "ToriiArch", Color = C(255, 120, 120)},
	{Name = "Sage Throne", Mult = 250, Pass = "ZoneSageThrone", Robux = 1800, Theme = "beam", Color = C(200, 120, 255)},
}
-- issue #13 guard: lobby-hub systems (Boss Shop / Fuse) are NOT built yet. These are
-- empty STUBS so SystemsService handlers fail safely instead of erroring. Filled in by the lobby issue.
S.BossShop = S.BossShop or {}
S.FuseTiers = S.FuseTiers or {}
S.FuseCount = S.FuseCount or 3
S.ShopOnlyAuras = S.ShopOnlyAuras or {}

return S
