-- /gcedit Settings: every GoomSwap setting, its value now and where that comes from (the default, the shared file
-- every character uses, this character's char.lua, the job file open in the editor); change one for this character,
-- for every character, or for this job. Below them, the job file's own options (WeaponModes, Packer...).
return function(imgui, palette, set_tip, files, groups, setFile, editorState, feedback)
    -- Not in the defaults table (nil there) but read when set.
    local OPTIONAL = { 'EditorGroups', 'EditorHidden', 'EditorSort', 'EditorOrder', 'DisplayBarX', 'LockstyleSet' }
    local LUA_TEXT = { Theme = true } -- false, or a preset's name: typed as Lua
    local FROM = { own = 'this character', shared = 'every character', default = 'default', job = 'this job' }
    local DOCS = gFunc.LoadFile('common\\gceditsettingsdoc.lua')
    local DOC, JOB = DOCS.settings, DOCS.job -- [key] = { what it does, an example as typed }; job: its own list
    local ADVANCED, LIMITS, JOB_ONLY = DOCS.advanced, DOCS.limits, DOCS.jobOnly
    local BOX_W = 340
    local W = gFunc.LoadFile('common\\gceditwidgets.lua')(imgui, palette, set_tip)
    -- Settings drawn as controls, not Lua text: names as chips, name -> value rows, keybinds. Anything else (or a
    -- value of another shape) keeps its Lua box.
    local LIST = { SIRSkip = true, THSkip = true, MBSkills = true, ElementSkills = true, HoldExempt = true,
        MoonshadeSkip = true, CapacityCapes = true, HUDOwners = true, MyBoxes = true, EditorIgnoreSuggestions = true,
        HoxneLockSlots = true, MainModes = true, SubModes = true, RangeModes = true, NukeModes = true }
    local MAP = { HUDAbbr = true, WeaponClass = true, ElementalWS = true, ReceivedSets = true, WeaponRoles = true,
        RangeAmmo = true }
    local NUMBER_MAP = { EnchantDelays = true }
    -- Settings GoomSwap no longer reads: shown (when a file sets one) to clear, or move.
    local RETIRED = {
        PackerItems = 'No longer read: the Bellhop packer is gone. Its items belong in Packer (below), which /lac gear '
            .. '(the Packer plugin) fetches on every job.',
        PackerPutAway = 'No longer read: the Bellhop packer is gone. The Packer plugin sorts what /lac gear leaves out '
            .. 'by its own config.',
    }
    local function is_list(v)
        if type(v) ~= 'table' then return v == nil end
        for k, x in pairs(v) do
            if (type(k) ~= 'number') or (type(x) ~= 'string') then return false end
        end
        return true
    end
    local function is_map(v, number)
        if type(v) ~= 'table' then return v == nil end
        for k, x in pairs(v) do
            if (type(k) ~= 'string') or (type(x) ~= (number and 'number' or 'string')) then return false end
        end
        return true
    end
    local function widget_kind(key, v)
        if key == 'Keybinds' then
            if type(v) ~= 'table' then return (v == nil) and 'keys' or nil end
            for _, b in ipairs(v) do
                if (type(b) ~= 'table') or (type(b[1]) ~= 'string') or (type(b[2]) ~= 'string') then return nil end
            end
            return 'keys'
        end
        if LIST[key] and is_list(v) then return 'list' end
        if MAP[key] and is_map(v) then return 'map' end
        if NUMBER_MAP[key] and is_map(v, true) then return 'nmap' end
        return nil
    end
    local function draw_widget(kind, id, v)
        if kind == 'list' then return W.List(id, v) end
        if kind == 'map' then return W.Map(id, v) end
        if kind == 'nmap' then return W.Map(id, v, { number = true, valueHint = 'seconds' }) end
        if kind == 'keys' then return W.Keybinds(id, v) end
        return nil
    end
    local function item_known(name) -- the game's spelling of an item's name, nil when there is none
        local r = AshitaCore:GetResourceManager():GetItemByName(name, 0)
        return (r ~= nil) and (r.Name[1] or name) or nil
    end
    local function stack_of(name)
        local r = AshitaCore:GetResourceManager():GetItemByName(name, 0)
        return (r ~= nil) and (r.StackSize or 1) or 1
    end
    local function packer_form(v) -- char.lua's map, else LAC's list
        if type(v) ~= 'table' then return 'map' end
        for k in pairs(v) do
            if type(k) == 'number' then return 'list' end
        end
        return 'map'
    end

    local function job_name() return files.JobFile() or 'the job file' end
    -- who and what each target is: this character's name, and the job file's job (WHM.lua: WHM)
    local function char_name() return ((gState ~= nil) and gState.PlayerName) or 'this character' end
    local function job_abbr() return string.match(job_name(), '^(%u%u%u)') or 'this job' end
    local function where_label(from)
        if from == 'own' then return char_name() .. ', every job' end
        if from == 'shared' then return 'every character' end
        if from == 'job' then return char_name() .. ', ' .. job_abbr() .. ' only' end
        return 'default'
    end
    local function target_name(t)
        if t == 'own' then return 'char.lua' end
        if t == 'shared' then return 'goomswap-shared.lua' end
        return job_name()
    end

    -- A value as its box shows it: a text setting as it is, anything else as Lua.
    local function text_of(v, plain)
        if v == nil then return '' end
        if (type(v) == 'string') and plain then return v end
        return groups.SerializeValue(v, setFile.QuoteText, setFile.FormatKey)
    end
    -- Lua data (no code run; T{...} allowed): the value, and whether it read.
    local function data(text)
        local chunk = (loadstring or load)('return ' .. text)
        if chunk == nil then return nil, false end
        if setfenv ~= nil then setfenv(chunk, { T = function(t) return t end }) end
        local ok, v = pcall(chunk)
        return v, ok
    end
    local function same(a, b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= 'table' then return a == b end
        for k, v in pairs(a) do
            if not same(v, b[k]) then return false end
        end
        for k in pairs(b) do
            if a[k] == nil then return false end
        end
        return true
    end
    -- One the panel can write back as it is (tables: what the writer gives reads back the same).
    local function editable(v)
        if (type(v) == 'function') or (type(v) == 'userdata') then return false end
        if type(v) ~= 'table' then return true end
        local back, ok = data(groups.SerializeValue(v, setFile.QuoteText, setFile.FormatKey))
        return ok and same(back, v)
    end
    -- The typed text as a value of the setting's kind (by its default); nil and what it must be when it can't be.
    local function parse(key, text, default)
        local lim = LIMITS[key]
        if ((type(default) == 'number') or (lim ~= nil)) and not LUA_TEXT[key] then
            local n = tonumber(text)
            if n == nil then return nil, 'a number' end
            if lim ~= nil then
                local range = tostring(lim[1]) .. ((lim[2] ~= nil) and ('-' .. lim[2]) or ' or more')
                if (n < lim[1]) or ((lim[2] ~= nil) and (n > lim[2])) then return nil, range end
                if lim[3] and (math.floor(n) ~= n) then return nil, 'a whole number, ' .. range end
            end
            return n
        end
        if (type(default) == 'string') and not LUA_TEXT[key] then return text end
        local v, ok = data(text)
        if (not ok) or (v == nil) then return nil, "Lua data, like { 'a', 'b' } or 'text'" end
        if (type(default) == 'table') and (type(v) ~= 'table') then return nil, 'a table: { ... }' end
        return v
    end

    local function keys()
        local seen, out = {}, {}
        local function add(k)
            if (type(k) == 'string') and not seen[k] then seen[k], out[#out + 1] = true, k end
        end
        for k in pairs(files.Defaults()) do add(k) end
        for k in pairs(files.Layer('shared')) do add(k) end
        for k in pairs(files.Layer('own')) do add(k) end
        for _, k in ipairs(OPTIONAL) do add(k) end
        table.sort(out, function(a, b) return string.lower(a) < string.lower(b) end)
        return out
    end

    -- Long values (Keybinds, ElementalWS) cut to a few lines in a tooltip.
    local function clip(text)
        local lines, out = 0, {}
        for line in string.gmatch(text, '[^\n]+') do
            lines = lines + 1
            if lines > 6 then
                out[#out + 1] = '    ...'
                break
            end
            out[#out + 1] = line
        end
        return table.concat(out, '\n')
    end
    local function how_to(kind, example, lim)
        if kind == 'check' then return 'Tick: on. Untick: off.' end
        if (kind == 'number') or (tonumber(example or '') ~= nil) then
            local range = (lim ~= nil) and (' from ' .. lim[1] .. ((lim[2] ~= nil) and (' to ' .. lim[2]) or ' up')) or ''
            return ((lim ~= nil) and lim[3] and 'A whole number' or 'A number') .. range
                .. (example and (', like: ' .. example) or '.')
        end
        if kind == 'text' then return 'Text as it is, no quotes' .. (example and (', like: ' .. example) or '.') end
        return 'Lua' .. (example and (', like: ' .. example) or (": { 'a', 'b' } or 'text'"))
    end
    -- This job's own line for name, as the tooltip says it.
    local function job_says(name, plain)
        local v, how = files.Job(name)
        if how == 'code' then return '(code in the file: edit it there)' end
        if (how ~= 'staged') and (how ~= 'file') then
            return (how == 'none') and '(not set)' or ('(' .. how .. ': edit it in the file)')
        end
        return ((v == nil) and '(taken out)' or clip(text_of(v, plain))) .. ((how == 'staged') and ' (unsaved)' or '')
    end
    -- What a row's tooltip says: what it does, how to type it (with an example), then each file's value.
    local function tip_of(key, kind, default)
        local doc = DOC[key]
        local plain = (kind == 'text') -- shown as typed
        local function layer(which)
            local v = files.Layer(which)[key]
            return (v == nil) and '(not set)' or clip(text_of(v, plain))
        end
        return ((doc ~= nil) and (doc[1] .. '\n\n') or '') .. how_to(kind, doc and doc[2], LIMITS[key])
            .. '\n\nDefault: ' .. ((default == nil) and '(none)' or clip(text_of(default, plain)))
            .. '\nEvery character: ' .. layer('shared') .. '\n' .. char_name() .. ', every job: ' .. layer('own')
            .. '\n' .. char_name() .. ', ' .. job_abbr() .. ' only (' .. job_name() .. '): ' .. job_says('settings.' .. key, plain)
    end

    -- Saved now (char.lua, the shared file), or staged for the job file's Save.
    local function save(target, key, value, tMeta)
        local ui = editorState.ui
        if target == 'job' then
            files.StageJob('settings.' .. key, value, tMeta)
            feedback(key .. ((value == files.REMOVE) and ' taken out of ' or ' set in ') .. job_name()
                .. ': written by Save.')
            ui.settingsEdit[key] = nil
            return true
        end
        local ok, err = files.Write(target, { [key] = value })
        if ok then
            feedback(key .. ((value == files.REMOVE) and ' cleared' or ' saved') .. ' in ' .. target_name(target)
                .. ': /lac reload to use it everywhere.')
        else
            feedback(key .. ' not saved: ' .. tostring(err) .. '.')
        end
        ui.settingsEdit[key] = nil -- its box shows the new value
        return ok
    end

    -- The value box (or checkbox) of a row; true when its text differs from the value. ed: the row's state.
    local function value_box(id, ed, check, v, example, onCheck)
        if not ed.editable then
            imgui.TextColored(palette.dim, ed.why or '(edit this one in the file)')
            return false
        end
        if check then
            local b = { v == true }
            if imgui.Checkbox('##' .. id, b) then onCheck(b[1]) end
            return false
        end
        local lines = select(2, string.gsub(ed.text[1], '\n', '\n')) + 1
        if (type(v) == 'table') or (lines > 1) then
            imgui.InputTextMultiline('##' .. id, ed.text, 2048, { BOX_W, math.min(8, lines + 1) * 15 + 6 })
        else
            imgui.PushItemWidth(BOX_W)
            imgui.InputTextWithHint('##' .. id, example or '', ed.text, 512) -- empty: the example, greyed
            imgui.PopItemWidth()
        end
        return ed.text[1] ~= ed.base
    end

    local function retired_row(key, target)
        local which = (target == 'job') and nil or target
        local here = (which ~= nil) and files.Layer(which)[key]
        imgui.TextColored(palette.warn, key)
        if imgui.IsItemHovered() then set_tip(RETIRED[key]) end
        imgui.SameLine(200)
        imgui.TextColored(palette.dim, (here ~= nil) and ('set in ' .. target_name(which) .. ', not used') or 'not used')
        if here == nil then return end
        if (key == 'PackerItems') and (type(here) == 'table') then
            imgui.SameLine()
            if imgui.SmallButton('Move to Packer##retired_' .. key) then
                local packer = files.Top(which, 'Packer')
                local merged = {}
                for k, x in pairs(packer or {}) do merged[k] = x end
                for name, n in pairs(here) do
                    if type(name) == 'string' then
                        if packer_form(merged) == 'list' then
                            merged[#merged + 1] = { Name = name, Quantity = n }
                        elseif merged[name] == nil then
                            merged[name] = n
                        end
                    end
                end
                local ok, err = files.WriteTop(which, 'Packer', merged)
                if ok then ok, err = files.Write(which, { [key] = files.REMOVE }) end
                feedback(ok and ('PackerItems moved into Packer in ' .. target_name(which) .. '.')
                    or ('Not moved: ' .. tostring(err) .. '.'))
            end
            if imgui.IsItemHovered() then set_tip('Its items go into Packer in the same file, then it is taken out.') end
        end
        imgui.SameLine()
        if imgui.SmallButton('Clear##retired_clear_' .. key) then save(which, key, files.REMOVE) end
    end

    local function row(key, target)
        if RETIRED[key] then return retired_row(key, target) end
        local ui = editorState.ui
        local v, from
        if target == 'job' then v, from = files.GetForJob(key) else v, from = files.Get(key) end
        local default = files.Defaults()[key]
        local plain = (type(default) == 'string') and not LUA_TEXT[key]
        local now = text_of(v, plain)
        local jobHow = (target == 'job') and select(2, files.Job('settings.' .. key)) or nil
        local ed = ui.settingsEdit[key]
        if (ed == nil) or (ed.base ~= now) or (ed.target ~= target) then
            ed = { base = now, text = { now }, target = target, editable = editable(v) } -- read back once
            if (jobHow == 'code') or ((jobHow ~= nil) and string.match(jobHow, '^set in')) then
                ed.editable, ed.why = false, '(' .. ((jobHow == 'code') and 'code' or jobHow) .. ' in the job file: edit it there)'
            end
            ui.settingsEdit[key] = ed
        end
        local check = ((type(v) == 'boolean') or ((v == nil) and (type(default) == 'boolean'))) and not LUA_TEXT[key]
        if ed.tip == nil then -- made when the row's value changes, not every frame
            local kind = check and 'check' or (((type(default) == 'number') and not LUA_TEXT[key]) and 'number')
                or (plain and 'text') or 'lua'
            ed.tip = tip_of(key, kind, default)
        end
        imgui.TextUnformatted(key)
        if imgui.IsItemHovered() then set_tip(ed.tip) end
        imgui.SameLine(200)
        -- a T{} default: this job's line is written T{...} (its methods: HoldExempt:contains)
        local tMeta = (type(default) == 'table') and (getmetatable(default) ~= nil)
        local kind = ed.editable and widget_kind(key, v) or nil
        if kind ~= nil then -- a control under its name; the line keeps where it comes from and Clear
            imgui.TextColored(((from == 'own') or (from == 'job')) and palette.ok
                or ((from == 'shared') and palette.blue or palette.dim), where_label(from))
            local has
            if target == 'job' then has = (files.Job('settings.' .. key) ~= nil) else has = (files.Layer(target)[key] ~= nil) end
            if has then
                imgui.SameLine()
                if imgui.SmallButton('Clear##set_clear_' .. key) then save(target, key, files.REMOVE) end
            end
            imgui.Indent(24)
            local nv = draw_widget(kind, 'w_' .. target .. '_' .. key, v)
            imgui.Unindent(24)
            if nv ~= nil then save(target, key, nv, tMeta) end
            return
        end
        local changed = value_box('set_' .. key, ed, check, v, DOC[key] and DOC[key][2],
            function(b) save(target, key, b, tMeta) end)
        if imgui.IsItemHovered() then set_tip(ed.tip) end
        imgui.SameLine()
        imgui.TextColored(((from == 'own') or (from == 'job')) and palette.ok
            or ((from == 'shared') and palette.blue or palette.dim), where_label(from))
        if changed then
            imgui.SameLine()
            if imgui.SmallButton('Save##set_save_' .. key) then
                local value, want = parse(key, ed.text[1], default)
                if value == nil then feedback(key .. ' must be ' .. want .. '.') else save(target, key, value, tMeta) end
            end
            imgui.SameLine()
            if imgui.SmallButton('Undo##set_undo_' .. key) then ed.text[1] = ed.base end
        end
        local has
        if target == 'job' then
            local jv, how = files.Job('settings.' .. key)
            has = (jv ~= nil) and ((how == 'staged') or (how == 'file'))
        else
            has = (files.Layer(target)[key] ~= nil)
        end
        if has and ed.editable then
            imgui.SameLine()
            if imgui.SmallButton('Clear##set_clear_' .. key) then save(target, key, files.REMOVE) end
            if imgui.IsItemHovered() then
                set_tip('Takes it out of ' .. target_name(target) .. (((target == 'own') or (target == 'job'))
                    and ': the value below it comes back.' or ': the default comes back.'))
            end
        end
        if (target == 'shared') and (from == 'own') then
            imgui.SameLine()
            imgui.TextColored(palette.warn, '(char.lua sets its own here)')
        elseif (target ~= 'job') and (files.Job('settings.' .. key) ~= nil) then
            imgui.SameLine()
            imgui.TextColored(palette.warn, '(' .. job_name() .. ' sets its own)')
        end
    end

    -- The job file's own Packer list (profile.Packer, LAC's): rows of items and counts, staged for Save; and Get gear.
    local function packer_job_row(entry)
        local name = entry[1]
        local v, how = files.Job(name)
        imgui.TextUnformatted('Packer')
        if imgui.IsItemHovered() then set_tip(entry[2]) end
        imgui.SameLine(200)
        imgui.TextColored((how == 'staged') and palette.warn or ((v ~= nil) and palette.ok or palette.dim),
            (how == 'staged') and 'unsaved' or ((v ~= nil) and where_label('job') or 'not set'))
        local engine = ((files.Engine ~= nil) and files.Engine()) or gcinclude -- the gcinclude the editor runs with
        local ready, why = false, nil
        if engine == nil then
            why = 'no GoomSwap job file is loaded (/lac load)'
        elseif engine.PackerReady == nil then
            why = 'the newest common\\gcinclude.lua: an older one is loaded. Copy common\\ again, then /lac reload'
        else
            ready, why = engine.PackerReady()
        end
        imgui.SameLine()
        if imgui.BeginDisabled ~= nil and not ready then imgui.BeginDisabled() end
        if imgui.SmallButton('Get gear now##packer_get') and ready then
            if engine.GetGear() then feedback('/lac gear: the Packer plugin is fetching your sets\' gear and this list.') end
        end
        if imgui.EndDisabled ~= nil and not ready then imgui.EndDisabled() end
        if imgui.IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled or 0) then
            set_tip(ready and ('/lac gear: every set\'s gear, this list, char.lua\'s Packer and the items GoomSwap '
                .. 'wears, into your wardrobes and inventory.' .. ((how == 'staged') and ' Save first: the list here '
                .. 'is not saved yet.' or '')) or ('Get gear now needs ' .. tostring(why) .. '.'))
        end
        if (how == 'code') or string.match(how or '', '^set in') then
            imgui.TextColored(palette.dim, '(' .. how .. ' in the file: edit it there)')
            return
        end
        imgui.Indent(24)
        local nv = W.Packer('w_job_packer', v, 'list', { known = item_known, stackOf = stack_of })
        imgui.Unindent(24)
        if nv ~= nil then files.StageJob(name, nv) end
        -- the Bellhop list this file still has: offered into this one
        local old, oldHow = files.Job('Packer')
        if (old ~= nil) and (oldHow == 'file' or oldHow == 'staged') then
            imgui.TextColored(palette.warn, 'gcinclude.Packer (the Bellhop list) is no longer read.')
            imgui.SameLine()
            if imgui.SmallButton('Move into Packer##packer_move') then
                local merged = {}
                for _, x in ipairs((type(v) == 'table') and v or {}) do merged[#merged + 1] = x end
                for item, n in pairs((type(old) == 'table') and old or {}) do
                    if type(item) == 'string' and (n ~= false) then
                        if (n == 'stack') or (n == true) then n = stack_of(item) end
                        merged[#merged + 1] = (n == 1) and item or { Name = item, Quantity = n }
                    end
                end
                files.StageJob(name, merged)
                files.StageJob('Packer', files.REMOVE)
                feedback('gcinclude.Packer moved into Packer: written by Save.')
            end
            if imgui.IsItemHovered() then set_tip('Its items join this list (a stack as its size) and its line goes, on Save.') end
        end
    end

    -- A job-file-only option (gcinclude.<name>): staged for Save.
    local function job_row(entry)
        local ui = editorState.ui
        local name, desc, example, unset, readonly = entry[1], entry[2], entry[3], entry[4], entry[5]
        if name == 'profile.Packer' then return packer_job_row(entry) end
        local v, how = files.Job(name)
        local kind = (not readonly) and (how ~= 'code') and not string.match(how or '', '^set in')
            and widget_kind(name, v) or nil
        if kind ~= nil then
            imgui.TextUnformatted(name)
            if imgui.IsItemHovered() then set_tip(desc .. '\n\nNot set: ' .. tostring(unset or 'nothing')) end
            imgui.SameLine(200)
            imgui.TextColored((how == 'staged') and palette.warn or ((v ~= nil) and palette.ok or palette.dim),
                (how == 'staged') and 'unsaved' or ((v ~= nil) and where_label('job') or 'not set'))
            if v ~= nil then
                imgui.SameLine()
                if imgui.SmallButton('Clear##job_clear_' .. name) then files.StageJob(name, files.REMOVE) end
            end
            imgui.Indent(24)
            local nv = draw_widget(kind, 'w_jobopt_' .. name, v)
            imgui.Unindent(24)
            if nv ~= nil then files.StageJob(name, nv) end
            return
        end
        local now = text_of(v)
        local id = 'job_' .. name
        local ed = ui.settingsEdit[id]
        if (ed == nil) or (ed.base ~= now) then
            ed = { base = now, text = { now }, editable = editable(v) and not readonly }
            if readonly then ed.why = (v ~= nil) and clip(now) or ('default ' .. tostring(unset)) end
            if (how == 'code') or string.match(how or '', '^set in') then
                ed.editable, ed.why = false, '(' .. how .. ' in the file: edit it there)'
            end
            ed.tip = desc .. '\n\n' .. (readonly and 'Shown here; changed as it says.' or how_to((example == nil) and 'check' or 'lua', example))
                .. '\n\nNot set: ' .. tostring(unset or 'nothing') .. '\n' .. job_name() .. ': ' .. job_says(name)
            ui.settingsEdit[id] = ed
        end
        imgui.TextUnformatted(name)
        if imgui.IsItemHovered() then set_tip(ed.tip) end
        imgui.SameLine(200)
        local check = ((example == nil) or (example == 'true') or (example == 'false')) and not readonly
        local cur = v
        if check and (cur == nil) then cur = (unset == 'true') end
        local changed = value_box(id, ed, check, cur, example, function(b) files.StageJob(name, b) end)
        if imgui.IsItemHovered() then set_tip(ed.tip) end
        imgui.SameLine()
        imgui.TextColored((how == 'staged') and palette.warn or ((v ~= nil) and palette.ok or palette.dim),
            (how == 'staged') and 'unsaved' or ((v ~= nil) and where_label('job') or 'not set'))
        if changed then
            imgui.SameLine()
            if imgui.SmallButton('Save##job_save_' .. name) then
                local value, ok = data(ed.text[1])
                if (not ok) or (value == nil) then
                    feedback(name .. ' must be Lua data, like ' .. tostring(example) .. '.')
                else
                    files.StageJob(name, value)
                    feedback(name .. ' set in ' .. job_name() .. ': written by Save.')
                    ui.settingsEdit[id] = nil
                end
            end
            imgui.SameLine()
            if imgui.SmallButton('Undo##job_undo_' .. name) then ed.text[1] = ed.base end
        end
        if (v ~= nil) and ed.editable then
            imgui.SameLine()
            if imgui.SmallButton('Clear##job_clear_' .. name) then
                files.StageJob(name, files.REMOVE)
                ui.settingsEdit[id] = nil
            end
            if imgui.IsItemHovered() then set_tip('Takes its line out of ' .. job_name() .. ' on Save.') end
        end
    end

    -- A setting's row shows: every one with Show all; else not the advanced ones, unless a file sets it (yours to see).
    local function wanted(key)
        if editorState.ui.settingsAll[1] or not ADVANCED[key] then return true end
        if (files.Layer('own')[key] ~= nil) or (files.Layer('shared')[key] ~= nil) then return true end
        return files.Job('settings.' .. key) ~= nil
    end
    -- A job option's row shows on the jobs that read it, or when the file sets it.
    local function job_wanted(name)
        local only = JOB_ONLY[name]
        if (only == nil) or editorState.ui.settingsAll[1] then return true end
        local abbr = string.match(job_name(), '^(%u%u%u)') -- the job file's name: BRD.lua
        if (abbr ~= nil) and only[abbr] then return true end
        return files.Job(name) ~= nil
    end

    local M = { Parse = parse, Doc = DOC, Job = JOB, Optional = OPTIONAL, LuaText = LUA_TEXT, Advanced = ADVANCED,
        Limits = LIMITS } -- for tests
    -- The window's contents (gcedit opens and closes the window around it).
    function M.Body()
        local ui = editorState.ui
        ui.settingsEdit, ui.settingsFind = ui.settingsEdit or {}, ui.settingsFind or { '' }
        ui.settingsAll = ui.settingsAll or { false }
        ui.settingsTarget = ui.settingsTarget or 'own'
        imgui.TextColored(palette.dim, 'Save to:')
        local targets = {
            { 'own', char_name() .. ': every job (char.lua)', 'Only ' .. char_name() .. ', on every job: ' },
            { 'job', char_name() .. ': ' .. job_abbr() .. ' only (' .. job_name() .. ')', 'Only ' .. char_name()
                .. ' on ' .. job_abbr() .. ': the job file open in the editor, written by its Save (like set edits). ' },
            { 'shared', 'Every character (goomswap-shared.lua)', 'Every character on this PC, unless its char.lua or job '
                .. 'file sets its own: ' },
        }
        for _, t in ipairs(targets) do
            imgui.SameLine()
            local on = (ui.settingsTarget == t[1])
            imgui.PushStyleColor(ImGuiCol_Button, on and palette.selBg or palette.btn)
            imgui.PushStyleColor(ImGuiCol_ButtonHovered, on and palette.save or palette.btnHi)
            if on then imgui.PushStyleColor(ImGuiCol_Text, palette.blue) end
            if imgui.SmallButton(t[2] .. '##set_target_' .. t[1]) then ui.settingsTarget = t[1] end
            imgui.PopStyleColor(on and 3 or 2)
            if imgui.IsItemHovered() then set_tip(t[3] .. ((t[1] == 'job') and '' or tostring(files.Path(t[1])))) end
        end
        if imgui.PushTextWrapPos ~= nil then imgui.PushTextWrapPos(0) end
        imgui.TextColored(palette.dim, char_name() .. "'s " .. job_name() .. ' wins over ' .. char_name() .. "'s char.lua, and "
            .. 'char.lua over the shared file. char.lua and the shared file are saved at once, after a backup; the job '
            .. 'file with Save. Hover a name for what it does.')
        if imgui.PopTextWrapPos ~= nil then imgui.PopTextWrapPos() end
        imgui.PushItemWidth(260)
        imgui.InputTextWithHint('##set_find', 'Find a setting: Hpp, Editor, Moonshade...', ui.settingsFind, 48)
        imgui.PopItemWidth()
        imgui.SameLine()
        imgui.Checkbox('Show all##set_all', ui.settingsAll)
        if imgui.IsItemHovered() then
            set_tip('Also the ones most never change: item names, game data, timing windows, what the heading menus '
                .. 'write. One a file sets, or a search finds, always shows.')
        end
        imgui.Separator()
        imgui.BeginChild('##set_rows', { 0, 0 }, 0)
        local find = string.lower(ui.settingsFind[1] or '')
        local function shown(name) return (find == '') or (string.find(string.lower(name), find, 1, true) ~= nil) end
        for _, key in ipairs(keys()) do
            if shown(key) and ((find ~= '') or wanted(key)) then row(key, ui.settingsTarget) end
        end
        if (ui.settingsTarget ~= 'job') and shown('Packer') then
            imgui.Separator()
            local which = ui.settingsTarget
            imgui.TextUnformatted('Packer (every job)')
            if imgui.IsItemHovered() then
                set_tip('Items /lac gear (the Packer plugin) fetches on every job of '
                    .. ((which == 'own') and 'this character' or 'every character') .. ', with each job file\'s own '
                    .. 'Packer and every set\'s gear: a count, a stack or all you have. char.lua\'s list replaces the '
                    .. 'shared one. Saved at once.')
            end
            if (which == 'shared') and (files.Top('own', 'Packer') ~= nil) then
                imgui.SameLine()
                imgui.TextColored(palette.warn, '(char.lua has its own: it wins)')
            end
            local cur = files.Top(which, 'Packer')
            imgui.Indent(24)
            local nv = W.Packer('w_top_packer_' .. which, cur, packer_form(cur), { known = item_known, stackOf = stack_of })
            imgui.Unindent(24)
            if nv ~= nil then
                local ok, err = files.WriteTop(which, 'Packer', (next(nv) ~= nil) and nv or files.REMOVE)
                feedback(ok and ('Packer saved in ' .. target_name(which) .. '.') or ('Packer not saved: ' .. tostring(err) .. '.'))
            end
        end
        imgui.Separator()
        imgui.TextColored(palette.blue, 'Only ' .. char_name() .. ' on ' .. job_abbr() .. ': ' .. job_name()
            .. "'s own options (written by Save)")
        -- a default weapon or role nothing offers: the engine skips it at load without a word
        for _, p in ipairs((files.WeaponProblems ~= nil) and files.WeaponProblems() or {}) do
            imgui.PushTextWrapPos(0)
            imgui.TextColored(palette.warn, p)
            imgui.PopTextWrapPos()
        end
        for _, entry in ipairs(JOB) do
            if shown(entry[1]) and ((find ~= '') or job_wanted(entry[1])) then job_row(entry) end
        end
        imgui.EndChild()
    end
    return M
end
