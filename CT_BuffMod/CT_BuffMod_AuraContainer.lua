------------------------------------------------------------------------------------------------------
-- CT_BuffMod -- AuraContainer display path (WoW Midnight 12.1+)
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

-- initializeFrame: CustomAuraButton is "bring your own regions" -- create the display regions and
-- register them; Blizzard's SECURE code fills them from the (secret) aura, so it works in combat.
local function initButton(button)
	if (type(button) ~= "table") then
		return;
	end
	pcall(button.SetSize, button, 30, 30);
	if (not button.ctIcon) then
		local icon = button:CreateTexture(nil, "ARTWORK");
		icon:SetAllPoints(button);
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
		button.ctIcon = icon;
		pcall(button.SetIcon, button, icon);
	end
	if (not button.ctCooldown) then
		local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
		cd:SetAllPoints(button);
		button.ctCooldown = cd;
		pcall(button.SetDurationCooldown, button, cd);
	end
	if (not button.ctCount) then
		local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
		count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1);
		button.ctCount = count;
		pcall(button.SetApplicationCount, button, count);
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
local function layout() return { elementWidth = 30, elementHeight = 30, elementSpacing = 4 }; end

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
	a:SetSize(320, 34);
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
		c:SetSize(320, 40);
		c:ClearAllPoints();
		if (not pcall(c.SetPoint, c, "TOPLEFT", a, "TOPLEFT", 0, 0)) then
			local pt, _, rp, x, y = a:GetPoint();
			c:SetPoint(pt or "TOPRIGHT", UIParent, rp or "TOPRIGHT", x or -20, y or -220);
		end
		c:AddAuraGroup("buffs", "HELPFUL", groupOpts());
		c:SetAuraGroupLayout("buffs", layout());
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
