-- /gcedit Settings: what each setting does and an example in the form its box takes (a number as is, text without
-- quotes, a table as Lua; nil for a checkbox). From the comments beside the defaults (gcruntime.lua, Settings) and
-- docs/settings.md, docs/commands.md (Keys). job: the job file's own options (docs/sets.md Job file, gcinclude.lua).
local settings = {
    Messages = { 'A chat line on every mode change and /gc toggle (DT, TH, Kite...); some always show.' },
    AutoGear = { 'Master switch for the auto sets: Idle_Regen, Idle_Refresh, Dt, Pet_Dt (by the HP/MP % below). /autogear changes them in game.' },
    WScheck = { 'Distance check: a non-ranged weapon skill goes off only within its reach (WS range 3 past your and '
        .. "the target's hitboxes, so further on a big mob; WSdistance at least)." },
    WSdistance = { 'The least reach in yalms (center to center) a non-ranged weapon skill gets, while WScheck is on; '
        .. 'a big mob gets more.', '5' },
    RegenGearHPP = { 'Idle_Regen below this HP %, out of combat only. 0 = never.', '60' },
    RefreshGearMPP = { 'Idle_Refresh below this MP %, out of combat only. 0 = never.', '60' },
    DTGearHPP = { 'Dt below this HP %, in any status. 0 = never.', '50' },
    PetDTGearHPP = { 'Pet_Dt below this pet HP %. 0 = never.', '50' },
    MoonshadeTP = { 'Moonshade Earring on every weapon skill below this TP, never at or above it. 0 = left alone.', '1750' },
    MoonshadeSlot = { 'The ear Moonshade goes in; the other one when the WS set has a right-ear-only Sortie earring there.', 'Ear2' },
    MoonshadeSkip = { 'Weapon skills that never get Moonshade.', "{ 'Myrkr' }" },
    DisplayBar = { "The status bar on load. Once /gcbar or a drag saved this character's bar (gcbar\\<name>.txt), its on/off wins." },
    DisplayBarX = { "The bar's x position on screen. Not set: centred at the top, or flush right with the HUD on. A drag or /gcbar pos saves a spot that wins; /gcbar reset.", '400' },
    DisplayBarY = { "The bar's y position on screen. A drag or /gcbar pos saves a spot that wins; /gcbar reset.", '0' },
    warp_Ring = { '/warpring: held in Ring2, used once its equip delay is up, then your normal ring comes back.', 'Warp Ring' },
    mea_Ring = { '/mea: held in Ring2, used once its equip delay is up, then your normal ring comes back.', 'Dim. Ring (Mea)' },
    dem_Ring = { '/dem: held in Ring2, used once its equip delay is up, then your normal ring comes back.', 'Dim. Ring (Dem)' },
    holla_Ring = { '/holla: held in Ring2, used once its equip delay is up, then your normal ring comes back.', 'Dim. Ring (Holla)' },
    WeaponTPGuard = { 'At or above this TP, Main/Sub/Range stay on against automatic swaps; /wm, /mw... still swap. 0 = action sets always get their weapons.', '1000' },
    IdleWeapons = { 'Not engaged: weapons your idle sets name (Idle, Town, Dt...) beat the weapon mode. Off = the weapon mode always.' },
    AftermathHold = { 'Aftermath up: Main/Sub/Range stay on against idle/engaged swaps; spells still get theirs; /wm still swaps.' },
    HoldExempt = { 'Spell skills and ability types that always get their weapon swaps.', "{ 'Singing', 'Geomancy', 'Corsair Roll' }" },
    SmartSwap = { 'Keeps Main/Sub/Range on for the KeepWeaponsFor spells instead of losing TP to a swap (/smartswap).' },
    SmartSwapTP = { 'SmartSwap acts only at or above this TP.', '1' },
    KeepWeaponsFor = { 'Spells that keep Main/Sub/Range: a name, or Spells (names they start with) while a Worn item is in Main or Sub.', "{ 'Dia II', { Spells = { 'Cure' }, Worn = { 'Daybreak' } } }" },
    EditorIgnoreSuggestions = { 'Exact set names /gcedit no longer suggests (Related tab), any case.', "{ 'Singing' }" },
    EditorBackupKeep = { 'Newest dated /gcedit backups kept per job file after a save. 0 = keep all.', '3' },
    EditorGroups = { 'Your /gcedit headings and their order; the heading menus write it.', "{ 'Weapons', 'Idle', { 'Two-handed', 'Tp_Chango' } }" },
    EditorHidden = { 'Headings /gcedit hides: on every job (all) or on one job.', "{ all = { 'Received' }, WAR = { 'Hoxne' } }" },
    EditorSort = { "How a heading sorts its sets: 'file' (the default), 'az' or 'own'.", "{ Melee = 'own', Casting = 'az' }" },
    EditorOrder = { "A heading's sets in your order (EditorSort 'own'); the rest follow in file order.", "{ Melee = { 'Tp_Default', 'Tp_Chango' } }" },
    EnchantWindow = { 'Seconds to wait when an enchanted item has no equip delay in its data.', '12' },
    EnchantDelays = { "An item's wait in seconds, in place of its equip delay.", "{ ['Reraise Earring'] = 30 }" },
    ReceivedSets = { 'Spell or ability name (lowercase, matched as a start) -> the set worn while it is on its way to you. This list replaces the whole default one.', "{ ['cure'] = 'Cure_Received', ['phalanx'] = 'Phalanx_Received' }" },
    ReceivedWindow = { 'Seconds received gear stays on before it gives up.', '8' },
    MyBoxes = { "Your characters that get the Multisend 'received' notice. Only needed when boxes aren't found by the HUD state file.", "{ 'YourMain', 'YourBox' }" },
    ElementReport = { 'A chat line naming the obi/Orpheus/ring/back each nuke or weapon skill got.' },
    OrpheusPoints = { "{ yalms, affinity % } points for Orpheus's Sash, a straight line between; add tested points in order.", '{ { 1.93, 15 }, { 13, 1 } }' },
    ElementGear = { "Waist (and ring, back) by the spell's element, day and weather: Obis, AnyObi, Distance (Orpheus), DistanceMax, Ring, RingSlot, Back, Cures, BackOnCures, Keep. Replaces the whole table: keep the keys you use.", "{ Obis = { Dark = 'Anrin Obi' }, AnyObi = 'Hachirin-no-Obi', Distance = \"Orpheus's Sash\", RingSlot = 'Ring2', Keep = { 'Oneiros Rope' } }" },
    MBWindow = { 'Magic burst window in seconds from the skillchain; another weapon skill on the mob ends it.', '10' },
    MBSkills = { 'Spell skills that wear Burst when they land in a live skillchain.', "{ 'Elemental Magic', 'Dark Magic' }" },
    ElementSkills = { 'Spell skills that get the obi, Orpheus and element ring.', "{ 'Elemental Magic', 'Blue Magic' }" },
    ElementalWS = { 'Elemental weapon skills and their element, for the same element gear. Replaces the whole list.', "{ ['Aeolian Edge'] = 'Wind', ['Leaden Salute'] = 'Dark' }" },
    CombatWindow = { 'Seconds you count as in combat after a monster hits you or a party member, or you act on one (auto Idle_Regen/Idle_Refresh wait for it).', '6' },
    SIRSkip = { "Spells /sir never goes over, on every job (their own set stays); a job's gcinclude.SIRSkip adds to it.", "{ 'Absorb-TP', 'Stun' }" },
    THSkip = { "Spells /th never goes over (their own set stays); a job's gcinclude.THSkip adds to it.", "{ 'Absorb-TP', 'Stun' }" },
    HoxneItem = { 'What the Hoxne states keep in your ammo slot.', 'Hoxne Ampulla' },
    HoxneLockSlots = { 'Slots the Hoxne Locked state locks.', "{ 'Ammo', 'Range' }" },
    HoxneAutoUse = { "Hoxne Locked: uses the Ampulla when it is in ammo and Enchantment isn't up." },
    Keybinds = { 'Your keys, the whole list: { key, command }. ^ Ctrl, ! Alt, + Shift, @ Win, # Apps. A command starting with / is bound as is. {} = none.', "{ { 'F7', 'wm' }, { '^F1', '/ja \"Provoke\" <t>' } }" },
    XIRollSet = { 'Worn idle while a Corsair roll sits at 11, when the job file has no XIRoll set.', "{ Ring2 = \"Roller's Ring\" }" },
    HUDOwners = { 'Your main(s): the HUD (the other boxes, under /gcbar) on with every load; others: /gchud.', "{ 'YourMain' }" },
    Theme = { "Colour preset shared with goomui: false = goomui's; a preset name (/gcbar theme lists them); 'goomswap' = GoomSwap's own. Typed as Lua.", "'ocean'" },
    HUDAbbr = { 'Extra short names you can type for a value (/wm carn).', "{ ['Carnwenhan'] = 'Carn' }" },
    WeaponClass = { "The bar's weapon colour for items it doesn't know: relic, mythic, empyrean, prime, aeonic or tpbonus.", "{ ['Item Name'] = 'tpbonus' }" },
    LockstyleSet = { '/lockstyleset N 4s after load and job change; a job file can set its own.', '3' },
    CapacityCapes = { '/capacity wears the carried one worth most (Mecisto. Mantle by its augment).', "{ 'Aptitude Mantle +1', 'Mecisto. Mantle' }" },
    JubileeSlot = { 'The ring slot /jubilee uses.', 'Ring1' },
    SleepCancelStoneskin = { 'Asleep with Stoneskin up: /cancel Stoneskin so damage can wake you.' },
}

