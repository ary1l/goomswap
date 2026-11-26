-- char.lua (singular): preferences shared by every job on this character.
-- Run /gcconfig to find the exact folder, or /gcconfig init to create this file.
-- Ashita: config/addons/luashitacast/<CharacterName>_<CharacterId>/char.lua
-- Keep this file outside common/ when updating. Reload the job after editing.
-- Settings for every character: goomswap-shared.lua (same layout); this file wins. /gcedit Settings edits both.
--
-- Existing char.lua? Merge your choices into its existing tables. Keep ONE
-- return table and ONE settings table; do not paste a second return at the end.
-- The examples below are commented out to preserve your current defaults.
-- Remove the leading -- from a setting you want to use, then edit its value.
return {
    settings = {
        -- Put HUD owners and keybinds HERE, inside settings.
        -- Use the same main's name in each box's char.lua.
        -- HUDOwners = { 'YourMain' }, -- replace YourMain with the actual name
        -- Keybinds = {},             -- disable all GoomSwap keybinds
        -- EditorBackupKeep = 3,      -- newest editor backups per job file; 0 = keep all
        -- EditorGroups = { 'Weapons', 'Idle' }, -- /gcedit heading order; its right-click menus write this

        -- For custom binds, use this INSTEAD of Keybinds = {} above.
        -- This list replaces the default bindings; it does not add to them.
        -- Keybinds = { { 'F7', 'wm' }, { 'F9', 'mset' } },
    },

    -- Optional supplies belong OUTSIDE settings, alongside it: /lac gear (Packer plugin) fetches them on every job.
    -- Uncomment the whole block you want (or use /gcedit Settings). A count, 'stack' or 'all'.
    -- Packer = {
    --     ['Echo Drops'] = 'stack',
    --     ['Holy Water'] = 'stack',
    -- },

    -- Optional common fallback sets (not your job's gear table).
    -- sets = {
    --     Doomed = { Ring1 = 'Purity Ring', Waist = 'Gishdubar Sash' },
    -- },
}
-- A later job-specific setting still wins over the same character setting.
