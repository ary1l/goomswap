local Gm = gFunc.LoadFile('common\\gcgoomfile.lua')
local F = gFunc.LoadFile('common\\gcsetfile.lua')
local Gr = gFunc.LoadFile('common\\gceditgroups.lua')
local function eq(a, b, what) if a ~= b then error((what or '') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b), 2) end end
local function ser(v) return Gr.SerializeValue(v, F.QuoteText, F.FormatKey) end
return {
    { 'every example exports, reads back, and is in step with its job file', function()
        for _, job in ipairs({ 'WAR', 'RDM', 'COR', 'SMN', 'BLU', 'PLD' }) do
            local text = io.open('examples/' .. job .. '.lua'):read('*a')
            local data = assert(Gm.Export(text, F, { file = job .. '.lua', job = job }))
            eq(data.job, job)
            eq(type(data.sets.Idle), 'table', job .. ' Idle')
            eq(type(data.rules), 'table', job .. ' rules')
            eq(#data.order > 5, true, job .. ' sets')
            local out = Gm.Text(data, ser)
            local back = assert(Gm.Read(out), job .. ' reads back')
            eq(#back.rules, #data.rules, job .. ' rules back')
            eq(Gm.InStep(out, text), true, job .. ' in step')
            eq(Gm.InStep(out, text .. '\n-- edited by hand'), false, job .. ' stale after an outside edit')
        end
    end },
    { 'options and settings lines, code named', function()
        local text = io.open('examples/WAR.lua'):read('*a')
        local data = Gm.Export(text, F, { file = 'WAR.lua' })
        eq(data.options.DefaultWeapons, 'None'); eq(data.settings.RefreshGearMPP, 0)
        local coded = "local profile = {};\nlocal x = { Head = 'A' };\nlocal sets = {\n    Idle = { Head = 'B' },\n    Built = x,\n};\nprofile.Sets = sets;\nreturn profile;\n"
        local d2 = Gm.Export(coded, F, {})
        eq(d2.sets.Idle.Head, 'B'); eq(d2.sets.Built, nil); eq(d2.code[1], 'sets.Built')
    end },
    { 'paths', function() eq(Gm.PathFor('C:\\x\\Me_1\\WHM.lua'), 'C:\\x\\Me_1\\WHM.goom.lua') end },
}
