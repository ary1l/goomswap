local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

local sets = {
    Idle = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Bhikku Crown +3',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Adamantite Armor',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Murky Ring',
        Ring2 = 'Shadow Ring',
        Back = 'Null Shawl',
        Waist = 'Carrier\'s Sash',
        Legs = 'Bhikku Hose +3',
        Feet = 'Nyame Sollerets',
    },
    Resting = {},
    Idle_Regen = {
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Body = 'Hiza. Haramaki +2',
        Hands = 'Rao Kote',
        Ring2 = 'Chirich Ring +1',
    },
    Town = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Bhikku Crown +3',
        Body = 'Nyame Mail',
        Legs = 'Mpaca\'s Hose',
    },

    Dt = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adamantite Armor',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Murky Ring',
        Ring2 = 'Defending Ring',
        Back = 'Moonbeam Cape',
        Waist = 'Plat. Mog. Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Dt_Impetus = { -- /dt + Impetus up: over Dt (Impetus down: Dt alone); Dt_Impetus_SubtleBlow over it
    },

    Weapon_Godhands = {
        Main = 'Godhands',
    },
    Tp_Default = {
        Ammo = 'Coiste Bodhar',
        Head = 'Bhikku Crown +3',
        Neck = 'Mnk. Nodowa +2',
        Ear1 = 'Telos Earring',
        Ear2 = 'Sherida Earring',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Malignance Gloves',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'Gere Ring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = '"Store TP"+10', [5] = 'Attack+20' } },
        Waist = 'Moonbow Belt +1',
        Legs = 'Bhikku Hose +3',
        Feet = 'Anch. Gaiters +4',
    },
    Tp_Acc = {
        Ear2 = 'Mache Earring +1',
        Hands = 'Tatena. Gote +1',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
        Feet = 'Tatena. Sune. +1',
    },
    Midcast = {},

    Precast = {
        Ammo = 'Staunch Tathlum +1',
        Neck = 'Baetyl Pendant',
        Ear2 = 'Etiolation Earring',
    },

    Preshot = {
    },
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },

    Ws_Default = {
        Ammo = 'Knobkierrie',
        Head = 'Mpaca\'s Cap',
        Neck = 'Mnk. Nodowa +2',
        Ear2 = 'Schere Earring',
        Body = 'Bhikku Cyclas +3',
        Hands = 'Bhikku Gloves +3',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Moonbow Belt +1',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Anch. Gaiters +4',
    },

    ['Victory Smite'] = {
        Ear1 = 'Sherida Earring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Legs = 'Mpaca\'s Hose',
    },
    ['Victory Smite_Impetus'] = {
        Ammo = 'Coiste Bodhar',
        Ear2 = 'Schere Earring',
        Ear1 = 'Sherida Earring',
        Body = 'Bhikku Cyclas +3',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
    },

    ['Howling Fist'] = {
        Ammo = 'Knobkierrie',
        Head = 'Mpaca\'s Cap',
        Neck = 'Mnk. Nodowa +2',
        Ear2 = 'Schere Earring',
        Body = 'Bhikku Cyclas +3',
        Hands = 'Bhikku Gloves +3',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'STR+30', [4] = 'Attack+20', [5] = 'Accuracy+20' } },
        Waist = 'Moonbow Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    ['Dragon Kick'] = {
        Ammo = 'Knobkierrie',
        Head = 'Mpaca\'s Cap',
        Neck = 'Mnk. Nodowa +2',
        Ear2 = 'Schere Earring',
        Body = 'Bhikku Cyclas +3',
        Hands = 'Bhikku Gloves +3',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Moonbow Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Anch. Gaiters +4',
    },

    ['Tornado Kick'] = {
        Ammo = 'Knobkierrie',
        Head = 'Mpaca\'s Cap',
        Neck = 'Mnk. Nodowa +2',
        Ear2 = 'Schere Earring',
        Body = 'Bhikku Cyclas +3',
        Hands = 'Bhikku Gloves +3',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Moonbow Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Anch. Gaiters +4',
    },

    Tp_Impetus = {--over rides your TP set if impetus is up
        Ear1 = 'Dedition Earring',
        Body = 'Bhikku Cyclas +3',
    },

    Focus = {
        Head = 'Anchor. Crown +4',
    },
    Dodge = {
        Feet = 'Anch. Gaiters +4',
    },
    Chakra = {
        Body = 'Anch. Cyclas +4',
        Hands = 'Hes. Gloves',
    },
    Footwork = {--this is used on JA activation
        Feet = 'Bhikku Gaiters +3',
    },
    Tp_Footwork = {--this will override your TP while footwork is active
        Feet = 'Bhikku Gaiters +3',
    },
    ['Hundred Fists'] = {
        Legs = 'Hes. Hose +3',
    },
    ['Formless Strikes'] = {
        Body = 'Hes. Cyclas',
    },
    Counterstance = {--these feet are also for Mantra
        Feet = 'Hes. Gaiters',
    },
    Mantra = {--these feet are also for Mantra
        Feet = 'Hes. Gaiters',
    },
    Buffs = { -- worn while that buff is up (engine layer, on top of Dt/TH)
        ['Boost'] = { Waist = 'Ask Sash' }, -- Boost: "Regain"+200 only while the sash stays on (FFXIAH Ask Sash thread)
    },

    TH = {
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Potency of "Cure" effect received+5%', [2] = 'Mag. Acc.+19', [3] = 'Accuracy+21', [4] = '"Mag. Atk. Bns."+19', [5] = '"Treasure Hunter"+2' } },
    },
    Movement = {
        Feet = 'Herald\'s Gaiters',
    },
    XIRoll = { -- worn standing idle with a roll at 11
        Ring2 = 'Roller\'s Ring',
    },
    -- Templates: fill the ones you use; an empty set changes nothing.
    Buffs_Ws = { -- while the buff is up: weapon skills
        ['Aftermath: Lv.3'] = {},
    },
};
profile.Sets = sets;

