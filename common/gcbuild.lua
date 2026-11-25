-- /gcbuild [JOB]: a proposed job file for this character. Takes the job's example (examples/<JOB>.lua)
-- and keeps, set by set, the gear the character owns:
--   owned as the example names it            the line stays
--   owned, but with other augments           the name alone stays (LAC needs every listed augment on the item)
--   owned, only in a bag sets can't use      the line stays, marked: move it to a wardrobe
-- not owned (or one copy for two slots)    the line is commented out where it stands, so the set under it shows through
-- A piece you lack is swapped for the version of the same item you do own
-- (Leth. Chappel +2 for +3, Chirich Ring for Chirich Ring +1), the highest you have. Nothing else is ever picked.
-- Nothing outside the sets changes: weapon modes whose Weapon_<mode> set lost its weapon stay in WeaponModes and are
-- listed at the top; other item names in OnLoad and the handlers (gFunc.Equip, slot-pick lists) are listed too.
-- Written next to the job files as <JOB>.proposed.lua: your <JOB>.lua is never touched.
-- /checksets uses the same bag scan and rules on the sets you have loaded (CheckSets below).
-- Loaded by gcinclude when the command is used. Build() is plain text in, text out.
local gcbuild = {}
local setFile = gFunc.LoadFile('common\\gcsetfile.lua') -- the editor's job-file string helpers

local SLOTS = { Main = true, Sub = true, Range = true, Ammo = true, Head = true, Neck = true, Ear1 = true, Ear2 = true,
    Body = true, Hands = true, Ring1 = true, Ring2 = true, Back = true, Waist = true, Legs = true, Feet = true }
local KEYWORDS = { remove = true, displaced = true, ignore = true } -- LAC slot words, not items

-- A quoted string starting at `at`: its text (escapes undone) and the index after its closing quote; nil when there
-- is no quote at `at` or it never closes.
local function read_string(s, at)
    local c = string.sub(s, at, at)
    if (c ~= "'") and (c ~= '"') then return nil end
    return setFile.ReadString(s, at, true)
end

