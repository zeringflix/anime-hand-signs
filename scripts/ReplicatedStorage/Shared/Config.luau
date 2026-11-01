--!strict
-- +1 ANIME HAND SIGNS - shared, data-driven configuration (single source of truth for client + server)
local Config = {}

---------------------------------------------------------------- ECONOMY
Config.Economy = {
	MaxTrainsPerSecond = 12,      -- server tap cap (LihFolk: cap taps per second on the server)
	BaseGain = 1,
	BasicDamageBase = 10,
	DamagePerPower = 0.5,         -- damage = (Base + Power*k) * level bonus * upgrades
	LevelDamageBonus = 0.02,
	HitsPerEnemyAtRecommended = 8,
	BossHpMult = 6,
	EliteHpMult = 2.5,
	KillsToClear = 5,             -- "5 LEFT" counter
	OfflineRatePerMinute = 0.5,   -- fraction of 1 train/sec equivalent
	OfflineMaxMinutes = 8 * 60,
}

function Config.XPForLevel(level: number): number
	return math.floor(5 + level * 1.4 + level ^ 1.6)
end

---------------------------------------------------------------- JUTSU (28)
-- kind decides the server mechanic; vfx decides the client effect. Every pair on a sign differs in kind.
export type Jutsu = {Id: string, Name: string, Short: string, Kind: string, Vfx: string, DamageMult: number, Cooldown: number,
	Range: number, Radius: number?, Speed: number?, Count: number?, Duration: number?, Color: Color3, Color2: Color3, Desc: string}
