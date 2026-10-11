-- Action checks, mini-queue and set trace. Loaded and bound by gcinclude.
local gcaction = {};

local inc = nil;
local queued = nil;   -- { name, cmd, index, token, res, kind, untilT }
local tracing = nil;  -- { label, parts } while a handler runs with /gctrace on
local traceHead = nil;-- precast/preshot line waiting for its midcast/midshot

-- Ability recast ids (Windower res ability_recasts) whose timer is a charge pool, not the next use:
-- 102 Sic/Ready, 195 Quick Draw, 255 Ready. 231 Stratagems is counted by charges below.
local CHARGE_POOLS = { [102] = true, [195] = true, [255] = true };
local STRATAGEMS = 231;
-- MP check is skipped under these: Manafont/Manawell cost 0; Parsimony/Penury halve the next black/white
-- spell (BG, simplest to skip); Addendum/Tabula Rasa aren't sourced for exact cost, so skip is the safe side.
local MP_CUT = { 'Manafont', 'Manawell', 'Parsimony', 'Penury', 'Addendum: White', 'Addendum: Black', 'Tabula Rasa' };

local MP_SPECIAL = { ['Embrava'] = true, ['Kaustra'] = true }; -- cost is 20% of max MP, not the resource's

function gcaction.Bind(gcinclude)
    inc = gcinclude;
end

local function say(msg) inc.Say(msg) end

local function has(name) return inc.BuffCount(name) > 0 end

-- Arts cost per BG: own school -floor(10%) (so 9 MP or less is unchanged), other school +ceil(20%).
local function arts_cost(cost, spellType)
    local light, dark = has('Light Arts'), has('Dark Arts');
    if not (light or dark) then return cost end
    local own = (light and spellType == 'White Magic') or (dark and spellType == 'Black Magic');
    local other = (light and spellType == 'Black Magic') or (dark and spellType == 'White Magic');
    if own then return cost - math.floor(cost / 10) end
    if other then return cost + math.ceil(cost / 5) end
    return cost;
end

local function mmss(sec)
    sec = math.max(0, math.ceil(sec));
    return string.format('%d:%02d', math.floor(sec / 60), sec % 60);
end

