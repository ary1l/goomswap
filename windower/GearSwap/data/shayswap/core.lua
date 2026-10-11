-- ShaySwap for Windower: runs the LuAshitacast job files and common/*.lua unchanged inside GearSwap.
--
-- LuAshitacast (LAC) behaviour copied here, from ThornyFFXI/LuAshitacast (MIT, (c) 2021 ThornyFFXI):
--   * gFunc.EquipSet/Equip fill a buffer; the buffer is sent when the handler returns. Locked slots
--     (gState.Disabled) are dropped when it is sent, as LAC's equip.lua does. ForceEquip* send at once
--     and also skip locked slots (LAC CheckEquipTable).
--   * HandleDefault runs while no action is pending. LAC runs it on every outgoing packet chunk; here
--     the outgoing chunk sends 'gs c __ss tick' at most every TICK seconds (Rahvin GS's pattern:
--     GearSwap only sends an equip made inside a GearSwap event).
--   * An action is pending from precast until your action packet says it finished or was interrupted,
--     or its LAC timeout passes (LAC packethandlers.lua).
-- Settings and constants below are LAC's defaults (config.lua, constants.lua).

local ROOT = windower.addon_path .. 'data/shayswap/';
local TICK = 0.2; -- seconds between HandleDefault runs while idle (tunable; not a game value)

local A = include('shayswap/ashita.lua');
local I = include('shayswap/imgui.lua');
local wres, ffxi = gearswap.res, A.ffxi; -- ffxi reads kept per event (ashita.lua)

local ctx = { root = ROOT, events = {}, inEvent = false };

---------------------------------------------------------------------------------------------------
-- LAC constants
---------------------------------------------------------------------------------------------------
local C = {};
C.SlotNames = { 'Main', 'Sub', 'Range', 'Ammo', 'Head', 'Body', 'Hands', 'Legs', 'Feet', 'Neck', 'Waist',
    'Ear1', 'Ear2', 'Ring1', 'Ring2', 'Back' };
C.SlotsLC = {};
for i, n in ipairs(C.SlotNames) do C.SlotsLC[string.lower(n)] = i end
-- GearSwap slot keys for LAC slots 1..16.
C.GS = { 'main', 'sub', 'range', 'ammo', 'head', 'body', 'hands', 'legs', 'feet', 'neck', 'waist',
    'ear1', 'ear2', 'ring1', 'ring2', 'back' };
C.Containers = { inventory = 0, safe = 1, storage = 2, temporary = 3, locker = 4, satchel = 5, sack = 6, case = 7,
    wardrobe = 8, safe2 = 9, wardrobe2 = 10, wardrobe3 = 11, wardrobe4 = 12, wardrobe5 = 13, wardrobe6 = 14,
    wardrobe7 = 15, wardrobe8 = 16 };
-- LAC resolves these with table[value + 1].
C.SpellElements = { 'Fire', 'Ice', 'Wind', 'Earth', 'Thunder', 'Water', 'Light', 'Dark', [16] = 'Non-Elemental' };
C.SpellSkills = { [33] = 'Divine Magic', [34] = 'Healing Magic', [35] = 'Enhancing Magic', [36] = 'Enfeebling Magic',
    [37] = 'Elemental Magic', [38] = 'Dark Magic', [39] = 'Summoning', [40] = 'Ninjutsu', [41] = 'Singing',
    [44] = 'Blue Magic', [45] = 'Geomancy' };
C.SpellTypes = { [2] = 'White Magic', [3] = 'Black Magic', [4] = 'Summoning', [5] = 'Ninjutsu', [6] = 'Bard Song',
    [7] = 'Blue Magic' };
C.AbilityTypes = { [10] = 'Rune Enchantment', [102] = 'Ready', [173] = 'Blood Pact: Rage', [174] = 'Blood Pact: Ward',
    [193] = 'Corsair Roll', [195] = 'Quick Draw' }; -- keyed by recast id, not +1
C.SpawnFlags = { [2] = 'PC', [3] = 'NPC', [10] = 'Alliance', [14] = 'Party', [17] = 'Monster' };
C.EntityStatus = { 'Idle', 'Engaged', 'Dead', 'Dead', 'Zoning', [34] = 'Resting' };
C.WeekDay = { 'Firesday', 'Earthsday', 'Watersday', 'Windsday', 'Iceday', 'Lightningday', 'Lightsday', 'Darksday' };
C.WeekDayElement = { 'Fire', 'Earth', 'Water', 'Wind', 'Ice', 'Thunder', 'Light', 'Dark' };
C.Weather = { 'Clear', 'Sunshine', 'Clouds', 'Fog', 'Fire', 'Fire x2', 'Water', 'Water x2', 'Earth', 'Earth x2',
    'Wind', 'Wind x2', 'Ice', 'Ice x2', 'Thunder', 'Thunder x2', 'Light', 'Light x2', 'Dark', 'Dark x2' };
C.WeatherElement = { 'None', 'None', 'None', 'None', 'Fire', 'Fire', 'Water', 'Water', 'Earth', 'Earth', 'Wind', 'Wind',
    'Ice', 'Ice', 'Thunder', 'Thunder', 'Light', 'Light', 'Dark', 'Dark' };
C.StormWeather = { [178] = 4, [179] = 12, [180] = 10, [181] = 8, [182] = 14, [183] = 6, [184] = 16, [185] = 18,
    [589] = 5, [590] = 13, [591] = 11, [592] = 9, [593] = 15, [594] = 7, [595] = 17, [596] = 19 };
C.ActionComplete = { [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [14] = true, [15] = true };
C.PetActionComplete = { [4] = true, [11] = true, [13] = true };
local function resolve(t, v) return (type(v) == 'number') and t[v + 1] or 'Unknown' end

gSettings = {
    AllowAddSet = false, EquipBags = { 8, 10, 11, 12, 13, 14, 15, 16, 0 }, FastCast = 0, Snapshot = 0,
    SpellOffset = 1.0, WeaponskillDelay = 3.0, AbilityDelay = 2.5, RangedBase = 10.0, RangedOffset = 0.5,
    ItemBase = 8, ItemOffset = 1.0, PetskillDelay = 4.0,
};
gState = { Disabled = {}, Encumbrance = {}, PlayerAction = nil, PetAction = nil, ForceSet = nil, ForceSetTimer = 0,
    CurrentCall = 'N/A' };
for i = 1, 16 do gState.Disabled[i] = false; gState.Encumbrance[i] = false end
gProfile = nil;

---------------------------------------------------------------------------------------------------
-- Equip: LAC item tables -> GearSwap
---------------------------------------------------------------------------------------------------
local slotOf = {}; -- slot key as written -> index (string.lower once per key)
local function slot_index(slot)
    if (type(slot) == 'number') then return ((slot >= 1) and (slot <= 16)) and slot or 0 end
    if (type(slot) ~= 'string') then return 0 end
    local n = slotOf[slot];
    if (n == nil) then n = C.SlotsLC[string.lower(slot)] or 0; slotOf[slot] = n end
    return n;
end

-- A plain item name always makes the same table, so it is made once (nothing writes to these).
local plainItem = {};
local function make_item(item) -- LAC equip.lua MakeItemTable
    if (type(item) == 'string') then
        local hit = plainItem[item];
        if (hit ~= nil) then return hit end
    end
    local t = {};
    if (type(item) == 'string') then
        t.Name = string.lower(item);
    elseif (type(item) == 'table') then
        for k, v in pairs(item) do
            if (k == 'Name') and (type(v) == 'string') then t.Name = string.lower(v)
            elseif (k == 'Augment') then t.Augment = v
            elseif (k == 'Bag') then t.Bag = (type(v) == 'string') and C.Containers[string.lower(v)] or v
            elseif (k == 'Priority') and (type(v) == 'number') then t.Priority = v
            elseif (k == 'AugPath') then t.AugPath = v
            elseif (k == 'AugRank') then t.AugRank = v
            elseif (k == 'AugTrial') then t.AugTrial = v end
        end
    else
        return nil;
    end
    if (t.Name == 'remove') and (t.Priority == nil) then t.Priority = -100 end
    t.Priority = t.Priority or 0;
    if (type(item) == 'string') then plainItem[item] = t end
    return t;
end

local function bag_name(id) local b = wres.bags[id]; return b and b.en or nil end

-- AugPath/AugRank/AugTrial: find the carried copy by its extdata and hand GearSwap that copy's exact
-- augment list and bag. Cached a few seconds (weapon sets are asked for on every tick).
local augCache = {};
local function aug_item(t)
    local key = t.Name .. '|' .. tostring(t.AugPath) .. '|' .. tostring(t.AugRank) .. '|' .. tostring(t.AugTrial);
    local hit = augCache[key];
    local now = os.clock();
    if (hit ~= nil) and (now < hit.until_) then return hit.augments, hit.bag end
    local id = A.ItemIdByName(t.Name);
    local all = ffxi.get_items();
    local augments, bag = nil, nil;
    if (id ~= nil) and (type(all) == 'table') then
        for _, b in ipairs(gSettings.EquipBags) do
            local name = bag_name(b);
            local list = name and all[gearswap.to_windower_bag_api(name)] or nil;
            if (type(list) == 'table') then
                for _, it in pairs(list) do
                    if (type(it) == 'table') and (it.id == id) and (it.extdata ~= nil) then
                        local ok, d = pcall(gearswap.extdata.decode, it);
                        if ok and (type(d) == 'table')
                            and ((t.AugPath == nil) or (d.path == t.AugPath))
                            and ((t.AugRank == nil) or (d.rank == t.AugRank))
                            and ((t.AugTrial == nil) or (d.trial_number == t.AugTrial)) then
                            augments = d.augments or ((t.AugPath ~= nil) and { 'Path: ' .. t.AugPath } or nil);
                            bag = name;
                            break;
                        end
                    end
                end
            end
            if (bag ~= nil) then break end
        end
    end
    if (augments == nil) and (t.AugPath ~= nil) then augments = { 'Path: ' .. t.AugPath } end
    augCache[key] = { augments = augments, bag = bag, until_ = now + 5 };
    return augments, bag;
end

local function to_gs(t)
    if (t.Name == 'remove') then return empty end
    if (t.Name == 'displaced') or (t.Name == 'ignore') then return nil end
    local e = { name = t.Name };
    local plain = true;
    if (t.Priority ~= 0) then e.priority = t.Priority; plain = false end
    if (t.Augment ~= nil) then
        e.augments = (type(t.Augment) == 'table') and t.Augment or { t.Augment };
        plain = false;
    end
    if (t.Bag ~= nil) then e.bag = bag_name(t.Bag); plain = false end
    if (t.AugPath ~= nil) or (t.AugRank ~= nil) or (t.AugTrial ~= nil) then
        local augs, bag = aug_item(t);
        if (augs ~= nil) then
            local merged = {};
            for _, a in ipairs(e.augments or {}) do merged[#merged + 1] = a end
            for _, a in ipairs(augs) do merged[#merged + 1] = a end
            e.augments = merged;
        end
        e.bag = e.bag or bag;
        plain = false;
    end
    return plain and t.Name or e;
end

local gs_equip = equip;
local function send(map)
    local out, n = {}, 0;
    for slot, t in pairs(map) do
        if (gState.Disabled[slot] ~= true) and (gState.Encumbrance[slot] ~= true) then
            local g = to_gs(t);
            if (g ~= nil) then out[C.GS[slot]] = g; n = n + 1 end
        end
    end
    if (n > 0) then gs_equip(out) end
end

-- Force equips outside a GearSwap event wait for one: GearSwap only sends equips made inside one.
local pendingForce, flushSentAt = {}, nil;
local function force(map)
    if ctx.inEvent then send(map); return end
    for k, v in pairs(map) do pendingForce[k] = v end
    local now = os.clock();
    if (flushSentAt == nil) or (now > flushSentAt + 2) then -- resent if the first was lost
        flushSentAt = now;
        windower.send_command('gs c __ss flush');
    end
end

local buffer = {};
local function to_slot_table(set)
    local out = {};
    for k, v in pairs(set) do
        local n = slot_index(k);
        if (n == 0) then print(chat.header('LuAshitacast') .. chat.error('Invalid slot specified: ' .. tostring(k))); return nil end
        local t = make_item(v);
        if (t ~= nil) and (type(t.Name) == 'string') then out[n] = t end
    end
    return out;
end

local function string_to_set(ref, base) -- LAC func.lua StringToSet
    ref = string.lower(ref);
    local tbl = (type(base) == 'table') and base or (gProfile and gProfile.Sets);
    local dot = string.find(ref, '%.');
    while (dot ~= nil) and (type(tbl) == 'table') do
        local want, old = string.sub(ref, 1, dot - 1), tbl;
        tbl = nil;
        for name, entry in pairs(old) do
            if (type(name) == 'string') and (string.lower(name) == want) then tbl = entry; break end
        end
        ref = string.sub(ref, dot + 1);
        dot = string.find(ref, '%.');
    end
    if (type(tbl) == 'table') then
        for name, entry in pairs(tbl) do
            if (type(name) == 'string') and (string.lower(name) == ref) then return entry end
        end
    end
    return nil;
end

local function named_set(set, what)
    if (type(set) == 'table') then return set end
    if (type(set) ~= 'string') then return nil end
    if (gProfile == nil) or (gProfile.Sets == nil) then
        print(chat.header('LuAshitacast') .. chat.error('You must have a profile loaded to use ' .. what .. '(string).'));
        return nil;
    end
    local s = string_to_set(set);
    if (s == nil) then print(chat.header('LuAshitacast') .. chat.error('Set not found: ' .. set)) end
    return s;
end

---------------------------------------------------------------------------------------------------
-- gFunc
---------------------------------------------------------------------------------------------------
local function equip_one(slot, item)
    local n = slot_index(slot);
    if (n == 0) then print(chat.header('LuAshitacast') .. chat.error('Invalid slot specified: ' .. tostring(slot))); return end
    local t = make_item(item);
    if (t == nil) or (type(t.Name) ~= 'string') then return end
    if (t.Name == 'ignore') then buffer[n] = nil; return end
    buffer[n] = t;
end

local function load_file(path)
    local p = string.gsub(tostring(path), '\\', '/');
    local me = ffxi.get_player();
    local name = me and me.name or '';
    local tries = { ROOT .. name .. '/' .. p, ROOT .. name .. '/' .. p .. '.lua', ROOT .. p, ROOT .. p .. '.lua' };
    local file = nil;
    for _, f in ipairs(tries) do
        if windower.file_exists(f) then file = f; break end
    end
    if (file == nil) then
        print(chat.header('LuAshitacast') .. chat.error('File not found matching: ' .. tostring(path)));
        return nil;
    end
    local fn, err = gearswap.loadfile(file);
    if (fn == nil) then
        print(chat.header('LuAshitacast') .. chat.error('Failed to load file: ' .. file));
        print(chat.header('LuAshitacast') .. chat.error(tostring(err)));
        return nil;
    end
    gearswap.setfenv(fn, _G);
    local ok, value = pcall(fn);
    if not ok then
        print(chat.header('LuAshitacast') .. chat.error('Failed to execute file: ' .. file));
        print(chat.header('LuAshitacast') .. chat.error(tostring(value)));
        return nil;
    end
    return value;
end

gFunc = setmetatable({
    Equip = equip_one,
    EquipSet = function(set)
        local s = named_set(set, 'EquipSet');
        if (type(s) ~= 'table') then return end
        for k, v in pairs(s) do equip_one(k, v) end
    end,
    ForceEquip = function(slot, item)
        local n = slot_index(slot);
        if (n == 0) then print(chat.header('LuAshitacast') .. chat.error('Invalid slot specified: ' .. tostring(slot))); return end
        local t = make_item(item);
        if (t == nil) or (type(t.Name) ~= 'string') or (t.Name == 'ignore') then return end
        force({ [n] = t });
    end,
    ForceEquipSet = function(set)
        local s = named_set(set, 'ForceEquipSet');
        if (type(s) ~= 'table') then return end
        local map = to_slot_table(s);
        if (map ~= nil) then
            for k, t in pairs(map) do if (t.Name == 'ignore') then map[k] = nil end end
            force(map);
        end
    end,
    LockSet = function(set, seconds)
        local s = named_set(set, 'LockSet');
        if (type(s) ~= 'table') then return end
        gState.ForceSet = s;
        gState.ForceSetTimer = os.clock() + (tonumber(seconds) or 3);
        local map = to_slot_table(s);
        if (map ~= nil) then force(map) end
    end,
    CancelAction = function() if (gState.PlayerAction ~= nil) then gState.PlayerAction.Block = true end end,
    ClearEquipBuffer = function() buffer = {} end,
    Combine = function(base, override)
        local out = {};
        for _, t in ipairs({ base or {}, override or {} }) do
            for k, v in pairs(t) do
                local n = slot_index(k);
                if (n ~= 0) then out[C.SlotNames[n]] = v end
            end
        end
        return out;
    end,
    Disable = function(slot)
        if (slot == 'all') then for i = 1, 16 do gState.Disabled[i] = true end; print(chat.header('LuAshitacast') .. 'All slots disabled.'); return end
        local n = slot_index(slot);
        if (n == 0) then print(chat.header('LuAshitacast') .. chat.error('Could not identify slot: ' .. tostring(slot))); return end
        gState.Disabled[n] = true;
        print(chat.header('LuAshitacast') .. C.SlotNames[n] .. ' disabled.');
    end,
    Enable = function(slot)
        if (slot == 'all') then for i = 1, 16 do gState.Disabled[i] = false end; print(chat.header('LuAshitacast') .. 'All slots enabled.'); return end
        local n = slot_index(slot);
        if (n == 0) then print(chat.header('LuAshitacast') .. chat.error('Could not identify slot: ' .. tostring(slot))); return end
        gState.Disabled[n] = false;
        print(chat.header('LuAshitacast') .. C.SlotNames[n] .. ' enabled.');
    end,
    LoadFile = load_file,
    Message = function(text) print(chat.header('LuAshitacast') .. tostring(text)) end,
    Echo = function(_, text) print(chat.header('LuAshitacast') .. tostring(text)) end,
    Error = function(text) print(chat.header('LuAshitacast') .. chat.error(tostring(text))) end,
}, { __index = function(_, k)
    return function() A.Unsupported('gFunc.' .. tostring(k)) end
end });

---------------------------------------------------------------------------------------------------
-- gData
---------------------------------------------------------------------------------------------------
local lastSentX, lastSentY = nil, nil; -- your position in the last 0x015 you sent (LAC IsMoving)

local function entity_table(index)
    local m = (type(index) == 'number') and (index > 0) and ffxi.get_mob_by_index(index) or nil;
    return {
        Distance = math.sqrt((m and m.distance) or 0),
        HPP = (m and m.hpp) or 0,
        Id = (m and m.id) or 0,
        Index = index,
        Name = (m and m.name) or '',
        Status = resolve(C.EntityStatus, (m and m.status) or 0),
        Type = resolve(C.SpawnFlags, (m and m.spawn_type) or 0),
    };
end

local function target_index()
    local st = ffxi.get_mob_by_target('st');
    if (st ~= nil) then return st.index end
    local t = ffxi.get_mob_by_target('t');
    return t and t.index or 0;
end

local function pet_index()
    local p = ffxi.get_player();
    local m = p and ffxi.get_mob_by_index(p.index) or nil;
    local pi = m and m.pet_index or 0;
    if (pi == nil) or (pi == 0) then return 0 end
    local pm = ffxi.get_mob_by_index(pi);
    if (pm == nil) or ((pm.hpp or 0) == 0) then return 0 end
    return pi;
end

local buffLower = {}; -- buff id -> lower-case name
local function buff_name(b)
    local n = buffLower[b];
    if (n == nil) then
        local r = wres.buffs[b];
        n = (r ~= nil) and string.lower(r.en) or false;
        buffLower[b] = n;
    end
    return n;
end

local function buff_count(match)
    local p = ffxi.get_player();
    local count = 0;
    if (p == nil) or (type(p.buffs) ~= 'table') then return 0 end
    local want = (type(match) == 'string') and string.lower(match) or match;
    for _, b in pairs(p.buffs) do
        if (type(want) == 'number') then
            if (b == want) then count = count + 1 end
        elseif (buff_name(b) == want) then
            count = count + 1;
        end
    end
    return count;
end

local function action_table(action, pet)
    if (action == nil) then return nil end
    local r = action.Resource;
    local t = { Resource = r, ActionType = action.Type, Resend = false };
    if (action.Type == 'Spell') and (r ~= nil) then
        t.CastTime = r.CastTime * 250;
        t.Element = resolve(C.SpellElements, r.Element);
        t.Id = r.Index;
        t.MpCost = r.ManaCost;
        t.Name = r.Name[1];
        t.Recast = r.RecastDelay * 250;
        t.Skill = resolve(C.SpellSkills, r.Skill);
        t.Type = resolve(C.SpellTypes, r.Type);
        if not pet then
            local p = ffxi.get_player();
            local mp = (p and p.vitals and p.vitals.mp) or 0;
            local maxmp = (p and p.vitals and p.vitals.max_mp) or 0;
            t.MpAftercast = mp - t.MpCost;
            t.MppAftercast = (maxmp > 0) and ((t.MpAftercast * 100) / maxmp) or 0;
        end
    elseif (action.Type == 'Weaponskill') and (r ~= nil) then
        t.Name = r.Name[1];
        t.Id = r.Id;
    elseif (action.Type == 'Ability') and (r ~= nil) then
        t.Name = r.Name[1];
        t.Id = r.Id - 0x200;
        t.Type = C.AbilityTypes[r.RecastTimerId] or (pet and 'Generic' or 'Unknown');
    elseif (action.Type == 'Ranged') then
        t.Name = 'Ranged';
        t.Id = 0;
    elseif (action.Type == 'Item') and (r ~= nil) then
        t.CastTime = r.CastTime * 250;
        t.Id = r.Id;
        t.Name = r.Name[1];
        t.Recast = r.RecastDelay * 250;
    elseif (action.Type == 'MobSkill') then
        t.Id = action.Id;
        t.Name = action.Name;
    end
    return t;
end

-- gData.GetPlayer / GetEnvironment / GetEquipment: built once per event (A.PerEvent); nothing writes to them.
local function player_table()
    local p = ffxi.get_player();
    if (p == nil) then return nil end
    local m = ffxi.get_mob_by_index(p.index);
    local v = p.vitals or {};
    local moving = false;
    if (m ~= nil) and (lastSentX ~= nil) then moving = (m.x ~= lastSentX) or (m.y ~= lastSentY) end
    local mj, sj = wres.jobs[p.main_job_id or 0], wres.jobs[p.sub_job_id or 0];
    return {
        HP = v.hp or 0, MaxHP = v.max_hp or 0, HPP = v.hpp or 0,
        MP = v.mp or 0, MaxMP = v.max_mp or 0, MPP = v.mpp or 0,
        TP = v.tp or 0,
        IsMoving = moving,
        MainJob = mj and mj.ens or 'NON', MainJobLevel = p.main_job_level or 0, MainJobSync = p.main_job_level or 0,
        SubJob = sj and sj.ens or 'NON', SubJobLevel = p.sub_job_level or 0, SubJobSync = p.sub_job_level or 0,
        Name = p.name,
        Status = resolve(C.EntityStatus, (m and m.status) or 0),
    };
end

local function environment_table()
    local info = ffxi.get_info() or {};
    local e = {};
    local z = wres.zones[info.zone or -1];
    e.Area = z and z.en or nil;
    local day = info.day or 0;
    e.Day = C.WeekDay[(day % 8) + 1];
    e.DayElement = C.WeekDayElement[(day % 8) + 1];
    local t = info.time or 0; -- minutes after midnight
    e.Time = math.floor(t / 60) + (t % 60) / 100;
    e.Timestamp = { day = day, hour = math.floor(t / 60), minute = t % 60 };
    local w = info.weather or 0;
    e.RawWeather = resolve(C.Weather, w);
    e.RawWeatherElement = resolve(C.WeatherElement, w);
    local p = ffxi.get_player();
    if (p ~= nil) and (type(p.buffs) == 'table') then
        for _, b in pairs(p.buffs) do if (C.StormWeather[b] ~= nil) then w = C.StormWeather[b] end end
    end
    e.Weather = resolve(C.Weather, w);
    e.WeatherElement = resolve(C.WeatherElement, w);
    local mp = wres.moon_phases and wres.moon_phases[info.moon_phase or -1];
    e.MoonPhase = mp and mp.en or nil;
    e.MoonPercent = info.moon;
    return e;
end

local function equipment_table()
    local items = ffxi.get_items();
    local eq = (type(items) == 'table') and items.equipment or nil;
    local out = {};
    if (type(eq) ~= 'table') then return out end
    for n = 1, 16 do
        local key = A.EquipKeys[n - 1];
        local index, bag = eq[key], eq[key .. '_bag'];
        if (type(index) == 'number') and (index > 0) then
            local it = ffxi.get_items(bag, index);
            local r = (type(it) == 'table') and wres.items[it.id] or nil;
            if (r ~= nil) then
                out[C.SlotNames[n]] = { Container = bag, Item = { Id = it.id, Index = index, Count = it.count },
                    Name = r.en, Resource = AshitaCore:GetResourceManager():GetItemById(it.id) };
            end
        end
    end
    return out;
end

gData = setmetatable({
    Constants = { EquipSlotNames = C.SlotNames },
    GetEquipSlot = slot_index,
    GetContainerMax = function(c)
        local b = ffxi.get_bag_info(c);
        local max = b and b.max or 0;
        return (max < 1) and 0 or math.min(max, 80);
    end,
    GetBuffCount = buff_count,
    GetCurrentCall = function() return gState.CurrentCall end,
    GetTargetIndex = target_index,
    GetEntity = entity_table,
    GetTarget = function()
        local i = target_index();
        if (i == 0) then return nil end
        return entity_table(i);
    end,
    GetAction = function() return action_table(gState.PlayerAction, false) end,
    GetActionTarget = function()
        if (gState.PlayerAction == nil) or (gState.PlayerAction.Target == nil) then return nil end
        return entity_table(gState.PlayerAction.Target);
    end,
    GetPetAction = function()
        if (gState.PetAction == nil) or (pet_index() == 0) then return nil end
        return action_table(gState.PetAction, true);
    end,
    GetPet = function()
        local pi = pet_index();
        if (pi == 0) then return nil end
        local t = entity_table(pi);
        t.TP = 0; -- not in Windower's mob table
        return t;
    end,
    GetPlayer = function() return A.PerEvent('gData.GetPlayer', player_table) end,
    GetEnvironment = function() return A.PerEvent('gData.GetEnvironment', environment_table) end,
    GetEquipment = function() return A.PerEvent('gData.GetEquipment', equipment_table) end,
    GetParty = function()
        local out = { ActionTarget = false, Count = 0, InParty = false, Target = false };
        local party = AshitaCore:GetMemoryManager():GetParty();
        local mine = target_index();
        for i = 0, 17 do
            if (party:GetMemberIsActive(i) == 1) then
                out.Count = out.Count + 1;
                if (i > 0) then out.InParty = true end
                local idx = party:GetMemberTargetIndex(i);
                if (gState.PlayerAction ~= nil) and (idx == gState.PlayerAction.Target) then out.ActionTarget = true end
                if (idx == mine) then out.Target = true end
            end
        end
        return out;
    end,
}, { __index = function(_, k)
    return function() A.Unsupported('gData.' .. tostring(k)) end
end });

-- LAC's equip module, only GetCurrentEquip (gcinclude.CheckLockingRings).
gEquip = {
    GetCurrentEquip = function(slot)
        local items = ffxi.get_items();
        local eq = (type(items) == 'table') and items.equipment or nil;
        local key = A.EquipKeys[(slot or 0) - 1];
        if (type(eq) ~= 'table') or (key == nil) then return {} end
        local index, bag = eq[key], eq[key .. '_bag'];
        if (type(index) ~= 'number') or (index == 0) then return {} end
        local it = ffxi.get_items(bag, index);
        if (type(it) ~= 'table') or (it.id == nil) or (it.id == 0) then return {} end
        return { Container = bag, Item = { Id = it.id, Index = index, Count = it.count } };
    end,
};

---------------------------------------------------------------------------------------------------
-- Handlers (LAC state.lua HandleEquipEvent)
---------------------------------------------------------------------------------------------------
local reported = {};
local function safe_call(name, ...)
    if (gProfile == nil) or (type(gProfile[name]) ~= 'function') then return end
    local ok, err = pcall(gProfile[name], ...);
    if (not ok) then
        local key = name .. tostring(err);
        if not reported[key] then
            reported[key] = true;
            print(chat.header('LuAshitacast') .. chat.error('Error in ' .. name .. ': ' .. tostring(err)));
        end
    end
end

local function process_buffer()
    if (gState.ForceSet ~= nil) then
        if (os.clock() > gState.ForceSetTimer) then
            gState.ForceSet = nil;
        else
            local map = to_slot_table(gState.ForceSet);
            if (map ~= nil) then send(map) end
            return;
        end
    end
    send(buffer);
end

local function handle(name)
    if (gProfile == nil) or (type(gProfile[name]) ~= 'function') then return end
    buffer = {};
    gState.CurrentCall = name;
    safe_call(name);
    if (name == 'HandleDefault') then
        process_buffer();
    elseif (gState.PlayerAction ~= nil) and (gState.PlayerAction.Block ~= true) then
        process_buffer();
    end
    gState.CurrentCall = 'N/A';
end

local function in_event(fn, ...)
    A.Fresh();
    local was = ctx.inEvent;
    ctx.inEvent = true;
    local ok, err = pcall(fn, ...);
    ctx.inEvent = was;
    if not ok then print(chat.header('ShaySwap') .. chat.error(tostring(err))) end
end

-- A GearSwap spell -> LAC's pending action.
local function new_action(spell)
    local now = os.clock();
    local a = { Block = false, Target = (spell.target and spell.target.index) or 0, SpellId = spell.id };
    local at = spell.action_type;
    local rm = AshitaCore:GetResourceManager();
    if (at == 'Magic') then
        a.Type = 'Spell';
        a.Resource = rm:GetSpellById(spell.id);
        local cast = a.Resource and (a.Resource.CastTime * 0.25) or 0;
        a.Completion = now + (cast * (100 - gSettings.FastCast)) / 100 + gSettings.SpellOffset;
    elseif (at == 'Ability') and (spell.type == 'WeaponSkill') then
        a.Type = 'Weaponskill';
        a.Resource = rm:GetAbilityById(spell.id);
        a.Completion = now + gSettings.WeaponskillDelay;
    elseif (at == 'Ability') and (spell.prefix == '/jobability' or spell.prefix == '/pet') then
        a.Type = 'Ability';
        a.Resource = rm:GetAbilityById(spell.id + 0x200);
        a.Completion = now + gSettings.AbilityDelay;
    elseif (at == 'Ranged Attack') then
        a.Type = 'Ranged';
        a.Completion = now + (gSettings.RangedBase * (100 - gSettings.Snapshot)) / 100 + gSettings.RangedOffset;
    elseif (at == 'Item') then
        a.Type = 'Item';
        a.Resource = rm:GetItemById(spell.id);
        a.Completion = now + gSettings.ItemBase + gSettings.ItemOffset;
    else
        return nil;
    end
    return a;
end

local PRECAST = { Spell = 'HandlePrecast', Weaponskill = 'HandleWeaponskill', Ability = 'HandleAbility',
    Ranged = 'HandlePreshot', Item = 'HandleItem' };
local MIDCAST = { Spell = 'HandleMidcast', Ranged = 'HandleMidshot' };

local nextTick, tickPending, tickSentAt = 0, false, 0;

function precast(spell)
    in_event(function()
        local a = new_action(spell);
        if (a == nil) then return end
        gState.PlayerAction = a;
        handle(PRECAST[a.Type]);
        if (gState.PlayerAction ~= nil) and (gState.PlayerAction.Block == true) then
            gState.PlayerAction = nil;
            cancel_spell();
            nextTick = 0;
        end
    end);
end

function midcast(spell)
    in_event(function()
        local a = gState.PlayerAction;
        if (a == nil) or (MIDCAST[a.Type] == nil) then return end
        local now = os.clock();
        if (a.Type == 'Spell') then
            local cast = a.Resource and (a.Resource.CastTime * 0.25) or 0;
            a.Completion = now + (cast * (100 - gSettings.FastCast)) / 100 + gSettings.SpellOffset;
        else
            a.Completion = now + (gSettings.RangedBase * (100 - gSettings.Snapshot)) / 100 + gSettings.RangedOffset;
        end
        handle(MIDCAST[a.Type]);
    end);
end

-- GearSwap's aftercast comes from the same finish/interrupt packet LAC ends the action on (or a
-- failure message), so idle gear goes back on here; the action event below and the LAC timeout
-- are the fallbacks.
function aftercast(spell)
    in_event(function()
        local a = gState.PlayerAction;
        -- A late aftercast for an earlier action must not end the one now pending.
        if (a ~= nil) and (type(spell) == 'table') and (spell.id ~= nil) and (a.SpellId ~= spell.id) then return end
        gState.PlayerAction = nil;
        handle('HandleDefault');
    end);
end
function pet_midcast() end
function pet_aftercast()
    in_event(function()
        gState.PetAction = nil;
        if (gState.PlayerAction == nil) then handle('HandleDefault') end
    end);
end

function status_change()
    in_event(function() if (gState.PlayerAction == nil) then handle('HandleDefault') end end);
end
sub_job_change = status_change;

---------------------------------------------------------------------------------------------------
-- Commands: Ashita chat commands -> Windower
---------------------------------------------------------------------------------------------------
local function split_args(s) -- quoted words stay whole, like Ashita's string:args()
    local out = {};
    local i, n = 1, #s;
    while (i <= n) do
        local c = string.sub(s, i, i);
        if (c == ' ') then
            i = i + 1;
        elseif (c == '"') then
            local j = string.find(s, '"', i + 1, true) or (n + 1);
            out[#out + 1] = string.sub(s, i + 1, j - 1);
            i = j + 1;
        else
            local j = string.find(s, ' ', i, true) or (n + 1);
            out[#out + 1] = string.sub(s, i, j - 1);
            i = j;
        end
    end
    return out;
end

-- Ashita bind modifiers ^ ctrl, ! alt, + shift, @ win, # apps; Windower uses ~ for shift.
local function bind_key(key)
    local mods, rest = string.match(key, '^([%^!%+@#]*)(.*)$');
    return string.gsub(mods or '', '%+', '~') .. (rest or key);
end

local function my_name() local p = ffxi.get_player(); return p and string.lower(p.name) or '' end

local queue_command;

-- What a bound key / alias should run on Windower.
local function console_form(cmd)
    local lower = string.lower(cmd);
    if (string.sub(lower, 1, 9) == '/lac fwd ') then return 'gs c ' .. string.sub(cmd, 10) end
    if (string.sub(lower, 1, 5) == '/lac ') then return 'gs c __ss lac ' .. string.sub(cmd, 6) end
    return 'input ' .. cmd;
end

local function cancel_buff(name)
    local want = string.lower(name);
    local p = ffxi.get_player();
    local ids = {};
    if (p ~= nil) and (type(p.buffs) == 'table') then
        for _, b in pairs(p.buffs) do
            if (buff_name(b) == want) then ids[b] = true end
        end
    end
    for id in pairs(ids) do
        -- The game's own cancel packet (Rahvin GS monitor.lua).
        windower.packets.inject_outgoing(0xF1, string.char(0xF1, 0x04, 0, 0, id % 256, math.floor(id / 256), 0, 0));
    end
end

queue_command = function(cmd)
    cmd = string.gsub(tostring(cmd or ''), '^%s+', '');
    local args = split_args(cmd);
    local first = string.lower(args[1] or '');
    if (first == '/lac') or (first == '/luashitacast') then
        windower.send_command(console_form('/lac ' .. (string.match(cmd, '^%S+%s+(.*)$') or '')));
        return;
    end
    if (first == '/ms') and (string.lower(args[2] or '') == 'sendto') and (args[3] ~= nil) then
        local rest = string.match(cmd, '^%S+%s+%S+%s+%S+%s+(.*)$') or '';
        if (string.lower(args[3]) == my_name()) then queue_command(rest)
        else windower.send_ipc_message('shayswap cmd ' .. args[3] .. ' ' .. rest) end
        return;
    end
    if (first == '/alias') then
        if (string.lower(args[2] or '') == 'del') and (args[3] ~= nil) then
            windower.send_command('unalias ' .. string.gsub(args[3], '^/', ''));
        elseif (args[2] ~= nil) then
            local rest = string.match(cmd, '^%S+%s+%S+%s+(.*)$') or '';
            windower.send_command('alias ' .. string.gsub(args[2], '^/', '') .. ' ' .. console_form(rest));
        end
        return;
    end
    if (first == '/bind') and (args[2] ~= nil) then
        local rest = string.match(cmd, '^%S+%s+%S+%s+(.*)$') or '';
        windower.send_command('bind ' .. bind_key(args[2]) .. ' ' .. console_form(rest));
        return;
    end
    if (first == '/unbind') and (args[2] ~= nil) then
        windower.send_command('unbind ' .. bind_key(args[2]));
        return;
    end
    if (first == '/cancel') and (args[2] ~= nil) then
        cancel_buff(string.match(cmd, '^%S+%s+(.*)$'));
        return;
    end
    windower.send_command('input ' .. cmd);
end

ctx.chatManager = setmetatable({
    QueueCommand = function(_, _, cmd) queue_command(cmd) end,
}, { __index = function(_, k) return function() A.Unsupported('IChatManager:' .. tostring(k) .. '()') end end });

-- /lac equip|set|disable|enable, run inside a GearSwap event (LAC commandhandlers.lua).
local function lac_command(args)
    local sub = string.lower(args[1] or '');
    if (sub == 'disable') then gFunc.Disable(args[2] or 'all')
    elseif (sub == 'enable') then gFunc.Enable(args[2] or 'all')
    elseif (sub == 'equip') then
        if (#args == 3) then gFunc.ForceEquip(args[2], args[3])
        elseif (#args >= 3) and ((#args - 1) % 2 == 0) then
            local set = {};
            for i = 2, #args - 1, 2 do set[args[i]] = args[i + 1] end
            gFunc.ForceEquipSet(set);
        end
    elseif (sub == 'set') and (args[2] ~= nil) then gFunc.LockSet(args[2], tonumber(args[3]) or 3.0)
    else A.Unsupported('/lac ' .. sub) end
end

function self_command(command)
    in_event(function()
        local args = split_args(command);
        if (string.lower(args[1] or '') == '__ss') then
            local what = string.lower(args[2] or '');
            if (what == 'tick') then
                tickPending = false;
                if (gState.PlayerAction == nil) then handle('HandleDefault') end
            elseif (what == 'flush') then
                flushSentAt = nil;
                local map = pendingForce;
                pendingForce = {};
                send(map);
            elseif (what == 'lac') then
                local rest = {};
                for i = 3, #args do rest[#rest + 1] = args[i] end
                lac_command(rest);
            end
            return;
        end
        safe_call('HandleCommand', args);
    end);
end

---------------------------------------------------------------------------------------------------
-- HUD folder over IPC. common/gchud.lua shares each box's state by writing <Name>.txt into
-- <install>config\addons\luashitacast\hud\ and reading every file there. Here that folder is
-- virtual: writing a file sends its line to your other boxes (Windower IPC, same PC), and reading
-- returns the last line each box sent. gchud.lua itself is unchanged.
---------------------------------------------------------------------------------------------------
local hudLines = {}; -- lower name -> line
local function norm(p) return string.lower((string.gsub(tostring(p or ''), '\\', '/'))) end
local HUD_DIR = norm(ROOT .. 'config/addons/luashitacast/hud/');
local function hud_file(p) -- '' for the folder, the file name for a file in it, nil otherwise
    local n = norm(p);
    if (n == HUD_DIR) or (n .. '/' == HUD_DIR) then return '' end
    if (string.sub(n, 1, #HUD_DIR) == HUD_DIR) then return string.sub(n, #HUD_DIR + 1) end
    return nil;
end
local function hud_store(line)
    local name = string.match(line or '', '^([^\t]+)');
    if (name ~= nil) then hudLines[string.lower(name)] = line end
end

ctx.vfs = {
    exists = function(p)
        local f = hud_file(p);
        if (f == nil) then return nil end
        if (f == '') then return true end
        return hudLines[string.match(f, '^(.-)%.txt$') or ''] ~= nil;
    end,
    create_directory = function(p) if (hud_file(p) ~= nil) then return true end return nil end,
    get_directory = function(p)
        if (hud_file(p) ~= '') then return nil end
        local out = {};
        for name in pairs(hudLines) do out[#out + 1] = name .. '.txt' end
        return out;
    end,
};

local real_io = io;
io = setmetatable({
    open = function(path, mode)
        local f = hud_file(path);
        if (f == nil) or (f == '') then return real_io.open(path, mode) end
        local key = string.match(f, '^(.-)%.txt$');
        if (key == nil) then return nil end
        if (string.sub(mode or 'r', 1, 1) == 'w') then
            local buf = {};
            return {
                write = function(self, ...) for i = 1, select('#', ...) do buf[#buf + 1] = tostring((select(i, ...))) end return self end,
                close = function()
                    local line = table.concat(buf);
                    hud_store(line);
                    windower.send_ipc_message('shayswap hud ' .. line);
                    return true;
                end,
            };
        end
        local line = hudLines[key];
        if (line == nil) then return nil end
        return { read = function() return line end, close = function() return true end };
    end,
}, { __index = real_io });

---------------------------------------------------------------------------------------------------
-- Profile load / unload
---------------------------------------------------------------------------------------------------
-- A GearSwap-format copy of the job's sets (item tables Name/Augment/AugPath/Priority/Bag -> name/
-- augments/priority/bag). Only GearSwap's commands read it; the engine keeps using gProfile.Sets.
local function gs_sets(src, seen)
    seen = seen or {};
    if (type(src) ~= 'table') then return {} end
    if seen[src] then return seen[src] end
    local out = {};
    seen[src] = out;
    for k, v in pairs(src) do
        if (type(v) == 'table') and (type(v.Name) == 'string') then
            local e = { name = v.Name };
            if (v.Augment ~= nil) then e.augments = (type(v.Augment) == 'table') and v.Augment or { v.Augment } end
            if (v.AugPath ~= nil) then
                e.augments = e.augments or {};
                table.insert(e.augments, 'Path: ' .. v.AugPath);
            end
            if (type(v.Priority) == 'number') then e.priority = v.Priority end
            if (v.Bag ~= nil) then e.bag = (type(v.Bag) == 'number') and bag_name(v.Bag) or v.Bag end
            out[k] = e;
        elseif (type(v) == 'table') then
            out[k] = gs_sets(v, seen);
        elseif (v == 'remove') then
            out[k] = empty;
        else
            out[k] = v;
        end
    end
    return out;
end
function get_sets()
    A.Fresh();
    A.Install(ctx);
    I.Install(ctx);
    local job = player and player.main_job;
    local profile = (type(job) == 'string') and load_file(job .. '.lua') or nil;
    if (type(profile) ~= 'table') then
        print(chat.header('ShaySwap') .. chat.error('No job file for ' .. tostring(job) .. ': put it at data/shayswap/<Name>/' .. tostring(job) .. '.lua'));
        return;
    end
    gProfile = profile;
    -- GearSwap's own commands (//gs validate, //gs org) read 'sets' in GearSwap's item format.
    sets = gs_sets(profile.Sets);
    -- profile.Packer -> Organizer (GearSwap's organizer-lib; needs the Organizer addon for //gs org).
    if (type(profile.Packer) == 'table') and (next(profile.Packer) ~= nil) then
        organizer_items = {};
        for i, v in ipairs(profile.Packer) do
            local name = (type(v) == 'table') and v.Name or v;
            if (type(name) == 'string') then organizer_items['packer' .. i] = name end
        end
        pcall(include, 'organizer-lib');
    end
    safe_call('OnLoad'); -- not a GearSwap equip event: force equips here wait for a flush
end

function file_unload()
    A.Fresh();
    safe_call('OnUnload');
    gProfile = nil;
end

---------------------------------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------------------------------
local function dispatch(name, ...)
    local list = ctx.events[name];
    if (list == nil) then return end
    for key, fn in pairs(list) do
        local ok, err = pcall(fn, ...);
        if (not ok) then
            local k = name .. key .. tostring(err);
            if not reported[k] then
                reported[k] = true;
                print(chat.header('ShaySwap') .. chat.error(name .. ' ' .. tostring(key) .. ': ' .. tostring(err)));
            end
        end
    end
end

windower.raw_register_event('prerender', function()
    A.Fresh();
    I.BeginFrame();
    dispatch('d3d_present');
    I.EndFrame();
end);

windower.raw_register_event('outgoing chunk', function(id, original, modified, injected, blocked)
    A.Fresh();
    if (id == 0x015) and (type(modified) == 'string') and (#modified >= 0x10) then
        lastSentX = modified:unpack('f', 0x04 + 1);
        lastSentY = modified:unpack('f', 0x0C + 1);
    end
    dispatch('packet_out', { id = id, data = modified, data_modified = modified, size = #(modified or ''),
        injected = injected, blocked = blocked });
    local now = os.clock();
    if (gState.PlayerAction ~= nil) and ((gState.PlayerAction.Completion or 0) < now) then gState.PlayerAction = nil end
    if (gState.PetAction ~= nil) and ((gState.PetAction.Completion or 0) < now) then gState.PetAction = nil end
    -- tickPending clears when the command runs; after 2s it is assumed lost and sent again.
    if (gProfile ~= nil) and (gState.PlayerAction == nil) and (now >= nextTick) and ((not tickPending) or (now > tickSentAt + 2)) then
        tickPending, tickSentAt = true, now;
        nextTick = now + TICK;
        windower.send_command('gs c __ss tick');
    end
end);

windower.raw_register_event('incoming chunk', function(id, original, modified, injected, blocked)
    A.Fresh();
    if (id == 0x00A) then gState.PlayerAction = nil; gState.PetAction = nil end
    dispatch('packet_in', { id = id, data = modified, data_modified = modified, size = #(modified or ''),
        injected = injected, blocked = blocked });
end);

-- Your action and your pet's, as LAC reads them from 0x028 (packethandlers.lua HandleIncoming0x28).
windower.raw_register_event('action', function(act)
    A.Fresh();
    local p = ffxi.get_player();
    if (p == nil) or (type(act) ~= 'table') then return end
    local cat, now = act.category, os.clock();
    if (act.actor_id == p.id) then
        if C.ActionComplete[cat] or (((cat == 8) or (cat == 12)) and (act.param == 28787)) then
            gState.PlayerAction = nil;
            nextTick = 0;
        end
        return;
    end
    local pi = pet_index();
    if (pi == 0) then return end
    local pm = ffxi.get_mob_by_index(pi);
    if (pm == nil) or (act.actor_id ~= pm.id) then return end
    if C.PetActionComplete[cat] or (((cat == 8) or (cat == 12)) and (act.param == 28787)) then
        gState.PetAction = nil;
        nextTick = 0;
        return;
    end
    if (cat ~= 7) and (cat ~= 8) then return end
    local t1 = act.targets and act.targets[1];
    local a1 = t1 and t1.actions and t1.actions[1];
    local actionId = a1 and a1.param or 0;
    if (actionId == 0) then return end
    local tm = t1.id and ffxi.get_mob_by_id(t1.id) or nil;
    local pa = { Id = actionId, Target = tm and tm.index or 0 };
    local rm = AshitaCore:GetResourceManager();
    if (cat == 7) then
        pa.Completion = now + gSettings.PetskillDelay;
        if (a1.message == 43) then
            pa.Type = 'MobSkill';
            pa.Name = rm:GetString('monsters.abilities', actionId - 256);
        else
            pa.Type = 'Ability';
            pa.Resource = rm:GetAbilityById(actionId + 512);
        end
    else
        pa.Type = 'Spell';
        pa.Resource = rm:GetSpellById(actionId);
        pa.Completion = now + ((pa.Resource and pa.Resource.CastTime or 0) * 0.25) + gSettings.SpellOffset;
    end
    gState.PetAction = pa;
end);

windower.raw_register_event('zone change', function()
    A.Fresh();
    gState.PlayerAction = nil;
    gState.PetAction = nil;
end);

windower.raw_register_event('ipc message', function(msg)
    A.Fresh();
    if (type(msg) ~= 'string') or (string.sub(msg, 1, 9) ~= 'shayswap ') then return end
    local kind, rest = string.match(msg, '^shayswap (%S+) (.*)$');
    if (kind == 'hud') and (rest ~= nil) then
        hud_store(rest);
    elseif (kind == 'cmd') and (rest ~= nil) then
        local who, cmd = string.match(rest, '^(%S+) (.*)$');
        if (who ~= nil) and (string.lower(who) == my_name()) then queue_command(cmd) end
    end
end);

windower.raw_register_event('mouse', function(kind)
    if (kind == 1) then I.SetMouseDown(true) elseif (kind == 2) then I.SetMouseDown(false) end
end);
