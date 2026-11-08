-- Optional, one per character: copy into the character's folder as char.lua (Ashita luashitacast/<Name>_<id>/char.lua,
-- Windower data/goomswap/<Name>/char.lua). Every job of that character uses it; a job file can still change it after:
-- gcinclude.Food = {...} (that job's food), gcinclude.Packer = { ['Trump Card'] = 99 } (adds), gcinclude.settings.X (wins).
return {
    Food = {'Grape Daifuku +1'}, -- /packer keeps a stack of each (every job of this character)
    Packer = { -- kept in inventory on every job change and /packer (Bellhop plugin): item = count or 'stack'
        ['Echo Drops'] = 'stack',
        ['Remedy'] = 'stack',
        ['Panacea'] = 'stack',
        ['Holy Water'] = 'stack',
    },
    settings = { -- any gcinclude setting, this character only
        HUDOwners = T{'YourMain'}, -- the box whose bar drops the other boxes in on hover (the HUD)
    },
};
