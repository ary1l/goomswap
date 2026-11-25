local P = gFunc.LoadFile('common\\gcpackerlist.lua')
local function eq(a, b, what) if a ~= b then error((what or '') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b), 2) end end
local function find(list, name)
    for _, e in ipairs(list) do
        local n = (type(e) == 'table') and e.Name or e
        if n == name then return e end
    end
end
return {
    { 'file entries kept as they are, map counts converted', function()
        local out = P.Build({ file = { 'Echo Drops', { Name = 'Thr. Tomahawk', Quantity = 'all' } } })
        eq(out[1], 'Echo Drops'); eq(out[2].Quantity, 'all')
    end },
    { 'char map: stack -> stack size, all kept, false and 0 dropped', function()
        local out = P.Build({ char = { ['Grape Daifuku +1'] = 'stack', ['Holy Water'] = 'all', ['Remedy'] = false,
            ['Echo Drops'] = 0, ['Panacea'] = 3.7 }, stackOf = function() return 12 end })
        eq(find(out, 'Grape Daifuku +1').Quantity, 12); eq(find(out, 'Holy Water').Quantity, 'all')
        eq(find(out, 'Remedy'), nil); eq(find(out, 'Echo Drops'), nil); eq(find(out, 'Panacea').Quantity, 3)
    end },
    { 'nested buff sets added, top-level slots left to LAC', function()
        local sets = { Idle = { Head = 'Nyame Helm' }, Buffs = { ['Aftermath: Lv.3'] = { Ring1 = 'Chirich Ring +1',
            Ring2 = 'Chirich Ring +1', Ear1 = 'remove' } } }
        local out = P.Build({ sets = sets })
        eq(find(out, 'Nyame Helm'), nil, 'top level'); eq(find(out, 'Chirich Ring +1').Quantity, 2, 'two rings')
        eq(find(out, 'remove'), nil, 'slot word')
    end },
    { 'engine sets: own slots and nested', function()
        local out = P.Build({ engineSets = { Doomed = { Waist = { Name = 'Gishdubar Sash', AugPath = 'A' } } } })
        local e = find(out, 'Gishdubar Sash'); eq(e.AugPath, 'A'); eq(e.Quantity, nil)
    end },
    { 'engine sets: only the pieces you own', function()
        local out = P.Build({ engineSets = { Doomed = { Ring1 = 'Purity Ring', Waist = 'Gishdubar Sash' } },
            owns = function(n) return n == 'Gishdubar Sash' end })
        eq(#out, 1); eq(out[1].Name, 'Gishdubar Sash')
    end },
    { 'engine items only when owned, once each', function()
        local items = P.Names({ 'Warp Ring', { Dark = 'Anrin Obi' }, 'Warp Ring', { ['Sparrowhawk +2'] = 'Chrono Arrow' } })
        local out = P.Build({ items = items, owns = function(n) return n ~= 'Anrin Obi' end })
        eq(#out, 2); eq(find(out, 'Anrin Obi'), nil); eq(find(out, 'Sparrowhawk +2'), nil, 'keys left out')
    end },
}
