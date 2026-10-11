local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
gcinclude.SIRSkip = T{'Phalanx','Reprisal'}; -- /sir leaves these midcasts alone


local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
		Main = 'burtgang',
		Sub = 'aegis',
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'chev. armet +3', Priority = 145 },
        Neck = 'unmoving collar +1',
        Ear1 = 'spellbr. earring',
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'chev. cuirass +3', Priority = 151 },
        Hands = { Name = 'chev. gauntlets +3', Priority = 64 },
        Ring1 = 'shadow ring',
        Ring2 = 'fortified ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'carrier\'s sash', Priority = 20 },
        Legs = { Name = 'chev. cuisses +3', Priority = 127 },
        Feet = { Name = 'rev. leggings +4', Priority = 92 },
    },
    Resting = {},
    Idle_Regen = {
        --Head = 'volte salade',
        Neck = 'Coatl Gorget +1',
        --Ear1 = 'Infused Earring',
		Hands = { Name = 'regal gauntlets', Priority = 205 },
        Ring1 = 'Chirich Ring +1',
		Waist = 'null belt',
    },
    Idle_Refresh = {
        --Ammo = 'Homiliary',
        --Head = 'Jumalik Helm',
        Ring1 = 'Stikini Ring +1',
		Ring2 = 'stikini ring +1',
    },
    Town = {
        Main = 'burtgang',
        Sub = 'duban',
		Range = 'ullr',
        Ammo = 'chapuli arrow',
		Head = { Name = 'chev. armet +3', Priority = 145 },
		Neck = 'coatl gorget +1',
        Ear1 = 'hearty earring',
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
		Body = { Name = 'adamantite armor', Priority = 182 },
        Hands = { Name = 'regal gauntlets', Priority = 205 },
		Ring1 = 'shneddick ring',
		Ring2 = 'stikini ring +1',
		Waist = 'plat. mog. belt',
        Legs = { Name = 'cab. breeches +4', Priority = 82 },
        Feet = { Name = 'Rev. Leggings +4', Priority = 92 },
    },

    mdt = {
		Main = 'burtgang',
		Sub = 'aegis',
        Head = { Name = 'nyame helm', Priority = 91 },
        Neck = 'coatl gorget +1',
        Ear1 = 'Spellbr. Earring',
        Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'adamantite armor', Priority = 182 },
        Hands = { Name = 'nyame gauntlets', Priority = 91 },
        Ring1 = 'shadow ring',
		Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'carrier\'s sash', Priority = 20 },
        Legs = { Name = 'nyame flanchard', Priority = 114 },
        Feet = { Name = 'nyame sollerets', Priority = 68 },
    },
    Aminon = {
		Main = 'caliburnus',
		Sub = 'aegis',
        Head = { Name = 'nyame helm', Priority = 91 },
        Neck = 'coatl gorget +1',
        Ear1 = 'Spellbr. Earring',
        Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'adamantite armor', Priority = 182 },
        Hands = { Name = 'nyame gauntlets', Priority = 91 },
        Ring1 = 'shadow ring',
		Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'carrier\'s sash', Priority = 20 },
        Legs = { Name = 'nyame flanchard', Priority = 114 },
        Feet = { Name = 'nyame sollerets', Priority = 68 },
    },

    Dt = {
		Main = 'burtgang',
		Sub = 'duban',
		Ammo = 'staunch tathlum +1',
        Head = { Name = 'chev. armet +3', Priority = 145 },
        Neck = 'warder\'s charm +1',
        Ear1 = 'hearty earring',
        Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'adamantite armor', Priority = 182 },
        Hands = { Name = 'chev. gauntlets +3', Priority = 64 },
        Ring1 = 'shadow ring',
		Ring2 = 'fortified ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'carrier\'s sash', Priority = 20 },
        Legs = { Name = 'chev. cuisses +3', Priority = 127 },
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },
    },

    Tp_Default = {
        Ammo = 'coiste bodhar',
        Head = { Name = 'sakpata\'s helm', Priority = 91 },
        Neck ={ Name = 'null loop', Priority = 50 },
        Ear1 = 'Telos Earring',
        Ear2 = 'Cessance Earring',
        Body = { Name = 'sakpata\'s plate', Priority = 136 },
        Hands = { Name = 'Sakpata\'s Gauntlets', Priority = 91 },
        Ring1 = 'chirich Ring +1',
        Ring2 = { Name = 'moonlight Ring', Priority = 110 },
        Back = 'null shawl',
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Sakpata\'s Cuisses', Priority = 114 },
        Feet = { Name = 'sakpata\'s leggings', Priority = 68 },
    },
    Tp_Hybrid = {
        Ammo = 'coiste bodhar',
        Head = { Name = 'sakpata\'s helm', Priority = 91 },
        Neck ={ Name = 'null loop', Priority = 50 },
        Ear1 = 'Telos Earring',
        Ear2 = 'Cessance Earring',
        Body = { Name = 'sakpata\'s plate', Priority = 136 },
        Hands = { Name = 'Sakpata\'s Gauntlets', Priority = 91 },
        Ring1 = 'murky ring',
        Ring2 = { Name = 'moonlight Ring', Priority = 110 },
        Back = 'null shawl',
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Sakpata\'s Cuisses', Priority = 114 },
        Feet = { Name = 'Sakpata\'s leggings', Priority = 68 },
    },
    Tp_Acc = {
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Cacoethic Ring +1',
    },

    --These will overwrite any above TP profile.Sets if /tankset is used
    Tank_Main = {--Default Tanking,  dt
        Ammo = 'coiste bodhar',
        Head = { Name = 'nyame helm', Priority = 91 },
        Neck = 'unmoving collar +1',
        Ear1 = 'Tuisto Earring',
        Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'nyame mail', Priority = 136 },
        Hands = { Name = 'nyame gauntlets', Priority = 91 },
        Ring1 = { Name = 'Moonlight Ring', Priority = 110 },
		Ring2 = 'petrov ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = 'sailfi belt +1',
        Legs = { Name = 'nyame flanchard', Priority = 114 },
        Feet = { Name = 'nyame sollerets', Priority = 68 },
        },

    Tank_MEVA = {
        Ammo = 'vanir battery',
        Head = { Name = 'nyame helm', Priority = 91 },
        Neck = 'moonlight necklace',
        Ear1 = 'chev. earring +1',
        Ear2 = { Name = 'Eabani Earring', Priority = 45 },
        Body = { Name = 'nyame mail', Priority = 136 },
        Hands = { Name = 'nyame gauntlets', Priority = 91 },
		Ring1 = { Name = 'vexer ring +1', Priority = 55 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'carrier\'s sash', Priority = 20 },
        Legs = { Name = 'nyame flanchard', Priority = 114 },
        Feet = { Name = 'nyame sollerets', Priority = 68 },
    },

    Precast = { --47FC
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'chev. armet +3', Priority = 145 },--9
        Neck = 'voltsurge torque',--4
        Ear1 = 'loquac. earring', --2
        Ear2 = { Name = 'alabaster Earring', Priority = 100 },
        Body = { Name = 'Rev. Surcoat +4', Priority = 264 },--10
        Hands = { Name = 'Leyline Gloves', Priority = 25 },--6
		Ring1 = 'murky ring',
		Ring2 = 'kishar ring',
		Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+30', [4] = 'HP+60', [5] = 'Evasion+20' }, Priority = 60 },
		Waist = 'plat. mog. belt',
        Legs = { Name = 'odyssean cuisses', Priority = 54 },--6
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--7
    },
    Cure_Precast = {
	    --Ear1 = 'Nourish. Earring +1',
        Ear2 = 'Mendi. Earring',
    },
    Enhancing_Precast = {
		Body = { Name = 'shab. cuirass +1', Priority = 115 },
		Hands = { Name = 'regal gauntlets', Priority = 205 },
        Waist = 'Siegel Sash',
    },
    SIR = {
        Ammo = 'Staunch Tathlum +1',--11
        Head = { Name = 'Souv. Schaller +1', Priority = 175 },
        Neck = 'Moonlight Necklace',--15
	    Ear1 = 'Tuisto Earring',
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'chev. cuirass +3', Priority = 151 },--20
		Hands = { Name = 'regal gauntlets', Priority = 205 }, --10
		Ring1 = 'murky ring',--3
		Ring2 = { Name = 'moonlight ring', Priority = 110 },
		Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = 'audumbla sash',--10
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--10
        Feet = { Name = 'Odyssean Greaves', Priority = 20 },
    },
    Enmity = {
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },
		Ear2 = 'friomisi earring',
        Body = { Name = 'souv. cuirass +1', Priority = 66 },--20
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
		Ring1 = { Name = 'eihwaz Ring', Priority = 70 },--5
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },--4
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = 'plat. mog. belt',
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
    },

    Cure = {  --98% SIR(capped w merits) 39%/50% CurePot, 25%/30%CurePot2 w Majesty
        Ammo = 'Staunch Tathlum +1', --10SIR
        Head = { Name = 'Souv. Schaller +1', Priority = 175 }, --15rec/20SIR
        Neck = 'moonlight necklace',--15SIR
        Ear1 = 'chev. earring +1', --11
        Ear2 = 'mendi. earring', --5
        Body = { Name = 'chev. cuirass +3', Priority = 151 },--20SIR
        Hands = { Name = 'Macabre Gaunt. +1', Priority = 29 }, --11
        Ring1 = 'murky ring',--3SIR
        Ring2 = 'defending ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = 'plat. mog. belt',
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--10SIR
        Feet = { Name = 'odyssean greaves', Priority = 20 },--12/20SIR
    },

    Phalanx = { -- +36phalanx received
		Main = { Name = 'Sakpata\'s sword', Priority = 100 }, --5
		Sub = { Name = 'priwen', Priority = 30 }, --3
		Ammo = 'staunch tathlum +1',
        Head = { Name = 'valorous mask', Priority = 38 },--4
        Neck = 'moonlight necklace',
        Ear1 = 'tuisto Earring',
        Ear2 = 'odnowa earring +1',
        Body = { Name = 'valorous mail', Priority = 61 },--4
        Hands = { Name = 'souv. handsch. +1', Priority = 134 }, --5
        Ring1 = 'murky ring',
        Ring2 = { Name = 'Moonlight Ring', Priority = 110 },
        Back = { Name = 'weard mantle', Priority = 40 }, --5
        Waist = 'audumbla sash',
        Legs = { Name = 'sakpata\'s cuisses', Priority = 114 }, --5
        Feet = { Name = 'souveran schuhs +1', Priority = 122 }, --5
	},

	Stoneskin = {
		Ammo = 'staunch tathlum +1',
        Head = { Name = 'chev. armet +3', Priority = 145 },
        Neck = 'stone gorget',
        Ear1 = 'earthcry earring',
        Ear2 = 'odnowa earring +1',
        Body = { Name = 'rev. surcoat +4', Priority = 264 },
        Hands = { Name = 'stone mufflers', Priority = 10 },
        Ring1 = { Name = 'Moonlight Ring', Priority = 110 },
		Ring2 = 'defending ring',
        Back = { Name = 'moonbeam cape', Priority = 250 },
        Waist = 'siegel sash',
        Legs = 'haven hose',
        Feet = { Name = 'sakpata\'s leggings', Priority = 68 },
    },

    Reprisal = { --105 SIR
        Ammo = 'staunch tathlum +1',--10
        Head = { Name = 'souv. schaller +1', Priority = 175 },--20
        Neck = 'moonlight necklace', --15
        Ear1 = 'Tuisto Earring',
        Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'Shab. Cuirass +1', Priority = 115 },
		Hands = { Name = 'regal gauntlets', Priority = 205 },--20
		Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'Moonlight Ring', Priority = 110 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = 'audumbla sash',--10
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--10
        Feet = { Name = 'odyssean greaves', Priority = 20 },--20
    },

    Absorb_TP = {
        Head = { Name = 'Chev. Armet +3', Priority = 145 },
        Neck = { Name = 'Null Loop', Priority = 50 },
		Ear1 = 'chev. earring +1',
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'Chev. Cuirass +3', Priority = 151 },
        Hands = { Name = 'Chev. Gauntlets +3', Priority = 64 },
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = { Name = 'Chev. Cuisses +3', Priority = 127 },
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },
    },
    Flash = {
        Ammo = 'sapience orb',
        Head = { Name = 'loess barbuta +1', Priority = 105 },
        Neck = 'moonlight necklace',
        Ear1 = { Name = 'cryptic Earring', Priority = 40 },
        Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'Rev. Surcoat +4', Priority = 264 },
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'creed baudrier', Priority = 40 },
		Legs = { Name = 'cab. breeches +4', Priority = 82 },
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
    },

    Preshot = {
		Range = 'ullr',
		Ammo = 'chapuli arrow',
		},

    Midshot = {
		Head = { Name = 'nyame helm', Priority = 91 },
		Neck = { Name = 'sanctity necklace', Priority = 35 },
        Ear1 = 'Telos Earring',
        Ear2 = 'Enervating Earring',
		Body = { Name = 'nyame mail', Priority = 136 },
		Hands = { Name = 'nyame gauntlets', Priority = 91 },
		Ring1 = { Name = 'regal ring', Priority = 50 },
		Ring2 = 'petrov ring',
		Back = 'null shawl',
		Waist = 'null belt',
		Legs = { Name = 'nyame flanchard', Priority = 114 },
		Feet = { Name = 'nyame sollerets', Priority = 68 },
    },

    Ws_Default = {
        Ammo = 'coiste bodhar',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'rep. plat. medal',
        Ear1 = 'thrud Earring',
        Ear2 = 'Cessance Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'nyame Gauntlets', Priority = 91 },
        Ring1 = 'ephramad\'s ring',
        Ring2 = 'petrov Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'sailfi Belt +1',
        Legs = { Name = 'nyame flanchard', Priority = 114 },
        Feet = { Name = 'nyame Sollerets', Priority = 68 },
    },
    Ws_Hybrid = {
    },
    Ws_Acc = {
    },
    Chant_Default = {
        Ammo = 'coiste bodhar',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'rep. plat. medal',
        Ear1 = 'telos Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'nyame Gauntlets', Priority = 91 },
        Ring1 = 'ephramad\'s ring',
        Ring2 = { Name = 'regal Ring', Priority = 50 },
		Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'nyame flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    Chant_Hybrid = {
    },
    Chant_Acc = {
    },
    Savage_Default = {
		Ammo = 'coiste bodhar',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'rep. plat. medal',
        Ear1 = 'thrud Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'nyame Gauntlets', Priority = 91 },
        Ring1 = 'ephramad\'s ring',
        Ring2 = { Name = 'regal Ring', Priority = 50 },
		Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'nyame flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    Savage_Hybrid = {
    },
    Savage_Acc = {
    },
    Atone_Default = {
        Ammo = 'sapience orb',
        Head = { Name = 'loess barbuta +1', Priority = 105 },
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },
        Ear2 = 'Odnowa Earring +1',
        Body = { Name = 'rev. surcoat +4', Priority = 264 },
        Hands = { Name = 'cab. gauntlets +4', Priority = 134 },
        Ring1 = { Name = 'eihwaz Ring', Priority = 70 },--5
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },--4
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Eva.+20', [3] = 'Eva.+20', [4] = 'HP+60', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'creed baudrier', Priority = 40 },
        Legs = { Name = 'cab. breeches +4', Priority = 82 },
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },
    },
    Atone_Hybrid = {
    },
    Atone_Acc = {
    },
    Aedge_Default = {
        Ammo = 'Pemphredo Tathlum',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'sibyl scarf',
        Ear1 = 'Crematio Earring',
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = 'metamor. ring +1',
        Ring2 = { Name = 'regal ring', Priority = 50 },
		Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'orpheus\'s sash',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    Aedge_Hybrid = {},
    Aedge_Acc = {},

    sanguine_Default = {
        Ammo = 'Pemphredo tathlum',
        Head = { Name = 'pixie hairpin +1', Priority = -35 },
        Neck = 'sibyl scarf',
        Ear1 = 'Regal Earring',
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = 'metamor. ring +1',
        Ring2 = 'archon Ring',
		Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'orpheus\'s sash',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    sanguine_Hybrid = {},
    sanguine_Acc = {},

	shining_Default = {
        Ammo = 'Pemphredo Tathlum',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'sibyl scarf',
        Ear1 = 'Crematio Earring',
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = 'metamor. ring +1',
        Ring2 = { Name = 'regal ring', Priority = 50 },
		Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'orpheus\'s sash',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    shining_Hybrid = {},
    shining_Acc = {},

	KOR_Default = {
        Ammo = 'crepuscular pebble',
        Head = { Name = 'nyame helm', Priority = 91 },
        Neck = 'fotia gorget',
        Ear1 = 'thrud Earring',
        Ear2 = { Name = 'alabaster Earring', Priority = 100 },
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'sakpata\'s gauntlets', Priority = 91 },
        Ring1 = 'ephramad\'s ring',
        Ring2 = 'sroda ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'sailfi belt +1',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'nyame sollerets', Priority = 68 },
    },
    KOR_Hybrid = {},
    KOR_Acc = {},

	Imperator_Default = {
        Ammo = 'crepuscular pebble',
        Head = { Name = 'nyame helm', Priority = 91 },
        Neck = 'rep. plat. medal',
        Ear1 = { Name = 'alabaster Earring', Priority = 100 },
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'sakpata\'s gauntlets', Priority = 91 },
        Ring1 = 'ephramad\'s ring',
        Ring2 = { Name = 'regal ring', Priority = 50 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'sailfi belt +1',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'nyame sollerets', Priority = 68 },
    },
    Imperator_Hybrid = {},
    Imperator_Acc = {},

    Fealty = {
		Sub = 'diamond aspis',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },--2
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
    },
    Sentinel = {
		Sub = 'diamond aspis',
		Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },--2
		Ear2 = 'friomisi earring',
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
        Feet = { Name = 'Cab. Leggings +2', Priority = 53 },
    },
    Bash = {
		Sub = 'aegis',
		Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },--2
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
    },
    Invincible = {
		Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--9
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },
        Ear2 = 'friomisi earring',--2
        Body = { Name = 'souv. cuirass +1', Priority = 66 },--20
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
		},
	de = {
		Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--9
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'alabaster earring', Priority = 100 },
        Ear2 = 'friomisi earring',--2
        Body = { Name = 'souv. cuirass +1', Priority = 66 },--20
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
		},

    Cover = {
        --Head = 'Rev. Coronet +1',
		Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },--2
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
    },
    Rampart = {
		Sub = 'diamond aspis',
		Ammo = 'Sapience Orb',--2
        Head = { Name = 'Cab. Coronet +2', Priority = 106 },
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },--2
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
    },
	circle = {
		Sub = 'diamond aspis',
		Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },--2
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'souv. cuirass +1', Priority = 66 },--20
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
		Feet = { Name = 'rev. leggings +4', Priority = 92 },
		},

	palisade = {
		Sub = 'diamond aspis',
		Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },--2
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'souv. cuirass +1', Priority = 66 },--20
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
		},

	chiv = {
        Head = { Name = 'loess barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },--2',
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'souv. cuirass +1', Priority = 66 },--20
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
		},

    intervene = {
		Sub = 'duban',
		Ammo = 'Sapience Orb',--2
        Head = { Name = 'loess barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'cryptic earring', Priority = 40 },--2
		Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'souv. cuirass +1', Priority = 66 },--20
		Hands = { Name = 'cab. gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'eihwaz ring', Priority = 70 },
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'cab. breeches +4', Priority = 82 },--9
        Feet = { Name = 'chev. sabatons +3', Priority = 52 },--15
		},
    TH = {
        Ammo = 'Per. Lucky Egg',
		Waist = 'Chaac Belt',
	},

    Movement = {
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'chev. armet +3', Priority = 145 },
        Neck = 'unmoving collar +1',
        Ear1 = 'hearty earring',
        Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'sakpata\'s plate', Priority = 136 },
        Hands = { Name = 'regal gauntlets', Priority = 205 },
        Ring1 = 'shneddick ring',
        Ring2 = { Name = 'moonlight ring', Priority = 110 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'carrier\'s sash', Priority = 20 },
        Legs = { Name = 'chev. cuisses +3', Priority = 127 },
        Feet = { Name = 'nyame sollerets', Priority = 68 },
	},

	kite = {
		Main = 'burtgang',
		Sub = 'aegis',
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'chev. armet +3', Priority = 145 },
        Neck = 'unmoving collar +1',
        Ear1 = 'hearty earring',
        Ear2 = { Name = 'alabaster earring', Priority = 100 },
        Body = { Name = 'sakpata\'s plate', Priority = 136 },
        Hands = { Name = 'nyame gauntlets', Priority = 91 },
        Ring1 = 'shneddick ring',
        Ring2 = { Name = 'vexer ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'carrier\'s sash', Priority = 20 },
        Legs = { Name = 'chev. cuisses +3', Priority = 127 },
        Feet = { Name = 'nyame sollerets', Priority = 68 },
	},
    Absorb = {}, -- every Absorb- spell (land rate: Dark Magic skill, macc; potency is not skill)
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
    gcinclude.MainModes = {'None', 'Burtgang', 'Caliburnus'};
    gcinclude.SubModes = {'None', 'Aegis', 'Duban'};
    gcinclude.DefaultWeapons = { Main = 'Burtgang', Sub = 'Aegis' };
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
        local tank = gcdisplay.GetCycle('TankSet');
        if (tank ~= 'None') then gFunc.EquipSet(gcinclude.FindSet('Tank_' .. tank)) end
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
		gFunc.EquipSet(sets.Movement);
    end

    local cover = gcinclude.BuffCount('Cover');
	if (cover >= 1) then
		gFunc.EquipSet(sets.Fealty); -- same set as fealty
	end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end;
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.kite) end;
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    gFunc.EquipSet(sets.Enmity)
	if string.match(ability.Name, 'Fealty') then
		gFunc.EquipSet(sets.Fealty);
    elseif string.match(ability.Name, 'Sentinel') then
		gFunc.EquipSet(sets.Sentinel);
	elseif string.match(ability.Name, 'Divine Emblem') then
		gFunc.EquipSet(sets.de);
    elseif string.match(ability.Name, 'Shield Bash') or string.match(ability.Name, 'Majesty') then
		gFunc.EquipSet(sets.Bash);
    elseif string.match(ability.Name, 'Invincible') then
		gFunc.EquipSet(sets.Invincible);
	elseif string.match(ability.Name, 'Intervene') then
		gFunc.EquipSet(sets.intervene);
    elseif string.match(ability.Name, 'Cover') then
		gFunc.EquipSet(sets.Cover);
	elseif string.match(ability.Name, 'Palisade') then
		gFunc.EquipSet(sets.palisade);
    elseif string.match(ability.Name, 'Rampart') then
		gFunc.EquipSet(sets.Rampart);
	elseif string.match(ability.Name, 'Holy Circle') then
		gFunc.EquipSet(sets.circle);
	elseif string.match(ability.Name, 'Chivalry') then
		gFunc.EquipSet(sets.chiv);
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
    elseif (spell.Skill == 'Healing Magic') then
        gFunc.EquipSet(sets.Cure_Precast);
    end

    gcinclude.CheckCancels();
