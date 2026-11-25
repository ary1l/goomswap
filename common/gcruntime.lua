-- Gear-engine services, grouped by responsibility. Install order is owned by gcinclude.
local runtime = {}

-- == Settings ==
do
    -- Default settings and per-job mode initialization. Job overrides keep the same API.
    local settings = {}
    function settings.Install(gcinclude)
        gcinclude.sets = T{
            Doomed = { -- this set will equip any time you have the doom status
                Ring1 = 'Purity Ring',
                Waist = 'Gishdubar Sash',
            },
            Holy_Water = { -- update with whatever gear you use for the Holy Water item
                Ring1 = 'Purity Ring',
                Ring2 = "Blenmot's Ring",
            },
            -- this set will auto equip if you are asleep, over Incapacitated; a job file's own Sleeping set is used
            -- instead (Main allowed there)
            Sleeping = {},
        }
        gcinclude.settings = {
            -- Personal settings belong in char.lua, outside common/. Use /gcconfig
            -- to find the exact path. A job may override settings before Initialize().
            -- set to true if you want chat log messages to appear on any /gc command used such as DT, TH, or KITE gear
            -- toggles, certain messages will always appear
            Messages = false,
            AutoGear = true, -- master switch for the four auto sets below, /autogear to change any of them in game
            WScheck = true, --set to false if you dont want to use the WS distance safety check
            -- the least reach (yalms, center to center) for a non-ranged WS while WScheck is on; a big mob gets more:
            -- WS range 3 + your and its hitbox (gcinclude.WsReach)
            WSdistance = 5,
            RegenGearHPP = 60, -- Idle_Regen below this HPP, out of combat only, 0 = never
            RefreshGearMPP = 60, -- Idle_Refresh below this MPP, out of combat only, 0 = never
            DTGearHPP = 50, -- Dt below this HPP, any status (engaged, idle, in or out of combat), 0 = never
            PetDTGearHPP = 50, -- Pet_Dt below this pet HPP, 0 = never
            -- every WS, every job: Moonshade Earring below this TP, never at or above it; 0 = engine leaves Moonshade
            -- alone
            MoonshadeTP = 1750,
            -- the slot the engine puts it in; the other ear when the WS set has a Sortie (right-ear-only) earring there
            MoonshadeSlot = 'Ear2',
            MoonshadeSkip = T{}, -- WS names the engine never gives Moonshade, e.g. T{'Myrkr'}
            -- the status bar (job, atk/def, modes and toggles as pills), /gcbar to toggle; the HUD drops under it
            DisplayBar = false,
            -- DisplayBarX unset: the bar sits centred at the top, or flush right with the HUD on; dragged, it stays
            -- there (saved per character; /gcbar reset)
            DisplayBarY = 0,
            -- /warpring, /mea, /holla, /dem: held in Ring2, used once its equip delay is up (as /gce), let go after the
            -- use (normal ring back)
            warp_Ring = 'Warp Ring',
            mea_Ring = 'Dim. Ring (Mea)',
            dem_Ring = 'Dim. Ring (Dem)',
            holla_Ring = 'Dim. Ring (Holla)',
            -- at or above this TP (engaged or not), the main/sub/range on are held against automatic swaps (action
            -- sets, idle/engaged sets); weapon commands (/wm, /mw...) still swap; 0 = action sets always get their
            -- weapons (mages, BRD, GEO, COR); per job in the job file
            WeaponTPGuard = 1000,
            -- not engaged: weapons your idle sets name (Idle, Idle_Regen/Refresh, Town, Dt...) beat the weapon mode;
            -- false = the weapon mode always
            IdleWeapons = true,
            -- Aftermath up: main/sub/range held against idle/engaged swaps (a weapon change ends it); spells still get
            -- their weapons; /wm still swaps
            AftermathHold = true,
            -- spell skills and ability types that always get their weapon swaps
            HoldExempt = T{ 'Singing', 'Geomancy', 'Healing Magic', 'Enfeebling Magic', 'Enhancing Magic',
                'Corsair Roll' },
            -- keep main/sub/range on the spells below instead of losing TP to a weapon swap, /smartswap to toggle
            SmartSwap = true,
            SmartSwapTP = 1, -- SmartSwap only acts at or above this TP
            -- spells that keep main/sub/range: a name = that spell; { Spells, Worn } = spells starting with Spells
            -- while any Worn item is in main or sub
            KeepWeaponsFor = T{
                'Dia', 'Dia II', 'Dia III', 'Diaga', 'Blink', 'Ice Spikes', 'Blaze Spikes', 'Shock Spikes',
                { Spells = T{ 'Cure', 'Cura' }, Worn = T{ 'Daybreak', "Bunzi's Rod" } },
            },
            -- set names hidden from /gcedit's Related tab, e.g. T{'Singing'}
            EditorIgnoreSuggestions = T{},
            -- newest dated /gcedit backups kept per job file, after a successful save; 0 = keep all
            EditorBackupKeep = 10,
            -- /gcedit heading order and your own headings ({ 'Weapons', 'Idle', { 'Two-handed', 'Tp_Chango' } }); the
            -- editor's right-click menus write it to char.lua (docs/gcedit.md, Headings)
            EditorGroups = nil,
            EnchantWindow = 12, -- fallback wait when the item resource has no equip delay
            EnchantDelays = T{}, -- per-item override in seconds, e.g. T{ ['Reraise Earring'] = 30 }
            -- spell or ability name (lowercase, matched as a prefix) -> set worn while it is on its way to you
            ReceivedSets = T{
                ['cure'] = 'Cure_Received',
                ['cura'] = 'Cure_Received',
                ['curaga'] = 'Cure_Received',
                ['cursna'] = 'Cursna_Received',
                ['phalanx'] = 'Phalanx_Received',
                ['protect'] = 'Protect_Shell_Received',
                ['shell'] = 'Protect_Shell_Received',
                ['regen'] = 'Regen_Received',
                ['refresh'] = 'Refresh_Received',
                ['curing waltz'] = 'Waltz_Received',
                ['divine waltz'] = 'Waltz_Received',
            },
            ReceivedWindow = 8, -- seconds the received gear stays on before it gives up
            -- your own characters that get the Multisend 'received' notice; boxes running this engine are found by
            -- themselves (HUD state file), so only needed if that fails, e.g. T{'YourMain','YourBox'}
            MyBoxes = T{},
            ElementReport = false, -- chat line naming the obi/Orpheus/ring/back each nuke or WS got
            -- {yalms, affinity %}: BG's two documented ends; linear between them is assumed. Add tested points in
            -- order. ElementReport = true prints what the element picker chose
            OrpheusPoints = T{ { 1.93, 15 }, { 13, 1 } },
            ElementGear = T{ -- waist chosen by the spell's element, day and weather
                Obis = T{ Dark = 'Anrin Obi' }, -- element obis you own; add as you get them
                AnyObi = 'Hachirin-no-Obi', -- every element; worn only when day/weather nets positive
                Distance = "Orpheus's Sash", -- used when it beats the obi's day/weather value
                DistanceMax = nil, -- optional yalm cap for Orpheus; nil = any distance (it is never below +1)
                -- e.g. 'Zodiac Ring', worn when the day matches the element (never Light/Dark, never on cures)
                Ring = nil,
                RingSlot = 'Ring2',
                Back = nil, -- e.g. 'Twilight Cape': +5% to a day bonus, or to a weather bonus that applies (BG-Wiki)
                -- Cure/Cura/Curaga: obi on Light day/weather (BG-Wiki: +10/+10/+25, the obi forces it). Every job; one
                -- job: gcinclude.CureObi = true/false at the top of its file (WHM/SCH/RDM/GEO turn it on)
                Cures = false,
                BackOnCures = false, -- also the back on Cure/Cura/Curaga (your cure-potency back may be worth more)
                Keep = T{ 'Oneiros Rope' }, -- items that are never displaced by the picks above
            },
            MBWindow = 10, -- magic burst window in seconds from the skillchain (BG: 10); another WS on the mob ends it
            -- spells of these skills wear Burst when they land in a live skillchain; add 'Dark Magic' etc. as you like
            MBSkills = T{ 'Elemental Magic' },
            ElementSkills = T{ 'Elemental Magic', 'Blue Magic' }, -- spell skills that get obi/Orpheus/element ring
            -- Elemental WS and their element (BG-Wiki Category:Elemental Weapon Skill). Starburst/Sunburst
            -- (Light or Dark), Spirits Within and Atonement (breath damage) are left out on purpose.
            ElementalWS = {
                ['Gust Slash'] = 'Wind',
                ['Cyclone'] = 'Wind',
                ['Energy Steal'] = 'Dark',
                ['Energy Drain'] = 'Dark',
                ['Aeolian Edge'] = 'Wind',
                ['Burning Blade'] = 'Fire',
                ['Red Lotus Blade'] = 'Fire',
                ['Shining Blade'] = 'Light',
                ['Seraph Blade'] = 'Light',
                ['Sanguine Blade'] = 'Dark',
                ['Frostbite'] = 'Ice',
                ['Freezebite'] = 'Ice',
                ['Herculean Slash'] = 'Ice',
                ['Cloudsplitter'] = 'Thunder',
                ['Primal Rend'] = 'Light',
                ['Dark Harvest'] = 'Dark',
                ['Shadow of Death'] = 'Dark',
                ['Infernal Scythe'] = 'Dark',
                ['Thunder Thrust'] = 'Thunder',
                ['Raiden Thrust'] = 'Thunder',
                ['Blade: Teki'] = 'Water',
                ['Blade: To'] = 'Ice',
                ['Blade: Chi'] = 'Earth',
                ['Blade: Ei'] = 'Dark',
                ['Blade: Yu'] = 'Water',
                ['Tachi: Goten'] = 'Thunder',
                ['Tachi: Kagero'] = 'Fire',
                ['Tachi: Jinpu'] = 'Wind',
                ['Tachi: Koki'] = 'Light',
                ['Shining Strike'] = 'Light',
                ['Seraph Strike'] = 'Light',
                ['Flash Nova'] = 'Light',
                ['Rock Crusher'] = 'Earth',
                ['Earth Crusher'] = 'Earth',
                ['Cataclysm'] = 'Dark',
                ['Vidohunir'] = 'Dark',
                ['Garland of Bliss'] = 'Light',
                ['Omniscience'] = 'Dark',
                ['Flaming Arrow'] = 'Fire',
                ['Hot Shot'] = 'Fire',
                ['Wildfire'] = 'Fire',
                ['Trueflight'] = 'Light',
                ['Leaden Salute'] = 'Dark',
            },
            CombatWindow = 6, -- seconds; Selindrile uses 6
            -- spells /sir never goes over on every job (your own set for them stays); a job's gcinclude.SIRSkip =
            -- T{...} adds to it
            SIRSkip = T{ 'Absorb-TP', 'Stun' },
            -- spells /th never goes over (their own set stays, tagged or not); a job's gcinclude.THSkip = T{...} adds
            -- to it
            THSkip = T{ 'Absorb-TP', 'Stun' },
            HoxneItem = 'Hoxne Ampulla', -- what the Hoxne states keep in your ammo slot
            -- locked by the Locked state (nothing worn in Range can stay on with the Ampulla: SE forum ranged/ammo
            -- groups)
            HoxneLockSlots = T{ 'Ammo', 'Range' },
            -- Selindrile's F-key layout. Bound on load, unbound on unload; T{} for none. A command starting with / is
            -- bound
            -- as is. Use char.lua settings.Keybinds = {} for no binds; per-job overrides still win.
            Keybinds = T{
                { 'F7', 'wm' },
                { '+F7', 'wm default' },
                { 'F9', 'mset' },
                { '^F9', 'tankset' },
                { '!F9', 'wsset' },
                { 'F10', 'def' },
                { '!F10', 'kite' },
                { '@F10', 'hoxne' },
                { '+F11', 'nukeset' },
                { '!F11', 'burst' },
                { '+F12', 'idleset' },
                { '!F12', 'def off' },
                { '^@!F12', '/lac reload' },
            },
            XIRollSet = T{ Ring2 = "Roller's Ring" }, -- used when a job file has no XIRoll set of its own
            -- your main(s), e.g. T{'YourMain'}: the HUD (the other boxes, dropped under /gcbar on hover) on with every
            -- load; others: /gchud
            HUDOwners = T{},
            -- colour preset shared with goomui (/gcbar theme lists them): false follows goomui's, else GoomSwap's own;
            -- 'ocean' picks one; 'goomswap' keeps GoomSwap's own
            Theme = false,
            HUDAbbr = {}, -- extra short names you can type for a value, e.g. { ['Carnwenhan'] = 'Carn' } (/wm carn)
            -- the bar's weapon colour for items it doesn't know: { ['Item Name'] = 'tpbonus' } (relic mythic empyrean
            -- prime aeonic tpbonus)
            WeaponClass = {},
            -- /lockstyleset N 4s after load and job change; per job gcinclude.LockstyleSet = N in OnLoad
            LockstyleSet = nil,
            -- /capacity wears the carried one worth most (Mecisto by its augment)
            CapacityCapes = T{ 'Aptitude Mantle +1', 'Aptitude Mantle', 'Mecisto. Mantle' },
            JubileeSlot = 'Ring1', -- /jubilee ring slot
            -- asleep with Stoneskin up: /cancel Stoneskin so damage can wake you (FFXIclopedia Sleep)
            SleepCancelStoneskin = true,
            HoxneAutoUse = true, -- Hoxne Locked: use the Ampulla when it is in ammo and Enchantment isn't up
        }

        function gcinclude.SetVariables()
            local player = AshitaCore:GetMemoryManager():GetPlayer()
            local mJob = 'NON'
            gcinclude.ActiveJobId = nil
            if player ~= nil then
                local mainJobId = player:GetMainJob()
                gcinclude.ActiveJobId = mainJobId
                mJob = gcinclude.JobName(mainJobId) or 'NON'
            end

            gcinclude.UnlockSlots(nil)
            gcinclude.UnlockWeapons()
            gcinclude.Holds = {}
            gcinclude.Enchants = {}
            gcdisplay.ClearAll()
            gcdisplay.CreateToggle('DTset', false)
            gcdisplay.CreateToggle('MDTset', false)
            gcdisplay.CreateToggle('Aminon', false)
            gcdisplay.CreateToggle('SIR', false)
            gcdisplay.CreateCycle('Hoxne', { [1] = 'Off', [2] = 'Locked' })
            gcdisplay.CreateToggle('Kite', false)
            gcdisplay.CreateToggle('TH', false)
            -- /mset modes: <set>_<mode> over <set>_Default (shown and typed as Base). A job file can set its own list
            -- (gcinclude.MeleeModes = {...} in
            -- OnLoad, before Initialize). DT is not a mode: /dt layers the Dt set over any of them.
            local melee = (type(gcinclude.MeleeModes) == 'table')
                    and (#gcinclude.MeleeModes > 0) and gcinclude.MeleeModes or { 'Default', 'SubtleBlow', 'Acc' }
            gcdisplay.CreateCycle('MeleeSet', melee)
            -- /wsset: how buffed you are, for weapon skills only. High wears <WS set>_HighBuff over each WS set.
            gcdisplay.CreateCycle('WsSet', { 'Mid', 'High' })
            -- /idleset: Idle_<mode> over Idle while idle (gcinclude.EquipIdle).
            gcdisplay.CreateCycle('IdleSet', { 'Default', 'Refresh', 'Regen', 'Regain' })
            gcinclude.BuildWeaponCycles()
            if type(gcinclude.DefaultWeapons) == 'string' then
                gcinclude.SetWeaponCycle('Weapons', gcinclude.DefaultWeapons, true)
            elseif type(gcinclude.DefaultWeapons) == 'table' then
                for cname, val in pairs(gcinclude.DefaultWeapons) do
                    gcinclude.SetWeaponCycle(cname, val, true)
                end
            end
            if gchud ~= nil then gchud.Bind(gcinclude, gcdisplay) end
            if gcgear ~= nil then gcgear.Bind(gcinclude, gcdisplay) end
            if (mJob == 'RDM') or (mJob == 'BLM') or (mJob == 'SCH') or (mJob == 'GEO') then
                gcdisplay.CreateToggle('Burst', false) -- /burst: Burst set on every nuke, not only on live skillchains
                -- a job can add modes (RDM GEO BLM SCH: 'OccultAcumen')
                gcdisplay.CreateCycle('NukeSet', gcinclude.NukeModes or { 'Power', 'Macc' })
                if (mJob == 'BLM') or (mJob == 'SCH') then
                    gcdisplay.CreateCycle('Weapon', { [1] = 'Club', [2] = 'Staff' })
                    if mJob == 'BLM' then gcdisplay.CreateToggle('Death', false) end
                end
            end
            if mJob == 'WHM' then
                -- a job can add modes (RDM GEO BLM SCH: 'OccultAcumen')
                gcdisplay.CreateCycle('NukeSet', gcinclude.NukeModes or { 'Power', 'Macc' })
            elseif mJob == 'DRK' then
                -- /nukeset oa: OccultAcumen set on nukes
                gcdisplay.CreateCycle('NukeSet', gcinclude.NukeModes or { 'Power', 'OccultAcumen' })
            end
            if (mJob == 'PLD') or (mJob == 'RUN') then
                gcdisplay.CreateCycle('TankSet', { [1] = 'None', [2] = 'Main', [3] = 'MEVA' })
            end
            gcdisplay.CreateToggle('PROC', false) -- /proc: every job (Proc / Ws_Proc sets, worn by the engine)
            if mJob == 'PUP' then
                gcdisplay.CreateCycle('PupMode', { [1] = 'Tank', [2] = 'Melee', [3] = 'Ranger', [4] = 'Mage' })
            end
            if mJob == 'BRD' then
                gcdisplay.CreateToggle('String', false)
                gcdisplay.CreateToggle('SongLock', false)
            end
            gcdisplay.MarkDefaults()
        end
    end

    runtime.Settings = settings
end

-- == Commands ==
do
    -- Command routing and aliases. Public gcinclude entry points are installed unchanged.
    local commands = {}
    function commands.Install(gcinclude)
        function gcinclude.CycleDefense(arg)
            local want = string.lower(tostring(arg or ''))
            if want ~= '' then -- /def off|none, or a set by name (dt, mdt, aminon)
                local pick = nil
                for _, d in ipairs(gcinclude.DefenseCycle) do
                    if (string.lower(d[2]) == want) or (string.lower(d[1]) == want) then pick = d end
                end
                if (pick == nil) and (want ~= 'off') and (want ~= 'none') then
                    gcinclude.Err('/def off|dt|mdt|aminon (no ' .. want .. ')')
                    return 'unknown: ' .. want
                end
                for _, d in ipairs(gcinclude.DefenseCycle) do
                    gcdisplay.SetToggle(d[1], d == pick)
                end
                return (pick ~= nil) and pick[2] or 'None'
            end
            local current = 0
            for i, d in ipairs(gcinclude.DefenseCycle) do
                if (gcdisplay.GetToggle(d[1]) == true) and (current == 0) then current = i end
                gcdisplay.SetToggle(d[1], false)
            end
            local nextOne = gcinclude.DefenseCycle[current + 1]
            if nextOne == nil then return 'None' end
            gcdisplay.SetToggle(nextOne[1], true)
            return nextOne[2]
        end

        function gcinclude.FlipToggle(name, arg)
            local a = string.lower(tostring(arg or ''))
            if a == 'on' then
                gcdisplay.SetToggle(name, true)
            elseif a == 'off' then
                gcdisplay.SetToggle(name, false)
            else
                gcdisplay.AdvanceToggle(name)
            end
            return gcdisplay.GetToggle(name)
        end

        function gcinclude.Message(toggle, status)
            if toggle ~= nil and status ~= nil then
                if type(status) == 'boolean' then status = status and 'on' or 'off' end
                gcinclude.Say(toggle .. ' ' .. tostring(status))
            end
        end

        function gcinclude.SetAlias()
            for _, v in ipairs(gcinclude.AliasList) do
                AshitaCore:GetChatManager():QueueCommand(-1, '/alias /' .. v .. ' /lac fwd ' .. v)
            end
        end

        function gcinclude.ClearAlias()
            for _, v in ipairs(gcinclude.AliasList) do
                AshitaCore:GetChatManager():QueueCommand(-1, '/alias del /' .. v)
            end
        end

        function gcinclude.HandleCommands(args)
            if type(args[1]) == 'string' then
                args[1] = string.lower(args[1])
            end -- //gs c MeleeSet works too
            -- gcclick <command>: a click on the bar or a dropped line; always says the new value in chat
            local clicked = false
            if args[1] == 'gcclick' then
                table.remove(args, 1)
                clicked = true
                if type(args[1]) == 'string' then args[1] = string.lower(args[1]) end
            end
            if not gcinclude.AliasList:contains(args[1]) then return end

            local player = gData.GetPlayer()
            local toggle = nil
            local status = nil

            if args[1] == 'gcmessages' then
                local m = string.lower(tostring(args[2] or ''))
                if (m == 'on') or (m == 'off') then
                    gcinclude.settings.Messages = (m == 'on')
                else
                    gcinclude.settings.Messages = not gcinclude.settings.Messages
                end
                gcinclude.Say('Chat messages ' .. (gcinclude.settings.Messages and 'on' or 'off'))
            elseif args[1] == 'wsdistance' then
                local w = (args[2] ~= nil) and string.lower(args[2]) or nil
                if (w == 'on') or (w == 'off') then
                    gcinclude.settings.WScheck = (w == 'on')
                    gcinclude.Say('WS distance check is now ' .. tostring(gcinclude.settings.WScheck))
                elseif tonumber(args[2]) then
                    gcinclude.settings.WScheck = true
                    gcinclude.settings.WSdistance = tonumber(args[2])
                    gcinclude.Say('WS Distance is on and set to ' .. gcinclude.settings.WSdistance)
                else
                    gcinclude.settings.WScheck = not gcinclude.settings.WScheck
                    gcinclude.Say('WS distance check is now ' .. tostring(gcinclude.settings.WScheck))
                    gcinclude.Say('/wsdistance N: the least reach in yalms (a big mob reaches further: WS range '
                        .. gcinclude.WsRange .. ' + both hitboxes)')
                end
            elseif args[1] == 'dt' then
                gcinclude.FlipToggle('DTset', args[2])
                toggle = 'DT Set'
                status = gcdisplay.GetToggle('DTset')
            elseif args[1] == 'sir' then
                if gcdisplay.GetToggle('Aminon') == true then
                    gcdisplay.SetToggle('SIR', false)
                    gcinclude.Err('/sir stays off while Aminon is on')
                else
                    gcinclude.FlipToggle('SIR', args[2])
                end
                toggle = 'Spell Interrupt Set'
                status = gcdisplay.GetToggle('SIR')
            elseif args[1] == 'def' then
                toggle, status = 'Defense', gcinclude.CycleDefense(args[2])
                gcinclude.CheckAminonLock()
            elseif args[1] == 'mdt' then
                gcinclude.FlipToggle('MDTset', args[2])
                toggle = 'MDT Set'
                status = gcdisplay.GetToggle('MDTset')
            elseif args[1] == 'mset' then
                local before = gcinclude.WeaponLayerKey()
                gcinclude.PickCycle('MeleeSet', args[2])
                if gcinclude.WeaponLayerKey() ~= before then
                    gcinclude.ApplyWeapons(true)
                end -- a Weapon_<mode>Acc: you asked, swaps at any TP
                toggle = 'Melee mode'
                status = gcinclude.ModeLabel('MeleeSet', gcdisplay.GetCycle('MeleeSet'))
            elseif args[1] == 'wsset' then
                gcinclude.PickCycle('WsSet', args[2])
                toggle = 'WS Set'
                status = gcdisplay.GetCycle('WsSet')
            elseif args[1] == 'idleset' then
                gcinclude.PickCycle('IdleSet', args[2])
                toggle = 'Idle set'
                status = gcdisplay.GetCycle('IdleSet')
            elseif gcinclude.WeaponCommands[args[1]] ~= nil then
                local cname = gcinclude.WeaponCommands[args[1]]
                gcinclude.WeaponCommand(cname, args)
                toggle = cname
                status = gcdisplay.GetCycle(cname)
            elseif args[1] == 'hoxne' then
                if (args[2] ~= nil) and (string.lower(args[2]) == 'use') then
                    gcinclude.SetWeaponCycle('Hoxne', 'Locked', true)
                    gcinclude.CheckHoxne()
                    gcinclude.UseEnchanted(gcinclude.settings.HoxneItem, 'Ammo', 'hoxne')
                elseif args[2] ~= nil then
                    local want = string.lower(args[2])
                    -- on = Locked; a word matching neither is reported
                    gcinclude.SetWeaponCycle('Hoxne', (want == 'on') and 'Locked' or want)
                else
                    gcdisplay.AdvanceCycle('Hoxne')
                end
                toggle = 'Hoxne'
                status = gcdisplay.GetCycle('Hoxne')
            elseif args[1] == 'gcconfig' then
                gcinclude.ConfigCommand(args[2])
            elseif args[1] == 'gcbuild' then -- common/gcbuild.lua, loaded on use
                local ok, mod = pcall(gFunc.LoadFile, 'common\\gcbuild.lua')
                if not ok or (type(mod) ~= 'table') then
                    gcinclude.Err('/' .. args[1] .. ': common\\gcbuild.lua failed to load')
                else -- <JOB>.proposed.lua: the job's example with the gear you own
                    local job, proposed, dir = mod.Run({ args[2], args[3] }, gcinclude.Say, gcinclude.Err)
                    if (job ~= nil) then
                        gcinclude.EditorDraft(job, proposed, dir)
                    end
                end
            elseif args[1] == 'gcimport' then -- a GearSwap job file's sets as a draft (common/gcgsimport.lua)
                local ok, mod = pcall(gFunc.LoadFile, 'common\\gcgsimport.lua')
                local okF, setFile = pcall(gFunc.LoadFile, 'common\\gcsetfile.lua')
                if not ok or (type(mod) ~= 'table') or not okF then
                    gcinclude.Err('/gcimport: common\\gcgsimport.lua failed to load')
                else
                    local rest = {}
                    for i = 2, #args do rest[#rest + 1] = args[i] end
                    local job, proposed, dir = mod.Run(rest, gcinclude.Say, gcinclude.Err, setFile)
                    if (job ~= nil) then gcinclude.EditorDraft(job, proposed, dir, '/gcimport') end
                end
            elseif args[1] == 'gcedit' then -- the set editor window (common/gcedit.lua, Ashita, loaded on use)
                local words = {}
                for i = 2, #args do
                    words[#words + 1] = tostring(args[i])
                end
                local w1, w2 = string.lower(words[1] or ''), string.lower(words[2] or '')
                if (w1 == 'last') and ((#words == 1)
                    or ((#words == 2) and (gcinclude.EditorLastSlots[w2] ~= nil))) then
                    gcinclude.EditorLast(words[2]) -- /gcedit last [slot] ('/gcedit Last Stand' is the set)
                else
                    gcinclude.EditorCommand((#words > 0) and table.concat(words, ' ') or nil) -- /gcedit Savage Blade
                end
            elseif args[1] == 'gce' then
                gcinclude.EnchantCommand(args)
            elseif args[1] == 'gchelp' then
                gcinclude.Help()
            elseif args[1] == 'gckey' then
                gcinclude.KeyCommand(args)
            elseif args[1] == 'aminon' then
                gcinclude.FlipToggle('Aminon', args[2])
                gcinclude.CheckAminonLock()
                toggle = 'Aminon Set'
                status = gcdisplay.GetToggle('Aminon')
            elseif args[1] == 'gchud' then
                if gchud ~= nil then
                    gchud.HandleCommand(args)
                else
                    gcinclude.Err('HUD is not loaded.')
                end
            elseif args[1] == 'smartswap' then
                gcinclude.SmartSwapCommand(args)
            elseif args[1] == 'autogear' then
                gcinclude.AutoGearCommand(args)
            elseif args[1] == 'gcbar' then
                gcdisplay.BarCommand(args)
            elseif args[1] == 'gcgear' then
                if gcgear ~= nil then
                    gcgear.HandleCommand(args)
                else
                    gcinclude.Err('Gear grid is not loaded.')
                end
            elseif args[1] == 'lock' then
                gcinclude.LockCommand(args)
            elseif args[1] == 'unlock' then
                gcinclude.UnlockCommand(args)
            elseif args[1] == 'gcperf' then
                gcinclude.PerfCommand(args[2] and string.lower(args[2]))
            elseif args[1] == 'checksets' then
                gcinclude.CheckSets()
            elseif args[1] == 'kite' then
                gcinclude.FlipToggle('Kite', args[2])
                toggle = 'Kite Set'
                status = gcdisplay.GetToggle('Kite')
            elseif args[1] == 'th' then
                gcinclude.FlipToggle('TH', args[2])
                toggle = 'TH Set'
                status = gcdisplay.GetToggle('TH')
            elseif gcinclude.TeleRings[args[1]] ~= nil then
                gcinclude.UseTeleRing(gcinclude.TeleRings[args[1]])
            elseif gcinclude.ExitItems[args[1]] ~= nil then
                AshitaCore:GetChatManager()
                    :QueueCommand(-1, '/item "' .. gcinclude.ExitItems[args[1]] .. '" <me>')
            elseif args[1] == 'dw' then
                gcinclude.DualWieldCommand(args)
            elseif gcinclude.CarriedKeys:contains(args[1]) then
                gcinclude.CarriedCommand(args[1], args[2] and string.lower(args[2]))
            elseif args[1] == 'abyproc' then
                gcinclude.AbyProcCommand(args[2] and string.lower(args[2]))
            end
            if (player.MainJob == 'RDM') or (player.MainJob == 'BLM') or (player.MainJob == 'SCH')
                or (player.MainJob == 'GEO') then
                if args[1] == 'nukeset' then
                    gcinclude.PickCycle('NukeSet', args[2])
                    toggle = 'Nuking Gear Set'
                    status = gcdisplay.GetCycle('NukeSet')
                elseif args[1] == 'burst' then
                    gcinclude.FlipToggle('Burst', args[2])
                    toggle = 'Burst set on every nuke'
                    status = gcdisplay.GetToggle('Burst')
                end
                if (player.MainJob == 'BLM') or (player.MainJob == 'SCH') then
                    if args[1] == 'weapon' then
                        gcinclude.PickCycle('Weapon', args[2])
                        toggle = 'Mage Weapon'
                        status = gcdisplay.GetCycle('Weapon')
                    end
                    if player.MainJob == 'BLM' then
                        if args[1] == 'death' then
                            gcinclude.FlipToggle('Death', args[2])
                            toggle = 'BLM Death Set'
                            status = gcdisplay.GetToggle('Death')
                        end
                    end
                end
            end
            if ((player.MainJob == 'WHM') or (player.MainJob == 'DRK')) and (args[1] == 'nukeset') then
                gcinclude.PickCycle('NukeSet', args[2])
                toggle = 'Nuking Gear Set'
                status = gcdisplay.GetCycle('NukeSet')
            end
            if (player.MainJob == 'PLD') or (player.MainJob == 'RUN') then
                if args[1] == 'tankset' then
                    gcinclude.PickCycle('TankSet', args[2])
                    toggle = 'Tank Gear Set'
                    status = gcdisplay.GetCycle('TankSet')
                end
            end
            do
                if args[1] == 'proc' then -- every job
                    gcinclude.FlipToggle('PROC', args[2])
                    -- a proc window: Hoxne and Aminon go off, with their locks
                    if gcdisplay.GetToggle('PROC') == true then
                        local off = {}
                        if gcdisplay.GetCycle('Hoxne') == 'Locked' then
                            gcdisplay.SetCycle('Hoxne', 'Off')
                            gcinclude.CheckHoxne()
                            off[#off + 1] = '/hoxne'
                        end
                        if gcdisplay.GetToggle('Aminon') == true then
                            gcdisplay.SetToggle('Aminon', false)
                            gcinclude.CheckAminonLock()
                            off[#off + 1] = '/aminon'
                        end
                        if #off > 0 then gcinclude.Say(table.concat(off, ' and ') .. ' off: /proc is on') end
                    end
                    toggle = 'Low Damage PROC Set'
                    status = gcdisplay.GetToggle('PROC')
                    if player.MainJob == 'NIN' then
                        -- an owned lock, so it never undoes your /lock ammo or Hoxne's (raw /lac disable|enable did)
                        if gcdisplay.GetToggle('PROC') == true then
                            gcinclude.LockSlots(T{ 4 }, 'proc')
                        else
                            gcinclude.UnlockSlots(T{ 4 }, 'proc')
                        end
                    end
                end
            end
            if player.MainJob == 'PUP' then
                if args[1] == 'pupmode' then
                    gcinclude.PickCycle('PupMode', args[2])
                    toggle = 'Puppet Mode'
                    status = gcdisplay.GetCycle('PupMode')
                end
            end
            if player.MainJob == 'BRD' then
                if args[1] == 'forcestring' then
                    gcinclude.FlipToggle('String', args[2])
                    toggle = 'BRD Forced Harp'
                    status = gcdisplay.GetToggle('String')
                elseif args[1] == 'songlock' then
                    gcinclude.FlipToggle('SongLock', args[2])
                    toggle = 'BRD Song Lock'
                    status = gcdisplay.GetToggle('SongLock')
                end
            end
            if player.MainJob == 'SMN' then
                if args[1] == 'siphon' then gcinclude.DoSiphon() end
            end

            if gcinclude.settings.Messages or clicked then gcinclude.Message(toggle, status) end
        end
    end

    runtime.Commands = commands
end

-- == Weapons ==
do
    -- Weapon-mode selection and layers. Slot resolution and TH policy stay with the host.
    local weapons = {}
    function weapons.Install(gcinclude, dependencies)
        local slotOf, thFullTime = dependencies.slotOf, dependencies.thFullTime
        local PICK_LISTS = { Main = 'MainModes', Sub = 'SubModes', Range = 'RangeModes', Ammo = 'AmmoModes' }

        function gcinclude.WeaponCycleList(cname)
            if cname == 'Weapons' then return gcinclude.WeaponModes end
            if cname == 'Hoxne' then return T{ 'Off', 'Locked' } end
            return (PICK_LISTS[cname] ~= nil) and gcinclude[PICK_LISTS[cname]] or nil
        end

        function gcinclude.WeaponLabel(v)
            if type(v) == 'string' then return v end
            if (type(v) ~= 'table') or (type(v.Name) ~= 'string') then return nil end
            if v.AugPath ~= nil then return v.Name .. ' (' .. tostring(v.AugPath) .. ')' end
            return v.Name
        end

        local function itemKey(v) -- one weapon however it is written: 'Rostam (B)', RostamB in WeaponItemMap, the table
            v = (type(v) == 'string') and (gcinclude.WeaponItems[string.lower(v)] or v) or v
            if type(v) == 'table' then
                return string.lower(tostring(v.Name)) .. '|' .. string.lower(tostring(v.AugPath or ''))
            end
            return string.lower(tostring(v)) .. '|'
        end

        -- /mw /sw /rw picks: the job's own list (gcinclude.MainModes ...) in its order, then every other item its
        -- Weapon_ sets put in that slot, so no list is needed to pick one (/mw cali, /sw bunzi). A table item is
        -- labelled as the bar shows it: 'Rostam (B)'.
        local function pickList(cname)
            local declared = gcinclude[PICK_LISTS[cname]]
            local list, seen = T{ 'None' }, { ['none|'] = true }
            local function add(label, item)
                if (type(label) ~= 'string') or gcinclude.WeaponKeywords:contains(string.lower(label)) then return end
                if item ~= nil then gcinclude.WeaponItems[string.lower(label)] = item end
                local key = itemKey(item or label)
                if not seen[key] then
                    seen[key] = true
                    list:append(label)
                end
            end
            for _, v in ipairs((type(declared) == 'table') and declared or {}) do
                add(v)
            end
            local sets = (gProfile ~= nil) and (type(gProfile.Sets) == 'table') and gProfile.Sets or {}
            local names = {}
            for key, set in pairs(sets) do
                if (type(key) == 'string') and (string.lower(string.sub(key, 1,
                    7)) == 'weapon_') and (type(set) == 'table') then
                    names[#names + 1] = key
                end
            end
            table.sort(names)
            for _, key in ipairs(names) do
                for k, v in pairs(sets[key]) do
                    if gcinclude.WeaponSlotNames[slotOf(k) or 0] == cname then
                        add(gcinclude.WeaponLabel(v), (type(v) == 'table') and v or nil)
                    end
                end
            end
            return (#list > 1) and list or nil
        end

        function gcinclude.BuildWeaponCycles()
            gcinclude.WeaponItems = {}
            if type(gcinclude.WeaponItemMap) == 'table' then
                for label, item in pairs(gcinclude.WeaponItemMap) do
                    gcinclude.WeaponItems[string.lower(label)] = item
                end
            end
            gcinclude.MainModes, gcinclude.SubModes, gcinclude.RangeModes = pickList('Main'), pickList('Sub'),
                pickList('Range')
            if (type(gcinclude.AmmoModes) ~= 'table') or (#gcinclude.AmmoModes == 0) then
                gcinclude.AmmoModes = T{ 'None' }
            end
            for _, cname in ipairs(T{ 'Weapons', 'Main', 'Sub', 'Range' }) do
                local list = gcinclude.WeaponCycleList(cname)
                if (type(list) == 'table') and (#list > 0) then gcdisplay.CreateCycle(cname, list) end
            end
            if #gcinclude.AmmoModes > 1 then gcdisplay.CreateCycle('Ammo', gcinclude.AmmoModes) end
        end

        function gcinclude.SetWeaponCycle(cname, val, quiet)
            local list = gcinclude.WeaponCycleList(cname)
            if type(list) ~= 'table' then return false end
            return gcinclude.SetCycleFrom(cname, list, val, quiet)
        end

        function gcinclude.PickCycle(cname, val)
            if (val == nil) or (val == '') then
                gcdisplay.AdvanceCycle(cname)
                return true
            end
            local list = gcdisplay.GetCycleValues(cname)
            if type(list) ~= 'table' then return false end
            return gcinclude.SetCycleFrom(cname, list, val)
        end

        -- A value's initials: first letter, each capital after a lower-case letter, each letter after a space/_/-
        -- ('OccultAcumen' -> 'oa', 'SubtleBlow' -> 'sb', 'Bunzi's Rod' -> 'br').
        local function initials(v)
            local out = string.sub(v, 1, 1)
            for i = 2, #v do
                local c, p = string.sub(v, i, i), string.sub(v, i - 1, i - 1)
                if (string.find(c, '%u') and string.find(p, '[%l%d]')) or (string.find(p,
                    '[%s_%-]') and string.find(c, '%w')) then
                    out = out .. c
                end
            end
            return string.lower(out)
        end

        -- What the HUD shows for a value (gchud's short form, both lengths, and settings.HUDAbbr), lower case, so
        -- typing
        -- what you see works: 'Anarchy +2' -> ana+2, 'Rostam B' -> rosb, 'Death Penalty' -> dea / deap.
        local function hudForms(v)
            local t = string.gsub(v, "['%.]", '')
            t = string.gsub(t, '[^%w%+]', ' ')
            t = string.gsub(t, '(%l)(%u)', '%1 %2')
            t = string.gsub(t, '(%w)(%+)', '%1 %2')
            local short, long, first = '', '', true
            for tok in string.gmatch(t, '%S+') do
                if first then
                    local w = (#tok <= 4) and tok or string.sub(tok, 1, 3)
                    short, long, first = w, w, false
                elseif string.match(tok, '^%+?%d+$') or (#tok == 1) then
                    short, long = short .. tok, long .. tok
                else
                    long = long .. string.sub(tok, 1, 1)
                end
            end
            local forms = { string.lower(short), string.lower(long) }
            local user = gcinclude.settings.HUDAbbr
            if type(user) == 'table' then
                for k, a in pairs(user) do
                    if string.lower(tostring(k)) == string.lower(v) then
                        forms[#forms + 1] = string.lower(tostring(a))
                    end
                end
            end
            return forms
        end

        -- Sets cycle cname to the value val names in list: a number, else the exact name (any case), else the one value
        -- it starts, else the one whose initials it is, else what the HUD shows for it, else the one containing it.
        -- Says why when nothing or more than one matches, unless quiet.
        function gcinclude.SetCycleFrom(cname, list, val, quiet)
            local wantBase = string.lower(tostring(val or ''))
            if (cname == 'MeleeSet') and (wantBase ~= '') and (string.sub('base', 1, #wantBase) == wantBase) then
                val = 'Default'
            end -- Base = Default
            local index = tonumber(val)
            if (index ~= nil) and (index >= 1) and (index <= #list) then
                return gcdisplay.SetCycle(cname, list[index])
            end
            local want = string.lower(val)
            for _, v in ipairs(list) do
                if string.lower(v) == want then return gcdisplay.SetCycle(cname, v) end
            end
            local hits = T{}
            for _, v in ipairs(list) do
                local lv = string.lower(v)
                if string.sub(lv, 1, string.len(want)) == want then hits:append(v) end
            end
            if #hits == 0 then
                for _, v in ipairs(list) do
                    if initials(v) == want then hits:append(v) end
                end
            end
            if #hits == 0 then
                for _, v in ipairs(list) do
                    for _, f in ipairs(hudForms(v)) do
                        if f == want then
                            hits:append(v)
                            break
                        end
                    end
                end
            end
            if #hits == 0 then
                for _, v in ipairs(list) do
                    if string.find(string.lower(v), want, 1, true) ~= nil then hits:append(v) end
                end
            end
            if #hits > 1 then -- 'carn' with Carnwenhan and CarnwenhanTP: the one every other hit extends
                for _, h in ipairs(hits) do
                    local lh, all = string.lower(h), true
                    for _, o in ipairs(hits) do
                        if string.sub(string.lower(o), 1, #lh) ~= lh then
                            all = false
                            break
                        end
                    end
                    if all then return gcdisplay.SetCycle(cname, h) end
                end
            end
            if #hits == 1 then
                return gcdisplay.SetCycle(cname, hits[1])
            elseif quiet == true then
                return false
            elseif #hits > 1 then
                gcinclude.Err(cname .. ' match is ambiguous: ' .. table.concat(hits, ', '))
            else
                local names = {}
                for _, v in ipairs(list) do
                    names[#names + 1] = tostring(v)
                end
                gcinclude.Err('No ' .. cname .. ' match for: ' .. val .. '. Choices: ' .. table.concat(names, ', '))
            end
            return false
        end

        -- The set a weapon mode wears: its /mset variant first (Weapon_Carnwenhan_Acc or Weapon_CarnwenhanAcc while
        -- /mset Acc), else Weapon_<mode> (_1h without Dual Wield). nil: none.
        local function modeSet(mode)
            local set = nil
            local ms = gcdisplay.GetCycle('MeleeSet')
            if (type(ms) == 'string') and (ms ~= 'Default') then
                set = gcinclude.WeaponSetFor(mode .. '_' .. ms) or gcinclude.WeaponSetFor(mode .. ms)
            end
            return set or gcinclude.WeaponSetFor(mode)
        end

        -- The current weapon mode's own item for a slot (Weapon_<Mode>[_1h].Sub...), lower case, or nil.
        local function modeSlotItem(cname)
            local mode = gcdisplay.GetCycle('Weapons')
            if not gcinclude.IsWeaponValue(mode) then return nil end
            local set = gcinclude.WeaponSetFor(mode)
            local item = (type(set) == 'table') and set[cname] or nil
            if type(item) == 'table' then item = item.Name end
            return (type(item) == 'string') and string.lower(item) or nil
        end

        -- One slot pick by name, number or default/none (back to the weapon mode's own). Says why when it can't.
        local function setPick(cname, arg)
            local list = gcinclude.WeaponCycleList(cname)
            if (type(list) ~= 'table') or (#list == 0) then
                gcinclude.Err(cname .. ': no picks. Name the item in a Weapon_ set, or list it in gcinclude.'
                    .. PICK_LISTS[cname])
                return false
            end
            local want = string.lower(arg)
            if (want == 'default') or (want == 'def') or (want == 'mode') or (want == 'off') then
                return gcinclude.SetWeaponCycle(cname, 'None', true)
            end
            -- naming the mode's own item for the slot (/sw thibron while the mode wears Thibron) = None
            local own = modeSlotItem(cname)
            if (own ~= nil) and (string.sub(own, 1, #want) == want) and gcinclude.SetWeaponCycle(cname,
                'None', true) then
                gcinclude.Say(cname .. ": None (the weapon mode's own)")
                return true
            end
            return gcinclude.SetWeaponCycle(cname, arg) -- reports no match / ambiguous, with the choices
        end

        -- /wm [mode|N|none|default|role] [sub] [force]; /mw /sw /rw /ammoset [item|N|none] [force].
        function gcinclude.WeaponCommand(cname, args)
            local force = false
            local words = T{}
            for i = 2, #args do
                if string.lower(args[i]) == 'force' then
                    force = true
                else
                    words:append(args[i])
                end
            end
            local arg = (#words > 0) and table.concat(words, ' ') or nil
            local list = gcinclude.WeaponCycleList(cname)
            if (cname == 'Weapons') and ((type(list) ~= 'table') or (#list == 0)) then
                gcinclude.Err('No weapon modes: add Weapon_<Name> sets and gcinclude.WeaponModes (/gcedit + New set does both)')
                return
            end
            local before = gcinclude.WeaponLayerKey()
            local modeBefore = gcdisplay.GetCycle('Weapons')
            local setNow = {} -- slot picks this command sets itself: kept
            if arg == nil then
                if (type(list) ~= 'table') or (#list == 0) then return setPick(cname, '') end
                gcdisplay.AdvanceCycle(cname)
            elseif cname ~= 'Weapons' then
                if not setPick(cname, arg) then return end
            else
                local want = string.lower(arg)
                if (want == 'default') and (type(gcinclude.DefaultWeapons) == 'table') then
                    for dname, dval in pairs(gcinclude.DefaultWeapons) do
                        gcinclude.SetWeaponCycle(dname, dval, true)
                        setNow[dname] = true
                    end
                elseif want == 'default' then
                    gcinclude.SetWeaponCycle('Weapons', gcinclude.DefaultWeapons or 'None', true)
                elseif (type(gcinclude.WeaponRoles) == 'table') and (gcinclude.WeaponRoles[want] ~= nil) then
                    gcinclude.SetWeaponCycle('Weapons', gcinclude.WeaponRoles[want])
                elseif gcinclude.WeaponRoleNames:contains(want) then
                    gcinclude.Err('/wm ' .. want .. ': no gcinclude.WeaponRoles entry for it')
                    return
                elseif not gcinclude.SetWeaponCycle('Weapons', arg, #words > 1) then
                    -- /wm <mode> <sub>: the mode, then a Sub pick over it (/wm cali bunzi)
                    if (#words < 2) or not gcinclude.SetWeaponCycle('Weapons', words[1]) then return end
                    setPick('Sub', table.concat(words, ' ', 2))
                    setNow.Sub = true
                end
            end
            -- a new mode takes back the slots its set names: picks there go (/mw Naegling, then /wm Tizona: Tizona)
            local mode = gcdisplay.GetCycle('Weapons')
            if (cname == 'Weapons') and (mode ~= modeBefore) and gcinclude.IsWeaponValue(mode) then
                local set = modeSet(mode)
                for k, _ in pairs((type(set) == 'table') and set or {}) do
                    local slot = gcinclude.WeaponSlotNames[slotOf(k) or 0]
                    if (slot ~= nil) and (not setNow[slot]) and gcinclude.IsWeaponValue(gcdisplay.GetCycle(slot)) then
                        gcinclude.SetWeaponCycle(slot, 'None', true)
                    end
                end
            end
            -- force re-applies the current weapons: a lock may have kept them off
            if (gcinclude.WeaponLayerKey() ~= before) or force then
                gcinclude.ApplyWeapons(true) -- you asked: swaps at any TP (the TP hold only guards automatic swaps)
            end
        end

        function gcinclude.IsWeaponValue(v)
            return (v ~= nil) and (v ~= 'None') and (v ~= 'Unknown')
        end

        -- Weapon_<name>, Weapon_<name>_1h first when you can't dual wield.
        function gcinclude.WeaponSetFor(name)
            if not gcinclude.CanDualWield() then
                local s = gcinclude.FindSet('Weapon_' .. name .. '_1h')
                if s ~= nil then return s end
            end
            return gcinclude.FindSet('Weapon_' .. name)
        end

        function gcinclude.BuildWeaponLayer()
            local equip = {}
            local mode = gcdisplay.GetCycle('Weapons')
            if gcinclude.IsWeaponValue(mode) then
                local set = modeSet(mode)
                if set == nil then
                    if gcinclude.MissingWarned[mode] == nil then
                        gcinclude.MissingWarned[mode] = true
                        gcinclude.Err('Missing set: Weapon_' .. mode)
                    end
                else
                    for k, v in pairs(set) do
                        local slot = slotOf(k)
                        if gcinclude.WeaponSlots:contains(slot) then equip[gcinclude.WeaponSlotNames[slot]] = v end
                    end
                end
            end
            for _, cname in ipairs(gcinclude.WeaponSlotNames) do
                local v = gcdisplay.GetCycle(cname)
                if gcinclude.IsWeaponValue(v) then equip[cname] = gcinclude.WeaponItems[string.lower(v)] or v end
            end
            if (equip.Sub ~= nil) and gcinclude.SubRefusedNow(equip.Sub) then equip.Sub = nil end
            -- Full-time TH (THF): Main/Sub/Range in the TH set stay on while /th is on, tagged or not: swapping them
            -- resets TP. Sub only when you can dual wield. Other jobs: CheckTH wears them until the tag like the rest.
            if (gcdisplay.GetToggle('TH') == true) and thFullTime() then
                local th = gcinclude.FindSet('TH')
                if th ~= nil then
                    for k, v in pairs(th) do
                        local slot = slotOf(k)
                        if gcinclude.HoldSlots:contains(slot) and ((slot ~= 2) or gcinclude.CanDualWield()) then
                            equip[gcinclude.WeaponSlotNames[slot]] = v
                        end
                    end
                end
            end
            return (next(equip) ~= nil) and equip or nil
        end

        -- The weapon layer as one string, to tell whether a command changed it.
        function gcinclude.WeaponLayerKey()
            local set = gcinclude.BuildWeaponLayer() or {}
            local out = {}
            for _, cname in ipairs(gcinclude.WeaponSlotNames) do
                out[#out + 1] = tostring(gcinclude.WeaponLabel(set[cname]))
            end
            return table.concat(out, '|')
        end

        function gcinclude.ApplyWeapons(force)
            if (gcdisplay.GetToggle('Aminon') == true) and (#gcinclude.AminonOwned > 0) then
                -- /aminon holds the weapons: let go, then CheckAminonLock puts the (new) mode's on and locks them again
                gcinclude.UnlockSlots(gcinclude.AminonOwned, 'aminon')
                gcinclude.AminonOwned = T{}
                gcinclude.CheckAminonLock()
                return
            end
            local set = gcinclude.BuildWeaponLayer()
            if set == nil then return end
            local p = gData.GetPlayer()
            -- idle weapons stay; the mode's come on when you engage
            if (gcinclude.IdleWeaponSlots ~= nil) and (p ~= nil) and (p.Status ~= 'Engaged') then
                for n, _ in pairs(gcinclude.IdleWeaponSlots) do
                    set[gcinclude.WeaponSlotNames[n]] = nil
                end
                if next(set) == nil then return end
            end
            if force == true then
                gcinclude.UnlockWeapons() -- force lifts the TP hold only; /lock stays absolute
                gcinclude.NextHoldCheck = os.clock() + 0.5 -- let the swap land before the hold re-checks
            end
            gcinclude.ForceUnlocked(set)
        end

        function gcinclude.IdleWeaponDrop(set, player)
            if (set == nil) or (gcinclude.settings.IdleWeapons == false) or (player == nil)
                or (player.Status == 'Engaged') then
                return nil
            end
            -- runs on every HandleDefault out of combat: no helper closures, a table only when something is dropped
            local buffered = gcinclude.BufferedItem
            local drop = nil
            if (buffered(1) ~= nil) or (buffered(2) ~= nil) then drop = { [1] = true, [2] = true } end
            if buffered(3) ~= nil then
                drop = drop or {}
                drop[3], drop[4] = true, true
            elseif buffered(4) ~= nil then
                drop = drop or {}
                drop[4] = true
            end
            return drop
        end

        -- the weapon mode / slot picks (idle sets' own weapons win while idle)
        function gcinclude.WearWeaponLayer(player)
            local set = gcinclude.BuildWeaponLayer()
            local drop = gcinclude.IdleWeaponDrop(set, player)
            gcinclude.IdleWeaponSlots = drop
            if drop ~= nil then
                for n, _ in pairs(drop) do
                    set[gcinclude.WeaponSlotNames[n]] = nil
                end
            end
            if (set ~= nil) and (next(set) ~= nil) then gFunc.EquipSet(set) end
        end

        function gcinclude.CheckWeapons(player)
            gcinclude.WearWeaponLayer(player)
            gcinclude.CheckMDT()
            gcinclude.CheckHoxne()
            gcinclude.CheckTH()
            gcinclude.CheckReceived()
            gcinclude.CheckBuffSets()
            gcinclude.CheckHoxneCombos(player) -- Hoxne + buff sets over the plain buff sets
            gcinclude.CheckXIRoll(player)
        end
    end

    runtime.Weapons = weapons
end

-- == Elements ==
do
    -- Element gear: obi, Orpheus's Sash, back piece and Zodiac Ring by the action's element, day and weather, and
    -- Healing Magic's LightBonus set.
    local elements = {}
    function elements.Install(gcinclude, dependencies)
        local slotOf = dependencies.slotOf
        gcinclude.WeakTo = T{ Fire = 'Water', Ice = 'Fire', Wind = 'Ice', Earth = 'Wind',
            Thunder = 'Earth', Water = 'Thunder', Light = 'Dark', Dark = 'Light' }
        gcinclude.NinjutsuNukes = T{'Katon', 'Hyoton', 'Huton', 'Doton', 'Raiton', 'Suiton'}
        gcinclude.QuickDrawElement = { ['Fire Shot'] = 'Fire', ['Ice Shot'] = 'Ice', ['Wind Shot'] = 'Wind',
            ['Earth Shot'] = 'Earth',
            ['Thunder Shot'] = 'Thunder', ['Water Shot'] = 'Water', ['Light Shot'] = 'Light', ['Dark Shot'] = 'Dark' }

        -- Blue Magic lists that aren't damage: buffs, skill buffs, cures, debuffs, enmity, physical and stun spells.
        gcinclude.BluNoElementLists = T{'BluMagBuff', 'BluMagSkill', 'BluMagCure', 'BluMagDebuff', 'BluMagEnmity',
            'BluMagPhysical', 'BluMagStun'}

        -- Day/weather value for an element, in %: day +10, single weather +10, double weather +25; the element
        -- strong against it (WeakTo) subtracts the same. An obi forces all of it, bonus and penalty (BG
        -- Category:Elemental Obi: Hachirin keeps the forced penalty; example day +10 / double weather -25).
        function gcinclude.DayWeatherNet(element)
            local env = gData.GetEnvironment()
            if (env == nil) or (element == nil) then return 0 end
            local against = gcinclude.WeakTo[element]
            local double = (type(env.Weather) == 'string') and (string.find(env.Weather, 'x2', 1, true) ~= nil)
            local function weather(el)
                if (el ~= nil) and (env.WeatherElement == el) then return double and 25 or 10 end
                return 0
            end
            local net = weather(element) - weather(against)
            if env.DayElement == element then net = net + 10 end
            if (against ~= nil) and (env.DayElement == against) then net = net - 10 end
            return net
        end

        -- Orpheus's Sash: affinity rises as the target gets closer. BG documents only the ends: +15 at <= 1.93',
        -- +1 at >= 13'. In between it is interpolated linearly through settings.OrpheusPoints - an assumption,
        -- not a published formula. Add measured {distance, value} points there to refine it.
        function gcinclude.OrpheusValue(distance)
            if distance == nil then return nil end
            local pts = gcinclude.settings.OrpheusPoints
            if (type(pts) ~= 'table') or (#pts == 0) then return nil end
            if distance <= pts[1][1] then return pts[1][2] end
            for i = 2, #pts do
                local a, b = pts[i - 1], pts[i]
                if distance <= b[1] then return a[2] + (b[2] - a[2]) * (distance - a[1]) / (b[1] - a[1]) end
            end
            return pts[#pts][2]
        end

        function gcinclude.ElementCfg()
            return gcinclude.ElementGear or gcinclude.settings.ElementGear
        end

        function gcinclude.ElementWaist(element, noObi, noSash)
            local cfg = gcinclude.ElementCfg()
            if (type(cfg) ~= 'table') or (element == nil) then return nil end
            local obi = (type(cfg.Obis) == 'table') and cfg.Obis[element] or nil
            obi = obi or cfg.AnyObi
            if noObi == true then obi = nil end
            local obiValue = (obi ~= nil) and gcinclude.DayWeatherNet(element) or 0
            local sashValue = nil
            if (cfg.Distance ~= nil) and (noSash ~= true) then
                -- the action's target, not whatever is selected
                local target = gData.GetActionTarget() or gData.GetTarget()
                local d = (target ~= nil) and tonumber(target.Distance) or nil
                if (d ~= nil) and ((cfg.DistanceMax == nil) or (d <= cfg.DistanceMax)) then
                    sashValue = gcinclude.OrpheusValue(d)
                end
            end
            if (obiValue > 0) and ((sashValue == nil) or (obiValue > sashValue)) then return obi, obiValue end
            if sashValue ~= nil then return cfg.Distance, sashValue end
            return nil
        end

        function gcinclude.ElementKept(slot)
            local cfg = gcinclude.ElementCfg()
            local keep = (type(cfg) == 'table') and cfg.Keep or nil
            if (type(keep) ~= 'table') or (#keep == 0) then return false end
            local equip = gData.GetEquipment()
            if (equip == nil) or (equip[slot] == nil) or (equip[slot].Name == nil) then return false end
            local worn = string.lower(equip[slot].Name)
            for _, item in ipairs(keep) do
                if string.lower(item) == worn then return true end
            end
            return false
        end

        -- Zodiac Ring: the six elements only, never Lightsday/Darksday, never cures (BG-Wiki Zodiac Ring).
        function gcinclude.ElementRing(element)
            local cfg = gcinclude.ElementCfg()
            if (type(cfg) ~= 'table') or (cfg.Ring == nil) or (element == nil) then return nil end
            if (element == 'Light') or (element == 'Dark') then return nil end
            local env = gData.GetEnvironment()
            if (env == nil) or (env.DayElement ~= element) then return nil end
            return cfg.Ring, (cfg.RingSlot or 'Ring2')
        end

        -- Element gear per action (BG-Wiki): nukes and blue magic in ElementSkills, elemental ninjutsu, Quick Draw
        -- (day/weather count) and elemental WS get obi/Orpheus and the back piece; helixes always get day and
        -- weather, so never an obi; Cure/Cura/Curaga get Light day/weather (+10/+10/+25, the obi forces it) but no
        -- sash; Zodiac Ring only on ElementSkills spells (see ElementRing).
        function gcinclude.CheckElementGear()
            local action = gData.GetAction()
            if (action == nil) or (type(action.Name) ~= 'string') then return end
            local element, opts = nil, {}
            if action.ActionType == 'Spell' then
                local fam = gcinclude.Family(action.Name)
                local skills = gcinclude.settings.ElementSkills
                if gcinclude.HelixSpells:contains(fam) then
                    element, opts.noObi = action.Element, true
                elseif (type(skills) == 'table') and skills:contains(action.Skill) then
                    -- Blue Magic: damage spells only, never the buff/debuff/enmity/cure/physical lists (Subduction, a
                    -- TH spell on no other list, still gets it)
                    if (action.Skill ~= 'Blue Magic') or not gcinclude.BluNoElement(action.Name) then
                        element = action.Element
                    end
                elseif (action.Skill == 'Ninjutsu') and gcinclude.NinjutsuNukes:contains(fam) then
                    element, opts.noRing = action.Element, true
                elseif (action.Skill == 'Healing Magic') and gcinclude.CureObiOn() and T{ 'Cure', 'Cura',
                    'Curaga' }:contains(fam) then
                    element, opts.noSash, opts.noRing = 'Light', true, true
                    opts.noBack = (gcinclude.ElementCfg() or {}).BackOnCures ~= true
                end
            elseif action.ActionType == 'Weaponskill' then
                local list = gcinclude.settings.ElementalWS
                if type(list) == 'table' then element = list[action.Name] end
                opts.noRing = true -- Zodiac-type ring only on spells
            elseif action.ActionType == 'Ability' then
                element, opts.noRing = gcinclude.QuickDrawElement[action.Name], true
            end
            if (element == nil) or (element == 'Non-Elemental') then return end
            -- /th put its set on for this cast (untagged mob): the TH waist stays, the obi/Orpheus pick doesn't replace
            -- it
            if (gcinclude.THWorn == true) and (action.ActionType == 'Spell') and (gcinclude.FindSet('TH') ~= nil) then
                for k, _ in pairs(gcinclude.FindSet('TH')) do
                    if slotOf(k) == slotOf('Waist') then opts.keepWaist = true end
                end
            end
            gcinclude.ApplyElementGear(element, action.Name, opts)
        end

        function gcinclude.BluNoElement(name)
            for _, key in ipairs(gcinclude.BluNoElementLists) do
                local list = gcinclude[key]
                if (type(list) == 'table') and list:contains(name) then return true end
            end
            return false
        end

        -- Cure obi: the job file's gcinclude.CureObi (true/false) wins, else ElementGear.Cures.
        function gcinclude.CureObiOn()
            if gcinclude.CureObi ~= nil then return gcinclude.CureObi == true end
            return (gcinclude.ElementCfg() or {}).Cures == true
        end

        function gcinclude.ApplyElementGear(element, label, opts)
            if type(opts) ~= 'table' then
                opts = { noRing = (opts == true) }
            end -- old (element, label, noRing) form
            local set = {}
            local report = T{}
            local waist, value = nil, 0
            if opts.keepWaist ~= true then waist, value = gcinclude.ElementWaist(element, opts.noObi, opts.noSash) end
            if waist ~= nil then
                if gcinclude.ElementKept('Waist') then
                    report:append('waist kept')
                else
                    set.Waist = waist
                    report:append('waist ' .. waist .. string.format(' (+%.1f%%)', value))
                end
            end
            local cfg = gcinclude.ElementCfg()
            if (opts.noBack ~= true) and (type(cfg) == 'table') and (cfg.Back ~= nil) then
                local env = gData.GetEnvironment()
                local obiOn = (set.Waist ~= nil) and (set.Waist ~= cfg.Distance)
                local dayHit = (env ~= nil) and (env.DayElement == element)
                local weatherHit = (env ~= nil) and (env.WeatherElement == element) and (obiOn or (opts.noObi == true))
                if dayHit or weatherHit then
                    if gcinclude.ElementKept('Back') then
                        report:append('back kept')
                    else
                        set.Back = cfg.Back
                        report:append('back ' .. cfg.Back .. (dayHit and ' (day)' or ' (weather)'))
                    end
                end
            end
            local ring, slot = nil, nil
            if opts.noRing ~= true then ring, slot = gcinclude.ElementRing(element) end
            if ring ~= nil then
                if gcinclude.ElementKept(slot) then
                    report:append(string.lower(slot) .. ' kept')
                else
                    set[slot] = ring
                    report:append(string.lower(slot) .. ' ' .. ring)
                end
            end
            if next(set) == nil then return end
            gFunc.EquipSet(set)
            if gcinclude.settings.ElementReport == true then
                print(
                    chat.header('GoomSwap'):append(
                        chat.message((label or element) .. ' [' .. element .. ']: ' .. table.concat(report, ', '))
                    )
                )
            end
        end

        function gcinclude.CheckLightBonus()
            local action = gData.GetAction()
            if (action == nil) or (action.Skill ~= 'Healing Magic') then return end
            local set = gcinclude.FindSet('LightBonus')
            if (set ~= nil) then gFunc.EquipSet(set) end
        end
    end

    runtime.Elements = elements
end

-- == Enchants ==
do
    -- Enchanted-item timing, retries, and slot tracking. Instantiated per loaded profile.
    local enchants = {}
    function enchants.Install(gcinclude, dependencies)
        local slotOf, carriedId = dependencies.slotOf, dependencies.carriedId
        gcinclude.Enchants = {}
        -- Leave three seconds after the equip delay for the server to accept item use.
        local ENCHANT_MARGIN = 3.0
        local ENCHANT_RETRY = 2.0
        local ENCHANT_TRIES = 5
        local ENCHANT_EQUIP_WAIT = 10
        local ENCHANT_USE_WAIT = 15
        local slotSeen = {}

        local function equippedItem(slot, inv)
            inv = inv or AshitaCore:GetMemoryManager():GetInventory()
            local e = inv:GetEquippedItem(slot - 1)
            local index = (e ~= nil) and bit.band(e.Index, 0x00FF) or 0
            if index == 0 then return nil end
            local item = inv:GetContainerItem(bit.band(e.Index, 0xFF00) / 256, index)
            return ((item ~= nil) and (item.Count > 0)) and item or nil
        end

        local function equippedId(slot)
            local item = equippedItem(slot)
            return (item ~= nil) and item.Id or nil
        end

        local function trackSlots(now)
            local inv = AshitaCore:GetMemoryManager():GetInventory() -- once for all 16 slots
            for slot = 1, 16 do
                local item = equippedItem(slot, inv)
                local id = (item ~= nil) and item.Id or nil
                local s = slotSeen[slot]
                if id == nil then
                    slotSeen[slot] = nil
                elseif (s == nil) or (s.id ~= id) then
                    slotSeen[slot] = { id = id, at = now }
                end
            end
        end

        local function enchantInfo(item)
            local x = (item ~= nil) and item.Extra or nil
            if (type(x) ~= 'string') or (#x < 12) or (string.byte(x, 1) ~= 1) then return nil end
            return {
                charges = string.byte(x, 2),
                nextUse = struct.unpack('I', x, 5),
                activation = struct.unpack('I', x, 9),
            }
        end

        function gcinclude.ReleaseEnchant(index)
            local e = gcinclude.Enchants[index]
            if e == nil then return end
            gcinclude.UnlockSlots(T{ index }, 'enchant') -- Hoxne's or your own lock on the slot stays
            gcinclude.Enchants[index] = nil
            -- A ring CheckLockingRings keeps on (Warp, Dim., exp rings): stop keeping it, so your normal ring returns
            -- (once any zoning is over: SafeSetIdle).
            for _, r in ipairs(gcinclude.LockingRings) do
                if string.lower(r) == string.lower(e.item) then
                    gcinclude.SafeSetIdle(0, e.item)
                    break
                end
            end
        end

        local function enchant_step(e, now)
            if e.doneAt ~= nil then
                if now >= e.doneAt then gcinclude.ReleaseEnchant(e.index) end
                return
            end
            if e.equippedAt == nil then
                local item = equippedItem(e.index)
                if (item ~= nil) and (item.Id == e.id) then
                    e.equippedAt = now
                    local seen = slotSeen[e.index]
                    local onSince = now
                    if e.alreadyOn then onSince = ((seen ~= nil) and (seen.id == e.id)) and seen.at or -math.huge end
                    e.nextTry = math.max(now + 0.5, onSince + e.delay + ENCHANT_MARGIN)
                    local info = enchantInfo(item)
                    e.extPending = (info ~= nil) and (e.alreadyOn ~= true)
                elseif now > e.start + ENCHANT_EQUIP_WAIT then
                    gcinclude.Err(e.item .. ': never showed up in ' .. string.lower(e.slot) .. ', released')
                    gcinclude.ReleaseEnchant(e.index)
                end
                return
            end
            -- Reuse timer, once the extdata shows this equip (activation changed): the equip happened at
            -- activation - delay, so the item is usable reuse = next use - (activation - delay) seconds after it.
            -- A few seconds past the delay: the first try waits for it. Never refuses: the game says no itself.
            if e.extPending == true then
                local info = enchantInfo(equippedItem(e.index))
                if info == nil then
                    e.extPending = false
                elseif (e.preAct == nil) or (info.activation ~= e.preAct) then
                    e.extPending = false
                    local reuse = info.nextUse - (info.activation - e.delay)
                    if (reuse > e.delay) and (reuse <= e.delay + 5) then
                        e.nextTry = math.max(e.nextTry, e.equippedAt + reuse + ENCHANT_MARGIN)
                    end
                elseif now > e.equippedAt + 2 then
                    e.extPending = false
                end
            end
            if now < e.nextTry then return end
            if gState.PlayerAction ~= nil then
                e.nextTry = now + 0.5
                return
            end -- an action is running: wait, don't spend a try
            if e.tries >= ENCHANT_TRIES then
                gcinclude.Err(e.item .. ': not used after ' .. e.tries .. ' tries, released')
                gcinclude.ReleaseEnchant(e.index)
                return
            end
            e.tries = e.tries + 1
            e.nextTry = now + ENCHANT_RETRY
            AshitaCore:GetChatManager():QueueCommand(-1, '/item "' .. e.item .. '" <me>')
        end

        function gcinclude.CheckEnchantHold()
            if next(gcinclude.Enchants) == nil then return end
            local now = os.clock()
            for _, e in pairs(gcinclude.Enchants) do
                enchant_step(e, now)
            end
        end

        function gcinclude.OnItemAction(cmd, id)
            local now = os.clock()
            for _, e in pairs(gcinclude.Enchants) do
                if (e.doneAt == nil) and (e.equippedAt ~= nil) then
                    if (cmd == 5) and (id == e.id) then
                        e.doneAt = now + 0.5
                    elseif (cmd == 9) and (id == e.id) then
                        e.nextTry = now + ENCHANT_USE_WAIT
                    elseif (cmd == 9) and (id == 0) and (e.nextTry > now + ENCHANT_RETRY) then
                        e.nextTry = now + ENCHANT_RETRY -- an item use was interrupted: try again soon
                    end
                end
            end
        end

        function gcinclude.EnchantDelay(name, res)
            local override = gcinclude.settings.EnchantDelays[name]
            if override == nil then
                for key, value in pairs(gcinclude.settings.EnchantDelays) do
                    if string.lower(key) == string.lower(name) then
                        override = value
                        break
                    end
                end
            end
            if tonumber(override) ~= nil then return tonumber(override), 'setting' end
            local delay = (res ~= nil) and tonumber(res.CastDelay) or nil
            if (delay ~= nil) and (delay > 0) and (delay <= 600) then return delay, 'item' end
            return (gcinclude.settings.EnchantWindow or 12), 'default'
        end

        function gcinclude.UseEnchanted(name, slot, allowOwner)
            local res = AshitaCore:GetResourceManager():GetItemByName(name, 0)
            if res == nil then
                gcinclude.Err('no such item: ' .. name)
                return false
            end
            if slot == nil then
                local slots = gcinclude.EnchantSlots
                    or T{
                        'Ring1',
                        'Ring2',
                        'Neck',
                        'Waist',
                        'Back',
                        'Ear1',
                        'Ear2',
                        'Head',
                        'Body',
                        'Hands',
                        'Legs',
                        'Feet',
                        'Ammo',
                    }
                for _, candidate in ipairs(slots) do
                    if bit.band(res.Slots, gcinclude.SlotBits[candidate] or 0) ~= 0 then
                        slot = candidate
                        break
                    end
                end
            end
            if slot == nil then
                gcinclude.Err(name .. ' has no slot to wear')
                return false
            end
            local delay, source = gcinclude.EnchantDelay(name, res)
            local index = slotOf(slot)
            gcinclude.ReleaseEnchant(index) -- a new /gce on the same slot replaces the old one
            -- Already in the slot: using it swaps nothing, so another owner's lock doesn't matter. Else /hoxne use may
            -- use Hoxne's own lock, never your /lock or another feature's.
            if (equippedId(index) ~= res.Id) and gcinclude.LockedByOther(index, allowOwner) then
                gcinclude.Err(
                    slot .. ' is locked - ' .. table.concat(gcinclude.LockHolders(index, allowOwner), ', ') .. ' first'
                )
                return false
            end
            gFunc.ForceEquipSet({ [slot] = name }) -- slot is free or owned by the caller
            gcinclude.LockSlots(T{ index }, 'enchant')
            local alreadyOn = (equippedId(index) == res.Id) -- worn already: its delay may be long past
            local before = enchantInfo(carriedId(res.Id)) -- extdata before this equip, to see when it refreshes
            gcinclude.Enchants[index] = {
                item = name,
                id = res.Id,
                slot = slot,
                index = index,
                alreadyOn = alreadyOn,
                preAct = (before ~= nil) and before.activation or nil,
                delay = delay,
                start = os.clock(),
                tries = 0,
            }
            gcinclude.Say(
                name
                    .. ' on '
                    .. string.lower(slot) .. ', using it ' .. tostring(delay) .. 's after it is on (' .. source .. ')'
            )
            return true
        end

        function gcinclude.EnchantCommand(args)
            local words = T{}
            for i = 2, #args do
                words:append(args[i])
            end
            if #words == 0 then
                gcinclude.Say('usage: /gce Warp Ring')
                return
            end
            if (#words == 1) and (string.lower(words[1]) == 'cancel') then
                local n = 0
                for index, _ in pairs(gcinclude.Enchants) do
                    gcinclude.ReleaseEnchant(index)
                    n = n + 1
                end
                gcinclude.Say('gce: ' .. ((n > 0) and 'cancelled' or 'nothing running'))
                return
            end
            local name = table.concat(words, ' ')
            gcinclude.UseEnchanted(name, nil)
        end
        gcinclude.EquippedId = equippedId
        return { TrackSlots = trackSlots, EquippedId = equippedId }
    end

    runtime.Enchants = enchants
end

-- == Config ==
do
    -- Per-character preferences. Shared-code updates never write this file.
    local config = {}

    local TEMPLATE = [[-- char.lua (singular): preferences shared by every job on this character.
-- Run /gcconfig to find the exact folder, or /gcconfig init to create this file.
-- Ashita: config/addons/luashitacast/<CharacterName>_<CharacterId>/char.lua
-- Keep this file outside common/ when updating. Reload the job after editing.
-- Settings for every character: goomswap-shared.lua (same layout); this file wins. /gcedit Settings edits both.
--
-- Existing char.lua? Merge your choices into its existing tables. Keep ONE
-- return table and ONE settings table; do not paste a second return at the end.
-- The examples below are commented out to preserve your current defaults.
-- Remove the leading -- from a setting you want to use, then edit its value.
return {
    settings = {
        -- Put HUD owners and keybinds HERE, inside settings.
        -- Use the same main's name in each box's char.lua.
        -- HUDOwners = { 'YourMain' }, -- replace YourMain with the actual name
        -- Keybinds = {},             -- disable all GoomSwap keybinds
        -- EditorBackupKeep = 10,     -- newest editor backups per job file; 0 = keep all
        -- EditorGroups = { 'Weapons', 'Idle' }, -- /gcedit heading order; its right-click menus write this

        -- For custom binds, use this INSTEAD of Keybinds = {} above.
        -- This list replaces the default bindings; it does not add to them.
        -- Keybinds = { { 'F7', 'wm' }, { 'F9', 'mset' } },
    },

    -- Optional supplies belong OUTSIDE settings, alongside it: /lac gear (Packer plugin) fetches them on every job.
    -- Uncomment the whole block you want. A count, 'stack' or 'all'.
    -- Packer = {
    --     ['Echo Drops'] = 'stack',
    --     ['Holy Water'] = 'stack',
    -- },

    -- Optional common fallback sets (not your job's gear table).
    -- sets = {
    --     Doomed = { Ring1 = 'Purity Ring', Waist = 'Gishdubar Sash' },
    -- },
}
-- A later job-specific setting still wins over the same character setting.
]]

    function config.Path()
        if gState and gState.PlayerName and gState.PlayerId then
            return string.format('%sconfig\\addons\\luashitacast\\%s_%u\\char.lua',
                AshitaCore:GetInstallPath(), gState.PlayerName, gState.PlayerId)
        end
        local path = gProfile and gProfile.FilePath
        local folder = type(path) == 'string' and path:match('^(.*[\\/])')
        if folder then return folder .. 'char.lua' end
    end

    -- Settings every character uses under its own char.lua (same layout: settings, Packer, sets).
    function config.SharedPath()
        return AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\goomswap-shared.lua'
    end

    local function exists(path)
        if not path then return false end
        return ashita.fs.exists(path)
    end

    -- The file's table as config.Apply takes it: true, or nil and why not (the editor checks before it writes).
    function config.Check(values)
        if type(values) ~= 'table' then return nil, 'must return a table' end
        if values.settings ~= nil and type(values.settings) ~= 'table' then return nil, 'settings must be a table' end
        if values.sets ~= nil and type(values.sets) ~= 'table' then return nil, 'sets must be a table' end
        local personal = values.settings or {}
        for _, name in ipairs({ 'HUDOwners', 'Keybinds' }) do
            if personal[name] ~= nil and personal[name] ~= false and type(personal[name]) ~= 'table' then
                return nil, name .. ' must be a table or false'
            end
        end
        for _, owner in ipairs(personal.HUDOwners or {}) do
            if type(owner) ~= 'string' then return nil, 'HUDOwners must contain character names' end
        end
        for name, set in pairs(values.sets or {}) do
            if type(set) ~= 'table' then return nil, 'set ' .. tostring(name) .. ' must be a table' end
        end
        return true
    end

    function config.Apply(engine, values)
        local ok, err = config.Check(values)
        if not ok then return nil, err end
        if values.Packer ~= nil then engine.CharPacker = values.Packer end -- char.lua's replaces the shared one
        for key, value in pairs(values.settings or {}) do
            local d = engine.settings[key] -- a T{} default: a plain { ... } gets its methods (HoldExempt:contains)
            if (type(value) == 'table') and (type(d) == 'table') and (getmetatable(value) == nil) then
                setmetatable(value, getmetatable(d))
            end
            engine.settings[key] = value
        end
        for name, set in pairs(values.sets or {}) do engine.sets[name] = set end
        return true
    end

    -- Refuses an existing file, even one whose contents cannot be read as Lua (exists/write are passed in).
    function config.Create(path, fileExists, write)
        if not path then return nil, 'character folder is unavailable' end
        if fileExists(path) then return nil, 'exists' end
        return write(path, TEMPLATE)
    end

    function config.Command(engine, action)
        action = action and string.lower(tostring(action))
        local path = config.Path()
        if not path then engine.Err('Character folder is unavailable. Load a job first.'); return end
        if action == 'init' then
            local writer = gFunc.LoadFile('common\\gcsetfile.lua')
            local ok, err = config.Create(path, exists, writer.Write)
            if ok then engine.Say('Created ' .. path)
            elseif err == 'exists' then engine.Say('Kept existing ' .. path)
            else engine.Err('Could not create char.lua: ' .. tostring(err)); return end
        elseif action ~= nil and action ~= '' then
            engine.Err('Use /gcconfig to show the path, or /gcconfig init to create a template.'); return
        end
        engine.Say('Character config: ' .. path)
        engine.Say('Shared by every character: ' .. config.SharedPath()
            .. (exists(config.SharedPath()) and '' or ' (none yet; /gcedit Settings makes it)'))
        local owners = engine.settings.HUDOwners
        local binds = engine.settings.Keybinds
        engine.Say('Effective HUDOwners: ' .. (type(owners) == 'table' and #owners > 0
            and table.concat(owners, ', ') or '(none)') .. '; GoomSwap keybinds: '
            .. (type(binds) == 'table' and #binds or 0))
        engine.Say(exists(path) and 'Edit its settings table (or /gcedit Settings), then reload the job. char.lua wins over the shared file; job files win over both.'
            or 'Run /gcconfig init to create it. Put personal preferences here, outside common/.')
    end

    -- The defaults, then goomswap-shared.lua (every character), then char.lua (this one). The editor reads each layer
    -- (SharedConfig, CharConfig) and the defaults (DefaultSettings) to show where a value comes from.
    function config.Install(engine)
        engine.ConfigCommand = function(action) return config.Command(engine, action) end
        engine.CharConfigPath, engine.CharConfigTemplate = config.Path, TEMPLATE -- /gcedit writes settings there
        engine.SharedConfigPath, engine.CheckConfig = config.SharedPath, config.Check
        engine.DefaultSettings = {}
        for k, v in pairs(engine.settings) do engine.DefaultSettings[k] = v end
        engine.CharPacker, engine.SharedConfig, engine.CharConfig = nil, nil, nil
        for _, layer in ipairs({ { 'SharedConfig', config.SharedPath(), 'goomswap-shared.lua' },
            { 'CharConfig', config.Path(), 'char.lua' } }) do
            if exists(layer[2]) then
                local ok, values = pcall(gFunc.LoadFile, layer[2])
                local applied, err
                if ok then applied, err = config.Apply(engine, values) else err = values end
                if applied then engine[layer[1]] = values else engine.Err(layer[3] .. ': ' .. tostring(err)) end
            end
        end
    end

    runtime.Config = config
end

-- == Packet/automatic-gear state: create at the original lifecycle point. ==
function runtime.NewAuto()
    local gcauto = {}

    local inc = nil
    local nextTick = 0
    local rolls = {}
    local rollAbilities = nil
    local rollEleven = false
    local ROLL_STALE = 660
    local ROLL_RECAST = 193

    -- How many of an item (by name) in Inventory and Temporary items.
    function gcauto.ItemCount(name)
        local res = AshitaCore:GetResourceManager():GetItemByName(name, 0)
        return (res ~= nil) and (inc.CountItem(res.Id, { 0, 3 })) or 0
    end

    -- TH tags: a mob my melee (1), ranged (2), WS (3), spell (4), ability (6), step/flourish (14) or
    -- Effusion (15) hit (XiPackets 0x0028 cmd_no). Spells, steps and Effusions count only when they land.
    -- Dropped at 0 HP (a respawn with the same id gets TH again) and on zone.
    local tagged = {}
    -- Messages for a spell or ability that didn't land (Windower Resources action_messages): resisted
    -- 85 284 653-656, no effect 75 114 156 283 323 423 659, missed 158 324 658, out of range / too far /
    -- can't see 4 78 154 198 217 219 313 328.
    local NOLAND = { [4]=true, [75]=true, [78]=true, [85]=true, [114]=true, [154]=true, [156]=true, [158]=true,
        [198]=true, [217]=true, [219]=true, [283]=true, [284]=true, [313]=true, [323]=true, [324]=true,
        [328]=true, [423]=true, [653]=true, [654]=true, [655]=true, [656]=true, [658]=true, [659]=true }
    local TAGCAT = { [1]='any', [2]='any', [3]='any', [4]='landed', [6]='any', [14]='landed', [15]='landed' }
    local function prune_tags()
        if (next(tagged) == nil) then return end
        local ent = AshitaCore:GetMemoryManager():GetEntity()
        for id in pairs(tagged) do
            local idx = bit.band(id, 0x7FF)
            if (ent:GetServerId(idx) == id) and ((ent:GetHPPercent(idx) or 0) == 0) then tagged[id] = nil end
        end
    end

    -- Reads the bit-packed 0x0028 action packet once, layout per atom0s' XiPackets notes.
    -- Bits are LSB-first; one parse feeds the roll, combat and burst readers.
    local band, rshift = bit.band, bit.rshift
    local POW2 = {}
    for i = 0, 32 do POW2[i] = 2 ^ i end
    local pdata, ppos, pbit = nil, 0, 0
    local function rd(n)
        local value, got = 0, 0
        while (got < n) do
            local byte = string.byte(pdata, ppos) or 0
            local take = 8 - pbit
            if (take > (n - got)) then take = n - got end
            value = value + band(rshift(byte, pbit), POW2[take] - 1) * POW2[got]
            got = got + take
            pbit = pbit + take
            if (pbit >= 8) then pbit = 0; ppos = ppos + 1 end
        end
        return value
    end

    local A = { tgt = {}, nres = {}, first = {}, rmiss = {}, rval = {}, rmsg = {}, rkind = {} }
    local function parse_action(data)
        -- Lua index 6 = byte 0x05: skip the 4-byte header and the size byte (XiPackets 0x0028 Reversing.md;
        -- LAC reads the actor at e.data 0x05 + 1).
        pdata, ppos, pbit = data, 6, 0
        A.actor = rd(32)
        A.ntgt = rd(6)
        rd(4)
        A.cat = rd(4)
        A.param = rd(32)
        rd(32)
        local k = 0
        for t = 1, A.ntgt do
            A.tgt[t] = rd(32)
            local results = rd(4)
            A.nres[t] = results
            A.first[t] = k + 1
            for _ = 1, results do
                k = k + 1
                A.rmiss[k] = rd(3) -- XiPackets: 0 hit, 1 miss, 2 guard, 3 parry, 4 block
                rd(2); rd(12); rd(5); rd(5)
                A.rval[k] = rd(17)
                A.rmsg[k] = rd(10)
                rd(31)
                if (rd(1) == 1) then A.rkind[k] = rd(6); rd(4); rd(17); rd(10) else A.rkind[k] = false end
                if (rd(1) == 1) then rd(6); rd(4); rd(14); rd(10) end
            end
        end
        pdata = nil
        local party = AshitaCore:GetMemoryManager():GetParty()
        A.me = party and party:GetMemberServerId(0) -- my server id, read once for every handler
        return A
    end

    -- Buffs counted early: a result on me whose message names its status (Windower res action_messages:
    -- "gains/receives the effect of ${status}", the result's param = the buff id) counts as up for 2s, until the buff
    -- list has it. gcinclude.BuffCount reads gcauto.Predicted.
    local GAIN_MSG = { [166] = true, [186] = true, [194] = true, [205] = true, [230] = true, [237] = true, [243] = true,
        [266] = true, [267] = true, [268] = true, [269] = true, [278] = true, [280] = true, [319] = true, [320] = true,
        [375] = true, [412] = true, [755] = true, [804] = true }
    local PREDICT_FOR = 2.0
    local predicted = {} -- buff id -> until (os.clock)
    local function predict_packet(P)
        if (P.me == nil) then return end
        for t = 1, P.ntgt do
            if (P.tgt[t] == P.me) then
                for k = P.first[t], P.first[t] + P.nres[t] - 1 do
                    if GAIN_MSG[P.rmsg[k]] then predicted[P.rval[k]] = os.clock() + PREDICT_FOR end
                end
            end
        end
    end

    function gcauto.Predicted(id)
        local untilT = predicted[id]
        if (untilT == nil) then return false end
        if (os.clock() > untilT) then predicted[id] = nil; return false end
        return true
    end

    local function roll_abilities()
        if (rollAbilities ~= nil) then return rollAbilities end
        rollAbilities = {}
        local res = AshitaCore:GetResourceManager()
        for id = 0x200, 0x200 + 0x3FF do
            local ability = res:GetAbilityById(id)
            if (ability ~= nil) and (ability.RecastTimerId == ROLL_RECAST) then
                -- Ashita job ability resource id = packet id + 0x200 (LAC packethandlers / data.lua).
                rollAbilities[id - 0x200] = ability.Name[1]
            end
        end
        return rollAbilities
    end

    -- Combat window, Selindrile-style: a monster hits me or a party/alliance member
    -- (melee, ranged, monster skill), or I act on a monster. Expires after CombatWindow.
    local lastCombat = -1e9
    local monsterCache = {}

    -- Monster: spawn flag 0x10 set, 0x01 (player) clear. Covers LAC's exact 16 = Monster.
    local function monster_flags(sf)
        sf = sf or 0
        return (bit.band(sf, 0x10) ~= 0) and (bit.band(sf, 0x01) == 0)
    end

    -- Zone entities sit at index = id & 0x7FF (LAC packethandlers does the same); others (players,
    -- pets, trusts) are found by scanning the whole array (0..0x8FF, as LAC does). nil if not loaded.
    local function entity_index(id)
        if (id == nil) or (id == 0) then return nil end
        local entity = AshitaCore:GetMemoryManager():GetEntity()
        local idx = bit.band(id, 0x7FF)
        if (entity:GetServerId(idx) == id) then return idx end
        for i = 0, 0x8FF do
            if (entity:GetServerId(i) == id) then return i end
        end
        return nil
    end

    local function is_monster(id)
        if (id == nil) or (id == 0) then return false end
        local hit = monsterCache[id]
        if (hit ~= nil) then return hit end
        local idx = entity_index(id)
        if (idx == nil) then return false end -- not loaded yet: don't cache
        local found = monster_flags(AshitaCore:GetMemoryManager():GetEntity():GetSpawnFlags(idx))
        monsterCache[id] = found
        return found
    end

    local function in_party(id)
        local party = AshitaCore:GetMemoryManager():GetParty()
        if (party == nil) then return false end
        for i = 0, 5 do
            if (party:GetMemberIsActive(i) == 1) and (party:GetMemberServerId(i) == id) then return true end
        end
        return false
    end

    local function is_ally(id)
        local party = AshitaCore:GetMemoryManager():GetParty()
        if (party == nil) then return false end
        for i = 0, 17 do
            if (party:GetMemberIsActive(i) == 1) and (party:GetMemberServerId(i) == id) then return true end
        end
        return false
    end

    local function combat_packet(P)
        local me = P.me
        if (me == nil) then return end
        local category = P.cat
        local hostile = ((category == 1) or (category == 2) or (category == 11)) and is_monster(P.actor)
        local mine = (P.actor == me) and ((category == 1) or (category == 2) or (category == 3) or (category == 4)
            or (category == 6))
        if (not hostile) and (not mine) then return end
        for t = 1, P.ntgt do
            local target = P.tgt[t]
            if (hostile and is_ally(target)) or (mine and is_monster(target)) then
                lastCombat = os.clock()
                return
            end
        end
    end

    -- Learned cast time, so no job needs gSettings.FastCast. XiPackets 0x0028: cmd_no 8 = Magic (Start),
    -- cmd_arg low 16 bits 'ca' (24931) = start, 'sp' (28787) = interrupt; cmd_no 4 = Magic (Finish), cmd_arg = spell
    -- id.
    -- Finish minus start is the real cast time (FC, Quick Cast, Celerity, cast-time gear, latency).
    -- Per skill keep the last 5 ratios to base cast time and use the slowest, so a Quick Cast/Celerity cast
    -- never makes a burst look like it will land when a normal cast would not.
    local castStart = nil -- { id, t }
    local castRatio = {} -- [skill] = { ratios }

    local function cast_packet(P)
        local cat = P.cat
        if (cat ~= 8) and (cat ~= 4) then return end
        local me = P.me
        if (me == nil) or (P.actor ~= me) then return end
        gcauto.LastCastPacket = os.clock() -- my spell started, was interrupted or finished: gcinclude.CastLeft
        if (cat == 8) then
            local id = (P.ntgt > 0) and (P.nres[1] > 0) and P.rval[P.first[1]] or nil
            castStart = (bit.band(P.param, 0xFFFF) == 24931) and (id ~= nil) and { id = id, t = os.clock() } or nil
            -- LAC ends the pending spell at send + base cast + SpellOffset, then put idle
            -- gear on even if it hasn't landed (lag). It has started: keep it pending until base cast + SpellOffset
            -- from now; the finish or interrupt packet still ends it at once.
            local a = (gState ~= nil) and gState.PlayerAction or nil
            local res = (castStart ~= nil) and AshitaCore:GetResourceManager():GetSpellById(id) or nil
            if (a ~= nil) and (a.Type == 'Spell') and (a.Resource ~= nil) and (a.Resource.Index == id)
                and (res ~= nil) then
                local offset = ((gSettings ~= nil) and tonumber(gSettings.SpellOffset)) or 1
                a.Completion = math.max(a.Completion or 0, os.clock() + (res.CastTime or 0) / 4 + offset)
            end
            return
        end
        local s = castStart
        castStart = nil
        if (s == nil) or (s.id ~= P.param) then return end
        local res = AshitaCore:GetResourceManager():GetSpellById(s.id)
        if (res == nil) or (res.CastTime == nil) or (res.CastTime <= 0) then return end
        local ratio = (os.clock() - s.t) / (res.CastTime / 4)
        if (ratio < 0.05) or (ratio > 1.5) then return end
        local list = castRatio[res.Skill] or {}
        table.insert(list, ratio)
        if (#list > 5) then table.remove(list, 1) end
        castRatio[res.Skill] = list
    end

    gcauto.LastCastPacket = -1e9 -- when the last start / interrupt / finish packet of a spell of mine came in

    -- Seconds left on my cast in progress, and its spell id: its start packet was seen and no finish or
    -- interrupt yet. 0 when not casting. Past its learned cast time it stays at 0.1 for up to 2s (the finish
    -- packet is on its way), then the cast is taken as over (a missed packet).
    function gcauto.CastLeft()
        local s = castStart
        if (s == nil) then return 0 end
        local left = s.t + gcauto.CastTime(AshitaCore:GetResourceManager():GetSpellById(s.id)) - os.clock()
        if (left < -2) then castStart = nil; return 0 end
        return math.max(left, 0.1), s.id
    end

    -- Seconds a spell resource takes to cast now: learned for its skill, else base less gSettings.FastCast.
    function gcauto.CastTime(res)
        if (res == nil) or (res.CastTime == nil) then return 0 end
        local base = res.CastTime / 4
        local list = castRatio[res.Skill]
        if (list ~= nil) and (#list > 0) then return base * math.max(unpack(list)), true end
        local fc = math.min(math.max(tonumber(gSettings.FastCast) or 0, 0), 80)
        return base * (1 - fc / 100), false
    end

    -- Magic burst, ported from sync (sync_packethandler H028.sc + geo_mod.mb.tick).
    -- Chain property = the result's proc kind (6 bits, 1..16 -> scdata.PROPNUM; LSB ActionProcSkillChain),
    -- counted when the action is in scdata.BYCAT for its category (4 spell, 13 pet, 14); any WS chain counts.
    -- Window: settings.MBWindow seconds (BG: 10) from the chain packet; another WS on the mob ends it.
    -- A burst is cast only if its cast time (gcauto.CastTime) lands it inside the window.
    local scdata = nil
    pcall(function() scdata = gFunc.LoadFile('common\\scdata.lua') end)

    local MBELEM = {
        Liquefaction = { 'Fire' }, Induration = { 'Ice' }, Detonation = { 'Wind' }, Scission = { 'Earth' },
        Impaction = { 'Thunder' }, Reverberation = { 'Water' }, Transfixion = { 'Light' }, Compression = { 'Dark' },
        Fusion = { 'Fire', 'Light' }, Fragmentation = { 'Wind', 'Thunder' }, Distortion = { 'Ice', 'Water' },
        Gravitation = { 'Earth', 'Dark' },
        Light = { 'Fire', 'Wind', 'Thunder', 'Light' }, Darkness = { 'Ice', 'Earth', 'Water', 'Dark' },
        Radiance = { 'Fire', 'Wind', 'Thunder', 'Light' }, Umbra = { 'Ice', 'Earth', 'Water', 'Dark' },
    }
    local mbres = {} -- [mob server id] = { props, ts, dur, step }

    local function mb_packet(P)
        if (scdata == nil) then return end
        local now = os.clock()
        for t = 1, P.ntgt do
            local target = P.tgt[t]
            local prop, msg = nil, nil
            if (P.nres[t] > 0) then
                local k = P.first[t]
                msg = P.rmsg[k]
                if (P.rkind[k] ~= false) then prop = scdata.PROPNUM[bit.band(P.rkind[k], 0x3F)] end
            end
            local cat = P.cat
            if (msg ~= nil) and scdata.PETMSG[msg] then cat = 13 end
            local tbl = scdata.BYCAT[cat]
            local act = tbl and tbl[bit.band(P.param, 0xFFFF)]
            local chained = (prop ~= nil) -- every PROPNUM value is a skillchain property
            -- XiPackets documents proc_kind as the skillchain id for weapon skills (cmd 3), so a WS chain
            -- counts even when the WS is missing from scdata; other categories still need their table entry.
            if chained and ((act ~= nil) or (cat == 3)) and is_monster(target) then
                local old = mbres[target]
                if (old ~= nil) and (now > old.ts + old.dur) then old = nil end
                local step = ((old ~= nil) and old.step or 1) + 1
                mbres[target] = { props = { prop }, ts = now, dur = inc.settings.MBWindow or 10, step = step }
            elseif (cat == 3) and (not chained) and (mbres[target] ~= nil) then
                -- BG: any further weapon skill on the target ends the magic burst window.
                mbres[target] = nil
            end
        end
    end

    local function live_res(targetId, now)
        local r = mbres[targetId]
        if (r == nil) then return nil end
        if (now > r.ts + r.dur) then mbres[targetId] = nil; return nil end
        return r
    end

    -- Burst gear: the spell's element fits the chain and it lands inside dur.
    function gcauto.BurstLive(targetId, element, landsAt)
        if (targetId == nil) then return false end
        local now = os.clock()
        local r = live_res(targetId, now)
        if (r == nil) then return false end
        for _, pr in ipairs(r.props) do
            for _, el in ipairs(MBELEM[pr] or {}) do
                if (el == element) then return ((landsAt or now) <= r.ts + r.dur) end
            end
        end
        return false
    end

    function gcauto.InCombat()
        local window = (inc ~= nil) and inc.settings.CombatWindow or 6
        return (os.clock() - lastCombat) <= window
    end

    local function roll_recompute()
        local now, eleven = os.clock(), false
        for id, entry in pairs(rolls) do
            if ((now - entry.at) > ROLL_STALE) then
                rolls[id] = nil
            elseif (entry.name ~= nil) and (inc ~= nil) and (inc.BuffCount(entry.name) == 0) then
                rolls[id] = nil -- roll folded, overwritten or worn off
            elseif (entry.total == 11) then
                eleven = true
            end
        end
        rollEleven = eleven
    end

    -- Area spells (gcinclude.AoeOnCaster, AoeOnTarget, AoeRange): their start packet may name only one target, so a
    -- party member's cast is also checked by my distance from its center.
    local function incoming_cast(P)
        local actor, me = P.actor, P.me
        if (me == nil) or (actor == me) or (gcauto.OnIncomingCast == nil) then return end
        if (bit.band(P.param, 0xFFFF) ~= 24931) then return end -- 'ca' = start; 'sp' (interrupt) ends it below
        for t = 1, P.ntgt do
            local k = P.first[t]
            for r = k, k + P.nres[t] - 1 do
                local spell = AshitaCore:GetResourceManager():GetSpellById(P.rval[r])
                if (spell ~= nil) and (spell.Name ~= nil) then
                    local name = spell.Name[1]
                    local hit = (P.tgt[t] == me)
                    if (not hit) and (inc ~= nil) and in_party(actor) then
                        local fam = string.gsub(string.lower(name), ' [ivx]+$', '')
                        local center = (inc.AoeOnCaster:contains(fam) and actor) or (inc.AoeOnTarget:contains(fam)
                            and P.tgt[t]) or nil
                        local idx = (center ~= nil) and entity_index(center) or nil
                        hit = (idx ~= nil) and (math.sqrt(AshitaCore:GetMemoryManager():GetEntity():GetDistance(idx)
                            or 0) <= inc.AoeRange)
                    end
                    if hit then gcauto.OnIncomingCast(name, actor); return end
                end
            end
        end
    end

    -- Someone else's spell finished (cmd_no 4) or was interrupted (cmd_no 8, 'sp'): received gear can come off.
    local function incoming_end(P)
        if (gcauto.OnReceivedEnd == nil) or (P.me == nil) or (P.actor == P.me) then return end
        if (P.cat == 4) then
            local hitMe = false
            for t = 1, P.ntgt do
                if (P.tgt[t] == P.me) then hitMe = true end
            end
            gcauto.OnReceivedEnd(P.actor, hitMe)
        elseif (P.cat == 8) and (bit.band(P.param, 0xFFFF) == 28787) then
            gcauto.OnReceivedEnd(P.actor, false)
        end
    end

    local function roll_packet(P)
        local actor, category, param, me = P.actor, P.cat, P.param, P.me
        -- Magic (Start): handled by incoming_cast.
        if (category == 8) then return end
        local tagcat = TAGCAT[category]
        -- A THSkip spell (Absorb-TP, Stun) is cast without the TH set, so it doesn't count as the tag.
        -- only my casts tag
        if (tagcat ~= nil) and (category == 4) and (actor == me) and (inc ~= nil) and (inc.Skipped ~= nil) then
            local res = AshitaCore:GetResourceManager():GetSpellById(param)
            if (res ~= nil) and (res.Name ~= nil) and inc.Skipped('THSkip', res.Name[1]) then tagcat = nil end
        end
        if (tagcat ~= nil) then
            if (me ~= nil) and (actor == me) then
                for t = 1, P.ntgt do
                    local k = P.first[t]
                    local ok = (tagcat == 'any') or ((P.nres[t] > 0) and (P.rmiss[k] == 0) and (not NOLAND[P.rmsg[k]]))
                    if ok and is_monster(P.tgt[t]) then tagged[P.tgt[t]] = true end
                end
                -- category 6 falls through: your own Phantom Roll / Double-Up is also a roll packet.
                if (category ~= 6) then return end
            end
        end
        local rollName = (category == 6) and roll_abilities()[param] or nil
        if (rollName == nil) or (me == nil) then return end
        for t = 1, P.ntgt do
            if (P.tgt[t] == me) then
                local k = P.first[t]
                for r = k, k + P.nres[t] - 1 do
                    local value = P.rval[r]
                    if (value >= 1) and (value <= 11) then
                        rolls[param] = { total = value, at = os.clock(), name = rollName }
                    end
                end
            end
        end
        roll_recompute()
    end

    -- Only an 11 can be dropped by a recompute here; roll_packet recomputes after every roll.
    function gcauto.RollEleven()
        if rollEleven then roll_recompute() end
        return rollEleven
    end

    function gcauto.IsTagged(id)
        return (id ~= nil) and (tagged[id] == true)
    end

    function gcauto.ClearTags()
        tagged = {}
    end

    function gcauto.RollReset()
        rolls = {}
        rollEleven = false
    end

    function gcauto.Bind(gcinclude)
        inc = gcinclude
    end

    -- My item use started / was interrupted (cmd_no 9, result value = item id, 0 if interrupted) or finished
    -- (cmd_no 5, cmd_arg = item id), XiPackets 0x0028: tells gcinclude's enchanted-item use.
    local function item_packet(P)
        if ((P.cat ~= 5) and (P.cat ~= 9)) or (P.me == nil) or (P.actor ~= P.me) then return end
        if (inc == nil) or (inc.OnItemAction == nil) then return end
        local id = P.param
        if (P.cat == 9) then id = ((P.ntgt > 0) and (P.nres[1] > 0)) and P.rval[P.first[1]] or 0 end
        inc.OnItemAction(P.cat, id)
    end

    -- My spell refused before it started (0x0029 caster 0x04, MessageNum 0x18, XiPackets; texts from Windower
    -- Resources action_messages): 17/18 unable to cast at this time, 34 not enough MP, 40 not in this area,
    -- 47 cannot cast, 48 cannot be cast on target, 49 unable to cast, 313 out of range.
    local SPELL_REFUSED = { [17] = true, [18] = true, [34] = true, [40] = true, [47] = true, [48] = true,
        [49] = true, [313] = true }
    local function refused_packet(data)
        if (inc == nil) then return end
        local msg = struct.unpack('H', data, 0x18 + 1)
        -- 39: "You need the Dual Wield ability to equip the ${item} as a sub-weapon." (Data 0x0C = the item)
        if (msg == 39) then
            if (inc.OnSubRefused ~= nil) then inc.OnSubRefused(struct.unpack('L', data, 0x0C + 1)) end
            return
        end
        if (inc.OnSpellRefused == nil) or not SPELL_REFUSED[msg] then return end
        local party = AshitaCore:GetMemoryManager():GetParty()
        local me = party and party:GetMemberServerId(0)
        if (me == nil) or (struct.unpack('L', data, 0x04 + 1) ~= me) then return end
        inc.OnSpellRefused()
    end

    -- Twice a second: drop TH tags on dead mobs and burst windows that have closed.
    local function tick()
        local now = os.clock()
        if (now < nextTick) then return end
        nextTick = now + 0.5
        prune_tags()
        for id, r in pairs(mbres) do
            if (now > r.ts + r.dur) then mbres[id] = nil end
        end
    end

    gcauto.Tick = tick -- called from gcinclude.Tick (the engine's one per-frame hook)

    function gcauto.Start()
        ashita.events.register('packet_in', 'gcauto_packet', function (e)
            if (e.id == 0x0028) then
                local ok, P = pcall(parse_action, e.data)
                if ok then
                    pcall(roll_packet, P); pcall(combat_packet, P); pcall(cast_packet, P); pcall(mb_packet,
                        P); pcall(item_packet, P); pcall(incoming_cast, P); pcall(incoming_end,
                        P); pcall(predict_packet, P)
                end
            end
            if (e.id == 0x0029) then pcall(refused_packet, e.data) end
            -- LogoutState
            if (e.id == 0x000B) and (inc ~= nil)
                and (inc.OnZoneOut ~= nil) then pcall(function() inc.OnZoneOut(struct.unpack('L', e.data,
                0x04 + 1)) end) end
            if (e.id == 0x000A) and (inc ~= nil) and (inc.OnZone ~= nil) then pcall(inc.OnZone) end
            if (e.id == 0x000A) then
                predicted = {}; gcauto.RollReset(); gcauto.ClearTags(); lastCombat = -1e9; monsterCache = {}; mbres = {}
            end
        end)
    end

    function gcauto.Stop()
        ashita.events.unregister('packet_in', 'gcauto_packet')
    end

    return gcauto
end

return runtime
