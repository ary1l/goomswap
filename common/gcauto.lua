local gcauto = {};

local inc = nil;
local disp = nil;
local nextTick = 0;
local rolls = {};
local rollAbilities = nil;
local rollEleven = false;
local ROLL_STALE = 660;
local ROLL_RECAST = 193;


local CONTAINERS = { 0, 3 }; -- inventory, temporary items

local function item_count(name)
    local res = AshitaCore:GetResourceManager():GetItemByName(name, 0);
    if (res == nil) then return 0 end
    local inv = AshitaCore:GetMemoryManager():GetInventory();
    local n = 0;
    for _, c in ipairs(CONTAINERS) do
        local max = gData.GetContainerMax(c) or 0;
        for i = 1, max do
            local it = inv:GetContainerItem(c, i);
            if (it ~= nil) and (it.Id == res.Id) and (it.Count > 0) then
                n = n + it.Count;
            end
        end
    end
    return n;
end

gcauto.ItemCount = item_count;

-- TH tags: a mob my melee (1), ranged (2), WS (3), spell (4), ability (6), step/flourish (14) or
-- Effusion (15) hit (XiPackets 0x0028 cmd_no). Spells, steps and Effusions count only when they land.
-- Dropped at 0 HP (a respawn with the same id gets TH again) and on zone.
local tagged = {};
-- Messages for a spell or ability that didn't land (Windower Resources action_messages): resisted
-- 85 284 653-656, no effect 75 114 156 283 323 423 659, missed 158 324 658, out of range / too far /
-- can't see 4 78 154 198 217 219 313 328.
local NOLAND = { [4]=true, [75]=true, [78]=true, [85]=true, [114]=true, [154]=true, [156]=true, [158]=true,
    [198]=true, [217]=true, [219]=true, [283]=true, [284]=true, [313]=true, [323]=true, [324]=true,
    [328]=true, [423]=true, [653]=true, [654]=true, [655]=true, [656]=true, [658]=true, [659]=true };
local TAGCAT = { [1]='any', [2]='any', [3]='any', [4]='landed', [6]='any', [14]='landed', [15]='landed' };
local function prune_tags()
    if (next(tagged) == nil) then return end
    local ent = AshitaCore:GetMemoryManager():GetEntity();
    for id in pairs(tagged) do
        local idx = bit.band(id, 0x7FF);
        if (ent:GetServerId(idx) == id) and ((ent:GetHPPercent(idx) or 0) == 0) then tagged[id] = nil end
    end
end

-- Reads the bit-packed 0x0028 action packet once, layout per atom0s' XiPackets notes.
-- Bits are LSB-first; one parse feeds the roll, combat and burst readers.
local band, rshift = bit.band, bit.rshift;
local POW2 = {};
for i = 0, 32 do POW2[i] = 2 ^ i end
local pdata, ppos, pbit = nil, 0, 0;
local function rd(n)
    local value, got = 0, 0;
    while (got < n) do
        local byte = string.byte(pdata, ppos) or 0;
        local take = 8 - pbit;
        if (take > (n - got)) then take = n - got end
        value = value + band(rshift(byte, pbit), POW2[take] - 1) * POW2[got];
        got = got + take;
        pbit = pbit + take;
        if (pbit >= 8) then pbit = 0; ppos = ppos + 1 end
    end
    return value;
end

local A = { tgt = {}, nres = {}, first = {}, rmiss = {}, rval = {}, rmsg = {}, rkind = {} };
local function parse_action(data)
    -- Lua index 6 = byte 0x05: skip the 4-byte header and the size byte (XiPackets 0x0028 Reversing.md;
    -- LAC reads the actor at e.data 0x05 + 1).
    pdata, ppos, pbit = data, 6, 0;
    A.actor = rd(32);
    A.ntgt = rd(6);
    rd(4);
    A.cat = rd(4);
    A.param = rd(32);
    rd(32);
    local k = 0;
    for t = 1, A.ntgt do
        A.tgt[t] = rd(32);
        local results = rd(4);
        A.nres[t] = results;
        A.first[t] = k + 1;
        for _ = 1, results do
            k = k + 1;
            A.rmiss[k] = rd(3); -- XiPackets: 0 hit, 1 miss, 2 guard, 3 parry, 4 block
            rd(2); rd(12); rd(5); rd(5);
            A.rval[k] = rd(17);
            A.rmsg[k] = rd(10);
            rd(31);
            if (rd(1) == 1) then A.rkind[k] = rd(6); rd(4); rd(17); rd(10) else A.rkind[k] = false end
            if (rd(1) == 1) then rd(6); rd(4); rd(14); rd(10) end
        end
    end
    pdata = nil;
    local party = AshitaCore:GetMemoryManager():GetParty();
    A.me = party and party:GetMemberServerId(0); -- my server id, read once for every handler
    return A;
