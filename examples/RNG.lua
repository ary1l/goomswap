local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Head = 'Malignance Chapeau',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Hearty Earring',
        Ear2 = 'Telos Earring',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'defending ring',
		Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Carrier\'s Sash',
        Legs = 'Ikenga\'s Trousers',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+7', [2] = 'Attack+18', [3] = 'Spell interruption rate down -8%', [4] = 'Quadruple Attack +2' } },
    },
    Resting = {},
    Idle_Regen = {
        Neck = 'Sanctity Necklace',
        Ear1 = 'Infused Earring',
        Ring1 = 'Chirich Ring +1',
    },
    Idle_Refresh = {
        Head = 'Rawhide Mask',
        Ring2 = 'Stikini Ring +1',
        Waist = 'Fucho-no-Obi',
    },
    Town = {
        Main = 'Naegling',
        Sub = 'Leafkin Shield',
        Range = 'Fomalhaut',
        Ammo = 'Chrono Bullet',
        Head = 'Scout\'s Beret',
        Neck = 'Iskur Gorget',
        Ear1 = 'Mache Earring +1',
        Ear2 = 'Telos Earring',
        Body = 'Adhemar Jacket +1',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'shneddick ring',
        Ring2 = 'Defending Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Sailfi Belt +1',
		Legs = 'Samnuha Tights',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+7', [2] = 'Attack+18', [3] = 'Spell interruption rate down -8%', [4] = 'Quadruple Attack +2' } },
    },

    Dt = {
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Etiolation Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Gelatinous Ring +1',
        Ring2 = 'Defending Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Flume Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Weapon_Armageddon = {
        Range = 'Armageddon',
    },
    Weapon_Annihilator = {
        Main = 'Naegling',
        Sub = 'Nusku Shield',
        Range = 'Annihilator',
    },
    Weapon_Sparrowhawk = {
        Main = 'Naegling',
        Sub = 'Kraken Club',
        Range = 'Sparrowhawk +2',
    },
    Weapon_Sparrowhawk_1h = {
        Main = 'Naegling',
        Sub = 'Nusku Shield',
        Range = 'Sparrowhawk +2',
    },
    Weapon_Gastraphetes = {
        Range = 'Gastraphetes',
    },
    Weapon_Fomalhaut = {
        Range = 'Fomalhaut',
    },
    Tp_Default = {
        Head = 'Adhemar Bonnet +1',
        Neck = 'Anu Torque',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Telos Earring',
        Body = 'Herculean Vest',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Epona\'s Ring',
		Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Accuracy+20', [3] = 'DEX+30', [4] = 'Attack+20', [5] = '"Dual Wield"+10' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Samnuha Tights',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+7', [2] = 'Attack+18', [3] = 'Spell interruption rate down -8%', [4] = 'Quadruple Attack +2' } },
    },
    Tp_Hybrid = {
        Head = 'Malignance Chapeau',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
    },
    Tp_Acc = {
        Ear1 = 'Mache Earring +1',
        Ear2 = 'Telos Earring',
        Hands = 'Tatena. Gote +1',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Cacoethic Ring +1',
        Legs = 'Tatena. Haidate +1',
        Feet = 'Tatena. Sune. +1',
    },


    Precast = {
        Neck = 'Baetyl Pendant',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Taeon Tabard',
        Ring1 = 'Prolix Ring',
        Legs = 'Enif Cosciales',
    },


    Cure = {
        Neck = 'Incanter\'s Torque',
        Ear2 = 'Mendi. Earring',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Solemnity Cape',
        Legs = 'Carmine Cuisses +1',
    },

    Enhancing = {
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Ring2 = 'Metamor. Ring +1',
    },

    Enfeebling = {
        Neck = 'Erra Pendant',
        Ring2 = 'Metamor. Ring +1',
    },
    Macc = {},

    Drain = {
        Neck = 'Erra Pendant',
        Ring2 = 'Metamor. Ring +1',
    },

    Nuke = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Preshot = {--base preshot, no flurry, 70cap, 10 from gifts
        Hands = 'Carmine Fin. Ga. +1',--8
        Ring1 = 'Crepuscular Ring',--3
        Waist = 'Impulse Belt',--3
        Legs = 'Ikenga\'s Trousers',--8
        Feet = 'Meg. Jam. +2',--10
    },
    Preshot_FlurryI = {--with flurry I on, gives 15, 10 from gifts
        Hands = 'Carmine Fin. Ga. +1',--8
        Ring1 = 'Crepuscular Ring',--3
        Waist = 'Impulse Belt',--3
        Legs = 'Ikenga\'s Trousers',--8
        Feet = 'Meg. Jam. +2',--10
    },
    Preshot_FlurryII = {--with flurry II on, gives 30, 10 from gifts
        Hands = 'Carmine Fin. Ga. +1',--8
        Waist = 'Impulse Belt',--3
        Legs = 'Ikenga\'s Trousers',--8
        Feet = 'Meg. Jam. +2',--10
    },
    Midshot = {
        Head = 'Malignance Chapeau',
        Neck = 'Iskur Gorget',
        Ear1 = 'Enervating Earring',
        Ear2 = 'Telos Earring',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ilabrat Ring',
		Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Ikenga\'s Trousers',
        Feet = 'Nyame Sollerets',
    },
    Barrage = {
        Hands = 'Orion Bracers',
    },
    Midshot_Acc = {--will be over written by barrage set still
        Head = 'Malignance Chapeau',
        Neck = 'Iskur Gorget',
        Ear1 = 'Crep. Earring',
        Ear2 = 'Telos Earring',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Ring1 = 'Crepuscular Ring',
        Ring2 = 'Cacoethic Ring +1',
        Waist = 'Eschan Stone',
        Legs = 'Ikenga\'s Trousers',
        Feet = 'Nyame Sollerets',
    },
    DoubleShot = {
    },

    Ws_Default = {
        Head = 'Nyame Helm',
        Neck = 'Fotia Gorget',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'regal Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Accuracy+14', [3] = 'Attack+26', [4] = 'DEX+8' } },
    },
    Ws_Hybrid = {
    },
    Ws_Acc = {
    },
    WsObi = {--puts elemental obi on for trueflight/wildfire under light/fire situations
        Waist = 'Hachirin-no-Obi',
    },

    Savage_Default = {
        Head = 'Nyame Helm',
        Ear1 = 'Sherida Earring',
        Body = 'Nyame Mail',
        Hands = 'nyame gauntlets',
        Ring1 = 'Regal Ring',
        Ring2 = 'Ephramad\'s Ring',
		Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
		Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Accuracy+14', [3] = 'Attack+26', [4] = 'DEX+8' } },
    },
    Savage_Hybrid = {
    },
    Savage_Acc = {
    },
    Aedge_Default = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
		Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'orpheus\'s sash',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Mag. Acc.+17', [3] = 'MND+8', [4] = '"Mag. Atk. Bns."+29' } },
    },
    Aedge_Hybrid = {
    },
    Aedge_Acc = {
    },
    Wildfire_Default = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'orpheus\'s sash',
        Legs = 'Nyame Flanchard',--relic+3
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Mag. Acc.+17', [3] = 'MND+8', [4] = '"Mag. Atk. Bns."+29' } },
    },
    Wildfire_Hybrid = {
    },
    Wildfire_Acc = {
    },
    HS_Default = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'orpheus\'s sash',
        Legs = 'Nyame Flanchard',--relic+3
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Mag. Acc.+17', [3] = 'MND+8', [4] = '"Mag. Atk. Bns."+29' } },
    },
    HS_Hybrid = {
    },
    HS_Acc = {
    },
    TrueFlight_Default = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'orpheus\'s sash',
        Legs = 'Nyame Flanchard',--relic+3
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Mag. Acc.+17', [3] = 'MND+8', [4] = '"Mag. Atk. Bns."+29' } },
    },
    TrueFlight_Hybrid = {
    },
    TrueFlight_Acc = {
    },

    Scavenge = {
        Feet = 'Orion Socks',
    },
    Sharpshot = {
        Legs = 'Orion Braccae',
    },
    TH = {
        Head = { Name = 'Herculean Helm', Augment = { [1] = 'Accuracy+30', [2] = 'Attack+18', [3] = '"Fast Cast"+3', [4] = '"Treasure Hunter"+2' } },
		Waist = 'Chaac Belt',
	},
    Movement = {
        Ring1 = 'shneddick ring',
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

profile.OnLoad = function()
	gSettings.AllowAddSet = true;
    gcinclude.SafeAmmo = { Bullet = 'Chrono Bullet', Arrow = 'Chrono Arrow' }; -- keyed by the blocked ammo's last word; add Bolt if you use one
    gcinclude.RangeModes = {'None', 'Annihilator', 'Armageddon', 'Fomalhaut', 'Gastraphetes', 'Sparrowhawk +2'};
    gcinclude.WeaponModes = {'None', 'Annihilator', 'Sparrowhawk', 'Gastraphetes', 'Fomalhaut', 'Armageddon'};
    gcinclude.MainModes = {'None', 'Naegling'};
    gcinclude.SubModes = {'None', 'Kraken Club', 'Nusku Shield'};
    gcinclude.DefaultWeapons = 'Annihilator';
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

    if string.match(ability.Name, 'Scavenge') then gFunc.EquipSet(sets.Scavenge);
    elseif string.match(ability.Name, 'Sharpshot') then gFunc.EquipSet(sets.Sharpshot) end

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
    local spell = gData.GetAction();

    if (spell.Skill == 'Enhancing Magic') then
        gFunc.EquipSet(sets.Enhancing);
    elseif (spell.Skill == 'Healing Magic') then
        gFunc.EquipSet(sets.Cure);
    elseif (spell.Skill == 'Elemental Magic') then
        gFunc.EquipSet(sets.Nuke);
    elseif (spell.Skill == 'Enfeebling Magic') then
        gFunc.EquipSet(sets.Enfeebling);
    elseif (spell.Skill == 'Dark Magic') then
        gFunc.EquipSet(sets.Macc);
        if (string.contains(spell.Name, 'Aspir') or string.contains(spell.Name, 'Drain')) then
            gFunc.EquipSet(sets.Drain);
        end
    end
	gcinclude.CheckTH();
end

profile.HandlePreshot = function()
    if (gcinclude.CheckBlockedAmmo() == true) then return end
    local flurryI = gcinclude.BuffCount(265);
    local flurryII = gcinclude.BuffCount(581);

    gFunc.EquipSet(sets.Preshot);

    if flurryII > 0 then
        gFunc.EquipSet(sets.Preshot_FlurryII);
    elseif flurryI > 0 then
        gFunc.EquipSet(sets.Preshot_FlurryI);
    end
end

profile.HandleMidshot = function()
    local double = gcinclude.BuffCount('Double Shot');
    local barrage = gcinclude.BuffCount('Barrage');
    gFunc.EquipSet(sets.Midshot);

    if double > 0 then
        gFunc.EquipSet(sets.DoubleShot);
    end

    if (gcdisplay.GetCycle('MeleeSet') == 'Acc') then
        gFunc.EquipSet(sets.Midshot_Acc);
    end

    if barrage > 0 then--ensure acc as base if barrage up
        gFunc.EquipSet(sets.Midshot_Acc);
        gFunc.EquipSet(sets.Barrage);
    end
	gcinclude.CheckTH();
end

profile.HandleWeaponskill = function()
    if (gcinclude.CheckWsBailout() == false) then gFunc.CancelAction(); return end
    local ws = gData.GetAction();
    if (gcinclude.CheckBlockedAmmoWS(ws.Name) == true) then return end

    gcinclude.EquipMode('Ws');

    if string.match(ws.Name, 'Savage Blade') then
        gcinclude.EquipMode('Savage');
    elseif string.match(ws.Name, 'Aeolian Edge') then
        gcinclude.EquipMode('Aedge');
    elseif string.match(ws.Name, 'Trueflight') then
        gcinclude.EquipMode('TrueFlight');
    elseif string.match(ws.Name, 'Hot Shot') then
        gcinclude.EquipMode('HS');
    elseif string.match(ws.Name, 'Wildfire') then
        gcinclude.EquipMode('Wildfire');
    end
end

return profile;
