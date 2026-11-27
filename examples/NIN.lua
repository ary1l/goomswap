local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- NIN example: swap in your own gear.
-- Sets named after an ability, spell, skill or weapon skill (['Yonin'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_SubtleBlow' / '<Name>_Acc' for /mset. Empty sets do nothing.
local sets = {

    Idle = {
        Ammo = 'Yamarang',
        Head = 'Malignance Chapeau',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Infused Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Malignance Tabard',
        Hands = 'Macabre Gaunt. +1',
        Ring1 = 'Defending Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Dbl.Atk."+10', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Carrier\'s Sash',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    Idle_Regen = {
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Body = 'Hiza. Haramaki +2',
        Hands = 'Rao Kote',
        Ring2 = 'Chirich Ring +1',
    },
    Resting = {},
    Town = {
        Main = 'Kikoku',
        Sub = 'Tauret',
        Ammo = 'Yamarang',
        Head = 'Mochi. Hatsuburi +3',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Mpaca\'s Gloves',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Dbl.Atk."+10', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Flume Belt +1',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Danzo Sune-Ate',
    },
    Movement = {
        Feet = 'Danzo Sune-Ate',
    },
    Movement_Night = {
        Feet = 'Hachi. Kyahan +1',
    },
    Dt = {
        Ammo = 'Yamarang',
        Head = 'Malignance Chapeau',
        Neck = { Name = 'Loricate Torque +1', AugPath='A' },
        Ear1 = { Name = 'Odnowa Earring +1', AugPath='A' },
        Ear2 = 'Etiolation Earring',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Malignance Gloves',
        Ring1 = 'Defending Ring',
        Ring2 = { Name = 'Gelatinous Ring +1', AugPath='A' },
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Dbl.Atk."+10', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Flume Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    TH = { -- /th: until the target is tagged; Main/Sub/Range here stay on while /th is on
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Potency of "Cure" effect received+5%', [2] = 'Mag. Acc.+19', [3] = 'Accuracy+21', [4] = '"Mag. Atk. Bns."+19', [5] = '"Treasure Hunter"+2' } },
    },

    XIRoll = { -- worn standing idle with a roll at 11
        Ring2 = 'Roller\'s Ring',
    },
    Proc = { -- /proc: low-damage gear for proc windows, worn by the engine while engaged and on WS (Ws_Proc there if you have one)
        -- a set to force low dmg for things like Abyssea
        Ammo = { Name = 'Coiste Bodhar', AugPath='A' },
        Head = 'Rawhide Mask',
        Neck = 'Bathy Choker +1',
        Ear1 = 'Telos Earring',
        Ear2 = 'Cessance Earring',
        Body = 'Emet Harness +1',
        Hands = 'Tatena. Gote +1',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Dbl.Atk."+10', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = { Name = 'Tatena. Haidate +1', AugPath='A' },
        Feet = 'Tatena. Sune. +1',
    },
    Tp_Default = {
        Ammo = 'Date Shuriken',
        Head = { Name = 'Adhemar Bonnet +1', AugPath='B' },
        Neck = { Name = 'Ninja Nodowa +1', AugPath='A' },
        Ear1 = 'Telos Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Hiza. Haramaki +2',
        Hands = { Name = 'Adhemar Wrist. +1', AugPath='B' },
        Ring1 = 'Gere Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Dbl.Atk."+10', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = { Name = 'Tatena. Haidate +1', AugPath='A' },
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+20', [2] = 'Attack+6', [3] = 'AGI+1', [4] = '"Triple Atk."+3' } },
    },
    Tp_Acc = {
        Head = 'Malignance Chapeau',
        Ear1 = 'Telos Earring',
        Ear2 = 'Hattori Earring',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Malignance Gloves',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
        Feet = 'Tatena. Sune. +1',
    },

    Precast = {
        Ammo = 'Sapience Orb',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Loquac. Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Taeon Tabard',
        Hands = 'Leyline Gloves',
        Ring1 = 'Prolix Ring',
        Ring2 = 'Kishar Ring',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Magic Damage +20', [2] = 'Mag. Acc+20', [3] = '"Fast Cast"+10', [4] = 'INT+20' } },
        Waist = 'Audumbla Sash',
        Feet = 'Taeon Boots',
    },
    Midcast = {},
    Preshot = {},
    Midshot = {
        Neck = 'Iskur Gorget',
        Ear1 = 'Telos Earring',
        Ear2 = 'Hattori Earring',
    },
    Precast_Utsusemi = {},
    ['Ninjutsu'] = {
        Ammo = 'Staunch Tathlum',
        Head = 'Mochi. Hatsuburi +3',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Crep. Earring',
        Ear2 = 'Digni. Earring',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Ring1 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Magic Damage +20', [2] = 'Mag. Acc+20', [3] = '"Fast Cast"+10', [4] = 'INT+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Utsusemi'] = { -- all tiers
        Ammo = 'Staunch Tathlum',--sir10
        Head = 'Malignance Chapeau',
        Neck = 'Moonlight Necklace',--sir15
        Body = 'Malignance Tabard',
        Hands = 'Rawhide Gloves',--sir15
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Dbl.Atk."+10', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Audumbla Sash',--sir10
        Legs = 'Nyame Flanchard',
        Feet = 'Hattori Kyahan +1',
    },
    Nuke = {
        -- I only nuke when bursting so ... yeah.
        Ammo = 'Ghastly Tathlum +1',
        Head = 'Mochi. Hatsuburi +3',
        Neck = 'Sibyl Scarf',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Hattori Tekko +1',
        Ring1 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Ring2 = 'Mujin Band',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Magic Damage +20', [2] = 'Mag. Acc+20', [3] = '"Fast Cast"+10', [4] = 'INT+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Hachi. Kyahan +1',
    },
    Nuke_Futae = {
        Hands = 'Hattori Tekko +1',
    },

    Ws_Default = {
        Ammo = 'Coiste Bodhar',
        Head = 'Mpaca\'s Cap',
        Neck = 'Fotia Gorget',
        Ear1 = 'Lugra Earring +1',
        Ear2 = 'Digni. Earring',
        Body = 'Malignance Tabard',
        Hands = { Name = 'Adhemar Wrist. +1', AugPath='B' },
        Ring1 = 'Gere Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'AGI+20', [4] = 'Attack+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Hiza. Hizayoroi +2',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },
    ['Blade: Hi'] = {
        Ammo = 'Voluspa Tathlum',
        Head = 'Adhemar Bonnet +1',
        Neck = { Name = 'Ninja Nodowa +1', AugPath='A' },
        Ear1 = 'Odr Earring',
        Ear2 = 'Lugra Earring +1',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Ryuo Tekko',
        Ring1 = 'Begrudging Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'AGI+20', [4] = 'Attack+20' } },
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    ['Blade: Metsu'] = {
        Ammo = 'Coiste Bodhar',
        Head = 'Nyame Helm',
        Neck = { Name = 'Ninja Nodowa +1', AugPath='A' },
        Ear1 = 'Odr Earring',
        Ear2 = 'Lugra Earring +1',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Gere Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'AGI+20', [4] = 'Attack+20' } },
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = 'Hiza. Hizayoroi +2',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },
    ['Blade: Shun'] = {
        Ammo = 'Coiste Bodhar',
        Head = 'Mpaca\'s Cap',
        Neck = 'Fotia Gorget',
        Ear1 = 'Lugra Earring +1',
        Ear2 = 'Hattori Earring',
        Body = 'Malignance Tabard',
        Hands = { Name = 'Adhemar Wrist. +1', AugPath='B' },
        Ring1 = 'Gere Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Dbl.Atk."+10', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Mpaca\'s Hose',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },
    ['Blade: Chi'] = {
        Ammo = 'Seeth. Bomblet +1',
        Head = 'Mochi. Hatsuburi +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Lugra Earring +1',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Gere Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'AGI+20', [4] = 'Attack+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },
    ['Blade: Teki'] = {
        Ammo = 'Seeth. Bomblet +1',
        Head = 'Mochi. Hatsuburi +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Lugra Earring +1',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Gere Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'AGI+20', [4] = 'Attack+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },
    ['Blade: To'] = {
        Ammo = 'Seeth. Bomblet +1',
        Head = 'Mochi. Hatsuburi +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Lugra Earring +1',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Gere Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'AGI+20', [4] = 'Attack+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+30', [2] = 'Weapon skill damage +8%', [3] = 'Attack+6', [4] = 'Mag. Acc.+2' } },
    },

    ['Yonin'] = {
        Legs = 'Hattori Hakama +1',
    },
    ['Innin'] = {
        Head = 'Hattori Zukin +1',
    },
    ['Mijin Gakure'] = {
        Legs = 'Mochi. Hakama +3',
    },
    Provoke = {
        Ammo = 'Date Shuriken',
        Head = 'Mpaca\'s Cap',
        Neck = 'Moonlight Necklace',
        Ear1 = { Name = 'Odnowa Earring +1', AugPath='A' },
        Ear2 = 'Etiolation Earring',
        Body = 'Hiza. Haramaki +2',
        Hands = 'Macabre Gaunt. +1',
        Ring1 = 'Eihwaz Ring',
        Ring2 = 'Supershear Ring',
        Back = { Name = 'Andartia\'s Mantle', Augment = { [1] = 'Damage taken-5%', [2] = '"Dbl.Atk."+10', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+20' } },
        Waist = 'Flume Belt +1',
        Feet = 'Danzo Sune-Ate',
    },
    Buffs = { -- worn while that buff is up (engine layer)
        Migawari = {
            Body = 'Hattori Ningi +1',
        },
    },
    -- Templates: fill the ones you use; an empty set changes nothing.
    Buffs_Ws = { -- while the buff is up: weapon skills
        ['Aftermath: Lv.3'] = {},
    },
};
profile.Sets = sets;

-- Kept in your bags for this job by /lac gear (the Packer plugin), with every set's gear; /gcedit Settings edits it.
profile.Packer = {
    {Name = 'Toolbag (Ino)', Quantity = 'all'},
    {Name = 'Toolbag (Shika)', Quantity = 'all'},
    {Name = 'Toolbag (Cho)', Quantity = 'all'},
    {Name = 'Toolbag (Shihe)', Quantity = 'all'},
    {Name = 'Shihei', Quantity = 'all'},
    {Name = 'Inoshishinofuda', Quantity = 'all'},
    {Name = 'Chonofuda', Quantity = 'all'},
    {Name = 'Shikanofuda', Quantity = 'all'},
    {Name = 'Forbidden Key', Quantity = 'all'},
    {Name = 'Date Shuriken', Quantity = 'all'}
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;
local NinNukes = T{'Katon', 'Hyoton', 'Huton', 'Doton', 'Raiton', 'Suiton'}; -- elemental ninjutsu
local function Night() -- dusk to dawn, 17:00-07:00 (Hachiya Kyahan movement speed)
    local t = gData.GetEnvironment().Time;
    return (t >= 17) or (t < 7);
end

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None'}; -- e.g. {'None', 'Example'} with a Weapon_Example set
    gcinclude.DefaultWeapons = 'None';
    gcinclude.settings.RefreshGearMPP = 0; -- no auto Idle_Refresh on this job; /autogear refresh 60 (or set it here) to turn it on
    -- Rules (/gcedit, RULES): when this, wear that, as data. A rule with at = goes on where gcinclude.RulesAt(...) is in the handlers below.
    gcinclude.Rules = {
        { on = 'Default', at = 'Default 1', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Precast', when = { family = 'Utsusemi' }, wear = 'Precast_Utsusemi', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { family = { 'Katon', 'Hyoton', 'Huton', 'Doton', 'Raiton', 'Suiton' } }, wear = 'Nuke', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { buff = 'Futae', family = { 'Katon', 'Hyoton', 'Huton', 'Doton', 'Raiton', 'Suiton' } }, wear = 'Nuke_Futae', exact = true },
        { on = 'Default', when = { any = { { time = { ge = 17 } }, { time = { lt = 7 } } }, toggle = { kite = true } }, wear = 'Movement_Night', exact = true },
        { on = 'Default', when = { time = { ge = 7, lt = 17 }, toggle = { kite = true } }, wear = 'Movement', exact = true },
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
        if (gcinclude.BuffCount('Yonin') > 0) then gFunc.EquipSet(sets.Yonin)
        elseif (gcinclude.BuffCount('Innin') > 0) then gFunc.EquipSet(sets.Innin) end
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
        gFunc.EquipSet(Night() and sets.Movement_Night or sets.Movement);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    gcinclude.RulesAt('Default 1');
    gcinclude.CheckDefault();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
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
    gcinclude.RulesAt('Midcast 1');
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
