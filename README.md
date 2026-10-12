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

Examples worth copying: `WHM.lua` cures (weapons by MP% and Light weather, `Cure_Dt` while `/dt` is on),
`MNK.lua` Hoxne sets, `PLD.lua` shields with `/subset`.

## Everyday commands

| Command | Does |
|---|---|
| `/wm [name]` | Weapon mode: next, or by name. `/wm default`, `/wm none` (hands off weapons) |
| `/mainset` `/subset` `[name]` | One slot's weapon, e.g. PLD `/subset duban`. Add `force` at 1000+ TP |
| `/meleeset` or `/mset [hybrid\|acc\|default]` | Wear `_Hybrid` / `_Acc` versions of TP and WS sets |
| `/def` | Defense: DT → MDT → Aminon → SIRD → off (one at a time) |
| `/dt` `/mdt` `/sir` | Toggle one directly (`/dt` and `/sir` can both be on) |
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

`SIR` goes on last, so every slot it lists wins, even over `Cure_Dt` and the obi. Leave a slot out of `SIR`
to keep the cure or DT piece. `/dt` only touches spells where the job file says so (WHM: `Cure_Dt`).

**Weapon skills:** your job file → Hoxne sets → `Buffs_Ws` → Moonshade → obi/Orpheus/back.

Full list of engine sets: `COMMANDS.md` Sets the engine uses.

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
