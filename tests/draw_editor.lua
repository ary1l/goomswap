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
local player = { GetMainJob = function() return 3 end, GetMainJobLevel = function() return 99 end,
    GetSubJob = function() return 5 end, GetSubJobLevel = function() return 49 end }

AshitaCore = setmetatable({
    GetMemoryManager = function() return setmetatable({ GetPlayer = function() return player end },
        { __index = function() return function() return stub('mm') end end }) end,
    GetFontManager = function() return { GetVisible = function() return true end } end,
    GetGuiManager = function() return { GetVisible = function() return true end } end,
    GetInstallPath = function() return '/tmp/' end,
    GetResourceManager = function() return setmetatable({}, { __index = function() return nilf end }) end,
}, { __index = function() return function() return stub('core') end end })
gState = { PlayerName = 'Me', PlayerId = 1 }; gData = setmetatable({}, { __index = function() return nilf end })
gProfile = { FilePath = (arg[1] or 'examples/WHM.lua'), Sets = {} }
local cbs = {}
ashita = { fs = { exists = function() return false end, create_directory = function() end },
    events = { register = function(ev, n, f) cbs[n] = f end, unregister = function(ev, n) cbs[n] = nil end } }
SEEN = {}
local clicks, frame = {}, 0
local fail = nil
local imgui = setmetatable({}, { __index = function(_, k)
    if (k == 'CalcTextSize') then return function(t) return #tostring(t) * 7, 14 end end
    if (k == 'GetContentRegionAvail') or (k == 'GetWindowSize') then return function() return 900, 600 end end
    if (k == 'GetCursorScreenPos') or (k == 'GetWindowPos') or (k == 'GetItemRectMin') or (k == 'GetItemRectMax')
        or (k == 'GetCursorPos') or (k == 'GetMousePos') then return function() return 10, 10 end end
    if (k == 'GetCursorPosX') or (k == 'GetCursorPosY') or (k == 'GetWindowHeight') or (k == 'GetWindowWidth')
        or (k == 'GetTextLineHeight') or (k == 'GetTextLineHeightWithSpacing') or (k == 'GetFontSize')
        or (k == 'GetFrameHeight') or (k == 'GetScrollY') or (k == 'GetScrollMaxY') or (k == 'GetTime') then
        return function() return 16 end end
    if (k == 'GetColorU32') then return function() return 0 end end
    if (k == 'GetWindowDrawList') or (k == 'GetForegroundDrawList') then return function() return stub('dl') end end
    if (k == 'GetStyle') then return function() return { ItemSpacing = { x = 8, y = 4 }, FramePadding = { x = 4, y = 3 } } end end
    if (k == 'GetIO') then return function() return { DisplaySize = { x = 1920, y = 1080 }, KeyCtrl = false, KeyShift = false } end end
    if (k == 'Begin') or (k == 'BeginChild') or (k == 'BeginTabBar') or (k == 'BeginTable') then return function() return true end end
    if (k == 'Button') or (k == 'SmallButton') or (k == 'Selectable') or (k == 'MenuItem') then
        return function(label)
            label = tostring(label); SEEN[label] = true
            local id = string.match(label, '##(.*)$') or label
            if clicks[id] then clicks[id] = nil; return true end return false end
    end
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
local ok, err = pcall(gcedit.Open, include)
if not ok then print('OPEN ERROR ' .. tostring(err)) os.exit(1) end
local function draw(n) for i = 1, n or 1 do frame = frame + 1; local f = cbs['gcedit_render']; if f then
    local ok2, e2 = pcall(f); if not ok2 then print('FRAME ERROR ' .. tostring(e2)); os.exit(1) end end end end
draw(3)
local function has(l) return SEEN[l] and 'y' or 'n' end
print('main: Use worn ' .. has('Use worn##gcedit') .. ', Rules btn ' .. tostring((function() for k in pairs(SEEN) do if k:match('##gcedit_rules_top$') then return k end end end)()))
local seq = {}; for id in string.gmatch(arg[2] or 'gcedit_rules_top', '[^,]+') do seq[#seq + 1] = id end
for _, id in ipairs(seq) do clicks[id] = true; draw(2) end
print('after: New rule ' .. has('+ New rule##rules_add'))
for k in pairs(SEEN) do if arg[3] and k:match(arg[3]) then print('  ' .. k) end end
print(fail and ('FAILED ' .. fail) or 'drawn')
