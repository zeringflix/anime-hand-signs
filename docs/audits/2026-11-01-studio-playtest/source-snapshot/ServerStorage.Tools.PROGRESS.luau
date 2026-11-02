--[[ +1 ANIME HAND SIGNS - build checklist (read this first when continuing)
Status key: NOT STARTED / IN PROGRESS / IMPLEMENTED / TESTED / BLOCKED

WORLD
  50 connected stages (WorldBuilder, data from Shared.Config) ........ TESTED (stages 1,2,4/5,42,50 visited)
  Studded checker floors, terraced cliffs, walls, biome props ......... IMPLEMENTED
  Landmark per region, path lanterns, torii gates + tinted barrier ..... IMPLEMENTED
  Per-stage atmosphere / colour grade (client) ......................... IMPLEMENTED
  Rebuild: require(game.ServerStorage.Tools.WorldBuilder:Clone()).BuildAll()

CORE LOOP
  +1 training (batched, server-capped 12/s) ........................... TESTED
  Tiger auto-equipped, M1 + E Fireball + R Phoenix Flower .............. TESTED
  Enemy HP bars, 5 LEFT counter, gate opens per player ................ TESTED
  Trophy pad claim, Stage 2 unlock + Cherry Blossom roster ............. TESTED
  Ram unlock -> E Rasengan / R Shadow Clone, swap back to Tiger ........ TESTED
  Cooldowns survive sign swaps; unowned sign equip rejected ............ TESTED
  Final boss (stage 50): 3 phases, patterns, ultimate, knockback ....... TESTED (phases 2+3 seen)
  All 28 jutsu server mechanics + client VFX ........................... IMPLEMENTED (Fireball/Phoenix/Rasengan/Clones/Forbidden pair exercised)

SYSTEMS (SystemsService + Client.Menus)
  Pets: 8 eggs, 32 pets, odds shown, server rolls, equip/best/lock/delete  TESTED (hatch/equip)
  Auras x8, Upgrades x8, Rebirth, Offline gains, Daily/Playtime/Milestones IMPLEMENTED (aura+upgrade+rebirth-guard tested)
  Codes (table empty on purpose), Leaderboards (OrderedDataStore) ...... IMPLEMENTED
  Game passes / dev product (ids = 0 -> disabled until real ids set) ... IMPLEMENTED

DATA
  Session-locked saving, fenced writes, BindToClose ..................... IMPLEMENTED
  Persistence across sessions ........................................... BLOCKED: place not published, so no DataStore in Studio.
     -> Publish the place, enable Game Settings > Security > Studio Access to API Services, then retest.

HUD (Client.HUD + Client.Main) restyled to the +1 reference layout ............ TESTED
  Free Auto Clicker (3 min on / 7 min recharge, 2 trains/s) ........... TESTED
  OP Auto Clicker pass + 3 Hand Sign packs (dev products) ............. IMPLEMENTED, disabled until real ids set

ART PASS
  30 glossy outlined icons (Blender, vault: Anime Hand Signs/Icons) uploaded -> Shared.Assets ... TESTED (HUD)
  Blender kit AHSKit.fbx: StoneLantern, PostLantern, TrophyStatue -> ServerStorage.Tools.Kit .. TESTED (all 50 stages)
  StreamingEnabled on ........................................................ IMPLEMENTED

USER DIRECTION 2026-11-01 12:57 (do these next, in order)
  1. RESEARCH +1 Anime Eyes heavily (anime-eyes.wiki, 1-anime-eyes.wiki, dexerto, progameguides, sportskeeda auras) BEFORE remaking anything. Started; blocked by usage limit.
  2. Lobby hub like the reference screenshots: purple-tile plaza with yellow trim; row of hand-sign showcase pads
     (emblem disc + name + "xN Chakra" + trophy price; pads: owned yellow / equipped green / buy red / skip blue);
     training stations ("X2..X350 CHAKRA" labels, price, light beams); egg row on glowing pads with deal signs;
     FUSE MACHINE, BOSS SHOP, WORLDS portal, timed boss fight, special pet pedestal, leaderboards, black stone lanterns.
  3. Wins (Trophy) + Rebirth icons = gvesster pack (red/white rebirth ball with arrow = Rebirth 2nd?, gold trophy).
  4. ATTACK / E / R all show ONE emblem of the equipped hand sign (animal emoji disc, e.g. Ram).
  5. 30 stages instead of 50 (remap biomes, sign unlocks, final boss on 30).
  6. VFX remake; popups: "Welcome Back!" offline (x5 + Claim), "DON'T LEAVE YET!" (x2 chakra + 3 levels), "COME BACK TOMORROW".

  7. Ram = E Dragon Flame + R Shadow Clone (user 15:30). Rasengan moved to Horse (E) so all 28 jutsu stay in. DONE in Config.

NEXT
  - Menus still use emoji in a few card spots; swap to Assets icons
  - More Blender props per biome (torii, bamboo, pagoda tower, pet models)
  - Balance pass on Config.Stages curve vs sign/pet/aura multipliers (play stages 1-15 for pacing)
  - Mobile layout check on phone emulator
  - Custom uploaded animations/sounds if wanted (current poses are procedural, sounds are Roblox built-ins)
  - Real game pass / product ids in Shared.SystemsConfig
]]
return nil

