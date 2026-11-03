-- Every rbxassetid lives here (never hard-code ids in screens).
-- UI ICONS: ONLY the owner's Free Icon Pack 3.0.1 (Basic) by @gvesster (commercial use allowed, credit appreciated).
-- Source PNGs: assets/icons/pack (uploaded 2026-11-02). No other icon sets are used (owner request).
local Assets = {}
Assets.Icons = {
	Aura = "rbxassetid://133655228042168", Bomb = "rbxassetid://118076514633538", Boost = "rbxassetid://126814216129031",
	Chakra = "rbxassetid://140299940878337", Check = "rbxassetid://122989641348123", Chest = "rbxassetid://72706008225408",
	Clock = "rbxassetid://103486030496420", Close = "rbxassetid://117020381281067", Codes = "rbxassetid://111572838026074",
	Coin = "rbxassetid://131897507961033", Crown = "rbxassetid://87832447992819", Daily = "rbxassetid://91658058721134",
	DarkFlame = "rbxassetid://126424497894441", Egg = "rbxassetid://123700898995377", Fire = "rbxassetid://112772703405496",
	Fist = "rbxassetid://75488138526832", Gift = "rbxassetid://111494651170442", GiftBlue = "rbxassetid://123450136038856",
	Invite = "rbxassetid://88648427753926", Lightning = "rbxassetid://83091418335168", Lock = "rbxassetid://77786018872659",
	Medal = "rbxassetid://117846169875284", Pets = "rbxassetid://86899680149157", Places = "rbxassetid://98459242155344",
	Planet = "rbxassetid://121851545198239", Quests = "rbxassetid://137751765249841", Rebirth = "rbxassetid://103485207632915",
	Robux = "rbxassetid://130059794162123", Rock = "rbxassetid://133709549186877", Scroll = "rbxassetid://107820965193945",
	Settings = "rbxassetid://92941581509528", Shadow = "rbxassetid://117645748471325", Shield = "rbxassetid://88978355932705",
	Shop = "rbxassetid://88983239096423", Skip = "rbxassetid://93884024038279", Smoke = "rbxassetid://125744660433050",
	Snake = "rbxassetid://102516173104883", Sound = "rbxassetid://121668571817893", Star = "rbxassetid://105659368355050",
	Swirl = "rbxassetid://91156024982116", Teleporter = "rbxassetid://91364695533432", Trophy = "rbxassetid://99656253443234",
	TrophyBoost = "rbxassetid://88173952251280", Upgrades = "rbxassetid://96972025988474", Water = "rbxassetid://135052561742581",
	Wind = "rbxassetid://122083388151864",
	-- added 2026-11-02 (owner: blue verified Codes icon, Settings revamp); same Free Icon Pack
	Verified = "rbxassetid://81595987767385", MusicOn = "rbxassetid://83674423258573", SoundOn = "rbxassetid://121668571817893",
	SoundOff = "rbxassetid://133728784822044", CheckButton = "rbxassetid://106347711186346",
}
-- bevelled square studs (original texture, assets/textures/studs_square.png) for studded UI backgrounds
Assets.Studs = "rbxassetid://118774955486499" -- owner stud texture (8x8 studs per sheet), white/black alpha overlay

