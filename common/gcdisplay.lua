local gcdisplay = {}

local imgui = require('imgui')
local function say(msg) print(chat.header('GoomSwap'):append(chat.message(msg))) end
local function err(msg) print(chat.header('GoomSwap'):append(chat.error(msg))) end
local cfg = nil
local inc = nil -- gcinclude: the bar's mode names and labels
local barPlaced = false
local placedX, placedY, heldSeen = nil, nil, false -- where the bar's own line was put; a mouse press since (a drag)

local Toggles = {}
local DefToggles = {}
local DefCycles = {}
local Cycles = {}
local Def = 0
local Attk = 0
local MainLV = 0
local SubLV = 0
local Main = 'FOO'
local Sub = 'BAR'
local headText = ''
local headMID, headSID = nil, nil
local version = 0 -- bumped on every toggle/cycle change: the bar's model and the HUD's state line rebuild on it
function gcdisplay.Version() return version end

function gcdisplay.AdvanceCycle(name)
    local ctable = Cycles[name]
    if (type(ctable) ~= 'table') then return; end

    ctable.Index = ctable.Index + 1
    if (ctable.Index > #ctable.Array) then ctable.Index = 1; end
    version = version + 1
end

function gcdisplay.SetCycle(name,val)
    local ctable = Cycles[name]
    if (type(ctable) ~= 'table') then return; end

    for k,v in pairs(ctable.Array) do
        if val == v then
            if (ctable.Index ~= k) then ctable.Index = k; version = version + 1 end
            return true
        end
    end
    return false
end

function gcdisplay.AdvanceToggle(name)
    if (type(Toggles[name]) == 'boolean') then Toggles[name] = not Toggles[name]; version = version + 1 end
end

function gcdisplay.SetToggle(name, val)
    if (type(Toggles[name]) ~= 'boolean') then return end
    if (Toggles[name] ~= (val == true)) then Toggles[name] = (val == true); version = version + 1 end
end

-- Only the bar shows these, so nothing is read while it is off (BarCommand reads them when it goes on).
function gcdisplay.Update()
    if (cfg == nil) or (cfg.DisplayBar ~= true) then return end
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if (player == nil) then return; end

    local MID, SID = player:GetMainJob(), player:GetSubJob()
    local mlv, slv = player:GetMainJobLevel(), player:GetSubJobLevel()
    Def = player:GetDefense()
    Attk = player:GetAttack()
    -- job text unchanged
    if (MID == headMID) and (SID == headSID) and (mlv == MainLV) and (slv == SubLV) and (headText ~= '') then return end
    headMID, headSID, MainLV, SubLV = MID, SID, mlv, slv
    Main = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", MID) or 'NON'
    Sub = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", SID) or 'NON'
    headText = string.format('%s%d/%s%d', Main, MainLV, Sub, SubLV)
end

function gcdisplay.CreateToggle(name, default)
    Toggles[name] = default
    version = version + 1
end

function gcdisplay.GetToggle(name)
    return Toggles[name] or false
end

function gcdisplay.GetToggles()
    local out = {}
    for k, v in pairs(Toggles) do out[k] = v end
    return out
end

function gcdisplay.GetCycles()
    local out = {}
    for k, v in pairs(Cycles) do out[k] = v.Array[v.Index] end
    return out
end

function gcdisplay.GetCycleValues(name) -- the cycle's value list (read only), nil if no such cycle
    local ctable = Cycles[name]
    return (type(ctable) == 'table') and ctable.Array or nil
end

function gcdisplay.CreateCycle(name, values)
    local newCycle = { Index = 1, Array = values }
    Cycles[name] = newCycle
    version = version + 1
end

function gcdisplay.GetCycle(name)
    local ctable = Cycles[name]
    if (type(ctable) == 'table') then
        return ctable.Array[ctable.Index]
    else
        return 'Unknown'
    end
end

function gcdisplay.ClearAll()
    Toggles = {}
    Cycles = {}
    DefToggles = {}
    DefCycles = {}
    version = version + 1
end

-- Snapshot of every toggle and cycle right after the job loads; the HUD hides values still at it.
function gcdisplay.MarkDefaults()
    DefToggles, DefCycles = {}, {}
    for k, v in pairs(Toggles) do DefToggles[k] = v end
    for k, v in pairs(Cycles) do DefCycles[k] = v.Index end
    version = version + 1
end

function gcdisplay.IsDefault(kind, name)
    if (kind == 'toggle') then return (DefToggles[name] ~= nil) and (DefToggles[name] == Toggles[name]) end
    local c = Cycles[name]
    return (c ~= nil) and (DefCycles[name] == c.Index)
end

-- Bar colours: labels blue-grey, values white. One rounded capsule in three parts, split by thin lines: job | modes |
-- def
-- and the toggles. Every mode and toggle is a pill (gcdisplay.Pill, the HUD's cells too): set or on, outlined and
-- tinted
-- in its colour with a solid dot; at its default or off, a dashed grey outline with a ring; a weapon, plain.
local COL_HEAD = { 0.93, 0.93, 0.96, 1.0 }
local COL_KEY = { 0.62, 0.68, 0.80, 1.0 }
-- Every job its own colour (picked to tell all 22 apart on the dark bar; RNG moss green, COR mustard gold, WHM light
-- rose). Ashita outlines the job text: the main job's
-- half in its colour, the sub job's in its.
local JOB_COL = {
    WAR = { 1.00, 0.45, 0.40, 1.0 }, MNK = { 0.96, 0.70, 0.04, 1.0 }, WHM = { 1.00, 0.82, 0.75, 1.0 },
    BLM = { 0.71, 0.39, 1.00, 1.0 }, RDM = { 1.00, 0.22, 0.61, 1.0 }, THF = { 0.53, 1.00, 0.14, 1.0 },
    PLD = { 0.12, 0.71, 1.00, 1.0 }, DRK = { 0.73, 0.44, 0.80, 1.0 }, BST = { 0.85, 0.58, 0.33, 1.0 },
    BRD = { 0.80, 0.85, 0.02, 1.0 }, RNG = { 0.52, 0.65, 0.36, 1.0 }, SAM = { 0.72, 0.49, 0.48, 1.0 },
    NIN = { 0.53, 0.62, 0.70, 1.0 }, DRG = { 0.02, 0.98, 1.00, 1.0 }, SMN = { 0.18, 1.00, 0.76, 1.0 },
    BLU = { 0.19, 0.54, 1.00, 1.0 }, COR = { 0.65, 0.61, 0.10, 1.0 }, PUP = { 1.00, 0.55, 0.74, 1.0 },
    DNC = { 1.00, 0.18, 0.89, 1.0 }, SCH = { 0.82, 0.75, 1.00, 1.0 }, GEO = { 0.11, 0.81, 0.33, 1.0 },
    RUN = { 1.00, 0.45, 0.04, 1.0 }
}
local function job_col(j) return JOB_COL[string.upper(tostring(j or ''))] or COL_HEAD end
local COL_DIV = { 1.0, 1.0, 1.0, 0.20 }
local COL_EDGE = { 1.0, 1.0, 1.0, 0.10 }
local COL_BAR_BG = { 0.04, 0.045, 0.06 }

-- Mode and toggle colours, the bar's and the HUD's: every meaning its own.
local CYAN, MAGENTA, PURPLE = { 0.25, 0.88, 1.00, 1.0 }, { 0.94, 0.35, 0.90, 1.0 }, { 0.65, 0.40, 1.00, 1.0 }
local MODE_COL = {
    MeleeSet = { Acc = CYAN, SubtleBlow = MAGENTA },
    WsSet = { High = PURPLE, PDL = MAGENTA, Acc = CYAN },
    -- mp blue, hp green, tp yellow
    IdleSet = { Refresh = { 0.45, 0.70, 1.00, 1.0 }, Regen = { 0.40, 0.90, 0.50, 1.0 },
        Regain = { 0.95, 0.85, 0.35, 1.0 } },
    NukeSet = { Macc = { 0.24, 0.82, 0.71, 1.0 }, OccultAcumen = { 1.00, 0.59, 0.55, 1.0 } }, -- teal, salmon
    Hoxne = { Locked = { 0.82, 0.63, 0.39, 1.0 } }, -- bronze
    TankSet = { Main = { 0.55, 0.74, 1.00, 1.0 }, MEVA = { 0.71, 0.94, 0.35, 1.0 } }, -- periwinkle, lime
}
-- a job file's own modes: lime, salmon, periwinkle
local COL_MORE = { { 0.71, 0.94, 0.35, 1.0 }, { 1.00, 0.59, 0.55, 1.0 }, { 0.55, 0.74, 1.00, 1.0 } }
local MODE_EMPTY = { MeleeSet = 'Default', WsSet = 'Default', NukeSet = 'Power', IdleSet = 'Default',
    Hoxne = 'Off', TankSet = 'None' } -- each mode's nothing-laid-over value
local EMPTY_ANY = { None = true, Off = true, Default = true, Unknown = true }
-- always something
local MODE_PLAIN = { Weapons = true, Main = true, Sub = true, Range = true, Ammo = true, Weapon = true, PupMode = true }
local MODE_TEXT = { MeleeSet = { SubtleBlow = 'sb' }, IdleSet = { Refresh = 'mp', Regen = 'hp', Regain = 'tp' },
    NukeSet = { OccultAcumen = 'oa' }, Hoxne = { Locked = 'hoxne' } }
local TOGGLE_COL = { DTset = { 1.00, 0.54, 0.24, 1.0 }, MDTset = { 0.43, 0.53, 1.00, 1.0 },
    Aminon = { 0.75, 0.47, 0.85, 1.0 },
    SIR = { 0.24, 0.82, 0.71, 1.0 }, TH = { 0.95, 0.85, 0.35, 1.0 }, Kite = { 0.35, 0.95, 0.45, 1.0 },
    Burst = { 1.00, 0.48, 0.72, 1.0 }, PROC = { 1.00, 0.35, 0.35, 1.0 }, String = { 0.24, 0.82, 0.71, 1.0 },
    SongLock = { 0.65, 0.40, 1.00, 1.0 }, Death = { 1.00, 0.35, 0.35, 1.0 } }
-- Colour preset (gctheme, shared with goomui): each meaning takes the preset's shade for it. GoomSwap's own colours
-- are kept to restore ('goomswap'). Job and weapon-class colours never change.
local THEMED = {
    { MODE_COL.MeleeSet, 'Acc', 'hit' }, { MODE_COL.MeleeSet, 'SubtleBlow', 'ws' }, { MODE_COL.WsSet, 'High', 'tp' },
    { MODE_COL.IdleSet, 'Refresh', 'mp' }, { MODE_COL.IdleSet, 'Regen', 'hp_full' },
        { MODE_COL.IdleSet, 'Regain', 'tp_max' },
    { MODE_COL.NukeSet, 'Macc', 'spell' }, { MODE_COL.NukeSet, 'OccultAcumen', 'item' },
        { MODE_COL.TankSet, 'Main', 'mp' },
    { MODE_COL.TankSet, 'MEVA', 'heal' }, { COL_MORE, 1, 'heal' }, { COL_MORE, 2, 'hp_25' }, { COL_MORE, 3, 'r3' },
    { TOGGLE_COL, 'DTset', 'hp_25' }, { TOGGLE_COL, 'MDTset', 'mp' }, { TOGGLE_COL, 'Aminon', 'item' },
    { TOGGLE_COL, 'SIR', 'spell' }, { TOGGLE_COL, 'TH', 'crit' }, { TOGGLE_COL, 'Kite', 'heal' },
        { TOGGLE_COL, 'Burst', 'ws' },
    { TOGGLE_COL, 'PROC', 'counter' }, { TOGGLE_COL, 'String', 'spell' }, { TOGGLE_COL, 'SongLock', 'tp' },
    { TOGGLE_COL, 'Death', 'hp_0' },
}
local themeMod = nil
local function gctheme()
    themeMod = themeMod or gFunc.LoadFile('common\\gctheme.lua')
    return themeMod
end
local OWN = {}
for i, t in ipairs(THEMED) do OWN[i] = { t[1][t[2]][1], t[1][t[2]][2], t[1][t[2]][3] } end
gcdisplay.Theme = nil -- the preset in use, nil = GoomSwap's own
function gcdisplay.ApplyTheme(name)
    local presets = gctheme()
    name = (type(presets) == 'table') and (presets.PRESETS[name or ''] ~= nil) and name or nil
    for i, t in ipairs(THEMED) do
        local c = t[1][t[2]]
        local p = (name ~= nil) and presets.Color(name, t[3]) or OWN[i]
        c[1], c[2], c[3] = p[1], p[2], p[3]
    end
    gcdisplay.Theme = name
    version = version + 1
    return name
end

-- A cycle value's pill: 'plain' (weapons, element...: always something), 'def' (nothing laid over) or 'set', and its
-- colour.
function gcdisplay.ModeKind(k, v)
    v = tostring(v or '')
    if MODE_PLAIN[k] then return 'plain', nil end
    if (v == MODE_EMPTY[k]) or EMPTY_ANY[v] then return 'def', nil end
    local c = MODE_COL[k] and MODE_COL[k][v]
    if (c == nil) then
        local n = 0
        for i = 1, #v do n = n + string.byte(v, i) end
        c = COL_MORE[(n % #COL_MORE) + 1]
    end
    return 'set', c
end
function gcdisplay.ModeText(k, v) -- lower case, short: sb, mp, oa...
    v = tostring(v or '')
    local t = MODE_TEXT[k] and MODE_TEXT[k][v]
    if (t ~= nil) then return t end
    if (inc ~= nil) and (inc.ModeLabel ~= nil) then v = tostring(inc.ModeLabel(k, v)) end
    return string.lower(v)
end
-- The weapon pill's colour: its weapon's class, as a job's colour. Classes from the game's own item descriptions
-- (Windower resources: each class has its own Aftermath) and BG-Wiki's Prime Weapons; TP bonus = the Ambuscade +2
-- weapons named here. settings.WeaponClass = { ['Item Name'] = 'tpbonus' } adds or overrides (classes as below).
local WEAPON_COL = { relic = { 0.45, 0.80, 1.00, 1.0 }, mythic = { 0.35, 0.85, 0.45, 1.0 },
    empyrean = { 1.00, 0.35, 0.35, 1.0 },
    -- light blue, green (ergon too), red, purple, orange, dark blue
    prime = { 0.70, 0.45, 1.00, 1.0 }, aeonic = { 1.00, 0.62, 0.20, 1.0 }, tpbonus = { 0.30, 0.45, 1.00, 1.0 } }
local WEAPON_CLASS = {}
for cls, list in pairs({
    relic = { 'Spharai', 'Mandau', 'Excalibur', 'Ragnarok', 'Guttler', 'Bravura', 'Apocalypse', 'Gungnir', 'Kikoku',
        'Amanomurakumo',
        'Mjollnir', 'Claustrum', 'Annihilator', 'Yoichinoyumi' },
    mythic = { 'Conqueror', 'Glanzfaust', 'Yagrush', 'Laevateinn', 'Murgleis', 'Vajra', 'Burtgang', 'Liberator',
        'Aymur', 'Carnwenhan',
        'Gastraphetes', 'Kogarasumaru', 'Nagi', 'Ryunohige', 'Nirvana', 'Tizona', 'Death Penalty', 'Kenkonken',
            'Terpsichore', 'Tupsimati',
        'Idris', 'Epeolatry' }, -- the last two: Ergon
    empyrean = { 'Verethragna', 'Twashtar', 'Almace', 'Caladbolg', 'Farsha', 'Ukonvasara', 'Redemption',
        'Rhongomiant', 'Kannagi',
        'Masamune', 'Gambanteinn', 'Hvergelmir', 'Gandiva', 'Armageddon' },
    aeonic = { 'Godhands', 'Aeneas', 'Sequence', 'Lionheart', 'Tri-edge', 'Chango', 'Anguta', 'Trishula',
        'Heishi Shorinken',
        'Dojikiri Yasutsuna', 'Tishtrya', 'Khatvanga', 'Fail-Not', 'Fomalhaut' },
    prime = { 'Varga Purnikawa', 'Mpu Gandring', 'Caliburnus', 'Helheim', 'Foenaria', 'Spalirisos', 'Laphria',
        'Kusanagi', 'Gae Buide',
        'Dokoku', 'Lorg Mor', 'Opashoro', 'Pinaka', 'Earp', 'Duban', 'Loughnashade' },
    tpbonus = { 'Sparrowhawk +2', 'Anarchy +2' },
}) do
    for _, n in ipairs(list) do WEAPON_CLASS[string.lower(n)] = cls end
end
local function item_class(v)
    local n = (type(v) == 'table') and (v.Name or v.name) or v
    if (type(n) ~= 'string') then return nil end
    n = string.lower(n)
    local user = (cfg ~= nil) and cfg.WeaponClass or nil
    if (type(user) == 'table') then
        for k, c in pairs(user) do
            if (string.lower(tostring(k)) == n) and (WEAPON_COL[string.lower(tostring(c))] ~= nil) then
                return string.lower(tostring(c))
            end
        end
    end
    return WEAPON_CLASS[n]
end
-- A weapon mode's class: its set's Main if classed, else Range (guns, bows), else Sub; a slot pick (no modes): the
-- item.
local function mode_class(wk, v)
    if (v == nil) then return nil end
    if (wk ~= 'Weapons') then return item_class(v) end
    local set = (inc ~= nil) and (inc.FindSet ~= nil) and inc.FindSet('Weapon_' .. tostring(v)) or nil
    if (type(set) ~= 'table') then return item_class(v) end
    return item_class(set.Main) or item_class(set.Range) or item_class(set.Sub)
end
function gcdisplay.WeaponClass() -- this box's, for the HUD line (the other boxes' drop shows it)
    local wk = ((Cycles.Weapons ~= nil) and 'Weapons') or ((Cycles.Main ~= nil) and 'Main') or nil
    if (wk == nil) then return nil end
    local c = Cycles[wk]
    return mode_class(wk, c.Array[c.Index])
end

-- Pills. LEAD: px from the pill's left edge to its text (the dot before it); PLAIN_LEAD with no dot; TAIL after the
-- text.
local PILL_GREY = { 0.50, 0.50, 0.56 }
local COL_PILL_TEXT = { 0.93, 0.93, 0.96, 1.0 }
local COL_PILL_DIM = { 0.55, 0.55, 0.61, 0.90 }
gcdisplay.PILL_LEAD, gcdisplay.PILL_PLAIN_LEAD, gcdisplay.PILL_TAIL = 13, 5, 5
gcdisplay.COL_PILL_TEXT, gcdisplay.COL_PILL_DIM = COL_PILL_TEXT, COL_PILL_DIM
-- Scratch points and colour for the draw calls: ImGui copies each argument when it is called and keeps none, so
-- the bar (every frame; one dashed pill alone is ~40 lines) makes no new tables for them.
local VA, VB, CC = { 0, 0 }, { 0, 0 }, { 0, 0, 0, 1 }
local function va(x, y) VA[1], VA[2] = x, y; return VA end
local function vb(x, y) VB[1], VB[2] = x, y; return VB end
local function rgba(c, a) CC[1], CC[2], CC[3], CC[4] = c[1], c[2], c[3],
    a or c[4] or 1.0; return imgui.GetColorU32(CC) end
local PLAIN_EDGE = { 0.80, 0.80, 0.84 }
-- A rounded outline as dashes (ImGui draws no dashed lines), per pill size, worked out once: { x1, y1, xm, ym, x2, y2 }
-- each, from the top left, the middle point keeping the dashes on the round ends.
local dashCache = {}
local function dashes(w, h)
    local key = w .. 'x' .. h
    local hit = dashCache[key]
    if (hit ~= nil) then return hit end
    local r = math.min(h / 2, w / 2)
    local sx, sy, q = w - 2 * r, h - 2 * r, math.pi * r / 2
    local runs = { -- clockwise from the top edge; each { length, fn(t) -> x, y }
        { sx, function(t) return r + t, 0 end },
        { q, function(t) local a = -math.pi / 2 + t / r; return w - r + r * math.cos(a), r + r * math.sin(a) end },
        { sy, function(t) return w, r + t end },
        { q, function(t) local a = t / r; return w - r + r * math.cos(a), h - r + r * math.sin(a) end },
        { sx, function(t) return w - r - t, h end },
        { q, function(t) local a = math.pi / 2 + t / r; return r + r * math.cos(a), h - r + r * math.sin(a) end },
        { sy, function(t) return 0, h - r - t end },
        { q, function(t) local a = math.pi + t / r; return r + r * math.cos(a), r + r * math.sin(a) end },
    }
    local total = 0
    for _, run in ipairs(runs) do total = total + run[1] end
    local function at(s)
        for _, run in ipairs(runs) do
            if (s <= run[1]) then return run[2](s) end
            s = s - run[1]
        end
        return r, 0
    end
    local n = math.max(4, math.floor(total / 5 + 0.5)) -- ~3px on, 2px off, evenly round
    local period = total / n
    local out = {}
    for i = 0, n - 1 do
        local s = i * period
        local ax, ay = at(s)
        local mx, my = at(s + period * 0.3)
        local bx, by = at(s + period * 0.6)
        out[#out + 1] = { ax, ay, mx, my, bx, by }
    end
    dashCache[key] = out
    return out
end
-- kind: 'set' (col: outline, tint, solid dot), 'plain' (col or grey: outline, tint if col, no dot), 'def' (dashed grey,
-- ring).
function gcdisplay.Pill(dl, x1, y1, x2, y2, kind, col)
    local h = y2 - y1
    local r, cy = h / 2, y1 + h / 2
    if (kind == 'set') or ((kind == 'plain') and (col ~= nil)) then
        dl:AddRectFilled(va(x1, y1), vb(x2, y2), rgba(col, 0.18), r)
        dl:AddRect(va(x1, y1), vb(x2, y2), rgba(col, 0.90), r, 0, 1)
        if (kind == 'set') then dl:AddCircleFilled(va(x1 + 7, cy), 3, rgba(col, 1.0), 12) end
    elseif (kind == 'plain') then
        dl:AddRect(va(x1, y1), vb(x2, y2), rgba(PLAIN_EDGE, 0.45), r, 0, 1)
    else
        local grey = rgba(PILL_GREY, 0.60)
        local ox, oy = x1 + 0.5, y1 + 0.5
        for _, d in ipairs(dashes(math.floor(x2 - x1 - 1), math.floor(h - 1))) do
            dl:AddLine(va(ox + d[1], oy + d[2]), vb(ox + d[3], oy + d[4]), grey, 1)
            dl:AddLine(va(ox + d[3], oy + d[4]), vb(ox + d[5], oy + d[6]), grey, 1)
        end
        dl:AddCircle(va(x1 + 7, cy), 2.6, rgba(PILL_GREY, 0.85), 12, 1.2)
    end
end
-- An outline split at x: left in colour a, right in b (the job box: main | sub).
function gcdisplay.SplitOutline(dl, x1, y1, x2, y2, split, a, b)
    local r = (y2 - y1) / 2
    if (dl.PushClipRect ~= nil) and (dl.PopClipRect ~= nil) then
        dl:PushClipRect(va(x1 - 1, y1 - 1), vb(split, y2 + 1), true)
        dl:AddRect(va(x1, y1), vb(x2, y2), rgba(a, 0.90), r, 0, 1)
        dl:PopClipRect()
        dl:PushClipRect(va(split, y1 - 1), vb(x2 + 1, y2 + 1), true)
        dl:AddRect(va(x1, y1), vb(x2, y2), rgba(b, 0.90), r, 0, 1)
        dl:PopClipRect()
    else
        dl:AddRect(va(x1, y1), vb(x2, y2), rgba(a, 0.90), r, 0, 1)
    end
end

-- The bar's pills, in this order: weapon | melee ws idle nuke weapon tank pup hoxne | def sir th kite proc +
-- the job's own toggles. Each as wide as its widest text, so the bar keeps its width while you cycle.
local BAR_ORDER = { 'MeleeSet', 'WsSet', 'IdleSet', 'NukeSet', 'Weapon', 'TankSet', 'PupMode', 'Hoxne' }
local BAR_LABEL = { MeleeSet = 'melee', WsSet = 'ws', IdleSet = 'idle', NukeSet = 'nuke', Weapon = 'weapon',
    TankSet = 'tank', PupMode = 'pup', Hoxne = 'hoxne' }
local BAR_TOGGLES = { 'SIR', 'TH', 'Kite', 'PROC', 'Burst', 'Death', 'String', 'SongLock' }
local TOGGLE_LABEL = { SIR = 'sir', TH = 'th', Kite = 'kite', PROC = 'proc', Burst = 'burst', Death = 'death',
    String = 'harp', SongLock = 'lock' }
local DEF_PARTS = { { 'DTset', 'dt' }, { 'MDTset', 'mdt' }, { 'Aminon', 'amin' } }
-- Click a pill: the command that cycles it, as the HUD's cells send (ctrl+click the weapon: /mset).
local BAR_CMD = { Weapons = 'wm', Main = 'mw', Sub = 'sw', Range = 'rw', Ammo = 'ammoset', MeleeSet = 'mset',
    WsSet = 'wsset', NukeSet = 'nukeset', Weapon = 'weapon', TankSet = 'tankset', Hoxne = 'hoxne',
    PupMode = 'pupmode', IdleSet = 'idleset' }
local BAR_TCMD = { DTset = 'dt', MDTset = 'mdt', Aminon = 'aminon', SIR = 'sir', TH = 'th', Kite = 'kite',
    Burst = 'burst',
    PROC = 'proc', String = 'forcestring', SongLock = 'songlock', Death = 'death' }
-- The weapon pill: the weapon mode (else the main pick, e.g. PLD), a + when a slot pick (/mw /sw /ammoset) is changed;
-- a Range pick (/rw) gets its own pill beside it.
-- A job without either shows melee, ws and hoxne only once changed (most mages never touch them).
local SLOT_PICKS = { 'Main', 'Sub', 'Range', 'Ammo' }
local WEAPONLESS = { MeleeSet = true, WsSet = true, Hoxne = true }

local function xy(a, b)
    if (type(a) == 'table') then return tonumber(a[1] or a.x), tonumber(a[2] or a.y) end
    return tonumber(a), tonumber(b)
end

local function value_text(k, v) -- a weapon's text, as typed (Anarchy+)
    v = tostring(v)
    if (v == 'None') or (v == 'Off') then return '-' end
    if (inc ~= nil) and (inc.ModeLabel ~= nil) then return tostring(inc.ModeLabel(k, v)) end
    return v
end

-- Per-character bar state (x, y, on) in config\addons\luashitacast\gcbar\<name>.txt,
-- kept out of the hud folder so gchud never reads it.
local function bar_path()
    local p = gData.GetPlayer()
    if (p == nil) or (p.Name == nil) or (p.Name == '') then return nil, nil end
    return string.format('%sconfig\\addons\\luashitacast\\gcbar\\', AshitaCore:GetInstallPath()), p.Name .. '.txt'
end

local function bar_save()
    local dir, file = bar_path()
    if (dir == nil) then return end
    if not ashita.fs.exists(dir) then ashita.fs.create_directory(dir) end
    local f = io.open(dir .. file, 'w')
    if (f == nil) then return end
    local x = (tonumber(cfg.DisplayBarX) ~= nil) and string.format('%d', cfg.DisplayBarX) or 'auto'
    f:write(string.format('%s,%d,%s,%s', x, cfg.DisplayBarY or 0, (cfg.DisplayBar == true) and 'on' or 'off',
        tostring(tonumber(cfg.DisplayBarScale) or 1)))
    f:close()
end

local function bar_load()
    local dir, file = bar_path()
    if (dir == nil) then return end
    local f = io.open(dir .. file, 'r')
    if (f == nil) then return end
    local text = f:read('*a') or ''
    f:close()
    local x, y, on, scale = string.match(text, '^(%-?%w+),(%-?%d+),(%a+),?([%d%.]*)')
    if (x == nil) then return end
    cfg.DisplayBarScale = tonumber(scale) -- nil (an older file): 1
    if (x == '300') and (y == '0') then x = 'auto' end -- the old default, never dragged
    cfg.DisplayBarX, cfg.DisplayBarY = tonumber(x), tonumber(y) -- 'auto': nil
    cfg.DisplayBar = (on == 'on')
end

-- Dragged (moved from where it was put, after a mouse press): that spot is saved and kept (no longer auto).
local function track_drag(ownDy) -- ownDy: px from the window's top to this box's own line (the drop rising above it)
    local x, y = xy(imgui.GetWindowPos())
    if (x == nil) or (y == nil) or imgui.IsMouseDown(0) or not heldSeen then return end
    heldSeen = false
    x, y = math.floor(x + 0.5), math.floor(y + (ownDy or 0) + 0.5)
    -- a click, not a drag
    if (placedX ~= nil) and (math.abs(x - placedX) <= 1) and (math.abs(y - (placedY or 0)) <= 1) then return end
    if (y > 0) and (y <= 8) then y = 0; barPlaced = false end -- dropped near the top: flush with it
    cfg.DisplayBarX, cfg.DisplayBarY = x, y
    placedX, placedY = x, y
    bar_save()
end

-- Lines: this box's (the bar) and, hovered with /gchud on, one per other box dropped under it (gchud's rows), every
-- pill in its column: as wide as its widest text so far, blank where a line's job has no such mode.
local hud = nil -- gchud: the other boxes' modes, and sending them a click
local menuFor = nil -- the box whose pill menu is open (nil: this one)
local menuKey = nil -- that menu: 'wpn' (weapon modes and picks) or a mode's cycle name
local menuCol = nil -- the right-clicked pill's colour: the current weapon mode drawn as on the bar
-- the frame being drawn; s: /gcbar scale
local B = { dl = nil, lh = 0, wx = nil, first = true, gapNext = nil, extra = 0, s = 1, menu = false }
-- Hover text: each pill's name, before its full value.
local TIP_NAME = { Weapons = 'Weapon mode', Main = 'Main pick', Sub = 'Sub pick', Range = 'Range pick',
    Ammo = 'Ammo pick',
    MeleeSet = 'Melee mode', WsSet = 'WS mode', IdleSet = 'Idle mode', NukeSet = 'Nuke mode', Weapon = 'Mage weapon',
    TankSet = 'Tank mode', PupMode = 'Pup mode', Hoxne = 'Hoxne', SIR = 'SIR set', TH = 'TH',
        Kite = 'Kite', PROC = 'Proc',
    Burst = 'Burst on every nuke', Death = 'Death set', String = 'Forced harp', SongLock = 'Song lock' }
local menuLists = { until_ = 0 } -- that box's lists, as last read
local barH = nil -- the bar's own height (its line alone), measured while the drop is shut
function gcdisplay.SetHud(h) hud = h end
local gear = nil -- gcgear: a dropped box's gear, shown when its name is hovered
function gcdisplay.SetGear(g) gear = g end
local LINE_COLS = { 'wpn', 'Main', 'Sub', 'Range', 'Ammo', 'MeleeSet', 'WsSet', 'IdleSet', 'NukeSet', 'Weapon',
    'TankSet', 'PupMode', 'Hoxne', '|', 'Def', 'SIR', 'TH', 'Kite', 'PROC', 'Burst', 'Death', 'String', 'SongLock' }
-- One line's pills by column. cyc(k): value, still at its load default; vals(k): every value (own box only, for
-- widths);
-- tog(k): true / false / nil (the job has none).
local function build_line(cyc, vals, tog, wclass)
    local map = {}
    local wk = (cyc('Weapons') ~= nil) and 'Weapons' or ((cyc('Main') ~= nil) and 'Main' or nil)
    if (wk ~= nil) then
        local picked = false
        for _, k in ipairs(SLOT_PICKS) do
            local v, d = cyc(k)
            if (k == 'Range') and (k ~= wk) and (v ~= nil) and (value_text(k, v) ~= '-') then
                -- the gun or bow, its own pill (COR/RNG: /wm is the melee pair, /rw the gun)
                local texts = {}
                for _, x in ipairs(vals(k) or {}) do texts[#texts + 1] = value_text(k, x) end
                map.Range = { kind = 'plain', text = value_text(k, v), texts = texts, cmd = BAR_CMD[k],
                    col = WEAPON_COL[item_class(v) or ''],
                    menu = 'wpn', tip = { 'Range pick: ' .. tostring(v),
                        'Click: next\nRight-click: weapon modes and picks' } }
            elseif (k ~= wk) and (v ~= nil) and (value_text(k, v) ~= '-') and not d then
                picked = true -- set, and not the job's own default pick (PLD's Aegis): a + means you changed one
            end
        end
        local texts = {}
        for _, x in ipairs(vals(wk) or {}) do texts[#texts + 1] = value_text(wk, x) .. '+' end
        local ctrl = (cyc('MeleeSet') ~= nil) and 'mset' or nil
        map.wpn = { kind = 'plain', text = value_text(wk, (cyc(wk))) .. (picked and '+' or ''), texts = texts,
            cmd = BAR_CMD[wk],
            ctrl = ctrl, col = WEAPON_COL[wclass(wk, (cyc(wk))) or ''], menu = 'wpn',
            tip = { TIP_NAME[wk] .. ': ' .. tostring((cyc(wk))),
                (picked and '+: a slot pick changed\n' or '') .. 'Click: next'
                .. (ctrl and '\nCtrl+click: next melee mode' or '') .. '\nRight-click: weapon modes and picks' } }
    else
        for _, k in ipairs(SLOT_PICKS) do -- no weapon pill to carry them: each once changed
            local v, d = cyc(k)
            if (v ~= nil) and not d then
                map[k] = { kind = 'plain', text = value_text(k, v), cmd = BAR_CMD[k], menu = 'wpn',
                    tip = { TIP_NAME[k] .. ': ' .. tostring(v), 'Click: next\nRight-click: weapon picks' } }
            end
        end
    end
    for _, k in ipairs(BAR_ORDER) do
        local v = cyc(k)
        if (v ~= nil) then
            local kind, col = gcdisplay.ModeKind(k, v)
            if (wk ~= nil) or not WEAPONLESS[k] or (kind ~= 'def') then
                local texts = { BAR_LABEL[k] }
                for _, x in ipairs(vals(k) or {}) do texts[#texts + 1] = gcdisplay.ModeText(k, x) end
                local menu = (k ~= 'Hoxne') and k or nil
                map[k] = { kind = kind, col = col, text = (kind == 'def') and BAR_LABEL[k] or gcdisplay.ModeText(k, v),
                    texts = texts, cmd = BAR_CMD[k],
                    menu = menu, tip = { TIP_NAME[k] .. ': ' .. tostring(v),
                        'Click: next' .. (menu and '\nRight-click: pick one' or '') } }
            end
        end
    end
    -- def: DT, MDT, Aminon as one pill (/def), the first on (+ when more)
    local parts, any = {}, false
    for _, p in ipairs(DEF_PARTS) do
        local on = tog(p[1])
        if (on ~= nil) then any = true end
        if (on == true) then parts[#parts + 1] = p end
    end
    if any then
        local first = parts[1]
        map.Def = { kind = (first ~= nil) and 'set' or 'def', col = (first ~= nil) and TOGGLE_COL[first[1]] or nil,
            text = (first ~= nil) and (first[2] .. ((#parts > 1) and '+' or '')) or 'def', texts = { 'def', 'dt+',
                'mdt+', 'amin+' }, cmd = 'def',
            tip = { 'Defense: ' .. ((first ~= nil) and string.upper(first[2]) or 'off'),
                'Click: next (DT > MDT > Aminon > off)' } }
    end
    for _, k in ipairs(BAR_TOGGLES) do
        local on = tog(k)
        if (on ~= nil) then
            map[k] = { kind = (on == true) and 'set' or 'def', col = TOGGLE_COL[k], text = TOGGLE_LABEL[k],
                cmd = BAR_TCMD[k],
                tip = { (TIP_NAME[k] or k) .. ': ' .. ((on == true) and 'on' or 'off'),
                    'Click: turn ' .. ((on == true) and 'off' or 'on') } }
        end
    end
    return map
end

local modelVer, ownLine = -1, nil -- this box's line: rebuilt when a toggle or cycle changes (gcdisplay's version)
local function own_line()
    if (modelVer ~= version) then
        ownLine = build_line(
            function(k) local c = Cycles[k]; if (c == nil) then return nil end; return c.Array[c.Index],
                gcdisplay.IsDefault('cycle', k) end,
            function(k) local c = Cycles[k]; return (c ~= nil) and c.Array or nil end,
            function(k) return Toggles[k] end,
            mode_class)
        modelVer = version
    end
    return ownLine
end
local function strip(raw) -- a shared value: '~' marks one still at its load default
    raw = tostring(raw or '')
    if (string.sub(raw, 1, 1) == '~') then return string.sub(raw, 2), true end
    return raw, false
end
local altLines = setmetatable({}, { __mode = 'k' }) -- per gchud row (kept while its content is unchanged)
local function alt_line(row)
    local l = altLines[row]
    if (l == nil) then
        l = build_line(
            function(k) local raw = row.Cycles[k]; if (raw == nil) then return nil end; return strip(raw) end,
            function() return nil end,
            function(k) local raw = row.Toggles[k]; if (raw == nil) then return nil end; return (strip(raw) == 'true') end,
            -- shared by that box
            function() return (row.Cycles.WpnClass ~= nil) and strip(row.Cycles.WpnClass) or nil end)
        altLines[row] = l
    end
    return l
end

local function textw(t)
    local w = imgui.CalcTextSize(t)
    if (type(w) == 'table') then w = w[1] or w.x end
    return tonumber(w) or 0
end

local colW, colUnit = {}, nil -- each column's widest text so far (px), until the text size changes
local leadW = {} -- px from the window's left to the end of each line's name/job part, by line ('' = this box)
-- This box's columns first, in bar order, then (after a divider) what only the other boxes have: your own pills sit
-- where they are whether the drop is open or shut, and the shut bar is only as wide as your line.
local function columns(lines)
    local unit = textw('M')
    if (unit ~= colUnit) then colUnit, colW, leadW = unit, {}, {} end
    local cols = { { id = '|' } }
    local function divider()
        if (cols[#cols].id ~= '|') then cols[#cols + 1] = { id = '|' } end
    end
    local function add(id)
        local w = colW[id] or 0
        for _, l in ipairs(lines) do
            local e = l[id]
            if (e ~= nil) then
                if (e.wu ~= unit) then
                    local tw = textw(e.text)
                    for _, t in ipairs(e.texts or {}) do tw = math.max(tw, textw(t)) end
                    e.w, e.wu = tw, unit
                end
                w = math.max(w, e.w)
            end
        end
        colW[id] = w
        local lead = ((id == 'wpn') or MODE_PLAIN[id]) and gcdisplay.PILL_PLAIN_LEAD or gcdisplay.PILL_LEAD
        cols[#cols + 1] = { id = id, lead = lead, pw = math.floor((lead + gcdisplay.PILL_TAIL) * B.s + w + 0.5) }
    end
    local own = lines[1]
    for _, id in ipairs(LINE_COLS) do
        if (id == '|') then divider() elseif (own[id] ~= nil) then add(id) end
    end
    local extra = false
    for _, id in ipairs(LINE_COLS) do
        if (id ~= '|') and (own[id] == nil) then
            for i = 2, #lines do
                if (lines[i][id] ~= nil) then
                    if not extra then divider(); extra = true end
                    add(id)
                    break
                end
            end
        end
    end
    if (cols[#cols].id == '|') then cols[#cols] = nil end
    return cols
end

local btnIds = {} -- '##gcl_<line><column>', made once per line and column
local function button_id(line, col)
    local t = btnIds[line]
    if (t == nil) then t = {}; btnIds[line] = t end
    local s = t[col]
    if (s == nil) then s = '##gcl_' .. line .. col; t[col] = s end
    return s
end
-- The helpers below are made once, not every frame (each frame's new closures and tables were garbage 60 times
-- a second); B is the frame being drawn.
local SEG, PGAP = 9, 5 -- px at scale 1: each side of a divider, between pills
local function place(gap)
    if B.first then B.first = false else imgui.SameLine(0, (B.gapNext or gap or 14) * B.s + B.extra) end
    B.gapNext, B.extra = nil, 0
end
local function run(name, cmd, ctrl) -- a click: this box runs it, or the other box (gchud)
    local ok, io = pcall(imgui.GetIO)
    -- gcclick: the new value is said in chat (an alt's comes back as [Name])
    cmd = 'gcclick ' .. ((ok and (io ~= nil) and io.KeyCtrl and ctrl) or cmd)
    if (name == nil) then AshitaCore:GetChatManager():QueueCommand(-1, '/lac fwd ' .. cmd)
    elseif (hud ~= nil) then hud.Send(name, cmd) end
end
local function put(text, col, gap)
    place(gap)
    imgui.PushStyleColor(ImGuiCol_Text, col)
    imgui.Text(text)
    imgui.PopStyleColor()
end
local function hold(text, widest) -- keep a number's spot as wide as its widest
    B.extra = math.max(0, textw(widest) - textw(text))
end
local function lead_end() -- window x just past this line's last item
    imgui.SameLine(0, 0)
    local x = imgui.GetCursorPosX() + B.extra
    B.extra = 0
    return x
end
-- the job box: two coloured texts, outlined main | sub, the outline turning at split
local function job_box(a, aCol, mid, b, bCol)
    local split = nil
    local x, y = xy(imgui.GetCursorScreenPos())
    put(a, aCol)
    if (mid ~= nil) then put(mid, COL_KEY, 0) end
    local s1, s2 = xy(imgui.GetItemRectMin()), xy(imgui.GetItemRectMax())
    if (s1 ~= nil) and (s2 ~= nil) then split = (mid ~= nil) and ((s1 + s2) / 2) or s2 end
    if (b ~= '') then put(b, bCol, 0) end
    if (x ~= nil) and (y ~= nil) and (split ~= nil) then
        local x2, y2 = xy(imgui.GetItemRectMax())
        local pad = 5 * B.s
        -- 1px in from the edge
        if (x2 ~= nil) and (y2 ~= nil) then gcdisplay.SplitOutline(B.dl, x - pad, y + 1, x2 + pad, y2 - 1,
            split, aCol, bCol) end
    end
end
-- Hovered pill: what it is, its full value and what each click does (built with the line, shown only on hover).
local TIP_PAD = { 8, 5 }
local function tip(e, name)
    if (e.tip == nil) or not imgui.IsItemHovered() then return end
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, TIP_PAD)
    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 8)
    imgui.BeginTooltip()
    imgui.PushStyleColor(ImGuiCol_Text, COL_HEAD)
    imgui.TextUnformatted(e.tip[1])
    imgui.PopStyleColor()
    imgui.PushStyleColor(ImGuiCol_Text, COL_KEY)
    imgui.TextUnformatted(e.tip[2])
    if (name ~= nil) then imgui.TextUnformatted('Runs on ' .. name) end
    imgui.PopStyleColor()
    imgui.EndTooltip()
    imgui.PopStyleVar(2)
end
local function cells(line, cols, name, id)
    local dl, lh, wx = B.dl, B.lh, B.wx
    local _, top = xy(imgui.GetCursorScreenPos()) -- this line's top (after an item the cursor moves on)
    for _, c in ipairs(cols) do
        if (c.id == '|') then
            if (wx ~= nil) and (top ~= nil) then
                dl:AddLine(va(wx + c.x, top + 1), vb(wx + c.x, top + lh - 1), imgui.GetColorU32(COL_DIV), 1)
            end
        else
            local e = line[c.id]
            if (e ~= nil) then
                imgui.SameLine(c.x)
                local x, y = xy(imgui.GetCursorScreenPos())
                if imgui.Button(button_id(id, c.id), va(c.pw, lh)) and (e.cmd ~= nil) then run(name, e.cmd, e.ctrl) end
                if (e.menu ~= nil) and imgui.IsItemClicked(1) then
                    menuFor, menuKey, menuCol = name, e.menu, e.col
                    imgui.OpenPopup((e.menu == 'wpn') and '##gcbar_wpn' or '##gcbar_mode')
                end
                tip(e, name)
                if (x ~= nil) and (y ~= nil) then
                    gcdisplay.Pill(dl, x, y + 1, x + c.pw, y + lh - 1, e.kind, e.col)
                    dl:AddText(va(x + c.lead * B.s, y),
                        imgui.GetColorU32((e.kind == 'def') and COL_PILL_DIM or COL_PILL_TEXT), e.text)
                end
            end
        end
    end
end
local function rule() -- a thin line between the bar and the dropped boxes, across the window
    local _, y = xy(imgui.GetCursorScreenPos())
    local ww = xy(imgui.GetWindowSize())
    if (B.wx ~= nil) and (y ~= nil) and (ww ~= nil) then
        B.dl:AddLine(va(B.wx, y - 2), vb(B.wx + ww, y - 2), imgui.GetColorU32(COL_DIV), 1)
    end
end
local function own_row(L)
    B.first = true
    if (headText ~= '') then -- set by Update
        job_box(Main .. tostring(MainLV or ''), job_col(Main), '/', Sub .. tostring(SubLV or ''), job_col(Sub))
    else
        put(headText, COL_HEAD)
    end
    -- labelled, so it doesn't read as HP
    put('Atk ', COL_KEY, 13); put(tostring(Attk), COL_HEAD, 0); hold(tostring(Attk), '0000')
    put('Def ', COL_KEY, 8); put(tostring(Def), COL_HEAD, 0); hold(tostring(Def), '0000')
    leadW[''] = lead_end()
    cells(L.lines[1], L.cols, nil, 'me')
end
local function alt_row(L, drop, i)
    local r = drop[i]
    B.first = true
    local x0, y0 = xy(imgui.GetCursorScreenPos())
    local short = r.Name
    local mj, sj = string.match(tostring(r.Job or ''), '^(%a+)'), string.match(tostring(r.Job or ''), '/(%a+)')
    local half = math.ceil(#short / 2)
    -- first half of the letters in the main job's colour, the rest the sub's, outlined the same
    job_box(string.sub(short, 1, half), job_col(mj), nil, string.sub(short, half + 1), job_col(sj or mj))
    put(tostring(r.Job or ''), COL_KEY, 13)
    if (gear ~= nil) and (x0 ~= nil) and (y0 ~= nil) then -- its name and job hovered: that box's gear (/gcgear)
        local x1, y1 = xy(imgui.GetItemRectMax())
        if (x1 ~= nil) and (y1 ~= nil) and imgui.IsWindowHovered() and imgui.IsMouseHoveringRect(va(x0, y0), vb(x1, y1))
            then gear.AltTip(r.Name, r.Job) end
    end
    leadW[r.Name] = lead_end()
    cells(L.lines[i + 1], L.cols, r.Name, r.Name)
end

-- Lines and columns: rebuilt only when this box's modes, the dropped boxes or the text size change.
local L = { ver = -1, drop = false, unit = nil, lines = nil, names = nil, cols = nil }
local function layout(drop)
    local unit = textw('M')
    if (L.ver ~= version) or (L.drop ~= (drop or false)) or (L.unit ~= unit) or (L.cols == nil) then
        local lines, names = { own_line() }, { '' }
        for _, r in ipairs(drop or {}) do lines[#lines + 1] = alt_line(r); names[#names + 1] = r.Name end
        L.ver, L.drop, L.unit, L.lines, L.names = version, drop or false, unit, lines, names
        L.cols = columns(lines)
    end
    return L
end

-- Right-click on a pill: the weapon pill lists that box's weapon modes and slot picks side by side; any other mode
-- pill lists its values. A click runs the same command as typing it, by number (/wm 3, /mset 2), on that box.
-- Drawn like the bar: its background and edge, rounded; each value a pill-sized button, the current one drawn as
-- the bar draws it, the others as text with the pills' soft hover.
local MENU_COLS = { { 'Weapons', 'mode' }, { 'Main', 'main' }, { 'Sub', 'sub' }, { 'Range', 'range' },
    { 'Ammo', 'ammo' } }
local MENU_PAD, MENU_GAP, MENU_COL_GAP = { 8, 6 }, { 6, 2 }, 8
local function menu_lists(drop) -- the open menu's box: its lists and current values
    local lists, now = {}, {}
    if (menuFor == nil) then
        for k, c in pairs(Cycles) do lists[k], now[k] = c.Array, c.Array[c.Index] end
    elseif (hud ~= nil) and (hud.Lists ~= nil) then
        if (menuLists.name ~= menuFor) or (os.clock() > menuLists.until_) then -- read once a second, not every frame
            menuLists = { name = menuFor, lists = hud.Lists(menuFor) or {}, until_ = os.clock() + 1 }
        end
        lists = menuLists.lists
        for _, r in ipairs(drop or {}) do
            if (r.Name == menuFor) then
                for k, raw in pairs(r.Cycles or {}) do now[k] = (string.gsub(tostring(raw), '^~', '')) end
            end
        end
    end
    return lists, now
end
-- Pushed before a menu's BeginPopup (the popup reads them as it opens), popped after it whether it opened or not.
local function push_menu()
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, MENU_PAD)
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, MENU_GAP)
    imgui.PushStyleVar(ImGuiStyleVar_PopupRounding, 10)
    if (ImGuiStyleVar_FrameRounding ~= nil) then imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, B.lh / 2); return 4 end
    return 3
end
local function label(text, x)
    if (x ~= nil) then imgui.SameLine(x) end
    imgui.PushStyleColor(ImGuiCol_Text, COL_KEY)
    imgui.TextUnformatted(text)
    imgui.PopStyleColor()
end
-- One value: a pill-sized button; the current one as its pill (kind, col), none dimmed.
local function menu_item(id, text, w, lead, current, kind, col, dim)
    local x, y = xy(imgui.GetCursorScreenPos())
    local clicked = imgui.Button(id, va(w, B.lh))
    if (x ~= nil) and (y ~= nil) then
        local dl = imgui.GetWindowDrawList() -- the menu's own
        if current then gcdisplay.Pill(dl, x, y + 1, x + w, y + B.lh - 1, kind, col) end
        dl:AddText(va(x + lead * B.s, y), imgui.GetColorU32(dim and COL_PILL_DIM or COL_PILL_TEXT), text)
    end
    return clicked
end
-- This box's menus end with '+ new mode...': /gcedit opens on the new mode (gcinclude.EditorRequest). Not on another
-- box's line: its editor would open on that box's screen.
local NEW_MODE, ADD_PICK = '+ new mode...', '+ add...'
-- each column's last row on this box's weapon menu: what it asks /gcedit for, and its hover text
local MENU_ADD = {
    Weapons = { NEW_MODE, 'wm', 'A /wm mode: /gcedit opens on New set, Weapon_ typed (as its WEAPONS heading\'s '
        .. '+ /wm mode).' },
    Main = { ADD_PICK, 'MainModes', '/mw picks: /gcedit Settings opens on MainModes. Every Main in a Weapon_ set is '
        .. 'one already.' },
    Sub = { ADD_PICK, 'SubModes', '/sw picks: /gcedit Settings opens on SubModes. Every Sub in a Weapon_ set is one '
        .. 'already.' },
    Range = { ADD_PICK, 'RangeModes', '/rw picks: /gcedit Settings opens on RangeModes. Every Range in a Weapon_ set '
        .. 'is one already.' },
    Ammo = { ADD_PICK, 'AmmoModes', '/ammoset picks: /gcedit Settings opens on AmmoModes.' },
}
local function ctrl_down()
    local ok, io = pcall(imgui.GetIO)
    return ok and (io ~= nil) and (io.KeyCtrl == true)
end
local function menu_tip(text)
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, TIP_PAD)
    imgui.BeginTooltip()
    imgui.PushStyleColor(ImGuiCol_Text, COL_KEY)
    imgui.TextUnformatted(text)
    imgui.PopStyleColor()
    imgui.EndTooltip()
    imgui.PopStyleVar()
end
local function new_mode_item(id, x, w, kind, tipText, text)
    if (x ~= nil) then imgui.SameLine(x) end -- under its column
    if menu_item(id, text or NEW_MODE, w, gcdisplay.PILL_PLAIN_LEAD, false, 'plain', nil, true) then
        if (inc ~= nil) and (inc.EditorRequest ~= nil) then inc.EditorRequest(kind) end
        imgui.CloseCurrentPopup()
    end
    if imgui.IsItemHovered() then menu_tip(tipText) end
end
local function weapon_menu(drop)
    local vars = push_menu()
    local shown = imgui.BeginPopup('##gcbar_wpn')
    if shown then
        local lists, now = menu_lists(drop)
        local cols, rows = {}, 0
        local x = MENU_PAD[1] * B.s
        for _, mc in ipairs(MENU_COLS) do
            local list = lists[mc[1]]
            if (type(list) == 'table') and (#list > 1) then
                local c = { key = mc[1], label = mc[2], list = list, texts = {} }
                local w = textw(mc[2])
                if (menuFor == nil) and (MENU_ADD[mc[1]] ~= nil) then w = math.max(w, textw(MENU_ADD[mc[1]][1])) end
                for i, v in ipairs(list) do
                    c.texts[i] = (v == 'None') and 'none' or value_text(mc[1], v)
                    w = math.max(w, textw(c.texts[i]))
                end
                c.lead = gcdisplay.PILL_PLAIN_LEAD
                c.w = math.floor(w + (c.lead + gcdisplay.PILL_TAIL) * B.s + 0.5)
                c.x, x, rows = x, x + c.w + MENU_COL_GAP * B.s, math.max(rows, #list)
                cols[#cols + 1] = c
            end
        end
        if (#cols == 0) then
            label((menuFor ~= nil) and (menuFor .. ': no weapon lists shared yet') or 'No weapon modes or picks')
            if (menuFor == nil) then
                new_mode_item('##gcbar_newwm', nil, math.floor(textw(NEW_MODE) + 12 * B.s), 'wm',
                    'A /wm mode: /gcedit opens on New set, Weapon_ typed.')
            end
        else
            for i, c in ipairs(cols) do label(c.label, (i > 1) and c.x or nil) end
            for r = 1, rows do
                for i, c in ipairs(cols) do
                    if (i > 1) then imgui.SameLine(c.x) end
                    local v = c.list[r]
                    if (v == nil) then
                        imgui.Dummy(va(c.w, B.lh))
                    else
                        local current = (v == now[c.key])
                        local col = (c.key == 'Weapons') and menuCol or WEAPON_COL[item_class(v) or '']
                        if menu_item('##gcbar_mi' .. c.key .. '_' .. r, c.texts[r], c.w, c.lead, current, 'plain', col,
                            v == 'None') then
                            if (c.key == 'Weapons') and (menuFor == nil) and (v ~= 'None') and ctrl_down()
                                and (inc ~= nil) and (inc.EditorCommand ~= nil) then
                                inc.EditorCommand('Weapon_' .. v) -- ctrl+click: its set in /gcedit
                            else
                                run(menuFor, BAR_CMD[c.key] .. ' ' .. r)
                            end
                            imgui.CloseCurrentPopup()
                        end
                        if (c.key == 'Weapons') and (menuFor == nil) and (v ~= 'None') and imgui.IsItemHovered() then
                            menu_tip('Click: /wm ' .. string.lower(tostring(v)) .. '\nCtrl+click: edit Weapon_' .. v
                                .. ' in /gcedit')
                        end
                    end
                end
            end
            if (menuFor == nil) then -- one last row: + new mode... under the modes, + add... under each pick list
                for i, c in ipairs(cols) do
                    local a = MENU_ADD[c.key]
                    if (a ~= nil) then
                        new_mode_item('##gcbar_add' .. c.key, (i > 1) and c.x or nil, c.w, a[2], a[3], a[1])
                    elseif (i == 1) then
                        imgui.Dummy(va(c.w, B.lh))
                    end
                end
            end
        end
        imgui.EndPopup()
    end
    imgui.PopStyleVar(vars)
    return shown
end
local function mode_menu(drop)
    local vars = push_menu()
    local shown = imgui.BeginPopup('##gcbar_mode')
    if shown then
        local k = menuKey
        local lists, now = menu_lists(drop)
        local list = lists[k]
        label((TIP_NAME[k] or tostring(k)) .. ((menuFor ~= nil) and (' on ' .. menuFor) or ''))
        if (type(list) ~= 'table') or (#list == 0) then
            label((menuFor ~= nil) and 'not shared by that box yet' or 'no values')
        else
            local w = 0
            local own = (k == 'MeleeSet') and (menuFor == nil) -- this box's melee modes: + new mode...
            for _, v in ipairs(list) do w = math.max(w, textw(tostring(v))) end
            if own then w = math.max(w, textw(NEW_MODE)) end
            w = math.floor(w + (gcdisplay.PILL_LEAD + gcdisplay.PILL_TAIL) * B.s + 0.5)
            for i, v in ipairs(list) do
                local kind, col = gcdisplay.ModeKind(k, v)
                if menu_item('##gcbar_mi' .. tostring(k) .. '_' .. i, tostring(v), w, gcdisplay.PILL_LEAD, v == now[k],
                    kind, col, false) then
                    run(menuFor, BAR_CMD[k] .. ' ' .. i)
                    imgui.CloseCurrentPopup()
                end
            end
            if own then
                new_mode_item('##gcbar_newms', nil, w, 'mset',
                    'A /mset mode of your own: /gcedit opens on its popup (the name, then the sets to make for it).')
            end
        end
        imgui.EndPopup()
    end
    imgui.PopStyleVar(vars)
    return shown
end

local function bar_body(drop, open, up) -- drop: the other boxes (their columns hold even while shut)
    -- Pills, lines and outlines are drawn shapes on the window's draw list.
    B.dl, B.lh, B.wx = imgui.GetWindowDrawList(), imgui.GetTextLineHeight(), xy(imgui.GetWindowPos())
    B.first, B.gapNext, B.extra = true, nil, 0
    local s = B.s
    local lay = layout(drop)
    local lead = 0
    for _, n in ipairs(lay.names) do lead = math.max(lead, leadW[n] or 0) end
    local x, prevPill = lead, false
    for _, c in ipairs(lay.cols) do -- positions only: the lead moves with Atk/Def and the job text
        if (c.id == '|') then c.x = x + SEG * s; x = c.x + SEG * s; prevPill = false
        else
            if prevPill then x = x + PGAP * s end
            c.x, x, prevPill = x, x + c.pw, true
        end
    end
    B.endX = x -- the open drop's right end (window x): the auto spot leaves room for it, shut or open
    local n = open and #(drop or {}) or 0
    if up then -- the drop rises above the bar: the other boxes first, this box's line last (at the bottom)
        for i = 1, n do alt_row(lay, drop, i) end
        if (n > 0) then rule() end
        own_row(lay)
    else
        own_row(lay)
        if (n > 0) then rule() end
        for i = 1, n do alt_row(lay, drop, i) end
    end
    B.menu = weapon_menu(drop)
    B.menu = mode_menu(drop) or B.menu -- shown: the drop stays open (render_bar)
    track_drag((up and (barH ~= nil)) and ((select(2, xy(imgui.GetWindowSize())) or barH) - barH) or 0)
end

-- Hovered with /gchud on: the other boxes drop in; in the screen's bottom half they rise above the bar instead.
local hoverUntil, closedFrames, dropUp, barW = 0, 0, false, nil
local function viewport_h() return imgui.GetMainViewport().Size.y end
local function viewport_w() return imgui.GetMainViewport().Size.x end
local function screen_h()
    local ok, h = pcall(viewport_h)
    return ok and tonumber(h) or nil
end
local function screen_w()
    local ok, w = pcall(viewport_w)
    return ok and tonumber(w) or nil
end
-- Made once, not every frame: imgui reads these when they are pushed and keeps none of them.
local BAR_PAD, BAR_GAP, PILL_PAD, PIVOT_BOTTOM = { 10, 1 }, { 5, 3 }, { 1, 0 }, { 0, 1 }
local COL_NONE, COL_PILL_HOVER = { 0, 0, 0, 0 }, { 1, 1, 1, 0.12 }
local barBg, barPos, barFlags = { COL_BAR_BG[1], COL_BAR_BG[2], COL_BAR_BG[3], 0.70 }, { 0, 0 }, nil
local menuBg = { COL_BAR_BG[1], COL_BAR_BG[2], COL_BAR_BG[3], 0.94 } -- menus and hover text: the bar's, nearly opaque
-- Hidden with the game's interface (its hide-UI key), in cutscenes and while zoning, as Thorny's tHotBar and
-- luashitaview do (same FFXiMain signatures); also when Ashita's own GUI is hidden.
local pInterfaceHidden, pEventSystem = 0, 0
if (ashita ~= nil) and (ashita.memory ~= nil) then
    pInterfaceHidden = ashita.memory.find('FFXiMain.dll', 0,
        '8B4424046A016A0050B9????????E8????????F6D81BC040C3', 0, 0) or 0
    pEventSystem = ashita.memory.find('FFXiMain.dll', 0,
        'A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3', 0, 0) or 0
end
local function ui_hidden()
    if (pInterfaceHidden ~= 0) then
        local ptr = ashita.memory.read_uint32(pInterfaceHidden + 10)
        if (ptr ~= 0) and (ashita.memory.read_uint8(ptr + 0xB4) == 1) then return true end
    end
    if (pEventSystem ~= 0) then
        local ptr = ashita.memory.read_uint32(pEventSystem + 1)
        if (ptr ~= 0) and (ashita.memory.read_uint8(ptr) == 1) then return true end
    end
    if (AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0) == 0) then return true end -- zoning
    return (AshitaCore:GetGuiManager():GetVisible() == false)
end
function gcdisplay.UiHidden() -- for /gcgear's window: hidden when the bar is
    local ok, hidden = pcall(ui_hidden)
    return ok and (hidden == true)
end

-- /gcbar scale: Ashita's ImGui (1.92) sizes a font when it is pushed (PushFont(font, size)); an older one has
-- SetWindowFontScale. True when a font was pushed (popped before End).
local function scale_font(s)
    if (imgui.SetWindowFontScale ~= nil) then imgui.SetWindowFontScale(s); return false end
    return pcall(function() imgui.PushFont(imgui.GetFont(), imgui.GetStyle().FontSizeBase * s) end) == true
end

-- Hovered with /gchud on: the other boxes drop in; in the screen's bottom half they rise above the bar instead.
local function render_bar()
    if (cfg == nil) or (cfg.DisplayBar ~= true) then return end
    local okHidden, hidden = pcall(ui_hidden) -- a failed read never costs the bar
    if okHidden and hidden then return end
    local now = os.clock()
    local drop = (hud ~= nil) and hud.DropRows() or nil
    local open = (drop ~= nil) and (#drop > 0) and ((now < hoverUntil) or B.menu) -- B.menu: a menu shown last frame
    local held = imgui.IsMouseDown(0)
    if held then heldSeen = true end
    -- Not dragged yet (DisplayBarX unset, or /gcbar pos auto): centred at the top, or with the drop on (/gchud,
    -- HUDOwners) at the right, leaving room for the open drop (shut, it ends short of the edge); re-placed when that
    -- width changes.
    local tx, ty = tonumber(cfg.DisplayBarX), cfg.DisplayBarY or 0
    if (tx == nil) then
        local sw = screen_w()
        local fullW = (B.endX ~= nil) and (B.endX + BAR_PAD[1] + 1) or barW -- open width: opening never moves the bar
        tx = ((sw ~= nil) and (barW ~= nil)) and math.max(0,
            math.floor((drop ~= nil) and (sw - (fullW or barW)) or ((sw - barW) / 2))) or 300
        if (tx ~= placedX) and not held then barPlaced = false end
    end
    if not held then
        local sh = screen_h()
        dropUp = (sh ~= nil) and ((ty + (barH or 0) / 2) > sh / 2)
    end
    local up = open and dropUp and (barH ~= nil)
    if up and not held then -- pin this box's line (the bottom) where it is
        barPos[1], barPos[2] = tx, ty + barH
        imgui.SetNextWindowPos(barPos, ImGuiCond_Always, PIVOT_BOTTOM)
        placedX, placedY, barPlaced = tx, ty, false
    elseif (not barPlaced) and not held then
        barPos[1], barPos[2] = tx, ty
        imgui.SetNextWindowPos(barPos, ImGuiCond_Always)
        placedX, placedY, barPlaced = tx, ty, true
    end
    if (barFlags == nil) then
        barFlags = bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing,
            ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoResize)
    end
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, BAR_PAD) -- 1px above and below the text: room for the job outline
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, BAR_GAP) -- 3px between dropped lines
    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 12) -- a capsule
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1)
    imgui.PushStyleVar(ImGuiStyleVar_PopupBorderSize, 1)
    -- pills are borderless buttons under their drawn outline: hovered, a soft fill as round as the pill
    local styleVars = 5
    if (ImGuiStyleVar_FramePadding ~= nil) then
        imgui.PushStyleVar(ImGuiStyleVar_FramePadding, PILL_PAD); styleVars = styleVars + 1
    end
    if (ImGuiStyleVar_FrameBorderSize ~= nil) then
        imgui.PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0); styleVars = styleVars + 1
    end
    if (ImGuiStyleVar_FrameRounding ~= nil) then
        imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 7); styleVars = styleVars + 1
    end
    imgui.PushStyleColor(ImGuiCol_WindowBg, barBg)
    imgui.PushStyleColor(ImGuiCol_PopupBg, menuBg) -- the menus and hover text opened from the bar
    imgui.PushStyleColor(ImGuiCol_Border, COL_EDGE)
    imgui.PushStyleColor(ImGuiCol_Button, COL_NONE)
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, COL_PILL_HOVER)
    imgui.PushStyleColor(ImGuiCol_ButtonActive, COL_PILL_HOVER)
    local ok, why, pushed = true, nil, false
    if imgui.Begin('GC##gcdisplay_bar', true, barFlags) then
        B.s = tonumber(cfg.DisplayBarScale) or 1
        if (B.s ~= 1) then
            pushed = scale_font(B.s)
            -- neither way: pills stay matched to the text
            if (not pushed) and (imgui.SetWindowFontScale == nil) then B.s = 1 end
        end
        -- an error here must not skip End/PopStyleVar, or ImGui asserts every frame after (as in gchud)
        ok, why = pcall(bar_body, drop, open, up)
        -- a menu open: the drop stays
        if ((imgui.IsWindowHovered ~= nil) and imgui.IsWindowHovered()) or B.menu then hoverUntil = now + 0.6 end
        closedFrames = open and 0 or (closedFrames + 1)
        local w = xy(imgui.GetWindowSize())
        if (w ~= nil) and (w > 0) then barW = math.floor(w + 0.5) end
        if (closedFrames >= 3) then -- the bar's own height, once the window has fit it
            local _, h = xy(imgui.GetWindowSize())
            if (h ~= nil) and (h > 0) then barH = h end
        end
        if pushed then imgui.PopFont() end
    end
    imgui.End()
    imgui.PopStyleColor(6)
    imgui.PopStyleVar(styleVars)
    if (ok ~= true) then error(why, 0) end
end

function gcdisplay.BarCommand(args)
    if (cfg == nil) then return end
    local arg = (args[2] ~= nil) and string.lower(args[2]) or nil
    if (arg == 'pos') and (tonumber(args[3]) ~= nil) and (tonumber(args[4]) ~= nil) then
        cfg.DisplayBarX, cfg.DisplayBarY = tonumber(args[3]), tonumber(args[4])
        barPlaced = false
        bar_save()
        return
    -- back to the auto spot
    elseif (arg == 'reset') or ((arg == 'pos') and (string.lower(tostring(args[3])) == 'auto')) then
        cfg.DisplayBarX, cfg.DisplayBarY = nil, 0
        barPlaced = false
        bar_save()
        return
    elseif (arg == 'scale') then -- /gcbar scale [0.5-3]: text and pills, saved per character
        local n = tonumber(args[3])
        if (n == nil) then
            say('Bar scale: ' .. tostring(tonumber(cfg.DisplayBarScale) or 1) .. ' (/gcbar scale 0.5-3)'); return
        end
        cfg.DisplayBarScale = math.max(0.5, math.min(3, n))
        barPlaced = false
        bar_save()
        say('Bar scale: ' .. tostring(cfg.DisplayBarScale))
        return
    -- /gcbar theme [name|goomui|goomswap]: try a preset until reload (Theme in char.lua keeps one)
    elseif (arg == 'theme') then
        local presets = gctheme()
        local want = (args[3] ~= nil) and string.lower(args[3]) or nil
        if (want == nil) then
            say('Theme: ' .. (gcdisplay.Theme or 'goomswap') .. '. Presets: ' .. table.concat(presets.ORDER, ' ')
                .. '; goomui (follow goomui), goomswap (own colours)')
            return
        end
        local name = (want == 'goomui') and presets.Resolve(nil, presets.GoomuiText()) or presets.Resolve(want)
        if (name == nil) and (want ~= 'goomswap') and (want ~= 'goomui') then
            err('No theme ' .. want .. ' (/gcbar theme lists them)')
            return
        end
        gcdisplay.ApplyTheme(name)
        say('Theme: ' .. (name or 'goomswap'))
        return
    elseif (arg == 'on') then cfg.DisplayBar = true
    elseif (arg == 'off') then cfg.DisplayBar = false
    elseif (arg == nil) then cfg.DisplayBar = (cfg.DisplayBar ~= true)
    else
        err('usage: /gcbar [on|off|pos x y|reset|scale N|theme name]')
        return
    end
    gcdisplay.Update()
    barPlaced = false
    bar_save()
    say('Display bar: ' .. (cfg.DisplayBar and 'On' or 'Off'))
end

function gcdisplay.Unload()
    ashita.events.unregister('d3d_present', 'gcdisplay_bar')
end

function gcdisplay.Initialize(settings, include)
    cfg = settings
    inc = include
    barPlaced = false
    pcall(bar_load)
    pcall(function() gcdisplay.ApplyTheme(gctheme().Resolve(settings.Theme or nil, gctheme().GoomuiText())) end)
    gcdisplay.Update()
    ashita.events.register('d3d_present', 'gcdisplay_bar', function ()
        local t0 = (inc ~= nil) and (inc.Perf ~= nil) and inc.PerfNow() or nil -- /gcperf
        local ok, why = pcall(render_bar)
        if (t0 ~= nil) then inc.PerfAdd('bar', t0) end
        if (not ok) and (cfg ~= nil) and (cfg.DisplayBar == true) then
            cfg.DisplayBar = false
            err('Display bar off after an error: ' .. tostring(why))
        end
    end)
end

return gcdisplay