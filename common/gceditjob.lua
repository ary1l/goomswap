-- /gcedit: the job file read as text: handler references, conditions and modes. Job code is never executed.
-- Read handler references and conditions as text. Job code is never executed.
-- Dependencies: buff-name lookup and the engine's job-specific lists/settings.
local analysis = {}
function analysis.New(options)
    local gearEngine = options.engine
    local HANDLER_EVENT = {
        HandleDefault = 'Default',
        HandlePrecast = 'Precast',
        HandleMidcast = 'Midcast',
        HandleAbility = 'Ability',
        HandleWeaponskill = 'Weaponskill',
        HandlePreshot = 'Preshot',
        HandleMidshot = 'Midshot',
        HandleItem = 'Item',
    }
    local KEYWORD = {
        ['if'] = true,
        ['then'] = true,
        ['elseif'] = true,
        ['else'] = true,
        ['end'] = true,
        ['do'] = true,
        ['function'] = true,
        ['repeat'] = true,
        ['until'] = true,
    }

    local function masked(s) -- string contents blanked (same length), so words and brackets inside them don't count
        s = string.gsub(s, '\\.', '__')
        s = string.gsub(s, "'[^']*'", function(x) return "'" .. string.rep('_', #x - 2) .. "'" end)
        return (string.gsub(s, '"[^"]*"', function(x) return '"' .. string.rep('_', #x - 2) .. '"' end))
    end

    local function close_paren(m, open) -- the ')' that closes the '(' at open, in a masked text
        local depth = 0
        for i = open, #m do
            local c = string.sub(m, i, i)
            if c == '(' then
                depth = depth + 1
            elseif c == ')' then
                depth = depth - 1
                if depth == 0 then return i end
            end
        end
        return nil
    end

    local function trim(s)
        return (string.match(s or '', '^%s*(.-)%s*$'))
    end

    local function unwrap(s) -- '((a and b))' -> 'a and b'
        s = trim(s)
        while (string.sub(s, 1, 1) == '(') and (close_paren(masked(s), 1) == #s) do
            s = trim(string.sub(s, 2, -2))
        end
        return s
    end

    local function split_top(s, sep) -- s split at each top-level sep ('and', 'or' as words; ',')
        local m, parts, depth, last, i = masked(s), {}, 0, 1, 1
        local word = string.match(sep, '^%a+$') ~= nil
        while i <= #m do
            local c = string.sub(m, i, i)
            if (c == '(') or (c == '{') then
                depth = depth + 1
            elseif (c == ')') or (c == '}') then
                depth = depth - 1
            elseif (depth == 0) and (string.sub(m, i,
                i + #sep - 1) == sep) and ( not word or ( not string.match(string.sub(m, i - 1, i - 1),
                '[%w_]') and not string.match(string.sub(m, i + #sep, i + #sep), '[%w_]') ) ) then
                parts[#parts + 1] = string.sub(s, last, i - 1)
                last = i + #sep
                i = last - 1
            end
            i = i + 1
        end
        parts[#parts + 1] = string.sub(s, last)
        return parts
    end

    local TOGGLE_TEXT = {
        DTset = 'DT mode',
        MDTset = 'MDT mode',
        Aminon = 'Aminon mode',
        Kite = 'kite mode',
        PROC = 'proc mode',
        TH = 'TH mode',
        SIR = 'SIR mode',
        Burst = 'burst mode',
        Death = 'death mode',
        String = 'harp mode',
        SongLock = 'song lock',
    }
    local CYCLE_TEXT = {
        NukeSet = 'nuke mode',
        Weapon = 'weapon',
        Weapons = 'weapon mode',
        PupMode = 'pup mode',
        TankSet = 'tank mode',
        Hoxne = 'Hoxne',
    }
    local ACTION_VAR = { ws = true, spell = true, ability = true, action = true }
    local GUARD = {
        target = true,
        player = true,
        spell = true,
        ws = true,
        ability = true,
        action = true,
        me = true,
        env = true,
    }
    local STATUS_TEXT = { Engaged = 'engaged', Idle = 'idle', Resting = 'resting' }

    local function buff_text(arg)
        local lit = string.match(trim(arg), "^'(.-)'$")
        if lit ~= nil then return lit end
        local id = tonumber(arg)
        if id ~= nil then
            local n = options.buffName(id)
            return ((type(n) == 'string') and (n ~= '')) and (string.gsub(n, '%z+$', '')) or ('buff ' .. id)
        end
        return trim(arg)
    end

    local WS_TEXT = { low = 'WS low-buff mode', high = 'WS high-buff mode', pdl = 'WS PDL mode', acc = 'WS acc mode',
        subtleblow = 'WS subtle blow mode' } -- gceditinspect WS_COND reads these back
    local function cycle_text(name, v)
        if name == 'MeleeSet' then return 'melee mode ' .. v end
        if name == 'WsSet' then return WS_TEXT[string.lower(v)] or ('WS mode ' .. v) end
        if name == 'IdleSet' then return 'idle mode ' .. v end
        return (CYCLE_TEXT[name] or name) .. ' ' .. v
    end

    local function in_list(list, name) -- a T{...} or a plain list, matched without case
        if (type(list) ~= 'table') or (name == nil) then return nil end
        for _, v in pairs(list) do
            if (type(v) == 'string') and (string.lower(v) == string.lower(name)) then return true end
        end
        return false
    end

    -- ctx: the action looked at { status (Default: 'Idle' / 'Engaged' / 'Resting', nil = either), action, skill, family
    -- };
    -- vars: the handler's locals the conditions read. A verdict: true / false / nil (depends on the moment), and words.
    local eval_cond
    local function eval_atom(a, ctx, vars)
        a = unwrap(a)
        local inner = string.match(a, '^not%s+(.+)$')
        if inner ~= nil then
            local v, t = eval_cond(inner, ctx, vars)
            if v ~= nil then return not v, {} end
            return nil, { 'not ' .. table.concat(t, ' + ') }
        end
        local cmp = function(op, eq)
            if op == '==' then return eq end
            return not eq
        end
        -- buffs: gcinclude.BuffCount('X') > 0, or a local that holds it (local sa = gcinclude.BuffCount('Sneak
        -- Attack'))
        local arg, op, n = string.match(a, '^gcinclude%.BuffCount%((.-)%)%s*([<>=~]+)%s*(%d+)$')
        local buff = (arg ~= nil) and buff_text(arg) or nil
        if buff == nil then
            local var
            var, op, n = string.match(a, '^([%a_][%w_]*)%s*([<>=~]+)%s*(%d+)$')
            if (var ~= nil) and (vars[var] ~= nil) then buff = vars[var].buff end
        end
        if buff ~= nil then
            n = tonumber(n)
            if ((op == '>') and (n == 0)) or ((op == '>=') and (n == 1)) or ((op == '~=') and (n == 0)) then
                return nil, { buff .. ' up' }
            end
            if ((op == '==') and (n == 0)) or ((op == '<') and (n == 1)) or ((op == '<=') and (n == 0)) then
                return nil, { buff .. ' not up' }
            end
        end
        local tname, top, tval = string.match(a, "^gcdisplay%.GetToggle%('(%w+)'%)%s*([=~]=)%s*(%a+)$")
        if (tname ~= nil) or string.match(a, "^gcdisplay%.GetToggle%('(%w+)'%)$") then
            tname = tname or string.match(a, "^gcdisplay%.GetToggle%('(%w+)'%)$")
            local on = (top == nil) or cmp(top, tval == 'true')
            local t = TOGGLE_TEXT[tname] or (tname .. ' on')
            return nil, { on and t or ('not ' .. t) }
        end
        local cname, cop, cval = string.match(a, "^gcdisplay%.GetCycle%('(%w+)'%)%s*([=~]=)%s*'(.-)'$")
        if cname == nil then
            local var
            var, cop, cval = string.match(a, "^([%a_][%w_]*)%s*([=~]=)%s*'(.-)'$")
            if (var ~= nil) and (vars[var] ~= nil) and (vars[var].cycle ~= nil) then cname = vars[var].cycle end
            if (var ~= nil) and (vars[var] ~= nil) and vars[var].family then
                if ctx.family ~= nil then return cmp(cop, string.lower(ctx.family) == string.lower(cval)), {} end
                return nil, { (cop == '==') and (cval .. ' spells') or ('not ' .. cval) }
            end
        end
        if cname ~= nil then
            local t = cycle_text(cname, cval)
            return nil, { (cop == '==') and t or ('not ' .. t) }
        end
        local pop, pval = string.match(a, "^pet%.Status%s*([=~]=)%s*'(%a+)'$")
        if pop ~= nil then
            return nil, { ((pop == '==') and 'pet ' or 'pet not ') .. (STATUS_TEXT[pval] or string.lower(pval)) }
        end
        local sop, sval = string.match(a, "^player%.Status%s*([=~]=)%s*'(%a+)'$")
        if sop == nil then sop, sval = string.match(a, "^gData%.GetPlayer%(%)%.Status%s*([=~]=)%s*'(%a+)'$") end
        if sop ~= nil then
            if ctx.status ~= nil then return cmp(sop, ctx.status == sval), {} end
            local t = STATUS_TEXT[sval] or string.lower(sval)
            return nil, { (sop == '==') and t or ('not ' .. t) }
        end
        if string.match(a, 'IsMoving%s*==%s*true$') or string.match(a, 'IsMoving$') then return nil, { 'moving' } end
        local avar, aop, aval = string.match(a, "^([%a_]+)%.Name%s*([=~]=)%s*'(.-)'$")
        if (avar ~= nil) and ACTION_VAR[avar] then
            if ctx.action ~= nil then return cmp(aop, string.lower(ctx.action) == string.lower(aval)), {} end
            return nil, { ((aop == '==') and 'only ' or 'not ') .. aval }
        end
        local mop, who = string.match(a, '^target%.Name%s*([=~]=)%s*(.+)$')
        if (mop ~= nil) and ((who == 'me') or (who == 'player.Name') or (who == 'gData.GetPlayer().Name')) then
            return nil, { (mop == '==') and 'cast on yourself' or 'cast on someone else' }
        end
        local nv, nop = string.match(a, '^([%a_]+)%s*([=~]=)%s*nil$')
        if nv == 'pet' then return nil, { (nop == '~=') and 'pet out' or 'no pet' } end
        if nv == 'petAction' then return nil, { (nop == '~=') and 'pet using an ability' or 'pet not acting' } end
        if (nv ~= nil) and (nop == '~=') and GUARD[nv] then
            return true, {}
        end -- target ~= nil: a guard, not a circumstance
        local wel = string.match(a, "WeatherElement%s*==%s*'(%a+)'$")
        if wel ~= nil then return nil, { wel .. ' weather' } end
        local del = string.match(a, "DayElement%s*==%s*'(%a+)'$")
        if del ~= nil then return nil, { del .. ' day' } end
        local kop, kval = string.match(a, "^spell%.Skill%s*([=~]=)%s*'(.-)'$")
        if kop ~= nil then
            if ctx.skill ~= nil then return cmp(kop, string.lower(ctx.skill) == string.lower(kval)), {} end
            return nil, { ((kop == '==') and '' or 'not ') .. kval .. ' spells' }
        end
        local fop, fval = string.match(a, "^Family%(spell%.Name%)%s*([=~]=)%s*'(.-)'$")
        if fop ~= nil then
            if ctx.family ~= nil then return cmp(fop, string.lower(ctx.family) == string.lower(fval)), {} end
            return nil, { ((fop == '==') and '' or 'not ') .. fval .. ' spells' }
        end
        if (a == 'gcinclude.BurstWanted()') or ((vars[a] ~= nil) and vars[a].burst) then
            -- BurstWanted: only these skills
            local mb = (gearEngine ~= nil) and gearEngine.settings and gearEngine.settings.MBSkills or nil
            if (ctx.skill ~= nil) and (in_list(mb, ctx.skill) == false) then return false, {} end
            return nil, { 'magic burst' }
        end
        if a == 'gcinclude.RangedAcc()' then return nil, { 'melee mode Acc (/mset)' } end -- /mset acc: ranged too
        local blist, barg = string.match(a, '^T%s*(%b{})%s*:%s*contains%((.-)%)$')
        if blist ~= nil then
            local names = {}
            for s in string.gmatch(blist, "'(.-)'") do
                names[#names + 1] = s
            end
            local bv = string.match(barg, '^([%a_]+)%.Name$')
            local fam = (barg == 'Family(spell.Name)') or ((vars[barg] ~= nil) and vars[barg].family)
            if (bv ~= nil) and ACTION_VAR[bv] then
                if ctx.action ~= nil then return in_list(names, ctx.action), {} end
                return nil, { 'only ' .. table.concat(names, ', ') }
            elseif fam then
                if ctx.family ~= nil then return in_list(names, ctx.family), {} end
                return nil, { table.concat(names, ' / ') .. ' spells' }
            end
        end
        local lname, lvar = string.match(a, '^gcinclude%.([%w_]+)%s*:%s*contains%(([%a_]+)%.Name%)$')
        if (lname ~= nil) and ACTION_VAR[lvar] then
            local v = (ctx.action ~= nil) and (gearEngine ~= nil) and in_list(gearEngine[lname], ctx.action) or nil
            if v ~= nil then return v, {} end
            return nil, { 'a spell in ' .. lname }
        end
        local fvar, fpat = string.match(a, "^string%.%a+%(([%a_]+)%.Name,%s*'(.-)'")
        if (fvar ~= nil) and ACTION_VAR[fvar] then
            if ctx.action ~= nil then
                local ok, hit = pcall(string.find, ctx.action, fpat, 1, string.find(a, '^string%.match') == nil)
                if ok then return (hit ~= nil), {} end
            end
            return nil, { 'name has ' .. fpat }
        end
        local nb = string.match(a, '^ByName%((.-)%)$')
        if nb ~= nil then -- ByName(spell.Name): a set named for the action; Family(...): for its family
            local v = string.match(nb, '^([%a_]+)%.Name$')
            if (v ~= nil) and ACTION_VAR[v] then return nil, { 'a set named for it' } end
            v = string.match(nb, '^Family%(([%a_]+)%.Name%)$')
            if (v ~= nil) and ACTION_VAR[v] then return nil, { 'a set for its family' } end
            if nb == 'spell.Skill' then return nil, { 'a set for its skill' } end
            return nil, { 'a set for ' .. nb }
        end
        local pct, pn = string.match(a, '([HM]PP)%s*<=?%s*(%d+)$')
        if pct ~= nil then return nil, { string.sub(pct, 1, 2) .. ' ' .. pn .. '% or less' } end
        return nil, { 'code: ' .. ((#a > 48) and (string.sub(a, 1, 45) .. '...') or a) }
    end

    eval_cond = function(c, ctx, vars)
        c = unwrap(c)
        local ors = split_top(c, 'or')
        if #ors > 1 then
            local texts, anyNil = {}, false
            for _, p in ipairs(ors) do
                local v, t = eval_cond(p, ctx, vars)
                if v == true then return true, {} end
                if v == nil then
                    anyNil = true
                    texts[#texts + 1] = table.concat(t, ' + ')
                end
            end
            if not anyNil then return false, {} end
            return nil, { table.concat(texts, ' or ') }
        end
        local ands = split_top(c, 'and')
        if #ands > 1 then
            local texts, anyNil = {}, false
            for _, p in ipairs(ands) do
                local v, t = eval_cond(p, ctx, vars)
                if v == false then return false, {} end
                if v == nil then
                    anyNil = true
                    for _, x in ipairs(t) do
                        texts[#texts + 1] = x
                    end
                end
            end
            if not anyNil then return true, {} end
            return nil, texts
        end
        return eval_atom(c, ctx, vars)
    end

    -- { [event] = { { kind, arg, frames, vars, line, code } } }: kind 'set' (sets.X, FindSet), 'byname' (ByName),
    -- 'mode'
    -- (EquipMode), 'idle' (EquipIdle), 'th' (CheckTH); arg the name or the expression; frames the if-blocks around it.
    local function scan_job(text)
        local out = {}
        local ev, frames, vars, ln, pending = nil, {}, {}, 0, nil
        local function open_branch(p) -- an if opens a frame; an elseif moves the frame's condition to prior
            if p.kw == 'if' then
                frames[#frames + 1] = { cond = p.cond, prior = {} }
            elseif #frames > 0 then
                local f = frames[#frames]
                f.prior[#f.prior + 1] = f.cond
                f.cond = p.cond
            end
        end
        for raw in string.gmatch(text .. '\n', '(.-)\r?\n') do
            ln = ln + 1
            local h = string.match(raw, '^profile%.(Handle%a+)%s*=%s*function')
            if h ~= nil then
                ev, frames, vars, pending = HANDLER_EVENT[h], {}, {}, nil
                if ev ~= nil then out[ev] = out[ev] or {} end
            elseif (ev ~= nil) and string.match(raw, '^end') then
                ev = nil
            elseif ev ~= nil then
                local line, m = raw, masked(raw)
                local cut = string.find(m, '--', 1, true)
                if cut ~= nil then line, m = string.sub(raw, 1, cut - 1), string.sub(m, 1, cut - 1) end
                -- locals the conditions read
                local lv, rhs = string.match(line, '^%s*local%s+([%w_,%s]-)%s*=%s*(.+)$')
                if lv ~= nil then
                    local names, vals = split_top(lv, ','), split_top(rhs, ',')
                    for i, v in ipairs(names) do
                        local r, info = trim((string.gsub(vals[i] or '', ';%s*$', ''))), nil -- the line's ; off
                        local buffs = {}
                        for b in string.gmatch(r, 'gcinclude%.BuffCount%((.-)%)') do
                            buffs[#buffs + 1] = buff_text(b)
                        end
                        if #buffs > 0 then
                            info = { buff = table.concat(buffs, ' or ') }
                        elseif string.match(r, "^gcdisplay%.GetCycle%('(%w+)'%)$") then
                            info = { cycle = string.match(r, "'(%w+)'") }
                        elseif r == 'gcinclude.BurstWanted()' then
                            info = { burst = true }
                        elseif string.match(r, '^Family%(') then
                            info = { family = true }
                        end
                        if info ~= nil then vars[trim(v)] = info end
                    end
                end
                -- keywords and set references in line order
                local items = {}
                for pos, w in string.gmatch(m, '()%f[%w_]([%a_]+)%f[^%w_]') do
                    if KEYWORD[w] then items[#items + 1] = { pos = pos, kw = w } end
                end
                local function ref(pos, kind, arg)
                    items[#items + 1] = { pos = pos, kind = kind, arg = arg }
                end
                for pos in string.gmatch(m, '()gcinclude%.EquipIdle%s*%(') do
                    ref(pos, 'idle')
                end
                for pos, n in string.gmatch(line, "()gcinclude%.EquipMode%s*%(%s*'([^']*)'") do
                    ref(pos, 'mode', n)
                end
                for pos in string.gmatch(m, '()gcinclude%.CheckTH%s*%(') do
                    ref(pos, 'th')
                end
                for _, fn in ipairs({ 'ByName', 'FindSet' }) do
                    for pos, open in string.gmatch(m, '()%f[%w_]' .. fn .. '%s*()%(') do
                        local close = close_paren(m, open)
                        if close ~= nil then
                            ref(
                                pos, (fn == 'ByName') and 'byname' or 'set', trim(string.sub(line, open + 1, close - 1))
                            )
                        end
                    end
                end
                for pos, n, after in string.gmatch(line, '()%f[%w_]sets%.([%a_][%w_]*)()') do
                    local before = string.sub(line, pos - 1, pos - 1)
                    if (before ~= '.') and not string.match(string.sub(line, after, after), '[%.%[%w_]') then
                        ref(pos, 'set', "'" .. n .. "'")
                    end
                end
                for pos, q in string.gmatch(line, "()%f[%w_]sets%s*%[%s*(%b'')%s*%]") do
                    if string.sub(line, pos - 1, pos - 1) ~= '.' then ref(pos, 'set', q) end
                end
                for pos, q in string.gmatch(line, '()%f[%w_]sets%s*%[%s*(%b"")%s*%]') do
                    if string.sub(line, pos - 1, pos - 1) ~= '.' then
                        ref(pos, 'set', "'" .. string.sub(q, 2, -2) .. "'")
                    end
                end
                table.sort(items, function(x, y) return x.pos < y.pos end)
                for i, it in ipairs(items) do
                    if (it.kw == 'if') or (it.kw == 'elseif') then
                        local stop = #line + 1
                        for j = i + 1, #items do
                            if items[j].kw == 'then' then
                                stop = items[j].pos
                                break
                            end
                        end
                        pending = { kw = it.kw, cond = string.sub(line, it.pos + #it.kw, stop - 1) }
                        if stop > #line then -- 'then' on a later line: the block starts here
                            open_branch(pending)
                            pending = nil
                        end
                    elseif (it.kw == 'then') and (pending ~= nil) then
                        open_branch(pending)
                        pending = nil
                    elseif it.kw == 'else' then
                        if #frames > 0 then
                            local f = frames[#frames]
                            f.prior[#f.prior + 1] = f.cond
                            f.cond = nil
                        end
                    elseif (it.kw == 'do') or (it.kw == 'function') or (it.kw == 'repeat') then
                        frames[#frames + 1] = { prior = {} }
                    elseif (it.kw == 'end') or (it.kw == 'until') then
                        frames[#frames] = nil
                    elseif it.kind ~= nil then
                        local snap = {}
                        for _, f in ipairs(frames) do
                            local prior = {}
                            for _, p in ipairs(f.prior) do
                                prior[#prior + 1] = p
                            end
                            snap[#snap + 1] = { cond = f.cond, prior = prior }
                        end
                        -- a reference inside the if's own condition (if not ByName(x) then) is under the blocks before
                        -- it
                        table.insert(out[ev], {
                            kind = it.kind,
                            arg = it.arg,
                            frames = snap,
                            vars = vars,
                            line = ln,
                            code = trim(line),
                        })
                    end
                end
            end
        end
        return out
    end

    -- An expression naming a set, for the action looked at: the name; else nil, a literal start and the rest of a name
    -- built in code ('Tank_' .. tank), and miss = true when only the action is unknown here (ByName(ws.Name) under
    -- Ws_Default).
    local function resolve(e, ctx, vars)
        e = trim(e or '')
        local lit = string.match(e, "^'([^']*)'$") or string.match(e, '^"([^"]*)"$')
        if lit ~= nil then return lit end
        local v = string.match(e, '^([%a_]+)%.Name$')
        if (v ~= nil) and ACTION_VAR[v] then return ctx.action, nil, nil, true end
        if e == 'spell.Skill' then return ctx.skill, nil, nil, true end
        if string.match(e, '^Family%(spell%.Name%)$') or ((vars[e] ~= nil) and vars[e].family) then
            return ctx.family, nil, nil, true
        end
        local left, suffix = string.match(e, "^(.-)%s*%.%.%s*'([^']*)'$")
        if left ~= nil then
            local l, pre, _, miss = resolve(left, ctx, vars)
            if l ~= nil then return l .. suffix end
            return nil, pre, nil, miss
        end
        local pre, rest = string.match(e, "^'([^']*)'%s*%.%.%s*(.+)$")
        return nil, pre, rest, false
    end
    -- the cycle a name's built-in part reads: GetCycle('PupMode'), or a local holding it
    local function cycle_of(rest, vars)
        rest = trim(rest or '')
        return string.match(rest, "^gcdisplay%.GetCycle%('(%w+)'%)$")
            or ((vars[rest] ~= nil) and vars[rest].cycle) or nil
    end

    return {
        Scan = scan_job,
        Evaluate = eval_cond,
        Resolve = resolve,
        CycleOf = cycle_of,
        CycleText = cycle_text,
        InList = in_list,
        StatusText = STATUS_TEXT,
    }
end

return analysis
