# TODO

Open items from the perf / logic / readability pass (stopped early for usage limits). Each was found by one
reviewer but **not yet independently verified**: re-check against the code before changing anything.

## Fixes found, not applied

| # | Where | Problem | Proposed fix |
|---|---|---|---|
| 1 | `common/gcinclude.lua` `UnlockSlots`, `HoldSet` | A Main/Sub/Range lock let go at 1000+ TP (`/unlock main`, `/aminon off`, `/hoxne off`) stays enabled until the next 0.1s HoldTick, so a HandleDefault in between can swap the weapon and lose TP. | When the last owner lets go of a Main/Sub/Range slot and the TP hold is active, hand it straight to the TP hold (`HeldSlots[slot] = true`, keep `Disabled`), as `CheckDefault` already does after Sleep. `HoldSet` must pick its slots before releasing its own hold. |
| 2 | `gcinclude.DualWieldState` | Main-job dual wield (NIN/DNC/THF main) never saves `LastDualWield`, so the "zoning, kept last" fallback returns the wrong answer while zoning. | Set `gcinclude.LastDualWield = true` on the main-job path before returning. |
| 3 | `gcinclude.EquipMode` | A missing `<prefix>_<mode>` set (e.g. `Tp_Hybrid` with `/mset hybrid`) makes LAC print `Set not found` on every HandleDefault. | Skip a missing variant and name it once (`modeWarned` table) instead of passing the bare name to `gFunc.EquipSet`. |
| 4 | `gcinclude.CheckSupplies` | Every ranged shot and ranged WS looks the worn ammo up by name and allocates `T{25, 26, 27}`. | Use `gData.GetEquipment().Ammo.Resource` (already the worn item's resource) and a file-level `SUPPLY_SKILLS` table. |
| 5 | `gcinclude.RollBuffs` | Repeats the 31 roll names in `gcinclude.Rolls`, so a new roll has to be added to both. | Build `RollBuffs` from `gcinclude.Rolls`. |
| 6 | `gcinclude.CheckTH` | The action's target is stored in a local named `action`. | Rename the local to `target`. |
| 7 | `gcinclude.Enchants` comment | The field list leaves out `alreadyOn`, `preAct`, `extPending`. | Add them to the comment. |

## Not reviewed yet

- `common/gcinclude.lua` from line ~2240 to the end (help, keybinds, Aminon, buff sets, XIRoll, debuffs, `CheckDefault`, init/unload, action wrapper, Absorb, Moonshade, nukes).
- `common/gcauto.lua`, `common/gcaction.lua` (packet readers, tagging, auto food/soda/nuke, cast timing, queue).
- `common/gchud.lua`, `common/gcdisplay.lua`, `common/scdata.lua` (HUD render every frame, state files).
- `windower/GearSwap/data/goomswap/` and `windower/GearSwap/data/default.lua` (the Windower adapter).

Hot paths to look at first: `CheckDefault` (every outgoing packet chunk), HoldTick/UpdateHold (every frame),
gcauto packet readers (every 0x28), gchud render (every frame).

## After the rename (GoomSwap)

- Not re-run on all 22 jobs after the rename: run the full Windower harness.
- GitHub repo is still named `shayswap` (rename in GitHub settings if wanted).
