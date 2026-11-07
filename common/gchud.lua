local gchud = {};

local imgui = require('imgui');

local inc = nil;
local disp = nil;
local nextWrite = 0;
local nextRead = 0;
local lastLine = nil;
local lastWriteTime = 0;
local rows = {};
local visible = false;
local expanded = {};
local placed = false;


local STALE = 15;

gchud.CycleCommands = {
    MeleeSet = 'mmode',
    WsSet = 'wsset',
    Weapons = 'wm',
    Main = 'mainset',
    Sub = 'subset',
    Range = 'rangeset',
    Ammo = 'ammoset',
    Weapon = 'weapon',
    NukeSet = 'nukeset',
    Element = 'elecycle',
    TankSet = 'tankset',
    Hoxne = 'hoxne',
    PupMode = 'pupmode',
    IdleSet = 'idleset',
    RangedSet = 'rangedset',
};

gchud.ToggleCommands = {
    DTset = 'dt',
    MDTset = 'mdt',
    Aminon = 'aminon',
    TH = 'th',
    Kite = 'kite',
    SIR = 'sir',
    PROC = 'proc',
    Burst = 'burst',
    String = 'forcestring',
    SongLock = 'songlock',
    Death = 'death',
};

gchud.CycleOrder = { 'Weapons', 'Main', 'Sub', 'Range', 'Ammo', 'MeleeSet', 'WsSet', 'RangedSet', 'IdleSet' }; -- slot picks right after wpn
gchud.ToggleOrder = { 'DTset', 'MDTset', 'Aminon', 'SIR', 'TH', 'Kite' };

-- Column header glyphs. Override any with settings.HUDLabels = { Main = 'mn' }.
local SHORT = {
    DTset = 'dt', MDTset = 'md', Aminon = 'am', -- in the def cell
    SIR = 'si', TH = 'th', Kite = 'kt', PROC = 'pr', -- toggles: no columns (name colour or chat), detail line
    Burst = 'bs', String = 'hp', SongLock = 'sl', Death = 'dh',
    Def = 'def',
    Weapons = 'wpn', MeleeSet = 'melee', WsSet = 'buff', Main = 'main', Sub = 'sub', Range = 'rng', Ammo = 'ammo',
    NukeSet = 'nuke', Element = 'elem', TankSet = 'tank', Hoxne = 'hx', PupMode = 'pup', Weapon = 'w',
    IdleSet = 'idle', RangedSet = 'ra',
};

-- Full names, hover tooltips only.
local FULL = {
    DTset = 'DT set', MDTset = 'MDT set', Aminon = 'Aminon', SIR = 'Spell interrupt', TH = 'Treasure Hunter',
    Kite = 'Kite', PROC = 'Proc',
    Burst = 'Burst set on every nuke (/burst): * after the nuke value', String = 'Harp (force string)', SongLock = 'Song lock (enemy songs keep main/sub)',
    Death = 'Death', Weapons = 'Weapon set', WsSet = 'WS buff level (/wsset): High wears <WS set>_HighBuff',
    Def = 'Defense (click = /def: DT > MDT > Aminon > none)',
    MeleeSet = 'Melee set', Main = 'Main', Sub = 'Sub',
    Range = 'Range', Ammo = 'Ammo', NukeSet = 'Nuke set', Element = 'Element', TankSet = 'Tank set',
    Hoxne = 'Hoxne', PupMode = 'Pup mode', Weapon = 'Weapon',
    IdleSet = 'Idle set (click = /idleset: Default > Refresh > Regen > Regain; compact: MP HP TP)',
    RangedSet = 'Ranged accuracy (click = /rangedset: Default > Acc)',
};

-- Modes whose Default draws as '-' (nothing laid over), and their compact-style values.
local DASH_DEFAULT = { IdleSet = true, RangedSet = true };
local SHORT_VALUE = { IdleSet = { Refresh = 'MP', Regen = 'HP', Regain = 'TP' } };

-- Cycle values drawn as '-'. A cycle column empty on every box is hidden from the grid.
local EMPTY = { none = true, off = true, unknown = true };

