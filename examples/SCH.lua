local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Main = 'Bolelabunga',
        Sub = 'Genmei Shield',
        Ammo = 'Staunch Tathlum +1',
        Head = 'Arbatel Bonnet +3',
        Neck = 'warder\'s charm +1',
        Ear1 = 'Eabani Earring',
        Ear2 = 'alabaster earring',
        Body = 'shamash robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'fortified ring',
        Ring2 = 'shadow ring',
        Back = 'null shawl',
        Waist = 'carrier\'s sash',
        Legs = 'arbatel pants +3',
        Feet = 'nyame sollerets',
    },
    Idle_Staff = {
        Main = 'Musa',
        Sub = 'Enki Strap',
    },
    Resting = {},
    Idle_Regen = {
        --Ear1 = 'Infused Earring',
		Ring1 = 'chirich ring +1',
        Ring2 = 'Chirich Ring +1',
		Waist = 'null belt',
    },
    Idle_Refresh = {
        Ammo = 'Homiliary',
        Head = 'Befouled Crown',
		Hands = 'merlinic dastanas',
        Ring1 = 'Stikini Ring +1',
		Ring2 = 'stikini ring +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'volte brais',
		Feet = 'merlinic crackows',
    },
    Town = {
        Main = 'Bunzi\'s Rod',
        Sub = 'ammurapi shield',
        Ammo = 'staunch tathlum +1',
        Head = 'Arbatel Bonnet +3',
        Neck = 'argute stole +2',
		Ear1 = 'etiolation earring',
		Ear2 = 'alabaster earring',
        Body = 'adamantite armor',
        Hands = 'Acad. Bracers +4',
		Ring1 = 'murky ring',
		Ring2 = 'shadow ring',
        Back = 'shadow mantle',
		Waist = 'null belt',
        Legs = 'nyame flanchard',
        Feet = 'acad. loafers +4',
    },

    Dt = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Etiolation Earring',
        Ear2 = 'alabaster earring',
        Body = 'adamantite armor',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'fortified ring',
        Ring2 = 'shadow ring',
        Back = 'null shawl',
        Waist = 'plat. mog. belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    SIR = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Arbatel Bonnet +3',
        Neck = 'warder\'s charm +1',
        Ear1 = 'Eabani Earring',
        Ear2 = 'alabaster earring',
        Body = 'shamash robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'fortified ring',
        Ring2 = 'shadow ring',
        Back = 'null shawl',
        Waist = 'carrier\'s sash',
        Legs = 'arbatel pants +3',
        Feet = 'nyame sollerets',
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
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Cacoethic Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Eschan Stone',
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },
    Tp_Hybrid = {
    },
    Tp_Acc = {
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Cacoethic Ring +1',
    },


    Precast = {
        Ammo = 'Sapience Orb', --2
        Head = 'Peda. M.Board +3',
        Neck = 'voltsurge torque', --4
        Ear1 = 'Loquac. Earring', --2
        Ear2 = 'Malignance Earring', --4
        Body = 'pinga tunic +1', --15
        Hands = 'Acad. Bracers +4',
        Ring1 = 'prolix Ring',
        Ring2 = 'Kishar Ring',
        Back = 'Fi Follet Cape +1',
        Waist = 'Embla Sash',
        Legs = 'Pinga Pants +1',--11
        Feet = 'peda. Loafers +2',
    },
    Cure_Precast = {
        Ear2 = 'Mendi. Earring',
        Feet = 'acad. loafers +4',
    },
    Enhancing_Precast = {
        Waist = 'Siegel Sash',
    },
    Stoneskin_Precast = {
        Head = 'Umuthi Hat',
        Hands = 'Carapacho Cuffs',
        Waist = 'Siegel Sash',
    },


    Cure = {--I cap is 50, II cap is 30
        Main = 'Bunzi\'s Rod',--I 30
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'loricate torque +1',
        Ear1 = 'Regal Earring',
        Ear2 = 'Mendi. Earring',--I 5
		Body = 'arbatel gown +3',
        Hands = 'peda. bracers +2',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Fi Follet Cape +1',
        Waist = 'Rumination Sash',
        Legs = 'acad. pants +3', --I 15
        Feet = 'acad. loafers +4',
    },
    Self_Cure = {--cap 30
        Waist = 'Gishdubar Sash',
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

    Enhancing = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'telchine cap',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Body = 'Peda. Gown +2',
        Hands = 'Arbatel Bracers +3',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'stikini ring +1',
        Back = 'fi follet cape +1',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Telchine Pigaches',
    },
    Self_Enhancing = {},
    Skill_Enhancing = {},
    Stoneskin = {
        Neck = 'Nodens Gorget',
        Waist = 'Siegel Sash',
    },
    Phalanx = {},
    Refresh = {
		Waist = 'Gishdubar Sash',
    },
    Self_Refresh = {},

    Enfeebling = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Befouled Crown',
        Neck = 'argute stole +2',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Acad. Gown +3',
        Hands = 'Peda. Bracers +2',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'stikini ring +1',
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
        Ring1 = 'evanescence ring',
        Ring2 = 'mujin band',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Acad. Pants +3',
        Feet = 'Agwu\'s Pigaches',
    },

    Nuke = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'arbatel bonnet +3',
        Neck = 'sibyl scarf',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'arbatel gown +3',
        Hands = 'arbatel bracers +3',
        Ring1 = 'freke ring',
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Lugh\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Evasion+15', [3] = 'Mag. Acc.+20', [4] = 'INT+30', [5] = 'Magic Damage+20' } },
        Waist = 'Eschan Stone',
        Legs = 'arbatel pants +3',
        Feet = 'arbatel loafers +3',
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
        Ring1 = 'freke Ring',
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
        Ring1 = 'freke ring',
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
    Ws_Hybrid = {
    },
    Ws_Acc = {
    },
    Mykyr_Default = {
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
    Mykyr_Hybrid = {
    },
    Mykyr_Acc = {
    },
    Cataclysm_Default = {
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
    Cataclysm_Hybrid = {
    },
    Cataclysm_Acc = {
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
    {Name = 'Tropical Crepe', Quantity = 'all'},
    {Name = 'Rolan. Daifuku', Quantity = 'all'},
};

profile.OnLoad = function()
	gSettings.AllowAddSet = true;
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
    local sub = gcinclude.BuffCount('Sublimation: Activated');
    gFunc.EquipSet(sets.Idle);

    if (player.Status == 'Engaged') then
        gcinclude.EquipMode('Tp');
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
		gFunc.EquipSet(sets.Movement);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    if (gcdisplay.GetCycle('Weapon') == 'Staff') then
        gFunc.EquipSet(sets.Idle_Staff);
    end
    if (sub > 0) then
        gFunc.EquipSet(sets.Sublimation);
    end
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end;
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end;
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()

    gcinclude.CheckCancels();
end

profile.HandleItem = function()
    local item = gData.GetAction();

	if string.match(item.Name, 'Holy Water') then gFunc.EquipSet(gcinclude.sets.Holy_Water) end
end

profile.HandlePrecast = function()
    local spell = gData.GetAction();

    gFunc.EquipSet(sets.Precast);

    if (spell.Skill == 'Enhancing Magic') then
        gFunc.EquipSet(sets.Enhancing_Precast);

        if string.contains(spell.Name, 'Stoneskin') then
            gFunc.EquipSet(sets.Stoneskin_Precast);
        end
    elseif (spell.Skill == 'Healing Magic') then
        gFunc.EquipSet(sets.Cure_Precast);
    end

    gcinclude.CheckCancels();
    if (gcdisplay.GetCycle('Weapon') == 'Staff') then
        gFunc.EquipSet(sets.Idle_Staff);
    end
end

profile.HandleMidcast = function()
    local spell = gData.GetAction();
    local target = gData.GetActionTarget();
    local me = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0);
    local power = gcinclude.BuffCount('Ebullience') +  gcinclude.BuffCount('Rapture');

    if (spell.Skill == 'Enhancing Magic') then
        gFunc.EquipSet(sets.Enhancing);
        if (target.Name == me) then
            gFunc.EquipSet(sets.Self_Enhancing);
        end

        if string.match(spell.Name, 'Phalanx') then
            gFunc.EquipSet(sets.Phalanx);
        elseif string.match(spell.Name, 'Stoneskin') then
            gFunc.EquipSet(sets.Stoneskin);
        elseif string.contains(spell.Name, 'Regen') then
            gFunc.EquipSet(sets.Regen);
        elseif string.contains(spell.Name, 'storm') then
            gFunc.EquipSet(sets.Storm);
        elseif string.contains(spell.Name, 'Refresh') then
            gFunc.EquipSet(sets.Refresh);
            if (target.Name == me) then
                gFunc.EquipSet(sets.Self_Refresh);
            end
        end
    elseif (spell.Skill == 'Healing Magic') then
        gFunc.EquipSet(sets.Cure);
        if (target.Name == me) then
            gFunc.EquipSet(sets.Self_Cure);
        end
        if string.match(spell.Name, 'Cursna') then
            gFunc.EquipSet(sets.Cursna);
        end
    elseif (spell.Skill == 'Elemental Magic') then
        local burst = gcinclude.BurstWanted();
        gFunc.EquipSet(sets.Nuke);

        if (gcdisplay.GetCycle('NukeSet') == 'Macc') then
            gFunc.EquipSet(sets.NukeACC);
        end
        if burst then
            gFunc.EquipSet(sets.Burst);
        end
        if (gcinclude.BuffCount('Klimaform') > 0) and (spell.Element == gData.GetEnvironment().WeatherElement) then
                gFunc.EquipSet(sets.Klimaform);
        end
        if (gData.GetPlayer().MPP <= 40) then
            gFunc.EquipSet(sets.Mp_Body);
        end
        if string.contains(spell.Name, 'helix') then
            gFunc.EquipSet(sets.Helix);
            if burst then
                gFunc.EquipSet(sets.HelixBurst);
            end
            if string.contains(spell.Name, 'Nocto') then
                gFunc.Equip('Head', 'Pixie Hairpin +1');
            end
        end
    elseif (spell.Skill == 'Enfeebling Magic') then
        gFunc.EquipSet(sets.Enfeebling);
    elseif (spell.Skill == 'Dark Magic') then
        gFunc.EquipSet(sets.Enfeebling); -- mostly macc anyways
        if (string.contains(spell.Name, 'Aspir') or string.contains(spell.Name, 'Drain')) then
            gFunc.EquipSet(sets.Drain);
        elseif (string.match(spell.Name, 'Kaustra')) then
            gFunc.EquipSet(sets.Kaustra);
        end
    end

    if (power > 0) then
        gFunc.EquipSet(sets.Power);
    end
    if (gcdisplay.GetCycle('Weapon') == 'Staff') then
        gFunc.EquipSet(sets.Idle_Staff);
    end
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

    if string.match(ws.Name, 'Cataclysm') then
        gcinclude.EquipMode('Cataclysm');
    elseif string.match(ws.Name, 'Myrkr') then
        gcinclude.EquipMode('Mykyr');
    end
end

return profile;