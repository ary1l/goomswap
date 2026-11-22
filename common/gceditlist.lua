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
end

local function draw_new_popup()
    if not imgui.BeginPopup('##gcedit_new') then return end
    editorState.ui.sugg = editorState.ui.sugg or suggestions()
    imgui.TextUnformatted('New set')
    imgui.PushItemWidth(340)
    imgui.InputTextWithHint('##gcedit_newname', 'Name: mdt, Barrage, Cure...', editorState.ui.newName, 64)
    imgui.PopItemWidth()
    local name = string.match(editorState.ui.newName[1] or '', '^%s*(.-)%s*$')
    local lname = string.lower(name)
    local note, bad = ctx.weapon_name_note(name) -- Weapon_...: a new /wm mode, or one mode's own set
    if note ~= nil then
        imgui.PushTextWrapPos(340)
        imgui.TextColored(bad and palette.warn or palette.blue, note)
        imgui.PopTextWrapPos()
    end
    local clash = (editorState.document.model.byLower[lname] ~= nil)
    if (note == nil) and (name ~= '') and not clash and (ctx.actions ~= nil) and (ctx.actions.When ~= nil) then
        -- what wears a set by this name, before it is made: the Used for sentence's first part
        local nw = editorState.ui.newWhen
        if (nw == nil) or (nw.name ~= name) or (nw.rev ~= editorState.document.revision) then
            local proper = name -- as the game spells it (a suggestion picked or typed in any case)
            for _, sg in ipairs(editorState.ui.sugg) do
                if sg.lname == lname then proper = sg.name break end
            end
            local ok, text = pcall(ctx.actions.When, { name = proper, lname = lname })
            nw = { name = name, rev = editorState.document.revision }
            if ok and (type(text) == 'string') and (string.find(text, '^No built%-in trigger') == nil) then
                text = string.match(text, '^(.-%.)%s+%u') or text -- its first sentence
                nw.text = 'Worn: ' .. string.lower(string.sub(text, 1, 1)) .. string.sub(text, 2)
            end
            editorState.ui.newWhen = nw
        end
        imgui.PushTextWrapPos(340)
        if nw.text ~= nil then
            imgui.TextColored(palette.blue, nw.text)
        else
            imgui.TextColored(palette.warn, 'Nothing wears a set by this name: only code in your job file could.')
        end
        imgui.PopTextWrapPos()
    end
    local from = (editorState.selection.setName ~= nil)
            and editorState.document.model.byName[editorState.selection.setName] or nil
    if (from ~= nil) and (from.code == nil) and not from.extra then
        imgui.Checkbox('Copy slots from ' .. from.name .. '##gcedit_copy', editorState.ui.newCopy)
    else
        from = nil
    end
    imgui.TextColored(palette.dim, 'Not in your file yet:')
    imgui.BeginChild('##gcedit_sugg', { 340, 280 }, CHILD_BORDERS)
    local shown = 0
    for i, sg in ipairs(editorState.ui.sugg) do
        if (lname == '') or (string.find(sg.lname, lname, 1, true) ~= nil) then
            shown = shown + 1
            if imgui.Selectable(sg.name .. '##gcsg' .. i, sg.lname == lname) then
                editorState.ui.newName[1] = sg.name
            end
            imgui.SameLine()
            imgui.TextColored(palette.dim, sg.why)
        end
    end
    if shown == 0 then imgui.TextColored(palette.dim, 'No match: Create uses the name as typed.') end
    imgui.EndChild()
    if clash then imgui.TextColored(palette.bad, 'A set with that name exists (names ignore case).') end
    if imgui.Button('Create##gcedit_new') and (name ~= '') and not clash and not string.find(name, '[\r\n]') then
        make_set(name, editorState.ui.newCopy[1] and from or nil)
        editorState.ui.newName[1], editorState.ui.sugg = '', nil
        -- a new /wm mode: offer its weapon sets and layers (reopened from its header's Weapon sets...)
        local made = editorState.document.model.byName[name]
        local wmode = (ctx.weapon_set_mode ~= nil) and ctx.weapon_set_mode(made) or nil
        if wmode ~= nil then editorState.ui.requestWeaponSets = wmode end
        imgui.CloseCurrentPopup()
    end
    imgui.SameLine()
    if imgui.Button('Cancel##gcedit_new') then imgui.CloseCurrentPopup() end
    imgui.EndPopup()
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
    if status.missing > 0 then return palette.bad end
    if #status.unfinished > 0 then return palette.rp end
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
        or ('Partial definition: ' .. status.armor .. '/12 armor/accessory slots name items.\n'
            .. 'Omitted slots keep earlier gear; overlays can be intentionally partial.')
    if status.missing > 0 then detail = detail .. '\n' .. status.missing .. ' named items are not owned.' end
    if #status.unfinished > 0 then detail = detail .. '\n' .. #status.unfinished .. ' items need RP.' end
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
    { 'rp', 'Needs RP.' },
    { 'bad', 'Names gear you do not own (or deleted on Save).' },
    { 'warn', 'Unsaved edits.' },
}
local function color_key()
    imgui.TextColored(palette.dim, '(?)')
    if not imgui.IsItemHovered() then return end
    imgui.PushStyleColor(ImGuiCol_PopupBg, { 0.055, 0.06, 0.08, 1 })
    imgui.BeginTooltip()
    imgui.PushTextWrapPos(440)
    imgui.TextUnformatted('Set colors:')
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
-- A /mset mode with no Tp_ set yet: a grey row, and make to add it (empty).
local function mset_ghosts()
    if (ctx.melee_modes == nil) then return end
    local by = editorState.document.model.byLower
    for _, m in ipairs(ctx.melee_modes()) do
        local name = 'Tp_' .. m
        if (by[string.lower(name)] == nil) and (string.lower(m) ~= 'default') then
            imgui.TextColored(palette.dim, name .. ' no set')
            if imgui.IsItemHovered() then
                set_tip('/mset ' .. string.lower(m) .. ' has no Tp_ set: engaged gear stays as Default. Make adds '
                    .. 'it, empty: fill only what differs.')
            end
            imgui.SameLine()
            if imgui.SmallButton('make##gcm_ghost_' .. m) then make_set(name, nil, true) end
            local t = '/mset ' .. string.lower(m)
            imgui.SameLine()
            local avail = (imgui.GetContentRegionAvail ~= nil) and ctx.xy(imgui.GetContentRegionAvail()) or nil
            if (avail ~= nil) and (avail > text_w(t) + 8) and (imgui.SetCursorPosX ~= nil)
                and (imgui.GetCursorPosX ~= nil) then
                imgui.SetCursorPosX(imgui.GetCursorPosX() + avail - text_w(t))
                imgui.TextColored(palette.dim, t)
            else
                imgui.NewLine()
            end
        end
    end
