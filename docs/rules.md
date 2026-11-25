# Rules: when this, wear that

[Back to README](../README.md)

A rule wears a set (or single items) when its conditions hold: Fealty while Cover is up, a body piece under 40% MP
on nukes, Self_Cure when a cure lands on you. Rules are data in the job file (`gcinclude.Rules`), made and changed in
`/gcedit`: **Rules** in the top bar (or the blue **RULES** button over the set list) opens them; it also says how many
of your job file's `if`s Convert can turn into rules (**Rules  +5 to convert**). No code, no text editor.

## In the editor

- **Left**: what to show: **All rules** or one moment's (Casting, Not acting...), and **Your code**: **Can become
  rules** (Convert) and **Stays code** (each `if` that stays, with why).
- **Each rule is a card**: what it does as a sentence (`When you cast Absorb-TP: put on Absorb_TP`), its tags
  (moment, **over everything**, **code spot 1**), and **Edit**, **Up** / **Down** (a later rule wins the slots both
  wear), **Off** (kept, not used), **Delete**.
- **+ New rule** opens the builder over the cards, in three steps:
  1. **When**: not acting (idle, fighting, resting), your pet's move, starting a spell, casting, a job ability, a
     weapon skill, starting a shot, a ranged shot, using an item.
  2. **If**: conditions from a menu (below), **all of these** or **any of these**. Skills, elements, targets and
     modes offer their values; several values, separated by commas, mean any of them.
  3. **Wear**: a set by name, ticked **with its weapon and /mset versions** (as a set worn by name:
     `Savage Blade`, then `Savage Blade_Naegling`, `Savage Blade_Acc`) or not (that set only); **+ one item** puts
     one piece in one slot.
  - The green box reads the rule back as a sentence. **More** holds the rest:
    - **Layer**: **Job layer** (the default: where a job file's own code goes, GoomSwap's layers on top) or **Over
      everything** (over weapons, TH, Hoxne, buff sets, obi, SIR; still under `/lock`, the TP and Aftermath holds,
      Incapacitated, Sleeping and Doomed, SmartSwap's weapon keep and Dispelga's Daybreak).
    - **Cancel it instead**: starting a spell, a job ability, a weapon skill, an item, starting a shot only
      (LuAshitacast's `CancelAction`).
    - **Note**: for yourself.
  - **Now**: whether a not-acting rule's conditions hold right now.
- **Save** (or **Save + reload**) writes them, one rule a line; the review lists each in words.

## Conditions

| Condition | Takes | Reads (LuAshitacast `gData`) |
|---|---|---|
| Your status | Idle, Engaged, Resting | `GetPlayer().Status` |
| Your HP % / MP % / TP | a number: <, <=, >, >=, =, not | `HPP` `MPP` `TP` |
| Moving, In combat | yes / no | `IsMoving`; GoomSwap's combat window |
| Sub job, Your level (synced) | WAR... / a number | `SubJob` `MainJobSync` |
| Action name | is, is not, has, starts with, ends with | `GetAction().Name` (Pet phase: the pet's action) |
| Spell family | Cure for Cure IV | GoomSwap's `Family` |
| Spell skill, Spell element, Action type | the game's names; element also `weather` / `day` (it matches today's) | `Skill` `Element` `Type` |
| Target | me, other, PC, NPC, Party, Alliance, Monster | `GetActionTarget()` |
| Target's HP %, Target distance | a number | `HPP` `Distance` |
| Day element, Weather element, Zone, Vana'diel time | names / a number (12.30 = 12:30) | `GetEnvironment()` |
| Buff up (any of), Buffs up (all of), Buff not up (none of) | buff names or ids | GoomSwap's buff count |
| You have a pet; pet's HP %, TP, name, status | | `GetPet()` |
| Mode | `/wm` `/mset` `/nukeset` `/idleset` `/wsset` `/tankset` `/weapon` `/pupmode` `/hoxne` `/mw` `/sw` `/rw` `/ammoset` and its value | `gcdisplay.GetCycle` |
| Toggle | `/dt` `/mdt` `/kite` `/th` `/sir` `/proc` `/burst` `/aminon` `/death` `/songlock` `/forcestring`, on / off | `gcdisplay.GetToggle` |
| Magic burst, Can dual wield | yes / no | GoomSwap's `BurstWanted`, `CanDualWield` |

Text matches as the game writes it: **has**, **starts with** and **ends with** count upper and lower case
(`helix` finds Pyrohelix II, not Helix). A value that isn't there (no target, no pet) fails a condition and passes
its **not**.

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

`on`: the phase (`Default`, `Pet`, `Precast`, `Midcast`, `Ability`, `Weaponskill`, `Preshot`, `Midshot`, `Item`).
`when`: every key must hold; `any = { {...}, {...} }` holds when one does. `first`: only the first choice whose
conditions hold. `exact = true`: that set only. `item = { Head = 'Pixie Hairpin +1' }`. `layer = 'top'`: over
everything. `off = true`: kept, not used. A rule the engine can't use is left out on load, with one line in chat.
`/gcperf` times them.

## Convert: your code into rules

**Your code** on the Rules page lists every `if` in your job file's handlers: **Can become rules** shows each with
the rules it becomes, **Stays code** each that stays and why. **Convert N into rules** stages them for Save (a
backup first; **Undo convert** takes it back):

- Conditions on the values above, joined by `and` / `or` / `not`; locals read from `gData` or `gcinclude.BuffCount`
  (sums of buff counts too); `T{...}:contains(...)`; plain-text searches (`string.contains`, `string.find(..., 1,
  true)`, `:contains`).
- Branches that only wear sets (`gFunc.EquipSet(sets.X)`, `ByName('X')`), items (`gFunc.Equip`) or cancel.
  `elseif` chains become **first of** groups, or plain rules when their branches can't overlap (a chain on the spell's
  skill); nested `if`s join their parent's conditions.
- Order is kept. The last run of `if`s in a handler goes where rules go by themselves (`HandleDefault`: at
  `gcinclude.CheckDefault()`); any other run leaves one line where it was, `gcinclude.RulesAt('Midcast 1')`, and its
  rules go on right there (the page marks them **code spot 1**; hover it for what that means).
- Stays code: names built in code (`'Tank_' .. tank`), engine calls (`CheckBlockedAmmo`), pet action branches, math
  on counts, two `has` that must both hold. `gData.GetBuffCount` becomes GoomSwap's buff check, which also counts a
  buff that just landed.

`tests/convert_sim.lua` checks Convert on every example: the original handlers and the converted ones wear the same
gear, slot by slot, over thousands of random game states.

## Adopt: a plain LuAshitacast file

Open it from the file name menu: the Rules page offers **Adopt**. GoomSwap then loads at the top of the file, starts
in `OnLoad`, stops in `OnUnload`, takes its commands in `HandleCommand` and adds its layers at the end of
`HandleDefault`; your code and set names stay (GoomSwap's own sets, `Dt`, `TH`, `Idle_Regen`..., work once you make
them). Its `if`s convert in the same Save.
