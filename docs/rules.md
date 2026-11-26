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
  (moment, **over everything**, where it goes on in your code: **before skill set**), and **Edit**, **Up** / **Down**, **Off** (kept, not used), **Delete**.
  Order only matters between rules that go on at the same moment and place (same moment, same code spot or layer):
  where two put gear in the same slot, the later one wins. **Up** / **Down** show only there, and move a rule past the
  next one that goes on at that place.
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
| A /wm weapon is picked | yes / no | GoomSwap's `IsWeaponValue(gcdisplay.GetCycle('Weapons'))`: the pick isn't None or Unknown |
| In GoomSwap's spell list | `BluMagPhysical`, `BluMagDebuff`, `BluMagStun`, `BluMagBuff`, `BluMagSkill`, `BluMagCure`, `BluMagEnmity`, `BluMagTH` (is / is not) | `gcinclude.<list>:contains(name)`, the engine's own lists |
| Has a set named after it, Has a set for its family | yes / no: a set in your job file named after the spell / ability / weapon skill (`Flash`), or its family (`Cure` for Cure IV), checked as it happens | GoomSwap's `FindSet` (what `ByName` looks for) |

Text matches as the game writes it: **has**, **starts with** and **ends with** count upper and lower case;
**matches (Lua pattern)** reads the text as `string.find` does (`Evryone. Grudge`: the `.` is any character)
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
backup first; **Undo convert** takes it back).

**Checked on your file.** Before Convert is offered, the editor runs your job file's handlers and the converted ones
side by side, over 400 random game states each (spells, buffs, modes, HP/MP, targets, weather...), and compares
what they wear, slot by slot (it takes a moment, a little each frame; the page says *Checking...*). A part of your
code whose result differs stays code, with what differed. Your sets are your file's own; GoomSwap's own steps
(`CheckDefault`, `CheckTH`...) are stand-ins, the same on both sides. If your file can't be run there, the page says
so and Convert works without the check. A part of your code that stops with an error there in most rounds (it calls
something the check can't stand in for) isn't counted as the same: it stays code, with that error.

What converts:

- Conditions on the values above, joined by `and` / `or` / `not`; locals read from `gData` or `gcinclude.BuffCount`
  (sums of buff counts too), or holding a condition (`local roll = string.find(ability.Name, 'Roll', 1, true) ~=
  nil`); `T{...}:contains(...)`; plain-text searches (`string.contains`, `string.find(..., 1, true)`, `:contains`).
- The zone read from Ashita (`AshitaCore:GetResourceManager():GetString('zones.names', ...GetMemberZone(0))`, the
  same read LuAshitacast's `Area` is) when the check searches part of its name; GoomSwap's spell lists
  (`gcinclude.BluMagPhysical:contains(spell.Name)`); a set picked by a check (`gFunc.EquipSet(c and sets.A or sets.B)`
  becomes two rules); a Lua pattern (`string.match(spell.Name, 'Evryone. Grudge')`), kept as a pattern.
- A check that looks a set up, `if not (ByName(spell.Name) or ByName(Family(spell.Name))) then
  gFunc.EquipSet(sets.Enmity) end`: the lookup stays code (`if not ByName(spell.Name) then ByName(Family(spell.Name))
  end`, it still puts that set on) and the rest becomes a rule, *When you cast a spell, while it has no set of its own
  (by name or family): put on Enmity*. A set you add later counts, as in the code.
- Branches that only wear sets (`gFunc.EquipSet(sets.X)`, `ByName('X')`), items (`gFunc.Equip`) or cancel.
  `elseif` chains become **first of** groups, or plain rules when their branches can't overlap (a chain on the spell's
  skill); nested `if`s join their parent's conditions.
- Order is kept. A run of `if`s goes where rules go by themselves (`HandleDefault`: at `gcinclude.CheckDefault()`,
  else after the handler) when nothing after it can put on the same slots and the check finds the same gear (it
  reads which slots each set has). Otherwise it leaves one line where it was, `gcinclude.RulesAt('Midcast 1')`, and
  its rules go on right there: their tag says what comes next in your code, **before skill set** (`ByName(spell.Skill)`),
  **before named set** (the set named after the spell), **after line 12** (a line that can stop the handler
  first). Your later code still wins those slots, as before. If that line is later taken out of the file by hand,
  its rules can't go on: GoomSwap says so in chat on load, and the Rules page tags them **not running** (Edit, More,
  **Use a layer instead**).
- **Stays code** says, for each, what the line does and why a rule can't do it (*Not gear: it prints the roll's
  lucky and unlucky numbers to chat. A rule only puts on gear or cancels the action.*); it keeps working as code.
  Stays code: names built in code (`'Tank_' .. tank`), engine calls (`CheckBlockedAmmo`), pet action branches, math
  on counts, two `has` that must both hold. `gData.GetBuffCount` becomes GoomSwap's buff check, which also counts a
  buff that just landed.

`tests/convert_sim.lua` runs the same check (`common/gcconvertcheck.lua`) on every example and on the examples as
they were before their Convert, again with other random states, and makes sure it catches a rule that wears the
wrong set.

## Adopt: a plain LuAshitacast file

Open it from the file name menu: the Rules page offers **Adopt**. GoomSwap then loads at the top of the file, starts
in `OnLoad`, stops in `OnUnload`, takes its commands in `HandleCommand` and adds its layers at the end of
`HandleDefault`; your code and set names stay (GoomSwap's own sets, `Dt`, `TH`, `Idle_Regen`..., work once you make
them). Its `if`s convert in the same Save.
