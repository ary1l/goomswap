-- Editor UI helpers: navigation, layout, item views, review, and opt-in timing.
-- Loaded once with gcedit. Each section owns its locals; no frame-loop I/O.
local ui = {}

-- == Elements ==
-- Elemental resistances as the game shows them: the element's icon (here a dot in its crystal colour), then the
-- value. Item text names them 'Fire+15' (the game's icon, decoded) or 'Fire resistance +15'. Dark gets a light ring
-- so it shows on a dark card. Fixed colours, as job colours: a theme never changes them.
local ELEMENT_COL = {
    Fire = { 0.93, 0.33, 0.27, 1 }, Ice = { 0.55, 0.86, 1.00, 1 }, Wind = { 0.42, 0.85, 0.42, 1 },
    Earth = { 0.86, 0.72, 0.32, 1 }, Lightning = { 0.72, 0.48, 1.00, 1 }, Water = { 0.32, 0.52, 1.00, 1 },
    Light = { 0.96, 0.96, 0.96, 1 }, Dark = { 0.36, 0.26, 0.46, 1 },
}
local ELEMENT_FIND = { 'Lightning', 'Fire', 'Ice', 'Wind', 'Earth', 'Water', 'Light', 'Dark' } -- Lightning before Light
local DARK_RING = { 0.80, 0.80, 0.86, 0.90 }
ui.ElementColors = ELEMENT_COL
local function cursor(imgui)
    local a, b = imgui.GetCursorScreenPos()
    if type(a) == 'table' then return tonumber(a.x or a[1]), tonumber(a.y or a[2]) end
    return tonumber(a), tonumber(b)
end
-- An element's dot, one text line square, at the cursor. False (nothing drawn) for a name that is not an element.
function ui.ElementDot(imgui, element)
    local col = ELEMENT_COL[element]
    if (col == nil) then return false end
    local h = imgui.GetTextLineHeight and imgui.GetTextLineHeight() or 14
    local x, y = cursor(imgui)
    imgui.Dummy({ h, h })
    if (x ~= nil) and (y ~= nil) and (imgui.GetWindowDrawList ~= nil) and (imgui.GetColorU32 ~= nil) then
        local dl, c = imgui.GetWindowDrawList(), { x + h / 2, y + h / 2 }
        dl:AddCircleFilled(c, h * 0.3, imgui.GetColorU32(col), 12)
        if (element == 'Dark') then dl:AddCircle(c, h * 0.3, imgui.GetColorU32(DARK_RING), 12, 1) end
    end
    return true
end
-- Text split into lines of runs: { t = text } or { e = element, v = '+15' }; false when no line names one.
local runCache, runCount = {}, 0
function ui.ElementRuns(value)
    local hit = runCache[value]
    if (hit ~= nil) then return hit end
    local out, any = {}, false
    for line in string.gmatch((value or '') .. '\n', '(.-)\n') do
        local runs, at = {}, 1
        while true do
            local best = nil
            for _, e in ipairs(ELEMENT_FIND) do
                local s, f, v = string.find(line, '%f[%a]' .. e .. ' resistance ?([+-]%d+)', at)
                if (s == nil) then s, f, v = string.find(line, '%f[%a]' .. e .. ' ?([+-]%d+)', at) end
                if (s ~= nil) and ((best == nil) or (s < best[1])) then best = { s, f, e, v } end
            end
            if (best == nil) then break end
            if (best[1] > at) then runs[#runs + 1] = { t = string.sub(line, at, best[1] - 1) } end
            runs[#runs + 1] = { e = best[3], v = best[4] }
            any, at = true, best[2] + 1
        end
        if (at <= #line) or (#runs == 0) then runs[#runs + 1] = { t = string.sub(line, at) } end
        out[#out + 1] = runs
    end
    if not any then out = false end
    if (runCount >= 64) then runCache, runCount = {}, 0 end
    runCache[value], runCount = out, runCount + 1
    return out
end
-- An item's resistances by element, in the game's order (its icons' order): { { e, v }... } nonzero only, .same the
-- value when every one matches (Carrier's Sash: all 8 at +15); nil when it names none. Cached by text.
local ELEMENT_ORDER = { 'Fire', 'Ice', 'Wind', 'Earth', 'Lightning', 'Water', 'Light', 'Dark' }
local totalCache, totalCount = {}, 0
function ui.ElementTotals(value)
    if (value == nil) or (value == '') then return nil end
    local hit = totalCache[value]
    if (hit ~= nil) then return hit or nil end
    local sum, out = {}, {}
    for _, runs in ipairs(ui.ElementRuns(value) or {}) do
        for _, r in ipairs(runs) do
            if (r.e ~= nil) then sum[r.e] = (sum[r.e] or 0) + (tonumber(r.v) or 0) end
        end
    end
    for _, e in ipairs(ELEMENT_ORDER) do
        if ((sum[e] or 0) ~= 0) then out[#out + 1] = { e = e, v = sum[e] } end
    end
    if (#out > 0) then
        out.same = out[1].v
        for _, o in ipairs(out) do
            if (o.v ~= out.same) then out.same = nil; break end
        end
    end
    if (totalCount >= 64) then totalCache, totalCount = {}, 0 end
    totalCache[value], totalCount = (#out > 0) and out or false, totalCount + 1
    return (#out > 0) and out or nil
end
-- A row of small element dots (a card's resistances): filled for a bonus, a ring for a penalty.
local DOT_AT = { 0, 0 }
function ui.ElementDots(imgui, list)
    local h = imgui.GetTextLineHeight and imgui.GetTextLineHeight() or 14
    local step, r = math.floor(h * 0.5 + 0.5), h * 0.2
    local x, y = cursor(imgui)
    imgui.Dummy({ step * #list, h })
    if (x == nil) or (y == nil) or (imgui.GetWindowDrawList == nil) or (imgui.GetColorU32 == nil) then return end
    local dl = imgui.GetWindowDrawList()
    for i, o in ipairs(list) do
        DOT_AT[1], DOT_AT[2] = x + step * (i - 0.5), y + h / 2
        local col = imgui.GetColorU32(ELEMENT_COL[o.e])
        if (o.v > 0) then dl:AddCircleFilled(DOT_AT, r, col, 10) else dl:AddCircle(DOT_AT, r, col, 10, 1.2) end
        if (o.e == 'Dark') and (o.v > 0) then dl:AddCircle(DOT_AT, r, imgui.GetColorU32(DARK_RING), 10, 1) end
    end
end
-- How wide ElementDots draws list.
function ui.ElementDotsWidth(imgui, list)
    local h = imgui.GetTextLineHeight and imgui.GetTextLineHeight() or 14
    return math.floor(h * 0.5 + 0.5) * #list
end
-- A block of item text: lines naming an element drawn as dot + value, the rest as text, stacked as one block.
function ui.StatText(imgui, value)
    local lines = ui.ElementRuns(value)
    if not lines then imgui.TextUnformatted(value); return end
    local spaced = (ImGuiStyleVar_ItemSpacing ~= nil) and (imgui.PushStyleVar ~= nil)
    if spaced then imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 0, 0 }) end
    for _, runs in ipairs(lines) do
        for i, r in ipairs(runs) do
            if (i > 1) then imgui.SameLine(0, 0) end
            if (r.e ~= nil) then
                ui.ElementDot(imgui, r.e)
                imgui.SameLine(0, 0)
                imgui.TextUnformatted(r.v)
            else
                imgui.TextUnformatted(r.t)
            end
        end
    end
    if spaced then imgui.PopStyleVar() end
end

-- == State ==
do
-- Editor memory per job file for this game session: the sets opened last (recent) and Getting started (start).
-- Kept in GcEditSession, a global, so it outlives Save's reload; nothing is written to disk. Spacing is a GoomSwap
-- setting (EditorSpacing, char.lua).
local state = {}

function state.Defaults()
    return {}
end

-- path: the job file. Its old <file>.gcedit-ui (where this was kept before) is removed.
function state.Load(path)
    GcEditSession = GcEditSession or {}
    local key = string.lower(tostring(path))
    if GcEditSession[key] == nil then
        GcEditSession[key] = state.Defaults()
        if type(path) == 'string' then os.remove(path .. '.gcedit-ui') end
    end
    return GcEditSession[key]
end

function state.Feedback(editor, text)
    editor.ui.feedback = { text = text, remaining = 3.5 }
end

function state.TickFeedback(editor, elapsed)
    local feedback = editor.ui.feedback
    if feedback then
        feedback.remaining = feedback.remaining - math.max(0, elapsed or 0)
        if feedback.remaining <= 0 then editor.ui.feedback = nil end
    end
    return editor.ui.feedback and editor.ui.feedback.text
end

-- Each group has one lifetime: document edits, inventory snapshot, navigation,
-- derived caches, undo history, profile identity, and transient UI controls.
function state.New(profile)
    profile = profile or {}
    return {
        document = {
            path = profile.path,
            sourcePath = profile.sourcePath,
            reloadCommand = profile.reloadCommand,
            file = profile.path and profile.path:match('[^\\/]+$'),
            edits = {},
            newSets = {},
            deleted = {},
            renames = {},
            renameRefs = {},
            newModes = {},
            revision = 0,
        },
        inventory = {},
        selection = { tab = profile.draft and 'fill' or 'action' },
        cache = {},
        history = { entries = {} },
        profile = { job = profile.job, level = profile.level },
        preferences = profile.preferences or state.Defaults(),
        ui = {
            open = { true },
            compareDiffOnly = { true },
            statLayers = { true },
            find = { '' },
            search = { '' },
            copyFind = { '' },
            cmtNote = { '' },
            issuesOnly = { false },
            editedOnly = { false },
            missingOnly = { false },
            needsRpOnly = { false },
            fold = profile.fold or {},
            anyJob = { false },
            wardOnly = { false },
            rpOnly = { false },
            augOnly = { false },
            newMode = { '' },
            newWm = { '' }, -- New /wm mode: its name, and whether it starts from the weapons you hold
            newWmWorn = { true },
            addCustom = { '' }, -- the set list's + add: a name of your own (a spell: Cure IV)
            overShow = 'all',
            overShowIgnored = { false },
            allRecs = { false },
            wi = { ms = {}, high = { false }, dt = { false }, hoxne = { false }, proc = { false }, buffs = {
                '',
            } },
        },
    }
end

function state.Select(editor, name, slot, tab)
    editor.selection.rules = false -- a set picked: the middle pane leaves the Rules page
    editor.selection.setName, editor.selection.slot = name, slot
    editor.cache.cover, editor.ui.drag = nil, nil
    editor.selection.tab = tab or (slot and 'gear') or (editor.selection.tab == 'summary' and 'summary') or 'action'
end

ui.State = state
end

-- == Panels ==
do
-- Panel geometry and common editor controls. No gear or file operations.
local panels = {}
local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

local densities = {
    -- Compact: icon cards (slot, bag and the icon; its name and stats on hover), half as wide: more of the rest fits
    -- 80: the card's padding (8 top and bottom), the slot line and the 40px icon, so the icon isn't cut at the bottom
    Compact = { spacing = { 4, 2 }, padding = { 5, 2 }, cardHeight = 80, card = 88, icon = 40, rowIcon = 20, names = false },
    -- Comfortable: each card names its piece and what is under it (108: a 2-line name still clears the rank line)
    Comfortable = { spacing = { 4, 2 }, padding = { 5, 2 }, cardHeight = 108, card = 176, icon = 32, rowIcon = 20, names = true },
}

function panels.Density(name)
    return densities[name] or densities.Compact
end

-- Literal colored text also handles stat strings containing percent signs.
function panels.Text(imgui, color, value, wrap)
    imgui.PushStyleColor(ImGuiCol_Text, color)
    if wrap then imgui.PushTextWrapPos(0) end
    imgui.TextUnformatted(value)
    if wrap then imgui.PopTextWrapPos() end
    imgui.PopStyleColor()
end

function panels.Tip(imgui, colors, text)
    if not imgui.IsItemHovered() then return end
    imgui.PushStyleColor(ImGuiCol_PopupBg, { 0.055, 0.06, 0.08, 1 })
    imgui.BeginTooltip()
    imgui.PushTextWrapPos(440)
    panels.Text(imgui, colors.text, text, false)
    imgui.PopTextWrapPos()
    imgui.EndTooltip()
    imgui.PopStyleColor()
end

-- The editor's first size: about 65% of the screen wide and 63% tall (at least 900 x 520, at most 1420 x 840), so it
-- leaves room around it: addons such as tHotBar act on clicks under the editor (they don't check whether one was
-- taken). 1920 wide: 1248, three slot cards a row; 2560 and up: 1420, four. Drag its corner to resize; ImGui keeps it.
-- The smallest it opens at or can be dragged to: two slot cards a row and a right pane still wide enough to read.
panels.MIN_SIZE = { 900, 500 }
function panels.WindowSize(width, height)
    width, height = width or 1700, height or 910
    local w = math.min(width - 32, math.max(panels.MIN_SIZE[1], math.min(1420, math.floor(width * 0.65))))
    local h = math.min(height - 32, math.max(panels.MIN_SIZE[2], math.min(840, math.floor(height * 0.63))))
    return { math.max(1, w), math.max(1, h) }
end

-- Fixed pane widths, no dragging: the set list about 34 characters wide (by the font), the middle four slot cards wide,
-- the right pane the rest; a narrow window gives the middle three, then two cards before the right pane goes under 380.
function panels.Layout(width, charW, spacing, card)
    local gap = 4
    spacing = spacing or 8
    local CARD = card or 176 -- a slot card's width: the spacing's (Compact's icon cards are narrower)
    local left = clamp(math.floor((charW or 7) * 34), 230, 300)
    local function middle_for(cols) return cols * CARD + (cols - 1) * spacing + 30 end
    local cols = 4
    while (cols > 2) and ((width - left - middle_for(cols) - 2 * gap) < 380) do cols = cols - 1 end
    if (width - left - middle_for(cols) - 2 * gap) < 300 then left = 200 end
    return { left = left, middle = middle_for(cols), gap = gap }
end

function panels.Grid(width, spacing, card)
    spacing = spacing or 8
    local least = math.floor((card or 176) * 0.82) -- a card narrows this far before a column goes
    local columns = clamp(math.floor((width + spacing) / (least + spacing)), 1, 4)
    return columns, math.max(40, math.floor((width - spacing * (columns - 1)) / columns))
end

-- A collapsing section header in the button greys: blue stays for what is selected.
function panels.Section(imgui, colors, label, flags)
    imgui.PushStyleColor(ImGuiCol_Header, colors.btn)
    imgui.PushStyleColor(ImGuiCol_HeaderHovered, colors.btnHi)
    local open = imgui.CollapsingHeader(label, flags or 0)
    imgui.PopStyleColor(2)
    return open
end

function panels.SameLineIfFits(imgui, required)
    imgui.SameLine()
    local available = imgui.GetContentRegionAvail()
    local width = type(available) == 'number' and available or (available.x or available[1])
    if width < required then imgui.NewLine() end
end

function panels.Tabs(imgui, colors, selected, entries)
    local available = imgui.GetContentRegionAvail()
    local width = type(available) == 'number' and available or (available.x or available[1])
    local found = false
    for _, entry in ipairs(entries) do
        if entry[2] == selected then found = true end
    end
    if not found then selected = entries[1][2] end
    local used = 0
    for _, entry in ipairs(entries) do
        local size = imgui.CalcTextSize(entry[1])
        local labelWidth = (type(size) == 'number' and size or (size.x or size[1])) + 18
        if used > 0 and used + labelWidth + 4 <= width then
            imgui.SameLine(0, 1) -- one segmented control
        else
            used = 0
        end
        local on = selected == entry[2]
        imgui.PushStyleColor(ImGuiCol_Button, on and colors.selBg or colors.chipBg or colors.btn)
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, on and colors.selBg or colors.btnHi)
        imgui.PushStyleColor(ImGuiCol_Text, on and colors.blue or colors.dim)
        if imgui.Button(entry[1] .. '###gcedit_tab_' .. entry[2]) then selected = entry[2] end
        imgui.PopStyleColor(3)
        used = used + labelWidth + 4
    end
    return selected
end

-- Static completion reward. Uses the existing PNG cache and measured wrap cache.
function panels.FillComplete(imgui, colors, drawImage)
    local width, height = imgui.GetContentRegionAvail()
    if type(width) ~= 'number' then width, height = width.x or width[1], width.y or width[2] end
    width, height = math.max(1, width or 1), math.max(1, height or 1)
    local frameWidth = math.max(1, math.min(420, width - 16))
    local textWidth = math.max(1, frameWidth - 32)
    local heading, headingLines = ui.Tooltip.Wrap(imgui, 'Nothing left to fill.', textWidth)
    local detail, detailLines = ui.Tooltip.Wrap(imgui, 'All listed gear is owned and accessible.', textWidth)
    local line = imgui.GetTextLineHeightWithSpacing()
    local textHeight = line * (headingLines + detailLines + 1)
    local imageHeight = math.min(168, math.max(48, height - textHeight - 76))
    local imageWidth = imageHeight * 393 / 388 -- visible alpha bounds of the unchanged source PNG
    if imageWidth > math.max(1, frameWidth - 64) then
        imageWidth = math.max(1, frameWidth - 64); imageHeight = imageWidth * 388 / 393
    end
    local frameHeight = imageHeight + textHeight + 76
    local x, y = imgui.GetCursorPosX(), imgui.GetCursorPosY()
    imgui.SetCursorPosX(x + math.max(0, (width - frameWidth) / 2))
    imgui.SetCursorPosY(y + math.max(0, (height - frameHeight) / 2))
    imgui.PushStyleColor(ImGuiCol_ChildBg, colors.cell)
    imgui.PushStyleColor(ImGuiCol_Border, colors.edge)
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 16, 16 })
    local rounded = ImGuiStyleVar_ChildRounding ~= nil
    if rounded then imgui.PushStyleVar(ImGuiStyleVar_ChildRounding, 10) end
    imgui.BeginChild('##gcedit_fill_reward', { frameWidth, frameHeight },
        ImGuiChildFlags_Borders or 1, ImGuiWindowFlags_NoScrollbar or 0)
    local inner = imgui.GetContentRegionAvail()
    inner = type(inner) == 'number' and inner or (inner.x or inner[1])
    local left = imgui.GetCursorPosX()
    imgui.SetCursorPosX(left + math.max(0, (inner - imageWidth) / 2))
    local sx, sy = imgui.GetCursorScreenPos()
    if type(sx) ~= 'number' then sx, sy = sx.x or sx[1], sx.y or sx[2] end
    -- Render only the occupied UV region; no resampling/editing of the asset file.
    if not drawImage('goomy_shiny.png', imageWidth, imageHeight, { 60 / 512, 116 / 512 }, { 453 / 512, 504 / 512 }) then
        imgui.Dummy({ imageWidth, imageHeight })
    end
    if imgui.GetWindowDrawList and imgui.GetColorU32 then
        local draw, color = imgui.GetWindowDrawList(), imgui.GetColorU32(colors.shiny)
        for _, glint in ipairs({ { sx - 8, sy + imageHeight * 0.65 }, { sx + imageWidth + 8,
            sy + imageHeight * 0.23 } }) do
            draw:AddRectFilled({ glint[1] - 4, glint[2] }, { glint[1] + 5, glint[2] + 1 }, color)
            draw:AddRectFilled({ glint[1], glint[2] - 4 }, { glint[1] + 1, glint[2] + 5 }, color)
        end
    end
    imgui.Dummy({ 0, 12 })
    local function centered(value, color)
        for row in (value .. '\n'):gmatch('(.-)\n') do
            local measured = imgui.CalcTextSize(row)
            measured = type(measured) == 'number' and measured or (measured.x or measured[1])
            imgui.SetCursorPosX(left + math.max(0, (inner - measured) / 2))
            panels.Text(imgui, color, row)
        end
    end
    centered(heading, colors.ok)
    centered('For now.', colors.text)
    imgui.Dummy({ 0, 6 })
    centered(detail, colors.dim)
    imgui.EndChild()
    if rounded then imgui.PopStyleVar() end
    imgui.PopStyleVar()
    imgui.PopStyleColor(2)
end

ui.Panels = panels
end

-- == Card ==
do
-- Bound card labels by measured width; full strings stay available on hover.
local cardText = {}

function cardText.Fit(text, width, measure)
    if measure(text) <= width then return text end
    local suffix = '...'
    while #suffix > 0 and measure(suffix) > width do
        suffix = suffix:sub(1, -2)
    end
    while #text > 0 and measure(text .. suffix) > width do
        local at = #text
        while at > 1 and text:byte(at) >= 128 and text:byte(at) < 192 do
            at = at - 1
        end
        text = text:sub(1, at - 1)
    end
    return text .. suffix
end

function cardText.Name(text, width, measure)
    if measure(text) <= width then return text end
    local first = ''
    for word in string.gmatch(text, '%S+') do
        local candidate = first == '' and word or first .. ' ' .. word
        if measure(candidate) > width then break end
        first = candidate
    end
    if first == '' then return cardText.Fit(text, width, measure) end
    local rest = string.match(string.sub(text, #first + 1), '^%s*(.*)$')
    return first .. '\n' .. cardText.Fit(rest, width, measure)
end

function cardText.Bag(bag)
    if not bag then return 'Missing' end
    return string
        .gsub(bag, '^Wardrobe%s*(%d*)$', function(n) return 'W' .. (n == '' and '1' or n) end)
        :gsub('^Inventory$', 'Inv')
end

ui.Card = cardText
end

-- == Picker ==
do
local picker = {}

function picker.HasAugments(gear)
    return gear.rank ~= nil or gear.path ~= nil or #(gear.displayAugs or gear.augs or {}) > 0
end

function picker.Accept(gear, search, accessible, rpOnly, augmentedOnly)
    if accessible and not gear.equippable then return false end
    if rpOnly and not (gear.progress and gear.progress.unfinished) then return false end
    if augmentedOnly and not picker.HasAugments(gear) then return false end
    local haystack = gear.search or gear.lname
    -- Words may occur anywhere, so 'nyame damage' finds decoded ranked stats.
    for word in string.gmatch(string.lower(search or ''), '%S+') do
        if not string.find(haystack, word, 1, true) then return false end
    end
    return true
end

function picker.Caption(gear, isSelected)
    local details = {}
    if isSelected then details[#details + 1] = type(isSelected) == 'string' and isSelected or 'Selected' end
    if gear.path then details[#details + 1] = gear.path end
    if gear.rank ~= nil then details[#details + 1] = 'R' .. gear.rank .. (gear.cap and ('/' .. gear.cap) or '') end
    if gear.progress and gear.progress.unfinished then details[#details + 1] = 'RP' end
    if #details == 0 and picker.HasAugments(gear) then details[1] = 'Aug' end
    return gear.name .. (#details > 0 and ('  [' .. table.concat(details, ' / ') .. ']') or '')
end

-- One stable bag column; the tooltip retains the complete list of copies.
function picker.BagCaption(bags, primary)
    local seen, count = {}, 0
    for _, bag in ipairs(bags or {}) do
        if not seen[bag] then seen[bag], count = true, count + 1 end
    end
    return (primary or (bags and bags[1]) or 'Unknown') .. (count > 1 and (' +' .. (count - 1)) or '')
end

function picker.BagColumn(width)
    local bagWidth = math.max(76, math.min(126, width * 0.32))
    return math.max(80, width - bagWidth), bagWidth
end
-- The access marker has its own space; HQ icon borders cannot cover it.

function picker.DrawAccessMarker(imgui, colors, accessible, height)
    local start = imgui.GetCursorScreenPos()
    local x, y
    if type(start) == 'table' then
        x, y = start.x or start[1], start.y or start[2]
    elseif type(start) == 'number' then
        x, y = imgui.GetCursorScreenPos()
    else
        x, y = start.x, start.y
    end
    imgui.GetWindowDrawList():AddRectFilled(
        { x, y + 1 }, { x + 4, y + height - 1 }, imgui.GetColorU32(accessible and colors.ok or colors.warn), 1
    )
    imgui.Dummy({ 4, height })
    imgui.SameLine(0, 5)
end

ui.Picker = picker
end

-- == Tooltip ==
do
-- Structured, literal-text item tooltips shared by cards and the gear picker.
local tooltip = {}
tooltip.ElementTotals, tooltip.ElementDots, tooltip.ElementDotsWidth = ui.ElementTotals, ui.ElementDots,
    ui.ElementDotsWidth -- the gear cards' resistances
local wraps, wrapOrder, wrapIndex = {}, {}, 0
local wrapUi, wrapFont, wrapMeasure
local hover

function tooltip.Reset()
    wraps, wrapOrder, wrapIndex = {}, {}, 0
    wrapUi, wrapFont, wrapMeasure, hover = nil, nil, nil, nil
end

-- Count display time rather than process CPU time, including on an idle client.
function tooltip.HoverReady(imgui, key, frame)
    if not hover or hover.key ~= key or hover.frame < frame - 1 then
        hover = { key = key, frame = frame, elapsed = 0 }
    end
    if hover.frame ~= frame then
        local io = imgui.GetIO()
        hover.elapsed = hover.elapsed + math.min(io.DeltaTime or 1 / 60, 0.1)
        hover.frame = frame
    end
    return hover.elapsed >= 0.15
end

function tooltip.Model(value, owned, options)
    options = options or {}
    local item = {
        name = value.name,
        metadata = {},
        augments = {},
        notes = {},
        description = options.description,
        replacement = options.replacement,
        comparison = options.comparison,
    }
    if options.rule then
        item.metadata[1] = 'Equipment rule'
        item.notes[1] = 'This is a LuAshitacast directive, not an inventory item.'
        if string.lower(value.name) == 'displaced' then
            item.description = 'Marks a slot emptied by another equipped item, such as an instrument, ammo, or a two-handed weapon.'
            item.notes[2] = 'Displaced does not request an unequip.'
        end
        return item
    end
    item.metadata[1] = options.bag or (owned and owned.bag) or 'Not owned'
    local path = value.path or (owned and owned.path)
    local rank = value.rank or (owned and owned.rank)
    if path then item.metadata[#item.metadata + 1] = 'Path ' .. path end
    if rank ~= nil and not (owned and owned.progress and not owned.progress.unknown) then
        item.metadata[#item.metadata + 1] = 'R' .. rank
    end
    local progress = owned and owned.progress
    if progress and (progress.unfinished or not progress.unknown) then
        item.status = progress.label
    elseif progress and progress.unknown then
        item.notes[#item.notes + 1] = 'Rank limit could not be decoded.'
    end
    if owned and type(owned.augs) == 'table' then
        for _, text in ipairs(owned.displayAugs or owned.augs) do
            item.augments[#item.augments + 1] = text
        end
    end
    if #item.augments == 0 and type(value.augs) == 'string' and value.augs ~= '' then
        item.augments[1] = value.augs
        item.augmentTitle = 'Set augments'
    end
    if owned and owned.unreadable then item.notes[#item.notes + 1] = 'Rank bonus stats unavailable.' end
    if options.equippable == false then item.notes[#item.notes + 1] = 'Move to Inventory or a wardrobe to equip.' end
    if options.bags and #options.bags > 1 then
        item.notes[#item.notes + 1] = 'Copies: ' .. table.concat(options.bags, ', ')
    end
    if options.otherSlot then item.notes[#item.notes + 1] = 'Also used in ' .. options.otherSlot .. '.' end
    if options.usedIn then item.notes[#item.notes + 1] = options.usedIn end -- 'In 9 sets of COR.lua: ...'
    return item
end
-- Read vectors from either Lua tables or the binding's native vector type.
local function component(v, name, index, fallback)
    local ok, value = pcall(function() return v[name] or v[index] end)
    return (ok and tonumber(value)) or fallback
end

local function measure(imgui, value, fontSize)
    if imgui.CalcTextSize then
        local size = imgui.CalcTextSize(value)
        if type(size) == 'number' then return size end
        return component(size, 'x', 1, #value * fontSize * 0.55)
    end
    return #value * fontSize * 0.55
end

-- Explicit line breaks avoid depending on an auto-sized window's work rectangle.

function tooltip.Wrap(imgui, value, width, fontSize)
    if wrapUi ~= imgui or wrapFont ~= fontSize or wrapMeasure ~= imgui.CalcTextSize then
        wraps, wrapOrder, wrapIndex = {}, {}, 0
        wrapUi, wrapFont, wrapMeasure = imgui, fontSize, imgui.CalcTextSize
    end
    local key = tostring(width) .. '\0' .. (value or '')
    local cached = wraps[key]
    if cached then return cached.text, cached.lines end
    local lines = {}
    local function append(word, line)
        local candidate = line == '' and word or (line .. ' ' .. word)
        if measure(imgui, candidate, fontSize) <= width then return candidate end
        if line ~= '' then
            lines[#lines + 1] = line
            line = ''
        end
        if measure(imgui, word, fontSize) <= width then return word end
        -- Split a long token on UTF-8 boundaries if it cannot fit a whole line.
        local part = line
        for character in string.gmatch(word, '[%z\1-\127\194-\244][\128-\191]*') do
            local nextPart = (part == line and line ~= '') and (part .. ' ' .. character) or (part .. character)
            if measure(imgui, nextPart, fontSize) > width and part ~= '' then
                lines[#lines + 1] = part
                part = character
                line = ''
            else
                part = nextPart
            end
        end
        return part
    end
    for paragraph in string.gmatch((value or '') .. '\n', '(.-)\n') do
        local line = ''
        for word in string.gmatch(paragraph, '%S+') do
            line = append(word, line)
        end
        lines[#lines + 1] = line
    end
    local result = { text = table.concat(lines, '\n'), lines = #lines }
    wrapIndex = wrapIndex % 64 + 1
    local previous = wrapOrder[wrapIndex]
    if previous then wraps[previous] = nil end
    wrapOrder[wrapIndex], wraps[key] = key, result
    return result.text, result.lines
end

function tooltip.Layout(imgui, item, embedded)
    local io = imgui.GetIO and imgui.GetIO() or {}
    local display = io.DisplaySize
    local fontSize = imgui.GetFontSize and imgui.GetFontSize() or 16
    local screenWidth = component(display, 'x', 1, 1280)
    local screenHeight = component(display, 'y', 2, 720)
    local width = math.min(560, fontSize * 35, math.max(120, screenWidth - 48))
    if embedded then
        local available = imgui.GetContentRegionAvail and imgui.GetContentRegionAvail()
        width = math.max(120, type(available) == 'number' and available or component(available, 'x', 1, 400))
    elseif #item.augments == 0 then
        local longest = measure(imgui, item.name, fontSize)
        for line in string.gmatch((item.description or '') .. '\n', '(.-)\n') do
            longest = math.max(longest, measure(imgui, line, fontSize))
        end
        width = math.min(width, math.max(fontSize * 20, longest))
    end
    local gap = 20
    local columns = #item.augments > 0 and width >= fontSize * 29
    local baseWidth = columns and math.floor((width - gap) * 0.59) or width
    local augWidth = columns and (width - gap - baseWidth) or width
    local base, baseLines =
        tooltip.Wrap(imgui, item.description or 'No base description available.', baseWidth, fontSize)
    if base == '' then base = 'No base description available.' end
    local augments, augLines = tooltip.Wrap(imgui, table.concat(item.augments, '\n'), augWidth, fontSize)
    local bodyLines = columns and math.max(baseLines, augLines)
        or (baseLines + (#item.augments > 0 and (augLines + 2) or 0))
    local lineHeight = imgui.GetTextLineHeightWithSpacing and imgui.GetTextLineHeightWithSpacing() or (fontSize + 4)
    local headerLines = 2 + (item.status and 1 or 0)
    local footerLines = #item.notes + (item.comparison and 2 or 0) + (item.replacement and 2 or 0)
    local maxBody = math.min(430, math.max(60, screenHeight - (headerLines + footerLines + 5) * lineHeight - 48))
    return {
        width = width,
        baseWidth = baseWidth,
        augWidth = augWidth,
        gap = gap,
        columns = columns,
        base = base,
        augments = augments,
        fontSize = fontSize,
        maxBody = maxBody,
        bounded = not embedded and ((bodyLines + 2) * lineHeight > maxBody),
        screenWidth = screenWidth,
        screenHeight = screenHeight, heightEstimate = math.min((bodyLines + 2) * lineHeight, maxBody)
            + (headerLines + footerLines + 4) * lineHeight
            + 24,
    }
end

local lastPopup

local BACKGROUND = { 0.055, 0.060, 0.075, 1 }
local BORDER = { 0.23, 0.26, 0.32, 1 }
local SEPARATOR = { 0.18, 0.21, 0.26, 1 }

function tooltip.Draw(imgui, colors, item, embedded, bodyOnly)
    local layout = tooltip.Layout(imgui, item, embedded)
    local styles = 0
    local popupKey = item.name
        .. '\0'
        .. layout.maxBody
        .. '\0'
        .. tostring(item.comparison)
        .. '\0'
        .. layout.width
        .. '\0'
        .. layout.fontSize
        .. '\0'
        .. (item.description or '')
        .. '\0'
        .. table.concat(item.augments, '\0')
        .. '\0'
        .. tostring(item.status)
        .. '\0'
        .. tostring(item.replacement)
        .. '\0' .. table.concat(item.metadata, '\0') .. '\0' .. table.concat(item.notes, '\0')
    if not embedded then
        -- Clamp the whole card when no quadrant around the pointer fits it.
        if imgui.SetNextWindowPos then
            local io = imgui.GetIO and imgui.GetIO() or {}
            local mouse = io.MousePos
            local mouseX = component(mouse, 'x', 1, layout.screenWidth / 2)
            local mouseY = component(mouse, 'y', 2, layout.screenHeight / 2)
            local popupWidth = lastPopup and lastPopup.key == popupKey and lastPopup.width or (layout.width + 24)
            local popupHeight = lastPopup and lastPopup.key == popupKey and lastPopup.height or layout.heightEstimate
            local x, y = mouseX + 18, mouseY + 18
            if x + popupWidth > layout.screenWidth - 8 then x = mouseX - popupWidth - 18 end
            if y + popupHeight > layout.screenHeight - 8 then y = mouseY - popupHeight - 18 end
            x = math.max(8, math.min(x, layout.screenWidth - popupWidth - 8))
            y = math.max(8, math.min(y, layout.screenHeight - popupHeight - 8))
            imgui.SetNextWindowPos({ x, y })
        end
        imgui.PushStyleColor(ImGuiCol_PopupBg, BACKGROUND)
        imgui.PushStyleColor(ImGuiCol_ChildBg, BACKGROUND)
        imgui.PushStyleColor(ImGuiCol_Border, BORDER)
        imgui.PushStyleColor(ImGuiCol_Separator, SEPARATOR)
        if imgui.PushStyleVar then
            if ImGuiStyleVar_WindowPadding then
                imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 14, 12 })
                styles = styles + 1
            end
            if ImGuiStyleVar_ItemSpacing then
                imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 6, 4 })
                styles = styles + 1
            end
        end
        imgui.BeginTooltip()
    end
    -- Disable inherited wrapping. Every text run below is wrapped using measured pixels.
    imgui.PushTextWrapPos(-1)
    local function text(value, color, width)
        local wrapped = tooltip.Wrap(imgui, value, width or layout.width, layout.fontSize)
        imgui.PushStyleColor(ImGuiCol_Text, color)
        imgui.TextUnformatted(wrapped)
        imgui.PopStyleColor()
    end
    -- Reserve the width before auto-sizing the tooltip or opening a child.
    imgui.Dummy({ layout.width, 0 })
    if not bodyOnly then
        text(item.name, colors.blue)
        text(table.concat(item.metadata, '  |  '), colors.dim)
        if item.status then
            text(item.status, string.find(item.status, 'At current cap', 1,
                true) and colors.ok or (colors.rp or colors.warn))
        end
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
    end
    if layout.bounded then imgui.BeginChild('##item_stats_hover', { layout.width, layout.maxBody }, 0) end
    local function section(title, value, color, width)
        imgui.BeginGroup()
        imgui.PushStyleColor(ImGuiCol_Text, color)
        imgui.TextUnformatted(title)
        imgui.PopStyleColor()
        imgui.PushStyleColor(ImGuiCol_Text, colors.text)
        ui.StatText(imgui, value)
        imgui.PopStyleColor()
        imgui.Dummy({ width, 0 })
        imgui.EndGroup()
    end
    section('Base stats', layout.base, colors.dim, layout.baseWidth)
    if #item.augments > 0 then
        if layout.columns then
            imgui.SameLine(0, layout.gap)
        else
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
        end
        section(item.augmentTitle or 'Augments', layout.augments, colors.aug, layout.augWidth)
    end
    if layout.bounded then imgui.EndChild() end
    if #item.notes > 0 or item.replacement or item.comparison or layout.bounded then
        imgui.Spacing()
        imgui.Separator()
        for _, note in ipairs(item.notes) do
            text(note, colors.dim)
        end
        if item.replacement then text('Replaced by ' .. item.replacement, colors.override or colors.dim) end
        if item.comparison then text(item.comparison, colors.aug) end
        if layout.bounded then text('Full details: right-click item > Inspect item below grid', colors.dim) end
    end
    imgui.PopTextWrapPos()
    if not embedded then
        if imgui.GetWindowSize then
            local size, height = imgui.GetWindowSize()
            local width = type(size) == 'number' and size or component(size, 'x', 1, layout.width + 24)
            height = height or component(size, 'y', 2, layout.heightEstimate)
            if width > 0 and height > 0 then lastPopup = { key = popupKey, width = width, height = height } end
        end
        imgui.EndTooltip()
        if styles > 0 then imgui.PopStyleVar(styles) end
        imgui.PopStyleColor(4)
    end
end

ui.Tooltip = tooltip
end

-- == Inspect ==
do
-- Persistent item snapshots and set-definition comparison views.
local inspect = {}

local function wrappedText(imgui, color, text)
    imgui.PushStyleColor(ImGuiCol_Text, color)
    imgui.PushTextWrapPos(0)
    imgui.TextUnformatted(text)
    imgui.PopTextWrapPos()
    imgui.PopStyleColor()
end

function inspect.Pin(editor, sourceSet, slot, model, source)
    editor.ui.pinned = { set = sourceSet, slot = slot, item = model, source = source }
end

function inspect.Key(value)
    if not value then return '' end
    if value.kind == 'code' then return 'code\0' .. (value.raw or '') end
    return table.concat({
        string.lower(value.name or value.raw or ''),
        type(value.augs) == 'string' and value.augs or '',
        tostring(value.path or ''),
        tostring(value.rank or ''),
    }, '\0')
end

function inspect.Rows(slots, left, right, current, differencesOnly)
    local rows, total = {}, 0
    for _, slot in ipairs(slots) do
        local leftValue, rightValue = current(left, slot), current(right, slot)
        local different = inspect.Key(leftValue) ~= inspect.Key(rightValue)
        if different then total = total + 1 end
        if different or not differencesOnly then
            rows[#rows + 1] = { slot = slot, left = leftValue, right = rightValue, different = different }
        end
    end
    return rows, total
end

function inspect.Value(value)
    if not value then return 'Unchanged' end
    if value.kind == 'code' then return value.raw end
    local lines = { value.name or value.raw or 'Unchanged' }
    if value.path then lines[#lines + 1] = 'Path ' .. value.path end
    if value.rank then lines[#lines + 1] = 'Rank ' .. value.rank end
    if value.augs and value.augs ~= '' then lines[#lines + 1] = value.augs end
    return table.concat(lines, '\n')
end

function inspect.DrawPinned(imgui, colors, editor, tooltip, height, drawIcon)
    local pinned = editor.ui.pinned
    if not pinned then return end
    imgui.BeginChild('##gcedit_inspector', { 0, height }, ImGuiChildFlags_Borders or 1)
    local available = imgui.GetContentRegionAvail()
    local width = type(available) == 'number' and available or (available.x or available[1])
    local x, y = imgui.GetCursorPosX(), imgui.GetCursorPosY()
    local closeSize = imgui.CalcTextSize('Close')
    local closeWidth = (type(closeSize) == 'number' and closeSize or (closeSize.x or closeSize[1])) + 18
    imgui.SetCursorPosX(x + math.max(0, width - closeWidth))
    if imgui.SmallButton('Close##gcedit_inspector') then
        editor.ui.pinned = nil
        imgui.EndChild()
        return
    end
    imgui.SetCursorPosX(x)
    imgui.SetCursorPosY(y)
    if drawIcon then drawIcon(pinned.item.id, 28); imgui.SameLine() end
    local name = tooltip.Wrap(imgui, pinned.item.name, math.max(80, width - closeWidth - (drawIcon and 44 or 8)))
    imgui.TextColored(colors.blue, name)
    imgui.SetCursorPosY(math.max(imgui.GetCursorPosY(), y + (drawIcon and 32 or 0)))
    local metadata = table.concat(pinned.item.metadata, '  |  ')
    if pinned.item.status then metadata = metadata .. '  |  ' .. pinned.item.status:gsub('^At current cap: ', '') end
    wrappedText(imgui, pinned.item.status and pinned.item.status:find('Needs RP', 1, true)
        and (colors.rp or colors.warn) or colors.dim, metadata)
    wrappedText(imgui, colors.dim, pinned.set .. ' / ' .. pinned.slot
        .. (pinned.source and ('  -  ' .. pinned.source) or ''))
    imgui.Separator()
    imgui.BeginChild('##gcedit_pinned_stats', { 0, 0 }, 0)
    tooltip.Draw(imgui, colors, pinned.item, true, true)
    imgui.EndChild()
    imgui.EndChild()
end

function inspect.DrawComparison(imgui, colors, editor, set, other, slots, current, copy, leftStats,
    rightStats, statPair)
    if not other then
        imgui.TextWrapped('Choose Compare above the gear grid, then select another set.')
        return
    end
    wrappedText(imgui, colors.blue, set.name .. ' vs ' .. other.name)
    if imgui.SmallButton('Change set##compare_choose') then
        editor.ui.copyFind[1], editor.ui.pickMode, editor.ui.openSetChooser = '', 'compare', true
    end
    if leftStats and rightStats then
        editor.ui.compareView = ui.Panels.Tabs(imgui, colors, editor.ui.compareView or 'stats',
            { { 'Stats', 'stats' }, { 'Gear changes', 'definitions' } })
    end
    imgui.Checkbox('Differences only##gcedit', editor.ui.compareDiffOnly)
    ui.Panels.Tip(imgui, colors,
        'Stats hides equal totals. Gear changes hides matching item definitions.\nA different item can have the same listed stats.')
    local rows, total, definitionTotal
    if statPair and statPair.gearRows then
        rows, total, definitionTotal = statPair.gearRows, statPair.gearDifferences, statPair.definitionDifferences
    else rows, total = inspect.Rows(slots, set, other, current, false); definitionTotal = total end
    wrappedText(
        imgui,
        colors.dim,
        leftStats and (total .. ' differing gear slots.')
            or (total .. ' differing slots. Definitions shown; Unchanged keeps earlier gear.')
    )
    ui.Panels.Tip(imgui, colors, 'Compares winning items, paths, ranks and augment selectors in all 16 slots.\n'
        .. 'With inheritance enabled, earlier layers fill omitted slots. Unknown slots are not assumed to be worn gear.\n'
        .. 'The grid outlines the same differences. This count is gear slots, not stat rows.')
    if definitionTotal > 0 then
        if imgui.Button('Copy definition...##compare_copy') then imgui.OpenPopup('##compare_confirm') end
        ui.Panels.Tip(imgui, colors, 'Review a copy of the other set\'s written definition into the current set.\n'
            .. 'Inherited items are not copied. Empty source slots remove your overrides. Save remains separate.')
    end
    if imgui.BeginPopup('##compare_confirm') then
        imgui.PushTextWrapPos(440)
        imgui.TextUnformatted(
            'Copy only the written definition into '
                .. set.name
                .. ' from '
                .. other.name
                .. '? Inherited gear is not copied. Source gaps remove target overrides. Slots written as Lua stay unchanged.'
        )
        imgui.PopTextWrapPos()
        if imgui.Button('Copy definition##compare_apply') then
            copy(set, other)
            imgui.CloseCurrentPopup()
        end
        imgui.SameLine()
        if imgui.Button('Cancel##compare_cancel') then imgui.CloseCurrentPopup() end
        imgui.EndPopup()
    end
    if leftStats and rightStats and editor.ui.compareView == 'stats' then
        ui.Stats.DrawComparison(imgui, colors, set.name, other.name, statPair, editor.ui.compareDiffOnly[1])
        return
    end
    if #rows == 0 or (total == 0 and editor.ui.compareDiffOnly[1]) then
        imgui.TextColored(colors.ok, 'No differences.')
        return
    end
    imgui.BeginChild('##comparison_rows', { 0, 0 }, 0)
    local flags = (ImGuiTableFlags_Borders or 0) + (ImGuiTableFlags_SizingStretchProp or 0)
    if imgui.BeginTable('##comparison_table', 3, flags) then
        imgui.TableSetupColumn('Slot', 0, 0.55)
        imgui.TableSetupColumn(set.name, 0, 1.7)
        imgui.TableSetupColumn(other.name, 0, 1.7)
        imgui.TableHeadersRow()
        for _, row in ipairs(rows) do
          if not editor.ui.compareDiffOnly[1] or row.different then
            imgui.TableNextRow()
            imgui.TableNextColumn()
            imgui.TextUnformatted(row.slot)
            for _, value in ipairs({ { row.left, row.leftSource }, { row.right, row.rightSource } }) do
                imgui.TableNextColumn()
                imgui.PushTextWrapPos(0)
                imgui.TextUnformatted(inspect.Value(value[1]))
                if value[2] and editor.ui.statLayers and editor.ui.statLayers[1] then
                    ui.Panels.Text(imgui, colors.dim, 'From ' .. value[2])
                end
                imgui.PopTextWrapPos()
            end
          end
        end
        imgui.EndTable()
    end
    imgui.EndChild()
end

ui.Inspect = inspect
end

-- == Review ==
do
-- Build a readable save review without writing files or evaluating job code.
local review = {}

function review.Value(value)
    if not value then return 'No slot override' end
    if value.kind == 'code' then return 'Code: ' .. (value.raw or value.text or '') end
    local details = {}
    if value.path then details[#details + 1] = 'Path ' .. value.path end
    if value.rank then details[#details + 1] = 'Rank ' .. value.rank end
    local augments = type(value.augs) == 'table' and table.concat(value.augs, ', ') or value.augs
    if augments and augments ~= '' then details[#details + 1] = 'Augments: ' .. augments end
    return (value.name or value.text or value.raw or 'Item')
        .. (#details > 0 and (' (' .. table.concat(details, '; ') .. ')') or '')
end

function review.Build(document, slots, weaponModes, canRegister)
    local model = { groups = {}, weaponModes = weaponModes or {}, modes = document.newModes,
        created = 0, edited = 0, deleted = 0, renamed = 0, slots = 0, canRegister = canRegister ~= false }
    for _, set in ipairs(document.model.list) do
        local new = (document.renames or {})[set.name]
        if new and not document.deleted[set.name] then
            model.renamed = model.renamed + 1
            model.groups[#model.groups + 1] = { name = set.name .. ' -> ' .. new, kind = 'Rename set', rows = {},
                refs = (document.renameRefs or {})[set.name] or 0 }
        end
    end
    for _, set in ipairs(document.model.list) do
        local edits = document.edits[set.name]
        local deleted = document.deleted[set.name]
        if deleted or set.new or edits then
            local kind = deleted and 'Delete set' or (set.new and 'Create set' or 'Edit set')
            local group = { name = set.name, kind = kind, rows = {} }
            if deleted then model.deleted = model.deleted + 1
            elseif set.new then model.created = model.created + 1
            else model.edited = model.edited + 1 end
            for _, slot in ipairs(deleted and {} or slots) do
                local change = edits and edits[slot]
                if change then
                    local saved = set.slots[slot] and set.slots[slot].value
                    local ghost = set.ghosts and set.ghosts[slot]
                    local before = saved and review.Value(saved)
                        or (ghost and ('Commented placeholder: ' .. ghost.name)) or 'No slot override'
                    local after = review.Value(change)
                    if change.comment then
                        after = 'Comment out: ' .. (change.name or (saved and saved.name) or slot)
                            .. (change.why and (' (' .. change.why .. ')') or '')
                    elseif change.remove then
                        after = ghost and not saved and 'Remove commented placeholder' or 'Remove slot override'
                    end
                    group.rows[#group.rows + 1] = { slot = slot, before = before, after = after }
                    model.slots = model.slots + 1
                end
            end
            model.groups[#model.groups + 1] = group
        end
    end
    return model
end

function review.Draw(imgui, colors, model)
    imgui.TextUnformatted(string.format('Sets: %d new, %d edited, %d deleted, %d renamed | Slot changes: %d',
        model.created, model.edited, model.deleted, model.renamed, model.slots))
    imgui.Separator()
    for index, group in ipairs(model.groups) do
        local color = group.kind == 'Delete set' and colors.bad or colors.blue
        imgui.TextColored(color, group.kind .. ': ' .. group.name)
        if group.kind == 'Delete set' then
            imgui.TextWrapped('Removes the definition. References elsewhere in the job file remain.')
        elseif group.kind == 'Rename set' then
            imgui.TextColored(colors.dim,
                group.refs .. ' reference' .. (group.refs == 1 and '' or 's') .. ' in code renamed too.')
        elseif #group.rows == 0 then
            imgui.TextColored(colors.dim, 'Empty set: no slot overrides.')
        elseif imgui.BeginTable('##review_set_' .. index, 3,
            (ImGuiTableFlags_Borders or 0) + (ImGuiTableFlags_SizingStretchProp or 0)) then
            imgui.TableSetupColumn('Slot', 0, 0.55)
            imgui.TableSetupColumn('Before', 0, 1.7)
            imgui.TableSetupColumn('After', 0, 1.7)
            imgui.TableHeadersRow()
            for _, row in ipairs(group.rows) do
                imgui.TableNextRow()
                imgui.TableNextColumn()
                imgui.TextUnformatted(row.slot)
                imgui.TableNextColumn()
                imgui.PushTextWrapPos(0)
                ui.Panels.Text(imgui, colors.dim, row.before)
                imgui.PopTextWrapPos()
                imgui.TableNextColumn()
                imgui.PushTextWrapPos(0)
                local removed = row.after == 'Remove slot override' or row.after == 'Remove commented placeholder'
                ui.Panels.Text(imgui, removed and colors.bad or colors.ok, row.after)
                imgui.PopTextWrapPos()
            end
            imgui.EndTable()
        end
        imgui.Spacing()
    end
    if #model.weaponModes > 0 then
        imgui.TextColored(model.canRegister and colors.blue or colors.bad,
            model.canRegister and 'Weapon cycle additions on Save' or 'Weapon registration blocked')
        for _, mode in ipairs(model.weaponModes) do imgui.TextUnformatted(mode .. '  (/wm ' .. mode .. ')') end
        imgui.TextWrapped(model.canRegister
            and 'Existing weapon order, default, and selection are kept.'
            or 'No gcinclude.Initialize() line was found. Save will refuse this registration.')
    end
    for _, mode in ipairs(model.modes) do imgui.TextUnformatted('New melee mode: ' .. mode) end
end

ui.Review = review
end

-- == Profiler ==
do
-- Bounded, opt-in CPU timing. No per-frame logging.
local profiler = { enabled = false, samples = {}, limit = 600 }

function profiler.Start()
    return profiler.enabled and os.clock() or nil
end

function profiler.Finish(name, start)
    if not start then return end
    local list = profiler.samples[name] or {}
    if #list < profiler.limit then list[#list + 1] = math.max(0, (os.clock() - start) * 1000) end
    profiler.samples[name] = list
end

function profiler.Reset()
    profiler.samples = {}
end

function profiler.Report(name)
    local source = profiler.samples[name] or {}
    if #source == 0 then return name .. ': no samples' end
    local sorted, total = {}, 0
    for i, v in ipairs(source) do
        sorted[i] = v
        total = total + v
    end
    table.sort(sorted)
    return string.format(
        '%s: n=%d mean=%.3f p95=%.3f max=%.3f ms CPU',
        name, #sorted, total / #sorted, sorted[math.ceil(#sorted * 0.95)], sorted[#sorted]
    )
end

ui.Profiler = profiler
end

-- == Set totals and stat deltas. Models are cached by the editor; drawing is read-only. ==
do
local views = {}
local function text(imgui, color, value)
    ui.Panels.Text(imgui, color, value, true)
end
function views.Controls(imgui, colors, editor)
    editor.ui.statLayers = editor.ui.statLayers or { true }
    imgui.Checkbox('Include inherited gear##stats_layers', editor.ui.statLayers)
    ui.Panels.Tip(imgui, colors, 'On: earlier layers fill slots the selected set leaves unchanged.\n'
        .. 'Off: only items written in each set are totaled; partial sets can look much weaker.\n'
        .. 'This changes the preview only. It does not add weapons or change what the game equips.')
    if editor.ui.statLayers[1] then
        ui.Panels.SameLineIfFits(imgui, 150)
        if imgui.SmallButton('Base: ' .. (editor.ui.statBase or 'Auto') .. '##stats_base') then
            editor.ui.copyFind[1], editor.ui.pickMode, editor.ui.openSetChooser = '', 'statsBase', true
        end
        ui.Panels.Tip(imgui, colors, 'Auto follows known built-in routes, such as Idle > Idle_Refresh.\n'
            .. 'For a custom set, choose the set that goes on before it. Both previews use that base.\n'
            .. 'Custom job code and live weapon-hold rules are not simulated.')
    end
end
local function layers(imgui, colors, model, name)
    if model.layered then
        text(imgui, colors.blue, (name and (name .. ': ') or 'Layers: ') .. table.concat(model.layers, ' > '))
    end
    for _, warning in ipairs(model.layerWarnings or {}) do text(imgui, colors.warn, warning) end
end
local coverageHelp = 'Items: slots with a named item in this preview.\nInherited: items supplied by an earlier layer.\n'
    .. 'Unresolved: no known item after the preview layers; gear already worn in game is not assumed.\n'
    .. 'Unchanged: an omitted slot in a definition-only preview. Rules: ignore/displaced directives.\n'
    .. 'Counts describe definitions, not missing ownership or unfinished RP.'
local previewHelp = 'Change subtracts the left set from the right set. A positive value means more of that stat.\n'
    .. 'Green/red follow a known beneficial direction; less Damage taken can be green with a negative change.\n'
    .. 'Neutral stats, such as Enmity, are not rated. Gear differences and stat differences are separate.\n'
    .. 'Totals add listed gear bonuses. Zero means no listed numeric contribution, not that an unknown slot is empty.\n'
    .. 'Live modes/settings, current worn gear, custom logic, buffs and combat formulas are not simulated; caps are '
    .. 'shown over the totals (over: wasted), not applied to them.\n'
    .. 'Conditional and unsupported effects are under Other effects / not totaled below the table.'
local reasons = {
    ['Conditional or variable effect'] = 'Conditional: ',
    ['Other or unrecognized effect'] = 'Other: ',
    ['Unknown base stats'] = 'Base unknown: ',
    ['Base stats only'] = 'Augments unknown: ',
}
local function notes(imgui, colors, model, id, name)
    local n = #model.notes + model.code
    if n == 0 then return end
    if ui.Panels.Section(imgui, colors, (name and (name .. ': ') or '') .. 'Other effects / not totaled (' .. n .. ')##'
        .. id) then
        if model.code > 0 then text(imgui, colors.warn, model.code .. ' code-defined slots were not evaluated.') end
        for _, group in ipairs(model.noteGroups) do
            text(imgui, colors.blue, group.slot .. ': ' .. group.item)
            for _, entry in ipairs(group.entries) do
                text(imgui, colors.dim, (reasons[entry.reason] or '') .. entry.text)
            end
            imgui.Spacing()
        end
    end
end
local function stat_name(imgui, colors, name) -- '<Element> resistance' after its element's dot
    local e = string.match(name, '^(%a+) resistance$')
    if (e ~= nil) and ui.ElementDot(imgui, e) then imgui.SameLine(0, 2) end
    text(imgui, colors.text, name)
end
-- Gear totals against their caps, each checked on BG-Wiki or FFXIclopedia (the hover names the page): over is
-- wasted, under is room left. Damage taken is split as the game caps it: physical (DT + PDT), magic (DT + MDT) and
-- breath (DT + BDT) each at -50%; the II versions are apart, past it. Only stats the gear has.
local DT_TIP = 'DT counts toward each of the physical, magic and breath caps (-50% each); PDT, MDT and BDT only '
    .. 'toward their own. The II versions (PDT II...) are counted apart: past -50%, up to -87.5% in all '
    .. '(BG-Wiki: Damage Taken). Older gear\'s listed % can round down a little (/256: FFXIclopedia, Damage).'
local CAPS = {
    { label = 'Haste (gear)', stat = 'Haste', cap = 25, near = 26,
        tip = 'Gear haste caps at 256/1024, exactly 25%. Gear lists rounded values (Blitz Ring 11/1024 reads 1%), so '
            .. '25-26% as listed is at or about the cap (FFXIclopedia: Haste (Status Effect)).' },
    { label = 'Fast Cast', stat = 'Fast Cast', cap = 80,
        tip = 'Casting time reduction caps at 80%; traits count toward it too (BG-Wiki: Fast Cast).' },
    { label = 'Snapshot', stat = 'Snapshot', cap = 70,
        tip = '70% from all sources: merits (up to 10%) and Flurry count too; Rapid Shot and Velocity Shot are apart '
            .. '(BG-Wiki: Snapshot).' },
    { label = 'Quick Magic', stat = 'Quick Magic', cap = 10, tip = 'Caps at +10% (FFXIclopedia: Quick Magic).' },
    { label = 'Cure potency', stat = 'Cure potency', cap = 50,
        tip = 'Equipment cure potency caps at +50% (FFXIclopedia: Cure Potency).' },
}
local DT_ROWS = { -- the specific stat with DT toward one -50% cap, and its II
    { label = 'Physical damage taken', short = 'PDT', stat = 'Physical damage taken',
        two = 'Physical damage taken II' },
    { label = 'Magic damage taken', short = 'MDT', stat = 'Magic damage taken', two = 'Magic damage taken II' },
    { label = 'Breath damage taken', short = 'BDT', stat = 'Breath damage taken', only = true },
}
local function fmt(v) return ((v > 0) and '+' or '') .. string.format('%g', v) .. '%' end
local function caps_rows(model) -- { { label, total, parts, state, color, tip } }, worked out once per model
    if model.caps ~= nil then return model.caps end
    local t = {}
    for _, row in ipairs(model.rows) do
        if row.unit == '%' then t[row.name] = (t[row.name] or 0) + row.value end
    end
    local out = {}
    for _, c in ipairs(CAPS) do
        local v = t[c.stat] or 0
        if v ~= 0 then
            local r = { label = c.label, total = fmt(v), tip = c.tip }
            if v > (c.near or c.cap) then -- haste: 25-26% as listed is the cap, so over by a range
                local lo, hi = v - (c.near or c.cap), v - c.cap
                r.state, r.color = ((lo ~= hi) and (string.format('%g', lo) .. '-') or '') .. string.format('%g', hi)
                    .. '% over (cap ' .. c.cap .. '%)', 'warn'
            elseif v >= c.cap then
                r.state, r.color = 'at cap (' .. c.cap .. '%)', 'ok'
            else
                r.state, r.color = string.format('%g', c.cap - v) .. '% free (cap ' .. c.cap .. '%)', 'dim'
            end
            out[#out + 1] = r
        end
    end
    local dt, dt2 = t['Damage taken'] or 0, t['Damage taken II'] or 0
    local split = false -- no PDT, MDT or BDT: one Damage taken row (DT counts toward each cap the same)
    for _, d in ipairs(DT_ROWS) do
        if ((t[d.stat] or 0) ~= 0) or ((d.two ~= nil) and ((t[d.two] or 0) ~= 0)) then split = true end
    end
    for _, d in ipairs(DT_ROWS) do
        local own = t[d.stat] or 0
        if (not split) and (d.short ~= 'PDT') then
            own = nil -- the one row is the physical row, renamed
        end
        if (own ~= nil) and ((own ~= 0) or ((dt ~= 0) and not d.only)) then
            local v = dt + own
            local parts = {}
            if dt ~= 0 then parts[#parts + 1] = 'DT ' .. string.format('%g', dt) end
            if own ~= 0 then parts[#parts + 1] = d.short .. ' ' .. string.format('%g', own) end
            local r = { label = split and d.label or 'Damage taken', total = fmt(v), tip = DT_TIP,
                parts = split and table.concat(parts, ' + ') or 'physical, magic, breath alike' }
            if v < -50 then
                r.state, r.color = string.format('%g', -50 - v) .. '% over (cap -50%)', 'warn'
            elseif v == -50 then
                r.state, r.color = 'at cap (-50%)', 'ok'
            else
                r.state, r.color = string.format('%g', v + 50) .. '% free (cap -50%)', 'dim'
            end
            local two = dt2 + ((d.two ~= nil) and (t[d.two] or 0) or 0)
            if two ~= 0 then r.two = 'II ' .. string.format('%g', two) .. '% past the cap' end
            out[#out + 1] = r
        end
    end
    model.caps = out
    return out
end
local function caps(imgui, colors, model, tw)
    local rows = caps_rows(model)
    if #rows == 0 then return end
    local lw, vw, sw = 0, 0, 0 -- columns: the stat, its total (right-aligned), the state, then what makes it up
    for _, r in ipairs(rows) do
        lw, vw, sw = math.max(lw, tw(r.label)), math.max(vw, tw(r.total)), math.max(sw, tw(r.state))
    end
    imgui.TextColored(colors.blue, 'Caps')
    for _, r in ipairs(rows) do
        local x0 = (imgui.GetCursorPosX ~= nil) and imgui.GetCursorPosX() or nil
        local at = (x0 ~= nil) and (imgui.SetCursorPosX ~= nil)
        imgui.TextColored(colors.text, r.label)
        ui.Panels.Tip(imgui, colors, r.tip) -- where the cap comes from, and what counts toward it
        imgui.SameLine()
        if at then imgui.SetCursorPosX(x0 + lw + 12 + vw - tw(r.total)) end
        imgui.TextColored(colors.text, r.total)
        imgui.SameLine()
        if at then imgui.SetCursorPosX(x0 + lw + 12 + vw + 14) end
        imgui.TextColored(colors[r.color] or colors.dim, r.state)
        ui.Panels.Tip(imgui, colors, r.tip)
        local after = ((r.parts ~= nil) and r.parts or '') .. ((r.two ~= nil) and (((r.parts ~= nil) and '; ' or '')
            .. r.two) or '')
        if after ~= '' then
            imgui.SameLine()
            if at then imgui.SetCursorPosX(x0 + lw + 12 + vw + 14 + sw + 14) end
            imgui.TextColored(colors.dim, after)
            ui.Panels.Tip(imgui, colors, r.tip)
        end
    end
    imgui.Spacing()
end
function views.DrawSummary(imgui, colors, name, model)
    local fs = imgui.GetFontSize() or 16
    local function tw(t)
        local w = imgui.CalcTextSize(t)
        return ((type(w) == 'table') and (w.x or w[1]) or w) or 0
    end
    -- one line: whose totals, what they cover; the help (coverage, how the preview works) behind one (?)
    imgui.TextColored(colors.blue, name .. (model.layered and ' - with inherited gear' or ' - this set only'))
    ui.Panels.SameLineIfFits(imgui, tw(model.coverage .. ' (?)') + fs)
    imgui.TextColored(colors.dim, model.coverage)
    imgui.SameLine()
    imgui.TextColored(colors.dim, '(?)')
    ui.Panels.Tip(imgui, colors, (model.layered and 'Layer preview: unresolved slots stay unknown.\n'
        or 'This set only: slots it leaves out are not totaled.\n') .. coverageHelp .. '\n\n' .. previewHelp)
    if model.pending then text(imgui, colors.warn, 'Includes unsaved changes.') end
    if model.layered and (#model.layers > 1) then layers(imgui, colors, model) -- just the set itself: no line
    else
        for _, warning in ipairs(model.layerWarnings or {}) do text(imgui, colors.warn, warning) end
    end
    if model.baseOnly > 0 then text(imgui, colors.warn, model.baseOnly
        .. (model.baseOnly == 1 and ' item has' or ' items have')
            .. ' base stats only; exact augments are unknown.') end
    imgui.Separator()
    caps(imgui, colors, model, tw) -- against their caps: over (wasted) or room left
    imgui.BeginChild('##summary_rows', { 0, 0 }, 0)
    local available = imgui.GetContentRegionAvail()
    local width = type(available) == 'number' and available or (available.x or available[1])
    if model.colW == nil then -- the widest stat name (room for an element dot) and value: columns that fit them
        local nw, vw = 0, 0
        for _, row in ipairs(model.rows) do
            nw, vw = math.max(nw, tw(row.name)), math.max(vw, tw(row.text))
        end
        model.colW = { nw + fs, vw }
    end
    local gap = fs * 2 -- between one stat's value and the next stat's name
    local pairW = model.colW[1] + model.colW[2] + gap
    local pairs = math.max(1, math.min(3, math.floor(width / pairW)))
    if #model.rows == 0 then text(imgui, colors.dim, 'No nonzero listed bonuses in these definitions.')
    elseif imgui.BeginTable('##summary_stats', pairs * 2,
        (ImGuiTableFlags_RowBg or 0) + (ImGuiTableFlags_SizingStretchProp or 0), { math.min(width, pairs * pairW), 0 }) then
        for _ = 1, pairs do
            imgui.TableSetupColumn('Stat', 0, model.colW[1])
            imgui.TableSetupColumn('Total', 0, model.colW[2] + gap)
        end
        local group, index = nil, 0
        for _, row in ipairs(model.rows) do
            if row.group ~= group then -- the group's name heads its rows (no header row: it said Stat / Total)
                group, index = row.group, 0
                imgui.TableNextRow(); imgui.TableNextColumn(); imgui.TextColored(colors.blue, group)
            end
            if index % pairs == 0 then imgui.TableNextRow() end
            imgui.TableNextColumn(); stat_name(imgui, colors, row.name)
            imgui.TableNextColumn()
            local room = imgui.GetContentRegionAvail() -- the value at the column's right, short of the gap
            room = (type(room) == 'number') and room or (room.x or room[1])
            local push = room - tw(row.text) - gap
            if (push > 0) and (imgui.SetCursorPosX ~= nil) then imgui.SetCursorPosX(imgui.GetCursorPosX() + push) end
            ui.Panels.Text(imgui, colors.text, row.text)
            index = index + 1
        end
        imgui.EndTable()
    end
    notes(imgui, colors, model, 'summary_notes')
    imgui.EndChild()
end
function views.DrawComparison(imgui, colors, leftName, rightName, pair, differencesOnly)
    text(imgui, colors.dim, leftName .. ': ' .. pair.left.coverage)
    ui.Panels.Tip(imgui, colors, coverageHelp)
    text(imgui, colors.dim, rightName .. ': ' .. pair.right.coverage)
    ui.Panels.Tip(imgui, colors, coverageHelp)
    for _, entry in ipairs({ { pair.left, leftName }, { pair.right, rightName } }) do
        if entry[1].layered then text(imgui, colors.blue, entry[2] .. ': ' .. table.concat(entry[1].layers, ' > ')) end
    end
    for _, notice in ipairs(pair.warnings or {}) do
        text(imgui, colors.warn, (notice.sides == 3 and 'Both sets' or (notice.sides == 1 and leftName or rightName))
            .. ': ' .. notice.text)
    end
    text(imgui, colors.dim, 'Change = right minus left. Preview help (?)')
    ui.Panels.Tip(imgui, colors, previewHelp)
    if pair.left.pending or pair.right.pending then text(imgui, colors.warn, 'Includes unsaved layer changes.') end
    if pair.left.baseOnly + pair.right.baseOnly > 0 then
        local count = pair.left.baseOnly + pair.right.baseOnly
        text(imgui, colors.warn, 'Augments unknown: ' .. count .. ' slot entries (base stats only).')
        ui.Panels.Tip(imgui, colors, leftName .. ': ' .. pair.left.baseOnly .. ' base-only entries.\n'
            .. rightName .. ': ' .. pair.right.baseOnly .. ' base-only entries.\n'
            .. 'An exact owned copy or decoded augment data could not be resolved. Its base bonuses are counted.\n'
            .. 'A shared item can appear on both sides. Unknown augment differences are not treated as zero.')
    end
    imgui.BeginChild('##compare_stats_rows', { 0, 0 }, 0)
    local count = 0
    if imgui.BeginTable('##compare_stats', 4,
        (ImGuiTableFlags_RowBg or 0) + (ImGuiTableFlags_SizingStretchProp or 0)) then
        imgui.TableSetupColumn('Stat', 0, 1.9)
        imgui.TableSetupColumn(leftName, 0, 1)
        imgui.TableSetupColumn(rightName, 0, 1)
        imgui.TableSetupColumn('Change', 0, 1)
        imgui.TableHeadersRow()
        local group
        for _, row in ipairs(pair.rows) do
            if not differencesOnly or row.delta ~= 0 then
                count = count + 1
                if row.group ~= group then
                    group = row.group
                    imgui.TableNextRow(); imgui.TableNextColumn(); imgui.TextColored(colors.blue, group)
                    for _ = 1, 3 do imgui.TableNextColumn() end
                end
                imgui.TableNextRow(); imgui.TableNextColumn(); stat_name(imgui, colors, row.name)
                imgui.TableNextColumn(); ui.Panels.Text(imgui, colors.dim, row.before)
                imgui.TableNextColumn(); ui.Panels.Text(imgui, colors.text, row.after)
                imgui.TableNextColumn()
                local benefit = row.delta * row.direction
                ui.Panels.Text(imgui,
                    benefit > 0 and colors.ok or (benefit < 0 and colors.bad or colors.dim), row.deltaText)
            end
        end
        imgui.EndTable()
    end
    if count == 0 then
        text(imgui, colors.dim, 'No additive stat differences. Gear or conditional effects may still differ.')
    end
    notes(imgui, colors, pair.left, 'compare_left_notes', leftName)
    notes(imgui, colors, pair.right, 'compare_right_notes', rightName)
    imgui.EndChild()
end
ui.Stats = views
end

return ui
