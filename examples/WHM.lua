local profile = {};
if (gFunc == nil) then error('GoomSwap: GearSwap loaded this job file directly. Windower: move it to data/goomswap/<Name>/<JOB>.lua and delete it from data/<Name>/ (see README Install)', 0) end
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
-- gcinclude.Food = {'Grape Daifuku +1'}; -- this job's food: /packer keeps a stack of each (replaces the Food setting / char.lua's)
-- gcinclude.Packer = { ['Echo Drops'] = 'stack', ['Holy Water'] = 'stack' }; -- kept in inventory on job change (/packer, Bellhop plugin)
gcinclude.settings.SmartSwap = false; -- always swap to the casting weapons: TP isn't used on this job
gcinclude.settings.WeaponTPGuard = 0; -- no 1000+ TP weapon hold either (nukes, Dark, Divine swap too)
gcinclude.CureObi = true; -- Hachirin-no-Obi on Cure/Cura/Curaga in Light day/weather (Aurorastorm counts); false = never

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
        Ring2 = 'stikini ring +1',
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
        --Head = 'volte beret',
		--Neck = 'sibyl scarf',
		Body = 'ebers bliaut +2',
        --Hands = 'volte gloves',
        Ring1 = 'Stikini Ring +1',
		--Ring2 = 'gurebu\'s ring',
        Waist = 'Fucho-no-Obi',
        --Legs = 'volte brais',
		--Feet = 'volte boots',
    },
    Idle_Regain = { -- /idleset regain: over Idle while idle
    },
    Town = {
        Main = 'yagrush',
        Sub = 'chanter\'s shield',
		--Ammo = 'Homiliary',
        Head = 'theo. cap +4',
		Neck = 'sibyl scarf',
		Body = 'ebers bliaut +2',
        Hands = 'sworn gauntlets',
        Ring1 = 'murky ring',
		Ring2 = 'stikini ring +1',
        Waist = 'null belt',
        Legs = 'sworn brais',
		Feet = 'sworn sabatons',
    },

    Dt = {
		Sub = 'genmei shield',
        Ammo = 'Staunch Tathlum +1',
        Head = 'nyame helm',
        Neck = 'loricate torque +1',
        Ear1 = 'alabaster earring',
        Ear2 = 'eabani Earring',
        Body = 'ebers bliaut +2',
        Hands = 'nyame gauntlets',
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
        Hands = 'sworn gauntlets',
        Ring1 = 'rajas ring',
        Ring2 = 'ayanmo ring',
		Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+30', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Cornelia\'s Belt',
        Legs = 'sworn brais',
        Feet = 'sworn sabatons',
    },
    Tp_SubtleBlow = { -- /mset subtleblow: Subtle Blow pieces over Tp_Default
    },
    Tp_Acc = {
        Ear2 = 'Digni. Earring',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
    },
    Midcast = {},


    Precast = {
		Main = 'gada',--5
		Sub = 'chanter\'s shield',--3
        Ammo = 'Impatiens',
        Head = 'ebers cap +2',--10
		Neck = 'Clr. Torque +2',--10
        Ear1 = 'alabaster earring',
        Ear2 = 'Malignance Earring',
		Body = 'inyanga jubbah +2',--14
        Hands = 'sworn gauntlets', --5
        Ring1 = 'weather. Ring',--5
        Ring2 = 'lebeche Ring',
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },--10
        Waist = 'Witful Belt',--3
        Legs = 'sworn brais',--8
        Feet = 'sworn sabatons',--5
    },
    ['Healing Magic_Precast'] = {
		Main = 'gada',--5
		Sub = 'chanter\'s shield',--3
        Ammo = 'Impatiens',
        Head = 'ebers cap +2',--10
		Neck = 'Clr. Torque +2',--10
        Ear1 = 'alabaster earring',
        Ear2 = 'malignance earring',
		Body = 'inyanga jubbah +2',
        Hands = 'sworn gauntlets', --6
        Ring1 = 'weather. Ring',--5
        Ring2 = 'lebeche Ring',--2
        Back = { Name = 'Alaunus\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+20', [4] = 'MND+30', [5] = 'Evasion+20' } },
        Waist = 'Witful Belt',
        Legs = 'sworn brais',
        Feet = 'sworn sabatons',
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
        Feet = 'sworn sabatons',
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
    Cure_Dt = { -- over the cure sets while /dt is on: DT pieces only
        Head = 'nyame helm',
        Ear1 = 'alabaster earring',
        Ring1 = 'murky ring',
    },
    ['Regen IV'] = {
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

    ['Enhancing Magic'] = {
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

    ['Divine Magic'] = {}, -- Flash, Repose, Banish, Holy: layered over Enfeebling
    ['Enfeebling Magic'] = {
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
		Legs = 'chironic hose',
		Feet = 'theo. duckbills +4',
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
    Ws_Acc = {
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
        Back = 'alabaster mantle',
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
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
    -- Templates: fill the ones you use; an empty set changes nothing.
    Proc = {}, -- /proc: low-damage gear for proc windows (Abyssea, Vagary...), over the engaged sets
    Ws_Proc = {}, -- /proc on weapon skills (empty: Proc)
    Ws_HighBuff = {}, -- /wsset high: over Ws_Default (PDL)
    Cataclysm_HighBuff = {}, -- /wsset high: this WS
    Benediction = {}, -- a job ability: worn as it goes off (ByName)
    Buffs = { -- while the buff is up: idle and engaged
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Ws = { -- while the buff is up: weapon skills
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Midcast = { -- while the buff is up: spells (e.g. ['Saboteur'])
    },
    -- Weapon_Example_Acc = { Main = 'Item Name' }, -- /mset acc: a whole weapon set in place of Weapon_Example
    -- Weapon_Example_1h = { Main = 'Item Name', Sub = 'Shield Name' }, -- when you can't dual wield (/dw off, sub not NIN/DNC)
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

local ByName, Family = gcinclude.ByName, gcinclude.Family;

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

    gcinclude.EquipIdle(); -- Idle, then Idle_<mode> (/idleset)

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
    local target = gData.GetActionTarget();
    local me = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0);
    local family = Family(spell.Name); -- 'Cure IV' -> 'Cure'
    gFunc.EquipSet(sets.Midcast);
    if (spell.Skill == 'Divine Magic') then gFunc.EquipSet(sets['Enfeebling Magic']) end -- under ['Divine Magic']
    ByName(spell.Skill); -- e.g. ['Enhancing Magic'], ['Healing Magic'], ['Elemental Magic']
    if (spell.Skill == 'Enhancing Magic') then
        if (target.Name == me) then gFunc.EquipSet(sets.Self_Enhancing) end
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
        if T{'Paralyna', 'Erase', 'Blindna', 'Silena', 'Poisona', 'Stona', 'Viruna'}:contains(spell.Name) then
            gFunc.EquipSet(sets.erase);
        end
    elseif (spell.Skill == 'Elemental Magic') then
        if (gcdisplay.GetCycle('NukeSet') == 'Macc') then gFunc.EquipSet(sets.NukeACC) end
    elseif (spell.Skill == 'Dark Magic') then
        gFunc.EquipSet(sets['Enfeebling Magic']); -- mostly macc anyways
    end
    if not ByName(spell.Name) then ByName(family) end -- a set named after the spell or its family, e.g. ['Phalanx'], ['Cursna'], ['Drain']
    if (family == 'Refresh') and (target.Name == me) then gFunc.EquipSet(sets.Self_Refresh) end
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