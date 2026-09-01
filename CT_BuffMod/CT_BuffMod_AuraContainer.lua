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

local function isActive()
	return CT_BuffMod_AuraContainerDB and CT_BuffMod_AuraContainerDB.useAuraContainer and isCapable();
end

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
local function layout() return { elementWidth = ROW_WIDTH, elementHeight = ROW_HEIGHT, elementSpacing = 0, lineSpacing = 1 }; end

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

-- Get (creating once) the container for one window, then point it at the window's unit and show it.
-- Reused across refreshes/toggles -- never recreated (recreating leaked duplicate frames).
local function buildWindow(w)
	local id = w.windowId;
	local c = containers[id];
	if (not c) then
		local a = getAnchor(id);
		c = CreateFrame("AuraContainer", "CT_BuffMod_AuraContainer" .. id, UIParent, "CustomAuraContainerTemplate");
		c:SetSize(ROW_WIDTH, ROW_HEIGHT);
		c:ClearAllPoints();
		if (not pcall(c.SetPoint, c, "TOPLEFT", a, "TOPLEFT", 0, 0)) then
			local pt, _, rp, x, y = a:GetPoint();
			c:SetPoint(pt or "TOPRIGHT", UIParent, rp or "TOPRIGHT", x or -20, y or -220);
		end
		c:AddAuraGroup("buffs", "HELPFUL", groupOpts());
		c:SetAuraGroupLayout("buffs", layout());
		-- Make it a VERTICAL column like the old CT_BuffMod display: cap the line width so only one
		-- row-wide aura fits per line (default line size is math.huge -> never wraps -> horizontal),
		-- and grow lines DOWNWARD.
		if (c.SetFlowLayoutMaximumLineSize) then
			pcall(c.SetFlowLayoutMaximumLineSize, c, ROW_WIDTH);
		end
		if (type(AnchorUtil) == "table" and type(AnchorUtil.FlowDirection) == "table" and c.SetFlowLayoutGrowthDirection) then
			pcall(c.SetFlowLayoutGrowthDirection, c, AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down);
		end
		if (type(AuraContainerSortMethod) == "table" and type(AuraContainerSortDirection) == "table") then
			pcall(c.SetAuraGroupSortMethod, c, "buffs", AuraContainerSortMethod.Expiration, AuraContainerSortDirection.Normal);
		end
		-- Weapon enchants are the player's own -- only on the player window.
		if (w.unit == "player" and type(AuraContainerItemEnchantmentSlot) == "table") then
			pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.MainHand, groupOpts(ENCHANT_R, ENCHANT_G, ENCHANT_B));
			pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.OffHand, groupOpts(ENCHANT_R, ENCHANT_G, ENCHANT_B));
			pcall(c.SetItemEnchantmentLayout, c, layout());
		end
		containers[id] = c;
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
		for _, w in ipairs(windows) do
			buildWindow(w);
			hideOldFrame(w.auraFrame);
			hideOldFrame(w.altFrame);
		end
	else
		for _, c in pairs(containers) do
			c:Hide();
		end
		for _, w in ipairs(windows) do
			if (w.auraFrame) then w.auraFrame:Show(); end
			if (w.altFrame) then w.altFrame:Show(); end
		end
	end
end

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
ev:SetScript("OnEvent", function()
	-- Delay so CT_BuffMod has created its own windows before we read/hide them.
	if (C_Timer and C_Timer.After) then
		C_Timer.After(3, refresh);
	else
		refresh();
	end
end);

-- Dev toggle: /ctbuffac [on|off]  (default OFF)
SLASH_CTBUFFMODAC1 = "/ctbuffac";
SlashCmdList.CTBUFFMODAC = function(msg)
	CT_BuffMod_AuraContainerDB = CT_BuffMod_AuraContainerDB or {};
	msg = (msg or ""):lower():gsub("%s", "");
	if (msg == "on") then
		CT_BuffMod_AuraContainerDB.useAuraContainer = true;
	elseif (msg == "off") then
		CT_BuffMod_AuraContainerDB.useAuraContainer = false;
	else
		CT_BuffMod_AuraContainerDB.useAuraContainer = not CT_BuffMod_AuraContainerDB.useAuraContainer;
	end
	if (CT_BuffMod_AuraContainerDB.useAuraContainer and not isCapable()) then
		print("|cffff4040CT_BuffMod|r AuraContainer API not available on this client.");
		return;
	end
	print("|cff33ff99CT_BuffMod|r AuraContainer display: " .. (CT_BuffMod_AuraContainerDB.useAuraContainer and "ON  (one row per window; drag the blue handle to move)" or "OFF"));
	refresh();
end