-- Short value (compact styles): the full value if it is no wider than FIT_TEXT (the widest def cell, so the column
-- doesn't widen); else a short form players use (DP, Max, GH, KC); else the first word, whole if it fits, else its
-- first 4 letters. '+N' and one-letter words (paths) are kept: 'Anarchy +2' -> Anar+2, 'RostamB' -> RostB. Two of
-- this box's choices that would match get longer forms (check_abbr): 'ProcStaff' / 'ProcSword' -> ProcSta / ProcSwo.
-- Override any with settings.HUDAbbr = { ['Carnwenhan'] = 'Carn' } (case-insensitive).
local FIT_TEXT = 'Amin+';
local SHORT_FORM = { deathpenalty = 'DP', maxentius = 'Max', godhands = 'GH', krakenclub = 'KC' }; -- leading words, letters only, lower case
local abbrCache, abbrLevel = {}, {}; -- level: 0 short, 1 + later words' initials, 2 + their first 3 letters, 3 full name
local function user_abbr(value)
    local user = inc.settings.HUDAbbr;
    if (type(user) ~= 'table') then return nil end
    local lv = string.lower(value);
    for k, v in pairs(user) do
        if (string.lower(tostring(k)) == lv) then return tostring(v) end
    end
    return nil;
end
local function textw(t)
    local w = imgui.CalcTextSize(t);
    if (type(w) == 'table') then w = w[1] or w.x end
    return tonumber(w) or 0;
end
local function cap(w) return string.upper(string.sub(w, 1, 1)) .. string.sub(w, 2) end
local function abbr(value)
    value = tostring(value or '');
    if (value == '') then return '' end
    local hit = abbrCache[value]; -- cleared by gchud.Start, so HUDAbbr edits apply on reload
    if (hit ~= nil) then return hit end
    local u = user_abbr(value);
    if (u ~= nil) then abbrCache[value] = u; return u end
    local lvl = abbrLevel[value] or 0;
    local budget = textw(FIT_TEXT);
    if (lvl >= 3) or (textw(value) <= budget) then abbrCache[value] = value; return value end
    local t = string.gsub(value, "'s ", ' '); -- Bunzi's Rod -> Bunzi
    t = string.gsub(t, "['%.]", '');
    t = string.gsub(t, '[^%w%+]', ' ');
    t = string.gsub(t, '(%l)(%u)', '%1 %2');
    t = string.gsub(t, '(%w)(%+)', '%1 %2');
    local tok = {};
    for w in string.gmatch(t, '%S+') do tok[#tok + 1] = w end
    if (#tok == 0) then abbrCache[value] = value; return value end
    local out, from = {}, 2;
    local key = '';
    for i = 1, #tok do -- a known short form for the leading words
        key = key .. string.lower(tok[i]);
        if (SHORT_FORM[key] ~= nil) then out[1], from = SHORT_FORM[key], i + 1; break end
    end
    if (out[1] == nil) then
        local first = tok[1];
        if (#first <= 4) or ((lvl == 0) and (#tok > 1) and (textw(cap(first)) <= budget)) then
            out[1] = cap(first);
        else
            out[1] = cap(string.sub(first, 1, 4));
        end
    end
    for i = from, #tok do
        local w = tok[i];
        if string.match(w, '^%+?%d+$') then
            out[#out + 1] = w;
        elseif (#w == 1) or (lvl == 1) then
            out[#out + 1] = string.upper(string.sub(w, 1, 1));
        elseif (lvl == 2) then
            out[#out + 1] = cap(string.sub(w, 1, 3));
        end
    end
    hit = table.concat(out);
    abbrCache[value] = hit;
    return hit;
end

-- Once per load: two of this box's weapon choices that shorten to the same text get longer forms (the later words'
-- initials, then their first 3 letters, then the full name) until they differ, so each reads as its own.
local abbrChecked = false;
local function check_abbr()
    abbrChecked = true;
    if (type(inc.WeaponCycleList) ~= 'function') then return end
    for pass = 1, 3 do
        local clash, bumped = false, {};
        for _, cname in ipairs({ 'Weapons', 'Main', 'Sub', 'Range', 'Ammo' }) do
            local list = inc.WeaponCycleList(cname);
            if (type(list) == 'table') then
                local seen = {};
                for _, v in ipairs(list) do
                    local full = (type(inc.WeaponLabel) == 'function') and inc.WeaponLabel(v) or v;
                    if (type(full) == 'string') and (EMPTY[string.lower(full)] ~= true) then
                        local a = abbr(full);
                        if (seen[a] ~= nil) and (seen[a] ~= full) then
                            for _, x in ipairs({ seen[a], full }) do
                                if not bumped[x] then bumped[x] = true; abbrLevel[x] = math.min((abbrLevel[x] or 0) + 1, 3) end
                            end
                            clash = true;
                        else
                            seen[a] = full;
                        end
                    end
                end
            end
        end
        abbrCache = {}; -- the next pass and drawing see the longer forms
        if not clash then break end
    end
end

local COL_CLEAR = { 0.0, 0.0, 0.0, 0.0 };
local COL_HOVER = { 1.0, 1.0, 1.0, 0.12 };
-- bright = changed since load, dim = still at load default
local COL_ON = { 0.35, 0.95, 0.45, 1.0 };      -- on, changed
local COL_ON_DEF = { 0.30, 0.70, 0.38, 0.85 }; -- on, default
local COL_OFF = { 0.50, 0.50, 0.56, 0.85 };    -- off, default
local COL_OFF_CHG = { 1.00, 0.55, 0.25, 1.0 }; -- off, changed (turned off something that loads on)
local COL_VAL = { 0.95, 0.85, 0.35, 1.0 };     -- cycle, changed
local COL_VAL_DEF = { 0.73, 0.67, 0.50, 1.0 }; -- cycle, default (softer than changed)
local COL_EMPTY = { 0.36, 0.36, 0.41, 0.85 };  -- cycle at None/Off: faint
-- def cell by state; a dot before the name in its SIR/TH/Kite/PROC colour; your own name gold; the header on a soft
-- blue fade; a 1px shadow under the text (drawn shapes: Ashita only)
local COL_DEF = { DT = { 1.00, 0.59, 0.27, 1.0 }, MDT = { 0.43, 0.71, 1.00, 1.0 }, Amin = { 0.75, 0.59, 1.00, 1.0 } };
local COL_OWN_NAME = { 0.95, 0.85, 0.35, 1.0 };
local COL_FADE_TOP, COL_FADE_BOT = { 0.24, 0.27, 0.43, 0.55 }, { 0.24, 0.27, 0.43, 0.0 };
local COL_SHADOW = { 0.0, 0.0, 0.0, 0.85 };
local COL_HEAD = { 0.59, 0.63, 0.71, 1.0 };
local DOTW = 10; -- px left of the names for the state dot

-- This frame's draw list (Ashita); nil on Windower, whose text box draws no shapes.
local DL, SHADOW = nil, nil;
local function shadow(text, padx) -- the shadow goes in first, so the item's own text sits on it
    if (DL == nil) then return end
    local x, y = imgui.GetCursorScreenPos();
    if (type(x) == 'table') then x, y = x[1] or x.x, x[2] or x.y end
    if (tonumber(x) ~= nil) then DL:AddText({ x + (padx or 0) + 1, y + 1 }, SHADOW, tostring(text)) end
end
local COL_HIGHBUFF = { 0.72, 0.52, 1.00, 1.0 }; -- mmode cell while /wsset high (no column of its own): purple
local COL_HOXNE = { 0.35, 0.85, 0.85, 1.0 };    -- wpn cell while /hoxne is on (no column of its own): teal
local COL_NAME = { 0.93, 0.93, 0.96, 1.0 };     -- white: SIR/TH/Kite/PROC colours stand out
-- The name shows SIR, TH, Kite, PROC (first one on, in this order; its tooltip lists all on). The rest of the toggles
-- (food, soda, harp, song lock, death) have no place on the HUD: their changes come in as chat lines.
local NAME_STATES = { { 'SIR', 'SIR', { 0.35, 0.55, 1.00, 1.0 } }, { 'TH', 'TH', { 1.00, 0.80, 0.20, 1.0 } },
    { 'Kite', 'Kite', { 0.35, 0.95, 0.45, 1.0 } }, { 'PROC', 'PROC', { 1.00, 0.35, 0.35, 1.0 } } }; -- blue, gold, green, red
local COL_JOB = { 0.60, 0.65, 0.75, 1.0 };
local COL_KEY = { 0.78, 0.82, 0.90, 1.0 };     -- headers

local function dir()
    return string.format('%sconfig\\addons\\luashitacast\\hud\\', AshitaCore:GetInstallPath());
end

local function listing()
    local base = dir();
    local trimmed = string.sub(base, 1, string.len(base) - 1);
    local tries = {
        { base, '.*%.txt' }, { base, '.*' }, { base },
        { trimmed, '.*%.txt' }, { trimmed, '.*' }, { trimmed },
    };
    for _, t in ipairs(tries) do
        local ok, files = pcall(ashita.fs.get_directory, t[1], t[2]);
        if (ok == true) and (type(files) == 'table') then
            local n = 0;
            for _, _ in pairs(files) do n = n + 1 end
            if (n > 0) then return files, t[1], (t[2] or 'nil') end
        end
    end
    return nil, base, 'none matched';
end

local function me()
    local player = gData.GetPlayer();
    if (player == nil) then return nil end
    if (player.Name == nil) or (player.Name == '') then return nil end
    return player;
end

local function encode(map, order)
    local parts = {};
    for _, k in ipairs(order) do
        if (map[k] ~= nil) then
            parts[#parts + 1] = k .. '=' .. tostring(map[k]);
            map[k] = nil;
        end
    end
    for k, v in pairs(map) do
        parts[#parts + 1] = k .. '=' .. tostring(v);
    end
    return table.concat(parts, ',');
end

local function decode(text)
    local map = {};
    local order = {};
    for pair in string.gmatch(text or '', '[^,]+') do
        local k, v = string.match(pair, '^([^=]+)=(.*)$');
        if (k ~= nil) then
            map[k] = v;
            order[#order + 1] = k;
        end
    end
    return map, order;
end

local function write_state()
    local player = me();
    if (player == nil) then return end
    -- '~' marks a value still at its load default, so readers can hide it.
    local tmap, cmap = disp.GetToggles(), disp.GetCycles();
    for k, v in pairs(tmap) do tmap[k] = (disp.IsDefault('toggle', k) and '~' or '') .. tostring(v) end
    for k, v in pairs(cmap) do
        if (k ~= 'Weapons') and disp.IsDefault('cycle', k) then cmap[k] = '~' .. tostring(v) end
    end
    local toggles = encode(tmap, gchud.ToggleOrder);
    local cycles = encode(cmap, gchud.CycleOrder);
    local line = table.concat({
        player.Name,
        tostring(player.MainJob or '?') .. '/' .. tostring(player.SubJob or '-'),
        toggles,
        cycles,
    }, '\t');
    local now = os.time();
    if (line == lastLine) and ((now - lastWriteTime) < 3) then return end
    local d = dir();
    if not ashita.fs.exists(d) then ashita.fs.create_directory(d) end
    local f = io.open(d .. player.Name .. '.txt', 'w');
    if (f == nil) then return end
    f:write(line .. '\t' .. tostring(now));
    f:close();
    lastLine = line;
    lastWriteTime = now;
end

local function read_all(everyBox)
    local files = listing();
    if (type(files) ~= 'table') then return end
    local now = os.time();
    local out = {};
    for _, entry in pairs(files) do
        local fname = (type(entry) == 'string') and string.match(entry, '([^\\/]+)$') or nil;
        if (fname ~= nil) and (string.sub(fname, -4) == '.txt') then
            local f = io.open(dir() .. fname, 'r');
            if (f ~= nil) then
                local text = f:read('*a');
                f:close();
                local parts = {};
                local rest = text or '';
                while true do
                    local at = string.find(rest, '\t', 1, true);
                    if (at == nil) then parts[#parts + 1] = rest; break end
                    parts[#parts + 1] = string.sub(rest, 1, at - 1);
                    rest = string.sub(rest, at + 1);
                end
                local stamp = tonumber(parts[5]);
                if (parts[1] ~= nil) and (parts[1] ~= '') and (stamp ~= nil) and ((now - stamp) <= STALE) then
                    local tmap, torder = decode(parts[3]);
                    local cmap, corder = decode(parts[4]);
                    out[#out + 1] = {
                        Name = parts[1],
                        Job = parts[2],
                        Toggles = tmap, ToggleOrder = torder,
                        Cycles = cmap, CycleOrder = corder,
                    };
                end
            end
        end
    end
    -- Order: HUDOwners first (in their order), then party/alliance order, then by name.
    local rank = {};
    for i, n in ipairs(inc.settings.HUDOwners or {}) do rank[string.lower(n)] = i end
    local okp, party = pcall(function() return AshitaCore:GetMemoryManager():GetParty() end);
    for i = 0, 17 do
        local okn, n = pcall(function() return party:GetMemberName(i) end);
        if okp and okn and (type(n) == 'string') and (n ~= '') and (rank[string.lower(n)] == nil) then rank[string.lower(n)] = 100 + i end
    end
    table.sort(out, function (a, b)
        local ra, rb = rank[string.lower(a.Name)] or 1000, rank[string.lower(b.Name)] or 1000;
        if (ra ~= rb) then return ra < rb end
        return a.Name < b.Name;
    end);
    -- With HUDOwners set, a box not in it shows only its own line.
    local owners, player = inc.settings.HUDOwners, me();
    if (everyBox ~= true) and (type(owners) == 'table') and (#owners > 0) and (player ~= nil) then
        local owner = false;
        for _, n in ipairs(owners) do
            if (string.lower(n) == string.lower(player.Name)) then owner = true end
        end
        if not owner then
            local mine = {};
            for _, r in ipairs(out) do
                if (string.lower(r.Name) == string.lower(player.Name)) then mine[#mine + 1] = r end
            end
            out = mine;
        end
    end
    rows = out;
end

-- Messages: every box keeps its last GoomSwap lines in hud\<Name>.msg, one "seq\tS|E\ttext" per line;
-- the box with the HUD open prints the other boxes' new ones as [Name]. seq is time based, so it keeps rising
-- across reloads; a box seen for the first time has its backlog skipped.
local MSG_KEEP = 10;
local outbox, lastSeq, seenSeq = {}, 0, {};

function gchud.Relay(text, isErr)
    local player = me();
    if (player == nil) then return end
    lastSeq = math.max(lastSeq + 1, os.time() * 1000);
    outbox[#outbox + 1] = lastSeq .. '\t' .. (isErr and 'E' or 'S') .. '\t' .. (string.gsub(tostring(text), '[\r\n\t]', ' '));
    while (#outbox > MSG_KEEP) do table.remove(outbox, 1) end
    local d = dir();
    if not ashita.fs.exists(d) then ashita.fs.create_directory(d) end
    local f = io.open(d .. player.Name .. '.msg', 'w');
    if (f == nil) then return end
    f:write(table.concat(outbox, '\n'));
    f:close();
end

local function read_msgs()
    local player = me();
    if (player == nil) then return end
    for _, row in ipairs(rows) do
        if (row.Name ~= player.Name) then
            local f = io.open(dir() .. row.Name .. '.msg', 'r');
            if (f ~= nil) then
                local text = f:read('*a') or '';
                f:close();
                local last = seenSeq[row.Name];
                local top = last or 0;
                for line in string.gmatch(text, '[^\n]+') do
                    local seq, kind, msg = string.match(line, '^(%d+)\t([SE])\t(.*)$');
                    seq = tonumber(seq);
                    if (seq ~= nil) then
                        if (last ~= nil) and (seq > last) then
                            print(chat.header(row.Name):append((kind == 'E') and chat.error(msg) or chat.message(msg)));
                        end
                        if (seq > top) then top = seq end
                    end
                end
                seenSeq[row.Name] = top;
            end
        end
    end
end

local savedX, savedY = nil, nil;

-- Two looks: 'compact' (default, tight) and 'large' (bigger text, more room, full names). /gchud large|compact,
-- saved per character with the position. settings.HUDStyle is the default; HUDScale / HUDScaleLarge the text size.
local STYLES = {
    compact = { window = { 4, 2 }, frame = { 1, 0 }, spacing = { 4, 1 }, padx = 1, gap = 1, name = 4 },
    large = { window = { 8, 5 }, frame = { 3, 1 }, spacing = { 6, 3 }, padx = 2, gap = 2, name = nil },
};
local function style_name()
    local s = string.lower(tostring(inc.settings.HUDStyle or 'compact'));
    return (STYLES[s] ~= nil) and s or 'compact';
end
local function style() return STYLES[style_name()] end

local function pos_file()
    local player = me();
    if (player == nil) then return nil end
    return string.format('%sconfig\\addons\\luashitacast\\gcbar\\', AshitaCore:GetInstallPath()), player.Name .. '_hud.txt';
end

local function save_pos()
    local d, f = pos_file();
    if (d == nil) then return end
    if not ashita.fs.exists(d) then ashita.fs.create_directory(d) end
    local h = io.open(d .. f, 'w');
    if (h == nil) then return end
    h:write(string.format('%d,%d,%s', inc.settings.HUDX or 300, inc.settings.HUDY or 40, style_name()));
    h:close();
    savedX, savedY = inc.settings.HUDX, inc.settings.HUDY;
end

local function load_pos()
    local d, f = pos_file();
    if (d == nil) then return end
    local h = io.open(d .. f, 'r');
    if (h == nil) then return end
    local x, y, s = string.match(h:read('*a') or '', '^(%-?%d+),(%-?%d+),?(%a*)');
    h:close();
    if (x == nil) then return end
    inc.settings.HUDX, inc.settings.HUDY = tonumber(x), tonumber(y);
    if (s ~= nil) and (STYLES[string.lower(s)] ~= nil) then inc.settings.HUDStyle = string.lower(s) end
    savedX, savedY = inc.settings.HUDX, inc.settings.HUDY;
end

-- HUDX/HUDY = top left of this box's own line. A drag moves it by the window's movement (same size frames),
-- so it works whichever way the HUD grows; saved on release.
local lastWX, lastWY, lastWH = nil, nil, nil;
local function win_size()
    if (imgui.GetWindowSize == nil) then return nil, nil end
    return imgui.GetWindowSize();
end
local function pair(a, b)
    if (type(a) == 'table') then return tonumber(a[1] or a.x), tonumber(a[2] or a.y) end
    return tonumber(a), tonumber(b);
end
local function track_drag()
    local x, y = pair(imgui.GetWindowPos());
    local _, h = pair(win_size());
    if (x == nil) or (y == nil) then return end
    if imgui.IsMouseDown(0) then
        if (lastWX ~= nil) and (h == lastWH) and ((x ~= lastWX) or (y ~= lastWY)) then
            inc.settings.HUDX = math.floor((inc.settings.HUDX or 300) + x - lastWX + 0.5);
            inc.settings.HUDY = math.floor((inc.settings.HUDY or 40) + y - lastWY + 0.5);
        end
    elseif (inc.settings.HUDX ~= savedX) or (inc.settings.HUDY ~= savedY) then
        save_pos();
    end
    lastWX, lastWY, lastWH = x, y, h;
end

local function send(name, command)
    nextRead = 0;
    local player = me();
    if (player ~= nil) and (string.lower(player.Name) == string.lower(name)) then
        AshitaCore:GetChatManager():QueueCommand(-1, '/lac fwd ' .. command);
    else
        AshitaCore:GetChatManager():QueueCommand(-1, '/ms sendto ' .. name .. ' /lac fwd ' .. command);
    end
end

local function label(key)
    local user = inc.settings.HUDLabels;
    if (type(user) == 'table') and (user[key] ~= nil) then return tostring(user[key]) end
    return SHORT[key] or string.lower(key);
end

local function tip(text)
    if imgui.IsItemHovered() then
        imgui.SetTooltip((string.gsub(text, '%%', '%%%%')));
    end
end

local function strip_default(value)
    value = value or '';
    if (string.sub(value, 1, 1) == '~') then return string.sub(value, 2), true end
    return value, false;
end

-- Grid: one header line, one line per box, columns aligned by measured text width.
-- Cycle columns first (weapon set leads), then toggle columns. Clicking a cell drives that box.
-- Columns show while any box's job has them, set or not, so the width doesn't change; toggles are one-letter flags.
-- DT/MDT/Aminon merge into one 'def' column (/def); SIR (a casting mode) keeps its own 'si' column; Burst is a * on the nuke cell.
-- Clicking a name adds a detail line under it: job + that box's hidden cycles and toggles.
local PADX = 1; -- cell padding; set from the style each frame in render()
local function short_name(name)
    local n = style().name;
    return (n ~= nil) and string.sub(name, 1, n) or name;
end

local function toggle_cell(row, key)
    local raw = row.Toggles[key];
    if (raw == nil) then return nil end
    local value, def = strip_default(raw);
    local on = (value == 'true');
    local cmd = gchud.ToggleCommands[key];
    return {
        -- off + default = '.', anything else shows the glyph so changes read at a glance
        text = (on or not def) and label(key) or '.',
        def = def,
        col = on and (def and COL_ON_DEF or COL_ON) or (def and COL_OFF or COL_OFF_CHG),
        cmd = cmd,
        tip = row.Name .. '  ' .. (FULL[key] or key) .. ': ' .. (on and 'on' or 'off')
            .. (def and ' (default)' or '') .. ((cmd ~= nil) and ('  /' .. cmd) or ''),
    };
end

-- The text a cycle value shows: '-' for None/Off, Base for the melee mode Default, short (compact) or full (large).
local function cell_text(key, value)
    value = tostring(value);
    if (key == 'MeleeSet') and (value == 'Default') then value = 'Base' end
    if (EMPTY[string.lower(value)] == true) or (DASH_DEFAULT[key] and (value == 'Default')) then return '-' end
    local short = SHORT_VALUE[key] and SHORT_VALUE[key][value];
    return (style().name == nil) and (user_abbr(value) or value) or (short or abbr(value));
end

-- Widest text this box's own cycle can show (every value in its list), so its column never widens later.
local function own_widest(key)
    if (disp == nil) or (type(disp.GetCycleValues) ~= 'function') then return 0 end
    local ok, list = pcall(disp.GetCycleValues, key);
    if (not ok) or (type(list) ~= 'table') then return 0 end
    local w = 0;
    local extra = (key == 'NukeSet') and '*' or ''; -- /burst's mark
    for _, v in ipairs(list) do w = math.max(w, textw(cell_text(key, v) .. extra)) end
    return w;
end

local function cycle_cell(row, key)
    local raw = row.Cycles[key];
    if (raw == nil) then return nil end
    local value, def = strip_default(raw);
    if (key == 'MeleeSet') and (value == 'Default') then value = 'Base' end -- the melee mode Default reads Base
    local empty = (EMPTY[string.lower(value)] == true) or (DASH_DEFAULT[key] == true) and (value == 'Default');
    local cmd = gchud.CycleCommands[key];
    return {
        text = cell_text(key, value), -- large: full value
        col = empty and COL_EMPTY or (def and COL_VAL_DEF or COL_VAL),
        cmd = cmd,
        empty = empty,
        tip = row.Name .. '  ' .. (FULL[key] or key) .. ': ' .. value
            .. (def and ' (default)' or '') .. ((cmd ~= nil) and ('  /' .. cmd) or ''),
    };
end

-- Merged columns: several toggles shown as one mode, clicked through the command that cycles them.
local DEF_PARTS = { { 'DTset', 'DT' }, { 'MDTset', 'MDT' }, { 'Aminon', 'Amin' } };
local GROUP_PART = { DTset = true, MDTset = true, Aminon = true, Burst = true }; -- Burst: a * on the nuke cell
local GROUP_ORDER = { 'Def' };

local function part(row, key)
    local raw = row.Toggles[key];
    if (raw == nil) then return nil end
    local value, def = strip_default(raw);
    return (value == 'true'), def;
end

local function group_cell(row, key)
    if (key == 'Def') then
        local on, alldef, any = {}, true, false;
        for _, p in ipairs(DEF_PARTS) do
            local v, d = part(row, p[1]);
            if (v ~= nil) then
                any = true;
                if v then on[#on + 1] = p[2] end
                if not d then alldef = false end
            end
        end
        if not any then return nil end
        local text = (#on == 0) and '-' or (on[1] .. ((#on > 1) and '+' or ''));
        return {
            text = text,
            col = (#on > 0) and (COL_DEF[on[1]] or COL_ON) or (alldef and COL_EMPTY or COL_OFF_CHG),
            cmd = 'def',
            def = alldef,
            tip = row.Name .. '  Defense: ' .. ((#on == 0) and 'none' or table.concat(on, ', '))
                .. (alldef and ' (default)' or '') .. '  /def',
        };
    end
    return nil;
end

local function draw_cell(row, key, c)
    shadow(c.text, (c.cmd ~= nil) and ((style().frame or { 0 })[1] or 0) or 0);
    imgui.PushStyleColor(ImGuiCol_Text, c.col);
    local clicked = false;
    if (c.cmd == nil) then
        imgui.Text(c.text);
    else
        c.id = c.id or (c.text .. '##' .. row.Name .. key); -- cells live until the next read, so built once
        clicked = imgui.SmallButton(c.id);
    end
    imgui.PopStyleColor();
    tip(c.tip);
    if clicked then
        local ok, ctrl = pcall(function() return imgui.GetIO().KeyCtrl end);
        send(row.Name, (ok and ctrl and c.ctrlCmd) or c.cmd);
    end
end

-- Keys present on any box: canonical order first, then the rest as they appear.
local view = {}; -- the rows the grid is built from (all of them)
local collapsedView, hoverUntil = false, 0; -- collapsed: only this box's line is drawn, in the full grid's columns
local growUp, homeH, collapsedFrames = false, nil, 0; -- grows up: own line stays at the bottom; homeH = its height
local revSrc, revView = nil, {};
local function columns(orderKey, canonical)
    local out, seen, present = {}, {}, {};
    for _, row in ipairs(view) do
        for _, k in ipairs(row[orderKey]) do
            if (orderKey ~= 'ToggleOrder') or not GROUP_PART[k] then present[k] = true end
        end
    end
    for _, k in ipairs(canonical) do
        if present[k] and not seen[k] then seen[k] = true; out[#out + 1] = k end
    end
    for _, row in ipairs(view) do
        for _, k in ipairs(row[orderKey]) do
            if present[k] and not seen[k] then seen[k] = true; out[#out + 1] = k end
        end
    end
    return out;
end

-- Cells, visible columns and widths depend only on the rows (re-read every 0.5s), the style, the text
-- scale and the window origin, so they are built when one of those changes, not every frame.
local FIXED_TEXT = { Def = 'Amin+' }; -- widest text those cells can show
local widthUnit, widthMax = nil, {};
local function build_grid(x0)
    local ccols = columns('CycleOrder', gchud.CycleOrder);
    local tcols = columns('ToggleOrder', gchud.ToggleOrder);
    local cells = {};
    local shown = {};
    for i, row in ipairs(view) do
        cells[i] = { c = {}, t = {} };
        for _, k in ipairs(ccols) do
            local c = cycle_cell(row, k);
            cells[i].c[k] = c;
            if (k == 'MeleeSet') and (c ~= nil) and (strip_default(row.Cycles.WsSet or '') == 'High') then
                c.col = COL_HIGHBUFF; -- /wsset high: shown on the mmode cell, so the HUD doesn't widen
                c.tip = c.tip .. '  |  WS buff: High (/wsset)';
            end
            local hx = strip_default(row.Cycles.Hoxne or '');
            if (k == 'Weapons') and (c ~= nil) and (hx ~= '') and (EMPTY[string.lower(hx)] ~= true) then
                c.col = COL_HOXNE; -- /hoxne on: shown on the wpn cell, so the HUD doesn't widen
                c.tip = c.tip .. '  |  Hoxne: ' .. hx .. ' (/hoxne)';
            end
            if (k == 'NukeSet') and (c ~= nil) and (part(row, 'Burst') == true) then
                c.text = c.text .. '*'; -- /burst on: Burst set on every nuke (the column leaves room for it)
                c.tip = c.tip .. '  |  Burst set: every nuke (/burst)';
            end
            if (c ~= nil) and (k ~= 'WsSet') and (k ~= 'Hoxne') then shown[k] = true end -- any box having it, set or not: no width change when set; WsSet/Hoxne colours
        end
        for _, k in ipairs(tcols) do cells[i].t[k] = toggle_cell(row, k) end
        cells[i].g = {};
        for _, k in ipairs(GROUP_ORDER) do cells[i].g[k] = group_cell(row, k) end
    end
    local vis = {};
    for _, k in ipairs(ccols) do
        if shown[k] then vis[#vis + 1] = k end
    end
    -- def, mb and every toggle a box's job has always show (toggles as one-letter flags side by side), so turning
    -- something on or off never changes the width.
    local gvis, gshown = {}, {};
    for _, k in ipairs(GROUP_ORDER) do
        for i = 1, #view do
            if (cells[i].g[k] ~= nil) then gvis[#gvis + 1] = k; gshown[k] = true; break end
        end
    end
    local tvis, tshown = {}, {}; -- toggles: no columns (name colour, chat lines, detail line)

    -- measure
    local gap = textw(string.rep(' ', style().gap));
    local nameW = 0;
    for _, row in ipairs(view) do nameW = math.max(nameW, textw(short_name(row.Name)) + PADX * 2) end
    local cols = {};
    local x = x0 + nameW + gap;
    -- Widths don't jump: mb/def take their widest possible text, every column keeps the widest it has been
    -- (until the style or text size changes), so a value changing doesn't resize the HUD.
    local unit = style_name() .. textw('M');
    if (unit ~= widthUnit) then widthUnit, widthMax = unit, {} end
    local function measure(key, kind, center)
        local l = label(key);
        local lw = textw(l);
        local w = lw;
        if (FIXED_TEXT[key] ~= nil) then w = math.max(w, textw(FIXED_TEXT[key])) end
        if (kind == 'c') then w = math.max(w, own_widest(key)) end -- this box's own values: room for the longest from the start
        for i = 1, #view do
            local c = cells[i][kind][key];
            if (c ~= nil) then c.w = textw(c.text); w = math.max(w, c.w) end -- reused when the row is drawn
        end
        w = math.max(w, widthMax[kind .. key] or 0);
        widthMax[kind .. key] = w;
        cols[#cols + 1] = { key = key, kind = kind, w = w, center = center, label = l, labelW = lw, tip = FULL[key] or key };
    end
    for _, k in ipairs(vis) do measure(k, 'c', false) end
    local ngrid = #cols;
    for _, k in ipairs(gvis) do measure(k, 'g', false) end
    for _, k in ipairs(tvis) do measure(k, 't', true) end
    -- Every mode column (cycles, def, mb) as wide as the widest of them, so they line up evenly.
    local uniform = 0;
    for _, col in ipairs(cols) do
        if (col.kind ~= 't') then uniform = math.max(uniform, col.w) end
    end
    for i, col in ipairs(cols) do
        local flag = (col.kind == 't'); -- one-letter flags sit side by side
        if (not flag) then col.w = uniform + PADX * 2 end
        if (i == ngrid + 1) then x = x + gap end -- group gap
        if flag and (i > 1) and (cols[i - 1].kind ~= 't') then x = x + gap end -- before the flags
        col.x = x;
        x = x + col.w + (flag and 0 or gap);
    end
    local nameIds = {};
    for i, row in ipairs(view) do nameIds[i] = short_name(row.Name) .. '##' .. row.Name .. 'row' end
    return { view = view, style = style_name(), x0 = x0, cells = cells, cols = cols, nameIds = nameIds,
        ccols = ccols, tcols = tcols, shown = shown, gshown = gshown, tshown = tshown };
end

local grid = nil;
local function body(scale)
    if (#view == 0) then
        imgui.Text('no characters reporting');
        track_drag();
        return;
    end
    DL = (imgui.GetWindowDrawList ~= nil) and imgui.GetWindowDrawList() or nil;
    if (DL ~= nil) and ((imgui.GetColorU32 == nil) or (imgui.GetCursorScreenPos == nil) or (imgui.GetTextLineHeight == nil)) then DL = nil end
    SHADOW = (DL ~= nil) and imgui.GetColorU32(COL_SHADOW) or nil;
    local x0 = imgui.GetCursorPosX() + ((DL ~= nil) and DOTW or 0);
    local g = grid;
    if (g == nil) or (g.view ~= view) or (g.style ~= style_name()) or (g.scale ~= scale) or (g.x0 ~= x0) then
        g = build_grid(x0);
        g.scale = scale;
        grid = g;
    end
    local cells, cols, ccols, tcols, shown, gshown, tshown = g.cells, g.cols, g.ccols, g.tcols, g.shown, g.gshown, g.tshown;
    local function at(col, textWidth, first)
        local cx = col.x;
        if col.center then cx = cx + math.floor((col.w - textWidth) / 2) end
        if first then imgui.SetCursorPosX(cx) else imgui.SameLine(cx) end
    end

    local dl = DL;
    local wx, wy = pair(imgui.GetWindowPos());
    local ww = pair(win_size());
    local function u32(c) return imgui.GetColorU32(c) end
    local lh = (dl ~= nil) and imgui.GetTextLineHeight() or nil;

    -- header (also over the owner's one-line view), on a soft blue fade from the window's top
    do
    if (dl ~= nil) and (wx ~= nil) and (ww ~= nil) then
        local _, cy = pair(imgui.GetCursorScreenPos());
        if (cy ~= nil) then
            local top, bot = u32(COL_FADE_TOP), u32(COL_FADE_BOT);
            dl:AddRectFilledMultiColor({ wx, wy }, { wx + ww, cy + lh + 2 }, top, top, bot, bot);
        end
    end
    imgui.PushStyleColor(ImGuiCol_Text, COL_HEAD);
    for i, col in ipairs(cols) do
        at(col, col.labelW, i == 1);
        if not col.center then imgui.SetCursorPosX(imgui.GetCursorPosX() + PADX) end
        shadow(col.label);
        imgui.Text(col.label);
        tip(col.tip);
    end
    imgui.PopStyleColor();
    end

    -- rows
    local mine = me();
    for i, row in ipairs(view) do
      if not collapsedView or ((mine ~= nil) and (string.lower(row.Name) == string.lower(mine.Name))) then
        local open = (expanded[row.Name] == true);
        imgui.SetCursorPosX(x0);
        local ncol, states = COL_NAME, {};
        for _, st in ipairs(NAME_STATES) do
            if (part(row, st[1]) == true) then
                if (#states == 0) then ncol = st[3] end
                states[#states + 1] = st[2];
            end
        end
        local own = (mine ~= nil) and (string.lower(row.Name) == string.lower(mine.Name));
        if (dl ~= nil) then -- the state as a dot left of the name; the name white, yours gold
            local rx, ry = pair(imgui.GetCursorScreenPos());
            if (rx ~= nil) and (#states > 0) then dl:AddCircleFilled({ rx - DOTW / 2 - 1, ry + lh / 2 }, 3.5, u32(ncol), 12) end
            ncol = own and COL_OWN_NAME or COL_NAME;
        elseif own and (#states == 0) then
            ncol = COL_OWN_NAME; -- Windower: the name shows the state, else gold for yours
        end
        shadow(short_name(row.Name), (style().frame or { 0 })[1] or 0);
        imgui.PushStyleColor(ImGuiCol_Text, ncol);
        local clicked = imgui.SmallButton(g.nameIds[i]);
        imgui.PopStyleColor();
        if imgui.IsItemHovered() then
            tip(row.Name .. '  ' .. tostring(row.Job) .. ((#states > 0) and ('  |  on: ' .. table.concat(states, ', ')) or '')
                .. '  (click: ' .. (open and 'hide' or 'show') .. ' details)');
        end
        for _, col in ipairs(cols) do
            local c = cells[i][col.kind][col.key];
            if (c ~= nil) then
                at(col, c.w + PADX * 2, false);
                draw_cell(row, col.key, c);
            end
        end
        if open then
            local first = cols[1];
            imgui.SetCursorPosX((first ~= nil) and first.x or x0);
            imgui.PushStyleColor(ImGuiCol_Text, COL_JOB);
            imgui.Text(tostring(row.Job));
            imgui.PopStyleColor();
            for _, k in ipairs(ccols) do
                local c = cells[i].c[k];
                if (c ~= nil) and not shown[k] then
                    imgui.SameLine();
                    imgui.PushStyleColor(ImGuiCol_Text, COL_KEY);
                    imgui.Text(label(k));
                    imgui.PopStyleColor();
                    imgui.SameLine(0, 0);
                    draw_cell(row, k, c);
                end
            end
            for _, k in ipairs(GROUP_ORDER) do
                local c = cells[i].g[k];
                if (c ~= nil) and not gshown[k] then
                    imgui.SameLine();
                    imgui.PushStyleColor(ImGuiCol_Text, COL_KEY);
                    imgui.Text(label(k));
                    imgui.PopStyleColor();
                    imgui.SameLine(0, 0);
                    draw_cell(row, k, c);
                end
            end
            for _, k in ipairs(tcols) do
                local c = cells[i].t[k];
                if (c ~= nil) and not tshown[k] then
                    imgui.SameLine();
                    c.alt = c.alt or { text = label(k), col = c.col, cmd = c.cmd, tip = c.tip };
                    draw_cell(row, k, c.alt);
                end
            end
        end
        if clicked then expanded[row.Name] = not open end
      end
    end
    track_drag();
end

local fontPushed = false;
local function inner()
    -- Ashita < 4.3: SetWindowFontScale. Ashita 4.3 (ImGui 1.92) removed it: PushFont(nil, size).
    local scale = (style_name() == 'large') and (tonumber(inc.settings.HUDScaleLarge) or 1.1) or (tonumber(inc.settings.HUDScale) or 1.0);
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(scale);
    elseif (scale ~= 1.0) and (imgui.PushFont ~= nil) and (imgui.GetFontSize ~= nil) then
        imgui.PushFont(nil, imgui.GetFontSize() * scale);
        fontPushed = true;
    end
    body(scale);
end

-- HUDGrow 'up' / 'down', or 'auto': up when this box's line sits in the bottom half of the screen.
local function grows_up()
    local g = string.lower(tostring(inc.settings.HUDGrow or 'auto'));
    if (g == 'up') then return true elseif (g == 'down') then return false end
    local ok, sh = pcall(function() return imgui.GetMainViewport().Size.y end);
    if (not ok) or (tonumber(sh) == nil) then
        ok, sh = pcall(function() return imgui.GetIO().DisplaySize.y end);
    end
    if (not ok) or (tonumber(sh) == nil) or (sh <= 0) then return false end
    return ((inc.settings.HUDY or 40) + (homeH or 0) / 2) > (sh / 2);
end

local function render()
    if not visible then return end
    local held = imgui.IsMouseDown(0);
    if not held then -- not mid-drag
        local up = grows_up();
        if growUp and not up then placed = false end -- own line back on top, where it is now (HUDY)
        growUp = up;
    end
    if (not placed) then
        -- Always: after /gchud pos ImGui would otherwise keep the old position
        imgui.SetNextWindowPos({ inc.settings.HUDX or 300, inc.settings.HUDY or 40 }, ImGuiCond_Always);
        placed = true;
    elseif growUp and (homeH ~= nil) and not held then
        -- pin the bottom of the own line; the rest of the grid goes above it
        imgui.SetNextWindowPos({ inc.settings.HUDX or 300, (inc.settings.HUDY or 40) + homeH }, ImGuiCond_Always, { 0, 1 });
    end
    local flags = bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing,
        ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoResize);
    local st = style();
    PADX = st.padx;
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, st.window);
    imgui.PushStyleVar(ImGuiStyleVar_FramePadding, st.frame);
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, st.spacing);
    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 6);
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0);
    imgui.PushStyleColor(ImGuiCol_Button, COL_CLEAR);
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, COL_HOVER);
    imgui.PushStyleColor(ImGuiCol_ButtonActive, COL_HOVER);
    imgui.PushStyleColor(ImGuiCol_WindowBg, { 0.04, 0.045, 0.06, inc.settings.HUDAlpha or 0.45 });
    imgui.PushStyleColor(ImGuiCol_Border, COL_CLEAR);
    local ok, err = true, nil;
    if imgui.Begin('GC##gchud', true, flags) then
        -- Owner: one line (this box) until the mouse is over the HUD, then every box (HUDHover = false: always all).
        local now = os.clock();
        if (imgui.IsWindowHovered ~= nil) and imgui.IsWindowHovered() then hoverUntil = now + 0.6 end
        collapsedView = (inc.settings.HUDHover ~= false) and (now >= hoverUntil) and (#rows > 1);
        -- the own line's height, once the window has had a few frames to fit it
        collapsedFrames = collapsedView and (collapsedFrames + 1) or 0;
        if (collapsedFrames >= 3) then
            local _, h = pair(win_size());
            if (h ~= nil) and (h > 0) then homeH = h end
        end
        if growUp then
            -- mirrored: own line (first) at the bottom, the next box just above it
            if (revSrc ~= rows) then
                revSrc, revView = rows, {};
                for i = #rows, 1, -1 do revView[#revView + 1] = rows[i] end
            end
            view = revView;
        else
            view = rows;
        end
        -- any error between Begin and End must not skip PopFont/End/Pop*, or ImGui asserts every frame after
        ok, err = pcall(inner);
        if fontPushed then imgui.PopFont(); fontPushed = false; end
    end
    imgui.End();
    imgui.PopStyleColor(5);
    imgui.PopStyleVar(5);
    if (ok ~= true) then error(err, 0) end
end

local function present()
    if (inc == nil) or (disp == nil) then return end
    if (abbrChecked ~= true) then pcall(check_abbr) end
    local now = os.clock();
    if (now >= nextWrite) then
        nextWrite = now + 0.25;
        pcall(write_state);
    end
    if visible then
        if (now >= nextRead) then
            nextRead = now + 0.5;
            local ok, err = pcall(read_all);
            if (ok ~= true) and (gchud.Errors ~= true) then
                gchud.Errors = true;
                print(chat.header('GCHUD'):append(chat.error('read failed: ' .. tostring(err))));
            end
            if (inc.settings.HUDMessages ~= false) then pcall(read_msgs) end
        end
        local ok, err = pcall(render);
        if (ok ~= true) and (gchud.Errors ~= true) then
            gchud.Errors = true;
            print(chat.header('GCHUD'):append(chat.error('draw failed: ' .. tostring(err))));
        end
    end
end

-- True when <name> is one of my boxes: every box running this engine rewrites hud\<Name>.txt every
-- 0.25s (write_state), so a fresh file means a box that can take '/lac fwd'. Cached 5s per name.
local boxCache = {};
-- Every reporting box's modes (for /gcmodes all): { Name, Job, Toggles, Cycles }, owner first.
function gchud.AllRows()
    local keep = rows;
    pcall(read_all, true);
    local all = rows;
    rows = keep;
    return all;
end

function gchud.IsBox(name)
    if (type(name) ~= 'string') or (name == '') then return false end
    local key = string.lower(name);
    local now = os.time();
    local hit = boxCache[key];
    if (hit ~= nil) and ((now - hit.at) < 5) then return hit.ok end
    local ok = false;
    local f = io.open(dir() .. name .. '.txt', 'r');
    if (f ~= nil) then
        local stamp = tonumber(string.match(f:read('*a') or '', '\t(%d+)%s*$'));
        f:close();
        ok = (stamp ~= nil) and ((now - stamp) <= STALE);
    end
    boxCache[key] = { ok = ok, at = now };
    return ok;
end

function gchud.Bind(gcinclude, gcdisplay)
    inc = gcinclude;
    disp = gcdisplay;
end

function gchud.Start()
    pcall(load_pos);
    abbrChecked = false;
    abbrCache, abbrLevel = {}, {};
    boxCache = {};
    seenSeq = {};
    placed = false;
    ashita.events.register('d3d_present', 'gchud_present', present);
    local player = me();
    local owners = inc.settings.HUDOwners;
    if (player ~= nil) and (type(owners) == 'table') then
        for _, n in ipairs(owners) do
            if (string.lower(n) == string.lower(player.Name)) then visible = true end
        end
    end
end

function gchud.Stop()
    ashita.events.unregister('d3d_present', 'gchud_present');
    visible = false;
end

function gchud.Debug()
    local files, path, mask = listing();
    print(chat.header('GCHUD'):append(chat.message('path: ' .. path)));
    print(chat.header('GCHUD'):append(chat.message('mask used: ' .. tostring(mask))));
    if (type(files) ~= 'table') then
        print(chat.header('GCHUD'):append(chat.error('get_directory returned nothing')));
    else
        for _, entry in pairs(files) do
            print(chat.header('GCHUD'):append(chat.message('file: ' .. tostring(entry))));
        end
    end
    read_all();
    print(chat.header('GCHUD'):append(chat.message('rows parsed: ' .. tostring(#rows))));
    for _, row in ipairs(rows) do
        print(chat.header('GCHUD'):append(chat.message(row.Name .. ' ' .. row.Job)));
    end
end

function gchud.HandleCommand(args)
    local arg = (args[2] ~= nil) and string.lower(args[2]) or nil;
    if (arg == 'debug') then
        gchud.Debug();
        return;
    end
    if (arg == 'pos') and (tonumber(args[3]) ~= nil) and (tonumber(args[4]) ~= nil) then
        inc.settings.HUDX = tonumber(args[3]);
        inc.settings.HUDY = tonumber(args[4]);
        placed = false;
        save_pos();
        return;
    end
    if (arg == 'large') or (arg == 'compact') or (arg == 'style') then
        if (arg == 'style') then arg = (style_name() == 'large') and 'compact' or 'large' end
        inc.settings.HUDStyle = arg;
        save_pos();
        visible = true;
        nextRead = 0;
        print(chat.header('GCHUD'):append(chat.message('style: ' .. arg)));
        return;
    end
    if (arg == 'on') then
        visible = true;
    elseif (arg == 'off') then
        visible = false;
    else
        visible = not visible;
    end
    nextRead = 0;
end

return gchud;
