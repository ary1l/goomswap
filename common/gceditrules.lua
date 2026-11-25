-- /gcedit's Rules page: the job file's gcinclude.Rules (gcrules.lua) as a list, and a builder for one rule: when
-- (phase), if (conditions from a menu), wear (a set, items), layer, stop. Edits are staged like set edits and
-- written by the editor's Save as `gcinclude.Rules = {...}` (one rule a line). The middle pane shows it while
-- editorState.selection.rules is on (the RULES row at the top of the set list).
-- o: { imgui, palette, set_tip, editorState, files (gceditsettings), setFile, feedback, ctx }
return function(o)
    local imgui, palette, set_tip, editorState, files, setFile, feedback, ctx =
        o.imgui, o.palette, o.set_tip, o.editorState, o.files, o.setFile, o.feedback, o.ctx
    local R = gFunc.LoadFile('common\\gcrules.lua')
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
    local function chip(text, col)
        imgui.TextColored(col, '[' .. text .. ']')
    end
    local function short(text, n)
        if #text <= n then return text end
        return string.sub(text, 1, n - 3) .. '...'
    end
    local function row_buttons(list, i, group)
        local id = (group ~= nil) and (tostring(group) .. '_' .. i) or tostring(i)
        local items = (group ~= nil) and list[group].first or list
        imgui.SameLine()
        if imgui.SmallButton('Edit##rule_edit_' .. id) then
            M.Edit(group or i, (group ~= nil) and i or nil)
        end
        imgui.SameLine()
        if imgui.SmallButton('^##rule_up_' .. id) and (i > 1) then
            local out = copy(list)
            local arr = (group ~= nil) and out[group].first or out
            arr[i], arr[i - 1] = arr[i - 1], arr[i]
            M.Stage(out)
        end
        if imgui.IsItemHovered() then set_tip('Earlier: a later rule wins the slots both wear.') end
        imgui.SameLine()
        if imgui.SmallButton('v##rule_down_' .. id) and (i < #items) then
            local out = copy(list)
            local arr = (group ~= nil) and out[group].first or out
            arr[i], arr[i + 1] = arr[i + 1], arr[i]
            M.Stage(out)
        end
        imgui.SameLine()
        if imgui.SmallButton('x##rule_del_' .. id) then
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
        imgui.SameLine()
        imgui.TextColored(palette.blue, R.PHASE_LABEL[rule.on] or tostring(rule.on))
        imgui.SameLine()
        if rule.layer == 'top' then chip('over everything', palette.warn) else chip('job layer', palette.dim) end
        if imgui.IsItemHovered() then set_tip((rule.layer == 'top') and TOP_NOTE or JOB_NOTE) end
        if type(rule.first) == 'table' then
            imgui.SameLine()
            imgui.TextUnformatted('first of these' .. ((rule.when ~= nil) and (', when ' .. R.WhenWords(rule.when)) or '') .. ':')
            if rule.note then
                imgui.SameLine()
                imgui.TextColored(palette.dim, '-- ' .. rule.note)
            end
            imgui.SameLine()
            if imgui.SmallButton('x##rule_delg_' .. i) then
                local out = copy(list)
                table.remove(out, i)
                M.Stage(out)
            end
            imgui.Indent(28)
            for j, m in ipairs(rule.first) do
                imgui.TextColored(palette.dim, j .. ')')
                imgui.SameLine()
                local words = R.WhenWords(m.when) .. '  ->  ' .. R.WearWords(m)
                imgui.TextUnformatted(short(words, 90))
                if imgui.IsItemHovered() then set_tip(words) end
                row_buttons(list, j, i)
            end
            if imgui.SmallButton('+ choice##rule_addc_' .. i) then M.Edit(i, #rule.first + 1) end
            imgui.Unindent(28)
            return
        end
        imgui.SameLine()
        local words = R.WhenWords(rule.when) .. '  ->  ' .. R.WearWords(rule)
        imgui.TextUnformatted(short(words, 90))
        if imgui.IsItemHovered() then set_tip(words .. ((rule.note ~= nil) and ('\n\n' .. rule.note) or '')) end
        if rule.note then
            imgui.SameLine()
            imgui.TextColored(palette.dim, '-- ' .. short(rule.note, 40))
        end
        row_buttons(list, i)
    end

    -- The RULES row at the top of the set list.
    function M.ListButton()
        local n, sel = M.Count(), editorState.selection.rules == true
        if sel then imgui.PushStyleColor(ImGuiCol_Text, palette.blue) end
        if imgui.Selectable('RULES  ' .. ((n > 0) and (n .. ((n == 1) and ' rule' or ' rules')) or '(none yet)')
            .. '##gcedit_rules_row', sel) then
            editorState.selection.rules = true
        end
        if sel then imgui.PopStyleColor() end
        if imgui.IsItemHovered() then
            set_tip('When this, wear that, without code: a buff up, low MP, a spell on you, a mode... '
                .. 'Saved in the job file as gcinclude.Rules.')
        end
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
            if (k.phases == nil) or k.phases[phase] then out[#out + 1] = { k.key, k.label } end
        end
        return out
    end

    local function draw_row(e, i, r)
        local meta = R.KEY[r.key] or { label = r.key, kind = 'text' }
        local id = 'rb_' .. i
        local pick = W.Pick(id .. '_key', meta.label, key_options(e.phase))
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
        imgui.SameLine()
        if meta.kind == 'bool' then
            local v = W.Pick(id .. '_bool', (r.value == false) and 'no' or 'yes', { { true, 'yes' }, { false, 'no' } })
            if v ~= nil then r.value = v end
        elseif meta.kind == 'toggle' then
            local s = W.Pick(id .. '_sub', '/' .. (r.sub or 'dt'), TOGGLE_NAMES)
            if s ~= nil then r.sub = s end
            imgui.SameLine()
            local v = W.Pick(id .. '_tv', (r.value == false) and 'off' or 'on', { { true, 'on' }, { false, 'off' } })
            if v ~= nil then r.value = v end
        else
            if meta.kind == 'mode' then
                local s = W.Pick(id .. '_sub', '/' .. (r.sub or 'wm'), CYCLE_NAMES)
                if s ~= nil then r.sub = s end
                imgui.SameLine()
                imgui.TextUnformatted('is')
            elseif meta.kind == 'number' then
                local op = W.Pick(id .. '_op', OP_WORDS[r.op or 'lt'], { { 'lt', '<' }, { 'le', '<=' }, { 'gt', '>' },
                    { 'ge', '>=' }, { 'eq', '=' }, { 'ne', 'not' } })
                if op ~= nil then r.op = op end
            elseif meta.kind == 'list' then
                imgui.TextUnformatted('')
            else
                local op = W.Pick(id .. '_op', OP_WORDS[r.op or 'is'], { { 'is', 'is' }, { 'isnt', 'is not' },
                    { 'has', 'has' }, { 'start', 'starts with' }, { 'ends', 'ends with' } })
                if op ~= nil then r.op = op end
            end
            imgui.SameLine()
            imgui.PushItemWidth(220)
            imgui.InputTextWithHint('##' .. id .. '_val', (meta.kind == 'number') and 'a number'
                or 'a name; several: commas', r.buf, 128)
            imgui.PopItemWidth()
            if imgui.IsItemHovered() then
                set_tip((meta.kind == 'number') and 'A number.' or ('As the game writes it. Several, separated by commas: '
                    .. 'any of them.' .. ((r.op == 'has' or r.op == 'start' or r.op == 'ends') and ' Upper and lower '
                    .. 'case count.' or '')))
            end
            -- the values this key can have: a click puts one in the box
            local values = meta.values
            if meta.kind == 'mode' and (gcdisplay ~= nil) and (gcdisplay.GetCycleValues ~= nil) then
                values = gcdisplay.GetCycleValues(R.CYCLES[r.sub or 'wm'] or r.sub)
            end
            if (values ~= nil) and (#values > 0) then
                imgui.Indent(24)
                for j, v in ipairs(values) do
                    if j > 1 then imgui.SameLine() end
                    if j > 1 and (j - 1) % 6 == 0 then imgui.NewLine() end
                    if imgui.SmallButton(tostring(v) .. '##' .. id .. '_v' .. j) then
                        local cur = trim(r.buf[1])
                        r.buf[1] = (cur == '') and tostring(v) or (cur .. ', ' .. tostring(v))
                    end
                end
                imgui.Unindent(24)
            end
        end
        imgui.SameLine()
        if imgui.SmallButton('x##' .. id .. '_x') then return true end
        return false
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
        if e.member == nil and e.top[1] then rule.layer = 'top' end
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
        -- when
        imgui.TextColored(palette.dim, 'When')
        imgui.SameLine(70)
        if e.member ~= nil then
            imgui.TextUnformatted(R.PHASE_LABEL[e.phase] .. ' (its group\'s)')
        else
            local options = {}
            for _, p in ipairs(R.PHASES) do options[#options + 1] = { p, R.PHASE_LABEL[p] } end
            local p = W.Pick('rb_phase', R.PHASE_LABEL[e.phase] or e.phase, options)
            if p ~= nil then e.phase = p end
        end
        -- if
        imgui.TextColored(palette.dim, 'If')
        imgui.SameLine(70)
        if e.unsupported then
            imgui.TextColored(palette.warn, R.WhenWords(e.rule.when) .. '  (this shape is edited in the file)')
        else
            local m = W.Pick('rb_any', e.any and 'any of these' or 'all of these',
                { { false, 'all of these' }, { true, 'any of these' } })
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
            if imgui.SmallButton('+ condition##rb_add') then
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
                    if shown > 0 then imgui.SameLine() end
                    shown = shown + 1
                    if imgui.SmallButton(n .. '##rb_set_' .. shown) then e.wear[1] = n end
                end
            end
            imgui.Unindent(70)
        end
        imgui.Indent(70)
        local goneItem = nil
        for i, it in ipairs(e.items) do
            local s = W.Pick('rb_islot_' .. i, it.slot, R.SLOTS)
            if s ~= nil then it.slot = s end
            imgui.SameLine()
            imgui.PushItemWidth(220)
            imgui.InputTextWithHint('##rb_item_' .. i, 'an item, as the game shows it', it.buf, 96)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.SmallButton('x##rb_ix_' .. i) then goneItem = i end
        end
        if goneItem ~= nil then table.remove(e.items, goneItem) end
        if imgui.SmallButton('+ one item##rb_additem') then
            e.items[#e.items + 1] = { slot = 'Head', buf = { '' } }
        end
        if imgui.IsItemHovered() then set_tip('One piece in one slot, without a set (Pixie Hairpin +1 on Noctohelix).') end
        imgui.Unindent(70)
        -- layer, stop, note
        if e.member == nil then
            imgui.TextColored(palette.dim, 'Layer')
            imgui.SameLine(70)
            if imgui.SmallButton(((not e.top[1]) and '> ' or '') .. 'Job layer##rb_job') then e.top[1] = false end
            if imgui.IsItemHovered() then set_tip(JOB_NOTE) end
            imgui.SameLine()
            if imgui.SmallButton((e.top[1] and '> ' or '') .. 'Over everything##rb_top') then e.top[1] = true end
            if imgui.IsItemHovered() then set_tip(TOP_NOTE) end
            if e.top[1] then
                imgui.PushTextWrapPos(0)
                imgui.TextColored(palette.dim, TOP_NOTE)
                imgui.PopTextWrapPos()
            end
        end
        local stoppable = R.STOPPABLE[e.phase] == true
        if (not stoppable) and (imgui.BeginDisabled ~= nil) then imgui.BeginDisabled() end
        imgui.Checkbox('Stop the action##rb_stop', e.stop)
        if (not stoppable) and (imgui.EndDisabled ~= nil) then imgui.EndDisabled() end
        if imgui.IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled or 0) then
            set_tip(stoppable and 'Cancels the action (LuAshitacast\'s CancelAction), with a line in chat.'
                or 'Only Precast, Job ability, Weapon skill, Item and Preshot can stop an action (LuAshitacast).')
        end
        imgui.SameLine()
        imgui.PushItemWidth(260)
        imgui.InputTextWithHint('##rb_note', 'a note for yourself (optional)', e.note, 96)
        imgui.PopItemWidth()
        -- now
        local rule, why = built(e)
        imgui.TextColored(palette.dim, 'Now')
        imgui.SameLine(70)
        if rule == nil then
            imgui.TextColored(palette.warn, why)
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
        if imgui.Button('Save rule##rb_save') and (rule ~= nil) then
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
        if imgui.Button('Cancel##rb_cancel') then editorState.ui.ruleEdit = nil end
    end

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
        if imgui.Button('+ Rule##rules_add') then M.Edit(nil) end
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
    end

    return M
end