-- Recast timers are in 1/60 s (Ashita's recast addon divides by 60).
local function ability_timer(rid)
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    for x = 0, 31 do
        if ((x == 0) or (rid ~= 0)) and (recast:GetAbilityTimerId(x) == rid) then
            return recast:GetAbilityTimer(x) / 60;
        end
    end
    return 0;
end

-- Stratagems in hand and seconds to the next, per Ashita's recast addon: the pool is 240s split by
-- SCH level (1/2/3/4/5 charges at 10/30/50/70/90), 33s a charge at 99 with 550 JP spent.
local function stratagems()
    local p = AshitaCore:GetMemoryManager():GetPlayer();
    local lvl = (p:GetMainJob() == 20) and p:GetMainJobLevel() or ((p:GetSubJob() == 20) and p:GetSubJobLevel() or 0);
    if (lvl < 10) then return 0, nil end
    local per = (lvl >= 90 and 48) or (lvl >= 70 and 60) or (lvl >= 50 and 80) or (lvl >= 30 and 120) or 240;
    local max = 240 / per;
    if (p:GetMainJob() == 20) and (p:GetMainJobLevel() == 99) and (p:GetJobPointsSpent(20) >= 550) then per = 33 end
    local t = ability_timer(STRATAGEMS);
    if (t <= 0) then return max, nil end
    local nextIn = t % per;
    if (nextIn == 0) then nextIn = per end
    return math.max(0, math.floor((max * per - t) / per)), nextIn;
end

local function ready(q)
    if (q.kind == 'Spell') then
        return AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(q.res.Index) == 0;
    end
    return ability_timer(q.res.RecastTimerId) <= 0;
end

local function current_target()
    local t = AshitaCore:GetMemoryManager():GetTarget();
    local ok, idx = pcall(function() return t:GetTargetIndex(t:GetIsSubTargetActive()) end);
    return ok and idx or 0;
end

-- How to name the action's target again later: <me>, a player's name, or <t> while still targeted.
local function target_token(index)
    local mm = AshitaCore:GetMemoryManager();
    if (index == mm:GetParty():GetMemberTargetIndex(0)) then return '<me>' end
    if (bit.band(mm:GetEntity():GetSpawnFlags(index) or 0, 0x01) ~= 0) then
        return mm:GetEntity():GetName(index);
    end
    if (index == current_target()) then return '<t>' end
    return nil;
end

-- Silence or paralysis: use the first carried cure item (Echo Drops: silence; Remedy: paralysis,
-- silence, blindness, poison, disease - in-game item text). Muddle blocks item use.
local function use_cure(list)
    if (inc.settings.AutoRemedy == false) or has('Muddle') then return nil end
    for _, item in ipairs(list) do
        if (gcauto.ItemCount(item) > 0) then
            AshitaCore:GetChatManager():QueueCommand(-1, '/item "' .. item .. '" <me>');
            return item;
        end
    end
    return nil;
end

-- Forced delay left after my last action (gcauto, BG-Wiki Forced Delay); 0 without the tracker.
local function forced_delay(kind)
    if (gcauto == nil) or (gcauto.ForcedDelay == nil) then return 0 end
    return gcauto.ForcedDelay(kind);
end

-- On recast: queue it when it comes back within MiniQueueMax seconds, else say how long.
local function on_recast(a, secs, kind)
    local cfg = inc.settings;
    local target = gData.GetActionTarget();
    if (cfg.MiniQueue ~= false) and (secs <= (cfg.MiniQueueMax or 5)) and (target ~= nil) and (a.Resource ~= nil) then
        local token = target_token(target.Index);
        if (token ~= nil) then
            local wait = math.max(secs, forced_delay(kind));
            queued = { name = a.Name, kind = kind, res = a.Resource, token = token,
                index = target.Index, untilT = os.clock() + wait + 2,
                cmd = ((kind == 'Spell') and '/ma "' or '/ja "') .. a.Name .. '" ' };
            say(a.Name .. ': queued, ' .. string.format('%.1fs', wait));
            return true;
        end
    end
    say(a.Name .. ': recast ' .. mmss(secs));
    return true;
end

-- True when the pending action would fail; the caller cancels it. Runs before any gear goes on.
function gcaction.Check()
    if (inc.settings.Validate == false) then return false end
    local a = gData.GetAction();
    if (a == nil) or (a.Name == nil) then return false end
    local player = gData.GetPlayer();
    if (player.HP == 0) then return true end
    for _, b in ipairs(inc.HardCC) do
        if has(b) then say(a.Name .. ': ' .. string.lower(b)); return true end
    end
    local kind = a.ActionType;
    if (kind == 'Spell') then
        if has('Mute') then say(a.Name .. ': mute'); return true end
        if has('Silence') then
            local item = use_cure(has('Paralysis') and { 'Remedy', 'Echo Drops' } or { 'Echo Drops', 'Remedy' });
            say(a.Name .. ': silenced' .. (item and (', using ' .. item) or ''));
            return true;
        end
        local timer = AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(a.Resource.Index) / 60;
        if (timer > 0) then return on_recast(a, timer, 'Spell') end
        local cost = tonumber(a.MpCost) or 0;
        if (inc.settings.ValidateMP ~= false) and (cost > 0) and not MP_SPECIAL[a.Name] then
            for _, b in ipairs(MP_CUT) do
                if has(b) then return false end
            end
            cost = arts_cost(cost, a.Type);
            if (player.MP >= cost) then return false end
            say(a.Name .. ': MP ' .. player.MP .. '/' .. cost);
            return true;
        end
    elseif (kind == 'Ability') then
        if has('Amnesia') then say(a.Name .. ': amnesia'); return true end
        if has('Paralysis') then
            local item = use_cure({ 'Remedy' });
            if item then say(a.Name .. ': paralyzed, using ' .. item); return true end
        end
        local rid = (a.Resource ~= nil) and a.Resource.RecastTimerId or nil;
        if (rid == STRATAGEMS) then
            local n, nextIn = stratagems();
            if (n == 0) then
                say(a.Name .. ': no stratagems' .. (nextIn and (', next in ' .. mmss(nextIn)) or ''));
                return true;
            end
        elseif (rid ~= nil) and not CHARGE_POOLS[rid] then
            local timer = ability_timer(rid);
            if (timer > 0) then return on_recast(a, timer, 'Ability') end
        end
        if (string.find(a.Name, 'Waltz', 1, true) ~= nil) then
            -- TP cost minus your gear's "Waltz TP cost" (LandSandBoat checkWaltzAbility).
            local cost = (tonumber(a.Resource.TPCost) or 0) - (inc.settings.WaltzTPCut or 0);
            if (cost > 0) and (player.TP < cost) then say(a.Name .. ': TP ' .. player.TP .. '/' .. cost); return true end
        end
    elseif (kind == 'Weaponskill') then
        if has('Amnesia') then say(a.Name .. ': amnesia'); return true end
    end
    return false;
end

-- Called every 0.1s: send the queued action once its recast is back, the forced delay is over and
-- nothing else is running.
function gcaction.Tick()
    local q = queued;
    if (q == nil) then return end
    if (os.clock() > q.untilT) then queued = nil; say(q.name .. ': queue dropped'); return end
    if (gState.PlayerAction ~= nil) or not ready(q) or (forced_delay(q.kind) > 0) then return end
    queued = nil;
    if (q.token == '<t>') and (current_target() ~= q.index) then say(q.name .. ': target changed, not sent'); return end
    AshitaCore:GetChatManager():QueueCommand(-1, q.cmd .. q.token);
end

-- Trace: one chat line per action naming each set put on, in order.
local names, namesOf = {}, nil;
local function set_name(set)
    if (type(set) == 'string') then return set end
    if (type(set) ~= 'table') then return tostring(set) end
    if (gProfile ~= nil) and (namesOf ~= gProfile.Sets) then
        names, namesOf = {}, gProfile.Sets;
        for k, v in pairs(gProfile.Sets or {}) do
            if (type(v) == 'table') then names[v] = k end
        end
    end
    if names[set] then return names[set] end
    local keys = {};
    for k in pairs(set) do keys[#keys + 1] = tostring(k) end
    table.sort(keys);
    return '{' .. table.concat(keys, ',') .. '}';
end

function gcaction.TraceOn() return inc.settings.Trace == true end

-- gFunc outlives a profile reload, so it is wrapped once and calls whichever gcaction loaded last.
function gcaction.Hook()
    gFunc.GcTraceNote = function(set)
        if (tracing ~= nil) and (set ~= nil) then tracing.parts[#tracing.parts + 1] = set_name(set) end
    end
    if (gFunc.GcTraced == true) then return end
    local equipSet = gFunc.EquipSet;
    gFunc.EquipSet = function(set, ...)
        local note = gFunc.GcTraceNote;
        if (note ~= nil) then note(set) end
        return equipSet(set, ...);
    end
    gFunc.GcTraced = true;
end

function gcaction.TraceStart()
    if not gcaction.TraceOn() then tracing = nil; return end
    tracing = { parts = {} };
end

-- phase: 'pre' holds the line for the matching 'mid'; anything else prints now.
function gcaction.TraceEnd(phase)
    local t = tracing;
    tracing = nil;
    if (t == nil) then return end
    local a = gData.GetAction();
    local label = (a ~= nil) and a.Name or '?';
    local text = (#t.parts > 0) and table.concat(t.parts, ' > ') or '-';
    if (phase == 'pre') then traceHead = { label = label, text = text }; return end
    local line = '[' .. label .. '] ';
    if (phase == 'mid') and (traceHead ~= nil) and (traceHead.label == label) then
        line = line .. traceHead.text .. ' | ' .. text;
    else
        line = line .. text;
    end
    traceHead = nil;
    say(line);
end

return gcaction;
