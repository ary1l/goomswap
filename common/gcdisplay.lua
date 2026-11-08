local gcdisplay = {};

local imgui = require('imgui');
local cfg = nil;
local inc = nil; -- gcinclude: the bar's mode names and labels
local barPlaced = false;
local placedX, placedY, heldSeen = nil, nil, false; -- where the bar's own line was put; a mouse press since (a drag)

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
-- The weapon pill's colour: its weapon's class, as a job's colour. Classes from the game's own item descriptions
-- (Windower resources: each class has its own Aftermath) and BG-Wiki's Prime Weapons; TP bonus = the Ambuscade +2
-- weapons named here. settings.WeaponClass = { ['Item Name'] = 'tpbonus' } adds or overrides (classes as below).
local WEAPON_COL = { relic = { 0.45, 0.80, 1.00, 1.0 }, mythic = { 0.35, 0.85, 0.45, 1.0 }, empyrean = { 1.00, 0.35, 0.35, 1.0 },
	prime = { 0.70, 0.45, 1.00, 1.0 }, aeonic = { 1.00, 0.62, 0.20, 1.0 }, tpbonus = { 0.30, 0.45, 1.00, 1.0 } }; -- light blue, green (ergon too), red, purple, orange, dark blue
local WEAPON_CLASS = {};
for cls, list in pairs({
	relic = { 'Spharai', 'Mandau', 'Excalibur', 'Ragnarok', 'Guttler', 'Bravura', 'Apocalypse', 'Gungnir', 'Kikoku', 'Amanomurakumo',
		'Mjollnir', 'Claustrum', 'Annihilator', 'Yoichinoyumi' },
	mythic = { 'Conqueror', 'Glanzfaust', 'Yagrush', 'Laevateinn', 'Murgleis', 'Vajra', 'Burtgang', 'Liberator', 'Aymur', 'Carnwenhan',
		'Gastraphetes', 'Kogarasumaru', 'Nagi', 'Ryunohige', 'Nirvana', 'Tizona', 'Death Penalty', 'Kenkonken', 'Terpsichore', 'Tupsimati',
		'Idris', 'Epeolatry' }, -- the last two: Ergon
	empyrean = { 'Verethragna', 'Twashtar', 'Almace', 'Caladbolg', 'Farsha', 'Ukonvasara', 'Redemption', 'Rhongomiant', 'Kannagi',
		'Masamune', 'Gambanteinn', 'Hvergelmir', 'Gandiva', 'Armageddon' },
	aeonic = { 'Godhands', 'Aeneas', 'Sequence', 'Lionheart', 'Tri-edge', 'Chango', 'Anguta', 'Trishula', 'Heishi Shorinken',
		'Dojikiri Yasutsuna', 'Tishtrya', 'Khatvanga', 'Fail-Not', 'Fomalhaut' },
	prime = { 'Varga Purnikawa', 'Mpu Gandring', 'Caliburnus', 'Helheim', 'Foenaria', 'Spalirisos', 'Laphria', 'Kusanagi', 'Gae Buide',
		'Dokoku', 'Lorg Mor', 'Opashoro', 'Pinaka', 'Earp', 'Duban', 'Loughnashade' },
	tpbonus = { 'Sparrowhawk +2', 'Anarchy +2' },
}) do
	for _, n in ipairs(list) do WEAPON_CLASS[string.lower(n)] = cls end
end
local function item_class(v)
	local n = (type(v) == 'table') and (v.Name or v.name) or v;
	if (type(n) ~= 'string') then return nil end
	n = string.lower(n);
	local user = (cfg ~= nil) and cfg.WeaponClass or nil;
	if (type(user) == 'table') then
		for k, c in pairs(user) do
			if (string.lower(tostring(k)) == n) and (WEAPON_COL[string.lower(tostring(c))] ~= nil) then return string.lower(tostring(c)) end
		end
	end
	return WEAPON_CLASS[n];
end
-- A weapon mode's class: its set's Main if classed, else Range (guns, bows), else Sub; a slot pick (no modes): the item.
local function mode_class(wk, v)
	if (v == nil) then return nil end
	if (wk ~= 'Weapons') then return item_class(v) end
	local set = (inc ~= nil) and (inc.FindSet ~= nil) and inc.FindSet('Weapon_' .. tostring(v)) or nil;
	if (type(set) ~= 'table') then return item_class(v) end
	return item_class(set.Main) or item_class(set.Range) or item_class(set.Sub);
