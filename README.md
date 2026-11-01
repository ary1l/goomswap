# GoomSwap

Gear-swap engine for FFXI multiboxing. You write sets in a job file; GoomSwap wears them and adds automatic
layers (weapons, defense, TH, obi, and more) on top. **Ashita v4** (LuAshitacast) and **Windower 4** (GearSwap,
through `windower/`), same job files. Full reference: [`COMMANDS.md`](COMMANDS.md).

## What it does on its own

- **Weapons:** `/wm` modes (`_1h` sets when you can't dual wield, `/mmode Acc` variants), idle/town weapons out of
  combat. No automatic swap throws away TP (`WeaponTPGuard`, per job) or Aftermath; songs, rolls, cures still swap.
- **Defense:** `/dt` `/mdt` `/aminon`; regen/refresh/DT idle by HP/MP; sleep, stun, doom, weakness sets.
- **Casting:** TH until tagged, SIR, obi/Orpheus/elemental ring and back, Moonshade, auto magic burst (RDM BLM SCH GEO).
- **Items:** food (per job), packer (keeps a list of items in inventory on every job change), soda, holy water, enchanted items and warp/dim rings, Hoxne Ampulla.
- **Multibox:** one HUD for every box (click a cell to drive it, the boxes' messages show there); Einherjar entry,
  lamp copies and hand-out (`/ejenter`, Ashita).
- **Checks:** refused actions say why; `/checksets` finds empty sets and misspellings; `/gctrace` shows what each action wore.

## Install

**Ashita v4**
1. Copy `common/` and `examples/` into `Ashita/config/addons/luashitacast/`.
2. Copy `examples/<JOB>.lua` into your character folder `luashitacast/<Name>_<id>/`, put your gear in. Optional:
   `examples/char.lua` there too, for that character's food, packer list and settings on every job.
3. `/addon load luashitacast`, then `/lac load`.
4. Recommended: Thorny's [Sequencer](https://github.com/ThornyFFXI/Sequencer) and [PacketFlow](https://github.com/ThornyFFXI/PacketFlow) plugins
   (`/load sequencer`, `/load packetflow`, or in your startup script). Without Sequencer, LuAshitacast blocks the
   game's own resends, so an action is lost when lag hits; PacketFlow sends packets more often.

**Windower 4**

```
Windower/addons/GearSwap/data/
├── default.lua                        <- windower/GearSwap/data/default.lua
└── goomswap/
    ├── core.lua ashita.lua imgui.lua  <- windower/GearSwap/data/goomswap/
    ├── common/                        <- common/
    └── <Name>/<JOB>.lua               <- examples/<JOB>.lua, your gear in it
```

`//lua load gearswap`, change job: chat shows `[GoomSwap] Loaded data/goomswap/<Name>/<JOB>.lua`. A red
`[GoomSwap]`/`[LuAshitacast]` line names a missing file or folder. No `[GoomSwap]` line at all = GearSwap found another file first (`data/<Name>/<JOB>.lua`, `data/<Name>_<JOB>.lua`, `data/<Name>.lua`,
`data/<JOB>.lua` all beat `default.lua`). A job file straight in `goomswap/` serves every character. Already use
`default.lua` for other jobs? Copy ours to `data/<Name>_<JOB>.lua` for each GoomSwap job instead.

| | Ashita | Windower |
|---|---|---|
| Command | `/wm` | `//wm` or `//gs c wm` |
| All boxes | `/mss /wm` (Multisend) | `//send @all gs c wm` |
| Reload after edits | `/lac reload` | `//gs reload` |
| HUD | `/gchud`, click cells | `//gchud`, click cells |
| Augmented gear | `{ Name = 'X', Augment = {...} }` (LAC strings) | Same file works: the carried copy best matching the list is worn (names differ a bit between the two, so not exact). Or GearSwap's own `{ name="X", augments={...} }`, pasted from `//gs export`, matched exactly |

Windower augment strings: wear the gear, `//gs export` (file in `GearSwap/data/export/`) or `//gs export copy`
(clipboard), paste each line into a set and capitalize the slot (`back=` → `Back =`). Rare items export without
augments (only one copy exists). In a job file (COR):

```lua
local sets = {
    Weapon_Rostam = {
        Main = { name="Rostam", augments={'Path: A',} },
    },
    Tp_Default = {
        Back = { name="Camulus's Mantle", augments={
            'AGI+20', 'Rng.Acc.+20 Rng.Atk.+20', 'Rng.Acc.+10', '"Store TP"+10', 'Mag. Evasion+15',
        } },
    },
};
```

## First steps

1. Fill `Idle`, `Tp_Default`, `Ws_Default`. The rest can wait.
2. `/checksets`: empty sets, misspelled items. `/gctrace`: which sets each action wore.
3. Leave `gSettings.FastCast` at 0.

Template jobs (BLM BST DNC DRG DRK NIN PUP RUN SAM SMN WAR) name sets after the action (`['Savage Blade']`); a spell
with no set uses its family's (`['Cure']` for Cure IV). Worth copying: `WHM.lua` cures (MP% / Light weather weapons, `Cure_Dt`), `MNK.lua` Hoxne sets, `PLD.lua` `/subset`.

## Settings (`common/gcinclude.lua`)

The top of `common/gcinclude.lua` has two blocks you edit; everything below is the engine.

- **`gcinclude.sets`**: sets shared by every job: `Doomed`, `Holy_Water`, `Sleeping` (a job's own `Sleeping` wins),
  `Reraise` (worn while Weakened), `Crafting` (`/craftset`), `Zeni` (`/zeniset`), `Fishing` (`/fishset`).
- **`gcinclude.settings`**: one option per line, each commented.

| Where | How | Example |
|---|---|---|
| Every job | Edit the value in `common/gcinclude.lua` | `RefreshGearMPP = 50;` |
| One job | Job file `OnLoad`, before `gcinclude.Initialize()` | `gcinclude.settings.RefreshGearMPP = 50;` |
| One job, list | Top of the job file; adds to the setting's list | `gcinclude.SIRSkip = T{'Phalanx'};` |
| One job, value | Job file; replaces the setting in brackets | `gcinclude.MBTier` (`MBTier`), `gcinclude.AutoFood` (food list, `AutoFoodItems`; on/off stays `AutoFood`), `gcinclude.LockstyleSet`, `gcinclude.ElementGear` (whole table), `gcinclude.CureObi` (`ElementGear.Cures`) |

Copying a newer `common/` over yours erases your edits: note them, or set them per job instead.

| Area | Settings |
|---|---|
| Weapons / TP | `WeaponTPGuard`, `AftermathHold`, `IdleWeapons`, `HoldExemptSkills`, `HoldExemptAbilities`, `SmartSwap`, `SmartSwapTP`, `NoWeaponSpells`, `KeepWeaponsFor` |
| Casting | `SIRSkip`, `THSkip`, `ElementGear` (obi, Orpheus, ring, back, `Cures`), `ElementSkills`, `OrpheusPoints` |
| Auto idle sets | `AutoGear`, `RegenGearHPP`, `RefreshGearMPP`, `DTGearHPP`, `PetDTGearHPP` |
| Weapon skills | `WScheck`, `WSdistance`, `MoonshadeTP`, `MoonshadeSlot`, `MoonshadeSkip`, `ElementalWS` |
| Magic burst | `AutoNuke`, `MBTier`, `MBCasts`, `MBRotate`, `MBMinMP`, `MBWindow`, `MBFallback`, `MBSkills` |
| Items | `AutoFood`, `AutoFoodItems`, `PackerItems`, `PackerFood`, `AutoSoda`, `SodaItem`, `AutoHolyWater`, `HolyWaterItem`, `AutoRevitalizer`, `AutoUseItems`, `EnchantDelays`, `EnchantWindow`, `ConsumableMaxTries` |
| Hoxne | `HoxneItem`, `HoxneLockSlots`, `HoxneAutoUse` |
| Received gear | `ReceivedSets`, `ReceivedWindow`, `MyBoxes` |
| Action checks | `Validate`, `ValidateMP`, `WaltzTPCut` |
| HUD / bar | `HUDOwners`, `HUDHover`, `HUDMessages`, `HUDX`, `HUDY`, `HUDStyle`, `HUDScale`, `HUDScaleLarge`, `HUDAlpha`, `HUDAbbr`, `HUDLabels`, `DisplayBar`, `DisplayBarX`, `DisplayBarY` |
| Other | `Keybinds`, `Messages`, `Trace`, `LockstyleSet`, `CombatWindow`, `XIRollSet`, `CapacityCapes`, `JubileeSlot`, `AmmoWarn`, `NinjaToolWarn`, `SleepCancelStoneskin`, `ElementReport`, `warp_Ring` `mea_Ring` `dem_Ring` `holla_Ring` |

Weapon modes, default weapons, job helpers: `COMMANDS.md` Job file.

## Commands

Every command, one line each; details and examples: [`COMMANDS.md`](COMMANDS.md). Toggles take `on`/`off`, no word flips.

**Weapons**
| Command | Does |
|---|---|
| `/wm [name\|N\|none\|default]` (`/weaponset`) | Weapon mode: next, or by name/number. `/wm <mode> force` re-applies it |
| `/mw` `/sw` `/rw` `/ammoset` `[name\|none]` | One slot's pick (`/mainset` `/subset` `/rangeset` long names), e.g. PLD `/sw duban`. Swaps at any TP |
| `/dw [on\|off\|auto]` | Dual Wield: shows why; `off` = `_1h` sets always, `on` = DW always |
| `/smartswap` | Light spells (Dia, Blink…) keep your weapons at `SmartSwapTP`+ |
| `/setcycle <cycle> <value>` | Set any mode by its name |

**Melee and weapon skills**
| Command | Does |
|---|---|
| `/mmode [sb\|acc\|base]` (`/melee`, `/meleeset`) | Melee mode: Base (`_Default` sets) → `_SubtleBlow` → `_Acc` TP and WS sets |
| `/wsset [mid\|high]` | `high`: each WS set also wears its `_HighBuff` |
| `/th` | `TH` set until the mob is tagged (THF main: always) |
| `/wsdistance [yalms]` | WS range check on/off or its distance |

**Defense**
| Command | Does |
|---|---|
| `/def [dt\|mdt\|aminon\|off]` | DT → MDT → Aminon → off; `/dt` `/mdt` `/aminon` toggle one |
| `/sir` | `SIR` set over spell midcasts (not `SIRSkip`) |
| `/kite` | Movement gear |
| `/autogear [regen\|refresh\|dt\|petdt N]` | Auto Regen/Refresh/DT idle sets by HP/MP %; no word shows the thresholds |
| `/lock [slots\|all]` `/unlock [slot]` | Freeze slots (none named: Main, Sub, Ammo); `/unlock` says what else holds one |
| `/naked` `/weaponsonly` `/abysseaproc` | Keep all 16 / armor / head-hands-legs-feet bare |
| `/rrset` `/craftset` `/zeniset` `/fishset` | Reraise / crafting / Zeni / fishing set over everything until toggled off |
| `/received <spell>` | Wear that `*_Received` set |

**Magic**
| Command | Does |
|---|---|
| `/nukeset [power\|macc\|oa]` | Nuke sets (RDM GEO: `oa` = OccultAcumen) |
| `/automb` (`/autonuke`, `/mbmode`) | Cast into live skillchains by itself (RDM BLM SCH GEO) |
| `/mbtier [1-5]` | Its tier I to V; no word: next |
| `/burst` | Burst set on every nuke, not only live skillchains |
| `/mbinfo` | Last skillchain seen |
| `/gcaspir` `/gcdrain` | Best castable tier on `<t>` |
| `/nuke <1-6>` `/helix` `/weather` `/elecycle` `/weapon` | BLM/SCH: element's nuke, helix, storm, element, Club ↔ Staff |
| `/death` | BLM Death mode |

**Items, travel and content**
| Command | Does |
|---|---|
| `/autofood` `/autosoda` | Eat food / drink soda when the buff is missing (food: `char.lua` or `gcinclude.AutoFood`) |
| `/packer` | Fetch what inventory lacks of your packer list (Bellhop); also on every job change |
| `/holywater` `/revit` | Holy Water on Doom / per-zone item use (`AutoUseItems`) |
| `/hoxne [off\|use]` | Keep Hoxne Ampulla in Ammo and use it |
| `/gce <item>` / `/gce cancel` | Equip an enchanted item (Volte Harness, Reraise Earring…), wait its delay, use it, free the slot |
| `/warpring` `/mea` `/holla` `/dem` | Warp / Dimensional ring, the same way |
| `/ontic` `/shard` | Use Ontic Extremity / V. Con. Shard (more: `gcinclude.ExitItems`) |
| `/temps` | Every carried Escha drink |
| `/capacity` `/jubilee` `/dynamisrp` | Hold capacity cape / Jubilee Ring / Dynamis job neck |
| `/ejenter [chamber]` `/ejlamps` `/ejexit` | Einherjar (Ashita): reserve, lamps to the party, enter, leave |

**Jobs**
| Command | Does |
|---|---|
| `/tankset` | PLD RUN: None → Main → MEVA |
| `/proc` | SAM NIN: proc set |
| `/pupmode` | PUP: Tank → Melee → Ranger → Mage |
| `/forcestring` `/songlock` | BRD: force harp / enemy songs keep main-sub |
| `/cormsg` `/xiroll` | COR: roll messages / roll tracking |
| `/siphon` | SMN: Elemental Siphon with the day's spirit |

**Display and help**
| Command | Does |
|---|---|
| `/gchud [on\|off\|large\|compact\|pos X Y\|debug]` | The multibox HUD (see HUD below) |
| `/gcbar [on\|off\|pos X Y]` | One-line status bar |
| `/gcmodes [all]` | This box's modes and toggles in chat; `all`: every box |
| `/checksets` | Empty sets, bad item names |
| `/gctrace` | What each action wore (and its obi/Orpheus pick) |
| `/gcstyle [N]` | Lockstyle set now |
| `/gcmessages` | Chat confirmations on/off |
| `/gchelp` / `/gckey <key> <cmd>` | Command list in game / bind a key |

Picking a value, any case: no word = next; else exact name, the one it starts, its initials, the one containing it, or
a number: `/wm max` (Maxentius), `/nukeset oa` (OccultAcumen), `/mmode sb` (SubtleBlow), `/wm 3`. Two matches: it lists them.

Keys: Ctrl+grave `/wm`, Shift+grave `/wm default`, Ctrl+Shift+grave `/def`, Alt+grave `/hoxne`, Win+grave `/automb`.
`/gckey <key> <cmd>` rebinds.

## HUD (multibox)

Every box running GoomSwap writes its modes 4x/s (`luashitacast/hud/`; Windower: over IPC); one box shows them all.

- **Who gets the grid:** in `common/gcinclude.lua` settings, `HUDOwners = T{'YourMain'};` (per character: `settings` in
  `char.lua`). Those characters open it on load with every box; on any other box `/gchud` shows only that box's line.
  Empty list: any box's `/gchud` shows every box.
- **Use:** click a cell = run it on that box; click a name = its hidden modes; Ctrl+click `mb` = tier. The owner also
  prints the other boxes' GoomSwap lines as `[Name]` (`HUDMessages = false` to stop).
- **Commands:** `/gchud` (on/off), `/gchud large|compact`, `/gchud pos X Y`, `/gchud debug`. Drag to move; saved per character.
- **Layout:** top left; `HUDOwners` first, then party order. The owner sees its own line until the mouse is over the HUD,
  then every box (`HUDHover = false`: always all). Every column a box's job has always shows, so the width never changes.
  Name colour: blue SIR, gold TH, green kite, red PROC. Food, soda, harp, song lock, death: a chat line when they change.
  A box on `/wsset high` shows its `melee` cell purple; `/hoxne` on, its `wpn` cell teal. `HUDAbbr` shortens values.

## How sets stack

Later wins, slot by slot; a set changes only the slots it lists.

**Idle / engaged**, lowest to highest:
1. Your job file: `Idle` / `Tp_Default` → `Tp_<mset>` → buff sets (`Impetus`) → `Dt` (`/dt`) → `Movement` (`/kite`).
2. Hoxne sets → auto `Idle_Regen` / `Idle_Refresh` / `Dt` (low HP/MP) → `Town`.
3. Weapon mode (not engaged: only the weapon slots your idle sets leave empty; `IdleWeapons = false` = all) → `mdt` (`/mdt`) or `Aminon` (`/aminon`) → Hoxne Ampulla → `TH` → `*_Received` → `Buffs` → XIRoll.
4. **`Incapacitated`** (slept, petrified, stunned, terrorized): `Aminon` if `/aminon` is on, else `mdt` if `/mdt`,
   else `Dt` (even with `/dt` off), without Main/Sub/Range/Ammo; then the `Incapacitated` set, then `*_Received`. **Over DT, MDT, Aminon,
   TH, Buffs and everything in 1-3.**
5. `Sleeping` (asleep) → `Doomed` → `Reraise` (Weakness) → craft / zeni / fish / rr sets.

**Spells (midcast):** your job file → `TH` (not `THSkip`) → its `_Self` / `_Others` / `_Burst` sets → `Absorb` (TH back on top) → `Buffs_Midcast` →
`LightBonus` → obi/Orpheus/back/ring (a `TH` waist stays) → `SIR` (`/sir`, not `SIRSkip`). WHM cures:
`Cure` → `Self_Cure` → `Cure_LowMP` or `Cure_LowMP_Storm` (MP ≤ 50%) → `Cure_Dt` (`/dt`) → Hachirin-no-Obi → `SIR`.

**Weapon skills:** your job file → its `_HighBuff` sets (`/wsset high`) → Hoxne sets → `Buffs_Ws` → Moonshade → obi/Orpheus/back.

Defense toggles change idle/engaged gear only (`/aminon` also locks weapons); a spell wears DT gear only where the
job file says so (WHM `Cure_Dt`).
All engine sets: `COMMANDS.md` Sets the engine uses.

## Exclusions: SIRSkip and THSkip

Two lists of spells the engine leaves alone, so the set your job file put on for them is what you cast in:

| List | Stops | Default |
|---|---|---|
| `SIRSkip` | `/sir` putting the `SIR` set over that spell's midcast | `'Absorb-TP', 'Stun'` |
| `THSkip` | `/th` putting the `TH` set over it at an untagged mob (and it won't count as the tag) | `'Absorb-TP', 'Stun'` |

Only that one layer is skipped: Aminon's weapon lock, obi/Orpheus and `Buffs_Midcast` still apply as usual.

**Add a spell, one job:** top of the job file, under the `gcinclude = gFunc.LoadFile(...)` line. Adds to the
default list:

```lua
gcinclude.SIRSkip = T{'Phalanx', 'Reprisal'};   -- PLD: Phalanx keeps its potency gear, Reprisal its own 105 SIR set
gcinclude.THSkip  = T{'Absorb-STR', 'Absorb-ACC'}; -- example: these keep their own macc set at a new mob
```

**Add or remove, every job:** edit the line in `common/gcinclude.lua` settings:

```lua
SIRSkip = T{'Absorb-TP', 'Stun'};
THSkip  = T{'Absorb-TP', 'Stun'};
```

**Remove a default, one job:** in that job's `OnLoad`, before `gcinclude.Initialize()`, replace the list:
`gcinclude.settings.SIRSkip = T{'Absorb-TP'};` (now `/sir` covers Stun on this job).

- Exact spell name, any case: `'Cure IV'`; `'Cure'` matches only Cure I. List every tier you want.
- A spell that needs SIR *and* its own stats: put the SIR pieces in its own set and add it to `SIRSkip` (PLD
  `Reprisal`). Spells not on the list get `SIR` over them (PLD `Cure`, `Protect`).
- Check what's active: `/gchelp` prints both lists for the current job. `/lac reload` after editing.

## Something wrong

| Problem | Check |
|---|---|
| Edit does nothing | `/lac reload` (`//gs reload`) |
| Windower: nothing loads | Red `[GoomSwap]`/`[LuAshitacast]` line: do what it says. No `[GoomSwap]` line at all: see Install |
| Windower: `attempt to index global 'gFunc'` or `GearSwap loaded this job file directly` | Job file is in `data/<Name>/` (GearSwap's own spot): move it to `data/goomswap/<Name>/<JOB>.lua`, delete `data/<Name>/` |
| A slot won't change | `/unlock` (it names other holders: `/aminon off`, `/hoxne off`…); weapons are held at `WeaponTPGuard`+ TP and while Aftermath is up (`/wm <mode>` swaps; `/wm <current mode> force` re-applies); `TH`-set weapon while `/th` is on (THF) |
| Weapon in TP set never shows | Engaged, the weapon mode wins: `/wm none`, and `/mainset none` / `/subset none` for slot picks (PLD has only those). Out of combat your idle sets' weapons win (`IdleWeapons = false` to stop) |
| Wrong or no gear | `/checksets`, item spelling, `/gctrace` |
| Action cancelled | Chat says why (`COMMANDS.md` Action checks) |
| HUD gone | `/gchud on`, `/gchud pos 500 120` |
