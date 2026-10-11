local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
		Main = 'excalibur',
		Sub = 'diamond aspis',
		Range = 'displaced',
		Ammo = 'staunch tathlum',
        Head = 'leth. chappel +3',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'eabani earring',
        Ear2 = 'alabaster Earring',
		Body = 'adamantite armor',
        Hands = 'leth. ganth. +3',
        Ring1 = 'murky ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'null shawl',
        Waist = 'null belt',
        Legs = 'Nyame flanchard',
        Feet = 'nyame sollerets',
    },
    Resting = {},
    Idle_Regen = {
        --Neck = 'Bathy Choker +1',
        --Ear1 = 'Infused Earring',
        Ring1 = 'Chirich Ring +1',
    },
    Idle_Refresh = {
        Head = 'Viti. Chapeau +4',
		Body = 'lethargy sayon +3',
		Hands = 'merlinic dastanas',
		Feet = 'merlinic crackows',
    },

    Town = {
        Main = 'Excalibur',
        Sub = 'diamond aspis',
        Range = 'Ullr',
		Ammo = 'chapuli arrow',
        Head = 'Viti. Chapeau +4',
        Neck = 'warder\'s charm +1',
        Ear1 = 'alabaster earring',
        Ear2 = 'etiolation earring',
        Body = 'adamantite armor',
        Hands = 'leth. ganth. +3',
        Ring1 = 'shneddick ring',
        Ring2 = 'stikini ring +1',
        Back = 'null shawl',
        Waist = 'null belt',
        Legs = 'nyame flanchard',
        Feet= 'Viti. Boots +4',
    },

    Dt = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'nyame helm',
        Neck = 'warder\'s charm +1',
        Ear1 = 'eabani earring',
        Ear2 = 'alabaster Earring',
        Body = 'adamantite armor',
        Hands = 'Malignance Gloves',
        Ring1 = 'murky ring',
        Ring2 = 'fortified ring',
        Back = 'shadow mantle',
        Waist = 'carrier\'s sash',
        Legs = 'nyame flanchard',
        Feet = 'leth. houseaux +3',
    },
    SIR = {
		Ammo = 'staunch tathlum',
        Head = 'leth. chappel +3',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'eabani earring',
        Ear2 = 'alabaster Earring',
		Body = 'adamantite armor',
        Hands = 'leth. ganth. +3',
        Ring1 = 'murky ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'null shawl',
        Waist = 'null belt',
        Legs = 'Nyame flanchard',
        Feet = 'nyame sollerets',
    },

    Weapon_Naegling = {
        Main = 'Naegling',
        Sub = 'Thibron',
    },
    Weapon_Naegling_1h = {
        Main = 'Naegling',
        Sub = 'Genmei Shield',
    },
    Weapon_Maxentius = {
        Main = 'Maxentius',
        Sub = 'Thibron',
    },
    Weapon_Maxentius_1h = {
        Main = 'Maxentius',
        Sub = 'Genmei Shield',
    },
    Weapon_Crocea = {
        Main = 'Crocea Mors',
        Sub = 'Daybreak',
    },
    Weapon_Crocea_1h = {
        Main = 'Crocea Mors',
        Sub = 'Genmei Shield',
    },
    Tp_Default = {
		Main = 'excalibur',
		Sub = 'thibron',
        Ammo = 'Coiste Bodhar',
        Head = 'Malignance Chapeau',
        Neck = 'Anu Torque',
        Ear1 = 'eabani Earring',
        Ear2 = 'Sherida Earring',
        Body = 'malignance tabard',
        Hands = 'Malignance Gloves',
        Ring1 = 'chirich ring +1',
        Ring2 = 'chirich Ring +1',
        Back = 'null shawl',
        Waist = 'reiki yotai',
        Legs = 'malignance tights',
        Feet = 'malignance boots',
    },

    Tp_Hybrid = {
        Ring1 = 'murky Ring',
    },

    Tp_Acc = {
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Cacoethic Ring +1',
    },


    Precast = {--30 from traits, 80 from gear
		Main = 'Sakpata\'s sword',--10
		Sub = 'diamond aspis',
        Head = 'Atro. Chapeau +2',--14
        Neck = 'voltsurge torque',--4
        Ear1 = 'leth. earring +2',--8
        Ear2 = 'malignance Earring',--4
        Body = 'Viti. Tabard +4',--15
		Hands = 'leyline gloves',--6
        Ring1 = 'prolix Ring',
        Ring2 = 'kishar ring',--4
		Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Waist = 'Embla Sash',--5
        Legs = 'chironic hose',--5
        Feet = 'amalric nails +1',--6
    },
    Cure_Precast = {
        Ear2 = 'Mendi. Earring',
		Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Feet = 'Vanya Clogs',
    },
    Enhancing_Precast = {
		Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Waist = 'Siegel Sash',
    },
    Stoneskin_Precast = {
        Head = 'Umuthi Hat',
		Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
		Waist = 'Siegel Sash',
    },
	dispelga_precast = {
		Main = 'daybreak',
		Sub = 'ammurapi shield',
		Range = 'ullr',
		Ammo = 'displaced',
		Head = 'Atro. Chapeau +2',--12
        Neck = 'voltsurge torque',--4
        Ear1 = 'leth. earring +2',--8
        Ear2 = 'malignance Earring',--4
        Body = 'Viti. Tabard +4',--15
		Hands = 'leyline gloves',--6
        Ring1 = 'Prolix Ring',--2
        Ring2 = 'kishar ring',--4
		Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Waist = 'Embla Sash',--5
        Legs = 'chironic hose',--5
        Feet = 'amalric nails +1',--6
	},


    Cure = {--I cap is 50, II cap is 30
        Main = 'daybreak',--I 30
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'loricate torque +1',
        Ear1 = 'gwati earring',
        Ear2 = 'Mendi. Earring',--I 5
		Body = 'Bunzi\'s robe', --I 15
        Ring1 = 'murky ring',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Waist = 'Rumination Sash',
        Legs = 'Atrophy Tights +2',--I 10 and skill
		Feet = 'leth. houseaux +3',
    },
    Self_Cure = {--cap 30
        Waist = 'Gishdubar Sash',
    },
    Regen = {
        Main = 'Bolelabunga',
        Sub = 'Ammurapi Shield',
        Body = 'Viti. Tabard +4',
		Back = 'ghostfyre cape',
    },
    Cursna = {
        --Ring1 = 'Purity Ring',
		Waist = 'Gishdubar Sash',
    },

    Enhancing = {
        Main = 'Sakpata\'s Sword',
        Sub = 'Ammurapi Shield',
        Ammo = 'hydrocera',
        Head = 'telchine cap',
        Neck = 'Dls. Torque +2',
        Ear1 = 'Leth. Earring +2',
        Ear2 = 'malignance Earring',
        Body = 'Viti. Tabard +4',
        Hands = 'Atrophy Gloves +2',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'stikini ring +1',
        Back = 'ghostfyre cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Leth. Houseaux +3',
    },
    Self_Enhancing = {},
    Skill_Enhancing = {
		Head = 'befouled crown',
		Ear1 = 'andoaa earring',
		Waist = 'olympus sash',
		Legs = 'atrophy tights +2',
	},
    Stoneskin = {
		Neck = 'Nodens Gorget',--I 5
		Hands = 'stone mufflers',
        Waist = 'Siegel Sash',
		Legs = 'haven hose',
    },
    Phalanx = {},
    Refresh = {
		Sub = 'ammurapi shield',
		Ammo = 'hydrocera',
		Head = 'amalric coif +1',
		Neck = 'Dls. Torque +2',
		Ear1 = 'leth. earring +2',
		Ear2 = 'Malignance Earring',
        Body = 'Atrophy Tabard +2',
		Hands = 'atrophy gloves +2',
		Ring1 = 'murky ring',
		Ring2 = 'stikini ring +1',
		Back = 'ghostfyre cape',
		Waist = 'Gishdubar Sash',
		Legs = 'leth. fuseau +3',
		Feet = 'Leth. Houseaux +3',
    },
    Self_Refresh = {},

	Gain = {
        Sub = 'Ammurapi Shield',
        Ammo = 'hydrocera',
        Head = 'telchine cap',
        Neck = 'Dls. Torque +2',
        Ear1 = 'Leth. Earring +2',
        Ear2 = 'Mendi. Earring',
        Body = 'Viti. Tabard +4',
        Hands = 'Viti. Gloves +2',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'ghostfyre cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Leth. Houseaux +3',
	},

	aquaveil = {
		Sub = 'Ammurapi Shield',
        Ammo = 'hydrocera',
        Head = 'amalric coif +1',
        Neck = 'Dls. Torque +2',
        Ear1 = 'Leth. Earring +2',
        Ear2 = 'malignance Earring',
        Body = 'Viti. Tabard +4',
        Hands = 'Atrophy Gloves +2',
        Ring1 = 'murky ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'ghostfyre cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Leth. Houseaux +3',
	},

    Enfeebling = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Range = 'Ullr',
		Ammo = 'chapuli arrow',
        Head = 'viti. chapeau +4',
		Neck = 'Dls. Torque +2',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Snotra Earring',
        Body = 'Lethargy Sayon +3',
        Hands = 'leth. ganth. +3',
        Ring1 =  'Metamor. Ring +1',
        Ring2 = 'stikini ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'obstin. sash',
        Legs = 'chironic hose',
        Feet = 'Viti. Boots +4',
    },
    EnfeeblingACC = {
        Ear1 = 'Regal Earring',
        Ear2 = 'Snotra Earring',
        Body = 'Atrophy Tabard +2',
        Hands = 'Atrophy Gloves +2',
    },
	dispelga = {
        Main = 'Daybreak',
        Sub = 'Ammurapi Shield',
        Range = 'Ullr',
		Ammo = 'displaced',
        Head = 'viti. chapeau +4',
		Neck = 'Dls. Torque +2',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Snotra Earring',
        Body = 'Lethargy Sayon +3',
        Hands = 'leth. ganth. +3',
        Ring1 =  'Metamor. Ring +1',
        Ring2 = 'stikini ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'obstin. sash',
        Legs = 'chironic hose',
        Feet = 'Viti. Boots +4',
    },
    Mind_Enfeebling = {
		Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
    },
    Int_Enfeebling = {},
    Potency_Enfeebling = {},

    Drain = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Range = 'Ullr',
		Ammo = 'chapuli arrow',
        Head = 'Viti. Chapeau +4',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Atrophy Tabard +2',
        Hands = 'Atrophy Gloves +2',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'stikini ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'Fucho-no-Obi',
        Legs = 'leth. fuseau +3',
        Feet = 'Leth. Houseaux +3',
    },

    Nuke = {
        Main = 'bunzi\'s rod',
        Sub = 'ammurapi shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'leth. chappel +3',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Lethargy Sayon +3',
        Hands = 'leth. ganth. +3',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'stikini ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'Acuity Belt +1',
        Legs = 'leth. fuseau +3',
        Feet = 'Leth. Houseaux +3',
    },
    NukeACC = {};
    Burst = {
        Main = 'Bunzi\'s Rod', -- 10 and 0
        Sub = 'Ammurapi Shield',
        --Head = 'Ea Hat', -- 6 and 6
        --Body = 'Ea Houppelande', -- 8 and 8
        Hands = 'Amalric Gages +1', -- 0 and 6
        Ring2 = 'Mujin Band', -- 0 and 5
        --Feet = 'Ea Pigaches', -- 4 and 4
    },
    Helix = {},
    Mp_Body = {Body = 'Seidr Cotehardie',},

    Preshot = {
    },
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },

    Ws_Default = {
        Ammo = 'coiste bodhar',
        Head = 'Viti. Chapeau +4',
		Neck = 'rep. plat. medal',
        Ear1 = 'ishvara Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'ephramad\'s Ring',
        Ring2 = 'petrov Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'leth. houseaux +3',
    },
    Ws_Hybrid = {
    },
    Ws_Acc = {
    },

    Savage_Default = {
        Ammo = 'coiste bodhar',
        Head = 'Viti. Chapeau +4',
        Neck = 'rep. plat. medal',
        Ear1 = 'ishvara earring',
        Body = 'Nyame Mail',
        Hands = 'nyame gauntlets',
        Ring1 = 'ephramad\'s ring',
        Ring2 = 'sroda ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'leth. houseaux +3',
    },
    Savage_Hybrid = {},
    Savage_Acc = {},

    Chant_Default = {
        Ammo = 'Voluspa Tathlum',
        Head = 'Blistering Sallet +1',
        Neck = 'Fotia Gorget',
        Ear1 = 'Eabani Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Begrudging Ring',
        Ring2 = 'Petrov Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Fotia Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Thereoid Greaves',
    },
    Chant_Hybrid = {},
    Chant_Acc = {},

	BH_Default = {
        Ammo = 'coiste bodhar',
        Head = 'Viti. Chapeau +4',
        Neck = 'rep. plat. medal',
        Ear1 = 'regal earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'ephramad\'s ring',
        Ring2 = 'sroda ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'sailfi belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'leth. houseaux +3',
    },
    BH_Hybrid = {},
    BH_Acc = {},

	shining_Default = {
        Ammo = 'Voluspa Tathlum',
        Head = 'leth. chappel +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'malignance Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Metamor. ring +1',
        Ring2 = 'ilabrat ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'orpheus\'s sash',
        Legs = 'Nyame Flanchard',
        Feet = 'leth. houseaux +3',
    },
    shining_Hybrid = {},
    shining_Acc = {},

	sanguine_Default = {
        Ammo = 'oshasha\'s treatise',
        Head = 'pixie hairpin +1',
        Neck = 'sibyl scarf',
        Ear1 = 'regal Earring',
        Ear2 = 'malignance Earring',
        Body = 'lethargy sayon +3',
        Hands = 'leth. ganth. +3',
        Ring1 = 'Metamor. ring +1',
        Ring2 = 'archon ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'orpheus\'s sash',
        Legs = 'leth. fuseau +3',
        Feet = 'leth. houseaux +3',
    },
    sanguine_Hybrid = {},
    sanguine_Acc = {},

	KOR_Default = {
        Ammo = 'coiste bodhar',
        Head = 'viti. chapeau +4',
        Neck = 'rep. plat. medal',
        Ear1 = 'ishvara Earring',
        Ear2 = 'sherida Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'ephramad\'s ring',
        Ring2 = 'sroda ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'sailfi belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'leth. houseaux +3',
    },
    KOR_Hybrid = {},
    KOR_Acc = {},

    CS = {
		Body = 'Viti. Tabard +4',
	},

	sab = {
		Body = 'diamond aspis',
	},

    TH = {
        Ammo = 'Per. Lucky Egg',
		Waist = 'Chaac Belt',
	},
    Movement = {
        Ring1 = 'shneddick ring',
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
    gcinclude.WeaponModes = {'None', 'Naegling', 'Maxentius', 'Crocea'};
    gcinclude.DefaultWeapons = 'Maxentius';
    gcinclude.Initialize();
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
    -- No Dual Wield + /wm none + engaged: Tp_Default's Thibron can't equip, use Genmei Shield.
    if (player.Status == 'Engaged') and (not gcinclude.IsWeaponValue(gcdisplay.GetCycle('Weapons'))) and (not gcinclude.CanDualWield()) then
        gFunc.Equip('Sub', 'Genmei Shield');
    end
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();

    if ability.Name == 'Chainspell' then
        gFunc.EquipSet(sets.CS);
    end

	if ability.Name == 'Saboteur' then
        gFunc.EquipSet(sets.sab);
    end


    gcinclude.CheckCancels();
end

profile.HandleItem = function()
    local item = gData.GetAction();

	if string.match(item.Name, 'Holy Water') then gFunc.EquipSet(gcinclude.sets.Holy_Water) end
end

profile.HandlePrecast = function()
    local spell = gData.GetAction();
    gFunc.EquipSet(sets.Precast)

    if (spell.Skill == 'Enhancing Magic') then
        gFunc.EquipSet(sets.Enhancing_Precast);

        if string.contains(spell.Name, 'Stoneskin') then
            gFunc.EquipSet(sets.Stoneskin_Precast);
        end
    elseif (spell.Skill == 'Healing Magic') then
        gFunc.EquipSet(sets.Cure_Precast);
    end
    if (spell.Name == 'Dispelga') then gFunc.EquipSet(sets.dispelga_precast) end
    gcinclude.CheckCancels();
end

profile.HandleMidcast = function()
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
        elseif string.contains(spell.Name, 'Temper') then
            gFunc.EquipSet(sets.Skill_Enhancing);
        elseif string.contains(spell.Name, 'Regen') then
            gFunc.EquipSet(sets.Regen);
		elseif string.contains(spell.Name, 'Gain') then
            gFunc.EquipSet(sets.Gain);
		elseif string.contains(spell.Name, 'Aquaveil') then
			gFunc.EquipSet(sets.aquaveil);
        elseif string.contains(spell.Name, 'Refresh') then
            gFunc.EquipSet(sets.Refresh);
            if (target.Name == me) then
                gFunc.EquipSet(sets.Self_Refresh);
            end
        elseif (target.Name == me) and string.contains(spell.Name, 'En') then
            gFunc.EquipSet(sets.Skill_Enhancing);
        end
    elseif (spell.Skill == 'Healing Magic') then
        gFunc.EquipSet(sets.Cure);
        if (target.Name == me) then
            gFunc.EquipSet(sets.Self_Cure);
        end
        if string.match(spell.Name, 'Cursna') then
            gFunc.EquipSet(sets.Cursna);
        end
    elseif (spell.Skill == 'Elemental Magic') then
        gFunc.EquipSet(sets.Nuke);

        if (gcdisplay.GetCycle('NukeSet') == 'Macc') then
            gFunc.EquipSet(sets.NukeACC);
        end
        if gcinclude.BurstWanted() then
            gFunc.EquipSet(sets.Burst);
        end
        if string.match(spell.Name, 'helix') then
            gFunc.EquipSet(sets.Helix);
        end
        if (gData.GetPlayer().MPP <= 40) then
            gFunc.EquipSet(sets.Mp_Body);
        end
    elseif (spell.Skill == 'Enfeebling Magic') then
        gFunc.EquipSet(sets.Enfeebling);
        if (gcdisplay.GetCycle('NukeSet') == 'Macc') then
            gFunc.EquipSet(sets.EnfeeblingACC);
        end
        if string.contains(spell.Name, 'Paralyze') or string.contains(spell.Name, 'Slow') or string.contains(spell.Name, 'Addle') then
            gFunc.EquipSet(sets.Mind_Enfeebling);
        elseif string.contains(spell.Name, 'Poison') then
            gFunc.EquipSet(sets.Int_Enfeebling);
		elseif string.contains(spell.Name, 'Dispelga') then
            gFunc.EquipSet(sets.dispelga);
        elseif string.contains(spell.Name, 'Distract') or string.match(spell.Name, 'Frazzle III') then
            gFunc.EquipSet(sets.Potency_Enfeebling);
        end
    elseif (spell.Skill == 'Dark Magic') then
        gFunc.EquipSet(sets.EnfeeblingACC); -- mostly MACC anyways
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

    if string.match(ws.Name, 'Chant du Cygne') then
        gcinclude.EquipMode('Chant');
	elseif string.match(ws.Name, 'Sanguine Blade') then
        gcinclude.EquipMode('sanguine');
	elseif string.match(ws.Name, 'Black Halo') then
        gcinclude.EquipMode('BH');
	elseif string.match(ws.Name, 'Knights of Round') then
        gcinclude.EquipMode('KOR');
	elseif string.match(ws.Name, 'Shining Blade') or string.match(ws.Name, 'Seraph Blade') or string.match(ws.Name, 'Shining Strike') then
        gcinclude.EquipMode('shining');
    elseif string.match(ws.Name, 'Savage Blade') then
        gcinclude.EquipMode('Savage');
    end
end

return profile;