local function J(t) return t end
local C = Color3.fromRGB
Config.Jutsu = {
	Fireball = J{Name="Fire Style: Fireball Jutsu", Short="FIREBALL", Kind="projectile", Vfx="fireball", DamageMult=3, Cooldown=3, Range=70, Radius=6, Speed=90, Color=C(255,140,30), Color2=C(255,60,20), Desc="Launch a blazing fireball at the target."},
	PhoenixFlower = J{Name="Fire Style: Phoenix Flower Jutsu", Short="PHOENIX FLOWERS", Kind="multiprojectile", Vfx="phoenix", DamageMult=1.4, Count=6, Cooldown=6, Range=65, Radius=4, Speed=80, Color=C(255,110,40), Color2=C(255,200,60), Desc="Fire a spread of small homing flames."},
	Rasengan = J{Name="Rasengan", Short="RASENGAN", Kind="dash", Vfx="rasengan", DamageMult=5, Cooldown=5, Range=35, Radius=8, Color=C(80,170,255), Color2=C(220,245,255), Desc="Charge a spinning chakra sphere and slam it into the target."},
	ShadowClone = J{Name="Shadow Clone Jutsu", Short="SHADOW CLONE", Kind="clones", Vfx="clones", DamageMult=1, Count=2, Duration=8, Cooldown=12, Range=60, Color=C(240,240,240), Color2=C(120,180,255), Desc="Summon 2 clones that fight beside you."},
	SnakeHands = J{Name="Hidden Shadow Snake Hands", Short="SNAKE HANDS", Kind="beam", Vfx="snakes", DamageMult=4, Cooldown=4, Range=40, Radius=4, Color=C(120,80,160), Color2=C(60,40,80), Desc="Snakes lash out from your sleeves in a line."},
	StrikingSnakes = J{Name="Striking Shadow Snakes", Short="STRIKING SNAKES", Kind="cone", Vfx="snakes", DamageMult=3.5, Count=4, Cooldown=8, Range=35, Radius=60, Color=C(140,90,190), Color2=C(80,200,120), Desc="Several snakes strike every enemy in front of you."},
	ShadowImitation = J{Name="Shadow Imitation Technique", Short="SHADOW BIND", Kind="root", Vfx="shadow", DamageMult=1.5, Duration=3, Cooldown=7, Range=45, Color=C(25,25,30), Color2=C(90,60,140), Desc="Your shadow binds the target, freezing it."},
	ShadowStrangle = J{Name="Shadow Strangle Technique", Short="SHADOW STRANGLE", Kind="execute", Vfx="shadowhands", DamageMult=7, Cooldown=10, Range=45, Color=C(20,20,25), Color2=C(140,90,220), Desc="Crush the target. Double damage on bound enemies."},
	Chidori = J{Name="Chidori", Short="CHIDORI", Kind="dash", Vfx="chidori", DamageMult=6, Cooldown=5, Range=40, Radius=7, Color=C(120,200,255), Color2=C(255,255,255), Desc="Lightning gathers in your hand as you lunge."},
	ChidoriStream = J{Name="Chidori Stream", Short="CHIDORI STREAM", Kind="aoe", Vfx="lightningburst", DamageMult=4, Cooldown=8, Range=0, Radius=22, Color=C(140,210,255), Color2=C(255,255,255), Desc="Release a radial burst of lightning around you."},
	Substitution = J{Name="Substitution Jutsu", Short="SUBSTITUTION", Kind="evade", Vfx="log", DamageMult=3, Duration=2.5, Cooldown=9, Range=18, Color=C(150,100,60), Color2=C(240,240,240), Desc="Become untouchable, leave a log and counter-strike."},
	BodyFlicker = J{Name="Body Flicker Technique", Short="BODY FLICKER", Kind="blink", Vfx="flicker", DamageMult=4.5, Cooldown=5, Range=60, Color=C(200,230,255), Color2=C(255,255,255), Desc="Flash to the target and strike instantly."},
	DragonFlame = J{Name="Fire Style: Dragon Flame Jutsu", Short="DRAGON FLAME", Kind="beam", Vfx="flamebeam", DamageMult=6, Cooldown=5, Range=60, Radius=6, Color=C(255,120,20), Color2=C(255,230,90), Desc="Breathe a long dragon of flame in a line."},
	MajesticFlame = J{Name="Fire Style: Majestic Destroyer Flame", Short="MAJESTIC FLAME", Kind="cone", Vfx="flamewave", DamageMult=7, Cooldown=11, Range=55, Radius=80, Color=C(255,90,10), Color2=C(255,200,50), Desc="A vast wall of fire scorches everything ahead."},
	Summoning = J{Name="Summoning Jutsu", Short="SUMMONING", Kind="summon", Vfx="summon", DamageMult=3, Duration=10, Cooldown=15, Range=60, Color=C(255,170,60), Color2=C(255,255,255), Desc="Summon a giant toad that slams enemies."},
	EarthWall = J{Name="Earth Style: Earth Wall", Short="EARTH WALL", Kind="wall", Vfx="earthwall", DamageMult=2.5, Duration=6, Cooldown=10, Range=12, Radius=14, Color=C(140,100,60), Color2=C(90,70,50), Desc="Raise a stone wall that blocks and knocks back."},
	WaterWall = J{Name="Water Style: Water Wall", Short="WATER WALL", Kind="shield", Vfx="waterwall", DamageMult=2, Duration=5, Cooldown=10, Range=0, Radius=14, Color=C(60,160,255), Color2=C(200,240,255), Desc="A spinning water barrier blocks damage and pushes enemies."},
	WaterDragon = J{Name="Water Style: Water Dragon Jutsu", Short="WATER DRAGON", Kind="piercing", Vfx="waterdragon", DamageMult=7, Cooldown=9, Range=80, Radius=9, Speed=70, Color=C(40,140,255), Color2=C(210,245,255), Desc="A water dragon tears through every enemy in its path."},
	GreatBreakthrough = J{Name="Wind Style: Great Breakthrough", Short="BREAKTHROUGH", Kind="cone", Vfx="gust", DamageMult=5, Cooldown=5, Range=45, Radius=70, Color=C(200,255,230), Color2=C(255,255,255), Desc="A huge gust damages and blasts enemies away."},
	Rasenshuriken = J{Name="Wind Style: Rasenshuriken", Short="RASENSHURIKEN", Kind="bigprojectile", Vfx="rasenshuriken", DamageMult=14, Cooldown=14, Range=90, Radius=20, Speed=65, Color=C(160,230,255), Color2=C(255,255,255), Desc="Throw a screaming wind shuriken that detonates in a huge sphere."},
	MultiShadowClone = J{Name="Multi Shadow Clone Jutsu", Short="MULTI CLONE", Kind="clones", Vfx="clones", DamageMult=1.3, Count=5, Duration=9, Cooldown=16, Range=60, Color=C(255,255,255), Color2=C(255,180,60), Desc="Five clones swarm and pummel enemies together."},
	ChidoriSenbon = J{Name="Chidori Senbon", Short="CHIDORI SENBON", Kind="multiprojectile", Vfx="senbon", DamageMult=2.2, Count=10, Cooldown=7, Range=70, Radius=3, Speed=160, Color=C(150,220,255), Color2=C(255,255,255), Desc="Fire a volley of lightning needles."},
	GiantRasengan = J{Name="Giant Rasengan", Short="GIANT RASENGAN", Kind="slam", Vfx="giantrasengan", DamageMult=16, Cooldown=12, Range=40, Radius=22, Color=C(60,150,255), Color2=C(230,250,255), Desc="Leap and crush the area with a colossal Rasengan."},
	Kirin = J{Name="Kirin", Short="KIRIN", Kind="strike", Vfx="kirin", DamageMult=26, Cooldown=20, Range=70, Radius=26, Duration=1.6, Color=C(180,220,255), Color2=C(255,255,255), Desc="Call a lightning beast down from the storm. Huge area."},
	Amaterasu = J{Name="Amaterasu", Short="AMATERASU", Kind="dot", Vfx="blackflame", DamageMult=3, Duration=6, Cooldown=10, Range=60, Radius=10, Color=C(15,10,20), Color2=C(170,30,60), Desc="Black flames that burn targets near the focus for 6s."},
	Susanoo = J{Name="Susanoo", Short="SUSANOO", Kind="transform", Vfx="susanoo", DamageMult=6, Duration=10, Cooldown=30, Range=30, Radius=18, Color=C(150,60,255), Color2=C(230,180,255), Desc="Become a towering chakra warrior: -70% damage taken, sword swings."},
	PlanetaryDevastation = J{Name="Planetary Devastation", Short="PLANETARY DEV.", Kind="pull", Vfx="planetary", DamageMult=20, Duration=3, Cooldown=22, Range=60, Radius=35, Color=C(120,90,70), Color2=C(200,120,255), Desc="A gravity core drags enemies in and crushes them."},
	TailedBeastBomb = J{Name="Tailed Beast Bomb", Short="BEAST BOMB", Kind="bigprojectile", Vfx="beastbomb", DamageMult=40, Cooldown=28, Range=100, Radius=32, Speed=55, Color=C(40,0,60), Color2=C(255,80,200), Desc="Compress a massive chakra bomb and fire it. Devastating."},
}
for id, j in Config.Jutsu do (j :: any).Id = id end

