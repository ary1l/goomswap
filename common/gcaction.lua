-- Action checks and set trace. Loaded and bound by gcinclude.
local gcaction = {};

local inc = nil;
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

-- Silence or paralysis: use the first carried cure item (Echo Drops: silence; Remedy: paralysis,
-- silence, blindness, poison, disease - in-game item text). Muddle blocks item use.
-- One item per status at a time: none while the last one is still going (up to CURE_WAIT s for its finish
-- packet). If the status is still on after an item finished (an aura puts it straight back, e.g. Triboulex),
-- no more items for it for CURE_PAUSE s, or until it has been seen gone.
local CURE_WAIT, CURE_BACK, CURE_PAUSE = 8, 15, 60;
local cures = {}; -- [status] = { item, id, at, doneAt, pausedUntil }
local function use_cure(status, list)
    if (inc.settings.AutoRemedy == false) or has('Muddle') then return nil end
    local now = os.clock();
    local c = cures[status];
    if (c ~= nil) then
        if (c.pausedUntil ~= nil) and (now < c.pausedUntil) then return nil, 'AutoRemedy paused' end
        if (c.pausedUntil == nil) then
            if (c.doneAt == nil) then
                if (now - c.at < CURE_WAIT) then return nil, c.item .. ' in use' end -- no finish yet; after that it didn't go
            elseif (now - c.doneAt < 1) then
                return nil, c.item .. ' in use'; -- just landed: the buff list may not show it gone yet
            elseif (now - c.doneAt < CURE_BACK) then
                c.pausedUntil = now + CURE_PAUSE;
                say(status .. ' is back after ' .. c.item .. ' (an aura?): no more items for it for ' .. CURE_PAUSE .. 's');
                return nil, 'AutoRemedy paused';
            end
        end
    end
    for _, item in ipairs(list) do
        if (gcauto.ItemCount(item) > 0) then
            AshitaCore:GetChatManager():QueueCommand(-1, '/item "' .. item .. '" <me>');
            local res = AshitaCore:GetResourceManager():GetItemByName(item, 0);
            cures[status] = { item = item, id = (res ~= nil) and res.Id or nil, at = now };
            return item;
        end
    end
    return nil;
end

-- From gcinclude.OnItemAction (gcauto's 0x0028 reader): my item use finished (cmd 5, item id).
function gcaction.OnItemAction(cmd, id)
    if (cmd ~= 5) then return end
    for _, c in pairs(cures) do
        if (c.id == id) and (c.doneAt == nil) then c.doneAt = os.clock() end
    end
end

-- Seconds left on my own cast in progress (gcinclude.CastLeft: start/finish packets, or a cast sent whose start
-- packet isn't back yet); 0 without the tracker.
local function cast_left()
    if (inc ~= nil) and (inc.CastLeft ~= nil) then return inc.CastLeft() end -- also a cast sent but not started yet
    if (gcauto == nil) or (gcauto.CastLeft == nil) then return 0 end
    return gcauto.CastLeft(); -- seconds, spell id
end

-- Recast or your cast in progress: cancelled, reason in chat (the game refuses them, and a cancel keeps your
-- current cast's gear on). The spell you're casting pressed again is cancelled without a message.
local function on_wait(a, kind, recast)
    local casting, castId = cast_left();
    if (casting > 0) and (kind == 'Spell') and (castId ~= nil) and (a.Resource ~= nil) and (castId == a.Resource.Index) then
        return true;
    end
    if ((recast or 0) > 0) then say(a.Name .. ': recast ' .. mmss(recast)); return true end
    if (casting > 0) then say(a.Name .. ': casting'); return true end
    return false;
end

-- True when the pending action would fail; the caller cancels it. Runs before any gear goes on.
function gcaction.Check()
    if (inc.settings.Validate == false) then return false end
    local a = gData.GetAction();
    if (a == nil) or (a.Name == nil) then return false end
    -- The game's own resend (Sequencer plugin): checked when first sent, so it goes unless the server has
    -- started that cast (start packet seen); then it is cancelled without a message.
    if (a.Resend == true) then
        return (gcauto ~= nil) and (gcauto.CastLeft ~= nil) and (gcauto.CastLeft() > 0);
    end
    local player = gData.GetPlayer();
    if (player.HP == 0) then return true end
    for status, _ in pairs(cures) do
        if not has(status) then cures[status] = nil end -- gone: the next one gets an item again
    end
    for _, b in ipairs(inc.HardCC) do
        if has(b) then say(a.Name .. ': ' .. string.lower(b)); return true end
    end
    local kind = a.ActionType;
    if (kind == 'Spell') then
        if has('Mute') then say(a.Name .. ': mute'); return true end
        if has('Silence') then
            local item, why = use_cure('Silence', has('Paralysis') and { 'Remedy', 'Echo Drops' } or { 'Echo Drops', 'Remedy' });
            say(a.Name .. ': silenced' .. (item and (', using ' .. item) or (why and (' (' .. why .. ')') or '')));
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
            local item = use_cure('Paralysis', { 'Remedy' }); -- none (paused, in use): the ability goes anyway
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
