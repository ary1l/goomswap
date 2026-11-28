-- /gcedit Settings: every GoomSwap setting, its value now and where that comes from (the default, the shared file
-- every character uses, this character's char.lua, the job file open in the editor); change one for this character,
-- for every character, or for this job. Below them, the job file's own options (WeaponModes, Packer...).
return function(imgui, palette, set_tip, files, groups, setFile, editorState, feedback, version)
    -- Not in the defaults table (nil there) but read when set.
    local OPTIONAL = { 'EditorGroups', 'EditorHidden', 'EditorSort', 'EditorOrder', 'DisplayBarX', 'LockstyleSet',
        'EditorComparePins' }
    local LUA_TEXT = { Theme = true } -- false, or a preset's name: typed as Lua
    local FROM = { own = 'this character', shared = 'every character', default = 'default', job = 'this job' }
    local DOCS = gFunc.LoadFile('common\\gceditsettingsdoc.lua')
    local DOC, JOB = DOCS.settings, DOCS.job -- [key] = { what it does, an example as typed }; job: its own list
    local ADVANCED, LIMITS, JOB_ONLY = DOCS.advanced, DOCS.limits, DOCS.jobOnly
    local NAMES, CATEGORIES = DOCS.names or {}, DOCS.categories or {}
    local LABEL_W = 250 -- the value column
    local function nice(key) return NAMES[key] or key end -- the plain name a setting shows by
    local BOX_W = 340 -- at most: a box takes what is left of the row
    local W = gFunc.LoadFile('common\\gceditwidgets.lua')(imgui, palette, set_tip)
    -- A narrow window keeps every part: names wrap inside their column, boxes shrink, and a pill or button that
    -- doesn't fit goes under the value column instead of off the window's edge.
    local function avail_x() return (W.Vec(imgui.GetContentRegionAvail())) or 400 end
    local function fit_line(w, toStart)
        imgui.SameLine()
        if avail_x() < w then
            imgui.NewLine()
            if not toStart then imgui.SetCursorPosX(LABEL_W) end
        end
    end
    local function pill_w(text) return (W.Width(text) or 60) + 16 end
    local function name_cell(text)
        if imgui.PushTextWrapPos ~= nil then imgui.PushTextWrapPos(LABEL_W - 14) end
        imgui.TextUnformatted(text)
        if imgui.PopTextWrapPos ~= nil then imgui.PopTextWrapPos() end
    end
    -- Settings drawn as controls, not Lua text: names as chips, name -> value rows, keybinds. Anything else (or a
    -- value of another shape) keeps its Lua box.
    local LIST = { SIRSkip = true, THSkip = true, MBSkills = true, ElementSkills = true, HoldExempt = true,
        MoonshadeSkip = true, CapacityCapes = true, HUDOwners = true, MyBoxes = true, EditorIgnoreSuggestions = true,
        HoxneLockSlots = true, MainModes = true, SubModes = true, RangeModes = true, NukeModes = true,
        BluMagPhysical = true, BluMagDebuff = true, BluMagStun = true, BluMagBuff = true, BluMagSkill = true,
        BluMagCure = true, BluMagEnmity = true, BluMagTH = true, AmmoModes = true, MeleeModes = true }
    LIST.BarHide = true
    local MAP = { HUDAbbr = true, WeaponClass = true, ElementalWS = true, ReceivedSets = true, WeaponRoles = true,
        RangeAmmo = true, XIRollSet = true }
    -- Settings with a few fixed values: a picker, not a text box (Theme: goomui's, GoomSwap's or a preset)
    local CHOICES = { EditorSpacing = { 'Compact', 'Comfortable' }, MoonshadeSlot = { 'Ear1', 'Ear2' },
        JubileeSlot = { 'Ring1', 'Ring2' } }
    local function choices(key)
        if (key == 'Theme') and (CHOICES.Theme == nil) then
            local list, names = { { false, "goomui's own" }, 'goomswap' }, {}
            local ok, t = pcall(gFunc.LoadFile, 'common\\gctheme.lua')
            for n in pairs((ok and (type(t) == 'table') and t.PRESETS) or {}) do names[#names + 1] = n end
            table.sort(names)
            for _, n in ipairs(names) do list[#list + 1] = n end
            CHOICES.Theme = list
        end
        return CHOICES[key]
    end
    -- HoldExempt's entries: a spell skill (every spell of it), an ability type (every ability of it), else a name
    local HOLD_SKILLS = { ['Divine Magic'] = true, ['Healing Magic'] = true, ['Enhancing Magic'] = true,
        ['Enfeebling Magic'] = true, ['Elemental Magic'] = true, ['Dark Magic'] = true, ['Summoning Magic'] = true,
        Ninjutsu = true, Singing = true, ['Blue Magic'] = true, Geomancy = true }
    local HOLD_TYPES = { ['Corsair Roll'] = 'every roll', ['Quick Draw'] = 'every shot', Ready = 'every Ready move',
        ['Blood Pact: Rage'] = 'every Rage pact', ['Blood Pact: Ward'] = 'every Ward pact',
        ['Rune Enchantment'] = 'every rune' }
    local function hold_label(v)
        local t = HOLD_TYPES[tostring(v)]
        return (t ~= nil) and (tostring(v) .. ' (' .. t .. ')') or tostring(v)
    end
    local function hold_tip(v)
        v = tostring(v)
        if HOLD_SKILLS[v] then return 'Every ' .. v .. ' spell.' end
        if HOLD_TYPES[v] then
            local note = (v == 'Corsair Roll') and ", not Corsair's Roll alone." or '.'
            return 'An ability type: ' .. HOLD_TYPES[v] .. note
        end
        return 'The spell or ability by that name.'
    end
    -- Every spell and job ability name (the game's resources), for the add boxes' suggestions
    local spellNames, actionNames = nil, nil
    local function names_index()
        if actionNames ~= nil then return end
        spellNames, actionNames = {}, {}
        local ok, res = pcall(function() return AshitaCore:GetResourceManager() end)
        if (not ok) or (res == nil) then return end
        local seen = {}
        local function add(list, r)
            local n = (r ~= nil) and (r.Name ~= nil) and r.Name[1] or nil
            if (type(n) == 'string') and (n ~= '') and not seen[n] then
                seen[n] = true
                list[#list + 1] = n
                if list ~= actionNames then actionNames[#actionNames + 1] = n end
            end
        end
        for i = 1, 0x400 do add(spellNames, res:GetSpellById(i)) end
        for i = 0x200, 0x600 do add(actionNames, res:GetAbilityById(i)) end
        table.sort(spellNames)
        table.sort(actionNames)
    end
    local function starts_with(lists)
        return function(t)
            names_index()
            local lt, out = string.lower(t), {}
            for _, list in ipairs(lists()) do
                for _, n in ipairs(list) do
                    if string.sub(string.lower(n), 1, #lt) == lt then out[#out + 1] = n end
                    if #out >= 8 then return out end
                end
            end
            return out
        end
    end
    local HOLD_FIRST = {}
    -- ElementGear's parts, each its own field (a nil one, the Zodiac Ring until you name yours, just isn't there)
    local EG_FIELDS = { { 'AnyObi', 'Any-element obi', 'e.g. Hachirin-no-Obi',
            'Worn when the day or weather helps and you have no obi of that element.' },
        { 'Distance', 'Close-range piece', "e.g. Orpheus's Sash",
            'Worn instead of the obi when it gives more: the closer the target, the more it gives.' },
        { 'DistanceMax', 'its max distance', 'blank: any',
            'Yalms. Blank: no limit (it always gives at least 1%).', true },
        { 'Back', 'Day/weather back', 'blank: none', 'e.g. Twilight Cape: adds to a day or weather bonus.' } }
    local egBuf = {}
    local function element_gear(id, v)
        local cur, out = (type(v) == 'table') and v or {}, nil
        local function set(k, x)
            if out == nil then
                out = {}
                for a, b in pairs(cur) do out[a] = b end
            end
            out[k] = x
        end
        imgui.TextColored(palette.dim, 'Your element obis (element, then obi)')
        local obis = W.Map(id .. '_obis', cur.Obis or {}, { keyHint = 'element', valueHint = 'obi name' })
        if obis ~= nil then set('Obis', obis) end
        for _, f in ipairs(EG_FIELDS) do
            local k = f[1]
            -- the form's own label column, past its indent
            local x0 = (imgui.GetCursorPosX ~= nil) and imgui.GetCursorPosX() or 0
            imgui.TextUnformatted(f[2])
            if imgui.IsItemHovered() then set_tip(f[4]) end
            imgui.SameLine(x0 + 150)
            local now = (cur[k] ~= nil) and tostring(cur[k]) or ''
            local b = egBuf[id .. k]
            if (b == nil) or (b.base ~= now) then
                b = { base = now, a = { now } }
                egBuf[id .. k] = b
            end
            imgui.PushItemWidth(190)
            imgui.InputTextWithHint('##eg_' .. id .. k, f[3], b.a, 96)
            imgui.PopItemWidth()
            local typed = W.Trim(b.a[1])
            if typed ~= now then
                imgui.SameLine()
                if W.Button('Set##eg_set_' .. id .. k, 'accent') then
                    local x = (typed ~= '') and typed or nil
                    if f[5] then x = tonumber(typed) end
                    if (x ~= nil) or (typed == '') then set(k, x) end
                end
            end
        end
        -- the Zodiac Ring: on by itself when one is in your equip bags (Ring unset); off is Ring = false
        local ring = { cur.Ring ~= false }
        if imgui.Checkbox("Zodiac Ring on its element's day##eg_" .. id .. 'ring', ring) then
            set('Ring', (not ring[1]) and false or nil)
        end
        if imgui.IsItemHovered() then
            set_tip('Worn when one is in your equip bags: nothing to type. Never on Light / Dark days or cures.')
        end
        imgui.SameLine()
        imgui.TextColored(palette.dim, 'in')
        imgui.SameLine()
        local pick = W.Pick(id .. '_ringslot', cur.RingSlot or 'Ring2', { 'Ring1', 'Ring2' }, 80)
        if pick ~= nil then set('RingSlot', pick) end
        for _, f in ipairs({ { 'Cures', 'Obi on Cure, Cura, Curaga in Light day or weather' },
            { 'BackOnCures', 'The back on those cures too' } }) do
            local b = { cur[f[1]] == true }
            if imgui.Checkbox(f[2] .. '##eg_' .. id .. f[1], b) then set(f[1], b[1]) end
        end
        imgui.TextColored(palette.dim, 'Never swapped out while worn')
        if imgui.IsItemHovered() then
            set_tip('When your set puts one of these on (Oneiros Rope in Waist...), the obi, close-range piece, '
                .. 'ring and back leave that slot alone.')
        end
        local keep = W.List(id .. '_keep', cur.Keep or {}, { hint = 'e.g. Oneiros Rope' })
        if keep ~= nil then set('Keep', keep) end
        return out
    end
    -- the words on the bar's pills, for BarHide's suggestions
    local BAR_WORDS = { 'melee', 'ws', 'idle', 'nuke', 'weapon', 'tank', 'pup', 'hoxne', 'def', 'sir', 'th', 'kite',
        'proc', 'burst', 'death', 'harp', 'lock' }
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
        if (key == 'ElementGear') and ((v == nil) or (type(v) == 'table')) then return 'element' end
        if choices(key) ~= nil then
            local fits = (v == nil) or (type(v) == 'string') or ((key == 'Theme') and (v == false))
            return fits and 'choice' or nil
        end
        if LIST[key] and is_list(v) then return 'list' end
        if (key == 'KeepWeaponsFor') and (v == nil or type(v) == 'table') then -- names and { Spells, Worn } rows
            for _, x in ipairs(v or {}) do
                if (type(x) ~= 'string') and ((type(x) ~= 'table') or (type(x.Spells) ~= 'table')
                    or (type(x.Worn) ~= 'table')) then return nil end
            end
            return 'keep'
        end
        if MAP[key] and is_map(v) then return 'map' end
        if NUMBER_MAP[key] and is_map(v, true) then return 'nmap' end
        return nil
    end
    local function draw_widget(kind, id, v, key)
        if kind == 'choice' then
            local label = (v == nil) and 'default' or tostring(v)
            for _, o in ipairs(choices(key)) do
                if (type(o) == 'table') and (o[1] == v) then label = o[2] end
            end
            return W.Pick(id, label, choices(key), 200)
        end
        if kind == 'element' then return element_gear(id, v) end
        if (kind == 'list') and (key == 'HoldExempt') then
            if #HOLD_FIRST == 0 then
                for n in pairs(HOLD_SKILLS) do HOLD_FIRST[#HOLD_FIRST + 1] = n end
                for n in pairs(HOLD_TYPES) do HOLD_FIRST[#HOLD_FIRST + 1] = n end
                table.sort(HOLD_FIRST)
            end
            return W.List(id, v, { label = hold_label, tip = hold_tip, width = 300,
                hint = 'skill, ability type or name', suggest = starts_with(function()
                    return { HOLD_FIRST, actionNames or {} }
                end) })
        end
        if (kind == 'list') and (key == 'BarHide') then
            return W.List(id, v, { hint = 'harp, lock...', suggest = function(t)
                local out = {}
                for _, w in ipairs(BAR_WORDS) do
                    if string.sub(w, 1, #t) == string.lower(t) then out[#out + 1] = w end
                end
                return out
            end })
        end
        if kind == 'list' then return W.List(id, v) end
        if kind == 'keep' then -- spells only: SmartSwap acts on casts
            return W.KeepList(id, v, { suggest = starts_with(function() return { spellNames or {} } end) })
        end
        if kind == 'map' then return W.Map(id, v) end
        if kind == 'nmap' then return W.Map(id, v, { number = true, valueHint = 'seconds' }) end
        if kind == 'keys' then return W.Keybinds(id, v) end
        return nil
    end
    local function item_known(name) -- the game's spelling of an item's name, nil when there is none
        local r = AshitaCore:GetResourceManager():GetItemByName(name, 0)
        return (r ~= nil) and (r.Name[1] or name) or nil
    end
    local function stack_of(name) -- the engine's (gcinclude.StackOf), 1 when it isn't loaded
        local e = (files.Engine ~= nil) and files.Engine() or nil
        return ((type(e) == 'table') and (e.StackOf ~= nil)) and e.StackOf(name) or 1
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
    local function tag_colors(from)
        if (from == 'own') or (from == 'job') then return palette.ok, palette.okBg end
        if from == 'shared' then return palette.blue, palette.selBg end
        if from == 'staged' then return palette.warn, palette.warnBg end
        return palette.dim, palette.chipBg
    end
    local function where_label(from) -- short: the legend's hover says whose
        if from == 'own' then return 'all jobs' end
        if from == 'shared' then return 'everyone' end
        if from == 'job' then return job_abbr() .. ' only' end
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
    -- Lua data (no code run; T{...} allowed): the value, and whether it read; two values alike, tables deeply.
    local data, same = files.ValueOf, files.Same
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
        if kind == 'widget' then -- a chip or form row: edited with its controls, never typed as Lua
            local function brief(v)
                if type(v) ~= 'table' then return clip(text_of(v, plain)) end
                local parts = {}
                for _, x in ipairs(v) do parts[#parts + 1] = (type(x) == 'table') and W.KeepText(x) or tostring(x) end
                if #parts == 0 then
                    for k, x in pairs(v) do
                        if type(x) ~= 'table' then parts[#parts + 1] = tostring(k) .. ' = ' .. tostring(x) end
                    end
                    table.sort(parts)
                end
                local s = table.concat(parts, ', ')
                if #s > 180 then s = string.sub(s, 1, 177) .. '...' end
                return (s ~= '') and s or '(none)'
            end
            local by = {}
            if files.Layer('shared')[key] ~= nil then by[#by + 1] = 'everyone' end
            if files.Layer('own')[key] ~= nil then by[#by + 1] = 'all jobs (char.lua)' end
            if select(2, files.Job('settings.' .. key)) ~= 'none' then by[#by + 1] = job_abbr() .. ' only' end
            return ((doc ~= nil) and (doc[1] .. '\n\n') or '') .. 'Default: '
                .. ((default == nil) and '(none)' or brief(default))
                .. ((#by > 0) and ('\nSet in: ' .. table.concat(by, ', '))
                    or '\nNot set in any file: the default is used.')
                .. '\n\nKey: ' .. key
        end
        local set = {} -- only the files that set it: three "(not set)" lines said nothing
        if files.Layer('shared')[key] ~= nil then set[#set + 1] = 'everyone: ' .. layer('shared') end
        if files.Layer('own')[key] ~= nil then set[#set + 1] = 'all jobs (char.lua): ' .. layer('own') end
        local js = job_says('settings.' .. key, plain)
        if js ~= '(not set)' then set[#set + 1] = job_abbr() .. ' only (' .. job_name() .. '): ' .. js end
        return ((doc ~= nil) and (doc[1] .. '\n\n') or '') .. how_to(kind, doc and doc[2], LIMITS[key])
            .. '\n\nDefault: ' .. ((default == nil) and '(none)' or clip(text_of(default, plain)))
            .. ((#set > 0) and ('\n' .. table.concat(set, '\n')) or '\nNot set in any file: the default is used.')
            .. '\n\nKey: ' .. key
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
    -- A number's - / + step: 100 for TP, 5 for HP / MP %, else 1; kept inside its limits (LIMITS)
    local function stepper_of(key, default)
        if (type(default) ~= 'number') or LUA_TEXT[key] then return nil end
        local step = string.match(key, 'TP$') and 100 or ((string.match(key, 'HPP$') or string.match(key, 'MPP$')) and 5
            or 1)
        return { step = step, lim = LIMITS[key] }
    end
    local function value_box(id, ed, check, v, example, onCheck, stepper)
        -- its hover (ed.tip) on its own control: what follows it (- / +, a note) keeps its own
        if not ed.editable then
            if imgui.PushTextWrapPos ~= nil then imgui.PushTextWrapPos(0) end
            imgui.TextColored(palette.dim, ed.why or '(edit this one in the file)')
            if imgui.PopTextWrapPos ~= nil then imgui.PopTextWrapPos() end
            if imgui.IsItemHovered() then set_tip(ed.tip) end
            return false
        end
        if check then
            local b = { v == true }
            if imgui.Checkbox('##' .. id, b) then onCheck(b[1]) end
            if imgui.IsItemHovered() then set_tip(ed.tip) end
            return false
        end
        local lines = select(2, string.gsub(ed.text[1], '\n', '\n')) + 1
        local w = math.max(140, math.min(BOX_W, avail_x() - 8))
        if (type(v) == 'table') or (lines > 1) then
            imgui.InputTextMultiline('##' .. id, ed.text, 2048, { w, math.min(8, lines + 1) * 15 + 6 })
            local hovered = imgui.IsItemHovered()
            imgui.TextColored(palette.dim, 'typed as Lua (advanced)') -- no control for this one's shape
            if hovered then set_tip(ed.tip) end
        else
            imgui.PushItemWidth(stepper and (w - 52) or w)
            imgui.InputTextWithHint('##' .. id, example or '', ed.text, 512) -- empty: the example, greyed
            imgui.PopItemWidth()
            if imgui.IsItemHovered() then set_tip(ed.tip) end
            if stepper ~= nil then -- - / +, as typed: Save keeps it
                for _, d in ipairs({ { '-', -1 }, { '+', 1 } }) do
                    imgui.SameLine(0, 2)
                    if imgui.SmallButton(d[1] .. '##step_' .. id) then
                        local n = (tonumber(ed.text[1]) or tonumber(v) or 0) + d[2] * stepper.step
                        local lim = stepper.lim
                        if lim ~= nil then
                            if (lim[1] ~= nil) and (n < lim[1]) then n = lim[1] end
                            if (lim[2] ~= nil) and (n > lim[2]) then n = lim[2] end
                        end
                        ed.text[1] = tostring(n)
                    end
                    if imgui.IsItemHovered() then
                        set_tip(((d[2] < 0) and 'Down ' or 'Up ') .. stepper.step .. '; Save keeps it.')
                    end
                end
            end
        end
        return ed.text[1] ~= ed.base
    end

    -- What Reset brings back: the value of the file under this one (job file > char.lua > everyone > default)
    local function reset_tip(target)
        if target == 'job' then
            return 'Takes its line out of ' .. job_name() .. ' on Save: char.lua\'s (or the default) comes back.'
        end
        if target == 'own' then return "Takes it out of char.lua: everyone's (or the default) comes back." end
        return 'Takes it out of the shared file: the default comes back.'
    end
    local function retired_row(key, target)
        local which = (target == 'job') and nil or target
        local here = (which ~= nil) and files.Layer(which)[key]
        imgui.TextColored(palette.warn, key)
        if imgui.IsItemHovered() then set_tip(RETIRED[key]) end
        imgui.SameLine(LABEL_W)
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
        fit_line(64)
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
            if ed.editable and (widget_kind(key, v) ~= nil) then kind = 'widget' end
            ed.tip = tip_of(key, kind, default)
        end
        name_cell(nice(key))
        if imgui.IsItemHovered() then set_tip(ed.tip) end
        imgui.SameLine(LABEL_W)
        -- a T{} default: this job's line is written T{...} (its methods: HoldExempt:contains)
        local tMeta = (type(default) == 'table') and (getmetatable(default) ~= nil)
        local kind = ed.editable and widget_kind(key, v) or nil
        if kind == 'choice' then -- a picker on the name's line, then where it comes from and Reset
            local nv = draw_widget(kind, 'w_' .. target .. '_' .. key, v, key)
            fit_line(pill_w(where_label(from)))
            W.Pill(where_label(from), tag_colors(from))
            local has
            if target == 'job' then has = (files.Job('settings.' .. key) ~= nil) else has = (files.Layer(target)[key] ~= nil) end
            if has then
                fit_line(64)
                if imgui.SmallButton('Reset##set_clear_' .. key) then save(target, key, files.REMOVE) end
                if imgui.IsItemHovered() then set_tip(reset_tip(target)) end
            end
            if nv ~= nil then save(target, key, nv, tMeta) end
            return
        end
        if kind ~= nil then -- a control under its name; the line keeps where it comes from and Reset
            W.Pill(where_label(from), tag_colors(from))
            local has
            if target == 'job' then has = (files.Job('settings.' .. key) ~= nil) else has = (files.Layer(target)[key] ~= nil) end
            if has then
                fit_line(64)
                if imgui.SmallButton('Reset##set_clear_' .. key) then save(target, key, files.REMOVE) end
                if imgui.IsItemHovered() then set_tip(reset_tip(target)) end
            end
            imgui.Indent(24)
            local nv = draw_widget(kind, 'w_' .. target .. '_' .. key, v, key)
            imgui.Unindent(24)
            if nv ~= nil then save(target, key, nv, tMeta) end
            return
        end
        local changed = value_box('set_' .. key, ed, check, v, DOC[key] and DOC[key][2],
            function(b) save(target, key, b, tMeta) end, (not check) and stepper_of(key, default) or nil)
        fit_line(pill_w(where_label(from)))
        W.Pill(where_label(from), tag_colors(from))
        if changed then
            fit_line(64)
            if imgui.SmallButton('Save##set_save_' .. key) then
                local value, want = parse(key, ed.text[1], default)
                if value == nil then feedback(key .. ' must be ' .. want .. '.') else save(target, key, value, tMeta) end
            end
            fit_line(64)
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
            fit_line(64)
            if imgui.SmallButton('Reset##set_clear_' .. key) then save(target, key, files.REMOVE) end
            if imgui.IsItemHovered() then set_tip(reset_tip(target)) end
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
        imgui.TextUnformatted('Packer (' .. job_abbr() .. ')')
        if imgui.IsItemHovered() then set_tip(entry[2] .. '\n\nKey: profile.Packer') end
        imgui.SameLine(LABEL_W)
        W.Pill((how == 'staged') and 'unsaved' or ((v ~= nil) and where_label('job') or 'default'),
                tag_colors((how == 'staged') and 'staged' or ((v ~= nil) and 'job' or 'default')))
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
        local shown = v -- the value the control starts from: the job file's, else the engine's own list (BluMag...)
        local newModes = (name == 'MeleeModes') and (editorState.document or {}).newModes or nil
        if newModes ~= nil then -- + /mset mode's adds, written by Save, are in it already
            local have, list = {}, {}
            for i, m in ipairs(shown or { 'Default', 'SubtleBlow', 'Acc' }) do
                list[i], have[string.lower(m)] = m, true
            end
            for _, m in ipairs(newModes) do
                if not have[string.lower(m)] then list[#list + 1], have[string.lower(m)] = m, true end
            end
            shown = list
        end
        if (shown == nil) and string.match(name, '^BluMag') then
            local e = (files.Engine ~= nil) and files.Engine() or nil
            if (e ~= nil) and (type(rawget(e, name)) == 'table') then
                shown = {}
                for i, n in ipairs(rawget(e, name)) do shown[i] = n end
            end
        end
        local kind = (not readonly) and (how ~= 'code') and not string.match(how or '', '^set in')
            and widget_kind(name, shown) or nil
        if kind ~= nil then
            name_cell(nice(name))
            if imgui.IsItemHovered() then
                set_tip(desc .. '\n\nNot set: ' .. tostring(unset or 'nothing') .. '\n\nKey: ' .. name)
            end
            imgui.SameLine(LABEL_W)
            W.Pill((how == 'staged') and 'unsaved' or ((v ~= nil) and where_label('job') or 'default'),
                tag_colors((how == 'staged') and 'staged' or ((v ~= nil) and 'job' or 'default')))
            if v ~= nil then
                fit_line(64)
                if imgui.SmallButton('Reset##job_clear_' .. name) then files.StageJob(name, files.REMOVE) end
                if imgui.IsItemHovered() then
                    set_tip('Takes its line out of ' .. job_name() .. ' on Save: the default comes back.')
                end
            end
            imgui.Indent(24)
            local nv = draw_widget(kind, 'w_jobopt_' .. name, shown, name)
            imgui.Unindent(24)
            -- BluMag lists written T{...}: job files call gcinclude.BluMagTH:contains(...)
            if nv ~= nil then files.StageJob(name, nv, string.match(name, '^BluMag') ~= nil) end
            if (nv ~= nil) and (newModes ~= nil) then -- a new mode taken out here: not added at Save either
                local keep, left = {}, {}
                for _, m in ipairs(nv) do keep[string.lower(m)] = true end
                for _, m in ipairs(newModes) do if keep[string.lower(m)] then left[#left + 1] = m end end
                editorState.document.newModes = left
            end
            return
        end
        local now = text_of(v)
        local id = 'job_' .. name
        local ed = ui.settingsEdit[id]
        if (ed == nil) or (ed.base ~= now) then
            ed = { base = now, text = { now }, editable = editable(v) and not readonly }
            if readonly then ed.why = (v ~= nil) and clip(now) or tostring(unset or 'nothing') end -- its pill says default
            if (how == 'code') or string.match(how or '', '^set in') then
                ed.editable, ed.why = false, '(' .. how .. ' in the file: edit it there)'
            end
            ed.tip = desc .. '\n\n' .. (readonly and 'Shown here; changed as it says.' or how_to((example == nil) and 'check' or 'lua', example))
                .. '\n\nNot set: ' .. tostring(unset or 'nothing') .. '\n' .. job_name() .. ': ' .. job_says(name)
                .. '\n\nKey: ' .. name
            ui.settingsEdit[id] = ed
        end
        name_cell(nice(name))
        if imgui.IsItemHovered() then set_tip(ed.tip) end
        imgui.SameLine(LABEL_W)
        local check = ((example == nil) or (example == 'true') or (example == 'false')) and not readonly
        local cur = v
        if check and (cur == nil) then cur = (unset == 'true') end
        local changed = value_box(id, ed, check, cur, example, function(b) files.StageJob(name, b) end,
            (not check) and (tonumber(example or '') ~= nil) and { step = 1 } or nil)
        fit_line(pill_w((v ~= nil) and where_label('job') or 'default'))
        W.Pill((how == 'staged') and 'unsaved' or ((v ~= nil) and where_label('job') or 'default'),
                tag_colors((how == 'staged') and 'staged' or ((v ~= nil) and 'job' or 'default')))
        if changed then
            fit_line(64)
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
            fit_line(64)
            if imgui.SmallButton('Undo##job_undo_' .. name) then ed.text[1] = ed.base end
        end
        if (v ~= nil) and ed.editable then
            fit_line(64)
            if imgui.SmallButton('Reset##job_clear_' .. name) then
                files.StageJob(name, files.REMOVE)
                ui.settingsEdit[id] = nil
            end
            if imgui.IsItemHovered() then
                set_tip('Takes its line out of ' .. job_name() .. ' on Save: the default comes back.')
            end
        end
    end

    -- A setting's row shows: every one with Show all; else not the advanced ones, unless a file sets it (yours to see).
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
    -- The every-job Packer list (char.lua or the shared file), saved at once.
    local function top_packer_row(which)
        imgui.TextUnformatted('Packer (every job)')
        if imgui.IsItemHovered() then
            set_tip('Items /lac gear (the Packer plugin) fetches on every job of '
                .. ((which == 'own') and char_name() or 'every character') .. ', with each job file\'s own '
                .. 'Packer and every set\'s gear: a count, a stack or all you have. char.lua\'s list replaces the '
                .. 'shared one. Saved at once.\n\nKey: Packer')
        end
        if (which == 'shared') and (files.Top('own', 'Packer') ~= nil) then
            imgui.SameLine()
            imgui.TextColored(palette.warn, '(' .. char_name() .. "'s char.lua has its own: it wins)")
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
    local function job_entry(name)
        for _, entry in ipairs(JOB) do
            if entry[1] == name then return entry end
        end
        return nil
    end
    local function job_options()
        -- a default weapon or role nothing offers: the engine skips it at load without a word
        for _, p in ipairs((files.WeaponProblems ~= nil) and files.WeaponProblems() or {}) do
            imgui.PushTextWrapPos(0)
            imgui.TextColored(palette.warn, p)
            imgui.PopTextWrapPos()
        end
        for _, entry in ipairs(JOB) do
            if job_wanted(entry[1]) then job_row(entry) end
            imgui.Spacing()
        end
    end
    -- One line of the list: a setting by its key, or Packer (every job, or this job's on the job target).
    local function line(key, target)
        if key == 'Packer' then
            if target == 'job' then
                local e = job_entry('profile.Packer')
                if e ~= nil then packer_job_row(e) end
            else
                top_packer_row(target)
            end
        else
            row(key, target)
        end
        imgui.Spacing()
    end

    local function segment(label, on, id)
        imgui.PushStyleColor(ImGuiCol_Button, on and palette.selBg or palette.btn)
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, on and palette.save or palette.btnHi)
        if on then imgui.PushStyleColor(ImGuiCol_Text, palette.blue) end
        local hit = imgui.Button(label .. '##' .. id)
        imgui.PopStyleColor(on and 3 or 2)
        return hit
    end
    local CAT_W = { 180, 0 }
    -- the window no narrower than the categories, a name's column and a short box: the rest wraps
    function M.MinWidth() return CAT_W[1] + LABEL_W + 230 end
    -- Every mode list in one place, by what each does: the job file's own lists (written by Save), the built-in
    -- cycles (each value wears a set of its own: fill it, there is nothing to add), and the bar pills left off.
    local BUILT_IN = {
        { '/idleset', { 'Default', 'Refresh', 'Regen', 'Regain', 'Reraise' },
            'Idle_<value> over Idle (Idle_Refresh...)' },
        { '/wsset', { 'Default', 'Low', 'High', 'PDL', 'Acc', 'SubtleBlow' },
            "the WS set's _LowBuff, _HighBuff, _PDL, _Acc or _SubtleBlow" } }
    local TANK = { '/tankset', { 'None', 'Main', 'MEVA' }, 'Tank_Main or Tank_MEVA' }
    local STAFF = { '/weapon', { 'Club', 'Staff' }, "the job file's rules go by it (Staff: Idle_Staff)" }
    local BUILT_IN_JOB = { PLD = { TANK }, RUN = { TANK }, BLM = { STAFF }, SCH = { STAFF },
        PUP = { { '/pupmode', { 'Tank', 'Melee', 'Ranger', 'Mage' }, 'Pet_<value> and Idle_Pet_<value>' } } }
    local function section(title, hint)
        imgui.Spacing()
        imgui.TextColored(palette.blue, title)
        if hint ~= nil then
            fit_line(W.Width(hint) + 8, true)
            if imgui.PushTextWrapPos ~= nil then imgui.PushTextWrapPos(0) end
            imgui.TextColored(palette.dim, hint)
            if imgui.PopTextWrapPos ~= nil then imgui.PopTextWrapPos() end
        end
        imgui.Separator()
    end
    local function chips(list) -- read-only names, wrapping under the value column
        if #list == 0 then imgui.TextColored(palette.dim, '(none yet)') end
        for i, m in ipairs(list) do
            if i > 1 then fit_line(pill_w(m)) end
            W.Pill(tostring(m), palette.text, palette.chipBg)
        end
    end
    local function job_pill(v, how)
        local text = (how == 'staged') and 'unsaved' or ((v ~= nil) and where_label('job') or 'default')
        fit_line(pill_w(text))
        W.Pill(text, tag_colors((how == 'staged') and 'staged' or ((v ~= nil) and 'job' or 'default')))
    end
    local function editable_how(how) return (how ~= 'code') and not string.match(how or '', '^set in') end
    -- the Modes tab's /wm shortcuts as typed: the new one, and each one's rename box
    local shortcutBox = { name = { '' }, mode = nil, rename = {} }
    -- Home: what this window is, this file's tools (the Editor menu's, asked of the editor: gcedit toolsAsk), the
    -- editor's spacing, and where each kind of setting is
    local CAT_ABOUT = { Common = 'auto idle sets, TP that keeps weapons, Moonshade, chat lines, lockstyle',
        ['Idle & defense'] = 'Regen / Refresh / DT gear thresholds, idle weapons, roll 11 set, Hoxne',
        Weapons = 'when weapons swap: TP guard, Aftermath, always / never swap',
        Casting = 'SIR / TH skips, element gear (obi, Orpheus, Zodiac Ring), magic bursts, received sets',
        ['Weapon skills'] = 'WS range check, Moonshade',
        ['Items & Packer'] = 'Packer, enchanted items, warp rings, capacity capes',
        Keys = 'keybinds', ['Bar & HUD'] = 'the bar, hidden pills, HUD owners, theme',
        Editor = "this editor's spacing, backups kept, hidden suggestions",
        Modes = 'every mode list for this job: /wm and its shortcuts, picks, /mset, the built-in ones' }
    local HOME_TOOLS = {
        { 'Unused gear', 'cleanup', 'The gear in your Inventory and Wardrobes that none of your job files, char.lua '
            .. 'or GoomSwap names. Read only.' },
        { 'Rescan bags', 'rescan', 'Read your bags again (after moving gear). Keeps your unsaved changes.' },
        { 'Backups', 'backups', 'Every Save keeps a dated copy of the file: see what each changed, and put one back.' },
        { 'Reload file', 'reload', 'Read the file and your bags again.' } }
    local function home_tab(jobCat)
        local ui = editorState.ui
        imgui.TextColored(palette.blue, job_name())
        imgui.SameLine()
        imgui.TextColored(palette.dim, '(the file open in the editor)')
        for i, t in ipairs(HOME_TOOLS) do
            if i > 1 then fit_line(pill_w(t[1]) + 8, true) end
            if W.Button(t[1] .. '##home_' .. t[2], 'ghost') then ui.toolsAsk, ui.focusEditor = t[2], true end
            if imgui.IsItemHovered() then set_tip(t[3]) end
        end
        imgui.Spacing()
        row('EditorSpacing', 'own')
        row('EditorKeepSize', 'own')
        imgui.TextColored(palette.dim, "The editor's theme and Diagnostics: its Editor menu (top bar).")
        imgui.Separator()
        imgui.TextColored(palette.blue, 'Where things are')
        local list = {}
        for _, c in ipairs(CATEGORIES) do list[#list + 1] = { c[1], CAT_ABOUT[c[1]] } end
        list[#list + 1] = { 'Modes', CAT_ABOUT.Modes }
        list[#list + 1] = { jobCat, 'what only ' .. job_name() .. ' has (its picks, Packer, lists...)' }
        list[#list + 1] = { 'All (advanced)', 'every setting, data most never change included' }
        for _, c in ipairs(list) do
            if imgui.Selectable(c[1] .. '##home_go_' .. c[1], false) then
                ui.settingsCat = (c[1] == jobCat) and 'job options' or c[1]
            end
            if c[2] ~= nil then
                imgui.SameLine(LABEL_W - 60)
                imgui.TextColored(palette.dim, c[2])
            end
        end
        if version ~= nil then
            imgui.Spacing()
            imgui.TextColored(palette.dim, 'GoomSwap ' .. version)
        end
    end
    local function modes_tab()
        imgui.TextColored(palette.blue, job_abbr() .. ' modes')
        imgui.SameLine()
        imgui.TextColored(palette.dim, '(in ' .. job_name() .. ', written by Save)')
        if imgui.PushTextWrapPos ~= nil then imgui.PushTextWrapPos(0) end
        imgui.TextColored(palette.dim, 'On the bar: right-click your weapon pill for every /wm mode and /mw /subw /rw '
            .. '/ammoset pick, any other pill for its values.')
        if imgui.PopTextWrapPos ~= nil then imgui.PopTextWrapPos() end
        -- /wm: one mode per Weapon_ set, so the list is the sets'; what it starts on and its roles pick from it
        section('Weapons', '/wm: one mode per Weapon_ set')
        local wm = files.Job('WeaponModes') or { 'None' }
        name_cell('/wm modes')
        if imgui.IsItemHovered() then
            set_tip(tostring((job_entry('WeaponModes') or {})[2]) .. '\n\nKey: WeaponModes')
        end
        imgui.SameLine(LABEL_W)
        chips(wm)
        imgui.SetCursorPosX(LABEL_W)
        if imgui.PushTextWrapPos ~= nil then imgui.PushTextWrapPos(0) end
        imgui.TextColored(palette.dim, 'Add: + /wm mode (WEAPONS heading). Take out: delete its Weapon_ set. Order: '
            .. 'right-click a Weapon_ set.')
        if imgui.PopTextWrapPos ~= nil then imgui.PopTextWrapPos() end
        local dw, dhow = files.Job('DefaultWeapons')
        if (type(dw) == 'table') or not editable_how(dhow) then
            job_row(job_entry('DefaultWeapons')) -- slots ({ Weapons = , Range = }): its Lua box
        else
            name_cell(nice('DefaultWeapons'))
            if imgui.IsItemHovered() then set_tip(job_entry('DefaultWeapons')[2] .. '\n\nKey: DefaultWeapons') end
            imgui.SameLine(LABEL_W)
            local nv = W.Pick('mode_default', (dw == nil) and 'None' or tostring(dw), wm, 200)
            if nv ~= nil then files.StageJob('DefaultWeapons', nv) end
            job_pill(dw, dhow)
        end
        local roles, rhow = files.Job('WeaponRoles')
        if ((roles ~= nil) and (type(roles) ~= 'table')) or not editable_how(rhow) then
            job_row(job_entry('WeaponRoles'))
        else
            local opts = { { false, '(none)' } }
            for _, m in ipairs(wm) do if m ~= 'None' then opts[#opts + 1] = m end end
            imgui.SetCursorPosX(LABEL_W)
            if imgui.PushTextWrapPos ~= nil then imgui.PushTextWrapPos(0) end
            imgui.TextColored(palette.dim, 'Shortcuts: /wm <word> switches to the mode picked beside it (/wm aoe, '
                .. '/wm melee...). Use them in macros: they keep working when you rename or add modes.')
            if imgui.PopTextWrapPos ~= nil then imgui.PopTextWrapPos() end
            local function stage(t)
                files.StageJob('WeaponRoles', (next(t) ~= nil) and t or files.REMOVE)
            end
            local function copy()
                local t = {}
                for k, x in pairs((type(roles) == 'table') and roles or {}) do t[k] = x end
                return t
            end
            local names = {}
            for k in pairs((type(roles) == 'table') and roles or {}) do names[#names + 1] = k end
            table.sort(names)
            if #names == 0 then
                imgui.SetCursorPosX(LABEL_W)
                imgui.TextColored(palette.dim, '(none yet)')
            end
            for i, r in ipairs(names) do
                -- its word, renamed in place (Set), then its mode, then x
                local b = shortcutBox.rename[r]
                if (b == nil) then
                    b = { r }
                    shortcutBox.rename[r] = b
                end
                imgui.TextUnformatted('/wm')
                imgui.SameLine()
                imgui.PushItemWidth(LABEL_W - 60)
                imgui.InputText('##role_name_' .. r, b, 24)
                imgui.PopItemWidth()
                if imgui.IsItemHovered() then
                    set_tip('Typing /wm ' .. r .. ' (or a macro with it) switches /wm to the mode '
                        .. 'picked here. Type another word and Set to rename it.\n\nKey: WeaponRoles')
                end
                local typed = string.lower(W.Trim(b[1]))
                local renaming = (typed ~= r) and string.match(typed, '^%a%w*$') and (roles[typed] == nil)
                imgui.SameLine(LABEL_W)
                local nv = W.Pick('mode_role_' .. r, tostring(roles[r]), opts, 200)
                if nv ~= nil then
                    local t = copy()
                    t[r] = nv or nil
                    stage(t)
                end
                imgui.SameLine()
                if W.Button('x##role_x_' .. r, 'danger') then
                    local t = copy()
                    t[r] = nil
                    stage(t)
                end
                if imgui.IsItemHovered() then set_tip('Click to remove /wm ' .. r .. '.') end
                if renaming then
                    imgui.SameLine()
                    if W.Button('Set##role_set_' .. r, 'accent') then
                        local t = copy()
                        t[typed], t[r] = t[r], nil
                        shortcutBox.rename[r], shortcutBox.rename[typed] = nil, nil
                        stage(t)
                    end
                end
                if i == 1 then job_pill(roles, rhow) end
            end
            -- a new one: a plain word, not a mode's name (it would hide the mode) nor default / none / force
            local nb = shortcutBox
            imgui.SetCursorPosX(LABEL_W)
            imgui.TextColored(palette.dim, '/wm')
            imgui.SameLine()
            imgui.PushItemWidth(110)
            imgui.InputTextWithHint('##role_new', 'e.g. aoe', nb.name, 24)
            imgui.PopItemWidth()
            imgui.SameLine()
            local pick = W.Pick('mode_role_new', nb.mode or '(pick a mode)', opts, 160)
            if pick ~= nil then nb.mode = pick or nil end
            imgui.SameLine()
            local word = string.lower(W.Trim(nb.name[1]))
            local why = nil
            if word ~= '' then
                local taken = (word == 'default') or (word == 'none') or (word == 'force')
                local dup = (type(roles) == 'table') and (roles[word] ~= nil)
                if not string.match(word, '^%a%w*$') then why = 'one word, letters and digits'
                elseif taken then why = '/wm ' .. word .. ' is taken'
                elseif dup then why = 'already a shortcut'
                else
                    for _, m in ipairs(wm) do
                        if string.lower(m) == word then why = "a mode's name: it would hide that mode" end
                    end
                end
            end
            if W.Button('+ Add##role_add', 'accent') and (word ~= '') and (why == nil) and (nb.mode ~= nil) then
                stage(word, nb.mode)
                nb.name[1], nb.mode = '', nil
            end
            if imgui.IsItemHovered() then
                set_tip('Add your own shortcut: /wm <word> switches to the mode you pick.')
            end
            if why ~= nil then
                imgui.SetCursorPosX(LABEL_W)
                imgui.TextColored(palette.warn, why)
            end
        end
        section('Slot picks', '/mw /subw /rw /ammoset: one item each, every item in a Weapon_ set is one already')
        for _, name in ipairs({ 'MainModes', 'SubModes', 'RangeModes', 'AmmoModes' }) do
            local e = job_entry(name)
            if (e ~= nil) and job_wanted(name) then
                job_row(e)
                imgui.Spacing()
            end
        end
        section('Your modes', '/mset /nukeset: add a name, then fill its sets (Tp_<mode>, <WS>_<mode>...)')
        for _, name in ipairs({ 'MeleeModes', 'NukeModes' }) do
            local e = job_entry(name)
            if (e ~= nil) and job_wanted(name) then
                job_row(e)
                imgui.Spacing()
            end
        end
        section('Built in', 'nothing to add: each value wears a set of its own, so fill that set')
        local fixed = {}
        for _, f in ipairs(BUILT_IN) do fixed[#fixed + 1] = f end
        for _, f in ipairs(BUILT_IN_JOB[job_abbr()] or {}) do fixed[#fixed + 1] = f end
        for _, f in ipairs(fixed) do
            name_cell(f[1])
            if imgui.IsItemHovered() then
                set_tip(f[1] .. ': GoomSwap\'s own values, on every job file. Each wears ' .. f[3] .. '.')
            end
            imgui.SameLine(LABEL_W)
            chips(f[2])
            imgui.SetCursorPosX(LABEL_W)
            if imgui.PushTextWrapPos ~= nil then imgui.PushTextWrapPos(0) end
            imgui.TextColored(palette.dim, 'wears ' .. f[3])
            if imgui.PopTextWrapPos ~= nil then imgui.PopTextWrapPos() end
        end
        section('Bar', 'pills left off it; their commands still work')
        row('BarHide', editorState.ui.settingsTarget)
    end

    function M.Body()
        local ui = editorState.ui
        ui.settingsEdit, ui.settingsFind = ui.settingsEdit or {}, ui.settingsFind or { '' }
        ui.settingsAll = ui.settingsAll or { false }
        ui.settingsTarget = ui.settingsTarget or 'own'
        ui.settingsCat = ui.settingsCat or 'Home'
        -- what this window is: GoomSwap's own behaviour, as an include file's settings are; not the editor's look
        imgui.TextColored(palette.text, 'GoomSwap in game, for every job file that loads it')
        if imgui.IsItemHovered() then
            set_tip('What an include file\'s settings are in GearSwap or LuAshitacast. The editor\'s own spacing and '
                .. 'theme: Editor, in its top bar.')
        end
        -- Applies to: one switch, the names in it
        imgui.TextColored(palette.dim, 'Applies to')
        local targets = {
            { 'own', char_name() .. ' - all jobs', 'Only ' .. char_name() .. ', on every job (saved at once in '
                .. 'char.lua): ' .. tostring(files.Path('own')) },
            { 'job', char_name() .. ' - ' .. job_abbr(), 'Only ' .. char_name() .. ' on ' .. job_abbr() .. ': in '
                .. job_name() .. ', written by the editor\'s Save (like set edits).' },
            { 'shared', 'Everyone', 'Every character on this PC, unless its char.lua or job file sets its own (saved '
                .. 'at once in goomswap-shared.lua): ' .. tostring(files.Path('shared')) },
        }
        for i, t in ipairs(targets) do
            if i == 1 then imgui.SameLine(0, 10) else fit_line(pill_w(t[2]) + 4, true) end
            if segment(t[2], ui.settingsTarget == t[1], 'set_target_' .. t[1]) then ui.settingsTarget = t[1] end
            if imgui.IsItemHovered() then set_tip(t[3]) end
        end
        fit_line(236, true)
        imgui.PushItemWidth(220)
        imgui.InputTextWithHint('##set_find', 'find a setting', ui.settingsFind, 48)
        imgui.PopItemWidth()
        -- the colours of where a value comes from, once here instead of words on every row
        local legend = 'Where a value comes from: default (GoomSwap\'s), everyone (the shared file), all jobs ('
            .. char_name() .. "'s char.lua), " .. job_abbr() .. ' only (' .. job_name() .. '), unsaved (waits for '
            .. 'Save). ' .. job_name() .. ' wins over char.lua, char.lua over everyone. Hover a setting\'s name for '
            .. 'what it does and its key.'
        fit_line(W.Width('From') + 8, true)
        imgui.TextColored(palette.dim, 'From')
        if imgui.IsItemHovered() then set_tip(legend) end
        for _, f in ipairs({ 'default', 'shared', 'own', 'job', 'staged' }) do
            fit_line(pill_w((f == 'staged') and 'unsaved' or where_label(f)), true)
            W.Pill((f == 'staged') and 'unsaved' or where_label(f), tag_colors(f))
            if imgui.IsItemHovered() then set_tip(legend) end
        end
        imgui.Separator()
        local find = string.lower(ui.settingsFind[1] or '')
        local target = ui.settingsTarget
        -- categories on the left (hidden while searching: a search looks through all of them)
        local jobCat = 'This job (' .. job_abbr() .. ')'
        if find == '' then
            imgui.BeginChild('##set_cats', CAT_W, 0)
            local cats = { 'Home' }
            for _, c in ipairs(CATEGORIES) do cats[#cats + 1] = c[1] end
            cats[#cats + 1] = 'Modes'
            cats[#cats + 1] = jobCat
            cats[#cats + 1] = 'All (advanced)'
            for _, c in ipairs(cats) do
                local on = (ui.settingsCat == c) or ((c == jobCat) and (ui.settingsCat == 'job options'))
                if on then imgui.PushStyleColor(ImGuiCol_Text, palette.blue) end
                if imgui.Selectable(c .. '##set_cat_' .. c, on) then ui.settingsCat = (c == jobCat) and 'job options' or c end
                if on then imgui.PopStyleColor() end
            end
            imgui.EndChild()
            imgui.SameLine()
        end
        imgui.BeginChild('##set_rows', { 0, 0 }, 0)
        local known = {}
        for _, k in ipairs(keys()) do known[k] = true end
        if find ~= '' then -- every setting whose name or key has the words, then the job file's options
            local function hit(k) return (string.find(string.lower(k), find, 1, true) ~= nil)
                or (string.find(string.lower(nice(k)), find, 1, true) ~= nil) end
            for _, key in ipairs(keys()) do
                if hit(key) then line(key, target) end
            end
            if (string.find('packer', find, 1, true) ~= nil) then line('Packer', target) end
            local any = false
            for _, entry in ipairs(JOB) do
                if hit(entry[1]) and (entry[1] ~= 'profile.Packer') then
                    if not any then imgui.Separator(); imgui.TextColored(palette.blue, job_name() .. "'s own options"); any = true end
                    job_row(entry)
                end
            end
        elseif ui.settingsCat == 'Home' then
            home_tab(jobCat)
        elseif ui.settingsCat == 'Modes' then
            modes_tab()
        elseif ui.settingsCat == 'job options' then
            imgui.TextColored(palette.blue, 'This job (' .. job_abbr() .. ')')
            imgui.SameLine()
            imgui.TextColored(palette.dim, '(in ' .. job_name() .. ', for ' .. char_name() .. ' on ' .. job_abbr()
                .. ': written by Save)')
            imgui.Separator()
            job_options()
        elseif ui.settingsCat == 'All (advanced)' then
            for _, key in ipairs(keys()) do line(key, target) end
            if target ~= 'job' then line('Packer', target) end -- the job's own Packer is among its options below
            imgui.Separator()
            imgui.TextColored(palette.blue, job_name() .. "'s own options")
            job_options()
        else
            for _, c in ipairs(CATEGORIES) do
                if c[1] == ui.settingsCat then
                    for _, key in ipairs(c[2]) do
                        if (key == 'Packer') or known[key] then line(key, target) end
                    end
                    if c[1] == 'Items & Packer' then -- settings no longer read, when a file still sets one
                        for _, key in ipairs({ 'PackerItems', 'PackerPutAway' }) do
                            if known[key] then line(key, target) end
                        end
                    end
                end
            end
        end
        imgui.EndChild()
    end
    return M
end
