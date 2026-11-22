-- Action checks and recorded layers. Loaded and bound by gcinclude.
local gcaction = {}

local inc = nil

-- Ability recast ids (Windower res ability_recasts) whose timer is a charge pool, not the next use:
-- 102 Sic/Ready, 195 Quick Draw, 255 Ready. 231 Stratagems is counted by charges below.
local CHARGE_POOLS = { [102] = true, [195] = true, [255] = true }
local STRATAGEMS = 231
function gcaction.Bind(gcinclude)
    inc = gcinclude
end

local function say(msg) inc.Say(msg) end

local function has(name) return inc.BuffCount(name) > 0 end

local function mmss(sec)
    sec = math.max(0, math.ceil(sec))
    return string.format('%d:%02d', math.floor(sec / 60), sec % 60)
end

-- Seconds left on an ability recast id (gcinclude.RecastTimer is in 1/60 s).
local function ability_timer(rid)
    return inc.RecastTimer(rid) / 60
end

-- Stratagems in hand and seconds to the next, per Ashita's recast addon: the pool is 240s split by
-- SCH level (1/2/3/4/5 charges at 10/30/50/70/90), 33s a charge at 99 with 550 JP spent.
local function stratagems()
    local p = AshitaCore:GetMemoryManager():GetPlayer()
    local lvl = (p:GetMainJob() == 20) and p:GetMainJobLevel() or ((p:GetSubJob() == 20) and p:GetSubJobLevel() or 0)
    if (lvl < 10) then return 0, nil end
    local per = (lvl >= 90 and 48) or (lvl >= 70 and 60) or (lvl >= 50 and 80) or (lvl >= 30 and 120) or 240
    local max = 240 / per
    if (p:GetMainJob() == 20) and (p:GetMainJobLevel() == 99) and (p:GetJobPointsSpent(20) >= 550) then per = 33 end
    local t = ability_timer(STRATAGEMS)
    if (t <= 0) then return max, nil end
    local nextIn = t % per
    if (nextIn == 0) then nextIn = per end
    return math.max(0, math.floor((max * per - t) / per)), nextIn
end

