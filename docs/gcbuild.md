# A job file from the gear you own: `/gcbuild`

[← Back to the README](../README.md)

`/gcbuild` takes the job's example file and keeps only the gear your character actually has, so you start from sets
that work instead of someone else's gear list.

**Run it**

1. The examples must be installed in `luashitacast/examples/` ([Install](../README.md#install), step 1).
2. `/gcbuild` needs a GoomSwap job file loaded (its commands come with one): load the example first
   ([First steps](../README.md#first-steps), step 1).
3. Type `/gcbuild` (your current job) or `/gcbuild RDM` (any job). It writes `<JOB>.proposed.lua` in the character's
   folder (`luashitacast/<Name>_<id>/`); the top of the file says what is
   missing and what to move.

**Then, on your current job:** the draft opens in the set editor ([/gcedit](gcedit.md)). Its `To fill`
tab lists the slots left out; an empty slot shows the example's piece and why. Pick gear you own for them, then
`Save + reload`: the draft becomes your `<JOB>.lua` (the file LuAshitacast has loaded for this job, else
`<Name>_<id>/<JOB>.lua`), the old one kept as `<JOB>.<date>-<time>.gcedit.bak`, and it loads. Close the editor
instead and nothing but the `.proposed.lua` is written. With unsaved changes in the editor, `/gcbuild` writes the
file and leaves the editor alone.

**For another job:** run `/gcbuild` on that job to finish it in the editor, or open `<JOB>.proposed.lua`, fill the
commented-out slots, save it as `<JOB>.lua`, `/lac reload`, then `/checksets`.

`/gcbuild` itself only writes `<JOB>.proposed.lua`: your `<JOB>.lua` changes only when you Save in the editor.

**What it does to each line of each set**

It looks through every bag (Inventory, Wardrobes 1-8, Safe, Safe 2, Storage, Locker, Satchel, Sack, Case) and your
Storage Slips, and compares by item name:

| Your character | The line in the proposed file |
|---|---|
| has the item, as the example names it | unchanged |
| has it, but with different augments | name only, your copies' augments in a comment — so it still equips |
| has it, but only in a bag gear can't be equipped from, or on a slip | unchanged, marked `move it to a wardrobe` |
| doesn't have it | commented out, marked `not owned` |
| has one, and the set wears two (same ring in `Ring1` and `Ring2`) | the second is commented out, marked `only 1 owned` |

```lua
    ['Savage Blade'] = {
        Head = 'Nyame Helm',
        Back = 'Sucellos\'s Cape', -- your augments differ from the example's: MND+20, Haste+10
        Ring1 = 'Chirich Ring +1',
        --Ring2 = 'Chirich Ring +1', -- only 1 owned
        --Ear1 = 'Ishvara Earring', -- not owned
        Feet = 'Leth. Houseaux +3', -- in Safe: move it to a wardrobe
    },
```

A commented-out slot simply shows whatever the set underneath puts there (`Ws_Default` under a weapon skill's own
set, `Idle` under `Idle_Refresh`...), so the file works as it is.

**Your own version of the same item**

A piece you lack is swapped for the version of *the same item* you do
own, the highest you have: `Leth. Chappel +2` for `+3`, plain `Chirich Ring` for `Chirich Ring +1` (also for the
second ring of a pair). Each swapped line says what the example named:

```lua
        Head = 'Leth. Chappel +2', -- example: Leth. Chappel +3
        Ring2 = 'Chirich Ring', -- example: Chirich Ring +1
```

Only the `+N` at the end of the name may differ. It never reaches for a different item.

**Weapon modes**

A `/wm` mode whose `Weapon_<mode>` set lost its weapon (its `Main`, or every slot of a set without one) puts nothing
on until you fill that set. It **stays** in `gcinclude.WeaponModes` (and `DefaultWeapons` is left as it is): the
top of the file names it, and the editor's `To fill` tab lists it.

**The top of the file** is a summary:

- how many set slots were kept and how many left out
- every item left out, with the number of slots it filled — your shopping list
- every item to move to a wardrobe
- weapon modes with no weapon you own (kept)
- item names *outside* the sets that you don't own: `gFunc.Equip('Sub', '...')` in the handlers and the slot-pick
  lists (`gcinclude.MainModes` `SubModes` `RangeModes` `AmmoModes`, `WeaponItemMap`). These are listed, not changed:
  fix them by hand.

**It never picks a different item** (only another `+N` of the same one), leaves `OnLoad` and the handlers as the
example has them, and doesn't check job or level (the examples are level 99 sets).

**`/checksets`** runs the same bag check on your loaded job file and changes nothing. It reports:

- misspelled items, empty sets, and an earring or ring in the wrong slot;
- slots naming items you don't own, one copy worn twice, augments no copy has, and items only in bags you can't
  equip from (with the worst sets named);
- weapon modes with no weapon you own.
