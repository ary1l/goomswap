-- Smoke test: the Rules page and the Settings widgets draw without errors against a stub ImGui, and the
-- builder's Save stages the rule it shows. Clicks are scripted by label.
local clicks = {}
local imgui = setmetatable({}, { __index = function(_, k)
    if (k == 'CalcTextSize') or (k == 'GetContentRegionAvail') then return function() return 100, 20 end end
    if (k == 'SmallButton') or (k == 'Button') or (k == 'Selectable') then
        return function(label) if clicks[label] then clicks[label] = nil; return true end return false end
    end
    if (k == 'BeginPopup') then return function() return true end end
    return function() return false end
end })
ImGuiCol_Text = 0
local function eq(a, b, what) if a ~= b then error((what or '') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b), 2) end end
local palette = setmetatable({}, { __index = function() return { 1, 1, 1, 1 } end })
local staged, fileValue = {}, nil
local REMOVE = {}
local files = {
    REMOVE = REMOVE,
    Job = function(name)
        local st = staged[name]
        if st ~= nil then
            if st.remove then return nil, 'staged' end
            return st.value, 'staged'
        end
        return fileValue, (fileValue ~= nil) and 'file' or 'none'
    end,
    StageJob = function(name, v, t, text)
        staged[name] = (v == REMOVE) and { remove = true } or { value = v, text = text }
    end,
}
local F = gFunc.LoadFile('common\\gcsetfile.lua')
local state = { selection = {}, ui = {}, document = { model = { list = { { name = 'Fealty' } }, byName = { Fealty = {} } } } }
local msg = nil
local M = gFunc.LoadFile('common\\gceditrules.lua')({ imgui = imgui, palette = palette, set_tip = function() end,
    editorState = state, files = files, setFile = F, feedback = function(t) msg = t end, ctx = {} })
return {
    { 'empty page, list row, builder, save a rule', function()
        M.ListButton(); M.Draw()
        clicks['+ Rule##rules_add'] = true
        M.Draw()
        local e = state.ui.ruleEdit
        eq(e ~= nil, true, 'builder open')
        e.phase = 'Default'
        e.rows[1] = { key = 'buff', op = 'is', buf = { 'Cover' } }
        e.wear[1] = 'Fealty'
        M.Draw()
        clicks['Save rule##rb_save'] = true
        M.Draw()
        eq(state.ui.ruleEdit, nil, 'builder closed')
        local v = staged.Rules.value
        eq(#v, 1); eq(v[1].on, 'Default'); eq(v[1].when.buff, 'Cover'); eq(v[1].wear, 'Fealty')
        eq(staged.Rules.text(v, ''), "{\n    { on = 'Default', when = { buff = 'Cover' }, wear = 'Fealty' },\n}")
    end },
    { 'edit, group rows, delete', function()
        fileValue = { { on = 'Midcast', first = { { when = { skill = 'Healing Magic' }, wear = 'Heal' }, { wear = 'Other' } } },
            { on = 'Precast', when = { mpp = { lt = 10 } }, stop = true, note = 'no MP' } }
        staged = {}
        M.Draw()
        clicks['Edit##rule_edit_1_1'] = true
        M.Draw()
        local e = state.ui.ruleEdit
        eq(e.member, 1); eq(e.rows[1].key, 'skill')
        e.rows[1].buf[1] = 'Healing Magic, Divine Magic'
        clicks['Save rule##rb_save'] = true
        M.Draw()
        local v = staged.Rules.value
        eq(v[1].first[1].when.skill[2], 'Divine Magic'); eq(v[1].first[1].on, nil, 'a choice has no phase')
        eq(v[1].on, 'Midcast')
        clicks['x##rule_del_2'] = true
        M.Draw()
        eq(#staged.Rules.value, 1)
        clicks['x##rule_delg_1'] = true
        M.Draw()
        eq(staged.Rules.remove, true, 'none left: the line goes')
    end },
    { 'settings widgets draw', function()
        local W = gFunc.LoadFile('common\\gceditwidgets.lua')(imgui, palette, function() end)
        eq(W.List('a', { 'Stun' }), nil)
        clicks['Stun  x##a_1'] = true
        eq(#W.List('a', { 'Stun', 'Absorb-TP' }), 1)
        eq(W.Map('m', { Carnwenhan = 'carn' }), nil)
        clicks['x##k_x1'] = true
        eq(#W.Keybinds('k', { { 'F7', 'wm' }, { '^F1', '/ja "Provoke" <t>' } }), 1)
        eq(W.KeyText('^!F1'), 'Ctrl+Alt+F1')
        local rows = W.PackerRows({ 'Echo Drops', { Name = 'Trump Card', Quantity = 99 }, ['Holy Water'] = 'stack' })
        eq(#rows, 3)
        local v = W.PackerValue(rows, 'list', function() return 12 end)
        eq(v[1], 'Echo Drops'); eq(v[2].Quantity, 12); eq(v[3].Quantity, 99)
    end },
}