---------------------------------------------------------------- HAND SIGNS (14)
export type HandSign = {Id: string, Name: string, Order: number, Multiplier: number, Stage: number, Power: number, E: string, R: string, Color: Color3, Pose: string}
Config.HandSignOrder = {"Tiger","Ram","Snake","Rat","Ox","Hare","Horse","Boar","Dog","Bird","Monkey","Dragon","Advanced","Forbidden"}
local signData = {
	Tiger={"Tiger",1,1,"Fireball","PhoenixFlower",C(255,120,40),"tiger"},
	Ram={"Ram",3,4,"Rasengan","ShadowClone",C(80,170,255),"ram"},
	Snake={"Snake",8,7,"SnakeHands","StrikingSnakes",C(140,90,190),"snake"},
	Rat={"Rat",20,10,"ShadowImitation","ShadowStrangle",C(70,60,90),"rat"},
	Ox={"Ox",50,14,"Chidori","ChidoriStream",C(120,200,255),"ox"},
	Hare={"Hare",120,18,"Substitution","BodyFlicker",C(230,230,240),"hare"},
	Horse={"Horse",300,22,"DragonFlame","MajesticFlame",C(255,90,20),"horse"},
	Boar={"Boar",800,26,"Summoning","EarthWall",C(160,110,60),"boar"},
	Dog={"Dog",2000,30,"WaterWall","WaterDragon",C(40,140,255),"dog"},
	Bird={"Bird",5000,34,"GreatBreakthrough","Rasenshuriken",C(170,240,220),"bird"},
	Monkey={"Monkey",12000,38,"MultiShadowClone","ChidoriSenbon",C(255,190,70),"monkey"},
	Dragon={"Dragon",30000,42,"GiantRasengan","Kirin",C(60,150,255),"dragon"},
	Advanced={"Advanced Hand Seal Combination",80000,46,"Amaterasu","Susanoo",C(170,40,90),"advanced"},
	Forbidden={"Forbidden Hand Seal Mastery",250000,50,"PlanetaryDevastation","TailedBeastBomb",C(200,100,255),"forbidden"},
}
Config.HandSigns = {} :: {[string]: HandSign}

