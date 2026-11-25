-- Offline tests for GoomSwap's pure modules: luajit tests/run.lua (from the repository root).
-- No game: gFunc.LoadFile reads common\x.lua from disk; each test file returns a list of { name, fn }.
gFunc = { LoadFile = function(p) return dofile((string.gsub(p, '\\', '/'))) end }
T = function(t) return t end
local files = { 'tests/packerlist.lua', 'tests/setfile.lua', 'tests/rules.lua', 'tests/ui_rules.lua', 'tests/convert.lua', 'tests/convert_sim.lua', 'tests/gsimport.lua', 'tests/ui_settings.lua' }
for i = 1, #arg do files = { arg[i] } end
local passed, failed = 0, 0
for _, f in ipairs(files) do
    for _, t in ipairs(dofile(f)) do
        local ok, err = pcall(t[2])
        if ok then passed = passed + 1 else failed = failed + 1; print('FAIL ' .. f .. ': ' .. t[1] .. ': ' .. tostring(err)) end
    end
end
print(passed .. ' passed, ' .. failed .. ' failed')
os.exit((failed == 0) and 0 or 1)