end

-- Buffs counted early: a result on me whose message names its status (Windower res action_messages:
-- "gains/receives the effect of ${status}", the result's param = the buff id) counts as up for 2s, until the buff
-- list has it. gcinclude.BuffCount reads gcauto.Predicted.
local GAIN_MSG = { [166] = true, [186] = true, [194] = true, [205] = true, [230] = true, [237] = true, [243] = true,
    [266] = true, [267] = true, [268] = true, [269] = true, [278] = true, [280] = true, [319] = true, [320] = true,
    [375] = true, [412] = true, [755] = true, [804] = true };
local PREDICT_FOR = 2.0;
local predicted = {}; -- buff id -> until (os.clock)
local function predict_packet(P)
    if (P.me == nil) then return end
    for t = 1, P.ntgt do
        if (P.tgt[t] == P.me) then
            for k = P.first[t], P.first[t] + P.nres[t] - 1 do
                if GAIN_MSG[P.rmsg[k]] then predicted[P.rval[k]] = os.clock() + PREDICT_FOR end
            end
        end
    end
end

function gcauto.Predicted(id)
    local untilT = predicted[id];
    if (untilT == nil) then return false end
    if (os.clock() > untilT) then predicted[id] = nil; return false end
    return true;
end

local function roll_abilities()
    if (rollAbilities ~= nil) then return rollAbilities end
    rollAbilities = {};
    local res = AshitaCore:GetResourceManager();
    for id = 0x200, 0x200 + 0x3FF do
        local ability = res:GetAbilityById(id);
        if (ability ~= nil) and (ability.RecastTimerId == ROLL_RECAST) then
            -- Ashita job ability resource id = packet id + 0x200 (LAC packethandlers / data.lua).
            rollAbilities[id - 0x200] = ability.Name[1];
        end
    end
    return rollAbilities;
end

-- Combat window, Selindrile-style: a monster hits me or a party/alliance member
-- (melee, ranged, monster skill), or I act on a monster. Expires after CombatWindow.
local lastCombat = -1e9;
local monsterCache = {};

-- Monster: spawn flag 0x10 set, 0x01 (player) clear. Covers LAC's exact 16 = Monster.
local function monster_flags(sf)
    sf = sf or 0;
    return (bit.band(sf, 0x10) ~= 0) and (bit.band(sf, 0x01) == 0);
end

-- Zone entities sit at index = id & 0x7FF (LAC packethandlers does the same); others (players,
-- pets, trusts) are found by scanning the whole array (0..0x8FF, as LAC does). nil if not loaded.
local function entity_index(id)
    if (id == nil) or (id == 0) then return nil end
    local entity = AshitaCore:GetMemoryManager():GetEntity();
    local idx = bit.band(id, 0x7FF);
    if (entity:GetServerId(idx) == id) then return idx end
    for i = 0, 0x8FF do
        if (entity:GetServerId(i) == id) then return i end
    end
    return nil;
end

local function is_monster(id)
    if (id == nil) or (id == 0) then return false end
    local hit = monsterCache[id];
    if (hit ~= nil) then return hit end
    local idx = entity_index(id);
    if (idx == nil) then return false end -- not loaded yet: don't cache
    local found = monster_flags(AshitaCore:GetMemoryManager():GetEntity():GetSpawnFlags(idx));
    monsterCache[id] = found;
    return found;
end

local function in_party(id)
    local party = AshitaCore:GetMemoryManager():GetParty();
    if (party == nil) then return false end
    for i = 0, 5 do
        if (party:GetMemberIsActive(i) == 1) and (party:GetMemberServerId(i) == id) then return true end
    end
    return false;
end

local function is_ally(id)
    local party = AshitaCore:GetMemoryManager():GetParty();
    if (party == nil) then return false end
    for i = 0, 17 do
        if (party:GetMemberIsActive(i) == 1) and (party:GetMemberServerId(i) == id) then return true end
    end
    return false;
end

local function combat_packet(P)
    local me = P.me;
    if (me == nil) then return end
    local category = P.cat;
    local hostile = ((category == 1) or (category == 2) or (category == 11)) and is_monster(P.actor);
    local mine = (P.actor == me) and ((category == 1) or (category == 2) or (category == 3) or (category == 4) or (category == 6));
    if (not hostile) and (not mine) then return end
    for t = 1, P.ntgt do
        local target = P.tgt[t];
        if (hostile and is_ally(target)) or (mine and is_monster(target)) then
            lastCombat = os.clock();
            return;
        end
    end
end

-- Learned cast time, so no job needs gSettings.FastCast. XiPackets 0x0028: cmd_no 8 = Magic (Start),
-- cmd_arg low 16 bits 'ca' (24931) = start, 'sp' (28787) = interrupt; cmd_no 4 = Magic (Finish), cmd_arg = spell id.
-- Finish minus start is the real cast time (FC, Quick Cast, Celerity, cast-time gear, latency).
-- Per skill keep the last 5 ratios to base cast time and use the slowest, so a Quick Cast/Celerity cast
-- never makes a burst look like it will land when a normal cast would not.
local castStart = nil;  -- { id, t }
local castRatio = {};   -- [skill] = { ratios }

local function cast_packet(P)
    local cat = P.cat;
    if (cat ~= 8) and (cat ~= 4) then return end
    local me = P.me;
    if (me == nil) or (P.actor ~= me) then return end
    if (cat == 8) then
        local id = (P.ntgt > 0) and (P.nres[1] > 0) and P.rval[P.first[1]] or nil;
        castStart = (bit.band(P.param, 0xFFFF) == 24931) and (id ~= nil) and { id = id, t = os.clock() } or nil;
        -- LAC (and the Windower adapter) end the pending spell at send + base cast + SpellOffset, then put idle
        -- gear on even if it hasn't landed (lag). It has started: keep it pending until base cast + SpellOffset
        -- from now; the finish or interrupt packet still ends it at once.
        local a = (gState ~= nil) and gState.PlayerAction or nil;
        local res = (castStart ~= nil) and AshitaCore:GetResourceManager():GetSpellById(id) or nil;
        if (a ~= nil) and (a.Type == 'Spell') and (a.Resource ~= nil) and (a.Resource.Index == id) and (res ~= nil) then
            local offset = ((gSettings ~= nil) and tonumber(gSettings.SpellOffset)) or 1;
            a.Completion = math.max(a.Completion or 0, os.clock() + (res.CastTime or 0) / 4 + offset);
        end
        return;
    end
    local s = castStart;
    castStart = nil;
    if (s == nil) or (s.id ~= P.param) then return end
    local res = AshitaCore:GetResourceManager():GetSpellById(s.id);
    if (res == nil) or (res.CastTime == nil) or (res.CastTime <= 0) then return end
    local ratio = (os.clock() - s.t) / (res.CastTime / 4);
    if (ratio < 0.05) or (ratio > 1.5) then return end
    local list = castRatio[res.Skill] or {};
    table.insert(list, ratio);
    if (#list > 5) then table.remove(list, 1) end
    castRatio[res.Skill] = list;
end

-- Seconds left on my cast in progress, and its spell id: its start packet was seen and no finish or
-- interrupt yet. 0 when not casting. Past its learned cast time it stays at 0.1 for up to 2s (the finish
-- packet is on its way), then the cast is taken as over (a missed packet).
function gcauto.CastLeft()
    local s = castStart;
    if (s == nil) then return 0 end
    local left = s.t + gcauto.CastTime(AshitaCore:GetResourceManager():GetSpellById(s.id)) - os.clock();
    if (left < -2) then castStart = nil; return 0 end
    return math.max(left, 0.1), s.id;
end

-- Seconds a spell resource takes to cast now: learned for its skill, else base less gSettings.FastCast.
function gcauto.CastTime(res)
    if (res == nil) or (res.CastTime == nil) then return 0 end
    local base = res.CastTime / 4;
    local list = castRatio[res.Skill];
    if (list ~= nil) and (#list > 0) then return base * math.max(unpack(list)), true end
    local fc = math.min(math.max(tonumber(gSettings.FastCast) or 0, 0), 80);
    return base * (1 - fc / 100), false;
end

-- Magic burst, ported from sync (sync_packethandler H028.sc + geo_mod.mb.tick).
-- Chain property = the result's proc kind (6 bits, 1..16 -> scdata.PROPNUM; LSB ActionProcSkillChain),
-- counted when the action is in scdata.BYCAT for its category (4 spell, 13 pet, 14); any WS chain counts.
-- Window: settings.MBWindow seconds (BG: 10) from the chain packet; another WS on the mob ends it.
-- A burst is cast only if its cast time (gcauto.CastTime) lands it inside the window.
local scdata = nil;
pcall(function() scdata = gFunc.LoadFile('common\\scdata.lua') end);

local MBELEM = {
    Liquefaction = { 'Fire' }, Induration = { 'Ice' }, Detonation = { 'Wind' }, Scission = { 'Earth' },
    Impaction = { 'Thunder' }, Reverberation = { 'Water' }, Transfixion = { 'Light' }, Compression = { 'Dark' },
    Fusion = { 'Fire', 'Light' }, Fragmentation = { 'Wind', 'Thunder' }, Distortion = { 'Ice', 'Water' },
    Gravitation = { 'Earth', 'Dark' },
    Light = { 'Fire', 'Wind', 'Thunder', 'Light' }, Darkness = { 'Ice', 'Earth', 'Water', 'Dark' },
    Radiance = { 'Fire', 'Wind', 'Thunder', 'Light' }, Umbra = { 'Ice', 'Earth', 'Water', 'Dark' },
};
local mbres = {};   -- [mob server id] = { props, ts, dur, step }

local function mb_packet(P)
    if (scdata == nil) then return end
    local now = os.clock();
    for t = 1, P.ntgt do
        local target = P.tgt[t];
        local prop, msg = nil, nil;
        if (P.nres[t] > 0) then
            local k = P.first[t];
            msg = P.rmsg[k];
            if (P.rkind[k] ~= false) then prop = scdata.PROPNUM[bit.band(P.rkind[k], 0x3F)] end
        end
        local cat = P.cat;
        if (msg ~= nil) and scdata.PETMSG[msg] then cat = 13 end
        local tbl = scdata.BYCAT[cat];
        local act = tbl and tbl[bit.band(P.param, 0xFFFF)];
        local chained = (prop ~= nil); -- every PROPNUM value is a skillchain property
        -- XiPackets documents proc_kind as the skillchain id for weapon skills (cmd 3), so a WS chain
        -- counts even when the WS is missing from scdata; other categories still need their table entry.
        if chained and ((act ~= nil) or (cat == 3)) and is_monster(target) then
            local old = mbres[target];
            if (old ~= nil) and (now > old.ts + old.dur) then old = nil end
            local step = ((old ~= nil) and old.step or 1) + 1;
            mbres[target] = { props = { prop }, ts = now, dur = inc.settings.MBWindow or 10, step = step };
        elseif (cat == 3) and (not chained) and (mbres[target] ~= nil) then
            -- BG: any further weapon skill on the target ends the magic burst window.
            mbres[target] = nil;
        end
    end
end

local function live_res(targetId, now)
    local r = mbres[targetId];
    if (r == nil) then return nil end
    if (now > r.ts + r.dur) then mbres[targetId] = nil; return nil end
    return r;
end

-- Burst gear: the spell's element fits the chain and it lands inside dur.
function gcauto.BurstLive(targetId, element, landsAt)
    if (targetId == nil) then return false end
    local now = os.clock();
    local r = live_res(targetId, now);
    if (r == nil) then return false end
    for _, pr in ipairs(r.props) do
        for _, el in ipairs(MBELEM[pr] or {}) do
            if (el == element) then return ((landsAt or now) <= r.ts + r.dur) end
        end
    end
    return false;
end

function gcauto.BurstInfo()
    local now, best, bestId = os.clock(), nil, nil;
    for id, r in pairs(mbres) do
        if (best == nil) or (r.ts > best.ts) then best, bestId = r, id end
    end
    if (best == nil) then return 'no skillchain seen' end
    return string.format('%s on %d, step %d, %.1fs ago, window %.1fs', best.props[1], bestId, best.step, now - best.ts, best.dur);
end

function gcauto.InCombat()
    local window = (inc ~= nil) and inc.settings.CombatWindow or 6;
    return (os.clock() - lastCombat) <= window;
end

local function roll_recompute()
    local now, eleven = os.clock(), false;
    for id, entry in pairs(rolls) do
        if ((now - entry.at) > ROLL_STALE) then
            rolls[id] = nil;
        elseif (entry.name ~= nil) and (inc ~= nil) and (inc.BuffCount(entry.name) == 0) then
            rolls[id] = nil; -- roll folded, overwritten or worn off
        elseif (entry.total == 11) then
            eleven = true;
        end
    end
    rollEleven = eleven;
end

-- Area spells that reach party members near a center (BG-Wiki/FFXIclopedia: Curaga 10' around its target;
-- Cura, Protectra and Shellra 10' around the caster). Their start packet may name only one target, so a
-- party member's cast is also checked by distance.
local AOE_ON_TARGET = { curaga = true };
local AOE_ON_CASTER = { cura = true, protectra = true, shellra = true };
local AOE_RANGE = 10;

local function incoming_cast(P)
    local actor, me = P.actor, P.me;
    if (me == nil) or (actor == me) or (gcauto.OnIncomingCast == nil) then return end
    if (bit.band(P.param, 0xFFFF) ~= 24931) then return end -- 'ca' = start; 'sp' (interrupt) ends it below
    for t = 1, P.ntgt do
        local k = P.first[t];
        for r = k, k + P.nres[t] - 1 do
            local spell = AshitaCore:GetResourceManager():GetSpellById(P.rval[r]);
            if (spell ~= nil) and (spell.Name ~= nil) then
                local name = spell.Name[1];
                local hit = (P.tgt[t] == me);
                if (not hit) and in_party(actor) then
                    local fam = string.gsub(string.lower(name), ' [ivx]+$', '');
                    local center = (AOE_ON_CASTER[fam] and actor) or (AOE_ON_TARGET[fam] and P.tgt[t]) or nil;
                    local idx = (center ~= nil) and entity_index(center) or nil;
                    hit = (idx ~= nil) and (math.sqrt(AshitaCore:GetMemoryManager():GetEntity():GetDistance(idx) or 0) <= AOE_RANGE);
                end
                if hit then gcauto.OnIncomingCast(name, actor); return end
            end
        end
    end
end

-- Someone else's spell finished (cmd_no 4) or was interrupted (cmd_no 8, 'sp'): received gear can come off.
local function incoming_end(P)
    if (gcauto.OnReceivedEnd == nil) or (P.me == nil) or (P.actor == P.me) then return end
    if (P.cat == 4) then
        local hitMe = false;
        for t = 1, P.ntgt do
            if (P.tgt[t] == P.me) then hitMe = true end
        end
        gcauto.OnReceivedEnd(P.actor, hitMe);
    elseif (P.cat == 8) and (bit.band(P.param, 0xFFFF) == 28787) then
        gcauto.OnReceivedEnd(P.actor, false);
    end
end

local function roll_packet(P)
    local actor, category, param, me = P.actor, P.cat, P.param, P.me;
    -- Magic (Start): handled by incoming_cast.
    if (category == 8) then return end
    local tagcat = TAGCAT[category];
    -- A THSkip spell (Absorb-TP, Stun) is cast without the TH set, so it doesn't count as the tag.
    if (tagcat ~= nil) and (category == 4) and (inc ~= nil) and (inc.Skipped ~= nil) then
        local res = AshitaCore:GetResourceManager():GetSpellById(param);
        if (res ~= nil) and (res.Name ~= nil) and inc.Skipped('THSkip', res.Name[1]) then tagcat = nil end
    end
    if (tagcat ~= nil) then
        if (me ~= nil) and (actor == me) then
            for t = 1, P.ntgt do
                local k = P.first[t];
                local ok = (tagcat == 'any') or ((P.nres[t] > 0) and (P.rmiss[k] == 0) and (not NOLAND[P.rmsg[k]]));
                if ok and is_monster(P.tgt[t]) then tagged[P.tgt[t]] = true end
            end
            -- category 6 falls through: your own Phantom Roll / Double-Up is also a roll packet.
            if (category ~= 6) then return end
        end
    end
    local rollName = (category == 6) and roll_abilities()[param] or nil;
    if (rollName == nil) or (me == nil) then return end
    for t = 1, P.ntgt do
        if (P.tgt[t] == me) then
            local k = P.first[t];
            for r = k, k + P.nres[t] - 1 do
                local value = P.rval[r];
                if (value >= 1) and (value <= 11) then
                    rolls[param] = { total = value, at = os.clock(), name = rollName };
                end
            end
        end
    end
    roll_recompute();
end

-- Only an 11 can be dropped by a recompute here; roll_packet recomputes after every roll.
function gcauto.RollEleven()
    if rollEleven then roll_recompute() end
    return rollEleven;
end

function gcauto.IsTagged(id)
    return (id ~= nil) and (tagged[id] == true);
end

function gcauto.ClearTags()
    tagged = {};
end

function gcauto.RollInfo()
    roll_recompute();
    local now = os.clock();
    local parts = {};
    for id, entry in pairs(rolls) do
        local name = entry.name or tostring(id);
        parts[#parts + 1] = name .. '=' .. tostring(entry.total) .. ' (' .. tostring(math.floor(now - entry.at)) .. 's)';
    end
    if (#parts == 0) then return 'no roll seen yet' end
    return table.concat(parts, ', ');
end

function gcauto.RollReset()
    rolls = {};
    rollEleven = false;
end

function gcauto.Bind(gcinclude, gcdisplay)
    inc = gcinclude;
    disp = gcdisplay;
end

-- My item use started / was interrupted (cmd_no 9, result value = item id, 0 if interrupted) or finished
-- (cmd_no 5, cmd_arg = item id), XiPackets 0x0028: tells gcinclude's enchanted-item use.
local function item_packet(P)
    if ((P.cat ~= 5) and (P.cat ~= 9)) or (P.me == nil) or (P.actor ~= P.me) then return end
    if (inc == nil) or (inc.OnItemAction == nil) then return end
    local id = P.param;
    if (P.cat == 9) then id = ((P.ntgt > 0) and (P.nres[1] > 0)) and P.rval[P.first[1]] or 0 end
    inc.OnItemAction(P.cat, id);
end

-- My spell refused before it started (0x0029 caster 0x04, MessageNum 0x18, XiPackets; texts from Windower
-- Resources action_messages): 17/18 unable to cast at this time, 34 not enough MP, 40 not in this area,
-- 47 cannot cast, 48 cannot be cast on target, 49 unable to cast, 313 out of range.
local SPELL_REFUSED = { [17] = true, [18] = true, [34] = true, [40] = true, [47] = true, [48] = true, [49] = true, [313] = true };
local function refused_packet(data)
    if (inc == nil) then return end
    local msg = struct.unpack('H', data, 0x18 + 1);
    -- 39: "You need the Dual Wield ability to equip the ${item} as a sub-weapon." (Data 0x0C = the item)
    if (msg == 39) then
        if (inc.OnSubRefused ~= nil) then inc.OnSubRefused(struct.unpack('L', data, 0x0C + 1)) end
        return;
    end
    if (inc.OnSpellRefused == nil) or not SPELL_REFUSED[msg] then return end
    local party = AshitaCore:GetMemoryManager():GetParty();
    local me = party and party:GetMemberServerId(0);
    if (me == nil) or (struct.unpack('L', data, 0x04 + 1) ~= me) then return end
    inc.OnSpellRefused();
end

-- Twice a second: drop TH tags on dead mobs and burst windows that have closed.
local function tick()
    local now = os.clock();
    if (now < nextTick) then return end
    nextTick = now + 0.5;
    prune_tags();
    for id, r in pairs(mbres) do
        if (now > r.ts + r.dur) then mbres[id] = nil end
    end
end

function gcauto.Start()
    ashita.events.register('d3d_present', 'gcauto_tick', tick);
    ashita.events.register('packet_in', 'gcauto_packet', function (e)
        if (e.id == 0x0028) then
            local ok, P = pcall(parse_action, e.data);
            if ok then pcall(roll_packet, P); pcall(combat_packet, P); pcall(cast_packet, P); pcall(mb_packet, P); pcall(item_packet, P); pcall(incoming_cast, P); pcall(incoming_end, P); pcall(predict_packet, P) end
        end
        if (e.id == 0x0029) then pcall(refused_packet, e.data) end
        if (e.id == 0x000B) and (inc ~= nil) and (inc.OnZoneOut ~= nil) then pcall(function() inc.OnZoneOut(struct.unpack('L', e.data, 0x04 + 1)) end) end -- LogoutState
        if (e.id == 0x000A) and (inc ~= nil) and (inc.OnZone ~= nil) then pcall(inc.OnZone) end
        if (e.id == 0x000A) then predicted = {}; gcauto.RollReset(); gcauto.ClearTags(); lastCombat = -1e9; monsterCache = {}; mbres = {} end
    end);
end

function gcauto.Stop()
    ashita.events.unregister('d3d_present', 'gcauto_tick');
    ashita.events.unregister('packet_in', 'gcauto_packet');
end

return gcauto;