end
function gcdisplay.WeaponClass() -- this box's, for the HUD line (the other boxes' drop shows it)
	local wk = ((Cycles.Weapons ~= nil) and 'Weapons') or ((Cycles.Main ~= nil) and 'Main') or nil;
	if (wk == nil) then return nil end
	local c = Cycles[wk];
	return mode_class(wk, c.Array[c.Index]);
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
	local x = (tonumber(cfg.DisplayBarX) ~= nil) and string.format('%d', cfg.DisplayBarX) or 'auto';
	f:write(string.format('%s,%d,%s', x, cfg.DisplayBarY or 0, (cfg.DisplayBar == true) and 'on' or 'off'));
	f:close();
end

local function bar_load()
	local dir, file = bar_path();
	if (dir == nil) then return end
	local f = io.open(dir .. file, 'r');
	if (f == nil) then return end
	local text = f:read('*a') or '';
	f:close();
	local x, y, on = string.match(text, '^(%-?%w+),(%-?%d+),(%a+)');
	if (x == nil) then return end
	if (x == '300') and (y == '0') then x = 'auto' end -- the old default, never dragged
	cfg.DisplayBarX, cfg.DisplayBarY = tonumber(x), tonumber(y); -- 'auto': nil
	cfg.DisplayBar = (on == 'on');
end

-- Dragged (moved from where it was put, after a mouse press): that spot is saved and kept (no longer auto).
local function track_drag(ownDy) -- ownDy: px from the window's top to this box's own line (the drop rising above it)
	local x, y = xy(imgui.GetWindowPos());
	if (x == nil) or (y == nil) or imgui.IsMouseDown(0) or not heldSeen then return end
	heldSeen = false;
	x, y = math.floor(x + 0.5), math.floor(y + (ownDy or 0) + 0.5);
	if (placedX ~= nil) and (math.abs(x - placedX) <= 1) and (math.abs(y - (placedY or 0)) <= 1) then return end -- a click, not a drag
	if (y > 0) and (y <= 8) then y = 0; barPlaced = false end -- dropped near the top: flush with it
	cfg.DisplayBarX, cfg.DisplayBarY = x, y;
	placedX, placedY = x, y;
	bar_save();
end

-- Lines: this box's (the bar) and, hovered with /gchud on, one per other box dropped under it (gchud's rows), every
-- pill in its column: as wide as its widest text so far, blank where a line's job has no such mode.
local hud = nil; -- gchud: the other boxes' modes, and sending them a click
local barH = nil; -- the bar's own height (its line alone), measured while the drop is shut
function gcdisplay.SetHud(h) hud = h end
local LINE_COLS = { 'wpn', 'Main', 'Sub', 'Range', 'Ammo', 'MeleeSet', 'WsSet', 'IdleSet', 'NukeSet', 'Element', 'Weapon',
	'RangedSet', 'TankSet', 'PupMode', 'Hoxne', '|', 'Def', 'SIR', 'TH', 'Kite', 'PROC', 'Burst', 'Death', 'String', 'SongLock' };
