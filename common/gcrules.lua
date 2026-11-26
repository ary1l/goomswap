-- Rules: a job file's "when this, wear that" as data (gcinclude.Rules), so its conditions need no Lua. GoomSwap
-- compiles them once at load and runs them from its own handler wrappers; the job file's code is untouched.
--
--   gcinclude.Rules = {
--       { on = 'Midcast', when = { skill = 'Healing Magic', target = 'me' }, wear = 'Self_Cure' },
--       { on = 'Default', when = { buff = 'Cover' }, wear = 'Fealty', layer = 'top' },
--       { on = 'Midcast', first = {                       -- the first one whose conditions hold, only
--           { when = { skill = 'Enhancing Magic' }, wear = 'Enh' },
--           { when = { skill = 'Healing Magic' }, wear = 'Heal' } } },
--       { on = 'Midcast', when = { name = { has = 'Nocto' } }, item = { Head = 'Pixie Hairpin +1' } },
--       { on = 'Precast', when = { name = 'Stun', mpp = { lt = 10 } }, stop = true },
--   }
--
-- on: the phase (PHASES). when: every key must hold; `any = { {...}, {...} }` holds when one of its tables does.
-- wear: a set by name, with its weapon and /mset versions as gcinclude.ByName wears them (exact = true: that set
-- only, as gFunc.EquipSet). item: slot -> item. layer: 'job' (the default: where a job file's own `if` goes, under
-- GoomSwap's layers) or 'top' (over them; still under /lock, holds, Incapacitated, Sleeping, Doomed, SmartSwap and
-- Dispelga's Daybreak). at: a spot in the job file's code (`gcinclude.RulesAt('Midcast 1')`, left by /gcedit's
-- Convert where `if`s were), so the rule goes on exactly there; layer is then not used. stop: cancel the action (Precast, Ability, Weaponskill, Item, Preshot only: LAC's
-- CancelAction). off: kept, not used. note: your words, shown in /gcedit.
--
-- Values: a text key takes 'Exact', { 'A', 'B' } (any of them), or { is = .., isnt = .., has = .., start = ..,
-- ends = .. } (each a text or a list; has/start/ends match case as written, like string.find). A number key takes
-- { lt = , le = , gt = , ge = , eq = , ne = } (all must hold). A yes/no key takes true or false.
-- Pure: game data comes in through an api table (gcinclude.RulesApi), so tests run without the game.
local R = {}

R.PHASES = { 'Default', 'Pet', 'Precast', 'Midcast', 'Ability', 'Weaponskill', 'Preshot', 'Midshot', 'Item' }
R.PHASE_LABEL = { Default = 'Not acting', Pet = 'Pet action', Precast = 'Starting a spell', Midcast = 'Casting',
    Ability = 'Job ability', Weaponskill = 'Weapon skill', Preshot = 'Starting a shot', Midshot = 'Ranged shot',
    Item = 'Using an item' }
-- the builder's When menu: each moment in words, with LuAshitacast's name for it
R.PHASE_LONG = { Default = 'Not acting: idle, fighting, resting, moving', Pet = 'Your pet uses a move',
    Precast = 'Starting a spell (precast: Fast Cast gear)', Midcast = 'Casting a spell (midcast: as it lands)',
    Ability = 'Using a job ability', Weaponskill = 'Using a weapon skill', Preshot = 'Starting a ranged attack (preshot)',
    Midshot = 'Firing a ranged attack (midshot)', Item = 'Using an item' }
R.STOPPABLE = { Precast = true, Ability = true, Weaponskill = true, Item = true, Preshot = true } -- LAC gFunc.CancelAction
local ACTION = { Precast = true, Midcast = true, Ability = true, Weaponskill = true, Preshot = true, Midshot = true,
    Item = true }
local SPELL = { Precast = true, Midcast = true }
local SLOTS = { Main = true, Sub = true, Range = true, Ammo = true, Head = true, Neck = true, Ear1 = true, Ear2 = true,
    Body = true, Hands = true, Ring1 = true, Ring2 = true, Back = true, Waist = true, Legs = true, Feet = true }
R.SLOTS = { 'Main', 'Sub', 'Range', 'Ammo', 'Head', 'Neck', 'Ear1', 'Ear2', 'Body', 'Hands', 'Ring1', 'Ring2', 'Back',
    'Waist', 'Legs', 'Feet' }

local ELEMENTS = { 'Fire', 'Ice', 'Wind', 'Earth', 'Thunder', 'Water', 'Light', 'Dark' }
local JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN',
    'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }
-- /wm, /mset...: the gcdisplay cycle each short name reads; any other name is read as it is.
R.CYCLES = { wm = 'Weapons', mw = 'Main', sw = 'Sub', rw = 'Range', ammoset = 'Ammo', mset = 'MeleeSet',
    nukeset = 'NukeSet', idleset = 'IdleSet', wsset = 'WsSet', tankset = 'TankSet', weapon = 'Weapon',
    pupmode = 'PupMode', hoxne = 'Hoxne' }
R.TOGGLES = { dt = 'DTset', mdt = 'MDTset', kite = 'Kite', th = 'TH', sir = 'SIR', proc = 'PROC', burst = 'Burst',
    aminon = 'Aminon', death = 'Death', songlock = 'SongLock', forcestring = 'String' }

-- Each condition: what it reads (from the api), its kind, the phases it means something in (nil: every phase), and
-- what /gcedit's builder offers. LAC's gData fields (docs/gdata.html): Player Status HPP MPP TP IsMoving SubJob
-- MainJobSync; Action Name Skill Element Type; ActionTarget Name Type HPP Distance; Environment DayElement
-- WeatherElement Area Time; Pet HPP TP Name; PetAction Name Element.
R.KEYS = {
    { key = 'status', label = 'Your status', kind = 'text', values = { 'Idle', 'Engaged', 'Resting' },
        hint = 'Idle, Engaged or Resting.' },
    { key = 'hpp', label = 'Your HP %', kind = 'number', hint = 'Your HP as a percent of your max HP.', example = '50' },
    { key = 'mpp', label = 'Your MP %', kind = 'number', hint = 'Your MP as a percent of your max MP.', example = '50' },
    { key = 'tp', label = 'Your TP', kind = 'number', hint = '0 to 3000.', example = '1000' },
    { key = 'moving', label = 'Moving', kind = 'bool', hint = 'You moved since the last position update.' },
    { key = 'combat', label = 'In combat', kind = 'bool',
        hint = 'A monster hit you or a party member, or you acted on one, in the last few seconds (CombatWindow).' },
    { key = 'sub', label = 'Sub job', kind = 'text', values = JOBS, hint = 'Your support job.' },
    { key = 'level', label = 'Your level', kind = 'number', hint = "Your main job's level, after level sync.", example = '99' },
    { key = 'name', label = 'Action name', kind = 'text', example = 'Cure IV, Savage Blade, Provoke',
        hint = 'The spell, ability, weapon skill or item, as the game writes it. In a pet action: the pet\'s move.', phases = { Pet = true, Precast = true, Midcast = true,
        Ability = true, Weaponskill = true, Preshot = true, Midshot = true, Item = true } },
    { key = 'family', label = 'Spell family', kind = 'text', phases = SPELL, example = 'Cure, Protect, Refresh',
        hint = "The spell's name without its tier: Cure IV and Cure V are Cure, Protect III is Protect." },
    { key = 'skill', label = 'Spell skill', kind = 'text', phases = SPELL, hint = "The spell's magic skill.", values = { 'Divine Magic', 'Healing Magic',
        'Enhancing Magic', 'Enfeebling Magic', 'Elemental Magic', 'Dark Magic', 'Summoning', 'Ninjutsu', 'Singing',
        'Blue Magic', 'Geomancy' } },
    { key = 'element', label = 'Spell element', kind = 'text', phases = { Precast = true, Midcast = true, Pet = true },
        hint = "The spell's element. weather / day: it matches today's weather or day.",
        values = { 'Fire', 'Ice', 'Wind', 'Earth', 'Thunder', 'Water', 'Light', 'Dark', 'weather', 'day' } },
    { key = 'type', label = 'Action type', kind = 'text', phases = ACTION, hint = 'What kind of spell or ability it is.', values = { 'White Magic', 'Black Magic',
        'Summoning', 'Ninjutsu', 'Bard Song', 'Blue Magic', 'Rune Enchantment', 'Ready', 'Blood Pact: Rage',
        'Blood Pact: Ward', 'Corsair Roll', 'Quick Draw' } },
    { key = 'target', label = 'Target', kind = 'text', phases = ACTION,
        hint = 'me: on you. other: on anyone else. Or what it is on: a PC, an NPC, your party, a monster.',
        values = { 'me', 'other', 'PC', 'NPC', 'Party', 'Alliance', 'Monster' } },
    { key = 'targethpp', label = "Target's HP %", kind = 'number', phases = ACTION, example = '25' },
    { key = 'distance', label = 'Target distance', kind = 'number', phases = ACTION, hint = 'In yalms.', example = '5' },
    { key = 'day', label = 'Day element', kind = 'text', values = ELEMENTS },
    { key = 'weather', label = 'Weather element', kind = 'text', values = { 'None', 'Fire', 'Ice', 'Wind', 'Earth',
        'Thunder', 'Water', 'Light', 'Dark' } },
    { key = 'zone', label = 'Zone', kind = 'text', hint = 'The zone you are in, as the game names it.' },
    { key = 'time', label = "Vana'diel time", kind = 'number', hint = '12.30 means 12:30.', example = '18.00' },
    { key = 'buff', label = 'Buff up', kind = 'list', example = 'Cover, Haste',
        hint = 'Holds when any of these buffs is on you (names as the game shows them).' },
    { key = 'allbuffs', label = 'Buffs all up', kind = 'list', example = 'Ebullience, Rapture',
        hint = 'Holds when every one of these buffs is on you.' },
    { key = 'nobuff', label = 'Buff not up', kind = 'list', example = 'Sleep',
        hint = 'Holds when none of these buffs is on you.' },
    { key = 'pet', label = 'You have a pet', kind = 'bool' },
    { key = 'pethpp', label = "Pet's HP %", kind = 'number' },
    { key = 'pettp', label = "Pet's TP", kind = 'number' },
    { key = 'petname', label = "Pet's name", kind = 'text' },
    { key = 'petstatus', label = "Pet's status", kind = 'text', values = { 'Idle', 'Engaged' } },
    { key = 'mode', label = 'Mode', kind = 'mode', hint = 'A GoomSwap mode and its value: /wm Naegling, /mset Acc, /nukeset Macc.' },
    { key = 'toggle', label = 'Toggle', kind = 'toggle', hint = 'A GoomSwap toggle, on or off: /dt, /kite, /th...' },
    { key = 'burst', label = 'Magic burst', kind = 'bool', phases = SPELL,
        hint = "The spell lands in a live skillchain of its element (GoomSwap's burst check)." },
    { key = 'dualwield', label = 'Can dual wield', kind = 'bool', hint = 'Your job and sub job can dual wield now.' },
    { key = 'wmpick', label = 'A /wm weapon is picked', kind = 'bool',
        hint = "Your /wm pick is a weapon mode, not None or Unknown (GoomSwap's IsWeaponValue)." },
    { key = 'inlist', label = "In GoomSwap's spell list", kind = 'text', phases = { Precast = true, Midcast = true },
        values = { 'BluMagPhysical', 'BluMagDebuff', 'BluMagStun', 'BluMagBuff', 'BluMagSkill', 'BluMagCure',
            'BluMagEnmity', 'BluMagTH' },
        hint = "The spell is in one of GoomSwap's own spell lists (gcinclude.BluMagPhysical...), as GoomSwap has it." },
    { key = 'nameset', label = 'Has a set named after it', kind = 'bool',
        phases = { Precast = true, Midcast = true, Ability = true, Weaponskill = true, Item = true },
        hint = 'Your job file has a set named after the spell, ability or weapon skill (Flash, Provoke), checked as it '
            .. 'happens: a set you add later counts.' },
    { key = 'familyset', label = 'Has a set for its family', kind = 'bool', phases = { Precast = true, Midcast = true },
        hint = "Your job file has a set named after the spell's family (Cure for Cure IV), checked as it happens." },
}
-- A condition's name in the builder, for the moment it is checked (the action's name: Spell, Ability...).
local NAME_LABEL = { Precast = 'Spell (exact name)', Midcast = 'Spell (exact name)', Ability = 'Ability',
    Weaponskill = 'Weapon skill', Item = 'Item', Pet = "Pet's move" }
