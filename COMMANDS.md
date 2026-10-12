# ShaySwap commands

Every command works as `/name` or `/lac fwd name`. All boxes: `/mss /lac fwd <cmd>`.
One box: `/ms sendto <name> /lac fwd <cmd>`.

Zoning turns off `/autofood`, `/autosoda` and `/hoxne` (re-arm them where you want them).
While zoning (from the server's zone-line reply until 3s after arriving) nothing is sent by itself: no item uses,
queued actions, food/soda or auto-casts.

On/off commands (`/automb`, `/burst`, `/kite`, `/th`, `/dt`, `/mdt`, `/aminon`, `/sir`, `/death`, `/proc`, `/forcestring`,
`/songlock`, `/gcmessages`, `/autofood`, `/autosoda`, ...) take `on` or `off`; with no argument they flip.

## Weapons

| Command | Does |
|---|---|
| `/wm` | Next weapon mode (`/weaponset` same) |
| `/wm savage` | Match by name: exact, prefix, substring |
| `/wm 3` | By position (1 = None) |
| `/wm none` | Stop managing weapons (`TH`-set weapons still apply while `/th` is on) |
| `/wm default` | This job's `DefaultWeapons` |
| `/wm melee` | Role name from `gcinclude.WeaponRoles` |
| `/wm leaden force` | Swap even at 1000+ TP |
| `/mainset` `/subset` `/rangeset` `/ammoset` `[name\|N\|none]` | Per-slot cycles, on jobs that define them |
| `/subset duban` | e.g. PLD shields: `/subset` cycles None → Aegis → Duban (list: `gcinclude.SubModes` in OnLoad); add `force` at 1000+ TP |

- A weapon mode is what you return to at rest. Action sets that swap weapons still do.
- Per-slot cycles override the mode for their slot. COR/RNG modes are named for the gun, so
  `/mainset` changes the melee weapon.
- `/th` on: Main/Sub/Range in the `TH` set override the mode and per-slot cycles, tagged or not (Sub only if
  you can dual wield). `/th` off gives them back.
- **TP hold:** at 1000+ TP, engaged or not, Main/Sub/Range don't change (songs, rolls, cures, enfeebling,
  enhancing, geomancy excepted). `force` overrides; `settings.WeaponTPGuard = 0` disables. Asleep, the slots
  your `Sleeping` set names are let go (see Sets the engine uses).
- `Weapon_<Mode>_1h` is used when you can't dual wield: main or sub job NIN Lv10+, DNC Lv20+ or THF Lv83+
  (FFXIclopedia Dual Wield), at the effective level, so a restricted support job (Sheol Gaol, SJ Restriction:
  sub Lv0) doesn't count. Losing Dual Wield puts the `_1h` set on at once, past the TP hold (the offhand weapon
  is no use); getting it back waits for the TP hold. `gcinclude.AlwaysDualWield = true` forces the DW pair (BLU,
  THF). The same check decides whether the `TH` set's Sub is used.

Augmented items in a per-slot cycle:

```lua
gcinclude.MainModes = {'None', 'Naegling', 'Rostam B', 'Rostam C'};
gcinclude.WeaponItemMap = {
    ['Rostam B'] = { Name = 'Rostam', AugPath = 'B' },
    ['Rostam C'] = { Name = 'Rostam', AugPath = 'C' },
};
```

## Defense and locks

