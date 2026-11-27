-- Draw /gcedit frames against a stub ImGui: catches runtime errors in the editor's draw code (no picture).
-- luajit tests/draw_editor.lua [job file] [ids to click, in order, comma separated] [pattern: list drawn labels]
local function stub(name)
    local t
    t = setmetatable({}, { __index = function(_, k) return function() return t end end, __call = function() return t end,
        __concat = function(a, b) return tostring(a) .. tostring(b) end, __tostring = function() return name end })
    return t
end
gFunc = { LoadFile = function(p) return dofile((string.gsub(p, '\\', '/'))) end }
T = function(t) return t end
nilf = function() return nil end
-- two pieces in Wardrobe (bag 8) that fit every slot, so the gear picker has rows
ITEMS = { [23001] = { Name = { 'Nyame Mail' }, Slots = 0xFFFF, Jobs = 0x7FFFFFFE, Level = 1,
        Description = { 'DEF:150 HP+68 MP+44 MND+25 Damage taken -9%' } },
    [23002] = { Name = { 'Ebers Bliaut +2' }, Slots = 0xFFFF, Jobs = 0x7FFFFFFE, Level = 1,
        Description = { 'DEF:120 HP+60 MP+50 MND+30 Damage taken -10%' } } }
local inventory = { GetContainerItem = function(_, c, i)
    if c == 8 and i <= 2 then return { Id = 23000 + i, Count = 1, Extra = string.rep('\0', 24) } end
end }
local player = { GetMainJob = function() return 3 end, GetMainJobLevel = function() return 99 end,
    GetSubJob = function() return 5 end, GetSubJobLevel = function() return 49 end,
    HasAbility = function(_, id) return (id == 0x2A0) and (os.getenv('JA') ~= nil) end, HasSpell = function() return false end }

AshitaCore = setmetatable({
    GetMemoryManager = function() return setmetatable({ GetPlayer = function() return player end,
        GetInventory = function() return inventory end },
        { __index = function() return function() return stub('mm') end end }) end,
    GetFontManager = function() return { GetVisible = function() return true end } end,
    GetGuiManager = function() return { GetVisible = function() return true end } end,
    GetInstallPath = function() return '/tmp/' end,
    GetResourceManager = function() return setmetatable({ GetItemById = function(_, id) return ITEMS[id] end,
        -- JA=1: one job ability known (No Foot Rise, a resource id over 0x200), for the set list's + N to add
        GetAbilityById = function(_, id)
            if os.getenv('JA') and (id == 0x2A0) then return { Id = 0x2A0, Name = { 'No Foot Rise' } } end
            return nil
        end,
        GetString = function(_, key, id) -- JA=1: a buff by that ability's name (Buffs['No Foot Rise'] offered)
            if os.getenv('JA') and (key == 'buffs.names') and (id == 410) then return 'No Foot Rise' end
            return nil
        end,
        GetAbilityByName = function(_, n)
            if os.getenv('JA') and (n == 'No Foot Rise') then return { Id = 0x2A0, Name = { 'No Foot Rise' } } end
            return nil
        end },
        { __index = function() return nilf end }) end,
}, { __index = function() return function() return stub('core') end end })
gState = { PlayerName = 'Me', PlayerId = 1 }; gData = setmetatable({ GetContainerMax = function(c) return (c == 8) and 2 or 0 end },
    { __index = function() return nilf end })
gProfile = { FilePath = (arg[1] or 'examples/WHM.lua'), Sets = {} }
local cbs = {}
ashita = { fs = { exists = function() return false end, create_directory = function() end },
    events = { register = function(ev, n, f) cbs[n] = f end, unregister = function(ev, n) cbs[n] = nil end } }
SEEN = {}
local clicks, frame = {}, 0
local fail = nil
-- Argument types as Ashita's ImGui binding (sol) takes them: a wrong one is an error in game ("no matching function
-- call"), so it is one here too. A vector is a table; flags and sizes are numbers.
local SIG = {
    BeginChild = { 'string', 'table?', 'number?', 'number?' },
    Begin = { 'string', 'table?', 'number?' },
    Selectable = { 'string', 'boolean?', 'number?', 'table?' },
    Checkbox = { 'string', 'table' },
    Button = { 'string', 'table?' },
    SmallButton = { 'string' },
    InputTextWithHint = { 'string', 'string', 'table', 'number' },
    SetCursorPos = { 'table' }, SetCursorPosX = { 'number' }, SetCursorPosY = { 'number' },
    SameLine = { 'number?', 'number?' }, Indent = { 'number?' }, Unindent = { 'number?' },
    PushTextWrapPos = { 'number?' }, Dummy = { 'table' }, PushItemWidth = { 'number' },
    TextColored = { 'table', 'string' },
}
local function check_args(k, ...)
    local sig = SIG[k]
    if sig == nil then return end
    local args = { ... }
    for i, want in ipairs(sig) do
        local opt = string.sub(want, -1) == '?'
        local t = opt and string.sub(want, 1, -2) or want
        local v = args[i]
        if not ((v == nil and opt) or (type(v) == t)) then
            error(string.format('imgui.%s: argument %d is a %s, the binding takes a %s', k, i, type(v), want), 3)
        end
    end
