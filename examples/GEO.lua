local profile = {};
if (gFunc == nil) then error('GoomSwap: GearSwap loaded this job file directly. Windower: move it to data/goomswap/<Name>/<JOB>.lua and delete it from data/<Name>/ (see README Install)', 0) end
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
-- gcinclude.Food = {'Grape Daifuku +1'}; -- this job's food: /packer keeps a stack of each (replaces the Food setting / char.lua's)
-- gcinclude.Packer = { ['Echo Drops'] = 'stack', ['Holy Water'] = 'stack' }; -- kept in inventory on job change (/packer, Bellhop plugin)
gcinclude.settings.SmartSwap = false; -- always swap to the casting weapons: TP isn't used on this job
gcinclude.settings.WeaponTPGuard = 0; -- no 1000+ TP weapon hold either (nukes, Dark, Divine swap too)
gcinclude.CureObi = true; -- Hachirin-no-Obi on Cure/Cura/Curaga in Light day/weather (Aurorastorm counts); false = never
local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Main = 'idris',
        Sub = 'Genmei Shield',
        Range = 'Dunna',
        Head = 'azimuth hood +3',
        Neck = 'loricate torque +1',
        Ear1 = 'alabaster Earring',
        Ear2 = 'lugalbanda Earring',
        Body = 'shamash robe',
        Hands = 'nyame gauntlets',
        Ring1 = 'murky ring',
        Ring2 = 'gurebu\'s ring',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Mag. Evasion+30', [2] = 'HP+60', [3] = 'Pet: "Regen"+15', [4] = 'Evasion+20' } },
        Waist = 'carrier\'s sash',
        Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },
    Idle_Pet = {
        Main = 'idris',
        Sub = 'Genmei Shield',
        Range = 'Dunna',
        Head = 'Azimuth Hood +3',
        Neck = 'bagua charm +2',
        Ear1 = 'alabaster Earring',
        Ear2 = 'lugalbanda earring',
        Body = 'shamash robe',
        Hands = 'Geo. Mitaines +4',
        Ring1 = 'murky ring',
        Ring2 = 'gurebu\'s ring',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Mag. Evasion+30', [2] = 'HP+60', [3] = 'Pet: "Regen"+15', [4] = 'Evasion+20' } },
        Waist = 'Isa Belt',
        Legs = 'nyame flanchard',
        Feet = 'bagua sandals +3',
    },
	    Pet_Dt = {
        Main = 'idris',
        Sub = 'Genmei Shield',
        Range = 'Dunna',
        Head = 'Azimuth Hood +3',
        Neck = 'bagua charm +2',
        Ear1 = 'alabaster earring',
		Ear2 = 'lugalbanda earring',
        Body = 'shamash robe',
        Hands = 'Geo. Mitaines +4',
        Ring1 = 'murky ring',
        Ring2 = 'gurebu\'s ring',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Mag. Evasion+30', [2] = 'HP+60', [3] = 'Pet: "Regen"+15', [4] = 'Evasion+20' } },
        Waist = 'Isa Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'bagua sandals +3',
    },
    Resting = {},
    Idle_Regen = {
        Ring2 = 'Chirich Ring +1',
		Waist = 'null belt',
    },
    Idle_Refresh = {
        Main = 'Bolelabunga',
		Head = 'volte beret',
		Neck = 'sibyl scarf',
        Body = 'shamash robe',
        Hands = 'bagua mitaines +3',
		Ring1 = 'gurebu\'s ring',
		Ring2 = 'stikini ring +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'volte brais',
    },
    Idle_Regain = { -- /idleset regain: over Idle while idle
    },
    Town = {
		Main = 'idris',
		Sub = 'chanter\'s shield',
		Range = 'dunna',
		Head = 'azimuth hood +3',
		Neck = 'sibyl scarf',
        Body = 'shamash robe',
        Hands = 'Geo. Mitaines +4',
		Ring2 = 'gurebu\'s ring',
		Waist = 'carrier\'s sash',
        Legs = 'geo. pants +4',
        Feet = 'geo. sandals +4',
    },

    Dt = {
        Head = 'azimuth hood +3',
        Neck = 'loricate torque +1',
        Ear1 = 'alabaster earring',
		Ear2 = 'lugalbanda earring',
        Body = 'shamash robe',
        Hands = 'azimuth gloves +2',
        Ring1 = 'murky Ring',
        Ring2 = 'Defending Ring',
        Back = 'null shawl',
        Waist = 'carrier\'s sash',
        Legs = 'Nyame Flanchard',
        Feet = 'nyame sollerets',
    },
    Sleeping = { -- worn while asleep over the /def set and Incapacitated, past the TP hold: stage 2 Lorg Mor "Slowly devours your soul" (HP/MP drain wakes you); stages 3+ don't drain
        Main = 'Lorg Mor',
    },
    SIR = {
        Head = 'azimuth hood +3',
        Neck = 'loricate torque +1',
        Ear1 = 'alabaster Earring',
        Ear2 = 'lugalbanda Earring',
        Body = 'shamash robe',
        Hands = 'nyame gauntlets',
        Ring1 = 'murky ring',
        Ring2 = 'gurebu\'s ring',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Mag. Evasion+30', [2] = 'HP+60', [3] = 'Pet: "Regen"+15', [4] = 'Evasion+20' } },
        Waist = 'carrier\'s sash',
        Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },
    Weapon_Idris = {
        Main = 'Idris',
        Sub = 'Bunzi\'s Rod',
        Range = 'Dunna',
    },
    Weapon_Idris_1h = {
        Main = 'Idris',
        Sub = 'Genmei Shield',
        Range = 'Dunna',
    },
    Weapon_Maxentius = {
        Main = 'Maxentius',
        Sub = 'Bunzi\'s Rod',
        Range = 'Dunna',
    },
    Weapon_Maxentius_1h = {
        Main = 'Maxentius',
        Sub = 'Genmei Shield',
        Range = 'Dunna',
    },
    Weapon_Tishtrya = {
        Main = 'Tishtrya',
        Sub = 'Bunzi\'s Rod',
        Range = 'Dunna',
    },
    Weapon_Tishtrya_1h = {
        Main = 'Tishtrya',
        Sub = 'Genmei Shield',
        Range = 'Dunna',
    },
    Tp_Default = {
        Main = 'idris',
        Sub = 'Ammurapi Shield',
        Range = 'Dunna',
		Ammo = 'displaced',
        Head = 'nyame helm',
        Neck = 'Sanctity Necklace',
        Ear1 = 'alabaster Earring',
        Ear2 = 'brutal Earring',
        Body = 'nyame mail',
        Hands = 'nyame gauntlets',
        Ring1 = 'murky Ring',
        Ring2 = 'Chirich Ring +1',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Mag. Evasion+30', [2] = 'HP+60', [3] = 'Pet: "Regen"+15', [4] = 'Evasion+20' } },
        Waist = 'cornelia\'s belt',
        Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },
    Tp_SubtleBlow = { -- /mset subtleblow: Subtle Blow pieces over Tp_Default
    },
    Tp_Acc = {
        --Head = 'Blistering Sallet +1',
        --Ear1 = 'Mache Earring +1',
        --Ring1 = 'Cacoethic Ring +1',
        --Ring2 = 'Chirich Ring +1',
        --Back = 'Aurist\'s Cape +1',
    },
    Midcast = {},


    Precast = {
        Main = 'idris',
		Sub = 'chanter\'s shield',--3
        Range = 'Dunna',--3
		Ammo = 'displaced',
        Head = 'volte beret',--6
        Neck = 'voltsurge torque',--4
        Ear1 = 'loquac. Earring',--2
        Ear2 = 'malignance earring',--4
        Body = 'indomitable coat',--10
        Hands = 'volte gloves',--6
        Ring1 = 'weather. ring',--5
        Ring2 = 'Kishar Ring',--4
        Back = 'fi follet cape +1',--10
        Waist = 'witful belt',--3
        Legs = 'geo. pants +4',--15
        Feet = 'indom. sabots',--4
    },
    ['Healing Magic_Precast'] = {
		Ear2 = 'Mendi. Earring',
    },
    ['Enhancing Magic_Precast'] = {
        Waist = 'Siegel Sash',
    },
    Stoneskin_Precast = {
        Head = 'Umuthi Hat',
        --Hands = 'Carapacho Cuffs',
        Waist = 'Siegel Sash',
    },


    ['Healing Magic'] = {--I cap is 50, II cap is 30
        Main = 'bunzi\'s rod',--30
        Sub = 'genmei Shield',
		Head = 'nyame helm',
        Neck = 'loricate torque +1',
        Ear1 = 'alabaster earring',
        Ear2 = 'mendi. Earring',--5
		Body = 'annoint. kalasiris',--10
        Hands = 'nyame gauntlets',
        Ring1 = 'murky ring',
        Ring2 = 'gurebu\'s ring',
        Back = 'Solemnity cape',--7
        Waist = 'witful belt',
		Legs = 'geo. pants +4',
        Feet = 'nyame sollerets',
    },
    Self_Cure = {--cap 30
        Waist = 'Gishdubar Sash',
    },
    -- Cure/Cura/Curaga midcast, lowest to highest (later wins per slot):
    --   Cure -> Self_Cure (on you) -> Cure_LowMP or Cure_LowMP_Storm (MP <= 50%) -> Cure_Dt (/dt on)
    --   -> engine: Hachirin-no-Obi (Light day/weather) -> SIR set (/sir on) last. Empty sets change nothing.
    -- Main/Sub in these? Add gcinclude.settings.KeepWeaponsFor = T{}; to OnLoad (see WHM.lua).
    Cure_LowMP = { -- MP <= 50%, no Light weather
    },
    Cure_LowMP_Storm = { -- MP <= 50%, Light weather: a SCH's Aurorastorm or natural Light
    },
    Cure_Dt = { -- /dt on: DT pieces to trade in while curing
    },
    Regen = {
        Main = 'Bolelabunga',
        Sub = 'Ammurapi Shield',
        Body = 'Telchine Chas.',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Telchine Pigaches',
    },
    Cursna = {
		Neck = 'debilis medallion',
        Ring1 = 'haoma\'s Ring',
		Waist = 'Gishdubar Sash',
        Feet = 'Vanya Clogs',
    },

    ['Enhancing Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'telchine Cap',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Body = 'Telchine Chas.',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'murky ring',
        Ring2 = 'stikini ring +1',
        Back = 'Solemnity Cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Telchine Pigaches',
    },
    Stoneskin = {
        Neck = 'Nodens Gorget',
        Waist = 'Siegel Sash',
    },
    Phalanx = {},
    Refresh = {
		Waist = 'Gishdubar Sash',
    },
    Geomancy = { --900 skill, then indi duration, then CMP
        Main = 'idris',
        Range = 'Dunna',
		Ammo = 'displaced',
        Head = 'azimuth hood +3',
        Neck = 'Bagua Charm +2',
		Ear1 = 'alabaster earring',
        Ear2 = 'Mendi. Earring',
        Body = 'bagua tunic +3',
        Hands = 'Geo. Mitaines +4',--15
        Ring1 = 'weather. Ring',
        Ring2 = 'Stikini Ring +1',--8
		Back = 'lifestream cape',
		Waist = 'embla sash',
        --Waist = 'Hachirin-no-Obi',
        Legs = 'geo. pants +4',
        Feet = 'azimuth gaiters +3',
    },
    Indi = { --900 skill, then indi duration, then CMP
        Main = 'idris',
        Range = 'Dunna',
		Ammo = 'displaced',
        Head = 'azimuth hood +3',
        Neck = 'Bagua Charm +2',
		Ear1 = 'alabaster earring',
        Ear2 = 'Mendi. Earring',
        Body = 'bagua tunic +3',
        Hands = 'Geo. Mitaines +4',--15
        Ring1 = 'weather. Ring',
        Ring2 = 'Stikini Ring +1',--8
		Back = 'lifestream cape',
		Waist = 'embla sash',
        --Waist = 'Hachirin-no-Obi',
        Legs = 'bagua pants +4',
        Feet = 'azimuth gaiters +3',
    },

    ['Enfeebling Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'azimuth hood +3',
        Neck = 'Erra Pendant',
        Ear1 = 'Digni. Earring',
        Ear2 = 'Malignance Earring',
        --Ear2 = 'Regal Earring',--use this when u upgrade the AF
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'weather. Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Acuity Belt +1',
        Legs = 'Agwu\'s Slops',
        Feet = 'Medium\'s Sabots',
    },
    Macc = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Erra Pendant',
        Ear1 = 'Digni. Earring',
        Ear2 = 'Malignance Earring',
        --Ear2 = 'Regal Earring',--use this when u upgrade the AF
        Body = 'Agwu\'s Robe',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Acuity Belt +1',
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },

    Drain = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Bagua Galero +1',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Agwu\'s Robe',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Kishar Ring',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },

    Aspir = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Bagua Galero +1',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Agwu\'s Robe',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Kishar Ring',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Agwu\'s Slops',
        Feet = 'Agwu\'s Pigaches',
    },

    ['Elemental Magic'] = {
        Main = 'Bunzi\'s rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'hydrocera',
        Head = 'Azimuth Hood +3',
        Neck = 'sibyl scarf',
        Ear1 = 'Malignance Earring',
        Ear2 = 'lugalbanda Earring',
        Body = 'Azimuth Coat +3',
        Hands = 'azimuth gloves +2',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'stikini ring +1',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'INT+30', [3] = 'Mag. Acc.+20', [4] = 'Pet: Damage taken -5%', [5] = 'Magic Damage+20' } },
        Waist = 'null Belt',
        Legs = 'bagua pants +4',
        Feet = 'azimuth gaiters +3',
    },
    NukeACC = {
        Waist = 'Acuity Belt +1',
    },
    OccultAcumen = { -- /nukeset oa: Occult Acumen / Store TP pieces, over Nuke and Burst (TP from nukes)
    },
    Burst = {
        Main = 'Bunzi\'s Rod', --10 and 0
        Sub = 'Ammurapi Shield',
        Head = 'Ea Hat', -- 6 and 6
        Body = 'Ea Houppelande', -- 8 and 8
        Hands = 'Amalric Gages +1', -- 0 and 6
        Ring2 = 'Mujin Band', -- 0 and 5
        Waist = 'Acuity Belt +1',
        Legs = 'Agwu\'s Slops', -- 9 and 0
        Feet = 'Ea Pigaches', -- 4 and 4
    },
    Mp_Body = {Body = 'Seidr Cotehardie',},

    Preshot = {
    },
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },

    Ws_Default = {
        Ammo = 'oshasha\'s treatise',
        Head = 'Nyame Helm',
        Neck = 'rep. plat. medal',
        Ear1 = 'alabaster Earring',
        Ear2 = 'ishvara Earring',
        Body = 'egbesu frock',
        Hands = 'Jhakri Cuffs +2',
        Ring1 = 'metamor. ring +1',
        Ring2 = 'gurebu\'s ring',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Pet: Damage taken -5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = 'MND+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'cornelia\'s belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Ws_Acc = {
    },

	['Black Halo'] = {
        Ammo = 'Oshasha\'s Treatise',
        Head = 'Nyame Helm',
        Neck = 'rep. plat. medal',
		Ear1 = 'alabaster earring',
        Ear2 = 'ishvara Earring',
        Body = 'egbesu frock',
        Hands = 'jhakri cuffs +2',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'gurebu\'s Ring',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Pet: Damage taken -5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = 'MND+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'cornelia\'s belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Black Halo_Acc'] = {
    },
    ['Aeolian Edge'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'nyame helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'egbesu frock',
        Hands = 'Jhakri Cuffs +2',
        Ring1 = 'Shiva Ring +1',
        Ring2 = 'Karieyh Ring +1',
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Aeolian Edge_Acc'] = {
    },
    -- Exudation (Idris): physical, attack varies with TP (FFXIclopedia). Stat mods not published
    -- on FFXIclopedia/BG snippets I could reach, so this starts as Ws_Default; tune it.
    Exudation = {
        Ammo = 'oshasha\'s treatise',
        Head = 'Nyame Helm',
        Neck = 'rep. plat. medal',
        Ear1 = 'alabaster Earring',
        Ear2 = 'ishvara Earring',
        Body = 'egbesu frock',
        Hands = 'Jhakri Cuffs +2',
        Ring1 = 'metamor. ring +1',
        Ring2 = 'gurebu\'s ring',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Pet: Damage taken -5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = 'MND+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'cornelia\'s belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Exudation_Acc = {
    },
    -- Judgment: physical single hit, STR + MND mods, damage varies with TP. Same profile as Black Halo.
    Judgment = {
        Ammo = 'Oshasha\'s Treatise',
        Head = 'Nyame Helm',
        Neck = 'rep. plat. medal',
        Ear1 = 'alabaster earring',
        Ear2 = 'ishvara Earring',
        Body = 'egbesu frock',
        Hands = 'jhakri cuffs +2',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'gurebu\'s Ring',
        Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Pet: Damage taken -5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = 'MND+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'cornelia\'s belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Judgment_Acc = {
    },
    -- Shining Strike / Seraph Strike: magical, light, STR + MND mods; INT still counts (dINT term).
    -- Starts as your Aedge (MAB) set. Obi/Orpheus added by the engine (both are in ElementalWS).
    ['Seraph Strike'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'nyame helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'egbesu frock',
        Hands = 'Jhakri Cuffs +2',
        Ring1 = 'weather. ring',
        Ring2 = 'gurebu\'s Ring',
		Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Pet: Damage taken -5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = 'MND+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Shining Strike'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'nyame helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Body = 'egbesu frock',
        Hands = 'Jhakri Cuffs +2',
        Ring1 = 'weather. ring',
        Ring2 = 'gurebu\'s Ring',
		Back = { Name = 'Nantosuelta\'s Cape', Augment = { [1] = 'Pet: Damage taken -5%', [2] = 'Accuracy+30', [3] = 'Attack+20', [4] = 'MND+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    ['Seraph Strike_Acc'] = {
    },
    ['Shining Strike_Acc'] = {
    },

    Bolster = {Body = 'Bagua Tunic +3'},
	['Full Circle'] = {Head = 'Azimuth Hood +3',
		  Body = 'geo. tunic +4',},
    TH = {
        Ammo = 'Per. Lucky Egg',
		Waist = 'Chaac Belt',
	},
    Movement = {
        Feet = 'Geo. Sandals +4',
	},
    -- Templates: fill the ones you use; an empty set changes nothing.
    Ws_HighBuff = {}, -- /wsset high: over Ws_Default (PDL)
    ['Black Halo_HighBuff'] = {}, -- /wsset high: this WS
    Buffs = { -- while the buff is up: idle and engaged
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Ws = { -- while the buff is up: weapon skills
        ['Aftermath: Lv.3'] = {},
    },
    Buffs_Midcast = { -- while the buff is up: spells (e.g. ['Saboteur'])
    },
    -- Weapon_Idris_Acc = { Main = 'Item Name' }, -- /mset acc: a whole weapon set in place of Weapon_Idris
    Absorb = {}, -- every Absorb- spell (land rate: Dark Magic skill, macc; potency is not skill)
    Absorb_TP = {
		Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'azimuth hood +3',
        Neck = 'Erra Pendant',
        Ear1 = 'alabaster earring',
        Ear2 = 'malignance earring',
        Body = 'geo. tunic +4',
        Hands = 'geo. mitaines +4',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'null shawl',
        Waist = 'null belt',
        Legs = 'geo. pants +4',
        Feet = 'geo. sandals +4',
	}, -- Absorb-TP on top of Absorb
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
    --{Name = 'Tropical Crepe', Quantity = 'all'},
    --{Name = 'Rolan. Daifuku', Quantity = 'all'},
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
	gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None', 'Idris', 'Maxentius', 'Tishtrya'};
    gcinclude.DefaultWeapons = 'Idris';
    gcinclude.NukeModes = {'Power', 'Macc', 'OccultAcumen'}; -- /nukeset oa (or oc, occult, acumen): OccultAcumen set on nukes
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
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    if (player.Status ~= 'Engaged') and (gData.GetPet() ~= nil) then
        gFunc.EquipSet(sets.Idle_Pet);
    end
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end;
    if (gcdisplay.GetToggle('Kite') == true) or (player.IsMoving == true) then gFunc.EquipSet(sets.Movement) end -- any status, over Dt
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    ByName(ability.Name); -- a set named after the ability, e.g. ['Bolster']
    gcinclude.CheckCancels();
end

profile.HandleItem = function()
    local item = gData.GetAction();

	if string.match(item.Name, 'Holy Water') then gFunc.EquipSet(gcinclude.sets.Holy_Water) end
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
    local target = gData.GetActionTarget();
    local me = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0);
    local family = Family(spell.Name); -- 'Cure IV' -> 'Cure'
    gFunc.EquipSet(sets.Midcast);
    ByName(spell.Skill); -- e.g. ['Enhancing Magic'], ['Healing Magic'], ['Elemental Magic']
    if (spell.Skill == 'Enhancing Magic') then
        -- Phalanx, Stoneskin, Regen, Refresh: by name below
    elseif (spell.Skill == 'Healing Magic') then
        if (target.Name == me) then gFunc.EquipSet(sets.Self_Cure) end
        if T{'Cure', 'Cura', 'Curaga'}:contains(family) then
            if (gData.GetPlayer().MPP <= 50) then
                -- Light weather: Aurorastorm counts (LAC GetEnvironment reads storm buffs as weather), so does natural Light
                local env = gData.GetEnvironment();
                if (env ~= nil) and (env.WeatherElement == 'Light') then
                    gFunc.EquipSet(sets.Cure_LowMP_Storm);
                else
                    gFunc.EquipSet(sets.Cure_LowMP);
                end
            end
            if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Cure_Dt) end
        end
    elseif (spell.Skill == 'Elemental Magic') then
        if (gcdisplay.GetCycle('NukeSet') == 'Macc') then gFunc.EquipSet(sets.NukeACC) end
        if gcinclude.BurstWanted() then gFunc.EquipSet(sets.Burst) end
        if (gcdisplay.GetCycle('NukeSet') == 'OccultAcumen') then gFunc.EquipSet(sets.OccultAcumen) end -- /nukeset oa: TP from nukes, over Nuke/Burst
        if (gData.GetPlayer().MPP <= 40) then gFunc.EquipSet(sets.Mp_Body) end
    elseif (spell.Skill == 'Enfeebling Magic') then
        if (gcdisplay.GetCycle('NukeSet') == 'Macc') then gFunc.EquipSet(sets.Macc) end
    elseif (spell.Skill == 'Dark Magic') then
        gFunc.EquipSet(sets.Macc);
    elseif (spell.Skill == 'Geomancy') then
        if string.contains(spell.Name, 'Indi') then gFunc.EquipSet(sets.Indi) end -- over ['Geomancy']
    end
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
    ByName(ws.Name); -- e.g. ['Black Halo'], then ['Black Halo_<mset>']
end

return profile;
