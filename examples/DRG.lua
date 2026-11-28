local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- DRG example: swap in your own gear.
-- Sets named after an ability, spell, skill or weapon skill (['Jump'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_SubtleBlow' / '<Name>_Acc' for /mset. Empty sets do nothing.
local sets = {

    Idle = {
        Ammo = 'Staunch Tathlum',
        Head = 'Crepuscular Helm',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Telos Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Flam. Manopolas +2',
        Ring1 = 'Defending Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Brigantia\'s Mantle', Augment = { [1] = 'STR+30', [2] = '"Dbl.Atk."+10', [3] = 'Attack+20', [4] = 'Accuracy+20' } },
        Waist = 'Isa Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Idle_Regen = {
        Head = 'Crepuscular Helm',
        Neck = 'Bathy Choker +1',
        Ear2 = 'Infused Earring',
        Ring2 = 'Chirich Ring +1',
    },
    Idle_Refresh = {
        Head = 'Jumalik Helm',
        Ring1 = 'Stikini Ring +1',
    },
    Resting = {},
    Town = {
        Main = 'Shining One',
        Sub = 'Utu Grip',
        Ammo = { Name = 'Coiste Bodhar', AugPath='A' },
        Head = 'Crepuscular Helm',
        Neck = 'Bathy Choker +1',
        Ear1 = 'Telos Earring',
        Ear2 = 'Infused Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Flam. Manopolas +2',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Chirich Ring +1',
        Back = { Name = 'Brigantia\'s Mantle', Augment = { [1] = 'STR+30', [2] = '"Dbl.Atk."+10', [3] = 'Attack+20', [4] = 'Accuracy+20' } },
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
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
        Hands = 'Nyame Gauntlets',
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
    Idle_Pet = {},

    Tp_Default = {
        Ammo = { Name = 'Coiste Bodhar', AugPath='A' },
        Head = 'Flam. Zucchetto +2',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Telos Earring',
        Ear2 = 'Sherida Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Flam. Manopolas +2',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Niqmaddu Ring',
        Back = { Name = 'Brigantia\'s Mantle', Augment = { [1] = 'STR+30', [2] = '"Dbl.Atk."+10', [3] = 'Attack+20', [4] = 'Accuracy+20' } },
        Waist = { Name = 'Sailfi Belt +1', AugPath='A' },
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Tp_Acc = {
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
    },

    Precast = {
        Neck = 'Baetyl Pendant',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Taeon Tabard',
        Hands = 'Leyline Gloves',
        Ring1 = 'Prolix Ring',
        Legs = 'Enif Cosciales',
    },
    Midcast = {},
    Preshot = {},
    Midshot = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Crep. Earring',
    },
    ['Healing Magic'] = {
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Incanter\'s Torque',
        Ear2 = 'Mendi. Earring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = 'Solemnity Cape',
        Legs = 'Carmine Cuisses +1',
    },
    ['Enhancing Magic'] = {
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Mendi. Earring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
    },
    ['Enfeebling Magic'] = {
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Erra Pendant',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
    },
    ['Elemental Magic'] = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shiva Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Drain = {
        Neck = 'Erra Pendant',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
    },
    Aspir = {
        Neck = 'Erra Pendant',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
    },
    PetAction = {}, -- default for wyvern breaths; add a set named after the breath to override

    Ws_Default = {
        Ammo = 'Knobkierrie',
        Head = { Name = 'Valorous Mask', Augment = { [1] = 'Attack+16', [2] = 'Weapon skill damage +10%', [3] = 'Accuracy+16', [4] = 'Pet: Mag. Acc.+1', [5] = 'Pet: STR+4' } },
        Neck = 'Fotia Gorget',
        Ear2 = 'Thrud Earring',
        Ear1 = 'Telos Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Beithir Ring',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Brigantia\'s Mantle', Augment = { [1] = 'STR+30', [2] = '"Dbl.Atk."+10', [3] = 'Attack+20', [4] = 'Accuracy+20' } },
        Waist = 'Fotia Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Sulev. Leggings +2',
    },
    ['Aeolian Edge'] = {
        Ammo = 'Knobkierrie',
        Head = { Name = 'Valorous Mask', Augment = { [1] = 'Attack+16', [2] = 'Weapon skill damage +10%', [3] = 'Accuracy+16', [4] = 'Pet: Mag. Acc.+1', [5] = 'Pet: STR+4' } },
        Neck = 'Baetyl Pendant',
        Ear2 = 'Thrud Earring',
        Ear1 = 'Friomisi Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shiva Ring +1',
        Ring2 = 'Karieyh Ring +1',
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
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
    gcinclude.settings.RefreshGearMPP = 0; -- no auto Idle_Refresh on this job; /autogear refresh 60 (or set it here) to turn it on
    -- Rules (/gcedit, RULES): when this, wear that, as data. A rule with at = goes on where gcinclude.RulesAt(...) is in the handlers below.
    gcinclude.Rules = {
        { on = 'Default', at = 'Default 1', when = { pet = true, status = { isnt = 'Engaged' } }, wear = 'Idle_Pet', exact = true },
        { on = 'Default', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Default', when = { toggle = { kite = true } }, wear = 'Movement', exact = true },
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
    local petAction = gData.GetPetAction(); -- pet actions arrive here, not in HandleAbility
    if (petAction ~= nil) then
        if not ByName(petAction.Name) then gFunc.EquipSet(sets.PetAction) end
        return;
    end
    local player = gData.GetPlayer();
    gcinclude.EquipIdle(); -- Idle, then Idle_<mode> (/idleset)
    gcinclude.RulesAt('Default 1');
    if (player.Status == 'Engaged') then
        gcinclude.EquipMode('Tp');
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
        gFunc.EquipSet(sets.Movement);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
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
