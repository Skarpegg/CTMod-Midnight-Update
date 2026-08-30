------------------------------------------------------------------------------------------------------
-- CT_BuffMod -- AuraContainer display path (WoW Midnight 12.1+)
--
-- Additive + capability-gated + behind a dev flag (default OFF): the existing secure/unsecure buff
-- system is completely unaffected unless CT_BuffMod_AuraContainerDB.useAuraContainer is turned on (/ctbuffac)
-- AND the client actually has the AuraContainer API (Mainline 12.1+; Classic/Cata don't load this file).
--
-- Why: Midnight makes auras "secret", so the old unsecure path freezes in combat. Blizzard's secure
-- AuraContainer reads the aura data itself and drives our buttons -> buffs display and update IN COMBAT.
--
-- Increment 1 (this file): a self-contained, styled, cancelable player-buff container built from the
-- proven recipe. It does NOT yet touch CT_BuffMod's window/frameClass machinery -- that integration
-- (replacing a window's display, wiring per-window filter/sort/style options) is the next step.
------------------------------------------------------------------------------------------------------

-- Capability probe (cached). Mainline 12.1+ only; anywhere without the API this returns false and the
-- whole file becomes inert.
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

local container;

-- initializeFrame: CustomAuraButton is "bring your own regions" -- create the display regions and
-- register them; Blizzard's SECURE code then fills them from the (secret) aura, so it works in combat.
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
	-- Right-click cancels (out of combat; blocked in combat -- parity with the old system, no regression).
	if (button.SetCancelAuraButtons) then
		pcall(button.SetCancelAuraButtons, button, "RightButtonUp");
	end

	if (button.Show) then
		button:Show();
	end
end

local GROUP_OPTS = { templateNames = { "CustomAuraButtonTemplate" }, initializeFrame = initButton };
local LAYOUT = { elementWidth = 30, elementHeight = 30, elementSpacing = 4 };

-- The AuraContainer is a secure/forbidden frame: GetPoint() on it after StartMoving returns nothing,
-- and it controls its own anchoring. So we use a normal "anchor" frame as the draggable position
-- store (reliable GetPoint) and anchor the container to it. The drag handle lives on the anchor.
local anchor;
local function getAnchor()
	if (anchor) then
		return anchor;
	end
	CT_BuffMod_AuraContainerDB = CT_BuffMod_AuraContainerDB or {};
	anchor = CreateFrame("Frame", "CT_BuffMod_AuraAnchor", UIParent);
	anchor:SetSize(320, 34);
	anchor:SetMovable(true);
	anchor:SetClampedToScreen(true);

	local p = CT_BuffMod_AuraContainerDB.auraContainerPoint;
	anchor:ClearAllPoints();
	if (type(p) == "table") then
		anchor:SetPoint(p[1] or "TOPRIGHT", UIParent, p[2] or "TOPRIGHT", p[3] or -20, p[4] or -220);
	else
		anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -220);
	end

	local mover = CreateFrame("Button", nil, anchor);
	mover:SetSize(14, 28);
	mover:SetPoint("RIGHT", anchor, "LEFT", -2, 0);
	local tex = mover:CreateTexture(nil, "BACKGROUND");
	tex:SetAllPoints();
	tex:SetColorTexture(0.2, 0.6, 1.0, 0.7);
	mover:RegisterForDrag("LeftButton");
	mover:SetScript("OnDragStart", function() anchor:StartMoving(); end);
	mover:SetScript("OnDragStop", function()
		anchor:StopMovingOrSizing();
		local point, _, relPoint, x, y = anchor:GetPoint();
		CT_BuffMod_AuraContainerDB.auraContainerPoint = { point, relPoint, x, y };
		-- Reposition the live container to match (in case it isn't live-anchored to us).
		if (container) then
			container:ClearAllPoints();
			if (not pcall(container.SetPoint, container, "TOPLEFT", anchor, "TOPLEFT", 0, 0)) then
				container:SetPoint(point or "TOPRIGHT", UIParent, relPoint or "TOPRIGHT", x or -20, y or -220);
			end
		end
	end);
	return anchor;
end

local function build()
	if (container) then
		container:Hide();
		container = nil;
	end

	local c = CreateFrame("AuraContainer", "CT_BuffMod_AuraContainer_Player", UIParent, "CustomAuraContainerTemplate");

	-- Position: follow the draggable anchor frame (the container can't report its own moved position).
	local a = getAnchor();
	c:ClearAllPoints();
	local okp = pcall(c.SetPoint, c, "TOPLEFT", a, "TOPLEFT", 0, 0);
	if (not okp) then
		-- If anchoring the forbidden container to our frame is disallowed, mirror the anchor's point.
		local pt, _, rp, x, y = a:GetPoint();
		c:SetPoint(pt or "TOPRIGHT", UIParent, rp or "TOPRIGHT", x or -20, y or -220);
	end
	c:SetSize(320, 40);

	-- Create group -> layout -> set unit -> show  (order matters).
	c:AddAuraGroup("buffs", "HELPFUL", GROUP_OPTS);
	c:SetAuraGroupLayout("buffs", LAYOUT);
	if (type(AuraContainerSortMethod) == "table" and type(AuraContainerSortDirection) == "table") then
		pcall(c.SetAuraGroupSortMethod, c, "buffs", AuraContainerSortMethod.Expiration, AuraContainerSortDirection.Normal);
	end

	-- Temporary weapon enchants (poisons/oils/sharpening stones/...), main and off hand.
	if (type(AuraContainerItemEnchantmentSlot) == "table") then
		pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.MainHand, GROUP_OPTS);
		pcall(c.AddItemEnchantment, c, AuraContainerItemEnchantmentSlot.OffHand, GROUP_OPTS);
		pcall(c.SetItemEnchantmentLayout, c, LAYOUT);
	end

	c:SetUnit("player");
	c:Show();

	container = c;
end

-- Show/hide according to the flag + capability.
local function refresh()
	local on = CT_BuffMod_AuraContainerDB and CT_BuffMod_AuraContainerDB.useAuraContainer and isCapable();
	if (on) then
		build();
	elseif (container) then
		container:Hide();
	end
end

local ev = CreateFrame("Frame");
ev:RegisterEvent("PLAYER_LOGIN");
ev:SetScript("OnEvent", refresh);

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
	print("|cff33ff99CT_BuffMod|r AuraContainer display: " .. (CT_BuffMod_AuraContainerDB.useAuraContainer and "ON  (drag the blue handle to move)" or "OFF"));
	refresh();
end
