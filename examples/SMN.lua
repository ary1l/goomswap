local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');

-- SMN example. Gear from GetAwayCoxn's Luashitacast-Profiles (github.com/GetAwayCoxn/Luashitacast-Profiles,
-- MIT, see LICENSE-GetAwayCoxn.txt); swap in your own.
-- Sets named after an ability, spell, skill or weapon skill (['Astral Flow'], ['Savage Blade'])
-- are worn by name (gcinclude.ByName); a spell with no set uses its family's (['Cure'] for Cure IV).
-- Add '<Name>_Hybrid' / '<Name>_Acc' for /meleeset. Empty sets do nothing.
local sets = {
    Incapacitated = { -- slept, petrified, stunned or terrorized: worn over your /def set (else Dt) minus Main/Sub/Range/Ammo; add extra pieces here
    },
    -- Weapon modes: add a Weapon_<Mode> set and the mode to WeaponModes in OnLoad.
    -- Weapon_Example = { Main = 'Item Name', Sub = 'Item Name' },

    Idle = {
        Main = 'Bolelabunga',
        Sub = 'Ammurapi Shield',
        Ammo = 'Epitaph',
        Head = 'Convoker\'s Horn',
        Neck = 'Loricate Torque +1',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Etiolation Earring',
        Body = 'Shomonjijoe +1',
        Hands = 'Asteria Mitts +1',
        Ring1 = 'Defending Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Solemnity Cape',
        Waist = 'Gishdubar Sash',
        Legs = 'Assid. Pants +1',
        Feet = 'Volte Gaiters',
    },
    Idle_Regen = {
        Neck = 'Bathy Choker +1',
        Ear1 = 'Infused Earring',
        Ring2 = 'Chirich Ring +1',
    },
    Idle_Refresh = {
        Head = 'Convoker\'s Horn',
        Ear1 = 'C. Palug Earring',
        Ear2 = 'Beck. Earring',
        Body = 'Shomonjijoe +1',
        Hands = 'Asteria Mitts +1',
        Ring2 = 'Stikini Ring +1',
        Waist = 'Fucho-no-Obi',
        Legs = 'Assid. Pants +1',
        Feet = 'Volte Gaiters',
    },
    Resting = {},
    Town = {
        Main = 'Gridarvor',
        Sub = 'Khonsu',
        Ammo = 'Epitaph',
        Head = 'Beckoner\'s Horn +1',
        Body = 'Shomonjijoe +1',
        Hands = 'Asteria Mitts +1',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'Varar Ring +1',
        Back = 'Solemnity Cape',
        Waist = 'Regal Belt',
        Legs = 'Assid. Pants +1',
        Feet = 'Herald\'s Gaiters',
    },
    Movement = {
        Feet = 'Herald\'s Gaiters',
    },
    Dt = {
        Head = 'Nyame Helm',
        Neck = 'Empath Necklace',
        Ear1 = 'Odnowa Earring +1',
        Ear2 = 'Handler\'s Earring +1',
        Body = 'Gleti\'s Cuirass',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Defending Ring',
        Ring2 = 'Gelatinous Ring +1',
        Back = 'Solemnity Cape',
        Waist = 'Isa Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    mdt = {},
    Aminon = {},
    SIR = {
        Ammo = 'Staunch Tathlum',--10
        Neck = 'Loricate Torque +1',--5
        Hands = 'Amalric Gages +1',--11
        Waist = 'Rumination Sash',--10
        Feet = 'Amalric Nails +1',--16
    },
    TH = { -- /th: until the target is tagged; Main/Sub/Range here stay on while /th is on
        Ammo = 'Per. Lucky Egg',
        Waist = 'Chaac Belt',
    },
    Idle_Pet = {
        --only need 14, rest 512|575|670 skill for favor then refresh
        Main = 'Gridarvor',--5
        Sub = 'Elan Strap',
        Ammo = 'Epitaph',
        Head = 'Beckoner\'s Horn +1',
        Neck = 'Caller\'s Pendant',--1,
        Ear1 = 'Evans Earring',--2
        Ear2 = 'Beck. Earring',
        Body = 'Beck. Doublet +1',--6
        Hands = 'Asteria Mitts +1',
        Ring1 = 'Evoker\'s Ring',--1
        Ring2 = 'Stikini Ring +1',
        Back = 'Campestres\'s Cape',
        Waist = 'Isa Belt',
        Legs = 'Assid. Pants +1',
        Feet = 'Volte Gaiters',
    },
    Pet_Dt = {
        Neck = 'Empath Necklace',
        Ear1 = 'Enmerkar Earring',
        Ear2 = 'Handler\'s Earring +1',
        Waist = 'Isa Belt',
    },
    Pet_Only_Tp_Default = {
        Main = 'Gridarvor',
        Sub = 'Elan Strap',
        Ammo = 'Epitaph',
        Head = 'Beckoner\'s Horn +1',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Enmerkar Earring',
        Ear2 = 'Beck. Earring',
        Hands = 'Asteria Mitts +1',
        Ring1 = 'Evoker\'s Ring',
        Ring2 = 'Varar Ring +1',
        Back = 'Campestres\'s Cape',
        Waist = 'Regal Belt',
        Legs = 'Taeon Tights',
        Feet = 'Gleti\'s Boots',
    },

    Tp_Default = {
        Main = 'Marin Staff +1',
        Sub = 'Elan Strap',
        Head = 'Nyame Helm',
        Neck = 'Sanctity Necklace',
        Ear1 = 'Mache Earring +1',
        Ear2 = 'Telos Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Petrov Ring',
        Back = 'Aurist\'s Cape +1',
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Tp_Hybrid = {
        Neck = 'Empath Necklace',
        Ear1 = 'Mache Earring +1',
        Ring1 = 'Cacoethic Ring +1',
    },
    Tp_Acc = {
        Ring1 = 'Cacoethic Ring +1',
        Ring2 = 'Chirich Ring +1',
    },

    Precast = {
        Ammo = 'Sapience Orb',
        Head = 'Haruspex Hat',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Malignance Earring',
        Ear2 = 'Etiolation Earring',
        Body = 'Inyanga Jubbah +2',
        Ring1 = 'Kishar Ring',
        Ring2 = 'Prolix Ring',
        Waist = 'Embla Sash',
        Feet = 'Amalric Nails +1',
    },
    ['Healing Magic_Precast'] = {
        Ear1 = 'Mendi. Earring',
        Feet = 'Vanya Clogs',
    },
    ['Enhancing Magic_Precast'] = {
        Waist = 'Siegel Sash',
    },
    Stoneskin_Precast = {
        Head = 'Umuthi Hat',
        Waist = 'Siegel Sash',
    },
    Midcast = {
        Ammo = 'Staunch Tathlum',--10
        Neck = 'Loricate Torque +1',--5
        Hands = 'Amalric Gages +1',--11
        Waist = 'Rumination Sash',--10
        Feet = 'Amalric Nails +1',--16
    },
    Preshot = {},
    Midshot = {},
    ['Healing Magic'] = {
        --I cap is 50, II cap is 30
        Main = 'Bunzi\'s Rod',--I 30
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Nodens Gorget',--I 5
        Ear1 = 'Mendi. Earring',--I 5
        Ear2 = 'Regal Earring',
        Hands = 'Telchine Gloves',--I 9
        Ring1 = 'Stikini Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = 'Solemnity Cape',--I 7
        Waist = 'Rumination Sash',
        Feet = { Name = 'Medium\'s Sabots', Augment = { [1] = 'MND+6', [2] = '"Conserve MP"+5', [3] = 'MP+40', [4] = '"Cure" potency +3%' } },
    },
    ['Enhancing Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Head = 'Befouled Crown',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Mendi. Earring',
        Ear2 = 'Andoaa Earring',
        Ring1 = 'Stikini Ring +1',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = 'Solemnity Cape',
        Waist = 'Embla Sash',
        Legs = 'Telchine Braconi',
        Feet = 'Telchine Pigaches',
    },
    ['Dark Magic'] = {
        Main = 'Bunzi\'s Rod',
        Sub = 'Ammurapi Shield',
        Ammo = 'Pemphredo Tathlum',
        Neck = 'Erra Pendant',
        Ear1 = 'Regal Earring',
        Ear2 = 'Malignance Earring',
        Ring1 = 'Kishar Ring',
        Ring2 = { Name = 'Metamor. Ring +1', AugPath='A' },
        Back = { Name = 'Aurist\'s Cape +1', AugPath='A' },
        Waist = 'Fucho-no-Obi',
        Legs = 'Nyame Flanchard',
        Feet = 'Amalric Nails +1',
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
        Ring1 = 'Purity Ring',
        Waist = 'Gishdubar Sash',
        Feet = 'Vanya Clogs',
    },
    Stoneskin = {
        Neck = 'Nodens Gorget',
        Waist = 'Siegel Sash',
    },
    Refresh = {
        Waist = 'Gishdubar Sash',
    },
    BP_Delay = { -- worn on Blood Pact: Rage / Ward use
        --I/II cap at 15, the rest need 680 skill total
        Ammo = 'Epitaph',--II 5
        Head = 'Beckoner\'s Horn +1',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Evans Earring',--I 2
        Ear2 = 'Andoaa Earring',
        Body = 'Shomonjijoe +1',--I 8
        Hands = 'Con. Bracers',--I 5
        Ring1 = 'Evoker\'s Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Conveyance Cape',--II 3
    },
    BloodPact = { -- default for pet actions; add a set named after a pact to override
        Main = 'Gridarvor',
        Sub = 'Elan Strap',
        Ammo = 'Epitaph',
        Head ='Helios Band',
        Neck = 'Shulmanu Collar',
        Ear1 = 'Lugalbanda Earring',
        Ear2 = 'Beck. Earring',
        Body = 'Con. Doublet +2',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'Varar Ring +1',
        Waist = 'Incarnation Sash',
        Legs = 'Apogee Slacks +1',
        Feet = 'Helios Boots',
    },
    BloodPact_Magical = {
        Main = 'Espiritus',
        Sub = 'Elan Strap',
        Ammo = 'Epitaph',
        Head = 'Nyame Helm',--cait head
        Neck = 'Adad Amulet',
        Ear1 = 'Lugalbanda Earring',
        Ear2 = 'Beck. Earring',
        Body = 'Con. Doublet +2',
        Hands = 'Asteria Mitts +1',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'Varar Ring +1',
        Back = 'Campestres\'s Cape',
        Waist = 'Regal Belt',
        Legs = 'Apogee Slacks +1',
        Feet = 'Helios Boots',--replace these
    },
    BloodPact_Hybrid = {
        --special set for flamming crush and burning strike (for now)
        Main = 'Gridarvor',
        Sub = 'Elan Strap',
        Ammo = 'Epitaph',
        Head ='Helios Band',--replace this
        Neck = 'Adad Amulet',
        Ear1 = 'Lugalbanda Earring',
        Ear2 = 'Beck. Earring',
        Body = 'Con. Doublet +2',
        --Body = 'Con. Doublet +2',-- after +2
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Varar Ring +1',
        Ring2 = 'Varar Ring +1',
        Back = 'Campestres\'s Cape',
        Waist = 'Regal Belt',
        Legs = 'Apogee Slacks +1',
        Feet = 'Helios Boots',
    },
    BloodPact_Skill = {
        Ammo = 'Epitaph',
        Head = 'Beckoner\'s Horn +1',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'C. Palug Earring',
        Body = 'Beck. Doublet +1',
        Hands = 'Lamassu Mitts +1',
        Ring1 = 'Evoker\'s Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Campestres\'s Cape',
        Waist = 'Regal Belt',
        Legs = 'Beck. Spats +1',
    },
    ['Wind\'s Blessing'] = {
        --mostly for Wind's Blessing'
        Ammo = 'Epitaph',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'C. Palug Earring',
        Body = 'Shomonjijoe +1',--need to Augment
        Hands = 'Lamassu Mitts +1',
        Ring1 = 'Evoker\'s Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Campestres\'s Cape',
        Waist = 'Regal Belt',
        Legs = 'Assid. Pants +1',--need to Augment
    },
    BloodPact_Healing = {
        --avatar HP+
        Ammo = 'Epitaph',
        Head = 'Beckoner\'s Horn +1',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'Beck. Earring',
        Body = 'Beck. Doublet +1',
        Hands = 'Lamassu Mitts +1',
        Ring1 = 'Evoker\'s Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Campestres\'s Cape',
        Legs = 'Beck. Spats +1',
    },
    BloodPact_Enfeebling = {
        Main = 'Espiritus',
        Sub = 'Elan Strap',
        Ammo = 'Epitaph',
        Head = 'Nyame Helm',
        Neck = 'Adad Amulet',
        Ear1 = 'Lugalbanda Earring',
        Ear2 = 'Beck. Earring',
        Body = 'Nyame Mail',
        --Body = 'Con. Doublet +2',--after +2
        Hands = 'Lamassu Mitts +1',
        Ring1 = 'Evoker\'s Ring',
        Ring2 = 'C. Palug Ring',
        Back = 'Campestres\'s Cape',
        Waist = 'Regal Belt',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
        --Feet = 'Con. Pigaches',--after +2
    },
    ['Summoning'] = {},

    Ws_Default = {
        Ammo = 'Pemphredo Tathlum',
        Head = 'Pixie Hairpin +1',
        Neck = 'Baetyl Pendant',
        Ear1 = 'Friomisi Earring',
        Ear2 = 'Crematio Earring',
        Body = 'Nyame Mail',
        Hands = 'Nyame Gauntlets',
        Ring1 = 'Shiva Ring +1',
        Ring2 = 'Karieyh Ring +1',
        Waist = 'Eschan Stone',
        Legs = 'Nyame Flanchard',
        Feet = 'Nyame Sollerets',
    },
    Ws_Hybrid = {},
    Ws_Acc = {},
    -- ['Weapon Skill Name'] = {}, ['Weapon Skill Name_Acc'] = {},

    ['Astral Flow'] = {},
    ['Elemental Siphon'] = {
        Ammo = 'Epitaph',
        Head = 'Beckoner\'s Horn +1',
        Neck = 'Incanter\'s Torque',
        Ear1 = 'Andoaa Earring',
        Ear2 = 'C. Palug Earring',
        Body = 'Beck. Doublet +1',
        Hands = 'Lamassu Mitts +1',
        Ring1 = 'Evoker\'s Ring',
        Ring2 = 'Stikini Ring +1',
        Back = 'Campestres\'s Cape',
        Legs = 'Beck. Spats +1',
        Feet = 'Beck. Pigaches +1',
    },
    ['Mana Cede'] = {},
    ['Astral Conduit'] = {},
    ['Apogee'] = {},
    ['Avatar\'s Favor'] = {},
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
};

local ByName, Family = gcinclude.ByName, gcinclude.Family;
local BPKind = {}; -- GAC's pact lists: sets.BloodPact (physical) first, then BloodPact_<kind>
for kind, list in pairs({
    Skill = {'Shining Ruby','Glittering Ruby','Crimson Howl','Inferno Howl','Frost Armor','Crystal Blessing','Aerial Armor','Hastega II','Fleet Wind','Hastega','Earthen Ward','Earthen Armor','Rolling Thunder','Lightning Armor','Soothing Current','Ecliptic Growl','Heavenward Howl','Ecliptic Howl','Noctoshield','Dream Shroud','Altana\'s Favor','Reraise','Reraise II','Reraise III','Raise','Raise II','Raise III','Wind\'s Blessing'},
    Magical = {'Searing Light','Meteorite','Holy Mist','Inferno','Fire II','Fire IV','Meteor Strike','Conflag Strike','Diamond Dust','Blizzard II','Blizzard IV','Heavenly Strike','Aerial Blast','Aero II','Aero IV','Wind Blade','Earthen Fury','Stone II','Stone IV','Geocrush','Judgement Bolt','Thunder II','Thunder IV','Thunderstorm','Thunderspark','Tidal Wave','Water II','Water IV','Grand Fall','Howling Moon','Lunar Bay','Ruinous Omen','Somnolence','Nether Blast','Night Terror','Level ? Holy'},
    Hybrid = {'Flaming Crush','Burning Strike'},
    Healing = {'Healing Ruby','Healing Ruby II','Whispering Wind','Spring Water'},
    Enfeebling = {'Diamond Storm','Sleepga','Shock Squall','Slowga','Tidal Roar','Pavor Nocturnus','Ultimate Terror','Nightmare','Mewing Lullaby','Eerie Eye'},
}) do
    for _, name in ipairs(list) do BPKind[name] = kind end
end

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
        gFunc.EquipSet(sets.BloodPact);
        if (BPKind[petAction.Name] ~= nil) then ByName('BloodPact_' .. BPKind[petAction.Name]) end
        ByName(petAction.Name); -- a set named after the pact goes on top
        return;
    end
    local player = gData.GetPlayer();
    gFunc.EquipSet(sets.Idle);
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
    if (gcdisplay.GetToggle('DTset') == true) then gFunc.EquipSet(sets.Dt) end
    if (gcdisplay.GetToggle('Kite') == true) then gFunc.EquipSet(sets.Movement) end
    gcinclude.CheckDefault();
end

profile.HandleAbility = function()
    local ability = gData.GetAction();
    if (ability.Type == 'Blood Pact: Rage') or (ability.Type == 'Blood Pact: Ward') then gFunc.EquipSet(sets.BP_Delay) end
    ByName(ability.Name);
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