end
local imgui = setmetatable({}, { __index = function(_, k)
    if (k == 'CalcTextSize') then return function(t) return #tostring(t) * 7, 14 end end
    if (k == 'GetContentRegionAvail') or (k == 'GetWindowSize') then return function() return 900, 600 end end
    if (k == 'GetCursorScreenPos') or (k == 'GetWindowPos') or (k == 'GetItemRectMin') or (k == 'GetItemRectMax')
        or (k == 'GetCursorPos') or (k == 'GetMousePos') then return function() return 10, 10 end end
    if (k == 'GetCursorPosY') then return function() CY = (CY or 0) + 18; return CY end end -- rows have height
    if (k == 'GetScrollY') then return nil end -- no clipping: every picker row is drawn
    if (k == 'GetCursorPosX') or (k == 'GetWindowHeight') or (k == 'GetWindowWidth')
        or (k == 'GetTextLineHeight') or (k == 'GetTextLineHeightWithSpacing') or (k == 'GetFontSize')
        or (k == 'GetFrameHeight') or (k == 'GetScrollY') or (k == 'GetScrollMaxY') or (k == 'GetTime') then
        return function() return 16 end end
    if (k == 'GetColorU32') then return function() return 0 end end
    if (k == 'GetWindowDrawList') or (k == 'GetForegroundDrawList') then return function() return stub('dl') end end
    if (k == 'GetStyle') then return function() return { ItemSpacing = { x = 8, y = 4 }, FramePadding = { x = 4, y = 3 } } end end
    if (k == 'GetIO') then return function() return { DisplaySize = { x = 1920, y = 1080 }, KeyCtrl = false, KeyShift = false } end end
    if k == 'TreeNodeEx' then return function(...) return true end end -- open, as SetNextItemOpen asks (the list's headings)
    if (k == 'Begin') or (k == 'BeginChild') or (k == 'BeginTabBar') or (k == 'BeginTable') then
        return function(...) check_args(k, ...) return true end
    end
    if (k == 'Button') or (k == 'SmallButton') or (k == 'Selectable') or (k == 'MenuItem') then
        return function(label, ...)
            check_args(k, label, ...)
            label = tostring(label); SEEN[label] = true
            local id = string.match(label, '##(.*)$') or label
            if clicks[label] then clicks[label] = nil; return true end
            if clicks[id] then clicks[id] = nil; if os.getenv("TRACE") then print("  clicked " .. label) end return true end return false end
    end
    if (k == 'TextColored') then return function(c, t) check_args(k, c, t) SEEN[tostring(t)] = true end end
    if (k == 'TextUnformatted') or (k == 'Text') then return function(t) SEEN[tostring(t)] = true end end
    if ((k == 'BeginPopup') or (k == 'BeginPopupModal')) and os.getenv('POPUP') then -- that popup held open
        return function(id) return tostring(id) == os.getenv('POPUP') end
    end
    if (k == 'IsItemHovered') and os.getenv('HOVER') then return function() return true end end -- every tooltip path
    if (k == 'IsItemClicked') then
        return function(b) if (b or 0) == 0 and CLICK_ITEM and CLICK_ITEM > 0 then CLICK_ITEM = CLICK_ITEM - 1
            return CLICK_ITEM == 0 end return false end
    end
    if SIG[k] ~= nil then return function(...) check_args(k, ...) return false end end
    return function() return false end
end })
package.preload['imgui'] = function() return imgui end
package.preload['common'] = function() return {} end
for _, m in ipairs({ 'd3d8', 'ffi', 'settings' }) do package.preload[m] = package.preload[m] or function() return stub(m) end end
chat = stub('chat')
package.preload['d3d8'] = function() return { get_device = function() return nil end } end
local gcedit = dofile('common/gcedit.lua')
local include = setmetatable({ Err = function(t) fail = fail or t; print('ERR ' .. tostring(t)) end,
    Say = function(t) end, sets = {}, settings = {}, CharConfig = {}, SharedConfig = {} },
    { __index = function(_, k) if string.match(k, '^%u') and not string.match(k, 'Config$') and k ~= 'Rules'
        and k ~= 'Settings' and k ~= 'RulesCompiled' then return nilf end return nil end })
local ok, err = pcall(gcedit.Open, include, os.getenv('OPENSET')) -- OPENSET: the set it opens on
if not ok then print('OPEN ERROR ' .. tostring(err)) os.exit(1) end
local function draw(n) for i = 1, n or 1 do frame = frame + 1; local f = cbs['gcedit_render']; if f then
    local ok2, e2 = pcall(f); if not ok2 then print('FRAME ERROR ' .. tostring(e2)); os.exit(1) end end end end
draw(3)
local function has(l) return SEEN[l] and 'y' or 'n' end
print('main: Use worn ' .. has('Use worn##gcedit') .. ', Rules btn ' .. tostring((function() for k in pairs(SEEN) do if k:match('##gcedit_rules_top$') then return k end end end)()))
local seq = {}; for id in string.gmatch(arg[2] or 'gcedit_rules_top', '[^,]+') do seq[#seq + 1] = id end
for _, id in ipairs(seq) do
    local n = tonumber(string.match(id, '^item(%d+)$'))
    if n then CLICK_ITEM = n else clicks[id] = true end
    draw(2)
    if os.getenv("TRACE") then print(id, SEEN[os.getenv("TRACE")] and "seen" or "-", gcedit.Dirty and tostring(gcedit.Dirty())) end
    if os.getenv('TRACE') then SEEN[os.getenv('TRACE')] = nil end
end
print('after: New rule ' .. has('+ New rule##rules_add'))
for k in pairs(SEEN) do if arg[3] and k:match(arg[3]) then print('  ' .. k) end end
print(fail and ('FAILED ' .. fail) or 'drawn')
