-- /gcedit's controls for table values, so a list or a table is never typed as Lua: names as chips (x takes one out,
-- a box adds one), name -> value rows, Packer counts (a number, a stack, all) and keybinds (modifier ticks, a key, a
-- command). Each returns the whole new value when it changed this frame, else nil; the caller saves it. Values are
-- copied, never changed in place. No file access.
return function(imgui, palette, set_tip)
    local W = {}
    local boxes = {} -- [id] = { a = { text }, b = { text } }: the add row's boxes
    local function box(id)
        boxes[id] = boxes[id] or { a = { '' }, b = { '' } }
        return boxes[id]
    end
    local function trim(s) return (string.match(s or '', '^%s*(.-)%s*$')) end
    local function vec(a, b) -- ImGui vectors come back as two numbers or as a table, by Ashita version
        if type(a) == 'table' then return a.x or a[1] or 0, a.y or a[2] or 0 end
        return a or 0, b or 0
    end
    local function width(text)
        return (vec(imgui.CalcTextSize(text)))
    end
    -- Wrapping flow for chips: SameLine while the next one fits the row.
    local function flow_start() return { used = 0, avail = (vec(imgui.GetContentRegionAvail())) } end
    local function flow_next(f, w)
        if (f.used > 0) and (f.used + w + 8 <= f.avail) then imgui.SameLine() else f.used = 0 end
        f.used = f.used + w + 8
    end
    local function list_copy(t)
        local o = {}
        for i, v in ipairs(t or {}) do o[i] = v end
        return o
    end
    local function map_copy(t)
        local o = {}
        for k, v in pairs(t or {}) do o[k] = v end
        return o
    end
    local function sorted_keys(t)
        local out = {}
        for k in pairs(t or {}) do
            if type(k) == 'string' then out[#out + 1] = k end
        end
        table.sort(out, function(x, y) return string.lower(x) < string.lower(y) end)
        return out
    end

    -- A small dropdown: options are values or { value, label }; the pick, or nil.
    function W.Pick(id, label, options)
        if imgui.SmallButton(label .. ' v##' .. id) then imgui.OpenPopup('##pick_' .. id) end
        local out = nil
        if imgui.BeginPopup('##pick_' .. id) then
            for i, o in ipairs(options) do
                local value, text = o, tostring(o)
                if type(o) == 'table' then value, text = o[1], o[2] end
                if imgui.Selectable(text .. '##' .. id .. '_' .. i, false) then out = value end
            end
            imgui.EndPopup()
        end
        return out
    end

    -- Suggestions under an add box: up to 8 of opts.suggest(text), a click fills the box.
    local function suggestions(id, b, suggest)
        local text = trim(b.a[1])
        if (suggest == nil) or (#text < 2) then return end
        local shown = 0
        for _, name in ipairs(suggest(text) or {}) do
            if shown >= 8 then break end
            if string.lower(name) ~= string.lower(text) then
                shown = shown + 1
                if shown > 1 then imgui.SameLine() end
                if imgui.SmallButton(name .. '##sug_' .. id .. '_' .. shown) then b.a[1] = name end
            end
        end
    end

    -- A list of names. opts: hint (the add box's), suggest(text) -> names, unique (default true), width.
    function W.List(id, list, opts)
        opts = opts or {}
        local out, changed = list_copy(list), false
        local f = flow_start()
        for i, v in ipairs(list or {}) do
            local label = tostring(v) .. '  x##' .. id .. '_' .. i
            flow_next(f, width(tostring(v) .. '  x') + 8)
            if imgui.SmallButton(label) then
                table.remove(out, i)
                changed = true
            end
            if imgui.IsItemHovered() then set_tip('Take ' .. tostring(v) .. ' out.') end
        end
        if #(list or {}) == 0 then imgui.TextColored(palette.dim, '(none)') end
        local b = box(id)
        imgui.PushItemWidth(opts.width or 200)
        local enter = imgui.InputTextWithHint('##add_' .. id, opts.hint or 'add...', b.a, 96)
        imgui.PopItemWidth()
        imgui.SameLine()
        local text = trim(b.a[1])
        if (imgui.SmallButton('+ Add##' .. id) or (enter and (imgui.IsItemActive == nil))) and (text ~= '') then
            local dup = false
            if opts.unique ~= false then
                for _, v in ipairs(out) do
                    if string.lower(tostring(v)) == string.lower(text) then dup = true end
                end
            end
            if not dup then
                out[#out + 1] = text
                changed = true
            end
            b.a[1] = ''
        end
        suggestions(id, b, opts.suggest)
        return changed and out or nil
    end

    -- name -> value rows. opts: keyHint, valueHint, number (values are numbers), suggest(text) -> names.
    function W.Map(id, map, opts)
        opts = opts or {}
        local out, changed = map_copy(map), false
        for i, k in ipairs(sorted_keys(map)) do
            imgui.TextUnformatted(k)
            imgui.SameLine(opts.at or 180)
            local b = boxes[id .. '_v' .. i]
            if (b == nil) or (b.base ~= tostring(map[k])) or (b.key ~= k) then
                b = { base = tostring(map[k]), key = k, a = { tostring(map[k]) } }
                boxes[id .. '_v' .. i] = b
            end
            imgui.PushItemWidth(opts.valueWidth or 140)
            imgui.InputText('##' .. id .. '_val' .. i, b.a, 128)
            imgui.PopItemWidth()
            if trim(b.a[1]) ~= b.base then
                imgui.SameLine()
                if imgui.SmallButton('Set##' .. id .. '_set' .. i) then
                    local v = trim(b.a[1])
                    if opts.number then v = tonumber(v) end
                    if v ~= nil and v ~= '' then
                        out[k] = v
                        changed = true
                    end
                end
            end
            imgui.SameLine()
            if imgui.SmallButton('x##' .. id .. '_del' .. i) then
                out[k] = nil
                changed = true
            end
            if imgui.IsItemHovered() then set_tip('Take ' .. k .. ' out.') end
        end
        local b = box(id)
        imgui.PushItemWidth(170)
        imgui.InputTextWithHint('##' .. id .. '_newk', opts.keyHint or 'name', b.a, 96)
        imgui.PopItemWidth()
        imgui.SameLine()
        imgui.PushItemWidth(opts.valueWidth or 140)
        imgui.InputTextWithHint('##' .. id .. '_newv', opts.valueHint or 'value', b.b, 128)
        imgui.PopItemWidth()
        imgui.SameLine()
        local k, v = trim(b.a[1]), trim(b.b[1])
        if opts.number then v = tonumber(v) end
        if imgui.SmallButton('+ Add##' .. id) and (k ~= '') and (v ~= nil) and (v ~= '') then
            out[k] = v
            changed = true
            b.a[1], b.b[1] = '', ''
        end
        suggestions(id, b, opts.suggest)
        return changed and out or nil
    end

    -- == Packer: name -> count. 'map' form (char.lua: { ['Item'] = 'stack' }) or LAC's 'list' form (profile.Packer:
    -- { 'Item', { Name = 'Item', Quantity = 12 } }, where a stack is written as its size: LAC takes a number or 'all').
    -- Rows read either form; an entry with augments (a LAC table with more than Name and Quantity) is kept as it is. ==
    local function packer_rows(value)
        local rows = {}
        for k, v in pairs(value or {}) do
            if type(k) == 'string' then
                rows[#rows + 1] = { name = k, n = v }
            elseif type(v) == 'string' then
                rows[#rows + 1] = { name = v, n = 1 }
            elseif (type(v) == 'table') and (type(v.Name) == 'string') then
                local extra = false
                for f in pairs(v) do
                    if (f ~= 'Name') and (f ~= 'Quantity') then extra = true end
                end
                rows[#rows + 1] = { name = v.Name, n = v.Quantity or 1, raw = extra and v or nil }
            end
        end
        table.sort(rows, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
        return rows
    end
    local function packer_value(rows, form, stackOf)
        local out = {}
        for _, r in ipairs(rows) do
            if form == 'map' then
                out[r.name] = r.n
            elseif r.raw ~= nil then
                local e = map_copy(r.raw)
                e.Quantity = (r.n ~= 1) and r.n or nil
                out[#out + 1] = e
            else
                local n = r.n
                if (n == 'stack') or (n == true) then n = (stackOf ~= nil) and stackOf(r.name) or 1 end
                out[#out + 1] = (n == 1) and r.name or { Name = r.name, Quantity = n }
            end
        end
        return out
    end
    local function count_label(n)
        if n == 'stack' or n == true then return 'stack' end
        if n == 'all' then return 'all' end
        return tostring(n)
    end
    -- form: 'map' or 'list'. opts: suggest(text) -> item names, stackOf(name) -> its stack size.
    function W.Packer(id, value, form, opts)
        opts = opts or {}
        local rows, changed = packer_rows(value), false
        for i, r in ipairs(rows) do
            imgui.TextUnformatted(r.name .. ((r.raw ~= nil) and ' (augmented)' or ''))
            imgui.SameLine(opts.at or 200)
            local options = { { 'stack', 'a stack' }, { 'all', 'all you have' }, { 1, '1' }, { 'count', 'a count...' } }
            local pick = W.Pick(id .. '_n' .. i, count_label(r.n), options)
            if pick == 'count' then
                boxes[id .. '_c' .. i] = { a = { (type(r.n) == 'number') and tostring(r.n) or '' } }
            elseif pick ~= nil then
                r.n, changed = pick, true
            end
            local cb = boxes[id .. '_c' .. i]
            if cb ~= nil then
                imgui.SameLine()
                imgui.PushItemWidth(60)
                imgui.InputText('##' .. id .. '_cn' .. i, cb.a, 8)
                imgui.PopItemWidth()
                imgui.SameLine()
                local n = tonumber(trim(cb.a[1]))
                if imgui.SmallButton('Set##' .. id .. '_cs' .. i) and (n ~= nil) and (n > 0) then
                    r.n, changed = math.floor(n), true
                    boxes[id .. '_c' .. i] = nil
                end
            end
            imgui.SameLine()
            if imgui.SmallButton('x##' .. id .. '_x' .. i) then
                r.gone, changed = true, true
            end
            if imgui.IsItemHovered() then set_tip('Take ' .. r.name .. ' out of the list.') end
        end
        if #rows == 0 then imgui.TextColored(palette.dim, '(none)') end
        local b = box(id)
        imgui.PushItemWidth(220)
        imgui.InputTextWithHint('##' .. id .. '_new', 'item name, as the game shows it', b.a, 96)
        imgui.PopItemWidth()
        imgui.SameLine()
        local name = trim(b.a[1])
        if imgui.SmallButton('+ Add##' .. id) and (name ~= '') then
            local dup = false
            for _, r in ipairs(rows) do
                if string.lower(r.name) == string.lower(name) then dup = true end
            end
            local real = (opts.known == nil) and name or opts.known(name) -- the game's spelling, nil: no such item
            if real == nil then
                b.err = 'No item is named ' .. name .. '.'
            elseif not dup then
                rows[#rows + 1] = { name = real, n = (form == 'map') and 'stack' or 1 }
                b.a[1], b.err, changed = '', nil, true
            else
                b.a[1], b.err = '', nil
            end
        end
        if b.err ~= nil then imgui.TextColored(palette.warn, b.err) end
        suggestions(id, b, opts.suggest)
        if not changed then return nil end
        local keep = {}
        for _, r in ipairs(rows) do
            if not r.gone then keep[#keep + 1] = r end
        end
        return packer_value(keep, form, opts.stackOf)
    end

    -- == Keybinds: { { key, command } }. A key is modifiers (^ Ctrl, ! Alt, + Shift, @ Win) and a key name. ==
    local MODS = { { '^', 'Ctrl' }, { '!', 'Alt' }, { '+', 'Shift' }, { '@', 'Win' } }
    local KEYS = {}
    for i = 1, 12 do KEYS[#KEYS + 1] = 'F' .. i end
    for c in string.gmatch('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.') do KEYS[#KEYS + 1] = c end
    for i = 0, 9 do KEYS[#KEYS + 1] = tostring(i) end -- the keys GoomSwap's own binds use; others: /gckey
    W.KEYS = KEYS
    function W.KeyText(key) -- '^!F1' -> 'Ctrl+Alt+F1'
        local mods, rest = string.match(key or '', '^([%^!%+@#]*)(.*)$')
        local out = {}
        for _, m in ipairs(MODS) do
            if string.find(mods or '', m[1], 1, true) then out[#out + 1] = m[2] end
        end
        if string.find(mods or '', '#', 1, true) then out[#out + 1] = 'Apps' end
        out[#out + 1] = rest
        return table.concat(out, '+')
    end
    function W.Keybinds(id, list)
        local out, changed = {}, false
        for i, b in ipairs(list or {}) do
            out[i] = { b[1], b[2] }
            imgui.TextUnformatted(W.KeyText(b[1]))
            imgui.SameLine(130)
            imgui.TextUnformatted(tostring(b[2]))
            imgui.SameLine()
            if imgui.SmallButton('x##' .. id .. '_x' .. i) then out[i], changed = false, true end
            if imgui.IsItemHovered() then set_tip('Unbind ' .. W.KeyText(b[1]) .. '.') end
        end
        if #(list or {}) == 0 then imgui.TextColored(palette.dim, '(no keys bound)') end
        local b = box(id)
        b.mods = b.mods or {}
        b.key = b.key or 'F1'
        for _, m in ipairs(MODS) do
            b.mods[m[1]] = b.mods[m[1]] or { false }
            imgui.Checkbox(m[2] .. '##' .. id .. '_m' .. m[1], b.mods[m[1]])
            imgui.SameLine()
        end
        local pick = W.Pick(id .. '_key', b.key, KEYS)
        if pick ~= nil then b.key = pick end
        imgui.SameLine()
        imgui.PushItemWidth(220)
        imgui.InputTextWithHint('##' .. id .. '_cmd', 'wm, or /ma "Cure IV" <stpc>', b.a, 128)
        imgui.PopItemWidth()
        imgui.SameLine()
        local cmd = trim(b.a[1])
        if imgui.SmallButton('+ Bind##' .. id) and (cmd ~= '') then
            local key = ''
            for _, m in ipairs(MODS) do
                if b.mods[m[1]][1] then key = key .. m[1] end
            end
            key = key .. b.key
            for i, e in ipairs(out) do
                if e and (e[1] == key) then out[i] = false end -- one command per key
            end
            out[#out + 1] = { key, cmd }
            b.a[1], changed = '', true
        end
        if imgui.IsItemHovered() then
            set_tip('A GoomSwap command without the slash (wm, mset acc) or any chat command (/ja "Provoke" <t>).')
        end
        if not changed then return nil end
        local keep = {}
        for _, e in ipairs(out) do
            if e then keep[#keep + 1] = e end
        end
        return keep
    end

    W.PackerRows, W.PackerValue = packer_rows, packer_value -- for tests
    return W
end
