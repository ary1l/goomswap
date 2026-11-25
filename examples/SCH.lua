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
        Head = 'Arbatel Bonnet +3',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Shamash Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Fortified Ring',
        Ring2 = 'Shadow Ring',
        Back = 'Null Shawl',
        Waist = 'Carrier\'s Sash',
        Legs = 'Arbatel Pants +3',
        Feet = 'Nyame Sollerets',
    },
    Idle_Staff = {
        Main = 'Musa',
        Sub = 'Enki Strap',
    },
    Resting = {},
    Idle_Regen = {
        --Ear1 = 'Infused Earring',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Chirich Ring +1',
        Waist = 'Null Belt',
    },
    Idle_Refresh = {
        Ammo = 'Homiliary',
        Head = 'Befouled Crown',
        Hands = 'Merlinic Dastanas',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Volte Brais',
        Feet = 'Merlinic Crackows',
    },
    Town = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Staunch Tathlum +1',
        Head = 'Arbatel Bonnet +3',
        Neck = 'Argute Stole +2',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adamantite Armor',
        Hands = 'Acad. Bracers +4',
        Ring1 = 'Murky Ring',
        Ring2 = 'Shadow Ring',
        Back = 'Shadow Mantle',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Acad. Loafers +4',
    },

    Dt = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adamantite Armor',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Fortified Ring',
        Ring2 = 'Shadow Ring',
        Back = 'Null Shawl',
        Waist = 'Plat. Mog. Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    SIR = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Arbatel Bonnet +3',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Shamash Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Fortified Ring',
        Ring2 = 'Shadow Ring',
        Back = 'Null Shawl',
        Waist = 'Carrier\'s Sash',
        Legs = 'Arbatel Pants +3',
        Feet = 'Nyame Sollerets',
    },

    Tp_Default = {
        Main = 'Maxentius',
        Sub = 'Genmei Shield',
        Ammo = 'Jukukik Feather',
        Head = 'Agwu\'s Cap',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Telos Earring',
        Ear2 = 'Cessance Earring',
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Eschan Stone',
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },
    Midcast = {},

    Precast = {
        Ammo = 'Sapience Orb', --2
        Head = 'Peda. M.Board +3',
        Neck = 'Voltsurge Torque', --4
        Ear1 = 'Loquac. Earring', --2
        Ear2 = 'Malignance Earring', --4
        Body = 'Pinga Tunic +1', --15
        Hands = 'Acad. Bracers +4',
        Ring1 = 'Prolix Ring',
        Ring2 = 'Kishar Ring',
        Back = 'Fi Follet Cape +1',
        Waist = 'Embla Sash',
        Legs = 'Pinga Pants +1',--11
        Feet = 'Peda. Loafers +2',
    },
    ['Healing Magic_Precast'] = {
        Ear2 = 'Mendi. Earring',
        Feet = 'Acad. Loafers +4',
    },
    ['Enhancing Magic_Precast'] = {
        Waist = 'Siegel Sash',
    },
    Stoneskin_Precast = {
        Head = 'Umuthi Hat',
        Hands = 'Carapacho Cuffs',
        Waist = 'Siegel Sash',
    },

    ['Healing Magic'] = {--I cap is 50, II cap is 30
        Main = 'Bunzi\'s Rod',--I 30
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Regal Earring',
        Ear2 = 'Mendi. Earring',--I 5
        Body = 'Arbatel Gown +3',
        Hands = 'Peda. Bracers +2',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Fi Follet Cape +1',
        Waist = 'Rumination Sash',
        Legs = 'Acad. Pants +3', --I 15
        Feet = 'Acad. Loafers +4',
    },
    Self_Cure = {--cap 30
        Waist = 'Gishdubar Sash',
    },
    -- Cure/Cura/Curaga midcast, lowest to highest (later wins per slot):
    --   Cure -> Self_Cure (on you) -> Cure_LowMP or Cure_LowMP_Storm (MP <= 50%) -> Cure_Dt (/dt on)
    --   -> engine: Hachirin-no-Obi (Light day/weather) -> SIR set (/sir on) last. Empty sets change nothing.
    -- Main/Sub in these? Copy WHM.lua's KeepWeaponsFor line to OnLoad.
    Cure_LowMP = { -- MP <= 50%, no Light weather
    },
    Cure_LowMP_Storm = { -- MP <= 50%, Light weather: your own Aurorastorm, another SCH's, or natural Light
    },
    Cure_Dt = { -- /dt on: DT pieces to trade in while curing
    },
    Regen = {
        Main = 'Musa',
        Sub = 'Enki Strap',
        Head = 'Telchine Cap',
        Body = 'Telchine Chas.',
        Hands = 'Arbatel Bracers +3',
        Back = 'Lugh\'s Cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Telchine Pigaches',
    },
    Cursna = {
        Ring1 = 'Purity Ring',
        Waist = 'Gishdubar Sash',
    },

    ['Enhancing Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Telchine Cap',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Body = 'Peda. Gown +2',
        Hands = 'Arbatel Bracers +3',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Fi Follet Cape +1',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Telchine Pigaches',
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
        Neck = 'Argute Stole +2',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Acad. Gown +3',
        Hands = 'Peda. Bracers +2',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Obstin. Sash',
        Legs = 'Acad. Pants +3',
        Feet = 'Acad. Loafers +4',
    },

    Drain = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Pixie Hairpin +1',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Acad. Gown +3',
        Hands = 'Acad. Bracers +4',
        Ring1 = 'Evanescence Ring',
        Ring2 = 'Mujin Band',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Acad. Pants +3',
        Feet = 'Agwu\'s Pigaches',
    },

    Aspir = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Pixie Hairpin +1',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Acad. Gown +3',
        Hands = 'Acad. Bracers +4',
        Ring1 = 'Evanescence Ring',
        Ring2 = 'Mujin Band',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Acad. Pants +3',
        Feet = 'Agwu\'s Pigaches',
    },

    ['Elemental Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Arbatel Bonnet +3',
        Neck = 'Sibyl Scarf',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Arbatel Gown +3',
        Hands = 'Arbatel Bracers +3',
        Ring1 = 'Freke Ring',
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Lugh\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Evasion+15', [3] = 'Mag. Acc.+20', [4] = 'INT+30', [5] = 'Magic Damage+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Arbatel Pants +3',
        Feet = 'Arbatel Loafers +3',
    },
    NukeACC = {
        Neck = 'Argute Stole +2',
        Waist = 'Acuity Belt +1',
    },
    Burst = {
        Main = 'Bunzi\'s Rod', -- 10 and 0
        Sub = 'Ammurapi Shield',
        Ammo = 'Ghastly Tathlum +1',
        Head = 'Agwu\'s Cap', -- 0 and 4
        Neck = 'Argute Stole +2', -- 7 and 0
        Hands = 'Agwu\'s Gages', -- 0 and 6
        Waist = 'Acuity Belt +1',
        Legs = 'Agwu\'s Slops', -- 9 and 0
        Feet = 'Agwu\'s Pigaches', -- 6 and 0
    },
    OccultAcumen = { -- /nukeset oa: Occult Acumen / Store TP pieces, over Nuke and Burst (TP from nukes)
    },
    Helix = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Ghastly Tathlum +1',
        Head = 'Agwu\'s Cap',
        Neck = 'Argute Stole +2',
        Ear1 = 'Regal Earring',
        Ear2 = 'Arbatel Earring +1',
        Body = 'Agwu\'s Robe',
        Hands = 'Amalric Gages +1',
        Ring1 = 'Freke Ring',
        Ring2 = 'Mallquis Ring',
        Back = { Name = 'Lugh\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Evasion+15', [3] = 'Mag. Acc.+20', [4] = 'INT+30', [5] = 'Magic Damage+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Agwu\'s Slops',
        Feet = 'Amalric Nails +1',
    },
    HelixBurst = {
        Ring2 = 'Mujin Band',
        Feet = 'Agwu\'s Pigaches', -- 6 and 0
    },
    Storm = {
        Feet = 'Peda. Loafers +2',
    },
    Kaustra = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Pixie Hairpin +1',
        Neck = 'Argute Stole +2',
        Ear1 = 'Regal Earring',
        Ear2 = 'Arbatel Earring +1',
        --Body = 'Seidr Cotehardie',
        Hands = 'Amalric Gages +1',
        Ring1 = 'Freke Ring',
        Ring2 = 'Archon Ring',
        Back = { Name = 'Lugh\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Evasion+15', [3] = 'Mag. Acc.+20', [4] = 'INT+30', [5] = 'Magic Damage+20' } },
        Waist = 'Acuity Belt +1',
        Legs = 'Amalric Slops +1',
        Feet = 'Amalric Nails +1',
    },
    --Mp_Body = {Body = 'Seidr Cotehardie',},

    Mp_Body = {
    },
    Preshot = {
    },
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },

    Ws_Default = {
        Head = 'Nyame Helm',
        Neck = 'Sanctity Necklace',
        Ear2 = 'Malignance Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring2 = 'Karieyh Ring +1',
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Myrkr = {
        Ammo = 'Ghastly Tathlum +1',
        Head = 'Pixie Hairpin +1',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Etiolation Earring',
        Ear2 = 'Mendi. Earring',
        Body = 'Acad. Gown +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Sangoma Ring',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Shinjutsu-no-Obi +1',
        Legs = 'Amalric Slops +1',
        Feet = 'Arbatel Loafers +3',
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
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Lugh\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Evasion+15', [3] = 'Mag. Acc.+20', [4] = 'INT+30', [5] = 'Magic Damage+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Sublimation = {
        Head = 'Acad. Mortar. +2',
        Body = 'Peda. Gown +2',
        Waist = 'Embla Sash',
    },
    Power = {--rapture/ebullience
        Head = 'Arbatel Bonnet +3',
    },
    Klimaform = {--klimaform dmg boost
        Feet = 'Arbatel Loafers +3',
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

-- Kept in your bags for this job by /lac gear (the Packer plugin), with every set's gear; /gcedit Settings edits it.
profile.Packer = {
    {Name = 'Tropical Crepe', Quantity = 'all'},
    {Name = 'Rolan. Daifuku', Quantity = 'all'},
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.NukeModes = {'Power', 'Macc', 'OccultAcumen'}; -- /nukeset oa (or oc, occult, acumen): OccultAcumen set on nukes
    -- Rules (/gcedit, RULES): when this, wear that, as data.
    gcinclude.Rules = {
        { on = 'Default', when = { mode = { weapon = 'Staff' } }, wear = 'Idle_Staff', exact = true },
        { on = 'Default', when = { buff = 'Sublimation: Activated' }, wear = 'Sublimation', exact = true },
        { on = 'Default', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Default', when = { toggle = { kite = true } }, wear = 'Movement', exact = true },
        { on = 'Precast', when = { mode = { weapon = 'Staff' } }, wear = 'Idle_Staff', exact = true },
        { on = 'Midcast', when = { family = 'Refresh', target = 'me' }, wear = 'Self_Refresh', exact = true },
        { on = 'Midcast', when = { buff = { 'Ebullience', 'Rapture' } }, wear = 'Power', exact = true },
        { on = 'Midcast', when = { mode = { weapon = 'Staff' } }, wear = 'Idle_Staff', exact = true },
    };
    gcinclude.Initialize();

    AshitaCore:GetChatManager():QueueCommand(1, '/macro book 8');
    AshitaCore:GetChatManager():QueueCommand(1, '/macro set 2');
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
    ByName(ability.Name); -- a set named after the ability, e.g. ['Tabula Rasa']
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
    local target = gData.GetActionTarget() or {}; -- {} when LAC has no entity for the target: no Self_ sets
    local me = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0);
    local family = Family(spell.Name); -- 'Cure IV' -> 'Cure'
    gFunc.EquipSet(sets.Midcast);
    ByName(spell.Skill); -- e.g. ['Enhancing Magic'], ['Healing Magic'], ['Elemental Magic']
    if (spell.Skill == 'Enhancing Magic') then
        if (target.Name == me) then gFunc.EquipSet(sets.Self_Enhancing) end
        if string.contains(spell.Name, 'storm') then gFunc.EquipSet(sets.Storm) end
    elseif (spell.Skill == 'Healing Magic') then
        if (target.Name == me) then gFunc.EquipSet(sets.Self_Cure) end
        if T{'Cure', 'Cura', 'Curaga'}:contains(family) then
            if (gData.GetPlayer().MPP <= 50) then
                -- Light weather: Aurorastorm counts (LAC GetEnvironment reads storm buffs as weather), so does natural Light
                local env = gData.GetEnvironment();
                if (env ~= nil) and (env.WeatherElement == 'Light') then
                    gFunc.EquipSet(sets.Cure_LowMP_Storm);
                else
                    gFunc.EquipSet(sets.Cure_LowMP);
                end
            end
            if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Cure_Dt) end
        end
    elseif (spell.Skill == 'Elemental Magic') then
        local burst = gcinclude.BurstWanted();
        if (gcdisplay.GetCycle('NukeSet') == 'Macc') then gFunc.EquipSet(sets.NukeACC) end
        if burst then gFunc.EquipSet(sets.Burst) end
        if (gcdisplay.GetCycle('NukeSet') == 'OccultAcumen') then gFunc.EquipSet(sets.OccultAcumen) end -- /nukeset oa: TP from nukes, over Nuke/Burst
        if (gcinclude.BuffCount('Klimaform') > 0) and (spell.Element == gData.GetEnvironment().WeatherElement) then
            gFunc.EquipSet(sets.Klimaform);
        end
        if (gData.GetPlayer().MPP <= 40) then gFunc.EquipSet(sets.Mp_Body) end
        if string.contains(spell.Name, 'helix') then
            gFunc.EquipSet(sets.Helix);
            if burst then gFunc.EquipSet(sets.HelixBurst) end
            if string.contains(spell.Name, 'Nocto') then gFunc.Equip('Head', 'Pixie Hairpin +1') end
        end
    elseif (spell.Skill == 'Dark Magic') then
        gFunc.EquipSet(sets['Enfeebling Magic']); -- mostly macc anyways; Kaustra by name below
    end
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
    ByName(ws.Name); -- e.g. ['Myrkr'], then ['Myrkr_<mset>']
end

return profile;
