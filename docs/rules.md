# Rules: when this, wear that

[Back to README](../README.md)

A rule puts on a set (or single items) when its conditions hold: Fealty while Cover is up, a body piece under 40% MP
on nukes, Self_Cure when a cure lands on you. Rules live in the job file (`gcinclude.Rules`) and are made in
`/gcedit`: **Rules** in the top bar opens them. No code, no text editor.

**Most swaps need no rule.** A set with an action's exact name goes on by itself (`Savage Blade`, `Sentinel`, `Cure`,
or the spell's family), then its `/wm` and `/mset` versions (`Savage Blade_Naegling`, `Savage Blade_Acc`). Each
moment's base set does too (`Ws_Default`, `Precast`, `Midcast`, `Idle`, `Tp_Default`). Rules are the extras: *if
this, then that*.

## In the editor

- **Left:** **All rules** or one moment's (Casting, Not acting...). While your job file has `if`s, **Your code** lists
  the ones that **Can become rules** and the ones that **Stay code**, with why.
- **Each rule is a card:** what it does as a sentence (`When you cast Absorb-TP: put on Absorb_TP`), its tags, and
  **Edit**, **Up** / **Down**, **Off** (kept, not used), **Delete**.
- **Order** only matters when two rules put gear in the same slot at the same moment: the later one wins. **Up** /
  **Down** show only where that can happen.
