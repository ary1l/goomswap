-- GoomSwap tests: luajit tests/run.lua (from the repo root, or with the root as the first argument).
-- No game needed: every .lua file must compile, and the two converters (common/gcbuild.lua, sel2goom.lua) are
-- text in, text out, so they run here against all 22 examples.
local root = (...) or (arg and arg[0] and string.match(arg[0], '^(.*)[/\\]tests[/\\][^/\\]*$')) or '.';
local JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG',
    'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' };
local fails, checks, log = 0, 0, {};
local function check(ok, what)
    checks = checks + 1;
    if not ok then fails = fails + 1; log[#log + 1] = 'FAIL ' .. tostring(what) end
    return ok;
end
local function read(p)
    local f = io.open(p, 'rb');
    if (f == nil) then return nil end
    local t = f:read('*a');
    f:close();
    return t;
end
local function has(text, piece) return string.find(text, piece, 1, true) ~= nil end
local function compiles(text, name)
    local fn, err = loadstring(text, name);
    return check(fn ~= nil, name .. ' compiles' .. ((err ~= nil) and (': ' .. tostring(err)) or ''));
end

---------------------------------------------------------------------------------------------------
-- 1. Every file compiles
---------------------------------------------------------------------------------------------------
local files = { 'common/gcaction.lua', 'common/gcauto.lua', 'common/gcbuild.lua', 'common/gcdisplay.lua', 'common/gchud.lua',
    'common/gcinclude.lua', 'common/scdata.lua', 'examples/char.lua', 'windower/GearSwap/data/default.lua',
    'windower/GearSwap/data/goomswap_migrate.lua', 'windower/GearSwap/data/goomswap/ashita.lua',
    'windower/GearSwap/data/goomswap/core.lua', 'windower/GearSwap/data/goomswap/imgui.lua',
    'windower/GearSwap/data/goomswap/sel2goom.lua' };
for _, job in ipairs(JOBS) do files[#files + 1] = 'examples/' .. job .. '.lua' end
for _, f in ipairs(files) do
    local text = read(root .. '/' .. f);
    if check(text ~= nil, f .. ' exists') then compiles(text, f) end
end

-- The part of a job file after its sets: what a converter must leave alone.
local function tail(text) return string.sub(text, (string.find(text, '\nprofile.Sets', 1, true))) end
-- Every sets.<name> the handlers use is a set of the file.
local function refs_ok(text, name)
    local block = string.sub(text, (string.find(text, 'local sets = {', 1, true)), (string.find(text, '\nprofile.Sets', 1, true)));
    local keys = {};
    for k in string.gmatch(block, '\n    ([%a_][%w_]*) = {') do keys[k] = true end
    for k in string.gmatch(block, '\n    %[[\'"](.-)[\'"]%] = {') do keys[k] = true end
    for ref in string.gmatch(tail(text), '[^%w_]sets%.([%a_][%w_]*)') do
        if not keys[ref] then return check(false, name .. ': handlers use sets.' .. ref .. ', which the file lacks') end
    end
    return check(true, name);
end

---------------------------------------------------------------------------------------------------
-- 2. /gcbuild (common/gcbuild.lua)
---------------------------------------------------------------------------------------------------
local B = assert(loadfile(root .. '/common/gcbuild.lua'))();
local function copy(bag, augs, path) return { bag = bag or 'Wardrobe', equippable = (bag == nil) or (string.sub(bag, 1, 8) == 'Wardrobe'), augs = augs or {}, path = path } end
for _, job in ipairs(JOBS) do
    local tpl = read(root .. '/examples/' .. job .. '.lua');
    -- nothing owned: every item line goes, the file still loads, nothing after the sets changes
    local none, r0 = B.Build(tpl, {}, { name = 'T', job = job });
    compiles(none, 'gcbuild ' .. job .. ' (nothing owned)');
    check(r0.kept + r0.dropped == r0.slots, 'gcbuild ' .. job .. ': kept + left out = slots');
    local names = {};
    for _, m in ipairs(r0.missing) do names[#names + 1] = m[1] end
    -- everything owned twice, unaugmented: nothing is left out, and nothing outside the sets changes
    local all = {};
    for _, n in ipairs(names) do all[string.lower(n)] = { name = n, copies = { copy(), copy() } } end
    local full, r1 = B.Build(tpl, all, { name = 'T', job = job });
    compiles(full, 'gcbuild ' .. job .. ' (everything owned)');
    check(r1.dropped == 0, 'gcbuild ' .. job .. ': everything owned leaves nothing out (' .. r1.dropped .. ')');
    check(#r1.modes == 0, 'gcbuild ' .. job .. ': everything owned keeps every weapon mode');
    check(tail(full) == tail(tpl), 'gcbuild ' .. job .. ': everything owned leaves OnLoad and the handlers as they are');
    -- every other item owned, some only in the Safe
    local half, k = {}, 0;
    for i, n in ipairs(names) do
        if (i % 2 == 0) then k = k + 1; half[string.lower(n)] = { name = n, copies = { copy((k % 4 == 0) and 'Safe' or 'Wardrobe 2') } } end
    end
    local mixed = B.Build(tpl, half, { name = 'T', job = job, family = true });
    compiles(mixed, 'gcbuild ' .. job .. ' (half owned, family)');
    refs_ok(mixed, 'gcbuild ' .. job .. ' (half owned)');
end

local TPL = [[
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
local sets = {
    A = {
        Head = 'Nyame Helm', -- keep me
        Back = { Name = 'Sucellos\'s Cape', Augment = { [1] = 'STR+30', [2] = 'Weapon skill damage +10%' } },
        Main = { Name = 'Rostam', AugPath = 'B' },
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Chirich Ring +1',
        Range = 'displaced',
        Ear1 = 'Not Owned Earring',
        --Ear2 = 'Already Commented',
        Hands = 'Leth. Ganth. +3',
        Feet= "Viti. Boots +4",
    },
    Mp_Body = {Body = 'Seidr Cotehardie',},
    Two = { Head = 'Nyame Helm', Neck = 'Missing Torque', Waist = 'Old Belt' },
    Buffs = { ['Aftermath: Lv.3'] = { Hands = 'Missing Gloves' }, },
    Weapon_Naegling = {
        Main = 'Naegling',
        Sub = 'Old Belt',
    },
    Weapon_Kept = {
        Main = 'Nyame Helm',
    },
    ['Weapon_Bow'] = { Range = 'Missing Bow', Ammo = 'Missing Arrow' },
};
profile.Sets = sets;
profile.OnLoad = function()
    gcinclude.WeaponModes = {'None', 'Naegling', 'Kept', 'Bow', 'NoSet'}; -- modes
    gcinclude.DefaultWeapons = 'Naegling';
    gcinclude.SubModes = {'None', 'Old Belt', 'Missing Shield', 'RostamA', 'DeathP'};
    gcinclude.WeaponItemMap = {
        ['RostamA'] = { Name = 'Rostam', AugPath = 'A' },
        DeathP = { Name = 'Death Penalty' },
    };
    gcinclude.Initialize();
end
profile.HandleDefault = function() gFunc.Equip('Sub', 'Genmei Shield'); gFunc.Equip('Main', 'remove') end
]];
local function owned_unit(loose)
    return {
        ['nyame helm'] = { name = 'Nyame Helm', copies = { copy() } },
        ["sucellos's cape"] = { name = "Sucellos's Cape", copies = {
            { bag = 'Wardrobe', equippable = true, loose = loose, augs = { 'MND+20', 'Haste+10' } },
            { bag = 'Safe', equippable = false, loose = loose, augs = loose and { 'STR+30', 'Weapon skill damage +10%', 'Attack+20' }
                or { 'STR+30', 'Weapon skill damage +10%', 'Attack+20' } } } },
        ['rostam'] = { name = 'Rostam', copies = { copy(nil, {}, 'A') } },
        ['chirich ring +1'] = { name = 'Chirich Ring +1', copies = { copy() } },
        ['chirich ring'] = { name = 'Chirich Ring', copies = { copy() } },
        ['leth. ganth. +2'] = { name = 'Leth. Ganth. +2', copies = { copy('Locker') } },
        ['leth. ganth. +1'] = { name = 'Leth. Ganth. +1', copies = { copy() } },
        ['viti. boots +4'] = { name = 'Viti. Boots +4', copies = { copy('Locker') } },
        ['old belt'] = { name = 'Old Belt', copies = { copy('Wardrobe 3') } },
    };
end
do
    local t, r = B.Build(TPL, owned_unit(), { name = 'Unit', job = 'XXX' });
    compiles(t, 'gcbuild unit');
    check(has(t, "        Head = 'Nyame Helm', -- keep me\n"), 'gcbuild: an owned item keeps its line');
    check(has(t, "Augment = { [1] = 'STR+30', [2] = 'Weapon skill damage +10%' } }, -- in Safe: move it to a wardrobe"), 'gcbuild: the copy with the listed augments, in the Safe');
    check(has(t, "        Main = 'Rostam', -- your augments differ from the example's: Path A"), 'gcbuild: another augment path keeps the name');
    check(has(t, "        Ring1 = 'Chirich Ring +1',\n        --Ring2 = 'Chirich Ring +1', -- only 1 owned"), 'gcbuild: one copy, two slots');
    check(has(t, "        Range = 'displaced',"), 'gcbuild: slot words are no items');
    check(has(t, "        --Ear1 = 'Not Owned Earring', -- not owned"), 'gcbuild: not owned is commented out');
    check(has(t, "        --Ear2 = 'Already Commented',\n"), 'gcbuild: a commented line is left alone');
    check(has(t, "        --Hands = 'Leth. Ganth. +3', -- not owned"), 'gcbuild: no family swap unless asked');
    check(has(t, "    Mp_Body = {}, -- not owned: Seidr Cotehardie"), 'gcbuild: a one-line set');
    check(has(t, "    Two = { Head = 'Nyame Helm', Waist = 'Old Belt' }, -- not owned: Missing Torque"), 'gcbuild: one slot out of a one-line set');
    check(has(t, "gcinclude.WeaponModes = {'None', 'Kept', 'NoSet'}; -- modes -- /gcbuild took out (weapon not owned): Naegling, Bow"), 'gcbuild: weapon modes without their weapon leave /wm');
    check(has(t, "gcinclude.DefaultWeapons = 'Kept'; -- /gcbuild: was Naegling (weapon not owned)"), 'gcbuild: the default moves to a mode that is left');
    check(#r.outside == 3 and r.outside[1][1] == 'Missing Shield' and r.outside[2][1] == 'Death Penalty' and r.outside[3][1] == 'Genmei Shield',
        'gcbuild: names outside the sets are listed, an item map\'s key by its item (' .. #r.outside .. ')');
    check(has(t, "gcinclude.SubModes = {'None', 'Old Belt', 'Missing Shield', 'RostamA', 'DeathP'};\n"), 'gcbuild: slot-pick lists are not changed');
    check(r.kept + r.dropped == r.slots, 'gcbuild unit: counts add up');

    local f, rf = B.Build(TPL, owned_unit(), { name = 'Unit', job = 'XXX', family = true });
    compiles(f, 'gcbuild unit (family)');
    check(has(f, "        Ring2 = 'Chirich Ring', -- example: Chirich Ring +1"), 'gcbuild family: the second ring is the plain one');
    check(has(f, "        Hands = 'Leth. Ganth. +2', -- example: Leth. Ganth. +3; yours is in Locker: move it to a wardrobe"), 'gcbuild family: the highest version owned, and its bag');
    check(rf.family == 2, 'gcbuild family: two slots (' .. rf.family .. ')');
    check(has(f, "        --Ear1 = 'Not Owned Earring', -- not owned"), 'gcbuild family: nothing else is picked');

    -- /gcaudit: the same findings as a report, the file itself untouched
    local at, ar = B.Audit(TPL, owned_unit(), { name = 'Unit', job = 'XXX' });
    check(has(at, '19 set slots name an item: 7 fine, 8 not owned, 1 need a second copy, 1 with other augments, 2 in a bag'), 'gcaudit: the counts line');
    check(has(at, "Not owned (these lines do nothing):\n  Not Owned Earring (1)\n      A Ear1"), 'gcaudit: not owned, with where');
    check(has(at, "  Chirich Ring +1: only 1 owned\n      A Ring2"), 'gcaudit: one copy for two slots');
    check(has(at, "  Rostam - yours: Path A\n      A Main"), 'gcaudit: other augments');
    check(has(at, "  Viti. Boots +4 [Locker]\n      A Feet"), 'gcaudit: wrong bag');
    check(has(at, 'Weapon modes whose Weapon_<mode> set has no weapon you own: Naegling, Bow'), 'gcaudit: weapon modes');
    check(has(at, "Named outside the sets and not owned:\n  Missing Shield (SubModes)"), 'gcaudit: names outside the sets');
    check(ar.audit.missing == 8 and ar.audit.short == 1 and ar.audit.name == 1 and ar.audit.move == 2, 'gcaudit: report numbers');
    local clean = B.Audit("local sets = {\n    A = {\n        Head = 'Nyame Helm',\n    },\n};\nprofile.Sets = sets;\n", owned_unit(), { job = 'XXX' });
    check(has(clean, '1 set slots name an item: 1 fine, 0 not owned') and not has(clean, 'Not owned ('), 'gcaudit: a clean file has no sections');

    -- Windower: augment strings are compared loosely (one string per augment slot, other spelling)
    local w = owned_unit(true);
    w["sucellos's cape"].copies[2].augs = { 'STR+30', '"Weapon skill damage "+10%', 'Accuracy+20 Attack+20' };
    local wt = B.Build(TPL, w, { name = 'Unit', job = 'XXX' });
    check(has(wt, "Augment = { [1] = 'STR+30', [2] = 'Weapon skill damage +10%' } }, -- in Safe: move it to a wardrobe"), 'gcbuild Windower: the listed augments found in the copy\'s own strings');
end

---------------------------------------------------------------------------------------------------
-- 3. Selindrile migration (sel2goom.lua)
---------------------------------------------------------------------------------------------------
local S2G = assert(loadfile(root .. '/windower/GearSwap/data/goomswap/sel2goom.lua'))();
local io_ = { read = read, loadstring = loadstring, setfenv = setfenv };
local out = {};
for _, job in ipairs(JOBS) do
    local ok, text, rep = pcall(S2G.Convert, { io_ = io_, name = 'Tester', job = job, sub = 'NIN',
        gear_file = root .. '/tests/sel/Tester_Gear.lua', pre_files = { root .. '/tests/sel/Tester-Globals.lua' },
        mappings_file = root .. '/tests/sel/Sel-Mappings.lua', template_text = read(root .. '/examples/' .. job .. '.lua'), source_label = 'test' });
    if check(ok and (type(text) == 'string'), 'sel2goom ' .. job .. ' converts' .. ((not ok) and (': ' .. tostring(text)) or '')) then
        compiles(text, 'sel2goom ' .. job);
        refs_ok(text, 'sel2goom ' .. job);
        check(#rep.failed == 0, 'sel2goom ' .. job .. ': nothing failed to run');
        out[job] = text;
    end
end
-- Each converted file loaded the way the game would (stand-ins for the engine): it runs, OnLoad runs, every set
-- holds slots with item names, no set name appears twice, every weapon mode has its set.
local SLOTS = { Main = 1, Sub = 1, Range = 1, Ammo = 1, Head = 1, Neck = 1, Ear1 = 1, Ear2 = 1, Body = 1, Hands = 1, Ring1 = 1, Ring2 = 1,
    Back = 1, Waist = 1, Legs = 1, Feet = 1 };
local function loads_like_a_job_file(text, name)
    local block, seen = string.sub(text, (string.find(text, 'local sets = {', 1, true)), (string.find(text, '\nprofile.Sets', 1, true))), {};
    for _, pat in ipairs({ '\n    ([%a_][%w_]*) = {', '\n    %["(.-)"%] = {', "\n    %['(.-)'%] = {" }) do
        for key in string.gmatch(block, pat) do
            if seen[string.lower(key)] then return check(false, name .. ': set ' .. key .. ' is there twice') end
            seen[string.lower(key)] = true;
        end
    end
    local stubmt = {};
    local function stub() return setmetatable({}, stubmt) end
    stubmt.__index = function() return stub() end
    stubmt.__call = function() return stub() end
    local inc = setmetatable({ settings = { Keybinds = {} } }, { __index = function() return stub() end });
    local env = setmetatable({ gFunc = { LoadFile = function() return inc end }, gcinclude = inc, gSettings = {}, T = function(t) return t end,
        ipairs = ipairs, pairs = pairs, table = table, string = string, type = type, error = error, tostring = tostring },
        { __index = function() return stub() end });
    local fn = loadstring(text, name);
    if (fn == nil) then return check(false, name .. ' compiles') end
    setfenv(fn, env);
    local ok, profile = pcall(fn);
    if not (ok and (type(profile) == 'table') and (type(profile.Sets) == 'table')) then return check(false, name .. ' loads: ' .. tostring(profile)) end
    local okl, e = pcall(profile.OnLoad);
    if not okl then return check(false, name .. ': OnLoad runs: ' .. tostring(e)) end
    local function bad_set(set, depth)
        for k, v in pairs(set) do
            if SLOTS[k] then
                local nm = (type(v) == 'table') and (v.name or v.Name) or v;
                if (type(nm) ~= 'string') or (nm == '') then return tostring(k) .. ' has no item name' end
            elseif (type(v) == 'table') and (depth < 2) then
                local why = bad_set(v, depth + 1);
                if (why ~= nil) then return why end
            else
                return 'odd key ' .. tostring(k);
            end
        end
        return nil;
    end
    local lower = {};
    for sname, set in pairs(profile.Sets) do
        lower[string.lower(tostring(sname))] = true;
        local why = (type(set) ~= 'table') and 'not a table' or bad_set(set, 0);
        if (why ~= nil) then return check(false, name .. ': set ' .. tostring(sname) .. ': ' .. why) end
    end
    local modes, isMode = rawget(inc, 'WeaponModes'), {};
    for _, m in ipairs((type(modes) == 'table') and modes or {}) do
        isMode[m] = true;
        if (m ~= 'None') and not lower['weapon_' .. string.lower(m)] then return check(false, name .. ': weapon mode ' .. m .. ' has no Weapon_ set') end
    end
    local d = rawget(inc, 'DefaultWeapons');
    if (type(d) == 'string') and (type(modes) == 'table') and not isMode[d] then return check(false, name .. ': DefaultWeapons ' .. d .. ' is no weapon mode') end
    return check(true, name);
end
for _, job in ipairs(JOBS) do
    if (out[job] ~= nil) then loads_like_a_job_file(out[job], 'sel2goom ' .. job .. ' as a job file') end
    loads_like_a_job_file(read(root .. '/examples/' .. job .. '.lua'), 'examples/' .. job .. '.lua as a job file');
end

local function placed(job, from, as) return has(out[job] or '', '    -- from sets.' .. from .. '\n    ' .. as .. ' = {') end
local function unused(job, path) return has(out[job] or '', 'Sel_' .. path) end
check(placed('RDM', 'idle', 'Idle') and placed('RDM', 'engaged', 'Tp_Default') and placed('RDM', 'engaged.Acc', 'Tp_Acc'), 'sel2goom: idle, engaged, engaged.Acc');
check(placed('RDM', 'defense.PDT', 'Dt') and placed('RDM', 'defense.MDT', 'mdt'), 'sel2goom: defense sets');
check(placed('RDM', 'precast.WS.Savage Blade', '["Savage Blade"]') and placed('RDM', 'precast.WS.Savage Blade.Acc', '["Savage Blade_Acc"]'), 'sel2goom: a weapon skill and its Acc set');
check(placed('RDM', 'precast.WS.Proc', 'Ws_Proc') and not placed('RDM', 'precast.WS.Proc', 'Proc'), 'sel2goom: WS Proc mode is Ws_Proc, not the engaged Proc set');
check(placed('RDM', 'precast.WS.Savage Blade.PDL', '["Savage Blade_HighBuff"]'), 'sel2goom: PDL is /wsset high');
check(unused('RDM', 'precast.WS.Fodder') and not placed('RDM', 'precast.WS.Fodder', 'Fodder'), 'sel2goom: a WS-only mode word is no weapon skill');
check(placed('RDM', 'MagicBurst', 'Burst') and unused('WAR', 'MagicBurst'), 'sel2goom: Burst only where the template wears it');
check(placed('PLD', 'Enmity', 'Enmity') and unused('RDM', 'Enmity'), 'sel2goom: Enmity only where the template wears it');
check(placed('THF', 'buff.Sneak Attack', 'SA') and unused('RDM', 'buff.Sneak Attack'), 'sel2goom: buff sets only where the template has them');
check(placed('RDM', 'buff.Doom', 'Doomed'), 'sel2goom: Doomed on every job');
check(placed('BRD', 'precast.JA.Nightingale', 'Nitro') and placed('RDM', 'precast.JA.Nightingale', 'Nightingale'), 'sel2goom: an ability under its template\'s group set, else its own name');
do
    local old = string.gsub(read(root .. '/examples/WAR.lua'), 'ByName', 'Unnamed');
    local text, why = S2G.Convert({ io_ = io_, name = 'Tester', job = 'WAR', gear_file = root .. '/tests/sel/Tester_Gear.lua', template_text = old });
    check((text == nil) and has(tostring(why), 'old one'), 'sel2goom: a template from before the by-name lookups is refused');
end
check(placed('RDM', 'precast.FC.Impact', 'Impact_Precast') and placed('RDM', 'precast.FC.Elemental Magic', '["Elemental Magic_Precast"]'), 'sel2goom: precast sets by spell family and skill');
check(placed('BRD', 'precast.FC.BardSong', 'Singing_Precast') and unused('RDM', 'precast.FC.BardSong') and unused('RDM', 'precast.FC.Trust'), 'sel2goom: spell.type precast keys');
check(unused('WAR', 'precast.FC.Impact'), 'sel2goom: no precast by name where the template has no lookup');
check(unused('BLU', 'midcast.Enhancing Magic') and placed('RDM', 'midcast.Enhancing Magic', '["Enhancing Magic"]'), 'sel2goom: skill-named midcast sets need ByName(spell.Skill)');
check(has(out.RDM or '', 'gcinclude.MeleeModes = {"Default", "Acc", "FullAcc"};'), 'sel2goom: the job\'s own setup wins over the global one');
check(has(out.RDM or '', 'gcinclude.WeaponModes = {"None", "Naegling", "Maxentius", "DualWeapons"};'), 'sel2goom: weapon modes from state.Weapons');
check(has(out.RDM or '', 'sets["Erase"] = sets["StatusRemoval"];'), 'sel2goom: a spell group becomes one alias per spell');
check(has(out.RDM or '', 'not copied here (1): Capacity.') and not unused('RDM', 'Capacity') and placed('RDM', 'Kiting', 'Movement'), 'sel2goom: Globals sets are named once, mapped ones still placed');
check(has(out.RDM or '', '1 slots named gear.ElementalObi'), 'sel2goom: elemental placeholders are not unreadable slots');
do -- Moonshade leaves weapon skill sets; the other earring ends where the engine won't cover it
    local function set(name) return string.match(out.RDM or '', '\n    %["' .. name .. '"%] = {\n(.-)\n    },') or '' end
    check(not has(out.RDM or '', 'Moonshade Earring",'), 'sel2goom: no Moonshade line left in a weapon skill set');
    check(has(set('Chant du Cygne'), 'Ear1 = "Sherida Earring"') and not has(set('Chant du Cygne'), 'Ear2'), 'sel2goom: Moonshade in Ear1: the other earring moves to Ear1');
    check(has(set('Seraph Blade'), 'Ear2 = "Leth. Earring +1"') and not has(set('Seraph Blade'), 'Ear1'), 'sel2goom: a right-ear-only earring stays in Ear2');
    check(has(set('Sanguine Blade'), 'Ear1 = "Regal Earring"') and not has(set('Sanguine Blade'), 'Ear2'), 'sel2goom: Moonshade in Ear2 is just taken out');
    check(has(out.RDM or '', '3 weapon skill sets named Moonshade Earring'), 'sel2goom: the header says so');
end
check(not has(out.RDM or '', ' = "",') and not has(out.RDM or '', 'HPDown (Legs)'), 'sel2goom: a slot given as "" is left out, not written or reported');
check(has(out.RDM or '', '{ "^f7", "wm Naegling" }') and has(out.RDM or '', '{ "!q", "/ma \\"Temper II\\" <me>" }'), 'sel2goom: binds become Keybinds');

for _, l in ipairs(log) do print(l) end
print(string.format('%d checks, %d failed', checks, fails));
if (os.exit ~= nil) and (arg ~= nil) then os.exit((fails == 0) and 0 or 1) end
return fails;
