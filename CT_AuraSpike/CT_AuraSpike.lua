-- CT_AuraSpike -- throwaway spike to crack the AuraContainer render sequence for the CT_BuffMod
-- migration. NOT for release. Loads on /reload; use /ctspike to rebuild and print diagnostics.
--
-- Findings baked in so far (from Blizzard source, branch `live`):
--   * container = CreateFrame("AuraContainer", name, parent, "CustomAuraContainerTemplate")
--   * group     = container:AddAuraGroup(key, filterString, { templateNames = {"CustomAuraButtonTemplate"},
--                    initializeFrame = fn, ignoreBuffs=, ignoreDebuffs=, displayOnlyDispellableDebuffs= })
--   * CustomAuraButton is "bring your own regions": in initializeFrame create a Texture and register it
--     with button:SetIcon(tex) (also SetApplicationCount / SetDurationCooldown / AddDispelTypeTexture...).
--     Blizzard's SECURE code then fills them from the (secret) aura data -> works in combat.
--   * container:SetUnit("player"); container:Show()

local PREFIX = "|cff33ff99CTSpike|r ";
local function log(...) print(PREFIX, ...); end

-- pcall a method call and log the outcome (so one bad call doesn't abort the whole build).
local function try(label, obj, method, ...)
	if (type(obj) ~= "table" or type(obj[method]) ~= "function") then
		log("SKIP", label, "-- no method", method);
		return false;
	end
	local ok, a, b = pcall(obj[method], obj, ...);
	if (ok) then
		log("ok  ", label, a, b);
	else
		log("ERR ", label, a);
	end
	return ok, a;
end

-- initializeFrame: attach + register the display regions Blizzard will drive securely.
local initCount = 0;
local function initButton(...)
	initCount = initCount + 1;
	local button = ...;
	if (initCount <= 2) then
		log("initButton call", initCount, "argc=", select("#", ...),
			"type=", type(button), button and button.GetObjectType and button:GetObjectType());
	end
	if (type(button) ~= "table") then return; end
	pcall(button.SetSize, button, 32, 32);
	if (not button.ctIcon and button.CreateTexture) then
		local tex = button:CreateTexture(nil, "ARTWORK");
		tex:SetAllPoints(button);
		tex:SetTexture(134400);	-- placeholder (question-mark) so we can SEE the button even before Blizzard sets the real icon
		button.ctIcon = tex;
		-- Register the icon region with the secure button so Blizzard fills it from the aura.
		if (button.SetIcon) then pcall(button.SetIcon, button, tex); end
	end
	if (button.Show) then button:Show(); end
end

local container;

local function build()
	if (not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer")) then
		local ok, err = C_AddOns.LoadAddOn("Blizzard_AuraContainer");
		log("LoadAddOn Blizzard_AuraContainer ->", ok, err);
	end

	if (container) then
		container:Hide();
		container = nil;
	end

	local ok, c = pcall(CreateFrame, "AuraContainer", "CT_AuraSpikeContainer", UIParent, "CustomAuraContainerTemplate");
	if (not ok or not c) then
		log("CreateFrame FAILED:", c);
		return;
	end
	container = c;
	c:SetPoint("CENTER", UIParent, "CENTER", 0, 120);
	c:SetSize(400, 40);

	-- A visible backdrop so we can see the container region itself even if buttons don't render.
	if (BackdropTemplateMixin) then
		Mixin(c, BackdropTemplateMixin);
		pcall(c.SetBackdrop, c, { bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" });
		pcall(c.SetBackdropColor, c, 0, 0, 0, 0.5);
	end

	initCount = 0;
	try("AddAuraGroup", c, "AddAuraGroup", "buffs", "HELPFUL", {
		templateNames = { "CustomAuraButtonTemplate" },
		initializeFrame = initButton,
	});
	try("SetAuraGroupLayout", c, "SetAuraGroupLayout", "buffs", {
		elementWidth = 32,
		elementHeight = 32,
		elementSpacing = 4,
	});
	try("SetUnit", c, "SetUnit", "player");
	c:Show();

	-- Report what got built.
	local _, count = try("GetAuraGroupFrameCount", c, "GetAuraGroupFrameCount", "buffs");
	log("built. initButton calls =", initCount, " group frame count =", count,
		" container children =", c:GetNumChildren());
end

local ev = CreateFrame("Frame");
ev:RegisterEvent("PLAYER_LOGIN");
ev:SetScript("OnEvent", function()
	log("loaded. Run /ctspike to build the test container.");
end);

SLASH_CTSPIKE1 = "/ctspike";
SlashCmdList.CTSPIKE = function(msg)
	if (msg == "count" and container) then
		log("frame count =", container:GetAuraGroupFrameCount("buffs"), " children =", container:GetNumChildren());
	else
		build();
	end
end
