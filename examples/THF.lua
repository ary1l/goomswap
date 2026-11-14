local profile = {};
if (gFunc == nil) then error('GoomSwap: GearSwap loaded this job file directly. Windower: move it to data/goomswap/<Name>/<JOB>.lua and delete it from data/<Name>/ (see docs/windower.md)', 0) end
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
-- gcinclude.Food = {'Grape Daifuku +1'}; -- this job's food: /packer keeps a stack of each (replaces the Food setting / char.lua's)
-- gcinclude.Packer = { ['Echo Drops'] = 'stack', ['Holy Water'] = 'stack' }; -- kept in inventory on job change (/packer, Bellhop plugin)
gcinclude.THFullTime = true; -- /th keeps the TH set on the whole fight (THF default anyway; false = only until the mob is tagged)


local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Malignance Gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Defending Ring',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Resting = {},
    Idle_Regen = {
        --Head = 'Meghanada Visor +2',
        --Neck = 'Bathy Choker +1',
        --Ear1 = 'Infused Earring',
        --Hands = 'Meg. Gloves +2',
        Ring1 = 'Chirich Ring +1',
        --Feet = 'Meg. Jam. +2',
    },
    Idle_Refresh = {},
    Idle_Regain = { -- /idleset regain: over Idle while idle
    },
    Town = {
        Head = 'Gleti\'s Mask',
        Neck = 'Asn. Gorget +2',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Skulk. Earring +2',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shneddick Ring',
        Ring2 = 'Defending Ring',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Dt = {
        Head = 'Nyame Helm',
        Neck ='Loricate Torque +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Gelatinous Ring',
        Ring2 = 'Defending Ring',
        Back = 'Null Shawl',
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Weapon_Mpu = {
        Main = 'Mpu Gandring',
        Sub = 'Fusetto +2',
    },
    Weapon_MpuAcc = {
        Main = 'Mpu Gandring',
        Sub = 'Gleti\'s Knife',
    },
    Weapon_Naegling = {
        Main = 'Naegling',
        Sub = 'Fusetto +2',
    },
    Tp_Default = {
        Ammo = 'Coiste Bodhar',
        Head = 'Gleti\'s Mask',
        Neck = { Name = 'Asn. Gorget +2', AugPath='A' },
        Ear1 = 'Sherida Earring',
        Ear2 = 'Skulk. Earring +2',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Epona\'s Ring',
        Back = 'Null Shawl',
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Tp_SubtleBlow = { -- /mset subtleblow: Subtle Blow pieces over Tp_Default
    },
    Tp_Acc = {
        --Ammo = "Ginsen",
        Head = 'Malignance Chapeau',
        --Neck = 'Sanctity Necklace',
        --Ear1 = 'Mache Earring +1',
        Hands = 'Malignance Gloves',
        --Ring1 = 'Cacoethic Ring +1',
        Ring1 = 'Chirich Ring +1',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Midcast = {},


    Precast = {
        Head = 'Haruspex Hat',
        Neck = 'Voltsurge Torque',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Taeon Tabard',
        Hands = 'Leyline Gloves',
        Ring1 = 'Prolix Ring',
        Legs = 'Enif Cosciales',
    },

    Preshot = {
    },
    Midshot = {
        Head = 'Malignance Chapeau',
        Neck = 'Iskur Gorget',
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
        Body = 'Mummu Jacket +2',
        Hands = 'Plun. Armlets +3',
        Ring1 = 'Dingir Ring',
        Waist = 'Eschan Stone',
    },

    Ws_Default = {
        Ammo = "Yetshila +1",
        Head = 'Pill. Bonnet +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Odr Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Pillager\'s Vest +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Regal Ring',
        Ring2 = 'Ilabrat Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'Fotia Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Accuracy+14', [3] = 'Attack+26', [4] = 'DEX+8' } },
    },
    Ws_Default_SA = {
    },
    Ws_Default_TA = {
    },
    Ws_Default_SATA = {
    },
    Ws_SubtleBlow_SA = {},
    Ws_SubtleBlow_TA = {},
    Ws_SubtleBlow_SATA = {},
    Ws_Acc = {
    },
    Ws_Acc_SA = {},
    Ws_Acc_TA = {},
    Ws_Acc_SATA = {},

    Evisceration = {
        Head = 'Pill. Bonnet +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Odr Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Plunderer\'s Vest +3',
        --Hands = 'Meg. Gloves +2',
        Ring1 = 'Regal Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'Fotia Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Accuracy+14', [3] = 'Attack+26', [4] = 'DEX+8' } },
    },
    Evisceration_SA = {
    },
    Evisceration_TA = {

    },
    Evisceration_SATA = {
    },
    Evisceration_SubtleBlow_SA = {},
    Evisceration_SubtleBlow_TA = {},
    Evisceration_SubtleBlow_SATA = {},
    Evisceration_Acc = {
    },
    Evisceration_Acc_SA = {},
    Evisceration_Acc_TA = {},
    Evisceration_Acc_SATA = {},

    ['Rudra\'s Storm'] = {
        Head = 'Nyame Helm',
        Neck = 'Asn. Gorget +2',
        Ear1 = 'Sherida Earring',
        Body = 'Plunderer\'s Vest +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Regal Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'Kentarch Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Rudra\'s Storm_SA'] = {
    },
    ['Rudra\'s Storm_TA'] = {

    },
    ['Rudra\'s Storm_SATA'] = {
    },
    ['Rudra\'s Storm_SubtleBlow_SA'] = {},
    ['Rudra\'s Storm_SubtleBlow_TA'] = {},
    ['Rudra\'s Storm_SubtleBlow_SATA'] = {},
    ['Rudra\'s Storm_Acc'] = {
    },
    ['Rudra\'s Storm_Acc_SA'] = {},
    ['Rudra\'s Storm_Acc_TA'] = {},
    ['Rudra\'s Storm_Acc_SATA'] = {},

    ['Savage Blade'] = {
        Ammo = 'Coiste Bodhar',
        Head = 'Nyame Helm',
        Neck = { Name = 'Asn. Gorget +2', AugPath='A' },
        Ear1 = 'Telos Earring',
        Body = 'Plunderer\'s Vest +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Regal Ring',
        Ring2 = 'Hetairoi Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'Kentarch Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Savage Blade_SA'] = {
    },
    ['Savage Blade_TA'] = {

    },
    ['Savage Blade_SATA'] = {
    },
    ['Savage Blade_SubtleBlow_SA'] = {},
    ['Savage Blade_SubtleBlow_TA'] = {},
    ['Savage Blade_SubtleBlow_SATA'] = {},
    ['Savage Blade_Acc'] = {
    },
    ['Savage Blade_Acc_SA'] = {},
    ['Savage Blade_Acc_TA'] = {},
    ['Savage Blade_Acc_SATA'] = {},

    ['Aeolian Edge'] = {
        Ammo = "C. Palug Stone",
        Head = 'Nyame Helm',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Friomisi Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    ['Aeolian Edge_SA'] = {
    },

    ['Aeolian Edge_TA'] = {
    },
    ['Aeolian Edge_SATA'] = {
    },
    ['Aeolian Edge_SubtleBlow_SA'] = {},
    ['Aeolian Edge_SubtleBlow_TA'] = {},
    ['Aeolian Edge_SubtleBlow_SATA'] = {},
    ['Aeolian Edge_Acc'] = {
    },
    ['Aeolian Edge_Acc_SA'] = {},
    ['Aeolian Edge_Acc_TA'] = {},
    ['Aeolian Edge_Acc_SATA'] = {},

    SATA = {

    },
    SA = {

    },
    TA = {

    },
    ['TH'] = {
        Sub = 'Gandring', -- held while /th is on, even after the tag (a Sub swap resets TP)
        Head = 'Herculean Helm',
        Hands = 'Plun. Armlets +3',
    },
    Flee = {
        Feet = 'Pill. Poulaines +2',
    },
    -- Hoxne: /hoxne Locked + Enchantment up (Double Attack +100%). Per slot, later wins; leave a slot out to keep the one under.
    -- Idle/TP: job sets (Tp, buff sets, Dt) -> Hoxne_Tp|Idle|Dt -> its _SubtleBlow/_Acc -> its _<buff> combos -> engine layers.
    -- WS: job WS sets -> Hoxne_Ws -> Hoxne_<ws> -> Hoxne_Ws_<buff> -> Hoxne_<ws>_<buff> -> Buffs_Ws, Moonshade, obi.
    -- Combos: <set>_<buff>, <set>_<buff>&<buff> (all up); fewest buffs first, then A-Z. Full order: docs/sets.md (How sets stack).
    Hoxne_Tp = {},
    Hoxne_Idle = {},
    Hoxne_Dt = {}, -- instead of Hoxne_Tp/Hoxne_Idle while /dt is on
    Hoxne_Ws = {}, -- every WS
    ['Hoxne_Tp_Sneak Attack'] = {},
    ['Hoxne_Tp_Trick Attack'] = {},
    ['Hoxne_Tp_Sneak Attack&Trick Attack'] = {}, -- SATA: over the two above
    ['Hoxne_Savage Blade'] = {}, -- that WS, over Hoxne_Ws
    ['Hoxne_Ws_Sneak Attack'] = {}, -- buff combos go over the WS sets
    ['Hoxne_Ws_Trick Attack'] = {},
    ['Hoxne_Ws_Sneak Attack&Trick Attack'] = {},
    ['Hoxne_Savage Blade_Sneak Attack'] = {}, -- one WS with one buff

    Movement = {
        Feet = 'Pill. Poulaines +2',
    },
    -- Templates: fill the ones you use; an empty set changes nothing.
    Proc = {}, -- /proc: low-damage gear for proc windows (Abyssea, Vagary...), over the engaged sets
    Ws_Proc = {}, -- /proc on weapon skills (empty: Proc)
    Ws_HighBuff = {}, -- /wsset high: over Ws_Default (PDL)
    ['Rudra\'s Storm_HighBuff'] = {}, -- /wsset high: this WS
    Buffs = { -- while the buff is up: idle and engaged
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Ws = { -- while the buff is up: weapon skills
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Midcast = { -- while the buff is up: spells (e.g. ['Saboteur'])
    },
    -- Weapon_Mpu_Acc = { Main = 'Item Name' }, -- /mset acc: a whole weapon set in place of Weapon_Mpu
    -- Weapon_Mpu_1h = { Main = 'Item Name', Sub = 'Shield Name' }, -- when you can't dual wield (/dw off, sub not NIN/DNC)
    Absorb = {}, -- every Absorb- spell (land rate: Dark Magic skill, macc; potency is not skill)
    Absorb_TP = {}, -- Absorb-TP on top of Absorb
    Cure_Received = {
    },
    Cursna_Received = {
    },
    Phalanx_Received = {
    },
    Protect_Shell_Received = {
    },
    Regen_Received = {
    },
    Refresh_Received = {
    },
    Waltz_Received = {
    },
};
profile.Sets = sets;



local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.AlwaysDualWield = true;
    gcinclude.WeaponModes = {'None', 'Mpu', 'Naegling'}; -- Weapon_MpuAcc goes on with /mset Acc
    gcinclude.DefaultWeapons = 'Mpu';
    gcinclude.MainModes = {'None', 'Mpu Gandring', 'Naegling'};
    gcinclude.SubModes = {'None', 'Gleti\'s Knife', 'Fusetto +2', 'Gandring'};
    gcinclude.settings.RefreshGearMPP = 0; -- no auto Idle_Refresh on this job; /autogear refresh 60 (or set it here) to turn it on
    gcinclude.Initialize();
end

profile.OnUnload = function()
    gcinclude.Unload();
end

profile.HandleCommand = function(args)
    gcinclude.HandleCommands(args);
end

profile.HandleDefault = function()
    gcinclude.EquipIdle(); -- Idle, then Idle_<mode> (/idleset)
    local sa = gcinclude.BuffCount('Sneak Attack');
    local ta = gcinclude.BuffCount('Trick Attack');

    local player = gData.GetPlayer();
    if (player.Status == 'Engaged') then
        gcinclude.EquipMode('Tp');
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
        gFunc.EquipSet(sets.Movement);
    end

    if (sa == 1) and (ta == 1) then
        gFunc.EquipSet(sets.SATA);
    elseif (sa == 1) then
        gFunc.EquipSet(sets.SA);
    elseif (ta == 1) then
        gFunc.EquipSet(sets.TA);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end;
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end;
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    ByName(ability.Name); -- a set named after the ability, e.g. ['Flee']
    gcinclude.CheckCancels();
end

profile.HandlePrecast = function()
    local spell = gData.GetAction();
    gFunc.EquipSet(sets.Precast);
    ByName(spell.Skill .. '_Precast'); -- e.g. ['Healing Magic_Precast']
    ByName(Family(spell.Name) .. '_Precast'); -- e.g. ['Stoneskin_Precast'], on top
    gcinclude.CheckCancels();
end

profile.HandleMidcast = function()
    local spell = gData.GetAction();
    gFunc.EquipSet(sets.Midcast);
    ByName(spell.Skill); -- e.g. ['Enhancing Magic']
    if not ByName(spell.Name) then ByName(Family(spell.Name)) end -- e.g. ['Cure'] for Cure IV
    gcinclude.CheckTH();
end

profile.HandlePreshot = function()
    gFunc.EquipSet(sets.Preshot);
end

profile.HandleMidshot = function()
    gFunc.EquipSet(sets.Midshot);

    gcinclude.CheckTH();
end

profile.HandleWeaponskill = function()
    if (gcinclude.CheckWsBailout() == false) then gFunc.CancelAction(); return end
    local ws = gData.GetAction();
    gcinclude.EquipMode('Ws');
    ByName(ws.Name); -- e.g. ['Rudra\'s Storm'], then ['Rudra\'s Storm_<mset>']
    -- Sneak/Trick Attack on top: ['<WS>_SA'] / _TA / _SATA (['<WS>_Acc_SA'] with /mset acc), else Ws_<mset>_SA ...
    local sa, ta = gcinclude.BuffCount('Sneak Attack'), gcinclude.BuffCount('Trick Attack');
    local suffix = ((sa > 0) and (ta > 0) and 'SATA') or ((sa > 0) and 'SA') or ((ta > 0) and 'TA') or nil;
    if (suffix ~= nil) then
        local mode = gcdisplay.GetCycle('MeleeSet');
        local set = gcinclude.FindSet(ws.Name .. ((mode == 'Default') and '' or ('_' .. mode)) .. '_' .. suffix);
        if (set == nil) or (next(set) == nil) then set = gcinclude.FindSet('Ws_' .. mode .. '_' .. suffix) end
        if (set ~= nil) then gFunc.EquipSet(set) end
    end
end

return profile;
