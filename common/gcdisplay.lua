local gcdisplay = {};

local imgui = require('imgui');
local cfg = nil;
local inc = nil; -- gcinclude: the bar's mode names and labels
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
local headText, statText = '', '';

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
    headText = string.format('%s%d/%s%d', Main, MainLV, Sub, SubLV);
    statText = string.format('Atk %d  Def %d', Attk, Def);
end

function gcdisplay.CreateToggle(name, default)
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

-- Bar colours: as the HUD's (labels blue-grey, a changed value gold, one still at its load default dim gold,
-- a toggle that's on green, off grey).
local COL_HEAD = { 0.93, 0.93, 0.96, 1.0 };
local COL_KEY = { 0.62, 0.68, 0.80, 1.0 };
local COL_VAL = { 0.95, 0.85, 0.35, 1.0 };
local COL_VAL_DEF = { 0.72, 0.68, 0.50, 1.0 };
local COL_EMPTY = { 0.50, 0.50, 0.55, 1.0 };
local COL_ON = { 0.35, 0.95, 0.45, 1.0 };
local COL_OFF = { 0.45, 0.45, 0.50, 1.0 };

-- Modes in /gcmodes order (gcinclude.ModeNames), then toggles by their short names, each in a slot as wide as its
-- widest value, so the bar never changes width when a mode does.
local BAR_TOGGLES = { 'DTset', 'MDTset', 'Aminon', 'SIR', 'TH', 'Kite', 'Burst', 'PROC', 'String', 'SongLock', 'Death' };
local FALLBACK_MODES = { {'Weapons', 'wpn'}, {'MeleeSet', 'melee'}, {'NukeSet', 'nuke'}, {'IdleSet', 'idle'} };

local function textw(t)
	local w = imgui.CalcTextSize(t);
	if (type(w) == 'table') then w = w[1] or w.x end
	return tonumber(w) or 0;
end

local function value_text(k, v)
	v = tostring(v);
	if (k == 'MeleeSet') and (v == 'Default') then return 'Base' end
	if (v == 'None') or (v == 'Off') or (v == 'Default') then return '-' end
	if (inc ~= nil) and (inc.ModeLabel ~= nil) then return tostring(inc.ModeLabel(k, v)) end
	return v;
end

local widest = {}; -- [cycle name] = { arr = its value list, w = widest value }
local function widest_of(k, c)
	local e = widest[k];
	if (e ~= nil) and (e.arr == c.Array) and (e.unit == textw('M')) then return e.w end
	local w = 0;
	for _, v in ipairs(c.Array) do w = math.max(w, textw(value_text(k, v))) end
	widest[k] = { arr = c.Array, w = w, unit = textw('M') };
	return w;
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
	local x0 = imgui.GetCursorPosX();
	local gap = textw('  ');
	local x = x0;
	local first = true;
	local function put(text, col, w)
		if first then first = false else imgui.SameLine(x) end
		imgui.PushStyleColor(ImGuiCol_Text, col);
		imgui.Text(text);
		imgui.PopStyleColor();
		x = x + (w or textw(text));
	end
	local function sep() x = x + gap; put('|', COL_KEY); x = x + gap end
	put(headText, COL_HEAD, textw('WWW99/WWW99'));
	x = x + gap;
	put(statText, COL_KEY, textw('Atk 9999  Def 9999'));
	sep();
	local names = ((inc ~= nil) and inc.ModeNames) or FALLBACK_MODES;
	local any = false;
	for _, m in ipairs(names) do
		local k, label = m[1], m[2];
		local c = Cycles[k];
		if (c ~= nil) then
			if any then x = x + gap end
			any = true;
			put(label, COL_KEY);
			x = x + textw(' ');
			local v = value_text(k, c.Array[c.Index]);
			local col = (v == '-') and COL_EMPTY or (gcdisplay.IsDefault('cycle', k) and COL_VAL_DEF or COL_VAL);
			put(v, col, widest_of(k, c));
		end
	end
	local tnames = (inc ~= nil) and inc.ToggleNames or {};
	local shown = false;
	for _, k in ipairs(BAR_TOGGLES) do
		if (Toggles[k] ~= nil) then
			if not shown then sep(); shown = true else x = x + textw(' ') end
			put(tnames[k] or k, (Toggles[k] == true) and COL_ON or COL_OFF);
		end
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
	if (imgui.SetNextWindowBgAlpha ~= nil) then imgui.SetNextWindowBgAlpha(cfg.HUDAlpha or 0.70) end -- as the HUD
	imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 6, 3 });
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
	print(chat.header('GoomSwap'):append(chat.message('Display bar: ' .. (cfg.DisplayBar and 'On' or 'Off'))));
end

function gcdisplay.Unload()
	ashita.events.unregister('d3d_present', 'gcdisplay_bar');
end

function gcdisplay.Initialize(settings, include)
	cfg = settings;
	inc = include;
	widest = {};
	barPlaced = false;
	pcall(bar_load);
	gcdisplay.Update();
	ashita.events.register('d3d_present', 'gcdisplay_bar', function ()
		local ok, err = pcall(render_bar);
		if (not ok) and (cfg ~= nil) and (cfg.DisplayBar == true) then
			cfg.DisplayBar = false;
			print(chat.header('GoomSwap'):append(chat.error('Display bar off after an error: ' .. tostring(err))));
		end
	end);
end

return gcdisplay;