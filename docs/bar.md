# Status bar and HUD

[← Back to the README](../README.md)

One window. The **bar** shows this box; hover it and every other box **drops in under it**, one line each (the
HUD). Click a line to drive that box.

- **Show:** `/gcbar` (or `DisplayBar = true`). `/gchud` turns the drop on, and the bar with it; `HUDOwners` boxes
  have it on at load.
- **Place:** centred at the top; with the drop on, flush right (room for the lines, clear of status timers). Drag it
  anywhere (saved per character; within 8px of the top it snaps flush); `/gcbar reset` puts it back.
- **Sync:** each box shares its modes when they change (checked 4x/s); the box with the drop reads them twice a
  second (Ashita `luashitacast/hud/`, Windower IPC).

![The status bar with the HUD dropped](gcbar.png)

**A line**, left to right:

| Part | Shows |
|---|---|
| Job / name | Yours: job box (main \| sub outline), `Atk` `Def` (Ashita). Others: name (first half of the letters in the main job's colour, the rest the sub's) and job/levels |
| Weapon | the weapon mode, coloured by its weapon (below); `+` = a slot pick (`/mainset` `/subset` `/rangeset` `/ammoset`) changed |
| Modes | `melee` `ws` `idle` `nuke` `ranged` `tank` `pup` `hoxne`...; blank = that job has no such mode |
| `def`, toggles | `def` (DT / MDT / Aminon), `sir` `th` `kite` `proc`, the job's own (`burst`, `harp`, `lock`...) |

- **Pills:** set or on = coloured outline, tint and dot, showing the value (`acc`, `mp`, `dt`); default or off =
  dashed grey and a ring, showing its name (`melee`, `idle`, `sir`).
- **Click** a pill: cycles it on that box (ctrl+click the weapon: `/mset`).
- **Fixed width:** each column as wide as its widest value, `Atk`/`Def` as 4 digits; cycling never moves anything.
- A job without weapon modes (WHM...) shows `melee` `ws` `hoxne` only once changed.

<details>
<summary><b>Pill colours</b></summary>

| Pill | Colours |
|---|---|
| melee | `acc` cyan, `sb` magenta (a job's own modes: lime, salmon, periwinkle) |
| ws / idle | `high` purple / `mp` blue, `hp` green, `tp` yellow |
| nuke / ranged | `macc` teal, `oa` salmon / `racc` cyan |
| tank / hoxne | `main` periwinkle, `meva` lime / bronze |
| def | `dt` orange, `mdt` blue, `amin` mauve (`+` = more than one) |
| toggles | `sir` teal, `th` gold, `kite` green, `proc` red, `burst` pink |
| weapon | relic light blue, mythic and ergon green, empyrean red, prime purple, aeonic orange, TP bonus (Sparrowhawk +2, Anarchy +2) dark blue, others grey |

The weapon's class comes from the mode's Main, else Range, else Sub; add your own with
`WeaponClass = { ['Item Name'] = 'tpbonus' }`. Each of the 22 jobs has its own colour.

</details>

- **Drop:** opens on hover (`HUDHover = false`: always); in the screen's bottom half the lines rise above the bar
  (`HUDGrow`). The box with it on also prints the other boxes' chat lines as `[Name]` (`HUDMessages`).
- `/gchud debug` lists what it reads.
- **Windower:** no shapes: `|` and the words in their colours (grey = default/off).
