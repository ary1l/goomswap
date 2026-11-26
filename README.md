# GoomSwap

A gear-set engine for Final Fantasy XI. Define sets in one job file; GoomSwap layers the relevant sets for spells,
abilities, weapon skills, combat modes, defense and utility gear.

For **Ashita v4** (LuAshitacast). Start from an example job file and the in-game set editor (`/gcedit`).

![The set editor (in game, before the v3.30 layout clean-up): the set list, the open set's slots with icons and bags, and Related: every set that goes on with it, in order (character name pixelated)](docs/gcedit_editor.png)

More pictures of the editor, some of them mockups of the newest build, are in [its docs](docs/gcedit.md).

## Features

- Weapon modes, TP and Aftermath protection, defense modes, idle Regen/Refresh, and status-specific gear.
- Precast/midcast layers, TH, spell-element gear, magic burst, Moonshade and action safety checks.
- Rules: "when this, wear that" without code (a buff up, low MP, a spell on you, a mode...), made in `/gcedit`;
  **Convert** turns your job file's own `if`s into rules with the same result ([Rules](docs/rules.md)).
- No text editor needed: sets, rules, modes, settings (lists and keybinds as controls) and new job files are all
  done in `/gcedit`.
- `/gcimport` reads a Windower GearSwap job file's sets into a GoomSwap draft; **Adopt** makes a plain LuAshitacast
  file a GoomSwap one, its code kept.
- Packer: `/lac gear` (the Packer plugin) fetches every set's gear, your Packer lists and the items GoomSwap wears.
- `/gcbar` status bar and `/gchud` multibox controls; colours follow goomui's preset.
- `/gcgear` worn-gear grid (equipmon-style icons, ammo, encumbrance) marking `/lock`, TP holds, Aminon/Hoxne, gear
  that needs RP and swaps that didn't go on; hover a slot for the set that put it on, a box's name in the `/gchud`
  drop for its gear.
- `/gcbuild` to draft a job file from carried gear; `/gcedit` to browse the character's job files, inspect gear,
  fill and compare inherited gear/stat totals (with gear caps: haste, Fast Cast, PDT/MDT), keep item details
  visible, and resize panels; arrange, hide and sort its headings, copy sets to other jobs, find an item in every
  job file, put a piece in many sets or replace it everywhere, see which sets are on you now, restore a backup,
  list gear no job file uses, and edit settings for one character or all of them. `/gcedit last` opens the set
  your last action used.
- TP/WS/DT/idle sets per weapon mode or weapon type (`Tp_Chango`, `Tp_2h`).

![The status bar and, hovered, the other boxes' modes](docs/gcbar.png)

## Install

**Ashita v4**

1. Copy `common/` and `examples/` into `Ashita-V4beta-main/config/addons/luashitacast/`.
2. Copy `examples/<JOB>.lua` into your character's LuAshitacast profile folder (or, once one job file loads, make the
   others in `/gcedit`: the file name menu, **New job file**). Add `examples/char.lua` there if you want
   per-character settings.
3. Load LuAshitacast and your job file: `/addon load luashitacast`, then `/lac load`.
4. Optional: Ashita's Packer plugin (`/load packer`) for `/lac gear`, which puts your sets' gear and Packer items in
   your bags (`/gcedit` Settings, **Get gear now**).
5. Load Ashita's `debuff` addon (`/addon load debuff`): it provides `/cancel`, which GoomSwap uses to drop Sneak or
   Stoneskin before recasting them and to cancel Stoneskin while you are asleep.
6. Einherjar: a separate addon, not part of this repository (`/ejenter`).
7. Sequencer and PacketFlow are recommended for multiboxing and action timing: [Sequencer](https://github.com/ThornyFFXI/Sequencer),
   [PacketFlow](https://github.com/ThornyFFXI/PacketFlow). [Multisend](https://github.com/ThornyFFXI/Multisend)
   (`/load multisend`) lets your boxes tell each other about incoming Cures and buffs (received sets).

## First use

1. Load the matching example job file. `/lac newlua` can create the profile folder and an empty job file. Coming
   from GearSwap: put your job file in your character's luashitacast folder and run `/gcimport <file>`.
2. Run `/gcbuild` to create `<JOB>.proposed.lua` with gear you own, or open `/gcedit` and choose **Keep only my gear**.
3. Use the editor's **To fill** and **Gear** tabs to fill empty or missing slots. **Use worn** copies your current gear
   into a set.
4. Choose **Save + reload**. The previous file is backed up; the newest three editor backups per job are kept
   by default (`EditorBackupKeep = 0` keeps all). Other job files use **Save file** without changing your active job.
5. Run `/checksets`; the editor's **What goes on** tab shows what an action actually put on, slot by slot.

While a job file is new (still the example, or a `/gcbuild` draft), the editor shows a **Getting started** list of
these steps, each ticked from what GoomSwap sees, with a button for each. It goes away once every step is done, or
with **Hide**.

## Weapon modes

A weapon mode is a `Weapon_<Name>` set (Main, Sub, any of Range/Ammo) listed in `gcinclude.WeaponModes`; `/wm <name>`
picks it (F7 cycles). While it is on, its own sets go over their base: `Tp_<Name>` over `Tp_Default`, `Ws_<Name>`,
`Savage Blade_<Name>`, `Idle_<Name>`, `Dt_<Name>`... `Weapon_<Name>_1h` is worn instead when you can't dual wield,
`Weapon_<Name>Acc` (or `Weapon_<Name>_Acc`) with `/mset acc`. All of it is done in `/gcedit`.

**Add one** (example: an RDM adding Mpu Gandring as `/wm mpu`):

1. `/gcedit` on that character. For another job's file, click the file name in the top bar.
2. **+ /wm mode** on the WEAPONS heading (or **+ New set**), name it `Weapon_Mpu` (one word, no spaces or `_`:
   `/wm mpu`), **Create**.
3. **Weapon sets for /wm Mpu** opens. Tick the sets whose gear should differ with Mpu (`Tp_Mpu`, `Ws_Mpu`, a weapon
   skill's set...) and **Make**. They start empty: fill only what differs, and later changes to the base still apply.
4. Fill `Weapon_Mpu`: Main Mpu Gandring, Sub your offhand.
5. **Weapon sets...** (over the slots) again: tick `Weapon_Mpu_1h`, `Weapon_Mpu_Acc`... (spelled like your file's,
   `Weapon_MpuAcc` if it joins them) and **Make**. They start as copies of `Weapon_Mpu`; change their Sub.
6. Optional: right-click `Weapon_Mpu`, **/wm order**, to place it in the cycle; **GoomSwap settings**, **DefaultWeapons**, to
   start in it.
7. **Save + reload** (another job's file: **Save file**, in effect when you change to that job). The review lists
   the new `/wm` mode.

After the reload it is in `/wm` (`/wm mpu`, F7) and on the bar: the weapon pill and its right-click menu, and that
box's line in the other boxes' HUD (they read it within a second). The pill takes the colour of the mode's Main
(else Range, else Sub): Mpu Gandring is prime, purple; `WeaponClass` adds your own. To type a different name,
`HUDAbbr = { ['Mpu'] = 'gand' }` in char.lua's settings (`/wm gand`).

**Remove one** (example: a PLD dropping its Malignance Sword mode):

1. Right-click `Weapon_Malignance`, **Delete set...**. The box shows:
   - `/wm Malignance` coming out of `gcinclude.WeaponModes`;
   - **Also delete the N sets worn only with /wm Malignance**, ticked (`Weapon_Malignance_1h`, `Tp_Malignance`...);
     untick to keep them. Sets your job file's code names are kept and listed;
   - in orange, `DefaultWeapons` / `WeaponRoles` still naming it: change those in **GoomSwap settings**.
2. **Confirm deletion**, then **Save + reload**.

After the reload it is gone from `/wm`, F7, the bar's menu and the HUD. A reload always starts in `DefaultWeapons`'s
mode; if that still names the removed one (the orange note), in the list's first, None: no weapon mode.

To swap one weapon for another instead, **Rename set...** (`Weapon_Malignance` to `Weapon_<New>`) renames the mode
everywhere the file names it (the mode lists, `DefaultWeapons`, code) and, ticked, its `Weapon_Malignance_...` sets;
rename its other sets (`Tp_Malignance`, `Weapon_MalignanceAcc`) yourself.

## Common commands

| Command | Purpose |
|---|---|
| `/wm [mode] [sub]` | Weapon mode, optionally with a Sub pick; right-click the bar's weapon for a menu |
| `/mw` `/sw` `/rw [item]` | Main/Sub/Range pick over the mode (any item in a `Weapon_` set) |
| `/mset [mode]` | Melee mode, such as Acc or SubtleBlow |
| `/def` | Cycle DT, MDT, Aminon and off |
| `/th` `/sir` `/kite` | Treasure Hunter, spell interruption resistance, movement gear |
| `/idleset [mode]` | Idle set mode |
| `/lock [slots]` `/unlock` | Hold equipment slots |
| `/gcbar` `/gchud` `/gcgear` | Status bar, multibox HUD, worn-gear grid |
| `/checksets` | Validate sets |
| `/gcbuild` `/gcedit [set]` | Build or edit job sets |
| `/gcimport <file> [JOB]` | A GearSwap job file's sets as a draft to edit and save |
| `/lac gear` | Fetch every set's gear and your Packer items (Packer plugin) |
| `/gchelp` | In-game command help |

See [all commands and keys](docs/commands.md).

## Documentation

- [Sets and job files](docs/sets.md)
- [Commands and keys](docs/commands.md)
- [Settings](docs/settings.md)
- [Engine behavior](docs/features.md)
- [Status bar and HUD](docs/bar.md)
- [Building a job file](docs/gcbuild.md)
- [Set editor](docs/gcedit.md)
- [Rules, Convert, Adopt](docs/rules.md)

## Troubleshooting

- **Changes do not apply:** `/lac reload`.
- **A slot will not change:** `/unlock`; check TP and Aftermath weapon holds.
- **A set is empty or gear is missing:** run `/checksets` and inspect the set in `/gcedit`.
- **An action is cancelled:** read the reason in chat; the editor's What goes on tab shows the gear path.
- **Bar or HUD is hidden:** `/gcbar on`, `/gchud on`, or `/gcbar reset`; the gear grid: `/gcgear on`, `/gcgear reset`.
