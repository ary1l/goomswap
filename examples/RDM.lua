local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
gcinclude.settings.WeaponTPGuard = 0; -- spells always get their weapons: worth the TP
gcinclude.CureObi = true; -- Hachirin-no-Obi on Cure/Cura/Curaga in Light day/weather (Aurorastorm counts); false = never

local sets = {
    Idle = {
        Main = 'Excalibur',
        Sub = 'Diamond Aspis',
        Range = 'displaced',
        Ammo = 'Staunch Tathlum',
        Head = 'Leth. Chappel +3',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Adamantite Armor',
        Hands = 'Leth. Ganth. +3',
        Ring1 = 'Murky Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Resting = {},
    Idle_Regen = {
        --Neck = 'Bathy Choker +1',
        --Ear1 = 'Infused Earring',
        Ring1 = 'Chirich Ring +1',
    },
    Idle_Refresh = {
        Head = 'Viti. Chapeau +4',
        Body = 'Lethargy Sayon +3',
        Hands = 'Merlinic Dastanas',
        Feet = 'Merlinic Crackows',
    },

    Town = {
        Main = 'Excalibur',
        Sub = 'Diamond Aspis',
        Range = 'Ullr',
        Ammo = 'Chapuli Arrow',
        Head = 'Viti. Chapeau +4',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Adamantite Armor',
        Hands = 'Leth. Ganth. +3',
        Ring1 = 'Shneddick Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet= 'Viti. Boots +4',
    },

    Dt = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Adamantite Armor',
        Hands = 'Malignance Gloves',
        Ring1 = 'Murky Ring',
        Ring2 = 'Fortified Ring',
        Back = 'Shadow Mantle',
        Waist = 'Carrier\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },
    SIR = {
        Ammo = 'Staunch Tathlum',
        Head = 'Leth. Chappel +3',
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Adamantite Armor',
        Hands = 'Leth. Ganth. +3',
        Ring1 = 'Murky Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
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
    Weapon_Caliburnus = { -- /wm cali
        Main = 'Caliburnus',
        Sub = 'Thibron',
    },
    Weapon_Caliburnus_1h = {
        Main = 'Caliburnus',
        Sub = 'Genmei Shield',
    },
    Weapon_Mpu = { -- /wm mpu
        Main = 'Mpu Gandring',
        Sub = 'Thibron',
    },
    Weapon_Mpu_1h = {
        Main = 'Mpu Gandring',
        Sub = 'Genmei Shield',
    },
    Weapon_Enspell = { -- /wm enspell: these weapons, and Tp_Enspell over the TP sets while engaged (HandleDefault)
        Main = 'Crocea Mors',
        Sub = 'Gleti\'s Knife',
    },
    Weapon_Enspell_1h = {
        Main = 'Crocea Mors',
        Sub = 'Genmei Shield',
    },
    Tp_Default = {
        Main = 'Excalibur',
        Sub = 'Thibron',
        Ammo = 'Coiste Bodhar',
        Head = 'Malignance Chapeau',
        Neck = 'Anu Torque',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Chirich Ring +1',
        Back = 'Null Shawl',
        Waist = 'Reiki Yotai',
        Legs = 'Malignance Tights',
        Feet = 'Malignance Boots',
    },

    Tp_Acc = {
        Ring2 = 'Cacoethic Ring +1',
    },

    Tp_Enspell = { -- /wm enspell, engaged: over Tp_Default and its /mset set. Enspell damage: Enhancing skill + "Sword enhancement spell damage" gear, day/weather; not MAB or Magic Damage
        Hands = 'Aya. Manopolas +2', -- Sword enhancement spell damage +17
        Waist = 'Orpheus\'s Sash',
        -- rest of BG-Wiki's EnSpell: Crocea set: Sroda Tathlum, Sworn Crown, Sworn Platemail, Sworn Brais, Sworn Sabatons
    },
    Midcast = {},

    Precast = {--30 from traits, 80 from gear
        Main = 'Sakpata\'s Sword',--10
        Sub = 'Diamond Aspis',
        Head = 'Atro. Chapeau +2',--14
        Neck = 'Voltsurge Torque',--4
        Ear1 = 'Malignance Earring',--4
        Ear2 = 'Leth. Earring +2',--8
        Body = 'Viti. Tabard +4',--15
        Hands = 'Leyline Gloves',--6
        Ring1 = 'Prolix Ring',
        Ring2 = 'Kishar Ring',--4
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Waist = 'Embla Sash',--5
        Legs = 'Chironic Hose',--5
        Feet = 'Amalric Nails +1',--6
    },
    ['Healing Magic_Precast'] = {
        Ear2 = 'Mendi. Earring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Feet = 'Vanya Clogs',
    },
    ['Enhancing Magic_Precast'] = {
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Waist = 'Siegel Sash',
    },
    Stoneskin_Precast = {
        Head = 'Umuthi Hat',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Waist = 'Siegel Sash',
    },
    Dispelga_Precast = {
        Main = 'Daybreak',
        Sub = 'Ammurapi Shield',
        Range = 'Ullr',
        Ammo = 'displaced',
        Head = 'Atro. Chapeau +2',--12
        Neck = 'Voltsurge Torque',--4
        Ear1 = 'Malignance Earring',--4
        Ear2 = 'Leth. Earring +2',--8
        Body = 'Viti. Tabard +4',--15
        Hands = 'Leyline Gloves',--6
        Ring1 = 'Prolix Ring',--2
        Ring2 = 'Kishar Ring',--4
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Waist = 'Embla Sash',--5
        Legs = 'Chironic Hose',--5
        Feet = 'Amalric Nails +1',--6
    },

    ['Healing Magic'] = {--I cap is 50, II cap is 30
        Main = 'Daybreak',--I 30
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Gwati Earring',
        Ear2 = 'Mendi. Earring',--I 5
        Body = 'Bunzi\'s Robe', --I 15
        Ring1 = 'Murky Ring',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Acc.+30', [3] = 'Magic Damage+20', [4] = 'MND+20', [5] = 'Haste+10' } },
        Waist = 'Rumination Sash',
        Legs = 'Atrophy Tights +2',--I 10 and skill
        Feet = 'Leth. Houseaux +3',
    },
    Self_Cure = {--cap 30
        Waist = 'Gishdubar Sash',
    },
    -- Cure/Cura/Curaga midcast, lowest to highest (later wins per slot):
    --   Cure -> Self_Cure (on you) -> Cure_LowMP or Cure_LowMP_Storm (MP <= 50%) -> Cure_Dt (/dt on)
    --   -> engine: Hachirin-no-Obi (Light day/weather) -> SIR set (/sir on) last. Empty sets change nothing.
    -- Main/Sub in these? Copy WHM.lua's KeepWeaponsFor line to OnLoad.
    Cure_LowMP = { -- MP <= 50%, no Light weather
    },
    Cure_LowMP_Storm = { -- MP <= 50%, Light weather: a SCH's Aurorastorm or natural Light
    },
    Cure_Dt = { -- /dt on: DT pieces to trade in while curing
    },
    Regen = {
        Main = 'Bolelabunga',
        Sub = 'Ammurapi Shield',
        Body = 'Viti. Tabard +4',
        Back = 'Ghostfyre Cape',
    },
    Cursna = {
        --Ring1 = 'Purity Ring',
        Waist = 'Gishdubar Sash',
    },

    ['Enhancing Magic'] = {
        Main = 'Sakpata\'s Sword',
        Sub = 'Ammurapi Shield',
        Ammo = 'Hydrocera',
        Head = 'Telchine Cap',
        Neck = 'Dls. Torque +2',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Leth. Earring +2',
        Body = 'Viti. Tabard +4',
        Hands = 'Atrophy Gloves +2',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Ghostfyre Cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Leth. Houseaux +3',
    },
    Self_Enhancing = {},
    Skill_Enhancing = {
        Head = 'Befouled Crown',
        Ear1 = 'Andoaa Earring',
        Waist = 'Olympus Sash',
        Legs = 'Atrophy Tights +2',
    },
    Stoneskin = {
        Neck = 'Nodens Gorget',--I 5
        Hands = 'Stone Mufflers',
        Waist = 'Siegel Sash',
        Legs = 'Haven Hose',
    },
    Refresh = {
        Sub = 'Ammurapi Shield',
        Ammo = 'Hydrocera',
        Head = 'Amalric Coif +1',
        Neck = 'Dls. Torque +2',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Leth. Earring +2',
        Body = 'Atrophy Tabard +2',
        Hands = 'Atrophy Gloves +2',
        Ring1 = 'Murky Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Ghostfyre Cape',
        Waist = 'Gishdubar Sash',
        Legs = 'Leth. Fuseau +3',
        Feet = 'Leth. Houseaux +3',
    },
    Self_Refresh = {},

    Gain = {
        Sub = 'Ammurapi Shield',
        Ammo = 'Hydrocera',
        Head = 'Telchine Cap',
        Neck = 'Dls. Torque +2',
        Ear1 = 'Mendi. Earring',
        Ear2 = 'Leth. Earring +2',
        Body = 'Viti. Tabard +4',
        Hands = 'Viti. Gloves +2',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Ghostfyre Cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Leth. Houseaux +3',
    },

    Aquaveil = {
        Sub = 'Ammurapi Shield',
        Ammo = 'Hydrocera',
        Head = 'Amalric Coif +1',
        Neck = 'Dls. Torque +2',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Leth. Earring +2',
        Body = 'Viti. Tabard +4',
        Hands = 'Atrophy Gloves +2',
        Ring1 = 'Murky Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Ghostfyre Cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Leth. Houseaux +3',
    },

    ['Enfeebling Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Range = 'Ullr',
        Ammo = 'Chapuli Arrow',
        Head = 'Viti. Chapeau +4',
        Neck = 'Dls. Torque +2',
        Ear1 = 'Snotra Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Lethargy Sayon +3',
        Hands = 'Leth. Ganth. +3',
        Ring1 =  'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'Obstin. Sash',
        Legs = 'Chironic Hose',
        Feet = 'Viti. Boots +4',
    },
    EnfeeblingACC = {
        Ear1 = 'Regal Earring',
        Ear2 = 'Snotra Earring',
        Body = 'Atrophy Tabard +2',
        Hands = 'Atrophy Gloves +2',
    },
    Dispelga = {
        Main = 'Daybreak',
        Sub = 'Ammurapi Shield',
        Range = 'Ullr',
        Ammo = 'displaced',
        Head = 'Viti. Chapeau +4',
        Neck = 'Dls. Torque +2',
        Ear1 = 'Snotra Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Lethargy Sayon +3',
        Hands = 'Leth. Ganth. +3',
        Ring1 =  'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'Obstin. Sash',
        Legs = 'Chironic Hose',
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
        Ammo = 'Chapuli Arrow',
        Head = 'Viti. Chapeau +4',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Atrophy Tabard +2',
        Hands = 'Atrophy Gloves +2',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'Fucho-no-Obi',
        Legs = 'Leth. Fuseau +3',
        Feet = 'Leth. Houseaux +3',
    },

    Aspir = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Range = 'Ullr',
        Ammo = 'Chapuli Arrow',
        Head = 'Viti. Chapeau +4',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Atrophy Tabard +2',
        Hands = 'Atrophy Gloves +2',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'Fucho-no-Obi',
        Legs = 'Leth. Fuseau +3',
        Feet = 'Leth. Houseaux +3',
    },

    ['Elemental Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Leth. Chappel +3',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Lethargy Sayon +3',
        Hands = 'Leth. Ganth. +3',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'Acuity Belt +1',
        Legs = 'Leth. Fuseau +3',
        Feet = 'Leth. Houseaux +3',
    },
    NukeACC = {},
    OccultAcumen = { -- /nukeset oa: Occult Acumen / Store TP pieces, over Nuke and Burst (TP from nukes)
    },
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
        Ammo = 'Coiste Bodhar',
        Head = 'Viti. Chapeau +4',
        Neck = 'Rep. Plat. Medal',
        Ear2 = 'Ishvara Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Ephramad\'s Ring',
        Ring2 = 'Petrov Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },

    ['Savage Blade'] = {
        Ammo = 'Coiste Bodhar',
        Head = 'Viti. Chapeau +4',
        Neck = 'Rep. Plat. Medal',
        Ear2 = 'Ishvara Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Ephramad\'s Ring',
        Ring2 = 'Sroda Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },

    Imperator = {
        Ammo = 'Coiste Bodhar',
        Head = 'Viti. Chapeau +4',
        Neck = 'Rep. Plat. Medal',
        Ear2 = 'Ishvara Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Ephramad\'s Ring',
        Ring2 = 'Ilabrat Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },

    ['Ruthless Stroke'] = { -- Mpu Gandring: 4 hits, DEX 25% / AGI 25%, fTP 5.375 / 14 / 23 (BG-Wiki). The Imperator set's pieces; not simulated
        Ammo = 'Coiste Bodhar',
        Head = 'Viti. Chapeau +4',
        Neck = 'Rep. Plat. Medal',
        Ear2 = 'Ishvara Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Ephramad\'s Ring',
        Ring2 = 'Ilabrat Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },

    ['Chant du Cygne'] = {
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

    ['Black Halo'] = {
        Ammo = 'Coiste Bodhar',
        Head = 'Viti. Chapeau +4',
        Neck = 'Rep. Plat. Medal',
        Ear1 = 'Regal Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Ephramad\'s Ring',
        Ring2 = 'Sroda Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },

    ['Shining Blade'] = {
        Ammo = 'Voluspa Tathlum',
        Head = 'Leth. Chappel +3',
        Neck = 'Fotia Gorget',
        Ear2 = 'Malignance Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Ilabrat Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },

    ['Shining Strike'] = {
        Ammo = 'Voluspa Tathlum',
        Head = 'Leth. Chappel +3',
        Neck = 'Fotia Gorget',
        Ear2 = 'Malignance Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Ilabrat Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },

    ['Seraph Blade'] = {
        Ammo = 'Voluspa Tathlum',
        Head = 'Leth. Chappel +3',
        Neck = 'Fotia Gorget',
        Ear2 = 'Malignance Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Ilabrat Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },

    ['Sanguine Blade'] = {
        Ammo = 'Oshasha\'s Treatise',
        Head = 'Pixie Hairpin +1',
        Neck = 'Sibyl Scarf',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Lethargy Sayon +3',
        Hands = 'Leth. Ganth. +3',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Archon Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = '"Mag. Atk. Bns."+10', [3] = 'Mag. Acc.+20', [4] = 'INT+20', [5] = 'Magic Damage+20' } },
        Waist = 'Orpheus\'s Sash',
        Legs = 'Leth. Fuseau +3',
        Feet = 'Leth. Houseaux +3',
    },

    ['Knights of Round'] = {
        Ammo = 'Coiste Bodhar',
        Head = 'Viti. Chapeau +4',
        Neck = 'Rep. Plat. Medal',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Ishvara Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Ephramad\'s Ring',
        Ring2 = 'Sroda Ring',
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Leth. Houseaux +3',
    },

    Chainspell = {
        Body = 'Viti. Tabard +4',
    },

    Saboteur = {
        Sub = 'Diamond Aspis',
    },

    TH = {
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
    },
    Movement = {
        Ring1 = 'Shneddick Ring',
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

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None', 'Naegling', 'Maxentius', 'Crocea', 'Caliburnus', 'Mpu', 'Enspell'};
    gcinclude.DefaultWeapons = 'Maxentius';
    gcinclude.NukeModes = {'Power', 'Macc', 'OccultAcumen'}; -- /nukeset oa (or oc, occult, acumen): OccultAcumen set on nukes
    -- Rules (/gcedit, RULES): when this, wear that, as data. A rule with at = goes on where gcinclude.RulesAt(...) is in the handlers below.
    gcinclude.Rules = {
        { on = 'Default', at = 'Default 1', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Default', at = 'Default 1', when = { toggle = { kite = true } }, wear = 'Movement', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { skill = 'Enhancing Magic', target = 'me' }, wear = 'Self_Enhancing', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { skill = 'Enhancing Magic' }, first = {
            { when = { any = { { name = { has = 'Temper' } }, { name = { has = 'En' }, target = 'me' } } }, wear = 'Skill_Enhancing', exact = true },
            { when = { name = { has = 'Gain' } }, wear = 'Gain', exact = true },
        } },
        { on = 'Midcast', at = 'Midcast 1', when = { skill = 'Healing Magic', target = 'me' }, wear = 'Self_Cure', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { family = { 'Cure', 'Cura', 'Curaga' }, mpp = { le = 50 }, skill = 'Healing Magic', weather = 'Light' }, wear = 'Cure_LowMP_Storm', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { family = { 'Cure', 'Cura', 'Curaga' }, mpp = { le = 50 }, skill = 'Healing Magic', weather = { isnt = { 'Light' } } }, wear = 'Cure_LowMP', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { family = { 'Cure', 'Cura', 'Curaga' }, skill = 'Healing Magic', toggle = { dt = true } }, wear = 'Cure_Dt', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { mode = { nukeset = 'Macc' }, skill = 'Elemental Magic' }, wear = 'NukeACC', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { burst = true, skill = 'Elemental Magic' }, wear = 'Burst', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { mode = { nukeset = 'OccultAcumen' }, skill = 'Elemental Magic' }, wear = 'OccultAcumen', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { name = { has = 'helix' }, skill = 'Elemental Magic' }, wear = 'Helix', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { mpp = { le = 40 }, skill = 'Elemental Magic' }, wear = 'Mp_Body', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { mode = { nukeset = 'Macc' }, skill = 'Enfeebling Magic' }, wear = 'EnfeeblingACC', exact = true },
        { on = 'Midcast', at = 'Midcast 1', when = { skill = 'Enfeebling Magic' }, first = {
            { when = { name = { has = { 'Paralyze', 'Slow', 'Addle' } } }, wear = 'Mind_Enfeebling', exact = true },
            { when = { name = { has = 'Poison' } }, wear = 'Int_Enfeebling', exact = true },
            { when = { name = { has = { 'Distract', 'Frazzle III' } } }, wear = 'Potency_Enfeebling', exact = true },
        } },
        { on = 'Midcast', at = 'Midcast 1', when = { skill = 'Dark Magic' }, wear = 'EnfeeblingACC', exact = true },
        { on = 'Midcast', when = { family = 'Refresh', target = 'me' }, wear = 'Self_Refresh', exact = true },
        { on = 'Default', when = { dualwield = false, status = 'Engaged', wmpick = false }, item = { Sub = 'Genmei Shield' },
            note = "Tp_Default's Thibron can't go on without dual wield" },
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
    gcinclude.EquipIdle(); -- Idle, then Idle_<mode> (/idleset)

    local player = gData.GetPlayer();
    if (player.Status == 'Engaged') then
        gcinclude.EquipMode('Tp');
        if (gcdisplay.GetCycle('Weapons') == 'Enspell') then gFunc.EquipSet(sets.Tp_Enspell) end -- /wm enspell: enspell pieces over the TP set
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
        gFunc.EquipSet(sets.Movement);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    gcinclude.RulesAt('Default 1');
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    ByName(ability.Name); -- a set named after the ability, e.g. ['Chainspell']
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
    local family = Family(spell.Name); -- 'Cure IV' -> 'Cure'
    gFunc.EquipSet(sets.Midcast);
    ByName(spell.Skill); -- e.g. ['Enhancing Magic'], ['Healing Magic'], ['Elemental Magic']
    gcinclude.RulesAt('Midcast 1');
    if not ByName(spell.Name) then ByName(family) end -- a set named after the spell or its family, e.g. ['Phalanx'], ['Cursna'], ['Drain']
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
    ByName(ws.Name); -- e.g. ['Savage Blade'], then ['Savage Blade_<mset>']
end

return profile;