-- One line's pills by column. cyc(k): value, still at its load default; vals(k): every value (own box only, for widths);
-- tog(k): true / false / nil (the job has none).
local function build_line(cyc, vals, tog, wclass)
	local map = {};
	local wk = (cyc('Weapons') ~= nil) and 'Weapons' or ((cyc('Main') ~= nil) and 'Main' or nil);
	if (wk ~= nil) then
		local picked = false;
		for _, k in ipairs(SLOT_PICKS) do
			local v, d = cyc(k);
			-- set, and not the job's own default pick (PLD's Aegis): a + means you changed one
			if (k ~= wk) and (v ~= nil) and (value_text(k, v) ~= '-') and not d then picked = true end
		end
		local texts = {};
		for _, x in ipairs(vals(wk) or {}) do texts[#texts + 1] = value_text(wk, x) .. '+' end
		map.wpn = { kind = 'plain', text = value_text(wk, (cyc(wk))) .. (picked and '+' or ''), texts = texts, cmd = BAR_CMD[wk],
			ctrl = (cyc('MeleeSet') ~= nil) and 'mset' or nil, col = WEAPON_COL[wclass(wk, (cyc(wk))) or ''] };
	else
		for _, k in ipairs(SLOT_PICKS) do -- no weapon pill to carry them: each once changed
			local v, d = cyc(k);
			if (v ~= nil) and not d then map[k] = { kind = 'plain', text = value_text(k, v), cmd = BAR_CMD[k] } end
		end
	end
	for _, k in ipairs(BAR_ORDER) do
		local v = cyc(k);
		if (v ~= nil) then
			local kind, col = gcdisplay.ModeKind(k, v);
			if (wk ~= nil) or not WEAPONLESS[k] or (kind ~= 'def') then
				local texts = { BAR_LABEL[k] };
				for _, x in ipairs(vals(k) or {}) do texts[#texts + 1] = gcdisplay.ModeText(k, x) end
				map[k] = { kind = kind, col = col, text = (kind == 'def') and BAR_LABEL[k] or gcdisplay.ModeText(k, v), texts = texts, cmd = BAR_CMD[k] };
			end
		end
	end
	-- def: DT, MDT, Aminon as one pill (/def), the first on (+ when more)
	local parts, any = {}, false;
	for _, p in ipairs(DEF_PARTS) do
		local on = tog(p[1]);
		if (on ~= nil) then any = true end
		if (on == true) then parts[#parts + 1] = p end
	end
	if any then
		local first = parts[1];
		map.Def = { kind = (first ~= nil) and 'set' or 'def', col = (first ~= nil) and TOGGLE_COL[first[1]] or nil,
			text = (first ~= nil) and (first[2] .. ((#parts > 1) and '+' or '')) or 'def', texts = { 'def', 'dt+', 'mdt+', 'amin+' }, cmd = 'def' };
	end
	for _, k in ipairs(BAR_TOGGLES) do
		local on = tog(k);
		if (on ~= nil) then map[k] = { kind = (on == true) and 'set' or 'def', col = TOGGLE_COL[k], text = TOGGLE_LABEL[k], cmd = BAR_TCMD[k] } end
	end
	return map;
end

local modelVer, ownLine = -1, nil; -- this box's line: rebuilt when a toggle or cycle changes (gcdisplay's version)
local function own_line()
	if (modelVer ~= version) then
		ownLine = build_line(
			function(k) local c = Cycles[k]; if (c == nil) then return nil end; return c.Array[c.Index], gcdisplay.IsDefault('cycle', k) end,
			function(k) local c = Cycles[k]; return (c ~= nil) and c.Array or nil end,
			function(k) return Toggles[k] end,
			mode_class);
		modelVer = version;
	end
	return ownLine;
end
local function strip(raw) -- a shared value: '~' marks one still at its load default
	raw = tostring(raw or '');
	if (string.sub(raw, 1, 1) == '~') then return string.sub(raw, 2), true end
	return raw, false;
end
local altLines = setmetatable({}, { __mode = 'k' }); -- per gchud row (kept while its content is unchanged)
local function alt_line(row)
	local l = altLines[row];
	if (l == nil) then
		l = build_line(
			function(k) local raw = row.Cycles[k]; if (raw == nil) then return nil end; return strip(raw) end,
			function() return nil end,
			function(k) local raw = row.Toggles[k]; if (raw == nil) then return nil end; return (strip(raw) == 'true') end,
			function() return (row.Cycles.WpnClass ~= nil) and strip(row.Cycles.WpnClass) or nil end); -- shared by that box
		altLines[row] = l;
	end
	return l;
end

local function textw(t)
	local w = imgui.CalcTextSize(t);
	if (type(w) == 'table') then w = w[1] or w.x end
	return tonumber(w) or 0;
end

local colW, colUnit = {}, nil; -- each column's widest text so far (px), until the text size changes
local leadW = {}; -- px from the window's left to the end of each line's name/job part, by line ('' = this box)
local function columns(lines, dl)
	local unit = textw('M');
	if (unit ~= colUnit) then colUnit, colW, leadW = unit, {}, {} end
	local cols = { { id = '|' } };
	for _, id in ipairs(LINE_COLS) do
		if (id == '|') then
			if (cols[#cols].id ~= '|') then cols[#cols + 1] = { id = '|' } end
		else
			local w, any = colW[id] or 0, false;
			for _, l in ipairs(lines) do
				local e = l[id];
				if (e ~= nil) then
					any = true;
					if (e.wu ~= unit) then
						local tw = textw(e.text);
						for _, t in ipairs(e.texts or {}) do tw = math.max(tw, textw(t)) end
						e.w, e.wu = tw, unit;
					end
					w = math.max(w, e.w);
				end
			end
			if any then
				colW[id] = w;
				local lead = (dl == nil) and 0 or (((id == 'wpn') or MODE_PLAIN[id]) and gcdisplay.PILL_PLAIN_LEAD or gcdisplay.PILL_LEAD);
				cols[#cols + 1] = { id = id, lead = lead, pw = math.floor(lead + w + ((dl ~= nil) and gcdisplay.PILL_TAIL or 0) + 0.5) };
			end
		end
	end
	if (cols[#cols].id == '|') then cols[#cols] = nil end
	return cols;
end

local function bar_body(drop, open, up) -- drop: the other boxes (their columns hold even while shut)
	-- Pills, lines and outlines are drawn shapes (Ashita's window draw list); the Windower text box has none, so it shows
	-- a | and the words in their colours.
	local dl = (imgui.GetWindowDrawList ~= nil) and imgui.GetWindowDrawList() or nil;
	local lh = (imgui.GetTextLineHeight ~= nil) and imgui.GetTextLineHeight() or nil;
	if (dl ~= nil) and ((lh == nil) or (imgui.GetColorU32 == nil) or (imgui.GetCursorScreenPos == nil) or (imgui.GetItemRectMax == nil) or (imgui.GetItemRectMin == nil)) then dl = nil end
	local SEG, PGAP = 9, 5; -- px: each side of a divider, between pills
	if (dl == nil) then SEG, PGAP = textw(' '), textw(' ') end
	local wx = xy(imgui.GetWindowPos());
	local first, gapNext, extra = true, nil, 0; -- extra: px held after the last item (a number's spare width)
	local function place(gap)
		if first then first = false else imgui.SameLine(0, (gapNext or gap or 14) + extra) end
		gapNext, extra = nil, 0;
	end
	local function run(name, cmd, ctrl) -- a click: this box runs it, or the other box (gchud)
		local ok, held = pcall(function() return imgui.GetIO().KeyCtrl end);
		cmd = (ok and held and ctrl) or cmd;
		if (name == nil) then AshitaCore:GetChatManager():QueueCommand(-1, '/lac fwd ' .. cmd)
		elseif (hud ~= nil) then hud.Send(name, cmd) end
	end
	local function put(text, col, gap)
		place(gap);
		imgui.PushStyleColor(ImGuiCol_Text, col);
		imgui.Text(text);
		imgui.PopStyleColor();
	end
	local function hold(text, widest) -- keep a number's spot as wide as its widest
		if (dl ~= nil) then extra = math.max(0, textw(widest) - textw(text)) end
	end
	local function lead_end() -- window x just past this line's last item
		imgui.SameLine(0, 0);
		local x = imgui.GetCursorPosX() + extra;
		extra = 0;
		return x;
	end
	-- the job box: two coloured texts, outlined main | sub (Ashita), the outline turning at split
	local function job_box(a, aCol, mid, b, bCol)
		local x, y, split = nil, nil, nil;
		if (dl ~= nil) then x, y = xy(imgui.GetCursorScreenPos()) end
		put(a, aCol);
		if (mid ~= nil) then put(mid, COL_KEY, 0) end
		if (dl ~= nil) then
			local s1, s2 = xy(imgui.GetItemRectMin()), xy(imgui.GetItemRectMax());
			if (s1 ~= nil) and (s2 ~= nil) then split = (mid ~= nil) and ((s1 + s2) / 2) or s2 end
		end
		if (b ~= '') then put(b, bCol, 0) end
		if (x ~= nil) and (y ~= nil) and (split ~= nil) then
			local x2, y2 = xy(imgui.GetItemRectMax());
			if (x2 ~= nil) and (y2 ~= nil) then gcdisplay.SplitOutline(dl, x - 5, y + 1, x2 + 5, y2 - 1, split, aCol, bCol) end -- 1px in from the edge
		end
	end
	local function cells(line, cols, name, id)
		local _, y = nil, nil;
		if (dl ~= nil) then _, y = xy(imgui.GetCursorScreenPos()) end -- this line's top (after an item the cursor moves on)
		for _, c in ipairs(cols) do
			if (c.id == '|') then
				if (dl ~= nil) then
					if (wx ~= nil) and (y ~= nil) then dl:AddLine({ wx + c.x, y + 1 }, { wx + c.x, y + lh - 1 }, imgui.GetColorU32(COL_DIV), 1) end
				else
					imgui.SameLine(c.x);
					imgui.PushStyleColor(ImGuiCol_Text, COL_KEY);
					imgui.Text('|');
					imgui.PopStyleColor();
				end
			else
				local e = line[c.id];
				if (e ~= nil) then
					imgui.SameLine(c.x);
					if (dl ~= nil) then
						local x, y = xy(imgui.GetCursorScreenPos());
						if imgui.Button('##gcl_' .. id .. c.id, { c.pw, lh }) and (e.cmd ~= nil) then run(name, e.cmd, e.ctrl) end
						if (x ~= nil) and (y ~= nil) then
							gcdisplay.Pill(dl, x, y + 1, x + c.pw, y + lh - 1, e.kind, e.col);
							dl:AddText({ x + c.lead, y }, imgui.GetColorU32((e.kind == 'def') and COL_PILL_DIM or COL_PILL_TEXT), e.text);
						end
					else -- Windower: the word in its colour (grey at its default or off)
						imgui.PushStyleColor(ImGuiCol_Text, ((e.kind ~= 'def') and e.col) or ((e.kind == 'def') and COL_PILL_DIM or COL_HEAD));
						if ((e.cmd ~= nil) and (imgui.SmallButton ~= nil)) then
							if imgui.SmallButton(e.text .. '##gcl_' .. id .. c.id) then run(name, e.cmd, e.ctrl) end
						else
							imgui.Text(e.text);
						end
						imgui.PopStyleColor();
					end
				end
			end
		end
	end

	local lines, names = { own_line() }, { '' };
	for _, r in ipairs(drop or {}) do lines[#lines + 1] = alt_line(r); names[#names + 1] = r.Name end
	local cols = columns(lines, dl);
	local lead = 0;
	for _, n in ipairs(names) do lead = math.max(lead, leadW[n] or 0) end
	local x = lead;
	local prevPill = false;
	for _, c in ipairs(cols) do
		if (c.id == '|') then c.x = x + SEG; x = c.x + ((dl == nil) and textw('|') or 0) + SEG; prevPill = false -- Windower: the | is text
		else
			if prevPill then x = x + PGAP end
			c.x, x, prevPill = x, x + c.pw, true;
		end
	end

	local function own()
		first = true;
		if (headText ~= '') then -- set by Update
			job_box(Main .. tostring(MainLV or ''), job_col(Main), '/', Sub .. tostring(SubLV or ''), job_col(Sub));
		else
			put(headText, COL_HEAD);
		end
		if (windower == nil) then -- Windower's player table has no attack/defense (the shim returns 0)
			put('Atk ', COL_KEY, (dl ~= nil) and 13 or 8); put(tostring(Attk), COL_HEAD, 0); hold(tostring(Attk), '0000'); -- labelled, so it doesn't read as HP
			put('Def ', COL_KEY, 8); put(tostring(Def), COL_HEAD, 0); hold(tostring(Def), '0000');
		end
		leadW[''] = lead_end();
		cells(lines[1], cols, nil, 'me');
	end
	local function alt(i)
		local r = drop[i];
		first = true;
		local short = r.Name;
		local mj, sj = string.match(tostring(r.Job or ''), '^(%a+)'), string.match(tostring(r.Job or ''), '/(%a+)');
		local half = math.ceil(#short / 2);
		if (dl ~= nil) then -- first half of the letters in the main job's colour, the rest the sub's, outlined the same
			job_box(string.sub(short, 1, half), job_col(mj), nil, string.sub(short, half + 1), job_col(sj or mj));
		else
			put(short, job_col(mj));
		end
		put(tostring(r.Job or ''), COL_KEY, (dl ~= nil) and 13 or 8);
		leadW[r.Name] = lead_end();
		cells(lines[i + 1], cols, r.Name, r.Name);
	end
	local n = open and #(drop or {}) or 0;
	local function rule() -- a thin line between the bar and the dropped boxes, across the window
		local _, y = xy(imgui.GetCursorScreenPos());
		local ww = xy(imgui.GetWindowSize());
		if (dl ~= nil) and (wx ~= nil) and (y ~= nil) and (ww ~= nil) then dl:AddLine({ wx, y - 2 }, { wx + ww, y - 2 }, imgui.GetColorU32(COL_DIV), 1) end
	end
	if up then -- the drop rises above the bar: the other boxes first, this box's line last (at the bottom)
		for i = 1, n do alt(i) end
		if (n > 0) then rule() end
		own();
	else
		own();
		if (n > 0) then rule() end
		for i = 1, n do alt(i) end
	end
	track_drag((up and (barH ~= nil)) and ((select(2, xy(imgui.GetWindowSize())) or barH) - barH) or 0);
end

-- Hovered with /gchud on: the other boxes drop in (HUDHover = false: always); in the screen's bottom half they rise
-- above the bar instead (HUDGrow 'up' / 'down' / 'auto').
local hoverUntil, closedFrames, dropUp, barW = 0, 0, false, nil;
local function screen_h()
	local ok, h = pcall(function() return imgui.GetMainViewport().Size.y end);
	return ok and tonumber(h) or nil;
end
local function screen_w()
	local ok, w = pcall(function() return imgui.GetMainViewport().Size.x end);
	return ok and tonumber(w) or nil;
end
local function render_bar()
	if (cfg == nil) or (cfg.DisplayBar ~= true) then return end
	local now = os.clock();
	local drop = (hud ~= nil) and hud.DropRows() or nil;
	local open = (drop ~= nil) and (#drop > 0) and ((cfg.HUDHover == false) or (now < hoverUntil));
	local held = imgui.IsMouseDown(0);
	if held then heldSeen = true end
	-- Not dragged yet (DisplayBarX unset, or /gcbar pos auto): centred at the top, or with the drop on (/gchud,
	-- HUDOwners) flush right, its width counting the dropped lines; re-placed when the width changes.
	local tx, ty = tonumber(cfg.DisplayBarX), cfg.DisplayBarY or 0;
	if (tx == nil) then
		local sw = screen_w();
		tx = ((sw ~= nil) and (barW ~= nil)) and math.max(0, math.floor((drop ~= nil) and (sw - barW) or ((sw - barW) / 2))) or 300;
		if (tx ~= placedX) and not held then barPlaced = false end
	end
	if not held then
		local g = string.lower(tostring(cfg.HUDGrow or 'auto'));
		local sh = screen_h();
		dropUp = (g == 'up') or ((g ~= 'down') and (sh ~= nil) and ((ty + (barH or 0) / 2) > sh / 2));
	end
	local up = open and dropUp and (barH ~= nil);
	if up and not held then -- pin this box's line (the bottom) where it is
		imgui.SetNextWindowPos({ tx, ty + barH }, ImGuiCond_Always, { 0, 1 });
		placedX, placedY, barPlaced = tx, ty, false;
	elseif (not barPlaced) and not held then
		imgui.SetNextWindowPos({ tx, ty }, ImGuiCond_Always);
		placedX, placedY, barPlaced = tx, ty, true;
	end
	local flags = bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing,
		ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoResize);
	imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 10, 1 }); -- 1px above and below the text: room for the job outline
	imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 5, 3 }); -- 3px between dropped lines
	imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 12); -- a capsule
	imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1);
	-- pills are borderless buttons under their drawn outline: hovered, a soft fill as round as the pill
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
		ok, err = pcall(bar_body, drop, open, up);
		if (imgui.IsWindowHovered ~= nil) and imgui.IsWindowHovered() then hoverUntil = now + 0.6 end
		closedFrames = open and 0 or (closedFrames + 1);
		local w = xy(imgui.GetWindowSize());
		if (w ~= nil) and (w > 0) then barW = math.floor(w + 0.5) end
		if (closedFrames >= 3) then -- the bar's own height, once the window has fit it
			local _, h = xy(imgui.GetWindowSize());
			if (h ~= nil) and (h > 0) then barH = h end
		end
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
	elseif (arg == 'reset') or ((arg == 'pos') and (string.lower(tostring(args[3])) == 'auto')) then -- back to the auto spot
		cfg.DisplayBarX, cfg.DisplayBarY = nil, 0;
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