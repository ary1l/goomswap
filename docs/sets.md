# Sets and job files

[← Back to the README](../README.md)

## How sets stack

Later wins, slot by slot.

**Idle/engaged:** (engaged with `/proc`: only `Proc`, then the weapon mode; no other set but 5's sleep/doom ones)
1. Job file: `Idle` → `Idle_<weapon>` → `Idle_<mode>` → `Idle_<weapon>_<mode>` / `Tp_Default` → `Tp_<weapon>` →
   `Tp_<mset>` → `Tp_<weapon>_<mset>` → buff sets → `Dt` → `Dt_<weapon>` → `Dt_<mset>` (`/dt`) → `Movement` (`/kite`).
   `<weapon>` is the `/wm` mode (`Tp_Chango` while `/wm Chango`). A weapon with no set of its own takes its type's:
   `Tp_2h` for a two-handed Main (Great Sword, Great Axe, Scythe, Polearm, Great Katana, Staff), `Tp_1h` for a
   one-handed one (Dagger, Sword, Axe, Katana, Club); Hand-to-Hand takes neither. With no `/wm` mode, the Main worn.
2. Hoxne sets → auto `Idle_Regen` `Idle_Refresh` `Dt` → `Town`.
3. Weapon mode → `mdt`/`Aminon` → Hoxne Ampulla → `TH` → `*_Received` → `Buffs` → `Buffs_Tp` (engaged) or
   `Buffs_Idle` (not engaged) → Hoxne + buff
   (`Hoxne_Tp_Berserk`: over `Buffs['Berserk']`, it wins the slots both name) → XIRoll.
4. `Incapacitated` (slept, petrified, stunned, terror), over 1-3: Aminon, else `mdt`, else `Dt` (no weapons), its set.
5. `Sleeping` → `Doomed`.

**Precast:** job file → `Buffs_Precast` (`['Spontaneity']`: next spell near-instant, skip fast cast).

**Midcast:** job file → `TH` → `_Self` `_Others` `_Burst` → `Absorb` → `Buffs_Midcast` → `LightBonus` →
obi/Orpheus/back/ring → `SIR`. WHM cures: `['Healing Magic']` → `Self_Cure` → `Cure_LowMP` → `Cure_Dt` → obi → `SIR`.

**WS:** job file (`Ws_Default` → `Ws_<weapon>` → `Ws_<mset>` → `Ws_<weapon>_<mset>` → the WS's own set →
`<WS>_<weapon>` → `<WS>_<mset>` → `<WS>_<weapon>_<mset>`; `<weapon>` falls back to `2h` / `1h` as above) → `_HighBuff` →
`_Dt` (`/dt`) → Hoxne (→ its `_Dt`) → `Buffs_Ws` → Hoxne + buff (`Hoxne_Ws_Berserk`, → its `_Dt`) → Moonshade →
obi/Orpheus/back.
`/proc`: only `Ws_Proc` (else `Proc`) in place of all of that; the job file's checks still run.
`/dt` adds `_Dt` to each WS set worn: `Ws_Dt`, `Ws_SubtleBlow_Dt`, `['Victory Smite_Dt']`, `Hoxne_Ws_Dt`.

**Your file lacks one?** No code needed: make the set by name ([editor: Add a set or mode](gcedit.md#add-a-set-or-mode))
and its toggle wears it. Until then it falls back as the table says (`Aminon` → `mdt`).

| Engine set | Worn |
|---|---|
| `<set>_Self` `_Others` `_Burst` | spell on you / on others / a burst |
| `Weapon_<Mode>` `_1h` `<Mode>Acc` | weapon mode; no DW; `/mset acc` |
| `Tp_<Mode>` `Ws_<Mode>` `Tp_<Mode>_<mset>` | TP / WS gear for that weapon mode, over `Tp_Default` / `Ws_Default` (`Tp_Chango`) |
| `Tp_2h` `Tp_1h` `Ws_2h` `Tp_2h_<mset>` | a weapon with no `Tp_<Mode>` of its own, by its Main's type |
| `<set>_<Mode>` `Dt_Chango` `Idle_Chango` `['Savage Blade_Naegling']` | that weapon mode's version of a set worn by name, `Dt` or `Idle` (else `_2h` / `_1h`) |
| `mdt` `Aminon` `SIR` `TH` | their toggles (`/def`, `/sir`, `/th`); `TH` until tagged; `Aminon` missing or empty: `mdt` |
| `Dt` | `/dt`: every example wears it by `ByName('Dt')`; and on its own below `DTGearHPP` HP |
| `Movement` | your job file, not GoomSwap: every example wears it while moving, most also on `/kite` (PLD wears `kite`, BLU `Evasion`) |
| `Dt_<mset>` | `/dt` with an `/mset` mode on (`Dt_SubtleBlow`), over `Dt`: every example wears `Dt` by `ByName` |
| `Idle_Refresh` `Idle_Regen` `Idle_Regain` | `/idleset`; low MP/HP |
| `Midshot_Acc` `Midshot_<Mode>` `Midshot_<Mode>_Acc` | COR RNG PLD shots: `/mset acc`; that weapon mode's own (`ByName('Midshot')`, like a WS); `Midshot_Acc` again over `TripleShot` / `DoubleShot` |
| `Proc` `Ws_Proc` | `/proc`: engaged, `Proc` in place of your sets (weapon mode stays); on WS `Ws_Proc` (else, missing or empty, `Proc`) in place of every WS set |
| `Incapacitated` `Sleeping` | disabled / asleep (weapons pass the TP hold) |
| `Absorb` `Absorb_TP` `LightBonus` | Absorb spells / Healing Magic |
| `Buffs` `Buffs_Tp` `Buffs_Idle` `Buffs_Ws` `Buffs_Precast` `Buffs_Midcast` | `{ ['Aftermath: Lv.3'] = {...} }` while the buff is up: `Buffs` idle and engaged, `Buffs_Tp` engaged only, `Buffs_Idle` not engaged (both over `Buffs`), `Buffs_Ws` weapon skills, `Buffs_Precast` / `Buffs_Midcast` spells (precast / midcast); each is its own set in `/gcedit` |
| `Hoxne_Tp` `_Idle` `_Dt` `_Ws` `Hoxne_<set>_<buff>` | `/hoxne` + Enchantment; each also `_<mset>` (`Hoxne_Dt_Impetus_SubtleBlow`). `Hoxne_<set>_<buff>` (`Hoxne_Tp_Berserk`, `&` for several: `Hoxne_Tp_Berserk&Aggressor`) while those buffs are up too, over the plain buff sets (`Buffs['Berserk']`) |
| `Ws_Dt` `<ws>_Dt` `<ws>_<mset>_Dt` | WS while `/dt` is on |
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
profile.Packer = { 'Echo Drops', { Name = 'Grape Daifuku +1', Quantity = 12 } }; -- /lac gear
profile.OnLoad = function()
    gcinclude.WeaponModes = {'None', 'Savage', 'Leaden'};
    gcinclude.DefaultWeapons = 'Savage';          -- or { Main = 'Burtgang', Sub = 'Aegis' }
    gcinclude.WeaponRoles = { melee = 'Savage', ranged = 'Leaden' };
    gcinclude.SubModes = {'None', 'Duban'};      -- optional: /sw picks; items in Weapon_ sets are picks already
    gcinclude.AlwaysDualWield = true;
    gcinclude.Rules = { { on = 'Default', when = { buff = 'Cover' }, wear = 'Fealty' } }; -- /gcedit RULES
    gcinclude.MeleeModes = {'Default', 'Acc'};    -- own /mset list (NukeModes: /nukeset)
    gcinclude.settings.RefreshGearMPP = 50;
    gcinclude.Initialize();
end
```

| Helper | Does |
|---|---|
| `gcinclude.EquipIdle()` | `Idle` + `Idle_<weapon>` + `Idle_<mode>` + `Idle_<weapon>_<mode>` (use in `HandleDefault`) |
| `gcinclude.RangedAcc()` | true on `/mset acc` |
| `gcinclude.EquipMode('Ws')` | `Ws_Default` + `Ws_<weapon>` + `Ws_<mset>` + `Ws_<weapon>_<mset>` |
| `gcinclude.ByName(name)` | set `name`, then `name_<weapon>`, `name_<mset>`, `name_<weapon>_<mset>`; false if none |
| `gcinclude.Family(name)` | `'Drain III'` → `'Drain'` |
| `gcinclude.CheckTH(force)` | `TH` at an untagged mob |
| `gcinclude.CheckWsBailout()` | false if the WS would fail |
| `gcinclude.EquipSATA(ws.Name)` | THF, SA/TA up: `<WS>_SATA` / `_SA` / `_TA` (`<WS>_<mset>_SA`), else `Ws_<mset>_SA`... |
| `gcinclude.BuffCount(x)` | buff count |

No `HandleItem` needed: the engine wears `Holy_Water` itself; add one only for your own item sets.

**Set names:** the game's own name, worn by `ByName`. An empty set does nothing, and in a fallback chain counts as
missing. The examples carry only sets with gear; `/gcedit` → **+ New set** lists the engine's other names.

| Set | Worn |
|---|---|
| `['Savage Blade']` `['Savage Blade_Acc']` `['Savage Blade_HighBuff']` | that WS; `/mset acc`; `/wsset high` |
| `Ws_Default` `Ws_Acc` `Ws_HighBuff` | any WS, under its own |
| `['Berserk']` | that job ability |
| `['Enhancing Magic']` `['Cure']` `['Phalanx']` | skill, then spell or family (`Cure IV` → `Cure`) |
| `['Healing Magic_Precast']` `['Stoneskin_Precast']` | over `Precast` |
| `Tp_Default` `Tp_SubtleBlow` `Tp_Acc` | engaged, `/mset` |

Any `/mset` mode works the same way: add it to `gcinclude.MeleeModes` (or `/gcedit` → **+ /mset mode**) and every
`<set>_<mode>` goes on over its base set.

Groups keep a plain name (`Phantom Roll` for every roll, `Quick Draw`, `Nitro`, `Enmity`, BRD song groups).

## Tips

- Slot words: `'remove'` empty, `'displaced'` empty without a packet, `'ignore'` leave alone.
- `Priority = <HP>` keeps max HP up mid-swap.
