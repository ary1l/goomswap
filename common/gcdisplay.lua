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
local headText = '';
local headMID, headSID = nil, nil;

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

    local MID, SID = player:GetMainJob(), player:GetSubJob();
    local mlv, slv = player:GetMainJobLevel(), player:GetSubJobLevel();
    Def = player:GetDefense();
    Attk = player:GetAttack();
    if (MID == headMID) and (SID == headSID) and (mlv == MainLV) and (slv == SubLV) and (headText ~= '') then return end -- job text unchanged
    headMID, headSID, MainLV, SubLV = MID, SID, mlv, slv;
    Main = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", MID) or 'NON';
    Sub = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", SID) or 'NON';
    headText = string.format('%s%d/%s%d', Main, MainLV, Sub, SubLV);
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

-- Bar colours: as the HUD's (labels blue-grey, a changed value gold, one still at its load default soft gold).
-- One rounded capsule in three parts, split by thin lines: job | modes | the toggles that are on, each a dot in its
-- own colour (DT orange, MDT blue, Aminon purple, SIR blue, TH gold, Kite green...) then its name.
local COL_HEAD = { 0.93, 0.93, 0.96, 1.0 };
local COL_KEY = { 0.62, 0.68, 0.80, 1.0 };
-- Every job its own colour (picked to tell all 22 apart on the dark bar). Ashita outlines the job text: the main job's
-- half in its colour, the sub job's in its.
local JOB_COL = {
	WAR = { 1.00, 0.45, 0.40, 1.0 }, MNK = { 0.96, 0.70, 0.04, 1.0 }, WHM = { 0.97, 0.97, 0.97, 1.0 },
	BLM = { 0.71, 0.39, 1.00, 1.0 }, RDM = { 1.00, 0.22, 0.61, 1.0 }, THF = { 0.53, 1.00, 0.14, 1.0 },
	PLD = { 0.12, 0.71, 1.00, 1.0 }, DRK = { 0.73, 0.44, 0.80, 1.0 }, BST = { 0.85, 0.58, 0.33, 1.0 },
	BRD = { 0.80, 0.85, 0.02, 1.0 }, RNG = { 0.99, 1.00, 0.64, 1.0 }, SAM = { 0.72, 0.49, 0.48, 1.0 },
	NIN = { 0.53, 0.62, 0.70, 1.0 }, DRG = { 0.02, 0.98, 1.00, 1.0 }, SMN = { 0.18, 1.00, 0.76, 1.0 },
	BLU = { 0.19, 0.54, 1.00, 1.0 }, COR = { 0.28, 0.70, 0.57, 1.0 }, PUP = { 1.00, 0.55, 0.74, 1.0 },
	DNC = { 1.00, 0.18, 0.89, 1.0 }, SCH = { 0.82, 0.75, 1.00, 1.0 }, GEO = { 0.11, 0.81, 0.33, 1.0 },
	RUN = { 1.00, 0.45, 0.04, 1.0 }
};
local function job_col(j) return JOB_COL[string.upper(tostring(j or ''))] or COL_HEAD end
local COL_VAL = { 0.95, 0.85, 0.35, 1.0 };
local COL_VAL_DEF = { 0.73, 0.67, 0.50, 1.0 };
local COL_DIV = { 1.0, 1.0, 1.0, 0.20 };
local COL_EDGE = { 1.0, 1.0, 1.0, 0.10 };
local COL_BAR_BG = { 0.04, 0.045, 0.06 };
local TOGGLE_COL = { DTset = { 1.00, 0.59, 0.27, 1.0 }, MDTset = { 0.43, 0.71, 1.00, 1.0 }, Aminon = { 0.75, 0.59, 1.00, 1.0 },
	SIR = { 0.35, 0.55, 1.00, 1.0 }, TH = { 1.00, 0.80, 0.20, 1.0 }, Kite = { 0.35, 0.95, 0.45, 1.0 },
	Burst = { 1.00, 0.45, 0.75, 1.0 }, PROC = { 1.00, 0.35, 0.35, 1.0 }, String = { 0.35, 0.85, 0.85, 1.0 },
	SongLock = { 0.72, 0.52, 1.00, 1.0 }, Death = { 0.85, 0.30, 0.30, 1.0 } };

