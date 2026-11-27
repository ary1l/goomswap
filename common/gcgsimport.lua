-- /gcimport: a Windower GearSwap job file's sets, as a GoomSwap job file draft. The file is parsed (gcconvert's Lua
-- parser) and its set assignments evaluated as data: tables, set_combine(...), names it set earlier (gear.X,
-- locals), string joins. Nothing in it runs, and its logic (states, functions, binds) is not imported: that is for
-- /gcedit's Rules.
--
-- GearSwap's own rules, from its source (addons/GearSwap): a slot key is any case of main sub range/ranged ammo head
-- body hands legs feet neck waist back, ear1/left_ear/learring/lear, ear2/right_ear/rearring/rear,
-- ring1/left_ring/lring, ring2/right_ring/rring (statics.lua slot_map; user_key_filter lowercases); an item is a name
-- or { name, augments | augment, priority, bag } (equip_processing.lua expand_entry); set_combine(a, b, ...) is the
-- slots of each in turn (helper_functions.lua set_merge); `empty` takes a slot off.
-- Set names follow Mote's include where GoomSwap has the same idea (sets.engaged.Acc -> Tp_Acc, sets.precast.WS
-- ['Savage Blade'] -> ['Savage Blade'], sets.midcast.RA -> Midshot ...); anything else keeps its path, joined by _.
local G = {}
local C = gFunc.LoadFile('common\\gcconvert.lua')

local SLOT = {
    main = 'Main', sub = 'Sub', range = 'Range', ranged = 'Range', ammo = 'Ammo', head = 'Head', body = 'Body',
    hands = 'Hands', legs = 'Legs', feet = 'Feet', neck = 'Neck', waist = 'Waist', back = 'Back',
    ear1 = 'Ear1', left_ear = 'Ear1', learring = 'Ear1', lear = 'Ear1',
    ear2 = 'Ear2', right_ear = 'Ear2', rearring = 'Ear2', rear = 'Ear2',
    ring1 = 'Ring1', left_ring = 'Ring1', lring = 'Ring1', ring2 = 'Ring2', right_ring = 'Ring2', rring = 'Ring2',
}
G.SLOT = SLOT
local SCREEN = { 'Main', 'Sub', 'Range', 'Ammo', 'Head', 'Neck', 'Ear1', 'Ear2', 'Body', 'Hands', 'Ring1', 'Ring2',
    'Back', 'Waist', 'Legs', 'Feet' }
