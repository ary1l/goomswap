# Settings

[← Back to the README](../README.md)

Edit two blocks at the top of `common/gcinclude.lua` (the rest is engine). A newer `common/` overwrites them: keep
yours in `char.lua` (per character, survives updates) or the job file.

- **`gcinclude.sets`**, every job: `Doomed`, `Sleeping` (a job's own wins), `Holy_Water` (on using one), `Reraise`
  (Weakened), `Crafting` `Zeni` `Fishing` (`/craftset` `/zeniset` `/fishset`).
- **`gcinclude.settings`**, one commented option per line.

| Where | Example |
|---|---|
| Every job | `RefreshGearMPP = 50;` in `common/gcinclude.lua` |
| One character | `char.lua`: `return { settings = { Messages = true, HUDOwners = T{'YourMain'} } };` |
| One job | `OnLoad`, before `gcinclude.Initialize()`: `gcinclude.settings.RefreshGearMPP = 50;` |
| One job, add to a list | top of the job file: `gcinclude.SIRSkip = T{'Phalanx'};` |
| One job, replace | `gcinclude.Food`, `gcinclude.LockstyleSet`, `gcinclude.ElementGear`, `gcinclude.CureObi` |

Most changed:

| Setting | Default | Does |
|---|---|---|
| `Messages` | `false` | chat line on every mode change (`/gcmessages`) |
| `HUDOwners` | `T{}` | boxes whose bar drops the others in (the HUD) |
| `Keybinds` | F-key layout | your keys ([Keys](commands.md#keys)); `T{}` none |
| `LockstyleSet` | `nil` | lockstyle set put on after load/job change |
| `RegenGearHPP` `RefreshGearMPP` `DTGearHPP` | 60 60 50 | auto `Idle_Regen` / `Idle_Refresh` / `Dt` below this %; 0 never |
| `WeaponTPGuard` | 1000 | TP at which Main/Sub/Range stay on; 0 never hold |
| `IdleWeapons` | `true` | idle sets' weapons beat the mode out of combat |
| `Food` | Grape Daifuku +1 | food `/packer` keeps a stack of |
| `MoonshadeTP` | 1750 | Moonshade below this TP; 0 never |
| `Validate` `ValidateMP` | `true` | cancel actions that would fail |
| `DisplayBar` | `false` | status bar on load |

`RefreshGearMPP` is 0 in the WAR MNK THF SAM DRG DNC COR RNG NIN BST PUP BRD examples; `/autogear refresh 60` turns
it on.

More, by area:

| Area | Settings |
|---|---|
| Weapons | `AftermathHold` `HoldExemptSkills` `HoldExemptAbilities` `SmartSwap` `SmartSwapTP` `NoWeaponSpells` `KeepWeaponsFor` |
| Casting | `SIRSkip` `THSkip` `ElementGear` `ElementSkills` `OrpheusPoints` `MBWindow` `MBSkills` |
| Idle | `AutoGear` `PetDTGearHPP` |
| Weapon skills | `WScheck` `WSdistance` `MoonshadeSlot` `MoonshadeSkip` `ElementalWS` |
| Items | `PackerItems` `EnchantDelays` `EnchantWindow` `AmmoWarn` `NinjaToolWarn` |
| Hoxne | `HoxneItem` `HoxneLockSlots` `HoxneAutoUse` |
| Received sets | `ReceivedSets` `ReceivedWindow` `MyBoxes` |
| Bar and HUD | `DisplayBar` `DisplayBarX` `DisplayBarY` `HUDOwners` `HUDHover` `HUDGrow` `HUDMessages` `HUDAlpha` `HUDAbbr` `WeaponClass` |
| Other | `WaltzTPCut` `Trace` `CombatWindow` `XIRollSet` `CapacityCapes` `JubileeSlot` `SleepCancelStoneskin` `ElementReport` `warp_Ring` `mea_Ring` `dem_Ring` `holla_Ring` |