---------------------------------------------------------------- STAGES (50)
-- {name, {enemies x3}, boss, ground, path, cliff, leaf, trunk, gateColor, prop, element, sky}
local S = {
	{"Leaf Grove",{"Leaf Genin","Leaf Scout","Academy Ninja"},"Academy Captain",C(75,190,70),C(205,205,195),C(90,160,70),C(60,170,60),C(110,75,45),C(230,40,90),"pine","leaf"},
	{"Cherry Blossom Hill",{"Blossom Ronin","Sakura Spirit","Blossom Guard"},"Sakura Commander",C(110,200,90),C(235,200,215),C(200,140,170),C(255,170,205),C(80,55,50),C(240,60,140),"blossom","wind"},
	{"Sand Dunes",{"Sand Genin","Desert Scout","Sandblade Ninja"},"Sandblade Captain",C(230,200,130),C(240,220,170),C(205,170,105),C(120,170,80),C(150,120,70),C(255,160,40),"cactus","earth"},
	{"Red Canyon",{"Canyon Rogue","Red Stone Ninja","Canyon Berserker"},"Canyon Warlord",C(200,95,60),C(225,150,110),C(165,70,45),C(190,120,60),C(100,60,40),C(240,80,40),"rock","earth"},
	{"Bamboo Sanctuary",{"Bamboo Assassin","Bamboo Monk","Forest Sentinel"},"Bamboo Guardian",C(90,175,80),C(190,160,120),C(110,130,90),C(150,210,70),C(120,170,60),C(60,200,120),"bamboo","leaf"},
	{"Misty Marsh",{"Mist Ninja","Water Scout","Marsh Assassin"},"Mist Commander",C(95,150,110),C(150,170,160),C(80,110,95),C(90,140,100),C(80,70,55),C(80,170,220),"reed","water"},
	{"Stone Valley",{"Stone Genin","Earth Guard","Rock Shinobi"},"Stone Guardian",C(140,150,120),C(175,170,160),C(120,115,110),C(100,140,80),C(110,90,70),C(170,140,100),"boulder","earth"},
	{"Frozen Pass",{"Frost Ninja","Ice Scout","Frozen Guardian"},"Frost Commander",C(225,240,250),C(190,220,240),C(160,200,230),C(200,235,250),C(110,100,100),C(110,200,255),"icespike","ice"},
	{"Storm Peak",{"Lightning Ninja","Thunder Assassin","Storm Guard"},"Thunder Captain",C(110,120,150),C(160,165,185),C(85,90,115),C(90,110,170),C(70,70,90),C(255,230,60),"rod","lightning"},
	{"Lava Crater",{"Flame Ninja","Magma Guardian","Inferno Shinobi"},"Inferno Commander",C(70,55,55),C(120,80,70),C(55,40,40),C(255,110,30),C(40,30,30),C(255,90,20),"lavarock","fire"},
	{"Spirit Forest",{"Spirit Ninja","Cursed Ronin","Phantom Assassin"},"Forest Curse Master",C(60,120,90),C(120,150,140),C(50,90,75),C(100,220,180),C(60,50,70),C(120,255,200),"spirittree","spirit"},
	{"Moonlit Ruins",{"Ruin Guardian","Shadow Shinobi","Ancient Monk"},"Ancient Jutsu Master",C(90,110,150),C(150,160,190),C(100,105,130),C(120,130,200),C(70,70,90),C(150,170,255),"pillar","moon"},
	{"Poison Swamp",{"Venom Shinobi","Toxic Hunter","Swamp Guardian"},"Poison Sovereign",C(90,120,60),C(130,140,90),C(70,85,50),C(150,200,40),C(70,60,40),C(160,255,40),"mushroom","poison"},
	{"Haunted Graveyard",{"Grave Ronin","Spectral Ninja","Dark Spirit"},"Graveyard Warden",C(80,90,95),C(130,130,140),C(70,70,80),C(110,90,140),C(55,50,60),C(170,120,255),"grave","spirit"},
	{"Forbidden Shrine",{"Shrine Guard","Seal Master","Cursed Monk"},"Forbidden Shrine Master",C(120,70,120),C(200,170,190),C(100,60,100),C(200,80,160),C(80,40,60),C(255,60,160),"torii","spirit"},
	{"Samurai Village",{"Samurai Trainee","Blade Ronin","Elite Swordsman"},"Samurai General",C(110,175,80),C(210,190,150),C(150,120,90),C(80,160,70),C(110,75,45),C(220,50,50),"house","steel"},
	{"Iron Fortress",{"Armored Ninja","Iron Guard","Fortress Captain"},"Iron Warlord",C(130,135,140),C(170,170,175),C(100,105,110),C(120,140,90),C(80,80,85),C(200,200,210),"wall","steel"},
	{"Shadow Dojo",{"Shadow Student","Silent Assassin","Dojo Master"},"Shadow Sensei",C(150,110,70),C(190,150,100),C(90,60,45),C(60,60,70),C(70,45,30),C(120,90,200),"dojo","shadow"},
	{"Crimson Battlefield",{"Crimson Shinobi","War Ninja","Elite Fighter"},"Crimson Commander",C(150,70,60),C(190,120,100),C(120,50,45),C(200,60,50),C(80,40,35),C(255,40,40),"banner","fire"},
	{"Ancient Castle",{"Castle Guard","War Monk","Royal Shinobi"},"Castle Shogun",C(100,160,90),C(200,195,185),C(170,165,160),C(90,150,80),C(100,70,45),C(255,200,60),"castle","steel"},
	{"Thunder Forest",{"Thunder Scout","Lightning Hunter","Storm Ninja"},"Thunder Beast",C(70,110,100),C(140,150,160),C(60,80,90),C(80,200,230),C(50,50,70),C(255,240,80),"pine","lightning"},
	{"Inferno Temple",{"Flame Disciple","Fire Guardian","Inferno Monk"},"Flame Master",C(150,60,40),C(210,120,70),C(120,40,30),C(255,140,40),C(60,30,25),C(255,120,0),"temple","fire"},
	{"Tidal Sanctuary",{"Water Disciple","Tidal Ninja","Ocean Guardian"},"Water Dragon Guardian",C(90,190,200),C(220,230,210),C(70,150,170),C(60,200,180),C(120,100,80),C(40,150,255),"coral","water"},
	{"Wind Canyon",{"Wind Assassin","Air Shinobi","Gale Guardian"},"Tempest Commander",C(190,200,150),C(230,225,200),C(170,160,120),C(170,230,200),C(130,110,80),C(160,255,220),"windmill","wind"},
	{"Crystal Cavern",{"Crystal Scout","Crystal Warrior","Crystal Guardian"},"Crystal Overlord",C(80,70,120),C(130,120,170),C(60,55,95),C(200,120,255),C(50,45,70),C(220,140,255),"crystal","crystal"},
	{"Summoning Grounds",{"Summoner Ninja","Beast Handler","Summoning Guard"},"Summoning Master",C(120,170,90),C(220,200,160),C(140,120,90),C(110,180,80),C(110,75,45),C(255,170,60),"scroll","earth"},
	{"Serpent Valley",{"Snake Ninja","Venom Warrior","Serpent Guardian"},"Serpent Sage",C(110,140,80),C(170,160,130),C(90,100,70),C(130,170,60),C(80,70,50),C(150,90,220),"snakestatue","poison"},
	{"Toad Mountain",{"Mountain Ninja","Toad Disciple","Sage Warrior"},"Toad Sage Guardian",C(100,180,110),C(200,190,150),C(110,140,100),C(80,190,110),C(110,80,50),C(255,140,40),"toadstatue","water"},
	{"Hidden Laboratory",{"Experiment Ninja","Chakra Subject","Forbidden Guard"},"Forbidden Scientist",C(160,170,180),C(200,210,215),C(110,120,130),C(90,230,200),C(80,90,100),C(60,255,200),"tank","chakra"},
	{"Sage Sanctuary",{"Sage Disciple","Nature Warrior","Sage Guardian"},"Ancient Sage",C(100,190,90),C(220,210,170),C(120,160,90),C(250,200,80),C(110,80,50),C(255,200,60),"bigtree","nature"},
	{"War-Torn Village",{"War Ninja","Battle Captain","Elite Shinobi"},"War General",C(130,120,90),C(170,155,130),C(100,90,75),C(110,120,70),C(80,60,45),C(220,120,40),"ruinhouse","fire"},
	{"Hidden Hideout",{"Cloaked Rogue","Dark Jutsu User","Elite Outlaw"},"Shadow Organization Leader",C(60,55,65),C(110,100,110),C(50,45,55),C(170,40,50),C(40,35,40),C(220,30,50),"cloud","shadow"},
	{"Lightning Citadel",{"Lightning Guard","Storm Warrior","Thunder Elite"},"Thunder Kage",C(200,200,120),C(230,230,190),C(160,150,90),C(255,240,90),C(120,110,70),C(255,230,40),"rod","lightning"},
	{"Wind Temple",{"Wind Disciple","Gale Shinobi","Tempest Guardian"},"Wind Master",C(150,210,170),C(220,240,220),C(120,170,140),C(180,255,220),C(100,120,90),C(120,255,200),"temple","wind"},
	{"Tailed Beast Valley",{"Beast Guardian","Chakra Warrior","Tailed Beast Disciple"},"Beast Chakra Guardian",C(180,110,60),C(220,170,120),C(150,80,50),C(255,140,40),C(90,55,35),C(255,110,30),"rock","chakra"},
	{"Cloud Temple",{"Cloud Shinobi","Sky Guardian","Celestial Scout"},"Celestial Commander",C(230,240,255),C(250,250,255),C(200,215,240),C(255,255,255),C(180,180,200),C(140,200,255),"cloudpuff","wind"},
	{"Floating Islands",{"Floating Guard","Air Assassin","Sky Monk"},"Floating Island Master",C(120,210,110),C(220,230,210),C(150,120,90),C(120,220,110),C(110,80,50),C(120,220,255),"floatrock","wind"},
	{"Divine Waterfall",{"Divine Disciple","Water Spirit","Celestial Guardian"},"Divine Water Guardian",C(140,220,200),C(230,245,240),C(120,180,190),C(150,240,220),C(110,100,90),C(80,220,255),"waterfall","water"},
	{"Golden Summit",{"Golden Shinobi","Light Warrior","Summit Guardian"},"Golden Sage",C(240,210,110),C(255,240,190),C(210,170,80),C(255,220,80),C(150,110,50),C(255,210,40),"goldpillar","light"},
	{"Heavenly Gateway",{"Heaven Guard","Divine Fighter","Heavenly Sentinel"},"Heavenly Gatekeeper",C(245,245,255),C(255,250,230),C(220,220,240),C(255,240,200),C(200,180,140),C(255,230,150),"torii","light"},
	{"Void Rift",{"Void Ninja","Shadow Guardian","Rift Warrior"},"Void Master",C(55,35,80),C(90,60,120),C(40,25,60),C(150,60,255),C(30,20,45),C(170,60,255),"crack","void"},
	{"Six Paths Ruins",{"Chakra Guardian","Ancient Shinobi","Six Paths Warrior"},"Six Paths Guardian",C(150,130,170),C(200,190,210),C(110,95,130),C(230,200,255),C(80,70,90),C(220,180,255),"pillar","chakra"},
	{"Dark Moon Realm",{"Moon Assassin","Lunar Guardian","Dark Chakra Warrior"},"Lunar Sovereign",C(45,45,80),C(90,90,130),C(35,35,60),C(200,30,40),C(30,30,45),C(255,40,60),"moonrock","moon"},
	{"Celestial Battlefield",{"Celestial Soldier","Divine Monk","Chakra Champion"},"Celestial Warlord",C(90,80,140),C(170,160,210),C(70,60,110),C(255,220,120),C(60,50,80),C(255,200,90),"banner","light"},
	{"Dimension Nexus",{"Rift Guardian","Dimension Ninja","Cosmic Shinobi"},"Dimension Master",C(40,30,70),C(90,70,140),C(30,20,55),C(80,220,255),C(25,20,40),C(80,230,255),"floatrock","void"},
	{"Divine Forest",{"Divine Scout","Celestial Ninja","Golden Guardian"},"Divine Forest Master",C(150,220,120),C(250,240,200),C(140,170,110),C(255,230,120),C(150,110,60),C(255,230,100),"bigtree","light"},
	{"Chakra Dimension",{"Chakra Entity","Energy Warrior","Dimension Guard"},"Chakra Overlord",C(60,80,140),C(120,150,220),C(50,60,110),C(90,200,255),C(40,50,80),C(90,200,255),"crystal","chakra"},
	{"Eternal Temple",{"Eternal Monk","Temple Sentinel","Divine Shinobi"},"Eternal Sage",C(230,220,200),C(250,245,235),C(200,190,170),C(255,200,100),C(150,120,80),C(255,190,80),"temple","light"},
	{"Godly Battlefield",{"Godly Guardian","Legendary Warrior","Celestial Champion"},"Supreme Shinobi",C(120,90,60),C(200,170,120),C(90,60,40),C(255,180,60),C(70,50,30),C(255,150,40),"goldpillar","chakra"},
	{"Divine Summit",{"Six Paths Guardian","Divine Shinobi","Celestial Master"},"Divine Chakra Master",C(250,240,210),C(255,250,240),C(220,200,150),C(255,230,140),C(170,140,90),C(255,215,90),"goldpillar","divine"},
}

