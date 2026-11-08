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
local version = 0; -- bumped on every toggle/cycle change: the bar's model and the HUD's state line rebuild on it
function gcdisplay.Version() return version end

function gcdisplay.AdvanceCycle(name)
	local ctable = Cycles[name];
	if (type(ctable) ~= 'table') then
		return;
	end

	ctable.Index = ctable.Index + 1;
	if (ctable.Index > #ctable.Array) then
		ctable.Index = 1;
	end
	version = version + 1;
end

function gcdisplay.SetCycle(name,val)
	local ctable = Cycles[name];
	if (type(ctable) ~= 'table') then
		return;
	end

	for k,v in pairs(ctable.Array) do
		if val == v then
			if (ctable.Index ~= k) then ctable.Index = k; version = version + 1 end
			return true
		end
	end
	return false
end

function gcdisplay.AdvanceToggle(name)
	if (type(Toggles[name]) == 'boolean') then Toggles[name] = not Toggles[name]; version = version + 1 end
end

function gcdisplay.SetToggle(name, val)
	if (type(Toggles[name]) ~= 'boolean') then return end
	if (Toggles[name] ~= (val == true)) then Toggles[name] = (val == true); version = version + 1 end
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
	version = version + 1;
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
	version = version + 1;
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
	version = version + 1;
end

-- Snapshot of every toggle and cycle right after the job loads; the HUD hides values still at it.
function gcdisplay.MarkDefaults()
	DefToggles, DefCycles = {}, {};
	for k, v in pairs(Toggles) do DefToggles[k] = v end
	for k, v in pairs(Cycles) do DefCycles[k] = v.Index end
	version = version + 1;
end

function gcdisplay.IsDefault(kind, name)
	if (kind == 'toggle') then return (DefToggles[name] ~= nil) and (DefToggles[name] == Toggles[name]) end
	local c = Cycles[name];
	return (c ~= nil) and (DefCycles[name] == c.Index);
end

-- Bar colours: labels blue-grey, values white. One rounded capsule in three parts, split by thin lines: job | modes | def
-- and the toggles. Every mode and toggle is a pill (gcdisplay.Pill, the HUD's cells too): set or on, outlined and tinted
-- in its colour with a solid dot; at its default or off, a dashed grey outline with a ring; a weapon, plain.
local COL_HEAD = { 0.93, 0.93, 0.96, 1.0 };
local COL_KEY = { 0.62, 0.68, 0.80, 1.0 };
-- Every job its own colour (picked to tell all 22 apart on the dark bar; RNG moss green, COR mustard gold, WHM light rose). Ashita outlines the job text: the main job's
-- half in its colour, the sub job's in its.
local JOB_COL = {
	WAR = { 1.00, 0.45, 0.40, 1.0 }, MNK = { 0.96, 0.70, 0.04, 1.0 }, WHM = { 1.00, 0.82, 0.75, 1.0 },
	BLM = { 0.71, 0.39, 1.00, 1.0 }, RDM = { 1.00, 0.22, 0.61, 1.0 }, THF = { 0.53, 1.00, 0.14, 1.0 },
	PLD = { 0.12, 0.71, 1.00, 1.0 }, DRK = { 0.73, 0.44, 0.80, 1.0 }, BST = { 0.85, 0.58, 0.33, 1.0 },
	BRD = { 0.80, 0.85, 0.02, 1.0 }, RNG = { 0.52, 0.65, 0.36, 1.0 }, SAM = { 0.72, 0.49, 0.48, 1.0 },
	NIN = { 0.53, 0.62, 0.70, 1.0 }, DRG = { 0.02, 0.98, 1.00, 1.0 }, SMN = { 0.18, 1.00, 0.76, 1.0 },
	BLU = { 0.19, 0.54, 1.00, 1.0 }, COR = { 0.65, 0.61, 0.10, 1.0 }, PUP = { 1.00, 0.55, 0.74, 1.0 },
	DNC = { 1.00, 0.18, 0.89, 1.0 }, SCH = { 0.82, 0.75, 1.00, 1.0 }, GEO = { 0.11, 0.81, 0.33, 1.0 },
	RUN = { 1.00, 0.45, 0.04, 1.0 }
};
local function job_col(j) return JOB_COL[string.upper(tostring(j or ''))] or COL_HEAD end
function gcdisplay.JobColor(j) return JOB_COL[string.upper(tostring(j or ''))] end -- the HUD's names; nil if unknown
local COL_DIV = { 1.0, 1.0, 1.0, 0.20 };
local COL_EDGE = { 1.0, 1.0, 1.0, 0.10 };
local COL_BAR_BG = { 0.04, 0.045, 0.06 };

-- Mode and toggle colours, the bar's and the HUD's: every meaning its own.
local CYAN, MAGENTA, PURPLE = { 0.25, 0.88, 1.00, 1.0 }, { 0.94, 0.35, 0.90, 1.0 }, { 0.65, 0.40, 1.00, 1.0 };
local MODE_COL = {
	MeleeSet = { Acc = CYAN, SubtleBlow = MAGENTA },
	WsSet = { High = PURPLE },
	IdleSet = { Refresh = { 0.45, 0.70, 1.00, 1.0 }, Regen = { 0.40, 0.90, 0.50, 1.0 }, Regain = { 0.95, 0.85, 0.35, 1.0 } }, -- mp blue, hp green, tp yellow
	NukeSet = { Macc = { 0.24, 0.82, 0.71, 1.0 }, OccultAcumen = { 1.00, 0.59, 0.55, 1.0 } }, -- teal, salmon
	RangedSet = { Acc = CYAN },
	Hoxne = { Locked = { 0.82, 0.63, 0.39, 1.0 } }, -- bronze
	TankSet = { Main = { 0.55, 0.74, 1.00, 1.0 }, MEVA = { 0.71, 0.94, 0.35, 1.0 } }, -- periwinkle, lime
};
local COL_MORE = { { 0.71, 0.94, 0.35, 1.0 }, { 1.00, 0.59, 0.55, 1.0 }, { 0.55, 0.74, 1.00, 1.0 } }; -- a job file's own modes: lime, salmon, periwinkle
local MODE_EMPTY = { MeleeSet = 'Default', WsSet = 'Mid', NukeSet = 'Power', IdleSet = 'Default', RangedSet = 'Default',
	Hoxne = 'Off', TankSet = 'None' }; -- each mode's nothing-laid-over value
local EMPTY_ANY = { None = true, Off = true, Default = true, Unknown = true };
local MODE_PLAIN = { Weapons = true, Main = true, Sub = true, Range = true, Ammo = true, Element = true, Weapon = true, PupMode = true }; -- always something
local MODE_TEXT = { MeleeSet = { SubtleBlow = 'sb' }, IdleSet = { Refresh = 'mp', Regen = 'hp', Regain = 'tp' },
	NukeSet = { OccultAcumen = 'oa' }, RangedSet = { Acc = 'racc' }, Hoxne = { Locked = 'hoxne' } };
local TOGGLE_COL = { DTset = { 1.00, 0.54, 0.24, 1.0 }, MDTset = { 0.43, 0.53, 1.00, 1.0 }, Aminon = { 0.75, 0.47, 0.85, 1.0 },
	SIR = { 0.24, 0.82, 0.71, 1.0 }, TH = { 0.95, 0.85, 0.35, 1.0 }, Kite = { 0.35, 0.95, 0.45, 1.0 },
	Burst = { 1.00, 0.48, 0.72, 1.0 }, PROC = { 1.00, 0.35, 0.35, 1.0 }, String = { 0.24, 0.82, 0.71, 1.0 },
	SongLock = { 0.65, 0.40, 1.00, 1.0 }, Death = { 1.00, 0.35, 0.35, 1.0 } };
-- A cycle value's pill: 'plain' (weapons, element...: always something), 'def' (nothing laid over) or 'set', and its colour.
function gcdisplay.ModeKind(k, v)
	v = tostring(v or '');
	if MODE_PLAIN[k] then return 'plain', nil end
	if (v == MODE_EMPTY[k]) or EMPTY_ANY[v] then return 'def', nil end
	local c = MODE_COL[k] and MODE_COL[k][v];
	if (c == nil) then
		local n = 0;
		for i = 1, #v do n = n + string.byte(v, i) end
		c = COL_MORE[(n % #COL_MORE) + 1];
	end
	return 'set', c;
end
function gcdisplay.ModeText(k, v) -- lower case, short: sb, mp, oa...
	v = tostring(v or '');
	local t = MODE_TEXT[k] and MODE_TEXT[k][v];
	if (t ~= nil) then return t end
	if (inc ~= nil) and (inc.ModeLabel ~= nil) then v = tostring(inc.ModeLabel(k, v)) end
	return string.lower(v);
end
function gcdisplay.ToggleColor(k) return TOGGLE_COL[k] or { 0.35, 0.95, 0.45, 1.0 } end

-- Pills. LEAD: px from the pill's left edge to its text (the dot before it); PLAIN_LEAD with no dot; TAIL after the text.
local PILL_GREY = { 0.50, 0.50, 0.56 };
local COL_PILL_TEXT = { 0.93, 0.93, 0.96, 1.0 };
local COL_PILL_DIM = { 0.55, 0.55, 0.61, 0.90 };
gcdisplay.PILL_LEAD, gcdisplay.PILL_PLAIN_LEAD, gcdisplay.PILL_TAIL = 13, 5, 5;
gcdisplay.COL_PILL_TEXT, gcdisplay.COL_PILL_DIM = COL_PILL_TEXT, COL_PILL_DIM;
local function rgba(c, a) return imgui.GetColorU32({ c[1], c[2], c[3], a or c[4] or 1.0 }) end
-- A rounded outline as dashes (ImGui draws no dashed lines), per pill size, worked out once: { x1, y1, xm, ym, x2, y2 }
-- each, from the top left, the middle point keeping the dashes on the round ends.
local dashCache = {};
local function dashes(w, h)
	local key = w .. 'x' .. h;
	local hit = dashCache[key];
	if (hit ~= nil) then return hit end
	local r = math.min(h / 2, w / 2);
	local sx, sy, q = w - 2 * r, h - 2 * r, math.pi * r / 2;
	local runs = { -- clockwise from the top edge; each { length, fn(t) -> x, y }
		{ sx, function(t) return r + t, 0 end },
		{ q, function(t) local a = -math.pi / 2 + t / r; return w - r + r * math.cos(a), r + r * math.sin(a) end },
		{ sy, function(t) return w, r + t end },
		{ q, function(t) local a = t / r; return w - r + r * math.cos(a), h - r + r * math.sin(a) end },
		{ sx, function(t) return w - r - t, h end },
		{ q, function(t) local a = math.pi / 2 + t / r; return r + r * math.cos(a), h - r + r * math.sin(a) end },
		{ sy, function(t) return 0, h - r - t end },
		{ q, function(t) local a = math.pi + t / r; return r + r * math.cos(a), r + r * math.sin(a) end },
	};
	local total = 0;
	for _, run in ipairs(runs) do total = total + run[1] end
	local function at(s)
		for _, run in ipairs(runs) do
			if (s <= run[1]) then return run[2](s) end
			s = s - run[1];
		end
		return r, 0;
	end
	local n = math.max(4, math.floor(total / 5 + 0.5)); -- ~3px on, 2px off, evenly round
	local period = total / n;
	local out = {};
	for i = 0, n - 1 do
		local s = i * period;
		local ax, ay = at(s);
		local mx, my = at(s + period * 0.3);
		local bx, by = at(s + period * 0.6);
		out[#out + 1] = { ax, ay, mx, my, bx, by };
	end
	dashCache[key] = out;
	return out;
end
-- kind: 'set' (col: outline, tint, solid dot), 'plain' (col or grey: outline, tint if col, no dot), 'def' (dashed grey, ring).
function gcdisplay.Pill(dl, x1, y1, x2, y2, kind, col)
	local h = y2 - y1;
	local r, cy = h / 2, y1 + h / 2;
	if (kind == 'set') or ((kind == 'plain') and (col ~= nil)) then
		dl:AddRectFilled({ x1, y1 }, { x2, y2 }, rgba(col, 0.18), r);
		dl:AddRect({ x1, y1 }, { x2, y2 }, rgba(col, 0.90), r, 0, 1);
		if (kind == 'set') then dl:AddCircleFilled({ x1 + 7, cy }, 3, rgba(col, 1.0), 12) end
	elseif (kind == 'plain') then
		dl:AddRect({ x1, y1 }, { x2, y2 }, rgba({ 0.80, 0.80, 0.84 }, 0.45), r, 0, 1);
	else
		local grey = rgba(PILL_GREY, 0.60);
		local ox, oy = x1 + 0.5, y1 + 0.5;
		for _, d in ipairs(dashes(math.floor(x2 - x1 - 1), math.floor(h - 1))) do
			dl:AddLine({ ox + d[1], oy + d[2] }, { ox + d[3], oy + d[4] }, grey, 1);
			dl:AddLine({ ox + d[3], oy + d[4] }, { ox + d[5], oy + d[6] }, grey, 1);
		end
		dl:AddCircle({ x1 + 7, cy }, 2.6, rgba(PILL_GREY, 0.85), 12, 1.2);
	end
end
-- An outline split at x: left in colour a, right in b (the job box: main | sub).
function gcdisplay.SplitOutline(dl, x1, y1, x2, y2, split, a, b)
	local r = (y2 - y1) / 2;
	if (dl.PushClipRect ~= nil) and (dl.PopClipRect ~= nil) then
		dl:PushClipRect({ x1 - 1, y1 - 1 }, { split, y2 + 1 }, true);
		dl:AddRect({ x1, y1 }, { x2, y2 }, rgba(a, 0.90), r, 0, 1);
		dl:PopClipRect();
		dl:PushClipRect({ split, y1 - 1 }, { x2 + 1, y2 + 1 }, true);
		dl:AddRect({ x1, y1 }, { x2, y2 }, rgba(b, 0.90), r, 0, 1);
		dl:PopClipRect();
	else
		dl:AddRect({ x1, y1 }, { x2, y2 }, rgba(a, 0.90), r, 0, 1);
	end
end

-- The bar's pills, in this order: weapon | melee ws idle nuke elem weapon ranged tank pup hoxne | def sir th kite proc +
-- the job's own toggles. Each as wide as its widest text, so the bar keeps its width while you cycle.
local BAR_ORDER = { 'MeleeSet', 'WsSet', 'IdleSet', 'NukeSet', 'Element', 'Weapon', 'RangedSet', 'TankSet', 'PupMode', 'Hoxne' };
local BAR_LABEL = { MeleeSet = 'melee', WsSet = 'ws', IdleSet = 'idle', NukeSet = 'nuke', Element = 'elem', Weapon = 'weapon',
	RangedSet = 'ranged', TankSet = 'tank', PupMode = 'pup', Hoxne = 'hoxne' };
local BAR_TOGGLES = { 'SIR', 'TH', 'Kite', 'PROC', 'Burst', 'Death', 'String', 'SongLock' };
local TOGGLE_LABEL = { SIR = 'sir', TH = 'th', Kite = 'kite', PROC = 'proc', Burst = 'burst', Death = 'death', String = 'harp', SongLock = 'lock' };
local DEF_PARTS = { { 'DTset', 'dt' }, { 'MDTset', 'mdt' }, { 'Aminon', 'amin' } };
-- Click a pill: the command that cycles it, as the HUD's cells send (ctrl+click the weapon: /mset).
local BAR_CMD = { Weapons = 'wm', Main = 'mainset', Sub = 'subset', Range = 'rangeset', Ammo = 'ammoset', MeleeSet = 'mset',
	WsSet = 'wsset', NukeSet = 'nukeset', Element = 'elecycle', Weapon = 'weapon', TankSet = 'tankset', Hoxne = 'hoxne',
	PupMode = 'pupmode', IdleSet = 'idleset', RangedSet = 'rangedset' };
local BAR_TCMD = { DTset = 'dt', MDTset = 'mdt', Aminon = 'aminon', SIR = 'sir', TH = 'th', Kite = 'kite', Burst = 'burst',
	PROC = 'proc', String = 'forcestring', SongLock = 'songlock', Death = 'death' };
-- The weapon pill: the weapon mode (else the main pick, e.g. PLD), a + when a slot pick (/mw /sw /rw /ammoset) is changed.
-- A job without either shows melee, ws and hoxne only once changed (most mages never touch them).
local SLOT_PICKS = { 'Main', 'Sub', 'Range', 'Ammo' };
local WEAPONLESS = { MeleeSet = true, WsSet = true, Hoxne = true };
local function wpn_key() return ((Cycles.Weapons ~= nil) and 'Weapons') or ((Cycles.Main ~= nil) and 'Main') or nil end

local function xy(a, b)
	if (type(a) == 'table') then return tonumber(a[1] or a.x), tonumber(a[2] or a.y) end
	return tonumber(a), tonumber(b);
end

local function value_text(k, v) -- a weapon's text, as typed (Anarchy+)
	v = tostring(v);
	if (v == 'None') or (v == 'Off') then return '-' end
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

-- The bar's pills: built when a toggle or cycle changes (gcdisplay's version), not every frame. Each entry: kind, text,
-- col, cmd (ctrl: ctrl+click), texts (every text it can show: its width).
local modelVer, modelModes, modelOn = -1, nil, nil;
local function bar_model()
	if (modelVer == version) then return modelModes, modelOn end
	local modes, on = {}, {};
	local wk = wpn_key();
	if (wk ~= nil) then
		local picked = false;
		for _, k in ipairs(SLOT_PICKS) do
			local c = Cycles[k];
			-- set, and not the job's own default pick (PLD's Aegis): a + means you changed one
			if (k ~= wk) and (c ~= nil) and (value_text(k, c.Array[c.Index]) ~= '-') and not gcdisplay.IsDefault('cycle', k) then picked = true end
		end
		local c = Cycles[wk];
		local texts = {};
		for _, v in ipairs(c.Array) do texts[#texts + 1] = value_text(wk, v) .. '+' end
		modes[#modes + 1] = { key = wk, kind = 'plain', text = value_text(wk, c.Array[c.Index]) .. (picked and '+' or ''), texts = texts,
			cmd = BAR_CMD[wk], ctrl = (Cycles.MeleeSet ~= nil) and 'mset' or nil };
	else
		for _, k in ipairs(SLOT_PICKS) do -- no weapon pill to carry them: each once changed
			local c = Cycles[k];
			if (c ~= nil) and not gcdisplay.IsDefault('cycle', k) then
				modes[#modes + 1] = { key = k, kind = 'plain', text = value_text(k, c.Array[c.Index]), cmd = BAR_CMD[k] };
			end
		end
	end
	for _, k in ipairs(BAR_ORDER) do
		local c = Cycles[k];
		if (c ~= nil) then
			local v = c.Array[c.Index];
			local kind, col = gcdisplay.ModeKind(k, v);
			if (wk ~= nil) or not WEAPONLESS[k] or (kind ~= 'def') then
				local texts = { BAR_LABEL[k] };
				for _, x in ipairs(c.Array) do texts[#texts + 1] = gcdisplay.ModeText(k, x) end
				modes[#modes + 1] = { key = k, kind = kind, col = col, text = (kind == 'def') and BAR_LABEL[k] or gcdisplay.ModeText(k, v),
					texts = texts, cmd = BAR_CMD[k] };
			end
		end
	end
	-- def: DT, MDT, Aminon as one pill (/def), the first on (+ when more); then the toggles
	local parts, any = {}, false;
	for _, p in ipairs(DEF_PARTS) do
		if (Toggles[p[1]] ~= nil) then any = true end
		if (Toggles[p[1]] == true) then parts[#parts + 1] = p end
	end
	if any then
		local first = parts[1];
		on[#on + 1] = { key = 'Def', kind = (first ~= nil) and 'set' or 'def', col = (first ~= nil) and TOGGLE_COL[first[1]] or nil,
			text = (first ~= nil) and (first[2] .. ((#parts > 1) and '+' or '')) or 'def', texts = { 'def', 'dt+', 'mdt+', 'amin+' }, cmd = 'def' };
	end
	for _, k in ipairs(BAR_TOGGLES) do
		if (Toggles[k] ~= nil) then
			on[#on + 1] = { key = k, kind = (Toggles[k] == true) and 'set' or 'def', col = TOGGLE_COL[k], text = TOGGLE_LABEL[k], cmd = BAR_TCMD[k] };
		end
	end
	modelVer, modelModes, modelOn = version, modes, on;
	return modes, on;
end

local function textw(t)
	local w = imgui.CalcTextSize(t);
	if (type(w) == 'table') then w = w[1] or w.x end
	return tonumber(w) or 0;
end

local function bar_body()
	-- Pills, lines and outlines are drawn shapes (Ashita's window draw list); the Windower text box has none, so it shows
	-- a | and the words in their colours.
	local dl = (imgui.GetWindowDrawList ~= nil) and imgui.GetWindowDrawList() or nil;
	local lh = (imgui.GetTextLineHeight ~= nil) and imgui.GetTextLineHeight() or nil;
	if (dl ~= nil) and ((lh == nil) or (imgui.GetColorU32 == nil) or (imgui.GetCursorScreenPos == nil) or (imgui.GetItemRectMax == nil) or (imgui.GetItemRectMin == nil)) then dl = nil end
	local ITEM, SEG, PGAP = 14, 9, 5; -- px: between items, each side of a divider, between pills
	local first, gapNext, extra = true, nil, 0; -- extra: px held after the last item (a number's spare width)
	local function place(gap)
		if first then first = false else imgui.SameLine(0, (gapNext or gap or ITEM) + extra) end
		gapNext, extra = nil, 0;
	end
	local function run(cmd, ctrl)
		local ok, held = pcall(function() return imgui.GetIO().KeyCtrl end);
		AshitaCore:GetChatManager():QueueCommand(-1, '/lac fwd ' .. ((ok and held and ctrl) or cmd));
	end
	local function put(text, col, gap, cmd, ctrl) -- text, or a borderless button that runs cmd on this box
		place(gap);
		imgui.PushStyleColor(ImGuiCol_Text, col);
		if (cmd == nil) or (imgui.SmallButton == nil) then
			imgui.Text(text);
		elseif imgui.SmallButton(text .. '##gcbar_' .. cmd) then
			run(cmd, ctrl);
		end
		imgui.PopStyleColor();
	end
	local function hold(text, widest) -- keep a number's spot as wide as its widest
		if (dl ~= nil) then extra = math.max(0, textw(widest) - textw(text)) end
	end
	local function divider()
		if (dl ~= nil) then
			local x2 = xy(imgui.GetItemRectMax());
			local _, y1 = xy(imgui.GetItemRectMin());
			if (x2 ~= nil) and (y1 ~= nil) then dl:AddLine({ x2 + extra + SEG, y1 + 1 }, { x2 + extra + SEG, y1 + lh - 1 }, imgui.GetColorU32(COL_DIV), 1) end
			gapNext = SEG * 2;
		else
			put('|', COL_KEY);
		end
	end
	local function pill(e)
		if (dl == nil) then -- Windower: the word in its colour (grey at its default or off)
			put(e.text, (e.kind == 'set') and e.col or ((e.kind == 'def') and COL_PILL_DIM or COL_HEAD), PGAP + 4, e.cmd, e.ctrl);
			return;
		end
		place(PGAP);
		if (e.w == nil) then
			local w = textw(e.text);
			for _, t in ipairs(e.texts or {}) do w = math.max(w, textw(t)) end
			e.w = w;
		end
		local lead = (e.kind == 'plain') and gcdisplay.PILL_PLAIN_LEAD or gcdisplay.PILL_LEAD;
		local pw = math.floor(lead + e.w + gcdisplay.PILL_TAIL + 0.5);
		local x, y = xy(imgui.GetCursorScreenPos());
		if imgui.Button('##gcbar_' .. e.key, { pw, lh }) and (e.cmd ~= nil) then run(e.cmd, e.ctrl) end
		if (x ~= nil) and (y ~= nil) then
			gcdisplay.Pill(dl, x, y + 1, x + pw, y + lh - 1, e.kind, e.col);
			dl:AddText({ x + lead, y }, imgui.GetColorU32((e.kind == 'def') and COL_PILL_DIM or COL_PILL_TEXT), e.text);
		end
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
			if (x2 ~= nil) and (y2 ~= nil) then -- 1px in from the bar's edge; left half the main job's colour, right half the sub's
				gcdisplay.SplitOutline(dl, x - 5, y + 1, x2 + 5, y2 - 1, split, job_col(Main), job_col(Sub));
			end
		end
	else
		put(headText, COL_HEAD);
	end
	if (windower == nil) then -- Windower's player table has no attack/defense (the shim returns 0)
		put('Atk ', COL_KEY, (dl ~= nil) and 13 or 8); put(tostring(Attk), COL_HEAD, 0); hold(tostring(Attk), '0000'); -- labelled, so it doesn't read as HP
		put('Def ', COL_KEY, 8); put(tostring(Def), COL_HEAD, 0); hold(tostring(Def), '0000');
	end
	local modes, on = bar_model();
	if (#modes > 0) then
		divider();
		for _, e in ipairs(modes) do pill(e) end
	end
	if (#on > 0) then
		divider();
		for _, e in ipairs(on) do pill(e) end
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
	-- pills are borderless buttons under their drawn outline: hovered, a soft fill as round as the pill (as the HUD's cells)
	local styleVars = 4;
	if (ImGuiStyleVar_FramePadding ~= nil) then imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { 1, 0 }); styleVars = styleVars + 1 end
	if (ImGuiStyleVar_FrameBorderSize ~= nil) then imgui.PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0); styleVars = styleVars + 1 end
	if (ImGuiStyleVar_FrameRounding ~= nil) then imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 7); styleVars = styleVars + 1 end
	imgui.PushStyleColor(ImGuiCol_WindowBg, { COL_BAR_BG[1], COL_BAR_BG[2], COL_BAR_BG[3], cfg.HUDAlpha or 0.70 }); -- as the HUD
	imgui.PushStyleColor(ImGuiCol_Border, COL_EDGE);
	imgui.PushStyleColor(ImGuiCol_Button, { 0, 0, 0, 0 });
	imgui.PushStyleColor(ImGuiCol_ButtonHovered, { 1, 1, 1, 0.12 });
	imgui.PushStyleColor(ImGuiCol_ButtonActive, { 1, 1, 1, 0.12 });
	local ok, err = true, nil;
	if imgui.Begin('GC##gcdisplay_bar', true, flags) then
		-- an error here must not skip End/PopStyleVar, or ImGui asserts every frame after (as in gchud)
		ok, err = pcall(bar_body);
	end
	imgui.End();
	imgui.PopStyleColor(5);
	imgui.PopStyleVar(styleVars);
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