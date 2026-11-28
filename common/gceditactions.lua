-- /gcedit: action, replacement and related-set models (no drawing).
-- Build action, replacement, and related-set data. No ImGui calls or palette values.
-- The document and inventory are snapshots owned by the editor; callbacks read slots
-- and host resources. Drawing code consumes the returned view data.
local actionModel = {}
-- /wsset modes (gcinclude.WsSetKeys): the child key each wears over the WS sets worn, why, its word in the modes line
-- (wsOnly: no /mset mode wears them)
local WSSET = { Low = { key = 'LowBuff', why = 'WS low-buff mode (/wsset low)', word = 'WS low-buff', wsOnly = true },
    High = { key = 'HighBuff', why = 'WS high-buff mode (/wsset high)', word = 'WS high-buff', wsOnly = true },
    PDL = { key = 'PDL', why = 'WS PDL mode (/wsset pdl)', word = 'WS PDL', wsOnly = true },
    Acc = { key = 'Acc', why = 'WS acc mode (/wsset acc)', word = 'WS acc' },
    SubtleBlow = { key = 'SubtleBlow', why = 'WS subtle blow mode (/wsset sb)', word = 'WS subtle blow' } }
local WSSET_BY_KEY = {}
for mode, m in pairs(WSSET) do
    m.mode = mode
    WSSET_BY_KEY[m.key] = m
