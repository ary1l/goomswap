# Settings

[Back to README](../README.md)

Put personal preferences in the character's **char.lua**, outside `common/`.
Run `/gcconfig` to print its exact path and effective HUD/keybind settings.
`/gcconfig init` creates a commented template only when that file is missing;
`examples/char.lua` contains the same template.

It is `config/addons/luashitacast/<Name>_<Id>/char.lua`. Every job on that character uses
it. Reload the job after editing. A later job-specific override still wins.
`/gcedit` → **Settings** edits it for you ([Settings](gcedit.md#settings)).

For example:

```lua
return {
    settings = {
        HUDOwners = { 'YourMain' },
        Keybinds = {}, -- disable GoomSwap's default bindings
        RefreshGearMPP = 50,
    },
    Packer = { ['Grape Daifuku +1'] = 'stack' }, -- /lac gear on every job (Packer plugin)
    sets = {
        Doomed = { Ring1 = 'Purity Ring', Waist = 'Gishdubar Sash' },
    },
}
```

If the file exists, merge choices into its existing tables. Keep one return table
and one settings table. Packer and common fallback sets are siblings of
settings. A job's own gear table remains in that job file.

| Scope | Location |
|---|---|
| Every character | `goomswap-shared.lua`, inside `settings` ([below](#every-character-goomswap-sharedlua)) |
| Every job on one character | `char.lua`, inside `settings` |
| One job | `gcinclude.settings.X = value` before `gcinclude.Initialize()` (`/gcedit` → Settings → **This job**) |
| One job's packer/style | `profile.Packer` (LuAshitacast's list, `/lac gear`), `gcinclude.LockstyleSet` |

Keep character files and customized job files when applying shared-code updates.
Existing personal edits in shared code need a one-time move into char.lua; updates
do not automatically migrate them.

Most changed:

| Setting | Default | Does |
|---|---|---|
| `Messages` | `false` | chat line on every mode change (`/gcmessages`) |
| `EditorBackupKeep` | `10` | newest dated `/gcedit` backups retained per job file after successful saves; `0` keeps all |
| `EditorGroups` | none | `/gcedit` heading order and your own headings; the editor's right-click menus write it ([Headings](gcedit.md#headings)) |
| `EditorHidden` `EditorSort` `EditorOrder` | none | `/gcedit` headings hidden per job or on every job, how each heading sorts its sets, your own order ([Headings](gcedit.md#headings)) |
| `HUDOwners` | `T{}` | boxes whose bar drops the others in (the HUD) |
| `Keybinds` | F-key layout | your keys ([Keys](commands.md#keys)); `T{}` none |
| `LockstyleSet` | `nil` | lockstyle set put on after load/job change |
| `RegenGearHPP` `RefreshGearMPP` `DTGearHPP` | 60 60 50 | auto `Idle_Regen` / `Idle_Refresh` / `Dt` below this %; 0 never |
| `WeaponTPGuard` | 1000 | TP at which Main/Sub/Range stay on; 0 never hold |
| `IdleWeapons` | `true` | idle sets' weapons beat the mode out of combat |
| `MoonshadeTP` | 1750 | Moonshade below this TP; 0 never |
| `DisplayBar` | `false` | status bar on load |
| `EditorIgnoreSuggestions` | `T{}` | exact set names hidden in `/gcedit` → `Related`; e.g. `T{'Singing'}` |

`RefreshGearMPP` is 0 in the WAR MNK THF SAM DRG DNC COR RNG NIN BST PUP BRD examples; `/autogear refresh 60` turns
it on.

More, by area:

| Area | Settings |
|---|---|
| Set editor | `EditorBackupKeep` `EditorIgnoreSuggestions` `EditorGroups` `EditorHidden` `EditorSort` `EditorOrder` |
| Weapons | `AftermathHold` `HoldExempt` `SmartSwap` `SmartSwapTP` `KeepWeaponsFor` |
| Casting | `SIRSkip` `THSkip` `ElementGear` `ElementSkills` `OrpheusPoints` `MBWindow` `MBSkills` |
| Idle | `AutoGear` `PetDTGearHPP` |
| Weapon skills | `WScheck` `WSdistance` `MoonshadeSlot` `MoonshadeSkip` `ElementalWS` |
| Items | `EnchantDelays` `EnchantWindow` (Packer: beside `settings`, see above) |
| Hoxne | `HoxneItem` `HoxneLockSlots` `HoxneAutoUse` |
| Received sets | `ReceivedSets` `ReceivedWindow` `MyBoxes` |
| Bar and HUD | `DisplayBar` `DisplayBarX` `DisplayBarY` `HUDOwners` `HUDAbbr` `WeaponClass` `Theme` |
| Other | `CombatWindow` `XIRollSet` `CapacityCapes` `JubileeSlot` `SleepCancelStoneskin` `ElementReport` `warp_Ring` `mea_Ring` `dem_Ring` `holla_Ring` |

For example, to hide the Singing candidate on one character, put this in that character's `char.lua`:

```lua
return {
    settings = {
        EditorIgnoreSuggestions = T{'Singing'},
    },
}
```

Exact set names, any case; the editor's **Show ignored** checkbox reveals them for now.

## Every character: goomswap-shared.lua

`config/addons/luashitacast/goomswap-shared.lua` has the same layout as `char.lua` (`settings`, `Packer`,
`sets`) and applies to every character. The engine reads the defaults, then this file, then the character's
`char.lua`: a setting in `char.lua` wins, and a job file wins over both. A `Packer` in `char.lua` replaces the
shared one. `/gcconfig` prints both paths. `/gcedit` → **Settings** with **Applies to: Everyone** writes it
(and makes it the first time); heading **Share with every character** puts your headings there.

```lua
return {
    settings = {
        DTGearHPP = 40,
        EditorBackupKeep = 20,
    },
}
```

## LuAshitacast settings

The entries in `defaults/settings.lua` belong to LuAshitacast's `gSettings`, a
separate table from the GoomSwap preferences above. For example:

```lua
settings["AddSetEquipScreenOrder"] = true;
```

This is ordinary Lua, equivalent to `settings.AddSetEquipScreenOrder = true`.
It controls the slot order written by `/lac addset`: `true` follows the equipment
screen's rows; `false` follows internal slot IDs. It changes saved text formatting.

| Host setting | Purpose |
|---|---|
| `AddSetBackups` | Back up the profile when using addset |
| `EquipBags` | Containers searched for equipment, in priority order |
| `AllowSyncEquip` | Try gear up to your real level while level synced |
| `FastCast`, `Snapshot` | Inputs to estimated spell/ranged completion times |
| `AbilityDelay`, `PetskillDelay`, `WeaponskillDelay` | Completion timeouts if the action's completion packet is missed |
| `SpellOffset`, `RangedBase`, `RangedOffset`, `ItemBase`, `ItemOffset` | Spell/ranged/item timeout estimates |

See the [LuAshitacast gSettings reference](https://thornyffxi.github.io/LuAshitacast/gsettings.html).
Updates never replace your global settings file.