-- jutsu VFX family -> icon
Assets.JutsuIcon = {
	fireball = "Fire", phoenix = "Fire", flamebeam = "Fire", flamewave = "Fire", rasengan = "Swirl", giantrasengan = "Swirl",
	clones = "Smoke", log = "Smoke", flicker = "Smoke", summon = "Smoke", snakes = "Snake", shadow = "Shadow", shadowhands = "Shadow",
	chidori = "Lightning", lightningburst = "Lightning", senbon = "Lightning", kirin = "Lightning", gust = "Wind", rasenshuriken = "Wind",
	earthwall = "Rock", waterwall = "Water", waterdragon = "Water", blackflame = "DarkFlame", susanoo = "Shield", planetary = "Planet", beastbomb = "Bomb",
}
-- owner 2026-11-03 "use the outlined logos": the SAME Free Icon Pack icons in their '1st Outline' variant (thick dark border).
-- Sources: assets/icons/pack_outline. Assets.Icon() prefers these; Assets.Icons keeps the plain versions.
Assets.IconsOutline = {
	Aura = "rbxassetid://117685047456280",
	Bomb = "rbxassetid://78900466591532",
	Boost = "rbxassetid://84437840093574",
	Chakra = "rbxassetid://130808355210760",
	Check = "rbxassetid://109709201147637",
	CheckButton = "rbxassetid://70538374365576",
	Chest = "rbxassetid://87901245047658",
	Clock = "rbxassetid://108275438988305",
	Close = "rbxassetid://87534519706404",
	Codes = "rbxassetid://94729247285884",
	Coin = "rbxassetid://71237867324669",
	Crown = "rbxassetid://81587435624968",
	Daily = "rbxassetid://125486475940003",
	DarkFlame = "rbxassetid://125528177641907",
	Egg = "rbxassetid://122249053640279",
	Fire = "rbxassetid://128236498507718",
	Fist = "rbxassetid://73296684157524",
	Gift = "rbxassetid://135518706814532",
	GiftBlue = "rbxassetid://90023304835235",
	Invite = "rbxassetid://84168204761745",
	Lightning = "rbxassetid://106434067357849",
	Lock = "rbxassetid://138252538883183",
	Medal = "rbxassetid://118619928174946",
	MusicOn = "rbxassetid://113126002762095",
	Pets = "rbxassetid://138064522385986",
	Places = "rbxassetid://116292673796346",
	Planet = "rbxassetid://115236931052571",
	Quests = "rbxassetid://70470113635541",
	Rebirth = "rbxassetid://140306784641183",
	Robux = "rbxassetid://138507121748140",
	Rock = "rbxassetid://114049573019291",
	Scroll = "rbxassetid://115116930227764",
	Settings = "rbxassetid://113519052228599",
	Shadow = "rbxassetid://97220228688173",
	Shield = "rbxassetid://117075398519377",
	Shop = "rbxassetid://93668277165991",
	Skip = "rbxassetid://77631203150300",
	Smoke = "rbxassetid://118602494464044",
	Snake = "rbxassetid://90780497717755",
	Sound = "rbxassetid://128560248221770",
	SoundOff = "rbxassetid://93991092938550",
	SoundOn = "rbxassetid://128560248221770",
	Star = "rbxassetid://70633382162377",
	Stats = "rbxassetid://74329087843732",
	Swirl = "rbxassetid://114475034524844",
	Teleporter = "rbxassetid://133216877590178",
	Trophy = "rbxassetid://127669762542069",
	TrophyBoost = "rbxassetid://80565613148637",
	Upgrades = "rbxassetid://77763779703828",
	Verified = "rbxassetid://80679546706033",
	Water = "rbxassetid://122484528701286",
	Wind = "rbxassetid://108469459484231",
}
function Assets.Icon(name: string?): string
	if name == "HandSign" then return Assets.SignIcons and Assets.SignIcons.Tiger or "" end -- our own hand art
	return (name and (Assets.IconsOutline[name] or Assets.Icons[name])) or ""
end
-- Hand-sign artwork: cartoon version (owner 2026-11-02 "more cartoonified"): the approved hands-only sheet run through
-- tools/cartoonify_hands.py (cel-shaded skin, navy ninja sleeves, thick outline) -> assets/icons/hand-signs-cartoon.
-- Pose mapping follows the traditional seals and is flagged for owner confirmation. Advanced + Forbidden have no
-- approved art yet: UI shows a "?" placeholder (do not substitute other poses).
Assets.SignIcons = {
	Tiger = "rbxassetid://131099870003725", Ram = "rbxassetid://79388527447103", Snake = "rbxassetid://95072143240584",
	Rat = "rbxassetid://115404407559286", Ox = "rbxassetid://101982626517900", Hare = "rbxassetid://98370343772443",
	Horse = "rbxassetid://73627783857913", Boar = "rbxassetid://112009649334919", Dog = "rbxassetid://130848249850652",
	Bird = "rbxassetid://104563382389792", Monkey = "rbxassetid://78682738981925", Dragon = "rbxassetid://117006185478056",
}

-- Training-station VFX textures: ORIGINAL, drawn with numpy (vfx/training/textures.py), uploaded 2026-11-02.
-- White shapes in alpha; emitter Color tints them. Map: vfx/training/asset_ids.json
Assets.FX = {
	Bolt = "rbxassetid://77440291120462",
	Column = "rbxassetid://109288698541393",
	Ember = "rbxassetid://98260290348533",
	Flame = "rbxassetid://128196827751321",
	Glint = "rbxassetid://110913753050498",
	Glow = "rbxassetid://112123228465402",
	Halo = "rbxassetid://91979392887827",
	Mist = "rbxassetid://123588300305744",
	Orb = "rbxassetid://87369425414757",
	Petal = "rbxassetid://91312796559442",
	Ring = "rbxassetid://101137204663510",
	Rune = "rbxassetid://89802798448788",
	Shard = "rbxassetid://73563628895087",
	Smoke = "rbxassetid://78579475702105",
	Swirl = "rbxassetid://98358801781376",
}
return Assets
