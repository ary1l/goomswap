# ShaySwap

Gear-swap engine for FFXI multiboxing. You write sets in a job file; ShaySwap wears them for idle, TP,
spells and weapon skills, and adds the automatic layers (weapons, defense, obi, TH, and more) on top.
Runs on **Ashita v4** (LuAshitacast) and **Windower 4** (GearSwap, through the adapter in `windower/`).
Same job files on both. Every command and setting: [`COMMANDS.md`](COMMANDS.md).

## Install

### Ashita v4

1. Copy `common/` and `examples/` into `Ashita/config/addons/luashitacast/`.
2. Copy `examples/<JOB>.lua` into your character folder `luashitacast/<Name>_<id>/` and put in your gear.
3. `/addon load luashitacast`, then `/lac load`.

### Windower 4

```
Windower/addons/GearSwap/data/
├── default.lua                        <- windower/GearSwap/data/default.lua
└── shayswap/
    ├── core.lua ashita.lua imgui.lua  <- windower/GearSwap/data/shayswap/
    ├── common/                        <- common/
    └── <Name>/<JOB>.lua               <- examples/<JOB>.lua, your gear in it
```

1. Copy as above. A job file straight in `shayswap/` is used by every character; an Ashita `<Name>_<id>/`
   folder copied over as is also works.
2. `//lua load gearswap`, then change job. Chat shows `[ShaySwap] Loaded data/shayswap/<Name>/<JOB>.lua`.

No `[ShaySwap]` line means GearSwap found another file first: `data/<Name>/<JOB>.lua`, `data/<Name>_<JOB>.lua`,
`data/<Name>.lua` and `data/<JOB>.lua` all beat `default.lua`. Never put a ShaySwap job file in those places.
Already use `default.lua` for other jobs? Copy ours to `data/<Name>_<JOB>.lua` for each ShaySwap job instead.

## Ashita vs Windower

| | Ashita | Windower |
|---|---|---|
| Command | `/wm` | `//wm` or `//gs c wm` |
| All boxes | `/mss /lac fwd wm` (Multisend) | `//send @all gs c wm` (Send addon) |
| Reload after editing | `/lac reload` | `//gs reload` |
| Keys | below | same keys |
| HUD (one line per box) | `/gchud`; click a cell to change it on that box | `//gchud`; display only (no clicks), drag to move |
| Status bar | `/gcbar` | `//gcbar`; Atk/Def show 0 |

The HUD opens by itself for names in `gcinclude.settings.HUDOwners`; otherwise `/gchud on` (`//gchud on`).
On Windower, boxes on the same PC share HUD state over IPC, `/automb` casts at the mob without targeting it, and
`profile.Packer` goes to `//gs org` (needs the Organizer addon).

## First steps

1. Fill `Idle`, `Tp_Default` and `Ws_Default`. The rest can wait.
2. `/checksets` lists empty sets and item names it can't find. `/gctrace` shows which sets each action used.
3. Leave `gSettings.FastCast` at 0.
4. Template jobs (BLM BST DNC DRG DRK NIN PUP RUN SAM SMN WAR) use a set named after the action
   (`['Savage Blade']`); a spell with no set of its own uses its family's (`['Cure']` for Cure IV). Other jobs name their sets in the job file. Example gear in
   template jobs is from [GetAwayCoxn](https://github.com/GetAwayCoxn/Luashitacast-Profiles) (MIT,
   `examples/LICENSE-GetAwayCoxn.txt`).

Examples worth copying: `WHM.lua` cures (weapons by MP% and Light weather, `Cure_Dt` while `/dt` is on; same hooks,
empty, in `SCH.lua`, `RDM.lua`, `GEO.lua`),
`MNK.lua` Hoxne sets, `PLD.lua` shields with `/subset`.

## Everyday commands

| Command | Does |
|---|---|
| `/wm [name]` | Weapon mode: next, or by name. `/wm default`, `/wm none` (hands off weapons) |
| `/mainset` `/subset` `[name]` | One slot's weapon, e.g. PLD `/subset duban`. Add `force` at 1000+ TP |
| `/meleeset` or `/mset [hybrid\|acc\|default]` | Wear `_Hybrid` / `_Acc` versions of TP and WS sets |
| `/def` | Defense: DT → MDT → Aminon → off (one at a time). `/dt` `/mdt` `/aminon` toggle one directly |
| `/sir` | Casting mode: `SIR` set over every spell's midcast except `SIRSkip` (Absorb-TP, Stun, plus the job's own: PLD adds Phalanx, Reprisal). Works with DT/MDT; Aminon turns it off |
| `/th` | TH gear until the mob is tagged |
| `/kite` | Movement gear |
| `/hoxne` | Off → Locked: Hoxne Ampulla kept in ammo and used |
| `/automb` | Auto magic burst (RDM BLM SCH GEO) |
| `/lock [slots]` `/unlock` | Freeze slots |
| `/gchelp` | Command list in game |

