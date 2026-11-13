# GoomSwap on Windower

[← Back to the README](../README.md)

The same job files as on Ashita, run through GearSwap.

## Install

```
Windower/addons/GearSwap/data/
├── default.lua                        <- windower/GearSwap/data/default.lua
└── goomswap/
    ├── core.lua ashita.lua imgui.lua  <- windower/GearSwap/data/goomswap/
    ├── common/                        <- common/
    ├── examples/                      <- examples/ (optional: for /gcbuild and the Selindrile migration)
    └── <Name>/<JOB>.lua               <- examples/<JOB>.lua, your gear in it
```

`//lua load gearswap`, then change job. Chat should say `[GoomSwap] Loaded data/goomswap/<Name>/<JOB>.lua`.

- **Red line:** a missing file; do what it says.
- **No `[GoomSwap]` line:** GearSwap found another file first (`data/<Name>/<JOB>.lua`, `data/<Name>_<JOB>.lua`,
  `data/<Name>.lua` and `data/<JOB>.lua` all beat `default.lua`).
- A job file in `goomswap/` itself serves every character.

| | Ashita | Windower |
|---|---|---|
| Command | `/wm` | `//wm`, `//gs c wm` |
| All boxes | `/mss /wm` (Multisend) | `//send @all gs c wm` |
| Reload | `/lac reload` | `//gs reload` |
| Augments | `{ Name = 'X', Augment = {...} }` | same line works (closest copy); or `{ name="X", augments={...} }` from `//gs export`, exact |
| 2 of one item | nothing to do | give each copy its bag (below) |

## Two of one item

**Two of one item** (2 Stikini Ring +1, twin earrings, same weapon Main+Sub): by name alone GearSwap can
grab the copy worn in the other slot and the two swap places. Pin each:

```lua
Ring1 = { Name = 'Stikini Ring +1', Bag = 'Wardrobe' },   -- 'wardrobe1' works too
Ring2 = { Name = 'Stikini Ring +1', Bag = 'Wardrobe2' },
```

Bags: `Inventory`, `Wardrobe` … `Wardrobe8`, any case. Spelled `Wardrobe` … `Wardrobe4` the line works on Ashita too.

## Augments

**Augments:** wear the gear, `//gs export` (or `//gs export copy`), paste into the set, capitalize the slot
(`back=` → `Back =`).

## Coming from Selindrile

1. Install as above with the `examples/` folder, plus `goomswap_migrate.lua` next to `default.lua`.
2. On the character: `//gs load goomswap_migrate`. Each `data/<Name>/<Name>_<Job>_Gear.lua` becomes
   `data/goomswap/<Name>/<JOB>.lua` plus a one-line `data/<Name>/<JOB>.lua` that loads GoomSwap. Re-run replaces its
   own earlier file (old one kept as `.lua.bak`); a file you wrote stays, new one is `.migrated.lua`. Selindrile files
   are only read.
3. `//gs reload`, `//gs c checksets`. Back to Selindrile: delete `data/<Name>/<JOB>.lua`.

Each new file starts with a summary: how many sets were placed, what was left out and why.

**Where your sets go**

| Selindrile | GoomSwap |
|---|---|
| `idle` `.Refresh` `.Regen` `.Regain`, `resting`, `Kiting`, `TreasureHunter` | `Idle` `Idle_Refresh` `Idle_Regen` `Idle_Regain`, `Resting`, `Movement`, `TH` |
| `engaged` `.<OffenseMode>` | `Tp_Default` `Tp_<mode>`; OffenseMode = `/mset` list |
| `defense.PDT` `.MDT` (else `.MEVA`) | `Dt` `mdt` |
| `precast.FC`, `FC.Cure`, `FC['Enhancing Magic']`, `FC.Impact` | `Precast`, `['Healing Magic_Precast']`, `['Enhancing Magic_Precast']`, `Impact_Precast` (skill or spell family + `_Precast`) |
| `precast.WS` `['Savage Blade']` `.Acc` | `Ws_Default`, `['Savage Blade']`, `['Savage Blade_Acc']` |
| `precast.WS.Proc`; `precast.WS['Savage Blade'].PDL` | `Ws_Proc` (`/proc`); `['Savage Blade_HighBuff']` (`/wsset high`) |
| `precast.JA[...]`, `midcast.Cure`, `midcast['Enhancing Magic']` | the template's set, else by name |
| `midcast.RA` `.Acc`; `midcast['Elemental Magic'].OccultAcumen` | `Midshot` `Midshot_Acc`; `OccultAcumen` |
| `weapons.<Name>` + `state.Weapons` | `Weapon_<Name>` + `/wm` modes |
| `buff.Doom` `.Sleep`, `Cure_Received`... | `Doomed` `Sleeping` `Cure_Received`... |

**What else it does**

- **No GoomSwap place** (`.DT` hybrids, `Resistant`, latent sets, other WS-only modes, a set the job's template
  never wears such as `Enmity` or `buff['Sneak Attack']` off PLD/THF...): kept as `['Sel_<path>']`, unused until
  you rename it.
- **Moonshade Earring** is taken out of weapon skill sets: GoomSwap wears it itself under `MoonshadeTP`. The set's
  other earring is put in Ear1 so both are worn.
- **Sets from your Globals/Items files** with no GoomSwap place (`Capacity`...) are named once in the summary, not
  copied into every job.
- **Binds** become that job's `Keybinds`: chat commands as is, modes mapped (`Weapons`→`wm`, `OffenseMode`→`mset`,
  `IdleMode`→`idleset`, `HybridMode`→`tankset`, `RangedMode`→`rangedset`, `CastingMode`→`nukeset` or `sir`,
  `gs reload`→`/lac reload`).
- **Left out:** defense keys and Selindrile automation (`AutoWSMode`, `SkillchainMode`...); the file's top comment
  lists what was.