function R.KeyLabel(key, phase)
    if key == 'name' then return NAME_LABEL[phase] or 'Action name' end
    if key == 'family' then return 'Spell (any tier)' end
    if key == 'skill' then return 'Magic skill' end
    local k = R.KEY[key]
    return (k ~= nil) and k.label or tostring(key)
end
R.KEY = {}
for _, k in ipairs(R.KEYS) do R.KEY[k.key] = k end

-- == Matching ==
local function list_of(v)
    if type(v) == 'table' then return v end
    return { v }
end
local function plain_find(s, part) return string.find(s, part, 1, true) ~= nil end
-- A text (or nil) against a text value: 'Exact', { 'A', 'B' }, or { is, isnt, has, start, ends }.
function R.MatchText(actual, spec)
    if type(spec) == 'string' then return actual == spec end
    if type(spec) ~= 'table' then return false end
    if spec[1] ~= nil then
        for _, v in ipairs(spec) do
            if actual == v then return true end
        end
        return false
    end
    local s = (type(actual) == 'string') and actual or nil
    if spec.is ~= nil then
        local hit = false
        for _, v in ipairs(list_of(spec.is)) do hit = hit or (actual == v) end
        if not hit then return false end
    end
    if spec.isnt ~= nil then
        for _, v in ipairs(list_of(spec.isnt)) do
            if actual == v then return false end
        end
    end
    if spec.pattern ~= nil then -- a Lua pattern, as string.find / string.match read it (a bad one never matches)
        if s == nil then return false end
        local hit = false
        for _, v in ipairs(list_of(spec.pattern)) do
            if type(v) == 'string' then
                local ok, at = pcall(string.find, s, v)
                hit = hit or (ok and (at ~= nil))
            end
        end
        if not hit then return false end
    end
    for _, field in ipairs({ 'has', 'start', 'ends' }) do
        if spec[field] ~= nil then
            if s == nil then return false end
            local hit = false
            for _, v in ipairs(list_of(spec[field])) do
                if type(v) == 'string' then
                    if field == 'has' then hit = hit or plain_find(s, v)
                    elseif field == 'start' then hit = hit or (string.sub(s, 1, #v) == v)
                    else hit = hit or ((#v <= #s) and (string.sub(s, -#v) == v)) end
                end
            end
            if not hit then return false end
        end
    end
    return true
end
function R.MatchNumber(actual, spec)
    actual = tonumber(actual)
    if actual == nil then return false end
    if type(spec) == 'number' then return actual == spec end
    if type(spec) ~= 'table' then return false end
    if (spec.lt ~= nil) and not (actual < spec.lt) then return false end
    if (spec.le ~= nil) and not (actual <= spec.le) then return false end
    if (spec.gt ~= nil) and not (actual > spec.gt) then return false end
    if (spec.ge ~= nil) and not (actual >= spec.ge) then return false end
    if (spec.eq ~= nil) and not (actual == spec.eq) then return false end
    if (spec.ne ~= nil) and not (actual ~= spec.ne) then return false end
    return true
end

-- The context of one run: each game read once, when a condition first asks.
local function context(api, phase)
    local c, cache = { phase = phase, api = api }, {}
    local function get(name)
        local v = cache[name]
        if v == nil then
            v = api[name] and api[name]() or false
            cache[name] = v
        end
        return v or nil
    end
    c.get = get
    -- The action the conditions read: the pet's in the Pet phase, else yours.
    function c.action() return (phase == 'Pet') and get('petAction') or get('action') end
    return c
end

local TEST = {}
function TEST.status(c, v) local p = c.get('player'); return R.MatchText(p and p.Status, v) end
function TEST.hpp(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchNumber(p.HPP, v) end
function TEST.mpp(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchNumber(p.MPP, v) end
function TEST.tp(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchNumber(p.TP, v) end
function TEST.moving(c, v) local p = c.get('player'); return (p ~= nil) and ((p.IsMoving == true) == (v == true)) end
function TEST.combat(c, v) return (c.api.inCombat ~= nil) and ((c.api.inCombat() == true) == (v == true)) end
function TEST.sub(c, v) local p = c.get('player'); return R.MatchText(p and p.SubJob, v) end
function TEST.level(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchNumber(p.MainJobSync, v) end
function TEST.name(c, v) local a = c.action(); return R.MatchText(a and a.Name, v) end
function TEST.family(c, v)
    local a = c.action()
    if (a == nil) or (type(a.Name) ~= 'string') then return R.MatchText(nil, v) end
    return R.MatchText((c.api.family ~= nil) and c.api.family(a.Name) or a.Name, v)
end
function TEST.skill(c, v) local a = c.action(); return R.MatchText(a and a.Skill, v) end
function TEST.type(c, v) local a = c.action(); return R.MatchText(a and a.Type, v) end
function TEST.element(c, v)
    local a = c.action()
    if (a == nil) or (a.Element == nil) then return (type(v) == 'table') and (v[1] == nil) and R.MatchText(nil, v) end
    local env = c.get('env')
    for _, want in ipairs(list_of(v)) do
        if (want == 'weather') then
            if (env ~= nil) and (env.WeatherElement == a.Element) then return true end
        elseif (want == 'day') then
            if (env ~= nil) and (env.DayElement == a.Element) then return true end
        elseif R.MatchText(a.Element, want) then
            return true
        end
    end
    return false
end
function TEST.target(c, v) -- 'other': not you, a missing target included (as `target.Name ~= me` reads it)
    local t = c.get('target') or {}
    local me = c.get('me')
    for _, want in ipairs(list_of(v)) do
        if want == 'me' then
            if (me ~= nil) and (t.Name == me) then return true end
        elseif want == 'other' then
            if t.Name ~= me then return true end
        elseif t.Type == want then
            return true
        end
    end
    return false
end
function TEST.targethpp(c, v) local t = c.get('target'); return (t ~= nil) and R.MatchNumber(t.HPP, v) end
function TEST.distance(c, v) local t = c.get('target'); return (t ~= nil) and R.MatchNumber(t.Distance, v) end
function TEST.day(c, v) local e = c.get('env'); return R.MatchText(e and e.DayElement, v) end
function TEST.weather(c, v) local e = c.get('env'); return R.MatchText(e and e.WeatherElement, v) end
function TEST.zone(c, v) local e = c.get('env'); return R.MatchText(e and e.Area, v) end
function TEST.time(c, v) local e = c.get('env'); return (e ~= nil) and R.MatchNumber(e.Time, v) end
local function up(c, b) return (c.api.buff ~= nil) and ((c.api.buff(b) or 0) > 0) end
function TEST.buff(c, v)
    for _, b in ipairs(list_of(v)) do
        if up(c, b) then return true end
    end
    return false
end
function TEST.allbuffs(c, v)
    for _, b in ipairs(list_of(v)) do
        if not up(c, b) then return false end
    end
    return true
end
function TEST.nobuff(c, v)
    for _, b in ipairs(list_of(v)) do
        if up(c, b) then return false end
    end
    return true
end
function TEST.pet(c, v) return (c.get('pet') ~= nil) == (v == true) end
function TEST.pethpp(c, v) local p = c.get('pet'); return (p ~= nil) and R.MatchNumber(p.HPP, v) end
function TEST.pettp(c, v) local p = c.get('pet'); return (p ~= nil) and R.MatchNumber(p.TP, v) end
function TEST.petname(c, v) local p = c.get('pet'); return R.MatchText(p and p.Name, v) end
function TEST.petstatus(c, v) local p = c.get('pet'); return R.MatchText(p and p.Status, v) end
function TEST.mode(c, v)
    if (type(v) ~= 'table') or (c.api.cycle == nil) then return false end
    for name, want in pairs(v) do
        if not R.MatchText(c.api.cycle(R.CYCLES[name] or name), want) then return false end
    end
    return true
end
function TEST.toggle(c, v)
    if (type(v) ~= 'table') or (c.api.toggle == nil) then return false end
    for name, want in pairs(v) do
        if (c.api.toggle(R.TOGGLES[name] or name) == true) ~= (want == true) then return false end
    end
    return true
end
-- The action in one of GoomSwap's spell lists (gcinclude.BluMagPhysical...): a list name, names (any of), or
-- { isnt = name(s) } (none of them).
function TEST.inlist(c, v)
    local a = c.action()
    local name = (a ~= nil) and a.Name or nil
    local function inl(list)
        return (type(name) == 'string') and (c.api.inList ~= nil) and (c.api.inList(list, name) == true)
    end
    if type(v) == 'table' and (v[1] == nil) then
        if v.isnt ~= nil then
            for _, l in ipairs(list_of(v.isnt)) do if inl(l) then return false end end
        end
        if v.is ~= nil then
            local hit = false
            for _, l in ipairs(list_of(v.is)) do hit = hit or inl(l) end
            if not hit then return false end
        end
        return true
    end
    for _, l in ipairs(list_of(v)) do if inl(l) then return true end end
    return false
end
-- A set in the job file by the action's name / its family's (gcinclude.FindSet): what ByName(spell.Name) looks for.
local function has_set(c, name)
    return (type(name) == 'string') and (c.api.hasSet ~= nil) and (c.api.hasSet(name) == true)
end
function TEST.nameset(c, v)
    local a = c.action()
    return has_set(c, a and a.Name) == (v == true)
end
function TEST.familyset(c, v)
    local a = c.action()
    local f = ((a ~= nil) and (type(a.Name) == 'string') and (c.api.family ~= nil)) and c.api.family(a.Name) or nil
    return has_set(c, f) == (v == true)
end
function TEST.wmpick(c, v) return (c.api.weaponPick ~= nil) and ((c.api.weaponPick() == true) == (v == true)) end
function TEST.burst(c, v) return (c.api.burst ~= nil) and ((c.api.burst() == true) == (v == true)) end
function TEST.dualwield(c, v) return (c.api.dualWield ~= nil) and ((c.api.dualWield() == true) == (v == true)) end
R.TEST = TEST

-- == Compiling ==
-- A `when` table as one test; nil and why when a key is unknown.
local function compile_when(when, where)
    if when == nil then return function() return true end end
    if type(when) ~= 'table' then return nil, where .. ': when must be a table' end
    local tests = {}
    for k, v in pairs(when) do
        if k == 'any' then
            local alts = {}
            if type(v) ~= 'table' then return nil, where .. ': any must be a list of condition tables' end
            for i, alt in ipairs(v) do
                local t, err = compile_when(alt, where .. ' any ' .. i)
                if t == nil then return nil, err end
                alts[#alts + 1] = t
            end
            tests[#tests + 1] = function(c)
                for _, t in ipairs(alts) do
                    if t(c) then return true end
                end
                return false
            end
        elseif TEST[k] ~= nil then
            local f = TEST[k]
            tests[#tests + 1] = function(c) return f(c, v) == true end
        else
            return nil, where .. ": unknown condition '" .. tostring(k) .. "'"
        end
    end
    return function(c)
        for _, t in ipairs(tests) do
            if not t(c) then return false end
        end
        return true
    end
end

-- A rule in compact words (tests, and Say's fallback for a key it has no sentence for): 'skill Healing Magic -> X'.
local function value_words(v)
    if type(v) ~= 'table' then return tostring(v) end
    if v[1] ~= nil then
        local out = {}
        for _, x in ipairs(v) do out[#out + 1] = tostring(x) end
        return table.concat(out, ' or ')
    end
    local out = {}
    local OPS = { lt = '<', le = '<=', gt = '>', ge = '>=', eq = '=', ne = '~=' }
    for _, op in ipairs({ 'lt', 'le', 'gt', 'ge', 'eq', 'ne' }) do
        if v[op] ~= nil then out[#out + 1] = OPS[op] .. ' ' .. tostring(v[op]) end
    end
    for _, f in ipairs({ 'is', 'isnt', 'has', 'start', 'ends' }) do
        if v[f] ~= nil then
            local words = { is = 'is', isnt = 'is not', has = 'has', start = 'starts', ends = 'ends' }
            out[#out + 1] = words[f] .. ' "' .. value_words(v[f]) .. '"'
        end
    end
    local keys = {}
    for k in pairs(v) do
        if (type(k) == 'string') and not OPS[k] and not ({ is = 1, isnt = 1, has = 1, start = 1, ends = 1 })[k] then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys)
    for _, k in ipairs(keys) do out[#out + 1] = k .. ' ' .. value_words(v[k]) end
    return table.concat(out, ', ')
end
function R.WhenWords(when)
    if type(when) ~= 'table' then return 'always' end
    local keys = {}
    for k in pairs(when) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local out = {}
    for _, k in ipairs(keys) do
        if k == 'any' then
            local alts = {}
            for _, alt in ipairs(when.any) do alts[#alts + 1] = '(' .. R.WhenWords(alt) .. ')' end
            out[#out + 1] = table.concat(alts, ' or ')
        elseif ((k == 'toggle') or (k == 'mode')) and (type(when[k]) == 'table') then -- /dt on, /nukeset Macc
            local subs = {}
            for sub in pairs(when[k]) do subs[#subs + 1] = tostring(sub) end
            table.sort(subs)
            for _, sub in ipairs(subs) do
                local v = when[k][sub]
                local slash = (R.CYCLES[sub] or R.TOGGLES[sub]) and ('/' .. sub) or sub
                if k == 'toggle' then
                    out[#out + 1] = slash .. ((v == true) and ' on' or ' off')
                else
                    out[#out + 1] = slash .. ' ' .. value_words(v)
                end
            end
        else
            out[#out + 1] = k .. ' ' .. value_words(when[k])
        end
    end
    return (#out > 0) and table.concat(out, ', ') or 'always'
end
function R.WearWords(rule)
    local out = {}
    if type(rule.wear) == 'string' then out[#out + 1] = rule.wear .. (rule.exact and ' (only)' or '') end
    if type(rule.item) == 'table' then
        for _, slot in ipairs(R.SLOTS) do
            local it = rule.item[slot]
            if it ~= nil then out[#out + 1] = slot .. ' ' .. tostring((type(it) == 'table') and it.Name or it) end
        end
    end
    if rule.stop then out[#out + 1] = 'stop the action' end
    return (#out > 0) and table.concat(out, ', ') or 'nothing'
end
function R.Words(rule)
    if type(rule) ~= 'table' then return '?' end
    if type(rule.first) == 'table' then
        local out = {}
        for i, r in ipairs(rule.first) do out[#out + 1] = i .. ') ' .. R.WhenWords(r.when) .. ' -> ' .. R.WearWords(r) end
        return 'first of: ' .. table.concat(out, '; ')
    end
    return R.WhenWords(rule.when) .. ' -> ' .. R.WearWords(rule)
end

-- == A rule as a sentence, for the editor: "When a Cure on you, MP at most 50%: wear Cure_LowMP". ==
-- R.BuffName(id) -> name: the editor sets it (the game's buff names), so 'while 581 is up' reads 'while Flurry II is up'.
R.BuffName = nil
local function buff_names(v)
    local function one(x)
        if (type(x) == 'number') and (R.BuffName ~= nil) then
            local ok, n = pcall(R.BuffName, x)
            if ok and (type(n) == 'string') and (n ~= '') then return n end
        end
        return x
    end
    if type(v) ~= 'table' then return one(v) end
    local out = {}
    for i, x in ipairs(v) do out[i] = one(x) end
    return out
end
local function either_of(v, sep)
    if type(v) ~= 'table' then return tostring(v) end
    local out = {}
    for _, x in ipairs(v) do out[#out + 1] = tostring(x) end
    if #out <= 1 then return out[1] or '' end
    return table.concat(out, ', ', 1, #out - 1) .. ' ' .. (sep or 'or') .. ' ' .. out[#out]
end
-- Texts each in quotes: '"A"', '"A" or "B"', '"A", "B" or "C"'.
local function quoted(v)
    local list = {}
    for _, x in ipairs((type(v) == 'table') and v or { v }) do list[#list + 1] = '"' .. tostring(x) .. '"' end
    return either_of(list)
end
local NUM_SAY = { lt = 'under', le = 'at most', gt = 'over', ge = 'at least', eq = 'exactly', ne = 'not' }
local function num_say(what, v, unit)
    if type(v) ~= 'table' then return what .. ' ' .. tostring(v) .. (unit or '') end
    local out = {}
    for _, op in ipairs({ 'gt', 'ge', 'lt', 'le', 'eq', 'ne' }) do
        if v[op] ~= nil then out[#out + 1] = NUM_SAY[op] .. ' ' .. tostring(v[op]) .. (unit or '') end
    end
    return what .. ' ' .. table.concat(out, ' and ')
end
-- a text value: 'X' / { 'A', 'B' } / { is, isnt, has, start, ends }, each part through fmt(words, negated)
local function text_say(v, fmt)
    if (type(v) == 'string') or ((type(v) == 'table') and (v[1] ~= nil)) then return fmt(either_of(v), false) end
    if type(v) ~= 'table' then return fmt(tostring(v), false) end
    local out = {}
    if v.is ~= nil then out[#out + 1] = fmt(either_of(v.is), false) end
    if v.isnt ~= nil then out[#out + 1] = fmt(either_of(v.isnt), true) end
    if v.has ~= nil then out[#out + 1] = 'its name has ' .. quoted(v.has) end
    if v.start ~= nil then out[#out + 1] = 'its name starts with ' .. quoted(v.start) end
    if v.ends ~= nil then out[#out + 1] = 'its name ends with ' .. quoted(v.ends) end
    if v.pattern ~= nil then out[#out + 1] = 'its name matches the pattern ' .. quoted(v.pattern) end
    return table.concat(out, ', ')
end
-- GoomSwap's spell lists, as a sentence says them.
local LIST_SAY = { BluMagPhysical = 'physical Blue Magic', BluMagDebuff = 'Blue Magic debuffs',
    BluMagStun = 'Blue Magic stuns', BluMagBuff = 'Blue Magic buffs', BluMagSkill = 'skill-based Blue Magic',
    BluMagCure = 'Blue Magic cures', BluMagEnmity = 'Blue Magic for enmity', BluMagTH = 'Blue Magic for Treasure Hunter' }
local function list_say(v)
    local function names(x)
        local out = {}
        for _, l in ipairs(list_of(x)) do out[#out + 1] = LIST_SAY[l] or tostring(l) end
        return either_of(out)
    end
    if (type(v) == 'table') and (v[1] == nil) then
        if v.isnt ~= nil then return "it is not in GoomSwap's " .. names(v.isnt) .. ' list' end
        v = v.is
    end
    return "it is in GoomSwap's " .. names(v) .. ' list'
end
local SAY = {
    status = function(v) return text_say(v, function(w, n) return (n and 'not ' or '') .. string.lower(w) end) end,
    hpp = function(v) return num_say('HP', v, '%') end,
    mpp = function(v) return num_say('MP', v, '%') end,
    tp = function(v) return num_say('TP', v) end,
    moving = function(v) return v and 'moving' or 'standing still' end,
    combat = function(v) return v and 'in combat' or 'out of combat' end,
    sub = function(v) return text_say(v, function(w, n) return (n and 'sub job not ' or 'sub job ') .. w end) end,
    level = function(v) return num_say('level', v) end,
    name = function(v) return text_say(v, function(w, n) return (n and 'not ' or '') .. w end) end,
    family = function(v) return text_say(v, function(w, n) return (n and 'not a ' or 'a ') .. w .. ' spell' end) end,
    skill = function(v) return text_say(v, function(w, n) return (n and 'not ' or '') .. w end) end,
    type = function(v) return text_say(v, function(w, n) return (n and 'not a ' or 'a ') .. w end) end,
    element = function(v)
        local out = {}
        for _, x in ipairs((type(v) == 'table' and v[1] ~= nil) and v or { v }) do
            if x == 'weather' then out[#out + 1] = "its element matches the weather"
            elseif x == 'day' then out[#out + 1] = "its element matches the day"
            elseif type(x) == 'string' then out[#out + 1] = 'a ' .. x .. ' spell'
            else out[#out + 1] = text_say(x, function(w, n) return (n and 'not a ' or 'a ') .. w .. ' spell' end) end
        end
        return table.concat(out, ' or ')
    end,
    target = function(v)
        local WORD = { me = 'on you', other = 'on someone else', PC = 'on a player', NPC = 'on an NPC',
            Party = 'on your party', Alliance = 'on your alliance', Monster = 'on a monster' }
        local out = {}
        for _, x in ipairs((type(v) == 'table') and v or { v }) do out[#out + 1] = WORD[x] or ('on ' .. tostring(x)) end
        return table.concat(out, ' or ')
    end,
    targethpp = function(v) return num_say("target's HP", v, '%') end,
    distance = function(v) return num_say('target', v, ' yalms away') end,
    day = function(v) return text_say(v, function(w, n) return (n and 'not ' or '') .. w .. 'sday' end) end,
    weather = function(v) return text_say(v, function(w, n)
        if w == 'None' then return n and 'not clear weather' or 'clear weather' end
        return (n and 'not in ' or 'in ') .. w .. ' weather' end) end,
    zone = function(v)
        if (type(v) == 'table') and (v[1] == nil) and ((v.has ~= nil) or (v.start ~= nil) or (v.ends ~= nil) or (v.pattern ~= nil)) then
            return 'in a zone with ' .. quoted(v.has or v.start or v.ends or v.pattern) .. ' in its name'
        end
        return text_say(v, function(w, n) return (n and 'not in ' or 'in ') .. w end)
    end,
    inlist = list_say,
    time = function(v) return num_say('time', v) end,
    buff = function(v) return either_of(buff_names(v)) .. ' up' end,
    allbuffs = function(v) return either_of(buff_names(v), 'and') .. ' up' end,
    nobuff = function(v)
        v = buff_names(v)
        if (type(v) == 'table') and (#v > 1) then return 'none of ' .. either_of(v, 'or') .. ' up' end
        return either_of(v) .. ' not up'
    end,
    pet = function(v) return v and 'you have a pet' or 'no pet' end,
    pethpp = function(v) return num_say("pet's HP", v, '%') end,
    pettp = function(v) return num_say("pet's TP", v) end,
    petname = function(v) return text_say(v, function(w, n) return (n and 'pet not ' or 'pet ') .. w end) end,
    petstatus = function(v) return text_say(v, function(w, n) return (n and 'pet not ' or 'pet ') .. string.lower(w) end) end,
    burst = function(v) return v and 'a magic burst' or 'not a magic burst' end,
    nameset = function(v) return v and 'a set named after it' or 'no set named after it' end,
    wmpick = function(v) return v and 'a /wm weapon picked' or 'no /wm weapon picked' end,
    familyset = function(v) return v and 'a set for its family' or 'no set for its family' end,
    dualwield = function(v) return v and 'you can dual wield' or 'you cannot dual wield' end,
}
function R.SayWhen(when)
    if (type(when) ~= 'table') or (next(when) == nil) then return nil end
    local order = {}
    for i, k in ipairs({ 'name', 'family', 'skill', 'type', 'element', 'target', 'targethpp', 'distance', 'burst', 'buff',
        'allbuffs', 'nobuff', 'status', 'hpp', 'mpp', 'tp', 'moving', 'combat', 'mode', 'toggle', 'pet', 'pethpp', 'pettp',
        'petname', 'petstatus', 'day', 'weather', 'zone', 'time', 'sub', 'level', 'dualwield', 'wmpick', 'inlist', 'nameset', 'familyset', 'any' }) do order[k] = i end
    local keys = {}
    for k in pairs(when) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return (order[a] or 999) < (order[b] or 999) end)
    local out = {}
    for _, k in ipairs(keys) do
        local v = when[k]
        if k == 'any' then
            local alts = {}
            for _, alt in ipairs(v) do alts[#alts + 1] = R.SayWhen(alt) or 'always' end
            out[#out + 1] = '(' .. table.concat(alts, ') or (') .. ')'
        elseif ((k == 'toggle') or (k == 'mode')) and (type(v) == 'table') then
            out[#out + 1] = R.WhenWords({ [k] = v })
        elseif SAY[k] ~= nil then
            out[#out + 1] = SAY[k](v)
        else
            out[#out + 1] = R.WhenWords({ [k] = v })
        end
    end
    return table.concat(out, ', ')
end
function R.SayWear(rule)
    local out = {}
    if type(rule.wear) == 'string' then
        out[#out + 1] = 'put on ' .. rule.wear .. ((not rule.exact) and ' (and its /wm, /mset versions)' or '')
    end
    if type(rule.item) == 'table' then
        for _, slot in ipairs(R.SLOTS) do
            local it = rule.item[slot]
            if it ~= nil then out[#out + 1] = 'put ' .. tostring((type(it) == 'table') and it.Name or it) .. ' in ' .. slot end
        end
    end
    if rule.stop then out[#out + 1] = 'cancel it (it is not used)' end
    return (#out > 0) and table.concat(out, ', ') or 'nothing'
end

-- What the action is, for the sentence: 'Absorb-TP', 'Cure, Cura or Curaga (any tier, Healing Magic)',
-- 'an Elemental Magic spell'; nil when the rule doesn't say.
local SPELLS = { Precast = true, Midcast = true }
local NOUN = { Precast = 'a spell', Midcast = 'a spell', Ability = 'a job ability', Weaponskill = 'a weapon skill',
    Item = 'an item', Pet = 'a move' }
local function article(w) return (string.match(w, '^[AEIOUaeiou]') and 'an ' or 'a ') .. w end
local function what_of(when, phase)
    local noun = NOUN[phase] or 'an action'
    local bare = string.match(noun, '^an? (.+)$') or noun
    local main, extra = nil, {}
    local name, family = when.name, when.family
    if name ~= nil then
        if (type(name) == 'string') or ((type(name) == 'table') and (name[1] ~= nil)) then
            main = either_of(name)
        elseif type(name) == 'table' then
            local parts = {}
            if name.is ~= nil then parts[#parts + 1] = either_of(name.is) end
            if name.has ~= nil then parts[#parts + 1] = article(bare) .. ' with ' .. quoted(name.has) .. ' in its name' end
            if name.start ~= nil then parts[#parts + 1] = article(bare) .. ' starting ' .. quoted(name.start) end
            if name.ends ~= nil then parts[#parts + 1] = article(bare) .. ' ending ' .. quoted(name.ends) end
            if name.pattern ~= nil then
                parts[#parts + 1] = article(bare) .. ' matching the pattern ' .. quoted(name.pattern)
            end
            if name.isnt ~= nil then
                if #parts == 0 then parts[#parts + 1] = article(bare) end
                parts[#parts] = parts[#parts] .. ' other than ' .. either_of(name.isnt)
            end
            main = table.concat(parts, ', ')
        end
    end
    if family ~= nil then
        local f = text_say(family, function(w, n) return n and ('not ' .. w) or w end)
        if main == nil then main = f; extra[#extra + 1] = 'any tier' else extra[#extra + 1] = 'family ' .. f end
    end
    local skill = when.skill
    if skill ~= nil then
        local sk = text_say(skill, function(w, n) return (n and 'not ' or '') .. w end)
        if main == nil then
            main = ((type(skill) == 'string') and article(sk .. ' ' .. bare)) or (sk .. ' ' .. bare)
        else
            extra[#extra + 1] = sk
        end
    end
    if when.type ~= nil then
        local ty = text_say(when.type, function(w, n) return (n and 'not ' or '') .. w end)
        if main == nil then main = (type(when.type) == 'string') and article(ty) or ty else extra[#extra + 1] = ty end
    end
    if when.element ~= nil then
        local el = {}
        for _, x in ipairs((type(when.element) == 'table' and when.element[1] ~= nil) and when.element or { when.element }) do
            if x == 'weather' then el[#el + 1] = 'element matching the weather'
            elseif x == 'day' then el[#el + 1] = 'element matching the day'
            elseif type(x) == 'string' then el[#el + 1] = x
            else el[#el + 1] = text_say(x, function(w, n) return (n and 'not ' or '') .. w end) end
        end
        local e = table.concat(el, ' or ')
        if (main == nil) and (#el == 1) and not string.find(e, 'matching', 1, true) then main = article(e .. ' ' .. bare)
        else extra[#extra + 1] = e end
    end
    if main == nil and #extra == 0 then return nil end
    main = main or noun
    if #extra > 0 then main = main .. ' (' .. table.concat(extra, ', ') .. ')' end
    return main
end
local TARGET_SAY = { me = 'on yourself', other = 'on someone else', PC = 'on a player', NPC = 'on an NPC',
    Party = 'on your party', Alliance = 'on your alliance', Monster = 'on a monster' }
-- What has to be true besides what the action is: 'MP is at most 50% and in Light weather'.
local STATE = {
    hpp = function(v) return num_say('your HP is', v, '%') end,
    mpp = function(v) return num_say('your MP is', v, '%') end,
    tp = function(v) return num_say('your TP is', v) end,
    targethpp = function(v) return num_say("the target's HP is", v, '%') end,
    distance = function(v) return num_say('the target is', v, ' yalms away') end,
    buff = function(v) return either_of(buff_names(v)) .. ' is up' end,
    allbuffs = function(v) return either_of(buff_names(v), 'and') .. ' are all up' end,
    nobuff = function(v)
        v = buff_names(v)
        if (type(v) == 'table') and (#v > 1) then return 'none of ' .. either_of(v, 'or') .. ' is up' end
        return either_of(v) .. ' is not up'
    end,
    burst = function(v) return v and 'it is a magic burst' or 'it is not a magic burst' end,
    nameset = function(v) return v and 'it has a set named after it' or 'it has no set named after it' end,
    wmpick = function(v) return v and 'a /wm weapon is picked' or 'no /wm weapon is picked' end,
    familyset = function(v) return v and 'it has a set for its family' or 'it has no set for its family' end,
    moving = function(v) return v and 'you are moving' or 'you are standing still' end,
    combat = function(v) return v and 'you are in combat' or 'you are out of combat' end,
}
local ACTION_KEYS = { name = true, family = true, skill = true, type = true, element = true, target = true }
local function state_of(when, skipStatus)
    local order = {}
    for i, k in ipairs({ 'targethpp', 'distance', 'burst', 'buff', 'allbuffs', 'nobuff', 'status', 'hpp', 'mpp', 'tp',
        'moving', 'combat', 'mode', 'toggle', 'pet', 'pethpp', 'pettp', 'petname', 'petstatus', 'day', 'weather', 'zone',
        'time', 'sub', 'level', 'dualwield', 'wmpick', 'inlist', 'nameset', 'familyset', 'any' }) do order[k] = i end
    local keys = {}
    for k in pairs(when) do
        if not ACTION_KEYS[k] and not ((k == 'status') and skipStatus) then keys[#keys + 1] = k end
    end
    table.sort(keys, function(a, b) return (order[a] or 999) < (order[b] or 999) end)
    local out = {}
    if (when.nameset == false) and (when.familyset == false) then -- the usual fallback, in one phrase
        out[#out + 1] = 'it has no set of its own (by name or family)'
        local k2 = {}
        for _, k in ipairs(keys) do if (k ~= 'nameset') and (k ~= 'familyset') then k2[#k2 + 1] = k end end
        keys = k2
    end
    for _, k in ipairs(keys) do
        local v = when[k]
        if k == 'any' then
            local alts = {}
            for _, alt in ipairs(v) do alts[#alts + 1] = state_of(alt) or R.SayWhen(alt) or 'always' end
            out[#out + 1] = 'either ' .. table.concat(alts, ', or ')
        elseif (k == 'toggle') and (type(v) == 'table') then
            local subs = {}
            for sub in pairs(v) do subs[#subs + 1] = tostring(sub) end
            table.sort(subs)
            for _, sub in ipairs(subs) do out[#out + 1] = '/' .. sub .. ' is ' .. ((v[sub] == true) and 'on' or 'off') end
        elseif (k == 'mode') and (type(v) == 'table') then
            local subs = {}
            for sub in pairs(v) do subs[#subs + 1] = tostring(sub) end
            table.sort(subs)
            for _, sub in ipairs(subs) do
                out[#out + 1] = text_say(v[sub], function(w, n) return '/' .. sub .. (n and ' is not ' or ' is ') .. w end)
            end
        elseif STATE[k] ~= nil then
            out[#out + 1] = STATE[k](v)
        elseif SAY[k] ~= nil then
            out[#out + 1] = SAY[k](v)
        else
            out[#out + 1] = R.WhenWords({ [k] = v })
        end
    end
    if #out == 0 then return nil end
    if #out == 1 then return out[1] end
    return table.concat(out, ', ', 1, #out - 1) .. ' and ' .. out[#out]
end
-- The moment and what it is about: 'When you cast Absorb-TP on yourself', 'While fighting'.
local function moment(when, phase, whatOverride)
    if phase == 'Default' then
        local st = when.status
        if st == 'Engaged' then return 'While fighting', true end
        if st == 'Idle' then return 'While idle', true end
        if st == 'Resting' then return 'While resting', true end
        return 'While not acting (idle, fighting, resting)', false
    end
    local what = whatOverride or what_of(when, phase)
    local head
    if phase == 'Precast' then head = 'When you start casting ' .. (what or 'a spell')
    elseif phase == 'Midcast' then head = 'When you cast ' .. (what or 'a spell')
    elseif (phase == 'Ability') or (phase == 'Weaponskill') or (phase == 'Item') then head = 'When you use ' .. (what or NOUN[phase])
    elseif phase == 'Preshot' then head = 'When you start a ranged attack' .. (what and (' (' .. what .. ')') or '')
    elseif phase == 'Midshot' then head = 'When your ranged attack fires' .. (what and (' (' .. what .. ')') or '')
    elseif phase == 'Pet' then head = 'When your pet uses ' .. (what or 'a move')
    else head = 'When ' .. (what or 'it happens') end
    if when.target ~= nil then
        local t = {}
        for _, x in ipairs((type(when.target) == 'table') and when.target or { when.target }) do t[#t + 1] = TARGET_SAY[x] or ('on ' .. tostring(x)) end
        head = head .. ' ' .. table.concat(t, ' or ')
    end
    return head, false
end
-- A rule as a sentence: 'When you cast Absorb-TP: put on Absorb_TP'. phase: for a `first` group's choice (no `on`).
function R.Say(rule, phase)
    if type(rule) ~= 'table' then return '?' end
    local member = (rule.on == nil) and (phase ~= nil) -- a group's choice
    phase = rule.on or phase
    local when = (type(rule.when) == 'table') and rule.when or {}
    if member and (next(when) == nil) then return 'Otherwise: ' .. R.SayWear(rule) end
    -- 'either its name has "Roll", or Double-Up': when every choice is about the action itself, say it as the action
    local whatOverride = nil
    if (type(when.any) == 'table') and (phase ~= 'Default') and (when.name == nil) and (when.family == nil)
        and (when.skill == nil) and (when.type == nil) and (when.element == nil) then
        local whats, plain = {}, true
        for _, alt in ipairs(when.any) do
            for k in pairs(alt) do if (k == 'target') or not ACTION_KEYS[k] then plain = false end end
            local w = plain and what_of(alt, phase) or nil
            if w == nil then plain = false else whats[#whats + 1] = w end
        end
        if plain and (#whats > 1) then
            whatOverride = table.concat(whats, ', ', 1, #whats - 1) .. ' or ' .. whats[#whats]
            local w2 = {}
            for k, v in pairs(when) do if k ~= 'any' then w2[k] = v end end
            when = w2
        end
    end
    if member then -- a group's choice: only what it adds ('If Flurry II is up', 'For Dark Shot or Light Shot')
        local what = whatOverride or what_of(when, phase)
        local st = state_of(when, false)
        local tgt = nil
        if when.target ~= nil then
            local t = {}
            for _, x in ipairs((type(when.target) == 'table') and when.target or { when.target }) do t[#t + 1] = TARGET_SAY[x] or ('on ' .. tostring(x)) end
            tgt = table.concat(t, ' or ')
        end
        local head
        if what ~= nil then
            head = 'For ' .. what .. ((tgt ~= nil) and (' ' .. tgt) or '') .. ((st ~= nil) and (', while ' .. st) or '')
        elseif tgt ~= nil then
            head = 'If cast ' .. tgt .. ((st ~= nil) and (', while ' .. st) or '')
        else
            head = 'If ' .. (st or 'it fits')
        end
        return head .. ': ' .. R.SayWear(rule)
    end
    local head, statusSaid = moment(when, phase, whatOverride)
    local st = state_of(when, statusSaid)
    if st ~= nil then head = head .. ((phase == 'Default') and ', when ' or ', while ') .. st end
    if type(rule.first) == 'table' then -- a group: the first of its choices that fits
        local parts = {}
        for i, m in ipairs(rule.first) do parts[#parts + 1] = i .. ') ' .. R.Say(m, phase) end
        return head .. ', the first that fits: ' .. table.concat(parts, '  ')
    end
    return head .. ': ' .. R.SayWear(rule)
end

-- One rule (or a `first` group's member): its test and what it does; nil and why when it can't be used.
local function compile_one(rule, where, phase)
    local test, err = compile_when(rule.when, where)
    if test == nil then return nil, err end
    if (rule.wear ~= nil) and (type(rule.wear) ~= 'string') then return nil, where .. ': wear must be a set name' end
    if (rule.item ~= nil) then
        if type(rule.item) ~= 'table' then return nil, where .. ': item must be { Slot = item }' end
        for slot in pairs(rule.item) do
            if not SLOTS[slot] then return nil, where .. ": no slot named '" .. tostring(slot) .. "'" end
        end
    end
    if rule.stop and not R.STOPPABLE[phase] then
        return nil, where .. ': stop works only on Precast, Ability, Weaponskill, Item and Preshot'
    end
    if (rule.wear == nil) and (rule.item == nil) and not rule.stop and (rule.first == nil) then
        return nil, where .. ': wears nothing (wear, item or stop)'
    end
    return { test = test, wear = rule.wear, exact = (rule.exact == true), item = rule.item, stop = (rule.stop == true),
        words = R.Say(rule, phase), note = rule.note } -- in chat and Equip order: the editor's own sentence
end

-- rules: gcinclude.Rules. The compiled form: [phase] = { job = { ... }, top = { ... } }, each entry a rule or a
-- group ({ group = { rules }, test }), in file order; and the problems (one line each: the rule is left out).
function R.Compile(rules)
    local out, problems = { at = {} }, {}
    for _, p in ipairs(R.PHASES) do out[p] = { job = {}, top = {} } end
    if rules == nil then return out, problems end
    if type(rules) ~= 'table' then return out, { 'gcinclude.Rules must be a list of rules' } end
    for i, rule in ipairs(rules) do
        local where = 'rule ' .. i
        if type(rule) ~= 'table' then
            problems[#problems + 1] = where .. ': not a table'
        elseif rule.off then
            -- kept in the file, not used
        elseif out[rule.on or ''] == nil then
            problems[#problems + 1] = where .. ": on must be one of " .. table.concat(R.PHASES, ', ')
        elseif (rule.layer ~= nil) and (rule.layer ~= 'job') and (rule.layer ~= 'top') then
            problems[#problems + 1] = where .. ": layer must be 'job' or 'top'"
        elseif (rule.at ~= nil) and (type(rule.at) ~= 'string') then
            problems[#problems + 1] = where .. ': at must be a spot name'
        else
            local entry, err
            if type(rule.first) == 'table' then
                local test, werr = compile_when(rule.when, where)
                if test == nil then
                    err = werr
                else
                    entry = { group = {}, test = test, index = i, words = R.Say(rule), note = rule.note }
                    for j, member in ipairs(rule.first) do
                        local m, merr = nil, where .. ' choice ' .. j .. ': not a table'
                        if type(member) == 'table' then m, merr = compile_one(member, where .. ' choice ' .. j, rule.on) end
                        if m == nil then
                            err = merr
                            break
                        end
                        entry.group[#entry.group + 1] = m
                    end
                end
            else
                entry, err = compile_one(rule, where, rule.on)
                if entry ~= nil then entry.index = i end
            end
            if entry == nil then
                problems[#problems + 1] = err
            elseif rule.at ~= nil then -- run by the job file's gcinclude.RulesAt(at), in its place
                entry.phase = rule.on
                out.at[rule.at] = out.at[rule.at] or {}
                local list = out.at[rule.at]
                list[#list + 1] = entry
            else
                local list = out[rule.on][(rule.layer == 'top') and 'top' or 'job']
                list[#list + 1] = entry
            end
        end
    end
    return out, problems
end

-- Whether a rule's conditions hold now (the editor's "Now" line); nil when they can't be read.
function R.Holds(rule, phase, api)
    local test = compile_when((type(rule) == 'table') and rule.when or nil, 'rule')
    if test == nil then return nil end
    local ok, hit = pcall(test, context(api, phase))
    return ok and hit or nil
end

function R.Count(compiled, phase)
    local p = compiled and compiled[phase]
    return (p ~= nil) and (#p.job + #p.top) or 0
end

-- == Running ==
-- Runs one phase's layer: each rule whose conditions hold wears its set and items, in order (a later one wins its
-- slots). true when one stopped the action (the rest are skipped), and how many went on.
local function apply(entry, c, api)
    if entry.wear ~= nil then api.wear(entry.wear, entry.exact, entry) end
    if entry.item ~= nil then
        for _, slot in ipairs(R.SLOTS) do
            local it = entry.item[slot]
            if it ~= nil then api.equip(slot, it, entry) end
        end
    end
    if entry.stop then
        if api.cancel ~= nil then api.cancel(entry) end
        return true
    end
    return false
end
local function run_list(list, phase, api)
    local c, n = context(api, phase), 0
    for _, entry in ipairs(list) do
        if entry.test(c) then
            if entry.group ~= nil then
                for _, m in ipairs(entry.group) do
                    if m.test(c) then
                        n = n + 1
                        if apply(m, c, api) then return true, n end
                        break
                    end
                end
            else
                n = n + 1
                if apply(entry, c, api) then return true, n end
            end
        end
    end
    return false, n
end
function R.Run(compiled, phase, layer, api)
    local list = compiled and compiled[phase] and compiled[phase][layer]
    if (list == nil) or (#list == 0) then return false, 0 end
    return run_list(list, phase, api)
end
-- The rules at a spot in the job file's code (gcinclude.RulesAt), each read in its own phase.
function R.RunAt(compiled, at, api)
    local list = compiled and compiled.at and compiled.at[at]
    if (list == nil) or (#list == 0) then return false, 0 end
    return run_list(list, list[1].phase, api)
end

-- == The builder's rows (gceditrules): a `when` as { key, op, value, sub } rows and back. A text key's ops are is,
-- isnt, has, start, ends; a number's lt, le, gt, ge, eq, ne; yes/no and list keys take 'is'; mode and toggle rows
-- name their cycle in sub. any: the rows are alternatives (when = { any = { {...}, {...} } }). ==
local TEXT_OPS = { 'is', 'isnt', 'has', 'start', 'ends', 'pattern' }
local NUM_OPS = { 'lt', 'le', 'gt', 'ge', 'eq', 'ne' }
R.TEXT_OPS, R.NUM_OPS = TEXT_OPS, NUM_OPS
local function key_rows(k, v, out)
    local meta = R.KEY[k]
    if meta == nil then return false end
    if (meta.kind == 'mode') or (meta.kind == 'toggle') then
        if type(v) ~= 'table' then return false end
        local subs = {}
        for sub in pairs(v) do subs[#subs + 1] = sub end
        table.sort(subs)
        for _, sub in ipairs(subs) do out[#out + 1] = { key = k, op = 'is', sub = sub, value = v[sub] } end
    elseif meta.kind == 'number' then
        if type(v) == 'number' then
            out[#out + 1] = { key = k, op = 'eq', value = v }
        elseif type(v) == 'table' then
            for _, op in ipairs(NUM_OPS) do
                if v[op] ~= nil then out[#out + 1] = { key = k, op = op, value = v[op] } end
            end
        else
            return false
        end
    elseif (meta.kind == 'bool') or (meta.kind == 'list') then
        out[#out + 1] = { key = k, op = 'is', value = v }
    else
        if (type(v) == 'string') or ((type(v) == 'table') and (v[1] ~= nil)) then
            out[#out + 1] = { key = k, op = 'is', value = v }
        elseif type(v) == 'table' then
            for _, op in ipairs(TEXT_OPS) do
                if v[op] ~= nil then out[#out + 1] = { key = k, op = op, value = v[op] } end
            end
        else
            return false
        end
    end
    return true
end
-- rows, any; nil when the `when` has a shape the builder can't show (it is then edited in the file).
function R.WhenToRows(when)
    local rows = {}
    if when == nil then return rows, false end
    if type(when) ~= 'table' then return nil end
    if when.any ~= nil then
        if next(when, nil) ~= nil then
            for k in pairs(when) do
                if k ~= 'any' then return nil end -- all of these and any of those: the file's own shape
            end
        end
        for _, alt in ipairs(when.any) do
            if type(alt) ~= 'table' then return nil end
            local n = 0
            for k, v in pairs(alt) do
                n = n + 1
                if (k == 'any') or not key_rows(k, v, rows) then return nil end
            end
            if n ~= 1 then return nil end
        end
        return rows, true
    end
    local keys = {}
    for k in pairs(when) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
        if not key_rows(k, when[k], rows) then return nil end
    end
    return rows, false
end
local function merge_row(when, r)
    local meta = R.KEY[r.key]
    if meta == nil then return end
    if (meta.kind == 'mode') or (meta.kind == 'toggle') then
        when[r.key] = when[r.key] or {}
        if r.sub ~= nil then when[r.key][r.sub] = r.value end
    elseif meta.kind == 'number' then
        when[r.key] = (type(when[r.key]) == 'table') and when[r.key] or {}
        when[r.key][r.op] = r.value
    elseif (meta.kind == 'bool') or (meta.kind == 'list') then
        when[r.key] = r.value
    elseif r.op == 'is' then
        local cur = when[r.key]
        if (cur == nil) then
            when[r.key] = r.value
        elseif (type(cur) == 'table') and (cur[1] == nil) then -- ops already: is joins them
            cur.is = r.value
        else -- two 'is' rows: either of them
            local both = {}
            for _, x in ipairs(list_of(cur)) do both[#both + 1] = x end
            for _, x in ipairs(list_of(r.value)) do both[#both + 1] = x end
            when[r.key] = both
        end
    else
        local cur = when[r.key]
        if (type(cur) == 'string') or ((type(cur) == 'table') and (cur[1] ~= nil)) then cur = { is = cur } end
        cur = cur or {}
        cur[r.op] = r.value
        when[r.key] = cur
    end
end
function R.RowsToWhen(rows, any)
    if (rows == nil) or (#rows == 0) then return nil end
    if any then
        local alts = {}
        for _, r in ipairs(rows) do
            local w = {}
            merge_row(w, r)
            if next(w) ~= nil then alts[#alts + 1] = w end
        end
        return { any = alts }
    end
    local w = {}
    for _, r in ipairs(rows) do merge_row(w, r) end
    return (next(w) ~= nil) and w or nil
end

-- == Rules as Lua text: one rule a line (a `first` group: one choice a line), keys in reading order. ==
local RULE_ORDER = { 'on', 'at', 'when', 'first', 'wear', 'exact', 'item', 'layer', 'stop', 'off', 'note' }
local function inline(v, quote, key)
    if type(v) == 'string' then return quote(v) end
    if type(v) ~= 'table' then return tostring(v) end
    local parts = {}
    for _, x in ipairs(v) do parts[#parts + 1] = inline(x, quote, key) end
    local keys = {}
    for k in pairs(v) do
        if type(k) == 'string' then keys[#keys + 1] = k end
    end
    local order = {}
    for i, k in ipairs(RULE_ORDER) do order[k] = i end
    local slotAt = {}
    for i, sl in ipairs(R.SLOTS) do slotAt[sl] = i end
    table.sort(keys, function(a, b)
        local x, y = order[a] or slotAt[a] or 99, order[b] or slotAt[b] or 99
        if x ~= y then return x < y end
        return a < b
    end)
    for _, k in ipairs(keys) do parts[#parts + 1] = key(k) .. ' = ' .. inline(v[k], quote, key) end
    if #parts == 0 then return '{}' end
    return '{ ' .. table.concat(parts, ', ') .. ' }'
end
R.Inline = inline
function R.Serialize(rules, ind, quote, key)
    ind = ind or ''
    if (type(rules) ~= 'table') or (#rules == 0) then return '{}' end
    local lines = { '{' }
    for _, rule in ipairs(rules) do
        if (type(rule) == 'table') and (type(rule.first) == 'table') then
            local head = {}
            for k, v in pairs(rule) do
                if k ~= 'first' then head[k] = v end
            end
            local text = inline(head, quote, key)
            text = string.sub(text, 1, #text - 2) .. ', first = {'
            lines[#lines + 1] = ind .. '    ' .. text
            for _, m in ipairs(rule.first) do lines[#lines + 1] = ind .. '        ' .. inline(m, quote, key) .. ',' end
            lines[#lines + 1] = ind .. '    } },'
        else
            lines[#lines + 1] = ind .. '    ' .. inline(rule, quote, key) .. ','
        end
    end
    lines[#lines + 1] = ind .. '}'
    return table.concat(lines, '\n')
end

return R
