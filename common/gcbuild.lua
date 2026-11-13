-- /gcbuild [JOB]: a proposed job file for this character. Takes the job's example (luashitacast\examples\<JOB>.lua)
-- and keeps, set by set, the gear the character owns:
--   owned as the example names it            the line stays
--   owned, but with other augments           the name alone stays (LAC needs every listed augment on the item)
--   owned, only in a bag sets can't use      the line stays, marked: move it to a wardrobe
--   not owned (or one copy for two slots)    the line is commented out where it stands, so the set under it shows through
-- Nothing is picked for a slot the character has nothing from the example for. Handlers and OnLoad are the example's
-- as they are. Written to <Name>_<id>\<JOB>.proposed.lua: your <JOB>.lua is never touched. Ashita only.
-- Loaded by gcinclude when the command is used. Build() is plain text in, text out, so it runs outside the game too.
local gcbuild = {};

local SLOTS = { Main = true, Sub = true, Range = true, Ammo = true, Head = true, Neck = true, Ear1 = true, Ear2 = true,
    Body = true, Hands = true, Ring1 = true, Ring2 = true, Back = true, Waist = true, Legs = true, Feet = true };
local KEYWORDS = { remove = true, displaced = true, ignore = true }; -- LAC slot words, not items

-- A quoted string starting at `at`: its text (escapes undone) and the index after its closing quote.
local function read_string(s, at)
    local q = string.sub(s, at, at);
    if (q ~= "'") and (q ~= '"') then return nil end
    local out, i = {}, at + 1;
    while (i <= #s) do
        local c = string.sub(s, i, i);
        if (c == '\\') then
            out[#out + 1] = string.sub(s, i + 1, i + 1);
            i = i + 2;
        elseif (c == q) then
            return table.concat(out), i + 1;
        else
            out[#out + 1] = c;
            i = i + 1;
        end
    end
    return nil;
end

-- The index after the '}' matching the '{' at `at` (strings skipped), or nil.
local function skip_table(s, at)
    local depth, i = 0, at;
    while (i <= #s) do
        local c = string.sub(s, i, i);
        if (c == "'") or (c == '"') then
            local _, nxt = read_string(s, i);
            if (nxt == nil) then return nil end
            i = nxt;
        else
            if (c == '{') then depth = depth + 1 elseif (c == '}') then depth = depth - 1 end
            i = i + 1;
            if (depth == 0) then return i end
        end
    end
    return nil;
end

-- An item value at `at` ('Name' or { Name = 'X', Augment = {...}, AugPath = 'B' }): { name, augs, path } and the
-- index after it. nil when it is neither (a variable, a call): such a line is left as it is.
local function read_item(s, at)
    local c = string.sub(s, at, at);
    if (c == "'") or (c == '"') then
        local name, nxt = read_string(s, at);
        if (name == nil) then return nil end
        return { name = name, augs = {} }, nxt;
    end
    if (c ~= '{') then return nil end
    local nxt = skip_table(s, at);
    if (nxt == nil) then return nil end
    local body = string.sub(s, at, nxt - 1);
    local n1 = select(2, string.find(body, '[Nn]ame%s*=%s*'));
    local name = (n1 ~= nil) and read_string(body, n1 + 1) or nil;
    if (name == nil) then return nil end
    local item = { name = name, augs = {} };
    local a1 = select(2, string.find(body, 'Augment%s*=%s*'));
    if (a1 ~= nil) then
        local first = string.sub(body, a1 + 1, a1 + 1);
        if (first == '{') then
            local stop = skip_table(body, a1 + 1) or #body;
            local i = a1 + 2;
            while (i < stop) do
                local ch = string.sub(body, i, i);
                if (ch == "'") or (ch == '"') then
                    local str, after = read_string(body, i);
                    if (str == nil) then break end
                    item.augs[#item.augs + 1] = str;
                    i = after;
                else
                    i = i + 1;
                end
            end
        else
            local str = read_string(body, a1 + 1);
            if (str ~= nil) then item.augs[1] = str end
        end
    end
    local p1 = select(2, string.find(body, 'AugPath%s*=%s*'));
    if (p1 ~= nil) then item.path = read_string(body, p1 + 1) end
    return item, nxt;
end

-- A copy of an item fits the example's entry the way LAC checks it (equip.lua CheckAugments): the path, when
-- named, is the copy's, and every augment listed is on the copy.
local function copy_fits(item, copy)
    if (item.path ~= nil) and (copy.path ~= item.path) then return false end
    for _, want in ipairs(item.augs) do
        local found = false;
        for _, have in ipairs(copy.augs) do
            if (have == want) then found = true; break end
        end
        if not found then return false end
    end
    return true;
end

local function q(s) return "'" .. string.gsub(string.gsub(s, '\\', '\\\\'), "'", "\\'") .. "'" end

local function copy_text(copy)
    local parts = {};
    if (copy.path ~= nil) then parts[#parts + 1] = 'Path ' .. tostring(copy.path) end
    for _, a in ipairs(copy.augs) do parts[#parts + 1] = a end
    return (#parts > 0) and table.concat(parts, ', ') or 'no augments';
end

-- What to do with one item of the example: 'keep', 'move' (bag), 'name' (other augments; note), 'drop' (why).
-- used: how often each item was already kept in this set, so the same ring in Ring1 and Ring2 needs two copies.
local function judge(item, owned, used)
    local key = string.lower(item.name);
    if KEYWORDS[key] then return 'keep' end
    local have = owned[key];
    if (have == nil) or (#have.copies == 0) then return 'drop', 'not owned' end
    used[key] = (used[key] or 0) + 1;
    if (used[key] > #have.copies) then return 'drop', 'only ' .. #have.copies .. ' owned' end
    local fits, usable, bag = false, false, nil;
    for _, copy in ipairs(have.copies) do
        if copy_fits(item, copy) then
            fits = true;
            if copy.equippable then usable = true else bag = bag or copy.bag end
        end
    end
    if fits and usable then return 'keep' end
    if fits then return 'move', bag end
    local list = {};
    for _, copy in ipairs(have.copies) do list[#list + 1] = copy_text(copy) .. (copy.equippable and '' or (' [' .. tostring(copy.bag) .. ']')) end
    return 'name', table.concat(list, ' | ');
end

-- templateText: an example job file. owned: { [lower item name] = { name = 'Item', copies = { { bag = 'Wardrobe',
-- equippable = true, augs = { 'STR+30', ... }, path = 'B' }, ... } } }. Returns the proposed file's text and a report
-- { slots, kept, dropped, renamed, moved, missing = { {name, n}... }, move = { {name, bag}... } }, or nil, why.
function gcbuild.Build(templateText, owned, info)
    info = info or {};
    local lines = {};
    for line in string.gmatch(templateText .. '\n', '(.-)\r?\n') do lines[#lines + 1] = line end
    if (lines[#lines] == '') then lines[#lines] = nil end
    local first, last = nil, nil;
    for i, line in ipairs(lines) do
        if (first == nil) and (string.find(line, 'local sets = {', 1, true) ~= nil) then first = i end
        if (first ~= nil) and (string.match(line, '^profile%.Sets%s*=') ~= nil) then last = i; break end
    end
    if (first == nil) or (last == nil) then return nil, 'the example has no `local sets = {` ... `profile.Sets = sets` block' end

    local rep = { slots = 0, kept = 0, dropped = 0, renamed = 0, moved = 0, missing = {}, move = {} };
    local missN, moveSeen = {}, {};
    local function note(verdict, item, extra)
        rep.slots = rep.slots + 1;
        if (verdict == 'drop') then
            rep.dropped = rep.dropped + 1;
            local key = string.lower(item.name);
            if (missN[key] == nil) then missN[key] = { item.name, 0 }; rep.missing[#rep.missing + 1] = missN[key] end
            missN[key][2] = missN[key][2] + 1;
        else
            rep.kept = rep.kept + 1;
            if (verdict == 'name') then rep.renamed = rep.renamed + 1 end
            if (verdict == 'move') then
                rep.moved = rep.moved + 1;
                local key = string.lower(item.name);
                if not moveSeen[key] then moveSeen[key] = true; rep.move[#rep.move + 1] = { item.name, extra } end
            end
        end
    end

    local used = {}; -- per set: emptied where a set opens and where one closes
    for i = first + 1, last - 1 do
        local line = lines[i];
        local indent, key, eq = string.match(line, '^(%s*)(%a+%d?)(%s*=%s*)');
        local item, nxt = nil, nil;
        if (key ~= nil) and SLOTS[key] then
            item, nxt = read_item(line, #indent + #key + #eq + 1);
            -- only a comma and a comment may follow, else the line holds more than this slot (a closing brace)
            if (item ~= nil) and (string.match(string.sub(line, nxt), '^%s*,?%s*$') == nil)
                and (string.match(string.sub(line, nxt), '^%s*,?%s*%-%-') == nil) then item = nil end
        end
        if (item ~= nil) then
            -- one slot on its own line: Head = 'Nyame Helm',
            local verdict, extra = judge(item, owned, used);
            note(verdict, item, extra);
            if (verdict == 'drop') then
                lines[i] = indent .. '--' .. string.sub(line, #indent + 1) .. ' -- ' .. extra;
            elseif (verdict == 'move') then
                lines[i] = line .. ' -- in ' .. tostring(extra) .. ': move it to a wardrobe';
            elseif (verdict == 'name') then
                lines[i] = indent .. key .. eq .. q(item.name) .. string.sub(line, nxt) .. ' -- your augments differ from the example\'s: ' .. extra;
            end
        elseif (string.match(line, '^%s*%-%-') == nil) then
            -- slots sharing a line with braces: Mp_Body = {Body = 'Seidr Cotehardie',},
            local open, close = string.find(line, '{', 1, true), string.find(line, '}', 1, true);
            if (open ~= nil) and ((close == nil) or (open < close)) then used = {} end -- a set opens here
            local out, pos, notes = {}, 1, {};
            while true do
                local s1, e1, k = string.find(line, '([%a]+%d?)%s*=%s*', pos);
                if (s1 == nil) then break end
                local item, nxt = nil, nil;
                if SLOTS[k] and ((s1 == 1) or (string.match(string.sub(line, s1 - 1, s1 - 1), '[%w_%.]') == nil)) then
                    item, nxt = read_item(line, e1 + 1);
                end
                if (item == nil) then
                    out[#out + 1] = string.sub(line, pos, e1);
                    pos = e1 + 1;
                else
                    local verdict, extra = judge(item, owned, used);
                    note(verdict, item, extra);
                    out[#out + 1] = string.sub(line, pos, s1 - 1);
                    local comma = string.match(line, '^%s*,%s*', nxt);
                    if (verdict == 'drop') then
                        notes[#notes + 1] = extra .. ': ' .. item.name;
                        nxt = nxt + #(comma or '');
                    elseif (verdict == 'name') then
                        out[#out + 1] = k .. ' = ' .. q(item.name);
                        notes[#notes + 1] = item.name .. ': your augments differ from the example\'s: ' .. extra;
                    else
                        out[#out + 1] = string.sub(line, s1, nxt - 1);
                        if (verdict == 'move') then notes[#notes + 1] = item.name .. ' is in ' .. tostring(extra) .. ': move it to a wardrobe' end
                    end
                    pos = nxt;
                end
            end
            if (#notes > 0) then
                out[#out + 1] = string.sub(line, pos);
                lines[i] = table.concat(out) .. ' -- ' .. table.concat(notes, '; ');
            end
            if (string.find(line, '}', 1, true) ~= nil) then used = {} end -- the set (or an item table on its own lines) ended
        end
    end

    table.sort(rep.missing, function(a, b) if (a[2] ~= b[2]) then return a[2] > b[2] end return a[1] < b[1] end);
    local function wrap(head, list, fmt)
        local out, row = {}, {};
        for _, v in ipairs(list) do
            row[#row + 1] = fmt(v);
            if (#row == 5) then out[#out + 1] = '--   ' .. table.concat(row, ', '); row = {} end
        end
        if (#row > 0) then out[#out + 1] = '--   ' .. table.concat(row, ', ') end
        if (#out > 0) then table.insert(out, 1, head) end
        return out;
    end
    local h = {
        '-- Proposed by /gcbuild for ' .. tostring(info.name or 'this character') .. ': GoomSwap examples/' .. tostring(info.job or '?')
            .. '.lua with the gear you own' .. ((info.date ~= nil) and (' (' .. info.date .. ')') or '') .. '.',
        string.format('-- %d of %d set slots kept; %d left out (not owned, or fewer copies than the set wears): commented out where', rep.kept, rep.slots, rep.dropped),
        '-- they stood, so the set under shows through.',
        string.format('-- %d kept by name only (your copy has other augments); %d are in a bag sets can\'t equip from.', rep.renamed, rep.moved),
        '-- Nothing was picked for the slots left out. Handlers and OnLoad are the example\'s: item names in them',
        '-- (gFunc.Equip, weapon lists, settings) are not checked. Review, then save as ' .. tostring(info.job or '<JOB>') .. '.lua; /checksets after.',
    };
    for _, l in ipairs(wrap('-- Move to a wardrobe:', rep.move, function(v) return v[1] .. ' (' .. tostring(v[2]) .. ')' end)) do h[#h + 1] = l end
    for _, l in ipairs(wrap('-- Left out (slots):', rep.missing, function(v) return v[1] .. ' (' .. v[2] .. ')' end)) do h[#h + 1] = l end
    return table.concat(h, '\n') .. '\n' .. table.concat(lines, '\n') .. '\n', rep;
end

local JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG',
    'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' };
local BAGS = { [0] = 'Inventory', 'Safe', 'Storage', 'Temporary', 'Locker', 'Satchel', 'Sack', 'Case',
    'Wardrobe', 'Safe 2', 'Wardrobe 2', 'Wardrobe 3', 'Wardrobe 4', 'Wardrobe 5', 'Wardrobe 6', 'Wardrobe 7', 'Wardrobe 8' };
local EQUIP_BAGS = { 0, 8, 10, 11, 12, 13, 14, 15, 16 }; -- LAC's default gSettings.EquipBags

-- Every piece of equipment in every bag, by lower-case name.
local function owned_gear()
    local equippable = {};
    local bags = ((gSettings ~= nil) and (type(gSettings.EquipBags) == 'table')) and gSettings.EquipBags or EQUIP_BAGS;
    for _, c in pairs(bags) do equippable[c] = true end
    local inv, res = AshitaCore:GetMemoryManager():GetInventory(), AshitaCore:GetResourceManager();
    local owned = {};
    for c = 0, 16 do
        if (c ~= 3) then -- temporary items
            for i = 1, (gData.GetContainerMax(c) or 0) do
                local it = inv:GetContainerItem(c, i);
                local r = (it ~= nil) and (it.Id ~= 0) and (it.Id ~= 65535) and ((it.Count or 0) > 0) and res:GetItemById(it.Id) or nil;
                if (r ~= nil) and (r.Slots ~= 0) and (r.Name ~= nil) and (type(r.Name[1]) == 'string') then
                    local copy = { bag = BAGS[c] or tostring(c), equippable = (equippable[c] == true), augs = {} };
                    local ok, aug = pcall(gData.GetAugment, it);
                    if ok and (type(aug) == 'table') then
                        copy.path = aug.Path;
                        if (type(aug.Augs) == 'table') then
                            for _, v in pairs(aug.Augs) do
                                if (type(v) == 'table') and (type(v.String) == 'string') then copy.augs[#copy.augs + 1] = v.String end
                            end
                        end
                    end
                    local key = string.lower(r.Name[1]);
                    owned[key] = owned[key] or { name = r.Name[1], copies = {} };
                    table.insert(owned[key].copies, copy);
                end
            end
        end
    end
    return owned;
end

-- say / err: gcinclude's chat lines.
function gcbuild.Run(jobArg, say, err)
    if (windower ~= nil) then err('/gcbuild is Ashita only.'); return end
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local job = JOBS[player:GetMainJob()];
    if (jobArg ~= nil) then
        job = nil;
        for _, a in ipairs(JOBS) do
            if (a == string.upper(tostring(jobArg))) then job = a end
        end
        if (job == nil) then err('/gcbuild: no job ' .. tostring(jobArg)); return end
    end
    if (job == nil) then err('/gcbuild: no job yet'); return end
    local root = AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\';
    local f = io.open(root .. 'examples\\' .. job .. '.lua', 'rb');
    if (f == nil) then
        err('/gcbuild: no luashitacast\\examples\\' .. job .. '.lua: copy GoomSwap\'s examples folder into luashitacast.');
        return;
    end
    local template = f:read('*a');
    f:close();
    local text, rep = gcbuild.Build(template, owned_gear(), { name = gState.PlayerName, job = job, date = os.date('%Y-%m-%d') });
    if (text == nil) then err('/gcbuild: ' .. tostring(rep)); return end
    local file = job .. '.proposed.lua';
    local out = io.open(string.format('%s%s_%u\\%s', root, gState.PlayerName, gState.PlayerId, file), 'wb');
    if (out == nil) then err('/gcbuild: cannot write ' .. file); return end
    out:write(text);
    out:close();
    say(string.format('%s written to your character folder: %d of %d set slots kept, %d left out, %d by name only, %d to move to a wardrobe.',
        file, rep.kept, rep.slots, rep.dropped, rep.renamed, rep.moved));
end

return gcbuild;
