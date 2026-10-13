	local gcinclude = T{};
	function gcinclude.Say(msg) print(chat.header('GCinclude'):append(chat.message(msg))) end
	function gcinclude.Err(msg) print(chat.header('GCinclude'):append(chat.error(msg))) end

	--[[
	Only edit the next two small sections here. See the readme on my github for more information on usages for my profiles.

	These are universal sets for things like doomed or asleep; avoid main/sub/range/ammo here.
	The second section is a couple basic settings to decide on whether or not to use you the automatic equiping function of idle regen, idle refresh, DT gear etc.
	More details in each section.
	]]
	gcinclude.sets = T{
		Doomed = { -- this set will equip any time you have the doom status
			Ring1 = 'Purity Ring',
			Waist = 'Gishdubar Sash',
		},
		Holy_Water = { -- update with whatever gear you use for the Holy Water item
			Ring1 = 'Purity Ring',
			Ring2 = 'Blenmot\'s Ring',
		},
		Sleeping = { -- this set will auto equip if you are asleep, over Incapacitated; a job file's own Sleeping set is used instead (Main allowed there)
		},
		Reraise = { -- this set will try to equip when weakened if AutoGear variable is true below or you can force it with /rrset in game
			Head = 'Crepuscular Helm',
			Body = 'Crepuscular Mail',
		},
		Crafting = { -- this set is meant as a default set for crafting, equip using /craftset, be sure to dbl check what rings you want to use
			Head = 'Midras\'s Helm +1',
			Body = 'Tanner\'s Apron',
			Hands = 'Tanner\'s Gloves',
			Ring1 = 'Artificer\'s Ring',
			Ring2 = 'Craftmaster\'s Ring',
		},
		Zeni = { -- this set is meant as a default set for pictures, equip using /zeniset
			Range = 'Soultrapper 2000',
			Ammo = 'Blank Soulplate',
			Head = 'Malignance Chapeau',
			Neck = 'Bathy Choker +1';
			Ear1 = 'Infused Earring',
			Ear2 = 'Eabani Earring',
			Body = 'Nyame Mail',
			Hands = 'Malignance Gloves',
			Ring1 = 'Ilabrat Ring',
			Ring2 = 'Vengeful Ring',
			Back = 'Solemnity Cape',
			Waist = 'Svelt. Gouriz +1',
			Legs = 'Nyame Flanchard',
			Feet = 'Nyame Sollerets',
		},
		Fishing = { -- this set is meant as a default set for fishing, equip using /fishset
			Range = 'Halcyon Rod',
			Ring2 = 'Pelican Ring',
		},
	};
	gcinclude.settings = {
		--[[
		You can also set any of these on a per job basis in the job file in the OnLoad function. See my COR job file to see how this is done
		but as an example you can just put 'gcinclude.settings.RefreshGearMPP = 50;' in your job files OnLoad function to modify for that job only
		]]
		Messages = false; --set to true if you want chat log messages to appear on any /gc command used such as DT, TH, or KITE gear toggles, certain messages will always appear
		AutoGear = true; -- master switch for the four auto sets below, /autogear to change any of them in game
		WScheck = true; --set to false if you dont want to use the WSdistance safety check
		WSdistance = 5; --default max distance (yalms) to allow non-ranged WS to go off at if the above WScheck is true
		RegenGearHPP = 60; -- Idle_Regen below this HPP, out of combat only, 0 = never
		RefreshGearMPP = 60; -- Idle_Refresh below this MPP, out of combat only, 0 = never
		DTGearHPP = 50; -- Dt below this HPP, any status (engaged, idle, in or out of combat), 0 = never
		PetDTGearHPP = 50; -- Pet_Dt below this pet HPP, 0 = never
		MoonshadeTP = 1750; -- every WS, every job: Moonshade Earring below this TP, never at or above it; 0 = engine leaves Moonshade alone
		MoonshadeSlot = 'Ear2'; -- the slot the engine puts it in
		MoonshadeSkip = T{}; -- WS names the engine never gives Moonshade, e.g. T{'Myrkr'}
		DisplayBar = false; -- one-line status bar (job, atk/def, toggles, cycles), /gcbar to toggle
		DisplayBarX = 300;
		DisplayBarY = 0;
		warp_Ring = 'Warp Ring'; -- /warpring, /mea, /holla, /dem: equip in Ring2, use 11s later, back to Idle 11s after that
		mea_Ring = 'Dim. Ring (Mea)';
		dem_Ring = 'Dim. Ring (Dem)';
		holla_Ring = 'Dim. Ring (Holla)';
		WeaponTPGuard = 1000; -- at or above this TP (engaged or not), main/sub/range are held and weapon commands are refused unless you add force, 0 to disable
		HoldExemptSkills = T{'Singing', 'Geomancy', 'Healing Magic', 'Enfeebling Magic', 'Enhancing Magic'}; -- spells of these skills always get their weapon swaps
		HoldExemptAbilities = T{'Corsair Roll'}; -- ability types that always get their weapon swaps
		SmartSwap = true; -- keep main/sub/range on the spells below instead of losing TP to a weapon swap, /smartswap to toggle
		SmartSwapTP = 1; -- SmartSwap only acts at or above this TP
		NoWeaponSpells = T{'Dia', 'Dia II', 'Dia III', 'Diaga', 'Blink', 'Ice Spikes', 'Blaze Spikes', 'Shock Spikes'}; -- exact spell names that never swap main/sub/range
		KeepWeaponsFor = T{ -- spells starting with Spells keep main/sub/range while any Worn item is in main or sub
			{ Spells = T{'Cure', 'Cura'}, Worn = T{'Daybreak', 'Bunzi\'s Rod'} },
		};
		AutoFood = false; -- default state of the AutoFood toggle on load
		AutoFoodItems = T{'Grape Daifuku +1', 'Grape Daifuku'}; -- eaten in this order, a job can override with gcinclude.AutoFood
		AutoRevitalizer = true; -- master switch for AutoUseItems below, /revit off to stop
		AutoUseItems = T{ -- use one of these the moment it lands in your bags in a matching zone
			{ Zone = 'Ghoyu', Item = 'Revitalizer' },
		};
		EnchantWindow = 12; -- fallback wait when the item resource has no equip delay
		EnchantDelays = T{}; -- per-item override in seconds, e.g. T{ ['Reraise Earring'] = 30 }
		AutoHolyWater = true; -- use a Holy Water the moment you are Doomed
		HolyWaterItem = 'Holy Water';
		ReceivedSets = T{ -- spell or ability name (lowercase, matched as a prefix) -> set worn while it is on its way to you
			['cure'] = 'Cure_Received',
			['cura'] = 'Cure_Received',
			['curaga'] = 'Cure_Received',
			['cursna'] = 'Cursna_Received',
			['phalanx'] = 'Phalanx_Received',
			['protect'] = 'Protect_Shell_Received',
			['shell'] = 'Protect_Shell_Received',
			['regen'] = 'Regen_Received',
			['refresh'] = 'Refresh_Received',
			['curing waltz'] = 'Waltz_Received',
			['divine waltz'] = 'Waltz_Received',
		};
		ReceivedWindow = 8; -- seconds the received gear stays on before it gives up
		MyBoxes = T{}; -- your own characters that get the Multisend 'received' notice; boxes running this engine are found by themselves (HUD state file), so only needed if that fails, e.g. T{'Shaymin','Muunch'}
		ElementReport = false;
		OrpheusPoints = T{ {1.93, 15}, {13, 1} }; -- {yalms, affinity %}: BG's two documented ends; linear between them is assumed. Add tested points in order. -- /gcinfo prints what the element picker chose and why
		ElementGear = T{ -- waist chosen by the spell's element, day and weather
			Obis = T{ Dark = 'Anrin Obi' }, -- element obis you own; add as you get them
			AnyObi = 'Hachirin-no-Obi', -- every element; worn only when day/weather nets positive
			Distance = 'Orpheus\'s Sash', -- used when it beats the obi's day/weather value
			DistanceMax = nil, -- optional yalm cap for Orpheus; nil = any distance (it is never below +1)
			Ring = nil, -- e.g. 'Zodiac Ring', worn when the day matches the element (never Light/Dark, never on cures)
			RingSlot = 'Ring2',
			Back = nil, -- e.g. 'Twilight Cape': +5% to a day bonus, or to a weather bonus that applies (BG-Wiki)
			Cures = true, -- Cure/Cura/Curaga: obi on Light day/weather (BG-Wiki: +10/+10/+25, the obi forces it); false = never
			BackOnCures = false, -- also the back on Cure/Cura/Curaga (your cure-potency back may be worth more)
			Keep = T{'Oneiros Rope'}, -- items that are never displaced by the picks above
		};
		AutoSoda = false; -- /autosoda: keep Regain up with SodaItem
		SodaItem = 'Frontier Soda';
		ConsumableMaxTries = 2; -- AutoSoda disarms after this many tries without Regain showing up
		AutoNuke = false; -- /automb on load: cast into live skillchains on your target or a mob your party is engaged on (RDM/BLM/SCH/GEO). Sync's logic.
		MBCasts = 1; -- bursts per chain (sync: count)
		MBRotate = false; -- spread bursts across the chain's elements (sync: rotate)
		MBMinMP = 0; -- hold fire below this MP (sync: mp)
		MBWindow = 10; -- magic burst window in seconds from the skillchain (BG: 10); another WS on the mob ends it
		-- /autonuke casts the chain element's single-target nuke (Fire, Blizzard, Aero, Stone, Thunder,
		-- Water) at this tier: 'Low' = I, 'Mid' = III, 'High' = V. /mbtier changes it in game.
		-- Light/Dark have no tiered nuke: SCH falls back to Luminohelix/Noctohelix. Per job: gcinclude.MBTier = 'High'.
		MBTier = 'Mid';
		MBFallback = true; -- tier not castable / on recast / short MP: try the next tier down (V > IV > III > II > I)
		MBSkills = T{'Elemental Magic'}; -- skills /automb dresses; add 'Dark Magic' etc. as you like
		ElementSkills = T{'Elemental Magic','Blue Magic'}; -- spell skills that get obi/Orpheus/element ring
		-- Elemental WS and their element (BG-Wiki Category:Elemental Weapon Skill). Starburst/Sunburst
		-- (Light or Dark), Spirits Within and Atonement (breath damage) are left out on purpose.
		ElementalWS = {
			['Gust Slash'] = 'Wind', ['Cyclone'] = 'Wind', ['Energy Steal'] = 'Dark', ['Energy Drain'] = 'Dark', ['Aeolian Edge'] = 'Wind',
			['Burning Blade'] = 'Fire', ['Red Lotus Blade'] = 'Fire', ['Shining Blade'] = 'Light', ['Seraph Blade'] = 'Light', ['Sanguine Blade'] = 'Dark',
			['Frostbite'] = 'Ice', ['Freezebite'] = 'Ice', ['Herculean Slash'] = 'Ice',
			['Cloudsplitter'] = 'Thunder', ['Primal Rend'] = 'Light',
			['Dark Harvest'] = 'Dark', ['Shadow of Death'] = 'Dark', ['Infernal Scythe'] = 'Dark',
			['Thunder Thrust'] = 'Thunder', ['Raiden Thrust'] = 'Thunder',
			['Blade: Teki'] = 'Water', ['Blade: To'] = 'Ice', ['Blade: Chi'] = 'Earth', ['Blade: Ei'] = 'Dark', ['Blade: Yu'] = 'Water',
			['Tachi: Goten'] = 'Thunder', ['Tachi: Kagero'] = 'Fire', ['Tachi: Jinpu'] = 'Wind', ['Tachi: Koki'] = 'Light',
			['Shining Strike'] = 'Light', ['Seraph Strike'] = 'Light', ['Flash Nova'] = 'Light',
			['Rock Crusher'] = 'Earth', ['Earth Crusher'] = 'Earth', ['Cataclysm'] = 'Dark', ['Vidohunir'] = 'Dark',
			['Garland of Bliss'] = 'Light', ['Omniscience'] = 'Dark',
			['Flaming Arrow'] = 'Fire', ['Hot Shot'] = 'Fire', ['Wildfire'] = 'Fire', ['Trueflight'] = 'Light', ['Leaden Salute'] = 'Dark',
		};
		CombatWindow = 6; -- seconds; Selindrile uses 6
		SIRSkip = T{}; -- spell names /sir leaves alone, e.g. T{'Phalanx','Reprisal'}
		DefenseExempt = T{'Absorb-TP', 'Stun'}; -- /def states leave these spells alone: no SIR over them, /aminon's weapon lock lifted for the cast; opt-in <Set>_<State> sets (COMMANDS.md Defense and locks)
		HoxneItem = 'Hoxne Ampulla'; -- what the Hoxne states keep in your ammo slot
		HoxneLockSlots = T{'Ammo', 'Range'}; -- locked by the Locked state (nothing worn in Range can stay on with the Ampulla: SE forum ranged/ammo groups)
		Keybinds = T{ {'^`','wm'}, {'+`','wm default'}, {'^+`','def'}, {'!`','hoxne'}, {'@`','automb'} }; -- no bare grave (too easy to hit); bound on load, unbound on unload; T{} for none. Per job: set gcinclude.settings.Keybinds in OnLoad before gcinclude.Initialize()
		XIRollSet = T{ Ring2 = 'Roller\'s Ring' }; -- used when a job file has no XIRoll set of its own
		HUDOwners = T{'Shaymin'}; -- character names that open the alt HUD on load
		HUDX = 300; -- alt HUD position; drag it in game, saved per character
		HUDY = 40;
		HUDAlpha = 0.45; -- HUD background opacity, 0 = none
		HUDScale = 0.9; -- HUD text size (compact style)
		HUDStyle = 'compact'; -- HUD look: 'compact' (tight) or 'large' (bigger text, more spacing, full names); /gchud large|compact, saved per character
		HUDScaleLarge = 1.1; -- HUD text size in the large style
		HUDPinned = T{'Def', 'MB', 'Kite', 'AutoFood', 'AutoSoda'}; -- HUD columns always shown (Def = DT/MDT/Aminon/SIR via /def, MB = /mbmode); others only once a box changes them
		HUDAbbr = {}; -- HUD short value overrides, e.g. { ['CarnwenhanAcc'] = 'CarnA' }; auto-shortened otherwise
		HUDLabels = {}; -- HUD column glyph overrides, e.g. { Main = 'mn', AutoSoda = 'so' }
		Validate = true; -- cancel spells/abilities/WS that would fail: KO, sleep/stun/petrify/terror/charm, mute, silence, recast, MP, stratagems, Waltz TP, amnesia
		ValidateMP = true; -- the MP part; gear "MP cost -%" isn't counted, so turn off if it stops casts that would go off
		AutoRemedy = true; -- silenced: Echo Drops, else Remedy (Remedy first if also paralyzed); paralyzed on an ability: Remedy. Not under Muddle
		WaltzTPCut = 0; -- total "Waltz TP cost" reduction on your Waltz gear, in TP
		MiniQueue = true; -- recast back within MiniQueueMax seconds: send it then instead of just cancelling
		MiniQueueMax = 5;
		Trace = false; -- /gctrace: one chat line per action naming each set put on
		LockstyleSet = nil; -- /lockstyleset N 4s after load and job change; per job gcinclude.LockstyleSet = N in OnLoad
		CapacityCapes = T{'Aptitude Mantle +1', 'Aptitude Mantle', 'Mecisto. Mantle'}; -- /capacity wears the carried one worth most (Mecisto by its augment)
		JubileeSlot = 'Ring1'; -- /jubilee ring slot
		AmmoWarn = 20; -- warn when the ammo in use (inventory + wardrobes) is at or under this, 0 = never
		NinjaToolWarn = 10; -- warn when Utsusemi tools (Shihei, + Shikanofuda on NIN) are at or under this, 0 = never
		SleepCancelStoneskin = true; -- asleep with Stoneskin up: /cancel Stoneskin so damage can wake you (FFXIclopedia Sleep)
		HoxneAutoUse = true; -- Hoxne Locked: use the Ampulla when it is in ammo and Enchantment isn't up
	};

	--[[
	Everything else in this file should not be editted by anyone trying to use my profiles. You really just want to update the various gear sets
	in each individual job lua file. Unless you know what you're doing then it is best to leave everything below this line alone, the rest here are various functions and arrays etc.
	]]
	gcdisplay = gFunc.LoadFile('common\\gcdisplay.lua');
	gcauto = gFunc.LoadFile('common\\gcauto.lua');
	gcaction = gFunc.LoadFile('common\\gcaction.lua');
	local hudOk, hudModule = pcall(gFunc.LoadFile, 'common\\gchud.lua');
	if (hudOk == true) and (type(hudModule) == 'table') then
		gchud = hudModule;
	else
		gchud = nil;
		gcinclude.Err('HUD disabled: gchud.lua failed to load.');
	end

	gcinclude.AliasList = T{'gcmessages','wsdistance','setcycle','dt','mdt','th','kite','meleeset','mset','gcdrain','gcaspir','nukeset','burst','automb','autonuke','weapon','elecycle','helix','weather','nuke','death','sir','tankset','proc',
	'pupmode','weaponset','wm','mainset','subset','rangeset','ammoset','autofood','autosoda','revit','holywater','aminon','gchud','lock','unlock','hoxne','gchelp','gckey','def','mbmode','received','gcinfo','gce','xiroll','checksets','smartswap','autogear','gcbar','mbinfo','cormsg','forcestring','songlock','siphon','warpring','mea','holla','dem','rrset','craftset','zeniset','fishset','mbtier',
	'gctrace','naked','weaponsonly','abysseaproc','capacity','jubilee','gcstyle','dw','dynamisrp','temps'};
	-- Exit/use-on-self items: key = /command, value = exact /item name. Add a line, /lac reload.
	gcinclude.ExitItems = {
		ontic = 'ontic extremity',
		shard = 'v. con. shard',
	};
	for k in pairs(gcinclude.ExitItems) do
		if not gcinclude.AliasList:contains(k) then table.insert(gcinclude.AliasList, k) end
	end
	gcinclude.Towns = T{'Tavnazian Safehold','Aht Urhgan Whitegate','Nashmau','Southern San d\'Oria [S]','Bastok Markets [S]','Windurst Waters [S]','San d\'Oria-Jeuno Airship','Bastok-Jeuno Airship','Windurst-Jeuno Airship','Kazham-Jeuno Airship','Southern San d\'Oria','Northern San d\'Oria','Port San d\'Oria','Chateau d\'Oraguille','Bastok Mines','Bastok Markets','Port Bastok','Metalworks','Windurst Waters','Windurst Walls','Port Windurst','Windurst Woods','Heavens Tower','Ru\'Lude Gardens','Upper Jeuno','Lower Jeuno','Port Jeuno','Rabao','Selbina','Mhaura','Kazham','Norg','Mog Garden','Celennia Memorial Library','Western Adoulin','Eastern Adoulin'};
	gcinclude.LockingRings = T{'Echad Ring', 'Trizek Ring', 'Endorsement Ring', 'Capacity Ring', 'Warp Ring','Facility Ring','Dim. Ring (Dem)','Dim. Ring (Mea)','Dim. Ring (Holla)'};
	gcinclude.DistanceWS = T{'Flaming Arrow','Piercing Arrow','Dulling Arrow','Sidewinder','Blast Arrow','Arching Arrow','Empyreal Arrow','Refulgent Arrow','Apex Arrow','Namas Arrow','Jishnu\'s Radiance','Hot Shot','Split Shot','Sniper Shot','Slug Shot','Blast Shot','Heavy Shot','Detonator','Numbing Shot','Last Stand','Coronach','Wildfire','Trueflight','Leaden Salute','Myrkr','Dagan','Moonlight','Starlight','Mistral Axe','Bora Axe','Sarv','Terminus'};
	gcinclude.NoAmmoWS = T{'Myrkr','Dagan','Moonlight','Starlight','Mistral Axe','Bora Axe'};
	gcinclude.BluMagDebuff = T{'Filamented Hold','Cimicine Discharge','Demoralizing Roar','Venom Shell','Light of Penance','Sandspray','Auroral Drape','Frightful Roar','Enervation','Infrasonics','Lowing','Cold Wave','Awful Eye','Voracious Trunk','Sheep Song','Soporific','Yawn','Dream Flower','Chaotic Eye','Sound Blast','Blank Gaze','Stinking Gas','Geist Wall','Feather Tickle','Reaving Wind','Mortal Ray','Absolute Terror','Blistering Roar','Cruel Joke'};
	gcinclude.BluMagPhysical = T{'Foot Kick','Power Attack','Sprout Smack','Wild Oats','Queasyshroom','Battle Dance','Head Butt','Feather Storm','Helldive','Bludgeon','Claw Cyclone','Screwdriver','Grand Slam','Smite of Rage','Pinecone Bomb','Jet Stream','Uppercut','Terror Touch','Mandibular Bite','Sickle Slash','Death Scissors','Dimensional Death','Spiral Spin','Seedspray','Body Slam','Spinal Cleave','Frenetic Rip','Frypan','Hydro Shot','Tail Slap','Hysteric Barrage','Cannonball','Asuran Claws','Disseverment','Sub-zero Smash','Ram Charge','Vertical Cleave','Final Sting','Goblin Rush','Vanity Dive','Whirl of Rage','Benthic Typhoon','Quad. Continuum','Empty Thrash','Delta Thrust','Heavy Strike','Sudden Lunge','Quadrastrike','Tourbillion','Amorphic Spikes','Barbed Crescent','Paralyzing Triad','Glutinous Dart','Thrashing Assault','Sinker Drill','Sweeping Gouge','Saurian Slide','Bilgestorm','Bloodrake'};
	gcinclude.BluMagStun = T{'Head Butt','Frypan','Tail Slap','Sub-zero Smash','Sudden Lunge'};
	gcinclude.BluMagBuff = T{'Cocoon','Refueling','Feather Barrier','Memento Mori','Zephyr Mantle','Warm-Up','Amplification','Triumphant Roar','Saline Coat','Reactor Cool','Plasma Charge','Regeneration','Animating Wail','Battery Charge','Winds of Promy.','Barrier Tusk','Orcish Counterstance','Pyric Bulwark','Nat. Meditation','Restoral','Erratic Flutter','Carcharian Verve','Harden Shell','Mighty Guard'};
	gcinclude.BluMagSkill = T{'Metallic Body','Diamondhide','Magic Barrier','Occultation','Atra. Libations'};
	gcinclude.BluMagCure = T{'Pollen','Healing Breeze','Wild Carrot','Magic Fruit','Plenilune Embrace'};
	gcinclude.BluMagEnmity = T{'Actinic Burst','Exuviation','Fantod','Jettatura','Temporal Shift'};
	gcinclude.BluMagTH = T{'Actinic Burst','Dream Flower','Subduction'};
	gcinclude.Elements = T{'Thunder', 'Blizzard', 'Fire', 'Stone', 'Aero', 'Water', 'Light', 'Dark'};
	gcinclude.HelixSpells = T{'Ionohelix', 'Cryohelix', 'Pyrohelix', 'Geohelix', 'Anemohelix', 'Hydrohelix', 'Luminohelix', 'Noctohelix'};
	gcinclude.StormSpells = T{'Thunderstorm', 'Hailstorm', 'Firestorm', 'Sandstorm', 'Windstorm', 'Rainstorm', 'Aurorastorm', 'Voidstorm'};
	gcinclude.Rolls = T{{'Fighter\'s Roll',5,9}, {'Monk\'s Roll',3,7}, {'Healer\'s Roll',3,7}, {'Corsair\'s Roll',5,9}, {'Ninja Roll',4,8},{'Hunter\'s Roll',4,8}, {'Chaos Roll',4,8}, {'Magus\'s Roll',2,6}, {'Drachen Roll',4,8}, {'Choral Roll',2,6},{'Beast Roll',4,8}, {'Samurai Roll',2,6}, {'Evoker\'s Roll',5,9}, {'Rogue\'s Roll',5,9}, {'Warlock\'s Roll',4,8},
		{'Puppet Roll',3,7}, {'Gallant\'s Roll',3,7}, {'Wizard\'s Roll',5,9}, {'Dancer\'s Roll',3,7}, {'Scholar\'s Roll',2,6},{'Naturalist\'s Roll',3,7}, {'Runeist\'s Roll',4,8}, {'Bolter\'s Roll',3,9}, {'Caster\'s Roll',2,7}, {'Courser\'s Roll',3,9},{'Blitzer\'s Roll',4,9}, {'Tactician\'s Roll',5,8}, {'Allies\' Roll',3,10}, {'Miser\'s Roll',5,7},
		{'Companion\'s Roll',2,10},{'Avenger\'s Roll',4,8},}; -- {name,lucky,unlucky}
	-- /rrset /craftset /zeniset /fishset: command -> gcinclude.sets name; on ones layer over everything.
	gcinclude.UtilSets = { rrset = 'Reraise', craftset = 'Crafting', zeniset = 'Zeni', fishset = 'Fishing' };
	gcinclude.UtilOn = {};
	gcinclude.HardCC = T{'Sleep', 'Petrification', 'Stun', 'Terror', 'Charm'}; -- can't act (gcauto, gcaction, WS bailout)
	gcinclude.CORmsg = true;

	-- /def: none > DT > MDT > Aminon > SIRD > none. Only one of the four is on at a time.
	gcinclude.DefenseCycle = T{ {'DTset','DT'}, {'MDTset','MDT'}, {'Aminon','Aminon'}, {'SIR','SIRD'} };
	function gcinclude.CycleDefense(arg)
		local want = string.lower(tostring(arg or ''));
		if (want ~= '') then -- /def off|none, or a set by name (dt, mdt, aminon, sir)
			local pick = nil;
			for _, d in ipairs(gcinclude.DefenseCycle) do
				if (string.lower(d[2]) == want) or (string.lower(d[1]) == want) then pick = d end
			end
			if (pick == nil) and (want ~= 'off') and (want ~= 'none') then return 'unknown: ' .. want end
			for _, d in ipairs(gcinclude.DefenseCycle) do gcdisplay.SetToggle(d[1], d == pick) end
			return (pick ~= nil) and pick[2] or 'None';
		end
		local current = 0;
		for i, d in ipairs(gcinclude.DefenseCycle) do
			if (gcdisplay.GetToggle(d[1]) == true) and (current == 0) then current = i end
			gcdisplay.SetToggle(d[1], false);
		end
		local nextOne = gcinclude.DefenseCycle[current + 1];
		if (nextOne == nil) then return 'None' end
		gcdisplay.SetToggle(nextOne[1], true);
		return nextOne[2];
	end

	-- /mbtier: Low (tier I) / Mid (tier III) / High (tier V) for /autonuke. Accepts low|mid|high|hi|1|3|5.
	gcinclude.MBTierAlias = { low = 'Low', l = 'Low', ['1'] = 'Low', i = 'Low', mid = 'Mid', m = 'Mid', ['3'] = 'Mid', iii = 'Mid',
		high = 'High', hi = 'High', h = 'High', ['5'] = 'High', v = 'High' };
	gcinclude.MBTierNum = { Low = 1, Mid = 3, High = 5 };
	function gcinclude.SetMBTier(v, quiet)
		local t = gcinclude.MBTierAlias[string.lower(tostring(v or ''))];
		if (t == nil) then
			if not quiet then gcinclude.Err('/mbtier low|mid|high (tier I / III / V)') end
			return;
		end
		gcdisplay.SetCycle('MBTier', t);
	end
	function gcinclude.MBTierText()
		local t = gcdisplay.GetCycle('MBTier');
		local roman = { Low = 'I', Mid = 'III', High = 'V' };
		return tostring(t) .. ' (tier ' .. (roman[t] or '?') .. ')';
	end

	-- Toggle commands: 'on' or 'off' sets it, no argument flips it.
	function gcinclude.FlipToggle(name, arg)
		local a = string.lower(tostring(arg or ''));
		if (a == 'on') then gcdisplay.SetToggle(name, true)
		elseif (a == 'off') then gcdisplay.SetToggle(name, false)
		else gcdisplay.AdvanceToggle(name) end
		return gcdisplay.GetToggle(name);
	end

	-- /automb (same: /autonuke, /mbmode): this box casts into live skillchains by itself, on/off; /mbtier picks the
	-- tier. The Burst set needs no switch: a nuke landing in a live skillchain of its element always wears it.
	function gcinclude.AutoMBCommand(arg)
		local job = gData.GetPlayer().MainJob;
		if not T{'RDM','BLM','SCH','GEO'}:contains(job) then return 'not used on ' .. tostring(job) end
		local a = string.lower(tostring(arg or ''));
		local on = (a == 'on') or ((a ~= 'off') and (gcdisplay.GetToggle('AutoNuke') ~= true));
		gcdisplay.SetToggle('AutoNuke', on);
		if (gcauto ~= nil) and (gcauto.ResetNuke ~= nil) then gcauto.ResetNuke() end
		return on and ('on, ' .. gcinclude.MBTierText()) or 'off';
	end

	function gcinclude.Message(toggle, status)
		if toggle ~= nil and status ~= nil then
			gcinclude.Say(toggle .. ' is now ' .. tostring(status))
		end
	end

	function gcinclude.SetAlias()
		for _, v in ipairs(gcinclude.AliasList) do
			AshitaCore:GetChatManager():QueueCommand(-1, '/alias /' .. v .. ' /lac fwd ' .. v);
		end
	end

	function gcinclude.ClearAlias()
		for _, v in ipairs(gcinclude.AliasList) do
			AshitaCore:GetChatManager():QueueCommand(-1, '/alias del /' .. v);
		end
	end

