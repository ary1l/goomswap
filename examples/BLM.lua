local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- BLM example. Gear from GetAwayCoxn's Luashitacast-Profiles (github.com/GetAwayCoxn/Luashitacast-Profiles,
-- MIT, see LICENSE-GetAwayCoxn.txt); swap in your own.
-- Sets named after an ability, spell, skill or weapon skill (['Manafont'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_Hybrid' / '<Name>_Acc' for /meleeset. Empty sets do nothing.
local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    -- Weapon modes: add a Weapon_<Mode> set and the mode to WeaponModes in OnLoad.
    -- Weapon_Example = { Main = 'Item Name', Sub = 'Item Name' },

    Idle = {
        Main = 'Bolelabunga',
        Sub = 'Genmei Shield',
        Ammo = 'Staunch Tathlum',
        Head = 'Agwu\'s Cap',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Eabani Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Agwu\'s Robe',
        Hands = 'Amalric Gages +1',
        Ring1 = 'Stikini Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = { Name = 'Taranus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc+20', [4] = 'INT+20', [5] = 'Magic Damage +20' } },
        Waist = 'Gishdubar Sash',
        Legs = 'Agwu\'s Slops',
        Feet = 'Volte Gaiters',
    },
    Idle_Regen = {
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Ring2 = 'Chirich Ring +1',
    },
    Idle_Refresh = {
        Head = 'Befouled Crown',
        Waist = 'Fucho-no-Obi',
        Legs = 'Assid. Pants +1',
    },
    Idle_Staff = {
        Main = 'Marin Staff +1',
        Sub = 'Enki Strap',
    },
    Resting = {},
    Town = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Culminus',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Agwu\'s Cap',
        Neck = 'Bathy Choker +1',
        Body = 'Agwu\'s Robe',
        Hands = 'Amalric Gages +1',
        Back = { Name = 'Taranus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc+20', [4] = 'INT+20', [5] = 'Magic Damage +20' } },
        Legs = 'Agwu\'s Slops',
        Feet = 'Herald\'s Gaiters',
    },
    Movement = {
        Feet = 'Herald\'s Gaiters',
    },
    Dt = {
        Ammo = 'Staunch Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Etiolation Earring',
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = 'Gelatinous Ring +1',
        Back = { Name = 'Taranus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc+20', [4] = 'INT+20', [5] = 'Magic Damage +20' } },
        Waist = 'Gishdubar Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    mdt = {},
    Aminon = {},
    SIR = {},
    TH = { -- /th: until the target is tagged; Main/Sub/Range here stay on while /th is on
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
    },

    Tp_Default = {},
    Tp_Hybrid = {},
    Tp_Acc = {
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
    },

    Precast = {
        Ammo = 'Sapience Orb',
        Head = 'Haruspex Hat',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Agwu\'s Robe',
        Hands = 'Mallquis Cuffs +2',
        Ring1 = 'Kishar Ring',
        Ring2 = 'Mallquis Ring',
        Back = 'Swith Cape +1',
        Waist = 'Embla Sash',
        Legs = 'Agwu\'s Slops',
        Feet = 'Volte Gaiters',
    },
    ['Healing Magic_Precast'] = {
        Ear1 = 'Mendi. Earring',
        Feet = 'Vanya Clogs',
    },
    ['Enhancing Magic_Precast'] = {
        Waist = 'Siegel Sash',
    },
    Stoneskin_Precast = {
        Head = 'Umuthi Hat',
        Hands = 'Carapacho Cuffs',
        Waist = 'Siegel Sash',
    },
    Midcast = {},
    Preshot = {},
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },
    Nuke = {
        Main = 'Marin Staff +1',
        Sub = 'Enki Strap',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Jhakri Coronal +2',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Regal Earring',
        Body = 'Arch. Coat +3',
        Hands = 'Amalric Gages +1',
        Ring1 = 'Shiva Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = { Name = 'Taranus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc+20', [4] = 'INT+20', [5] = 'Magic Damage +20' } },
        Waist = 'Eschan Stone',
        Legs = 'Wicce Chausses +2',
        Feet = 'Amalric Nails +1',
    },
    NukeACC = {
        Waist = { Name = 'Acuity Belt +1', AugPath='A' },
    },
    Burst = {
        Main = 'Bunzi\'s Rod', -- 10 and 0
        Sub = 'Ammurapi Shield',
        Head = 'Ea Hat', -- 6 and 6
        Neck = 'Src. Stole +1', -- 8 and 0
        Body = 'Ea Houppelande', -- 8 and 9
        Hands = 'Amalric Gages +1', -- 0 and 6
        Ring1 = 'Mujin Band', -- 0 and 5
        Back = { Name = 'Taranus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc+20', [4] = 'INT+20', [5] = 'Magic Damage +20' } }, -- 5 and 0
        Waist = { Name = 'Acuity Belt +1', AugPath='A' },
        Legs = 'Agwu\'s Slops', -- 9 and 0
        Feet = 'Ea Pigaches', -- 4 and 4
    },
    Helix = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Head = 'Mall. Chapeau +2',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Wicce Earring +1',
        Body = 'Agwu\'s Robe',
        Hands = 'Amalric Gages +1',
        Back = { Name = 'Taranus\'s Cape', Augment = { [1] = 'Damage taken-5%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc+20', [4] = 'INT+20', [5] = 'Magic Damage +20' } },
        Waist = { Name = 'Acuity Belt +1', AugPath='A' },
        Legs = 'Agwu\'s Slops',
        Feet = 'Amalric Nails +1',
    },
    Death_Mode = {
        Main = 'Marin Staff +1',
        Sub = 'Enki Strap',
        Ammo = 'Ghastly Tathlum +1',
        Head = 'Pixie Hairpin +1',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Mendi. Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Archon Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = 'Aurist\'s Cape +1',
        Waist = { Name = 'Acuity Belt +1', AugPath='A' },
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },
    ['Enfeebling Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Befouled Crown',
        Neck = 'Erra Pendant',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Regal Earring',
        Body = 'Arch. Coat +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Kishar Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = { Name = 'Aurist\'s Cape +1', AugPath='A' },
        Waist = { Name = 'Acuity Belt +1', AugPath='A' },
        Legs = 'Agwu\'s Slops',
        Feet = { Name = 'Medium\'s Sabots', Augment = { [1] = 'MND+6', [2] = '"Conserve MP"+5', [3] = 'MP+40', [4] = '"Cure" potency +3%' } },
    },
    ['Dark Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Src. Stole +1',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Regal Earring',
        Body = 'Spaekona\'s Coat +2',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Kishar Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = { Name = 'Aurist\'s Cape +1', AugPath='A' },
        Waist = { Name = 'Acuity Belt +1', AugPath='A' },
        Legs = 'Agwu\'s Slops',
        Feet = { Name = 'Medium\'s Sabots', Augment = { [1] = 'MND+6', [2] = '"Conserve MP"+5', [3] = 'MP+40', [4] = '"Cure" potency +3%' } },
    },
    ['Enhancing Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Befouled Crown',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Mendi. Earring',
        Ear2 = 'Andoaa Earring',
        Body = 'Telchine Chas.',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = 'Solemnity Cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Telchine Pigaches',
    },
    ['Healing Magic'] = {
        --I cap is 50, II cap is 30
        Main = 'Bunzi\'s Rod',--I 30
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Nodens Gorget',--I 5
        Ear1 = 'Mendi. Earring',--I 5
        Ear2 = 'Regal Earring',
        Hands = 'Telchine Gloves',--I 9
        Ring1 = 'Stikini Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = 'Aurist\'s Cape +1',
        Waist = 'Rumination Sash',
        Feet = 'Vanya Clogs',--I 10
    },
    ['Death'] = { -- all tiers
        Main = 'Marin Staff +1',
        Sub = 'Enki Strap',
        Ammo = 'Ghastly Tathlum +1',
        Head = 'Pixie Hairpin +1',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Mendi. Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Archon Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = 'Aurist\'s Cape +1',
        Waist = { Name = 'Acuity Belt +1', AugPath='A' },
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },
    ['Impact'] = {}, -- all tiers
    ['Stun'] = {}, -- all tiers
    ['Drain'] = { -- all tiers
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Erra Pendant',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Regal Earring',
        Body = 'Spaekona\'s Coat +2',
        Ring1 = 'Kishar Ring',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },
    ['Aspir'] = { -- all tiers
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Erra Pendant',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Regal Earring',
        Body = 'Spaekona\'s Coat +2',
        Ring1 = 'Kishar Ring',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },
    Self_Cure = {
        --cap 30
        Waist = 'Gishdubar Sash',
    },
    Regen = {
        Main = 'Bolelabunga',
        Sub = 'Ammurapi Shield',
        Body = 'Telchine Chas.',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Telchine Pigaches',
    },
    Cursna = {
        Ring1 = 'Purity Ring',
        Waist = 'Gishdubar Sash',
        Feet = 'Vanya Clogs',
    },
    Stoneskin = {
        Neck = 'Nodens Gorget',
        Waist = 'Siegel Sash',
    },
    Refresh = {
        Waist = 'Gishdubar Sash',
    },

    Ws_Default = {
        --myrkr mostly
        Ammo = 'Ghastly Tathlum +1',
        Head = 'Pixie Hairpin +1',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Mendi. Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Ea Houppelande',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Sangoma Ring',
        Ring2 = 'Metamor. Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Shinjutsu-no-Obi +1',
        Legs = 'Wicce Chausses +2',
        Feet = 'Nyame Sollerets',
    },
    Ws_Hybrid = {},
    Ws_Acc = {},
    -- ['Weapon Skill Name'] = {}, ['Weapon Skill Name_Acc'] = {},

    ['Manafont'] = {},
    ['Elemental Seal'] = {},
    ['Mana Wall'] = {},
    ['Subtle Sorcery'] = {},
    ['Cascade'] = {},
    ['Manawell'] = {},
    ['Enmity Douse'] = {},
    Absorb = {}, -- every Absorb- spell (land rate: Dark Magic skill, macc; potency is not skill)
    Absorb_TP = {}, -- Absorb-TP on top of Absorb
    Cure_Received = {},
    Cursna_Received = {},
    Phalanx_Received = {},
    Protect_Shell_Received = {},
    Regen_Received = {},
    Refresh_Received = {},
    Waltz_Received = {},
};
profile.Sets = sets;

