# ShaySwap

Gear-swap engine for FFXI multiboxing. You write sets in a job file; ShaySwap wears them and adds automatic
layers (weapons, defense, TH, obi, and more) on top. **Ashita v4** (LuAshitacast) and **Windower 4** (GearSwap,
through `windower/`), same job files. Full reference: [`COMMANDS.md`](COMMANDS.md).

## Install

**Ashita v4**
1. Copy `common/` and `examples/` into `Ashita/config/addons/luashitacast/`.
2. Copy `examples/<JOB>.lua` into your character folder `luashitacast/<Name>_<id>/`, put your gear in.
3. `/addon load luashitacast`, then `/lac load`.

**Windower 4**

```
Windower/addons/GearSwap/data/
├── default.lua                        <- windower/GearSwap/data/default.lua
└── shayswap/
    ├── core.lua ashita.lua imgui.lua  <- windower/GearSwap/data/shayswap/
    ├── common/                        <- common/
    └── <Name>/<JOB>.lua               <- examples/<JOB>.lua, your gear in it
```

`//lua load gearswap`, change job: chat shows `[ShaySwap] Loaded data/shayswap/<Name>/<JOB>.lua`. No such line =
GearSwap found another file first (`data/<Name>/<JOB>.lua`, `data/<Name>_<JOB>.lua`, `data/<Name>.lua`,
`data/<JOB>.lua` all beat `default.lua`). A job file straight in `shayswap/` serves every character. Already use
`default.lua` for other jobs? Copy ours to `data/<Name>_<JOB>.lua` for each ShaySwap job instead.

| | Ashita | Windower |
|---|---|---|
| Command | `/wm` | `//wm` or `//gs c wm` |
| All boxes | `/mss /wm` (Multisend) | `//send @all gs c wm` |
| Reload after edits | `/lac reload` | `//gs reload` |
| HUD | `/gchud`, click cells | `//gchud`, display only |

## First steps

1. Fill `Idle`, `Tp_Default`, `Ws_Default`. The rest can wait.
2. `/checksets`: empty sets, misspelled items. `/gctrace`: which sets each action wore.
3. Leave `gSettings.FastCast` at 0.

