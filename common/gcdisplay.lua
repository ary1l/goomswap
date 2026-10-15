local gcdisplay = {};

local imgui = require('imgui');
local cfg = nil;
local barPlaced = false;
local barSavedX, barSavedY = nil, nil;

local Toggles = {};
local DefToggles = {};
local DefCycles = {};
local Cycles = {};
local Def = 0;
local Attk = 0;
local MainLV = 0;
local SubLV = 0;
local Main = 'FOO';
local Sub = 'BAR';
local headText = '';
local toggleKeys, cycleKeys = nil, nil; -- sorted names for the bar, rebuilt when a toggle or cycle is added

function gcdisplay.AdvanceCycle(name)
	local ctable = Cycles[name];
	if (type(ctable) ~= 'table') then
		return;
	end

	ctable.Index = ctable.Index + 1;
	if (ctable.Index > #ctable.Array) then
		ctable.Index = 1;
	end
end

function gcdisplay.SetCycle(name,val)
	local ctable = Cycles[name];
	if (type(ctable) ~= 'table') then
		return;
	end

	for k,v in pairs(ctable.Array) do
		if val == v then
			ctable.Index = k
			return true
		end
	end
	return false
end

function gcdisplay.AdvanceToggle(name)
	if (type(Toggles[name]) == 'boolean') then Toggles[name] = not Toggles[name] end
end

function gcdisplay.SetToggle(name, val)
	if (type(Toggles[name]) ~= 'boolean') then return end
	Toggles[name] = (val == true);
end

-- Only the bar shows these, so nothing is read while it is off (BarCommand reads them when it goes on).
function gcdisplay.Update()
    if (cfg == nil) or (cfg.DisplayBar ~= true) then return end
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    if (player == nil) then return; end

    local MID = player:GetMainJob();
    local SID = player:GetSubJob();
    Def = player:GetDefense();
    Attk = player:GetAttack();
    MainLV = player:GetMainJobLevel();
    SubLV = player:GetSubJobLevel();
    Main = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", MID) or 'NON';
    Sub = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", SID) or 'NON';
    headText = string.format('%d%s/%d%s  Atk:%d  Def:%d', MainLV, Main, SubLV, Sub, Attk, Def);
end

function gcdisplay.CreateToggle(name, default)
	if (Toggles[name] == nil) then toggleKeys = nil end
	Toggles[name] = default;
end

function gcdisplay.GetToggle(name)
	return Toggles[name] or false;
end

function gcdisplay.GetToggles()
	local out = {};
	for k, v in pairs(Toggles) do out[k] = v end
	return out;
end

function gcdisplay.GetCycles()
	local out = {};
	for k, v in pairs(Cycles) do out[k] = v.Array[v.Index] end
	return out;
end

function gcdisplay.GetCycleValues(name) -- the cycle's value list (read only), nil if no such cycle
	local ctable = Cycles[name];
	return (type(ctable) == 'table') and ctable.Array or nil;
end

function gcdisplay.CreateCycle(name, values)
	local newCycle = {
		Index = 1,
		Array = values
	};
	if (Cycles[name] == nil) then cycleKeys = nil end
	Cycles[name] = newCycle;
end

function gcdisplay.GetCycle(name)
	local ctable = Cycles[name];
	if (type(ctable) == 'table') then
		return ctable.Array[ctable.Index];
	else
		return 'Unknown';
	end
end

function gcdisplay.ClearAll()
	Toggles = {};
	Cycles = {};
	DefToggles = {};
	DefCycles = {};
	toggleKeys, cycleKeys = nil, nil;
end

-- Snapshot of every toggle and cycle right after the job loads; the HUD hides values still at it.
function gcdisplay.MarkDefaults()
	DefToggles, DefCycles = {}, {};
	for k, v in pairs(Toggles) do DefToggles[k] = v end
	for k, v in pairs(Cycles) do DefCycles[k] = v.Index end
end

function gcdisplay.IsDefault(kind, name)
	if (kind == 'toggle') then return (DefToggles[name] ~= nil) and (DefToggles[name] == Toggles[name]) end
	local c = Cycles[name];
	return (c ~= nil) and (DefCycles[name] == c.Index);
end

local COL_ON = { 0.35, 0.95, 0.45, 1.0 };
local COL_OFF = { 0.95, 0.35, 0.35, 1.0 };
local COL_VAL = { 0.95, 0.85, 0.35, 1.0 };

local function sorted_keys(t)
	local keys = {};
	for k, _ in pairs(t) do keys[#keys + 1] = k end
	table.sort(keys);
	return keys;
end

-- Per-character bar state (x, y, on) in config\addons\luashitacast\gcbar\<name>.txt,
-- kept out of the hud folder so gchud never reads it.
local function bar_path()
	local p = gData.GetPlayer();
	if (p == nil) or (p.Name == nil) or (p.Name == '') then return nil, nil end
	return string.format('%sconfig\\addons\\luashitacast\\gcbar\\', AshitaCore:GetInstallPath()), p.Name .. '.txt';
end

local function bar_save()
	local dir, file = bar_path();
	if (dir == nil) then return end
	if not ashita.fs.exists(dir) then ashita.fs.create_directory(dir) end
	local f = io.open(dir .. file, 'w');
	if (f == nil) then return end
	f:write(string.format('%d,%d,%s', cfg.DisplayBarX or 300, cfg.DisplayBarY or 0, (cfg.DisplayBar == true) and 'on' or 'off'));
	f:close();
	barSavedX, barSavedY = cfg.DisplayBarX, cfg.DisplayBarY;
end

local function bar_load()
	local dir, file = bar_path();
	if (dir == nil) then return end
	local f = io.open(dir .. file, 'r');
	if (f == nil) then return end
	local text = f:read('*a') or '';
	f:close();
	local x, y, on = string.match(text, '^(%-?%d+),(%-?%d+),(%a+)');
	if (x == nil) then return end
	cfg.DisplayBarX, cfg.DisplayBarY = tonumber(x), tonumber(y);
	cfg.DisplayBar = (on == 'on');
	barSavedX, barSavedY = cfg.DisplayBarX, cfg.DisplayBarY;
end

local function track_drag()
	local x, y = imgui.GetWindowPos();
	if (type(x) == 'table') then x, y = x[1] or x.x, x[2] or x.y end
	x, y = tonumber(x), tonumber(y);
	if (x == nil) or (y == nil) or imgui.IsMouseDown(0) then return end
	x, y = math.floor(x + 0.5), math.floor(y + 0.5);
	if (x ~= barSavedX) or (y ~= barSavedY) then
		cfg.DisplayBarX, cfg.DisplayBarY = x, y;
		bar_save();
	end
end

local function bar_body()
	imgui.Text(headText);
	toggleKeys = toggleKeys or sorted_keys(Toggles);
	cycleKeys = cycleKeys or sorted_keys(Cycles);
	for _, k in ipairs(toggleKeys) do
		imgui.SameLine();
		imgui.PushStyleColor(ImGuiCol_Text, (Toggles[k] == true) and COL_ON or COL_OFF);
		imgui.Text(k);
		imgui.PopStyleColor();
	end
	for _, k in ipairs(cycleKeys) do
		local c = Cycles[k];
		imgui.SameLine();
		imgui.PushStyleColor(ImGuiCol_Text, COL_VAL);
		imgui.Text(k .. ':' .. tostring(c.Array[c.Index]));
		imgui.PopStyleColor();
	end
	track_drag();
end

local function render_bar()
	if (cfg == nil) or (cfg.DisplayBar ~= true) then return end
	if (not barPlaced) then
		imgui.SetNextWindowPos({ cfg.DisplayBarX or 300, cfg.DisplayBarY or 0 }, ImGuiCond_Always);
		barPlaced = true;
	end
	local flags = bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing,
		ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoResize);
	imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 4, 2 });
	imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 6, 1 });
	local ok, err = true, nil;
	if imgui.Begin('GC##gcdisplay_bar', true, flags) then
		-- an error here must not skip End/PopStyleVar, or ImGui asserts every frame after (as in gchud)
		ok, err = pcall(bar_body);
	end
	imgui.End();
	imgui.PopStyleVar(2);
	if (ok ~= true) then error(err, 0) end
