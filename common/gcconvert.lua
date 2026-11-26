-- Convert: a job file's own `if`s (in its handlers) into gcinclude.Rules, when the rules wear exactly what the code
-- did. The file is read as text and parsed (a Lua parser for what job files hold), never run.
--
-- An `if` converts when every condition maps to a rule condition (gcrules.KEYS), every branch only wears (a set by
-- name, gFunc.EquipSet of a set, gFunc.Equip of an item) or cancels, and the order holds: rules go on where the
-- handler's code ends (HandleDefault: at gcinclude.CheckDefault()), so an `if` converts only when no code after it
-- in that handler can wear anything (TH, CheckCancels and other `if`s that convert too are fine). elseif chains
-- become `first` groups (or plain rules when their branches can't overlap); nested `if`s join their parent's
-- conditions. Anything else stays code, with the reason.
--
-- Pure: Plan(text) -> { handlers = { { name, phase, items = { { line, ok, why, rules, s, e } } } }, rules, removals }.
local C = {}
local R = gFunc.LoadFile('common\\gcrules.lua')

-- == Tokens ==
local KEYWORDS = {}
for w in string.gmatch('and break do else elseif end false for function goto if in local nil not or repeat return '
    .. 'then true until while', '%a+') do KEYWORDS[w] = true end

local function long_close(s, i) -- [[ ... ]] / [==[ ... ]==] at i: the index after it, nil when it isn't one
    local eq = string.match(s, '^%[(=*)%[', i)
    if eq == nil then return nil end
    local close = string.find(s, ']' .. eq .. ']', i + #eq + 2, true)
    return (close ~= nil) and (close + #eq + 2) or (#s + 1)
end

function C.Tokens(s)
    local toks, i, n = {}, 1, #s
    while i <= n do
        local c = string.sub(s, i, i)
        if string.match(c, '%s') then
            i = i + 1
        elseif string.sub(s, i, i + 1) == '--' then
            local after = long_close(s, i + 2)
            if after ~= nil then
                i = after
            else
                local nl = string.find(s, '\n', i, true)
                i = (nl ~= nil) and nl or (n + 1)
            end
        elseif string.match(c, '[%a_]') then
            local w = string.match(s, '^[%w_]+', i)
            toks[#toks + 1] = { t = KEYWORDS[w] and 'kw' or 'name', v = w, s = i, e = i + #w - 1 }
            i = i + #w
        elseif string.match(c, '%d') or ((c == '.') and string.match(string.sub(s, i + 1, i + 1), '%d')) then
            local num = string.match(s, '^0[xX]%x+', i) or string.match(s, '^%d*%.?%d+[eE][%+%-]?%d+', i)
                or string.match(s, '^%d*%.?%d*', i)
            toks[#toks + 1] = { t = 'num', v = tonumber(num), s = i, e = i + #num - 1 }
            i = i + #num
        elseif (c == "'") or (c == '"') then
            local j, out = i + 1, {}
            while j <= n do
                local d = string.sub(s, j, j)
                if d == '\\' then
                    local nx = string.sub(s, j + 1, j + 1)
                    local map = { n = '\n', t = '\t', r = '\r', ['\\'] = '\\', ["'"] = "'", ['"'] = '"' }
                    out[#out + 1] = map[nx] or nx
                    j = j + 2
                elseif d == c then
                    break
                else
                    out[#out + 1] = d
                    j = j + 1
                end
            end
            toks[#toks + 1] = { t = 'str', v = table.concat(out), s = i, e = j }
            i = j + 1
        elseif (c == '[') and (long_close(s, i) ~= nil) then
            local after = long_close(s, i)
            local eq = string.match(s, '^%[(=*)%[', i)
            toks[#toks + 1] = { t = 'str', v = string.sub(s, i + #eq + 2, after - #eq - 3), s = i, e = after - 1 }
            i = after
        else
            local three, two = string.sub(s, i, i + 2), string.sub(s, i, i + 1)
            local op = (three == '...') and three
                or ((two == '..') or (two == '==') or (two == '~=') or (two == '<=') or (two == '>=') or (two == '::')) and two
                or c
            toks[#toks + 1] = { t = 'op', v = op, s = i, e = i + #op - 1 }
            i = i + #op
        end
    end
    toks[#toks + 1] = { t = 'eof', v = '<eof>', s = n + 1, e = n + 1 }
    return toks
end

-- == Parser: statements and expressions, positions kept (s: first char, e: last char). ==
local function parser(toks)
    local P, pos = {}, 1
    local function peek(k) return toks[pos + (k or 0)] end
    local function next_tok()
        local t = toks[pos]
        pos = pos + 1
        return t
    end
    local function is(v, t) local x = toks[pos]; return (x.v == v) and ((t == nil) or (x.t == t)) end
    local function expect(v)
        local t = next_tok()
        if t.v ~= v then error({ parse = "expected '" .. v .. "' near '" .. tostring(t.v) .. "'", at = t.s }) end
        return t
    end
    local block, expr

    local function funcbody(start)
        expect('(')
        local params = 0
        while not is(')') do
            local t = next_tok()
            if (t.t == 'name') or (t.v == '...') then params = params + 1 end
        end
        expect(')')
        local body = block()
        local fin = expect('end')
        return { k = 'func', body = body, params = params, s = start, e = fin.e }
    end
    local function args()
        local t = peek()
        if t.v == '(' and t.t == 'op' then
            next_tok()
            local list = {}
            if not is(')') then
                list[#list + 1] = expr()
                while is(',') do
                    next_tok()
                    list[#list + 1] = expr()
                end
            end
            local close = expect(')')
            return list, close.e
        elseif t.v == '{' and t.t == 'op' then
            local tbl = P.table()
            return { tbl }, tbl.e
        elseif t.t == 'str' then
            next_tok()
            return { { k = 'str', v = t.v, s = t.s, e = t.e } }, t.e
        end
        error({ parse = 'expected arguments', at = t.s })
    end
    function P.table()
        local open = expect('{')
        local node = { k = 'table', items = {}, fields = {}, s = open.s }
        while not is('}') do
            if is('[') and (peek().t == 'op') then
                next_tok()
                local key = expr()
                expect(']')
                expect('=')
                local v = expr()
                if key.k == 'str' then node.fields[key.v] = v else node.computed = true end
            elseif (peek().t == 'name') and (peek(1).v == '=') and (peek(1).t == 'op') then
                local key = next_tok().v
                next_tok()
                node.fields[key] = expr()
            else
                node.items[#node.items + 1] = expr()
            end
            if is(',') or is(';') then next_tok() else break end
        end
        node.e = expect('}').e
        return node
    end
    local function primary()
        local t = peek()
        if t.t == 'name' then
            next_tok()
            return { k = 'name', v = t.v, s = t.s, e = t.e }
        elseif t.v == '(' and t.t == 'op' then
            next_tok()
            local inner = expr()
            local close = expect(')')
            return { k = 'paren', a = inner, s = t.s, e = close.e }
        end
        error({ parse = "unexpected '" .. tostring(t.v) .. "'", at = t.s })
    end
    local function suffixed()
        local node = primary()
        while true do
            local t = peek()
            if t.v == '.' and t.t == 'op' then
                next_tok()
                local name = next_tok()
                node = { k = 'index', obj = node, key = { k = 'str', v = name.v }, s = node.s, e = name.e }
            elseif t.v == '[' and t.t == 'op' then
                next_tok()
                local key = expr()
                local close = expect(']')
                node = { k = 'index', obj = node, key = key, s = node.s, e = close.e }
            elseif t.v == ':' and t.t == 'op' then
                next_tok()
                local name = next_tok()
                local list, e = args()
                node = { k = 'call', fn = node, method = name.v, args = list, s = node.s, e = e }
            elseif ((t.v == '(' or t.v == '{') and t.t == 'op') or (t.t == 'str') then
                local list, e = args()
                node = { k = 'call', fn = node, args = list, s = node.s, e = e }
            else
                return node
            end
        end
    end
    local function simple()
        local t = peek()
        if t.t == 'num' then next_tok(); return { k = 'num', v = t.v, s = t.s, e = t.e } end
        if t.t == 'str' then next_tok(); return { k = 'str', v = t.v, s = t.s, e = t.e } end
        if t.t == 'kw' and (t.v == 'true' or t.v == 'false') then next_tok(); return { k = 'bool', v = (t.v == 'true'), s = t.s, e = t.e } end
        if t.t == 'kw' and t.v == 'nil' then next_tok(); return { k = 'nil', s = t.s, e = t.e } end
        if t.v == '...' then next_tok(); return { k = 'vararg', s = t.s, e = t.e } end
        if t.v == '{' and t.t == 'op' then return P.table() end
        if t.t == 'kw' and t.v == 'function' then next_tok(); return funcbody(t.s) end
        return suffixed()
    end
    local BIN = { ['or'] = { 1, 1 }, ['and'] = { 2, 2 }, ['<'] = { 3, 3 }, ['>'] = { 3, 3 }, ['<='] = { 3, 3 },
        ['>='] = { 3, 3 }, ['~='] = { 3, 3 }, ['=='] = { 3, 3 }, ['..'] = { 5, 4 }, ['+'] = { 6, 6 }, ['-'] = { 6, 6 },
        ['*'] = { 7, 7 }, ['/'] = { 7, 7 }, ['%'] = { 7, 7 }, ['^'] = { 10, 9 } }
    local UNARY = 8
    local function sub(limit)
        local node
        local t = peek()
        if (t.t == 'kw' and t.v == 'not') or (t.t == 'op' and (t.v == '-' or t.v == '#')) then
            next_tok()
            local a = sub(UNARY)
            node = { k = 'un', op = t.v, a = a, s = t.s, e = a.e }
        else
            node = simple()
        end
        while true do
            local op = peek()
            local pr = ((op.t == 'op') or (op.t == 'kw')) and BIN[op.v] or nil
            if (pr == nil) or (pr[1] <= limit) then break end
            next_tok()
            local b = sub(pr[2])
            node = { k = 'bin', op = op.v, a = node, b = b, s = node.s, e = b.e }
        end
        return node
    end
    expr = function() return sub(0) end

    local function stat()
        local t = peek()
        if t.v == ';' and t.t == 'op' then next_tok(); return nil end
        if t.t == 'kw' then
            if t.v == 'if' then
                next_tok()
                local node = { k = 'if', branches = {}, s = t.s }
                local cond = expr()
                expect('then')
                node.branches[1] = { cond = cond, body = block() }
                while is('elseif', 'kw') do
                    next_tok()
                    local c = expr()
                    expect('then')
                    node.branches[#node.branches + 1] = { cond = c, body = block() }
                end
                if is('else', 'kw') then
                    next_tok()
                    node.elseBody = block()
                end
                node.e = expect('end').e
                return node
            elseif t.v == 'local' then
                next_tok()
                if is('function', 'kw') then
                    next_tok()
                    local name = next_tok()
                    local f = funcbody(t.s)
                    return { k = 'localfunc', name = name.v, body = f.body, params = f.params, s = t.s, e = f.e }
                end
                local names = { next_tok().v }
                while is(',') do
                    next_tok()
                    names[#names + 1] = next_tok().v
                end
                local exprs = {}
                if is('=') then
                    next_tok()
                    exprs[1] = expr()
                    while is(',') do
                        next_tok()
                        exprs[#exprs + 1] = expr()
                    end
                end
                local last = (#exprs > 0) and exprs[#exprs].e or toks[pos - 1].e
                return { k = 'local', names = names, exprs = exprs, s = t.s, e = last }
            elseif t.v == 'return' then
                next_tok()
                local e = t.e
                local list = {}
                if not (is('end', 'kw') or is('else', 'kw') or is('elseif', 'kw') or is('until', 'kw') or (peek().t == 'eof')
                    or is(';')) then
                    list[1] = expr()
                    while is(',') do
                        next_tok()
                        list[#list + 1] = expr()
                    end
                    e = list[#list].e
                end
                if is(';') then e = next_tok().e end
                return { k = 'return', exprs = list, s = t.s, e = e }
            elseif t.v == 'while' then
                next_tok(); expr(); expect('do'); local b = block()
                return { k = 'loop', body = b, s = t.s, e = expect('end').e }
            elseif t.v == 'for' then
                next_tok()
                while not is('do', 'kw') do next_tok() end
                next_tok()
                local b = block()
                return { k = 'loop', body = b, s = t.s, e = expect('end').e }
            elseif t.v == 'repeat' then
                next_tok(); local b = block(); expect('until'); local c = expr()
                return { k = 'loop', body = b, s = t.s, e = c.e }
            elseif t.v == 'do' then
                next_tok(); local b = block()
                return { k = 'do', body = b, s = t.s, e = expect('end').e }
            elseif t.v == 'function' then
                next_tok()
                local name = next_tok()
                local target = { k = 'name', v = name.v, s = name.s, e = name.e }
                while is('.') or is(':') do
                    next_tok()
                    local field = next_tok()
                    target = { k = 'index', obj = target, key = { k = 'str', v = field.v }, s = target.s, e = field.e }
                end
                local f = funcbody(t.s)
                return { k = 'assign', targets = { target }, exprs = { f }, s = t.s, e = f.e }
            elseif t.v == 'break' or t.v == 'goto' then
                next_tok()
                if t.v == 'goto' then next_tok() end
                return { k = 'other', s = t.s, e = t.e }
            end
        end
        if t.v == '::' then
            next_tok(); next_tok(); expect('::')
            return nil
        end
        local first = suffixed()
        if is('=') or is(',') then
            local targets = { first }
            while is(',') do
                next_tok()
                targets[#targets + 1] = suffixed()
            end
            expect('=')
            local exprs = { expr() }
            while is(',') do
                next_tok()
                exprs[#exprs + 1] = expr()
            end
            return { k = 'assign', targets = targets, exprs = exprs, s = t.s, e = exprs[#exprs].e }
        end
        return { k = 'callstat', call = first, s = first.s, e = first.e }
    end
    block = function()
        local list = {}
        while true do
            local t = peek()
            if (t.t == 'eof') or ((t.t == 'kw') and (t.v == 'end' or t.v == 'else' or t.v == 'elseif' or t.v == 'until')) then
                return list
            end
            local st = stat()
            if st ~= nil then list[#list + 1] = st end
        end
    end
    function P.chunk()
        local b = block()
        if peek().t ~= 'eof' then error({ parse = "unexpected '" .. tostring(peek().v) .. "'", at = peek().s }) end
        return b
    end
    return P
end

-- The file as statements; nil and why (with where) when it doesn't parse.
function C.Parse(text)
    local ok, r = pcall(function() return parser(C.Tokens(text)).chunk() end)
    if ok then return r end
    if type(r) == 'table' then return nil, r.parse, r.at end
    return nil, tostring(r)
end

-- == Meaning: what an expression reads ==
local function path_of(e) -- 'gData.GetPlayer', 'sets.Idle'; nil for anything but names and . / ['x'] indexes
    if e == nil then return nil end
    if e.k == 'paren' then return path_of(e.a) end
    if e.k == 'name' then return e.v end
    if e.k == 'index' and e.key.k == 'str' then
        local base = path_of(e.obj)
        return (base ~= nil) and (base .. '.' .. e.key.v) or nil
    end
    return nil
end
local function unparen(e)
    while (e ~= nil) and (e.k == 'paren') do e = e.a end
    return e
end

local GETTERS = { ['gData.GetPlayer'] = 'player', ['gData.GetAction'] = 'action', ['gData.GetActionTarget'] = 'target',
    ['gData.GetEnvironment'] = 'env', ['gData.GetPet'] = 'pet', ['gData.GetPetAction'] = 'petAction',
    ['gData.GetTarget'] = 'curtarget' }
local FIELD_KEY = {
    player = { Status = 'status', HPP = 'hpp', MPP = 'mpp', TP = 'tp', SubJob = 'sub', MainJobSync = 'level',
        IsMoving = 'moving' },
    action = { Name = 'name', Skill = 'skill', Element = 'element', Type = 'type' },
    target = { HPP = 'targethpp', Distance = 'distance', Type = 'target' },
    env = { DayElement = 'day', WeatherElement = 'weather', Area = 'zone', Time = 'time' },
    pet = { HPP = 'pethpp', TP = 'pettp', Name = 'petname', Status = 'petstatus' },
}
local CYCLE_SHORT = {}
for short, full in pairs(R.CYCLES) do CYCLE_SHORT[full] = short end
local TOGGLE_SHORT = {}
for short, full in pairs(R.TOGGLES) do TOGGLE_SHORT[full] = short end

-- scope: { vars = { [name] = meaning }, aliases = { [name] = 'gcinclude.ByName' }, lists = { [name] = { 'a' } } }
local meaning
local function canon(scope, p) -- a path with file-level aliases resolved (ByName -> gcinclude.ByName)
    if p == nil then return nil end
    local head, rest = string.match(p, '^([%w_]+)(.*)$')
    local a = scope.aliases[head]
    if a ~= nil then return a .. rest end
    return p
end
local function call_path(scope, call)
    if call.method ~= nil then return nil end
    return canon(scope, path_of(call.fn))
end
local function is_party_me(e) -- AshitaCore:GetMemoryManager():GetParty():GetMemberName(0)
    e = unparen(e)
    if (e == nil) or (e.k ~= 'call') or (e.method ~= 'GetMemberName') then return false end
    local a = e.args[1]
    if (a == nil) or (a.k ~= 'num') or (a.v ~= 0) then return false end
    local p = e.fn
    if (p.k ~= 'call') or (p.method ~= 'GetParty') then return false end
    p = p.fn
    return (p.k == 'call') and (p.method == 'GetMemoryManager') and (path_of(p.fn) == 'AshitaCore')
end
-- AshitaCore:GetResourceManager():GetString('zones.names', AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0)):
-- the zone's name as LuAshitacast's gData.GetEnvironment().Area reads it (data.lua), before it trims trailing NULs
-- and turns Shift-JIS into UTF-8; so a search in it reads the same, a whole-name compare may not.
local function is_zone_name(e)
    e = unparen(e)
    if (e == nil) or (e.k ~= 'call') or (e.method ~= 'GetString') or (#e.args ~= 2) then return false end
    local a1, a2 = unparen(e.args[1]), unparen(e.args[2])
    if (a1 == nil) or (a1.k ~= 'str') or (a1.v ~= 'zones.names') then return false end
    local rm = e.fn
    if (rm.k ~= 'call') or (rm.method ~= 'GetResourceManager') or (path_of(rm.fn) ~= 'AshitaCore') then return false end
    if (a2 == nil) or (a2.k ~= 'call') or (a2.method ~= 'GetMemberZone') then return false end
    local n = a2.args[1]
    if (n == nil) or (n.k ~= 'num') or (n.v ~= 0) then return false end
    local party = a2.fn
    if (party.k ~= 'call') or (party.method ~= 'GetParty') then return false end
    local mm = party.fn
    return (mm.k == 'call') and (mm.method == 'GetMemoryManager') and (path_of(mm.fn) == 'AshitaCore')
end
local function literal_list(scope, e)
    e = unparen(e)
    if e == nil then return nil end
    if (e.k == 'call') and (#e.args == 1) and (e.args[1].k == 'table') and (path_of(e.fn) == 'T') then e = e.args[1] end
    if e.k == 'name' then return scope.lists[e.v] end
    if (e.k ~= 'table') or e.computed or (next(e.fields) ~= nil) then return nil end
    local out = {}
    for _, x in ipairs(e.items) do
        if x.k ~= 'str' then return nil end
        out[#out + 1] = x.v
    end
    return out
end
meaning = function(scope, e)
    e = unparen(e)
    if e == nil then return nil end
    if e.k == 'str' or e.k == 'num' or e.k == 'bool' then return { kind = 'lit', v = e.v } end
    if e.k == 'nil' then return { kind = 'nil' } end
    if e.k == 'name' then
        local v = scope.vars[e.v]
        if v ~= nil then return v end
        return nil
    end
    if e.k == 'bin' and e.op == 'or' then -- gData.GetActionTarget() or {}: the getter
        local m = meaning(scope, e.a)
        local b = unparen(e.b)
        if (m ~= nil) and (b.k == 'table') and (#b.items == 0) and (next(b.fields) == nil) then return m end
        return nil
    end
    if e.k == 'bin' and e.op == '+' then -- BuffCount('A') + BuffCount('B'): up when any of them is
        local a, b = meaning(scope, e.a), meaning(scope, e.b)
        if (a ~= nil) and (b ~= nil) and (a.kind == 'buffcount') and (b.kind == 'buffcount') then
            local names = {}
            for _, x in ipairs(a.names) do names[#names + 1] = x end
            for _, x in ipairs(b.names) do names[#names + 1] = x end
            return { kind = 'buffcount', names = names }
        end
        return nil
    end
    if e.k == 'index' and e.key.k == 'str' then
        local base = meaning(scope, e.obj)
        if (base ~= nil) and (base.kind == 'player') and (e.key.v == 'Name') then return { kind = 'me' } end
        if (base ~= nil) and FIELD_KEY[base.kind] ~= nil then return { kind = 'field', base = base.kind, field = e.key.v } end
        return nil
    end
    if e.k == 'call' then
        if is_party_me(e) then return { kind = 'me' } end
        if is_zone_name(e) then return { kind = 'field', base = 'env', field = 'Area', raw = true } end
        local p = call_path(scope, e)
        if (p ~= nil) and GETTERS[p] then return { kind = GETTERS[p] } end
        if (p == 'gcinclude.BuffCount') or (p == 'gData.GetBuffCount') then
            local a = e.args[1]
            if (a ~= nil) and ((a.k == 'str') or (a.k == 'num')) and (#e.args == 1) then
                return { kind = 'buffcount', names = { a.v } }
            end
            return nil
        end
        if (p == 'gcdisplay.GetCycle') and (e.args[1] ~= nil) and (e.args[1].k == 'str') then
            return { kind = 'cycle', name = e.args[1].v }
        end
        if (p == 'gcdisplay.GetToggle') and (e.args[1] ~= nil) and (e.args[1].k == 'str') then
            return { kind = 'toggle', name = e.args[1].v }
        end
        if p == 'gcinclude.BurstWanted' then return { kind = 'flag', key = 'burst' } end
        if p == 'gcinclude.CanDualWield' then return { kind = 'flag', key = 'dualwield' } end
        if (p == 'gcinclude.Family') and (#e.args == 1) then
            local m = meaning(scope, e.args[1])
            if (m ~= nil) and (m.kind == 'field') and (m.base == 'action') and (m.field == 'Name') then
                return { kind = 'family' }
            end
        end
        return nil
    end
    return nil
end

-- == Conditions ==
local function deep(v)
    if type(v) ~= 'table' then return v end
    local o = {}
    for k, x in pairs(v) do o[k] = deep(x) end
    return o
end
local MAGIC = '[%^%$%(%)%%%.%[%]%*%+%-%?]'
local function cond_of(scope, e) end -- forward
local NEG_NUM = { lt = 'ge', le = 'gt', gt = 'le', ge = 'lt', eq = 'ne', ne = 'eq' }
local FLIP = { ['<'] = '>', ['>'] = '<', ['<='] = '>=', ['>='] = '<=', ['=='] = '==', ['~='] = '~=' }
local NUM_OP = { ['<'] = 'lt', ['<='] = 'le', ['>'] = 'gt', ['>='] = 'ge', ['=='] = 'eq', ['~='] = 'ne' }

local function single(when) -- the one key of a when table, or nil
    local k = next(when)
    if (k == nil) or (next(when, k) ~= nil) then return nil end
    return k
end
-- `a and b` as one when table; nil and why when they can't be said together.
-- One value checked twice in a way one rule can't hold (its name has 'A' and has 'B', two HP limits...).
local function twice(k)
    local key = string.match(k, '^(%S+)')
    local label = (R.KEY[key] ~= nil) and (R.KEY[key].label or key) or k
    return 'It checks ' .. string.lower(label) .. ' twice in one condition (nested ifs, or an elseif\'s "not the ones '
        .. 'before"). A rule checks each value once.'
end
local function both(a, b)
    if a.any ~= nil and b.any ~= nil then return nil, 'Its check is (A or B) and (C or D). A rule takes one list of "any of these", not two.' end
    local out = {}
    for k, v in pairs(a) do out[k] = v end
    for k, v in pairs(b) do
        local cur = out[k]
        if cur == nil then
            out[k] = v
        else
            local meta = R.KEY[k] or {}
            if (meta.kind == 'number') and (type(cur) == 'table') and (type(v) == 'table') then
                local m = {}
                for op, x in pairs(cur) do m[op] = x end
                for op, x in pairs(v) do
                    if m[op] ~= nil and m[op] ~= x then return nil, twice(k) end
                    m[op] = x
                end
                out[k] = m
            elseif (meta.kind == 'mode') or (meta.kind == 'toggle') then
                local m = {}
                for s, x in pairs(cur) do m[s] = x end
                for s, x in pairs(v) do
                    if m[s] ~= nil then return nil, twice(k .. ' ' .. s) end
                    m[s] = x
                end
                out[k] = m
            elseif (k == 'buff') and (type(cur) == 'string' or #cur == 1) and (type(v) == 'string' or #v == 1) then
                out.buff = nil -- two buffs that must both be up
                local x, y = (type(cur) == 'table') and cur[1] or cur, (type(v) == 'table') and v[1] or v
                local all = out.allbuffs or {}
                if type(all) == 'string' then all = { all } end
                all[#all + 1], all[#all + 2] = x, y
                out.allbuffs = all
            elseif (k == 'nobuff') then
                local list = {}
                for _, x in ipairs((type(cur) == 'table') and cur or { cur }) do list[#list + 1] = x end
                for _, x in ipairs((type(v) == 'table') and v or { v }) do list[#list + 1] = x end
                out.nobuff = list
            elseif (k == 'any') then
                return nil, 'Its check is (A or B) and (C or D). A rule takes one list of "any of these", not two.'
            elseif (type(cur) == 'table') and (type(v) == 'table') and (cur[1] == nil) and (v[1] == nil) then
                local m = {}
                for f, x in pairs(cur) do m[f] = x end
                for f, x in pairs(v) do
                    if (f == 'has') and (m.has ~= nil) and ((type(x) == 'string') or (type(m.has) == 'string')) then
                        -- 'helix', then inside it 'Nocto': the name has both (hasall); a list stays has (any of)
                        local one, keep = x, m.has
                        if type(x) ~= 'string' then one, keep = m.has, x end
                        local all = {}
                        for _, y in ipairs(m.hasall or {}) do all[#all + 1] = y end
                        if type(keep) == 'string' then all[#all + 1], keep = keep, nil end
                        all[#all + 1] = one
                        m.hasall, m.has = all, keep
                    elseif m[f] ~= nil then
                        return nil, twice(k)
                    else
                        m[f] = x
                    end
                end
                out[k] = m
            elseif (type(cur) ~= 'table' or cur[1] ~= nil) and (type(v) == 'table') and (v[1] == nil) and (v.is == nil) then
                local m = { is = cur }
                for f, x in pairs(v) do m[f] = x end
                out[k] = m
            elseif (type(v) ~= 'table' or v[1] ~= nil) and (type(cur) == 'table') and (cur[1] == nil) and (cur.is == nil) then
                local m = { is = v }
                for f, x in pairs(cur) do m[f] = x end
                out[k] = m
            else
                return nil, twice(k)
            end
        end
    end
    return out
end
C.Both = both

-- `a or b`: one key's alternatives joined (name has 'a' or has 'b'), else any = { a, b }.
local function either(a, b)
    local ka, kb = single(a), single(b)
    if (ka ~= nil) and (ka == kb) and (ka ~= 'any') then
        local va, vb = a[ka], b[kb]
        local meta = R.KEY[ka] or {}
        local function list(v) return (type(v) == 'table') and v or { v } end
        if (meta.kind == 'list') and (ka == 'buff') then
            local out = {}
            for _, x in ipairs(list(va)) do out[#out + 1] = x end
            for _, x in ipairs(list(vb)) do out[#out + 1] = x end
            return { buff = out }
        end
        if (meta.kind == 'text') then
            local ta = (type(va) == 'string' or va[1] ~= nil) and { is = va } or va
            local tb = (type(vb) == 'string' or vb[1] ~= nil) and { is = vb } or vb
            local fa, fb = single(ta), single(tb)
            if (fa ~= nil) and (fa == fb) and (fa ~= 'isnt') then
                local out = {}
                for _, x in ipairs(list(ta[fa])) do out[#out + 1] = x end
                for _, x in ipairs(list(tb[fb])) do out[#out + 1] = x end
                return { [ka] = (fa == 'is') and out or { [fa] = out } }
            end
        end
    end
    local alts = {}
    for _, w in ipairs({ a, b }) do
        if (single(w) == 'any') then
            for _, x in ipairs(w.any) do alts[#alts + 1] = x end
        else
            alts[#alts + 1] = w
        end
    end
    return { any = alts }
end

-- `not x`: the opposite, for one condition; nil when it has none.
local function negate(w)
    local k = single(w)
    if k == nil then return nil end
    local v = w[k]
    if (k == 'any') and (type(v) == 'table') then -- not (A or B): not A and not B
        local out = {}
        for _, alt in ipairs(v) do
            local n = negate(alt)
            if n == nil then return nil end
            out = both(out, n)
            if out == nil then return nil end
        end
        return out
    end
    local meta = R.KEY[k] or {}
    if k == 'buff' then return { nobuff = v } end
    if k == 'nobuff' then return { buff = v } end
    if meta.kind == 'bool' then return { [k] = not v } end
    if meta.kind == 'toggle' then
        local s = single(v)
        if s == nil then return nil end
        return { toggle = { [s] = not v[s] } }
    end
    if meta.kind == 'mode' then
        local s = single(v)
        if s == nil then return nil end
        local x = v[s]
        if (type(x) == 'string') or (type(x) == 'table' and x[1] ~= nil) then return { mode = { [s] = { isnt = x } } } end
        if (type(x) == 'table') and (single(x) == 'isnt') then return { mode = { [s] = x.isnt } } end
        return nil
    end
    if meta.kind == 'number' then
        local op = single(v)
        if op == nil then return nil end
        return { [k] = { [NEG_NUM[op]] = v[op] } }
    end
    if meta.kind == 'text' then
        if k == 'target' then
            if v == 'me' then return { target = 'other' } end
            if v == 'other' then return { target = 'me' } end
            return nil
        end
        if (type(v) == 'string') or (v[1] ~= nil) then return { [k] = { isnt = v } } end
        if single(v) == 'isnt' then return { [k] = v.isnt } end
        return nil
    end
    return nil
end
C.Negate = negate

-- Why a value can't be read, naming it when it's one of the file's own locals (suffix, roll...).
local function unread(e)
    e = unparen(e) or e
    if (e ~= nil) and (e.k == 'name') then
        return 'It checks ' .. e.v .. ', a value your code works out here. A rule only checks game values (spell, buffs, HP/MP, modes...).'
    end
    return 'It compares a value a rule can\'t read. A rule only checks game values (spell, buffs, HP/MP, modes...).'
end

-- A comparison `a op b` as a when table.
local function compare(scope, op, ea, eb)
    -- string.find(spell.Name, 'helix', 1, true) ~= nil: the call as a condition (== nil: turned around)
    local ua, ub = unparen(ea), unparen(eb)
    if ((op == '~=') or (op == '==')) and (ua ~= nil) and (ub ~= nil) and ((ua.k == 'nil') ~= (ub.k == 'nil')) then
        local other = (ua.k == 'nil') and ub or ua
        if other.k == 'call' then
            local c = cond_of(scope, other)
            if c ~= nil then
                if op == '~=' then return c end
                local n = negate(c)
                if n ~= nil then return n end
                return nil, 'It checks that something is missing (== nil) in a way a rule can\'t say.'
            end
        end
    end
    local a, b = meaning(scope, ea), meaning(scope, eb)
    if (a == nil) or (b == nil) then return nil, unread((a == nil) and ea or eb) end
    if (a.kind == 'lit') or (a.kind == 'nil') or (a.kind == 'me') and (b.kind == 'field') then a, b, op = b, a, FLIP[op] end
    if (op ~= '==') and (op ~= '~=') and NUM_OP[op] == nil then return nil, 'It uses a comparison a rule doesn\'t have.' end
    local eq = (op == '==')
    local textOk = (op == '==') or (op == '~=')
    local function text(key, v) if eq then return { [key] = v } end return { [key] = { isnt = v } } end
    if a.raw and (b.kind ~= 'nil') then
        return nil, 'It compares the whole zone name as Ashita gives it (it can end in blank characters LuAshitacast trims). '
            .. 'A rule reads the trimmed name; a search for part of it converts.'
    end
    if (b.kind == 'nil') and (a.kind == 'field') and not eq then return {} end -- area ~= nil: a guard, as below
    if a.kind == 'field' then
        if (a.base == 'target') and (a.field == 'Name') and (b.kind == 'me') and textOk then
            return { target = eq and 'me' or 'other' }
        end
        local key = (FIELD_KEY[a.base] or {})[a.field]
        if key == nil then return nil, a.base .. '.' .. a.field .. ' is not read by rules' end
        local meta = R.KEY[key]
        if (a.base == 'action') and (a.field == 'Element') and (b.kind == 'field') and (b.base == 'env') and textOk then
            local which = (b.field == 'WeatherElement') and 'weather' or ((b.field == 'DayElement') and 'day' or nil)
            if which == nil then
                return nil, 'It compares the spell\'s element with ' .. tostring(b.field) .. '. A rule can match it to the day or the weather only.'
            end
            if not eq then return nil, 'It checks the element is NOT the ' .. which .. '\'s. A rule can only match it.' end
            return { element = which }
        end
        if (a.base == 'target') and (a.field == 'Name') and (b.kind == 'me') and textOk then
            return { target = eq and 'me' or 'other' }
        end
        if b.kind ~= 'lit' then return nil, a.field .. ' compared with something that is not a value' end
        if meta.kind == 'number' then
            if type(b.v) ~= 'number' then return nil, a.field .. ' compared with text' end
            return { [key] = { [NUM_OP[op]] = b.v } }
        end
        if meta.kind == 'bool' then
            if (type(b.v) ~= 'boolean') or not textOk then return nil, a.field .. ' compared with a non-boolean' end
            return { [key] = (b.v == eq) }
        end
        if (not textOk) or (type(b.v) ~= 'string') then return nil, a.field .. ' compared as a number' end
        if key == 'target' then
            if not eq then return nil, 'It checks the target is NOT a kind (PC, monster...). A rule can only match the kind.' end
            return { target = b.v }
        end
        return text(key, b.v)
    end
    if a.kind == 'family' then
        if (b.kind ~= 'lit') or (type(b.v) ~= 'string') or not textOk then return nil, 'It compares the spell family with something other than a name.' end
        return text('family', b.v)
    end
    if a.kind == 'buffcount' then
        if (b.kind ~= 'lit') or (type(b.v) ~= 'number') then return nil, 'It compares a buff count with something other than a number.' end
        local n, up = b.v, nil
        if ((op == '>') and (n == 0)) or ((op == '>=') and (n == 1)) or ((op == '~=') and (n == 0)) then up = true end
        if ((op == '==') and (n == 0)) or ((op == '<') and (n == 1)) or ((op == '<=') and (n == 0)) then up = false end
        if up == nil then return nil, 'It checks a buff count ' .. op .. ' ' .. n .. '. A rule only knows up (count above 0) or not up. '
            .. 'For a buff that never shows twice, > 0 means the same and converts.' end
        local v = (#a.names == 1) and a.names[1] or a.names
        if up then return { buff = v } end
        return { nobuff = v }
    end
    if a.kind == 'cycle' then
        if (b.kind ~= 'lit') or (type(b.v) ~= 'string') or not textOk then return nil, 'It compares a mode with something other than one of its values.' end
        local s = CYCLE_SHORT[a.name] or a.name
        return { mode = { [s] = eq and b.v or { isnt = b.v } } }
    end
    if a.kind == 'toggle' then
        if (b.kind ~= 'lit') or (type(b.v) ~= 'boolean') or not textOk then return nil, 'It compares a toggle with something other than on or off.' end
        local s = TOGGLE_SHORT[a.name] or a.name
        return { toggle = { [s] = (b.v == eq) } }
    end
    if (a.kind == 'pet') and (b.kind == 'nil') and textOk then return { pet = not eq } end
    if (a.kind == 'flag') and (b.kind == 'lit') and (type(b.v) == 'boolean') and textOk then
        return { [a.key] = (b.v == eq) }
    end
    if (a.kind == 'petAction') and (b.kind == 'nil') then return nil, 'It checks your pet\'s move. Pet moves are handled on their own, so this part stays with your code.' end
    if (b.kind == 'nil') and (a.kind == 'player' or a.kind == 'action' or a.kind == 'target' or a.kind == 'env') then
        if eq then return nil, 'It checks that the ' .. a.kind .. ' is missing. A rule can\'t test for that.' end
        return {} -- x ~= nil: a guard; a rule reading a missing one is false anyway
    end
    return nil, unread(ea)
end

-- string.contains(spell.Name, 'x'), string.find(..., 'x', 1, true), spell.Name:contains('x'), T{...}:contains(x)
local function call_cond(scope, e)
    local p = call_path(scope, e)
    local function text_arg(subject, lit, plain)
        local m = meaning(scope, subject)
        if (m == nil) or (lit == nil) or (lit.k ~= 'str') then return nil, 'It searches text a rule can\'t read. A rule only checks game values (spell, buffs, HP/MP, modes...).' end
        local key = nil
        if (m.kind == 'field') then key = (FIELD_KEY[m.base] or {})[m.field] end
        if m.kind == 'family' then key = 'family' end
        if (key == nil) or (R.KEY[key].kind ~= 'text') then return nil, 'It searches text a rule can\'t read. A rule only checks game values (spell, buffs, HP/MP, modes...).' end
        if (not plain) and string.find(lit.v, MAGIC) then return { [key] = { pattern = lit.v } } end -- as the code reads it
        return { [key] = { has = lit.v } }
    end
    -- gcinclude.RangedAcc(): gcdisplay.GetCycle('MeleeSet') == 'Acc' (gcinclude.lua)
    if (p == 'gcinclude.RangedAcc') and (#e.args == 0) then return { mode = { mset = 'Acc' } } end
    if (p == 'string.contains') and (#e.args == 2) then return text_arg(e.args[1], e.args[2], false) end
    if (p == 'string.find') and (#e.args >= 2) then
        local plain = (#e.args == 4) and (e.args[3].k == 'num') and (e.args[3].v == 1) and (e.args[4].k == 'bool')
            and (e.args[4].v == true)
        if (#e.args ~= 2) and not plain then return nil, 'It uses string.find with options a rule doesn\'t have.' end
        return text_arg(e.args[1], e.args[2], plain)
    end
    if (p == 'string.match') and (#e.args == 2) then return text_arg(e.args[1], e.args[2], false) end
    if e.method == 'contains' and (#e.args == 1) then
        local lp = path_of(e.fn) -- gcinclude.BluMagPhysical:contains(spell.Name): GoomSwap's own spell list
        local listName = lp and string.match(canon(scope, lp) or lp, '^gcinclude%.([%w_]+)$') or nil
        if listName ~= nil then
            local m = meaning(scope, e.args[1])
            if (m ~= nil) and (m.kind == 'field') and (m.base == 'action') and (m.field == 'Name') then
                return { inlist = listName }
            end
            return nil, 'It checks GoomSwap\'s ' .. listName .. ' list against something other than the action\'s name.'
        end
        local list = literal_list(scope, e.fn)
        if list ~= nil then -- T{'Cure', 'Cura'}:contains(family)
            local m = meaning(scope, e.args[1])
            local key = nil
            if (m ~= nil) and (m.kind == 'field') then key = (FIELD_KEY[m.base] or {})[m.field] end
            if (m ~= nil) and (m.kind == 'family') then key = 'family' end
            if (key == nil) or (R.KEY[key].kind ~= 'text') then return nil, 'It checks a list against something a rule can\'t read. A rule only checks game values (spell, buffs, HP/MP, modes...).' end
            -- T{}:contains compares as written; a list in rules too
            return { [key] = list }
        end
        return text_arg(e.fn, e.args[1], false) -- spell.Name:contains('x')
    end
    local m = meaning(scope, e)
    if m ~= nil then
        if m.kind == 'flag' then return { [m.key] = true } end
        if m.kind == 'toggle' then return { toggle = { [TOGGLE_SHORT[m.name] or m.name] = true } } end
    end
    -- ByName(spell.Name) / ByName(Family(spell.Name)) in a check: whether that set exists (and it wears it, so Convert
    -- keeps the call itself as code: see keep_of)
    if ((p == 'gcinclude.ByName') or (p == 'ByName')) and (#e.args == 1) then
        local m = meaning(scope, e.args[1])
        if (m ~= nil) and (m.kind == 'field') and (m.base == 'action') and (m.field == 'Name') then return { nameset = true } end
        if (m ~= nil) and (m.kind == 'family') then return { familyset = true } end
    end
    local asks = { -- what a few engine calls in a check do, plainly
        ['gcinclude.ByName'] = 'Its check puts on a set and asks whether one by that name exists (ByName). A rule '
            .. 'can\'t ask whether a set exists.',
        ['gcinclude.IsWeaponValue'] = 'Its check asks whether a weapon pick is set, not None or Unknown '
            .. '(IsWeaponValue). A rule can\'t ask that one.',
    }
    if (p == 'gcinclude.IsWeaponValue') and (#e.args == 1) then -- IsWeaponValue(gcdisplay.GetCycle('Weapons')): a /wm pick
        local m = meaning(scope, e.args[1])
        if (m ~= nil) and (m.kind == 'cycle') and (m.name == 'Weapons') then return { wmpick = true } end
    end
    if (p ~= nil) and (asks[p] ~= nil) then return nil, asks[p] end
    local body = (e.fn ~= nil) and (e.fn.k == 'name') and (e.method == nil) and (#e.args == 0) and (scope.funcs ~= nil)
        and (scope.vars[e.fn.v] == nil) and scope.funcs[e.fn.v] or nil -- not a handler local by that name
    if (body ~= nil) and ((scope.depth or 0) < 4) then -- Night(): its locals, then the check it returns
        local inner = { vars = {}, aliases = scope.aliases, lists = scope.lists, funcs = scope.funcs, depth = (scope.depth or 0) + 1 }
        for i = 1, #body - 1 do
            for j, name in ipairs(body[i].names) do
                local m = (body[i].exprs[j] ~= nil) and meaning(inner, body[i].exprs[j]) or nil
                if m == nil then
                    return nil, 'Its check asks ' .. e.fn.v .. '(), your own function, which reads something a rule can\'t ('
                        .. name .. ').'
                end
                inner.vars[name] = m
            end
        end
        local c, why = cond_of(inner, body[#body].exprs[1])
        if c == nil then return nil, 'Its check asks ' .. e.fn.v .. '(), your own function: ' .. tostring(why) end
        return c
    end
    return nil, 'Its check asks ' .. tostring(p or (e.method and (':' .. e.method)) or 'a function') .. '(), which a rule '
        .. 'can\'t ask. A rule only checks game values (spell, buffs, HP/MP, modes...).'
end

cond_of = function(scope, e)
    e = unparen(e)
    if e.k == 'bin' then
        if e.op == 'and' then
            local a, why = cond_of(scope, e.a)
            if a == nil then return nil, why end
            local b, whyb = cond_of(scope, e.b)
            if b == nil then return nil, whyb end
            return both(a, b)
        elseif e.op == 'or' then
            local a, why = cond_of(scope, e.a)
            if a == nil then return nil, why end
            local b, whyb = cond_of(scope, e.b)
            if b == nil then return nil, whyb end
            if (next(a) == nil) or (next(b) == nil) then
                return nil, 'It joins with "or" a part a rule reads as always true (a check that a value exists), so the '
                    .. 'rule would always apply.'
            end
            return either(a, b)
        elseif (NUM_OP[e.op] ~= nil) then
            return compare(scope, e.op, e.a, e.b)
        end
        return nil, 'It does math (' .. tostring(e.op) .. ') in its check. A rule only compares values.'
    end
    if (e.k == 'un') and (e.op == 'not') then
        local a, why = cond_of(scope, e.a)
        if a == nil then return nil, why end
        local n = negate(a)
        if n == nil then return nil, 'It uses "not" on a check a rule can\'t turn around.' end
        return n
    end
    if e.k == 'call' then return call_cond(scope, e) end
    if e.k == 'name' or e.k == 'index' then
        local m = meaning(scope, e)
        if m == nil then
            return nil, 'It reads ' .. tostring(path_of(e) or 'a value') .. ', which a rule can\'t. A rule only checks game values (spell, buffs, HP/MP, modes...).'
        end
        if m.kind == 'cond' then return deep(m.cond) end -- local roll = string.find(ability.Name, 'Roll', 1, true) ~= nil
        if m.kind == 'flag' then return { [m.key] = true } end
        if m.kind == 'toggle' then return { toggle = { [TOGGLE_SHORT[m.name] or m.name] = true } } end
        if (m.kind == 'field') and (FIELD_KEY[m.base] or {})[m.field] == 'moving' then return { moving = true } end
        if (m.kind == 'pet') then return { pet = true } end
        if (m.kind == 'env') or (m.kind == 'player') or (m.kind == 'action') or (m.kind == 'target') then return {} end
        if m.kind == 'petAction' then return nil, 'It checks your pet\'s move. Pet moves are handled on their own, so this part stays with your code.' end
        return nil, 'It uses ' .. tostring(path_of(e)) .. ' as yes/no. A rule can\'t read it that way.'
    end
    if e.k == 'bool' then return nil, 'Its check is always true or always false: nothing to make a rule from.' end
    return nil, 'Its check is code a rule can\'t read. A rule only checks game values (spell, buffs, HP/MP, modes...).'
end

-- == Bodies: what a branch wears ==
local SLOT = {}
for _, s in ipairs(R.SLOTS) do SLOT[string.lower(s)] = s end
local function set_name_of(scope, arg)
    arg = unparen(arg)
    if arg == nil then return nil end
    if arg.k == 'str' then return arg.v end
    local p = path_of(arg)
    if p ~= nil then
        local name = string.match(p, '^sets%.(.+)$') or string.match(p, '^profile%.Sets%.(.+)$')
        if (name ~= nil) and not string.find(name, '.', 1, true) then return name end
    end
    if (arg.k == 'index') and (arg.key.k == 'str') then -- sets.Buffs.Boost / sets.Buffs['Boost']: Buffs['Boost'], as /gcedit names it
        local holder = path_of(unparen(arg.obj))
        local parent = (holder ~= nil) and (string.match(holder, '^sets%.([%w_]+)$') or string.match(holder, '^profile%.Sets%.([%w_]+)$')) or nil
        if (parent ~= nil) and not string.find(arg.key.v, "'", 1, true) then return parent .. "['" .. arg.key.v .. "']" end
    end
    if (arg.k == 'call') and (call_path(scope, arg) == 'gcinclude.FindSet') and (#arg.args == 1) and (arg.args[1].k == 'str') then
        return arg.args[1].v
    end
    return nil
end
local function item_of(e)
    e = unparen(e)
    if e.k == 'str' then return e.v end
    if (e.k == 'table') and not e.computed and (#e.items == 0) and (e.fields.Name ~= nil) and (e.fields.Name.k == 'str') then
        local out = {}
        for k, v in pairs(e.fields) do
            if v.k == 'str' or v.k == 'num' or v.k == 'bool' then
                out[k] = v.v
            elseif v.k == 'table' then
                local list = {}
                for _, x in ipairs(v.items) do
                    if x.k ~= 'str' then return nil end
                    list[#list + 1] = x.v
                end
                out[k] = list
            else
                return nil
            end
        end
        return out
    end
    return nil
end

-- What a call that isn't gear does, said plainly (a rule only puts on gear or cancels the action).
local CALL_SAYS = {
    ['gcinclude.DoCORmsg'] = 'prints the roll\'s lucky and unlucky numbers to chat',
    ['gcinclude.CheckCancels'] = 'cancels a buff first when an action needs it (Sneak, Utsusemi...)',
    ['gFunc.Message'] = 'prints to chat', ['gFunc.Echo'] = 'prints to chat', ['gFunc.Error'] = 'prints to chat',
    ['gcinclude.Say'] = 'prints to chat', ['gcinclude.Err'] = 'prints to chat', print = 'prints to chat',
}
local function not_gear(p)
    if p == 'gcinclude.CheckTH' then
        return 'It runs GoomSwap\'s TH step (CheckTH), which decides by itself whether to put on your TH set (/th, the '
            .. 'target...). A rule puts on a set without those checks.'
    end
    local what = CALL_SAYS[p]
    if what ~= nil then
        return 'Not gear: it ' .. what .. ' (' .. tostring(p) .. '). A rule only puts on gear or cancels the action.'
    end
    return 'It runs ' .. tostring(p or 'a function') .. '(), which does more than put on gear. A rule only puts on gear '
        .. 'or cancels the action.'
end
-- A set whose name is put together while the code runs (FindSet(ws.Name .. '_' .. suffix)): anywhere in an if's
-- branches, the whole if stays code, whatever its conditions say.
local NAMED_BY = { ['gcinclude.FindSet'] = true, ['gcinclude.ByName'] = true, ['gcinclude.FindFilled'] = true }
local function joined(e) -- 'Pet_WS_' .. mode
    e = unparen(e)
    return (e ~= nil) and (e.k == 'bin') and (e.op == '..')
end
local function builds_name(scope, node)
    if type(node) ~= 'table' then return false end
    if (node.k == 'call') and NAMED_BY[call_path(scope, node) or ''] and joined(node.args[1]) then return true end
    for k, v in pairs(node) do
        if (k ~= 'cond') and (type(v) == 'table') and builds_name(scope, v) then return true end
    end
    return false
end
local BUILT = 'It puts on a set whose name is put together while it runs (the action\'s name, a mode, a buff...). '
    .. 'A rule needs the set\'s name written out.'

-- A statement in a branch as rule actions: { wear, exact } / { item = { slot, item } } / { stop } / { localvar };
-- nil and why when it is something else.
local function action_of(scope, st)
    if st.k == 'callstat' then
        local call = st.call
        local p = call_path(scope, call)
        if p == 'gFunc.EquipSet' and (#call.args == 1) then
            local name = set_name_of(scope, call.args[1])
            if name == nil then
                local arg = unparen(call.args[1])
                local inner = (arg ~= nil) and path_of(arg) or nil
                inner = (inner ~= nil) and (string.match(inner, '^sets%.(.+)$') or string.match(inner, '^profile%.Sets%.(.+)$')) or nil
                if inner ~= nil then
                    return nil, 'It puts on sets.' .. inner .. ', a set inside another table. A rule puts on a set from '
                        .. 'your set list by its name.'
                end
                if joined(arg) or builds_name(scope, arg) then return nil, BUILT end
                return nil, 'It puts on a set named by a variable. A rule needs the set\'s name written out.'
            end
            return { wear = name, exact = true }
        end
        if p == 'gcinclude.ByName' and (#call.args == 1) then
            if call.args[1].k ~= 'str' then
                return nil, 'It puts on a set named by a variable. A rule needs the set\'s name written out.'
            end
            return { wear = call.args[1].v }
        end
        if p == 'gFunc.Equip' and (#call.args == 2) then
            local slot = (call.args[1].k == 'str') and SLOT[string.lower(call.args[1].v)] or nil
            local item = item_of(call.args[2])
            if (slot == nil) or (item == nil) then
                return nil, 'It puts on an item or slot named by a variable. A rule needs both written out.'
            end
            return { item = { slot, item } }
        end
        if p == 'gFunc.CancelAction' and (#call.args == 0) then return { stop = true } end
        return nil, not_gear(p)
    end
    if st.k == 'local' then return nil, 'It sets a variable for later code. A rule can\'t keep a value.' end
    return nil, 'It has other code (' .. st.k .. '). A rule only puts on gear or cancels the action.'
end


-- gFunc.EquipSet(c and sets.X or sets.Y): c, 'X', 'Y'; nil when the statement is something else.
local function ternary_wear(scope, st)
    if (st.k ~= 'callstat') or (call_path(scope, st.call) ~= 'gFunc.EquipSet') or (#st.call.args ~= 1) then return nil end
    local e = unparen(st.call.args[1])
    if (e == nil) or (e.k ~= 'bin') or (e.op ~= 'or') then return nil end
    local l = unparen(e.a)
    if (l == nil) or (l.k ~= 'bin') or (l.op ~= 'and') then return nil end
    local x, y = set_name_of(scope, l.b), set_name_of(scope, e.b)
    if (x == nil) or (y == nil) then return nil end
    return l.a, x, y
end
-- A block's statements as rules (in order) under the conditions `when`; nil and why when one can't be.
local convert_if
local function block_rules(scope, body, when, phase, out)
    local inner = { vars = setmetatable({}, { __index = scope.vars }), aliases = scope.aliases, lists = scope.lists, funcs = scope.funcs }
    local pending = nil -- consecutive wears/items under the same conditions join one rule
    local function flush()
        if pending ~= nil then out[#out + 1] = pending end
        pending = nil
    end
    for i, st in ipairs(body) do
        if st.k == 'if' then
            flush()
            local ok, why = convert_if(inner, st, when, phase, out)
            if not ok then return nil, why end
        elseif st.k == 'local' then
            for j, name in ipairs(st.names) do
                local m = (st.exprs[j] ~= nil) and meaning(inner, st.exprs[j]) or nil
                if m == nil then
                    return nil, 'It sets ' .. name .. ' from something a rule can\'t read. ' .. 'A rule only checks game values (spell, buffs, HP/MP, modes...).'
                end
                inner.vars[name] = m
            end
        elseif st.k == 'return' then
            if (i ~= #body) or (#st.exprs > 0) or ((pending == nil or not pending.stop) and not (out[#out] and out[#out].stop)) then
                return nil, 'It stops the handler early (return), so the code after it is skipped. A rule can\'t skip code.'
            end
        elseif ternary_wear(inner, st) ~= nil then -- gFunc.EquipSet(c and sets.X or sets.Y): two rules, c and not c
            flush()
            local c, x, y = ternary_wear(inner, st)
            local cw, cwhy = cond_of(inner, c)
            if cw == nil then return nil, cwhy end
            local ncw = negate(cw)
            if ncw == nil then return nil, 'It picks a set by a check a rule can\'t turn around for the other set.' end
            local w1, why1 = both(when, cw)
            if w1 == nil then return nil, why1 end
            local w2, why2 = both(when, ncw)
            if w2 == nil then return nil, why2 end
            out[#out + 1] = { on = phase, when = deep(w1), wear = x, exact = true }
            out[#out + 1] = { on = phase, when = deep(w2), wear = y, exact = true }
        else
            local a, why = action_of(inner, st)
            if a == nil then return nil, why end
            if a.stop then
                if not R.STOPPABLE[phase] then
                    return nil, 'It cancels at a moment LuAshitacast can\'t cancel (only when starting a spell, an '
                        .. 'ability, a weapon skill, an item or a shot).'
                end
                pending = pending or { on = phase, when = deep(when) }
                pending.stop = true
            elseif a.wear then
                flush()
                pending = { on = phase, when = deep(when), wear = a.wear, exact = a.exact or nil }
            else
                if (pending == nil) or (pending.item ~= nil and pending.item[a.item[1]] ~= nil) or pending.stop then
                    flush()
                    pending = { on = phase, when = deep(when) }
                end
                pending.item = pending.item or {}
                pending.item[a.item[1]] = a.item[2]
            end
        end
    end
    flush()
    return out
end

-- Branch conditions that can't overlap: all one text key compared with different values ('is').
local function exclusive(conds)
    local key = nil
    local seen = {}
    for _, w in ipairs(conds) do
        local k = single(w)
        if (k == nil) or (k == 'any') then return false end
        local meta = R.KEY[k] or {}
        if (meta.kind ~= 'text') or (k == 'target') then return false end
        if (key ~= nil) and (k ~= key) then return false end
        key = k
        local v = w[k]
        if type(v) ~= 'string' and not (type(v) == 'table' and v[1] ~= nil) then return false end
        for _, x in ipairs((type(v) == 'table') and v or { v }) do
            if seen[x] then return false end
            seen[x] = true
        end
    end
    return key ~= nil, key, seen
end

convert_if = function(scope, st, when, phase, out)
    if builds_name(scope, { st.branches, st.elseBody }) then return nil, BUILT end
    local conds = {}
    for i, br in ipairs(st.branches) do
        local c, why = cond_of(scope, br.cond)
        if c == nil then return nil, why end
        conds[i] = c
    end
    -- one-member branches (a single rule each, no nested code): a `first` group, or plain rules when they can't overlap
    local members, simple = {}, true
    for i, br in ipairs(st.branches) do
        local rules, why = block_rules(scope, br.body, {}, phase, {})
        if rules == nil then return nil, why end
        if #rules ~= 1 then simple = false end
        members[i] = rules
    end
    local elseRules = nil
    if st.elseBody ~= nil then
        local why
        elseRules, why = block_rules(scope, st.elseBody, {}, phase, {})
        if elseRules == nil then return nil, why end
        if #elseRules ~= 1 then simple = false end
    end
    local excl, key, values = exclusive(conds)
    if (#st.branches == 1) and (elseRules == nil) then -- a plain if
        local w, why = both(when, conds[1])
        if w == nil then return nil, why end
        return block_rules(scope, st.branches[1].body, w, phase, out)
    end
    if excl then -- skill chains: each branch on its own, the else as "none of them"
        for i, br in ipairs(st.branches) do
            local w, why = both(when, conds[i])
            if w == nil then return nil, why end
            local r, bwhy = block_rules(scope, br.body, w, phase, out)
            if r == nil then return nil, bwhy end
        end
        if st.elseBody ~= nil then
            local list = {}
            for v in pairs(values) do list[#list + 1] = v end
            table.sort(list)
            local w, why = both(when, { [key] = { isnt = list } })
            if w == nil then return nil, why end
            local r, bwhy = block_rules(scope, st.elseBody, w, phase, out)
            if r == nil then return nil, bwhy end
        end
        return out
    end
    if simple then
        local group = { on = phase, when = (next(when) ~= nil) and deep(when) or nil, first = {} }
        for i in ipairs(st.branches) do
            local m = members[i][1]
            m.on = nil
            local w, why = both(conds[i], m.when or {})
            if w == nil then return nil, why end
            m.when = (next(w) ~= nil) and w or nil
            group.first[#group.first + 1] = m
        end
        if elseRules ~= nil then
            local m = elseRules[1]
            m.on = nil
            if (m.when ~= nil) and (next(m.when) == nil) then m.when = nil end
            group.first[#group.first + 1] = m
        end
        for _, m in ipairs(group.first) do
            if m.stop then
                return nil, 'One choice of its if / elseif chain cancels the action. A first-that-fits group of rules '
                    .. 'can only put on gear.'
            end
        end
        out[#out + 1] = group
        return out
    end
    -- else: each branch with the earlier ones turned around
    local prior = {}
    for i, br in ipairs(st.branches) do
        local w, why = both(when, conds[i])
        if w == nil then return nil, why end
        for _, p in ipairs(prior) do
            w, why = both(w, p)
            if w == nil then return nil, why end
        end
        local r, bwhy = block_rules(scope, br.body, w, phase, out)
        if r == nil then return nil, bwhy end
        local n = negate(conds[i])
        if n == nil then
            return nil, 'In its elseif chain, each later branch means "not the ones before", and a rule can\'t say "not" '
                .. 'for one of those checks.'
        end
        prior[#prior + 1] = n
    end
    if st.elseBody ~= nil then
        local w = when
        for _, p in ipairs(prior) do
            local why
            w, why = both(w, p)
            if w == nil then return nil, why end
        end
        local r, bwhy = block_rules(scope, st.elseBody, w, phase, out)
        if r == nil then return nil, bwhy end
    end
    return out
end

-- == The plan ==
-- Lines every GoomSwap job file has, which stay as they are (they are GoomSwap's steps, not your own logic).
C.STANDARD = {
    { 'gcinclude%.EquipMode%(', 'a standard step: your idle / engaged / resting / moving sets' },
    -- exactly `if not ByName(x) then ByName(y) end` (gcinclude.ByName too): nothing else in it
    { '^if%s+not%s+[%w_%.]*ByName%s*%b()%s*then%s+[%w_%.]*ByName%s*%b()%s*;?%s*end$',
        "a standard step: the action's own set, else its family's (Cure IV: Cure)" },
    { 'CheckWsBailout', 'a standard step: a weapon skill that would fail is stopped' },
    { 'CheckBlockedAmmo', 'a standard step: a shot or weapon skill that would use precious ammo is stopped' },
}
local HANDLERS = { HandleDefault = 'Default', HandlePrecast = 'Precast', HandleMidcast = 'Midcast',
    HandleAbility = 'Ability', HandleWeaponskill = 'Weaponskill', HandlePreshot = 'Preshot', HandleMidshot = 'Midshot',
    HandleItem = 'Item' }
C.HANDLERS = HANDLERS
-- Calls after an `if` that wear nothing a rule could lose to (TH: re-worn over rules), or are the rules' own place.
local NEUTRAL = { ['gcinclude.CheckTH'] = true, ['gcinclude.CheckCancels'] = true, ['gcinclude.DoCORmsg'] = true }
-- What the same-gear check (gcconvertcheck) runs as the game would, or that only reads: code between a run and the
-- rules' own place made only of these can have its run moved there, when the check finds the same gear.
local CHECKED = { ['gcinclude.ByName'] = true, ['gcinclude.EquipSet'] = true, ['gcinclude.FindSet'] = true,
    ['gcinclude.FindFilled'] = true, ['gcinclude.Family'] = true, ['gcinclude.BuffCount'] = true,
    ['gcinclude.BurstWanted'] = true, ['gcinclude.CanDualWield'] = true, ['gcinclude.RangedAcc'] = true,
    ['gcinclude.IsWeaponValue'] = true, ['gFunc.EquipSet'] = true, ['gFunc.Equip'] = true, ['gFunc.Combine'] = true,
    ['gFunc.Message'] = true, ['gFunc.Echo'] = true, ['gFunc.Error'] = true, ['gFunc.CancelAction'] = true,
    T = true, tostring = true, tonumber = true, type = true, pairs = true, ipairs = true, next = true, select = true,
    print = true }
C.CHECKED = CHECKED -- gcconvertcheck must stand in for each gcinclude.* here (tests/convert_sim.lua holds it)
local READ_METHOD = { contains = true, find = true, match = true, lower = true, upper = true, sub = true, gsub = true,
    format = true, len = true }
local function checked_call(p)
    return CHECKED[p] or NEUTRAL[p] or string.match(p, '^gData%.Get') or string.match(p, '^gcdisplay%.Get')
        or string.match(p, '^string%.') or string.match(p, '^table%.') or string.match(p, '^math%.')
end
-- == Which slots code can wear: a run moves only past code that can't touch its slots ==
local ALL = { all = true } -- any slot (a set built in code, a name not known here)
local function union(a, b)
    if a.all or b.all then return ALL end
    local o = {}
    for k in pairs(a) do o[k] = true end
    for k in pairs(b) do o[k] = true end
    return o
end
local function overlap(a, b)
    if a.all then return next(b) ~= nil end
    if b.all then return next(a) ~= nil end
    for k in pairs(a) do if b[k] then return true end end
    return false
end
-- The file's sets: lower name -> its slots (ALL when not a plain table of slots).
local function set_table(chunk)
    local out = {}
    local function slots_of(v)
        v = unparen(v)
        if (v == nil) or (v.k ~= 'table') or v.computed then return ALL end
        local o = {}
        for k in pairs(v.fields) do
            local sl = SLOT[string.lower(k)]
            if sl ~= nil then o[sl] = true end
        end
        return o
    end
    local function take(t)
        for name, v in pairs(t.fields) do out[string.lower(name)] = slots_of(v) end
        if t.computed then out.__unknown = true end
    end
    local function is_sets(p) return (p == 'sets') or (p == 'profile.Sets') end
    for _, st in ipairs(chunk) do
        if st.k == 'local' then
            for j, n in ipairs(st.names) do
                local e = unparen(st.exprs[j])
                if (n == 'sets') and (e ~= nil) and (e.k == 'table') then take(e) end
            end
        elseif st.k == 'assign' then
            for j, t in ipairs(st.targets) do
                local e, p = st.exprs[j], path_of(t)
                local u = unparen(e)
                if is_sets(p) and (u ~= nil) and (u.k == 'table') then
                    take(u)
                elseif (t.k == 'index') and (t.key ~= nil) and (t.key.k == 'str') and is_sets(path_of(t.obj)) then
                    out[string.lower(t.key.v)] = slots_of(e)
                end
            end
        end
    end
    return out
end
local function name_slots(T, name, versions) -- a set by name; versions: its _<mode> sets too (worn by name)
    if T.__unknown then return ALL end
    local l = string.lower(name)
    local o = T[l]
    if o == nil then return ALL end -- not in this file (char.lua's sets...): could be anything
    if versions then
        for k, v in pairs(T) do
            if (k ~= '__unknown') and (string.sub(k, 1, #l + 1) == l .. '_') then o = union(o, v) end
        end
    end
    return o
end
local function rule_slots(T, r)
    if r.stop then return ALL end
    local o = {}
    if type(r.wear) == 'string' then o = union(o, name_slots(T, r.wear, not r.exact)) end
    if type(r.item) == 'table' then
        local it = {}
        for slot in pairs(r.item) do it[slot] = true end
        o = union(o, it)
    end
    for _, m in ipairs((type(r.first) == 'table') and r.first or {}) do o = union(o, rule_slots(T, m)) end
    return o
end
-- The slots node's code can wear (the file's own functions it calls too).
local function wears(scope, node, funcs, T, seen)
    if type(node) ~= 'table' then return {} end
    local acc = {}
    if (node.k == 'call') and (node.method == nil) then
        local p = canon(scope, path_of(node.fn))
        if (p == 'gFunc.EquipSet') or (p == 'gcinclude.EquipSet') then
            local nm = set_name_of(scope, node.args[1])
            acc = (nm ~= nil) and name_slots(T, nm, false) or ALL
        elseif p == 'gcinclude.ByName' then
            local a = unparen(node.args[1])
            acc = ((a ~= nil) and (a.k == 'str')) and name_slots(T, a.v, true) or ALL
        elseif p == 'gFunc.Equip' then
            local a = unparen(node.args[1])
            local sl = (a ~= nil) and (a.k == 'str') and SLOT[string.lower(a.v)] or nil
            acc = (sl ~= nil) and { [sl] = true } or ALL
        elseif (p ~= nil) and (funcs[p] ~= nil) and not seen[p] then
            seen[p] = true
            acc = wears(scope, funcs[p].body, funcs, T, seen)
        end
    end
    for _, v in pairs(node) do
        if acc.all then return ALL end
        if type(v) == 'table' then acc = union(acc, wears(scope, v, funcs, T, seen)) end
    end
    return acc
end

-- Every call in node (and in the file's own functions it calls) is one of those.
local function only_checked(scope, node, funcs, seen)
    if type(node) ~= 'table' then return true end
    if node.k == 'call' then
        if node.method ~= nil then
            if not (READ_METHOD[node.method] or string.match(node.method, '^Get')) then return false end
        else
            local p = canon(scope, path_of(node.fn))
            if p == nil then return false end
            if not checked_call(p) then
                local f = funcs[p]
                if f == nil then return false end
                if not seen[p] then
                    seen[p] = true
                    if not only_checked(scope, f.body, funcs, seen) then return false end
                end
            end
        end
    end
    for _, v in pairs(node) do
        if (type(v) == 'table') and not only_checked(scope, v, funcs, seen) then return false end
    end
    return true
end

local function line_of(text, pos)
    local n = 1
    for _ in string.gmatch(string.sub(text, 1, pos - 1), '\n') do n = n + 1 end
    return n
end

-- The first `return` in a statement that leaves the handler without cancelling the action (a return right after
-- gFunc.CancelAction() is fine: a cancelled action's rules don't run either); nil when there is none.
local function early_return(scope, list)
    for i, st in ipairs(list or {}) do
        if st.k == 'return' then
            local cancelled = false
            for j = 1, i - 1 do
                if (list[j].k == 'callstat') and (call_path(scope, list[j].call) == 'gFunc.CancelAction') then cancelled = true end
            end
            if not cancelled then return st end
        elseif st.k == 'if' then
            for _, br in ipairs(st.branches) do
                local r = early_return(scope, br.body)
                if r ~= nil then return r end
            end
            local r = early_return(scope, st.elseBody)
            if r ~= nil then return r end
        elseif (st.k == 'loop') or (st.k == 'do') then
            local r = early_return(scope, st.body)
            if r ~= nil then return r end
        end
    end
    return nil
end
-- An `if` on gData.GetPetAction(): HandleDefault's pet action branch (rules skip idle ones during a pet action too).
local function pet_branch(scope, st)
    if st.k ~= 'if' then return false end
    local c = unparen(st.branches[1].cond)
    local m = (c.k == 'bin') and meaning(scope, c.a) or meaning(scope, c)
    return (m ~= nil) and (m.kind == 'petAction')
end

-- A file function a check can read through: no arguments, only locals, then `return <check>`
-- (local function Night() local t = gData.GetEnvironment().Time; return (t >= 17) or (t < 7); end).
local function check_func(f)
    if (f == nil) or (f.params ~= 0) or (type(f.body) ~= 'table') or (#f.body == 0) then return nil end
    for i, st in ipairs(f.body) do
        if i < #f.body then
            if st.k ~= 'local' then return nil end
        elseif (st.k ~= 'return') or (#st.exprs ~= 1) then
            return nil
        end
    end
    return f.body
end
-- File-level: aliases (local ByName, Family = gcinclude.ByName, gcinclude.Family), literal lists (local X = T{...})
-- and functions a check can read through (check_func).
local function file_scope(chunk)
    local scope = { vars = {}, aliases = {}, lists = {}, funcs = {} }
    for _, st in ipairs(chunk) do
        if st.k == 'localfunc' then scope.funcs[st.name] = check_func(st) end
        if st.k == 'local' then
            for j, name in ipairs(st.names) do
                local e = st.exprs[j]
                local p = path_of(e)
                if (p ~= nil) and string.match(p, '^gcinclude%.[%w_]+$') then scope.aliases[name] = p end
                local list = (e ~= nil) and literal_list(scope, e) or nil
                if list ~= nil then scope.lists[name] = list end
            end
        end
    end
    return scope
end

-- text: the job file. The plan: each handler's top-level `if`s, converted or not (why); the rules in order; and the
-- splices Convert makes (each converted `if` out). Consecutive converted `if`s are a run; the last run of a
-- handler, with nothing after it that wears gear (up to HandleDefault's CheckDefault, or the handler's end), goes
-- where rules go by themselves. Any other run leaves one line where it was, `gcinclude.RulesAt('<Phase> <n>')`, and
-- its rules carry at = that spot, so they go on exactly where the code did (before a named set, after an early
-- return...).
-- An if whose check calls ByName (it puts on the set it finds, and says whether there was one): the calls stay as
-- code, in the same order (`not (ByName(a) or ByName(b))` keeps `if not ByName(a) then ByName(b) end`), and the
-- rest becomes rules on whether those sets exist. nil: no ByName in its checks; false and why: a shape it can't keep.
local function is_byname(scope, e)
    if (type(e) ~= 'table') or (e.k ~= 'call') or (e.method ~= nil) then return false end
    local p = call_path(scope, e)
    return (p == 'gcinclude.ByName') or (p == 'ByName')
end
local function any_byname(scope, node)
    if type(node) ~= 'table' then return false end
    if is_byname(scope, node) then return true end
    for _, v in pairs(node) do
        if (type(v) == 'table') and any_byname(scope, v) then return true end
    end
    return false
end
local function byname_chain(scope, e, out) -- ByName calls joined by `or`, under `not` / parentheses only
    e = unparen(e)
    if e == nil then return nil end
    if (e.k == 'un') and (e.op == 'not') then return byname_chain(scope, e.a, out) end
    if (e.k == 'bin') and (e.op == 'or') then
        if byname_chain(scope, e.a, out) == nil then return nil end
        return byname_chain(scope, e.b, out)
    end
    if is_byname(scope, e) then
        out[#out + 1] = e
        return out
    end
    return nil
end
local function keep_of(scope, text, st)
    local found = false
    for _, br in ipairs(st.branches) do if any_byname(scope, br.cond) then found = true end end
    if not found then return nil end
    if (#st.branches ~= 1) or (st.elseBody ~= nil) then
        return false, 'Its check puts on a set (ByName) in an if / elseif chain. Convert can split that only from a '
            .. 'plain if.'
    end
    local calls = byname_chain(scope, st.branches[1].cond, {})
    if calls == nil then
        return false, 'Its check mixes a set lookup (ByName) with other checks. Convert can split it only when the '
            .. 'check is just ByName calls joined by "or".'
    end
    local function src(c) return string.sub(text, c.s, c.e) end
    local keep = src(calls[#calls])
    if #calls == 1 then return keep .. ';' end
    for i = #calls - 1, 1, -1 do keep = 'if not ' .. src(calls[i]) .. ' then ' .. keep .. ' end' end
    return keep
end

-- opts (from gcconvertcheck): free = { [line of a run's first if] = true }: those runs go where rules go by
-- themselves (the check found the same gear); skip = { [handler] = why }: that handler's ifs stay code.
function C.Plan(text, opts)
    opts = opts or {}
    local chunk, err, at = C.Parse(text)
    if chunk == nil then return nil, 'the file does not parse here: ' .. tostring(err) .. (at and (' (line ' .. line_of(text, at) .. ')') or '') end
    local scope = file_scope(chunk)
    local plan = { handlers = {}, rules = {}, removals = {}, splices = {}, runs = {} }
    local setSlots = set_table(chunk)
    local funcs = {} -- the file's own functions, by the name a call uses: what they call counts too
    for _, st in ipairs(chunk) do
        if st.k == 'localfunc' then funcs[st.name] = st end
        if (st.k == 'assign') and (#st.targets == 1) and (st.exprs[1] ~= nil) and (st.exprs[1].k == 'func') then
            local p = path_of(st.targets[1])
            if p ~= nil then funcs[p] = st.exprs[1] end
        end
        if st.k == 'local' then
            for j, n in ipairs(st.names) do
                if (st.exprs[j] ~= nil) and (st.exprs[j].k == 'func') then funcs[n] = st.exprs[j] end
            end
        end
    end
    local used = {}
    for spot in string.gmatch(text, "gcinclude%.RulesAt%(%s*'([^']+)'") do used[spot] = true end
    for _, st in ipairs(chunk) do
        if (st.k == 'assign') and (#st.targets == 1) and (st.exprs[1] ~= nil) and (st.exprs[1].k == 'func') then
            local name = string.match(path_of(st.targets[1]) or '', '^profile%.(Handle%a+)$')
            local phase = name and HANDLERS[name]
            if phase ~= nil then
                local h = { name = name, phase = phase, items = {} }
                plan.handlers[#plan.handlers + 1] = h
                local hs = { vars = setmetatable({}, { __index = scope.vars }), aliases = scope.aliases, lists = scope.lists, funcs = scope.funcs }
                local body = st.exprs[1].body
                local stopAt = #body + 1 -- the place rules go by themselves: HandleDefault's CheckDefault, else the end
                for i, s in ipairs(body) do
                    if (phase == 'Default') and (s.k == 'callstat') and (call_path(hs, s.call) == 'gcinclude.CheckDefault') then
                        stopAt = i
                    end
                end
                local runs, cur, returned = {}, nil, false
                local function close() if cur ~= nil then runs[#runs + 1] = cur end cur = nil end
                for i, s in ipairs(body) do
                    if i >= stopAt then break end
                    if s.k == 'local' then
                        for j, n in ipairs(s.names) do
                            local m = (s.exprs[j] ~= nil) and meaning(hs, s.exprs[j]) or nil
                            if (m == nil) and (s.exprs[j] ~= nil) and (#s.names == #s.exprs) then
                                local c = cond_of(hs, s.exprs[j]) -- a local holding a condition: read as that condition
                                if c ~= nil then m = { kind = 'cond', cond = c } end
                            end
                            hs.vars[n] = m
                        end
                    elseif s.k == 'if' then
                        local snapshot = { vars = setmetatable({}, { __index = hs.vars }), aliases = hs.aliases, lists = hs.lists, funcs = hs.funcs }
                        for k, v in pairs(hs.vars) do snapshot.vars[k] = v end
                        local rules, why = convert_if(snapshot, s, {}, phase, {})
                        if (rules ~= nil) and (opts.skip ~= nil) and (opts.skip[name] ~= nil) then
                            rules, why = nil, opts.skip[name]
                        end
                        local keep, keepFailed = nil, false
                        if rules ~= nil then -- a check that puts on a set: that part stays code (keep), the rest rules
                            local k, kwhy = keep_of(hs, text, s)
                            if k == false then rules, why, keepFailed = nil, kwhy, true else keep = k end
                        end
                        local item = { line = line_of(text, s.s), s = s.s, e = s.e, ok = (rules ~= nil), why = why,
                            rules = rules, keep = keep }
                        if (rules == nil) and not keepFailed then -- GoomSwap's own steps every job file has: stay
                            local code = string.sub(text, s.s, s.e)
                            for _, std in ipairs(C.STANDARD) do
                                if string.find(code, std[1]) then item.standard, item.why = true, std[2] break end
                            end
                        end
                        h.items[#h.items + 1] = item
                        if item.ok then
                            cur = cur or { items = {}, returnedBefore = returned }
                            cur.items[#cur.items + 1] = item
                        else
                            close()
                        end
                    else
                        close()
                    end
                    if (s.k ~= 'local') and not ((phase == 'Default') and pet_branch(hs, s)) and (early_return(hs, { s }) ~= nil) then
                        returned = true -- what follows runs only when this didn't return
                    end
                end
                close()
                -- the last run goes by itself when nothing after it, up to the rules' place, wears gear
                local last = runs[#runs]
                if (last ~= nil) and not last.returnedBefore then
                    local after = last.items[#last.items]
                    local clear = true
                    for i, s in ipairs(body) do
                        if (i < stopAt) and (s.s > after.e) and (s.k ~= 'local') then
                            if s.k == 'callstat' then
                                if not NEUTRAL[call_path(hs, s.call)] then clear = false end
                            elseif not ((s.k == 'return') and (i == #body)) then
                                clear = false
                            end
                        end
                    end
                    last.free = clear
                end
                -- a run can be moved to the rules' own place when nothing before it may return, and everything after
                -- it up to there is code the same-gear check runs as the game does
                for _, run in ipairs(runs) do
                    local after = run.items[#run.items]
                    local movable = not run.returnedBefore
                    local mine = {} -- the slots the run's rules can wear
                    for _, item in ipairs(run.items) do
                        for _, r in ipairs(item.rules) do mine = union(mine, rule_slots(setSlots, r)) end
                    end
                    if mine.all then movable = false end
                    for i, s in ipairs(body) do
                        if movable and (i < stopAt) and (s.s > after.e) and ((not only_checked(hs, s, funcs, {}))
                            or overlap(mine, wears(hs, s, funcs, setSlots, {}))) then
                            movable = false
                        end
                    end
                    run.movable = movable
                    if movable and (opts.free ~= nil) and opts.free[run.items[1].line] then run.free = true end
                end
                local gone = {} -- this handler's removed ranges, for the unused locals below
                for _, run in ipairs(runs) do -- (an if that keeps code still reads its locals)
                    for _, item in ipairs(run.items) do
                        if item.keep == nil then gone[#gone + 1] = { item.s, item.e } end
                    end
                end
                local n = 0
                for _, run in ipairs(runs) do
                    local spot = nil
                    if not run.free then
                        repeat
                            n = n + 1
                            spot = phase .. ' ' .. n
                        until not used[spot]
                        used[spot] = true
                    end
                    plan.runs[#plan.runs + 1] = { handler = name, phase = phase, line = run.items[1].line, spot = spot,
                        movable = run.movable, free = run.free }
                    for k, item in ipairs(run.items) do
                        item.spot = spot
                        for _, r in ipairs(item.rules) do
                            r.at = spot
                            plan.rules[#plan.rules + 1] = r
                        end
                        local sp = C.Removal(text, item.s, item.e)
                        local ls = item.s
                        while (ls > 1) and (string.sub(text, ls - 1, ls - 1) ~= '\n') do ls = ls - 1 end
                        local ind = string.match(string.sub(text, ls, item.s - 1), '^[ \t]*$') and string.sub(text, ls, item.s - 1) or ''
                        if (k == 1) and (spot ~= nil) then -- the spot's line, where the first if was
                            local call = "gcinclude.RulesAt('" .. spot .. "');"
                            if sp[1] == ls then sp[3] = ind .. call .. '\n' else sp[3] = call .. ' ' end
                        end
                        if item.keep ~= nil then -- the set lookup stays, just before the rules' spot
                            if sp[1] == ls then sp[3] = ind .. item.keep .. '\n' .. sp[3] else sp[3] = item.keep .. ' ' .. sp[3] end
                        end
                        plan.removals[#plan.removals + 1] = { item.s, item.e }
                        plan.splices[#plan.splices + 1] = sp
                    end
                end
                -- a local only the converted ifs read (local power = BuffCount(...) + ...) goes with them
                if #gone > 0 then
                    local function removed(at)
                        for _, g in ipairs(gone) do
                            if (at >= g[1]) and (at <= g[2]) then return true end
                        end
                        return false
                    end
                    -- the code's own uses of nm after `from`, outside the removed ranges (comments and texts aren't uses)
                    local function read_after(node, nm, from)
                        if type(node) ~= 'table' then return false end
                        if (node.k == 'name') and (node.v == nm) and (type(node.s) == 'number') and (node.s > from)
                            and not removed(node.s) then
                            return true
                        end
                        for _, v in pairs(node) do
                            if (type(v) == 'table') and read_after(v, nm, from) then return true end
                        end
                        return false
                    end
                    for _, s in ipairs(body) do
                        if (s.k == 'local') and (#s.exprs == #s.names) then
                            local pure, used = true, false
                            for j, nm in ipairs(s.names) do
                                if (meaning(hs, s.exprs[j]) == nil) and (cond_of(hs, s.exprs[j]) == nil) then pure = false end
                                if read_after(body, nm, s.e) then used = true end
                            end
                            if pure and not used then
                                plan.splices[#plan.splices + 1] = C.Removal(text, s.s, s.e)
                                plan.locals = (plan.locals or 0) + 1
                            end
                        end
                    end
                end
            end
        end
    end
    return plan
end

-- What each code spot in the file comes just before: { ['Midcast 1'] = { short = 'skill set', long = "the set named
-- after the spell's skill", line = 441 } }. The rules marked with a spot go on there, so that code still wins the
-- slots both wear.
local WHAT = { Precast = 'spell', Midcast = 'spell', Ability = 'ability', Weaponskill = 'weapon skill', Item = 'item',
    Preshot = 'shot', Midshot = 'shot', Pet = "pet's move", Default = 'action' }
local WEAR_CALL = { ['gFunc.EquipSet'] = true, ['gcinclude.EquipSet'] = true, ['gcinclude.ByName'] = true,
    ['gFunc.Equip'] = true }
function C.Spots(text)
    local out = {}
    if (text == nil) or not string.find(text, 'RulesAt', 1, true) then return out, true end
    local chunk = C.Parse(text)
    if chunk == nil then return out, false end -- not read: no spot can be called missing
    local scope = file_scope(chunk)
    local setSlots, funcs = set_table(chunk), {}
    for _, st in ipairs(chunk) do
        if st.k == 'localfunc' then funcs[st.name] = st end
        if (st.k == 'assign') and (#st.targets == 1) and (st.exprs[1] ~= nil) and (st.exprs[1].k == 'func') then
            local p = path_of(st.targets[1])
            if p ~= nil then funcs[p] = st.exprs[1] end
        end
    end
    local function first_wear(node) -- the first call in node that wears gear (or calls the file's code that does)
        if type(node) ~= 'table' then return nil end
        if (node.k == 'call') and (node.method == nil) then
            local p = canon(scope, path_of(node.fn))
            if WEAR_CALL[p] then return node, p end
            if (p ~= nil) and (funcs[p] ~= nil) and (next(wears(scope, funcs[p].body, funcs, setSlots, {})) ~= nil) then
                return node, p
            end
        end
        local keys = {}
        for k, v in pairs(node) do if type(v) == 'table' then keys[#keys + 1] = k end end
        local function start(t) -- where a part starts (a list: its first statement)
            if type(t) ~= 'table' then return math.huge end
            if tonumber(t.s) ~= nil then return t.s end
            return start(t[1])
        end
        table.sort(keys, function(x, y) return start(node[x]) < start(node[y]) end) -- source order
        for _, k in ipairs(keys) do
            local c, p = first_wear(node[k])
            if c ~= nil then return c, p end
        end
        return nil
    end
    local hs = scope
    local function has_return(node)
        if type(node) ~= 'table' then return false end
        if node.k == 'return' then return true end
        if node.k == 'func' then return false end -- a function inside: its return is its own
        for _, v in pairs(node) do if (type(v) == 'table') and has_return(v) then return true end end
        return false
    end
    local function describe(call, p, phase)
        local scope = hs
        local line = line_of(text, call.s)
        local a = unparen(call.args[1])
        if WEAR_CALL[p] and (p ~= 'gFunc.Equip') and (a ~= nil) then
            if a.k == 'str' then return a.v, 'the set ' .. a.v, line end
            local nm = set_name_of(scope, a)
            if nm ~= nil then return nm, 'the set ' .. nm, line end
            local m = meaning(scope, a)
            if (m ~= nil) and (m.kind == 'field') and (m.base == 'action') then
                if m.field == 'Skill' then return 'skill set', "the set named after the spell's skill (['Healing Magic']...)", line end
                if m.field == 'Name' then
                    return 'named set', 'the set named after the ' .. (WHAT[phase] or 'action'), line
                end
                if m.field == 'Type' then return 'type set', "the set named after the action's type", line end
            end
            if (m ~= nil) and (m.kind == 'family') then return 'family set', "the set named after the spell's family", line end
            return 'named set', 'a set your code names (line ' .. line .. ')', line
        end
        if p == 'gFunc.Equip' then return 'line ' .. line, 'the item your code puts on at line ' .. line, line end
        return p, p .. ' (line ' .. line .. ')', line
    end
    for _, st in ipairs(chunk) do
        if (st.k == 'assign') and (#st.targets == 1) and (st.exprs[1] ~= nil) and (st.exprs[1].k == 'func') then
            local name = string.match(path_of(st.targets[1]) or '', '^profile%.(Handle%a+)$')
            local phase = name and HANDLERS[name]
            if phase ~= nil then
                local body = st.exprs[1].body
                hs = { vars = setmetatable({}, { __index = scope.vars }), aliases = scope.aliases, lists = scope.lists, funcs = scope.funcs }
                for i, s in ipairs(body) do
                    if s.k == 'local' then
                        for j, n in ipairs(s.names) do hs.vars[n] = (s.exprs[j] ~= nil) and meaning(hs, s.exprs[j]) or nil end
                    end
                    if (s.k == 'callstat') and (call_path(scope, s.call) == 'gcinclude.RulesAt') then
                        local a = unparen(s.call.args[1])
                        if (a ~= nil) and (a.k == 'str') then
                            local info = { short = 'end', long = 'the end of ' .. name, line = line_of(text, s.s) }
                            local found = false
                            for j = i + 1, #body do
                                local call, p = first_wear(body[j])
                                if call ~= nil then
                                    info.short, info.long, info.line = describe(call, p, phase)
                                    info.before, found = true, true
                                    break
                                end
                            end
                            if not found then -- nothing after it wears gear: it is there for a return above it
                                for j = i - 1, 1, -1 do
                                    if has_return(body[j]) then
                                        local ln = line_of(text, body[j].s)
                                        info.short = 'after line ' .. ln
                                        info.long = 'after line ' .. ln .. ', which can stop ' .. name .. ' first (then these '
                                            .. "rules don't go on either)"
                                        info.line = ln
                                        break
                                    end
                                end
                            end
                            out[a.v] = info
                        end
                    end
                end
            end
        end
    end
    return out, true
end

-- The named-set steps in the job file: { [phase] = { name = { line, text }, skill = ..., family = ..., type = ...,
-- ['skill_Precast'] = ... }, idle = { line } } for a ByName on the action's name, skill, family or type (with a fixed
-- suffix: spell.Skill .. '_Precast'), and gcinclude.EquipIdle (Idle_<wm>, Idle_<idleset>). A set by that name is
-- worn there with no rule (the builder says so).
local STEP_WORDS = { name = 'the set named after the %s', skill = "the set named after the spell's skill",
    family = "the set named after the spell's family", type = "the set named after the action's type" }
function C.NameSteps(text)
    local out = {}
    if text == nil then return out end
    local chunk = C.Parse(text)
    if chunk == nil then return out end
    local scope = file_scope(chunk)
    for _, st in ipairs(chunk) do
        if (st.k == 'assign') and (#st.targets == 1) and (st.exprs[1] ~= nil) and (st.exprs[1].k == 'func') then
            local name = string.match(path_of(st.targets[1]) or '', '^profile%.(Handle%a+)$')
            local phase = name and HANDLERS[name]
            if phase ~= nil then
                local hs = { vars = setmetatable({}, { __index = scope.vars }), aliases = scope.aliases, lists = scope.lists, funcs = scope.funcs }
                local steps = out[phase] or {}
                out[phase] = steps
                local function kind_of(a) -- what a ByName argument names: 'name', 'skill', 'family', 'type' (+ suffix)
                    a = unparen(a)
                    if a == nil then return nil end
                    if (a.k == 'bin') and (a.op == '..') then
                        local left, right = kind_of(a.a), unparen(a.b)
                        if (left ~= nil) and (right ~= nil) and (right.k == 'str') then return left .. right.v end
                        return nil
                    end
                    local m = meaning(hs, a)
                    if m == nil then return nil end
                    if m.kind == 'family' then return 'family' end
                    if (m.kind == 'field') and (m.base == 'action') then
                        return ({ Name = 'name', Skill = 'skill', Type = 'type' })[m.field]
                    end
                    return nil
                end
                local function walk(node)
                    if type(node) ~= 'table' then return end
                    if (node.k == 'call') and (node.method == nil) then
                        local p = canon(hs, path_of(node.fn))
                        if (p == 'gcinclude.ByName') or (p == 'ByName') then
                            local k = kind_of(node.args[1])
                            if (k ~= nil) and (steps[k] == nil) then
                                local base, suffix = string.match(k, '^(%a+)(.*)$')
                                local words = string.format(STEP_WORDS[base] or 'its set', WHAT[phase] or 'action')
                                steps[k] = { line = line_of(text, node.s), text = words .. ((suffix ~= '') and (' + ' .. suffix) or '') }
                            end
                        elseif (p == 'gcinclude.EquipIdle') and (out.idle == nil) then
                            out.idle = { line = line_of(text, node.s) }
                        end
                    end
                    for _, v in pairs(node) do if type(v) == 'table' then walk(v) end end
                end
                for _, s in ipairs(st.exprs[1].body) do
                    if s.k == 'local' then
                        for j, n in ipairs(s.names) do hs.vars[n] = (s.exprs[j] ~= nil) and meaning(hs, s.exprs[j]) or nil end
                    end
                    walk(s)
                end
            end
        end
    end
    return out
end

-- The splice taking a statement (s..e) out: its whole lines when nothing else is on them (a trailing ';' and
-- comment go too), else just the statement.
function C.Removal(text, s, e)
    local ls = s
    while (ls > 1) and (string.sub(text, ls - 1, ls - 1) ~= '\n') do ls = ls - 1 end
    local le = e + 1
    local rest = string.match(text, '^[ \t]*;?[ \t]*()', le)
    local tail = string.match(text, '^%-%-[^\n]*()', rest) or rest
    local nl = string.sub(text, tail, tail)
    if string.match(string.sub(text, ls, s - 1), '^[ \t]*$') and ((nl == '\n') or (nl == '') or (nl == '\r')) then
        local finish = tail
        if string.sub(text, finish, finish) == '\r' then finish = finish + 1 end
        if string.sub(text, finish, finish) == '\n' then finish = finish + 1 end
        return { ls, finish, '' }
    end
    local finish = string.match(text, '^[ \t]*;?()', le)
    return { s, finish, '' }
end

-- == Adopt: a plain LuAshitacast job file (no GoomSwap) made a GoomSwap one, its own code kept: GoomSwap loads at the
-- top, starts in OnLoad, stops in OnUnload, takes /lac fwd commands in HandleCommand and adds its layers at the end of
-- HandleDefault. Its sets keep their names; GoomSwap's own sets (Dt, TH, Idle_Regen...) work once you make them. ==
function C.IsGoomSwap(text) return string.find(text or '', 'gcinclude.lua', 1, true) ~= nil end
-- The splices and what each does (lines); nil and why when it can't.
function C.Adopt(text)
    if C.IsGoomSwap(text) then return nil, 'it already loads GoomSwap' end
    local chunk, err = C.Parse(text)
    if chunk == nil then return nil, 'the file does not parse: ' .. tostring(err) end
    local splices, lines, profileAt, returnAt = {}, {}, nil, nil
    local funcs = {}
    for _, st in ipairs(chunk) do
        if (st.k == 'local') and (st.names[1] == 'profile') then profileAt = st.e end
        if (st.k == 'assign') and (#st.targets == 1) and (st.exprs[1] ~= nil) and (st.exprs[1].k == 'func') then
            local name = string.match(path_of(st.targets[1]) or '', '^profile%.([%w_]+)$')
            if name ~= nil then funcs[name] = st.exprs[1] end
        end
        if st.k == 'return' then returnAt = st.s end
    end
    if profileAt == nil then return nil, 'no `local profile = {}` line' end
    if returnAt == nil then return nil, 'no `return profile` at the end' end
    local function line_after(pos)
        local nl = string.find(text, '\n', pos, true)
        return (nl ~= nil) and (nl + 1) or (#text + 1)
    end
    local at = line_after(profileAt)
    splices[#splices + 1] = { at, at, "gcinclude = gFunc.LoadFile('common\\\\gcinclude.lua');\n" }
    lines[#lines + 1] = 'GoomSwap loaded at the top (gcinclude)'
    local function before_end(f, call)
        local endAt = f.e - 2 -- the function's closing `end`
        local ls = endAt
        while (ls > 1) and (string.sub(text, ls - 1, ls - 1) ~= '\n') do ls = ls - 1 end
        local ind = string.match(string.sub(text, ls, endAt - 1), '^([ \t]*)$')
        if ind == nil then -- `end` shares its line: the call goes just before it
            splices[#splices + 1] = { endAt, endAt, call .. ' ' }
        else
            splices[#splices + 1] = { ls, ls, ind .. '    ' .. call .. '\n' }
        end
    end
    local adds = {}
    local WANT = {
        { 'OnLoad', 'gcinclude.Initialize();', 'OnLoad starts GoomSwap (gcinclude.Initialize)' },
        { 'OnUnload', 'gcinclude.Unload();', 'OnUnload stops it (gcinclude.Unload)' },
        { 'HandleDefault', 'gcinclude.CheckDefault();', "HandleDefault ends with GoomSwap's layers (gcinclude.CheckDefault)" },
    }
    for _, w in ipairs(WANT) do
        if funcs[w[1]] ~= nil then
            before_end(funcs[w[1]], w[2])
        else
            adds[#adds + 1] = 'profile.' .. w[1] .. ' = function()\n    ' .. w[2] .. '\nend\n'
        end
        lines[#lines + 1] = w[3]
    end
    local hc = funcs.HandleCommand
    if hc ~= nil then
        local param = string.match(text, '^function%s*%(%s*([%a_][%w_]*)', hc.s)
        if param == nil then return nil, 'HandleCommand takes no arguments: GoomSwap\'s commands need them' end
        before_end(hc, 'gcinclude.HandleCommands(' .. param .. ');')
    else
        adds[#adds + 1] = 'profile.HandleCommand = function(args)\n    gcinclude.HandleCommands(args);\nend\n'
    end
    lines[#lines + 1] = "HandleCommand passes GoomSwap's commands on (/wm, /gcedit...)"
    if #adds > 0 then
        local ls = returnAt
        while (ls > 1) and (string.sub(text, ls - 1, ls - 1) ~= '\n') do ls = ls - 1 end
        splices[#splices + 1] = { ls, ls, table.concat(adds, '\n') .. '\n' }
    end
    return { splices = splices, lines = lines }
end

return C
