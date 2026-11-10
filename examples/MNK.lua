local profile = {};
if (gFunc == nil) then error('GoomSwap: GearSwap loaded this job file directly. Windower: move it to data/goomswap/<Name>/<JOB>.lua and delete it from data/<Name>/ (see README Install)', 0) end
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
-- gcinclude.Food = {'Grape Daifuku +1'}; -- this job's food: /packer keeps a stack of each (replaces the Food setting / char.lua's)
-- gcinclude.Packer = { ['Echo Drops'] = 'stack', ['Holy Water'] = 'stack' }; -- kept in inventory on job change (/packer, Bellhop plugin)

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
        Ring2 = 'Chirich Ring +1',
    },
    Idle_Refresh = {},
    Idle_Regain = { -- /idleset regain: over Idle while idle
    },
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
    Tp_SubtleBlow = { -- /mset subtleblow: Subtle Blow pieces over Tp_Default
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
    Ws_Acc = {
    },

    ['Victory Smite'] = {
        Ear2 = 'Sherida Earring',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Legs = 'Mpaca\'s Hose',
    },
    ['Victory Smite_Impetus'] = {
        Ammo = 'Coiste Bodhar',
        Ear1 = 'Schere Earring',
        Ear2 = 'Sherida Earring',
        Body = 'Bhikku Cyclas +3',
        Back = { Name = 'Segomo\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
    },
    ['Victory Smite_Acc'] = {},

    ['Shijin Spiral'] = {
    },
    ['Shijin Spiral_Acc'] = {},

	['Howling Fist'] = {
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
    ['Howling Fist_Acc'] = {},


	['Dragon Kick'] = {
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


	['Tornado Kick'] = {
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
    ['Dragon Kick_Acc'] = {},
    ['Tornado Kick_Acc'] = {},
    ['Dragon Kick_SubtleBlow'] = { -- /mset subtleblow: Subtle Blow pieces over kickws_Default (Dragon Kick, Tornado Kick)
    },
    ['Tornado Kick_SubtleBlow'] = { -- /mset subtleblow: Subtle Blow pieces over kickws_Default (Dragon Kick, Tornado Kick)
    },


    Tp_Impetus = {--over rides your TP set if impetus is up
		Ear1 = 'dedition earring',
        Body = 'Bhikku Cyclas +3',
    },
    -- Hoxne: /hoxne Locked + Enchantment up (Double Attack +100%). Per slot, later wins; leave a slot out to keep the one under.
    -- Idle/TP: job sets (Tp, buff sets, Dt) -> Hoxne_Tp|Idle|Dt -> its _SubtleBlow/_Acc -> its _<buff> combos -> engine layers.
    -- WS: job WS sets -> Hoxne_Ws -> Hoxne_<ws> -> Hoxne_Ws_<buff> -> Hoxne_<ws>_<buff> -> Buffs_Ws, Moonshade, obi.
    -- Combos: <set>_<buff>, <set>_<buff>&<buff> (all up); fewest buffs first, then A-Z. Full order: README Hoxne layering.
    Hoxne_Tp = {},
    Hoxne_Idle = {},
    Hoxne_Dt = {}, -- instead of Hoxne_Tp/Hoxne_Idle while /dt is on
    Hoxne_Ws = {}, -- every WS
    Hoxne_Tp_Impetus = {},
    Hoxne_Tp_Footwork = {},
    ['Hoxne_Victory Smite'] = {}, -- that WS, over Hoxne_Ws
    ['Hoxne_Victory Smite_Impetus'] = {}, -- Victory Smite with Impetus up (Victory_Imp)

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
    -- Templates: fill the ones you use; an empty set changes nothing.
    Proc = {}, -- /proc: low-damage gear for proc windows (Abyssea, Vagary...), over the engaged sets
    Ws_Proc = {}, -- /proc on weapon skills (empty: Proc)
    Ws_HighBuff = {}, -- /wsset high: over Ws_Default (PDL)
    ['Victory Smite_HighBuff'] = {}, -- /wsset high: this WS
    Buffs_Ws = { -- while the buff is up: weapon skills
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Midcast = { -- while the buff is up: spells (e.g. ['Saboteur'])
    },
    -- Weapon_Godhands_Acc = { Main = 'Item Name' }, -- /mset acc: a whole weapon set in place of Weapon_Godhands
    -- Weapon_Godhands_1h = { Main = 'Item Name', Sub = 'Shield Name' }, -- when you can't dual wield (/dw off, sub not NIN/DNC)
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

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
	gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None', 'Godhands'};
    gcinclude.DefaultWeapons = 'Godhands';
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
	local player = gData.GetPlayer();

    if (player.Status == 'Engaged') then
        gcinclude.EquipMode('Tp');
        if (gcinclude.BuffCount('Impetus') > 0) then gFunc.EquipSet(sets.Tp_Impetus) end
        if (gcinclude.BuffCount('Footwork') > 0) then gFunc.EquipSet(sets.Tp_Footwork) end
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
    ByName(ability.Name); -- a set named after the ability, e.g. ['Focus'], ['Hundred Fists']
    if (ability.Name == 'Boost') then gFunc.EquipSet(sets.Buffs.Boost) end -- sash on from the start
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
    if (ws.Name == 'Victory Smite') and (gcinclude.BuffCount('Impetus') > 0) then ByName('Victory Smite_Impetus') end
end

return profile;