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
export type Egg = {Id: string, Name: string, Stage: number, Cost: number, Color: Color3, Odds: {{Pet: string, Chance: number}}, Robux: number?, Product: string?}
-- LEGACY eggs: no longer sold (owner 2026-11-02 picked 4 eggs). Their pets stay defined so existing saves keep them.
local LEGACY_EGGS = {"Ninja", "Sakura", "Desert", "Forest"}
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
-- THE 4 LOBBY EGGS (owner 2026-11-02): models Celestial / Summoning / Lightning / Divine, shrunk ~20%.
-- Two cost Trophies (no stage gate); the two cool ones cost Robux (developer products, Id 0 = "not available yet").
-- New ninja-inspired ORIGINAL pets (no licensed characters). Boost is additive (1 + sum of equipped boosts).
local newEggPets = {
	Celestial = { -- Spirit Egg (kitsune-mask egg): starter pets
		{pet("LeafPup", "Leaf Ninja Pup", "Common", 0.12, "dog", C(240, 170, 90), C(40, 60, 120)), 50},
		{pet("KunaiCat", "Kunai Cat", "Uncommon", 0.25, "cat", C(60, 60, 75), C(230, 60, 60)), 30},
		{pet("MaskedKitsune", "Masked Kitsune", "Rare", 0.55, "fox", C(250, 250, 255), C(230, 50, 60)), 15},
		{pet("ScrollFox", "Scroll Fox", "Epic", 1.2, "fox", C(255, 150, 50), C(255, 230, 160)), 5},
	},
	Summoning = { -- Flame Egg (chained lava egg)
		{pet("EmberToad", "Ember Toad", "Uncommon", 1.5, "toad", C(255, 120, 50), C(120, 40, 20)), 50},
		{pet("ShurikenSerpent", "Shuriken Serpent", "Rare", 3, "serpent", C(80, 80, 100), C(255, 200, 60)), 30},
		{pet("FlameWolf", "Flame Wolf", "Epic", 6, "wolf", C(255, 90, 30), C(255, 220, 80)), 15},
		{pet("PhoenixHawk", "Phoenix Hawk", "Legendary", 15, "dragon", C(255, 110, 40), C(255, 240, 120)), 5},
	},
	Lightning = { -- Shadow Egg (Robux): purple dragon-scale egg
		{pet("ShadowKitsune", "Shadow Kitsune", "Epic", 10, "fox", C(60, 30, 90), C(200, 90, 255)), 50},
		{pet("StormHound", "Storm Hound", "Legendary", 22, "wolf", C(90, 130, 255), C(230, 240, 255)), 30},
		{pet("VoidSerpent", "Void Serpent", "Mythic", 45, "serpent", C(40, 20, 60), C(190, 90, 255)), 15},
		{pet("ThunderDragon", "Thunder Dragon", "Mythic", 100, "dragon", C(80, 90, 230), C(255, 240, 120)), 5},
	},
	Divine = { -- Mythic Egg (Robux): cracked crystal egg
		{pet("HaloFox", "Halo Fox", "Legendary", 30, "fox", C(255, 250, 235), C(255, 210, 90)), 45},
		{pet("SageToadKing", "Sage Toad King", "Mythic", 65, "toad", C(255, 170, 60), C(255, 240, 200)), 30},
		{pet("CelestialKirin", "Celestial Kirin", "Mythic", 140, "beast", C(200, 220, 255), C(255, 230, 140)), 20},
		{pet("SixTailSpirit", "Six-Tail Spirit", "Secret", 300, "fox", C(30, 20, 50), C(255, 120, 220)), 5},
	},
}
S.EggOrder = {"Celestial", "Summoning", "Lightning", "Divine"}
local EGG_INFO = {
	Celestial = {Name = "Spirit Egg", Cost = 50, Color = C(90, 170, 255)},
	Summoning = {Name = "Flame Egg", Cost = 2500, Color = C(255, 120, 40)},
	Lightning = {Name = "Shadow Egg", Robux = 79, Product = "EggShadow", Color = C(170, 80, 255)},
	Divine = {Name = "Mythic Egg", Robux = 149, Product = "EggMythic", Color = C(255, 220, 120)},
}
S.Eggs = {} :: {[string]: Egg}
for _, id in S.EggOrder do
	local info = EGG_INFO[id]
	local odds = {}
	for _, row in newEggPets[id] do table.insert(odds, {Pet = row[1], Chance = row[2]}) end
	S.Eggs[id] = {Id = id, Name = info.Name, Stage = 1, Cost = info.Cost or 0, Color = info.Color, Odds = odds, Robux = info.Robux, Product = info.Product}
end
local _ = LEGACY_EGGS; local __ = eggStages; local ___ = eggColors; local ____ = eggPets -- legacy pets above stay registered

