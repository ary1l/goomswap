# GoomSwap

Gear-swap engine for FFXI multiboxing. You write sets in a job file; GoomSwap wears them and adds automatic
layers (weapons, defense, TH, obi, and more) on top. **Ashita v4** (LuAshitacast) and **Windower 4** (GearSwap,
through `windower/`), same job files.

## What it does on its own

- **Weapons:** `/wm` modes (`_1h` sets when you can't dual wield, `/mmode Acc` variants), idle/town weapons out of
  combat. No automatic swap throws away TP (`WeaponTPGuard`, per job) or Aftermath; songs, rolls, cures still swap.
- **Defense:** `/dt` `/mdt` `/aminon`; regen/refresh/DT idle by HP/MP; sleep, stun, doom, weakness sets.
- **Casting:** TH until tagged, SIR, obi/Orpheus/elemental ring and back, Moonshade, auto magic burst (RDM BLM SCH GEO).
- **Items:** food (per job), packer (keeps a list of items in inventory on every job change), soda, holy water, enchanted items and warp/dim rings, Hoxne Ampulla.
- **Multibox:** one HUD for every box (click a cell to drive it, the boxes' messages show there); Einherjar entry,
  lamp copies and hand-out (`/ejenter`, Ashita).
- **Checks:** refused actions say why; `/checksets` finds empty sets and misspellings; `/gctrace` shows what each action wore.

## Install

**Ashita v4**
1. Copy `common/` and `examples/` into `Ashita/config/addons/luashitacast/`.
2. Copy `examples/<JOB>.lua` into your character folder `luashitacast/<Name>_<id>/`, put your gear in. Optional:
   `examples/char.lua` there too, for that character's food, packer list and settings on every job.
3. `/addon load luashitacast`, then `/lac load`.
4. Recommended: Thorny's [Sequencer](https://github.com/ThornyFFXI/Sequencer) and [PacketFlow](https://github.com/ThornyFFXI/PacketFlow) plugins
   (`/load sequencer`, `/load packetflow`, or in your startup script). Without Sequencer, LuAshitacast blocks the
   game's own resends, so an action is lost when lag hits; PacketFlow sends packets more often.

**Windower 4**

```
Windower/addons/GearSwap/data/
├── default.lua                        <- windower/GearSwap/data/default.lua
└── goomswap/
    ├── core.lua ashita.lua imgui.lua  <- windower/GearSwap/data/goomswap/
    ├── common/                        <- common/
    └── <Name>/<JOB>.lua               <- examples/<JOB>.lua, your gear in it
```

`//lua load gearswap`, change job: chat shows `[GoomSwap] Loaded data/goomswap/<Name>/<JOB>.lua`. A red
`[GoomSwap]`/`[LuAshitacast]` line names a missing file or folder. No `[GoomSwap]` line at all = GearSwap found another file first (`data/<Name>/<JOB>.lua`, `data/<Name>_<JOB>.lua`, `data/<Name>.lua`,
`data/<JOB>.lua` all beat `default.lua`). A job file straight in `goomswap/` serves every character. Already use
`default.lua` for other jobs? Copy ours to `data/<Name>_<JOB>.lua` for each GoomSwap job instead.

| | Ashita | Windower |
|---|---|---|
| Command | `/wm` | `//wm` or `//gs c wm` |
| All boxes | `/mss /wm` (Multisend) | `//send @all gs c wm` |
| Reload after edits | `/lac reload` | `//gs reload` |
| HUD | `/gchud`, click cells | `//gchud`, click cells |
| Augmented gear | `{ Name = 'X', Augment = {...} }` (LAC strings) | Same file works: the carried copy best matching the list is worn (names differ a bit between the two, so not exact). Or GearSwap's own `{ name="X", augments={...} }`, pasted from `//gs export`, matched exactly |

Windower augment strings: wear the gear, `//gs export` (file in `GearSwap/data/export/`) or `//gs export copy`
(clipboard), paste each line into a set and capitalize the slot (`back=` → `Back =`). Rare items export without
augments (only one copy exists). In a job file (COR):

```lua
local sets = {
    Weapon_Rostam = {
        Main = { name="Rostam", augments={'Path: A',} },
    },
    Tp_Default = {
        Back = { name="Camulus's Mantle", augments={
            'AGI+20', 'Rng.Acc.+20 Rng.Atk.+20', 'Rng.Acc.+10', '"Store TP"+10', 'Mag. Evasion+15',
        } },
    },
};
```

## First steps

1. Fill `Idle`, `Tp_Default`, `Ws_Default`. The rest can wait.
2. `/checksets`: empty sets, misspelled items. `/gctrace`: which sets each action wore.
3. Leave `gSettings.FastCast` at 0.

Template jobs (BLM BST DNC DRG DRK NIN PUP RUN SAM SMN WAR) name sets after the action (`['Savage Blade']`); a spell
with no set uses its family's (`['Cure']` for Cure IV). Worth copying: `WHM.lua` cures (MP% / Light weather weapons, `Cure_Dt`), `MNK.lua` Hoxne sets, `PLD.lua` `/subset`.

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
| One job, value | Job file; replaces the setting in brackets | `gcinclude.MBTier` (`MBTier`), `gcinclude.AutoFood` (food list, `AutoFoodItems`; on/off stays `AutoFood`), `gcinclude.LockstyleSet`, `gcinclude.ElementGear` (whole table), `gcinclude.CureObi` (`ElementGear.Cures`) |

Copying a newer `common/` over yours erases your edits: note them, or set them per job instead.

| Area | Settings |
|---|---|
| Weapons / TP | `WeaponTPGuard`, `AftermathHold`, `IdleWeapons`, `HoldExemptSkills`, `HoldExemptAbilities`, `SmartSwap`, `SmartSwapTP`, `NoWeaponSpells`, `KeepWeaponsFor` |
| Casting | `SIRSkip`, `THSkip`, `ElementGear` (obi, Orpheus, ring, back, `Cures`), `ElementSkills`, `OrpheusPoints` |
| Auto idle sets | `AutoGear`, `RegenGearHPP`, `RefreshGearMPP`, `DTGearHPP`, `PetDTGearHPP` |
| Weapon skills | `WScheck`, `WSdistance`, `MoonshadeTP`, `MoonshadeSlot`, `MoonshadeSkip`, `ElementalWS` |
| Magic burst | `AutoNuke`, `MBTier`, `MBCasts`, `MBRotate`, `MBMinMP`, `MBWindow`, `MBFallback`, `MBSkills` |
| Items | `AutoFood`, `AutoFoodItems`, `PackerItems`, `PackerFood`, `AutoSoda`, `SodaItem`, `AutoHolyWater`, `HolyWaterItem`, `AutoRevitalizer`, `AutoUseItems`, `EnchantDelays`, `EnchantWindow`, `ConsumableMaxTries` |
| Hoxne | `HoxneItem`, `HoxneLockSlots`, `HoxneAutoUse` |
| Received gear | `ReceivedSets`, `ReceivedWindow`, `MyBoxes` |
| Action checks | `Validate`, `ValidateMP`, `WaltzTPCut` |
| HUD / bar | `HUDOwners`, `HUDHover`, `HUDGrow`, `HUDMessages`, `HUDX`, `HUDY`, `HUDStyle`, `HUDScale`, `HUDScaleLarge`, `HUDAlpha`, `HUDAbbr`, `HUDLabels`, `DisplayBar`, `DisplayBarX`, `DisplayBarY` |
| Other | `Keybinds`, `Messages`, `Trace`, `LockstyleSet`, `CombatWindow`, `XIRollSet`, `CapacityCapes`, `JubileeSlot`, `AmmoWarn`, `NinjaToolWarn`, `SleepCancelStoneskin`, `ElementReport`, `warp_Ring` `mea_Ring` `dem_Ring` `holla_Ring` |

Weapon modes, default weapons, job helpers: see Job file.

## Commands

Ashita `/name`; Windower `//name` or `//gs c name`. Other boxes (Multisend): `/mss /wm default` all, `/ms sendto <name> /wm 3`
one; Windower `//send @all gs c wm default`. Toggles take `on`/`off`, no word flips.

**Weapons**
| Command | Does |
|---|---|
| `/wm [name\|N\|none\|default]` (`/weaponset`) | Weapon mode: next, by name/number, `default` (`DefaultWeapons`), a `WeaponRoles` name (`/wm melee`); `none` = hands off. `/wm <mode> force` re-applies it |
| `/mw` `/sw` `/rw` `/ammoset` `[name\|none]` | One slot's pick (`/mainset` `/subset` `/rangeset` long names), e.g. PLD `/sw duban`. `none`, `default` or the mode's own item (`/sw thibron`) = back to the mode's. Swaps at any TP |
| `/dw [on\|off\|auto]` | Dual Wield: shows why; `off` = `_1h` sets always, `on` = DW always |
| `/smartswap` | Light spells (Dia, Blink…) keep your weapons at `SmartSwapTP`+ |
| `/setcycle <cycle> <value>` | Set any mode by its name |

**Melee and weapon skills**
| Command | Does |
|---|---|
| `/mmode [sb\|acc\|base]` (`/melee`, `/meleeset`) | Melee mode: Base (`_Default` sets) → `_SubtleBlow` → `_Acc` TP and WS sets |
| `/wsset [mid\|high]` | `high`: each WS set also wears its `_HighBuff` |
| `/th` | `TH` set until the mob is tagged (THF main: always) |
| `/wsdistance [yalms]` | WS range check on/off or its distance |

**Defense**
| Command | Does |
|---|---|
| `/def [dt\|mdt\|aminon\|off]` | DT → MDT → Aminon → off; `/dt` `/mdt` `/aminon` toggle one |
| `/sir` | `SIR` set over spell midcasts (not `SIRSkip`) |
| `/kite` | Movement gear |
| `/autogear [regen\|refresh\|dt\|petdt N]` | Auto Regen/Refresh/DT idle sets by HP/MP %; no word shows the thresholds |
| `/lock [slots\|all]` `/unlock [slot]` | Freeze slots (none named: Main, Sub, Ammo); `/unlock` says what else holds one |
| `/naked` `/weaponsonly` `/abysseaproc` | Keep all 16 / armor / head-hands-legs-feet bare |
| `/rrset` `/craftset` `/zeniset` `/fishset` | Reraise / crafting / Zeni / fishing set over everything until toggled off |
| `/received <spell>` | Wear that `*_Received` set |

**Magic**
| Command | Does |
|---|---|
| `/nukeset [power\|macc\|oa]` | Nuke sets (RDM GEO: `oa` = OccultAcumen) |
| `/automb` (`/autonuke`, `/mbmode`) | Cast into live skillchains by itself (RDM BLM SCH GEO) |
| `/mbtier [1-5]` | Its tier I to V; no word: next |
| `/burst` | Burst set on every nuke, not only live skillchains |
| `/mbinfo` | Last skillchain seen |
| `/gcaspir` `/gcdrain` | Best castable tier on `<t>` |
| `/nuke <1-6>` `/helix` `/weather` `/elecycle` `/weapon` | BLM/SCH: element's nuke, helix, storm, element, Club ↔ Staff |
| `/death` | BLM Death mode |

**Items, travel and content**
| Command | Does |
|---|---|
| `/autofood` `/autosoda` | Eat food / drink soda when the buff is missing (food: `char.lua` or `gcinclude.AutoFood`) |
| `/packer` | Fetch what inventory lacks of your packer list (Bellhop); also on every job change |
| `/holywater` `/revit` | Holy Water on Doom / per-zone item use (`AutoUseItems`) |
| `/hoxne [off\|use]` | Keep Hoxne Ampulla in Ammo and use it |
| `/gce <item>` / `/gce cancel` | Equip an enchanted item (Volte Harness, Reraise Earring…), wait its delay, use it, free the slot |
| `/warpring` `/mea` `/holla` `/dem` | Warp / Dimensional ring, the same way |
| `/ontic` `/shard` | Use Ontic Extremity / V. Con. Shard (more: `gcinclude.ExitItems`) |
| `/temps` | Every carried Escha drink |
| `/capacity` `/jubilee` `/dynamisrp` | Hold capacity cape / Jubilee Ring / Dynamis job neck |
| `/ejenter [chamber]` `/ejlamps` `/ejexit` | Einherjar (Ashita): reserve, lamps to the party, enter, leave |

**Jobs**
| Command | Does |
|---|---|
| `/tankset` | PLD RUN: None → Main → MEVA |
| `/proc` | SAM NIN: proc set |
| `/pupmode` | PUP: Tank → Melee → Ranger → Mage |
| `/forcestring` `/songlock` | BRD: force harp / enemy songs keep main-sub |
| `/cormsg` `/xiroll` | COR: roll messages / roll tracking |
| `/siphon` | SMN: Elemental Siphon with the day's spirit |

**Display and help**
| Command | Does |
|---|---|
| `/gchud [on\|off\|large\|compact\|pos X Y\|debug]` | The multibox HUD (see HUD below) |
| `/gcbar [on\|off\|pos X Y]` | One-line status bar |
| `/gcmodes [all]` | This box's modes and toggles in chat; `all`: every box |
| `/checksets` | Empty sets, bad item names, items in the wrong ear/ring: Sortie earrings and any item whose text says 'Right ear:' go in Ear2 (right), 'Left ear:' in Ear1 |
| `/gcgear [JOB]` | Every item you own that the job can wear (all bags), with level, augments and stats, into `gear_<JOB>.txt` in your character folder (Ashita) |
| `/gctrace` | What each action wore (and its obi/Orpheus pick) |
| `/gcstyle [N]` | Lockstyle set now |
| `/gcmessages` | Chat confirmations on/off |
| `/gchelp` / `/gckey <key> <cmd>` | Command list in game / bind a key |

Picking a value, any case: no word = next; else exact name, the one it starts, its initials, the one containing it, or
a number: `/wm max` (Maxentius), `/nukeset oa` (OccultAcumen), `/mmode sb` (SubtleBlow), `/wm 3`. Two matches: it lists them.

Zoning turns off `/autofood`, `/autosoda`, `/hoxne`. While zoning (until 3s after arriving) nothing is sent by itself.

Keys: Ctrl+grave `/wm`, Shift+grave `/wm default`, Ctrl+Shift+grave `/def`, Alt+grave `/hoxne`, Win+grave `/automb`.
`/gckey <key> <cmd>` rebinds.

## Weapons

- The weapon mode is what you return to; action sets that name weapons still swap them. Slot picks (`/mw` `/sw` `/rw`
  `/ammoset`) beat the mode for their slot. COR/RNG modes are named for the gun, so `/mw` changes the melee weapon.
- **Idle weapons:** out of combat, weapons your idle sets name (`Idle`, `Idle_Regen`, `Town`, `Dt`…) win; the mode's go
  on at engage. Main+Sub and Range+Ammo move as pairs. `IdleWeapons = false`: mode always.
- **TP hold:** at `WeaponTPGuard`+ TP (default 1000; examples: 0 on BLM BRD COR GEO RDM SCH SMN WHM, 100 on PLD)
  Main/Sub/Range stay, except for songs, rolls, cures, enfeebling, enhancing, geomancy. Weapon commands swap at any TP;
  `0` = no hold. Aftermath up holds them too, at any TP, against idle/engaged sets (`AftermathHold = false` to stop).
  Asleep, the `Sleeping` set's weapons pass.
- **`/th`:** THF main keeps `TH` Main/Sub/Range on the whole time, over mode and picks. Other jobs: they come off with
  the rest of `TH` at the tag (a weapon swap resets TP).
- **Dual wield:** `Weapon_<Mode>_1h` when you can't: NIN 10+, DNC 20+, THF 83+, main or sub at the effective level
  (FFXIclopedia; Sheol Gaol sub Lv0 doesn't count). Losing DW puts `_1h` on at once; regaining waits for the TP hold.
  `gcinclude.AlwaysDualWield = true` forces DW (BLU, THF). Game refuses a Sub for lack of DW: that item stays off Sub
  15s (`gcinclude.SubRefuseHold`), then one retry.
- Augmented weapon in a cycle: `gcinclude.WeaponItemMap = { ['Rostam B'] = { Name = 'Rostam', AugPath = 'B' } };` and
  `'Rostam B'` in `MainModes`.

## Defense and locks

- `/aminon`: `Aminon` set (else `mdt`); locks Main/Sub (the set's, else what's worn) and Range/Ammo if the set names
  them, until off. Turns `/sir` off; `/sir` is refused while it's on.
- `/lock` holds until `/unlock`, even against force-equips (handy for `//gs export`). Locks have owners (you, Aminon,
  Hoxne, `/proc`, holds, `/gce`): turning one off frees only its slots; `/unlock` frees only yours and names the rest.
- `/naked` `/weaponsonly` `/abysseaproc`: one at a time. NIN `/proc` also locks Ammo.
- **`/hoxne`** (off ↔ Locked; `use` = Locked and use now): Hoxne Ampulla kept in Ammo, Ammo and Range locked (anything
  there knocks it off and ends Enchantment). Used when in Ammo and Enchantment has been gone 3s (BG-Wiki: Double
  Attack +100%, 30 min, 60s recast, 5s use delay, lost on unequip or zone). `HoxneAutoUse = false` stops auto use.

## Magic burst (RDM BLM SCH GEO)

1. Fill `Burst`. It goes on by itself when a nuke lands in a live skillchain of its element; `/burst` = every nuke.
2. Tier: `MBTier = 'III'` (`'I'`–`'V'`) in settings, `gcinclude.MBTier` per job, or `/mbtier 5` (until reload or job change).
3. `/automb on` (Win+grave); `AutoNuke = true` starts it on.
4. Optional: `MBCasts` (bursts per chain, 1), `MBRotate` (spread over the chain's elements), `MBMinMP` (hold below it),
   `MBFallback` (next tier down when the tier can't go), `MBSkills` (skills that wear `Burst`).

`/automb` takes a chain on your target, else on a mob you or your party fight, within 21.8'. It casts by id, so it works
engaged on another mob (Windower: at the mob without targeting it). It casts the chain element's nuke only if it lands
inside `MBWindow` (10s; cast time learned from your casts), you aren't moving, and your last action's delay is over (3s
spell, 2s WS/JA). Tier can't go (not learned, level/JP gift, recast, MP, SCH IV/V without Addendum: Black or
Enlightenment): next tier down. Light/Dark-only chains: SCH helix, others skip.

## Items

- **Food** (`/autofood`; outside town, not moving), first one set: `gcinclude.AutoFood` in the job file → `AutoFood`
  in `char.lua` (every job) → `AutoFoodItems` setting.
- **Packer** (Ashita, Thorny's Bellhop plugin: `/bh get`, any bag it reaches): lists add up, later wins, `false` drops an
  item: `PackerItems` setting → `Packer` in `char.lua` → `gcinclude.Packer = { ['Trump Card'] = 99, ['Holy Water'] =
  false }` in a job file. `'stack'` = full stack. `PackerFood` adds a stack of the job's first food. Still short a few
  seconds later: named in chat. Windower: `profile.Packer` feeds `//gs org` (Organizer addon).
- **`/autosoda`:** `SodaItem` when Regain is missing; 20s between tries, off after `ConsumableMaxTries`.
- **`/gce`:** waits the item's `CastDelay` (override `EnchantDelays`, fallback `EnchantWindow`) once it's really on;
  `/item` retried every 2s, 5 tries; gives up after 10s not on. Refused if `/lock` or another feature holds the slot.
- **Rings** (`/warpring` `/mea` `/holla` `/dem`): `/gce` on Ring2, past `/lock`; let go after the use so your Ring2
  returns. Ring names: `warp_Ring` etc.
- **Einherjar** (Ashita, Hazhalm Testing Grounds): reserver within 5' of the Entry Gate runs `/ejenter ort` (1-9 or
  name start). It trades the Smoldering Lamp, picks the chamber, copies a Glowing Lamp per party member within 6' and
  trades one to each. GoomSwap boxes accept by themselves (party members only, Glowing Lamps only). When all have one,
  the reserver enters and sends `/mso /ejenter`. `/ejexit` drops the lamp = leave. Windower: use Valkyrie.
- Warnings, never cancel: ammo ≤ `AmmoWarn` (20), Utsusemi tools ≤ `NinjaToolWarn` (10).
- Asleep under Stoneskin: sends `/cancel Stoneskin` (needs a cancel addon; `SleepCancelStoneskin = false` stops it).

## Action checks

Spells, abilities and WS that would fail are cancelled before gear moves, reason in chat (`Validate = false` off).
Nothing is queued: press it again when ready.

- KO, sleep, stun, petrify, terror, charm, Mute, Silence; Amnesia for JA/WS. No item use for Silence: leave Echo
  Drops/Remedy to another addon.
- Recast: shows `m:ss` left (Ready/Sic/Quick Draw use charges, not checked).
- Already casting: new spell/JA/WS/`/item`/`/ra` cancelled so your cast keeps its gear. A spell the server refuses stops
  counting at once.
- MP short, arts-adjusted (own school -10%, other +20%); skipped under Manafont, Manawell, Parsimony, Penury, Addenda,
  Tabula Rasa. Gear MP cost isn't counted: `ValidateMP = false`.
- Stratagems at 0; Waltz short on TP (`WaltzTPCut` = your gear's reduction).
- Forced delay (BG-Wiki: 3s after a spell, 2s after WS/JA) isn't checked; the game's message says so.

## HUD (multibox)

Every box running GoomSwap writes its modes 4x/s (`luashitacast/hud/`; Windower: over IPC); one box shows them all.

- **Who gets the grid:** in `common/gcinclude.lua` settings, `HUDOwners = T{'YourMain'};` (per character: `settings` in
  `char.lua`). Those characters open it on load with every box; on any other box `/gchud` shows only that box's line.
  Empty list: any box's `/gchud` shows every box.
- **Use:** click a cell = run it on that box; click a name = its hidden modes; Ctrl+click `mb` = tier. The owner also
  prints the other boxes' GoomSwap lines as `[Name]` (`HUDMessages = false` to stop).
- **Commands:** `/gchud` (on/off), `/gchud large|compact`, `/gchud pos X Y`, `/gchud debug`. Drag to move; saved per character.
- **Layout:** top left; `HUDOwners` first, then party order. The owner sees the headers and its own line until the
  mouse is over the HUD, then every box (`HUDHover = false`: always all). In the bottom half of the screen it opens
  upward: your line stays put, the other boxes stack above it (`HUDGrow = 'up'`, `'down'`, `'auto'`). Every column a
  box's job has always shows, so the width never changes.
  Name colour: blue SIR, gold TH, green kite, red PROC. Food, soda, harp, song lock, death: a chat line when they change.
  A box on `/wsset high` shows its `melee` cell purple; `/hoxne` on, its `wpn` cell teal. Bright = changed, dim = default.
- **Columns:** `wpn` weapon mode, then the slot picks `main` `sub` `rng` `ammo` (`-` none), `melee`, `nuke`, `elem`,
  `tank`, `pup`, `w` BLM/SCH weapon, `def` (`-` none), `mb` (`-` off, else tier). Tune: `HUDAbbr`, `HUDLabels`,
  `HUDScale`, `HUDScaleLarge`, `HUDAlpha`.

## How sets stack

Later wins, slot by slot; a set changes only the slots it lists.

**Idle / engaged**, lowest to highest:
1. Your job file: `Idle` / `Tp_Default` → `Tp_<mset>` → buff sets (`Impetus`) → `Dt` (`/dt`) → `Movement` (`/kite`).
2. Hoxne sets → auto `Idle_Regen` / `Idle_Refresh` / `Dt` (low HP/MP) → `Town`.
3. Weapon mode (not engaged: only the weapon slots your idle sets leave empty; `IdleWeapons = false` = all) → `mdt` (`/mdt`) or `Aminon` (`/aminon`) → Hoxne Ampulla → `TH` → `*_Received` → `Buffs` → XIRoll.
4. **`Incapacitated`** (slept, petrified, stunned, terrorized): `Aminon` if `/aminon` is on, else `mdt` if `/mdt`,
   else `Dt` (even with `/dt` off), without Main/Sub/Range/Ammo; then the `Incapacitated` set, then `*_Received`. **Over DT, MDT, Aminon,
   TH, Buffs and everything in 1-3.**
5. `Sleeping` (asleep) → `Doomed` → `Reraise` (Weakness) → craft / zeni / fish / rr sets.

**Spells (midcast):** your job file → `TH` (not `THSkip`) → its `_Self` / `_Others` / `_Burst` sets → `Absorb` (TH back on top) → `Buffs_Midcast` →
`LightBonus` → obi/Orpheus/back/ring (a `TH` waist stays) → `SIR` (`/sir`, not `SIRSkip`). WHM cures:
`Cure` → `Self_Cure` → `Cure_LowMP` or `Cure_LowMP_Storm` (MP ≤ 50%) → `Cure_Dt` (`/dt`) → Hachirin-no-Obi → `SIR`.

**Weapon skills:** your job file → its `_HighBuff` sets (`/wsset high`) → Hoxne sets → `Buffs_Ws` → Moonshade → obi/Orpheus/back.

Defense toggles change idle/engaged gear only (`/aminon` also locks weapons); a spell wears DT gear only where the
job file says so (WHM `Cure_Dt`).

**Engine sets** (fill the ones you want; order above):

| Set | Worn |
|---|---|
| `<set>_Self` / `_Others` / `_Burst` | After a midcast set: spell on you / on anyone but a mob / a burst (`Cure_Others`, `Nuke_Burst`) |
| `Weapon_<Mode>`, `_1h`, `<Mode>Acc` | Weapon mode; `_1h` without DW; `Acc` variant while `/mmode Acc` (any `/mmode` value works) |
| `Dt` `mdt` `Aminon` `SIR` `TH` `Movement` | With their toggles. `TH`: until tagged (swing, shot, WS, JA, a spell that lands); not on you/allies |
| `Incapacitated` | Slept, petrified, stunned, terrorized (not charmed: the client can't change gear) |
| `Sleeping` | Asleep (else `gcinclude.sets.Sleeping`); its weapons pass the TP hold, not locks |
| `Absorb` / `Absorb_TP` | Every Absorb- spell / Absorb-TP; `TH` goes back on top |
| `LightBonus` | Healing Magic midcast |
| `Buffs` `Buffs_Ws` `Buffs_Midcast` | `{ ['Aftermath: Lv.3'] = {...} }` while that buff is up: at rest / WS / midcast. A buff counts once its "gains the effect" message lands, before the buff list shows it |
| `Hoxne_Tp` `Hoxne_Idle` `Hoxne_Dt` `Hoxne_Ws` `Hoxne_<ws>` | `/hoxne` Locked + Enchantment up; not while `/kite` |
| `Hoxne_<set>_<buff>` | While the buff is up (`Hoxne_Tp_Impetus`); `&` = all up. Fewest buffs first, then A-Z |
| `HolyWater` | Right before a Holy Water (else `gcinclude.sets.Holy_Water`) |
| `XIRoll` | Idle with a roll at 11 |
| `*_Received` | A spell cast on you, until it lands (max `ReceivedWindow` 8s) |

**Hoxne layering**, MNK Victory Smite with Impetus: `Ws_Default` → `Victory_Default` → `Victory_Imp` → `Hoxne_Ws` →
`['Hoxne_Victory Smite']` → `['Hoxne_Victory Smite_Impetus']` → `Buffs_Ws` → Moonshade. Hoxne sets take `/mmode`
variants (`Hoxne_Tp_SubtleBlow`).

**Moonshade, grips:** Moonshade goes in `MoonshadeSlot` (Ear2; Ear1 when the WS set has a Sortie earring there) on WS under
`MoonshadeTP` (1750), except `MoonshadeSkip`;
leave it out of WS sets. A Sub that can't go with the final Main (two-hander needs a grip, grip needs a two-hander) is
dropped.

**Received sets** (`ReceivedSets`): `Cure_Received` (Cure/Cura/Curaga), `Cursna_Received`, `Phalanx_Received`,
`Protect_Shell_Received`, `Regen_Received`, `Refresh_Received`, `Waltz_Received` (your boxes only). Start on anyone's
"starts casting" on you, area spells within 10', or your own boxes' notice (`MyBoxes`); off when it lands or is
interrupted. Never over your own action.

**Element gear** (spells in `ElementSkills`, elemental ninjutsu, Quick Draw, cures, WS in `ElementalWS`):

```lua
ElementGear = T{ Obis = T{ Dark = 'Anrin Obi' }, AnyObi = 'Hachirin-no-Obi', Distance = "Orpheus's Sash",
    DistanceMax = nil, Back = nil, Ring = nil, RingSlot = 'Ring2', -- optional, e.g. 'Twilight Cape', 'Zodiac Ring'
    Cures = false, BackOnCures = false, Keep = T{'Oneiros Rope'} };
```

- Obi score: day +10, weather +10 (double +25), opposing element subtracts; never at ≤ 0. Orpheus: `OrpheusPoints`
  (+15 at ≤ 1.93', +1 at ≥ 13', linear between). Higher wins. `Keep` items are never displaced; a `TH` waist stays.
- Helixes: no obi. Cures: obi only (`BackOnCures` adds the back), per job `gcinclude.CureObi = true`. Blue Magic:
  damage spells only.
- Twilight Cape: a day or weather bonus that applies. Zodiac Ring: `ElementSkills` spells only, day matches, never
  Lightsday/Darksday.

## Exclusions: SIRSkip and THSkip

Two lists of spells the engine leaves alone, so the set your job file put on for them is what you cast in:

| List | Stops | Default |
|---|---|---|
| `SIRSkip` | `/sir` putting the `SIR` set over that spell's midcast | `'Absorb-TP', 'Stun'` |
| `THSkip` | `/th` putting the `TH` set over it at an untagged mob (and it won't count as the tag) | `'Absorb-TP', 'Stun'` |

Only that one layer is skipped: Aminon's weapon lock, obi/Orpheus and `Buffs_Midcast` still apply as usual.

**Add a spell, one job:** top of the job file, under the `gcinclude = gFunc.LoadFile(...)` line. Adds to the
default list:

```lua
gcinclude.SIRSkip = T{'Phalanx', 'Reprisal'};   -- PLD: Phalanx keeps its potency gear, Reprisal its own 105 SIR set
gcinclude.THSkip  = T{'Absorb-STR', 'Absorb-ACC'}; -- example: these keep their own macc set at a new mob
```

**Add or remove, every job:** edit the line in `common/gcinclude.lua` settings:

```lua
SIRSkip = T{'Absorb-TP', 'Stun'};
THSkip  = T{'Absorb-TP', 'Stun'};
```

**Remove a default, one job:** in that job's `OnLoad`, before `gcinclude.Initialize()`, replace the list:
`gcinclude.settings.SIRSkip = T{'Absorb-TP'};` (now `/sir` covers Stun on this job).

- Exact spell name, any case: `'Cure IV'`; `'Cure'` matches only Cure I. List every tier you want.
- A spell that needs SIR *and* its own stats: put the SIR pieces in its own set and add it to `SIRSkip` (PLD
  `Reprisal`). Spells not on the list get `SIR` over them (PLD `Cure`, `Protect`).
- Check what's active: `/gchelp` prints both lists for the current job. `/lac reload` after editing.

## Job file

```lua
gcinclude.SIRSkip = T{'Phalanx'};   -- top of file: adds to settings lists (THSkip too)
gcinclude.CureObi = true;           -- top of file: cure obi for this job
profile.OnLoad = function()
    gcinclude.WeaponModes = {'None', 'Savage', 'Leaden'};
    gcinclude.DefaultWeapons = 'Savage';          -- or { Main = 'Burtgang', Sub = 'Aegis' }
    gcinclude.WeaponRoles = { melee = 'Savage', ranged = 'Leaden' };
    gcinclude.MainModes = {'None', 'Burtgang', 'Caliburnus'};
    gcinclude.SubModes  = {'None', 'Aegis', 'Duban'};
    gcinclude.RangeModes = {'None', 'Annihilator'};
    gcinclude.AlwaysDualWield = true;
    gcinclude.AutoFood = 'Grape Daifuku +1';
    gcinclude.Packer = { ['Echo Drops'] = 'stack', ['Instant Reraise'] = 2 };
    gcinclude.BuffSetOrder = T{'Saboteur', 'Aftermath'};
    gcinclude.MeleeModes = {'Default', 'Acc'};    -- own /mmode list (NukeModes for /nukeset)
    gcinclude.MBTier = 'V';
    gcinclude.settings.RefreshGearMPP = 50;       -- any setting, this job only
    gcinclude.Initialize();
end
```

| Helper | Does |
|---|---|
| `gcinclude.EquipMode('Ws')` | `Ws_Default`, then `Ws_<MeleeSet>` unless Default |
| `gcinclude.ByName(name)` | Set `name` (any case), then `name_<MeleeSet>`. False if none |
| `gcinclude.Family(name)` | `'Utsusemi: Ni'` → `'Utsusemi'`, `'Drain III'` → `'Drain'` |
| `gcinclude.CheckTH(force)` | `TH` without weapons at an untagged mob (`force` skips target checks); never `THSkip` |
| `gcinclude.CheckWsBailout()` | False if the WS would fail |
| `gcinclude.BuffCount('Name' or id)` | Buff count (cached ids) |

## Tips

- `gSettings.FastCast` stays 0: idle gear returns on the game's finish packet, and burst timing is learned from real
  casts. A higher value makes LAC's backup timer put idle gear on mid-cast.
- Slot keywords (LuAshitacast): `'remove'` empties the slot; `'displaced'` marks it empty without a packet (cloak covers
  Head, instrument empties Ammo); `'ignore'` leaves it alone.
- HP pieces: `Priority = <HP>` so max HP doesn't dip mid-swap.
- Dynamis RP: wear only what you rank, `/lock neck main sub range`, `/unlock` after.
- Keybinds (setting `Keybinds`, or per job before `Initialize()`; `T{}` = none). `!` Alt, `^` Ctrl, `+` Shift, `@` Win,
  `#` Apps, combined (`^+`). They replace your binds on those keys; unload and job change remove them (`/gckey` ones too).

  ```lua
  Keybinds = T{ {'^`','wm'}, {'+`','wm default'}, {'^+`','def'}, {'!`','hoxne'}, {'@`','automb'} };
  ```

## Something wrong

| Problem | Check |
|---|---|
| Edit does nothing | `/lac reload` (`//gs reload`) |
| Windower: nothing loads | Red `[GoomSwap]`/`[LuAshitacast]` line: do what it says. No `[GoomSwap]` line at all: see Install |
| Windower: `attempt to index global 'gFunc'` or `GearSwap loaded this job file directly` | Job file is in `data/<Name>/` (GearSwap's own spot): move it to `data/goomswap/<Name>/<JOB>.lua`, delete `data/<Name>/` |
| A slot won't change | `/unlock` (it names other holders: `/aminon off`, `/hoxne off`…); weapons are held at `WeaponTPGuard`+ TP and while Aftermath is up (`/wm <mode>` swaps; `/wm <current mode> force` re-applies); `TH`-set weapon while `/th` is on (THF) |
| Weapon in TP set never shows | Engaged, the weapon mode wins: `/wm none`, and `/mainset none` / `/subset none` for slot picks (PLD has only those). Out of combat your idle sets' weapons win (`IdleWeapons = false` to stop) |
| Wrong or no gear | `/checksets`, item spelling, `/gctrace` |
| Action cancelled | Chat says why (Action checks) |
| HUD gone | `/gchud on`, `/gchud pos 500 120` |
