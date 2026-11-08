# GoomSwap

FFXI gear-swap engine for multiboxing. You write sets in a job file; GoomSwap wears them and layers weapons, defense,
TH, obi and more on top. **Ashita v4** (LuAshitacast) and **Windower 4** (GearSwap, via `windower/`), same job files.

- **Weapons:** `/wm` modes, `_1h` sets without dual wield, idle/town weapons out of combat; no auto swap costs TP
  (`WeaponTPGuard`) or Aftermath.
- **Defense:** `/def` (DT, MDT, Aminon), idle Regen/Refresh/DT by HP/MP, sleep/stun/doom/weakness sets.
- **Casting:** TH until tagged, SIR, obi/Orpheus/ring/back, Moonshade, Burst gear on nukes in a live skillchain.
- **Items:** packer (items and food on every job change), enchanted items, warp/dim rings, Hoxne Ampulla.
- **Multibox:** status bar with every other box dropped under it (click to drive any), Einherjar entry (`/ejenter`, Ashita).
- **Checks:** failing actions cancelled with the reason; `/checksets`; `/gctrace`.

## Install

**Ashita v4**
1. `common/` and `examples/` into `Ashita/config/addons/luashitacast/`.
2. `examples/<JOB>.lua` into `luashitacast/<Name>_<id>/`, your gear in it. Optional: `examples/char.lua` there
   (that character's food, packer list, settings).
3. `/addon load luashitacast`, `/lac load`.
4. Recommended: Thorny's [Sequencer](https://github.com/ThornyFFXI/Sequencer) (else lag loses actions) and
   [PacketFlow](https://github.com/ThornyFFXI/PacketFlow) plugins.

**Windower 4**

```
Windower/addons/GearSwap/data/
├── default.lua                        <- windower/GearSwap/data/default.lua
└── goomswap/
    ├── core.lua ashita.lua imgui.lua  <- windower/GearSwap/data/goomswap/
    ├── common/                        <- common/
    └── <Name>/<JOB>.lua               <- examples/<JOB>.lua, your gear in it
```

`//lua load gearswap`, change job: chat says `[GoomSwap] Loaded data/goomswap/<Name>/<JOB>.lua`. Red line = missing
file, do what it says. No `[GoomSwap]` line = GearSwap found another file first (`data/<Name>/<JOB>.lua`,
`data/<Name>_<JOB>.lua`, `data/<Name>.lua`, `data/<JOB>.lua` all beat `default.lua`). A job file in `goomswap/`
itself serves every character.

| | Ashita | Windower |
|---|---|---|
| Command | `/wm` | `//wm`, `//gs c wm` |
| All boxes | `/mss /wm` (Multisend) | `//send @all gs c wm` |
| Reload | `/lac reload` | `//gs reload` |
| Augments | `{ Name = 'X', Augment = {...} }` | same line works (closest copy); or `{ name="X", augments={...} }` from `//gs export`, exact |
| 2 of one item | nothing to do | give each copy its bag (below) |

**Windower, two of one item** (2 Stikini Ring +1, twin earrings, same weapon Main+Sub): by name alone GearSwap can
grab the copy worn in the other slot and the two swap places. Pin each:

```lua
Ring1 = { Name = 'Stikini Ring +1', Bag = 'Wardrobe' },   -- 'wardrobe1' works too
Ring2 = { Name = 'Stikini Ring +1', Bag = 'Wardrobe2' },
```

Bags: `Inventory`, `Wardrobe` … `Wardrobe8`, any case. Spelled `Wardrobe` … `Wardrobe4` the line works on Ashita too.

**Windower augments:** wear the gear, `//gs export` (or `//gs export copy`), paste into the set, capitalize the slot
(`back=` → `Back =`).

### From Selindrile (Windower)

1. Install as above, plus `goomswap_migrate.lua` next to `default.lua` and `examples/` as `data/goomswap/examples/`.
2. On the character: `//gs load goomswap_migrate`. Each `data/<Name>/<Name>_<Job>_Gear.lua` becomes
   `data/goomswap/<Name>/<JOB>.lua` plus a one-line `data/<Name>/<JOB>.lua` that loads GoomSwap. Re-run replaces its
   own earlier file (old one kept as `.lua.bak`); a file you wrote stays, new one is `.migrated.lua`. Selindrile files
   are only read.
3. `//gs reload`, `//gs c checksets`. Back to Selindrile: delete `data/<Name>/<JOB>.lua`.

| Selindrile | GoomSwap |
|---|---|
| `idle` `.Refresh` `.Regen` `.Regain`, `resting`, `Kiting`, `TreasureHunter` | `Idle` `Idle_Refresh` `Idle_Regen` `Idle_Regain`, `Resting`, `Movement`, `TH` |
| `engaged` `.<OffenseMode>` | `Tp_Default` `Tp_<mode>`; OffenseMode = `/mset` list |
| `defense.PDT` `.MDT` (else `.MEVA`) | `Dt` `mdt` |
| `precast.FC`, `FC.Cure`, `FC['Enhancing Magic']` | `Precast` `Cure_Precast` `Enhancing_Precast` |
| `precast.WS` `['Savage Blade']` `.Acc` | `Ws_Default`, `['Savage Blade']`, `['Savage Blade_Acc']` |
| `precast.JA[...]`, `midcast.Cure`, `midcast['Enhancing Magic']` | the template's set, else by name |
| `midcast.RA` `.Acc`; `midcast['Elemental Magic'].OccultAcumen` | `Midshot` `Midshot_Acc`; `OccultAcumen` |
| `weapons.<Name>` + `state.Weapons` | `Weapon_<Name>` + `/wm` modes |
| `buff.Doom` `.Sleep`, `Cure_Received`... | `Doomed` `Sleeping` `Cure_Received`... |

No place (`.DT` hybrids, `Resistant`, latent sets...): kept as `['Sel_<path>']`. Binds become that job's `Keybinds`:
chat commands as is, modes mapped (`Weapons`→`wm`, `OffenseMode`→`mset`, `IdleMode`→`idleset`, `HybridMode`→`tankset`,
`RangedMode`→`rangedset`, `CastingMode`→`nukeset` or `sir`, `gs reload`→`/lac reload`). Defense keys and
Selindrile automation (`AutoWSMode`, `SkillchainMode`...) are left out; the file's top comment lists what was.

## First steps

1. Fill `Idle`, `Tp_Default`, `Ws_Default`.
2. `/checksets` (empty sets, misspellings), `/gctrace` (what each action wore).
3. Leave `gSettings.FastCast` at 0.

Every example names sets after the action (`['Savage Blade']`); a spell without one uses its family's (`['Cure']` for
Cure IV). Worth copying: `WHM.lua` cures, `MNK.lua` Hoxne, `PLD.lua` `/subset`.

## Settings

Edit two blocks at the top of `common/gcinclude.lua` (the rest is engine). A newer `common/` overwrites them: keep
yours in `char.lua` (per character, survives updates) or the job file.

- **`gcinclude.sets`**, every job: `Doomed`, `Holy_Water`, `Sleeping` (a job's own wins), `Reraise` (Weakened),
  `Crafting` `Zeni` `Fishing` (`/craftset` `/zeniset` `/fishset`).
- **`gcinclude.settings`**, one commented option per line.

| Where | Example |
|---|---|
| Every job | `RefreshGearMPP = 50;` in `common/gcinclude.lua` |
| One character | `char.lua`: `return { settings = { Messages = true, HUDOwners = T{'YourMain'} } };` |
| One job | `OnLoad`, before `gcinclude.Initialize()`: `gcinclude.settings.RefreshGearMPP = 50;` |
| One job, add to a list | top of the job file: `gcinclude.SIRSkip = T{'Phalanx'};` |
| One job, replace | `gcinclude.Food`, `gcinclude.LockstyleSet`, `gcinclude.ElementGear`, `gcinclude.CureObi` |

Most changed:

| Setting | Default | Does |
|---|---|---|
| `Messages` | `false` | chat line on every mode change (`/gcmessages`) |
| `HUDOwners` | `T{}` | boxes whose bar drops the others in (the HUD) |
| `Keybinds` | F-key layout | your keys (Keys); `T{}` none |
| `LockstyleSet` | `nil` | lockstyle set put on after load/job change |
| `RegenGearHPP` `RefreshGearMPP` `DTGearHPP` | 60 60 50 | auto `Idle_Regen` / `Idle_Refresh` / `Dt` below this %; 0 never |
| `WeaponTPGuard` | 1000 | TP at which Main/Sub/Range stay on; 0 never hold |
| `IdleWeapons` | `true` | idle sets' weapons beat the mode out of combat |
| `Food` | Grape Daifuku +1 | food `/packer` keeps a stack of |
| `MoonshadeTP` | 1750 | Moonshade below this TP; 0 never |
| `Validate` `ValidateMP` | `true` | cancel actions that would fail |
| `DisplayBar` | `false` | status bar on load |

All: weapons `AftermathHold` `HoldExemptSkills` `HoldExemptAbilities` `SmartSwap` `SmartSwapTP` `NoWeaponSpells`
`KeepWeaponsFor`; casting `SIRSkip` `THSkip` `ElementGear` `ElementSkills` `OrpheusPoints` `MBWindow` `MBSkills`;
idle `AutoGear` `PetDTGearHPP`; WS `WScheck` `WSdistance` `MoonshadeSlot` `MoonshadeSkip` `ElementalWS`; items
`PackerItems` `EnchantDelays` `EnchantWindow`; Hoxne `HoxneItem` `HoxneLockSlots` `HoxneAutoUse`; received
`ReceivedSets` `ReceivedWindow` `MyBoxes`; checks `WaltzTPCut`; HUD/bar `HUD*` `DisplayBarX` `DisplayBarY`; other
`Trace` `CombatWindow` `XIRollSet` `CapacityCapes` `JubileeSlot` `AmmoWarn` `NinjaToolWarn` `SleepCancelStoneskin`
`ElementReport` `warp_Ring` `mea_Ring` `dem_Ring` `holla_Ring`.

## Commands

Ashita `/name`, Windower `//name` or `//gs c name`. Toggles take `on`/`off`, no word flips. Values, any case: no word =
next; else name, start, initials, contains, or number (`/wm max`, `/mset sb`, `/wm 3`). Windower: with Stopwatch or
THTracker loaded use `//subset` / `//gs c th`.

| Command | Does |
|---|---|
| `/wm [name\|N\|none\|default]` | Weapon mode; `/wm <mode> force` re-applies |
| `/mw` `/sw` `/rw` `/ammoset [name\|none]` | One slot's pick over the mode (`/mainset` `/subset` `/rangeset`); any TP |
| `/dw [on\|off\|auto]` | Dual Wield: why; `off` = `_1h` always |
| `/smartswap` | Light spells (Dia, Blink…) keep weapons at `SmartSwapTP`+ |
| `/setcycle <cycle> <value>` | Any mode by name |
| `/mset [sb\|acc\|base]` | Melee mode: `_Default` → `_SubtleBlow` → `_Acc` TP/WS sets |
| `/wsset [mid\|high]` | `high`: WS sets add their `_HighBuff` |
| `/rangedset [acc]` | COR RNG PLD: `Midshot_Acc` |
| `/th` | `TH` until tagged (THF main: always) |
| `/wsdistance [yalms]` | WS range check |
| `/def [dt\|mdt\|aminon\|off]` | DT → MDT → Aminon → off; `/dt` `/mdt` `/aminon` one |
| `/sir` `/kite` | SIR over midcasts (not `SIRSkip`) / Movement |
| `/idleset [refresh\|regen\|regain]` | `Idle_<mode>` over `Idle` while idle |
| `/autogear [regen\|refresh\|dt\|petdt N]` | Auto idle set thresholds |
| `/lock [slots\|all]` `/unlock [slot]` | Freeze slots; `/unlock` names other holders |
| `/naked` `/weaponsonly` `/abysseaproc` | Keep all / armor / head-hands-legs-feet bare |
| `/rrset` `/craftset` `/zeniset` `/fishset` | That set over everything until off |
| `/received <spell>` | Wear its `*_Received` set |
| `/nukeset [power\|macc\|oa]` | Nuke sets; `oa` = `OccultAcumen` (RDM GEO BLM SCH DRK) |
| `/burst` | `Burst` on every nuke |
| `/mbinfo` | Last skillchain |
| `/gcaspir` `/gcdrain` | Best tier on `<t>` |
| `/nuke <1-6>` `/helix` `/weather` `/elecycle` `/weapon` `/death` | BLM/SCH helpers |
| `/packer` | Fetch missing packer items (Bellhop) |
| `/hoxne [off\|use]` | Hoxne Ampulla in Ammo, used |
| `/gce <item>` `/gce cancel` | Equip enchanted item, wait, use, free the slot |
| `/warpring` `/mea` `/holla` `/dem` `/ontic` `/shard` `/gctemps` | Warp/dim rings, exit items, Escha drinks |
| `/capacity` `/jubilee` `/dynamisrp` | Hold cape / Jubilee Ring / Dynamis neck |
| `/ejenter [chamber]` `/ejlamps` `/ejexit` | Einherjar (Ashita) |
| `/tankset` `/proc` `/pupmode` | PLD RUN tank set / `Proc` set, every job / PUP mode |
| `/forcestring` `/songlock` `/cormsg` `/xiroll` `/siphon` | BRD / COR / SMN |
| `/gcbar` `/gchud` | Status bar / the other boxes dropped under it (below) |
| `/gcmodes [all]` | Modes in chat |
| `/checksets` | Empty sets, bad names, wrong ear/ring (Sortie/"Right ear:" → Ear2) |
| `/gcgear [JOB]` | Everything you own the job can wear → `gear_<JOB>.txt` (Ashita) |
| `/gctrace` `/gcstyle [N]` `/gcmessages` `/gchelp` | Trace / lockstyle / chat lines / help |
| `/gckey <key> <cmd>` | Bind a key |

Old names still work: `/mmode` `/meleeset` `/melee` = `/mset`, `/weaponset` = `/wm`.

## Keys

Bound on load, removed on unload/job change.

| Key | Runs | Key | Runs |
|---|---|---|---|
| F7 | `/wm` | Shift+F7 | `/wm default` |
| F9 | `/mset` | Ctrl+F9 | `/tankset` |
| Shift+F9 | `/rangedset` | Alt+F9 | `/wsset` |
| F10 | `/def` | Alt+F10 | `/kite` |
| Win+F10 | `/hoxne` | Shift+F11 | `/nukeset` |
| Alt+F11 | `/burst` | Shift+F12 | `/idleset` |
| Alt+F12 | `/def off` | Ctrl+Win+Alt+F12 | reload |

Your own: a GoomSwap command (`wm 2`) or any chat command (`/ma "Cure IV" <stpc>`). Modifiers `^` Ctrl, `!` Alt,
`+` Shift, `@` Win, `#` Apps.

- Now: `/gckey ^F1 /ma "Cure IV" <stpc>`.
- One character: `char.lua` `settings = { Keybinds = { {'F7','wm'}, {'^F1','/ja "Provoke" <t>'} } }` (whole list).
- One job: `table.insert(gcinclude.settings.Keybinds, {'^F2', '/ja "Sentinel" <me>'});` in `OnLoad`.

## Weapons

- The mode is what you return to; action sets naming weapons still swap them. Slot picks beat the mode for their slot.
- Out of combat, idle sets' weapons win (`IdleWeapons`); Main+Sub and Range+Ammo move as pairs.
- At `WeaponTPGuard`+ TP (examples: 0 on mages, 100 PLD) Main/Sub/Range stay, except songs, rolls, cures,
  enfeebling, enhancing, geomancy. Aftermath holds them too (`AftermathHold`). Weapon commands always swap.
- `Weapon_<Mode>_1h` without DW (NIN 10+, DNC 20+, THF 83+, main or sub). `gcinclude.AlwaysDualWield = true` forces it.
  A Sub refused for lack of DW stays off 15s.
- THF `/th`: `TH` weapons stay on; other jobs drop them at the tag.
- Augmented cycle entry: `gcinclude.WeaponItemMap = { ['Rostam B'] = { Name = 'Rostam', AugPath = 'B' } };`.

## Defense, locks, Hoxne

- `/aminon`: `Aminon` set (else `mdt`), weapon mode's Main/Sub on and locked even idle (Regain TP); turns `/sir` off.
- `/lock` beats everything until `/unlock`. Each lock has an owner; `/unlock` frees yours and names the rest.
- `/hoxne`: Ampulla kept in Ammo (Ammo, Range locked), used 3s after Enchantment ends (`HoxneAutoUse = false` stops).
  Zoning turns it off.

## Magic burst

`Burst` goes on when a nuke lands in a live skillchain of its element within `MBWindow` (10s). You cast; GoomSwap
dresses. `/burst` = every nuke. `MBSkills` = skills that get it.

## Items

- **Packer** (Ashita, Bellhop): `PackerItems` → `char.lua` `Packer` → `gcinclude.Packer = { ['Trump Card'] = 99 }`;
  `'stack'` = full, `false` drops. Plus a stack of each `Food`. Windower: `profile.Packer` → `//gs org`.
- **`/gce`:** waits the item's delay (`EnchantDelays`, `EnchantWindow`), retries 5x, then frees the slot. Rings: Ring2.
- **Einherjar** (Ashita): reserver at the Entry Gate `/ejenter ort` trades lamps to the party; boxes accept and enter.
  `/ejexit` leaves. Windower: Valkyrie.
- Warns at `AmmoWarn` ammo, `NinjaToolWarn` tools. Asleep under Stoneskin: `/cancel Stoneskin`.

## Action checks

Cancelled before gear moves, reason in chat (`Validate = false` off): KO, sleep/stun/petrify/terror/charm, Mute,
Silence, Amnesia (JA/WS), recast (`m:ss`), already casting, MP short (arts-adjusted; `ValidateMP`), stratagems,
Waltz TP. Nothing is queued.

## Status bar and HUD

One window: this box's **bar**, and (the HUD) every other box **dropped in under it** while the mouse is over it.
`/gcbar` (or `DisplayBar = true`) shows the bar; drag it (saved per character; within 8px of the top it snaps
flush). `/gchud` turns the drop on (`HUDOwners` boxes: on at load; it also turns the bar on). Each box shares its
modes when they change (checked 4x/s); the box with the drop reads them twice a second (Ashita
`luashitacast/hud/`, Windower IPC).

![The status bar with the HUD dropped](docs/gcbar.png)

- **Lines:** yours = job box (main | sub outline), `Atk` `Def` (Ashita); each other box = its name (first half of
  the letters in its main job's colour, the rest its sub job's) and job/levels. Then the same pills in the same
  columns: weapon | modes | `def` and toggles; blank = that job has no such mode.
- **Pills:** set or on = its colour, tint and a solid dot, showing the value; default or off = dashed grey and a
  ring, showing its name. The weapon pill is plain (`+` = a slot pick `/mainset` `/subset` `/rangeset` `/ammoset`
  changed). Each column as wide as its widest value, `Atk`/`Def` as 4 digits: cycling never moves anything.
- **Click** a pill: cycles it on that box (ctrl+click the weapon: `/mset`).
- **Colours:** melee `acc` cyan / `sb` magenta (own modes: lime, salmon, periwinkle), ws `high` purple, idle `mp`
  blue / `hp` green / `tp` yellow, nuke `macc` teal / `oa` salmon, ranged `racc` cyan, `hoxne` bronze, tank `main`
  periwinkle / `meva` lime, `dt` orange / `mdt` blue / `amin` mauve (`+` = more than one), `sir` teal, `th` gold,
  `kite` green, `proc` red, `burst` pink. Each of the 22 jobs its own colour.
- A job without weapon modes (WHM...) shows `melee`, `ws` and `hoxne` only once changed.
- **Drop:** on hover (`HUDHover = false`: always); in the screen's bottom half the other boxes rise above the bar
  instead (`HUDGrow`). The box with it on also prints the other boxes' chat lines as `[Name]` (`HUDMessages`).
- Settings: `DisplayBar` `HUDOwners` `HUDHover` `HUDGrow` `HUDMessages` `HUDAlpha`; `/gchud debug` lists what it
  reads.
- Windower: `|` and the words in their colours (grey = default/off), no capsule, outline or pills.

## How sets stack

Later wins, slot by slot.

**Idle/engaged:**
1. Job file: `Idle` → `Idle_<mode>` / `Tp_Default` → `Tp_<mset>` → buff sets → `Dt` (`/dt`) → `Movement` (`/kite`).
2. Hoxne sets → auto `Idle_Regen` `Idle_Refresh` `Dt` → `Town`.
3. Weapon mode → `mdt`/`Aminon` → Hoxne Ampulla → `TH` → `*_Received` → `Buffs` → XIRoll.
4. `Incapacitated` (slept, petrified, stunned, terror), over 1-3: Aminon, else `mdt`, else `Dt` (no weapons), its set.
5. `Sleeping` → `Doomed` → `Reraise` → craft/zeni/fish/rr.

**Midcast:** job file → `TH` → `_Self` `_Others` `_Burst` → `Absorb` → `Buffs_Midcast` → `LightBonus` →
obi/Orpheus/back/ring → `SIR`. WHM cures: `['Healing Magic']` → `Self_Cure` → `Cure_LowMP` → `Cure_Dt` → obi → `SIR`.

**WS:** job file → `_HighBuff` → Hoxne → `Buffs_Ws` → Moonshade → obi/Orpheus/back.

| Engine set | Worn |
|---|---|
| `<set>_Self` `_Others` `_Burst` | spell on you / on others / a burst |
| `Weapon_<Mode>` `_1h` `<Mode>Acc` | weapon mode; no DW; `/mset acc` |
| `Dt` `mdt` `Aminon` `SIR` `TH` `Movement` | their toggles; `TH` until tagged |
| `Idle_Refresh` `Idle_Regen` `Idle_Regain` | `/idleset`; low MP/HP |
| `Midshot_Acc` | `/rangedset acc` |
| `Proc` `Ws_Proc` | `/proc`: engaged over your sets (`Dt` stays on top); on WS `Ws_Proc`, else `Proc` |
| `Incapacitated` `Sleeping` | disabled / asleep (weapons pass the TP hold) |
| `Absorb` `Absorb_TP` `LightBonus` | Absorb spells / Healing Magic |
| `Buffs` `Buffs_Ws` `Buffs_Midcast` | `{ ['Aftermath: Lv.3'] = {...} }` while the buff is up |
| `Hoxne_Tp` `_Idle` `_Dt` `_Ws` `Hoxne_<set>_<buff>` | `/hoxne` + Enchantment |
| `XIRoll` | idle with a roll at 11 |
| `*_Received` | a spell coming at you (`ReceivedSets`, 8s max) |

- **Moonshade:** leave it out of WS sets; added below `MoonshadeTP` (not `MoonshadeSkip`). WS set's Ear2 a Sortie or
  "Right ear:" item → Moonshade in Ear1, else Ear2.
- **Grips:** a Sub that can't go with the Main is dropped.
- **Element gear** (`ElementSkills`, ninjutsu, Quick Draw, cures, `ElementalWS`):
  ```lua
  ElementGear = T{ Obis = T{ Dark = 'Anrin Obi' }, AnyObi = 'Hachirin-no-Obi', Distance = "Orpheus's Sash",
      Keep = T{'Oneiros Rope'} };
  ```
  Obi: day +10, weather +10/+25, opposite subtracts; Orpheus by distance (`OrpheusPoints`); higher wins. Helixes no obi;
  cures obi only (`gcinclude.CureObi`).

**SIRSkip / THSkip** (default `'Absorb-TP', 'Stun'`): spells `/sir` / `/th` leave alone. Exact names. Add per job at
the top: `gcinclude.SIRSkip = T{'Phalanx'};`; replace in `OnLoad`: `gcinclude.settings.SIRSkip = T{...};`. `/gchelp`
lists them.

## Job file

```lua
gcinclude.SIRSkip = T{'Phalanx'};   -- top: adds to the list
gcinclude.CureObi = true;           -- top: cure obi
profile.OnLoad = function()
    gcinclude.WeaponModes = {'None', 'Savage', 'Leaden'};
    gcinclude.DefaultWeapons = 'Savage';          -- or { Main = 'Burtgang', Sub = 'Aegis' }
    gcinclude.WeaponRoles = { melee = 'Savage', ranged = 'Leaden' };
    gcinclude.MainModes = {'None', 'Burtgang'};  gcinclude.SubModes = {'None', 'Aegis', 'Duban'};
    gcinclude.AlwaysDualWield = true;
    gcinclude.Food = {'Grape Daifuku +1'};
    gcinclude.Packer = { ['Echo Drops'] = 'stack' };
    gcinclude.MeleeModes = {'Default', 'Acc'};    -- own /mset list (NukeModes: /nukeset)
    gcinclude.settings.RefreshGearMPP = 50;
    gcinclude.Initialize();
end
```

| Helper | Does |
|---|---|
| `gcinclude.EquipIdle()` | `Idle` + `Idle_<mode>` (use in `HandleDefault`) |
| `gcinclude.RangedAcc()` | true on `/rangedset acc` |
| `gcinclude.EquipMode('Ws')` | `Ws_Default` + `Ws_<mset>` |
| `gcinclude.ByName(name)` | set `name`, then `name_<mset>`; false if none |
| `gcinclude.Family(name)` | `'Drain III'` → `'Drain'` |
| `gcinclude.CheckTH(force)` | `TH` at an untagged mob |
| `gcinclude.CheckWsBailout()` | false if the WS would fail |
| `gcinclude.BuffCount(x)` | buff count |

**Set names** (every example, same handlers): the game's own name, worn by `ByName`; empty sets do nothing.

| Set | Worn |
|---|---|
| `['Savage Blade']` `['Savage Blade_Acc']` `['Savage Blade_HighBuff']` | that WS; `/mset acc`; `/wsset high` |
| `Ws_Default` `Ws_Acc` `Ws_HighBuff` | any WS, under its own |
| `['Berserk']` | that job ability |
| `['Enhancing Magic']` `['Cure']` `['Phalanx']` | skill, then spell or family (`Cure IV` → `Cure`) |
| `['Healing Magic_Precast']` `['Stoneskin_Precast']` | over `Precast` |
| `Tp_Default` `Tp_SubtleBlow` `Tp_Acc` | engaged, `/mset` |
| `Buffs` `Buffs_Ws` `Buffs_Midcast` `{ ['Aftermath: Lv.3'] = {...} }` | while that buff is up |

Each file ends its sets with a Templates block (one of each, blank) to copy from. Groups keep a plain name
(`Phantom Roll` for every roll, `Quick Draw`, `Nitro`, `Enmity`, BRD song groups).

## Tips

- `gSettings.FastCast` 0: idle gear returns on the finish packet.
- Slot words: `'remove'` empty, `'displaced'` empty without a packet, `'ignore'` leave alone.
- `Priority = <HP>` keeps max HP up mid-swap.

## Something wrong

| Problem | Check |
|---|---|
| Edit does nothing | `/lac reload` / `//gs reload` |
| Windower loads nothing | red line says what; no `[GoomSwap]` line: see Install |
| `attempt to index global 'gFunc'` | job file in `data/<Name>/`: move to `data/goomswap/<Name>/` |
| Slot won't change | `/unlock` (names holders); TP/Aftermath hold (`/wm <mode> force`) |
| TP-set weapon never shows | engaged the mode wins: `/wm none`, `/mainset none` |
| Wrong gear | `/checksets`, spelling, `/gctrace` |
| Action cancelled | chat says why |
| HUD gone | `/gcbar on`, `/gchud on`, `/gcbar pos 500 0` |
