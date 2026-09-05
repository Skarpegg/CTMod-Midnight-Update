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
local ROW_WIDTH, ROW_HEIGHT, ICON_SIZE = 180, 22, 20;
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
local COLOR_BUFF = { BUFF_R, BUFF_G, BUFF_B };
local COLOR_DEBUFF = { DEBUFF_R, DEBUFF_G, DEBUFF_B };
local COLOR_ENCHANT = { ENCHANT_R, ENCHANT_G, ENCHANT_B };

-- initializeFrame factory: CustomAuraButton is "bring your own regions" -- we create the display
-- regions and register them; Blizzard's SECURE code fills them from the (secret) aura, so it works in
-- combat. Returns a closure so different aura GROUPS can paint the bright track in their own colour
-- (regular buffs green, weapon enchants purple -- matching the original per-type colours).
local function makeInitButton(r, g, b)
	return function(button)
		if (type(button) ~= "table") then
			return;
		end
		pcall(button.SetSize, button, ROW_WIDTH, ROW_HEIGHT);

		-- Icon (left).
		if (not button.ctIcon) then
			local icon = button:CreateTexture(nil, "ARTWORK");
			icon:SetSize(ICON_SIZE, ICON_SIZE);
			icon:SetPoint("LEFT", button, "LEFT", 0, 0);
			icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
			button.ctIcon = icon;
			pcall(button.SetIcon, button, icon);
		end
		-- Dispel-type border: a border atlas tinted by dispel type (Magic/Curse/Disease/Poison). Blizzard
		-- drives it securely and (with default options) shows it ONLY for auras that HAVE a dispel type,
		-- i.e. typed debuffs -- it stays hidden on buffs. Matches the original coloured debuff border.
		if (not button.ctBorder and button.SetAuraBorder
			and type(Enum) == "table" and type(Enum.CustomAuraButtonDispelTypeTextureStyle) == "table") then
			local bd = button:CreateTexture(nil, "OVERLAY");
			bd:SetAllPoints(button.ctIcon);	-- exactly on the icon; no outset (an outset can nudge row spacing)
			button.ctBorder = bd;
			pcall(button.SetAuraBorder, button, bd, { style = Enum.CustomAuraButtonDispelTypeTextureStyle.Border });
		end
		-- Track: the BRIGHT "full" bar, filling the row right of the icon. This is the remaining-time
		-- look; the dark fill (below) grows over it to mark the used-up part. A no-duration buff keeps a
		-- full bright track (its fill stays at 0), which fixes empty bars on permanent buffs.
		if (not button.ctTrack) then
			local track = button:CreateTexture(nil, "BACKGROUND");
			track:SetTexture(BAR_TEXTURE);
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

		if (button.SetCancelAuraButtons) then
			pcall(button.SetCancelAuraButtons, button, "RightButtonUp");	-- right-click cancel (out of combat)
		end
		if (button.Show) then
			button:Show();
		end
	end
end

