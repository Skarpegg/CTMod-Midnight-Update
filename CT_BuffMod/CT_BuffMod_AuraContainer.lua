------------------------------------------------------------------------------------------------------
-- CT_BuffMod -- AuraContainer display path (WoW Midnight 12.1+)
--
-- PROVENANCE: This file is ORIGINAL code written for the CTMod Midnight port -- it is NOT derived from
-- the original CTMod. Where the rest of CT_BuffMod is the work of Cide & TS (original CTMod), adapted
-- for Midnight, this AuraContainer display path was built from scratch against Blizzard's 12.1
-- AuraContainer API. Author: Skarpegg (CTMod Midnight port), AI-assisted (Claude).
--
-- Additive + capability-gated + behind a dev flag (default OFF via /ctbuffac). The existing
-- secure/unsecure buff system is completely unaffected unless CT_BuffMod_AuraContainerDB.useAuraContainer
-- is on AND the client has the AuraContainer API (Mainline 12.1+; Classic/Cata don't load this file).
--
-- When active it builds one Blizzard-secure AuraContainer PER CT_BuffMod window (so buffs display and
-- update IN COMBAT, which the old unsecure path can't) and hides that window's old display -- a true
-- replacement. Each container has a small drag handle; its position persists per window.
--
-- Still a work in progress: filter is HELPFUL for every window (per-window buff/debuff/cancelable/own
-- option mapping is the next step); weapon enchants only on the player window.
------------------------------------------------------------------------------------------------------

-- Capability probe (cached). Mainline 12.1+ only; anywhere without the API this returns false -> inert.
local capable;
local function isCapable()
	if (capable == nil) then
		capable = false;
		if (C_AddOns and C_AddOns.LoadAddOn) then
			pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer");
			local ok, f = pcall(CreateFrame, "AuraContainer", nil, UIParent, "CustomAuraContainerTemplate");
			if (ok and type(f) == "table" and type(f.AddAuraGroup) == "function") then
				capable = true;
			end
		end
	end
	return capable;
end

-- The buff-display engine is the CT_BuffMod option "buffEngine" (1 = AuraContainer, 2 = Legacy header).
-- Default (unset) is AuraContainer on capable clients; Classic/Cata never load this file so they stay
-- on the legacy header. Exposed as CT_BuffMod_AuraContainerActive() for the options panel to branch on.
local function isActive()
	local mod = _G["CT_BuffMod"];
	local eng = mod and mod.getOption and mod:getOption("buffEngine");
	return (eng ~= 2) and isCapable();
end
_G.CT_BuffMod_AuraContainerActive = isActive;

-- Old CT_BuffMod "Style 1" look: a vertical list of rows, each = icon (left) + a colored bar that
-- carries the spell name and time-left, with a bright fill that DEPLETES as the aura runs down.
-- ROW_*/ICON_SIZE are the FALLBACK sizes (used before any window config is known, e.g. the anchor);
-- per-window sizes come from sizesFor() below, mapping CT_BuffMod's buffSize1 (icon) / detailWidth1 (bar).
local ROW_WIDTH, ROW_HEIGHT, ICON_SIZE = 265, 20, 20;
local DEFAULT_ICON, DEFAULT_BARWIDTH = 20, 245;	-- constants.BUFF_SIZE_DEFAULT / DEFAULT_DETAIL_WIDTH
-- Per-window sizes from the window's CT_BuffMod options: buffSize1 = icon size (= row height),
-- detailWidth1 = coloured-bar width. Row width = icon + bar. Returns iconSize, rowHeight, rowWidth.
local function sizesFor(opts)
	opts = opts or {};
	local icon = tonumber(opts.buffSize1) or DEFAULT_ICON;
	local bar = tonumber(opts.detailWidth1) or DEFAULT_BARWIDTH;
	if (icon < 1) then icon = 1; end
	if (bar < 1) then bar = 1; end
	return icon, icon, icon + bar;
end
local BAR_TEXTURE = "Interface\\AddOns\\CT_BuffMod\\Images\\barSmooth";
-- Original CT_BuffMod colours buff bars by duration: AURATYPE_BUFF (timed) = blue {0.1,0.4,0.85},
-- AURATYPE_AURA (no-duration/permanent) = green {0.35,0.8,0.15}. The secure AuraContainer can't tell
-- a button's duration apart in Lua, so we can't split the colour per-aura -- use one default. Match
-- the original's green (the colour seen on the player window).
local BUFF_R, BUFF_G, BUFF_B = 0.35, 0.8, 0.15;			-- original AURATYPE_AURA background colour (green)
local ENCHANT_R, ENCHANT_G, ENCHANT_B = 0.75, 0.25, 1;	-- original AURATYPE_ENCHANT background colour (purple)
local DEBUFF_R, DEBUFF_G, DEBUFF_B = 1, 0, 0;			-- original AURATYPE_DEBUFF background colour (red)

-- CT_BuffMod per-window config we map onto AuraContainer groups (values are CT_BuffMod constants):
-- each window lists an ordered sequence of aura-type "filters" (sortSeq1..5) plus a sort method.
local FT_NONE, FT_DEBUFF, FT_CANCEL, FT_UNCANCEL, FT_ALLBUFF, FT_WEAPON, FT_CONSOL = 1, 2, 3, 4, 5, 6, 7;
local SM_NAME, SM_TIME, SM_INDEX = 1, 2, 3;
local SO_BEFORE, SO_AFTER, SO_WITH = 1, 2, 3;	-- separateOwn: own auras before / after / mixed with others
-- Bar colours come from CT_BuffMod's global colour options so they're user-configurable and stay in
-- sync with the legacy display: buff bar <- bgColorAURA, debuff <- bgColorDEBUFF, weapon <- bgColorITEM.
-- (AuraContainer can't tell timed vs permanent buffs apart, so all buffs use the one AURA colour.)
local COLOR_OPTION  = { buff = "bgColorAURA", debuff = "bgColorDEBUFF", enchant = "bgColorITEM" };
local COLOR_DEFAULT = { buff = { BUFF_R, BUFF_G, BUFF_B }, debuff = { DEBUFF_R, DEBUFF_G, DEBUFF_B }, enchant = { ENCHANT_R, ENCHANT_G, ENCHANT_B } };
local function getColor(key)
	local mod = _G["CT_BuffMod"];
	local c = mod and mod.getOption and mod:getOption(COLOR_OPTION[key]);
	if (type(c) == "table" and c[1]) then
		return c[1], c[2], c[3];
	end
	local d = COLOR_DEFAULT[key] or COLOR_DEFAULT.buff;
	return d[1], d[2], d[3];
end
local allButtons = {};	-- every styled CustomAuraButton, so a colour-option change can recolour in place
local windowFontSize = {};	-- [windowId] = current fontSize option, so a font change can re-font in place

-- Map CT_BuffMod's fontSize option (1=normal, 2=small, 3=large) onto a bar's name/time fontstrings,
-- mirroring the legacy display's font objects (large reuses the same lazily-created custom fonts).
local function applyFonts(button, fontSize)
	local nameFont, timeFont;
	if (fontSize == 2) then
		nameFont, timeFont = "GameFontNormalSmall", "ChatFontSmall";
	elseif (fontSize == 3) then
		if (not CT_BuffMod_GameFontNormalMed2) then
			CreateFont("CT_BuffMod_GameFontNormalMed2");
			local fname, fsize, fargs = GameFontNormal:GetFont();
			CT_BuffMod_GameFontNormalMed2:SetFont(fname, fsize + 2, fargs);
		end
		if (not CT_BuffMod_ChatFontLarge) then
			CreateFont("CT_BuffMod_ChatFontLarge");
			local fname, fsize, fargs = ChatFontNormal:GetFont();
			CT_BuffMod_ChatFontLarge:SetFont(fname, fsize + 2, fargs);
		end
		nameFont, timeFont = "CT_BuffMod_GameFontNormalMed2", "CT_BuffMod_ChatFontLarge";
	else
		nameFont, timeFont = "GameFontNormal", "ChatFontNormal";
	end
	if (button.ctName) then button.ctName:SetFontObject(nameFont); end
	if (button.ctDuration) then button.ctDuration:SetFontObject(timeFont); end
end

-- initializeFrame factory: CustomAuraButton is "bring your own regions" -- we create the display
-- regions and register them; Blizzard's SECURE code fills them from the (secret) aura, so it works in
-- combat. Returns a closure so different aura GROUPS can paint the bright track in their own colour
-- (regular buffs green, weapon enchants purple -- matching the original per-type colours).
local function makeInitButton(colorKey, iconSize, rowW, rowH, windowId)
	iconSize = iconSize or ICON_SIZE;
	rowW = rowW or ROW_WIDTH;
	rowH = rowH or ROW_HEIGHT;
	return function(button)
		if (type(button) ~= "table") then
			return;
		end
		pcall(button.SetSize, button, rowW, rowH);
		button.ctColorKey = colorKey;
		button.ctWindowId = windowId;
		allButtons[button] = true;

		-- Icon (left).
		if (not button.ctIcon) then
			local icon = button:CreateTexture(nil, "ARTWORK");
			icon:SetSize(iconSize, iconSize);
			icon:SetPoint("LEFT", button, "LEFT", 0, 0);
			icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
			button.ctIcon = icon;
			pcall(button.SetIcon, button, icon);
		end
		-- Dispel-type border: a border texture tinted by dispel type (Magic/Curse/Disease/Poison). Blizzard
		-- drives it securely -- SetAuraBorderColor tints our texture and it's shown ONLY for auras that
		-- HAVE a dispel type (typed debuffs), hidden on buffs. We use PreserveAsset with our own explicit
		-- border texture (the classic UI-Debuff-Overlays frame); the built-in Border ATLAS style rendered
		-- nothing when anchored onto the icon.
		if (not button.ctBorder and button.SetAuraBorder
			and type(Enum) == "table" and type(Enum.CustomAuraButtonDispelTypeTextureStyle) == "table") then
			local bd = button:CreateTexture(nil, "OVERLAY");
			bd:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays");
			bd:SetTexCoord(0.296875, 0.5703125, 0, 0.515625);	-- the square border region of this texture
			bd:SetAllPoints(button.ctIcon);
			button.ctBorder = bd;
			local ok = pcall(button.SetAuraBorder, button, bd, { style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset });
			if (CT_BuffMod_AuraContainerDB and CT_BuffMod_AuraContainerDB.debug) then
				print("|cff33ff99CTBuffAC|r SetAuraBorder ok=" .. tostring(ok));
			end
		end
		-- Diagnostic (/ctbuffac bordertest): a plain always-visible red border on EVERY icon, NOT driven
		-- by Blizzard -- proves the border texture renders at the right place/size/layer, without needing
		-- a typed debuff or being out of combat. If this shows but the real one doesn't, it's Blizzard's
		-- dispel driving; if this doesn't show either, it's a texture position/size/layer problem.
		if (CT_BuffMod_AuraContainerDB and CT_BuffMod_AuraContainerDB.borderTest and not button.ctBorderTest) then
			local t = button:CreateTexture(nil, "OVERLAY");
			t:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays");
			t:SetTexCoord(0.296875, 0.5703125, 0, 0.515625);
			t:SetAllPoints(button.ctIcon);
			t:SetVertexColor(1, 0, 0, 1);
			button.ctBorderTest = t;
		end
		-- Track: the BRIGHT "full" bar, filling the row right of the icon. This is the remaining-time
		-- look; the dark fill (below) grows over it to mark the used-up part. A no-duration buff keeps a
		-- full bright track (its fill stays at 0), which fixes empty bars on permanent buffs.
		if (not button.ctTrack) then
			local track = button:CreateTexture(nil, "BACKGROUND");
			track:SetTexture(BAR_TEXTURE);
			local r, g, b = getColor(colorKey);
			track:SetVertexColor(r, g, b, 0.55);
			track:SetPoint("TOPLEFT", button.ctIcon, "TOPRIGHT", 1, 0);
			track:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
			button.ctTrack = track;
		end
		-- Duration bar: a DARK overlay marking the ELAPSED (used-up) part over the bright track. Driven
		-- by Blizzard's secure code (SetDurationBar -> SetTimerDuration on the secret duration), so it
		-- animates in combat too. direction = ElapsedTime GROWS with time, so a permanent buff (no
		-- duration) stays at 0 -> no overlay -> full bright track; RemainingTime would instead sit empty
		-- for permanent auras. Reverse fill so the overlay eats from the RIGHT, leaving the remaining
		-- bright bar (and the name) on the left. Name/time text live on this StatusBar frame so they
		-- draw ABOVE the fill (a child frame would otherwise render over text placed on the button).
		if (not button.ctBar) then
			local bar = CreateFrame("StatusBar", nil, button);
			bar:SetStatusBarTexture(BAR_TEXTURE);
			bar:SetStatusBarColor(0.05, 0.05, 0.08, 0.8);
			bar:SetPoint("TOPLEFT", button.ctIcon, "TOPRIGHT", 1, 0);
			bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
			if (bar.SetReverseFill) then
				bar:SetReverseFill(true);
			end
			button.ctBar = bar;
			local dir = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.ElapsedTime;
			pcall(button.SetDurationBar, button, bar, { direction = dir });
		end

		-- Stack count on the icon.
		if (not button.ctCount) then
			local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
			count:SetPoint("BOTTOMRIGHT", button.ctIcon, "BOTTOMRIGHT", 0, 0);
			button.ctCount = count;
			pcall(button.SetApplicationCount, button, count);
		end
		-- Time-remaining text on the right of the bar (ChatFontNormal / white -- original default font).
		if (not button.ctDuration) then
			local dur = button.ctBar:CreateFontString(nil, "OVERLAY", "ChatFontNormal");
			dur:SetPoint("RIGHT", button.ctBar, "RIGHT", -3, 0);
			dur:SetJustifyH("RIGHT");
			button.ctDuration = dur;
			pcall(button.SetDurationText, button, dur);
		end
		-- Spell name label over the bar (GameFontNormal / gold -- original default font).
		if (not button.ctName) then
			local name = button.ctBar:CreateFontString(nil, "OVERLAY", "GameFontNormal");
			name:SetPoint("LEFT", button.ctBar, "LEFT", 3, 0);
			name:SetPoint("RIGHT", button.ctDuration, "LEFT", -4, 0);
			name:SetJustifyH("LEFT");
			name:SetWordWrap(false);
			button.ctName = name;
			pcall(button.SetSpellName, button, name);
		end
		-- Apply the window's current font size to the name/time text (live lookup, so a button created
		-- after a font change still gets the right size without a container rebuild).
		applyFonts(button, windowFontSize[windowId] or 1);

		if (button.SetCancelAuraButtons) then
			pcall(button.SetCancelAuraButtons, button, "RightButtonUp");	-- right-click cancel (out of combat)
		end
		if (button.Show) then
			button:Show();
		end
	end
end

-- Fresh option/layout tables per call (don't share one table across containers).
local function groupOpts(colorKey, iconSize, rowW, rowH, windowId) return { templateNames = { "CustomAuraButtonTemplate" }, initializeFrame = makeInitButton(colorKey or "buff", iconSize, rowW, rowH, windowId) }; end
-- Re-apply a window's current font size to its existing buttons in place (no rebuild), like recolour.
local function refontWindow(windowId)
	local fontSize = windowFontSize[windowId] or 1;
	for button in pairs(allButtons) do
		if (button.ctWindowId == windowId) then
			applyFonts(button, fontSize);
		end
	end
end
-- No inter-row / inter-group spacing: the bars stack tightly like the original CT_BuffMod list.
local function layout(rowW, rowH) return { elementWidth = rowW or ROW_WIDTH, elementHeight = rowH or ROW_HEIGHT, elementSpacing = 0, lineSpacing = 0, groupLineSpacing = 0 }; end

-- Map a window's CT_BuffMod sortMethod/sortDirection onto the container's secure sort enums.
local function sortFor(opts)
	opts = opts or {};
	if (type(AuraContainerSortMethod) ~= "table" or type(AuraContainerSortDirection) ~= "table") then
		return nil, nil;
	end
	local method = opts.sortMethod or SM_NAME;			-- CT_BuffMod default is Name
	-- Use the PURE ("Only") comparators. The plain Name/Expiration/Default ones are composite (they
	-- sort by from-player, then priority/canApplyAura, THEN the key), which is why buffs came out in a
	-- non-alphabetical order. CT_BuffMod already separates types into their own groups and sorts each
	-- purely by the chosen key, so NameOnly = alphabetical, ExpirationOnly = by time, InstanceID = order.
	local sm;
	if (method == SM_TIME) then
		sm = AuraContainerSortMethod.ExpirationOnly or AuraContainerSortMethod.Expiration;
	elseif (method == SM_INDEX) then
		sm = AuraContainerSortMethod.AuraInstanceIDOnly or AuraContainerSortMethod.Default;
	else
		sm = AuraContainerSortMethod.NameOnly or AuraContainerSortMethod.Name;
	end
	local sdir = (opts.sortDirection and AuraContainerSortDirection.Reverse) or AuraContainerSortDirection.Normal;
	return sm, sdir;
end

-- Build the ordered list of coloured groups for a window from its sortSeq1..5 filter types.
-- Filters: HELPFUL / HARMFUL / CANCELABLE, and negation via a "!" prefix ("!CANCELABLE"), so cancelable
-- and uncancelable buffs each get their own disjoint group. "All buffs" supersedes that split (it would
-- overlap the cancelable groups). All groups are disjoint (HARMFUL vs HELPFUL-CANCELABLE vs
-- HELPFUL-!CANCELABLE vs weapon enchant) so no aura is ever shown twice.
-- Returns specs like { order, key, filter=<str> | enchant=true, color={r,g,b} }.
local function planGroups(opts)
	opts = opts or {};
	local seq = {
		opts.sortSeq1 or FT_DEBUFF,
		opts.sortSeq2 or FT_WEAPON,
		opts.sortSeq3 or FT_CANCEL,
		opts.sortSeq4 or FT_UNCANCEL,
		opts.sortSeq5 or FT_NONE,
	};
	local groups = {};
	local allPos, cancelPos, uncancelPos;
	for i, t in ipairs(seq) do
		if (t == FT_DEBUFF) then
			groups[#groups + 1] = { order = i, key = "debuff", filter = "HARMFUL", colorKey = "debuff" };
		elseif (t == FT_WEAPON) then
			groups[#groups + 1] = { order = i, enchant = true, colorKey = "enchant" };
		elseif (t == FT_ALLBUFF) then
			allPos = allPos or i;
		elseif (t == FT_CANCEL) then
			cancelPos = cancelPos or i;
		elseif (t == FT_UNCANCEL) then
			uncancelPos = uncancelPos or i;
		end
		-- FT_NONE / FT_CONSOLIDATED: nothing (consolidation was removed from the game).
	end
	if (allPos) then
		-- "All buffs" covers everything helpful; it supersedes the cancelable/uncancelable split.
		groups[#groups + 1] = { order = allPos, key = "buffs", filter = "HELPFUL", colorKey = "buff" };
	else
		if (cancelPos) then
			groups[#groups + 1] = { order = cancelPos, key = "buffcancel", filter = "HELPFUL CANCELABLE", colorKey = "buff" };
		end
		if (uncancelPos) then
			groups[#groups + 1] = { order = uncancelPos, key = "buffuncancel", filter = "HELPFUL !CANCELABLE", colorKey = "buff" };
		end
	end
	-- separateOwn: split each aura group into "own" (player-cast) and "others" via the PLAYER filter
	-- token and its negation !PLAYER (disjoint -> no duplicates). BEFORE puts own first, AFTER puts own
	-- last, WITHIN each filter-type block (matches groupByPriority's default Filter > Own ordering). WITH
	-- (the default) leaves each group whole. Weapon enchants are always the player's own -> never split.
	-- Note: CT_BuffMod's "own" is player-ONLY; the PLAYER token also counts the player's pet/vehicle, so
	-- a pet-cast aura lands in "own" here but "others" in the original -- a minor, acceptable difference.
	local sepOwn = opts.separateOwn or SO_WITH;
	if (sepOwn == SO_BEFORE or sepOwn == SO_AFTER) then
		local ownSub = (sepOwn == SO_BEFORE) and 0 or 1;
		local split = {};
		for _, g in ipairs(groups) do
			if (g.enchant) then
				split[#split + 1] = g;
			else
				split[#split + 1] = { order = g.order, subOrder = ownSub, key = g.key .. "_own", filter = g.filter .. " PLAYER", colorKey = g.colorKey };
				split[#split + 1] = { order = g.order, subOrder = 1 - ownSub, key = g.key .. "_other", filter = g.filter .. " !PLAYER", colorKey = g.colorKey };
			end
		end
		groups = split;
	end

	table.sort(groups, function(a, b)
		if (a.order ~= b.order) then
			return a.order < b.order;
		end
		return (a.subOrder or 0) < (b.subOrder or 0);
	end);
	return groups;
end

local containers = {};	-- [windowId] = AuraContainer frame
local anchors = {};		-- [windowId] = normal anchor frame (draggable position store)

-- Title-bar text: default to the unit-type word (Player/Target/Focus/Pet/Vehicle), but show the actual
-- unit NAME when one exists -- so the player's window shows the character's name, and target/focus/pet
-- windows show whoever is currently there (falling back to the word when the unit is empty).
local UNIT_LABEL = { player = "Player", pet = "Pet", target = "Target", focus = "Focus", vehicle = "Vehicle" };
local function titleText(unit)
	unit = unit or "player";
	local name;
	if (UnitExists(unit)) then
		name = UnitName(unit);
	end
	if (name and name ~= "" and name ~= UNKNOWN) then
		return name;
	end
	return UNIT_LABEL[unit] or unit;
end

-- When CT_BuffMod's options panel is open it shows a "Window N" title over each window (current one
-- highlighted), like the legacy display. CT_BuffMod calls CT_BuffMod_AuraContainerSetConfig(open, id)
-- from windowListClass:setCurrentWindow; while open, the title/grip bar shows "Window N" (overriding the
-- per-window title toggle) and is always shown + draggable so you can reposition while configuring.
local configOpen = false;
local configCurrentWindowId = nil;

-- Re-anchor a window's container to its anchor (falling back to the stored screen point if the secure
-- SetPoint-to-anchor is rejected). Used after a drag and after a position reset.
local function reanchorContainer(windowId)
	local a = anchors[windowId];
	local c = containers[windowId];
	if (not a or not c) then
		return;
	end
	c:ClearAllPoints();
	if (not pcall(c.SetPoint, c, "TOPLEFT", a, "TOPLEFT", 0, 0)) then
		local point, _, relPoint, x, y = a:GetPoint();
		c:SetPoint(point or "TOPRIGHT", UIParent, relPoint or "TOPRIGHT", x or -20, y or -220);
	end
end

-- Push a window's current AC-anchor position into the legacy frame's position store, so the window stays
-- in the same screen spot when the user switches back to the Legacy engine (the two engines otherwise keep
-- independent positions). Uses the anchor's TOP-LEFT offset from UIParent; both grow down/right from there.
local function syncLegacyPosition(windowId)
	if (not CT_BuffMod_SyncLegacyPosition or not isActive()) then
		return;	-- only mirror while AuraContainer is the active engine; Legacy owns its own position then
	end
	local a = anchors[windowId];
	if (not a) then
		return;
	end
	local left, top = a:GetLeft(), a:GetTop();
	if (not left or not top) then
		return;
	end
	CT_BuffMod_SyncLegacyPosition(windowId, left - (UIParent:GetLeft() or 0), top - (UIParent:GetTop() or 0));
end

-- The AuraContainer is a secure/forbidden frame (can't attach drag handlers, read its own moved position
-- or dynamic height, or host a tooltip child), so a normal "anchor" frame is the draggable position store
-- and the container follows it. We can't make the whole (secure, variable-height) buff list draggable like
-- the legacy frame, so the drag affordance is a grip BAR spanning the window width just above the top row,
-- shown only when the window is unlocked (lockWindow). buildWindow/applyAnchorOpts sizes the bar to the
-- window width and applies lock (grip shown) + clamp (SetClampedToScreen).
local function getAnchor(windowId)
	if (anchors[windowId]) then
		return anchors[windowId];
	end
	CT_BuffMod_AuraContainerDB = CT_BuffMod_AuraContainerDB or {};
	CT_BuffMod_AuraContainerDB.windowPoints = CT_BuffMod_AuraContainerDB.windowPoints or {};

	local a = CreateFrame("Frame", "CT_BuffMod_AuraAnchor" .. windowId, UIParent);
	a:SetSize(ROW_WIDTH, ROW_HEIGHT);
	a:SetMovable(true);
	a:SetClampedToScreen(true);
	local p = CT_BuffMod_AuraContainerDB.windowPoints[windowId];
	a:ClearAllPoints();
	if (type(p) == "table") then
		a:SetPoint(p[1] or "TOPRIGHT", UIParent, p[2] or "TOPRIGHT", p[3] or -20, p[4] or -220);
	else
		a:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -220 - (windowId - 1) * 42);	-- staggered default
	end

	-- Grip bar: a "title bar" the width of the window, sitting just above the top row. Left-drag to move.
	local grip = CreateFrame("Button", nil, a);
	grip:SetHeight(11);
	grip:SetPoint("BOTTOMLEFT", a, "TOPLEFT", 0, 1);
	grip:SetPoint("BOTTOMRIGHT", a, "TOPRIGHT", 0, 1);
	local tex = grip:CreateTexture(nil, "BACKGROUND");
	tex:SetAllPoints();
	tex:SetColorTexture(0.2, 0.6, 1.0, 0.55);
	local label = grip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	label:SetPoint("CENTER");
	label:SetTextColor(1, 1, 1, 0.9);
	grip.ctLabel = label;
	grip:SetScript("OnEnter", function(self)
		-- Draggable = options panel open, or the window is unlocked. When it's neither (a locked title bar
		-- in normal play), don't highlight or show a tooltip -- it would be distracting under the cursor.
		if (not (configOpen or not a.ctLocked)) then
			return;
		end
		tex:SetColorTexture(0.3, 0.7, 1.0, 0.85);
		GameTooltip:SetOwner(self, "ANCHOR_TOP");
		GameTooltip:SetText("Drag to move this buff window");
		GameTooltip:AddLine("Lock it in CT > BuffMod > (window) > Lock window position.", 1, 1, 1, true);
		GameTooltip:Show();
	end);
	grip:SetScript("OnLeave", function() tex:SetColorTexture(0.2, 0.6, 1.0, 0.55); GameTooltip:Hide(); end);
	grip:RegisterForDrag("LeftButton");
	grip:SetScript("OnDragStart", function()
		if (configOpen or not a.ctLocked) then	-- locked windows move only while configuring
			a:StartMoving();
			a.ctMoving = true;
		end
	end);
	grip:SetScript("OnDragStop", function()
		if (not a.ctMoving) then
			return;
		end
		a.ctMoving = false;
		a:StopMovingOrSizing();
		local point, _, relPoint, x, y = a:GetPoint();
		CT_BuffMod_AuraContainerDB.windowPoints[windowId] = { point, relPoint, x, y };
		reanchorContainer(windowId);
		syncLegacyPosition(windowId);	-- keep the Legacy frame at the same spot
	end);
	a.ctGrip = grip;
	a.ctWindowId = windowId;

	anchors[windowId] = a;
	return a;
end

-- Refresh the grip/title bar's text and shown state from the anchor's stored options. The bar shows
-- when the window has a title (acShowTitle) OR is unlocked (then it's the drag grip). With a title it
-- shows the unit/character name; as a bare drag grip it shows a subtle handle mark.
local function updateAnchorTitle(a)
	if (not a or not a.ctGrip) then
		return;
	end
	local grip = a.ctGrip;
	local lbl = grip.ctLabel;
	if (configOpen) then
		-- Options panel open: show "Window N" (current highlighted white, others gold), always visible.
		if (lbl) then
			lbl:SetText("Window " .. tostring(a.ctWindowId or "?"));
			if (a.ctWindowId == configCurrentWindowId) then
				lbl:SetTextColor(1, 1, 1);
			else
				lbl:SetTextColor(1, 0.82, 0);
			end
		end
		grip:SetShown(true);
	else
		if (lbl) then
			lbl:SetText(a.ctShowTitle and titleText(a.ctTitleUnit) or "::::::");
			lbl:SetTextColor(1, 1, 1, 0.9);
		end
		grip:SetShown(a.ctShowTitle or not a.ctLocked);
	end
end

-- Apply the window's position options to its anchor: size the grip to the window width, honour clamp
-- (SetClampedToScreen), lock and the title-bar toggle. Called from buildWindow.
local function applyAnchorOpts(a, w)
	if (not a) then
		return;
	end
	local _, _, rowW = sizesFor(w.options);
	a:SetWidth(rowW);
	a:SetClampedToScreen(w.clampWindow ~= false);
	a.ctTitleUnit = w.unit or "player";
	a.ctShowTitle = not not w.acShowTitle;
	a.ctLocked = not not w.lockWindow;
	updateAnchorTitle(a);
end

-- Refresh every live anchor's title text (used when the target/focus/pet changes so name titles track).
local function refreshTitles()
	for _, a in pairs(anchors) do
		updateAnchorTitle(a);
	end
end

-- Called by CT_BuffMod when its options panel opens (open=true, current window id), switches window, or
-- closes (open=false). Drives the "Window N" title overlay + makes every window draggable while open.
_G.CT_BuffMod_AuraContainerSetConfig = function(open, currentWindowId)
	configOpen = not not open;
	configCurrentWindowId = currentWindowId;
	refreshTitles();
end

-- Reset a window's AuraContainer position to the CENTRE of the screen (matching the options help text
-- and the legacy frame's reset). Stores the centred point so it persists across reloads, then re-anchors.
local function resetPosition(windowId)
	CT_BuffMod_AuraContainerDB = CT_BuffMod_AuraContainerDB or {};
	CT_BuffMod_AuraContainerDB.windowPoints = CT_BuffMod_AuraContainerDB.windowPoints or {};
	CT_BuffMod_AuraContainerDB.windowPoints[windowId] = { "CENTER", "CENTER", 0, 0 };
	local a = anchors[windowId];
	if (a) then
		a:ClearAllPoints();
		a:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		reanchorContainer(windowId);
		syncLegacyPosition(windowId);	-- keep the Legacy frame at the same spot as the reset AC window
	end
end
_G.CT_BuffMod_AuraContainerResetPosition = resetPosition;

-- Signatures of the window's config. groupSig (unit + which groups + sizes) forces a container REBUILD
-- when it changes -- there's no public API to remove/replace an AuraContainer's groups OR to resize its
-- element layout in place, so we recreate the frame. sortSig (sort method/direction) is applied in place
-- on the existing groups: no rebuild, no leak.
local function groupSig(w)
	local o = w.options or {};
	return table.concat({
		tostring(w.unit),
		tostring(o.sortSeq1), tostring(o.sortSeq2), tostring(o.sortSeq3), tostring(o.sortSeq4), tostring(o.sortSeq5),
		tostring(o.separateOwn),
		tostring(o.buffSize1), tostring(o.detailWidth1),
	}, ":");
end
local function sortSig(w)
	local o = w.options or {};
	return tostring(o.sortMethod) .. ":" .. tostring(o.sortDirection);
end
-- Re-apply the sort method/direction to a container's existing aura groups (cheap; no rebuild).
local function applySort(c, w)
	local sm, sdir = sortFor(w.options);
	if (not sm) then
		return;
	end
	for _, g in ipairs(planGroups(w.options)) do
		if (not g.enchant) then
			pcall(c.SetAuraGroupSortMethod, c, g.key, sm, sdir);
		end
	end
end

-- (Re)build a container's groups + enchants from the window's current config. Clears existing groups
-- first, so it is safe to call again when a window is reconfigured. Must not run in combat (AddAuraGroup
-- is protected) -- callers guard on InCombatLockdown.
local function applyGroups(c, w)
	-- Called on a FRESH container (initial build, or a recreate on a grouping change). We do NOT clear
	-- anything here: there is no public API to remove an AuraContainer's aura groups (ClearAuraGroups is
	-- a private mixin, not on the frame -> silently fails), and ClearItemEnchantments cancels the
	-- enchant's pending async item-data request (Lua error in AsyncCallbackSystem). So a grouping change
	-- recreates the container (buildWindow) rather than mutating this one's groups.

	-- Per-window sizes (icon = buffSize1, bar = detailWidth1; row width = icon + bar).
	local iconSize, rowH, rowW = sizesFor(w.options);
	local wid = w.windowId;

	-- Vertical column, one aura per row, growing downward (see increment 2d/2e).
	if (c.SetFlowLayoutMaximumLineSize) then
		pcall(c.SetFlowLayoutMaximumLineSize, c, rowW);
	end
	if (type(AnchorUtil) == "table" and type(AnchorUtil.FlowDirection) == "table" and c.SetFlowLayoutGrowthDirection) then
		pcall(c.SetFlowLayoutGrowthDirection, c, AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down);
	end

	-- Map this window's CT_BuffMod options onto ordered, coloured groups (debuffs red, buffs green,
	-- weapon enchants purple) with the window's sort method, in the configured sequence order.
	local sm, sdir = sortFor(w.options);
	local plan = planGroups(w.options);
	local dbg = CT_BuffMod_AuraContainerDB and CT_BuffMod_AuraContainerDB.debug;
	if (dbg) then
		local o = w.options or {};
		local r = w.resolved or {};
		print(("|cff33ff99CTBuffAC|r win=%s unit=%s | RAW sortMethod=%s seq=%s/%s/%s/%s/%s")
			:format(tostring(w.windowId), tostring(w.unit), tostring(o.sortMethod),
				tostring(o.sortSeq1), tostring(o.sortSeq2), tostring(o.sortSeq3), tostring(o.sortSeq4), tostring(o.sortSeq5)));
		print(("   RESOLVED sortMethod=%s dir=%s seq=%s/%s/%s/%s/%s grpPri=%s sepOwn=%s")
			:format(tostring(r.sortMethod), tostring(r.sortDirection),
				tostring(r.sortSeq1), tostring(r.sortSeq2), tostring(r.sortSeq3), tostring(r.sortSeq4), tostring(r.sortSeq5),
				tostring(r.groupByPriority), tostring(r.separateOwn)));
	end

	-- Weapon-enchant placement: the container can only put enchants BEFORE or AFTER all aura groups
	-- (not at an arbitrary sortSeq slot). Put them after the aura groups if any group is configured
	-- before the weapon, else before -- the closest we can get to the configured position.
	local enchantLayout = { elementWidth = rowW, elementHeight = rowH, elementSpacing = 0, lineSpacing = 0 };
	if (type(CustomAuraContainerItemEnchantmentPlacement) == "table") then
		local weaponOrder;
		for _, g in ipairs(plan) do
			if (g.enchant) then weaponOrder = g.order; end
		end
		if (weaponOrder) then
			local anyBefore = false;
			for _, g in ipairs(plan) do
				if ((not g.enchant) and g.order < weaponOrder) then anyBefore = true; end
			end
			enchantLayout.placement = anyBefore and CustomAuraContainerItemEnchantmentPlacement.AfterAuraGroups
				or CustomAuraContainerItemEnchantmentPlacement.BeforeAuraGroups;
		end
	end

	-- Enchants are added once and kept across rebuilds (see the ClearItemEnchantments note above).
	local addedEnchant = c.ctEnchantsAdded;
	for _, g in ipairs(plan) do
		if (g.enchant) then
			-- Temporary weapon enchants are the player's own -- only meaningful on the player window.
			if (w.unit == "player" and type(AuraContainerItemEnchantmentSlot) == "table" and not addedEnchant) then
				pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.MainHand, groupOpts(g.colorKey, iconSize, rowW, rowH, wid));
				pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.OffHand, groupOpts(g.colorKey, iconSize, rowW, rowH, wid));
				pcall(c.SetItemEnchantmentLayout, c, enchantLayout);
				addedEnchant = true;
				c.ctEnchantsAdded = true;
			end
		else
			pcall(c.AddAuraGroup, c, g.key, g.filter, groupOpts(g.colorKey, iconSize, rowW, rowH, wid));
			pcall(c.SetAuraGroupLayout, c, g.key, layout(rowW, rowH));
			local sortOk = false;
			if (sm) then
				sortOk = pcall(c.SetAuraGroupSortMethod, c, g.key, sm, sdir);
			end
			if (dbg) then
				print(("  group %s filter=%s sortApplied=%s"):format(tostring(g.key), tostring(g.filter), tostring(sortOk)));
			end
		end
	end
end

-- Visibility: mirror the legacy frame's "visibility" state driver onto a frame. A window set to
-- Basic/Advanced visibility yields a macro-condition string (e.g. "[combat]hide; show"); "always show"
-- yields nil. RegisterStateDriver then shows/hides the frame on combat/vehicle/etc. state changes
-- (secure, works in combat once registered). We (un)register only from buildWindow, which runs out of
-- combat. A "show"/empty condition means always-visible -> no driver. Applied to BOTH the container and
-- its anchor (so the drag grip hides along with the buffs when a visibility condition hides the window).
local function clearVisibility(f)
	if (f.ctVisDriven) then
		pcall(UnregisterStateDriver, f, "visibility");
		f.ctVisDriven = nil;
	end
end
local function applyVisibility(f, cond)
	if (type(cond) == "string" and cond ~= "" and cond ~= "show") then
		if (pcall(RegisterStateDriver, f, "visibility", cond)) then
			f.ctVisDriven = true;
		end
	else
		clearVisibility(f);
		f:Show();
	end
end

-- Get (creating once) the container for one window, point it at the window's unit and show it. The
-- container frame is reused (forbidden frames can't be destroyed); its groups are rebuilt only when
-- the window's config signature changes (auto-refresh on reconfigure).
local function buildWindow(w)
	local id = w.windowId;
	-- Disabled window: show nothing. Drop its buttons (SetUnit "none") and hide the container + drag
	-- handle. On re-enable, buildWindow runs normally again and re-points the container at its unit.
	if (w.disableWindow) then
		local c = containers[id];
		if (c) then
			clearVisibility(c);
			pcall(c.SetUnit, c, "none");
			c:Hide();
		end
		if (anchors[id]) then clearVisibility(anchors[id]); anchors[id]:Hide(); end
		return;
	end
	-- Live font-size source for this window (read by the init closure for new buttons, and by
	-- refontWindow for existing ones). Set before any (re)build so freshly-created buttons pick it up.
	windowFontSize[id] = tonumber(w.options and w.options.fontSize) or 1;
	local c = containers[id];
	local gsig = groupSig(w);
	local ssig = sortSig(w);
	if ((not c) or c.ctGroupSig ~= gsig) then
		-- (Re)build. Forbidden frames can't be destroyed and there's no public API to clear an
		-- AuraContainer's groups, so on a grouping/size change we retire the old container and build a
		-- fresh one. Hiding the frame alone does NOT remove its (Blizzard-managed) aura buttons -- they
		-- linger and overlap the new window -- so first drop them by pointing the old container at no
		-- unit ("none", the same clear the target-switch re-read uses), then unhook and hide it.
		if (c) then
			clearVisibility(c);
			pcall(c.SetUnit, c, "none");
			c:Hide();
		end
		local a = getAnchor(id);
		c = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate");	-- anonymous: recreatable
		local _, csrowH, csrowW = sizesFor(w.options);
		c:SetSize(csrowW, csrowH);
		c:ClearAllPoints();
		if (not pcall(c.SetPoint, c, "TOPLEFT", a, "TOPLEFT", 0, 0)) then
			local pt, _, rp, x, y = a:GetPoint();
			c:SetPoint(pt or "TOPRIGHT", UIParent, rp or "TOPRIGHT", x or -20, y or -220);
		end
		containers[id] = c;
		applyGroups(c, w);
		c.ctGroupSig = gsig;
		c.ctSortSig = ssig;
	elseif (c.ctSortSig ~= ssig) then
		applySort(c, w);
		c.ctSortSig = ssig;
	end
	c.ctUnit = w.unit or "player";
	c:SetUnit(c.ctUnit);
	c:Show();
	-- Re-apply the font size to this window's existing buttons in place (no rebuild -- a font change is
	-- like a colour change; putting it in groupSig would recreate the container and leave the old,
	-- un-destroyable one visible, superimposing the old text under the new).
	refontWindow(id);
	-- Apply the window's visibility rule (state driver, or always-show). Done every build so a
	-- visibility-only change (not in groupSig/sortSig) still takes effect. Applied to the container AND
	-- the anchor, so the drag grip hides along with the buffs when a visibility condition hides the window.
	applyVisibility(c, w.visCondition);
	-- Apply position options (grip width, clamp, lock) to the anchor -- also every build, so a
	-- lock/clamp change takes effect without a grouping/sort change.
	local a = anchors[id];
	applyAnchorOpts(a, w);
	if (a) then
		applyVisibility(a, w.visCondition);
	end
end

-- Hide (and keep hidden while active) an old CT_BuffMod display frame.
local function hideOldFrame(f)
	if (not f) then
		return;
	end
	f:Hide();
	if (not f.ctacHooked) then
		f.ctacHooked = true;
		f:HookScript("OnShow", function(self)
			if (isActive()) then
				self:Hide();
			end
		end);
	end
end

local function getWindows()
	local mod = _G["CT_BuffMod"];
	if (not mod or not mod.getAuraContainerWindows) then
		return {};
	end
	local ok, windows = pcall(mod.getAuraContainerWindows, mod);
	if (ok and type(windows) == "table") then
		return windows;
	end
	return {};
end

local function refresh()
	local windows = getWindows();
	if (isActive()) then
		local present = {};
		for _, w in ipairs(windows) do
			present[w.windowId] = true;
			buildWindow(w);
			hideOldFrame(w.auraFrame);
			hideOldFrame(w.altFrame);
		end
		-- Hide containers (and drag handles) whose window has been deleted. Clear any visibility state
		-- driver first, or it could re-show the frame on a later state change. Live windows' anchors are
		-- shown/driven by buildWindow's applyVisibility(a) above, so no explicit re-show loop is needed
		-- here (and forcing a:Show() would fight a vehicle/combat driver that wants the anchor hidden).
		for id, c in pairs(containers) do
			if (not present[id]) then
				clearVisibility(c);
				c:Hide();
				if (anchors[id]) then clearVisibility(anchors[id]); anchors[id]:Hide(); end
			end
		end
	else
		-- Legacy engine: hide the AuraContainers AND their drag handles, restore the old frames. Clear the
		-- visibility drivers too, so a combat/vehicle state change can't re-show a container in Legacy mode.
		for _, c in pairs(containers) do
			clearVisibility(c);
			c:Hide();
		end
		for _, a in pairs(anchors) do
			clearVisibility(a);
			a:Hide();
		end
		for _, w in ipairs(windows) do
			if (w.auraFrame) then w.auraFrame:Show(); end
			if (w.altFrame) then w.altFrame:Show(); end
		end
	end
end

-- Auto-refresh: CT_BuffMod calls CT_BuffMod_AuraContainerNotify() when a window is added/removed or a
-- window's options are (re)applied. Debounce (a burst of option applies collapses to one refresh) and
-- defer while in combat (building groups and SetUnit are protected) -- PLAYER_REGEN_ENABLED flushes it.
local pendingRefresh = false;
local deferredForCombat = false;
local loginDone = false;	-- ignore notifies until the initial login refresh has run (config still settling)
local function scheduleRefresh()
	if (not loginDone or pendingRefresh) then
		return;
	end
	pendingRefresh = true;
	if (C_Timer and C_Timer.After) then
		C_Timer.After(0.15, function()
			pendingRefresh = false;
			if (InCombatLockdown()) then
				deferredForCombat = true;
				return;
			end
			refresh();
		end);
	else
		pendingRefresh = false;
		refresh();
	end
end
_G.CT_BuffMod_AuraContainerNotify = scheduleRefresh;
_G.CT_BuffMod_AuraContainerRefresh = refresh;	-- immediate refresh (used when the engine option changes)

-- Live recolour: repaint every existing button's bright track from the current colour options, in
-- place (no rebuild). Called when the user changes a bgColor* swatch so bars recolour immediately.
local function recolor()
	for button in pairs(allButtons) do
		if (button.ctTrack and button.ctColorKey) then
			local r, g, b = getColor(button.ctColorKey);
			button.ctTrack:SetVertexColor(r, g, b, 0.55);
		end
	end
end
_G.CT_BuffMod_AuraContainerRecolor = recolor;

-- Dynamic units: the container reads its unit on UNIT_AURA, which doesn't reliably fire when you
-- SWITCH target/focus, so it can show stale auras. Force a re-read by briefly clearing the unit.
local du = CreateFrame("Frame");
du:RegisterEvent("PLAYER_TARGET_CHANGED");
du:RegisterEvent("PLAYER_FOCUS_CHANGED");
du:RegisterEvent("UNIT_PET");
du:SetScript("OnEvent", function(_, event)
	if (not isActive()) then
		return;
	end
	-- Re-read the container's auras for the unit that changed (UNIT_PET carries no target/focus change).
	if (event ~= "UNIT_PET") then
		local unit = (event == "PLAYER_FOCUS_CHANGED") and "focus" or "target";
		for _, c in pairs(containers) do
			if (c.ctUnit == unit) then
				pcall(c.SetUnit, c, "none");
				pcall(c.SetUnit, c, unit);
			end
		end
	end
	-- Name titles (target/focus/pet) track whoever is now there.
	refreshTitles();
end);

local ev = CreateFrame("Frame");
ev:RegisterEvent("PLAYER_LOGIN");
ev:RegisterEvent("PLAYER_REGEN_ENABLED");
ev:SetScript("OnEvent", function(_, event)
	if (event == "PLAYER_REGEN_ENABLED") then
		-- Combat ended: run any refresh that was deferred because groups/SetUnit are protected in combat.
		if (deferredForCombat) then
			deferredForCombat = false;
			refresh();
		end
		return;
	end
	-- PLAYER_LOGIN: delay so CT_BuffMod has created its own windows before we read/hide them, then
	-- enable auto-refresh (notifies before this are ignored -- config is still settling at startup).
	if (C_Timer and C_Timer.After) then
		C_Timer.After(3, function() loginDone = true; refresh(); end);
	else
		loginDone = true;
		refresh();
	end
end);

-- /ctbuffac [on|off|debug] -- on/off pick the buff engine (also selectable in the options panel);
-- debug toggles the per-window group dump. The engine now lives in the "buffEngine" CT_BuffMod option.
SLASH_CTBUFFMODAC1 = "/ctbuffac";
SlashCmdList.CTBUFFMODAC = function(msg)
	CT_BuffMod_AuraContainerDB = CT_BuffMod_AuraContainerDB or {};
	msg = (msg or ""):lower():gsub("%s", "");
	if (msg == "debug") then
		CT_BuffMod_AuraContainerDB.debug = not CT_BuffMod_AuraContainerDB.debug;
		print("|cff33ff99CT_BuffMod|r AuraContainer debug: " .. (CT_BuffMod_AuraContainerDB.debug and "ON (rebuild with /ctbuffac off then on)" or "OFF"));
		return;
	elseif (msg == "bordertest") then
		CT_BuffMod_AuraContainerDB.borderTest = not CT_BuffMod_AuraContainerDB.borderTest;
		print("|cff33ff99CT_BuffMod|r border test overlay: " .. (CT_BuffMod_AuraContainerDB.borderTest and "ON -- a red border on every icon after /reload" or "OFF -- /reload to remove"));
		return;
	elseif (msg:sub(1, 6) == "border") then
		-- /ctbuffac border [unit] -- list a unit's debuffs and their dispel types so you can tell which
		-- SHOULD show a coloured border (only typed debuffs do). Readable out of combat only (secret in
		-- combat). Default unit is target.
		local unit = msg:sub(7);
		if (unit == "") then unit = "target"; end
		print(("|cff33ff99CTBuffAC|r HARMFUL auras on '%s' (border shows only for typed):"):format(unit));
		local n = 0;
		for i = 1, 40 do
			local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL");
			if (not ok) then print("  (auras unreadable -- in combat?)"); break; end
			if (not aura) then break; end
			n = n + 1;
			local dispel = aura.dispelName;
			print(("  %s -- dispel=%s -> %s"):format(tostring(aura.name), tostring(dispel),
				(dispel and "|cff40ff40coloured border expected|r" or "no border (untyped)")));
		end
		if (n == 0) then print("  (none)"); end
		return;
	end
	local mod = _G["CT_BuffMod"];
	if (not mod or not mod.setOption) then
		return;
	end
	local eng = mod:getOption("buffEngine");
	local newEng;
	if (msg == "on") then
		newEng = 1;
	elseif (msg == "off") then
		newEng = 2;
	else
		newEng = (eng == 2) and 1 or 2;	-- toggle (default is AuraContainer)
	end
	if (newEng == 1 and not isCapable()) then
		print("|cffff4040CT_BuffMod|r AuraContainer API not available on this client.");
		return;
	end
	mod:setOption("buffEngine", newEng);	-- triggers the option update (refresh + options-panel rebuild)
	print("|cff33ff99CT_BuffMod|r buff engine: " .. ((newEng == 1) and "AuraContainer" or "Legacy header"));
end
