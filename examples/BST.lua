local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- BST example: swap in your own gear.
-- Sets named after an ability, spell, skill or weapon skill (['Reward'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_SubtleBlow' / '<Name>_Acc' for /mset. Empty sets do nothing.
local sets = {

    Idle = {
        Main = 'Naegling',
        Sub = 'Adapa Shield',
        Ammo = 'Voluspa Tathlum',
        Head = 'Malignance Chapeau',
        Neck = 'Bathy Choker +1',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Etiolation Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = 'Gelatinous Ring +1',
        Back = { Name = 'Artio\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: "Regen"+10', [4] = 'Pet: Acc.+20', [5] = 'Pet: Atk.+20' } },
        Waist = 'Isa Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Idle_Regen = {
        Head = 'Crepuscular Helm',
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Ring2 = 'Chirich Ring +1',
    },
    Idle_Refresh = {
        Head = 'Jumalik Helm',
        Ring1 = 'Stikini Ring +1',
    },
    Resting = {},
    Town = {
        Main = 'Naegling',
        Sub = 'Adapa Shield',
        Ammo = 'Voluspa Tathlum',
        Head = 'Malignance Chapeau',
        Neck = 'Empath Necklace',
        Ear1 = 'Thrud Earring',
        Ear2 = 'Telos Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Malignance Gloves',
        Ring1 = 'Petrov Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Artio\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: "Regen"+10', [4] = 'Pet: Acc.+20', [5] = 'Pet: Atk.+20' } },
        Waist = 'Flume Belt +1',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Movement = {},
    Dt = {
        Ammo = 'Staunch Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Empath Necklace',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Handler\'s Earring +1',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = 'Gelatinous Ring +1',
        Back = { Name = 'Artio\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: "Regen"+10', [4] = 'Pet: Acc.+20', [5] = 'Pet: Atk.+20' } },
        Waist = 'Gishdubar Sash',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    TH = { -- /th: until the target is tagged; Main/Sub/Range here stay on while /th is on
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
    },
    Idle_Pet = {},
    Pet_Dt = {
        Head = 'Anwig Salade',
        Neck = 'Empath Necklace',
        Ear1 = 'Enmerkar Earring',
        Ear2 = 'Handler\'s Earring +1',
        Body = 'Taeon Tabard',
        Hands = 'Taeon Gloves',
        Ring1 = 'Defending Ring',
        Ring2 = 'Gelatinous Ring +1',
        Back = { Name = 'Artio\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: "Regen"+10', [4] = 'Pet: Acc.+20', [5] = 'Pet: Atk.+20' } },
        Waist = 'Isa Belt',
        Legs = 'Taeon Tights',
        Feet = 'Gleti\'s Boots',
    },
    Pet_Only_Tp_Default = {
        Ammo = 'Voluspa Tathlum',
        Head = 'Taeon Chapeau',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Enmerkar Earring',
        Ear2 = 'Domes. Earring',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'C. Palug Ring',
        Back = { Name = 'Artio\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: "Regen"+10', [4] = 'Pet: Acc.+20', [5] = 'Pet: Atk.+20' } },
        Waist = 'Incarnation Sash',
        Legs = 'Taeon Tights',
        Feet = 'Gleti\'s Boots',
    },

    Tp_Default = {
        Ammo = 'Coiste Bodhar',
        Head = 'Malignance Chapeau',
        Neck = 'Anu Torque',
        Ear1 = 'Sherida Earring',
        Ear2 = 'Telos Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Malignance Gloves',
        Ring1 = 'Gere Ring',
        Ring2 = 'Epona\'s Ring',
        Back = { Name = 'Artio\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: "Regen"+10', [4] = 'Pet: Acc.+20', [5] = 'Pet: Atk.+20' } },
        Waist = 'Sailfi Belt +1',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Tp_Acc = {
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
    },

    Precast = {
        Neck = 'Baetyl Pendant',
        Ear2 = 'Etiolation Earring',
        Body = 'Taeon Tabard',
        Hands = 'Leyline Gloves',
        Ring2 = 'Prolix Ring',
    },
    Midcast = {},
    Preshot = {},
    Midshot = {},
    Ready_Delay = { -- worn when you use a Ready move
        Legs = 'Gleti\'s Breeches',
    },
    PetAction = { -- default for pet moves; add a set named after a move to override
        Ammo = 'Voluspa Tathlum',
        Head = 'Nyame Helm',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Enmerkar Earring',
        Ear2 = 'Domes. Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Nukumi Manoplas +1',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'C. Palug Ring',
        Waist = 'Incarnation Sash',
        Legs = 'Taeon Tights',
        Feet = 'Gleti\'s Boots',
    },

    Ws_Default = {
        Ammo = 'Coiste Bodhar',
        Head = { Name = 'Valorous Mask', Augment = { [1] = 'Attack+16', [2] = 'Weapon skill damage +10%', [3] = 'Accuracy+16', [4] = 'Pet: Mag. Acc.+1', [5] = 'Pet: STR+4' } },
        Neck = 'Fotia Gorget',
        Ear1 = 'Thrud Earring',
        Ear2 = 'Telos Earring',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Meg. Gloves +2',
        Ring1 = 'Beithir Ring',
        Ring2 = 'Karieyh Ring +1',
        Waist = 'Fotia Belt',
        Legs = 'Gleti\'s Breeches',
        Feet = 'Gleti\'s Boots',
    },
    Ws_Acc = {
        Ammo = 'Voluspa Tathlum',
    },
    ['Aeolian Edge'] = {
        Ammo = 'Knobkierrie',
        Head = { Name = 'Valorous Mask', Augment = { [1] = 'Attack+16', [2] = 'Weapon skill damage +10%', [3] = 'Accuracy+16', [4] = 'Pet: Mag. Acc.+1', [5] = 'Pet: STR+4' } },
        --Head = 'Nyame Helm',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Thrud Earring',
        Ear2 = 'Friomisi Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shiva Ring +1',
        Ring2 = 'Karieyh Ring +1',
        Back = { Name = 'Ankou\'s Mantle', Augment = { [1] = 'Accuracy+20', [2] = '"Dbl.Atk."+10', [3] = 'Attack+20', [4] = 'DEX+20' } },
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },

    ['Reward'] = {
        Ammo = 'Pet Food Theta',
    },
    ['Call Beast'] = {
        Hands = 'Ankusa Gloves +1',
        Feet = 'Gleti\'s Boots',
    },
    ['Bestial Loyalty'] = {
        Hands = 'Ankusa Gloves +1',
        Feet = 'Gleti\'s Boots',
    },
    ['Killer Instinct'] = {
        Body = 'Nukumi Gausape +1',
    },
    ['Spur'] = {
        Feet = 'Nukumi Ocreae +1',
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
    {Name = 'Pet Food Theta', Quantity = 'all'},
    {Name = 'Furious Broth', Quantity = 'all'},
    {Name = 'Poisonous Broth', Quantity = 'all'},
    {Name = 'Livid Broth', Quantity = 'all'},
    {Name = 'Crackling Broth', Quantity = 'all'},
    {Name = 'Dire Broth', Quantity = 'all'},
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None'}; -- e.g. {'None', 'Example'} with a Weapon_Example set
    gcinclude.DefaultWeapons = 'None';
    gcinclude.settings.RefreshGearMPP = 0; -- no auto Idle_Refresh on this job; /autogear refresh 60 (or set it here) to turn it on
    -- Rules (/gcedit, RULES): when this, wear that, as data. A rule with at = goes on where gcinclude.RulesAt(...) is in the handlers below.
    gcinclude.Rules = {
        { on = 'Default', when = { toggle = { dt = true } }, wear = 'Dt' },
        { on = 'Default', when = { toggle = { kite = true } }, wear = 'Movement', exact = true },
        { on = 'Ability', at = 'Ability 1', when = { type = 'Ready' }, wear = 'Ready_Delay', exact = true },
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
    local pet = gData.GetPet();
    if (player.Status ~= 'Engaged') and (pet ~= nil) then
        gFunc.EquipSet(sets.Idle_Pet);
        if (pet.Status == 'Engaged') then gcinclude.EquipMode('Pet_Only_Tp') end -- pet fighting, you not
    end
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
    gcinclude.RulesAt('Ability 1');
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