export type Stage = {Index: number, Name: string, Region: number, Enemies: {string}, Boss: string, Ground: Color3, Path: Color3, Cliff: Color3,
	Leaf: Color3, Trunk: Color3, Gate: Color3, Prop: string, Element: string, Recommended: number, Trophies: number, EnemyHp: number, EnemyDamage: number, XP: number}
Config.StageCount = #S
Config.StageLength = 170
Config.Stages = {} :: {Stage}
Config.RegionNames = {"Beginner Shinobi Grounds","Elemental Wilderness","Cursed Lands","Warrior Territories","Elemental Mastery","Advanced Shinobi Realms","Legendary Battlegrounds","Celestial Path","Void and Six Paths","Final Divine Ascension"}

-- Recommended curve: 0, 60, 400, 2.5K then a slowly flattening growth ratio
local rec = {0, 60}
for s = 3, #S do
	local ratio = math.max(1.55, 6.667 * 0.91 ^ (s - 3))
	rec[s] = rec[s - 1] * ratio
end
local function roundNice(n: number): number
	if n < 100 then return math.floor(n + 0.5) end
	local p = 10 ^ (math.floor(math.log10(n)) - 1)
	return math.floor(n / p + 0.5) * p
end

function Config.DamageForPower(power: number, level: number, dmgUpgrade: number): number
	local e = Config.Economy
	return (e.BasicDamageBase + power * e.DamagePerPower) * (1 + (level - 1) * e.LevelDamageBonus) * dmgUpgrade