-- The index after the '}' matching the '{' at `at` (strings skipped), or nil.
local function skip_table(s, at)
    local depth, i = 0, at
    while (i <= #s) do
        local c = string.sub(s, i, i)
        if (c == "'") or (c == '"') then
            local _, nxt = read_string(s, i)
            if (nxt == nil) then return nil end
            i = nxt
        else
            if (c == '{') then depth = depth + 1 elseif (c == '}') then depth = depth - 1 end
            i = i + 1
            if (depth == 0) then return i end
        end
    end
    return nil
end

-- An item value at `at` ('Name' or { Name = 'X', Augment = {...}, AugPath = 'B' }): { name, augs, path } and the
-- index after it. nil when it is neither (a variable, a call): such a line is left as it is.
local function read_item(s, at)
    local c = string.sub(s, at, at)
    if (c == "'") or (c == '"') then
        local name, nxt = read_string(s, at)
        if (name == nil) then return nil end
        return { name = name, augs = {} }, nxt
    end
    if (c ~= '{') then return nil end
    local nxt = skip_table(s, at)
    if (nxt == nil) then return nil end
    local body = string.sub(s, at, nxt - 1)
    local n1 = select(2, string.find(body, '[Nn]ame%s*=%s*'))
    local name = (n1 ~= nil) and read_string(body, n1 + 1) or nil
    if (name == nil) then return nil end
    local item = { name = name, augs = {} }
    local a1 = select(2, string.find(body, 'Augment%s*=%s*'))
    if (a1 ~= nil) then
        local first = string.sub(body, a1 + 1, a1 + 1)
        if (first == '{') then
            local stop = skip_table(body, a1 + 1) or #body
            local i = a1 + 2
            while (i < stop) do
                local ch = string.sub(body, i, i)
                if (ch == "'") or (ch == '"') then
                    local str, after = read_string(body, i)
                    if (str == nil) then break end
                    item.augs[#item.augs + 1] = str
                    i = after
                else
                    i = i + 1
                end
            end
        else
            local str = read_string(body, a1 + 1)
            if (str ~= nil) then item.augs[1] = str end
        end
    end
    local p1 = select(2, string.find(body, 'AugPath%s*=%s*'))
    if (p1 ~= nil) then item.path = read_string(body, p1 + 1) end
    return item, nxt
end

-- A copy of an item fits the example's entry the way LAC checks it (equip.lua CheckAugments): the path, when
-- named, is the copy's, and every augment listed is on the copy.
local function copy_fits(item, copy)
    if (item.path ~= nil) and (copy.path ~= item.path) then return false end
    for _, want in ipairs(item.augs) do
        local found = false
        for _, have in ipairs(copy.augs) do
            if (have == want) then found = true; break end
        end
        if not found then return false end
    end
    return true
end

local q = setFile.Quote

local function copy_text(copy)
    local parts = {}
    if (copy.path ~= nil) then parts[#parts + 1] = 'Path ' .. tostring(copy.path) end
    for _, a in ipairs(copy.augs) do parts[#parts + 1] = a end
    return (#parts > 0) and table.concat(parts, ', ') or 'no augments'
end

-- 'Leth. Chappel +3' -> 'leth. chappel', 3; 'Chirich Ring' -> 'chirich ring', 0.
local function family_of(name)
    local base, plus = string.match(name, '^(.-) %+(%d+)$')
    return string.lower(base or name), tonumber(plus) or 0
end

-- The other versions of an item the character owns ({ entry, plus }...), highest first; built once per owned table.
local familyIndex = setmetatable({}, { __mode = 'k' })
local function relatives(owned, name)
    local idx = familyIndex[owned]
    if (idx == nil) then
        idx = {}
        for _, entry in pairs(owned) do
            if (type(entry) == 'table') and (type(entry.name) == 'string') then
                local base, plus = family_of(entry.name)
                idx[base] = idx[base] or {}
                table.insert(idx[base], { entry = entry, plus = plus })
            end
        end
        for _, list in pairs(idx) do table.sort(list, function(a, b) return a.plus > b.plus end) end
        familyIndex[owned] = idx
    end
    return idx[(family_of(name))] or {}
end

-- What to do with one item of the example: 'keep', 'move' (bag), 'name' (other augments; note), 'family' (the
-- version owned, its bag when it has to be moved), 'drop' (why).
-- used: how often each item was already kept in this set, so the same ring in Ring1 and Ring2 needs two copies.
local function judge(item, owned, used)
    local key = string.lower(item.name)
    if KEYWORDS[key] then return 'keep' end
    local have = owned[key]
    local why = nil
    if (have == nil) or (#have.copies == 0) then
        why = 'not owned'
    else
        used[key] = (used[key] or 0) + 1
        if (used[key] > #have.copies) then why = 'only ' .. #have.copies .. ' owned' end
    end
    if (why ~= nil) then
        for _, rel in ipairs(relatives(owned, item.name)) do
            local rkey = string.lower(rel.entry.name)
            if (rkey ~= key) and ((used[rkey] or 0) < #rel.entry.copies) then
                used[rkey] = (used[rkey] or 0) + 1
                local bag = nil
                for _, copy in ipairs(rel.entry.copies) do
                    if copy.equippable then bag = nil; break end
                    bag = bag or copy.bag
                end
                return 'family', rel.entry.name, bag
            end
        end
        return 'drop', why
    end
    local fits, usable, bag = false, false, nil
    for _, copy in ipairs(have.copies) do
        if copy_fits(item, copy) then
            fits = true
            if copy.equippable then usable = true else bag = bag or copy.bag end
        end
    end
    if fits and usable then return 'keep' end
    if fits then return 'move', bag end
    local list = {}
    for _, copy in ipairs(have.copies) do list[#list + 1] = copy_text(copy) .. (copy.equippable and '' or (' ['
        .. tostring(copy.bag) .. ']')) end
    return 'name', table.concat(list, ' | ')
end

-- templateText: an example job file. owned: { [lower item name] = { name = 'Item', copies = { { bag = 'Wardrobe',
-- equippable = true, augs = { 'STR+30', ... }, path = 'B' }, ... } } }. info: { name, job, date }. Returns the proposed
-- file's text and a report { slots, kept, dropped, renamed, moved,
-- family, missing = { {name, n}... }, move = { {name, bag}... }, modes = { modes whose weapon is not owned },
-- outside = { {name, where}... } }, or nil, why.
function gcbuild.Build(templateText, owned, info)
    info = info or {}
    local lines = {}
    for line in string.gmatch(templateText .. '\n', '(.-)\r?\n') do lines[#lines + 1] = line end
    if (lines[#lines] == '') then lines[#lines] = nil end
    local first, last = nil, nil
    for i, line in ipairs(lines) do
        if (first == nil) and (string.find(line, 'local sets = {', 1, true) ~= nil) then first = i end
        if (first ~= nil) and (string.match(line, '^profile%.Sets%s*=') ~= nil) then last = i; break end
    end
    if (first == nil) or (last == nil) then
        return nil, 'the example has no `local sets = {` ... `profile.Sets = sets` block'
    end

    local rep = { slots = 0, kept = 0, dropped = 0, renamed = 0, moved = 0, family = 0, missing = {}, move = {},
        modes = {}, outside = {} }
    local missN, moveSeen = {}, {}
    local sets, cur = {}, nil -- [lower set name] = { [slot] = verdict }, for the weapon modes below
    local function to_move(name, bag)
        rep.moved = rep.moved + 1
        local key = string.lower(name)
        if not moveSeen[key] then moveSeen[key] = true; rep.move[#rep.move + 1] = { name, bag } end
    end
    local function note(slot, verdict, item, extra, bag)
        rep.slots = rep.slots + 1
        if (cur ~= nil) then cur[slot] = verdict end
        if (verdict == 'drop') then
            rep.dropped = rep.dropped + 1
            local key = string.lower(item.name)
            if (missN[key] == nil) then missN[key] = { item.name, 0 }; rep.missing[#rep.missing + 1] = missN[key] end
            missN[key][2] = missN[key][2] + 1
        else
            rep.kept = rep.kept + 1
            if (verdict == 'name') then rep.renamed = rep.renamed + 1 end
            if (verdict == 'move') then to_move(item.name, extra) end
            if (verdict == 'family') then
                rep.family = rep.family + 1
                if (bag ~= nil) then to_move(extra, bag) end
            end
        end
    end
    local function family_note(item, bag)
        return 'example: ' .. item.name .. ((bag ~= nil) and ('; yours is in ' .. tostring(bag)
            .. ': move it to a wardrobe') or '')
    end

    local baseIndent = nil -- the indent of the set names
    local used = {} -- per set: emptied where a set opens and where one closes
    for i = first + 1, last - 1 do
        local line = lines[i]
        local indent, key, eq = string.match(line, '^(%s*)(%a+%d?)(%s*=%s*)')
        local item, nxt = nil, nil
        if (key ~= nil) and SLOTS[key] then
            item, nxt = read_item(line, #indent + #key + #eq + 1)
            -- only a comma and a comment may follow, else the line holds more than this slot (a closing brace)
            if (item ~= nil) and (string.match(string.sub(line, nxt), '^%s*,?%s*$') == nil)
                and (string.match(string.sub(line, nxt), '^%s*,?%s*%-%-') == nil) then item = nil end
        end
        if (item ~= nil) then
            -- one slot on its own line: Head = 'Nyame Helm',
            local verdict, extra, bag = judge(item, owned, used)
            note(key, verdict, item, extra, bag)
            if (verdict == 'drop') then
                lines[i] = indent .. '--' .. string.sub(line, #indent + 1) .. ' -- ' .. extra
            elseif (verdict == 'move') then
                lines[i] = line .. ' -- in ' .. tostring(extra) .. ': move it to a wardrobe'
            elseif (verdict == 'name') then
                lines[i] = indent .. key .. eq .. q(item.name) .. string.sub(line,
                    nxt) .. ' -- your augments differ from the example\'s: ' .. extra
            elseif (verdict == 'family') then
                lines[i] = indent .. key .. eq .. q(extra) .. string.sub(line, nxt) .. ' -- ' .. family_note(item, bag)
            end
        elseif (string.match(line, '^%s*%-%-') == nil) then
            -- a set's name: Idle = {  /  ['Savage Blade'] = {
            local ind, name = string.match(line, '^(%s*)([%a_][%w_]*)%s*=%s*{')
            if (name == nil) then ind, name = string.match(line, '^(%s*)%[%s*[\'"](.-)[\'"]%s*%]%s*=%s*{') end
            if (name ~= nil) then
                baseIndent = baseIndent or ind
                if (ind == baseIndent) then cur = {}; sets[string.lower(name)] = cur end
            end
            -- slots sharing a line with braces: Mp_Body = {Body = 'Seidr Cotehardie',},
            local open, close = string.find(line, '{', 1, true), string.find(line, '}', 1, true)
            if (open ~= nil) and ((close == nil) or (open < close)) then used = {} end -- a set opens here
            local out, pos, notes = {}, 1, {}
            while true do
                local s1, e1, k = string.find(line, '([%a]+%d?)%s*=%s*', pos)
                if (s1 == nil) then break end
                local it, after = nil, nil
                if SLOTS[k] and ((s1 == 1) or (string.match(string.sub(line, s1 - 1, s1 - 1), '[%w_%.]') == nil)) then
                    it, after = read_item(line, e1 + 1)
                end
                if (it == nil) then
                    out[#out + 1] = string.sub(line, pos, e1)
                    pos = e1 + 1
                else
                    local verdict, extra, bag = judge(it, owned, used)
                    note(k, verdict, it, extra, bag)
                    out[#out + 1] = string.sub(line, pos, s1 - 1)
                    local comma = string.match(line, '^%s*,%s*', after)
                    if (verdict == 'drop') then
                        notes[#notes + 1] = extra .. ': ' .. it.name
                        after = after + #(comma or '')
                    elseif (verdict == 'name') then
                        out[#out + 1] = k .. ' = ' .. q(it.name)
                        notes[#notes + 1] = it.name .. ': your augments differ from the example\'s: ' .. extra
                    elseif (verdict == 'family') then
                        out[#out + 1] = k .. ' = ' .. q(extra)
                        notes[#notes + 1] = extra .. ': ' .. family_note(it, bag)
                    else
                        out[#out + 1] = string.sub(line, s1, after - 1)
                        if (verdict == 'move') then
                            notes[#notes + 1] = it.name .. ' is in ' .. tostring(extra) .. ': move it to a wardrobe'
                        end
                    end
                    pos = after
                end
            end
            if (#notes > 0) then
                out[#out + 1] = string.sub(line, pos)
                lines[i] = table.concat(out) .. ' -- ' .. table.concat(notes, '; ')
            end
            -- the set (or an item table on its own lines) ended
            if (string.find(line, '}', 1, true) ~= nil) then used = {} end
        end
    end

    -- Outside the sets. Weapon modes: a mode whose Weapon_<mode> set lost its Main (or, with no Main, every slot)
    -- has nothing to put on; it stays in the /wm list (you may get the weapon later) and is listed at the top.
    local function quoted(str) -- every quoted string in str, in order
        local list, i = {}, 1
        while (i <= #str) do
            local c = string.sub(str, i, i)
            if (c == "'") or (c == '"') then
                local text, after = read_string(str, i)
                if (text == nil) then break end
                list[#list + 1] = text
                i = after
            elseif (string.sub(str, i, i + 1) == '--') then
                break
            else
                i = i + 1
            end
        end
        return list
    end
    local function mode_lost(mode)
        local set = sets['weapon_' .. string.lower(mode)]
        if (set == nil) or (next(set) == nil) then return false end -- no such set in the example: not judged
        if (set.Main ~= nil) then return set.Main == 'drop' end
        for _, v in pairs(set) do
            if (v ~= 'drop') then return false end
        end
        return true
    end
    local outsideText = {}
    for i, line in ipairs(lines) do
        if ((i < first) or (i > last)) and (string.match(line, '^%s*%-%-') == nil) then
            outsideText[#outsideText + 1] = line
        end
    end
    outsideText = table.concat(outsideText, '\n')
    for i = last + 1, #lines do
        local list = string.match(lines[i], '^%s*gcinclude%.WeaponModes%s*=%s*(%b{})')
        if (list ~= nil) then
            for _, m in ipairs(quoted(list)) do
                if (m ~= 'None') and mode_lost(m) then rep.modes[#rep.modes + 1] = m end
            end
        end
    end
    -- Other item names outside the sets: checked and listed, never changed.
    local seenOut = {}
    local function outside(name, where)
        local key = string.lower(name)
        if KEYWORDS[key] or (key == 'none') or (owned[key] ~= nil) or seenOut[key] then return end
        -- a slot-pick name that is a key of the job's own item map (RostamA = { Name = 'Rostam', AugPath = 'A' }): the
        -- map's item is checked instead, below
        if (string.find(outsideText, "['" .. name .. "']", 1, true) ~= nil) or (string.find(outsideText,
            '["' .. name .. '"]', 1, true) ~= nil) then
            return
        end
        if (string.match(name, '^[%a_][%w_]*$') ~= nil) and (string.find('\n' .. outsideText,
            '[^%w_]' .. name .. '%s*=%s*{') ~= nil) then
            return
        end
        seenOut[key] = true
        rep.outside[#rep.outside + 1] = { name, where }
    end
    for i, line in ipairs(lines) do
        if ((i < first) or (i > last)) and (string.match(line, '^%s*%-%-') == nil) then
            local pos = 1
            while true do
                local s1, e1, slot = string.find(line, "gFunc%.Equip%(%s*['\"](%a+%d?)['\"]%s*,%s*", pos)
                if (s1 == nil) then break end
                local name = read_string(line, e1 + 1)
                if (name ~= nil) then outside(name, 'gFunc.Equip ' .. slot) end
                pos = e1 + 1
            end
            -- gcinclude.WeaponItemMap entries: <key> = { Name = 'Item', ... }
            pos = 1
            while true do
                local s1, e1 = string.find(line, '=%s*{%s*Name%s*=%s*', pos)
                if (s1 == nil) then break end
                local name = read_string(line, e1 + 1)
                if (name ~= nil) then outside(name, 'WeaponItemMap') end
                pos = e1 + 1
            end
            local which, list = string.match(line, '^%s*gcinclude%.(%a+Modes)%s*=%s*(%b{})')
            if (which == 'MainModes') or (which == 'SubModes') or (which == 'RangeModes') or (which == 'AmmoModes') then
                for _, name in ipairs(quoted(list)) do outside(name, which) end
            end
        end
    end

    table.sort(rep.missing, function(a, b) if (a[2] ~= b[2]) then return a[2] > b[2] end return a[1] < b[1] end)
    local function wrap(head, list, fmt)
        local out, row = {}, {}
        for _, v in ipairs(list) do
            row[#row + 1] = fmt(v)
            if (#row == 5) then out[#out + 1] = '--   ' .. table.concat(row, ', '); row = {} end
        end
        if (#row > 0) then out[#out + 1] = '--   ' .. table.concat(row, ', ') end
        if (#out > 0) then table.insert(out, 1, head) end
        return out
    end
    local job = tostring(info.job or '<JOB>')
    local h = {
        '-- Proposed by /gcbuild for ' .. tostring(info.name or 'this character') .. ': GoomSwap examples/' .. job
            .. '.lua with the gear you own' .. ((info.date ~= nil) and (' (' .. info.date .. ')') or '') .. '.',
        string.format('-- %d of %d set slots kept; %d left out (not owned, or fewer copies than the set wears): commented out where', rep.kept, rep.slots, rep.dropped),
        '-- they stood, so the set under shows through.',
        string.format('-- %d kept by name only (your copy has other augments); %d are in a bag sets can\'t equip from.',
            rep.renamed, rep.moved),
    }
    h[#h + 1] = string.format('-- family: %d slots got the version of the item you own (each says which the example named).', rep.family)
    if (#rep.modes > 0) then
        h[#h + 1] = '-- Weapon modes with no weapon you own (still in /wm: fill Weapon_<mode>, or take the mode out): '
            .. table.concat(rep.modes, ', ') .. '.'
    end
    h[#h + 1] = '-- Handlers and OnLoad are the example\'s. Fill the slots left out, then /checksets.'
    for _, l in ipairs(wrap('-- Named outside the sets and not owned (change these by hand):', rep.outside,
        function(v) return v[1] .. ' (' .. v[2] .. ')' end)) do h[#h + 1] = l end
    for _, l in ipairs(wrap('-- Move to a wardrobe:', rep.move,
        function(v) return v[1] .. ' (' .. tostring(v[2]) .. ')' end)) do h[#h + 1] = l end
    for _, l in ipairs(wrap('-- Left out (slots):', rep.missing,
        function(v) return v[1] .. ' (' .. v[2] .. ')' end)) do h[#h + 1] = l end
    return table.concat(h, '\n') .. '\n' .. table.concat(lines, '\n') .. '\n', rep
end

local JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG',
    'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }
-- Every piece of equipment in every bag and on a Storage Slip, by lower-case name: the editor's bag scan
-- (gceditbags.ScanOwned, LAC's augment strings), each item's copies in the order its bags were walked.
local function owned_gear()
    local list = gFunc.LoadFile('common\\gceditbags.lua').ScanOwned()
    table.sort(list, function(a, b) return (a.order or math.huge) < (b.order or math.huge) end) -- slip copies last
    local owned = {}
    for _, g in ipairs(list) do
        local entry = owned[g.lname]
        if (entry == nil) then entry = { name = g.name, copies = {} }; owned[g.lname] = entry end
        entry.copies[#entry.copies + 1] = { augs = g.augs, path = g.path, bag = g.bag, equippable = g.equippable }
    end
    return owned
end

-- Where the examples are and where the character's job files go.
local function folders()
    local root = AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\'
    return root .. 'examples\\', string.format('%s%s_%u\\', root, gState.PlayerName, gState.PlayerId),
        gState.PlayerName, 'luashitacast\\examples\\'
end

-- args: the command's words after /gcbuild: a job.
-- say / err: gcinclude's chat lines. Returns the job when the file was written.
function gcbuild.Run(args, say, err)
    local job = nil
    for _, a in ipairs(args or {}) do
        local word = string.upper(tostring(a))
        if (word ~= 'FAMILY') then -- 'family' (older syntax): your own version of an item is always used now
            local found = nil
            for _, j in ipairs(JOBS) do
                if (j == word) then found = j end
            end
            if (found == nil) then err('/gcbuild: no job ' .. tostring(a) .. ' (usage: /gcbuild [JOB])'); return end
            job = found
        end
    end
    job = job or JOBS[AshitaCore:GetMemoryManager():GetPlayer():GetMainJob()]
    if (job == nil) then err('/gcbuild: no job yet'); return end
    local examples, dir, name, shown = folders()
    local f = io.open(examples .. job .. '.lua', 'rb')
    if (f == nil) then
        err('/gcbuild: no ' .. shown .. job .. '.lua: copy GoomSwap\'s examples folder there.')
        return
    end
    local template = f:read('*a')
    f:close()
    local text, rep = gcbuild.Build(template, owned_gear(), { name = name, job = job, date = os.date('%Y-%m-%d') })
    if (text == nil) then err('/gcbuild: ' .. tostring(rep)); return end
    local file = job .. '.proposed.lua'
    local out = io.open(dir .. file, 'wb')
    if (out == nil) then err('/gcbuild: cannot write ' .. file); return end
    out:write(text)
    out:close()
    say(string.format('%s written to your character folder: %d of %d set slots kept (%d as your own version of the item, %d by name only), %d left out, %d to move to a wardrobe%s.',
        file, rep.kept, rep.slots, rep.family, rep.renamed, rep.dropped, rep.moved,
        (#rep.modes > 0) and (', weapon modes with no weapon you own: ' .. table.concat(rep.modes, ' ')) or ''))
    return job, dir .. file, dir
end

-- /checksets: the loaded sets (profile.Sets, as LuAshitacast holds them) against the bags. An item is 'Name' or
-- { Name = , Augment = , AugPath = }; a table of sets inside a set (Buffs) is walked too. modes: the /wm list.
-- Returns { slots, missing, short, augs, bag = { { name, detail, where = { 'Set Slot'... } }... }, modes = { names } }.
local SLOT_OF = {}
for slot, _ in pairs(SLOTS) do SLOT_OF[string.lower(slot)] = slot end
function gcbuild.CheckOwned(sets, modes, owned)
    owned = owned or owned_gear()
    local res = { slots = 0, missing = {}, short = {}, augs = {}, bag = {}, modes = {} }
    local index = { missing = {}, short = {}, augs = {}, bag = {} }
    local function add(kind, name, where, detail)
        local key = string.lower(name) .. '|' .. tostring(detail or '')
        local e = index[kind][key]
        if (e == nil) then
            e = { name = name, detail = detail, where = {} }
            index[kind][key] = e
            table.insert(res[kind], e)
        end
        table.insert(e.where, where)
    end
    local function sorted_keys(t)
        local keys = {}
        for k, _ in pairs(t) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return string.lower(tostring(a)) < string.lower(tostring(b)) end)
        return keys
    end
    local function walk(setName, set, depth)
        local used = {}
        for _, k in ipairs(sorted_keys(set)) do -- A-Z: Ring1 is judged before Ring2
            local v = set[k]
            local slot = (type(k) == 'string') and SLOT_OF[string.lower(k)] or nil
            if (slot ~= nil) then
                local name = (type(v) == 'table') and (v.Name or v.name) or v
                if (type(name) == 'string') then
                    res.slots = res.slots + 1
                    local item = { name = name, augs = {}, path = (type(v) == 'table') and v.AugPath or nil }
                    local a = (type(v) == 'table') and (v.Augment or v.augments) or nil
                    if (type(a) == 'string') then
                        item.augs[1] = a
                    elseif (type(a) == 'table') then
                        for _, str in pairs(a) do
                            if (type(str) == 'string') then item.augs[#item.augs + 1] = str end
                        end
                    end
                    local verdict, extra = judge(item, owned, used, false)
                    local where = setName .. ' ' .. slot
                    if (verdict == 'drop') then add((extra == 'not owned') and 'missing' or 'short', name, where, extra)
                    elseif (verdict == 'name') then add('augs', name, where, extra)
                    elseif (verdict == 'move') then add('bag', name, where, extra) end
                end
            elseif (type(v) == 'table') and (depth < 2) then
                walk(setName .. '.' .. tostring(k), v, depth + 1)
            end
        end
    end
    local byLower = {}
    for _, name in ipairs(sorted_keys(sets)) do
        if (type(sets[name]) == 'table') then
            byLower[string.lower(tostring(name))] = sets[name]
            walk(tostring(name), sets[name], 0)
        end
    end
    for _, m in ipairs((type(modes) == 'table') and modes or {}) do
        local set = (type(m) == 'string') and byLower['weapon_' .. string.lower(m)] or nil
        if (set ~= nil) then
            for k, v in pairs(set) do
                local name = (type(v) == 'table') and (v.Name or v.name) or v
                if (type(k) == 'string') and (string.lower(k) == 'main') and (type(name) == 'string')
                    and (not KEYWORDS[string.lower(name)])
                        and (owned[string.lower(name)] == nil) then res.modes[#res.modes + 1] = m end
            end
        end
    end
    for _, kind in ipairs({ 'missing', 'short', 'augs', 'bag' }) do
        table.sort(res[kind], function(x, y)
            if (#x.where ~= #y.where) then return #x.where > #y.where end
            return x.name < y.name
        end)
    end
    return res
end

-- The lines /checksets adds about ownership. say / err: gcinclude's chat lines. At most `most` items per kind.
function gcbuild.CheckSets(sets, modes, say, err, most)
    local res = gcbuild.CheckOwned(sets, modes)
    most = most or 8
    local n = { missing = 0, short = 0, augs = 0, bag = 0 }
    for kind, _ in pairs(n) do
        for _, e in ipairs(res[kind]) do n[kind] = n[kind] + #e.where end
    end
    say(string.format('checksets, your bags: %d set slots, %d not owned, %d need a second copy, %d with other augments, %d in a bag sets can\'t equip from',
        res.slots, n.missing, n.short, n.augs, n.bag))
    local function lines(kind, label, text)
        for i, e in ipairs(res[kind]) do
            if (i > most) then
                say('... and ' .. (#res[kind] - most) .. ' more ' .. label .. ' (/checksets all lists them; /gcedit: the Missing filter)')
                break
            end
            local where = table.concat(e.where, ', ', 1,
                math.min(#e.where, 3)) .. ((#e.where > 3) and (' +' .. (#e.where - 3)) or '')
            err(label .. ': ' .. text(e) .. ' (' .. where .. ')')
        end
    end
    lines('missing', 'not owned', function(e) return e.name end)
    lines('short', 'worn twice, one copy', function(e) return e.name end)
    lines('augs', 'augments no copy has', function(e) return e.name .. ' - yours: ' .. tostring(e.detail) end)
    lines('bag', 'move to a wardrobe', function(e) return e.name .. ' [' .. tostring(e.detail) .. ']' end)
    if (#res.modes > 0) then err('weapon modes whose weapon you don\'t own: ' .. table.concat(res.modes, ', ')) end
    return res
end

return gcbuild
