------------------------------------------------------------------------------------------------------
-- CT_BuffMod -- AuraContainer display path (WoW Midnight 12.1+)
--
-- Additive + capability-gated + behind a dev flag (default OFF): the existing secure/unsecure buff
-- system is completely unaffected unless CT_BuffModOptions.useAuraContainer is turned on (/ctbuffac)
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

local function build()
	if (container) then
		container:Hide();
		container = nil;
	end

	local c = CreateFrame("AuraContainer", "CT_BuffMod_AuraContainer_Player", UIParent, "CustomAuraContainerTemplate");

	-- Position (saved, else a sensible default top-right).
	CT_BuffModOptions = CT_BuffModOptions or {};
	local p = CT_BuffModOptions.auraContainerPoint;
	c:ClearAllPoints();
	if (type(p) == "table") then
		c:SetPoint(p[1] or "TOPRIGHT", UIParent, p[2] or "TOPRIGHT", p[3] or -20, p[4] or -220);
	else
		c:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -220);
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
	local on = CT_BuffModOptions and CT_BuffModOptions.useAuraContainer and isCapable();
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
	CT_BuffModOptions = CT_BuffModOptions or {};
	msg = (msg or ""):lower():gsub("%s", "");
	if (msg == "on") then
		CT_BuffModOptions.useAuraContainer = true;
	elseif (msg == "off") then
		CT_BuffModOptions.useAuraContainer = false;
	else
		CT_BuffModOptions.useAuraContainer = not CT_BuffModOptions.useAuraContainer;
	end
	if (CT_BuffModOptions.useAuraContainer and not isCapable()) then
		print("|cffff4040CT_BuffMod|r AuraContainer API not available on this client.");
		return;
	end
	print("|cff33ff99CT_BuffMod|r AuraContainer display: " .. (CT_BuffModOptions.useAuraContainer and "ON (top-right)" or "OFF"));
	refresh();
end
