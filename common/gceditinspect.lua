-- /gcedit: item details, inspection, stats and Compare, set actions and melee modes.
return function(
    BASE, CHILD_BORDERS, ELEM_ICON, NONE, SCREEN, SJIS, ago, augmentInfo, by_name, cardText, ctx, current,
    descs, draw_icon, drop_new, edit, editorInspect, editorPanels, editorPreferences, editorState, empty_armor,
    feedback, ghost_of, go_to, help, imgui, is_slot_word, itemTooltip, item_id, make_set, owned_for, palette,
    pending_weapon_mode, pill, profiler, red_button, registration_plan, request_context, rp_uses,
    set_status, set_tip, statModel, tag, text_w, use_worn, where, wrap, xy
)
local BUFF_HOLDERS = { buffs = true, buffs_ws = true, buffs_midcast = true } -- sets the engine reads per buff
local CLEAR = { 0, 0, 0, 0 }
-- A small-caps heading, as in Settings and the set list: dim, upper case.
local function heading(text)
    imgui.TextColored(palette.dim, string.upper(text))
end

local function describe(name)
    local key = string.lower(name)
    if key == "carrier's sash" then
        return 'DEF:5 HP+20\nFire resistance +15  Ice resistance +15\nWind resistance +15  Earth resistance +15\nLightning resistance +15  Water resistance +15\nLight resistance +15  Dark resistance +15'
    end
    if descs[key] ~= nil then return descs[key] or nil end
    descs[key] = false
    local id = item_id(name)
    local ok, r = pcall(function() return AshitaCore:GetResourceManager():GetItemById(id) end)
    if (id ~= nil) and ok and (r ~= nil) and (r.Description ~= nil) and (type(r.Description[1]) == 'string')
        and (r.Description[1] ~= '') then
        -- the game's element icons are two bytes (a high byte, then 0x1F-0x26 in element order): their names instead
        local d = string.gsub(r.Description[1], '[\128-\255]([\31-\38])', function(c)
            return ELEM_ICON[string.byte(c)]
        end)
        -- Shift-JIS two-byte signs ('Store TP'+1～5): the ASCII look-alike; any other pair, then any other byte: '?'
        d = string.gsub(d, '([\129-\159\224-\252])([\64-\252])', function(a, b)
            return SJIS[string.byte(a) * 256 + string.byte(b)] or '?'
        end)
        d = string.gsub(d, '[\128-\255]', '?')
        descs[key] = d
    end
    return descs[key] or nil
end

-- A comparison belongs to the selected set and includes all equipment selectors.
local function cmp_of(set)
    if (editorState.ui.cmp == nil) or (editorState.ui.cmp.set ~= set.name) then return nil end
    return editorState.document.model.byName[editorState.ui.cmp.with]
end
local function item_model(value, owned)
    local bag, accessible = where(value.name)
    return itemTooltip.Model(value, owned, {
        description = describe(value.name),
        bag = bag,
        equippable = bag and accessible,
        rule = is_slot_word(value),
    })
end

local function exact_owned(value)
    local owned, key, ambiguous
    for _, copy in ipairs(editorState.inventory.copiesByName[string.lower(value.name)] or {}) do
        if augmentInfo.Match(value, { copy }) then
            local copyKey = copy.key or tostring(copy)
            if key and key ~= copyKey then ambiguous = true end
            key, owned = copyKey, copy
        end
    end
    return not ambiguous and owned or nil, ambiguous
end

-- The picker's stat changes: what a piece changes against the one in the slot now.
local SHORT_STAT = { ['Damage taken'] = 'DT', ['Physical damage taken'] = 'PDT', ['Magic damage taken'] = 'MDT',
    ['Damage taken II'] = 'DT II', ['Physical damage taken II'] = 'PDT II', ['Magic damage taken II'] = 'MDT II',
    ['Accuracy'] = 'Acc', ['Attack'] = 'Atk', ['Ranged accuracy'] = 'R.Acc', ['Ranged attack'] = 'R.Atk',
    ['Evasion'] = 'Eva', ['Defense'] = 'DEF', ['Magic accuracy'] = 'M.Acc', ['Magic attack bonus'] = 'MAB',
    ['Magic defense bonus'] = 'MDB', ['Magic evasion'] = 'M.Eva', ['Magic damage'] = 'M.Dmg', ['Fast Cast'] = 'FC',
    ['Double Attack'] = 'DA', ['Triple Attack'] = 'TA', ['Weapon skill damage'] = 'WSD', ['Critical hit rate'] = 'Crit',
    ['Spell interruption rate down'] = 'SIRD', ['Dual Wield'] = 'DW', ['Movement speed'] = 'Move' }
local function piece_stats(slot, value, owned)
    local item = item_model(value, owned)
    item.slot = slot
    item.unknownAugments = (owned ~= nil) and (owned.unreadable or (owned.progress and owned.progress.unknown)) or nil
    return statModel.Build({ item })
end
-- The slot's piece now, as stats (nothing there, a slot word or code: no stats).
function ctx.slot_stats(set, slot)
    local v = current(set, slot)
    if (v == nil) or (v.kind ~= 'item') or is_slot_word(v) or (v.name == nil) then return statModel.Build({}) end
    return piece_stats(slot, v, owned_for(set, slot))
