-- Action checks, mini-queue and set trace. Loaded and bound by gcinclude.
local gcaction = {};

local inc = nil;
local queue = {};     -- waiting actions, oldest first: { name, cmd, index, token, res, kind, untilT, hardT }
local QUEUE_MAX = 3;  -- a 4th drops the oldest (said in chat)
local BUSY_HOLD = 10; -- seconds a waiting action's deadline may stretch while you're mid-action
local SEND_GAP = 1.0; -- after sending one, the next waits this long for it to start
local sendAfter = 0;
local lastSent = nil; -- { name, at }: a re-sent action that is still blocked is not queued again
local lastTick = nil;
local lastStarted = nil; -- { name, at }: the last action let through, so a double-tap isn't queued again
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
    elseif (q.kind == 'Weaponskill') then
        return true; -- no recast; TP is checked by the game
    end
    local rid = q.res.RecastTimerId;
    if CHARGE_POOLS[rid] or (rid == STRATAGEMS) then return true end -- charges, not a single timer
    return ability_timer(rid) <= 0;
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

-- Seconds left on my own cast in progress (gcinclude.CastLeft: start/finish packets, or a cast sent whose start
-- packet isn't back yet); 0 without the tracker.
local function cast_left()
    if (inc ~= nil) and (inc.CastLeft ~= nil) then return inc.CastLeft() end -- also a cast sent but not started yet
    if (gcauto == nil) or (gcauto.CastLeft == nil) then return 0 end
    return gcauto.CastLeft(); -- seconds, spell id
end

local CMD = { Spell = '/ma "', Ability = '/ja "', Weaponskill = '/ws "' };

-- Queue the action if it can go out within MiniQueueMax seconds. False when it can't be queued
-- (queue off, too long, no target to name again, or it was just re-sent from the queue and is still blocked).
local function enqueue(a, wait, kind, why)
    local cfg = inc.settings;
    local target = gData.GetActionTarget();
    if (cfg.MiniQueue == false) or (wait > (cfg.MiniQueueMax or 5)) or (target == nil) or (a.Resource == nil) then return false end
    local now = os.clock();
    if (lastSent ~= nil) and (lastSent.name == a.Name) and (now - lastSent.at < 1.5) then return false end
    local token = target_token(target.Index);
    if (token == nil) then return false end
    for i = #queue, 1, -1 do -- pressed again: the newer one replaces it
        if (queue[i].name == a.Name) then table.remove(queue, i) end
    end
    if (#queue >= QUEUE_MAX) then
        local old = table.remove(queue, 1);
        say(old.name .. ': queue full, dropped');
    end
    queue[#queue + 1] = { name = a.Name, kind = kind, res = a.Resource, token = token, index = target.Index,
        untilT = now + wait + 2, hardT = now + wait + 2 + BUSY_HOLD, cmd = CMD[kind] .. a.Name .. '" ' };
    say(a.Name .. ': queued (' .. why .. '), ' .. string.format('%.1fs', wait));
    return true;
end

-- Recast, your cast in progress, or the forced delay after your last action. Recast and casting always
-- cancel (the game refuses them, and a cancel keeps your current cast's gear on); the forced delay only
-- cancels when it can be queued, otherwise the action goes out as it would have.
local function on_wait(a, kind, recast)
    local casting, castId = cast_left();
    local busy = (casting > 0) and (casting + 3.0) or 0; -- then the 3s forced delay after a spell (BG-Wiki)
    busy = math.max(busy, forced_delay(kind));
    local wait = math.max(recast or 0, busy);
    if (wait <= 0) then return false end
    local why = ((recast or 0) >= busy) and 'recast' or ((casting > 0) and 'casting' or 'delay');
    -- Double-taps: the spell you're casting pressed again is only cancelled, and the action you just
    -- used pressed again in its own forced delay goes out as it would have; neither is queued twice.
    if (why == 'casting') and (kind == 'Spell') and (castId ~= nil) and (a.Resource ~= nil) and (castId == a.Resource.Index) then
        return true;
    end
    if (why == 'delay') and (lastStarted ~= nil) and (lastStarted.name == a.Name) and (os.clock() - lastStarted.at < 5) then
        return false;
    end
    if enqueue(a, wait, kind, why) then return true end
    if ((recast or 0) > 0) then say(a.Name .. ': recast ' .. mmss(recast)); return true end
    if (casting > 0) then say(a.Name .. ': casting'); return true end
    return false;
end

-- True when the pending action would fail; the caller cancels it. Runs before any gear goes on.
local function check()
    if (inc.settings.Validate == false) then return false end
    local a = gData.GetAction();
    if (a == nil) or (a.Name == nil) then return false end
    -- The game's own resend (Sequencer plugin): checked when first sent, so it goes unless the server has
    -- started that cast (start packet seen); then it is cancelled without a message. Never queued.
    if (a.Resend == true) then
        return (gcauto ~= nil) and (gcauto.CastLeft ~= nil) and (gcauto.CastLeft() > 0);
    end
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
        if on_wait(a, 'Spell', timer) then return true end
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
            if on_wait(a, 'Ability', 0) then return true end
        elseif (rid ~= nil) and not CHARGE_POOLS[rid] then
            if on_wait(a, 'Ability', ability_timer(rid)) then return true end
        else
            if on_wait(a, 'Ability', 0) then return true end
        end
        if (string.find(a.Name, 'Waltz', 1, true) ~= nil) then
            -- TP cost minus your gear's "Waltz TP cost" (LandSandBoat checkWaltzAbility).
            local cost = (tonumber(a.Resource.TPCost) or 0) - (inc.settings.WaltzTPCut or 0);
            if (cost > 0) and (player.TP < cost) then say(a.Name .. ': TP ' .. player.TP .. '/' .. cost); return true end
        end
    elseif (kind == 'Weaponskill') then
        if has('Amnesia') then say(a.Name .. ': amnesia'); return true end
        if on_wait(a, 'Weaponskill', 0) then return true end
    end
    return false;
end

function gcaction.Check()
    local blocked = check();
    if not blocked then
        local a = gData.GetAction();
        if (a ~= nil) and (a.Name ~= nil) then lastStarted = { name = a.Name, at = os.clock() } end
    end
    return blocked;
end

-- Called every 0.1s. While you're mid-action the deadlines stop (up to BUSY_HOLD more), so an action
-- that waited behind another isn't dropped for it. When nothing is running: sends the oldest waiting
-- action whose recast is back and whose forced delay is over, one at a time.
function gcaction.Tick()
    local now = os.clock();
    local dt = (lastTick ~= nil) and math.min(now - lastTick, 0.5) or 0;
    lastTick = now;
    if (#queue == 0) then return end
    local busy = (gState.PlayerAction ~= nil) or (cast_left() > 0);
    for i = #queue, 1, -1 do
        local q = queue[i];
        if busy then q.untilT = math.min(q.untilT + dt, q.hardT) end
        if (now > q.untilT) then table.remove(queue, i); say(q.name .. ': queue dropped') end
    end
    if busy or (now < sendAfter) then return end
    for i, q in ipairs(queue) do
        if ready(q) and (forced_delay(q.kind) <= 0) then
            table.remove(queue, i);
            if (q.token == '<t>') and (current_target() ~= q.index) then say(q.name .. ': target changed, not sent'); return end
            sendAfter = now + SEND_GAP;
            lastSent = { name = q.name, at = now };
            AshitaCore:GetChatManager():QueueCommand(-1, q.cmd .. q.token);
            return;
        end
    end
end

-- Zoning: nothing waiting is sent on arrival.
function gcaction.Clear()
    queue = {};
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
