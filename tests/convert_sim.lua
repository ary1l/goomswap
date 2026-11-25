-- Convert's promise, checked: for every example job file, the converted file (its handlers with the converted `if`s
-- taken out, gcinclude.RulesAt spots in) plus the rules wears exactly what the original handlers wore, slot by slot,
-- over many random game states. The game is faked: sets are the file's own, the engine's helpers are simple stand-ins
-- used the same way on both sides.
local C = gFunc.LoadFile('common\\gcconvert.lua')
local R = gFunc.LoadFile('common\\gcrules.lua')
local F = gFunc.LoadFile('common\\gcsetfile.lua')
local SLOTS = {}
for _, s in ipairs(R.SLOTS) do SLOTS[s] = true end
string.contains = string.contains or function(s, v) return string.find(s, v, 1, true) ~= nil end

local function literals(text) -- every quoted text in the file: names to try
    local out, seen = {}, {}
    for q in string.gmatch(text, "'([^'\n]+)'") do
        if not seen[q] then seen[q], out[#out + 1] = true, q end
    end
    return out
end

-- One fake game state, and the engine stand-ins that read it.
local function world(state, sets, record)
    local gear = {}
    local W = { gear = gear }
    local function find(name)
        if type(name) ~= 'string' then return nil end
        for k, v in pairs(sets) do
            if (type(k) == 'string') and (string.lower(k) == string.lower(name)) and (type(v) == 'table') then return v end
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
    local gc = setmetatable({ settings = setmetatable({}, { __index = function() return nil end }) }, { __index = function(_, k)
        return function() record('gcinclude.' .. k) return false end
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

-- The file loaded against a world: its profile.
local function load(text, W)
    local env = setmetatable({ gData = W.gData, gFunc = W.gFunc, gcdisplay = W.gcdisplay, AshitaCore = W.AshitaCore,
        gSettings = {}, T = function(t) return setmetatable(t, { __index = { contains = function(self, v)
            for _, x in ipairs(self) do if x == v then return true end end return false end } }) end,
        string = string, table = table, math = math, pairs = pairs, ipairs = ipairs, type = type, tostring = tostring,
        tonumber = tonumber, next = next, print = function() end, select = select, setmetatable = setmetatable,
        unpack = unpack, pcall = pcall, error = error }, { __index = function(_, k) return nil end })
    env._G = env
    local chunk = assert(loadstring(text))
    setfenv(chunk, env)
    env.gcinclude = W.gc
    local profile = chunk()
    return profile, env
end

local PHASE_OF = C.HANDLERS
local function random_state(lits, rnd)
    local function pick(list) return list[rnd(#list)] end
    local statuses = { 'Idle', 'Engaged', 'Resting' }
    local buffs = {}
    for _, l in ipairs(lits) do if rnd(4) == 1 then buffs[l] = 1 end end
    local cycles, toggles = {}, {}
    for _, c in ipairs({ 'MeleeSet', 'NukeSet', 'Weapons', 'Weapon', 'TankSet', 'IdleSet', 'WsSet', 'PupMode', 'Hoxne' }) do
        cycles[c] = (rnd(2) == 1) and pick(lits) or ((rnd(2) == 1) and 'Default' or 'None')
    end
    for _, t in ipairs({ 'DTset', 'MDTset', 'Kite', 'TH', 'SIR', 'PROC', 'Burst', 'String', 'SongLock', 'Death', 'Aminon' }) do
        toggles[t] = rnd(2) == 1
    end
    local elements = { 'Fire', 'Ice', 'Wind', 'Earth', 'Thunder', 'Water', 'Light', 'Dark' }
    local skills = { 'Healing Magic', 'Enhancing Magic', 'Enfeebling Magic', 'Elemental Magic', 'Dark Magic', 'Divine Magic',
        'Singing', 'Ninjutsu', 'Blue Magic', 'Geomancy', 'Summoning' }
    local name = pick(lits)
    if rnd(3) == 1 then name = name .. ' II' end
    return {
        player = { Status = pick(statuses), HPP = rnd(100), MPP = rnd(100), TP = rnd(3000), IsMoving = rnd(2) == 1,
            SubJob = pick({ 'NIN', 'DNC', 'WHM', 'RDM', 'SCH', 'WAR' }), MainJobSync = 99, Name = 'Me' },
        action = { Name = name, Skill = pick(skills), Element = pick(elements), Type = pick(lits) },
        target = (rnd(5) == 1) and nil or { Name = (rnd(2) == 1) and 'Me' or 'Other', Type = pick({ 'PC', 'Monster', 'NPC' }), HPP = rnd(100), Distance = rnd(20) },
        env = { WeatherElement = pick(elements), DayElement = pick(elements), Area = pick(lits), Time = rnd(24) },
        pet = (rnd(2) == 1) and { Name = pick(lits), HPP = rnd(100), TP = rnd(3000), Status = pick(statuses) } or nil,
        petAction = nil, buffs = buffs, cycles = cycles, toggles = toggles, burst = rnd(2) == 1, dw = rnd(2) == 1,
        zoneName = pick(lits),
    }
end

local function gear_text(g)
    local out = {}
    for _, s in ipairs(R.SLOTS) do if g[s] ~= nil then out[#out + 1] = s .. '=' .. g[s] end end
    return table.concat(out, ' ')
end

local function check_file(path, rounds)
    local text = io.open(path):read('*a')
    local plan = assert(C.Plan(text))
    local converted = assert(F.Apply(text, plan.splices))
    local compiled, problems = R.Compile(plan.rules)
    assert(#problems == 0, problems[1])
    local lits = literals(text)
    local seed = 0
    for i = 1, #path do seed = seed + string.byte(path, i) end
    math.randomseed(seed)
    local rnd = function(n) return math.random(n) end
    for _, h in ipairs(plan.handlers) do
        for round = 1, rounds do
            local state = random_state(lits, rnd)
            -- original
            local recA = function() end
            local A = world(state, {}, recA)
            local profA = load(text, A)
            local setsA = profA.Sets or {}
            local WA = world(state, setsA, recA)
            profA = load(text, WA)
            local okA, errA = pcall(profA[h.name])
            -- converted: rules at CheckDefault (Default), after the handler (others), and at the spots
            local WB = world(state, {}, recA)
            local profB0 = load(converted, WB)
            WB = world(state, profB0.Sets or {}, recA)
            local profB = load(converted, WB)
            local ran = false
            if h.phase == 'Default' then
                WB.onCheckDefault = function() ran = true; R.Run(compiled, 'Default', 'job', WB.api) end
            end
            WB.onRulesAt = function(at) return (R.RunAt(compiled, at, WB.api)) end
            local okB, errB = pcall(profB[h.name])
            if okB and not WB.cancelled then
                if h.phase == 'Default' then
                    if not ran then R.Run(compiled, 'Default', 'job', WB.api) end
                else
                    local _, n = R.Run(compiled, h.phase, 'job', WB.api)
                    if (n > 0) and WB.thWorn then WB.gc.CheckTH() end
                end
            end
            if okA ~= okB then error(path .. ' ' .. h.name .. ': one side errored: ' .. tostring(errA or errB)) end
            local a, b = gear_text(WA.gear), gear_text(WB.gear)
            if a ~= b or (WA.cancelled ~= WB.cancelled) then
                error(path .. ' ' .. h.name .. ' round ' .. round .. ':\n  code:  ' .. a .. '\n  rules: ' .. b)
            end
        end
    end
    return #plan.rules
end

local tests = {}
local files = {}
for _, job in ipairs({ 'BLM', 'BLU', 'BRD', 'BST', 'COR', 'DNC', 'DRG', 'DRK', 'GEO', 'MNK', 'NIN', 'PLD', 'PUP', 'RDM',
    'RNG', 'RUN', 'SAM', 'SCH', 'SMN', 'THF', 'WAR', 'WHM' }) do
    files[#files + 1] = 'examples/' .. job .. '.lua'
end
for _, f in ipairs(files) do
    tests[#tests + 1] = { 'converted ' .. f .. ' wears what its code did', function() check_file(f, 300) end }
end
return tests