end

function gcdisplay.BarCommand(args)
	if (cfg == nil) then return end
	local arg = (args[2] ~= nil) and string.lower(args[2]) or nil;
	if (arg == 'pos') and (tonumber(args[3]) ~= nil) and (tonumber(args[4]) ~= nil) then
		cfg.DisplayBarX, cfg.DisplayBarY = tonumber(args[3]), tonumber(args[4]);
		barPlaced = false;
		bar_save();
		return;
	elseif (arg == 'on') then cfg.DisplayBar = true;
	elseif (arg == 'off') then cfg.DisplayBar = false;
	else cfg.DisplayBar = not (cfg.DisplayBar == true) end
	gcdisplay.Update();
	barPlaced = false;
	bar_save();
	print(chat.header('GCinclude'):append(chat.message('Display bar: ' .. (cfg.DisplayBar and 'On' or 'Off'))));
end

function gcdisplay.Unload()
	ashita.events.unregister('d3d_present', 'gcdisplay_bar');
end

function gcdisplay.Initialize(settings)
	cfg = settings;
	barPlaced = false;
	pcall(bar_load);
	gcdisplay.Update();
	ashita.events.register('d3d_present', 'gcdisplay_bar', function ()
		local ok, err = pcall(render_bar);
		if (not ok) and (cfg ~= nil) and (cfg.DisplayBar == true) then
			cfg.DisplayBar = false;
			print(chat.header('GCinclude'):append(chat.error('Display bar off after an error: ' .. tostring(err))));
		end
	end);
end

return gcdisplay;