-- Fresh option/layout tables per call (don't share one table across containers).
local function groupOpts(r, g, b) return { templateNames = { "CustomAuraButtonTemplate" }, initializeFrame = makeInitButton(r or BUFF_R, g or BUFF_G, b or BUFF_B) }; end
-- No inter-row / inter-group spacing: the bars stack tightly like the original CT_BuffMod list.
local function layout() return { elementWidth = ROW_WIDTH, elementHeight = ROW_HEIGHT, elementSpacing = 0, lineSpacing = 0, groupLineSpacing = 0 }; end

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
			groups[#groups + 1] = { order = i, key = "debuff", filter = "HARMFUL", color = COLOR_DEBUFF };
		elseif (t == FT_WEAPON) then
			groups[#groups + 1] = { order = i, enchant = true, color = COLOR_ENCHANT };
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
		groups[#groups + 1] = { order = allPos, key = "buffs", filter = "HELPFUL", color = COLOR_BUFF };
	else
		if (cancelPos) then
			groups[#groups + 1] = { order = cancelPos, key = "buffcancel", filter = "HELPFUL CANCELABLE", color = COLOR_BUFF };
		end
		if (uncancelPos) then
			groups[#groups + 1] = { order = uncancelPos, key = "buffuncancel", filter = "HELPFUL !CANCELABLE", color = COLOR_BUFF };
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
				split[#split + 1] = { order = g.order, subOrder = ownSub, key = g.key .. "_own", filter = g.filter .. " PLAYER", color = g.color };
				split[#split + 1] = { order = g.order, subOrder = 1 - ownSub, key = g.key .. "_other", filter = g.filter .. " !PLAYER", color = g.color };
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

-- The AuraContainer is a secure/forbidden frame (can't read its own moved position or host a tooltip
-- child), so a normal "anchor" frame is the draggable position store and the container follows it.
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

	local mover = CreateFrame("Button", nil, a);
	mover:SetSize(14, 28);
	mover:SetPoint("RIGHT", a, "LEFT", -2, 0);
	local tex = mover:CreateTexture(nil, "BACKGROUND");
	tex:SetAllPoints();
	tex:SetColorTexture(0.2, 0.6, 1.0, 0.7);
	mover:RegisterForDrag("LeftButton");
	mover:SetScript("OnDragStart", function() a:StartMoving(); end);
	mover:SetScript("OnDragStop", function()
		a:StopMovingOrSizing();
		local point, _, relPoint, x, y = a:GetPoint();
		CT_BuffMod_AuraContainerDB.windowPoints[windowId] = { point, relPoint, x, y };
		local c = containers[windowId];
		if (c) then
			c:ClearAllPoints();
			if (not pcall(c.SetPoint, c, "TOPLEFT", a, "TOPLEFT", 0, 0)) then
				c:SetPoint(point or "TOPRIGHT", UIParent, relPoint or "TOPRIGHT", x or -20, y or -220);
			end
		end
	end);

	anchors[windowId] = a;
	return a;
end

-- Signatures of the window's config. groupSig (unit + which groups) forces a container REBUILD when it
-- changes -- there's no public API to remove/replace an AuraContainer's groups, so we recreate the
-- frame. sortSig (sort method/direction) is applied in place on the existing groups: no rebuild, no leak.
local function groupSig(w)
	local o = w.options or {};
	return table.concat({
		tostring(w.unit),
		tostring(o.sortSeq1), tostring(o.sortSeq2), tostring(o.sortSeq3), tostring(o.sortSeq4), tostring(o.sortSeq5),
		tostring(o.separateOwn),
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

	-- Vertical column, one aura per row, growing downward (see increment 2d/2e).
	if (c.SetFlowLayoutMaximumLineSize) then
		pcall(c.SetFlowLayoutMaximumLineSize, c, ROW_WIDTH);
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
	local enchantLayout = { elementWidth = ROW_WIDTH, elementHeight = ROW_HEIGHT, elementSpacing = 0, lineSpacing = 0 };
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
				pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.MainHand, groupOpts(unpack(g.color)));
				pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.OffHand, groupOpts(unpack(g.color)));
				pcall(c.SetItemEnchantmentLayout, c, enchantLayout);
				addedEnchant = true;
				c.ctEnchantsAdded = true;
			end
		else
			pcall(c.AddAuraGroup, c, g.key, g.filter, groupOpts(unpack(g.color)));
			pcall(c.SetAuraGroupLayout, c, g.key, layout());
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

-- Get (creating once) the container for one window, point it at the window's unit and show it. The
-- container frame is reused (forbidden frames can't be destroyed); its groups are rebuilt only when
-- the window's config signature changes (auto-refresh on reconfigure).
local function buildWindow(w)
	local id = w.windowId;
	local c = containers[id];
	local gsig = groupSig(w);
	local ssig = sortSig(w);
	if ((not c) or c.ctGroupSig ~= gsig) then
		-- (Re)build. Forbidden frames can't be destroyed and there's no public API to clear an
		-- AuraContainer's groups, so on a grouping change we hide the old container and build a fresh
		-- one. The old frame leaks (hidden) -- acceptable for occasional reconfigures; sort-only changes
		-- take the cheap in-place branch below and never leak.
		if (c) then
			c:Hide();
		end
		local a = getAnchor(id);
		c = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate");	-- anonymous: recreatable
		c:SetSize(ROW_WIDTH, ROW_HEIGHT);
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
		-- Hide containers (and drag handles) whose window has been deleted; show handles for live ones.
		for id, c in pairs(containers) do
			if (not present[id]) then
				c:Hide();
				if (anchors[id]) then anchors[id]:Hide(); end
			end
		end
		for id, a in pairs(anchors) do
			if (present[id]) then a:Show(); end
		end
	else
		-- Legacy engine: hide the AuraContainers AND their drag handles, restore the old frames.
		for _, c in pairs(containers) do
			c:Hide();
		end
		for _, a in pairs(anchors) do
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

-- Dynamic units: the container reads its unit on UNIT_AURA, which doesn't reliably fire when you
-- SWITCH target/focus, so it can show stale auras. Force a re-read by briefly clearing the unit.
local du = CreateFrame("Frame");
du:RegisterEvent("PLAYER_TARGET_CHANGED");
du:RegisterEvent("PLAYER_FOCUS_CHANGED");
du:SetScript("OnEvent", function(_, event)
	if (not isActive()) then
		return;
	end
	local unit = (event == "PLAYER_FOCUS_CHANGED") and "focus" or "target";
	for _, c in pairs(containers) do
		if (c.ctUnit == unit) then
			pcall(c.SetUnit, c, "none");
			pcall(c.SetUnit, c, unit);
		end
	end
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
