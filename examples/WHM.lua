local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
gcinclude.settings.SmartSwap = false; -- always swap to the casting weapons: TP isn't used on this job
gcinclude.settings.WeaponTPGuard = 0; -- no 1000+ TP weapon hold either (nukes, Dark, Divine swap too)
gcinclude.CureObi = true; -- Hachirin-no-Obi on Cure/Cura/Curaga in Light day/weather (Aurorastorm counts); false = never

local sets = {
    Idle = {
        Main = 'Bolelabunga',
        Sub = 'Genmei Shield',
        Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Ebers Bliaut +2',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Murky Ring',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Carrier\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Resting = {},
    Idle_Regen = {
        Neck = 'Sanctity Necklace',
        --Ear1 = 'Infused Earring',
        --Ring1 = 'Chirich Ring +1',
        Ring2 = 'Gurebu\'s Ring',
        Waist = 'Null Belt',
    },
    Idle_Refresh = {
        --Ammo = 'Homiliary',
        --Head = 'volte beret',
        --Neck = 'sibyl scarf',
        Body = 'Ebers Bliaut +2',
        --Hands = 'volte gloves',
        Ring1 = 'Stikini Ring +1',
        --Ring2 = 'gurebu\'s ring',
        Waist = 'Fucho-no-Obi',
        --Legs = 'volte brais',
        --Feet = 'volte boots',
    },
    Town = {
        Main = 'Yagrush',
        Sub = 'Chanter\'s Shield',
        --Ammo = 'Homiliary',
        Head = 'Theo. Cap +4',
        Neck = 'Sibyl Scarf',
        Body = 'Ebers Bliaut +2',
        Hands = 'Sworn Gauntlets',
        Ring1 = 'Murky Ring',
        Ring2 = 'Stikini Ring +1',
        Waist = 'Null Belt',
        Legs = 'Sworn Brais',
        Feet = 'Sworn Sabatons',
    },

    Dt = {
        Sub = 'Genmei Shield',
        Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Ebers Bliaut +2',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Murky Ring',
        Ring2 = 'Defending Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Carrier\'s Sash',
        Legs = 'Ebers Pant. +3',
        Feet = 'Nyame Sollerets',
    },
    Sleeping = { -- worn while asleep over the /def set and Incapacitated, past the TP hold: stage 2 Lorg Mor "Slowly devours your soul" (HP/MP drain wakes you); stages 3+ don't drain
        Main = 'Lorg Mor',
    },
    SIR = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Theo. Cap +4',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Theo. Bliaut +4',
        Hands = 'Theo. Mitts +4',
        Ring1 = 'Murky Ring',
        Ring2 = 'Gurebu\'s Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Carrier\'s Sash',
        Legs = 'Ebers Pant. +3',
        Feet = 'Theo. Duckbills +4',
    },
    Tp_Default = {
        Main = 'Maxentius',
        Sub = 'Diamond Aspis',
        Ammo = 'Staunch Tathlum +1',
        Head = 'Aya. Zucchetto +1',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Brutal Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Ayanmo Corazza +1',
        Hands = 'Sworn Gauntlets',
        Ring1 = 'Rajas Ring',
        Ring2 = 'Ayanmo Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+30', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Cornelia\'s Belt',
        Legs = 'Sworn Brais',
        Feet = 'Sworn Sabatons',
    },
    Tp_Acc = {
        Ear2 = 'Digni. Earring',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
    },
    Midcast = {},

    Precast = {
        Main = 'Gada',--5
        Sub = 'Chanter\'s Shield',--3
        Ammo = 'Impatiens',
        Head = 'Ebers Cap +2',--10
        Neck = 'Clr. Torque +2',--10
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Inyanga Jubbah +2',--14
        Hands = 'Sworn Gauntlets', --5
        Ring1 = 'Weather. Ring',--5
        Ring2 = 'Lebeche Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },--10
        Waist = 'Witful Belt',--3
        Legs = 'Sworn Brais',--8
        Feet = 'Sworn Sabatons',--5
    },
    ['Healing Magic_Precast'] = {
        Main = 'Gada',--5
        Sub = 'Chanter\'s Shield',--3
        Ammo = 'Impatiens',
        Head = 'Ebers Cap +2',--10
        Neck = 'Clr. Torque +2',--10
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Inyanga Jubbah +2',
        Hands = 'Sworn Gauntlets', --6
        Ring1 = 'Weather. Ring',--5
        Ring2 = 'Lebeche Ring',--2
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Witful Belt',
        Legs = 'Sworn Brais',
        Feet = 'Sworn Sabatons',
    },
    ['Enhancing Magic_Precast'] = {
        Waist = 'Siegel Sash',
    },
    Stoneskin_Precast = {
        Head = 'Umuthi Hat',
        Hands = 'Carapacho Cuffs',
        Waist = 'Siegel Sash',
    },

    -- Cure/Cura/Curaga midcast, lowest to highest (later wins per slot):
    --   Cure -> Self_Cure (on you) -> Cure_LowMP or Cure_LowMP_Storm (MP <= 50%) -> Cure_Dt (/dt on)
    --   -> engine: Hachirin-no-Obi (Light day/weather) -> SIR set (/sir on) last, over all of it.
    -- MP above 50%: Cure's own Main/Sub stay (Raetic Rod +1 / Thuellaic Ecu +1).
    ['Healing Magic'] = {--I cap is 50, II cap is 30
        Main = 'Raetic Rod +1',
        Sub = 'Thuellaic Ecu +1',
        Ammo = 'Impatiens',
        Head = 'Theo. Cap +4',
        Neck = 'Clr. Torque +2',
        Ear1 = 'Mendi. Earring',
        Ear2 = 'Ebers Earring +1',
        Body = 'Ebers Bliaut +2',
        Hands = 'Theo. Mitts +4',
        Ring1 = 'Weather. Ring',
        Ring2 = 'Lebeche Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Witful Belt',
        Legs = 'Ebers Pant. +3',--I 11
        Feet = 'Sworn Sabatons',
    },
    Self_Cure = {--cap 30
        Waist = 'Gishdubar Sash',
    },
    Cure_LowMP = { -- MP <= 50%, no Light weather
        Main = 'Daybreak',
        Sub = 'Thuellaic Ecu +1',
    },
    Cure_LowMP_Storm = { -- MP <= 50%, Light weather: Aurorastorm I/II or natural Light weather
        Main = 'Chatoyant Staff', -- or 'Iridal Staff': "Cure" potency +10%, Iridescence (+10% weather roll)
        Sub = 'Enki Strap',
    },
    Cure_Dt = { -- over the cure sets while /dt is on: DT pieces only
        Head = 'Nyame Helm',
        Ear1 = 'Alabaster Earring',
        Ring1 = 'Murky Ring',
    },
    ['Regen IV'] = {
        Main = 'Bolelabunga',
        Sub = 'Ammurapi Shield',
        Head = 'Inyanga Tiara +2',
        Body = 'Piety Bliaut +3',
        Hands = 'Ebers Mitts +2',
        Waist = 'Embla Sash',
        Legs = 'Theo. Pant. +4',
        Feet = 'Theo. Duckbills +4',
    },
    erase = {
        Main = 'Yagrush',
        Sub = 'Ammurapi Shield',
        Ammo = 'Impatiens',
        Neck = 'Clr. Torque +2',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Malignance Earring',
        Hands = 'Ebers Mitts +2',
        Ring1 = 'Kishar Ring',
        Ring2 = 'Weather. Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Witful Belt',
        Legs = 'Sworn Brais',
        Feet = 'Theo. Duckbills +4',
    },
    Cursna = {
        Main = 'Yagrush',
        Sub = 'Ammurapi Shield',
        Head = 'Vanya Hood',
        Neck = 'Debilis Medallion',
        Hands = 'Fanatic Gloves',
        Ring1 = 'Haoma\'s Ring',
        Ring2 = 'Menelaus\'s Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Bishop\'s Sash',
        Legs = 'Theo. Pant. +4',
        Feet = 'Vanya Clogs',
    },

    ['Enhancing Magic'] = {
        Main = 'Yagrush',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Befouled Crown',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Solemnity Cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Theo. Duckbills +4',
    },
    Self_Enhancing = {},
    Stoneskin = {
        Neck = 'Nodens Gorget',
        Waist = 'Siegel Sash',
    },
    Refresh = {
        Waist = 'Gishdubar Sash',
    },
    Self_Refresh = {},

    ['Enfeebling Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Befouled Crown',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Theo. Bliaut +4',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Acuity Belt +1',
        Legs = 'Chironic Hose',
        Feet = 'Theo. Duckbills +4',
    },

    Drain = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Ring1 = 'Kishar Ring',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Chironic Hose',
        Feet = 'Theo. Duckbills +4',
    },

    Aspir = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Ring1 = 'Kishar Ring',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Chironic Hose',
        Feet = 'Theo. Duckbills +4',
    },

    ['Elemental Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Ring1 = 'Shiva Ring +1',
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Eschan Stone',
        Feet = 'Volte Gaiters',
    },
    NukeACC = {
        Waist = 'Acuity Belt +1',
    },

    Preshot = {
    },
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },

    Ws_Default = {
        Ammo = 'Voluspa Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Rep. Plat. Medal',
        Ear1 = 'Brutal Earring',
        Ear2 = 'Ishvara Earring',
        Body = 'Ayanmo Corazza +1',
        Hands = 'Bunzi\'s Gloves',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Karieyh Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+30', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Cornelia\'s Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Cataclysm = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Pixie Hairpin +1',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Crematio Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shiva Ring +1',
        Ring2 = 'Karieyh Ring',
        Back = 'Alabaster Mantle',
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    TH = {
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
    },
    Movement = {
        Feet = 'Herald\'s Gaiters',
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
    gcinclude.settings.KeepWeaponsFor = T{'Dia', 'Dia II', 'Dia III', 'Diaga', 'Blink', 'Ice Spikes', 'Blaze Spikes', 'Shock Spikes'}; -- no Cure rule: cures pick Main/Sub by MP (HandleMidcast)
    -- Rules (/gcedit, RULES): when this, wear that, as data. A rule with at = goes on where gcinclude.RulesAt(...) is in the handlers below.
    gcinclude.Rules = {
        { on = 'Default', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Default', when = { toggle = { kite = true } }, wear = 'Movement', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { skill = 'Divine Magic' }, wear = 'Enfeebling Magic', exact = true },
        { on = 'Midcast', at = 'Midcast 2', when = { skill = 'Enhancing Magic', target = 'me' }, wear = 'Self_Enhancing', exact = true },
        { on = 'Midcast', at = 'Midcast 2', when = { skill = 'Healing Magic', target = 'me' }, wear = 'Self_Cure', exact = true },
        { on = 'Midcast', at = 'Midcast 2', when = { family = { 'Cure', 'Cura', 'Curaga' }, mpp = { le = 50 }, skill = 'Healing Magic', weather = 'Light' }, wear = 'Cure_LowMP_Storm', exact = true },
        { on = 'Midcast', at = 'Midcast 2', when = { family = { 'Cure', 'Cura', 'Curaga' }, mpp = { le = 50 }, skill = 'Healing Magic', weather = { isnt = { 'Light' } } }, wear = 'Cure_LowMP', exact = true },
        { on = 'Midcast', at = 'Midcast 2', when = { family = { 'Cure', 'Cura', 'Curaga' }, skill = 'Healing Magic', toggle = { dt = true } }, wear = 'Cure_Dt', exact = true },
        { on = 'Midcast', at = 'Midcast 2', when = { name = { 'Paralyna', 'Erase', 'Blindna', 'Silena', 'Poisona', 'Stona', 'Viruna' }, skill = 'Healing Magic' }, wear = 'erase', exact = true },
        { on = 'Midcast', at = 'Midcast 2', when = { mode = { nukeset = 'Macc' }, skill = 'Elemental Magic' }, wear = 'NukeACC', exact = true },
        { on = 'Midcast', at = 'Midcast 2', when = { skill = 'Dark Magic' }, wear = 'Enfeebling Magic', exact = true },
        { on = 'Midcast', when = { family = 'Refresh', target = 'me' }, wear = 'Self_Refresh', exact = true },
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
    local player = gData.GetPlayer();

    gcinclude.EquipIdle(); -- Idle, then Idle_<mode> (/idleset)

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
    ByName(ability.Name); -- a set named after the ability, e.g. ['Benediction']
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
    local family = Family(spell.Name); -- 'Cure IV' -> 'Cure'
    gFunc.EquipSet(sets.Midcast);
    gcinclude.RulesAt('Midcast 1');
    ByName(spell.Skill); -- e.g. ['Enhancing Magic'], ['Healing Magic'], ['Elemental Magic']
    gcinclude.RulesAt('Midcast 2');
    if not ByName(spell.Name) then ByName(family) end -- a set named after the spell or its family, e.g. ['Phalanx'], ['Cursna'], ['Drain']
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
    ByName(ws.Name); -- e.g. ['Cataclysm'], then ['Cataclysm_<mset>']
end

return profile;