local EMPTY = setmetatable({}, { __tostring = function() return 'empty' end })
local SET = {} -- marks a table a set_combine made (its slot keys already GoomSwap's)

local function slot_of(k) return (type(k) == 'string') and SLOT[string.lower(k)] or nil end

-- == Evaluation: values as data ==
local function evaluator()
    local env = { sets = {}, gear = {}, empty = EMPTY, player = {}, state = {}, buffactive = {}, world = {}, info = {},
        res = {}, windower = {}, options = {} }
    local unknown = {}
    local eval
    local function combine(args)
        local out = { [SET] = true }
        for _, t in ipairs(args) do
            if type(t) == 'table' then
                for k, v in pairs(t) do
                    local s = (k ~= SET) and (t[SET] and k or slot_of(k)) or nil
                    if s ~= nil then out[s] = v end
                end
            end
        end
        return out
    end
    eval = function(e)
        if e == nil then return nil end
        local k = e.k
        if k == 'str' or k == 'num' or k == 'bool' then return e.v end
        if k == 'nil' then return nil end
        if k == 'paren' then return eval(e.a) end
        if k == 'table' then
            local t = {}
            for i, x in ipairs(e.items) do t[i] = eval(x) end
            for name, x in pairs(e.fields) do t[name] = eval(x) end
            return t
        end
        if k == 'name' then return env[e.v] end
        if k == 'index' then
            local base = eval(e.obj)
            local key = eval(e.key)
            if (type(base) == 'table') and (key ~= nil) then return base[key] end
            return nil
        end
        if k == 'bin' and e.op == '..' then
            local a, b = eval(e.a), eval(e.b)
            if (type(a) == 'string' or type(a) == 'number') and (type(b) == 'string' or type(b) == 'number') then
                return tostring(a) .. tostring(b)
            end
            return nil
        end
        if k == 'call' and e.method == nil then
            local fn = (e.fn.k == 'name') and e.fn.v or nil
            if fn == 'set_combine' then
                local args = {}
                for i, a in ipairs(e.args) do args[i] = eval(a) end
                return combine(args)
            end
            if (fn == 'T') or (fn == 'S') or (fn == 'L') then return eval(e.args[1]) end
            unknown[#unknown + 1] = fn or 'a call'
            return nil
        end
        return nil
    end
    local function assign(target, v)
        if target.k == 'name' then
            env[target.v] = v
        elseif target.k == 'index' then
            local base = eval(target.obj)
            if (type(base) ~= 'table') and (target.obj.k == 'index' or target.obj.k == 'name') then
                base = {}
                assign(target.obj, base) -- sets.precast.WS = sets.precast.WS or {}: made on the way
            end
            local key = eval(target.key)
            if (type(base) == 'table') and (key ~= nil) then base[key] = v end
        end
    end
    local walk
    walk = function(list)
        for _, st in ipairs(list or {}) do
            if st.k == 'local' then
                for i, name in ipairs(st.names) do env[name] = eval(st.exprs[i]) end
            elseif st.k == 'assign' then
                for i, t in ipairs(st.targets) do
                    local x = st.exprs[i]
                    if (x ~= nil) and (x.k == 'func') then
                        walk(x.body) -- a function's assignments, in the order it was defined
                    else
                        local v = eval(x)
                        -- sets.x = sets.x or {}: keep what is there
                        if (v == nil) and (x ~= nil) and (x.k == 'bin') and (x.op == 'or') then v = eval(x.a) or eval(x.b) end
                        assign(t, v)
                    end
                end
            elseif st.k == 'localfunc' then
                walk(st.body)
            elseif st.k == 'if' then
                for _, br in ipairs(st.branches) do walk(br.body) end
                walk(st.elseBody)
            elseif (st.k == 'loop') or (st.k == 'do') then
                walk(st.body)
            end
        end
    end
    return env, walk, unknown
end

-- == Names ==
G.MODE_WORDS = {}
for w in string.gmatch('Normal Acc MidAcc HighAcc FullAcc SomeAcc LowAcc Mod Att Crit Hybrid PDT DT MDT Low Mid High '
    .. 'Proc Fodder Resistant Dark Light SubtleBlow STP Tank', '%S+') do G.MODE_WORDS[string.lower(w)] = true end
local function join(list, from)
    local out = {}
    for i = from, #list do out[#out + 1] = tostring(list[i]) end
    return table.concat(out, '_')
end
-- path: { 'precast', 'WS', 'Savage Blade' }. A GoomSwap set name, or { buff = 'Haste' } for Buffs['Haste'].
function G.Name(path)
    local a, b = path[1], path[2]
    local la, lb = string.lower(tostring(a or '')), string.lower(tostring(b or ''))
    local rest3 = (#path >= 3) and join(path, 3) or nil
    local function with(base, from)
        local r = (#path >= from) and join(path, from) or nil
        return (r ~= nil) and (base .. '_' .. r) or base
    end
    if la == 'precast' then
        if #path == 1 then return 'Precast' end
        if lb == 'fc' then
            if #path == 2 then return 'Precast' end
            return rest3 .. '_Precast'
        end
        if lb == 'ja' then return (#path >= 3) and rest3 or 'JA' end
        if lb == 'ws' then
            if #path == 2 then return 'Ws_Default' end
            if G.MODE_WORDS[string.lower(tostring(path[3]))] then return 'Ws_' .. rest3 end
            return rest3
        end
        if lb == 'ra' then return with('Preshot', 3) end
        if lb == 'corsairroll' then return (#path >= 3) and rest3 or 'Phantom Roll' end
        if lb == 'corsairshot' then return with('Quick Draw', 3) end
        return with(tostring(b), 3) .. '_Precast'
    end
    if la == 'midcast' then
        if #path == 1 then return 'Midcast' end
        if lb == 'fastrecast' then return with('Midcast', 3) end
        if lb == 'ra' then return with('Midshot', 3) end
        return join(path, 2)
    end
    if la == 'idle' then
        if #path == 1 then return 'Idle' end
        if lb == 'town' then return with('Town', 3) end
        return 'Idle_' .. join(path, 2)
    end
    if la == 'resting' then return with('Resting', 2) end
    if la == 'engaged' then
        if #path == 1 then return 'Tp_Default' end
        return 'Tp_' .. join(path, 2)
    end
    if la == 'defense' then
        if lb == 'pdt' or lb == 'dt' then return with('Dt', 3) end
        if lb == 'mdt' then return with('mdt', 3) end
        return 'Dt_' .. join(path, 2)
    end
    if la == 'kiting' then return 'Movement' end
    if (la == 'treasurehunter') or (la == 'th') then return 'TH' end
    if la == 'buff' and #path >= 2 then
        if lb == 'doom' then return 'Doomed' end
        if lb == 'sleep' then return 'Sleeping' end
        return { buff = join(path, 2) }
    end
    return join(path, 1)
end

-- An item as LAC takes it: 'Name', { Name, Augment, Priority }, 'remove' for empty; nil and why when it isn't one.
function G.Item(v)
    if v == EMPTY then return 'remove' end
    if type(v) == 'string' then
        if string.lower(v) == 'empty' then return 'remove' end
        return v
    end
    if (type(v) == 'table') and (type(v.name) == 'string') then
        local out = { Name = v.name }
        if type(v.augments) == 'table' then
            local augs = {}
            for _, x in ipairs(v.augments) do if type(x) == 'string' then augs[#augs + 1] = x end end
            if #augs > 0 then out.Augment = augs end
        elseif type(v.augment) == 'string' then
            out.Augment = { v.augment }
        end
        if type(v.priority) == 'number' then out.Priority = v.priority end
        if (out.Augment == nil) and (out.Priority == nil) then return v.name end
        return out
    end
    return nil, 'not an item'
end

-- text: the GearSwap file. { sets = { [name] = set }, order = { names }, buffs = { [buff] = set }, notes = { lines } }.
function G.Import(text)
    local chunk, err = C.Parse(text)
    if chunk == nil then return nil, 'the file does not parse: ' .. tostring(err) end
    local env, walk, unknown = evaluator()
    walk(chunk)
    local out = { sets = {}, order = {}, buffs = {}, buffOrder = {}, notes = {}, from = {} }
    local seen = {}
    local function visit(t, path)
        if seen[t] then return end
        seen[t] = true
        local set, any = {}, false
        for k, v in pairs(t) do
            local s = (k ~= SET) and (t[SET] and k or slot_of(k)) or nil
            if s ~= nil then
                local item, why = G.Item(v)
                if item ~= nil then
                    set[s], any = item, true
                elseif v ~= nil then
                    out.notes[#out.notes + 1] = 'sets.' .. table.concat(path, '.') .. ' ' .. s .. ': ' .. why .. ' (left out)'
                end
            end
        end
        if any and (#path > 0) then
            local name = G.Name(path)
            if type(name) == 'table' then
                if out.buffs[name.buff] == nil then out.buffOrder[#out.buffOrder + 1] = name.buff end
                out.buffs[name.buff] = set
            else
                local base, n = name, 1
                while out.sets[name] ~= nil do
                    n = n + 1
                    name = base .. '_' .. n
                end
                if n > 1 then
                    out.notes[#out.notes + 1] = 'sets.' .. table.concat(path, '.') .. ' -> ' .. name .. ' (' .. base
                        .. ' was taken by sets.' .. out.from[base] .. ')'
                end
                out.sets[name], out.order[#out.order + 1], out.from[name] = set, name, table.concat(path, '.')
            end
        end
        local keys = {}
        for k, v in pairs(t) do
            if (k ~= SET) and (type(v) == 'table') and (slot_of(k) == nil) and (type(k) == 'string') then keys[#keys + 1] = k end
        end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local p = {}
            for i, x in ipairs(path) do p[i] = x end
            p[#p + 1] = k
            visit(t[k], p)
        end
    end
    -- in the order the file names them (sets.precast before sets.midcast...)
    local tops, at = {}, {}
    for name in pairs(env.sets) do
        if type(name) == 'string' then
            tops[#tops + 1] = name
            at[name] = string.find(text, 'sets%.' .. name:gsub('%p', '%%%0')) or string.find(text, name, 1, true) or 1e9
        end
    end
    table.sort(tops, function(a, b) if at[a] ~= at[b] then return at[a] < at[b] end return a < b end)
    for _, name in ipairs(tops) do
        if type(env.sets[name]) == 'table' then visit(env.sets[name], { name }) end
    end
    if #unknown > 0 then
        local names, s = {}, {}
        for _, u in ipairs(unknown) do if not s[u] then s[u], names[#names + 1] = true, u end end
        out.notes[#out.notes + 1] = 'values from code left out: ' .. table.concat(names, ', ')
    end
    return out
end

-- == Writing ==
-- A set as Lua text (one line), slots in the equipment screen's order.
function G.SetText(set, quote, key)
    local parts = {}
    for _, s in ipairs(SCREEN) do
        local v = set[s]
        if v ~= nil then
            local val
            if type(v) == 'string' then
                val = quote(v)
            else
                local f = { 'Name = ' .. quote(v.Name) }
                if v.Augment ~= nil then
                    local a = {}
                    for _, x in ipairs(v.Augment) do a[#a + 1] = quote(x) end
                    f[#f + 1] = 'Augment = { ' .. table.concat(a, ', ') .. ' }'
                end
                if v.Priority ~= nil then f[#f + 1] = 'Priority = ' .. tostring(v.Priority) end
                val = '{ ' .. table.concat(f, ', ') .. ' }'
            end
            parts[#parts + 1] = s .. ' = ' .. val
        end
    end
    return '{ ' .. table.concat(parts, ', ') .. ' }'
end

-- template: the job's example (its handlers and options are kept; its sets are replaced). The draft's text, and
-- counts { sets, empty, buffs }.
function G.Draft(template, imported, info, setFile)
    local model, err = setFile.Parse(template)
    if model == nil then return nil, err end
    local quote, key = setFile.QuoteText, setFile.FormatKey
    local lines, done, counts = {}, {}, { sets = 0, empty = 0, buffs = 0 }
    lines[#lines + 1] = '{'
    for _, set in ipairs(model.list) do
        if (set.parentName == nil) and not done[set.name] then
            done[set.name] = true
            if (set.name == 'Buffs') then
                lines[#lines + 1] = '    Buffs = { -- while the buff is up: idle and engaged'
                for _, b in ipairs(imported.buffOrder) do
                    lines[#lines + 1] = '        ' .. key(b) .. ' = ' .. G.SetText(imported.buffs[b], quote, key) .. ','
                    counts.buffs = counts.buffs + 1
                end
                lines[#lines + 1] = '    },'
            elseif imported.sets[set.name] ~= nil then
                lines[#lines + 1] = '    ' .. key(set.name) .. ' = ' .. G.SetText(imported.sets[set.name], quote, key)
                    .. ', -- sets.' .. imported.from[set.name]
                counts.sets = counts.sets + 1
            elseif string.match(set.name, '^Buffs_') then
                lines[#lines + 1] = '    ' .. key(set.name) .. ' = {},'
            else
                lines[#lines + 1] = '    ' .. key(set.name) .. ' = {}, -- not in the GearSwap file'
                counts.empty = counts.empty + 1
            end
        end
    end
    local extra = {}
    for _, name in ipairs(imported.order) do
        if not done[name] then extra[#extra + 1] = name end
    end
    if #extra > 0 then
        lines[#lines + 1] = ''
        lines[#lines + 1] = '    -- From the GearSwap file, by names this example has no set for (rename them in /gcedit):'
        for _, name in ipairs(extra) do
            lines[#lines + 1] = '    ' .. key(name) .. ' = ' .. G.SetText(imported.sets[name], quote, key) .. ', -- sets.'
                .. imported.from[name]
            counts.sets = counts.sets + 1
        end
    end
    if (not done.Buffs) and (#imported.buffOrder > 0) then
        lines[#lines + 1] = '    Buffs = {'
        for _, b in ipairs(imported.buffOrder) do
            lines[#lines + 1] = '        ' .. key(b) .. ' = ' .. G.SetText(imported.buffs[b], quote, key) .. ','
            counts.buffs = counts.buffs + 1
        end
        lines[#lines + 1] = '    },'
    end
    lines[#lines + 1] = '}'
    local head = { '-- Imported from ' .. tostring(info.file) .. ' (GearSwap) by /gcimport on ' .. tostring(info.date) .. ': '
        .. counts.sets .. ' sets, ' .. counts.buffs .. ' buff sets. Its logic (states, functions, binds) is not',
        '-- imported: add what you need as rules in /gcedit (RULES). Sets this example has and the file did not are empty.' }
    for _, n in ipairs(imported.notes) do head[#head + 1] = '-- ' .. n end
    local text = table.concat(head, '\n') .. '\n' .. string.sub(template, 1, model.open - 1)
        .. table.concat(lines, '\n') .. string.sub(template, model.close + 1)
    return text, counts
end

-- == /gcimport <file> [JOB] ==
local JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN',
    'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }
local IS_JOB = {}
for i, j in ipairs(JOBS) do IS_JOB[j] = i end
-- The job a file is for: Name_WAR.lua, WAR.lua, war_gear.lua...
function G.JobOf(file)
    local base = string.upper(string.match(file or '', '([^\\/]+)$') or '')
    for word in string.gmatch(base, '%u+') do
        if IS_JOB[word] then return word end
    end
    return nil
end
-- args: the command's words after /gcimport. Writes <JOB>.proposed.lua in the character's folder (as /gcbuild does).
-- Returns the job, the draft's path and the folder when it was written.
function G.Run(args, say, err, setFile)
    local words = {}
    for _, a in ipairs(args or {}) do words[#words + 1] = tostring(a) end
    local job = nil
    if (#words > 1) and IS_JOB[string.upper(words[#words])] then job = string.upper(table.remove(words)) end
    local name = table.concat(words, ' ')
    if name == '' then
        err('/gcimport <file> [JOB]: a GearSwap job file. Put it in your character\'s luashitacast folder (or give '
            .. 'its whole path): /gcimport Name_WAR.lua')
        return
    end
    if not string.match(name, '%.lua$') then name = name .. '.lua' end
    local root = AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\'
    local dir = string.format('%s%s_%u\\', root, gState.PlayerName, gState.PlayerId)
    local tries = string.match(name, '^%a:[\\/]') and { name } or { dir .. name, root .. name, root .. 'gearswap\\' .. name }
    local f, path = nil, nil
    for _, p in ipairs(tries) do
        f = io.open(p, 'rb')
        if f ~= nil then path = p break end
    end
    if f == nil then err('/gcimport: no ' .. name .. ' in your character\'s folder or luashitacast\\.') return end
    local text = f:read('*a')
    f:close()
    job = job or G.JobOf(name) or JOBS[AshitaCore:GetMemoryManager():GetPlayer():GetMainJob()]
    if job == nil then err('/gcimport: which job? /gcimport ' .. name .. ' WAR') return end
    local imported, why = G.Import(text)
    if imported == nil then err('/gcimport: ' .. tostring(why)) return end
    if #imported.order + #imported.buffOrder == 0 then err('/gcimport: no sets found in ' .. name .. '.') return end
    local ef = io.open(root .. 'examples\\' .. job .. '.lua', 'rb')
    if ef == nil then err('/gcimport: no luashitacast\\examples\\' .. job .. '.lua: copy GoomSwap\'s examples folder there.') return end
    local template = ef:read('*a')
    ef:close()
    local draft, counts = G.Draft(template, imported, { file = string.match(path, '[^\\/]+$'), date = os.date('%Y-%m-%d') }, setFile)
    if draft == nil then err('/gcimport: ' .. tostring(counts)) return end
    local file = job .. '.proposed.lua'
    local out = io.open(dir .. file, 'wb')
    if out == nil then err('/gcimport: cannot write ' .. file) return end
    out:write(draft)
    out:close()
    say(string.format('%s written from %s: %d sets, %d buff sets%s. Its GearSwap logic is not imported: add rules in /gcedit.',
        file, name, counts.sets, counts.buffs, (#imported.notes > 0) and (' (' .. #imported.notes .. ' notes at its top)') or ''))
    return job, dir .. file, dir
end

return G
