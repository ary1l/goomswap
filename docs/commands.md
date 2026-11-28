# Commands and keys

[← Back to the README](../README.md)

## Commands

- **Toggles** take `on` / `off`; no word flips them (`/wsdistance`: no word shows its state).
- **Modes** take a value in any case: no word = the next one; else its name, its start, its initials, part of it,
  its number, or your own short name in `HUDAbbr` (`/wm max`, `/mset sb`, `/wm 3`).

| Command | Does |
|---|---|
| `/wm [name\|N\|none\|default] [sub]` | Weapon mode, plus a Sub pick if named (`/wm cali bunzi`); a new mode clears `/mw` `/subw` `/rw` `/ammoset` picks for the slots its set names; `force` re-applies |
| `/mw` `/subw` `/rw` `/ammoset [name\|none]` | One slot's pick over the mode; any TP. Picks: the job's `MainModes`/`SubModes`/`RangeModes`, then any item its `Weapon_` sets name |
| `/dw [on\|off\|auto]` | Dual Wield: why; `off` = `_1h` always |
| `/smartswap` | Light spells (Dia, Blink…) keep weapons at `SmartSwapTP`+ |
| `/mset [sb\|acc\|base]` | Melee mode: `_Default` → `_SubtleBlow` → `_Acc` TP/WS sets; `acc` also wears `Midshot_Acc` (COR RNG PLD; `Midshot_<Mode>_Acc` per weapon mode) |
| `/wsset [default\|low\|high\|pdl\|acc\|sb]` | `low`: WS sets add their `_LowBuff` (attack not capped: low buffs, GearSwap's UncappedAtt); `high`: their `_HighBuff`; `pdl`: their `_PDL` (Physical damage limit+ gear); `acc` / `sb`: their `_Acc` / `_SubtleBlow`, as `/mset acc` / `sb` do, TP gear unchanged. `mid` (the old name) picks `default` |
| `/th` | `TH` until tagged (THF main: always) |
| `/wsdistance [yalms\|on\|off]` | No word: the check's state and your target's distance and reach. WS range check: a WS out of reach is cancelled (reach = its range: 3; Gust Slash, Cyclone, Mistral Axe, Bora Axe 14; bows and guns 20, at least 21; Blast Arrow, Blast Shot, Numbing Shot 5; + your and the target's hitboxes, so further on a big mob; at least as far as your auto-attacks have landed on a mob of that name and size this zone; `yalms` = the least reach, default 5). Myrkr, Dagan, Moonlight, Starlight (on you): no check |
| `/def [dt\|mdt\|aminon\|off]` | DT → MDT → Aminon → off; `/dt` `/mdt` `/aminon` one |
| `/sir` `/kite` | SIR over midcasts (not `SIRSkip`) / Movement |
| `/idleset [refresh\|regen\|regain\|reraise]` | `Idle_<mode>` over `Idle` while idle; `reraise`: your Reraise gear (`Idle_Reraise`), the auto `Idle_Regen` / `Idle_Refresh` kept off it |
| `/autogear [regen\|refresh\|dt\|petdt N]` | Auto idle set thresholds |
| `/lock [slots\|all]` `/unlock [slot]` | Freeze slots; `/unlock` names other holders |
| `/nukeset [power\|macc\|oa]` | Nuke sets; `oa` = `OccultAcumen` (RDM GEO BLM SCH DRK) |
| `/burst` | `Burst` on every nuke |
| `/weapon` `/death` | BLM/SCH: Club/Staff mode / BLM Death set |
| `/lac gear` | LuAshitacast + the Packer plugin: every set's gear, the Packer lists and the items GoomSwap wears, into your bags (`/gcedit` Settings: **Get gear now**) |
| `/hoxne [off\|use]` | Hoxne Ampulla in Ammo, used |
| `/gce <item>` `/gce cancel` | Equip enchanted item, wait, use, free the slot |
| `/warpring` `/mea` `/holla` `/dem` `/ontic` `/shard` | Warp/dim rings, exit items |
| `/capacity` `/jubilee` `/dynamisrp` | Hold cape / Jubilee Ring / Dynamis neck (`/dynamisrp` goes off by itself when you leave a Dynamis - Divergence zone) |
| `/abyproc` | Head, hands, legs, feet bare until off (Abyssea procs) |
| `/tankset` `/proc` `/pupmode` | PLD RUN tank set / `Proc` only (engaged; a WS: `Ws_Proc`, else `Proc`; turns `/hoxne` `/aminon` off), every job / PUP mode |
| `/forcestring` `/songlock` `/siphon` | BRD: Daurdabla on every song / keep Main/Sub on every enemy song (the BRD example's Lullaby always keeps them; instruments still swap, no TP lost) / SMN |
| `/gcbar` `/gchud` | Status bar / the other boxes dropped under it ([Status bar and HUD](bar.md)) |
| `/gcbar scale <0.5-3>` | Bar size, saved per character |
| `/gcgear [on\|off]` | Worn-gear grid: icons, ammo, encumbrance, locks, holds, RP, missed swaps; right-click a slot: edit its set; ctrl+click: lock, alt+click: take off, shift+click: pick gear ([gear grid](bar.md#gear-grid-gcgear)) |
| `/gcgear scale <0.5-3>` `alpha <0.2-1>` `bg [on\|off]` `reset` | Its size, icon opacity, panel, first spot; saved per character |
| `/gcperf` | Timings in chat every 10s: idle/engaged handler, bar, gear grid, engine tick; `/gcperf off` stops |
| `/checksets [all]` | Empty sets, bad names, wrong ear/ring (Sortie/"Right ear:" → Ear2); gear you don't own, wrong bag, other augments |
| `/gcbuild [JOB]` | A draft job file: the job's example with only the gear you own → `<JOB>.proposed.lua`; on your job it opens in `/gcedit` to fill and save as `<JOB>.lua` ([/gcbuild](gcbuild.md)) |
| `/gcimport <file> [JOB]` | A Windower GearSwap job file's sets (Mote's names mapped: `sets.engaged.Acc` -> `Tp_Acc`; SomeAcc / FullAcc fold into Acc; WS UncappedAtt -> `_LowBuff`; Selindrile's `<Char>-Items.lua` beside it read for its `gear.X`; its spell groups (`StatusRemoval`...) worn by a rule each; Mirdain's layout too (`Mirdain-Include`: `sets.OffenseMode.ACC` -> `Tp_Acc`, its TP mode merged into the base sets, `sets.Weapons.X` -> /wm with `Weapons.Shield` as `Weapon_X_1h`, `sets.WS` / `sets.JA` by name, its spell kinds worn by rules); item names the file misspells matched to the one item they can be, with a note) as `<JOB>.proposed.lua`, the job's example around them; it opens in `/gcedit` to save as `<JOB>.lua` (from another job: as that job's file, **Save file**, nothing loaded). Needs a GoomSwap job file loaded on the job you run it from ([Rules](rules.md) for its logic) |
| `/gcedit [set]` | Set editor window: sets, slots with icons, gear you own; Save writes `<JOB>.lua` and reloads ([/gcedit](gcedit.md)) |
| `/gcedit last [slot]` | The editor on the set your last action used (the set named after it, else the last set it wore), Result on that use; with a slot (`ear2`), the set that last put that slot on (as `/gcgear`'s right-click). `/gcedit Last Stand` is still the set |
| `/gcmessages` `/gchelp` | Chat lines / help |
| `/gckey <key> <cmd>` | Bind a key |


## Keys

Bound on load, removed on unload/job change.

| Key | Runs | Key | Runs |
|---|---|---|---|
| F7 | `/wm` | Shift+F7 | `/wm default` |
| F9 | `/mset` | Ctrl+F9 | `/tankset` |
| Alt+F9 | `/wsset` | | |
| F10 | `/def` | Alt+F10 | `/kite` |
| Win+F10 | `/hoxne` | Shift+F11 | `/nukeset` |
| Alt+F11 | `/burst` | Shift+F12 | `/idleset` |
| Alt+F12 | `/def off` | Ctrl+Win+Alt+F12 | reload |

Your own: a GoomSwap command (`wm 2`) or any chat command (`/ma "Cure IV" <stpc>`). Modifiers `^` Ctrl, `!` Alt,
`+` Shift, `@` Win, `#` Apps.

- Now: `/gckey ^F1 /ma "Cure IV" <stpc>`.
- One character: `char.lua` `settings = { Keybinds = { {'F7','wm'}, {'^F1','/ja "Provoke" <t>'} } }` (whole list).
- One job: `table.insert(gcinclude.settings.Keybinds, {'^F2', '/ja "Sentinel" <me>'});` in `OnLoad`.
