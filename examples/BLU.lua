local profile = {};
if (gFunc == nil) then error('GoomSwap: GearSwap loaded this job file directly. Windower: move it to data/goomswap/<Name>/<JOB>.lua and delete it from data/<Name>/ (see docs/windower.md)', 0) end
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
-- gcinclude.Food = {'Grape Daifuku +1'}; -- this job's food: /packer keeps a stack of each (replaces the Food setting / char.lua's)
-- gcinclude.Packer = { ['Echo Drops'] = 'stack', ['Holy Water'] = 'stack' }; -- kept in inventory on job change (/packer, Bellhop plugin)


local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adamantite Armor',
        Hands = 'Hashi. Bazu. +3',
        Ring1 = 'Murky Ring',
        Ring2 = 'Shadow Ring',
        Back = 'Shadow Mantle',
        Waist = 'Carrier\'s Sash',
        Legs = 'Hashishin Tayt +3',
        Feet = 'Nyame Sollerets',
    },
    Resting = {
        Body = 'Hashishin Mintan +3',
        Waist = 'Fucho-no-Obi',
    },
    Idle_Regen = {
        Neck = 'Sanctity Necklace',
        --Ear1 = 'Infused Earring',
        Ring1 = 'Chirich Ring +1',
        Waist = 'Null Belt',
    },
    Idle_Refresh = {
        --Head = 'Rawhide Mask',
        Body = 'Hashishin Mintan +3',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Waist = 'Fucho-no-Obi',
    },
    Idle_Regain = { -- /idleset regain: over Idle while idle
    },
    ['Town'] = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adamantite Armor',
        Hands = 'Assim. Bazu. +4',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Shadow Mantle',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Evasion = {--worn by /kite
        Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Adamantite Armor',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Murky Ring',
        Ring2 = 'Shadow Ring',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Dt = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Hearty Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Adamantite Armor',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Null Shawl',
        Waist = 'Carrier\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    SIR = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adamantite Armor',
        Hands = 'Hashi. Bazu. +3',
        Ring1 = 'Murky Ring',
        Ring2 = 'Shadow Ring',
        Back = 'Shadow Mantle',
        Waist = 'Carrier\'s Sash',
        Legs = 'Hashishin Tayt +3',
        Feet = 'Nyame Sollerets',
    },

    Weapon_Tizona = {
        Main = 'Tizona',
        Sub = 'Thibron',
    },
    Weapon_Tizona_1h = {
        Main = 'Tizona',
        Sub = 'Genmei Shield',
    },
    Weapon_Caliburnus = { -- /wm cali
        Main = 'Caliburnus',
        Sub = 'Thibron',
    },
    Weapon_Caliburnus_1h = {
        Main = 'Caliburnus',
        Sub = 'Genmei Shield',
    },
    Tp_Default = {
        --sub = 'thibron',
        Ammo = 'Coiste Bodhar',
        Head = 'Malignance Chapeau',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Telos Earring',
        Ear2 = 'Suppanomimi',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Epona\'s Ring',
        Back = 'Null Shawl',
        Waist = 'Sailfi Belt +1',
        Legs = 'Malignance Tights',
        Feet = 'Malignance Boots',
    },
    Tp_SubtleBlow = { -- /mset subtleblow: Subtle Blow pieces over Tp_Default
        Body = 'Volte Harness', -- Subtle Blow+10
    },
    Tp_Acc = {
        },
    Midcast = {},

    Precast = {--64
        Ammo = 'Sapience Orb',--2
        Head = 'Carmine Mask +1', --14
        Neck = 'Voltsurge Torque',--4
        Ear1 = 'Loquac. Earring', --2
        Ear2 = 'Etiolation Earring',--1
        Body = 'Pinga Tunic +1',--13
        Hands = 'Leyline Gloves',--6
        Ring1 = 'Prolix Ring',--2
        Ring2 = 'Kishar Ring',--4
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Mag. Evasion+20', [3] = 'AGI+20', [4] = 'Evasion+45' } },
        Waist = 'Witful Belt',
        Legs = 'Pinga Pants +1',--11
        Feet = 'Carmine Greaves +1',--7
    },
    ['Blue Magic_Precast'] = {
        Ammo = 'Sapience Orb',--2
        Head = 'Carmine Mask +1',--14
        Neck = 'Voltsurge Torque',--4
        Ear1 = 'Loquac. Earring',--2
        Ear2 = 'Etiolation Earring',--1
        Body = 'Hashishin Mintan +3',
        Hands = 'Leyline Gloves',--6
        Ring1 = 'Prolix Ring',--2
        Ring2 = 'Kishar Ring',--4
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Mag. Evasion+20', [3] = 'AGI+20', [4] = 'Evasion+45' } },
        Waist = 'Witful Belt',
        Legs = 'Pinga Pants +1',--11
        Feet = 'Carmine Greaves +1',--7
    },
    Stoneskin_Precast = {
        Ammo = 'Sapience Orb',--2
        Head = 'Carmine Mask +1',--14
        Neck = 'Voltsurge Torque',--4
        Ear1 = 'Loquac. Earring',--2
        Ear2 = 'Etiolation Earring',--1
        Body = 'Hashishin Mintan +3',
        Hands = 'Leyline Gloves',--6
        Ring1 = 'Prolix Ring',--2
        Ring2 = 'Kishar Ring',--4
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = '"Fast Cast"+10', [2] = 'Mag. Evasion+20', [3] = 'AGI+20', [4] = 'Evasion+45' } },
        Waist = 'Siegel Sash',
        Legs = 'Pinga Pants +1',--11
        Feet = 'Carmine Greaves +1',--7
    },

    Cure = {--I cap is 50, II cap is 30
        Ammo = 'Staunch Tathlum +1',
        --Head = 'Pinga Crown',--8
        Neck = 'Loricate Torque +1',
        Ear1 = 'Mendi. Earring',--5
        Ear2 = 'Etiolation Earring',
        Body = 'Pinga Tunic +1',--13
        Hands = 'Pinga Mittens',--16
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Solemnity Cape',--7
        Waist = 'Gishdubar Sash',
        Legs = 'Pinga Pants +1',--11
        Feet = 'Medium\'s Sabots',--10 atm
    },
    ['White Wind'] = {--HP+ go!
        --sub = 'sakpata\'s sword',
        Ammo = 'Egoist\'s Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Unmoving Collar +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Tuisto Earring',
        Body = 'Pinga Tunic +1',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Gelatinous Ring +1',
        Ring2 = 'Meridian Ring',
        Back = 'Moonbeam Cape',
        Waist = 'Plat. Mog. Belt',
        Legs = 'Pinga Pants +1',
        Feet = 'Carmine Greaves +1',
    },
    BluSkill = {
        Ear1 = 'Njordr Earring',
        Ear2 = 'Hashi. Earring +1',
        Body = 'Assim. Jubbah +4',
        Back = 'Cornflower Cape',
        Legs = 'Hashishin Tayt +3',
    },
    BluMagical = {
        Ammo = 'Ghastly Tathlum',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Regal Earring',
        Ear2 = 'Hashi. Earring +1',
        Body = 'Hashishin Mintan +3',
        Hands = 'Hashi. Bazu. +3',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Mag. Acc+20', [3] = 'Magic Damage+20', [4] = 'INT+30' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Hashishin Tayt +3',
        Feet = 'Hashi. Basmak +3',
    },
    BluDark = {
        Head = 'Pixie Hairpin +1',
        Ring2 = 'Archon Ring',
    },
    BluMagicAccuracy = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Regal Earring',
        Ear2 = 'Hashi. Earring +1',
        Body = 'Assim. Jubbah +4',
        Hands = 'Hashi. Bazu. +3',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'Hashishin Tayt +3',
        Feet = 'Hashi. Basmak +3',
    },
    BluStun = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Malignance Chapeau',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Digni. Earring',
        Ear2 = 'Hashi. Earring +1',
        Body = 'Hashishin Mintan +3',
        Hands = 'Hashi. Bazu. +3',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Mag. Acc+20', [3] = 'Magic Damage+20', [4] = 'INT+30' } },
        Waist = 'Yamabuki-no-Obi',
        Legs = 'Hashishin Tayt +3',
        Feet = 'Hashi. Basmak +3',
    },
    BluPhysical = {
        Ammo = 'Coiste Bodhar',
        Head = 'Nyame Helm',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Regal Earring',
        Ear2 = 'Hashi. Earring +1',
        Body = 'Malignance Tabard',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = 'STR+30', [2] = 'Accuracy+20', [3] = 'Attack+20', [4] = 'Weapon skill damage +10%', [5] = 'Phys. dmg. taken -10%' } },
        Waist = 'Prosilio Belt +1',
        Legs = 'Jhakri Slops +2',
        Feet = 'Gleti\'s Boots',
    },
    CMP = {
        Ammo = 'Pemphredo Tathlum',
        --Head = 'Ipoca Beret',--in storage probably
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Mendi. Earring',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Kishar Ring',
        Back = 'Solemnity Cape',
        Waist = 'Hachirin-no-Obi',
        --Legs = 'Augury Cuisses +1',--in storage probably
        Feet = 'Amalric Nails +1',
    },

    Preshot = {
        Range = 'Aliyat Chakram',
        Ammo = 'displaced',
    },
    Midshot = {
        Range = 'Aliyat Chakram',
        Ammo = 'displaced',
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },

    Ws_Default = {
        Ammo = 'Coiste Bodhar',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Telos Earring',
        Ear2 = 'Digni. Earring',
        Body = 'Assim. Jubbah +4',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Ws_Acc = {
    },
    ['Chant du Cygne'] = {
        Ammo = 'Jukukik Feather',
        Head = 'Adhemar Bonnet +1',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Telos Earring',
        Ear2 = 'Digni. Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Begrudging Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = '"Dbl.Atk."+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'DEX+30' } },
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    ['Chant du Cygne_Acc'] = {
    },
    ['Savage Blade'] = {
        Ammo = 'Coiste Bodhar',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Alabaster Earring',
        Body = 'Assim. Jubbah +4',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Savage Blade_Acc'] = {
    },
    Imperator = {
        Ammo = 'Coiste Bodhar',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Alabaster Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Kentarch Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Imperator_Acc = {
    },
    Expiacion = {
        Ammo = 'Crepuscular Pebble',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Alabaster Earring',
        Body = 'Assim. Jubbah +4',
        Hands = 'Gleti\'s Gauntlets',
        Ring1 = 'Sroda Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Expiacion_Acc = {
    },
    Expiacion_SubtleBlow = { -- /mset subtleblow: Subtle Blow pieces over Expiacion_Default (any WS: <its set>_SubtleBlow)
    },
    Requiescat = {
        Head = 'Hashishin Kavuk +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Brutal Earring',
        Body = 'Hashishin Mintan +3',
        Hands = 'Nyame Gauntlets',
        --Ring1 = 'archon ring',
        Ring1 = 'Metamor. Ring +1',
        Waist = 'Fotia Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Jhakri Pigaches +2',
    },
    Requiescat_Acc = {
    },
    ['Sanguine Blade'] = {
        Ammo = 'Ghastly Tathlum',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Sibyl Scarf',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Nyame Mail',
        Hands = 'Jhakri Cuffs +2',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Archon Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Mag. Acc+20', [3] = 'Magic Damage+20', [4] = 'INT+30' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Hashi. Basmak +3',
    },
    ['Sanguine Blade_Acc'] = {},
    Ca = {
        Head = 'Hashishin Kavuk +3',
        Feet = 'Hashi. Basmak +3',
        --Feet = 'Assim. Charuqs +1',
    },
    Ba = {
        Feet = 'Hashi. Basmak +3',
    },
    Diffusion = {
        Feet = 'Luhlaza Charuqs',
    },
    Efflux = {
        Legs = 'Hashishin Tayt +3',
    },

    Enmity = {
        Neck = 'Unmoving Collar +1',
        Ear2 = 'Cryptic Earring',
        Ring1 = 'Eihwaz Ring',
    },

    -- Hoxne: /hoxne Locked + Enchantment up (Double Attack +100%). Per slot, later wins; leave a slot out to keep the one under.
    -- Idle/TP: job sets (Tp, buff sets, Dt) -> Hoxne_Tp|Idle|Dt -> its _SubtleBlow/_Acc -> its _<buff> combos -> engine layers.
    -- WS: job WS sets -> Hoxne_Ws -> Hoxne_<ws> -> Hoxne_Ws_<buff> -> Hoxne_<ws>_<buff> -> Buffs_Ws, Moonshade, obi.
    -- Combos: <set>_<buff>, <set>_<buff>&<buff> (all up); fewest buffs first, then A-Z. Full order: docs/sets.md (How sets stack).
    Hoxne_Tp = {},
    Hoxne_Idle = {},
    Hoxne_Dt = {}, -- instead of Hoxne_Tp/Hoxne_Idle while /dt is on
    Hoxne_Ws = {}, -- every WS
    ['Hoxne_Savage Blade'] = {}, -- that WS, over Hoxne_Ws

    TH = {
        Head = { Name = 'Herculean Helm', Augment = { [1] = 'Accuracy+30', [2] = 'Attack+18', [3] = '"Fast Cast"+3', [4] = '"Treasure Hunter"+2' } },
        Waist = 'Chaac Belt',
    },
    Salvage = {
        Main = 'Tizona',
        Sub = 'Bunzi\'s Rod',
    },
    Movement = {
        Ring1 = 'Shneddick Ring',
    },
    -- Templates: fill the ones you use; an empty set changes nothing.
    Proc = {}, -- /proc: low-damage gear for proc windows (Abyssea, Vagary...), over the engaged sets
    Ws_Proc = {}, -- /proc on weapon skills (empty: Proc)
    Ws_HighBuff = {}, -- /wsset high: over Ws_Default (PDL)
    Expiacion_HighBuff = {}, -- /wsset high: this WS
    ['Azure Lore'] = {}, -- a job ability: worn as it goes off (ByName)
    Buffs = { -- while the buff is up: idle and engaged
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Ws = { -- while the buff is up: weapon skills
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Midcast = { -- while the buff is up: spells (e.g. ['Saboteur'])
    },
    -- Weapon_Tizona_Acc = { Main = 'Item Name' }, -- /mset acc: a whole weapon set in place of Weapon_Tizona
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
    gcinclude.AlwaysDualWield = true;
    gcinclude.WeaponModes = {'None', 'Tizona', 'Caliburnus'};
    gcinclude.DefaultWeapons = 'Tizona';
    gcinclude.SubModes = {'None', 'Bunzi\'s Rod'}; -- /subset bunzi: nuke offhand (Tizona stays), /subset none: back to the mode's Thibron. A Sub swap resets TP
    gcinclude.Initialize();

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
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end;
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Evasion) end;
    --lazy equip weapons for salvage runs
    local area = AshitaCore:GetResourceManager():GetString('zones.names', AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0));
    if (area ~= nil) and area:contains('Remnants') then
        gFunc.EquipSet(sets.Salvage);
    end
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    if (ability.Name == 'Provoke') then gFunc.EquipSet(sets.Enmity) end
    ByName(ability.Name); -- a set named after the ability, e.g. ['Azure Lore']
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
    local diff = gcinclude.BuffCount('Diffusion');
    local ca = gcinclude.BuffCount('Chain Affinity');
    local ba = gcinclude.BuffCount('Burst Affinity');
    local ef = gcinclude.BuffCount('Efflux');
    local spell = gData.GetAction();

    gFunc.EquipSet(sets.Midcast);
    if (spell.Skill == 'Blue Magic') then gFunc.EquipSet(gcinclude.BluMagPhysical:contains(spell.Name) and sets.BluPhysical or sets.BluMagical) end -- non-blue spells (Utsusemi etc.) keep precast gear
    if (gcinclude.BluMagDebuff:contains(spell.Name)) then gFunc.EquipSet(sets.BluMagicAccuracy)
    elseif (gcinclude.BluMagStun:contains(spell.Name)) then gFunc.EquipSet(sets.BluStun);
    elseif (gcinclude.BluMagBuff:contains(spell.Name)) then gFunc.EquipSet(sets.CMP);
    elseif (gcinclude.BluMagSkill:contains(spell.Name)) then gFunc.EquipSet(sets.BluSkill);
    elseif (gcinclude.BluMagCure:contains(spell.Name)) then gFunc.EquipSet(sets.Cure);
    elseif (gcinclude.BluMagEnmity:contains(spell.Name)) then gFunc.EquipSet(sets.Enmity);
    elseif string.match(spell.Name, 'Evryone. Grudge') or string.match(spell.Name, 'Tenebral Crush') then gFunc.EquipSet(sets.BluDark);
    end
    ByName(spell.Name); -- a set named after the spell, e.g. ['White Wind']

    if (ca>=1) then gFunc.EquipSet(sets.Ca) end
    if (ba>=1) then gFunc.EquipSet(sets.Ba) end
    if (ef>=1) then gFunc.EquipSet(sets.Efflux) end
    if (diff>=1) then gFunc.EquipSet(sets.Diffusion) end

    if gcinclude.BluMagTH:contains(spell.Name) then gcinclude.CheckTH(true) end -- AoE: tags the adds too
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
    ByName(ws.Name); -- e.g. ['Expiacion'], then ['Expiacion_<mset>']
end

return profile;
