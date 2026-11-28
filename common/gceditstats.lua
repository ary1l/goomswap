-- /gcedit: additive listed equipment bonuses; conditional and unknown effects stay separate.
local stats = {}
local aliases, definitions = {}, {}
local groups = { Core = 1, Attributes = 2, Physical = 3, Magic = 4, Defense = 5, Utility = 6, Skills = 7, Weapons = 8,
    Pet = 9, Abilities = 10 }
local function normalize(value) return (value:lower():gsub('[%s%p]', '')) end -- one value, not gsub's count too
local function define(name, group, unit, direction, names, weapon)
    local entry = { name = name, group = group, unit = unit or '', direction = direction or 1,
        order = #definitions + 1, weapon = weapon }
    definitions[#definitions + 1] = entry
    aliases[normalize(name)] = entry
    for _, alias in ipairs(names or {}) do aliases[normalize(alias)] = entry end
end
for _, name in ipairs({ 'HP', 'MP' }) do define(name, 'Core') end
define('Defense', 'Core', '', 1, { 'DEF' })
for _, name in ipairs({ 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND', 'CHR' }) do define(name, 'Attributes') end
define('Accuracy', 'Physical', '', 1, { 'Acc.' })
define('Attack', 'Physical', '', 1, { 'Atk.' })
define('Ranged accuracy', 'Physical', '', 1, { 'Ranged Acc.', 'Rng. Acc.', 'R. Acc.' })
define('Ranged attack', 'Physical', '', 1, { 'Ranged Atk.', 'Rng. Atk.', 'R. Atk.' })
define('Evasion', 'Defense', '', 1, { 'Eva.' })
define('Magic accuracy', 'Magic', '', 1, { 'Magic Acc.', 'Mag. Acc.', 'M.Acc.' })
define('Magic attack bonus', 'Magic', '', 1, { 'Magic Atk. Bonus', 'Mag. Atk. Bns.', 'MAB' })
define('Magic defense bonus', 'Defense', '', 1, { 'Magic Def. Bonus', 'Mag. Def. Bns.', 'MDB' })
define('Magic evasion', 'Defense', '', 1, { 'M.Eva.', 'Magic Eva.', 'Mag. Eva.', 'Mag. Evasion', 'MEVA' })
define('Magic damage', 'Magic', '', 1, { 'Magic Dmg.', 'Mag. Dmg.' })
for _, name in ipairs({ 'Haste', 'Fast Cast', 'Snapshot', 'Rapid Shot', 'Double Attack', 'Triple Attack',
    'Quadruple Attack', 'Dual Wield', 'Critical hit rate', 'Critical hit damage', 'Weapon skill damage',
    'Skillchain bonus', 'Skillchain damage' }) do define(name, 'Physical', '%') end
define('Weapon skill accuracy', 'Physical')
aliases[normalize('Crit. hit rate')] = aliases[normalize('Critical hit rate')]
aliases[normalize('Crit. hit damage')] = aliases[normalize('Critical hit damage')]
aliases[normalize('WS damage')] = aliases[normalize('Weapon skill damage')]
aliases[normalize('Dbl. Atk.')] = aliases[normalize('Double Attack')]
aliases[normalize('Quad. Atk.')] = aliases[normalize('Quadruple Attack')]
for _, name in ipairs({ 'Store TP', 'Subtle Blow', 'Subtle Blow II', 'Save TP',
    'Conserve TP' }) do define(name, 'Physical') end
for _, name in ipairs({ 'TP Bonus', 'Martial Arts', 'Fencer' }) do define(name, 'Physical') end
for _, name in ipairs({ 'Physical damage limit', 'Counter', 'Kick Attacks' }) do define(name, 'Physical', '%') end
aliases[normalize('PDL')] = aliases[normalize('Physical damage limit')]
for _, name in ipairs({ 'Magic burst damage', 'Magic burst damage II', 'Cure potency', 'Cure potency II',
    'Cure potency received', 'Enhancing magic duration', 'Enfeebling magic duration', 'Conserve MP' }) do define(name,
        'Magic', '%') end
aliases[normalize('Magic burst dmg.')] = aliases[normalize('Magic burst damage')]
aliases[normalize('Magic burst dmg. II')] = aliases[normalize('Magic burst damage II')]
aliases[normalize('Skillchain dmg.')] = aliases[normalize('Skillchain damage')]
aliases[normalize('Enhancing magic effect duration')] = aliases[normalize('Enhancing magic duration')]
aliases[normalize('Enfeebling magic effect duration')] = aliases[normalize('Enfeebling magic duration')]
aliases[normalize('Enh. mag. eff. dur.')] = aliases[normalize('Enhancing magic duration')]
for _, name in ipairs({ 'Cure spellcasting time', 'Song spellcasting time', 'Summoning magic casting time',
    'Blue magic spellcasting time', 'Drain and Aspir spell casting time' }) do define(name, 'Magic', '%', -1) end
for _, name in ipairs({ 'Drain and Aspir potency', 'Song effect duration' }) do define(name, 'Magic', '%') end
define('Ninjutsu magic attack bonus', 'Magic')
define('All songs', 'Magic')
define('Regen potency', 'Magic')
define('Refresh potency', 'Magic')
define('Quick Draw damage', 'Magic')
for _, name in ipairs({ 'Phalanx', 'Phalanx received', 'Stoneskin', 'Cursna', 'Cursna received',
    'Enfeebling magic effect', 'Magic burst accuracy' }) do define(name, 'Magic') end
define('Quick Magic', 'Magic', '%')
define('Blue magic recast delay', 'Magic', '%', -1)
define('Chain Affinity', 'Abilities')
define('Efflux: TP Bonus', 'Abilities', '', 1, { 'Efflux TP Bonus' })
define('Shield block rate', 'Defense', '%')
define('Blood Pact damage', 'Pet', '%')
define('Blood Pact delay', 'Pet', '', -1)
define('Blood Pact delay II', 'Pet', '', -1)
aliases[normalize('Blood Pact ability delay')] = aliases[normalize('Blood Pact delay')]
aliases[normalize('Blood Pact ability delay II')] = aliases[normalize('Blood Pact delay II')]
define('Waltz potency', 'Utility', '%')
define('Waltz potency received', 'Utility', '%')
define('Waltz delay', 'Utility', '', -1)
define('Phantom Roll', 'Utility')
define('Phantom Roll effect duration', 'Utility')
for _, entry in ipairs({ {'Damage taken', {'DT'}}, {'Physical damage taken', {'Phys. dmg. taken', 'PDT'}},
    {'Magic damage taken', {'Magic dmg. taken', 'MDT'}}, {'Breath damage taken', {'Breath dmg. taken'}},
    {'Damage taken II', {}}, {'Physical damage taken II', {}}, {'Magic damage taken II', {}} }) do
    define(entry[1], 'Defense', '%', -1, entry[2])
end
define('Spell interruption rate down', 'Defense', '%', 1, { 'Spell interruption rate' })
define('Status ailment resistance', 'Defense', '', 1, { 'Resistance to all status ailments' })
for _, name in ipairs({ 'Sleep', 'Poison', 'Paralyze', 'Blind', 'Silence', 'Petrify', 'Virus',
    'Stun', 'Amnesia', 'Bind', 'Slow', 'Gravity', 'Charm', 'Curse', 'Death', 'Terror' }) do
    define('Resist ' .. name, 'Defense')
end
define('Enmity', 'Utility', '', 0)
define('Enemy critical hit rate', 'Defense', '%', -1)
for _, name in ipairs({ 'Regen', 'Refresh', 'Regain', 'Occult Acumen',
    'Treasure Hunter' }) do define(name, 'Utility') end
define('Movement speed', 'Utility', '%')
for _, name in ipairs({ 'Fire', 'Ice', 'Wind', 'Earth', 'Lightning', 'Water', 'Light', 'Dark' }) do
    define(name .. ' resistance', 'Defense', '', 1, { name })
end
for _, name in ipairs({ 'Divine magic', 'Healing magic', 'Enhancing magic', 'Enfeebling magic', 'Elemental magic',
    'Dark magic', 'Summoning magic', 'Ninjutsu', 'Blue magic', 'Singing', 'Wind instrument', 'String instrument',
    'Geomancy', 'Handbell' }) do define(name .. ' skill', 'Skills') end
for _, name in ipairs({ 'Hand-to-hand', 'Dagger', 'Sword', 'Great sword', 'Axe', 'Great axe', 'Scythe',
    'Polearm', 'Katana', 'Great katana', 'Club', 'Staff', 'Archery', 'Marksmanship', 'Throwing',
    'Parrying', 'Magic accuracy' }) do define(name .. ' skill', 'Skills', '', 1, nil, true) end
for _, name in ipairs({ 'Shield', 'Guard', 'Evasion', 'Fishing' }) do define(name .. ' skill', 'Skills') end
define('Weapon damage', 'Weapons', '', 1, { 'DMG' }, true)
define('Weapon delay', 'Weapons', '', 0, { 'Delay' }, true)
local weaponSlots = { Main = true, Sub = true, Range = true, Ammo = true }
local owners = { pet = 'Pet', avatar = 'Avatar', automaton = 'Automaton', wyvern = 'Wyvern',
    luopan = 'Luopan', ['song effects'] = 'Song effects', player = '', master = '', you = '' }
local numericStat = "([%a][%a%s%.'\"/()%-]-)%s*([+%-:])%s*([+%-]?)%s*(%d+%.?%d*)%s*(%%?)"

local function context_start(line)
    local lower = line:lower()
    local owner = lower:match('^(.-):')
    return (owner and (owners[owner] ~= nil or (not owner:find('%d') and not aliases[normalize(owner)])))
        or lower:match('^set:') or lower:match('^latent') or lower:match('^unity')
        or lower:match('^occasionally') or lower:match('^occ%.') or lower:match('^augments ')
        or lower:match('^enhances ') or lower:match('^grants ')
        or lower:match('^while .-:') or lower:match('^during .-:') or lower:match('^when .-:')
end

-- Resource newlines wrap words and sentences as well as separate bonuses.
-- Join continuations before interpreting their numbers, so qualifiers stay attached.
local function description_lines(text)
    local lines, pending = {}, nil
    text = text:gsub('\226\136\146', '-'):gsub('\r', '')
    text = text:gsub('(%S)[ \t]+(%a+):', function(previous, owner)
        return previous .. (owners[owner:lower()] ~= nil and '\n' or ' ') .. owner .. ':'
    end)
    local function flush()
        if pending then lines[#lines + 1], pending = pending, nil end
    end
    for line in (text .. '\n'):gmatch('(.-)\n') do
        line = line:match('^%s*(.-)%s*$')
        if line == '' then
            flush(); lines[#lines + 1] = ''
        else
            local continuation = false
            if pending and not context_start(line) then
                local hasNumber = line:find('[+%-:]%s*[+%-]?%s*%d') or line:find('%d+%.?%d*%%')
                local tail = pending:match('([%a%.%s\"]+)$')
                local head = line:match('^([%a%.%s\"]-)[+%-:]')
                continuation = not hasNumber or line:match('^[+%-:]') or line:match('^%d')
                    or pending:match('[:+%-]%s*$') or (tail and head and aliases[normalize(tail .. head)] ~= nil)
            end
            if continuation then pending = pending .. ' ' .. line
            else flush(); pending = line end
        end
    end
    flush()
    return lines
end

function stats.Format(value, unit)
    if value == 0 then value = 0 end
    local number = math.floor(value) == value and string.format('%.0f', value)
        or string.format('%.2f', value):gsub('0+$', ''):gsub('%.$', '')
    return (value > 0 and '+' or '') .. number .. (unit or '')
end

local function sorted(values)
    local rows = {}
    for _, row in pairs(values) do
        row.value = math.floor(row.value * 100 + 0.5) / 100
        if row.value ~= 0 then row.text = stats.Format(row.value, row.unit); rows[#rows + 1] = row end
    end
    table.sort(rows, function(a, b)
        if a.group ~= b.group then return groups[a.group] < groups[b.group] end
        if a.order ~= b.order then return a.order < b.order end
        return a.key < b.key
    end)
    return rows
end

function stats.Build(items, coverage)
    coverage = coverage or {}
    local model = { values = {}, rows = {}, notes = {}, noteGroups = {}, pieces = #items,
        unchanged = coverage.unchanged or 0,
        rules = coverage.rules or 0, code = coverage.code or 0, baseOnly = 0, pending = coverage.pending }
    local noted, noteGroups = {}, {}
    local function note(item, line, reason)
        local key = item.slot .. '\0' .. line .. '\0' .. reason
        if noted[key] then return end
        noted[key] = true
        local entry = { slot = item.slot, item = item.name, text = line, reason = reason }
        model.notes[#model.notes + 1] = entry
        local groupKey = item.slot .. '\0' .. item.name
        local group = noteGroups[groupKey]
        if not group then
            group = { slot = item.slot, item = item.name, entries = {} }
            noteGroups[groupKey] = group
            model.noteGroups[#model.noteGroups + 1] = group
        end
        group.entries[#group.entries + 1] = entry
    end
    local function parse(item, text)
        local scope, conditional = '', false
        for _, line in ipairs(description_lines(text)) do
            if line == '' then scope, conditional = '', false
            else
                local lower = line:lower()
                if lower:match('^set:') or lower:match('^latent') or lower:match('^unity') or lower:match('^daytime:')
                    or lower:match('^nighttime:') or lower:match('^weather:') or lower:match('^day:')
                    or lower:match('^while ') or lower:match('^during ') or lower:match('^after ')
                        or lower:match('^when ')
                    or lower:match('^additional effect:') or lower:match('^augments ')
                    or lower:match('^enchantment:') or lower:match('^aftermath:') then conditional = true end
                local inlineConditional = lower:find(' while ', 1, true) or lower:find(' during ', 1, true)
                    or lower:find(' when ', 1, true) or lower:find('daytime', 1,
                        true) or lower:find('nighttime', 1, true)
                    or lower:find(' if ', 1, true) or lower:find(' with ', 1, true) or lower:find(' under ', 1, true)
                    or lower:find(' set:', 1, true) or lower:find('latent effect', 1, true)
                local original = line
                local owner, rest = line:match('^(.-):%s*(.*)$')
                if owner and owners[owner:lower()] ~= nil then
                    scope, line = owners[owner:lower()], rest
                elseif owner and not owner:find('%d') and not aliases[normalize(owner)] then
                    conditional = true
                end
                if conditional or inlineConditional or line:find('~', 1, true) or line:find('%d%s*%-%s*%d')
                    or lower:find('occasionally', 1, true) or lower:find('occ%.') then
                    note(item, original, 'Conditional or variable effect')
                else
                    line = line:gsub('([Ss]pell interruption rate down)%s*(%d+%.?%d*%%)', '%1+%2')
                    local recognized, fragments, cursor = false, {}, 1
                    local function fragment(value)
                        if value:find('[%w]') then fragments[#fragments + 1] = value:match('^%s*(.-)%s*$') end
                    end
                    while true do
                        local first, last, name, sign, innerSign, number, percent = line:find(numericStat, cursor)
                        if not first then fragment(line:sub(cursor)); break end
                        fragment(line:sub(cursor, first - 1))
                        local keyName = normalize(name)
                        local definition = aliases[keyName]
                        if definition then
                            local value = tonumber(number) * ((sign == '-' or innerSign == '-') and -1 or 1)
                            if keyName == 'spellinterruptionrate' then value = -value end
                            local unit = percent ~= '' and '%' or definition.unit
                            local group, label = definition.group, definition.name
                            if scope ~= '' then group, label = scope == 'Song effects' and 'Magic' or 'Pet',
                                scope .. ': ' .. label
                            elseif definition.weapon and weaponSlots[item.slot] then group, label = 'Weapons',
                                item.slot .. ': ' .. label
                            elseif definition.group == 'Weapons' then definition = nil end
                            if definition then
                                local key = label .. '\0' .. unit
                                local row = model.values[key]
                                if not row then
                                    row = { key = key, name = label, group = group, unit = unit, value = 0,
                                        order = definition.order, direction = definition.direction }
                                    model.values[key] = row
                                end
                                row.value = row.value + value
                                recognized = true
                            else fragment(line:sub(first, last)) end
                        else fragment(line:sub(first, last)) end
                        cursor = last + 1
                    end
                    if not recognized then note(item, original, 'Other or unrecognized effect')
                    elseif #fragments > 0 then note(item, table.concat(fragments, '; '),
                        'Other or unrecognized effect') end
                end
            end
        end
    end
    for _, item in ipairs(items) do
        if item.description and item.description ~= '' then parse(item, item.description)
        else note(item, 'Base description unavailable', 'Unknown base stats') end
        if item.unknownAugments then
            model.baseOnly = model.baseOnly + 1
            note(item, 'Exact augment bonuses are unavailable or ambiguous', 'Base stats only')
        else
            for _, augment in ipairs(item.augments or {}) do parse(item, augment) end
        end
    end
    model.rows = sorted(model.values)
    model.coverage = string.format('%d items | %d unchanged slots | %d rules', model.pieces,
        model.unchanged, model.rules)
    return model
end

function stats.Compare(left, right)
    local rows, seen = {}, {}
    for _, source in ipairs({ left.values, right.values }) do
        for key, entry in pairs(source) do
            if not seen[key] then
                seen[key] = true
                local a, b = left.values[key], right.values[key]
                local before, after = a and a.value or 0, b and b.value or 0
                local delta = math.floor((after - before) * 100 + 0.5) / 100
                local row = { key = key, name = entry.name, group = entry.group, order = entry.order,
                    unit = entry.unit, direction = entry.direction, value = delta,
                    before = stats.Format(before, entry.unit), after = stats.Format(after, entry.unit),
                    delta = delta, deltaText = stats.Format(delta, entry.unit) }
                rows[#rows + 1] = row
            end
        end
    end
    table.sort(rows, function(a,b)
        if a.group ~= b.group then return groups[a.group] < groups[b.group] end
        if a.order ~= b.order then return a.order < b.order end
        return a.key < b.key
    end)
    local warnings, byText = {}, {}
    for side, model in ipairs({ left, right }) do
        for _, message in ipairs(model.layerWarnings or {}) do
            local entry = byText[message]
            if not entry then
                entry = { text = message, sides = 0 }; byText[message] = entry; warnings[#warnings + 1] = entry
            end
            local flag = side == 1 and 1 or 2
            if entry.sides ~= 3 and entry.sides ~= flag then entry.sides = entry.sides + flag end
        end
    end
    return { rows = rows, left = left, right = right, warnings = warnings }
end
-- Compare's pinned stats (names, in order): each one's row from pair.rows, else a 0 / 0 row of that stat.
stats.DefaultPins = { 'Damage taken', 'Physical damage taken', 'Magic damage taken', 'HP', 'MP', 'STR',
    'Weapon skill damage' }
function stats.Pinned(pair, names)
    local out, byName = {}, {}
    for _, row in ipairs(pair.rows or {}) do byName[string.lower(row.name)] = row end
    for _, n in ipairs(names or {}) do
        local e = aliases[normalize(n)] -- DT, PDT: the stat's own name
        local row = byName[string.lower((e ~= nil) and e.name or n)]
        if row == nil then
            if e ~= nil then
                local zero = stats.Format(0, e.unit)
                row = { key = e.name, name = e.name, group = e.group, unit = e.unit, direction = e.direction,
                    value = 0, before = zero, after = zero, delta = 0, deltaText = zero }
            end
        end
        if row ~= nil then out[#out + 1] = row end
    end
    return out
end
return stats
