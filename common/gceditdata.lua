-- /gcedit constants: slot bits, set groups, engine set names, text and icon codes. Data only.
local data = {}

data.SLOT_BIT = {
    Main = 0,
    Sub = 1,
    Range = 2,
    Ammo = 3,
    Head = 4,
    Body = 5,
    Hands = 6,
    Legs = 7,
    Feet = 8,
    Neck = 9,
    Waist = 10,
    Ear1 = 11,
    Ear2 = 12,
    Ring1 = 13,
    Ring2 = 14,
    Back = 15,
} -- LAC constants.EquipSlots - 1

data.GROUPS = {
    'Idle',
    'Defense',
    'Melee',
    'Weapon skills',
    'Weapons',
    'Casting',
    'Job abilities',
    'Named weapon skills',
    'Spells (by name)',
    'Received',
    'Buffs',
    'Hoxne',
    'Other',
}

data.DEFENSE = {
    Dt = true,
    mdt = true,
    Aminon = true,
    Incapacitated = true,
    Sleeping = true,
    Doomed = true,
    SIR = true,
    Movement = true,
}

data.CASTING = {
    Precast = true,
    Midcast = true,
    Preshot = true,
    Midshot = true,
    Ninjutsu = true,
    Singing = true,
    Geomancy = true,
    Handbell = true,
    ['Blue Magic'] = true,
    Absorb = true,
    Absorb_TP = true,
    Cure_LowMP = true,
    Cure_Dt = true,
    Self_Cure = true,
    LightBonus = true,
}

-- Sets that go on first for their action: a slot they leave empty keeps whatever was worn before (for Tp_Default:
-- the Idle set's piece, Idle goes on under it in the job files' HandleDefault).
data.BASE = {
    Idle = 'keeps what you had on',
    Ws_Default = 'keeps your TP gear',
    Precast = 'keeps what you had on',
    Midcast = 'keeps your precast gear',
    Preshot = 'keeps what you had on',
    Midshot = 'keeps your preshot gear',
    Tp_Default = "takes Idle's piece",
}

-- Engine set names (docs/sets.md, gcinclude FindSet), offered when the file has none of that name.
data.ENGINE = {
    'Idle',
    'Idle_Regen',
    'Idle_Refresh',
    'Idle_Regain',
    'Resting',
    'Town',
    'Movement',
    'Dt',
    'mdt',
    'Aminon',
    'Incapacitated',
    'Sleeping',
    'Doomed',
    'SIR',
    'TH',
    'Proc',
    'Tp_Default',
    'Tp_SubtleBlow',
    'Tp_Acc',
    'Ws_Default',
    'Ws_Acc',
    'Ws_SubtleBlow',
    'Ws_LowBuff',
    'Ws_HighBuff',
    'Ws_PDL',
    'Ws_Dt',
    'Ws_Proc',
    'Precast',
    'Midcast',
    'Preshot',
    'Midshot',
    'Midshot_Acc',
    'Absorb',
    'Absorb_TP',
    'LightBonus',
    'XIRoll',
    'Hoxne_Tp',
    'Hoxne_Idle',
    'Hoxne_Dt',
    'Hoxne_Ws',
    'Buffs',
    'Buffs_Tp',
    'Buffs_Idle',
    'Buffs_Ws',
    'Buffs_Precast',
    'Buffs_Midcast',
}

data.SJIS = {
    [0x8160] = '~',
    [0x8169] = '(',
    [0x816A] = ')',
    [0x8146] = ':',
    [0x8145] = '-',
    [0x817B] = '+',
    [0x817C] = '-',
    [0x8193] = '%',
    [0x8140] = ' ',
    [0x8141] = ',',
    [0x8142] = '.',
}

data.ELEM_ICON = {
    [0x1F] = 'Fire',
    [0x20] = 'Ice',
    [0x21] = 'Wind',
    [0x22] = 'Earth',
    [0x23] = 'Lightning',
    [0x24] = 'Water',
    [0x25] = 'Light',
    [0x26] = 'Dark',
}

return data
