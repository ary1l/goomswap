-- <JOB>.goom.lua: a job file's sets, rules and options as plain data, beside the job file. The job file (<JOB>.lua)
-- is what LuAshitacast runs and what you share; this one is GoomSwap's own format of the same things, written by every
-- /gcedit Save and refreshed from the job file when that changed outside the editor (its source hash differs).
-- Values written as code in the job file (a variable, a call) are not data: they are named under `code`.
-- Pure: reads text, returns text.
local G = {}
G.FORMAT = 1

-- A short fingerprint of a text, to see whether the job file changed since the data was written.
function G.Hash(text) -- djb2 over the bytes, kept exact in doubles (each step < 2^38), plus the length
    local h = 5381
    for i = 1, #text do h = (h * 33 + string.byte(text, i)) % 4294967296 end
    return string.format('%08x-%d', h, #text)
end

-- Lua data from text (no code run; T{...} allowed): the value, or nil when it is code.
local function data_of(text)
    local chunk = (loadstring or load)('return ' .. text)
    if chunk == nil then return nil end
    if setfenv ~= nil then setfenv(chunk, { T = function(t) return t end }) end
    local ok, v = pcall(chunk)
    if not ok then return nil end
    return v
end

-- The job file's own options GoomSwap reads (gcinclude.X lines), besides gcinclude.Rules.
G.OPTIONS = { 'WeaponModes', 'DefaultWeapons', 'WeaponRoles', 'MainModes', 'SubModes', 'RangeModes', 'WeaponItemMap',
    'AlwaysDualWield', 'MeleeModes', 'NukeModes', 'SIRSkip', 'THSkip', 'CureObi', 'SafeAmmo', 'RangeAmmo', 'CORmsg',
    'LockstyleSet' }

-- text: the job file. setFile: gcsetfile. The data table, or nil and why.
function G.Export(text, setFile, info)
    local model, err = setFile.Parse(text)
    if model == nil then return nil, err end
    local out = { format = G.FORMAT, job = info and info.job or nil,
        source = { file = info and info.file or nil, hash = G.Hash(text) },
        sets = {}, order = {}, options = {}, settings = {}, code = {} }
    -- the sets table's entries, each read as data; one written as code is named, not copied
    local entries = {}
    for _, set in ipairs(model.list) do
        if set.parentName == nil and set.entry ~= nil then entries[#entries + 1] = set end
    end
    for _, set in ipairs(entries) do
        local e = set.entry
        local v = data_of(string.sub(text, e.vstart, e.vend - 1))
        if type(v) == 'table' then
            out.sets[set.name] = v
            out.order[#out.order + 1] = set.name
        else
            out.code[#out.code + 1] = 'sets.' .. set.name
        end
    end
    local function read(name, into, key)
        local raw, why = setFile.JobSetting(text, name)
        if raw == nil then
            if (why ~= 'none') then out.code[#out.code + 1] = name end
            return
        end
        local v = data_of(raw)
        if v == nil then out.code[#out.code + 1] = name else into[key] = v end
    end
    read('Rules', out, 'rules')
    read('profile.Packer', out, 'packer')
    for _, name in ipairs(G.OPTIONS) do read(name, out.options, name) end
    -- gcinclude.settings.X lines
    for key in string.gmatch(text, 'gcinclude%s*%.%s*settings%s*%.%s*([%a_][%w_]*)%s*=') do
        if out.settings[key] == nil then read('settings.' .. key, out.settings, key) end
    end
    if next(out.code) == nil then out.code = nil end
    return out
end

-- The data as the file's text: a header saying what it is, then one return table.
function G.Text(data, serialize)
    return '-- GoomSwap data for ' .. tostring(data.source and data.source.file or 'the job file') .. ': its sets, rules '
        .. 'and options as plain data.\n-- Written by /gcedit\'s Save. ' .. tostring(data.source and data.source.file or
        'The job file') .. ' is what LuAshitacast runs and what you share; this file is kept in step with it.\n'
        .. 'return ' .. serialize(data) .. '\n'
end

-- The data a .goom.lua file holds (read as data), or nil.
function G.Read(text)
    if type(text) ~= 'string' then return nil end
    local body = string.match(text, 'return%s+(.*)$')
    if body == nil then return nil end
    local v = data_of(body)
    return (type(v) == 'table') and v or nil
end

-- Whether the data file is in step with the job file's text.
function G.InStep(dataText, jobText)
    local d = G.Read(dataText)
    return (d ~= nil) and (d.format == G.FORMAT) and (d.source ~= nil) and (d.source.hash == G.Hash(jobText or ''))
end

-- <path>/WHM.lua -> <path>/WHM.goom.lua
function G.PathFor(jobPath)
    if type(jobPath) ~= 'string' then return nil end
    return (string.gsub(jobPath, '%.lua$', '')) .. '.goom.lua'
end

return G
