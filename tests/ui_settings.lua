-- Smoke test: the Settings panel draws every row (lists, keybinds, Packer, job options) against a stub ImGui on each
-- target, without errors and without drawing an ID twice in a frame.
local drawn, twice = {}, nil
local clicks = {}
local imgui = setmetatable({}, { __index = function(_, k)
    if (k == 'CalcTextSize') or (k == 'GetContentRegionAvail') then return function() return 100, 20 end end
    if (k == 'SmallButton') or (k == 'Button') or (k == 'Selectable') then
        return function(label)
            if drawn[label] and (twice == nil) then twice = label end
            drawn[label] = true
            if clicks[label] then clicks[label] = nil; return true end
            return false
        end
    end
    if k == 'BeginPopup' then return function() return true end end
    return function() return false end
end })
ImGuiCol_Text, ImGuiCol_Button, ImGuiCol_ButtonHovered, ImGuiCol_ButtonActive = 0, 1, 2, 3
gState = { PlayerName = 'Jirachi', PlayerId = 1 }
AshitaCore = setmetatable({}, { __index = function() return function() return nil end end })
gcinclude = { PackerReady = function() return false, 'the Packer plugin is not loaded' end }
local function eq(a, b, what) if a ~= b then error((what or '') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b), 2) end end
local palette = setmetatable({}, { __index = function() return { 1, 1, 1, 1 } end })
local F = gFunc.LoadFile('common\\gcsetfile.lua')
local G = gFunc.LoadFile('common\\gceditgroups.lua')
local REMOVE = {}
local layers = { own = { HUDOwners = { 'Jirachi' }, PackerItems = { ['Echo Drops'] = 'stack' } }, shared = {} }
local tops = { own = { Packer = { ['Echo Drops'] = 'stack' } }, shared = {} }
local staged = {}
local files = {
    REMOVE = REMOVE,
    Defaults = function() return { SIRSkip = { 'Absorb-TP', 'Stun' }, Keybinds = { { 'F7', 'wm' }, { '^!@F12', 'reload' } },
        HUDAbbr = {}, EnchantDelays = {}, DTGearHPP = 50, Messages = false, Theme = false, ElementGear = { AnyObi = 'x' } } end,
    Layer = function(w) return layers[w] or {} end,
    Get = function(k)
        if layers.own[k] ~= nil then return layers.own[k], 'own' end
        return ({ SIRSkip = { 'Absorb-TP', 'Stun' }, Keybinds = { { 'F7', 'wm' } }, DTGearHPP = 50 })[k], 'default'
    end,
    Job = function(name) local st = staged[name]; if st then return st.value, 'staged' end; return nil, 'none' end,
    JobInFile = function() return nil, 'none' end,
    GetForJob = function(k) return nil, 'default' end,
    JobFile = function() return 'WHM.lua' end,
    Path = function(w) return 'C:\\' .. w .. '.lua' end,
    Top = function(w, k) return (tops[w] or {})[k] end,
    StageJob = function(name, v) staged[name] = { value = v } end,
    Write = function() return true end, WriteTop = function() return true end,
}
local state = { ui = {} }
local P = gFunc.LoadFile('common\\gceditsettingsui.lua')(imgui, palette, function() end, files, G, F, state, function() end)
local function frame()
    drawn, twice = {}, nil
    P.Body()
    if twice ~= nil then error('drawn twice in one frame: ' .. twice, 2) end
end
return {
    { 'every target draws', function()
        for _, t in ipairs({ 'own', 'shared', 'job' }) do
            state.ui.settingsTarget = t
            state.ui.settingsAll = { true }
            frame()
        end
    end },
    { 'targets name the character and the job', function()
        state.ui.settingsTarget = 'own'
        frame()
        eq(drawn['Jirachi: every job (char.lua)##set_target_own'], true)
        eq(drawn['Jirachi: WHM only (WHM.lua)##set_target_job'], true)
    end },
}