function gcinclude.SetVariables()
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local mJob = 'NON';
    gcinclude.ActiveJobId = nil;
    if (player ~= nil) then
        local mainJobId = player:GetMainJob();
        gcinclude.ActiveJobId = mainJobId;
        mJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", mainJobId) or 'NON';
    end

    gcinclude.UnlockSlots(nil);
    gcinclude.UnlockWeapons();
    gcinclude.Holds, gcinclude.Strip = {}, nil;
    gcinclude.Enchants = {};
    gcdisplay.ClearAll();
    gcdisplay.CreateToggle('DTset', false);
    gcdisplay.CreateToggle('MDTset', false);
    gcdisplay.CreateToggle('Aminon', false);
    gcdisplay.CreateToggle('SIR', false);
    gcdisplay.CreateCycle('Hoxne', {[1] = 'Off', [2] = 'Locked'});
    gcdisplay.CreateToggle('Kite', false);
    gcdisplay.CreateToggle('TH', false);
    gcdisplay.CreateCycle('MeleeSet', {[1] = 'Default', [2] = 'Hybrid', [3] = 'Acc'});
    gcinclude.BuildWeaponCycles(mJob);
    if (type(gcinclude.DefaultWeapons) == 'string') then
        gcinclude.SetWeaponCycle('Weapons', gcinclude.DefaultWeapons, true);
    elseif (type(gcinclude.DefaultWeapons) == 'table') then
        for cname, val in pairs(gcinclude.DefaultWeapons) do
            gcinclude.SetWeaponCycle(cname, val, true);
        end
    end
    gcauto.Bind(gcinclude, gcdisplay);
    gcaction.Bind(gcinclude);
    if (gchud ~= nil) then gchud.Bind(gcinclude, gcdisplay) end
    gcauto.CreateToggles();
    if (mJob == 'RDM') or (mJob == 'BLM') or (mJob == 'SCH') or (mJob == 'GEO') then
        gcdisplay.CreateToggle('Burst', false); -- /burst: Burst set on every nuke, not only on live skillchains
        gcdisplay.CreateToggle('AutoNuke', gcinclude.settings.AutoNuke == true); -- /automb: cast into live skillchains
        gcdisplay.CreateCycle('NukeSet', {[1] = 'Power', [2] = 'Macc',});
        gcdisplay.CreateCycle('MBTier', {[1] = 'Low', [2] = 'Mid', [3] = 'High'}); -- /mbtier: I / III / V
        gcinclude.SetMBTier(gcinclude.MBTier or gcinclude.settings.MBTier or 'Mid', true);
        if (mJob == 'BLM') or (mJob == 'SCH') then
            gcdisplay.CreateCycle('Weapon', {[1] = 'Club', [2] = 'Staff'});
            gcdisplay.CreateCycle('Element', {[1] = 'Thunder', [2] = 'Blizzard', [3] = 'Fire', [4] = 'Stone', [5] = 'Aero', [6] = 'Water', [7] = 'Light', [8] = 'Dark'});
            if (mJob == 'BLM') then
                gcdisplay.CreateToggle('Death', false);
            end
        end
    end
    if (mJob == 'WHM') then
        gcdisplay.CreateCycle('NukeSet', {[1] = 'Power', [2] = 'Macc',});
    end
    if (mJob == 'PLD') or (mJob == 'RUN') then
        gcdisplay.CreateCycle('TankSet', {[1] = 'None', [2] = 'Main', [3] = 'MEVA'});
    end
    if (mJob == 'SAM') or (mJob == 'NIN') then
        gcdisplay.CreateToggle('PROC', false);
    end
    if (mJob == 'PUP') then
        gcdisplay.CreateCycle('PupMode', {[1] = 'Tank', [2] = 'Melee', [3] = 'Ranger', [4] = 'Mage'});
    end
    if (mJob == 'BRD') then
        gcdisplay.CreateToggle('String', false);
        gcdisplay.CreateToggle('SongLock', false);
    end
    gcdisplay.MarkDefaults();