-- { name, what it does, example (Lua; nil: a checkbox), the value when the file sets none, read-only }
local job = {
    { 'WeaponModes', 'The /wm cycle: one Weapon_<Name> set each. Save adds new Weapon_ sets to it; right-click a Weapon_ set to move it earlier or later.', nil, "{ 'None' }", true },
    { 'DefaultWeapons', "What /wm starts on at load and /wm default goes back to: a mode's name, or slots.", "{ Weapons = 'Naegling', Range = 'Anarchy +2' }", 'None' },
    { 'WeaponRoles', '/wm melee, ranged, caster or tank: the mode each one picks.', "{ melee = 'Savage', ranged = 'Leaden' }" },
    { 'MainModes', '/mw picks: these first, in order; every item your Weapon_ sets put in Main follows anyway.', "{ 'None', 'Naegling' }" },
    { 'SubModes', '/sw picks: these first, in order; every item your Weapon_ sets put in Sub follows anyway.', "{ 'None', 'Duban' }" },
    { 'RangeModes', '/rw picks: these first, in order; every item your Weapon_ sets put in Range follows anyway.', "{ 'None', 'Anarchy +2' }" },
    { 'WeaponItemMap', "A pick's name for one exact item, like an augment path (/mw rostama).", "{ RostamA = { Name = 'Rostam', AugPath = 'A' } }" },
    { 'AlwaysDualWield', 'Counts as able to dual wield whatever the support job (BLU: from its spells), so Weapon_<Mode>_1h is not used.', nil, 'false' },
    { 'MeleeModes', 'The /mset modes. + /mset mode (MELEE heading, Related tab) adds one.', nil, "{ 'Default', 'SubtleBlow', 'Acc' }", true },
    { 'NukeModes', "The /nukeset modes (RDM BLM SCH GEO WHM DRK).", "{ 'Power', 'Macc', 'OccultAcumen' }", "{ 'Power', 'Macc' } (DRK: { 'Power', 'OccultAcumen' })" },
    { 'profile.Packer', "LuAshitacast's own Packer list for this job: what /lac gear (the Packer plugin) fetches with every set's gear, char.lua's Packer and the items GoomSwap wears. A count, a stack (saved as its size) or all.", "{ 'Echo Drops', { Name = 'Trump Card', Quantity = 99 } }" },
    { 'SIRSkip', 'Spells /sir leaves alone on this job, on top of the SIRSkip setting.', "{ 'Phalanx' }" },
    { 'THSkip', 'Spells /th leaves alone on this job, on top of the THSkip setting.', "{ 'Absorb-TP' }" },
    { 'CureObi', 'Hachirin-no-Obi on Cure, Cura, Curaga in Light day or weather: true or false here wins over ElementGear.Cures.', 'true', 'ElementGear.Cures' },
    { 'SafeAmmo', "Ammo put on when a shot is stopped for blocked ammo (Hauksbok): a name, or by its last word.", "{ Bullet = 'Chrono Bullet', Arrow = 'Chrono Arrow' }" },
    { 'RangeAmmo', 'With that range weapon on, ammo of another kind (Arrow, Bullet, Bolt) becomes this one.', "{ ['Sparrowhawk +2'] = 'Chrono Arrow' }" },
    { 'CORmsg', 'COR: lucky and unlucky roll number messages.', nil, 'true' },
    { 'LockstyleSet', '/lockstyleset N 4s after load and job change, on this job.', '3', 'the LockstyleSet setting' },
}