| Command | Does |
|---|---|
| `/def [off\|dt\|mdt\|aminon\|sird]` | Sets one (or none); no arg cycles none → DT → MDT → Aminon → SIRD → none (Ctrl+Shift+grave) |
| `/dt` `/mdt` `/aminon` | Toggle one. `/aminon` uses `mdt` if the job has no `Aminon` set, and locks Main/Sub (the set's items, else what you wear) plus Range/Ammo when the set names them, until off; other slots still swap for actions |
| `/sir` | `SIR` set over every midcast. `SIRSkip` exempts spells; engaged or not |
| `/hoxne` | Off → Locked (Alt+grave). Locked keeps the ampulla in Ammo and locks Ammo and Range (any action set's Ammo would knock it off and end the Enchantment; an instrument in Range would too), and keeps bows/guns/crossbows out of Range (they need matching ammo). `/hoxne use` goes Locked and uses it. While Locked it is used when it is in Ammo and the Enchantment status isn't up (BG-Wiki: Double Attack +100% for 30 min as Enchantment, 60s recast, 5s use delay, lost when unequipped or zoning); Enchantment up, it is never used; it waits until Enchantment has been gone 3s (it drops as you cross a zone line). Zoning sets it back to Off. `HoxneAutoUse = false` stops the automatic use |
| `/hoxne use` | Locked, equip, wait its delay, use |
| `/lock` | Lock Main, Sub, Ammo |
| `/lock ear1 back` | Lock any slots by name |
| `/unlock` / `/unlock ammo` | Release all / one |
| `/dw [on\|off\|auto]` | Dual Wield: no arg shows yes/no and why (e.g. `sub NIN Lv0`). `off` = always `_1h` sets, `on` = always DW sets, `auto` = detect (default) |
| `/smartswap [on\|off]` | On: at `SmartSwapTP`+, `NoWeaponSpells` (Dia, Blink, spikes…) don't swap weapons; `KeepWeaponsFor` (Cure/Cura) keep Daybreak or Bunzi's Rod |
| `/naked` `/weaponsonly` `/abysseaproc` `[on\|off]` | Strip all 16 / the 12 armor slots / head, hands, legs, feet and keep them bare. One at a time |
| `/capacity` `/jubilee` `/dynamisrp` `[on\|off]` | Wear and hold: the best carried capacity cape (BG-Wiki: Aptitude Mantle +1 30%, Aptitude Mantle 25%, Mecisto. Mantle by its augment) / Jubilee Ring (`JubileeSlot`, Ring1) / your main job's best Dynamis - Divergence neck (+2, +1, base). Entering a `[D]` zone reminds you |

Defense toggles only wear gear, except `/aminon`, which also locks the weapon slots. `/lock` is absolute until `/unlock`, even against force-equips.
Unknown slot names are refused. Holds skip slots already locked or TP-held; off releases only what they took.

## Magic burst (RDM BLM SCH GEO)

| Command | Does |
|---|---|
| `/automb [on\|off]` | Casts into live skillchains by itself (off by default). No arg flips it. Same: `/autonuke`, `/mbmode` (Win+grave) |
| `/mbtier [low\|mid\|high]` | Its nuke tier I / III / V. No arg cycles; `1\|3\|5` work too |
| `/burst` | Burst set on every nuke, not only on live skillchains (off by default) |
| `/mbinfo` | Last skillchain seen |

Burst set: always on, no command. A nuke (yours or `/automb`'s) that lands inside a live skillchain of its
element on its target wears it; any other nuke wears your normal set (`/burst` puts it on every nuke).

`/automb` casting:
- Targets a chain on a mob you or your party are engaged on, or your target; your target's chain first.
  It casts on the chained mob by its id, so it works while you're engaged on another mob (skipped if
  that mob is past 21.8', the usual spell range per FFXIclopedia). Not engaged: it also targets the chained mob.
- Casts the chain element's nuke (Fire, Blizzard, Aero, Stone, Thunder, Water) at the tier.
  Light/Darkness chains use those elements. Transfixion/Compression (Light or Dark only): SCH casts
  Luminohelix/Noctohelix (II with 1200 JP); other jobs have no Light/Dark nuke, so they skip it.
- Tries the tier on each chain element, then one tier lower (`MBFallback`). Blizzard V on recast
  during Distortion → Water V.
- Only casts if it lands inside the window (`MBWindow` 10s; cast time is learned from your last casts),
  is castable, off recast, affordable, and you're not moving.
- Waits out the game's delay after your own actions: 3s after a spell finishes or is interrupted,
  2s after a WS or job ability (BG-Wiki). Its own wait ends when its cast finishes (5s if no finish is seen).
- SCH IV/V need Addendum: Black or Enlightenment. Tier V: BLM 86, SCH 91, RDM/GEO 100 JP gift.
- `MBCasts` (1) per chain, `MBRotate` rotates elements, `MBMinMP` holds fire.
- Default tier `settings.MBTier = 'Mid'`; per job `gcinclude.MBTier` before `Initialize()`.
- Anything else (helix, -ja, Death) is manual.

`BurstWanted()` decides the Burst set; `settings.MBSkills` (Elemental Magic) sets which skills
count. Cast time per skill is learned from your own start/finish packets (slowest of the last 5);
until one cast is seen it falls back to `gSettings.FastCast`.


## Action checks

Spells, abilities and WS that would fail are cancelled before any gear moves, with the reason in chat
(`Validate = false` turns it off):

| Check | Result |
|---|---|
| KO, sleep, stun, petrification, terror, charm | Cancelled |
| Mute; Amnesia (abilities, WS) | Cancelled |
| Silence | Cancelled; uses Echo Drops, else Remedy (Remedy first if paralyzed). `AutoRemedy`, not under Muddle |
| Paralysis on an ability | Uses a Remedy instead, if carried |
| Recast | Back within `MiniQueueMax` (5s): queued and sent when ready and past the forced delay (BG-Wiki: 3s after a spell, 2s after a WS, 2s after a job ability with job abilities allowed after 1s) (`<me>`, a player, or `<t>` if still targeted). Longer: shows `m:ss`. `MiniQueue = false` to only cancel |
| MP short | Cost adjusted for Light/Dark Arts (own school -10% rounded down, other +20% rounded up). Skipped under Manafont, Manawell, Parsimony, Penury, Addenda, Tabula Rasa. Gear "MP cost -%" isn't counted: `ValidateMP = false` if it bites |
| Stratagems at 0 | Cancelled, next charge time shown |
| Waltz short on TP | Cancelled. Set `WaltzTPCut` to your gear's "Waltz TP cost" reduction |

Charge-pool abilities (Ready, Sic, Quick Draw) skip the recast check. LAC only sees what the client sends,
so anything the client refuses itself never gets here.

## Automation

| Command | Does |
|---|---|
| `/autofood [on\|off]` | Eat when Food is missing (outside town, not moving); off on zoning |
| `/autosoda [on\|off]` | Use `SodaItem` when Regain is missing; 20s between tries, off after `ConsumableMaxTries` (2) and on zoning |
| `/revit [on\|off]` | Zone item list (below) |
| `/holywater [on\|off]` | Holy Water on Doom (on by default) |
| `/gce <item>` | Equip enchanted item, lock slot, wait its delay, use |
| `/gce cancel` | Stop every item use under way and give the slots back (zoning does too) |
| `/temps` | Drink the carried Escha temps, 3s apart: Monarch's, Braver's, Fighter's, Champion's, Soldier's, Barbarian's Drink |

```lua
AutoUseItems = T{
    { Zone = 'Ghoyu',    Item = 'Revitalizer' },   -- zone: case-insensitive substring
    { Zone = 'Al Zahbi', Item = "Giant's Drink" },
};
AutoFoodItems = T{'Grape Daifuku +1', 'Grape Daifuku'}; -- in order; per job gcinclude.AutoFood
```

Enchanted item delay comes from the item's `CastDelay`; override with `settings.EnchantDelays`,
fallback `EnchantWindow`. The wait starts once the item is really on (not at the command); then `/item`, retried
every 2s (up to 5 tries) until the use starts. The slot stays locked until the use finishes, then unlocks.
Gives up (and unlocks) if the item never goes on within 10s or 5 tries never start. One per slot, several at once.
The first try waits the delay + 3s (the server refuses for about 3s past it), counted from when the item went
on, also when a set put it on just before. A reuse timer a few seconds past the delay (extdata, Windower
extdata.lua layout) delays the first try to match. Nothing is refused up front: the game decides. Tries wait
while an action is running.

**Supply warnings** (never cancel anything; BG-Wiki: Barrage fires only as many shots as you have ammo):
the ammo in use, counted over inventory and wardrobes, at or under `AmmoWarn` (20), and Utsusemi tools
(Shihei, plus Shikanofuda on a NIN main) at or under `NinjaToolWarn` (10). Said once, then every 10 fewer,
and at 0. Unlimited Shot: quiet.

**Asleep under Stoneskin:** damage it absorbs can't wake you (FFXIclopedia Sleep), so the engine sends
`/cancel Stoneskin` (needs a cancel addon, as `CheckCancels` already does). `SleepCancelStoneskin = false` to stop.

## HUD

| Command | Does |
|---|---|
| `/gchud [on\|off]` | Show/hide |
| `/gchud pos 500 120` | Place it (dragging also saves) |
| `/gchud large` / `/gchud compact` | Look: `large` = bigger text, more spacing, full names and values; `compact` (default) = tight. `/gchud style` flips. Saved per character |
| `/gchud debug` | Files found, rows parsed |
| `/gcbar [on\|off]` | Local one-line status bar (off by default) |
| `/gcbar pos 300 0` | Place it |

Each box writes `hud/<name>.txt` 4x a second. Opens on load for names in `settings.HUDOwners`.

Default state:

```
     wpn  ml   nk   def  mb     kt fd sd
COR  Ana  Def       -           .  .  .
RDM  Max  Def  Pow  -    Off    .  .  .
SCH       Def  Pow  -    Off    .  .  .
BRD  Nae  Def       -           .  .  .
BLU  Tiz  Def       -           .  .  .
GEO  Idr  Def  Pow  -    Off    .  .  .
```

After some changes, BLU's name clicked:

```
     wpn  ml   nk    def  mb     th kt fd sd
COR  Ana  Def        MDT         .  .  .  .
RDM  Max  Def  Pow   -    AutoV  .  .  fd .
SCH       Def  Pow   -    Off    .  .  .  .
BRD  Nae  Acc        -           .  kt .  .
BLU  Tiz  Def        DT          th .  .  .
     BLU/DRG a- hx- cj
GEO  Idr  Def  Macc  -    Off    .  .  .  sd
```

- Columns: cycles, then `def` (`/def` state), `mb` (`/automb`: `Off`, or `Auto` + tier; `+F` = `/burst` on), then toggles.
- `.` off, glyph on, blank = job doesn't have it, `-` none.
- Bright = changed since load, dim = default, orange = turned off but loads on (SCH `Off`).
- Columns at default on every box are hidden unless in `HUDPinned`; they reappear when changed.
- Click a cell: runs it on that box. Click a name: shows its hidden columns. Hover: full names.
- `mb` cell: click = `/automb`, Ctrl+click cycles that box's tier (`/mbtier`: I → III → V).
- Values shorten automatically (`Death Penalty` → `DeaP`, `Anarchy +2` → `Ana+2`). A warning prints
  if two weapons shorten the same.

Glyphs: `wpn` Weapons, `ml` MeleeSet, `m` `s` `r` `a` Main/Sub/Range/Ammo, `nk` NukeSet,
`el` Element, `tk` TankSet, `hx` Hoxne, `pp` PupMode, `w` Weapon, `th` TH, `kt` Kite,
`fd` AutoFood, `sd` AutoSoda, `hp` String, `sl` SongLock, `pr` PROC, `dh` Death, `tier` MBTier.

| Setting | Default | |
|---|---|---|
| `HUDPinned` | `Def MB Kite AutoFood AutoSoda` | Always-shown columns |
| `HUDAbbr` | `{}` | Value names: `{ ['CarnwenhanAcc'] = 'CarnA' }` |
| `HUDLabels` | `{}` | Glyphs: `{ Main = 'mn' }` |
| `HUDScale` | `0.9` | Text size (compact) |
| `HUDStyle` | `'compact'` | `'large'` for the roomy look (or `/gchud large`) |
| `HUDScaleLarge` | `1.1` | Text size (large) |
| `HUDAlpha` | `0.45` | Background, 0 = none |

## Other commands

Cycle commands (`/meleeset`, `/nukeset`, `/weapon`, `/elecycle`, `/tankset`, `/pupmode`): no word cycles,
a word picks that value in any case, by number or by its start (`/meleeset hybrid`, `/meleeset d`, `/tankset meva`).
On/off commands (`/dt`, `/kite`, `/th`, ...) take `on`/`off` in any case; no word flips.
All boxes: `/mss /meleeset hybrid` (Multisend), Windower `//send @all gs c meleeset hybrid`.

| Command | Does |
|---|---|
| `/meleeset [value]` | MeleeSet: Default → Hybrid → Acc. Wears `Tp_`/`Ws_Hybrid` or `_Acc` over `Tp_`/`Ws_Default`, and `<Name>_Hybrid`/`_Acc` over a named set |
| `/kite` | Kite toggle |
| `/th` | TH toggle: `TH` set until the target is tagged; its Main/Sub/Range the whole time it's on |
| `/setcycle <name> <value>` | Set any cycle; name and value in any case (`/setcycle meleeset acc`) |
| `/wsdistance [yalms]` | Toggle WS distance check / set distance (default 5) |
| `/gcmessages` | Chat confirmations on/off |
| `/autogear [on\|off]` | Auto sets by HP/MP %; no arg shows thresholds |
| `/autogear regen\|refresh\|dt\|petdt N` | Threshold %, 0 = never. Defaults 60 / 60 / 50 / 50 |
| | Regen/Refresh only out of combat and never over `/dt`; Dt any time |
| `/received <spell>` | Wear that `*_Received` set |
| `/gcaspir` `/gcdrain` | Best castable, off-recast tier on `<t>` |
| `/ontic` `/shard` | Use Ontic Extremity / V. Con. Shard. Add more in `gcinclude.ExitItems` |
| `/rrset` `/craftset` `/zeniset` `/fishset` | Toggle Reraise / Crafting / Zeni / Fishing set |
| `/gcstyle [N]` | `/lockstyleset N` now. `LockstyleSet` (or per job `gcinclude.LockstyleSet`) applies it 4s after load and job change |

| Command | Jobs | Does |
|---|---|---|
| `/nukeset` | RDM BLM SCH GEO WHM | NukeSet: Power → Macc |
| `/weapon` | BLM SCH | Club → Staff |
| `/elecycle` | BLM SCH | Element cycle |
| `/nuke <1-6>` | BLM SCH | Element's nuke at that tier |
| `/helix` `/weather` | BLM/SCH, SCH | Element's helix / storm, II if available |
| `/death` | BLM | Death toggle |
| `/tankset` | PLD RUN | None → Main → MEVA |
| `/proc` | SAM NIN | Proc set; NIN also disables ammo |
| `/pupmode` | PUP | Tank → Melee → Ranger → Mage |
| `/forcestring` | BRD | Force harp |
| `/songlock` | BRD | Enemy songs (Requiem, Lullaby, Elegy, Finale, Threnody, Nocturne, Virelai) keep main/sub (no TP loss); buff songs and instruments still swap |
| `/cormsg` | COR | Roll messages |
| `/siphon` | SMN | Swap to day's spirit, Elemental Siphon, resummon |

## Tele rings

| Command | Setting | Goes to |
|---|---|---|
| `/warpring` | `warp_Ring` | Warp point |
| `/mea` | `mea_Ring` | Tahrongi portal |
| `/holla` | `holla_Ring` | La Theine portal |
| `/dem` | `dem_Ring` | Konschtat portal |

Force-equips to Ring2 (ignores `/lock`), holds it through the equip delay, uses it at 11s, then
`/lac set Idle` at 22s (retries while zoning). If `Idle` has no Ring2 the ring stays on.
Change per job: `gcinclude.settings.dem_Ring = 'Teleport Ring: Dem'`.

## Diagnostics

| Command | Does |
|---|---|
| `/checksets` | Empty sets, bad item names, `_Default` gaps, ear/ring slot swaps, leftover Moonshade |
| `/gctrace` | One chat line per action: `[Cure IV] Precast > Cure_Precast \| Midcast > Cure`. `{Waist}` = engine-made set (obi/Orpheus, TH without its weapons) |
| `/gchelp` | Command list in game |
| `/gckey <key> <cmd>` | Bind a key |
| `/gcinfo` | Show element gear picks |
| `/xiroll` | Roll tracking |

## Sets the engine uses

| Set | Worn |
|---|---|
| `Weapon_<Mode>` / `_1h` | Weapon mode |
| `mdt`, `Aminon`, `SIR` | With their toggles |
| `LightBonus` | Healing Magic midcast |
| `TH` | `/th` on: at rest, and over midcast/midshot at a mob, until it is tagged (your hit, shot, WS or ability; a spell, step or Effusion only if it lands; clears on death or zone). Not over actions on you or allies. BLU: only `BluMagTH` spells, always (AoE). Main/Sub/Range stay on while `/th` is on, tagged or not (Sub only if you can dual wield; a weapon swap resets TP) |
| `HolyWater` | When Doomed (else `gcinclude.sets.Holy_Water`) |
| `Incapacitated` | Slept, petrified, stunned or terrorized: your `/def` set (`mdt` or `Aminon`; else `Dt`, as SIRD is midcast only) minus Main/Sub/Range/Ammo goes on, then this set (extras, empty by default) on top, then any `*_Received` set. Not charmed: the client can't change gear then and GearSwap never sends any |
| `Sleeping` | Asleep, over `Incapacitated` (else `gcinclude.sets.Sleeping`). Main/Sub/Range in it go on past the TP hold (not past `/lock`), e.g. WHM/GEO `Main = 'Lorg Mor'`: a Prime stage 1-2 weapon's "Slowly devours your soul" drains 1 HP and 1 MP every 3s, which wakes you (BG-Wiki Prime weapons; not Diabolos' Nightmare). A weapon swap resets TP. Awake again, your normal weapon comes back |
| `XIRoll` | Idle only, with a roll on you at 11 (default Roller's Ring) |
| `Absorb` | Absorb-TP and every other Absorb- spell, over midcast |
| `Absorb_TP` | Optional, Absorb-TP only, on top of `Absorb` |
| `Hoxne_Tp`, `Hoxne_Idle`, `Hoxne_Dt` | While `/hoxne` is Locked and Enchantment is up: `Hoxne_Tp` engaged, `Hoxne_Idle` idle and not moving, `Hoxne_Dt` in place of both while `/dt` is on (none: your Dt set stays); none while `/kite` is on. Over your job sets (Tp, Impetus...), under every engine layer. Each takes its `/meleeset` variant (`Hoxne_Tp_Hybrid`) |
| `Hoxne_Ws`, `Hoxne_<ws name>` | Same gate, over every weaponskill, then that WS, e.g. `['Hoxne_Victory Smite'] = {...}` |
| `Hoxne_<set>_<buff>` | A Hoxne set's buff combo, over it while that buff is up: `Hoxne_Tp_Impetus`, `['Hoxne_Victory Smite_Impetus']`. `&` joins buffs that must all be up: `['Hoxne_Ws_Sneak Attack&Trick Attack']`. Fewest buffs first, then A-Z. On a WS every combo goes over both `Hoxne_Ws` and `Hoxne_<ws name>`. Examples in each melee job file |
| `Buffs = { Name = {...} }` | While that buff is up (idle/engaged) |
| `Buffs_Ws`, `Buffs_Midcast` | Same, over every weaponskill / every spell's midcast, e.g. `Buffs_Ws = { ['Aftermath: Lv.3'] = {...} }`. Name the buff as the buff list shows it |
| `*_Received` | See below |

Moonshade goes in Ear2 on WS below `MoonshadeTP` (1750), except `MoonshadeSkip`.

Layer order: your sets → Hoxne sets → weapons (+ `TH` weapons while `/th` is on) → mdt/Aminon → Hoxne Ampulla (Ammo) → TH → received → buff sets → XIRoll →
debuff (Incapacitated/Sleeping/Doom/Weakness) and craft/zeni/fish/rr sets.
Midcast: job sets → TH → `Buffs_Midcast` → Absorb → LightBonus → obi/Orpheus/back/ring → SIR.
WS: job sets → Hoxne sets → `Buffs_Ws` → Moonshade → obi/Orpheus/back.

### Hoxne layering

Lowest to highest; per slot the later set wins, so a slot left out of a set keeps the piece under it. Ammo is locked while
`/hoxne` is Locked, so Ammo in any set is ignored. Hoxne sets need `/hoxne` Locked and Enchantment up.

Idle/engaged:
1. Your job sets, in your job file's order, e.g. `Idle` → `Tp_Default` → `Tp_<meleeset>` → job buff sets (`Impetus`, `Footwork`...) → `Dt` (`/dt`) → `Movement` (`/kite`).
2. One Hoxne set: `Hoxne_Dt` while `/dt` is on, else `Hoxne_Tp` engaged, else `Hoxne_Idle` idle and not moving. None while `/kite` is on.
3. That set's `/meleeset` variant (`Hoxne_Tp_Hybrid`), then its combos (`Hoxne_Tp_Impetus`), fewest buffs first, then A-Z.
4. Auto `Idle_Regen`/`Idle_Refresh`/`Dt` (low HP/MP), `Town`.
5. Engine layers: weapons → mdt/Aminon → Hoxne Ampulla → TH → received → `Buffs` → XIRoll → debuff and craft/zeni/fish/rr sets.

Weaponskill:
1. Your job sets, in your job file's order, e.g. `Ws_Default` → `Ws_<meleeset>` → that WS's set → job buff sets (`Victory_Imp`, `Sekkanoki`...).
2. `Hoxne_Ws` → `Hoxne_Ws_<meleeset>` → `Hoxne_<ws name>` → `Hoxne_<ws name>_<meleeset>`.
3. Combos of `Hoxne_Ws`, then combos of `Hoxne_<ws name>` (each fewest buffs first, then A-Z), so buff combos go over both WS sets.
4. `Buffs_Ws` → Moonshade → obi/Orpheus/back.

MNK Victory Smite, Impetus up, `/meleeset` Default: `Ws_Default` → `Victory_Default` → `Victory_Imp` → `Hoxne_Ws` →
`['Hoxne_Victory Smite']` → `['Hoxne_Victory Smite_Impetus']` → `Buffs_Ws` → Moonshade.

Sub vs Main (FFXIclopedia Grips): a two-handed main (Great Sword, Great Axe, Scythe, Polearm, Great Katana,
Staff) takes only a grip in Sub, and a grip needs a two-handed main. After each handler a Sub that can't go
with the final Main (or the worn one, if Main is held) is dropped, so the swap can't fail.

**Received sets** (worn until the spell lands or is interrupted, `ReceivedWindow` 8s at most; mapping in `settings.ReceivedSets`):

| Cast on you | Set |
|---|---|
| Cure, Cura, Curaga | `Cure_Received` |
| Cursna | `Cursna_Received` |
| Phalanx | `Phalanx_Received` |
| Protect, Shell | `Protect_Shell_Received` |
| Regen | `Regen_Received` |
| Refresh | `Refresh_Received` |
| Curing/Divine Waltz | `Waltz_Received` |

Spells: triggered by anyone's "starts casting" packet on you, and by your own boxes (Multisend at precast).
Area spells reach you too (BG-Wiki/FFXIclopedia, 10'): a party member's Curaga landing near you, or Cura,
Protectra, Shellra cast near you; your own boxes are also told for Majesty Cure/Protect and Accession white
magic. The set comes off as soon as that caster's spell finishes or is interrupted.
The Multisend notice goes only to your own boxes: ones running this engine (fresh `hud\<Name>.txt`) or
listed in `settings.MyBoxes`. Other players' characters are never sent to.
Waltzes are instant, so only your own boxes' Curing Waltz is announced (Multisend when used) and it can
land after the heal; Divine Waltz is aimed at the dancer, so never. Doesn't interrupt your own action;
locked slots skipped.

**Element gear** (spells in `ElementSkills`, elemental ninjutsu, Quick Draw, Cure/Cura/Curaga, WS in `ElementalWS`):

```lua
ElementGear = T{
    Obis = T{ Dark = 'Anrin Obi' },
    AnyObi = 'Hachirin-no-Obi',
    Distance = "Orpheus's Sash",
    DistanceMax = nil,
    Back = 'Twilight Cape',   -- optional
    Ring = 'Zodiac Ring',     -- optional
};
```

Per BG-Wiki: helixes always get day/weather, so never an obi (Orpheus still); cures get Light day/weather
(+10/+10/+25, the obi forces it) but no sash and no ring (`BackOnCures = true` adds the back, `Cures = false` skips cures); Quick Draw
and elemental ninjutsu (Katon…Suiton) take obi/Orpheus/back; the Twilight Cape adds +5% to a day bonus, or to a
weather bonus that applies (obi on, or a helix); Zodiac Ring never on Lightsday/Darksday nor on cures.

Obi score: day +10, weather +10 (double +25), opposing element subtracts. Orpheus: `OrpheusPoints`
(+15 at ≤1.93', +1 at ≥13', linear between; the middle is assumed). Higher wins; obi never at ≤0.
`Ring` goes on when the day matches (`ElementSkills` spells only). `Keep` items are never displaced.

## Hotkeys

| Key | Command |
|---|---|
| Ctrl+grave | `wm` |
| Shift+grave | `wm default` |
| Ctrl+Shift+grave | `def` |
| Alt+grave | `hoxne` |
| Win+grave | `automb` |

```lua
Keybinds = T{ {'^`','wm'}, {'+`','wm default'}, {'^+`','def'}, {'!`','hoxne'}, {'@`','automb'} };
```

Prefixes: `!` Alt, `^` Ctrl, `+` Shift, `@` Win, `#` Apps; combine them (`^+` = Ctrl+Shift). Bare grave is left
unbound (too easy to hit; cleared on load unless a bind asks for it). `T{}` = none. Binds replace existing ones
on that key and are removed on unload; check `/bind list`. `/bind block 1` stops them firing while
typing. If Win+grave opens Start, try `/keyboard winkey 0` or another key.

## Fast Cast

Leave `gSettings.FastCast` at 0. Nothing here needs your Fast Cast number.

- **Idle gear after a cast**: LAC puts it back when the game says your cast finished (or was interrupted),
  not on a timer. `FastCast` only sets LAC's backup timer for a lost packet. At 0 the backup is the full
  cast time, which is safe. Set too high, the backup fires early and idle gear goes on mid-cast.
- **Will the burst land in time?** the engine times your real casts, from the game's
  "starts casting" packet to "finished". So Fast Cast gear, buffs, traits and lag are all included,
  with no setting to maintain. It keeps your last 5 casts per magic skill and plans with the slowest,
  so one lucky Quick Cast doesn't make it think you're faster than you are. Interrupted casts are ignored.
- Before your first cast of a skill it assumes the full base cast time (slow side = safe). Resets on `/lac reload`.

## Gear tips

- Slot keywords (LuAshitacast, per Thorny): `'remove'` forces the slot empty (sends an unequip); `'displaced'`
  changes nothing but marks the slot empty, for a slot the game empties itself when the set goes on (a cloak
  covers Head; a bell, instrument or throwing weapon in Range empties Ammo; a tathlum or the Hoxne Ampulla in Ammo
  empties Range); `'ignore'` leaves the slot alone.
- HP pieces: give them `Priority = <HP>` so max HP doesn't dip mid-swap.
- Leave Moonshade out of WS sets; the engine adds it.
- Weapons in `TH` (THF: Gandring Sub) stay on the whole time `/th` is on, tagged or not (a swap would reset TP).
  `/th` off gives your weapon mode back.
- `Absorb`: one set covers every Absorb- spell. `Absorb_TP` only if Absorb-TP needs different gear.
- Dynamis RP: wear only what you're ranking, `/lock neck main sub range`, `/unlock` after. Kill RP splits
  between every uncapped item worn, and only Divergence necks/weapons earn it (BG, Oboro).

## Job file

```lua
profile.OnLoad = function()
    gcinclude.WeaponModes = {'None', 'Savage', 'Leaden'};
    gcinclude.DefaultWeapons = 'Savage';          -- or { Main = 'Burtgang', Sub = 'Aegis' }
    gcinclude.WeaponRoles = { melee = 'Savage', ranged = 'Leaden' };
    gcinclude.MainModes = {'None', 'Burtgang', 'Caliburnus'};
    gcinclude.SubModes  = {'None', 'Aegis', 'Duban'};
    gcinclude.RangeModes = {'None', 'Annihilator', 'Fomalhaut'};
    gcinclude.AlwaysDualWield = true;
    gcinclude.AutoFood = 'Grape Daifuku +1';
    gcinclude.BuffSetOrder = T{'Saboteur', 'Aftermath'};
    gcinclude.MBTier = 'High';
    gcinclude.Initialize();
end
```

`gcinclude.BuffCount('Name')` or `(id)` counts buffs (same as `gData.GetBuffCount`, cached ids).

Handler helpers:

| Call | Does |
|---|---|
| `gcinclude.EquipMode('Ws')` | `Ws_Default`, then `Ws_<MeleeSet>` unless Default |
| `gcinclude.ByName(name)` | Set named `name` (any case), then `name_<MeleeSet>`. False if none |
| `gcinclude.Family(name)` | `'Utsusemi: Ni'` → `'Utsusemi'`, `'Drain III'` → `'Drain'` |
| `gcinclude.CheckTH(force)` | `TH` set without its weapons if `/th` is on and the target is an untagged mob; `force` skips the target checks |
| `gcinclude.CheckWsBailout()` | False if the WS would fail: `if (gcinclude.CheckWsBailout() == false) then gFunc.CancelAction(); return end` |

## Multibox examples

```
/mss /lac fwd wm default
/mss /lac fwd def
/mss /lac fwd autofood on
/ms sendto <name> /lac fwd wm 3
```