profile.Packer = {
    {Name = 'Tropical Crepe', Quantity = 'all'},
    {Name = 'Rolan. Daifuku', Quantity = 'all'},
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None'}; -- e.g. {'None', 'Example'} with a Weapon_Example set
    gcinclude.DefaultWeapons = 'None';
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
    if (gcdisplay.GetCycle('Weapon') == 'Staff') then gFunc.EquipSet(sets.Idle_Staff) end
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end
    gcinclude.CheckDefault();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    ByName(ability.Name);
    gcinclude.CheckCancels();
end

profile.HandleItem = function()
    local item = gData.GetAction();
    if string.match(item.Name, 'Holy Water') then gFunc.EquipSet(gcinclude.sets.Holy_Water) end
end

profile.HandlePrecast = function()
    local spell = gData.GetAction();
    gFunc.EquipSet(sets.Precast);
    ByName(spell.Skill .. '_Precast'); -- e.g. ['Healing Magic_Precast']
    ByName(Family(spell.Name) .. '_Precast'); -- e.g. ['Stoneskin_Precast'], on top
    if (gcdisplay.GetCycle('Weapon') == 'Staff') then gFunc.EquipSet(sets.Idle_Staff) end
    gcinclude.CheckCancels();
end

profile.HandleMidcast = function()
    local spell = gData.GetAction();
    gFunc.EquipSet(sets.Midcast);
    ByName(spell.Skill);
    if (spell.Skill == 'Elemental Magic') then
        gFunc.EquipSet(sets.Nuke);
        if (gcdisplay.GetCycle('NukeSet') == 'Macc') then gFunc.EquipSet(sets.NukeACC) end
        if gcinclude.BurstWanted() then gFunc.EquipSet(sets.Burst) end
        if string.find(spell.Name, 'helix', 1, true) then -- e.g. Pyrohelix II
            gFunc.EquipSet(sets.Helix);
            if gcinclude.BurstWanted() then gFunc.EquipSet(sets.Burst) end
        end
        if (gcdisplay.GetToggle('Death') == true) then gFunc.EquipSet(sets.Death_Mode) end
    end
    local target = gData.GetActionTarget();
    if (spell.Skill == 'Healing Magic') and (target ~= nil) and (target.Name == gData.GetPlayer().Name) then
        gFunc.EquipSet(sets.Self_Cure);
    end
    if not ByName(spell.Name) then ByName(Family(spell.Name)) end
    if (gcdisplay.GetCycle('Weapon') == 'Staff') then gFunc.EquipSet(sets.Idle_Staff) end
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
    ByName(ws.Name);
end

return profile;
