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
    local W = gFunc.LoadFile('common\\gceditwidgets.lua')(imgui, palette, set_tip)
    local M = { R = R }

    local OP_WORDS = { is = 'is', isnt = 'is not', has = 'has', start = 'starts with', ends = 'ends with',
        lt = '<', le = '<=', gt = '>', ge = '>=', eq = '=', ne = 'not' }
    local CYCLE_NAMES = { 'wm', 'mset', 'nukeset', 'idleset', 'wsset', 'tankset', 'weapon', 'pupmode', 'hoxne', 'mw',
        'sw', 'rw', 'ammoset' }
    local TOGGLE_NAMES = { 'dt', 'mdt', 'kite', 'th', 'sir', 'proc', 'burst', 'aminon', 'death', 'songlock',
        'forcestring' }
    local TOP_NOTE = 'Over GoomSwap\'s own layers (weapons, TH, Hoxne, buff sets, obi, SIR). Still under /lock, the '
        .. 'TP and Aftermath holds, Incapacitated, Sleeping and Doomed, SmartSwap\'s weapon keep and Dispelga\'s Daybreak.'
    local JOB_NOTE = 'Where your job file\'s own code goes: GoomSwap\'s layers (weapons, TH, Hoxne, buff sets, obi, '
        .. 'SIR...) still go on over it.'

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
    -- == Looks: buttons by what they do, and labels on a rounded fill (as the editor's other pills) ==
    local function vec(a, b)
        if type(a) == 'table' then return a.x or a[1], a.y or a[2] end
        if type(a) == 'number' then return a, b end
        return nil, nil
    end
    local CLEAR = { 0, 0, 0, 0 }
    -- kind: 'primary' (Save rule, Convert: the save blue), 'accent' (Edit, + Rule: blue text on the tab blue),
    -- 'plain' (moves, cancel), 'danger' (take out: grey until hovered, then red).
    local KINDS = {
        primary = function() return palette.save, palette.saveHi, palette.saveHi, nil end,
        accent = function() return palette.selBg, palette.save, palette.save, palette.blue end,
        plain = function() return palette.btn, palette.btnHi, palette.btnHi, nil end,
        danger = function() return palette.btn, palette.red, palette.redHi, nil end,
        ghost = function() return CLEAR, palette.btnHi, palette.btnHi, palette.dim end,
    }
    local function button(label, kind, big, off, size)
        local b, h, a, t = KINDS[kind or 'plain']()
        local disabled = off and (imgui.BeginDisabled ~= nil)
        if disabled then imgui.BeginDisabled() end
        imgui.PushStyleColor(ImGuiCol_Button, b)
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, h)
        imgui.PushStyleColor(ImGuiCol_ButtonActive, a)
        if t ~= nil then imgui.PushStyleColor(ImGuiCol_Text, t) end
        local hit
        if size ~= nil then hit = imgui.Button(label, size)
        elseif big then hit = imgui.Button(label)
        else hit = imgui.SmallButton(label) end -- one of them, never two
        imgui.PopStyleColor((t ~= nil) and 4 or 3)
        if disabled then imgui.EndDisabled() end
        return hit and not off
    end
    M.Button = button
    -- text on a rounded fill; plain coloured text when this ImGui has no draw list
    local PA, PB = { 0, 0 }, { 0, 0 }
    local function pill(text, fg, bg)
        local dl = (imgui.GetWindowDrawList ~= nil) and imgui.GetWindowDrawList() or nil
        if (type(dl) == 'userdata' or type(dl) == 'table') and (imgui.GetColorU32 ~= nil) then
            local x, y = vec(imgui.GetCursorScreenPos())
            local w, ht = vec(imgui.CalcTextSize(text))
            if (x ~= nil) and (y ~= nil) and (w ~= nil) and (ht ~= nil) then
                PA[1], PA[2], PB[1], PB[2] = x - 4, y - 1, x + w + 4, y + ht + 1
                dl:AddRectFilled(PA, PB, imgui.GetColorU32(bg), 7)
            end
        end
        imgui.TextColored(fg, text)
    end
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
    local function row_buttons(list, i, group)
        local id = (group ~= nil) and (tostring(group) .. '_' .. i) or tostring(i)
        local items = (group ~= nil) and list[group].first or list
        imgui.SameLine(0, 8)
        if button('Edit##rule_edit_' .. id, 'accent') then
            M.Edit(group or i, (group ~= nil) and i or nil)
        end
        imgui.SameLine(0, 3)
        if button('Up##rule_up_' .. id, 'plain', false, i <= 1) then
            local out = copy(list)
            local arr = (group ~= nil) and out[group].first or out
            arr[i], arr[i - 1] = arr[i - 1], arr[i]
            M.Stage(out)
        end
        if imgui.IsItemHovered() then set_tip('Earlier: a later rule wins the slots both wear.') end
        imgui.SameLine(0, 3)
        if button('Down##rule_down_' .. id, 'plain', false, i >= #items) then
            local out = copy(list)
            local arr = (group ~= nil) and out[group].first or out
            arr[i], arr[i + 1] = arr[i + 1], arr[i]
            M.Stage(out)
        end
        imgui.SameLine(0, 3)
        if button('x##rule_del_' .. id, 'danger') then
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
        if imgui.IsItemHovered() then set_tip('Take it out (Undo: Revert the job file, or put it back).') end
    end

    -- A rule: on top its tick, number, buttons, phase and layer; under it what it does, as a sentence that wraps to
    -- the pane (so nothing hides past its edge).
    local function sentence(text, col)
        imgui.Indent(30)
        imgui.PushTextWrapPos(0)
        if col ~= nil then imgui.TextColored(col, text) else imgui.TextUnformatted(text) end
        imgui.PopTextWrapPos()
        imgui.Unindent(30)
    end
    local function draw_rule_row(list, i)
        local rule = list[i]
        if type(rule) ~= 'table' then return end
        local on = { not rule.off }
        if imgui.Checkbox('##rule_on_' .. i, on) then
            local out = copy(list)
            out[i].off = (not on[1]) or nil
            M.Stage(out)
        end
        if imgui.IsItemHovered() then set_tip(rule.off and 'Off: kept, not used. Tick to use it.' or 'On. Untick to keep it without using it.') end
        imgui.SameLine()
        imgui.TextColored(palette.dim, i .. '.')
        if type(rule.first) ~= 'table' then
            row_buttons(list, i)
        else
            imgui.SameLine(0, 8)
            if button('x##rule_delg_' .. i, 'danger') then
                local out = copy(list)
                table.remove(out, i)
                M.Stage(out)
            end
            if imgui.IsItemHovered() then set_tip('Take out the whole group.') end
        end
        imgui.SameLine(0, 10)
        imgui.TextColored(palette.blue, R.PHASE_LABEL[rule.on] or tostring(rule.on))
        if rule.at ~= nil then
            chip('at ' .. rule.at, palette.blue, palette.selBg)
            if imgui.IsItemHovered() then
                set_tip('Goes on at gcinclude.RulesAt(\'' .. rule.at .. '\') in your job file\'s code: Convert left that line '
                    .. 'where the if was, so this goes on at the same point as before.')
            end
        elseif rule.layer == 'top' then
            chip('over everything', palette.warn, palette.warnBg)
            if imgui.IsItemHovered() then set_tip(TOP_NOTE) end
        else
            chip('job layer', palette.dim, palette.chipBg)
            if imgui.IsItemHovered() then set_tip(JOB_NOTE) end
        end
        if rule.off then
            imgui.SameLine(0, 10)
            imgui.TextColored(palette.dim, '(off)')
        end
        if type(rule.first) == 'table' then
            sentence(moment_words(rule.on, rule.when) .. ', the first of these that fits:'
                .. ((rule.note ~= nil) and ('  -- ' .. rule.note) or ''), rule.off and palette.dim or nil)
            imgui.Indent(30)
            for j, m in ipairs(rule.first) do
                imgui.TextColored(palette.dim, j .. ')')
                row_buttons(list, j, i)
                imgui.SameLine(0, 10)
                imgui.PushTextWrapPos(0)
                imgui.TextUnformatted(R.Say(m, rule.on))
                imgui.PopTextWrapPos()
            end
            if button('+ choice##rule_addc_' .. i, 'ghost') then M.Edit(i, #rule.first + 1) end
            imgui.Unindent(30)
        else
            sentence(R.Say(rule) .. ((rule.note ~= nil) and ('  -- ' .. rule.note) or ''), rule.off and palette.dim or nil)
        end
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
    -- The Rules button in the top bar: opens the page, or (open already) goes back to the set.
    function M.TopButton()
        local n, k = summary()
        local sel = editorState.selection.rules == true
        local label = 'Rules' .. ((n > 0) and (' (' .. n .. ')') or '') .. ((k > 0) and (' - ' .. k .. ' to convert') or '')
        if button(label .. '##gcedit_rules_top', sel and 'primary' or 'accent') then
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

    local function draw_builder()
        local e = editorState.ui.ruleEdit
        if e == nil then return end
        imgui.Separator()
        imgui.TextColored(palette.blue, (e.index == nil) and 'New rule' or ((e.member ~= nil) and ('Rule ' .. e.index
            .. ', choice ' .. e.member) or ('Rule ' .. e.index)))
        imgui.SameLine()
        imgui.TextColored(palette.dim, '-  pick the moment (When), what has to be true then (If), and what to put on (Wear).')
        -- when
        imgui.TextColored(palette.dim, 'When')
        imgui.SameLine(70)
        if e.member ~= nil then
            imgui.TextUnformatted(R.PHASE_LONG[e.phase] .. ' (its group\'s)')
        else
            local options = {}
            for _, p in ipairs(R.PHASES) do options[#options + 1] = { p, R.PHASE_LONG[p] } end
            local p = W.Pick('rb_phase', R.PHASE_LONG[e.phase] or e.phase, options, 330)
            if p ~= nil then e.phase = p end
        end
        -- if
        imgui.TextColored(palette.dim, 'If')
        imgui.SameLine(70)
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
            imgui.Indent(70)
            local gone = nil
            for i, r in ipairs(e.rows) do
                if draw_row(e, i, r) then gone = i end
            end
            if gone ~= nil then table.remove(e.rows, gone) end
            if button('+ condition##rb_add', 'ghost') then
                e.rows[#e.rows + 1] = row_state({ key = 'buff', op = 'is' })
            end
            imgui.Unindent(70)
        end
        -- wear
        imgui.TextColored(palette.dim, 'Wear')
        imgui.SameLine(70)
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
            imgui.Indent(70)
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
            imgui.Unindent(70)
        end
        imgui.Indent(70)
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
        imgui.Unindent(70)
        -- layer, stop, note
        if (e.member == nil) and (e.rule.at ~= nil) and not e.unspot then
            imgui.TextColored(palette.dim, 'Where')
            imgui.SameLine(70)
            imgui.TextUnformatted('at ' .. e.rule.at .. ' in the job file\'s code')
            imgui.SameLine()
            if imgui.SmallButton('Use a layer instead##rb_unspot') then e.unspot = true end
            if imgui.IsItemHovered() then
                set_tip('The rule then goes on with the other rules (job layer or over everything), not at its spot.')
            end
        elseif e.member == nil then
            imgui.TextColored(palette.dim, 'Layer')
            imgui.SameLine(70)
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
        if R.STOPPABLE[e.phase] then
            imgui.Checkbox('Cancel it instead (it is not used)##rb_stop', e.stop)
            if imgui.IsItemHovered() then
                set_tip('Rarely needed: when the conditions hold, the spell or ability is not used at all (a line in chat '
                    .. 'says why). Example: cancel Stun while your MP is under 10%.')
            end
            imgui.SameLine()
        else
            e.stop[1] = false
            imgui.TextColored(palette.dim, 'Note')
            imgui.SameLine(70)
        end
        imgui.PushItemWidth(260)
        imgui.InputTextWithHint('##rb_note', 'a note for yourself (optional)', e.note, 96)
        imgui.PopItemWidth()
        -- now
        local rule, why = built(e)
        imgui.TextColored(palette.dim, 'Reads')
        imgui.SameLine(70)
        imgui.PushTextWrapPos(0)
        if rule ~= nil then
            local r2 = rule
            if (e.member ~= nil) and (r2.on == nil) then r2 = copy(rule); r2.on = e.phase end
            imgui.TextColored(palette.ok, R.Say(r2, e.phase))
        else
            imgui.TextColored(palette.warn, why)
        end
        imgui.PopTextWrapPos()
        imgui.TextColored(palette.dim, 'Now')
        imgui.SameLine(70)
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
    local function plan_of(text)
        local c = editorState.ui.convertPlan
        if (c == nil) or (c.text ~= text) then
            local plan, why = Conv.Plan(text)
            c = { text = text, plan = plan, why = why, adoptable = not Conv.IsGoomSwap(text) }
            editorState.ui.convertPlan = c
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
    -- What Convert changes, each `if` in turn: its code (first line; all of it on hover) and the rules it becomes,
    -- or why it stays code.
    local function draw_changes(plan, text)
        local std = 0
        for _, h in ipairs(plan.handlers) do
            local shown = {}
            for _, it in ipairs(h.items) do
                if it.standard then std = std + 1 else shown[#shown + 1] = it end
            end
            if #shown > 0 then
                imgui.TextColored(palette.blue, h.name)
                imgui.Indent(16)
                for _, it in ipairs(shown) do
                    local code = string.sub(text, it.s, it.e)
                    local first = string.match(code, '^[^\n]*') or ''
                    local more = select(2, string.gsub(code, '\n', '\n'))
                    imgui.TextColored(it.ok and palette.ok or palette.dim, 'line ' .. it.line .. ':')
                    if it.standard then imgui.SameLine(); imgui.TextColored(palette.dim, '(standard)') end
                    imgui.SameLine()
                    imgui.TextColored(palette.dim, fit(first .. ((more > 0) and ('  (+' .. more .. ' lines)') or '')))
                    if imgui.IsItemHovered() then set_tip(string.sub(code, 1, 1200)) end
                    imgui.Indent(24)
                    imgui.PushTextWrapPos(0)
                    if it.ok then
                        for _, r in ipairs(it.rules) do imgui.TextUnformatted('-> ' .. R.Say(r)) end
                        if it.spot ~= nil then
                            imgui.TextColored(palette.dim, '   (these go on at ' .. it.spot .. ': the code keeps one line, '
                                .. "gcinclude.RulesAt('" .. it.spot .. "'), where this was)")
                        end
                    elseif it.standard then
                        imgui.TextColored(palette.dim, 'stays: ' .. tostring(it.why))
                    else
                        imgui.TextColored(palette.warn, 'stays code: ' .. tostring(it.why))
                    end
                    imgui.PopTextWrapPos()
                    imgui.Unindent(24)
                end
                imgui.Unindent(16)
            end
        end
        if std > 0 then
            imgui.TextColored(palette.dim, std .. ' more ' .. ((std == 1) and 'is' or 'are') .. " GoomSwap's standard lines "
                .. '(your idle / engaged steps, the named-set step, the WS check): they stay as they are.')
        end
    end
    local function paragraph(text, col)
        imgui.PushTextWrapPos(0)
        imgui.TextColored(col or palette.dim, text)
        imgui.PopTextWrapPos()
    end
    local function draw_code()
        local doc = editorState.document
        local text = (doc ~= nil) and (doc.model ~= nil) and doc.model.text or nil
        if text == nil then return end
        imgui.Separator()
        imgui.TextColored(palette.blue, 'CODE THAT CAN BECOME RULES')
        editorState.ui.codeOpen = editorState.ui.codeOpen or { false }
        if doc.convert ~= nil then
            local conv = doc.convert
            local plan = conv.plan
            local n, rules, lines = 0, 0, {}
            for _, h in ipairs((plan ~= nil) and plan.handlers or {}) do
                for _, it in ipairs(h.items) do
                    if it.ok then
                        n, rules = n + 1, rules + #it.rules
                        lines[#lines + 1] = tostring(it.line)
                    end
                end
            end
            paragraph('Converted, not saved yet: ' .. ((plan ~= nil) and (n .. ((n == 1) and ' piece' or ' pieces')
                .. ' of code (line' .. ((#lines == 1) and ' ' or 's ') .. table.concat(lines, ', ') .. ') became the '
                .. rules .. ((rules == 1) and ' rule' or ' rules') .. ' above. ') or '')
                .. 'What you wear stays the same. Press Save + reload to keep it (a backup is made first), or Undo convert.',
                palette.warn)
            for _, l in ipairs(conv.lines) do
                if not string.match(l, '^Handle') then paragraph('  ' .. l) end -- Adopt's own steps
            end
            if button('Undo convert##conv_undo', 'plain') then
                M.Stage(conv.prior)
                doc.convert = nil
                feedback('Convert undone (rule edits made since are undone too).')
                return
            end
            if plan ~= nil then
                imgui.SameLine()
                imgui.Checkbox('Show each##conv_each', editorState.ui.codeOpen)
                if editorState.ui.codeOpen[1] then draw_changes(plan, conv.text) end
            end
            return
        end
        local c = plan_of(text)
        if c.plan == nil then
            paragraph('Nothing to convert: ' .. tostring(c.why) .. '.', palette.warn)
            return
        end
        local ok, no, std = 0, 0, 0
        for _, h in ipairs(c.plan.handlers) do
            for _, it in ipairs(h.items) do
                if it.ok then ok = ok + 1 elseif it.standard then std = std + 1 else no = no + 1 end
            end
        end
        local example = nil
        for _, h in ipairs(c.plan.handlers) do
            for _, it in ipairs(h.items) do
                if it.ok and (example == nil) then example = R.Say(it.rules[1]) end
            end
        end
        if ok > 0 then
            paragraph('Your job file still picks some gear with code. ' .. ok .. ((ok == 1) and ' piece of it' or ' pieces of it')
                .. ' can become rules, like: ' .. example .. '. Convert moves them into the rules above, so you can see '
                .. 'and change them here. What you wear stays the same. Nothing is saved until Save + reload.', palette.text)
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
            end
        else
            paragraph((no > 0) and ('Nothing in your job file\'s code can become rules yet: ' .. no
                .. ((no == 1) and ' piece stays' or ' pieces stay') .. ' code (Show each: why).')
                or 'Your job file has no gear code left to convert.')
        end
        if no + ok > 0 then
            if ok > 0 then imgui.SameLine() end
            imgui.Checkbox('Show each' .. ((no > 0) and (' (' .. no .. ' stay code)') or '') .. '##conv_each',
                editorState.ui.codeOpen)
            if editorState.ui.codeOpen[1] then draw_changes(c.plan, text) end
        end
    end
    M.DrawCode = draw_code

    -- == The page ==
    function M.Draw()
        local list, how = M.List()
        imgui.TextColored(palette.blue, 'RULES')
        imgui.SameLine()
        imgui.TextColored(palette.dim, 'when this, wear that: no code. A later rule wins the slots both wear.')
        if list == nil then
            imgui.TextColored(palette.warn, 'gcinclude.Rules is ' .. tostring(how) .. ' in the file: edit it there.')
            return
        end
        if button('+ Rule##rules_add', 'accent', true) then M.Edit(nil) end
        if (o.extraButtons ~= nil) then o.extraButtons() end
        if how == 'staged' then
            imgui.SameLine()
            imgui.TextColored(palette.warn, 'unsaved: Save writes them')
        end
        -- problems, as the engine would see them on load
        local p = editorState.ui.ruleProblems
        if (p == nil) or (p.list ~= list) then
            local _, problems = R.Compile(list)
            p = { list = list, problems = problems }
            editorState.ui.ruleProblems = p
        end
        for _, line in ipairs(p.problems) do imgui.TextColored(palette.bad, 'Left out on load: ' .. line) end
        imgui.Separator()
        if #list == 0 then
            imgui.PushTextWrapPos(0)
            imgui.TextColored(palette.dim, 'No rules yet. A rule wears a set (or one item) when its conditions hold: '
                .. 'Fealty while Cover is up, a body piece under 40% MP on nukes, Self_Cure when a cure is on you.')
            imgui.PopTextWrapPos()
        end
        for i = 1, #list do draw_rule_row(list, i) end
        if o.extraRows ~= nil then o.extraRows() end
        draw_builder()
        draw_code()
    end

    return M
end