end
-- { { text = 'DT -3%', better = true|false|nil, full = 'Damage taken -3%' }, ... } in the stats' own order.
function ctx.piece_delta(slot, g, before)
    local cmp = statModel.Compare(before, piece_stats(slot, g, g))
    local out, pct = {}, {} -- % stats first (DT, Fast Cast, Haste...): the ones a set is usually built for
    for _, r in ipairs(cmp.rows) do
        if r.delta ~= 0 then
            local d = r.direction or 1
            local list = (r.unit == '%') and pct or out
            list[#list + 1] = { text = (SHORT_STAT[r.name] or r.name) .. ' ' .. r.deltaText,
                full = r.name .. ' ' .. r.deltaText .. '  (' .. r.before .. ' > ' .. r.after .. ')',
                better = nil }
            if d ~= 0 then list[#list].better = (d * r.delta) > 0 end -- neutral stats (Enmity): neither
        end
    end
    for i = #pct, 1, -1 do table.insert(out, 1, pct[i]) end
    return out
end

local function inspection_target(set, slot, gear, source)
    if gear then return gear, gear, source end
    local value = current(set, slot)
    if value then return value, owned_for(set, slot) end
    local ghost = ghost_of(set, slot)
    if ghost then
        value = { kind = 'item', name = ghost.name, augs = ghost.augs, path = ghost.path, rank = ghost.rank }
        source = 'Commented out in ' .. set.name
    else
        local view, cache = editorState.cache.view, editorState.cache
        if view and view.set == set.name and view.ver == editorState.document.revision then
            if cache.inspectionView ~= view then
                local _, final = ctx.actions.Layers(view.rec)
                cache.inspectionView, cache.inspectionFinal = view, final
            end
            local layer = cache.inspectionFinal[slot]
            if layer then
                value = { kind = 'item', name = layer.name }
                source = (view.rec.expected and 'Expected result: ' or 'Recorded result: ')
                    .. ctx.actions.SourceLabel(layer.by)
            end
        end
        if not value then
            local stats = cache.statSets
            local preview = stats and stats.revision == editorState.document.revision and stats.loadouts[set.name]
            local inherited = preview and preview.layered and preview.definitions[slot]
            if inherited and inherited.kind == 'item' and not is_slot_word(inherited) then
                return inherited, exact_owned(inherited), 'Inherited from ' .. preview.sources[slot]
            end
        end
    end
    if not value then return end
    local copies = editorState.inventory.copiesByName[string.lower(value.name)] or {}
    local owned = #copies == 1 and copies[1] or nil
    return value, owned, source
end

local function inspect_item(setName, slot, value, owned, source)
    local model = item_model(value, owned)
    model.id = item_id(value.name)
    if not owned and #(editorState.inventory.copiesByName[string.lower(value.name)] or {}) > 1 then
        model.notes[#model.notes + 1] = 'Multiple copies: inspect a picker entry for exact augments.'
    end
    editorInspect.Pin(editorState, setName, slot, model, source)
    feedback('Showing ' .. value.name .. ' below the gear grid.')
end

-- Grid comparisons need resolved definitions; numeric totals remain on demand.
local function stat_cache()
    local cache = editorState.cache.statSets
    local layered = not editorState.ui.statLayers or editorState.ui.statLayers[1]
    if not cache or cache.revision ~= editorState.document.revision
        or cache.layered ~= layered or cache.base ~= editorState.ui.statBase then
        cache = { revision = editorState.document.revision, layered = layered,
            base = editorState.ui.statBase, sets = {}, loadouts = {}, count = 0 }
        editorState.cache.statSets = cache
    end
    return cache
end
local function loadout_for(set)
    local cache = stat_cache()
    if not cache.loadouts[set.name] then
        if cache.count >= 8 then cache.loadouts, cache.sets, cache.count = {}, {}, 0 end
        cache.loadouts[set.name] = ctx.actions.Equipment(set, cache.layered and cache.base or nil, not cache.layered)
        cache.count = cache.count + 1
    end
    return cache.loadouts[set.name]
end
local function set_stats(set)
    local cache = stat_cache()
    if cache.sets[set.name] then return cache.sets[set.name] end
    local started = profiler.Start()
    local equipment = loadout_for(set)
    local items, inherited, ignored = {}, 0, 0
    local coverage = { unchanged = 0, rules = 0, code = 0, pending = equipment.pending }
    for _, slot in ipairs(SCREEN) do
        local value = equipment.definitions[slot]
        if not value then coverage.unchanged = coverage.unchanged + 1
        elseif value.kind == 'code' then coverage.code = coverage.code + 1
        elseif is_slot_word(value) then
            coverage.rules = coverage.rules + 1
            if string.lower(value.name) == 'ignore' then ignored = ignored + 1 end
        elseif value.name then
            local owned, ambiguous = exact_owned(value)
            local item = item_model(value, owned)
            item.slot = slot
            item.unknownAugments = ambiguous or (owned and (owned.unreadable or (owned.progress
                and owned.progress.unknown)))
                or (not owned and (value.path ~= nil or value.rank ~= nil or (value.augs and value.augs ~= '')))
            items[#items + 1] = item
            if equipment.sources[slot] ~= set.name then inherited = inherited + 1 end
        end
    end
    local model = statModel.Build(items, coverage)
    model.definitions, model.sources = equipment.definitions, equipment.sources
    model.layers, model.layered, model.layerWarnings = equipment.layers, equipment.layered, equipment.warnings
    model.inherited, model.unresolved = inherited, coverage.unchanged + coverage.code + ignored
    if model.layered then
        model.coverage = string.format('%d items | %d inherited | %d unresolved slots', #items, inherited,
            model.unresolved)
    end
    profiler.Finish('Set stats build', started)
    cache.sets[set.name] = model
    return model
end

local function differs(set, other, slot)
    local left, right = loadout_for(set), loadout_for(other)
    return editorInspect.Key(left.definitions[slot]) ~= editorInspect.Key(right.definitions[slot])
end

-- Where a piece dragged from the picker may go: its own slot, or the other ring / earring.
local PAIR = {
    Ring1 = { Ring1 = true, Ring2 = true },
    Ring2 = { Ring1 = true, Ring2 = true },
    Ear1 = { Ear1 = true, Ear2 = true },
    Ear2 = { Ear1 = true, Ear2 = true },
}
setmetatable(PAIR, { __index = function(_, k) return { [k] = true } end, })

-- A card's elemental resistances: its base text plus its augments (owned copy's, else the set's), cached per card.
local resistCache = setmetatable({}, { __mode = 'k' })
local function resist_of(v, owned)
    local hit = resistCache[v]
    if (hit ~= nil) and (hit.owned == owned) then return hit.list end
    local text = describe(v.name) or ''
    local augs = (owned ~= nil) and (owned.displayAugs or owned.augs) or nil
    if (type(augs) == 'table') and (#augs > 0) then
        text = text .. '\n' .. table.concat(augs, '\n')
    elseif (type(v.augs) == 'string') and (v.augs ~= '') then
        text = text .. '\n' .. v.augs
    end
    local list = itemTooltip.ElementTotals(text) or false
    resistCache[v] = { owned = owned, list = list }
    return list
end

-- A slot the set leaves out: the piece an earlier set puts there, as Summary layers them (Auto: Idle > Idle_Refresh,
-- Ws_Default > Savage Blade...; or the base picked there), and that set's name. nil: none known, or this set's own.
local function inherited_of(set, slot)
    local c = editorState.cache.inherit
    if (c == nil) or (c.rev ~= editorState.document.revision) or (c.set ~= set.name)
        or (c.base ~= editorState.ui.statBase) then
        local ok, eq = pcall(ctx.actions.Equipment, set, editorState.ui.statBase, false)
        c = { rev = editorState.document.revision, set = set.name, base = editorState.ui.statBase,
            eq = ok and eq or nil }
        editorState.cache.inherit = c
    end
    local eq = c.eq
    if (eq == nil) or not eq.layered then return nil end
    local d, from = eq.definitions[slot], eq.sources[slot]
    if (d == nil) or (d.kind ~= 'item') or (from == nil) or (from == set.name) or is_slot_word(d) then return nil end
    return { name = d.name, from = from }
end
local function draw_cell(set, slot)
    local v = current(set, slot)
    local selected = (editorState.selection.slot == slot)
    local changed = (editorState.document.edits[set.name] ~= nil)
        and (editorState.document.edits[set.name][slot] ~= nil)
    local owned = owned_for(set, slot)
    local rp = owned and owned.progress
    imgui.PushStyleColor( -- a slot this set leaves alone: no fill, only its outline
        ImGuiCol_ChildBg, changed and palette.warnBg or ((rp and rp.unfinished) and palette.rpBg
            or ((v == nil) and CLEAR or palette.cell))
    )
    local cover = (
        editorState.cache.view ~= nil
        and editorState.cache.view.set == set.name
        and editorState.cache.view.ver == editorState.document.revision and editorState.cache.cover ~= nil
    )
            and editorState.cache.cover[slot]
        or nil -- a later set replaced this piece (action picked below)
    local drop = (editorState.ui.drag ~= nil)
        and ((v == nil) or (v.kind == 'item'))
        and PAIR[editorState.ui.drag.slot][slot] -- a picker row dragged here fits
    local other = cmp_of(set)
    local diff = (other ~= nil) and differs(set, other, slot)
    local lit = (editorState.ui.hoverShown == slot) -- hovered last frame, here or in What goes on
    imgui.PushStyleColor(
        ImGuiCol_Border,
        (selected or drop or lit) and palette.sel
            or (
                changed and palette.warn or diff and palette.aug
                or ((rp and rp.unfinished) and palette.rp or ((cover ~= nil) and palette.override or palette.edge))
            )
    )
    local focusBorder = selected and ImGuiStyleVar_ChildBorderSize ~= nil and imgui.PushStyleVar ~= nil
    if focusBorder then imgui.PushStyleVar(ImGuiStyleVar_ChildBorderSize, 2) end
    imgui.BeginChild('##gcedit_cell_' .. slot, { ctx.CELL_W, ctx.CELL_H }, CHILD_BORDERS, ImGuiWindowFlags_NoScrollbar)
    imgui.TextColored(selected and palette.blue or (changed and palette.warn
        or ((rp and rp.unfinished) and palette.rp or ((cover ~= nil) and palette.override or palette.dim))), slot)
    local bag, ok, badge, badgeX -- the bag badge, right-aligned: what sits before it stops short of it
    if (v ~= nil) and (v.kind == 'item') then
        bag, ok = where(v.name)
        badge = is_slot_word(v) and 'Rule' or cardText.Bag(bag)
        badgeX = ctx.CELL_W - text_w(badge) - 14
    end
    local res = (v ~= nil) and (v.kind == 'item') and not is_slot_word(v) and resist_of(v, owned)
    if res then -- its resistances, as the game's element icons: one value when they all match
        imgui.SameLine(0, 8)
        local room = (badgeX or ctx.CELL_W) - 5 - imgui.GetCursorPosX() - 4 -- the badge's fill starts 5 left
        local dotsW = itemTooltip.ElementDotsWidth(imgui, res)
        local value = (res.same ~= nil) and (((res.same > 0) and '+' or '') .. res.same) or nil
        if dotsW <= room then -- no room: left to the item's tooltip
            itemTooltip.ElementDots(imgui, res)
            if (value ~= nil) and (dotsW + 2 + text_w(value) <= room) then
                imgui.SameLine(0, 2)
                imgui.TextColored(palette.dim, value)
            end
        end
    end
    if badge ~= nil then
        imgui.SameLine(badgeX)
        pill(
            badge,
            is_slot_word(v) and palette.blue
                or (bag == nil and palette.bad or (ok and palette.ok or palette.warn)),
            is_slot_word(v) and palette.invBg
                or (bag == nil and palette.badBg or (ok and palette.okBg or palette.warnBg))
        )
    end
    local gh = (v == nil) and ghost_of(set, slot) or nil -- commented out in the file (/gcbuild)
    -- not in this set: the piece an earlier set puts here, faint, with that set's name below
    local inh = ((v == nil) and (gh == nil) and not changed) and inherited_of(set, slot) or nil
    local faded = ((gh ~= nil) or (inh ~= nil)) and (ImGuiStyleVar_Alpha ~= nil) -- not worn: its icon faint
    if faded then imgui.PushStyleVar(ImGuiStyleVar_Alpha, 0.4) end
    draw_icon(
        ((v ~= nil) and (v.kind == 'item') and item_id(v.name)) or ((gh ~= nil) and item_id(gh.name))
            or ((inh ~= nil) and item_id(inh.name)) or nil, ctx.ICON
    )
    if faded then imgui.PopStyleVar() end
    imgui.SameLine()
    imgui.BeginGroup()
    if gh ~= nil then
        imgui.TextColored(palette.dim, cardText.Name(gh.name, ctx.CELL_W - ctx.ICON - 24, text_w))
    elseif inh ~= nil then
        imgui.TextColored(palette.dim, cardText.Name(inh.name, ctx.CELL_W - ctx.ICON - 24, text_w))
    elseif v == nil then
        imgui.TextColored(changed and palette.warn or palette.dim, changed and 'Slot cleared' or 'Unchanged')
    elseif v.kind == 'code' then
        imgui.TextColored(palette.dim, cardText.Name('code: ' .. v.raw, ctx.CELL_W - ctx.ICON - 24, text_w))
    else
        imgui.TextColored(
            is_slot_word(v) and palette.blue or palette.text, cardText.Name(v.name, ctx.CELL_W - ctx.ICON - 24, text_w)
        )
    end
    imgui.EndGroup()
    -- Fixed footer rows keep every card aligned, regardless of the item's name or metadata; placed by the font's
    -- line height from the bottom, so a bigger font never stacks them on each other or on the border.
    local lh = (imgui.GetTextLineHeight ~= nil) and imgui.GetTextLineHeight() or 16
    local statusY = ctx.CELL_H - lh - 6
    imgui.SetCursorPosY(statusY - lh - 2)
    imgui.Dummy({ 0, 0 }) -- register the new extent even when this card has no footer text
    local rankShown = false -- R<rank>/<cap>, in the RP colour while unfinished: Needs RP below would repeat it
    if v and v.kind == 'item' and not is_slot_word(v) then
        local meta = {}
        local path = v.path or (owned and owned.path)
        if path then meta[#meta + 1] = path end
        if rp and owned then
            meta[#meta + 1] = 'R' .. owned.rank .. (owned.cap and ('/' .. owned.cap) or '')
            rankShown = true
        end
        if #meta == 0 and ((v.augs and v.augs ~= '') or (owned and #owned.augs > 0)) then
            meta[#meta + 1] = 'Augmented'
        end
        if #meta > 0 then
            imgui.TextColored(
                (rp and rp.unfinished) and palette.rp or palette.dim,
                cardText.Fit(table.concat(meta, ' / '), ctx.CELL_W - 16, text_w)
            )
        end
    elseif gh then
        imgui.TextColored(palette.dim, 'Not in this set')
    elseif inh then
        imgui.TextColored(palette.dim, cardText.Fit('from ' .. inh.from, ctx.CELL_W - 16, text_w))
    elseif changed then
        imgui.TextColored(palette.warn, 'Cleared on Save')
    end
    if changed or cover or ((rp and rp.unfinished) and not rankShown) then
        imgui.SetCursorPosY(statusY)
        local status = cover and ((changed and 'Unsaved > ' or 'Replaced: ') .. cover.short)
            or (changed and 'Unsaved' or 'Needs RP')
        imgui.TextColored(changed and palette.warn or (cover and palette.override or palette.rp),
            cardText.Fit(status, ctx.CELL_W - 16, text_w))
    end
    local menuHit = false
    if (editorState.ui.cardShown == slot) and (imgui.SetCursorPosX ~= nil) then -- the card hovered: '...' opens its menu
        local bw = text_w('...') + 10
        imgui.SetCursorPosX(ctx.CELL_W - bw - 6)
        imgui.SetCursorPosY(ctx.CELL_H - lh - 8)
        imgui.PushStyleColor(ImGuiCol_Button, palette.btn)
        menuHit = imgui.SmallButton('...##gcedit_cellmenu_' .. slot)
        imgui.PopStyleColor()
        if imgui.IsItemHovered() then set_tip('This slot\'s menu: inspect, choose gear, undo, clear (or right-click).') end
        if menuHit then request_context('slot', set, slot) end
    end
    imgui.EndChild()
    if focusBorder then imgui.PopStyleVar() end
    if imgui.IsItemHovered() then editorState.ui.hoverSlot, editorState.ui.cardHover = slot, slot end
    if imgui.IsItemClicked(0) and not menuHit then
        editorState.selection.slot = slot
        editorState.selection.tab = 'gear'
    end
    if drop and (imgui.IsMouseDown ~= nil) and not imgui.IsMouseDown(0) and (imgui.GetMousePos ~= nil) then -- dropped
        local mx, my = xy(imgui.GetMousePos())
        local x1, y1 = xy(imgui.GetItemRectMin())
        local x2, y2 = xy(imgui.GetItemRectMax())
        if (mx ~= nil) and (x1 ~= nil) and (x2 ~= nil) and (mx >= x1) and (mx <= x2) and (my >= y1) and (my <= y2) then
            edit(set, slot, editorState.ui.drag.g)
            editorState.selection.slot, editorState.ui.drag = slot, nil
        end
    end
    if imgui.IsItemClicked(1) then request_context('slot', set, slot) end
    if imgui.IsItemHovered() and (gh ~= nil) then
        set_tip(
            wrap(
                'Empty. The file has '
                    .. gh.name
                    .. ' commented out here ('
                    .. (gh.why or 'no reason given')
                    .. ').\nClick the slot and pick gear you own: it takes that line.', 60
            )
        )
    elseif imgui.IsItemHovered() and (v ~= nil) and itemTooltip.HoverReady(imgui, 'card:' .. set.name .. ':' .. slot,
        editorState.ui.frame) then
        if v.kind == 'item' then
            local bag, ok = where(v.name)
            local comparison
            if diff then
                local w = set_stats(other).definitions[slot]
                comparison = other.name .. ': ' .. ((w ~= nil) and (w.name or w.raw) or 'empty')
            end
            local tooltipStarted = profiler.Start()
            itemTooltip.Draw(
                imgui,
                palette,
                itemTooltip.Model(v, owned, {
                    bag = bag,
                    equippable = bag and ok,
                    rule = is_slot_word(v),
                    description = not is_slot_word(v) and describe(v.name) or nil,
                    replacement = cover and cover.full,
                    comparison = comparison,
                    usedIn = (ctx.used_in ~= nil) and not is_slot_word(v) and ctx.used_in(v.name) or nil,
                })
            )
            profiler.Finish('Item tooltip', tooltipStarted)
        else
            set_tip(wrap(v.raw or '', 68))
        end
    elseif imgui.IsItemHovered() and v == nil and not diff then
        local inh = (ghost_of(set, slot) == nil) and inherited_of(set, slot) or nil
        set_tip((inh ~= nil)
            and (wrap('Not in this set: ' .. inh.from .. ' puts ' .. inh.name .. ' here, and it stays (the layers '
                .. 'Stats uses; its Base: picks another). Click: pick gear for this set.', 60))
            or 'This set leaves the slot alone. Gear from an earlier layer stays equipped.')
    elseif imgui.IsItemHovered() and diff then
        local w = current(other, slot)
        set_tip('Empty here.\n' .. other.name .. ' has: ' .. ((w ~= nil) and (w.name or w.raw) or 'nothing'))
    end
    imgui.PopStyleColor(2)
end

-- Equipped result: the recorded actions (gcaction.Rec*) that used this set; for the one picked, each slot's
-- final piece and the set (or engine rule) it came from, then the order the sets went on, then sets it looked for.
-- /gcedit: the What goes on tables (what an action wore, layer by layer).
local TABLE_FLAGS =
    bit.bor(ImGuiTableFlags_RowBg or 0, ImGuiTableFlags_Borders or 0, ImGuiTableFlags_SizingStretchProp or 0)

-- Text joined by '  |  ', wrapped only between its parts: a line never ends on a |.
local function parts_line(color, text)
    local n = 0
    for part in string.gmatch(text .. '  |  ', '(.-)  |  ') do
        n = n + 1
        if n > 1 then
            imgui.SameLine(0, 0)
            local avail = imgui.GetContentRegionAvail()
            local w = (type(avail) == 'number') and avail or (avail.x or avail[1])
            if w >= text_w('  |  ' .. part) then part = '  |  ' .. part else imgui.NewLine() end
        end
        imgui.TextColored(color, part)
    end
end

-- One layer of the equip order as icons, 4 to a row in the equipment screen's order, rows after its last piece left
-- out: outlined green while still worn, faded with an orange outline when a later one replaced it, grey when the
-- same piece went on again later. Ids worked out once per view.
local ORDER_ICON = 26
local function order_grid(o)
    if o.ids == nil then
        o.ids, o.last = {}, 0
        for i = 1, #SCREEN do
            local c = o.cells and o.cells[i] or nil
            if c ~= nil then
                local l = string.lower(tostring(c.name))
                o.ids[i] = (not is_slot_word({ kind = 'item', name = c.name })) and (l ~= 'ignore') and item_id(c.name)
                    or false
                o.last = i
            end
        end
    end
    local dl = ((imgui.GetWindowDrawList ~= nil) and (imgui.GetCursorScreenPos ~= nil) and (imgui.GetColorU32 ~= nil))
        and imgui.GetWindowDrawList() or nil
    local EDGE = { won = palette.ok, lost = palette.override, same = palette.dim }
    imgui.BeginGroup()
    for i = 1, math.max(1, math.ceil(o.last / 4)) * 4 do
        if (i - 1) % 4 ~= 0 then imgui.SameLine(0, 2) end
        local c = o.cells and o.cells[i] or nil
        local x, y = nil, nil
        if dl ~= nil then x, y = xy(imgui.GetCursorScreenPos()) end
        if (x ~= nil) and (y ~= nil) then
            dl:AddRectFilled({ x, y }, { x + ORDER_ICON, y + ORDER_ICON }, imgui.GetColorU32({ 0.09, 0.11, 0.14, 1 }))
        end
        if (c ~= nil) and o.ids[i] then
            local faded = (c.state == 'lost') and (ImGuiStyleVar_Alpha ~= nil)
            if faded then imgui.PushStyleVar(ImGuiStyleVar_Alpha, 0.35) end
            draw_icon(o.ids[i], ORDER_ICON)
            if faded then imgui.PopStyleVar(1) end
        else
            imgui.Dummy({ ORDER_ICON, ORDER_ICON })
        end
        if c ~= nil then
            if (x ~= nil) and (y ~= nil) then
                dl:AddRect({ x - 1, y - 1 }, { x + ORDER_ICON + 1, y + ORDER_ICON + 1 },
                    imgui.GetColorU32(EDGE[c.state] or palette.dim), 0, 0, 1)
            end
            if imgui.IsItemHovered() then
                set_tip(SCREEN[i] .. ': ' .. tostring(c.name) .. '\n'
                    .. ((c.state == 'won') and 'Still worn.'
                        or (c.state == 'same') and 'The same piece went on again later.'
                        or ('Replaced later' .. ((c.by ~= nil) and (' by ' .. c.by) or '') .. '.')))
            end
        end
    end
    imgui.EndGroup()
end

local function draw_layer_view(set, V)
    imgui.Spacing()
    heading('What goes on')
    imgui.PushTextWrapPos(0)
    imgui.TextUnformatted(V.head)
    imgui.PopTextWrapPos()
    if V.state ~= nil then
        imgui.PushTextWrapPos(0)
        parts_line(palette.dim, V.state)
        if V.buffs ~= nil then imgui.TextColored(palette.dim, V.buffs) end
        imgui.PopTextWrapPos()
    end
    local replacements = {}
    for _, cover in pairs(V.cover) do
        replacements[cover.short] = (replacements[cover.short] or 0) + 1
    end
    local sources = {}
    for source in pairs(replacements) do
        sources[#sources + 1] = source
    end
    table.sort(sources)
    for _, source in ipairs(sources) do
        local count = replacements[source]
        local text = source == 'a lock' and (count .. ' locked slot' .. (count == 1 and '' or 's'))
            or (source .. ' overrides ' .. count .. ' slot' .. (count == 1 and '' or 's'))
        imgui.TextColored(palette.override, text)
    end
    if imgui.BeginTable('##gcedit_final', 3, TABLE_FLAGS) then
        imgui.TableSetupColumn('Slot', 0, 0.6)
        imgui.TableSetupColumn('What was worn', 0, 1.6)
        imgui.TableSetupColumn('Source', 0, 1.6) -- no header row: slot, item, and the set as a tag
        local rowBg = (imgui.TableSetBgColor ~= nil) and (imgui.GetColorU32 ~= nil) and imgui.GetColorU32(palette.selBg) or nil
        for _, row in ipairs(V.rows) do
            imgui.TableNextRow()
            if (rowBg ~= nil) and (editorState.ui.hoverShown == row.slot) then -- its card is hovered (or this row)
                -- new to this editor: the binding's argument list isn't proven, so a refusal only loses the highlight
                if not pcall(imgui.TableSetBgColor, ImGuiTableBgTarget_RowBg0 or 1, rowBg) then
                    pcall(imgui.TableSetBgColor, ImGuiTableBgTarget_RowBg0 or 1, rowBg, -1)
                end
            end
            imgui.TableNextColumn()
            imgui.TextColored(palette.dim, row.slot)
            if imgui.IsItemHovered() then editorState.ui.hoverSlot = row.slot end
            imgui.TableNextColumn()
            if row.worn == nil then
                imgui.TextColored(palette.dim, 'no change')
            else
                imgui.TextUnformatted(row.worn)
                if imgui.IsItemHovered() then editorState.ui.hoverSlot = row.slot end
                if imgui.IsItemClicked(1) and row.worn ~= '(left empty)' then
                    request_context('result', set, row.slot, { kind = 'item', name = row.worn }, row.src)
                end
            end
            imgui.TableNextColumn()
            pill(row.src, palette[row.sourceRole] or palette.dim, palette.chipBg)
            if row.replacedName ~= nil then
                imgui.PushTextWrapPos(0) -- wraps at the column's edge
                imgui.TextColored(
                    palette.override, 'Replaced ' .. row.replacedName .. (row.locked and ' (locked)' or '')
                )
                imgui.PopTextWrapPos()
            end
        end
        imgui.EndTable()
    end
    if V.still ~= nil then
        imgui.PushTextWrapPos(0)
        imgui.TextColored(palette.dim, 'Unchanged slots: ' .. V.still)
        imgui.PopTextWrapPos()
    end

    imgui.Spacing()
    if editorPanels.Section(imgui, palette, 'Equip order: who put on what, first to last##gcedit_order') then
        for _, o in ipairs(V.order) do
            imgui.TextColored(palette.dim, string.match(o.title, '^%d+%.') or '')
            imgui.SameLine()
            order_grid(o)
            imgui.SameLine(0, 10)
            imgui.BeginGroup()
            imgui.PushTextWrapPos(0)
            imgui.TextColored(o.mine and palette.blue or palette.text, (string.gsub(o.title, '^%d+%.%s*', '')))
            if imgui.IsItemHovered() then set_tip(o.rawSource or o.title) end
            if o.mine then
                imgui.SameLine()
                imgui.TextColored(palette.blue, '(this set)')
            end
            imgui.TextColored(palette.dim, o.why)
            if o.won ~= nil then imgui.TextColored(palette.ok, o.won) end
            if o.same ~= nil then imgui.TextColored(palette.dim, o.same) end
            if o.lost ~= nil then imgui.TextColored(palette.override, o.lost) end
            imgui.PopTextWrapPos()
            imgui.EndGroup()
            imgui.Spacing()
        end
        imgui.TextColored(palette.dim, 'Green: still worn. Orange, faded: a later one replaced it. Hover a piece.')
    end
    if (#V.missing + #V.variants > 0) and editorPanels.Section(imgui, palette, 'Set suggestions ('
        .. (#V.missing + #V.variants) .. ')##gcedit_suggestions') then
        imgui.Spacing()
        imgui.TextColored(palette.dim, 'Optional set definitions for this action:')
        help(
            'Each says why it was looked for and what goes on without it. You only need one if it should change gear.\n'
                .. 'Make adds an empty set to the list; nothing is saved until Save + reload.'
        )
        local made = nil
        -- suggestions looked for for the same reason share it: their Make buttons, then the reason once
        local function rows(list, base)
            local i = 1
            while i <= #list do
                local why = list[i].why
                local j = i
                while (list[j + 1] ~= nil) and (list[j + 1].why == why) do j = j + 1 end
                for k = i, j do
                    if k > i then imgui.SameLine(0, 10) end
                    if imgui.SmallButton('Make##gcmiss' .. (base + k)) then made = list[k].name end
                    imgui.SameLine()
                    imgui.TextUnformatted(list[k].name)
                end
                imgui.Indent(52)
                imgui.PushTextWrapPos(0)
                imgui.TextColored(palette.dim, why)
                imgui.PopTextWrapPos()
                imgui.Unindent(52)
                i = j + 1
            end
        end
        rows(V.missing, 0)
        if #V.variants > 0 then
            imgui.TextColored(palette.dim, 'Optional variants (only if they need different gear):')
            rows(V.variants, 100)
        end
        if made ~= nil then
            make_set(made, nil, true)
        end -- after the loop: it rebuilds V.missing
    end
end

---------------------------------------------------------------------------------------------------------------------
-- Exact set names to omit from the suggestions view. Configure with settings.EditorIgnoreSuggestions = T{'Singing'}.
local function ignored_suggestion_names()
    local out = {}
    local function add(list)
        if type(list) ~= 'table' then return end
        for key, value in pairs(list) do
            local name = (type(key) == 'number') and value or ((value == true) and key or nil)
            if type(name) == 'string' and name ~= '' then out[string.lower(name)] = true end
        end
    end
    if ctx.gearEngine ~= nil and not editorState.document.inactive then
        add((ctx.gearEngine.settings ~= nil) and ctx.gearEngine.settings.EditorIgnoreSuggestions or nil)
        add(ctx.gearEngine.EditorIgnoreSuggestions) -- optional per-job list
    end
    return out
end

---------------------------------------------------------------------------------------------------------------------
local function draw_layers(set)
    local records = not editorState.document.inactive and GcRecords or nil
    editorState.cache.cover = nil
    imgui.Spacing()
    heading('When it went on')
    help(
        'Each line is one action:\n'
            .. '- seen: it happened since load. Shows everything that went on, engine rules too.\n'
            .. '- expected: not done yet. Worked out from your sets and the modes now.\n'
            .. 'Pick one:\n'
            .. '- the table: what each slot ends with, and the set that put it there (by number)\n'
            .. '- the list under it: the order the sets went on, and why each one did'
    )
    -- the records list, rebuilt only when a new record lands or the set / checkbox changes
    local rkey = set.name
        .. '\0'
        .. tostring(editorState.ui.allRecs[1])
        .. '\0' .. ((records ~= nil) and ((records.n or 0) .. '/' .. #records.order) or '-')
    if editorState.cache.recsKey ~= rkey then
        local recs = ctx.actions.RecordsFor(set.name)
        if editorState.ui.allRecs[1] and (records ~= nil) then
            recs = {}
            for _, key in ipairs(records.order) do
                local r = records.byKey[key]
                if (r ~= nil) and (r.job == editorState.profile.job) then recs[#recs + 1] = r end
            end
            table.sort(recs, function(x, y) return x.time > y.time end)
        end
        editorState.cache.recsKey, editorState.cache.recs = rkey, recs
    end
    local recs = editorState.cache.recs
    -- expected: the set's own action, from the sets and modes now, while it has not been seen since load
    local ekey = set.name
        .. '\0'
        .. editorState.document.revision
        .. '\0'
        .. ((gcdisplay ~= nil) and gcdisplay.Version() or '-') -- every mode change bumps it
        .. '\0' .. ((records ~= nil) and tostring(records.n) or '-')
    if editorState.cache.expKey ~= ekey then
        local e = ctx.actions.Expected(set)
        if (e ~= nil) and (e.seenKey ~= nil) and (records ~= nil) and (records.byKey[tostring(editorState.profile.job)
            .. ' ' .. e.seenKey] ~= nil) then
            e = nil
        end
        editorState.cache.expKey, editorState.cache.exp = ekey, e
    end
    local exp = editorState.cache.exp
    imgui.SameLine(0, 12)
    imgui.Checkbox('every action##gcedit_all', editorState.ui.allRecs)
    if imgui.IsItemHovered() then set_tip('Show every action, not only the ones that used ' .. set.name .. '.') end
    if (#recs == 0) and (exp == nil) then
        imgui.PushTextWrapPos(0)
        imgui.TextColored(
            palette.dim,
            'Nothing yet: '
                .. set.name .. ' has not been worn since LuAshitacast loaded. Use it in game, then look here.'
        )
        imgui.PopTextWrapPos()
        return
    end
    local pick = nil
    if editorState.cache.recFor == set.name then
        if (exp ~= nil) and (exp.key == editorState.cache.recKey) then pick = exp end
        for _, r in ipairs(recs) do
            if r.key == editorState.cache.recKey then pick = r end
        end
    end
    if (pick == nil) and (exp ~= nil) then
        pick = exp
    end -- not seen yet: what it would put on
    if pick == nil then -- first look at a set: the action where it kept the most slots (Idle: standing idle)
        local best = -1
        for _, r in ipairs(recs) do
            local n = 0
            local _, fin = ctx.actions.Layers(r)
            for _, f in pairs(fin) do
                if ctx.actions.IsSetLabel(f.by, set.name) then n = n + 1 end
            end
            if n > best then best, pick = n, r end
        end
    end
    editorState.cache.recKey, editorState.cache.recFor = pick.key, set.name
    local now = os.time()
    if editorState.cache.agoAt ~= now then
        editorState.cache.agoAt, editorState.cache.agoText = now, {}
    end -- the 'ago' texts, once a second
    local rows = #recs + ((exp ~= nil) and 1 or 0)
    imgui.BeginChild('##gcedit_recs', { 0, 22 * math.min(rows, 4) + 8 }, CHILD_BORDERS)
    if exp ~= nil then
        local main, kind = ctx.actions.ActionParts(exp)
        if imgui.Selectable(main .. '##gcexp', exp == pick) then
            editorState.cache.recKey = exp.key
            pick = exp
        end
        if kind ~= nil then
            imgui.SameLine()
            imgui.TextColored(palette.dim, '(' .. kind .. ')')
        end
        imgui.SameLine()
        imgui.TextColored(palette.blue, 'expected: not seen yet')
        if imgui.IsItemHovered() then
            set_tip(
                wrap(
                    'Not recorded: worked out from your sets and the modes now.\nUse it in game and a seen line takes its place.',
                    60
                )
            )
        end
    end
    for _, r in ipairs(recs) do
        if r.rowLabel == nil then -- its name as the row; its kind after it, dim
            local main, kind = ctx.actions.ActionParts(r)
            r.rowLabel, r.rowKind = main .. '##gcrec' .. r.key, (kind ~= nil) and ('(' .. kind .. ')') or nil
        end
        if imgui.Selectable(r.rowLabel, r == pick) then
            editorState.cache.recKey = r.key
            pick = r
        end
        if r.rowKind ~= nil then
            imgui.SameLine()
            imgui.TextColored(palette.dim, r.rowKind)
        end
        imgui.SameLine()
        imgui.TextColored(palette.ok, 'seen')
        imgui.SameLine()
        local t = editorState.cache.agoText[r]
        if t == nil then
            t = ago(r.time) .. ((r.tp ~= nil) and ('  at ' .. r.tp .. ' TP') or '')
            editorState.cache.agoText[r] = t
        end
        imgui.TextColored(palette.dim, t)
    end
    imgui.EndChild()

    -- everything below depends only on the record, the set and the set list: worked out once, drawn every frame
    local V = editorState.cache.view
    if (V == nil) or (V.rec ~= pick) or (V.set ~= set.name) or (V.ver ~= editorState.document.revision) then
        local started = profiler.Start()
        V = ctx.actions.View(set, pick)
        profiler.Finish('Action view rebuild', started)
        editorState.cache.view = V
    end
    editorState.cache.cover = V.cover
    draw_layer_view(set, V)
end

-- Shared entries keep More and right-click set actions identical.
-- Revert / Rename / Delete rows. part 'edit': Revert and Rename; 'drop': Delete (Discard for a new set); nil: all.
-- The moment a rule wearing a set most likely means, by the set's heading (the builder lets you change it).
local RULE_MOMENT = { ['Weapon skills'] = 'Weaponskill', ['Named weapon skills'] = 'Weaponskill',
    ['Job abilities'] = 'Ability', Casting = 'Midcast', ['Spells (by name)'] = 'Midcast' }
local function set_action_entries(set, part)
    local item, doc = ctx.menu_item, editorState.document
    if (part ~= 'drop') and (ctx.rules ~= nil) and item('Wear this when...##gcedit_rule') then
        -- the Rules page's builder, Wear set to this set: pick the moment and the conditions
        ctx.rules.Edit(nil, nil, { on = RULE_MOMENT[set.group or ''] or 'Default', wear = set.name, exact = true })
        editorState.selection.rules, editorState.ui.rulesView = true, 'all'
    end
    if set.new then
        if (part ~= 'drop') and item('Rename set...##gcedit_new') then editorState.ui.requestRenameSet = set.name end
        if (part ~= 'edit') and item('Discard new set##gcedit', true, false, palette.bad) then
            drop_new(set)
            return true
        end
        return false
    end
    if part ~= 'drop' then
        local count = 0
        for _ in pairs(doc.edits[set.name] or NONE) do count = count + 1 end
        if item('Revert set##gcedit', count > 0) then
            doc.edits[set.name] = nil
            doc.revision = doc.revision + 1
            feedback('Reverted unsaved slot edits in ' .. set.name .. '.')
        end
        if (doc.renames or {})[set.name] then
            if item('Cancel rename##gcedit') then
                ctx.stage_rename(set.name, nil)
                feedback('Cancelled renaming ' .. set.name .. '.')
            end
        elseif not doc.deleted[set.name] and item('Rename set...##gcedit') then
            editorState.ui.requestRenameSet = set.name
        end
    end
    if part ~= 'edit' then
        if doc.deleted[set.name] then
            if item('Undo deletion##context') then
                doc.deleted[set.name] = nil
                doc.revision = doc.revision + 1
                feedback('Cancelled deletion of ' .. set.name .. '.')
            end
        elseif item('Delete set...##gcedit', true, false, palette.bad) then
            editorState.ui.requestDeleteSet = set.name
        end
    end
    return false
end

-- The Rules page's buttons (primary, accent, plain, danger, ghost): one look across the editor.
local function sbutton(label, kind)
    if (ctx.rules ~= nil) and (ctx.rules.Button ~= nil) then return ctx.rules.Button(label, kind, true) end
    return imgui.Button(label)
end
local function badge(text, fg, bg)
    imgui.SameLine(0, 12)
    pill(text, fg, bg)
end
local function draw_set_actions(set)
    if sbutton('More...##set_actions', 'ghost') then imgui.OpenPopup('##set_actions_menu') end
    local discarded = false
    if imgui.BeginPopup('##set_actions_menu') then
        discarded = set_action_entries(set)
        imgui.EndPopup()
    end
    return discarded
end

-- A Weapon_ set's two ways to go wrong, said under its buttons with the fix: armor in it (never worn: a weapon mode
-- puts on Main, Sub, Range and Ammo only) and a set /wm never reaches (the job file's WeaponModes doesn't name it).
local function put_value(set, slot, v) -- a slot's value (current()) into another set as is: augments, path, rank
    local doc = editorState.document
    editorState.history.entries = editorState.history.entries or {}
    editorState.history.entries[#editorState.history.entries + 1] = { set = set.name, slot = slot,
        previous = doc.edits[set.name] and doc.edits[set.name][slot] }
    doc.edits[set.name] = doc.edits[set.name] or {}
    doc.edits[set.name][slot] = { kind = v.kind, name = v.name, path = v.path, rank = v.rank, augs = v.augs, raw = v.raw,
        text = v.text or v.raw }
    doc.revision = doc.revision + 1
end
local function draw_weapon_checks(set, w)
    imgui.PushTextWrapPos(ctx.CELL_W * ctx.GRID_COLUMNS + 8)
    if (w.kind == 'unlisted') and not string.find(w.mode, '[_%s]') then
        imgui.TextColored(palette.warn, 'Never worn: /wm has no ' .. w.mode .. ' mode (the job file\'s /wm modes don\'t '
            .. 'name it).')
        if sbutton('Add /wm ' .. w.mode .. '##gcws_addmode', 'plain') then
            local S = ctx.settingsFiles
            local list, now = {}, S.Job('WeaponModes')
            for _, m in ipairs((type(now) == 'table') and now or { 'None' }) do list[#list + 1] = m end
            list[#list + 1] = w.mode
            S.StageJob('WeaponModes', list)
            feedback('/wm ' .. w.mode .. ' added (written on Save).')
        end
        if imgui.IsItemHovered() then set_tip('Add ' .. w.mode .. ' to /wm modes (GoomSwap settings, this job options).') end
    elseif w.kind == 'unlisted' then
        imgui.TextColored(palette.warn, 'Never worn: not a /wm mode, nor one\'s own _1h or /mset set.')
    end
    if #w.armor > 0 then
        imgui.TextColored(palette.warn, table.concat(w.armor, ', ') .. ': never worn. A Weapon_ set only puts on Main, '
            .. 'Sub, Range and Ammo.')
        local target = 'Tp_' .. w.mode
        if (w.kind == 'mode') and sbutton('Move to ' .. target .. '##gcws_move', 'plain') then
            local model = editorState.document.model
            local t = model.byLower[string.lower(target)]
            if t == nil then
                make_set(target, nil, true)
                t = model.byLower[string.lower(target)] or model.byName[target]
            end
            local moved, kept = 0, {}
            for _, slot in ipairs(w.armor) do
                local v = current(set, slot)
                if (t ~= nil) and (t.code == nil) and (current(t, slot) == nil) and (v ~= nil) then
                    put_value(t, slot, v)
                    moved = moved + 1
                else
                    kept[#kept + 1] = slot
                end
                edit(set, slot, nil)
            end
            feedback('Moved ' .. moved .. ' to ' .. target .. ((#kept > 0) and (' (' .. table.concat(kept, ', ')
                .. ': ' .. target .. ' has its own, kept)') or '') .. '; unsaved.')
        end
        if (w.kind == 'mode') and imgui.IsItemHovered() then
            set_tip(target .. ' goes on over Tp_Default while /wm ' .. w.mode .. ' is on and you fight. Slots it '
                .. 'already fills keep its own piece.')
        end
        if w.kind == 'mode' then imgui.SameLine() end
        if sbutton('Clear them##gcws_clear', 'ghost') then
            for _, slot in ipairs(w.armor) do edit(set, slot, nil) end
            feedback('Cleared ' .. #w.armor .. ' slots of ' .. set.name .. ' (unsaved).')
        end
    end
    imgui.PopTextWrapPos()
end
local function draw_set(set)
    if (editorState.selection.back ~= nil) and (#editorState.selection.back > 0) then
        local prev = editorState.selection.back[#editorState.selection.back]
        if imgui.SmallButton('< Back to ' .. prev .. '##gcedit_back') then
            table.remove(editorState.selection.back)
            editorPreferences.Select(editorState, prev, nil, 'action')
            return
        end
        imgui.SameLine(0, 12)
    end
    -- the set being edited: a strip (an accent bar, its heading as a breadcrumb, its name and badges, how many
    -- slots it fills, then what it is used for), apart from the Recent line over it
    imgui.PushStyleColor(ImGuiCol_ChildBg, CLEAR) -- the title: plain, no strip
    imgui.BeginChild('##gcedit_title', { 0, 0 },
        (ImGuiChildFlags_AutoResizeY or 32) + (ImGuiChildFlags_AlwaysUseWindowPadding or 2),
        ImGuiWindowFlags_NoScrollbar or 0)
    if (set.group ~= nil) and (set.group ~= '') and (string.lower(set.group) ~= set.lname) then -- not 'Idle > Idle'
        imgui.TextColored(palette.dim, set.group .. ' >')
        imgui.SameLine()
    end
    imgui.TextColored(palette.text, set.bracket and ("['" .. set.name .. "']") or set.name)
    if by_name(set) then badge('worn by name', palette.blue, palette.invBg) end
    if (editorState.document.renames or {})[set.name] then
        badge('renamed to ' .. editorState.document.renames[set.name] .. ' on Save', palette.warn, palette.warnBg)
    end
    if set.new then
        badge('new: written on Save', palette.warn, palette.warnBg)
        local mode = pending_weapon_mode(set)
        if mode then
            local plan = registration_plan()
            imgui.TextColored(plan.ok and palette.blue or palette.bad,
                plan.ok and ('Weapon cycle: ' .. mode .. ' will be added on Save.')
                    or ('Cannot register ' .. mode .. ': no gcinclude.Initialize() line in this file.'))
        end
    end
    local status = set_status(set)
    local unfinished = status.unfinished
    if #unfinished > 0 then
        imgui.SameLine(0, 12)
        imgui.PushStyleColor(ImGuiCol_Button, palette.rpBg)
        imgui.PushStyleColor(ImGuiCol_Text, palette.rp)
        if imgui.SmallButton(#unfinished .. ' need RP##rp') then
            imgui.OpenPopup('##rp_details')
        end
        imgui.PopStyleColor(2)
        if imgui.IsItemHovered() then
            set_tip(#unfinished .. ' slot' .. ((#unfinished == 1) and '' or 's') .. ' below their rank cap:\n'
                .. table.concat(unfinished, '\n') .. '\nClick: where else they are used.')
        end
    end
    local filled = (set.code == nil) and (status.armor ~= nil) and ((status.armor or 0) + (status.weapons or 0)) or nil
    local function slots_line() -- '15 of 16 slots', on the line under the name
        if filled == nil then return end
        imgui.TextColored(palette.dim, filled .. ' of 16 slots')
        if imgui.IsItemHovered() then
            set_tip(status.armor .. ' of 12 armor slots, ' .. (status.weapons or 0) .. ' of 4 weapon slots name '
                .. 'gear here; the rest keep what earlier sets put on.')
        end
    end
    local function meter() -- under the strip: how much of the 16 this set fills
        if filled == nil then return end
        local dl = (imgui.GetWindowDrawList ~= nil) and imgui.GetWindowDrawList() or nil
        if (dl ~= nil) and (imgui.GetCursorScreenPos ~= nil) and (imgui.GetColorU32 ~= nil) then
            local x, y = xy(imgui.GetCursorScreenPos())
            local w = (imgui.GetContentRegionAvail ~= nil) and xy(imgui.GetContentRegionAvail()) or nil
            if (x ~= nil) and (y ~= nil) and (w ~= nil) and (w > 20) then
                dl:AddRectFilled({ x, y + 1 }, { x + w, y + 4 }, imgui.GetColorU32(palette.cell), 2)
                dl:AddRectFilled({ x, y + 1 }, { x + w * math.min(filled, 16) / 16, y + 4 }, imgui.GetColorU32(palette.sel), 2)
                imgui.Dummy({ w, 6 })
            end
        end
    end

    if imgui.BeginPopup('##rp_details') then
        imgui.TextUnformatted('Unfinished gear in this set')
        imgui.BeginChild('##rp_list', { 440, 300 }, 0)
        local seen = {}
        for _, slot in ipairs(SCREEN) do
            local g = owned_for(set, slot)
            if g and g.progress and g.progress.unfinished and not seen[g.key] then
                seen[g.key] = true
                imgui.TextColored(palette.rp, g.name .. ' - R' .. g.rank .. '/' .. tostring(g.cap or '?'))
                for index, use in ipairs(rp_uses(g)) do
                    if imgui.Selectable(use.set .. ' / ' .. use.slot .. '##rp_' .. slot .. '_' .. index) then
                        go_to(use.set, use.slot, 'gear')
                        imgui.CloseCurrentPopup()
                    end
                end
                imgui.Separator()
            end
        end
        imgui.EndChild()
        imgui.EndPopup()
    end
    local when, short = ctx.actions.When(set)
    local ruleUse = (ctx.rules ~= nil) and ctx.rules.UsesOf(set.name) or nil -- gcinclude.Rules that wear it
    if (when ~= nil) and (ruleUse ~= nil) and not string.find(when, 'No built-in trigger', 1, true) then
        when = when .. '\n\n' .. ruleUse.text
    end
    if when ~= nil then
        if (ruleUse ~= nil) and string.find(when, 'No built-in trigger', 1, true) then
            short, when = ruleUse.short, ruleUse.text
        elseif string.find(when, 'No built-in trigger', 1, true) then -- GoomSwap never wears it by its name
            if set.new or not ctx.actions.NamedInCode(set) then
                short = 'nothing yet (never worn)'
                when = 'GoomSwap never puts this set on by itself, and nothing in your job file names it, so it is never '
                    .. 'worn. Name it in a Handle function (gFunc.EquipSet(sets.' .. set.name .. '), ByName(\'' .. set.name
                    .. '\')), or delete it (the Unused filter lists sets like this).'
            else
                short = 'your job file\'s code'
                when = 'GoomSwap never puts this set on by itself: your job file\'s code does, wherever it names it (or '
                    .. 'builds its name). Look for it in the Handle functions.'
            end
        end
        short = short or (string.match(when, '^(.-)%. ') or when)
        if set.name == 'BluMagical' then
            short = 'Magical Blue Magic (midcast)'
            when =
                'In the standard BLU profile, this layers over Midcast for Blue Magic spells outside the physical spell list. Later spell-specific sets and overlays can replace its slots.'
        elseif set.name == 'BluPhysical' then
            short = 'Physical Blue Magic (midcast)'
            when =
                'In the standard BLU profile, this layers over Midcast for spells in the physical Blue Magic list. Later spell-specific sets and overlays can replace its slots.'
        end
        local room = ctx.CELL_W * ctx.GRID_COLUMNS + 8 - text_w('Used for ') - text_w('    15 of 16 slots')
        imgui.TextColored(palette.dim, 'Used for')
        if imgui.IsItemHovered() then set_tip(wrap(when, 68)) end
        imgui.SameLine(0, 4)
        imgui.TextColored(palette.blue, cardText.Fit(short:gsub('^When ', ''):gsub('^While ', ''), room, text_w))
        if imgui.IsItemHovered() then set_tip(wrap(when, 68)) end
        if filled ~= nil then imgui.SameLine(0, 16) end
    end
    slots_line()
    meter()
    if set.note ~= nil then -- the job file's own note on the set (Foe = { -- Lullaby keeps your weapons)
        imgui.TextColored(palette.dim, cardText.Fit('Note: ' .. set.note, ctx.CELL_W * ctx.GRID_COLUMNS + 8, text_w))
        if imgui.IsItemHovered() then set_tip(wrap('From the job file, beside ' .. set.name .. ':\n' .. set.note, 68)) end
    end
    imgui.EndChild()
    imgui.PopStyleColor()
    if (editorState.document.deleted or {})[set.name] then
        imgui.TextColored(palette.bad, 'This set will be deleted on Save + reload.')
        if imgui.Button('Undo deletion##gcedit') then
            editorState.document.deleted[set.name] = nil
            editorState.document.revision = editorState.document.revision + 1
            feedback('Cancelled deletion of ' .. set.name .. '.')
        end
        return
    end
    if set.code ~= nil then
        imgui.TextColored(palette.dim, 'Written as code, not a table of slots: edit it in the file.')
        imgui.TextColored(palette.dim, string.sub(set.code, 1, 120))
        return
    end
    -- a set of sets (Buffs = { ['Aftermath: Lv.3'] = {...} }): its sets, and a new one by key
    local holder = (set.children ~= nil) or ((set.parentName == nil) and not set.new and (set.close ~= nil)
        and (set.count == 0) and BUFF_HOLDERS[set.lname])
    if holder then
        local doc = editorState.document
        imgui.TextColored(palette.dim, 'A set per buff, worn while that buff is up. Click one to edit it.')
        for _, s in ipairs(doc.model.list) do
            if (s.parentName == set.name) and imgui.Button(s.key .. '##gcchild_' .. s.name) then go_to(s.name) end
        end
        if set.parentName == nil then
            editorState.ui.childKey = editorState.ui.childKey or { '' }
            imgui.PushItemWidth(240)
            imgui.InputTextWithHint('##gcchild_key', 'Buff name: Aftermath: Lv.3', editorState.ui.childKey, 64)
            imgui.PopItemWidth()
            if imgui.IsItemHovered() then
                set_tip('The buff\'s name as the game shows it (Aftermath: Lv.3, Haste).')
            end
            local key = string.match(editorState.ui.childKey[1] or '', '^%s*(.-)%s*$')
            local taken = doc.model.byLower[string.lower(set.name .. "['" .. key .. "']")] ~= nil
            imgui.SameLine()
            if imgui.Button('New buff set##gcchild_new') and (key ~= '') and not taken
                and not string.find(key, '[\r\n]') then
                editorState.ui.childKey[1] = ''
                make_set(nil, nil, false, set, key)
            end
            if taken then imgui.TextColored(palette.warn, key .. ' exists in ' .. set.name .. '.') end
        end
        local direct = false
        for _ in pairs(set.slots) do direct = true end
        if direct then
            imgui.TextColored(palette.warn, 'Slots written directly in ' .. set.name .. ' are never worn: '
                .. 'each key is read as a buff. Move them into a buff set in the file.')
        end
        if set.extra and (set.children == nil) then
            imgui.TextColored(palette.dim, 'Holds more than slots: edit it in the file.')
        end
        return
    end
    if set.extra then
        imgui.TextColored(palette.dim, 'Holds more than slots (a nested set): edit it in the file.')
        return
    end
    local gaps = empty_armor(set)
    if (gaps ~= nil) and (#gaps > 0) then
        imgui.PushTextWrapPos(0)
        imgui.TextColored(
            (set.name == 'Tp_Default') and palette.dim or palette.warn,
            'Empty: ' .. table.concat(gaps, ' ') .. ' (' .. BASE[set.name] .. ')'
        )
        imgui.PopTextWrapPos()
    end
    local other = cmp_of(set)
    if other ~= nil then
        local n = 0
        for _, slot in ipairs(SCREEN) do
            if differs(set, other, slot) then n = n + 1 end
        end
        imgui.TextColored(
            palette.aug,
            string.format(
                'Comparing with %s: %d slot%s differ%s', other.name, n, (n == 1) and '' or 's', (n == 1) and 's' or ''
            )
        )
        imgui.SameLine()
        if imgui.SmallButton('Stop##gcedit_cmp') then editorState.ui.cmp = nil end
    end
    local H = editorState.history
    -- Redo holds what Undo took back; any other edit since (a new undo entry on top) empties it
    local redo = H.redo
    if (redo ~= nil) and ((#(H.entries or NONE) ~= redo.at) or ((H.entries or NONE)[redo.at] ~= redo.top)) then
        H.redo, redo = nil, nil
    end
    local function put(u, value) -- a slot's pending edit back to value (nil: as saved)
        local doc = editorState.document
        if (not doc.model.byName[u.set]) or doc.deleted[u.set] then return false end
        doc.edits[u.set] = doc.edits[u.set] or {}
        local was = doc.edits[u.set][u.slot]
        doc.edits[u.set][u.slot] = value
        if next(doc.edits[u.set]) == nil then doc.edits[u.set] = nil end
        doc.revision = doc.revision + 1
        H.revision = doc.revision
        editorPreferences.Select(editorState, u.set, u.slot)
        return true, was
    end
    local function mark()
        H.redo.at = #H.entries
        H.redo.top = H.entries[#H.entries]
    end
    if H.entries and #H.entries > 0 then
        if sbutton('Undo edit##gcedit', 'ghost') then
            local u = table.remove(H.entries)
            local ok, was = put(u, u.previous)
            if ok then
                H.redo = H.redo or { list = {} }
                H.redo.list[#H.redo.list + 1] = { set = u.set, slot = u.slot, value = was }
                mark()
                feedback('Undid the last edit to ' .. u.set .. ' / ' .. u.slot .. '.')
            end
        end
        editorPanels.SameLineIfFits(imgui, 140)
    end
    if (H.redo ~= nil) and (#H.redo.list > 0) then
        if sbutton('Redo##gcedit_redo', 'ghost') then
            local r = table.remove(H.redo.list)
            local doc = editorState.document
            local before = doc.edits[r.set] and doc.edits[r.set][r.slot]
            if put(r, r.value) then
                H.entries[#H.entries + 1] = { set = r.set, slot = r.slot, previous = before }
                mark()
                feedback('Redid the edit to ' .. r.set .. ' / ' .. r.slot .. '.')
            end
        end
        local r = (H.redo ~= nil) and H.redo.list[#H.redo.list] or nil -- the next one (none after the last)
        if (r ~= nil) and imgui.IsItemHovered() then
            set_tip('Put back what Undo took out: ' .. r.set .. ' / ' .. r.slot .. '.')
        end
        editorPanels.SameLineIfFits(imgui, 140)
    end
    local winfo = ctx.weapon_set_info(set)
    if sbutton('Use worn##gcedit', 'plain') then
        use_worn(set)
        feedback('Copied worn ' .. ((winfo ~= nil) and 'weapons' or 'gear') .. ' into ' .. set.name .. ' (unsaved).')
    end
    if imgui.IsItemHovered() then
        set_tip((winfo ~= nil) and 'Put the Main, Sub, Range and Ammo you wear right now into this set: a Weapon_ set '
            .. 'puts on nothing else (not saved until Save).' or 'Put what you wear right now into this set (not saved until Save).')
    end
    editorPanels.SameLineIfFits(imgui, 140)
    if sbutton('Copy from...##gcedit', 'plain') then
        editorState.ui.copyFind[1], editorState.ui.pickMode = '', 'copy'
        editorState.ui.openSetChooser = true
    end
    if imgui.IsItemHovered() then
        set_tip('Fill this set from another (Dt, Idle...), then change only what differs.')
    end
    editorPanels.SameLineIfFits(imgui, 140)
    if sbutton('Compare...##gcedit', 'plain') then
        editorState.ui.copyFind[1], editorState.ui.pickMode = '', 'compare'
        editorState.ui.openSetChooser = true
    end
    if imgui.IsItemHovered() then set_tip('Outline the slots where this set and another differ.') end
    editorPanels.SameLineIfFits(imgui, 140)
    local wmode = (ctx.weapon_set_mode ~= nil) and ctx.weapon_set_mode(set) or nil
    if wmode ~= nil then -- a /wm mode's set: its _1h and /mset weapon sets, and the layers over Tp_Default...
        if sbutton('Weapon sets...##gcws_open', 'plain') then editorState.ui.requestWeaponSets = wmode end
        if imgui.IsItemHovered() then
            set_tip('Every set /wm ' .. wmode .. ' can have (Weapon_' .. wmode .. '_1h, its /mset weapon sets, '
                .. 'Tp_' .. wmode .. ' over Tp_Default...): tick the missing ones and make them.')
        end
        editorPanels.SameLineIfFits(imgui, 140)
    end
    if draw_set_actions(set) then return end
    if winfo ~= nil then draw_weapon_checks(set, winfo) end
    help(
        '- Click a slot: pick gear for it on the right.\n'
            .. '- Right-click a slot: inspect its item, choose gear, undo or clear.\n'
            .. 'Bag colour:\n'
            .. '- green: you can equip from it\n'
            .. '- orange: move it to a wardrobe first\n'
            .. '- red: you do not own it\n'
            .. 'Aug / Path: the file lists augments (hover the slot).\n'
            .. 'Blue outline: the slot being edited. Amber: unsaved changes. Violet: unfinished RP.\n'
            .. 'An unsaved card keeps its amber fill while selected. Path/rank has its own footer row.\n'
            .. 'Replaced labels (Unsaved > source on an edited slot) use the action selected on the right.'
    )
    imgui.Spacing()
    -- a Weapon_ set: its weapon row only (Main, Sub, Range, Ammo: all a weapon mode puts on), the rest while old
    -- armor in it still needs clearing
    local only = ((winfo ~= nil) and (#winfo.armor == 0)) and 4 or #SCREEN
    for i, slot in ipairs(SCREEN) do
        if i > only then break end
        if (i - 1) % ctx.GRID_COLUMNS ~= 0 then imgui.SameLine() end
        draw_cell(set, slot)
    end
    if only < #SCREEN then
        imgui.TextColored(palette.dim, 'Weapons only. Armor for fighting with /wm ' .. winfo.mode .. ': Tp_'
            .. winfo.mode .. ' (Weapon sets... makes it).')
    end
    if set.oneLine then
        imgui.TextColored(palette.dim, 'This set is on one line: saving rewrites it one slot a line.')
    end
end

-- The game's modes now, for the circumstance boxes.
local function wi_from_game()
    local wi = editorState.ui.wi
    local ok = not editorState.document.inactive and (gcdisplay ~= nil)
    local cur = ok and gcdisplay.GetCycle('MeleeSet') or nil
    for _, m in ipairs(ok and (gcdisplay.GetCycleValues('MeleeSet') or {}) or {}) do
        wi.ms[m] = { m == cur }
    end
    wi.high[1] = ok and (gcdisplay.GetCycle('WsSet') == 'High') or false
    wi.dt[1] = ok and (gcdisplay.GetToggle('DTset') == true) or false
    wi.hoxne[1] = ok and (gcdisplay.GetCycle('Hoxne') == 'Locked') or false
    wi.proc[1] = ok and (gcdisplay.GetToggle('PROC') == true) or false
end

-- The /mset modes: the file's gcinclude.MeleeModes ({...} or T{...}), else the engine's, then modes added here and
-- not saved yet. Read by gcsetfile, as Save writes it; once per file text and new mode, not every frame.
local function melee_modes()
    local doc, c = editorState.document, editorState.cache
    if (c.modes ~= nil) and (c.modesN == #doc.newModes) and (c.modesText == doc.model.text) then return c.modes end
    local list = ctx.setFile.MeleeModes(doc.model.text, doc.newModes)
    c.modes, c.modesN, c.modesText = list, #doc.newModes, doc.model.text
    return list
end

-- A group's circumstances, against the game now: true when every one is on (the action's own state counts as on).
local function conds_on(conds, now)
    for _, c in ipairs(conds) do
        local m = string.match(c, '^melee mode (.+)$')
        local im = string.match(c, '^idle mode (.+)$')
        local ok
        if (c == 'engaged') or (c == 'idle') then
            ok = true
        elseif m ~= nil then
            ok = (now.mset == m)
        elseif im ~= nil then
            ok = (now.idleset == im)
        elseif c == 'WS high-buff mode' then
            ok = (now.wsset == 'High')
        elseif c == 'DT mode' then
            ok = now.dt
        elseif c == 'proc mode' then
            ok = now.proc
        elseif c == 'Hoxne' then
            ok = (now.hoxne == 'Locked')
        else
            ok = false
        end -- buffs up, cast on whom, a burst: not known here
        if not ok then return false end
    end
    return true
end

    return { describe = describe, cmp_of = cmp_of, inspection_target = inspection_target, inspect_item = inspect_item,
        set_stats = set_stats, ignored_suggestion_names = ignored_suggestion_names, draw_layers = draw_layers,
        set_action_entries = set_action_entries, draw_set = draw_set, wi_from_game = wi_from_game,
        melee_modes = melee_modes, conds_on = conds_on }
end
