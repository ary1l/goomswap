-- The whole editor drawn frame by frame (tests/draw_editor.lua, its own process): every view, with the argument types
-- Ashita's ImGui binding takes, on a few job files. A draw error or a wrong argument type fails here, not in game.
local CLICKS = 'item3,#gcedit_tab_gear,pick2,#gcedit_tab_action,Undo edit##gcedit,Redo##gcedit_redo,#gcedit_tab_summary,'
    .. '#gcedit_tab_over,#gcedit_tab_fill,gcedit_rules_top,rules_add,rb_more,rv_code,x,x,x,x,x,x,conv_go,rv_all,rule_edit_1,'
    .. 'rv_stays,gcsettings,set_cat_Keys,set_cat_Items & Packer,set_target_job'
local function draw(file, hover)
    local p = io.popen((hover and 'HOVER=1 ' or '') .. 'luajit tests/draw_editor.lua ' .. file .. ' "' .. CLICKS .. '" 2>&1')
    local out = p:read('*a')
    p:close()
    local last = string.match(out, '([^\n]*)\n?$')
    assert(last == 'drawn', file .. (hover and ' (hovered)' or '') .. ': ' .. out)
end
local tests = {}
for _, f in ipairs({ 'examples/WHM.lua', 'examples/COR.lua', 'examples/PUP.lua', 'tests/fixtures/BLM.lua' }) do
    tests[#tests + 1] = { 'the editor draws ' .. f, function() draw(f, false); draw(f, true) end }
end
tests[#tests + 1] = { 'the Editor menu draws, its Spacing switch switches', function()
    local p = io.popen('POPUP="##gcedit_tools" luajit tests/draw_editor.lua examples/BLU.lua "x,gct_dens_2,x,gct_dens_1,x" "^Comfortable:" 2>&1')
    local out = p:read('*a')
    p:close()
    assert(string.match(out, '([^\n]*)\n?$') == 'drawn', out)
    assert(string.find(out, '\n  Comfortable:', 1, true), 'Spacing switch to Comfortable not shown: ' .. out)
end }
return tests
