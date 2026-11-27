-- /gcedit: the settings files. This character's char.lua, and goomswap-shared.lua that every character uses under
-- its own (the engine reads the defaults, then the shared file, then char.lua; job files after). Both are
-- `return { settings = {...} }`: a change rewrites only its key, after a backup (once per editor session), and only
-- when the file still loads. Heading prefs and folded headings ride on it. No drawing.
return function(o) -- o: { engine() -> gcinclude, setFile, groups (gceditgroups), readFile(path), state() -> editorState }
    local S = {}
    local F, G = o.setFile, o.groups
    local SHARED_TEMPLATE = [[-- goomswap-shared.lua: GoomSwap settings for every character on this PC.
-- A character's char.lua wins over these, and a job file over both. /gcedit's Settings writes here.
return {
    settings = {
    },
}
]]

    local function path_of(which)
        local e = o.engine()
        local f = (which == 'own') and e.CharConfigPath or e.SharedConfigPath
        return (f ~= nil) and f() or nil
    end

    -- A file's table, read as data (no code run; T{...} allowed); nil when it has code or doesn't load.
    local function data_of(text)
        local chunk = (text ~= nil) and (loadstring or load)(text) or nil
        if chunk == nil then return nil end
        if setfenv ~= nil then setfenv(chunk, { T = function(t) return t end }) end
        local ok, t = pcall(chunk)
        return (ok and (type(t) == 'table')) and t or nil
    end

    -- 'own' (char.lua) or 'shared': read once per editor open; else what the engine loaded.
    local cache, backedUp = {}, {}
    local function layer(which)
        if cache[which] == nil then
            local e, path = o.engine(), path_of(which)
            local t = ((path ~= nil) and data_of(o.readFile(path)))
                or ((which == 'own') and e.CharConfig or e.SharedConfig) or {}
            if type(t.settings) ~= 'table' then t.settings = {} end
            cache[which] = t
        end
        return cache[which]
    end

    function S.Reset() cache = {} end -- another character may have changed the shared file
    function S.Engine() return o.engine() end -- the loaded gcinclude the editor was opened with
    function S.Defaults() return o.engine().DefaultSettings or {} end
    function S.Path(which) return path_of(which) end
    function S.Layer(which) return layer(which).settings end

    -- A setting's value now and where it comes from: 'own', 'shared' or 'default' (a default of false stays false).
    function S.Get(key)
        local v = layer('own').settings[key]
        if v ~= nil then return v, 'own' end
        v = layer('shared').settings[key]
        if v ~= nil then return v, 'shared' end
        local d = o.engine().DefaultSettings
        if type(d) == 'table' then return d[key], 'default' end
        return nil, 'default'
    end

    S.REMOVE = setmetatable({}, { __tostring = function() return '(taken out)' end }) -- a value of false is a value
    -- text written to path (old: what it held, nil when new): the first write this session backs old up first; a
    -- failed write puts old back.
    local function commit(path, old, text)
        if (old ~= nil) and (backedUp[path] == nil) then
            local backup, berr = F.Backups.Path(path, function(p) return ashita.fs.exists(p) end)
            local ok, werr = false, berr
            if backup ~= nil then ok, werr = F.Write(backup, old) end
            if not ok then return false, 'backup failed: ' .. tostring(werr) end
            backedUp[path] = backup
        end
        local ok, werr = F.Write(path, text)
        if not ok then
            if old ~= nil then F.Write(path, old) end
            return false, tostring(werr)
        end
        return true
    end
    -- Each key of changes set in which ('own' or 'shared'; S.REMOVE: taken out), in one write; then in use at once (a
    -- job file's own value comes back on its next load). A missing file is made from its template.
    function S.Write(which, changes)
        local e, path = o.engine(), path_of(which)
        if path == nil then return false, 'no character folder yet' end
        local old = o.readFile(path)
        local text = old or ((which == 'own') and e.CharConfigTemplate or SHARED_TEMPLATE)
        for k, v in pairs(changes) do
            local err
            text, err = F.SetCharSetting(text, k, function(ind)
                if v == S.REMOVE then return nil end
                return G.SerializeValue(v, F.QuoteText, F.FormatKey, ind)
            end)
            if text == nil then return false, tostring(err) end
        end
        if (loadstring or load)(text) == nil then return false, 'the file would not load after the change' end
        local values = data_of(text) -- the engine's own check, so the next load takes the whole file
        if (values ~= nil) and (e.CheckConfig ~= nil) then
            local fine, why = e.CheckConfig(values)
            if not fine then return false, tostring(why) end
        end
        local ok, werr = commit(path, old, text)
        if not ok then return false, werr end
        local L = layer(which).settings
        for k, v in pairs(changes) do
            if v == S.REMOVE then L[k] = nil else L[k] = v end
        end
        if type(e.settings) == 'table' then
            for k in pairs(changes) do
                local v, d = (S.Get(k)), S.Defaults()[k]
                -- a T{} default keeps its methods (HoldExempt:contains): as config.Apply does on load
                if (type(v) == 'table') and (type(d) == 'table') and (getmetatable(v) == nil) then
                    setmetatable(v, getmetatable(d))
                end
                e.settings[k] = v
            end
        end
        return true
    end

    -- == The return table's own keys beside settings (Packer: kept on every job, /lac gear). ==
    function S.Top(which, key) return layer(which)[key] end
    -- key set to value in which ('own' or 'shared'; S.REMOVE: taken out), written at once after a backup; the engine's
    -- Packer list (char.lua's, else the shared file's) follows.
    function S.WriteTop(which, key, value)
        local e, path = o.engine(), path_of(which)
        if path == nil then return false, 'no character folder yet' end
        local old = o.readFile(path)
        local text, err = F.SetCharTop(old or ((which == 'own') and e.CharConfigTemplate or SHARED_TEMPLATE), key,
            function(ind)
                if value == S.REMOVE then return nil end
                return G.SerializeValue(value, F.QuoteText, F.FormatKey, ind)
            end)
        if text == nil then return false, tostring(err) end
        if (loadstring or load)(text) == nil then return false, 'the file would not load after the change' end
        local ok, werr = commit(path, old, text)
        if not ok then return false, werr end
        layer(which)[key] = (value ~= S.REMOVE) and value or nil
        if key == 'Packer' then
            e.CharPacker = layer('own').Packer or layer('shared').Packer
            if e.FillPacker ~= nil then e.FillPacker(true) end
        end
        return true
    end

    -- == This job: the job file open in the editor, its own `gcinclude.settings.X` and `gcinclude.X` lines. Changes
    -- are staged on the document (document.jobSettings) and written by its Save, like set edits (gceditsets). ==
    local function value_of(text) -- Lua data, no code run (T{...} allowed): the value, and whether it read
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
    S.ValueOf, S.Same = value_of, same -- the Settings panel reads typed values with them
    local function doc()
        local st = (o.state ~= nil) and o.state() or nil
        return (st ~= nil) and st.document or nil
    end
    local fileCache = { text = nil, names = {} } -- [name] = { value, why }: the file read once per text
    local function from_file(name)
        local d = doc()
        local text = (d ~= nil) and (d.model ~= nil) and d.model.text or ''
        if fileCache.text ~= text then fileCache = { text = text, names = {} } end
        local hit = fileCache.names[name]
        if hit == nil then
            local raw, why = F.JobSetting(text, name)
            local v, ok = nil, false
            if raw ~= nil then v, ok = value_of(raw) end
            hit = { v, (raw == nil) and why or (ok and 'file' or 'code') }
            if raw ~= nil and not ok then hit[1] = nil end
            fileCache.names[name] = hit
        end
        return hit[1], hit[2]
    end
    function S.JobFile()
        local d = doc()
        return (d ~= nil) and d.file or nil
    end
    function S.JobStaged()
        local d = doc()
        if d == nil then return {} end
        d.jobSettings = d.jobSettings or {}
        return d.jobSettings
    end
    -- name ('settings.X' or 'X'): this job's value (staged, else the file's) and what it is: 'staged', 'file',
    -- 'none', 'code' or 'set in N places'; the last two are edited in the file.
    function S.Job(name)
        local st = S.JobStaged()[name]
        if st ~= nil then
            if st.remove then return nil, 'staged' end
            return st.value, 'staged' -- a staged false is false
        end
        return from_file(name)
    end
    -- The file's own value, whatever is staged.
    function S.JobInFile(name) return from_file(name) end
    -- Staged for the job file's Save (S.REMOVE: its line taken out). t: written as T{...} (a T{} default's methods).
    -- Back to what the file has: nothing staged.
    function S.StageJob(name, v, t, textFor) -- textFor(value, indent): its own Lua text (gcinclude.Rules: a rule a line)
        local staged = S.JobStaged()
        local fv, why = from_file(name)
        if v == S.REMOVE then
            staged[name] = (why ~= 'none') and { remove = true } or nil
        elseif (why == 'file') and same(fv, v) then
            staged[name] = nil
        else
            staged[name] = { value = v, T = t, text = textFor }
        end
        local d = doc()
        if d ~= nil then d.revision = (d.revision or 0) + 1 end
    end
    -- A staged value as Lua text at an indent (the Save writes it).
    function S.JobText(entry, ind)
        if entry.text ~= nil then return entry.text(entry.value, ind) end
        return (entry.T and 'T' or '') .. G.SerializeValue(entry.value, F.QuoteText, F.FormatKey, ind)
    end
    -- A setting's value for the job open in the editor: its own line, else S.Get's. Also 'job' as where from.
    function S.GetForJob(key)
        local v = S.Job('settings.' .. key)
        if v ~= nil then return v, 'job' end
        return S.Get(key)
    end

    -- == Heading prefs: one layout, from this character's char.lua when it has any, else the shared file. ==
    local PREF_KEYS = { 'EditorGroups', 'EditorHidden', 'EditorSort', 'EditorOrder' }
    function S.HeadingSource()
        for _, which in ipairs({ 'own', 'shared' }) do
            for _, k in ipairs(PREF_KEYS) do
                if layer(which).settings[k] ~= nil then return which end
            end
        end
        return 'own'
    end
    function S.HeadingPref(key) return layer(S.HeadingSource()).settings[key] end
    function S.SaveHeadings(changes) return S.Write(S.HeadingSource(), changes) end
    -- This character's headings become the shared ones, and it uses them from there.
    function S.ShareHeadings()
        local values, remove = {}, {}
        for _, k in ipairs(PREF_KEYS) do
            local v = layer('own').settings[k]
            values[k] = (v ~= nil) and v or S.REMOVE
            if v ~= nil then remove[k] = S.REMOVE end
        end
        local ok, err = S.Write('shared', values)
        if ok and (next(remove) ~= nil) then ok, err = S.Write('own', remove) end
        return ok, err
    end
    -- The shared headings copied into char.lua, so changes stay on this character.
    function S.OwnHeadings()
        local changes = {}
        for _, k in ipairs(PREF_KEYS) do changes[k] = layer('shared').settings[k] end
        if next(changes) == nil then changes.EditorGroups = {} end -- marks them as this character's own
        return S.Write('own', changes)
    end

    -- Folded headings last the game session (GcEditFold); the gcedit-folds.txt they were once kept in, beside
    -- char.lua, is removed.
    function S.RemoveOldFolds()
        local own = path_of('own')
        local dir = (own ~= nil) and string.match(own, '^(.*[\\/])') or nil
        if dir ~= nil then os.remove(dir .. 'gcedit-folds.txt') end
    end

    return S
end
