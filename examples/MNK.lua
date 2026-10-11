local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'bhikku crown +3',
        Neck = 'warder\'s charm +1',
        Ear1 = 'alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'adamantite armor',
        Hands = 'nyame gauntlets',
        Ring1 = 'murky ring',
        Ring2 = 'shadow ring',
        Back = 'null shawl',
        Waist = 'carrier\'s sash',
        Legs = 'bhikku hose +3',
        Feet = 'nyame sollerets',
    },
    Resting = {},
    Idle_Regen = {
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Body = 'Hiza. Haramaki +2',
        Hands = 'Rao Kote',
        Ring1 = 'Chirich Ring +1',
    },
    Idle_Refresh = {},
    Town = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Bhikku Crown +3',
        Body = 'nyame mail',
        Legs = 'Mpaca\'s Hose',
    },

    Dt = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'alabaster earring',
        Ear2 = 'Etiolation Earring',
        Body = 'adamantite armor',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'murky Ring',
        Ring2 = 'defending ring',
		Back = 'moonbeam cape',
        Waist = 'plat. mog. belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Weapon_Godhands = {
        Main = 'Godhands',
    },
    Tp_Default = {
        Ammo = 'Coiste Bodhar',
        Head = 'bhikku crown +3',
        Neck = 'Mnk. Nodowa +2',
        Ear1 = 'telos earring',
        Ear2 = 'Sherida Earring',
        Body = 'mpaca\'s doublet',
        Hands = 'malignance gloves',
        Ring1 = 'niqmaddu ring',
        Ring2 = 'gere Ring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = '"Store TP"+10', [5] = 'Attack+20' } },
        Waist = 'Moonbow Belt +1',
        Legs = 'bhikku hose +3',
        Feet = 'anch. gaiters +4',
    },
    Tp_Hybrid = {
        Head = 'Mpaca\'s Cap',
        Neck = 'Sanctity Necklace',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Mpaca\'s Gloves',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    Tp_Acc = {
        Ear2 = 'Mache Earring +1',
        Hands = 'Tatena. Gote +1',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Cacoethic Ring +1',
        Feet = 'Tatena. Sune. +1',
    },


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
        Ear1 = 'schere Earring',
        Body = 'bhikku cyclas +3',
        Hands = 'bhikku gloves +3',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'ephramad\'s Ring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Moonbow Belt +1',
        Legs = 'Mpaca\'s Hose',
        Feet = 'anch. gaiters +4',
    },
    Ws_Hybrid = {
    },
    Ws_Acc = {
    },

    Victory_Default = {
        Ear1 = 'Sherida Earring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Legs = 'Mpaca\'s Hose',
    },
    Victory_Imp = {
        Ammo = 'Coiste Bodhar',
        Ear1 = 'Schere Earring',
        Ear2 = 'Sherida Earring',
        Body = 'Bhikku Cyclas +3',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
    },
    Victory_Hybrid = {},
    Victory_Acc = {},

    Shijin_Default = {
    },
    Shijin_Hybrid = {},
    Shijin_Acc = {},

	Howling_Default = {
        Ammo = 'Knobkierrie',
        Head = 'Mpaca\'s Cap',
        Neck = 'Mnk. Nodowa +2',
        Ear1 = 'schere Earring',
        Body = 'bhikku cyclas +3',
        Hands = 'bhikku gloves +3',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'ephramad\'s Ring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'STR+30', [4] = 'Attack+20', [5] = 'Accuracy+20' } },
        Waist = 'Moonbow Belt +1',
        Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },
    Howling_Hybrid = {},
    Howling_Acc = {},


	kickws_Default = {
        Ammo = 'Knobkierrie',
        Head = 'Mpaca\'s Cap',
        Neck = 'Mnk. Nodowa +2',
        Ear1 = 'schere earring',
        Body = 'bhikku cyclas +3',
        Hands = 'bhikku gloves +3',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'ephramad\'s Ring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Moonbow Belt +1',
        Legs = 'nyame flanchard',
        Feet = 'anch. gaiters +4',
    },
    kickws_Hybrid = {},
    kickws_Acc = {},


    Impetus = {--over rides your TP set if impetus is up
		Ear2 = 'dedition earring',
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
    FootworkJA = {--this is used on JA activation
        Feet = 'Bhikku Gaiters +3',
    },
    Footwork = {--this will override your TP while footwork is active
        Feet = 'Bhikku Gaiters +3',
    },
    HundredFists = {
        Legs = 'Hes. Hose +3',
    },
    FormlessStrikes = {
        Body = 'Hes. Cyclas',
    },
    Counterstance = {--these feet are also for Mantra
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

profile.Packer = {
};

profile.OnLoad = function()
	gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None', 'Godhands'};
    gcinclude.DefaultWeapons = 'Godhands';
    gcinclude.Initialize();
end

profile.OnUnload = function()
    gcinclude.Unload();
end

profile.HandleCommand = function(args)
    gcinclude.HandleCommands(args);
end

profile.HandleDefault = function()
    gFunc.EquipSet(sets.Idle);
	local player = gData.GetPlayer();

    if (player.Status == 'Engaged') then
        gcinclude.EquipMode('Tp');
        if (gcinclude.BuffCount('Impetus') > 0) then gFunc.EquipSet(sets.Impetus) end
        if (gcinclude.BuffCount('Footwork') > 0) then gFunc.EquipSet(sets.Footwork) end
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
		gFunc.EquipSet(sets.Movement);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end;
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end;
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();

    if string.match(ability.Name, 'Focus') then gFunc.EquipSet(sets.Focus);
    elseif string.match(ability.Name, 'Dodge') then gFunc.EquipSet(sets.Dodge);
    elseif string.match(ability.Name, 'Hundred Fists') then gFunc.EquipSet(sets.HundredFists);
    elseif string.match(ability.Name, 'Chakra') then gFunc.EquipSet(sets.Chakra);
    elseif string.match(ability.Name, 'Footwork') then gFunc.EquipSet(sets.FootworkJA);
    elseif string.match(ability.Name, 'Counterstance') or string.match(ability.Name, 'Mantra') then gFunc.EquipSet(sets.Counterstance);
    elseif string.contains(ability.Name, 'Formless Strikes') then gFunc.EquipSet(sets.FormlessStrikes)
    elseif (ability.Name == 'Boost') then gFunc.EquipSet(sets.Buffs.Boost) end -- sash on from the start

    gcinclude.CheckCancels();
end

profile.HandleItem = function()
    local item = gData.GetAction();

	if string.match(item.Name, 'Holy Water') then gFunc.EquipSet(gcinclude.sets.Holy_Water) end
end

profile.HandlePrecast = function()
    gFunc.EquipSet(sets.Precast);

    gcinclude.CheckCancels();
end

profile.HandleMidcast = function()
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

    if string.match(ws.Name, 'Victory Smite') then
        gFunc.EquipSet(sets.Victory_Default)
        if (gcinclude.BuffCount('Impetus') > 0) then gFunc.EquipSet(sets.Victory_Imp) end
        if (gcdisplay.GetCycle('MeleeSet') ~= 'Default') then
        gFunc.EquipSet('Victory_' .. gcdisplay.GetCycle('MeleeSet')); end
    elseif string.match(ws.Name, 'Shijin Spiral') then
        gcinclude.EquipMode('Shijin');
	elseif string.match(ws.Name, 'Dragon Kick') or string.match(ws.Name, 'Tornado Kick') then
        gcinclude.EquipMode('kickws');
	elseif string.match(ws.Name, 'Howling Fist') then
        gcinclude.EquipMode('Howling');
    end
end

return profile;