# TODO

Open items from the perf / logic / readability pass (stopped early for usage limits).

## Fixes found

All 7 from the first pass are applied (TP hold after an unlock at 1000+ TP, main-job dual wield while zoning,
missing `_<mset>` set named once, ammo lookup, `RollBuffs` built from `Rolls`, `CheckTH` local name, `Enchants`
comment).

## Not reviewed yet

- `common/gcinclude.lua` from line ~2240 to the end (help, keybinds, Aminon, buff sets, XIRoll, debuffs, `CheckDefault`, init/unload, action wrapper, Absorb, Moonshade, nukes).
- `common/gcauto.lua`, `common/gcaction.lua` (packet readers, tagging, auto food/soda/nuke, cast timing, queue).
- `common/gchud.lua`, `common/gcdisplay.lua`, `common/scdata.lua` (HUD render every frame, state files).
- `windower/GearSwap/data/goomswap/` and `windower/GearSwap/data/default.lua` (the Windower adapter).

Hot paths to look at first: `CheckDefault` (every outgoing packet chunk), HoldTick/UpdateHold (every frame),
gcauto packet readers (every 0x28), gchud render (every frame).

## After the rename (GoomSwap)

- GitHub repo is still named `shayswap` (rename in GitHub settings if wanted).
