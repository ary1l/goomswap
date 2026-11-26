-- /gcedit's Rules page: the job file's gcinclude.Rules (gcrules.lua) as a list, and a builder for one rule: when
-- (phase), if (conditions from a menu), wear (a set, items), layer, stop. Edits are staged like set edits and
-- written by the editor's Save as `gcinclude.Rules = {...}` (one rule a line). The middle pane shows it while
-- editorState.selection.rules is on (the RULES row at the top of the set list).
-- o: { imgui, palette, set_tip, editorState, files (gceditsettings), setFile, feedback, ctx }
return function(o)
    local imgui, palette, set_tip, editorState, files, setFile, feedback, ctx =
        o.imgui, o.palette, o.set_tip, o.editorState, o.files, o.setFile, o.feedback, o.ctx
    local R = gFunc.LoadFile('common\\gcrules.lua')
    local Conv = gFunc.LoadFile('common\\gcconvert.lua')
    local Check = gFunc.LoadFile('common\\gcconvertcheck.lua') -- the same-gear check, a little each frame
    -- 'while 265 is up' -> 'while Flurry is up'. The game gives some buffs one name (265 and 581 are both
    -- 'Flurry'): those keep their number, 'Flurry (581)', so two choices never read the same.
    local buffShared = nil
    R.BuffName = function(id)
        local res = AshitaCore:GetResourceManager()
        local name = res:GetString('buffs.names', id)
        if (type(name) ~= 'string') or (name == '') then return nil end
        if buffShared == nil then -- every buff's name, once: which names more than one id has
            buffShared = {}
            local seen = {}
            for i = 0, 1023 do
                local n = res:GetString('buffs.names', i)
                if (type(n) == 'string') and (n ~= '') then
                    local k = string.lower(n)
                    if seen[k] then buffShared[k] = true else seen[k] = true end
                end
            end
        end
        if buffShared[string.lower(name)] then return name .. ' (' .. tostring(id) .. ')' end
        return name
    end
    local W = gFunc.LoadFile('common\\gceditwidgets.lua')(imgui, palette, set_tip)
    local M = { R = R }

    local OP_WORDS = { is = 'is', isnt = 'is not', has = 'has', start = 'starts with', ends = 'ends with',
        lt = '<', le = '<=', gt = '>', ge = '>=', eq = '=', ne = 'not' }
    local CYCLE_NAMES = { 'wm', 'mset', 'nukeset', 'idleset', 'wsset', 'tankset', 'weapon', 'pupmode', 'hoxne', 'mw',
        'sw', 'rw', 'ammoset' }
    local TOGGLE_NAMES = { 'dt', 'mdt', 'kite', 'th', 'sir', 'proc', 'burst', 'aminon', 'death', 'songlock',
        'forcestring' }
    local TOP_NOTE = 'Goes on last, over everything GoomSwap adds by itself (weapon mode, TH, Hoxne, buff sets, obi, '
        .. 'SIR). Only these still win over it: /lock, the TP and Aftermath weapon holds, the Incapacitated, Sleeping and '
        .. 'Doomed sets, SmartSwap keeping your weapons, and Daybreak for Dispelga.'
    local JOB_NOTE = 'Goes on right after your job file\'s own gear for this moment (as if it were one more line of it). '
        .. 'What GoomSwap adds by itself (weapon mode, TH, Hoxne, buff sets, obi, SIR) still goes on after it and wins '
        .. 'the slots both use.'
    -- Where Convert left gcinclude.RulesAt('Midcast 2'), read from the job file (as it will be once a staged Convert
    -- is saved): what comes right after it, 'before skill set'.
    local spotCache, planSpots = {}, {}
    local function spot_info(at, plan, text0)
        if plan ~= nil then -- a plan not staged yet: its spots in the file as Convert would leave it
            if planSpots.plan ~= plan then
                local t = (setFile.Apply ~= nil) and setFile.Apply(text0, plan.splices) or nil
                local ok, info = pcall(Conv.Spots, t)
                planSpots = { plan = plan, info = ok and info or {} }
            end
            return planSpots.info[tostring(at)]
        end
        local doc = editorState.document
        local text = (doc ~= nil) and (doc.model ~= nil) and doc.model.text or nil
        if text == nil then return nil end
        local key = text
        if doc.convert ~= nil then key = doc.convert end
        if spotCache.key ~= key then
            local t = text
            if (doc.convert ~= nil) and (setFile.Apply ~= nil) then t = setFile.Apply(doc.convert.text, doc.convert.splices) or text end
            local ok, info, read = pcall(Conv.Spots, t)
            spotCache = { key = key, info = ok and info or {}, read = ok and (read == true) }
        end
        return spotCache.info[tostring(at)]
    end
    -- A rule's spot whose gcinclude.RulesAt line is not in the job file (deleted by hand): the rule never goes on.
    local function spot_missing(at)
        if at == nil then return false end
        local i = spot_info(at)
        return (i == nil) and (spotCache.read == true)
    end
    local function spot_label(at, plan, text0)
        local i = spot_info(at, plan, text0)
        if i == nil then return 'code spot ' .. (string.match(tostring(at), '(%d+)$') or tostring(at)) end
        return i.before and ('before ' .. i.short) or i.short
    end
    local function spot_tip(at, plan, text0)
        local i = spot_info(at, plan, text0)
        local where = (i == nil) and 'where its code used to be in your job file'
            or (i.before and ('where its code was in your job file: just before ' .. i.long .. ' (line ' .. i.line
                .. '), so that still wins the slots both wear') or ('where its code was: ' .. i.long))
        return 'This rule goes on ' .. where .. '. Convert left one line there, gcinclude.RulesAt(\'' .. tostring(at)
            .. '\'), which puts on the rules marked like this, in the order listed.\n\n'
            .. 'A rule without this tag goes on after all of your job file\'s own code (job layer).'
    end

    local function trim(s) return (string.match(s or '', '^%s*(.-)%s*$')) end
    local function copy(v)
        if type(v) ~= 'table' then return v end
        local out = {}
        for k, x in pairs(v) do out[k] = copy(x) end
        return out
    end
    local function rules_text(v, ind) return R.Serialize(v, ind, setFile.QuoteText, setFile.FormatKey) end

    -- The rules as staged (else as the file has them); nil and why when they are code in the file.
    function M.List()
        local v, how = files.Job('Rules')
        if (how == 'code') or string.match(how or '', '^set in') then return nil, how end
        return (type(v) == 'table') and v or {}, how
    end
    function M.Count()
        local list = M.List()
        return (list ~= nil) and #list or 0
    end
    -- A rule's moment and conditions in words, without what it wears: 'When you cast Cure on yourself'.
    local function moment_words(on, when)
        return (string.gsub(R.Say({ on = on, when = when }), ': nothing$', ''))
    end
    -- The rules that wear a set (its "Used for" line): { short, text }, nil when none do.
    function M.UsesOf(name)
        local list = M.List()
        if (list == nil) or (type(name) ~= 'string') then return nil end
        local lines = {}
        local function add(rule, on, extra)
            if (type(rule.wear) == 'string') and (string.lower(rule.wear) == string.lower(name)) and not rule.off then
                lines[#lines + 1] = moment_words(on, rule.when) .. (extra or '')
            end
        end
        for _, rule in ipairs(list) do
            if type(rule) == 'table' then
                if type(rule.first) == 'table' then
                    for _, m in ipairs(rule.first) do
                        add(m, rule.on, (rule.when ~= nil) and (' (in the group: ' .. moment_words(rule.on, rule.when) .. ')') or nil)
                    end
                else
                    add(rule, rule.on)
                end
            end
        end
        if #lines == 0 then return nil end
        return { short = 'a rule: ' .. lines[1] .. ((#lines > 1) and (' (+' .. (#lines - 1) .. ')') or ''),
            text = 'Rules that wear it (RULES, top of the set list):\n' .. table.concat(lines, '\n') }
    end

    -- Staged for Save: the whole list (none: the line goes).
    function M.Stage(list)
        if #list == 0 then
            files.StageJob('Rules', files.REMOVE)
        else
            files.StageJob('Rules', list, nil, rules_text)
        end
        editorState.ui.ruleProblems = nil
    end
    M.Serialize = rules_text

    -- == The list ==
    -- == Looks: buttons by what they do, and labels on a rounded fill: the editor's one copy (gceditwidgets) ==
    local vec, button, pill = W.Vec, W.Button, W.Pill
    M.Button = button
    local PA, PB = { 0, 0 }, { 0, 0 } -- the outlines' corners (cards, the Reads box)
    local function chip(text, fg, bg)
        imgui.SameLine(0, 10)
        pill(text, fg, bg or palette.chipBg)
    end
    local function short(text, n)
        if #text <= n then return text end
        return string.sub(text, 1, n - 3) .. '...'
    end
    local function xw(a) -- an ImGui vector's x: two numbers or a table, by Ashita version
        if type(a) == 'table' then return a.x or a[1] or 0 end
        return a or 0
    end
    -- text cut with ... to the room left on this line (the whole of it on hover)
    local function fit(text)
        local avail = xw(imgui.GetContentRegionAvail()) - 8
        if (avail <= 0) or (xw(imgui.CalcTextSize(text)) <= avail) then return text end
        local lo, hi = 0, #text
        while lo < hi do -- the most characters that fit, with the dots
            local mid = math.floor((lo + hi + 1) / 2)
            if xw(imgui.CalcTextSize(string.sub(text, 1, mid) .. '...')) <= avail then lo = mid else hi = mid - 1 end
        end
        return string.sub(text, 1, lo) .. '...'
    end
    -- A card: an outline from where it starts to the pane's right edge, under what was drawn since `top`.
    local function card_start()
        local x, y = vec(imgui.GetCursorScreenPos())
        local w = xw(imgui.GetContentRegionAvail())
        imgui.BeginGroup()
        imgui.Dummy({ 1, 2 })
        imgui.Indent(8)
        return { x = x, y = y, w = w }
    end
    local function card_end(c, col)
        imgui.Unindent(8)
        imgui.Dummy({ 1, 2 })
        imgui.EndGroup()
        local dl = (imgui.GetWindowDrawList ~= nil) and imgui.GetWindowDrawList() or nil
        if (dl == nil) or (type(dl) == 'boolean') or (imgui.GetItemRectMax == nil) or (imgui.GetColorU32 == nil)
            or (c.x == nil) or (c.y == nil) or (c.w == nil) then return end
        local _, y2 = vec(imgui.GetItemRectMax())
        if y2 == nil then return end
        PA[1], PA[2], PB[1], PB[2] = c.x, c.y, c.x + c.w - 2, y2
        dl:AddRect(PA, PB, imgui.GetColorU32(col or palette.edge), 5, 0, 1)
    end
    -- Quiet text buttons, pushed to the card's right edge when they fit there.
    local function pad()
        local st = (imgui.GetStyle ~= nil) and imgui.GetStyle() or nil
        local p = (type(st) == 'table' or type(st) == 'userdata') and st.FramePadding or nil
        local x = (type(p) == 'table' or type(p) == 'userdata') and (p.x or p[1]) or nil
        return tonumber(x) or 4
    end
    local function width_of(labels)
        local w, p = 0, pad()
        for _, l in ipairs(labels) do w = w + (xw(imgui.CalcTextSize(l)) or 0) + 2 * p + 4 end
        return w
    end
    local function window_x() return (imgui.GetWindowPos ~= nil) and vec(imgui.GetWindowPos()) or nil end
    -- Moved by the distance on screen, not to a window offset: inside the card's group ImGui adds the group's
    -- offset to SameLine(x), so a computed SameLine would land right of the card's edge.
    local function to_right(c, labels)
        local w = width_of(labels)
        imgui.SameLine(0, 12)
        local cx = vec(imgui.GetCursorScreenPos())
        local target = (c.x ~= nil) and (c.w ~= nil) and (c.x + c.w - 12 - w) or nil
        if (target ~= nil) and (cx ~= nil) and (target > cx) and (imgui.SetCursorPosX ~= nil) and (imgui.GetCursorPosX ~= nil) then
            imgui.SetCursorPosX(imgui.GetCursorPosX() + (target - cx))
        end
    end
    -- A sentence that wraps short of the buttons drawn beside it (on its first line, at the right).
    local function sentence_beside(c, text, col, labels)
        local wx = window_x()
        local wrap = 0
        if (c.x ~= nil) and (c.w ~= nil) and (wx ~= nil) then wrap = math.max(80, c.x - wx + c.w - 24 - width_of(labels)) end
        imgui.PushTextWrapPos(wrap)
        if col ~= nil then imgui.TextColored(col, text) else imgui.TextUnformatted(text) end
        imgui.PopTextWrapPos()
    end
    -- Where a rule goes on: its moment and its place (a code spot, or the job / top layer). Order only matters between
    -- rules with the same one (a later one wins the slots both wear); rules elsewhere never meet.
    local function place_of(r)
        if type(r) ~= 'table' then return nil end
        return tostring(r.on) .. '|' .. ((r.at ~= nil) and ('at ' .. tostring(r.at)) or ((r.layer == 'top') and 'top' or 'job'))
    end
    -- The nearest rule before (by -1) or after (by 1) i that goes on at the same place; nil when none.
    local function neighbour(list, i, group, by)
        if group ~= nil then -- a group's choices: their order is the first-that-fits order
            local j = i + by
            return (list[group].first[j] ~= nil) and j or nil
        end
        local mine = place_of(list[i])
        local j = i + by
        while (list[j] ~= nil) do
            if place_of(list[j]) == mine then return j end
            j = j + by
        end
        return nil
    end
    local function move(list, i, group, j) -- i and j trade places (the rules between them go on elsewhere)
        local out = copy(list)
        local arr = (group ~= nil) and out[group].first or out
        arr[i], arr[j] = arr[j], arr[i]
        M.Stage(out)
    end
    local function take_out(list, i, group)
        local out = copy(list)
        if group ~= nil then
            table.remove(out[group].first, i)
            if #out[group].first == 0 then table.remove(out, group) end
        else
            table.remove(out, i)
        end
        M.Stage(out)
        editorState.ui.ruleEdit = nil
        feedback('Rule taken out: written by Save.')
    end
    local function set_off(list, i, off)
        local out = copy(list)
        out[i].off = off or nil
        M.Stage(out)
    end
    -- Edit, Up, Down (and Off/On, Delete for a whole rule), as ghost buttons in one row.
    local function row_buttons(c, list, i, group)
        local id = (group ~= nil) and (tostring(group) .. '_' .. i) or tostring(i)
        local whole = list[group or i]
        -- Up / Down only where order can matter: another rule that goes on at the same moment and place
        local up, down = neighbour(list, i, group, -1), neighbour(list, i, group, 1)
        local labels = { 'Edit' }
        if up ~= nil then labels[#labels + 1] = 'Up' end
        if down ~= nil then labels[#labels + 1] = 'Down' end
        labels[#labels + 1] = 'Delete'
        if group == nil then labels[#labels + 1] = whole.off and 'On' or 'Off' end
        to_right(c, labels)
        if button('Edit##rule_edit_' .. id, 'ghost') then M.Edit(group or i, (group ~= nil) and i or nil) end
        local function said(j) -- the other rule, for the tip
            local r = (group ~= nil) and list[group].first[j] or list[j]
            return (group ~= nil) and ('choice ' .. j) or ('rule ' .. j .. ' (' .. short(R.Say(r), 60) .. ')')
        end
        if up ~= nil then
            imgui.SameLine(0, 4)
            if button('Up##rule_up_' .. id, 'ghost') then move(list, i, group, up) end
            if imgui.IsItemHovered() then
                set_tip((group ~= nil) and ('Before ' .. said(up) .. ': tried first.')
                    or ('Before ' .. said(up) .. '. Where both put gear in the same slot, the later one wins: this one '
                        .. 'would then lose to it.'))
            end
        end
        if down ~= nil then
            imgui.SameLine(0, 4)
            if button('Down##rule_down_' .. id, 'ghost') then move(list, i, group, down) end
            if imgui.IsItemHovered() then
                set_tip((group ~= nil) and ('After ' .. said(down) .. ': tried after it.')
                    or ('After ' .. said(down) .. '. Where both put gear in the same slot, the later one wins: this one '
                        .. 'would then win.'))
            end
        end
        if group == nil then
            imgui.SameLine(0, 4)
            if button((whole.off and 'On' or 'Off') .. '##rule_off_' .. id, 'ghost') then set_off(list, i, not whole.off) end
            if imgui.IsItemHovered() then
                set_tip(whole.off and 'Off: kept, not used. On: use it again.' or 'Keep it without using it.')
            end
        end
        imgui.SameLine(0, 4)
        if button('Delete##rule_del_' .. id, 'danger') then take_out(list, i, group) end
        if imgui.IsItemHovered() then set_tip('Take it out (Revert the job file to get it back before Save).') end
    end
    -- == A rule a set name already does: GoomSwap or your job file puts on a set named after the action (its named-set
    -- step: ByName(spell.Name), ByName(spell.Skill)...), or Idle_<pick> (gcinclude.EquipIdle). ==
    local stepCache = {}
    local function name_steps()
        local doc = editorState.document
        local text = (doc ~= nil) and (doc.model ~= nil) and doc.model.text or nil
        if (stepCache.steps == nil) or (stepCache.text ~= text) then
            local ok, st = pcall(Conv.NameSteps, text)
            stepCache = { text = text, steps = (ok and (type(st) == 'table')) and st or {} }
        end
        return stepCache.steps
    end
    -- The set name that would do this rule with no rule, the job file's line and what it does there; nil when none.
    -- Only a rule whose one condition is what a step names by (the action's name, skill, family, type; idle + a pick).
    local function name_cover(rule, phase)
        if (type(rule) ~= 'table') or rule.stop or (rule.item ~= nil) or (rule.first ~= nil) or (rule.layer == 'top') then
            return nil
        end
        local w = (type(rule.when) == 'table') and rule.when or {}
        local keys = {}
        for k in pairs(w) do keys[#keys + 1] = k end
        local steps = name_steps()
        if phase == 'Default' then -- Idle_<pick>: EquipIdle, standing idle
            if (steps.idle == nil) or (type(w.mode) ~= 'table') or (w.status ~= 'Idle') or (#keys ~= 2) then return nil end
            local mk, mv, n = nil, nil, 0
            for k, v in pairs(w.mode) do mk, mv, n = k, v, n + 1 end
            if (n ~= 1) or (type(mv) ~= 'string') or ((mk ~= 'wm') and (mk ~= 'idleset')) then return nil end
            return 'Idle_' .. mv, steps.idle.line, 'gcinclude.EquipIdle() puts on Idle_<your /' .. mk .. ' pick> while you '
                .. 'stand idle'
        end
        local st = steps[phase]
        if (st == nil) or (#keys ~= 1) then return nil end
        local k = keys[1]
        local v = w[k]
        if type(v) ~= 'string' then return nil end
        local best = nil
        for key, step in pairs(st) do
            local base, suffix = string.match(key, '^(%a+)(.*)$')
            if (base == k) and ((best == nil) or (suffix == '')) then best = { v .. suffix, step } end
        end
        if best == nil then return nil end
        return best[1], best[2].line, 'it puts on ' .. best[2].text
    end
    local function repeats(rule) -- the rule wears just what that step already wears there
        local cand, line = name_cover(rule, rule and rule.on)
        if (cand ~= nil) and (type(rule.wear) == 'string') and (string.lower(rule.wear) == string.lower(cand)) then
            return cand, line
        end
        return nil
    end
    M.NameCover = name_cover

    local function tags(rule)
        pill(R.PHASE_LABEL[rule.on] or tostring(rule.on), palette.blue, palette.selBg)
        if imgui.IsItemHovered() then set_tip('When it is checked: ' .. (R.PHASE_LONG[rule.on] or tostring(rule.on)) .. '.') end
        if spot_missing(rule.at) then
            chip('not running', palette.bad, palette.badBg)
            if imgui.IsItemHovered() then
                set_tip("This rule goes on at code spot '" .. tostring(rule.at) .. "', but your job file has no "
                    .. "gcinclude.RulesAt('" .. tostring(rule.at) .. "') line any more, so it never goes on. Edit, More, "
                    .. 'Use a layer instead (or put the line back in the file).')
            end
        elseif rule.at ~= nil then
            chip(spot_label(rule.at), palette.ok, palette.okBg)
            if imgui.IsItemHovered() then set_tip(spot_tip(rule.at)) end
        elseif rule.layer == 'top' then
            chip('over everything', palette.warn, palette.warnBg)
            if imgui.IsItemHovered() then set_tip(TOP_NOTE) end
        end
        if rule.stop then chip('cancels it', palette.bad, palette.chipBg) end
        local same, sameLine = repeats(rule)
        if same ~= nil then
            chip('repeats line ' .. sameLine, palette.warn, palette.warnBg)
            if imgui.IsItemHovered() then
                set_tip('Your job file already puts on ' .. same .. ' at this moment (line ' .. sameLine .. ', its named-set '
                    .. 'step), so this rule repeats it. Delete it, or keep it to also put ' .. same .. ' on later, over what '
                    .. 'your code puts on after that line.')
            end
        end
        if rule.off then chip('off', palette.dim, palette.chipBg) end
        if (rule.note or '') ~= '' then
            imgui.SameLine(0, 10)
            imgui.TextColored(palette.dim, short(rule.note, 40))
            if imgui.IsItemHovered() then set_tip(rule.note) end
        end
    end
    local function sentence(text, col)
        imgui.PushTextWrapPos(0)
        if col ~= nil then imgui.TextColored(col, text) else imgui.TextUnformatted(text) end
        imgui.PopTextWrapPos()
    end
    -- A rule as a card: what it does, as a sentence; under it its tags and its buttons.
    local function draw_rule_row(list, i)
        local rule = list[i]
        if type(rule) ~= 'table' then return end
        local editing = editorState.ui.ruleEdit
        local c = card_start()
        local col = rule.off and palette.dim or nil
        if type(rule.first) == 'table' then
            sentence(moment_words(rule.on, rule.when) .. ', the first that fits:', col)
            imgui.Indent(14)
            for j, m in ipairs(rule.first) do
                imgui.TextColored(palette.dim, j .. ')')
                imgui.SameLine(0, 6)
                sentence_beside(c, R.Say(m, rule.on), col, { 'Edit', 'Up', 'Down', 'Delete' })
                row_buttons(c, list, j, i)
            end
            if button('+ choice##rule_addc_' .. i, 'ghost') then M.Edit(i, #rule.first + 1) end
            if imgui.IsItemHovered() then set_tip('Another choice, tried after these.') end
            imgui.Unindent(14)
            tags(rule)
            to_right(c, { (rule.off and 'On' or 'Off'), 'Delete' })
            if button((rule.off and 'On' or 'Off') .. '##rule_off_' .. i, 'ghost') then set_off(list, i, not rule.off) end
            imgui.SameLine(0, 4)
            if button('Delete##rule_delg_' .. i, 'danger') then take_out(list, i) end
            if imgui.IsItemHovered() then set_tip('Take out the whole group.') end
        else
            sentence(R.Say(rule), col)
            tags(rule)
            row_buttons(c, list, i)
        end
        local on = (editing ~= nil) and (editing.index == i)
        card_end(c, on and palette.blue or nil)
        imgui.Spacing()
    end

    -- The RULES row at the top of the set list.
    -- How many ifs Convert could take from the open file (nothing staged); read once per file text.
    local convertible -- set below, with the Convert section
    local function summary()
        local n = M.Count()
        local k = (convertible ~= nil) and convertible() or 0
        return n, k
    end
    local function rules_tip(n, k)
        return 'Rules: when this, wear that, without code (a buff up, low MP, a spell on you, a mode...), saved in the '
            .. 'job file. ' .. ((n > 0) and (n .. ((n == 1) and ' rule' or ' rules') .. ' now. ') or 'None yet. ')
            .. ((k > 0) and (k .. ((k == 1) and ' if' or ' ifs') .. ' in your job file can be made into rules: Convert, '
            .. 'on the Rules page.') or '')
    end
    local LIST_W = { -1, 0 }
    -- The RULES button at the top of the set list: the whole width, blue.
    function M.ListButton()
        local n, k = summary()
        local sel = editorState.selection.rules == true
        -- the longest label that fits the pane: the set list is often narrow
        local rules = (n > 0) and (n .. ((n == 1) and ' rule' or ' rules')) or 'none yet'
        local labels = (k > 0) and { 'RULES  ' .. rules .. '  -  ' .. k .. ' to convert', 'RULES  ' .. n .. '  +' .. k
            .. ' to convert', 'RULES ' .. n .. ' +' .. k } or { 'RULES  ' .. rules, 'RULES ' .. n }
        local avail = xw(imgui.GetContentRegionAvail()) - 16
        local label = labels[#labels]
        for _, l in ipairs(labels) do
            if xw(imgui.CalcTextSize(l)) <= avail then label = l break end
        end
        if button(label .. '##gcedit_rules_row', sel and 'primary' or 'accent', true, false, LIST_W) then
            editorState.selection.rules = true
        end
        if imgui.IsItemHovered() then set_tip(rules_tip(n, k)) end
    end
    function M.TopLabel()
        local n, k = summary()
        return 'Rules' .. ((n > 0) and (' ' .. n) or '') .. ((k > 0) and ('  +' .. k .. ' to convert') or '')
    end
    -- The Rules button in the top bar: opens the page, or (open already) goes back to the set.
    function M.TopButton()
        local n, k = summary()
        local sel = editorState.selection.rules == true
        local label = M.TopLabel()
        if button(label .. '##gcedit_rules_top', sel and 'primary' or 'accent', true) then
            editorState.selection.rules = not sel
        end
        if imgui.IsItemHovered() then set_tip(rules_tip(n, k) .. (sel and '\n\nClick: back to the set.' or '')) end
    end

    -- == The builder ==
    local function value_text(v)
        if type(v) == 'table' then
            local out = {}
            for _, x in ipairs(v) do out[#out + 1] = tostring(x) end
            return table.concat(out, ', ')
        end
        if v == nil then return '' end
        return tostring(v)
    end
    local function row_state(r) -- a builder row: its boxes
        r.buf = r.buf or { value_text(r.value) }
        return r
    end
    -- A box's text as the row's value: a list when it has commas (any of them), a number for a number key.
    local function row_value(r)
        local meta = R.KEY[r.key] or {}
        if (meta.kind == 'bool') or (meta.kind == 'toggle') then return r.value end
        local text = trim(r.buf[1])
        if meta.kind == 'number' then return tonumber(text) end
        if text == '' then return nil end
        if string.find(text, ',', 1, true) then
            local list = {}
            for part in string.gmatch(text, '[^,]+') do
                local t = trim(part)
                if t ~= '' then list[#list + 1] = t end
            end
            return list
        end
        return text
    end

    function M.Edit(index, member)
        local list = M.List() or {}
        local rule, phase = nil, 'Midcast'
        if index ~= nil and list[index] ~= nil then
            phase = list[index].on or phase
            if member ~= nil then
                rule = copy((list[index].first or {})[member] or {})
            else
                rule = copy(list[index])
            end
        else
            rule = { on = 'Midcast' }
        end
        local rows, any = R.WhenToRows(rule.when)
        local e = { index = index, member = member, rule = rule, phase = phase, any = any or false,
            unsupported = (rows == nil), rows = {} }
        for _, r in ipairs(rows or {}) do e.rows[#e.rows + 1] = row_state(r) end
        e.wear = { rule.wear or '' }
        e.versions = { not rule.exact }
        e.items = {}
        for _, slot in ipairs(R.SLOTS) do
            local it = (rule.item or {})[slot]
            if it ~= nil then e.items[#e.items + 1] = { slot = slot, buf = { (type(it) == 'table') and it.Name or tostring(it) }, raw = it } end
        end
        e.top = { rule.layer == 'top' }
        e.stop = { rule.stop == true }
        e.note = { rule.note or '' }
        editorState.ui.ruleEdit = e
    end

    local function key_options(phase)
        local out = {}
        for _, k in ipairs(R.KEYS) do
            if (k.phases == nil) or k.phases[phase] then out[#out + 1] = { k.key, R.KeyLabel(k.key, phase) } end
        end
        return out
    end

    local function draw_row(e, i, r)
        local meta = R.KEY[r.key] or { label = r.key, kind = 'text' }
        local id = 'rb_' .. i
        local pick = W.Pick(id .. '_key', R.KeyLabel(r.key, e.phase), key_options(e.phase), 170)
        if pick ~= nil and pick ~= r.key then
            r.key, r.value, r.sub = pick, nil, nil
            local m = R.KEY[pick]
            r.op = (m.kind == 'number') and 'lt' or 'is'
            if m.kind == 'bool' then r.value = true end
            if m.kind == 'toggle' then r.value, r.sub = true, 'dt' end
            if m.kind == 'mode' then r.sub = 'wm' end
            r.buf = { '' }
            meta = m
        end
        local tip = meta.hint
        if imgui.IsItemHovered() and (tip ~= nil) then set_tip(R.KeyLabel(r.key, e.phase) .. ': ' .. tip) end
        imgui.SameLine()
        local values = nil
        if meta.kind == 'bool' then
            local v = W.Pick(id .. '_bool', (r.value == false) and 'no' or 'yes', { { true, 'yes' }, { false, 'no' } }, 80)
            if v ~= nil then r.value = v end
        elseif meta.kind == 'toggle' then
            local s = W.Pick(id .. '_sub', '/' .. (r.sub or 'dt'), TOGGLE_NAMES, 120)
            if s ~= nil then r.sub = s end
            imgui.SameLine()
            local v = W.Pick(id .. '_tv', (r.value == false) and 'off' or 'on', { { true, 'on' }, { false, 'off' } }, 80)
            if v ~= nil then r.value = v end
        else
            if meta.kind == 'mode' then
                local s = W.Pick(id .. '_sub', '/' .. (r.sub or 'wm'), CYCLE_NAMES, 120)
                if s ~= nil then r.sub = s end
            elseif meta.kind == 'number' then
                local op = W.Pick(id .. '_op', OP_WORDS[r.op or 'lt'], { { 'lt', '<' }, { 'le', '<=' }, { 'gt', '>' },
                    { 'ge', '>=' }, { 'eq', '=' }, { 'ne', 'not' } }, 120)
                if op ~= nil then r.op = op end
            elseif meta.kind ~= 'list' then
                local op = W.Pick(id .. '_op', OP_WORDS[r.op or 'is'], { { 'is', 'is' }, { 'isnt', 'is not' },
                    { 'has', 'has' }, { 'start', 'starts with' }, { 'ends', 'ends with' } }, 120)
                if op ~= nil then r.op = op end
            end
            if meta.kind ~= 'list' then imgui.SameLine() end
            imgui.PushItemWidth(220)
            local placeholder = meta.example or ((meta.kind == 'number') and 'a number')
                or ((meta.values ~= nil) and 'pick below, or type') or 'a name; several: commas'
            imgui.InputTextWithHint('##' .. id .. '_val', placeholder, r.buf, 128)
            imgui.PopItemWidth()
            if imgui.IsItemHovered() then
                set_tip(((tip ~= nil) and (tip .. '\n\n') or '') .. ((meta.kind == 'number') and 'A number.'
                    or ('As the game writes it. Several, separated by commas: any of them.'
                    .. ((r.op == 'has' or r.op == 'start' or r.op == 'ends') and ' Upper and lower case count.' or ''))))
            end
            values = meta.values
            if meta.kind == 'mode' and (gcdisplay ~= nil) and (gcdisplay.GetCycleValues ~= nil) then
                values = gcdisplay.GetCycleValues(R.CYCLES[r.sub or 'wm'] or r.sub)
            end
        end
        imgui.SameLine()
        local gone = button('x##' .. id .. '_x', 'danger') -- right after its value, before the choices below
        if imgui.IsItemHovered() then set_tip('Take this condition out.') end
        -- the values this key can have: a click puts one in the box (wrapped to the pane)
        if (values ~= nil) and (#values > 0) then
            imgui.Indent(24)
            imgui.TextColored(palette.dim, 'pick:')
            local used, avail = 0, xw(imgui.GetContentRegionAvail())
            used = xw(imgui.CalcTextSize('pick:')) + 8
            for j, v in ipairs(values) do
                local w = xw(imgui.CalcTextSize(tostring(v))) + 12
                if (used + w + 4 <= avail) or (j == 1) then imgui.SameLine(0, 4) else used = 0 end
                used = used + w + 4
                if button(tostring(v) .. '##' .. id .. '_v' .. j, 'ghost') then
                    local cur = trim(r.buf[1])
                    r.buf[1] = (cur == '') and tostring(v) or (cur .. ', ' .. tostring(v))
                end
                if imgui.IsItemHovered() then set_tip('Puts ' .. tostring(v) .. ' in the box (several: any of them).') end
            end
            imgui.Unindent(24)
        end
        return gone
    end

    local function set_names()
        local out = {}
        for _, s in ipairs(((editorState.document or {}).model or {}).list or {}) do out[#out + 1] = s.name end
        return out
    end
    local function has_set(name)
        local model = (editorState.document or {}).model
        return (model ~= nil) and (model.byName ~= nil) and (model.byName[name] ~= nil)
    end

    -- The rule the builder shows, as data; nil and why when it isn't one yet.
    local function built(e)
        local rule = {}
        if e.member == nil then rule.on = e.phase end
        if not e.unsupported then
            local rows = {}
            for _, r in ipairs(e.rows) do
                local v = row_value(r)
                local meta = R.KEY[r.key] or {}
                if (v == nil) and (meta.kind ~= 'bool') then
                    return nil, (meta.label or r.key) .. ': give it a value'
                end
                rows[#rows + 1] = { key = r.key, op = r.op or 'is', sub = r.sub, value = v }
            end
            rule.when = R.RowsToWhen(rows, e.any)
        else
            rule.when = copy(e.rule.when)
        end
        local wear = trim(e.wear[1])
        if wear ~= '' then
            rule.wear = wear
            if not e.versions[1] then rule.exact = true end
        end
        for _, it in ipairs(e.items) do
            local name = trim(it.buf[1])
            if name ~= '' then
                rule.item = rule.item or {}
                rule.item[it.slot] = ((type(it.raw) == 'table') and (it.raw.Name == name)) and copy(it.raw) or name
            end
        end
        if (e.member == nil) and (e.rule.at ~= nil) and not e.unspot then
            rule.at = e.rule.at
        elseif e.member == nil and e.top[1] then
            rule.layer = 'top'
        end
        if e.stop[1] and R.STOPPABLE[e.phase] then rule.stop = true end
        local note = trim(e.note[1])
        if note ~= '' then rule.note = note end
        if e.rule.off then rule.off = true end
        if (rule.wear == nil) and (rule.item == nil) and not rule.stop then
            return nil, 'Wear a set or an item, or stop the action'
        end
        return rule
    end

    -- A numbered step's label: '1  When', in the accent.
    local function step(n, label)
        imgui.TextColored(palette.blue, n .. '  ' .. label)
        imgui.SameLine(90)
    end
    -- An outline around the item just drawn (the Reads box), padded.
    local function outline(col)
        local dl = (imgui.GetWindowDrawList ~= nil) and imgui.GetWindowDrawList() or nil
        if (dl == nil) or (type(dl) == 'boolean') or (imgui.GetItemRectMin == nil) or (imgui.GetColorU32 == nil) then return end
        local x1, y1 = vec(imgui.GetItemRectMin())
        local x2, y2 = vec(imgui.GetItemRectMax())
        if (x1 ~= nil) and (y1 ~= nil) and (x2 ~= nil) and (y2 ~= nil) then
            PA[1], PA[2], PB[1], PB[2] = x1 - 6, y1 - 3, x2 + 6, y2 + 3
            dl:AddRect(PA, PB, imgui.GetColorU32(col), 4, 0, 1)
        end
    end
    local function draw_builder()
        local e = editorState.ui.ruleEdit
        if e == nil then return end
        imgui.TextColored(palette.text, (e.index == nil) and 'New rule' or ((e.member ~= nil) and ('Rule ' .. e.index
            .. ', choice ' .. e.member) or ('Rule ' .. e.index)))
        imgui.SameLine()
        imgui.TextColored(palette.dim, '-  the moment, what has to be true then, and what to put on.')
        imgui.Spacing()
        -- when
        step('1', 'When')
        if e.member ~= nil then
            imgui.TextUnformatted(R.PHASE_LONG[e.phase] .. ' (its group\'s)')
        else
            local options = {}
            for _, p in ipairs(R.PHASES) do options[#options + 1] = { p, R.PHASE_LONG[p] } end
            local p = W.Pick('rb_phase', R.PHASE_LONG[e.phase] or e.phase, options, 330)
            if p ~= nil then e.phase = p end
        end
        -- if
        step('2', 'If')
        if e.unsupported then
            imgui.TextColored(palette.warn, R.WhenWords(e.rule.when) .. '  (this shape is edited in the file)')
        else
            local m = W.Pick('rb_any', e.any and 'any of these' or 'all of these',
                { { false, 'all of these' }, { true, 'any of these' } }, 230)
            if m ~= nil then e.any = m end
            if #e.rows == 0 then
                imgui.SameLine()
                imgui.TextColored(palette.dim, '(no conditions: every time)')
            end
            imgui.Indent(90)
            local gone = nil
            for i, r in ipairs(e.rows) do
                if draw_row(e, i, r) then gone = i end
            end
            if gone ~= nil then table.remove(e.rows, gone) end
            if button('+ condition##rb_add', 'ghost') then
                e.rows[#e.rows + 1] = row_state({ key = 'buff', op = 'is' })
            end
            imgui.Unindent(90)
        end
        -- wear
        step('3', 'Wear')
        imgui.PushItemWidth(220)
        imgui.InputTextWithHint('##rb_wear', 'a set, by name', e.wear, 96)
        imgui.PopItemWidth()
        local wear = trim(e.wear[1])
        if (wear ~= '') and not has_set(wear) then
            imgui.SameLine()
            imgui.TextColored(palette.warn, 'no set by that name yet')
        end
        imgui.SameLine()
        imgui.Checkbox('with its weapon and /mset versions##rb_versions', e.versions)
        if imgui.IsItemHovered() then
            set_tip('Ticked: as a set worn by name (Savage Blade, then Savage Blade_Naegling, Savage Blade_Acc...). '
                .. 'Unticked: that set only.')
        end
        if (#wear >= 2) and not has_set(wear) then -- names that start like it
            imgui.Indent(90)
            local shown = 0
            for _, n in ipairs(set_names()) do
                if (shown < 8) and string.find(string.lower(n), string.lower(wear), 1, true) then
                    if shown == 0 then imgui.TextColored(palette.dim, 'your sets:') end
                    imgui.SameLine(0, 4)
                    shown = shown + 1
                    if button(n .. '##rb_set_' .. shown, 'ghost') then e.wear[1] = n end
                    if imgui.IsItemHovered() then set_tip('Wear your set ' .. n .. '.') end
                end
            end
            imgui.Unindent(90)
        end
        imgui.Indent(90)
        local goneItem = nil
        for i, it in ipairs(e.items) do
            local s = W.Pick('rb_islot_' .. i, it.slot, R.SLOTS, 90)
            if s ~= nil then it.slot = s end
            imgui.SameLine()
            imgui.PushItemWidth(220)
            imgui.InputTextWithHint('##rb_item_' .. i, 'an item, as the game shows it', it.buf, 96)
            imgui.PopItemWidth()
            imgui.SameLine()
            if button('x##rb_ix_' .. i, 'danger') then goneItem = i end
        end
        if goneItem ~= nil then table.remove(e.items, goneItem) end
        if button('+ one item##rb_additem', 'ghost') then
            e.items[#e.items + 1] = { slot = 'Head', buf = { '' } }
        end
        if imgui.IsItemHovered() then set_tip('One piece in one slot, without a set (Pixie Hairpin +1 on Noctohelix).') end
        imgui.Unindent(90)
        -- layer, cancel, note: folded under More (open when the rule uses one)
        if e.more == nil then
            e.more = (e.rule.layer == 'top') or (e.rule.stop == true) or ((e.rule.note or '') ~= '') or (e.rule.at ~= nil)
        end
        imgui.Spacing()
        if button((e.more and 'Less' or 'More: layer, cancel it, note') .. '##rb_more', 'ghost') then e.more = not e.more end
        if not e.more then
            -- nothing more shown
        elseif (e.member == nil) and (e.rule.at ~= nil) and not e.unspot then
            imgui.TextColored(palette.dim, 'Where')
            imgui.SameLine(90)
            imgui.TextUnformatted(spot_label(e.rule.at) .. ': where its code was in your job file')
            if imgui.IsItemHovered() then set_tip(spot_tip(e.rule.at)) end
            imgui.SameLine()
            if imgui.SmallButton('Use a layer instead##rb_unspot') then e.unspot = true end
            if imgui.IsItemHovered() then
                set_tip('The rule then goes on with the other rules (job layer or over everything), not at its spot.')
            end
        elseif e.member == nil then
            imgui.TextColored(palette.dim, 'Layer')
            imgui.SameLine(90)
            if button('Job layer##rb_job', (not e.top[1]) and 'accent' or 'plain') then e.top[1] = false end
            if imgui.IsItemHovered() then set_tip(JOB_NOTE) end
            imgui.SameLine()
            if button('Over everything##rb_top', e.top[1] and 'accent' or 'plain') then e.top[1] = true end
            if imgui.IsItemHovered() then set_tip(TOP_NOTE) end
            if e.top[1] then
                imgui.PushTextWrapPos(0)
                imgui.TextColored(palette.dim, TOP_NOTE)
                imgui.PopTextWrapPos()
            end
        end
        -- cancelling: only where LuAshitacast can (CancelAction), so only offered there
        if not e.more then
            if not R.STOPPABLE[e.phase] then e.stop[1] = false end
        elseif R.STOPPABLE[e.phase] then
            imgui.Checkbox('Cancel it instead (it is not used)##rb_stop', e.stop)
            if imgui.IsItemHovered() then
                set_tip('Rarely needed: when the conditions hold, the spell or ability is not used at all (a line in chat '
                    .. 'says why). Example: cancel Stun while your MP is under 10%.')
            end
            imgui.SameLine()
        else
            e.stop[1] = false
            imgui.TextColored(palette.dim, 'Note')
            imgui.SameLine(90)
        end
        if e.more then
            imgui.PushItemWidth(260)
            imgui.InputTextWithHint('##rb_note', 'a note for yourself (optional)', e.note, 96)
            imgui.PopItemWidth()
        end
        -- now
        local rule, why = built(e)
        imgui.Spacing()
        imgui.Indent(6)
        imgui.PushTextWrapPos(0)
        if rule ~= nil then
            local r2 = rule
            if (e.member ~= nil) and (r2.on == nil) then r2 = copy(rule); r2.on = e.phase end
            imgui.TextColored(palette.ok, R.Say(r2, e.phase))
            outline(palette.ok)
            -- a set name already does this: say so (or that the rule repeats it)
            local cand, line, what = nil, nil, nil
            if e.member == nil then cand, line, what = name_cover(r2, e.phase) end
            if cand ~= nil then
                imgui.Spacing()
                if (type(r2.wear) == 'string') and (string.lower(r2.wear) == string.lower(cand)) then
                    imgui.TextColored(palette.warn, 'Your job file already puts on ' .. cand .. ' at this moment (line '
                        .. line .. ': ' .. what .. '). This rule repeats it.')
                else
                    imgui.TextColored(palette.blue, 'A set named ' .. cand .. ' does this without a rule: line ' .. line
                        .. ' of your job file (' .. what .. '). Rename or copy ' .. tostring(r2.wear or 'the set') .. ' to '
                        .. cand .. ' and this rule isn\'t needed.')
                end
            end
        else
            imgui.TextColored(palette.warn, why)
            outline(palette.warn)
        end
        imgui.PopTextWrapPos()
        imgui.Unindent(6)
        imgui.Spacing()
        imgui.TextColored(palette.dim, 'Now')
        imgui.SameLine(90)
        if rule == nil then
            imgui.TextColored(palette.dim, '-')
        elseif (e.phase == 'Default') or (e.phase == 'Pet') then
            local api = (gcinclude ~= nil) and gcinclude.RulesApi or nil
            local holds = (api ~= nil) and (not editorState.document.inactive) and R.Holds(rule, e.phase, api) or nil
            if holds == nil then
                imgui.TextColored(palette.dim, 'checked in game, on the job it is for')
            else
                imgui.TextColored(holds and palette.ok or palette.dim, holds and 'its conditions hold now'
                    or 'its conditions do not hold now')
            end
        else
            imgui.TextColored(palette.dim, 'checked when you act: /gcedit last shows what went on, rule layers included')
        end
        -- save
        local off = (rule == nil) and (imgui.BeginDisabled ~= nil)
        if off then imgui.BeginDisabled() end
        if button('Save rule##rb_save', 'primary', true) and (rule ~= nil) then
            local out = copy(M.List() or {})
            if e.member ~= nil then
                rule.on = nil
                out[e.index].first = out[e.index].first or {}
                out[e.index].first[e.member] = rule
            elseif e.index ~= nil then
                if type(out[e.index].first) == 'table' then rule.first = out[e.index].first end
                out[e.index] = rule
            else
                out[#out + 1] = rule
            end
            M.Stage(out)
            editorState.ui.ruleEdit = nil
            feedback('Rule staged: written by Save' .. (editorState.document.inactive and '.' or ' + reload.'))
        end
        if off then imgui.EndDisabled() end
        imgui.SameLine()
        if button('Cancel##rb_cancel', 'plain', true) then editorState.ui.ruleEdit = nil end
    end

    -- == The job file's own code: what Convert turns into rules, and Adopt for a plain LuAshitacast file ==
    -- The plan for the file's text: at once the plain one (counts, the list), then the checked one once the same-gear
    -- check is done (a few ms each frame while the editor is open); Convert waits for it.
    local function plan_of(text)
        local c = editorState.ui.convertPlan
        if (c == nil) or (c.text ~= text) then
            local plan, why = Conv.Plan(text)
            c = { text = text, plan = plan, why = why, adoptable = not Conv.IsGoomSwap(text) }
            local any = false
            for _, h in ipairs((plan ~= nil) and plan.handlers or {}) do
                for _, it in ipairs(h.items) do if it.ok then any = true end end
            end
            if any then c.job = Check.Job(text, { engine = (o.ctx ~= nil) and o.ctx.gearEngine or nil }) else c.ready = true end
            editorState.ui.convertPlan = c
        end
        if (c.job ~= nil) and c.job.Step(o.checkBudget or 0.004) then
            if c.job.plan ~= nil then c.plan = c.job.plan else c.checkFailed = c.job.why end
            c.job, c.ready = nil, true
        end
        return c
    end
    convertible = function()
        local doc = editorState.document
        if (doc == nil) or (doc.convert ~= nil) or (doc.model == nil) or (doc.model.text == nil) then return 0 end
        local c = plan_of(doc.model.text)
        if c.plan == nil then return 0 end
        local k = 0
        for _, h in ipairs(c.plan.handlers) do
            for _, it in ipairs(h.items) do
                if it.ok then k = k + 1 end
            end
        end
        return k
    end
    local function stage_convert(c, adopt)
        local doc = editorState.document
        local list = M.List() or {}
        local conv = { text = c.text, splices = {}, lines = {}, prior = copy(list), title = 'Code made into rules' }
        if adopt then
            local a, why = Conv.Adopt(c.text)
            if a == nil then
                feedback('Not adopted: ' .. tostring(why) .. '.')
                return
            end
            for _, sp in ipairs(a.splices) do conv.splices[#conv.splices + 1] = sp end
            for _, l in ipairs(a.lines) do conv.lines[#conv.lines + 1] = l end
            conv.title = 'GoomSwap added (Adopt)' .. ((c.plan ~= nil and #c.plan.rules > 0) and ', and code made into rules' or '')
        end
        local out = copy(list)
        if c.plan ~= nil then
            for _, sp in ipairs(c.plan.splices) do conv.splices[#conv.splices + 1] = sp end
            for _, h in ipairs(c.plan.handlers) do
                for _, it in ipairs(h.items) do
                    if it.ok then
                        conv.lines[#conv.lines + 1] = h.name .. ' line ' .. it.line .. ': ' .. #it.rules
                            .. ((#it.rules == 1) and ' rule' or ' rules') .. ((it.spot ~= nil) and (', at ' .. it.spot) or '')
                    end
                end
            end
            for _, r in ipairs(c.plan.rules) do out[#out + 1] = copy(r) end
            conv.plan = c.plan
        end
        doc.convert = conv
        M.Stage(out)
        feedback(conv.title .. ': written by Save. Undo convert takes it back.')
    end
    local function paragraph(text, col)
        imgui.PushTextWrapPos(0)
        imgui.TextColored(col or palette.dim, text)
        imgui.PopTextWrapPos()
    end
    -- What Convert changes, one card per `if`: its code (first line; all of it on hover) and the rules it becomes,
    -- or why it stays code. want: 'ok' (the ones that convert) or 'stays'.
    local function draw_changes(plan, text, want)
        local std, shown = 0, 0
        for _, h in ipairs(plan.handlers) do
            for _, it in ipairs(h.items) do
                if it.standard then
                    std = std + 1
                elseif (want == 'ok') == (it.ok == true) then
                    shown = shown + 1
                    local code = string.sub(text, it.s, it.e)
                    local first = string.match(code, '^[^\n]*') or ''
                    local more = select(2, string.gsub(code, '\n', '\n'))
                    local c = card_start()
                    pill(h.name, palette.blue, palette.selBg)
                    imgui.SameLine(0, 10)
                    imgui.TextColored(palette.dim, 'line ' .. it.line)
                    imgui.SameLine(0, 10)
                    imgui.TextColored(palette.dim, fit(first .. ((more > 0) and ('  (+' .. more .. ' lines)') or '')))
                    if imgui.IsItemHovered() then set_tip(string.sub(code, 1, 1200)) end
                    imgui.PushTextWrapPos(0)
                    if it.ok then
                        for _, r in ipairs(it.rules) do imgui.TextColored(palette.ok, R.Say(r)) end
                        if it.spot ~= nil then
                            imgui.TextColored(palette.dim, 'Goes on ' .. spot_label(it.spot, plan, text) .. ', where this code was, '
                                .. 'so the order stays the same.')
                            if imgui.IsItemHovered() then set_tip(spot_tip(it.spot, plan, text)) end
                        end
                    else
                        -- why it can't be a rule, and that it's fine: it keeps working as code (the check's own
                        -- findings stay amber: something there differed or couldn't be run)
                        local why = tostring(it.why)
                        local fromCheck = string.match(why, "^Convert's check") ~= nil
                        imgui.TextColored(fromCheck and palette.warn or palette.dim, why
                            .. (fromCheck and '' or ' Fine as it is: it keeps working as code.'))
                    end
                    imgui.PopTextWrapPos()
                    card_end(c)
                    imgui.Spacing()
                end
            end
        end
        if (want == 'stays') and (std > 0) then
            paragraph(std .. ' more ' .. ((std == 1) and 'is' or 'are') .. " GoomSwap's standard lines (your idle / engaged "
                .. 'steps, the named-set step, the WS check): they stay as they are.')
        end
        return shown
    end
    -- The code views. stays: the ifs that stay code; else the ones Convert can make into rules, and its button.
    local function draw_code(stays)
        local doc = editorState.document
        local text = (doc ~= nil) and (doc.model ~= nil) and doc.model.text or nil
        if text == nil then return end
        if doc.convert ~= nil then -- staged: draw_staged says so; show what it did
            if doc.convert.plan ~= nil then draw_changes(doc.convert.plan, doc.convert.text, stays and 'stays' or 'ok') end
            return
        end
        local c = plan_of(text)
        if c.plan == nil then
            paragraph('Nothing to convert: ' .. tostring(c.why) .. '.', palette.warn)
            return
        end
        if stays then
            paragraph('These ifs in your job file stay code, each with why. They work as before; Rules go on with them.')
            imgui.Spacing()
            if draw_changes(c.plan, text, 'stays') == 0 then paragraph('None: all your gear code can become rules.') end
            return
        end
        local ok, example = 0, nil
        for _, h in ipairs(c.plan.handlers) do
            for _, it in ipairs(h.items) do
                if it.ok then
                    ok = ok + 1
                    if example == nil then example = R.Say(it.rules[1]) end
                end
            end
        end
        if ok > 0 then
            paragraph('Your job file still picks some gear with code. ' .. ok .. ((ok == 1) and ' piece of it' or ' pieces of it')
                .. ' can become rules, like: ' .. example .. '. Convert moves them into your rules, so you can see and '
                .. 'change them here. Nothing is saved until Save + reload.', palette.text)
        end
        if not c.ready then -- the same-gear check is still running: Convert waits for it
            local job = c.job
            paragraph('Checking that the converted file wears the same gear as your code... '
                .. math.floor(((job ~= nil) and job.progress or 0) * 100) .. '%', palette.blue)
            imgui.Spacing()
            draw_changes(c.plan, text, 'ok')
            return
        end
        local ck = c.plan.checked
        if c.checkFailed ~= nil then
            paragraph('The same-gear check stopped (' .. tostring(c.checkFailed) .. '): Convert works as before, '
                .. 'without it.', palette.warn)
        elseif (ck ~= nil) and (ck.unavailable ~= nil) then
            paragraph('The same-gear check could not run your file here (' .. tostring(ck.unavailable) .. '): Convert '
                .. 'works as before, without it.', palette.warn)
        elseif ck ~= nil then
            paragraph('Checked: with these rules your gear stays the same, slot by slot, in ' .. ck.rounds
                .. ' random game states for each part of your code.'
                .. ((ck.freed > 0) and (' ' .. ck.freed .. ((ck.freed == 1) and ' piece goes' or ' pieces go')
                    .. ' with your other rules, with no line left in the code.') or '')
                .. ((ck.skippedCount > 0) and (' ' .. ck.skippedCount .. ((ck.skippedCount == 1) and ' part stays' or ' parts stay')
                    .. ' code: the check found different gear there, or could not run it (Stays code: why).') or ''),
                (ck.skippedCount > 0) and palette.warn or palette.ok)
        end
        if c.adoptable then
            paragraph('This file does not load GoomSwap (a plain LuAshitacast file). Adopt adds it: GoomSwap loads at '
                .. 'the top and its layers go on at the end of HandleDefault; your code and set names stay.', palette.warn)
            if button('Adopt' .. ((ok > 0) and (' and convert ' .. ok) or '') .. '##conv_adopt', 'primary', true) then
                stage_convert(c, true)
            end
        elseif ok > 0 then
            if button('Convert ' .. ok .. ' into rules##conv_go', 'primary', true) then
                stage_convert(c, false)
                editorState.ui.rulesView = 'all'
            end
        else
            paragraph('Nothing in your job file\'s code can become rules (Stays code, on the left: why).')
        end
        imgui.Spacing()
        draw_changes(c.plan, text, 'ok')
    end

    -- == The page ==
    -- Left: what to show (all rules, one moment's, or your code); right: the builder (when open), then the cards.
    local NAV_W = { 190, 0 }
    local MAIN_W = { 0, 0 }
    local function code_counts()
        local doc = editorState.document
        if (doc == nil) or (doc.model == nil) or (doc.model.text == nil) then return 0, 0 end
        if doc.convert ~= nil then return 0, 0 end
        local c = plan_of(doc.model.text)
        local ok, no = 0, 0
        for _, h in ipairs((c.plan ~= nil) and c.plan.handlers or {}) do
            for _, it in ipairs(h.items) do
                if it.ok then ok = ok + 1 elseif not it.standard then no = no + 1 end
            end
        end
        return ok, no
    end
    local NAV_ROW = { 0, 0 }
    -- A row: the label as a selectable short of the right end, and the count there (whatever the font size).
    local function nav_row(label, n, key, tip)
        local sel = (editorState.ui.rulesView or 'all') == key
        local t = (n ~= nil) and tostring(n) or nil
        local avail = xw(imgui.GetContentRegionAvail())
        local tw = (t ~= nil) and xw(imgui.CalcTextSize(t)) or 0
        NAV_ROW[1] = ((avail ~= nil) and (tw ~= nil) and (t ~= nil)) and math.max(20, avail - tw - 8) or 0
        if imgui.Selectable(label .. '##rv_' .. key, sel, 0, NAV_ROW) then editorState.ui.rulesView = key end
        if (tip ~= nil) and imgui.IsItemHovered() then set_tip(tip) end
        if t ~= nil then
            imgui.SameLine(0, 8)
            imgui.TextColored(palette.dim, t)
        end
    end
    local function draw_nav(list)
        imgui.TextColored(palette.dim, 'SHOW')
        nav_row('All rules', #list, 'all')
        local per = {}
        for _, r in ipairs(list) do
            if type(r) == 'table' and (r.on ~= nil) then per[r.on] = (per[r.on] or 0) + 1 end
        end
        for _, ph in ipairs(R.PHASES) do
            if per[ph] ~= nil then nav_row(R.PHASE_LABEL[ph] or ph, per[ph], ph, R.PHASE_LONG[ph]) end
        end
        imgui.Spacing()
        imgui.TextColored(palette.dim, 'YOUR CODE')
        local ok, no = code_counts()
        nav_row('Can become rules', ok, 'code', 'The ifs in your job file that Convert can make into rules.')
        nav_row('Stays code', no, 'stays', 'The ifs that stay code, and why.')
    end
    -- Convert staged and not saved: said on every view, with its Undo.
    local function draw_staged()
        local doc = editorState.document
        local conv = (doc ~= nil) and doc.convert or nil
        if conv == nil then return end
        local plan = conv.plan
        local n, rules = 0, 0
        for _, h in ipairs((plan ~= nil) and plan.handlers or {}) do
            for _, it in ipairs(h.items) do
                if it.ok then n, rules = n + 1, rules + #it.rules end
            end
        end
        paragraph(((plan ~= nil) and ('Converted, not saved yet: ' .. n .. ((n == 1) and ' piece' or ' pieces')
            .. ' of code became ' .. rules .. ((rules == 1) and ' rule' or ' rules') .. '. ') or (conv.title .. ', not saved yet. '))
            .. 'What you wear stays the same. Save + reload keeps it (a backup is made first).', palette.warn)
        if button('Undo convert##conv_undo', 'plain') then
            M.Stage(conv.prior)
            doc.convert = nil
            feedback('Convert undone (rule edits made since are undone too).')
        end
        imgui.Spacing()
    end
    function M.Draw()
        local list, how = M.List()
        if list == nil then
            imgui.TextColored(palette.warn, 'gcinclude.Rules is ' .. tostring(how) .. ' in the file: edit it there.')
            return
        end
        local view = editorState.ui.rulesView or 'all'
        imgui.BeginChild('##rules_nav', NAV_W, ImGuiChildFlags_Borders or ImGuiChildFlags_Border or 1) -- flags: a number
        draw_nav(list)
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild('##rules_main', MAIN_W, 0)
        if button('+ New rule##rules_add', 'primary', true) then
            M.Edit(nil)
            if (view == 'code') or (view == 'stays') then editorState.ui.rulesView = 'all'; view = 'all' end
        end
        imgui.SameLine(0, 10)
        imgui.TextColored(palette.dim, 'A rule puts gear on at a moment, when its conditions hold.')
        if how == 'staged' then
            imgui.SameLine(0, 10)
            imgui.TextColored(palette.warn, 'unsaved')
        end
        if (#list > 1) and (view ~= 'code') and (view ~= 'stays') then
            paragraph('Order only matters when two rules put gear in the same slot at the same moment: the later one '
                .. 'wins. Up / Down show only where that can happen.')
        end
        -- problems, as the engine would see them on load
        local p = editorState.ui.ruleProblems
        if (p == nil) or (p.list ~= list) then
            local _, problems = R.Compile(list)
            p = { list = list, problems = problems }
            editorState.ui.ruleProblems = p
        end
        for _, line in ipairs(p.problems) do imgui.TextColored(palette.bad, 'Left out on load: ' .. line) end
        imgui.Spacing()
        draw_staged()
        if (view == 'code') or (view == 'stays') then
            draw_code(view == 'stays')
        else
            if editorState.ui.ruleEdit ~= nil then
                local c = card_start()
                draw_builder()
                card_end(c, palette.blue)
                imgui.Spacing()
            end
            local shown = 0
            for i = 1, #list do
                local r = list[i]
                if (view == 'all') or ((type(r) == 'table') and (r.on == view)) then
                    draw_rule_row(list, i)
                    shown = shown + 1
                end
            end
            if #list == 0 then
                paragraph('No rules yet. A rule wears a set (or one item) when its conditions hold: Fealty while Cover '
                    .. 'is up, a body piece under 40% MP on nukes, Self_Cure when a cure is on you.')
                local ok = code_counts()
                if ok > 0 then
                    paragraph(ok .. ((ok == 1) and ' piece' or ' pieces') .. ' of your job file\'s code can become rules: '
                        .. 'Your code, on the left.', palette.blue)
                end
            elseif shown == 0 then
                paragraph('No rules for this moment.')
            end
        end
        imgui.EndChild()
    end

    return M
end
