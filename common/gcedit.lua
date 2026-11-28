-- Ashita /gcedit window. gcinclude loads this module on demand and closes it on unload.
-- File patches, navigation, panels, and inspection views live in separate helpers.
-- Job handlers are inspected as text, never executed by the editor.
-- Icons use game item bitmaps; texture loading follows Thorny's tHotBar (MIT).

local gcedit = {}
local editorUI = gFunc.LoadFile('common\\gceditui.lua')
local editorPreferences = editorUI.State
local editorPanels = editorUI.Panels
local jobAnalysis = gFunc.LoadFile('common\\gceditjob.lua')
local actionModel = gFunc.LoadFile('common\\gceditactions.lua')
local statModel = gFunc.LoadFile('common\\gceditstats.lua')
local actions
local rescued = nil -- the editor state a render error closed with unsaved edits (gcedit.Open restores it)
local editorInspect = editorUI.Inspect
local editorData = gFunc.LoadFile('common\\gceditdata.lua') -- constant tables
local editorGroups = gFunc.LoadFile('common\\gceditgroups.lua') -- heading order and your own headings
local setFile = gFunc.LoadFile('common\\gcsetfile.lua')
local editorFiles = gFunc.LoadFile('common\\gceditfiles.lua') -- other job files: copy a set in, find an item
local saveReview = editorUI.Review
local picker = editorUI.Picker
local profiler = editorUI.Profiler
local fileWriter = setFile
local augmentInfo = gFunc.LoadFile('common\\gcaugments.lua')
local cardText = editorUI.Card
local itemTooltip = editorUI.Tooltip
local bagScan = gFunc.LoadFile('common\\gceditbags.lua') -- owned gear, Storage Slips, every item
local augments_of, scan_owned, index_all_items, allItems =
    bagScan.AugmentsOf, bagScan.ScanOwned, bagScan.IndexAllItems, bagScan.AllItems

local imgui = require('imgui')
-- Use literal text so item stats containing % are not interpreted as formats. Wrapped at 440px, or at its widest
-- line when it came wrapped by hand (every line short: wrap()) and wider than that, so no line wraps twice.
local function set_tip(t)
    t = tostring(t)
    local at = 440
    if imgui.CalcTextSize ~= nil then
        local widest = 0
        for line in string.gmatch(t, '[^\n]+') do
            if #line > 72 then
                widest = 0
                break
            end
            local w = imgui.CalcTextSize(line)
            w = (type(w) == 'table') and (w.x or w[1]) or w
            if (type(w) == 'number') and (w > widest) then widest = w end
        end
        if widest > at then at = widest + 16 end
    end
    imgui.PushStyleColor(ImGuiCol_PopupBg, { 0.055, 0.06, 0.08, 1 })
    imgui.BeginTooltip()
    imgui.PushTextWrapPos(at)
    imgui.TextUnformatted(t)
    imgui.PopTextWrapPos()
    imgui.EndTooltip()
    imgui.PopStyleColor()
end
local ffi = require('ffi')
local d3d8 = require('d3d8')

local SCREEN = setFile.slots
local SLOT_BIT = editorData.SLOT_BIT
local NUM_SLOT = {}
for name, b in pairs(SLOT_BIT) do
    NUM_SLOT[b + 1] = name
end -- LAC slot numbers (constants.EquipSlotNames)

local gearEngine = nil -- gcinclude: Say / Err
local ctx = {} -- for code in other files: ctx.gearEngine and ctx.actions, kept current here
ctx.setFile = setFile -- the job file's reader (gcsetfile)
-- The open editor's state. One table for the module's life, emptied and refilled in place, so code split into
-- other files keeps a working reference. editorState.open: an editor is open.
local editorState = {}
local function set_state(new)
    for k in pairs(editorState) do editorState[k] = nil end
    if new ~= nil then
        for k, v in pairs(new) do editorState[k] = v end
        editorState.open = true
    end
end

local function feedback(text)
    editorPreferences.Feedback(editorState, text)
end

local function request_context(kind, set, slot, gear, source)
    editorState.ui.context = { kind = kind, set = set.name, slot = slot, gear = gear, source = source }
    editorState.ui.openContext = true
end


-- Static editor palette: blue focus, amber edits, violet RP; no animated effects.
-- /gcedit: palette and its colour-preset recolouring (gctheme, shared with goomui).
local palette = {
    bg = { 0.067, 0.082, 0.110, 0.97 },
    panel = { 0.082, 0.102, 0.137, 1.0 },
    cell = { 0.114, 0.137, 0.173, 1.0 },
    edge = { 0.208, 0.239, 0.294, 1.0 },
    sel = { 0.365, 0.647, 1.0, 1.0 },
    selBg = { 0.129, 0.204, 0.329, 1.0 },
    text = { 0.902, 0.910, 0.925, 1.0 },
    dim = { 0.604, 0.639, 0.698, 1.0 },
    section = { 0.525, 0.635, 0.796, 1.0 },
    blue = { 0.612, 0.776, 1.0, 1.0 },
    ok = { 0.435, 0.812, 0.557, 1.0 },
    armor = { 0.431, 0.784, 0.784, 1.0 },
    warn = { 0.941, 0.659, 0.376, 1.0 },
    bad = { 0.937, 0.490, 0.490, 1.0 },
    override = { 0.64, 0.72, 0.82, 1.0 },
    aug = { 0.773, 0.702, 1.0, 1.0 },
    rp = { 0.773, 0.702, 1.0, 1.0 },
    rpBg = { 0.169, 0.137, 0.224, 1.0 },
    save = { 0.184, 0.435, 0.839, 1.0 },
    saveHi = { 0.290, 0.525, 0.910, 1.0 },
    btn = { 0.176, 0.200, 0.251, 1.0 },
    btnHi = { 0.231, 0.267, 0.333, 1.0 }, -- plain buttons: grey, not the theme's red
    red = { 0.580, 0.227, 0.227, 1.0 },
    redHi = { 0.718, 0.290, 0.290, 1.0 }, -- only what drops something
    okBg = { 0.125, 0.227, 0.169, 1.0 },
    invBg = { 0.122, 0.180, 0.271, 1.0 },
    badBg = { 0.271, 0.133, 0.165, 1.0 }, -- pills
    warnBg = { 0.259, 0.184, 0.110, 1.0 },
    chipBg = { 0.122, 0.137, 0.169, 1.0 },
    grab = { 0.231, 0.267, 0.333, 1.0 },
    grabHi = { 0.302, 0.349, 0.431, 1.0 },
    title = { 0.122, 0.149, 0.204, 1.0 },
    shiny = { 0.867, 0.784, 0.478, 1.0 },
}
-- A menu row: full width, lit on hover. A click closes the menu, unless keepOpen (Move up / down, clicked again and
-- again). enabled false: greyed, never clicks. color: its text (palette.bad for what drops something).
ctx.menu_item = function(label, enabled, keepOpen, color)
    local off = (enabled ~= nil) and not enabled
    local disabled = off and (imgui.BeginDisabled ~= nil)
    if disabled then imgui.BeginDisabled() end
    if color then imgui.PushStyleColor(ImGuiCol_Text, color) end
    local clicked = imgui.Selectable(label, false, keepOpen and (ImGuiSelectableFlags_NoAutoClosePopups or 0) or 0)
    if color then imgui.PopStyleColor() end
    if disabled then imgui.EndDisabled() end
    return clicked and not off
end
-- A colour preset (gctheme, shared with goomui) recolours the state accents by meaning; base, text and button greys
-- stay. Own values are kept to restore.
local THEMED = { sel = 'mp', ok = 'hp_full', warn = 'hp_25', bad = 'hp_0', rp = 'tp_rdy', aug = 'tp_rdy',
    armor = 'spell',
    save = 'mp', saveHi = 'mp' }
-- backgrounds: their accent (as themed, below) mixed into the panel by amount
local TINTS = { selBg = { 'sel', 0.30 }, okBg = { 'ok', 0.22 }, warnBg = { 'warn', 0.22 }, badBg = { 'bad', 0.22 },
    rpBg = { 'rp', 0.18 } }
-- the set colours (list, borders, pills) a preset must not merge: first wins its shade
local APART = { 'bad', 'warn', 'rp', 'ok', 'armor' }
local SHADE = { save = 0.62, saveHi = 0.78 } -- button fills under white text
local ownPalette = {}
for _, keys in ipairs({ THEMED, TINTS }) do
    for key in pairs(keys) do
        local c = palette[key]
        ownPalette[key] = { c[1], c[2], c[3] }
    end
end
local themeMod = nil
local function themes() -- gctheme, read once (nil if it failed to load)
    if (themeMod == nil) then
        local ok, t = pcall(gFunc.LoadFile, 'common\\gctheme.lua')
        themeMod = (ok and (type(t) == 'table')) and t or false
    end
    return themeMod or nil
end
local function apply_theme(name)
    local gctheme = themes()
    if (gctheme == nil) or (gctheme.PRESETS[name or ''] == nil) then name = nil end
    for key, own in pairs(ownPalette) do
        local c = palette[key]
        c[1], c[2], c[3] = own[1], own[2], own[3]
    end
    if name == nil then return end
    for key, preset in pairs(THEMED) do
        local c, shade = gctheme.Color(name, preset), SHADE[key] or 1
        palette[key][1], palette[key][2], palette[key][3] = c[1] * shade, c[2] * shade, c[3] * shade
    end
    gctheme.KeepApart(palette, APART, ownPalette, 25)
    for key, tint in pairs(TINTS) do
        local c, base, t = palette[tint[1]], palette.panel, tint[2]
        for i = 1, 3 do palette[key][i] = base[i] + (c[i] - base[i]) * t end
    end
end

local GRID_COLUMNS = 4
local CELL_W, CELL_H, ICON, ROW_ICON = 176, 114, 32, 20 -- room for a name on two lines
local ICONS_PER_FRAME = 8 -- texture uploads allowed per frame
local iconBudget = ICONS_PER_FRAME
local CHILD_BORDERS = ImGuiChildFlags_Borders or ImGuiChildFlags_Border or 1

-- ImGui vectors come back as two numbers or as a table, by Ashita version: the editor's one reader (gceditwidgets)
ctx.W = gFunc.LoadFile('common\\gceditwidgets.lua')(imgui, palette, set_tip) -- the editor's widgets (W.Switch...)
local xy = ctx.W.Vec
ctx.xy = xy

-- Game data: icons, owned gear, worn gear.
---------------------------------------------------------------------------------------------------------------------

local textures, nameIds = {}, {}

-- An item's id by name. Mythic, relic and empyrean weapons keep one name through their stages (Gastraphetes at 75, 99,
-- 119...), each its own id and stats; the resource lookup by name gives the first. So: the copy you own, else the
-- highest level one when every item has been looked through (a 3+ letter picker search), else the lookup's.
local function item_id(name)
    if name == nil then return nil end
    local key = string.lower(name)
    local inv = editorState.inventory
    local own = (inv ~= nil) and (inv.firstByName ~= nil) and inv.firstByName[key] or nil
    if (own ~= nil) and (own.id ~= nil) then return own.id end
    local any = (allItems ~= nil) and allItems.done and allItems.byName[key] or nil
    if (any ~= nil) and (any.id ~= nil) then return any.id end
    local id = nameIds[key]
    if id == nil then
        local r = AshitaCore:GetResourceManager():GetItemByName(name, 0)
        id = (r ~= nil) and r.Id or false
        nameIds[key] = id
    end
    return id or nil
end
ctx.item_id = item_id -- Related's weapon icons
ctx.GRID_COLUMNS, ctx.CELL_W, ctx.CELL_H, ctx.ICON, ctx.ROW_ICON, ctx.iconBudget =
    GRID_COLUMNS, CELL_W, CELL_H, ICON, ROW_ICON, iconBudget
local function icon(id) -- the item's icon as an ImGui texture id, or nil
    if (id == nil) or (id == 0) or (id == 65535) then return nil end
    local t = textures[id]
    if t ~= nil then return t or nil end
    if iconBudget <= 0 then
        return nil
    end -- this frame's quota is spent: next frame
    iconBudget = iconBudget - 1
    ctx.iconBudget = iconBudget
    textures[id] = false
    local item = AshitaCore:GetResourceManager():GetItemById(id)
    local device = d3d8.get_device()
    if (item == nil) or (item.Bitmap == nil) or (device == nil) then return nil end
    local ptr = ffi.new('IDirect3DTexture8*[1]')
    local size = (ashita.interface_version == nil) and item.ImageSize or -1 -- as tHotBar
    if ffi.C.D3DXCreateTextureFromFileInMemoryEx( device, item.Bitmap, size, 0xFFFFFFFF, 0xFFFFFFFF, 1, 0,
        ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED, ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT, 0xFF000000, nil, nil,
        ptr ) ~= ffi.C.S_OK then
        return nil
    end
    local tex = d3d8.gc_safe_release(ffi.cast('IDirect3DTexture8*', ptr[0]))
    textures[id] = { tex = tex, id = tonumber(ffi.cast('uint32_t', tex)) }
    return textures[id]
end

local function draw_icon(id, size)
    local t = icon(id)
    if t ~= nil then
        imgui.Image(t.id, { size, size })
    else
        imgui.Dummy({ size, size })
    end
end

local function slot_mask(slot)
    if (slot == 'Ear1') or (slot == 'Ear2') then return 0x1800 end
    if (slot == 'Ring1') or (slot == 'Ring2') then return 0x6000 end
    return bit.lshift(1, SLOT_BIT[slot])
end

local function fits(g, slot)
    if bit.band(g.slots or 0, slot_mask(slot)) == 0 then return false end
    if editorState.ui.anyJob[1] then return true end
    if (editorState.profile.job ~= nil) and (editorState.profile.job > 0) and (type(g.jobs) == 'number')
        and (g.jobs ~= 0) and (bit.band(bit.rshift(g.jobs, editorState.profile.job), 1) == 0) then
        return false
    end
    if (editorState.profile.level ~= nil) and (editorState.profile.level > 0) and (type(g.level) == 'number')
        and (g.level > editorState.profile.level) then
        return false
    end
    return true
end

-- Where you hold a piece named in a set: 'Wardrobe 3', 'Safe (not equippable from here)', or nil (not owned).
local function where(name)
    if (name == nil) or (editorState.inventory.firstByName == nil) then return nil end
    local g = editorState.inventory.firstByName[string.lower(name)]
    if g == nil then return nil end
    return g.bag, g.equippable
end

