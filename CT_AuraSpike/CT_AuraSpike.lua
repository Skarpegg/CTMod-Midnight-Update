-- CT_AuraSpike -- throwaway spike for the CT_BuffMod -> AuraContainer migration. NOT for release.
-- /reload then /ctspike.
--
-- CONFIRMED recipe (order matters!): create -> AddAuraGroup(+layout) -> SetUnit -> Show.
--   c = CreateFrame("AuraContainer", name, parent, "CustomAuraContainerTemplate")
--   c:AddAuraGroup(key, filterString, { templateNames={"CustomAuraButtonTemplate"}, initializeFrame=fn })
--   -- initializeFrame(button): create a Texture, button:SetIcon(tex), size it; Blizzard fills it securely.
--   c:SetAuraGroupLayout(key, { elementWidth, elementHeight, elementSpacing })
--   c:SetUnit(unit); c:Show()
--
-- Valid filter components (secure parser): HELPFUL, HARMFUL, PLAYER, RAID, CANCELABLE, DISPELLABLE.
--   Rejected: NOT_CANCELABLE, CURABLE. Sort: AuraContainerSortMethod.* + AuraContainerSortDirection.*.
--   Weapon enchants: AddItemEnchantment(AuraContainerItemEnchantmentSlot.MainHand/OffHand/Ranged, opts).
--   Click-to-cancel: NOT supported by CustomAuraButton (no cancel wiring).
--
-- This iteration renders separate colored boxes per filter so we can EYEBALL whether the secure
-- filtering actually works (GetAuraGroupFrameCount is a frame pool, not a match count -- useless).

local function log(...) print("|cff33ff99CTSpike|r ", ...); end

local function initButton(button)
	if (type(button) ~= "table") then return; end
	pcall(button.SetSize, button, 28, 28);
	if (not button.ctIcon and button.CreateTexture) then
		local tex = button:CreateTexture(nil, "ARTWORK");
		tex:SetAllPoints(button);
		button.ctIcon = tex;
		if (button.SetIcon) then pcall(button.SetIcon, button, tex); end
	end
	if (button.Show) then button:Show(); end
end

local layout = { elementWidth = 28, elementHeight = 28, elementSpacing = 3 };
local function groupOpts() return { templateNames = { "CustomAuraButtonTemplate" }, initializeFrame = initButton }; end

local containers = {};

-- create -> add group -> layout -> setunit -> show, in the required order.
local function makeBox(name, unit, filter, yoff, r, g, b)
	local c = CreateFrame("AuraContainer", name, UIParent, "CustomAuraContainerTemplate");
	c:SetPoint("CENTER", UIParent, "CENTER", -230, yoff);
	c:SetSize(300, 30);
	if (BackdropTemplateMixin) then
		Mixin(c, BackdropTemplateMixin);
		pcall(c.SetBackdrop, c, { bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" });
		pcall(c.SetBackdropColor, c, r, g, b, 0.5);
	end
	local fs = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	fs:SetPoint("RIGHT", c, "LEFT", -4, 0);
	fs:SetText(filter .. " @" .. unit);
	local ok, err = pcall(c.AddAuraGroup, c, "g", filter, groupOpts());
	if (ok) then
		pcall(c.SetAuraGroupLayout, c, "g", layout);
	else
		log("AddAuraGroup ERR", filter, err);
	end
	pcall(c.SetUnit, c, unit);
	c:Show();
	containers[#containers + 1] = c;
	return c;
end

local function build()
	for _, c in ipairs(containers) do c:Hide(); end
	wipe(containers);
	if (not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer")) then
		log("LoadAddOn ->", C_AddOns.LoadAddOn("Blizzard_AuraContainer"));
	end

	-- Colored boxes, top to bottom. Eyeball whether each shows the RIGHT auras.
	local black  = makeBox("CT_ASbuffs",  "player", "HELPFUL",            170, 0,    0,    0);     -- all your buffs
	makeBox("CT_ASdebuff", "player", "HARMFUL",            132, 0.30, 0,    0);     -- your debuffs (should NOT be your buffs)
	makeBox("CT_AScancel", "player", "HELPFUL|CANCELABLE", 94,  0,    0,    0.35);  -- only cancelable buffs (<= black?)
	makeBox("CT_ASown",    "player", "HELPFUL|PLAYER",     56,  0,    0.30, 0);     -- only buffs you cast
	makeBox("CT_AStarget", "target", "HELPFUL",            18,  0.30, 0.20, 0);     -- target's buffs (target someone)

	-- sort + weapon enchant on the black (all buffs) box
	if (type(AuraContainerSortMethod) == "table" and type(AuraContainerSortDirection) == "table") then
		local ok = pcall(black.SetAuraGroupSortMethod, black, "g", AuraContainerSortMethod.Name, AuraContainerSortDirection.Normal);
		log("sort by Name ->", ok);
	end
	if (type(AuraContainerItemEnchantmentSlot) == "table") then
		local ok = pcall(black.AddItemEnchantment, black, AuraContainerItemEnchantmentSlot.MainHand, groupOpts());
		log("AddItemEnchantment MainHand ->", ok);
	end

	log("Boxes (top->bottom): buffs / debuffs / cancelable / own / target. Compare what each shows.");
end

local ev = CreateFrame("Frame");
ev:RegisterEvent("PLAYER_LOGIN");
ev:SetScript("OnEvent", function() log("loaded. /ctspike to build."); end);

SLASH_CTSPIKE1 = "/ctspike";
SlashCmdList.CTSPIKE = function() build(); end
