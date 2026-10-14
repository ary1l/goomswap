-- GoomSwap for Windower (GearSwap entry file). Goes in Windower/addons/GearSwap/data/default.lua.
-- GearSwap loads it only for a job with no GearSwap file of its own (data/<Name>/<JOB>.lua, data/<Name>_<JOB>.lua,
-- data/<Name>.lua, data/<JOB>.lua all win over it). It then runs your LuAshitacast job file from
-- data/goomswap/<Name>/<JOB>.lua (or data/goomswap/<JOB>.lua for every character), common/ from data/goomswap/common/.
-- Loaded OK = "[GoomSwap] Loaded data/goomswap/.../<JOB>.lua" in chat. Install: README.md.
include('goomswap/core.lua');
