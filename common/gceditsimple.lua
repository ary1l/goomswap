-- /gcedit's Simple view: the same editor with fewer buttons in sight. Sets show what they are for in plain words
-- beside their names (Tp_Default: Fighting), the top bar keeps Settings and Save (the rest under ...), and the right
-- pane has Gear, What goes on and Stats (To fill when something is left). Full view is the editor as before. The
-- choice is kept per job (the .gcedit-ui file); a new job file (the example, a draft) starts in Simple.
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
    function M.On()
        local p = editorState.preferences or {}
        if p.view ~= nil then return p.view == 'simple' end
        local d = editorState.document or {}
        return ((d.example ~= nil) and (d.example ~= false)) or (d.sourcePath ~= nil)
    end
    function M.Set(simple)
        editorState.preferences.view = simple and 'simple' or 'full'
        editorState.preferences.dirty = true
    end
    return M
end
