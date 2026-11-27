local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- DNC example: swap in your own gear.
-- Sets named after an ability, spell, skill or weapon skill (['Trance'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_SubtleBlow' / '<Name>_Acc' for /mset. Empty sets do nothing.
local sets = {

    Idle = {
        Ammo = 'Yamarang',
        Head = 'Malignance Chapeau',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Eabani Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Malignance Gloves',
        Ring1 = 'Defending Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = 'Solemnity Cape',
        Waist = 'Gishdubar Sash',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Idle_Regen = {
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Ring2 = 'Chirich Ring +1',
        Feet = 'Turms Leggings',
    },
    Resting = {},
    Town = {
        Main = 'Tauret',
        Sub = 'Acrontica',
        Ammo = 'Yamarang',
        Head = 'Maculele Tiara +1',
        Body = 'Macu. Casaque +1',
        Hands = 'Malignance Gloves',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Movement = {
        Feet = 'Herald\'s Gaiters',
    },
    Dt = {
        Ammo = 'Staunch Tathlum',
        Head = 'Nyame Helm',
        Neck = { Name = 'Loricate Torque +1', AugPath='A' },
        Ear1 = { Name = 'Odnowa Earring +1', AugPath='A' },
        Ear2 = 'Etiolation Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = { Name = 'Gelatinous Ring +1', AugPath='A' },
        Back = 'Solemnity Cape',
        Waist = 'Flume Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    TH = { -- /th: until the target is tagged; Main/Sub/Range here stay on while /th is on
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Potency of "Cure" effect received+5%', [2] = 'Mag. Acc.+19', [3] = 'Accuracy+21', [4] = '"Mag. Atk. Bns."+19', [5] = '"Treasure Hunter"+2' } },
    },

    Tp_Default = {
        Ammo = { Name = 'Coiste Bodhar', AugPath='A' },
        Head = { Name = 'Adhemar Bonnet +1', AugPath='B' },
        Neck = 'Anu Torque',
        Ear1 = 'Eabani Earring',
        Ear2 = 'Sherida Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Gere Ring',
        Ring2 = 'Epona\'s Ring',
        Back = 'Senuna\'s Mantle',
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = 'Samnuha Tights',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+20', [2] = 'Attack+6', [3] = 'AGI+1', [4] = '"Triple Atk."+3' } },
    },
    Tp_Acc = {
        Ammo = 'Yamarang',
        Head = 'Malignance Chapeau',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Telos Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },

    Precast = {
        Ammo = 'Staunch Tathlum',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Loquac. Earring',
        Ear2 = 'Etiolation Earring',
        Hands = 'Leyline Gloves',
        Ring2 = 'Prolix Ring',
    },
    Midcast = {},
    Preshot = {},
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },
    Waltz = { -- every waltz
        Ammo = 'Yamarang',
    },

    Ws_Default = {
        Ammo = 'Voluspa Tathlum',
        Head = { Name = 'Adhemar Bonnet +1', AugPath='B' },
        Neck = 'Fotia Gorget',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Nyame Mail',
        Hands = 'Meg. Gloves +2',
        Ring1 = 'Beithir Ring',
        Ring2 = 'Karieyh Ring +1',
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },
    Evisceration = {
        Head = 'Adhemar Bonnet +1',
        Neck = 'Fotia Gorget',
        Ear1 = 'Odr Earring',
        Ear2 = 'Sherida Earring',
        Body = 'Meg. Cuirie +2',
        Hands = 'Mummu Wrists +2',
        Ring1 = 'Gere Ring',
        Ring2 = 'Ilabrat Ring',
        Waist = 'Fotia Belt',
        Legs = 'Mummu Kecks +2',
        Feet = 'Gleti\'s Boots',
    },
    ['Rudra\'s Storm'] = {
        Head = 'Blistering Sallet +1',
        Neck = 'Sanctity Necklace',
        Body = 'Meg. Cuirie +2',
        Hands = 'Meg. Gloves +2',
        Ring1 = 'Beithir Ring',
        Ring2 = 'Karieyh Ring +1',
        Waist = 'Sailfi Belt +1',
        Legs = 'Mummu Kecks +2',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },
    ['Pyrrhic Kleos'] = {
        Ammo = 'Coiste Bodhar',
        Head = 'Adhemar Bonnet +1',
        Neck = 'Fotia Gorget',
        Body = 'Herculean Vest',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Gere Ring',
        Ring2 = 'Epona\'s Ring',
        Waist = 'Fotia Belt',
        Legs = 'Samnuha Tights',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+20', [2] = 'Attack+6', [3] = 'AGI+1', [4] = '"Triple Atk."+3' } },
    },
    ['Aeolian Edge'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shiva Ring +1',
        Ring2 = 'Karieyh Ring +1',
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    ['Climactic Flourish'] = {
        -- on JA and while buff is active
        Head = 'Maculele Tiara +1',
    },
    ['Striking Flourish'] = {
        -- on JA and while buff is active
        Body = 'Macu. Casaque +1',
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
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None'}; -- e.g. {'None', 'Example'} with a Weapon_Example set
    gcinclude.DefaultWeapons = 'None';
    gcinclude.settings.RefreshGearMPP = 0; -- no auto Idle_Refresh on this job; /autogear refresh 60 (or set it here) to turn it on
    -- Rules (/gcedit, RULES): when this, wear that, as data.
    gcinclude.Rules = {
        { on = 'Default', when = { buff = 'Climactic Flourish' }, wear = 'Climactic Flourish', exact = true },
        { on = 'Default', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Default', when = { toggle = { kite = true } }, wear = 'Movement', exact = true },
        { on = 'Weaponskill', when = { buff = 'Striking Flourish' }, wear = 'Striking Flourish', exact = true },
        { on = 'Weaponskill', when = { buff = 'Climactic Flourish' }, wear = 'Climactic Flourish', exact = true },
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
    gcinclude.CheckDefault();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    for _, kind in ipairs({'Waltz', 'Step', 'Samba', 'Jig', 'Flourish'}) do -- ['Step'] on every step, then ['Box Step']
        if string.find(ability.Name, kind, 1, true) then ByName(kind) end
    end
    ByName(ability.Name);
    gcinclude.CheckCancels();
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
end

return profile;