end

local function draw_sets()
    if imgui.Button('+ New set##gcedit') then
        editorState.ui.sugg = nil
        imgui.OpenPopup('##gcedit_new')
    end
    if editorState.ui.openNewSet ~= nil then -- the WEAPONS heading's + A /wm mode: New set, Weapon_ typed
        editorState.ui.newName[1], editorState.ui.sugg = editorState.ui.openNewSet, nil
        editorState.ui.openNewSet = nil
        imgui.OpenPopup('##gcedit_new')
    end
    draw_new_popup()
    imgui.SameLine()
    imgui.PushItemWidth(-1)
    imgui.InputTextWithHint('##gcedit_find', 'Idle, Nyame...', editorState.ui.find, 48)
    imgui.PopItemWidth()
    if imgui.IsItemHovered() then set_tip('A set\'s name, or an item: every set that wears it (as edited).') end
    local unsaved = unsaved_set_count()
    if unsaved > 0 or editorState.ui.editedOnly[1] then
        imgui.PushStyleColor(ImGuiCol_Text, palette.warn)
        imgui.Checkbox('Unsaved sets (' .. unsaved .. ')##set_unsaved', editorState.ui.editedOnly)
        imgui.PopStyleColor()
        if imgui.IsItemHovered() then set_tip('Only sets with unsaved slot edits, new definitions, or deletions.') end
    end
    editorState.ui.unusedOnly = editorState.ui.unusedOnly or { false }
    for index, filter in ipairs({
        { 'Issues', editorState.ui.issuesOnly },
        { 'Missing', editorState.ui.missingOnly },
        { 'Needs RP', editorState.ui.needsRpOnly },
        { 'Unused', editorState.ui.unusedOnly },
    }) do
        if index > 1 then editorPanels.SameLineIfFits(imgui, 100) end
        if filter[1] == 'Needs RP' then imgui.PushStyleColor(ImGuiCol_Text, palette.rp) end
        imgui.Checkbox(filter[1] .. '##set_filter', filter[2])
        if filter[1] == 'Needs RP' then imgui.PopStyleColor() end
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
        imgui.Checkbox('Show hidden##set_hidden', ui.showHidden)
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
            if (rows == nil) and (find == '') and lib.IsCustom(g, GROUPS) then rows = {} end
            -- WEAPONS shows with no Weapon_ set too: how this file picks weapons, and how to add a /wm mode
            local filtering = ui.issuesOnly[1] or ui.editedOnly[1] or ui.missingOnly[1] or ui.needsRpOnly[1]
                or ui.unusedOnly[1]
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
                    ctx.headings.saveFolds()
                end
                local pad = editorPanels.Density(editorState.preferences.density).padding[1]
                arrowW = ((imgui.GetFontSize ~= nil) and imgui.GetFontSize() or 16) + 2 * pad
            else
                grp.labels = grp.labels
                    or { ['- '] = '- ' .. grp.head .. '##gcg_' .. grp.g, ['+ '] = '+ ' .. grp.head .. '##gcg_' .. grp.g, }
                if imgui.Selectable(grp.labels[folded and '+ ' or '- '], false) and (find == '') then
                    editorState.ui.fold[grp.g] = not folded
                    ctx.headings.saveFolds()
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
                local pad = editorPanels.Density(editorState.preferences.density).padding[1]
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
                    else editorState.ui.openNewSet = 'Weapon_' end
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
        if (grp.hint ~= nil) and (grp.hint.mset ~= nil) and not folded then mset_ghosts() end
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
                    if col ~= nil then imgui.PushStyleColor(ImGuiCol_Text, col) end
                    if imgui.Selectable(set.rowLabel, on) then
                        editorState.cache.listSel, editorState.selection.back = set.name, nil
                        editorPreferences.Select(editorState, set.name)
                    end
                    if imgui.IsItemClicked(1) then request_context('set', set) end
                    if imgui.IsItemHovered() and (editorState.ui.dragSet == nil) then
                        local rc = (grp.hint ~= nil) and row_cmd(set) or nil
                        local done = set_completion_tip(set, status)
                        set_tip(((rc ~= nil) and (rc.tip ~= nil)) and (rc.tip .. '\n\n' .. done) or done)
                    end
                    drag_set_from(set)
                    drop_set_here(grp.g, (not nested) and set or nil) -- under its parent: in file order
                    if col ~= nil then imgui.PopStyleColor(1) end
                    if on then left_bar(palette.sel) end
                    if on and scroll and (imgui.SetScrollHereY ~= nil) then imgui.SetScrollHereY(0.5) end
                    -- issues as numbers: (empty slots, not owned), each coloured; hover a number for what it counts
                    local gaps = empty_armor(set)
                    if set.code ~= nil then
                        tag('code', palette.dim)
                    elseif (set.count == 0) and (editorState.document.edits[set.name] == nil) and (gaps == nil) then
                        tag('empty', palette.dim)
                    end
                    local nGap = ((gaps ~= nil) and (#gaps > 0)) and #gaps or nil
                    local no = not_owned(set)
                    local cmd = (grp.hint ~= nil) and row_cmd(set) or nil
                    if (nGap ~= nil) or (no ~= nil) then
                        local function part(text, color, tip)
                            imgui.SameLine(0, 0)
                            imgui.TextColored(color, text)
                            if (tip ~= nil) and imgui.IsItemHovered() then set_tip(tip) end
                        end
                        imgui.SameLine()
                        imgui.TextColored(palette.dim, '(')
                        if nGap ~= nil then
                            part(
                                tostring(nGap),
                                (set.name == 'Tp_Default') and palette.dim or palette.warn,
                                nGap .. ' empty: ' .. table.concat(gaps, ' ') .. '\n(' .. BASE[set.name] .. ')'
                            )
                        end
                        if no ~= nil then
                            if nGap ~= nil then part(', ', palette.dim) end
                            part(
                                tostring(#no),
                                palette.bad, #no .. ' not owned (that slot does nothing):\n' .. table.concat(no, '\n')
                            )
                        end
                        part(')', palette.dim)
                    end
                    if (cmd ~= nil) and (cmd.text ~= nil) then -- what puts it on, at the row's right end
                        imgui.SameLine()
                        local avail = (imgui.GetContentRegionAvail ~= nil)
                            and ctx.xy(imgui.GetContentRegionAvail()) or nil
                        local w = text_w(cmd.text)
                        if (avail ~= nil) and (avail > w + 8) and (imgui.SetCursorPosX ~= nil) then
                            imgui.SetCursorPosX(imgui.GetCursorPosX() + avail - w)
                            imgui.TextColored(palette.dim, cmd.text)
                            if (cmd.tip ~= nil) and imgui.IsItemHovered() then set_tip(cmd.tip) end
                        else
                            imgui.NewLine() -- no room: the hover over the name says it
                        end
                    end
                    clip_drawn(clip, set)
                end
            end
        end
    end
    clip_end(clip)
    draw_heading_menu()
    imgui.EndChild()
end

-- Normalize the English resource text once; tooltip layout handles visual wrapping.
local descs = {}
local SJIS = editorData.SJIS
local ELEM_ICON = editorData.ELEM_ICON
    return { go_to = go_to, NONE = NONE, LAC_WORDS = LAC_WORDS, is_slot_word = is_slot_word, clip_begin = clip_begin,
        clip_skip = clip_skip, clip_drawn = clip_drawn, clip_end = clip_end, set_status = set_status, rp_uses = rp_uses,
        draw_sets = draw_sets, descs = descs, SJIS = SJIS, ELEM_ICON = ELEM_ICON }
end
