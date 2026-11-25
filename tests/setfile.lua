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
}
