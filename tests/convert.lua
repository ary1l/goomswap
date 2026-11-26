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
        eq(string.find(plan.handlers[1].items[2].why, 'asks MyThing()', 1, true) ~= nil, true, plan.handlers[1].items[2].why)
    end },
    { 'a set lookup in a check: the lookup stays, the rest becomes a rule', function()
        local text = [[
local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
local ByName = gcinclude.ByName;
local Family = gcinclude.Family;
profile.HandleMidcast = function()
    local spell = gData.GetAction();
    if not (ByName(spell.Name) or ByName(Family(spell.Name))) then gFunc.EquipSet(sets.Enmity) end
end
return profile;
]]
        local plan = assert(C.Plan(text))
        eq(#plan.rules, 1)
        local r = plan.rules[1]
        eq(r.wear, 'Enmity'); eq(r.when.nameset, false); eq(r.when.familyset, false)
        local out = F.Apply(text, plan.splices)
        eq(string.find(out, 'if not ByName(spell.Name) then ByName(Family(spell.Name)) end', 1, true) ~= nil, true, out)
        eq(string.find(out, 'sets.Enmity', 1, true), nil, out)
        eq(string.find(out, 'local spell = gData.GetAction();', 1, true) ~= nil, true, 'its local stays: ' .. out)
    end },
    { 'a set lookup mixed with other checks stays code', function()
        local text = [[
local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
local ByName = gcinclude.ByName;
profile.HandleMidcast = function()
    local spell = gData.GetAction();
    if not ByName(spell.Name) and (gData.GetPlayer().MPP < 50) then gFunc.EquipSet(sets.Enmity) end
end
return profile;
]]
        local plan = assert(C.Plan(text))
        eq(#plan.rules, 0)
        eq(string.find(plan.handlers[1].items[1].why, 'mixes a set lookup', 1, true) ~= nil, true, plan.handlers[1].items[1].why)
    end },
    { 'zone from Ashita, GoomSwap spell lists, a set picked by a check, a Lua pattern', function()
        local text = [[
local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
profile.HandleDefault = function()
    local area = AshitaCore:GetResourceManager():GetString('zones.names', AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0));
    if (area ~= nil) and area:contains('Remnants') then
        gFunc.EquipSet(sets.Salvage);
    end
    gcinclude.CheckDefault();
end
profile.HandleMidcast = function()
    local spell = gData.GetAction();
    if (spell.Skill == 'Blue Magic') then gFunc.EquipSet(gcinclude.BluMagPhysical:contains(spell.Name) and sets.BluPhysical or sets.BluMagical) end
    if string.match(spell.Name, 'Evryone. Grudge') then gFunc.EquipSet(sets.BluDark) end
end
return profile;
]]
        local plan = assert(C.Plan(text))
        eq(#plan.rules, 4)
        eq(plan.rules[1].when.zone.has, 'Remnants'); eq(plan.rules[1].wear, 'Salvage')
        eq(plan.rules[2].when.inlist, 'BluMagPhysical'); eq(plan.rules[2].wear, 'BluPhysical')
        eq(plan.rules[3].when.inlist.isnt, 'BluMagPhysical'); eq(plan.rules[3].wear, 'BluMagical')
        eq(plan.rules[4].when.name.pattern, 'Evryone. Grudge')
        local out = F.Apply(text, plan.splices)
        eq(string.find(out, 'local area', 1, true), nil, 'the zone local goes with its if: ' .. out)
        -- a whole-zone-name compare stays code (Ashita's raw name vs the trimmed one rules read)
        local t2 = string.gsub(text, "area:contains%('Remnants'%)", "(area == 'Remnants')")
        local p2 = assert(C.Plan(t2))
        eq(p2.handlers[1].items[1].ok, false)
    end },
    { 'a /wm weapon pick converts; another cycle in IsWeaponValue stays code', function()
        local text = [[
local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
profile.HandleDefault = function()
    local player = gData.GetPlayer();
    if (player.Status == 'Engaged') and (not gcinclude.IsWeaponValue(gcdisplay.GetCycle('Weapons'))) and (not gcinclude.CanDualWield()) then
        gFunc.Equip('Sub', 'Genmei Shield');
    end
    if gcinclude.IsWeaponValue(gcdisplay.GetCycle('MeleeSet')) then gFunc.Equip('Ammo', 'Coiste Bodhar') end
    gcinclude.CheckDefault();
end
return profile;
]]
        local plan = assert(C.Plan(text))
        eq(#plan.rules, 1)
        local w = plan.rules[1].when
        eq(w.wmpick, false); eq(w.dualwield, false); eq(w.status, 'Engaged')
        eq(plan.rules[1].item.Sub, 'Genmei Shield')
        eq(R.Say(plan.rules[1]), 'While fighting, when you cannot dual wield and no /wm weapon is picked: put Genmei Shield in Sub')
        eq(plan.handlers[1].items[2].ok, false)
        -- the rule reads the pick the same way the code did
        local pick
        local api = { player = function() return { Status = 'Engaged' } end, dualWield = function() return false end,
            weaponPick = function() return pick end }
        for _, v in ipairs({ true, false }) do
            pick = v
            eq(R.Holds(plan.rules[1], 'Default', api) == true, not v)
        end
    end },
    { 'a set name put together while it runs, or a set inside a table, says so (whatever the condition)', function()
        local text = [[
local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
profile.HandleWeaponskill = function()
    local ws = gData.GetAction();
    local suffix = (gcinclude.BuffCount('Sneak Attack') > 0) and 'SA' or nil;
    if (suffix ~= nil) then
        local set = gcinclude.FindSet(ws.Name .. '_' .. suffix);
        if (set ~= nil) then gFunc.EquipSet(set) end
    end
    if (ws.Name == 'Asuran Fists') then gFunc.EquipSet(sets.Buffs.Boost) end
end
return profile;
]]
        local items = assert(C.Plan(text)).handlers[1].items
        eq(string.find(items[1].why, 'put together while it runs', 1, true) ~= nil, true, items[1].why)
        eq(string.find(items[2].why, 'sets.Buffs.Boost, a set inside another table', 1, true) ~= nil, true, items[2].why)
    end },
    { 'a branch that is not gear says so plainly', function()
        local text = [[
local profile = {};
gcinclude = gFunc.LoadFile('common\\gcinclude.lua');
profile.HandleAbility = function()
    local ability = gData.GetAction();
    local roll = (string.find(ability.Name, 'Roll', 1, true) ~= nil);
    if roll then gcinclude.DoCORmsg(ability.Name) end
    if (ability.Name == 'Wild Card') then gcinclude.Mystery(ability.Name) end
end
return profile;
]]
        local plan = assert(C.Plan(text))
        local a, b = plan.handlers[1].items[1].why, plan.handlers[1].items[2].why
        eq(string.find(a, "Not gear: it prints the roll's lucky and unlucky numbers to chat", 1, true) ~= nil, true, a)
        eq(string.find(b, 'It runs gcinclude.Mystery(), which does more than put on gear', 1, true) ~= nil, true, b)
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
            .. 'first of: 1) /dt on -> A (only); 2) hpp < 50 -> B (only)')
    end },
}
