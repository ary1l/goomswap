-- Shared gear engine and lifecycle.
local gcinclude = T{}
local enchantRuntime, equippedId
function gcinclude.Relay(msg, isErr) -- also shown on the box with the HUD open (gchud)
    if (gchud ~= nil) and (gchud.Relay ~= nil) then pcall(gchud.Relay, msg, isErr) end
end
function gcinclude.Say(msg) print(chat.header('GoomSwap'):append(chat.message(msg))); gcinclude.Relay(msg, false) end
function gcinclude.Err(msg) print(chat.header('GoomSwap'):append(chat.error(msg))); gcinclude.Relay(msg, true) end
function gcinclude.Queue(cmd) AshitaCore:GetChatManager():QueueCommand(-1, cmd) end -- a chat command, as typed

local runtime = gFunc.LoadFile('common\\gcruntime.lua')
runtime.Settings.Install(gcinclude)
gcdisplay = gFunc.LoadFile('common\\gcdisplay.lua')
gcauto = runtime.NewAuto()
gcaction = gFunc.LoadFile('common\\gcaction.lua')
gcauto.Bind(gcinclude) -- bound now, not in SetVariables: the handlers are wrapped at
gcaction.Bind(gcinclude) -- Initialize, before InitStep's player wait ends (/item then hit a nil 'inc')
local gcpackerlist = gFunc.LoadFile('common\\gcpackerlist.lua') -- what /lac gear (Packer plugin) gets on top of the sets
local gcrules = gFunc.LoadFile('common\\gcrules.lua') -- gcinclude.Rules: the job file's conditions as data
local hudOk, hudModule = pcall(gFunc.LoadFile, 'common\\gchud.lua')
if (hudOk == true) and (type(hudModule) == 'table') then
    gchud = hudModule
else
    gchud = nil
    gcinclude.Err('HUD disabled: gchud.lua failed to load.')
end
local gearOk, gearModule = pcall(gFunc.LoadFile, 'common\\gcgear.lua') -- /gcgear, the worn-gear grid
if (gearOk == true) and (type(gearModule) == 'table') then
    gcgear = gearModule
else
    gcgear = nil
    gcinclude.Err('Gear grid disabled: gcgear.lua failed to load: ' .. tostring(gearModule))
end

gcinclude.AliasList = T{'gcmessages','wsdistance','dt','mdt','th','kite','mset','wsset','nukeset','burst','weapon',
    'death','sir','tankset','proc','pupmode','wm','mw','sw','rw','ammoset','aminon','gchud','lock','unlock',
    'hoxne','gchelp','gckey','def','gce','checksets','gcperf','smartswap','autogear','gcbar','forcestring','songlock',
    'siphon','warpring','mea','holla','dem','capacity','jubilee','abyproc','dw','dynamisrp','gcbuild','gcimport','gcedit',
    'gcconfig','idleset','gcgear'}
-- Exit/use-on-self items: key = /command, value = exact /item name. Add a line, /lac reload.
gcinclude.ExitItems = { ontic = 'ontic extremity', shard = 'v. con. shard', }
for k in pairs(gcinclude.ExitItems) do
    if not gcinclude.AliasList:contains(k) then table.insert(gcinclude.AliasList, k) end
end
gcinclude.Towns = T{'Tavnazian Safehold','Aht Urhgan Whitegate','Nashmau','Southern San d\'Oria [S]',
    'Bastok Markets [S]','Windurst Waters [S]','San d\'Oria-Jeuno Airship','Bastok-Jeuno Airship',
    'Windurst-Jeuno Airship','Kazham-Jeuno Airship','Southern San d\'Oria','Northern San d\'Oria','Port San d\'Oria',
    'Chateau d\'Oraguille','Bastok Mines','Bastok Markets','Port Bastok','Metalworks','Windurst Waters',
    'Windurst Walls','Port Windurst','Windurst Woods','Heavens Tower','Ru\'Lude Gardens','Upper Jeuno','Lower Jeuno',
    'Port Jeuno','Rabao','Selbina','Mhaura','Kazham','Norg','Mog Garden','Celennia Memorial Library','Western Adoulin',
    'Eastern Adoulin'}
gcinclude.LockingRings = T{'Echad Ring', 'Trizek Ring', 'Endorsement Ring', 'Capacity Ring', 'Warp Ring',
    'Facility Ring','Dim. Ring (Dem)','Dim. Ring (Mea)','Dim. Ring (Holla)'}
-- Archery / Marksmanship weapon skills: they take ammo (CheckBlockedAmmoWS); range 20 (WsRanges)
gcinclude.DistanceWS = T{'Flaming Arrow','Piercing Arrow','Dulling Arrow','Sidewinder','Blast Arrow','Arching Arrow',
    'Empyreal Arrow','Refulgent Arrow','Apex Arrow','Namas Arrow','Jishnu\'s Radiance','Hot Shot','Split Shot',
    'Sniper Shot','Slug Shot','Blast Shot','Heavy Shot','Detonator','Numbing Shot','Last Stand','Coronach','Wildfire',
    'Trueflight','Leaden Salute','Sarv','Terminus'}
-- On yourself (LandSandBoat data/weapon_skills.yaml target: [self]): no distance check
gcinclude.SelfWS = T{'Myrkr','Dagan','Moonlight','Starlight'}
gcinclude.BluMagDebuff = T{'Filamented Hold','Cimicine Discharge','Demoralizing Roar','Venom Shell','Light of Penance',
    'Sandspray','Auroral Drape','Frightful Roar','Enervation','Infrasonics','Lowing','Cold Wave','Awful Eye',
    'Voracious Trunk','Sheep Song','Soporific','Yawn','Dream Flower','Chaotic Eye','Sound Blast','Blank Gaze',
    'Stinking Gas','Geist Wall','Feather Tickle','Reaving Wind','Mortal Ray','Absolute Terror',
    'Blistering Roar','Cruel Joke'}
gcinclude.BluMagPhysical = T{'Foot Kick','Power Attack','Sprout Smack','Wild Oats','Queasyshroom','Battle Dance',
    'Head Butt','Feather Storm','Helldive','Bludgeon','Claw Cyclone','Screwdriver','Grand Slam','Smite of Rage',
    'Pinecone Bomb','Jet Stream','Uppercut','Terror Touch','Mandibular Bite','Sickle Slash','Death Scissors',
    'Dimensional Death','Spiral Spin','Seedspray','Body Slam','Spinal Cleave','Frenetic Rip','Frypan','Hydro Shot',
    'Tail Slap','Hysteric Barrage','Cannonball','Asuran Claws','Disseverment','Sub-zero Smash','Ram Charge',
    'Vertical Cleave','Final Sting','Goblin Rush','Vanity Dive','Whirl of Rage','Benthic Typhoon','Quad. Continuum',
    'Empty Thrash','Delta Thrust','Heavy Strike','Sudden Lunge','Quadrastrike','Tourbillion','Amorphic Spikes',
    'Barbed Crescent','Paralyzing Triad','Glutinous Dart','Thrashing Assault','Sinker Drill','Sweeping Gouge',
    'Saurian Slide','Bilgestorm','Bloodrake'}
gcinclude.BluMagStun = T{'Head Butt','Frypan','Tail Slap','Sub-zero Smash','Sudden Lunge'}
gcinclude.BluMagBuff = T{'Cocoon','Refueling','Feather Barrier','Memento Mori','Zephyr Mantle','Warm-Up',
    'Amplification','Triumphant Roar','Saline Coat','Reactor Cool','Plasma Charge','Regeneration','Animating Wail',
    'Battery Charge','Winds of Promy.','Barrier Tusk','Orcish Counterstance','Pyric Bulwark','Nat. Meditation',
    'Restoral','Erratic Flutter','Carcharian Verve','Harden Shell','Mighty Guard'}
gcinclude.BluMagSkill = T{'Metallic Body','Diamondhide','Magic Barrier','Occultation','Atra. Libations'}
gcinclude.BluMagCure = T{'Pollen','Healing Breeze','Wild Carrot','Magic Fruit','Plenilune Embrace'}
gcinclude.BluMagEnmity = T{'Actinic Burst','Exuviation','Fantod','Jettatura','Temporal Shift'}
gcinclude.BluMagTH = T{'Actinic Burst','Dream Flower','Subduction'}
gcinclude.HelixSpells = T{'Ionohelix', 'Cryohelix', 'Pyrohelix', 'Geohelix', 'Anemohelix', 'Hydrohelix',
    'Luminohelix', 'Noctohelix'}
gcinclude.Rolls = T{{'Fighter\'s Roll',5,9}, {'Monk\'s Roll',3,7}, {'Healer\'s Roll',3,7}, {'Corsair\'s Roll',5,9},
    {'Ninja Roll',4,8},{'Hunter\'s Roll',4,8}, {'Chaos Roll',4,8}, {'Magus\'s Roll',2,6}, {'Drachen Roll',4,8},
    {'Choral Roll',2,6},{'Beast Roll',4,8}, {'Samurai Roll',2,6}, {'Evoker\'s Roll',5,9}, {'Rogue\'s Roll',5,9},
    {'Warlock\'s Roll',4,8},
    {'Puppet Roll',3,7}, {'Gallant\'s Roll',3,7}, {'Wizard\'s Roll',5,9}, {'Dancer\'s Roll',3,7}, {'Scholar\'s Roll',2,
        6},{'Naturalist\'s Roll',3,7}, {'Runeist\'s Roll',4,8}, {'Bolter\'s Roll',3,9}, {'Caster\'s Roll',2,7},
        {'Courser\'s Roll',3,9},{'Blitzer\'s Roll',4,9}, {'Tactician\'s Roll',5,8}, {'Allies\' Roll',3,10},
        {'Miser\'s Roll',5,7},
    {'Companion\'s Roll',2,10},{'Avenger\'s Roll',4,8},} -- {name,lucky,unlucky}
gcinclude.HardCC = T{'Sleep', 'Petrification', 'Stun', 'Terror', 'Charm'} -- can't act (gcauto, gcaction, WS bailout)
gcinclude.CORmsg = true

gcinclude.DefenseCycle = T{ {'DTset','DT'}, {'MDTset','MDT'}, {'Aminon','Aminon'} }

-- gData.GetEquipSlot lowercases all 16 slot names and the key on every call (LAC data.lua); EquipSet runs
-- through it for every key while Hoxne is on, so each name is resolved once. Same result for every key.
local slotNum = {}
local function slotOf(k)
    if (type(k) ~= 'string') then return gData.GetEquipSlot(k) end
    local n = slotNum[k]
    if (n == nil) then n = gData.GetEquipSlot(k); slotNum[k] = n end
    return n
end

gcinclude.WeaponSlots = T{1, 2, 3, 4}
gcinclude.WeaponSlotNames = T{'Main', 'Sub', 'Range', 'Ammo'}
gcinclude.WeaponCommands = T{wm = 'Weapons', mw = 'Main', sw = 'Sub', rw = 'Range', ammoset = 'Ammo'}
gcinclude.WeaponRoleNames = T{'melee', 'ranged', 'caster', 'tank'}
gcinclude.WeaponKeywords = T{'remove', 'displaced', 'ignore'}
gcinclude.BlockedAmmo = T{'hauksbok'}
gcinclude.WeaponItems = {}

-- /mset, /nukeset, /tankset, /pupmode, /weapon: no word cycles; a word picks that value.

-- A job id's abbreviation from the client's own strings (trailing NULs dropped), else nil.
function gcinclude.JobName(id)
    local name = AshitaCore:GetResourceManager():GetString('jobs.names_abbr', id)
    return (type(name) == 'string') and (string.gsub(name, '%z', '')) or nil
end

function gcinclude.ModeLabel(cname, v)
    if (cname == 'MeleeSet') and (v == 'Default') then return 'Base' end
    return v
end

gcinclude.HoldSlots = T{1, 2, 3}
gcinclude.HeldSlots = {}
gcinclude.LockedSlots = {}
gcinclude.NextHoldCheck = 0
gcinclude.MissingWarned = {}
gcinclude.LastDualWield = false
gcinclude.RollBuffs = T{} -- the names in gcinclude.Rolls, as RollActive looks for them in the buff list
for _, r in ipairs(gcinclude.Rolls) do gcinclude.RollBuffs:append(r[1]) end

function gcinclude.UnlockWeapons()
    for slot, _ in pairs(gcinclude.HeldSlots) do
        if (gcinclude.LockedSlots[slot] == nil) then gState.Disabled[slot] = false end
    end
    gcinclude.HeldSlots = {}
end

gcinclude.AllSlotNames = T{'Main', 'Sub', 'Range', 'Ammo', 'Head', 'Body', 'Hands', 'Legs', 'Feet',
    'Neck', 'Waist', 'Ear1', 'Ear2', 'Ring1', 'Ring2', 'Back'}

function gcinclude.SlotNumbers(args, first)
    local slots, unknown = T{}, T{}
    for i = first, #args do
        local want = string.lower(args[i])
        local hit = false
        if (want == 'all') then -- /lock all: all 16 slots (e.g. to equip by hand)
            for n = 1, 16 do if not slots:contains(n) then slots:append(n) end end
            hit = true
        end
        for _, name in ipairs((want == 'all') and T{} or gcinclude.AllSlotNames) do
            if (string.sub(string.lower(name), 1, string.len(want)) == want) then
                local n = slotOf(name)
                hit = true
                if not slots:contains(n) then slots:append(n) end
            end
        end
        if not hit then unknown:append(args[i]) end
    end
    return slots, unknown
end

function gcinclude.SlotName(index)
    for _, name in ipairs(gcinclude.AllSlotNames) do
        if (slotOf(name) == index) then return name end
    end
    return tostring(index)
end

