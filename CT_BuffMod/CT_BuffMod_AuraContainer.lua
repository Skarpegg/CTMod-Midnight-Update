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

-- Old CT_BuffMod layout: a VERTICAL list of rows, each = icon (left) + spell name + time-left (right).
local ROW_WIDTH, ROW_HEIGHT, ICON_SIZE = 180, 22, 20;

-- initializeFrame: CustomAuraButton is "bring your own regions" -- create the display regions and
-- register them; Blizzard's SECURE code fills them from the (secret) aura, so it works in combat.
local function initButton(button)
	if (type(button) ~= "table") then
		return;
	end
	pcall(button.SetSize, button, ROW_WIDTH, ROW_HEIGHT);

	if (not button.ctIcon) then
		local icon = button:CreateTexture(nil, "ARTWORK");
		icon:SetSize(ICON_SIZE, ICON_SIZE);
		icon:SetPoint("LEFT", button, "LEFT", 0, 0);
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
		button.ctIcon = icon;
		pcall(button.SetIcon, button, icon);
	end
	if (not button.ctCooldown) then
		local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
		cd:SetAllPoints(button.ctIcon);
		if (cd.SetHideCountdownNumbers) then
			cd:SetHideCountdownNumbers(true);	-- time is shown as text in the row; keep only the swipe here
		end
		button.ctCooldown = cd;
		pcall(button.SetDurationCooldown, button, cd);
	end
	if (not button.ctCount) then
		local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
		count:SetPoint("BOTTOMRIGHT", button.ctIcon, "BOTTOMRIGHT", 0, 0);
		button.ctCount = count;
		pcall(button.SetApplicationCount, button, count);
	end
	-- Time-remaining text on the right of the row.
	if (not button.ctDuration) then
		local dur = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		dur:SetPoint("RIGHT", button, "RIGHT", -2, 0);
		dur:SetJustifyH("RIGHT");
		button.ctDuration = dur;
		pcall(button.SetDurationText, button, dur);
	end
	-- Spell name label, filling the space between the icon and the time text.
	if (not button.ctName) then
		local name = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		name:SetPoint("LEFT", button.ctIcon, "RIGHT", 4, 0);
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

-- Fresh option/layout tables per call (don't share one table across containers).
local function groupOpts() return { templateNames = { "CustomAuraButtonTemplate" }, initializeFrame = initButton }; end
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
			pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.MainHand, groupOpts());
			pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.OffHand, groupOpts());
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
