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
for _, f in ipairs({ 'examples/WHM.lua', 'examples/COR.lua', 'examples/PUP.lua', 'tests/fixtures/SCH.lua' }) do
    tests[#tests + 1] = { 'the editor draws ' .. f, function() draw(f, false); draw(f, true) end }
end
tests[#tests + 1] = { 'the Editor menu draws, its Spacing switch switches', function()
    local p = io.popen('POPUP="##gcedit_tools" luajit tests/draw_editor.lua examples/BLU.lua "x,gct_dens_2,x,gct_dens_1,x" "^Comfortable:" 2>&1')
    local out = p:read('*a')
    p:close()
    assert(string.match(out, '([^\n]*)\n?$') == 'drawn', out)
    assert(string.find(out, '\n  Comfortable:', 1, true), 'Spacing switch to Comfortable not shown: ' .. out)
end }
tests[#tests + 1] = { 'To fill: a slot opens its picker with a way back, and a pick goes back to the list', function()
    local function run(clicks, probe)
        local p = io.popen('luajit tests/draw_editor.lua examples/DNC.lua "' .. clicks .. '" "' .. probe .. '" 2>&1')
        local out = p:read('*a')
        p:close()
        assert(string.match(out, '([^\n]*)\n?$') == 'drawn', out)
        return out
    end
    local out = run('#gcedit_tab_fill,x,gcf_notOwnedIdleHead,x', 'backfill')
    assert(string.find(out, '< To fill (', 1, true), 'no way back to To fill: ' .. out)
    -- after the pick, To fill's list is up again (its first line is seen anew only if it was drawn after the pick)
    local p = io.popen('TRACE="What still needs gear, in every set." luajit tests/draw_editor.lua examples/DNC.lua '
        .. '"#gcedit_tab_fill,x,gcf_notOwnedIdleHead,x,pick1,x" "zzz" 2>&1')
    local trace = p:read('*a')
    p:close()
    assert(string.find(trace, 'pick1\tseen', 1, true), 'To fill not back after the pick: ' .. trace)
end }
tests[#tests + 1] = { 'a Weapon_ set: armor in it, or a set /wm never reaches, is said with its fix', function()
    local text = io.open('examples/DNC.lua'):read('*a')
    text = string.gsub(text, '    Tp_Acc = {', "    Weapon_Mpu = { Main = 'Mpu Gandring', Head = 'Nyame Helm' },\n"
        .. "    Weapon_MpuTP = { Main = 'Mpu Gandring' },\n    Tp_Acc = {", 1)
    text = string.gsub(text, "gcinclude.WeaponModes = %b{}", "gcinclude.WeaponModes = {'None', 'Mpu'}", 1)
    local path = os.tmpname()
    local fh = io.open(path, 'w')
    fh:write(text)
    fh:close()
    local function run(set, clicks, probe)
        local p = io.popen('OPENSET=' .. set .. ' luajit tests/draw_editor.lua ' .. path .. ' "' .. clicks .. '" "' .. probe
            .. '" 2>&1')
        local out = p:read('*a')
        p:close()
        assert(string.match(out, '([^\n]*)\n?$') == 'drawn', out)
        return out
    end
    local ok1 = string.find(run('Weapon_Mpu', 'x', 'never worn'), 'Head: never worn', 1, true)
    local ok2 = string.find(run('Weapon_Mpu', 'x', 'Move to'), 'Move to Tp_Mpu', 1, true)
    local ok3 = string.find(run('Weapon_MpuTP', 'x', 'Never worn'), '/wm has no MpuTP mode', 1, true)
    local ok4 = string.find(run('Weapon_MpuTP', 'x', 'Add /wm'), 'Add /wm MpuTP', 1, true)
    local ok5 = string.find(run('Weapon_MpuTP', 'x', 'Weapons only'), 'Weapons only.', 1, true) -- its weapon row alone
    local p = io.popen('POPUP="##gcedit_newwm" luajit tests/draw_editor.lua ' .. path .. ' "gch_Weapons,x" "New weapon mode" 2>&1')
    local out = p:read('*a')
    p:close()
    local ok6 = string.find(out, 'New weapon mode (/wm)', 1, true) and (string.match(out, '([^\n]*)\n?$') == 'drawn')
    os.remove(path)
    assert(ok1 and ok2 and ok3 and ok4 and ok5 and ok6, 'Weapon_ set checks missing: ' .. tostring(ok1) .. tostring(ok2)
        .. tostring(ok3) .. tostring(ok4) .. tostring(ok5) .. tostring(ok6) .. '\n' .. out)
end }
tests[#tests + 1] = { "a heading's '+ N to add' lists the sets a job file usually has and makes one", function()
    local function run(clicks, probe)
        local p = io.popen('POPUP="##gcedit_addable" luajit tests/draw_editor.lua examples/DNC.lua "' .. clicks .. '" "'
            .. probe .. '" 2>&1')
        local out = p:read('*a')
        p:close()
        assert(string.match(out, '([^\n]*)\n?$') == 'drawn', out)
        return out
    end
    assert(string.find(run('x', 'to add'), 'to add##gcadd_Idle', 1, true), 'no + to add under IDLE')
    local list = run('gcadd_Idle,x', 'Idle_Regain')
    assert(string.find(list, '\n  Idle_Regain\n', 1, true), 'Idle_Regain not offered: ' .. list)
    local made = run('gcadd_Idle,x,gcadd_mk2,x', 'gcs_Idle_Regain')
    assert(string.find(made, 'Idle_Regain (new)##gcs_Idle_Regain', 1, true), 'Make did not add it: ' .. made)
end }
return tests
