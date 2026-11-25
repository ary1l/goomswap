-- Convert's same-gear check, run on your own job file when you convert it: the converted file (its handlers with the
-- converted `if`s taken out, gcinclude.RulesAt spots in) plus the rules must wear exactly what the original handlers
-- wore, slot by slot, over many random game states. The game is faked: sets are the file's own; the engine's helpers
-- are simple stand-ins, the same on both sides, so only the file's own code and the rules are compared.
-- K.Run also moves runs of ifs to the rules' own place (no code spot) when the gear stays the same.
local C = gFunc.LoadFile('common\\gcconvert.lua')
local R = gFunc.LoadFile('common\\gcrules.lua')
local F = gFunc.LoadFile('common\\gcsetfile.lua')
local K = {}
local SLOTS = {}
for _, s in ipairs(R.SLOTS) do SLOTS[s] = true end
local function contains(s, v) return string.find(s, v, 1, true) ~= nil end

-- Every quoted text in the file: names to try. names: without the gear (Main = 'Yagrush'), so a spell, ability or
-- mode the code checks comes up often enough.
local function literals(text)
    local out, names, seen, gear = {}, {}, {}, {}
    for key, q in string.gmatch(text, "([%w_]+)%s*=%s*'([^'\n]+)'") do
        if SLOTS[key] or (key == 'Name') then gear[q] = true end
    end
    local function add(q)
        if seen[q] then return end
        seen[q], out[#out + 1] = true, q
        if not gear[q] then names[#names + 1] = q end
    end
    for q in string.gmatch(text, "'([^'\n]+)'") do add(q) end
    for q in string.gmatch(text, '"([^"\n]+)"') do add(q) end
    if #out == 0 then out[1] = 'None' end
    if #names == 0 then names[1] = out[1] end
    return out, names
end

-- A small seeded random source (Park-Miller): the game's math.random is left alone.
local function source(seed)
    local x = (seed % 2147483646) + 1
    return function(n)
        x = (x * 16807) % 2147483647
        return math.floor(x / 2147483647 * n) + 1
    end
end

-- An engine value the check has no stand-in for: an empty list you can also call (false), so
-- `gcinclude.BluMagDebuff:contains(name)` and `gcinclude.Something()` both run.
local EMPTY_META = { __index = { contains = function() return false end }, __call = function() return false end }
-- One fake game state, and the engine stand-ins that read it. engine: the loaded gcinclude, when there is one: its
-- data (spell lists, settings) is read as it is, the same on both sides.
local function world(state, record, engine)
    local gear = {}
    local W = { gear = gear, sets = {} }
    local function find(name)
        if type(name) ~= 'string' then return nil end
        local l = string.lower(name)
        for k, v in pairs(W.sets) do
            if (type(k) == 'string') and (string.lower(k) == l) and (type(v) == 'table') then return v end
        end
        return nil
    end
    local function wear(set)
        if type(set) == 'string' then set = find(set) end
        if type(set) ~= 'table' then return end
        for slot, v in pairs(set) do
            if SLOTS[slot] then gear[slot] = (type(v) == 'table') and tostring(v.Name) or tostring(v) end
        end
    end
    W.find, W.wear = find, wear
    local function byname(name)
        local set = find(name)
        if set == nil then return false end
        wear(set)
        local mode = state.cycles.MeleeSet
        if (mode ~= nil) and (mode ~= 'Default') then wear(find(name .. '_' .. mode)) end
        return true
    end
    W.byname = byname
    local settings = ((engine ~= nil) and (type(engine.settings) == 'table')) and engine.settings or {}
    local gc = setmetatable({ settings = settings }, { __index = function(_, k)
        local v = (engine ~= nil) and rawget(engine, k) or nil
        if type(v) == 'table' then return v end -- data: as the game has it
        record('gcinclude.' .. k)
        return setmetatable({}, EMPTY_META)
    end })
    gc.ByName = byname
    gc.FindSet = find
    gc.FindFilled = find
    gc.EquipSet = wear
    gc.Family = function(n) return (string.gsub(n or '', ' [IVX]+$', '')) end
    gc.BuffCount = function(b) return state.buffs[b] or 0 end
    gc.BurstWanted = function() return state.burst end
    gc.CanDualWield = function() return state.dw end
    gc.EquipIdle = function() byname('Idle') end
    gc.EquipMode = function(p) byname(p .. '_Default') end
    gc.CheckWsBailout = function() return true end
    gc.CheckTH = function() if state.toggles.TH then wear(find('TH')); W.thWorn = true end end
    gc.RangedAcc = function() return state.cycles.MeleeSet == 'Acc' end
    gc.IsWeaponValue = function(v) return v ~= 'None' end
    gc.CheckDefault = function() if W.onCheckDefault then W.onCheckDefault() end end
    gc.RulesAt = function(at) if W.onRulesAt then return W.onRulesAt(at) end return false end
    W.gc = gc
    local function action() return state.action end
    W.gData = {
        GetPlayer = function() return state.player end,
        GetAction = action,
        GetActionTarget = function() return state.target end,
        GetEnvironment = function() return state.env end,
        GetPet = function() return state.pet end,
        GetPetAction = function() return state.petAction end,
        GetBuffCount = function(b) return state.buffs[b] or 0 end,
        GetEquipment = function() return {} end,
    }
    W.gFunc = {
        EquipSet = wear,
        Equip = function(slot, item) gear[slot] = (type(item) == 'table') and tostring(item.Name) or tostring(item) end,
        CancelAction = function() W.cancelled = true end,
        LoadFile = function() return gc end,
        Combine = function(a, b) local o = {} for k, v in pairs(a or {}) do o[k] = v end for k, v in pairs(b or {}) do o[k] = v end return o end,
        Message = function() end, Echo = function() end, Error = function() end,
    }
    W.gcdisplay = { GetCycle = function(n) return state.cycles[n] or 'None' end,
        GetToggle = function(n) return state.toggles[n] == true end, GetCycleValues = function() return {} end }
    local ashita
    ashita = setmetatable({}, { __index = function(_, k)
        if k == 'GetMemberName' then return function() return 'Me' end end
        if k == 'GetString' then return function() return state.zoneName end end
        return function() return ashita end
    end })
    W.AshitaCore = ashita
    W.api = {
        player = function() return state.player end, action = action, target = function() return state.target end,
        env = function() return state.env end, pet = function() return state.pet end,
        petAction = function() return state.petAction end, me = function() return 'Me' end,
        buff = function(b) return state.buffs[b] or 0 end, cycle = function(n) return state.cycles[n] or 'None' end,
        toggle = function(n) return state.toggles[n] == true end, burst = function() return state.burst end,
        dualWield = function() return state.dw end, inCombat = function() return false end, family = gc.Family,
        wear = function(name, exact) if exact then wear(find(name)) else byname(name) end end,
        equip = function(slot, item) W.gFunc.Equip(slot, item) end,
        cancel = function() W.cancelled = true end,
    }
    return W
end

local function tlist(t)
    return setmetatable(t, { __index = { contains = function(self, v)
        for _, x in ipairs(self) do if x == v then return true end end
        return false
    end } })
end
local STR = setmetatable({ contains = string.contains or contains }, { __index = string })

-- The file run against a world (its compiled chunk, run afresh): its profile.
local function load(chunk, W)
    local env = setmetatable({ gData = W.gData, gFunc = W.gFunc, gcdisplay = W.gcdisplay, AshitaCore = W.AshitaCore,
        gSettings = {}, T = tlist, string = STR, table = table, math = math, bit = bit, pairs = pairs, ipairs = ipairs,
        type = type, tostring = tostring, tonumber = tonumber, next = next, print = function() end, select = select,
        setmetatable = setmetatable, getmetatable = getmetatable, unpack = unpack, pcall = pcall, error = error,
        os = { time = os.time, clock = os.clock, date = os.date } }, { __index = function() return nil end })
    env._G = env
    setfenv(chunk, env)
    env.gcinclude = W.gc
    local profile = chunk()
    if type(profile) ~= 'table' then error('the file does not return its profile') end
    W.sets = (type(profile.Sets) == 'table') and profile.Sets or {}
    return profile
end

local function random_state(lits, rnd, names)
    local function pick(list) return list[rnd(#list)] end
    local statuses = { 'Idle', 'Engaged', 'Resting' }
    local buffs = {}
    for _, l in ipairs(names) do if rnd(4) == 1 then buffs[l] = 1 end end
    local cycles, toggles = {}, {}
    for _, c in ipairs({ 'MeleeSet', 'NukeSet', 'Weapons', 'Weapon', 'TankSet', 'IdleSet', 'WsSet', 'PupMode', 'Hoxne' }) do
        cycles[c] = (rnd(2) == 1) and pick(names) or ((rnd(2) == 1) and 'Default' or 'None')
    end
    for _, t in ipairs({ 'DTset', 'MDTset', 'Kite', 'TH', 'SIR', 'PROC', 'Burst', 'String', 'SongLock', 'Death', 'Aminon' }) do
        toggles[t] = rnd(2) == 1
    end
    local elements = { 'Fire', 'Ice', 'Wind', 'Earth', 'Thunder', 'Water', 'Light', 'Dark' }
    local skills = { 'Healing Magic', 'Enhancing Magic', 'Enfeebling Magic', 'Elemental Magic', 'Dark Magic', 'Divine Magic',
        'Singing', 'Ninjutsu', 'Blue Magic', 'Geomancy', 'Summoning' }
    local name = pick(names)
    if rnd(3) == 1 then name = name .. ' II' end
    return {
        player = { Status = pick(statuses), HPP = rnd(100), MPP = rnd(100), TP = rnd(3000), IsMoving = rnd(2) == 1,
            SubJob = pick({ 'NIN', 'DNC', 'WHM', 'RDM', 'SCH', 'WAR' }), MainJobSync = 99, Name = 'Me' },
        action = { Name = name, Skill = pick(skills), Element = pick(elements), Type = pick(names) },
        target = (rnd(5) == 1) and ((rnd(2) == 1) and {} or nil) or { Name = (rnd(2) == 1) and 'Me' or 'Other',
            Type = pick({ 'PC', 'Monster', 'NPC' }), HPP = rnd(100), Distance = rnd(20) },
        env = (rnd(10) == 1) and nil or { WeatherElement = pick(elements), DayElement = pick(elements), Area = pick(lits),
            Time = rnd(24) },
        pet = (rnd(2) == 1) and { Name = pick(names), HPP = rnd(100), TP = rnd(3000), Status = pick(statuses) } or nil,
        petAction = nil, buffs = buffs, cycles = cycles, toggles = toggles, burst = rnd(2) == 1, dw = rnd(2) == 1,
        zoneName = pick(names),
    }
end

local function gear_text(g)
    local out = {}
    for _, s in ipairs(R.SLOTS) do if g[s] ~= nil then out[#out + 1] = s .. ' ' .. g[s] end end
    return (#out > 0) and table.concat(out, ', ') or 'nothing'
end

local PHASE = C.HANDLERS
-- One handler, original against converted, `rounds` random states. true; or false, what differed, and why ('gear':
-- they wear different gear; 'error': the handler errors here in most rounds, so too little was compared to tell).
-- tick: called after each round (the editor's job yields there).
function K.Same(text, plan, handler, rounds, seed, tick, engine)
    local converted, err = F.Apply(text, plan.splices)
    if converted == nil then return false, 'the converted file could not be made: ' .. tostring(err) end
    local compiled, problems = R.Compile(plan.rules)
    if #problems > 0 then return false, problems[1] end
    local chunkA, eA = loadstring(text)
    if chunkA == nil then return false, 'your file does not load: ' .. tostring(eA) end
    local chunkB, eB = loadstring(converted)
    if chunkB == nil then return false, 'the converted file does not load: ' .. tostring(eB) end
    local phase = PHASE[handler]
    local lits, names = literals(text)
    local rnd = source(seed or #text)
    local none = function() end
    local bothErr, lastErr = 0, nil -- rounds where both sides stopped with an error: nothing was compared after it
    for round = 1, rounds do
        local state = random_state(lits, rnd, names)
        local WA = world(state, none, engine)
        local profA = load(chunkA, WA)
        local okA, errA = pcall(profA[handler])
        local WB = world(state, none, engine)
        local profB = load(chunkB, WB)
        local ran = false
        if phase == 'Default' then
            WB.onCheckDefault = function() ran = true; R.Run(compiled, 'Default', 'job', WB.api) end
        end
        WB.onRulesAt = function(at) return (R.RunAt(compiled, at, WB.api)) end
        local okB, errB = pcall(profB[handler])
        if okB and not WB.cancelled then
            if phase == 'Default' then
                if not ran then R.Run(compiled, 'Default', 'job', WB.api) end
            else
                local _, n = R.Run(compiled, phase, 'job', WB.api)
                if (n > 0) and WB.thWorn then WB.gc.CheckTH() end
            end
        end
        if okA ~= okB then
            return false, handler .. ': ' .. (okA and 'the converted one' or 'yours') .. ' stops with an error ('
                .. tostring(errA or errB) .. ')', 'gear'
        end
        if not okA then bothErr, lastErr = bothErr + 1, errA end
        local a, b = gear_text(WA.gear), gear_text(WB.gear)
        if (a ~= b) or (WA.cancelled ~= WB.cancelled) then
            local what = (a ~= b) and ('yours wears ' .. a .. '; the rules wear ' .. b)
                or ((WA.cancelled and 'yours cancels it' or 'the rules cancel it'))
            return false, handler .. ' (' .. (state.action and state.action.Name or '') .. '): ' .. what, 'gear'
        end
        if tick ~= nil then tick() end
    end
    if bothErr * 2 > rounds then
        return false, handler .. ' stops with an error here in ' .. bothErr .. ' of ' .. rounds .. ' rounds ('
            .. tostring(lastErr) .. ')', 'error'
    end
    return true
end

local function count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
-- The checked plan: runs moved to the rules' own place where the gear stays the same, then every handler checked;
-- one that differs keeps its ifs as code. plan.checked = { rounds, handlers, freed, skipped = { [handler] = why } };
-- plan.checked.unavailable = why, when the file can't be run here (the plan is then the unchecked one, as before).
-- o: { rounds = 400, trialRounds = 300, tick = fn, engine = gcinclude }
function K.Run(text, o)
    o = o or {}
    local rounds, trial = o.rounds or 400, o.trialRounds or 300
    local plan0, why = C.Plan(text)
    if plan0 == nil then return nil, why end
    local ok, res = pcall(function()
        local free = {}
        for _, run in ipairs(plan0.runs) do
            if run.movable and not run.free then
                local f = {}
                for k in pairs(free) do f[k] = true end
                f[run.line] = true
                local tried = C.Plan(text, { free = f })
                if K.Same(text, tried, run.handler, trial, run.line, o.tick, o.engine) then free[run.line] = true end
            end
        end
        local plan = C.Plan(text, { free = free })
        local skip, checked = {}, 0
        for _, h in ipairs(plan.handlers) do
            local any = false
            for _, it in ipairs(h.items) do if it.ok then any = true end end
            if any then
                checked = checked + 1
                local same, diff, kind = K.Same(text, plan, h.name, rounds, #text + checked, o.tick, o.engine)
                if (not same) and (kind == 'gear') then -- its moved runs back in their code spots, then once more
                    local back = false
                    for _, run in ipairs(plan.runs) do
                        if (run.handler == h.name) and free[run.line] then free[run.line], back = nil, true end
                    end
                    if back then
                        plan = C.Plan(text, { free = free })
                        same, diff, kind = K.Same(text, plan, h.name, rounds, #text + checked, o.tick, o.engine)
                    end
                end
                if not same then
                    skip[h.name] = (kind == 'error') and ('Convert\'s check could not run this part of your file, so it '
                        .. 'stays code: ' .. diff) or ('Convert\'s check found different gear: ' .. diff)
                end
            end
        end
        if next(skip) ~= nil then plan = C.Plan(text, { free = free, skip = skip }) end
        local freed = 0
        for _, run in ipairs(plan.runs) do if free[run.line] then freed = freed + 1 end end
        plan.checked = { rounds = rounds, handlers = checked, freed = freed, skipped = skip, skippedCount = count(skip) }
        return plan
    end)
    if ok then return res end
    plan0.checked = { unavailable = tostring(res) }
    return plan0
end

-- The editor's check, a little each frame: job.Step(seconds) -> done; job.plan once done.
function K.Job(text, o)
    o = o or {}
    local job = { done = false, progress = 0 }
    local plan0 = C.Plan(text)
    local total, n = 1, 0
    if plan0 ~= nil then
        local runs, handlers = 0, 0
        for _, run in ipairs(plan0.runs) do if run.movable and not run.free then runs = runs + 1 end end
        for _, h in ipairs(plan0.handlers) do
            for _, it in ipairs(h.items) do if it.ok then handlers = handlers + 1 break end end
        end
        total = runs * (o.trialRounds or 300) + handlers * (o.rounds or 400)
    end
    local co = coroutine.create(function()
        return K.Run(text, { rounds = o.rounds, trialRounds = o.trialRounds, engine = o.engine,
            tick = function() n = n + 1; coroutine.yield() end })
    end)
    function job.Step(seconds)
        if job.done then return true end
        local stop = os.clock() + (seconds or 0.004)
        repeat
            local ok, res, why = coroutine.resume(co)
            if coroutine.status(co) == 'dead' then
                job.done = true
                if ok then job.plan, job.why = res, why else job.plan, job.why = nil, tostring(res) end
                job.progress = 1
                return true
            end
        until os.clock() >= stop
        job.progress = math.min(0.99, n / math.max(1, total))
        return false
    end
    return job
end

return K
