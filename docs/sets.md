# Sets and job files

[← Back to the README](../README.md)

## How sets stack

Later wins, slot by slot.

**Idle/engaged:**
1. Job file: `Idle` → `Idle_<mode>` / `Tp_Default` → `Tp_<mset>` → buff sets → `Dt` (`/dt`) → `Movement` (`/kite`).
2. Hoxne sets → auto `Idle_Regen` `Idle_Refresh` `Dt` → `Town`.
3. Weapon mode → `mdt`/`Aminon` → Hoxne Ampulla → `TH` → `*_Received` → `Buffs` → XIRoll.
4. `Incapacitated` (slept, petrified, stunned, terror), over 1-3: Aminon, else `mdt`, else `Dt` (no weapons), its set.
5. `Sleeping` → `Doomed` → `Reraise` → craft/zeni/fish/rr.

**Midcast:** job file → `TH` → `_Self` `_Others` `_Burst` → `Absorb` → `Buffs_Midcast` → `LightBonus` →
obi/Orpheus/back/ring → `SIR`. WHM cures: `['Healing Magic']` → `Self_Cure` → `Cure_LowMP` → `Cure_Dt` → obi → `SIR`.

**WS:** job file → `_HighBuff` → Hoxne → `Buffs_Ws` → Moonshade → obi/Orpheus/back.

| Engine set | Worn |
|---|---|
| `<set>_Self` `_Others` `_Burst` | spell on you / on others / a burst |
| `Weapon_<Mode>` `_1h` `<Mode>Acc` | weapon mode; no DW; `/mset acc` |
| `Dt` `mdt` `Aminon` `SIR` `TH` `Movement` | their toggles; `TH` until tagged |
| `Idle_Refresh` `Idle_Regen` `Idle_Regain` | `/idleset`; low MP/HP |
| `Midshot_Acc` | `/rangedset acc` |
| `Proc` `Ws_Proc` | `/proc`: engaged over your sets (`Dt` stays on top); on WS `Ws_Proc`, else `Proc` |
| `Incapacitated` `Sleeping` | disabled / asleep (weapons pass the TP hold) |
| `Absorb` `Absorb_TP` `LightBonus` | Absorb spells / Healing Magic |
| `Buffs` `Buffs_Ws` `Buffs_Midcast` | `{ ['Aftermath: Lv.3'] = {...} }` while the buff is up |
| `Hoxne_Tp` `_Idle` `_Dt` `_Ws` `Hoxne_<set>_<buff>` | `/hoxne` + Enchantment |
| `XIRoll` | idle with a roll at 11 |
| `*_Received` | a spell coming at you (`ReceivedSets`, 8s max) |

- **Moonshade:** leave it out of WS sets; added below `MoonshadeTP` (not `MoonshadeSkip`). WS set's Ear2 a Sortie or
  "Right ear:" item → Moonshade in Ear1, else Ear2.
- **Grips:** a Sub that can't go with the Main is dropped.
- **Element gear** (`ElementSkills`, ninjutsu, Quick Draw, cures, `ElementalWS`):
  ```lua
  ElementGear = T{ Obis = T{ Dark = 'Anrin Obi' }, AnyObi = 'Hachirin-no-Obi', Distance = "Orpheus's Sash",
      Keep = T{'Oneiros Rope'} };
  ```
  Obi: day +10, weather +10/+25, opposite subtracts; Orpheus by distance (`OrpheusPoints`); higher wins. Helixes no obi;
  cures obi only (`gcinclude.CureObi`).

**SIRSkip / THSkip** (default `'Absorb-TP', 'Stun'`): spells `/sir` / `/th` leave alone, exact names; `/gchelp` lists
them. Add per job as in [Job file](#job-file) below; replace in `OnLoad`: `gcinclude.settings.SIRSkip = T{...};`.

## Job file

```lua
gcinclude.SIRSkip = T{'Phalanx'};   -- top: adds to the list
gcinclude.CureObi = true;           -- top: cure obi
profile.OnLoad = function()
    gcinclude.WeaponModes = {'None', 'Savage', 'Leaden'};
    gcinclude.DefaultWeapons = 'Savage';          -- or { Main = 'Burtgang', Sub = 'Aegis' }
    gcinclude.WeaponRoles = { melee = 'Savage', ranged = 'Leaden' };
    gcinclude.MainModes = {'None', 'Burtgang'};  gcinclude.SubModes = {'None', 'Aegis', 'Duban'};
    gcinclude.AlwaysDualWield = true;
    gcinclude.Food = {'Grape Daifuku +1'};
    gcinclude.Packer = { ['Echo Drops'] = 'stack' };
    gcinclude.MeleeModes = {'Default', 'Acc'};    -- own /mset list (NukeModes: /nukeset)
    gcinclude.settings.RefreshGearMPP = 50;
    gcinclude.Initialize();
end
```

| Helper | Does |
|---|---|
| `gcinclude.EquipIdle()` | `Idle` + `Idle_<mode>` (use in `HandleDefault`) |
| `gcinclude.RangedAcc()` | true on `/rangedset acc` |
| `gcinclude.EquipMode('Ws')` | `Ws_Default` + `Ws_<mset>` |
| `gcinclude.ByName(name)` | set `name`, then `name_<mset>`; false if none |
| `gcinclude.Family(name)` | `'Drain III'` → `'Drain'` |
| `gcinclude.CheckTH(force)` | `TH` at an untagged mob |
| `gcinclude.CheckWsBailout()` | false if the WS would fail |
| `gcinclude.BuffCount(x)` | buff count |

No `HandleItem` needed: the engine wears `Holy_Water` itself; add one only for your own item sets.

**Set names** (every example, same handlers): the game's own name, worn by `ByName`; empty sets do nothing.

| Set | Worn |
|---|---|
| `['Savage Blade']` `['Savage Blade_Acc']` `['Savage Blade_HighBuff']` | that WS; `/mset acc`; `/wsset high` |
| `Ws_Default` `Ws_Acc` `Ws_HighBuff` | any WS, under its own |
| `['Berserk']` | that job ability |
| `['Enhancing Magic']` `['Cure']` `['Phalanx']` | skill, then spell or family (`Cure IV` → `Cure`) |
| `['Healing Magic_Precast']` `['Stoneskin_Precast']` | over `Precast` |
| `Tp_Default` `Tp_SubtleBlow` `Tp_Acc` | engaged, `/mset` |

Each file ends its sets with a Templates block (one of each, blank) to copy from. Groups keep a plain name
(`Phantom Roll` for every roll, `Quick Draw`, `Nitro`, `Enmity`, BRD song groups).

## Tips

- Slot words: `'remove'` empty, `'displaced'` empty without a packet, `'ignore'` leave alone.
- `Priority = <HP>` keeps max HP up mid-swap.
