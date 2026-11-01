-- Every rbxassetid lives here (never hard-code ids in screens).
-- Icons: glossy outlined 256px renders from the Blender icon pipeline
--   (vault: "Anime Hand Signs/Icons" + reused Smack Your Friend Icons4/Icons3D).
local Assets = {}
Assets.Icons = {
	-- new for +1 Anime Hand Signs
	HandSign = "rbxassetid://79891497371203", Chakra = "rbxassetid://97649988791697", Aura = "rbxassetid://99730763315243",
	Fire = "rbxassetid://134606246547590", DarkFlame = "rbxassetid://130473214916303", Fist = "rbxassetid://119064037060181",
	Codes = "rbxassetid://76070319512008", Swirl = "rbxassetid://76328501279455", Lightning = "rbxassetid://82929103178200",
	Water = "rbxassetid://82664315436313", Wind = "rbxassetid://126210777092550", Rock = "rbxassetid://137771754503391",
	Snake = "rbxassetid://120527343127065", Shadow = "rbxassetid://103620768780561", Planet = "rbxassetid://138907703608603",
	Bomb = "rbxassetid://91612792432372", Smoke = "rbxassetid://109119497581894", Shield = "rbxassetid://74359657738556",
	-- reused icon pack
	Shop = "rbxassetid://134572268185203", Gift = "rbxassetid://139560439000652", Trophy = "rbxassetid://96122372126685",
	Settings = "rbxassetid://117814321078749", Rebirth = "rbxassetid://124542216784628", Upgrades = "rbxassetid://96963835385918",
	Egg = "rbxassetid://79448941527363", Places = "rbxassetid://106175154334874", Boost = "rbxassetid://107848138116833",
	Crown = "rbxassetid://124158386966282", Lock = "rbxassetid://99457675712972", Close = "rbxassetid://110808781571169",
}
-- Free Icon Pack 3.0.1 (Basic) by @gvesster (commercial use allowed; credit appreciated). Overrides the renders above.
for k, v in {
	Aura = "rbxassetid://133655228042168", Bomb = "rbxassetid://118076514633538", Boost = "rbxassetid://126814216129031",
	Chakra = "rbxassetid://140299940878337", Close = "rbxassetid://117020381281067", Codes = "rbxassetid://111572838026074",
	Crown = "rbxassetid://87832447992819", Daily = "rbxassetid://82359883898100", DarkFlame = "rbxassetid://130035763722794",
	Egg = "rbxassetid://123700898995377", Fire = "rbxassetid://112772703405496", Fist = "rbxassetid://78389783935764",
	Gift = "rbxassetid://111494651170442", HandSign = "rbxassetid://94207501179549", Lightning = "rbxassetid://83091418335168",
	Lock = "rbxassetid://70808669412763", Places = "rbxassetid://88782016731518", Planet = "rbxassetid://125248603124506",
	Rebirth = "rbxassetid://76999303385142", Scroll = "rbxassetid://137751765249841", Settings = "rbxassetid://92941581509528",
	Shadow = "rbxassetid://99975053239911", Shield = "rbxassetid://88978355932705", Shop = "rbxassetid://75003053486678",
	Smoke = "rbxassetid://122083388151864", Star = "rbxassetid://110617004172405", Swirl = "rbxassetid://123483705467280",
	Trophy = "rbxassetid://99552622956894", Upgrades = "rbxassetid://99380858469223", Wind = "rbxassetid://108438677330929",
} do Assets.Icons[k] = v end

-- jutsu VFX family -> icon
Assets.JutsuIcon = {
	fireball = "Fire", phoenix = "Fire", flamebeam = "Fire", flamewave = "Fire", rasengan = "Swirl", giantrasengan = "Swirl",
	clones = "Smoke", log = "Smoke", flicker = "Smoke", summon = "Smoke", snakes = "Snake", shadow = "Shadow", shadowhands = "Shadow",
	chidori = "Lightning", lightningburst = "Lightning", senbon = "Lightning", kirin = "Lightning", gust = "Wind", rasenshuriken = "Wind",
	earthwall = "Rock", waterwall = "Water", waterdragon = "Water", blackflame = "DarkFlame", susanoo = "Shield", planetary = "Planet", beastbomb = "Bomb",
}
function Assets.Icon(name: string?): string
	return (name and Assets.Icons[name]) or ""
end
return Assets
