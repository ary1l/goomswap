local F = gFunc.LoadFile('common\\gcsetfile.lua')
local function eq(a, b, what) if a ~= b then error((what or '') .. ':\n' .. tostring(a) .. '\n~=\n' .. tostring(b), 2) end end
local CHAR = "return {\n    settings = {\n        DTGearHPP = 40,\n    },\n}\n"
return {
    { 'char.lua top key added beside settings', function()
        local t = F.SetCharTop(CHAR, 'Packer', function() return "{ ['Echo Drops'] = 'stack' }" end)
        eq(t, "return {\n    settings = {\n        DTGearHPP = 40,\n    },\n    Packer = { ['Echo Drops'] = 'stack' },\n}\n")
        local back = F.SetCharTop(t, 'Packer', function() return nil end)
        eq(back, CHAR, 'taken out')
        eq(F.SetCharTop(t, 'Packer', function() return '{}' end), "return {\n    settings = {\n        DTGearHPP = 40,\n    },\n    Packer = {},\n}\n")
    end },
    { 'profile.Packer read and replaced in a job file', function()
        local job = "local profile = {};\nprofile.Packer = {\n    'Echo Drops',\n};\nprofile.OnLoad = function()\n    gcinclude.Initialize();\nend\n"
        eq(F.JobSetting(job, 'profile.Packer'), "{\n    'Echo Drops',\n}")
        local t = F.SetJobSetting(job, 'profile.Packer', function() return "{ 'Remedy' }" end)
        eq(F.JobSetting(t, 'profile.Packer'), "{ 'Remedy' }")
        local none = "local profile = {};\nprofile.OnLoad = function()\n    gcinclude.Initialize();\nend\n"
        local added = F.SetJobSetting(none, 'profile.Packer', function() return '{}' end)
        eq(added, "local profile = {};\nprofile.OnLoad = function()\n    profile.Packer = {};\n    gcinclude.Initialize();\nend\n")
        eq(F.JobSetting(job, 'Packer'), nil, 'gcinclude.Packer is another name')
    end },
    { 'Save adds a new Weapon_ set to /wm unless the engine wears it for another mode (_1h, an /mset version)', function()
        local job = "local profile = {};\nprofile.OnLoad = function()\n    gcinclude.MeleeModes = {'Default', 'Acc'};\n"
            .. "    gcinclude.WeaponModes = {'None', 'Mpu'};\n    gcinclude.Initialize();\nend\n"
        local function adds(names)
            local sets = {}
            for i, n in ipairs(names) do sets[i] = { name = n } end
            local out = {}
            local ok, added = F.AddWeaponModes(job, sets, out, {})
            assert(ok)
            return table.concat(added or {}, ',')
        end
        eq(adds({ 'Weapon_MpuTP' }), 'MpuTP') -- no /mset TP: a mode of its own (was taken for a variant)
        eq(adds({ 'Weapon_MpuAcc' }), '') -- /wm Mpu with /mset Acc
        eq(adds({ 'Weapon_Mpu_Acc' }), '')
        eq(adds({ 'Weapon_Mpu_1h' }), '')
        eq(adds({ 'Weapon_Naegling' }), 'Naegling')
        eq(adds({ 'Weapon_Mpu_Foo' }), '') -- not one word
    end },
    { "/gcbuild's notes: its header and slot notes go; the slots it left out, and other comments, stay", function()
        local text = table.concat({
            '-- Proposed by /gcbuild for Me: GoomSwap examples/DNC.lua with the gear you own (2026-11-26).',
            '-- Move to a wardrobe:',
            '--   Maculele Tiara +3 (Slip 30)',
            'local profile = {};',
            '-- DNC example: swap in your own gear.',
            'local sets = {',
            "    Idle = { -- standing",
            "        Head = 'Maculele Tiara +3', -- example: Maculele Tiara +1; yours is in Slip 30: move it to a wardrobe",
            "        Body = 'Nyame Mail', -- in Slip 23: move it to a wardrobe",
            "        Hands = 'Nyame Gauntlets', -- your augments differ from the example's: Path A",
            "        --Neck = 'Bathy Choker +1', -- not owned",
            "        Feet = 'Gleti\\'s Boots', -- my own note",
            '    },',
            '};',
            'return profile;', '' }, '\n')
        local n, out = F.BuildNotes(text)
        eq(n, 4)
        eq(string.find(out, 'Proposed by', 1, true), nil, out)
        eq(string.find(out, 'wardrobe', 1, true), nil, out)
        eq(string.find(out, 'augments differ', 1, true), nil, out)
        eq(string.find(out, "--Neck = 'Bathy Choker +1', -- not owned", 1, true) ~= nil, true, out)
        eq(string.find(out, '-- my own note', 1, true) ~= nil, true, out)
        eq(string.find(out, '-- DNC example', 1, true) ~= nil, true, out)
        eq(string.sub(out, 1, 20), 'local profile = {};\n')
    end },
    { 'editor backups kept: 3 unless set (0 keeps all)', function()
        eq(F.Backups.Keep(nil), 3); eq(F.Backups.Keep('x'), 3); eq(F.Backups.Keep(-1), 3)
        eq(F.Backups.Keep(0), 0); eq(F.Backups.Keep(20), 20)
    end },
}
