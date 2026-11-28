-- /gcimport: a Windower GearSwap job file's sets, as a GoomSwap job file draft. The file is parsed (gcconvert's Lua
-- parser) and its set assignments evaluated as data: tables, set_combine(...), names it set earlier (gear.X,
-- locals), string joins. Nothing in it runs, and its logic (states, functions, binds) is not imported: that is for
-- /gcedit's Rules.
--
-- GearSwap's own rules, from its source (addons/GearSwap): a slot key is any case of main sub range/ranged ammo head
-- body hands legs feet neck waist back, ear1/left_ear/learring/lear, ear2/right_ear/rearring/rear,
-- ring1/left_ring/lring, ring2/right_ring/rring (statics.lua slot_map; user_key_filter lowercases); an item is a name
-- or { name, augments | augment, priority, bag } (equip_processing.lua expand_entry); set_combine(a, b, ...) is the
-- slots of each in turn (helper_functions.lua set_merge); `empty` takes a slot off.
-- Set names follow Mote's include where GoomSwap has the same idea (sets.engaged.Acc -> Tp_Acc, sets.precast.WS
-- ['Savage Blade'] -> ['Savage Blade'], sets.midcast.RA -> Midshot ...); anything else keeps its path, joined by _.
local G = {}
local C = gFunc.LoadFile('common\\gcconvert.lua')

local SLOT = {
    main = 'Main', sub = 'Sub', range = 'Range', ranged = 'Range', ammo = 'Ammo', head = 'Head', body = 'Body',
    hands = 'Hands', legs = 'Legs', feet = 'Feet', neck = 'Neck', waist = 'Waist', back = 'Back',
    ear1 = 'Ear1', left_ear = 'Ear1', learring = 'Ear1', lear = 'Ear1',
    ear2 = 'Ear2', right_ear = 'Ear2', rearring = 'Ear2', rear = 'Ear2',
    ring1 = 'Ring1', left_ring = 'Ring1', lring = 'Ring1', ring2 = 'Ring2', right_ring = 'Ring2', rring = 'Ring2',
}
G.SLOT = SLOT
local SCREEN = { 'Main', 'Sub', 'Range', 'Ammo', 'Head', 'Neck', 'Ear1', 'Ear2', 'Body', 'Hands', 'Ring1', 'Ring2',
    'Back', 'Waist', 'Legs', 'Feet' }
local EMPTY = setmetatable({}, { __tostring = function() return 'empty' end })
local SET = {} -- marks a table a set_combine made (its slot keys already GoomSwap's: slot_of still takes them, and
-- leaves out a set kept in it, sets.precast.WS['Stardiver'].Acc)

local function slot_of(k) return (type(k) == 'string') and SLOT[string.lower(k)] or nil end

