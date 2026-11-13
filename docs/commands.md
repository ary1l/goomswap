# Commands and keys

[← Back to the README](../README.md)

## Commands

Ashita `/name`; Windower `//name` or `//gs c name`.

- **Toggles** take `on` / `off`; no word flips them.
- **Modes** take a value in any case: no word = the next one; else its name, its start, its initials, part of it,
  its number, or your own short name in `HUDAbbr` (`/wm max`, `/mset sb`, `/wm 3`).
- Windower: `//sw` and `//th` also belong to Stopwatch and THTracker; with one loaded use `//subset` / `//gs c th`.

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
| `/gcbar` `/gchud` | Status bar / the other boxes dropped under it ([Status bar and HUD](bar.md)) |
| `/gcmodes [all]` | Modes in chat |
| `/checksets` | Empty sets, bad names, wrong ear/ring (Sortie/"Right ear:" → Ear2) |
| `/gcgear [JOB]` | Everything you own the job can wear → `gear_<JOB>.txt` (Ashita) |
| `/gcbuild [JOB] [family]` | A draft job file: the job's example with only the gear you own → `<JOB>.proposed.lua` ([/gcbuild](gcbuild.md)) |
| `/gcaudit [JOB]` | Your own job file checked against your bags, nothing changed → `<JOB>.audit.txt` ([/gcaudit](gcbuild.md)) |
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