-- Seconds left on my own cast in progress (gcinclude.CastLeft: start/finish packets, or a cast sent whose start
-- packet isn't back yet); 0 without the tracker.
local function cast_left()
    if (inc ~= nil) and (inc.CastLeft ~= nil) then return inc.CastLeft() end -- also a cast sent but not started yet
    if (gcauto == nil) or (gcauto.CastLeft == nil) then return 0 end
    return gcauto.CastLeft() -- seconds, spell id
end

-- Recast, or for a spell your cast in progress: cancelled, reason in chat (the game refuses them, and a cancel
-- keeps your current cast's gear on). The spell you're casting pressed again is cancelled without a message.
-- Weapon skills and abilities have no cast: never "casting" (one pressed mid-cast: gcinclude.MidCast).
local function on_wait(a, kind, recast)
    if (kind ~= 'Spell') then
        if ((recast or 0) > 0) then say(a.Name .. ': recast ' .. mmss(recast)); return true end
        return false
    end
    local casting, castId = cast_left()
    if (casting > 0) and (kind == 'Spell') and (castId ~= nil) and (a.Resource ~= nil)
        and (castId == a.Resource.Index) then
        return true
    end
    if ((recast or 0) > 0) then say(a.Name .. ': recast ' .. mmss(recast)); return true end
    if (casting > 0) then say(a.Name .. ': casting'); return true end
    return false
end

-- True when the pending action would fail; the caller cancels it. Runs before any gear goes on.
function gcaction.Check()
    local a = gData.GetAction()
    if (a == nil) or (a.Name == nil) then return false end
    -- The game's own resend (Sequencer plugin): checked when first sent, so it goes unless the server has
    -- started that cast (start packet seen); then it is cancelled without a message.
    if (a.Resend == true) then return (gcauto ~= nil) and (gcauto.CastLeft ~= nil) and (gcauto.CastLeft() > 0); end
    local player = gData.GetPlayer()
    if (player.HP == 0) then return true end
    for _, b in ipairs(inc.HardCC) do
        if has(b) then say(a.Name .. ': ' .. string.lower(b)); return true end
    end
    local kind = a.ActionType
    if (kind == 'Spell') then
        if has('Mute') then say(a.Name .. ': mute'); return true end
        if has('Silence') then say(a.Name .. ': silenced'); return true end
        local timer = AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(a.Resource.Index) / 60
        if on_wait(a, 'Spell', timer) then return true end
    elseif (kind == 'Ability') then
        if has('Amnesia') then say(a.Name .. ': amnesia'); return true end
        local rid = (a.Resource ~= nil) and a.Resource.RecastTimerId or nil
        if (rid == STRATAGEMS) then
            local n, nextIn = stratagems()
            if (n == 0) then
                say(a.Name .. ': no stratagems' .. (nextIn and (', next in ' .. mmss(nextIn)) or ''))
                return true
            end
            if on_wait(a, 'Ability', 0) then return true end
        elseif (rid ~= nil) and not CHARGE_POOLS[rid] then
            if on_wait(a, 'Ability', ability_timer(rid)) then return true end
        else
            if on_wait(a, 'Ability', 0) then return true end
        end
    elseif (kind == 'Weaponskill') then
        if has('Amnesia') then say(a.Name .. ': amnesia'); return true end
        if on_wait(a, 'Weaponskill', 0) then return true end
    end
    return false
end

-- Recorded layers, for /gcedit: each handler's writes to LAC's equip buffer, in order, each tagged with the set or
-- function that made it. LAC runs every event as ClearBuffer -> handler -> ProcessBuffer (ProcessImmediateBuffer for
-- a delayed midcast) (LuAshitacast state.lua HandleEquipEvent); gcinclude.WrapBuffer calls RecClear, RecWrite and
-- RecEnd from those, gcinclude.WrapEquip sets the tag (RecLabel). A cancelled action never reaches ProcessBuffer, so
-- it is never kept. Kept per key ('Idle', 'Engaged', 'Weaponskill Savage Blade', 'Midcast Cure IV'): the latest only.
-- GcRecords is a global so the records outlive /lac reload (the editor saves with one).
local EVENTS = { HandleDefault = 'Default', HandlePrecast = 'Precast', HandleMidcast = 'Midcast',
    HandleAbility = 'Ability', HandleWeaponskill = 'Weaponskill', HandlePreshot = 'Preshot', HandleMidshot = 'Midshot',
    HandleItem = 'Item' }
local rec, label, why = nil, nil, nil

-- LAC runs HandleDefault on every new outgoing packet chunk while no action is pending (packethandlers.lua
-- HandleOutgoingPacket), so it is recorded at most once a second, and at once when a mode or your status changes;
-- every other handler is recorded each time. Decided at the handler's first write: LAC sets CurrentCall after
-- ClearBuffer (state.lua HandleEquipEvent).
local DEFAULT_GAP = 1.0 -- seconds (not a game value)
local lastDefaultAt, lastDefaultKey = -math.huge, nil
local function default_key()
    local ver = ((gcdisplay ~= nil) and (gcdisplay.Version ~= nil)) and gcdisplay.Version() or 0
    local ok, status = pcall(function()
        local mm = AshitaCore:GetMemoryManager()
        return mm:GetEntity():GetStatus(mm:GetParty():GetMemberTargetIndex(0))
    end)
    return ver .. '/' .. tostring(ok and status or '?')
end
local function live()
    if (rec == nil) then return false end
    if (rec.skip == nil) then
        rec.skip = false
        if (gState.CurrentCall == 'HandleDefault') then
            local now, key = os.clock(), default_key()
            if ((now - lastDefaultAt) < DEFAULT_GAP) and (key == lastDefaultKey) then rec.skip = true
            else lastDefaultAt, lastDefaultKey = now, key end
        end
    end
    return not rec.skip
end
gcaction.Recording = live -- gcinclude.WrapEquip: work out a layer's reason (a stack walk) only for a recorded handler

function gcaction.RecClear()
    rec, label, why = { writes = {} }, nil, nil
end

-- A set name gcinclude.FindSet looked for and did not find, during the handler being recorded.
function gcaction.RecMiss(name)
    if not live() then return end
    rec.misses = rec.misses or {}
    local l = string.lower(name)
    if (rec.misses[l] == nil) and (#rec.misses < 40) then
        rec.misses[l] = true
        rec.misses[#rec.misses + 1] = name
        -- the job file line that looked for it (/gcedit shows it): the first call on the stack from that file
        local path = (gProfile ~= nil) and gProfile.FilePath or nil
        if (type(path) == 'string') and (debug ~= nil) and (debug.getinfo ~= nil) then
            path = string.lower((string.gsub(path, '/', '\\')))
            for lv = 2, 12 do
                local info = debug.getinfo(lv, 'Sl')
                if (info == nil) then break end
                local src = string.lower((string.gsub((string.gsub(tostring(info.source), '^@', '')), '/', '\\')))
                if (src == path) then
                    rec.missLine = rec.missLine or {}
                    rec.missLine[l] = info.currentline
                    break
                end
            end
        end
    end
end

-- new: the layer's name; chain: the functions that put it on (gcinclude.CallChain), for its reason in the editor.
function gcaction.RecLabel(new, chain)
    local oldL, oldW = label, why
    label, why = new, chain
    return oldL, oldW
end

-- slot: LAC's slot number (1 Main .. 16 Back); item: its item table, or a name. blocked: LAC drops it (slot locked).
function gcaction.RecWrite(slot, item, immediate, blocked, by)
    if (not live()) or (#rec.writes >= 96) then return end
    local name = (type(item) == 'table') and item.Name or item
    -- off: the slot is disabled (/lock, a hold): LAC's ProcessBuffer skips it
    local off = (gState ~= nil) and (gState.Disabled ~= nil) and (gState.Disabled[slot] == true) or nil
    rec.writes[#rec.writes + 1] = { slot = slot, name = (type(name) == 'string') and name or '?',
        by = by or label or '?',
        immediate = (immediate == true), blocked = (blocked == true), why = (by == nil) and why or nil, off = off }
end

-- What was on when the action ran: modes, toggles, HP/MP/TP, buffs (ids), for the reasons /gcedit gives.
local function snapshot(player)
    local st = { status = player.Status, tp = player.TP, hpp = player.HPP, mpp = player.MPP, moving = player.IsMoving }
    if (gcdisplay ~= nil) then
        local function cyc(n) local v = gcdisplay.GetCycle(n); return (v ~= 'Unknown') and v or nil end
        st.mset, st.wsset, st.idleset, st.hoxne = cyc('MeleeSet'), cyc('WsSet'), cyc('IdleSet'), cyc('Hoxne')
        st.weapons = cyc('Weapons') or cyc('Main')
        st.wmode = cyc('Weapons') -- the weapon mode alone: Tp_<mode>, Ws_<mode> (gcinclude.EquipMode)
        st.dt, st.mdt, st.aminon = gcdisplay.GetToggle('DTset'), gcdisplay.GetToggle('MDTset'),
            gcdisplay.GetToggle('Aminon')
        st.kite, st.th, st.sir, st.proc = gcdisplay.GetToggle('Kite'), gcdisplay.GetToggle('TH'),
            gcdisplay.GetToggle('SIR'), gcdisplay.GetToggle('PROC')
    end
    local ok, buffs = pcall(function() return AshitaCore:GetMemoryManager():GetPlayer():GetBuffs() end)
    if ok and (type(buffs) == 'table') then
        st.buffs = {}
        for _, b in pairs(buffs) do if (type(b) == 'number') and (b > 0)
            and (b ~= 255) then st.buffs[#st.buffs + 1] = b end end
    end
    return st
end

function gcaction.RecEnd()
    local keep = live() -- a handler that wrote nothing is decided here
    local r = rec
    rec, label, why = nil, nil, nil
    if (r == nil) or not keep then return end
    local event = EVENTS[gState.CurrentCall or '']
    if (event == nil) then return end
    local ok, player = pcall(gData.GetPlayer)
    player = ok and player or {}
    local key
    if (event == 'Default') then
        key = tostring(player.Status or 'Idle')
    else
        local a = gData.GetAction()
        if (a == nil) or (type(a.Name) ~= 'string') then return end
        key = event .. ' ' .. a.Name
        r.action = a.Name
    end
    r.key, r.event, r.time, r.tp = key, event, os.time(), player.TP
    local okS, st = pcall(snapshot, player)
    r.state = okS and st or nil
    r.job = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob() -- the editor shows this job's only
    key = r.job .. ' ' .. key
    GcRecords = GcRecords or { byKey = {}, order = {} }
    if (GcRecords.byKey[key] == nil) then
        GcRecords.order[#GcRecords.order + 1] = key
        if (#GcRecords.order > 300) then GcRecords.byKey[table.remove(GcRecords.order, 1)] = nil end
    end
    GcRecords.byKey[key] = r
    GcRecords.n = (GcRecords.n or 0) + 1 -- bumped on every record: /gcedit rebuilds its views only when it changes
    r.seq = GcRecords.n -- which came last (/gcedit last), finer than r.time's seconds
    -- Each slot's last write that went on, for /gcgear's hover (the set that put it on); the same piece again keeps
    -- the earlier layer, as /gcedit's layers do. A global, like GcRecords.
    GcWornBy = GcWornBy or {}
    local last = {}
    for _, w in ipairs(r.writes) do
        if (not w.blocked) and (not w.off) and (w.name ~= 'ignore') then
            local prev = last[w.slot]
            if (prev == nil) or (string.lower(prev.name) ~= string.lower(w.name)) then last[w.slot] = w end
        end
    end
    for slot, w in pairs(last) do GcWornBy[slot] = { name = w.name, by = w.by, key = r.key } end
end

return gcaction
