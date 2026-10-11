local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');


local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    Idle = {
        Head = 'nyame helm',
        Neck = 'Loricate Torque +1',
        Ear1 = 'alabaster Earring',
        Ear2 = 'Eabani Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Malignance Gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'defending Ring',
        Back = 'Null Shawl',
        Waist = 'Null Belt',
        Legs = 'nyame flanchard',
        Feet = 'nyame Sollerets',
    },
    Resting = {},
    Idle_Regen = {
        --Head = 'Meghanada Visor +2',
        --Neck = 'Bathy Choker +1',
        --Ear1 = 'Infused Earring',
        --Hands = 'Meg. Gloves +2',
        Ring1 = 'Chirich Ring +1',
        --Feet = 'Meg. Jam. +2',
    },
    Idle_Refresh = {},
    Town = {
        Head = 'Gleti\'s Mask',
        Neck = 'Asn. Gorget +2',
        Ear1 = 'alabaster Earring',
        Ear2 = 'skulk. earring +2',
        Body = 'Gleti\'s Cuirass',
        Hands = 'nyame gauntlets',
        Ring1 = 'shneddick ring',
        Ring2 = 'Defending Ring',
        Back = 'null shawl',
        Waist = 'null belt',
        Legs = 'nyame flanchard',
        Feet = 'nyame Sollerets',
    },

    Dt = {
        Head = 'Nyame Helm',
        Neck ='loricate torque +1',
        Ear1 = 'alabaster earring',
        Ear2 = 'Eabani Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Gelatinous Ring',
        Ring2 = 'Defending Ring',
        Back = 'null shawl',
        Waist = 'Sailfi Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    Weapon_Mpu = {
        Main = 'Mpu Gandring',
        Sub = 'Fusetto +2',
    },
    Weapon_MpuAcc = {
        Main = 'Mpu Gandring',
        Sub = 'Gleti\'s Knife',
    },
    Weapon_Naegling = {
        Main = 'Naegling',
        Sub = 'Fusetto +2',
    },
    Tp_Default = {
		Ammo = 'coiste bodhar',
        Head = 'gleti\'s mask',
        Neck = { Name = 'Asn. Gorget +2', AugPath='A' },
        Ear1 = 'Sherida Earring',
        Ear2 = 'skulk. earring +2',
        Body = 'gleti\'s cuirass',
        Hands = 'nyame gauntlets',
        Ring1 = 'petrov Ring',
        Ring2 = 'Epona\'s Ring',
        Back = 'null shawl',
        Waist = 'Sailfi Belt +1',
        Legs = 'nyame flanchard',
        Feet = 'nyame sollerets',
    },
    Tp_Hybrid = {
        Head = 'Malignance Chapeau',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Malignance Gloves',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Tp_Acc = {
		--Ammo = "Ginsen",
        Head = 'Malignance Chapeau',
        --Neck = 'Sanctity Necklace',
        --Ear1 = 'Mache Earring +1',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Malignance Gloves',
        --Ring1 = 'Cacoethic Ring +1',
        Ring1 = 'Chirich Ring +1',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },


    Precast = {
        Head = 'Haruspex Hat',
        Neck = 'voltsurge torque',
		Ear1 = 'alabaster earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Taeon Tabard',
        Hands = 'Leyline Gloves',
        Ring1 = 'Prolix Ring',
        Legs = 'Enif Cosciales',
    },

    Preshot = {
    },
    Midshot = {
        Head = 'Malignance Chapeau',
        Neck = 'Iskur Gorget',
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
        Body = 'Mummu Jacket +2',
        Hands = 'Plun. Armlets +3',
        Ring1 = 'Dingir Ring',
        Waist = 'Eschan Stone',
    },

    Ws_Default = {
		Ammo = "Yetshila +1",
        Head = 'Pill. Bonnet +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Odr Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Pillager\'s Vest +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Regal Ring',
        Ring2 = 'Ilabrat Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'Fotia Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Accuracy+14', [3] = 'Attack+26', [4] = 'DEX+8' } },
    },
    Ws_Default_SA = {
    },
    Ws_Default_TA = {
    },
    Ws_Default_SATA = {
    },
    Ws_Hybrid = {
        Head = 'Nyame Helm',
        Body = 'Gleti\'s Cuirass',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Ws_Hybrid_SA = {},
    Ws_Hybrid_TA = {},
    Ws_Hybrid_SATA = {},
    Ws_Acc = {
    },
    Ws_Acc_SA = {},
    Ws_Acc_TA = {},
    Ws_Acc_SATA = {},

    Evis_Default = {
        Head = 'Pill. Bonnet +3',
        Neck = 'Fotia Gorget',
        Ear1 = 'Odr Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Plunderer\'s Vest +3',
        --Hands = 'Meg. Gloves +2',
        Ring1 = 'Regal Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'Fotia Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Weapon skill damage +4%', [2] = 'Accuracy+14', [3] = 'Attack+26', [4] = 'DEX+8' } },
    },
    Evis_Default_SA = {
    },
    Evis_Default_TA = {

    },
    Evis_Default_SATA = {
    },
    Evis_Hybrid = {
    },
    Evis_Hybrid_SA = {},
    Evis_Hybrid_TA = {},
    Evis_Hybrid_SATA = {},
    Evis_Acc = {
    },
    Evis_Acc_SA = {},
    Evis_Acc_TA = {},
    Evis_Acc_SATA = {},

	Rudra_Default = {
        Head = 'Nyame Helm',
        Neck = 'Asn. Gorget +2',
        Ear1 = 'Sherida Earring',
        Body = 'Plunderer\'s Vest +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Regal Ring',
		Ring2 = 'ephramad\'s Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'Kentarch Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Rudra_Default_SA = {
    },
    Rudra_Default_TA = {

    },
    Rudra_Default_SATA = {
    },
    Rudra_Hybrid = {
    },
    Rudra_Hybrid_SA = {},
    Rudra_Hybrid_TA = {},
    Rudra_Hybrid_SATA = {},
    Rudra_Acc = {
    },
    Rudra_Acc_SA = {},
    Rudra_Acc_TA = {},
    Rudra_Acc_SATA = {},

	Savage_Default = {
		Ammo = 'coiste bodhar',
        Head = 'Nyame Helm',
        Neck = { Name = 'Asn. Gorget +2', AugPath='A' },
        Ear1 = 'Telos Earring',
        Body = 'Plunderer\'s Vest +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Regal Ring',
        Ring2 = 'Hetairoi Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'Kentarch Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Savage_Default_SA = {
    },
    Savage_Default_TA = {

    },
    Savage_Default_SATA = {
    },
    Savage_Hybrid = {
    },
    Savage_Hybrid_SA = {},
    Savage_Hybrid_TA = {},
    Savage_Hybrid_SATA = {},
    Savage_Acc = {
    },
    Savage_Acc_SA = {},
    Savage_Acc_TA = {},
    Savage_Acc_SATA = {},

	AE_Default = {
		Ammo = "C. Palug Stone",
        Head = 'Nyame Helm',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Friomisi Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Dingir Ring',
        Ring2 = 'ephramad\'s Ring',
        Back = { Name = 'Toutatis\'s Cape', Augment = { [1] = 'Accuracy+20', [2] = 'Weapon skill damage +10%', [3] = 'Attack+20', [4] = 'DEX+30' } },
        Waist = 'orpheus\'s sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    AE_Default_SA = {
    },

	AE_Default_TA = {
    },
    AE_Default_SATA = {
    },
    AE_Hybrid = {
    },
    AE_Hybrid_SA = {},
    AE_Hybrid_TA = {},
    AE_Hybrid_SATA = {},
    AE_Acc = {
    },
    AE_Acc_SA = {},
    AE_Acc_TA = {},
    AE_Acc_SATA = {},

    SATA = {

    },
    SA = {

    },
    TA = {

    },
    ['TH'] = {
        Sub = 'Gandring', -- held while /th is on, even after the tag (a Sub swap resets TP)
		Head = 'herculean helm',
		Hands = 'Plun. Armlets +3',
    },
    Flee = {
        Feet = 'Pill. Poulaines +2',
    },
    Movement = {
        Feet = 'Pill. Poulaines +2',
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
    gcinclude.AlwaysDualWield = true;
    gcinclude.WeaponModes = {'None', 'Mpu', 'MpuAcc', 'Naegling'};
    gcinclude.DefaultWeapons = 'Mpu';
    gcinclude.MainModes = {'None', 'Mpu Gandring', 'Naegling'};
    gcinclude.SubModes = {'None', 'Gleti\'s Knife', 'Fusetto +2', 'Gandring'};
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
    local sa = gcinclude.BuffCount('Sneak Attack');
    local ta = gcinclude.BuffCount('Trick Attack');

	local player = gData.GetPlayer();
    if (player.Status == 'Engaged') then
        gcinclude.EquipMode('Tp');
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
		gFunc.EquipSet(sets.Movement);
    end

    if (sa == 1) and (ta == 1) then
        gFunc.EquipSet(sets.SATA);
    elseif (sa == 1) then
        gFunc.EquipSet(sets.SA);
    elseif (ta == 1) then
        gFunc.EquipSet(sets.TA);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end;
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end;
    gcinclude.CheckDefault ();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
	if string.match(ability.Name, 'Flee') then
		gFunc.EquipSet(sets.Flee);
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
    local sa = gcinclude.BuffCount('Sneak Attack');
    local ta = gcinclude.BuffCount('Trick Attack');

    local prefix = 'Ws';
    if string.match(ws.Name, 'Savage Blade') then
        prefix = 'Savage';
    elseif string.match(ws.Name, 'Evisceration') then
        prefix = 'Evis';
    elseif string.match(ws.Name, 'Aeolian Edge') then
        prefix = 'AE';
    elseif string.match(ws.Name, 'Rudra\'s Storm') then
        prefix = 'Rudra';
    end

    gcinclude.EquipMode('Ws');
    if (prefix ~= 'Ws') then gcinclude.EquipMode(prefix) end

    -- SA/TA on top of the WS set: <prefix>_<mode>_SA/_TA/_SATA, or Ws_<mode>_... when that one is missing or empty.
    local suffix = ((sa > 0) and (ta > 0) and 'SATA') or ((sa > 0) and 'SA') or ((ta > 0) and 'TA') or nil;
    if (suffix ~= nil) then
        local mode = gcdisplay.GetCycle('MeleeSet');
        local set = gcinclude.FindSet(prefix .. '_' .. mode .. '_' .. suffix);
        if (set == nil) or (next(set) == nil) then set = gcinclude.FindSet('Ws_' .. mode .. '_' .. suffix) end
        if (set ~= nil) then gFunc.EquipSet(set) end
    end
end

return profile;
