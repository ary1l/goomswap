local gchud = {};


local inc = nil;
local disp = nil;
local nextWrite = 0;
local nextRead = 0;
local lastLine = nil;
local lastWriteTime = 0;
local rows = {};
local visible = false;

-- The HUD is the drop under /gcbar (gcdisplay draws it): this file shares each box's modes (hud\<Name>.txt,
-- Windower: IPC), reads the other boxes' and forwards clicks. /gchud turns the drop on or off.

local STALE = 15;

gchud.CycleCommands = {
    MeleeSet = 'mset',
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

gchud.CycleOrder = { 'Weapons', 'Main', 'Sub', 'Range', 'Ammo', 'MeleeSet', 'WsSet', 'RangedSet', 'IdleSet' }; -- Main/Sub/Range/Ammo, MeleeSet, WsSet fold into wpn (FOLDED)
gchud.ToggleOrder = { 'DTset', 'MDTset', 'Aminon', 'SIR', 'TH', 'Kite' };

local rowsKey = nil; -- read_all: the rows' content (not their timestamps); unchanged keeps rows (and the drop's built lines)

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

-- Nothing changed (gcdisplay's version, jobs, name) and the 3s heartbeat isn't due: skip building the line
-- (me() is LAC's whole gData.GetPlayer). A sub job change without a profile reload is caught by the heartbeat too.
local lastKey = nil;
local function state_key()
    if (type(disp.Version) ~= 'function') then return nil end
    local mm = AshitaCore:GetMemoryManager();
    local p, party = mm:GetPlayer(), mm:GetParty();
    if (p == nil) or (party == nil) then return nil end
    return disp.Version() .. '|' .. tostring(p:GetMainJob()) .. '|' .. tostring(p:GetSubJob()) .. '|' .. tostring(party:GetMemberName(0));
end
local function write_state()
    local key = state_key();
    if (key ~= nil) and (key == lastKey) and ((os.time() - lastWriteTime) < 3) then return end
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
        tostring(player.MainJob or '?') .. tostring(player.MainJobLevel or '') .. '/' .. tostring(player.SubJob or '-') ..
            (((tonumber(player.SubJobLevel) or 0) > 0) and tostring(player.SubJobLevel) or ''), -- COR99/DNC49: the drop's job text
        toggles,
        cycles,
    }, '\t');
    local now = os.time();
    if (line == lastLine) and ((now - lastWriteTime) < 3) then lastKey = key; return end
    local d = dir();
    if not ashita.fs.exists(d) then ashita.fs.create_directory(d) end
    local f = io.open(d .. player.Name .. '.txt', 'w');
    if (f == nil) then return end
    f:write(line .. '\t' .. tostring(now));
    f:close();
    lastLine = line;
    lastWriteTime = now;
    lastKey = key;
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
                        Raw = table.concat(parts, '\t', 1, 4),
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
    if (everyBox ~= true) then -- /gcmodes all reads every box without touching the HUD's rows
        local raw = {};
        for i, r in ipairs(out) do raw[i] = r.Raw end
        local key = table.concat(raw, '\n');
        if (key == rowsKey) then return end
        rowsKey = key;
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


local function send(name, command)
    nextRead = 0;
    local player = me();
    if (player ~= nil) and (string.lower(player.Name) == string.lower(name)) then
        AshitaCore:GetChatManager():QueueCommand(-1, '/lac fwd ' .. command);
    else
        AshitaCore:GetChatManager():QueueCommand(-1, '/ms sendto ' .. name .. ' /lac fwd ' .. command);
    end
end


local function present()
    if (inc == nil) or (disp == nil) then return end
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
    end
end

-- True when <name> is one of my boxes: every box running this engine rewrites hud\<Name>.txt when its modes
-- change and at least every 3s (write_state), so a fresh file means a box that can take '/lac fwd'. Cached 5s per name.
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
    if (type(disp.SetHud) == 'function') then disp.SetHud(gchud) end
end

-- The drop's lines: every other reporting box (this box's own line is the bar), nil while /gchud is off.
local dropSrc, dropRows = nil, nil;
function gchud.DropRows()
    if not visible then return nil end
    if (dropSrc ~= rows) then
        dropSrc, dropRows = rows, {};
        local player = me();
        local mine = (player ~= nil) and string.lower(player.Name) or '';
        for _, r in ipairs(rows) do
            if (string.lower(r.Name) ~= mine) then dropRows[#dropRows + 1] = r end
        end
    end
    return dropRows;
end
gchud.Send = send; -- a click on a dropped line: that box runs the command

function gchud.Start()
    boxCache = {};
    seenSeq = {};
    rowsKey = nil;
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
    if (arg == 'on') then
        visible = true;
    elseif (arg == 'off') then
        visible = false;
    else
        visible = not visible;
    end
    nextRead = 0;
    if visible and (inc.settings.DisplayBar ~= true) and (type(disp.BarCommand) == 'function') then
        disp.BarCommand({ 'gcbar', 'on' }); -- the drop hangs off the bar
    end
    print(chat.header('GCHUD'):append(chat.message('Drop under the bar: ' .. (visible and 'On' or 'Off'))));
end

return gchud;