end
function actionModel.New(context)
    local document, inventory = context.document, context.inventory
    local gcdisplay = context.display
    local SCREEN, SLOT_BIT, NUM_SLOT = context.slots, context.slotBits, context.slotNames
    local current, has_set, filled, is_ws = context.current, context.hasSet, context.filled, context.isWeaponskill
    local item_id, gearEngine = context.itemId, context.engine
    local setFile = context.setFile
    local parsed = context.analysis
    local scan_job, eval_cond, resolve = parsed.Scan, parsed.Evaluate, parsed.Resolve
    local cycle_of, cycle_text, in_list, STATUS_TEXT =
        parsed.CycleOf, parsed.CycleText, parsed.InList, parsed.StatusText
    local function layers_of(r)
        local layers, final = {}, {}
        for _, w in ipairs(r.writes) do
            local slot = NUM_SLOT[w.slot] or tostring(w.slot)
            local L = layers[#layers]
            if (L == nil) or (L.by ~= w.by) then
                L = { by = w.by, why = w.why, reason = w.reason, writes = {} }
                layers[#layers + 1] = L
            end
            local entry = { slot = slot, name = w.name, blocked = w.blocked }
            L.writes[#L.writes + 1] = entry
            if not w.blocked then
                local prev = final[slot]
                if prev ~= nil then
                    -- the same piece again is no loss: the earlier layer still put it there
                    if string.lower(prev.name) == string.lower(w.name) then prev.entry.same = true end
                    prev.entry.won = false
                end
                entry.won = true
                final[slot] = { name = w.name, by = w.by, entry = entry, layer = L }
            end
        end
        return layers, final
    end

    local function is_set_label(by, name)
        local l, n = string.lower(by), string.lower(name)
        return (l == n) or (string.sub(l, 1, #n + 1) == (n .. '['))
    end

    -- A record's layer names, lower case, for is_set_label in one lookup: each name and each part before a '['
    -- (Buffs['Aftermath: Lv.3'] also counts as Buffs). Worked out once per record.
    local function labels_of(r)
        local t = r.gcLabels
        if t ~= nil then return t end
        t = {}
        for _, w in ipairs(r.writes) do
            local l = string.lower(w.by)
            if t[l] == nil then
                t[l] = true
                local at = string.find(l, '[', 1, true)
                while at ~= nil do
                    t[string.sub(l, 1, at - 1)] = true
                    at = string.find(l, '[', at + 1, true)
                end
            end
        end
        r.gcLabels = t
        return t
    end

    -- Records this set was worn in, newest first.
    local function records_for(name)
        local out = {}
        local records = context.getRecords()
        if records == nil then return out end
        local n = string.lower(name)
        for _, key in ipairs(records.order) do
            local r = records.byKey[key]
            if (r ~= nil) and (r.job == context.job) and labels_of(r)[n] then out[#out + 1] = r end
        end
        table.sort(out, function(x, y) return x.time > y.time end)
        return out
    end

    local KIND = {
        Default = '',
        Precast = 'spell, start of cast',
        Midcast = 'spell, as it goes off',
        Ability = 'job ability',
        Weaponskill = 'weapon skill',
        Preshot = 'ranged attack, start',
        Midshot = 'ranged attack, as it fires',
        Item = 'item',
    }
    local STATUS = { Idle = 'standing idle', Engaged = 'fighting (engaged)', Resting = 'resting' }

    -- what it was, and its kind ('weapon skill'; nil for idle/engaged/resting)
    local function action_parts(r)
        if r.event == 'Default' then return STATUS[r.seenKey or r.key] or (r.seenKey or r.key), nil end
        if r.expected and (r.label ~= nil) then
            return r.label, nil
        end -- expected, no action of its own: 'a weapon skill with no set of its own'
        local kind = KIND[r.event] or r.event
        return r.action or '?', (kind ~= '') and kind or nil
    end
    local function action_label(r)
        local main, kind = action_parts(r)
        return (kind ~= nil) and (main .. ' (' .. kind .. ')') or main
    end

    local function source_label(by)
        local engine = string.match(by, '^gcinclude%.sets%.(.+)$')
        if engine ~= nil then return 'engine set ' .. engine end
        local fn = string.match(by, '^(.+)%(%)$')
        if fn ~= nil then
            return ({
                WearWeaponLayer = 'Weapon mode',
                ruleEquip = 'Rule',
                ApplyElementGear = 'Element bonus',
                EquipIdle = 'Idle gear',
                EquipMode = 'Combat mode',
            })[fn] or ('Rule: ' .. fn)
        end
        return by
    end

    -- Why a layer went on, in plain words: from the functions that put it on (rec chain, closest first) and what was
    -- on at the time (r.state). Each line matches the gcinclude code that does it.
    local GENERIC = { ByName = true, EquipMode = true, EquipIdle = true }
    local function why(L, r)
        local by, st, cfg = L.by, r.state or {}, (gearEngine ~= nil) and gearEngine.settings or {}
        local engine = string.match(by, '^gcinclude%.sets%.(.+)$')
        local inner = string.match(by, "%['(.+)'%]$")
        local fn = nil
        for _, f in ipairs(L.why or {}) do
            if not GENERIC[f] then
                fn = f
                break
            end
        end
        local first = (L.why or {})[1]
        local R = {
            ruleWear = function() -- gcinclude.Rules
                local w = (gearEngine ~= nil) and gearEngine.RuleWhy or {}
                return 'a rule in your job file: ' .. tostring(w[by] or w[inner or ''] or 'gcinclude.Rules')
            end, ruleEquip = function()
                local w = (gearEngine ~= nil) and gearEngine.RuleWhy or {}
                return 'a rule in your job file: ' .. tostring(w['ruleEquip()'] or 'gcinclude.Rules')
            end,
            CheckCommonDebuffs = function()
                if (by == 'Sleeping') or (engine == 'Sleeping') then return 'you are asleep' end
                if (by == 'Doomed') or (engine == 'Doomed') then return 'Doom or Bane is on you' end
                return 'a status effect on you'
            end, CheckIncapacitated = function()
                return 'slept, petrified, stunned or terrorized: your defense set without weapons, then Incapacitated'
            end, wear = function()
                if by == 'Idle_Regen' then
                    return string.format(
                        'HP %s%% is below RegenGearHPP %s%%, out of combat',
                        tostring(st.hpp), tostring(cfg.RegenGearHPP)
                    )
                end
                if by == 'Idle_Refresh' then
                    return string.format(
                        'MP %s%% is below RefreshGearMPP %s%%, out of combat',
                        tostring(st.mpp), tostring(cfg.RefreshGearMPP)
                    )
                end
                if by == 'Dt' then
                    return string.format('HP %s%% is below DTGearHPP %s%%', tostring(st.hpp), tostring(cfg.DTGearHPP))
                end
                if by == 'Pet_Dt' then return 'pet HP below PetDTGearHPP' end
                return 'HP or MP low'
            end, SetTownGear = function()
                return 'you are in a town'
            end, CheckWeapons = function()
                return 'weapon mode '
                    .. tostring(st.weapons or '?')
                    .. ' (/wm)'
                    .. ((st.status ~= 'Engaged') and '; not fighting, so weapons your idle sets name win' or '')
            end, WearWeaponLayer = function() -- gcruntime: the weapon mode and slot picks, over the sets before
                return 'weapon mode ' .. tostring(st.weapons or '?') .. ' (/wm): its weapons go on over the sets '
                    .. 'before (/mw /sw /rw picks too)'
                    .. (((st.status ~= 'Engaged') and (cfg.IdleWeapons ~= false))
                        and '; not fighting, so weapons your idle sets name win' or '')
            end, BuildWeaponLayer = function()
                return 'weapon mode ' .. tostring(st.weapons or '?') .. ' (/wm)'
            end, CheckMDT = function()
                return (by == 'mdt') and 'MDT mode (/mdt)' or 'Aminon mode (/aminon)'
            end, CheckHoxne = function()
                return 'Hoxne Locked (/hoxne): the Ampulla goes in Ammo'
            end, CheckTH = function()
                return 'TH mode (/th): the mob is not tagged yet'
            end, CheckReceived = function()
                return 'a spell is coming at you (' .. by .. ')'
            end, CheckBuffSets = function()
                return tostring(inner or by) .. ' is up'
            end, CheckXIRoll = function()
                return 'standing idle with a roll at 11'
            end, CheckLockingRings = function()
                return 'a ring in use stays on (warp, experience...)'
            end, CheckMoonshade = function()
                return string.format(
                    'TP %s is below MoonshadeTP %s: Moonshade adds TP to the WS',
                    tostring(st.tp), tostring(cfg.MoonshadeTP)
                )
            end, ApplyElementGear = function()
                return 'element bonus: day, weather or distance (obi, Orpheus)'
            end, CheckSIR = function()
                return 'SIR mode (/sir): spell interruption'
            end, CheckLightBonus = function()
                return 'Healing Magic: LightBonus set'
            end, CheckAbsorb = function()
                return 'an Absorb- spell'
            end, CheckDaybreak = function()
                return 'Dispelga needs Daybreak in Main'
            end, StripWeaponSwaps = function()
                return 'SmartSwap: a light spell keeps your weapons'
            end, wearHoxneCombos = function()
                return 'Hoxne Locked + Enchantment up, and the buffs in the name are up'
            end, CheckHoxneWs = function()
                return 'Hoxne Locked + Enchantment up: Hoxne WS set'
            end, WearHoxne = function()
                local where = string.match(by, '^Hoxne_(%a+)')
                local tail = ({ Dt = ', DT mode (/dt)', Tp = ', fighting', Idle = ', standing idle' })[where or '']
                    or ''
                return 'Hoxne Locked + Enchantment up' .. tail
            end, CheckHoxneSets = function()
                return 'Hoxne Locked + Enchantment up'
            end, WearChildren = function()
                local key = string.match(by, '_([^_]+)$')
                if WSSET_BY_KEY[key or ''] ~= nil then return WSSET_BY_KEY[key].why end
                if key == 'Dt' then return 'DT mode (/dt)' end
                if key == 'Self' then return 'the spell is on yourself' end
                if key == 'Others' then return 'the spell is on someone else' end
                if key == 'Burst' then return 'magic burst: the spell lands in a skillchain' end
                return 'a child set of one worn before it'
            end, checkDefault = function()
                return 'Proc mode (/proc) while fighting'
            end,
        }
        if L.reason ~= nil then
            return L.reason
        end -- an expected layer says why itself
        if (fn ~= nil) and (R[fn] ~= nil) then return R[fn]() end
        if string.match(by, '^Sub ') then
            return by
        end -- 'Sub held: no Dual Wield', 'Sub dropped: ...'
        -- a set the job file (or a helper) wears by name
        if first == 'EquipIdle' then
            if by == 'Idle' then return 'base: Idle goes on first, every time' end
            return 'idle mode ' .. tostring(st.idleset) .. ' (/idleset), standing idle'
        end
        if first == 'EquipMode' then
            if by == 'Ws_Default' then return 'base: every weapon skill starts with it' end
            if by == 'Tp_Default' then return 'base while fighting' end
            if string.match(by, '_Default$') then return 'base set' end
            return 'melee mode ' .. tostring(st.mset) .. ' (/mset)'
        end
        if (st.mset ~= nil) and (st.mset ~= 'Default') and (string.sub(by, -(#st.mset + 1)) == ('_' .. st.mset)) then
            return 'melee mode ' .. st.mset .. ' (/mset)'
        end
        if (r.action ~= nil) and (string.lower(by) == string.lower(r.action)) then
            return 'the set named after ' .. r.action
        end
        if (by == 'Dt') or string.match(by, '^Dt_') then return 'DT mode (/dt)' end
        if by == 'Movement' then return st.kite and 'kite mode (/kite)' or 'you are moving' end
        if by == 'Resting' then return 'you are resting' end
        if string.match(by, '^Tp_') then return 'fighting (engaged)' end
        if string.match(by, '^Weapon_') then return 'weapon mode ' .. tostring(st.weapons) .. ' (/wm)' end
        if first == 'ByName' then return 'your job file wears it by name' end
        return 'your job file puts it on'
    end

    local function buff_names(st)
        local out, res = {}, context.resources
        for _, b in ipairs((st and st.buffs) or {}) do
            local n = res:GetString('buffs.names', b)
            if (type(n) == 'string') and (n ~= '') then out[#out + 1] = n end
        end
        return out
    end

    -- An item as the game spells it ('naegling' -> 'Naegling'): from your bags, else the item's resource, else as
    -- written.
    local function game_name(n)
        local g = (inventory.firstByName ~= nil) and inventory.firstByName[string.lower(n)] or nil
        if g ~= nil then return g.name end
        local id = item_id(n)
        local r = (id ~= nil) and context.resources:GetItemById(id) or nil
        if (r ~= nil) and (r.Name ~= nil) and (type(r.Name[1]) == 'string') and (r.Name[1] ~= '') then
            return r.Name[1]
        end
        return n
    end

    -- The picked record, worked out for drawing: the cover per slot, the table rows, the order list.
    local function layer_view(set, pick)
        local V = { rec = pick, set = set.name, ver = document.revision }
        local layers, final = layers_of(pick)
        local mineLost = {} -- this set's piece in a slot, when a later set replaced it
        for _, L in ipairs(layers) do
            if is_set_label(L.by, set.name) then
                for _, w in ipairs(L.writes) do
                    if not w.won and not w.same then mineLost[w.slot] = { name = w.name, blocked = w.blocked } end
                end
            end
        end
        V.cover = {}
        for slot, m in pairs(mineLost) do
            local by = (final[slot] ~= nil) and final[slot].by or '?'
            local short = string.match(by, '^gcinclude%.sets%.(.+)$') or string.match(by, '^(.+)%(%)$') or by
            V.cover[slot] = m.blocked and { short = 'a lock', full = 'a locked slot' }
                or { short = short, full = source_label(by) }
        end
        V.head = 'For ' .. action_label(pick) .. ':'
        if pick.expected then
            local st, on = pick.state, {}
            if (st.mset ~= nil) and (st.mset ~= 'Default') then on[#on + 1] = 'melee ' .. st.mset end
            if (st.idleset ~= nil) and (st.idleset ~= 'Default') then on[#on + 1] = 'idle ' .. st.idleset end
            if WSSET[st.wsset or ''] ~= nil then on[#on + 1] = WSSET[st.wsset].word end
            if st.dt then on[#on + 1] = 'DT' end
            if st.kite then on[#on + 1] = 'kite' end
            if st.proc then on[#on + 1] = 'proc' end
            V.head = 'Expected for ' .. action_label(pick) .. ' (not seen since load):'
            V.state = 'Modes now: '
                .. ((#on > 0) and table.concat(on, ', ') or 'none')
                .. ((pick.as ~= nil) and ('  (' .. pick.as .. ')') or '')
            V.buffs =
                "Your sets as the editor has them, unsaved changes too.\nLeft out until seen: weapons (/wm), Moonshade, obi, TH, buffs, Hoxne, your job file's own logic."
        elseif pick.state ~= nil then
            local st, on = pick.state, {}
            if (st.mset ~= nil) and (st.mset ~= 'Default') then on[#on + 1] = 'melee ' .. st.mset end
            if WSSET[st.wsset or ''] ~= nil then on[#on + 1] = WSSET[st.wsset].word end
            if st.dt then on[#on + 1] = 'DT' end
            if st.mdt then on[#on + 1] = 'MDT' end
            if st.aminon then on[#on + 1] = 'Aminon' end
            if st.kite then on[#on + 1] = 'kite' end
            if st.th then on[#on + 1] = 'TH' end
            if st.sir then on[#on + 1] = 'SIR' end
            if st.proc then on[#on + 1] = 'proc' end
            if st.hoxne == 'Locked' then on[#on + 1] = 'Hoxne' end
            V.state = string.format(
                'At the time: HP %s%%  MP %s%%  TP %s  |  weapons %s  |  modes on: %s',
                tostring(st.hpp),
                tostring(st.mpp),
                tostring(st.tp), tostring(st.weapons or '-'), (#on > 0) and table.concat(on, ', ') or 'none'
            )
            local bn = buff_names(st)
            if #bn > 0 then V.buffs = 'Buffs/effects on you: ' .. table.concat(bn, ', ') end
        end
        local num = {} -- layer -> its number in the order list
        for i, L in ipairs(layers) do
            num[L] = i
        end
        V.rows, V.still = {}, {}
        for _, slot in ipairs(SCREEN) do
            local f = final[slot]
            if (f == nil) and (mineLost[slot] == nil) then
                V.still[#V.still + 1] = slot -- slots no set touched, on one row
            else
                local row = { slot = slot }
                if f == nil then
                    row.worn, row.src, row.sourceRole = nil, 'no set: keeps what you had on', 'dim'
                else
                    row.worn = (f.name == 'ignore') and '(left empty)' or game_name(f.name)
                    local n = ((f.layer ~= nil) and num[f.layer]) and (num[f.layer] .. '. ') or ''
                    if is_set_label(f.by, set.name) then
                        row.src, row.sourceRole = n .. 'this set', 'blue'
                    else
                        local lab = source_label(f.by)
                        row.src, row.sourceRole = n .. lab, string.match(lab, '^engine ') and 'dim' or 'text'
                    end
                end
                local m = mineLost[slot]
                if m ~= nil then
                    row.replacedName = game_name(m.name)
                    row.locked = m.blocked
                end
                V.rows[#V.rows + 1] = row
            end
        end
        V.still = (#V.still > 0) and table.concat(V.still, ' ') or nil
        -- the order the sets went on: each one's pieces by slot (cells, in the equipment screen's order: worn, the
        -- same piece put on again later, or replaced by a later one, which says by what), and why it went on
        V.order = {}
        local at = {}
        for i, slot in ipairs(SCREEN) do at[slot] = i end
        local function in_screen_order(t)
            table.sort(t, function(a, b) return (at[a] or 99) < (at[b] or 99) end)
            return t
        end
        for i, L in ipairs(layers) do
            local won, same, lost, cells, by = {}, {}, {}, {}, {}
            for _, w in ipairs(L.writes) do
                local c = { name = w.name, state = 'won' }
                if w.won then
                    won[#won + 1] = w.slot
                elseif w.same then
                    same[#same + 1] = w.slot
                    c.state = 'same'
                else
                    local f = final[w.slot]
                    by[w.slot] = w.blocked and 'a lock'
                        or (((f ~= nil) and (f.layer ~= nil) and (num[f.layer] ~= nil))
                            and (num[f.layer] .. '. ' .. source_label(f.by)) or nil)
                    lost[#lost + 1] = w.slot
                    c.state, c.by = 'lost', by[w.slot]
                end
                if at[w.slot] ~= nil then cells[at[w.slot]] = c end
            end
            in_screen_order(won)
            in_screen_order(same)
            in_screen_order(lost)
            for k, slot in ipairs(lost) do
                if by[slot] ~= nil then lost[k] = slot .. ' (by ' .. by[slot] .. ')' end
            end
            local label = source_label(L.by)
            if L.by == 'WearWeaponLayer()' then label = label .. ' ' .. tostring((pick.state or {}).weapons or '?') end
            local reason = tostring(why(L, pick) or '')
            if string.sub(reason, -1) ~= '.' then reason = reason .. '.' end
            V.order[i] = {
                title = i .. '. ' .. label,
                rawSource = L.by,
                mine = is_set_label(L.by, set.name),
                why = string.upper(string.sub(reason, 1, 1)) .. string.sub(reason, 2),
                won = (#won > 0) and ('worn: ' .. table.concat(won, ' ')) or nil,
                same = (#same > 0) and ('same piece put on again later: ' .. table.concat(same, ' ')) or nil,
                lost = (#lost > 0) and ('replaced later: ' .. table.concat(lost, ', ')) or nil,
                cells = cells,
            }
        end
        return V
    end

    local SLOT_NUM = {}
    for name, b in pairs(SLOT_BIT) do
        SLOT_NUM[name] = b + 1
    end
    -- Spell skill ids (the spell resource's Skill) to the names LAC's spell.Skill gives (Windower res skills 32-45).
    local SKILL = {
        [32] = 'Divine Magic',
        [33] = 'Healing Magic',
        [34] = 'Enhancing Magic',
        [35] = 'Enfeebling Magic',
        [36] = 'Elemental Magic',
        [37] = 'Dark Magic',
        [38] = 'Summoning Magic',
        [39] = 'Ninjutsu',
        [40] = 'Singing',
        [41] = 'String Instrument',
        [42] = 'Wind Instrument',
        [43] = 'Blue Magic',
        [44] = 'Geomancy',
        [45] = 'Handbell',
    }
    local SKILL_OF = {}
    for _, n in pairs(SKILL) do
        SKILL_OF[string.lower(n)] = n
    end

    local family = gearEngine.Family -- 'Utsusemi: Ni' -> 'Utsusemi', 'Cure IV' -> 'Cure'

    local function modes_now() -- as gcaction's snapshot reads them
        local st = {}
        if gcdisplay == nil then return st end
        local function cyc(n)
            local v = gcdisplay.GetCycle(n)
            return (v ~= 'Unknown') and v or nil
        end
        st.mset, st.wsset, st.idleset, st.hoxne = cyc('MeleeSet'), cyc('WsSet'), cyc('IdleSet'), cyc('Hoxne')
        st.weapons = cyc('Weapons') or cyc('Main')
        st.wmode = cyc('Weapons')
        st.dt, st.kite, st.proc =
            gcdisplay.GetToggle('DTset') == true,
            gcdisplay.GetToggle('Kite') == true, gcdisplay.GetToggle('PROC') == true
        return st
    end

    -- The action a set is for, and the modes to show it under: { event, key, action, label, as } or nil.
    -- A mode set (Tp_Acc, Idle_Regen, Savage Blade_HighBuff) is shown as if its mode were on ('as').
    -- A weapon mode by name (any case): one of the game's /wm values, or a Weapon_<name> set in the file. nil: none.
    local function weapon_of(name)
        local lname = string.lower(name)
        for _, v in ipairs(((gcdisplay ~= nil) and gcdisplay.GetCycleValues('Weapons')) or {}) do
            if (string.lower(v) == lname) and (lname ~= 'none') then return v end
        end
        local set = document.model.byLower['weapon_' .. lname]
        return (set ~= nil) and string.sub(set.name, 8) or nil
    end
    local HANDS = { ['2h'] = 'a two-handed weapon', ['1h'] = 'a one-handed weapon' }
    -- The weapon modes: gcinclude.WeaponModes for the loaded job, then the file's other Weapon_<mode> sets.
    -- worked out once per edit (the editor's menus and headers ask every frame); a copy each time: callers add to it
    local modesMemo = nil
    local function weapon_modes()
        local p = context.getPlayer()
        local live = ((gearEngine ~= nil) and (type(gearEngine.WeaponModes) == 'table') and (p ~= nil)
            and (context.job == p:GetMainJob())) and gearEngine.WeaponModes or nil
        if (modesMemo ~= nil) and (modesMemo.rev == document.revision) and (modesMemo.live == live)
            and (modesMemo.n == #(document.newModes or {})) then
            local copy = {}
            for i, m in ipairs(modesMemo.list) do copy[i] = m end
            return copy
        end
        local out, seen = {}, {}
        local function gone(m) -- its Weapon_ set is staged for deletion
            local s = document.model.byLower[string.lower('Weapon_' .. m)]
            return (s ~= nil) and (s.parentName == nil) and ((document.deleted or {})[s.name] ~= nil)
        end
        local function add(m)
            if (type(m) == 'string') and (m ~= 'None') and not seen[string.lower(m)] and not gone(m) then
                seen[string.lower(m)], out[#out + 1] = true, m
            end
        end
        for _, m in ipairs(live or {}) do add(m) end
        -- the file's Weapon_<mode> sets; not one that is another's own (Weapon_MpuAcc: Mpu with /mset Acc)
        local cands, msets = {}, setFile.MeleeModes(document.model.text, document.newModes)
        for _, s in ipairs(document.model.list) do cands[#cands + 1] = string.match(s.name, '^Weapon_([^_]+)$') end
        for _, m in ipairs(cands) do
            local own = false
            for _, list in ipairs({ cands, out }) do
                for _, base in ipairs(list) do
                    if (base ~= m) and setFile.WeaponVariantOf('Weapon_' .. m, base, msets) then own = true end
                end
            end
            if not own then add(m) end
        end
        modesMemo = { rev = document.revision, live = live, n = #(document.newModes or {}), list = out }
        local copy = {}
        for i, m in ipairs(out) do copy[i] = m end
        return copy
    end
    -- name split at its first _ whose left part is an action (Savage Blade_Naegling_Acc: Savage Blade,
    -- Naegling_Acc). nil when no part is.
    local function split_action(n, is_action)
        local at = 1
        while true do
            local i = string.find(n, '_', at, true)
            if i == nil then return nil end
            if is_action(string.sub(n, 1, i - 1)) then return string.sub(n, 1, i - 1), string.sub(n, i + 1) end
            at = i + 1
        end
    end

    local function action_for(set, st)
        local n, res = set.name, context.resources
        -- weaponToo: Tp_/Ws_ (EquipMode) also take a weapon mode; ws: a WS set (/wsset acc / sb wear its _Acc /
        -- _SubtleBlow)
        local function mset_of(suffix, weaponToo, ws)
            if (WSSET_BY_KEY[suffix] ~= nil) and WSSET_BY_KEY[suffix].wsOnly then -- LowBuff, HighBuff, PDL
                st.wsset = WSSET_BY_KEY[suffix].mode
                return 'as if ' .. WSSET_BY_KEY[suffix].why
            end
            if string.lower(suffix) == 'dt' then
                st.dt = true
                return 'as if DT mode (/dt)'
            end
            local rest = string.match(suffix, '^(.+)_[Dd][Tt]$') -- Acc_Dt, HighBuff_DT: /dt over the rest
            if rest ~= nil then
                st.dt = true
                return mset_of(rest, weaponToo, ws) .. ', DT mode (/dt)'
            end
            if suffix == 'Proc' then
                st.proc = true
                return 'as if proc mode (/proc)'
            end
            -- a weapon mode (Tp_Chango), or a weapon mode and a melee mode (Tp_Chango_Acc); a weapon type (Tp_2h)
            local h = weaponToo and HANDS[string.lower(suffix)] and string.lower(suffix) or nil
            if h ~= nil then
                st.hands = h
                return 'as if ' .. HANDS[h] .. ' with no set of its own is on'
            end
            local w = weaponToo and weapon_of(suffix) or nil
            if w ~= nil then
                st.wmode = w
                return 'as if weapon mode ' .. w .. ' (/wm)'
            end
            local wpart, mpart = string.match(suffix, '^(.+)_([^_]+)$')
            local h2 = (weaponToo and (wpart ~= nil) and HANDS[string.lower(wpart)]) and string.lower(wpart) or nil
            if h2 ~= nil then
                st.hands = h2
                return 'as if ' .. HANDS[h2] .. ' with no set of its own is on, ' .. mset_of(mpart, false, ws)
            end
            local w2 = (weaponToo and (wpart ~= nil)) and weapon_of(wpart) or nil
            if w2 ~= nil then
                st.wmode = w2
                return 'as if weapon mode ' .. w2 .. ' (/wm), ' .. mset_of(mpart, false, ws)
            end
            local modes = {}
            for _, m in ipairs(((gcdisplay ~= nil) and gcdisplay.GetCycleValues('MeleeSet'))
                or setFile.MeleeModes(document.model.text)) do -- a job file not loaded: its own list
                modes[#modes + 1] = m
            end
            for _, m in ipairs(document.newModes or {}) do
                modes[#modes + 1] = m
            end
            for _, m in ipairs(modes) do
                if string.lower(m) == string.lower(suffix) then
                    st.mset = m
                    return 'as if melee mode ' .. m .. ' (/mset)'
                end
            end
            if ws and (WSSET_BY_KEY[suffix] ~= nil) then -- /wsset acc / sb, not an /mset mode here
                st.wsset = WSSET_BY_KEY[suffix].mode
                return 'as if ' .. WSSET_BY_KEY[suffix].why
            end
            -- not a mode (MNK's _Impetus, _Footwork): the job file wears it by its own logic, which this view leaves
            -- out
            return n .. ' is no mode: your job file wears it by its own logic, not shown here'
        end
        if n == 'Idle' then return { event = 'Default', key = 'Idle' } end
        -- Idle_<weapon> / Idle_2h, then with an idle mode (Idle_Chango_Refresh); else Idle_<mode>
        local iw, irest = string.match(n, '^Idle_([^_]+)_?(.*)$')
        if (iw ~= nil) and (HANDS[string.lower(iw)] or weapon_of(iw)) then
            local as
            if HANDS[string.lower(iw)] then
                st.hands = string.lower(iw)
                as = 'as if ' .. HANDS[st.hands] .. ' with no set of its own is on'
            else
                st.wmode = weapon_of(iw)
                as = 'as if weapon mode ' .. st.wmode .. ' (/wm)'
            end
            if string.match(irest, '^%a+$') then
                st.idleset = irest
                as = as .. ', idle mode ' .. irest .. ' (/idleset)'
            end
            return { event = 'Default', key = 'Idle', as = as }
        end
        local im = string.match(n, '^Idle_(%a+)$')
        if im ~= nil then
            st.idleset = im
            return { event = 'Default', key = 'Idle', as = 'as if idle mode ' .. im .. ' (/idleset)' }
        end
        if n == 'Dt' then
            st.dt = true
            return { event = 'Default', key = 'Idle', as = 'as if DT mode (/dt)' }
        end
        local dsuf = string.match(n, '^Dt_(.+)$') -- ByName('Dt'): Dt_Chango, Dt_2h, Dt_Acc, Dt_Chango_Acc
        if dsuf ~= nil then
            st.dt = true
            return { event = 'Default', key = 'Idle', as = mset_of(dsuf, true), dt = true }
        end
        if n == 'Movement' then
            st.kite = true
            return { event = 'Default', key = 'Idle', as = 'as if kite mode (/kite)' }
        end
        if n == 'Resting' then return { event = 'Default', key = 'Resting' } end
        if n == 'Tp_Default' then return { event = 'Default', key = 'Engaged' } end
        local tm = string.match(n, '^Tp_(.+)$')
        if tm ~= nil then return { event = 'Default', key = 'Engaged', as = mset_of(tm, true) } end
        if n == 'Ws_Default' then
            return { event = 'Weaponskill', action = nil, label = 'a weapon skill with no set of its own' }
        end
        local wm = string.match(n, '^Ws_(.+)$')
        if wm ~= nil then
            return { event = 'Weaponskill', label = 'a weapon skill with no set of its own',
                as = mset_of(wm, true, true) }
        end
        if is_ws(n) then return { event = 'Weaponskill', action = n } end
        local wb, wsuf = split_action(n, is_ws) -- Savage Blade_Acc, Savage Blade_Naegling, Savage Blade_Naegling_Acc
        if wb ~= nil then return { event = 'Weaponskill', action = wb, as = mset_of(wsuf, true, true) } end
        if n == 'Precast' then
            return { event = 'Precast', label = 'a spell with no sets of its own, start of cast' }
        end
        if n == 'Midcast' then
            return { event = 'Midcast', label = 'a spell with no sets of its own, as it goes off' }
        end
        local sk = SKILL_OF[string.lower(n)]
        if sk ~= nil then
            return { event = 'Midcast', label = 'any ' .. sk .. ' spell with no set of its own', skill = sk }
        end
        local pre = string.match(n, '^(.+)_Precast$')
        if pre ~= nil then
            local psk = SKILL_OF[string.lower(pre)]
            if psk ~= nil then
                return { event = 'Precast', label = 'any ' .. psk .. ' spell, start of cast', skill = psk }
            end
            local r = res:GetSpellByName(pre, 0)
            if r ~= nil then return { event = 'Precast', action = pre, skill = SKILL[r.Skill] } end
        end
        local sp = res:GetSpellByName(n, 0)
        if sp ~= nil then return { event = 'Midcast', action = n, skill = SKILL[sp.Skill] } end
        if res:GetAbilityByName(n, 0) ~= nil then return { event = 'Ability', action = n } end
        local ab, asuf = split_action(n, function(b) return res:GetAbilityByName(b, 0) ~= nil end)
        if ab ~= nil then return { event = 'Ability', action = ab, as = mset_of(asuf, true) } end
        return nil
    end

    -- The name set's copy for weapon mode w (or '2h' / '1h') takes: Tp_Default -> Tp_Chango, Tp_Acc -> Tp_Chango_Acc,
    -- Idle_Refresh -> Idle_Chango_Refresh, Savage Blade -> Savage Blade_Chango. nil: no base for one (a spell, a
    -- weapon set, one already for a weapon).
    local function variant_name(set, w)
        local n, l = set.name, string.lower(set.name)
        if (l == 'tp_default') or (l == 'ws_default') then return string.sub(n, 1, 2) .. '_' .. w end
        if (n == 'Idle') or (n == 'Dt') then return n .. '_' .. w end
        local st = {}
        local a = action_for(set, st)
        if (a == nil) or (st.wmode ~= nil) or (st.hands ~= nil) or st.proc or (st.wsset ~= nil) then return nil end
        local byName = ((a.event == 'Weaponskill') or (a.event == 'Ability')) and (a.action ~= nil)
        if byName and (a.action == n) then return n .. '_' .. w end
        local mode = st.mset or st.idleset
        local base = (mode ~= nil) and string.sub(n, 1, #n - #mode - 1) or nil
        if (base == nil) or (string.lower(string.sub(n, -#mode)) ~= string.lower(mode)) then return nil end
        local lb = string.lower(base)
        if byName or (lb == 'tp') or (lb == 'ws') or (lb == 'dt') or ((lb == 'idle') and (st.idleset ~= nil)) then
            return base .. '_' .. w .. '_' .. string.sub(n, -#mode)
        end
        return nil
    end

    -- A plain-language summary for the set header. The order and overwrite details remain in Equipped result.
    -- A /wm mode's weapon set (gcruntime modeSet / WeaponSetFor): Weapon_<mode>, else its own variant (_1h when you
    -- can't dual wield, <mset> or _<mset> with that /mset mode, both). Its description and short label, else nil.
    local function weapon_set_when(set)
        local rest = (set.parentName == nil) and string.match(set.name, '^Weapon_(.+)$') or nil
        if rest == nil then return nil end
        local msets = setFile.MeleeModes(document.model.text, document.newModes)
        for _, m in ipairs(weapon_modes()) do
            local lm, lr = string.lower(m), string.lower(rest)
            if lr == lm then
                return 'While /wm ' .. m .. ' is on: the weapons it names are the ones you wear and go back to (an action '
                    .. 'set that names a weapon still swaps it). Its own sets take its place: Weapon_' .. m .. '_1h when '
                    .. 'you can\'t dual wield, Weapon_' .. m .. '<mset> with an /mset mode.', '/wm ' .. m
            end
            if setFile.WeaponVariantOf(set.name, m, msets) then
                local oneHand = string.match(lr, '_1h$') ~= nil
                local ms = string.gsub(string.gsub(string.sub(rest, #m + 1), '_1h$', ''), '^_', '')
                local cond = ((ms ~= '') and (' with /mset ' .. ms) or '')
                    .. (oneHand and ((ms ~= '') and ',' or '') .. " when you can't dual wield" or '')
                return '/wm ' .. m .. cond .. ': worn in place of Weapon_' .. m .. ', so its weapons are the ones you wear '
                    .. 'and go back to.', '/wm ' .. m .. cond
            end
        end
        return nil
    end

    -- == "Used for": when a set goes on. ==
    -- What GoomSwap wears by itself, by the set's name (gcinclude CheckDefault / CheckWeapons, the midcast checks):
    -- { short label, sentence }.
    local ENGINE_WHEN = {
        town = { 'in a town', 'In a town (gcinclude.Towns), whatever you are doing: GoomSwap puts it on over your sets.' },
        mdt = { '/def MDT', 'While /def is on MDT: GoomSwap puts it on over your sets (for /def Aminon too, when '
            .. 'Aminon is missing or empty).' },
        aminon = { '/def Aminon', 'While /def is on Aminon: GoomSwap puts it on over your sets (mdt in its place when '
            .. 'it is missing or empty).' },
        sir = { 'spells, /sir on', 'Spells while /sir is on, as they go off (midcast), over your midcast sets; not the '
            .. 'spells in SIRSkip.' },
        th = { '/th on, untagged mob', 'While /th is on, until the mob is tagged: an action at an untagged mob, or '
            .. 'engaged with one targeted (THF: all the time). Not at rest, nor THSkip spells.' },
        xiroll = { 'idle, a roll at 11', 'Idle only, while one of your rolls totals 11 (XIRollSet when this set is '
            .. 'empty).' },
        proc = { 'engaged, /proc on', 'Engaged with /proc on: in place of your engaged sets, only this and the weapon '
            .. 'mode go on (to hit a mob without killing it).' },
        incapacitated = { 'slept, petrified, stunned or terrorized', 'While slept, petrified, stunned or terrorized: '
            .. 'your /def set (mdt or Aminon, else Dt) without its weapons, then this one, over everything.' },
        sleeping = { 'asleep', "While asleep, over everything (GoomSwap's own Sleeping set when this one is empty)." },
        doomed = { 'doomed (Doom, Bane)', "While doomed (Doom or Bane), over everything (GoomSwap's own Doomed set "
            .. 'when this one is empty).' },
        lightbonus = { 'Healing Magic', 'Healing Magic spells as they go off (midcast), over your midcast sets.' },
    }
    -- What GoomSwap also wears by itself below a threshold (SetRegenRefreshGear), over your sets: { short, sentence }.
    local AUTO_WHEN = {
        dt = { 'below DTGearHPP% HP', 'GoomSwap also puts it on by itself below DTGearHPP% HP (GoomSwap settings; 0: never), '
            .. 'whatever you are doing.' },
        idle_regen = { 'below RegenGearHPP% HP', 'GoomSwap also puts it on by itself below RegenGearHPP% HP '
            .. '(GoomSwap settings; 0: never), out of combat and without /dt.' },
        idle_refresh = { 'below RefreshGearMPP% MP', 'GoomSwap also puts it on by itself below RefreshGearMPP% MP '
            .. '(GoomSwap settings; 0: never), out of combat and without /dt.' },
        pet_dt = { 'pet below PetDTGearHPP% HP', "GoomSwap puts it on by itself while your pet is below "
            .. 'PetDTGearHPP% HP (GoomSwap settings; 0: never).' },
    }
    local STATUS_WORD = { engaged = true, idle = true, resting = true } -- the job analysis' status words
    local EVENT_HANDLER = { Default = 'HandleDefault', Precast = 'HandlePrecast', Midcast = 'HandleMidcast',
        Ability = 'HandleAbility', Weaponskill = 'HandleWeaponskill', Preshot = 'HandlePreshot',
        Midshot = 'HandleMidshot', Item = 'HandleItem' }
    local EVENT_ALL = { Default = 'idle and engaged', Precast = 'every precast', Midcast = 'every spell',
        Ability = 'every ability', Weaponskill = 'every weapon skill', Preshot = 'every ranged attack',
        Midshot = 'every ranged attack', Item = 'every item' }

    -- Where the job file's handlers wear this set, read from the file (not run): { event, line, conds, nots } in file
    -- order. conds: what has to be on (moving, kite mode, tank mode Main); nots: the earlier branches of its if
    -- (not engaged).
    local function job_uses(set)
        if document.model.scan == nil then -- read once per file
            local ok, r = pcall(scan_job, document.model.text or '')
            document.model.scan = ok and r or {}
        end
        local uses = {}
        for ev, refs in pairs(document.model.scan) do
            for _, r in ipairs(refs) do
                if (r.kind ~= 'idle') and (r.kind ~= 'mode') and (r.kind ~= 'th') then
                    local n, pre, rest = resolve(r.arg, {}, r.vars)
                    local built, cycWord = nil, nil -- a name built from a mode: FindSet('Tank_' .. tank)
                    if (n == nil) and (pre ~= nil) and (pre ~= '')
                        and (string.sub(set.lname, 1, #pre) == string.lower(pre)) then
                        local cyc = cycle_of(rest, r.vars)
                        if cyc ~= nil then
                            n, built = set.name, cycle_text(cyc, string.sub(set.name, #pre + 1))
                            cycWord = 'not ' .. cycle_text(cyc, '') -- 'not tank mode None': the mode says it
                        end
                    end
                    if (n ~= nil) and (string.lower(n) == set.lname) then
                        local conds, nots, status = {}, {}, false
                        for _, f in ipairs(r.frames) do
                            for _, p in ipairs(f.prior) do -- an earlier branch of its if: only a status says much
                                local _, t = eval_cond(p, {}, r.vars)
                                for _, x in ipairs(t or {}) do
                                    if STATUS_WORD[x] then nots[#nots + 1] = 'not ' .. x end
                                end
                            end
                            if f.cond ~= nil then
                                local _, t = eval_cond(f.cond, {}, r.vars)
                                for _, x in ipairs(t or {}) do
                                    if (cycWord == nil) or (string.sub(x, 1, #cycWord) ~= cycWord) then
                                        conds[#conds + 1] = x
                                    end
                                    if STATUS_WORD[x] then status = true end
                                end
                            end
                        end
                        if status then nots = {} end -- resting, not engaged: resting says it
                        if built ~= nil then conds[#conds + 1] = built end
                        uses[#uses + 1] = { event = ev, line = r.line, conds = conds, nots = nots, kind = r.kind }
                    end
                end
            end
        end
        table.sort(uses, function(x, y) return x.line < y.line end)
        return uses
    end
    -- The modes a ByName set's version is worn with, from the rest of its name after the base ('Acc': 'melee mode
    -- Acc (/mset)', a /wm mode, 2h / 1h, or both: 'Fomalhaut_Acc'); nil when it is none (MNK's _Impetus: the job
    -- file's own logic). Read as Dt's version would be, which takes all of them.
    local function version_modes(rest)
        local st = {}
        local a = action_for({ name = 'Dt_' .. rest, lname = string.lower('Dt_' .. rest) }, st)
        if (a == nil) or ((st.mset == nil) and (st.wmode == nil) and (st.hands == nil)) then return nil end
        return (string.gsub(tostring(a.as or ''), '^as if ', ''))
    end
    -- Where the job file wears this set as another's version: ByName(base) also wears base_<wm>, base_<mset> and
    -- base_<wm>_<mset> when made (Midshot_Acc for ByName('Midshot')). The base's ByName uses, each with the modes.
    local function version_uses(set)
        local i = 0
        while true do
            i = string.find(set.name, '_', i + 1, true)
            if i == nil then return {} end
            local base, rest = string.sub(set.name, 1, i - 1), string.sub(set.name, i + 1)
            local modes = has_set(base) and version_modes(rest) or nil
            if modes ~= nil then
                local out = {}
                for _, u in ipairs(job_uses({ name = base, lname = string.lower(base) })) do
                    if u.kind == 'byname' then
                        local conds = {}
                        for _, c in ipairs(u.conds) do conds[#conds + 1] = c end
                        if #conds == 0 then conds[1] = EVENT_ALL[u.event] or u.event end
                        conds[#conds + 1] = 'with ' .. modes
                        out[#out + 1] = { event = u.event, line = u.line, conds = conds, nots = u.nots }
                    end
                end
                if #out > 0 then return out end
            end
        end
    end
    -- The job file's uses as a sentence (each with its handler and line) and a short label.
    local function uses_text(uses)
        local parts, shorts, seen = {}, {}, {}
        for _, u in ipairs(uses) do
            local what = (#u.conds > 0) and table.concat(u.conds, ', ') or (EVENT_ALL[u.event] or u.event)
            parts[#parts + 1] = what .. ((#u.nots > 0) and (', ' .. table.concat(u.nots, ', ')) or '') .. ' ('
                .. (EVENT_HANDLER[u.event] or u.event) .. ', line ' .. u.line .. ')'
            if not seen[what] then seen[what], shorts[#shorts + 1] = true, what end
        end
        return 'Your job file wears it: ' .. table.concat(parts, '; ') .. '.', table.concat(shorts, ' / ')
    end
    -- *_Received: the spells ReceivedSets sends to this set.
    local function received_when(set)
        if not string.match(set.lname, '_received$') then return nil end
        local cfg = (gearEngine ~= nil) and gearEngine.settings or {}
        local names = {}
        for k, v in pairs((type(cfg.ReceivedSets) == 'table') and cfg.ReceivedSets or {}) do
            if (type(v) == 'string') and (string.lower(v) == set.lname) then names[#names + 1] = k end
        end
        table.sort(names)
        local what = (#names > 0) and table.concat(names, ', ') or 'a spell (ReceivedSets)'
        return 'When ' .. what .. ' is on its way to you from another box (ReceivedSets; for up to ReceivedWindow '
            .. 'seconds), over your sets.', what .. ' coming at you'
    end

    -- The sentence for "Used for", and its short label (nil: the sentence's first part). GoomSwap's own triggers
    -- first, then the action the set's name is for, then where the job file's code wears it. Nothing: the marker
    -- 'No built-in trigger' (the editor says whether the job file names it).
    -- A set inside Buffs / Buffs_Tp / Buffs_Idle / Buffs_Ws / Buffs_Precast / Buffs_Midcast: worn while its buff is up
    -- (gcinclude.CheckBuffSets, at the end of HandleDefault / weapon skills / precast / midcast).
    local BUFF_HOLDER = { buffs = { 'idle and engaged', '' }, buffs_tp = { 'engaged only', ', engaged' },
        buffs_idle = { 'idle only (not engaged)', ', idle' }, buffs_ws = { 'on weapon skills', ', weapon skills' },
        buffs_precast = { 'on spells (precast)', ', precast' }, buffs_midcast = { 'on spells (midcast)', ', spells' } }
    local function when_description(set)
        local holder = (set.parentName ~= nil) and BUFF_HOLDER[string.lower(set.parentName)] or nil
        if (holder ~= nil) and (set.key ~= nil) then
            return 'While ' .. set.key .. ' is up, ' .. holder[1] .. ': GoomSwap puts it on over your sets (name it as '
                .. 'the buff list shows it).', set.key .. ' up' .. holder[2]
        end
        -- an ability group (DNC's ['Step']): the job file's HandleAbility wears it by name on each of them
        if (set.parentName == nil) and (context.abilityKinds ~= nil) and context.abilityKinds()[set.name] then
            return 'On every ability with ' .. set.name .. " in its name: your job file's HandleAbility puts it on, "
                .. "then the ability's own set (Box Step) over it.", 'every ability with ' .. set.name
        end
        local wtext, wshort = weapon_set_when(set)
        if wtext ~= nil then return wtext, wshort end
        local text, short
        local engine = ENGINE_WHEN[set.lname]
        if engine ~= nil then
            text, short = engine[2], engine[1]
        else
            text, short = received_when(set)
        end
        if text == nil then
            local a = action_for(set, modes_now())
            if a ~= nil then
                if a.event == 'Midcast' then
                    if a.action ~= nil then
                        text = 'When ' .. a.action .. ' goes off (midcast).'
                    elseif a.skill ~= nil then
                        text = 'When any ' .. a.skill .. ' spell goes off (midcast).'
                    else
                        text =
                            'Every spell, as it goes off (midcast). This is the base layer; skill- and spell-specific sets go on afterward and can replace its slots. Empty slots keep the gear already worn, including Precast gear.'
                    end
                elseif a.event == 'Precast' then
                    if a.action ~= nil then
                        text = 'At the start of ' .. a.action .. "'s cast (precast)."
                    elseif a.skill ~= nil then
                        text = 'At the start of any ' .. a.skill .. ' spell (precast).'
                    else
                        text = 'At the start of every spell cast (precast).'
                    end
                elseif a.event == 'Weaponskill' then
                    text = (a.action ~= nil) and ('When using ' .. a.action .. '.') or 'When using a weapon skill.'
                elseif a.event == 'Ability' then
                    text = 'When using ' .. (a.action or 'this ability') .. '.'
                elseif (a.event == 'Default') and not a.dt and (set.name ~= 'Dt') and (set.name ~= 'Movement') then
                    -- Dt and Movement: the job file's code wears them (below); no status of their own
                    if a.key == 'Idle' then
                        text = 'While standing idle.'
                    elseif a.key == 'Engaged' then
                        text = 'While engaged in combat.'
                    elseif a.key == 'Resting' then
                        text = 'While resting.'
                    end
                end
                if (text == nil) and (a.event ~= 'Default') then text = a.label end
                if (text ~= nil) and (a.as ~= nil) then text = text .. ' (' .. a.as .. ')' end
            end
        end
        local auto = AUTO_WHEN[set.lname]
        local uses = job_uses(set)
        local lines = {}
        for _, u in ipairs(uses) do lines[u.line] = true end
        for _, u in ipairs(version_uses(set)) do -- worn as a ByName set's version too (Midshot_Acc)
            if not lines[u.line] then uses[#uses + 1] = u end
        end
        table.sort(uses, function(x, y) return x.line < y.line end)
        local jtext, jshort
        if #uses > 0 then jtext, jshort = uses_text(uses) end
        if text == nil then -- nothing by its name: the job file's code, and GoomSwap's threshold
            if jtext ~= nil then text, short = jtext, jshort end
            if auto ~= nil then
                text = (text ~= nil) and (text .. ' ' .. auto[2]) or auto[2]
                short = (short ~= nil) and (short .. ' / ' .. auto[1]) or auto[1]
            end
        else
            if auto ~= nil then text = text .. ' ' .. auto[2] end
            if jtext ~= nil then text = text .. ' ' .. jtext end
        end
        if text == nil then
            return 'No built-in trigger was found. This set is worn only if your job file explicitly equips or combines it; inspect its Handle functions.'
        end
        return text, short
    end

    -- An expected record for the set's action (the shape gcaction records have, plus expected = true), or nil.
    local function expected_for(set, preview)
        local st = preview and { mset = 'Default', idleset = 'Default', wsset = 'Default' } or modes_now()
        local a = action_for(set, st)
        if a == nil then return nil end
        local steps, misses = {}, {}
        -- FindSet: worn when the file has it, else a miss (direct: sets.X, no lookup)
        local function look(name, reason, direct)
            if has_set(name) then
                steps[#steps + 1] = { name = document.model.byLower[string.lower(name)].name, why = reason }
                return true
            end
            if not direct then misses[#misses + 1] = name end
            return false
        end
        local w = ((st.wmode ~= nil) and (st.wmode ~= 'None')) and st.wmode or nil
        -- the Main's type for <name>_2h / _1h: a set shown as one, else the weapon mode's Weapon_ set, else worn
        local function hands()
            if st.hands ~= nil then return st.hands end
            if w ~= nil then
                local ws = document.model.byLower['weapon_' .. string.lower(w)]
                local v = (ws ~= nil) and current(ws, 'Main') or nil
                local r = ((v ~= nil) and (v.kind == 'item')) and context.resources:GetItemByName(v.name, 0) or nil
                local two, one = gearEngine.TwoHandSkills, gearEngine.OneHandSkills
                if (r == nil) or (two == nil) or (one == nil) then return nil end
                if two:contains(r.Skill) then return '2h' end
                return one:contains(r.Skill) and '1h' or nil
            end
            return (gearEngine.MainHands ~= nil) and gearEngine.MainHands() or nil
        end
        -- <name>_<weapon><suffix>, else <name>_2h / _1h<suffix> (gcinclude weaponVariant). optional: no miss.
        local function weapon_layer(name, suffix, also, optional)
            if (w ~= nil) and look(name .. '_' .. w .. suffix, 'weapon mode ' .. w .. ' (/wm)' .. also, optional) then
                return
            end
            local h = hands()
            if h ~= nil then
                look(name .. '_' .. h .. suffix, HANDS[h] .. ' with no set of its own' .. also, true)
            end
        end
        local function mode(prefix) -- EquipMode
            look(
                prefix .. '_Default',
                (prefix == 'Ws') and 'base: every weapon skill starts with it' or 'base while fighting'
            )
            weapon_layer(prefix, '', '')
            if (st.mset ~= nil) and (st.mset ~= 'Default') then
                look(prefix .. '_' .. st.mset, 'melee mode ' .. st.mset .. ' (/mset)')
                weapon_layer(prefix, '_' .. st.mset, ' with melee mode ' .. st.mset, w == nil)
            end
        end
        local function variants(n) -- ByName after its set: weapon, /mset, both
            weapon_layer(n, '', '', true)
            if (st.mset ~= nil) and (st.mset ~= 'Default') then
                look(n .. '_' .. st.mset, 'melee mode ' .. st.mset .. ' (/mset)')
                weapon_layer(n, '_' .. st.mset, ' with melee mode ' .. st.mset, true)
            end
        end
        local function byname(n, reason) -- ByName
            if not has_set(n) then
                misses[#misses + 1] = n
                return false
            end
            look(n, reason)
            variants(n)
            return true
        end
        if a.event == 'Default' then
            look('Idle', 'base: Idle goes on first, every time')
            weapon_layer('Idle', '', '', true)
            if (a.key == 'Idle') and (st.idleset ~= nil) and (st.idleset ~= 'Default') then
                look('Idle_' .. st.idleset, 'idle mode ' .. st.idleset .. ' (/idleset), standing idle')
                weapon_layer('Idle', '_' .. st.idleset, ' with idle mode ' .. st.idleset, true)
            end
            if a.key == 'Engaged' then mode('Tp') end
            if a.key == 'Resting' then look('Resting', 'you are resting', true) end
            if st.dt and look('Dt', 'DT mode (/dt)', true) then variants('Dt') end
            if st.kite then look('Movement', 'kite mode (/kite)', true) end
            if st.proc and (a.key == 'Engaged') then -- /proc: Proc in place of all of it (then the weapon mode)
                steps = {}
                look('Proc', 'Proc mode (/proc): in place of your engaged sets', true)
            end
        elseif a.event == 'Weaponskill' then
            mode('Ws')
            if a.action ~= nil then byname(a.action, 'the set named after ' .. a.action) end
            if st.proc then -- /proc drops the WS gear above: only the proc set, then its _Dt
                steps = {}
                if filled('Ws_Proc') then
                    look('Ws_Proc', 'Proc mode (/proc): in place of the WS gear')
                else
                    look('Proc', 'Proc mode (/proc): in place of the WS gear, no gear in Ws_Proc')
                end
            end
            local worn = {}
            for _, step in ipairs(steps) do
                worn[#worn + 1] = step.name
            end
            -- WearChildren: each worn n: n_<key>, and <prefix>_<key> for <prefix>_Default
            local function children(key, reason)
                local done, wore = {}, {}
                for _, n in ipairs(worn) do
                    local prefix = string.match(n, '^(.-)_[Dd][Ee][Ff][Aa][Uu][Ll][Tt]$')
                    for _, cand in ipairs({ n .. '_' .. key, (prefix ~= nil) and (prefix .. '_' .. key) or nil, }) do
                        local l = string.lower(cand)
                        if not done[l] and has_set(cand) then
                            done[l] = true
                            look(cand, reason)
                            wore[#wore + 1] = cand
                        end
                    end
                end
                return wore
            end
            -- as gcinclude: skipped when an /mset mode of that name wore them; their _Dt on /dt
            local wm = WSSET[st.wsset or '']
            if (wm ~= nil) and (st.mset ~= wm.key) and not st.proc then
                for _, c in ipairs(children(wm.key, wm.why)) do worn[#worn + 1] = c end
            end
            if st.dt and not st.proc then children('Dt', 'DT mode (/dt)') end
        elseif a.event == 'Ability' then
            byname(a.action, 'the set named after ' .. a.action)
        elseif a.event == 'Precast' then
            look('Precast', 'base: every spell starts with it', true)
            if a.skill ~= nil then byname(a.skill .. '_Precast', a.skill .. ": the skill's precast set") end
            if a.action ~= nil then byname(family(a.action) .. '_Precast', "the spell's own precast set") end
        elseif a.event == 'Midcast' then
            look('Midcast', 'base: every spell goes off in it', true)
            if a.skill ~= nil then byname(a.skill, a.skill .. ": the skill's set") end
            if (a.action ~= nil) and not byname(a.action, 'the set named after ' .. a.action) then
                byname(family(a.action), "the spell's family (" .. family(a.action) .. ')')
            end
        end
        if preview then return steps, a end
        local writes = {}
        for _, step in ipairs(steps) do
            local es = document.model.byName[step.name]
            if (es ~= nil) and (es.code == nil) then
                for _, slot in ipairs(SCREEN) do
                    local v = current(es, slot)
                    if (v ~= nil) and (v.kind == 'item') then
                        writes[#writes + 1] =
                            { slot = SLOT_NUM[slot], name = v.name, by = step.name, reason = step.why }
                    end
                end
            end
        end
        local key = (a.event == 'Default') and a.key or ((a.action ~= nil) and (a.event .. ' ' .. a.action) or nil)
        return {
            expected = true,
            key = 'expected ' .. tostring(key),
            seenKey = key,
            event = a.event,
            action = a.action or a.label,
            writes = writes,
            misses = misses,
            state = st,
            as = a.as,
            label = a.label,
        }
    end

    -- Resolve definitions, not recorded item names: selectors and pending edits survive.
    -- Preview routes use neutral modes with the selected variant assumed active.
    local function equipment_for(set, baseName, definitionsOnly)
        local result = { definitions = {}, sources = {}, layers = {}, warnings = {}, pending = false,
            layered = not definitionsOnly, base = baseName }
        local omitted = {}
        local function lookup(name)
            return name and document.model.byLower[string.lower(name)] or nil
        end
        local function route(candidate)
            local steps, action = expected_for(candidate, true)
            if steps then return steps, action, true end
            local parent = lookup(candidate.name:match('^(.+)_[^_]+$'))
            if parent then
                local inherited, event, known = route(parent)
                if known then
                    inherited[#inherited + 1] = { name = candidate.name, why = 'selected variant assumed active' }
                    return inherited, event, true
                end
            end
            local name = string.lower(candidate.name)
            if name == 'town' then
                return { { name = 'Idle' }, { name = candidate.name } }, { event = 'Default' }, true
            elseif name == 'preshot' or name == 'midshot' then
                local ranged = { { name = 'Preshot' } }
                if name == 'midshot' then ranged[#ranged + 1] = { name = candidate.name } end
                return ranged, { event = 'Ranged' }, true
            elseif name:match('^weapon_') then
                return { { name = candidate.name } }, { event = 'Weapon' }, true
            end
            return { { name = candidate.name } }, nil, false
        end
        local function apply(name)
            local layer = lookup(name)
            if not layer then return end
            local deleted = document.deleted and document.deleted[layer.name]
            if layer.new or document.edits[layer.name] or deleted then result.pending = true end
            if deleted then
                if not omitted[layer.name] then
                    result.warnings[#result.warnings + 1] = layer.name .. ' is pending deletion and was omitted.'
                    omitted[layer.name] = true
                end
                return
            end
            if result.layers[#result.layers] == layer.name then return end
            result.layers[#result.layers + 1] = layer.name
            if layer.code or layer.extra then
                result.warnings[#result.warnings + 1] = layer.name
                    .. ' contains Lua/nested gear; affected slots are unknown.'
                for _, slot in ipairs(SCREEN) do
                    result.definitions[slot], result.sources[slot] = { kind = 'code',
                        raw = layer.code or 'nested set' }, layer.name
                end
                return
            end
            for _, slot in ipairs(SCREEN) do
                local value = current(layer, slot)
                if value then result.definitions[slot], result.sources[slot] = value, layer.name end
            end
        end
        if definitionsOnly then apply(set.name); return result end
        local steps, action, known = route(set)
        if baseName then
            local base = lookup(baseName)
            if base then
                local first, _, baseKnown = route(base)
                if baseKnown then apply('Idle') end
                for _, step in ipairs(first) do apply(step.name) end
                apply(base.name)
                if not baseKnown then
                    result.warnings[#result.warnings + 1] = 'Chosen base uses its definition; its custom parent order is unknown.'
                end
            else result.warnings[#result.warnings + 1] = 'Chosen base is unavailable: ' .. baseName end
        elseif known then
            apply('Idle')
            if action and action.event == 'Weaponskill' then apply('Tp_Default') end
        end
        if action and action.event == 'Midcast' then
            local precast = { name = action.action and (action.action .. '_Precast')
                or action.skill and (action.skill .. '_Precast') or 'Precast' }
            local before = expected_for(precast, true)
            for _, step in ipairs(before or {}) do apply(step.name) end
        end
        for _, step in ipairs(steps) do
            if not baseName or string.lower(step.name) ~= 'idle' or string.lower(set.name) == 'idle' then
                apply(step.name)
            end
        end
        local included = false
        for _, name in ipairs(result.layers) do if name == set.name then included = true; break end end
        if not included then apply(set.name) end
        if not known and not baseName then
            result.warnings[#result.warnings + 1] = 'Custom layer order is unknown. Only this definition is shown; choose a base to preview an overlay.'
            result.layered = false
        end
        return result
    end

    local function child(n, key) -- WearChildren's name: X_Default's child is X_<key>
        local prefix = string.match(n, '^(.-)_[Dd][Ee][Ff][Aa][Uu][Ll][Tt]$')
        return ((prefix ~= nil) and prefix or n) .. '_' .. key
    end

    -- The buff combos a Hoxne base takes: each buff alone, and all of them together (A&B, A-Z) when more than one.
    local function combos(buffs)
        local out = {}
        for _, b in ipairs(buffs) do
            out[#out + 1] = b
        end
        if #buffs > 1 then
            local all = {}
            for _, b in ipairs(buffs) do
                all[#all + 1] = b
            end
            table.sort(all)
            out[#out + 1] = table.concat(all, '&')
        end
        return out
    end

    local DEFAULT_KEY = {
        Idle = 'Idle',
        Resting = 'Resting',
        Town = 'Idle',
        XIRoll = 'Idle',
        Tp_Default = 'Engaged',
        Proc = 'Engaged',
    }
    local ENGINE_DEFAULT = {
        mdt = true,
        Aminon = true,
        TH = true,
        Incapacitated = true,
        Sleeping = true,
        Doomed = true,
        Pet_Dt = true,
        Dt = true,
        Movement = true,
    }
    local function what_if(set, o)
        local out, seen, notes, dyn = {}, {}, {}, {}
        local function rank(c) -- one order for every heading: state, modes, Hoxne, buffs, the rest
            if STATUS_TEXT[string.gsub(c, '^%l', string.upper)] or (c == 'moving') or string.match(c, '^idle mode') then
                return 1
            end
            if string.match(c, '^melee mode') then return 2 end
            if (c == 'WS low-buff mode') or (c == 'WS high-buff mode') then return 3 end
            if c == 'DT mode' then return 4 end
            if c == 'proc mode' then return 5 end
            if c == 'Hoxne' then return 6 end
            if string.match(c, ' up$') then return 7 end
            return 8
        end
        local msetOn = {}
        for _, m in ipairs(o.msets) do
            msetOn[m] = true
        end
        local function allowed(conds) -- the modes ticked (Every mode: all of them)
            for _, c in ipairs(conds) do
                local m = string.match(c, '^melee mode (.+)$')
                if (m ~= nil) and not msetOn[m] then return false end
                if ((c == 'DT mode') and not o.dt) or ((c == 'proc mode') and not o.proc)
                    or ((c == 'WS high-buff mode') and not o.high) or ((c == 'WS PDL mode') and not o.pdl)
                    or ((c == 'WS low-buff mode') and not o.low)
                    or ((c == 'Hoxne') and not o.hoxne) then
                    return false
                end
            end
            return true
        end
        local function add(name, conds, parent, extra)
            if (name == nil) or (name == '') or not allowed(conds) then return false end
            local l = string.lower(name)
            if seen[l] then return true end
            seen[l] = true
            local sorted, dup = {}, {}
            for _, c in ipairs(conds) do
                if not dup[c] then
                    dup[c] = true
                    sorted[#sorted + 1] = c
                end
            end
            table.sort(sorted, function(x, y) if rank(x) ~= rank(y) then return rank(x) < rank(y) end return x < y end)
            local w = { name = name, conds = sorted, parent = parent, self = (l == set.lname) }
            for k, v in pairs(extra or {}) do
                w[k] = v
            end
            out[#out + 1] = w
            return true
        end
        local function plus(conds, ...) -- conds + more, as a new list
            local t = {}
            for _, x in ipairs(conds) do
                t[#t + 1] = x
            end
            for _, x in ipairs({ ... }) do
                t[#t + 1] = x
            end
            return t
        end
        local function mset(m)
            return 'melee mode ' .. m
        end
        local worn = {} -- the job file's sets, in order: their children (_HighBuff, _Dt, _Self...) come after
        local function wear(name, conds, parent, extra)
            if add(name, conds, parent, extra) then worn[#worn + 1] = { name, conds } end
        end
        -- the file's weapon and weapon-type variants (<root>_Chango<suffix>, <root>_2h<suffix>); the copy menu makes
        -- new ones, so none is listed as missing
        local function with_weapons(root, suffix, conds, parent, extra)
            for _, wm in ipairs(weapon_modes()) do
                if has_set(root .. '_' .. wm .. suffix) then
                    wear(root .. '_' .. wm .. suffix, plus(conds, 'weapon mode ' .. wm), parent, extra)
                end
            end
            for _, h in ipairs({ '2h', '1h' }) do
                if has_set(root .. '_' .. h .. suffix) then
                    wear(root .. '_' .. h .. suffix, plus(conds, HANDS[h] .. ' with no set of its own'), parent, extra)
                end
            end
        end
        -- base, its weapon variants, its /mset variants, then both (ByName / EquipMode; under: EquipMode's prefix,
        -- Ws_Default -> Ws_Chango, Ws_Acc)
        local function with_msets(base, conds, parent, under, extra)
            wear(base, conds, parent, extra)
            local root = under or base
            with_weapons(root, '', conds, base, extra)
            for _, m in ipairs(o.msets) do
                wear(root .. '_' .. m, plus(conds, mset(m)), base, extra)
                with_weapons(root, '_' .. m, plus(conds, mset(m)), base, extra)
            end
        end
        local OPPOSITE =
            { ['cast on yourself'] = 'cast on someone else', ['cast on someone else'] = 'cast on yourself' }
        -- WearChildren: each worn n: n_<key> (X_Default: X_<key>); returns the rows added, { name, conds }
        local function children(key, cond, from)
            local made = {}
            for _, w in ipairs(from) do
                local clash = false
                for _, c in ipairs(w[2]) do
                    if OPPOSITE[c] == cond then clash = true end
                end -- Self_Cure_Others: never
                local name, conds = child(w[1], key), plus(w[2], cond)
                if not clash and add(name, conds, w[1]) then made[#made + 1] = { name, conds } end
            end
            return made
        end
        -- a Hoxne base (CheckHoxneSets / CheckHoxneWs): itself and its /mset ('bases'), or its buff combos ('combos':
        -- the file's own, the buffs typed, and extra: each buff set the file has), which GoomSwap puts on after the
        -- plain buff sets (CheckHoxneCombos / CheckHoxneWsCombos); both when part is nil (a Hoxne set's own list)
        local function hoxne(bases, dtKids, part, extra)
            local keep = worn
            worn = {}
            for _, b in ipairs((part ~= 'combos') and bases or {}) do
                with_msets(b[1], b[2], nil)
            end
            for _, b in ipairs((part ~= 'bases') and bases or {}) do
                local cs, have = {}, {}
                for _, c in ipairs(combos(o.buffs)) do
                    cs[#cs + 1] = c
                    have[string.lower(c)] = true
                end
                for _, c in ipairs(extra or {}) do
                    if not have[string.lower(c)] then
                        cs[#cs + 1] = c
                        have[string.lower(c)] = true
                    end
                end
                local pre = string.lower(b[1]) .. '_'
                for _, s in ipairs(document.model.list) do -- Hoxne_Tp_Impetus, Hoxne_Ws_Impetus&Footwork: any buff name
                    if (s.parentName == nil) and (string.sub(s.lname, 1, #pre) == pre) then
                        local rest = string.sub(s.name, #pre + 1)
                        local ws = WSSET_BY_KEY[rest]
                        local isMode = msetOn[rest] or (rest == 'Dt') or ((ws ~= nil) and ws.wsOnly)
                        for _, m in ipairs(o.msets) do
                            if string.sub(rest, -(#m + 1)) == ('_' .. m) then isMode = true end
                        end
                        if string.match(rest, '_Dt$') then isMode = true end
                        if not isMode and not have[string.lower(rest)] then
                            have[string.lower(rest)] = true
                            cs[#cs + 1] = rest
                        end
                    end
                end
                for _, c in ipairs(cs) do
                    with_msets(b[1] .. '_' .. c, plus(b[2], (string.gsub(c, '&', ' + ')) .. ' up'), b[1])
                end
            end
            if dtKids and o.dt then children('Dt', 'DT mode', worn) end
            worn = keep
        end
        -- the buff sets a holder (Buffs, Buffs_Ws, Buffs_Precast, Buffs_Midcast) has, and the buffs typed: each one's set, worn
        -- while that buff is up (CheckBuffSets); its names, for the Hoxne combos after it. Nil: no such holder.
        local function buff_sets(holder, conds)
            if not has_set(holder) then return nil end
            local names, seen = {}, {}
            local function name_of(b)
                if (b ~= nil) and (b ~= '') and not seen[string.lower(b)] then
                    seen[string.lower(b)] = true
                    names[#names + 1] = b
                end
            end
            for _, b in ipairs(o.buffs) do name_of(b) end
            for _, s in ipairs(document.model.list) do
                if (s.parentName ~= nil) and (string.lower(s.parentName) == string.lower(holder)) then name_of(s.key) end
            end
            for _, b in ipairs(names) do
                add(setFile.ChildName(holder, b), plus(conds, b .. ' up'), nil, { holder = holder, key = b })
            end
            return names
        end
        local name = set.name
        if string.match(name, '^Hoxne_') then
            local base = string.match(name, '^(Hoxne_[^_]+)') or name
            hoxne({ { base, { 'Hoxne' } } }, (base == 'Hoxne_Ws') or is_ws(string.sub(base, 7)))
            return out
        end

        -- the action this set is for (action_for: by its name; else the handler of the job file that names it)
        local a = action_for(set, {})
        if (a == nil) and ( (DEFAULT_KEY[name] ~= nil) or ENGINE_DEFAULT[name] or string.match(name,
            '_Received$') or string.match(name, '^Weapon_') ) then
            a = { event = 'Default', key = DEFAULT_KEY[name] }
        end
        if document.model.scan == nil then -- read once per file
            local ok, r = pcall(scan_job, document.model.text or '')
            document.model.scan = ok and r or {}
        end
        local scan = document.model.scan
        if a == nil then
            -- A custom set can appear in several handlers. Follow source order
            -- rather than table hash order, which changes between Lua runtimes.
            local firstLine = math.huge
            for event, refs in pairs(scan) do
                for _, reference in ipairs(refs) do
                    if reference.line < firstLine and string.lower(resolve(reference.arg, {},
                        reference.vars) or '') == set.lname then
                        a, firstLine = { event = event }, reference.line
                    end
                end
            end
        end
        if a == nil then -- worn by name (an ability or spell the resources don't know?): its /mset variants
            with_msets(name, {}, nil)
            return out
        end
        local ev = a.event
        if (ev == 'Default') and (a.key == 'Idle') and not (string.match(name,
            '^Idle') or (name == 'Resting') or (name == 'Town')) then
            a.key = nil
        end
        local ctx = { status = (ev == 'Default') and a.key or nil, action = a.action, skill = a.skill }
        if ctx.action ~= nil then
            ctx.family = family(ctx.action)
            if (ctx.skill == nil) and ((ev == 'Midcast') or (ev == 'Precast')) then
                local r = context.resources:GetSpellByName(ctx.action, 0)
                if r ~= nil then ctx.skill = SKILL[r.Skill] end
            end
        end
        local function st(s) -- a status as a condition, when the view covers more than one
            if ctx.status == nil then return { STATUS_TEXT[s] } end
            if ctx.status == s then return {} end
            return nil
        end

        -- 1. the job file's handler, line by line
        local refs = scan[ev]
        if refs ~= nil then
            for _, r in ipairs(refs) do
                local ok, conds = true, {}
                for _, f in ipairs(r.frames) do
                    for _, p in ipairs(f.prior) do
                        if eval_cond(p, ctx, r.vars) == true then ok = false end
                    end
                    if f.cond ~= nil then
                        local v, t = eval_cond(f.cond, ctx, r.vars)
                        if v == false then ok = false end
                        for _, x in ipairs(t) do
                            conds[#conds + 1] = x
                        end
                    end
                end
                if ok then
                    local extra = { src = 'job', line = r.line, code = r.code }
                    if r.kind == 'idle' then
                        local c = st('Idle')
                        wear('Idle', conds, nil, extra)
                        with_weapons('Idle', '', conds, 'Idle', extra)
                        if c ~= nil then
                            for _, m in ipairs({ 'Refresh', 'Regen', 'Regain', 'Reraise' }) do
                                local mc = plus(conds, 'idle mode ' .. m, unpack(c))
                                wear('Idle_' .. m, mc, 'Idle', extra)
                                with_weapons('Idle', '_' .. m, mc, 'Idle', extra)
                            end
                        end
                    elseif r.kind == 'mode' then
                        local c = (r.arg == 'Tp') and st('Engaged') or {}
                        if c ~= nil then with_msets(r.arg .. '_Default', plus(conds, unpack(c)), nil, r.arg, extra) end
                    elseif r.kind == 'th' then
                        add('TH', plus(conds, 'TH mode'), nil, extra)
                    else
                        local n, pre, rest, miss = resolve(r.arg, ctx, r.vars)
                        local cyc = (n == nil) and (pre ~= nil) and (pre ~= '') and cycle_of(rest, r.vars) or nil
                        if n ~= nil then
                            if r.kind == 'byname' then
                                with_msets(n, conds, nil, nil, extra)
                            else
                                wear(n, conds, nil, extra)
                            end
                        elseif cyc ~= nil then -- 'Tank_' .. tank: each set of the file with that start, one per mode
                            local lp = string.lower(pre)
                            for _, s in ipairs(document.model.list) do
                                local val = string.sub(s.name, #pre + 1)
                                if (s.parentName == nil) and (string.sub(s.lname, 1, #lp) == lp) and (val ~= '') and not string.find(val,
                                    '_', 1, true) then
                                    local c = plus(conds, cycle_text(cyc, val))
                                    if r.kind == 'byname' then
                                        with_msets(s.name, c, nil, nil, extra)
                                    else
                                        wear(s.name, c, nil, extra)
                                    end
                                end
                            end
                        elseif not miss and string.find(r.arg, '..', 1, true) then
                            dyn[#dyn + 1] = 'line ' .. r.line .. ': ' .. r.code
                        end
                    end
                end
            end
        end

        -- 2. the engine's layers after the job file (gcinclude: WrapHoldHandlers, CheckDefault)
        if ev == 'Weaponskill' then
            -- /proc drops the job's WS gear: only Ws_Proc (else Proc) goes on; no _HighBuff, _Dt, Hoxne or Buffs_Ws
            local jobWorn = {}
            for _, w in ipairs(worn) do
                jobWorn[#jobWorn + 1] = w
            end
            worn = {}
            wear('Ws_Proc', { 'proc mode' }, nil, { proc = true })
            if not filled('Ws_Proc') then
                wear('Proc', { 'proc mode', 'no gear in Ws_Proc' }, nil, { proc = true })
            end -- FindFilled
            worn = jobWorn
            local dtFrom = {} -- /dt: the job's WS sets and the /wsset ones (Insurgency_HighBuff_Dt)
            for _, w in ipairs(jobWorn) do dtFrom[#dtFrom + 1] = w end
            for _, r in ipairs(o.low and children('LowBuff', 'WS low-buff mode', jobWorn) or {}) do
                dtFrom[#dtFrom + 1] = r
            end
            for _, r in ipairs(o.high and children('HighBuff', 'WS high-buff mode', jobWorn) or {}) do
                dtFrom[#dtFrom + 1] = r
            end
            for _, r in ipairs(o.pdl and children('PDL', 'WS PDL mode', jobWorn) or {}) do dtFrom[#dtFrom + 1] = r end
            if o.dt then children('Dt', 'DT mode', dtFrom) end -- the proc sets take no _Dt
            local bases = { { 'Hoxne_Ws', { 'Hoxne' } } }
            if ctx.action ~= nil then bases[2] = { 'Hoxne_' .. ctx.action, { 'Hoxne' } } end
            if o.hoxne then hoxne(bases, true, 'bases') end
            local buffs = buff_sets('Buffs_Ws', {})
            if o.hoxne then hoxne(bases, true, 'combos', buffs) end -- Hoxne + buff over the plain buff sets
            if buffs == nil then
                notes[#notes + 1] = "Buffs_Ws: a set per buff (Buffs_Ws = { ['Aftermath: Lv.3'] = {...} }), worn while "
                    .. 'that buff is up; make Buffs_Ws to list them here.'
            end
        elseif ev == 'Midcast' then
            -- WearChildren over every set the handler wore; left out: TH, idle/weapon swaps (Idle_Staff) and a set that
            -- already carries the word (Burst, Self_Cure: no Burst_Burst)
            local function kids(key, cond)
                local from = {}
                for _, w in ipairs(worn) do
                    local l = string.lower(w[1])
                    if (l ~= 'th') and not string.match(l, '^idle') and not string.match(l,
                        '^weapon_') and not string.find(l, string.lower(key), 1, true) then
                        from[#from + 1] = w
                    end
                end
                children(key, cond, from)
            end
            kids('Self', 'cast on yourself')
            kids('Others', 'cast on someone else')
            local mb = (gearEngine ~= nil) and gearEngine.settings and gearEngine.settings.MBSkills or nil
            if (ctx.skill == nil) or (in_list(mb, ctx.skill) ~= false) then
                kids('Burst', 'magic burst')
            end -- MBSkills only
            if o.dt then kids('Dt', 'DT mode') end -- /dt: Cure_Dt
            if ((ctx.action == nil) and ((ctx.skill == nil) or (ctx.skill == 'Dark Magic'))) or ((ctx.action ~= nil)
                and (string.sub(ctx.action, 1, 7) == 'Absorb-')) then
                local c = (ctx.action == nil) and { 'an Absorb- spell' } or {}
                add('Absorb', c)
                if (ctx.action == nil) or (ctx.action == 'Absorb-TP') then
                    add('Absorb_TP', plus(c, (ctx.action == nil) and 'Absorb-TP' or nil))
                end
            end
            local mbuffs = buff_sets('Buffs_Midcast', {})
            if (ctx.skill == nil) or (ctx.skill == 'Healing Magic') then
                add('LightBonus', (ctx.skill == nil) and { 'Healing Magic spells' } or {})
            end
            add('SIR', { 'SIR mode' })
            if mbuffs == nil then
                notes[#notes + 1] = 'Buffs_Midcast: a set per buff, worn while it is up; make Buffs_Midcast to list them.'
            end
        elseif ev == 'Precast' then
            if buff_sets('Buffs_Precast', {}) == nil then
                notes[#notes + 1] = "Buffs_Precast: a set per buff (Buffs_Precast = { ['Spontaneity'] = {...} }), worn "
                    .. 'while it is up; make Buffs_Precast to list them.'
            end
        elseif ev == 'Default' then
            local eng, idle = st('Engaged'), st('Idle')
            if eng ~= nil then
                add('Proc', plus(eng, 'proc mode'), nil, { proc = 'engaged' })
            end -- in place of the rest
            local hbases = {} -- the Hoxne sets idle/engaged take; their buff combos go after the plain buff sets
            if o.hoxne then
                hbases[1] = { 'Hoxne_Dt', { 'Hoxne', 'DT mode' } }
                if eng ~= nil then hbases[#hbases + 1] = { 'Hoxne_Tp', plus(eng, 'Hoxne') } end
                if idle ~= nil then hbases[#hbases + 1] = { 'Hoxne_Idle', plus(idle, 'Hoxne') } end
                for _, b in ipairs(hbases) do hoxne({ b }, false, 'bases') end
            end
            local cfg = (gearEngine ~= nil) and gearEngine.settings or {}
            add('Idle_Regen', {
                'HP under RegenGearHPP'
                    .. (((cfg.RegenGearHPP or 0) > 0) and (' ' .. cfg.RegenGearHPP .. '%') or ' (off)'),
                'not fighting',
            })
            add('Idle_Refresh', {
                'MP under RefreshGearMPP'
                    .. (((cfg.RefreshGearMPP or 0) > 0) and (' ' .. cfg.RefreshGearMPP .. '%') or ' (off)'),
                'not fighting',
            })
            add('Dt', { 'HP under DTGearHPP' })
            if has_set('Pet_Dt') then
                add('Pet_Dt', { 'pet HP under PetDTGearHPP' })
            end -- pet jobs' files have one
            if (idle ~= nil) or (ctx.status == 'Resting') then add('Town', { 'in a town' }) end
            for _, m in ipairs(weapon_modes()) do
                local c = { 'weapon mode ' .. m }
                add('Weapon_' .. m, c)
                add('Weapon_' .. m .. '_1h', plus(c, 'no Dual Wield'), 'Weapon_' .. m)
                for _, ms in ipairs(o.msets) do
                    add('Weapon_' .. m .. '_' .. ms, plus(c, mset(ms)), 'Weapon_' .. m)
                end
            end
            add('mdt', { 'MDT mode' })
            add('Aminon', { 'Aminon mode' }) -- empty: mdt (FindFilled)
            add('TH', { 'TH mode' })
            local rs, order = {}, {}
            for prefix, sn in pairs(cfg.ReceivedSets or {}) do
                if rs[sn] == nil then
                    rs[sn] = {}
                    order[#order + 1] = sn
                end
                table.insert(rs[sn], prefix)
            end
            table.sort(order)
            for _, sn in ipairs(order) do
                -- the spells the set is named after first, in the name's order (Protect_Shell: Protect / Shell), then
                -- the
                -- shortest (Cure / Cura / Curaga); capitalised as the game writes them
                local ln = string.lower(sn)
                local function at(x)
                    return string.find(ln, x, 1, true) or 1000
                end
                table.sort(rs[sn], function(x, y)
                    if at(x) ~= at(y) then return at(x) < at(y) end
                    if #x ~= #y then return #x < #y end
                    return x < y
                end)
                local names = {}
                for i, x in ipairs(rs[sn]) do
                    names[i] = (string.gsub(x, '(%a)(%a*)', function(f, r) return string.upper(f) .. r end))
                end
                add(sn, { table.concat(names, ' / ') .. ' on its way to you' })
            end
            local buffs = buff_sets('Buffs', {})
            if eng ~= nil then buff_sets('Buffs_Tp', eng) end -- engaged-only / idle-only ones, over the plain buff sets
            if idle ~= nil then buff_sets('Buffs_Idle', idle) end
            for _, b in ipairs(hbases) do hoxne({ b }, false, 'combos', buffs) end -- over the plain buff sets
            if idle ~= nil then add('XIRoll', plus(idle, 'a roll at 11')) end
            add('Incapacitated', { 'slept, petrified, stunned or terrorized' })
            add('Sleeping', { 'asleep' })
            add('Doomed', { 'Doom or Bane' })
            if buffs == nil then
                notes[#notes + 1] = "Buffs: a set per buff (Buffs = { ['Aftermath: Lv.3'] = {...} }), worn while that "
                    .. 'buff is up; make Buffs to list them here.'
            end
        end

        -- 3. the file's own variants of a set listed (Ws_Default_SA): nothing above looks for them
        local listed = {}
        for _, w in ipairs(out) do
            listed[#listed + 1] = w
        end
        for _, w in ipairs(listed) do
            local pre = string.lower(w.name) .. '_'
            for _, s in ipairs(document.model.list) do
                if (s.parentName == nil) and (string.sub(s.lname, 1,
                    #pre) == pre) and not seen[s.lname] and ((ev == 'Precast') or not string.match(s.lname,
                    '_precast$')) then
                    add(s.name, plus(w.conds, "your job file's own logic"), w.name, { src = 'file' })
                end
            end
        end
        if #dyn > 0 then
            notes[#notes + 1] =
                'Your job file also builds set names in code, not listed above (their sets show as "your job file\'s own logic"):'
            for _, d in ipairs(dyn) do
                notes[#notes + 1] = '  ' .. d
            end
        end
        return out, (#notes > 0) and table.concat(notes, '\n') or nil
    end

    -- Probably unused: no built-in trigger by its name, none of the engine's own names, no other set of the file it
    -- is a variant of (Tp_Default_X, Cure_Self), not a spell family (Utsusemi), not in settings.ReceivedSets, and
    -- the job file's code never names it or a start of it ('Tank_' .. tank). Cautious: one it can't rule out is used.
    local ENGINE_NAMES = {
        absorb = true, absorbtp = true, absorb_tp = true, aminon = true, blumagical = true, bluphysical = true,
        buffs = true, doomed = true, dt = true, idle = true, incapacitated = true, lightbonus = true, mdt = true,
        midcast = true, midshot = true, movement = true, pet_dt = true, precast = true, preshot = true, proc = true,
        resting = true, sir = true, sleeping = true, th = true, town = true, ws_proc = true, xiroll = true,
    }
    local ENGINE_PATTERNS = { '^weapon_', '_received$', '^hoxne', '^buffs', '^pet_', '^tp_', '^ws_', '^idle_', '^dt_',
        '_precast$' }
    local codeNames = nil -- { text, names = { [lower] = true }, starts = { lower prefixes ending in _ } }
    local families = nil
    local function named_in_code(l)
        local text = document.model.text or ''
        if (codeNames == nil) or (codeNames.text ~= text) then
            codeNames = { text = text, names = {}, starts = {} }
            local open, close = document.model.open or 0, document.model.close or 0
            local code = string.sub(text, 1, open) .. string.sub(text, close + 1) -- the sets table left out
            for _, pattern in ipairs({ "'([^'\n]*)'", '"([^"\n]*)"', '[sS]ets%s*%.%s*([%a_][%w_]*)' }) do
                for s in string.gmatch(code, pattern) do
                    local ls = string.lower(s)
                    codeNames.names[ls] = true
                    if string.match(ls, '_$') then codeNames.starts[#codeNames.starts + 1] = ls end
                end
            end
        end
        if codeNames.names[l] then return true end
        for _, p in ipairs(codeNames.starts) do
            if string.sub(l, 1, #p) == p then return true end
        end
        return false
    end
    local function spell_family(l)
        if families == nil then
            families = {}
            for id = 1, 1024 do
                local r = context.resources:GetSpellById(id)
                local n = (r ~= nil) and (r.Name ~= nil) and r.Name[1] or nil
                if (type(n) == 'string') and (n ~= '') then families[string.lower(family(n))] = true end
            end
        end
        return families[l] == true
    end
    local function unused(set)
        local n, l = set.name, string.lower(set.name)
        if (set.code ~= nil) or set.extra or set.new or (set.parentName ~= nil) then return false end
        if ENGINE_NAMES[l] or (DEFAULT_KEY[n] ~= nil) or ENGINE_DEFAULT[n] then return false end
        for _, p in ipairs(ENGINE_PATTERNS) do
            if string.match(l, p) then return false end
        end
        local base = n
        while true do
            base = string.match(base, '^(.+)_[^_]+$')
            if base == nil then break end
            if has_set(base) or has_set(base .. '_Default') then return false end
        end
        local cfg = (gearEngine ~= nil) and gearEngine.settings or {}
        for _, sn in pairs((type(cfg.ReceivedSets) == 'table') and cfg.ReceivedSets or {}) do
            if (type(sn) == 'string') and (string.lower(sn) == l) then return false end
        end
        if action_for(set, {}) ~= nil then return false end
        if named_in_code(l) or spell_family(l) then return false end
        return true
    end

    -- The sets your actions looked for since load (this job) that the file doesn't have: one per name, newest action
    -- first, each saying which action (or the job file's line) looked for it. The set list's add list shows them; the
    -- same table until a new record or edit.
    local lookedKey, lookedOut = nil, nil
    local function looked_for()
        local records = context.getRecords()
        local order = (records ~= nil) and records.order or {}
        local key = #order .. ':' .. tostring(order[#order]) .. ':' .. document.revision
        if key == lookedKey then return lookedOut end
        local out, seen, list = {}, {}, {}
        for _, k in ipairs(order) do
            local r = records.byKey[k]
            if (r ~= nil) and (r.job == context.job) then list[#list + 1] = r end
        end
        table.sort(list, function(x, y) return x.time > y.time end)
        for _, r in ipairs(list) do
            for _, n in ipairs(r.misses or {}) do
                local l = string.lower(n)
                if (not seen[l]) and (string.find(l, '_default_', 1, true) == nil) and not has_set(n) then
                    seen[l] = true
                    local line = (r.missLine ~= nil) and r.missLine[l] or nil
                    out[#out + 1] = { name = n, why = (line ~= nil) and ('your job file looks for it (line ' .. line .. ')')
                        or ('looked for when you used ' .. action_label(r)) }
                end
            end
        end
        lookedKey, lookedOut = key, out
        return out
    end

    return {
        Layers = layers_of,
        IsSetLabel = is_set_label,
        Labels = labels_of,
        RecordsFor = records_for,
        ActionLabel = action_label,
        ActionParts = action_parts,
        SourceLabel = source_label,
        Explain = why,
        View = layer_view,
        Family = family,
        ModesNow = modes_now,
        ActionFor = action_for,
        VariantName = variant_name,
        Unused = unused,
        -- the job file's code names the set (sets.X, 'X', a name it builds from 'X_'), read from the file
        NamedInCode = function(set) return named_in_code(set.lname) end,
        -- the /wm mode a set is worn with, by its name (Tp_Chango, Savage Blade_Chango_Acc, Idle_Chango: Chango)
        WeaponModeOf = function(set)
            local st = {}
            action_for(set, st)
            return st.wmode
        end,
        WeaponModes = weapon_modes,
        When = when_description,
        Expected = expected_for,
        Equipment = equipment_for,
        Related = what_if,
        LookedFor = looked_for,
    }
end

return actionModel
