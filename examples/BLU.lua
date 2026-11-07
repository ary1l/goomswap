local profile = {};
if (gFunc == nil) then error('GoomSwap: GearSwap loaded this job file directly. Windower: move it to data/goomswap/<Name>/<JOB>.lua and delete it from data/<Name>/ (see README Install)', 0) end
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
-- gcinclude.Food = {'Grape Daifuku +1'}; -- this job's food: /packer keeps a stack of each (replaces the Food setting / char.lua's)
-- gcinclude.Packer = { ['Echo Drops'] = 'stack', ['Holy Water'] = 'stack' }; -- kept in inventory on job change (/packer, Bellhop plugin)


local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Hashishin Kavuk +3',
        Neck = 'warder\'s charm +1',
        Ear1 = 'alabaster earring',
        Ear2 = 'Etiolation Earring',
        Body = 'adamantite armor',
        Hands = 'hashi. bazu. +3',
        Ring1 = 'murky ring',
        Ring2 = 'shadow ring',
		Back = 'shadow mantle',
        Waist = 'carrier\'s sash',
        Legs = 'hashishin tayt +3',
        Feet = 'nyame sollerets',
    },
	Resting = {
        Body = 'Hashishin Mintan +3',
        Waist = 'Fucho-no-Obi',
    },
    Idle_Regen = {
        Neck = 'Sanctity Necklace',
        --Ear1 = 'Infused Earring',
        Ring1 = 'Chirich Ring +1',
		Waist = 'null belt',
    },
    Idle_Refresh = {
        --Head = 'Rawhide Mask',
        Body = 'Hashishin Mintan +3',
        Ring1 = 'Stikini Ring +1',
		Ring2 = 'stikini ring +1',
        Waist = 'Fucho-no-Obi',
    },
    Idle_Regain = { -- /idleset regain: over Idle while idle
    },
	['Town'] = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Hashishin Kavuk +3',
        Neck = 'mirage stole +2',
        Ear1 = 'alabaster earring',
        Ear2 = 'Etiolation Earring',
        Body = 'adamantite armor',
        Hands = 'Assim. Bazu. +4',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'stikini ring +1',
        Back = 'shadow mantle',
        Waist = 'Null Belt',
        Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },

    Evasion = {--worn by /kite
        Ammo = 'Staunch Tathlum +1',
        Head = 'nyame helm',
        Neck = 'warder\'s charm +1',
        Ear1 = 'alabaster Earring',
        Ear2 = 'eabani earring',
        Body = 'adamantite armor',
        Hands = 'nyame gauntlets',
        Ring1 = 'murky ring',
        Ring2 = 'shadow ring',
		Back = 'null shawl',
        Waist = 'null belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

	Dt = {
		Ammo = 'Staunch Tathlum +1',
        Head = 'Nyame Helm',
		Neck = 'warder\'s charm +1',
		Ear1 = 'hearty earring',
		Ear2 = 'Eabani Earring',
		Body = 'adamantite armor',
        Hands = 'nyame gauntlets',
        Ring1 = 'stikini ring +1',
        Ring2 = 'stikini ring +1',
        Back = 'null shawl',
		Waist = 'carrier\'s sash',
		Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
	},
    SIR = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Hashishin Kavuk +3',
        Neck = 'warder\'s charm +1',
        Ear1 = 'alabaster earring',
        Ear2 = 'Etiolation Earring',
        Body = 'adamantite armor',
        Hands = 'hashi. bazu. +3',
        Ring1 = 'murky ring',
        Ring2 = 'shadow ring',
		Back = 'shadow mantle',
        Waist = 'carrier\'s sash',
        Legs = 'hashishin tayt +3',
        Feet = 'nyame sollerets',
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
        Ammo = 'coiste bodhar',
        Head = 'Malignance Chapeau',
        Neck = 'Mirage Stole +2',
        Ear1 = 'telos earring',
        Ear2 = 'Suppanomimi',
        Body = 'malignance tabard',
        Hands = 'malignance gloves',
        Ring1 = 'chirich ring +1',
        Ring2 = 'Epona\'s Ring',
        Back = 'null shawl',
        Waist = 'sailfi belt +1',
        Legs = 'malignance tights',
		Feet = 'malignance boots',
    },
	Tp_SubtleBlow = { -- /mmode subtleblow: Subtle Blow pieces over Tp_Default
	    Body = 'volte harness', -- Subtle Blow+10
	},
	Tp_Acc = {
        },
    Midcast = {},

	Precast = {--64
        Ammo = 'Sapience Orb',--2
        Head = 'Carmine Mask +1', --14
        Neck = 'voltsurge torque',--4
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
        Neck = 'voltsurge torque',--4
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
        Neck = 'voltsurge torque',--4
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
        Ammo = 'egoist\'s Tathlum',
        Head = 'nyame helm',
        Neck = 'unmoving collar +1',
        Ear1 = 'alabaster earring',
        Ear2 = 'tuisto Earring',
        Body = 'pinga tunic +1',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'gelatinous Ring +1',
        Ring2 = 'Meridian Ring',
        Back = 'Moonbeam Cape',
        Waist = 'plat. mog. belt',
        Legs = 'Pinga Pants +1',
        Feet = 'Carmine Greaves +1',
    },
    BluSkill = {
		Ear1 = 'Njordr earring',
		Ear2 = 'Hashi. earring +1',
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
        Hands = 'hashi. bazu. +3',
        Ring1 = 'Metamor. Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Mag. Acc+20', [3] = 'Magic Damage+20', [4] = 'INT+30' } },
        Waist = 'orpheus\'s sash',
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
        Body = 'assim. jubbah +4',
        Hands = 'Hashi. Bazu. +3',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'null shawl',
        Waist = 'null belt',
        Legs = 'Hashishin Tayt +3',
        Feet = 'Hashi. Basmak +3',
    },
    BluStun = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Malignance Chapeau',
        Neck = 'Mirage Stole +2',
        Ear1 = 'digni. Earring',
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
        Ammo = 'coiste bodhar',
        Head = 'Nyame Helm',
        Neck = 'Mirage Stole +2',
        Ear1 = 'Regal Earring',
        Ear2 = 'Hashi. Earring +1',
        Body = 'Malignance Tabard',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Ephramad\'s ring',
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
		Range = 'aliyat chakram',
		Ammo = 'displaced',
    },
    Midshot = {
		Range = 'aliyat chakram',
		Ammo = 'displaced',
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },

    Ws_Default = {
        Ammo = 'coiste bodhar',
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
        Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
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
	    Ammo = 'coiste bodhar',
        Head = 'Hashishin Kavuk +3',
		Neck = 'Mirage Stole +2',
        Ear1 = 'alabaster Earring',
        Body = 'Assim. Jubbah +4',
        Hands = 'nyame gauntlets',
        Ring1 = 'petrov Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'sailfi belt +1',
		Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },
    ['Savage Blade_Acc'] = {
    },
    Imperator = {
        Ammo = 'coiste bodhar',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Mirage Stole +2',
        Ear1 = 'alabaster Earring',
        Body = 'Nyame Mail',
        Hands = 'nyame gauntlets',
        Ring1 = 'petrov Ring',
        Ring2 = 'Ephramad\'s Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'kentarch belt +1',
        Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },
    Imperator_Acc = {
    },
    Expiacion = {
        Ammo = 'crepuscular pebble',
        Head = 'Hashishin Kavuk +3',
        Neck = 'Mirage Stole +2',
        Ear1 = 'alabaster Earring',
        Body = 'Assim. Jubbah +4',
        Hands = 'gleti\'s Gauntlets',
        Ring1 = 'sroda Ring',
        Ring2 = 'ephramad\'s Ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = 'Phys. dmg. taken -10%', [2] = 'STR+30', [3] = 'Accuracy+20', [4] = 'Attack+20', [5] = 'Weapon skill damage +10%' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },
    Expiacion_Acc = {
    },
    Expiacion_SubtleBlow = { -- /mmode subtleblow: Subtle Blow pieces over Expiacion_Default (any WS: <its set>_SubtleBlow)
    },
    Requiescat = {
        Head = 'Hashishin Kavuk +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Brutal Earring',
        Body = 'Hashishin Mintan +3',
        Hands = 'Nyame Gauntlets',
        --Ring1 = 'archon ring',
        Ring1 = 'Metamor. ring +1',
        Waist = 'Fotia Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Jhakri Pigaches +2',
    },
    Requiescat_Acc = {
    },
	['Sanguine Blade'] = {
        Ammo = 'ghastly tathlum',
        Head = 'Hashishin kavuk +3',
        Neck = 'sibyl scarf',
        Ear1 = 'regal Earring',
        Ear2 = 'malignance Earring',
        Body = 'Nyame Mail',
        Hands = 'jhakri cuffs +2',
        Ring1 = 'Metamor. ring +1',
        Ring2 = 'archon ring',
        Back = { Name = 'Rosmerta\'s Cape', Augment = { [1] = '"Mag. Atk. Bns."+10', [2] = 'Mag. Acc+20', [3] = 'Magic Damage+20', [4] = 'INT+30' } },
        Waist = 'orpheus\'s sash',
        Legs = 'nyame flanchard',
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
    -- Combos: <set>_<buff>, <set>_<buff>&<buff> (all up); fewest buffs first, then A-Z. Full order: README Hoxne layering.
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
		Ring1 = 'shneddick ring',
	},
    -- Templates: fill the ones you use; an empty set changes nothing.
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
    -- Weapon_Tizona_Acc = { Main = 'Item Name' }, -- /mmode acc: a whole weapon set in place of Weapon_Tizona
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
    ByName(ws.Name); -- e.g. ['Expiacion'], then ['Expiacion_<mmode>']
end

return profile;
