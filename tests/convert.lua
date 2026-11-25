local C = gFunc.LoadFile('common\\gcconvert.lua')
local F = gFunc.LoadFile('common\\gcsetfile.lua')
local R = gFunc.LoadFile('common\\gcrules.lua')
local function eq(a, b, what) if a ~= b then error((what or '') .. ':\n' .. tostring(a) .. '\n~=\n' .. tostring(b), 2) end end
local LAC = [[
local profile = {};
local sets = {
    Idle = { Head = 'Nyame Helm' },
    Fealty = { Body = 'Cab. Surcoat +1' },
    Cure = { Hands = 'Macabre Gaunt. +1' },
};
profile.Sets = sets;
profile.OnLoad = function()
    gSettings.AllowAddSet = true;
end
profile.HandleCommand = function(args)
end
profile.HandleDefault = function()
    gFunc.EquipSet(sets.Idle);
    if (gData.GetBuffCount('Cover') > 0) then gFunc.EquipSet(sets.Fealty) end
end
profile.HandleMidcast = function()
    local spell = gData.GetAction();
    if string.contains(spell.Name, 'Cure') then
        gFunc.EquipSet(sets.Cure);
    end
end
return profile;
]]
return {
    { 'plain LAC: plan converts both ifs', function()
        local plan = assert(C.Plan(LAC))
        eq(#plan.rules, 2)
        eq(R.Words(plan.rules[1]), 'buff Cover -> Fealty (only)')
        eq(R.Words(plan.rules[2]), 'name has "Cure" -> Cure (only)')
        local out = F.Apply(LAC, plan.splices)
        eq(string.find(out, 'Cover', 1, true), nil, 'if taken out')
        eq(loadstring(out) ~= nil, true, 'parses')
    end },
    { 'adopt: loads GoomSwap, keeps its own code, parses', function()
        local a = assert(C.Adopt(LAC))
        local out = F.Apply(LAC, a.splices)
        eq(loadstring(out) ~= nil, true, 'parses')
        eq(string.find(out, "gcinclude = gFunc.LoadFile('common\\\\gcinclude.lua');", 1, true) ~= nil, true, 'load line')
        eq(string.find(out, "    gSettings.AllowAddSet = true;\n    gcinclude.Initialize();\nend", 1, true) ~= nil, true, 'init')
        eq(string.find(out, "profile.HandleCommand = function(args)\n    gcinclude.HandleCommands(args);\nend", 1, true) ~= nil, true, 'cmd')
        eq(string.find(out, "gcinclude.Unload();", 1, true) ~= nil, true, 'unload added')
        eq(C.Adopt(out), nil, 'once')
        -- adopt and convert together
        local plan = assert(C.Plan(LAC))
        local both = {}
        for _, sp in ipairs(a.splices) do both[#both + 1] = sp end
        for _, sp in ipairs(plan.splices) do both[#both + 1] = sp end
        local out2 = F.Apply(LAC, both)
        eq(loadstring(out2) ~= nil, true, 'both parse')
    end },
    { 'spot: an if before more equips stays in place as gcinclude.RulesAt', function()
        local text = [[
local profile = {};
profile.HandleMidcast = function()
    local spell = gData.GetAction();
    if (spell.Skill == 'Healing Magic') then gFunc.EquipSet(sets.Heal) end
    gcinclude.ByName(spell.Name);
end
return profile;
]]
        local plan = assert(C.Plan(text))
        eq(plan.rules[1].at, 'Midcast 1')
        local out = F.Apply(text, plan.splices)
        eq(string.find(out, "    gcinclude.RulesAt('Midcast 1');\n    gcinclude.ByName(spell.Name);", 1, true) ~= nil, true, out)
    end },
    { 'stays code, with why', function()
        local text = [[
local profile = {};
profile.HandleMidcast = function()
    local spell = gData.GetAction();
    if (spell.Name:upper() == 'CURE') then gFunc.EquipSet(sets.Heal) end
    if MyThing() then gFunc.EquipSet(sets.X) end
end
return profile;
]]
        local plan = assert(C.Plan(text))
        eq(#plan.rules, 0)
        eq(plan.handlers[1].items[1].ok, false)
        eq(plan.handlers[1].items[2].why, 'calls MyThing')
    end },
    { 'elseif chains: exclusive skills, else, groups', function()
        local text = [[
local profile = {};
profile.HandleMidcast = function()
    local spell = gData.GetAction();
    if (spell.Skill == 'Healing Magic') then
        gFunc.EquipSet(sets.Heal)
    elseif (spell.Skill == 'Dark Magic') then
        gFunc.EquipSet(sets.Dark)
        if (gData.GetPlayer().MPP < 50) then gFunc.EquipSet(sets.Low) end
    else
        gFunc.EquipSet(sets.Other)
    end
    if gcdisplay.GetToggle('DTset') then gFunc.EquipSet(sets.A) elseif (gData.GetPlayer().HPP < 50) then gFunc.EquipSet(sets.B) end
end
return profile;
]]
        local plan = assert(C.Plan(text))
        local words = {}
        for _, r in ipairs(plan.rules) do words[#words + 1] = R.Words(r) end
        eq(table.concat(words, ' | '), 'skill Healing Magic -> Heal (only) | skill Dark Magic -> Dark (only) | '
            .. 'mpp < 50, skill Dark Magic -> Low (only) | skill is not "Dark Magic or Healing Magic" -> Other (only) | '
            .. 'first of: 1) toggle dt true -> A (only); 2) hpp < 50 -> B (only)')
    end },
}
