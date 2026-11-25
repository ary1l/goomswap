-- Convert's promise, checked with the same check the editor runs (common/gcconvertcheck.lua): for every example job
-- file and every original before its Convert, the checked plan (runs moved where the gear stays the same, failing
-- handlers left as code) wears what the code did, slot by slot, over many random game states; and the check catches
-- a conversion that changes gear.
string.contains = string.contains or function(s, v) return string.find(s, v, 1, true) ~= nil end
local K = gFunc.LoadFile('common\\gcconvertcheck.lua')
local C = gFunc.LoadFile('common\\gcconvert.lua')

local function check_file(path)
    local text = io.open(path):read('*a')
    local plan = assert(K.Run(text))
    assert(plan.checked.unavailable == nil, path .. ': check could not run: ' .. tostring(plan.checked.unavailable))
    local skipped = next(plan.checked.skipped)
    assert(skipped == nil, path .. ': ' .. tostring(skipped) .. ' ' .. tostring(plan.checked.skipped[skipped or '']))
    for _, h in ipairs(plan.handlers) do -- again, other states (another seed)
        local same, diff = K.Same(text, plan, h.name, 300, 7919)
        assert(same, path .. ' ' .. h.name .. ': ' .. tostring(diff))
    end
    return plan
end

local tests = {}
local files = {}
for _, job in ipairs({ 'BLM', 'BLU', 'BRD', 'BST', 'COR', 'DNC', 'DRG', 'DRK', 'GEO', 'MNK', 'NIN', 'PLD', 'PUP', 'RDM',
    'RNG', 'RUN', 'SAM', 'SCH', 'SMN', 'THF', 'WAR', 'WHM' }) do
    files[#files + 1] = 'examples/' .. job .. '.lua'
end
for _, job in ipairs({ 'BLM', 'RDM', 'SCH', 'GEO', 'WHM', 'BRD', 'COR', 'RNG', 'PLD' }) do -- the examples as they were before their Convert
    files[#files + 1] = 'tests/fixtures/' .. job .. '.lua'
end
for _, f in ipairs(files) do
    tests[#tests + 1] = { 'converted ' .. f .. ' wears what its code did', function() check_file(f) end }
end
tests[#tests + 1] = { 'the check frees code spots where the gear stays the same', function()
    local spots0, spots = 0, 0
    for _, job in ipairs({ 'BLM', 'RDM', 'SCH', 'GEO', 'WHM', 'BRD', 'COR', 'RNG', 'PLD' }) do
        local text = io.open('tests/fixtures/' .. job .. '.lua'):read('*a')
        for _, r in ipairs(C.Plan(text).runs) do if r.spot then spots0 = spots0 + 1 end end
        for _, r in ipairs(K.Run(text).runs) do if r.spot then spots = spots + 1 end end
    end
    assert(spots < spots0, 'no spot freed: ' .. spots .. ' of ' .. spots0)
end }
tests[#tests + 1] = { 'the check catches a conversion that changes gear', function()
    local text = io.open('tests/fixtures/WHM.lua'):read('*a')
    local plan = K.Run(text)
    local bad = false
    for _, r in ipairs(plan.rules) do
        if (r.on == 'Midcast') and (type(r.wear) == 'string') and not bad then r.wear, bad = 'Idle', true end
    end
    assert(bad, 'no midcast rule to change')
    local same = K.Same(text, plan, 'HandleMidcast', 300, 1)
    assert(not same, 'a changed rule passed the check')
end }
return tests
