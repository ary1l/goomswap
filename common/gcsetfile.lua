-- Read and patch job-file set tables without executing the job file.
-- Offsets are Lua string byte positions. A splice replaces [start, finish).
-- Comments and unrelated source text are preserved by applying splices backwards.

local SCREEN = {
    'Main',
    'Sub',
    'Range',
    'Ammo',
    'Head',
    'Neck',
    'Ear1',
    'Ear2',
    'Body',
    'Hands',
    'Ring1',
    'Ring2',
    'Back',
    'Waist',
    'Legs',
    'Feet',
} -- the equipment screen's order (LAC constants.EquipScreenOrder)
local ORDER, CANON = {}, {}
for i, s in ipairs(SCREEN) do
    ORDER[s] = i
    CANON[string.lower(s)] = s
end

local function long_bracket(s, i)
    local lvl = string.match(s, '^%[(=*)%[', i)
    if lvl == nil then return nil end
    local close = ']' .. lvl .. ']'
    local e = string.find(s, close, i + #lvl + 2, true)
    return (e ~= nil) and (e + #close) or (#s + 1)
end

-- A quoted string at i: its text (escapes undone) and the index after it. One the line or the text ends first:
-- what it has and where it stopped, or nil when strict (gcbuild).
local function read_string(s, i, strict)
    local q = string.sub(s, i, i)
    local out, j = {}, i + 1
    while j <= #s do
        local c = string.sub(s, j, j)
        if c == '\\' then
            local n = string.sub(s, j + 1, j + 1)
            out[#out + 1] = (n == 'n') and '\n' or ((n == 't') and '\t' or n)
            j = j + 2
        elseif c == q then
            return table.concat(out), j + 1
        elseif c == '\n' then
            if strict then return nil end
            return table.concat(out), j -- unfinished: the line ends it
        else
            out[#out + 1] = c
            j = j + 1
        end
    end
    if strict then return nil end
    return table.concat(out), j
end

-- Past spaces and comments.
local function skip_ws(s, i)
    while i <= #s do
        local c = string.sub(s, i, i)
        if string.match(c, '%s') then
            i = i + 1
        elseif string.sub(s, i, i + 1) == '--' then
            local e = long_bracket(s, i + 2)
            if e ~= nil then
                i = e
            else
                local nl = string.find(s, '\n', i, true)
                i = (nl ~= nil) and (nl + 1) or (#s + 1)
            end
        else
            return i
        end
    end
    return i
end

-- One value from i: the index after its last character, and the index of what stopped it (',' ';' or the '}').
local function skip_value(s, i)
    local depth, last = 0, i
    while i <= #s do
        i = skip_ws(s, i)
        if i > #s then break end
        local c = string.sub(s, i, i)
        if (c == "'") or (c == '"') then
            i = select(2, read_string(s, i))
            last = i
        elseif (c == '[') and (long_bracket(s, i) ~= nil) then
            i = long_bracket(s, i)
            last = i
        elseif (c == '{') or (c == '(') or (c == '[') then
            depth = depth + 1
            i = i + 1
            last = i
        elseif (c == '}') or (c == ')') or (c == ']') then
            if depth == 0 then return last, i end
            depth = depth - 1
            i = i + 1
            last = i
        elseif ((c == ',') or (c == ';')) and (depth == 0) then
            return last, i
        else
            i = i + 1
            last = i
        end
    end
    return last, i
end

-- The entries of the table whose '{' is at `open`: { key, start, keyEnd, vstart, vend, sep } (sep: the index of its ','
-- or
-- ';', nil for none), and the index of its '}'.
local function scan_table(s, open)
    local entries, i = {}, open + 1
    while true do
        i = skip_ws(s, i)
        if i > #s then return entries, nil end
        local c = string.sub(s, i, i)
        if c == '}' then return entries, i end
        if (c == ',') or (c == ';') then
            i = i + 1
        else
            local e, vstart = { start = i }, i
            if (c == '[') and (long_bracket(s, i) == nil) then
                local j = skip_ws(s, i + 1)
                local q = string.sub(s, j, j)
                if (q == "'") or (q == '"') then
                    local key, after = read_string(s, j)
                    local k = skip_ws(s, after)
                    if string.sub(s, k, k) == ']' then
                        local keyEnd = k
                        k = skip_ws(s, k + 1)
                        if string.sub(s, k, k) == '=' then
                            e.key, e.bracket, e.keyEnd, vstart = key, true, keyEnd, skip_ws(s, k + 1)
                        end
                    end
                end
            else
                local name = string.match(s, '^[%a_][%w_]*', i)
                if name ~= nil then
                    local k = skip_ws(s, i + #name)
                    if (string.sub(s, k, k) == '=') and (string.sub(s, k + 1, k + 1) ~= '=') then
                        e.key, e.keyEnd, vstart = name, i + #name - 1, skip_ws(s, k + 1)
                    end
                end
            end
            e.vstart = vstart
            local vend, stop = skip_value(s, vstart)
            e.vend = vend
            local sc = string.sub(s, stop, stop)
            if (sc == ',') or (sc == ';') then
                e.sep = stop
                i = stop + 1
            else
                i = stop
            end
            entries[#entries + 1] = e
            if stop > #s then return entries, nil end
        end
    end
end

-- A slot's value text: { name, augs (text), path, kind } where kind is 'item' (a name or { Name = ... }), or 'code'
-- (anything else: a variable, a call, a priority list), shown as written and never edited.
local function read_slot(s, e)
    local raw = string.sub(s, e.vstart, e.vend - 1)
    local c = string.sub(s, e.vstart, e.vstart)
    if (c == "'") or (c == '"') then
        local name, after = read_string(s, e.vstart)
        if after == e.vend then return { kind = 'item', name = name, raw = raw } end
    elseif c == '{' then
        local fields = scan_table(s, e.vstart)
        local out = { kind = 'item', raw = raw }
        for _, f in ipairs(fields) do
            local k = (f.key ~= nil) and string.lower(f.key) or nil
            local fc = string.sub(s, f.vstart, f.vstart)
            if (k == 'name') and ((fc == "'") or (fc == '"')) then
                out.name = read_string(s, f.vstart)
            elseif (k == 'augpath') and ((fc == "'") or (fc == '"')) then
                out.path = read_string(s, f.vstart)
            elseif k == 'augrank' then
                out.rank = tonumber(string.sub(s, f.vstart, f.vend - 1))
            elseif k == 'augment' then
                local a = string.sub(s, f.vstart, f.vend - 1)
                a = string.gsub(string.gsub(a, '%[%d+%]%s*=%s*', ''), '[{}\'"]', '')
                out.augs = string.gsub(string.gsub(a, '%s+', ' '), '^%s*(.-)%s*$', '%1')
            end
        end
        if out.name ~= nil then return out end
    end
    return { kind = 'code', raw = raw }
end

local function line_start(s, i)
    while (i > 1) and (string.sub(s, i - 1, i - 1) ~= '\n') do
        i = i - 1
    end
    return i
end
local function line_end(s, i) -- the index after the line's '\n'
    local nl = string.find(s, '\n', i, true)
    return (nl ~= nil) and (nl + 1) or (#s + 1)
end
local function indent_at(s, i)
    return string.match(s, '^[ \t]*', line_start(s, i))
end
local function step(ind)
    return string.find(ind, '\t', 1, true) and '\t' or '    '
end -- one more level, as the file indents

-- Slots commented out inside a set (`--Ear1 = 'Ishvara Earring', -- not owned`, as /gcbuild leaves them): { [Slot] =
-- { ls, le (the line), ind, name, why } } for slots the set does not have. Filling one rewrites that line.
local function ghosts_of(text, vstart, close, slots)
    local out, p = nil, line_end(text, vstart)
    while p < close do
        local le = line_end(text, p)
        local ind, key, rest = string.match(string.sub(text, p, le - 1), '^([ \t]*)%-%-%s*(%a+%d?)%s*=%s*(.-)%s*$')
        local slot = (key ~= nil) and CANON[string.lower(key)] or nil
        if (slot ~= nil) and (slots[slot] == nil) and ((out == nil) or (out[slot] == nil)) and (le <= close + 1) then
            local c, name, after = string.sub(rest, 1, 1), nil, 1
            if (c == "'") or (c == '"') then
                name, after = read_string(rest, 1)
            elseif (c == '{') then -- { Name = 'Sakpata\'s Sword', Priority = 100 }: escapes read, the comment after it
                local q = string.match(rest, '^{[^}]-Name%s*=%s*()[\'"]')
                if (q ~= nil) then name = read_string(rest, q) end
                after = skip_value(rest, 1)
            end
            name = name or rest
            out = out or {}
            out[slot] = {
                ls = p,
                le = le,
                ind = ind,
                name = name,
                -- the last comment: /gcbuild adds its note after the line's own (--5 -- not owned)
                why = string.match(string.sub(rest, after), '.*%-%-%s*(.-)%s*$'),
            }
        end
        p = le
    end
    return out
end

-- A set inside a set (Buffs = { ['Aftermath: Lv.3'] = {...} }): its name as the engine's layer records give it
-- (gcinclude.SetLabel), and back to its key.
local function child_name(parent, key)
    return parent .. "['" .. key .. "']"
end
local function child_key(set, name)
    local pre = set.parentName .. "['"
    if (string.sub(name, 1, #pre) == pre) and (string.sub(name, -2) == "']") then
        return string.sub(name, #pre + 1, -3)
    end
    return nil
end

-- One set's entry e: { name, entry, slots, close, note, oneLine, extra, ghosts } or { name, entry, code }. A set
-- whose keys are not slots holds sets (Buffs): each table under a name is one in children (only from the top
-- level, deep = true); the set itself stays as written (extra).
local function read_set(text, e, name, deep)
    local set = { name = name, entry = e, slots = {}, bracket = e.bracket }
    if string.sub(text, e.vstart, e.vstart) ~= '{' then
        set.code = string.sub(text, e.vstart, e.vend - 1)
        return set
    end
    local se, sclose = scan_table(text, e.vstart)
    set.close = sclose
    -- its note: a comment right after the { on the set's first line (Foe = { -- Lullaby keeps...)
    local after = string.sub(text, e.vstart + 1, line_end(text, e.vstart) - 1)
    local note = string.match(after, '^%s*%-%-%s*(.-)%s*$')
    if (note ~= nil) and (note ~= '') then set.note = note end
    local lines = {}
    lines[line_start(text, e.vstart)] = true
    for _, f in ipairs(se) do
        local slot = (f.key ~= nil) and CANON[string.lower(f.key)] or nil
        if slot ~= nil then set.slots[slot] = { entry = f, value = read_slot(text, f) } end
        local ls = line_start(text, f.start)
        if lines[ls] then set.oneLine = true end
        lines[ls] = true
        if slot == nil then
            set.extra = true -- a non-slot key: the set is left alone
            if deep and (f.key ~= nil) and (string.sub(text, f.vstart, f.vstart) == '{') then
                local child = read_set(text, f, child_name(name, f.key), false)
                child.parentName, child.key = name, f.key
                set.children = set.children or {}
                set.children[#set.children + 1] = child
            end
        end
    end
    set.entries = se
    if (sclose ~= nil) and (#se > 0) and lines[line_start(text, sclose)] then set.oneLine = true end
    if (sclose ~= nil) and not set.oneLine and not set.extra then
        set.ghosts = ghosts_of(text, e.vstart, sclose, set.slots)
    end
    return set
end

-- The job file's sets: { list = { set }, byName = { [name] = set } }. A set: { name, start, vstart, vend, close,
-- slots = { [Slot] = { entry, value } }, code (not a table literal), oneLine (entries share lines: rewritten whole) }.
-- A set holding sets (Buffs) is followed in the list by each of them: { parentName, key, ... } named Buffs['Key'].
local function parse_file(text)
    local a, b = string.find(text, 'local%s+sets%s*=%s*T?%s*{')
    if a == nil then a, b = string.find(text, '[%a_][%w_]*%.Sets%s*=%s*T?%s*{') end
    if a == nil then return nil, 'no `local sets = {` table in the file' end
    local entries, close = scan_table(text, b)
    if close == nil then return nil, 'the sets table never closes' end
    local model = { list = {}, byName = {}, text = text, close = close, open = b }
    for _, e in ipairs(entries) do
        if e.key ~= nil then
            local set = read_set(text, e, e.key, true)
            model.list[#model.list + 1] = set
            model.byName[e.key] = set
            for _, child in ipairs(set.children or {}) do
                if model.byName[child.name] == nil then
                    model.list[#model.list + 1] = child
                    model.byName[child.name] = child
                end
            end
        end
    end
    return model
end

-- == Writing: each changed set's splices, applied from the end of the file back. ==

local function q(s)
    return "'" .. string.gsub(string.gsub(s, '\\', '\\\\'), "'", "\\'") .. "'"
end

-- A pick as a slot value: 'Name', { Name = 'X', AugPath='A' } or { Name = 'X', Augment = { [1] = 'a', ... } }.
local function item_text(name, augs, path)
    if (path ~= nil) and (path ~= '') then return '{ Name = ' .. q(name) .. ', AugPath=' .. q(path) .. ' }' end
    if (type(augs) == 'table') and (#augs > 0) then
        local parts = {}
        for i, a in ipairs(augs) do
            parts[#parts + 1] = '[' .. i .. '] = ' .. q(a)
        end
        return '{ Name = ' .. q(name) .. ', Augment = { ' .. table.concat(parts, ', ') .. ' } }'
    end
    return q(name)
end

-- The set's value from scratch, LAC style (only for a set whose entries share lines).
-- A slot commented out, as /gcbuild leaves gear you lack: --Range = 'Annihilator', -- note
local function comment_line(slot, raw, why)
    return '--'
        .. slot
        .. ' = ' .. raw .. ',' .. (((why ~= nil) and (why ~= '')) and (' -- ' .. string.gsub(why, '[\r\n]', ' ')) or '')
end

local function whole_set(set, edits, baseIndent)
    local lines = { '{' }
    for _, slot in ipairs(SCREEN) do
        local ed, cur = edits[slot], set.slots[slot]
        local v = nil
        if ed ~= nil then
            if not ed.remove then v = ed.text end
        elseif cur ~= nil then
            v = cur.value.raw
        end
        if v ~= nil then lines[#lines + 1] = baseIndent .. step(baseIndent) .. slot .. ' = ' .. v .. ',' end
        if (ed ~= nil) and ed.comment and (cur ~= nil) then
            lines[#lines + 1] = baseIndent .. step(baseIndent) .. comment_line(slot, cur.value.raw, ed.why)
        end
    end
    lines[#lines + 1] = baseIndent .. '}'
    return table.concat(lines, '\n')
end

-- Splices { a, b, text } (replace text[a, b) with text) for one set's edits.
local function set_splices(s, set, edits, out)
    if (set.code ~= nil) or (set.close == nil) or set.extra then return false end
    for slot in pairs(edits) do
        local cur = set.slots[slot]
        if (cur ~= nil) and (cur.value.kind == 'code') then
            return false
        end -- code in a slot is never rewritten
    end
    if set.oneLine then
        out[#out + 1] = { set.entry.vstart, set.entry.vend, whole_set(set, edits, indent_at(s, set.entry.start)) }
        return true
    end
    local adds, commas = {}, {}
    local function comma_after(e) -- once per entry: two ',' at one spot would break the file
        if (e.sep == nil) and not commas[e] then
            commas[e] = true
            out[#out + 1] = { e.vend, e.vend, ',' }
        end
    end
    local ghosts = set.ghosts or {}
    for slot, ed in pairs(edits) do
        local cur = set.slots[slot]
        if (cur == nil) and not ed.remove and (ghosts[slot] ~= nil) then
            -- the slot's commented-out line becomes the slot; the entry before it needs its comma
            local g = ghosts[slot]
            local prev = nil
            for s2, c2 in pairs(set.slots) do
                local gone = (edits[s2] ~= nil) and edits[s2].remove
                if not gone and (c2.entry.start < g.ls) and ((prev == nil) or (c2.entry.start > prev.start)) then
                    prev = c2.entry
                end
            end
            if prev ~= nil then comma_after(prev) end
            out[#out + 1] = { g.ls, g.le, g.ind .. slot .. ' = ' .. ed.text .. ',\n' }
        elseif cur ~= nil then
            local e = cur.entry
            if ed.remove then
                local ls, le = line_start(s, e.start), line_end(s, e.vend)
                local before = string.sub(s, ls, e.start - 1)
                local after = string.sub(s, (e.sep or (e.vend - 1)) + 1, le - 1)
                local cmt = ed.comment
                        and (string.match(before, '^%s*') .. comment_line(slot, cur.value.raw, ed.why) .. '\n') or ''
                if string.match(before, '^%s*$') and (string.match(after, '^%s*$') or string.match(after,
                    '^%s*%-%-')) then
                    out[#out + 1] = { ls, le, cmt }
                else
                    out[#out + 1] = { e.start, (e.sep or (e.vend - 1)) + 1, '' }
                    if cmt ~= '' then out[#out + 1] = { le, le, cmt } end
                end
            else
                out[#out + 1] = { e.vstart, e.vend, ed.text }
            end
        elseif ed.remove and (ghosts[slot] ~= nil) then -- dropped: the commented-out line goes
            out[#out + 1] = { ghosts[slot].ls, ghosts[slot].le, '' }
        elseif not ed.remove then
            adds[#adds + 1] = slot
        end
    end
    if #adds == 0 then return true end
    table.sort(adds, function(x, y) return ORDER[x] < ORDER[y] end)
    -- Where each new slot goes: after the kept slot just before it on the equipment screen, else before the first.
    local kept = {}
    for slot, cur in pairs(set.slots) do
        if (edits[slot] == nil) or not edits[slot].remove then kept[#kept + 1] = { slot = slot, e = cur.entry } end
    end
    table.sort(kept, function(x, y) return x.e.start < y.e.start end)
    local base = indent_at(s, set.entry.start)
    local ind = (#kept > 0) and indent_at(s, kept[1].e.start) or (base .. step(base))
    local groups, order = {}, {}
    for _, slot in ipairs(adds) do
        local anchor = nil
        for _, k in ipairs(kept) do
            if (ORDER[k.slot] < ORDER[slot]) and ((anchor == nil) or (ORDER[k.slot] > ORDER[anchor.slot])) then
                anchor = k
            end
        end
        local key = (anchor ~= nil) and anchor.slot or ''
        if groups[key] == nil then
            groups[key] = { anchor = anchor, lines = {} }
            order[#order + 1] = key
        end
        table.insert(groups[key].lines, ind .. slot .. ' = ' .. edits[slot].text .. ',\n')
    end
    for _, key in ipairs(order) do
        local g = groups[key]
        local body = table.concat(g.lines)
        if g.anchor ~= nil then
            local e = g.anchor.e
            comma_after(e)
            local at = line_end(s, e.sep or e.vend)
            out[#out + 1] = { at, at, body }
        elseif #kept > 0 then
            local at = line_start(s, kept[1].e.start)
            out[#out + 1] = { at, at, body }
        else
            -- An empty set: `{}` / `{ -- note }` on one line opens up; one already over lines takes the slots
            -- above its '}'.
            if line_start(s, set.close) == line_start(s, set.entry.vstart) then
                local close = indent_at(s, set.entry.start)
                local inner = string.sub(s, set.entry.vstart + 1, set.close - 1)
                local note = string.match(inner, '%-%-.*$')
                local head = (note ~= nil) and (' ' .. note) or ''
                out[#out + 1] = { set.entry.vstart + 1, set.close, head .. '\n' .. body .. close }
            else
                local at = line_start(s, set.close)
                out[#out + 1] = { at, at, body }
            end
        end
    end
    return true
end

-- New /mset modes into the job file: added to its `gcinclude.MeleeModes = {...}` line, else a new line with the
-- whole list (base: the modes the game has now, the engine's default when the file sets none) just before
-- `gcinclude.Initialize()`, where gcinclude reads it (gcinclude.lua: MeleeModes before Initialize). false: no place.
-- The first `gcinclude.<field> = {...}` line: where it starts, the text before the list, the list, and its quoted
-- names in order (once each, any case).
local function list_line(s, field)
    local p = 1
    while p <= #s do
        local nl = string.find(s, '\n', p, true) or (#s + 1)
        local pre, list = string.match(string.sub(s, p, nl - 1), '^([ \t]*gcinclude%.' .. field .. '%s*=%s*)(%b{})')
        if pre ~= nil then
            local names, seen = {}, {}
            for _, pattern in ipairs({ "'([^']*)'", '"([^"]*)"' }) do
                for m in string.gmatch(list, pattern) do
                    if not seen[string.lower(m)] then seen[string.lower(m)], names[#names + 1] = true, m end
                end
            end
            return p, pre, list, names, seen
        end
        p = nl + 1
    end
end

-- A new `gcinclude.<field> = {...};` line just before `gcinclude.Initialize()`; false when the file has none.
local function list_before_initialize(s, field, names, note, out)
    local p = 1
    while p <= #s do
        local nl = string.find(s, '\n', p, true) or (#s + 1)
        local ind = string.match(string.sub(s, p, nl - 1), '^([ \t]*)gcinclude%.Initialize%s*%(%s*%)')
        if ind ~= nil then
            local quoted = {}
            for _, m in ipairs(names) do quoted[#quoted + 1] = q(m) end
            out[#out + 1] = { p, p, ind .. 'gcinclude.' .. field .. ' = {' .. table.concat(quoted,
                ', ') .. '}; -- ' .. note .. '\n' }
            return true
        end
        p = nl + 1
    end
    return false
end

local function modes_splice(s, base, adds, out)
    local p, pre, list, names, seen = list_line(s, 'MeleeModes')
    if p == nil then
        local all = {}
        for _, m in ipairs(base) do all[#all + 1] = m end
        for _, m in ipairs(adds) do all[#all + 1] = m end
        return list_before_initialize(s, 'MeleeModes', all, '/mset modes (added by /gcedit)', out)
    end
    for _, m in ipairs(adds) do
        if not seen[string.lower(m)] then names[#names + 1] = m end
    end
    local quoted = {}
    for _, m in ipairs(names) do quoted[#quoted + 1] = q(m) end
    local a = p + #pre
    out[#out + 1] = { a, a + #list, '{' .. table.concat(quoted, ', ') .. '}' }
    return true
end

-- The /mset modes: the file's gcinclude.MeleeModes list, else GoomSwap's own (gcinclude.SetVariables), then extra.
local function melee_modes_of(s, extra)
    local out = {}
    local list = string.match(s or '', '\n%s*gcinclude%.MeleeModes%s*=%s*T?(%b{})')
    for _, m in string.gmatch(list or '', "(['\"])(.-)%1") do out[#out + 1] = m end
    if #out == 0 then out = { 'Default', 'SubtleBlow', 'Acc' } end
    for _, m in ipairs(extra or {}) do out[#out + 1] = m end
    return out
end

-- Whether name is one of Weapon_<mode>'s own sets, worn in its place: _1h (no dual wield), _<mset> or <mset>
-- (Weapon_Mpu_Acc, Weapon_MpuAcc: the engine reads both), each with _1h too. msets: the /mset modes.
local function weapon_variant_of(name, mode, msets)
    local rest, lm = string.match(string.lower(name or ''), '^weapon_(.+)$'), string.lower(mode or '')
    if (rest == nil) or (lm == '') or (rest == lm) or (string.sub(rest, 1, #lm) ~= lm) then return false end
    local tail = (string.gsub(string.sub(rest, #lm + 1), '_1h$', ''))
    tail = (string.gsub(tail, '^_', ''))
    if tail == '' then return true end
    for _, m in ipairs(msets or {}) do
        if string.lower(m) == tail then return true end
    end
    return false
end

-- Register newly saved top-level Weapon_ sets in /wm, without touching the
-- current mode, default, or any existing list entry. Variants are not modes.
local WEAPON_VARIANTS = {
    ['1h'] = true, ['acc'] = true, ['accuracy'] = true,
    ['atk'] = true, ['attack'] = true, ['tp'] = true, ['ws'] = true,
    ['dt'] = true, ['pdt'] = true, ['mdt'] = true, ['idle'] = true,
    ['hybrid'] = true, ['def'] = true, ['eva'] = true,
}
local function weapon_mode(name, existing, msets)
    local mode = type(name) == 'string' and string.match(name, '^Weapon_(.+)$')
    if not mode or mode == '' then return nil end
    local lower = string.lower(mode)
    if lower == 'none' then return nil end
    -- An existing base mode may have variants with arbitrary names, e.g. _Magic.
    for _, base in ipairs(existing) do
        local prefix = string.lower(base) .. '_'
        if string.sub(lower, 1, #prefix) == prefix then return nil end
        local stem = string.lower(base)
        local tail = string.sub(lower, #stem + 1)
        if string.sub(lower, 1, #stem) == stem and WEAPON_VARIANTS[tail] then return nil end
        if weapon_variant_of(name, base, msets) then return nil end -- Weapon_MpuSubtleBlow: Mpu with /mset
    end
    local suffix = string.match(lower, '_([^_]+)$')
    if suffix and WEAPON_VARIANTS[suffix] then return nil end
    return mode
end

local function weapon_modes_splice(s, newSets, out, newModes)
    if #newSets == 0 then return true, {} end
    local msets = melee_modes_of(s, newModes)
    local p, pre, list, names, seen = list_line(s, 'WeaponModes')
    if p == nil then -- no list in the file: one before Initialize, None first as the runtime default
        names, seen = { 'None' }, { none = true }
    end
    local adds = {}
    for _, set in ipairs(newSets) do
        local mode = (set.parentName == nil) and weapon_mode(set.name, names, msets) or nil
        if mode and not seen[string.lower(mode)] then
            adds[#adds + 1], names[#names + 1], seen[string.lower(mode)] = mode, mode, true
        end
    end
    if #adds == 0 then return true, {} end
    if p == nil then
        return list_before_initialize(s, 'WeaponModes', names, '/wm modes (added by /gcedit)', out), adds
    end
    -- the list's own text (comments, quoting, layout) is kept: the new modes go before its closing brace
    local at, inside = p + #pre, string.sub(list, 2, -2)
    local trimmed = string.gsub(inside, '%s+$', '')
    local comma = (#trimmed > 0 and not string.match(trimmed, '[,;]$')) and ',' or ''
    local additions = {}
    for _, mode in ipairs(adds) do additions[#additions + 1] = q(mode) end
    out[#out + 1] = { at, at + #list, '{' .. trimmed .. comma .. ((#trimmed > 0) and ' ' or '')
        .. table.concat(additions, ', ') .. string.sub(inside, #trimmed + 1) .. '}' }
    return true, adds
end

-- The quoted names of a list's text in the order written (list_line's names group them by quote kind).
local function names_in_order(list)
    local names, seen = {}, {}
    for _, m in string.gmatch(list, "(['\"])(.-)%1") do
        if not seen[string.lower(m)] then seen[string.lower(m)], names[#names + 1] = true, m end
    end
    return names
end

-- The /wm modes as the file lists them (gcinclude.WeaponModes, on one line), nil when it has no such line.
local function weapon_modes_of(s)
    local p, _, list = list_line(s, 'WeaponModes')
    return (p ~= nil) and names_in_order(list) or nil
end

-- The /wm list rewritten in order: the modes order names fill their places in that order, the rest (None, any
-- not named) keep theirs. Run on the text after the other splices, so new and renamed modes are in it. Comments
-- inside the braces go. nil when the file has no one-line list.
local function weapon_modes_ordered(s, order)
    local p, pre, list = list_line(s, 'WeaponModes')
    if p == nil then return nil end
    local names = names_in_order(list)
    local want, ordered, used = {}, {}, {}
    for _, m in ipairs(order) do want[string.lower(m)] = true end
    for _, m in ipairs(order) do
        for _, n in ipairs(names) do
            if (string.lower(n) == string.lower(m)) and not used[string.lower(n)] then
                used[string.lower(n)], ordered[#ordered + 1] = true, n
            end
        end
    end
    local quoted, k = {}, 0
    for _, n in ipairs(names) do
        if want[string.lower(n)] and (ordered[k + 1] ~= nil) then
            k = k + 1
            quoted[#quoted + 1] = q(ordered[k])
        else
            quoted[#quoted + 1] = q(n)
        end
    end
    local a = p + #pre
    return string.sub(s, 1, a - 1) .. '{' .. table.concat(quoted, ', ') .. '}' .. string.sub(s, a + #list)
end

-- Deleting a definition also removes its line when there is no other content.
local function deletion_splices(text, model, deleted, out)
    for name in pairs(deleted or {}) do
        local set = model.byName[name]
        if not set or not set.entry then return false, name end
        local entry = set.entry
        local first = entry.start
        local finish = entry.sep and (entry.sep + 1) or entry.vend
        local lineFirst, lineFinish = line_start(text, first), line_end(text, finish)
        local before = string.sub(text, lineFirst, first - 1)
        local after = string.sub(text, finish, lineFinish - 1)
        if string.match(before, '^%s*$') and string.match(after, '^%s*$') then first, finish = lineFirst, lineFinish end
        out[#out + 1] = { first, finish, '' }
    end
    return true
end

local function apply(s, splices)
    table.sort(splices, function(x, y) if x[1] == y[1] then return x[2] > y[2] end return x[1] > y[1] end)
    local lastA = #s + 2
    for _, sp in ipairs(splices) do
        if sp[2] > lastA then
            return nil
        end -- overlapping: refuse rather than corrupt
        s = string.sub(s, 1, sp[1] - 1) .. sp[3] .. string.sub(s, sp[2])
        lastA = sp[1]
    end
    return s
end

local LUA_WORDS = {
    ['and'] = true,
    ['break'] = true,
    ['do'] = true,
    ['else'] = true,
    ['elseif'] = true,
    ['end'] = true,
    ['false'] = true,
    ['for'] = true,
    ['function'] = true,
    ['if'] = true,
    ['in'] = true,
    ['local'] = true,
    ['nil'] = true,
    ['not'] = true,
    ['or'] = true,
    ['repeat'] = true,
    ['return'] = true,
    ['then'] = true,
    ['true'] = true,
    ['until'] = true,
    ['while'] = true,
    ['goto'] = true,
}
local function key_text(name)
    if string.match(name, '^[%a_][%w_]*$') and not LUA_WORDS[name] then return name end
    return '[' .. q(name) .. ']'
end

local function new_set_text(name, edits, ind)
    local lines = {}
    for _, slot in ipairs(SCREEN) do
        local e = (edits ~= nil) and edits[slot] or nil
        if (e ~= nil) and not e.remove then lines[#lines + 1] = ind .. step(ind) .. slot .. ' = ' .. e.text .. ',\n' end
    end
    if #lines == 0 then return ind .. key_text(name) .. ' = {},\n' end
    return ind .. key_text(name) .. ' = {\n' .. table.concat(lines) .. ind .. '},\n'
end

-- The set a new one sits after: the one it was copied from, else its nearest relative in the file ('mdt' -> Dt,
-- 'Savage Blade_Acc' -> Savage Blade, 'Ws_Dt' -> Ws_Default), else (nil) the last set of its group.
local RELATED = {
    mdt = { 'Dt' },
    aminon = { 'mdt', 'Dt' },
    incapacitated = { 'Dt' },
    sleeping = { 'Dt' },
    doomed = { 'Dt' },
    movement = { 'Dt' },
    sir = { 'Midcast' },
    midshot_acc = { 'Midshot' },
}
local function related(model, name)
    local function find(n)
        local l = string.lower(n)
        for _, set in ipairs(model.list) do
            if not set.new and (set.parentName == nil) and (string.lower(set.name) == l) then return set end
        end
        return nil
    end
    for _, n in ipairs(RELATED[string.lower(name)] or {}) do
        local hit = find(n)
        if hit ~= nil then return hit end
    end
    local base = name
    while true do
        local shorter = string.match(base, '^(.+)_[^_]+$')
        if shorter == nil then break end
        base = shorter
        local hit = find(base) or find(base .. '_Default')
        if hit ~= nil then return hit end
    end
    return nil
end

-- Splices for sets made in the editor: each goes after set.after (a set's name) when the file has it, else after
-- its nearest relative, else after the file's last set of its group (else after the last set).
-- news: { set } in the order made (set.name, set.group, set.after); edits: [name] = { [Slot] = edit }.
-- A set inside a set (ns.parentName) goes after ns.after when that is its sibling, else after the parent's last
-- entry, else into the empty parent.
local function new_set_splices(s, model, news, edits, out)
    local byAnchor, order = {}, {}
    for _, ns in ipairs(news) do
        local anchor, last, parent
        local after = (ns.after ~= nil) and model.byName[ns.after] or nil
        if ns.parentName ~= nil then
            parent = model.byName[ns.parentName]
            if (parent == nil) or parent.new or (parent.close == nil) or (parent.parentName ~= nil) then
                return false
            end
            if (after ~= nil) and not after.new and (after.parentName == ns.parentName) then
                anchor = after
            else
                local entries = parent.entries or {}
                anchor = (#entries > 0) and { name = '\0' .. #entries, entry = entries[#entries] } or nil
            end
        else
            if (after ~= nil) and not after.new and (after.parentName == nil) then
                anchor = after
            else
                anchor = related(model, ns.name)
            end
            if anchor == nil then
                for _, set in ipairs(model.list) do
                    if not set.new and (set.parentName == nil) then
                        last = set
                        if set.group == ns.group then anchor = set end
                    end
                end
            end
            anchor = anchor or last
        end
        local key = (ns.parentName or '') .. '\0' .. ((anchor ~= nil) and anchor.name or '')
        if byAnchor[key] == nil then
            byAnchor[key] = { anchor = anchor, parent = parent, sets = {} }
            order[#order + 1] = key
        end
        table.insert(byAnchor[key].sets, ns)
    end
    for _, key in ipairs(order) do
        local g = byAnchor[key]
        local ind, at
        if (g.anchor == nil) and (g.parent ~= nil) then
            -- an empty parent: `Buffs = {}` / `{ -- note }` on one line opens up; one over lines takes them above '}'
            local p = g.parent
            local base = indent_at(s, p.entry.start)
            ind = base .. step(base)
            local parts = {}
            for _, ns in ipairs(g.sets) do
                parts[#parts + 1] = new_set_text(ns.key, edits[ns.name], ind)
            end
            if line_start(s, p.close) == line_start(s, p.entry.vstart) then
                local note = string.match(string.sub(s, p.entry.vstart + 1, p.close - 1), '%-%-.*$')
                local head = (note ~= nil) and (' ' .. note) or ''
                out[#out + 1] = { p.entry.vstart + 1, p.close, head .. '\n' .. table.concat(parts) .. base }
            else
                local here = line_start(s, p.close)
                out[#out + 1] = { here, here, table.concat(parts) }
            end
        elseif g.anchor ~= nil then
            local e = g.anchor.entry
            ind = indent_at(s, e.start)
            if e.sep == nil then out[#out + 1] = { e.vend, e.vend, ',' } end
            at = line_end(s, e.sep or e.vend)
        else
            local base = indent_at(s, model.open)
            ind = base .. step(base)
            at = line_start(s, model.close)
            if at <= model.open then
                return false
            end -- `local sets = {}` on one line
        end
        if at ~= nil then
            local parts = {}
            for _, ns in ipairs(g.sets) do
                parts[#parts + 1] = new_set_text(ns.key or ns.name, edits[ns.name], ind)
            end
            out[#out + 1] = { at, at, table.concat(parts) }
        end
    end
    return true
end


-- Checked writes; callers preserve originals/backups before replacing files.
-- == Renaming a set: its key, and every place the file names it in code (comments are left alone). ==

-- The text with every comment blanked to spaces: same length, so positions found in it hold in the original.
local function code_only(s)
    local out, i, from = {}, 1, 1
    while i <= #s do
        local c = string.sub(s, i, i)
        if (c == "'") or (c == '"') then
            i = select(2, read_string(s, i))
        elseif (c == '[') and (long_bracket(s, i) ~= nil) then
            i = long_bracket(s, i)
        elseif string.sub(s, i, i + 1) == '--' then
            local e = long_bracket(s, i + 2) or string.find(s, '\n', i, true) or (#s + 1)
            out[#out + 1] = string.sub(s, from, i - 1) .. string.rep(' ', e - i)
            i, from = e, e
        else
            i = i + 1
        end
    end
    out[#out + 1] = string.sub(s, from)
    return table.concat(out)
end

local function quoted(text, quote) -- the inside of a quote-delimited string
    return (string.gsub(string.gsub(text, '\\', '\\\\'), quote, '\\' .. quote))
end

-- Strings whose text is exactly `old` from position a to b: { first, last } of each one's inside.
local function strings_in(s, code, a, b, old, out)
    local i = a
    while true do
        local at = string.find(code, "['\"]", i)
        if (at == nil) or (at >= b) then return end
        local text, after = read_string(s, at)
        if text == old then out[#out + 1] = { at + 1, after - 2, string.sub(s, at, at) } end
        i = after
    end
end

local REF_CALLS = { 'ByName', 'EquipSet', 'ForceEquipSet', 'FindSet', 'FindFilled' }
local MODE_LISTS = { 'WeaponModes', 'DefaultWeapons', 'WeaponRoles' }

-- A set inside a set renamed: each place code takes key `old` from the parent (sets.Buffs['old'],
-- sets['Buffs'].old, FindSet('Buffs')['old']) gets `new`. Returns how many.
local function child_refs(s, code, parent, old, new, out)
    local ends = {} -- where each reference to the parent ends
    for _, name, after in string.gmatch(code, '()%f[%w_][sS]ets%s*%.%s*([%a_][%w_]*)()') do
        if name == parent then ends[#ends + 1] = after end
    end
    local function quoted_ref(at, close)
        local text, after = read_string(s, at)
        if text ~= parent then return end
        local k = skip_ws(s, after)
        if string.sub(s, k, k) == close then ends[#ends + 1] = k + 1 end
    end
    for at in string.gmatch(code, '%f[%w_][sS]ets%s*%[%s*()[\'"]') do quoted_ref(at, ']') end
    for _, call in ipairs(REF_CALLS) do
        for at in string.gmatch(code, '%f[%w_]' .. call .. '%s*%(%s*()[\'"]') do quoted_ref(at, ')') end
    end
    local refs, newKey = 0, key_text(new)
    for _, p in ipairs(ends) do
        local j = skip_ws(s, p)
        local c = string.sub(s, j, j)
        if (c == '[') and (long_bracket(s, j) == nil) then
            local k = skip_ws(s, j + 1)
            local qc = string.sub(s, k, k)
            if (qc == "'") or (qc == '"') then
                local text, after = read_string(s, k)
                local e = skip_ws(s, after)
                if (text == old) and (string.sub(s, e, e) == ']') then
                    out[#out + 1] = { k + 1, after - 1, quoted(new, qc) }
                    refs = refs + 1
                end
            end
        elseif (c == '.') and (string.sub(s, j + 1, j + 1) ~= '.') then
            local n0, name, n1 = string.match(s, '^%s*()([%a_][%w_]*)()', j + 1)
            if name == old then
                out[#out + 1] = { j, n1, (string.sub(newKey, 1, 1) == '[') and newKey or ('.' .. newKey) }
                refs = refs + 1
            end
        end
    end
    return refs
end

-- Splices renaming set `old` to `new` everywhere the file names it: the key, sets.Old / sets['Old'],
-- ByName('Old') and the like, and for a Weapon_ set its mode in WeaponModes / DefaultWeapons / WeaponRoles.
-- Returns the number of places outside the key.
local function rename_splices(s, model, old, new, out)
    local set = model.byName[old]
    if (set == nil) or (set.entry == nil) or (set.entry.keyEnd == nil) then return nil end
    if set.parentName ~= nil then -- a set inside a set: its key, and code taking it from the parent
        local key = child_key(set, new)
        if key == nil then return nil end
        out[#out + 1] = { set.entry.start, set.entry.keyEnd + 1, key_text(key) }
        return child_refs(s, code_only(s), set.parentName, set.key, key, out)
    end
    out[#out + 1] = { set.entry.start, set.entry.keyEnd + 1, key_text(new) }
    local code, refs = code_only(s), 0
    for at, _, name, after in string.gmatch(code, '()%f[%w_][sS]ets%s*%.%s*()([%a_][%w_]*)()') do
        if name == old then
            local dot = string.find(code, '.', at, true)
            local key = key_text(new)
            out[#out + 1] = { dot, after, (string.sub(key, 1, 1) == '[') and key or ('.' .. key) }
            refs = refs + 1
        end
    end
    local found = {}
    for qAt in string.gmatch(code, '%f[%w_][sS]ets%s*%[%s*()[\'"]') do strings_in(s, code, qAt, qAt + 1, old, found) end
    for _, call in ipairs(REF_CALLS) do
        for qAt in string.gmatch(code, '%f[%w_]' .. call .. '%s*%(%s*()[\'"]') do strings_in(s, code, qAt,
            qAt + 1, old, found) end
    end
    local modeOld, modeNew = string.match(old, '^Weapon_(.+)$'), string.match(new, '^Weapon_(.+)$')
    if (modeOld ~= nil) and (modeNew ~= nil) then
        for _, list in ipairs(MODE_LISTS) do
            for vAt in string.gmatch(code, 'gcinclude%.' .. list .. '%s*=%s*()') do
                local vend = skip_value(s, vAt)
                local modes = {}
                strings_in(s, code, vAt, vend, modeOld, modes)
                for _, m in ipairs(modes) do
                    out[#out + 1] = { m[1], m[2] + 1, quoted(modeNew, m[3]) }
                    refs = refs + 1
                end
            end
        end
    end
    for _, f in ipairs(found) do
        out[#out + 1] = { f[1], f[2] + 1, quoted(new, f[3]) }
        refs = refs + 1
    end
    return refs
end

-- renames: { [old] = new }. False and the name when a set to rename has no plain entry in the sets table.
local function rename_all(s, model, renames, out)
    for old, new in pairs(renames or {}) do
        if rename_splices(s, model, old, new, out) == nil then return false, old end
    end
    return true
end

-- == A deleted Weapon_ set's /wm mode: out of gcinclude.WeaponModes; DefaultWeapons / WeaponRoles naming it. ==

-- Where each assignment of gcinclude.<list> starts its value (code only: a commented-out line is not one).
local function list_values(code, list)
    local out = {}
    for vAt in string.gmatch(code, '%f[%w_]gcinclude%.' .. list .. '%s*=%s*()') do out[#out + 1] = vAt end
    return out
end
-- The '{' of a value written as a table ({...} or T{...}), else nil.
local function table_open(s, vAt)
    if string.sub(s, vAt, vAt) == '{' then return vAt end
    return string.match(s, '^T%s*(){', vAt)
end

-- Every quoted string in the mode lists (WeaponModes, DefaultWeapons, WeaponRoles) that names one of modes, any
-- case: { { list = 'DefaultWeapons', text = as written }, ... }.
local function mode_mentions(s, modes)
    local want, out, code = {}, {}, code_only(s)
    for _, m in ipairs(modes) do want[string.lower(m)] = true end
    for _, list in ipairs(MODE_LISTS) do
        for _, vAt in ipairs(list_values(code, list)) do
            local open, last = table_open(s, vAt), nil
            if open ~= nil then
                last = select(2, scan_table(s, open))
            elseif (string.sub(s, vAt, vAt) == "'") or (string.sub(s, vAt, vAt) == '"') then
                open, last = vAt, vAt
            end
            local i = open
            while (last ~= nil) and (i <= last) do
                local at = string.find(code, "['\"]", i)
                if (at == nil) or (at > last) then break end
                local text, after = read_string(s, at)
                if want[string.lower(text)] then out[#out + 1] = { list = list, text = text } end
                i = after
            end
        end
    end
    return out
end

-- gcinclude.WeaponModes without modes (any case; None stays): each entry goes with the comma after it (the last
-- one: with the comma before it), and its line too when nothing but spaces or a comment is left on it. The text;
-- unchanged when no list names them.
local function weapon_modes_without(s, modes)
    local want = {}
    for _, m in ipairs(modes) do
        if string.lower(m) ~= 'none' then want[string.lower(m)] = true end
    end
    while true do -- one entry at a time, the text read again each time: no two cuts can meet
        local code, cut = code_only(s), nil
        for _, vAt in ipairs(list_values(code, 'WeaponModes')) do
            local open = table_open(s, vAt)
            local entries = (open ~= nil) and scan_table(s, open) or {}
            for k, e in ipairs(entries) do
                local c = string.sub(s, e.vstart, e.vstart)
                if (cut == nil) and (e.key == nil) and ((c == "'") or (c == '"')) then
                    local text, after = read_string(s, e.vstart)
                    if (after == e.vend) and want[string.lower(text)] then
                        if e.sep ~= nil then
                            local j = e.sep + 1
                            while string.match(string.sub(s, j, j), '^[ \t]$') do j = j + 1 end
                            cut = { e.start, j }
                        elseif k > 1 then
                            cut = { entries[k - 1].sep or entries[k - 1].vend, e.vend }
                        else
                            cut = { e.start, e.vend }
                        end
                    end
                end
            end
            if cut ~= nil then break end
        end
        if cut == nil then return s end
        if not string.find(string.sub(s, cut[1], cut[2] - 1), '\n', 1, true) then
            local ls, le = line_start(s, cut[1]), line_end(s, cut[1])
            local nl = (string.sub(s, le - 1, le - 1) == '\n') and 1 or 0
            if string.match(string.sub(code, ls, cut[1] - 1), '^%s*$')
                and string.match(string.sub(code, cut[2], le - 1 - nl), '^%s*$') then
                cut = { ls, le }
            end
        end
        s = string.sub(s, 1, cut[1] - 1) .. string.sub(s, cut[2])
    end
end

-- char.lua (`return { settings = { ... } }`): the settings table's `key = ...` replaced, or added as its first entry
-- (a settings table is added when there is none). valueFor(indent) gives the value's Lua text for a key line with
-- that indent, or nil to take the key out. Comments and every other line stay. nil, why when the file has no
-- `return {` table.
local function set_char_setting(text, key, valueFor)
    local r = string.find(code_only(text), '%f[%w_]return%s*{')
    if r == nil then return nil, 'no `return {` table' end
    local open = string.find(text, '{', r, true)
    local entries, close = scan_table(text, open)
    if close == nil then return nil, 'its table never closes' end
    local settings = nil
    for _, e in ipairs(entries) do
        if (e.key == 'settings') and (string.sub(text, e.vstart, e.vstart) == '{') then settings = e end
    end
    local out = {}
    if settings == nil then
        if valueFor(indent_at(text, open) .. '        ') == nil then return text end -- nothing to take out
        local ind = indent_at(text, open) .. '    '
        local inner = ind .. '    '
        local block = '\n' .. ind .. 'settings = {\n' .. inner .. key .. ' = ' .. valueFor(inner) .. ',\n' .. ind .. '},'
        out[1] = { open + 1, open + 1, block }
    else
        local sEntries, sClose = scan_table(text, settings.vstart)
        if sClose == nil then return nil, 'its settings table never closes' end
        local hit = nil
        for _, e in ipairs(sEntries) do
            if e.key == key then hit = e end
        end
        local value = valueFor(indent_at(text, (hit or sEntries[1] or settings).start))
        if (hit ~= nil) and (value == nil) then -- taken out: its line goes when nothing else is on it
            local first, finish = hit.start, hit.sep and (hit.sep + 1) or hit.vend
            local ls, le = line_start(text, first), line_end(text, finish)
            if string.match(string.sub(text, ls, first - 1), '^%s*$') and string.match(string.sub(text, finish, le - 1), '^%s*$') then
                first, finish = ls, le
            end
            out[1] = { first, finish, '' }
        elseif value == nil then
            return text
        elseif hit ~= nil then
            out[1] = { hit.vstart, hit.vend, value }
        else
            local ind = (#sEntries > 0) and indent_at(text, sEntries[1].start)
                or (indent_at(text, settings.start) .. '    ')
            out[1] = { settings.vstart + 1, settings.vstart + 1, '\n' .. ind .. key .. ' = ' .. valueFor(ind) .. ',' }
        end
    end
    return apply(text, out)
end

-- The text with the return table's own key (beside settings: Packer, sets) set to valueFor(indent) (nil: taken out).
local function set_char_top(text, key, valueFor)
    local r = string.find(code_only(text), '%f[%w_]return%s*{')
    if r == nil then return nil, 'no `return {` table' end
    local open = string.find(text, '{', r, true)
    local entries, close = scan_table(text, open)
    if close == nil then return nil, 'its table never closes' end
    local hit = nil
    for _, e in ipairs(entries) do
        if e.key == key then hit = e end
    end
    local ind = (#entries > 0) and indent_at(text, entries[1].start) or (indent_at(text, open) .. '    ')
    local value = valueFor((hit ~= nil) and indent_at(text, hit.start) or ind)
    if hit == nil then
        if value == nil then return text end
        local at = (#entries > 0) and (entries[#entries].sep and (entries[#entries].sep + 1) or entries[#entries].vend) or (open + 1)
        local comma = ((#entries > 0) and (entries[#entries].sep == nil)) and ',' or ''
        return apply(text, { { at, at, comma .. '\n' .. ind .. key .. ' = ' .. value .. ',' } })
    end
    if value ~= nil then return apply(text, { { hit.vstart, hit.vend, value } }) end
    local first, finish = hit.start, hit.sep and (hit.sep + 1) or hit.vend
    local ls, le = line_start(text, first), line_end(text, finish)
    if string.match(string.sub(text, ls, first - 1), '^%s*$') and string.match(string.sub(text, finish, le - 1), '^%s*$') then
        first, finish = ls, le
    end
    return apply(text, { { first, finish, '' } })
end

-- == A job file's own settings: `gcinclude.<name> = <value>` statements (name 'settings.X' or 'X'), and the profile's
-- own `profile.Packer = <value>` (name 'profile.Packer': LAC's Packer list, read when /lac gear runs). ==
-- The statement's owner and name: 'profile.Packer' as it is, anything else under gcinclude.
local function owned_name(name)
    if string.match(name, '^profile%.') then return name end
    return 'gcinclude.' .. name
end

-- The end (the index after it) of a data value at i: a string, a number, true/false/nil, or a table ({...}, T{...})
-- with nothing but a ';' or a comment after it on its line. nil: the value is code.
local function data_value_end(s, i)
    local c = string.sub(s, i, i)
    local e
    if (c == "'") or (c == '"') then
        e = select(2, read_string(s, i))
    else
        local open = (c == '{') and i or string.match(s, '^T%s*(){', i)
        if open ~= nil then
            local _, close = scan_table(s, open)
            e = (close ~= nil) and (close + 1) or nil
        else
            e = string.match(s, '^%-?%d[%w%.]*()', i) or string.match(s, '^true()', i) or string.match(s, '^false()', i)
                or string.match(s, '^nil()', i)
            if (e ~= nil) and string.match(string.sub(s, e, e), '[%w_]') then e = nil end -- truex, nilable
        end
    end
    if e == nil then return nil end
    if string.match(s, '^[ \t]*;', e) then return e end -- the statement ends there
    local at = string.match(s, '^[ \t]*()', e)
    local two = string.sub(s, at, at + 1)
    if (two == '') or string.match(two, '^[\r\n]') or (two == '--') then return e end
    return nil -- more of the expression follows: code
end

local function job_lines(s, name)
    local code, out = code_only(s), {}
    local dotted = string.gsub(owned_name(name), '%.', '%%s*%%.%%s*')
    for at, v in string.gmatch(code, '()%f[%w_]' .. dotted .. '%s*=()') do
        if string.sub(code, v, v) ~= '=' then -- '==' is a test
            local vstart = string.match(s, '^[ \t]*()', v)
            out[#out + 1] = { at = at, vstart = vstart, vend = data_value_end(s, vstart) }
        end
    end
    return out
end

-- The file's own value for name as Lua text; nil and why when it has none ('none'), more than one ('set in N
-- places') or code ('code').
local function job_setting(s, name)
    local lines = job_lines(s, name)
    if #lines == 0 then return nil, 'none' end
    if #lines > 1 then return nil, 'set in ' .. #lines .. ' places' end
    if lines[1].vend == nil then return nil, 'code' end
    return string.sub(s, lines[1].vstart, lines[1].vend - 1)
end

-- The text with name set to value (Lua text, or a function(indent) giving it; nil: the statement taken out, its line
-- too when nothing else is on it). A new one goes just before `gcinclude.Initialize()`. nil and why when it can't.
local function set_job_setting(s, name, value)
    local function text_at(i) return (type(value) == 'function') and value(indent_at(s, i)) or value end
    local lines = job_lines(s, name)
    if #lines > 1 then return nil, owned_name(name) .. ' is set in ' .. #lines .. ' places: edit it in the file' end
    local hit = lines[1]
    if hit ~= nil then
        if hit.vend == nil then return nil, owned_name(name) .. ' is code in the file: edit it there' end
        if value ~= nil then return apply(s, { { hit.vstart, hit.vend, text_at(hit.at) } }) end
        local finish = string.match(s, '^[ \t]*;()', hit.vend) or hit.vend
        local ls, le = line_start(s, hit.at), line_end(s, finish)
        local after = string.sub(s, finish, le - 1)
        if string.match(string.sub(s, ls, hit.at - 1), '^%s*$')
            and (string.match(after, '^%s*%-%-') or string.match(after, '^%s*$')) then
            return apply(s, { { ls, le, '' } }) -- its comment says what it did: it goes too
        end
        return apply(s, { { hit.at, finish, '' } })
    end
    if value == nil then return s end
    local code, p = code_only(s), 1
    while p <= #s do
        local nl = string.find(code, '\n', p, true) or (#code + 1)
        local ind = string.match(string.sub(code, p, nl - 1), '^([ \t]*)gcinclude%.Initialize%s*%(%s*%)')
        if ind ~= nil then
            return apply(s, { { p, p, ind .. owned_name(name) .. ' = ' .. text_at(p) .. ';\n' } })
        end
        p = nl + 1
    end
    return nil, 'no gcinclude.Initialize() line to put ' .. owned_name(name) .. ' before'
end

-- Lua text for a string: single quotes, or double ones when it has an apostrophe and no double quote (as it reads).
local function quote_text(s)
    if string.find(s, "'", 1, true) and not string.find(s, '"', 1, true) and not string.find(s, '\\', 1, true) then
        return '"' .. s .. '"'
    end
    return q(s)
end

local function write_checked(path, text, opener)
    local file, err = (opener or io.open)(path, 'wb')
    if not file then return nil, err or 'open failed' end
    local writeCallOk, writeResult, writeError = pcall(file.write, file, text)
    local closeCallOk, closeResult, closeError = pcall(file.close, file)
    if not writeCallOk or not writeResult then return nil, writeError or writeResult or 'write failed' end
    if not closeCallOk or not closeResult then return nil, closeError or closeResult or 'close failed' end
    return true
end

-- Editor file operations. Only known job names and this file's own backup names
-- are considered; directory contents and job code are never evaluated.
local JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG',
    'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }
local function file_key(path)
    return type(path) == 'string' and path:gsub('\\', '/'):gsub('/+', '/'):lower() or ''
end
local function job_files(folder, activePath, activeJob, exists)
    local files, seen = {}, {}
    local function add(path, job)
        local key = file_key(path)
        if key ~= '' and not seen[key] and exists(path) then
            seen[key] = true
            files[#files + 1] = { path = path, job = job, name = path:match('[^\\/]+$'),
                active = key == file_key(activePath) }
        end
    end
    for job, name in ipairs(JOBS) do add(folder .. name .. '.lua', job) end
    add(activePath, activeJob)
    table.sort(files, function(a, b) return a.name:lower() < b.name:lower() end)
    return files
end
local backups = {}
function backups.Keep(value)
    value = tonumber(value)
    if not value or value ~= value or value < 0 or value == math.huge then return 10 end
    return math.min(1000, math.floor(value)) -- zero explicitly keeps every backup
end
function backups.Path(path, exists, stamp)
    local stem = path:gsub('%.[Ll][Uu][Aa]$', '') .. '.' .. (stamp or os.date('%Y%m%d-%H%M%S'))
    for index = 0, 10000 do
        local candidate = stem .. (index == 0 and '' or ('.' .. index)) .. '.gcedit.bak'
        if not exists(candidate) then return candidate end
    end
    return nil, 'too many backups with the same timestamp'
end
-- path's editor backups among files (a folder's listing): { path, stamp, sequence, protected }, newest first (the
-- protected one, this save's, before all). nil when files is not a list.
local function backup_list(path, files, protected)
    if type(files) ~= 'table' then return nil end
    local folder, name = path:match('^(.*[\\/])([^\\/]+)$')
    folder, name = folder or '', name or path
    local prefix = name:gsub('%.[Ll][Uu][Aa]$', ''):lower() .. '.'
    local candidates, seen = {}, {}
    for _, entry in pairs(files) do
        if type(entry) == 'string' then
            local parent, leaf = entry:match('^(.*[\\/])([^\\/]+)$')
            leaf = leaf or entry
            local suffix = leaf:lower():sub(#prefix + 1)
            local stamp, sequence = suffix:match('^(%d%d%d%d%d%d%d%d%-%d%d%d%d%d%d)%.(%d+)%.gcedit%.bak$')
            if not stamp then stamp = suffix:match('^(%d%d%d%d%d%d%d%d%-%d%d%d%d%d%d)%.gcedit%.bak$') end
            local full = folder .. leaf
            local key = file_key(full)
            if leaf:lower():sub(1, #prefix) == prefix and stamp
                and (not parent or file_key(parent) == file_key(folder)) and not seen[key] then
                seen[key] = true
                candidates[#candidates + 1] = { path = full, stamp = stamp, sequence = tonumber(sequence) or 0,
                    protected = (protected ~= nil) and (key == file_key(protected)) }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.protected ~= b.protected then return a.protected end
        if a.stamp ~= b.stamp then return a.stamp > b.stamp end
        return a.sequence > b.sequence
    end)
    return candidates
end
backups.List = backup_list
function backups.Prune(path, keep, files, remove, protected)
    keep = backups.Keep(keep)
    if keep == 0 then return 0 end
    local candidates = backup_list(path, files, protected)
    if candidates == nil then return 0, 'could not list editor backups' end
    local removed, failure = 0, nil
    for index = keep + 1, #candidates do
        local ok, err = remove(candidates[index].path)
        if ok then removed = removed + 1 else failure = err or 'could not remove an old editor backup' end
    end
    return removed, failure
end

return {
    FileKey = file_key,
    JobFiles = job_files,
    Backups = backups,
    Write = write_checked,
    ReadString = read_string,
    Quote = q,
    SetCharSetting = set_char_setting,
    SetCharTop = set_char_top,
    slots = SCREEN,
    Parse = parse_file,
    ChildName = child_name,
    ChildKey = child_key,
    FormatItem = item_text,
    FormatKey = key_text,
    ReadCommentedSlots = ghosts_of,
    AddSlotEdits = set_splices,
    AddDeletions = deletion_splices,
    AddModes = modes_splice,
    AddWeaponModes = weapon_modes_splice,
    WeaponModes = weapon_modes_of,
    JobSetting = job_setting,
    SetJobSetting = set_job_setting,
    QuoteText = quote_text,
    OrderWeaponModes = weapon_modes_ordered,
    ModeMentions = mode_mentions,
    MeleeModes = melee_modes_of,
    WeaponVariantOf = weapon_variant_of,
    RemoveWeaponModes = weapon_modes_without,
    AddNewSets = new_set_splices,
    AddRenames = rename_all,
    RenameCount = function(s, model, old, new) return rename_splices(s, model, old, new, {}) end,
    Apply = apply,
}
