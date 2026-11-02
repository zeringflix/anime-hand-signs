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
}
-- bevelled square studs (original texture, assets/textures/studs_square.png) for studded UI backgrounds
Assets.Studs = "rbxassetid://109401654557790"

-- jutsu VFX family -> icon
Assets.JutsuIcon = {
	fireball = "Fire", phoenix = "Fire", flamebeam = "Fire", flamewave = "Fire", rasengan = "Swirl", giantrasengan = "Swirl",
	clones = "Smoke", log = "Smoke", flicker = "Smoke", summon = "Smoke", snakes = "Snake", shadow = "Shadow", shadowhands = "Shadow",
	chidori = "Lightning", lightningburst = "Lightning", senbon = "Lightning", kirin = "Lightning", gust = "Wind", rasenshuriken = "Wind",
	earthwall = "Rock", waterwall = "Water", waterdragon = "Water", blackflame = "DarkFlame", susanoo = "Shield", planetary = "Planet", beastbomb = "Bomb",
}
function Assets.Icon(name: string?): string
	if name == "HandSign" then return Assets.SignIcons and Assets.SignIcons.Tiger or "" end -- our own hand art
	return (name and Assets.Icons[name]) or ""
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
return Assets