end

	function gcinclude.HandleCommands(args)
		if (type(args[1]) == 'string') then args[1] = string.lower(args[1]) end -- //gs c MeleeSet works too
		if not gcinclude.AliasList:contains(args[1]) then return end

		local player = gData.GetPlayer();
		local toggle = nil;
		local status = nil;

		if args[1] == 'gcmessages' then
			local m = string.lower(tostring(args[2] or ''));
			if (m == 'on') or (m == 'off') then gcinclude.settings.Messages = (m == 'on') else gcinclude.settings.Messages = not gcinclude.settings.Messages end
			gcinclude.Say('Chat messages ' .. (gcinclude.settings.Messages and 'on' or 'off'));
		elseif (args[1] == 'wsdistance') then
			if (tonumber(args[2])) then
				gcinclude.settings.WScheck = true;
				gcinclude.settings.WSdistance = tonumber(args[2]);
				gcinclude.Say('WS Distance is on and set to ' .. gcinclude.settings.WSdistance);
			else
				gcinclude.settings.WScheck = not gcinclude.settings.WScheck;
				gcinclude.Say('WS distance check is now ' .. tostring(gcinclude.settings.WScheck));
				gcinclude.Say('Can change WS distance allowed by using /wsdistance ##');
			end
		elseif (args[1] == 'dt') then
			gcinclude.FlipToggle('DTset', args[2]);
			toggle = 'DT Set';
			status = gcdisplay.GetToggle('DTset');
		elseif (args[1] == 'sir') then
			gcinclude.FlipToggle('SIR', args[2]);
			toggle = 'Spell Interrupt Set';
			status = gcdisplay.GetToggle('SIR');
		elseif (args[1] == 'mbmode') or (args[1] == 'automb') or (args[1] == 'autonuke') then
			toggle, status = 'Auto MB', gcinclude.AutoMBCommand(args[2]);
		elseif (args[1] == 'def') then
			toggle, status = 'Defense', gcinclude.CycleDefense(args[2]);
			gcinclude.CheckAminonLock();
		elseif (args[1] == 'mdt') then
			gcinclude.FlipToggle('MDTset', args[2]);
			toggle = 'MDT Set';
			status = gcdisplay.GetToggle('MDTset');
		elseif (args[1] == 'meleeset') or (args[1] == 'mset') then
			gcinclude.PickCycle('MeleeSet', args[2]);
			toggle = 'Melee Set';
			status = gcdisplay.GetCycle('MeleeSet');
		elseif (gcinclude.WeaponCommands[args[1]] ~= nil) then
			local cname = gcinclude.WeaponCommands[args[1]];
			gcinclude.WeaponCommand(cname, args);
			toggle = cname;
			status = gcdisplay.GetCycle(cname);
		elseif (args[1] == 'autofood') or (args[1] == 'autosoda') or (args[1] == 'revit') or (args[1] == 'holywater') then
			gcauto.HandleCommand(args);
		elseif (args[1] == 'hoxne') then
			if (args[2] ~= nil) and (string.lower(args[2]) == 'use') then
				gcinclude.SetWeaponCycle('Hoxne', 'Locked', true);
				gcinclude.CheckHoxne();
				gcinclude.UseEnchanted(gcinclude.settings.HoxneItem, 'Ammo', true);
			elseif (args[2] ~= nil) then
				gcinclude.SetWeaponCycle('Hoxne', args[2], true);
			else
				gcdisplay.AdvanceCycle('Hoxne');
			end
			toggle = 'Hoxne';
			status = gcdisplay.GetCycle('Hoxne');
		elseif (args[1] == 'received') then
			gcinclude.ReceivedCommand(args);
		elseif (args[1] == 'gcinfo') then
			gcinclude.settings.ElementReport = not (gcinclude.settings.ElementReport == true);
			toggle = 'Element report';
			status = gcinclude.settings.ElementReport;
		elseif (args[1] == 'gce') then
			gcinclude.EnchantCommand(args);
		elseif (args[1] == 'gchelp') then
			gcinclude.Help();
		elseif (args[1] == 'gckey') then
			gcinclude.KeyCommand(args);
		elseif (args[1] == 'aminon') then
			gcinclude.FlipToggle('Aminon', args[2]);
			gcinclude.CheckAminonLock();
			toggle = 'Aminon Set';
			status = gcdisplay.GetToggle('Aminon');
		elseif (args[1] == 'gchud') then
			if (gchud ~= nil) then
				gchud.HandleCommand(args);
			else
				gcinclude.Err('HUD is not loaded.');
			end
		elseif (args[1] == 'smartswap') then
			gcinclude.SmartSwapCommand(args);
		elseif (args[1] == 'autogear') then
			gcinclude.AutoGearCommand(args);
		elseif (args[1] == 'gcbar') then
			gcdisplay.BarCommand(args);
		elseif (args[1] == 'lock') then
			gcinclude.LockCommand(args);
		elseif (args[1] == 'unlock') then
			gcinclude.UnlockCommand(args);
		elseif (args[1] == 'mbinfo') then
			gcinclude.Say('last chain: ' .. ((gcauto ~= nil) and gcauto.BurstInfo() or 'no tracker'));
		elseif (args[1] == 'checksets') then
			gcinclude.CheckSets();
		elseif (args[1] == 'xiroll') then
			gcinclude.Say('rolls up: ' .. tostring(gcinclude.RollActive()) .. ' | eleven: ' .. tostring((gcauto ~= nil) and gcauto.RollEleven() or false) .. ' | ' .. ((gcauto ~= nil) and gcauto.RollInfo() or 'no tracker'));
		elseif (#args == 3 and args[1] == 'setcycle') then
			local cname = gcinclude.CycleName(args[2]);
			if (cname == nil) then
				gcinclude.Err('No cycle named ' .. args[2]);
			elseif gcinclude.PickCycle(cname, args[3]) then
				toggle = cname;
				status = gcdisplay.GetCycle(cname);
				if (gcinclude.WeaponCycleList(cname) ~= nil) then gcinclude.ApplyWeapons() end
			end
		elseif (args[1] == 'kite') then
			gcinclude.FlipToggle('Kite', args[2]);
			toggle = 'Kite Set';
			status = gcdisplay.GetToggle('Kite');
		elseif (args[1] == 'th') then
			gcinclude.FlipToggle('TH', args[2]);
			toggle = 'TH Set';
			status = gcdisplay.GetToggle('TH');
		elseif (args[1] == 'gcaspir') then
			gcinclude.DoAspir();
		elseif (args[1] == 'gcdrain') then
			gcinclude.DoDrain();
		elseif (gcinclude.TeleRings[args[1]] ~= nil) then
			gcinclude.UseTeleRing(gcinclude.TeleRings[args[1]]);
		elseif (gcinclude.ExitItems[args[1]] ~= nil) then
			AshitaCore:GetChatManager():QueueCommand(-1, '/item "' .. gcinclude.ExitItems[args[1]] .. '" <me>');
		elseif (args[1] == 'temps') then
			gcinclude.UseTemps();
		elseif (args[1] == 'dw') then
			gcinclude.DualWieldCommand(args);
		elseif (args[1] == 'gctrace') then
			gcinclude.settings.Trace = not (gcinclude.settings.Trace == true);
			gcinclude.Say('Trace: ' .. (gcinclude.settings.Trace and 'on' or 'off'));
		elseif (gcinclude.StripModes[args[1]] ~= nil) then
			gcinclude.StripCommand(args[1], args[2] and string.lower(args[2]));
		elseif (gcinclude.CarriedKeys:contains(args[1])) then
			gcinclude.CarriedCommand(args[1], args[2] and string.lower(args[2]));
		elseif (args[1] == 'gcstyle') then
			if not gcinclude.ApplyLockstyle(args[2], 0) then gcinclude.Say('usage: /gcstyle <N>, or set LockstyleSet') end
		elseif (gcinclude.UtilSets[args[1]] ~= nil) then
			gcinclude.UtilOn[args[1]] = not gcinclude.UtilOn[args[1]];
			toggle, status = gcinclude.UtilSets[args[1]] .. ' Set', gcinclude.UtilOn[args[1]];
		end
		if (player.MainJob == 'RDM') or (player.MainJob == 'BLM') or (player.MainJob == 'SCH') or (player.MainJob == 'GEO') then
			if (args[1] == 'nukeset') then
				gcinclude.PickCycle('NukeSet', args[2]);
				toggle = 'Nuking Gear Set';
				status = gcdisplay.GetCycle('NukeSet');
			elseif (args[1] == 'burst') then
				gcinclude.FlipToggle('Burst', args[2]);
				toggle = 'Burst set on every nuke';
				status = gcdisplay.GetToggle('Burst');
			elseif (args[1] == 'mbtier') then
				if (args[2] ~= nil) then
					gcinclude.SetMBTier(args[2]);
				else
					gcdisplay.AdvanceCycle('MBTier');
				end
				toggle = 'Auto MB tier';
				status = gcinclude.MBTierText();
			end
			if (player.MainJob == 'BLM') or (player.MainJob == 'SCH') then
				if (args[1] == 'weapon') then
					gcinclude.PickCycle('Weapon', args[2]);
					toggle = 'Mage Weapon';
					status = gcdisplay.GetCycle('Weapon');
				elseif (args[1] == 'elecycle') then
					gcinclude.PickCycle('Element', args[2]);
					toggle = 'Spell Element';
					status = gcdisplay.GetCycle('Element');
				elseif (args[1] == 'helix') then
					gcinclude.DoSCHspells('helix');
				elseif (args[1] == 'weather') then
					gcinclude.DoSCHspells('weather');
				elseif (args[1] == 'nuke') then
					gcinclude.DoNukes(args[2]);
				end
				if (player.MainJob == 'BLM') then
					if (args[1] == 'death') then
						gcinclude.FlipToggle('Death', args[2]);
						toggle = 'BLM Death Set';
						status = gcdisplay.GetToggle('Death');
					end
				end
			end
		end
		if (player.MainJob == 'WHM') and (args[1] == 'nukeset') then
			gcinclude.PickCycle('NukeSet', args[2]);
			toggle = 'Nuking Gear Set';
			status = gcdisplay.GetCycle('NukeSet');
		end
		if (player.MainJob == 'PLD') or (player.MainJob == 'RUN') then
			if (args[1] == 'tankset') then
				gcinclude.PickCycle('TankSet', args[2]);
				toggle = 'Tank Gear Set';
				status = gcdisplay.GetCycle('TankSet');
			end
		end
		if (player.MainJob == 'SAM') or (player.MainJob == 'NIN') then
			if (args[1] == 'proc') then
				gcinclude.FlipToggle('PROC', args[2]);
				toggle = 'Low Damage PROC Set';
				status = gcdisplay.GetToggle('PROC');
				if (player.MainJob == 'NIN') then
					if gcdisplay.GetToggle('PROC') == true then
						AshitaCore:GetChatManager():QueueCommand(-1, '/lac disable ammo');
					else
						AshitaCore:GetChatManager():QueueCommand(-1, '/lac enable ammo');
					end
				end
			end
		end
		if (player.MainJob == 'PUP') then
			if (args[1] == 'pupmode') then
				gcinclude.PickCycle('PupMode', args[2]);
				toggle = 'Puppet Mode';
				status = gcdisplay.GetCycle('PupMode');
			end
		end
		if (player.MainJob == 'BRD') then
			if (args[1] == 'forcestring') then
				gcinclude.FlipToggle('String', args[2]);
				toggle = 'BRD Forced Harp';
				status = gcdisplay.GetToggle('String');
			elseif (args[1] == 'songlock') then
				gcinclude.FlipToggle('SongLock', args[2]);
				toggle = 'BRD Song Lock';
				status = gcdisplay.GetToggle('SongLock');
			end
		end
		if (player.MainJob == 'COR') then
			if (args[1] == 'cormsg') then
				if gcinclude.CORmsg == true then
					gcinclude.CORmsg = false;
					gcinclude.Say('COR Roll messages will no longer show');
				else
					gcinclude.CORmsg = true;
					gcinclude.Say('COR Roll messages will show now');
				end
			end
		end
		if (player.MainJob == 'SMN') then
			if (args[1] == 'siphon') then
				gcinclude.DoSiphon();
			end
		end

		if gcinclude.settings.Messages then
			gcinclude.Message(toggle, status)
		end
	end

	-- gData.GetEquipSlot lowercases all 16 slot names and the key on every call (LAC data.lua); EquipSet runs
	-- through it for every key while Hoxne is on, so each name is resolved once. Same result for every key.
	local slotNum = {};
	local function slotOf(k)
		if (type(k) ~= 'string') then return gData.GetEquipSlot(k) end
		local n = slotNum[k];
		if (n == nil) then n = gData.GetEquipSlot(k); slotNum[k] = n end
		return n;
	end

	gcinclude.WeaponSlots = T{1, 2, 3, 4};
	gcinclude.WeaponSlotNames = T{'Main', 'Sub', 'Range', 'Ammo'};
	gcinclude.WeaponCommands = T{weaponset = 'Weapons', wm = 'Weapons', mainset = 'Main', subset = 'Sub', rangeset = 'Range', ammoset = 'Ammo'};
	gcinclude.WeaponRoleNames = T{'melee', 'ranged', 'caster', 'tank'};
	gcinclude.WeaponKeywords = T{'remove', 'displaced', 'ignore'};
	gcinclude.BlockedAmmo = T{'hauksbok'};
	gcinclude.ExtraAmmo = T{'Hoxne Ampulla'};
	gcinclude.WeaponItems = {};

	function gcinclude.WeaponCycleList(cname)
		if (cname == 'Weapons') then return gcinclude.WeaponModes end
		if (cname == 'Main') then return gcinclude.MainModes end
		if (cname == 'Sub') then return gcinclude.SubModes end
		if (cname == 'Range') then return gcinclude.RangeModes end
		if (cname == 'Ammo') then return gcinclude.AmmoModes end
		if (cname == 'Hoxne') then return T{'Off', 'Locked'} end
		return nil;
	end

	function gcinclude.WeaponLabel(v)
		if (type(v) == 'string') then return v end
		if (type(v) ~= 'table') or (type(v.Name) ~= 'string') then return nil end
		if (v.AugPath ~= nil) then return v.Name .. ' (' .. tostring(v.AugPath) .. ')' end
		return v.Name;
	end

	function gcinclude.BuildWeaponCycles(mJob)
		gcinclude.WeaponItems = {};
		if (type(gcinclude.WeaponItemMap) == 'table') then
			for label, item in pairs(gcinclude.WeaponItemMap) do
				gcinclude.WeaponItems[string.lower(label)] = item;
			end
		end
		local ammo = T{};
		if (type(gcinclude.AmmoModes) == 'table') and (#gcinclude.AmmoModes > 0) then
			ammo = gcinclude.AmmoModes;
		else
			ammo:append('None');
			for _, extra in ipairs(gcinclude.ExtraAmmo) do ammo:append(extra) end
			gcinclude.AmmoModes = ammo;
		end
		for _, cname in ipairs(T{'Weapons', 'Main', 'Sub', 'Range'}) do
			local list = gcinclude.WeaponCycleList(cname);
			if (type(list) == 'table') and (#list > 0) then
				gcdisplay.CreateCycle(cname, list);
			end
		end
		if (#ammo > 1) then gcdisplay.CreateCycle('Ammo', ammo) end
	end

	function gcinclude.SetWeaponCycle(cname, val, quiet)
		local list = gcinclude.WeaponCycleList(cname);
		if (type(list) ~= 'table') then return false end
		return gcinclude.SetCycleFrom(cname, list, val, quiet);
	end

	-- /meleeset, /nukeset, /tankset, /pupmode, /weapon, /elecycle: no word cycles; a word picks that value.
	function gcinclude.PickCycle(cname, val)
		if (val == nil) or (val == '') then gcdisplay.AdvanceCycle(cname); return true end
		local list = gcdisplay.GetCycleValues(cname);
		if (type(list) ~= 'table') then return false end
		return gcinclude.SetCycleFrom(cname, list, val);
	end

	-- A cycle's name in any case ('meleeset' -> 'MeleeSet'); nil if there is none.
	function gcinclude.CycleName(name)
		if (type(name) ~= 'string') then return nil end
		if (gcdisplay.GetCycleValues(name) ~= nil) then return name end
		local want = string.lower(name);
		for cname in pairs(gcdisplay.GetCycles()) do
			if (string.lower(cname) == want) then return cname end
		end
		return nil;
	end

	-- Sets cycle cname to the value val names in list: its number, the value in any case, or one value
	-- it starts (or is part of). Says why when nothing or more than one matches, unless quiet.
	function gcinclude.SetCycleFrom(cname, list, val, quiet)
		local index = tonumber(val);
		if (index ~= nil) and (index >= 1) and (index <= #list) then
			return gcdisplay.SetCycle(cname, list[index]);
		end
		local want = string.lower(val);
		for _, v in ipairs(list) do
			if (string.lower(v) == want) then
				return gcdisplay.SetCycle(cname, v);
			end
		end
		local hits = T{};
		for _, v in ipairs(list) do
			local lv = string.lower(v);
			if (string.sub(lv, 1, string.len(want)) == want) then hits:append(v) end
		end
		if (#hits == 0) then
			for _, v in ipairs(list) do
				if (string.find(string.lower(v), want, 1, true) ~= nil) then hits:append(v) end
			end
		end
		if (#hits == 1) then
			return gcdisplay.SetCycle(cname, hits[1]);
		elseif (quiet == true) then
			return false;
		elseif (#hits > 1) then
			gcinclude.Err(cname .. ' match is ambiguous: ' .. table.concat(hits, ', '));
		else
			gcinclude.Err('No ' .. cname .. ' match for: ' .. val);
		end
		return false;
	end

	function gcinclude.WeaponCommand(cname, args)
		local force = false;
		local words = T{};
		for i = 2, #args do
			if (string.lower(args[i]) == 'force') then force = true else words:append(args[i]) end
		end
		local arg = (#words > 0) and table.concat(words, ' ') or nil;
		if (cname == 'Weapons') and (arg ~= nil) and (string.lower(arg) == 'default') and (type(gcinclude.DefaultWeapons) == 'table') then
			if (not force) and gcinclude.HoldActive() then
				gcinclude.Err('Weapons kept: at ' .. tostring(gData.GetPlayer().TP) .. ' TP (add force to override)');
				return;
			end
			for dname, dval in pairs(gcinclude.DefaultWeapons) do gcinclude.SetWeaponCycle(dname, dval, true) end
			gcinclude.ApplyWeapons(force);
			return;
		end
		local list = gcinclude.WeaponCycleList(cname);
		if (type(list) ~= 'table') or (#list == 0) then return end
		local old = gcdisplay.GetCycle(cname);
		if (arg == nil) then
			gcdisplay.AdvanceCycle(cname);
		else
			local want = string.lower(arg);
			local quiet = false;
			if (cname == 'Weapons') then
				if (want == 'default') then
					arg = gcinclude.DefaultWeapons or 'None';
					quiet = true;
				elseif (type(gcinclude.WeaponRoles) == 'table') and (gcinclude.WeaponRoles[want] ~= nil) then
					arg = gcinclude.WeaponRoles[want];
				elseif gcinclude.WeaponRoleNames:contains(want) then
					arg = nil;
				end
			end
			if (arg == nil) then return end
			if not gcinclude.SetWeaponCycle(cname, arg, quiet) then return end
		end
		local new = gcdisplay.GetCycle(cname);
		if (new == old) then return end
		if (cname ~= 'Ammo') and (not force) and gcinclude.HoldActive() then
			gcdisplay.SetCycle(cname, old);
			gcinclude.Err(cname .. ' kept on ' .. tostring(old) .. ': at ' .. tostring(gData.GetPlayer().TP) .. ' TP (add force to override)');
			return;
		end
		gcinclude.ApplyWeapons(force);
	end

	function gcinclude.IsWeaponValue(v)
		return (v ~= nil) and (v ~= 'None') and (v ~= 'Unknown');
	end

	gcinclude.HoldSlots = T{1, 2, 3};
	gcinclude.HeldSlots = {};
	gcinclude.LockedSlots = {};
	gcinclude.NextHoldCheck = 0;
	gcinclude.MissingWarned = {};
	gcinclude.LastDualWield = false;
	gcinclude.RollBuffs = T{'Fighter\'s Roll','Monk\'s Roll','Healer\'s Roll','Wizard\'s Roll','Warlock\'s Roll','Rogue\'s Roll','Gallant\'s Roll','Chaos Roll','Beast Roll','Choral Roll','Hunter\'s Roll','Samurai Roll','Ninja Roll','Drachen Roll','Evoker\'s Roll','Magus\'s Roll','Corsair\'s Roll','Puppet Roll','Dancer\'s Roll','Scholar\'s Roll','Bolter\'s Roll','Caster\'s Roll','Courser\'s Roll','Blitzer\'s Roll','Tactician\'s Roll','Allies\' Roll','Miser\'s Roll','Companion\'s Roll','Avenger\'s Roll','Naturalist\'s Roll','Runeist\'s Roll'};

	function gcinclude.UnlockWeapons()
		for slot, _ in pairs(gcinclude.HeldSlots) do
			if (gcinclude.LockedSlots[slot] == nil) then gState.Disabled[slot] = false end
		end
		gcinclude.HeldSlots = {};
	end

	gcinclude.AllSlotNames = T{'Main', 'Sub', 'Range', 'Ammo', 'Head', 'Body', 'Hands', 'Legs', 'Feet',
		'Neck', 'Waist', 'Ear1', 'Ear2', 'Ring1', 'Ring2', 'Back'};

	function gcinclude.SlotNumbers(args, first)
		local slots, unknown = T{}, T{};
		for i = first, #args do
			local want = string.lower(args[i]);
			local hit = false;
			for _, name in ipairs(gcinclude.AllSlotNames) do
				if (string.sub(string.lower(name), 1, string.len(want)) == want) then
					local n = slotOf(name);
					hit = true;
					if not slots:contains(n) then slots:append(n) end
				end
			end
			if not hit then unknown:append(args[i]) end
		end
		return slots, unknown;
	end

	function gcinclude.SlotName(index)
		for _, name in ipairs(gcinclude.AllSlotNames) do
			if (slotOf(name) == index) then return name end
		end
		return tostring(index);
	end

	function gcinclude.LockSlots(slots)
		if (slots == nil) or (#slots == 0) then slots = T{1, 2, 4} end
		for _, slot in ipairs(slots) do
			gcinclude.LockedSlots[slot] = true;
			gState.Disabled[slot] = true;
			gcinclude.HeldSlots[slot] = nil;
		end
		return slots;
	end

	function gcinclude.UnlockSlots(slots)
		if (slots == nil) or (#slots == 0) then
			slots = T{};
			for slot, _ in pairs(gcinclude.LockedSlots) do slots:append(slot) end
		end
		for _, slot in ipairs(slots) do
			gcinclude.LockedSlots[slot] = nil;
			gState.Disabled[slot] = false;
		end
		return slots;
	end

	function gcinclude.LockCommand(args)
		local wanted, unknown = gcinclude.SlotNumbers(args, 2);
		if (#unknown > 0) then
			gcinclude.Err('No such slot: ' .. table.concat(unknown, ', ') .. ' - nothing locked');
			return;
		end
		local slots = gcinclude.LockSlots(wanted);
		local names = T{};
		for _, slot in ipairs(slots) do names:append(gcinclude.SlotName(slot)) end
		gcinclude.Say('Locked: ' .. table.concat(names, ', '));
	end

	function gcinclude.UnlockCommand(args)
		local wanted, unknown = gcinclude.SlotNumbers(args, 2);
		if (#unknown > 0) then
			gcinclude.Err('No such slot: ' .. table.concat(unknown, ', ') .. ' - nothing unlocked');
			return;
		end
		gcinclude.UnlockSlots(wanted);
		gcinclude.Say('Unlocked');
	end


	-- Holds: put items on and keep those slots until released. Slots already /locked or TP-held are skipped.
	gcinclude.Holds = {}; -- key -> slot numbers it locked
	function gcinclude.ReleaseHold(key)
		local owned = gcinclude.Holds[key];
		if (owned ~= nil) then gcinclude.UnlockSlots(owned) end
		gcinclude.Holds[key] = nil;
	end

	function gcinclude.HoldSet(key, set)
		gcinclude.ReleaseHold(key);
		local out, owned = {}, T{};
		for slotName, item in pairs(set) do
			local n = slotOf(slotName);
			if (n ~= 0) and (gState.Disabled[n] ~= true) then out[slotName] = item; owned:append(n) end
		end
		if (#owned == 0) then return false end
		gFunc.ForceEquipSet(out);
		gcinclude.LockSlots(owned);
		gcinclude.Holds[key] = owned;
		return true;
	end

	-- Strip holds, one at a time: bare these slots and keep them bare.
	gcinclude.StripModes = T{
		naked = gcinclude.AllSlotNames,
		weaponsonly = T{'Head', 'Body', 'Hands', 'Legs', 'Feet', 'Neck', 'Waist', 'Ear1', 'Ear2', 'Ring1', 'Ring2', 'Back'},
		abysseaproc = T{'Head', 'Hands', 'Legs', 'Feet'},
	};

	function gcinclude.StripCommand(mode, arg)
		local cur = gcinclude.Strip;
		if (arg == 'off') or ((arg ~= 'on') and (cur == mode)) then
			if (cur ~= mode) then gcinclude.Say(mode .. ': not on'); return end
			gcinclude.ReleaseHold('strip');
			gcinclude.Strip = nil;
			gcinclude.Say(mode .. ': off');
			return;
		end
		local set = {};
		for _, slot in ipairs(gcinclude.StripModes[mode]) do set[slot] = 'remove' end
		gcinclude.Strip = gcinclude.HoldSet('strip', set) and mode or nil;
		gcinclude.Say(mode .. ': ' .. (gcinclude.Strip and 'on' or 'every slot is locked'));
	end

	-- Carried-item holds: the best carried capacity cape, the Jubilee Ring, the Dynamis Divergence neck.
	gcinclude.CarriedKeys = T{'capacity', 'jubilee', 'dynamisrp'};

	-- Every copy of an item id in the bags gear is equipped from: the first copy found, and how many in all.
	local function carriedId(id)
		local inv = AshitaCore:GetMemoryManager():GetInventory();
		local bags = gSettings.EquipBags;
		if (type(bags) ~= 'table') or (#bags == 0) then bags = {8, 10, 11, 12, 13, 14, 15, 16, 0} end
		local first, count = nil, 0;
		for _, c in ipairs(bags) do
			for i = 1, (gData.GetContainerMax(c) or 0) do
				local it = inv:GetContainerItem(c, i);
				if (it ~= nil) and (it.Id == id) and (it.Count > 0) then
					first = first or it;
					count = count + it.Count;
				end
			end
		end
		return first, count;
	end
	gcinclude.CarriedId = carriedId;

	-- Matched by name, not by GetItemByName's single id: one name can cover several ids (FFXIAH: Prime Horn
	-- 22303, then Loughnashade 22304-22307 for stages 2-5), and any of them counts.
	local idName = {};
	local function carriedName(name)
		local want = string.lower(name);
		local inv = AshitaCore:GetMemoryManager():GetInventory();
		local res = AshitaCore:GetResourceManager();
		local bags = gSettings.EquipBags;
		if (type(bags) ~= 'table') or (#bags == 0) then bags = {8, 10, 11, 12, 13, 14, 15, 16, 0} end
		local first, count = nil, 0;
		for _, c in ipairs(bags) do
			for i = 1, (gData.GetContainerMax(c) or 0) do
				local it = inv:GetContainerItem(c, i);
				if (it ~= nil) and (it.Count > 0) and (it.Id ~= 0) and (it.Id ~= 65535) then
					local n = idName[it.Id];
					if (n == nil) then
						local r = res:GetItemById(it.Id);
						n = (r ~= nil) and string.lower(r.Name[1]) or false;
						idName[it.Id] = n;
					end
					if (n == want) then
						first = first or it;
						count = count + it.Count;
					end
				end
			end
		end
		return first, count;
	end

	-- Capacity point bonus (BG-Wiki): Aptitude Mantle +1 30%, Aptitude Mantle 25%; Mecisto. Mantle 10-50% from
	-- its augment, read with LAC's gData.GetAugment ('Cap. Point'). The highest carried cape wins.
	gcinclude.CapacityValues = { ['aptitude mantle +1'] = 30, ['aptitude mantle'] = 25 };
	local function capeValue(name)
		local it = carriedName(name);
		if (it == nil) then return nil end
		local fixed = gcinclude.CapacityValues[string.lower(name)];
		if (fixed ~= nil) then return fixed end
		local ok, aug = pcall(gData.GetAugment, it);
		local cp = ok and (type(aug) == 'table') and (type(aug.Augs) == 'table') and aug.Augs['Cap. Point'] or nil;
		return (type(cp) == 'table') and tonumber(cp.Value) or 0;
	end

	-- Dynamis - Divergence job necks, best first: +2, +1, base. Item ids 25417 + 6 * (job - 1) + 0/1/2, all 66
	-- checked on FFXIAH (25417 Warrior's Beads ... 25545 Futhark Torque +2); each is still checked to be a neck
	-- this main job can wear before it is used.
	local function dynamisNeck()
		local job = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
		if (job < 1) or (job > 22) then return nil end
		local base = 25417 + 6 * (job - 1);
		for _, id in ipairs({ base + 2, base + 1, base }) do
			local r = AshitaCore:GetResourceManager():GetItemById(id);
			if (r ~= nil) and (bit.band(r.Slots, gcinclude.SlotBits.Neck) ~= 0)
				and (bit.band(r.Jobs, bit.lshift(1, job)) ~= 0) and (carriedId(id) ~= nil) then
				return r.Name[1];
			end
		end
		return nil;
	end

	function gcinclude.CarriedPick(key)
		if (key == 'capacity') then
			local best, bestValue = nil, -1;
			for _, name in ipairs(gcinclude.settings.CapacityCapes or {}) do
				local v = capeValue(name);
				if (v ~= nil) and (v > bestValue) then best, bestValue = name, v end
			end
			if (best ~= nil) then return 'Back', best end
		elseif (key == 'jubilee') and carriedName('Jubilee Ring') then
			return (gcinclude.settings.JubileeSlot or 'Ring1'), 'Jubilee Ring';
		elseif (key == 'dynamisrp') then
			local neck = dynamisNeck();
			if (neck ~= nil) then return 'Neck', neck end
		end
		return nil;
	end

	-- Low ammo and Utsusemi tool warnings; nothing is cancelled (BG-Wiki Barrage: it fires only as many shots
	-- as you have ammo). Says so the first time a count is at or under the limit, then every 10 fewer, and at 0.
	local lowWarned = {};
	local function warnLow(label, count, limit)
		if ((limit or 0) <= 0) then return end
		if (count > limit) then lowWarned[label] = nil; return end
		local last = lowWarned[label];
		if (last ~= nil) and (count > last - 10) and not ((count == 0) and (last ~= 0)) then return end
		lowWarned[label] = count;
		gcinclude.Err(label .. ': ' .. count .. ' left');
	end

	-- kind: 'shot' (preshot), 'ws' (weaponskill) or nil (precast). Utsusemi uses Shihei, or Shikanofuda on a
	-- NIN main (BG-Wiki/FFXIclopedia), from your inventory.
	function gcinclude.CheckSupplies(kind)
		local a = gData.GetAction();
		if (a == nil) or (a.Name == nil) then return end
		local cfg = gcinclude.settings;
		if (kind == nil) then
			if (a.ActionType ~= 'Spell') or (gcinclude.Family(a.Name) ~= 'Utsusemi') or (gcauto == nil) then return end
			local n = gcauto.ItemCount('Shihei');
			local p = gData.GetPlayer();
			if (p ~= nil) and (p.MainJob == 'NIN') then n = n + gcauto.ItemCount('Shikanofuda') end
			warnLow('Utsusemi tools', n, cfg.NinjaToolWarn);
			return;
		end
		if (kind == 'ws') and ((not gcinclude.DistanceWS:contains(a.Name)) or gcinclude.NoAmmoWS:contains(a.Name)) then return end
		if (gcinclude.BuffCount('Unlimited Shot') > 0) then return end
		local equip = gData.GetEquipment();
		local ammo = (equip ~= nil) and equip.Ammo or nil;
		if (ammo == nil) or (type(ammo.Name) ~= 'string') then return end
		local r = AshitaCore:GetResourceManager():GetItemByName(ammo.Name, 0);
		if (r == nil) or not T{25, 26, 27}:contains(r.Skill) then return end -- arrows, bullets, throwing
		local _, count = carriedId(r.Id);
		warnLow(ammo.Name, count, cfg.AmmoWarn);
	end

	function gcinclude.CarriedCommand(key, arg)
		if (arg == 'off') or ((arg ~= 'on') and (gcinclude.Holds[key] ~= nil)) then
			gcinclude.ReleaseHold(key);
			gcinclude.Say(key .. ': off');
			return;
		end
		local slot, item = gcinclude.CarriedPick(key);
		if (item == nil) then gcinclude.Say(key .. ': none carried'); return end
		gcinclude.Say(key .. ': ' .. (gcinclude.HoldSet(key, { [slot] = item }) and item or (slot .. ' is locked')));
	end

	-- /lockstyleset after the gear settles.
	function gcinclude.ApplyLockstyle(n, delay)
		n = tonumber(n or gcinclude.LockstyleSet or gcinclude.settings.LockstyleSet);
		if (n == nil) then return false end
		local function go() AshitaCore:GetChatManager():QueueCommand(-1, '/lockstyleset ' .. n) end
		if ((delay or 4) > 0) then go:once(delay or 4) else go() end
		return true;
	end

	function gcinclude.HoldActive()
		local guard = gcinclude.settings.WeaponTPGuard or 0;
		if (guard <= 0) then return false end
		return (AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0) >= guard); -- any status: a Main/Sub/Range swap resets TP idle too
	end

	-- Asleep: Main/Sub/Range named in the Sleeping set skip the TP hold, so a wake-up weapon can go on
	-- (BG-Wiki Prime weapons: "Slowly devours your soul" drains HP/MP per tick, which wakes you from Sleep).
	function gcinclude.SleepFreeSlots()
		if (gcinclude.BuffCount('Sleep') == 0) then return nil end
		local set = gcinclude.FindSet('Sleeping') or gcinclude.sets.Sleeping;
		if (type(set) ~= 'table') then return nil end
		local free = nil;
		for k, _ in pairs(set) do
			local slot = slotOf(k);
			if gcinclude.HoldSlots:contains(slot) then free = free or {}; free[slot] = true end
		end
		return free;
	end

	gcinclude.SleepFreed = {}; -- slots the last UpdateHold let go for the Sleeping set
	function gcinclude.UpdateHold()
		gcinclude.SleepFreed = {};
		if gcinclude.HoldActive() then
			local free = gcinclude.SleepFreeSlots();
			for _, slot in ipairs(gcinclude.HoldSlots) do
				if (free ~= nil) and free[slot] then
					gcinclude.SleepFreed[slot] = true;
					if (gcinclude.HeldSlots[slot] ~= nil) then
						if (gcinclude.LockedSlots[slot] == nil) then gState.Disabled[slot] = false end
						gcinclude.HeldSlots[slot] = nil;
					end
				elseif (gcinclude.HeldSlots[slot] == nil) and (gcinclude.LockedSlots[slot] == nil) and (gState.Disabled[slot] ~= true) then
					gState.Disabled[slot] = true;
					gcinclude.HeldSlots[slot] = true;
				end
			end
		elseif (next(gcinclude.HeldSlots) ~= nil) then
			gcinclude.UnlockWeapons();
		end
	end

	-- Enchanted item use (/gce, /hoxne use). The equip delay runs from when the server has the item on,
	-- so the countdown starts once the slot really holds it (inventory memory, as LAC's GetCurrentEquip
	-- reads it), not at the command. Then /item, retried until the use shows up in 0x0028 (XiPackets:
	-- cmd_no 9 Item (Start) value = item id, 0 if interrupted; cmd_no 5 Item (Finish) cmd_arg = item id).
	-- The slot stays locked until that finish packet, so normal gear can't come back mid-use.
	-- Several can run at once (one per slot).
	gcinclude.Enchants = {}; -- [LAC slot] = { item, id, slot, index, wasLocked, delay, start, equippedAt, nextTry, tries, doneAt }
	local ENCHANT_MARGIN = 3.0;    -- after the equip delay, before the first try (the server refuses ~3s past it: Rahvin's notes)
	local ENCHANT_RETRY = 2.0;     -- between tries while no Item (Start) is seen
	local ENCHANT_TRIES = 5;
	local ENCHANT_EQUIP_WAIT = 10; -- give up if the item never shows up in the slot
	local ENCHANT_USE_WAIT = 15;   -- after Item (Start), wait this long for Item (Finish), then retry

	local function equippedItem(slot, inv)
		inv = inv or AshitaCore:GetMemoryManager():GetInventory();
		local e = inv:GetEquippedItem(slot - 1);
		local index = (e ~= nil) and bit.band(e.Index, 0x00FF) or 0;
		if (index == 0) then return nil end
		local item = inv:GetContainerItem(bit.band(e.Index, 0xFF00) / 256, index);
		return ((item ~= nil) and (item.Count > 0)) and item or nil;
	end
	local function equippedId(slot)
		local item = equippedItem(slot);
		return (item ~= nil) and item.Id or nil;
	end
	gcinclude.EquippedId = equippedId;

	-- When each slot's current item went on (first seen there): a use has to wait out its equip delay from then,
	-- also when the item was put on by a set just before (e.g. Hoxne's 5s use delay, BG-Wiki).
	local slotSeen = {};
	local function trackSlots(now)
		local inv = AshitaCore:GetMemoryManager():GetInventory(); -- once for all 16 slots
		for slot = 1, 16 do
			local item = equippedItem(slot, inv);
			local id = (item ~= nil) and item.Id or nil;
			local s = slotSeen[slot];
			if (id == nil) then
				slotSeen[slot] = nil;
			elseif (s == nil) or (s.id ~= id) then
				slotSeen[slot] = { id = id, at = now };
			end
		end
	end

	-- Enchanted-equipment extdata (Windower libs/extdata.lua decode.Enchanted): byte 1 = 1, byte 2 charges left,
	-- bytes 5-8 next use time, bytes 9-12 activation time (equip time + equip delay), both server timestamps.
	-- Only differences between the two are used, so no epoch is needed.
	local function enchantInfo(item)
		local x = (item ~= nil) and item.Extra or nil;
		if (type(x) ~= 'string') or (#x < 12) or (string.byte(x, 1) ~= 1) then return nil end
		return { charges = string.byte(x, 2), nextUse = struct.unpack('I', x, 5), activation = struct.unpack('I', x, 9) };
	end

	function gcinclude.ReleaseEnchant(index)
		local e = gcinclude.Enchants[index];
		if (e == nil) then return end
		if (e.wasLocked ~= true) then gcinclude.UnlockSlots(T{index}) end
		gcinclude.Enchants[index] = nil;
	end

	local function enchant_step(e, now)
		if (e.doneAt ~= nil) then
			if (now >= e.doneAt) then gcinclude.ReleaseEnchant(e.index) end
			return;
		end
		if (e.equippedAt == nil) then
			local item = equippedItem(e.index);
			if (item ~= nil) and (item.Id == e.id) then
				e.equippedAt = now;
				local seen = slotSeen[e.index];
				local onSince = now;
				if e.alreadyOn then onSince = ((seen ~= nil) and (seen.id == e.id)) and seen.at or -math.huge end
				e.nextTry = math.max(now + 0.5, onSince + e.delay + ENCHANT_MARGIN);
				local info = enchantInfo(item);
				e.extPending = (info ~= nil) and (e.alreadyOn ~= true);
			elseif (now > e.start + ENCHANT_EQUIP_WAIT) then
				gcinclude.Err(e.item .. ': never showed up in ' .. string.lower(e.slot) .. ', released');
				gcinclude.ReleaseEnchant(e.index);
			end
			return;
		end
		-- Reuse timer, once the extdata shows this equip (activation changed): the equip happened at
		-- activation - delay, so the item is usable reuse = next use - (activation - delay) seconds after it.
		-- A few seconds past the delay: the first try waits for it. Never refuses: the game says no itself.
		if (e.extPending == true) then
			local info = enchantInfo(equippedItem(e.index));
			if (info == nil) then
				e.extPending = false;
			elseif (e.preAct == nil) or (info.activation ~= e.preAct) then
				e.extPending = false;
				local reuse = info.nextUse - (info.activation - e.delay);
				if (reuse > e.delay) and (reuse <= e.delay + 5) then
					e.nextTry = math.max(e.nextTry, e.equippedAt + reuse + ENCHANT_MARGIN);
				end
			elseif (now > e.equippedAt + 2) then
				e.extPending = false;
			end
		end
		if (now < e.nextTry) then return end
		if (gState.PlayerAction ~= nil) then e.nextTry = now + 0.5; return end -- an action is running: wait, don't spend a try
		if (e.tries >= ENCHANT_TRIES) then
			gcinclude.Err(e.item .. ': not used after ' .. e.tries .. ' tries, released');
			gcinclude.ReleaseEnchant(e.index);
			return;
		end
		e.tries = e.tries + 1;
		e.nextTry = now + ENCHANT_RETRY;
		AshitaCore:GetChatManager():QueueCommand(-1, '/item "' .. e.item .. '" <me>');
	end

	function gcinclude.CheckEnchantHold()
		if (next(gcinclude.Enchants) == nil) then return end
		local now = os.clock();
		for _, e in pairs(gcinclude.Enchants) do enchant_step(e, now) end
	end

	-- From gcauto's 0x0028 reader: my item use started (cmd 9), was interrupted (cmd 9, id 0) or finished (cmd 5).
	function gcinclude.OnItemAction(cmd, id)
		local now = os.clock();
		for _, e in pairs(gcinclude.Enchants) do
			if (e.doneAt == nil) and (e.equippedAt ~= nil) then
				if (cmd == 5) and (id == e.id) then
					e.doneAt = now + 0.5;
				elseif (cmd == 9) and (id == e.id) then
					e.nextTry = now + ENCHANT_USE_WAIT;
				elseif (cmd == 9) and (id == 0) and (e.nextTry > now + ENCHANT_RETRY) then
					e.nextTry = now + ENCHANT_RETRY; -- an item use was interrupted: try again soon
				end
			end
		end
	end

	function gcinclude.HoldTick()
		local now = os.clock();
		if (now < gcinclude.NextHoldCheck) then return end
		gcinclude.NextHoldCheck = now + 0.1;
		if gcinclude.Zoning() then return end -- nothing sent or swapped by itself mid-zone
		trackSlots(now);
		gcinclude.CheckEnchantHold();
		if gcinclude.CheckDualWieldChange(now) then return end -- forced 1h swap: let it land before the hold re-checks
		gcinclude.CheckHoxneAuto(now);
		gcinclude.CheckSleepStoneskin(now);
		gcinclude.CheckZoneNotes();
		gcaction.Tick();
		if (gcinclude.HoldSuspended == true) then
			if (gState.PlayerAction ~= nil) then return end
			gcinclude.HoldSuspended = false;
		end
		gcinclude.UpdateHold();
	end

	gcinclude.SlotBits = T{ Main = 1, Sub = 2, Range = 4, Ammo = 8, Head = 16, Body = 32,
		Hands = 64, Legs = 128, Feet = 256, Neck = 512, Waist = 1024, Ear1 = 2048, Ear2 = 4096,
		Ring1 = 8192, Ring2 = 16384, Back = 32768 }; -- item resource Slots bits: 2^(LAC slot - 1), as LAC equip.lua tests them

	gcinclude.WeakTo = T{ Fire = 'Water', Ice = 'Fire', Wind = 'Ice', Earth = 'Wind',
		Thunder = 'Earth', Water = 'Thunder', Light = 'Dark', Dark = 'Light' };

	-- Day/weather value for an element, in %: day +10, single weather +10, double weather +25; the element
	-- strong against it (WeakTo) subtracts the same. An obi forces all of it, bonus and penalty (BG
	-- Category:Elemental Obi: Hachirin keeps the forced penalty; example day +10 / double weather -25).
	function gcinclude.DayWeatherNet(element)
		local env = gData.GetEnvironment();
		if (env == nil) or (element == nil) then return 0 end
		local against = gcinclude.WeakTo[element];
		local double = (type(env.Weather) == 'string') and (string.find(env.Weather, 'x2', 1, true) ~= nil);
		local function weather(el)
			if (el ~= nil) and (env.WeatherElement == el) then return double and 25 or 10 end
			return 0;
		end
		local net = weather(element) - weather(against);
		if (env.DayElement == element) then net = net + 10 end
		if (against ~= nil) and (env.DayElement == against) then net = net - 10 end
		return net;
	end

	-- Orpheus's Sash: affinity rises as the target gets closer. BG documents only the ends: +15 at <= 1.93',
	-- +1 at >= 13'. In between it is interpolated linearly through settings.OrpheusPoints - an assumption,
	-- not a published formula. Add measured {distance, value} points there to refine it.
	function gcinclude.OrpheusValue(distance)
		if (distance == nil) then return nil end
		local pts = gcinclude.settings.OrpheusPoints;
		if (type(pts) ~= 'table') or (#pts == 0) then return nil end
		if (distance <= pts[1][1]) then return pts[1][2] end
		for i = 2, #pts do
			local a, b = pts[i - 1], pts[i];
			if (distance <= b[1]) then
				return a[2] + (b[2] - a[2]) * (distance - a[1]) / (b[1] - a[1]);
			end
		end
		return pts[#pts][2];
	end

	function gcinclude.ElementCfg()
		return gcinclude.ElementGear or gcinclude.settings.ElementGear;
	end

	function gcinclude.ElementWaist(element, noObi, noSash)
		local cfg = gcinclude.ElementCfg();
		if (type(cfg) ~= 'table') or (element == nil) then return nil end
		local obi = (type(cfg.Obis) == 'table') and cfg.Obis[element] or nil;
		obi = obi or cfg.AnyObi;
		if (noObi == true) then obi = nil end
		local obiValue = (obi ~= nil) and gcinclude.DayWeatherNet(element) or 0;
		local sashValue = nil;
		if (cfg.Distance ~= nil) and (noSash ~= true) then
			local target = gData.GetActionTarget() or gData.GetTarget(); -- the action's target, not whatever is selected
			local d = (target ~= nil) and tonumber(target.Distance) or nil;
			if (d ~= nil) and ((cfg.DistanceMax == nil) or (d <= cfg.DistanceMax)) then
				sashValue = gcinclude.OrpheusValue(d);
			end
		end
		if (obiValue > 0) and ((sashValue == nil) or (obiValue > sashValue)) then return obi, obiValue end
		if (sashValue ~= nil) then return cfg.Distance, sashValue end
		return nil;
	end

	-- gFunc.ForceEquipSet sends packets directly and ignores gState.Disabled, so /lock and the TP hold
	-- would be bypassed. Engine force-equips drop disabled slots first.
	function gcinclude.ForceUnlocked(set)
		set = gcinclude.DropAmmoWeapon(set);
		if (type(set) ~= 'table') then return end
		local out, n = {}, 0;
		for k, v in pairs(set) do
			local slot = slotOf(k);
			if (slot ~= 0) and (gState.Disabled[slot] ~= true) then
				out[k] = v;
				n = n + 1;
			end
		end
		if (n > 0) then gFunc.ForceEquipSet(out) end
	end

	-- Received set: layered by CheckReceived in HandleDefault until the spell lands or is interrupted
	-- (EndReceived, from gcauto's 0x0028 reader), with ReceivedWindow as the fallback.
	-- Put on at once only when you are not mid-action, so your own precast/midcast gear is never replaced.
	-- from = the caster's server id when known (packet); nil from a Multisend notice.
	function gcinclude.StartReceived(spellName, from)
		local setName = gcinclude.ReceivedSetFor(spellName);
		if (setName == nil) then return end
		local set = gcinclude.FindSet(setName);
		if (set == nil) or (next(set) == nil) then return end
		local now = os.clock();
		local ended = gcinclude.ReceivedEnded;
		if (from == nil) and (ended ~= nil) and (ended.set == set) and ((now - ended.at) < 2) then return end -- notice after it landed
		local same = (gcinclude.ReceivedSet == set) and (now <= (gcinclude.ReceivedUntil or 0));
		if (from ~= nil) then gcinclude.ReceivedFrom = from elseif not same then gcinclude.ReceivedFrom = nil end
		gcinclude.ReceivedSet = set;
		gcinclude.ReceivedUntil = now + (gcinclude.settings.ReceivedWindow or 8);
		if (gState.PlayerAction == nil) then gcinclude.ForceUnlocked(set) end
	end

	-- The caster's spell finished or was interrupted. With no known caster (Multisend notice), only a
	-- spell landing on me ends it. LAC runs HandleDefault on its next packet, which puts normal gear back.
	function gcinclude.EndReceived(from, hitMe)
		if (gcinclude.ReceivedSet == nil) then return end
		if (gcinclude.ReceivedFrom ~= nil) then
			if (from ~= gcinclude.ReceivedFrom) then return end
		elseif (hitMe ~= true) then
			return;
		end
		gcinclude.ReceivedEnded = { set = gcinclude.ReceivedSet, at = os.clock() };
		gcinclude.ReceivedSet, gcinclude.ReceivedFrom = nil, nil;
	end

	function gcinclude.ReceivedSetFor(name)
		if (type(name) ~= 'string') then return nil end
		local lower = string.lower(name);
		local best, bestLen = nil, -1;
		for prefix, setName in pairs(gcinclude.settings.ReceivedSets) do
			if (string.sub(lower, 1, string.len(prefix)) == prefix) and (string.len(prefix) > bestLen) then
				best, bestLen = setName, string.len(prefix);
			end
		end
		return best;
	end

	-- Area of a received spell: entity index of its center, or nil for a single-target cast.
	-- BG-Wiki/FFXIclopedia: Curaga 10' around its target; Cura, Protectra, Shellra 10' around the caster;
	-- Majesty spreads Cure and Protect, Accession the next Healing or Enhancing white magic, 10' around the target.
	gcinclude.AoeOnTarget = T{ 'curaga' };
	gcinclude.AoeOnCaster = T{ 'cura', 'protectra', 'shellra' };
	gcinclude.AoeRange = 10;
	function gcinclude.AoeCenter(action, target)
		local fam = string.gsub(string.lower(action.Name), ' [ivx]+$', '');
		local party = AshitaCore:GetMemoryManager():GetParty();
		if gcinclude.AoeOnCaster:contains(fam) then return party:GetMemberTargetIndex(0) end
		local tindex = (target ~= nil) and target.Index or nil;
		if gcinclude.AoeOnTarget:contains(fam) then return tindex end
		if (gcinclude.BuffCount('Majesty') > 0) and ((fam == 'cure') or (fam == 'protect')) then return tindex end
		if (gcinclude.BuffCount('Accession') > 0) and (action.Type == 'White Magic')
			and ((action.Skill == 'Healing Magic') or (action.Skill == 'Enhancing Magic')) then return tindex end
		return nil;
	end

	local function entity_distance(a, b)
		local e = AshitaCore:GetMemoryManager():GetEntity();
		local dx = e:GetLocalPositionX(a) - e:GetLocalPositionX(b);
		local dy = e:GetLocalPositionY(a) - e:GetLocalPositionY(b);
		local dz = e:GetLocalPositionZ(a) - e:GetLocalPositionZ(b);
		return math.sqrt(dx * dx + dy * dy + dz * dz);
	end

	-- Tells my own boxes a received spell is coming: the target, and for an area spell every box in my
	-- party within AoeRange of its center.
	function gcinclude.AnnounceCast()
		local action = gData.GetAction();
		if (action == nil) or (action.Name == nil) then return end
		if (gcinclude.ReceivedSetFor(action.Name) == nil) then return end
		local target = gData.GetActionTarget();
		local me = gData.GetPlayer();
		local myName = (me ~= nil) and me.Name or nil;
		local told = {};
		local function tell(name)
			if (name == nil) or (name == '') or (name == myName) or told[name] then return end
			if not gcinclude.IsMyBox(name) then return end -- other players' characters: no Multisend
			told[name] = true;
			AshitaCore:GetChatManager():QueueCommand(-1, '/ms sendto ' .. name .. ' /lac fwd received ' .. action.Name);
		end
		if (target ~= nil) and ((target.Type == 'PC') or (target.Type == 'Party') or (target.Type == 'Alliance')) then
			tell(target.Name);
		end
		local center = gcinclude.AoeCenter(action, target);
		if (center == nil) or (center == 0) then return end
		local party = AshitaCore:GetMemoryManager():GetParty();
		for i = 1, 5 do
			local idx = party:GetMemberTargetIndex(i);
			if (party:GetMemberIsActive(i) == 1) and (idx ~= nil) and (idx > 0)
				and (entity_distance(center, idx) <= gcinclude.AoeRange) then
				tell(party:GetMemberName(i));
			end
		end
	end

	-- One of my own boxes: listed in settings.MyBoxes, or running this engine now (fresh HUD state file).
	function gcinclude.IsMyBox(name)
		if (type(name) ~= 'string') then return false end
		local lname = string.lower(name);
		for _, n in ipairs(gcinclude.settings.MyBoxes or {}) do
			if (string.lower(n) == lname) then return true end
		end
		return (gchud ~= nil) and (gchud.IsBox ~= nil) and gchud.IsBox(name);
	end

	function gcinclude.ReceivedCommand(args)
		local words = T{};
		for i = 2, #args do words:append(args[i]) end
		if (#words == 0) then return end
		gcinclude.StartReceived(table.concat(words, ' '));
	end

	function gcinclude.CheckReceived()
		if (gcinclude.ReceivedSet == nil) then return end
		if (os.clock() > (gcinclude.ReceivedUntil or 0)) then
			gcinclude.ReceivedSet = nil;
			return;
		end
		gFunc.EquipSet(gcinclude.ReceivedSet);
	end

	function gcinclude.ElementKept(slot)
		local cfg = gcinclude.ElementCfg();
		local keep = (type(cfg) == 'table') and cfg.Keep or nil;
		if (type(keep) ~= 'table') or (#keep == 0) then return false end
		local equip = gData.GetEquipment();
		if (equip == nil) or (equip[slot] == nil) or (equip[slot].Name == nil) then return false end
		local worn = string.lower(equip[slot].Name);
		for _, item in ipairs(keep) do
			if (string.lower(item) == worn) then return true end
		end
		return false;
	end

	-- Zodiac Ring: the six elements only, never Lightsday/Darksday, never cures (BG-Wiki Zodiac Ring).
	function gcinclude.ElementRing(element)
		local cfg = gcinclude.ElementCfg();
		if (type(cfg) ~= 'table') or (cfg.Ring == nil) or (element == nil) then return nil end
		if (element == 'Light') or (element == 'Dark') then return nil end
		local env = gData.GetEnvironment();
		if (env == nil) or (env.DayElement ~= element) then return nil end
		return cfg.Ring, (cfg.RingSlot or 'Ring2');
	end

	gcinclude.NinjutsuNukes = T{'Katon', 'Hyoton', 'Huton', 'Doton', 'Raiton', 'Suiton'};
	gcinclude.QuickDrawElement = { ['Fire Shot'] = 'Fire', ['Ice Shot'] = 'Ice', ['Wind Shot'] = 'Wind', ['Earth Shot'] = 'Earth',
		['Thunder Shot'] = 'Thunder', ['Water Shot'] = 'Water', ['Light Shot'] = 'Light', ['Dark Shot'] = 'Dark' };

	-- Element gear per action (BG-Wiki): nukes and blue magic in ElementSkills, elemental ninjutsu, Quick Draw
	-- (day/weather count) and elemental WS get obi/Orpheus and the back piece; helixes always get day and
	-- weather, so never an obi; Cure/Cura/Curaga get Light day/weather (+10/+10/+25, the obi forces it) but no
	-- sash; Zodiac Ring only on ElementSkills spells (see ElementRing).
	function gcinclude.CheckElementGear()
		local action = gData.GetAction();
		if (action == nil) or (type(action.Name) ~= 'string') then return end
		local element, opts = nil, {};
		if (action.ActionType == 'Spell') then
			local fam = gcinclude.Family(action.Name);
			local skills = gcinclude.settings.ElementSkills;
			if gcinclude.HelixSpells:contains(fam) then
				element, opts.noObi = action.Element, true;
			elseif (type(skills) == 'table') and skills:contains(action.Skill) then
				element = action.Element;
			elseif (action.Skill == 'Ninjutsu') and gcinclude.NinjutsuNukes:contains(fam) then
				element, opts.noRing = action.Element, true;
			elseif (action.Skill == 'Healing Magic') and ((gcinclude.ElementCfg() or {}).Cures ~= false)
				and T{'Cure', 'Cura', 'Curaga'}:contains(fam) then
				element, opts.noSash, opts.noRing = 'Light', true, true;
				opts.noBack = (gcinclude.ElementCfg() or {}).BackOnCures ~= true;
			end
		elseif (action.ActionType == 'Weaponskill') then
			local list = gcinclude.settings.ElementalWS;
			if (type(list) == 'table') then element = list[action.Name] end
			opts.noRing = true; -- Zodiac-type ring only on spells
		elseif (action.ActionType == 'Ability') then
			element, opts.noRing = gcinclude.QuickDrawElement[action.Name], true;
		end
		if (element == nil) or (element == 'Non-Elemental') then return end
		gcinclude.ApplyElementGear(element, action.Name, opts);
	end

	function gcinclude.ApplyElementGear(element, label, opts)
		if (type(opts) ~= 'table') then opts = { noRing = (opts == true) } end -- old (element, label, noRing) form
		local set = {};
		local report = T{};
		local waist, value = gcinclude.ElementWaist(element, opts.noObi, opts.noSash);
		if (waist ~= nil) then
			if gcinclude.ElementKept('Waist') then
				report:append('waist kept');
			else
				set.Waist = waist;
				report:append('waist ' .. waist .. string.format(' (+%.1f%%)', value));
			end
		end
		local cfg = gcinclude.ElementCfg();
		if (opts.noBack ~= true) and (type(cfg) == 'table') and (cfg.Back ~= nil) then
			local env = gData.GetEnvironment();
			local obiOn = (set.Waist ~= nil) and (set.Waist ~= cfg.Distance);
			local dayHit = (env ~= nil) and (env.DayElement == element);
			local weatherHit = (env ~= nil) and (env.WeatherElement == element) and (obiOn or (opts.noObi == true));
			if dayHit or weatherHit then
				if gcinclude.ElementKept('Back') then
					report:append('back kept');
				else
					set.Back = cfg.Back;
					report:append('back ' .. cfg.Back .. (dayHit and ' (day)' or ' (weather)'));
				end
			end
		end
		local ring, slot = nil, nil;
		if (opts.noRing ~= true) then ring, slot = gcinclude.ElementRing(element) end
		if (ring ~= nil) then
			if gcinclude.ElementKept(slot) then
				report:append(string.lower(slot) .. ' kept');
			else
				set[slot] = ring;
				report:append(string.lower(slot) .. ' ' .. ring);
			end
		end
		if (next(set) == nil) then return end
		gFunc.EquipSet(set);
		if (gcinclude.settings.ElementReport == true) then
			print(chat.header('ShaySwap'):append(chat.message((label or element) .. ' [' .. element .. ']: ' .. table.concat(report, ', '))));
		end
	end

	function gcinclude.CheckLightBonus()
		local action = gData.GetAction();
		if (action == nil) or (action.Skill ~= 'Healing Magic') then return end
		local set = gcinclude.FindSet('LightBonus');
		if (set ~= nil) then gFunc.EquipSet(set) end
	end

	function gcinclude.IsHoldExempt()
		local action = gData.GetAction();
		if (action == nil) then return false end
		if (action.ActionType == 'Spell') then
			return gcinclude.settings.HoldExemptSkills:contains(action.Skill);
		elseif (action.ActionType == 'Ability') then
			return gcinclude.settings.HoldExemptAbilities:contains(action.Type);
		end
		return false;
	end

	function gcinclude.CheckHoldExempt()
		if gcinclude.IsHoldExempt() then
			gcinclude.UnlockWeapons();
			gcinclude.HoldSuspended = true;
		end
	end

	gcinclude.SmartKeep = false;

	function gcinclude.SmartSwapCommand(args)
		local v = (args[2] ~= nil) and string.lower(args[2]) or nil;
		if (v == 'on') then gcinclude.settings.SmartSwap = true;
		elseif (v == 'off') then gcinclude.settings.SmartSwap = false;
		else gcinclude.settings.SmartSwap = not (gcinclude.settings.SmartSwap == true) end
		gcinclude.Say('SmartSwap: ' .. (gcinclude.settings.SmartSwap and 'On' or 'Off'));
	end

	gcinclude.AutoGearKeys = T{ regen = 'RegenGearHPP', refresh = 'RefreshGearMPP', dt = 'DTGearHPP', petdt = 'PetDTGearHPP' };

	function gcinclude.AutoGearCommand(args)
		local cfg = gcinclude.settings;
		local what = (args[2] ~= nil) and string.lower(args[2]) or nil;
		if (what == 'on') then cfg.AutoGear = true;
		elseif (what == 'off') then cfg.AutoGear = false;
		elseif (what ~= nil) and (gcinclude.AutoGearKeys[what] ~= nil) and (tonumber(args[3]) ~= nil) then
			cfg[gcinclude.AutoGearKeys[what]] = math.max(0, math.min(100, tonumber(args[3])));
		elseif (what ~= nil) then
			gcinclude.Err('usage: /autogear [on|off|regen N|refresh N|dt N|petdt N], 0 = never');
			return;
		end
		print(chat.header('GCinclude'):append(chat.message(string.format('AutoGear %s | regen <%d%% hp, refresh <%d%% mp (both out of combat) | dt <%d%% hp | petdt <%d%% pet hp',
			(cfg.AutoGear ~= false) and 'on' or 'off', cfg.RegenGearHPP or 0, cfg.RefreshGearMPP or 0, cfg.DTGearHPP or 0, cfg.PetDTGearHPP or 0))));
	end

	function gcinclude.SmartKeepFor(action)
		local cfg = gcinclude.settings;
		if (cfg.SmartSwap ~= true) or (action == nil) or (action.ActionType ~= 'Spell') or (type(action.Name) ~= 'string') then return false end
		local player = gData.GetPlayer();
		if (player == nil) or (player.TP < (cfg.SmartSwapTP or 1)) then return false end
		local lname = string.lower(action.Name);
		for _, n in ipairs(cfg.NoWeaponSpells or {}) do
			if (string.lower(n) == lname) then return true end
		end
		local equip = gData.GetEquipment();
		if (equip == nil) then return false end
		for _, rule in ipairs(cfg.KeepWeaponsFor or {}) do
			local hit = false;
			for _, pre in ipairs(rule.Spells or {}) do
				local lp = string.lower(pre);
				if (string.sub(lname, 1, string.len(lp)) == lp) then hit = true end
			end
			if hit then
				for _, slot in ipairs(T{'Main', 'Sub'}) do
					local worn = equip[slot];
					if (worn ~= nil) and (type(worn.Name) == 'string') then
						local wn = string.lower(worn.Name);
						for _, item in ipairs(rule.Worn or {}) do
							if (string.lower(item) == wn) then return true end
						end
					end
				end
			end
		end
		return false;
	end

	function gcinclude.StripWeaponSwaps()
		gFunc.Equip('Main', 'ignore');
		gFunc.Equip('Sub', 'ignore');
		gFunc.Equip('Range', 'ignore');
	end

	-- Trace phase per handler: 'pre' waits for its 'mid' so a spell or shot prints one line.
	gcinclude.TracePhase = { HandlePrecast = 'pre', HandleMidcast = 'mid', HandlePreshot = 'pre', HandleMidshot = 'mid' };
	gcinclude.Checked = T{'HandlePrecast', 'HandleAbility'};

	function gcinclude.WrapHoldHandlers()
		if (gProfile == nil) or (gProfile.GcHoldWrapped == true) then return end
		gcaction.Hook();
		for _, name in ipairs(T{'HandlePrecast', 'HandleAbility', 'HandleMidcast'}) do
			local original = gProfile[name];
			if (type(original) == 'function') then
				gProfile[name] = function(...)
					if gcinclude.Checked:contains(name) and gcaction.Check() then gFunc.CancelAction(); return end
					gcaction.TraceStart();
					gcinclude.CheckHoldExempt();
					if (name ~= 'HandleAbility') then gcinclude.LiftAminonForExempt() end
					if (name == 'HandleAbility') then gcinclude.AnnounceCast() end -- Waltzes to your own boxes
					if (name == 'HandlePrecast') then
						gcinclude.AnnounceCast();
						gcinclude.SmartKeep = gcinclude.SmartKeepFor(gData.GetAction());
					end
					local result = original(...);
					if (name == 'HandleMidcast') then
						gcinclude.CheckBuffSets('Buffs_Midcast');
						gcinclude.CheckAbsorb();
						gcinclude.CheckLightBonus();
						gcinclude.CheckElementGear();
						gcinclude.CheckSIR();
						gcinclude.CheckExemptStateSets();
					elseif (name == 'HandleAbility') then
						gcinclude.CheckElementGear(); -- Quick Draw
					else
						gcinclude.CheckSupplies(); -- Utsusemi tools
					end
					if (gcinclude.SmartKeep == true) and ((name == 'HandlePrecast') or (name == 'HandleMidcast')) then
						gcinclude.StripWeaponSwaps();
					end
					gcaction.TraceEnd(gcinclude.TracePhase[name]);
					return result;
				end
			end
		end
		local ws = gProfile.HandleWeaponskill;
		if (type(ws) == 'function') then
			gProfile.HandleWeaponskill = function(...)
				if gcaction.Check() then gFunc.CancelAction(); return end
				gcaction.TraceStart();
				local result, trail = gcinclude.TrackEars(function(...)
					local r = ws(...);
					gcinclude.CheckHoxneWs();
					gcinclude.CheckBuffSets('Buffs_Ws');
					return r;
				end, ...);
				if (gState.PlayerAction ~= nil) and (gState.PlayerAction.Block == true) then gcaction.TraceEnd(); return result end -- WS cancelled
				gcinclude.CheckMoonshade(trail);
				gcinclude.CheckElementGear();
				gcinclude.CheckSupplies('ws');
				gcaction.TraceEnd();
				return result;
			end
		end
		for _, name in ipairs(T{'HandlePreshot', 'HandleMidshot', 'HandleItem'}) do
			local original = gProfile[name];
			if (type(original) == 'function') then
				gProfile[name] = function(...)
					gcaction.TraceStart();
					local result = original(...);
					if (name == 'HandlePreshot') then gcinclude.CheckSupplies('shot') end
					gcaction.TraceEnd(gcinclude.TracePhase[name]);
					return result;
				end
			end
		end
		gProfile.GcHoldWrapped = true;
	end

	-- Buff counts by id. LAC's GetBuffCount(name) converts every active buff name on each call;
	-- here each name is resolved to its ids once and counted against the raw buff list.
	local buffIds = {};
	function gcinclude.BuffCount(m)
		local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
		local count = 0;
		if (type(m) == 'number') then
			for _, b in pairs(buffs) do
				if (b == m) then count = count + 1 end
			end
			return count;
		end
		if (type(m) ~= 'string') then return 0 end
		local key = string.lower(m);
		local ids = buffIds[key];
		if (ids == nil) then
			ids = {};
			local res = AshitaCore:GetResourceManager();
			for id = 0, 1023 do
				local name = res:GetString('buffs.names', id);
				if (type(name) == 'string') and (string.lower((name:gsub('%z+$', ''))) == key) then ids[id] = true end
			end
			buffIds[key] = ids;
		end
		for _, b in pairs(buffs) do
			if ids[b] then count = count + 1 end
		end
		return count;
	end

	-- Lowercase name -> set, built once per Sets table. HandleDefault looks up ~10 sets per call;
	-- scanning every set each time was the costliest part of it. /lac addset reloads the profile,
	-- which gives a new Sets table and so a fresh index.
	local setIndex, setIndexOf = {}, nil;
	function gcinclude.FindSet(name)
		if (gProfile == nil) or (type(gProfile.Sets) ~= 'table') or (type(name) ~= 'string') then return nil end
		if (setIndexOf ~= gProfile.Sets) then
			setIndex, setIndexOf = {}, gProfile.Sets;
			for key, set in pairs(gProfile.Sets) do
				if (type(key) == 'string') and (type(set) == 'table') then setIndex[string.lower(key)] = set end
			end
		end
		return setIndex[string.lower(name)];
	end

	-- Job-file helpers.
	-- Wears <prefix>_Default, then <prefix>_<mode> when /meleeset is not Default.
	function gcinclude.EquipMode(prefix)
		local base = gcinclude.FindSet(prefix .. '_Default');
		if (base ~= nil) then gFunc.EquipSet(base) end
		local mode = gcdisplay.GetCycle('MeleeSet');
		if (mode ~= 'Default') then local n = prefix .. '_' .. mode; gFunc.EquipSet(gcinclude.FindSet(n) or n) end -- index, not LAC's scan of every set
	end

	-- Wears the set named after an action, then its /meleeset variant. False if there is none.
	function gcinclude.ByName(name)
		local set = gcinclude.FindSet(name);
		if (set == nil) then return false end
		gFunc.EquipSet(set);
		local mode = gcdisplay.GetCycle('MeleeSet');
		if (mode ~= nil) and (mode ~= 'Default') then
			local v = gcinclude.FindSet(name .. '_' .. mode);
			if (v ~= nil) then gFunc.EquipSet(v) end
		end
		return true;
	end

	-- 'Utsusemi: Ni' -> 'Utsusemi', 'Drain III' -> 'Drain'.
	function gcinclude.Family(name)
		local base = string.match(name, '^(.-):') or name;
		return (string.gsub(base, ' [IVX]+$', ''));
	end

	-- Dual Wield I: NIN Lv10, DNC Lv20, THF Lv83 (FFXIclopedia Dual Wield). BLU gets it from set spells, so
	-- BLU.lua sets AlwaysDualWield. Levels are the effective ones (IPlayer GetMainJobLevel/GetSubJobLevel;
	-- LAC data.lua calls the sub one SubJobSync): SJ Restriction drops the sub to Lv0 (FFXIclopedia), and
	-- Sheol Gaol restricts support jobs (BG-Wiki), so a /NIN there can't dual wield. /dw on|off overrides.
	gcinclude.DualWieldLevels = T{ NIN = 10, DNC = 20, THF = 83 };
	gcinclude.DualWieldMode = 'auto';

	function gcinclude.DualWieldState()
		if (gcinclude.DualWieldMode == 'on') then return true, 'set by /dw on' end
		if (gcinclude.DualWieldMode == 'off') then return false, 'set by /dw off' end
		if (gcinclude.AlwaysDualWield == true) then return true, 'AlwaysDualWield' end
		local p = AshitaCore:GetMemoryManager():GetPlayer();
		local jobs = AshitaCore:GetResourceManager();
		local main, ml = jobs:GetString('jobs.names_abbr', p:GetMainJob()), p:GetMainJobLevel();
		local need = gcinclude.DualWieldLevels[main or ''];
		if (need ~= nil) and (ml >= need) then return true, string.format('main %s Lv%d', main, ml) end
		if (p:GetIsZoning() ~= 0) or (ml == 0) then return (gcinclude.LastDualWield == true), 'zoning, kept last' end
		local sub, sl = jobs:GetString('jobs.names_abbr', p:GetSubJob()), p:GetSubJobLevel();
		need = gcinclude.DualWieldLevels[sub or ''];
		local why = string.format('sub %s Lv%d', tostring(sub or 'none'), sl);
		local can = (need ~= nil) and (sl >= need);
		if can and (gcinclude.BuffCount('SJ Restriction') > 0) then can, why = false, why .. ', SJ Restriction' end
		gcinclude.LastDualWield = can;
		return can, why;
	end

	function gcinclude.CanDualWield()
		return (gcinclude.DualWieldState());
	end

	-- Dual Wield just lost (e.g. zoning into Sheol Gaol): put the 1h weapons on now, past the TP hold, since an
	-- offhand weapon is no use without it. Gaining it back waits for the TP hold like any weapon change.
	gcinclude.NextDualCheck = 0;
	function gcinclude.CheckDualWieldChange(now)
		if (now < gcinclude.NextDualCheck) then return false end
		gcinclude.NextDualCheck = now + 0.5;
		local can, why = gcinclude.DualWieldState();
		local was = gcinclude.DualWieldSeen;
		gcinclude.DualWieldSeen = can;
		if (was == true) and (can == false) then
			gcinclude.Say('Dual Wield off (' .. why .. '): 1h weapons');
			gcinclude.ApplyWeapons(true);
			return true;
		end
		return false;
	end

	function gcinclude.DualWieldCommand(args)
		local arg = (args[2] ~= nil) and string.lower(args[2]) or nil;
		if (arg == 'on') or (arg == 'off') or (arg == 'auto') then gcinclude.DualWieldMode = arg end
		local can, why = gcinclude.DualWieldState();
		gcinclude.Say('Dual Wield: ' .. (can and 'yes' or 'no') .. ' (' .. why .. ')');
		if (arg ~= nil) then gcinclude.NextDualCheck = 0; gcinclude.ApplyWeapons() end -- a switch to no DW forces the 1h set next tick
	end

	function gcinclude.BuildWeaponLayer()
		local equip = {};
		local mode = gcdisplay.GetCycle('Weapons');
		if gcinclude.IsWeaponValue(mode) then
			local set = nil;
			if not gcinclude.CanDualWield() then
				set = gcinclude.FindSet('Weapon_' .. mode .. '_1h');
			end
			if (set == nil) then
				set = gcinclude.FindSet('Weapon_' .. mode);
			end
			if (set == nil) then
				if (gcinclude.MissingWarned[mode] == nil) then
					gcinclude.MissingWarned[mode] = true;
					gcinclude.Err('Missing set: Weapon_' .. mode);
				end
			else
				for k, v in pairs(set) do
					local slot = slotOf(k);
					if gcinclude.WeaponSlots:contains(slot) then
						equip[gcinclude.WeaponSlotNames[slot]] = v;
					end
				end
			end
		end
		for _, cname in ipairs(gcinclude.WeaponSlotNames) do
			local v = gcdisplay.GetCycle(cname);
			if gcinclude.IsWeaponValue(v) then equip[cname] = gcinclude.WeaponItems[string.lower(v)] or v end
		end
		-- Main/Sub/Range in the TH set stay on while /th is on, tagged or not: swapping them resets TP.
		-- Sub only when you can dual wield; otherwise it is dropped (CheckTH skips it too).
		if (gcdisplay.GetToggle('TH') == true) then
			local th = gcinclude.FindSet('TH');
			if (th ~= nil) then
				for k, v in pairs(th) do
					local slot = slotOf(k);
					if gcinclude.HoldSlots:contains(slot) and ((slot ~= 2) or gcinclude.CanDualWield()) then equip[gcinclude.WeaponSlotNames[slot]] = v end
				end
			end
		end
		return (next(equip) ~= nil) and equip or nil;
	end

	function gcinclude.ApplyWeapons(force)
		local set = gcinclude.BuildWeaponLayer();
		if (set == nil) then return end
		if (force == true) then
			gcinclude.UnlockWeapons(); -- force lifts the TP hold only; /lock stays absolute
			gcinclude.NextHoldCheck = os.clock() + 0.5; -- let the swap land before the hold re-checks
		end
		gcinclude.ForceUnlocked(set);
	end


	-- No-ops kept so job files copied from older versions still load. Don't remove.
	function gcinclude.CheckWeaponSwap() end
	function gcinclude.DoMoonshade() end
	function gcinclude.GetWeaponSet(mode) return gcinclude.FindSet('Weapon_' .. mode) end

	-- TH gear until the action's target (else the selected one) is tagged; none for an action on you or an
	-- ally. force skips both checks (AoE TH spells, which can be self-targeted). Main/Sub/Range are left to BuildWeaponLayer, so they don't come off at the tag. The TH set
	-- minus those slots is built once per set table (the set itself when it has none, so /gctrace names it).
	local thGear, thGearOf = nil, nil;
	function gcinclude.CheckTH(force)
		if (gcdisplay.GetToggle('TH') ~= true) then return end
		local set = gcinclude.FindSet('TH');
		if (set == nil) then return end
		if (force ~= true) then
			local action = gData.GetActionTarget();
			if (action ~= nil) and (action.Type ~= 'Monster') then return end
			local target = action or gData.GetTarget();
			if (target ~= nil) and (target.Type == 'Monster') and (gcauto ~= nil) and (gcauto.IsTagged ~= nil) and gcauto.IsTagged(target.Id) then
				return;
			end
		end
		if (thGearOf ~= set) then
			thGear, thGearOf = set, set;
			for k, _ in pairs(set) do
				if gcinclude.HoldSlots:contains(slotOf(k)) then
					thGear = {};
					for k2, v2 in pairs(set) do
						if not gcinclude.HoldSlots:contains(slotOf(k2)) then thGear[k2] = v2 end
					end
					break;
				end
			end
		end
		gFunc.EquipSet(thGear);
	end

	gcinclude.HoxneOwned = T{};

	-- Bows, guns and crossbows (Archery 25 / Marksmanship 26) need matching ammo, so the ampulla can't sit with
	-- them. While Hoxne is Locked, any set asking for one in Range has that entry dropped.
	gcinclude.AmmoSkills = T{25, 26};
	local ammoWeapon = {};
	function gcinclude.NeedsAmmo(item)
		local name = (type(item) == 'table') and item.Name or item;
		if (type(name) ~= 'string') then return false end
		name = string.lower(name);
		if (ammoWeapon[name] == nil) then
			local r = AshitaCore:GetResourceManager():GetItemByName(name, 0);
			ammoWeapon[name] = (r ~= nil) and gcinclude.AmmoSkills:contains(r.Skill);
		end
		return ammoWeapon[name];
	end

	function gcinclude.HoxneOn()
		return (gcdisplay.GetCycle('Hoxne') == 'Locked');
	end

	-- Hoxne sets (per job), worn while /hoxne is Locked and Enchantment is up (the Ampulla's Double Attack +100%,
	-- FFXIclopedia Hoxne Ampulla): Hoxne_Tp engaged, Hoxne_Idle idle and not moving, Hoxne_Dt in place of both
	-- while /dt is on (none: the Dt set stays), none while /kite is on. WS: Hoxne_Ws, then Hoxne_<ws name>.
	-- Each also takes its /meleeset variant (Hoxne_Tp_Hybrid), then its buff combos: Hoxne_Tp_Impetus while
	-- Impetus is up, ['Hoxne_Ws_Sneak Attack&Trick Attack'] while both are (fewest buffs first, then A-Z).
	-- Over job sets, under engine layers.
	function gcinclude.HoxneActive()
		return gcinclude.HoxneOn() and (gcinclude.BuffCount('Enchantment') > 0);
	end

	-- Combos by base set, read from the set names once per profile: 'hoxne_tp' -> { {buffs, set}, ... }, fewest
	-- buffs first, then by name. No buff name has '_' or '&' (Windower resources buffs.lua), so they split cleanly.
	local hoxneCombos, hoxneCombosOf = {}, nil;
	local function hoxneCombosFor(base)
		if (type(gProfile.Sets) ~= 'table') then return nil end
		if (hoxneCombosOf ~= gProfile.Sets) then
			hoxneCombos, hoxneCombosOf = {}, gProfile.Sets;
			for key, set in pairs(gProfile.Sets) do
				local b, suffix;
				if (type(key) == 'string') and (type(set) == 'table') then b, suffix = string.match(key, '^(.+)_([^_]+)$') end
				if (b ~= nil) and (string.sub(string.lower(b), 1, 6) == 'hoxne_') then
					local buffs = T{};
					for name in string.gmatch(suffix, '[^&]+') do buffs:append(name) end
					local list = hoxneCombos[string.lower(b)] or T{};
					list:append({ buffs = buffs, set = set, key = string.lower(suffix) });
					hoxneCombos[string.lower(b)] = list;
				end
			end
			for _, list in pairs(hoxneCombos) do
				table.sort(list, function(x, y)
					if (#x.buffs ~= #y.buffs) then return #x.buffs < #y.buffs end
					return x.key < y.key;
				end);
			end
		end
		return hoxneCombos[string.lower(base)];
	end

	-- Each combo of a Hoxne set whose buffs are all up.
	local function wearHoxneCombos(name)
		local list = hoxneCombosFor(name);
		if (list == nil) then return end
		for _, c in ipairs(list) do
			local up = true;
			for _, b in ipairs(c.buffs) do
				if (gcinclude.BuffCount(b) == 0) then up = false; break end
			end
			if up then gFunc.EquipSet(c.set) end
		end
	end

	-- A Hoxne set, its /meleeset variant, then its combos.
	function gcinclude.WearHoxne(name)
		gcinclude.ByName(name);
		wearHoxneCombos(name);
	end

	function gcinclude.CheckHoxneSets(player)
		if (player == nil) or (not gcinclude.HoxneActive()) or (gcdisplay.GetToggle('Kite') == true) then return end
		if (gcdisplay.GetToggle('DTset') == true) then
			gcinclude.WearHoxne('Hoxne_Dt');
		elseif (player.Status == 'Engaged') then
			gcinclude.WearHoxne('Hoxne_Tp');
		elseif (player.Status == 'Idle') and (player.IsMoving ~= true) then
			gcinclude.WearHoxne('Hoxne_Idle');
		end
	end

	function gcinclude.CheckHoxneWs()
		if not gcinclude.HoxneActive() then return end
		-- Buff combos go over both WS sets, as job files put buff sets over the WS set.
		local ws = gData.GetAction();
		local name = (ws ~= nil) and (ws.Name ~= nil) and ('Hoxne_' .. ws.Name) or nil;
		gcinclude.ByName('Hoxne_Ws');
		if (name ~= nil) then gcinclude.ByName(name) end
		wearHoxneCombos('Hoxne_Ws');
		if (name ~= nil) then wearHoxneCombos(name) end
	end

	function gcinclude.DropAmmoWeapon(set)
		if (type(set) == 'string') then set = gcinclude.FindSet(set) or set end
		if (type(set) ~= 'table') or (not gcinclude.HoxneOn()) then return set end
		for k, v in pairs(set) do
			if (slotOf(k) == 3) and gcinclude.NeedsAmmo(v) then
				local out = {};
				for k2, v2 in pairs(set) do if (k2 ~= k) then out[k2] = v2 end end
				return out;
			end
		end
		return set;
	end

	-- Filters every gFunc.EquipSet / gFunc.Equip call, job files included. gFunc outlives profile reloads,
	-- so the originals are kept on it and wrapped once.
	function gcinclude.WrapEquip()
		if (gFunc.GcRawEquipSet ~= nil) then return end
		gFunc.GcRawEquipSet, gFunc.GcRawEquip = gFunc.EquipSet, gFunc.Equip;
		gFunc.EquipSet = function(set)
			if (gcinclude ~= nil) and (gcinclude.DropAmmoWeapon ~= nil) then set = gcinclude.DropAmmoWeapon(set) end
			return gFunc.GcRawEquipSet(set);
		end
		gFunc.Equip = function(slot, item)
			if (gcinclude ~= nil) and (gcinclude.HoxneOn ~= nil) and gcinclude.HoxneOn() and (slotOf(slot) == 3) and gcinclude.NeedsAmmo(item) then return end
			return gFunc.GcRawEquip(slot, item);
		end
	end

	-- Sub vs Main (FFXIclopedia Category:Grips): a two-handed main (Great Sword, Great Axe, Scythe, Polearm, Great
	-- Katana, Staff: skills 4 6 7 8 10 12) takes only a grip in Sub, and a grip needs a two-handed main. LAC's equip
	-- buffer is shadowed so the check sees the final Main of the handler; a Sub that can't go with it is dropped.
	gcinclude.TwoHandSkills = T{4, 6, 7, 8, 10, 12};
	local resByName, resById = {}, {};
	local function itemRes(v)
		local name = (type(v) == 'table') and v.Name or v;
		if (type(name) ~= 'string') then return nil end
		local key = string.lower(name);
		local r = resByName[key];
		if (r == nil) then
			r = AshitaCore:GetResourceManager():GetItemByName(name, 0) or false;
			resByName[key] = r;
		end
		return r or nil;
	end
	local function wornMainRes()
		local e = gEquip.GetCurrentEquip(1);
		local id = (e ~= nil) and (e.Item ~= nil) and e.Item.Id or nil;
		if (id == nil) then return nil end
		local r = resById[id];
		if (r == nil) then
			r = AshitaCore:GetResourceManager():GetItemById(id) or false;
			resById[id] = r;
		end
		return r or nil;
	end
	local function isGrip(r)
		return (r.Slots == 2) and (r.ShieldSize == 0) and (r.Skill == 0);
	end

	-- main/sub: LAC item tables ({ Name = ... }) or nil. True when they can be worn together, or unknown.
	function gcinclude.SubFits(main, sub)
		local subName = (type(sub) == 'table') and sub.Name or sub;
		if (type(subName) ~= 'string') or gcinclude.WeaponKeywords:contains(string.lower(subName)) then return true end
		local mainName = (type(main) == 'table') and main.Name or main;
		if (type(mainName) == 'string') and ((string.lower(mainName) == 'remove') or (string.lower(mainName) == 'displaced')) then return true end
		local mainRes;
		if (type(mainName) == 'string') and not gcinclude.WeaponKeywords:contains(string.lower(mainName))
			and (gState.Disabled[1] ~= true) then
			mainRes = itemRes(main);
		else
			mainRes = wornMainRes();
		end
		local subRes = itemRes(sub);
		if (mainRes == nil) or (subRes == nil) then return true end
		return gcinclude.TwoHandSkills:contains(mainRes.Skill) == isGrip(subRes);
	end

	function gcinclude.WrapBuffer()
		if (gEquip == nil) or (gEquip.GcRawToBuffer ~= nil) then return end
		gEquip.GcRawToBuffer, gEquip.GcRawClear, gEquip.GcRawProcess = gEquip.EquipItemToBuffer, gEquip.ClearBuffer, gEquip.ProcessBuffer;
		local shadow = {};
		gEquip.ClearBuffer = function(...)
			shadow = {};
			return gEquip.GcRawClear(...);
		end
		gEquip.EquipItemToBuffer = function(slot, itemTable, immediate)
			if (immediate ~= true) and (type(itemTable) == 'table') then
				local cur = shadow[slot];
				if not ((cur ~= nil) and (cur.Locked == true) and (itemTable.Locked ~= true)) then
					shadow[slot] = (itemTable.Name ~= 'ignore') and itemTable or nil;
				end
			end
			return gEquip.GcRawToBuffer(slot, itemTable, immediate);
		end
		gEquip.ProcessBuffer = function(...)
			local sub = shadow[2];
			if (sub ~= nil) and (gcinclude ~= nil) and (gcinclude.SubFits ~= nil) then
				local ok, fits = pcall(gcinclude.SubFits, shadow[1], sub);
				if ok and (fits == false) then gEquip.GcRawToBuffer(2, { Name = 'ignore' }) end
			end
			return gEquip.GcRawProcess(...);
		end
	end

	function gcinclude.CheckHoxne()
		local state = gcdisplay.GetCycle('Hoxne');
		if (state == 'Locked') then
			if (gcinclude.HoxneLocked ~= true) then
				gcinclude.HoxneLocked = true;
				gcinclude.HoxneOwned = T{};
				for _, slot in ipairs(gcinclude.SlotNumbers(gcinclude.settings.HoxneLockSlots, 1)) do
					if (gcinclude.LockedSlots[slot] == nil) then gcinclude.HoxneOwned:append(slot) end
				end
				-- Settle Ammo/Range before locking them, else a bow already on stays locked in.
				local range = gData.GetEquipment().Range;
				local settle = { Ammo = gcinclude.settings.HoxneItem };
				if (range ~= nil) and gcinclude.NeedsAmmo(range.Name) then settle.Range = 'displaced' end -- the Ampulla going on drops the bow
				gcinclude.ForceUnlocked(settle);
				if (#gcinclude.HoxneOwned > 0) then gcinclude.LockSlots(gcinclude.HoxneOwned) end
			end
		elseif (gcinclude.HoxneLocked == true) then
			gcinclude.HoxneLocked = false;
			if (#gcinclude.HoxneOwned > 0) then gcinclude.UnlockSlots(gcinclude.HoxneOwned) end
			gcinclude.HoxneOwned = T{};
		end
		if (state ~= 'Locked') then return end
		local set = { Ammo = gcinclude.settings.HoxneItem };
		local range = gData.GetEquipment().Range;
		if (range ~= nil) and gcinclude.NeedsAmmo(range.Name) then set.Range = 'displaced' end -- the game drops it for the Ampulla
		gFunc.EquipSet(set);
	end

	gcinclude.BoundKeys = T{};

	function gcinclude.ApplyKeybinds()
		local binds = gcinclude.settings.Keybinds;
		if (type(binds) ~= 'table') then return end
		-- bare grave used to be /wm: clear it unless a bind here still asks for it
		local bare = false;
		for _, bind in ipairs(binds) do
			if (type(bind) == 'table') and (bind[1] == '`') then bare = true end
		end
		if not bare then AshitaCore:GetChatManager():QueueCommand(-1, '/unbind `') end
		for _, bind in ipairs(binds) do
			if (type(bind) == 'table') and (bind[1] ~= nil) and (bind[2] ~= nil) then
				AshitaCore:GetChatManager():QueueCommand(-1, '/bind ' .. bind[1] .. ' /lac fwd ' .. bind[2]);
				if not gcinclude.BoundKeys:contains(bind[1]) then gcinclude.BoundKeys:append(bind[1]) end
			end
		end
	end

	function gcinclude.ClearKeybinds()
		for _, key in ipairs(gcinclude.BoundKeys) do
			AshitaCore:GetChatManager():QueueCommand(-1, '/unbind ' .. key);
		end
		gcinclude.BoundKeys = T{};
	end

	function gcinclude.KeyCommand(args)
		if (args[2] == nil) or (args[3] == nil) then
			gcinclude.Say('usage: /gckey <key> <command>  (key uses Ashita names and ! ^ + @ # modifiers)');
			return;
		end
		local rest = T{};
		for i = 3, #args do rest:append(args[i]) end
		AshitaCore:GetChatManager():QueueCommand(-1, '/bind ' .. args[2] .. ' /lac fwd ' .. table.concat(rest, ' '));
		if not gcinclude.BoundKeys:contains(args[2]) then gcinclude.BoundKeys:append(args[2]) end
		gcinclude.Say(args[2] .. ' -> /' .. table.concat(rest, ' '));
	end

	function gcinclude.EnchantDelay(name, res)
		local override = gcinclude.settings.EnchantDelays[name];
		if (override == nil) then
			for key, value in pairs(gcinclude.settings.EnchantDelays) do
				if (string.lower(key) == string.lower(name)) then override = value; break end
			end
		end
		if (tonumber(override) ~= nil) then return tonumber(override), 'setting' end
		local delay = (res ~= nil) and tonumber(res.CastDelay) or nil;
		if (delay ~= nil) and (delay > 0) and (delay <= 600) then return delay, 'item' end
		return (gcinclude.settings.EnchantWindow or 12), 'default';
	end

	function gcinclude.UseEnchanted(name, slot, allowLocked)
		local res = AshitaCore:GetResourceManager():GetItemByName(name, 0);
		if (res == nil) then
			gcinclude.Err('no such item: ' .. name);
			return false;
		end
		if (slot == nil) then
			local slots = gcinclude.EnchantSlots or T{'Ring1', 'Ring2', 'Neck', 'Waist', 'Back', 'Ear1', 'Ear2', 'Head', 'Body', 'Hands', 'Legs', 'Feet', 'Ammo'};
			for _, candidate in ipairs(slots) do
				if (bit.band(res.Slots, gcinclude.SlotBits[candidate] or 0) ~= 0) then slot = candidate; break end
			end
		end
		if (slot == nil) then
			gcinclude.Err(name .. ' has no slot to wear');
			return false;
		end
		local delay, source = gcinclude.EnchantDelay(name, res);
		local index = slotOf(slot);
		gcinclude.ReleaseEnchant(index); -- a new /gce on the same slot replaces the old one
		local wasLocked = (gcinclude.LockedSlots[index] == true);
		if wasLocked and (allowLocked ~= true) then
			gcinclude.Err(slot .. ' is locked - /unlock ' .. string.lower(slot) .. ' first');
			return false;
		end
		gFunc.ForceEquipSet({ [slot] = name }); -- slot is free or owned by the caller
		gcinclude.LockSlots(T{index});
		local alreadyOn = (equippedId(index) == res.Id); -- worn already: its delay may be long past
		local before = enchantInfo(carriedId(res.Id)); -- extdata before this equip, to see when it refreshes
		gcinclude.Enchants[index] = { item = name, id = res.Id, slot = slot, index = index, wasLocked = wasLocked, alreadyOn = alreadyOn, preAct = (before ~= nil) and before.activation or nil,
			delay = delay, start = os.clock(), tries = 0 };
		gcinclude.Say(name .. ' on ' .. string.lower(slot) .. ', using it ' .. tostring(delay) .. 's after it is on (' .. source .. ')');
		return true;
	end

	function gcinclude.EnchantCommand(args)
		local words = T{};
		for i = 2, #args do words:append(args[i]) end
		if (#words == 0) then
			gcinclude.Say('usage: /gce Warp Ring');
			return;
		end
		if (#words == 1) and (string.lower(words[1]) == 'cancel') then
			local n = 0;
			for index, _ in pairs(gcinclude.Enchants) do gcinclude.ReleaseEnchant(index); n = n + 1 end
			gcinclude.Say('gce: ' .. ((n > 0) and 'cancelled' or 'nothing running'));
			return;
		end
		local name = table.concat(words, ' ');
		gcinclude.UseEnchanted(name, nil);
	end

	-- Zoning: from the server's reply to the zone line (0x000B, XiPackets GP_SERV_COMMAND_LOGOUT; LogoutState 4 =
	-- cancelled) until 3s after zone-in (0x000A), or while Ashita's player says so. Nothing is sent by itself
	-- meanwhile: the buff list reads empty then, and an /item sent mid-zone took the Shorthand plugin down.
	gcinclude.ZoneOutAt, gcinclude.ZoneInAt = nil, -1e9;
	function gcinclude.OnZoneOut(state)
		gcinclude.ZoneOutAt = (state ~= 4) and os.clock() or nil;
	end
	function gcinclude.Zoning()
		local now = os.clock();
		if (gcinclude.ZoneOutAt ~= nil) and (now - gcinclude.ZoneOutAt < 60) then return true end
		if (now < gcinclude.ZoneInAt + 3) then return true end
		local p = AshitaCore:GetMemoryManager():GetPlayer();
		return (p ~= nil) and (p:GetIsZoning() ~= 0);
	end

	-- Zoning: item uses stop (zoning drops an enchantment anyway: BG-Wiki Hoxne Ampulla), slots are given back,
	-- and /hoxne goes back to Off, so nothing is used on arrival.
	function gcinclude.OnZone()
		gcinclude.ZoneOutAt, gcinclude.ZoneInAt = nil, os.clock();
		gcinclude.HoxneGoneSince = nil;
		for index, _ in pairs(gcinclude.Enchants) do gcinclude.ReleaseEnchant(index) end
		gcinclude.HoxneRetryAt = 0;
		if gcinclude.HoxneOn() then
			gcinclude.SetWeaponCycle('Hoxne', 'Off', true);
			gcinclude.CheckHoxne();
			gcinclude.Say('Hoxne: Off (zoned)');
		end
	end

	-- Hoxne Ampulla (BG-Wiki): Double Attack +100% for 30 min as the Enchantment status (BG-Wiki Category:Enchantment;
	-- id 162 in Windower's buff resources), 60s recast, 5s use delay, lost when unequipped or on zoning.
	-- While /hoxne is Locked and the Ampulla is in ammo with no Enchantment up, it is used (the use delay
	-- counted from when it went on). Enchantment up: never used. /hoxne use uses it now. One go a minute.
	-- Enchantment has to be gone 3s straight first: it drops as you cross a zone line, a moment before the
	-- server's zone reply (0x000B) marks you as zoning.
	gcinclude.HoxneRetryAt = 0;
	gcinclude.HoxneCheckAt = 0;
	gcinclude.HoxneGoneSince = nil;
	function gcinclude.CheckHoxneAuto(now)
		if (gcinclude.settings.HoxneAutoUse ~= true) or (now < gcinclude.HoxneCheckAt) then return end
		gcinclude.HoxneCheckAt = now + 1;
		if (not gcinclude.HoxneOn()) or (gcinclude.BuffCount('Enchantment') > 0) then gcinclude.HoxneGoneSince = nil; return end
		gcinclude.HoxneGoneSince = gcinclude.HoxneGoneSince or now;
		if (now < gcinclude.HoxneGoneSince + 3) or (now < gcinclude.HoxneRetryAt) then return end
		local r = AshitaCore:GetResourceManager():GetItemByName(gcinclude.settings.HoxneItem, 0);
		if (r == nil) or (equippedId(4) ~= r.Id) then return end
		if (gcinclude.Enchants[4] ~= nil) or (gState.PlayerAction ~= nil) then return end
		local p = gData.GetPlayer();
		if (p == nil) or ((p.Status ~= 'Idle') and (p.Status ~= 'Engaged')) or (p.IsMoving == true) then return end
		for _, b in ipairs(gcinclude.HardCC) do
			if (gcinclude.BuffCount(b) > 0) then return end
		end
		gcinclude.HoxneRetryAt = now + 60;
		gcinclude.UseEnchanted(gcinclude.settings.HoxneItem, 'Ammo', true);
	end

	-- Asleep under Stoneskin: damage it absorbs can't wake you (FFXIclopedia Sleep), so cancel it.
	gcinclude.SleepCancelAt = 0;
	function gcinclude.CheckSleepStoneskin(now)
		if (gcinclude.settings.SleepCancelStoneskin ~= true) or (now < gcinclude.SleepCancelAt) then return end
		if (gcinclude.BuffCount('Sleep') == 0) or (gcinclude.BuffCount('Stoneskin') == 0) then return end
		gcinclude.SleepCancelAt = now + 3;
		AshitaCore:GetChatManager():QueueCommand(-1, '/cancel Stoneskin');
	end

	-- Entering a Dynamis - Divergence zone (named "Dynamis - <city> [D]", per SE's Nov 2025 update notes): a reminder
	-- that /dynamisrp holds the job neck.
	gcinclude.LastZone = nil;
	function gcinclude.CheckZoneNotes()
		local zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
		if (zone == gcinclude.LastZone) then return end
		gcinclude.LastZone = zone;
		local name = AshitaCore:GetResourceManager():GetString('zones.names', zone) or '';
		if (string.find(name, 'Dynamis', 1, true) ~= nil) and (string.find(name, '[D]', 1, true) ~= nil) then
			gcinclude.Say('Dynamis - Divergence: /dynamisrp holds your best job neck (RP)');
		end
	end

	-- /temps: the six Escha drinks (BG-Wiki Escha Temporary Items), each carried one 3s apart.
	gcinclude.EschaTemps = T{"Monarch's Drink", "Braver's Drink", "Fighter's Drink", "Champion's Drink", "Soldier's Drink", "Barbarian's Drink"};
	function gcinclude.UseTemps()
		local queued = 0;
		for _, item in ipairs(gcinclude.EschaTemps) do
			if (gcauto ~= nil) and (gcauto.ItemCount(item) > 0) then
				local function use() AshitaCore:GetChatManager():QueueCommand(-1, '/item "' .. item .. '" <me>') end
				if (queued == 0) then use() else use:once(queued * 3) end
				queued = queued + 1;
			end
		end
		gcinclude.Say('temps: ' .. ((queued > 0) and (queued .. ' drinks') or 'none carried'));
	end

	function gcinclude.Help()
		local lines = T{
			'weapons: /wm [name|N|none|default|role] [force], /mainset /subset /rangeset /ammoset',
			'defense: /def (cycle DT > MDT > Aminon > SIRD > none), /dt /mdt /aminon (also locks main/sub, range/ammo if in the set) /sir, /lock [slots] /unlock [slots]',
			'hoxne  : /hoxne (Off > Locked), /hoxne use',
			'toggles: /th (TH gear until the target is tagged; TH-set weapons while on), /kite, /meleeset or /mset [hybrid|acc|default] (no word: Default > Hybrid > Acc)',
			'auto   : /autofood [on|off], /autosoda [on|off], /revit [on|off], /holywater [on|off]',
			'hud    : /gchud [on|off|pos x y|debug]',
			'checks : /checksets, /xiroll, /mbinfo',
			'swap   : /smartswap [on|off], /dw [on|off|auto] (dual wield: shows why; off = 1h weapon sets)',
			'holds  : /naked /weaponsonly /abysseaproc [on|off] (one at a time), /capacity /jubilee /dynamisrp [on|off]',
			'items  : /gce <item> | cancel, /temps (Escha drinks), /warpring /mea /holla /dem',
			'checks : /gctrace (sets per action), /gcstyle N (lockstyle); failing actions cancel, recasts under 5s queue',
			'gear   : /autogear [on|off|regen N|refresh N|dt N|petdt N]',
			'bar    : /gcbar [on|off|pos x y]',
			'on/off : every toggle takes on|off (no arg flips it); /def off|dt|mdt|aminon|sird',
			'nuke   : Burst set is automatic on live skillchains; /automb [on|off] = cast bursts by itself; /mbtier low|mid|high = its tier I|III|V; /burst = Burst set on every nuke',
			'keys   : Ctrl+grave wm, Shift+grave wm default, Ctrl+Shift+grave def, Alt+grave hoxne, Win+grave automb (no bare grave); /gckey <key> <command>',
			'all of these work as /mss /lac fwd <command> for every box',
		};
		for _, line in ipairs(lines) do
			print(chat.header('ShaySwap'):append(chat.message(line)));
		end
	end

	-- SIRD counts only while worn when each hit lands mid-cast (BG: must be in midcast),
	-- so it is laid over the finished midcast set, never at rest.
	function gcinclude.CheckSIR()
		if (gcdisplay.GetToggle('SIR') ~= true) then return end
		local action = gData.GetAction();
		if (action == nil) then return end
		local skip = gcinclude.SIRSkip or gcinclude.settings.SIRSkip; -- job file may set gcinclude.SIRSkip
		if (type(skip) == 'table') and (skip:contains(action.Name)) then return end
		if gcinclude.IsDefenseExempt(action) then return end
		local set = gcinclude.FindSet('SIR');
		if (set ~= nil) then gFunc.EquipSet(set) end
	end

	-- settings.DefenseExempt (Absorb-TP, Stun): /def states don't touch these casts. No SIR set over them, and
	-- /aminon's Main/Sub (and Range/Ammo) lock is lifted for the cast; HandleDefault puts it back afterwards.
	-- /lock, the Hoxne lock and the TP hold still apply. Per job: gcinclude.DefenseExempt = T{...} in OnLoad.
	function gcinclude.IsDefenseExempt(action)
		local list = gcinclude.DefenseExempt or gcinclude.settings.DefenseExempt;
		if (action == nil) or (type(action.Name) ~= 'string') or (type(list) ~= 'table') then return false end
		for _, n in ipairs(list) do
			if (string.lower(n) == string.lower(action.Name)) then return true end
		end
		return false;
	end

	function gcinclude.LiftAminonForExempt()
		if (#gcinclude.AminonOwned == 0) or not gcinclude.IsDefenseExempt(gData.GetAction()) then return end
		gcinclude.UnlockSlots(gcinclude.AminonOwned);
	end

	-- Opt-in: a set named <spell>_<state> goes on last over a DefenseExempt spell while that state is on, e.g.
	-- Absorb_TP_Aminon, Stun_SIR, Stun_Dt ('Absorb-TP' -> 'Absorb_TP'). No such set: nothing changes.
	gcinclude.ExemptStates = T{ {'DTset', 'Dt'}, {'MDTset', 'Mdt'}, {'Aminon', 'Aminon'}, {'SIR', 'SIR'} };
	function gcinclude.CheckExemptStateSets()
		local action = gData.GetAction();
		if not gcinclude.IsDefenseExempt(action) then return end
		local base = string.gsub(action.Name, '[%s%-]', '_');
		for _, s in ipairs(gcinclude.ExemptStates) do
			if (gcdisplay.GetToggle(s[1]) == true) then
				local set = gcinclude.FindSet(base .. '_' .. s[2]);
				if (set ~= nil) then gFunc.EquipSet(set) end
			end
		end
	end

	-- True when the Burst set belongs on this cast: always when a skillchain whose elements include the spell's
	-- is live on the spell's target and the cast lands inside the window; /burst puts it on every nuke.
	-- Job files call it where they used to check the Burst toggle, so their own layer order holds.
	function gcinclude.BurstWanted()
		local spell = gData.GetAction();
		if (spell == nil) then return false end
		local skills = gcinclude.settings.MBSkills;
		if (type(skills) ~= 'table') or (not skills:contains(spell.Skill)) then return false end
		if (gcdisplay.GetToggle('Burst') == true) then return true end
		local target = gData.GetActionTarget();
		if (target == nil) or (gcauto == nil) or (gcauto.BurstLive == nil) then return false end
		-- Midcast runs as the cast starts, so it lands after the learned cast time (gcauto.CastTime).
		-- No cast of this skill timed yet: only ask whether a chain is live now (wearing Burst gear on a
		-- miss costs little; skipping it on a hit costs the burst).
		local landsAt = nil;
		if (spell.Resource ~= nil) then
			local t, learned = gcauto.CastTime(spell.Resource);
			if learned then landsAt = os.clock() + t end
		end
		return gcauto.BurstLive(target.Id, spell.Element, landsAt);
	end

	function gcinclude.InCombat(player)
		player = player or gData.GetPlayer();
		if (player ~= nil) and (player.Status == 'Engaged') then return true end
		return (gcauto ~= nil) and (gcauto.InCombat ~= nil) and gcauto.InCombat();
	end

	function gcinclude.CheckMDT()
		if (gcdisplay.GetToggle('MDTset') == true) then
			local set = gcinclude.FindSet('mdt');
			if (set ~= nil) then gFunc.EquipSet(set) end
		end
		gcinclude.CheckAminonLock();
		if (gcdisplay.GetToggle('Aminon') == true) then
			local set = gcinclude.FindSet('Aminon') or gcinclude.FindSet('mdt');
			if (set ~= nil) then gFunc.EquipSet(set) end
		end
	end

	-- /aminon locks Main/Sub while on, plus Range/Ammo only when the set names them (BRD instruments keep
	-- swapping): puts on the set's items for those slots first (else keeps what you wear), then locks them so
	-- action sets can't swap them. Other slots still swap for actions.
	-- Slots already /locked or Hoxne-locked are left alone; off releases only what it took. /unlock re-locks.
	gcinclude.AminonSlots = T{'Main', 'Sub', 'Range', 'Ammo'};
	gcinclude.AminonAlways = T{1, 2}; -- Main, Sub
	gcinclude.AminonOwned = T{};
	function gcinclude.CheckAminonLock()
		if (gcdisplay.GetToggle('Aminon') ~= true) then
			if (#gcinclude.AminonOwned > 0) then gcinclude.UnlockSlots(gcinclude.AminonOwned) end
			gcinclude.AminonOwned = T{};
			return;
		end
		local set = gcinclude.FindSet('Aminon') or gcinclude.FindSet('mdt') or {};
		local wear, take = {}, T{};
		for _, name in ipairs(gcinclude.AminonSlots) do
			local slot = slotOf(name);
			local key = nil;
			for k, _ in pairs(set) do
				if (slotOf(k) == slot) then key = k end -- set keys in any case
			end
			if (gcinclude.LockedSlots[slot] == nil) and ((key ~= nil) or gcinclude.AminonAlways:contains(slot)) then
				if (key ~= nil) then wear[key] = set[key] end
				take:append(slot);
				if not gcinclude.AminonOwned:contains(slot) then gcinclude.AminonOwned:append(slot) end
			end
		end
		if (#take == 0) then return end
		if (next(wear) ~= nil) then gFunc.ForceEquipSet(wear) end -- ignores the TP hold: /aminon asked for these
		gcinclude.LockSlots(take);
	end

	-- Buffs (idle/engaged, HandleDefault), Buffs_Ws (weaponskills) and Buffs_Midcast (spells): { [buff name] = set },
	-- each worn while that buff is up, e.g. Buffs_Ws = { ['Aftermath: Lv.3'] = {...} }. Name it as the buff list shows it.
	function gcinclude.CheckBuffSets(setName)
		local buffs = gcinclude.FindSet(setName or 'Buffs');
		if (buffs == nil) then return end
		local order = gcinclude.BuffSetOrder;
		if (type(order) ~= 'table') then
			order = T{};
			for name, _ in pairs(buffs) do order:append(name) end
			table.sort(order);
		end
		for _, name in ipairs(order) do
			local set = buffs[name];
			if (type(set) == 'table') and (gcinclude.BuffCount(name) > 0) then
				gFunc.EquipSet(set);
			end
		end
	end

	function gcinclude.CheckWeapons(player)
		local set = gcinclude.BuildWeaponLayer();
		if (set ~= nil) then gFunc.EquipSet(set) end
		gcinclude.CheckMDT();
		gcinclude.CheckHoxne();
		gcinclude.CheckTH();
		gcinclude.CheckReceived();
		gcinclude.CheckBuffSets();
		gcinclude.CheckXIRoll(player);
	end

	function gcinclude.IsBlockedAmmo(name)
		if (type(name) ~= 'string') then return false end
		local lname = string.lower(name);
		for _, v in ipairs(gcinclude.BlockedAmmo) do
			if (string.find(lname, v, 1, true) ~= nil) then return true end
		end
		return false;
	end

	function gcinclude.BlockedAmmoName()
		local equip = gData.GetEquipment();
		if (equip == nil) or (equip.Ammo == nil) or (type(equip.Ammo.Name) ~= 'string') then return nil end
		if (gcinclude.IsBlockedAmmo(equip.Ammo.Name) == true) then return equip.Ammo.Name end
		return nil;
	end

	function gcinclude.CheckBlockedAmmo()
		local name = gcinclude.BlockedAmmoName();
		if (name == nil) then return false end
		if (gcinclude.BuffCount('Unlimited Shot') > 0) then return false end
		gcinclude.Err('Shot cancelled: ' .. name .. ' is equipped.');
		gFunc.CancelAction();
		-- SafeAmmo: a name, or a table keyed by the blocked ammo's last word, e.g. { Bullet = '...', Arrow = '...' }
		local safe = gcinclude.SafeAmmo;
		if (type(safe) == 'table') then safe = safe[string.match(name, '(%a+)%s*$') or ''] end
		if (type(safe) == 'string') then
			gcinclude.ForceUnlocked({ Ammo = safe });
		end
		return true;
	end

	function gcinclude.CheckBlockedAmmoWS(wsName)
		if (type(wsName) ~= 'string') then return false end
		if not gcinclude.DistanceWS:contains(wsName) or gcinclude.NoAmmoWS:contains(wsName) then return false end
		return gcinclude.CheckBlockedAmmo();
	end

	function gcinclude.RollActive()
		for _, name in ipairs(gcinclude.RollBuffs) do
			if (gcinclude.BuffCount(name) > 0) then return true end
		end
		return false;
	end

	function gcinclude.XIRollActive()
		if (gcauto == nil) or (gcauto.RollEleven == nil) then return false end
		return gcauto.RollEleven() and gcinclude.RollActive();
	end

	-- Idle only: never over melee (engaged) or resting gear.
	function gcinclude.CheckXIRoll(player)
		player = player or gData.GetPlayer();
		if (player == nil) or (player.Status ~= 'Idle') then return end
		if not gcinclude.XIRollActive() then return end
		local set = gcinclude.FindSet('XIRoll') or gcinclude.settings.XIRollSet;
		if (set ~= nil) then gFunc.EquipSet(set) end
	end

	gcinclude.PairSlots = T{ ear1 = 'ear2', ear2 = 'ear1', ring1 = 'ring2', ring2 = 'ring1' };

	function gcinclude.CheckSets()
		if (gProfile == nil) or (type(gProfile.Sets) ~= 'table') then return end
		local empty = T{};
		local unknown = T{};
		local families = {};
		local pairSlots = {};
		local moon = T{};
		for name, set in pairs(gProfile.Sets) do
			if (type(set) == 'table') then
				if (next(set) == nil) then empty:append(name) end
				local worn = {};
				for slot, item in pairs(set) do
					local iname = (type(item) == 'table') and item.Name or item;
					local key = string.lower(tostring(slot));
					if (type(iname) == 'string') and gcinclude.PairSlots[key] then worn[key] = string.lower(iname) end
					if (type(iname) == 'string') and (string.lower(iname) == 'moonshade earring') and not moon:contains(name) then moon:append(name) end
				end
				for key, iname in pairs(worn) do
					if (worn[gcinclude.PairSlots[key]] ~= iname) then
						pairSlots[iname] = pairSlots[iname] or {};
						pairSlots[iname][key] = true;
					end
				end
				for slot, item in pairs(set) do
					local label = gcinclude.WeaponLabel(item);
					local iname = (type(item) == 'table') and item.Name or item;
					if (type(iname) == 'string') and not gcinclude.WeaponKeywords:contains(string.lower(iname)) then
						if (AshitaCore:GetResourceManager():GetItemByName(iname, 0) == nil) then
							unknown:append(name .. '.' .. tostring(slot) .. ': ' .. label);
						end
					end
				end
				for _, suffix in ipairs(T{'Default', 'Hybrid', 'Acc'}) do
					local base = string.match(name, '^(.+)_' .. suffix .. '$');
					if (base ~= nil) then
						families[base] = families[base] or {};
						families[base][suffix] = true;
					end
				end
			end
		end
		local drift = T{};
		for iname, seen in pairs(pairSlots) do
			if (seen.ear1 and seen.ear2) or (seen.ring1 and seen.ring2) then drift:append(iname) end
		end
		table.sort(drift);
		local gaps = T{};
		for base, seen in pairs(families) do
			if (seen['Default'] == nil) and (gcinclude.FindSet(base) == nil) then gaps:append(base .. '_Default is missing (Hybrid/Acc exist)') end
		end
		gcinclude.Say('checksets: ' .. tostring(#empty) .. ' empty, ' .. tostring(#unknown) .. ' unknown items, ' .. tostring(#gaps) .. ' gaps, ' .. tostring(#drift) .. ' slot drifts');
		for _, v in ipairs(gaps) do gcinclude.Err(v) end
		for _, v in ipairs(unknown) do gcinclude.Err('unknown item ' .. v) end
		if (#moon > 0) and ((gcinclude.settings.MoonshadeTP or 0) > 0) then
			table.sort(moon);
			gcinclude.Say('Moonshade Earring in: ' .. table.concat(moon, ', ') .. ' - not needed, the engine adds it below MoonshadeTP on every WS (see README, Moonshade)');
		end
		if (#drift > 0) then
			gcinclude.Say('in both ear/ring slots across sets (swaps it out and back): ' .. table.concat(drift, ', '));
		end
		if (#empty > 0) then
			gcinclude.Say('empty: ' .. table.concat(empty, ', '));
		end
	end

	-- A set without Main/Sub/Range/Ammo: swapping those costs TP or a Hoxne Enchantment.
	function gcinclude.NoWeapons(set)
		local out = {};
		for k, v in pairs(set or {}) do
			if not gcinclude.WeaponSlots:contains(slotOf(k)) then out[k] = v end
		end
		return out;
	end

	-- Slept, petrified, stunned or terrorized: your /def set (mdt or Aminon; else Dt, as SIRD is midcast only)
	-- minus Main/Sub/Range/Ammo, then the job's Incapacitated set, then received gear.
	-- Not charmed: the client can't change gear then and GearSwap never sends any (Windower GearSwap flow.lua).
	gcinclude.IncapacitatedBuffs = T{'Sleep', 'Petrification', 'Stun', 'Terror'};
	local noWeaponsOf = setmetatable({}, { __mode = 'k' }); -- built once per set table
	function gcinclude.CheckIncapacitated()
		local hit = false;
		for _, b in ipairs(gcinclude.IncapacitatedBuffs) do
			if (gcinclude.BuffCount(b) > 0) then hit = true; break end
		end
		if not hit then return end
		local def;
		if (gcdisplay.GetToggle('Aminon') == true) then def = gcinclude.FindSet('Aminon') or gcinclude.FindSet('mdt');
		elseif (gcdisplay.GetToggle('MDTset') == true) then def = gcinclude.FindSet('mdt') end
		def = def or gcinclude.FindSet('Dt');
		if (def ~= nil) then
			if (noWeaponsOf[def] == nil) then noWeaponsOf[def] = gcinclude.NoWeapons(def) end
			gFunc.EquipSet(noWeaponsOf[def]);
		end
		local extra = gcinclude.FindSet('Incapacitated');
		if (extra ~= nil) then gFunc.EquipSet(extra) end
		gcinclude.CheckReceived(); -- gear for a Phalanx/Cure/etc. on its way still goes on top, as it does over /dt
	end

	function gcinclude.CheckCommonDebuffs()
		local weakened = gcinclude.BuffCount(1); -- Weakness (buff 1; the name is 'weakness', not 'Weakened')
		local sleep = gcinclude.BuffCount('Sleep');
		local doom = (gcinclude.BuffCount('Doom'))+(gcinclude.BuffCount('Bane'));

		gcinclude.CheckIncapacitated();
		if (sleep >= 1) then gFunc.EquipSet(gcinclude.FindSet('Sleeping') or gcinclude.sets.Sleeping) end
		if (doom >= 1) then	gFunc.EquipSet(gcinclude.sets.Doomed) end
		if (weakened >= 1) then gFunc.EquipSet(gcinclude.sets.Reraise) end
	end

	function gcinclude.CheckAbilityRecast(check)
		local res = AshitaCore:GetResourceManager():GetAbilityByName(check, 0);
		if (res == nil) then return 0 end
		local recast = AshitaCore:GetMemoryManager():GetRecast();
		for x = 0, 31 do
			if ((x == 0) or (res.RecastTimerId ~= 0)) and (recast:GetAbilityTimerId(x) == res.RecastTimerId) then
				return recast:GetAbilityTimer(x);
			end
		end
		return 0;
	end

	-- Ring1/Ring2 only (slots 14/15), read the way LAC's gData.GetEquipment does, without its 16-slot walk.
	function gcinclude.CheckLockingRings()
		for slot = 14, 15 do
			local item = gEquip.GetCurrentEquip(slot).Item;
			local res = (item ~= nil) and AshitaCore:GetResourceManager():GetItemById(item.Id) or nil;
			if (res ~= nil) and gcinclude.LockingRings:contains(res.Name[1]) then gFunc.Equip(slot, res.Name[1]) end
		end
	end

	function gcinclude.SetTownGear()
		local area = AshitaCore:GetResourceManager():GetString('zones.names', AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0));
		if (area ~= nil) and gcinclude.Towns:contains(area) then local t = gcinclude.FindSet('Town'); if (t ~= nil) then gFunc.EquipSet(t) end end
	end

	function gcinclude.SetRegenRefreshGear(player)
		local cfg = gcinclude.settings;
		if (cfg.AutoGear == false) then return end
		local function wear(name, pct, limit)
			if ((limit or 0) <= 0) or (pct == nil) or (pct >= limit) then return end
			local set = gcinclude.FindSet(name);
			if (set ~= nil) then gFunc.EquipSet(set) end
		end
		-- Regen/Refresh only out of combat and never over a manual /dt; auto Dt any time.
		if (gcdisplay.GetToggle('DTset') ~= true) and (not gcinclude.InCombat(player)) then
			wear('Idle_Regen', player.HPP, cfg.RegenGearHPP);
			wear('Idle_Refresh', player.MPP, cfg.RefreshGearMPP);
		end
		wear('Dt', player.HPP, cfg.DTGearHPP);
		local pet = gData.GetPet();
		if (pet ~= nil) then wear('Pet_Dt', pet.HPP, cfg.PetDTGearHPP) end
	end


	function gcinclude.CheckWsBailout()
		local player = gData.GetPlayer();
		local ws = gData.GetAction();
		if (player == nil) or (ws == nil) or (ws.Name == nil) then return false end
		if (player.TP < 1000) then return false end
		if (gcinclude.BuffCount('Amnesia') > 0) then return false end
		for _, name in ipairs(gcinclude.HardCC) do
			if (gcinclude.BuffCount(name) > 0) then return false end
		end
		local target = gData.GetActionTarget();
		local distance = (target ~= nil) and tonumber(target.Distance) or nil;
		if gcinclude.settings.WScheck and (distance ~= nil) and (not gcinclude.DistanceWS:contains(ws.Name)) and (distance > gcinclude.settings.WSdistance) then
			gcinclude.Say('Distance to mob is too far! Move closer or /wsdistance ##');
			return false;
		end
		return true;
	end

	function gcinclude.SafeSetIdle(tries)
		local mm = AshitaCore:GetMemoryManager();
		if (mm:GetPlayer():GetIsZoning() ~= 0) or (mm:GetInventory():GetEquippedItem(0) == nil) then
			if (tries < 30) then
				local function retry()
					gcinclude.SafeSetIdle(tries + 1);
				end
				retry:once(1);
			end
			return;
		end
		AshitaCore:GetChatManager():QueueCommand(-1, '/lac set Idle');
	end

	gcinclude.TeleRings = T{ warpring = 'warp_Ring', mea = 'mea_Ring', holla = 'holla_Ring', dem = 'dem_Ring' };

	function gcinclude.UseTeleRing(key)
		local ring = gcinclude.settings[key];
		if (type(ring) ~= 'string') then return end
		AshitaCore:GetChatManager():QueueCommand(-1, '/lac equip ring2 "' .. ring .. '"');
		local function restoreIdle()
			gcinclude.SafeSetIdle(0);
		end
		local function useRing()
			AshitaCore:GetChatManager():QueueCommand(-1, '/item "' .. ring .. '" <me>');
			restoreIdle:once(11);
		end
		useRing:once(11);
	end


	function gcinclude.DoNukes(tier)
		local cast = gcdisplay.GetCycle('Element');
		if (cast == 'Light') or (cast == 'Dark') then
			gcinclude.Err('/nuke: no tiered ' .. cast .. ' nuke; use /helix or /weather');
			return;
		end
		tier = ({ ['1'] = 'I', ['2'] = 'II', ['3'] = 'III', ['4'] = 'IV', ['5'] = 'V', ['6'] = 'VI' })[tostring(tier)] or string.upper(tostring(tier or ''));
		if not ({ I = true, II = true, III = true, IV = true, V = true, VI = true })[tier] then
			gcinclude.Err('usage: /nuke <1-6>');
			return;
		end
		if tier == "I" then
			AshitaCore:GetChatManager():QueueCommand(-1, '/ma "' .. cast .. '" <t>');
		else
			AshitaCore:GetChatManager():QueueCommand(-1, '/ma "' .. cast .. ' ' .. tier .. '" <t>');
		end
	end

	function gcinclude.DoCORmsg(roll)
		if gcinclude.CORmsg == false then return end

		for n = 1, #gcinclude.Rolls do
			if gcinclude.Rolls[n][1] == roll then
				print(chat.header('GCinclude'):append('[' .. chat.warning(roll) .. ']' .. '  [Lucky: ' .. chat.success(gcinclude.Rolls[n][2]) .. ']  [Unlucky: ' .. chat.error(gcinclude.Rolls[n][3]) .. ']'));
				return;
			end
		end
	end

	-- Castable now: learned (HasSpell) and the main or sub job meets the resource's level, or its job point
	-- requirement when JobPointMask marks the spell as a gift (same test as Thorny's tHotBar).
	function gcinclude.CanCast(name)
		local res = AshitaCore:GetResourceManager():GetSpellByName(name, 0);
		if (res == nil) then return false, nil end
		local p = AshitaCore:GetMemoryManager():GetPlayer();
		if (p == nil) or (not p:HasSpell(res.Index)) then return false, res end
		local req, mask = res.LevelRequired, res.JobPointMask;
		local mj, ml, sj, sl = p:GetMainJob(), p:GetMainJobLevel(), p:GetSubJob(), p:GetSubJobLevel();
		local need = req[mj + 1];
		if (bit.band(bit.rshift(mask, mj), 1) == 1) then
			if (ml == 99) and (p:GetJobPointsSpent(mj) >= need) then return true, res end
		elseif (need ~= nil) and (need ~= -1) and (ml >= need) then
			return true, res;
		end
		need = req[sj + 1];
		if (sj ~= 0) and (bit.band(bit.rshift(mask, sj), 1) == 0) and (need ~= nil) and (need ~= -1) and (sl >= need) then return true, res end
		return false, res;
	end

	-- First spell in the list that is castable and off recast.
	function gcinclude.CastBestTier(tiers, target)
		local recast = AshitaCore:GetMemoryManager():GetRecast();
		for _, name in ipairs(tiers) do
			local ok, res = gcinclude.CanCast(name);
			if ok and (recast:GetSpellTimer(res.Index) == 0) then
				AshitaCore:GetChatManager():QueueCommand(-1, '/ma "' .. name .. '" ' .. target);
				return true;
			end
		end
		return false;
	end

	function gcinclude.DoAspir()
		gcinclude.CastBestTier(T{'Aspir III', 'Aspir II', 'Aspir'}, '<t>');
	end

	function gcinclude.DoDrain()
		gcinclude.CastBestTier(T{'Drain III', 'Drain II', 'Drain'}, '<t>');
	end

	function gcinclude.DoSCHspells(spell)
		local list, target = nil, '<me>';
		if (spell == 'helix') then list, target = gcinclude.HelixSpells, '<t>';
		elseif (spell == 'weather') then list = gcinclude.StormSpells end
		if (list == nil) then return end
		local e = gcdisplay.GetCycle('Element');
		for i, v in ipairs(gcinclude.Elements) do
			if (v == e) and (list[i] ~= nil) then
				if not gcinclude.CastBestTier(T{list[i] .. ' II', list[i]}, target) then
					gcinclude.Err(list[i] .. ': not castable or on recast');
				end
				return;
			end
		end
	end

	function gcinclude.DoSiphon()
		local recast = gcinclude.CheckAbilityRecast('Elemental Siphon');
		if recast ~= 0 then
			print(chat.header('GCinclude'):append(chat.warning('Elemental Siphon not available yet!')));
			return;
		end
		local pet = gData.GetPet();
		local oldpet = 'none';
		local spirit = 'none';
		local spirits = {['Firesday'] = 'Fire Spirit', ['Earthsday'] = 'Earth Spirit', ['Watersday'] = 'Water Spirit', ['Windsday'] = 'Air Spirit', ['Iceday'] = 'Ice Spirit', ['Lightningday'] = 'Thunder Spirit', ['Lightsday'] = 'Light Spirit', ['Darksday'] = 'Dark Spirit'};
		local e = gData.GetEnvironment();

		local function release()
			AshitaCore:GetChatManager():QueueCommand(-1, '/ja "Release" <me>');
		end
		local function siphon()
			AshitaCore:GetChatManager():QueueCommand(-1, '/ja "Elemental Siphon" <me>');
		end
		local function castavatar()
			AshitaCore:GetChatManager():QueueCommand(-1, '/ma "' .. oldpet .. '" <me>');
		end
		local function castspirit()
			AshitaCore:GetChatManager():QueueCommand(-1, '/ma "' .. spirit .. '" <me>');
			siphon:once(4);
			release:once(6);
			if oldpet ~= 'none' then
				castavatar:once(8);
			end
		end

		if pet ~= nil then
			oldpet = pet.Name;
			release:once(1);
		end

		if (spirits[e.Day] ~= nil) then
			spirit = spirits[e.Day];
			castspirit:once(3);
		end
	end

	-- Runs the job's WS handler and records every Ear1/Ear2 value it asks for, in order, so the engine
	-- knows what each ear would hold without Moonshade.
	function gcinclude.TrackEars(fn, ...)
		local trail = { ear1 = {}, ear2 = {} };
		local function note(slot, item)
			local key = string.lower(tostring(slot));
			if (trail[key] ~= nil) then table.insert(trail[key], item) end
		end
		local equipSet, equip = gFunc.EquipSet, gFunc.Equip;
		gFunc.EquipSet = function(set, ...)
			local t = (type(set) == 'string') and gcinclude.FindSet(set) or set;
			if (type(t) == 'table') then
				for k, v in pairs(t) do note(k, v) end
			end
			return equipSet(set, ...);
		end
		gFunc.Equip = function(slot, item, ...)
			note(slot, item);
			return equip(slot, item, ...);
		end
		local ok, result = pcall(fn, ...);
		gFunc.EquipSet, gFunc.Equip = equipSet, equip;
		if not ok then error(result, 0) end
		return result, trail;
	end

	local function isMoonshade(v)
		local n = (type(v) == 'table') and v.Name or v;
		return (type(n) == 'string') and (string.lower(n) == 'moonshade earring');
	end

	-- Moonshade Earring, every WS: in settings.MoonshadeSlot below MoonshadeTP; at or above it, an ear the
	-- WS sets left on Moonshade goes back to the last other earring those sets gave it (or stays as worn).
	function gcinclude.CheckMoonshade(trail)
		local cfg = gcinclude.settings;
		local limit = cfg.MoonshadeTP or 0;
		if (limit <= 0) or (type(trail) ~= 'table') then return end
		local player, ws = gData.GetPlayer(), gData.GetAction();
		if (player == nil) or (ws == nil) then return end
		local skip = (type(cfg.MoonshadeSkip) == 'table') and cfg.MoonshadeSkip:contains(ws.Name);
		local want = (player.TP < limit) and (not skip);
		local slot = string.lower(cfg.MoonshadeSlot or 'Ear2');
		for _, ear in ipairs(T{'ear1', 'ear2'}) do
			local list = trail[ear];
			if want and (ear == slot) then
				gFunc.Equip(ear == 'ear1' and 'Ear1' or 'Ear2', 'Moonshade Earring');
			elseif (#list > 0) and isMoonshade(list[#list]) then
				local back = 'ignore';
				for i = #list, 1, -1 do
					if not isMoonshade(list[i]) then back = list[i]; break end
				end
				gFunc.Equip(ear == 'ear1' and 'Ear1' or 'Ear2', back);
			end
		end
	end


	-- Absorb spells: Absorb set for all of them, then Absorb_TP (or legacy AbsorbTP) for Absorb-TP.
	function gcinclude.CheckAbsorb()
		local spell = gData.GetAction();
		if (spell == nil) or (type(spell.Name) ~= 'string') or (string.sub(spell.Name, 1, 7) ~= 'Absorb-') then return end
		local set = gcinclude.FindSet('Absorb');
		if (set ~= nil) then gFunc.EquipSet(set) end
		if (spell.Name == 'Absorb-TP') then
			set = gcinclude.FindSet('Absorb_TP') or gcinclude.FindSet('AbsorbTP');
			if (set ~= nil) then gFunc.EquipSet(set) end
		end
	end

	function gcinclude.CheckCancels()--tossed Stoneskin in here too
		local action = gData.GetAction();
		local sneak = gcinclude.BuffCount('Sneak');
		local stoneskin = gcinclude.BuffCount('Stoneskin');
		local target = gData.GetActionTarget();
		local me = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0);

		local function do_jig()
			AshitaCore:GetChatManager():QueueCommand(-1, '/ja "Spectral Jig" <me>');
		end
		local function do_sneak()
			AshitaCore:GetChatManager():QueueCommand(-1, '/ma "Sneak" <me>');
		end
		local function do_ss()
			AshitaCore:GetChatManager():QueueCommand(-1, '/ma "Stoneskin" <me>');
		end

		if (action == nil) then return end
		if (action.Name == 'Spectral Jig' and sneak ~=0) then
			gFunc.CancelAction();
			AshitaCore:GetChatManager():QueueCommand(-1, '/cancel Sneak');
			do_jig:once(2);
		elseif (action.Name == 'Sneak' and sneak ~= 0 and target ~= nil and target.Name == me) then
			gFunc.CancelAction();
			AshitaCore:GetChatManager():QueueCommand(-1, '/cancel Sneak');
			do_sneak:once(1);
		elseif (action.Name == 'Stoneskin' and stoneskin ~= 0) then
			gFunc.CancelAction();
			AshitaCore:GetChatManager():QueueCommand(-1, '/cancel Stoneskin');
			do_ss:once(1);
		end
	end

local UTIL_ORDER = {'craftset', 'zeniset', 'fishset', 'rrset'};
function gcinclude.CheckDefault()
    -- Self-healing check: Rebuild toggles if the memory manager updates to a new job
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    if (player ~= nil) and (gcinclude.ActiveJobId ~= nil) then
        local mainJobId = player:GetMainJob();
        if (mainJobId ~= 0) and (mainJobId ~= gcinclude.ActiveJobId) then gcinclude.SetVariables() end
    end

    -- Auto Regen/Refresh/DT/Pet_Dt and Town sets count as "your sets", so they go under the engine layers
    -- (README layer order: your sets -> Hoxne sets -> weapons (+ TH weapons while /th is on) -> mdt/Aminon -> Hoxne -> TH -> received -> buffs -> XIRoll).
    -- Hoxne sets go first: over the job layers (Tp, Impetus...), under auto Dt and every engine layer.
    -- Awake again with a slot still let go for the Sleeping set: hold it now, not at the next 0.1s HoldTick,
    -- so this handler's job-set weapon can't cost the TP (LAC checks gState.Disabled when the buffer goes out).
    if (next(gcinclude.SleepFreed) ~= nil) and (gcinclude.BuffCount('Sleep') == 0) then gcinclude.UpdateHold() end
    local me = gData.GetPlayer(); -- one read for the auto sets, the combat check and XIRoll
    gcinclude.CheckHoxneSets(me);
    gcinclude.SetRegenRefreshGear(me);
    gcinclude.SetTownGear();
    gcinclude.CheckWeapons(me);
    gcinclude.CheckCommonDebuffs();
    gcinclude.CheckLockingRings();
    for _, cmd in ipairs(UTIL_ORDER) do
        if gcinclude.UtilOn[cmd] then gFunc.EquipSet(gcinclude.sets[gcinclude.UtilSets[cmd]]) end
    end
    gcdisplay.Update();
end

	function gcinclude.Unload()
			gcinclude.ClearKeybinds();
			gcauto.Stop();
			ashita.events.unregister('d3d_present', 'gcinclude_tphold');
			if (gchud ~= nil) then gchud.Stop() end
			gcinclude.UnlockSlots(nil);
			gcinclude.UnlockWeapons();
			if (gFunc.GcRawEquipSet ~= nil) then
				gFunc.EquipSet, gFunc.Equip = gFunc.GcRawEquipSet, gFunc.GcRawEquip;
				gFunc.GcRawEquipSet, gFunc.GcRawEquip = nil, nil;
			end
			if (gEquip ~= nil) and (gEquip.GcRawToBuffer ~= nil) then
				gEquip.EquipItemToBuffer, gEquip.ClearBuffer, gEquip.ProcessBuffer = gEquip.GcRawToBuffer, gEquip.GcRawClear, gEquip.GcRawProcess;
				gEquip.GcRawToBuffer, gEquip.GcRawClear, gEquip.GcRawProcess = nil, nil, nil;
			end
			gcdisplay.Unload();
			gcinclude.ClearAlias();
	end

function gcinclude.PlayerReady()
    local mm = AshitaCore:GetMemoryManager();
    if (mm == nil) then return false; end

    local p = mm:GetPlayer();
    local party = mm:GetParty();
    if (p == nil) or (party == nil) then return false; end

    local mainJobId = p:GetMainJob();
    if (mainJobId == nil) or (mainJobId == 0) then return false; end
    if (p:GetMainJobLevel() == nil) or (p:GetMainJobLevel() == 0) then return false; end
    if (party:GetMemberIsActive(0) ~= 1) then return false; end

    local name = party:GetMemberName(0);
    if (name == nil) or (name == '') then return false; end

    -- Fetch expected job abbreviation directly from memory
    local mainJobStr = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", mainJobId);

    -- Gate until gData exists AND has synced to match the current memory state
    local gp = gData.GetPlayer();
    if (gp == nil) or (gp.MainJob == nil) or (gp.MainJob == 'NON') or (gp.MainJob ~= mainJobStr) then
        return false;
    end

    return true;
end

	function gcinclude.InitStep(tries)
		tries = tries or 0;

		if not gcinclude.PlayerReady() then
			if (tries < 150) then
				local retry = function() gcinclude.InitStep(tries + 1); end
				retry:once(0.2);
			else
				gcinclude.Say('Init gave up waiting on player data after 30s.');
			end
			return;
		end

		gcdisplay.Initialize(gcinclude.settings);
		gcinclude.SetVariables();
		gcinclude.SetAlias();
		gcinclude.ApplyKeybinds();
		if (gcauto ~= nil) then gcauto.OnIncomingCast, gcauto.OnReceivedEnd = gcinclude.StartReceived, gcinclude.EndReceived end
		gcinclude.ApplyLockstyle();
		gcauto.Start();
		ashita.events.register('d3d_present', 'gcinclude_tphold', gcinclude.HoldTick);
		if (gchud ~= nil) then gchud.Start() end
	end

	function gcinclude.Initialize()
		gcinclude.WrapHoldHandlers();
		gcinclude.WrapEquip();
		gcinclude.WrapBuffer();
		gcinclude.InitStep(0);
	end

	return gcinclude;