end

profile.HandleMidcast = function()
    local spell = gData.GetAction();
    gFunc.EquipSet(sets.SIR);
	if string.match(spell.Name, '^Cur[ae]') then -- Cure/Cura/Curaga, not Cursna
        gFunc.EquipSet(sets.Cure);
	elseif string.contains(spell.Name, 'Pro') then
        gFunc.EquipSet(sets.Reprisal);
    elseif string.match(spell.Name, 'Phalanx') then
        gFunc.EquipSet(sets.Phalanx);
    elseif string.match(spell.Name, 'Reprisal') then
        gFunc.EquipSet(sets.Reprisal);
	elseif string.match(spell.Name, 'Stoneskin') then
        gFunc.EquipSet(sets.Stoneskin);
    elseif (spell.Name == 'Absorb-TP') then
        gFunc.EquipSet(sets.Absorb_TP);
    elseif string.match(spell.Name, 'Flash') then
        gFunc.EquipSet(sets.Flash);
    else
        gFunc.EquipSet(sets.Enmity);
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
    elseif string.match(ws.Name, 'Savage Blade') then
        gcinclude.EquipMode('Savage');
	elseif string.match(ws.Name, 'Imperator') then
        gcinclude.EquipMode('Imperator');
    elseif string.match(ws.Name, 'Atonement') then
        gcinclude.EquipMode('Atone');
	elseif string.match(ws.Name, 'Sanguine Blade') then
        gcinclude.EquipMode('sanguine');
	elseif string.match(ws.Name, 'Knights of Round') then
        gcinclude.EquipMode('KOR');
	elseif string.match(ws.Name, 'Shining Blade') or string.match(ws.Name, 'Seraph Blade') or string.match(ws.Name, 'Shining Strike') then
        gcinclude.EquipMode('shining');
    elseif string.match(ws.Name, 'Aeolian Edge') then
        gcinclude.EquipMode('Aedge');
    end
end
return profile;