Template jobs (BLM BST DNC DRG DRK NIN PUP RUN SAM SMN WAR) name sets after the action (`['Savage Blade']`); a spell
with no set uses its family's (`['Cure']` for Cure IV). Template gear is from
[GetAwayCoxn](https://github.com/GetAwayCoxn/Luashitacast-Profiles) (MIT, `examples/LICENSE-GetAwayCoxn.txt`).
Worth copying: `WHM.lua` cures (MP% / Light weather weapons, `Cure_Dt`), `MNK.lua` Hoxne sets, `PLD.lua` `/subset`.

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
| One job, value | Job file; wins over the setting | `gcinclude.MBTier`, `gcinclude.AutoFood`, `gcinclude.LockstyleSet`, `gcinclude.ElementGear`, `gcinclude.CureObi` |

Copying a newer `common/` over yours erases your edits: note them, or set them per job instead.

| Area | Settings |
|---|---|
| Weapons / TP | `WeaponTPGuard`, `HoldExemptSkills`, `HoldExemptAbilities`, `SmartSwap`, `SmartSwapTP`, `NoWeaponSpells`, `KeepWeaponsFor` |
| Casting | `SIRSkip`, `THSkip`, `ElementGear` (obi, Orpheus, ring, back, `Cures`), `ElementSkills`, `OrpheusPoints` |
| Auto idle sets | `AutoGear`, `RegenGearHPP`, `RefreshGearMPP`, `DTGearHPP`, `PetDTGearHPP` |
| Weapon skills | `WScheck`, `WSdistance`, `MoonshadeTP`, `MoonshadeSlot`, `MoonshadeSkip`, `ElementalWS` |
| Magic burst | `AutoNuke`, `MBTier`, `MBCasts`, `MBRotate`, `MBMinMP`, `MBWindow`, `MBFallback`, `MBSkills` |
| Items | `AutoFood`, `AutoFoodItems`, `AutoSoda`, `SodaItem`, `AutoHolyWater`, `HolyWaterItem`, `AutoRevitalizer`, `AutoUseItems`, `EnchantDelays`, `EnchantWindow`, `ConsumableMaxTries` |
| Hoxne | `HoxneItem`, `HoxneLockSlots`, `HoxneAutoUse` |
| Received gear | `ReceivedSets`, `ReceivedWindow`, `MyBoxes` |
| Action checks | `Validate`, `ValidateMP`, `AutoRemedy`, `WaltzTPCut`, `MiniQueue`, `MiniQueueMax` |
| HUD / bar | `HUDOwners`, `HUDX`, `HUDY`, `HUDStyle`, `HUDScale`, `HUDScaleLarge`, `HUDAlpha`, `HUDPinned`, `HUDAbbr`, `HUDLabels`, `DisplayBar`, `DisplayBarX`, `DisplayBarY` |
| Other | `Keybinds`, `Messages`, `Trace`, `LockstyleSet`, `CombatWindow`, `XIRollSet`, `CapacityCapes`, `JubileeSlot`, `AmmoWarn`, `NinjaToolWarn`, `SleepCancelStoneskin`, `ElementReport`, `warp_Ring` `mea_Ring` `dem_Ring` `holla_Ring` |

Weapon modes, default weapons, job helpers: `COMMANDS.md` Job file.

## Everyday commands

| Command | Does |
|---|---|
| `/wm [name]` | Weapon mode: next, or by name. `/wm default`, `/wm none` |
| `/mainset` `/subset` `[name]` | One slot's weapon (PLD `/subset duban`). `force` at 1000+ TP |
| `/mset [hybrid\|acc\|default]` | `_Hybrid` / `_Acc` versions of TP and WS sets (`/meleeset` same) |
| `/def` | DT → MDT → Aminon → off. `/dt` `/mdt` `/aminon` toggle one |
| `/sir` | `SIR` set over spell midcasts (not `SIRSkip`). Aminon turns it off |
| `/th` | `TH` set until the mob is tagged (not `THSkip`) |
| `/kite` | Movement gear |
| `/hoxne` | Off ↔ Locked (ampulla kept in Ammo and used). `/hoxne off` releases it |
| `/automb` | Auto magic burst on/off (RDM BLM SCH GEO) |
| `/mbtier [low\|mid\|high]` | Its nuke tier I / III / V. Load default: `MBTier` setting, or `gcinclude.MBTier` per job |
| `/lock [slots]` `/unlock` | Freeze slots. `/unlock` frees only yours, and says what else holds a slot |
| `/gchelp` | Command list in game |

Keys: Ctrl+grave `/wm`, Shift+grave `/wm default`, Ctrl+Shift+grave `/def`, Alt+grave `/hoxne`, Win+grave `/automb`.
`/gckey <key> <cmd>` rebinds.

## How sets stack

Later wins, slot by slot; a set changes only the slots it lists.

**Idle / engaged**, lowest to highest:
1. Your job file: `Idle` / `Tp_Default` → `Tp_<mset>` → buff sets (`Impetus`) → `Dt` (`/dt`) → `Movement` (`/kite`).
2. Hoxne sets → auto `Idle_Regen` / `Idle_Refresh` / `Dt` (low HP/MP) → `Town`.
3. Weapon mode → `mdt` (`/mdt`) or `Aminon` (`/aminon`) → Hoxne Ampulla → `TH` → `*_Received` → `Buffs` → XIRoll.
4. **`Incapacitated`** (slept, petrified, stunned, terrorized): your defense set (`Aminon`, else `mdt` if `/mdt`,
   else `Dt`) without Main/Sub/Range/Ammo, then the `Incapacitated` set, then `*_Received`. **Over DT, MDT, Aminon,
   TH, Buffs and everything in 1-3.**
5. `Sleeping` (asleep) → `Doomed` → `Reraise` (Weakness) → craft / zeni / fish / rr sets.

**Spells (midcast):** your job file → `TH` (not `THSkip`) → `Absorb` → `Buffs_Midcast` → `LightBonus` →
obi/Orpheus/back/ring → `SIR` (`/sir`, not `SIRSkip`). WHM cures:
`Cure` → `Self_Cure` → `Cure_LowMP` or `Cure_LowMP_Storm` (MP ≤ 50%) → `Cure_Dt` (`/dt`) → Hachirin-no-Obi → `SIR`.

**Weapon skills:** your job file → Hoxne sets → `Buffs_Ws` → Moonshade → obi/Orpheus/back.

Defense toggles change idle/engaged gear only (`/aminon` also locks weapons); a spell wears DT gear only where the
job file says so (WHM `Cure_Dt`).
All engine sets: `COMMANDS.md` Sets the engine uses.

## SIRSkip and THSkip

`/sir` puts `SIR` on last at every spell's midcast; `/th` puts `TH` on at an untagged mob. Spells on these lists are
left alone, so their own set stands:

```lua
-- common/gcinclude.lua settings, every job:
SIRSkip = T{'Absorb-TP', 'Stun'};
THSkip  = T{'Absorb-TP', 'Stun'};
-- top of a job file, adds for that job:
gcinclude.SIRSkip = T{'Phalanx', 'Reprisal'};
```

Exact spell names, any case (`'Cure IV'`, not `'Cure'`). A spell that needs SIR *and* its own stats: build the SIR
gear into its set and add it to `SIRSkip` (PLD `Reprisal`). THSkip spells don't count as the TH tag.

## Something wrong

| Problem | Check |
|---|---|
| Edit does nothing | `/lac reload` (`//gs reload`) |
| Windower: nothing loads | No `[ShaySwap] Loaded` line: see Install |
| A slot won't change | `/unlock` (it names other holders: `/aminon off`, `/hoxne off`…); weapon at 1000+ TP is held (`/wm <mode> force`); `TH`-set weapon while `/th` is on |
| Weapon in Idle/TP never shows | The weapon mode wins: `/wm none` |
| Wrong or no gear | `/checksets`, item spelling, `/gctrace` |
| Action cancelled | Chat says why (`COMMANDS.md` Action checks) |
| HUD gone | `/gchud on`, `/gchud pos 500 120` |
