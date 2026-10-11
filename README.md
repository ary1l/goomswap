# ShaySwap

LuAshitacast engine for multiboxing. You fill in sets; it picks the gear. Runs on Ashita v4, and on
Windower 4 through the GearSwap adapter in `windower/`.
Full reference: `COMMANDS.md`.

## Install

### Ashita v4 (LuAshitacast)

1. Copy `common/` and `examples/` into `Ashita/config/addons/luashitacast/`.
2. Copy `examples/<JOB>.lua` into your character folder (`luashitacast/<Name>_<id>/`) and put in your gear.
3. `/addon load luashitacast`, then `/lac load` (or change job). After edits: `/lac reload`.

### Windower 4 (GearSwap)

1. Copy everything in `windower/GearSwap/data/` into `Windower/addons/GearSwap/data/`
   (that is `default.lua` and the `shayswap/` folder).
2. Copy `common/` to `Windower/addons/GearSwap/data/shayswap/common/`.
3. Copy `examples/<JOB>.lua` to `Windower/addons/GearSwap/data/shayswap/<Name>/<JOB>.lua` and put in your gear.
   A job file straight in `shayswap/` (no name folder) is used by every character.
4. `//lua load gearswap`, then change job (or `//gs reload`).

- GearSwap only uses `default.lua` for jobs with no GearSwap file of their own. Already have a
  `default.lua`? Rename this one to `<Name>.lua`.
- Commands take two slashes: `//wm`, `//def`, `//gchud` (or `//gs c wm`). All boxes:
  `//send @all gs c <command>` (Send addon). Keys are the same as Ashita.
- Updating: replace `shayswap/common/` (and `shayswap/*.lua` if `windower/` changed).
- Windower differences: the HUD and bar are display only (use commands; drag to move; boxes on one PC
  share HUD state over IPC). Auto-nuke casts at the mob without targeting it. Packer list: `//gs org`
  (needs the Organizer addon). The bar shows Atk/Def as 0.

## Quick start

1. Fill `Idle`, `Tp_Default`, `Ws_Default`. Everything else can wait.
2. Template jobs (BLM BST DNC DRG DRK NIN PUP RUN SAM SMN WAR): a set named after an ability, spell,
   skill or WS (`['Savage Blade']`) is used for that action; a spell with no set uses its family's
   (`['Cure']` for Cure IV). `_Hybrid`/`_Acc` follow `/meleeset`. Other jobs name their sets in the job file.
   Their example gear comes from [GetAwayCoxn's Luashitacast-Profiles](https://github.com/GetAwayCoxn/Luashitacast-Profiles):
   swap in your own (MIT, see `examples/LICENSE-GetAwayCoxn.txt`).
3. Leave `gSettings.FastCast` at 0 (see Fast Cast below).
4. `/checksets` finds empty sets and bad item names.

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

- **Weapons**: weapon modes per job (`/wm`). At 1000+ TP, engaged or not, weapons don't change so you keep TP.
  Can't dual wield: uses the `_1h` version of the mode. Dual Wield = main or sub NIN Lv10+, DNC Lv20+, THF Lv83+ at
  the *effective* level, so a restricted support job (Sheol Gaol, SJ Restriction) counts as none; losing it swaps to
  `_1h` at once, even at 1000+ TP. `/dw` shows why; `/dw on|off|auto` overrides.
- **Layers**, lowest to highest: your sets → weapons (+ `TH`-set weapons while `/th` is on) → MDT/Aminon → Hoxne →
  TH → received gear → buff sets → XIRoll → debuff and craft/zeni/fish/rr sets. Midcast: job sets → TH → `Buffs_Midcast` → Absorb → LightBonus → obi/Orpheus/back/ring → SIR.
- **Automatic**: obi/Orpheus/Twilight Cape/Zodiac Ring by day, weather and distance (nukes, helixes, elemental ninjutsu,
  Quick Draw, cures, elemental WS); a Sub that can't go with the Main (2-handed/grip) is dropped;
  Hoxne Ampulla used when its Enchantment buff isn't up; low ammo / Utsusemi tool warnings; `/cancel Stoneskin` when asleep under it;
  your /def set (else Dt) minus weapons + `Incapacitated` when slept/petrified/stunned/terrorized, `Sleeping` over it when asleep (its weapons past the TP hold, e.g. Lorg Mor to wake);
  Moonshade under 1750 TP on every WS; Holy Water
  on Doom; food and soda (both off on zoning); `/th`: TH gear at rest and on spells/shots at a mob until it is tagged (your hit, shot,
  WS, ability, or a spell/step that lands; BLU: `BluMagTH` spells only), `TH`-set weapons the whole time; lockstyle on load if `LockstyleSet` is set.
- **Action checks**: spells, abilities and WS that would fail are cancelled before any gear moves, with the
  reason in chat. A recast back within 5s is queued and fires when ready, after the forced delay of your last action
  (BG-Wiki: spell 3s, WS 2s, job ability 2s with other job abilities allowed after 1s).
- **Holds**: `/naked` `/weaponsonly` `/abysseaproc` strip slots and keep them bare; `/capacity` `/jubilee`
  `/dynamisrp` put on and keep your best capacity cape / Jubilee Ring / Dynamis - Divergence neck.
- **Magic burst** (RDM BLM SCH GEO): the Burst set goes on by itself whenever a nuke will land inside a live
  skillchain of its element on that target. `/automb` (Win+grave) makes the box cast the chain's nuke itself
  (tier I/III/V by `/mbtier`; Transfixion/Compression: SCH helix). `/burst`: Burst set on every nuke.
- **Received gear**: when anyone starts casting Cure/Cura/Curaga, Phalanx, Protect, Shell, Regen, Refresh or
  Cursna on you (or Curaga/Cura/Protectra/Shellra near you from a party member), the matching `*_Received` set goes
  on until that spell lands or is interrupted (8s max). Waltzes are instant abilities,
  so there is nothing to see in advance: `Waltz_Received` only works when one of **your own boxes** uses Curing
  Waltz on you (it tells your box by `/ms`; only your own boxes get told, never other players), and may still land after the heal. Divine Waltz (area, aimed at
  the dancer) and anyone else's Waltz: no swap.
- **Multibox**: `/mss /lac fwd <cmd>` runs a command on every box. HUD (`/gchud`): one line per box, click
  a cell to change it on that box.

```
     wpn  ml   nk   def  mb     kt fd sd
COR  Ana  Def       MDT         .  .  .
RDM  Max  Def  Pow  -    AutoV  .  fd .
```

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

## Something wrong

| Problem | Check |
|---|---|
| Edit does nothing | `/lac reload` |
| A slot won't change | `/unlock`, or it's a weapon held at 1000+ TP (`/wm <mode> force`), or a `TH`-set weapon while `/th` is on |
| Weapon in Idle/TP/Town never shows | Weapon mode overrides it at rest; `/wm none` to manage weapons yourself. `/th` on: `TH`-set weapons override both |
| Wrong/no gear | `/checksets`, then the item name spelling; `/gctrace` names each set used |
| Action cancelled | The chat line says why. See Action checks in `COMMANDS.md` |
| HUD gone | `/gchud on`, `/gchud pos 500 120` |
