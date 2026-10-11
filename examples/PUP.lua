local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- PUP example. Gear from GetAwayCoxn's Luashitacast-Profiles (github.com/GetAwayCoxn/Luashitacast-Profiles,
-- MIT, see LICENSE-GetAwayCoxn.txt); swap in your own.
-- Sets named after an ability, spell, skill or weapon skill (['Activate'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_Hybrid' / '<Name>_Acc' for /meleeset. Empty sets do nothing.
local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    -- Weapon modes: add a Weapon_<Mode> set and the mode to WeaponModes in OnLoad.
    -- Weapon_Example = { Main = 'Item Name', Sub = 'Item Name' },

    Idle = {
        Main = 'Sakpata\'s Fists',
        Head = 'Mpaca\'s Cap',
        Neck = 'Empath Necklace',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Etiolation Earring',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = 'Gelatinous Ring +1',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
        Waist = 'Gishdubar Sash',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    Idle_Regen = {
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Hands = 'Rao Kote',
        Ring2 = 'Chirich Ring +1',
    },
    Idle_Refresh = {
        Head = 'Rawhide Mask',
        Ring2 = 'Stikini Ring +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Assid. Pants +1',
    },
    Resting = {
        Head = 'Foire Taj +1',
    },
    Town = {
        Main = 'Sakpata\'s Fists',
        Range = 'Neo Animator',
        Ammo = 'Automat. Oil +3',
        Head = 'Kara. Cappello +2',
        Neck = 'Bathy Choker +1',
        Ear1 = 'Burana Earring',
        Ear2 = 'Kara. Earring +1',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Mpaca\'s Gloves',
        Ring1 = 'Stikini Ring +1',
        Ring2 = 'Chirich Ring +1',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
        Waist = 'Moonbow Belt',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Hermes\' Sandals',
    },
    Movement = {
        Feet = 'Hermes\' Sandals',
    },
    Dt = {
        Head = 'Malignance Chapeau',
        Neck = 'Empath Necklace',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Handler\'s Earring +1',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = 'C. Palug Ring',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
        Waist = 'Isa Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    mdt = {},
    Aminon = {},
    SIR = {},
    TH = { -- /th: until the target is tagged; Main/Sub/Range here stay on while /th is on
        Waist = 'Chaac Belt',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Potency of "Cure" effect received+5%', [2] = 'Mag. Acc.+19', [3] = 'Accuracy+21', [4] = '"Mag. Atk. Bns."+19', [5] = '"Treasure Hunter"+2' } },
    },
    Idle_Pet = {
        Main = 'Sakpata\'s Fists',
        Head = 'Taeon Chapeau',
        Neck = 'Empath Necklace',
        Ear1 = 'Burana Earring',
        Ear2 = 'Kara. Earring +1',
        Body = 'Taeon Tabard',
        Hands = 'Taeon Gloves',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Stikini Ring +1',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
        Waist = 'Isa Belt',
        Legs = 'Taeon Tights',
        Feet = 'Mpaca\'s Boots',
    },
    Pet_Dt = {
        Head = 'Anwig Salade',--10pt
        Neck = 'Empath Necklace',
        Ear1 = 'Enmerkar Earring',--3dt
        Ear2 = 'Handler\'s Earring +1',--4pt
        --Ear2 = 'Kara. Earring +1',
        Body = 'Taeon Tabard',--4dt
        Hands = 'Taeon Gloves',--4dt
        Ring1 = 'Defending Ring',
        Ring2 = 'C. Palug Ring',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
        Waist = 'Isa Belt',--3dt
        Legs = 'Taeon Tights',
        Feet = 'Mpaca\'s Boots',
    },
    Idle_Pet_Tank = {},
    Idle_Pet_Melee = {},
    Idle_Pet_Ranger = {},
    Idle_Pet_Mage = {},
    Pet_Only_Tp_Default = {
        Ammo = 'Automat. Oil +3',
        Head = 'Foire Taj +1',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Domes. Earring',
        Ear2 = 'Kara. Earring +1',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'C. Palug Ring',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
        Waist = 'Incarnation Sash',
        Legs = 'Taeon Tights',
        Feet = 'Mpaca\'s Boots',
    },
    Pet_Only_Tp_Acc = {
        Legs = 'Heyoka Subligar',
    },
    Pet_Tank = {
        Range = 'Animator P +1',
        Head = 'Taeon Chapeau',
        Ear1 = 'Domes. Earring',
        Ring1 = 'Overbearing Ring',
        Ring2 = 'C. Palug Ring',
        Legs = 'Heyoka Subligar',
    },
    Pet_Melee = {
        Range = 'Neo Animator',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'C. Palug Ring',
    },
    Pet_Ranger = {
        Range = 'Animator P +1',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'C. Palug Ring',
        -- Waist = 'Klouskap Sash +1', -- do this after getting +1
    },
    Pet_Mage = {
        Range = 'Neo Animator',
        Head = 'Naga Somen',
        Neck = 'Empath Necklace',
        Ear1 = 'Enmerkar Earring',
        Ear2 = 'Burana Earring',
        Body = 'Naga Samue',
        Hands = 'Foire Dastanas +1',
        Ring1 = 'Tali\'ah Ring',
        Ring2 = 'C. Palug Ring',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
        Waist = 'Ukko Sash',
        Legs = 'Foire Churidars +2',
        Feet = 'Mpaca\'s Boots',
    },
    Pet_WS_Melee = {
        Head = 'Kara. Cappello +2',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Burana Earring',
        Ear2 = 'Domes. Earring',
        Body = 'Pitre Tobe +3',
        Hands = 'Mpaca\'s Gloves',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'C. Palug Ring',
        Waist = 'Incarnation Sash',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    Pet_WS_Ranger = {
        Head = 'Kara. Cappello +2',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Burana Earring',
        Ear2 = 'Crep. Earring',
        Body = 'Pitre Tobe +3',
        Hands = 'Mpaca\'s Gloves',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'C. Palug Ring',
        Waist = 'Klouskap Sash',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },

    Tp_Default = {
        Main = 'Sakpata\'s Fists',
        Head = 'Malignance Chapeau',
        Ammo = 'Automat. Oil +3',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Cessance Earring',
        Ear2 = 'Kara. Earring +1',
        Body = 'Pitre Tobe +3',
        Hands = 'Mpaca\'s Gloves',
        Ring1 = 'Epona\'s Ring',
        Ring2 = 'Gere Ring',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
        Waist = 'Moonbow Belt',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    Tp_Hybrid = {
        Neck = 'Empath Necklace',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Malignance Gloves',
        Ring2 = 'C. Palug Ring',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    Tp_Acc = {
        Ear1 = 'Telos Earring',
        Ear2 = 'Cessance Earring',
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
    },

    Precast = {
        Head = 'Haruspex Hat',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Loquac. Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Taeon Tabard',
        Ring2 = 'Prolix Ring',
    },
    Midcast = {},
    Preshot = {},
    Midshot = {},
    PetAction = {}, -- default for automaton actions; add a set named after the action to override

    Ws_Default = {
        Head = 'Blistering Sallet +1',
        Neck = 'Fotia Gorget',
        Ear1 = 'Schere Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Mpaca\'s Doublet',
        Hands = 'Ryuo Tekko',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'Gere Ring',
        Waist = 'Fotia Belt',
        Legs = 'Mpaca\'s Hose',
        Feet = 'Mpaca\'s Boots',
    },
    Ws_Hybrid = {},
    Ws_Acc = {},
    ['Shijin Spiral'] = {
        Head = 'Malignance Chapeau',
        Neck = 'Fotia Gorget',
        Ear1 = 'Schere Earring',
        Ear2 = 'Mache Earring +1',
        Body = 'Herculean Vest',
        Hands = 'Malignance Gloves',
        Ring1 = 'Niqmaddu Ring',
        Ring2 = 'Gere Ring',
        Waist = 'Moonbow Belt',
        Legs = 'Samnuha Tights',
        Feet = { Name = 'Herculean Boots', Augment = { [1] = 'Accuracy+20', [2] = 'Attack+6', [3] = 'AGI+1', [4] = '"Triple Atk."+3' } },
    },
    -- ['Weapon Skill Name'] = {}, ['Weapon Skill Name_Acc'] = {},

    ['Activate'] = {},
    ['Deus Ex Automata'] = {},
    ['Repair'] = {
        Ammo = 'Automat. Oil +3',
        Ear1 = 'Guignol Earring',
        Body = 'Foire Tobe +2',
        Hands = 'Rao Kote',
        Ring1 = 'Overbearing Ring',
        Feet = 'Foire Babouches',
    },
    ['Maintenance'] = {
        Ammo = 'Automat. Oil +3',
        Ear1 = 'Guignol Earring',
        Body = 'Foire Tobe +2',
        Hands = 'Rao Kote',
        Ring1 = 'Overbearing Ring',
        Feet = 'Foire Babouches',
    },
    ['Overdrive'] = {
        -- this set will force on the ability AND stay on for the duration of OD, dont change the body out because of that
        Range = 'Animator P +1',
        Ammo = 'Automat. Oil +3',
        Head = 'Kara. Cappello +2',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Enmerkar Earring',
        Ear2 = 'Domes. Earring',
        Body = 'Pitre Tobe +3',
        Hands = 'Mpaca\'s Gloves',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'C. Palug Ring',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
        Waist = 'Klouskap Sash',
        Legs = 'Heyoka Subligar',
        Feet = 'Mpaca\'s Boots',
    },
    ['Ventriloquy'] = {},
    ['Role Reversal'] = {},
    ['Tactical Switch'] = {},
    ['Cooldown'] = {},
    ['Heady Artifice'] = {},
    Maneuver = {
        Ear1 = 'Burana Earring',
        Body = 'Kara. Farsetto +1',
        Hands = 'Foire Dastanas +1',
        Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
    },
    Buffs = { -- worn while that buff is up (engine layer)
        Overdrive = {
            -- this set will force on the ability AND stay on for the duration of OD, dont change the body out because of that
            Range = 'Animator P +1',
            Ammo = 'Automat. Oil +3',
            Head = 'Kara. Cappello +2',
            Neck = 'Shulmanu Collar',
            Ear1 = 'Enmerkar Earring',
            Ear2 = 'Domes. Earring',
            Body = 'Pitre Tobe +3',
            Hands = 'Mpaca\'s Gloves',
            Ring1 = 'Varar Ring +1',
            Ring2 = 'C. Palug Ring',
            Back = { Name = 'Visucius\'s Mantle', Augment = { [1] = 'Pet: R.Acc.+20', [2] = 'Pet: R.Atk.+20', [3] = 'Pet: Haste+10', [4] = 'Accuracy+20', [5] = 'Attack+20', [6] = 'Pet: Acc.+20', [7] = 'Pet: Atk.+20' } },
            Waist = 'Klouskap Sash',
            Legs = 'Heyoka Subligar',
            Feet = 'Mpaca\'s Boots',
        },
    },
    Absorb = {}, -- every Absorb- spell (land rate: Dark Magic skill, macc; potency is not skill)
    Absorb_TP = {}, -- Absorb-TP on top of Absorb
    Cure_Received = {},
    Cursna_Received = {},
    Phalanx_Received = {},
    Protect_Shell_Received = {},
    Regen_Received = {},
    Refresh_Received = {},
    Waltz_Received = {},
};
profile.Sets = sets;

profile.Packer = {
    {Name = 'Automat. Oil +3', Quantity = 'all'},
    {Name = 'Bean Daifuku', Quantity = 'all'},
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    gcinclude.WeaponModes = {'None'}; -- e.g. {'None', 'Example'} with a Weapon_Example set
    gcinclude.DefaultWeapons = 'None';
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
    gFunc.EquipSet(sets.Idle);
    local pet = gData.GetPet();
    if (player.Status ~= 'Engaged') and (pet ~= nil) then
        gFunc.EquipSet(sets.Idle_Pet);
        gFunc.EquipSet(gcinclude.FindSet('Idle_Pet_' .. gcdisplay.GetCycle('PupMode')));
        if (pet.Status == 'Engaged') then -- pet fighting, you not
            gcinclude.EquipMode('Pet_Only_Tp');
            gFunc.EquipSet(gcinclude.FindSet('Pet_' .. gcdisplay.GetCycle('PupMode')));
        end
    end
    if (player.Status == 'Engaged') then
        gcinclude.EquipMode('Tp');
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    elseif (player.IsMoving == true) then
        gFunc.EquipSet(sets.Movement);
    end

    -- job layers go before CheckDefault so engine layers (weapons, mdt/Aminon, Hoxne, TH, received, buffs, XIRoll) sit on top
    if (pet ~= nil) and (pet.Status == 'Engaged') and (pet.TP > 950) then -- GAC's threshold, ahead of its weapon skill
        gFunc.EquipSet(gcinclude.FindSet('Pet_WS_' .. gcdisplay.GetCycle('PupMode')));
    end
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end
    gcinclude.CheckDefault();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    if string.find(ability.Name, 'Maneuver', 1, true) then gFunc.EquipSet(sets.Maneuver) end -- any element
    ByName(ability.Name);
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