- **+ New rule** opens the builder. (A set's **More...**, **Wear this when...**, opens it with that set.)
  1. **When:** not acting (idle, fighting, resting), your pet's move, starting a spell, casting, a job ability, a
     weapon skill, starting a shot, a ranged shot, using an item.
  2. **If:** conditions from a menu (below), **all of these** or **any of these**. Several values, separated by
     commas, mean any of them.
  3. **Wear:** a set by name, with or without its `/wm` and `/mset` versions, or **+ one item** for a single slot.
- The green box reads the rule back as a sentence. **More** holds:
  - **Layer:** **Job layer** (default: where a job file's own code goes, GoomSwap's layers on top) or **Over
    everything** (over weapons, TH, Hoxne, buff sets, obi, SIR; still under `/lock`, the TP and Aftermath holds,
    the Incapacitated, Sleeping and Doomed sets, SmartSwap's weapon keep and Dispelga's Daybreak).
  - **Cancel it instead:** stop the action. Only when it starts: a spell (precast), a job ability, a weapon skill,
    an item, a shot (preshot).
  - **Note:** for yourself.
- **Now** shows whether a not-acting rule holds right now. **Save** writes the rules, one a line.

## Conditions

| Condition | Takes | Reads (LuAshitacast `gData`) |
|---|---|---|
| Your status | Idle, Engaged, Resting | `GetPlayer().Status` |
| Your HP % / MP % / TP | a number: <, <=, >, >=, =, not | `HPP` `MPP` `TP` |
| Moving, In combat | yes / no | `IsMoving`; GoomSwap's combat window |
| Sub job, Your level (synced) | WAR... / a number | `SubJob` `MainJobSync` |
| Action name | is, is not, has, has all of, starts with, ends with | `GetAction().Name` (Pet phase: the pet's action) |
| Spell family | Cure for Cure IV | GoomSwap's `Family` |
| Spell skill, Spell element, Action type | the game's names; element also `weather` / `day` | `Skill` `Element` `Type` |
| Target | me, other, PC, NPC, Party, Alliance, Monster | `GetActionTarget()` |
| Target's HP %, Target distance | a number | `HPP` `Distance` |
| Day element, Weather element, Zone, Vana'diel time | names / a number (12.30 = 12:30) | `GetEnvironment()` |
| Buff up (any of), Buffs up (all of), Buff not up (none of) | buff names or ids | GoomSwap's buff count |
| You have a pet; pet's HP %, TP, name, status | | `GetPet()` |
| Mode | `/wm` `/mset` `/nukeset` `/idleset` `/wsset` `/tankset` `/weapon` `/pupmode` `/hoxne` `/mw` `/sw` `/rw` `/ammoset` and its value | `gcdisplay.GetCycle` |
| Toggle | `/dt` `/mdt` `/kite` `/th` `/sir` `/proc` `/burst` `/aminon` `/death` `/songlock` `/forcestring`, on / off | `gcdisplay.GetToggle` |
| Magic burst, Can dual wield | yes / no | GoomSwap's `BurstWanted`, `CanDualWield` |
| A /wm weapon is picked | yes / no (not None or Unknown) | GoomSwap's `IsWeaponValue` on `/wm` |
| In GoomSwap's spell list | `BluMagPhysical`, `BluMagDebuff`, `BluMagStun`, `BluMagBuff`, `BluMagSkill`, `BluMagCure`, `BluMagEnmity`, `BluMagTH` | `gcinclude.<list>:contains(name)` |
| Has a set named after it, Has a set for its family | yes / no (`Flash`; `Cure` for Cure IV) | GoomSwap's `FindSet` (what `ByName` looks for) |

- Text matches as the game writes it, upper and lower case.
- **has** is any of its texts; **has all of** needs every one (`helix, Nocto`).
- **matches (Lua pattern)** reads the text as `string.find` does (`Evryone. Grudge`: `.` is any character).
- A value that isn't there (no target, no pet) fails a condition and passes its **not**.

## In the file

```lua
gcinclude.Rules = {
    { on = 'Default', when = { buff = 'Cover' }, wear = 'Fealty', exact = true },
    { on = 'Midcast', when = { skill = 'Elemental Magic', mpp = { le = 40 } }, wear = 'Mp_Body', exact = true },
    { on = 'Midcast', when = { skill = 'Healing Magic', target = 'me' }, wear = 'Self_Cure' },
    { on = 'Midcast', when = { skill = 'Enhancing Magic' }, first = {
        { when = { name = { has = 'storm' } }, wear = 'Storm' },
        { wear = 'Enhancing' },
    } },
    { on = 'Precast', when = { name = 'Stun', mpp = { lt = 10 } }, stop = true, note = 'no MP' },
};
```

| Key | Means |
|---|---|
| `on` | The moment: `Default`, `Pet`, `Precast`, `Midcast`, `Ability`, `Weaponskill`, `Preshot`, `Midshot`, `Item` |
| `when` | Every key must hold. `any = { {...}, {...} }` holds when one does. |
| `first` | Only the first choice whose conditions hold |
| `wear`, `exact` | The set; `exact = true`: that set only, not its versions. A set inside a set: `wear = "Buffs['Boost']"` |
| `item` | One piece: `item = { Head = 'Pixie Hairpin +1' }` |
| `layer = 'top'` | Over everything |
| `stop = true` | Cancel the action |
| `off = true` | Kept, not used |

A rule the engine can't use is left out on load, with one line in chat. `/gcperf` times them.

## Convert: your code into rules

**Your code** on the Rules page lists every `if` in your job file's handlers. **Convert N into rules** stages the ones
that can become rules, for Save (a backup comes first; **Undo convert** takes it back).

**It is checked first.** The editor runs your handlers and the converted ones side by side over 400 random game states
(spells, buffs, modes, HP/MP, targets, weather...) and compares what they wear, slot by slot. Any part whose result
differs stays code, with what differed. If your file can't be run there, the page says so and Convert works without
the check.

**What converts:**

- Conditions on the values above, with `and` / `or` / `not`.
- Locals read from `gData` or `gcinclude.BuffCount`, or holding a condition
  (`local roll = string.find(ability.Name, 'Roll', 1, true) ~= nil`).
- Text searches (`string.contains`, `string.find(..., 1, true)`, `:contains`), `T{...}:contains(...)` and Lua patterns.
- The zone read from Ashita, when the check looks for part of its name.
- GoomSwap's spell lists (`gcinclude.BluMagPhysical:contains(spell.Name)`).
- A set picked by a check: `gFunc.EquipSet(c and sets.A or sets.B)` becomes two rules.
- Your file's own no-argument function that only sets locals and returns a check:
  `local function Night() local t = gData.GetEnvironment().Time; return (t >= 17) or (t < 7); end` becomes
  *Vana'diel time 17:00 or later, or before 7:00*.
- `gcinclude.IsWeaponValue(gcdisplay.GetCycle('Weapons'))`: *A /wm weapon is picked*.
- A set inside a set, `gFunc.EquipSet(sets.Buffs.Boost)`: the rule wears `Buffs['Boost']`, the same set.
- A name checked inside another (`helix`, then `Nocto`): **has all of**.
- `if not (ByName(spell.Name) or ByName(Family(spell.Name))) then gFunc.EquipSet(sets.Enmity) end`: the lookup stays
  code, and the rest becomes *When you cast a spell, while it has no set of its own: put on Enmity*.
- Branches that only wear sets, items, or cancel. `elseif` chains become **first of** groups; nested `if`s join their
  parent's conditions.

**Order is kept.** Converted rules go where rules go by themselves (`HandleDefault`: at `gcinclude.CheckDefault()`)
when nothing later in the handler touches the same slots. Otherwise Convert leaves one line in your code,
`gcinclude.RulesAt('Midcast 1')`, and the rules go on right there. Their tag says where: **before skill set**,
**before named set**, **after line 12**. If that line is later removed by hand, GoomSwap says so in chat, and the
Rules page tags those rules **not running** (with **Use a layer instead**).

**What stays code,** each with why: set names built while running (`'Tank_' .. tank`), engine calls that do more
than wear gear (`CheckTH`, roll messages), pet action branches, math on counts. It keeps working as before.

**A buff count compared with exactly 1** (`if (sa == 1) and (ta == 1)`) stays code: a rule only knows *up* (count
above 0). If those buffs never show twice, press **Count 1 as up** on that line and it converts (**Undo** puts it
back). That's your call: Convert can't know which buffs stack.

## Adopt: a plain LuAshitacast file

Open it from the file name menu: the Rules page offers **Adopt**. GoomSwap then loads at the top of the file, starts
in `OnLoad`, stops in `OnUnload`, takes its commands in `HandleCommand` and adds its layers at the end of
`HandleDefault`. Your code and set names stay; GoomSwap's own sets (`Dt`, `TH`, `Idle_Regen`...) work once you make
them. Its `if`s convert in the same Save.
