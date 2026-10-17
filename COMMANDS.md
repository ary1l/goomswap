# GoomSwap commands

Commands are plain `/name` (Windower `//name` or `//gs c name`). Other boxes through Multisend: `/mss /wm default`
(all), `/ms sendto <name> /wm 3` (one), or your own Multisend shortcuts. Windower: `//send @all gs c wm default`.

- On/off commands (`/dt`, `/th`, `/sir`, `/kite`, `/automb`, `/autofood`…) take `on`/`off`; no word flips.
- Cycle commands (`/mset`, `/nukeset`, `/tankset`, `/weapon`, `/elecycle`, `/pupmode`): no word cycles; a word picks
  by name, start or number, any case (`/mset hybrid`, `/mset d`, `/tankset meva`). `/setcycle <name> <value>` sets any.
- Windower: `profile.Packer` goes to `//gs org` (Organizer addon).
- Zoning turns off `/autofood`, `/autosoda`, `/hoxne`. While zoning (zone-line reply until 3s after arriving) nothing
  is sent by itself: no item uses, queued actions, food/soda or auto-casts.

## Weapons

| Command | Does |
|---|---|
| `/wm` | Next weapon mode (`/weaponset` same) |
| `/wm savage` / `/wm 3` | By name (exact, prefix, substring) / position (1 = None) |
| `/wm none` | Stop managing weapons (`TH`-set weapons still apply while `/th` is on) |
| `/wm default` / `/wm melee` | This job's `DefaultWeapons` / a role from `gcinclude.WeaponRoles` |
| `/wm leaden force` | Swap even at 1000+ TP |
| `/mainset` `/subset` `/rangeset` `/ammoset` `[name\|N\|none]` | Per-slot cycles (jobs that define them), e.g. PLD `/subset`: None → Aegis → Duban. `force` at 1000+ TP |
| `/dw [on\|off\|auto]` | Dual Wield: no word shows yes/no and why; `off` = always `_1h` sets, `on` = always DW, `auto` = detect |
| `/smartswap [on\|off]` | At `SmartSwapTP`+: `NoWeaponSpells` (Dia, Blink, spikes…) don't swap weapons; `KeepWeaponsFor` (Cure/Cura) keep Daybreak or Bunzi's Rod |

- The weapon mode is what you return to at rest; action sets that name weapons still swap them. Per-slot cycles
  override the mode for their slot. COR/RNG modes are named for the gun, so `/mainset` changes the melee weapon.
- `/th` on: Main/Sub/Range in `TH` override mode and cycles the whole time, tagged or not (Sub only if you can dual wield).
- **TP hold:** at 1000+ TP Main/Sub/Range don't change (except songs, rolls, cures, enfeebling, enhancing,
  geomancy). `force` overrides; `WeaponTPGuard = 0` disables. Asleep, slots your `Sleeping` set names are let go.
