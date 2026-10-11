-- ShaySwap for Windower: just enough of ImGui to draw common/gchud.lua and the gcdisplay bar as Windower
-- text boxes, so those files run unchanged. Display only: buttons draw as text and never report a click
-- (use the commands). Boxes can be dragged; gchud/gcdisplay save the new position as they do on Ashita.
--
-- Layout: widths are measured in character cells (CalcTextSize = characters * CW), and the box uses a
-- monospace font, so the column positions gchud computes line up.
--
-- gchud and the bar make the same calls every frame until something changes. Each window keeps last
-- frame's items and rebuilds its text only when one differs; an unchanged frame skips the rebuild.

local I = {};
local CW, LH = 7, 14;           -- pixels per character cell / line, only used to convert gchud's positions
local ITEM_SPACING = 7;          -- SameLine() gap: one character cell (gchud pushes 4px, gcdisplay 6px)
local FONT, SIZE = 'Consolas', 10;

local windows = {};
local frame = 0;
local cur = nil;
local nextPos = nil;
local colorIdx, colorVal, colorN = {}, {}, 0; -- style color stack
local mouseDown = false;

local K = {
    ImGuiCol_Text = 0, ImGuiCol_WindowBg = 2, ImGuiCol_Border = 5, ImGuiCol_Button = 21,
    ImGuiCol_ButtonHovered = 22, ImGuiCol_ButtonActive = 23,
    ImGuiCond_Always = 1,
    ImGuiStyleVar_WindowPadding = 2, ImGuiStyleVar_FramePadding = 11, ImGuiStyleVar_ItemSpacing = 13,
    ImGuiWindowFlags_NoTitleBar = 1, ImGuiWindowFlags_NoResize = 2, ImGuiWindowFlags_NoScrollbar = 8,
    ImGuiWindowFlags_AlwaysAutoResize = 64, ImGuiWindowFlags_NoFocusOnAppearing = 4096,
};

local function channel(v) return math.max(0, math.min(255, math.floor((tonumber(v) or 1) * 255 + 0.5))) end

-- '\cs(r,g,b)' for a color table, made once per table (and again if its values change).
local prefixOf = setmetatable({}, { __mode = 'k' });
local function color_prefix(col)
    local r, g, b = col[1], col[2], col[3];
    local c = prefixOf[col];
    if (c ~= nil) and (c[1] == r) and (c[2] == g) and (c[3] == b) then return c[4] end
    local p = string.format('\\cs(%d,%d,%d)', channel(r), channel(g), channel(b));
    prefixOf[col] = { r, g, b, p };
    return p;
end

local function text_prefix()
    for i = colorN, 1, -1 do
        if (colorIdx[i] == K.ImGuiCol_Text) then return color_prefix(colorVal[i]) end
    end
    return nil;
end

local spaces = {};
local function pad(n)
    local s = spaces[n];
    if (s == nil) then s = string.rep(' ', n); spaces[n] = s end
    return s;
end

-- Items are kept in call order: { line, x, text, prefix }. A changed item marks the window dirty.
local function add_item(text, padPx)
    text = tostring(text or '');
    local w = cur;
    if (w == nil) then return end
    if w.hasItem and not w.same then w.line = w.line + 1 end
    local k = w.n + 1;
    w.n = k;
    local seg = w.segs[k];
    if (seg == nil) then seg = {}; w.segs[k] = seg end
    local pre = text_prefix();
    if (seg.line ~= w.line) or (seg.x ~= w.cx) or (seg.text ~= text) or (seg.pre ~= pre) then
        seg.line, seg.x, seg.text, seg.pre = w.line, w.cx, text, pre;
        w.dirty = true;
    end
    w.lastEnd = w.cx + #text * CW + (padPx or 0);
    w.cx = 0;
    w.same = false;
    w.hasItem = true;
end

local function strip_id(label) return (string.gsub(tostring(label or ''), '##.*$', '')) end

local function by_x(a, b) return a.x < b.x end

