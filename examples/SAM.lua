local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- SAM example. Gear from GetAwayCoxn's Luashitacast-Profiles (github.com/GetAwayCoxn/Luashitacast-Profiles,
-- MIT, see LICENSE-GetAwayCoxn.txt); swap in your own.
-- Sets named after an ability, spell, skill or weapon skill (['Meditate'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_Hybrid' / '<Name>_Acc' for /meleeset. Empty sets do nothing.
local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    -- Weapon modes: add a Weapon_<Mode> set and the mode to WeaponModes in OnLoad.
    -- Weapon_Example = { Main = 'Item Name', Sub = 'Item Name' },

    Idle = {
        Main = 'Masamune',
        Sub = 'Utu Grip',
        Ammo = 'Staunch Tathlum',
        Head = 'Wakido Kabuto +2',
        Neck = 'Bathy Choker +1',
        Ear1 = { Name = 'Odnowa Earring +1', AugPath='A' },
        Ear2 = 'Eabani Earring',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Macabre Gaunt. +1',
        Ring1 = 'Karieyh Ring +1',
        Ring2 = 'Chirich Ring +1',
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = '"Store TP"+10', [5] = 'DEX+20' } },
        Waist = 'Flume Belt +1',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    Idle_Regen = {
        Head = 'Crepuscular Helm',
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Body = 'Hiza. Haramaki +2',
        Hands = 'Rao Kote',
        Ring2 = 'Chirich Ring +1',
    },
    Idle_Refresh = {},
    Resting = {},
    Town = {
        Main = 'Masamune',
        Sub = 'Utu Grip',
        Ammo = 'Staunch Tathlum',
        Head = 'Wakido Kabuto +2',
        Neck = 'Bathy Choker +1',
        Ear1 = { Name = 'Odnowa Earring +1', AugPath='A' },
        Ear2 = 'Eabani Earring',
        Body = { Name = 'Sakonji Domaru +3', AugTrial=5483 },
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = { Name = 'Gelatinous Ring +1', AugPath='A' },
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = '"Store TP"+10', [5] = 'DEX+20' } },
        Waist = 'Flume Belt +1',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Danzo Sune-Ate',
    },
    Movement = {
        Feet = 'Danzo Sune-Ate',
    },
    Dt = {
        Ammo = 'Staunch Tathlum',--3
        Head = 'Nyame Helm',--7
        Neck = { Name = 'Loricate Torque +1', AugPath='A' },--6
        Ear1 = { Name = 'Odnowa Earring +1', AugPath='A' },--1
        Ear2 = 'Schere Earring',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Nyame Gauntlets',--7
        Ring1 = 'Defending Ring',--10
        Ring2 = { Name = 'Gelatinous Ring +1', AugPath='A' },--7
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = '"Store TP"+10', [5] = 'DEX+20' } },
        Waist = 'Ioskeha Belt +1',
        Legs = 'Nyame Flanchard',--8
        Feet = 'Nyame Sollerets',--7
    },
    mdt = {},
    Aminon = {},
    SIR = {},
    TH = { -- /th: until the target is tagged; Main/Sub/Range here stay on while /th is on
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
    },

    Proc = { -- /proc: low-damage gear for proc windows, layered while engaged and on WS
        -- a set to force low dmg for things like Vagary
        Ammo = { Name = 'Coiste Bodhar', AugPath='A' },
        Head = 'Flam. Zucchetto +2',
        Neck = { Name = 'Sam. Nodowa +1', AugPath='A' },
        Ear1 = 'Telos Earring',
        Ear2 = 'Schere Earring',
        Body = 'Kasuga Domaru +2',
        Hands = 'Flam. Manopolas +2',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = '"Store TP"+10', [5] = 'DEX+20' } },
        Waist = 'Ioskeha Belt +1',
        Legs = { Name = 'Tatena. Haidate +1', AugPath='A' },
        Feet = 'Flam. Gambieras +2',
    },
    Ws_Proc = {
        -- a set to force low dmg for things like Vagary
        Ammo = 'Staunch Tathlum',
        Head = 'Flam. Zucchetto +2',
        Neck = { Name = 'Loricate Torque +1', AugPath='A' },
        Ear1 = 'Telos Earring',
        Ear2 = 'Cessance Earring',
        Body = 'Kasuga Domaru +2',
        Hands = 'Wakido Kote +3',
        Ring1 = 'Defending Ring',
        Ring2 = 'Beithir Ring',
        Back = 'Solemnity Cape',
        Waist = 'Flume Belt +1',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Flam. Gambieras +2',
    },
    Tp_Default = {
        Ammo = { Name = 'Coiste Bodhar', AugPath='A' },
        Head = 'Flam. Zucchetto +2',
        Neck = { Name = 'Sam. Nodowa +1', AugPath='A' },
        Ear1 = 'Telos Earring',
        Ear2 = 'Schere Earring',
        Body = 'Kasuga Domaru +2',
        Hands = 'Flam. Manopolas +2',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'Chirich Ring +1',
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = '"Store TP"+10', [5] = 'DEX+20' } },
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Tatena. Haidate +1', AugPath='A' },
        Feet = { Name = 'Tatena. Sune. +1', AugPath='A' },
    },
    Tp_Hybrid = {
        Head = 'Mpaca\'s Cap',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Mpaca\'s Gloves',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    Tp_Acc = {
        Ear1 = 'Mache Earring +1',
        Hands = 'Tatena. Gote +1',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
        Waist = 'Ioskeha Belt +1',
        Feet = 'Tatena. Sune. +1',
    },

    Precast = {
        Ammo = 'Sapience Orb',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Etiolation Earring',
        Ear2 = 'Loquac. Earring',
        Hands = 'Leyline Gloves',
        Ring2 = 'Prolix Ring',
    },
    Midcast = {},
    Preshot = {
        Ring1 = 'Crepuscular Ring',
    },
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },

    Ws_Default = {
        Ammo = 'Knobkierrie',
        Head = 'Mpaca\'s Cap',
        Neck = { Name = 'Sam. Nodowa +1', AugPath='A' },
        Ear1 = 'Thrud Earring',
        Ear2 = 'Schere Earring',
        Body = { Name = 'Sakonji Domaru +3', AugTrial=5483 },
        Hands = 'Kasuga Kote +2',
        Ring1 = 'Beithir Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'STR+30', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'Accuracy+20' } },
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = 'Hiza. Hizayoroi +2',
        Feet = 'Valorous Greaves',
    },
    Ws_Hybrid = {
        Body = 'Nyame Mail',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Ws_Acc = {},
    ['Savage Blade'] = {
        Ammo = 'Knobkierrie',
        Head = 'Mpaca\'s Cap',
        Neck = 'Fotia Gorget',
        Ear1 = 'Schere Earring',
        Ear2 = 'Telos Earring',
        Body = { Name = 'Sakonji Domaru +3', AugTrial=5483 },
        Hands = 'Kasuga Kote +2',
        Ring1 = 'Beithir Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'STR+30', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'Accuracy+20' } },
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = 'Mpaca\'s Hose',
        Feet = 'Valorous Greaves',
    },
    ['Savage Blade_Hybrid'] = {
        Body = 'Nyame Mail',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Tachi: Jinpu'] = {
        Ammo = 'Knobkierrie',
        Head = 'Nyame Helm',
        Neck = { Name = 'Sam. Nodowa +1', AugPath='A' },
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = { Name = 'Sakonji Domaru +3', AugTrial=5483 },
        Hands = 'Kasuga Kote +2',
        Ring2 = 'Karieyh Ring +1',
        Ring1 = 'Metamor. Ring +1',
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'STR+30', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'Accuracy+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Hiza. Hizayoroi +2',
        Feet = 'Nyame Sollerets',
    },
    ['Tachi: Jinpu_Hybrid'] = {
        Body = 'Nyame Mail',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Tachi: Ageha'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Crep. Earring',
        Ear2 = 'Lugra Earring +1',
        Body = 'Nyame Mail',
        Hands = 'Mpaca\'s Gloves',
        Ring1 = 'Stikini Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'STR+30', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'Accuracy+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Nyame Sollerets',
    },
    ['Tachi: Ageha_Hybrid'] = {
        Body = 'Nyame Mail',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Stardiver = {
        Ammo = 'Knobkierrie',
        Head = 'Mpaca\'s Cap',
        Neck = { Name = 'Sam. Nodowa +1', AugPath='A' },
        Ear1 = 'Thrud Earring',
        Ear2 = 'Schere Earring',
        Body = { Name = 'Sakonji Domaru +3', AugTrial=5483 },
        Hands = 'Mpaca\'s Gloves',
        Ring1 = 'Beithir Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Smertrios\'s Mantle', Augment = { [1] = 'STR+30', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'Accuracy+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Valorous Greaves',
    },
    Stardiver_Hybrid = {
        Body = 'Nyame Mail',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    -- ['Weapon Skill Name'] = {}, ['Weapon Skill Name_Acc'] = {},

    ['Meditate'] = {
        Head = 'Wakido Kabuto +2',
        Hands = 'Sakonji Kote +1',
    },
    ['Warding Circle'] = {},
    ['Third Eye'] = {
        Legs = 'Sakonji Haidate +1',
    },
    ['Hasso'] = {
        Hands = 'Wakido Kote +3',
    },
    ['Seigan'] = {
        Head = 'Kasuga Kabuto +1',
    },
    ['Sekkanoki'] = {
        Hands = 'Kasuga Kote +2',
    },
    ['Sengikori'] = {
        Feet = 'Kas. Sune-Ate +1',
    },
    ['Meikyo Shisui'] = {
        Feet = 'Sakonji Sune-Ate',
    },
    ['Blade Bash'] = {},
    ['Shikikoyo'] = {},
    ['Konzen-ittai'] = {},
    Provoke = {
        Neck = { Name = 'Unmoving Collar +1', AugPath='A' },
        Ear1 = 'Cryptic Earring',
        Ring1 = 'Petrov Ring',
    },
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
    {Name = 'Red Curry Bun', Quantity = 'all'},
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
        if (gcinclude.BuffCount('Hasso') > 0) then gFunc.EquipSet(sets.Hasso) end
        if (gcinclude.BuffCount('Seigan') > 0) then -- Third Eye set instead when both are up
            gFunc.EquipSet((gcinclude.BuffCount('Third Eye') > 0) and sets['Third Eye'] or sets.Seigan);
        end
        if (gcdisplay.GetToggle('PROC') == true) then gFunc.EquipSet(sets.Proc) end
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
    ByName(ability.Name);
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
    if (gcinclude.BuffCount('Meikyo Shisui') > 0) then gFunc.EquipSet(sets['Meikyo Shisui']) end
    if (gcinclude.BuffCount('Sekkanoki') > 0) then gFunc.EquipSet(sets.Sekkanoki) end
    if (gcdisplay.GetToggle('PROC') == true) then gFunc.EquipSet(sets.Ws_Proc or sets.Proc) end
end

return profile;
