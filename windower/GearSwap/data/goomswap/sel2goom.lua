-- Selindrile GearSwap -> GoomSwap job files (Windower). Used by goomswap_migrate.lua (//gs load goomswap_migrate).
--
-- A Selindrile gear file (data/<Name>/<Name>_<Job>_Gear.lua) builds its sets with code (set_combine, local
-- variables, user_job_setup/init_gear_sets), so it is run in a sandbox with stand-ins for GearSwap/Selindrile
-- (state modes, set_combine, send_command, windower...), after the same files Selindrile loads first
-- (User-Globals, <Name>-Globals, <Name>-Items, Sel-Mappings for spell_maps). The finished sets table is then
-- put into the job's GoomSwap template (examples/<JOB>.lua) under the template's own set names; sets with no
-- place are kept as ['Sel_<path>'] so nothing is lost. Your Selindrile files are only read, never changed.
--
-- I/O comes in through `io_` (read, list, loadfile, setfenv) so the same code runs in GearSwap and in tests.

local S2G = {};

local SLOT = { main = 'Main', sub = 'Sub', range = 'Range', ranged = 'Range', ammo = 'Ammo', head = 'Head',
    neck = 'Neck', ear1 = 'Ear1', left_ear = 'Ear1', lear = 'Ear1', ear2 = 'Ear2', right_ear = 'Ear2', rear = 'Ear2',
    body = 'Body', hands = 'Hands', ring1 = 'Ring1', left_ring = 'Ring1', lring = 'Ring1', ring2 = 'Ring2',
    right_ring = 'Ring2', rring = 'Ring2', back = 'Back', waist = 'Waist', legs = 'Legs', feet = 'Feet' };
local ORDER = { 'Main', 'Sub', 'Range', 'Ammo', 'Head', 'Neck', 'Ear1', 'Ear2', 'Body', 'Hands', 'Ring1', 'Ring2',
    'Back', 'Waist', 'Legs', 'Feet' };
S2G.JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG',
    'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' };

---------------------------------------------------------------------------------------------------
-- Sandbox
---------------------------------------------------------------------------------------------------
local EMPTY = { name = 'empty' }; -- GearSwap's `empty` (slot left bare) -> GoomSwap 'remove'

local stubmt = {};
local function stub() return setmetatable({}, stubmt) end
stubmt.__index = function() return stub() end
stubmt.__call = function() return stub() end
stubmt.__concat = function(a, b) return ((type(a) == 'string') and a or '') .. ((type(b) == 'string') and b or '') end
stubmt.__add = function() return 0 end
stubmt.__sub = stubmt.__add
stubmt.__mul = stubmt.__add
stubmt.__div = stubmt.__add
stubmt.__lt = function() return false end
stubmt.__le = stubmt.__lt
stubmt.__len = function() return 0 end