local function render(w)
    if (w.n == 0) then return '' end
    local lines = {};
    for k = 1, w.n do
        local seg = w.segs[k];
        local line = lines[seg.line];
        if (line == nil) then line = {}; lines[seg.line] = line end
        line[#line + 1] = seg;
    end
    local out = {};
    for li = 1, w.line do
        local line = lines[li] or {};
        table.sort(line, by_x);
        local s, pos = {}, 0;
        for _, seg in ipairs(line) do
            local col = math.floor(seg.x / CW + 0.5);
            if (col > pos) then s[#s + 1] = pad(col - pos); pos = col end
            if (seg.pre ~= nil) then
                s[#s + 1] = seg.pre .. seg.text .. '\\cr';
            else
                s[#s + 1] = seg.text;
            end
            pos = pos + #seg.text;
        end
        out[#out + 1] = table.concat(s);
    end
    return table.concat(out, '\n');
end

local imgui = setmetatable({
    Begin = function(name)
        local w = windows[name];
        if (w == nil) then
            w = { text = texts.new('', {
                pos = { x = 0, y = 0 },
                bg = { alpha = 115, red = 0, green = 0, blue = 0, visible = true },
                text = { font = FONT, size = SIZE, red = 255, green = 255, blue = 255 },
                flags = { draggable = true },
                padding = 2,
            }), shown = '', segs = {}, shownN = -1 };
            windows[name] = w;
        end
        if (nextPos ~= nil) then w.text:pos(nextPos[1], nextPos[2]); nextPos = nil end
        w.frame = frame;
        w.n, w.line, w.dirty = 0, 1, false;
        w.cx, w.lastEnd, w.same, w.hasItem, w.scale, w.bgAlpha = 0, 0, false, false, 1.0, nil;
        for i = colorN, 1, -1 do
            if (colorIdx[i] == K.ImGuiCol_WindowBg) then w.bgAlpha = colorVal[i][4]; break end
        end
        cur = w;
        return true;
    end,
    End = function()
        local w = cur;
        cur = nil;
        if (w == nil) then return end
        if w.dirty or (w.n ~= w.shownN) then
            local str = render(w);
            if (str ~= w.shown) then w.text:text(str); w.shown = str end
            w.shownN = w.n;
        end
        local size = math.max(6, math.floor(SIZE * (w.scale or 1) + 0.5));
        if (size ~= w.size) then w.text:size(size); w.size = size end
        if (w.bgAlpha ~= nil) and (w.bgAlpha ~= w.alpha) then w.text:bg_alpha(channel(w.bgAlpha)); w.alpha = w.bgAlpha end
        if not w.visible then w.text:show(); w.visible = true end
    end,
    Text = function(t) add_item(t) end,
    SmallButton = function(label) add_item(strip_id(label), 2); return false end,
    Button = function(label) add_item(strip_id(label), 2); return false end,
    SameLine = function(offset, spacing)
        if (cur == nil) then return end
        cur.same = true;
        if (tonumber(offset) ~= nil) and (offset > 0) then
            cur.cx = offset;
        else
            cur.cx = cur.lastEnd + (((tonumber(spacing) ~= nil) and (spacing >= 0)) and spacing or ITEM_SPACING);
        end
    end,
    SetCursorPosX = function(x) if (cur ~= nil) then cur.cx = tonumber(x) or 0 end end,
    GetCursorPosX = function() return (cur ~= nil) and cur.cx or 0 end,
    CalcTextSize = function(t) return #tostring(t or '') * CW, LH end,
    SetNextWindowPos = function(pos) if (type(pos) == 'table') then nextPos = { pos[1] or pos.x or 0, pos[2] or pos.y or 0 } end end,
    GetWindowPos = function()
        if (cur == nil) then return 0, 0 end
        return cur.text:pos();
    end,
    IsMouseDown = function() return mouseDown end,
    IsItemHovered = function() return false end,
    SetTooltip = function() end,
    GetIO = function() return { KeyCtrl = false } end,
    PushStyleColor = function(idx, col) colorN = colorN + 1; colorIdx[colorN], colorVal[colorN] = idx, col end,
    PopStyleColor = function(n)
        for _ = 1, (tonumber(n) or 1) do
            if (colorN > 0) then colorIdx[colorN], colorVal[colorN] = nil, nil; colorN = colorN - 1 end
        end
    end,
    PushStyleVar = function() end,
    PopStyleVar = function() end,
    SetWindowFontScale = function(s) if (cur ~= nil) then cur.scale = tonumber(s) or 1 end end,
}, { __index = function() return function() end end });

function I.BeginFrame()
    frame = frame + 1;
    for i = colorN, 1, -1 do colorIdx[i], colorVal[i] = nil, nil end
    colorN = 0;
end

-- Boxes not drawn this frame are hidden (gchud/gcdisplay draw only while switched on).
function I.EndFrame()
    for _, w in pairs(windows) do
        if w.visible and (w.frame ~= frame) then w.text:hide(); w.visible = false end
    end
end

function I.SetMouseDown(v) mouseDown = v end

function I.Install()
    windows, cur, nextPos = {}, nil, nil;
    for i = colorN, 1, -1 do colorIdx[i], colorVal[i] = nil, nil end
    colorN = 0;
    for k, v in pairs(K) do _G[k] = v end
    gearswap.package.loaded['imgui'] = imgui;
end

return I;
