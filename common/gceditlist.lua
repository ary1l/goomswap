-- /gcedit: the set list, navigation, set status and RP.
return function(
    BASE, CHILD_BORDERS, GROUPS, SCREEN, SLOT_BIT, current, editorData, editorPanels, editorPreferences,
    editorState, empty_armor, help, imgui, left_bar, make_set, owned_for, palette, pill, profiler, request_context,
    set_tip, suggestions, tag, text_w, unsaved_set_count, where, ctx
)
local function go_to(name, slot, tab)
    if (editorState.selection.setName ~= nil) and (name ~= editorState.selection.setName) then
        editorState.selection.back = editorState.selection.back or {}
        editorState.selection.back[#editorState.selection.back + 1] = editorState.selection.setName
        if #editorState.selection.back > 10 then table.remove(editorState.selection.back, 1) end
    end
    editorPreferences.Select(editorState, name, slot, tab)
    editorState.ui.fromFill = nil -- To fill sets it again after this: a pick there goes back to the list
end

local NONE = {} -- an empty list, never written (a folded group's rows)
local LAC_WORDS = { remove = true, displaced = true, ignore = true } -- LAC slot words, not items
local function is_slot_word(v)
    return v ~= nil and v.kind == 'item' and v.name ~= nil and LAC_WORDS[string.lower(v.name)]
end

-- The slots of a set naming gear you do not own ('Waist: Flume Belt'), redone on each edit
-- (editorState.document.revision). nil: none.
local function not_owned(set)
    if set.noVer == editorState.document.revision then return set.noList end
    local out = nil
    if (set.code == nil) and not set.extra then
        for _, slot in ipairs(SCREEN) do
            local v = current(set, slot)
            if (v ~= nil) and (v.kind == 'item') and (v.name ~= nil) and not LAC_WORDS[string.lower(v.name)]
                and (where(v.name) == nil) then
                out = out or {}
                out[#out + 1] = slot .. ': ' .. v.name
            end
        end
    end
    set.noList, set.noVer = out, editorState.document.revision
    return out
end

-- Long lists draw only the rows in view: a row out of view is stepped over by its height (measured when it was last
-- drawn, kept on the row's own table), so 300 rows cost what the 30 on screen do. A row with no height yet is drawn.
local function clip_begin()
    if (imgui.GetScrollY == nil) or (imgui.GetWindowHeight == nil) or (imgui.GetCursorPosY == nil)
        or (imgui.SetCursorPosY == nil) then
        return nil
    end
    local top = imgui.GetScrollY()
    return { lo = top - 60, hi = top + imgui.GetWindowHeight() + 60, skipped = false, y = 0 }
end
local function clip_skip(clip, row, force) -- true: out of view, stepped over
    if clip == nil then return false end
    local y = imgui.GetCursorPosY()
    clip.y = y
    local h = row.clipH
    if force or (h == nil) or ((y + h >= clip.lo) and (y <= clip.hi)) then return false end
    imgui.SetCursorPosY(y + h)
    clip.skipped = true
    return true
end
local function clip_drawn(clip, row)
    if clip ~= nil then row.clipH = imgui.GetCursorPosY() - clip.y end
end
local function clip_end(clip) -- rows stepped over at the end still count for the scrollbar
    if (clip ~= nil) and clip.skipped then imgui.Dummy({ 1, 0 }) end
end
-- Derived attention state changes only with document/inventory revisions.
local function set_status(set)
    local cache = editorState.cache
    if cache.statusRevision ~= editorState.document.revision then
        cache.statusRevision, cache.statuses, cache.rpUsage = editorState.document.revision, {}, {}
    end
    if cache.statuses[set.name] then return cache.statuses[set.name] end
    local missing, gaps = not_owned(set), empty_armor(set)
    local status = {
        missing = missing and #missing or 0,
        empty = gaps and set.name ~= 'Tp_Default' and #gaps or 0,
        unfinished = {},
        armor = 0,
        weapons = 0,
        edited = set.new
            or editorState.document.edits[set.name] ~= nil
            or editorState.document.deleted[set.name] ~= nil,
    }
    if not set.code and not set.extra then
        for _, slot in ipairs(SCREEN) do
            local value = current(set, slot)
            if value and value.kind == 'item' and not is_slot_word(value) then
                local key = SLOT_BIT[slot] < 4 and 'weapons' or 'armor'
                status[key] = status[key] + 1
            end
            local gear = owned_for(set, slot)
            if gear and gear.progress and gear.progress.unfinished then
                status.unfinished[#status.unfinished + 1] = slot
                    .. ': ' .. gear.name .. ' (' .. gear.progress.label .. ')'
            end
        end
    end
    cache.statuses[set.name] = status
    return status
end

local function set_color(set, status)
    if editorState.document.deleted[set.name] then return palette.bad end
    if status.edited then return palette.warn end
    if status.missing > 0 then return palette.bad end -- unfinished RP: a dot after the name, not its colour
    if set.code or set.extra or set.count == 0 then return nil end
    if status.armor == 12 then return status.weapons == 4 and palette.ok or palette.armor end
    -- Partial overlays are useful as written. Base armor gaps still need attention.
    if status.empty == 0 then return palette.ok end
end

local function set_completion_tip(set, status)
    if set.code or set.extra then
        return 'Code-defined or nested set: slot completeness cannot be determined without executing Lua.'
    end
    local detail = status.armor == 12 and (status.weapons == 4
        and 'All 16 slots name items.'
        or ('Armor complete: all 12 armor/accessory slots name items.\n'
            .. status.weapons
                .. '/4 top-row slots name items. Omitted weapons stay unchanged; no weapon swap is required.'))
        or (((status.armor == 0) and (status.weapons > 0))
            and ('Weapons only (' .. status.weapons .. '/4 top-row slots): armor stays as it is.')
            or ('Partial definition: ' .. status.armor .. '/12 armor/accessory slots name items.\n'
                .. 'Omitted slots keep earlier gear; overlays can be intentionally partial.'))
    if status.missing > 0 then
        detail = detail .. '\n' .. status.missing .. ((status.missing == 1) and ' named item is' or ' named items are')
            .. ' not owned.'
    end
    if #status.unfinished > 0 then
        detail = detail .. '\n' .. #status.unfinished .. ((#status.unfinished == 1) and ' item needs' or ' items need')
            .. ' RP.'
    end
    if status.edited then detail = detail .. '\nIncludes unsaved edits.' end
    return detail
end

local function has_issue(set)
    local status = set_status(set)
    return status.missing > 0 or status.empty > 0 or #status.unfinished > 0
end

-- Nothing seems to look for it (gceditactions Unused), redone when the set list or an edit changes.
local function is_unused(set)
    if set.unusedVer ~= editorState.document.revision then
        set.unused, set.unusedVer = ctx.actions.Unused(set), editorState.document.revision
    end
    return set.unused
end

-- Search: a set's name, else an item it names (nyame: every set wearing a Nyame piece), as edited.
local function names_item(set, query)
    for _, slot in ipairs(SCREEN) do
        local v = current(set, slot)
        if (v ~= nil) and (v.name ~= nil) and string.find(string.lower(v.name), query, 1, true) then return true end
    end
    return false
end
local function matches_set(set, query)
    if (query ~= '') and not string.find(set.lname, query, 1, true) and not names_item(set, query) then return false end
    local ui, status = editorState.ui, set_status(set)
    return (not ui.issuesOnly[1] or has_issue(set))
        and (not ui.editedOnly[1] or status.edited)
        and (not ui.missingOnly[1] or status.missing > 0) and (not ui.needsRpOnly[1] or #status.unfinished > 0)
        and (not ui.unusedOnly[1] or is_unused(set))
end

-- Unused filter on: delete every set it shows, staged (written on Save, with a backup).
local function draw_unused_delete()
    local names = {}
    for _, grp in ipairs(editorState.cache.listRows or {}) do
        for _, set in ipairs(grp.rows) do
            if not editorState.document.deleted[set.name] then names[#names + 1] = set.name end
        end
    end
    if #names > 0 then
        imgui.PushStyleColor(ImGuiCol_Text, palette.bad)
        if imgui.SmallButton('Delete these ' .. #names .. '...##unused_delete') then
            editorState.ui.unusedDelete = names
            imgui.OpenPopup('##gcedit_unused_delete')
        end
        imgui.PopStyleColor()
    end
    if not imgui.BeginPopup('##gcedit_unused_delete') then return end
    local list = editorState.ui.unusedDelete or {}
    imgui.TextColored(palette.bad, 'Delete ' .. #list .. ' sets on Save?')
    imgui.TextColored(palette.dim, 'Nothing in GoomSwap or your job file seems to look for them. A backup is kept.')
    imgui.BeginChild('##unused_delete_list', { 360, math.min(220, 18 * #list + 8) }, CHILD_BORDERS)
    for _, n in ipairs(list) do imgui.TextUnformatted(n) end
    imgui.EndChild()
    imgui.PushStyleColor(ImGuiCol_Text, palette.bad)
    if imgui.Button('Delete them##unused_delete') then
        for _, n in ipairs(list) do
            editorState.document.deleted[n] = true
            editorState.document.edits[n] = nil
        end
        editorState.document.revision = editorState.document.revision + 1
        editorPreferences.Feedback(editorState, #list .. ' deletions staged (unsaved).')
        imgui.CloseCurrentPopup()
    end
    imgui.PopStyleColor()
    imgui.SameLine()
    if imgui.Button('Cancel##unused_delete') then imgui.CloseCurrentPopup() end
    imgui.EndPopup()
end

local function rp_uses(gear)
    local cache = editorState.cache
    local key = gear.key or tostring(gear)
    cache.rpUsage = cache.rpUsage or {}
    if cache.rpUsage[key] then return cache.rpUsage[key] end
    local started = profiler.Start()
    local uses = {}
    for _, candidate in ipairs(editorState.document.model.list) do
        if not candidate.code and not candidate.extra and not editorState.document.deleted[candidate.name] then
            for _, slot in ipairs(SCREEN) do
                if owned_for(candidate, slot) == gear then uses[#uses + 1] = { set = candidate.name, slot = slot } end
            end
        end
    end
    cache.rpUsage[key] = uses
    profiler.Finish('RP usage rebuild', started)
    return uses
end

-- Drag a set (the row's mouse held and moved) onto a heading: it goes under that heading. Onto another set: under
-- that set's heading, just before it, and the heading takes your own order. Same mouse rules as the gear picker's.
local function drag_set_from(set)
    if (editorState.ui.dragSet == nil) and (imgui.IsItemActive ~= nil) and (imgui.IsMouseDragging ~= nil)
        and imgui.IsItemActive() and imgui.IsMouseDragging(0) then
        editorState.ui.dragSet = set.name
    end
end
local function released_on_item()
    if (editorState.ui.dragSet == nil) or (imgui.IsMouseDown == nil) or imgui.IsMouseDown(0)
        or (imgui.GetMousePos == nil) then
        return false
    end
    local mx, my = ctx.xy(imgui.GetMousePos())
    local x1, y1 = ctx.xy(imgui.GetItemRectMin())
    local x2, y2 = ctx.xy(imgui.GetItemRectMax())
    return (mx ~= nil) and (x1 ~= nil) and (x2 ~= nil) and (mx >= x1) and (mx <= x2) and (my >= y1) and (my <= y2)
end
local function drop_set_here(heading, before)
    if not released_on_item() then return end
    local name = editorState.ui.dragSet
    editorState.ui.dragSet = nil
    if (before ~= nil) and (string.lower(before.name) == string.lower(name)) then return end -- dropped on itself
    local H = ctx.headings
    local moved = editorState.document.model.byName[name]
    local changes = {}
    local parent = (moved ~= nil) and (moved.parentName ~= nil) and editorState.document.model.byName[moved.parentName]
    if parent and (parent.group == heading) then -- back under its parent: no placement of its own
        if H.lib.PlacedBy(H.setting(), name) ~= nil then
            changes.EditorGroups = H.lib.Place(H.setting(), H.builtins, name, nil)
        end
        before = nil
    elseif (moved ~= nil) and (moved.group ~= heading) then
        changes.EditorGroups = H.lib.Place(H.setting(), H.builtins, name, heading)
    end
    if before ~= nil then
        local order = H.pref('EditorOrder')
        changes.EditorOrder = H.lib.With(order, heading, H.lib.DropInOrder(H.rows(heading), name, before.name))
        changes.EditorSort = H.lib.With(H.pref('EditorSort'), heading, 'own')
    end
    if next(changes) ~= nil then H.savePrefs(changes) end
end

-- A heading's right-click menu: move it, add a heading of your own below it, rename or remove one of yours, hide it,
-- sort its sets, go back to the built-in order, share them with every character. Saved in char.lua's settings (every
-- job on this character), or in the shared headings file.
local function draw_heading_menu()
    if editorState.ui.openHeadingMenu then
        imgui.OpenPopup('##gcedit_heading')
        editorState.ui.openHeadingMenu = nil
        editorState.ui.headingName = { '' }
    end
    if not imgui.BeginPopup('##gcedit_heading') then return end
    local H, name = ctx.headings, editorState.ui.headingMenu or ''
    local lib, builtins, now = H.lib, H.builtins, H.setting()
    local custom = lib.IsCustom(name, builtins)
    imgui.TextUnformatted(name)
    imgui.TextColored(palette.dim, custom and 'Your heading' or 'Built-in heading')
    imgui.Separator()
    if imgui.Button('Move up##heading') then H.save(lib.Move(now, builtins, name, -1), 'already at the top') end
    imgui.SameLine()
    if imgui.Button('Move down##heading') then H.save(lib.Move(now, builtins, name, 1), 'already at the bottom') end
    imgui.Separator()
    imgui.PushItemWidth(220)
    imgui.InputTextWithHint('##gcedit_headingname', 'Heading name', editorState.ui.headingName, 48)
    imgui.PopItemWidth()
    local typed = editorState.ui.headingName[1] or ''
    if imgui.Button('New heading below##heading') then
        if H.save(lib.Add(now, builtins, typed, name)) then imgui.CloseCurrentPopup() end
    end
    if custom then
        imgui.SameLine()
        if imgui.Button('Rename##heading') then
            if H.save(lib.Rename(now, builtins, name, typed)) then imgui.CloseCurrentPopup() end
        end
        if imgui.Button('Remove this heading##heading') then
            if H.save(lib.Remove(now, builtins, name)) then imgui.CloseCurrentPopup() end
        end
        if imgui.IsItemHovered() then set_tip('Its sets go back under their built-in headings.') end
    end
    imgui.Separator()
    -- hide: on this job, or on every job
    local job, hidden = H.job() or '?', H.pref('EditorHidden')
    local isHidden, scope = lib.IsHidden(hidden, name, job)
    if isHidden then
        imgui.TextColored(palette.warn, 'Hidden ' .. ((scope == 'all') and 'on every job' or ('on ' .. job)))
        if imgui.Button('Show again##heading') then
            if H.savePrefs({ EditorHidden = lib.Unhide(hidden, name, job) }) then imgui.CloseCurrentPopup() end
        end
    else
        if imgui.Button('Hide on ' .. job .. '##heading') then
            if H.savePrefs({ EditorHidden = lib.Hide(hidden, name, job) }) then imgui.CloseCurrentPopup() end
        end
        imgui.SameLine()
        if imgui.Button('Hide on every job##heading') then
            if H.savePrefs({ EditorHidden = lib.Hide(hidden, name, 'all') }) then imgui.CloseCurrentPopup() end
        end
        if imgui.IsItemHovered() then set_tip('Hidden headings come back with Show hidden, and in a search.') end
    end
    -- sets inside it: file order, A-Z, or your own (drag a set onto another, or Move up / down on a set)
    local sort = H.pref('EditorSort')
    local mode = lib.SortMode(sort, name)
    imgui.TextColored(palette.dim, 'Sets in it:')
    for _, m in ipairs({ { 'file', 'File order' }, { 'az', 'A-Z' }, { 'own', 'Your order' } }) do
        imgui.SameLine()
        if imgui.SmallButton(((mode == m[1]) and '> ' or '') .. m[2] .. '##sort_' .. m[1]) and (mode ~= m[1]) then
            H.savePrefs({ EditorSort = lib.With(sort, name, (m[1] ~= 'file') and m[1] or nil) })
        end
    end
    imgui.Separator()
    imgui.TextColored(palette.dim, 'Right-click a set: Move to heading. Or drag it onto a heading.')
    if imgui.Button('Built-in order##heading') then
        if H.save({}) then imgui.CloseCurrentPopup() end
    end
    if imgui.IsItemHovered() then set_tip('Every heading back to the built-in order; your own headings go away.') end
    -- where these are kept: this character's char.lua, or shared by every character without its own
    imgui.Separator()
    local shared = (H.source() == 'shared')
    imgui.TextColored(palette.dim, shared and 'Shared by every character (goomswap-shared.lua)'
        or 'Kept for this character (char.lua)')
    if shared then
        if imgui.Button('Only this character##heading') then H.ownCopy() end
        if imgui.IsItemHovered() then set_tip('Copies the shared headings into this character\'s char.lua.') end
    else
        if imgui.Button('Share with every character##heading') then H.share() end
        if imgui.IsItemHovered() then
            set_tip('Characters with no headings of their own use these (this one too, from now on).')
        end
    end
    imgui.EndPopup()
end

-- (?) for the set colours, each line drawn in its colour as now themed
local COLOR_KEY = {
    { 'ok', 'Full 16 slots, or a ready partial overlay.' },
    { 'armor', 'All 12 armor/accessory slots filled; weapons may stay unchanged.' },
    { 'rp', 'Dot after a name: a piece in it needs RP (the line over the list names them).' },
    { 'ok', 'A ring around the dot: on you now (On you now, over the list).' },
    { 'edge', 'Grey: neither full nor missing anything (a partial set, empty, or code).' },
    { 'bad', 'Names gear you do not own (or deleted on Save).' },
    { 'warn', 'Unsaved edits.' },
}
local function color_key()
    imgui.TextColored(palette.dim, '(?)')
    if not imgui.IsItemHovered() then return end
    imgui.PushStyleColor(ImGuiCol_PopupBg, { 0.055, 0.06, 0.08, 1 })
    imgui.BeginTooltip()
    imgui.PushTextWrapPos(440)
    imgui.TextUnformatted('The dot before a set\'s name (a green ring around it: on you now):')
    for _, row in ipairs(COLOR_KEY) do imgui.TextColored(palette[row[1]], row[2]) end
    imgui.TextColored(palette.dim, 'Colors describe this definition, not inherited layers. Empty weapon slots are '
        .. 'never counted as gaps. Numbers after a name: (empty slots, not owned); hover one.')
    imgui.PopTextWrapPos()
    imgui.EndTooltip()
    imgui.PopStyleColor()
end

-- MELEE and WEAPONS rows: the command that puts the set on, right-aligned, and a sentence for its hover. Tp_<mode>
-- for each /mset mode (Default too); Weapon_<mode> and its own sets by gceditactions' When. Kept per revision.
local function row_cmd(set)
    if (set.cmdVer == editorState.document.revision) then return set.cmd or nil end
    set.cmdVer, set.cmd = editorState.document.revision, false
    if (set.parentName ~= nil) then return nil end
    local mode = string.match(set.name, '^[Tt][Pp]_(.+)$')
    if (mode ~= nil) and (ctx.melee_modes ~= nil) then
        for _, m in ipairs(ctx.melee_modes()) do
            if (string.lower(m) == string.lower(mode)) then
                local lm = string.lower(m)
                if (lm == 'default') then
                    set.cmd = { text = '/mset default', tip = '/mset default (Base): engaged, the TP set every melee '
                        .. 'mode starts from.' }
                else
                    set.cmd = { text = '/mset ' .. lm, tip = '/mset ' .. lm .. ' wears it over Tp_Default'
                        .. (((set.count or 0) == 0) and ': empty, so the same gear as Default.' or '.') }
                end
                return set.cmd
            end
        end
        return nil
    end
    if string.match(set.name, '^[Ww]eapon_') and (ctx.actions ~= nil) and (ctx.actions.When ~= nil) then
        local ok, text, short = pcall(ctx.actions.When, set)
        local wm = ok and (type(short) == 'string') and string.match(short, '^/wm (%S+)') or nil
        if (wm ~= nil) then
            local cond = string.sub(short, #wm + 6)
            cond = string.gsub(string.gsub(cond, "when you can't dual wield", 'no dual wield'), '^%s*with%s+', '')
            cond = string.gsub(cond, '^[%s,]+', '')
            set.cmd = { text = (cond ~= '') and string.lower(cond) or ('/wm ' .. string.lower(wm)), tip = text }
            return set.cmd
        end
    end
    return nil
end
-- The command at a row's right end, cut with '...' to the room left (the hover has it whole); nil when not even a few
-- letters fit.
local function fit_cmd(t, room)
    if text_w(t) <= room then return t end
    local lo, hi = 0, #t - 1
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if text_w(string.sub(t, 1, mid) .. '...') <= room then lo = mid else hi = mid - 1 end
    end
    return (lo >= 5) and (string.sub(t, 1, lo) .. '...') or nil
end

-- A small filled dot at the cursor (dx from it), centred on the text line; nothing drawn without a draw list.
local function dot(dx, col)
    if (imgui.GetWindowDrawList == nil) or (imgui.GetCursorScreenPos == nil) or (imgui.GetColorU32 == nil) then
        return
    end
    local x, y = ctx.xy(imgui.GetCursorScreenPos())
    local lh = (imgui.GetTextLineHeight ~= nil) and imgui.GetTextLineHeight() or 14
    if (x ~= nil) and (y ~= nil) then
        imgui.GetWindowDrawList():AddCircleFilled({ x + dx, y + lh / 2 }, 3, imgui.GetColorU32(col), 12)
    end
end
local function ring(dx, col) -- an open circle around the row's dot: the set is on you now
    if (imgui.GetWindowDrawList == nil) or (imgui.GetCursorScreenPos == nil) or (imgui.GetColorU32 == nil) then
        return
    end
    local x, y = ctx.xy(imgui.GetCursorScreenPos())
    local lh = (imgui.GetTextLineHeight ~= nil) and imgui.GetTextLineHeight() or 14
    if (x ~= nil) and (y ~= nil) then
        imgui.GetWindowDrawList():AddCircle({ x + dx, y + lh / 2 }, 5.5, imgui.GetColorU32(col), 16, 1.5)
    end
end
local SLOT_OF = { 'Main', 'Sub', 'Range', 'Ammo', 'Head', 'Body', 'Hands', 'Legs', 'Feet', 'Neck', 'Waist', 'Ear1',
    'Ear2', 'Ring1', 'Ring2', 'Back' } -- LAC's slot numbers (gcaction's records)
-- On you now (over the list): the sets wearing something on you, the most slots first, from gcaction's record of
-- each slot's last swap (GcWornBy); a click opens one. The loaded job only. Its rows get a green dot.
local function draw_now()
    editorState.cache.nowSets = nil
    if editorState.document.inactive or (type(GcWornBy) ~= 'table') then return end
    local N = editorState.cache.nowSetsKept
    local stamp = (type(GcRecords) == 'table') and GcRecords.n or 0
    if (N == nil) or (N.stamp ~= stamp) or (N.rev ~= editorState.document.revision) then
        N = { stamp = stamp, rev = editorState.document.revision, list = {}, by = {} }
        for slot = 1, 16 do
            local w = GcWornBy[slot]
            local by = (w ~= nil) and w.by or nil
            local hit = (type(by) == 'string') and editorState.document.model.byLower[string.lower(by)] or nil
            if hit ~= nil then
                local e = N.by[hit.name]
                if e == nil then
                    e = { name = hit.name, n = 0, slots = {} }
                    N.by[hit.name], N.list[#N.list + 1] = e, e
                end
                e.n, e.slots[#e.slots + 1] = e.n + 1, SLOT_OF[slot]
            end
        end
        table.sort(N.list, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.name < b.name end)
        editorState.cache.nowSetsKept = N
    end
    editorState.cache.nowSets = N
    if #N.list == 0 then return end
    imgui.TextColored(palette.dim, 'On you now:')
    for _, e in ipairs(N.list) do
        e.label = e.label or (e.name .. ' ' .. e.n .. '##gcnow')
        editorPanels.SameLineIfFits(imgui, text_w(e.name .. ' ' .. e.n) + 16)
        imgui.PushStyleColor(ImGuiCol_Button, palette.okBg)
        imgui.PushStyleColor(ImGuiCol_Text, palette.ok)
        if imgui.SmallButton(e.label) then go_to(e.name) end
        imgui.PopStyleColor(2)
        if imgui.IsItemHovered() then
            set_tip(e.name .. ': ' .. e.n .. ' of your 16 slots right now (' .. table.concat(e.slots, ' ') .. ').')
        end
    end
end
-- The RP line (over the list): the pieces your sets name that need RP, and in how many sets; a click shows only
-- those sets (Needs RP). Worked out once per edit.
local function draw_rp_line()
    local R = editorState.cache.rpLine
    if (R == nil) or (R.rev ~= editorState.document.revision) then
        R = { rev = editorState.document.revision, pieces = {}, sets = 0 }
        local seen = {}
        for _, set in ipairs(editorState.document.model.list) do
            local st = set_status(set)
            if #st.unfinished > 0 then
                R.sets = R.sets + 1
                for _, u in ipairs(st.unfinished) do
                    local piece = string.gsub(string.match(u, '^[^:]+: (.+)$') or u, '%(NEEDS RP%s*', '(')
                    if not seen[piece] then
                        seen[piece] = true
                        R.pieces[#R.pieces + 1] = piece
                    end
                end
            end
        end
        -- one line over the list (the pieces on hover): a list of them here pushed the sets down on every set
        R.text = (#R.pieces == 1 and '1 piece needs RP' or (#R.pieces .. ' pieces need RP')) .. ' (' .. R.sets
            .. ((R.sets == 1) and ' set)' or ' sets)')
        R.tip = table.concat(R.pieces, '\n') .. '\n\nClick: only the sets using them (Needs RP), again: all.'
        editorState.cache.rpLine = R
    end
    if #R.pieces == 0 then return end
    dot(4, palette.rp)
    imgui.Dummy({ 9, 1 })
    imgui.SameLine(0, 2)
    imgui.TextColored(palette.rp, R.text)
    if imgui.IsItemHovered() then set_tip(R.tip) end
    if imgui.IsItemClicked(0) then editorState.ui.needsRpOnly[1] = not editorState.ui.needsRpOnly[1] end
end

-- A filter as a chip: lit while on; a click turns it on or off.
local CLEAR = { 0, 0, 0, 0 }
-- A filter as an outlined chip: round, its outline only until it is on.
local function chip(label, value, col)
    local on = value[1] == true
    local vars = 0
    for _, sv in ipairs({ { ImGuiStyleVar_FrameRounding, 9 }, { ImGuiStyleVar_FrameBorderSize, 1 } }) do
        if (sv[1] ~= nil) and (imgui.PushStyleVar ~= nil) then
            imgui.PushStyleVar(sv[1], sv[2])
            vars = vars + 1
        end
    end
    imgui.PushStyleColor(ImGuiCol_Button, on and palette.selBg or CLEAR)
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, on and palette.save or palette.btnHi)
    imgui.PushStyleColor(ImGuiCol_Text, on and palette.blue or (col or palette.dim))
    imgui.PushStyleColor(ImGuiCol_Border, on and palette.sel or palette.edge)
    if imgui.SmallButton(label) then value[1] = not on end
    imgui.PopStyleColor(4)
    if vars > 0 then imgui.PopStyleVar(vars) end
end
-- The sets a job file usually has (the engine's, the job's example's, /wm layers) and the job abilities and weapon
-- skills you know (no spells: too many), that this one lacks, by the heading each would go under; worked out again
-- when the file or its edits change.
-- Engine sets for one fight or one state (Aminon, asleep, doomed...), listed under More: few job files have them.
local RARE = { aminon = true, incapacitated = true, sleeping = true, doomed = true, sir = true, proc = true,
    ws_proc = true, lightbonus = true }
local function RARE_SET(name)
    local l = string.lower(name)
    return RARE[l] or (string.match(l, '^hoxne_') ~= nil)
end
local function addable()
    local c = editorState.cache
    local looked = (ctx.actions ~= nil) and ctx.actions.LookedFor() or NONE -- names an action looked for, made after
    if (c.addRev == editorState.document.revision) and (c.addLooked == looked) and (c.addable ~= nil) then
        return c.addable
    end
    -- rank: 1 the sets most job files have (the engine's usual ones, the example's, an /mset or /wm mode's, the
    -- ability groups), 2 the abilities and weapon skills you know, 3 under More: the one-fight / one-state ones (RARE)
    -- and the abilities an ability group's set covers (Curing Waltz III: Waltz)
    local out, list, seen = {}, {}, {}
    for _, x in ipairs(looked) do list[#list + 1] = { name = x.name, why = x.why } end
    local kinds = NONE -- the ability groups the job file wears by name (['Step'] on every step)
    if ctx.ability_kinds ~= nil then kinds = select(2, ctx.ability_kinds()) or NONE end
    for _, m in ipairs((ctx.melee_modes ~= nil) and ctx.melee_modes() or {}) do -- an /mset mode with no Tp_ set
        local name = 'Tp_' .. m
        if (string.lower(m) ~= 'default') and (editorState.document.model.byLower[string.lower(name)] == nil) then
            list[#list + 1] = { name = name, why = '/mset ' .. string.lower(m) .. ' (fighting stays Default without it)' }
        end
    end
    for _, k in ipairs(kinds) do
        if editorState.document.model.byLower[string.lower(k)] == nil then
            list[#list + 1] = { name = k, why = 'every ability with ' .. k .. ' in its name',
                tip = 'Your job file\'s HandleAbility puts on a set named ' .. k .. ' for every ability with ' .. k
                    .. ' in its name, then the ability\'s own set over it. Make it once for all of them.' }
        end
    end
    local ok, sugg = pcall(suggestions, false, true)
    if not ok then ok, sugg = pcall(suggestions, true) end -- the abilities couldn't be read: the standard sets still
    for _, x in ipairs(ok and sugg or {}) do list[#list + 1] = x end
    -- a set for while your own JA's buff is up (Buffs['Saber Dance']), when the game has a buff by its name and the
    -- file has Buffs to put it in: the engine wears it idle and engaged
    -- and Buffs_Ws / Buffs_Midcast ones (its weapon skills / spells while it is up), for each of those the file has
    local model = editorState.document.model
    for _, x in ipairs(((ctx.rules ~= nil) and (ctx.rules.IsBuff ~= nil) and ok) and sugg or NONE) do
        if (x.why == 'job ability') and ctx.rules.IsBuff(x.name) and not string.find(x.name, "'", 1, true) then
            for _, b in ipairs({ { 'Buffs', 'idle and engaged' }, { 'Buffs_Ws', 'weapon skills' },
                { 'Buffs_Midcast', 'spells' } }) do
                local parent, child = model.byName[b[1]], b[1] .. "['" .. x.name .. "']"
                if (parent ~= nil) and (parent.parentName == nil) and (model.byLower[string.lower(child)] == nil) then
                    list[#list + 1] = { name = child, parent = b[1], key = x.name, group = 'Buffs',
                        why = 'while ' .. x.name .. ' is up (' .. b[2] .. ')' }
                end
            end
        end
    end
    local ignored = (ctx.ignored_names ~= nil) and ctx.ignored_names() or NONE -- settings.EditorIgnoreSuggestions
    local ruled = {} -- moments a rule (on, not off) can put gear on at: 'no change' isn't sure there
    for _, r in ipairs(((ctx.rules ~= nil) and ctx.rules.List()) or NONE) do
        if (type(r) == 'table') and not r.off and (r.on ~= nil) then ruled[r.on] = true end
    end
    for _, x in ipairs(list) do
        local g = x.group or ((ctx.group_of ~= nil) and ctx.group_of(x.name)) or nil
        if (g ~= nil) and not seen[string.lower(x.name)] and not ignored[string.lower(x.name)] then
            seen[string.lower(x.name)] = true
            x.rank = ((x.why == 'job ability') or (x.why == 'weapon skill')) and 2 or (RARE_SET(x.name) and 3 or 1)
            -- an action: what it wears until this set is made (now: a set's name, false: no gear change)
            local by = editorState.document.model.byLower
            if x.why == 'weapon skill' then x.now = (by['ws_default'] ~= nil) and 'Ws_Default' or false end
            local moment = (x.why == 'weapon skill') and 'Weaponskill' or 'Ability'
            if x.why == 'job ability' then
                x.now = false -- no base set for job abilities: only one by its name, or its group's
                for _, k in ipairs(kinds) do
                    if (x.name ~= k) and string.find(x.name, k, 1, true) then
                        local made = by[string.lower(k)] ~= nil
                        x.rank, x.why = 3, made and ('your ' .. k .. ' set covers it') or (k .. ' would cover it')
                        x.now = made and k or false
                        break
                    end
                end
            end
            if (x.now == false) and ruled[moment] then x.ruled = true end
            out[g] = out[g] or {}
            out[g][#out[g] + 1] = x
        end
    end
    for _, l in pairs(out) do -- by rank, else as listed
        for i, x in ipairs(l) do x.at = i end
        table.sort(l, function(a, b) if a.rank ~= b.rank then return a.rank < b.rank end return a.at < b.at end)
        local main = 0
        for _, x in ipairs(l) do if x.rank < 3 then main = main + 1 end end
        l.main = main
    end
    c.addRev, c.addLooked, c.addable = editorState.document.revision, looked, out
    return out
end
-- Make from the add list: the set (a Buffs['X'] one inside Buffs), opened on its first slot to fill (Main for a
-- Weapon_ set, else Head) on the Gear tab; from: then Copy from... picks a set to start it as.
local function make_listed(s, from)
    local model = editorState.document.model
    local parent = (s.parent ~= nil) and model.byName[s.parent] or nil
    make_set(s.name, nil, false, parent, s.key)
    go_to(s.name, string.match(s.name, '^[Ww]eapon_') and 'Main' or 'Head', 'gear')
    if from then
        editorState.ui.copyFind[1], editorState.ui.pickMode = '', 'copy'
        editorState.ui.openSetChooser = true
    end
    editorState.ui.addTo = nil
    imgui.CloseCurrentPopup()
end
-- When a listed set goes on, for its hover (the Used for sentence); false: nothing by its name wears it.
local function when_of(s)
    if (s.when == nil) and (ctx.actions ~= nil) and (ctx.actions.When ~= nil) then
        local ok, text = pcall(ctx.actions.When, { name = s.name, lname = string.lower(s.name), parentName = s.parent,
            key = s.key })
        s.when = (ok and (type(text) == 'string') and (string.find(text, '^No built%-in trigger') == nil)) and text
            or false
    end
    return s.when or nil
end
-- + New set (every heading) or a heading's + N to add (that heading): the sets you could make, what each is for
-- (hover: when it goes on), Make (empty) or from... (a copy of a set you pick), made and opened on its first slot;
-- typing filters the list or names your own (Weapon_<name>: a new /wm mode). Unsaved until Save.
local function draw_addable()
    local a = editorState.ui.addTo
    if a == nil then return end
    if a.open then
        a.open = nil
        imgui.OpenPopup('##gcedit_addable')
    end
    if not imgui.BeginPopup('##gcedit_addable') then return end
    local model = editorState.document.model
    imgui.TextColored(palette.section, (a.g ~= nil) and ('Add to ' .. tostring(a.head)) or 'New set')
    imgui.PushItemWidth(320)
    imgui.InputTextWithHint('##gcadd_custom', 'Filter, or a name of your own: Cure IV, Idle_Pdt',
        editorState.ui.addCustom, 64)
    imgui.PopItemWidth()
    local name = string.gsub(editorState.ui.addCustom[1] or '', '^%s*(.-)%s*$', '%1')
    local lname = string.lower(name)
    local all, rows, listed = addable(), {}, false
    for _, g in ipairs((a.g ~= nil) and { a.g } or ctx.headings.order()) do
        local more, head = false, (a.g ~= nil)
        for _, s in ipairs(all[g] or NONE) do
            local ls = string.lower(s.name)
            if ls == lname then listed = true end
            if (lname == '') or (string.find(ls, lname, 1, true) ~= nil) then
                if not head then
                    head = true
                    rows[#rows + 1] = { g = g }
                end
                if ((s.rank or 1) >= 3) and not more and (lname == '') then
                    more = true -- still made from here (a set of its own for one flourish): each says why it sits lower
                    rows[#rows + 1] = { more = true }
                end
                rows[#rows + 1] = s
            end
        end
    end
    local line = (imgui.GetTextLineHeightWithSpacing ~= nil) and imgui.GetTextLineHeightWithSpacing() or 18
    -- as wide as its widest row (Make, from..., the name, what it is for), up to 720; past that the words wrap
    local btn, wide = text_w('Makefrom...') + 30, 320
    for _, s in ipairs(rows) do
        if (s.name ~= nil) and (s.rowW == nil) then
            s.words = ((ctx.words ~= nil) and ctx.words.Label(s.name)) or s.why or ''
            s.rowW = btn + text_w(s.name) + 8 + text_w(s.words)
                + ((s.now ~= nil) and (12 + text_w('now: ' .. (s.now or 'no change, rules aside'))) or 0)
        end
        wide = math.max(wide, s.rowW or 0)
    end
    wide = math.min(wide + ((#rows > 16) and 20 or 4), 720)
    if #rows > 0 then
        imgui.BeginChild('##gcadd_scroll', { wide, math.min(#rows, 16) * line + 6 }, 0)
        imgui.PushTextWrapPos(0)
    end
    for i, s in ipairs(rows) do
        if s.g ~= nil then
            imgui.TextColored(palette.section, string.upper((string.gsub(s.g, ' %(by name%)', ''))))
        elseif s.more then
            imgui.TextColored(palette.dim, 'More:')
        else
            if imgui.SmallButton('Make##gcadd_mk' .. i) then make_listed(s) end
            imgui.SameLine(0, 2)
            if imgui.SmallButton('from...##gcadd_from' .. i) then make_listed(s, true) end
            if imgui.IsItemHovered() then set_tip('Make it as a copy of a set you pick (then change what differs).') end
            imgui.SameLine()
            imgui.TextUnformatted(s.name)
            if s.words ~= '' then
                imgui.SameLine(0, 8)
                imgui.TextColored(palette.dim, s.words)
            end
            local tip = s.tip or when_of(s)
            if imgui.IsItemHovered() and (tip ~= nil) then set_tip(tip) end
            if s.now ~= nil then -- what the action wears until this set is made
                imgui.SameLine(0, 12)
                imgui.TextColored(palette.dim, 'now:')
                imgui.SameLine(0, 4)
                imgui.TextColored(s.now and palette.blue or palette.warn,
                    s.now or (s.ruled and 'no change, rules aside' or 'no change'))
                if imgui.IsItemHovered() then
                    set_tip(s.now and ('Until you make ' .. s.name .. ', it wears ' .. s.now .. '.')
                        or ('Until you make ' .. s.name .. ', it changes no gear: you keep what you have on'
                            .. (s.ruled and ', except what a rule of yours puts on for it (Rules).' or '.')))
                end
            end
        end
    end
    if #rows > 0 then
        imgui.PopTextWrapPos()
        imgui.EndChild()
    end
    if (#rows == 0) and (name == '') then imgui.TextColored(palette.dim, 'Nothing listed: type a name of your own.') end
    -- the name as typed, when the list doesn't have it: any set (a spell: Cure IV), under the heading its name puts it
    if (name ~= '') and not listed then
        local clash = model.byLower[lname] ~= nil
        local winfo = string.match(name, '^[Ww]eapon_') and (ctx.weapon_set_info ~= nil)
            and ctx.weapon_set_info({ name = name, slots = {}, new = true }) or nil
        if #rows > 0 then imgui.Separator() end
        if clash then
            imgui.TextColored(palette.bad, name .. ' exists (names ignore case).')
        elseif string.find(name, '[\r\n]') then
            imgui.TextColored(palette.bad, 'One line only.')
        elseif (winfo ~= nil) and (winfo.kind ~= 'variant') then -- a /wm mode of its own: its name and weapons there
            if imgui.SmallButton('New /wm mode...##gcadd_wm') then
                editorState.ui.requestNewWm, editorState.ui.addTo = string.match(name, '^[Ww]eapon_(.+)$'), nil
                imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            imgui.TextColored(palette.dim, 'Weapon_ sets are /wm modes.')
        else
            if imgui.SmallButton('Make##gcadd_custom_go') then make_listed({ name = name }) end
            imgui.SameLine(0, 2)
            if imgui.SmallButton('from...##gcadd_custom_from') then make_listed({ name = name }, true) end
            imgui.SameLine()
            imgui.TextUnformatted(name)
            local nw = editorState.ui.addWhen
            if (nw == nil) or (nw.name ~= name) or (nw.rev ~= editorState.document.revision) then
                nw = { name = name, rev = editorState.document.revision }
                when_of(nw)
                editorState.ui.addWhen = nw
            end
            imgui.PushTextWrapPos(wide)
            if nw.when then
                imgui.TextColored(palette.blue, (string.match(nw.when, '^(.-%.)%s+%u') or nw.when))
            else
                imgui.TextColored(palette.warn, 'Nothing wears a set by this name: only code in your job file could.')
            end
            imgui.PopTextWrapPos()
        end
    end
    imgui.EndPopup()
end
local function draw_sets()
    if ctx.rules ~= nil then ctx.rules.ListButton() end -- RULES: the job file's gcinclude.Rules
    if imgui.Button('+ New set##gcedit') then
        editorState.ui.addTo, editorState.ui.addCustom[1] = { open = true }, ''
    end
    imgui.SameLine()
    imgui.PushItemWidth(-1)
    imgui.InputTextWithHint('##gcedit_find', 'Idle, Nyame...', editorState.ui.find, 48)
    imgui.PopItemWidth()
    if imgui.IsItemHovered() then set_tip('A set\'s name, or an item: every set that wears it (as edited).') end
    local unsaved = unsaved_set_count()
    if unsaved > 0 or editorState.ui.editedOnly[1] then
        chip('Unsaved ' .. unsaved .. '##set_unsaved', editorState.ui.editedOnly, palette.warn)
        if imgui.IsItemHovered() then set_tip('Only sets with unsaved slot edits, new definitions, or deletions.') end
    end
    editorState.ui.unusedOnly = editorState.ui.unusedOnly or { false }
    for index, filter in ipairs({
        { 'Issues', editorState.ui.issuesOnly },
        { 'Missing', editorState.ui.missingOnly },
        { 'Needs RP', editorState.ui.needsRpOnly },
        { 'Unused', editorState.ui.unusedOnly },
    }) do
        if index > 1 then editorPanels.SameLineIfFits(imgui, 80) end
        chip(filter[1] .. '##set_filter', filter[2], (filter[1] == 'Needs RP') and palette.rp or nil)
        if imgui.IsItemHovered() then
            local descriptions = {
                Issues = 'Sets with empty slots, missing gear, or unfinished RP.',
                Missing = 'Sets naming gear you do not own.',
                ['Needs RP'] = 'Sets using gear below its decoded rank cap.',
                Unused = 'Sets nothing seems to look for: no built-in trigger by name, not named in your job file, '
                    .. 'not a variant of another set. Check before you delete.',
            }
            set_tip(descriptions[filter[1]])
        end
    end
    local ui = editorState.ui
    ui.showHidden = ui.showHidden or { false }
    local hiddenPref, jobNow = ctx.headings.pref('EditorHidden'), ctx.headings.job()
    if editorState.cache.anyHidden or ui.showHidden[1] then -- a heading is hidden on this job
        editorPanels.SameLineIfFits(imgui, 120)
        chip('Show hidden##set_hidden', ui.showHidden)
        if imgui.IsItemHovered() then set_tip('Headings you hid (right-click a heading) show again, marked hidden.') end
    end
    editorPanels.SameLineIfFits(imgui, 30)
    color_key()
    if ui.issuesOnly[1] or ui.editedOnly[1] or ui.missingOnly[1] or ui.needsRpOnly[1] or ui.unusedOnly[1]
        or ui.find[1] ~= '' then
        if imgui.SmallButton('Reset filters##set_filters') then
            ui.issuesOnly[1], ui.editedOnly[1], ui.missingOnly[1], ui.needsRpOnly[1] = false, false, false, false
            ui.unusedOnly[1], ui.find[1] = false, ''
        end
        if ui.unusedOnly[1] then
            imgui.SameLine()
            draw_unused_delete()
        end
    end
    draw_now() -- On you now: the sets wearing something on you
    draw_rp_line() -- the pieces that need RP, in one line
    local find = string.lower(editorState.ui.find[1] or '')
    -- the groups' rows, rebuilt only when the filter or the set list changes
    local key = find
        .. '\0'
        .. editorState.document.revision
        .. tostring(ui.issuesOnly[1])
        .. tostring(ui.editedOnly[1])
        .. tostring(ui.missingOnly[1])
        .. tostring(ui.needsRpOnly[1])
        .. ':' .. tostring(ui.showHidden[1]) .. tostring(ui.unusedOnly[1])
    if editorState.cache.listKey ~= key then
        local buckets = {}
        for _, set in ipairs(editorState.document.model.list) do
            if matches_set(set, find) then
                buckets[set.group] = buckets[set.group] or {}
                table.insert(buckets[set.group], set)
            end
        end
        editorState.cache.listKey, editorState.cache.listRows = key, {}
        -- settings.EditorGroups' order; a heading of your own shows even with no set under it (to move sets in)
        local lib = ctx.headings.lib
        editorState.cache.anyHidden = false
        for _, g in ipairs(ctx.headings.order()) do
            local rows = buckets[g]
            local filtering = ui.issuesOnly[1] or ui.editedOnly[1] or ui.missingOnly[1] or ui.needsRpOnly[1]
                or ui.unusedOnly[1]
            -- JOB ABILITIES / NAMED WEAPON SKILLS show before your first set there, to add one (others need a set first:
            -- an empty HOXNE on every job would be noise)
            local actionHeading = (g == 'Job abilities') or (g == 'Named weapon skills')
            if (rows == nil) and (find == '')
                and (lib.IsCustom(g, GROUPS) or ((not filtering) and actionHeading and (addable()[g] ~= nil))) then
                rows = {}
            end
            -- WEAPONS shows with no Weapon_ set too: how this file picks weapons, and how to add a /wm mode
            local hint = nil
            if (g == 'Weapons') and (find == '') and not filtering then
                rows = rows or {}
                hint = { empty = (#rows == 0), picks = ctx.weapon_picks(), problems = ctx.weapon_problems() }
            elseif (g == 'Melee') and (find == '') and not filtering and (ctx.melee_modes ~= nil) then
                -- MELEE shows the /mset modes and how to add one, a set under it or not
                rows = rows or {}
                local names = {}
                for _, m in ipairs(ctx.melee_modes()) do names[#names + 1] = (m == 'Default') and 'Base' or m end
                hint = { mset = names, picks = {}, problems = {} }
            end
            local isHidden = lib.IsHidden(hiddenPref, g, jobNow)
            if isHidden and (rows ~= nil) then editorState.cache.anyHidden = true end
            if isHidden and (find == '') and not ui.showHidden[1] then rows = nil end
            if rows ~= nil then
                rows = ctx.headings.sorted(rows, g)
                editorState.cache.listRows[#editorState.cache.listRows + 1] = {
                    g = g,
                    head = string.upper((string.gsub(g, ' %(by name%)', ''))) .. (isHidden and ' (hidden)' or ''),
                    n = tostring(#rows),
                    rows = rows,
                    hint = hint,
                }
            end -- '(by name)' left off: it fits
        end
    end
    -- the set was picked elsewhere (a have link, /gcedit <set>): scroll the list to it once
    local scroll = (editorState.cache.listSel ~= editorState.selection.setName)
    editorState.cache.listSel = editorState.selection.setName
    imgui.BeginChild('##gcedit_setlist', { 0, 0 }, 0)
    if #editorState.cache.listRows == 0 then imgui.TextColored(palette.dim, 'No set matches.') end
    local clip = clip_begin()
    for _, grp in ipairs(editorState.cache.listRows) do
        -- a group folds on a click of its heading; a search shows every match, and the open set's group opens
        if scroll and (editorState.ui.fold[grp.g] == true) then
            for _, set in ipairs(grp.rows) do
                if set.name == editorState.selection.setName then
                    editorState.ui.fold[grp.g] = false
                    break
                end
            end
        end
        local folded = (find == '') and not ui.editedOnly[1] and (editorState.ui.fold[grp.g] == true)
        if not clip_skip(clip, grp) then
            imgui.Spacing()
            imgui.PushStyleColor(ImGuiCol_Text, palette.section)
            local x0 = (imgui.GetCursorPosX ~= nil) and imgui.GetCursorPosX() or nil
            local arrowW = text_w('- ') -- what the fold marker takes before the heading's name
            if (imgui.TreeNodeEx ~= nil) and (imgui.SetNextItemOpen ~= nil) then
                -- the same arrow as the panels' section headers; the fold is ours, set every frame
                grp.label = grp.label or (grp.head .. '##gcg_' .. grp.g)
                imgui.SetNextItemOpen(not folded, ImGuiCond_Always or 1)
                local open = imgui.TreeNodeEx(grp.label, bit.bor(ImGuiTreeNodeFlags_SpanAvailWidth or 0,
                    ImGuiTreeNodeFlags_AllowOverlap or 0, -- the + /mset mode, + /wm mode buttons
                    ImGuiTreeNodeFlags_NoTreePushOnOpen or 0))
                if (open == folded) and (find == '') then -- clicked: it turned
                    editorState.ui.fold[grp.g] = not open
                end
                local pad = editorPanels.Density(ctx.spacing()).padding[1]
                arrowW = ((imgui.GetFontSize ~= nil) and imgui.GetFontSize() or 16) + 2 * pad
            else
                grp.labels = grp.labels
                    or { ['- '] = '- ' .. grp.head .. '##gcg_' .. grp.g, ['+ '] = '+ ' .. grp.head .. '##gcg_' .. grp.g, }
                if imgui.Selectable(grp.labels[folded and '+ ' or '- '], false) and (find == '') then
                    editorState.ui.fold[grp.g] = not folded
                end
            end
            drop_set_here(grp.g, nil)
            if imgui.IsItemClicked(1) then editorState.ui.headingMenu, editorState.ui.openHeadingMenu = grp.g, true end
            if imgui.IsItemHovered() then
                set_tip('Click: fold. Right-click: move, hide, sort, add or rename headings. Drop a set here to move it.')
            end
            imgui.PopStyleColor(1)
            if x0 ~= nil then
                imgui.SameLine(x0 + arrowW + text_w(grp.head) + 12)
                pill(grp.n, palette.dim, palette.chipBg)
            end
            if (grp.hint ~= nil) then -- MELEE / WEAPONS: + /mset mode, + /wm mode at the heading's right end
                local pad = editorPanels.Density(ctx.spacing()).padding[1]
                local label = (grp.hint.mset ~= nil) and '+ /mset mode' or '+ /wm mode'
                local bw = text_w(label) + 2 * pad
                imgui.SameLine()
                local avail = (imgui.GetContentRegionAvail ~= nil) and ctx.xy(imgui.GetContentRegionAvail()) or nil
                if (avail ~= nil) and (avail > bw) and (imgui.SetCursorPosX ~= nil)
                    and (imgui.GetCursorPosX ~= nil) then
                    imgui.SetCursorPosX(imgui.GetCursorPosX() + avail - bw)
                end
                if imgui.SmallButton(label .. '##gch_' .. grp.g) then
                    if (grp.hint.mset ~= nil) then editorState.ui.requestNewMset = true
                    else editorState.ui.requestNewWm = true end
                end
                if imgui.IsItemHovered() then
                    set_tip((grp.hint.mset ~= nil)
                        and ('A /mset mode of your own (Hybrid, MidAcc...): /mset <name> then wears <set>_<name> '
                            .. "(Tp_, Ws_, a weapon skill's) over its base. Name it, tick the sets to make, Add; "
                            .. 'Save writes it.')
                        or ('A /wm mode: New set Weapon_<Name> with Main and Sub. /wm <name> puts them on, and its '
                            .. 'items become /mw /sw picks too. Save adds it to gcinclude.WeaponModes.'))
                end
            end
            if (grp.hint ~= nil) and not folded then -- MELEE: its modes; WEAPONS: what is wrong, the picks with no set
                imgui.Indent(arrowW)
                imgui.PushTextWrapPos(0)
                for _, p in ipairs(grp.hint.problems) do imgui.TextColored(palette.warn, p) end
                if grp.hint.empty then
                    for _, p in ipairs(grp.hint.picks) do
                        imgui.TextColored(palette.dim, p)
                        if imgui.IsItemHovered() then
                            set_tip('The weapons /mw /sw /rw switch between (MainModes, SubModes, RangeModes '
                                .. "in Settings), not what you wear now. A Weapon_ set's Main, Sub and Range are "
                                .. 'picks too.')
                        end
                    end
                end
                imgui.PopTextWrapPos()
                imgui.Unindent(arrowW)
            end
            clip_drawn(clip, grp)
        end
        for _, set in ipairs(folded and NONE or grp.rows) do
            if (not editorState.ui.issuesOnly[1]) or has_issue(set) then
                local on = (editorState.selection.setName == set.name)
                if not clip_skip(clip, set, on and scroll) then -- the set picked elsewhere is drawn, to scroll to it
                    -- its label, redone when an edit or the set list changes (editorState.document.revision)
                    -- a set inside a set under its parent's heading: indented, by its key; moved elsewhere: its name
                    local parent = (set.parentName ~= nil) and editorState.document.model.byName[set.parentName] or nil
                    local nested = (parent ~= nil) and (parent.group == set.group)
                    if (set.rowVer ~= editorState.document.revision) or (set.rowNested ~= nested) then
                        set.rowNested = nested
                        local label = nested and ('    ' .. set.key) or set.name
                        if editorState.document.deleted[set.name] then
                            label = label .. ' (delete)'
                        elseif set.new then
                            label = label .. ' (new)'
                        elseif editorState.document.edits[set.name] ~= nil then
                            label = label .. ' (unsaved)'
                        end
                        set.rowLabel, set.rowVer = label .. '##gcs_' .. set.name, editorState.document.revision
                    end
                    local status = set_status(set)
                    local col = set_color(set, status)
                    local nowSets = editorState.cache.nowSets
                    -- its state as a dot before the name (the name stays plain text); a ring: on you now
                    dot(-8, col or palette.edge)
                    if (nowSets ~= nil) and (nowSets.by[set.name] ~= nil) then ring(-8, palette.ok) end
                    local gone = editorState.document.deleted[set.name]
                    if gone then imgui.PushStyleColor(ImGuiCol_Text, palette.bad) end
                    local picked = imgui.Selectable(set.rowLabel, on)
                    if gone then imgui.PopStyleColor(1) end
                    if picked then
                        editorState.cache.listSel, editorState.selection.back = set.name, nil
                        editorPreferences.Select(editorState, set.name)
                    end
                    if imgui.IsItemClicked(1) then request_context('set', set) end
                    if imgui.IsItemHovered() and (editorState.ui.dragSet == nil) then
                        local rc = (grp.hint ~= nil) and row_cmd(set) or nil
                        local done = set_completion_tip(set, status)
                        local plain = (ctx.words ~= nil) and ctx.words.Label(set.name) or nil -- what it is for, in words
                        if plain ~= nil then done = plain .. '\n\n' .. done end
                        local tip = ((rc ~= nil) and (rc.tip ~= nil)) and (rc.tip .. '\n\n' .. done) or done
                        if ctx.set_peek ~= nil then ctx.set_peek(set, tip) else set_tip(tip) end -- its gear too
                    end
                    drag_set_from(set)
                    drop_set_here(grp.g, (not nested) and set or nil) -- under its parent: in file order
                    if on then left_bar(palette.sel) end
                    if on and scroll and (imgui.SetScrollHereY ~= nil) then imgui.SetScrollHereY(0.5) end
                    -- issues as numbers: (empty slots, not owned), each coloured; hover a number for what it counts
                    local gaps = empty_armor(set)
                    if set.code ~= nil then
                        imgui.SameLine(0, 10)
                        pill('code', palette.dim, palette.chipBg)
                    elseif (set.count == 0) and (editorState.document.edits[set.name] == nil) and (gaps == nil) then
                        imgui.SameLine(0, 10)
                        pill('empty', palette.dim, palette.chipBg)
                    end
                    local nGap = ((gaps ~= nil) and (#gaps > 0)) and #gaps or nil
                    local no = not_owned(set)
                    local cmd = (grp.hint ~= nil) and row_cmd(set) or nil
                    if (nGap ~= nil) or (no ~= nil) then
                        local function part(text, color, tip, bg) -- a small pill per count
                            imgui.SameLine(0, 10)
                            pill(text, color, bg)
                            if (tip ~= nil) and imgui.IsItemHovered() then set_tip(tip) end
                        end
                        if nGap ~= nil then
                            part(
                                tostring(nGap),
                                (set.name == 'Tp_Default') and palette.dim or palette.warn,
                                nGap .. ' empty: ' .. table.concat(gaps, ' ') .. '\n(' .. BASE[set.name] .. ')',
                                (set.name == 'Tp_Default') and palette.chipBg or palette.warnBg
                            )
                        end
                        if no ~= nil then
                            part(
                                tostring(#no),
                                palette.bad, #no .. ' not owned (that slot does nothing):\n' .. table.concat(no, '\n'),
                                palette.badBg
                            )
                        end
                    end
                    if #status.unfinished > 0 then -- a piece in it needs RP: a small dot, the pieces on hover
                        imgui.SameLine(0, 6)
                        dot(3, palette.rp)
                        imgui.Dummy({ 7, 1 })
                        if imgui.IsItemHovered() then
                            set_tip('Needs RP:\n' .. string.gsub(table.concat(status.unfinished, '\n'), '%(NEEDS RP%s*',
                                '('))
                        end
                    end
                    local nSlots = ((set.code == nil) and (set.count or 0) > 0) and status.armor ~= nil
                        and ((status.armor or 0) + (status.weapons or 0)) or nil
                    if ((cmd == nil) or (cmd.text == nil)) and (nSlots ~= nil) then -- its slot count, at the right end
                        local t = tostring(nSlots)
                        imgui.SameLine()
                        local avail = (imgui.GetContentRegionAvail ~= nil)
                            and ctx.xy(imgui.GetContentRegionAvail()) or nil
                        if (avail ~= nil) and (avail > text_w(t) + 4) and (imgui.SetCursorPosX ~= nil)
                            and (imgui.GetCursorPosX ~= nil) then
                            imgui.SetCursorPosX(imgui.GetCursorPosX() + avail - text_w(t) - 4)
                            imgui.TextColored(palette.dim, t)
                            if imgui.IsItemHovered() then set_tip(t .. ' of 16 slots name gear in ' .. set.name .. '.') end
                        else
                            imgui.NewLine()
                        end
                    end
                    if (cmd ~= nil) and (cmd.text ~= nil) then -- what puts it on, at the row's right end
                        imgui.SameLine()
                        local avail = (imgui.GetContentRegionAvail ~= nil)
                            and ctx.xy(imgui.GetContentRegionAvail()) or nil
                        local shown = nil -- cut with '...' to the room left; kept until that or the command changes
                        if (avail ~= nil) and (imgui.SetCursorPosX ~= nil) and (imgui.GetCursorPosX ~= nil) then
                            if (set.cmdRoom ~= avail) or (set.cmdFor ~= cmd.text) then
                                set.cmdRoom, set.cmdFor, set.cmdShown = avail, cmd.text, fit_cmd(cmd.text, avail - 8)
                            end
                            shown = set.cmdShown
                        end
                        if shown ~= nil then
                            imgui.SetCursorPosX(imgui.GetCursorPosX() + avail - text_w(shown))
                            imgui.TextColored(palette.dim, shown)
                            if (cmd.tip ~= nil) and imgui.IsItemHovered() then set_tip(cmd.tip) end
                        else
                            imgui.NewLine() -- no room even cut: the hover over the name says it
                        end
                    end
                    clip_drawn(clip, set)
                end
            end
        end
        -- the sets a job file usually has, not made yet, under the heading they would go, and a name of your own: one
        -- framed button (like the headings' + /wm mode) a click lists them from. WEAPONS has + /wm mode for that.
        local add = ((not folded) and (find == '') and (grp.g ~= 'Weapons')) and (addable()[grp.g] or NONE) or nil
        grp.addRow = grp.addRow or {}
        if (add ~= nil) and not clip_skip(clip, grp.addRow) then
            local main = add.main or 0 -- the button counts the ones worth a look; More's are inside
            if imgui.SmallButton(((main > 0) and ('+ ' .. main .. ' to add') or '+ add') .. '##gcadd_' .. grp.g) then
                editorState.ui.addTo, editorState.ui.addCustom[1] = { g = grp.g, head = grp.head, open = true }, ''
            end
            if imgui.IsItemHovered() then
                local names = {}
                for i, a in ipairs(add) do if i <= 6 then names[#names + 1] = a.name end end
                set_tip(((#add > 0) and ('Sets this heading usually has that your file doesn\'t: ' .. table.concat(names, ', ')
                    .. ((#add > 6) and ', ...' or '') .. '. ') or '') .. 'Click to make one, or one of your own name.')
            end
            clip_drawn(clip, grp.addRow)
        end
    end
    clip_end(clip)
    draw_heading_menu()
    imgui.EndChild()
    draw_addable()
end

-- Normalize the English resource text once; tooltip layout handles visual wrapping.
local descs = {}
local SJIS = editorData.SJIS
local ELEM_ICON = editorData.ELEM_ICON
    return { go_to = go_to, NONE = NONE, LAC_WORDS = LAC_WORDS, is_slot_word = is_slot_word, clip_begin = clip_begin,
        clip_skip = clip_skip, clip_drawn = clip_drawn, clip_end = clip_end, set_status = set_status, rp_uses = rp_uses,
        draw_sets = draw_sets, descs = descs, SJIS = SJIS, ELEM_ICON = ELEM_ICON }
end
