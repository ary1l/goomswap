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
-- Dispelga's Daybreak). stop: cancel the action (Precast, Ability, Weaponskill, Item, Preshot only: LAC's
-- CancelAction). off: kept, not used. note: your words, shown in /gcedit.
--
-- Values: a text key takes 'Exact', { 'A', 'B' } (any of them), or { is = .., isnt = .., has = .., start = ..,
-- ends = .. } (each a text or a list; has/start/ends match case as written, like string.find). A number key takes
-- { lt = , le = , gt = , ge = , eq = , ne = } (all must hold). A yes/no key takes true or false.
-- Pure: game data comes in through an api table (gcinclude.RulesApi), so tests run without the game.
local R = {}

R.PHASES = { 'Default', 'Pet', 'Precast', 'Midcast', 'Ability', 'Weaponskill', 'Preshot', 'Midshot', 'Item' }
R.PHASE_LABEL = { Default = 'Idle / engaged', Pet = 'Pet action', Precast = 'Precast', Midcast = 'Midcast',
    Ability = 'Job ability', Weaponskill = 'Weapon skill', Preshot = 'Preshot', Midshot = 'Midshot', Item = 'Item' }
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
    { key = 'status', label = 'Your status', kind = 'text', values = { 'Idle', 'Engaged', 'Resting' } },
    { key = 'hpp', label = 'Your HP %', kind = 'number' },
    { key = 'mpp', label = 'Your MP %', kind = 'number' },
    { key = 'tp', label = 'Your TP', kind = 'number' },
    { key = 'moving', label = 'Moving', kind = 'bool' },
    { key = 'combat', label = 'In combat', kind = 'bool' },
    { key = 'sub', label = 'Sub job', kind = 'text', values = JOBS },
    { key = 'level', label = 'Your level (synced)', kind = 'number' },
    { key = 'name', label = 'Action name', kind = 'text', phases = { Pet = true, Precast = true, Midcast = true,
        Ability = true, Weaponskill = true, Preshot = true, Midshot = true, Item = true } },
    { key = 'family', label = 'Spell family (Cure IV: Cure)', kind = 'text', phases = SPELL },
    { key = 'skill', label = 'Spell skill', kind = 'text', phases = SPELL, values = { 'Divine Magic', 'Healing Magic',
        'Enhancing Magic', 'Enfeebling Magic', 'Elemental Magic', 'Dark Magic', 'Summoning', 'Ninjutsu', 'Singing',
        'Blue Magic', 'Geomancy' } },
    { key = 'element', label = 'Spell element', kind = 'text', phases = { Precast = true, Midcast = true, Pet = true },
        values = { 'Fire', 'Ice', 'Wind', 'Earth', 'Thunder', 'Water', 'Light', 'Dark', 'weather', 'day' } },
    { key = 'type', label = 'Action type', kind = 'text', phases = ACTION, values = { 'White Magic', 'Black Magic',
        'Summoning', 'Ninjutsu', 'Bard Song', 'Blue Magic', 'Rune Enchantment', 'Ready', 'Blood Pact: Rage',
        'Blood Pact: Ward', 'Corsair Roll', 'Quick Draw' } },
    { key = 'target', label = 'Target', kind = 'text', phases = ACTION,
        values = { 'me', 'other', 'PC', 'NPC', 'Party', 'Alliance', 'Monster' } },
    { key = 'targethpp', label = "Target's HP %", kind = 'number', phases = ACTION },
    { key = 'distance', label = 'Target distance (yalms)', kind = 'number', phases = ACTION },
    { key = 'day', label = 'Day element', kind = 'text', values = ELEMENTS },
    { key = 'weather', label = 'Weather element', kind = 'text', values = { 'None', 'Fire', 'Ice', 'Wind', 'Earth',
        'Thunder', 'Water', 'Light', 'Dark' } },
    { key = 'zone', label = 'Zone', kind = 'text' },
    { key = 'time', label = "Vana'diel time (12.30 = 12:30)", kind = 'number' },
    { key = 'buff', label = 'Buff up (any of)', kind = 'list' },
    { key = 'allbuffs', label = 'Buffs up (all of)', kind = 'list' },
    { key = 'nobuff', label = 'Buff not up (none of)', kind = 'list' },
    { key = 'pet', label = 'You have a pet', kind = 'bool' },
    { key = 'pethpp', label = "Pet's HP %", kind = 'number' },
    { key = 'pettp', label = "Pet's TP", kind = 'number' },
    { key = 'petname', label = "Pet's name", kind = 'text' },
    { key = 'mode', label = 'Mode (/wm, /mset...)', kind = 'mode' },
    { key = 'toggle', label = 'Toggle (/dt, /kite...)', kind = 'toggle' },
    { key = 'burst', label = 'Magic burst (a live skillchain)', kind = 'bool', phases = SPELL },
    { key = 'dualwield', label = 'Can dual wield', kind = 'bool' },
}
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
function TEST.status(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchText(p.Status, v) end
function TEST.hpp(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchNumber(p.HPP, v) end
function TEST.mpp(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchNumber(p.MPP, v) end
function TEST.tp(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchNumber(p.TP, v) end
function TEST.moving(c, v) local p = c.get('player'); return (p ~= nil) and ((p.IsMoving == true) == (v == true)) end
function TEST.combat(c, v) return (c.api.inCombat ~= nil) and ((c.api.inCombat() == true) == (v == true)) end
function TEST.sub(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchText(p.SubJob, v) end
function TEST.level(c, v) local p = c.get('player'); return (p ~= nil) and R.MatchNumber(p.MainJobSync, v) end
function TEST.name(c, v) local a = c.action(); return (a ~= nil) and R.MatchText(a.Name, v) end
function TEST.family(c, v)
    local a = c.action()
    if (a == nil) or (type(a.Name) ~= 'string') then return false end
    return R.MatchText((c.api.family ~= nil) and c.api.family(a.Name) or a.Name, v)
end
function TEST.skill(c, v) local a = c.action(); return (a ~= nil) and R.MatchText(a.Skill, v) end
function TEST.type(c, v) local a = c.action(); return (a ~= nil) and R.MatchText(a.Type, v) end
function TEST.element(c, v)
    local a = c.action()
    if (a == nil) or (a.Element == nil) then return false end
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
function TEST.target(c, v)
    local t = c.get('target')
    if t == nil then return false end
    local me = c.get('me')
    for _, want in ipairs(list_of(v)) do
        if want == 'me' then
            if (me ~= nil) and (t.Name == me) then return true end
        elseif want == 'other' then
            if (t.Name ~= nil) and (t.Name ~= me) then return true end
        elseif t.Type == want then
            return true
        end
    end
    return false
end
function TEST.targethpp(c, v) local t = c.get('target'); return (t ~= nil) and R.MatchNumber(t.HPP, v) end
function TEST.distance(c, v) local t = c.get('target'); return (t ~= nil) and R.MatchNumber(t.Distance, v) end
function TEST.day(c, v) local e = c.get('env'); return (e ~= nil) and R.MatchText(e.DayElement, v) end
function TEST.weather(c, v) local e = c.get('env'); return (e ~= nil) and R.MatchText(e.WeatherElement, v) end
function TEST.zone(c, v) local e = c.get('env'); return (e ~= nil) and R.MatchText(e.Area, v) end
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
function TEST.petname(c, v) local p = c.get('pet'); return (p ~= nil) and R.MatchText(p.Name, v) end
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

-- A rule in plain words, for the editor and chat: 'Midcast: skill Healing Magic, target me -> Self_Cure'.
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
        words = R.Words(rule), note = rule.note }
end

-- rules: gcinclude.Rules. The compiled form: [phase] = { job = { ... }, top = { ... } }, each entry a rule or a
-- group ({ group = { rules }, test }), in file order; and the problems (one line each: the rule is left out).
function R.Compile(rules)
    local out, problems = {}, {}
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
        else
            local entry, err
            if type(rule.first) == 'table' then
                local test, werr = compile_when(rule.when, where)
                if test == nil then
                    err = werr
                else
                    entry = { group = {}, test = test, index = i, words = R.Words(rule), note = rule.note }
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
            else
                local list = out[rule.on][(rule.layer == 'top') and 'top' or 'job']
                list[#list + 1] = entry
            end
        end
    end
    return out, problems
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
function R.Run(compiled, phase, layer, api)
    local list = compiled and compiled[phase] and compiled[phase][layer]
    if (list == nil) or (#list == 0) then return false, 0 end
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

return R
