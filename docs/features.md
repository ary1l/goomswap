# What the engine does

[← Back to the README](../README.md)

## Weapons

- The mode is what you return to; action sets naming weapons still swap them. Slot picks beat the mode for their slot.
- Out of combat, idle sets' weapons win (`IdleWeapons`); Main+Sub and Range+Ammo move as pairs.
- At `WeaponTPGuard`+ TP (examples: 0 on mages, 100 PLD) Main/Sub/Range stay, except songs, rolls, cures,
  enfeebling, enhancing, geomancy. Aftermath holds them too (`AftermathHold`). Weapon commands always swap.
- `Weapon_<Mode>_1h` without DW (NIN 10+, DNC 20+, THF 83+, main or sub). `gcinclude.AlwaysDualWield = true` forces it.
  A Sub refused for lack of DW stays off 15s.
- THF `/th`: `TH` weapons stay on; other jobs drop them at the tag.
- Augmented cycle entry: `gcinclude.WeaponItemMap = { ['Rostam B'] = { Name = 'Rostam', AugPath = 'B' } };`.

## Defense, locks, Hoxne

- `/aminon`: `Aminon` set (else `mdt`), weapon mode's Main/Sub on and locked even idle (Regain TP); turns `/sir` off.
- `/lock` beats everything until `/unlock`. Each lock has an owner; `/unlock` frees yours and names the rest.
- `/hoxne`: Ampulla kept in Ammo (Ammo, Range locked), used 3s after Enchantment ends (`HoxneAutoUse = false` stops).
  Zoning turns it off.

## Magic burst

`Burst` goes on when a nuke lands in a live skillchain of its element within `MBWindow` (10s). You cast; GoomSwap
dresses. `/burst` = every nuke. `MBSkills` = skills that get it.

## Dispelga

Dispelga only goes off with Daybreak in the main hand. GoomSwap puts Daybreak in `Main` for its precast and
midcast on any job, over whatever your sets name there, so no job file needs a Dispelga set to cast it (one named
`Dispelga` or `Dispelga_Precast` still works for the other slots). `/lock` or `/aminon` on Main stops it.

## Items

- **Packer** (Ashita, Bellhop): `PackerItems` → `char.lua` `Packer` → `gcinclude.Packer = { ['Trump Card'] = 99 }`;
  `'stack'` = full, `false` drops. Plus a stack of each `Food`. Windower: `profile.Packer` → `//gs org`.
- **`/gce`:** waits the item's delay (`EnchantDelays`, `EnchantWindow`), retries 5x, then frees the slot. Rings: Ring2.
- **Einherjar** (Ashita): reserver at the Entry Gate `/ejenter ort` trades lamps to the party; boxes accept and enter.
  `/ejexit` leaves. Windower: Valkyrie.
- Warns at `AmmoWarn` ammo, `NinjaToolWarn` tools. Asleep under Stoneskin: `/cancel Stoneskin`.

## Action checks

Cancelled before gear moves, reason in chat (`Validate = false` off): KO, sleep/stun/petrify/terror/charm, Mute,
Silence, Amnesia (JA/WS), recast (`m:ss`), already casting, MP short (arts-adjusted; `ValidateMP`), stratagems,
Waltz TP. Nothing is queued.