-- Settings most never change (item names, game data, timing windows, what the editor's own menus write): shown
-- with Show all, when a file sets one, or in a search.
local advanced = {}
for _, k in ipairs({ 'HoxneItem', 'HoxneLockSlots', 'warp_Ring', 'mea_Ring', 'dem_Ring', 'holla_Ring', 'ElementalWS',
    'ReceivedSets', 'ReceivedWindow', 'OrpheusPoints', 'CombatWindow', 'MBWindow', 'EnchantWindow', 'EnchantDelays',
    'ElementSkills', 'CapacityCapes', 'XIRollSet', 'JubileeSlot', 'MoonshadeSlot', 'WeaponClass', 'HUDAbbr', 'MyBoxes',
    'DisplayBarX', 'DisplayBarY', 'EditorGroups', 'EditorHidden', 'EditorSort', 'EditorOrder', 'HoldExempt',
    'KeepWeaponsFor', 'WScheck' }) do
    advanced[k] = true
end

-- Number ranges: HP/MP % 0-100 (/autogear clamps the same), TP 0-3000 (the most TP there is), a count of backups
-- 0-1000 (gcsetfile Backups.Keep), seconds and yalms not below 0. { min, max (nil: none), whole numbers only }
local limits = {
    RegenGearHPP = { 0, 100, true }, RefreshGearMPP = { 0, 100, true }, DTGearHPP = { 0, 100, true },
    PetDTGearHPP = { 0, 100, true },
    MoonshadeTP = { 0, 3000, true }, WeaponTPGuard = { 0, 3000, true }, SmartSwapTP = { 0, 3000, true },
    EditorBackupKeep = { 0, 1000, true },
    WSdistance = { 0 }, EnchantWindow = { 0 }, ReceivedWindow = { 0 }, CombatWindow = { 0 }, MBWindow = { 0 },
    LockstyleSet = { 1, nil, true },
}

-- Job-file options the engine reads only on some jobs: shown on others only when the file sets them.
local jobOnly = {
    CORmsg = { COR = true },
    NukeModes = { RDM = true, BLM = true, SCH = true, GEO = true, WHM = true, DRK = true },
}

-- Plain names the Settings panel shows (the real key on hover), and the category each setting sits in.
local names = {
    Messages = 'Chat line on mode changes', AutoGear = 'Auto idle sets', WScheck = 'WS range check',
    WSdistance = 'WS range (yalms)', RegenGearHPP = 'Regen gear below HP %', RefreshGearMPP = 'Refresh gear below MP %',
    DTGearHPP = 'DT gear below HP %', PetDTGearHPP = 'Pet DT gear below pet HP %', MoonshadeTP = 'Moonshade below TP',
    MoonshadeSlot = 'Moonshade ear', MoonshadeSkip = 'Weapon skills without Moonshade', DisplayBar = 'Bar on load',
    DisplayBarX = 'Bar position X', DisplayBarY = 'Bar position Y', warp_Ring = '/warpring ring', mea_Ring = '/mea ring',
    dem_Ring = '/dem ring', holla_Ring = '/holla ring', WeaponTPGuard = 'Keep weapons from TP',
    IdleWeapons = "Idle sets' weapons win out of combat", AftermathHold = 'Keep weapons during Aftermath',
    HoldExempt = 'Always swap weapons for', SmartSwap = 'SmartSwap', SmartSwapTP = 'SmartSwap from TP',
    KeepWeaponsFor = 'Spells that keep your weapons', EditorIgnoreSuggestions = 'Hidden set suggestions',
    EditorBackupKeep = 'Backups kept per job file', EditorGroups = 'Set list headings', EditorHidden = 'Hidden headings',
    EditorSort = 'Heading sort order', EditorOrder = 'Your set order', EnchantWindow = 'Enchanted item wait (s)',
    EnchantDelays = 'Enchanted item waits', ReceivedSets = 'Sets for spells on their way to you',
    ReceivedWindow = 'Received set time (s)', MyBoxes = 'Your boxes (Multisend)', ElementReport = 'Chat line for element gear',
    OrpheusPoints = "Orpheus's Sash curve", ElementGear = 'Obi, Orpheus and element gear', MBWindow = 'Magic burst window (s)',
    MBSkills = 'Skills that magic burst', ElementSkills = 'Skills that get element gear', ElementalWS = 'Elemental weapon skills',
    CombatWindow = 'Combat window (s)', SIRSkip = 'Spells /sir skips', THSkip = 'Spells /th skips', HoxneItem = 'Hoxne item',
    HoxneLockSlots = 'Hoxne locked slots', HoxneAutoUse = 'Use the Ampulla by itself', Keybinds = 'Keys',
    XIRollSet = 'Set at a roll of 11', HUDOwners = 'HUD owners (your mains)', Theme = 'Colour theme',
    HUDAbbr = 'Short names you can type', WeaponClass = 'Weapon colours', LockstyleSet = 'Lockstyle set',
    CapacityCapes = 'Capacity capes', JubileeSlot = 'Jubilee Ring slot', SleepCancelStoneskin = 'Cancel Stoneskin when asleep',
    -- the job file's own
    WeaponModes = '/wm modes', DefaultWeapons = 'Weapons on load', WeaponRoles = '/wm melee, ranged, caster, tank',
    MainModes = '/mw picks', SubModes = '/sw picks', RangeModes = '/rw picks', WeaponItemMap = 'Pick names for exact items',
    AlwaysDualWield = 'Always dual wield', MeleeModes = '/mset modes', NukeModes = '/nukeset modes',
    ['profile.Packer'] = 'Packer', CureObi = 'Obi on cures', SafeAmmo = 'Ammo when a shot is stopped',
    RangeAmmo = 'Ammo per range weapon', CORmsg = 'Lucky / unlucky roll messages',
}
local categories = {
    { 'Common', { 'DTGearHPP', 'RefreshGearMPP', 'RegenGearHPP', 'WeaponTPGuard', 'MoonshadeTP', 'Messages', 'LockstyleSet',
        'DisplayBar', 'AutoGear' } },
    { 'Idle & defense', { 'AutoGear', 'RegenGearHPP', 'RefreshGearMPP', 'DTGearHPP', 'PetDTGearHPP', 'IdleWeapons',
        'CombatWindow', 'XIRollSet', 'SleepCancelStoneskin', 'HoxneItem', 'HoxneLockSlots', 'HoxneAutoUse' } },
    { 'Weapons', { 'WeaponTPGuard', 'AftermathHold', 'HoldExempt', 'SmartSwap', 'SmartSwapTP', 'KeepWeaponsFor' } },
    { 'Casting', { 'SIRSkip', 'THSkip', 'ElementGear', 'ElementSkills', 'OrpheusPoints', 'MBWindow', 'MBSkills',
        'ElementReport', 'ReceivedSets', 'ReceivedWindow', 'MyBoxes' } },
    { 'Weapon skills', { 'WScheck', 'WSdistance', 'MoonshadeTP', 'MoonshadeSlot', 'MoonshadeSkip', 'ElementalWS' } },
    { 'Items & Packer', { 'Packer', 'EnchantDelays', 'EnchantWindow', 'warp_Ring', 'mea_Ring', 'dem_Ring', 'holla_Ring',
        'CapacityCapes', 'JubileeSlot' } },
    { 'Keys', { 'Keybinds' } },
    { 'Bar & HUD', { 'DisplayBar', 'DisplayBarX', 'DisplayBarY', 'HUDOwners', 'HUDAbbr', 'WeaponClass', 'Theme' } },
    { 'Editor', { 'EditorBackupKeep', 'EditorIgnoreSuggestions', 'EditorGroups', 'EditorHidden', 'EditorSort',
        'EditorOrder' } },
}

return { settings = settings, job = job, advanced = advanced, limits = limits, jobOnly = jobOnly, names = names,
    categories = categories }
