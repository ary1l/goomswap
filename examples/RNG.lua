local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

local sets = {
    Idle = {
        Head = 'Malignance Chapeau',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Telos Earring',
        Ear2 = 'Hearty Earring',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Defending Ring',
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
        Ear1 = 'Telos Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Adhemar Jacket +1',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Shneddick Ring',
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

    Weapon_Naegling = { -- /wm: the melee pair, dual wield; _1h (shield) when you can't. The bow/gun is /rw (RangeModes)
        Main = 'Naegling',
        Sub = 'Kraken Club',
    },
    Weapon_Naegling_1h = {
        Main = 'Naegling',
        Sub = 'Nusku Shield',
    },

    Tp_Default = {
        Head = 'Adhemar Bonnet +1',
        Neck = 'Anu Torque',
        Ear1 = 'Telos Earring',
        Ear2 = 'Sherida Earring',
        Body = 'Herculean Vest',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Accuracy+20', [3] = 'DEX+30', [4] = 'Attack+20', [5] = '"Dual Wield"+10' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Samnuha Tights',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+7', [2] = 'Attack+18', [3] = 'Spell interruption rate down -8%', [4] = 'Quadruple Attack +2' } },
    },
    Tp_Acc = {
        Ear2 = 'Mache Earring +1',
        Hands = 'Tatena. Gote +1',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Cacoethic Ring +1',
        Legs = 'Tatena. Haidate +1',
        Feet = 'Tatena. Sune. +1',
    },
    Midcast = {},

    Precast = {
        Neck = 'Baetyl Pendant',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Taeon Tabard',
        Ring1 = 'Prolix Ring',
        Legs = 'Enif Cosciales',
    },

    ['Healing Magic'] = {
        Neck = 'Incanter\'s Torque',
        Ear2 = 'Mendi. Earring',
        Ring1 = 'Metamor. Ring +1',
        Back = 'Solemnity Cape',
        Legs = 'Carmine Cuisses +1',
    },

    ['Enhancing Magic'] = {
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Ring1 = 'Metamor. Ring +1',
    },

    ['Enfeebling Magic'] = {
        Neck = 'Erra Pendant',
        Ring1 = 'Metamor. Ring +1',
    },

    Drain = {
        Neck = 'Erra Pendant',
        Ring1 = 'Metamor. Ring +1',
    },

    Aspir = {
        Neck = 'Erra Pendant',
        Ring1 = 'Metamor. Ring +1',
    },

    ['Elemental Magic'] = {
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
        Ear1 = 'Telos Earring',
        Ear2 = 'Enervating Earring',
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
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
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
        Ring1 = 'Regal Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Accuracy+14', [3] = 'Attack+26', [4] = 'DEX+8' } },
    },

    ['Savage Blade'] = {
        Head = 'Nyame Helm',
        Ear1 = 'Sherida Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Regal Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Accuracy+14', [3] = 'Attack+26', [4] = 'DEX+8' } },
    },
    ['Aeolian Edge'] = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear2 = 'Friomisi Earring',
        Ear1 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Mag. Acc.+17', [3] = 'MND+8', [4] = '"Mag. Atk. Bns."+29' } },
    },
    Wildfire = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear2 = 'Friomisi Earring',
        Ear1 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',--relic+3
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Mag. Acc.+17', [3] = 'MND+8', [4] = '"Mag. Atk. Bns."+29' } },
    },
    ['Hot Shot'] = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear2 = 'Friomisi Earring',
        Ear1 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',--relic+3
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Mag. Acc.+17', [3] = 'MND+8', [4] = '"Mag. Atk. Bns."+29' } },
    },
    Trueflight = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear2 = 'Friomisi Earring',
        Ear1 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Belenus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',--relic+3
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Mag. Acc.+17', [3] = 'MND+8', [4] = '"Mag. Atk. Bns."+29' } },
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
        Ring1 = 'Shneddick Ring',
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
    gcinclude.SafeAmmo = { Bullet = 'Chrono Bullet', Arrow = 'Chrono Arrow' }; -- keyed by the blocked ammo's last word; add Bolt if you use one
    gcinclude.WeaponModes = {'None', 'Naegling'}; -- /wm: melee pair
    gcinclude.RangeModes = {'None', 'Annihilator', 'Fomalhaut', 'Armageddon', 'Gastraphetes', 'Sparrowhawk +2'}; -- /rw: bow or gun
    gcinclude.RangeAmmo = { ['Sparrowhawk +2'] = 'Chrono Arrow' }; -- a bow's arrows replace the sets' bullets; add Gastraphetes = '<your bolt>'
    gcinclude.DefaultWeapons = { Weapons = 'Naegling', Range = 'Annihilator' }; -- /wm default puts both back
    gcinclude.settings.RefreshGearMPP = 0; -- no auto Idle_Refresh on this job; /autogear refresh 60 (or set it here) to turn it on
    -- Rules (/gcedit, RULES): when this, wear that, as data. A rule with at = goes on where gcinclude.RulesAt(...) is in the handlers below.
    gcinclude.Rules = {
        { on = 'Default', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Default', when = { toggle = { kite = true } }, wear = 'Movement', exact = true },
        { on = 'Preshot', at = 'Preshot 1', first = {
            { when = { buff = 581 }, wear = 'Preshot_FlurryII', exact = true },
            { when = { buff = 265 }, wear = 'Preshot_FlurryI', exact = true },
        } },
        { on = 'Midshot', when = { buff = 'Barrage' }, wear = 'Midshot_Acc', exact = true },
        { on = 'Midshot', when = { buff = 'Barrage' }, wear = 'Barrage', exact = true },
        { on = 'Midshot', when = { buff = 'Double Shot' }, wear = 'DoubleShot', exact = true },
        { on = 'Midshot', when = { buff = 'Double Shot', mode = { mset = 'Acc' } }, wear = 'Midshot_Acc', exact = true },
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
    ByName(ability.Name); -- a set named after the ability, e.g. ['Scavenge']
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
    if (gcinclude.CheckBlockedAmmo() == true) then return end

    gFunc.EquipSet(sets.Preshot);

    gcinclude.RulesAt('Preshot 1');
end

profile.HandleMidshot = function()
    -- Midshot, then the ones made of: Midshot_<wm> (the /wm mode's own), Midshot_Acc on /mset acc,
    -- Midshot_<wm>_Acc
    ByName('Midshot');


    gcinclude.CheckTH();
end

profile.HandleWeaponskill = function()
    if (gcinclude.CheckWsBailout() == false) then gFunc.CancelAction(); return end
    local ws = gData.GetAction();
    if (gcinclude.CheckBlockedAmmoWS(ws.Name) == true) then return end
    gcinclude.EquipMode('Ws');
    ByName(ws.Name); -- e.g. ['Savage Blade'], then ['Savage Blade_<mset>']
end

return profile;
