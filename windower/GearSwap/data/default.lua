-- ShaySwap for Windower (GearSwap entry file). Goes in Windower/addons/GearSwap/data/default.lua.
-- GearSwap loads it only for a job with no GearSwap file of its own (data/<Name>/<JOB>.lua, data/<Name>_<JOB>.lua,
-- data/<Name>.lua, data/<JOB>.lua all win over it). It then runs your LuAshitacast job file from
-- data/shayswap/<Name>/<JOB>.lua (or data/shayswap/<JOB>.lua for every character), common/ from data/shayswap/common/.
-- Loaded OK = "[ShaySwap] Loaded data/shayswap/.../<JOB>.lua" in chat. Install: README.md.
include('shayswap/core.lua');
