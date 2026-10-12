local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Main = 'Bolelabunga',
        Sub = 'genmei shield',
        Ammo = 'Staunch Tathlum +1',
        Head = 'nyame helm',
        Neck = 'loricate torque +1',
        Ear1 = 'alabaster Earring',
        Ear2 = 'eabani earring',
        Body = 'ebers bliaut +2',
        Hands = 'nyame gauntlets',
        Ring1 = 'murky ring',
        Ring2 = 'gurebu\'s ring',
		Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
		Waist = 'carrier\'s sash',
		Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },
    Resting = {},
    Idle_Regen = {
        Neck = 'Sanctity necklace',
        --Ear1 = 'Infused Earring',
        --Ring1 = 'Chirich Ring +1',
		Ring2 = 'gurebu\'s ring',
		Waist = 'null belt',
    },
    Idle_Refresh = {
        --Ammo = 'Homiliary',
        Head = 'volte beret',
		Neck = 'sibyl scarf',
		Body = 'ebers bliaut +2',
        Hands = 'volte gloves',
        Ring1 = 'Stikini Ring +1',
		Ring2 = 'gurebu\'s ring',
        Waist = 'Fucho-no-Obi',
        Legs = 'volte brais',
		Feet = 'volte boots',
    },
    Town = {
        Main = 'yagrush',
        Sub = 'chanter\'s shield',
		--Ammo = 'Homiliary',
        Head = 'theo. cap +4',
		Neck = 'sibyl scarf',
		Body = 'ebers bliaut +2',
        Hands = 'ebers mitts +2',
        Ring1 = 'murky ring',
		Ring2 = 'gurebu\'s ring',
        Waist = 'null belt',
        Legs = 'sworn brais',
		Feet = 'theo. duckbills +4',
    },

    Dt = {
		Sub = 'genmei shield',
        Ammo = 'Staunch Tathlum +1',
        Head = 'nyame helm',
        Neck = 'loricate torque +1',
        Ear1 = 'alabaster earring',
        Ear2 = 'eabani Earring',
        Body = 'nyame mail',
        Hands = 'ebers mitts +2',
        Ring1 = 'murky Ring',
        Ring2 = 'defending ring',
		Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
		Waist = 'carrier\'s sash',
        Legs = 'ebers pant. +3',
        Feet = 'nyame sollerets',
    },
    Sleeping = { -- worn while asleep over the /def set and Incapacitated, past the TP hold: stage 2 Lorg Mor "Slowly devours your soul" (HP/MP drain wakes you); stages 3+ don't drain
        Main = 'Lorg Mor',
    },
    SIR = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'theo. cap +4',
        Neck = 'loricate torque +1',
        Ear1 = 'alabaster Earring',
        Ear2 = 'eabani earring',
        Body = 'theo. bliaut +4',
        Hands = 'theo. mitts +4',
        Ring1 = 'murky ring',
        Ring2 = 'gurebu\'s ring',
		Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
		Waist = 'carrier\'s sash',
		Legs = 'ebers pant. +3',
        Feet = 'theo. duckbills +4',
    },
    Tp_Default = {
        Main = 'Maxentius',
        Sub = 'diamond aspis',
        Ammo = 'Staunch Tathlum +1',
        Head = 'Aya. Zucchetto +1',
		Neck = 'Sanctity Necklace',
        Ear1 = 'Brutal Earring',
        Ear2 = 'eabani Earring',
        Body = 'ayanmo corazza +1',
        Hands = 'bunzi\'s gloves',
        Ring1 = 'rajas ring',
        Ring2 = 'ayanmo ring',
		Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+30', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Cornelia\'s Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'bunzi\'s sabots',
    },
    Tp_Hybrid = {
    },
    Tp_Acc = {
        Ear2 = 'Digni. Earring',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
    },


    Precast = {
		Main = 'gada',--5
		Sub = 'chanter\'s shield',--3
        Ammo = 'Impatiens',
        Head = 'ebers cap +2',--10
		Neck = 'Clr. Torque +2',--10
        Ear1 = 'alabaster earring',
        Ear2 = 'Malignance Earring',
		Body = 'inyanga jubbah +2',--14
        Hands = 'egbesu mitts', --5
        Ring1 = 'lebeche Ring',
        Ring2 = 'weather. Ring',--5
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },--10
        Waist = 'Witful Belt',--3
        Legs = 'sworn brais',--8
        Feet = 'regal pumps +1',--5
    },
    Cure_Precast = {
		Main = 'gada',--5
		Sub = 'chanter\'s shield',--3
        Ammo = 'Impatiens',
        Head = 'ebers cap +2',--10
		Neck = 'Clr. Torque +2',--10
        Ear1 = 'alabaster earring',
        Ear2 = 'malignance earring',
		Body = 'inyanga jubbah +2',
        Hands = 'egbesu mitts', --6
        Ring1 = 'lebeche Ring',--2
        Ring2 = 'weather. Ring',--5
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Witful Belt',
        Legs = 'sworn brais',
        Feet = 'regal pumps +1',
    },
    Enhancing_Precast = {
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
    Cure = {--I cap is 50, II cap is 30
        Main = 'raetic rod +1',
		Sub = 'thuellaic ecu +1',
        Ammo = 'impatiens',
		Head = 'theo. cap +4',
        Neck = 'Clr. Torque +2',
        Ear1 = 'mendi. earring',
        Ear2 = 'ebers earring +1',
		Body = 'ebers bliaut +2',
        Hands = 'theo. mitts +4',
        Ring1 = 'weather. ring',
		Ring2 = 'lebeche ring',
		Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'witful belt',
		Legs = 'ebers pant. +3',--I 11
        Feet = 'regal pumps +1',
    },
    Self_Cure = {--cap 30
        Waist = 'Gishdubar Sash',
    },
    Cure_LowMP = { -- MP <= 50%, no Light weather
        Main = 'Daybreak',
        Sub = 'thuellaic ecu +1',
    },
    Cure_LowMP_Storm = { -- MP <= 50%, Light weather: Aurorastorm I/II or natural Light weather
        Main = 'Chatoyant Staff', -- or 'Iridal Staff': "Cure" potency +10%, Iridescence (+10% weather roll)
        Sub = 'Enki Strap',
    },
    Cure_Dt = { -- /dt on: goes over the cure sets above, so list only the DT pieces to trade in
        Head = 'nyame helm',
        Ear1 = 'alabaster earring',
        Ring2 = 'murky ring',
        Feet = 'nyame sollerets',
    },
    Regen = {
        Main = 'Bolelabunga',
        Sub = 'Ammurapi Shield',
		Head = 'inyanga tiara +2',
		Body = 'Piety Bliaut +3',
		Hands = 'ebers mitts +2',
        Waist = 'embla sash',
        Legs = 'theo. pant. +4',
		Feet = 'theo. duckbills +4',
    },
	erase = {
		Main = 'yagrush',
        Sub = 'Ammurapi Shield',
		Ammo = 'impatiens',
		Neck = 'Clr. Torque +2',
		Ear1 = 'alabaster earring',
		Ear2 = 'malignance earring',
		Hands = 'ebers mitts +2',
        Ring1 = 'kishar Ring',
		Ring2 = 'weather. Ring',
		Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
		Waist = 'witful belt',
		Legs = 'sworn brais',
        Feet = 'theo. duckbills +4',
    },
    Cursna = {
		Main = 'yagrush',
        Sub = 'Ammurapi Shield',
		Head = 'vanya hood',
		Neck = 'debilis medallion',
		Hands = 'fanatic gloves',
        Ring1 = 'Haoma\'s Ring',
		Ring2 = 'Menelaus\'s Ring',
		Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
		Waist = 'bishop\'s Sash',
		Legs = 'theo. pant. +4',
        Feet = 'Vanya Clogs',
    },

    Enhancing = {
        Main = 'yagrush',
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
        Feet = 'theo. duckbills +4',
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

    Divine = {}, -- Flash, Repose, Banish, Holy: layered over Enfeebling
    Enfeebling = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Befouled Crown',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
		Body = 'theo. bliaut +4',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Acuity Belt +1',
		Legs = 'chironic hose',
		Feet = 'theo. duckbills +4',
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
		Legs = 'chironic hose',
		Feet = 'theo. duckbills +4',
    },

    Nuke = {
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
        Neck = 'rep. plat. medal',
        Ear1 = 'brutal Earring',
        Ear2 = 'ishvara Earring',
        Body = 'ayanmo corazza +1',
        Hands = 'bunzi\'s gloves',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Karieyh Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+30', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Cornelia\'s belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Ws_Hybrid = {
    },
    Ws_Acc = {
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
        Ring2 = 'Karieyh Ring',
        Back = 'alabaster mantle',
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Cataclysm_Hybrid = {
    },
    Cataclysm_Acc = {
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

profile.OnLoad = function()
	gSettings.AllowAddSet = true;
    gcinclude.settings.KeepWeaponsFor = T{}; -- cures pick Main/Sub by MP (HandleMidcast), so a worn Daybreak must not be kept
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

    gFunc.EquipSet(sets.Idle);

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
end

profile.HandleMidcast = function()
    local player = gData.GetPlayer();
    local weather = gData.GetEnvironment();
    local spell = gData.GetAction();
    local target = gData.GetActionTarget();
    local me = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0);

    if (spell.Skill == 'Enhancing Magic') then
        gFunc.EquipSet(sets.Enhancing);
        if (target.Name == me) then
            gFunc.EquipSet(sets.Self_Enhancing);
        end

        if string.match(spell.Name, 'Phalanx') then
            gFunc.EquipSet(sets.Phalanx);
        elseif string.match(spell.Name, 'Stoneskin') then
            gFunc.EquipSet(sets.Stoneskin);
        elseif string.contains(spell.Name, 'Regen IV') then
            gFunc.EquipSet(sets.Regen);
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
        if T{'Cure', 'Cura', 'Curaga'}:contains(gcinclude.Family(spell.Name)) then
            if (player.MPP <= 50) then -- above 50%: Cure's Raetic Rod +1 / Ecu stay
                -- Light weather: Aurorastorm counts (LAC GetEnvironment reads storm buffs as weather), so does natural Light
                if (weather ~= nil) and (weather.WeatherElement == 'Light') then
                    gFunc.EquipSet(sets.Cure_LowMP_Storm);
                else
                    gFunc.EquipSet(sets.Cure_LowMP);
                end
            end
            if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Cure_Dt) end
        end
		if string.match(spell.Name, 'Paralyna') or string.match(spell.Name, 'Erase') or string.match(spell.Name, 'Blindna') or (string.match(spell.Name, 'Silena') or string.match(spell.Name, 'Poisona') or string.match(spell.Name, 'Stona') or string.match(spell.Name, 'Viruna')) then
            gFunc.EquipSet(sets.erase);
        end
        if string.match(spell.Name, 'Cursna') then
            gFunc.EquipSet(sets.Cursna);
        end
    elseif (spell.Skill == 'Elemental Magic') then
        gFunc.EquipSet(sets.Nuke);

        if (gcdisplay.GetCycle('NukeSet') == 'Macc') then
            gFunc.EquipSet(sets.NukeACC);
        end
    elseif (spell.Skill == 'Divine Magic') then
        gFunc.EquipSet(sets.Enfeebling);
        gFunc.EquipSet(sets.Divine);
    elseif (spell.Skill == 'Enfeebling Magic') then
        gFunc.EquipSet(sets.Enfeebling);
    elseif (spell.Skill == 'Dark Magic') then
        gFunc.EquipSet(sets.Enfeebling); -- mostly macc anyways
        if (string.contains(spell.Name, 'Aspir') or string.contains(spell.Name, 'Drain')) then
            gFunc.EquipSet(sets.Drain);
        end
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
    end
end

return profile;