-- ROBUX PETS (Store + lobby special pet). Rainbow name in the UI. Product Id 0 = not purchasable yet.
S.RobuxPets = {
	{Pet = pet("NineTailSpiritFox", "Nine-Tail Spirit Fox", "Secret", 99, "fox", C(255, 130, 40), C(255, 235, 200)), Product = "PetSpiritFox", Robux = 799, Special = true},
	{Pet = pet("ThunderKirinPup", "Thunder Kirin Pup", "Mythic", 25, "beast", C(120, 190, 255), C(255, 250, 160)), Product = "PetKirinPup", Robux = 199},
	{Pet = pet("SummitToadSage", "Summit Toad Sage", "Mythic", 50, "toad", C(110, 200, 90), C(255, 220, 120)), Product = "PetToadSage", Robux = 349},
}
-- daily reward pet (Day 7)
pet("SpiritDragon", "Spirit Dragon", "Legendary", 10, "dragon", C(120, 200, 255), C(255, 255, 255))
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
S.PlaytimeRewards = {{Minutes = 5, Mult = 8}, {Minutes = 15, Mult = 15}, {Minutes = 30, Mult = 30}, {Minutes = 60, Mult = 60}} -- legacy (replaced by Gifts)

-- DAILY REWARDS (7-day week, +1 Anime Eyes layout). Kind: Trophies (x stage trophies), Boost (x2 Hand Signs, minutes),
-- TrophyBoost (x2 Trophies, minutes), Aura (id), Hatch (egg id, count), Pet (pet id).
S.DailyWeek = {
	{Kind = "Trophies", Mult = 10},
	{Kind = "Boost", Minutes = 5},
	{Kind = "Aura", Aura = "Blue", Mult = 20},       -- falls back to Trophies x Mult if already owned
	{Kind = "Trophies", Mult = 30},
	{Kind = "Hatch", Egg = "Summoning", Count = 3},
	{Kind = "TrophyBoost", Minutes = 15},
	{Kind = "Pet", Pet = "SpiritDragon"},
}

-- FREE GIFTS (session timers; daily claim caps). Pools are weighted (%).
S.Gifts = {
	{Id = "g5", Title = "Every 5 Min", Minutes = 5, PerDay = 9, Color = C(70, 150, 240), Icon = "Gift", Pool = {
		{Kind = "Trophies", Mult = 6, Chance = 52}, {Kind = "Hatch", Egg = "Celestial", Count = 1, Chance = 25},
		{Kind = "Boost", Minutes = 1, Chance = 8}, {Kind = "Trophies", Mult = 18, Chance = 10}, {Kind = "Hatch", Egg = "Summoning", Count = 1, Chance = 5},
	}},
	{Id = "g15", Title = "Every 15 Min", Minutes = 15, PerDay = 4, Color = C(170, 90, 240), Icon = "GiftBlue", Pool = {
		{Kind = "Trophies", Mult = 25, Chance = 45}, {Kind = "Hatch", Egg = "Celestial", Count = 3, Chance = 20}, {Kind = "Boost", Minutes = 3, Chance = 10},
		{Kind = "TrophyBoost", Minutes = 5, Chance = 15}, {Kind = "Hatch", Egg = "Summoning", Count = 1, Chance = 8}, {Kind = "Trophies", Mult = 90, Chance = 2},
	}},
	{Id = "g60", Title = "Every 60 Min", Minutes = 60, PerDay = 1, Color = C(250, 190, 60), Icon = "Chest", Pool = {
		{Kind = "Trophies", Mult = 110, Chance = 47}, {Kind = "Hatch", Egg = "Summoning", Count = 3, Chance = 25}, {Kind = "Boost", Minutes = 8, Chance = 13},
		{Kind = "TrophyBoost", Minutes = 15, Chance = 12}, {Kind = "Trophies", Mult = 500, Chance = 3},
	}},
}
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
	-- Robux eggs / pets / daily skip (owner 2026-11-02). Id 0 until the owner creates the products.
	EggShadow = {Name = "Shadow Egg (1 hatch)", Id = 0, Egg = "Lightning"},
	EggMythic = {Name = "Mythic Egg (1 hatch)", Id = 0, Egg = "Divine"},
	PetSpiritFox = {Name = "Nine-Tail Spirit Fox", Id = 0, Pet = "NineTailSpiritFox"},
	PetKirinPup = {Name = "Thunder Kirin Pup", Id = 0, Pet = "ThunderKirinPup"},
	PetToadSage = {Name = "Summit Toad Sage", Id = 0, Pet = "SummitToadSage"},
	DailyUnlockAll = {Name = "Unlock all Daily Rewards", Id = 0, Robux = 149, UnlockDaily = true},
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