- `Weapon_<Mode>_1h` when you can't dual wield: NIN Lv10+, DNC Lv20+, THF Lv83+ main or sub at the effective level
  (FFXIclopedia; SJ Restriction / Sheol Gaol sub Lv0 doesn't count). Losing DW puts `_1h` on at once; regaining waits
  for the TP hold. `gcinclude.AlwaysDualWield = true` forces DW (BLU, THF).
- Augmented items in a cycle:
  `gcinclude.WeaponItemMap = { ['Rostam B'] = { Name = 'Rostam', AugPath = 'B' } };` with `'Rostam B'` in `MainModes`.

## Defense, SIR, locks

| Command | Does |
|---|---|
| `/def [off\|dt\|mdt\|aminon]` | One (or none); no word cycles none → DT → MDT → Aminon (Ctrl+Shift+grave) |
| `/dt` `/mdt` | Toggle `Dt` / `mdt` set (idle/engaged) |
| `/aminon` | `Aminon` set (else `mdt`); locks Main/Sub (the set's, else worn) and Range/Ammo if the set names them, until off. Turns `/sir` off |
| `/sir` | `SIR` set last over every spell midcast, not `SIRSkip` (Absorb-TP, Stun + job's own). Refused while Aminon is on; stays off after Aminon |
| `/hoxne` / `/hoxne off` / `/hoxne use` | Off ↔ Locked (Alt+grave) / off / Locked and use it now |
| `/lock` / `/lock ear1 back` | Lock Main, Sub, Ammo / any slots |
| `/unlock` / `/unlock ammo` | Free your locks, all / one. Names what still holds a slot (`/aminon off`, `/hoxne off`…) |
| `/naked` `/weaponsonly` `/abysseaproc` `[on\|off]` | Strip all 16 / 12 armor slots / head, hands, legs, feet, kept bare. One at a time |
| `/capacity` `/jubilee` `/dynamisrp` `[on\|off]` | Wear and hold best carried capacity cape / Jubilee Ring (`JubileeSlot`) / main job's best Dynamis neck |

- Defense toggles only wear idle/engaged gear; `/aminon` also locks weapons. `/lock` holds until `/unlock`, even
  against force-equips.
- Locks have owners (you, Aminon, Hoxne, `/proc`, holds, `/gce`). Turning one off frees only its own slots; `/unlock`
  frees only yours.
- **Hoxne Locked:** ampulla kept in Ammo; Ammo and Range locked (any set's Ammo, or an instrument/bow in Range, would
  knock it off and end Enchantment). Used when in Ammo and Enchantment has been gone 3s (BG-Wiki: Double Attack +100%,
  30 min, 60s recast, 5s use delay, lost when unequipped or zoning). `HoxneAutoUse = false` stops auto use.

## Magic burst (RDM BLM SCH GEO)

| Command | Does |
|---|---|
| `/automb [on\|off]` | Casts into live skillchains by itself (Win+grave; `/autonuke`, `/mbmode` same) |
| `/mbtier [low\|mid\|high]` | Its nuke tier I / III / V (`1\|3\|5` too); no word cycles. HUD: Ctrl+click `mb` |
| `/burst` | Burst set on every nuke, not only live skillchains |
| `/mbinfo` | Last skillchain seen |

- Burst set: automatic. A nuke landing in a live skillchain of its element wears it.
- Tier default: `MBTier = 'Mid'`; per job `gcinclude.MBTier = 'High'` before `Initialize()`. A command's tier lasts
  until reload or job change.
- `/automb` targets a chain on your target or a mob you/your party are engaged on (your target first), cast by id
  (works engaged on another mob; skipped past 21.8'). Casts the chain element's tiered nuke; can't (not learned,
  recast, MP, SCH IV/V without Addendum: Black/Enlightenment) → next tier down (`MBFallback`). Light/Dark-only chains:
  SCH Luminohelix/Noctohelix, others skip. Only if it lands inside `MBWindow` (10s; cast time learned), not moving,
  after your own action delays (3s spell, 2s WS/JA). `MBCasts` per chain, `MBRotate`, `MBMinMP`. Tier V: BLM 86,
  SCH 91, RDM/GEO 100 JP gift. Windower: casts at the mob without targeting it.
- `settings.MBSkills` (Elemental Magic) = skills that count for Burst.

## Action checks

Spells, abilities and WS that would fail are cancelled before any gear moves, reason in chat (`Validate = false` off):

| Check | Result |
|---|---|
| KO, sleep, stun, petrify, terror, charm; Mute; Amnesia (JA/WS) | Cancelled |
| Silence | Cancelled; uses Echo Drops, else Remedy (Remedy first if paralyzed). `AutoRemedy`, not under Muddle |
| Paralysis on an ability | Uses a Remedy instead, if carried |
| Recast | Back within `MiniQueueMax` (5s): queued, else shows `m:ss` |
| While you cast (also before "starts casting" is back) | Spell/JA/WS queued for after the cast + 3s forced delay if within `MiniQueueMax`, else cancelled so your cast keeps its gear. Same spell again: only cancelled. `/item`, `/ra`: cancelled |
| Forced delay (BG-Wiki: 3s spell, 2s WS, 2s JA / 1s JA→JA) | Queued. Same action double-tapped goes out as pressed |
| MP short | Arts-adjusted (own school -10%, other +20%); skipped under Manafont, Manawell, Parsimony, Penury, Addenda, Tabula Rasa. Gear MP cost not counted: `ValidateMP = false` |
| Stratagems at 0 / Waltz short on TP | Cancelled (`WaltzTPCut` = your gear's reduction) |

**Queue** (`MiniQueue = false` off): 3 actions; oldest ready one goes when nothing is running, one at a time; a 4th
drops the oldest; same action again replaces its entry. Each waits expected time + 2s (clock stops while you're busy,
up to 10s more). Targets `<me>`, a player by name, or `<t>` if still your target. Zoning clears it. A refused spell
holds the next press about 1.5s at most. Ready/Sic/Quick Draw and stratagems skip the recast check.

## Automation and items

| Command | Does |
|---|---|
| `/autofood [on\|off]` | Eat when Food is missing (outside town, not moving) |
| `/autosoda [on\|off]` | `SodaItem` when Regain is missing; 20s between tries, off after `ConsumableMaxTries` |
| `/revit [on\|off]` | `AutoUseItems` per zone: `{ Zone = 'Ghoyu', Item = 'Revitalizer' }` |
| `/holywater [on\|off]` | Holy Water on Doom (on by default) |
| `/gce <item>` / `/gce cancel` | Equip enchanted item, lock slot, wait its delay, use / stop all and free slots |
| `/temps` | Carried Escha drinks, 3s apart |
| `/warpring` `/mea` `/holla` `/dem` | Ring2 (past `/lock`), held through its delay, used at 11s, let go at 22s so your normal Ring2 returns (if a set names Ring2). Ring names: `warp_Ring` etc. |
| `/ontic` `/shard` | Ontic Extremity / V. Con. Shard (more: `gcinclude.ExitItems`) |
| `/gcaspir` `/gcdrain` | Best castable tier on `<t>` |

- `/gce`: delay from the item's `CastDelay` (override `EnchantDelays`, fallback `EnchantWindow`), counted once it's
  really on; `/item` retried every 2s, 5 tries; gives up after 10s not on. Not held back for its reuse timer (the game
  decides), but refused if the slot is held by `/lock` or another feature (chat names it).
- Warnings (never cancel): ammo ≤ `AmmoWarn` (20), Utsusemi tools ≤ `NinjaToolWarn` (10); once, every 10 fewer, at 0.
- Asleep under Stoneskin: sends `/cancel Stoneskin` (needs a cancel addon). `SleepCancelStoneskin = false` stops it.

## Other commands

| Command | Does |
|---|---|
| `/mset [value]` (`/meleeset`) | Default → Hybrid → Acc: `Tp_`/`Ws_Hybrid` or `_Acc` over `_Default`, `<Name>_Hybrid` over a named set |
| `/kite` / `/th` | Movement gear / `TH` until tagged |
| `/autogear [on\|off]` / `/autogear regen\|refresh\|dt\|petdt N` | Auto sets by HP/MP % (60/60/50/50; 0 = never). No word shows thresholds (doesn't flip). Regen/Refresh out of combat, not over `/dt`; Dt/Pet_Dt any time |
| `/received <spell>` | Wear that `*_Received` set |
| `/rrset` `/craftset` `/zeniset` `/fishset` | Toggle Reraise / Crafting / Zeni / Fishing set, worn over all idle/engaged gear until toggled again (any word flips it) |
| `/wsdistance [yalms]` | WS distance check on/off, or set (default 5) |
| `/gcstyle [N]` | `/lockstyleset N` now; `LockstyleSet` applies it 4s after load |
| `/gcmessages` | Chat confirmations on/off |

| Command | Jobs | Does |
|---|---|---|
| `/nukeset` | RDM BLM SCH GEO WHM | Power → Macc |
| `/weapon` / `/elecycle` | BLM SCH | Club ↔ Staff / element |
| `/nuke <1-6>` `/helix` `/weather` | BLM SCH (`/weather` SCH) | Element's nuke / helix / storm |
| `/death` | BLM | Death toggle |
| `/tankset` | PLD RUN | None → Main → MEVA |
| `/proc` | SAM NIN | Proc set; NIN also locks Ammo |
| `/pupmode` | PUP | Tank → Melee → Ranger → Mage |
| `/forcestring` / `/songlock` | BRD | Force harp / enemy songs keep main/sub |
| `/cormsg` | COR | Roll messages |
| `/siphon` | SMN | Day's spirit, Elemental Siphon, resummon |

## Diagnostics

| Command | Does |
|---|---|
| `/checksets` | Empty sets, bad item names, `_Default` gaps, ear/ring swaps, leftover Moonshade |
| `/gctrace` | One line per action: `[Cure IV] Precast > Cure_Precast \| Midcast > Cure`; `{Waist}` = engine-made |
| `/gcinfo` / `/xiroll` | Element gear picks / roll tracking |
| `/gchelp` / `/gckey <key> <cmd>` | Command list / bind a key |

## HUD

| Command | Does |
|---|---|
| `/gchud [on\|off]` / `/gchud pos 500 120` | Show/hide / place (dragging saves too) |
| `/gchud large` / `compact` / `style` | Look (saved per character) |
| `/gchud debug` | Files found, rows parsed |
| `/gcbar [on\|off]` / `/gcbar pos 300 0` | One-line status bar (Windower: Atk/Def show 0) |

One row per box (each writes `hud/<name>.txt` 4x/s); opens on load for `HUDOwners`. `.` off, glyph on, blank = job
lacks it, `-` none. Bright = changed, dim = default, orange = off but loads on. Toggle columns (and `def`, `mb`) at
load default on every box hide unless in `HUDPinned`; cycle columns hide only when None/Off on every box. Ashita: click a cell runs it on that box, click a name shows hidden columns, Ctrl+click `mb`
cycles its tier. Windower: display only, boxes share state over IPC.
Glyphs: `wpn` Weapons, `ml` MeleeSet, `m` `s` `r` `a` slots, `nk` NukeSet, `el` Element, `tk` TankSet, `hx` Hoxne,
`pp` PupMode, `w` Weapon, `th` TH, `kt` Kite, `fd` AutoFood, `sd` AutoSoda, `hp` String, `sl` SongLock, `pr` PROC,
`dh` Death, `tier` MBTier, `mb` AutoMB (`Off`, or `Auto` + tier; `+F` = `/burst`). Tune: `HUDAbbr`, `HUDLabels`, `HUDScale`, `HUDScaleLarge`, `HUDAlpha`.

## Sets the engine uses

Order: README How sets stack.

| Set | Worn |
|---|---|
| `Weapon_<Mode>` / `_1h` | Weapon mode |
| `Dt`, `mdt`, `Aminon`, `SIR` | With their toggles |
| `Incapacitated` | Slept, petrified, stunned, terrorized: `Aminon` if `/aminon` (no Aminon set: `mdt`), else `mdt` if `/mdt`, else `Dt` (even with `/dt` off), minus Main/Sub/Range/Ammo; then this set; then `*_Received`. Over all job sets incl. `Dt`, and over `mdt`/`Aminon`, `TH`, `Buffs`, XIRoll. Under `Sleeping`, `Doomed`, `Reraise`, util sets. Not charmed (the client can't change gear) |
| `Sleeping` | Asleep, over `Incapacitated` (else `gcinclude.sets.Sleeping`). Main/Sub/Range in it pass the TP hold, not any lock (`/lock`, `/aminon` Main/Sub, `/hoxne` Range): e.g. a Prime stage 1-2 weapon drains 1 HP/MP every 3s, which wakes you (BG-Wiki; not Diabolos' Nightmare). Weapon comes back when awake |
| `TH` | `/th`: at rest, and over midcast/midshot at a mob until tagged (your swing hit or miss, shot, WS, JA; a spell, step or Effusion that lands). THF main: tag ignored, on the whole fight (`gcinclude.THFullTime = true/false` in a job file overrides, any job). Not on you/allies, not `THSkip` (those don't tag). BLU: only `BluMagTH`. Its waist beats obi/Orpheus on that cast |
| `Absorb` / `Absorb_TP` | Every Absorb- spell / Absorb-TP on top. Without `Absorb_TP`, a spell-named set (`['Absorb-TP']`, `['Absorb-STR']`) goes on again over `Absorb`. TH worn on the cast goes back on top |
| `LightBonus` | Healing Magic midcast |
| `Buffs`, `Buffs_Ws`, `Buffs_Midcast` | `{ ['Aftermath: Lv.3'] = {...} }`: while that buff is up, at rest / over WS / over midcast |
| `Hoxne_Tp`, `Hoxne_Idle`, `Hoxne_Dt` | `/hoxne` Locked + Enchantment up: engaged / idle not moving / instead of both while `/dt`. None while `/kite` |
| `Hoxne_Ws`, `Hoxne_<ws>` | Same gate, over every WS, then that WS (`['Hoxne_Victory Smite']`) |
| `Hoxne_<set>_<buff>` | Over it while the buff is up (`Hoxne_Tp_Impetus`); `&` = all up (`['Hoxne_Ws_Sneak Attack&Trick Attack']`). Fewest buffs first, then A-Z |
| `HolyWater` | Put on right before `/holywater` auto-uses a Holy Water (else `gcinclude.sets.Holy_Water`) |
| `gcinclude.sets.Doomed` | While Doomed or Baned, over `Sleeping`/`Incapacitated` |
| `XIRoll` | Idle with a roll at 11 (default Roller's Ring) |
| `*_Received` | Spell cast on you, until it lands (max `ReceivedWindow` 8s) |

### Hoxne layering

Hoxne sets go over your job sets (incl. `Impetus`), under every engine layer, and take `/mset` variants
(`Hoxne_Tp_Hybrid`). MNK Victory Smite, Impetus up: `Ws_Default` → `Victory_Default` → `Victory_Imp` → `Hoxne_Ws`
→ `['Hoxne_Victory Smite']` → `['Hoxne_Victory Smite_Impetus']` → `Buffs_Ws` → Moonshade.
Moonshade goes in Ear2 on WS under `MoonshadeTP` (1750), except `MoonshadeSkip`. A Sub that can't go with the final
Main (two-hander needs a grip, grip needs a two-hander; FFXIclopedia Grips) is dropped.

**Received sets** (`settings.ReceivedSets`): Cure/Cura/Curaga `Cure_Received`, Cursna `Cursna_Received`, Phalanx
`Phalanx_Received`, Protect/Shell `Protect_Shell_Received`, Regen `Regen_Received`, Refresh `Refresh_Received`,
Curing Waltz `Waltz_Received` (your own boxes only). Triggered by anyone's "starts casting" on you, area spells near you (10'), and your own
boxes (Multisend notice to boxes running this engine or in `MyBoxes`). Off when that cast lands or is interrupted.
Never over your own action; locked slots skipped.

**Element gear** (spells in `ElementSkills`, elemental ninjutsu, Quick Draw, cures, WS in `ElementalWS`):

```lua
ElementGear = T{ Obis = T{ Dark = 'Anrin Obi' }, AnyObi = 'Hachirin-no-Obi', Distance = "Orpheus's Sash",
    DistanceMax = nil, Back = nil, Ring = nil, RingSlot = 'Ring2', -- optional, e.g. 'Twilight Cape', 'Zodiac Ring'
    Cures = false, BackOnCures = false, Keep = T{'Oneiros Rope'} };
```

- Obi score: day +10, weather +10 (double +25), opposing element subtracts; obi never at ≤ 0. Orpheus: `OrpheusPoints`
  (+15 at ≤ 1.93', +1 at ≥ 13', linear between). Higher wins. `Keep` items are never displaced.
- Helixes: no obi (day/weather always apply). Cures: obi only (no sash/ring; `BackOnCures` adds the back), off by default; per job
  `gcinclude.CureObi = true` (WHM SCH RDM GEO on; PLD RUN commented). Blue Magic: damage spells only.
- Twilight Cape: +5% to a day bonus, or a weather bonus that applies. Zodiac Ring: `ElementSkills` spells only (not
  ninjutsu, Quick Draw, WS or cures), day matches, never Lightsday/Darksday. A TH waist worn on the cast stays.

## Job file

```lua
gcinclude.SIRSkip = T{'Phalanx'};   -- top of file: adds to settings lists (THSkip too)
gcinclude.CureObi = true;           -- top of file: cure obi for this job
profile.OnLoad = function()
    gcinclude.WeaponModes = {'None', 'Savage', 'Leaden'};
    gcinclude.DefaultWeapons = 'Savage';          -- or { Main = 'Burtgang', Sub = 'Aegis' }
    gcinclude.WeaponRoles = { melee = 'Savage', ranged = 'Leaden' };
    gcinclude.MainModes = {'None', 'Burtgang', 'Caliburnus'};
    gcinclude.SubModes  = {'None', 'Aegis', 'Duban'};
    gcinclude.RangeModes = {'None', 'Annihilator'};
    gcinclude.AlwaysDualWield = true;
    gcinclude.AutoFood = 'Grape Daifuku +1';
    gcinclude.BuffSetOrder = T{'Saboteur', 'Aftermath'};
    gcinclude.MBTier = 'High';
    gcinclude.settings.RefreshGearMPP = 50;       -- any setting, this job only
    gcinclude.Initialize();
end
```

| Helper | Does |
|---|---|
| `gcinclude.EquipMode('Ws')` | `Ws_Default`, then `Ws_<MeleeSet>` unless Default |
| `gcinclude.ByName(name)` | Set `name` (any case), then `name_<MeleeSet>`. False if none |
| `gcinclude.Family(name)` | `'Utsusemi: Ni'` → `'Utsusemi'`, `'Drain III'` → `'Drain'` |
| `gcinclude.CheckTH(force)` | `TH` without weapons at an untagged mob (`force` skips target checks); never `THSkip` |
| `gcinclude.CheckWsBailout()` | False if the WS would fail |
| `gcinclude.BuffCount('Name' or id)` | Buff count (cached ids) |

## Tips

- `gSettings.FastCast` stays 0: idle gear returns on the game's finish packet, and burst timing is learned from your
  real casts (last 5 per skill, slowest used). Too high a value makes LAC's backup timer put idle gear on mid-cast.
- Slot keywords (LuAshitacast): `'remove'` empties the slot; `'displaced'` marks it empty without a packet (a cloak
  covers Head, an instrument empties Ammo, the ampulla empties Range); `'ignore'` leaves it alone.
- HP pieces: `Priority = <HP>` so max HP doesn't dip mid-swap.
- Moonshade Earring: leave it out of WS sets. The engine puts it in `MoonshadeSlot` (Ear2) on every WS below
  `MoonshadeTP` (1750) and gives the set's earring back at or above it, so a set that lists it only fights that.
  `MoonshadeSkip` = WS that never get it; `MoonshadeTP = 0` = engine leaves it alone. `/checksets` flags it.
- Dynamis RP: wear only what you rank, `/lock neck main sub range`, `/unlock` after (BG, Oboro).
- Keybinds (setting `Keybinds`; per job before `Initialize()`; `T{}` = none). Prefixes: `!` Alt, `^` Ctrl, `+` Shift,
  `@` Win, `#` Apps, combined (`^+` = Ctrl+Shift). On load these replace any bind you had on those keys, and bare grave is
  `/unbind`-ed unless listed; unload and job change remove them (`/gckey` ones too), so put lasting binds here.

  ```lua
  Keybinds = T{ {'^`','wm'}, {'+`','wm default'}, {'^+`','def'}, {'!`','hoxne'}, {'@`','automb'} };
  ```
