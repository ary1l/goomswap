-- ShaySwap for Windower: the Ashita calls common/*.lua and the job files make, answered from Windower.
-- Only what ShaySwap uses is here. Anything else prints one "not on Windower" line and returns nil.
--
-- Units checked against the sources:
--   spell cast/recast   Ashita quarter-seconds (LAC: CastTime * 0.25)  <- Windower seconds * 4
--   spell recast timer  Ashita 1/60 s                                   <- Windower get_spell_recasts, 1/60 s
--   ability recast      Ashita 1/60 s                                   <- Windower get_ability_recasts, seconds * 60
--   entity distance     squared in both
--   spawn flags         Windower spawn_type is the same byte (1 PC, 2 NPC, 9 alliance, 13 party, 16 monster)

local A = {};
local wres = gearswap.res;

local warned = {};
local function unsupported(what)
    if warned[what] then return end
    warned[what] = true;
    windower.add_to_chat(123, '[ShaySwap] not on Windower: ' .. what);
end
A.Unsupported = unsupported;

-- windower.ffxi reads, kept until the next event. Windower builds a new table on every read
-- (get_items() copies every bag), and the game does not change while one event runs, so each read is
-- made once per event. core.lua calls A.Fresh() as each event (frame, packet, GearSwap call, timer) starts.
local raw = windower.ffxi;
local memo = {};
local NONE = {};
function A.Fresh() memo = {} end
local function kept(t, k, fn, ...)
    local v = t[k];
    if (v == nil) then
        v = fn(...);
        t[k] = (v == nil) and NONE or v;
        return v;
    end
    if (v == NONE) then return nil end
    return v;
end
-- A value built from those reads, kept for the rest of the event (gData.GetPlayer, GetEnvironment).
function A.PerEvent(key, build) return kept(memo, key, build) end
local function kept0(name)
    local fn = raw[name];
    return function() return kept(memo, name, fn) end
end
local function kept1(name)
    local fn = raw[name];
    return function(k)
        if (k == nil) then return fn() end
        local t = memo[name];
        if (t == nil) then t = {}; memo[name] = t end
        return kept(t, k, fn, k);
    end
end
A.ffxi = setmetatable({
    get_player = kept0('get_player'),
    get_party = kept0('get_party'),
    get_info = kept0('get_info'),
    get_spells = kept0('get_spells'),
    get_spell_recasts = kept0('get_spell_recasts'),
    get_ability_recasts = kept0('get_ability_recasts'),
    get_mob_by_index = kept1('get_mob_by_index'),
    get_mob_by_target = kept1('get_mob_by_target'),
    get_mob_by_id = kept1('get_mob_by_id'),
    get_bag_info = kept1('get_bag_info'),
    get_items = function(bag, index)
        if (bag == nil) then return kept(memo, 'get_items', raw.get_items) end
        local bags = memo.get_items_at;
        if (bags == nil) then bags = {}; memo.get_items_at = bags end
        local t = bags[bag];
        if (t == nil) then t = {}; bags[bag] = t end
        if (index == nil) then return kept(t, 'all', raw.get_items, bag) end
        return kept(t, index, raw.get_items, bag, index);
    end,
}, { __index = raw });

-- Unknown methods on the stand-in objects warn once instead of erroring.
local function object(name, t)
    return setmetatable(t, { __index = function(_, k)
        return function() unsupported(name .. ':' .. tostring(k) .. '()') return nil end
    end });
end

-- chat: LAC and ShaySwap print lines built from these. print() below sends them to the chat log
-- (on Windower print() goes to the console). A line that ends with chat.error text is shown red;
-- one that only has an error-coloured word inside (COR's Unlucky number) is not.
local errorText = nil;
chat = {
    header = function(s) return '[' .. tostring(s) .. '] ' end,
    message = function(s) return tostring(s) end,
    error = function(s) errorText = tostring(s); return errorText end,
    warning = function(s) return tostring(s) end,
    success = function(s) return tostring(s) end,
    color1 = function(_, s) return tostring(s) end,
    color2 = function(_, s) return tostring(s) end,
};
print = function(...)
    local parts = {};
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    local text = table.concat(parts, ' ');
    local red = (errorText ~= nil) and (errorText ~= '') and (string.sub(text, -#errorText) == errorText);
    errorText = nil;
    for line in string.gmatch(text, '[^\n]+') do windower.add_to_chat(red and 123 or 207, line) end
end

-- Ashita's function:once(delay, ...): run once after delay seconds. Windower's functions library has no
-- 'once'; adding it does not change anything that library already defines.
if (rawget(functions, 'once') == nil) then
    functions.once = function(fn, delay, ...)
        local args, n = { ... }, select('#', ...);
        return coroutine.schedule(function() A.Fresh(); fn(unpack(args, 1, n)) end, tonumber(delay) or 0);
    end
end

---------------------------------------------------------------------------------------------------
-- Resources
---------------------------------------------------------------------------------------------------
local SPELL_TYPE = { WhiteMagic = 1, BlackMagic = 2, SummonerPact = 3, Ninjutsu = 4, BardSong = 5, BlueMagic = 6,
    Geomancy = 7, Trust = 8 }; -- LAC names 1..6 (White..Blue); anything higher is 'Unknown' in LAC either way

-- Resource objects are static: each is built once per id and handed out again.
local built = { items = {}, spells = {}, abilities = {} };
local function once(cache, id, make)
    local v = cache[id];
    if (v == nil) then v = make(id) or false; cache[id] = v end
    return v or nil;
end

local function item_obj(r)
    if (r == nil) then return nil end
    return {
        Id = r.id, Name = { r.en }, Skill = r.skill or 0, Slots = r.slots or 0, Jobs = r.jobs or 0,
        Level = r.level or 0, Flags = r.flags or 0, Type = r.type or 0, StackSize = r.stack or 1,
        CastDelay = r.cast_delay or 0, CastTime = (r.cast_time or 0) * 4, RecastDelay = (r.recast_delay or 0) * 4,
    };
end

local function spell_obj(r)
    if (r == nil) then return nil end
    local req, mask = {}, 0;
    for j = 0, 23 do
        local lv = (type(r.levels) == 'table') and r.levels[j] or nil;
        req[j + 1] = lv or -1;
        -- Levels above 99 are job point totals (gifts): Ashita flags those jobs in JobPointMask.
        if (lv ~= nil) and (lv > 99) then mask = mask + 2 ^ j end
    end
    return {
        Index = r.id, Id = r.id, Name = { r.en }, Element = r.element or 0, Skill = r.skill or 0,
        Type = SPELL_TYPE[r.type] or 0, ManaCost = r.mp_cost or 0,
        CastTime = (r.cast_time or 0) * 4, RecastDelay = (r.recast or 0) * 4, RecastTimerId = r.recast_id or 0,
        LevelRequired = req, JobPointMask = mask, Range = r.range or 0, Targets = r.targets or 0,
    };
end

-- Ashita ability ids: weapon skills 0..255, job abilities (incl. pet commands, Blood Pacts) 0x200 + id.
local function ability_obj(id)
    if (type(id) ~= 'number') then return nil end
    if (id >= 0x200) then
        local r = wres.job_abilities[id - 0x200];
        if (r == nil) then return nil end
        return { Id = id, Name = { r.en }, RecastTimerId = r.recast_id or 0, TPCost = r.tp_cost or 0,
            ManaCost = r.mp_cost or 0, Element = r.element or 0, Range = r.range or 0, Targets = r.targets or 0 };
    end
    local r = wres.weapon_skills[id];
    if (r == nil) then return nil end
    return { Id = id, Name = { r.en }, RecastTimerId = 0, TPCost = 0, ManaCost = 0, Element = r.element or 0,
        Range = r.range or 0, Targets = r.targets or 0 };
end

local function item_by_id(id)
    if (id == nil) then return nil end
    return once(built.items, id, function(i) return item_obj(wres.items[i]) end);
end
local function spell_by_id(id)
    if (id == nil) then return nil end
    return once(built.spells, id, function(i) return spell_obj(wres.spells[i]) end);
end
local function ability_by_id(id)
    if (type(id) ~= 'number') then return nil end
    return once(built.abilities, id, ability_obj);
end

-- Case-insensitive name -> lowest id, built on first use.
local nameIndex = {};
local function by_name(kind, name)
    if (type(name) ~= 'string') then return nil end
    local idx = nameIndex[kind];
    if (idx == nil) then
        idx = {};
        for id, r in pairs(wres[kind]) do
            if (type(r) == 'table') and (type(r.en) == 'string') then
                local k = string.lower(r.en);
                if (idx[k] == nil) or (id < idx[k]) then idx[k] = id end
            end
        end
        nameIndex[kind] = idx;
    end
    return idx[string.lower(name)];
end
A.ItemIdByName = function(name) return by_name('items', name) end;

local STRINGS = {
    ['jobs.names_abbr'] = function(id) local r = wres.jobs[id]; return r and r.ens end,
    ['jobs.names'] = function(id) local r = wres.jobs[id]; return r and r.en end,
    ['buffs.names'] = function(id) local r = wres.buffs[id]; return r and r.en end,
    ['zones.names'] = function(id) local r = wres.zones[id]; return r and r.en end,
    -- Ashita monsters.abilities is 0-based from Windower's id 256 (LAC: packet id - 256).
    ['monsters.abilities'] = function(id) local r = wres.monster_abilities[id + 256]; return r and r.en end,
};

local resourceManager = object('IResourceManager', {
    GetString = function(_, tbl, id)
        local f = STRINGS[tbl];
        if (f == nil) then unsupported('GetString ' .. tostring(tbl)); return nil end
        return f(tonumber(id) or -1);
    end,
    GetItemById = function(_, id) return item_by_id(id) end,
    GetItemByName = function(_, name) local id = by_name('items', name); return id and item_by_id(id) end,
    GetSpellById = function(_, id) return spell_by_id(id) end,
    GetSpellByName = function(_, name) local id = by_name('spells', name); return id and spell_by_id(id) end,
    GetAbilityById = function(_, id) return ability_by_id(id) end,
    GetAbilityByName = function(_, name)
        local id = by_name('job_abilities', name);
        if (id ~= nil) then return ability_by_id(id + 0x200) end
        id = by_name('weapon_skills', name);
        return id and ability_by_id(id);
    end,
});

---------------------------------------------------------------------------------------------------
-- Memory
---------------------------------------------------------------------------------------------------
local ffxi = A.ffxi;

local function me() return ffxi.get_player() end
local function mob(i) if (type(i) ~= 'number') or (i <= 0) then return nil end return ffxi.get_mob_by_index(i) end

-- Ashita party slots 0-5 party, 6-11 alliance 1, 12-17 alliance 2 = Windower p0-p5, a10-a15, a20-a25.
local function member(i)
    local party = ffxi.get_party();
    if (party == nil) or (type(i) ~= 'number') then return nil end
    local key = (i < 6) and ('p' .. i) or ((i < 12) and ('a1' .. (i - 6)) or ('a2' .. (i - 12)));
    return party[key];
end

local player = object('IPlayer', {
    GetMainJob = function() local p = me(); return p and p.main_job_id or 0 end,
    GetMainJobLevel = function() local p = me(); return p and p.main_job_level or 0 end,
    GetSubJob = function() local p = me(); return p and p.sub_job_id or 0 end,
    GetSubJobLevel = function() local p = me(); return p and p.sub_job_level or 0 end,
    GetJobPointsSpent = function(_, job)
        local p, r = me(), wres.jobs[job];
        if (p == nil) or (r == nil) or (type(p.job_points) ~= 'table') then return 0 end
        local jp = p.job_points[string.lower(r.ens)];
        return (type(jp) == 'table') and (jp.jp_spent or 0) or 0;
    end,
    HasSpell = function(_, id) local s = ffxi.get_spells(); return (s ~= nil) and (s[id] == true) end,
    GetBuffs = function() -- one copy per event (read only by gcinclude.BuffCount)
        local out = memo.buffs;
        if (out ~= nil) then return out end
        local p = me();
        out = {};
        if (p ~= nil) and (type(p.buffs) == 'table') then for k, v in pairs(p.buffs) do out[k] = v end end
        memo.buffs = out;
        return out;
    end,
    -- No zoning flag on Windower: treat "no player entity yet" as zoning.
    GetIsZoning = function() return ((me() == nil) or (ffxi.get_mob_by_target('me') == nil)) and 1 or 0 end,
    GetHPMax = function() local p = me(); return p and p.vitals and p.vitals.max_hp or 0 end,
    GetMPMax = function() local p = me(); return p and p.vitals and p.vitals.max_mp or 0 end,
    -- Not in Windower's player table: the /gcbar shows 0.
    GetAttack = function() return 0 end,
    GetDefense = function() return 0 end,
});

local party = object('IParty', {
    GetMemberIsActive = function(_, i) return (member(i) ~= nil) and 1 or 0 end,
    GetMemberName = function(_, i) local m = member(i); return m and m.name or '' end,
    GetMemberZone = function(_, i) local m = member(i); return m and m.zone or 0 end,
    GetMemberHP = function(_, i) local m = member(i); return m and m.hp or 0 end,
    GetMemberMP = function(_, i) local m = member(i); return m and m.mp or 0 end,
    GetMemberTP = function(_, i) local m = member(i); return m and m.tp or 0 end,
    GetMemberHPPercent = function(_, i) local m = member(i); return m and m.hpp or 0 end,
    GetMemberMPPercent = function(_, i) local m = member(i); return m and m.mpp or 0 end,
    GetMemberServerId = function(_, i)
        if (i == 0) then local p = me(); return p and p.id or 0 end
        local m = member(i); return m and m.mob and m.mob.id or 0;
    end,
    GetMemberTargetIndex = function(_, i)
        if (i == 0) then local p = me(); return p and p.index or 0 end
        local m = member(i); return m and m.mob and m.mob.index or 0;
    end,
});

local entity = object('IEntity', {
    GetSpawnFlags = function(_, i) local m = mob(i); return m and m.spawn_type or 0 end,
    GetDistance = function(_, i) local m = mob(i); return m and m.distance or 0 end,
    GetStatus = function(_, i) local m = mob(i); return m and m.status or 0 end,
    GetTargetedIndex = function(_, i) local m = mob(i); return m and m.target_index or 0 end,
    GetHPPercent = function(_, i) local m = mob(i); return m and m.hpp or 0 end,
    GetName = function(_, i) local m = mob(i); return m and m.name or '' end,
    GetServerId = function(_, i) local m = mob(i); return m and m.id or 0 end,
    GetPetTargetIndex = function(_, i) local m = mob(i); return m and m.pet_index or 0 end,
    GetLocalPositionX = function(_, i) local m = mob(i); return m and m.x or 0 end,
    GetLocalPositionY = function(_, i) local m = mob(i); return m and m.y or 0 end,
});

local target = object('ITarget', {
    GetIsSubTargetActive = function() return (ffxi.get_mob_by_target('st') ~= nil) and 1 or 0 end,
    GetTargetIndex = function(_, n)
        local t = ffxi.get_mob_by_target(((n == 1) or (n == true)) and 'st' or 't');
        return t and t.index or 0;
    end,
    -- Decision: no retarget on Windower. Auto-nuke already names the mob by server id.
    SetTarget = function() end,
});

-- Ability recast slots: 0 is recast id 0 (SP abilities); the rest are the timers now running.
-- Built once per event (gcinclude reads every slot).
local function ability_slots()
    local hit = memo.ability_slots;
    if (hit ~= nil) then return hit[1], hit[2] end
    local r = ffxi.get_ability_recasts() or {};
    local ids = {};
    for id, t in pairs(r) do
        if (type(id) == 'number') and (id ~= 0) and (type(t) == 'number') and (t > 0) then ids[#ids + 1] = id end
    end
    table.sort(ids);
    table.insert(ids, 1, 0);
    memo.ability_slots = { ids, r };
    return ids, r;
end

local recast = object('IRecast', {
    GetSpellTimer = function(_, id) local r = ffxi.get_spell_recasts(); return r and r[id] or 0 end,
    GetAbilityTimerId = function(_, x) local ids = ability_slots(); return ids[x + 1] or 0 end,
    GetAbilityTimer = function(_, x)
        local ids, r = ability_slots();
        local id = ids[x + 1];
        if (id == nil) then return 0 end
        return math.floor((r[id] or 0) * 60 + 0.5);
    end,
});

local EQUIP_KEYS = { [0] = 'main', 'sub', 'range', 'ammo', 'head', 'body', 'hands', 'legs', 'feet', 'neck', 'waist',
    'left_ear', 'right_ear', 'left_ring', 'right_ring', 'back' };
A.EquipKeys = EQUIP_KEYS;

local inventory = object('IInventory', {
    GetContainerItem = function(_, c, i)
        local it = ffxi.get_items(c, i);
        if (type(it) ~= 'table') or (it.id == nil) or (it.id == 0) then return nil end
        return { Id = it.id, Count = it.count or 0, Index = i, Flags = it.status or 0, Extra = it.extdata };
    end,
    GetContainerCountMax = function(_, c) local b = ffxi.get_bag_info(c); return b and b.max or 0 end,
    -- nil until Windower has the equipment list (used as a "still zoning" check).
    GetEquippedItem = function(_, slot)
        local items = ffxi.get_items();
        local e = (type(items) == 'table') and items.equipment or nil;
        if (type(e) ~= 'table') then return nil end
        local key = EQUIP_KEYS[slot];
        return { Index = key and e[key] or 0, Container = key and e[key .. '_bag'] or 0 };
    end,
});

local memoryManager = object('IMemoryManager', {
    GetPlayer = function() return player end,
    GetParty = function() return party end,
    GetEntity = function() return entity end,
    GetTarget = function() return target end,
    GetRecast = function() return recast end,
    GetInventory = function() return inventory end,
});

---------------------------------------------------------------------------------------------------
-- AshitaCore, ashita.fs, ashita.events
---------------------------------------------------------------------------------------------------
function A.Install(ctx)
    AshitaCore = object('AshitaCore', {
        GetResourceManager = function() return resourceManager end,
        GetMemoryManager = function() return memoryManager end,
        GetChatManager = function() return ctx.chatManager end,
        GetInstallPath = function() return ctx.root end,
    });

    local function mkdirs(path)
        local p = string.gsub(path, '\\', '/');
        local built = (string.sub(p, 1, 1) == '/') and '/' or ''; -- keep an absolute path absolute
        for part in string.gmatch(p, '[^/]+') do
            built = built .. part .. '/';
            if (string.find(part, ':', 1, true) == nil) and not windower.dir_exists(built) then
                if not windower.create_dir(built) then return false end
            end
        end
        return true;
    end

    ashita = {
        -- ctx.vfs answers first for virtual folders (the HUD folder, see core.lua).
        fs = {
            exists = function(p)
                local v = ctx.vfs and ctx.vfs.exists(p);
                if (v ~= nil) then return v end
                return windower.file_exists(p) or windower.dir_exists(p);
            end,
            create_directory = function(p) if ctx.vfs and ctx.vfs.create_directory(p) then return true end return mkdirs(p) end,
            create_dir = function(p) if ctx.vfs and ctx.vfs.create_directory(p) then return true end return mkdirs(p) end,
            get_directory = function(p, mask)
                local vlist = ctx.vfs and ctx.vfs.get_directory(p);
                local ok, list = true, vlist;
                if (vlist == nil) then ok, list = pcall(windower.get_dir, p) end
                if (not ok) or (type(list) ~= 'table') then return nil end
                if (mask == nil) then return list end
                local out = {};
                for _, f in ipairs(list) do
                    local okm, hit = pcall(string.match, f, mask);
                    if (not okm) or hit then out[#out + 1] = f end
                end
                return out;
            end,
        },
        events = {
            register = function(name, key, fn) ctx.events[name] = ctx.events[name] or {}; ctx.events[name][key] = fn end,
            unregister = function(name, key) if ctx.events[name] then ctx.events[name][key] = nil end end,
        },
    };
end

return A;