local function list_methods(t)
    return setmetatable(t or {}, { __index = {
        contains = function(self, v) for _, x in pairs(self) do if x == v then return true end end return false end,
        append = function(self, v) self[#self + 1] = v; return self end,
        length = function(self) local n = 0; for _ in pairs(self) do n = n + 1 end return n end,
        find = function(self, v) for k, x in pairs(self) do if x == v then return k end end return nil end,
    } });
end
local function set_of(t) -- Windower S{}: a set, also indexable by value
    local o = {};
    for _, v in pairs(t or {}) do o[v] = true end
    return setmetatable(o, { __index = { contains = function(self, v) return rawget(self, v) == true end } });
end

-- Selindrile modes: M{['description']=..., 'a', 'b'}, M(true, 'desc'), state.X:options('a', 'b').
local modemt = {};
modemt.__index = function(self, k)
    local f = ({
        options = function(s, ...) s._opts = { ... }; s.value = s._opts[1]; return s end,
        set = function(s, v) s.value = v; return s end,
        reset = function(s) s.value = s._opts[1]; return s end,
        toggle = function(s) if (type(s.value) == 'boolean') then s.value = not s.value end return s end,
        cycle = function(s) return s end, cycleback = function(s) return s end,
        unset = function(s) s.value = false; return s end,
        contains = function(s, v) for _, x in ipairs(s._opts) do if x == v then return true end end return false end,
        current = function(s) return s.value end,
        describe = function(s) return s.description end,
    })[k];
    if (f ~= nil) then return f end
    return function() return nil end
end
local function Mode(...)
    local a1, a2 = ...;
    local o = { _opts = {}, description = '' };
    if (type(a1) == 'table') then
        for _, v in ipairs(a1) do o._opts[#o._opts + 1] = v end
        o.description = a1.description or a1['description'] or '';
        o.value = o._opts[1];
    elseif (type(a1) == 'boolean') then
        o.value, o.description = a1, a2 or '';
    else
        for _, v in ipairs({ ... }) do o._opts[#o._opts + 1] = v end
        o.value = o._opts[1];
    end
    return setmetatable(o, modemt);
end

local function autoviv()
    return setmetatable({}, { __index = function(t, k) local v = autoviv(); rawset(t, k, v); return v end });
end

local function set_combine(...)
    local o = {};
    for i = 1, select('#', ...) do
        local s = select(i, ...);
        if (type(s) == 'table') then
            for k, v in pairs(s) do
                local slot = (type(k) == 'string') and SLOT[string.lower(k)] or nil;
                if (slot ~= nil) then o[slot] = v end
            end
        end
    end
    return o;
end

local function new_env(name, job, sub, sent)
    local player = { name = name, main_job = job, sub_job = sub or 'WAR', main_job_level = 99, sub_job_level = 49,
        main_job_full = job, sub_job_full = sub or 'WAR', status = 'Idle', hpp = 100, mpp = 100, tp = 0,
        equipment = {}, buffs = {}, target = {}, merits = autoviv(), job_points = autoviv() };
    local win = stub();
    rawset(win, 'ffxi', setmetatable({ get_player = function() return player end }, stubmt));
    rawset(win, 'addon_path', '');
    local function send_command(cmd) if (type(cmd) == 'string') and (sent ~= nil) then sent[#sent + 1] = cmd end end
    rawset(win, 'send_command', send_command);
    local base = {
        pairs = pairs, ipairs = ipairs, next = next, type = type, tostring = tostring, tonumber = tonumber,
        select = select, unpack = unpack or table.unpack, pcall = pcall, error = error, assert = assert,
        setmetatable = setmetatable, getmetatable = getmetatable, rawget = rawget, rawset = rawset,
        string = string, table = table, math = math, os = { clock = os.clock, time = os.time, date = os.date },
        print = function() end,
        sets = autoviv(), set_combine = set_combine, empty = EMPTY,
        state = setmetatable({}, { __index = function(t, k) local m = Mode(); rawset(t, k, m); return m end }),
        M = setmetatable({}, { __call = function(_, ...) return Mode(...) end }),
        T = list_methods, L = list_methods, S = set_of,
        player = player, buffactive = {}, world = { area = '', day = '', weather_element = 'None', time = 0 },
        windower = win, gear = autoviv(), data = autoviv(),
        item_available = function() return true end, -- the file asked for it: assume it's owned
        send_command = send_command, -- kept: the binds become Keybinds
    };
    return setmetatable(base, { __index = function(_, k) return stub() end });
end

-- Runs one file in env; returns ok, err.
local function run_file(io_, path, env)
    local text = io_.read(path);
    if (text == nil) then return false, 'missing' end
    local fn, err = io_.loadstring(text, '@' .. path);
    if (fn == nil) then return false, tostring(err) end
    io_.setfenv(fn, env);
    local ok, e = pcall(fn);
    if not ok then return false, tostring(e) end
    return true;
end

---------------------------------------------------------------------------------------------------
-- Gear values
---------------------------------------------------------------------------------------------------
local function is_gear_table(t)
    if (type(t) ~= 'table') or (getmetatable(t) == stubmt) then return false end
    for k, _ in pairs(t) do
        if (type(k) == 'string') and (SLOT[string.lower(k)] ~= nil) then return true end
    end
    return false;
end

-- GoomSwap item: 'Name' or { name=, augments=, priority=, bag= } (GearSwap's format, matched as is on Windower).
local function item_of(v)
    if (v == EMPTY) then return 'remove' end
    if (type(v) == 'string') then return (v == 'empty') and 'remove' or v end
    if (type(v) == 'table') and (getmetatable(v) ~= stubmt) and (type(v.name or v.Name) == 'string') then
        local o = { name = v.name or v.Name };
        if (type(v.augments) == 'table') then o.augments = {}; for _, a in ipairs(v.augments) do o.augments[#o.augments + 1] = tostring(a) end
        elseif (type(v.augments) == 'string') then o.augments = { v.augments } end
        if (type(v.priority) == 'number') then o.priority = v.priority end
        if (type(v.bag) == 'string') then o.bag = v.bag end
        if (o.augments == nil) and (o.priority == nil) and (o.bag == nil) then return o.name end
        return o;
    end
    return nil; -- a value the sandbox couldn't resolve (a missing global): left out, reported
end

local function gear_of(t, bad)
    local o = {};
    for k, v in pairs(t) do
        local slot = (type(k) == 'string') and SLOT[string.lower(k)] or nil;
        if (slot ~= nil) then
            local it = item_of(v);
            if (it ~= nil) then o[slot] = it else bad[#bad + 1] = slot end
        end
    end
    return o;
end

---------------------------------------------------------------------------------------------------
-- Set paths -> GoomSwap names
---------------------------------------------------------------------------------------------------
-- Custom-handler templates: their weapon-skill set prefixes (EquipMode('<prefix>'): <prefix>_Default, <prefix>_<mode>).
local WS_PREFIX = {
    BLU = { ['Chant du Cygne'] = 'Chant', ['Savage Blade'] = 'Savage', ['Imperator'] = 'Imperator', ['Expiacion'] = 'Expiacion',
        ['Requiescat'] = 'Requiescat', ['Sanguine Blade'] = 'sanguine' },
    BRD = { ['Mordant Rime'] = 'Mordant', ['Ruthless Stroke'] = 'Ruthless', ['Savage Blade'] = 'Savage' },
    COR = { ['Savage Blade'] = 'Savage', ['Evisceration'] = 'Evisceration', ['Aeolian Edge'] = 'Aedge', ['Last Stand'] = 'Laststand',
        ['Wildfire'] = 'Wildfire', ['Hot Shot'] = 'HS', ['Leaden Salute'] = 'Leaden' },
    GEO = { ['Black Halo'] = 'BH', ['Aeolian Edge'] = 'Aedge', ['Exudation'] = 'Exudation', ['Judgment'] = 'Judgment',
        ['Shining Strike'] = 'Strike', ['Seraph Strike'] = 'Strike' },
    MNK = { ['Victory Smite'] = 'Victory', ['Shijin Spiral'] = 'Shijin', ['Dragon Kick'] = 'kickws', ['Tornado Kick'] = 'kickws',
        ['Howling Fist'] = 'Howling' },
    PLD = { ['Chant du Cygne'] = 'Chant', ['Savage Blade'] = 'Savage', ['Imperator'] = 'Imperator', ['Atonement'] = 'Atone',
        ['Sanguine Blade'] = 'sanguine', ['Knights of Round'] = 'KOR', ['Shining Blade'] = 'shining', ['Seraph Blade'] = 'shining',
        ['Shining Strike'] = 'shining', ['Aeolian Edge'] = 'Aedge' },
    RDM = { ['Chant du Cygne'] = 'Chant', ['Sanguine Blade'] = 'sanguine', ['Black Halo'] = 'BH', ['Knights of Round'] = 'KOR',
        ['Shining Blade'] = 'shining', ['Seraph Blade'] = 'shining', ['Shining Strike'] = 'shining', ['Savage Blade'] = 'Savage',
        ['Imperator'] = 'Imperator' },
    RNG = { ['Savage Blade'] = 'Savage', ['Aeolian Edge'] = 'Aedge', ['Trueflight'] = 'TrueFlight', ['Hot Shot'] = 'HS', ['Wildfire'] = 'Wildfire' },
    SCH = { ['Cataclysm'] = 'Cataclysm', ['Myrkr'] = 'Mykyr' },
    THF = { ['Savage Blade'] = 'Savage', ['Evisceration'] = 'Evis', ['Aeolian Edge'] = 'AE', ["Rudra's Storm"] = 'Rudra' },
    WHM = { ['Cataclysm'] = 'Cataclysm' },
};
-- Custom-handler templates: job ability -> set.
local JA_SET = {
    PLD = { ['Fealty'] = 'Fealty', ['Sentinel'] = 'Sentinel', ['Divine Emblem'] = 'de', ['Shield Bash'] = 'Bash', ['Invincible'] = 'Invincible',
        ['Intervene'] = 'intervene', ['Cover'] = 'Cover', ['Palisade'] = 'palisade', ['Rampart'] = 'Rampart', ['Holy Circle'] = 'circle',
        ['Chivalry'] = 'chiv' },
    MNK = { ['Focus'] = 'Focus', ['Dodge'] = 'Dodge', ['Hundred Fists'] = 'HundredFists', ['Chakra'] = 'Chakra', ['Footwork'] = 'FootworkJA',
        ['Counterstance'] = 'Counterstance', ['Formless Strikes'] = 'FormlessStrikes', ['Boost'] = 'Boost' },
    COR = { ['Wild Card'] = 'WildCard', ['Fold'] = 'Fold', ['Random Deal'] = 'RandomDeal', ['Snake Eye'] = 'SnakeEye', ['Double-Up'] = 'DoubleUp' },
    RDM = { ['Chainspell'] = 'CS', ['Saboteur'] = 'sab' },
    RNG = { ['Scavenge'] = 'Scavenge', ['Sharpshot'] = 'Sharpshot' },
    THF = { ['Flee'] = 'Flee' },
    GEO = { ['Full Circle'] = 'fc', ['Bolster'] = 'Bolster' },
    BRD = { ['Troubadour'] = 'Nitro', ['Nightingale'] = 'Nitro', ['Soul Voice'] = 'Nitro' },
    BLU = { ['Diffusion'] = 'Diffusion', ['Efflux'] = 'Efflux', ['Chain Affinity'] = 'Ca', ['Burst Affinity'] = 'Ba' },
};
-- Spell / skill / Selindrile spell_maps name -> template set names to try, first one the template has wins.
local MID_TRY = {
    ['Enhancing Magic'] = { 'Enhancing' }, ['Enfeebling Magic'] = { 'Enfeebling' }, ['Elemental Magic'] = { 'Nuke' },
    ['Healing Magic'] = { 'Cure' }, ['Cure'] = { 'Cure', 'Healing Magic' }, ['Divine Magic'] = { 'Divine' }, ['Dark Magic'] = { 'Macc' },
    ['Drain'] = { 'Drain' }, ['Aspir'] = { 'Aspir', 'Drain' }, ['Regen'] = { 'Regen', 'Regen IV' }, ['Aquaveil'] = { 'aquaveil' }, ['StatusRemoval'] = { 'erase' },
    ['Absorb-TP'] = { 'Absorb_TP' }, ['IntEnfeebles'] = { 'Int_Enfeebling' }, ['MndEnfeebles'] = { 'Mind_Enfeebling' },
    ['Blue Magic'] = { 'BluSkill' }, ['BardSong'] = { 'Buff' }, ['SongEffect'] = { 'Buff' }, ['SongDebuff'] = { 'Wind' },
    ['Foe Lullaby'] = { 'Foe' }, ['Horde Lullaby'] = { 'Horde' }, ["Sentinel's Scherzo"] = { 'Scherzo' },
    ['Honor March'] = { 'Honor' }, ['Aria of Passion'] = { 'Aria' }, ['DaurdablaDummy'] = { 'Dummy' },
};
local PRECAST_FC = { Cure = { 'Cure_Precast', 'Healing Magic_Precast' }, Curaga = { 'Cure_Precast', 'Healing Magic_Precast' },
    ['Healing Magic'] = { 'Cure_Precast', 'Healing Magic_Precast' }, ['Enhancing Magic'] = { 'Enhancing_Precast', 'Enhancing Magic_Precast' },
    Stoneskin = { 'Stoneskin_Precast' }, Utsusemi = { 'Precast_Utsusemi' }, BardSong = { 'Singing_Precast', 'Song_Precast' },
    ['Honor March'] = { 'Honor March_Precast', 'Honor_Precast' }, ['Aria of Passion'] = { 'Aria of Passion_Precast', 'Aria_Precast' },
    ['Blue Magic'] = { 'Blue Magic_Precast', 'Blu_Precast' },
    Dispelga = { 'Dispelga_Precast', 'dispelga_precast' } };
local BUFF_SET = { Impetus = 'Tp_Impetus', Footwork = 'Tp_Footwork', ['Triple Shot'] = 'TripleShot', Barrage = 'Barrage',
    ['Double Shot'] = 'DoubleShot', Sublimation = 'Sublimation', Doom = 'Doomed', Sleep = 'Sleeping',
    ['Sneak Attack'] = 'SA', ['Trick Attack'] = 'TA' };
-- Selindrile's precast sets for a family of abilities -> one set, plus one alias per ability name (ByName finds them).
local GROUPS = {
    Waltz = { set = 'Waltz', names = { 'Curing Waltz', 'Curing Waltz II', 'Curing Waltz III', 'Curing Waltz IV', 'Curing Waltz V',
        'Divine Waltz', 'Divine Waltz II' } },
    Step = { set = 'Step', names = { 'Box Step', 'Quickstep', 'Stutter Step', 'Feather Step' } },
    Flourish1 = { set = 'Flourish1', names = { 'Animated Flourish', 'Desperate Flourish', 'Violent Flourish' } },
    Flourish2 = { set = 'Flourish2', names = { 'Reverse Flourish', 'Building Flourish', 'Wild Flourish' } },
    Flourish3 = { set = 'Flourish3', names = { 'Climactic Flourish', 'Striking Flourish', 'Ternary Flourish' } },
};
local RECEIVED = { Cure_Received = true, Cursna_Received = true, Phalanx_Received = true, Protect_Shell_Received = true,
    Regen_Received = true, Refresh_Received = true, Waltz_Received = true };

local function mapper(ctx)
    local function has(n) return ctx.tset[string.lower(n)] ~= nil end
    local function first(list) for _, n in ipairs(list or {}) do if has(n) then return n end end return nil end
    local job, generic, modes = ctx.job, ctx.generic, ctx.modes;
    return function(k)
        local n, a, b, c, d = #k, k[1], k[2], k[3], k[4];
        if (n == 1) then
            if (a == 'idle') then return 'Idle' end
            if (a == 'resting') then return 'Resting' end
            if (a == 'Kiting') then return 'Movement' end
            if (a == 'TreasureHunter') then return 'TH' end
            if (a == 'Enmity') then return 'Enmity' end
            if (a == 'engaged') then return 'Tp_Default' end
            if (a == 'MagicBurst') then return 'Burst' end
            if (a == 'Self_Healing') then return has('Self_Cure') and 'Self_Cure' or 'Cure_Self' end
            if (a == 'Self_Refresh') then return has('Self_Refresh') and 'Self_Refresh' or 'Refresh_Self' end
            if RECEIVED[a] then return a end
            return nil;
        end
        if (a == 'idle') and (n == 2) then
            return ({ Refresh = 'Idle_Refresh', Regen = 'Idle_Regen', Regain = 'Idle_Regain', Town = 'Town', Pet = 'Idle_Pet' })[b];
        end
        if (a == 'engaged') and (n == 2) and modes[b] then return 'Tp_' .. b end
        if (a == 'engaged') and (n == 2) and ctx.hybrid[b] and has('Tank_Main') then -- PLD/RUN: HybridMode tank sets -> /tankset
            if (b == 'MEVA') then return first({ 'Tank_MEVA' }) end
            if (b == ctx.tankMain) then return 'Tank_Main' end
            return nil;
        end
        if (a == 'defense') and (n == 2) then
            if (b == 'PDT') then return 'Dt' end
            if (b == 'MDT') or (b == 'MEVA') then return 'mdt' end -- /mdt reads it on any job; MDT first (paths sort alphabetically)
            return nil;
        end
        if (a == 'buff') and (n == 2) then return BUFF_SET[b] end
        if (a == 'weapons') and (n == 2) then return 'Weapon_' .. b end
        if (a == 'precast') then
            if (b == 'FC') and (n == 2) then return 'Precast' end
            if (b == 'FC') and (n == 3) then return first(PRECAST_FC[c]) end
            if (b == 'RA') and (n == 2) then return 'Preshot' end
            if (b == 'RA') and (n == 3) then return first(({ Flurry = { 'Preshot_FlurryI' }, Flurry2 = { 'Preshot_FlurryII' } })[c]) end
            if (n == 2) and (GROUPS[b] ~= nil) then return GROUPS[b].set end
            if (n == 3) and (GROUPS[b] ~= nil) and (b ~= 'FC') then return c end -- precast.Waltz['Healing Waltz']: by name
            if (b == 'CorsairRoll') and (n == 2) then return first({ 'Phantom Roll', 'Rolls' }) end
            if (b == 'CorsairShot') and (n == 2) then return first({ 'Quick Draw', 'QD' }) end
            if (b == 'JA') and (n == 3) then
                if has(c) then return c end -- the template's set named after the ability
                local m = JA_SET[job] and JA_SET[job][c];
                if (m ~= nil) and has(m) then return m end
                if generic or has(c) then return c end
                return nil;
            end
            if (b == 'WS') and (n == 2) then return 'Ws_Default' end
            if (b == 'WS') and (n == 3) and modes[c] then return 'Ws_' .. c end
            if (b == 'WS') and (n == 3) and ((c == 'SA') or (c == 'TA') or (c == 'SATA')) then return first({ 'Ws_Default_' .. c }) end
            if (b == 'WS') and (n >= 3) then
                local mode = (n == 4) and d or nil;
                if (n == 4) and (not modes[d]) and not ((d == 'SA') or (d == 'TA') or (d == 'SATA')) then return nil end
                if (n > 4) then return nil end
                local p = WS_PREFIX[job] and WS_PREFIX[job][c];
                if (p ~= nil) then
                    local nm;
                    if (mode == nil) then nm = p .. '_Default'
                    elseif modes[mode] then nm = p .. '_' .. mode
                    else nm = p .. '_Default_' .. mode end
                    if has(nm) then return nm end -- older templates: <prefix>_Default; named ones fall through
                end
                if generic or has(c) then return (mode == nil) and c or (c .. '_' .. mode) end
                return nil;
            end
            return nil;
        end
        if (a == 'midcast') then
            if (b == 'FastRecast') and (n == 2) then return first({ 'Midcast' }) end
            if (b == 'RA') and (n == 2) then return 'Midshot' end
            if (b == 'RA') and (n == 3) and (c == 'Acc') then return first({ 'Midshot_Acc' }) end
            if (n == 2) then
                if has(b) then return b end
                local m = first(MID_TRY[b]);
                if (m ~= nil) then return m end
                if generic then return b end
                return nil;
            end
            if (n == 3) and (c == 'OccultAcumen') and (b == 'Elemental Magic') and has('OccultAcumen') then return 'OccultAcumen' end -- /nukeset oa
            if (n == 3) and (c == 'Resistant') then
                for _, base in ipairs({ b, unpack(MID_TRY[b] or {}) }) do -- ['Elemental Magic'] or Nuke -> NukeACC
                    if has(base .. 'ACC') then return base .. 'ACC' end
                end
                return nil;
            end
            return nil;
        end
        return nil;
    end
end

---------------------------------------------------------------------------------------------------
-- Template (examples/<JOB>.lua) parsing: the `local sets = {...}` block and its top-level keys
---------------------------------------------------------------------------------------------------
local function scan_block(text, start)
    -- From the '{' at `start`: returns the index of its matching '}' and the depth-1 keys in order.
    local i, depth, keys, n = start, 0, {}, #text;
    while (i <= n) do
        local ch = string.sub(text, i, i);
        local two = string.sub(text, i, i + 1);
        if (two == '--') then
            local long = string.match(text, '^%-%-%[(=*)%[', i);
            if (long ~= nil) then
                local close = string.find(text, ']' .. long .. ']', i, true);
                i = (close or n) + #long + 2;
            else
                local nl = string.find(text, '\n', i, true);
                i = (nl or n) + 1;
            end
        elseif (ch == "'") or (ch == '"') then
            local j = i + 1;
            while (j <= n) do
                local c = string.sub(text, j, j);
                if (c == '\\') then j = j + 2 elseif (c == ch) then break else j = j + 1 end
            end
            i = j + 1;
        elseif (string.match(text, '^%[=*%[', i) ~= nil) then
            local eq = string.match(text, '^%[(=*)%[', i);
            local close = string.find(text, ']' .. eq .. ']', i, true);
            i = (close or n) + #eq + 2;
        elseif (ch == '{') then
            depth = depth + 1;
            if (depth == 2) then
                -- the key right before this '{' at depth 1: Name = { or ['Name'] = {
                local before = string.sub(text, math.max(1, i - 200), i - 1);
                local key = string.match(before, "%[%s*'([^']+)'%s*%]%s*=%s*$") or string.match(before, '%[%s*"([^"]+)"%s*%]%s*=%s*$')
                    or string.match(before, '([%a_][%w_]*)%s*=%s*$');
                if (key ~= nil) then keys[#keys + 1] = key end
            end
            i = i + 1;
        elseif (ch == '}') then
            depth = depth - 1;
            if (depth == 0) then return i, keys end
            i = i + 1;
        else
            i = i + 1;
        end
    end
    return nil, keys;
end

---------------------------------------------------------------------------------------------------
-- Output
---------------------------------------------------------------------------------------------------
local function q(s) return string.format('%q', s) end
local function key_of(name)
    if string.match(name, '^[%a_][%w_]*$') then return name end
    return '[' .. q(name) .. ']';
end
local function item_code(v)
    if (type(v) == 'string') then return q(v) end
    local parts = { 'name = ' .. q(v.name) };
    if (v.augments ~= nil) then
        local a = {};
        for _, s in ipairs(v.augments) do a[#a + 1] = q(s) end
        parts[#parts + 1] = 'augments = { ' .. table.concat(a, ', ') .. ' }';
    end
    if (v.priority ~= nil) then parts[#parts + 1] = 'priority = ' .. tostring(v.priority) end
    if (v.bag ~= nil) then parts[#parts + 1] = 'bag = ' .. q(v.bag) end
    return '{ ' .. table.concat(parts, ', ') .. ' }';
end
local function set_code(name, gear, indent)
    local lines = { indent .. key_of(name) .. ' = {' };
    for _, slot in ipairs(ORDER) do
        if (gear[slot] ~= nil) then lines[#lines + 1] = indent .. '    ' .. slot .. ' = ' .. item_code(gear[slot]) .. ',' end
    end
    lines[#lines + 1] = indent .. '},';
    return table.concat(lines, '\n');
end
local function path_name(k)
    local out = {};
    for _, p in ipairs(k) do out[#out + 1] = tostring(p) end
    return table.concat(out, '.');
end
local function lua_list(t)
    local o = {};
    for _, v in ipairs(t) do o[#o + 1] = q(v) end
    return '{' .. table.concat(o, ', ') .. '}';
end

---------------------------------------------------------------------------------------------------
-- Convert one gear file
---------------------------------------------------------------------------------------------------
-- opts: io_ { read(path)->text|nil, loadstring, setfenv }, name, job, sub, gear_file, pre_files (list, loaded first,
-- missing ones skipped), mappings_file, template_text, source_label
-- Selindrile binds -> GoomSwap Keybinds. GoomSwap's own keys (keep in step with Keybinds in common/gcinclude.lua):
local GOOM_KEYS = { f7 = 'wm', ['+f7'] = 'wm default', f9 = 'mmode', ['^f9'] = 'tankset', ['+f9'] = 'rangedset',
    ['!f9'] = 'wsset', f10 = 'def', ['!f10'] = 'kite', ['@f10'] = 'hoxne', ['+f11'] = 'nukeset', ['!f11'] = 'burst',
    ['+f12'] = 'idleset', ['!f12'] = 'def off', ['!@^f12'] = '/lac reload' };
-- 'gs c <words>' -> GoomSwap command; a table = per job (others: no GoomSwap match there).
local SEL_CMD = {
    ['cycle weapons'] = 'wm', ['weapons default'] = 'wm default', ['cycle offensemode'] = 'mmode',
    ['cycle weaponskillmode'] = 'wsset', ['toggle kiting'] = 'kite', ['cycle idlemode'] = 'idleset',
    ['toggle capacity'] = 'capacity', ['cycle treasuremode'] = 'th',
    ['cycle hybridmode'] = { PLD = 'tankset', RUN = 'tankset' },
    ['cycle rangedmode'] = { COR = 'rangedset', RNG = 'rangedset', PLD = 'rangedset' },
    ['cycle castingmode'] = { BLM = 'nukeset', RDM = 'nukeset', SCH = 'nukeset', GEO = 'nukeset', WHM = 'nukeset', DRK = 'nukeset' },
    ['cycle magicburstmode'] = { BLM = 'burst', RDM = 'burst', SCH = 'burst', GEO = 'burst' },
    ['cycle elementalmode'] = { BLM = 'elecycle', SCH = 'elecycle' },
};
-- Selindrile's defense keys: GoomSwap has one /def cycle (F10) and /def off (Alt+F12) instead.
local SEL_DEFENSE = { ['set defensemode'] = true, ['reset defensemode'] = true, ['cycle physicaldefensemode'] = true,
    ['cycle magicaldefensemode'] = true, ['cycle resistdefensemode'] = true };
-- '~^f9' -> '^+f9' (GoomSwap writes Shift as +; the Windower side turns it back into ~), modifiers sorted to compare.
local function goom_key(k)
    local mods, name = string.match(k, '^([%^!@#~%+%%%$]*)(.+)$');
    if (name == nil) then return k, k end
    mods = string.gsub(mods, '~', '+');
    local m = {};
    for c in string.gmatch(mods, '.') do m[#m + 1] = c end
    table.sort(m);
    local norm = table.concat(m) .. string.lower(name);
    return mods .. name, norm;
end
-- One bind's command: kind 'key' (GoomSwap command or chat command), 'covered', or 'drop' (with why).
local function bind_command(rest, job, sird)
    local got, why = {}, nil;
    for part in string.gmatch(rest, '[^;]+') do
        part = string.match(part, '^%s*(.-)%s*$');
        local lp = string.lower(part);
        if (part == '') or string.match(lp, '^gs c update') then
            -- Selindrile's own refresh: GoomSwap re-checks gear by itself
        elseif string.match(lp, '^input%s+/') then
            got[#got + 1] = string.match(part, '^%S+%s+(.*)$');
        elseif (lp == 'gs reload') then
            got[#got + 1] = '/lac reload';
        elseif string.match(lp, '^gs c ') then
            local words = {};
            for w in string.gmatch(string.sub(lp, 6), '%S+') do words[#words + 1] = w end
            local two = (words[1] or '') .. ' ' .. (words[2] or '');
            local m = SEL_CMD[two];
            if (type(m) == 'table') then m = m[job] end
            if (m == nil) and (two == 'cycle castingmode') and sird then m = 'sir' end -- CastingMode Normal/SIRD -> /sir
            if (m == nil) and (words[1] == 'weapons') and (words[2] ~= nil) then -- a weapon set by name -> /wm <name>
                m = 'wm ' .. string.match(part, '^%S+%s+%S+%s+%S+%s+(.*)$');
            end
            if SEL_DEFENSE[two] then return 'covered' end
            if (m == nil) then return 'drop', 'no GoomSwap match' end
            got[#got + 1] = m;
        else
            return 'drop', 'console command';
        end
    end
    if (#got == 0) then return 'drop', 'nothing to run' end
    if (#got > 1) then return 'drop', 'several commands' end
    return 'key', got[1];
end
-- The captured send_command calls -> { added = {{key, cmd}...}, covered = n, dropped = {'key: cmd (why)'...} }.
local function convert_binds(sent, job, sird)
    local order, byKey = {}, {};
    for _, line in ipairs(sent) do -- in order: Globals first, then the gear file (later binds and unbinds win)
        local key, rest = string.match(line, '^%s*bind%s+(%S+)%s+(.-)%s*$');
        local ukey = string.match(string.lower(line), '^%s*unbind%s+(%S+)');
        if (key ~= nil) then
            local gk, norm = goom_key(key);
            if (byKey[norm] == nil) then order[#order + 1] = norm end
            byKey[norm] = { key = gk, raw = key, rest = rest };
        elseif (ukey ~= nil) then
            local _, norm = goom_key(ukey);
            byKey[norm] = nil;
        end
    end
    local res = { added = {}, covered = 0, same = 0, dropped = {} };
    for _, norm in ipairs(order) do
        local b = byKey[norm];
        if (b ~= nil) then
            local kind, v = bind_command(b.rest, job, sird);
            if (kind == 'covered') then res.covered = res.covered + 1
            elseif (kind == 'drop') then res.dropped[#res.dropped + 1] = b.raw .. ': ' .. b.rest .. ' (' .. v .. ')'
            elseif (GOOM_KEYS[norm] == v) then res.same = res.same + 1
            else res.added[#res.added + 1] = { b.key, v } end
        end
    end
    return res;
end

function S2G.Convert(opts)
    local io_ = opts.io_;
    local sent = {};
    local env = new_env(opts.name, opts.job, opts.sub, sent);
    local report = { loaded = {}, failed = {}, unmapped = {}, unresolved = {}, mapped = 0, notes = {} };
    if (opts.mappings_file ~= nil) then
        local ok = run_file(io_, opts.mappings_file, env);
        if ok then report.loaded[#report.loaded + 1] = 'Sel-Mappings' end
    end
    for _, f in ipairs(opts.pre_files or {}) do
        local ok, err = run_file(io_, f, env);
        if ok then report.loaded[#report.loaded + 1] = f elseif (err ~= 'missing') then report.failed[#report.failed + 1] = f .. ': ' .. err end
    end
    local ok, err = run_file(io_, opts.gear_file, env);
    if not ok then return nil, 'cannot run ' .. opts.gear_file .. ': ' .. tostring(err) end
    for _, fname in ipairs({ 'user_job_setup', 'user_setup', 'character_user_job_setup' }) do
        local f = rawget(env, fname);
        if (type(f) == 'function') then
            local okf, e = pcall(f);
            if not okf then report.failed[#report.failed + 1] = fname .. '(): ' .. tostring(e) end
        end
    end
    local init = rawget(env, 'init_gear_sets');
    if (type(init) ~= 'function') then return nil, opts.gear_file .. ' has no init_gear_sets()' end
    local oki, e = pcall(init);
    if not oki then return nil, 'init_gear_sets() failed: ' .. tostring(e) end

    -- modes
    local st = rawget(env, 'state');
    local function opts_of(nm) local m = rawget(st, nm); return (type(m) == 'table') and m._opts or {} end
    local weapons = {};
    for _, w in ipairs(opts_of('Weapons')) do if (type(w) == 'string') and (w ~= 'None') then weapons[#weapons + 1] = w end end
    local melee, modes = { 'Default' }, {};
    for _, m in ipairs(opts_of('OffenseMode')) do
        if (type(m) == 'string') and (m ~= 'Normal') then melee[#melee + 1] = m; modes[m] = true end
    end
    for _, m in ipairs(opts_of('WeaponskillMode')) do
        if (type(m) == 'string') and (m ~= 'Normal') and (m ~= 'Match') and not modes[m] then report.notes[#report.notes + 1] = 'WS mode ' .. m .. ' (no /mmode of that name: its WS sets are kept as Sel_*)' end
    end

    -- template
    local tt = opts.template_text;
    local s1 = string.find(tt, 'local sets = {', 1, true);
    if (s1 == nil) then return nil, 'template has no `local sets = {`' end
    local brace = s1 + #'local sets = ' ;
    local close, tkeys = scan_block(tt, brace);
    if (close == nil) then return nil, 'template sets block not closed' end
    local tset = {};
    for _, k in ipairs(tkeys) do tset[string.lower(k)] = k end
    local generic = (string.find(tt, 'ByName(', 1, true) ~= nil);

    -- walk Selindrile sets
    local hybrid, tankMain = {}, nil;
    for _, m in ipairs(opts_of('HybridMode')) do
        if (type(m) == 'string') and (m ~= 'Normal') then
            hybrid[m] = true;
            if (tankMain == nil) and (m ~= 'MEVA') then tankMain = m end
        end
    end
    local map = mapper({ job = opts.job, generic = generic, modes = modes, tset = tset, hybrid = hybrid, tankMain = tankMain });
    local found = {};
    local onPath = {};
    local function walk(t, path)
        onPath[t] = true; -- sets.X.Acc = sets.X would otherwise nest forever (X.Acc.Acc...)
        if is_gear_table(t) then found[#found + 1] = { path = path, set = t } end
        local subs = {};
        for k, v in pairs(t) do
            if (type(v) == 'table') and (getmetatable(v) ~= stubmt) and (v ~= EMPTY)
                and not ((type(k) == 'string') and (SLOT[string.lower(k)] ~= nil)) and (type(k) == 'string') then
                subs[#subs + 1] = k;
            end
        end
        table.sort(subs);
        for _, k in ipairs(subs) do
            local p = {};
            for i, x in ipairs(path) do p[i] = x end
            p[#p + 1] = k;
            if (#p <= 6) and not onPath[t[k]] then walk(t[k], p) end
        end
        onPath[t] = nil;
    end
    walk(rawget(env, 'sets'), {});
    -- shorter paths first, so sets.midcast.Cure wins over sets.midcast['Healing Magic'] only by order of definition
    table.sort(found, function(x, y)
        if (#x.path ~= #y.path) then return #x.path < #y.path end
        return path_name(x.path) < path_name(y.path);
    end);

    local out, outOrder, extra = {}, {}, {};
    local byName = {}; -- kinds of by-name sets a custom-handler template needs a lookup for: ws, ja, mid
    local placedTable = {}; -- a table already placed or kept: its other names (aliases) aren't repeated as Sel_*
    for _, f in ipairs(found) do
        local bad = {};
        local gear = gear_of(f.set, bad);
        if (#bad > 0) then report.unresolved[#report.unresolved + 1] = path_name(f.path) .. ' (' .. table.concat(bad, ', ') .. ')' end
        local name = map(f.path);
        if (name ~= nil) then
            local tkey = tset[string.lower(name)] or name;
            if (out[string.lower(tkey)] == nil) then
                placedTable[f.set] = true;
                out[string.lower(tkey)] = { name = tkey, gear = gear, from = path_name(f.path) };
                report.mapped = report.mapped + 1;
                if (tset[string.lower(tkey)] == nil) then extra[#extra + 1] = string.lower(tkey) end
            else
                name = nil; -- taken by an earlier path
            end
        end
        if (name == nil) and (next(gear) ~= nil) and not placedTable[f.set] then
            -- weapon skills, abilities and spells the template has no free set for keep their own name; a
            -- custom-handler template's handlers get a by-name lookup (below) so they are used
            local k, kind = f.path, nil;
            local nk = #k;
            if (nk == 2) and (k[1] == 'midcast') and (k[2] ~= 'FastRecast') and (k[2] ~= 'RA') then name, kind = k[2], 'mid'
            elseif (nk == 3) and (k[1] == 'precast') and (k[2] == 'JA') then name, kind = k[3], 'ja'
            elseif (nk == 3) and (k[1] == 'precast') and (k[2] == 'WS') and not modes[k[3]] then name, kind = k[3], 'ws'
            elseif (nk == 4) and (k[1] == 'precast') and (k[2] == 'WS') and modes[k[4]] then name, kind = k[3] .. '_' .. k[4], 'ws' end
            if (name ~= nil) and (out[string.lower(name)] == nil) and (tset[string.lower(name)] == nil) then
                placedTable[f.set] = true;
                out[string.lower(name)] = { name = name, gear = gear, from = path_name(f.path) };
                extra[#extra + 1] = string.lower(name);
                report.mapped = report.mapped + 1;
                byName[kind] = true;
            else
                name = nil;
            end
        end
        if (name == nil) and (next(gear) ~= nil) and not placedTable[f.set] then
            placedTable[f.set] = true;
            report.unmapped[#report.unmapped + 1] = { name = 'Sel_' .. path_name(f.path), gear = gear };
        end
    end
    -- ability-family aliases (Curing Waltz III -> Waltz) where the template has no set of that family
    local groupAliases = {};
    for _, g in pairs(GROUPS) do
        local src = out[string.lower(g.set)];
        if (src ~= nil) and (tset[string.lower(g.set)] == nil) then
            for _, nm in ipairs(g.names) do
                if (out[string.lower(nm)] == nil) and (tset[string.lower(nm)] == nil) then
                    groupAliases[#groupAliases + 1] = 'sets[' .. q(nm) .. '] = sets[' .. q(src.name) .. '];';
                end
            end
            byName.ja = true;
        end
    end
    table.sort(groupAliases);

    -- build the sets block
    local lines = { 'local sets = {' };
    for _, k in ipairs(tkeys) do
        local lk = string.lower(k);
        if string.match(k, '^Weapon_') and (out[lk] == nil) then
            -- the template's example weapons: yours are the Weapon_<mode> sets below
        elseif (out[lk] ~= nil) then
            lines[#lines + 1] = '    -- from sets.' .. out[lk].from;
            lines[#lines + 1] = set_code(k, out[lk].gear, '    ');
        else
            lines[#lines + 1] = '    ' .. key_of(k) .. ' = {},';
        end
    end
    if (#extra > 0) then
        lines[#lines + 1] = '';
        lines[#lines + 1] = '    -- Your sets the template has no line for (weapon modes, /mmode variants, action names):';
        for _, lk in ipairs(extra) do
            lines[#lines + 1] = '    -- from sets.' .. out[lk].from;
            lines[#lines + 1] = set_code(out[lk].name, out[lk].gear, '    ');
        end
    end
    if (#report.unmapped > 0) then
        lines[#lines + 1] = '';
        lines[#lines + 1] = '    -- Selindrile sets with no GoomSwap place. Not used as they are: rename one (or copy its lines) to use it.';
        for _, u in ipairs(report.unmapped) do lines[#lines + 1] = set_code(u.name, u.gear, '    ') end
    end
    lines[#lines + 1] = '}';
    local body = string.sub(tt, 1, s1 - 1) .. table.concat(lines, '\n') .. string.sub(tt, close + 1);

    -- OnLoad: weapon modes, melee modes
    local wm = { 'None' };
    for _, w in ipairs(weapons) do if (out['weapon_' .. string.lower(w)] ~= nil) then wm[#wm + 1] = w end end
    local function sub_line(pattern, repl)
        local nbody, n = string.gsub(body, pattern, repl);
        body = nbody;
        return n;
    end
    local wmLine = 'gcinclude.WeaponModes = ' .. lua_list(wm) .. '; -- from your Selindrile state.Weapons';
    local defLine = "gcinclude.DefaultWeapons = " .. q(wm[2] or 'None') .. ';';
    if (sub_line('gcinclude%.WeaponModes%s*=%s*%b{}%s*;?[^\n]*', wmLine) == 0) then
        sub_line('(\n%s*)gcinclude%.Initialize%(%);', '%1' .. wmLine .. '%1gcinclude.Initialize();');
    end
    if (sub_line('gcinclude%.DefaultWeapons%s*=%s*%b{}%s*;?[^\n]*', defLine) == 0) then
        if (sub_line("gcinclude%.DefaultWeapons%s*=%s*'[^']*'%s*;?[^\n]*", defLine) == 0) then
            sub_line('(\n%s*)gcinclude%.Initialize%(%);', '%1' .. defLine .. '%1gcinclude.Initialize();');
        end
    end
    for _, cname in ipairs({ 'MainModes', 'SubModes', 'RangeModes', 'AmmoModes' }) do
        sub_line('(\n%s*)(gcinclude%.' .. cname .. '%s*=)', '%1-- (template slot picks, its example weapons) %2');
    end
    if (#melee > 1) then
        sub_line('(\n%s*)gcinclude%.Initialize%(%);', '%1gcinclude.MeleeModes = ' .. lua_list(melee) .. '; -- /mmode, from your OffenseMode%1gcinclude.Initialize();');
    end
    local sird = false;
    for _, m in ipairs(opts_of('CastingMode')) do if (m == 'SIRD') then sird = true end end
    local keys = convert_binds(sent, opts.job, sird);
    report.keys = keys;
    if (#keys.added > 0) then
        local kl = { '%1for _, b in ipairs({ -- your Selindrile keys (goomswap_migrate), added to GoomSwap\'s; README Keys' };
        for _, b in ipairs(keys.added) do
            kl[#kl + 1] = '%1    { ' .. string.gsub(q(b[1]), '%%', '%%%%') .. ', ' .. string.gsub(q(b[2]), '%%', '%%%%') .. ' },';
        end
        kl[#kl + 1] = '%1}) do table.insert(gcinclude.settings.Keybinds, b) end';
        sub_line('(\n%s*)gcinclude%.Initialize%(%);', table.concat(kl) .. '%1gcinclude.Initialize();');
    end

    -- Generic (by-name) templates: a Selindrile spell_maps group (StatusRemoval, BarElement...) becomes one set
    -- per spell, sharing that group's gear, where GoomSwap's spell family name differs from the group's.
    local aliases = {};
    local smaps = rawget(env, 'spell_maps');
    if (generic or byName.mid) and (type(smaps) == 'table') and (getmetatable(smaps) ~= stubmt) then
        local spells = {};
        for sp, grp in pairs(smaps) do if (type(sp) == 'string') and (type(grp) == 'string') then spells[#spells + 1] = sp end end
        table.sort(spells);
        for _, sp in ipairs(spells) do
            local grp = smaps[sp];
            local fam = string.gsub(string.match(sp, '^(.-):') or sp, ' [IVX]+$', '');
            local src = out[string.lower(grp)];
            if (src ~= nil) and (string.lower(fam) ~= string.lower(grp)) and (string.lower(sp) ~= string.lower(grp))
                and (out[string.lower(sp)] == nil) and (out[string.lower(fam)] == nil) and (tset[string.lower(sp)] == nil) then
                aliases[#aliases + 1] = 'sets[' .. q(sp) .. '] = sets[' .. q(src.name) .. ']; -- Selindrile group ' .. grp;
            end
        end
        if (#aliases > 0) then
            sub_line('\n(profile%.Sets%s*=%s*sets%s*;)', '\n' .. table.concat(aliases, '\n') .. '\n%1');
        end
    end

    if (#groupAliases > 0) then
        sub_line('\n(profile%.Sets%s*=%s*sets%s*;)', '\n' .. table.concat(groupAliases, '\n') .. '\n%1');
    end
    -- custom-handler templates: look the by-name sets up (weapon skill / ability / spell name), under the template's own
    local function inject(handler, find, add, before)
        local a1 = string.find(body, 'profile.' .. handler .. ' = function()', 1, true);
        if (a1 == nil) then return false end
        local e1 = string.find(body, '\nend', a1, true) or #body;
        local seg = string.sub(body, a1, e1);
        local at = string.find(seg, find, 1, true);
        if (at == nil) then return false end
        local ind = string.match(string.sub(seg, 1, at - 1), '\n([ \t]*)$') or '    ';
        local newseg;
        if before then newseg = string.sub(seg, 1, at - 1) .. add .. '\n' .. ind .. string.sub(seg, at)
        else newseg = string.sub(seg, 1, at + #find - 1) .. '\n' .. ind .. add .. string.sub(seg, at + #find) end
        body = string.sub(body, 1, a1 - 1) .. newseg .. string.sub(body, e1 + 1);
        return true;
    end
    if not generic then
        if byName.ws then inject('HandleWeaponskill', "gcinclude.EquipMode('Ws');", 'gcinclude.ByName(ws.Name); -- migrated: a weapon skill\'s own set (from Selindrile)', false) end
        if byName.ja then inject('HandleAbility', 'gcinclude.CheckCancels();', 'gcinclude.ByName(gData.GetAction().Name); -- migrated: an ability\'s own set (from Selindrile)', true) end
        if byName.mid then
            inject('HandleMidcast', 'local spell = gData.GetAction();',
                'gcinclude.ByName(spell.Skill); if not gcinclude.ByName(spell.Name) then gcinclude.ByName(gcinclude.Family(spell.Name)) end -- migrated: Selindrile sets by skill/spell, under the sets below', false);
        end
    end

    -- header
    for slot, item in string.gmatch(string.sub(tt, close + 1), "gFunc%.Equip%('(%a+)',[^\n]-'([^']+)'%)") do
        local li = string.lower(item);
        if (li ~= 'ignore') and (li ~= 'remove') and (li ~= 'displaced') then
            report.notes[#report.notes + 1] = 'The template code itself puts ' .. item .. ' in ' .. slot .. ': search for it and change it if you use something else.';
        end
    end
    local h = {
        '-- Migrated from Selindrile: ' .. (opts.source_label or opts.gear_file),
        '-- Template: GoomSwap examples/' .. opts.job .. '.lua (its handlers; your gear). Weapon modes (/wm): ' .. table.concat(wm, ', ') .. '.',
        '-- ' .. report.mapped .. ' sets placed; ' .. #report.unmapped .. ' kept as Sel_* (no GoomSwap place yet). Template sets you had nothing for are {}.',
        '-- Keys: ' .. #keys.added .. ' of your binds added in OnLoad; ' .. (keys.same + keys.covered) .. ' already on GoomSwap\'s keys (its F-key layout, /def); '
            .. #keys.dropped .. ' left out' .. ((#keys.dropped > 0) and ':' or '.'),
    };
    for i = 1, math.min(#keys.dropped, 40) do h[#h + 1] = '--   ' .. keys.dropped[i] end
    if (#keys.dropped > 40) then h[#h + 1] = '--   ... and ' .. (#keys.dropped - 40) .. ' more' end
    h[#h + 1] = '-- Not carried over: Selindrile automation (AutoDefense, AutoRune, AutoTank, AutoWS...), Day/Night idles.';
    for _, nt in ipairs(report.notes) do h[#h + 1] = '-- ' .. nt end
    if (#report.unresolved > 0) then
        h[#h + 1] = '-- Slots left out (a value the migration could not read, e.g. a global from your own code):';
        for i = 1, math.min(#report.unresolved, 20) do h[#h + 1] = '--   ' .. report.unresolved[i] end
    end
    body = table.concat(h, '\n') .. '\n' .. body;
    return body, report;
end

return S2G;
