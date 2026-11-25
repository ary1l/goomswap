local G = gFunc.LoadFile('common\\gcgsimport.lua')
local F = gFunc.LoadFile('common\\gcsetfile.lua')
local function eq(a, b, what) if a ~= b then error((what or '') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b), 2) end end
-- A GearSwap job file in Mote's style (written for this test).
local GS = [=[
function get_sets()
    mote_include_version = 2
    include('Mote-Include.lua')
end
function job_setup()
    state.Buff.Berserk = buffactive.Berserk or false
end
function user_setup()
    state.OffenseMode:options('Normal', 'Acc')
    gear.WSCape = { name="Cichol's Mantle", augments={'STR+20','Accuracy+20 Attack+20','Weapon skill damage +10%',}}
    gear.TPCape = { name="Cichol's Mantle", augments={'DEX+20','"Dbl.Atk."+10',}}
end
function init_gear_sets()
    sets.precast.JA['Berserk'] = {body="Pumm. Lorica +3", feet="Agoge Calligae +3"}
    sets.precast.FC = {neck="Baetyl Pendant", left_ear="Loquac. Earring", rring="Prolix Ring"}
    sets.precast.WS = {head="Agoge Mask +3", back=gear.WSCape, waist="Fotia Belt"}
    sets.precast.WS.Acc = set_combine(sets.precast.WS, {waist="Ioskeha Belt +1"})
    sets.precast.WS['Savage Blade'] = set_combine(sets.precast.WS, {neck="War. Beads +2", ear2="Moonshade Earring"})
    sets.precast.WS['Upheaval'] = {head=empty}
    sets.midcast.FastRecast = {head="Sakpata's Helm"}
    sets.midcast.RA = {ammo="Seeth. Bomblet +1"}
    sets.idle = {head="Sakpata's Helm", body="Sakpata's Plate", left_ring="Defending Ring", right_ring={name="Gelatinous Ring +1", priority=10}}
    sets.idle.Town = set_combine(sets.idle, {feet="Hermes' Sandals"})
    sets.idle.Refresh = {neck="Sibyl Scarf"}
    sets.defense.PDT = {head="Nyame Helm"}
    sets.defense.MDT = {head="Nyame Helm", neck="Warder's Charm +1"}
    sets.Kiting = {feet="Hermes' Sandals"}
    sets.engaged = {head="Flam. Zucchetto +2", back=gear.TPCape, ear1="Brutal Earring"}
    sets.engaged.Acc = set_combine(sets.engaged, {ear1="Telos Earring"})
    sets.buff.Doom = {neck="Nicander's Necklace"}
    sets.buff.Berserk = {feet="Warrior's Calligae"}
    sets.TreasureHunter = {waist="Chaac Belt"}
end
function job_buff_change(buff, gain)
    if buff == 'Berserk' then state.Buff.Berserk = gain end
end
]=]
return {
    { 'names map to GoomSwap', function()
        local t = {
            { { 'precast', 'JA', 'Berserk' }, 'Berserk' }, { { 'precast', 'FC' }, 'Precast' },
            { { 'precast', 'FC', 'Healing Magic' }, 'Healing Magic_Precast' }, { { 'precast', 'WS' }, 'Ws_Default' },
            { { 'precast', 'WS', 'Acc' }, 'Ws_Acc' }, { { 'precast', 'WS', 'Savage Blade' }, 'Savage Blade' },
            { { 'precast', 'WS', 'Savage Blade', 'Acc' }, 'Savage Blade_Acc' }, { { 'midcast', 'RA', 'Acc' }, 'Midshot_Acc' },
            { { 'idle' }, 'Idle' }, { { 'idle', 'Town' }, 'Town' }, { { 'idle', 'Regen' }, 'Idle_Regen' },
            { { 'engaged' }, 'Tp_Default' }, { { 'engaged', 'Acc' }, 'Tp_Acc' }, { { 'defense', 'MDT' }, 'mdt' },
            { { 'Kiting' }, 'Movement' }, { { 'buff', 'Doom' }, 'Doomed' }, { { 'midcast', 'Elemental Magic', 'Resistant' }, 'Elemental Magic_Resistant' },
            { { 'precast', 'CorsairRoll' }, 'Phantom Roll' }, { { 'precast', 'CorsairShot' }, 'Quick Draw' },
        }
        for _, x in ipairs(t) do eq(G.Name(x[1]), x[2], table.concat(x[1], '.')) end
        eq(G.Name({ 'buff', 'Berserk' }).buff, 'Berserk')
    end },
    { 'a Mote file: sets, set_combine, gear vars, empty, slot aliases', function()
        local imp = assert(G.Import(GS))
        local s = imp.sets
        eq(s.Berserk.Body, 'Pumm. Lorica +3'); eq(s.Precast.Ear1, 'Loquac. Earring'); eq(s.Precast.Ring2, 'Prolix Ring')
        eq(s.Ws_Default.Back.Name, "Cichol's Mantle"); eq(s.Ws_Default.Back.Augment[3], 'Weapon skill damage +10%')
        eq(s.Ws_Acc.Head, 'Agoge Mask +3', 'combined base'); eq(s.Ws_Acc.Waist, 'Ioskeha Belt +1', 'combined over')
        eq(s['Savage Blade'].Ear2, 'Moonshade Earring'); eq(s.Upheaval.Head, 'remove')
        eq(s.Midcast.Head, "Sakpata's Helm"); eq(s.Midshot.Ammo, 'Seeth. Bomblet +1')
        eq(s.Idle.Ring2.Priority, 10); eq(s.Town.Feet, "Hermes' Sandals"); eq(s.Town.Body, "Sakpata's Plate")
        eq(s.Idle_Refresh.Neck, 'Sibyl Scarf'); eq(s.Dt.Head, 'Nyame Helm'); eq(s.mdt.Neck, "Warder's Charm +1")
        eq(s.Movement.Feet, "Hermes' Sandals"); eq(s.Tp_Acc.Ear1, 'Telos Earring'); eq(s.Tp_Acc.Back.Name, "Cichol's Mantle")
        eq(s.Doomed.Neck, "Nicander's Necklace"); eq(imp.buffs.Berserk.Feet, "Warrior's Calligae"); eq(s.TH.Waist, 'Chaac Belt')
    end },
    { 'draft: the example with its sets replaced, loads, parses as sets', function()
        local imp = assert(G.Import(GS))
        local template = io.open('examples/WAR.lua'):read('*a')
        local text, counts = G.Draft(template, imp, { file = 'Me_WAR.lua', date = '2026-11-25' }, F)
        assert(text, counts)
        eq(loadstring(text) ~= nil, true, 'loads')
        local model = assert(F.Parse(text))
        eq(model.byName.Tp_Acc ~= nil, true); eq(model.byName["Buffs['Berserk']"] ~= nil, true, 'buff set under Buffs')
        eq(string.find(text, "Head = 'Valorous Mask'", 1, true), nil, 'example gear gone')
        eq(counts.buffs, 1)
    end },
}
