-- /gcedit: new sets, copying, Use worn and saving.
return function(
    ARMOR, BASE, ENGINE, SCREEN, augments_of, ctx, current, edit, editorPreferences, editorState, feedback,
    fileWriter, gcedit, group_of, imgui, palette, pending_weapon_mode, read_file, setFile,
    set_tip, xy
)
-- What the New set list offers: { name, why } for names the file lacks: the job's example file's sets, the engine's,
-- then the job abilities, weapon skills and spells you know (found as tHotBar does: HasAbility(Id), HasSpell(Index)).
-- standard: no job abilities, weapon skills or spells; noSpells: the abilities and weapon skills you know, no spells
local function suggestions(standard, noSpells)
    local list, seen = {}, {}
    local function add(name, why)
        local l = string.lower(name)
        if (editorState.document.model.byLower[l] == nil) and not seen[l] then
            seen[l] = true
            list[#list + 1] = { name = name, lname = l, why = why }
        end
    end
    local res = AshitaCore:GetResourceManager()
    local job = res:GetString('jobs.names_abbr', editorState.profile.job)
    if type(job) == 'string' then
        local ex = read_file(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\examples\\' .. job .. '.lua')
        local m = (ex ~= nil) and setFile.Parse(ex) or nil
        if m ~= nil then
            for _, set in ipairs(m.list) do
                add(set.name, 'in the ' .. job .. ' example')
            end
        end
    end
    for _, n in ipairs(ENGINE) do
        add(n, 'engine set')
    end
    -- weapon-mode sets: Tp_<mode> / Ws_<mode> go on over Tp_Default / Ws_Default while /wm <mode> is on
    local wmodes = (not editorState.document.inactive) and ctx.gearEngine.WeaponModes or nil
    if type(wmodes) ~= 'table' then
        wmodes = {}
        for _, set in ipairs(editorState.document.model.list) do
            local m = string.match(set.name, '^[Ww][Ee][Aa][Pp][Oo][Nn]_([^_]+)$')
            if m ~= nil then wmodes[#wmodes + 1] = m end
        end
    end
    for _, m in ipairs(wmodes) do
        if (type(m) == 'string') and (m ~= 'None') then
            add('Tp_' .. m, 'TP while /wm ' .. m)
            add('Ws_' .. m, 'weapon skills while /wm ' .. m)
        end
    end
    local received = {}
    for _, n in pairs((ctx.gearEngine.settings or {}).ReceivedSets or {}) do
        if type(n) == 'string' then received[#received + 1] = n end
    end
    table.sort(received)
    for _, n in ipairs(received) do add(n, 'a spell coming at you') end
    if standard then return list end
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    local acts = {}
    for i = 1, 0x600 do
        local r = res:GetAbilityById(i)
        if (r ~= nil) and (r.Name ~= nil) and (type(r.Name[1]) == 'string') and (r.Name[1] ~= '')
            and not editorState.document.inactive and player:HasAbility(r.Id) then
            acts[#acts + 1] = { r.Name[1], (i < 0x200) and 'weapon skill' or 'job ability' }
        end
    end
    local main, sub, subLv = editorState.profile.job, player:GetSubJob(), player:GetSubJobLevel()
    for i = 1, noSpells and 0 or 0x400 do
        local r = res:GetSpellById(i)
        if (r ~= nil) and (r.Name ~= nil) and (type(r.Name[1]) == 'string') and (r.Name[1] ~= '')
            and player:HasSpell(r.Index) then
            local lr = r.LevelRequired
            local ok = (type(lr) == 'table')
                and (lr[2] ~= 1) -- trusts read WAR 1 (as tHotBar)
                and (
                    ((lr[main + 1] or -1) ~= -1)
                    or (not editorState.document.inactive and ((lr[sub + 1] or -1) ~= -1)
                        and (lr[sub + 1] <= (subLv or 0)))
                )
            if ok then acts[#acts + 1] = { r.Name[1], 'spell' } end
        end
    end
    table.sort(acts, function(x, y) return x[1] < y[1] end)
    for _, a in ipairs(acts) do
        add(a[1], a[2])
    end
    return list
end

-- parent: a set that holds sets (Buffs); the new one is its key `key`, named Buffs['key'].
local function make_set(name, copyFrom, stay, parent, key)
    if parent ~= nil then name = setFile.ChildName(parent.name, key) end
    local set = {
        name = name,
        lname = string.lower(name),
        new = true,
        slots = {},
        count = 0,
        bracket = (setFile.FormatKey(name) ~= name),
        parentName = parent and parent.name,
        key = key,
    }
    set.group, set.builtin = group_of(name, parent and parent.name)
    editorState.document.model.byLower[set.lname] = set
    editorState.document.revision = editorState.document.revision + 1
    if (copyFrom ~= nil) and not copyFrom.new then set.after = copyFrom.name end
    local list, at = editorState.document.model.list, #editorState.document.model.list + 1
    if parent ~= nil then -- in the list right after the parent's other sets
        for i, s in ipairs(list) do
            if (s == parent) or (s.parentName == parent.name) then at = i + 1 end
        end
    end
    table.insert(list, at, set)
    editorState.document.model.byName[name] = set
    editorState.document.newSets[#editorState.document.newSets + 1] = set
    if copyFrom ~= nil then
        local ed = {}
        for _, slot in ipairs(SCREEN) do
            local v = current(copyFrom, slot)
            if v ~= nil then
                ed[slot] = {
                    kind = v.kind,
                    name = v.name,
                    path = v.path,
                    rank = v.rank,
                    augs = v.augs,
                    raw = v.raw,
                    text = v.text or v.raw,
                }
            end
        end
        if next(ed) ~= nil then editorState.document.edits[name] = ed end
    elseif set.lname == 'xiroll' then -- always the same piece (gcinclude's XIRollSet)
        editorState.document.edits[name] =
            { Ring2 = { kind = 'item', name = "Roller's Ring", text = setFile.FormatItem("Roller's Ring") } }
    end
    if not stay then editorPreferences.Select(editorState, name, nil) end
    editorState.ui.sugg = nil
    local mode = pending_weapon_mode(set)
    feedback(mode and (name .. ' created; /wm ' .. mode .. ' will be added on Save.')
        or (name .. ' created (unsaved).'))
end

-- Stage a full copy, clearing empty source slots and preserving code-valued targets.
local function copy_from(set, sourceSet)
    editorState.document.revision = editorState.document.revision + 1
    local pending = editorState.document.edits[set.name] or {}
    for _, slot in ipairs(SCREEN) do
        local saved = set.slots[slot]
        if saved == nil or saved.value.kind ~= 'code' then
            local source = current(sourceSet, slot)
            if source == nil then
                pending[slot] = saved and { remove = true } or nil
            elseif saved and saved.value.raw == (source.text or source.raw) then
                pending[slot] = nil
            else
                pending[slot] = {
                    kind = source.kind,
                    name = source.name,
                    path = source.path,
                    rank = source.rank,
                    augs = source.augs,
                    raw = source.raw,
                    text = source.text or source.raw,
                }
            end
        end
    end
    editorState.document.edits[set.name] = next(pending) and pending or nil
    feedback('Copied ' .. sourceSet.name .. ' into ' .. set.name .. ' (unsaved).')
end
local function draw_copy_popup(set)
    if not imgui.BeginPopup('##gcedit_copy') then return end
    local cmp = (editorState.ui.pickMode == 'compare')
    local base = editorState.ui.pickMode == 'statsBase'
    imgui.TextUnformatted(base and 'Starting base for both previews:' or (cmp and 'Compare with:'
        or 'Copy every slot from:'))
    if base and imgui.Selectable('Auto (built-in layers)##stats_base_auto') then
        editorState.ui.statBase = nil
        imgui.CloseCurrentPopup()
    end
    imgui.PushItemWidth(260)
    imgui.InputTextWithHint('##gcedit_copyfind', 'Dt, Idle, Savage...', editorState.ui.copyFind, 48)
    imgui.PopItemWidth()
    local find = string.lower(editorState.ui.copyFind[1] or '')
    imgui.BeginChild('##gcedit_copylist', { 260, 300 }, 0)
    for _, src in ipairs(editorState.document.model.list) do
        if (base or src ~= set) and (src.code == nil) and not src.extra and not editorState.document.deleted[src.name]
            and ((find == '') or string.find(src.lname, find, 1, true)) then
            if imgui.Selectable(src.name .. '##gcc_' .. src.name, false) then
                if base then
                    editorState.ui.statBase = src.name
                elseif cmp then
                    editorState.ui.cmp = { set = set.name, with = src.name }
                    editorState.selection.tab = 'compare'
                else
                    copy_from(set, src)
                end
                imgui.CloseCurrentPopup()
            end
        end
    end
    imgui.EndChild()
    imgui.TextColored(
        palette.dim,
        base and 'Preview only. Custom job logic, active buffs and currently worn gear are not executed.'
            or cmp and 'Opens a read-only comparison. Copying is a separate action.'
            or 'Unsaved until Save + reload. Revert set undoes it.'
    )
    imgui.EndPopup()
end

local function drop_new(set)
    local mode = pending_weapon_mode(set)
    for i, ns in ipairs(editorState.document.newSets) do
        if ns == set then
            table.remove(editorState.document.newSets, i)
            break
        end
    end
    for i, ns in ipairs(editorState.document.model.list) do
        if ns == set then
            table.remove(editorState.document.model.list, i)
            break
        end
    end
    editorState.document.model.byName[set.name], editorState.document.edits[set.name] = nil, nil
    if editorState.document.model.byLower[set.lname] == set then editorState.document.model.byLower[set.lname] = nil end
    editorState.document.revision = editorState.document.revision + 1
    local nextSet = editorState.document.model.byName.Idle or editorState.document.model.list[1]
    editorPreferences.Select(editorState, nextSet and nextSet.name, nil, 'action')
    feedback('Discarded ' .. set.name .. (mode and '; its pending weapon registration was removed.' or '.'))
end

-- A base set's armor slots left empty (nil for a set that is not a base set).
local function empty_armor(set)
    if (BASE[set.name] == nil) or (set.code ~= nil) or set.extra then return nil end
    local out = {}
    for _, slot in ipairs(ARMOR) do
        if current(set, slot) == nil then out[#out + 1] = slot end
    end
    return out
end

---------------------------------------------------------------------------------------------------------------------
-- What could go over a set: the set names GoomSwap looks for, under the circumstances ticked. The rules, from
-- gcinclude: EquipMode(prefix) = <prefix>_Default then <prefix>_<mset>; ByName(n) = n then n_<mset>; WS wrapper
-- (WrapHoldHandlers) = job file, Ws_Proc/Proc (/proc), then WearChildren(worn, HighBuff) on /wsset high and
-- WearChildren(worn, Dt) on /dt (each worn n: n_<key>, and <prefix>_<key> for <prefix>_Default), then CheckHoxneWs
-- (Hoxne_Ws, Hoxne_<ws> and each one's _<mset>, their _Dt on /dt), Buffs_Ws, then CheckHoxneWsCombos (their buff
-- combos <base>_<buffs>, over the plain buff sets). Idle/engaged: CheckHoxneSets (Hoxne_Dt on /dt, else Hoxne_Tp
-- engaged / Hoxne_Idle idle, by ByName), ..., Buffs, then CheckHoxneCombos (that base's buff combos). Midcast:
-- WearChildren(worn, Self / Others / Burst). Job files may look for more (THF _SA,
-- MNK Victory Smite_Impetus): those show under Worn in when an action looks for them.
---------------------------------------------------------------------------------------------------------------------

local function use_worn(set) -- a Weapon_ set takes only Main, Sub, Range and Ammo: the rest of it is never worn
    local eq = gData.GetEquipment()
    local weaponsOnly = (ctx.weapon_set_info ~= nil) and (ctx.weapon_set_info(set) ~= nil)
    for _, slot in ipairs(SCREEN) do
        local cur = set.slots[slot]
        if weaponsOnly and not ctx.WEAPON_SLOT[slot] then
            -- left as it is
        elseif (cur == nil) or (cur.value.kind == 'item') then
            local w = eq[slot]
            if (w ~= nil) and (w.Name ~= nil) then
                local a = (w.Item ~= nil) and augments_of(w.Item) or { augs = {} }
                edit(set, slot, { name = w.Name, augs = a.augs, path = a.path })
            else
                edit(set, slot, nil)
            end
        end
    end
end

local function save()
    local disk = read_file(editorState.document.sourcePath or editorState.document.path)
    if disk ~= editorState.document.model.text then
        editorState.ui.notice, editorState.ui.noticeBad =
            string.match(editorState.document.sourcePath or editorState.document.path, '[^\\/]+$')
                .. ' changed on disk since the editor read it: Reload (your changes here are dropped).', true
        return
    end
    local splices = {}
    local canDelete, missingSet =
        setFile.AddDeletions(disk, editorState.document.model, editorState.document.deleted, splices)
    if not canDelete then
        editorState.ui.notice, editorState.ui.noticeBad =
            'Cannot delete ' .. missingSet .. ': source entry missing.', true
        return
    end
    local renames = {}
    for old, new in pairs(editorState.document.renames or {}) do
        if not editorState.document.deleted[old] then renames[old] = new end
    end
    local canRename, badRename = setFile.AddRenames(disk, editorState.document.model, renames, splices)
    if not canRename then
        editorState.ui.notice, editorState.ui.noticeBad = 'Cannot rename ' .. badRename .. ': written as code.', true
        return
    end
    if (#editorState.document.newSets > 0) and not setFile.AddNewSets( disk, editorState.document.model,
        editorState.document.newSets, editorState.document.edits, splices ) then
        editorState.ui.notice, editorState.ui.noticeBad = 'Not saved: no place for a new set in the sets table.', true
        return
    end
    for name, edits in pairs(editorState.document.edits) do
        local set = editorState.document.model.byName[name]
        -- deleted: its edits go with it; new: AddNewSets wrote it whole
        local skip = (editorState.document.deleted or {})[name] or ((set ~= nil) and set.new)
        if not skip and ((set == nil) or not setFile.AddSlotEdits(disk, set, edits, splices)) then
            editorState.ui.notice, editorState.ui.noticeBad = name .. ' is written as code: not saved.', true
            return
        end
    end
    if #editorState.document.newModes > 0 then
        local base = (not editorState.document.inactive and (gcdisplay ~= nil) and gcdisplay.GetCycleValues('MeleeSet'))
            or { 'Default', 'SubtleBlow', 'Acc' }
        if not setFile.AddModes(disk, base, editorState.document.newModes, splices) then
            editorState.ui.notice, editorState.ui.noticeBad =
                'Not saved: no gcinclude.Initialize() line in the file to put the new mode before.', true
            return
        end
    end
    if not setFile.AddWeaponModes(disk, editorState.document.newSets, splices, editorState.document.newModes) then
        editorState.ui.notice, editorState.ui.noticeBad =
            'Not saved: no gcinclude.Initialize() line to register new weapon modes.', true
        return
    end
    -- Rules page: Convert's / Adopt's splices, read against this same text (the handlers, apart from the sets)
    local conv = editorState.document.convert
    if conv ~= nil then
        if conv.text ~= disk then
            editorState.ui.notice, editorState.ui.noticeBad = 'Not saved: the file changed since Convert read it.', true
            return
        end
        for _, sp in ipairs(conv.splices) do splices[#splices + 1] = { sp[1], sp[2], sp[3] } end
    end
    local text = setFile.Apply(disk, splices)
    -- Settings, This job: each staged gcinclude.<name> line, on the text with the edits above
    for name, e in pairs((text ~= nil) and editorState.document.jobSettings or {}) do
        local err
        text, err = setFile.SetJobSetting(text, name, (not e.remove) and function(ind)
            return ctx.settingsFiles.JobText(e, ind)
        end or nil)
        if text == nil then
            editorState.ui.notice, editorState.ui.noticeBad = 'Not saved: ' .. tostring(err) .. '.', true
            return
        end
    end
    -- a deleted Weapon_ set's mode leaves the /wm list (read again here: the splices above may have rewritten it)
    local gone = ctx.wm_removal().modes
    if (text ~= nil) and (#gone > 0) then text = setFile.RemoveWeaponModes(text, gone) end
    if (text ~= nil) and (editorState.document.wmOrder ~= nil) then -- after the rest: new and renamed modes are in it
        local order = {}
        for i, m in ipairs(editorState.document.wmOrder) do
            local renamed = renames['Weapon_' .. m]
            order[i] = (renamed ~= nil) and (string.match(renamed, '^Weapon_(.+)$') or m) or m
        end
        text = setFile.OrderWeaponModes(text, order)
        if text == nil then
            editorState.ui.notice, editorState.ui.noticeBad =
                'Not saved: /wm order needs gcinclude.WeaponModes = {...} on one line.', true
            return
        end
    end
    local check = (text ~= nil) and setFile.Parse(text) or nil
    -- compiled, not run
    local compiles = (text ~= nil) and ((loadstring or load)(text, '=' .. editorState.document.file) ~= nil)
    if (check == nil) or not compiles then
        editorState.ui.notice, editorState.ui.noticeBad =
            'Not saved: the edit would break the file (please report this set).', true
        return
    end
    -- the file about to be replaced is kept next to it (a draft replaces the job file, when there is one)
    local old = disk
    if editorState.document.sourcePath ~= nil then old = read_file(editorState.document.path) end
    local backup = nil
    if old ~= nil then
        local err
        backup, err = fileWriter.Backups.Path(editorState.document.path, function(path)
            if ashita.fs and ashita.fs.exists then return ashita.fs.exists(path) end
            return read_file(path) ~= nil
        end)
        if not backup then editorState.ui.notice, editorState.ui.noticeBad = 'Not saved: ' .. err, true; return end
        local backedUp, backupErr = fileWriter.Write(backup, old)
        if not backedUp then
            editorState.ui.notice, editorState.ui.noticeBad = 'Not saved: backup failed: ' .. tostring(backupErr), true
            return
        end
    end
    local written, err = fileWriter.Write(editorState.document.path, text)
    if not written then
        local restored = old and fileWriter.Write(editorState.document.path, old)
        editorState.ui.notice, editorState.ui.noticeBad =
            'Save failed: '
                .. tostring(err)
                .. (
                    restored and '. Original restored.'
                    or (backup and ('. Recover from ' .. backup) or '. Destination may be incomplete.')
                ),
            true
        return
    end
    -- Retention runs only after the checked destination write succeeds. Never
    -- delete a host/addset backup, another job's backup, or this save's backup.
    local cleanupError
    local keep = fileWriter.Backups.Keep((ctx.gearEngine.settings or {}).EditorBackupKeep)
    if backup and keep > 0 then
        local folder = editorState.document.path:match('^(.*[\\/])') or ''
        local ok, files = pcall(function() return ashita.fs.get_directory(folder, '.*') end)
        local _, pruneErr = fileWriter.Backups.Prune(editorState.document.path, keep, ok and files or nil,
            os.remove, backup)
        cleanupError = pruneErr
        if pruneErr then ctx.gearEngine.Err('Saved, but backup cleanup failed: ' .. tostring(pruneErr)) end
    end
    if renames[editorState.selection.setName or ''] then
        editorState.selection.setName = renames[editorState.selection.setName]
    end
    if (editorState.preferences ~= nil) and (editorState.preferences.start == 'on') then -- Getting started: saved once
        editorState.preferences.start = 'saved'
    end
    if editorState.document.inactive then
        ctx.gearEngine.Say('/gcedit: saved ' .. editorState.document.file .. '; active job left loaded')
        gcedit.Reload()
        editorState.ui.notice, editorState.ui.noticeBad = cleanupError
            and ('Saved, but backup cleanup failed: ' .. tostring(cleanupError))
            or ('Saved ' .. editorState.document.file .. '. Your active job is still loaded.'), cleanupError ~= nil
        return
    end
    ctx.gearEngine.Say(
        '/gcedit: saved '
            .. editorState.document.file
            .. ((backup ~= nil) and (' (old file: ' .. string.match(backup, '[^\\/]+$') .. ')') or '') .. '; reloading'
    )
    editorState.ui.saving, editorState.ui.notice, editorState.ui.noticeBad =
        true, 'Saved: reloading the job file...', false -- a second click would find the file changed
    GcEditReopen = nil
    if editorState.ui.reopen == nil or editorState.ui.reopen[1] then
        local ok, reopenErr = fileWriter.Write(
            editorState.document.path .. '.gcedit-reopen',
            tostring(os.time())
                .. '\n' .. (editorState.selection.setName or '') .. '\n' .. (editorState.selection.slot or '')
        )
        if not ok then ctx.gearEngine.Err('Saved, but reopen request failed: ' .. tostring(reopenErr)) end
    else
        os.remove(editorState.document.path .. '.gcedit-reopen')
    end
    -- a draft for a new file: /lac load finds it
    AshitaCore:GetChatManager():QueueCommand(-1, editorState.document.reloadCommand or '/lac reload')
end

-- == Recorded layers (gcaction.Rec*, GcRecords): what real actions wore, set by set. ==

-- A record's writes as layers: { by, writes = { slot, name, blocked, won } } in order, and the final gear per slot.
-- /gcedit: recorded layers (gcaction's records) turned into readable rows.
local function ago(t)
    local d = os.time() - (t or 0)
    if d < 60 then return d .. 's ago' end
    if d < 3600 then return math.floor(d / 60) .. 'm ago' end
    return math.floor(d / 3600) .. 'h ago'
end

-- == Drawing ==

-- A red button, for what drops something (Clear slot, Revert set, Discard).
local function red_button(label, small)
    imgui.PushStyleColor(ImGuiCol_Button, palette.red)
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, palette.redHi)
    imgui.PushStyleColor(ImGuiCol_ButtonActive, palette.redHi)
    local hit
    if small then
        hit = imgui.SmallButton(label)
    else
        hit = imgui.Button(label)
    end
    imgui.PopStyleColor(3)
    return hit
end

local function tag(text, col)
    imgui.SameLine()
    imgui.TextColored(col, text)
end

-- Text on a rounded fill (a bag, the save state). Plain coloured text when this ImGui has no draw list.
local PA, PB = { 0, 0 }, { 0, 0 }
local function canDraw()
    return (imgui.GetWindowDrawList ~= nil)
        and (imgui.GetColorU32 ~= nil)
        and (imgui.GetCursorScreenPos ~= nil)
        and (imgui.CalcTextSize ~= nil) and (imgui.GetItemRectMin ~= nil) and (imgui.GetItemRectMax ~= nil)
end
local function text_w(t)
    return (imgui.CalcTextSize ~= nil) and (tonumber((xy(imgui.CalcTextSize(t)))) or 0) or (#t * 7)
end
local pill = gFunc.LoadFile('common\\gceditwidgets.lua')(imgui, palette, set_tip).Pill -- the editor's one pill

local function make_button(label) -- adds a set: blue, like the open tab
    imgui.PushStyleColor(ImGuiCol_Button, palette.selBg)
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, palette.save)
    imgui.PushStyleColor(ImGuiCol_Text, palette.blue)
    local hit = imgui.SmallButton(label)
    imgui.PopStyleColor(3)
    return hit
end
local function left_bar(col) -- a 2px bar on the left edge of the item just drawn
    if not canDraw() then return end
    local x1, y1 = xy(imgui.GetItemRectMin())
    local _, y2 = xy(imgui.GetItemRectMax())
    if (x1 == nil) or (y1 == nil) or (y2 == nil) then return end
    PA[1], PA[2], PB[1], PB[2] = x1, y1, x1 + 2, y2
    imgui.GetWindowDrawList():AddRectFilled(PA, PB, imgui.GetColorU32(col), 0)
end

-- SetTooltip does not wrap: break each line of the text at spaces, n characters wide. Line breaks stay; a
-- '- ' bullet's own lines are indented under its text. Wrapped once per text.
local wrapped = {} -- a handful of fixed texts
local function wrap(s, n)
    local key = s .. '\0' .. n
    if wrapped[key] ~= nil then return wrapped[key] end
    local out = {}
    for para in string.gmatch(s .. '\n', '(.-)\n') do
        local hang = string.match(para, '^(%- )') and '  ' or ''
        local line = ''
        for w in string.gmatch(para, '%S+') do
            if (#line > 0) and (#line + #w + 1 > n) then
                out[#out + 1] = line
                line = hang .. w
            else
                line = (#line > 0) and (line .. ' ' .. w) or w
            end
        end
        out[#out + 1] = line
    end
    wrapped[key] = table.concat(out, '\n')
    return wrapped[key]
end

local function help_icon(text) -- a dim (?); hover it for the text
    imgui.TextColored(palette.dim, '(?)')
    if imgui.IsItemHovered() then set_tip(wrap(text, 64)) end
end
local function help(text) -- the (?) after a one-line item (before a wrapped one: help_icon, then the text)
    imgui.SameLine()
    help_icon(text)
end

-- Open another set from the right panel (a have link, To fill): the set you were on goes on a back list, so
-- '< Back to <set>' over the slots returns to it. Picking in the left list clears that list.
    return { suggestions = suggestions, make_set = make_set, copy_from = copy_from, draw_copy_popup = draw_copy_popup,
        drop_new = drop_new, empty_armor = empty_armor, use_worn = use_worn, save = save, ago = ago,
        red_button = red_button, tag = tag, canDraw = canDraw, text_w = text_w, pill = pill, make_button = make_button,
        left_bar = left_bar, wrap = wrap, help_icon = help_icon, help = help }
end
