local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
gcinclude.settings.WeaponTPGuard = 0; -- rolls, Quick Draw and JAs always get their weapons: worth the TP

local sets = {
    Idle = {
        --Main = { Name = 'Rostam', AugPath='B'},
        --Sub = { Name = 'Rostam', AugPath='C'},
        --Range = 'Death Penalty',
        Ammo = 'Living Bullet',
        Head = 'Malignance Chapeau',
        Neck = 'Rep. Plat. Medal',
        Ear1 = 'Eabani Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adamantite Armor',
        Hands = 'Malignance Gloves',
        Ring1 = 'Murky Ring',
        Ring2 = 'Defending Ring',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Weapon_Naegling = { -- /wm: the melee pair; the gun is /rw (RangeModes)
        Main = 'Naegling',
        Sub = 'Gleti\'s Knife',
    },
    Weapon_Naegling_1h = { -- can't dual wield
        Main = 'Naegling',
        Sub = 'Nusku Shield',
    },
    Weapon_Rostam = {
        Main = { Name = 'Rostam', AugPath='B'},
        Sub = 'Gleti\'s Knife',
    },
    Weapon_Rostam_1h = {
        Main = { Name = 'Rostam', AugPath='B'},
        Sub = 'Nusku Shield',
    },
    Resting = {},
    Idle_Regen = {
        Head = 'Meghanada Visor +2',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Infused Earring',
        Body = 'Meg. Cuirie +2',
        Ring1 = 'Chirich Ring +1',
        Legs = 'Meg. Chausses +2',
        Feet = 'Meg. Jam. +2',
    },
    Idle_Refresh = {
        Ring2 = 'Stikini Ring +1',
    },
    Town = {
        Sub = 'Leafkin Shield',
        Range = 'Death Penalty',
        Ammo = 'Living Bullet',
        Head = 'Laksa. Tricorne +4',
        Neck = 'Rep. Plat. Medal',
        Body = 'Adamantite Armor',
        Hands = 'Lanun Gants +4',
        Ring1 = 'Shneddick Ring',
        Ring2 = 'Stikini Ring +1',
        Waist = 'K. Kachina Belt +1',
        Legs = 'Osh. Trousers +1',
        Feet = 'Lanun Bottes +4',
    },
    Dt = {
        Head = 'Nyame Helm',
        Neck = 'Null Loop',
        Ear1 = 'Eabani Earring',
        Ear2 = 'Alabaster Earring',
        Body = 'Adamantite Armor',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Murky Ring',
        Ring2 = 'Defending Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'HP+60', [3] = '"Snapshot"+10', [4] = 'Mag. Evasion+20', [5] = 'Evasion+20' } },
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Tp_Default = {
        Main = { Name = 'Rostam', AugPath='B'},
        Sub = 'Gleti\'s Knife',
        Range = 'Death Penalty',
        Ammo = 'Chrono Bullet',
        Head = 'Malignance Chapeau',
        Neck = 'Iskur Gorget',
        Ear1 = 'Telos Earring',
        Ear2 = 'Suppanomimi',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Epona\'s Ring',
        Back = 'Null Shawl',
        Waist = 'Sailfi Belt +1',
        Legs = 'Chas. Culottes +3',
        Feet = 'Malignance Boots',
    },
    Tp_Acc = {
        Ring1 = 'Petrov Ring',
    },
    Midcast = {},

    Precast = {
        --Neck = 'Baetyl Pendant',
        Ear1 = 'Loquac. Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adhemar Jacket',
        Hands = 'Leyline Gloves',
        Ring1 = 'Prolix Ring',
        Feet = 'Carmine Greaves +1',--8
    },

    ['Healing Magic'] = {
        Neck = 'Incanter\'s Torque',
        Ear2 = 'Mendi. Earring',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Solemnity Cape',
        Legs = 'Carmine Cuisses +1',
    },

    ['Enhancing Magic'] = {
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Ring1 = 'Metamor. Ring +1',
    },

    ['Enfeebling Magic'] = {
        Neck = 'Erra Pendant',
        Ring1 = 'Metamor. Ring +1',
    },

    Drain = {
        Neck = 'Erra Pendant',
        Ring1 = 'Metamor. Ring +1',
    },

    Aspir = {
        Neck = 'Erra Pendant',
        Ring1 = 'Metamor. Ring +1',
    },

    ['Elemental Magic'] = {
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Preshot = {--base preshot, no flurry, 70cap, 10 from gifts (only 1200 JP needed)
        Ammo = 'Chrono Bullet',
        Head = 'Ikenga\'s Hat',
        Neck = 'Comm. Charm +2',
        Body = 'Laksa. Frac +4',
        Hands = 'Carmine Fin. Ga. +1',--13
        Ring1 = 'Crepuscular Ring',--3
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'HP+60', [3] = '"Snapshot"+10', [4] = 'Mag. Evasion+20', [5] = 'Evasion+20' } },
        Waist = 'Impulse Belt',--3
        Legs = 'Osh. Trousers +1',--8
        Feet = 'Meg. Jam. +2',--10
    },
    Preshot_FlurryI = {--with flurry I on, gives 15
    },
    Preshot_FlurryII = {--with flurry II on, gives 30
        Hands = 'Carmine Fin. Ga. +1',--8
    },
    Midshot = {
        Ammo = 'Chrono Bullet',
        Head = 'Ikenga\'s Hat',
        Neck = 'Iskur Gorget',
        Ear1 = 'Telos Earring',
        Ear2 = 'Enervating Earring',
        Body = 'Ikenga\'s Vest',
        Hands = 'Ikenga\'s Gloves',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Rng.Acc.+20', [3] = 'AGI+30', [4] = '"Store TP"+10', [5] = 'Rng.Atk.+20' } },
        Waist = 'Yemaya Belt',
        Legs = 'Chas. Culottes +3',
        Feet = 'Ikenga\'s Clogs',
    },
    Midshot_Acc = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
        Body = 'Laksa. Frac +4',
        Ring1 = 'Crepuscular Ring',
        Legs = 'Ikenga\'s Trousers',
    },
    TripleShot = {
        Ammo = 'Chrono Bullet',
        --Head = 'Oshosi Mask +1',
        Body = 'Chasseur\'s Frac +3',
        Hands = 'Lanun Gants +4',
        Legs = 'Osh. Trousers +1',
        --feet = 'Osh. Leggings +1',
    },

    Ws_Default = {
        Head = 'Nyame Helm',
        Neck = 'Fotia Gorget',
        Body = 'Nyame Mail',
        Hands = 'Chasseur\'s Gants +3',
        Ring1 = 'Regal Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },

    ['Savage Blade'] = {
        Head = 'Nyame Helm',
        Neck = 'Rep. Plat. Medal',
        Ear2 = 'Ishvara Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Sroda Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },

    Evisceration = {
        Head = 'Adhemar Bonnet +1',
        Neck = 'Fotia Gorget',
        Ear2 = 'Odr Earring',
        Ear1 = 'Mache Earring +1',
        -- Body = 'Mummu Jacket +2',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Ilabrat Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = '"Store TP"+10', [5] = 'DEX+20' } },
        Waist = 'Fotia Belt',
        -- Legs = 'Mummu Kecks +2',
        -- Feet = 'Mummu Gamash. +2',
    },

    ['Aeolian Edge'] = {
        Ammo = 'Hauksbok Bullet',
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear2 = 'Friomisi Earring',
        Ear1 = 'Crematio Earring',
        Body = 'Lanun Frac +4',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },

    ['Last Stand'] = {
        Ammo = 'Chrono Bullet',
        Head = 'Lanun Tricorne +4',
        Neck = 'Iskur Gorget',
        Ear2 = 'Ishvara Earring',
        Body = 'Laksa. Frac +4',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },
    ['Last Stand_Acc'] = {
    Neck = 'Null Loop',
    },

    Wildfire = {
        Ammo = 'Living Bullet',
        Head = 'Nyame Helm',
        Neck = 'Comm. Charm +2',
        Ear2 = 'Friomisi Earring',
        Body = 'Lanun Frac +4',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },
    ['Hot Shot'] = {
        Ammo = 'Living Bullet',
        Head = 'Nyame Helm',
        Neck = 'Fotia Gorget',
        Ear2 = 'Friomisi Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },

    ['Leaden Salute'] = {
        Ammo = 'Living Bullet',
        Head = 'Pixie Hairpin +1',
        Neck = 'Comm. Charm +2',
        Ear2 = 'Friomisi Earring',
        Body = 'Lanun Frac +4',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Archon Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Svelt. Gouriz +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },

    ['Quick Draw'] = {
        Ammo = 'Hauksbok Bullet',
        Head = 'Ikenga\'s Hat',
        Neck = 'Comm. Charm +2',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Lanun Frac +4',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Chass. Bottes +3',
    },
    ['Quick Draw_Acc'] = {--with AF 2/3 and regal is better
        Ammo = 'Animikii Bullet',
        Head = 'Laksa. Tricorne +4',
        Neck = 'Comm. Charm +2',
        Ear1 = 'Gwati Earring',
        Ear2 = 'Digni. Earring',
        Body = 'Ikenga\'s Vest',
        Hands = 'Malignance Gloves',
        Ring1 = 'Regal Ring',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'K. Kachina Belt +1',
        Legs = 'Ikenga\'s Trousers',
        Feet = 'Laksa. Bottes +2',
    },
    ['Double-Up'] = { -- layered on the DT set; roll+ gear set on the initial roll carries over, Luzaf keeps the 16' range
        Ring1 = 'Luzaf\'s Ring',
    },
    ['Phantom Roll'] = { -- it will put on ur DT gear set first then layer this set on for phantom roll (not dbl up), use /dt if you think you need to lock dt set while rolling
        Main = { Name = 'Rostam', AugPath='C'},
        Range = 'Compensator',
        Head = 'Lanun Tricorne +4',
        Neck = 'Regal Necklace',
        Hands = 'Chasseur\'s Gants +3',
        Ring1 = 'Luzaf\'s Ring',
        Ring2 = 'Defending Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'HP+60', [3] = '"Snapshot"+10', [4] = 'Mag. Evasion+20', [5] = 'Evasion+20' } },
        Legs = 'Desultor Tassets',
    },

    ['Bolter\'s Roll'] = { -- it will put on ur DT gear set first then layer this set on for phantom roll (not dbl up), use /dt if you think you need to lock dt set while rolling
        Main = { Name = 'Rostam', AugPath='C' },
        Neck = 'Null Loop',
        Ring1 = 'Luzaf\'s Ring',
        Ring2 = 'Defending Ring',
        Back = 'Null Shawl',
    },

    Fold = {Hands = 'Lanun Gants +4'},
    ['Wild Card'] = {Feet = 'Lanun Bottes +4'},
    ['Random Deal'] = {Body = 'Lanun Frac +4'},
    ['Snake Eye'] = {Legs = 'Lanun Trews +2'},

    TH = {
        Head = { Name = 'Herculean Helm', Augment = { [1] = 'Accuracy+30', [2] = 'Attack+18', [3] = '"Fast Cast"+3', [4] = '"Treasure Hunter"+2' } },
        Waist = 'Chaac Belt',
    },
    Movement = {
        Head = 'Nyame Helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Eabani Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shneddick Ring',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
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
    { Name = 'Trump Card', Quantity = 99 },
    'Trump Card Case',
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.SafeAmmo = 'Chrono Bullet';
    gcinclude.WeaponModes = {'None', 'Naegling', 'Rostam'}; -- /wm: melee pair
    gcinclude.RangeModes = {'None', 'Anarchy +2', 'Death Penalty', 'Fomalhaut', 'Armageddon'}; -- /rw: the gun (/rw dp)
    gcinclude.MainModes = {'None', 'RostamA', 'RostamC'}; -- /mw: Naegling and Rostam (B) are picks already (Weapon_ sets)
    gcinclude.SubModes = {'None', 'Tauret'};
    gcinclude.WeaponItemMap = {
        RostamA = { Name = 'Rostam', AugPath = 'A' },
        RostamC = { Name = 'Rostam', AugPath = 'C' },
    };
    gcinclude.DefaultWeapons = { Weapons = 'Naegling', Range = 'Anarchy +2' }; -- /wm default puts both back
    gcinclude.settings.RefreshGearMPP = 0; -- no auto Idle_Refresh on this job; /autogear refresh 60 (or set it here) to turn it on
    -- Rules (/gcedit, RULES): when this, wear that, as data. A rule with at = goes on where gcinclude.RulesAt(...) is in the handlers below.
    gcinclude.Rules = {
        { on = 'Default', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Default', when = { toggle = { kite = true } }, wear = 'Movement', exact = true },
        { on = 'Ability', at = 'Ability 1', when = { type = 'Quick Draw' }, wear = 'Quick Draw' },
        { on = 'Ability', at = 'Ability 1', when = { name = { 'Dark Shot', 'Light Shot' }, type = 'Quick Draw' }, wear = 'Quick Draw_Acc' },
        { on = 'Preshot', at = 'Preshot 1', first = {
            { when = { buff = 581 }, wear = 'Preshot_FlurryII', exact = true },
            { when = { buff = 265 }, wear = 'Preshot_FlurryI', exact = true },
        } },
        { on = 'Midshot', when = { buff = 'Triple Shot' }, wear = 'TripleShot', exact = true },
        { on = 'Midshot', when = { buff = 'Triple Shot', mode = { mset = 'Acc' } }, wear = 'Midshot_Acc', exact = true },
        { on = 'Ability', at = 'Ability 2', when = { any = { { name = { has = 'Roll' } }, { name = 'Double-Up' } } }, wear = 'Dt', exact = true },
        { on = 'Ability', at = 'Ability 2', when = { name = { has = 'Roll', isnt = "Bolter's Roll" } }, wear = 'Phantom Roll' },
    };
    gcinclude.Initialize();

    gcinclude.CORmsg = true; -- set this to false if you do not want to see lucky/unlucky # messages
end

profile.OnUnload = function()
    gcinclude.Unload();
end

profile.HandleCommand = function(args)
    gcinclude.HandleCommands(args);
end

profile.HandleDefault = function()
    gcinclude.EquipIdle(); -- Idle, then Idle_<mode> (/idleset)

    local player = gData.GetPlayer();
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
    local roll = (string.find(ability.Name, 'Roll', 1, true) ~= nil);
    gcinclude.RulesAt('Ability 2');
    if roll then gcinclude.DoCORmsg(ability.Name) end
    gcinclude.RulesAt('Ability 1');
    ByName(ability.Name); -- a set named after the ability, e.g. ['Bolter\'s Roll'], ['Wild Card']
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
    gFunc.EquipSet(sets.Midcast);
    ByName(spell.Skill); -- e.g. ['Enhancing Magic']
    if not ByName(spell.Name) then ByName(Family(spell.Name)) end -- e.g. ['Cure'] for Cure IV
    gcinclude.CheckTH();
end

profile.HandlePreshot = function()
    if (gcinclude.CheckBlockedAmmo() == true) then return end

    gFunc.EquipSet(sets.Preshot);

    gcinclude.RulesAt('Preshot 1');
end

profile.HandleMidshot = function()
    -- Midshot, then the ones made of: Midshot_<wm> (the /wm mode's own), Midshot_Acc on /mset acc,
    -- Midshot_<wm>_Acc
    ByName('Midshot');

    gcinclude.CheckTH();
end

profile.HandleWeaponskill = function()
    if (gcinclude.CheckWsBailout() == false) then gFunc.CancelAction(); return end
    local ws = gData.GetAction();
    if (gcinclude.CheckBlockedAmmoWS(ws.Name) == true) then return end
    gcinclude.EquipMode('Ws');
    ByName(ws.Name); -- e.g. ['Leaden Salute'], then ['Leaden Salute_<mset>']
end

return profile;
