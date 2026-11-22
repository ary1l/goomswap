# Set editor: `/gcedit`

[Back to README](../README.md)

Edits your loaded job file. Changes stay in memory until you confirm a save. `/gcedit Savage Blade` opens a set.

## Add a set or mode

1. **+ New set**, type a name, **Create**. Names the engine looks for that your file lacks are suggested as you
   type (your spells, abilities and weapon skills too), and the box says what would wear a set by that name
   (`Absorb-TP`: *Worn: when Absorb-TP goes off (midcast).*). Tick *Copy slots from ...* to start from the open set.
2. Click a slot and pick gear from **Gear** (or **Use worn** for everything you have on).
3. **Save + reload**, check the review, confirm.

| To add | Do |
|---|---|
| A set for an action | Name it after the action: `Barrage`, `Cure`, `Savage Blade` |
| A weapon mode (`/wm`) | Name it `Weapon_<Name>` with Main/Sub; Save adds it to `gcinclude.WeaponModes`. Deleting the set takes it out on Save, with the sets worn only with that mode (`Tp_<Name>`, `Ws_<Name>_Acc`, `Savage Blade_<Name>`, `Weapon_<Name>_1h`...; untick to keep them; ones your code names are kept); a `DefaultWeapons` / `WeaponRoles` still naming it is flagged (change it in **Settings**). `Weapon_<Name>_1h` is used when you can't dual wield, `Weapon_<Name>Acc` (or `Weapon_<Name>_Acc`) with `/mset acc`. **Weapon sets...** (the set's header or right-click; offered when you make one) lists every set the mode can have: its `_1h` and `/mset` weapon sets (made as copies of `Weapon_<Name>`, spelled like your file's) and the layers below; tick the missing ones and **Make**. After **Save + reload** the mode is on the bar and HUD (the weapon pill and its right-click menu), coloured by its Main |
| TP or WS gear for one weapon | `Tp_<Name>` / `Ws_<Name>` (`Tp_Chango`): worn over `Tp_Default` / `Ws_Default` while `/wm <Name>` is on; `Tp_Chango_Acc` with `/mset acc` too. **Weapon sets...** on the `Weapon_<Name>` set makes the ones you tick, empty: fill only what differs, and later changes to the base still apply (or tick **Layers start as a copy of their base**). Right-click `Tp_Default` (or `Tp_Acc`, `Dt`, `Idle`, a WS's set): **Copy as a weapon set** makes one full copy |
| TP or WS gear for a weapon type | `Tp_2h` / `Tp_1h` (and `Ws_`, `Dt_`, `Idle_`...): for a weapon with no set of its own, by its Main ([How sets stack](sets.md#how-sets-stack)) |
| A Main/Sub/Range pick (`/mw` `/sw` `/rw`) | Nothing: every item in a `Weapon_` set is one. Others go in `gcinclude.SubModes` (etc.) in the file |
| A COR/RNG gun | Add its name to `gcinclude.RangeModes` in the file |
| A melee mode (`/mset`) | **+ /mset mode** on the **MELEE** heading (also on the **Related** tab): name it, tick the sets to make for it (`Tp_<mode>` and `Ws_<mode>` start ticked; `Dt_<mode>` and each weapon skill's `Savage Blade_<mode>` offered), **Add**. They start empty: fill only what differs. **Save + reload** adds it to `gcinclude.MeleeModes`; `/mset <mode>` then wears each over its base |
| A set for one buff | Open `Buffs` (idle/engaged), `Buffs_Ws` or `Buffs_Midcast`, type the buff's name as the game shows it, **New buff set**. Each shows under its parent (`Buffs['Aftermath: Lv.3']`) and edits, deletes and copies to other jobs like any set. Renaming one also renames code that takes it from its parent (`sets.Buffs['Haste']`, `sets.Buffs.Haste`) |

## Headings

The set list is grouped under headings (Idle, Defense, Melee, Weapons...). Arrange them your way:

- **Right-click a heading:** Move up / Move down, **New heading below** (type its name first), and for a heading
  of your own **Rename** and **Remove this heading** (its sets go back where their names put them).
  **Built-in order** undoes all of it.
- **Right-click a set:** **Move to heading** (a submenu) puts that set under any heading; **Back to where its name
  puts it**, at the end of that submenu, undoes the move. **Move up / Move down** reorders it inside its heading.
- **Drag a set** onto a heading to move it there, or onto another set to put it just before that one.
- **Buff sets** (`Buffs['Haste']`) sit under their parent in file order. Drag one or use **Move to heading** to put
  it elsewhere (shown by its full name there); **Back under Buffs** returns it.
- **Hide** (heading menu): **Hide on <JOB>** or **Hide on every job**. **Show hidden** (beside the filters) shows
  them again, marked hidden; a search always shows them. **Show again** undoes it.
- **Sets in it** (heading menu): **File order**, **A-Z**, or **Your order** (what Move up / down and dragging make).
- Folded headings stay folded after a game restart (`gcedit-folds.txt` beside `char.lua`).
- **Share with every character** (heading menu): these headings go into the shared settings file, and every
  character without headings of its own uses them. **Only this character** copies them back into `char.lua`.

Saved at once in the character's `char.lua` (`settings.EditorGroups`, `EditorHidden`, `EditorSort`, `EditorOrder`),
or in the shared file once shared ([Settings](settings.md#every-character-goomswap-sharedlua)), so every job shows the
same headings in the same order; the file is backed up first (once each time the editor opens). You can also
write it by hand:

```lua
EditorGroups = {
    { 'Weapons', 'Weapon_*' },  -- a heading and the set names it takes ('*': any text, any case)
    'Idle', 'Defense', 'Melee', 'Weapon skills', 'Job abilities', 'Casting', 'Named weapon skills', 'Hoxne',
    { 'Two-handed', 'Tp_Chango', 'Ws_Chango' }, -- your own heading: these exact sets
},
```

Listed headings come first, in that order; built-in ones you leave out follow, Other last. A set named exactly
under a heading goes there first, then the first heading whose `*` pattern takes it, else its built-in heading.

```lua
EditorHidden = { all = { 'Received' }, WAR = { 'Hoxne' } }, -- hidden on every job / on WAR
EditorSort = { Melee = 'own', Casting = 'az' },             -- 'file' (the default), 'az', 'own'
EditorOrder = { Melee = { 'Tp_Default', 'Tp_Chango' } },    -- 'own': these first, the rest in file order
```

## Across job files

- **Copy to other jobs** (right-click a set): its pieces into the job files you tick (new sets ticked; a file that
  has the set already replaces only the slots this set fills). A piece that job can't wear (by the item's job
  list, or above that job's level) is left out and listed; slots this set leaves empty keep that file's own.
  Each file is backed up and written only if it still loads. A job you have loaded needs `/lac reload` after.
- **Find in every job file** (right-click a slot): every set that names the item, in this file (as edited) and
  the others (as saved). Click one to open it there.
- **/wm order** (right-click a `Weapon_` set): **Earlier / Later in /wm** reorders the cycle; written on Save.
- **Unused** (filter): sets nothing seems to look for: no trigger by their name, not one of the engine's names,
  not a variant of another set, never named in the job file. **Delete these** stages them for Save. It is
  cautious, but check: a set your own code builds a name for can still look unused.

## Settings

**Settings** (top bar) lists every GoomSwap setting, its value now and where it comes from: **default**, **every
character** (the shared file), **this character** (`char.lua`) or **this job** (the job file open in the editor).
Pick **Save to**, change a value, **Save**; **Clear** takes it out of that file. `char.lua` and the shared file are
written at once; **This job** changes wait for the editor's Save, like set edits, as `gcinclude.settings.X = value;`
lines (a new one goes just before `gcinclude.Initialize()`). Below the settings, **Only in <job file>** edits that
file's own options the same way: `DefaultWeapons`, `WeaponRoles`, `MainModes` `SubModes` `RangeModes`,
`WeaponItemMap`, `AlwaysDualWield`, `NukeModes`, `Packer`, `SIRSkip` `THSkip`, `CureObi`, `SafeAmmo`, `RangeAmmo`,
`CORmsg`, `LockstyleSet` (`WeaponModes` and `MeleeModes` are shown; Weapon_ sets and the headings' **+ /wm mode**,
**+ /mset mode** change them).
A value written as code, or set in more than one place in the file, is left for you to edit there. True/false are checkboxes, numbers and text are boxes, tables are Lua
(`{ 'Ninjutsu' }`). Hover a setting for what it does, an example typed the way its box takes it, and its value in
each file; an empty box shows the example greyed. Numbers keep to their range (HP/MP % 0-100, TP 0-3000).
Settings most never change (item names like `HoxneItem`, game data, timing windows) show with **Show all**, when a
file sets one, or in a search; job options only some jobs read (`NukeModes`, `CORmsg`) show on those jobs. A value the engine would refuse on load is refused here. `/lac reload` applies it everywhere;
a job file's own setting still wins. Details: [Settings](settings.md).

## Find your way

- A comment right after a set's `{` in the job file shows under its name as **Note** (`Foe = { -- Lullaby keeps
  your weapons`).
- **Used for** (over the slots) says when a set goes on: GoomSwap's own trigger for it, else where your job file's
  code wears it, read from the file (`moving, not engaged (HandleDefault, line 732)`); hover it for each place.
- **WEAPONS** and **MELEE** always show, with **+ /wm mode** / **+ /mset mode** at the heading's right end (WEAPONS:
  New set with `Weapon_` typed, the box says what the name will be; MELEE: the new `/mset` mode and its sets). Each
  set there says, at its right end, what wears it: `/mset acc` (`Tp_Acc`), `/wm naegling`, `no dual wield`
  (`Weapon_Naegling_1h`), cut with `...` when the panel is narrow; hover it for the sentence. A `/mset` mode with no `Tp_<mode>` set shows greyed
  (`Tp_Hybrid no set`) with **make**. With no `Weapon_` set WEAPONS lists the file's picks
  (`Main picks (/mw): ...`, from `MainModes` `SubModes` `RangeModes`). A `DefaultWeapons` or
  `WeaponRoles` naming a weapon or mode nothing offers is flagged there and in **Settings**: the engine skips it at
  load without a word.
- Hover a set's name (the list, **Related**): its gear as icons, 4x4 in the equipment screen's order (a slot it
  leaves out is blank; rows after its last item are left out, so a weapon set is one row), over the usual hover
  text.
- Search the set list by a set's name or an item (`nyame`: every set wearing a Nyame piece, as edited), or fold its
  headings; for your main sets at the top, make a heading of your own and move them into it
  ([Headings](#headings)). **Unsaved sets**, **Issues**, **Missing**, **Needs RP** and **Unused** filter it; the `?`
  after the filters shows the colours as your theme draws them.
- Set colours (GoomSwap's own; a theme recolours them but keeps them apart): amber unsaved, red missing gear,
  violet unfinished RP, then green (all 16 slots, or a ready overlay) and teal (all 12 armor slots; weapons left
  out on purpose).
- Drag dividers to resize (double-click resets). Density is remembered per job.
- **Theme** (top bar): the editor's colours. Same as the bar (default), **Match goomui** (the theme goomui saved for
  this character), GoomSwap's own, or any of the 30 presets; hover one to preview. Kept per character
  (`gcedit-theme.txt`); the bar keeps its own.
- **Rescan bags** refreshes ownership and keeps edits. Storage Slip gear counts as owned and shows its slip.
- **Unused gear** lists, by bag, the gear in your Inventory and Wardrobes that nothing of this character names:
  none of its job files, char.lua, the shared settings file, GoomSwap's own sets or its code (Moonshade, obis,
  Warp Ring). A name anywhere as a string counts, code and unsaved edits too. Read only: it moves nothing.
- The **filename** opens the character's other job files. They are edited without changing your active job and
  saved with **Save file** (no reload). Switching with unsaved work asks to keep editing or discard.

## Gear grid and picker

| On a card | Means |
|---|---|
| Blue outline | The slot being edited |
| Amber fill, Unsaved | A pending change |
| Violet rank | Unfinished RP |
| Green / amber bag marker | Equippable bag / move it to Inventory or a wardrobe |
| Missing | No copy owned |
| Not in this set | A commented-out placeholder |
| Unchanged / Replaced: source | The set leaves the slot alone / a later layer of the selected Result wins |

- Click a slot, then pick an item from **Gear**; the header shows **Pending** vs **Saved** (paths, augments).
- **Put in other sets...** (over the picker, or right-click a slot card): that piece, exactly as it is (path,
  augments), into the same slot of the sets you tick: grouped by heading, each showing what it has now (sets that
  already have it, write that slot as code, or wear your only copy of that earring or ring in the other ear or ring
  slot, can't be ticked); **All in <heading>** ticks the open set's heading
  (an enmity piece in every job ability). Each is an unsaved edit: **Undo slot** per set, **Undo edit** one at a
  time; Save writes them.
- Changed a piece (Chev. Armet +2 -> +3) that other sets still have? Under the grid: *+2 is still in 6 other sets*,
  **Replace in all 6**, **Pick...** (tick which) or **Not now** (until the editor closes). An earring or ring is
  found in either slot of the pair (not where the set already wears your only copy of the new one). Each is an
  unsaved edit: **Undo edit** steps back; Save writes them.
- Search matches words anywhere in the name or decoded stats (`nyame damage`); 3+ letters also lists items you don't
  own, after yours, marked not owned, to plan a set (every item is looked through once, a moment the first time).
  Combine **Any job / level**, **Can equip now**, **Needs RP** and **Augmented**. Identical copies share a row; hover
  for their bags. Drag a row onto a card to stage it.
- Right-click a card or row: inspect, choose, **Set displaced rule** (`Slot = 'displaced'`: another item empties
  the slot, e.g. an instrument displacing ammo), undo, or **Clear slot** (earlier gear stays).

## Summary, Inspect, Compare

- **Summary** totals the set's listed gear bonuses including inherited layers (`Idle > Tp_Default > Tp_Acc`);
  untick **Include inherited gear** for the written definition only. **Base: Auto** uses the built-in route; pick a
  base set to change the underlay. Buffs, caps, job code and combat formulas are not simulated; conditional and
  unknown effects sit under **Other effects / not totaled**.
- Hover any item for its stats; elemental resistances show as the element's coloured dot and value, as the game's
  icons do (also in Summary, and as a dot row on the card: one value when they all match, a ring for a penalty). **Inspect item below grid** pins it while you pick. Commented, inherited and
  Result items can be inspected without adding them.
- **Compare** shows both sets' stats and the difference (green/red by direction), or **Gear changes** slot by
  slot. **Copy definition...** (confirmed) copies the other set's written slots. Hover any count for details.

## Sets, Result, Related, To fill

- **More**: Revert set, Discard new set, Rename set, Delete set (undoable until Save).
- **Rename set** is written on Save (a new set is renamed at once): the key and every place your code names it
  (`sets.X`, `ByName('X')`, `EquipSet('X')`; a `Weapon_` set's mode in WeaponModes/DefaultWeapons/WeaponRoles),
  optionally with its variants (`X_Acc`). Comments stay. A set found by its own name (`Idle`, an action) is then
  only worn where your code names it; the dialog warns.
- **Undo edit** steps back through slot changes; **Undo slot** restores the saved definition.
- **Result** shows what an action wore, layer by layer: recorded since load, or expected from your sets and modes.
- **Related** lists the sets you have that go on with this one, in the order they go on (a later one wins its
  slots): number, set (click to open), when it goes on (`(on now)`: its modes are on in game). The ones your file
  doesn't have are one line under them (*+ 26 you could make*); that line or **Not made too** lists them in their
  place with **make** (**Make all** on top). A long name or condition is cut with `...`; hover it for all of it,
  what it goes over, the job file line that wears it, and for one not made what goes on instead (its base set,
  GoomSwap's own `Doomed`, ...).
- **To fill** lists placeholders, missing or unusable items and empty weapon modes; **Fill all** stages one choice
  for every listed use. When nothing is left, it says **Nothing left to fill.**

## Save

**Save + reload** shows a review (before/after per set, new, deleted and renamed sets, weapon and melee modes);
cancelling writes nothing. Saving checks the file didn't change on disk and still parses, writes a dated backup,
then reloads (reopening the editor if ticked). Code-defined sets need a text editor; everything outside the gear
definitions is kept as written. The newest ten editor backups per file are kept (`EditorBackupKeep` in
char.lua's `settings`, `0` keeps all). Widths and density live in the job's `.gcedit-ui` file.
