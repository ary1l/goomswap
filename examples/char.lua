-- Optional, one per character: copy into the character's folder as char.lua (Ashita luashitacast/<Name>_<id>/char.lua,
-- Windower data/goomswap/<Name>/char.lua). Every job of that character uses it; a job file can still change it after:
-- gcinclude.AutoFood = {...} (that job's food), gcinclude.Packer = { ['Trump Card'] = 99 } (adds), gcinclude.settings.X (wins).
return {
    AutoFood = {'Grape Daifuku +1', 'Grape Daifuku'}, -- /autofood eats these, in order
    Packer = { -- kept in inventory on every job change and /packer (Bellhop plugin): item = count or 'stack'
        ['Echo Drops'] = 'stack',
        ['Remedy'] = 'stack',
        ['Panacea'] = 'stack',
        ['Holy Water'] = 'stack',
    },
    settings = { -- any gcinclude setting, this character only
        HUDOwners = T{'YourMain'}, -- the box that shows every box's HUD row; the others show only their own
    },
};
