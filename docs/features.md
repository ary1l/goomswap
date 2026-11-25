# What the engine does

[← Back to the README](../README.md)

## Weapons

- The mode is what you return to; action sets naming weapons still swap them. Slot picks beat the mode for their slot until `/wm` changes mode: it clears picks for the slots its `Weapon_` set names (a `/rw` pick stays when the set has no Range).
- Out of combat, idle sets' weapons win (`IdleWeapons`); Main+Sub and Range+Ammo move as pairs.
- At `WeaponTPGuard`+ TP (examples: 0 on mages, 100 PLD) Main/Sub/Range stay, except songs, rolls, cures,
  enfeebling, enhancing, geomancy. Aftermath holds them too (`AftermathHold`). Weapon commands always swap.
- `Weapon_<Mode>_1h` without DW (NIN 10+, DNC 20+, THF 83+, main or sub). `gcinclude.AlwaysDualWield = true` forces it.
  A Sub refused for lack of DW stays off 15s.
- THF `/th`: `TH` weapons stay on; other jobs drop them at the tag.
- Slot picks (`/mw` `/sw` `/rw`): any item a `Weapon_` set names, plus `MainModes`/`SubModes`/`RangeModes`. An
  augmented item is picked as the bar shows it (`Rostam (B)`), or by your own label in
  `gcinclude.WeaponItemMap = { RostamA = { Name = 'Rostam', AugPath = 'A' } };`.
- COR/RNG examples: `/wm` is the melee pair (`Weapon_Naegling`), `/rw` the gun or bow (`RangeModes`), shown as its
  own pill. `DefaultWeapons = { Weapons = 'Naegling', Range = 'Anarchy +2' }` sets both; `/wm default` restores both.
- `gcinclude.RangeAmmo = { ['Sparrowhawk +2'] = 'Chrono Arrow' }`: with that weapon in Range, sets' Bullets/Bolts become
  that Arrow (by the ammo name's last word). Other Ammo (Hoxne Ampulla, tathlums) is never touched.

## Defense, locks, Hoxne

- `/aminon`: `Aminon` set (else `mdt`), weapon mode's Main/Sub on and locked even idle (Regain TP); turns `/sir` off.
- `/lock` beats everything until `/unlock`. Each lock has an owner; `/unlock` frees yours and names the rest.
- `/hoxne`: Ampulla kept in Ammo (Ammo, Range locked), used 3s after Enchantment ends (`HoxneAutoUse = false` stops).
  Zoning turns it off.

## Magic burst

`Burst` goes on when a nuke lands in a live skillchain of its element within `MBWindow` (10s). You cast; GoomSwap
dresses. `/burst` = every nuke. `MBSkills` = skills that get it.

## Dispelga

Dispelga needs Daybreak in Main: GoomSwap puts it there for precast and midcast on any job, so no Dispelga set is
needed (one still dresses the other slots). `/lock` or `/aminon` on Main stops it.

## Items

- **Packer**: `/lac gear` (LuAshitacast, with the Packer plugin loaded: `/load packer`) gathers the gear of every
  set in the job file and the job's `profile.Packer` list into your inventory and wardrobes; the Packer plugin sorts
  the rest by its own config. LuAshitacast reads only the sets' own slots, so at load GoomSwap adds to that list, in
  memory (the file is not written): `char.lua`'s `Packer` (else the shared file's), sets inside sets (`Buffs`),
  GoomSwap's own sets and `char.lua`'s `sets`, and the items its commands and layers wear that you own (Warp and
  Dimensional rings, Hoxne Ampulla, obis, Moonshade, capacity capes). Counts: a number, `'all'`, or (in `char.lua`)
  `'stack'`, which becomes the item's stack size. `/gcedit` Settings edits the lists (**Get gear now**). The Bellhop
  packer (`/packer`, `PackerItems`, `PackerPutAway`, `gcinclude.Packer`) is gone; Settings offers to move an old list
  into Packer.
- **`/gce`:** waits the item's delay (`EnchantDelays`, `EnchantWindow`), retries 5x, then frees the slot. Rings: Ring2.
- **Einherjar:** a separate Ashita addon, not part of this repository (`/ejenter`, `/ejlamps`, `/ejexit`).
- Asleep under Stoneskin: `/cancel Stoneskin` (Ashita's `debuff` addon), twice at most per sleep.

## Action checks

Cancelled before gear moves, reason in chat: KO, sleep/stun/petrify/terror/charm, Mute, Silence, Amnesia (JA/WS),
recast (`m:ss`), already casting, stratagems. Nothing is queued.

Sneak on yourself, Spectral Jig or Stoneskin with that buff already up: cancelled, the buff goes with `/cancel`
(Ashita's `debuff` addon), then the action is sent again once the buff is gone. If `/cancel` did nothing, one
message says so and nothing is re-sent.