-- == Evaluation: values as data ==
local function evaluator()
    local env = { sets = {}, gear = {}, empty = EMPTY, player = {}, state = {}, buffactive = {}, world = {}, info = {},
        res = {}, windower = {}, options = {} }
    local unknown, gearRead = {}, {} -- gearRead: gear.X names read, for those never set
    local eval
    local function combine(args)
        local out = { [SET] = true }
        for _, t in ipairs(args) do
            if type(t) == 'table' then
                for k, v in pairs(t) do
                    local s = (k ~= SET) and slot_of(k) or nil
                    if s ~= nil then out[s] = v end
                end
            end
        end
        return out
    end
    eval = function(e)
        if e == nil then return nil end
        local k = e.k
        if k == 'str' or k == 'num' or k == 'bool' then return e.v end
        if k == 'nil' then return nil end
        if k == 'paren' then return eval(e.a) end
        if k == 'table' then
            local t = {}
            for i, x in ipairs(e.items) do t[i] = eval(x) end
            for name, x in pairs(e.fields) do t[name] = eval(x) end
            return t
        end
        if k == 'name' then return env[e.v] end
        if k == 'index' then
            local base = eval(e.obj)
            local key = eval(e.key)
            if (type(base) == 'table') and (key ~= nil) then
                if (base == env.gear) and (type(key) == 'string') and (base[key] == nil) then gearRead[key] = true end
                return base[key]
            end
            return nil
        end
        if k == 'bin' and e.op == '..' then
            local a, b = eval(e.a), eval(e.b)
            if (type(a) == 'string' or type(a) == 'number') and (type(b) == 'string' or type(b) == 'number') then
                return tostring(a) .. tostring(b)
            end
            return nil
        end
        if k == 'call' and e.method == nil then
            local fn = (e.fn.k == 'name') and e.fn.v or nil
            if fn == 'set_combine' then
                local args = {}
                for i, a in ipairs(e.args) do args[i] = eval(a) end
                return combine(args)
            end
            if (fn == 'T') or (fn == 'S') or (fn == 'L') then return eval(e.args[1]) end
            unknown[#unknown + 1] = fn or 'a call'
            return nil
        end
        return nil
    end
    local function assign(target, v)
        if target.k == 'name' then
            env[target.v] = v
        elseif target.k == 'index' then
            local base = eval(target.obj)
            if (type(base) ~= 'table') and (target.obj.k == 'index' or target.obj.k == 'name') then
                base = {}
                assign(target.obj, base) -- sets.precast.WS = sets.precast.WS or {}: made on the way
            end
            local key = eval(target.key)
            if (type(base) == 'table') and (key ~= nil) then base[key] = v end
        end
    end
    local walk
    walk = function(list)
        for _, st in ipairs(list or {}) do
            if st.k == 'local' then
                for i, name in ipairs(st.names) do env[name] = eval(st.exprs[i]) end
            elseif st.k == 'assign' then
                for i, t in ipairs(st.targets) do
                    local x = st.exprs[i]
                    if (x ~= nil) and (x.k == 'func') then
                        walk(x.body) -- a function's assignments, in the order it was defined
                    else
                        local v = eval(x)
                        -- sets.x = sets.x or {}: keep what is there
                        if (v == nil) and (x ~= nil) and (x.k == 'bin') and (x.op == 'or') then v = eval(x.a) or eval(x.b) end
                        assign(t, v)
                    end
                end
            elseif st.k == 'localfunc' then
                walk(st.body)
            elseif st.k == 'if' then
                for _, br in ipairs(st.branches) do walk(br.body) end
                walk(st.elseBody)
            elseif (st.k == 'loop') or (st.k == 'do') then
                walk(st.body)
            end
        end
    end
    return env, walk, unknown, gearRead
end

-- == Names ==
G.MODE_WORDS = {}
for w in string.gmatch('Normal Acc MidAcc HighAcc FullAcc SomeAcc LowAcc Mod Att Crit Hybrid PDT DT MDT Low Mid High '
    .. 'Proc Fodder Resistant Dark Light SubtleBlow STP Tank UncappedAtt PDL AM AM3 Match', '%S+') do G.MODE_WORDS[string.lower(w)] = true end
local function join(list, from)
    local out = {}
    for i = from, #list do out[#out + 1] = tostring(list[i]) end
    return table.concat(out, '_')
end
-- A spell's name, as the game has it (in game: the resource manager), of that skill when one is named (the
-- resource's Skill id: Windower res skills 32-44); false outside the game.
local SKILL_IDS = { ['Divine Magic'] = 32, ['Healing Magic'] = 33, ['Enhancing Magic'] = 34,
    ['Enfeebling Magic'] = 35, ['Elemental Magic'] = 36, ['Dark Magic'] = 37, ['Summoning Magic'] = 38,
    Ninjutsu = 39, Singing = 40, ['Blue Magic'] = 43, Geomancy = 44 }
function G.IsSpell(name, skill)
    local ok, r = pcall(function() return AshitaCore:GetResourceManager():GetSpellByName(name, 0) end)
    return ok and (r ~= nil) and ((skill == nil) or (r.Skill == SKILL_IDS[skill]))
end

-- path: { 'precast', 'WS', 'Savage Blade' }. A GoomSwap set name, or { buff = 'Haste' } for Buffs['Haste'] ({ buff,
-- idle = true }: Buffs_Idle).
function G.Name(path)
    local a, b = path[1], path[2]
    local la, lb = string.lower(tostring(a or '')), string.lower(tostring(b or ''))
    local rest3 = (#path >= 3) and join(path, 3) or nil
    local function with(base, from)
        local r = (#path >= from) and join(path, from) or nil
        return (r ~= nil) and (base .. '_' .. r) or base
    end
    if la == 'precast' then
        if #path == 1 then return 'Precast' end
        if lb == 'fc' then
            if #path == 2 then return 'Precast' end
            return rest3 .. '_Precast'
        end
        if lb == 'ja' then return (#path >= 3) and rest3 or 'JA' end
        if lb == 'ws' then
            if #path == 2 then return 'Ws_Default' end
            -- WeaponskillMode UncappedAtt (attack not capped: low buffs, more attack) is GoomSwap's /wsset low,
            -- _LowBuff; PDL stays _PDL (/wsset pdl)
            local name = G.MODE_WORDS[string.lower(tostring(path[3]))] and ('Ws_' .. rest3) or rest3
            return (string.gsub(name, '_[Uu]ncapped[Aa]tt%f[%W_]', '_LowBuff'))
        end
        if lb == 'ra' then return with('Preshot', 3) end
        if lb == 'corsairroll' then return (#path >= 3) and rest3 or 'Phantom Roll' end
        -- a shot by name (sets.precast.CorsairShot['Light Shot']), else a Quick Draw mode (Quick Draw_Resistant)
        if lb == 'corsairshot' then
            return string.match(tostring(rest3), '^%a+ Shot$') and rest3 or with('Quick Draw', 3)
        end
        return with(tostring(b), 3) .. '_Precast'
    end
    if la == 'midcast' then
        if #path == 1 then return 'Midcast' end
        if lb == 'fastrecast' then return with('Midcast', 3) end
        if lb == 'ra' then return with('Midshot', 3) end
        return join(path, 2)
    end
    if la == 'idle' then
        if #path == 1 then return 'Idle' end
        if lb == 'town' then return with('Town', 3) end
        -- Mote's and Selindrile's get_idle_set: sets.idle.Weak while buffactive.weakness (buff 1, Weakness: after a
        -- raise), idle only
        if (lb == 'weak') and (#path == 2) then return { buff = 'Weakness', idle = true } end
        return 'Idle_' .. join(path, 2)
    end
    if la == 'resting' then return with('Resting', 2) end
    if la == 'engaged' then
        if #path == 1 then return 'Tp_Default' end
        return 'Tp_' .. join(path, 2)
    end
    if la == 'defense' then
        if lb == 'pdt' or lb == 'dt' then return with('Dt', 3) end
        -- MDT (MagicalDefenseMode) and Selindrile's MEVA (ResistDefenseMode, DefenseMode Resist): GoomSwap's /mdt
        -- (a file with both: MEVA left out, G.Import)
        if (lb == 'mdt') or (lb == 'meva') then return with('mdt', 3) end
        return 'Dt_' .. join(path, 2)
    end
    if la == 'kiting' then return 'Movement' end
    -- Selindrile's sets.weapons.Naegling (state.Weapons): a /wm mode's weapons
    if (la == 'weapons') and (#path == 2) then return 'Weapon_' .. tostring(b) end
    if (la == 'treasurehunter') or (la == 'th') then return 'TH' end
    if la == 'buff' and #path >= 2 then
        if lb == 'doom' then return 'Doomed' end
        if lb == 'sleep' then return 'Sleeping' end
        return { buff = join(path, 2) }
    end
    return join(path, 1)
end

-- == Mirdain's layout (Mirdain-Include.lua, github.com/Mirdain/Gearswap) ==
-- Its include wears, as it reads: engaged sets.OffenseMode, then OffenseMode[mode], the weapon mode's
-- sets.Weapons[X] (sets.Weapons.Shield over it when it is 1-handed and you can't dual wield, sets.DualWield when
-- you can), Aftermath's OffenseMode.AM3[weapon mode]; idle sets.Idle, then Idle[mode], Idle.Resting, Idle.Pet,
-- Idle.Sublimation, sets.Movement; a spell sets.Precast, Precast.FastCast, Precast.Enhancing, then Precast[spell]
-- or Precast.Cure (Cure, Cura, Curaga) / Healing / Utsusemi / BlueMagic / Songs, and sets.Midcast, Midcast.SIRD,
-- then the spell's own, its kind's (Cure, Refresh, Enfeebling.Potency...) or its skill's; a weapon skill sets.WS,
-- WS[ws], then WS[ws][mode] or else WS[mode] (not in mode TP); an ability sets.JA[name], by kind for rolls, Quick
-- Draw, Waltz, Jig, Samba, Step and Flourish. Its mode TP is the plain one (GoomSwap's Default): its sets are
-- merged into the base ones; ACC is /mset acc, SB /mset sb.
local MIRDAIN_MODE = { acc = 'Acc', sb = 'SubtleBlow' }
function G.MirdainMode(m)
    return MIRDAIN_MODE[string.lower(tostring(m))] or (string.gsub(tostring(m), '[^%w]', ''))
end
local function nospace(s) return (string.gsub(tostring(s), '[^%w]', '')) end
local MIRDAIN_KIND = { phantomroll = 'Phantom Roll', quickdraw = 'Quick Draw', waltz = 'Waltz', jig = 'Jig',
    samba = 'Samba', step = 'Step', flourish = 'Flourish' }
local MIRDAIN_TOP = { treasurehunter = 'TH', movement = 'Movement', dualwield = 'Tp_DW', storms = 'Storm',
    ready = 'Ready_Delay', thirdeye = 'Third Eye', impetus = 'Tp_Impetus',
    foot_work = 'Tp_Footwork', cover = 'Cover_Up', mp_recover = 'MP_Recover', sird = 'SIR', luopan = 'Luopan' }
local MIRDAIN_PRECAST = { enhancing = 'Enhancing Magic_Precast', cure = 'Cure_Precast',
    healing = 'Healing Magic_Precast', bluemagic = 'Blue Magic_Precast', songs = 'Singing_Precast',
    utsusemi = 'Utsusemi_Precast', ra = 'Preshot', fastcast = 'Precast_FastCast' }
local MIRDAIN_MIDCAST = { sird = 'SIR', ra = 'Midshot', enhancing = 'Enhancing Magic', enfeebling = 'Enfeebling Magic',
    dark = 'Dark Magic', divine = 'Divine Magic', nuke = 'Elemental Magic', burst = 'Elemental Magic_Burst',
    bp = 'BP_Delay', summon = 'Summoning Magic', summoningmagic = 'Elemental Siphon', dummysongs = 'Dummy',
    bluemagic = 'Blue Magic' }
local MIRDAIN_UNDER = { -- Midcast.<kind>.<x>
    ra = { tripleshot = 'TripleShot', doubleshot = 'DoubleShot', barrage = 'Barrage' },
    enhancing = { others = 'Enhancing Magic_Others', gain = 'Gain', elemental = 'BarElement', status = 'BarStatus',
        skill = 'Skill_Enhancing' },
    enfeebling = { macc = 'Enfeebling_MACC', potency = 'Enfeebling_Potency', duration = 'Enfeebling_Duration' },
    dark = { macc = 'Dark_MACC', absorb = 'Absorb', enhancing = 'Dark_Enhancing' },
    bluemagic = { nuke = 'BluMagical', skill = 'BluSkill', acc = 'BluMagicAccuracy', healing = 'BluCure',
        enmity = 'BluEnmity' } }
-- the sample SMN's pact classes (its pet_midcast_custom): GoomSwap SMN's BloodPact (physical) and BloodPact_<kind>
local MIRDAIN_PET = { physical_bp = 'BloodPact', magic_bp = 'BloodPact_Magical', flamingcrush = 'Flaming Crush',
    summoningmagic = 'BloodPact_Skill' }
-- song kinds its equip_song_gear picks by name (the first a song's name has, in this order)
local MIRDAIN_SONGS = { 'Finale', 'Lullaby', 'Threnody', 'Elegy', 'Requiem', 'March', 'Minuet', 'Madrigal', 'Ballad',
    'Scherzo', 'Mazurka', 'Paeon', 'Carol', 'Minne', 'Mambo', 'Etude', 'Prelude', 'Dirge', 'Sirvente', 'Aria' }
-- path: { 'OffenseMode', 'ACC' }. modes: the file's OffenseMode options, lower case. A GoomSwap name, { buff = X },
-- or nil for G.Name's. Aftermath sets: <base>_AM3_<weapon mode>; mode TP: <base>_TP (merged or left out after).
function G.MirdainName(path, modes)
    local n, l = #path, {}
    for i, x in ipairs(path) do l[i] = string.lower(tostring(x)) end
    local function mode(i) return (path[i] ~= nil) and modes[l[i]] and G.MirdainMode(path[i]) or nil end
    local function am(base, i) -- AM / AM1-3, then the weapon mode
        if not string.match(l[i] or '', '^am%d?$') then return nil end
        return base .. '_' .. string.upper(l[i]) .. ((path[i + 1] ~= nil) and ('_' .. nospace(path[i + 1])) or '')
    end
    if (n == 1) and MIRDAIN_TOP[l[1]] then return MIRDAIN_TOP[l[1]] end
    if (n == 1) and (l[1] == 'boost') then return { buff = 'Boost' } end
    if l[1] == 'idle' then
        local I = { resting = 'Resting', pet = 'Idle_Pet', sublimation = 'Sublimation' }
        if n == 1 then return 'Idle' end
        if (n == 2) and I[l[2]] then return I[l[2]] end
        return 'Idle_' .. (mode(2) or join(path, 2))
    end
    if l[1] == 'offensemode' then
        if n == 1 then return 'Tp_Default' end
        return am('Tp', 2) or ('Tp_' .. (mode(2) or join(path, 2)))
    end
    if l[1] == 'weapons' then
        if n == 1 then return nil end
        if (n == 2) and (l[2] == 'sleep') then return 'Sleeping' end
        return 'Weapon_' .. nospace(path[2]) .. ((n > 2) and ('_' .. join(path, 3)) or '')
    end
    if l[1] == 'precast' then
        if n == 1 then return 'Precast' end
        if (n == 2) and MIRDAIN_PRECAST[l[2]] then return MIRDAIN_PRECAST[l[2]] end
        if l[2] == 'ra' then
            local F = { flurry = 'Preshot_FlurryI', flurry_ii = 'Preshot_FlurryII' }
            return F[l[3]] or ('Preshot_' .. join(path, 3))
        end
        return join(path, 2) .. '_Precast'
    end
    if l[1] == 'midcast' then
        if n == 1 then return 'Midcast' end
        if (n == 2) and MIRDAIN_MIDCAST[l[2]] then return MIRDAIN_MIDCAST[l[2]] end
        local under = MIRDAIN_UNDER[l[2]]
        if (n == 3) and (under ~= nil) and under[l[3]] then return under[l[3]] end
        if l[2] == 'ra' then return am('Midshot', 3) or ('Midshot_' .. (mode(3) or join(path, 3))) end
        if (l[2] == 'nuke') and (n == 3) then return 'Elemental Magic_' .. tostring(path[3]) end -- Nuke.Earth
        return join(path, 2)
    end
    if l[1] == 'ws' then
        if n == 1 then return 'Ws_Default' end
        if l[2] == 'ra' then
            if n == 2 then return 'Ws_Ranged' end
            return am('Ws_Ranged', 3) or ('Ws_Ranged_' .. (mode(3) or join(path, 3)))
        end
        if am('Ws', 2) then return am('Ws', 2) end
        if (n == 2) and mode(2) then return 'Ws_' .. mode(2) end
        if (n == 3) and mode(3) then return tostring(path[2]) .. '_' .. mode(3) end
        return join(path, 2)
    end
    if l[1] == 'ja' then return (n == 1) and 'JA' or join(path, 2) end
    if MIRDAIN_KIND[l[1]] then return (n == 1) and MIRDAIN_KIND[l[1]] or join(path, 2) end
    if l[1] == 'geomancy' then
        local Geo = { geo = 'Geomancy', indi = 'Indi' }
        if n == 1 then return 'Geomancy_Base' end
        if (n == 2) and Geo[l[2]] then return Geo[l[2]] end
        if (l[2] == 'indi') and (l[3] == 'entrust') then return 'Indi_Entrust' end
        return join(path, 2)
    end
    if l[1] == 'helix' then return (n == 1) and 'Helix' or ('Helix_' .. join(path, 2)) end
    if l[1] == 'pet_midcast' then
        return ((n == 1) and 'PetAction') or ((n == 2) and MIRDAIN_PET[l[2]]) or join(path, 2)
    end
    if l[1] == 'jugs' then return 'Jugs_' .. join(path, 2) end
    return nil
end

-- Mirdain's spell lists (Mirdain-Include.lua), for the rules that wear its kinds' sets
local MIRDAIN_LISTS = {
    Enfeebling_MACC = "skill = 'Enfeebling Magic', name = { 'Dispel', 'Frazzle', 'Frazzle II', 'Poison', 'Poison II', "
        .. "'Poisonga' }",
    Enfeebling_Potency = "name = { 'Paralyze', 'Paralyze II', 'Slow', 'Slow II', 'Addle', 'Addle II', 'Distract', "
        .. "'Distract II', 'Distract III', 'Frazzle III', 'Blind', 'Blind II', 'Gravity', 'Gravity II' }",
    Enfeebling_Duration = "name = { 'Sleep', 'Sleep II', 'Sleepga', 'Sleepga II', 'Diaga', 'Dia', 'Dia II', "
        .. "'Dia III', 'Bio', 'Bio II', 'Bio III', 'Silence', 'Inundation', 'Break', 'Breakaga', 'Bind', 'Bind II' }",
    Dark_MACC = "name = { 'Death', 'Kaustra', 'Stun' }",
    Dark_Enhancing = "name = { 'Dread Spikes', 'Endark', 'Endark II', 'Klimaform', 'Tractor' }",
    Skill_Enhancing = "name = { 'Temper', 'Temper II', 'Enaero', 'Enstone', 'Enthunder', 'Enwater', 'Enfire', "
        .. "'Enblizzard', 'Boost-STR', 'Boost-DEX', 'Boost-VIT', 'Boost-AGI', 'Boost-INT', 'Boost-MND', 'Boost-CHR' }",
    Gain = "name = { start = 'Gain-' }",
    Indi_Entrust = "name = { start = 'Indi-' }, target = 'other'",
    Helix_Dark = "name = { has = 'helix' }, element = 'Dark'",
    Helix_Light = "name = { has = 'helix' }, element = 'Light'",
    BluMagical = "skill = 'Blue Magic', name = { 'Spectral Floe', 'Entomb', 'Magic Hammer', 'Tenebral Crush' }",
    BluMagicAccuracy = "skill = 'Blue Magic', name = { 'Cruel Joke', 'Dream Flower', 'Reaving Wind' }",
    BluCure = "skill = 'Blue Magic', name = { 'Magic Fruit', 'Healing Breeze', 'Wild Carrot', 'Plenilune Embrace', "
        .. "'Restoral' }",
    BluSkill = "skill = 'Blue Magic', name = { 'Occultation', 'Erratic Flutter', \"Nature's Meditation\", 'Cocoon', "
        .. "'Barrier Tusk', 'Metallic Body', 'Mighty Guard' }",
    BluEnmity = "skill = 'Blue Magic', name = { 'Jettatura', 'Geist Wall', 'Blank Gaze', 'Sheep Song', 'Sandspin', "
        .. "'Healing Breeze' }",
}
-- Archery and Marksmanship weapon skills (the game's weapon skill resources, skills 25 and 26): sets.WS.RA's
local RANGED_WS = "'Flaming Arrow', 'Piercing Arrow', 'Dulling Arrow', 'Sidewinder', 'Blast Arrow', 'Arching Arrow', "
    .. "'Empyreal Arrow', 'Namas Arrow', 'Refulgent Arrow', \"Jishnu's Radiance\", 'Apex Arrow', 'Sarv', 'Hot Shot', "
    .. "'Split Shot', 'Sniper Shot', 'Slug Shot', 'Blast Shot', 'Heavy Shot', 'Detonator', 'Coronach', 'Trueflight', "
    .. "'Leaden Salute', 'Numbing Shot', 'Wildfire', 'Last Stand', 'Terminus'"
local AM_BUFF = { AM = 'Aftermath', AM1 = 'Aftermath: Lv.1', AM2 = 'Aftermath: Lv.2', AM3 = 'Aftermath: Lv.3' }
-- A weapon's kind by its item resource: '1h' (skills 2 3 5 9 11, as gcinclude.OneHandSkills), '2h', or nil
function G.WeaponKind(item)
    local name = (type(item) == 'table') and item.Name or item
    local ok, r = pcall(function() return AshitaCore:GetResourceManager():GetItemByName(name, 0) end)
    if not ok or (r == nil) then return nil end
    local s = r.Skill
    if (s == 2) or (s == 3) or (s == 5) or (s == 9) or (s == 11) then return '1h' end
    if (s == 4) or (s == 6) or (s == 7) or (s == 8) or (s == 10) or (s == 12) then return '2h' end
    return nil
end

-- After the sets are named: TP sets merged into the base ones, idle mode sets worn by rule (or left out when they
-- are Idle), Shield made into Weapon_<X>_1h, Precast.Cure copied to Cura / Curaga, the JA base set put under each
-- ability's, the rules for its kinds' sets (out.rules), and what GoomSwap has no use for left out with a note.
function G.MirdainPost(out, modes)
    local function copy(s) local c = {}; for k, v in pairs(s) do c[k] = v end; return c end
    local function over(a, b) local c = copy(a); for k, v in pairs(b) do c[k] = v end; return c end
    local function key(v)
        if type(v) ~= 'table' then return tostring(v) end
        return tostring(v.Name) .. '|' .. table.concat(v.Augment or {}, ',')
    end
    local function same(a, b)
        for k, v in pairs(a) do if key(v) ~= key(b[k]) then return false end end
        for k in pairs(b) do if a[k] == nil then return false end end
        return true
    end
    local gone, merged, rules, why, whyOrder = {}, {}, {}, {}, {}
    local function drop(n, reason)
        if why[reason] == nil then why[reason], whyOrder[#whyOrder + 1] = {}, reason end
        table.insert(why[reason], 'sets.' .. out.from[n])
        gone[n] = true
    end
    -- loose: not when the example names the set at all (DNC wears Waltz by kind in its handler)
    local function rule(set, line, loose) rules[#rules + 1] = { set, line, loose } end
    local NEVER = 'never worn: Mirdain\'s TP mode adds nothing to these'
    for _, n in ipairs(out.order) do
        local base = string.match(out.from[n] or '', '%.[Tt][Pp]$') and string.match(n, '^(.+)_TP$') -- mode TP's
        if (n == 'Ws_TP') or (n == 'Midshot_TP') or (n == 'Ws_Ranged_TP') then
            drop(n, NEVER)
        elseif (base ~= nil) or (n == 'Precast_FastCast') then
            base = base or 'Precast'
            if base == 'Tp' then base = 'Tp_Default' end
            if out.sets[base] ~= nil then
                out.sets[base] = over(out.sets[base], out.sets[n])
            else
                out.sets[base], out.from[base] = out.sets[n], out.from[n]
                out.order[#out.order + 1] = base
            end
            merged[#merged + 1] = 'sets.' .. out.from[n] .. ' -> ' .. base
            gone[n] = true
        end
    end
    local shield = out.sets.Weapon_Shield
    for _, n in ipairs(out.order) do
        local raw = string.match(out.from[n] or '', '^[Ii]dle%.([^%.]+)$') -- Idle[mode]: the file's mode, as named
        local idleMode = (raw ~= nil) and modes[string.lower(raw)] and G.MirdainMode(raw) or nil
        local amBase, amLv, amW = string.match(n, '^(.-)_(AM%d?)_(%w+)$')
        if gone[n] then
            -- merged above
        elseif (idleMode ~= nil) and (out.sets.Idle ~= nil) then
            if same(out.sets[n], out.sets.Idle) then
                drop(n, 'the same as Idle')
            else
                rule(n, "{ on = 'Default', when = { status = 'Idle', mode = { mset = '" .. idleMode .. "' } }, wear = '"
                    .. n .. "' },")
            end
        elseif string.match(n, '^Weapon_') and (shield ~= nil) and (n ~= 'Weapon_Shield')
            and not string.match(n, '_1h$') and (out.sets[n].Main ~= nil) and (out.sets[n .. '_1h'] == nil)
            and (G.WeaponKind(out.sets[n].Main) == '1h') then
            out.sets[n .. '_1h'], out.from[n .. '_1h'] = over(out.sets[n], shield), out.from[n] .. ' + Weapons.Shield'
            out.order[#out.order + 1] = n .. '_1h'
        elseif amLv ~= nil then
            local on = ((amBase == 'Tp') and 'Default') or ((amBase == 'Midshot') and 'Midshot') or 'Weaponskill'
            rule(n, "{ on = '" .. on .. "', when = { buff = '" .. AM_BUFF[amLv] .. "', mode = { wm = '" .. amW .. "' }"
                .. ((on == 'Default') and ", status = 'Engaged'" or '') .. " }, wear = '" .. n .. "' },")
        elseif string.match(n, '_AM%d?$') then
            drop(n, 'Aftermath sets with no weapon mode: Mirdain wears only AM3[weapon mode] and the like')
        elseif n == 'JA' then
            for _, m in ipairs(out.order) do
                if string.match(string.lower(out.from[m] or ''), '^ja%.') then
                    out.sets[m] = over(out.sets.JA, out.sets[m])
                end
            end
            drop(n, 'under each ability\'s set now (Mirdain wears it under sets.JA[name])')
        elseif n == 'Geomancy_Base' then
            drop(n, 'never worn: Mirdain wears Geomancy[spell], .Indi or .Geo')
        elseif string.match(n, '^Jugs_') then
            drop(n, "jug pets by its JobMode: put the jug in Call Beast / Bestial Loyalty")
        elseif string.match(n, '^Weapon_Songs') then
            drop(n, "song weapons: put them in your song sets, and singing in Always swap weapons for (HoldExempt)")
        elseif MIRDAIN_LISTS[n] then
            rule(n, "{ on = 'Midcast', when = { " .. MIRDAIN_LISTS[n] .. ", nameset = false }, wear = '" .. n .. "' },")
        elseif n == 'Ws_Ranged' then
            rule(n, "{ on = 'Weaponskill', when = { name = { " .. RANGED_WS .. " }, nameset = false }, wear = '"
                .. n .. "' },")
        end
        local el = string.match(n, '^Elemental Magic_(%u%l+)$')
        if (el ~= nil) and (el ~= 'Burst') and (el ~= 'Precast') then
            rule(n, "{ on = 'Midcast', when = { skill = 'Elemental Magic', element = '" .. el .. "' }, wear = '" .. n
                .. "' },")
        end
    end
    if shield ~= nil then
        drop('Weapon_Shield', 'over each 1-handed weapon set when you can\'t dual wield: Weapon_<X>_1h')
    end
    -- Precast.Cure is worn for Cure, Cura and Curaga: GoomSwap's precast goes by family
    local cure = out.sets.Cure_Precast
    for _, f in ipairs((cure ~= nil) and { 'Curaga_Precast', 'Cura_Precast' } or {}) do
        if out.sets[f] == nil then
            out.sets[f], out.from[f] = cure, out.from.Cure_Precast
            out.order[#out.order + 1] = f
            merged[#merged + 1] = 'sets.' .. out.from.Cure_Precast .. ' -> ' .. f .. ' too'
        end
    end
    local keep = {}
    for _, n in ipairs(out.order) do
        if gone[n] then out.sets[n], out.from[n] = nil, nil else keep[#keep + 1] = n end
    end
    out.order = keep
    if (out.sets.Luopan ~= nil) and (out.sets.Idle_Pet == nil) then -- the sample GEO's luopan set: idle with a pet
        out.sets.Idle_Pet, out.from.Idle_Pet, out.sets.Luopan = out.sets.Luopan, out.from.Luopan, nil
        for i, n in ipairs(out.order) do if n == 'Luopan' then out.order[i] = 'Idle_Pet' end end
    end
    for _, k in ipairs(MIRDAIN_SONGS) do
        rule(k, "{ on = 'Midcast', when = { skill = 'Singing', name = { has = '" .. k .. "' } }, wear = '" .. k
            .. "' },")
    end
    local SAMPLE = { -- the sample job files' own code: kept as they read it
        { 'Idle_Pet', "{ on = 'Default', when = { pet = true, status = { isnt = 'Engaged' } }, wear = 'Idle_Pet' }," },
        { 'MEVA', "{ on = 'Midcast', when = { mode = { mset = 'MEVA' }, family = { isnt = 'Cure' } }, wear = "
            .. "'MEVA' }," },
        { 'MP_Recover', "{ on = 'Midcast', when = { skill = 'Elemental Magic', name = { isnt = { 'Burn', 'Frost', "
            .. "'Choke', 'Rasp', 'Shock', 'Drown' } }, mpp = { lt = 30 } }, wear = 'MP_Recover' }," },
        { 'Cover_Up', "{ on = 'Default', when = { buff = 'Cover' }, wear = 'Cover_Up' }," },
        { 'Saboteur', "{ on = 'Midcast', when = { buff = 'Saboteur', skill = 'Enfeebling Magic' }, wear = "
            .. "'Saboteur' }," },
        { 'TripleShot', "{ on = 'Midshot', when = { buff = 'Triple Shot' }, wear = 'TripleShot' }," },
        { 'DoubleShot', "{ on = 'Midshot', when = { buff = 'Double Shot' }, wear = 'DoubleShot' }," },
        { 'Barrage', "{ on = 'Midshot', when = { buff = 'Barrage' }, wear = 'Barrage' }," },
        { 'Preshot_FlurryI', "{ on = 'Preshot', when = { buff = 265 }, wear = 'Preshot_FlurryI' }," },
        { 'Preshot_FlurryII', "{ on = 'Preshot', when = { buff = 581 }, wear = 'Preshot_FlurryII' }," },
    }
    for _, r in ipairs(SAMPLE) do rule(r[1], r[2]) end
    for _, k in ipairs({ 'Waltz', 'Jig', 'Samba', 'Step', 'Flourish' }) do
        rule(k, "{ on = 'Ability', when = { name = { has = '" .. k .. "' }, nameset = false }, wear = '" .. k .. "' },",
            true)
    end
    out.rules = rules
    if #merged > 0 then
        out.notes[#out.notes + 1] = 'Mirdain\'s TP mode is GoomSwap\'s Default, merged into the base sets (with '
            .. 'Precast.FastCast): ' .. table.concat(merged, ', ')
    end
    for _, w in ipairs(whyOrder) do
        out.notes[#out.notes + 1] = 'left out: ' .. table.concat(why[w], ', ') .. ': ' .. w
    end
end

-- An item as LAC takes it: 'Name', { Name, Augment, Priority }, 'remove' for empty; nil and why when it isn't one.
function G.Item(v)
    if v == EMPTY then return 'remove' end
    if type(v) == 'string' then
        if string.lower(v) == 'empty' then return 'remove' end
        return v
    end
    if (type(v) == 'table') and (type(v.name) == 'string') then
        local out = { Name = v.name }
        if type(v.augments) == 'table' then
            local augs = {}
            for _, x in ipairs(v.augments) do if type(x) == 'string' then augs[#augs + 1] = x end end
            if #augs > 0 then out.Augment = augs end
        elseif type(v.augment) == 'string' then
            out.Augment = { v.augment }
        end
        if type(v.priority) == 'number' then out.Priority = v.priority end
        if (out.Augment == nil) and (out.Priority == nil) then return v.name end
        return out
    end
    return nil, 'not an item'
end

-- text: the GearSwap file. { sets = { [name] = set }, order = { names }, buffs = { [buff] = set }, notes = { lines } }.
-- items: the character's -Items.lua text (G.ItemsFile), read first for its gear.X; its own sets.X are for every job:
-- left out unless GoomSwap has a name for them (sets.TreasureHunter: TH).
function G.Import(text, items)
    local fromItems, itemSets = {}, {}
    for line in string.gmatch(items or '', '[^\n]+') do
        local n = string.match(line, '^%s*sets%.([%a_][%w_]*)%s*=')
        local mine = (n ~= nil) and string.find(text, 'sets%.' .. n .. '%s*=') -- the job file sets it itself
        if (n ~= nil) and (G.Name({ n }) == n) and not mine and not fromItems[n] then
            fromItems[n], itemSets[#itemSets + 1] = true, n
        end
    end
    if items ~= nil then text = items .. '\n' .. text end
    local chunk, err = C.Parse(text)
    if chunk == nil then return nil, 'the file does not parse: ' .. tostring(err) end
    local env, walk, unknown, gearRead = evaluator()
    walk(chunk)
    -- Mirdain's layout (G.MirdainName): its OffenseMode options name its mode sets (TP ACC DT by default; the
    -- sample files' other modes too)
    local mirdain = (string.find(text, 'Mirdain%-Include') ~= nil)
    local modes = { tp = true, acc = true, dt = true, pdt = true, pdl = true, meva = true, sb = true, crit = true }
    local optText = string.match(text, 'state%.OffenseMode%s*:%s*options%s*(%b())') or ''
    for _, x in string.gmatch(optText, "(['\"])(.-)%1") do modes[string.lower(x)] = true end
    local function nameOf(path)
        local m = mirdain and G.MirdainName(path, modes) or nil
        if m ~= nil then return m end
        return G.Name(path)
    end
    local out = { sets = {}, order = {}, buffs = {}, buffOrder = {}, idleBuffs = {}, idleBuffOrder = {}, notes = {},
        from = {} }
    local seen, takenNote, seenName = {}, {}, {}
    -- Mirdain: one table under two names (sets.WS['Burning Blade'] = sets.WS.MAB) is worn by both: a copy for a
    -- weapon skill, ability or spell by name, unless the first is a kind GoomSwap wears for all of them (Waltz)
    local BYNAME = { ws = true, ja = true, midcast = true, precast = true, pet_midcast = true }
    local KINDS = { ['Phantom Roll'] = true, ['Quick Draw'] = true, Waltz = true, Jig = true, Samba = true, Step = true,
        Flourish = true }
    local function alias(t, path)
        local first = seenName[t]
        if not mirdain or (first == nil) or KINDS[first] or (#path ~= 2) then return end
        if not BYNAME[string.lower(tostring(path[1]))] then return end
        local name = nameOf(path)
        if (type(name) ~= 'string') or (out.sets[name] ~= nil) then return end
        local c = {}
        for k, v in pairs(out.sets[first]) do c[k] = v end
        out.sets[name], out.order[#out.order + 1], out.from[name] = c, name, table.concat(path, '.')
    end
    local function visit(t, path)
        if seen[t] then return alias(t, path) end
        seen[t] = true
        local set, any = {}, false
        for k, v in pairs(t) do
            local s = (k ~= SET) and slot_of(k) or nil
            if s ~= nil then
                local item, why = G.Item(v)
                if item ~= nil then
                    set[s], any = item, true
                elseif v ~= nil then
                    out.notes[#out.notes + 1] = 'sets.' .. table.concat(path, '.') .. ' ' .. s .. ': ' .. why .. ' (left out)'
                end
            end
        end
        if any and (#path > 0) then
            local name = nameOf(path)
            if type(name) == 'table' then
                local into, order = out.buffs, out.buffOrder
                if name.idle then into, order = out.idleBuffs, out.idleBuffOrder end
                if into[name.buff] == nil then order[#order + 1] = name.buff end
                into[name.buff] = set
            else
                local base, n = name, 1
                while out.sets[name] ~= nil do
                    n = n + 1
                    name = base .. '_' .. n
                end
                if n > 1 then -- noted below, unless left out
                    takenNote[name] = 'sets.' .. table.concat(path, '.') .. ' -> ' .. name .. ' (' .. base
                        .. ' was taken by sets.' .. out.from[base] .. ')'
                end
                out.sets[name], out.order[#out.order + 1], out.from[name] = set, name, table.concat(path, '.')
                seenName[t] = name
            end
        end
        local keys = {}
        for k, v in pairs(t) do
            if (k ~= SET) and (type(v) == 'table') and (slot_of(k) == nil) and (type(k) == 'string') then keys[#keys + 1] = k end
        end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local p = {}
            for i, x in ipairs(path) do p[i] = x end
            p[#p + 1] = k
            visit(t[k], p)
        end
    end
    -- in the order the file names them (sets.precast before sets.midcast...)
    local tops, at = {}, {}
    for name in pairs(env.sets) do
        if type(name) == 'string' then
            tops[#tops + 1] = name
            at[name] = string.find(text, 'sets%.' .. name:gsub('%p', '%%%0')) or string.find(text, name, 1, true) or 1e9
        end
    end
    -- Mirdain: the sets its include wears first, so one table under two names (sets.JA.Provoke = sets.Enmity,
    -- sets.Waltz['Curing Waltz'] = sets.Waltz) keeps the name it is worn by
    local FIRST = { 'Weapons', 'Idle', 'OffenseMode', 'DualWield', 'TreasureHunter', 'Movement', 'Precast', 'Midcast',
        'WS', 'PhantomRoll', 'QuickDraw', 'Waltz', 'Jig', 'Samba', 'Step', 'Flourish', 'JA', 'Geomancy', 'Helix',
        'Storms', 'Pet_Midcast', 'Ready' }
    for i, name in ipairs(mirdain and FIRST or {}) do if at[name] ~= nil then at[name] = i - 100 end end
    table.sort(tops, function(a, b) if at[a] ~= at[b] then return at[a] < at[b] end return a < b end)
    for _, name in ipairs(tops) do
        if (type(env.sets[name]) == 'table') and not fromItems[name] then visit(env.sets[name], { name }) end
    end
    if #itemSets > 0 then
        out.notes[#out.notes + 1] = 'left out, the Items file\'s sets for every job: ' .. table.concat(itemSets, ', ')
    end
    -- Selindrile's helper sets, put on by its own code: GoomSwap does that itself, or a set by name does. Left out
    -- with a note, by reason; gear named only where it should go elsewhere (sets.MaxTP['Savage Blade'] too)
    local MOONSHADE = 'ears for weapon skills at high TP or by time of day (GoomSwap takes Moonshade off at '
        .. 'MoonshadeTP)'
    local DROP = { MaxTP = { MOONSHADE }, AccMaxTP = { MOONSHADE }, DayMaxTPWSEars = { MOONSHADE },
        AccDayMaxTPWSEars = { MOONSHADE }, DayWSEars = { MOONSHADE }, AccDayWSEars = { MOONSHADE },
        Schere = { 'an ear its WS enmity-down mode puts on' }, Obi = { 'GoomSwap picks obis itself (ElementGear)' },
        DrainWeapon = { "Drain's weapons: put them in ['Drain'], and Drain in Always swap weapons for "
            .. '(HoldExempt)', true },
        DreadWeapon = { "Dread Spikes' weapons: put them in ['Dread Spikes'], and Dread Spikes in Always swap weapons "
            .. 'for (HoldExempt)', true },
        TPEat = { 'idle gear for TP above 10' }, HPDown = { 'its own HP-down swaps' },
        latent_refresh_grip = { 'a grip for a staff under 51% MP', true },
        DWMax = { 'its dual-wield swaps' }, DWEarrings = { 'its dual-wield swaps' },
        HPCure = { 'its cure cheat (cures after an HP-down swap)' },
        MP = { 'nothing in Selindrile\'s code puts it on' }, Suppa = { 'nothing in Selindrile\'s code puts it on' },
        SuppaBrutal = { 'nothing in Selindrile\'s code puts it on' },
        MeleeCuraga = { 'nothing in Selindrile\'s code puts it on (its WHM has melee versions of Cure only)' },
        Learning = { 'its BLU learning mode' },
        Skillchain = { 'its SkillchainMode\'s WS gear: put it in the WS sets you skillchain with' },
        ResistantMagicBurst = { 'CastingMode Resistant magic bursts: GoomSwap\'s burst set is Elemental Magic_Burst' },
        passive = { 'its Passive mode\'s sets, over idle and engaged (reraise gear: /idleset reraise, Idle_Reraise)' } }
    local SKIPPED = { { '_Fodder', 'Fodder mode versions (weak mobs)' }, { 'HighTierNuke', 'high-tier nuke versions: '
        .. "GoomSwap's nuke set is Elemental Magic" }, { '^Idle_Sphere', "Selindrile's Sphere idle mode" },
        { '^Blue Magic_Physical%u', 'Blue Magic by stat: BLU has one physical set (BluPhysical)' },
        { '^Blue Magic_Magical%u', 'Blue Magic by stat: BLU has one magical set (BluMagical)' },
        { '^Dt_%u+Reraise$', 'DefenseMode Reraise versions: /dt with /idleset reraise' },
        { '^Dt_%u+_HP$', 'DefenseMode HP versions: GoomSwap has one Dt (/dt) and one mdt (/mdt)' },
        { '^Idle_Kite', 'idle modes for kiting: /kite wears Movement' },
        { '^Bestial Loyalty_', 'jug pets by its JugMode: put the jug you use in Bestial Loyalty / Call Beast' },
        { '^Call Beast_', 'jug pets by its JugMode: put the jug you use in Bestial Loyalty / Call Beast' } }
    local LIGHT = { "cures in Light day or weather (GoomSwap's CureObi puts the obi on)" }
    local IDLEDT = { '/dt and /mdt put Dt and mdt over idle' }
    local PROC = { 'proc modes (/proc wears Proc engaged, Ws_Proc on a weapon skill)' }
    local SPELLTH = { "spells' TH versions (/th puts the TH set on over a spell's set)" }
    local DWV = { "dual wield versions of action sets: GoomSwap's dual wield set is engaged only (Tp_DW)" }
    -- named sets GoomSwap wears under its own name (latent_refresh: idle under 51% MP is the auto Idle_Refresh);
    -- left out when the file has that set already
    local RENAME = { Self_Refresh = 'Refresh_Self', Self_Healing = 'Cure_Self', latent_refresh = 'Idle_Refresh',
        MagicBurst = 'Elemental Magic_Burst', IntEnfeebles = 'Int_Enfeebling', MndEnfeebles = 'Mind_Enfeebling',
        Preshot_Flurry = 'Preshot_FlurryI', Preshot_Flurry2 = 'Preshot_FlurryII' }
    out.mirdain = mirdain
    if mirdain then -- Selindrile's names: none of these
        G.MirdainPost(out, modes)
        DROP, SKIPPED, RENAME = {}, {}, {}
    end
    local hasMdt = false -- sets.defense.MDT: /mdt wears it, MEVA left out
    for _, n in ipairs(out.order) do
        if string.lower(tostring(out.from[n] or '')) == 'defense.mdt' then hasMdt = true end
    end
    local left, byWhy, whyOrder, renamedTo = {}, {}, {}, {}
    for _, n in ipairs(out.order) do
        local from = string.lower(tostring(out.from[n] or ''))
        local d = DROP[n] or DROP[string.match(n, '^([^_]+)_') or '']
        if (d == nil) and hasMdt and (from == 'defense.meva') then
            d = { 'magic evasion: /mdt wears the file\'s MDT set' }
        end
        if (d == nil) and (string.match(n, '^LightDay') or string.match(n, '^LightWeather')
            or string.match(n, '^MeleeLight')) then d = LIGHT end
        local dw = string.match(n, '_DW$') or string.find(n, '_DW_', 1, true)
        if (d == nil) and dw and not string.match(n, '^Tp_') then d = DWV end
        if (d == nil) and string.match(n, '_TH$') and (string.sub(from, 1, 8) == 'midcast.') then d = SPELLTH end
        for _, sk in ipairs(SKIPPED) do
            if (d == nil) and string.find(n, sk[1]) then d = { sk[2] } end
        end
        if (d == nil) and not mirdain and string.match(n, '^Idle_[PM]?DT') then
            d = IDLEDT
        end
        local cast = string.match(from, '^precast') or string.match(from, '^midcast') -- WS, spells, abilities
        if (d == nil) and cast and string.match(n, '_Proc$') and (n ~= 'Ws_Proc') then d = PROC end -- Ws_Proc: /proc's
        if (d == nil) and (RENAME[n] ~= nil) then
            if out.sets[RENAME[n]] ~= nil then d = { 'the file has ' .. RENAME[n] .. ' already' } end
        end
        if d ~= nil then
            local what = 'sets.' .. out.from[n]
            if d[2] then
                local items = {}
                for _, slot in ipairs(SCREEN) do
                    local v = out.sets[n][slot]
                    if v ~= nil then
                        items[#items + 1] = slot .. ' ' .. tostring((type(v) == 'table') and v.Name or v)
                    end
                end
                what = what .. ' (' .. table.concat(items, ', ') .. ')'
            end
            if byWhy[d[1]] == nil then byWhy[d[1]], whyOrder[#whyOrder + 1] = {}, d[1] end
            table.insert(byWhy[d[1]], what)
            out.sets[n], out.from[n] = nil, nil
        elseif RENAME[n] ~= nil then
            local to = RENAME[n]
            renamedTo[#renamedTo + 1] = 'sets.' .. out.from[n] .. ' -> ' .. to
            out.sets[to], out.from[to], out.sets[n], out.from[n] = out.sets[n], out.from[n], nil, nil
            left[#left + 1] = to
        else
            left[#left + 1] = n
        end
    end
    out.order = left
    local bySpell = {}
    -- the engine's own children stay (Elemental Magic_Burst is the magic burst set, not the spell Burst), and the
    -- spell must be of that skill (Blue Magic_Stun is Selindrile's blue magic stuns, not the spell Stun)
    local CHILD = { Burst = true, Self = true, Others = true, Dt = true, Precast = true }
    for i, n in ipairs(out.order) do
        local skill, spell = string.match(n, '^([%a ]-Magic)_(.+)$')
        if (skill == nil) then skill, spell = string.match(n, '^(Ninjutsu)_(.+)$') end
        if (skill == nil) then skill, spell = string.match(n, '^(Singing)_(.+)$') end
        if (spell ~= nil) and not CHILD[spell] and (out.sets[spell] == nil) and G.IsSpell(spell, skill) then
            bySpell[#bySpell + 1] = n .. ' -> ' .. spell
            out.sets[spell], out.from[spell], out.sets[n], out.from[n] = out.sets[n], out.from[n], nil, nil
            out.order[i] = spell
        end
    end
    if #bySpell > 0 then
        out.notes[#out.notes + 1] = 'a skill\'s set for one spell, as that spell\'s set (worn by name): '
            .. table.concat(bySpell, ', ')
    end
    for _, n in ipairs(left) do
        if takenNote[n] ~= nil then out.notes[#out.notes + 1] = takenNote[n] end
    end
    if #renamedTo > 0 then
        out.notes[#out.notes + 1] = 'as GoomSwap names them (Cure_Self: a cure on you; Idle_Refresh: idle, low MP; '
            .. 'Elemental Magic_Burst: a nuke in a skillchain; Int_ / Mind_Enfeebling: the RDM example\'s, by rule): '
            .. table.concat(renamedTo, ', ')
    end
    -- CastingMode SIRD: GoomSwap's SIR is one set over every spell (/sir). The file's midcast one (sets.midcast.SIRD)
    -- becomes it, else the first; the others left out
    local sird, sirdFrom, sirdLeft = nil, nil, {}
    for _, n in ipairs(out.order) do
        if string.find(n, '_SIRD', 1, true) and ((sird == nil) or (n == 'Midcast_SIRD')) then sird = n end
    end
    if (sird ~= nil) and (out.sets.SIR == nil) then
        local keep = {}
        for _, n in ipairs(out.order) do
            if n == sird then
                sirdFrom = 'sets.' .. out.from[n]
                out.sets.SIR, out.from.SIR, out.sets[n], out.from[n] = out.sets[n], out.from[n], nil, nil
                keep[#keep + 1] = 'SIR'
            elseif string.find(n, '_SIRD', 1, true) then
                sirdLeft[#sirdLeft + 1] = n
                out.sets[n], out.from[n] = nil, nil
            else
                keep[#keep + 1] = n
            end
        end
        out.order = keep
        out.notes[#out.notes + 1] = 'CastingMode SIRD: ' .. sirdFrom .. ' -> SIR (/sir, over every spell)'
            .. ((#sirdLeft > 0) and ('; left out: ' .. table.concat(sirdLeft, ', ')) or '')
    end
    for _, w in ipairs(whyOrder) do
        out.notes[#out.notes + 1] = 'left out, put on by the file\'s own code: ' .. table.concat(byWhy[w], ', ')
            .. ': ' .. w
    end
    -- SomeAcc / FullAcc (Selindrile's accuracy steps) fold into Acc, GoomSwap's one (/mset acc, /wsset acc): the
    -- file's own Acc set kept where it has one, else the first of them in the file's order becomes it
    local dropped, renamed, kept = {}, {}, {}
    for _, n in ipairs(out.order) do
        local acc = string.gsub(string.gsub(n, '_[Ss]ome[Aa]cc%f[%W_]', '_Acc'), '_[Ff]ull[Aa]cc%f[%W_]', '_Acc')
        if acc == n then
            kept[#kept + 1] = n
        elseif out.sets[acc] ~= nil then
            dropped[#dropped + 1] = n
            out.sets[n], out.from[n] = nil, nil
        else
            renamed[#renamed + 1] = n .. ' -> ' .. acc
            out.sets[acc], out.from[acc], out.sets[n], out.from[n] = out.sets[n], out.from[n], nil, nil
            kept[#kept + 1] = acc
        end
    end
    out.order = kept
    if (#dropped + #renamed) > 0 then
        out.notes[#out.notes + 1] = 'SomeAcc / FullAcc folded into Acc (/mset acc): ' .. #dropped .. ' left out (an Acc '
            .. 'set there already: ' .. table.concat(dropped, ', ', 1, math.min(#dropped, 6))
            .. ((#dropped > 6) and '...' or '') .. ')'
            .. ((#renamed > 0) and ('; renamed: ' .. table.concat(renamed, ', ')) or '')
    end
    -- Mote's / Selindrile's mode lists, as text (comments dropped): state.Weapons:options('Naegling', ...),
    -- OffenseMode, HybridMode, WeaponskillMode. For the /wm and /mset lists (G.ModeLists) and the notes below.
    local plain = string.gsub(string.gsub(text, '%-%-%[(=*)%[.-%]%1%]', ''), '%-%-[^\n]*', '')
    out.modes = {}
    for _, st in ipairs({ 'Weapons', 'OffenseMode', 'HybridMode', 'WeaponskillMode' }) do
        local args = string.match(plain, 'state%.' .. st .. '%s*:%s*options%s*(%b())')
        if args ~= nil then
            local list = {}
            for _, x in string.gmatch(args, "(['\"])(.-)%1") do list[#list + 1] = x end
            out.modes[st] = list
        end
    end
    if mirdain then -- /mset: TP is Default; /wm: its WeaponMode options, but Unlocked / Locked (weapons left alone)
        local om, wm = {}, {}
        for _, m in ipairs(out.modes.OffenseMode or {}) do
            if string.lower(m) ~= 'tp' then om[#om + 1] = G.MirdainMode(m) end
        end
        local args = string.match(plain, 'state%.WeaponMode%s*:%s*options%s*(%b())') or ''
        for _, x in string.gmatch(args, "(['\"])(.-)%1") do
            if (string.lower(x) ~= 'unlocked') and (string.lower(x) ~= 'locked') then wm[#wm + 1] = nospace(x) end
        end
        -- and the modes its sets have that the options don't (sets.OffenseMode.PDT, sets.Idle.MEVA): /mset ones too
        local have = {}
        for _, m in ipairs(om) do have[string.lower(m)] = true end
        for _, n in ipairs(out.order) do
            local top, k = string.match(out.from[n] or '', '^(%a+)%.([^%.]+)$')
            top = string.lower(top or '')
            if ((top == 'offensemode') or (top == 'idle') or (top == 'ws')) and modes[string.lower(k)]
                and (string.lower(k) ~= 'tp') and not have[string.lower(G.MirdainMode(k))] then
                have[string.lower(G.MirdainMode(k))], om[#om + 1] = true, G.MirdainMode(k)
            end
        end
        -- its starting weapon mode first (Unlocked / Locked: GoomSwap's None, weapons left alone)
        local wstart = string.match(plain, "state%.WeaponMode%s*:%s*set%s*%(%s*['\"]([^'\"]+)")
        if (wstart ~= nil) and ((string.lower(wstart) == 'unlocked') or (string.lower(wstart) == 'locked')) then
            out.modes.KeepNone = true
        elseif wstart ~= nil then
            table.insert(wm, 1, nospace(wstart))
        end
        out.modes.OffenseMode, out.modes.Weapons = om, wm
        local start = string.match(plain, "state%.OffenseMode%s*:%s*set%s*%(%s*['\"]([^'\"]+)")
        out.notes[#out.notes + 1] = "Mirdain's OffenseMode is /mset (TP: Default, ACC: acc, SB: sb), its WeaponMode /wm"
            .. (((start ~= nil) and (string.lower(start) ~= 'tp')) and ("; it starts in " .. start .. ': /mset '
            .. string.lower(G.MirdainMode(start)) .. ' after loading') or '') .. ". Its WS[mode] went over a weapon "
            .. "skill's own set; GoomSwap's Ws_<mode> goes under it (<WS>_<mode>, as WS[ws][mode], over it)"

    end
    -- sets GoomSwap has no moment for, by name: say what to do with them
    local am, wsm, low, pdl = {}, {}, 0, 0
    for _, n in ipairs(out.order) do
        if string.match(n, '^Tp_.*_AM3?$') or string.match(n, '^Tp_AM3?$') then am[#am + 1] = n end
        if not string.match(n, '^Tp_') then
            if string.find(n, '_LowBuff', 1, true) then low = low + 1 end
            if string.find(n, '_PDL', 1, true) then pdl = pdl + 1 end
            if string.match(n, '_Match$') then wsm[#wsm + 1] = n end
        end
    end
    if ((low + pdl) > 0) and not mirdain then
        out.notes[#out.notes + 1] = 'WeaponskillMode sets: ' .. low .. ' UncappedAtt -> _LowBuff (/wsset low), '
            .. pdl .. ' PDL -> _PDL (/wsset pdl)'
    end
    if #am > 0 then
        out.notes[#out.notes + 1] = 'Aftermath engaged sets (' .. table.concat(am, ', ', 1, math.min(#am, 6))
            .. ((#am > 6) and ', ...' or '') .. '): GoomSwap wears these by buff, Buffs_Tp[\'Aftermath: Lv.3\'] '
            .. '(or the level yours used): rename the one you want in /gcedit'
    end
    -- engaged sets of two modes at once (Tp_Acc_DT: OffenseMode Acc + HybridMode DT): /mset is one mode
    local isMode, isWeapon, combos = {}, {}, {}
    for w in pairs(G.MODE_WORDS) do isMode[w] = true end
    for _, st in ipairs({ 'OffenseMode', 'HybridMode' }) do
        for _, m in ipairs(out.modes[st] or {}) do isMode[string.lower(m)] = true end
    end
    isMode.normal = nil
    for _, n in ipairs(out.order) do
        local w = string.match(n, '^Weapon_(.+)$')
        if w then isWeapon[string.lower(w)] = true end
    end
    for _, n in ipairs(out.order) do
        local c = 0
        for t in string.gmatch(string.match(n, '^Tp_(.+)$') or '', '[^_]+') do
            if isMode[string.lower(t)] and not isWeapon[string.lower(t)] then c = c + 1 end
        end
        if c >= 2 then combos[#combos + 1] = n end
    end
    if (#combos > 0) and not mirdain then
        out.notes[#out.notes + 1] = 'not worn, two modes at once (/mset is one): ' .. table.concat(combos, ', ', 1,
            math.min(#combos, 6)) .. ((#combos > 6) and (' and ' .. (#combos - 6) .. ' more') or '') .. '. GoomSwap '
            .. 'layers them: /mset acc + /dt wears Tp_Acc, then Dt over it (empty Dt slots keep Tp_Acc\'s). Copy the '
            .. 'pieces you want into Dt, or delete them'
    end
    if #wsm > 0 then
        out.notes[#out.notes + 1] = #wsm .. ' WS sets for WeaponskillMode Match: GoomSwap\'s WS variants follow /mset '
            .. '(_Acc) already; rename or delete them'
    end
    if #out.idleBuffOrder > 0 then
        out.notes[#out.notes + 1] = 'sets.idle.Weak became Buffs_Idle[\'Weakness\']: worn standing (not engaged) '
            .. 'while Weakness is up, after a raise'
    end
    if #out.buffOrder > 0 then
        out.notes[#out.notes + 1] = 'sets.buff.X became Buffs[\'X\']: worn idle and engaged while X is up. One the '
            .. 'file puts on with an action (sets.buff.Souleater in its WS code) belongs in Buffs_Ws / Buffs_Midcast '
            .. '(/gcedit: its buff row\'s WS / Midcast)'
    end
    -- gear.X a set names but this file never sets (Selindrile's and Mote's keep them in another file): those slots
    -- are left out
    local nogear = {}
    for name in pairs(gearRead) do
        if env.gear[name] == nil then nogear[#nogear + 1] = 'gear.' .. name end
    end
    table.sort(nogear)
    if #nogear > 0 then
        out.notes[#out.notes + 1] = 'not set in this file, their slots left out (in your globals/items file? paste its '
            .. 'gear. lines at the top and /gcimport again): ' .. table.concat(nogear, ', ')
    end
    if #unknown > 0 then
        local names, s = {}, {}
        for _, u in ipairs(unknown) do if not s[u] then s[u], names[#names + 1] = true, u end end
        out.notes[#out.notes + 1] = 'values from code left out: ' .. table.concat(names, ', ')
    end
    return out
end

-- == Item names ==
-- LuAshitacast finds an item by the game's item name (its resource Name, any case: LuAshitacast equip.lua CheckItem),
-- and skips a name it doesn't find without a word. GearSwap also takes the log name (Windower resources' enl:
-- "heathen's sollerets +3" for Heath. Sollerets +3), so files have both. lookup(name): the game's name, or nil. Each
-- set's items are renamed in place; notes list the log names changed and the names the game doesn't know.
function G.FixNames(imported, lookup)
    local changed, unknown, seen, cased, loose = {}, {}, {}, 0, {}
    local function fix(set)
        for slot, v in pairs(set or {}) do
            local name = (type(v) == 'string') and v or ((type(v) == 'table') and v.Name) or nil
            if (type(name) == 'string') and (name ~= 'remove') then
                local real, near = lookup(name)
                if real == nil then
                    if not seen[name] then seen[name] = true; unknown[#unknown + 1] = name end
                elseif real ~= name then
                    if not seen[name] then
                        seen[name] = true
                        if near then loose[#loose + 1] = name .. ' -> ' .. real
                        elseif string.lower(real) == string.lower(name) then cased = cased + 1
                        else changed[#changed + 1] = name .. ' -> ' .. real end
                    end
                    if type(v) == 'string' then set[slot] = real else v.Name = real end
                end
            end
        end
    end
    for _, n in ipairs(imported.order) do fix(imported.sets[n]) end
    for _, b in ipairs(imported.buffOrder) do fix(imported.buffs[b]) end
    for _, b in ipairs(imported.idleBuffOrder or {}) do fix(imported.idleBuffs[b]) end
    local function list(t)
        table.sort(t)
        if #t <= 12 then return table.concat(t, ', ') end
        return table.concat(t, ', ', 1, 12) .. ' and ' .. (#t - 12) .. ' more'
    end
    if #changed > 0 then
        imported.notes[#imported.notes + 1] = #changed .. ' log name' .. ((#changed == 1) and '' or 's')
            .. ' changed to the game\'s item names (LuAshitacast '
            .. 'finds only those): ' .. list(changed)
    end
    if #loose > 0 then
        imported.notes[#imported.notes + 1] = #loose .. ' name' .. ((#loose == 1) and '' or 's')
            .. ' spelled unlike the game (GearSwap never found ' .. ((#loose == 1) and 'it' or 'them')
            .. ' either), written as the one item ' .. ((#loose == 1) and 'it' or 'each') .. ' can be; check: '
            .. list(loose)
    end
    if cased > 0 then
        imported.notes[#imported.notes + 1] = cased .. ' item name' .. ((cased == 1) and '' or 's')
            .. ' written in the game\'s capitals (Nyame helm -> Nyame Helm)'
    end
    if #unknown > 0 then
        imported.notes[#imported.notes + 1] = 'not an item name the game knows (left as is; LuAshitacast will skip it, fix '
            .. 'it in /gcedit): ' .. list(unknown)
    end
    return #changed, cased, #unknown
end

-- A name without the s ending its words (flanchards -> flanchard; Heathen's stays): the game's log names
-- differ from what files write ("heathen's flanchards +3" for Heath. Flanchard +3, "Heathen's flanchard +3" in files).
local function unplural(s) return (string.gsub(string.lower(s), '(%w%w%w)s%f[^%w]', '%1')) end
G.Unplural = unplural

-- Names files spell differently from the game's (none of them a name GearSwap finds either): the one item whose
-- name or log name has the same words, the same +N, and each word the same but for an s ("Heathen's flanchard +3"),
-- a possessive ("Runeist's Coat +3", "Carrier Sash"), a dot ("Theo Duckbills +2"), an abbreviation either way
-- ("Theo. Pant. +2": theophany pantaloons +2) or, in one word of five letters or more, two letters ("Briault":
-- bliaut; "Sybil": sibyl; one letter in a four-letter word). each(fn): fn(name, logName) for every equippable item.
local function words(s)
    s = string.gsub(string.gsub(string.lower(s), "\226\128\153", "'"), "'s%f[%W]", '')
    s = string.gsub(string.gsub(s, "'", ''), '^(%a+) of ', function(q) -- "jug of bubbling carrion broth"
        return ({ jug = true, pair = true, set = true, suit = true })[q] and '' or nil
    end)
    local out = {}
    for w in string.gmatch(s, '%S+') do out[#out + 1] = w end
    local plus = ((#out > 0) and string.match(out[#out], '^[%+%-]%d+$')) and table.remove(out) or ''
    return out, plus
end
local function edit(a, b) -- Levenshtein distance
    if math.abs(#a - #b) > 2 then return 3 end
    local prev = {}
    for j = 0, #b do prev[j] = j end
    for i = 1, #a do
        local cur = { [0] = i }
        for j = 1, #b do
            local cost = (string.byte(a, i) == string.byte(b, j)) and 0 or 1
            cur[j] = math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
        end
        prev = cur
    end
    return prev[#b]
end
-- 0: the same word; 1: the same but for an s, a dot or an abbreviation; 2: two letters apart; nil: not it
local function word_like(a, b)
    local a0, b0 = string.gsub(a, '%.$', ''), string.gsub(b, '%.$', '')
    if a0 == b0 then return 0 end
    if (#a0 >= 2) and string.match(a, '%.$') and (string.sub(b0, 1, #a0) == a0) then return 1 end
    if (#b0 >= 2) and string.match(b, '%.$') and (string.sub(a0, 1, #b0) == b0) then return 1 end
    if unplural(a0) == unplural(b0) then return 1 end
    if string.match(a0, '%d') or string.match(b0, '%d') then return nil end
    local short = math.min(#a0, #b0)
    if (short >= 4) and (edit(a0, b0) <= ((short >= 5) and 2 or 1)) then return 2 end
    return nil
end
function G.ItemMatcher(each)
    local names, logs, byShape = {}, {}, {}
    each(function(n, log)
        names[string.lower(n)] = names[string.lower(n)] or n
        if (type(log) == 'string') and (log ~= '') then logs[string.lower(log)] = logs[string.lower(log)] or n end
        for _, form in ipairs({ n, log }) do
            if (type(form) == 'string') and (form ~= '') then
                local w, plus = words(form)
                local key = #w .. '|' .. plus
                byShape[key] = byShape[key] or {}
                table.insert(byShape[key], { n, w })
            end
        end
    end)
    return function(name)
        local l = string.lower(name)
        if (names[l] or logs[l]) ~= nil then return names[l] or logs[l] end
        local w, plus = words(name)
        local best, found = 3, {}
        for _, c in ipairs(byShape[#w .. '|' .. plus] or {}) do
            local worst, loose = 0, 0
            for i = 1, #w do
                local d = word_like(w[i], c[2][i])
                if d == nil then worst = 9 break end
                if d == 2 then loose = loose + 1 end
                worst = math.max(worst, d)
            end
            if (worst < 9) and (loose <= 1) then
                if worst < best then best, found = worst, {} end
                if worst == best then found[c[1]] = true end
            end
        end
        local only = nil
        for n in pairs(found) do
            if only ~= nil then return nil end -- two items fit: left as is
            only = n
        end
        if only ~= nil then return only, true end
        return nil
    end
end

-- The game's item name for a name or log name, any case (G.FixNames' lookup): every equippable item read once (its
-- Name and LogNameSingular, Ashita SDK IItem), which takes a moment; then G.ItemMatcher's near names.
local function item_lookup()
    local res = AshitaCore:GetResourceManager()
    local look = nil
    return function(name)
        local r = res:GetItemByName(name, 0)
        if (r ~= nil) and (r.Name ~= nil) and (type(r.Name[1]) == 'string')
            and (string.lower(r.Name[1]) == string.lower(name)) then return r.Name[1] end
        look = look or G.ItemMatcher(function(fn)
            for id = 1, 65534 do
                local it = res:GetItemById(id)
                if (it ~= nil) and (it.Slots ~= 0) and (it.Name ~= nil) and (type(it.Name[1]) == 'string') then
                    fn(it.Name[1], (it.LogNameSingular ~= nil) and it.LogNameSingular[1] or nil)
                end
            end
        end)
        return look(name)
    end
end

-- == Writing ==
-- A set as Lua text (one line), slots in the equipment screen's order.
function G.SetText(set, quote, key)
    local parts = {}
    for _, s in ipairs(SCREEN) do
        local v = set[s]
        if v ~= nil then
            local val
            if type(v) == 'string' then
                val = quote(v)
            else
                local f = { 'Name = ' .. quote(v.Name) }
                if v.Augment ~= nil then
                    local a = {}
                    for _, x in ipairs(v.Augment) do a[#a + 1] = quote(x) end
                    f[#f + 1] = 'Augment = { ' .. table.concat(a, ', ') .. ' }'
                end
                if v.Priority ~= nil then f[#f + 1] = 'Priority = ' .. tostring(v.Priority) end
                val = '{ ' .. table.concat(f, ', ') .. ' }'
            end
            parts[#parts + 1] = s .. ' = ' .. val
        end
    end
    return '{ ' .. table.concat(parts, ', ') .. ' }'
end

-- The /wm and /mset modes the imported sets need, added to the example's lists in text: Weapon_<mode>
-- (sets.weapons.X) a /wm mode (gcinclude.WeaponModes), Tp_<mode> and Tp_<weapon>_<mode> an /mset mode
-- (gcinclude.MeleeModes, a line after WeaponModes when the example has none). Without them Tp_Agwu, Tp_FullAcc...
-- are never worn. text: the example after its sets (OnLoad holds the lists); whole: all of it.
function G.ModeLists(text, imported, whole)
    local opts = imported.modes or {}
    local wm, wseen, made = {}, { ['1h'] = true, ['2h'] = true }, {}
    for _, n in ipairs(imported.order) do
        local m = string.match(n, '^Weapon_(%w+)$')
        if m then made[string.lower(m)] = m end
    end
    local function addw(m)
        if (m ~= nil) and not wseen[string.lower(m)] then wseen[string.lower(m)], wm[#wm + 1] = true, m end
    end
    for _, m in ipairs(opts.Weapons or {}) do addw(made[string.lower(m)]) end -- the file's order first
    for _, n in ipairs(imported.order) do addw(string.match(n, '^Weapon_(%w+)$')) end
    local ms, mseen = { }, { default = true, normal = true, am = true, am3 = true, someacc = true, fullacc = true,
        dw = true, fodder = true } -- SomeAcc / FullAcc: Acc; DW: the engine's Tp_DW (dual wielding); Fodder: left out
    -- the file's OffenseMode / HybridMode options when it has them (Normal is Default), else every Tp_ mode
    for _, st in ipairs({ 'OffenseMode', 'HybridMode' }) do
        for _, m in ipairs(opts[st] or {}) do
            if string.match(m, '^%w+$') and not mseen[string.lower(m)] then mseen[string.lower(m)], ms[#ms + 1] = true, m end
        end
    end
    for _, n in ipairs((opts.OffenseMode == nil) and imported.order or {}) do
        local rest = string.match(n, '^Tp_(.+)$')
        local a, b = string.match(rest or '', '^([^_]+)_([^_]+)$')
        local m = nil
        if (a ~= nil) and wseen[string.lower(a)] then m = b
        elseif (rest ~= nil) and not string.find(rest, '_') and not wseen[string.lower(rest)] then m = rest end
        if (m ~= nil) and not mseen[string.lower(m)] then mseen[string.lower(m)], ms[#ms + 1] = true, m end
    end
    local function merge(list, add, base)
        local names, seen = {}, {}
        for _, x in string.gmatch(list or '', "(['\"])(.-)%1") do
            if not seen[string.lower(x)] then seen[string.lower(x)], names[#names + 1] = true, x end
        end
        if #names == 0 then
            for _, x in ipairs(base) do seen[string.lower(x)], names[#names + 1] = true, x end
        end
        local n0 = #names
        for _, x in ipairs(add) do
            if not seen[string.lower(x)] then seen[string.lower(x)], names[#names + 1] = true, x end
        end
        if #names == n0 then return nil end
        local q = {}
        for i, x in ipairs(names) do q[i] = "'" .. x .. "'" end
        return '{' .. table.concat(q, ', ') .. '}'
    end
    local hadMelee = string.find(whole or text, 'gcinclude%.MeleeModes%s*=') ~= nil
    local first = nil -- the GearSwap file's default weapons: its first state.Weapons option with a set
    for _, m in ipairs(opts.Weapons or {}) do
        if (first == nil) and made[string.lower(m)] then first = made[string.lower(m)] end
    end
    if (first ~= nil) and not opts.KeepNone then
        text = string.gsub(text, "(gcinclude%.DefaultWeapons%s*=%s*)(['\"])None%2", "%1'" .. first .. "'", 1)
    end
    text = string.gsub(text, '(gcinclude%.MeleeModes%s*=%s*T?)(%b{})', function(pre, list)
        local new = merge(list, ms, { 'Default' })
        return pre .. (new or list)
    end, 1)
    text = string.gsub(text, '([ \t]*)(gcinclude%.WeaponModes%s*=%s*T?)(%b{})([^\n]*)', function(ind, pre, list, after)
        local new = merge(list, wm, { 'None' })
        local line = ind .. pre .. (new or list) .. after
        local melee = (not hadMelee) and merge('', ms, { 'Default', 'SubtleBlow', 'Acc' }) or nil
        if melee ~= nil then
            line = line .. '\n' .. ind .. 'gcinclude.MeleeModes = ' .. melee
                .. '; -- /mset modes, from the GearSwap file\'s engaged sets'
        end
        return line
    end, 1)
    return text
end

-- template: the job's example (its handlers and options are kept; its sets are replaced). The draft's text, and
-- counts { sets, empty, buffs }.
function G.Draft(template, imported, info, setFile)
    local model, err = setFile.Parse(template)
    if model == nil then return nil, err end
    -- Selindrile's CastingMode Resistant (magic accuracy): the example's /nukeset Macc set for that skill (a rule
    -- with mode = { nukeset = 'Macc' }, skill = 'Elemental Magic' wearing NukeACC), else left out
    -- the example's own name for a set Selindrile names otherwise (WHM: erase, Self_Cure, Self_Refresh; BLU: its
    -- Blue Magic sets), when the example has that set and the file doesn't
    local has = {}
    for _, set in ipairs(model.list) do has[set.name] = true end
    local PREFER = { { 'Cure_Self', 'Self_Cure' }, { 'Refresh_Self', 'Self_Refresh' }, { 'StatusRemoval', 'erase' },
        { 'Blue Magic_Physical', 'BluPhysical' }, { 'Blue Magic_Magical', 'BluMagical' },
        { 'Blue Magic_MagicAccuracy', 'BluMagicAccuracy' }, { 'Blue Magic_Stun', 'BluStun' },
        { 'Blue Magic_Buff', 'CMP' }, { 'Blue Magic_SkillBasedBuff', 'BluSkill' }, { 'Blue Magic_Healing', 'Cure' },
        { 'PetAction', 'BloodPact' }, { 'BluCure', 'Cure' }, { 'BluEnmity', 'Enmity' } } -- Mirdain's: SMN, BLU
    local preferred = {}
    -- Mirdain's BRD: its Midcast.Enfeebling is for enfeebling songs, the example's Wind
    if imported.mirdain then PREFER[#PREFER + 1] = { 'Enfeebling Magic', 'Wind' } end
    for _, pr in ipairs(PREFER) do
        local from, to = pr[1], pr[2]
        if (imported.sets[from] ~= nil) and (imported.sets[to] == nil) and has[to] then
            imported.sets[to], imported.from[to], imported.sets[from] = imported.sets[from], imported.from[from], nil
            for i, n in ipairs(imported.order) do if n == from then imported.order[i] = to end end
            preferred[#preferred + 1] = from .. ' -> ' .. to
        end
    end
    if #preferred > 0 then
        imported.notes[#imported.notes + 1] = 'as the example names them: ' .. table.concat(preferred, ', ')
    end
    -- Selindrile's sets.RecoverMP (nukes under an MP %): the example's Mp_Body, worn by its rule (BLM), if it has one
    -- (Mirdain's sample BLM: sets.MP_Recover)
    local mpBody = string.find(template, "wear%s*=%s*'Mp_Body'")
    for _, mp in ipairs({ 'RecoverMP', 'MP_Recover' }) do
        if (imported.sets[mp] ~= nil) and (imported.sets.Mp_Body == nil) and mpBody then
            imported.sets.Mp_Body, imported.from.Mp_Body, imported.sets[mp] = imported.sets[mp], imported.from[mp], nil
            for i, n in ipairs(imported.order) do if n == mp then imported.order[i] = 'Mp_Body' end end
            imported.notes[#imported.notes + 1] = 'sets.' .. imported.from.Mp_Body .. ' -> Mp_Body (the example\'s: '
                .. 'nukes at low MP)'
        end
    end
    -- Selindrile's sets.midcast.Lullaby: the example's Foe Lullaby set (BRD's rules wear Foe / Horde), if it has one
    if (imported.sets.Lullaby ~= nil) and (imported.sets.Foe == nil) and string.find(template, "wear%s*=%s*'Foe'") then
        imported.sets.Foe, imported.from.Foe, imported.sets.Lullaby = imported.sets.Lullaby, imported.from.Lullaby, nil
        for i, n in ipairs(imported.order) do if n == 'Lullaby' then imported.order[i] = 'Foe' end end
        imported.notes[#imported.notes + 1] = 'sets.midcast.Lullaby -> Foe (the example\'s Foe Lullaby set; Horde '
            .. 'Lullaby wears Horde)'
    end
    local macc, folded, gone = {}, {}, {}
    for skill, set in string.gmatch(template, "nukeset%s*=%s*'Macc'%s*}%s*,%s*skill%s*=%s*'([^']+)'%s*}%s*,%s*wear%s*="
        .. "%s*'([^']+)'") do macc[string.lower(skill)] = set end
    local order = {}
    for _, n in ipairs(imported.order) do
        local base = string.match(n, '^(.+)_[Rr]esistant$')
        local to = (base ~= nil) and macc[string.lower(base)] or nil
        if (base ~= nil) and (to ~= nil) and (imported.sets[to] == nil) then
            folded[#folded + 1] = n .. ' -> ' .. to
            imported.sets[to], imported.from[to], imported.sets[n] = imported.sets[n], imported.from[n], nil
            order[#order + 1] = to
        elseif base ~= nil then
            gone[#gone + 1] = n
            imported.sets[n] = nil
        else
            order[#order + 1] = n
        end
    end
    imported.order = order
    if (#folded + #gone) > 0 then
        imported.notes[#imported.notes + 1] = 'CastingMode Resistant: ' .. ((#folded > 0) and ('worn on /nukeset macc: '
            .. table.concat(folded, ', ') .. (#gone > 0 and '; ' or '')) or '') .. ((#gone > 0) and ('left out: '
            .. table.concat(gone, ', ')) or '')
    end
    local quote, key = setFile.QuoteText, setFile.FormatKey
    local lines, done, counts = {}, {}, { sets = 0, empty = 0, buffs = 0 }
    -- the buff tables: Buffs (sets.buff.X), Buffs_Idle (sets.idle.Weak)
    local BUFFS = { Buffs = { imported.buffOrder, imported.buffs, ' -- while the buff is up: idle and engaged' },
        Buffs_Idle = { imported.idleBuffOrder or {}, imported.idleBuffs or {},
            ' -- while the buff is up, not engaged' } }
    local function buff_table(name)
        local b = BUFFS[name]
        lines[#lines + 1] = '    ' .. name .. ' = {' .. b[3]
        for _, buff in ipairs(b[1]) do
            lines[#lines + 1] = '        ' .. key(buff) .. ' = ' .. G.SetText(b[2][buff], quote, key) .. ','
            counts.buffs = counts.buffs + 1
        end
        lines[#lines + 1] = '    },'
    end
    lines[#lines + 1] = '{'
    for _, set in ipairs(model.list) do
        if (set.parentName == nil) and not done[set.name] then
            done[set.name] = true
            if (BUFFS[set.name] ~= nil) and ((set.name == 'Buffs') or (#BUFFS[set.name][1] > 0)) then
                buff_table(set.name)
            elseif imported.sets[set.name] ~= nil then
                lines[#lines + 1] = '    ' .. key(set.name) .. ' = ' .. G.SetText(imported.sets[set.name], quote, key)
                    .. ', -- sets.' .. imported.from[set.name]
                counts.sets = counts.sets + 1
            elseif string.match(set.name, '^Buffs_') then
                lines[#lines + 1] = '    ' .. key(set.name) .. ' = {},'
            else
                lines[#lines + 1] = '    ' .. key(set.name) .. ' = {}, -- not in the GearSwap file'
                counts.empty = counts.empty + 1
            end
        end
    end
    local extra = {}
    for _, name in ipairs(imported.order) do
        if not done[name] then extra[#extra + 1] = name end
    end
    if #extra > 0 then
        lines[#lines + 1] = ''
        lines[#lines + 1] = '    -- From the GearSwap file, by names this example has no set for (rename them in /gcedit):'
        for _, name in ipairs(extra) do
            lines[#lines + 1] = '    ' .. key(name) .. ' = ' .. G.SetText(imported.sets[name], quote, key) .. ', -- sets.'
                .. imported.from[name]
            counts.sets = counts.sets + 1
        end
    end
    for _, name in ipairs({ 'Buffs', 'Buffs_Idle' }) do -- the example has no such table: added last
        if (not done[name]) and (#BUFFS[name][1] > 0) then buff_table(name) end
    end
    lines[#lines + 1] = '}'
    local after = G.GroupRules(G.ModeLists(string.sub(template, model.close + 1), imported, template), imported,
        template)
    local text = string.sub(template, 1, model.open - 1)
    local head = { '-- Imported from ' .. tostring(info.file) .. ' (GearSwap) by /gcimport on ' .. tostring(info.date) .. ': '
        .. counts.sets .. ' sets, ' .. counts.buffs .. ' buff sets. Its logic (states, functions, binds) is not',
        '-- imported: add what you need as rules in /gcedit (RULES). Sets this example has and the file did not are empty.' }
    for _, n in ipairs(imported.notes) do head[#head + 1] = '-- ' .. n end
    text = table.concat(head, '\n') .. '\n' .. text .. table.concat(lines, '\n') .. after
    return text, counts
end

-- Selindrile's spell groups (its spellMap: sets.midcast.StatusRemoval for every -na spell and Erase) that no spell
-- family covers: the draft gets a Midcast rule wearing each one the file has, unless the example wears it already.
-- nameset = false: a spell with a set of its own wears that one, as Selindrile's sets.midcast[spell] comes first.
local SPELL_GROUPS = {
    { 'StatusRemoval', "{ 'Poisona', 'Paralyna', 'Silena', 'Blindna', 'Cursna', 'Stona', 'Viruna', 'Erase' }" },
    { 'BarElement', "{ 'Barfire', 'Barblizzard', 'Baraero', 'Barstone', 'Barthunder', 'Barwater', 'Barfira', "
        .. "'Barblizzara', 'Baraera', 'Barstonra', 'Barthundra', 'Barwatera' }" },
    { 'BarStatus', "{ 'Barsleep', 'Barpoison', 'Barparalyze', 'Barblind', 'Barsilence', 'Barpetrify', 'Barvirus', "
        .. "'Baramnesia', 'Barsleepra', 'Barpoisonra', 'Barparalyzra', 'Barblindra', 'Barsilencera', 'Barpetra', "
        .. "'Barvira', 'Baramnesra' }" },
    { 'ElementalEnfeeble', "{ 'Burn', 'Frost', 'Choke', 'Rasp', 'Shock', 'Drown' }" },
    { 'Helix', "{ has = 'helix' }" },
    { 'Storm', "{ 'Firestorm', 'Hailstorm', 'Windstorm', 'Sandstorm', 'Thunderstorm', 'Rainstorm', 'Aurorastorm', "
        .. "'Voidstorm', 'Firestorm II', 'Hailstorm II', 'Windstorm II', 'Sandstorm II', 'Thunderstorm II', "
        .. "'Rainstorm II', 'Aurorastorm II', 'Voidstorm II' }" },
    { 'ElementalNinjutsu', "{ 'Katon: Ichi', 'Katon: Ni', 'Katon: San', 'Hyoton: Ichi', 'Hyoton: Ni', 'Hyoton: San', "
        .. "'Huton: Ichi', 'Huton: Ni', 'Huton: San', 'Doton: Ichi', 'Doton: Ni', 'Doton: San', 'Raiton: Ichi', "
        .. "'Raiton: Ni', 'Raiton: San', 'Suiton: Ichi', 'Suiton: Ni', 'Suiton: San' }" },
    { 'Enspell', "{ 'Enfire', 'Enblizzard', 'Enaero', 'Enstone', 'Enthunder', 'Enwater', 'Enfire II', 'Enblizzard II', "
        .. "'Enaero II', 'Enstone II', 'Enthunder II', 'Enwater II' }" },
    { 'BoostStat', "{ 'Boost-STR', 'Boost-DEX', 'Boost-VIT', 'Boost-AGI', 'Boost-INT', 'Boost-MND', 'Boost-CHR', "
        .. "'Gain-STR', 'Gain-DEX', 'Gain-VIT', 'Gain-AGI', 'Gain-INT', 'Gain-MND', 'Gain-CHR' }" },
    { 'Lullaby', "{ 'Foe Lullaby', 'Foe Lullaby II', 'Horde Lullaby', 'Horde Lullaby II' }" },
}
-- Sets Selindrile's code puts on that no GoomSwap name does: a rule each, as the code reads (Int / Mind_Enfeebling:
-- the RDM example's own rules; element_Dark: its is_nuke, dark; RecoverMP: GoomSwap's BLM Mp_Body rule).
local SET_RULES = {
    { 'Int_Enfeebling', "{ on = 'Midcast', when = { skill = 'Enfeebling Magic', name = { has = 'Poison' }, nameset = "
        .. "false }, wear = 'Int_Enfeebling' }," },
    { 'Mind_Enfeebling', "{ on = 'Midcast', when = { skill = 'Enfeebling Magic', name = { has = { 'Paralyze', 'Slow', "
        .. "'Addle' } }, nameset = false }, wear = 'Mind_Enfeebling' }," },
    { 'element_Dark', "{ on = 'Midcast', when = { element = 'Dark', name = { isnt = 'Impact' }, any = { { skill = "
        .. "'Elemental Magic' }, { name = { has = { 'Drain', 'Aspir' } } } } }, wear = 'element_Dark' }," },
    { 'RecoverMP', "{ on = 'Midcast', when = { skill = 'Elemental Magic', mpp = { le = 40 } }, wear = 'RecoverMP' }," },
    { 'Self_Waltz', "{ on = 'Ability', when = { name = { start = 'Curing Waltz' }, target = 'me' }, wear = "
        .. "'Self_Waltz' }," },
    -- its WHM's cure map: CureSolace under Afflatus Solace; Melee ones while a weapon mode is set (/wm)
    { 'CureSolace', "{ on = 'Midcast', when = { family = 'Cure', buff = 'Afflatus Solace' }, wear = 'CureSolace' }," },
    { 'MeleeCure', "{ on = 'Midcast', when = { family = 'Cure', mode = { wm = { isnt = 'None' } } }, wear = "
        .. "'MeleeCure' }," },
    { 'MeleeCureSolace', "{ on = 'Midcast', when = { family = 'Cure', buff = 'Afflatus Solace', mode = { wm = { isnt "
        .. "= 'None' } } }, wear = 'MeleeCureSolace' }," },
}
function G.GroupRules(text, imported, template)
    local rules, names = {}, {}
    local function add(set, line)
        if (imported.sets[set] ~= nil) and not string.find(template, "wear%s*=%s*'" .. set .. "'") then
            rules[#rules + 1] = '        ' .. line
            names[#names + 1] = set
        end
    end
    for _, g in ipairs(SPELL_GROUPS) do
        add(g[1], "{ on = 'Midcast', when = { name = " .. g[2] .. ", nameset = false }, wear = '" .. g[1] .. "' },")
    end
    for _, r in ipairs(SET_RULES) do add(r[1], r[2]) end
    -- Mirdain's (G.MirdainPost); a loose one not when the example names the set at all
    for _, r in ipairs(imported.rules or {}) do
        if not (r[3] and string.find(template, "'" .. r[1] .. "'", 1, true)) then add(r[1], r[2]) end
    end
    for _, n in ipairs(imported.order) do -- an ability's DT version (Berserk_DT): Selindrile's DefenseMode, /dt here
        local ja = string.match(n, '^(.+)_DT$')
        if (ja ~= nil) and string.match(string.lower(imported.from[n] or ''), '^precast%.ja%.') then
            add(n, "{ on = 'Ability', when = { name = '" .. ja .. "', toggle = { dt = true } }, wear = '" .. n
                .. "' },")
        end
    end
    for _, n in ipairs(imported.order) do -- a weapon skill's TH version (Aeolian Edge_TH): with /th on
        local ws = string.match(n, '^(.+)_TH$')
        if (ws ~= nil) and string.match(string.lower(imported.from[n] or ''), '^precast%.ws') then
            add(n, "{ on = 'Weaponskill', when = { name = '" .. ws .. "', toggle = { th = true } }, wear = '" .. n
                .. "' },")
        end
    end
    if #rules == 0 then return text end
    local at = string.find(text, 'gcinclude%.Rules%s*=%s*{')
    local eol = (at ~= nil) and string.find(text, '\n', at, true) or nil
    if eol == nil then
        imported.notes[#imported.notes + 1] = 'spell group sets no rule wears yet (add one in /gcedit RULES): '
            .. table.concat(names, ', ')
        return text
    end
    imported.notes[#imported.notes + 1] = 'sets the file\'s code puts on, worn by a rule each (RULES, at the top): '
        .. table.concat(names, ', ')
    return string.sub(text, 1, eol) .. "        -- /gcimport: sets the file's code puts on (spell groups: unless "
        .. 'the spell has a set of its own)\n' .. table.concat(rules, '\n') .. '\n' .. string.sub(text, eol + 1)
end

-- Selindrile's layout: <Char>_<Job>_Gear.lua takes its augmented gear (gear.X) from <Char>-Items.lua beside it. Its
-- text and file name, or nil. open: io.open.
function G.ItemsFile(path, open)
    local dir, char = string.match(path or '', '^(.*[\\/])([^\\/_]+)_[^\\/]*$')
    if dir == nil then return nil end
    local f = open(dir .. char .. '-Items.lua', 'rb')
    if f == nil then return nil end
    local t = f:read('*a')
    f:close()
    return t, char .. '-Items.lua'
end

-- == /gcimport <file> [JOB] ==
local JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN',
    'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }
local IS_JOB = {}
for i, j in ipairs(JOBS) do IS_JOB[j] = i end
-- The job a file is for: Name_WAR.lua, WAR.lua, war_gear.lua...
function G.JobOf(file)
    local base = string.upper(string.match(file or '', '([^\\/]+)$') or '')
    for word in string.gmatch(base, '%u+') do
        if IS_JOB[word] then return word end
    end
    return nil
end
-- args: the command's words after /gcimport. Writes <JOB>.proposed.lua in the character's folder (as /gcbuild does).
-- Returns the job, the draft's path and the folder when it was written.
function G.Run(args, say, err, setFile)
    local words = {}
    for _, a in ipairs(args or {}) do words[#words + 1] = tostring(a) end
    local job = nil
    if (#words > 1) and IS_JOB[string.upper(words[#words])] then job = string.upper(table.remove(words)) end
    local name = table.concat(words, ' ')
    if name == '' then
        err('/gcimport <file> [JOB]: a GearSwap job file. Put it in your character\'s luashitacast folder (or give '
            .. 'its whole path): /gcimport Name_WAR.lua')
        return
    end
    if not string.match(name, '%.lua$') then name = name .. '.lua' end
    local root = AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\'
    local dir = string.format('%s%s_%u\\', root, gState.PlayerName, gState.PlayerId)
    local tries = string.match(name, '^%a:[\\/]') and { name } or { dir .. name, root .. name, root .. 'gearswap\\' .. name }
    local f, path = nil, nil
    for _, p in ipairs(tries) do
        f = io.open(p, 'rb')
        if f ~= nil then path = p break end
    end
    if f == nil then err('/gcimport: no ' .. name .. ' in your character\'s folder or luashitacast\\.') return end
    local text = f:read('*a')
    f:close()
    local items, itemsName = G.ItemsFile(path, io.open) -- its gear.X tables
    job = job or G.JobOf(name) or JOBS[AshitaCore:GetMemoryManager():GetPlayer():GetMainJob()]
    if job == nil then err('/gcimport: which job? /gcimport ' .. name .. ' WAR') return end
    local imported, why = G.Import(text, items)
    if imported == nil then err('/gcimport: ' .. tostring(why)) return end
    if items ~= nil then imported.notes[#imported.notes + 1] = 'gear.X read from ' .. itemsName .. ' beside it' end
    if #imported.order + #imported.buffOrder + #imported.idleBuffOrder == 0 then
        err('/gcimport: no sets found in ' .. name .. '.')
        return
    end
    local okNames, whyNames = pcall(G.FixNames, imported, item_lookup())
    if not okNames then
        imported.notes[#imported.notes + 1] = 'item names not checked against the game (' .. tostring(whyNames) .. ')'
    end
    local ef = io.open(root .. 'examples\\' .. job .. '.lua', 'rb')
    if ef == nil then err('/gcimport: no luashitacast\\examples\\' .. job .. '.lua: copy GoomSwap\'s examples folder there.') return end
    local template = ef:read('*a')
    ef:close()
    local draft, counts = G.Draft(template, imported, { file = string.match(path, '[^\\/]+$'), date = os.date('%Y-%m-%d') }, setFile)
    if draft == nil then err('/gcimport: ' .. tostring(counts)) return end
    local file = job .. '.proposed.lua'
    local out = io.open(dir .. file, 'wb')
    if out == nil then err('/gcimport: cannot write ' .. file) return end
    out:write(draft)
    out:close()
    say(string.format('%s written from %s: %d sets, %d buff sets%s. Its GearSwap logic is not imported: add rules in /gcedit.',
        file, name, counts.sets, counts.buffs, (#imported.notes > 0) and (' (' .. #imported.notes .. ' notes at its top)') or ''))
    return job, dir .. file, dir
end

return G
