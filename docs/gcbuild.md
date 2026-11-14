# A job file from the gear you own: `/gcbuild`

[← Back to the README](../README.md)

`/gcbuild` takes the job's example file and keeps only the gear your character actually has, so you start from sets
that work instead of someone else's gear list. Ashita and Windower.

**Run it**

1. The examples must be installed: Ashita `luashitacast/examples/` ([Install](../README.md#install), step 1), Windower
   `data/goomswap/examples/`.
2. Log in on the character and type `/gcbuild` (your current job) or `/gcbuild RDM` (any job).
3. Open `<JOB>.proposed.lua` in the character's folder (Ashita `luashitacast/<Name>_<id>/`, Windower
   `data/goomswap/<Name>/`). The top of the file says what is missing and what to move.
4. Fill the commented-out slots. On Ashita `/gcbuild` also writes `gear_<JOB>.txt` next to it: everything you own
   that the job can wear, by slot.
5. Save it as `<JOB>.lua`, reload (`/lac reload`), then `/checksets`.

Your existing `<JOB>.lua` is **never changed**. Running `/gcbuild` again only replaces the `.proposed.lua` file.

**What it does to each line of each set**

It looks through every bag (Inventory, Wardrobes 1-8, Safe, Safe 2, Storage, Locker, Satchel, Sack, Case) and
compares by item name:

| Your character | The line in the proposed file |
|---|---|
| has the item, as the example names it | unchanged |
| has it, but with different augments | name only, your copies' augments in a comment — so it still equips |
| has it, but only in a bag gear can't be equipped from | unchanged, marked `move it to a wardrobe` |
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

A `/wm` mode whose `Weapon_<mode>` set lost its weapon (its `Main`, or every slot of a set without one) has nothing
to put on, so it is taken out of `gcinclude.WeaponModes`; if it was the `DefaultWeapons`, the first mode left
becomes the default. Both lines say what was changed.

**The top of the file** is a summary:

- how many set slots were kept and how many left out
- every item left out, with the number of slots it filled — your shopping list
- every item to move to a wardrobe
- weapon modes taken out
- item names *outside* the sets that you don't own: `gFunc.Equip('Sub', '...')` in the handlers and the slot-pick
  lists (`gcinclude.MainModes` `SubModes` `RangeModes` `AmmoModes`, `WeaponItemMap`). These are listed, not changed:
  fix them by hand.

**What it does not do**

- It **never picks a different item**. A slot you lack is left out unless you own another version of the same item
  (`+2` for `+3`). It won't guess that another piece of yours is "close enough". Fill those in yourself.
- Apart from the two weapon-mode lines, `OnLoad` and the handlers are the example's, untouched.
- It doesn't check job or level: the examples are level 99 sets.
- `/checksets` afterwards names anything misspelled or missing.

**Checking a job file you already use: `/checksets`**

`/checksets` runs the same bag check over the job file you have loaded, and changes nothing. After its usual lines
(misspelled items, empty sets, wrong ear or ring) it says how many set slots name:

- items you don't own (those lines do nothing)
- the same item in two slots of a set with one copy owned
- augments that no copy of yours has
- items that are only in a bag gear can't be equipped from

and names the worst of each with the sets they are in, plus weapon modes whose `Weapon_<mode>` set has no weapon
you own. Useful after selling or storing gear, or after copying a job file from someone else.

`/gcgear [JOB]` (Ashita) writes that `gear_<JOB>.txt` on its own, any time.
