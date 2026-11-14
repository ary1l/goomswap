local profile = {};
if (gFunc == nil) then error('GoomSwap: GearSwap loaded this job file directly. Windower: move it to data/goomswap/<Name>/<JOB>.lua and delete it from data/<Name>/ (see docs/windower.md)', 0) end
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
-- gcinclude.Food = {'Grape Daifuku +1'}; -- this job's food: /packer keeps a stack of each (replaces the Food setting / char.lua's)
-- gcinclude.Packer = { ['Echo Drops'] = 'stack', ['Holy Water'] = 'stack' }; -- kept in inventory on job change (/packer, Bellhop plugin)
gcinclude.settings.WeaponTPGuard = 100; -- weapons held from 100 TP, so soda TP survives JAs; 0 = always swap
-- gcinclude.CureObi = true; -- uncomment: Hachirin-no-Obi on Cure/Cura/Curaga in Light day/weather (Aurorastorm counts)
gcinclude.SIRSkip = T{'Phalanx','Reprisal'}; -- /sir leaves these midcasts alone, on top of the default Absorb-TP and Stun


local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Main = 'Burtgang',
        Sub = 'Aegis',
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Chev. Armet +3', Priority = 145 },
        Neck = 'Unmoving Collar +1',
        Ear1 = 'Spellbr. Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Chev. Cuirass +3', Priority = 151 },
        Hands = { Name = 'Chev. Gauntlets +3', Priority = 64 },
        Ring1 = 'Shadow Ring',
        Ring2 = 'Fortified Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'Carrier\'s Sash', Priority = 20 },
        Legs = { Name = 'Chev. Cuisses +3', Priority = 127 },
        Feet = { Name = 'Rev. Leggings +4', Priority = 92 },
    },
    Resting = {},
    Idle_Regen = {
        --Head = 'volte salade',
        Neck = 'Coatl Gorget +1',
        --Ear1 = 'Infused Earring',
        Hands = { Name = 'Regal Gauntlets', Priority = 205 },
        Ring1 = 'Chirich Ring +1',
        Waist = 'Null Belt',
    },
    Idle_Refresh = {
        --Ammo = 'Homiliary',
        --Head = 'Jumalik Helm',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
    },
    Idle_Regain = { -- /idleset regain: over Idle while idle
    },
    Town = {
        Main = 'Burtgang',
        Sub = 'Duban',
        Range = 'Ullr',
        Ammo = 'Chapuli Arrow',
        Head = { Name = 'Chev. Armet +3', Priority = 145 },
        Neck = 'Coatl Gorget +1',
        Ear1 = 'Hearty Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Adamantite Armor', Priority = 182 },
        Hands = { Name = 'Regal Gauntlets', Priority = 205 },
        Ring1 = 'Shneddick Ring',
        Ring2 = 'Stikini Ring +1',
        Waist = 'Plat. Mog. Belt',
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },
        Feet = { Name = 'Rev. Leggings +4', Priority = 92 },
    },

    mdt = {
        Main = 'Burtgang',
        Sub = 'Aegis',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Coatl Gorget +1',
        Ear1 = 'Spellbr. Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Adamantite Armor', Priority = 182 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = 'Shadow Ring',
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'Carrier\'s Sash', Priority = 20 },
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    Aminon = {
        Main = 'Caliburnus',
        Sub = 'Aegis',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Coatl Gorget +1',
        Ear1 = 'Spellbr. Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Adamantite Armor', Priority = 182 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = 'Shadow Ring',
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'Carrier\'s Sash', Priority = 20 },
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },

    Dt = {
        Main = 'Burtgang',
        Sub = 'Duban',
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Chev. Armet +3', Priority = 145 },
        Neck = 'Warder\'s Charm +1',
        Ear1 = 'Hearty Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Adamantite Armor', Priority = 182 },
        Hands = { Name = 'Chev. Gauntlets +3', Priority = 64 },
        Ring1 = 'Shadow Ring',
        Ring2 = 'Fortified Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'Carrier\'s Sash', Priority = 20 },
        Legs = { Name = 'Chev. Cuisses +3', Priority = 127 },
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },
    },

    Tp_Default = {
        Ammo = 'Coiste Bodhar',
        Head = { Name = 'Sakpata\'s Helm', Priority = 91 },
        Neck ={ Name = 'Null Loop', Priority = 50 },
        Ear1 = 'Telos Earring',
        Ear2 = 'Cessance Earring',
        Body = { Name = 'Sakpata\'s Plate', Priority = 136 },
        Hands = { Name = 'Sakpata\'s Gauntlets', Priority = 91 },
        Ring1 = 'Chirich Ring +1',
        Ring2 = { Name = 'Moonlight Ring', Priority = 110 },
        Back = 'Null Shawl',
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Sakpata\'s Cuisses', Priority = 114 },
        Feet = { Name = 'Sakpata\'s Leggings', Priority = 68 },
    },
    Tp_SubtleBlow = { -- /mset subtleblow: Subtle Blow pieces over Tp_Default
    },
    Tp_Acc = {
        Ring2 = 'Cacoethic Ring +1',
    },

    --These will overwrite any above TP profile.Sets if /tankset is used
    Tank_Main = {--Default Tanking,  dt
        Ammo = 'Coiste Bodhar',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Unmoving Collar +1',
        Ear1 = 'Tuisto Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = 'Petrov Ring',
        Ring2 = { Name = 'Moonlight Ring', Priority = 110 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
        },

    Tank_MEVA = {
        Ammo = 'Vanir Battery',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Moonlight Necklace',
        Ear1 = { Name = 'Eabani Earring', Priority = 45 },
        Ear2 = 'Chev. Earring +1',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = { Name = 'Vexer Ring +1', Priority = 55 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'Carrier\'s Sash', Priority = 20 },
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    Midcast = {},

    Precast = { --47FC
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Chev. Armet +3', Priority = 145 },--9
        Neck = 'Voltsurge Torque',--4
        Ear1 = 'Loquac. Earring', --2
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Rev. Surcoat +4', Priority = 264 },--10
        Hands = { Name = 'Leyline Gloves', Priority = 25 },--6
        Ring1 = 'Murky Ring',
        Ring2 = 'Kishar Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = '"Fast Cast"+10', [2] = 'Phys. dmg. taken -10%', [3] = 'Mag. Evasion+30', [4] = 'HP+60', [5] = 'Evasion+20' }, Priority = 60 },
        Waist = 'Plat. Mog. Belt',
        Legs = { Name = 'Odyssean Cuisses', Priority = 54 },--6
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--7
    },
    ['Healing Magic_Precast'] = {
        --Ear1 = 'Nourish. Earring +1',
        Ear2 = 'Mendi. Earring',
    },
    ['Enhancing Magic_Precast'] = {
        Body = { Name = 'Shab. Cuirass +1', Priority = 115 },
        Hands = { Name = 'Regal Gauntlets', Priority = 205 },
        Waist = 'Siegel Sash',
    },
    SIR = {
        Ammo = 'Staunch Tathlum +1',--11
        Head = { Name = 'Souv. Schaller +1', Priority = 175 },
        Neck = 'Moonlight Necklace',--15
        Ear1 = 'Tuisto Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Chev. Cuirass +3', Priority = 151 },--20
        Hands = { Name = 'Regal Gauntlets', Priority = 205 }, --10
        Ring1 = 'Murky Ring',--3
        Ring2 = { Name = 'Moonlight Ring', Priority = 110 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = 'Audumbla Sash',--10
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--10
        Feet = { Name = 'Odyssean Greaves', Priority = 20 },
    },
    Enmity = {
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Souv. Cuirass +1', Priority = 66 },--20
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },--5
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },--4
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = 'Plat. Mog. Belt',
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
    },

    Cure = {  --98% SIR(capped w merits) 39%/50% CurePot, 25%/30%CurePot2 w Majesty
        Ammo = 'Staunch Tathlum +1', --10SIR
        Head = { Name = 'Souv. Schaller +1', Priority = 175 }, --15rec/20SIR
        Neck = 'Moonlight Necklace',--15SIR
        Ear1 = 'Mendi. Earring', --5
        Ear2 = 'Chev. Earring +1', --11
        Body = { Name = 'Chev. Cuirass +3', Priority = 151 },--20SIR
        Hands = { Name = 'Macabre Gaunt. +1', Priority = 29 }, --11
        Ring1 = 'Murky Ring',--3SIR
        Ring2 = 'Defending Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = 'Plat. Mog. Belt',
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--10SIR
        Feet = { Name = 'Odyssean Greaves', Priority = 20 },--12/20SIR
    },

    Phalanx = { -- +36phalanx received
        Main = { Name = 'Sakpata\'s Sword', Priority = 100 }, --5
        Sub = { Name = 'Priwen', Priority = 30 }, --3
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Valorous Mask', Priority = 38 },--4
        Neck = 'Moonlight Necklace',
        Ear1 = 'Tuisto Earring',
        Ear2 = 'Odnowa Earring +1',
        Body = { Name = 'Valorous Mail', Priority = 61 },--4
        Hands = { Name = 'Souv. Handsch. +1', Priority = 134 }, --5
        Ring1 = 'Murky Ring',
        Ring2 = { Name = 'Moonlight Ring', Priority = 110 },
        Back = { Name = 'Weard Mantle', Priority = 40 }, --5
        Waist = 'Audumbla Sash',
        Legs = { Name = 'Sakpata\'s Cuisses', Priority = 114 }, --5
        Feet = { Name = 'Souveran Schuhs +1', Priority = 122 }, --5
    },

    Stoneskin = {
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Chev. Armet +3', Priority = 145 },
        Neck = 'Stone Gorget',
        Ear1 = 'Earthcry Earring',
        Ear2 = 'Odnowa Earring +1',
        Body = { Name = 'Rev. Surcoat +4', Priority = 264 },
        Hands = { Name = 'Stone Mufflers', Priority = 10 },
        Ring1 = { Name = 'Moonlight Ring', Priority = 110 },
        Ring2 = 'Defending Ring',
        Back = { Name = 'Moonbeam Cape', Priority = 250 },
        Waist = 'Siegel Sash',
        Legs = 'Haven Hose',
        Feet = { Name = 'Sakpata\'s Leggings', Priority = 68 },
    },

    Reprisal = { --105 SIR
        Ammo = 'Staunch Tathlum +1',--10
        Head = { Name = 'Souv. Schaller +1', Priority = 175 },--20
        Neck = 'Moonlight Necklace', --15
        Ear1 = 'Tuisto Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Shab. Cuirass +1', Priority = 115 },
        Hands = { Name = 'Regal Gauntlets', Priority = 205 },--20
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Moonlight Ring', Priority = 110 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = 'Audumbla Sash',--10
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--10
        Feet = { Name = 'Odyssean Greaves', Priority = 20 },--20
    },

    Protect = { --105 SIR
        Ammo = 'Staunch Tathlum +1',--10
        Head = { Name = 'Souv. Schaller +1', Priority = 175 },--20
        Neck = 'Moonlight Necklace', --15
        Ear1 = 'Tuisto Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Shab. Cuirass +1', Priority = 115 },
        Hands = { Name = 'Regal Gauntlets', Priority = 205 },--20
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Moonlight Ring', Priority = 110 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = 'Audumbla Sash',--10
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--10
        Feet = { Name = 'Odyssean Greaves', Priority = 20 },--20
    },

    Absorb_TP = { -- /sir never goes over this (settings.SIRSkip); /aminon's weapons stay
        Head = { Name = 'Chev. Armet +3', Priority = 145 },
        Neck = { Name = 'Null Loop', Priority = 50 },
        Ear1 = { Name = 'Alabaster Earring', Priority = 100 },
        Ear2 = 'Chev. Earring +1',
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
        Ammo = 'Sapience Orb',
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },
        Neck = 'Moonlight Necklace',
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Rev. Surcoat +4', Priority = 264 },
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'Creed Baudrier', Priority = 40 },
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
    },

    Preshot = {
        Range = 'Ullr',
        Ammo = 'Chapuli Arrow',
        },

    Midshot = {
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = { Name = 'Sanctity Necklace', Priority = 35 },
        Ear1 = 'Telos Earring',
        Ear2 = 'Enervating Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = { Name = 'Regal Ring', Priority = 50 },
        Ring2 = 'Petrov Ring',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    Midshot_Acc = { -- /rangedset acc: over Midshot
    },

    Ws_Default = {
        Ammo = 'Coiste Bodhar',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Rep. Plat. Medal',
        Ear1 = 'Thrud Earring',
        Ear2 = 'Cessance Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = 'Petrov Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    Ws_Acc = {
    },
    ['Chant du Cygne'] = {
        Ammo = 'Coiste Bodhar',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Rep. Plat. Medal',
        Ear1 = 'Telos Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = { Name = 'Regal Ring', Priority = 50 },
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    ['Chant du Cygne_Acc'] = {
    },
    ['Savage Blade'] = {
        Ammo = 'Coiste Bodhar',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Rep. Plat. Medal',
        Ear1 = 'Thrud Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = { Name = 'Regal Ring', Priority = 50 },
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    ['Savage Blade_Acc'] = {
    },
    Atonement = {
        Ammo = 'Sapience Orb',
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },
        Ear2 = 'Odnowa Earring +1',
        Body = { Name = 'Rev. Surcoat +4', Priority = 264 },
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },--5
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },--4
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Mag. Eva.+20', [3] = 'Eva.+20', [4] = 'HP+60', [5] = 'Enmity+10' }, Priority = 60 },
        Waist = { Name = 'Creed Baudrier', Priority = 40 },
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },
    },
    Atonement_Acc = {
    },
    ['Aeolian Edge'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Sibyl Scarf',
        Ear1 = 'Crematio Earring',
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = { Name = 'Regal Ring', Priority = 50 },
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Orpheus\'s Sash',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    ['Aeolian Edge_Acc'] = {},

    ['Sanguine Blade'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = { Name = 'Pixie Hairpin +1', Priority = -35 },
        Neck = 'Sibyl Scarf',
        Ear1 = 'Regal Earring',
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = 'Archon Ring',
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Orpheus\'s Sash',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    ['Sanguine Blade_Acc'] = {},

    ['Shining Blade'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Sibyl Scarf',
        Ear1 = 'Crematio Earring',
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = { Name = 'Regal Ring', Priority = 50 },
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Orpheus\'s Sash',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },

    ['Shining Strike'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Sibyl Scarf',
        Ear1 = 'Crematio Earring',
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = { Name = 'Regal Ring', Priority = 50 },
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Orpheus\'s Sash',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },

    ['Seraph Blade'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Sibyl Scarf',
        Ear1 = 'Crematio Earring',
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = { Name = 'Regal Ring', Priority = 50 },
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Orpheus\'s Sash',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    ['Shining Blade_Acc'] = {},
    ['Shining Strike_Acc'] = {},
    ['Seraph Blade_Acc'] = {},

    ['Knights of Round'] = {
        Ammo = 'Crepuscular Pebble',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Fotia Gorget',
        Ear1 = 'Thrud Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Sakpata\'s Gauntlets', Priority = 91 },
        Ring1 = 'Sroda Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    ['Knights of Round_Acc'] = {},

    Imperator = {
        Ammo = 'Coiste Bodhar',
        Head = { Name = 'Nyame Helm', Priority = 91 },
        Neck = 'Rep. Plat. Medal',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Nyame Mail', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = { Name = 'Regal Ring', Priority = 50 },
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = { Name = 'Nyame Flanchard', Priority = 114 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    Imperator_Acc = {},

    Fealty = {
        Sub = 'Diamond Aspis',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
    },
    Sentinel = {
        Sub = 'Diamond Aspis',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2
        Ear2 = 'Friomisi Earring',
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Cab. Leggings +2', Priority = 53 },
    },
    ['Shield Bash'] = {
        Sub = 'Aegis',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
    },
    Majesty = {
        Sub = 'Aegis',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
    },
    Invincible = {
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--9
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },
        Ear2 = 'Friomisi Earring',--2
        Body = { Name = 'Souv. Cuirass +1', Priority = 66 },--20
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
        },
    ['Divine Emblem'] = {
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--9
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Alabaster Earring', Priority = 100 },
        Ear2 = 'Friomisi Earring',--2
        Body = { Name = 'Souv. Cuirass +1', Priority = 66 },--20
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
        },

    Cover = {
        --Head = 'Rev. Coronet +1',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
    },
    Rampart = {
        Sub = 'Diamond Aspis',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Cab. Coronet +2', Priority = 106 },
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Cab. Surcoat +4', Priority = 148 },
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
    },
    ['Holy Circle'] = {
        Sub = 'Diamond Aspis',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Souv. Cuirass +1', Priority = 66 },--20
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Rev. Leggings +4', Priority = 92 },
        },

    Palisade = {
        Sub = 'Diamond Aspis',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Souv. Cuirass +1', Priority = 66 },--20
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
        },

    Chivalry = {
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Souv. Cuirass +1', Priority = 66 },--20
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
        },

    Intervene = {
        Sub = 'Duban',
        Ammo = 'Sapience Orb',--2
        Head = { Name = 'Loess Barbuta +1', Priority = 105 },--19
        Neck = 'Moonlight Necklace', -- 15
        Ear1 = { Name = 'Cryptic Earring', Priority = 40 },--2
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Souv. Cuirass +1', Priority = 66 },--20
        Hands = { Name = 'Cab. Gauntlets +4', Priority = 134 },--9
        Ring1 = { Name = 'Eihwaz Ring', Priority = 70 },
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Creed Baudrier', Priority = 40 },--5
        Legs = { Name = 'Cab. Breeches +4', Priority = 82 },--9
        Feet = { Name = 'Chev. Sabatons +3', Priority = 52 },--15
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
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
    },

    Movement = {
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Chev. Armet +3', Priority = 145 },
        Neck = 'Unmoving Collar +1',
        Ear1 = 'Hearty Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Sakpata\'s Plate', Priority = 136 },
        Hands = { Name = 'Regal Gauntlets', Priority = 205 },
        Ring1 = 'Shneddick Ring',
        Ring2 = { Name = 'Moonlight Ring', Priority = 110 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Carrier\'s Sash', Priority = 20 },
        Legs = { Name = 'Chev. Cuisses +3', Priority = 127 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },

    kite = {
        Main = 'Burtgang',
        Sub = 'Aegis',
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Chev. Armet +3', Priority = 145 },
        Neck = 'Unmoving Collar +1',
        Ear1 = 'Hearty Earring',
        Ear2 = { Name = 'Alabaster Earring', Priority = 100 },
        Body = { Name = 'Sakpata\'s Plate', Priority = 136 },
        Hands = { Name = 'Nyame Gauntlets', Priority = 91 },
        Ring1 = 'Shneddick Ring',
        Ring2 = { Name = 'Vexer Ring +1', Priority = 55 },
        Back = { Name = 'Rudianos\'s Mantle', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'Evasion+20', [3] = 'HP+60', [4] = 'Mag. Evasion+30', [5] = 'Enmity+10' }, Priority = 60 }, --10
        Waist = { Name = 'Carrier\'s Sash', Priority = 20 },
        Legs = { Name = 'Chev. Cuisses +3', Priority = 127 },
        Feet = { Name = 'Nyame Sollerets', Priority = 68 },
    },
    -- Templates: fill the ones you use; an empty set changes nothing.
    Proc = {}, -- /proc: low-damage gear for proc windows (Abyssea, Vagary...), over the engaged sets
    Ws_Proc = {}, -- /proc on weapon skills (empty: Proc)
    Ws_HighBuff = {}, -- /wsset high: over Ws_Default (PDL)
    ['Savage Blade_HighBuff'] = {}, -- /wsset high: this WS
    Buffs = { -- while the buff is up: idle and engaged
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Ws = { -- while the buff is up: weapon skills
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Midcast = { -- while the buff is up: spells (e.g. ['Saboteur'])
    },
    -- Weapon_Example_Acc = { Main = 'Item Name' }, -- /mset acc: a whole weapon set in place of Weapon_Example
    -- Weapon_Example_1h = { Main = 'Item Name', Sub = 'Shield Name' }, -- when you can't dual wield (/dw off, sub not NIN/DNC)
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

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.MainModes = {'None', 'Burtgang', 'Caliburnus'};
    gcinclude.SubModes = {'None', 'Aegis', 'Duban'}; -- shields: /subset cycles them, /subset duban picks one (add force at 1000+ TP)
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
    gcinclude.EquipIdle(); -- Idle, then Idle_<mode> (/idleset)

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
    gFunc.EquipSet(sets.Enmity); -- PLD: enmity under every ability
    ByName(ability.Name); -- a set named after the ability, e.g. ['Sentinel']
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
    -- a set named after the spell or its family (['Cure'], ['Protect'], ['Phalanx'], ['Flash']); none: Enmity
    if not (ByName(spell.Name) or ByName(Family(spell.Name))) then gFunc.EquipSet(sets.Enmity) end
    gcinclude.CheckTH();
end

profile.HandlePreshot = function()
    gFunc.EquipSet(sets.Preshot);
end

profile.HandleMidshot = function()
    gFunc.EquipSet(sets.Midshot);
    if gcinclude.RangedAcc() then gFunc.EquipSet(sets.Midshot_Acc) end -- /rangedset acc
    gcinclude.CheckTH();
end

profile.HandleWeaponskill = function()
    if (gcinclude.CheckWsBailout() == false) then gFunc.CancelAction(); return end
    local ws = gData.GetAction();
    gcinclude.EquipMode('Ws');
    ByName(ws.Name); -- e.g. ['Savage Blade'], then ['Savage Blade_<mset>']
end
return profile;
