-- GoomSwap: move a character from Selindrile's GearSwap to GoomSwap. Goes in Windower/addons/GearSwap/data/.
--   //gs load goomswap_migrate
-- For every job with a Selindrile gear file (data/<Name>/<Name>_<Job>_Gear.lua) it writes a GoomSwap job file,
-- data/goomswap/<Name>/<JOB>.lua, from the job's GoomSwap template
-- (data/goomswap/examples/<JOB>.lua) with your gear in it, plus a one-line data/<Name>/<JOB>.lua that makes
-- GearSwap load GoomSwap for that job instead of Selindrile's data/<JOB>.lua. Then //gs reload.
-- Re-run: a <JOB>.lua an earlier run wrote is replaced (old one kept as <JOB>.lua.bak); one you wrote yourself is
-- left alone and the new file is <JOB>.migrated.lua.
-- Your Selindrile files are only read. Back to Selindrile for a job: delete data/<Name>/<JOB>.lua.

local G = gearswap or _G;
local DATA = windower.addon_path .. 'data/';
local ROOT = DATA .. 'goomswap/';

local function say(color, msg) windower.add_to_chat(color, '[GoomSwap] ' .. msg) end
local function read(path)
    local f = io.open(path, 'rb');
    if (f == nil) then return nil end
    local t = f:read('*a');
    f:close();
    return t;
end
local function write(path, text)
    local f = io.open(path, 'wb');
    if (f == nil) then return false end
    f:write(text);
    f:close();
    return true;
end
local function exists(path) return windower.file_exists(path) end
local function find_ci(dir, want) -- file in dir whose name matches want in any case (Windows doesn't care, the list does)
    local ok, list = pcall(windower.get_dir, dir);
    if (not ok) or (type(list) ~= 'table') then return nil end
    want = string.lower(want);
    for _, e in ipairs(list) do
        if (string.lower(tostring(e)) == want) then return dir .. tostring(e) end
    end
    return nil;
end

local function load_lib()
    local fn, err = G.loadfile(ROOT .. 'sel2goom.lua');
    if (fn == nil) then return nil, tostring(err) end
    G.setfenv(fn, getfenv and getfenv(1) or _G);
    local ok, lib = pcall(fn);
    if (not ok) then return nil, tostring(lib) end
    return lib;
end

local function migrate()
    local p = windower.ffxi.get_player();
    if (p == nil) or (p.name == nil) then say(167, 'migrate: not logged in.'); return end
    local name = p.name;
    local S2G, err = load_lib();
    if (S2G == nil) then say(167, 'migrate: cannot load goomswap/sel2goom.lua: ' .. tostring(err)); return end
    if not windower.dir_exists(ROOT .. 'examples') then
        say(167, 'migrate: data/goomswap/examples/ is missing: copy the repo\'s examples/ folder there (the GoomSwap job templates).');
        return;
    end
    local charDir = DATA .. name .. '/';
    local io_ = { read = read, loadstring = G.loadstring or loadstring, setfenv = G.setfenv or setfenv };
    local pre = {};
    for _, f in ipairs({ DATA .. 'User/User-Globals.lua', charDir .. name .. '-Globals.lua', DATA .. name .. '-Globals.lua',
        charDir .. name .. '-Items.lua', DATA .. name .. '-Items.lua' }) do
        if exists(f) then pre[#pre + 1] = f end
    end
    local mappings = windower.addon_path .. 'libs/Sel-Mappings.lua';
    if not exists(mappings) then mappings = nil end
    if not windower.dir_exists(ROOT .. name) then windower.create_dir(ROOT .. name) end
    local done = 0;
    for _, job in ipairs(S2G.JOBS) do
        local gearFile = find_ci(charDir, name .. '_' .. job .. '_gear.lua');
        if (gearFile ~= nil) then
            local tpl = read(ROOT .. 'examples/' .. job .. '.lua');
            if (tpl == nil) then
                say(167, job .. ': no template data/goomswap/examples/' .. job .. '.lua, skipped.');
            else
                local jobPre = {};
                for _, f in ipairs(pre) do jobPre[#jobPre + 1] = f end
                -- Sel-Include loads User-<JOB>.lua after the Globals/Items files and before the gear file
                for _, f in ipairs({ charDir .. 'User-' .. job .. '.lua', DATA .. 'User/User-' .. job .. '.lua', DATA .. 'User-' .. job .. '.lua' }) do
                    if exists(f) then jobPre[#jobPre + 1] = f end
                end
                local text, rep = S2G.Convert({ io_ = io_, name = name, job = job, sub = p.sub_job, gear_file = gearFile,
                    pre_files = jobPre, mappings_file = mappings, template_text = tpl,
                    source_label = 'data/' .. name .. '/' .. string.match(gearFile, '[^/\\]+$') });
                if (text == nil) then
                    say(167, job .. ': ' .. tostring(rep));
                else
                    local out, kept = ROOT .. name .. '/' .. job .. '.lua', '';
                    if exists(out) then
                        local old = read(out) or '';
                        if (string.sub(old, 1, 27) == '-- Migrated from Selindrile') then -- an earlier run wrote it: replace, keep a copy
                            write(out .. '.bak', old);
                            kept = ' (old one kept as ' .. job .. '.lua.bak)';
                        else -- your own file: leave it alone
                            out = ROOT .. name .. '/' .. job .. '.migrated.lua';
                        end
                    end
                    if write(out, text) then
                        done = done + 1;
                        local k = rep.keys or { added = {}, dropped = {} };
                        say(207, string.format('%s: %d sets placed, %d kept as Sel_*, %d keys added, %d keys left out -> %s', job,
                            rep.mapped, #rep.unmapped, #k.added, #k.dropped, string.sub(out, #DATA + 1)) .. kept);
                        local stub = DATA .. name .. '/' .. job .. '.lua';
                        if (not exists(stub)) and string.match(out, '/' .. job .. '%.lua$') then
                            write(stub, '-- GoomSwap entry for ' .. job .. ' (written by goomswap_migrate). GearSwap loads this before\n'
                                .. '-- Selindrile\'s data/' .. job .. '.lua. Delete this file to go back to Selindrile for ' .. job .. '.\n'
                                .. "include('goomswap/core.lua');\n");
                        end
                    else
                        say(167, job .. ': cannot write ' .. out);
                    end
                end
            end
        end
    end
    if (done == 0) then
        say(167, 'migrate: no Selindrile gear files found in data/' .. name .. '/ (' .. name .. '_<Job>_Gear.lua).');
    else
        say(207, 'migrate: ' .. done .. ' job(s) done. //gs reload (or change job) to run GoomSwap; //gs c checksets to check names.');
    end
end

function get_sets()
    sets = {};
    local ok, e = pcall(migrate);
    if not ok then say(167, 'migrate failed: ' .. tostring(e)) end
end
