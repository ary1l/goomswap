-- /gcedit: what a set is for, in plain words (Tp_Default: Fighting), shown when you hover a set in the list. (There
-- was a Simple view with these as the names; the editor now has one view.)
return function(editorState)
    local M = {}
    local NAMES = {
        Idle = 'Standing', Town = 'In town', Movement = 'Moving', Resting = 'Resting', Tp_Default = 'Fighting',
        Ws_Default = 'Any weapon skill', Precast = 'Fast Cast (precast)', Midcast = 'Casting (midcast)',
        Preshot = 'Ranged: preshot', Midshot = 'Ranged: midshot', Dt = 'Damage taken (/dt)',
        mdt = 'Magic damage taken (/mdt)', Aminon = 'Aminon (/aminon)', TH = 'Treasure Hunter (/th)',
        SIR = 'Spell interruption (/sir)', Incapacitated = 'Slept, stunned, petrified', Sleeping = 'Asleep',
        Doomed = 'Doom or Bane', Proc = 'Proc (/proc)', Ws_Proc = 'Weapon skill: proc', XIRoll = 'A roll at 11',
        Burst = 'Magic burst', Idle_Regen = 'Standing: low HP (Regen)', Idle_Refresh = 'Standing: low MP (Refresh)',
        Idle_Regain = 'Standing: Regain', Buffs = 'While a buff is up', Buffs_Ws = 'Weapon skills while a buff is up',
        Buffs_Midcast = 'Spells while a buff is up', Holy_Water = 'Holy Water',
    }
    local PATTERNS = {
        { '^Tp_(.+)$', 'Fighting: %1' }, { '^Ws_(.+)$', 'Weapon skills: %1' }, { '^Idle_(.+)$', 'Standing: %1' },
        { '^Weapon_(.+)$', 'Weapons: /wm %1' }, { '^Dt_(.+)$', 'Damage taken: %1' }, { '^Midshot_(.+)$', 'Ranged: %1' },
        { '^(.+)_Precast$', '%1: precast' },
    }
    -- What a set is for, in plain words; nil when its name says it already (Savage Blade, Cure).
    function M.Label(name)
        if type(name) ~= 'string' then return nil end
        if NAMES[name] ~= nil then return NAMES[name] end
        for _, p in ipairs(PATTERNS) do
            local out, n = string.gsub(name, p[1], p[2])
            if n > 0 then return out end
        end
        return nil
    end
    return M
end