-- Every lock has an owner ('user' = /lock, 'aminon', 'hoxne', 'enchant', 'proc', 'hold:<key>'), so one
-- feature letting go never frees a slot another still holds: /aminon off keeps your /lock main.
-- LockedSlots[slot] = { [owner] = true } while anyone holds it, nil when free.
function gcinclude.LockSlots(slots, owner)
    if (slots == nil) or (#slots == 0) then slots = T{1, 2, 4} end
    owner = owner or 'user'
    for _, slot in ipairs(slots) do
        gcinclude.LockedSlots[slot] = gcinclude.LockedSlots[slot] or {}
        gcinclude.LockedSlots[slot][owner] = true
        gState.Disabled[slot] = true
        gcinclude.HeldSlots[slot] = nil
    end
    return slots
end

-- A Main/Sub/Range let go at WeaponTPGuard+ TP goes straight to the TP hold, as CheckDefault does after Sleep:
-- left enabled until the next 0.1s HoldTick, a HandleDefault in between could swap the weapon and lose the TP.
local function freeSlot(slot)
    gcinclude.LockedSlots[slot] = nil
    if gcinclude.HoldSlots:contains(slot) and (gcinclude.HoldSuspended ~= true) and gcinclude.HoldActive() then
        gcinclude.HeldSlots[slot] = true
        gState.Disabled[slot] = true
    else
        gState.Disabled[slot] = false
    end
end

-- owner nil: every owner (load/unload reset). slots nil: every slot that owner holds.
function gcinclude.UnlockSlots(slots, owner)
    if (slots == nil) or (#slots == 0) then
        slots = T{}
        for slot, owners in pairs(gcinclude.LockedSlots) do
            if (owner == nil) or owners[owner] then slots:append(slot) end
        end
    end
    for _, slot in ipairs(slots) do
        local owners = gcinclude.LockedSlots[slot]
        if (owner == nil) then
            freeSlot(slot)
        elseif (owners ~= nil) and owners[owner] then -- a slot this owner doesn't hold (e.g. TP-held) is left alone
            owners[owner] = nil
            if (next(owners) == nil) then freeSlot(slot) end
        end
    end
    return slots
end

-- What turns each owner's lock off, for messages.
function gcinclude.LockOwnerFix(owner, slot)
    if (owner == 'user') then return '/unlock ' .. string.lower(gcinclude.SlotName(slot)) end
    if (owner == 'hoxne') or (owner == 'aminon') or (owner == 'proc') then return '/' .. owner .. ' off' end
    if (owner == 'enchant') then return 'its /gce use' end
    local key = string.match(owner, '^hold:(.+)$')
    if (key ~= nil) then return '/' .. key .. ' off' end
    return owner
end

-- Owners of the slot other than skip, as their off commands.
function gcinclude.LockHolders(slot, skip)
    local out = T{}
    for o, _ in pairs(gcinclude.LockedSlots[slot] or {}) do
        if (o ~= skip) then out:append(gcinclude.LockOwnerFix(o, slot)) end
    end
    return out
end

-- True when anyone but owner holds the slot.
function gcinclude.LockedByOther(slot, owner)
    local owners = gcinclude.LockedSlots[slot]
    if (owners == nil) then return false end
    for o, _ in pairs(owners) do
        if (o ~= owner) then return true end
    end
    return false
end

function gcinclude.LockCommand(args)
    local wanted, unknown = gcinclude.SlotNumbers(args, 2)
    if (#unknown > 0) then
        gcinclude.Err('No such slot: ' .. table.concat(unknown, ', ') .. ' - nothing locked')
        return
    end
    local slots = gcinclude.LockSlots(wanted, 'user')
    local names = T{}
    for _, slot in ipairs(slots) do names:append(gcinclude.SlotName(slot)) end
    gcinclude.Say('Locked: ' .. table.concat(names, ', '))
end

function gcinclude.UnlockCommand(args)
    local wanted, unknown = gcinclude.SlotNumbers(args, 2)
    if (#unknown > 0) then
        gcinclude.Err('No such slot: ' .. table.concat(unknown, ', ') .. ' - nothing unlocked')
        return
    end
    -- yours only: Aminon/Hoxne/holds keep theirs until they turn off
    local slots = gcinclude.UnlockSlots(wanted, 'user')
    local still = T{}
    local check = slots
    if (wanted == nil) or (#wanted == 0) then check = T{}; for s = 1, 16 do check:append(s) end end
    for _, slot in ipairs(check) do
        local by = gcinclude.LockHolders(slot)
        if (#by > 0) then still:append(gcinclude.SlotName(slot) .. ' (' .. table.concat(by, ', ') .. ')') end
    end
    gcinclude.Say('Unlocked' .. ((#still > 0) and ('; still held: ' .. table.concat(still, ', ')) or ''))
end

-- Holds: put items on and keep those slots until released. Slots already /locked or TP-held are skipped.
gcinclude.Holds = {} -- key -> slot numbers it locked
function gcinclude.ReleaseHold(key)
    local owned = gcinclude.Holds[key]
    if (owned ~= nil) then gcinclude.UnlockSlots(owned, 'hold:' .. key) end
    gcinclude.Holds[key] = nil
end

function gcinclude.HoldSet(key, set)
    local owner = 'hold:' .. key
    local out, owned = {}, T{}
    for slotName, item in pairs(set) do
        local n = slotOf(slotName)
        -- a re-apply keeps its own slots
        local mine = (gcinclude.LockedSlots[n] ~= nil) and not gcinclude.LockedByOther(n, owner)
        if (n ~= 0) and ((gState.Disabled[n] ~= true) or mine) then out[slotName] = item; owned:append(n) end
    end
    gcinclude.ReleaseHold(key) -- after picking slots: released weapon slots go to the TP hold at 1000+ TP
    if (#owned == 0) then return false end
    gFunc.ForceEquipSet(out)
    gcinclude.LockSlots(owned, owner)
    gcinclude.Holds[key] = owned
    return true
end

-- /abyproc: Head, Hands, Legs and Feet bare and kept bare until /abyproc off.
function gcinclude.AbyProcCommand(arg)
    if (arg == 'off') or ((arg ~= 'on') and (gcinclude.Holds.abyproc ~= nil)) then
        gcinclude.ReleaseHold('abyproc')
        gcinclude.Say('abyproc: off')
        return
    end
    local bare = { Head = 'remove', Hands = 'remove', Legs = 'remove', Feet = 'remove' }
    gcinclude.Say('abyproc: ' .. (gcinclude.HoldSet('abyproc', bare) and 'on' or 'every slot is locked'))
end

-- Carried-item holds: the best carried capacity cape, the Jubilee Ring, the Dynamis Divergence neck.
gcinclude.CarriedKeys = T{'capacity', 'jubilee', 'dynamisrp'}

-- The one inventory walk: fn(item, bag, slot) for every real item (no gil, none empty) in bags (default: all
-- 17, Temporary included); a true return stops it and that item, bag and slot are returned.
local ALL_BAGS = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
function gcinclude.EachItem(bags, fn)
    local inv = AshitaCore:GetMemoryManager():GetInventory()
    for _, c in ipairs(bags or ALL_BAGS) do
        for i = 1, (gData.GetContainerMax(c) or 0) do
            local it = inv:GetContainerItem(c, i)
            if (it ~= nil) and (it.Id ~= 0) and (it.Id ~= 65535) and ((it.Count or 0) > 0) and fn(it, c, i) then
                return it, c, i
            end
        end
    end
end

-- How many of an item id in bags, and the first copy found.
function gcinclude.CountItem(id, bags)
    local count, first = 0, nil
    gcinclude.EachItem(bags, function(it)
        if (it.Id == id) then count, first = count + it.Count, first or it end
    end)
    return count, first
end

function gcinclude.FreeSlots(bag)
    local used = 0
    gcinclude.EachItem({ bag or 0 }, function() used = used + 1 end)
    return math.max(0, (gData.GetContainerMax(bag or 0) or 0) - used)
end

-- Bags gear is equipped from (LuAshitacast's EquipBags, else its default).
local function equipBags()
    local bags = gSettings.EquipBags
    return ((type(bags) == 'table') and (#bags > 0)) and bags or {8, 10, 11, 12, 13, 14, 15, 16, 0}
end

-- Every copy of an item id in the equip bags: the first copy found, and how many in all.
local function carriedId(id)
    local count, first = gcinclude.CountItem(id, equipBags())
    return first, count
end
gcinclude.CarriedId = carriedId

-- Matched by name, not by GetItemByName's single id: one name can cover several ids (FFXIAH: Prime Horn
-- 22303, then Loughnashade 22304-22307 for stages 2-5), and any of them counts.
local idName, carriedSeen = {}, {} -- carriedSeen: name -> { until, first, count }, a walk reused for 2s
local function carriedName(name)
    local hit = carriedSeen[name]
    if (hit ~= nil) and (os.clock() < hit[1]) then return hit[2], hit[3] end
    local want, res = string.lower(name), AshitaCore:GetResourceManager()
    local first, count = nil, 0
    gcinclude.EachItem(equipBags(), function(it)
        local n = idName[it.Id]
        if (n == nil) then
            local r = res:GetItemById(it.Id)
            n = (r ~= nil) and string.lower(r.Name[1]) or false
            idName[it.Id] = n
        end
        if (n == want) then first, count = first or it, count + it.Count end
    end)
    carriedSeen[name] = { os.clock() + 2, first, count }
    return first, count
end

-- Capacity point bonus (BG-Wiki): Aptitude Mantle +1 30%, Aptitude Mantle 25%; Mecisto. Mantle 10-50% from
-- its augment, read with LAC's gData.GetAugment ('Cap. Point'). The highest carried cape wins.
gcinclude.CapacityValues = { ['aptitude mantle +1'] = 30, ['aptitude mantle'] = 25 }
local function capeValue(name)
    local it = carriedName(name)
    if (it == nil) then return nil end
    local fixed = gcinclude.CapacityValues[string.lower(name)]
    if (fixed ~= nil) then return fixed end
    local ok, aug = pcall(gData.GetAugment, it)
    local cp = ok and (type(aug) == 'table') and (type(aug.Augs) == 'table') and aug.Augs['Cap. Point'] or nil
    return (type(cp) == 'table') and tonumber(cp.Value) or 0
end

-- Dynamis - Divergence job necks, best first: +2, +1, base. Item ids 25417 + 6 * (job - 1) + 0/1/2, all 66
-- checked on FFXIAH (25417 Warrior's Beads ... 25545 Futhark Torque +2); each is still checked to be a neck
-- this main job can wear before it is used.
local function dynamisNeck()
    local job = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob()
    if (job < 1) or (job > 22) then return nil end
    local base = 25417 + 6 * (job - 1)
    for _, id in ipairs({ base + 2, base + 1, base }) do
        local r = AshitaCore:GetResourceManager():GetItemById(id)
        if (r ~= nil) and (bit.band(r.Slots, gcinclude.SlotBits.Neck) ~= 0)
            and (bit.band(r.Jobs, bit.lshift(1, job)) ~= 0) and (carriedId(id) ~= nil) then
            return r.Name[1]
        end
    end
    return nil
end

function gcinclude.CarriedPick(key)
    if (key == 'capacity') then
        local best, bestValue = nil, -1
        for _, name in ipairs(gcinclude.settings.CapacityCapes or {}) do
            local v = capeValue(name)
            if (v ~= nil) and (v > bestValue) then best, bestValue = name, v end
        end
        if (best ~= nil) then return 'Back', best end
    elseif (key == 'jubilee') and carriedName('Jubilee Ring') then
        return (gcinclude.settings.JubileeSlot or 'Ring1'), 'Jubilee Ring'
    elseif (key == 'dynamisrp') then
        local neck = dynamisNeck()
        if (neck ~= nil) then return 'Neck', neck end
    end
    return nil
end

function gcinclude.CarriedCommand(key, arg)
    if (arg == 'off') or ((arg ~= 'on') and (gcinclude.Holds[key] ~= nil)) then
        gcinclude.ReleaseHold(key)
        gcinclude.Say(key .. ': off')
        return
    end
    local slot, item = gcinclude.CarriedPick(key)
    if (item == nil) then gcinclude.Say(key .. ': none carried'); return end
    gcinclude.Say(key .. ': ' .. (gcinclude.HoldSet(key, { [slot] = item }) and item or (slot .. ' is locked')))
end

-- /lockstyleset after the gear settles.
function gcinclude.ApplyLockstyle(n, delay)
    n = tonumber(n or gcinclude.LockstyleSet or gcinclude.settings.LockstyleSet)
    if (n == nil) then return false end
    local function go() gcinclude.Queue('/lockstyleset ' .. n) end
    if ((delay or 4) > 0) then go:once(delay or 4) else go() end
    return true
end

-- Aftermath (buffs 270-272 Lv.1-3, 273 relic): any weapon equipped, switched or unequipped ends it, ammo doesn't
-- (FFXIclopedia Aftermath), so it holds Main/Sub/Range against idle/engaged sets whatever WeaponTPGuard is; a spell
-- still gets its weapons (IsHoldExempt), as do the TP hold's exemptions.
function gcinclude.AftermathUp()
    for id = 270, 273 do
        if (gcinclude.BuffCount(id) > 0) then return true end
    end
    return false
end

function gcinclude.TPHoldActive()
    local guard = gcinclude.settings.WeaponTPGuard or 0
    if (guard <= 0) then return false end
    -- any status: a Main/Sub/Range swap resets TP idle too
    return (AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0) >= guard)
end

function gcinclude.HoldActive()
    if gcinclude.TPHoldActive() then return true end
    return (gcinclude.settings.AftermathHold ~= false) and gcinclude.AftermathUp()
end

-- Asleep: Main/Sub/Range named in the Sleeping set skip the TP hold, so a wake-up weapon can go on
-- (BG-Wiki Prime weapons: "Slowly devours your soul" drains HP/MP per tick, which wakes you from Sleep).
function gcinclude.SleepFreeSlots()
    if (gcinclude.BuffCount('Sleep') == 0) then return nil end
    local set = gcinclude.FindFilled('Sleeping') or gcinclude.sets.Sleeping
    if (type(set) ~= 'table') then return nil end
    local free = nil
    for k, _ in pairs(set) do
        local slot = slotOf(k)
        if gcinclude.HoldSlots:contains(slot) then free = free or {}; free[slot] = true end
    end
    return free
end

gcinclude.SleepFreed = {} -- slots the last UpdateHold let go for the Sleeping set
function gcinclude.UpdateHold()
    gcinclude.SleepFreed = {}
    if gcinclude.HoldActive() then
        local free = gcinclude.SleepFreeSlots()
        for _, slot in ipairs(gcinclude.HoldSlots) do
            if (free ~= nil) and free[slot] then
                gcinclude.SleepFreed[slot] = true
                if (gcinclude.HeldSlots[slot] ~= nil) then
                    if (gcinclude.LockedSlots[slot] == nil) then gState.Disabled[slot] = false end
                    gcinclude.HeldSlots[slot] = nil
                end
            elseif (gcinclude.HeldSlots[slot] == nil) and (gcinclude.LockedSlots[slot] == nil)
                and (gState.Disabled[slot] ~= true) then
                gState.Disabled[slot] = true
                gcinclude.HeldSlots[slot] = true
            end
        end
    elseif (next(gcinclude.HeldSlots) ~= nil) then
        gcinclude.UnlockWeapons()
    end
end

-- /gcperf: times the idle/engaged handler, the bar and the engine tick; a chat line every 10s until off.
-- ashita.time.qpc/qpf (QueryPerformanceCounter, Ashita's time table); os.clock where this Ashita has neither.
local perfFreq = nil
local function perfNow()
    if (perfFreq == nil) then
        local ok, f = pcall(function() local t = ashita.time.qpf(); return t.q or t.quad_part end)
        perfFreq = (ok and ((tonumber(f) or 0) > 0)) and tonumber(f) or false
    end
    if perfFreq then
        local t = ashita.time.qpc()
        return (t.q or t.quad_part) / perfFreq
    end
    return os.clock()
end
gcinclude.Perf = nil -- { since, nextReport, [name] = { n, total, max } } while /gcperf is on
gcinclude.PerfNow = perfNow
function gcinclude.PerfAdd(name, t0)
    local p = gcinclude.Perf
    if (p == nil) or (t0 == nil) then return end
    local ms = (perfNow() - t0) * 1000
    local e = p[name]
    if (e == nil) then e = { n = 0, total = 0, max = 0 }; p[name] = e end
    e.n, e.total = e.n + 1, e.total + ms
    if (ms > e.max) then e.max = ms end
end
local PERF_ORDER = { { 'default', 'idle/engaged handler' }, { 'rules', 'rules' }, { 'bar', 'bar' },
    { 'gear', 'gear grid' }, { 'tick', 'engine tick' } }
function gcinclude.PerfReport(force)
    local p = gcinclude.Perf
    if (p == nil) then return end
    local now = os.clock()
    if (not force) and (now < p.nextReport) then return end
    local secs = math.max(0.001, now - p.since)
    local parts = {}
    for _, o in ipairs(PERF_ORDER) do
        local e = p[o[1]]
        if (e ~= nil) and (e.n > 0) then
            parts[#parts + 1] = string.format('%s %.1f/s, avg %.3f ms, max %.2f ms', o[2], e.n / secs,
                e.total / e.n, e.max)
        end
    end
    gcinclude.Say('perf (' .. math.floor(secs + 0.5) .. 's): ' .. ((#parts > 0) and table.concat(parts,
        ' | ') or 'nothing ran'))
    gcinclude.Perf = { since = now, nextReport = now + 10 }
end
function gcinclude.PerfCommand(arg)
    if (arg == 'off') or ((arg ~= 'on') and (gcinclude.Perf ~= nil)) then
        gcinclude.PerfReport(true)
        gcinclude.Perf = nil
        gcinclude.Say('perf: off')
        return
    end
    local now = os.clock()
    gcinclude.Perf = { since = now, nextReport = now + 10 }
    perfNow()
    gcinclude.Say('perf: on, a line every 10s (' .. (perfFreq and 'performance counter' or 'os.clock, ~1 ms steps')
        .. '); /gcperf off')
end

-- One per-frame hook for the engine's timed work: gcauto (TH tags, burst windows) and the HUD's files, each
-- guarded, then the TP hold (HoldTick, unguarded: an error in it is reported as before).
local tickErr = false
-- Filled each frame (gcauto / gchud / gcgear can load after this file), not built anew: no garbage per frame.
local tickFns = { false, false, false }
function gcinclude.Tick()
    local t0 = (gcinclude.Perf ~= nil) and perfNow() or nil
    tickFns[1] = (gcauto ~= nil) and gcauto.Tick or false
    tickFns[2] = (gchud ~= nil) and gchud.Tick or false
    tickFns[3] = (gcgear ~= nil) and gcgear.Tick or false
    for i = 1, 3 do
        local f = tickFns[i]
        if f then
            local ok, e = pcall(f)
            if (not ok) and (not tickErr) then tickErr = true; gcinclude.Err('tick: ' .. tostring(e)) end
        end
    end
    gcinclude.HoldTick()
    if (t0 ~= nil) then
        gcinclude.PerfAdd('tick', t0)
        gcinclude.PerfReport()
    end
end

-- The per-profile enchantment service tracks equipped slots for the hold tick.
local holdTick
function gcinclude.HoldTick()
    local now = os.clock()
    if (now < gcinclude.NextHoldCheck) then return end
    gcinclude.NextHoldCheck = now + 0.1
    if gcinclude.Zoning() then return end -- nothing sent or swapped by itself mid-zone
    gcinclude.WithBuffs(holdTick, now)
end
holdTick = function(now)
    enchantRuntime.TrackSlots(now)
    gcinclude.CheckEnchantHold()
    if gcinclude.CheckDualWieldChange(now) then return end -- forced 1h swap: let it land before the hold re-checks
    gcinclude.CheckHoxneAuto(now)
    gcinclude.CheckSleepStoneskin(now)
    gcinclude.CheckZoneNotes()
    if (gcinclude.HoldSuspended == true) then
        if (gState.PlayerAction ~= nil) then return end
        gcinclude.HoldSuspended = false
    end
    gcinclude.UpdateHold()
end

gcinclude.SlotBits = T{ Main = 1, Sub = 2, Range = 4, Ammo = 8, Head = 16, Body = 32,
    Hands = 64, Legs = 128, Feet = 256, Neck = 512, Waist = 1024, Ear1 = 2048, Ear2 = 4096,
    -- item resource Slots bits: 2^(LAC slot - 1), as LAC equip.lua tests them
    Ring1 = 8192, Ring2 = 16384, Back = 32768 }

-- gFunc.ForceEquipSet sends packets directly and ignores gState.Disabled, so /lock and the TP hold
-- would be bypassed. Engine force-equips drop disabled slots first.
function gcinclude.ForceUnlocked(set)
    set = gcinclude.DropAmmoWeapon(set)
    if (type(set) ~= 'table') then return end
    local out, n = {}, 0
    for k, v in pairs(set) do
        local slot = slotOf(k)
        if (slot ~= 0) and (gState.Disabled[slot] ~= true) and not ((slot == 2) and gcinclude.SubRefusedNow(v)) then
            out[k] = v
            n = n + 1
        end
    end
    if (n > 0) then gFunc.ForceEquipSet(out) end
end

-- Received sets: gear for a spell on its way to you, its area, and telling your own boxes.
-- Received set: layered by CheckReceived in HandleDefault until the spell lands or is interrupted
-- (EndReceived, from gcauto's 0x0028 reader), with ReceivedWindow as the fallback.
-- Put on at once only when you are not mid-action, so your own precast/midcast gear is never replaced.
-- from = the caster's server id when known (packet); nil from a Multisend notice.
function gcinclude.StartReceived(spellName, from)
    local setName = gcinclude.ReceivedSetFor(spellName)
    if (setName == nil) then return end
    local set = gcinclude.FindSet(setName)
    if (set == nil) or (next(set) == nil) then return end
    local now = os.clock()
    local ended = gcinclude.ReceivedEnded
    -- notice after it landed
    if (from == nil) and (ended ~= nil) and (ended.set == set) and ((now - ended.at) < 2) then return end
    local same = (gcinclude.ReceivedSet == set) and (now <= (gcinclude.ReceivedUntil or 0))
    if (from ~= nil) then gcinclude.ReceivedFrom = from elseif not same then gcinclude.ReceivedFrom = nil end
    gcinclude.ReceivedSet = set
    gcinclude.ReceivedUntil = now + (gcinclude.settings.ReceivedWindow or 8)
    if (gState.PlayerAction == nil) and (gcinclude.CastLeft() == 0) then gcinclude.ForceUnlocked(set) end
end

-- The caster's spell finished or was interrupted. With no known caster (Multisend notice), only a
-- spell landing on me ends it. LAC runs HandleDefault on its next packet, which puts normal gear back.
function gcinclude.EndReceived(from, hitMe)
    if (gcinclude.ReceivedSet == nil) then return end
    if (gcinclude.ReceivedFrom ~= nil) then
        if (from ~= gcinclude.ReceivedFrom) then return end
    elseif (hitMe ~= true) then
        return
    end
    gcinclude.ReceivedEnded = { set = gcinclude.ReceivedSet, at = os.clock() }
    gcinclude.ReceivedSet, gcinclude.ReceivedFrom = nil, nil
end

function gcinclude.ReceivedSetFor(name)
    if (type(name) ~= 'string') then return nil end
    local lower = string.lower(name)
    local best, bestLen = nil, -1
    for prefix, setName in pairs(gcinclude.settings.ReceivedSets) do
        if (string.sub(lower, 1, string.len(prefix)) == prefix) and (string.len(prefix) > bestLen) then
            best, bestLen = setName, string.len(prefix)
        end
    end
    return best
end

-- Area of a received spell: entity index of its center, or nil for a single-target cast.
-- BG-Wiki/FFXIclopedia: Curaga 10' around its target; Cura, Protectra, Shellra 10' around the caster;
-- Majesty spreads Cure and Protect, Accession the next Healing or Enhancing white magic, 10' around the target.
gcinclude.AoeOnTarget = T{ 'curaga' }
gcinclude.AoeOnCaster = T{ 'cura', 'protectra', 'shellra' }
gcinclude.AoeRange = 10
function gcinclude.AoeCenter(action, target)
    local fam = string.gsub(string.lower(action.Name), ' [ivx]+$', '')
    local party = AshitaCore:GetMemoryManager():GetParty()
    if gcinclude.AoeOnCaster:contains(fam) then return party:GetMemberTargetIndex(0) end
    local tindex = (target ~= nil) and target.Index or nil
    if gcinclude.AoeOnTarget:contains(fam) then return tindex end
    if (gcinclude.BuffCount('Majesty') > 0) and ((fam == 'cure') or (fam == 'protect')) then return tindex end
    if (gcinclude.BuffCount('Accession') > 0) and (action.Type == 'White Magic')
        and ((action.Skill == 'Healing Magic') or (action.Skill == 'Enhancing Magic')) then return tindex end
    return nil
end

local function entity_distance(a, b)
    local e = AshitaCore:GetMemoryManager():GetEntity()
    local dx = e:GetLocalPositionX(a) - e:GetLocalPositionX(b)
    local dy = e:GetLocalPositionY(a) - e:GetLocalPositionY(b)
    local dz = e:GetLocalPositionZ(a) - e:GetLocalPositionZ(b)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- The Multisend plugin (/load multisend) owns /ms; without it /ms sendto is an unknown command.
local function multisendLoaded()
    local pm = AshitaCore:GetPluginManager()
    return (pm ~= nil) and ((pm:Get('Multisend') ~= nil) or (pm:Get('multisend') ~= nil))
end

-- Tells my own boxes a received spell is coming (Multisend): the target, and for an area spell every box in my
-- party within AoeRange of its center. Each box also sees the cast start in its own packets (gcauto).
function gcinclude.AnnounceCast()
    local action = gData.GetAction()
    if (action == nil) or (action.Name == nil) then return end
    if (gcinclude.ReceivedSetFor(action.Name) == nil) or not multisendLoaded() then return end
    local target = gData.GetActionTarget()
    local me = gData.GetPlayer()
    local myName = (me ~= nil) and me.Name or nil
    local told = {}
    local function tell(name)
        if (name == nil) or (name == '') or (name == myName) or told[name] then return end
        if not gcinclude.IsMyBox(name) then return end -- other players' characters: no Multisend
        told[name] = true
        gcinclude.Queue('/ms sendto ' .. name .. ' /lac fwd received ' .. action.Name)
    end
    if (target ~= nil) and ((target.Type == 'PC') or (target.Type == 'Party') or (target.Type == 'Alliance')) then
        tell(target.Name)
    end
    local center = gcinclude.AoeCenter(action, target)
    if (center == nil) or (center == 0) then return end
    local party = AshitaCore:GetMemoryManager():GetParty()
    for i = 1, 5 do
        local idx = party:GetMemberTargetIndex(i)
        if (party:GetMemberIsActive(i) == 1) and (idx ~= nil) and (idx > 0)
            and (entity_distance(center, idx) <= gcinclude.AoeRange) then
            tell(party:GetMemberName(i))
        end
    end
end

-- One of my own boxes: listed in settings.MyBoxes, or running this engine now (fresh HUD state file).
function gcinclude.IsMyBox(name)
    if (type(name) ~= 'string') then return false end
    local lname = string.lower(name)
    for _, n in ipairs(gcinclude.settings.MyBoxes or {}) do
        if (string.lower(n) == lname) then return true end
    end
    return (gchud ~= nil) and (gchud.IsBox ~= nil) and gchud.IsBox(name)
end

function gcinclude.CheckReceived()
    if (gcinclude.ReceivedSet == nil) then return end
    if (os.clock() > (gcinclude.ReceivedUntil or 0)) then
        gcinclude.ReceivedSet = nil
        return
    end
    gFunc.EquipSet(gcinclude.ReceivedSet)
end

function gcinclude.IsHoldExempt()
    local action = gData.GetAction()
    if (action == nil) then return false end
    local exempt = gcinclude.settings.HoldExempt
    if (action.ActionType == 'Spell') then -- its skill (Singing) or its name (Dread Spikes)
        if exempt:contains(action.Skill) or exempt:contains(action.Name) then return true end
        -- held only for Aftermath: a cast still gets its weapons
        return gcinclude.AftermathUp() and not gcinclude.TPHoldActive()
    elseif (action.ActionType == 'Ability') then -- its type (Corsair Roll) or its name
        return exempt:contains(action.Type) or exempt:contains(action.Name)
    end
    return false
end

function gcinclude.CheckHoldExempt()
    if gcinclude.IsHoldExempt() then
        gcinclude.UnlockWeapons()
        gcinclude.HoldSuspended = true
    end
end

gcinclude.SmartKeep = false

function gcinclude.SmartSwapCommand(args)
    local v = (args[2] ~= nil) and string.lower(args[2]) or nil
    if (v == 'on') then gcinclude.settings.SmartSwap = true
    elseif (v == 'off') then gcinclude.settings.SmartSwap = false
    else gcinclude.settings.SmartSwap = (gcinclude.settings.SmartSwap ~= true) end
    gcinclude.Say('SmartSwap: ' .. (gcinclude.settings.SmartSwap and 'On' or 'Off'))
end

gcinclude.AutoGearKeys = T{ regen = 'RegenGearHPP', refresh = 'RefreshGearMPP', dt = 'DTGearHPP',
    petdt = 'PetDTGearHPP' }

function gcinclude.AutoGearCommand(args)
    local cfg = gcinclude.settings
    local what = (args[2] ~= nil) and string.lower(args[2]) or nil
    if (what == 'on') then cfg.AutoGear = true
    elseif (what == 'off') then cfg.AutoGear = false
    elseif (what ~= nil) and (gcinclude.AutoGearKeys[what] ~= nil) and (tonumber(args[3]) ~= nil) then
        cfg[gcinclude.AutoGearKeys[what]] = math.max(0, math.min(100, tonumber(args[3])))
    elseif (what ~= nil) then
        gcinclude.Err('usage: /autogear [on|off|regen N|refresh N|dt N|petdt N], 0 = never')
        return
    end
    print(chat.header('GoomSwap'):append(chat.message(string.format('AutoGear %s | regen <%d%% hp, refresh <%d%% mp (both out of combat) | dt <%d%% hp | petdt <%d%% pet hp',
        (cfg.AutoGear ~= false) and 'on' or 'off', cfg.RegenGearHPP or 0, cfg.RefreshGearMPP or 0, cfg.DTGearHPP or 0,
            cfg.PetDTGearHPP or 0))))
end

function gcinclude.SmartKeepFor(action)
    local cfg = gcinclude.settings
    if (cfg.SmartSwap ~= true) or (action == nil) or (action.ActionType ~= 'Spell')
        or (type(action.Name) ~= 'string') then
        return false
    end
    local player = gData.GetPlayer()
    if (player == nil) or (player.TP < (cfg.SmartSwapTP or 1)) then return false end
    local lname = string.lower(action.Name)
    local equip = nil
    for _, rule in ipairs(cfg.KeepWeaponsFor or {}) do
        if (type(rule) == 'string') then
            if (string.lower(rule) == lname) then return true end
        elseif (type(rule) == 'table') then
            local hit = false
            for _, pre in ipairs(rule.Spells or {}) do
                local lp = string.lower(pre)
                if (string.sub(lname, 1, string.len(lp)) == lp) then hit = true end
            end
            if hit then
                equip = equip or gData.GetEquipment() or {}
                for _, slot in ipairs(T{'Main', 'Sub'}) do
                    local worn = equip[slot]
                    if (worn ~= nil) and (type(worn.Name) == 'string') then
                        local wn = string.lower(worn.Name)
                        for _, item in ipairs(rule.Worn or {}) do
                            if (string.lower(item) == wn) then return true end
                        end
                    end
                end
            end
        end
    end
    return false
end

function gcinclude.StripWeaponSwaps()
    gFunc.Equip('Main', 'ignore')
    gFunc.Equip('Sub', 'ignore')
    gFunc.Equip('Range', 'ignore')
end

-- Dispelga can only be cast with Daybreak in the main hand (BG-Wiki Dispelga: "Mainhand: Daybreak", on WHM BLM RDM
-- BRD SMN SCH GEO), so its precast and midcast end with Daybreak in Main whatever the job's sets put there: a job
-- file needs no Dispelga set for the spell to go off. A Sub that can't go with it is dropped (SubFits); a /lock or
-- /aminon on Main still wins.
function gcinclude.CheckDaybreak()
    local action = gData.GetAction()
    if (action ~= nil) and (action.Name == 'Dispelga') then gFunc.Equip('Main', 'Daybreak') end
end

-- == Rules (gcinclude.Rules, gcrules.lua): the job file's "when this, wear that" as data. Compiled at Initialize and
-- run from the wrappers below: 'job' rules where a job file's own code goes (under GoomSwap's layers), 'top' rules
-- over them. Each run reads the game once per value (gData, buffs from WithBuffs' list). ==
gcinclude.RulesCompiled = nil
gcinclude.RuleWhy = {} -- [the set or item a rule wore] = that rule in words, for /gcedit's Equip order
local function ruleNote(entry, label)
    if (label ~= nil) and (entry ~= nil) then gcinclude.RuleWhy[label] = entry.note or entry.words end
end
-- Named so /gcedit's layer record says a rule put it on (gceditactions: ruleWear, ruleEquip).
local function ruleWear(name, exact, entry)
    ruleNote(entry, name)
    if exact then
        local set = gcinclude.FindSet(name)
        if (set ~= nil) then gFunc.EquipSet(set) end
    else
        gcinclude.ByName(name)
    end
end
local function ruleEquip(slot, item, entry)
    ruleNote(entry, 'ruleEquip()')
    gFunc.Equip(slot, item)
end
local rulesApi = {
    player = function() return gData.GetPlayer() end,
    action = function() return gData.GetAction() end,
    target = function() return gData.GetActionTarget() end,
    env = function() return gData.GetEnvironment() end,
    pet = function() return gData.GetPet() end,
    petAction = function() return gData.GetPetAction() end,
    me = function()
        local party = AshitaCore:GetMemoryManager():GetParty()
        return (party ~= nil) and party:GetMemberName(0) or nil
    end,
    buff = function(b) return gcinclude.BuffCount(b) end,
    cycle = function(n) return gcdisplay.GetCycle(n) end,
    toggle = function(n) return gcdisplay.GetToggle(n) end,
    burst = function() return gcinclude.BurstWanted() end,
    dualWield = function() return gcinclude.CanDualWield() end,
    inCombat = function() return gcinclude.InCombat(gData.GetPlayer()) end,
    family = function(n) return gcinclude.Family(n) end,
    hasSet = function(n) return gcinclude.FindSet(n) ~= nil end, -- 'has a set named after it / its family'
    weaponPick = function() return gcinclude.IsWeaponValue(gcdisplay.GetCycle('Weapons')) == true end,
    inList = function(list, name) -- "in GoomSwap's spell list": gcinclude.BluMagPhysical...
        local l = (type(list) == 'string') and rawget(gcinclude, list) or nil
        return (type(l) == 'table') and (type(l.contains) == 'function') and (l:contains(name) == true)
    end,
    wear = function(name, exact, entry) ruleWear(name, exact, entry) end,
    equip = function(slot, item, entry) ruleEquip(slot, item, entry) end,
    cancel = function(entry)
        gFunc.CancelAction()
        gcinclude.Say('Stopped by a rule: ' .. tostring(entry.note or entry.words))
    end,
}
gcinclude.RulesApi = rulesApi
-- The code spots rules are tied to whose gcinclude.RulesAt line is not in the job file (deleted or renamed by
-- hand): those rules would never go on. { { spot, n } }, empty when the file can't be read.
local function missing_spots(compiled)
    local out = {}
    if (compiled == nil) or (next(compiled.at or {}) == nil) or (gProfile == nil)
        or (type(gProfile.FilePath) ~= 'string') then
        return out
    end
    local f = io.open(gProfile.FilePath, 'r')
    if f == nil then return out end
    local text = string.gsub(f:read('*a') or '', '%-%-[^\n]*', '') -- a commented-out line doesn't count
    f:close()
    for spot, list in pairs(compiled.at) do
        local pat = "RulesAt%s*%(%s*['\"]" .. string.gsub(spot, '%p', '%%%0') .. "['\"]%s*%)"
        if not string.find(text, pat) then out[#out + 1] = { spot = spot, n = #list } end
    end
    table.sort(out, function(a, b) return a.spot < b.spot end)
    return out
end
function gcinclude.CompileRules()
    local compiled, problems = gcrules.Compile(gcinclude.Rules)
    gcinclude.RulesCompiled, gcinclude.RuleProblems = compiled, problems
    for _, p in ipairs(problems) do gcinclude.Err('gcinclude.Rules, ' .. p .. ': left out.') end
    for _, m in ipairs(missing_spots(compiled)) do
        gcinclude.Err('gcinclude.Rules: ' .. m.n .. ((m.n == 1) and ' rule goes' or ' rules go') .. " on at code spot '"
            .. m.spot .. "', but the job file has no gcinclude.RulesAt('" .. m.spot .. "') line: "
            .. ((m.n == 1) and 'it never goes' or 'they never go') .. ' on. /gcedit, Rules: Edit, More, Use a layer instead.')
    end
end
function gcinclude.HasRules(phase) return gcrules.Count(gcinclude.RulesCompiled, phase) > 0 end
-- One phase's layer ('job' or 'top'). true when a rule stopped the action; and how many rules went on.
function gcinclude.RunRules(phase, layer)
    local c = gcinclude.RulesCompiled
    local list = (c ~= nil) and (c[phase] ~= nil) and c[phase][layer] or nil
    if (list == nil) or (#list == 0) then return false, 0 end
    -- an action the job file (CheckCancels, a bailout) already cancelled: its gear doesn't go on, rules' neither
    if (phase ~= 'Default') and (phase ~= 'Pet') and (gState ~= nil) and (gState.PlayerAction ~= nil)
        and (gState.PlayerAction.Block == true) then
        return true, 0
    end
    local t0 = (gcinclude.Perf ~= nil) and perfNow() or nil
    local stopped, n = gcrules.Run(c, phase, layer, rulesApi)
    gcinclude.PerfAdd('rules', t0)
    return stopped, n
end
-- The rules at a spot in the job file's code (/gcedit's Convert leaves `gcinclude.RulesAt('Midcast 1')` where the
-- `if`s it turned into rules were): they go on right there. true when one stopped the action.
function gcinclude.RulesAt(at)
    local c = gcinclude.RulesCompiled
    if (c == nil) or (c.at == nil) or (c.at[at] == nil) then return false end
    local list = c.at[at]
    local phase = list[1].phase
    if (phase ~= 'Default') and (phase ~= 'Pet') and (gState ~= nil) and (gState.PlayerAction ~= nil)
        and (gState.PlayerAction.Block == true) then
        return true
    end
    local t0 = (gcinclude.Perf ~= nil) and perfNow() or nil
    local stopped = gcrules.RunAt(c, at, rulesApi)
    gcinclude.PerfAdd('rules', t0)
    return stopped
end

-- The handler names LAC calls, and the rule phase each one runs.
local RULE_PHASE = { HandlePrecast = 'Precast', HandleMidcast = 'Midcast', HandleAbility = 'Ability',
    HandleWeaponskill = 'Weaponskill', HandlePreshot = 'Preshot', HandleMidshot = 'Midshot', HandleItem = 'Item' }
-- The job file's handler, or (a job file without one, rules for its phase) a stand-in so the rules still run.
local function handlerFor(name)
    local f = gProfile[name]
    if (type(f) == 'function') then return f end
    if gcinclude.HasRules(RULE_PHASE[name]) then return function() end end
    return nil
end

-- Trace phase per handler: 'pre' waits for its 'mid' so a spell or shot prints one line.
gcinclude.Checked = T{'HandlePrecast', 'HandleAbility'}

function gcinclude.WrapHoldHandlers()
    if (gProfile == nil) or (gProfile.GcHoldWrapped == true) then return end
    for _, name in ipairs(T{'HandlePrecast', 'HandleAbility', 'HandleMidcast'}) do
        local original = handlerFor(name)
        if (type(original) == 'function') then
            gProfile[name] = function(...)
                if gcinclude.Checked:contains(name) and gcaction.Check() then gFunc.CancelAction(); return end
                -- sent as is, the cast keeps its gear
                if (name == 'HandleAbility') and gcinclude.MidCast() then return end
                gcinclude.CheckHoldExempt()
                if (name == 'HandleAbility') then gcinclude.AnnounceCast() end -- Waltzes to your own boxes
                if (name == 'HandlePrecast') then
                    gcinclude.AnnounceCast()
                    gcinclude.SmartKeep = gcinclude.SmartKeepFor(gData.GetAction())
                end
                gcinclude.THWorn = false
                gcinclude.WornSets = (name == 'HandleMidcast') and {} or nil
                local result = original(...)
                local phase = RULE_PHASE[name]
                -- job rules: where the job file's own code ends (their sets noted, so _Self/_Burst follow them)
                local stopped, ran = gcinclude.RunRules(phase, 'job')
                if stopped then
                    gcinclude.WornSets = nil
                    return result
                end
                -- TH this cast already wore stays over the rules' gear, as over the job file's (CheckAbsorb does the same)
                if (ran > 0) and (name == 'HandleMidcast') and (gcinclude.THWorn == true) then gcinclude.CheckTH() end
                local worn = gcinclude.WornSets
                gcinclude.WornSets = nil
                if (name == 'HandleMidcast') then
                    gcinclude.WearChildren(worn, gcinclude.SpellChildKeys())
                    -- before the buff layer: a buff piece (Nether Void, Dark Seal) beats the Absorb sets
                    gcinclude.CheckAbsorb()
                    gcinclude.CheckBuffSets('Buffs_Midcast')
                    gcinclude.CheckLightBonus()
                    gcinclude.CheckElementGear()
                    gcinclude.CheckSIR()
                elseif (name == 'HandleAbility') then
                    gcinclude.CheckElementGear() -- Quick Draw
                elseif (name == 'HandlePrecast') then
                    gcinclude.CheckBuffSets('Buffs_Precast') -- Buffs_Precast['Spontaneity']: no fast cast needed
                end
                -- top rules: over GoomSwap's layers; SmartSwap's weapon keep and Dispelga's Daybreak still win
                if gcinclude.RunRules(phase, 'top') then return result end
                if (gcinclude.SmartKeep == true) and ((name == 'HandlePrecast') or (name == 'HandleMidcast')) then
                    gcinclude.StripWeaponSwaps()
                end
                -- last: nothing above may take Daybreak off a Dispelga
                if (name ~= 'HandleAbility') then gcinclude.CheckDaybreak() end
                return result
            end
        end
    end
    local ws = handlerFor('HandleWeaponskill')
    if (type(ws) == 'function') then
        gProfile.HandleWeaponskill = function(...)
            if gcaction.Check() then gFunc.CancelAction(); return end
            if gcinclude.MidCast() then return end -- sent as is, the cast keeps its gear
            -- /proc: a weapon skill to proc a mob (Abyssea, Vagary), not to kill it. The job file still runs (its
            -- checks can cancel the WS), but its WS gear is dropped from the buffer: only Ws_Proc (else Proc) goes
            -- on. Slots the proc set leaves out keep what you have on. No _HighBuff, _PDL, _Dt, Hoxne, Buffs_Ws,
            -- Moonshade or obi.
            local proc = (gcdisplay.GetToggle('PROC') == true)
            local result, trail = gcinclude.TrackEars(function(...)
                gcinclude.WornSets = {}
                local r = ws(...)
                if proc and not ((gState.PlayerAction ~= nil) and (gState.PlayerAction.Block == true)) then
                    if (gEquip ~= nil) and (gEquip.ClearBuffer ~= nil) then gEquip.ClearBuffer() end
                    gcinclude.WornSets = {}
                    local set = gcinclude.FindFilled('Ws_Proc') or gcinclude.FindSet('Proc')
                    if (set ~= nil) then gFunc.EquipSet(set) end
                    gcinclude.WornSets = nil
                    return r
                end
                if (gState.PlayerAction ~= nil) and (gState.PlayerAction.Block == true) then -- cancelled
                    gcinclude.WornSets = nil
                    return r
                end
                -- job rules: after the job file's WS code (their sets noted for _HighBuff / _Dt, ears for Moonshade)
                if gcinclude.RunRules('Weaponskill', 'job') then
                    gcinclude.WornSets = nil
                    return r
                end
                local worn = gcinclude.WornSets
                gcinclude.WornSets = nil
                -- /wsset: each WS set's child; an /mset mode of that name already wore them (/mset acc: Ws_Acc). Those
                -- children are WS sets worn too: /dt takes their _Dt (['Insurgency_HighBuff_Dt'])
                local key = gcinclude.WsSetKeys[gcdisplay.GetCycle('WsSet')]
                if (key ~= nil) and (gcdisplay.GetCycle('MeleeSet') ~= key) then
                    for _, n in ipairs(gcinclude.WearChildren(worn, {key})) do worn[#worn + 1] = n end
                end
                -- /dt: Ws_Dt, ['Victory Smite_Dt'], Ws_HighBuff_Dt
                if (gcdisplay.GetToggle('DTset') == true) then gcinclude.WearChildren(worn, {'Dt'}) end
                gcinclude.CheckHoxneWs()
                gcinclude.CheckBuffSets('Buffs_Ws')
                gcinclude.CheckHoxneWsCombos() -- Hoxne + buff over the plain buff sets
                return r
            end, ...)
            -- WS cancelled
            if (gState.PlayerAction ~= nil) and (gState.PlayerAction.Block == true) then return result end
            if proc then return result end
            gcinclude.CheckMoonshade(trail)
            gcinclude.CheckElementGear()
            gcinclude.RunRules('Weaponskill', 'top') -- over every WS layer
            return result
        end
    end
    for _, name in ipairs(T{'HandlePreshot', 'HandleMidshot', 'HandleItem'}) do
        local original = handlerFor(name)
        -- HandleItem: every job, the job file needs none
        if (type(original) == 'function') or (name == 'HandleItem') then
            gProfile[name] = function(...)
                -- /item or /ra while a spell is being cast: the game refuses it, and letting it through would
                -- put its gear (or, once refused, idle gear) over the cast's midcast set.
                if (name ~= 'HandleMidshot') and (gcinclude.CastLeft() > 0) then
                    local a = gData.GetAction()
                    gcinclude.Say(((a ~= nil) and a.Name or ((name == 'HandleItem') and 'item' or 'ranged'))
                        .. ': casting')
                    gFunc.CancelAction()
                    return
                end
                if (name == 'HandleItem') then -- gcinclude.sets.Holy_Water, under the job's own HandleItem
                    local a = gData.GetAction()
                    if (a ~= nil) and (type(a.Name) == 'string') and (string.find(a.Name, 'Holy Water', 1,
                        true) ~= nil) then
                        gFunc.EquipSet(gcinclude.sets.Holy_Water)
                    end
                end
                local result
                if (type(original) == 'function') then result = original(...) end
                local phase = RULE_PHASE[name]
                if not gcinclude.RunRules(phase, 'job') then gcinclude.RunRules(phase, 'top') end
                return result
            end
        end
    end
    -- The job file's own BuffCount calls (MNK: Impetus, Footwork) read the buff list once with CheckDefault's,
    -- not once each: LAC runs HandleDefault on every outgoing packet chunk.
    local default = gProfile.HandleDefault
    if (type(default) == 'function') then
        -- Rules: a pet action's (LAC brings those here, not to a handler of their own), else the idle/engaged ones
        -- when the job file didn't call CheckDefault (which runs them in their places).
        local function run(...)
            gcinclude.RulesRanDefault = false
            default(...)
            local pet, idle = gcinclude.HasRules('Pet'), gcinclude.HasRules('Default')
            if not (pet or idle) then return end
            if gData.GetPetAction() ~= nil then
                if pet and not gcinclude.RunRules('Pet', 'job') then gcinclude.RunRules('Pet', 'top') end
            elseif (gcinclude.RulesRanDefault == false) and idle then
                gcinclude.RunRules('Default', 'job')
                gcinclude.RunRules('Default', 'top')
            end
        end
        gProfile.HandleDefault = function(...)
            if (gcinclude.Perf == nil) then gcinclude.WithBuffs(run, ...); return end
            local t0 = perfNow() -- /gcperf
            gcinclude.WithBuffs(run, ...)
            gcinclude.PerfAdd('default', t0)
        end
    end
    gProfile.GcHoldWrapped = true
end

-- Buff counts by id. LAC's GetBuffCount(name) converts every active buff name on each call;
-- here each name is resolved to its ids once and counted against the raw buff list.
-- GetBuffs copies the 32-entry buff array (Ashita.h IPlayer::GetBuffs) into a new table per call. Inside
-- WithBuffs (CheckDefault, HoldTick: a dozen counts each) it is read once, as id -> count, for that call only.
local buffIds, buffCache = {}, nil
local dualWieldNow = nil -- CanDualWield's answer for the same call (asked 3-4 times per HandleDefault)
local function buffCounts()
    if (buffCache ~= nil) then return buffCache end
    local counts = {}
    for _, b in pairs(AshitaCore:GetMemoryManager():GetPlayer():GetBuffs()) do counts[b] = (counts[b] or 0) + 1 end
    return counts
end
function gcinclude.WithBuffs(fn, ...)
    if (buffCache ~= nil) then return fn(...) end -- already inside one
    buffCache, dualWieldNow = buffCounts(), nil
    local ok, err = pcall(fn, ...)
    buffCache, dualWieldNow = nil, nil -- also after an error, so nothing later reads a stale list
    if not ok then error(err, 0) end
end
function gcinclude.BuffCount(m)
    local counts = buffCounts()
    local predicted = (gcauto ~= nil) and gcauto.Predicted or nil -- landed, not listed yet
    if (type(m) == 'number') then
        local n = counts[m] or 0
        if (n == 0) and (predicted ~= nil) and predicted(m) then n = 1 end
        return n
    end
    if (type(m) ~= 'string') then return 0 end
    local key = string.lower(m)
    local ids = buffIds[key]
    if (ids == nil) then
        ids = {}
        local res = AshitaCore:GetResourceManager()
        for id = 0, 1023 do
            local name = res:GetString('buffs.names', id)
            if (type(name) == 'string') and (string.lower((name:gsub('%z+$', ''))) == key) then ids[id] = true end
        end
        buffIds[key] = ids
    end
    local count = 0
    for id in pairs(ids) do count = count + (counts[id] or 0) end
    if (count == 0) and (predicted ~= nil) then
        for id in pairs(ids) do
            if predicted(id) then return 1 end
        end
    end
    return count
end

-- Lowercase name -> set, built once per Sets table. HandleDefault looks up ~10 sets per call;
-- scanning every set each time was the costliest part of it. /lac addset reloads the profile,
-- which gives a new Sets table and so a fresh index.
local setIndex, setIndexOf, setNameOf = {}, nil, {}
function gcinclude.FindSet(name)
    if (gProfile == nil) or (type(gProfile.Sets) ~= 'table') or (type(name) ~= 'string') then return nil end
    if (setIndexOf ~= gProfile.Sets) then
        setIndex, setIndexOf, setNameOf = {}, gProfile.Sets, {}
        for key, set in pairs(gProfile.Sets) do
            if (type(key) == 'string') and (type(set) == 'table') then
                setIndex[string.lower(key)] = set
                setNameOf[set] = key
            end
        end
    end
    local hit = setIndex[string.lower(name)]
    if (hit == nil) then -- a set inside a set, by the name /gcedit gives it: Buffs['Boost']
        local parent, key = string.match(name, "^(.-)%['(.+)'%]$")
        local holder = (parent ~= nil) and setIndex[string.lower(parent)] or nil
        if (type(holder) == 'table') then
            hit = holder[key]
            if (hit == nil) then
                local l = string.lower(key)
                for k, v in pairs(holder) do
                    if (type(k) == 'string') and (string.lower(k) == l) then hit = v break end
                end
            end
            if (type(hit) ~= 'table') then hit = nil end
        end
    end
    -- a set looked for and not there, during an action: /gcedit lists it (gcaction.RecMiss)
    if (hit == nil) and (name ~= '') and (gcaction ~= nil) and (gcaction.RecMiss ~= nil) then gcaction.RecMiss(name) end
    return hit
end

-- FindSet, but nil for an empty set: in a chain an empty template falls through to the next one (Ws_Proc -> Proc,
-- Aminon -> mdt -> Dt, Sleeping/Doomed -> the engine's own), as the example files' comments say.
function gcinclude.FindFilled(name)
    local set = gcinclude.FindSet(name)
    if (set ~= nil) and (next(set) == nil) then return nil end
    return set
end

-- Child sets: while a handler runs, the sets it wears are noted by
-- name; then each one's <name>_<key> goes on, in the order they went on, and for <prefix>_Default also
-- <prefix>_<key> (Ws_Default -> Ws_HighBuff, Savage_Default -> Savage_HighBuff). Keys: LowBuff / HighBuff / PDL / Acc
-- / SubtleBlow on weapon skills (/wsset low / high / pdl / acc / sb); Self or Others (a spell on you / on anyone but a
-- monster) and Burst (BurstWanted) on spells.
gcinclude.WornSets = nil -- the names, while a handler runs
-- /wsset mode: the child key it wears over each WS set
gcinclude.WsSetKeys = { Low = 'LowBuff', High = 'HighBuff', PDL = 'PDL', Acc = 'Acc', SubtleBlow = 'SubtleBlow' }
-- A set's name for the /gcedit layer record: its key in the job file's sets (or a set inside one, as
-- Buffs['Aftermath: Lv.3']), gcinclude.sets.<key> for the engine's own, else nil (a table built in code).
local labelOf = setmetatable({}, { __mode = 'k' })
function gcinclude.SetLabel(set)
    if (type(set) == 'string') then return set end
    if (type(set) ~= 'table') then return nil end
    gcinclude.FindSet('')
    if (setNameOf[set] ~= nil) then return setNameOf[set] end
    local hit = labelOf[set]
    if (hit == nil) then
        hit = false
        for k, v in pairs(gcinclude.sets or {}) do
            if (v == set) then hit = 'gcinclude.sets.' .. tostring(k) break end
        end
        if (hit == false) and (gProfile ~= nil) and (type(gProfile.Sets) == 'table') then
            for k, v in pairs(gProfile.Sets) do
                if (type(v) == 'table') then
                    for k2, v2 in pairs(v) do
                        if (v2 == set) and (type(k2) == 'string') then hit = tostring(k) .. "['" .. k2 .. "']" break end
                    end
                end
                if (hit ~= false) then break end
            end
        end
        labelOf[set] = hit
    end
    return hit or nil
end

-- The function that called the one asking (level 2 = its caller), for a layer with no set name.
function gcinclude.CallerLabel(level)
    if (debug == nil) or (debug.getinfo == nil) then return 'code' end
    local info = debug.getinfo(level + 1, 'n')
    return ((info ~= nil) and (type(info.name) == 'string')) and (info.name .. '()') or 'code'
end

-- The functions on the stack above the one asking, closest first (for the /gcedit "why" of a layer).
function gcinclude.CallChain(level)
    if (debug == nil) or (debug.getinfo == nil) then return nil end
    local out = {}
    for l = level + 1, level + 8 do
        local info = debug.getinfo(l, 'n')
        if (info == nil) then break end
        if (type(info.name) == 'string') then out[#out + 1] = info.name end
    end
    return out
end

function gcinclude.NoteSet(set)
    -- capped: a handler that errored leaves it on
    if (gcinclude.WornSets == nil) or (#gcinclude.WornSets >= 64) then return end
    local name = set
    if (type(set) == 'table') then
        gcinclude.FindSet('')
        name = setNameOf[set]
    end
    if (type(name) == 'string') then table.insert(gcinclude.WornSets, name) end
end

-- LuAshitacast's Packer list (profile.Packer), for /lac gear and /lac validate (the Packer plugin). Filled once per
-- load, in memory: char.lua's Packer, sets inside sets (Buffs), GoomSwap's own sets and the items its commands and
-- layers wear, the ones you own (gcpackerlist.lua). The job file itself is never written here.
local PACKER_BAGS = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 } -- every container (gceditbags BAGS)
function gcinclude.PackerItems()
    local s, j = gcinclude.settings, gcinclude
    local items = gcpackerlist.Names({ s.warp_Ring, s.mea_Ring, s.dem_Ring, s.holla_Ring, s.HoxneItem, s.CapacityCapes,
        s.XIRollSet, s.ElementGear, j.SafeAmmo, j.RangeAmmo })
    for _, name in ipairs({ 'Moonshade Earring', 'Daybreak', 'Jubilee Ring' }) do items[#items + 1] = name end
    return items
end
-- An item's stack size (Packer's 'stack'), 1 when the game doesn't know it. The editor's Packer rows use it too.
function gcinclude.StackOf(name)
    local r = AshitaCore:GetResourceManager():GetItemByName(name, 0)
    return (r ~= nil) and (r.StackSize or 1) or 1
end
function gcinclude.FillPacker(again) -- again: rebuild (char.lua's Packer changed; Get gear: what you own now)
    if gProfile == nil then return end
    if gProfile.GcPackerFilled == true then
        if again ~= true then return end
        gProfile.Packer, gProfile.GcPackerFilled = gcinclude.FilePacker, nil
    end
    local res, inv = AshitaCore:GetResourceManager(), AshitaCore:GetMemoryManager():GetInventory()
    local owned = nil
    local function owns(name)
        if owned == nil then
            owned = {}
            for _, c in ipairs(PACKER_BAGS) do
                for i = 1, (gData.GetContainerMax(c) or 0) do -- as the bag scans do (gceditbags, gcgear)
                    local it = inv:GetContainerItem(c, i)
                    if (it ~= nil) and (it.Id ~= 0) and (it.Id ~= 65535) then
                        local r = res:GetItemById(it.Id)
                        if (r ~= nil) and (r.Name ~= nil) and (r.Name[1] ~= nil) then owned[string.lower(r.Name[1])] = true end
                    end
                end
            end
        end
        return owned[string.lower(name)] == true
    end
    gcinclude.FilePacker = gProfile.Packer -- as the job file has it
    gProfile.Packer = gcpackerlist.Build({ file = gProfile.Packer, char = gcinclude.CharPacker, sets = gProfile.Sets,
        engineSets = gcinclude.sets, items = gcinclude.PackerItems(), stackOf = gcinclude.StackOf, owns = owns })
    gProfile.GcPackerFilled = true
end
-- /lac gear: the Packer plugin collects every set's gear plus the list above. false and why when it can't run.
function gcinclude.PackerReady()
    local pm = AshitaCore:GetPluginManager()
    if (pm == nil) or (not pm:IsLoaded('Packer')) then return false, 'the Packer plugin: /load packer' end
    return true
end
function gcinclude.GetGear()
    local ok, why = gcinclude.PackerReady()
    if not ok then gcinclude.Err('/lac gear needs ' .. why); return false end
    gcinclude.FillPacker(true) -- again: what you own now (gear bought or moved since the job file loaded)
    AshitaCore:GetChatManager():QueueCommand(1, '/lac gear')
    return true
end

function gcinclude.WearChildren(names, keys)
    local wore = {} -- the names worn, in order
    if (names == nil) or (#keys == 0) then return wore end
    local done = {}
    for _, n in ipairs(names) do
        local prefix = string.match(n, '^(.-)_[Dd][Ee][Ff][Aa][Uu][Ll][Tt]$')
        for _, key in ipairs(keys) do
            for _, cand in ipairs({ n .. '_' .. key, (prefix ~= nil) and (prefix .. '_' .. key) or nil }) do
                local set = gcinclude.FindSet(cand)
                if (set ~= nil) and not done[set] then
                    done[set] = true
                    gFunc.EquipSet(set)
                    wore[#wore + 1] = cand
                end
            end
        end
    end
    return wore
end

-- The midcast child keys for the current spell.
function gcinclude.SpellChildKeys()
    local keys = {}
    local target, player = gData.GetActionTarget(), gData.GetPlayer()
    if (target ~= nil) and (player ~= nil) then
        if (target.Name == player.Name) then keys[#keys + 1] = 'Self'
        elseif (target.Type ~= 'Monster') then keys[#keys + 1] = 'Others' end
    end
    if gcinclude.BurstWanted() then keys[#keys + 1] = 'Burst' end
    return keys
end

-- Job-file helpers.
-- The weapon mode on (/wm), nil for none.
local function weaponMode()
    local weapon = gcdisplay.GetCycle('Weapons')
    return gcinclude.IsWeaponValue(weapon) and weapon or nil
end

-- <name>_<weapon><suffix> for the weapon mode on (Tp_Chango, Dt_Chango_Acc); when the file has none, <name>_2h /
-- <name>_1h<suffix> by the Main's type (MainHands). nil: none of them in the file.
local function weaponVariant(name, weapon, suffix)
    suffix = suffix or ''
    local set = (weapon ~= nil) and gcinclude.FindSet(name .. '_' .. weapon .. suffix) or nil
    if (set ~= nil) then return set end
    if (gcinclude.FindSet(name .. '_2h' .. suffix) == nil) and (gcinclude.FindSet(name .. '_1h' .. suffix) == nil) then
        return nil -- the usual case: no type sets, so no weapon layer built to look
    end
    local hands = gcinclude.MainHands()
    return (hands ~= nil) and gcinclude.FindSet(name .. '_' .. hands .. suffix) or nil
end

-- Wears <prefix>_Default, then <prefix>_<weapon> for the weapon mode on (/wm Chango: Tp_Chango, Ws_Chango), then
-- <prefix>_<mode> when /mset is not Default, then <prefix>_<weapon>_<mode> (Tp_Chango_Acc); each one only when the
-- job file has it. A weapon with no set of its own takes <prefix>_2h / <prefix>_1h (Tp_2h_Acc), by its type. A
-- missing <prefix>_Acc is named once, not on every HandleDefault (LAC's 'Set not found').
local modeWarned = {}
function gcinclude.EquipMode(prefix)
    local base = gcinclude.FindSet(prefix .. '_Default')
    if (base ~= nil) then gFunc.EquipSet(base) end
    local weapon = weaponMode()
    local w = weaponVariant(prefix, weapon)
    if (w ~= nil) then gFunc.EquipSet(w) end
    local mode = gcdisplay.GetCycle('MeleeSet')
    if (mode == 'Default') then return end
    local n = prefix .. '_' .. mode
    local set = gcinclude.FindSet(n) -- index, not LAC's scan of every set
    local both = weaponVariant(prefix, weapon, '_' .. mode)
    if (set ~= nil) then
        gFunc.EquipSet(set)
    elseif (both == nil) and (mode == 'Acc') and (modeWarned[n] == nil) then -- other modes are optional per set
        modeWarned[n] = true
        gcinclude.Err('no ' .. n .. ' set: ' .. prefix .. '_Default stays (add ' .. n .. ' or /mset base)')
    end
    if (both ~= nil) then gFunc.EquipSet(both) end
end

-- The idle base: Idle, then Idle_<weapon> (as EquipMode), then Idle_<mode> over it while idle (/idleset Refresh,
-- Regen, Regain; not engaged or resting), then Idle_<weapon>_<mode>. The job's own idle layers (pet, movement, /dt,
-- /kite) go on after it.
function gcinclude.EquipIdle()
    local idle = gcinclude.FindSet('Idle')
    if (idle ~= nil) then gFunc.EquipSet(idle) end
    local weapon = weaponMode()
    local w = weaponVariant('Idle', weapon)
    if (w ~= nil) then gFunc.EquipSet(w) end
    local mode = gcdisplay.GetCycle('IdleSet')
    if (mode == nil) or (mode == 'Default') then return end
    local player = gData.GetPlayer()
    if (player == nil) or (player.Status ~= 'Idle') then return end
    local n = 'Idle_' .. mode
    local set = gcinclude.FindSet(n)
    local both = weaponVariant('Idle', weapon, '_' .. mode)
    if (set ~= nil) then
        gFunc.EquipSet(set)
    elseif (both == nil) and (modeWarned[n] == nil) then
        modeWarned[n] = true
        gcinclude.Err('no ' .. n .. ' set: Idle stays (add ' .. n .. ' or /idleset default)')
    end
    if (both ~= nil) then gFunc.EquipSet(both) end
end

-- Ranged accuracy (/mset Acc, COR RNG PLD): the job's HandleMidshot wears Midshot_Acc when true.
function gcinclude.RangedAcc()
    return gcdisplay.GetCycle('MeleeSet') == 'Acc'
end

-- Wears the set named after an action (or Dt), then its weapon variant (Savage Blade_Naegling, Dt_Chango; else
-- Dt_2h / Dt_1h, as EquipMode), then its /mset variant, then both (Dt_Chango_Acc). False if there is none.
function gcinclude.ByName(name)
    local set = gcinclude.FindSet(name)
    if (set == nil) then return false end
    gFunc.EquipSet(set)
    local weapon = weaponMode()
    local w = weaponVariant(name, weapon)
    if (w ~= nil) then gFunc.EquipSet(w) end
    local mode = gcdisplay.GetCycle('MeleeSet')
    if (mode ~= nil) and (mode ~= 'Default') then
        local v = gcinclude.FindSet(name .. '_' .. mode)
        if (v ~= nil) then gFunc.EquipSet(v) end
        local both = weaponVariant(name, weapon, '_' .. mode)
        if (both ~= nil) then gFunc.EquipSet(both) end
    end
    return true
end

-- 'Utsusemi: Ni' -> 'Utsusemi', 'Drain III' -> 'Drain'.
function gcinclude.Family(name)
    local base = string.match(name, '^(.-):') or name
    return (string.gsub(base, ' [IVX]+$', ''))
end

-- Dual Wield I: NIN Lv10, DNC Lv20, THF Lv83 (FFXIclopedia Dual Wield). BLU gets it from set spells, so
-- BLU.lua sets AlwaysDualWield. Levels are the effective ones (IPlayer GetMainJobLevel/GetSubJobLevel;
-- LAC data.lua calls the sub one SubJobSync): SJ Restriction drops the sub to Lv0 (FFXIclopedia), and
-- Sheol Gaol restricts support jobs (BG-Wiki), so a /NIN there can't dual wield. /dw on|off overrides.
gcinclude.DualWieldLevels = T{ NIN = 10, DNC = 20, THF = 83 }
gcinclude.DualWieldMode = 'auto'

-- The game refused a Sub weapon for lack of Dual Wield (BLU changing spells, a level sync): that item stays off
-- Sub and Dual Wield counts as off for SubRefuseHold seconds, instead of LAC re-sending it every packet.
gcinclude.SubRefuseHold = 15
gcinclude.SubRefused = {} -- [lower item name] = os.clock() it may be tried again
function gcinclude.OnSubRefused(itemId)
    local r = (itemId ~= nil) and (itemId > 0) and AshitaCore:GetResourceManager():GetItemById(itemId) or nil
    local name = ((r ~= nil) and (r.Name ~= nil)) and r.Name[1] or gcinclude.LastSubSent
    if (type(name) ~= 'string') then return end
    gcinclude.SubRefused[string.lower(name)] = os.clock() + gcinclude.SubRefuseHold
    gcinclude.NextDualCheck = 0 -- CheckDualWieldChange: 1h weapons now
end
function gcinclude.SubRefusedNow(item)
    local name = (type(item) == 'table') and item.Name or item
    if (type(name) ~= 'string') then return false end
    local untilT = gcinclude.SubRefused[string.lower(name)]
    return (untilT ~= nil) and (os.clock() < untilT)
end
local function subRefused()
    local now = os.clock()
    for name, untilT in pairs(gcinclude.SubRefused) do
        if (now < untilT) then return name end
        gcinclude.SubRefused[name] = nil
    end
    return nil
end

function gcinclude.DualWieldState()
    if (gcinclude.DualWieldMode == 'off') then return false, 'set by /dw off' end
    local refused = subRefused()
    if (refused ~= nil) then
        return false, 'the game refused ' .. refused .. ' in Sub, retry in ' .. gcinclude.SubRefuseHold .. 's'
    end
    if (gcinclude.DualWieldMode == 'on') then return true, 'set by /dw on' end
    if (gcinclude.AlwaysDualWield == true) then return true, 'AlwaysDualWield' end
    local p = AshitaCore:GetMemoryManager():GetPlayer()
    local main, ml = gcinclude.JobName(p:GetMainJob()), p:GetMainJobLevel()
    local need = gcinclude.DualWieldLevels[main or '']
    if (need ~= nil) and (ml >= need) then
        gcinclude.LastDualWield = true -- the zoning fallback below keeps this answer too
        return true, string.format('main %s Lv%d', main, ml)
    end
    if (p:GetIsZoning() ~= 0) or (ml == 0) then return (gcinclude.LastDualWield == true), 'zoning, kept last' end
    local sub, sl = gcinclude.JobName(p:GetSubJob()), p:GetSubJobLevel()
    need = gcinclude.DualWieldLevels[sub or '']
    local why = string.format('sub %s Lv%d', tostring(sub or 'none'), sl)
    local can = (need ~= nil) and (sl >= need)
    if can and (gcinclude.BuffCount('SJ Restriction') > 0) then can, why = false, why .. ', SJ Restriction' end
    gcinclude.LastDualWield = can
    return can, why
end

-- Inside WithBuffs (HandleDefault, the hold tick) the answer is worked out once: job, levels and buffs don't
-- change while one call runs. A forced weapon change (CheckDualWieldChange) asks DualWieldState itself.
function gcinclude.CanDualWield()
    if (buffCache == nil) then return (gcinclude.DualWieldState()) end
    if (dualWieldNow == nil) then dualWieldNow = ((gcinclude.DualWieldState()) == true) end
    return dualWieldNow
end

-- Dual Wield just lost (e.g. zoning into Sheol Gaol): put the 1h weapons on now, past the TP hold, since an
-- offhand weapon is no use without it. Gaining it back waits for the TP hold like any weapon change.
gcinclude.NextDualCheck = 0
function gcinclude.CheckDualWieldChange(now)
    if (now < gcinclude.NextDualCheck) then return false end
    gcinclude.NextDualCheck = now + 0.5
    local can, why = gcinclude.DualWieldState()
    if (buffCache ~= nil) then dualWieldNow = can end -- the weapon layer built below sees this answer
    local was = gcinclude.DualWieldSeen
    gcinclude.DualWieldSeen = can
    if (was == true) and (can == false) then
        gcinclude.Say('Dual Wield off (' .. why .. '): 1h weapons')
        gcinclude.ApplyWeapons(true)
        return true
    end
    return false
end

function gcinclude.DualWieldCommand(args)
    local arg = (args[2] ~= nil) and string.lower(args[2]) or nil
    if (arg == 'on') or (arg == 'off') or (arg == 'auto') then gcinclude.DualWieldMode = arg end
    local can, why = gcinclude.DualWieldState()
    gcinclude.Say('Dual Wield: ' .. (can and 'yes' or 'no') .. ' (' .. why .. ')')
    -- a switch to no DW forces the 1h set next tick
    if (arg ~= nil) then gcinclude.NextDualCheck = 0; gcinclude.ApplyWeapons() end
end

-- THF main: /th keeps TH on the whole time, tagged or not. Other jobs: only to tag the mob.
-- A job file can set gcinclude.THFullTime = true/false to choose.
local function thFullTime()
    local f = gcinclude.THFullTime
    if (f == nil) then
        local p = gData.GetPlayer()
        f = (p ~= nil) and (p.MainJob == 'THF')
    end
    return (f == true)
end

-- No-ops kept so job files copied from older versions still load. Don't remove.
function gcinclude.DoMoonshade() end

-- TH gear, never for an action on you or an ally. Full time (THF): always otherwise, and Main/Sub/Range are
-- left to BuildWeaponLayer so they stay. Other jobs: only for an action at an untagged mob, or engaged with
-- one targeted; not at rest; the whole set (Sub only if you can dual wield). force skips the target checks
-- (AoE TH spells, which can be self-targeted). The worn set is built once per set table and case (the set
-- itself when nothing is dropped, so the editor's Result names it).
local thGear, thGearOf, thGearKey = nil, nil, nil
function gcinclude.CheckTH(force)
    if (gcdisplay.GetToggle('TH') ~= true) then return end
    local set = gcinclude.FindSet('TH')
    if (set == nil) then return end
    local acting = gData.GetAction()
    if (acting ~= nil) and gcinclude.Skipped('THSkip', acting.Name) then return end -- that spell's own set stays
    local full = thFullTime()
    if (force ~= true) then
        local actionTarget = gData.GetActionTarget()
        if (actionTarget ~= nil) and (actionTarget.Type ~= 'Monster') then return end
        if not full then
            local target = actionTarget
            if (target == nil) then
                local p = gData.GetPlayer()
                if (p == nil) or (p.Status ~= 'Engaged') then return end
                target = gData.GetTarget()
            end
            if (target == nil) or (target.Type ~= 'Monster') then return end
            if (gcauto ~= nil) and (gcauto.IsTagged ~= nil) and gcauto.IsTagged(target.Id) then return end
        end
    end
    local dw = full or gcinclude.CanDualWield()
    local key = full and 'full' or (dw and 'dw' or '1h')
    if (thGearOf ~= set) or (thGearKey ~= key) then
        thGear, thGearOf, thGearKey = set, set, key
        local function drop(k)
            local s = slotOf(k)
            return (full and gcinclude.HoldSlots:contains(s)) or ((s == 2) and not dw)
        end
        for k, _ in pairs(set) do
            if drop(k) then
                thGear = {}
                for k2, v2 in pairs(set) do
                    if not drop(k2) then thGear[k2] = v2 end
                end
                break
            end
        end
    end
    gFunc.EquipSet(thGear)
    gcinclude.THWorn = true -- this action wears TH: the element layer leaves the TH waist alone
end
-- /hoxne: Hoxne sets, their buff combos, and keeping range weapons that need ammo off the Ampulla.

-- Bows, guns and crossbows (Archery 25 / Marksmanship 26) need matching ammo, so the ampulla can't sit with
-- them. While Hoxne is Locked, any set asking for one in Range has that entry dropped.
gcinclude.AmmoSkills = T{25, 26}
local ammoWeapon = {}
function gcinclude.NeedsAmmo(item)
    local name = (type(item) == 'table') and item.Name or item
    if (type(name) ~= 'string') then return false end
    name = string.lower(name)
    if (ammoWeapon[name] == nil) then
        local r = AshitaCore:GetResourceManager():GetItemByName(name, 0)
        ammoWeapon[name] = (r ~= nil) and gcinclude.AmmoSkills:contains(r.Skill)
    end
    return ammoWeapon[name]
end

function gcinclude.HoxneOn()
    return (gcdisplay.GetCycle('Hoxne') == 'Locked')
end

-- Hoxne sets while /hoxne is Locked and Enchantment is up (Ampulla's Double Attack +100%, FFXIclopedia):
-- Hoxne_Tp / _Idle (not moving) / _Dt (with /dt), none with /kite; WS: Hoxne_Ws then Hoxne_<ws>. Each takes its
-- /mset variant, then buff combos (fewest first, A-Z), then _Dt on a WS with /dt (docs/sets.md). Over job sets.
function gcinclude.HoxneActive()
    return gcinclude.HoxneOn() and (gcinclude.BuffCount('Enchantment') > 0)
end

-- Combos by base set, read from the set names once per profile: 'hoxne_tp' -> { {buffs, set}, ... }, fewest
-- buffs first, then by name. No buff name has '_' or '&' (Windower resources buffs.lua), so they split cleanly.
local hoxneCombos, hoxneCombosOf = {}, nil
local function hoxneCombosFor(base)
    if (type(gProfile.Sets) ~= 'table') then return nil end
    if (hoxneCombosOf ~= gProfile.Sets) then
        hoxneCombos, hoxneCombosOf = {}, gProfile.Sets
        for key, set in pairs(gProfile.Sets) do
            local b, suffix
            if (type(key) == 'string') and (type(set) == 'table') then
                b, suffix = string.match(key, '^(.+)_([^_]+)$')
            end
            if (b ~= nil) and (string.sub(string.lower(b), 1, 6) == 'hoxne_') then
                local buffs = T{}
                for name in string.gmatch(suffix, '[^&]+') do buffs:append(name) end
                local list = hoxneCombos[string.lower(b)] or T{}
                list:append({ buffs = buffs, set = set, key = string.lower(suffix), name = key })
                hoxneCombos[string.lower(b)] = list
            end
        end
        for _, list in pairs(hoxneCombos) do
            table.sort(list, function(x, y)
                if (#x.buffs ~= #y.buffs) then return #x.buffs < #y.buffs end
                return x.key < y.key
            end)
        end
    end
    return hoxneCombos[string.lower(base)]
end

-- Each combo of a Hoxne set whose buffs are all up.
local function wearHoxneCombos(name)
    local list = hoxneCombosFor(name)
    if (list == nil) then return end
    for _, c in ipairs(list) do
        local up = true
        for _, b in ipairs(c.buffs) do
            if (gcinclude.BuffCount(b) == 0) then up = false; break end
        end
        if up then gcinclude.ByName(c.name) end -- the combo, then its /mset variant
    end
end

-- A Hoxne set, its /mset variant, then its combos (for a job file's own use; GoomSwap's own order below puts the
-- combos after the plain buff sets).
function gcinclude.WearHoxne(name)
    gcinclude.ByName(name)
    wearHoxneCombos(name)
end

-- The Hoxne set idle/engaged takes now: Hoxne_Dt on /dt, else Hoxne_Tp engaged, Hoxne_Idle idle; nil: none.
local function hoxneBase(player)
    if (player == nil) or (not gcinclude.HoxneActive()) or (gcdisplay.GetToggle('Kite') == true) then return nil end
    if (gcdisplay.GetToggle('DTset') == true) then return 'Hoxne_Dt' end
    if (player.Status == 'Engaged') then return 'Hoxne_Tp' end
    if (player.Status == 'Idle') and (player.IsMoving ~= true) then return 'Hoxne_Idle' end
    return nil
end
function gcinclude.CheckHoxneSets(player) -- the Hoxne set (and its /mset version); its buff combos come later
    local base = hoxneBase(player)
    if (base ~= nil) then gcinclude.ByName(base) end
end
-- Its buff combos (Hoxne_Tp_Berserk, Hoxne_Tp_Berserk&Aggressor): after the plain buff sets (Buffs['Berserk']),
-- so a Hoxne + buff set wins the slots both name and layers over the buff set (CheckWeapons, after CheckBuffSets).
function gcinclude.CheckHoxneCombos(player)
    local base = hoxneBase(player)
    if (base ~= nil) then wearHoxneCombos(base) end
end

-- The Hoxne WS sets (Hoxne_Ws, Hoxne_<WS>) and, on /dt, their _Dt; their buff combos come after Buffs_Ws.
local function hoxneWsName()
    local ws = gData.GetAction()
    return (ws ~= nil) and (ws.Name ~= nil) and ('Hoxne_' .. ws.Name) or nil
end
function gcinclude.CheckHoxneWs()
    if not gcinclude.HoxneActive() then return end
    local name = hoxneWsName()
    gcinclude.WornSets = {} -- the Hoxne WS sets worn, for their /dt children
    gcinclude.ByName('Hoxne_Ws')
    if (name ~= nil) then gcinclude.ByName(name) end
    local worn = gcinclude.WornSets
    gcinclude.WornSets = nil
    -- Hoxne_Ws_Dt, Hoxne_Ws_SubtleBlow_Dt...
    if (gcdisplay.GetToggle('DTset') == true) then gcinclude.WearChildren(worn, {'Dt'}) end
end
-- Their buff combos (Hoxne_Ws_Berserk...), after Buffs_Ws so they win the slots both name; then their _Dt on /dt.
function gcinclude.CheckHoxneWsCombos()
    if not gcinclude.HoxneActive() then return end
    local name = hoxneWsName()
    gcinclude.WornSets = {}
    wearHoxneCombos('Hoxne_Ws')
    if (name ~= nil) then wearHoxneCombos(name) end
    local worn = gcinclude.WornSets
    gcinclude.WornSets = nil
    if (gcdisplay.GetToggle('DTset') == true) then gcinclude.WearChildren(worn, {'Dt'}) end
end

function gcinclude.DropAmmoWeapon(set)
    if (type(set) == 'string') then set = gcinclude.FindSet(set) or set end
    if (type(set) ~= 'table') or (not gcinclude.HoxneOn()) then return set end
    for k, v in pairs(set) do
        if (slotOf(k) == 3) and gcinclude.NeedsAmmo(v) then
            local out = {}
            for k2, v2 in pairs(set) do if (k2 ~= k) then out[k2] = v2 end end
            return out
        end
    end
    return set
end

-- Filters every gFunc.EquipSet / gFunc.Equip call, job files included. gFunc outlives profile reloads,
-- so the originals are kept on it and wrapped once.
function gcinclude.WrapEquip()
    if (gFunc.GcRawEquipSet ~= nil) then return end
    gFunc.GcRawEquipSet, gFunc.GcRawEquip = gFunc.EquipSet, gFunc.Equip
    -- Each also tags the buffer writes it makes for the /gcedit layer record (gcaction.RecLabel), only while a
    -- handler is being recorded (gcaction.Recording): the tag's reason walks the call stack.
    local function recording()
        return (gcaction ~= nil) and (gcaction.RecLabel ~= nil) and (gcinclude ~= nil) and (gcinclude.CallChain ~= nil)
            and ((gcaction.Recording == nil) or gcaction.Recording())
    end
    gFunc.EquipSet = function(set)
        if (gcinclude ~= nil) and (gcinclude.NoteSet ~= nil) then gcinclude.NoteSet(set) end
        local rec = recording()
        local oldL, oldW = nil, nil
        if rec then
            oldL, oldW = gcaction.RecLabel(gcinclude.SetLabel(set) or gcinclude.CallerLabel(2), gcinclude.CallChain(2))
        end
        if (gcinclude ~= nil) and (gcinclude.DropAmmoWeapon ~= nil) then set = gcinclude.DropAmmoWeapon(set) end
        local r = gFunc.GcRawEquipSet(set)
        if rec then gcaction.RecLabel(oldL, oldW) end
        return r
    end
    gFunc.Equip = function(slot, item)
        if (gcinclude ~= nil) and (gcinclude.HoxneOn ~= nil) and gcinclude.HoxneOn() and (slotOf(slot) == 3)
            and gcinclude.NeedsAmmo(item) then
            return
        end
        local rec = recording()
        local oldL, oldW = nil, nil
        if rec then
            oldL, oldW = gcaction.RecLabel(nil, nil)
            if (oldL ~= nil) then gcaction.RecLabel(oldL, oldW) else gcaction.RecLabel(gcinclude.CallerLabel(2),
                gcinclude.CallChain(2)) end
        end
        local r = gFunc.GcRawEquip(slot, item)
        if rec then gcaction.RecLabel(oldL, oldW) end
        return r
    end
end

-- Sub vs Main (FFXIclopedia Category:Grips): a two-handed main (Great Sword, Great Axe, Scythe, Polearm, Great
-- Katana, Staff: skills 4 6 7 8 10 12) takes only a grip in Sub, and a grip needs a two-handed main. LAC's equip
-- buffer is shadowed so the check sees the final Main of the handler; a Sub that can't go with it is dropped.
gcinclude.TwoHandSkills = T{4, 6, 7, 8, 10, 12}
local resByName, resById = {}, {}
local function itemRes(v)
    local name = (type(v) == 'table') and v.Name or v
    if (type(name) ~= 'string') then return nil end
    local key = string.lower(name)
    local r = resByName[key]
    if (r == nil) then
        r = AshitaCore:GetResourceManager():GetItemByName(name, 0) or false
        resByName[key] = r
    end
    return r or nil
end
local function wornMainRes()
    local e = gEquip.GetCurrentEquip(1)
    local id = (e ~= nil) and (e.Item ~= nil) and e.Item.Id or nil
    if (id == nil) then return nil end
    local r = resById[id]
    if (r == nil) then
        r = AshitaCore:GetResourceManager():GetItemById(id) or false
        resById[id] = r
    end
    return r or nil
end
local function isGrip(r)
    return (r.Slots == 2) and (r.ShieldSize == 0) and (r.Skill == 0)
end

-- One-handed: Dagger, Sword, Axe, Katana, Club (skills 2 3 5 9 11). Hand-to-Hand (1) is neither kind.
gcinclude.OneHandSkills = T{2, 3, 5, 9, 11}

-- '2h' or '1h' for the Main the weapon layer puts on (the weapon mode's, a /mw pick), else the one worn now: which
-- of Tp_2h / Tp_1h a weapon with no set of its own takes. nil: Hand-to-Hand, no weapon, or not known.
function gcinclude.MainHands()
    local layer = (gcinclude.BuildWeaponLayer ~= nil) and gcinclude.BuildWeaponLayer() or nil
    local main = (layer ~= nil) and layer.Main or nil
    local r = ((main ~= nil) and itemRes(main)) or wornMainRes()
    if (r == nil) then return nil end
    if gcinclude.TwoHandSkills:contains(r.Skill) then return '2h' end
    if gcinclude.OneHandSkills:contains(r.Skill) then return '1h' end
    return nil
end

-- main/sub: LAC item tables ({ Name = ... }) or nil. True when they can be worn together, or unknown.
function gcinclude.SubFits(main, sub)
    local subName = (type(sub) == 'table') and sub.Name or sub
    if (type(subName) ~= 'string') or gcinclude.WeaponKeywords:contains(string.lower(subName)) then return true end
    local mainName = (type(main) == 'table') and main.Name or main
    if (type(mainName) == 'string') and ((string.lower(mainName) == 'remove')
        or (string.lower(mainName) == 'displaced')) then
        return true
    end
    local mainRes
    if (type(mainName) == 'string') and not gcinclude.WeaponKeywords:contains(string.lower(mainName))
        and (gState.Disabled[1] ~= true) then
        mainRes = itemRes(main)
    else
        mainRes = wornMainRes()
    end
    local subRes = itemRes(sub)
    if (mainRes == nil) or (subRes == nil) then return true end
    return gcinclude.TwoHandSkills:contains(mainRes.Skill) == isGrip(subRes)
end

-- RangeAmmo = { ['Sparrowhawk +2'] = 'Chrono Arrow' }: with that range weapon on, ammo of another kind (the name's
-- last word: Arrow, Bullet, Bolt) is swapped for this one. The item data Ashita gives has no ammo kind, so the
-- job file says it; nil = keep the ammo as is.
function gcinclude.AmmoFor(range, ammo)
    local map = gcinclude.RangeAmmo
    if (type(map) ~= 'table') or (type(range) ~= 'string') or (type(ammo) ~= 'string') then return nil end
    local want = nil
    for k, v in pairs(map) do
        if (string.lower(k) == string.lower(range)) then want = v end
    end
    local function kind(n) return string.lower(string.match(n, '(%a+)%s*$') or '') end
    local shot = { arrow = true, bullet = true, bolt = true } -- anything else in Ammo (Ampulla, tathlum, remove) stays
    if (type(want) == 'string') and shot[kind(ammo)] and (kind(want) ~= kind(ammo)) then return want end
    return nil
end

function gcinclude.WrapBuffer()
    if (gEquip == nil) or (gEquip.GcRawToBuffer ~= nil) then return end
    gEquip.GcRawToBuffer, gEquip.GcRawClear, gEquip.GcRawProcess = gEquip.EquipItemToBuffer, gEquip.ClearBuffer,
        gEquip.ProcessBuffer
    gEquip.GcRawImmediate = gEquip.ProcessImmediateBuffer
    local shadow = {}
    gcinclude.ShadowItem = function(slot) return shadow[slot] end
    -- gcaction.Rec*: the /gcedit layer record (each write, who made it, the final gear).
    local function rec(name,
        ...) if (gcaction ~= nil) and (gcaction[name] ~= nil) then pcall(gcaction[name], ...) end end
    gEquip.ClearBuffer = function(...)
        shadow = {}
        rec('RecClear')
        return gEquip.GcRawClear(...)
    end
    gEquip.EquipItemToBuffer = function(slot, itemTable, immediate)
        local blocked = false
        if (immediate ~= true) and (type(itemTable) == 'table') then
            local cur = shadow[slot]
            -- LAC drops it (equip.lua EquipItemToBuffer)
            blocked = (cur ~= nil) and (cur.Locked == true) and (itemTable.Locked ~= true)
            if not blocked then shadow[slot] = (itemTable.Name ~= 'ignore') and itemTable or nil; end
        end
        rec('RecWrite', slot, itemTable, immediate, blocked)
        return gEquip.GcRawToBuffer(slot, itemTable, immediate)
    end
    gEquip.ProcessBuffer = function(...)
        local sub = shadow[2]
        if (sub ~= nil) and (gcinclude ~= nil) and (gcinclude.SubRefusedNow ~= nil)
            and gcinclude.SubRefusedNow(sub) then
            gEquip.GcRawToBuffer(2, { Name = 'ignore' }) -- refused for lack of Dual Wield: not re-sent every packet
            rec('RecWrite', 2, 'ignore', false, false, 'Sub held: no Dual Wield')
        elseif (sub ~= nil) and (gcinclude ~= nil) and (gcinclude.SubFits ~= nil) then
            local ok, fits = pcall(gcinclude.SubFits, shadow[1], sub)
            if ok and (fits == false) then
                gEquip.GcRawToBuffer(2, { Name = 'ignore' })
                rec('RecWrite', 2, 'ignore', false, false, 'Sub dropped: does not fit Main')
            end
            if (gcinclude.SubRefusedNow ~= nil) and not (ok and (fits == false)) then
                gcinclude.LastSubSent = sub.Name
            end
        end
        -- RangeAmmo, only when this swap touches Range or Ammo (the worn gear is read only then)
        if (type(gcinclude.RangeAmmo) == 'table') and ((shadow[3] ~= nil) or (shadow[4] ~= nil)) then
            local worn = ((shadow[3] == nil) or (shadow[4] == nil)) and gData.GetEquipment() or {}
            local range, ammo = shadow[3] or worn.Range, shadow[4] or worn.Ammo
            local fix = gcinclude.AmmoFor(range and range.Name, ammo and ammo.Name)
            if (fix ~= nil) then
                gEquip.GcRawToBuffer(4, { Name = fix })
                rec('RecWrite', 4, fix, false, false, 'Ammo: ' .. fix .. ' for ' .. range.Name)
            end
        end
        rec('RecEnd')
        return gEquip.GcRawProcess(...)
    end
    if (gEquip.GcRawImmediate ~= nil) then
        gEquip.ProcessImmediateBuffer = function(...) -- a delayed midcast (LAC state.lua)
            rec('RecEnd')
            return gEquip.GcRawImmediate(...)
        end
    end
end

function gcinclude.CheckHoxne()
    local state = gcdisplay.GetCycle('Hoxne')
    if (state == 'Locked') then
        gcinclude.HoxneLocked = true
        -- Every call takes any lock slot nobody holds, so one that was /locked or held when Hoxne went Locked
        -- is taken as soon as it is free (/unlock no longer strips Hoxne's own: locks have owners).
        local take = T{}
        for _, slot in ipairs(gcinclude.SlotNumbers(gcinclude.settings.HoxneLockSlots, 1)) do
            if (gcinclude.LockedSlots[slot] == nil) then take:append(slot) end
        end
        if (#take > 0) then
            -- Settle Ammo/Range before locking them, else a bow already on stays locked in.
            local range = gData.GetEquipment().Range
            local settle = { Ammo = gcinclude.settings.HoxneItem }
            -- the Ampulla going on drops the bow
            if (range ~= nil) and gcinclude.NeedsAmmo(range.Name) then settle.Range = 'displaced' end
            gcinclude.ForceUnlocked(settle)
            gcinclude.LockSlots(take, 'hoxne')
        end
    elseif (gcinclude.HoxneLocked == true) then
        gcinclude.HoxneLocked = false
        gcinclude.UnlockSlots(nil, 'hoxne')
    end
    if (state ~= 'Locked') then return end
    local set = { Ammo = gcinclude.settings.HoxneItem }
    local range = gData.GetEquipment().Range
    -- the game drops it for the Ampulla
    if (range ~= nil) and gcinclude.NeedsAmmo(range.Name) then set.Range = 'displaced' end
    gFunc.EquipSet(set)
end

-- Keybinds: GoomSwap's default keys, settings.Keybinds, and /gckey.
gcinclude.BoundKeys = T{}

-- What a key runs: a GoomSwap command, or a chat command as is when it starts with / (e.g. /lac reload).
function gcinclude.KeyTarget(cmd)
    cmd = tostring(cmd)
    if (string.sub(cmd, 1, 1) == '/') then return cmd end
    return '/lac fwd ' .. cmd
end

function gcinclude.ApplyKeybinds()
    local binds = gcinclude.settings.Keybinds
    if (type(binds) ~= 'table') then return end
    for _, bind in ipairs(binds) do
        if (type(bind) == 'table') and (bind[1] ~= nil) and (bind[2] ~= nil) then
            gcinclude.Queue('/bind ' .. bind[1] .. ' ' .. gcinclude.KeyTarget(bind[2]))
            if not gcinclude.BoundKeys:contains(bind[1]) then gcinclude.BoundKeys:append(bind[1]) end
        end
    end
end

function gcinclude.ClearKeybinds()
    for _, key in ipairs(gcinclude.BoundKeys) do
        gcinclude.Queue('/unbind ' .. key)
    end
    gcinclude.BoundKeys = T{}
end

-- /gckey's command from its args: an action's name goes back in quotes, '/ma Cure IV <stpc>' -> '/ma "Cure IV" <stpc>'.
-- Not /ms: with Multisend loaded that is its command (/ms sendto <name> ...), and quoting would break it.
local KEY_ACTIONS = T{'/ma', '/magic', '/ja', '/jobability', '/ws', '/weaponskill', '/pet', '/item',
    '/monsterskill', '/song', '/ninjutsu', '/nin'}
function gcinclude.KeyArgs(args, first)
    local rest = {}
    for i = first, #args do rest[#rest + 1] = tostring(args[i]) end
    local head = string.lower(rest[1] or '')
    if KEY_ACTIONS:contains(head) and (#rest >= 2) then
        local last, target = #rest, nil
        if (#rest >= 3) and (string.match(rest[last], '^<.+>$') or tonumber(rest[last])) then
            target = rest[last]
            last = last - 1
        end
        local name = string.gsub(table.concat(rest, ' ', 2, last), '"', '')
        return head .. ' "' .. name .. '"' .. ((target ~= nil) and (' ' .. target) or '')
    end
    for i, a in ipairs(rest) do
        if string.find(a, ' ', 1, true) then rest[i] = '"' .. a .. '"' end
    end
    return table.concat(rest, ' ')
end

function gcinclude.KeyCommand(args)
    if (args[2] == nil) or (args[3] == nil) then
        gcinclude.Say('usage: /gckey <key> <command>  (key uses Ashita names and ! ^ + @ # modifiers)')
        return
    end
    local cmd = gcinclude.KeyArgs(args, 3)
    gcinclude.Queue('/bind ' .. args[2] .. ' ' .. gcinclude.KeyTarget(cmd))
    if not gcinclude.BoundKeys:contains(args[2]) then gcinclude.BoundKeys:append(args[2]) end
    gcinclude.Say(args[2] .. ' -> ' .. ((string.sub(cmd, 1, 1) == '/') and cmd or ('/' .. cmd)))
end

-- Zoning: from the server's reply to the zone line (0x000B, XiPackets GP_SERV_COMMAND_LOGOUT; LogoutState 4 =
-- cancelled) until 3s after zone-in (0x000A), or while Ashita's player says so. Nothing is sent by itself
-- meanwhile: the buff list reads empty then, and an /item sent mid-zone took the Shorthand plugin down.
gcinclude.ZoneOutAt, gcinclude.ZoneInAt = nil, -1e9
function gcinclude.OnZoneOut(state)
    gcinclude.ZoneOutAt = (state ~= 4) and os.clock() or nil
end
function gcinclude.Zoning()
    local now = os.clock()
    if (gcinclude.ZoneOutAt ~= nil) and (now - gcinclude.ZoneOutAt < 60) then return true end
    if (now < gcinclude.ZoneInAt + 3) then return true end
    local p = AshitaCore:GetMemoryManager():GetPlayer()
    return (p ~= nil) and (p:GetIsZoning() ~= 0)
end

-- Zoning: item uses stop (zoning drops an enchantment anyway: BG-Wiki Hoxne Ampulla), slots are given back,
-- and /hoxne goes back to Off, so nothing is used on arrival.
function gcinclude.OnZone()
    gcinclude.ZoneOutAt, gcinclude.ZoneInAt = nil, os.clock()
    gcinclude.HoxneGoneSince = nil
    for index, _ in pairs(gcinclude.Enchants) do gcinclude.ReleaseEnchant(index) end
    gcinclude.HoxneRetryAt = 0
    if gcinclude.HoxneOn() then
        gcinclude.SetWeaponCycle('Hoxne', 'Off', true)
        gcinclude.CheckHoxne()
        gcinclude.Say('Hoxne: Off (zoned)')
    end
end

-- /hoxne's Ampulla use: when it goes on, retries, and Enchantment watching.
-- Hoxne Ampulla (BG-Wiki): Double Attack +100% for 30 min as the Enchantment status (BG-Wiki Category:Enchantment;
-- id 162 in Windower's buff resources), 60s recast, 5s use delay, lost when unequipped or on zoning.
-- While /hoxne is Locked and the Ampulla is in ammo with no Enchantment up, it is used (the use delay
-- counted from when it went on). Enchantment up: never used. /hoxne use uses it now. One go a minute.
-- Enchantment has to be gone 3s straight first: it drops as you cross a zone line, a moment before the
-- server's zone reply (0x000B) marks you as zoning.
gcinclude.HoxneRetryAt = 0
gcinclude.HoxneCheckAt = 0
gcinclude.HoxneGoneSince = nil
function gcinclude.CheckHoxneAuto(now)
    if (gcinclude.settings.HoxneAutoUse ~= true) or (now < gcinclude.HoxneCheckAt) then return end
    gcinclude.HoxneCheckAt = now + 1
    if (not gcinclude.HoxneOn()) or (gcinclude.BuffCount('Enchantment') > 0) then
        gcinclude.HoxneGoneSince = nil; return
    end
    gcinclude.HoxneGoneSince = gcinclude.HoxneGoneSince or now
    if (now < gcinclude.HoxneGoneSince + 3) or (now < gcinclude.HoxneRetryAt) then return end
    local r = AshitaCore:GetResourceManager():GetItemByName(gcinclude.settings.HoxneItem, 0)
    if (r == nil) or (equippedId(4) ~= r.Id) then return end
    if (gcinclude.Enchants[4] ~= nil) or (gState.PlayerAction ~= nil) then return end
    local p = gData.GetPlayer()
    if (p == nil) or ((p.Status ~= 'Idle') and (p.Status ~= 'Engaged')) or (p.IsMoving == true) then return end
    for _, b in ipairs(gcinclude.HardCC) do
        if (gcinclude.BuffCount(b) > 0) then return end
    end
    gcinclude.HoxneRetryAt = now + 60
    gcinclude.UseEnchanted(gcinclude.settings.HoxneItem, 'Ammo', 'hoxne')
end

-- Asleep under Stoneskin: damage it absorbs can't wake you (FFXIclopedia Sleep), so cancel it (/cancel: Ashita's
-- debuff addon). Two tries per sleep, 3s apart; Stoneskin still up after both: said once, not retried.
gcinclude.SleepCancelAt, gcinclude.SleepCancelTries = 0, 0
function gcinclude.CheckSleepStoneskin(now)
    if (gcinclude.settings.SleepCancelStoneskin ~= true) or (now < gcinclude.SleepCancelAt) then return end
    if (gcinclude.BuffCount('Sleep') == 0) or (gcinclude.BuffCount('Stoneskin') == 0) then
        gcinclude.SleepCancelTries = 0
        return
    end
    gcinclude.SleepCancelAt = now + 3
    gcinclude.SleepCancelTries = gcinclude.SleepCancelTries + 1
    if (gcinclude.SleepCancelTries <= 2) then
        gcinclude.Queue('/cancel Stoneskin')
    elseif (gcinclude.SleepCancelTries == 3) then
        gcinclude.Err('/cancel Stoneskin did nothing: load Ashita\'s debuff addon (/addon load debuff)')
    end
end

-- Entering a Dynamis - Divergence zone (named "Dynamis - <city> [D]", per SE's Nov 2025 update notes): a reminder
-- that /dynamisrp holds the job neck. Leaving one for a zone that isn't: /dynamisrp goes off by itself, so your normal
-- neck comes back (a /dynamisrp turned on outside Dynamis stays). Run from the hold tick, never mid-zone.
gcinclude.LastZone, gcinclude.LastZoneDivergence = nil, false
function gcinclude.CheckZoneNotes()
    local zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0)
    if (zone == nil) or (zone == 0) or (zone == gcinclude.LastZone) then return end
    gcinclude.LastZone = zone
    local name = AshitaCore:GetResourceManager():GetString('zones.names', zone) or ''
    local divergence = (string.find(name, 'Dynamis', 1, true) ~= nil) and (string.find(name, '[D]', 1, true) ~= nil)
    local left = gcinclude.LastZoneDivergence and not divergence
    gcinclude.LastZoneDivergence = divergence
    if divergence then
        gcinclude.Say('Dynamis - Divergence: /dynamisrp holds your best job neck (RP)')
    elseif left and (gcinclude.Holds['dynamisrp'] ~= nil) then
        gcinclude.ReleaseHold('dynamisrp')
        gcinclude.Say('dynamisrp: off (left Dynamis - Divergence)')
    end
end

-- settings.<key> plus the job file's gcinclude.<key>, as Skipped() reads them
function gcinclude.SkipList(key)
    local out = {}
    for _, l in ipairs({ gcinclude.settings[key] or {}, gcinclude[key] or {} }) do
        if (type(l) == 'table') then
            for _, n in ipairs(l) do out[#out + 1] = n end
        end
    end
    return out
end

function gcinclude.Help()
    local skip, thskip = gcinclude.SkipList('SIRSkip'), gcinclude.SkipList('THSkip')
    local lines = T{
        'gcconfig : character settings path; /gcconfig init creates a missing char.lua',
        'weapons: /wm [name|N|none|default|role] [force], /mw /sw /rw /ammoset [name|N|none] [force]',
        'defense: /def (cycle DT > MDT > Aminon > none), /dt /mdt /aminon (also locks main/sub, range/ammo if in the set; turns /sir off), /lock [slots|all] /unlock [slots|all]',
        'casting: /sir (SIR set over every midcast' .. ((#skip > 0) and (' except SIRSkip: ' .. table.concat(skip,
            ', ')) or '') .. '; off while Aminon is on)',
        'hoxne  : /hoxne (Off > Locked), /hoxne use',
        'toggles: /th (TH gear until the target is tagged' .. ((#thskip > 0) and (', not on THSkip: '
            .. table.concat(thskip,
            ', ')) or '')
            .. '; TH-set weapons while on), /kite, /mset [sb|acc|base] (no word: Base > SubtleBlow > Acc), /wsset [default|low|high|pdl|acc|sb] (low: <WS set>_LowBuff, high: <WS set>_HighBuff, pdl: <WS set>_PDL, acc: <WS set>_Acc, sb: <WS set>_SubtleBlow)',
        'hud    : /gchud [on|off|debug] (the other boxes, dropped under the bar)',
        'checks : /checksets [all], /gcperf (timings in chat every 10s)',
        'ws     : /wsdistance [on|off|N] (no word: the check and your target\'s reach; N = the least reach)',
        'swap   : /smartswap [on|off], /dw [on|off|auto] (dual wield: shows why; off = 1h weapon sets)',
        'holds  : /capacity /jubilee /dynamisrp /abyproc [on|off]',
        'items  : /gce <item> | cancel, /warpring /mea /holla /dem',
        'checks : failing actions cancel, reason in chat',
        'gear   : /autogear [on|off|regen N|refresh N|dt N|petdt N], /gcbuild [JOB] (the example with your gear, as <JOB>.proposed.lua), /gcimport <file> [JOB] (a GearSwap file\'s sets, the same way), /gcedit [set|last [slot]] (set editor window, Ashita; last: the set your last action used)',
        'bar    : /gcbar [on|off|pos x y|reset|scale N|theme name]',
        'grid   : /gcgear [on|off|pos x y|reset|scale N|alpha N|bg on|off] (worn gear 4x4: locks, holds, RP)',
        'on/off : every toggle takes on|off (no arg flips it, but /wsdistance shows); /def off|dt|mdt|aminon',
        'nuke   : Burst set is automatic on a nuke landing in a live skillchain; /burst = Burst set on every nuke (HUD: * on the nuke cell)',
        'keys   : F7 wm, Shift+F7 wm default, F9 mset, Ctrl+F9 tankset, Alt+F9 wsset, F10 def, Alt+F10 kite,',
        '         Win+F10 hoxne, Shift+F11 nukeset, Alt+F11 burst, Shift+F12 idleset, Alt+F12 def off, Ctrl+Win+Alt+F12 reload',
        '         /gckey <key> <command or /chat command>, e.g. /gckey ^F1 /ma "Cure IV" <stpc>',
        'idle   : /idleset [default|refresh|regen|regain|reraise] (Idle_<mode> over Idle while idle); /mset acc also wears Midshot_Acc (COR RNG PLD)',
        'every box: /mss /<command> (Multisend), one box: /ms sendto <name> /<command>',
    }
    for _, line in ipairs(lines) do
        print(chat.header('GoomSwap'):append(chat.message(line)))
    end
end

-- SIRD counts only while worn when each hit lands mid-cast (BG: must be in midcast),
-- so it is laid over the finished midcast set, never at rest.
-- SIRSkip / THSkip: settings.<key> (every job) plus gcinclude.<key> (the job file's own), exact names, any case.
function gcinclude.Skipped(key, name)
    if (type(name) ~= 'string') then return false end
    for _, skip in ipairs({ gcinclude.settings[key] or {}, gcinclude[key] or {} }) do -- either may be missing
        if (type(skip) == 'table') then
            for _, n in ipairs(skip) do
                if (string.lower(n) == string.lower(name)) then return true end
            end
        end
    end
    return false
end

function gcinclude.CheckSIR()
    if (gcdisplay.GetToggle('SIR') ~= true) then return end
    local action = gData.GetAction()
    if (action == nil) or gcinclude.Skipped('SIRSkip', action.Name) then return end
    local set = gcinclude.FindSet('SIR')
    if (set ~= nil) then gFunc.EquipSet(set) end
end

-- True when the Burst set belongs on this cast: always when a skillchain whose elements include the spell's
-- is live on the spell's target and the cast lands inside the window; /burst puts it on every nuke.
-- Job files call it where they used to check the Burst toggle, so their own layer order holds.
function gcinclude.BurstWanted()
    local spell = gData.GetAction()
    if (spell == nil) then return false end
    local skills = gcinclude.settings.MBSkills
    if (type(skills) ~= 'table') or (not skills:contains(spell.Skill)) then return false end
    if (gcdisplay.GetToggle('Burst') == true) then return true end
    local target = gData.GetActionTarget()
    if (target == nil) or (gcauto == nil) or (gcauto.BurstLive == nil) then return false end
    -- Midcast runs as the cast starts, so it lands after the learned cast time (gcauto.CastTime).
    -- No cast of this skill timed yet: only ask whether a chain is live now (wearing Burst gear on a
    -- miss costs little; skipping it on a hit costs the burst).
    local landsAt = nil
    if (spell.Resource ~= nil) then
        local t, learned = gcauto.CastTime(spell.Resource)
        if learned then landsAt = os.clock() + t end
    end
    return gcauto.BurstLive(target.Id, spell.Element, landsAt)
end

function gcinclude.InCombat(player)
    player = player or gData.GetPlayer()
    if (player ~= nil) and (player.Status == 'Engaged') then return true end
    return (gcauto ~= nil) and (gcauto.InCombat ~= nil) and gcauto.InCombat()
end

function gcinclude.CheckMDT()
    if (gcdisplay.GetToggle('MDTset') == true) then
        local set = gcinclude.FindSet('mdt')
        if (set ~= nil) then gFunc.EquipSet(set) end
    end
    gcinclude.CheckAminonLock()
    if (gcdisplay.GetToggle('Aminon') == true) then
        local set = gcinclude.FindFilled('Aminon') or gcinclude.FindSet('mdt')
        if (set ~= nil) then gFunc.EquipSet(set) end
    end
end

-- /aminon locks Main/Sub while on, plus Range/Ammo only when the weapon mode or the set names them (BRD
-- instruments keep swapping). Against Aminon you don't engage (TP comes from Regain), so the weapon mode (and
-- slot picks, _1h without Dual Wield) goes on even though you're idle; with no mode/pick for a slot, the
-- Aminon set's item, else what you wear. Then they're locked so action sets can't swap them; /wm while on
-- re-locks the new weapons (ApplyWeapons). Other slots still swap for actions.
-- Slots already /locked or Hoxne-locked are left alone; off releases only Aminon's own lock (/unlock never does).
gcinclude.AminonSlots = T{'Main', 'Sub', 'Range', 'Ammo'}
gcinclude.AminonAlways = T{1, 2} -- Main, Sub
gcinclude.AminonOwned = T{}
function gcinclude.CheckAminonLock()
    if (gcdisplay.GetToggle('Aminon') ~= true) then
        if (#gcinclude.AminonOwned > 0) then gcinclude.UnlockSlots(gcinclude.AminonOwned, 'aminon') end
        gcinclude.AminonOwned = T{}
        return
    end
    -- No SIR against Aminon: /aminon (or /def) turns /sir off, /sir is refused until Aminon is off, and stays off
    -- after.
    if (gcdisplay.GetToggle('SIR') == true) then
        gcdisplay.SetToggle('SIR', false)
        gcinclude.Say('/sir off: Aminon is on')
    end
    local set = gcinclude.FindFilled('Aminon') or gcinclude.FindSet('mdt') or {}
    local layer = gcinclude.BuildWeaponLayer() or {}
    local wear, take = {}, T{}
    for _, name in ipairs(gcinclude.AminonSlots) do
        local slot = slotOf(name)
        local key = nil
        for k, _ in pairs(set) do
            if (slotOf(k) == slot) then key = k end -- set keys in any case
        end
        local mode = layer[name] -- the weapon mode's / slot pick's item for this slot
        if (gcinclude.LockedSlots[slot] == nil) and ((mode ~= nil) or (key ~= nil)
            or gcinclude.AminonAlways:contains(slot)) then
            if (mode ~= nil) then wear[name] = mode elseif (key ~= nil) then wear[key] = set[key] end
            take:append(slot)
            if not gcinclude.AminonOwned:contains(slot) then gcinclude.AminonOwned:append(slot) end
        end
    end
    if (#take == 0) then return end
    -- The TP hold disables Main/Sub/Range at 1000+ TP, and force equips skip disabled slots: let go of it for
    -- the slots taken here, or the weapons you wear (not the Aminon set's) would be the ones locked.
    for _, slot in ipairs(take) do
        if (gcinclude.HeldSlots[slot] ~= nil) then gcinclude.HeldSlots[slot] = nil; gState.Disabled[slot] = false end
    end
    if (next(wear) ~= nil) then gFunc.ForceEquipSet(wear) end -- /aminon asked for these
    gcinclude.LockSlots(take, 'aminon')
end

-- Buffs (idle and engaged, HandleDefault), Buffs_Tp (engaged only) and Buffs_Idle (not engaged) over it, Buffs_Ws
-- (weaponskills), Buffs_Precast and Buffs_Midcast (spells): { [buff name] = set }, each worn while that buff is up,
-- e.g. Buffs_Tp = { ['Saber Dance'] = {...} }. Name it as the buff list shows it.
local buffSetOrder = setmetatable({}, { __mode = 'k' }) -- A-Z buff names, once per set table
function gcinclude.CheckBuffSets(setName)
    local buffs = gcinclude.FindSet(setName or 'Buffs')
    if (buffs == nil) then return end
    local order = gcinclude.BuffSetOrder or buffSetOrder[buffs]
    if (type(order) ~= 'table') then
        order = {}
        for name, _ in pairs(buffs) do order[#order + 1] = name end
        table.sort(order)
        buffSetOrder[buffs] = order
    end
    for _, name in ipairs(order) do
        local set = buffs[name]
        if (type(set) == 'table') and (gcinclude.BuffCount(name) > 0) then gFunc.EquipSet(set); end
    end
end

-- What this handler has put in a slot so far (WrapBuffer's copy of LAC's buffer; LAC has no getter).
function gcinclude.BufferedItem(slot)
    if (gcinclude.ShadowItem ~= nil) then return gcinclude.ShadowItem(slot) end
    return nil
end

-- Not engaged (settings.IdleWeapons): weapons your idle sets named in this handler (Idle, Idle_Regen/Refresh,
-- Town, Dt...) beat the weapon mode; slots they leave alone still get the mode's. Main and Sub go as a pair, so
-- do Range and Ammo (Ammo alone: only Ammo). The TP hold still keeps the weapons on at WeaponTPGuard+ TP.
gcinclude.IdleWeaponSlots = nil -- slots left to the idle sets in the last handler (ApplyWeapons)

function gcinclude.IsBlockedAmmo(name)
    if (type(name) ~= 'string') then return false end
    local lname = string.lower(name)
    for _, v in ipairs(gcinclude.BlockedAmmo) do
        if (string.find(lname, v, 1, true) ~= nil) then return true end
    end
    return false
end

function gcinclude.BlockedAmmoName()
    local equip = gData.GetEquipment()
    if (equip == nil) or (equip.Ammo == nil) or (type(equip.Ammo.Name) ~= 'string') then return nil end
    if (gcinclude.IsBlockedAmmo(equip.Ammo.Name) == true) then return equip.Ammo.Name end
    return nil
end

function gcinclude.CheckBlockedAmmo()
    local name = gcinclude.BlockedAmmoName()
    if (name == nil) then return false end
    if (gcinclude.BuffCount('Unlimited Shot') > 0) then return false end
    gcinclude.Err('Shot cancelled: ' .. name .. ' is equipped.')
    gFunc.CancelAction()
    -- SafeAmmo: a name, or a table keyed by the blocked ammo's last word, e.g. { Bullet = '...', Arrow = '...' }
    local safe = gcinclude.SafeAmmo
    if (type(safe) == 'table') then safe = safe[string.match(name, '(%a+)%s*$') or ''] end
    if (type(safe) == 'string') then gcinclude.ForceUnlocked({ Ammo = safe }); end
    return true
end

function gcinclude.CheckBlockedAmmoWS(wsName)
    if (type(wsName) ~= 'string') then return false end
    if not gcinclude.DistanceWS:contains(wsName) then return false end
    return gcinclude.CheckBlockedAmmo()
end

function gcinclude.RollActive()
    for _, name in ipairs(gcinclude.RollBuffs) do
        if (gcinclude.BuffCount(name) > 0) then return true end
    end
    return false
end

function gcinclude.XIRollActive()
    if (gcauto == nil) or (gcauto.RollEleven == nil) then return false end
    return gcauto.RollEleven() and gcinclude.RollActive()
end

-- Idle only: never over melee (engaged) or resting gear.
function gcinclude.CheckXIRoll(player)
    player = player or gData.GetPlayer()
    if (player == nil) or (player.Status ~= 'Idle') then return end
    if not gcinclude.XIRollActive() then return end
    local set = gcinclude.FindFilled('XIRoll') or gcinclude.settings.XIRollSet
    if (set ~= nil) then gFunc.EquipSet(set) end
end

gcinclude.PairSlots = T{ ear1 = 'ear2', ear2 = 'ear1', ring1 = 'ring2', ring2 = 'ring1' }
-- Ear1/Ring1 are the left ear/ring, Ear2/Ring2 the right. Some items' bonus works in one only: their game text says
-- 'Right ear:' (Chev. Earring +1: Right ear: DEF:+22 Shield skill +11 "Cure" potency +11%). The slot that text names.
-- Sortie job earrings (and +1/+2): their augment is right ear (Ear2) only, whatever their text says. Matched by the
-- name's first word, full or as the client abbreviates it ('Kara. Earring +1', 'Pel. Earring +2', 'Beck. Earring').
gcinclude.SortieEarrings = T{'boii', 'bhikku', 'ebers', 'wicce', 'lethargy', 'leth.', "skulker's", 'skulk.',
    "chevalier's", 'chev.', "heathen's", 'heath.', 'nukumi', 'fili', 'amini', 'kasuga', 'hattori', "peltast's", 'pel.',
    "beckoner's", 'beck.', 'hashishin', 'hashi.', "chasseur's", 'chas.', 'karagoz', 'kara.', 'maculele', 'macu.',
    'arbatel', 'azimuth', 'erilaz'}
local sideCache = {}
function gcinclude.ItemSide(name)
    if (type(name) ~= 'string') then return nil end
    local key = string.lower(name)
    if (sideCache[key] == nil) then
        local stem = string.match(key, '^(%S+) earring')
        if (stem ~= nil) and gcinclude.SortieEarrings:contains(stem) then sideCache[key] = 'ear2'; return 'ear2' end
        local r = AshitaCore:GetResourceManager():GetItemByName(name, 0)
        local d = ((r ~= nil) and (type(r.Description) == 'table')) and string.lower(tostring(r.Description[1] or ''))
            or ''
        sideCache[key] = (string.find(d, 'right ear:', 1, true) and 'ear2') or (string.find(d, 'left ear:', 1,
            true) and 'ear1')
            or (string.find(d, 'right ring:', 1, true) and 'ring2') or (string.find(d, 'left ring:', 1,
                true) and 'ring1') or false
    end
    return sideCache[key] or nil
end

function gcinclude.CheckSets(all) -- all: every line, not the first 8 of each kind
    if (gProfile == nil) or (type(gProfile.Sets) ~= 'table') then return end
    local empty = T{}
    local unknown = T{}
    local families = {}
    local pairSlots = {}
    local moon = T{}
    local wrongSide = T{}
    for name, set in pairs(gProfile.Sets) do
        if (type(set) == 'table') then
            if (next(set) == nil) then empty:append(name) end
            local worn, orig = {}, {}
            for slot, item in pairs(set) do
                local iname = (type(item) == 'table') and item.Name or item
                local key = string.lower(tostring(slot))
                if (type(iname) == 'string') and gcinclude.PairSlots[key] then
                    worn[key], orig[key] = string.lower(iname), iname
                end
                if (type(iname) == 'string') and (string.lower(iname) == 'moonshade earring')
                    and not moon:contains(name) then
                    moon:append(name)
                end
            end
            for key, iname in pairs(worn) do
                local side = gcinclude.ItemSide(orig[key])
                if (side ~= nil) and (side ~= key) and (worn[side] ~= iname) then
                    wrongSide:append(name .. '.' .. key .. ': ' .. orig[key] .. ' (its bonus is ' .. ((side == 'ear2'
                        or side == 'ring2') and 'right' or 'left') .. ' only: ' .. side .. ')')
                end
                if (side == nil) and (worn[gcinclude.PairSlots[key]] ~= iname) then
                    pairSlots[iname] = pairSlots[iname] or {}
                    pairSlots[iname][key] = true
                end
            end
            for slot, item in pairs(set) do
                local label = gcinclude.WeaponLabel(item)
                local iname = (type(item) == 'table') and item.Name or item
                if (type(iname) == 'string') and not gcinclude.WeaponKeywords:contains(string.lower(iname)) then
                    if (AshitaCore:GetResourceManager():GetItemByName(iname, 0) == nil) then
                        unknown:append(name .. '.' .. tostring(slot) .. ': ' .. label)
                    end
                end
            end
            for _, suffix in ipairs(T{'Default', 'SubtleBlow', 'Acc'}) do
                local base = string.match(name, '^(.+)_' .. suffix .. '$')
                if (base ~= nil) then
                    families[base] = families[base] or {}
                    families[base][suffix] = true
                end
            end
        end
    end
    local drift = T{}
    for iname, seen in pairs(pairSlots) do
        if (seen.ear1 and seen.ear2) or (seen.ring1 and seen.ring2) then drift:append(iname) end
    end
    table.sort(drift)
    local gaps = T{}
    for base, seen in pairs(families) do
        if (seen['Default'] == nil) and (gcinclude.FindSet(base) == nil) then
            gaps:append(base .. '_Default is missing (SubtleBlow/Acc exist)')
        end
    end
    gcinclude.Say('checksets: ' .. tostring(#empty) .. ' empty, ' .. tostring(#unknown) .. ' unknown items, '
        .. tostring(#gaps) .. ' gaps, ' .. tostring(#drift) .. ' slot drifts, ' .. tostring(#wrongSide)
        .. ' wrong ear/ring')
    table.sort(wrongSide)
    for _, v in ipairs(wrongSide) do gcinclude.Err('wrong side ' .. v) end
    for _, v in ipairs(gaps) do gcinclude.Err(v) end
    for _, v in ipairs(unknown) do gcinclude.Err('unknown item ' .. v) end
    if (#moon > 0) and ((gcinclude.settings.MoonshadeTP or 0) > 0) then
        table.sort(moon)
        gcinclude.Say('Moonshade Earring in: ' .. table.concat(moon,
            ', ') .. ' - not needed, the engine adds it below MoonshadeTP on every WS (see docs/sets.md, Moonshade)')
    end
    if (#drift > 0) then
        gcinclude.Say('in both ear/ring slots across sets (swaps it out and back): ' .. table.concat(drift, ', '))
    end
    if (#empty > 0) then gcinclude.Say('empty: ' .. table.concat(empty, ', ')); end
    -- the same sets against your bags: not owned, one copy worn twice, other augments, wrong bag (common/gcbuild.lua)
    local ok, build = pcall(gFunc.LoadFile, 'common\\gcbuild.lua')
    if ok and (type(build) == 'table') and (build.CheckSets ~= nil) then
        local okc, e = pcall(build.CheckSets, gProfile.Sets, gcinclude.WeaponModes, gcinclude.Say, gcinclude.Err,
            all and 1000 or nil)
        if not okc then gcinclude.Err('checksets: the bag check failed: ' .. tostring(e)) end
    end
end

-- A set without Main/Sub/Range/Ammo: swapping those costs TP or a Hoxne Enchantment.
function gcinclude.NoWeapons(set)
    local out = {}
    for k, v in pairs(set or {}) do
        if not gcinclude.WeaponSlots:contains(slotOf(k)) then out[k] = v end
    end
    return out
end

-- Slept, petrified, stunned or terrorized: your /def set (mdt or Aminon; else Dt)
-- minus Main/Sub/Range/Ammo, then the job's Incapacitated set, then received gear.
-- Not charmed: the client can't change gear then and GearSwap never sends any (Windower GearSwap flow.lua).
gcinclude.IncapacitatedBuffs = T{'Sleep', 'Petrification', 'Stun', 'Terror'}
local noWeaponsOf = setmetatable({}, { __mode = 'k' }) -- built once per set table
function gcinclude.CheckIncapacitated()
    local hit = false
    for _, b in ipairs(gcinclude.IncapacitatedBuffs) do
        if (gcinclude.BuffCount(b) > 0) then hit = true; break end
    end
    if not hit then return end
    local def
    if (gcdisplay.GetToggle('Aminon') == true) then def = gcinclude.FindFilled('Aminon') or gcinclude.FindFilled('mdt')
    elseif (gcdisplay.GetToggle('MDTset') == true) then def = gcinclude.FindFilled('mdt') end
    def = def or gcinclude.FindSet('Dt')
    if (def ~= nil) then
        if (noWeaponsOf[def] == nil) then noWeaponsOf[def] = gcinclude.NoWeapons(def) end
        gFunc.EquipSet(noWeaponsOf[def])
    end
    local extra = gcinclude.FindSet('Incapacitated')
    if (extra ~= nil) then gFunc.EquipSet(extra) end
    gcinclude.CheckReceived() -- gear for a Phalanx/Cure/etc. on its way still goes on top, as it does over /dt
end

function gcinclude.CheckCommonDebuffs()
    local sleep = gcinclude.BuffCount('Sleep')
    local doom = (gcinclude.BuffCount('Doom'))+(gcinclude.BuffCount('Bane'))

    gcinclude.CheckIncapacitated()
    if (sleep >= 1) then gFunc.EquipSet(gcinclude.FindFilled('Sleeping') or gcinclude.sets.Sleeping) end
    -- a job's own Doomed set wins
    if (doom >= 1) then gFunc.EquipSet(gcinclude.FindFilled('Doomed') or gcinclude.sets.Doomed) end
end

-- An ability recast timer by recast id, in Ashita's raw units (1/60 s; Ashita's recast addon divides by 60), 0 when
-- ready. Slot 0 is the SP ability's timer, whose id is 0.
function gcinclude.RecastTimer(rid)
    local recast = AshitaCore:GetMemoryManager():GetRecast()
    for x = 0, 31 do
        if ((x == 0) or (rid ~= 0)) and (recast:GetAbilityTimerId(x) == rid) then
            return recast:GetAbilityTimer(x)
        end
    end
    return 0
end

-- The same by ability name (raw units, as job files have used it), 0 for an unknown name.
function gcinclude.CheckAbilityRecast(check)
    local res = AshitaCore:GetResourceManager():GetAbilityByName(check, 0)
    if (res == nil) then return 0 end
    return gcinclude.RecastTimer(res.RecastTimerId)
end

-- Ring1/Ring2 only (slots 14/15), read the way LAC's gData.GetEquipment does, without its 16-slot walk.
gcinclude.RingReleased = nil -- a teleport ring done with (SafeSetIdle): no longer kept on, so normal gear replaces it
local lockingRing = {} -- item id -> its name if a LockingRings ring, else false
function gcinclude.CheckLockingRings()
    local released = false
    for slot = 14, 15 do
        local item = gEquip.GetCurrentEquip(slot).Item
        local name = nil
        if (item ~= nil) then
            name = lockingRing[item.Id]
            if (name == nil) then
                local res = AshitaCore:GetResourceManager():GetItemById(item.Id)
                name = ((res ~= nil) and gcinclude.LockingRings:contains(res.Name[1])) and res.Name[1] or false
                lockingRing[item.Id] = name
            end
        end
        if name then
            if (string.lower(name) == string.lower(gcinclude.RingReleased
                or '')) then released = true else gFunc.Equip(slot, name) end
        end
    end
    if not released then gcinclude.RingReleased = nil end -- it's off: the next manual equip is kept again
end

local townZone, inTown = nil, false -- the Towns check, redone only when the zone changes
function gcinclude.SetTownGear()
    local zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0)
    if (zone ~= townZone) then
        local area = AshitaCore:GetResourceManager():GetString('zones.names', zone)
        townZone, inTown = zone, (area ~= nil) and gcinclude.Towns:contains(area)
    end
    if inTown then local t = gcinclude.FindSet('Town'); if (t ~= nil) then gFunc.EquipSet(t) end end
end

-- The set `name` while pct is under limit (0 or nil: never). Not made anew on every HandleDefault.
local function wear(name, pct, limit)
    if ((limit or 0) <= 0) or (pct == nil) or (pct >= limit) then return end
    local set = gcinclude.FindSet(name)
    if (set ~= nil) then gFunc.EquipSet(set) end
end
function gcinclude.SetRegenRefreshGear(player)
    local cfg = gcinclude.settings
    if (cfg.AutoGear == false) then return end
    -- Regen/Refresh only out of combat and never over a manual /dt or /idleset reraise (they'd take the Reraise gear
    -- off); auto Dt any time.
    if (gcdisplay.GetToggle('DTset') ~= true) and (gcdisplay.GetCycle('IdleSet') ~= 'Reraise')
        and (not gcinclude.InCombat(player)) then
        wear('Idle_Regen', player.HPP, cfg.RegenGearHPP)
        wear('Idle_Refresh', player.MPP, cfg.RefreshGearMPP)
    end
    wear('Dt', player.HPP, cfg.DTGearHPP)
    if ((cfg.PetDTGearHPP or 0) > 0) then -- LAC's GetPet builds a whole table: only when it is used
        local pet = gData.GetPet()
        if (pet ~= nil) then wear('Pet_Dt', pet.HPP, cfg.PetDTGearHPP) end
    end
end

-- THF, on a weapon skill while Sneak Attack and/or Trick Attack is up: <WS>_SATA / _SA / _TA (with /mset acc:
-- <WS>_Acc_SA...), else Ws_<mset>_SATA / _SA / _TA (Ws_Default_SA). Each only when the job file has it.
function gcinclude.EquipSATA(name)
    if (type(name) ~= 'string') then return end
    local sa, ta = gcinclude.BuffCount('Sneak Attack'), gcinclude.BuffCount('Trick Attack')
    local suffix = ((sa > 0) and (ta > 0) and 'SATA') or ((sa > 0) and 'SA') or ((ta > 0) and 'TA') or nil
    if (suffix == nil) then return end
    local mode = gcdisplay.GetCycle('MeleeSet')
    local set = gcinclude.FindSet(name .. ((mode == 'Default') and '' or ('_' .. mode)) .. '_' .. suffix)
    if (set == nil) or (next(set) == nil) then set = gcinclude.FindSet('Ws_' .. mode .. '_' .. suffix) end
    if (set ~= nil) then gFunc.EquipSet(set) end
end

function gcinclude.CheckWsBailout()
    local player = gData.GetPlayer()
    local ws = gData.GetAction()
    if (player == nil) or (ws == nil) or (ws.Name == nil) then return false end
    if (player.TP < 1000) then return false end
    if (gcinclude.BuffCount('Amnesia') > 0) then return false end
    for _, name in ipairs(gcinclude.HardCC) do
        if (gcinclude.BuffCount(name) > 0) then return false end
    end
    if not gcinclude.settings.WScheck then return true end
    if gcinclude.SelfWS:contains(ws.Name) then return true end -- on yourself
    local target = gData.GetActionTarget()
    local distance = (target ~= nil) and tonumber(target.Distance) or nil
    if (distance == nil) then return true end
    local reach, swung, range, me, mob, floor = gcinclude.WsReach(target, ws.Name)
    if (distance <= reach) then return true end
    gcinclude.Say(string.format('%s: too far (%.1f yalms, %s). Move closer, or /wsdistance off', ws.Name, distance,
        gcinclude.ReachWords(reach, swung, range, me, mob, floor)))
    return false
end

-- How far a weapon skill reaches, center to center: its range past both bodies, as the LandSandBoat server checks
-- it (char_entity.cpp OnWeaponSkillFinished: distance <= getRange() + attacker modelHitboxSize + target
-- modelHitboxSize; data/weapon_skills.yaml: range 3; Gust Slash, Cyclone, Mistral Axe and Bora Axe 14; bows and guns
-- 20, Blast Arrow, Blast Shot and Numbing Shot 5). Melee swings reach 2 past both bodies (GetMeleeRange), so a weapon
-- skill reaches 1' further than a swing (ffxiclopedia Distance). WSdistance (/wsdistance N) stays the least reach, and
-- so does the farthest your auto-attacks on a mob of this name and hitbox went out at (gcauto.SwingReach): a big mob
-- is hit from further away than a small one. A range-20 bow or gun weapon skill reaches at least RangedWsLeast
-- (retail test, SE forum 2012: Sidewinder and the Archery weapon skills at 21 yalms, not 21.1).
-- Returns the reach, then its parts: swing distance (0: none yet), WS range, your hitbox, its hitbox, least reach.
gcinclude.WsRange = 3
gcinclude.WsRanges = { ['Gust Slash'] = 14, ['Cyclone'] = 14, ['Mistral Axe'] = 14, ['Bora Axe'] = 14,
    ['Blast Arrow'] = 5, ['Blast Shot'] = 5, ['Numbing Shot'] = 5 }
for _, n in ipairs(gcinclude.DistanceWS) do gcinclude.WsRanges[n] = gcinclude.WsRanges[n] or 20 end -- bows, guns
gcinclude.RangedWsLeast = 21
function gcinclude.WsReach(target, wsName)
    local range = gcinclude.WsRanges[wsName or ''] or gcinclude.WsRange
    local floor = tonumber(gcinclude.settings.WSdistance) or 0
    if (range == 20) then floor = math.max(floor, gcinclude.RangedWsLeast) end
    local swung, me, mob = 0, 0, 0
    local index = (target ~= nil) and target.Index or nil
    if (index ~= nil) then
        pcall(function()
            local mm = AshitaCore:GetMemoryManager()
            local ent = mm:GetEntity()
            swung = tonumber(gcauto.SwingReach(index)) or 0
            me = tonumber(ent:GetModelHitboxSize(mm:GetParty():GetMemberTargetIndex(0))) or 0
            mob = tonumber(ent:GetModelHitboxSize(index)) or 0
        end)
    end
    return math.max(floor, swung, range + me + mob), swung, range, me, mob, floor
end

-- WsReach's parts in words, for chat: 'reach 5.2: WS 3 + you 0.4 + mob 1.8, swing 4.1, min 5'.
function gcinclude.ReachWords(reach, swung, range, me, mob, floor)
    return string.format('reach %.1f: WS %g + you %.1f + mob %.1f, swing %s, min %g', reach, range, me, mob,
        (swung > 0) and string.format('%.1f', swung) or 'none', floor)
end

-- /wsdistance with no word: the check's state, and for your target its distance and reach (nothing changes).
function gcinclude.WsDistanceStatus()
    local cfg = gcinclude.settings
    local line = 'WS distance check ' .. (cfg.WScheck and 'on' or 'off')
    local target = gData.GetTarget()
    local distance = (target ~= nil) and tonumber(target.Distance) or nil
    if (distance ~= nil) then -- ReachWords names the min
        line = line .. string.format('; %s %.1f yalms, %s', tostring(target.Name or 'target'), distance,
            gcinclude.ReachWords(gcinclude.WsReach(target, nil)))
    else
        line = line .. string.format(', min %g yalms', tonumber(cfg.WSdistance) or 0)
    end
    gcinclude.Say(line .. '. /wsdistance on|off|N')
end

-- After a teleport ring's use (warped or not): stop keeping that ring on, so the next HandleDefault puts
-- your normal ring back. No forced set: '/lac set Idle' locked Idle over every handler for 3 s, casts included.
function gcinclude.SafeSetIdle(tries, ring)
    local mm = AshitaCore:GetMemoryManager()
    if (mm:GetPlayer():GetIsZoning() ~= 0) or (mm:GetInventory():GetEquippedItem(0) == nil) then
        if (tries < 30) then
            local function retry()
                gcinclude.SafeSetIdle(tries + 1, ring)
            end
            retry:once(1)
        end
        return
    end
    gcinclude.RingReleased = ring
end

gcinclude.TeleRings = T{ warpring = 'warp_Ring', mea = 'mea_Ring', holla = 'holla_Ring', dem = 'dem_Ring' }

-- Same path as /gce: equipped directly (no '/lac equip' chat round trip), Ring2 held through the equip delay,
-- used when the extdata
-- says so, retried if no use is seen, let go after the use. Past your /lock on Ring2, as before.
function gcinclude.UseTeleRing(key)
    local ring = gcinclude.settings[key]
    if (type(ring) ~= 'string') then return end
    -- used again: keep it on
    if (gcinclude.RingReleased ~= nil)
        and (string.lower(gcinclude.RingReleased) == string.lower(ring)) then gcinclude.RingReleased = nil end
    gcinclude.UseEnchanted(ring, 'Ring2', 'user')
end


function gcinclude.DoCORmsg(roll)
    if gcinclude.CORmsg == false then return end

    for n = 1, #gcinclude.Rolls do
        if gcinclude.Rolls[n][1] == roll then
            print(chat.header('GoomSwap'):append('[' .. chat.warning(roll) .. ']' .. '  [Lucky: '
                .. chat.success(gcinclude.Rolls[n][2]) .. ']  [Unlucky: ' .. chat.error(gcinclude.Rolls[n][3]) .. ']'))
            return
        end
    end
end

function gcinclude.DoSiphon()
    local recast = gcinclude.CheckAbilityRecast('Elemental Siphon')
    if recast ~= 0 then
        print(chat.header('GoomSwap'):append(chat.warning('Elemental Siphon not available yet!')))
        return
    end
    local pet = gData.GetPet()
    local oldpet = 'none'
    local spirit = 'none'
    local spirits = {['Firesday'] = 'Fire Spirit', ['Earthsday'] = 'Earth Spirit', ['Watersday'] = 'Water Spirit',
        ['Windsday'] = 'Air Spirit', ['Iceday'] = 'Ice Spirit', ['Lightningday'] = 'Thunder Spirit',
        ['Lightsday'] = 'Light Spirit', ['Darksday'] = 'Dark Spirit'}
    local e = gData.GetEnvironment()

    local function release()
        gcinclude.Queue('/ja "Release" <me>')
    end
    local function siphon()
        gcinclude.Queue('/ja "Elemental Siphon" <me>')
    end
    local function castavatar()
        gcinclude.Queue('/ma "' .. oldpet .. '" <me>')
    end
    local function castspirit()
        gcinclude.Queue('/ma "' .. spirit .. '" <me>')
        siphon:once(4)
        release:once(6)
        if oldpet ~= 'none' then castavatar:once(8); end
    end

    if pet ~= nil then
        oldpet = pet.Name
        release:once(1)
    end

    if (spirits[e.Day] ~= nil) then
        spirit = spirits[e.Day]
        castspirit:once(3)
    end
end

-- Runs the job's WS handler and records every Ear1/Ear2 value it asks for, in order, so the engine
-- knows what each ear would hold without Moonshade.
function gcinclude.TrackEars(fn, ...)
    local trail = { ear1 = {}, ear2 = {} }
    local function note(slot, item)
        local key = string.lower(tostring(slot))
        if (trail[key] ~= nil) then table.insert(trail[key], item) end
    end
    local equipSet, equip = gFunc.EquipSet, gFunc.Equip
    gFunc.EquipSet = function(set, ...)
        local t = (type(set) == 'string') and gcinclude.FindSet(set) or set
        if (type(t) == 'table') then
            for k, v in pairs(t) do note(k, v) end
        end
        return equipSet(set, ...)
    end
    gFunc.Equip = function(slot, item, ...)
        note(slot, item)
        return equip(slot, item, ...)
    end
    local ok, result = pcall(fn, ...)
    gFunc.EquipSet, gFunc.Equip = equipSet, equip
    if not ok then error(result, 0) end
    return result, trail
end

local function isMoonshade(v)
    local n = (type(v) == 'table') and v.Name or v
    return (type(n) == 'string') and (string.lower(n) == 'moonshade earring')
end

-- Moonshade Earring, every WS: below MoonshadeTP in the ear a WS set put it in itself (ear1="Moonshade Earring", as
-- GearSwap files have it), else settings.MoonshadeSlot (Ear1, the left ear), the other ear when the WS set has a
-- one-ear item there (a "Left ear:" item in Ear1). At or above MoonshadeTP, an ear the WS sets left on Moonshade goes
-- back to the last other earring those sets gave it (or stays as worn).
function gcinclude.CheckMoonshade(trail)
    local cfg = gcinclude.settings
    local limit = cfg.MoonshadeTP or 0
    if (limit <= 0) or (type(trail) ~= 'table') then return end
    local player, ws = gData.GetPlayer(), gData.GetAction()
    if (player == nil) or (ws == nil) then return end
    local skip = (type(cfg.MoonshadeSkip) == 'table') and cfg.MoonshadeSkip:contains(ws.Name)
    local want = (player.TP < limit) and (not skip)
    local slot = string.lower(cfg.MoonshadeSlot or 'Ear1')
    local own = nil -- an ear the WS sets put Moonshade in themselves: it stays there
    for _, ear in ipairs({ 'ear1', 'ear2' }) do
        local list = trail[ear]
        if (own == nil) and (list ~= nil) and (#list > 0) and isMoonshade(list[#list]) then own = ear end
    end
    if (own ~= nil) then
        slot = own
    -- the WS set has a one-ear item there (a "Left ear:" item in Ear1, a Sortie earring in Ear2): the other ear
    elseif want and (trail[slot] ~= nil) and (#trail[slot] > 0) then
        local last = trail[slot][#trail[slot]]
        if (gcinclude.ItemSide((type(last) == 'table') and last.Name or last) == slot) then
            slot = (slot == 'ear1') and 'ear2' or 'ear1'
        end
    end
    for _, ear in ipairs(T{'ear1', 'ear2'}) do
        local list = trail[ear]
        if want and (ear == slot) then
            gFunc.Equip(ear == 'ear1' and 'Ear1' or 'Ear2', 'Moonshade Earring')
        elseif (#list > 0) and isMoonshade(list[#list]) then
            local back = 'ignore'
            for i = #list, 1, -1 do
                if not isMoonshade(list[i]) then back = list[i]; break end
            end
            gFunc.Equip(ear == 'ear1' and 'Ear1' or 'Ear2', back)
        end
    end
end

-- Absorb spells: Absorb set for all of them, then the spell's own set on top: Absorb_TP (or legacy AbsorbTP) for
-- Absorb-TP, else a set named after the spell (DRK's ['Absorb-TP'], an ['Absorb-STR']), so the generic one never wins.
function gcinclude.CheckAbsorb()
    local spell = gData.GetAction()
    if (spell == nil) or (type(spell.Name) ~= 'string') or (string.sub(spell.Name, 1, 7) ~= 'Absorb-') then return end
    local set = gcinclude.FindSet('Absorb')
    if (set ~= nil) then gFunc.EquipSet(set) end
    set = (spell.Name == 'Absorb-TP') and (gcinclude.FindFilled('Absorb_TP') or gcinclude.FindFilled('AbsorbTP')) or nil
    if (set ~= nil) then
        gFunc.EquipSet(set)
    else
        gcinclude.ByName(spell.Name) -- with its /mset version, as the job file wore it
    end
    if (gcinclude.THWorn == true) then gcinclude.CheckTH() end -- TH that this cast already wore stays over it
end

-- Spectral Jig, Sneak on yourself or Stoneskin with that buff already up: the action is cancelled, the buff is
-- /cancel'ed (Ashita's debuff addon provides /cancel), and the action is sent again once the buff is gone.
-- If the buff is still up 2s after that, /cancel did nothing: say so and stop, instead of cancelling and
-- re-sending the action until the buff wears off.
local CANCEL_FIRST = {
    ['Spectral Jig'] = { buff = 'Sneak', command = '/ja "Spectral Jig" <me>', delay = 2 },
    ['Sneak'] = { buff = 'Sneak', command = '/ma "Sneak" <me>', delay = 1, selfOnly = true },
    ['Stoneskin'] = { buff = 'Stoneskin', command = '/ma "Stoneskin" <me>', delay = 1 },
}
local cancelPending = {} -- action name -> true while its re-send waits for the buff to go
local function resendWhenGone(name, rule, delay, tries)
    (function()
        if (gcinclude.BuffCount(rule.buff) == 0) then
            cancelPending[name] = nil
            gcinclude.Queue(rule.command)
        elseif (tries >= 4) then
            cancelPending[name] = nil
            gcinclude.Err('/cancel ' .. rule.buff .. ' did nothing: load Ashita\'s debuff addon (/addon load debuff)')
        else
            resendWhenGone(name, rule, 0.5, tries + 1)
        end
    end):once(delay)
end

function gcinclude.CheckCancels()
    local action = gData.GetAction()
    local rule = (action ~= nil) and CANCEL_FIRST[action.Name] or nil
    if (rule == nil) or (gcinclude.BuffCount(rule.buff) == 0) then return end
    if rule.selfOnly then
        local target = gData.GetActionTarget()
        local me = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0)
        if (target == nil) or (target.Name ~= me) then return end
    end
    gFunc.CancelAction()
    if cancelPending[action.Name] then return end -- pressed again while waiting: one re-send is enough
    cancelPending[action.Name] = true
    gcinclude.Queue('/cancel ' .. rule.buff)
    resendWhenGone(action.Name, rule, rule.delay, 0)
end

local checkDefault
function gcinclude.CheckDefault() gcinclude.WithBuffs(checkDefault) end
checkDefault = function()
    -- Refresh the modes when the memory manager reports a different main job.
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if (player ~= nil) and (gcinclude.ActiveJobId ~= nil) then
        local mainJobId = player:GetMainJob()
        if (mainJobId ~= 0) and (mainJobId ~= gcinclude.ActiveJobId) then gcinclude.SetVariables() end
    end

    -- Auto Regen/Refresh/DT/Pet_Dt and Town sets count as "your sets", so they go under the engine layers
    -- (docs/sets.md layer order: your sets -> Hoxne sets -> weapons (+ TH weapons while /th is on) -> mdt/Aminon ->
    -- Hoxne -> TH -> received -> buffs -> XIRoll).
    -- Hoxne sets go first: over the job layers (Tp, Impetus...), under auto Dt and every engine layer.
    -- Awake again with a slot still let go for the Sleeping set: hold it now, not at the next 0.1s HoldTick,
    -- so this handler's job-set weapon can't cost the TP (LAC checks gState.Disabled when the buffer goes out).
    if (next(gcinclude.SleepFreed) ~= nil) and (gcinclude.BuffCount('Sleep') == 0) then gcinclude.UpdateHold() end
    local me = gData.GetPlayer() -- one read for the auto sets, the combat check and XIRoll
    if (me ~= nil) and (me.Status == 'Engaged') and (gcdisplay.GetToggle('PROC') == true) then
        -- /proc (proc windows: hit a mob without killing it): the job's engaged gear is dropped from the buffer and
        -- only
        -- Proc goes on, then the weapon mode (the WS you proc with needs it). No Dt, mdt/Aminon, Hoxne, auto, TH,
        -- received, buff or XIRoll sets; sleep/doom safety and the locks (/lock, Aminon, Hoxne Ampulla) still apply.
        gcinclude.RulesRanDefault = true -- /proc: no rules either
        if (gEquip ~= nil) and (gEquip.ClearBuffer ~= nil) then gEquip.ClearBuffer() end
        local proc = gcinclude.FindSet('Proc')
        if (proc ~= nil) then gFunc.EquipSet(proc) end
        gcinclude.WearWeaponLayer(me)
        gcinclude.CheckAminonLock()
        gcinclude.CheckCommonDebuffs()
        gcinclude.CheckLockingRings()
        gcdisplay.Update()
        return
    end
    -- job rules (gcinclude.Rules): where the job file's own code goes, just before this call; not during a pet action
    gcinclude.RulesRanDefault = true
    local rules = gcinclude.HasRules('Default') and (gData.GetPetAction() == nil)
    if rules then gcinclude.RunRules('Default', 'job') end
    gcinclude.CheckHoxneSets(me)
    gcinclude.SetRegenRefreshGear(me)
    gcinclude.SetTownGear()
    gcinclude.CheckWeapons(me)
    if rules then gcinclude.RunRules('Default', 'top') end -- top rules: over all of that, under the debuff sets
    gcinclude.CheckCommonDebuffs()
    gcinclude.CheckLockingRings()
    gcdisplay.Update()
end

function gcinclude.Unload()
    gcinclude.Stopped = true -- a pending InitStep retry of this load does nothing now
    gcinclude.ClearKeybinds()
    gcauto.Stop()
    ashita.events.unregister('d3d_present', 'gcinclude_tick')
    if (gchud ~= nil) then gchud.Stop() end
    if (gcgear ~= nil) then gcgear.Stop() end
    gcinclude.UnlockSlots(nil)
    gcinclude.UnlockWeapons()
    if (gFunc.GcRawEquipSet ~= nil) then
        gFunc.EquipSet, gFunc.Equip = gFunc.GcRawEquipSet, gFunc.GcRawEquip
        gFunc.GcRawEquipSet, gFunc.GcRawEquip = nil, nil
    end
    if (gPacketHandlers ~= nil) and (gPacketHandlers.GcRawItem ~= nil) then
        gPacketHandlers.HandleItemPacket, gPacketHandlers.GcRawItem = gPacketHandlers.GcRawItem, nil
    end
    if (gPacketHandlers ~= nil) and (gPacketHandlers.GcRawAction ~= nil) then
        gPacketHandlers.HandleActionPacket, gPacketHandlers.GcRawAction = gPacketHandlers.GcRawAction, nil
    end
    if (gEquip ~= nil) and (gEquip.GcRawToBuffer ~= nil) then
        gEquip.EquipItemToBuffer, gEquip.ClearBuffer, gEquip.ProcessBuffer = gEquip.GcRawToBuffer, gEquip.GcRawClear,
            gEquip.GcRawProcess
        gEquip.GcRawToBuffer, gEquip.GcRawClear, gEquip.GcRawProcess = nil, nil, nil
        if (gEquip.GcRawImmediate ~= nil) then
            gEquip.ProcessImmediateBuffer, gEquip.GcRawImmediate = gEquip.GcRawImmediate, nil
        end
    end
    gcdisplay.Unload()
    if (gcinclude.Editor ~= nil) then gcinclude.Editor.Close() end
    gcinclude.ClearAlias()
end

-- The set editor module, loaded on first use; false (said why) when it won't load.
local function loadEditor()
    if (gcinclude.Editor == nil) then
        local ok, mod = pcall(gFunc.LoadFile, 'common\\gcedit.lua')
        if not ok or (type(mod) ~= 'table') then
            gcinclude.Err('/gcedit: common\\gcedit.lua failed to load: ' .. tostring(mod)) return false
        end
        gcinclude.Editor = mod
    end
    return true
end

-- /gcedit [set]: open the set editor on that set, or close it. Saving reloads the job file; GcEditReopen (a
-- global, so it outlives the reload) brings the editor back on the same set (InitStep).
-- The bar's '+ new mode...' / '+ add...': /gcedit opened (if it isn't) on what was asked. kind: 'wm'
-- (New weapon mode), 'mset' (a /mset mode and its sets) or a pick list's setting ('MainModes': Settings, found).
function gcinclude.EditorRequest(kind)
    if not loadEditor() then return end
    if not gcinclude.Editor.IsOpen() then gcinclude.Editor.Open(gcinclude, nil, nil) end
    if gcinclude.Editor.IsOpen() and (gcinclude.Editor.Request ~= nil) then gcinclude.Editor.Request(kind) end
end

function gcinclude.EditorCommand(setName, slot)
    if not loadEditor() then return end
    if gcinclude.Editor.IsOpen() then
        -- open: /gcedit asks before dropping unsaved changes; /gcedit <set> goes to that set, keeping them
        if (setName == nil) then gcinclude.Editor.RequestClose() else gcinclude.Editor.Show(setName, slot) end
        return
    end
    gcinclude.Editor.Open(gcinclude, setName, slot)
end

-- /gcedit last [slot]: the editor on the set your last action used, its Result tab on that use: the set named after
-- the action (Leaden Salute), else the last set it wore. With a slot (ear2): the set that last put that slot on, as
-- /gcgear's right-click. From gcaction's records (GcRecords, GcWornBy); idle/engaged only when nothing else was.
gcinclude.EditorLastSlots = { main = 1, sub = 2, range = 3, ammo = 4, head = 5, body = 6, hands = 7, legs = 8,
    feet = 9, neck = 10, waist = 11, ear1 = 12, ear2 = 13, ring1 = 14, ring2 = 15, back = 16 } -- LAC's slot numbers
local LAST_NAME = { 'Main', 'Sub', 'Range', 'Ammo', 'Head', 'Body', 'Hands', 'Legs', 'Feet', 'Neck', 'Waist', 'Ear1',
    'Ear2', 'Ring1', 'Ring2', 'Back' }
local function last_set(by) -- a layer the editor can open: a set's own name, not a function or a table path
    if (type(by) ~= 'string') or (by == '') or (by == '?') then return nil end
    if string.find(by, '[%(%[]') or (string.sub(by, 1, 10) == 'gcinclude.') then return nil end
    return by
end
local function editor_pick(set, key)
    if (gcinclude.Editor ~= nil) and gcinclude.Editor.IsOpen() and (gcinclude.Editor.PickRecord ~= nil) then
        gcinclude.Editor.PickRecord(set, key)
    end
end
function gcinclude.EditorLast(slotWord)
    if slotWord ~= nil then
        local n = gcinclude.EditorLastSlots[string.lower(slotWord)]
        if n == nil then
            gcinclude.Err('/gcedit last <slot>: a slot (head, ear2, ring1...), not ' .. tostring(slotWord))
            return
        end
        local w = (type(GcWornBy) == 'table') and GcWornBy[n] or nil
        local set = (w ~= nil) and last_set(w.by) or nil
        if set == nil then
            gcinclude.Say(LAST_NAME[n] .. ': no set of your file put it on yet')
            return
        end
        gcinclude.EditorCommand(set, LAST_NAME[n])
        editor_pick(set, w.key)
        return
    end
    local job = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob()
    local best, idle = nil, nil
    local function later(r, than)
        return (than == nil) or ((r.seq or 0) > (than.seq or 0))
            or (((r.seq or 0) == (than.seq or 0)) and ((r.time or 0) > (than.time or 0)))
    end
    for _, r in pairs((type(GcRecords) == 'table') and GcRecords.byKey or {}) do
        if r.job == job then
            if (r.event == 'Default') then
                if later(r, idle) then idle = r end
            elseif later(r, best) then
                best = r
            end
        end
    end
    local r = best or idle
    if r == nil then
        gcinclude.Say('/gcedit last: nothing recorded since LuAshitacast loaded')
        return
    end
    local set = nil -- the set named after the action, else the last set it wore
    for _, w in ipairs(r.writes or {}) do
        local by = last_set(w.by)
        if (by ~= nil) and (r.action ~= nil) and (string.lower(by) == string.lower(r.action)) then set = by end
    end
    for i = #(r.writes or {}), 1, -1 do
        if set ~= nil then break end
        set = last_set(r.writes[i].by)
    end
    if set == nil then
        gcinclude.Say('/gcedit last: ' .. tostring(r.key) .. ' wore no set of your file')
        return
    end
    gcinclude.EditorCommand(set)
    editor_pick(set, r.key)
end

-- The loaded job file, when it is examples/<JOB>.lua byte for byte: that job, else nil. Read once per load.
local exampleOf = { path = nil, job = nil }
function gcinclude.UnchangedExample()
    if (gProfile == nil) or (type(gProfile.FilePath) ~= 'string') then return nil end
    if (exampleOf.path == gProfile.FilePath) then return exampleOf.job end
    exampleOf.path, exampleOf.job = gProfile.FilePath, nil
    local job = gcinclude.JobName(AshitaCore:GetMemoryManager():GetPlayer():GetMainJob())
    if (job == nil) then return nil end
    local function read(p)
        local f = io.open(p, 'rb')
        if (f == nil) then return nil end
        local t = f:read('*a')
        f:close()
        return t
    end
    local mine = read(gProfile.FilePath)
    local ex = read(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\examples\\' .. job .. '.lua')
    if (mine ~= nil) and (ex ~= nil) and (mine == ex) then exampleOf.job = job end
    return exampleOf.job
end

-- After /gcbuild: the draft opens in the set editor; its Save writes it as this job's file (the old one
-- backed up) and reloads. Another job's draft is only written: LAC loads that job's file on the job change.
function gcinclude.EditorDraft(job, proposed, dir, cmd)
    cmd = cmd or '/gcbuild'
    local now = gcinclude.JobName(AshitaCore:GetMemoryManager():GetPlayer():GetMainJob())
    local file = job .. '.proposed.lua'
    -- /gcimport for another job: opened now as that job's file (Save file writes <JOB>.lua; nothing is loaded).
    -- On that job GoomSwap may not load at all (its <JOB>.lua still the GearSwap file, or none), so no /gcimport
    -- there. /gcbuild stays on its job: it reads the gear you carry for it.
    local otherId = nil
    if (now ~= job) and (cmd == '/gcimport') then
        for id = 1, 22 do
            if gcinclude.JobName(id) == job then otherId = id end
        end
    end
    if (now ~= job) and (otherId == nil) then
        gcinclude.Say('Next: change to ' .. job .. ' and run ' .. cmd .. ' there: ' .. file
            .. ' opens in the set editor, and its Save makes it your ' .. job .. '.lua.')
        return
    end
    if not loadEditor() then return end
    if gcinclude.Editor.IsOpen() then
        if gcinclude.Editor.Dirty() then
            gcinclude.Err(cmd .. ': the set editor has unsaved changes: save or close it, then ' .. cmd .. ' again.')
            return
        end
        gcinclude.Editor.Close()
    end
    -- Where Save writes: the file LAC has loaded when it is this job's (<JOB>.lua, <Name>_<JOB>.lua), so /lac reload
    -- takes it; else <Name>_<id>\<JOB>.lua, the first place LAC's /lac load looks (LuAshitacast state.lua
    -- AutoLoadProfile).
    local cur = (gProfile ~= nil) and gProfile.FilePath or nil
    local base = (type(cur) == 'string') and string.lower(string.match(cur, '[^\\/]+$') or '') or ''
    local lj = string.lower(job)
    local target, reload = dir .. job .. '.lua', '/lac load'
    if (base == (lj .. '.lua')) or (string.sub(base, -(#lj + 5)) == ('_' .. lj .. '.lua')) then
        target, reload = cur, '/lac reload'
    end
    if otherId ~= nil then
        gcinclude.Say(file .. ' opened as your ' .. job .. '.lua (you are on ' .. tostring(now) .. '): Save file writes '
            .. 'it, the old one kept as a backup; then change to ' .. job .. '.')
        gcinclude.Editor.Open(gcinclude, nil, nil, { src = proposed, target = target, inactive = true, job = otherId })
        return
    end
    gcinclude.Editor.Open(gcinclude, nil, nil, { src = proposed, target = target, reload = reload })
end

function gcinclude.PlayerReady()
    local mm = AshitaCore:GetMemoryManager()
    if (mm == nil) then return false; end

    local p = mm:GetPlayer()
    local party = mm:GetParty()
    if (p == nil) or (party == nil) then return false; end

    local mainJobId = p:GetMainJob()
    if (mainJobId == nil) or (mainJobId == 0) then return false; end
    if (p:GetMainJobLevel() == nil) or (p:GetMainJobLevel() == 0) then return false; end
    if (party:GetMemberIsActive(0) ~= 1) then return false; end

    local name = party:GetMemberName(0)
    if (name == nil) or (name == '') then return false; end

    -- Fetch expected job abbreviation directly from memory
    local mainJobStr = gcinclude.JobName(mainJobId)

    -- Gate until gData exists AND has synced to match the current memory state
    local gp = gData.GetPlayer()
    if (gp == nil) or (gp.MainJob == nil) or (gp.MainJob == 'NON') or (gp.MainJob ~= mainJobStr) then return false; end

    return true
end

function gcinclude.InitStep(tries)
    tries = tries or 0
    if (gcinclude.Stopped == true) then return end -- unloaded while waiting for the player

    if not gcinclude.PlayerReady() then
        if (tries < 150) then
            local retry = function() gcinclude.InitStep(tries + 1); end
            retry:once(0.2)
        else
            gcinclude.Say('Init gave up waiting on player data after 30s.')
        end
        return
    end

    gcdisplay.Initialize(gcinclude.settings, gcinclude)
    gcinclude.SetVariables()
    gcinclude.SetAlias()
    gcinclude.ApplyKeybinds()
    if (gcauto ~= nil) then
        gcauto.OnIncomingCast, gcauto.OnReceivedEnd = gcinclude.StartReceived, gcinclude.EndReceived
    end
    gcinclude.ApplyLockstyle()
    gcauto.Start()
    ashita.events.register('d3d_present', 'gcinclude_tick', gcinclude.Tick)
    gcinclude.FillPacker() -- what /lac gear gets on top of the sets
    if (gchud ~= nil) then gchud.Start() end
    if (gcgear ~= nil) then gcgear.Start() end
    if (GcEditReopen == nil) and (gcinclude.UnchangedExample() ~= nil) then -- a new user's first load: say what to do
        gcinclude.Say('This is GoomSwap\'s ' .. gcinclude.UnchangedExample()
            .. ' example, as is: its sets name gear you may not own. '
            .. '/gcedit, then "Keep only my gear" (or /gcbuild), to start from what you own.')
    end
    if gProfile and gProfile.FilePath then
        local marker = gProfile.FilePath .. '.gcedit-reopen'
        local f = io.open(marker, 'r')
        if f then
            local timestamp, name, slot = tonumber(f:read('*l')), f:read('*l'), f:read('*l')
            f:close(); os.remove(marker)
            if timestamp and os.time() - timestamp >= 0 and os.time() - timestamp < 120 then
                GcEditReopen = {set = name ~= '' and name or nil, slot = slot ~= '' and slot or nil}
            end
        end
    end
    if (GcEditReopen ~= nil) then -- saved from /gcedit: open it again where it was
        local again = GcEditReopen
        GcEditReopen = nil
        pcall(gcinclude.EditorCommand, again.set, again.slot)
    end
end

-- LAC takes every outgoing action packet as the new pending action, and when it is cancelled leaves none, so
-- its idle gear goes on in that same packet chunk (LuAshitacast packethandlers.lua HandleActionPacket /
-- HandleOutgoingChunk), even while an earlier cast is still running. A cancelled action (on recast, or
-- queued while you cast) gives the earlier one back instead, so its gear stays on. Wrapped once.
-- gcinclude.PrevAction is that earlier action while the new one's handlers run, so the checks see a cast that
-- was sent but hasn't started yet (gcauto only knows it from the start packet). Item uses (0x37) too.
function gcinclude.WrapActionPacket()
    if (gPacketHandlers == nil) or (gPacketHandlers.GcRawAction ~= nil) then return end
    local function wrap(raw)
        return function(...)
            local before = gState.PlayerAction
            gcinclude.PrevAction = before
            local ok, result = pcall(raw, ...)
            gcinclude.PrevAction = nil
            local a = gState.PlayerAction
            if (a ~= nil) and (a ~= before) then -- went out now (not blocked)
                -- The game's resend (Sequencer) of the same action keeps the first send time: a fresh one per
                -- resend kept the not-started window open, so every other press read as "casting".
                local same = (a.Resend == true) and (before ~= nil) and (before.GcSentAt ~= nil)
                    and (before.Type == a.Type)
                    and (before.Resource ~= nil) and (a.Resource ~= nil) and (before.Resource.Index == a.Resource.Index)
                a.GcSentAt = same and before.GcSentAt or os.clock()
            end
            if (gState.PlayerAction == nil) and (before ~= nil) and ((before.Completion or 0) > os.clock()) then
                gState.PlayerAction = before
            end
            if not ok then error(result, 0) end
            return result
        end
    end
    gPacketHandlers.GcRawAction = gPacketHandlers.HandleActionPacket
    gPacketHandlers.HandleActionPacket = wrap(gPacketHandlers.GcRawAction)
    if (gPacketHandlers.HandleItemPacket ~= nil) and (gPacketHandlers.GcRawItem == nil) then
        gPacketHandlers.GcRawItem = gPacketHandlers.HandleItemPacket
        gPacketHandlers.HandleItemPacket = wrap(gPacketHandlers.GcRawItem)
    end
end

-- Seconds left on my own cast, and its spell id: from gcauto's start packet, else the spell sent before the
-- action now being handled, while its start packet could still be on the way (StartWindow s after it went
-- out). A spell the server refused never starts, so after that it no longer counts. 0 when not casting.
gcinclude.StartWindow = 1.5
-- The server refused my pending spell (gcauto, 0x0029): it won't start, so the window ends now.
function gcinclude.OnSpellRefused()
    local a = gState.PlayerAction
    if (a ~= nil) and (a.Type == 'Spell') then a.GcSentAt = nil end
end
-- A weapon skill or ability pressed while a spell of mine is casting (its start packet seen): GoomSwap doesn't
-- cancel it or say anything (they have no cast of their own); it goes to the game as is, and no gear moves, so
-- the spell keeps its midcast set.
function gcinclude.MidCast()
    return (gcauto ~= nil) and (gcauto.CastLeft ~= nil) and ((gcauto.CastLeft()) > 0)
end
function gcinclude.CastLeft()
    local left, id = 0, nil
    if (gcauto ~= nil) and (gcauto.CastLeft ~= nil) then left, id = gcauto.CastLeft() end
    if (left > 0) then return left, id end
    local p = gcinclude.PrevAction
    local now = os.clock()
    -- Not once the server has answered it: a start packet is in gcauto's count above, and a finish or interrupt
    -- means it is over. (A quick spell, Flash, finished before the 1.5s window ran out read as "casting".)
    local answered = (gcauto ~= nil) and ((gcauto.LastCastPacket or -1e9) >= (p and p.GcSentAt or math.huge))
    if (p ~= nil) and (p.Type == 'Spell') and (p.GcSentAt ~= nil) and (now - p.GcSentAt < gcinclude.StartWindow)
        and ((p.Completion or 0) > now) and not answered then
        -- learned, as gcauto does
        local cast = ((gcauto ~= nil) and (gcauto.CastTime ~= nil)) and gcauto.CastTime(p.Resource) or 0
        return math.max(p.GcSentAt + cast - now, 0.1), (p.Resource ~= nil) and p.Resource.Index or nil
    end
    return 0
end

function gcinclude.Initialize()
    gcinclude.CompileRules() -- before the wrappers: a phase with rules gets one even with no handler of its own
    gcinclude.WrapHoldHandlers()
    gcinclude.WrapEquip()
    gcinclude.WrapBuffer()
    gcinclude.WrapActionPacket()
    gcinclude.InitStep(0)
end

-- Install cohesive services after their private host dependencies are defined.
runtime.Commands.Install(gcinclude)
runtime.Weapons.Install(gcinclude, {slotOf = slotOf, thFullTime = thFullTime})
runtime.Elements.Install(gcinclude, {slotOf = slotOf})
enchantRuntime = runtime.Enchants.Install(gcinclude, {slotOf = slotOf, carriedId = carriedId})
equippedId = enchantRuntime.EquippedId

runtime.Config.Install(gcinclude)

return gcinclude