| Key | Does |
|---|---|
| Ctrl+grave | `/wm` |
| Shift+grave | `/wm default` |
| Ctrl+Shift+grave | `/def` |
| Alt+grave | `/hoxne` |
| Win+grave | `/automb` |

`/gckey <key> <cmd>` rebinds.

## How sets stack

Later wins, slot by slot. A set only changes the slots it lists.

**Idle / engaged:** your job file (`Idle` → `Tp_Default` → `Tp_<mset>` → buff sets like `Impetus` → `Dt` if `/dt`
→ `Movement` if `/kite`) → Hoxne sets → auto `Idle_Regen`/`Idle_Refresh`/`Dt` → `Town` → weapon mode → `mdt` or
`Aminon` → Hoxne Ampulla → `TH` → `*_Received` → `Buffs` → XIRoll → debuff and craft sets.

**Spells (midcast):** your job file → `TH` → `Buffs_Midcast` → `Absorb` → `LightBonus` → obi/Orpheus/back/ring →
`SIR` if `/sir`. WHM cure in `examples/WHM.lua`:

```
Cure → Self_Cure → Cure_LowMP or Cure_LowMP_Storm (MP <= 50%) → Cure_Dt (/dt) → Hachirin-no-Obi (Light) → SIR (/sir)
```

`SIR` goes on last (never on `SIRSkip` spells), so every slot it lists wins, even over `Cure_Dt` and the obi. Leave a slot out of `SIR`
to keep the cure or DT piece. `/dt` only touches spells where the job file says so (WHM: `Cure_Dt`).

**Weapon skills:** your job file → Hoxne sets → `Buffs_Ws` → Moonshade → obi/Orpheus/back.

Full list of engine sets: `COMMANDS.md` Sets the engine uses.

## SIR set and SIRSkip

`/sir` is a casting mode (separate from `/def`, engaged or not). While it's on:

- On every spell's **midcast**, the `SIR` set goes on **last**: after your job file's midcast sets and after every
  engine layer (TH, `Buffs_Midcast`, Absorb, LightBonus, obi/Orpheus).
- Only the slots `SIR` lists change, and those slots win for that cast (its waist replaces the obi, its ring
  replaces your cure ring). Slots it leaves out keep the spell's own gear. Precast and idle are never touched.
- Off: the engine never wears `SIR`. A job file can still use `sets.SIR` itself (PLD puts it on first for every
  spell as a base, `/sir` or not).
- Aminon: turning Aminon on (`/aminon`, `/def`) turns `/sir` off, and `/sir` is refused while Aminon is on. It stays
  off when Aminon goes off.

**`SIRSkip`** is the list of spells `/sir` leaves alone, so the spell's own set stands as the job file put it.
Use it for spells where the set's own stats matter more than not being interrupted (Stun and Absorb-TP need
magic accuracy; Phalanx needs its potency gear):

```lua
-- common/gcinclude.lua, every job:
SIRSkip = T{'Absorb-TP', 'Stun'};

-- top of a job file, that job only (adds to the list above):
gcinclude.SIRSkip = T{'Phalanx', 'Reprisal'};
```

Names are exact spell names in any case (`'Cure IV'`, not `'Cure'`). The job file's list adds to the shared one;
it doesn't replace it.

**Per-spell SIR sets.** The engine has one `SIR` set. When a spell needs SIR *and* its own stats, put the SIR gear
in that spell's set in the job file and add the spell to `SIRSkip`, so `/sir` doesn't cover it. PLD does this:

- `SIR`: worn by PLD.lua first on every spell, `/sir` or not.
- `Reprisal` (105 SIR, Enmity) and `Phalanx` (potency): in PLD's `SIRSkip`, so their sets stay as built.
- `Cure` (98% SIR, cure potency) and Protect (uses `Reprisal`): not in `SIRSkip`, so `/sir` still lays `SIR` over
  them.

## Auto magic burst tier (`/mbtier`)

RDM, BLM, SCH and GEO only. `/automb` (Win+grave) makes the box cast the skillchain's nuke by itself; `/mbtier`
picks which tier it casts.

| `/mbtier` | Casts |
|---|---|
| `low` (or `1`) | Tier I (Fire, Blizzard, Aero, Stone, Thunder, Water) |
| `mid` (or `3`) | Tier III. The default |
| `high` (or `5`) | Tier V |
| nothing | Cycles Low → Mid → High |

- Can't cast that tier (not learned, on recast, short MP; SCH IV/V without Addendum: Black or Enlightenment)? It
  tries the next tier down on each chain element, down to I. `MBFallback = false` stops that.
- Light and Dark chains have no tiered nuke: SCH casts Luminohelix / Noctohelix.

How to change it:

| Where | How |
|---|---|
| This box, now | `/mbtier high` (Windower `//mbtier high`) |
| Every box, now | `/mss /lac fwd mbtier high` (Windower `//send @all gs c mbtier high`) |
| HUD (Ashita) | Ctrl+click that box's `mb` cell: I → III → V |
| A key | `/gckey !m mbtier` (Alt+M cycles it) |
| Load default, every job | `MBTier = 'Mid';` in `common/gcinclude.lua` settings |
| Load default, one job | `gcinclude.MBTier = 'High';` in that job's `OnLoad`, before `gcinclude.Initialize()` |

A tier set with the command lasts until reload or job change, then the load default comes back.

## Settings: `common/gcinclude.lua`

Two blocks at the top of the file are yours to edit; everything below them is the engine.

- **`gcinclude.sets`**: sets every job shares. `Doomed`, `Holy_Water`, `Sleeping` (a job's own `Sleeping` wins),
  `Reraise` (worn while Weakened), `Crafting` (`/craftset`), `Zeni` (`/zeniset`), `Fishing` (`/fishset`).
- **`gcinclude.settings`**: options, one per line, each with a comment saying what it does.

| Area | Settings |
|---|---|
| Auto idle sets | `AutoGear`, `RegenGearHPP`, `RefreshGearMPP`, `DTGearHPP`, `PetDTGearHPP` |
| Weapons and TP | `WeaponTPGuard`, `HoldExemptSkills`, `HoldExemptAbilities`, `SmartSwap`, `SmartSwapTP`, `NoWeaponSpells`, `KeepWeaponsFor` |
| Weapon skills | `WScheck`, `WSdistance`, `MoonshadeTP`, `MoonshadeSlot`, `MoonshadeSkip`, `ElementalWS` |
| Casting | `SIRSkip`, `ElementGear` (obi, Orpheus, ring, back, cures), `ElementSkills`, `OrpheusPoints` |
| Magic burst | `AutoNuke`, `MBTier`, `MBCasts`, `MBRotate`, `MBMinMP`, `MBWindow`, `MBFallback`, `MBSkills` |
| Items and food | `AutoFood`, `AutoFoodItems`, `AutoSoda`, `SodaItem`, `AutoHolyWater`, `HolyWaterItem`, `AutoRevitalizer`, `AutoUseItems`, `EnchantDelays`, `EnchantWindow`, `ConsumableMaxTries` |
| Hoxne | `HoxneItem`, `HoxneLockSlots`, `HoxneAutoUse` |
| Received gear | `ReceivedSets`, `ReceivedWindow`, `MyBoxes` |
| Action checks | `Validate`, `ValidateMP`, `AutoRemedy`, `WaltzTPCut`, `MiniQueue`, `MiniQueueMax` |
| HUD and bar | `HUDOwners`, `HUDX`, `HUDY`, `HUDStyle`, `HUDScale`, `HUDScaleLarge`, `HUDAlpha`, `HUDPinned`, `HUDAbbr`, `HUDLabels`, `DisplayBar`, `DisplayBarX`, `DisplayBarY` |
| Other | `Keybinds`, `Messages`, `Trace`, `LockstyleSet`, `CombatWindow`, `XIRollSet`, `CapacityCapes`, `JubileeSlot`, `AmmoWarn`, `NinjaToolWarn`, `SleepCancelStoneskin`, `ElementReport`, `warp_Ring` `mea_Ring` `dem_Ring` `holla_Ring` |

**Every job or one job:**

- Every job: change the value in `gcinclude.lua`. Copying a newer `common/` over it erases your edits, so keep a
  note of them (or set them per job instead).
- One job: in that job file's `OnLoad`, before `gcinclude.Initialize()`, e.g. `gcinclude.settings.RefreshGearMPP = 50;`
  (`WHM.lua` does `gcinclude.settings.KeepWeaponsFor = T{};`).
- Per-job values on `gcinclude` itself win over the setting: `gcinclude.MBTier`, `gcinclude.AutoFood`,
  `gcinclude.LockstyleSet`, `gcinclude.ElementGear`. `gcinclude.SIRSkip` adds to `settings.SIRSkip` (PLD adds
  Phalanx and Reprisal).
- Weapon modes, default weapons and the rest of job setup: `COMMANDS.md` Job file.

## Something wrong

| Problem | Check |
|---|---|
| Edit does nothing | `/lac reload` (Windower: `//gs reload`) |
| Windower: nothing loads | No `[ShaySwap] Loaded` line: see Install, Windower |
| A slot won't change | `/unlock`; a weapon at 1000+ TP is held (`/wm <mode> force`); a `TH`-set weapon while `/th` is on |
| Weapon in Idle/TP never shows | The weapon mode overrides it: `/wm none` to manage weapons yourself |
| Wrong or no gear | `/checksets`, item spelling, `/gctrace` |
| Action cancelled | The chat line says why (`COMMANDS.md` Action checks) |
| HUD gone | `/gchud on`, `/gchud pos 500 120` |
