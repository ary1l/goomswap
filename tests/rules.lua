local R = gFunc.LoadFile('common\\gcrules.lua')
local function eq(a, b, what) if a ~= b then error((what or '') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b), 2) end end
-- A fake game: what each api read returns, and what the rules wore.
local function game(t)
    local worn, api = {}, {}
    for _, k in ipairs({ 'player', 'action', 'target', 'env', 'pet', 'petAction', 'me' }) do
        api[k] = function() return t[k] end
    end
    api.buff = function(b) return (t.buffs or {})[b] or 0 end
    api.cycle = function(n) return (t.cycles or {})[n] end
    api.toggle = function(n) return (t.toggles or {})[n] == true end
    api.burst = function() return t.burst == true end
    api.family = function(n) return (string.gsub(n, ' [IV]+$', '')) end
    api.wear = function(name, exact) worn[#worn + 1] = name .. (exact and '!' or '') end
    api.equip = function(slot, item) worn[#worn + 1] = slot .. '=' .. item end
    api.cancel = function() worn[#worn + 1] = 'STOP' end
    return api, worn
end
local function run(rules, phase, layer, t)
    local c, problems = R.Compile(rules)
    if #problems > 0 then error(problems[1], 2) end
    local api, worn = game(t)
    local stopped = R.Run(c, phase, layer or 'job', api)
    return table.concat(worn, ','), stopped
end
return {
    { 'text matching', function()
        eq(R.MatchText('Cure IV', 'Cure IV'), true); eq(R.MatchText('Cure IV', 'cure iv'), false)
        eq(R.MatchText('Cure IV', { 'Cure', 'Cure IV' }), true)
        eq(R.MatchText('Pyrohelix II', { has = 'helix' }), true); eq(R.MatchText('Helix', { has = 'helix' }), false)
        eq(R.MatchText('Cure IV', { start = 'Cur', isnt = 'Cure' }), true)
        eq(R.MatchText(nil, { has = 'x' }), false); eq(R.MatchText('Stun', { ends = { 'un', 'zz' } }), true)
    end },
    { 'numbers', function()
        eq(R.MatchNumber(40, { le = 40 }), true); eq(R.MatchNumber(41, { le = 40 }), false)
        eq(R.MatchNumber(50, { ge = 25, lt = 75 }), true); eq(R.MatchNumber(nil, { lt = 1 }), false)
    end },
    { 'midcast: nested condition (skill and MP), target me', function()
        local rules = {
            { on = 'Midcast', when = { skill = 'Elemental Magic', mpp = { le = 40 } }, wear = 'Mp_Body', exact = true },
            { on = 'Midcast', when = { skill = 'Healing Magic', target = 'me' }, wear = 'Self_Cure' },
        }
        local t = { player = { MPP = 30 }, action = { Name = 'Fire', Skill = 'Elemental Magic' }, target = { Name = 'Me' }, me = 'Me' }
        eq(run(rules, 'Midcast', 'job', t), 'Mp_Body!')
        t.action = { Name = 'Cure IV', Skill = 'Healing Magic' }
        eq(run(rules, 'Midcast', 'job', t), 'Self_Cure')
        t.target = { Name = 'Other' }
        eq(run(rules, 'Midcast', 'job', t), '')
    end },
    { 'first: only the first match of a group', function()
        local rules = { { on = 'Midcast', first = {
            { when = { name = { has = 'storm' } }, wear = 'Storm' },
            { when = { skill = 'Enhancing Magic' }, wear = 'Enh' } } } }
        eq(run(rules, 'Midcast', 'job', { action = { Name = 'Hailstorm', Skill = 'Enhancing Magic' } }), 'Storm')
        eq(run(rules, 'Midcast', 'job', { action = { Name = 'Haste', Skill = 'Enhancing Magic' } }), 'Enh')
    end },
    { 'any, buffs, modes, toggles, element = weather', function()
        local rules = {
            { on = 'Default', when = { any = { { buff = 'Cover' }, { toggle = { dt = true } } } }, wear = 'Fealty' },
            { on = 'Default', when = { mode = { nukeset = 'Macc' }, nobuff = { 'Sleep' } }, wear = 'Macc' },
            { on = 'Default', when = { allbuffs = { 'Ebullience', 'Rapture' } }, wear = 'Both' },
        }
        eq(run(rules, 'Default', 'job', { buffs = { Cover = 1 } }), 'Fealty')
        eq(run(rules, 'Default', 'job', { toggles = { DTset = true }, cycles = { NukeSet = 'Macc' } }), 'Fealty,Macc')
        eq(run(rules, 'Default', 'job', { buffs = { Ebullience = 1 } }), '')
        eq(run(rules, 'Default', 'job', { buffs = { Ebullience = 1, Rapture = 1 } }), 'Both')
        local k = { { on = 'Midcast', when = { buff = 'Klimaform', element = 'weather' }, wear = 'Klimaform' } }
        eq(run(k, 'Midcast', 'job', { buffs = { Klimaform = 1 }, action = { Element = 'Ice' }, env = { WeatherElement = 'Ice' } }), 'Klimaform')
        eq(run(k, 'Midcast', 'job', { buffs = { Klimaform = 1 }, action = { Element = 'Fire' }, env = { WeatherElement = 'Ice' } }), '')
    end },
    { 'layers, items, stop, off', function()
        local rules = {
            { on = 'Precast', when = { name = 'Stun' }, wear = 'FC' },
            { on = 'Precast', layer = 'top', when = { name = 'Stun' }, item = { Head = 'Nyame Helm' } },
            { on = 'Precast', when = { mpp = { lt = 10 } }, stop = true },
            { on = 'Precast', when = { name = 'Stun' }, wear = 'Never', off = true },
            { on = 'Precast', when = { name = 'Stun' }, wear = 'After' },
        }
        eq(run(rules, 'Precast', 'job', { action = { Name = 'Stun' }, player = { MPP = 50 } }), 'FC,After')
        eq(run(rules, 'Precast', 'top', { action = { Name = 'Stun' } }), 'Head=Nyame Helm')
        local worn, stopped = run(rules, 'Precast', 'job', { action = { Name = 'Stun' }, player = { MPP = 5 } })
        eq(worn, 'FC,STOP'); eq(stopped, true)
    end },
    { 'pet phase reads the pet action', function()
        local rules = { { on = 'Pet', when = { name = { has = 'Flaming' } }, wear = 'BP_Rage' } }
        eq(run(rules, 'Pet', 'job', { petAction = { Name = 'Flaming Crush' }, action = { Name = 'Cure' } }), 'BP_Rage')
    end },
    { 'problems: unknown key, stop on midcast, bad phase', function()
        local _, p = R.Compile({ { on = 'Midcast', when = { colour = 'red' }, wear = 'X' },
            { on = 'Midcast', stop = true }, { on = 'Later', wear = 'X' }, { on = 'Default', when = { buff = 'Haste' } } })
        eq(#p, 4)
        eq(string.find(p[1], 'colour', 1, true) ~= nil, true)
    end },
    { 'rows: a when to rows and back', function()
        local function same(a, b) return R.Inline(a, function(x) return "'" .. x .. "'" end, function(k) return k end)
            == R.Inline(b, function(x) return "'" .. x .. "'" end, function(k) return k end) end
        for _, w in ipairs({
            { skill = 'Healing Magic', target = 'me' },
            { name = { has = 'helix', isnt = 'Helix' }, mpp = { le = 40, gt = 5 } },
            { name = { 'Cure', 'Cura' }, buff = { 'Haste', 'Flurry' }, moving = true },
            { mode = { wm = 'Naegling', mset = { 'Acc', 'SubtleBlow' } }, toggle = { dt = true } },
        }) do
            local rows, any = R.WhenToRows(w)
            eq(any, false); eq(same(R.RowsToWhen(rows, any), w), true, R.Inline(w, tostring, tostring))
        end
        local w = { any = { { buff = 'Cover' }, { hpp = { lt = 50 } } } }
        local rows, any = R.WhenToRows(w)
        eq(any, true); eq(#rows, 2); eq(same(R.RowsToWhen(rows, true), w), true)
        eq(R.WhenToRows({ buff = 'Cover', any = { { hpp = { lt = 5 } } } }), nil, 'mixed shape')
        eq(R.WhenToRows({ colour = 'red' }), nil, 'unknown key')
        local two = R.RowsToWhen({ { key = 'name', op = 'is', value = 'Cure' }, { key = 'name', op = 'is', value = 'Cura' } })
        eq(two.name[2], 'Cura')
    end },
    { 'serialize: one rule a line, groups a choice a line, loads back', function()
        local rules = {
            { on = 'Midcast', when = { skill = 'Elemental Magic', mpp = { le = 40 } }, wear = 'Mp_Body', exact = true },
            { on = 'Midcast', first = { { when = { name = { has = 'storm' } }, wear = 'Storm' }, { wear = 'Enh' } } },
            { on = 'Midcast', item = { Head = "Pixie Hairpin +1", Body = 'Twilight Cloak' }, note = "it's dark" },
        }
        local q = function(x) return (string.find(x, "'", 1, true) and ('"' .. x .. '"')) or ("'" .. x .. "'") end
        local text = R.Serialize(rules, '    ', q, function(k) return k end)
        eq(text, "{\n        { on = 'Midcast', when = { mpp = { le = 40 }, skill = 'Elemental Magic' }, wear = 'Mp_Body', exact = true },\n"
            .. "        { on = 'Midcast', first = {\n            { when = { name = { has = 'storm' } }, wear = 'Storm' },\n            { wear = 'Enh' },\n        } },\n"
            .. "        { on = 'Midcast', item = { Head = 'Pixie Hairpin +1', Body = 'Twilight Cloak' }, note = \"it's dark\" },\n    }")
        local back = loadstring('return ' .. text)()
        eq(back[2].first[2].wear, 'Enh'); eq(back[3].item.Head, 'Pixie Hairpin +1')
    end },
    { 'words', function()
        eq(R.Words({ on = 'Midcast', when = { skill = 'Healing Magic', mpp = { le = 40 } }, wear = 'X' }),
            'mpp <= 40, skill Healing Magic -> X')
    end },
}
