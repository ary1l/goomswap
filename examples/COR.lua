local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
		--Main = { Name = 'Rostam', AugPath='B'},
		--Sub = { Name = 'Rostam', AugPath='C'},
		--Range = 'Death Penalty',
        Ammo = 'Living Bullet',
        Head = 'Malignance Chapeau',
        Neck = 'Rep. Plat. Medal',
        Ear1 = 'Eabani Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'adamantite armor',
        Hands = 'Malignance Gloves',
        Ring1 = 'murky ring',
        Ring2 = 'Defending Ring',
        Back = 'null shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Weapon_Armageddon = {
        Range = 'Armageddon',
    },
    Weapon_Anarchy = {
        Main = 'Naegling',
        Sub = 'Gleti\'s Knife',
        Range = 'Anarchy +2',
    },
    Weapon_Anarchy_1h = {
        Main = 'Naegling',
        Sub = 'Nusku Shield',
        Range = 'Anarchy +2',
    },
    Weapon_DeathPenalty = {
        Main = 'Naegling',
        Sub = 'Gleti\'s Knife',
        Range = 'Death Penalty',
    },
    Weapon_DeathPenalty_1h = {
        Main = 'Naegling',
        Sub = 'Nusku Shield',
        Range = 'Death Penalty',
    },
    Weapon_Fomalhaut = {
        Main = 'Naegling',
        Sub = 'Gleti\'s Knife',
        Range = 'Fomalhaut',
    },
    Weapon_Fomalhaut_1h = {
        Main = 'Naegling',
        Sub = 'Nusku Shield',
        Range = 'Fomalhaut',
    },
    Weapon_Rostam = {
        Main = { Name = 'Rostam', AugPath='B'},
        Sub = 'Gleti\'s Knife',
        Range = 'Anarchy +2',
    },
    Weapon_Rostam_1h = {
        Main = { Name = 'Rostam', AugPath='B'},
        Sub = 'Nusku Shield',
        Range = 'Anarchy +2',
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
		Sub = 'leafkin shield',
        Range = 'Death Penalty',
        Ammo = 'Living Bullet',
        Head = 'laksa. tricorne +4',
        Neck = 'Rep. Plat. Medal',
        Body = 'adamantite armor',
        Hands = 'Lanun Gants +4',
        Ring1 = 'shneddick ring',
        Ring2 = 'Stikini Ring +1',
		Waist = 'k. kachina belt +1',
        Legs = 'Osh. trousers +1',
        Feet = 'Lanun Bottes +4',
    },
	Dt = {
        Head = 'Nyame Helm',
        Neck = 'Null Loop',
		Ear1 = 'Eabani Earring',
        Ear2 = 'alabaster Earring',
        Body = 'adamantite armor',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'murky ring',
        Ring2 = 'defending Ring',
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
        Hands = 'Malignance gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Epona\'s Ring',
		Back = 'null shawl',
        Waist = 'sailfi belt +1',
        Legs = 'Chas. Culottes +3',
        Feet = 'malignance boots',
    },
    Tp_Hybrid = {
		Main = 'naegling',
		Sub = 'tauret',
		Range = 'Fomalhaut',
        Ammo = 'Chrono Bullet',
        Head = 'Malignance Chapeau',
        Neck = 'Iskur Gorget',
        Ear2 = 'Suppanomimi',
        Body = 'Malignance Tabard',
        Hands = 'Malignance gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Epona\'s Ring',
		Back = 'null shawl',
        Waist = 'sailfi belt +1',
        Legs = 'Chas. Culottes +3',
        Feet = 'malignance boots',
    },
    Tp_Acc = {
		Main = 'Naegling',
		Sub = 'Gleti\'s Knife',
		Range = 'Anarchy +2',
		Ammo = 'chrono bullet',
        Head = 'Malignance Chapeau',
        Neck = 'Iskur Gorget',
        Ear1 = 'Telos Earring',
        Ear2 = 'Suppanomimi',
        Body = 'Malignance Tabard',
        Hands = 'Malignance gloves',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Epona\'s Ring',
		Back = 'null shawl',
        Waist = 'sailfi belt +1',
        Legs = 'Chas. Culottes +3',
        Feet = 'malignance boots',
    },


    Precast = {
        --Neck = 'Baetyl Pendant',
		Ear1 = 'loquac. earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adhemar Jacket',
        Hands = 'Leyline Gloves',
        Ring1 = 'Prolix Ring',
        Feet = 'Carmine Greaves +1',--8
    },


    Cure = {
        Neck = 'Incanter\'s Torque',
        Ear2 = 'Mendi. Earring',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Solemnity Cape',
        Legs = 'Carmine Cuisses +1',
    },

    Enhancing = {
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Ring2 = 'Metamor. Ring +1',
    },

    Enfeebling = {
        Neck = 'Erra Pendant',
        Ring2 = 'Metamor. Ring +1',
    },
    Macc = {},

    Drain = {
        Neck = 'Erra Pendant',
        Ring2 = 'Metamor. Ring +1',
    },

    Nuke = {
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
        Head = 'Ikenga\'s hat',
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
        Ring1 = 'regal Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },
    Ws_Hybrid = {
    },
    Ws_Acc = {
    },
    WsObi = {--puts elemental obi on for leaden/wildfire under dark/fire situations
        Waist = 'Anrin Obi',
    },

    Savage_Default = {
		Head = 'Nyame Helm',
        Neck = 'Rep. Plat. Medal',
        Ear1 = 'Ishvara Earring',
		Body = 'Nyame Mail',
        Hands = 'nyame gauntlets',
        Ring1 = 'sroda Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },
    Savage_Hybrid = {
    },
    Savage_Acc = {
        --Ear1 = 'Telos Earring',
    },

    Evisceration_Default = {
        Head = 'Adhemar Bonnet +1',
        Neck = 'Fotia Gorget',
        Ear1 = 'Odr Earring',
        Ear2 = 'Mache Earring +1',
        -- Body = 'Mummu Jacket +2',
        Hands = 'Adhemar Wrist. +1',
        Ring1 = 'Ilabrat Ring',
        Ring2 = 'Ephramad\'s Ring',
		Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = '"Store TP"+10', [5] = 'DEX+20' } },
        Waist = 'Fotia Belt',
        -- Legs = 'Mummu Kecks +2',
        -- Feet = 'Mummu Gamash. +2',
    },
    Evisceration_Hybrid = {
    },
    Evisceration_Acc = {
    },

    Aedge_Default = {
        Ammo = 'Hauksbok Bullet',
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Lanun Frac +4',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },
    Aedge_Hybrid = {
    },
    Aedge_Acc = {
    },

    Laststand_Default = {
		Ammo = 'chrono bullet',
        Head = 'Lanun Tricorne +4',
        Neck = 'Iskur Gorget',
        Ear1 = 'Ishvara Earring',
        Body = 'Laksa. Frac +4',
        Hands = 'nyame gauntlets',
        Ring1 = 'dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
		Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },
    Laststand_Hybrid = {
    },
    Laststand_Acc = {
	Neck = 'null loop',
    },

    Wildfire_Default = {
        Ammo = 'Living Bullet',
        Head = 'Nyame Helm',
        Neck = 'Comm. Charm +2',
        Ear1 = 'Friomisi Earring',
        Body = 'Lanun Frac +4',
        Hands = 'nyame gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },
    Wildfire_Hybrid = {
    },
    Wildfire_Acc = {
        --Ear2 = 'Digni. Earring',
    },
	HS_Default = {
        Ammo = 'Living Bullet',
        Head = 'Nyame Helm',
        Neck = 'Fotia Gorget',
        Ear1 = 'Friomisi Earring',
        Body = 'Nyame Mail',
        Hands = 'nyame gauntlets',
        Ring1 = 'dingir Ring',
        Ring2 = 'Ephramad\'s Ring',
		Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },
    HS_Hybrid = {
    },
    HS_Acc = {
        --Ear2 = 'Digni. Earring',
    },

    Leaden_Default = {
        Ammo = 'Living Bullet',
        Head = 'Pixie Hairpin +1',
        Neck = 'Comm. Charm +2',
        Ear1 = 'Friomisi Earring',
        Body = 'Lanun Frac +4',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Archon Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
        Waist = 'Svelt. Gouriz +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Lanun Bottes +4',
    },
    Leaden_Hybrid = {
    },
    Leaden_Acc = {
        --Ear2 = 'Digni. Earring',
        --Waist = 'Eschan Stone',
    },

    QD = {
        Ammo = 'Hauksbok Bullet',
        Head = 'Ikenga\'s hat',
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
    QD_Acc = {--with AF 2/3 and regal is better
        Ammo = 'Animikii Bullet',
        Head = 'laksa. tricorne +4',
        Neck = 'Comm. Charm +2',
		Ear1 = 'Gwati Earring',
        Ear2 = 'Digni. Earring',
        Body = 'Ikenga\'s Vest',
        Hands = 'Malignance Gloves',
        Ring1 = 'regal Ring',
        Ring2 = 'Stikini Ring +1',
		Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+20', [3] = 'Weapon skill damage +10%', [4] = 'AGI+30', [5] = 'Magic Damage+20' } },
		Waist = 'k. kachina belt +1',
        Legs = 'Ikenga\'s Trousers',
        Feet = 'Laksa. Bottes +2',
    },
    DoubleUp = { -- layered on the DT set; roll+ gear set on the initial roll carries over, Luzaf keeps the 16' range
		Ring1 = 'Luzaf\'s Ring',
    },
    Rolls = { -- it will put on ur DT gear set first then layer this set on for phantom roll (not dbl up), use /dt if you think you need to lock dt set while rolling
        Main = { Name = 'Rostam', AugPath='C'},
        Range = 'Compensator',
        Head = 'Lanun Tricorne +4',
		Neck = 'Regal Necklace',
        Hands = 'Chasseur\'s Gants +3',
		Ring1 = 'Luzaf\'s Ring',
		Ring2 = 'Defending Ring',
        Back = { Name = 'Camulus\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'HP+60', [3] = '"Snapshot"+10', [4] = 'Mag. Evasion+20', [5] = 'Evasion+20' } },
		Legs = 'desultor tassets',
    },

	Bolt = { -- it will put on ur DT gear set first then layer this set on for phantom roll (not dbl up), use /dt if you think you need to lock dt set while rolling
        Main = { Name = 'Rostam', AugPath='C' },
		Neck = 'null loop',
		Ring1 = 'Luzaf\'s Ring',
		Ring2 = 'Defending Ring',
        Back = 'null shawl',
    },

    Fold = {Hands = 'Lanun Gants +4'},
    WildCard = {Feet = 'Lanun Bottes +4'},
    RandomDeal = {Body = 'Lanun Frac +4'},
    SnakeEye = {Legs = 'Lanun Trews +2'},
    TH = {
        Head = { Name = 'Herculean Helm', Augment = { [1] = 'Accuracy+30', [2] = 'Attack+18', [3] = '"Fast Cast"+3', [4] = '"Treasure Hunter"+2' } },
		Waist = 'Chaac Belt',
	},
    Movement = {
		Head = 'nyame helm',
        Neck = 'loricate torque +1',
        Ear1 = 'Eabani Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'nyame mail',
        Hands = 'nyame gauntlets',
		Ring1 = 'shneddick ring',
        Back = 'null shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
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
    {Name = 'trump card', Quantity = 'all'},
	{Name = 'trump card case', Quantity = 'all'}
};

profile.OnLoad = function()
	gSettings.AllowAddSet = true;
    gcinclude.SafeAmmo = 'Chrono Bullet';
    gcinclude.RangeModes = {'None', 'Anarchy +2', 'Armageddon', 'Death Penalty', 'Fomalhaut'};
    gcinclude.WeaponModes = {'None', 'Anarchy', 'DeathPenalty', 'Fomalhaut', 'Rostam', 'Armageddon'};
    gcinclude.MainModes = {'None', 'Naegling', 'RostamA', 'RostamB', 'RostamC'};
    gcinclude.SubModes = {'None', 'Gleti\'s Knife', 'Tauret', 'Nusku Shield'};
    gcinclude.WeaponItemMap = {
        RostamA = { Name = 'Rostam', AugPath = 'A' },
        RostamB = { Name = 'Rostam', AugPath = 'B' },
        RostamC = { Name = 'Rostam', AugPath = 'C' },
    };
    gcinclude.DefaultWeapons = 'Anarchy';
    gcinclude.Initialize();

    gcinclude.CORmsg = true; -- set this to false if you do not want to see lucky/unlucky # messages, can also do /cormsg in game to change on the fly
end

profile.OnUnload = function()
    gcinclude.Unload();
end

profile.HandleCommand = function(args)
    gcinclude.HandleCommands(args);
end

profile.HandleDefault = function()
    gFunc.EquipSet(sets.Idle);

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
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end;
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();

	if (ability.Name == 'Bolter\'s Roll') then
		gFunc.EquipSet(sets.Dt);
		gFunc.EquipSet(sets.Bolt);
		gcinclude.DoCORmsg(ability.Name);
    elseif (ability.Name:contains('Roll')) then
        gFunc.EquipSet(sets.Dt);
        gFunc.EquipSet(sets.Rolls);
        gcinclude.DoCORmsg(ability.Name);
    elseif (ability.Name == 'Double-Up') then
        gFunc.EquipSet(sets.Dt);
        gFunc.EquipSet(sets.DoubleUp);
    elseif (ability.Name == 'Wild Card') then gFunc.EquipSet(sets.WildCard);
    elseif (ability.Name == 'Fold') then gFunc.EquipSet(sets.Fold);
    elseif (ability.Name == 'Random Deal') then gFunc.EquipSet(sets.RandomDeal);
    elseif (ability.Name == 'Snake Eye') then gFunc.EquipSet(sets.SnakeEye);
    elseif (ability.Type == 'Quick Draw') then
        gFunc.EquipSet(sets.QD);
        if (gcdisplay.GetCycle('MeleeSet') == 'Acc') or (ability.Name == 'Dark Shot') or (ability.Name == 'Light Shot') then
            gFunc.EquipSet(sets.QD_Acc);
        end
    end

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

    if (spell.Skill == 'Enhancing Magic') then
        gFunc.EquipSet(sets.Enhancing);
    elseif (spell.Skill == 'Healing Magic') then
        gFunc.EquipSet(sets.Cure);
    elseif (spell.Skill == 'Elemental Magic') then
        gFunc.EquipSet(sets.Nuke);
    elseif (spell.Skill == 'Enfeebling Magic') then
        gFunc.EquipSet(sets.Enfeebling);
    elseif (spell.Skill == 'Dark Magic') then
        gFunc.EquipSet(sets.Macc);
        if (string.contains(spell.Name, 'Aspir') or string.contains(spell.Name, 'Drain')) then
            gFunc.EquipSet(sets.Drain);
        end
    end
	gcinclude.CheckTH();
end

profile.HandlePreshot = function()
    if (gcinclude.CheckBlockedAmmo() == true) then return end
    local flurryI = gcinclude.BuffCount(265);
    local flurryII = gcinclude.BuffCount(581);

    gFunc.EquipSet(sets.Preshot);

    if flurryII > 0 then
        gFunc.EquipSet(sets.Preshot_FlurryII);
    elseif flurryI > 0 then
        gFunc.EquipSet(sets.Preshot_FlurryI);
    end
end

profile.HandleMidshot = function()
    local triple = gcinclude.BuffCount('Triple Shot');
    gFunc.EquipSet(sets.Midshot);

    if triple > 0 then
        gFunc.EquipSet(sets.TripleShot);
    end

    if (gcdisplay.GetCycle('MeleeSet') == 'Acc') then
        gFunc.EquipSet(sets.Midshot_Acc);
    end
	gcinclude.CheckTH();
end

profile.HandleWeaponskill = function()
    if (gcinclude.CheckWsBailout() == false) then gFunc.CancelAction(); return end
    local ws = gData.GetAction();
    if (gcinclude.CheckBlockedAmmoWS(ws.Name) == true) then return end

    gcinclude.EquipMode('Ws');

    if string.match(ws.Name, 'Savage Blade') then
        gcinclude.EquipMode('Savage');
    elseif string.match(ws.Name, 'Evisceration') then
        gcinclude.EquipMode('Evisceration');
    elseif string.match(ws.Name, 'Aeolian Edge') then
        gcinclude.EquipMode('Aedge');
    elseif string.match(ws.Name, 'Last Stand') then
        gcinclude.EquipMode('Laststand');
    elseif string.match(ws.Name, 'Wildfire') then
        gcinclude.EquipMode('Wildfire');
	elseif string.match(ws.Name, 'Hot Shot') then
        gcinclude.EquipMode('HS');
    elseif string.match(ws.Name, 'Leaden Salute') then
        gcinclude.EquipMode('Leaden');
    end
end

return profile;
