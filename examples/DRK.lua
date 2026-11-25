local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- DRK example: swap in your own gear.
-- Sets named after an ability, spell, skill or weapon skill (['Last Resort'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_SubtleBlow' / '<Name>_Acc' for /mset. Empty sets do nothing.
local sets = {

    Idle = {
        Ammo = 'Staunch Tathlum',
        Head = 'Jumalik Helm',
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Nyame Mail',
        Hands = 'Volte Moufles',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = 'Solemnity Cape',
        Waist = 'Gishdubar Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Idle_Regen = {
        Head = 'Crepuscular Helm',
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Ring1 = 'Chirich Ring +1',
    },
    Idle_Refresh = {
        Head = 'Jumalik Helm',
        Ring2 = 'Stikini Ring +1',
    },
    Resting = {},
    Town = {
        Main = 'Apocalypse',
        Sub = 'Utu Grip',
        Ammo = 'Staunch Tathlum',
        Head = 'Crepuscular Helm',
        Body = 'Fall. Cuirass +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Stikini Ring +1',
        Legs = { Name = 'Carmine Cuisses +1', AugPath='D' },
        Feet = 'Nyame Sollerets',
    },
    Movement = {
        Legs = 'Carmine Cuisses +1',
    },
    Dt = {
        Ammo = 'Staunch Tathlum',
        Head = 'Nyame Helm',
        Neck = { Name = 'Loricate Torque +1', AugPath='A' },
        Ear1 = { Name = 'Odnowa Earring +1', AugPath='A' },
        Ear2 = 'Etiolation Earring',
        Body = 'Nyame Mail',
        Hands = 'Volte Moufles',
        Ring1 = 'Defending Ring',
        Ring2 = { Name = 'Gelatinous Ring +1', AugPath='A' },
        Back = 'Solemnity Cape',
        Waist = 'Flume Belt +1',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    TH = { -- /th: until the target is tagged; Main/Sub/Range here stay on while /th is on
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
    },

    Tp_Default = {
        Ammo = { Name = 'Coiste Bodhar', AugPath='A' },
        Head = 'Flam. Zucchetto +2',
        Neck = 'Sanctity Necklace',--jse neck
        Ear1 = 'Cessance Earring',
        Ear2 = 'Telos Earring',
        Body = 'Flamma Korazin +2',--Sakpata\ body
        Hands = 'Sakpata\'s Gauntlets',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Niqmaddu Ring',
        Back = { Name = 'Ankou\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = '"Dbl.Atk."+10', [3] = 'Attack+20', [4] = 'DEX+20' } },
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = 'Sakpata\'s Cuisses',--af+3
        Feet = 'Flam. Gambieras +2',
    },
    Tp_Acc = {
        Ammo = 'Seeth. Bomblet +1',
        Head = 'Blistering Sallet +1',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Cacoethic Ring +1',
        Waist = 'Ioskeha Belt +1',
    },

    Precast = {
        Ammo = 'Sapience Orb',
        Head = 'Haruspex Hat',
        Neck = 'Baetyl Pendant',
        Body = 'Fall. Cuirass +3',
        Hands = 'Leyline Gloves',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Etiolation Earring',
        Ring1 = 'Kishar Ring',
        Ring2 = 'Prolix Ring',
        Legs = 'Enif Cosciales',
        Feet = 'Carmine Greaves +1',--7
    },
    Midcast = {},
    Preshot = {},
    Midshot = {
        Ear1 = 'Crep. Earring',
        Ear2 = 'Telos Earring',
    },
    ['Healing Magic'] = {
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Incanter\'s Torque',
        Ear2 = 'Mendi. Earring',
        Ring1 = 'Stikini Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = 'Solemnity Cape',
        Legs = 'Carmine Cuisses +1',
        Feet = { Name = 'Odyssean Greaves', Augment = { [1] = 'Damage taken-4%', [2] = 'Attack+8', [3] = 'Accuracy+2' } },
    },
    ['Enhancing Magic'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Befouled Crown',
        Body = 'Shab. Cuirass +1',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
    },
    ['Dark Magic'] = {
        Neck = 'Erra Pendant',
        Ear1 = 'Crep. Earring',
        Ear2 = 'Malignance Earring',
        Ring1 = 'Kishar Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
    },
    ['Enfeebling Magic'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Befouled Crown',
        Neck = 'Erra Pendant',
        Ear1 = 'Crep. Earring',
        Ear2 = 'Malignance Earring',
        Ring1 = 'Kishar Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
    },
    ['Elemental Magic'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Crematio Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Fall. Cuirass +3',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shiva Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    OccultAcumen = { -- /nukeset oa: Occult Acumen / Store TP pieces, over Elemental Magic (TP from nukes)
    },
    ['Drain'] = { -- all tiers
        Neck = 'Erra Pendant',
        Ear1 = 'Crep. Earring',
        Ear2 = 'Malignance Earring',
        Ring1 = 'Kishar Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
    },
    ['Aspir'] = { -- all tiers
        Neck = 'Erra Pendant',
        Ear1 = 'Crep. Earring',
        Ear2 = 'Malignance Earring',
        Ring1 = 'Kishar Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
    },
    ['Dread Spikes'] = { -- all tiers
        -- HP+++++ at cast for max potency
        Head = 'Hjarrandi Helm',
        Neck = 'Unmoving Collar +1',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Etiolation Earring',
        Body = 'Hjarrandi Breast.',
        Hands = 'Sakpata\'s Gauntlets',
        Ring1 = 'Moonbeam Ring',
        Ring2 = 'Eihwaz Ring',
        Waist = 'Asklepian Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Carmine Greaves +1',
    },
    Dread_Spikes_Up = {
        -- set to leave body on with dread spikes up, only body here!
        Body = 'Heath. Cuirass +1',
    },

    Ws_Default = {
        -- WSD for all scythe basically
        Ammo = 'Knobkierrie',
        Head = { Name = 'Valorous Mask', Augment = { [1] = 'Attack+16', [2] = 'Weapon skill damage +10%', [3] = 'Accuracy+16', [4] = 'Pet: Mag. Acc.+1', [5] = 'Pet: STR+4' } },
        Neck = 'Fotia Gorget',
        Ear1 = 'Thrud Earring',
        Ear2 = 'Telos Earring',
        Body = 'Hjarrandi Breast.', -- af+3
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Beithir Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Ankou\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = '"Dbl.Atk."+10', [3] = 'Attack+20', [4] = 'DEX+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Sakpata\'s Cuisses', -- relic +3
        Feet = 'Sulev. Leggings +2',
    },
    ['Aeolian Edge'] = {
        Ammo = 'Seeth. Bomblet +1',
        Head = { Name = 'Valorous Mask', Augment = { [1] = 'Attack+16', [2] = 'Weapon skill damage +10%', [3] = 'Accuracy+16', [4] = 'Pet: Mag. Acc.+1', [5] = 'Pet: STR+4' } },
        Neck = 'Sanctity Necklace',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Malignance Earring',
        Body = 'Fall. Cuirass +3',
        Hands = 'Carmine Fin. Ga. +1',
        Ring1 = 'Shiva Ring +1',
        Ring2 = 'Metamor. Ring +1',
        Back = { Name = 'Ankou\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = '"Dbl.Atk."+10', [3] = 'Attack+20', [4] = 'DEX+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    ['Blood Weapon'] = {
        Body = 'Fall. Cuirass +3',
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
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None'}; -- e.g. {'None', 'Example'} with a Weapon_Example set
    gcinclude.DefaultWeapons = 'None';
    gcinclude.NukeModes = {'Power', 'OccultAcumen'}; -- /nukeset oa: OccultAcumen set on nukes (Power = your Elemental Magic set alone)
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
    elseif (player.IsMoving == true) then
        gFunc.EquipSet(sets.Movement);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    if (gcinclude.BuffCount('Dread Spikes') > 0) then gFunc.EquipSet(sets.Dread_Spikes_Up) end -- body stays on
    if (gcdisplay.GetToggle('DTset') == true) then ByName('Dt') end -- then Dt_<mset> (Dt_SubtleBlow)
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end
    gcinclude.CheckDefault();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    ByName(ability.Name);
    gcinclude.CheckCancels();
end

profile.HandlePrecast = function()
    gFunc.EquipSet(sets.Precast);
    gcinclude.CheckCancels();
end

profile.HandleMidcast = function()
    local spell = gData.GetAction();
    gFunc.EquipSet(sets.Midcast);
    ByName(spell.Skill);
    if not ByName(spell.Name) then ByName(Family(spell.Name)) end
    if (spell.Skill == 'Elemental Magic') and (gcdisplay.GetCycle('NukeSet') == 'OccultAcumen') then gFunc.EquipSet(sets.OccultAcumen) end -- /nukeset oa
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
    ByName(ws.Name);
end

return profile;
