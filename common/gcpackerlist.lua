-- LuAshitacast's own Packer list (profile.Packer): what `/lac gear` and `/lac validate` hand the Packer plugin, with
-- the gear of every set in profile.Sets. LAC only looks at those sets' own slots (integration.lua CreateOrderStruct),
-- so at load GoomSwap adds, in memory only (the file is never written), what that misses:
--   - char.lua's Packer (else goomswap-shared.lua's): items kept on every job, as { ['Echo Drops'] = 'stack' };
--   - sets inside sets (Buffs = { ['Haste'] = {...} }, Buffs_Ws, Buffs_Midcast);
--   - GoomSwap's own sets (Holy_Water, Sleeping, Doomed) and char.lua's `sets`;
--   - the items its commands and layers wear (Warp Ring, obis, Moonshade...), only the ones you own.
-- LAC counts: a number or 'all'; 'stack' (or true) becomes the item's stack size. The larger count of two entries for
-- the same item wins (LAC's IntegrateItems). Pure: lookups come in as functions.
local M = {}

M.SLOTS = { Main = true, Sub = true, Range = true, Ammo = true, Head = true, Neck = true, Ear1 = true, Ear2 = true,
    Body = true, Hands = true, Ring1 = true, Ring2 = true, Back = true, Waist = true, Legs = true, Feet = true }
local KEYWORDS = { displaced = true, remove = true, ignore = true } -- slot words, not items (LAC skips them too)
local SELECT = { 'AugPath', 'AugRank', 'AugTrial', 'Augment' } -- what tells two copies apart (LAC compares these)

-- A slot's value as a LAC entry ({ Name = ..., augments }); nil for a slot word or anything else.
function M.Entry(v)
    local name = (type(v) == 'table') and v.Name or v
    if (type(name) ~= 'string') or (name == '') or KEYWORDS[string.lower(name)] then return nil end
    local e = { Name = name }
    if type(v) == 'table' then
        for _, k in ipairs(SELECT) do e[k] = v[k] end
    end
    return e
end

local function signature(e)
    local aug = e.Augment
    if type(aug) == 'table' then aug = table.concat(aug, '|') end
    return string.lower(e.Name) .. '\0' .. tostring(e.AugPath) .. '\0' .. tostring(e.AugRank) .. '\0'
        .. tostring(e.AugTrial) .. '\0' .. tostring(aug)
end

-- One set's pieces, counted (two of the same ring: 2), in slot order.
local function set_entries(set, out)
    local tally, order = {}, {}
    for slot in pairs(M.SLOTS) do
        local e = M.Entry(set[slot])
        if e ~= nil then
            local k = signature(e)
            if tally[k] == nil then tally[k], order[#order + 1] = e, k end
            tally[k].Quantity = (tally[k].Quantity or 0) + 1
        end
    end
    table.sort(order)
    for _, k in ipairs(order) do
        if tally[k].Quantity == 1 then tally[k].Quantity = nil end -- LAC's default: one
        out[#out + 1] = tally[k]
    end
end

-- The sets inside a set table (Buffs['Haste']), any depth up to 3; not its own slots (LAC has those).
local function nested(set, out, depth)
    for k, v in pairs(set) do
        if (not M.SLOTS[k]) and (type(v) == 'table') then
            set_entries(v, out)
            if depth < 3 then nested(v, out, depth + 1) end
        end
    end
end

-- A Packer map's count as LAC takes it: a number, 'all', or (for 'stack' / true) the stack size; nil: left out.
function M.Count(n, name, stackOf)
    if (n == 'all') then return 'all' end
    if (n == 'stack') or (n == true) then return (stackOf ~= nil) and stackOf(name) or 1 end
    n = tonumber(n)
    if (n == nil) or (n <= 0) then return nil end
    return math.floor(n)
end

-- A Packer table in either form: LAC's list ({ 'Item', { Name = 'Item', Quantity = 12 } }) or GoomSwap's map
-- ({ ['Item'] = 12 }). LAC entries are kept as they are; map counts go through M.Count.
function M.FromTable(t, stackOf, out)
    out = out or {}
    if type(t) ~= 'table' then return out end
    local names = {}
    for k, v in pairs(t) do
        if type(k) == 'number' then
            if (type(v) == 'string') or (type(v) == 'table') then out[#out + 1] = v end
        elseif type(k) == 'string' then
            names[#names + 1] = k
        end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local n = M.Count(t[name], name, stackOf)
        if n ~= nil then out[#out + 1] = { Name = name, Quantity = n } end
    end
    return out
end

-- Item names in a value: a string, or the values of a table (any depth; keys are left out: RangeAmmo's weapons).
function M.Names(v, out)
    out = out or {}
    if type(v) == 'string' then
        out[#out + 1] = v
    elseif type(v) == 'table' then
        for _, x in pairs(v) do M.Names(x, out) end
    end
    return out
end

-- o: { file = profile.Packer, char = char.lua's Packer, sets = profile.Sets, engineSets = gcinclude.sets,
--      items = { names }, stackOf(name) -> n, owns(name) -> bool }
-- The whole list: the file's own entries first, as they are.
function M.Build(o)
    local out = {}
    for _, v in ipairs((type(o.file) == 'table') and o.file or {}) do out[#out + 1] = v end
    for k, v in pairs((type(o.file) == 'table') and o.file or {}) do -- a map in profile.Packer: counts as LAC takes them
        if type(k) == 'string' then
            local n = M.Count(v, k, o.stackOf)
            if n ~= nil then out[#out + 1] = { Name = k, Quantity = n } end
        end
    end
    M.FromTable(o.char, o.stackOf, out)
    for _, set in pairs((type(o.sets) == 'table') and o.sets or {}) do
        if type(set) == 'table' then nested(set, out, 1) end -- its own slots: LAC's scan has them
    end
    if type(o.engineSets) == 'table' then
        for _, set in pairs(o.engineSets) do
            if type(set) == 'table' then
                set_entries(set, out)
                nested(set, out, 2)
            end
        end
    end
    local seen = {}
    for _, name in ipairs(o.items or {}) do
        local k = string.lower(name)
        if (not seen[k]) and (not KEYWORDS[k]) and ((o.owns == nil) or o.owns(name)) then
            seen[k] = true
            out[#out + 1] = { Name = name }
        end
    end
    return out
end

return M