-- Kept in your bags for this job by /lac gear (the Packer plugin), with every set's gear; /gcedit Settings edits it.
profile.Packer = {
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None', 'Godhands'};
    gcinclude.DefaultWeapons = 'Godhands';
    gcinclude.MeleeModes = {'Default', 'SubtleBlow', 'Acc', 'Hybrid'}; -- /mset hybrid: Tp_Hybrid (mid DT)
    gcinclude.settings.RefreshGearMPP = 0; -- no auto Idle_Refresh on this job; /autogear refresh 60 (or set it here) to turn it on
    -- Rules (/gcedit, RULES): when this, wear that, as data.
    gcinclude.Rules = {
        { on = 'Default', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Default', when = { buff = 'Impetus', toggle = { dt = true } }, wear = 'Dt_Impetus' },
        { on = 'Default', when = { toggle = { kite = true } }, wear = 'Movement', exact = true },
        { on = 'Weaponskill', when = { buff = 'Impetus', name = 'Victory Smite' }, wear = 'Victory Smite_Impetus' },
        { on = 'Ability', when = { name = 'Boost' }, wear = "Buffs['Boost']", exact = true, note = 'sash on from the start' },
    };
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
    local player = gData.GetPlayer();

    if (player.Status == 'Engaged') then
        gcinclude.EquipMode('Tp');
        if (gcinclude.BuffCount('Impetus') > 0) then ByName('Tp_Impetus') end -- then Tp_Impetus_<mset> (Tp_Impetus_Hybrid)
        if (gcinclude.BuffCount('Footwork') > 0) then gFunc.EquipSet(sets.Tp_Footwork) end
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
        gFunc.EquipSet(sets.Movement);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    ByName(ability.Name); -- a set named after the ability, e.g. ['Focus'], ['Hundred Fists']
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
    ByName(ws.Name); -- e.g. ['Victory Smite'], then ['Victory Smite_<mset>']
end

return profile;