-- Modes in /gcmodes order (gcinclude.ModeNames), only those set to something ('-' ones are left out), then the
-- toggles that are on. The bar fits what it shows.
local BAR_TOGGLES = { 'DTset', 'MDTset', 'Aminon', 'SIR', 'TH', 'Kite', 'Burst', 'PROC', 'String', 'SongLock', 'Death' };
local FALLBACK_MODES = { {'Weapons', 'wpn'}, {'MeleeSet', 'melee'}, {'NukeSet', 'nuke'}, {'IdleSet', 'idle'} };

local IDLE_SHORT = { Refresh = 'MP', Regen = 'HP', Regain = 'TP' }; -- /idleset, kept small
-- With a weapon mode on the job, the wpn entry also carries (as the HUD's wpn cell): a + when a slot pick (/mw /sw /rw
-- /ammoset) is changed, its colour for the melee mode (green Base, gold Acc, orange SB), then a purple dot for /wsset
-- high and a blue dot for /hoxne. /gcmodes names them in full. A job without weapon modes shows them as their own entries.
local SLOT_PICKS = { Main = true, Sub = true, Range = true, Ammo = true };
local FOLD = { Main = true, Sub = true, Range = true, Ammo = true, MeleeSet = true, WsSet = true, Hoxne = true };
-- The wpn entry's own value: the weapon mode, else (a job with slot picks only, e.g. PLD) the main pick.
local function wpn_key() return ((Cycles.Weapons ~= nil) and 'Weapons') or ((Cycles.Main ~= nil) and 'Main') or nil end
local function folded(k) local w = wpn_key(); return FOLD[k] and (w ~= nil) and (k ~= w) end
local COL_MELEE = { Default = { 0.35, 0.95, 0.45, 1.0 }, Acc = { 0.95, 0.85, 0.35, 1.0 }, SubtleBlow = { 1.00, 0.67, 0.24, 1.0 } };
local COL_MELEE_MORE = { { 0.95, 0.55, 0.75, 1.0 }, { 0.55, 0.85, 1.00, 1.0 }, { 0.85, 0.85, 0.90, 1.0 } }; -- a job file's own modes
local COL_HIGHBUFF = { 0.72, 0.52, 1.00, 1.0 }; -- /wsset high dot
local COL_HOXNE = { 0.40, 0.62, 1.00, 1.0 };    -- /hoxne dot
local function melee_col(mode) -- the same colours as the HUD's wpn cell
	mode = tostring(mode or 'Default');
	if (COL_MELEE[mode] ~= nil) then return COL_MELEE[mode] end
	local n = 0;
	for i = 1, #mode do n = n + string.byte(mode, i) end
	return COL_MELEE_MORE[(n % #COL_MELEE_MORE) + 1];
end

local function xy(a, b)
	if (type(a) == 'table') then return tonumber(a[1] or a.x), tonumber(a[2] or a.y) end
	return tonumber(a), tonumber(b);
end

local function value_text(k, v)
	v = tostring(v);
	if (k == 'MeleeSet') and (v == 'Default') then return 'Base' end
	if (k == 'MeleeSet') and (v == 'SubtleBlow') then return 'SB' end
	if (k == 'IdleSet') and (IDLE_SHORT[v] ~= nil) then return IDLE_SHORT[v] end
	if (v == 'None') or (v == 'Off') or (v == 'Default') then return '-' end
	if (inc ~= nil) and (inc.ModeLabel ~= nil) then return tostring(inc.ModeLabel(k, v)) end
	return v;
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
	if (y > 0) and (y <= 8) then y = 0; barPlaced = false end -- dropped near the top: flush with it
	if (x ~= barSavedX) or (y ~= barSavedY) then
		cfg.DisplayBarX, cfg.DisplayBarY = x, y;
		bar_save();
	end
end

local function bar_body()
	-- Lines and dots are drawn shapes (Ashita's window draw list); the Windower text box has none, so it shows a | and
	-- the coloured names.
	local dl = (imgui.GetWindowDrawList ~= nil) and imgui.GetWindowDrawList() or nil;
	local lh = (imgui.GetTextLineHeight ~= nil) and imgui.GetTextLineHeight() or nil;
	if (dl ~= nil) and ((lh == nil) or (imgui.GetColorU32 == nil) or (imgui.GetCursorScreenPos == nil) or (imgui.GetItemRectMax == nil) or (imgui.GetItemRectMin == nil)) then dl = nil end
	local ITEM, SEG, DOT = 14, 9, 11; -- px: between items, each side of a divider, a dot and its name
	local first, gapNext, tail = true, nil, 0; -- tail: px of dots drawn after the last text
	local function put(text, col, gap)
		if first then first = false else imgui.SameLine(0, gapNext or gap or ITEM) end
		gapNext, tail = nil, 0;
		imgui.PushStyleColor(ImGuiCol_Text, col);
		imgui.Text(text);
		imgui.PopStyleColor();
	end
	local function divider()
		if (dl ~= nil) then
			local x2 = xy(imgui.GetItemRectMax());
			local _, y1 = xy(imgui.GetItemRectMin());
			if (x2 ~= nil) and (y1 ~= nil) then dl:AddLine({ x2 + tail + SEG, y1 + 1 }, { x2 + tail + SEG, y1 + lh - 1 }, imgui.GetColorU32(COL_DIV), 1) end
			gapNext = tail + SEG * 2;
		else
			put('|', COL_KEY);
		end
	end
	local function dotted(text, col)
		if first then first = false else imgui.SameLine(0, gapNext or ITEM) end
		gapNext, tail = nil, 0;
		if (dl ~= nil) then
			local x, y = xy(imgui.GetCursorScreenPos());
			if (x ~= nil) then dl:AddCircleFilled({ x + 4, y + lh / 2 }, 3.5, imgui.GetColorU32(col), 12) end
			imgui.SetCursorPosX(imgui.GetCursorPosX() + DOT);
		end
		imgui.PushStyleColor(ImGuiCol_Text, col);
		imgui.Text(text);
		imgui.PopStyleColor();
	end
	if (headText ~= '') then -- set by Update
		local mainT, subT = Main .. tostring(MainLV or ''), Sub .. tostring(SubLV or '');
		local x, y, split = nil, nil, nil;
		if (dl ~= nil) then x, y = xy(imgui.GetCursorScreenPos()) end
		put(mainT, job_col(Main));
		put('/', COL_KEY, 0);
		if (dl ~= nil) then
			local s1, s2 = xy(imgui.GetItemRectMin()), xy(imgui.GetItemRectMax());
			if (s1 ~= nil) and (s2 ~= nil) then split = (s1 + s2) / 2 end -- the outline changes colour at the '/'
		end
		put(subT, job_col(Sub), 0);
		if (x ~= nil) and (y ~= nil) and (split ~= nil) then
			local x2, y2 = xy(imgui.GetItemRectMax());
			if (x2 ~= nil) and (y2 ~= nil) then
				local a, b = { x - 5, y + 1 }, { x2 + 5, y2 - 1 }; -- 1px in from the bar's edge
				local function line(c) return imgui.GetColorU32({ c[1], c[2], c[3], 0.90 }) end
				if (dl.PushClipRect ~= nil) and (dl.PopClipRect ~= nil) then -- left half the main job's colour, right half the sub's
					dl:PushClipRect({ a[1] - 1, a[2] - 1 }, { split, b[2] + 1 }, true);
					dl:AddRect(a, b, line(job_col(Main)), 7, 0, 1);
					dl:PopClipRect();
					dl:PushClipRect({ split, a[2] - 1 }, { b[1] + 1, b[2] + 1 }, true);
					dl:AddRect(a, b, line(job_col(Sub)), 7, 0, 1);
					dl:PopClipRect();
				else
					dl:AddRect(a, b, line(job_col(Main)), 7, 0, 1);
				end
			end
		end
	else
		put(headText, COL_HEAD);
	end
	put('Atk ', COL_KEY, (dl ~= nil) and 13 or 8); put(tostring(Attk), COL_HEAD, 0); -- labelled, so it doesn't read as HP
	put('Def ', COL_KEY, 8); put(tostring(Def), COL_HEAD, 0);
	local names = ((inc ~= nil) and inc.ModeNames) or FALLBACK_MODES;
	local picked = false;
	for k in pairs(SLOT_PICKS) do
		local c = Cycles[k];
		-- set, and not the job's own default pick (PLD's Aegis): a + means you changed one
		if folded(k) and (c ~= nil) and (value_text(k, c.Array[c.Index]) ~= '-') and not gcdisplay.IsDefault('cycle', k) then picked = true end
	end
	local modes = {};
	local wk = wpn_key();
	if (wk ~= nil) then
		local c, mc, hx, ws = Cycles[wk], Cycles.MeleeSet, Cycles.Hoxne, Cycles.WsSet;
		local v = value_text(wk, c.Array[c.Index]);
		local mm = (mc ~= nil) and mc.Array[mc.Index] or 'Default';
		local hoxne = (hx ~= nil) and (hx.Array[hx.Index] ~= 'Off');
		local high = (ws ~= nil) and (ws.Array[ws.Index] == 'High');
		if (v ~= '-') or picked or (mm ~= 'Default') or hoxne or high then
			local parts = { { 'wpn ', COL_KEY }, { v .. (picked and '+' or ''), melee_col(mm) } };
			if high then parts[#parts + 1] = { dot = COL_HIGHBUFF } end
			if hoxne then parts[#parts + 1] = { dot = COL_HOXNE } end
			modes[#modes + 1] = parts;
		end
	end
	for _, m in ipairs(names) do
		local k, label = m[1], m[2];
		local c = Cycles[k];
		local v = ((c ~= nil) and (k ~= wk) and not folded(k)) and value_text(k, c.Array[c.Index]) or '-';
		if (v ~= '-') and FOLD[k] and (wk == nil) and gcdisplay.IsDefault('cycle', k) then v = '-' end -- no wpn entry to carry them: only once changed
		if (v ~= '-') then modes[#modes + 1] = { { label .. ' ', COL_KEY }, { v, gcdisplay.IsDefault('cycle', k) and COL_VAL_DEF or COL_VAL } } end
	end
	if (#modes > 0) then
		divider();
		for _, parts in ipairs(modes) do
			local dots = 0;
			for i, p in ipairs(parts) do
				if (p.dot == nil) then
					put(p[1], p[2], (i > 1) and 0 or nil);
				elseif (dl ~= nil) then -- after the last text, which the next entry's gap makes room for
					local x2, y2 = xy(imgui.GetItemRectMax());
					local _, y1 = xy(imgui.GetItemRectMin());
					if (x2 ~= nil) and (y1 ~= nil) and (y2 ~= nil) then
						dl:AddCircleFilled({ x2 + 6 + dots * 8, (y1 + y2) / 2 }, 3, imgui.GetColorU32(p.dot), 12);
					end
					dots = dots + 1;
					tail = dots * 8 + 3;
					gapNext = ITEM + tail;
				else
					put('o', p.dot, 0); -- Windower: no shapes
				end
			end
		end
	end
	local tnames = (inc ~= nil) and inc.ToggleNames or {};
	local on = {};
	for _, k in ipairs(BAR_TOGGLES) do
		if (Toggles[k] == true) then on[#on + 1] = k end
	end
	if (#on > 0) then
		divider();
		for i, k in ipairs(on) do dotted(tnames[k] or k, TOGGLE_COL[k] or { 0.35, 0.95, 0.45, 1.0 }) end
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
	imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 10, 1 }); -- 1px above and below the text: room for the job outline
	imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 5, 1 });
	imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 12); -- a capsule
	imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1);
	imgui.PushStyleColor(ImGuiCol_WindowBg, { COL_BAR_BG[1], COL_BAR_BG[2], COL_BAR_BG[3], cfg.HUDAlpha or 0.70 }); -- as the HUD
	imgui.PushStyleColor(ImGuiCol_Border, COL_EDGE);
	local ok, err = true, nil;
	if imgui.Begin('GC##gcdisplay_bar', true, flags) then
		-- an error here must not skip End/PopStyleVar, or ImGui asserts every frame after (as in gchud)
		ok, err = pcall(bar_body);
	end
	imgui.End();
	imgui.PopStyleColor(2);
	imgui.PopStyleVar(4);
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