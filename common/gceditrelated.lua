-- /gcedit: the Related and To fill tabs, and renaming sets.
return function(
    LAC_WORDS, NONE, SCREEN, allItems, canDraw, cardText, choose_item, clip_begin, clip_drawn, clip_end, clip_skip,
    conds_on, ctx, current, describe, draw_icon, draw_png, edit, editorPanels, editorPreferences,
    editorState, feedback, fits, ghost_of, go_to, group_of, has_set, help, help_icon, ignored_suggestion_names,
    imgui, index_all_items, inspect_item, inspection_target, itemTooltip, make_button, make_set, melee_modes,
    owned_for, palette, picker, pill, profiler, red_button, request_context, saveReview, setFile,
    set_action_entries, set_tip, tag, text_w, undo_slot, where, wi_from_game, wrap, xy
)
-- A submenu (opens on hover) where the imgui binding has one; else its rows inline under a dim title.
local function submenu(label, title, draw)
    if imgui.BeginMenu == nil then
        imgui.TextColored(palette.dim, title)
        draw()
    elseif imgui.BeginMenu(label) then
        draw()
        imgui.EndMenu()
    end
end

-- Copy as a weapon set: this set's slots as a new <name>_<weapon> (Tp_Default -> Tp_Chango, Tp_Acc ->
-- Tp_Chango_Acc), or by weapon type (_2h, _1h); then change what differs. Not written until Save.
local function draw_weapon_copies(set)
    if (set.code ~= nil) or set.extra or (set.parentName ~= nil) or editorState.document.deleted[set.name] then return end
    local targets = ctx.actions.WeaponModes()
    targets[#targets + 1], targets[#targets + 2] = '2h', '1h'
    local rows = {}
    for _, w in ipairs(targets) do
        local name = ctx.actions.VariantName(set, w)
        if (name ~= nil) and not has_set(name) then rows[#rows + 1] = { w = w, name = name } end
    end
    if #rows == 0 then return end
    submenu('Copy as a weapon set##copyas', 'Copy as a weapon set:', function()
        for _, r in ipairs(rows) do
            if ctx.menu_item(r.name .. '##copyas') then make_set(r.name, set) end
            if imgui.IsItemHovered() then
                set_tip(((r.w == '2h') or (r.w == '1h'))
                    and ('Worn over ' .. set.name .. ' with a ' .. ((r.w == '2h') and 'two' or 'one')
                        .. '-handed weapon that has no set of its own here.')
                    or ('Worn over ' .. set.name .. ' while /wm ' .. r.w .. ' is on.'))
            end
        end
    end)
end

-- /wm order as Save writes it: your staged one, else the file's (None is left out: it keeps its place), then the
-- modes new Weapon_ sets add.
local function wm_order()
    local doc = editorState.document
    local function gone(m) -- its Weapon_ set is staged for deletion: Save takes it out of the cycle
        local s = doc.model.byLower[string.lower('Weapon_' .. m)]
        return (s ~= nil) and (s.parentName == nil) and ((doc.deleted or {})[s.name] ~= nil)
    end
    local out, seen = {}, {}
    local function add(m)
        if (m ~= nil) and (string.lower(m) ~= 'none') and not seen[string.lower(m)] and not gone(m) then
            seen[string.lower(m)], out[#out + 1] = true, m
        end
    end
    if doc.wmOrder ~= nil then
        for _, m in ipairs(doc.wmOrder) do add(m) end
        return out
    end
    for _, m in ipairs(setFile.WeaponModes(doc.model.text or '') or {}) do add(m) end
    for _, s in ipairs(doc.newSets) do add(string.match(s.name, '^Weapon_([^_]+)$')) end
    return out
end

-- A Weapon_<mode> set's place in the /wm cycle: earlier or later, written on Save.
local function draw_wm_order(set)
    local mode = string.match(set.name, '^Weapon_([^_]+)$')
    if mode == nil then return end
    local order, at = wm_order(), nil
    for i, m in ipairs(order) do
        if string.lower(m) == string.lower(mode) then at = i end
    end
    if at == nil then return end
    submenu('/wm order##wmorder', '/wm order:', function()
        imgui.TextColored(palette.dim, table.concat(order, ', '))
        for _, mv in ipairs({ { 'Earlier in /wm', -1 }, { 'Later in /wm', 1 } }) do
            local to = at + mv[2]
            if ctx.menu_item(mv[1] .. '##wmorder', (to >= 1) and (to <= #order), true) then
                local new = {}
                for i, m in ipairs(order) do new[i] = m end
                new[at], new[to] = new[to], new[at]
                editorState.document.wmOrder = nil
                local same = (#wm_order() == #new)
                for i, m in ipairs(wm_order()) do
                    if m ~= new[i] then same = false end
                end
                editorState.document.wmOrder = (not same) and new or nil -- back to the file's: nothing to save
                feedback('/wm order: ' .. table.concat(new, ', ') .. (same and '' or ' (written on Save)') .. '.')
            end
        end
    end)
end

-- == Weapon sets for a /wm mode: every set the mode can have, the missing ones to tick and make. ==
-- weapon: Weapon_<mode>_1h (no dual wield) and Weapon_<mode><mset> (and _1h), worn whole in place of
--   Weapon_<mode>, so they start as its copy (then change the Sub); spelled like the file's own (Weapon_MpuAcc, or
--   Weapon_Mpu_Acc when the file has no joined one).
-- layer: each set worn over a base while the mode is on (Tp_<mode> over Tp_Default, Tp_<mode>_Acc over Tp_Acc,
--   Savage Blade_<mode>, Idle_<mode>, Dt_<mode>...), empty unless asked: only what differs goes in, so the base's
--   later edits still apply.

-- The mode a set is the Weapon_ set of (Weapon_Mpu: Mpu), else nil: not a variant (Weapon_MpuAcc), not deleted.
local function weapon_set_mode(set)
    local m = (set ~= nil) and (set.parentName == nil) and string.match(set.name, '^Weapon_([^_]+)$') or nil
    if (m == nil) or editorState.document.deleted[set.name] or (ctx.actions == nil) then return nil end
    for _, w in ipairs(ctx.actions.WeaponModes()) do
        if string.lower(w) == string.lower(m) then return m end
    end
    return nil
end
ctx.weapon_set_mode = weapon_set_mode

-- What a Weapon_ set is to /wm, nil for any other set: { mode, kind, armor }. kind: 'mode' (Weapon_<mode>, the job
-- file's WeaponModes names it, or Save adds it: made here), 'variant' (a mode's own _1h or /mset set) or 'unlisted'
-- (WeaponModes doesn't name it, so /wm never puts it on). armor: the slots it fills that a weapon mode never puts on:
-- the engine takes Main, Sub, Range and Ammo from it (gcruntime, gcinclude.WeaponSlotNames), nothing else.
local WEAPON_SLOT = { Main = true, Sub = true, Range = true, Ammo = true }
ctx.WEAPON_SLOT = WEAPON_SLOT
ctx.weapon_set_info = function(set)
    local doc = editorState.document
    if (set == nil) or (set.parentName ~= nil) or (set.code ~= nil) or doc.deleted[set.name] then return nil end
    local rest = string.match(set.name, '^[Ww]eapon_(.+)$')
    if rest == nil then return nil end
    local info = { armor = {} }
    for _, slot in ipairs(SCREEN) do
        if (not WEAPON_SLOT[slot]) and (current(set, slot) ~= nil) then info.armor[#info.armor + 1] = slot end
    end
    local listed = ctx.settingsFiles.Job('WeaponModes')
    listed = (type(listed) == 'table') and listed or {}
    local msets = setFile.MeleeModes(doc.model.text, doc.newModes)
    for _, m in ipairs(listed) do
        if (type(m) == 'string') and (string.lower(m) ~= string.lower(rest)) and setFile.WeaponVariantOf(set.name, m, msets) then
            info.mode, info.kind = m, 'variant'
            return info
        end
    end
    info.mode, info.kind = rest, 'unlisted'
    if set.new and not string.find(rest, '[_%s]') then info.kind = 'mode' end -- Save adds it to WeaponModes
    for _, m in ipairs(listed) do
        if (type(m) == 'string') and (string.lower(m) == string.lower(rest)) then info.kind = 'mode' end
    end
    return info
end

local function weapon_set_rows(mode)
    local doc, lm, rows = editorState.document, string.lower(mode), {}
    local msets = setFile.MeleeModes(doc.model.text, doc.newModes)
    local by = doc.model.byLower
    local function have(...)
        for _, n in ipairs({ ... }) do
            local s = by[string.lower(n)]
            if (s ~= nil) and not doc.deleted[s.name] then return true end
        end
        return false
    end
    -- the file's spelling of a weapon set for an /mset mode: joined when any mode's is (Weapon_CarnwenhanAcc)
    local joined = false
    for _, s in ipairs(doc.model.list) do
        local rest = string.match(s.lname, '^weapon_(.+)$')
        if (rest ~= nil) and (s.parentName == nil) then
            local r = (string.gsub(rest, '_1h$', ''))
            for _, ms in ipairs(msets) do
                local l = string.lower(ms)
                if (#r > #l) and (string.sub(r, -#l) == l) and (string.sub(r, -#l - 1, -#l - 1) ~= '_')
                    and (by['weapon_' .. string.sub(r, 1, #r - #l)] ~= nil) then
                    joined = true
                end
            end
        end
    end
    local function weapon(name, alt, why)
        rows[#rows + 1] = { name = name, kind = 'weapon', why = why, have = have(name, alt or name) }
    end
    weapon('Weapon_' .. mode .. '_1h', nil, "when you can't dual wield")
    for _, ms in ipairs(msets) do
        if string.lower(ms) ~= 'default' then
            local j, u = 'Weapon_' .. mode .. ms, 'Weapon_' .. mode .. '_' .. ms
            local name, alt = joined and j or u, joined and u or j
            weapon(name, alt, 'with /mset ' .. ms)
            weapon(name .. '_1h', alt .. '_1h', 'with /mset ' .. ms .. ", when you can't dual wield")
        end
    end
    local seen, layers = {}, {}
    for _, s in ipairs(doc.model.list) do
        if (s.parentName == nil) and not doc.deleted[s.name] and not string.match(s.lname, '^weapon_') then
            local name = ctx.actions.VariantName(s, mode)
            if (name ~= nil) and not seen[string.lower(name)] then
                seen[string.lower(name)] = true
                layers[#layers + 1] = { name = name, kind = 'layer', base = s, why = 'over ' .. s.name,
                    have = have(name), at = #layers + 1 }
            end
        end
    end
    local place = {} -- the headings in the list's order; a layer goes under its base's
    for i, h in ipairs(ctx.headings.order()) do place[h] = i end
    table.sort(layers, function(a, b)
        local pa, pb = place[a.base.group] or 999, place[b.base.group] or 999
        if pa ~= pb then return pa < pb end
        return a.at < b.at
    end)
    for _, r in ipairs(layers) do rows[#rows + 1] = r end
    for _, r in ipairs(rows) do r.tick = { false } end
    return rows
end

local function draw_weapon_sets()
    local ui = editorState.ui
    if ui.requestWeaponSets ~= nil then
        local mode = ui.requestWeaponSets
        ui.requestWeaponSets, ui.weaponSets = nil, { mode = mode, copy = { false }, rows = weapon_set_rows(mode),
            base = editorState.document.model.byLower['weapon_' .. string.lower(mode)] }
        -- just made, the job's only /wm mode, and nothing on load yet: it goes on at load (Weapons on load)
        if ui.newWeaponMode == mode then
            local S, only = ctx.settingsFiles, true
            for _, w in ipairs(ctx.actions.WeaponModes()) do
                if (string.lower(w) ~= 'none') and (string.lower(w) ~= string.lower(mode)) then only = false end
            end
            local cur = S.Job('DefaultWeapons')
            if only and ((cur == nil) or ((type(cur) == 'string') and (string.lower(cur) == 'none'))) then
                S.StageJob('DefaultWeapons', mode)
                ui.weaponSets.onLoad, ui.weaponSets.onLoadWas = cur or 'None', cur -- what Keep puts back
            end
        end
        ui.newWeaponMode = nil
        imgui.OpenPopup('##gcedit_weapon_sets')
    end
    if not imgui.BeginPopup('##gcedit_weapon_sets') then return end
    local W = ui.weaponSets
    if W ~= nil then
        local filled = (W.base ~= nil) and (current(W.base, 'Main') ~= nil) -- weapon sets copy it: needs its Main
        imgui.TextColored(palette.section, 'Weapon sets for /wm ' .. W.mode)
        if W.onLoad ~= nil then -- the job's first /wm mode: worn at load from now on, unless you keep the old one
            imgui.TextColored(palette.ok, 'Weapons on load: ' .. W.mode .. ' (your first /wm mode; Save writes it).')
            imgui.SameLine()
            if imgui.SmallButton('Keep ' .. tostring(W.onLoad) .. '##gcws_keep') then
                local S = ctx.settingsFiles
                S.StageJob('DefaultWeapons', (W.onLoadWas == nil) and S.REMOVE or W.onLoadWas)
                W.onLoad = nil
            end
            if imgui.IsItemHovered() then
                set_tip('Load with ' .. tostring(W.onLoad) .. ' as before; GoomSwap settings, this job options, '
                    .. 'Weapons on load changes it later.')
            end
        end
        imgui.PushTextWrapPos(520)
        imgui.TextColored(palette.dim, 'Tick the ones whose gear should differ, then Make. Nothing is written until '
            .. 'Save + reload.')
        imgui.PopTextWrapPos()
        imgui.Checkbox('Layers start as a copy of their base##gcws_copy', W.copy)
        if imgui.IsItemHovered() then
            set_tip('Off (the default): a layer starts empty; fill only what differs, and later changes to its base '
                .. 'still apply.\nOn: a full copy, which then no longer follows its base.')
        end
        if imgui.SmallButton('All##gcws_all') then
            for _, r in ipairs(W.rows) do r.tick[1] = (not r.have) and ((r.kind == 'layer') or filled) end
        end
        imgui.SameLine()
        if imgui.SmallButton('None##gcws_none') then
            for _, r in ipairs(W.rows) do r.tick[1] = false end
        end
        local lh = (imgui.GetFrameHeightWithSpacing ~= nil) and imgui.GetFrameHeightWithSpacing() or 24
        local borders = ImGuiChildFlags_Borders or ImGuiChildFlags_Border or 1
        imgui.BeginChild('##gcws_list', { 520, math.min(360, (#W.rows + 8) * lh) }, borders)
        local group = nil
        for i, r in ipairs(W.rows) do
            local g = (r.kind == 'weapon') and ('Weapon sets (start as a copy of Weapon_' .. W.mode .. ')')
                or ('Layers: ' .. r.base.group)
            if g ~= group then
                group = g
                imgui.TextColored(palette.section, g)
                if (r.kind == 'weapon') and not filled then
                    imgui.TextColored(palette.warn, '  Fill Weapon_' .. W.mode .. "'s Main first: these copy it.")
                end
            end
            if r.have then
                imgui.TextColored(palette.dim, '  ' .. r.name .. '  (have)')
            else
                local off = (r.kind == 'weapon') and not filled
                local disabled = off and (imgui.BeginDisabled ~= nil)
                if disabled then imgui.BeginDisabled() end
                imgui.Checkbox(r.name .. '##gcws' .. i, r.tick)
                if disabled then imgui.EndDisabled() end
                if off then r.tick[1] = false end
            end
            imgui.SameLine()
            imgui.TextColored(palette.dim, r.why)
        end
        imgui.EndChild()
        local n = 0
        for _, r in ipairs(W.rows) do
            if r.tick[1] and not r.have then n = n + 1 end
        end
        if make_button('Make ' .. n .. '##gcws_make') and (n > 0) then
            for _, r in ipairs(W.rows) do
                if r.tick[1] and not r.have and not has_set(r.name) then
                    local from = (r.kind == 'weapon') and W.base or (W.copy[1] and r.base or nil)
                    make_set(r.name, from, true)
                    local s, anchor = editorState.document.model.byName[r.name], from or r.base
                    if (s ~= nil) and (s.after == nil) and (anchor ~= nil) and not anchor.new then
                        s.after = anchor.name -- next to its base in the file
                    end
                end
            end
            feedback('Made ' .. n .. ' set' .. ((n == 1) and '' or 's') .. ' for /wm ' .. W.mode
                .. ' (unsaved): fill what differs, then Save + reload.')
            imgui.CloseCurrentPopup()
        end
        imgui.SameLine()
        if imgui.Button('Cancel##gcws_cancel') then imgui.CloseCurrentPopup() end
    end
    imgui.EndPopup()
end

-- A new /mset mode's sets: <set>_<mode> over each base the engine lays a melee mode over (gcinclude.EquipMode:
-- Tp_, Ws_; ByName: Dt and the sets named for a weapon skill or ability). Tp_ and Ws_ start ticked.
local function mset_set_rows(mode)
    local doc, rows = editorState.document, {}
    local by = doc.model.byLower
    for _, s in ipairs(doc.model.list) do
        if (s.parentName == nil) and not doc.deleted[s.name] and not string.match(s.lname, '^weapon_')
            and (s.lname ~= 'idle') then
            local name = ctx.actions.VariantName(s, mode)
            local l = s.lname
            local main = (l == 'tp_default') or (l == 'ws_default')
            if (name ~= nil) and (main or (l == 'dt') or (name == s.name .. '_' .. mode)) then
                local have = (by[string.lower(name)] ~= nil) and not doc.deleted[by[string.lower(name)].name]
                local why = (l == 'tp_default') and 'over Tp_Default (engaged)'
                    or ((l == 'ws_default') and 'over Ws_Default (any weapon skill)')
                    or ((l == 'dt') and 'over Dt (/dt)') or ('over ' .. s.name)
                rows[#rows + 1] = { name = name, base = s, why = why, have = have, tick = { main and not have } }
            end
        end
    end
    table.sort(rows, function(a, b)
        local ra = (a.base.lname == 'tp_default') and 1 or ((a.base.lname == 'ws_default') and 2)
            or ((a.base.lname == 'dt') and 3) or 4
        local rb = (b.base.lname == 'tp_default') and 1 or ((b.base.lname == 'ws_default') and 2)
            or ((b.base.lname == 'dt') and 3) or 4
        if ra ~= rb then return ra < rb end
        return a.name < b.name
    end)
    return rows
end
-- == New /wm mode: its name first (/wm <name>), checked as the engine reads Weapon_ sets, then Weapon_<Name> made,
-- from the weapons you hold when ticked; its Weapon sets list opens after (and Weapons on load, when it is the first). ==
local function wm_name_problem(name)
    if name == '' then return '' end
    if string.find(name, '[_%s]') then
        return "One word: /wm reads one word, and _ joins a mode to an /mset mode's set."
    end
    if string.lower(name) == 'none' then return 'None is /wm with no weapons: pick another name.' end
    local doc = editorState.document
    if doc.model.byLower['weapon_' .. string.lower(name)] ~= nil then return 'Weapon_' .. name .. ' exists.' end
    local msets = setFile.MeleeModes(doc.model.text, doc.newModes)
    for _, m in ipairs(ctx.actions.WeaponModes()) do
        if setFile.WeaponVariantOf('Weapon_' .. name, m, msets) then
            return 'Weapon_' .. name .. ' reads as /wm ' .. m .. "'s own set (with an /mset mode): pick another name."
        end
    end
    return nil
end
local function draw_wm_mode()
    local ui = editorState.ui
    if ui.requestNewWm then
        -- a name typed in + New set (Weapon_Mpu: Mpu), else empty
        ui.newWm, ui.newWmWorn = { (type(ui.requestNewWm) == 'string') and ui.requestNewWm or '' }, { true }
        ui.requestNewWm = nil
        imgui.OpenPopup('##gcedit_newwm')
    end
    if not imgui.BeginPopup('##gcedit_newwm') then return end
    imgui.TextColored(palette.section, 'New weapon mode (/wm)')
    imgui.PushItemWidth(260)
    imgui.InputTextWithHint('##gcedit_wmname', 'Name, one word: Mpu, Naegling, MpuTP', ui.newWm, 24)
    imgui.PopItemWidth()
    local name = string.gsub(ui.newWm[1] or '', '^%s*(.-)%s*$', '%1')
    local problem = wm_name_problem(name)
    if problem == nil then
        imgui.TextColored(palette.dim, 'Set: Weapon_' .. name .. '   In game: /wm ' .. string.lower(name))
    elseif problem ~= '' then
        imgui.TextColored(palette.bad, problem)
    end
    imgui.Checkbox('Start from the weapons you hold (Main, Sub, Range, Ammo)##gcedit_wmworn', ui.newWmWorn)
    if imgui.Button('Create##gcedit_wmgo') and (problem == nil) then
        local set = make_set('Weapon_' .. name, nil, false)
        set = set or editorState.document.model.byLower['weapon_' .. string.lower(name)]
        if (set ~= nil) and ui.newWmWorn[1] and (ctx.use_worn ~= nil) then ctx.use_worn(set) end
        ui.requestWeaponSets, ui.newWeaponMode = name, name
        imgui.CloseCurrentPopup()
    end
    imgui.SameLine()
    if imgui.Button('Cancel##gcedit_wmno') then imgui.CloseCurrentPopup() end
    imgui.EndPopup()
end


-- + A /mset mode (the MELEE heading, the Related tab): the name, then the sets to make for it, in one go. Save
-- writes the mode into gcinclude.MeleeModes and the sets into the file.
local function draw_mset_mode()
    local ui = editorState.ui
    if ui.requestNewMset then
        ui.requestNewMset, ui.newMode[1], ui.msetRows = nil, '', nil
        imgui.OpenPopup('##gcedit_newmset')
    end
    if not imgui.BeginPopup('##gcedit_newmset') then return end
    imgui.TextColored(palette.section, 'New melee mode (/mset)')
    imgui.PushItemWidth(260)
    imgui.InputTextWithHint('##gcedit_msetname', 'Name: Hybrid, MidAcc...', ui.newMode, 24)
    imgui.PopItemWidth()
    local name = string.match(ui.newMode[1] or '', '^%s*(.-)%s*$')
    local clash = false
    for _, m in ipairs(melee_modes()) do
        if string.lower(m) == string.lower(name) then clash = true end
    end
    local okName = (string.match(name, '^%a[%w]*$') ~= nil)
    imgui.PushTextWrapPos(520)
    if clash then
        imgui.TextColored(palette.bad, 'That mode exists.')
    elseif (name ~= '') and not okName then
        imgui.TextColored(palette.bad, 'Letters and digits only (no spaces or _).')
    end
    local shown = okName and name or '<Mode>'
    imgui.TextColored(palette.dim, '/mset ' .. string.lower(shown) .. ' wears <set>_' .. shown
        .. ' over each set below. Tick the ones whose gear should differ: they start empty, fill only what differs. '
        .. 'Written on Save + reload (added to gcinclude.MeleeModes).')
    imgui.PopTextWrapPos()
    if okName and not clash then
        if (ui.msetRows == nil) or (ui.msetRows.name ~= name) then -- ticks kept while the name stays
            ui.msetRows = { name = name, rows = mset_set_rows(name) }
        end
    else
        ui.msetRows = nil
    end
    local rows = (ui.msetRows ~= nil) and ui.msetRows.rows or {}
    local n = 0
    if #rows > 0 then
        local lh = (imgui.GetFrameHeightWithSpacing ~= nil) and imgui.GetFrameHeightWithSpacing() or 24
        local borders = ImGuiChildFlags_Borders or ImGuiChildFlags_Border or 1
        imgui.BeginChild('##gcms_list', { 520, math.min(300, (#rows + 1) * lh) }, borders)
        for i, r in ipairs(rows) do
            if r.have then
                imgui.TextColored(palette.dim, r.name .. '  (have)')
            else
                imgui.Checkbox(r.name .. '##gcms' .. i, r.tick)
            end
            imgui.SameLine()
            imgui.TextColored(palette.dim, r.why)
        end
        imgui.EndChild()
        for _, r in ipairs(rows) do
            if r.tick[1] and not r.have then n = n + 1 end
        end
    end
    local label = (n > 0) and ('Add ' .. shown .. ', make ' .. n .. ' set' .. ((n == 1) and '' or 's'))
        or ('Add ' .. shown)
    if make_button(label .. '##gcms_add') and okName and not clash then
        editorState.document.newModes[#editorState.document.newModes + 1] = name
        local first = nil
        for _, r in ipairs(rows) do
            if r.tick[1] and not r.have and not has_set(r.name) then
                make_set(r.name, nil, true)
                local s = editorState.document.model.byName[r.name]
                if (s ~= nil) and (s.after == nil) and not r.base.new then s.after = r.base.name end -- by its base
                first = first or r.name
            end
        end
        editorState.document.revision = editorState.document.revision + 1
        feedback('New /mset mode ' .. name .. ((n > 0) and (' and ' .. n .. ' set' .. ((n == 1) and '' or 's'))
            or '') .. ' (unsaved): fill what differs, then Save + reload.')
        if first ~= nil then go_to(first, nil) end
        ui.newMode[1], ui.msetRows = '', nil
        imgui.CloseCurrentPopup()
    end
    imgui.SameLine()
    if imgui.Button('Cancel##gcms_cancel') then imgui.CloseCurrentPopup() end
    imgui.EndPopup()
end

-- Put in other sets: one slot's piece, exactly as written (path, augments), into the same slot of the sets ticked.
-- Each is a pending edit (as Copy from makes them: Undo slot per set; Save writes them). Sets written as code, a
-- table of sets, deleted, or with that slot written as code can't take it.
-- A piece's augments: { key, text } each, key in lower case without spaces or quotes (the file drops the quotes of
-- "Fast Cast"+10, the bags keep them), text as shown.
local function aug_items(v)
    local out = {}
    for a in string.gmatch(tostring((v ~= nil) and v.augs or ''), '[^,]+') do
        local key = string.gsub(string.lower(a), '[%s\'"{}]', '')
        if key ~= '' then
            out[#out + 1] = { key = key, text = (string.gsub(string.gsub(a, '["{}]', ''), '^%s*(.-)%s*$', '%1')) }
        end
    end
    return out
end
local function piece_key(v) -- name, path and augments, the augments in any order and spelling of the list
    if (v == nil) or (v.kind ~= 'item') or (v.name == nil) then return nil end
    local augs = {}
    for _, x in ipairs(aug_items(v)) do augs[#augs + 1] = x.key end
    table.sort(augs)
    return string.lower(tostring(v.name)) .. '|' .. string.lower(tostring(v.path or '')) .. '|'
        .. table.concat(augs, ',')
end
local function piece_label(v)
    return tostring(v.name) .. ((v.path ~= nil) and (' (Path ' .. v.path .. ')')
        or (((v.augs or '') ~= '') and ' (augmented)' or ''))
end
-- Two versions of one piece (same name and path): the augments only a has, only b has, and both have ('' if none).
local function aug_diff(a, b)
    local ia, ib, inA, inB = aug_items(a), aug_items(b), {}, {}
    for _, x in ipairs(ia) do inA[x.key] = true end
    for _, x in ipairs(ib) do inB[x.key] = true end
    local onlyA, onlyB, both = {}, {}, {}
    for _, x in ipairs(ia) do
        if inB[x.key] then both[#both + 1] = x.text else onlyA[#onlyA + 1] = x.text end
    end
    for _, x in ipairs(ib) do
        if not inA[x.key] then onlyB[#onlyB + 1] = x.text end
    end
    return table.concat(onlyA, ', '), table.concat(onlyB, ', '), table.concat(both, ', ')
end
local function same_version_of(a, b) -- same name and path: only the augments can differ
    return (a ~= nil) and (b ~= nil) and (a.kind == 'item') and (b.kind == 'item')
        and (string.lower(tostring(a.name)) == string.lower(tostring(b.name)))
        and (string.lower(tostring(a.path or '')) == string.lower(tostring(b.path or '')))
end
-- Old -> new, said by what differs: Rudianos's Mantle (Evasion+2, HP+6 -> Evasion+20, HP+60) for two versions of
-- one piece, else each whole (Chev. Armet +2 -> Chev. Armet +3).
local function change_label(old, new)
    if same_version_of(old, new) then
        local a, b = aug_diff(old, new)
        return tostring(new.name) .. ' (' .. ((a ~= '') and a or 'no augments') .. ' -> '
            .. ((b ~= '') and b or 'no augments') .. ')'
    end
    return piece_label(old) .. ' -> ' .. piece_label(new)
end
-- Hover for a version of the piece being put in: what it has that the other lacks, and what both have.
local function version_tip(here, putting)
    local a, b, both = aug_diff(here, putting)
    local lines = { 'Here: ' .. ((a ~= '') and a or 'nothing the other lacks'),
        'Putting in: ' .. ((b ~= '') and b or 'nothing this one lacks') }
    if both ~= '' then lines[#lines + 1] = 'Both have: ' .. both end
    return table.concat(lines, '\n')
end
local PAIR = { Ear1 = 'Ear2', Ear2 = 'Ear1', Ring1 = 'Ring2', Ring2 = 'Ring1' }
local function put_rows(P)
    local doc, rows, place = editorState.document, {}, {}
    for i, h in ipairs(ctx.headings.order()) do place[h] = i end
    -- an ear or ring the set already wears in the other slot of the pair: one copy can't go in both
    local other, lname = PAIR[P.slot], string.lower(tostring(P.source.name))
    local copies = editorState.inventory and editorState.inventory.copiesByName
        and editorState.inventory.copiesByName[lname] or {}
    local one = (#copies < 2)
    local key = piece_key(P.source)
    -- the piece this set had in the file before you changed it here (Rudianos's Mantle before its new augments)
    local home = doc.model.byName[P.set]
    local was = (home ~= nil) and (home.slots[P.slot] ~= nil) and home.slots[P.slot].value or nil
    local wasKey = piece_key(was)
    if (wasKey == nil) or (wasKey == key) then was, wasKey = nil, nil end
    P.replaced, P.oldCount = was, 0
    for i, s in ipairs(doc.model.list) do
        if (s.name ~= P.set) and (s.code == nil) and not s.extra and not doc.deleted[s.name] then
            local saved = s.slots[P.slot]
            local r = { set = s, at = i, tick = { false } }
            local v = current(s, P.slot)
            local vk = piece_key(v)
            local pv = (other ~= nil) and one and current(s, other) or nil
            if (saved ~= nil) and (saved.value.kind == 'code') then
                r.note, r.off = 'code', true
            elseif (vk ~= nil) and (vk == key) then
                r.note, r.off = 'has it', true
            elseif (pv ~= nil) and (string.lower(tostring(pv.name)) == lname) then
                r.note, r.off = 'in ' .. other .. ' (one copy)', true
            elseif (wasKey ~= nil) and (vk == wasKey) then
                r.note, r.old = 'now the one you replaced', true
                P.oldCount = P.oldCount + 1
            elseif same_version_of(v, P.source) then
                r.note = 'now another version'
            else
                r.note = 'now ' .. (((v ~= nil) and v.name) or 'empty')
            end
            if same_version_of(v, P.source) and not r.off then r.tip = version_tip(v, P.source) end
            rows[#rows + 1] = r
        end
    end
    table.sort(rows, function(a, b)
        local pa, pb = place[a.set.group] or 999, place[b.set.group] or 999
        if pa ~= pb then return pa < pb end
        return a.at < b.at
    end)
    return rows
end
-- Puts the piece src (a slot's value) in set s's slot, as an edit Undo edit takes back. The caller bumps the
-- revision once for all of them.
local function put_value(s, slot, src)
    local saved = s.slots[slot]
    local pending = editorState.document.edits[s.name] or {}
    editorState.history.entries = editorState.history.entries or {}
    editorState.history.entries[#editorState.history.entries + 1] = { set = s.name, slot = slot,
        previous = pending[slot] }
    if #editorState.history.entries > 100 then table.remove(editorState.history.entries, 1) end
    if (saved ~= nil) and (saved.value.raw == (src.text or src.raw)) then
        pending[slot] = nil
    else
        pending[slot] = { kind = src.kind, name = src.name, path = src.path, rank = src.rank, augs = src.augs,
            raw = src.raw, text = src.text or src.raw }
    end
    editorState.document.edits[s.name] = next(pending) and pending or nil
end
local function put_in(P)
    local n = 0
    for _, r in ipairs(P.rows) do
        if r.tick[1] and not r.off then
            put_value(r.set, P.slot, P.source)
            n = n + 1
        end
    end
    editorState.document.revision = editorState.document.revision + 1
    editorState.history.revision = editorState.document.revision -- Undo edit takes them back one by one
    return n
end
local function draw_put_in()
    local ui = editorState.ui
    if ui.requestPutIn ~= nil then
        local req = ui.requestPutIn
        ui.requestPutIn = nil
        local set = editorState.document.model.byName[req.set]
        local src = (set ~= nil) and current(set, req.slot) or nil
        if (src ~= nil) and (src.kind == 'item') then
            ui.putIn = { set = req.set, slot = req.slot, source = src, group = set.group, find = { '' } }
            ui.putIn.rows = put_rows(ui.putIn)
            -- Where it opens: under what asked for it, and never into the screen's bottom edge (a popup at the mouse
            -- there sat over tHotBar, which took the clicks): moved up until all of it fits above.
            if (req.at ~= nil) then
                local lh = (imgui.GetFrameHeightWithSpacing ~= nil) and imgui.GetFrameHeightWithSpacing() or 24
                local h = math.min(340, (#ui.putIn.rows + 6) * lh) + 5 * lh + 30
                local ok, vh = pcall(function() return imgui.GetMainViewport().Size.y end)
                vh = ok and tonumber(vh) or nil
                local y = req.at[2]
                if (vh ~= nil) then y = math.max(10, math.min(y, vh - h - 60)) end
                ui.putIn.pos = { req.at[1], y }
            end
            imgui.OpenPopup('##gcedit_putin')
        end
    end
    if (ui.putIn ~= nil) and (ui.putIn.pos ~= nil) then
        imgui.SetNextWindowPos(ui.putIn.pos, ImGuiCond_Appearing or 8)
    end
    if not imgui.BeginPopup('##gcedit_putin') then
        ui.putIn = nil -- closed (a click outside it)
        return
    end
    local P = ui.putIn
    if P == nil then imgui.EndPopup(); return end
    local what = piece_label(P.source)
    if same_version_of(P.replaced, P.source) then -- the new augments, not just (augmented)
        local _, b = aug_diff(P.replaced, P.source)
        if b ~= '' then what = P.source.name .. ' (' .. b .. ')' end
    end
    imgui.TextColored(palette.section, 'Put ' .. what .. ' in ' .. P.slot .. ' of:')
    if ((P.source.augs or '') ~= '') and imgui.IsItemHovered() then set_tip(P.source.augs) end
    imgui.PushItemWidth(220)
    imgui.InputTextWithHint('##gcpi_find', 'Find a set...', P.find, 48)
    imgui.PopItemWidth()
    local group = tostring(P.group or '')
    imgui.SameLine()
    if imgui.SmallButton('All in ' .. group .. '##gcpi_all') then
        for _, r in ipairs(P.rows) do
            if (r.set.group == P.group) and not r.off then r.tick[1] = true end
        end
    end
    imgui.SameLine()
    if imgui.SmallButton('None##gcpi_none') then
        for _, r in ipairs(P.rows) do r.tick[1] = false end
    end
    if (P.oldCount or 0) > 0 then -- the sets that still have what this set had before
        local label = 'Sets with the one you replaced (' .. P.oldCount .. ')##gcpi_old'
        editorPanels.SameLineIfFits(imgui, text_w(label) + 24)
        if imgui.SmallButton(label) then
            for _, r in ipairs(P.rows) do r.tick[1] = (r.old == true) end
        end
        if imgui.IsItemHovered() then
            set_tip('Ticks only them: ' .. change_label(P.replaced, P.source) .. '.')
        end
    end
    local find = string.lower(P.find[1] or '')
    local lh = (imgui.GetFrameHeightWithSpacing ~= nil) and imgui.GetFrameHeightWithSpacing() or 24
    local borders = ImGuiChildFlags_Borders or ImGuiChildFlags_Border or 1
    imgui.BeginChild('##gcpi_list', { 520, math.min(340, (#P.rows + 6) * lh) }, borders)
    local heading = nil
    for i, r in ipairs(P.rows) do
        if (find == '') or string.find(r.set.lname, find, 1, true) then
            if (r.set.group ~= heading) then
                heading = r.set.group
                imgui.TextColored(palette.section, string.upper(tostring(heading)))
            end
            if r.off then
                imgui.TextColored(palette.dim, '    ' .. r.set.name)
            else
                imgui.Checkbox(r.set.name .. '##gcpi' .. i, r.tick)
            end
            imgui.SameLine()
            local nw = text_w(r.note)
            if (imgui.GetContentRegionAvail ~= nil) and (imgui.SetCursorPosX ~= nil)
                and (imgui.GetCursorPosX ~= nil) then
                local avail = xy(imgui.GetContentRegionAvail())
                if (avail ~= nil) and (avail > nw) then imgui.SetCursorPosX(imgui.GetCursorPosX() + avail - nw) end
            end
            imgui.TextColored(r.old and palette.blue or palette.dim, r.note)
            if (r.tip ~= nil) and imgui.IsItemHovered() then set_tip(r.tip) end
        end
    end
    imgui.EndChild()
    local n = 0
    for _, r in ipairs(P.rows) do
        if r.tick[1] and not r.off then n = n + 1 end
    end
    if make_button('Put in ' .. n .. ' set' .. ((n == 1) and '' or 's') .. '##gcpi_put') and (n > 0) then
        local done = put_in(P)
        feedback('Put ' .. what .. ' in ' .. P.slot .. ' of ' .. done .. ' set' .. ((done == 1) and '' or 's')
            .. ' (unsaved): Undo slot per set; Save writes them.')
        ui.putIn = nil
        imgui.CloseCurrentPopup()
    end
    imgui.SameLine()
    if imgui.Button('Cancel##gcpi_cancel') then
        ui.putIn = nil
        imgui.CloseCurrentPopup()
    end
    imgui.EndPopup()
end

-- == Upgrade everywhere: a piece changed in this set (Chev. Armet +2 -> +3) that other sets still have: the same
-- change there, all at once or picked. An ear or ring is found in either slot of the pair. ==
-- The slot to offer: the one picked, else the first changed (old piece in the file, a different one now).
local function upgrade_of(set)
    local edits = editorState.document.edits[set.name]
    if edits == nil then return nil end
    local skip, sel = editorState.ui.upgradeSkip or {}, editorState.selection.slot
    local order = {}
    if (sel ~= nil) then order[1] = sel end
    for _, slot in ipairs(SCREEN) do
        if slot ~= sel then order[#order + 1] = slot end
    end
    for _, slot in ipairs(order) do
        local e, saved = edits[slot], set.slots[slot]
        local old = (saved ~= nil) and saved.value or nil
        local ko, kn = piece_key(old), piece_key(e)
        if (ko ~= nil) and (kn ~= nil) and (ko ~= kn) then
            local key = set.name .. '|' .. slot .. '|' .. ko .. '|' .. kn
            if not skip[key] then return slot, old, e, key end
        end
    end
    return nil
end
-- The other sets with the old piece: { set, slot, tick }. Not one the new piece can't go in: its other ear/ring
-- slot already has it and you own one copy.
local function upgrade_rows(set, slot, old, new)
    local doc, rows = editorState.document, {}
    local ko, lnew = piece_key(old), string.lower(tostring(new.name))
    local copies = editorState.inventory and editorState.inventory.copiesByName
        and editorState.inventory.copiesByName[lnew] or {}
    local slots = (PAIR[slot] ~= nil) and { slot, PAIR[slot] } or { slot }
    for _, s in ipairs(doc.model.list) do
        if (s.name ~= set.name) and (s.code == nil) and not s.extra and not doc.deleted[s.name] then
            for _, sl in ipairs(slots) do
                if piece_key(current(s, sl)) == ko then
                    local ov = (PAIR[sl] ~= nil) and current(s, PAIR[sl]) or nil
                    if not ((ov ~= nil) and (#copies < 2) and (string.lower(tostring(ov.name)) == lnew)) then
                        rows[#rows + 1] = { set = s, slot = sl, tick = { true } }
                    end
                    break
                end
            end
        end
    end
    return rows
end
local function draw_upgrade(set)
    if (set == nil) or (set.code ~= nil) or set.extra then return end
    local slot, old, new, key = upgrade_of(set)
    if slot == nil then return end
    local ui = editorState.ui
    local U = ui.upgrade
    if (U == nil) or (U.key ~= key) or (U.rev ~= editorState.document.revision) then
        U = { key = key, rev = editorState.document.revision, rows = upgrade_rows(set, slot, old, new),
            pick = (U ~= nil) and (U.key == key) and U.pick }
        ui.upgrade = U
    end
    local n = #U.rows
    if n == 0 then return end
    imgui.Spacing()
    imgui.PushTextWrapPos(0)
    imgui.TextColored(palette.blue, slot .. ': ' .. change_label(old, new) .. '.')
    if imgui.IsItemHovered() and (((old.augs or '') ~= '') or ((new.augs or '') ~= '')) then
        local function all(v)
            local t = {}
            for _, x in ipairs(aug_items(v)) do t[#t + 1] = x.text end
            return (#t > 0) and table.concat(t, ', ') or 'no augments'
        end
        set_tip('Old: ' .. all(old) .. '\nNew: ' .. all(new))
    end
    if U.names == nil then
        local names = {}
        for i, r in ipairs(U.rows) do
            if i > 8 then
                names[#names + 1] = '+' .. (n - 8) .. ' more'
                break
            end
            names[#names + 1] = r.set.name .. ((r.slot ~= slot) and (' (' .. r.slot .. ')') or '')
        end
        U.names = table.concat(names, ', ')
    end
    imgui.TextUnformatted('The old one is still in ' .. n .. ' other set' .. ((n == 1) and '' or 's')
        .. ': ' .. U.names)
    imgui.PopTextWrapPos()
    local function replace(rows)
        local done = 0
        for _, r in ipairs(rows) do
            if r.tick[1] then
                put_value(r.set, r.slot, new)
                done = done + 1
            end
        end
        if done == 0 then return end
        editorState.document.revision = editorState.document.revision + 1
        editorState.history.revision = editorState.document.revision -- Undo edit takes them back one by one
        feedback(slot .. ': ' .. change_label(old, new) .. ' in ' .. done .. ' more set'
            .. ((done == 1) and '' or 's') .. ' (unsaved): Undo edit steps back; Save writes them.')
    end
    if make_button('Replace in all ' .. n .. '##gcup_all') then
        for _, r in ipairs(U.rows) do r.tick[1] = true end
        replace(U.rows)
    end
    if imgui.IsItemHovered() then
        set_tip('The same change in every set listed: the new one where the old one is now. Unsaved until '
            .. 'Save + reload.')
    end
    imgui.SameLine()
    if imgui.SmallButton((U.pick and 'Hide list' or 'Pick...') .. '##gcup_pick') then U.pick = not U.pick end
    imgui.SameLine()
    if imgui.SmallButton('Not now##gcup_skip') then
        ui.upgradeSkip = ui.upgradeSkip or {}
        ui.upgradeSkip[key] = true
    end
    if imgui.IsItemHovered() then set_tip('Hides this until the editor is closed. The sets stay as they are.') end
    if U.pick then
        local m = 0
        for i, r in ipairs(U.rows) do
            if i > 1 then editorPanels.SameLineIfFits(imgui, text_w(r.set.name) + 40) end
            imgui.Checkbox(r.set.name .. ((r.slot ~= slot) and (' (' .. r.slot .. ')') or '') .. '##gcup' .. i, r.tick)
            if r.tick[1] then m = m + 1 end
        end
        if (m > 0) and make_button('Replace in ' .. m .. '##gcup_some') then replace(U.rows) end
    end
end

-- Every set GoomSwap could put on for this set's action, grouped by what has to be on for it, have or missing.
local function draw_over(set)
    local wi = editorState.ui.wi
    local values = melee_modes()
    local now = ctx.actions.ModesNow()
    -- the (?) first: after a wrapped line it would land in the middle of it
    help_icon(
        'Every set GoomSwap and your job file look for with this one, in the order they go on: a later one wins its slots.\n'
            .. '- A set you have: click its name to open it; < Back over the slots returns.\n'
            .. '- Not made too lists the sets your file does not have, in their place: make adds one empty (Make all: '
            .. 'every one shown), saved on Save + reload. None is needed: hover one for what goes on instead.\n'
            .. '- A name or condition cut with ... is whole in its hover.\n'
            .. "- (on now): its modes are on in game right now.\n"
            .. '- Hover a name: what it goes over, and the job file line that wears it (read from the file, not run).\n'
            .. "- Ignore irrelevant candidates by exact set name in settings.EditorIgnoreSuggestions, e.g. T{'Singing'}.\n"
            .. '- + /mset mode: a melee mode of your own and its sets (<set>_<mode>); also on the MELEE heading.'
    )
    imgui.SameLine()
    imgui.PushTextWrapPos(0)
    imgui.TextColored(
        palette.dim,
        'Sets that go on with ' .. set.name .. ', in order: a later one wins its slots.'
    )
    imgui.PopTextWrapPos()
    -- which modes to list: every one (default), what is on in game now, or your own pick. The modes as the game
    -- has them: one /mset at a time, toggles lit when on, and the buffs up (each buff set, and Hoxne + buff). In
    -- All modes or As now, a click on any of them switches to Pick, from what was shown, with that change.
    local view = editorState.ui.overShow
    if (view == 'now') and editorState.document.inactive then view = 'all' end
    wi.ms, wi.buffs = wi.ms or {}, wi.buffs or { '' }
    wi.dt, wi.high, wi.proc, wi.hoxne = wi.dt or { false }, wi.high or { false }, wi.proc or { false },
        wi.hoxne or { false }
    for _, m in ipairs(values) do
        if m ~= 'Default' then wi.ms[m] = wi.ms[m] or { false } end
    end
    local shown = { ms = nil, dt = false, high = false, proc = false, hoxne = false } -- what the pills light
    if view == 'all' then
        shown.all, shown.dt, shown.high, shown.proc, shown.hoxne = true, true, true, true, true
    elseif view == 'now' then
        shown.ms = ((now.mset ~= nil) and (now.mset ~= 'Default')) and now.mset or nil
        shown.dt, shown.high, shown.proc, shown.hoxne = now.dt == true, now.wsset == 'High', now.proc == true,
            now.hoxne == 'Locked'
    else
        for _, m in ipairs(values) do
            if (m ~= 'Default') and wi.ms[m][1] then shown.ms = m end
        end
        shown.dt, shown.high, shown.proc, shown.hoxne = wi.dt[1], wi.high[1], wi.proc[1], wi.hoxne[1]
    end
    local function to_pick() -- start Pick from what is shown
        if view == 'pick' then return end
        if view == 'now' then wi_from_game() end
        editorState.ui.overShow, view = 'pick', 'pick'
    end
    local function seg(label, on, id) -- a segment of a row: lit when on
        imgui.PushStyleColor(ImGuiCol_Button, on and palette.selBg or palette.btn)
        imgui.PushStyleColor(ImGuiCol_Text, on and palette.blue or palette.dim)
        local hit = imgui.SmallButton(label .. '##gcwi_' .. id)
        imgui.PopStyleColor(2)
        return hit
    end
    local labelW = text_w('Show sets for') + 14
    local function label(t)
        local x0 = imgui.GetCursorPosX()
        imgui.TextColored(palette.dim, t)
        imgui.SameLine()
        if imgui.SetCursorPosX ~= nil then imgui.SetCursorPosX(x0 + labelW) end
    end
    label('Show sets for')
    for i, v in ipairs({ { 'All modes', 'all' }, { 'As now', 'now' }, { 'Pick', 'pick' } }) do
        if (v[2] ~= 'now') or not editorState.document.inactive then
            if i > 1 then imgui.SameLine(0, 2) end
            if seg(v[1], view == v[2], 'show_' .. v[2]) then
                if v[2] == 'pick' then to_pick() else editorState.ui.overShow, view = v[2], v[2] end
            end
            if imgui.IsItemHovered() then
                set_tip(({ all = 'Every version of every mode: what you could make.',
                    now = 'What is on in game now (the pills light it).',
                    pick = 'Your own: click the pills.' })[v[2]])
            end
        end
    end
    imgui.SameLine(0, 16)
    if imgui.SmallButton('+ /mset mode##gcedit') then editorState.ui.requestNewMset = true end
    label('/mset')
    for i, m in ipairs(values) do
        if i > 1 then imgui.SameLine(0, 2) end
        local on = shown.all or ((m == 'Default') and (shown.ms == nil)) or (shown.ms == m)
        if seg(m, on, 'ms_' .. m) then
            to_pick()
            for _, k in ipairs(values) do
                if k ~= 'Default' then wi.ms[k][1] = (k == m) end
            end
        end
    end
    if imgui.IsItemHovered() then set_tip('One at a time, as in game (/mset <mode>).') end
    label('Toggles')
    local TOGGLES = { { 'DT (/dt)', 'dt' }, { 'WS high-buff', 'high' }, { 'Proc', 'proc' }, { 'Hoxne', 'hoxne' } }
    for i, t in ipairs(TOGGLES) do
        if i > 1 then imgui.SameLine(0, 4) end
        imgui.PushStyleColor(ImGuiCol_Button, shown[t[2]] and palette.okBg or palette.btn)
        imgui.PushStyleColor(ImGuiCol_Text, shown[t[2]] and palette.ok or palette.dim)
        local hit = imgui.SmallButton(t[1] .. '##gcwi_tg_' .. t[2])
        imgui.PopStyleColor(2)
        if hit then
            to_pick()
            wi[t[2]][1] = not shown[t[2]]
        end
    end
    label('Buffs up')
    imgui.PushItemWidth(-1)
    imgui.InputTextWithHint('##gcwi_buffs', 'comma between: Berserk, Aftermath: Lv.3 (each buff set; with Hoxne, '
        .. 'Hoxne + buff too)', wi.buffs, 96)
    imgui.PopItemWidth()
    if #editorState.document.newModes > 0 then
        imgui.TextColored(
            palette.warn,
            'New mode'
                .. ((#editorState.document.newModes > 1) and 's' or '')
                .. ' (written on Save): ' .. table.concat(editorState.document.newModes, ', ')
        )
    end
    local o = { msets = {}, buffs = {} }
    for b in string.gmatch(wi.buffs[1] or '', '[^,]+') do -- the buffs typed count in every view
        local t = string.match(b, '^%s*(.-)%s*$')
        if t ~= '' then o.buffs[#o.buffs + 1] = t end
    end
    if view == 'all' then
        for _, m in ipairs(values) do
            if m ~= 'Default' then o.msets[#o.msets + 1] = m end
        end
        o.high, o.dt, o.proc, o.hoxne = true, true, true, true -- every option, to make or leave
    else
        if shown.ms ~= nil then o.msets[1] = shown.ms end
        o.high, o.dt, o.proc, o.hoxne = shown.high, shown.dt, shown.proc, shown.hoxne
    end
    -- what_if (resource lookups) and the grouping, redone only when the set, the modes or the set list change
    local ignored, ignoreList = ignored_suggestion_names(), {}
    for name in pairs(ignored) do
        ignoreList[#ignoreList + 1] = name
    end
    table.sort(ignoreList)
    local ignoreKey = table.concat(ignoreList, ',')
    editorState.ui.overShowIgnored = editorState.ui.overShowIgnored or { false }
    local okey = table.concat({
        set.name,
        table.concat(o.msets, ','),
        tostring(o.dt),
        tostring(o.high),
        tostring(o.hoxne),
        tostring(o.proc),
        table.concat(o.buffs, ','),
        ignoreKey,
        tostring(editorState.ui.overShowIgnored[1]),
        editorState.document.revision,
    }, '\0')
    local O = editorState.ui.over
    if (O == nil) or (O.key ~= okey) then
        local list, note = ctx.actions.Related(set, o)
        O = { key = okey, list = list, note = note, rows = {}, nIgnored = 0 }
        local own = (ctx.gearEngine ~= nil) and ctx.gearEngine.sets or nil -- GoomSwap's own Doomed, Sleeping...
        for pos, w in ipairs(list) do
            w.pos = pos -- what_if lists them in the order they go on
            w.ignored = (ignored[string.lower(w.name)] == true)
            w.have = has_set(w.name)
            w.parentHave = (w.parent ~= nil) and has_set(w.parent)
            w.when = (#w.conds == 0) and 'always' or table.concat(w.conds, ' + ')
            w.lwhen, w.tip = string.lower(w.when), nil
            -- not made, for its hover: what goes on in its place (its base set, GoomSwap's own set of that name, or
            -- nothing; a base not made either: the hover says GoomSwap only looks for it when that exists)
            w.fbTip = nil
            if not w.have then
                local es = (type(own) == 'table') and (w.parent == nil) and own[w.name] or nil
                if w.parentHave then
                    w.fbTip = 'Not made: ' .. w.parent .. ' covers it.'
                elseif w.parent ~= nil then
                    w.fbTip = nil
                elseif (type(es) == 'table') and (next(es) ~= nil) then
                    local items = {}
                    for _, v in pairs(es) do
                        items[#items + 1] = (type(v) == 'table') and tostring(v.Name) or tostring(v)
                    end
                    table.sort(items)
                    w.fbTip = "Not made: GoomSwap's own " .. w.name .. ' set goes on (' .. table.concat(items, ', ')
                        .. ').'
                else
                    w.fbTip = 'Not made: nothing goes on for it; the sets above stay.'
                end
            end
            if w.ignored then O.nIgnored = O.nIgnored + 1 end
            if not w.ignored or editorState.ui.overShowIgnored[1] then O.rows[#O.rows + 1] = w end
        end
        editorState.ui.over = O
    end
    local list, note = O.list, O.note
    imgui.Separator()
    -- what is shown: Find (a set's name or when it goes on) narrows it. The sets not made are one line under the list
    -- until Not made too (or that line) lists them in their place, with make.
    local ui = editorState.ui
    ui.overFind = ui.overFind or { '' }
    ui.overNotMade = ui.overNotMade or { false }
    imgui.PushItemWidth(150)
    imgui.InputTextWithHint('##gcwi_find', 'Find: Dt, Hoxne...', ui.overFind, 48)
    imgui.PopItemWidth()
    local find = string.lower(ui.overFind[1] or '')
    local vkey = O.key .. '\0' .. find .. '\0' .. tostring(ui.overNotMade[1])
    local V = O.view
    if (V == nil) or (V.key ~= vkey) then
        V = { key = vkey, rows = {}, nHave = 0, nMiss = 0, miss = {} }
        for _, w in ipairs(O.rows) do
            if (find == '') or (string.find(string.lower(w.name), find, 1, true) ~= nil)
                or (string.find(w.lwhen, find, 1, true) ~= nil) then
                if w.have then
                    V.nHave = V.nHave + 1
                    V.rows[#V.rows + 1] = w
                else
                    V.nMiss = V.nMiss + 1
                    if ui.overNotMade[1] then
                        V.rows[#V.rows + 1] = w
                        V.miss[#V.miss + 1] = w
                    end
                end
            end
        end
        -- What is drawn, in order. Every Weapon_ set is in one Weapons entry: only one of them goes on (gcruntime
        -- modeSet: the one for /wm, its /mset version when made, its _1h without Dual Wield). A set's /mset versions
        -- (Dt_Acc) are chips under it. A search lists every match as a row.
        V.items = {}
        local byName, wb = {}, nil
        for _, w in ipairs(V.rows) do
            local wmode, ms = nil, nil
            for _, c in ipairs(w.conds) do
                wmode = wmode or string.match(c, '^weapon mode (.+)$')
                ms = ms or string.match(c, '^melee mode (.+)$')
            end
            local lname, col = string.lower(w.name), nil
            local base = (wmode ~= nil) and ('weapon_' .. string.lower(wmode)) or nil
            if (find == '') and (base ~= nil) then
                if lname == base then
                    col = 'base'
                elseif lname == (base .. '_1h') then
                    col = '1h'
                elseif (ms ~= nil) and (lname == (base .. '_' .. string.lower(ms))) then
                    col = ms
                end
            end
            if col ~= nil then
                if wb == nil then
                    wb = { kind = 'weapons', pos = w.pos, modes = {}, byMode = {}, cols = {}, hasCol = {} }
                    V.items[#V.items + 1] = wb
                end
                local m = wb.byMode[string.lower(wmode)]
                if m == nil then
                    m = { mode = wmode, cells = {} }
                    wb.byMode[string.lower(wmode)], wb.modes[#wb.modes + 1] = m, m
                end
                m.cells[col], wb.hasCol[col] = w, true
            else
                local p = ((find == '') and (ms ~= nil) and (w.parent ~= nil)) and byName[string.lower(w.parent)] or nil
                if p ~= nil then
                    p.chips = p.chips or {}
                    p.chips[#p.chips + 1] = { w = w, mset = ms }
                else
                    local it = { kind = 'row', w = w }
                    V.items[#V.items + 1], byName[lname] = it, it
                end
            end
        end
        if wb ~= nil then -- its columns: the loadout, no Dual Wield, then each /mset version shown
            if wb.hasCol.base then wb.cols[#wb.cols + 1] = { key = 'base', head = 'loadout' } end
            if wb.hasCol['1h'] then wb.cols[#wb.cols + 1] = { key = '1h', head = 'no Dual Wield' } end
            for _, m in ipairs(o.msets) do
                if wb.hasCol[m] then wb.cols[#wb.cols + 1] = { key = m, head = '/mset ' .. m } end
            end
        end
        O.view = V
    end
    imgui.SameLine()
    imgui.Checkbox('Not made too (' .. V.nMiss .. ')##gcwi_miss', ui.overNotMade)
    if imgui.IsItemHovered() then
        set_tip(wrap('Also the sets GoomSwap or your job file would wear here that your file does not have, in their '
            .. 'place, with make. None is needed: each falls back to its base (hover one).', 60))
    end
    imgui.SameLine()
    imgui.Checkbox('Show ignored (' .. O.nIgnored .. ')##gcwi_ignored', ui.overShowIgnored)
    if imgui.IsItemHovered() then
        set_tip(
            'Ignored names are hidden by default. Add or remove them in settings.EditorIgnoreSuggestions; this checkbox only shows them temporarily.'
        )
    end
    local makeAll = nil -- made after the list is drawn: making changes it
    if ui.overNotMade[1] then
        pill(V.nHave .. ' made', palette.ok, palette.okBg)
        imgui.SameLine(0, 14)
        pill(V.nMiss .. ' not made', palette.dim, palette.chipBg)
        if V.nMiss > 0 then
            imgui.SameLine(0, 14)
            if make_button('Make all ' .. V.nMiss .. '##gcwi_all') then makeAll = V.miss end
            if imgui.IsItemHovered() then
                set_tip(wrap('Adds every set shown that is not made, empty, next to its base set in the file.\n'
                    .. 'Nothing is saved until Save + reload.', 60))
            end
        end
    else
        imgui.TextUnformatted(V.nHave .. ' set' .. ((V.nHave == 1) and '' or 's')
            .. ((find ~= '') and ' found' or ' you have'))
    end
    imgui.BeginChild('##gcedit_over', { 0, 0 }, 0)
    if #list == 0 then
        imgui.TextColored(palette.dim, 'GoomSwap adds no sets of its own to this one.')
    elseif (#V.rows == 0) and (V.nMiss == 0) then
        imgui.TextColored(palette.dim, 'No set matches.')
    end
    local width = (imgui.GetWindowWidth ~= nil) and imgui.GetWindowWidth() or nil
    local function tw(t)
        local w = xy(imgui.CalcTextSize(t))
        return tonumber(w) or 0
    end
    local function fit(t, room) -- t, cut to room with '...' when it is wider; and whether it was cut
        if (room == nil) or (tw(t) <= room) then return t, false end
        local lo, hi = 0, #t
        while lo < hi do
            local mid = math.floor((lo + hi + 1) / 2)
            if tw(string.sub(t, 1, mid) .. '...') <= room then lo = mid else hi = mid - 1 end
        end
        return string.sub(t, 1, lo) .. '...', true
    end
    -- the columns: its place in the order, the set (open it, or make it), when it goes on. A long name is cut to the
    -- set column (at most 40% of the panel), when it goes on to the panel's edge: the hover has them whole.
    local C = V.cols
    if (C == nil) or (C.at ~= width) then
        C = { at = width, num = tw(#list .. '.'), mk = tw('make') + 16, self = tw(' (this set)'),
            ign = tw('ignored') + 16 }
        local nameW = tw('Set')
        for _, it in ipairs(V.items) do
            local w = it.w
            local nw = (it.kind == 'weapons') and tw('Weapons')
                or (tw(w.name) + (w.self and C.self or 0) + ((not w.have) and C.mk or 0) + (w.ignored and C.ign or 0))
            if nw > nameW then nameW = nw end
        end
        if width ~= nil then nameW = math.min(nameW, math.max(120, width * 0.4)) end
        C.name, C.nameW = C.num + 10, nameW
        C.when = C.name + nameW + 16
        V.cols = C
    end
    -- make a set not made: a buff set (Buffs['Berserk']) inside its holder, any other at the file's top level
    local function make_row(w)
        local holder = (w.holder ~= nil) and editorState.document.model.byName[w.holder] or nil
        if holder ~= nil then
            make_set(w.name, nil, true, holder, w.key)
        else
            make_set(w.name, nil, true)
        end
    end
    -- a set's hover: what it goes over and when, open or make it, what covers it when not made, and the job file
    -- line that wears it (that line whole: not wrapped)
    local function row_tip(w)
        if w.tip ~= nil then return w.tip end
        local tip = {}
        if not w.self then
            tip[#tip + 1] = w.name .. ((w.parent ~= nil) and (': over ' .. w.parent) or '')
                .. ((#w.conds > 0) and (', when ' .. w.when) or ', always') .. '.'
        elseif w.cut then
            tip[#tip + 1] = w.name .. ' (this set)'
        end
        if w.src == 'file' then
            tip[#tip + 1] = 'In your file, named after ' .. w.parent .. ', but nothing GoomSwap or your job file names '
                .. 'looks for it: your job file may build its name in code (see the note at the end).'
        elseif (w.parent ~= nil) and not w.parentHave then
            tip[#tip + 1] = 'GoomSwap only looks for it when ' .. w.parent .. ' exists.'
        end
        if w.proc == 'engaged' then
            tip[#tip + 1] = '/proc while engaged: in place of every other set here (to proc a mob, not kill it); the '
                .. 'weapon mode stays, and sleep/doom sets still go on.'
        elseif w.proc then
            tip[#tip + 1] = '/proc: in place of all the WS gear above (to proc a mob, not kill it); slots it leaves '
                .. 'out keep what you have on.'
        end
        if w.fbTip ~= nil then tip[#tip + 1] = w.fbTip end
        if w.have and not w.self then tip[#tip + 1] = 'Click: open it (< Back over the slots returns).' end
        if not w.have then tip[#tip + 1] = 'Click make: add it, empty (Save writes it).' end
        local text = wrap(table.concat(tip, '\n'), 60)
        if w.src == 'job' then text = text .. '\nJob file, line ' .. w.line .. ':\n  ' .. w.code end
        w.tip = text
        return w.tip
    end
    local function row(w) -- one set: its place in the order, its name (click: open it) or make, when it goes on
        local x0 = imgui.GetCursorPosX()
        if w.self and (imgui.GetWindowDrawList ~= nil) and (imgui.GetCursorScreenPos ~= nil)
            and (imgui.GetColorU32 ~= nil) then -- this set: the title strip's fill and bar, under the row
            local sx, sy = xy(imgui.GetCursorScreenPos())
            local lh = (imgui.GetTextLineHeight ~= nil) and imgui.GetTextLineHeight() or 14
            local rw = (width ~= nil) and width or 600
            if (sx ~= nil) and (sy ~= nil) then
                local dl = imgui.GetWindowDrawList()
                dl:AddRectFilled({ sx - 4, sy - 1 }, { sx + rw, sy + lh + 1 }, imgui.GetColorU32(palette.selBg))
                dl:AddRectFilled({ sx - 4, sy - 1 }, { sx - 1, sy + lh + 1 }, imgui.GetColorU32(palette.sel))
            end
        end
        w.num = w.num or (w.pos .. '.')
        imgui.SetCursorPosX(x0 + C.num - tw(w.num))
        imgui.TextColored(palette.dim, w.num)
        imgui.SameLine()
        imgui.SetCursorPosX(x0 + C.name)
        if w.cutAt ~= C then -- its name, fitted to the set column (redone when the panel's width changes)
            local room = C.nameW - (w.self and C.self or 0) - ((not w.have) and C.mk or 0) - (w.ignored and C.ign or 0)
            w.shown, w.cut = fit(w.name, room)
            w.selLabel, w.cutAt, w.tip = w.shown .. '##gcwis' .. w.pos, C, nil
        end
        if w.self then
            imgui.TextColored(palette.blue, w.shown)
            imgui.SameLine()
            imgui.TextColored(palette.dim, '(this set)')
        elseif w.have then
            if imgui.Selectable(w.selLabel, false, 0, { tw(w.shown), 0 }) then go_to(w.name, nil) end
        else
            imgui.TextColored(palette.dim, w.shown)
        end
        if imgui.IsItemHovered() then
            local made = w.have and editorState.document.model.byLower[string.lower(w.name)] or nil
            if (made ~= nil) and (ctx.set_peek ~= nil) then ctx.set_peek(made, row_tip(w)) else set_tip(row_tip(w)) end
        end
        if not w.have then
            imgui.SameLine()
            w.makeLabel = w.makeLabel or ('make##gcwi' .. w.pos)
            if make_button(w.makeLabel) then make_row(w) end
            if imgui.IsItemHovered() then
                set_tip(wrap('Adds ' .. w.name .. ', empty, next to its base set in the file: fill only what differs. '
                    .. 'Saved on Save + reload.', 60))
            end
        end
        if w.ignored then tag('ignored', palette.dim) end
        imgui.SameLine()
        if imgui.GetCursorPosX() < x0 + C.when then imgui.SetCursorPosX(x0 + C.when) end
        local on = conds_on(w.conds, now)
        local avail = (imgui.GetContentRegionAvail ~= nil) and xy(imgui.GetContentRegionAvail()) or nil
        local room = (avail ~= nil) and (avail - (on and (tw('(on now)') + 10) or 0) - 6) or nil
        if (w.whenShown == nil) or (w.whenRoom ~= room) then
            w.whenShown, w.whenCut = fit(w.when, room)
            w.whenRoom = room
        end
        imgui.TextColored(palette.dim, w.whenShown)
        if w.whenCut and imgui.IsItemHovered() then set_tip(w.when) end
        if on then
            imgui.SameLine(0, 10)
            imgui.TextColored(palette.ok, '(on now)')
        end
    end
    -- the Weapons entry: its line, then a row per /wm mode with each version's Main, Sub and Range as icons
    local canDW = nil -- Dual Wield now (the job loaded only): which cell is worn
    if (not editorState.document.inactive) and (ctx.gearEngine ~= nil) and (ctx.gearEngine.CanDualWield ~= nil) then
        local okDW, v = pcall(ctx.gearEngine.CanDualWield)
        if okDW then canDW = v end
    end
    local function wm_cell(w, worn)
        if w == nil then
            imgui.TextColored(palette.dim, '-')
            return
        end
        if not w.have then
            w.mkLabel = w.mkLabel or ('+##gcwm' .. w.pos)
            if imgui.SmallButton(w.mkLabel) then make_row(w) end
            if imgui.IsItemHovered() then set_tip(row_tip(w)) end
            return
        end
        local made = editorState.document.model.byLower[string.lower(w.name)]
        if w.idsVer ~= editorState.document.revision then
            w.ids, w.idsVer = {}, editorState.document.revision
            for i, slot in ipairs({ 'Main', 'Sub', 'Range' }) do
                local v = (made ~= nil) and current(made, slot) or nil
                w.ids[i] = ((v ~= nil) and (v.kind == 'item') and (ctx.item_id ~= nil)) and ctx.item_id(v.name) or false
            end
        end
        local dl = ((imgui.GetWindowDrawList ~= nil) and (imgui.GetCursorScreenPos ~= nil)
            and (imgui.GetColorU32 ~= nil)) and imgui.GetWindowDrawList() or nil
        imgui.BeginGroup()
        for i = 1, 3 do
            if i > 1 then imgui.SameLine(0, 1) end
            if w.ids[i] then
                draw_icon(w.ids[i], 20)
            else
                local x, y = nil, nil
                if dl ~= nil then x, y = xy(imgui.GetCursorScreenPos()) end
                if (x ~= nil) and (y ~= nil) then
                    dl:AddRectFilled({ x, y }, { x + 20, y + 20 }, imgui.GetColorU32({ 0.09, 0.11, 0.14, 1 }))
                end
                imgui.Dummy({ 20, 20 })
            end
        end
        imgui.EndGroup()
        if worn and (dl ~= nil) and (imgui.GetItemRectMin ~= nil) then
            local x1, y1 = xy(imgui.GetItemRectMin())
            local x2, y2 = xy(imgui.GetItemRectMax())
            if (x1 ~= nil) and (x2 ~= nil) then
                dl:AddRect({ x1 - 2, y1 - 2 }, { x2 + 2, y2 + 2 }, imgui.GetColorU32(palette.ok), 2, 0, 1)
            end
        end
        if imgui.IsItemHovered() then
            if (made ~= nil) and (ctx.set_peek ~= nil) then ctx.set_peek(made, row_tip(w)) else set_tip(row_tip(w)) end
        end
        if imgui.IsItemClicked(0) then go_to(w.name, nil) end
    end
    local function weapons_entry(b)
        local x0 = imgui.GetCursorPosX()
        local num = b.pos .. '.'
        imgui.SetCursorPosX(x0 + C.num - tw(num))
        imgui.TextColored(palette.dim, num)
        imgui.SameLine()
        imgui.SetCursorPosX(x0 + C.name)
        imgui.TextUnformatted('Weapons')
        imgui.SameLine()
        imgui.SetCursorPosX(x0 + C.when)
        imgui.TextColored(palette.dim, 'one loadout, picked by your modes')
        local nowMode = ((not editorState.document.inactive) and (now ~= nil) and (now.wmode ~= nil))
            and b.byMode[string.lower(now.wmode)] or nil
        if nowMode ~= nil then
            imgui.SameLine(0, 10)
            imgui.TextColored(palette.ok, '(on now: ' .. string.lower(nowMode.mode) .. ')')
        end
        if imgui.IsItemHovered() then
            set_tip(wrap('Only one of these goes on: the row for your /wm; its /mset version replaces it when made; '
                .. "no Dual Wield: its _1h when you can't dual wield. Each shows its Main, Sub and Range; click one "
                .. 'to open it.', 60))
        end
        if b.at ~= width then -- the columns' widths
            b.at, b.modeW = width, tw('mode')
            for _, m in ipairs(b.modes) do b.modeW = math.max(b.modeW, tw('/wm ' .. string.lower(m.mode))) end
            b.modeW = b.modeW + 16
            for _, c in ipairs(b.cols) do c.w = math.max(3 * 21 + 12, tw(c.head) + 14) end
        end
        local mx = x0 + C.name
        imgui.SetCursorPosX(mx)
        imgui.TextColored(palette.dim, 'mode')
        local cx = mx + b.modeW
        for _, c in ipairs(b.cols) do
            imgui.SameLine()
            imgui.SetCursorPosX(cx)
            imgui.TextColored(palette.dim, c.head)
            cx = cx + c.w
        end
        for _, m in ipairs(b.modes) do
            local worn = nil
            if m == nowMode then -- gcruntime modeSet / WeaponSetFor: the /mset version, else _1h, else the loadout
                local ms = now.mset
                worn = ((ms ~= nil) and (ms ~= 'Default') and (m.cells[ms] ~= nil) and m.cells[ms].have) and ms
                    or (((canDW == false) and (m.cells['1h'] ~= nil) and m.cells['1h'].have) and '1h' or 'base')
            end
            imgui.SetCursorPosX(mx)
            imgui.TextUnformatted('/wm ' .. string.lower(m.mode))
            cx = mx + b.modeW
            for _, c in ipairs(b.cols) do
                imgui.SameLine()
                imgui.SetCursorPosX(cx)
                wm_cell(m.cells[c.key], worn == c.key)
                cx = cx + c.w
            end
        end
        imgui.Spacing()
    end
    local function chips_of(it, x0) -- a set's /mset versions, under it
        imgui.SetCursorPosX(x0 + C.when)
        imgui.TextColored(palette.dim, 'its /mset versions:')
        for _, ch in ipairs(it.chips) do
            local w = ch.w
            imgui.SameLine()
            if w.have then
                w.chipLabel = w.chipLabel or (ch.mset .. '##gcwc' .. w.pos)
                if imgui.SmallButton(w.chipLabel) then go_to(w.name, nil) end
                if imgui.IsItemHovered() then
                    local made = editorState.document.model.byLower[string.lower(w.name)]
                    if (made ~= nil) and (ctx.set_peek ~= nil) then ctx.set_peek(made, row_tip(w))
                    else set_tip(row_tip(w)) end
                end
            else
                w.chipLabel = w.chipLabel or (ch.mset .. ' +##gcwc' .. w.pos)
                if make_button(w.chipLabel) then make_row(w) end
                if imgui.IsItemHovered() then set_tip(row_tip(w)) end
            end
        end
    end
    if #V.items > 0 then -- the column heads
        local x0 = imgui.GetCursorPosX()
        imgui.SetCursorPosX(x0 + C.num - tw('#'))
        imgui.TextColored(palette.dim, '#')
        imgui.SameLine()
        imgui.SetCursorPosX(x0 + C.name)
        imgui.TextColored(palette.dim, 'Set')
        imgui.SameLine()
        imgui.SetCursorPosX(x0 + C.when)
        imgui.TextColored(palette.dim, 'Goes on when')
        imgui.Separator()
    end
    local clip = clip_begin()
    for _, it in ipairs(V.items) do
        if not clip_skip(clip, it) then
            if it.kind == 'weapons' then
                weapons_entry(it)
            else
                local x0 = imgui.GetCursorPosX()
                row(it.w)
                if it.chips ~= nil then chips_of(it, x0) end
            end
            clip_drawn(clip, it)
        end
    end
    clip_end(clip)
    imgui.PushTextWrapPos(0)
    if (not ui.overNotMade[1]) and (V.nMiss > 0) then -- the sets not made, one line until listed
        imgui.Spacing()
        if imgui.SmallButton('+ ' .. V.nMiss .. ' you could make##gcwi_showmiss') then ui.overNotMade[1] = true end
        if imgui.IsItemHovered() then set_tip('Lists them in their place, with make (Not made too).') end
        imgui.SameLine()
        imgui.TextColored(palette.dim, 'none needed: each falls back to its base')
    end
    if note ~= nil then
        imgui.Spacing()
        imgui.TextColored(palette.dim, note)
    end
    if o.hoxne and (#o.buffs == 0) then
        imgui.Spacing()
        imgui.TextColored(
            palette.dim,
            'Hoxne buff combos (Hoxne_Tp_Impetus, Hoxne_Ws_Impetus&Footwork...) take any buff name: type the buffs under Pick modes to list them.'
        )
    end
    imgui.PopTextWrapPos()
    imgui.EndChild()
    if makeAll ~= nil then
        for _, w in ipairs(makeAll) do
            if not w.have and not has_set(w.name) then make_row(w) end
        end
    end
end

local fill_list -- To fill's list (below): the picker's way back to it counts what is left
local function draw_picker(set)
    if (editorState.selection.slot == nil) or (set.code ~= nil) or set.extra then
        imgui.TextColored(palette.dim, 'Click a slot to pick gear for it.')
        if editorState.selection.slot == nil then -- Goomy, centred in the empty panel
            local w, h = 52, 68
            if (imgui.GetContentRegionAvail ~= nil) and (imgui.GetCursorPosX ~= nil) and (imgui.SetCursorPosX ~= nil)
                and (imgui.GetCursorPosY ~= nil) and (imgui.SetCursorPosY ~= nil) then
                local aw, ah = xy(imgui.GetContentRegionAvail())
                if (aw ~= nil) and (ah ~= nil) then
                    imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (aw - w) / 2))
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + math.max(0, (ah - h) / 2))
                end
            end
            if not draw_png('goomy_wave.png', w, h) then imgui.Dummy({ w, h }) end
        end
        return
    end
    local cur = set.slots[editorState.selection.slot]
    local changed = (editorState.document.edits[set.name] ~= nil)
        and (editorState.document.edits[set.name][editorState.selection.slot] ~= nil)
    local fa = editorState.ui.fillAll
    if (fa ~= nil) and (fa.slot == editorState.selection.slot) and fa.sets[set.name] then
        imgui.TextColored(
            palette.warn,
            string.format('Fill all: your pick replaces %s in %d sets (%s).', fa.name, fa.n, editorState.selection.slot)
        )
        imgui.SameLine()
        if imgui.SmallButton('Cancel##gcedit_fa') then editorState.ui.fillAll = nil end
    end
    if editorState.ui.fromFill then -- came from To fill: one click back to the list
        if imgui.SmallButton('< To fill (' .. fill_list().n .. ' left)##gcedit_backfill') then
            editorState.ui.fromFill, editorState.selection.tab = nil, 'fill'
        end
        if imgui.IsItemHovered() then set_tip('Back to the list of what still needs gear. Picking an item here does that too.') end
        imgui.SameLine()
    end
    imgui.TextColored(palette.blue, 'Editing: ' .. set.name .. ' / ' .. editorState.selection.slot)
    local wi = ctx.weapon_set_info(set)
    if (wi ~= nil) and not WEAPON_SLOT[editorState.selection.slot] then
        imgui.PushTextWrapPos(0)
        imgui.TextColored(palette.warn, 'Not worn: a Weapon_ set only puts on Main, Sub, Range and Ammo. Gear for '
            .. 'fighting with this mode goes in Tp_' .. wi.mode .. ' (over Tp_Default while /wm ' .. wi.mode .. ' is on).')
        imgui.PopTextWrapPos()
    end
    if (cur ~= nil) and (cur.value.kind == 'code') then
        imgui.TextColored(palette.dim, 'Written as code in the file: edit it there.')
        return
    end
    local now = current(set, editorState.selection.slot)
    local summary = editorState.cache.pickSummary
    if not summary or summary.set ~= set.name or summary.slot ~= editorState.selection.slot
        or summary.revision ~= editorState.document.revision then
        summary = { set = set.name, slot = editorState.selection.slot, revision = editorState.document.revision,
            current = (changed and 'Pending: ' or 'Saved: ') .. (now and saveReview.Value(now) or 'unchanged'),
            original = changed and ('Saved: ' .. (cur and saveReview.Value(cur.value) or 'unchanged'))
                or 'Choose an item to update this slot.' }
        editorState.cache.pickSummary = summary
    end
    imgui.PushTextWrapPos(0)
    editorPanels.Text(imgui, changed and palette.warn or palette.dim, summary.current)
    editorPanels.Text(imgui, palette.dim, summary.original)
    imgui.PopTextWrapPos()
    local actionShown = false
    local inspected, inspectedOwned, inspectedSource = inspection_target(set, editorState.selection.slot)
    if inspected and inspected.kind == 'item' then
        if imgui.Button('Inspect item##gcedit') then
            inspect_item(set.name, editorState.selection.slot, inspected, inspectedOwned, inspectedSource)
        end
        if imgui.IsItemHovered() then
            set_tip('Show this item\'s stats below the gear grid. They stay visible while you browse the picker.')
        end
        actionShown = true
    end
    local gh = (now == nil) and ghost_of(set, editorState.selection.slot) or nil -- read once: the click below drops it
    if gh ~= nil then
        if actionShown then editorPanels.SameLineIfFits(imgui, text_w('Drop commented line') + 24) end
        if red_button('Drop commented line##gcedit', true) then edit(set, editorState.selection.slot, nil) end
        if imgui.IsItemHovered() then
            set_tip(wrap('Empties the slot. Save deletes its commented-out ' .. gh.name .. ' line from the file.', 60))
        end
        actionShown = true
    end
    if now ~= nil then
        if actionShown then editorPanels.SameLineIfFits(imgui, text_w('Clear slot') + 24) end
        if red_button('Clear slot##gcedit', true) then
            edit(set, editorState.selection.slot, nil)
            feedback('Cleared ' .. set.name .. ' / ' .. editorState.selection.slot .. ' (unsaved).')
        end
        actionShown = true
    end
    if changed then
        if actionShown then editorPanels.SameLineIfFits(imgui, text_w('Undo slot') + 24) end
        if imgui.SmallButton('Undo slot##gcedit') then undo_slot(set, editorState.selection.slot) end
        if imgui.IsItemHovered() then
            set_tip('Back to what the file has: ' .. ((cur ~= nil) and cur.value.name or 'empty'))
        end
    end
    if (now ~= nil) and (now.kind == 'item') and (now.name ~= nil) then
        editorPanels.SameLineIfFits(imgui, text_w('Put in other sets...') + 24)
        if make_button('Put in other sets...##gcedit_putin') then
            local bx = xy(imgui.GetItemRectMin())
            local _, by = xy(imgui.GetItemRectMax())
            editorState.ui.requestPutIn = { set = set.name, slot = editorState.selection.slot,
                at = (bx ~= nil) and (by ~= nil) and { bx, by + 4 } or nil }
        end
        if imgui.IsItemHovered() then
            set_tip('This piece as it is here (path and augments too) into the same slot of other sets you tick.')
        end
    end
    imgui.PushItemWidth(-1)
    imgui.InputTextWithHint('##gcedit_search', 'Search name or augment', editorState.ui.search, 96)
    if imgui.IsItemHovered() then
        set_tip('3+ letters also finds items you do not own (after yours, marked not owned), to plan a set.')
    end
    imgui.PopItemWidth()
    if editorState.ui.search[1] ~= '' then
        if imgui.SmallButton('Clear search##gear') then editorState.ui.search[1] = '' end
        imgui.SameLine()
    end
    imgui.Checkbox('Any job / level##gcedit', editorState.ui.anyJob)
    editorPanels.SameLineIfFits(imgui, text_w('Can equip now') + 36)
    imgui.Checkbox('Can equip now##gcedit', editorState.ui.wardOnly)
    imgui.Checkbox('Needs RP##picker', editorState.ui.rpOnly)
    editorPanels.SameLineIfFits(imgui, text_w('Augmented') + 36)
    imgui.Checkbox('Augmented##picker', editorState.ui.augOnly)
    -- a search of 3+ letters also lists items you don't own (every equippable item, indexed the first time)
    local find = string.lower(editorState.ui.search[1] or '')
    local wantAll = (#(string.gsub(find, '%s', '')) >= 3)
    local allReady = wantAll and index_all_items()
    if wantAll and not allReady then
        imgui.TextColored(palette.dim, string.format('Looking through every item... %d%%',
            math.floor(allItems.nextId * 100 / 65535)))
    end
    if editorState.ui.anyJob[1] or editorState.ui.wardOnly[1] or editorState.ui.rpOnly[1] or editorState.ui.augOnly[1]
        or editorState.ui.search[1] ~= '' then
        editorPanels.SameLineIfFits(imgui, text_w('Reset filters') + 24)
        if imgui.SmallButton('Reset filters##picker') then
            editorState.ui.anyJob[1], editorState.ui.wardOnly[1], editorState.ui.rpOnly[1], editorState.ui.augOnly[1],
                editorState.ui.search[1] =
                false, false, false, false, ''
        end
    end
    -- the rows that fit, rebuilt only when the slot, the filters or the bags change; copies alike in every way
    -- (name, augments, path) share a row that names each bag
    local pkey = table.concat({
        editorState.selection.slot,
        find,
        tostring(editorState.ui.anyJob[1]),
        tostring(editorState.ui.wardOnly[1]),
        tostring(editorState.ui.rpOnly[1]),
        tostring(editorState.ui.augOnly[1]),
        tostring(allReady),
        editorState.document.revision,
    }, '\0')
    if editorState.cache.picksKey ~= pkey then
        local rows, byKey = {}, {}
        for _, g in ipairs(editorState.inventory.items) do
            if fits(g, editorState.selection.slot) and picker.Accept( g, find, editorState.ui.wardOnly[1],
                editorState.ui.rpOnly[1], editorState.ui.augOnly[1] ) then
                local row = byKey[g.key]
                if row == nil then
                    row = { g = g, bags = { g.bag }, equippable = g.equippable }
                    byKey[g.key] = row
                    rows[#rows + 1] = row
                else
                    row.bags[#row.bags + 1] = g.bag
                    if g.equippable and not row.equippable then row.g, row.equippable = g, true end
                end
            end
        end
        if allReady then -- unowned: after what you own, one row per name
            local owned = {}
            for _, row in ipairs(rows) do owned[row.g.lname] = true end
            for _, g in ipairs(allItems.rows) do
                if not owned[g.lname] and fits(g, editorState.selection.slot)
                    and picker.Accept(g, find, editorState.ui.wardOnly[1], editorState.ui.rpOnly[1],
                        editorState.ui.augOnly[1]) then
                    rows[#rows + 1] = { g = g, bags = { g.bag }, equippable = false }
                end
            end
        end
        editorState.cache.picksKey, editorState.cache.picks = pkey, rows
        if imgui.SetScrollY then editorState.ui.resetPickerScroll = true end
    end
    local inOther = {}
    for _, s2 in ipairs(SCREEN) do
        if s2 ~= editorState.selection.slot then
            local v = current(set, s2)
            if (v ~= nil) and (v.name ~= nil) then inOther[string.lower(v.name)] = s2 end
        end
    end
    local selectedCopy = owned_for(set, editorState.selection.slot)
    -- a new slot: scroll to the piece in it once
    local scroll = (editorState.cache.picksFor ~= set.name .. '\0' .. editorState.selection.slot)
    editorState.cache.picksFor = set.name .. '\0' .. editorState.selection.slot
    imgui.TextColored(palette.dim, #editorState.cache.picks .. ' items')
    if imgui.IsItemHovered() then
        set_tip('Right-click for item actions. Green marker = accessible; amber = storage. Hover a row for all bags and stats.')
    end
    -- Keep the column headings above the scrollable, virtualized rows.
    local style = imgui.GetStyle and imgui.GetStyle()
    local scrollbar = style and style.ScrollbarSize or 14
    imgui.BeginChild('##gcedit_pick_header', { 0, imgui.GetTextLineHeightWithSpacing() + 4 }, 0,
        ImGuiWindowFlags_NoScrollbar)
    local pickerWidth = math.max(1, (xy(imgui.GetContentRegionAvail()) or 300) - scrollbar)
    local bagColumn, bagWidth = picker.BagColumn(pickerWidth)
    imgui.TextColored(palette.dim, 'Item')
    imgui.SameLine(imgui.GetCursorPosX() + bagColumn)
    imgui.TextColored(palette.dim, 'Bag')
    imgui.EndChild()
    imgui.Separator()
    imgui.BeginChild('##gcedit_picks', { 0, 0 }, 0)
    local bagX = imgui.GetCursorPosX() + bagColumn
    -- what each piece changes against the slot's piece now: a column before the bag, when there is room
    local slotNow = editorState.selection.slot
    local dkey = set.name .. '\0' .. slotNow .. '\0' .. editorState.document.revision
    local DC = editorState.cache.pickDelta
    if (DC == nil) or (DC.key ~= dkey) then
        DC = { key = dkey, by = {} }
        editorState.cache.pickDelta = DC
    end
    local statW = (ctx.piece_delta ~= nil) and math.min(190, (bagX - imgui.GetCursorPosX()) * 0.45) or 0
    if statW < 90 then statW = 0 end
    local statX = bagX - statW
    if editorState.ui.resetPickerScroll then
        imgui.SetScrollY(0)
        editorState.ui.resetPickerScroll = nil
    end
    -- only the rows in view are drawn (a fixed row height, measured once): a 300-row list costs as much as 30
    local clip = (editorState.cache.rowH ~= nil)
        and (imgui.GetScrollY ~= nil)
        and (imgui.GetWindowHeight ~= nil) and (imgui.GetCursorPosY ~= nil) and (imgui.SetCursorPosY ~= nil)
    local first, last = 1, #editorState.cache.picks
    local top = (imgui.GetCursorPosY ~= nil) and imgui.GetCursorPosY() or 0
    if clip then
        if scroll and (imgui.SetScrollY ~= nil) then -- the slot's piece mid-view
            for i, row in ipairs(editorState.cache.picks) do
                if selectedCopy ~= nil and row.g.key == selectedCopy.key then
                    imgui.SetScrollY(math.max(0, (i - 1) * editorState.cache.rowH - imgui.GetWindowHeight() / 2))
                    break
                end
            end
            scroll = false
        end
        local y, h = imgui.GetScrollY() - top, imgui.GetWindowHeight()
        first = math.max(1, math.floor(y / editorState.cache.rowH) - 1)
        last = math.min(#editorState.cache.picks, math.ceil((y + h) / editorState.cache.rowH) + 2)
    end
    for i = first, last do
        local row = editorState.cache.picks[i]
        local g = row.g
        if clip then imgui.SetCursorPosY(top + (i - 1) * editorState.cache.rowH) end
        local y0 = (not clip) and (i == 1) and (imgui.GetCursorPosY ~= nil) and imgui.GetCursorPosY() or nil
        if canDraw() then picker.DrawAccessMarker(imgui, palette, row.equippable, ctx.ROW_ICON) end
        draw_icon(g.id, ctx.ROW_ICON)
        imgui.SameLine()
        local isNow = selectedCopy ~= nil and selectedCopy.key == g.key
        if g.progress and g.progress.unfinished then imgui.PushStyleColor(ImGuiCol_Text, palette.rp) end
        local label = cardText.Fit(picker.Caption(g, isNow and (changed and 'Pending' or 'Saved')),
            math.max(30, statX - imgui.GetCursorPosX() - 10), text_w)
            .. '##pick' .. i
        local picked = imgui.Selectable(label, isNow)
        if g.progress and g.progress.unfinished then imgui.PopStyleColor() end
        if picked then
            choose_item(set, editorState.selection.slot, g)
            selectedCopy = g
        end
        if (editorState.ui.drag == nil) and (imgui.IsItemActive ~= nil) and (imgui.IsMouseDragging ~= nil)
            and imgui.IsItemActive() and imgui.IsMouseDragging(0) then
            editorState.ui.drag = { g = g, slot = editorState.selection.slot } -- drop it on a slot in the grid
        end
        if isNow and scroll and (imgui.SetScrollHereY ~= nil) then
            imgui.SetScrollHereY(0.5)
            scroll = false
        end
        if imgui.IsItemClicked(1) then request_context('picker', set, editorState.selection.slot, g) end
        if imgui.IsItemHovered() and itemTooltip.HoverReady(imgui, 'pick:' .. g.key, editorState.ui.frame) then
            local tooltipStarted = profiler.Start()
            itemTooltip.Draw(
                imgui,
                palette,
                itemTooltip.Model(g, g, {
                    description = describe(g.name),
                    bag = g.bag,
                    equippable = row.equippable,
                    bags = row.bags,
                    otherSlot = inOther[g.lname],
                    usedIn = (ctx.used_in ~= nil) and ctx.used_in(g.name) or nil,
                })
            )
            profiler.Finish('Item tooltip', tooltipStarted)
        end
        if (statW > 0) and not isNow then -- its stat changes: green better, red worse, fitted to the column
            local parts = DC.by[g.key]
            if parts == nil then
                DC.before = DC.before or ctx.slot_stats(set, slotNow)
                local ok, res = pcall(ctx.piece_delta, slotNow, g, DC.before)
                parts = ok and res or {}
                DC.by[g.key] = parts
            end
            local used, full = 0, {}
            for k, p in ipairs(parts) do
                local w = text_w(p.text) + ((k > 1) and 6 or 0)
                if used + w > statW - 8 then break end
                if k == 1 then imgui.SameLine(statX) else imgui.SameLine(0, 6) end
                imgui.TextColored((p.better == true) and palette.ok or ((p.better == false) and palette.bad or palette.dim),
                    p.text)
                if imgui.IsItemHovered() then
                    for _, q in ipairs(parts) do full[#full + 1] = q.full end
                    set_tip('Against the piece in ' .. slotNow .. ' now:\n' .. table.concat(full, '\n'))
                end
                used = used + w
            end
        end
        imgui.SameLine(bagX + 5) -- its bag as a tag: green worn here, amber not in a bag you can wear from
        pill(cardText.Fit(picker.BagCaption(row.bags, g.bag), bagWidth - 18, text_w),
            isNow and palette.ok or (row.equippable and palette.dim or palette.warn),
            isNow and palette.okBg or (row.equippable and palette.chipBg or palette.warnBg))
        if y0 ~= nil then
            editorState.cache.rowH = imgui.GetCursorPosY() - y0
        end -- first frame: every row drawn, the height measured
    end
    if clip and (#editorState.cache.picks > 0) then -- the list's full height, so the scrollbar is right
        imgui.SetCursorPosY(top + #editorState.cache.picks * editorState.cache.rowH)
        imgui.Dummy({ 1, 0 })
    end
    if #editorState.cache.picks == 0 then
        imgui.TextColored(
            palette.dim,
            (find ~= '') and 'No items match. Clear the search or reset filters.'
                or (
                    not editorState.ui.anyJob[1]
                        and 'Nothing you own fits your job and level: tick Any job / level.' or 'Nothing you own fits.'
                )
        )
    end
    imgui.EndChild()
end

-- To fill: what still needs gear, across every set: slots left out (commented out, as /gcbuild leaves them), pieces
-- you do not own, pieces in a bag you cannot equip from, weapon modes with no weapon you own. Rebuilt on each change.
fill_list = function()
    if editorState.cache.fillVer == editorState.document.revision then return editorState.cache.fill end
    local F = { left = {}, notOwned = {}, move = {}, modes = {}, n = 0 }
    local idx = {}
    local function add(list, key, name, why, set, slot)
        local k = list .. '\0' .. key
        local e = idx[k]
        if e == nil then
            e = { name = name, why = why, places = {} }
            idx[k] = e
            table.insert(F[list], e)
        end
        e.places[#e.places + 1] = { set = set.name, slot = slot, id = '##gcf_' .. list .. set.name .. slot }
        F.n = F.n + 1
    end
    for _, set in ipairs(editorState.document.model.list) do
        if (set.code == nil) and not set.extra then
            for _, slot in ipairs(SCREEN) do
                local v = current(set, slot)
                if v == nil then
                    local gh = ghost_of(set, slot)
                    if gh ~= nil then add('left', string.lower(gh.name), gh.name, gh.why, set, slot) end
                elseif (v.kind == 'item') and (v.name ~= nil) and not LAC_WORDS[string.lower(v.name)] then
                    local bag, ok = where(v.name)
                    if bag == nil then
                        add('notOwned', string.lower(v.name), v.name, nil, set, slot)
                    elseif not ok then
                        add('move', string.lower(v.name), v.name, bag, set, slot)
                    end
                end
            end
        end
    end
    local function by_count(a, b)
        if #a.places ~= #b.places then return #a.places > #b.places end
        return a.name < b.name
    end
    table.sort(F.left, by_count)
    table.sort(F.notOwned, by_count)
    table.sort(F.move, by_count)
    -- weapon modes: the /wm list as loaded; a mode whose Weapon_<mode> set has no weapon you own puts nothing on
    for _, m in
        ipairs(
            (not editorState.document.inactive and (ctx.gearEngine ~= nil)
                and (type(ctx.gearEngine.WeaponModes) == 'table')) and ctx.gearEngine.WeaponModes
                or {}
        )
    do
        if (type(m) == 'string') and (m ~= 'None') then
            local set = editorState.document.model.byLower['weapon_' .. string.lower(m)]
            local why = nil
            if set == nil then
                why = 'no Weapon_' .. m .. ' set'
            elseif set.code == nil then
                local any = false
                for _, slot in ipairs({ 'Main', 'Sub', 'Range', 'Ammo' }) do
                    local v = current(set, slot)
                    if (v ~= nil) and (v.name ~= nil) and (where(v.name) ~= nil) then
                        any = true
                        break
                    end
                end
                if not any then why = 'no weapon you own in Weapon_' .. m end
            end
            if why ~= nil then
                F.modes[#F.modes + 1] = { mode = m, why = why, set = set }
                F.n = F.n + 1
            end
        end
    end
    editorState.cache.fill, editorState.cache.fillVer = F, editorState.document.revision
    return F
end

local function draw_fill()
    local F = fill_list()
    if F.n > 0 then
        imgui.TextColored(palette.dim, 'What still needs gear, in every set.')
        help(
            'Everything that still needs gear, in every set.\n'
                .. '- Click a set and slot: it opens on the Gear tab; your pick brings you back here.\n'
                .. '- Left out: commented out in the file (how /gcbuild leaves gear you lack).\n'
                .. 'Nothing is saved until Save + reload.'
        )
        local function cnt(list)
            local c = 0
            for _, e in ipairs(list) do
                c = c + #e.places
            end
            return c
        end
        local a, b, c = cnt(F.left), cnt(F.notOwned), cnt(F.move)
        pill('Left out ' .. a, (a > 0) and palette.warn or palette.dim, (a > 0) and palette.warnBg or palette.chipBg)
        imgui.SameLine(0, 14)
        pill('Not owned ' .. b, (b > 0) and palette.bad or palette.dim, (b > 0) and palette.badBg or palette.chipBg)
        imgui.SameLine(0, 14)
        pill('Wrong bag ' .. c, (c > 0) and palette.warn or palette.dim, (c > 0) and palette.warnBg or palette.chipBg)
        if #F.modes > 0 then
            imgui.SameLine(0, 14)
            pill('Weapon modes ' .. #F.modes, palette.warn, palette.warnBg)
        end
    end
    imgui.BeginChild('##gcedit_fill', { 0, 0 }, 0)
    if F.n == 0 then
        editorPanels.FillComplete(imgui, palette, draw_png)
        imgui.EndChild()
        return
    end
    local clip = clip_begin()
    editorState.ui.fillFold = editorState.ui.fillFold or {}
    -- Each piece: its name (blue) with why and how many slots; under it one row per place, the set (bright) and the
    -- slot (dim) in two columns. The whole row is the click.
    if F.setW == nil then
        local w = 0
        for _, list in ipairs({ F.left, F.notOwned, F.move }) do
            for _, e in ipairs(list) do
                for _, pl in ipairs(e.places) do
                    local tw = (imgui.CalcTextSize ~= nil) and tonumber((xy(imgui.CalcTextSize(pl.set))))
                        or (#pl.set * 7)
                    if tw > w then w = tw end
                end
            end
        end
        F.setW = math.min(w, 220) + 16
    end
    local function why_col(why)
        if why == 'not owned' then return palette.bad end
        if string.match(why, '^only %d') then return palette.warn end
        return palette.dim
    end
    local function section(list, title, col, tip)
        if #list == 0 then return end
        local n = 0
        for _, e in ipairs(list) do
            n = n + #e.places
        end
        imgui.Spacing()
        local folded = editorState.ui.fillFold[title] == true
        imgui.PushStyleColor(ImGuiCol_Text, col)
        if imgui.Selectable( string.format( '%s %s: %d slot%s##gcf_h%s', folded and '+' or '-', title, n,
            (n == 1) and '' or 's', title ), false ) then
            editorState.ui.fillFold[title] = not folded
        end
        imgui.PopStyleColor(1)
        if (tip ~= nil) and imgui.IsItemHovered() then set_tip(wrap(tip .. '\nClick to fold.', 64)) end
        imgui.Separator()
        for _, e in ipairs(folded and NONE or list) do
            if not clip_skip(clip, e) then
                imgui.Spacing()
                imgui.TextColored(palette.blue, e.name)
                if (e.why ~= nil) and (#e.why > 24) then -- a long note from the file: hover for it
                    tag('(note)', palette.dim)
                    if imgui.IsItemHovered() then set_tip(wrap(e.why, 60)) end
                elseif e.why ~= nil then
                    tag(e.why, why_col(e.why))
                end
                if #e.places > 1 then
                    tag('x' .. #e.places, palette.dim)
                    local slot, same = e.places[1].slot, true
                    for _, pl in ipairs(e.places) do
                        if pl.slot ~= slot then
                            same = false
                            break
                        end
                    end
                    if same and (list ~= F.move) then
                        imgui.SameLine()
                        if imgui.SmallButton('Fill all##gcf_fa' .. title .. e.name) then
                            local sets = {}
                            for _, pl in ipairs(e.places) do
                                sets[pl.set] = true
                            end
                            editorState.ui.fillAll = { name = e.name, slot = slot, sets = sets, n = #e.places }
                            go_to(e.places[1].set, slot, 'gear')
                            editorState.ui.fromFill = true
                        end
                        if imgui.IsItemHovered() then
                            set_tip('Pick once on the Gear tab: it goes in all ' .. #e.places .. ' sets.')
                        end
                    end
                end
                if list == F.notOwned then
                    imgui.SameLine()
                    if imgui.SmallButton('Comment out##gcf_co' .. e.name) then
                        editorState.ui.cmt, editorState.ui.cmtNote[1] = e, ''
                        imgui.OpenPopup('##gcedit_cmt')
                    end
                    if imgui.IsItemHovered() then
                        set_tip(
                            'Keep it in the file as a placeholder (gear still being made): its slot line\nbecomes a -- comment, with a note if you like. The set under it shows through.'
                        )
                    end
                end
                clip_drawn(clip, e)
            end
            for _, pl in ipairs(e.places) do
                if not clip_skip(clip, pl) then
                    local x0 = (imgui.GetCursorPosX ~= nil) and imgui.GetCursorPosX() or nil
                    if imgui.Selectable( pl.id,
                        (editorState.selection.setName == pl.set) and (editorState.selection.slot == pl.slot) ) then
                        go_to(pl.set, pl.slot, 'gear')
                        editorState.ui.fromFill = true
                    end
                    if x0 ~= nil then
                        imgui.SameLine(x0 + 14)
                    else
                        imgui.SameLine()
                    end
                    imgui.TextUnformatted(pl.set)
                    if x0 ~= nil then
                        imgui.SameLine(x0 + 14 + F.setW)
                    else
                        imgui.SameLine()
                    end
                    imgui.TextColored(palette.dim, pl.slot)
                    clip_drawn(clip, pl)
                end
            end
        end
    end
    section(
        F.left,
        'Left out',
        palette.warn,
        "The example's piece you lack, commented out where it stood: the set under it shows through until you fill it."
    )
    section(F.notOwned, 'Not owned', palette.bad, 'The set names it but you do not have it: that slot does nothing.')
    section(F.move, 'In a bag you cannot equip from', palette.warn, 'Move it to a wardrobe (or Inventory).')
    if #F.modes > 0 then
        imgui.Spacing()
        imgui.TextColored(palette.warn, 'Weapon modes with no weapon you own: ' .. #F.modes)
        help('/wm still cycles to them.\nThey put nothing on until Weapon_<mode> names a weapon you own.')
        for i, m in ipairs(F.modes) do
            if m.set ~= nil then
                if imgui.Selectable(m.mode .. '##gcfm' .. i, editorState.selection.setName == m.set.name) then
                    go_to(m.set.name, 'Main', 'gear')
                    editorState.ui.fromFill = true
                end
            else
                if imgui.SmallButton('Make##gcfm' .. i) then make_set('Weapon_' .. m.mode, nil, true) end
                imgui.SameLine()
                imgui.TextUnformatted(m.mode)
            end
            tag(m.why, palette.dim)
        end
    end
    clip_end(clip)
    if (editorState.ui.cmt ~= nil) and imgui.BeginPopup('##gcedit_cmt') then
        local e = editorState.ui.cmt
        imgui.TextUnformatted(
            'Comment out ' .. e.name .. ' in ' .. #e.places .. ' slot' .. ((#e.places == 1) and '' or 's') .. ':'
        )
        imgui.PushItemWidth(320)
        imgui.InputTextWithHint(
            '##gcedit_cmtnote', 'Note (optional): JSE in progress, need 3 more...', editorState.ui.cmtNote, 80
        )
        imgui.PopItemWidth()
        if imgui.Button('Comment out##gcedit_cmtok') then
            local note = string.match(editorState.ui.cmtNote[1] or '', '^%s*(.-)%s*$')
            for _, pl in ipairs(e.places) do
                local set = editorState.document.model.byName[pl.set]
                if (set ~= nil) and (set.code == nil) and (set.slots[pl.slot] ~= nil) then
                    editorState.document.edits[set.name] = editorState.document.edits[set.name] or {}
                    editorState.document.edits[set.name][pl.slot] =
                        { remove = true, comment = true, name = e.name, why = (note ~= '') and note or nil }
                end
            end
            editorState.document.revision, editorState.ui.cmt = editorState.document.revision + 1, nil
            imgui.CloseCurrentPopup()
        end
        imgui.SameLine()
        if imgui.SmallButton('Cancel##gcedit_cmtno') then
            editorState.ui.cmt = nil
            imgui.CloseCurrentPopup()
        end
        imgui.TextColored(palette.dim, 'Unsaved until Save + reload. Undo slot / Revert set undoes it.')
        imgui.EndPopup()
    end
    imgui.EndChild()
end

local function menu_button(label, enabled, color)
    return ctx.menu_item(label, enabled and true or false, false, color)
end

local function draw_context_menu()
    if editorState.ui.openContext then
        imgui.OpenPopup('##gcedit_context')
        editorState.ui.openContext = nil
    end
    if not imgui.BeginPopup('##gcedit_context') then return end
    local context = editorState.ui.context
    local set = context and editorState.document.model.byName[context.set]
    if set then
        -- a title, not a row: heading colour, and for a set the heading it sits under (Move up / down are in it)
        imgui.TextColored(palette.section, set.name .. (context.slot and (' / ' .. context.slot) or ''))
        if context.kind == 'set' then
            imgui.SameLine()
            imgui.TextColored(palette.dim, 'in ' .. set.group)
        end
        imgui.Separator()
        if context.kind == 'set' then
            local item = ctx.menu_item
            -- Open / Compare: only for a set other than the open one
            local selected = editorState.document.model.byName[editorState.selection.setName]
            if selected ~= set then
                if item('Open set##context') then editorPreferences.Select(editorState, set.name) end
                if item('Compare with current set##context', (selected ~= nil) and not selected.code
                    and not set.code and not selected.extra and not set.extra) then
                    editorState.ui.cmp = { set = selected.name, with = set.name }
                    editorState.selection.tab = 'compare'
                end
                imgui.Separator()
            end
            set_action_entries(set, 'edit')
            if item('Copy to other jobs...##copyjobs') then editorState.ui.copyJobs = { set = set.name, open = true } end
            if imgui.IsItemHovered() then
                set_tip('Its pieces into other job files. Pieces a job can\'t wear are left out; you pick the files.')
            end
            -- Move up / down under its heading (the heading takes your own order), or to another heading: this
            -- set by its exact name (char.lua's settings, or the shared headings file)
            -- a set inside a set (Buffs['Haste']) sits under its parent in file order, or where it was moved
            local H = ctx.headings
            local parent = (set.parentName ~= nil) and editorState.document.model.byName[set.parentName] or nil
            local nested = (parent ~= nil) and (parent.group == set.group)
            imgui.Separator()
            if not nested then
                for _, mv in ipairs({ { 'Move up', -1 }, { 'Move down', 1 } }) do
                    if item(mv[1] .. ' in ' .. set.group .. '##ownorder', true, true) then
                        local list = H.lib.MoveInOrder(H.rows(set.group), set.name, mv[2])
                        if list == nil then
                            H.savePrefs(nil, (mv[2] < 0) and 'already at the top' or 'already at the bottom')
                        else
                            H.savePrefs({
                                EditorOrder = H.lib.With(H.pref('EditorOrder'), set.group, list),
                                EditorSort = H.lib.With(H.pref('EditorSort'), set.group, 'own'),
                            })
                        end
                    end
                end
            end
            local scope = (H.source() == 'shared') and 'every character' or 'every job on this character'
            submenu('Move to heading##moveto', 'Move to heading (' .. scope .. '):', function()
                if imgui.BeginMenu ~= nil then imgui.TextColored(palette.dim, 'For ' .. scope .. ':') end
                for _, h in ipairs(H.order()) do
                    if (h ~= set.group) and item(h .. '##moveto') then
                        local to = h
                        if (parent ~= nil) and (parent.group == h) then to = nil end -- its parent's: back under it
                        H.save(H.lib.Place(H.setting(), H.builtins, set.name, to))
                    end
                end
                if (set.builtin ~= nil) and (H.lib.PlacedBy(H.setting(), set.name) ~= nil) then
                    imgui.Separator()
                    if item(((parent ~= nil) and ('Back under ' .. parent.name)
                        or 'Back to where its name puts it') .. '##moveto') then
                        H.save(H.lib.Place(H.setting(), H.builtins, set.name, nil))
                    end
                end
            end)
            draw_weapon_copies(set)
            draw_wm_order(set)
            local wmode = weapon_set_mode(set)
            if (wmode ~= nil) and item('Weapon sets for /wm ' .. wmode .. '...##gcws_menu') then
                editorState.ui.requestWeaponSets = wmode
            end
            imgui.Separator()
            set_action_entries(set, 'drop')
        else
            local slot, gear = context.slot, context.gear
            local value, owned, source = inspection_target(set, slot, gear, context.source)
            if context.kind == 'result' and value then
                local copies = editorState.inventory.copiesByName[string.lower(value.name)] or {}
                owned = #copies == 1 and copies[1] or nil
            end
            local saved = set.slots[slot]
            local editable = not set.code and not set.extra and not editorState.document.deleted[set.name]
                and (not saved or saved.value.kind ~= 'code')
            if value and value.name then imgui.TextColored(palette.blue, value.name) end
            if source then imgui.TextColored(palette.dim, source) end
            if menu_button('Inspect item below grid##context', value and value.name) then
                inspect_item(set.name, slot, value, owned, source)
                imgui.CloseCurrentPopup()
            end
            imgui.TextColored(palette.dim, value and value.name
                and 'View stats while browsing; leaves this slot unchanged.'
                or 'No item in this slot or the selected result.')
            if menu_button('Find in every job file##context', value and value.name) then
                editorState.ui.findItem = { name = value.name, open = true }
                imgui.CloseCurrentPopup()
            end
            imgui.Separator()
            if context.kind == 'picker' then
                if menu_button('Use item in slot##context', editable) then
                    choose_item(set, slot, gear)
                    imgui.CloseCurrentPopup()
                end
            elseif menu_button('Choose gear##context', editable) then
                go_to(set.name, slot, 'gear')
                imgui.CloseCurrentPopup()
            end
            local here = (context.kind == 'slot') and current(set, slot) or nil
            if (context.kind == 'slot') and menu_button('Put in other sets...##context',
                (here ~= nil) and (here.kind == 'item') and (here.name ~= nil)) then
                local mx, my = xy(imgui.GetItemRectMin())
                editorState.ui.requestPutIn = { set = set.name, slot = slot,
                    at = (mx ~= nil) and (my ~= nil) and { mx, my } or nil }
                imgui.CloseCurrentPopup()
            end
            imgui.Separator()
            local defined = current(set, slot)
            if menu_button('Set displaced rule##context', editable
                and not (defined and defined.name and string.lower(defined.name) == 'displaced')) then
                edit(set, slot, { name = 'displaced', augs = {} })
                feedback('Set ' .. set.name .. ' / ' .. slot .. ' to displaced (unsaved).')
                imgui.CloseCurrentPopup()
            end
            if imgui.IsItemHovered() then
                set_tip('Mark this slot as emptied by another equipped item, such as a two-handed weapon or instrument.')
            end
            imgui.Separator()
            if menu_button('Undo slot edits##context', editorState.document.edits[set.name]
                and editorState.document.edits[set.name][slot]) then
                undo_slot(set, slot)
                imgui.CloseCurrentPopup()
            end
            if menu_button('Clear slot##context', editable and (current(set, slot) or ghost_of(set, slot)),
                palette.bad) then
                edit(set, slot, nil)
                feedback('Cleared ' .. set.name .. ' / ' .. slot .. ' (unsaved).')
                imgui.CloseCurrentPopup()
            end
        end
    end
    imgui.EndPopup()
end

-- Rename: staged like a deletion and written on Save (setFile.AddRenames: the key and every reference in code).
-- The set keeps its old name in the editor until the reload.
local function variants_of(name)
    local out = {}
    for _, set in ipairs(editorState.document.model.list) do
        if (set.parentName == nil) and (string.sub(set.name, 1, #name + 1) == name .. '_') then
            out[#out + 1] = set.name
        end
    end
    return out
end

local function rename_problem(old, new)
    if (new == '') or string.find(new, '[\r\n]') then return 'Type a name.' end
    if new == old then return 'That is its name now.' end
    local taken = editorState.document.model.byLower[string.lower(new)]
    if (taken ~= nil) and (taken.name ~= old) then return new .. ' exists (names ignore case).' end
    for from, to in pairs(editorState.document.renames or {}) do
        if (from ~= old) and (string.lower(to) == string.lower(new)) then
            return from .. ' is being renamed to ' .. to .. '.'
        end
    end
    if (string.sub(old, 1, 7) == 'Weapon_') ~= (string.sub(new, 1, 7) == 'Weapon_') then
        return 'A weapon set keeps its Weapon_ start (it is what makes it a /wm mode).'
    end
end

-- A set not saved yet: renamed in place, everywhere the editor keys it by name.
local function rename_new(set, new)
    local doc, old = editorState.document, set.name
    doc.model.byName[old], doc.model.byLower[set.lname] = nil, nil
    set.name, set.lname, set.bracket = new, string.lower(new), (setFile.FormatKey(new) ~= new)
    if set.parentName ~= nil then set.key = setFile.ChildKey(set, new) end
    set.group = group_of(new, set.parentName)
    doc.model.byName[new], doc.model.byLower[set.lname] = set, set
    doc.edits[new], doc.edits[old] = doc.edits[old], nil
    for _, u in ipairs(editorState.history.entries or {}) do
        if u.set == old then u.set = new end
    end
    if editorState.selection.setName == old then editorState.selection.setName = new end
    doc.revision = doc.revision + 1
end

    return { draw_over = draw_over, draw_picker = draw_picker, fill_list = fill_list, draw_fill = draw_fill,
        draw_weapon_sets = draw_weapon_sets,
        draw_mset_mode = draw_mset_mode,
        draw_wm_mode = draw_wm_mode,
        draw_put_in = draw_put_in, draw_upgrade = draw_upgrade,
        draw_context_menu = draw_context_menu, variants_of = variants_of, rename_problem = rename_problem,
        rename_new = rename_new }
end