end

for i, d in S do
	local r = roundNice(rec[i])
	local hp = Config.DamageForPower(math.max(r, 5), 1, 1) * Config.Economy.HitsPerEnemyAtRecommended
	Config.Stages[i] = {
		Index = i, Name = d[1], Region = math.ceil(i / 5), Enemies = d[2], Boss = d[3],
		Ground = d[4], Path = d[5], Cliff = d[6], Leaf = d[7], Trunk = d[8], Gate = d[9], Prop = d[10], Element = d[11],
		Recommended = r,
		Trophies = roundNice(3 * 1.55 ^ (i - 1)),
		EnemyHp = hp,
		EnemyDamage = 4 + i * 2,
		XP = math.floor(2 + i * 1.5),
	}
end

for id, d in signData do
	local stage = d[3]
	Config.HandSigns[id] = {Id = id, Name = d[1], Order = table.find(Config.HandSignOrder, id) :: number, Multiplier = d[2],
		Stage = stage, Power = stage <= 1 and 0 or math.floor(Config.Stages[stage].Recommended * 0.5),
		E = d[4], R = d[5], Color = d[6], Pose = d[7]}
end

---------------------------------------------------------------- NUMBER FORMAT
local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "De", "UDe", "DDe", "TDe"}
function Config.Format(n: number): string
	if n ~= n then return "0" end
	if n < 1000 then return tostring(math.floor(n)) end
	local i = math.min(math.floor(math.log10(n) / 3), #suffixes - 1)
	local v = n / 10 ^ (i * 3)
	local s = v >= 100 and string.format("%d", v) or v >= 10 and string.format("%.1f", v) or string.format("%.2f", v)
	if s:find("%.") then s = s:gsub("0+$", ""):gsub("%.$", "") end
	return s .. suffixes[i + 1]
end

return Config