local function rescan()
    local timing = profiler.Start()
    editorState.inventory.items, editorState.inventory.firstByName = scan_owned()
    editorState.inventory.copiesByName = {}
    for _, gear in ipairs(editorState.inventory.items) do
        local copies = editorState.inventory.copiesByName[gear.lname] or {}
        copies[#copies + 1] = gear
        editorState.inventory.copiesByName[gear.lname] = copies
    end
    local preserveUndo = editorState.history.revision == editorState.document.revision
    editorState.document.revision = (editorState.document.revision or 0) + 1
    if preserveUndo then editorState.history.revision = editorState.document.revision end
    profiler.Finish('Bag scan', timing)
end

-- == Editor state ==

local GROUPS = editorData.GROUPS
local DEFENSE = editorData.DEFENSE
local CASTING = editorData.CASTING

-- The built-in heading for a set name. Prefixes in any case, as the engine finds sets (FindSet is case-blind).
-- The ability groups a job file wears by name: `for _, kind in ipairs({'Waltz', 'Step'}) do ... ByName(kind)` (DNC's
-- HandleAbility: ['Step'] on every step). Those sets go under JOB ABILITIES, and the set list offers the missing ones.
local kindsOf = { text = nil, set = {} }
local loadingText = nil -- load_model: the file being read, before it is the document's (its sets get headings first)
local function ability_kinds()
    local doc = editorState and editorState.document
    local text = loadingText or ((doc ~= nil) and (doc.model ~= nil) and doc.model.text) or nil
    if kindsOf.text ~= text then
        kindsOf.text, kindsOf.set, kindsOf.list = text, {}, {}
        for var, list, body in string.gmatch(text or '', 'for%s+_%s*,%s*([%w_]+)%s+in%s+ipairs%(%s*(%b{})%s*%)%s+do(.-)end') do
            if string.find(body, 'ByName%(%s*' .. var .. '%s*%)') then
                for _, w in string.gmatch(list, "(['\"])(.-)%1") do
                    if not kindsOf.set[w] then kindsOf.set[w] = true; kindsOf.list[#kindsOf.list + 1] = w end
                end
            end
        end
    end
    return kindsOf.set, kindsOf.list
end
ctx.ability_kinds = ability_kinds
local function builtin_group(n)
    local l = string.lower(n)
    if string.match(l, '^idle') or (l == 'resting') or (l == 'town') then return 'Idle' end
    if DEFENSE[n] then return 'Defense' end
    if string.match(l, '^tp_') then return 'Melee' end
    if string.match(l, '^ws_') then return 'Weapon skills' end
    if string.match(l, '^weapon_') then return 'Weapons' end
    if string.match(l, '_received$') then return 'Received' end
    if string.match(l, '^hoxne') then return 'Hoxne' end
    if string.match(l, '^buffs') then return 'Buffs' end
    if CASTING[n] or string.match(n, ' Magic') or string.match(n, '_Precast$') then return 'Casting' end
    if ability_kinds()[n] then return 'Job abilities' end -- ['Step']: worn on every step (the job file's own list)
    local res = AshitaCore:GetResourceManager()
    -- the name, else its part before the first _: ['Savage Blade_Acc'], ['Insurgency_HighBuff_Dt'] sit with it
    local base = string.match(n, '^([^_]+)_') or n
    local ability = res:GetAbilityByName(n, 0) or res:GetAbilityByName(base, 0)
    if (ability ~= nil) and (ability.Id < 0x200) then return 'Named weapon skills' end -- ids under 0x200: WS
    local spell = (res:GetSpellByName(n, 0) ~= nil) or (res:GetSpellByName(base, 0) ~= nil)
    -- a spell and a pet's move by one name (Impact, Fire IV, Sleepga: SMN pacts; Sheep Song: BST Ready, BLU): the
    -- move on SMN (15) and BST (9), else the spell
    local job = (editorState ~= nil) and (editorState.profile ~= nil) and editorState.profile.job or nil
    if (ability ~= nil) and not (spell and (job ~= 15) and (job ~= 9)) then return 'Job abilities' end
    if spell then return 'Spells (by name)' end
    return 'Other'
end

-- settings.EditorGroups (char.lua): heading order and your own headings (gceditgroups.lua).
local function read_file(path)
    local f = io.open(path, 'rb')
    if f == nil then return nil end
    local t = f:read('*a')
    f:close()
    return t
end

-- char.lua and the shared settings file (gceditsettings.lua): heading prefs, folds, the Settings panel.
local settingsFiles = gFunc.LoadFile('common\\gceditsettings.lua')({
    engine = function() return gearEngine end, setFile = setFile, groups = editorGroups, readFile = read_file,
    state = function() return editorState end,
})
ctx.settingsFiles = settingsFiles -- the job file's own settings are written by Save (gceditsets)
-- The editor's spacing: GoomSwap settings' EditorSpacing (char.lua, else the shared file, else Compact); this
-- session's pick when char.lua couldn't take it (GcEditSpacing).
ctx.spacing = function()
    local v = GcEditSpacing or settingsFiles.Get('EditorSpacing')
    return (v == 'Comfortable') and 'Comfortable' or 'Compact'
end
ctx.words = gFunc.LoadFile('common\\gceditwords.lua')(editorState) -- plain words for set names (the list's hover)
ctx.newjob = gFunc.LoadFile('common\\gceditnewjob.lua')({ imgui = imgui, palette = palette, set_tip = set_tip,
    feedback = feedback }) -- the file menu's New job file
-- the Rules page (gcinclude.Rules), in ctx: this chunk is at Lua's 200-local limit
ctx.rules = gFunc.LoadFile('common\\gceditrules.lua')({ imgui = imgui, palette = palette, set_tip = set_tip,
    editorState = editorState, files = settingsFiles, setFile = setFile, feedback = feedback, ctx = ctx })
local function headings_setting()
    return settingsFiles.HeadingPref('EditorGroups')
end

-- The heading a set sits under, and its built-in one. parent: a set inside a set (Buffs['Haste']) goes where it
-- was moved by its exact name, else under its parent.
local function group_of(n, parent)
    if parent ~= nil then
        local g, builtin = group_of(parent)
        return editorGroups.PlacedBy(headings_setting(), n) or g, builtin
    end
    local builtin = builtin_group(n)
    return editorGroups.Assign(n, builtin, headings_setting()), builtin
end
ctx.group_of = group_of -- the set list's "+ N to add" sorts sets not made yet under their heading

local function by_name(set)
    local g = set.builtin or set.group
    return (g == 'Job abilities') or (g == 'Named weapon skills') or (g == 'Spells (by name)')
end

local BASE = editorData.BASE
local ARMOR = { 'Head', 'Neck', 'Ear1', 'Ear2', 'Body', 'Hands', 'Ring1', 'Ring2', 'Back', 'Waist', 'Legs', 'Feet' }

-- Every set back under its heading, after the headings changed.
local function regroup()
    local model = (editorState.document ~= nil) and editorState.document.model or nil
    if model == nil then return end
    for _, set in ipairs(model.list) do set.group, set.builtin = group_of(set.name, set.parentName) end
    editorState.cache.listKey = nil
end

-- This character's LuAshitacast folder (<Name>_<id>\\), nil before login.
local function char_dir()
    if (gState == nil) or (gState.PlayerName == nil) or (gState.PlayerId == nil) then return nil end
    return string.format('%sconfig\\addons\\luashitacast\\%s_%u\\', AshitaCore:GetInstallPath(), gState.PlayerName,
        gState.PlayerId)
end

-- A heading's sets as the list shows them: file order, A-Z, or your own (EditorSort, EditorOrder).
local function sorted(rows, heading)
    return editorGroups.SortRows(rows, editorGroups.SortMode(settingsFiles.HeadingPref('EditorSort'), heading),
        editorGroups.Get(settingsFiles.HeadingPref('EditorOrder'), heading))
end
-- Every set under a heading (none left out by a filter), in that order: what Move up / down and a drop reorder.
local function heading_rows(heading)
    local rows = {}
    for _, set in ipairs(editorState.document.model.list) do
        if set.group == heading then rows[#rows + 1] = set end
    end
    return sorted(rows, heading)
end

local function job_abbr()
    local id = (editorState.profile ~= nil) and editorState.profile.job or nil
    local name = (id ~= nil) and AshitaCore:GetResourceManager():GetString('jobs.names_abbr', id) or nil
    return (type(name) == 'string') and (string.gsub(name, '%z', '')) or nil
end

-- Heading prefs changed in the editor ({ key = value, false: taken out }): saved where they come from (char.lua, or
-- the shared file), then used at once. changes nil: why says what was refused.
local function save_prefs(changes, why)
    if changes == nil then feedback('Headings: ' .. tostring(why or 'nothing to change') .. '.'); return false end
    local ok, err = settingsFiles.SaveHeadings(changes)
    if not ok then feedback('Headings not saved: ' .. tostring(err) .. '.'); return false end
    regroup()
    feedback((settingsFiles.HeadingSource() == 'shared') and 'Headings saved for every character (goomswap-shared.lua).'
        or 'Headings saved in char.lua (every job on this character).')
    return true
end

local settingsPanel = nil -- gceditsettingsui.lua, made on first use (palette and helpers are defined below)

ctx.headings = {
    builtins = GROUPS, lib = editorGroups, setting = headings_setting, savePrefs = save_prefs, job = job_abbr,
    pref = settingsFiles.HeadingPref, source = settingsFiles.HeadingSource, sorted = sorted, rows = heading_rows,
    order = function() return editorGroups.Order(headings_setting(), GROUPS) end,
    save = function(value, why) return save_prefs((value ~= nil) and { EditorGroups = value } or nil, why) end,
    share = function() -- this character's headings become the shared ones
        local ok, err = settingsFiles.ShareHeadings()
        if not ok then feedback('Headings not shared: ' .. tostring(err) .. '.'); return false end
        regroup()
        feedback('Headings shared: every character without its own uses them (goomswap-shared.lua).')
        return true
    end,
    ownCopy = function() -- the shared headings copied into char.lua
        local ok, err = settingsFiles.OwnHeadings()
        if not ok then feedback('Headings not copied: ' .. tostring(err) .. '.'); return false end
        regroup()
        feedback('Headings are this character\'s own now (char.lua).')
        return true
    end,
}

-- A PNG beside this file (goomy.png, goomy_shiny.png) as an ImGui texture { id }, made once; nil when missing.
local HERE = string.match(
    string.gsub(
        ((debug ~= nil) and (debug.getinfo ~= nil)) and (debug.getinfo(1, 'S').source or '') or '', '^@', ''
    ),
    '^(.*[\\/])'
) or ''
local pngs = {}
local function png(name)
    local t = pngs[name]
    if t ~= nil then return t or nil end
    pngs[name] = false
    local data, device = read_file(HERE .. name), d3d8.get_device()
    if (data == nil) or (device == nil) then return nil end
    local buf = ffi.new('uint8_t[?]', #data)
    ffi.copy(buf, data, #data)
    local ptr = ffi.new('IDirect3DTexture8*[1]')
    local reward = name == 'goomy_shiny.png'
    if ffi.C.D3DXCreateTextureFromFileInMemoryEx( device, buf, #data, reward and 256 or 0xFFFFFFFF,
        reward and 256 or 0xFFFFFFFF, 1, 0, ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED, ffi.C.D3DX_DEFAULT,
        ffi.C.D3DX_DEFAULT, 0, nil, nil, ptr ) ~= ffi.C.S_OK then
        return nil
    end
    local tex = d3d8.gc_safe_release(ffi.cast('IDirect3DTexture8*', ptr[0]))
    pngs[name] = { tex = tex, id = tonumber(ffi.cast('uint32_t', tex)) }
    return pngs[name]
end
local function draw_png(name, w, h, uvMin, uvMax) -- nothing when the file is missing
    local t = png(name)
    if t ~= nil then
        if uvMin then imgui.Image(t.id, { w, h }, uvMin, uvMax)
        else imgui.Image(t.id, { w, h }) end
        return true
    end
    return false
end

local function load_model(document)
    document = document or editorState.document
    local text = read_file(document.sourcePath or document.path) -- a /gcbuild draft is read from <JOB>.proposed.lua
    if text == nil then return nil, 'cannot read ' .. (document.sourcePath or document.path) end
    local model, err = setFile.Parse(text)
    if model == nil then
        -- a Windower GearSwap file (Mote's / Selindrile's init_gear_sets, get_sets): /gcimport makes a draft of it
        if string.find(text, 'function%s+init_gear_sets') or string.find(text, 'function%s+get_sets') then
            err = tostring(err) .. '. It looks like a GearSwap file: /gcimport '
                .. (string.match(document.path or '', '([^\\/]+)$') or '<file>') .. ' makes a GoomSwap draft of it'
        end
        return nil, err
    end
    model.text = text -- the job file's handlers are read from it (scan_job), once, when All sets first needs them
    model.byLower = {}
    loadingText = text -- its ability groups (['Waltz']) go under JOB ABILITIES
    for _, set in ipairs(model.list) do
        set.group, set.builtin = group_of(set.name, set.parentName)
        set.lname = string.lower(set.name)
        model.byLower[set.lname] = set
        local n = 0
        for _ in pairs(set.slots) do
            n = n + 1
        end
        set.count = n
    end
    loadingText = nil
    return model
end

local function has_set(name)
    return editorState.document.model.byLower[string.lower(name)] ~= nil
end

local function current(set, slot) -- Pending or saved slot definition, including its selectors.
    local ed = editorState.document.edits[set.name] and editorState.document.edits[set.name][slot]
    if ed ~= nil then
        if ed.remove then return nil end
        return ed
    end
    local cur = set.slots[slot]
    return (cur ~= nil) and cur.value or nil
end

-- Hovering a set's name (the set list, Related): its gear as icons, 4x4 in the equipment screen's order, then the
-- hover's text. A slot it leaves out, or writes as code, is a dark blank; rows after its last item are left out.
-- Its icon ids are kept per edit.
ctx.set_peek = function(set, text)
    if (set == nil) or (set.code ~= nil) or (set.slots == nil) then
        set_tip(text)
        return
    end
    if set.peekVer ~= editorState.document.revision then
        set.peekVer, set.peekIds, set.peekN = editorState.document.revision, {}, 0
        for i, slot in ipairs(SCREEN) do
            local v = current(set, slot)
            local id = ((v ~= nil) and (v.kind == 'item')) and item_id(v.name) or nil
            set.peekIds[i] = id or false
            if id ~= nil then set.peekN = set.peekN + 1 end
        end
    end
    if set.peekN == 0 then
        set_tip(text)
        return
    end
    imgui.PushStyleColor(ImGuiCol_PopupBg, { 0.055, 0.06, 0.08, 1 })
    imgui.BeginTooltip()
    local dl = ((imgui.GetWindowDrawList ~= nil) and (imgui.GetCursorScreenPos ~= nil) and (imgui.GetColorU32 ~= nil))
        and imgui.GetWindowDrawList() or nil
    local last = 0 -- rows after the last one with an item are left out (a weapon set: one row)
    for i = 1, #SCREEN do
        if set.peekIds[i] then last = i end
    end
    for i = 1, math.ceil(last / 4) * 4 do
        if (i - 1) % 4 ~= 0 then imgui.SameLine(0, 2) end
        if set.peekIds[i] then
            draw_icon(set.peekIds[i], 32)
        else
            local x, y = nil, nil
            if dl ~= nil then x, y = xy(imgui.GetCursorScreenPos()) end
            if (x ~= nil) and (y ~= nil) then
                dl:AddRectFilled({ x, y }, { x + 32, y + 32 }, imgui.GetColorU32({ 0.09, 0.11, 0.14, 1 }))
            end
            imgui.Dummy({ 32, 32 })
        end
    end
    if (text ~= nil) and (text ~= '') then
        imgui.PushTextWrapPos(440)
        imgui.TextUnformatted(tostring(text))
        imgui.PopTextWrapPos()
    end
    imgui.EndTooltip()
    imgui.PopStyleColor()
end

local function owned_for(set, slot)
    if editorState.cache.matchVer ~= editorState.document.revision then
        editorState.cache.matchVer, editorState.cache.matches = editorState.document.revision, {}
    end
    local key = set.name .. '\0' .. slot
    if editorState.cache.matches[key] == nil then
        local value = current(set, slot)
        local copies = value and value.name and editorState.inventory.copiesByName[string.lower(value.name)] or {}
        editorState.cache.matches[key] = augmentInfo.Match(value, copies) or false
    end
    return editorState.cache.matches[key] or nil
end

local function filled(name) -- the file has the set and it puts something on (an empty one is skipped: Ws_Proc -> Proc)
    local set = editorState.document.model.byLower[string.lower(name)]
    if set == nil then return false end
    if (set.code ~= nil) or set.extra then return true end
    for _, slot in ipairs(SCREEN) do
        if current(set, slot) ~= nil then return true end
    end
    return false
end

local function ghost_of(set, slot) -- a slot's commented-out line ({ name, why, ... }), nil once dropped
    local gh = (set.ghosts ~= nil) and set.ghosts[slot] or nil
    local ed = editorState.document.edits[set.name]
    if (ed ~= nil) and (ed[slot] ~= nil) and ed[slot].comment then
        return ed[slot]
    end -- commented out here: { name, why }
    if (gh ~= nil) and (ed ~= nil) and (ed[slot] ~= nil) and ed[slot].remove then return nil end
    return gh
end

local function edit(set, slot, v) -- v: an owned piece { name, augs, path } or nil to clear the slot
    editorState.history.entries = editorState.history.entries or {}
    editorState.history.entries[#editorState.history.entries + 1] = {
        set = set.name,
        slot = slot,
        previous = editorState.document.edits[set.name] and editorState.document.edits[set.name][slot],
    }
    if #editorState.history.entries > 100 then table.remove(editorState.history.entries, 1) end
    editorState.document.revision = editorState.document.revision + 1 -- the To fill tab follows the edits
    editorState.document.edits[set.name] = editorState.document.edits[set.name] or {}
    local orig = set.slots[slot]
    if v == nil then
        local gh = (set.ghosts ~= nil) and set.ghosts[slot] or nil -- commented out: Save deletes that line
        editorState.document.edits[set.name][slot] = ((orig ~= nil) or (gh ~= nil)) and { remove = true } or nil
    else
        local text = setFile.FormatItem(v.name, v.augs, v.path)
        if (orig ~= nil) and (orig.value.raw == text) then
            editorState.document.edits[set.name][slot] = nil
        else
            local augs = ((v.path == nil) and (type(v.augs) == 'table') and (#v.augs > 0))
                    and table.concat(v.augs, ', ') or nil
            editorState.document.edits[set.name][slot] =
                { kind = 'item', name = v.name, path = v.path, augs = augs, text = text }
        end
    end
    if next(editorState.document.edits[set.name]) == nil then editorState.document.edits[set.name] = nil end
    editorState.history.revision = editorState.document.revision
end

local function dirty_count()
    local n = #editorState.document.newSets + #editorState.document.newModes
        + ((editorState.document.wmOrder ~= nil) and 1 or 0) + ((editorState.document.convert ~= nil) and 1 or 0)
        + (editorState.document.dropNotes and 1 or 0)
    for _ in pairs(editorState.document.jobSettings or {}) do
        n = n + 1
    end
    for _ in pairs(editorState.document.deleted or {}) do
        n = n + 1
    end
    for _ in pairs(editorState.document.renames or {}) do
        n = n + 1
    end
    for _, e in pairs(editorState.document.edits) do
        for _ in pairs(e) do
            n = n + 1
        end
    end
    return n
end

local function unsaved_set_count()
    local cache, document = editorState.cache, editorState.document
    if cache.unsavedRevision ~= document.revision then
        local count = 0
        for _, set in ipairs(document.model.list) do
            if set.new or document.edits[set.name] or document.deleted[set.name] or (document.renames
                or {})[set.name] then
                count = count + 1
            end
        end
        cache.unsavedRevision, cache.unsavedSets = document.revision, count
    end
    return cache.unsavedSets
end

local function show_unsaved_sets()
    local ui = editorState.ui
    ui.editedOnly[1], ui.issuesOnly[1], ui.missingOnly[1], ui.needsRpOnly[1] = true, false, false, false
    ui.find[1] = ''
end

-- Preview and Save use the same registration planner. Nothing changes in the
-- running weapon cycle until the job is saved and reloaded.
local function registration_plan()
    local cached = editorState.cache.weaponPlan
    if not cached or cached.revision ~= editorState.document.revision then
        local ok, modes = setFile.AddWeaponModes(editorState.document.model.text, editorState.document.newSets, {},
            editorState.document.newModes)
        cached = { revision = editorState.document.revision, ok = ok, modes = modes or {} }
        editorState.cache.weaponPlan = cached
    end
    return cached
end

local function pending_weapon_mode(set)
    if set.new and (set.parentName == nil) and string.sub(set.name, 1, 7) == 'Weapon_' then
        for _, mode in ipairs(registration_plan().modes) do
            if set.name == 'Weapon_' .. mode then return mode end
        end
    end
end

-- Deleting a /wm mode (wm.*: one local for them all, the main chunk is at Lua's 200-local limit).
local wm = {}
-- A Weapon_ set deleted: Save takes its /wm mode out of gcinclude.WeaponModes. For modes: remove, the list's
-- entries naming them (as written); flags, { list, text } where DefaultWeapons / WeaponRoles still name one (as
-- staged in Settings, else as the file has them): those are left for you.
function wm.report(modes)
    local doc, out, want = editorState.document, { modes = modes, remove = {}, flags = {} }, {}
    if #modes == 0 then return out end
    for _, m in ipairs(modes) do want[string.lower(m)] = true end
    local staged = doc.jobSettings or {}
    for _, m in ipairs(setFile.ModeMentions(doc.model.text or '', modes)) do
        if m.list == 'WeaponModes' then
            out.remove[#out.remove + 1] = m.text
        elseif staged[m.list] == nil then
            out.flags[#out.flags + 1] = m
        end
    end
    for _, list in ipairs({ 'DefaultWeapons', 'WeaponRoles' }) do
        local e = staged[list]
        local function scan(v)
            if type(v) == 'string' then
                if want[string.lower(v)] then out.flags[#out.flags + 1] = { list = list, text = v } end
            elseif type(v) == 'table' then
                for _, x in pairs(v) do scan(x) end
            end
        end
        if (e ~= nil) and not e.remove then scan(e.value) end
    end
    return out
end
-- The sets worn only with weapon mode `mode` (Tp_<mode>, Ws_<mode>_Acc, Savage Blade_<mode>, Idle_<mode>,
-- Weapon_<mode>_1h, Weapon_<mode>Acc...), not already deleted: free, nothing else looks for them once the mode is gone; coded, your
-- job file names them (sets.X, ByName...), so they are kept.
function wm.sets(mode)
    local doc, lm, free, coded = editorState.document, string.lower(mode), {}, {}
    local msets, listed = setFile.MeleeModes(doc.model.text, doc.newModes), {}
    for _, m in ipairs(setFile.WeaponModes(doc.model.text or '') or {}) do listed[string.lower(m)] = true end
    for _, s in ipairs(doc.model.list or {}) do
        if (s.parentName == nil) and not doc.deleted[s.name] and (s.lname ~= 'weapon_' .. lm) then
            local rest, own = string.match(s.lname, '^weapon_(.+)$'), false
            if rest ~= nil then -- a weapon set: this mode's own (Weapon_Mpu_1h, Weapon_MpuAcc), not a listed mode
                own = (not listed[rest]) and setFile.WeaponVariantOf(s.name, mode, msets)
            else
                local w = (ctx.actions ~= nil) and ctx.actions.WeaponModeOf(s) or nil
                own = (w ~= nil) and (string.lower(w) == lm)
            end
            if own then
                local refs = (not s.new) and setFile.RenameCount(doc.model.text, doc.model, s.name, s.name) or 0
                if (refs or 0) > 0 then coded[#coded + 1] = s else free[#free + 1] = s end
            end
        end
    end
    return free, coded
end
function wm.names(sets)
    local out = {}
    for _, s in ipairs(sets) do out[#out + 1] = s.name end
    return table.concat(out, ', ')
end

-- The modes of every Weapon_ set staged for deletion (a set inside a set is not a mode).
function wm.removal()
    local doc, cached = editorState.document, editorState.cache.wmRemoval
    if (cached == nil) or (cached.doc ~= doc) or (cached.revision ~= doc.revision) then
        local modes = {}
        for name in pairs(doc.deleted or {}) do
            local set = doc.model.byName[name]
            local mode = (set ~= nil) and (set.parentName == nil) and string.match(name, '^Weapon_(.+)$') or nil
            if mode ~= nil then modes[#modes + 1] = mode end
        end
        table.sort(modes)
        cached = wm.report(modes)
        cached.doc, cached.revision, cached.left = doc, doc.revision, {}
        for _, m in ipairs(cached.remove) do -- what stays of each mode: deleting is up to you (the delete box)
            local free, coded = wm.sets(m)
            for _, s in ipairs(coded) do free[#free + 1] = s end
            if #free > 0 then cached.left[#cached.left + 1] = { mode = m, sets = free } end
        end
        editorState.cache.wmRemoval = cached
    end
    return cached
end
ctx.wm_removal = wm.removal

-- Lines for what a Weapon_ deletion does to the /wm cycle (the delete box, the Save review).
function wm.draw(r)
    for _, m in ipairs(r.remove) do
        imgui.TextColored(palette.blue, '/wm ' .. m .. ' comes out of the weapon cycle (gcinclude.WeaponModes).')
    end
    for _, f in ipairs(r.flags) do
        imgui.TextColored(palette.warn, 'gcinclude.' .. f.list .. ' still names ' .. f.text
            .. ': change it in GoomSwap settings (' .. tostring(editorState.document.file) .. ').')
    end
end

-- What DefaultWeapons / WeaponRoles name that nothing offers: the engine skips those at load without a word
-- (gcruntime SetCycleFrom finds a value by its name, start or part). Each a sentence; worked out once per edit.
local PICK_LIST = { Main = 'MainModes', Sub = 'SubModes', Range = 'RangeModes', Ammo = 'AmmoModes' }
local PICK_CMD = { Main = '/mw', Sub = '/subw', Range = '/rw', Ammo = '/ammoset' }
ctx.weapon_problems = function()
    local doc = editorState.document
    local memo = editorState.cache.weaponProblems
    if (memo ~= nil) and (memo.doc == doc) and (memo.rev == doc.revision) then return memo.list end
    local S, out = settingsFiles, {}
    local function offered(list, v) -- list (lowercase names) has v by its name or a part of one
        local lv = string.lower(v)
        for n in pairs(list) do
            if string.find(n, lv, 1, true) then return true end
        end
        return false
    end
    local labels = (type(S.Job('WeaponItemMap')) == 'table') and S.Job('WeaponItemMap') or {}
    local picks = {} -- what each slot's /mw /subw /rw /ammoset can pick: its list, any Weapon_ set's item there
    for slot, list in pairs(PICK_LIST) do
        picks[slot] = {}
        for _, v in ipairs((type(S.Job(list)) == 'table') and S.Job(list) or {}) do
            if type(v) == 'string' then picks[slot][string.lower(v)] = true end
        end
        for label in pairs(labels) do picks[slot][string.lower(tostring(label))] = true end
    end
    local modes = {}
    for _, m in ipairs(setFile.WeaponModes(doc.model.text or '') or {}) do modes[string.lower(m)] = true end
    for _, m in ipairs(registration_plan().modes) do modes[string.lower(m)] = true end
    for _, s in ipairs(doc.model.list) do
        if (s.parentName == nil) and string.match(s.lname, '^weapon_') and not doc.deleted[s.name] then
            for slot in pairs(PICK_LIST) do
                local v = current(s, slot)
                if (v ~= nil) and (v.name ~= nil) then picks[slot][string.lower(v.name)] = true end
            end
        end
    end
    local function mode(where, v)
        if (type(v) == 'string') and not offered(modes, v) and (string.lower(v) ~= 'none') then
            out[#out + 1] = where .. " '" .. v .. "': no /wm mode by that name (gcinclude.WeaponModes, Weapon_ sets). "
                .. 'Skipped at load.'
        end
    end
    local dw = S.Job('DefaultWeapons')
    if type(dw) == 'string' then
        mode('DefaultWeapons', dw)
    elseif type(dw) == 'table' then
        for k, v in pairs(dw) do
            if k == 'Weapons' then
                mode('DefaultWeapons Weapons', v)
            elseif (PICK_LIST[k] ~= nil) and (type(v) == 'string') and (string.lower(v) ~= 'none')
                and not offered(picks[k], v) then
                out[#out + 1] = 'DefaultWeapons ' .. k .. " '" .. v .. "': not in " .. PICK_LIST[k] .. ', nor any Weapon_ '
                    .. "set's " .. k .. '. Skipped at load.'
            end
        end
    end
    local roles = S.Job('WeaponRoles')
    for k, v in pairs((type(roles) == 'table') and roles or {}) do mode('WeaponRoles ' .. tostring(k), v) end
    table.sort(out)
    editorState.cache.weaponProblems = { doc = doc, rev = doc.revision, list = out }
    return out
end
settingsFiles.WeaponProblems = ctx.weapon_problems -- the Settings window shows them too
-- The /mw /subw /rw /ammoset picks the job file lists (not None): { 'Main picks (/mw): Burtgang, Naegling', ... }.
ctx.weapon_picks = function()
    local out = {}
    for _, slot in ipairs({ 'Main', 'Sub', 'Range', 'Ammo' }) do
        local names = {}
        local list = settingsFiles.Job(PICK_LIST[slot])
        for _, v in ipairs((type(list) == 'table') and list or {}) do
            if (type(v) == 'string') and (string.lower(v) ~= 'none') then names[#names + 1] = v end
        end
        if #names > 0 then
            out[#out + 1] = slot .. ' picks (' .. PICK_CMD[slot] .. '): ' .. table.concat(names, ', ')
        end
    end
    return out
end
local function undo_slot(set, slot)
    local edits = editorState.document.edits[set.name]
    if not edits or not edits[slot] then return end
    edits[slot] = nil
    if not next(edits) then editorState.document.edits[set.name] = nil end
    editorState.document.revision = editorState.document.revision + 1
    feedback('Restored ' .. set.name .. ' / ' .. slot .. ' to the file definition.')
end

local function choose_item(set, slot, gear)
    local fill = editorState.ui.fillAll
    if fill and fill.slot == slot and fill.sets[set.name] then
        local count = 0
        for name in pairs(fill.sets) do
            local target = editorState.document.model.byName[name]
            if target and target.code == nil then edit(target, slot, gear); count = count + 1 end
        end
        editorState.ui.fillAll = nil
        feedback('Selected ' .. gear.name .. ' for ' .. count .. ' sets (unsaved).')
    else
        edit(set, slot, gear)
        feedback('Selected ' .. gear.name .. ' for ' .. set.name .. ' / ' .. slot .. ' (unsaved).')
    end
    if editorState.ui.fromFill then -- picked from To fill's list: back to it, for the next one
        editorState.ui.fromFill, editorState.selection.tab = nil, 'fill'
    end
end

local ENGINE = editorData.ENGINE
local ENGINE_SET = {}
for _, name in ipairs(ENGINE) do
    ENGINE_SET[string.lower(name)] = true
end

local function bind_actions()
    local resources = AshitaCore:GetResourceManager()
    local live = not editorState.document.inactive
    -- another job's file
    local previewEngine = live and gearEngine or { settings = {}, sets = {}, Family = gearEngine.Family,
        TwoHandSkills = gearEngine.TwoHandSkills, OneHandSkills = gearEngine.OneHandSkills } -- not the live weapon
    actions = actionModel.New({
        document = editorState.document,
        inventory = editorState.inventory,
        slots = SCREEN,
        slotBits = SLOT_BIT,
        slotNames = NUM_SLOT,
        job = editorState.profile.job,
        engine = previewEngine, current = current, hasSet = has_set, filled = filled, isWeaponskill = function(name)
            local ability = resources:GetAbilityByName(name, 0)
            return ability ~= nil and ability.Id < 0x200
        end,
        itemId = item_id, setFile = setFile,
        readFile = read_file, abilityKinds = ability_kinds, resources = resources, display = live and gcdisplay or nil,
        getRecords = function()
            return live and GcRecords or nil
        end, getPlayer = function()
            if live then return AshitaCore:GetMemoryManager():GetPlayer() end
        end,
        analysis = jobAnalysis.New({
            engine = previewEngine, buffName = function(id)
                return resources:GetString('buffs.names', id)
            end,
        }),
    })
    ctx.actions = actions
end

local m_gceditsets = gFunc.LoadFile('common\\gceditsets.lua')(
    ARMOR, BASE, ENGINE, SCREEN, augments_of, ctx, current, edit, editorPreferences, editorState, feedback,
    fileWriter, gcedit, group_of, imgui, palette, pending_weapon_mode, read_file, setFile,
    set_tip, xy
)
local suggestions, make_set, copy_from, draw_copy_popup, drop_new, empty_armor, use_worn, save, ago, red_button, tag,
    canDraw, text_w, pill, make_button, left_bar, wrap, help_icon, help = m_gceditsets.suggestions,
    m_gceditsets.make_set, m_gceditsets.copy_from, m_gceditsets.draw_copy_popup, m_gceditsets.drop_new,
    m_gceditsets.empty_armor, m_gceditsets.use_worn, m_gceditsets.save, m_gceditsets.ago, m_gceditsets.red_button,
    m_gceditsets.tag, m_gceditsets.canDraw, m_gceditsets.text_w, m_gceditsets.pill, m_gceditsets.make_button,
    m_gceditsets.left_bar, m_gceditsets.wrap, m_gceditsets.help_icon, m_gceditsets.help
ctx.use_worn = use_worn -- New /wm mode starts from the weapons you hold
local m_gceditlist = gFunc.LoadFile('common\\gceditlist.lua')(
    BASE, CHILD_BORDERS, GROUPS, SCREEN, SLOT_BIT, current, editorData, editorPanels, editorPreferences,
    editorState, empty_armor, help, imgui, left_bar, make_set, owned_for, palette, pill, profiler, request_context,
    set_tip, suggestions, tag, text_w, unsaved_set_count, where, ctx
)
local go_to, NONE, LAC_WORDS, is_slot_word, clip_begin, clip_skip, clip_drawn, clip_end, set_status, rp_uses, draw_sets,
    descs, SJIS, ELEM_ICON = m_gceditlist.go_to, m_gceditlist.NONE, m_gceditlist.LAC_WORDS, m_gceditlist.is_slot_word,
    m_gceditlist.clip_begin, m_gceditlist.clip_skip, m_gceditlist.clip_drawn, m_gceditlist.clip_end,
    m_gceditlist.set_status, m_gceditlist.rp_uses, m_gceditlist.draw_sets, m_gceditlist.descs, m_gceditlist.SJIS,
    m_gceditlist.ELEM_ICON
local m_gceditinspect = gFunc.LoadFile('common\\gceditinspect.lua')(
    BASE, CHILD_BORDERS, ELEM_ICON, NONE, SCREEN, SJIS, ago, augmentInfo, by_name, cardText, ctx, current,
    descs, draw_icon, drop_new, edit, editorInspect, editorPanels, editorPreferences, editorState, empty_armor,
    feedback, ghost_of, go_to, help, imgui, is_slot_word, itemTooltip, item_id, make_set, owned_for, palette,
    pending_weapon_mode, pill, profiler, red_button, registration_plan, request_context, rp_uses,
    set_status, set_tip, statModel, tag, text_w, use_worn, where, wrap, xy
)
local describe, cmp_of, inspection_target, inspect_item, set_stats, ignored_suggestion_names, draw_layers,
    set_action_entries, draw_set, wi_from_game, melee_modes, conds_on = m_gceditinspect.describe,
    m_gceditinspect.cmp_of, m_gceditinspect.inspection_target, m_gceditinspect.inspect_item, m_gceditinspect.set_stats,
    m_gceditinspect.ignored_suggestion_names, m_gceditinspect.draw_layers, m_gceditinspect.set_action_entries,
    m_gceditinspect.draw_set, m_gceditinspect.wi_from_game, m_gceditinspect.melee_modes, m_gceditinspect.conds_on
ctx.melee_modes = melee_modes -- the list's MELEE heading names them
ctx.ignored_names = ignored_suggestion_names -- the add list leaves these out
-- The add list's x: the name joins EditorIgnoreSuggestions in char.lua (every job on this character).
ctx.ignore_suggestion = function(name)
    local cur, list = settingsFiles.Get('EditorIgnoreSuggestions'), {}
    for k, v in pairs((type(cur) == 'table') and cur or {}) do
        local n = (type(k) == 'number') and v or ((v == true) and k or nil)
        if type(n) == 'string' then list[#list + 1] = n end
    end
    list[#list + 1] = name
    local ok, err = settingsFiles.Write('own', { EditorIgnoreSuggestions = list })
    if not ok then feedback('Not hidden: ' .. tostring(err) .. '.'); return end
    editorState.cache.addable = nil
    feedback(name .. ' hidden from the add list (GoomSwap settings, Hidden set suggestions, takes it back).')
end
local m_gceditrelated = gFunc.LoadFile('common\\gceditrelated.lua')(
    LAC_WORDS, NONE, SCREEN, allItems, canDraw, cardText, choose_item, clip_begin, clip_drawn, clip_end, clip_skip,
    conds_on, ctx, current, describe, draw_icon, draw_png, edit, editorPanels, editorPreferences,
    editorState, feedback, fits, ghost_of, go_to, group_of, has_set, help, help_icon, ignored_suggestion_names,
    imgui, index_all_items, inspect_item, inspection_target, itemTooltip, make_button, make_set, melee_modes,
    owned_for, palette, picker, pill, profiler, red_button, request_context, saveReview, setFile,
    set_action_entries, set_tip, tag, text_w, undo_slot, where, wi_from_game, wrap, xy, m_gceditsets.known_ws
)
local draw_over, draw_picker, fill_list, draw_fill, draw_context_menu, variants_of, rename_problem,
    rename_new = m_gceditrelated.draw_over, m_gceditrelated.draw_picker, m_gceditrelated.fill_list,
    m_gceditrelated.draw_fill, m_gceditrelated.draw_context_menu, m_gceditrelated.variants_of,
    m_gceditrelated.rename_problem, m_gceditrelated.rename_new
ctx.stage_rename = function(old, new)
    local doc = editorState.document
    local set = doc.model.byName[old]
    if (set ~= nil) and set.new then
        if new ~= nil then rename_new(set, new) end
        return
    end
    doc.renames, doc.renameRefs = doc.renames or {}, doc.renameRefs or {}
    doc.renames[old], doc.renameRefs[old] = new, new and setFile.RenameCount(doc.model.text, doc.model, old, new) or nil
    doc.revision = doc.revision + 1
end

local function draw_rename()
    local ui = editorState.ui
    if ui.requestRenameSet then
        ui.renameSet, ui.requestRenameSet = ui.requestRenameSet, nil
        local s = editorState.document.model.byName[ui.renameSet or '']
        ui.renameName, ui.renameVariants = { (s ~= nil) and s.key or ui.renameSet }, { true }
        imgui.OpenPopup('##gcedit_rename')
    end
    if not imgui.BeginPopup('##gcedit_rename') then return end
    local set = editorState.document.model.byName[ui.renameSet or '']
    if set ~= nil then
        local child = set.parentName ~= nil -- a set inside a set: only its key changes
        imgui.TextUnformatted('Rename ' .. set.name .. (child and (' (its name in ' .. set.parentName .. ')') or ''))
        imgui.PushItemWidth(340)
        imgui.InputText('##gcedit_rename_name', ui.renameName, 64)
        imgui.PopItemWidth()
        local new = string.match(ui.renameName[1] or '', '^%s*(.-)%s*$')
        if child then new = (new == '') and '' or setFile.ChildName(set.parentName, new) end
        local variants = child and {} or variants_of(set.name)
        if #variants > 0 then
            imgui.Checkbox('Also rename ' .. #variants .. ' variant' .. (#variants == 1 and '' or 's') .. ' ('
                .. variants[1] .. ' -> ' .. new .. string.sub(variants[1], #set.name + 1) .. ')##gcedit_rename_v',
                    ui.renameVariants)
        end
        local plan = { [set.name] = new }
        if (#variants > 0) and ui.renameVariants[1] then
            for _, v in ipairs(variants) do plan[v] = new .. string.sub(v, #set.name + 1) end
        end
        local problem = nil
        for old, to in pairs(plan) do problem = problem or rename_problem(old, to) end
        imgui.PushTextWrapPos(440)
        if problem then
            imgui.TextColored(palette.bad, problem)
        else
            local refs = setFile.RenameCount(editorState.document.model.text, editorState.document.model,
                set.name, new) or 0
            imgui.TextColored(palette.dim, refs .. ' reference' .. (refs == 1 and '' or 's') .. ' in code ('
                .. (child and ('sets.' .. set.parentName .. "['" .. set.key .. "']")
                    or 'sets.X, ByName, EquipSet, weapon mode lists') .. ') renamed too. Comments are left alone.')
        end
        if (not child) and (by_name(set) or (ENGINE_SET[string.lower(set.name)] ~= nil)) then
            imgui.TextColored(palette.warn,
                'GoomSwap finds ' .. set.name .. ' by its name: renamed, it is only worn where your code names it.')
        end
        imgui.PopTextWrapPos()
        local from = set.name
        if imgui.Button((set.new and 'Rename' or 'Rename on Save') .. '##gcedit_rename') and not problem then
            for old, to in pairs(plan) do ctx.stage_rename(old, to) end
            feedback((set.new and 'Renamed: ' or 'Rename staged: ') .. from .. ' -> ' .. new .. ' (unsaved).')
            imgui.CloseCurrentPopup()
        end
        imgui.SameLine()
        if imgui.Button('Cancel##gcedit_rename_cancel') then imgui.CloseCurrentPopup() end
    end
    imgui.EndPopup()
end

local function draw_delete_confirmation()
    if editorState.ui.requestDeleteSet then
        editorState.ui.deleteSet, editorState.ui.deleteReport = editorState.ui.requestDeleteSet, nil
        editorState.ui.requestDeleteSet = nil
        imgui.OpenPopup('##gcedit_delete_set')
    end
    if not imgui.BeginPopup('##gcedit_delete_set') then return end
    local set = editorState.document.model.byName[editorState.ui.deleteSet]
    if set then
        local doc = editorState.document
        local children = {} -- the sets inside it (Buffs['X']) go with it
        for _, s in ipairs(doc.model.list) do
            if s.parentName == set.name then children[#children + 1] = s end
        end
        imgui.TextColored(palette.bad, 'Delete ' .. set.name .. ((#children > 0) and (' and its ' .. #children
            .. ' set' .. ((#children == 1) and '' or 's')) or '') .. ' from the job file?')
        imgui.PushTextWrapPos(440)
        imgui.TextUnformatted('References elsewhere remain. The definition is removed on Save, with a backup.')
        local mode = (set.parentName == nil) and string.match(set.name, '^Weapon_(.+)$') or nil
        if (mode ~= nil) and (editorState.ui.deleteReport == nil) then -- read once while the box is open
            local r = wm.report({ mode })
            r.free, r.coded = {}, {}
            if #r.remove > 0 then r.free, r.coded = wm.sets(mode) end -- a /wm mode: its own sets go with it
            editorState.ui.deleteReport, editorState.ui.deleteSets = r, { true }
        end
        local r = (mode ~= nil) and editorState.ui.deleteReport or nil
        if r ~= nil then
            wm.draw(r)
            if #r.free > 0 then
                imgui.Checkbox('Also delete the ' .. #r.free .. ' set' .. ((#r.free == 1) and '' or 's')
                    .. ' worn only with /wm ' .. mode .. ':##gcedit_delsets', editorState.ui.deleteSets)
                imgui.TextColored(editorState.ui.deleteSets[1] and palette.bad or palette.warn, wm.names(r.free))
            end
            if #r.coded > 0 then
                imgui.TextColored(palette.warn, 'Kept, your job file names them: ' .. wm.names(r.coded) .. '.')
            end
        end
        imgui.PopTextWrapPos()
        if red_button('Confirm deletion##gcedit') then
            local extra = 0
            if (r ~= nil) and editorState.ui.deleteSets[1] then -- the mode's own sets, ticked (the default)
                for _, s in ipairs(r.free) do
                    if s.new then
                        drop_new(s)
                    else
                        doc.deleted[s.name], doc.edits[s.name] = true, nil
                    end
                    extra = extra + 1
                end
            end
            for _, s in ipairs(children) do
                if s.new then
                    drop_new(s)
                else
                    doc.edits[s.name], doc.deleted[s.name] = nil, nil
                    if doc.renames ~= nil then doc.renames[s.name] = nil end
                    if doc.renameRefs ~= nil then doc.renameRefs[s.name] = nil end
                end
            end
            editorState.document.deleted[set.name] = true
            editorState.document.edits[set.name] = nil
            editorState.document.revision = editorState.document.revision + 1
            feedback('Deletion staged for ' .. set.name .. ((extra > 0) and (' and ' .. extra .. ' set'
                .. ((extra == 1) and '' or 's') .. ' worn only with it') or '') .. ' (unsaved).')
            imgui.CloseCurrentPopup()
        end
        imgui.SameLine()
        if imgui.Button('Cancel##gcedit_delete') then imgui.CloseCurrentPopup() end
    end
    imgui.EndPopup()
end

local function draw_save_review()
    if not imgui.BeginPopup('##save_preview') then return end
    local plan = registration_plan()
    local cached = editorState.cache.saveReview
    if not cached or cached.revision ~= editorState.document.revision then
        cached = { revision = editorState.document.revision,
            model = saveReview.Build(editorState.document, SCREEN, plan.modes, plan.ok) }
        editorState.cache.saveReview = cached
    end
    imgui.TextUnformatted('Review changes')
    if not editorState.document.inactive then
        editorState.ui.reopen = editorState.ui.reopen or { true }
        imgui.Checkbox('Reopen editor after saving', editorState.ui.reopen)
    else
        imgui.TextColored(palette.blue, 'Save ' .. editorState.document.file .. '; keep the active job loaded.')
    end
    local display = imgui.GetIO().DisplaySize
    local width, height = display and (display.x or display[1]) or 1024, display and (display.y or display[2]) or 768
    imgui.BeginChild('##save_changes', { math.max(260, math.min(760, width - 80)),
        math.max(120, math.min(360, height - 240)) }, CHILD_BORDERS)
    if saveReview.Draw(imgui, palette, cached.model) == 'drop empty' then -- the new sets with no gear: left out
        for _, name in ipairs(cached.model.empty) do
            local set = editorState.document.model.byName[name]
            if (set ~= nil) and set.new then drop_new(set) end
        end
        local n = #cached.model.empty
        feedback('Left out ' .. n .. ' empty new set' .. ((n == 1) and '' or 's') .. '.')
    end
    local gone = wm.removal()
    if (#gone.remove > 0) or (#gone.flags > 0) then
        imgui.TextColored(palette.blue, 'Weapon cycle removals on Save')
        imgui.PushTextWrapPos(0)
        wm.draw(gone)
        for _, l in ipairs(gone.left) do
            imgui.TextColored(palette.warn, 'Kept, worn only with /wm ' .. l.mode .. ': ' .. wm.names(l.sets) .. '.')
        end
        imgui.PopTextWrapPos()
    end
    local staged = editorState.document.jobSettings or {}
    if next(staged) ~= nil then -- Settings: This job
        imgui.TextColored(palette.blue, 'Job file settings')
        local names = {}
        for name in pairs(staged) do names[#names + 1] = name end
        table.sort(names)
        for _, name in ipairs(names) do
            local e = staged[name]
            if (name == 'Rules') and (not e.remove) and (ctx.rules ~= nil) then -- a rule a line, in words
                imgui.TextUnformatted('  gcinclude.Rules: ' .. #e.value .. ((#e.value == 1) and ' rule' or ' rules'))
                for i, rule in ipairs(e.value) do
                    imgui.TextColored(palette.dim, '    ' .. i .. '. ' .. tostring(rule.on) .. ': '
                        .. ctx.rules.R.Say(rule) .. ((rule.layer == 'top') and ' (over everything)' or '')
                        .. (rule.off and ' (off)' or ''))
                end
            else
            imgui.TextUnformatted('  ' .. (string.match(name, '^profile%.') and '' or 'gcinclude.') .. name
                .. (e.remove and ': taken out'
                or (' = ' .. string.gsub(settingsFiles.JobText(e, ''), '%s*\n%s*', ' '))))
            end
        end
    end
    local conv = editorState.document.convert
    if conv ~= nil then -- Rules page: Convert / Adopt, taken out of (or put into) the handlers' code
        imgui.TextColored(palette.blue, conv.title or 'Code made into rules')
        for _, l in ipairs(conv.lines or {}) do imgui.TextColored(palette.dim, '  ' .. l) end
    end
    if editorState.document.sourcePath then
        imgui.TextWrapped('This draft replaces the job file. The previous file is backed up.')
    end
    imgui.EndChild()
    imgui.TextColored(palette.dim, 'A dated backup is written before the job file is replaced.')
    local keep = fileWriter.Backups.Keep((gearEngine.settings or {}).EditorBackupKeep)
    imgui.TextColored(palette.dim, keep == 0 and 'Backup cleanup off: keep all editor backups.'
        or ('Keep newest ' .. keep .. ' editor backups for this file.'))
    help('EditorBackupKeep in char.lua settings controls retention (default 3; 0 keeps all).\n'
        .. 'Only this job file\'s dated .gcedit.bak files are pruned, after a successful save.\n'
        .. 'The backup just created is always kept. Host/addset backups are untouched.')
    if imgui.Button(editorState.document.inactive and 'Confirm save file' or 'Confirm save + reload')
        and not editorState.ui.saving then
        imgui.CloseCurrentPopup()
        save()
    end
    imgui.SameLine()
    if imgui.Button('Keep editing') then imgui.CloseCurrentPopup() end
    imgui.EndPopup()
end

local function exists_path(path)
    if ashita.fs and ashita.fs.exists then return ashita.fs.exists(path) end
    return read_file(path) ~= nil
end

-- This character's job files (SwitchFile opens only these), and the ones other than the file being edited.
local function job_files()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    editorState.ui.jobFiles = fileWriter.JobFiles(editorState.document.characterFolder,
        gProfile and gProfile.FilePath, player:GetMainJob(), exists_path)
    local others = {}
    for _, f in ipairs(editorState.ui.jobFiles) do
        if fileWriter.FileKey(f.path) ~= fileWriter.FileKey(editorState.document.path) then others[#others + 1] = f end
    end
    return editorState.ui.jobFiles, others
end

-- Unused gear (top bar): the gear in your equip bags (Inventory, Wardrobes: gSettings.EquipBags) that nothing of
-- this character names: no job file, char.lua, the shared settings file, GoomSwap's own sets or its code
-- (gcinclude, gcruntime: Moonshade, obis, Warp Ring). A piece is named when its name is a string in one of them
-- ('Name', "Name", 'Chasseur\'s'), so code naming it counts, as do unsaved edits. Read only: moves nothing.
ctx.cleanup_scan = function(C)
    local texts, files = {}, job_files()
    for _, f in ipairs(files) do
        local t = (fileWriter.FileKey(f.path) == fileWriter.FileKey(editorState.document.path))
            and editorState.document.model.text or read_file(f.path)
        if type(t) == 'string' then texts[#texts + 1] = t end
    end
    local base = AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\'
    for _, path in ipairs({ (char_dir() or base) .. 'char.lua', base .. 'goomswap-shared.lua',
        base .. 'common\\gcinclude.lua', base .. 'common\\gcruntime.lua' }) do
        local t = read_file(path)
        if type(t) == 'string' then texts[#texts + 1] = t end
    end
    -- every string in them, once (an escaped quote kept), then a plain search for what that missed
    local blob = string.lower(table.concat(texts, '\n'))
    local named, esc = {}, string.gsub(string.gsub(blob, "\\'", '\1'), '\\"', '\2')
    for q in string.gmatch(esc, "'([^'\n]*)'") do named[(string.gsub(q, '\1', "'"))] = true end
    for q in string.gmatch(esc, '"([^"\n]*)"') do named[(string.gsub(q, '\2', '"'))] = true end
    for _, e in pairs(editorState.document.edits) do
        for _, v in pairs(e) do
            if type(v.name) == 'string' then named[string.lower(v.name)] = true end
        end
    end
    for _, set in pairs((ctx.gearEngine ~= nil) and ctx.gearEngine.sets or {}) do
        for _, v in pairs((type(set) == 'table') and set or {}) do
            local n = (type(v) == 'table') and v.Name or v
            if type(n) == 'string' then named[string.lower(n)] = true end
        end
    end
    local function is_named(l)
        if named[l] == nil then
            named[l] = (string.find(blob, "'" .. string.gsub(l, "'", "\\'") .. "'", 1, true) ~= nil)
                or (string.find(blob, '"' .. l .. '"', 1, true) ~= nil)
        end
        return named[l]
    end
    local rows, byKey = {}, {}
    C.perBag = {}
    for _, g in ipairs(editorState.inventory.items or {}) do
        if g.equippable and not is_named(g.lname) then
            local key = g.lname .. '|' .. g.bag
            local r = byKey[key]
            if r == nil then
                r = { id = g.id, name = g.name, lname = g.lname, bag = g.bag, level = g.level, count = 0,
                    at = math.floor((g.order or 0) / 1000) }
                byKey[key], rows[#rows + 1] = r, r
            end
            r.count = r.count + 1
            C.perBag[g.bag] = (C.perBag[g.bag] or 0) + 1
            C.n = (C.n or 0) + 1
        end
    end
    table.sort(rows, function(a, b)
        if a.at ~= b.at then return a.at < b.at end
        return a.lname < b.lname
    end)
    C.rows, C.nFiles = rows, #files
end
ctx.draw_cleanup = function()
    local C = editorState.ui.cleanup
    if C == nil then return end
    if C.open then
        C.open = nil
        ctx.cleanup_scan(C)
        imgui.OpenPopup('##gcedit_cleanup')
    end
    if not imgui.BeginPopup('##gcedit_cleanup') then
        editorState.ui.cleanup = nil -- closed (a click outside it)
        return
    end
    local n = C.n or 0
    imgui.TextUnformatted((gState.PlayerName or 'You') .. ': ' .. n .. ' piece' .. ((n == 1) and '' or 's')
        .. ' in your equip bags nothing names')
    imgui.PushTextWrapPos(460)
    imgui.TextColored(palette.dim, 'Checked: ' .. C.nFiles .. ' job files, char.lua, the shared settings, GoomSwap\'s '
        .. 'own sets and code (a name in code counts). To store or move off a wardrobe. Read only: moves nothing.')
    imgui.PopTextWrapPos()
    imgui.BeginChild('##gcedit_cleanup_list', { 460, math.min(360, 60 + #C.rows * 28) }, CHILD_BORDERS)
    if n == 0 then imgui.TextColored(palette.ok, 'Every piece in your equip bags is named somewhere.') end
    local bag = nil
    for i, r in ipairs(C.rows) do
        if r.bag ~= bag then
            bag = r.bag
            imgui.TextColored(palette.section, bag .. ' (' .. C.perBag[bag] .. ')')
        end
        draw_icon(r.id, 24)
        imgui.SameLine()
        imgui.TextUnformatted(r.name .. ((r.count > 1) and (' x' .. r.count) or ''))
        imgui.SameLine()
        imgui.TextColored(palette.dim, 'Lv' .. tostring(r.level or '?'))
    end
    imgui.EndChild()
    if imgui.Button('Close##gcedit_cleanup') then
        editorState.ui.cleanup = nil
        imgui.CloseCurrentPopup()
    end
    imgui.EndPopup()
end

-- Backups (top bar): this file's editor backups (<file>.<date-time>.gcedit.bak, made by every Save), newest first,
-- each with the sets that differ from the file as it is now (Compare: slot by slot, then -> now). Restore puts one
-- back: the file is backed up first, then replaced and reloaded (/lac reload for the job loaded). Not while there
-- are unsaved edits.
ctx.backup_diff = function(old, now) -- two parsed files: { { name, lines } } for each set that differs
    local out, names, seen, a, b = {}, {}, {}, {}, {}
    for _, m in ipairs({ now, old }) do
        for _, st in ipairs(m.list) do
            local l = string.lower(st.name)
            if not seen[l] then seen[l], names[#names + 1] = true, st.name end
        end
    end
    for _, st in ipairs(old.list) do a[string.lower(st.name)] = st end
    for _, st in ipairs(now.list) do b[string.lower(st.name)] = st end
    for _, n in ipairs(names) do
        local so, sn = a[string.lower(n)], b[string.lower(n)]
        if so == nil then
            out[#out + 1] = { name = n, lines = { 'new since then (Restore takes it out)' } }
        elseif sn == nil then
            out[#out + 1] = { name = n, lines = { 'gone since then (Restore brings it back)' } }
        elseif (so.code ~= nil) or (sn.code ~= nil) then
            if so.code ~= sn.code then out[#out + 1] = { name = n, lines = { 'written as code: changed' } } end
        else
            local lines = {}
            for _, slot in ipairs(SCREEN) do
                local vo = (so.slots[slot] ~= nil) and so.slots[slot].value or nil
                local vn = (sn.slots[slot] ~= nil) and sn.slots[slot].value or nil
                if ((vo ~= nil) and vo.raw or nil) ~= ((vn ~= nil) and vn.raw or nil) then
                    lines[#lines + 1] = slot .. ': ' .. ((vo ~= nil) and tostring(vo.name or vo.raw) or 'empty')
                        .. ' -> ' .. ((vn ~= nil) and tostring(vn.name or vn.raw) or 'empty')
                end
            end
            if #lines > 0 then out[#out + 1] = { name = n, lines = lines } end
        end
    end
    return out
end
ctx.restore_backup = function(b) -- true when written
    local path, ui = editorState.document.path, editorState.ui
    local cur = read_file(path)
    if cur ~= nil then
        local keep, err = fileWriter.Backups.Path(path, exists_path)
        local wrote, werr = false, err
        if keep ~= nil then wrote, werr = fileWriter.Write(keep, cur) end
        if not wrote then
            ui.notice, ui.noticeBad = 'Not restored: could not back up the file first (' .. tostring(werr) .. ').', true
            return false
        end
    end
    local ok, err = fileWriter.Write(path, b.text)
    if not ok then
        ui.notice, ui.noticeBad = 'Not restored: ' .. tostring(err), true
        return false
    end
    if editorState.document.inactive then
        gcedit.Reload()
        ui.notice, ui.noticeBad = 'Restored ' .. editorState.document.file .. ' from ' .. b.when .. '.', false
        return true
    end
    gearEngine.Say('/gcedit: restored ' .. editorState.document.file .. ' from ' .. b.when .. '; reloading')
    ui.saving, ui.notice, ui.noticeBad = true, 'Restored: reloading the job file...', false
    GcEditReopen = nil
    fileWriter.Write(path .. '.gcedit-reopen', tostring(os.time()) .. '\n' .. (editorState.selection.setName or '')
        .. '\n' .. (editorState.selection.slot or ''))
    AshitaCore:GetChatManager():QueueCommand(-1, editorState.document.reloadCommand or '/lac reload')
    return true
end
ctx.draw_backups = function()
    local B = editorState.ui.backups
    if B == nil then return end
    if B.open then
        B.open = nil
        local path = editorState.document.path
        local folder = string.match(path, '^(.*[\\/])') or ''
        local okL, files = pcall(function() return ashita.fs.get_directory(folder, '.*') end)
        B.list = fileWriter.Backups.List(path, okL and files or nil) or {}
        local nowText = read_file(path)
        local nowModel = (nowText ~= nil) and fileWriter.Parse(nowText) or nil
        for _, b in ipairs(B.list) do
            b.text = read_file(b.path)
            local m = (b.text ~= nil) and fileWriter.Parse(b.text) or nil
            b.ok = (m ~= nil) and ((loadstring or load)(b.text, '=backup') ~= nil)
            b.diff = (b.ok and (nowModel ~= nil)) and ctx.backup_diff(m, nowModel) or nil
            local y, mo, d, h, mi = string.match(b.stamp, '^(%d%d%d%d)(%d%d)(%d%d)%-(%d%d)(%d%d)')
            b.when = (y ~= nil) and (y .. '-' .. mo .. '-' .. d .. ' ' .. h .. ':' .. mi) or b.stamp
            if b.sequence > 0 then b.when = b.when .. ' (' .. b.sequence .. ')' end
        end
        imgui.OpenPopup('##gcedit_backups')
    end
    if not imgui.BeginPopup('##gcedit_backups') then
        editorState.ui.backups = nil -- closed (a click outside it)
        return
    end
    imgui.TextUnformatted(editorState.document.file .. ' backups, newest first')
    imgui.TextColored(palette.dim, 'Every Save keeps one (EditorBackupKeep: the newest 3). Compare: then -> now.')
    local listH = math.min(380, 40 + #B.list * 26 + ((B.compare ~= nil) and 220 or 0))
    imgui.BeginChild('##gcedit_backups_list', { 560, listH }, CHILD_BORDERS)
    if #B.list == 0 then imgui.TextColored(palette.dim, 'None yet: the first Save makes one.') end
    for i, b in ipairs(B.list) do
        imgui.TextUnformatted(b.when)
        imgui.SameLine(0, 12)
        local d = b.diff
        local what
        if not b.ok then
            what = 'unreadable: not offered'
        elseif d == nil then
            what = '?'
        elseif #d == 0 then
            what = 'the same as now'
        else
            local names = {}
            for k = 1, math.min(3, #d) do names[k] = d[k].name end
            what = #d .. ((#d == 1) and ' set differs: ' or ' sets differ: ') .. table.concat(names, ', ')
                .. ((#d > 3) and '...' or '')
        end
        imgui.TextColored(palette.dim, what)
        if b.ok and (d ~= nil) and (#d > 0) then
            imgui.SameLine()
            local bw = text_w('Compare') + text_w('Restore') + 30
            local avail = (imgui.GetContentRegionAvail ~= nil) and xy(imgui.GetContentRegionAvail()) or nil
            if (avail ~= nil) and (avail > bw) and (imgui.SetCursorPosX ~= nil) then
                imgui.SetCursorPosX(imgui.GetCursorPosX() + avail - bw)
            end
            if imgui.SmallButton(((B.compare == i) and 'Hide' or 'Compare') .. '##gcbk_cmp' .. i) then
                B.compare = (B.compare ~= i) and i or nil
            end
            imgui.SameLine()
            if imgui.SmallButton('Restore##gcbk_res' .. i) then B.confirm = i end
        end
        if B.compare == i then
            imgui.Indent(16)
            imgui.PushTextWrapPos(0)
            for _, e in ipairs(d) do
                imgui.TextColored(palette.section, e.name)
                for _, line in ipairs(e.lines) do imgui.TextColored(palette.dim, '  ' .. line) end
            end
            imgui.PopTextWrapPos()
            imgui.Unindent(16)
        end
    end
    imgui.EndChild()
    local b = (B.confirm ~= nil) and B.list[B.confirm] or nil
    if b ~= nil then
        imgui.PushTextWrapPos(560)
        if dirty_count() > 0 then
            imgui.TextColored(palette.warn, 'Unsaved edits: Save + reload or Reload file first, then restore.')
        else
            imgui.TextColored(palette.warn, 'Restore ' .. b.when .. '? ' .. editorState.document.file
                .. ' is backed up first, then replaced and reloaded.')
            if red_button('Restore##gcbk_do') then
                if ctx.restore_backup(b) then
                    editorState.ui.backups = nil
                    imgui.CloseCurrentPopup()
                end
            end
            imgui.SameLine()
        end
        imgui.PopTextWrapPos()
        if imgui.Button('Cancel##gcbk_no') then B.confirm = nil end
        imgui.SameLine()
    end
    if imgui.Button('Close##gcbk_close') then
        editorState.ui.backups = nil
        imgui.CloseCurrentPopup()
    end
    imgui.EndPopup()
end
-- An item's hover: the sets naming it, as edited ('In 9 sets: Tp_Default, Midshot... +3'), nil when none.
-- Worked out once per edit for every item.
ctx.used_in = function(name)
    if type(name) ~= 'string' then return nil end
    local doc = editorState.document
    local U = editorState.cache.usedIn
    if (U == nil) or (U.rev ~= doc.revision) or (U.model ~= doc.model) then
        U = { rev = doc.revision, model = doc.model, by = {} }
        for _, set in ipairs(doc.model.list) do
            if not doc.deleted[set.name] then
                local seen = {}
                for _, slot in ipairs(SCREEN) do
                    local v = current(set, slot)
                    local named = (v ~= nil) and (v.kind == 'item') and (type(v.name) == 'string')
                    local l = named and string.lower(v.name) or nil
                    if (l ~= nil) and not seen[l] then
                        seen[l] = true
                        U.by[l] = U.by[l] or {}
                        table.insert(U.by[l], set.name)
                    end
                end
            end
        end
        editorState.cache.usedIn = U
    end
    local list = U.by[string.lower(name)]
    if list == nil then return nil end
    local shown = {}
    for i = 1, math.min(#list, 6) do shown[i] = list[i] end
    return 'In ' .. #list .. ((#list == 1) and ' set: ' or ' sets: ') .. table.concat(shown, ', ')
        .. ((#list > 6) and (' +' .. (#list - 6)) or '')
end
-- Recent (over the slots): the sets opened last, newest first, for this game session; a click opens one.
ctx.draw_recent = function(set)
    local p = editorState.preferences
    p.recent = (type(p.recent) == 'table') and p.recent or {}
    if p.recent[1] ~= set.name then
        for i = #p.recent, 1, -1 do
            if p.recent[i] == set.name then table.remove(p.recent, i) end
        end
        table.insert(p.recent, 1, set.name)
        while #p.recent > 7 do table.remove(p.recent) end
    end
    local shown = 0
    imgui.PushStyleColor(ImGuiCol_Button, palette.chipBg) -- quieter than the strip under it
    imgui.PushStyleColor(ImGuiCol_Text, palette.dim)
    for i = 2, #p.recent do
        local hit = editorState.document.model.byName[p.recent[i]]
        if hit ~= nil then
            if shown == 0 then
                imgui.TextColored(palette.dim, 'Recent:')
                imgui.SameLine()
            else
                editorPanels.SameLineIfFits(imgui, text_w(hit.name) + 16)
            end
            if imgui.SmallButton(hit.name .. '##gcrecent') then go_to(hit.name) end
            shown = shown + 1
        end
    end
    imgui.PopStyleColor(2)
    if shown > 0 then imgui.Separator() end
end

local function job_abbr_of(job)
    local s = AshitaCore:GetResourceManager():GetString('jobs.names_abbr', job)
    return (type(s) == 'string') and (string.gsub(s, '%z', '')) or ('job ' .. tostring(job))
end

-- Copy to other jobs (set menu): this set's pieces into the job files you tick. A piece that job can't wear is
-- left out (listed); slots this set leaves empty keep that file's own. Each file backed up, written only if it loads.
local function draw_copy_jobs()
    local req = editorState.ui.copyJobs
    if req == nil then return end
    if req.open then
        req.open = nil
        local set = editorState.document.model.byName[req.set]
        if set == nil then editorState.ui.copyJobs = nil; return end
        local res, player = AshitaCore:GetResourceManager(), AshitaCore:GetMemoryManager():GetPlayer()
        local _, others = job_files()
        req.plans = editorFiles.PlanCopy({
            name = set.name, parentName = set.parentName, key = set.key, slots = SCREEN,
            piece = function(slot) return current(set, slot) end,
            read = read_file, parse = fileWriter.Parse, item = function(n) return res:GetItemByName(n, 0) end,
            level = function(job) return player:GetJobLevel(job) end,
        }, others)
        req.pick, req.results = {}, nil
        for i, p in ipairs(req.plans) do req.pick[i] = { (p.err == nil) and (p.set == nil) } end -- new sets ticked
        imgui.OpenPopup('##gcedit_copyjobs')
    end
    if not imgui.BeginPopup('##gcedit_copyjobs') then return end
    imgui.TextUnformatted('Copy ' .. req.set .. ' to other jobs')
    imgui.TextColored(palette.dim, 'Pieces a job can\'t wear are left out. Empty slots keep that file\'s own.')
    imgui.BeginChild('##gcedit_copyjobs_list', { 460, 300 }, CHILD_BORDERS)
    local n = 0
    for i, p in ipairs(req.plans or {}) do
        if p.err ~= nil then
            imgui.TextColored(palette.dim, p.file.name .. ': ' .. p.err)
        else
            imgui.Checkbox(p.file.name .. ((p.set ~= nil) and ' (has one: its pieces in these slots are replaced)'
                or ' (new set)') .. '##copyjob' .. i, req.pick[i])
            if req.pick[i][1] then n = n + 1 end
            for _, d in ipairs(p.dropped) do
                local why = (d.why == 'job') and (job_abbr_of(p.file.job) .. ' can\'t wear it')
                    or ((d.why == 'code') and 'code, not copied') or ((d.why == 'code there') and 'code there')
                    or ('needs ' .. d.why)
                imgui.TextColored(palette.warn, '    left out: ' .. d.name .. ' (' .. d.slot .. '): ' .. why)
            end
        end
    end
    for _, r in ipairs(req.results or {}) do
        imgui.TextColored(r.ok and palette.ok or palette.bad, r.file.name .. (r.ok and ': copied' or (': ' .. r.err)))
    end
    imgui.EndChild()
    if (n > 0) and imgui.Button('Copy to ' .. n .. ' file' .. ((n == 1) and '' or 's') .. '##copyjobs') then
        local picked = {}
        for i, p in ipairs(req.plans) do
            if req.pick[i][1] then picked[#picked + 1] = p end
        end
        local keep = fileWriter.Backups.Keep((gearEngine.settings or {}).EditorBackupKeep)
        req.results = editorFiles.WriteCopies({
            name = req.set, setFile = fileWriter, read = read_file, exists = exists_path,
            prune = (keep > 0) and function(path, backup)
                local folder = path:match('^(.*[\\/])') or ''
                local ok, list = pcall(function() return ashita.fs.get_directory(folder, '.*') end)
                fileWriter.Backups.Prune(path, keep, ok and list or nil, os.remove, backup)
            end or nil,
        }, picked)
        local done, loaded = 0, false
        for _, r in ipairs(req.results) do
            if r.ok then
                done = done + 1
                loaded = loaded or (fileWriter.FileKey(r.file.path) == fileWriter.FileKey(gProfile and gProfile.FilePath))
            end
        end
        req.plans, req.pick = {}, {}
        feedback(req.set .. ' copied to ' .. done .. ' file' .. ((done == 1) and '' or 's')
            .. (loaded and ' (the loaded job: /lac reload to wear it).' or '.'))
    end
    imgui.SameLine()
    if imgui.Button('Close##copyjobs') then
        editorState.ui.copyJobs = nil
        imgui.CloseCurrentPopup()
    end
    imgui.EndPopup()
end

-- Find in every job file (slot menu): each set that names the item; this file as edited, the others as saved.
local function draw_find_item()
    local req = editorState.ui.findItem
    if req == nil then return end
    if req.open then
        req.open = nil
        local l = string.lower(req.name)
        req.here = {}
        for _, set in ipairs(editorState.document.model.list) do
            if not editorState.document.deleted[set.name] then
                for _, slot in ipairs(SCREEN) do
                    local v = current(set, slot)
                    if (v ~= nil) and (v.kind == 'item') and (string.lower(v.name or '') == l) then
                        req.here[#req.here + 1] = { set = set.name, slot = slot }
                    end
                end
            end
        end
        local _, others = job_files()
        req.others = editorFiles.FindItem(req.name, others, read_file, fileWriter.Parse, SCREEN)
        imgui.OpenPopup('##gcedit_finditem')
    end
    if not imgui.BeginPopup('##gcedit_finditem') then return end
    imgui.TextUnformatted(req.name .. ': ' .. (#req.here + #req.others) .. ' in your job files')
    imgui.BeginChild('##gcedit_finditem_list', { 420, 300 }, CHILD_BORDERS)
    local go = nil
    for i, h in ipairs(req.here) do
        if imgui.Selectable(editorState.document.file .. ': ' .. h.set .. ' / ' .. h.slot .. '##fi_here' .. i) then
            editorPreferences.Select(editorState, h.set, h.slot, 'gear')
            go = 'here'
        end
    end
    for i, h in ipairs(req.others) do
        if imgui.Selectable(h.file.name .. ': ' .. h.set .. ' / ' .. h.slot .. '##fi_other' .. i) then go = h end
        if imgui.IsItemHovered() then set_tip('Opens ' .. h.file.name .. ' in the editor at this set.') end
    end
    imgui.EndChild()
    if (go ~= nil) or imgui.Button('Close##finditem') then
        editorState.ui.findItem = nil
        imgui.CloseCurrentPopup()
    end
    imgui.EndPopup()
    if (go ~= nil) and (go ~= 'here') then gcedit.SwitchFile(go.file, false, go.set) end
end

local function draw_job_files()
    if imgui.SmallButton(editorState.document.file .. '##job_files') then
        job_files()
        imgui.OpenPopup('##job_file_picker')
    end
    if imgui.IsItemHovered() then set_tip('Browse this character\'s job files.\n' .. editorState.document.path) end
    if not imgui.BeginPopup('##job_file_picker') then return false end
    imgui.TextUnformatted('Job files for ' .. (gState.PlayerName or 'this character'))
    imgui.TextColored(palette.dim, 'Browse and edit; your active job stays loaded.')
    imgui.BeginChild('##job_file_list', { 360, 300 }, CHILD_BORDERS)
    local target
    for _, file in ipairs(editorState.ui.jobFiles or {}) do
        local label = file.name .. (file.active and ' (loaded)' or '') .. '##job_file_' .. file.path
        if imgui.Selectable(label, fileWriter.FileKey(file.path) == fileWriter.FileKey(editorState.document.path)) then
            target = file
        end
        if imgui.IsItemHovered() then set_tip(file.path) end
    end
    imgui.EndChild()
    ctx.newjob.Draw()
    if target then imgui.CloseCurrentPopup() end
    imgui.EndPopup()
    if target then gcedit.SwitchFile(target); return true end
    return false
end

-- Editor colours, chosen here (the theme button) and kept per character in <Name>_<id>\gcedit-theme.txt: 'bar' (what
-- the bar uses; the default), 'goomui' (the preset goomui saved for this character), 'goomswap' (GoomSwap's own) or
-- one of the presets. Hovering a choice in the menu previews it; the bar keeps its own (/gcbar theme, Theme).
local themeChoice, themeTarget, themeApplied, themeLabel, goomuiFound = nil, nil, false, '', nil
local THEME_SWATCH = { 'mp', 'hp_full', 'tp_rdy', 'hp_25', 'hp_0' } -- the editor's focus, ok, RP, warn and bad accents
local THEME_CELL = { 128, 0 }
local swatchCache = {}
local function theme_path()
    local dir = char_dir()
    return (dir ~= nil) and (dir .. 'gcedit-theme.txt') or nil
end
local function bar_theme() return (gcdisplay ~= nil) and gcdisplay.Theme or nil end
local function theme_set(choice, persist)
    local t = themes()
    themeChoice = choice
    if (t == nil) or (choice == 'goomswap') then themeTarget = nil
    elseif (choice == 'goomui') then themeTarget = t.Resolve(nil, t.GoomuiText())
    elseif (t.PRESETS[choice] ~= nil) then themeTarget = choice
    else themeTarget = bar_theme() end
    local shown = themeTarget or 'own'
    themeLabel = ((choice == 'bar') and ('Theme: bar (' .. shown .. ')')) or ((choice == 'goomui')
        and ('Theme: goomui (' .. shown .. ')'))
        or ((choice == 'goomswap') and 'Theme: GoomSwap') or ('Theme: ' .. choice)
    if persist then
        local path = theme_path()
        local f = (path ~= nil) and io.open(path, 'w') or nil
        if (f == nil) then
            gearEngine.Err('Could not save the editor theme' .. ((path ~= nil) and (' to ' .. path) or '') .. '.')
        else
            f:write(choice)
            f:close()
        end
    end
end
local function theme_load()
    local path = theme_path()
    local f = (path ~= nil) and io.open(path, 'r') or nil
    local choice = 'bar'
    if (f ~= nil) then
        local v = string.lower(string.match(f:read('*l') or '', '^%s*([%w_]+)') or '')
        f:close()
        local t = themes()
        if (v == 'goomui') or (v == 'goomswap') or ((t ~= nil) and (t.PRESETS[v] ~= nil)) then choice = v end
    end
    theme_set(choice, false)
end
local function use_theme(name)
    if (name ~= themeApplied) then
        apply_theme(name)
        themeApplied = name
    end
end
local function swatches(name)
    local t = themes()
    local list = swatchCache[name]
    if (list == nil) then
        list = {}
        for i, key in ipairs(THEME_SWATCH) do
            local c = t.Color(name, key)
            list[i] = (c ~= nil) and imgui.GetColorU32(c) or 0
        end
        swatchCache[name] = list
    end
    local x, y = xy(imgui.GetItemRectMin())
    local _, y2 = xy(imgui.GetItemRectMax())
    if (x == nil) or (y == nil) or (y2 == nil) or (imgui.GetWindowDrawList == nil) then return end
    local dl, cy = imgui.GetWindowDrawList(), (y + y2) / 2
    for i, col in ipairs(list) do dl:AddCircleFilled({ x + 6 + (i - 1) * 8, cy }, 3, col, 12) end
end
local function theme_menu()
    -- /gcbar theme changed it
    if (themeChoice == 'bar') and (bar_theme() ~= themeTarget) then theme_set('bar', false) end
    local t = themes()
    local previewing, preview = false, nil
    local function hover(name)
        if imgui.IsItemHovered() then previewing, preview = true, name end
    end
    local function choose(choice)
        theme_set(choice, true)
        feedback('Editor colours: ' .. string.gsub(themeLabel, '^Theme: ', '') .. '.')
        imgui.CloseCurrentPopup()
    end
    if imgui.SmallButton(themeLabel .. '##gcedit_theme') and (t ~= nil) then
        goomuiFound = t.Resolve(nil, t.GoomuiText()) -- read as the menu opens
        imgui.OpenPopup('##theme_options')
    end
    if imgui.IsItemHovered() then
        set_tip('Editor colours (hover a choice to preview). The bar keeps its own: /gcbar theme, or Theme in char.lua.')
    end
    if (t ~= nil) and imgui.BeginPopup('##theme_options') then
        imgui.TextColored(palette.dim, 'Editor colours')
        if (goomuiFound ~= nil) then
            imgui.PushStyleColor(ImGuiCol_Button, palette.save)
            imgui.PushStyleColor(ImGuiCol_ButtonHovered, palette.saveHi)
            if imgui.Button('Match goomui (' .. goomuiFound .. ')##th_goomui') then choose('goomui') end
            imgui.PopStyleColor(2)
            hover(goomuiFound)
        else
            imgui.TextColored(palette.dim, 'goomui: no saved theme for this character')
        end
        if imgui.Selectable('Same as the bar (' .. (bar_theme() or 'own colours') .. ')##th_bar',
            themeChoice == 'bar') then
            choose('bar')
        end
        hover(bar_theme())
        if imgui.Selectable("GoomSwap's own colours##th_own", themeChoice == 'goomswap') then choose('goomswap') end
        hover(nil)
        imgui.Separator()
        for i, name in ipairs(t.ORDER) do
            if ((i - 1) % 3 ~= 0) then imgui.SameLine() end
            if imgui.Selectable('       ' .. name .. '##th_' .. name, themeChoice == name, 0, THEME_CELL) then
                choose(name)
            end
            hover(name)
            swatches(name)
        end
        imgui.EndPopup()
    end
    if previewing then use_theme(preview) else use_theme(themeTarget) end
end

do -- (in a block: the main chunk is at Lua's 200 locals)
-- "Keep only my gear": /gcbuild on the live job, after the changes are saved or dropped (the draft replaces this view).
ctx.build_button = function(id)
    imgui.PushStyleColor(ImGuiCol_Button, palette.save)
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, palette.saveHi)
    local go = imgui.SmallButton('Keep only my gear (/gcbuild)##' .. id)
    imgui.PopStyleColor(2)
    if imgui.IsItemHovered() then
        set_tip(
            wrap(
                'Opens a draft here:\n- the example, with every piece you do not own commented out\n- your own +N of an item kept\nTo fill lists the gaps. Save writes it as your '
                    .. editorState.document.file .. '.', 60
            )
        )
    end
    if go then
        if dirty_count() > 0 then
            editorState.ui.notice, editorState.ui.noticeBad =
                'Save or revert your changes first: the draft replaces this view.', true
        else
            AshitaCore:GetChatManager():QueueCommand(-1, '/lac fwd gcbuild')
        end
    end
end

-- == Getting started: the first steps for a job file new to GoomSwap (the example as is, or a /gcbuild draft), each
-- ticked from what GoomSwap can see, until every one is done or it is hidden. preferences.start: 'on' (shown),
-- 'saved' (shown, saved once since), 'off' (done or hidden: not again for this job file). ==
local function start_steps()
    local doc = editorState.document
    local nf = fill_list().n
    local weapons = #ctx.weapon_picks() > 0 -- /mw /subw picks are weapons set up too
    for _, s in ipairs(doc.model.list) do
        if weapons then break end
        weapons = (string.match(s.name, '^[Ww]eapon_') ~= nil) and not doc.deleted[s.name]
    end
    local settings = (gearEngine ~= nil) and gearEngine.settings or nil
    return {
        { done = not doc.example, act = 'build', text = doc.example
            and ('Your own gear: this is still the ' .. tostring(doc.jobAbbreviation) .. ' example as is')
            or 'Your own gear, not the example as is' },
        { done = nf == 0, act = 'fill', text = (nf == 0) and 'Nothing left to fill'
            or (nf .. ' left to fill: empty slots, gear you lack or must move') },
        { done = weapons, act = 'wm', text = 'Your weapons: a /wm mode (or /mw /subw picks)' },
        { done = editorState.preferences.start == 'saved', act = 'save',
            text = 'Saved once: Save + reload writes your file (the old one kept as a backup)' },
        { done = (type(settings) == 'table') and (settings.DisplayBar == true), act = 'bar',
            text = 'The status bar on (/gcbar)' },
    }
end
local function start_dot(col, filled) -- a status dot at the line's start, then room for it
    local lh = (imgui.GetTextLineHeight ~= nil) and imgui.GetTextLineHeight() or 14
    if (imgui.GetWindowDrawList ~= nil) and (imgui.GetCursorScreenPos ~= nil) and (imgui.GetColorU32 ~= nil) then
        local x, y = xy(imgui.GetCursorScreenPos())
        if (x ~= nil) and (y ~= nil) then
            local dl = imgui.GetWindowDrawList()
            if filled then dl:AddCircleFilled({ x + 6, y + lh / 2 }, 4, imgui.GetColorU32(col), 12)
            else dl:AddCircle({ x + 6, y + lh / 2 }, 4, imgui.GetColorU32(col), 12, 1.5) end
        end
    end
    imgui.Dummy({ 16, lh })
    imgui.SameLine()
end
local function start_right(label) -- a small button at the line's right end
    imgui.SameLine()
    local w = text_w(label) + 12
    local avail = (imgui.GetContentRegionAvail ~= nil) and xy(imgui.GetContentRegionAvail()) or nil
    if (avail ~= nil) and (avail > w) and (imgui.SetCursorPosX ~= nil) and (imgui.GetCursorPosX ~= nil) then
        imgui.SetCursorPosX(imgui.GetCursorPosX() + avail - w)
    end
end
-- Draws the list when it is on; true when drawn (the example line is then its first step).
ctx.draw_start = function()
    local doc, p = editorState.document, editorState.preferences
    if doc.inactive or (p == nil) or (p.start == 'off') then return false end
    if p.start == nil then -- only a new job file starts it: not one you already set up
        if not (doc.example or (doc.sourcePath ~= nil)) then return false end
        p.start = 'on'
    end
    local steps = start_steps()
    local done = 0
    for _, st in ipairs(steps) do
        if st.done then done = done + 1 end
    end
    if done == #steps then
        p.start = 'off'
        feedback('Getting started: all ' .. #steps .. ' steps done.')
        return false
    end
    imgui.PushStyleColor(ImGuiCol_ChildBg, palette.selBg)
    imgui.BeginChild('##gcedit_start', { 0, 0 },
        (ImGuiChildFlags_AutoResizeY or 32) + (ImGuiChildFlags_AlwaysUseWindowPadding or 2),
        ImGuiWindowFlags_NoScrollbar or 0)
    if (imgui.GetWindowDrawList ~= nil) and (imgui.GetWindowPos ~= nil) and (imgui.GetColorU32 ~= nil) then
        local wx, wy = xy(imgui.GetWindowPos())
        local wh = imgui.GetWindowHeight()
        if (wx ~= nil) and (wy ~= nil) and (type(wh) == 'number') then
            imgui.GetWindowDrawList():AddRectFilled({ wx, wy }, { wx + 3, wy + wh }, imgui.GetColorU32(palette.sel))
        end
    end
    imgui.TextColored(palette.blue, 'Getting started')
    imgui.SameLine()
    imgui.TextColored(palette.dim, done .. ' of ' .. #steps .. ' done')
    start_right('Hide')
    if imgui.SmallButton('Hide##gcstart_hide') then
        p.start = 'off'
        feedback('Getting started hidden for ' .. tostring(doc.file) .. '.')
    end
    if imgui.IsItemHovered() then set_tip('Not shown again for ' .. tostring(doc.file) .. '.') end
    for i, st in ipairs(steps) do
        start_dot(st.done and palette.ok or palette.warn, st.done)
        imgui.TextColored(st.done and palette.dim or palette.text, st.text)
        if not st.done then
            if st.act == 'build' then
                start_right('Keep only my gear (/gcbuild)')
                ctx.build_button('gcstart_build')
            elseif st.act == 'fill' then
                start_right('To fill')
                if imgui.SmallButton('To fill##gcstart_fill') then editorState.selection.tab = 'fill' end
            elseif st.act == 'wm' then
                start_right('+ /wm mode')
                if imgui.SmallButton('+ /wm mode##gcstart_wm') then editorState.ui.requestNewWm = true end
                if imgui.IsItemHovered() then
                    set_tip('A /wm mode: New set Weapon_<Name> with Main and Sub. /wm <name> puts them on. Save adds '
                        .. 'it to gcinclude.WeaponModes.')
                end
            elseif st.act == 'save' then
                start_right('Save + reload')
                if imgui.SmallButton('Save + reload##gcstart_save') then editorState.ui.openSave = true end
                if imgui.IsItemHovered() then
                    set_tip('The same as Save + reload at the top: shows what changes first.')
                end
            elseif st.act == 'bar' then
                start_right('Turn it on')
                if imgui.SmallButton('Turn it on##gcstart_bar') then
                    AshitaCore:GetChatManager():QueueCommand(-1, '/lac fwd gcbar on')
                end
            end
        end
    end
    imgui.EndChild()
    imgui.PopStyleColor()
    return true
end
end

local function body()
    editorPreferences.TickFeedback(editorState, imgui.GetIO().DeltaTime or 0)
    editorState.ui.frame = (editorState.ui.frame or 0) + 1
    -- the slot hovered last frame (a card or its row in What goes on): both light up this frame
    editorState.ui.hoverShown, editorState.ui.hoverSlot = editorState.ui.hoverSlot, nil
    editorState.ui.cardShown, editorState.ui.cardHover = editorState.ui.cardHover, nil -- the card itself, for its ...
    if editorState.history.revision ~= editorState.document.revision then
        editorState.history.entries, editorState.history.redo = {}, nil
        editorState.history.revision = editorState.document.revision
    end
    editorState.cache.head = editorState.cache.head
        or string.format(
            '%s  %s%d',
            gState.PlayerName or '',
            AshitaCore:GetResourceManager():GetString('jobs.names_abbr',
                AshitaCore:GetMemoryManager():GetPlayer():GetMainJob()) or '?',
            AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel()
        )
    if draw_png('goomy.png', 25, 30) then imgui.SameLine(0, 12) end
    pill(editorState.cache.head, palette.text, palette.chipBg)
    imgui.SameLine(0, 14)
    if draw_job_files() then return end
    -- the left: who, which file, saved or not; the right: Rules, Settings, ... (view, density, theme, the file's
    -- tools) and Save
    local n = dirty_count()
    imgui.SameLine(0, 10)
    if n > 0 then
        imgui.PushStyleColor(ImGuiCol_Button, palette.warnBg)
        imgui.PushStyleColor(ImGuiCol_Text, palette.warn)
        if imgui.SmallButton(string.format('%d unsaved##gcedit_unsaved', n)) then show_unsaved_sets() end
        imgui.PopStyleColor(2)
        if imgui.IsItemHovered() then set_tip(n .. ' unsaved change' .. ((n == 1) and '' or 's') .. ': show the '
            .. unsaved_set_count() .. ' sets with them.') end
    else
        pill('saved', palette.ok, palette.okBg)
    end
    local d = editorPanels.Density(ctx.spacing())
    local saveLabel = editorState.document.inactive and 'Save file' or 'Save + reload'
    local need = text_w(ctx.rules.TopLabel()) + text_w('GoomSwap settings') + text_w('Editor') + text_w(saveLabel)
        + 8 * d.padding[1] + 3 * d.spacing[1]
    imgui.SameLine()
    local avail = imgui.GetContentRegionAvail()
    avail = (type(avail) == 'number') and avail or (avail.x or avail[1])
    if avail < need then
        imgui.NewLine()
    elseif (imgui.SetCursorPosX ~= nil) and (imgui.GetCursorPosX ~= nil) then
        imgui.SetCursorPosX(imgui.GetCursorPosX() + avail - need)
    end
    ctx.rules.TopButton() -- the Rules page (and how many ifs Convert could take)
    imgui.SameLine()
    if imgui.Button('GoomSwap settings##gcsettings') then editorState.ui.settingsOpen = { true } end
    if imgui.IsItemHovered() then
        set_tip('How GoomSwap behaves in game, for every job file that loads it: what an include file\'s settings are '
            .. 'in GearSwap or LuAshitacast (DT gear below HP, Moonshade TP, keys, the bar...). For you on every job, '
            .. 'on this job, or for everyone.\n\nThe editor\'s own spacing and theme: Editor.')
    end
    imgui.SameLine()
    local tools = { backups = false, cleanup = false, rescan = false, reload = false }
    if imgui.Button('Editor##gcedit_more') then imgui.OpenPopup('##gcedit_tools') end
    if imgui.IsItemHovered() then
        set_tip('This editor itself: its spacing and theme; this file\'s Backups, Unused gear, Rescan bags, Reload '
            .. 'file. (How GoomSwap behaves in game: GoomSwap settings.)')
    end
    if imgui.BeginPopup('##gcedit_tools') then
        -- either/or choices as switches, each with what the one on does
        imgui.PushTextWrapPos(imgui.GetCursorPosX() + 330)
        imgui.TextColored(palette.dim, 'Spacing')
        imgui.SameLine(90)
        local dens = ctx.spacing()
        local pickD = ctx.W.Switch('gct_dens', {
            { 'Compact', 'Compact', 'Icon cards: each slot as its icon (its name and stats on hover). More fits.' },
            { 'Comfortable', 'Comfortable', 'Named cards: each slot names its piece and what is under it.' },
        }, dens)
        if pickD ~= nil then -- GoomSwap settings' EditorSpacing, in char.lua: every job, every session
            local ok, err = settingsFiles.Write('own', { EditorSpacing = pickD })
            GcEditSpacing = (not ok) and pickD or nil
            if not ok then feedback('Spacing for this session only (not saved to char.lua: ' .. tostring(err) .. ').') end
        end
        imgui.TextColored(palette.dim, (dens == 'Comfortable') and 'Comfortable: each slot card names its piece.'
            or 'Compact: icon cards, name and stats on hover. More fits.')
        imgui.PopTextWrapPos()
        imgui.Spacing()
        theme_menu()
        imgui.Separator()
        imgui.TextColored(palette.dim, 'This file')
        tools.backups = imgui.Selectable('Backups##gct_b', false)
        if imgui.IsItemHovered() then set_tip('Every Save keeps a dated copy of the file: see what each changed, and put one back.') end
        tools.cleanup = imgui.Selectable('Unused gear##gct_u', false)
        if imgui.IsItemHovered() then
            set_tip('The gear in your Inventory and Wardrobes that none of your job files, char.lua or GoomSwap names. Read only.')
        end
        tools.rescan = imgui.Selectable('Rescan bags##gct_r', false)
        if imgui.IsItemHovered() then set_tip('Read your bags again (after moving gear). Keeps your unsaved changes.') end
        tools.reload = imgui.Selectable('Reload file##gct_l', false)
        if imgui.IsItemHovered() then set_tip('Read the file and your bags again.') end
        -- /gcbuild's notes (its header, a slot's "example: / move it to a wardrobe"): a snapshot that goes stale
        local doc = editorState.document
        if (doc.model ~= nil) and (doc.notesText ~= doc.model.text) then
            doc.notesText, doc.notesN = doc.model.text, (setFile.BuildNotes(doc.model.text))
        end
        if doc.dropNotes then
            if imgui.Selectable('Keep /gcbuild notes (they go on Save)##gct_n', false) then
                doc.dropNotes, doc.revision = nil, doc.revision + 1
            end
        elseif (doc.notesN or 0) > 0 then
            if imgui.Selectable('Remove /gcbuild notes (' .. doc.notesN .. ')##gct_n', false) then
                doc.dropNotes, doc.revision = true, doc.revision + 1
                feedback('/gcbuild notes go on Save (' .. doc.notesN .. ').')
            end
            if imgui.IsItemHovered() then
                set_tip("What /gcbuild wrote that day: the header at the top, and notes after slots (\"example: ...\", "
                    .. "\"move it to a wardrobe\", \"your augments differ\"). The slots it left out (-- not owned) "
                    .. 'stay: To fill lists them.')
            end
        end
        imgui.Separator()
        if editorPanels.Section(imgui, palette, 'Diagnostics##gcedit_diagnostics') then
            if imgui.Button(profiler.enabled and 'Stop sampling' or 'Start fresh sample') then
                profiler.enabled = not profiler.enabled
                if profiler.enabled then profiler.Reset() end
            end
            imgui.TextUnformatted('Up to 600 samples per section. CPU time, not FPS.')
            for _, name in ipairs({ 'Render', 'Bag scan', 'Item tooltip', 'Action view rebuild', 'RP usage rebuild',
                'Set stats build' }) do
                imgui.TextUnformatted(profiler.Report(name))
            end
        end
        imgui.TextColored(palette.dim, 'GoomSwap v3.30')
        imgui.EndPopup()
    end
    if tools.backups then editorState.ui.backups = { open = true } end
    ctx.draw_backups()
    if tools.cleanup then editorState.ui.cleanup = { open = true } end
    ctx.draw_cleanup()
    if tools.rescan then
        rescan()
        feedback('Bags rescanned: ' .. #editorState.inventory.items .. ' items. Unsaved edits kept.')
    end
    if tools.reload then
        if n > 0 then
            editorState.ui.confirm = 'reload'
        else
            gcedit.Reload()
            return
        end
    end
    imgui.SameLine()
    -- a draft saves as it is too
    local canSave = ((n > 0) or (editorState.document.sourcePath ~= nil)) and not editorState.ui.saving
    local off = (not canSave) and (imgui.BeginDisabled ~= nil)
    if off then imgui.BeginDisabled() end
    imgui.PushStyleColor(ImGuiCol_Button, palette.save)
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, palette.saveHi)
    if imgui.Button(editorState.document.inactive and 'Save file##gcedit' or 'Save + reload##gcedit') and canSave then
        imgui.OpenPopup('##save_preview')
    end
    if editorState.ui.openSave then -- Getting started's Save + reload: opened here, where the popup lives
        editorState.ui.openSave = nil
        if canSave then imgui.OpenPopup('##save_preview') end
    end
    imgui.PopStyleColor(2)
    if off then imgui.EndDisabled() end
    draw_save_review()
    if editorState.ui.confirm ~= nil then
        imgui.TextColored(
            palette.warn,
            string.format(
                '%s drops %d unsaved change%s%s',
                (editorState.ui.confirm == 'close') and 'Closing'
                    or (editorState.ui.confirm == 'switch' and ('Opening ' .. editorState.ui.nextFile.name)
                        or 'Reloading'),
                n, (n == 1) and '' or 's', (editorState.ui.confirm == 'close') and ' (X again: close anyway).' or '.'
            )
        )
        imgui.SameLine()
        if red_button('Discard them##gcedit_cf', true) then
            local what = editorState.ui.confirm
            editorState.ui.confirm = nil
            if what == 'close' then
                editorState.ui.open[1] = false
                editorState.ui.force = true
            elseif what == 'switch' then
                gcedit.SwitchFile(editorState.ui.nextFile, true, editorState.ui.nextSet)
            else
                gcedit.Reload()
            end
            return
        end
        imgui.SameLine()
        if imgui.SmallButton('Keep editing##gcedit_cf') then editorState.ui.confirm = nil end
    end
    if editorState.document.inactive then
        editorPanels.Text(imgui, palette.blue, 'Editing ' .. editorState.document.file
            .. ' only. Save does not load this job. Live modes/settings and action history are excluded.', true)
    end
    if editorState.document.sourcePath ~= nil then
        editorState.ui.draftLine = editorState.ui.draftLine
            or (
                string.format(
                    'Draft (%s). To fill lists the gaps.\nSave writes it as %s%s%s.',
                    string.match(editorState.document.sourcePath, '[^\\/]+$'),
                    editorState.document.file,
                    (read_file(editorState.document.path) ~= nil) and ' (the old one is kept as a .gcedit.bak)' or '',
                    editorState.document.inactive and ': change to its job to use it' or ' and loads it'
                )
            )
        imgui.PushTextWrapPos(0)
        imgui.TextColored(palette.blue, editorState.ui.draftLine)
        imgui.PopTextWrapPos()
    end
    local starting = ctx.draw_start() -- Getting started: the example line below is then its first step
    if editorState.document.example and not editorState.document.inactive and not starting then -- /gcbuild: live job
        imgui.TextColored(
            palette.blue,
            'This is the '
                .. editorState.document.jobAbbreviation .. ' example as is: its sets name gear you may not own.'
        )
        imgui.SameLine()
        ctx.build_button('gcedit_build')
    end
    if editorState.ui.notice ~= nil then
        imgui.PushTextWrapPos(0)
        imgui.TextColored(editorState.ui.noticeBad and palette.bad or palette.dim, editorState.ui.notice)
        imgui.PopTextWrapPos()
    end
    local message = editorState.ui.feedback and editorState.ui.feedback.text
    if message then
        imgui.TextColored(palette.ok, cardText.Fit(message, imgui.GetWindowWidth() - 40, text_w))
        if imgui.IsItemHovered() then set_tip(message) end
    else
        imgui.TextUnformatted(' ')
    end
    imgui.Separator()

    local availableWidth, availableHeight = xy(imgui.GetContentRegionAvail())
    local spacing = 8
    local style = imgui.GetStyle and imgui.GetStyle()
    if style and style.ItemSpacing then spacing = style.ItemSpacing.x or style.ItemSpacing[1] or spacing end
    local set = (editorState.selection.setName ~= nil)
            and editorState.document.model.byName[editorState.selection.setName] or nil
    -- fixed panes (no dragging); the Rules page has its own list on the left and takes the whole width
    local rulesPage = editorState.selection.rules and (ctx.rules ~= nil)
    local lay = editorPanels.Layout(availableWidth or 1200, text_w('0'), spacing, ctx.CARD_W)
    if not rulesPage then
        imgui.BeginChild('##gcedit_left', { lay.left, 0 }, CHILD_BORDERS)
        draw_sets()
        imgui.EndChild()
        imgui.SameLine(0, lay.gap)
    end
    imgui.BeginChild('##gcedit_mid', { rulesPage and 0 or lay.middle, 0 }, 0)
    local gridWidth = xy(imgui.GetContentRegionAvail())
    GRID_COLUMNS, CELL_W = editorPanels.Grid(gridWidth, spacing, ctx.CARD_W)
    ctx.GRID_COLUMNS, ctx.CELL_W = GRID_COLUMNS, CELL_W
    local inspectorHeight
    if editorState.ui.pinned then
        inspectorHeight = math.min(320, math.max(150, availableHeight * (gridWidth < 500 and 0.40 or 0.32)))
        imgui.BeginChild('##gcedit_grid', { 0, math.max(1, availableHeight - inspectorHeight - 8) }, 0)
    end
    if editorState.selection.rules and (ctx.rules ~= nil) then
        ctx.rules.Draw()
    elseif set ~= nil then
        ctx.draw_recent(set)
        draw_set(set)
        m_gceditrelated.draw_upgrade(set) -- a piece changed here that other sets still have: offer it there
    else
        imgui.TextColored(palette.dim, 'Pick a set on the left.')
    end
    if inspectorHeight then
        imgui.EndChild()
        editorInspect.DrawPinned(imgui, palette, editorState, itemTooltip, inspectorHeight, draw_icon)
    end
    imgui.EndChild()
    if not rulesPage then
    imgui.SameLine(0, lay.gap)
    imgui.BeginChild('##gcedit_right', { 0, 0 }, CHILD_BORDERS)
    local nf = fill_list().n
    -- one set of tabs: what the set does in game, picking gear, its stats; Compare while one is picked
    local tabs = { { 'What goes on', 'action' }, { 'Gear', 'gear' }, { 'Stats', 'summary' } }
    if set and cmp_of(set) then tabs[#tabs + 1] = { 'Compare', 'compare' } end
    tabs[#tabs + 1] = { 'Related', 'over' }
    tabs[#tabs + 1] = { nf > 0 and ('To fill (' .. nf .. ')') or 'To fill', 'fill' }
    local tab = editorPanels.Tabs(imgui, palette, editorState.selection.tab, tabs)
    if tab ~= editorState.selection.tab then editorState.ui.fromFill = nil end -- a tab of your own choosing
    editorState.selection.tab = tab
    imgui.Separator()
    if editorState.selection.tab == 'compare' then
        if set then
            editorUI.Stats.Controls(imgui, palette, editorState)
            local other = cmp_of(set)
            local leftStats, rightStats = set_stats(set), other and set_stats(other)
            local pair = editorState.cache.statPair
            if rightStats and (not pair or pair.left ~= leftStats or pair.right ~= rightStats) then
                pair = statModel.Compare(leftStats, rightStats)
                local function preview(candidate, slot)
                    return (candidate == set and leftStats or rightStats).definitions[slot]
                end
                pair.gearRows, pair.gearDifferences = editorInspect.Rows(SCREEN, set, other, preview, false)
                pair.definitionRows, pair.definitionDifferences = editorInspect.Rows(SCREEN, set, other, current, false)
                for _, row in ipairs(pair.gearRows) do
                    row.leftSource, row.rightSource = leftStats.sources[row.slot], rightStats.sources[row.slot]
                end
                editorState.cache.statPair = pair
            end
            if (pair ~= nil) and (editorState.ui.comparePins == nil) then -- Compare's pinned stats, every job
                local saved = settingsFiles.Get('EditorComparePins')
                editorState.ui.comparePins = (type(saved) == 'table') and saved or statModel.DefaultPins
                editorState.ui.toggleComparePin = function(name)
                    local list, found = {}, false
                    for _, n in ipairs(editorState.ui.comparePins) do
                        if string.lower(n) == string.lower(name) then found = true else list[#list + 1] = n end
                    end
                    if not found then list[#list + 1] = name end
                    editorState.ui.comparePins = list
                    local ok, err = settingsFiles.Write('own', { EditorComparePins = list })
                    if not ok then feedback('Pins not saved: ' .. tostring(err) .. '.') end
                end
            end
            if pair ~= nil then pair.pinned = statModel.Pinned(pair, editorState.ui.comparePins) end
            editorInspect.DrawComparison(
                imgui, palette, editorState, set, other, SCREEN, current, copy_from, leftStats, rightStats, pair
            )
        end
    elseif editorState.selection.tab == 'fill' then
        draw_fill()
    elseif set ~= nil then
        if editorState.selection.tab == 'summary' then
            editorUI.Stats.Controls(imgui, palette, editorState)
            editorUI.Stats.DrawSummary(imgui, palette, set.name, set_stats(set))
        elseif editorState.selection.tab == 'action' then
            imgui.PushTextWrapPos(0)
            draw_layers(set)
            imgui.PopTextWrapPos()
        elseif editorState.selection.tab == 'over' then
            draw_over(set)
        else
            draw_picker(set)
        end
    end
    imgui.EndChild()
    end
    if editorState.ui.openSetChooser then
        imgui.OpenPopup('##gcedit_copy')
        editorState.ui.openSetChooser = nil
    end
    if set then draw_copy_popup(set) end
    draw_context_menu()
    draw_delete_confirmation()
    m_gceditrelated.draw_weapon_sets()
    m_gceditrelated.draw_mset_mode()
    m_gceditrelated.draw_wm_mode()
    m_gceditrelated.draw_put_in()
    draw_copy_jobs()
    draw_find_item()
    draw_rename()
end

-- The rest of the window's colours (buttons, ticks, scrollbars, title, resize grip) in the editor's greys and blue
-- instead of the theme's red; a colour this ImGui lacks is skipped.
local themeList = nil
local function theme()
    if themeList ~= nil then return themeList end
    themeList = {}
    local function add(k, c)
        if k ~= nil then themeList[#themeList + 1] = { k, c } end
    end
    add(ImGuiCol_Button, palette.btn)
    add(ImGuiCol_ButtonHovered, palette.btnHi)
    add(ImGuiCol_ButtonActive, palette.selBg)
    add(ImGuiCol_FrameBg, palette.cell)
    add(ImGuiCol_FrameBgHovered, palette.btn)
    add(ImGuiCol_FrameBgActive, palette.btnHi)
    add(ImGuiCol_CheckMark, palette.sel)
    add(ImGuiCol_HeaderActive, palette.selBg)
    add(ImGuiCol_ScrollbarBg, palette.panel)
    add(ImGuiCol_ScrollbarGrab, palette.grab)
    add(ImGuiCol_ScrollbarGrabHovered, palette.grabHi)
    add(ImGuiCol_ScrollbarGrabActive, palette.sel)
    add(ImGuiCol_TitleBg, palette.title)
    add(ImGuiCol_TitleBgActive, palette.title)
    add(ImGuiCol_TitleBgCollapsed, palette.title)
    add(ImGuiCol_ResizeGrip, palette.grab)
    add(ImGuiCol_ResizeGripHovered, palette.grabHi)
    add(ImGuiCol_ResizeGripActive, palette.sel)
    add(ImGuiCol_Separator, palette.edge)
    add(ImGuiCol_TableHeaderBg, palette.cell)
    return themeList
end

-- Restore ImGui windows and style stacks if a draw callback fails.
-- /gcedit: ImGui begin/end pairing guard (a draw error must not leave windows or styles open).
local OPENERS = {
    BeginChild = 'EndChild',
    BeginPopup = 'EndPopup',
    BeginMenu = 'EndMenu',
    BeginTable = 'EndTable',
    BeginDisabled = 'EndDisabled',
    BeginGroup = 'EndGroup',
    BeginTooltip = 'EndTooltip',
}
-- closed whatever they return
local ALWAYS = { BeginChild = true, BeginDisabled = true, BeginGroup = true, BeginTooltip = true }
local function guarded(fn)
    local real, open, cols, vars = {}, {}, 0, 0
    local ok = pcall(function()
        for b, e in pairs(OPENERS) do
            if (imgui[b] ~= nil) and (imgui[e] ~= nil) then
                real[b], real[e] = imgui[b], imgui[e]
                imgui[b] = function(...)
                    local r = real[b](...)
                    if ALWAYS[b] or r then open[#open + 1] = e end
                    return r
                end
                imgui[e] = function(...)
                    open[#open] = nil
                    return real[e](...)
                end
            end
        end
        real.PushStyleColor, real.PopStyleColor, real.PushStyleVar, real.PopStyleVar =
            imgui.PushStyleColor, imgui.PopStyleColor, imgui.PushStyleVar, imgui.PopStyleVar
        imgui.PushStyleColor = function(...)
            cols = cols + 1
            return real.PushStyleColor(...)
        end
        imgui.PopStyleColor = function(n)
            cols = cols - (n or 1)
            return real.PopStyleColor(n)
        end
        imgui.PushStyleVar = function(...)
            vars = vars + 1
            return real.PushStyleVar(...)
        end
        imgui.PopStyleVar = function(n)
            vars = vars - (n or 1)
            return real.PopStyleVar(n)
        end
    end)
    local fine, err = pcall(fn)
    pcall(function()
        for k, f in pairs(real) do
            imgui[k] = f
        end
    end) -- the real calls back, whatever happened
    if not ok then
        return fine, err
    end -- could not count: as before
    if not fine then
        for i = #open, 1, -1 do
            pcall(real[open[i]])
        end
        if cols > 0 then pcall(real.PopStyleColor, cols) end
        if vars > 0 then pcall(real.PopStyleVar, vars) end
    end
    return fine, err
end
local function render()
    if not editorState.open then return end
    if (AshitaCore:GetFontManager():GetVisible() == false) or (AshitaCore:GetGuiManager():GetVisible() == false) then
        return
    end
    local spacing = ctx.spacing()
    local density = editorPanels.Density(spacing)
    if editorState.cache.density ~= spacing then
        editorState.cache.density = spacing
        editorState.cache.rowH, editorState.cache.listKey = nil, nil
        editorState.cache.fill, editorState.cache.fillVer, editorState.ui.over = nil, nil, nil
        for _, set in ipairs(editorState.document.model.list) do set.clipH = nil end
    end
    CELL_H, ICON, ROW_ICON = density.cardHeight, density.icon, density.rowIcon
    ctx.CELL_H, ctx.ICON, ctx.ROW_ICON = CELL_H, ICON, ROW_ICON
    ctx.CARD_W, ctx.CARD_NAMES = density.card, density.names -- Compact: icon cards; Comfortable: named ones
    local timing = profiler.Start()
    local display = imgui.GetIO().DisplaySize
    imgui.SetNextWindowSize(editorPanels.WindowSize(display.x or display[1], display.y or display[2]),
        ImGuiCond_FirstUseEver)
    if imgui.SetNextWindowSizeConstraints ~= nil then -- dragged no smaller than stays readable; a binding that
        pcall(imgui.SetNextWindowSizeConstraints, editorPanels.MIN_SIZE, { 100000, 100000 }) -- refuses: no floor
    end
    imgui.PushStyleColor(ImGuiCol_WindowBg, palette.bg)
    imgui.PushStyleColor(ImGuiCol_ChildBg, palette.panel)
    imgui.PushStyleColor(ImGuiCol_Border, palette.edge)
    imgui.PushStyleColor(ImGuiCol_Header, palette.selBg)
    imgui.PushStyleColor(ImGuiCol_HeaderHovered, palette.btnHi) -- hover grey: blue means selected
    imgui.PushStyleColor(ImGuiCol_Text, palette.text)
    local n = 6
    for _, kc in ipairs(theme()) do
        imgui.PushStyleColor(kc[1], kc[2])
        n = n + 1
    end
    local nv = 0 -- rounded corners: window, panels and cells, buttons and boxes
    for _, sv in ipairs({
        { ImGuiStyleVar_WindowRounding, 6 },
        { ImGuiStyleVar_ChildRounding, 5 },
        { ImGuiStyleVar_FrameRounding, 4 },
        { ImGuiStyleVar_PopupRounding, 4 },
        { ImGuiStyleVar_GrabRounding, 4 },
        { ImGuiStyleVar_ItemSpacing, density.spacing },
        { ImGuiStyleVar_FramePadding, density.padding },
    }) do
        if sv[1] ~= nil then
            imgui.PushStyleVar(sv[1], sv[2])
            nv = nv + 1
        end
    end
    iconBudget = ICONS_PER_FRAME
    ctx.iconBudget = iconBudget
    local ok, err = true, nil
    if imgui.Begin('GoomSwap set editor###gcedit_w2', editorState.ui.open, ImGuiWindowFlags_NoCollapse) then
        ok, err = guarded(body) -- an error must not skip End/PopStyleColor, nor leave a panel open
    end
    if editorState.open and (editorState.ui.drag ~= nil) then
        if (imgui.IsMouseDown ~= nil) and imgui.IsMouseDown(0) then
            set_tip(editorState.ui.drag.g.name .. '\nDrop it on a slot.')
        else
            editorState.ui.drag = nil
        end -- let go outside a slot
    end
    if editorState.open and (editorState.ui.dragSet ~= nil) then
        if (imgui.IsMouseDown ~= nil) and imgui.IsMouseDown(0) then
            set_tip(editorState.ui.dragSet .. '\nDrop it on a heading, or on a set to put it before that one.')
        else
            editorState.ui.dragSet = nil
        end -- let go elsewhere
    end
    imgui.End()
    -- the Settings window: its own, in the editor's colours (still pushed)
    if ok and editorState.open and (editorState.ui.settingsOpen ~= nil) and editorState.ui.settingsOpen[1] then
        settingsPanel = settingsPanel or gFunc.LoadFile('common\\gceditsettingsui.lua')(imgui, palette, set_tip,
            settingsFiles, editorGroups, setFile, editorState, feedback)
        if imgui.SetNextWindowSize ~= nil then imgui.SetNextWindowSize({ 980, 600 }, ImGuiCond_FirstUseEver or 4) end
        local sok, serr = true, nil
        if imgui.Begin('GoomSwap settings###gcedit_settings', editorState.ui.settingsOpen, 0) then
            sok, serr = guarded(settingsPanel.Body)
        end
        imgui.End()
        if not sok then
            editorState.ui.settingsOpen[1] = false
            feedback('Settings closed after an error: ' .. tostring(serr))
        end
    end
    imgui.PopStyleVar(nv)
    imgui.PopStyleColor(n)
    profiler.Finish('Render', timing)
    if not ok then
        -- unsaved edits survive the error: the next /gcedit on the same file reopens them
        local kept = editorState.open and (dirty_count() > 0)
        if kept then
            local copy = {}
            for k, v in pairs(editorState) do copy[k] = v end
            rescued = { path = editorState.document.path, state = copy }
        end
        gcedit.Close()
        gearEngine.Err('/gcedit closed after an error: ' .. tostring(err)
            .. (kept and ' Unsaved edits kept: /gcedit to reopen them.' or ''))
    elseif editorState.open and (editorState.ui.open[1] == false) then
        -- X again while asked: close, dropping them
        if editorState.ui.force or (dirty_count() == 0) or (editorState.ui.confirm == 'close') then
            gcedit.Close()
        else
            editorState.ui.open[1], editorState.ui.confirm = true, 'close' -- the X with unsaved changes: ask first
        end
    end
end

---------------------------------------------------------------------------------------------------------------------

-- draft (from /gcbuild): { src = <JOB>.proposed.lua (read), target = the job file Save writes, reload = the command
-- after Save ('/lac reload' when target is the loaded file, else '/lac load') }.
function gcedit.Open(include, setName, slot, draft)
    gearEngine = include
    ctx.gearEngine = include
    settingsFiles.Reset() -- another character may have changed the shared file
    itemTooltip.Reset()
    if (themeChoice == nil) then theme_load() else theme_set(themeChoice, false) end -- the editor's own colours
    use_theme(themeTarget)
    if (draft == nil) and ((gProfile == nil) or (type(gProfile.FilePath) ~= 'string')) then
        gearEngine.Err('/gcedit: no job file loaded (/lac load).')
        return
    end
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    local path = (draft ~= nil) and draft.target or gProfile.FilePath
    if rescued ~= nil then
        if (draft == nil) and (rescued.path == path) then
            -- reopen the edits an error closed, without the view that failed
            set_state(rescued.state)
            rescued = nil
            editorState.cache = {}
            bind_actions()
            rescan()
            gearEngine.Say('/gcedit: unsaved edits restored.')
            ashita.events.register('d3d_present', 'gcedit_render', render)
            return
        end
        if draft ~= nil then
            gearEngine.Say('/gcedit: unsaved edits from the last error are kept; /gcedit on the job file reopens them.')
        else
            rescued = nil -- another job's file: the old edits do not apply
        end
    end
    if GcEditFold == nil then settingsFiles.RemoveOldFolds() end
    set_state(editorPreferences.New({
        path = path,
        sourcePath = draft and draft.src,
        reloadCommand = draft and draft.reload,
        draft = draft ~= nil,
        job = (draft and draft.job) or player:GetMainJob(), -- draft.job: another job's (/gcimport), not loaded
        level = not (draft and draft.inactive) and player:GetMainJobLevel() or nil,
        preferences = editorPreferences.Load(path),
        fold = GcEditFold or {}, -- folded headings: this game session's
    }))
    editorState.document.characterFolder = char_dir() or path:match('^(.*[\\/])') or ''
    editorState.document.inactive = (draft ~= nil) and (draft.inactive == true) -- Save file, the active job kept
    local model, err = load_model()
    if model == nil then
        gearEngine.Err('/gcedit: ' .. tostring(err))
        set_state(nil)
        return
    end
    GcEditFold = editorState.ui.fold -- a global: folded groups stay folded after Save's reload
    editorState.document.model, editorState.document.revision = model, 0
    bind_actions()
    if (draft == nil) and (gearEngine.UnchangedExample ~= nil) then
        local ok, job = pcall(gearEngine.UnchangedExample)
        editorState.document.example, editorState.document.jobAbbreviation = ok and (job ~= nil), job
    end
    rescan()
    pcall(wi_from_game)
    local want = nil
    if setName ~= nil then
        for _, set in ipairs(model.list) do
            if string.lower(set.name) == string.lower(setName) then
                want = set.name
                break
            end
        end
        if want == nil then
            gearEngine.Say('/gcedit: no set named ' .. setName .. ' in ' .. editorState.document.file)
        end
    end
    editorState.selection.setName = want or (model.byName.Idle and 'Idle') or (model.list[1] and model.list[1].name)
    editorState.selection.slot = slot
    ashita.events.register('d3d_present', 'gcedit_render', render)
end

-- Only entries from the character's job picker are accepted. Parse first so a
-- missing/invalid file cannot replace the current document or its pending edits.
function gcedit.SwitchFile(target, discard, setName)
    if not editorState or editorState.ui.saving or not target then return false end
    if fileWriter.FileKey(target.path) == fileWriter.FileKey(editorState.document.path) then return false end
    local allowed
    for _, entry in ipairs(editorState.ui.jobFiles or {}) do
        if entry == target then allowed = true; break end
    end
    if not allowed then return false end
    if dirty_count() > 0 and not discard then
        editorState.ui.confirm, editorState.ui.nextFile, editorState.ui.nextSet = 'switch', target, setName
        return false
    end
    local live = fileWriter.FileKey(target.path) == fileWriter.FileKey(gProfile and gProfile.FilePath)
    local nextState = editorPreferences.New({ path = target.path, job = target.job,
        level = live and AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() or nil,
        preferences = editorPreferences.Load(target.path), fold = editorState.ui.fold })
    local model, err = load_model(nextState.document)
    if not model then
        editorState.ui.notice,
            editorState.ui.noticeBad = 'Could not open ' .. target.name .. ': ' .. tostring(err), true
        return false
    end
    nextState.document.model, nextState.document.inactive = model, not live
    nextState.document.characterFolder = editorState.document.characterFolder
    nextState.inventory, nextState.ui.jobFiles = editorState.inventory, editorState.ui.jobFiles
    nextState.cache.head = editorState.cache.head
    nextState.selection.setName = (model.byName.Idle and 'Idle') or (model.list[1] and model.list[1].name)
    if (setName ~= nil) and (model.byName[setName] ~= nil) then nextState.selection.setName = setName end
    if live and gearEngine.UnchangedExample then
        local ok, job = pcall(gearEngine.UnchangedExample)
        nextState.document.example, nextState.document.jobAbbreviation = ok and job ~= nil, job
    end
    set_state(nextState)
    regroup() -- headings by this file's job (a name both a spell and a pet's move: builtin_group)
    GcEditFold = editorState.ui.fold
    bind_actions()
    pcall(wi_from_game)
    feedback('Opened ' .. target.name .. (live and '.' or ' for editing. Active job kept loaded.'))
    return true
end

function gcedit.Reload()
    if not editorState.open then return end
    local model, err = load_model()
    if model == nil then
        editorState.ui.notice, editorState.ui.noticeBad = tostring(err), true
        return
    end
    editorState.document.model, editorState.document.edits, editorState.document.newSets, editorState.ui.notice,
        editorState.ui.confirm, editorState.document.newModes, editorState.document.deleted =
        model, {}, {}, nil, nil, {}, {}
    editorState.document.renames, editorState.document.renameRefs, editorState.document.wmOrder = {}, {}, nil
    editorState.document.jobSettings, editorState.document.convert = nil, nil
    editorState.history.entries, editorState.history.revision, editorState.cache.cover, editorState.cache.view =
        {}, nil, nil, nil
    editorState.document.revision = editorState.document.revision + 1
    editorState.ui.saving = nil
    if (editorState.selection.setName == nil) or (model.byName[editorState.selection.setName] == nil) then
        editorState.selection.setName = (model.byName.Idle and 'Idle') or (model.list[1] and model.list[1].name)
    end
    rescan()
end

-- /gcedit while open: with unsaved changes, ask in the window first.
function gcedit.RequestClose()
    if not editorState.open then return end
    if dirty_count() == 0 then
        gcedit.Close()
    else
        editorState.ui.confirm = 'close'
    end
end

-- /gcedit <set> while open: go to that set, keeping the changes.
function gcedit.Request(kind) -- the bar's '+ new mode...' / '+ add...' (gcinclude.EditorRequest), on the next frame
    if not editorState.open then return end
    if (kind == 'wm') then editorState.ui.requestNewWm = true
    elseif (kind == 'mset') then editorState.ui.requestNewMset = true
    elseif (type(kind) == 'string') and string.match(kind, '^%a+Modes$') then -- MainModes...: Settings, found
        editorState.ui.settingsOpen, editorState.ui.settingsFind = { true }, { kind }
    end
end

function gcedit.Show(setName, slot) -- slot: select it too (the /gcgear right-click)
    if (not editorState.open) or (setName == nil) then return end
    local hit = editorState.document.model.byLower[string.lower(setName)]
    if hit == nil then
        gearEngine.Say('/gcedit: no set named ' .. setName .. ' in ' .. editorState.document.file)
        return
    end
    go_to(hit.name, slot, 'action')
end

-- /gcedit last: the What goes on tab on that use of the set (a gcaction record's key: 'Weaponskill Leaden Salute').
function gcedit.PickRecord(setName, key)
    if (not editorState.open) or (setName == nil) or (key == nil) then return end
    local hit = editorState.document.model.byLower[string.lower(setName)]
    if hit == nil then return end
    editorState.cache.recKey, editorState.cache.recFor, editorState.selection.tab = key, hit.name, 'action'
end

function gcedit.Close()
    ashita.events.unregister('d3d_present', 'gcedit_render')
    set_state(nil)
end

function gcedit.IsOpen()
    return editorState.open == true
end
function gcedit.Dirty()
    return editorState.open and (dirty_count() > 0)
end

-- Compatibility hooks for existing editor tests.
gcedit._test = {
    icon = icon,
    theme_set = theme_set, theme_load = theme_load, use_theme = use_theme, palette = palette,
    theme_state = function() return themeChoice, themeTarget, themeLabel end,
    png = png,
    parse_file = setFile.Parse,
    ghosts_of = setFile.ReadCommentedSlots,
    modes_splice = setFile.AddModes,
    set_splices = setFile.AddSlotEdits,
    apply = setFile.Apply,
    item_text = setFile.FormatItem, new_set_splices = setFile.AddNewSets, expected_for = function(...)
        return actions.Expected(...)
    end, layers_of = function(...)
        return actions.Layers(...)
    end, what_if = function(...)
        return actions.Related(...)
    end, why = function(...)
        return actions.Explain(...)
    end, set_state = function(state)
        set_state(state)
        bind_actions()
    end,
}

return gcedit
