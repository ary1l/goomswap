# ShaySwap

LuAshitacast gear engine for multiboxing: you fill in sets, it picks the gear. Runs on Ashita v4, and on
Windower 4 through the GearSwap adapter in `windower/`. Full reference: `COMMANDS.md`.

## Install

### Ashita v4 (LuAshitacast)

1. Copy `common/` and `examples/` into `Ashita/config/addons/luashitacast/`.
2. Copy `examples/<JOB>.lua` into your character folder (`luashitacast/<Name>_<id>/`) and put in your gear.
3. `/addon load luashitacast`, then `/lac load` (or change job). After edits: `/lac reload`.

### Windower 4 (GearSwap)

```
Windower/addons/GearSwap/data/
├── default.lua                  <- windower/GearSwap/data/default.lua
└── shayswap/
    ├── core.lua, ashita.lua, imgui.lua   <- windower/GearSwap/data/shayswap/
    ├── common/                  <- common/
    └── <Name>/<JOB>.lua         <- examples/<JOB>.lua, with your gear
```

1. Copy as above. `shayswap/<JOB>.lua` (no name folder) is used by every character; an Ashita
   `<Name>_<id>/` folder copied over as is works too.
2. `//lua load gearswap`, then change job (or `//gs reload`). Chat: `[ShaySwap] Loaded data/shayswap/<Name>/<JOB>.lua`.

- No `[ShaySwap]` line: GearSwap runs `default.lua` only for a job with no GearSwap file of its own.
  `data/<Name>/<JOB>.lua`, `data/<Name>_<JOB>.lua`, `data/<Name>.lua` and `data/<JOB>.lua` all win. Never put a
  ShaySwap job file there (GearSwap runs it itself and it fails on `gFunc`).
- Already use `default.lua`? Save ours as `data/<Name>_<JOB>.lua` for each job that should run ShaySwap.
- Commands take two slashes: `//wm` (or `//gs c wm`); all boxes `//send @all gs c <cmd>` (Send addon).
- Updating: replace `shayswap/common/` and `shayswap/*.lua`.
- Differences: HUD and bar are display only (commands; drag to move; boxes on one PC share HUD state over IPC).
  Auto-nuke casts at the mob without targeting it. `//gs org` needs Organizer. The bar shows Atk/Def as 0.

## Quick start

1. Fill `Idle`, `Tp_Default`, `Ws_Default`. Everything else can wait. `/checksets` finds empty sets and bad item names.
2. Template jobs (BLM BST DNC DRG DRK NIN PUP RUN SAM SMN WAR): a set named after an action (`['Savage Blade']`)
   is used for it; a spell with no set uses its family's (`['Cure']` for Cure IV). `_Hybrid`/`_Acc` follow
   `/meleeset`. Other jobs name their sets in the job file. Their example gear is from
   [GetAwayCoxn's Luashitacast-Profiles](https://github.com/GetAwayCoxn/Luashitacast-Profiles) (MIT,
   `examples/LICENSE-GetAwayCoxn.txt`): swap in your own.
3. Leave `gSettings.FastCast` at 0 (`COMMANDS.md` Fast Cast).
4. Worth copying: `WHM.lua` cures (weapons by MP and Light weather, `Cure_Dt` while `/dt` is on), `MNK.lua`
   Hoxne sets, PLD shields with `/subset`.

## Keys

| Key | Does |
|---|---|
| Ctrl+grave | Next weapon mode (`/wm`) |
| Shift+grave | Default weapons |
| Ctrl+Shift+grave | `/def`: DT → MDT → Aminon → SIRD |
| Alt+grave | `/hoxne` |
| Win+grave | `/automb` |

`/gchelp` lists the main commands (all of them: `COMMANDS.md`). `/gckey <key> <cmd>` rebinds.

## What it does

- **Weapons**: modes per job (`/wm`) and per slot (`/mainset` `/subset`...). Held at 1000+ TP; `_1h` sets when
  you can't dual wield.
- **Layers**, lowest to highest: your sets → Hoxne sets → weapons → MDT/Aminon → Hoxne Ampulla → TH → received
  gear → buff sets → XIRoll → debuff and craft sets. Midcast: job sets → TH → `Buffs_Midcast` → Absorb →
  LightBonus → obi/Orpheus/back/ring → SIR. Details: `COMMANDS.md` Sets the engine uses.
- **Automatic**: obi/Orpheus/Twilight Cape/Zodiac Ring by day, weather and distance; a Sub that can't go with the
  Main is dropped; Hoxne Ampulla use; ammo and tool warnings; `Incapacitated`/`Sleeping` sets; Moonshade on WS;
  Holy Water on Doom; food and soda; `/th`; lockstyle.
- **Action checks**: actions that would fail are cancelled before gear moves, with the reason in chat.
- **Holds**: `/naked` `/weaponsonly` `/abysseaproc`, `/capacity` `/jubilee` `/dynamisrp`.
- **Magic burst** (RDM BLM SCH GEO): Burst set inside a live skillchain; `/automb` casts the chain's nuke.
- **Received gear**: `*_Received` sets while a Cure, Phalanx, Protect, Shell, Regen, Refresh or Cursna is on its way to you.
- **Multibox**: `/mss /lac fwd <cmd>` on every box; `/gchud` shows one line per box.

## Something wrong

| Problem | Check |
|---|---|
| Edit does nothing | `/lac reload` (Windower: `//gs reload`) |
| Windower: nothing loads | No `[ShaySwap] Loaded` line: see Install, Windower |
| A slot won't change | `/unlock`, or it's a weapon held at 1000+ TP (`/wm <mode> force`), or a `TH`-set weapon while `/th` is on |
| Weapon in Idle/TP/Town never shows | Weapon mode overrides it at rest; `/wm none` to manage weapons yourself. `/th` on: `TH`-set weapons override both |
| Wrong/no gear | `/checksets`, then the item name spelling; `/gctrace` names each set used |
| Action cancelled | The chat line says why. See Action checks in `COMMANDS.md` |
| HUD gone | `/gchud on`, `/gchud pos 500 120` |
