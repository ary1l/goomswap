local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
gcinclude.THFullTime = true; -- /th keeps the TH set on the whole fight (THF default anyway; false = only until the mob is tagged)

local sets = {
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

    Movement = {
        Feet = 'Pill. Poulaines +2',
    },
    XIRoll = { -- worn standing idle with a roll at 11
        Ring2 = 'Roller\'s Ring',
    },
    -- Templates: fill the ones you use; an empty set changes nothing.
    Buffs = { -- while the buff is up: idle and engaged
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Ws = { -- while the buff is up: weapon skills
        ['Aftermath: Lv.3'] = {},
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
    if (gcdisplay.GetToggle('DTset') == true) then ByName('Dt') end -- then Dt_<mset> (Dt_SubtleBlow)
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
