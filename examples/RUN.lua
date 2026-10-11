local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- RUN example. Gear from GetAwayCoxn's Luashitacast-Profiles (github.com/GetAwayCoxn/Luashitacast-Profiles,
-- MIT, see LICENSE-GetAwayCoxn.txt); swap in your own.
-- Sets named after an ability, spell, skill or weapon skill (['Vallation'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_Hybrid' / '<Name>_Acc' for /meleeset. Empty sets do nothing.
local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    -- Weapon modes: add a Weapon_<Mode> set and the mode to WeaponModes in OnLoad.
    -- Weapon_Example = { Main = 'Item Name', Sub = 'Item Name' },

    Idle = {
        Main = 'Epeolatry',
        Sub = 'Utu Grip',
        Ammo = 'Staunch Tathlum',--2
        Head = 'Nyame Helm',--7
        Neck ='Futhark Torque +1',--2 currently
        Ear1 = 'Odnowa Earring +1',--3
        Ear2 = 'Eabani Earring',
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',--7
        Ring1 = 'Moonbeam Ring',--4
        Ring2 = 'Defending Ring',--10
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Parrying rate+5%', [2] = 'Mag. Eva.+20', [3] = 'Eva.+20', [4] = 'HP+80', [5] = 'Enmity+10' } },
        Waist = 'Carrier\'s Sash',
        Legs = 'Nyame Flanchard',----8
        Feet = 'Nyame Sollerets',--7
    },
    Idle_Regen = {
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Body = 'Futhark Coat +3',
        Hands = 'Turms Mittens',
        Ring2 = 'Chirich Ring +1',
        Feet = 'Turms Leggings',
    },
    Idle_Refresh = {
        Ammo = 'Homiliary',
        Head = 'Rawhide Mask',
        Body = 'Agwu\'s Robe',
        Ring1 = 'Stikini Ring +1',
        Waist = 'Fucho-no-Obi',
    },
    Resting = {},
    Town = {
        Main = 'Epeolatry',
        Sub = 'Utu Grip',
        Ammo = 'Staunch Tathlum',
        Head = 'Erilaz Galea +2',
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',
        Legs = 'Carmine Cuisses +1',
        Feet = 'Nyame Sollerets',
    },
    Movement = {
        Legs = 'Carmine Cuisses +1',
    },
    Dt = {
        Ammo = 'Staunch Tathlum',--2
        Head = 'Nyame Helm',--7
        Neck ='Futhark Torque +1',--4 currently
        Ear1 = 'Odnowa Earring +1',--3
        Ear2 = 'Eabani Earring',
        --Body = 'Nyame Mail',--9
        Body = 'Agwu\'s Robe',--replace with Runeist coat +3
        Hands = 'Nyame Gauntlets',--7
        Ring1 = 'Moonbeam Ring',--4
        Ring2 = 'Defending Ring',--10
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Parrying rate+5%', [2] = 'Mag. Eva.+20', [3] = 'Eva.+20', [4] = 'HP+80', [5] = 'Enmity+10' } },
        Waist = 'Carrier\'s Sash',
        Legs = 'Nyame Flanchard',----8
        Feet = 'Nyame Sollerets',--7
    },
    mdt = {},
    Aminon = {},
    SIR = {
        --10 merits + 90
        Ammo = 'Staunch Tathlum', -- 10
        Head = 'Erilaz Galea +2', -- 15
        Neck = 'Moonlight Necklace', -- 15
        Hands = 'Rawhide Gloves', -- 15
        Waist = 'Audumbla Sash', -- 10
        Legs = 'Carmine Cuisses +1', -- 20
        Feet = 'Taeon Boots', -- 10
    },
    TH = { -- /th: until the target is tagged; Main/Sub/Range here stay on while /th is on
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Potency of "Cure" effect received+5%', [2] = 'Mag. Acc.+19', [3] = 'Accuracy+21', [4] = '"Mag. Atk. Bns."+19', [5] = '"Treasure Hunter"+2' } },
    },
    Enmity = {
        Neck = 'Unmoving Collar +1',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Cryptic Earring',
        Body = 'Emet Harness +1',
        Ring1 = 'Eihwaz Ring',
        Ring2 = 'Supershear Ring',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Parrying rate+5%', [2] = 'Mag. Eva.+20', [3] = 'Eva.+20', [4] = 'HP+80', [5] = 'Enmity+10' } },
        Legs = 'Eri. Leg Guards +1',
        Feet = 'Erilaz Greaves +1',
    },
    Tank_Main = {
        --Default Tanking,  dt
        Main = 'Epeolatry',
        --Sub = 'Refined Grip +1',--3
        Ammo = 'Staunch Tathlum',--2
        Head ='Nyame Helm',--7
        Neck = 'Futhark Torque +1',
        Ear1 = 'Odnowa Earring +1',--2
        Ear2 = 'Ethereal Earring',--3kinda
        --Ear2 = 'Hermodr Earring',--dragon points, 10 parry skill
        Body = 'Futhark Coat +3',--9
        Hands = 'Turms Mittens',
        Ring1 = 'Moonbeam Ring',--4
        Ring2 = 'Defending Ring',--7
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Parrying rate+5%', [2] = 'Mag. Eva.+20', [3] = 'Eva.+20', [4] = 'HP+80', [5] = 'Enmity+10' } },
        Waist = 'Flume Belt +1',
        Legs = 'Eri. Leg Guards +1',-- PDT 7
        Feet = 'Turms Leggings',--7
    },
    Tank_MEVA = {
        Main = 'Epeolatry',--Aettir technically better here
        --Sub = 'Refined Grip +1',
        Ammo = 'Staunch Tathlum',
        Head ='Nyame Helm',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Eabani Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = 'Purity Ring',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Parrying rate+5%', [2] = 'Mag. Eva.+20', [3] = 'Eva.+20', [4] = 'HP+80', [5] = 'Enmity+10' } },--want diff cape here
        Waist = 'Carrier\'s Sash',
        Legs = 'Agwu\'s Slops',
        Feet = 'Nyame Sollerets',
    },

    Tp_Default = {
        Main = 'Epeolatry',
        Sub = 'Utu Grip',
        Ammo = 'Yamarang',
        Head = 'Adhemar Bonnet +1',
        Neck ='Anu Torque',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Telos Earring',
        Body = 'Futhark Coat +3',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Epona\'s Ring',
        Ring2 = 'Niqmaddu Ring',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Ioskeha Belt +1',
        Legs = 'Meg. Chausses +2',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+20', [2] = 'Attack+6', [3] = 'AGI+1', [4] = '"Triple Atk."+3' } },
    },
    Tp_Hybrid = {
        Main = 'Epeolatry',
        Sub = 'Utu Grip',
        Ammo = 'Yamarang',
        Head = 'Nyame Helm',
        Neck ='Anu Torque',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Telos Earring',
        Body = 'Futhark Coat +3',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Epona\'s Ring',
        Ring2 = 'Niqmaddu Ring',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Ioskeha Belt +1',
        Legs = 'Meg. Chausses +2',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+20', [2] = 'Attack+6', [3] = 'AGI+1', [4] = '"Triple Atk."+3' } },
    },
    Tp_Acc = {
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
        Waist = 'Ioskeha Belt +1',
    },

    Precast = {
        Ammo = 'Sapience Orb', -- 2
        Head = 'Rune. Bandeau +2', -- 12
        Neck = 'Baetyl Pendant', -- 4
        Ear1 = 'Loquac. Earring', -- 2
        Ear2 = 'Etiolation Earring', -- 1
        Body = 'Agwu\'s Robe', -- 8
        Hands = 'Leyline Gloves', -- 6
        Ring1 = 'Prolix Ring', -- 2
        Ring2 = 'Kishar Ring', -- 4
        Waist = 'Audumbla Sash',
        Legs = 'Aya. Cosciales +2', -- 6
        Feet = 'Carmine Greaves +1',--7
    },
    Precast_Inspiration = {
        --this set I use for when my 5/5 inspire merits kicking in with val/vall up
        Ammo = 'Staunch Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Etiolation Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Eihwaz Ring',
        Ring2 = 'Gelatinous Ring +1',
        Waist = 'Audumbla Sash',
        Legs = 'Futhark Trousers +2',
        Feet = 'Agwu\'s Pigaches',
    },
    ['Healing Magic_Precast'] = {
        Ear1 = 'Mendi. Earring', -- 5
    },
    ['Enhancing Magic_Precast'] = {
        Waist = 'Siegel Sash', -- 8
        Legs = 'Futhark Trousers +2', -- 13
    },
    Midcast = {
        --10 merits + 90
        Ammo = 'Staunch Tathlum', -- 10
        Head = 'Erilaz Galea +2', -- 15
        Neck = 'Moonlight Necklace', -- 15
        Hands = 'Rawhide Gloves', -- 15
        Waist = 'Audumbla Sash', -- 10
        Legs = 'Carmine Cuisses +1', -- 20
        Feet = 'Taeon Boots', -- 10
    },
    Preshot = {},
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },
    ['Healing Magic'] = {
        Neck = 'Sacro Gorget', -- 10
        Ear1 = 'Mendi. Earring', -- 5
        Back = 'Solemnity Cape', -- 7
        Waist = 'Gishdubar Sash', --10rec
    },
    ['Blue Magic'] = {
        -- Foil and blue spells mostly
        Ammo = 'Staunch Tathlum', -- 10
        Head = 'Erilaz Galea +2', -- 15
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Cryptic Earring',
        Body = 'Emet Harness +1',
        Hands = 'Rawhide Gloves', -- 15
        Ring1 = 'Eihwaz Ring',
        Ring2 = 'Supershear Ring',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Parrying rate+5%', [2] = 'Mag. Eva.+20', [3] = 'Eva.+20', [4] = 'HP+80', [5] = 'Enmity+10' } },
        Waist = 'Audumbla Sash', -- 10
        Legs = 'Carmine Cuisses +1', -- 20
        Feet = 'Taeon Boots', -- 8
    },
    ['Enhancing Magic'] = {
        Head = 'Erilaz Galea +2',
        Neck = 'Incanter\'s Torque',
        Legs = 'Futhark Trousers +2',
    },
    ['Divine Magic'] = {},
    ['Phalanx'] = { -- all tiers
        Head = 'Fu. Bandeau +1', -- 5
        Neck = 'Incanter\'s Torque',
    },
    ['Foil'] = { -- all tiers
        -- Foil and blue spells mostly
        Ammo = 'Staunch Tathlum', -- 10
        Head = 'Erilaz Galea +2', -- 15
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Cryptic Earring',
        Body = 'Emet Harness +1',
        Hands = 'Rawhide Gloves', -- 15
        Ring1 = 'Eihwaz Ring',
        Ring2 = 'Supershear Ring',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = 'Parrying rate+5%', [2] = 'Mag. Eva.+20', [3] = 'Eva.+20', [4] = 'HP+80', [5] = 'Enmity+10' } },
        Waist = 'Audumbla Sash', -- 10
        Legs = 'Carmine Cuisses +1', -- 20
        Feet = 'Taeon Boots', -- 8
    },
    ['Flash'] = {}, -- all tiers
    ['Temper'] = { -- all tiers
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ring1 = 'Stikini Ring +1',
        --Back = 'Merciful Cape',
        Legs = 'Carmine Cuisses +1',
    },
    ['Refresh'] = {}, -- all tiers
    ['Regen'] = { -- all tiers
        Head = 'Rune. Bandeau +2',
        Neck = 'Sacro Gorget',
        Legs = 'Futhark Trousers +2',
    },
    ['Aquaveil'] = {}, -- all tiers
    ['Stoneskin'] = { -- all tiers
        Waist = 'Siegel Sash',
    },
    ['Crusade'] = {}, -- all tiers

    Ws_Default = {
        Ammo = 'Knobkierrie',
        Head = 'Nyame Helm',
        Neck = 'Fotia Gorget',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Telos Earring',
        Body = 'Nyame Mail',
        Hands = 'Futhark Mitons +3',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },
    Ws_Hybrid = {},
    Ws_Acc = {},
    Dimidiation = {
        Ammo = 'Knobkierrie',
        Head = 'Blistering Sallet +1',
        Neck = 'Fotia Gorget',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Telos Earring',
        Body = 'Nyame Mail',
        Hands = 'Meg. Gloves +2',
        Ring1 = 'Ilabrat Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Lustratio Subligar',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },
    Resolution = {
        Ammo = 'Seeth. Bomblet +1',
        Head = 'Lustratio Cap',
        Neck = 'Fotia Gorget',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Telos Earring',
        Body = 'Nyame Mail',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },--str better
        Waist = 'Fotia Belt',
        Legs = 'Meg. Chausses +2',
        Feet = 'Lustratio Leggings',
    },
    Shockwave = {
        Ammo = 'Seeth. Bomblet +1',
        Head = 'Nyame Helm',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Ring1 = 'Shiva Ring +1',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Ogma\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },--str better
        Waist = 'Acuity Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    -- ['Weapon Skill Name'] = {}, ['Weapon Skill Name_Acc'] = {},

    ['Vallation'] = {
        Body = 'Runeist Coat +1',
    },
    ['Valiance'] = {
        Body = 'Runeist Coat +1',
    },
    ['Pflug'] = {},
    ['Battuta'] = {
        Head = 'Fu. Bandeau +1',
    },
    ['Liement'] = {},
    ['Gambit'] = {},
    ['Rayke'] = {},
    ['Elemental Sforzo'] = {
        Body = 'Futhark Coat +3',
    },
    ['One for All'] = {},
    ['Swordplay'] = {
        Hands = 'Futhark Mitons +3',
    },
    ['Embolden'] = {},
    ['Vivacious Pulse'] = {
        Head = 'Erilaz Galea +2',
    },
    ['Lunge'] = {
        Ammo = 'Seeth. Bomblet +1',
        Head = 'Agwu\'s Cap',
        Neck = 'Baetyl Pendant',
        Ear2 = 'Crematio Earring',
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shiva Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Waist = 'Eschan Stone',
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },
    ['Swipe'] = {
        Ammo = 'Seeth. Bomblet +1',
        Head = 'Agwu\'s Cap',
        Neck = 'Baetyl Pendant',
        Ear2 = 'Crematio Earring',
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shiva Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Waist = 'Eschan Stone',
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },
    ['Odyllic Subterfuge'] = {},
    ['Provoke'] = {},
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
    {Name = 'Om. Sandwich', Quantity = 'all'},
    {Name = 'Black Curry Bun', Quantity = 'all'},
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
        local tank = gcdisplay.GetCycle('TankSet');
        if (tank ~= 'None') then gFunc.EquipSet(gcinclude.FindSet('Tank_' .. tank)) end
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
        gFunc.EquipSet(sets.Movement);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end
    gcinclude.CheckDefault();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    gFunc.EquipSet(sets.Enmity);
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
    if (gcinclude.BuffCount('Vallation') > 0) or (gcinclude.BuffCount('Valiance') > 0) then
        gFunc.EquipSet(sets.Precast_Inspiration); -- Inspiration merits: Fast Cast while Vallation/Valiance is up
    else
        ByName(spell.Skill .. '_Precast'); -- e.g. ['Enhancing Magic_Precast']
    end
    gcinclude.CheckCancels();
end

profile.HandleMidcast = function()
    local spell = gData.GetAction();
    gFunc.EquipSet(sets.Enmity);
    gFunc.EquipSet(sets.Midcast);
    ByName(spell.Skill);
    if not ByName(spell.Name) then ByName(Family(spell.Name)) end
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
