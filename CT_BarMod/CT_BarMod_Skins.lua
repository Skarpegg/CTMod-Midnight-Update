------------------------------------------------
--               CT_BarMod                    --
--                                            --
-- Intuitive yet powerful action bar addon,   --
-- featuring per-button positioning as well   --
-- as scaling while retaining the concept of  --
-- grouped buttons and action bars.           --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = select(2, ...);

-- End Initialization
--------------------------------------------

--------------------------------------------
-- Local Copies

local tinsert = tinsert;
local select = select;

-- End Local Copies
--------------------------------------------

--------------------------------------------
-- Button skins

-- The skins use the same format as the skins for Masque with some
-- additional key values starting with __CTBM__ for CT_BarMod use.
-- http://www.wowace.com/addons/masque/pages/api/skin-data/

module.skins = {};
module.skinsList = {};

local scale = 66 / 66;
local xoff = 0;
local yoff = 0;
module.skins.standard = {
	Masque_Version = 40200,
	Version = module.version,
	Shape = "Square",
	Backdrop = {
		Width = 36 * scale,
		Height = 36 * scale,
		Texture = [[Interface\Buttons\UI-EmptySlot]],
		TexCoords = {0.23, 0.77, 0.23, 0.77},
		BlendMode = "BLEND",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Normal = {
		Width = 66 * scale,
		Height = 66 * scale,
		Texture = [[Interface\Buttons\UI-Quickslot2]],
		TexCoords = {0, 1, 0, 1},
		--Random = ,
		--Textures = ,
		BlendMode = "BLEND",
		EmptyTexture = [[Interface\Buttons\UI-Quickslot]],
		EmptyCoords = {0, 1, 0, 1},
		Color = {1, 1, 1, 0.5},
		EmptyColor = {1, 1, 1, 0.5},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Icon = {
		Width = 36 * scale,
		Height = 36 * scale,
		TexCoords = {0, 1, 0, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
	},
	Flash = {
		Width = 36 * scale,
		Height = 36 * scale,
		Texture = [[Interface\Buttons\UI-QuickslotRed]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "BLEND",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Pushed = {
		Width = 36 * scale,
		Height = 36 * scale,
		Texture = [[Interface\Buttons\UI-Quickslot-Depress]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "BLEND",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Checked = {
		Width = 36 * scale,
		Height = 36 * scale,
		Texture = [[Interface\Buttons\CheckButtonHilight]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "ADD",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Border = {
		Width = 62 * scale,
		Height = 62 * scale,
		Texture = [[Interface\Buttons\UI-ActionButton-Border]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "ADD",
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Name = {
		Width = 32 * scale,
		Height = 10,
		Color = {1, 1, 1, 1},
		Font = (select(1, GameFontHighlightSmallOutline:GetFont())),
		FontSize = (select(2, GameFontHighlightSmallOutline:GetFont())), -- 10
		JustifyH = "CENTER",
		JustifyV = "MIDDLE",
		OffsetX = 0 + xoff,
		OffsetY = 2 + yoff,
	},
	Count = {
		Width = 32 * scale,
		Height = 10,
		Color = {1, 1, 1, 1},
		Font = (select(1, NumberFontNormal:GetFont())),
		FontSize = (select(2, NumberFontNormal:GetFont())), -- 14
		JustifyH = "RIGHT",
		JustifyV = "MIDDLE",
		OffsetX = -2 + xoff,
		OffsetY = 3 + yoff,
	},
	HotKey = {
		Width = 36 * scale,
		Height = 10,
		Font = (select(1, NumberFontNormalSmallGray:GetFont())),
		FontSize = (select(2, NumberFontNormalSmallGray:GetFont())), -- 12
		JustifyH = "RIGHT",
		JustifyV = "MIDDLE",
		OffsetX =  1 + xoff,
		OffsetY = -4 + yoff,
	},
	Highlight = {
		Width = 36 * scale,
		Height = 36 * scale,
		Texture = [[Interface\Buttons\ButtonHilight-Square]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "ADD",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Cooldown = {
		Width = 36 * scale,
		Height = 36 * scale,
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	AutoCast = {
		Width = 32 * scale,
		Height = 32 * scale,
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	AutoCastable = {
		Width = 66 * scale,
		Height = 66 * scale,
		Texture = [[Interface\Buttons\UI-AutoCastableOverlay]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "BLEND",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Duration = {
		Width = 36 * scale,
		Height = 10,
		Color = {1, 1, 1, 1},
		Font = (select(1, GameFontNormalSmall:GetFont())),
		FontSize = (select(2, GameFontNormalSmall:GetFont())), -- 10
		JustifyH = "CENTER",
		JustifyV = "MIDDLE",
		OffsetX = 0 + xoff,
		OffsetY = -2 + yoff,
	},
	Disabled = {
		--Width = ,
		--Height = ,
		--Texture = ,
		--TexCoords = ,
		--BlendMode = ,
		--Color = ,
		--OffsetX = ,
		--OffsetY = ,
		Hide = true,
	},
	Gloss = {
		--Width = ,
		--Height = ,
		--Texture = ,
		--TexCoords = ,
		--BlendMode = ,
		--Color = ,
		--OffsetX = ,
		--OffsetY = ,
		Hide = true,
	},
};

local scale = 62 / 56;
local xoff = -0.5;
local yoff = -0.5;
module.skins.alternate = {
	Masque_Version = 40200,
	Version = module.version,
	Shape = "Square",
	Backdrop = {
		Width = 31 * scale,
		Height = 31 * scale,
		Texture = [[Interface\Buttons\UI-EmptySlot]],
		TexCoords = {0.23, 0.77, 0.23, 0.77},
		BlendMode = "BLEND",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Normal = {
		Width = 56 * scale,
		Height = 56 * scale,
		Texture = [[Interface\Buttons\UI-Quickslot2]],
		TexCoords = {0, 1, 0, 1},
		--Random = ,
		--Textures = ,
		BlendMode = "BLEND",
		EmptyTexture = [[Interface\Buttons\UI-Quickslot]],
		EmptyCoords = {0, 1, 0, 1},
		Color = {1, 1, 1, 0.5},
		EmptyColor = {1, 1, 1, 0.5},
		OffsetX = 0.5 + xoff,
		OffsetY = -0.5 + yoff,
		Hide = false,
	},
	Icon = {
		Width = 30 * scale,
		Height = 30 * scale,
		TexCoords = {0.07, 0.93, 0.07, 0.93},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
	},
	Flash = {
		Width = 30 * scale,
		Height = 30 * scale,
		Texture = [[Interface\Buttons\UI-QuickslotRed]],
		TexCoords = {0.2, 0.8, 0.2, 0.8},
		BlendMode = "BLEND",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Pushed = {
		Width = 34 * scale,
		Height = 34 * scale,
		Texture = [[Interface\Buttons\UI-Quickslot-Depress]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "BLEND",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Checked = {
		Width = 31 * scale,
		Height = 31 * scale,
		Texture = [[Interface\Buttons\CheckButtonHilight]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "ADD",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Border = {
		Width = 62 * scale,
		Height = 62 * scale,
		Texture = [[Interface\Buttons\UI-ActionButton-Border]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "ADD",
		OffsetX = 0.5 + xoff,
		OffsetY = 0.5 + yoff,
		Hide = false,
	},
	Name = {
		Width = 32 * scale,
		Height = 10,
		Color = {1, 1, 1, 1},
		Font = (select(1, GameFontHighlightSmallOutline:GetFont())),
		FontSize = (select(2, GameFontHighlightSmallOutline:GetFont())), -- 10
		JustifyH = "CENTER",
		JustifyV = "MIDDLE",
		OffsetX = 0.5 + xoff,
		OffsetY = 2.5 + yoff,
	},
	Count = {
		Width = 32 * scale,
		Height = 10,
		Color = {1, 1, 1, 1},
		Font = (select(1, NumberFontNormal:GetFont())),
		FontSize = (select(2, NumberFontNormal:GetFont())), -- 14
		JustifyH = "RIGHT",
		JustifyV = "MIDDLE",
		OffsetX = -1.5 + xoff,
		OffsetY = 3.5 + yoff,
	},
	HotKey = {
		Width = 36 * scale,
		Height = 10,
		Font = (select(1, NumberFontNormalSmallGray:GetFont())),
		FontSize = (select(2, NumberFontNormalSmallGray:GetFont())), -- 12
		JustifyH = "RIGHT",
		JustifyV = "MIDDLE",
		OffsetX = -2.5 + xoff,
		OffsetY = -3.5 + yoff,
	},
	Highlight = {
		Width = 30 * scale,
		Height = 30 * scale,
		Texture = [[Interface\Buttons\ButtonHilight-Square]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "ADD",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Cooldown = {
		Width = 32 * scale,
		Height = 32 * scale,
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	AutoCast = {
		Width = 30 * scale,
		Height = 30 * scale,
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	AutoCastable = {
		Width = 62 * scale,
		Height = 62 * scale,
		Texture = [[Interface\Buttons\UI-AutoCastableOverlay]],
		TexCoords = {0, 1, 0, 1},
		BlendMode = "BLEND",
		Color = {1, 1, 1, 1},
		OffsetX = 0 + xoff,
		OffsetY = 0 + yoff,
		Hide = false,
	},
	Duration = {
		Width = 36 * scale,
		Height = 10,
		Color = {1, 1, 1, 1},
		Font = (select(1, GameFontNormalSmall:GetFont())),
		FontSize = (select(2, GameFontNormalSmall:GetFont())), -- 10
		JustifyH = "CENTER",
		JustifyV = "MIDDLE",
		OffsetX = 0.5 + xoff,
		OffsetY = -1.5 + yoff,
	},
	Disabled = {
		--Width = ,
		--Height = ,
		--Texture = ,
		--TexCoords = ,
		--BlendMode = ,
		--Color = ,
		--OffsetX = ,
		--OffsetY = ,
		Hide = true,
	},
	Gloss = {
		--Width = ,
		--Height = ,
		--Texture = ,
		--TexCoords = ,
		--BlendMode = ,
		--Color = ,
		--OffsetX = ,
		--OffsetY = ,
		Hide = true,
	},
};

local function setTextureData(skin, item, hide, layer, sublevel, color)
	-- hide == true, false, nil
	-- layer == "BACKGROUND", "BORDER", "ARTWORK", "OVERLAY", "HIGHLIGHT"
	-- sublevel == number
	-- color == true, false
	skin[item].__CTBM__Hide = hide;
	skin[item].__CTBM__DrawLayer = layer;
	skin[item].__CTBM__SubLevel = sublevel; -- number
	if (color) then
		skin[item].__CTBM__VertexColor = {1, 1, 1, 1};
	else
		skin[item].__CTBM__VertexColor = nil;
	end
end

local function setFontData(skin, item, hide, layer, sublevel, anchor, relative, color, font)
	-- hide == true, false, nil
	-- layer == "BACKGROUND", "BORDER", "ARTWORK", "OVERLAY", "HIGHLIGHT"
	-- sublevel == number
	-- anchor == anchor point ("TOPLEFT", etc)
	-- relative == relative point ("TOPLEFT", etc)
	-- color == true, false
	-- font == font object
	skin[item].__CTBM__Hide = hide;
	skin[item].__CTBM__DrawLayer = layer;
	skin[item].__CTBM__SubLevel = sublevel;
	skin[item].__CTBM__Anchor = anchor;
	skin[item].__CTBM__Relative = relative;
	skin[item].__CTBM__Font = font;
	if (color) then
		skin[item].__CTBM__VertexColor = {1, 1, 1, 1};
	else
		skin[item].__CTBM__VertexColor = nil;
	end
end

local function addSkin(skin, skinId, skinName, MasqueName)
	-- skinID -- Skin ID code (used in CT_BarMod)
	-- skinName -- Skin name (used in CT_BarMod dropdown menu)
	-- MasqueName -- Name used in Masque's skin dropdown menu

	skin.__CTBM__skinID = skinId;
	skin.__CTBM__skinName = skinName;
	skin.__CTBM__MasqueName = MasqueName;

	--                   Key          Hide   Layer        Lvl Color
	setTextureData(skin, "Backdrop",  nil,   "BACKGROUND", 0, true);
	setTextureData(skin, "Normal",    false, "BORDER",     0, true);
	setTextureData(skin, "Icon",      true,  "BORDER",     1, true);
	setTextureData(skin, "Flash",     true,  "ARTWORK",    0, true);
	setTextureData(skin, "Pushed",    true,  "ARTWORK",    0, true);
	setTextureData(skin, "Checked",   true,  "ARTWORK",    1, true);
	setTextureData(skin, "Border",    true,  "OVERLAY",    0, true);
	setTextureData(skin, "Highlight", false, "HIGHLIGHT",  0, true);

	--                Key       Hide Layer     Lvl AnchorPoint    RelativePoint  Color  FontObject
	setFontData(skin, "Name",   nil, "OVERLAY", 1, "BOTTOM",      "BOTTOM",      true,  GameFontHighlightSmallOutline);
	setFontData(skin, "Count",  nil, "OVERLAY", 1, "BOTTOMRIGHT", "BOTTOMRIGHT", true,  NumberFontNormal);
	setFontData(skin, "HotKey", nil, "OVERLAY", 1, "TOPLEFT",     "TOPLEFT",     false, NumberFontNormalSmallGray);

	skin.Cooldown.__CTBM__Hide = nil;

	-- Add the skin to Masque
	if (module:isMasqueLoaded()) then
		module:addSkinToMasque(skin.__CTBM__MasqueName, skin);
	end

	-- Add the skin to CT_BarMod
	tinsert(module.skinsList, skin);
end

function module:getSkinData(skinNumber)
	local skinNumber = skinNumber or 1;
	local skinData = module.skinsList[skinNumber];
	if (not skinData) then
		skinData = module.skins.standard;
	end
	return skinData;
end

function module:addSkins()
	-- Add the skins in the order they will appear in the CT_BarMod dropdown menu.
	-- The first one must be the standard CT_BarMod skin.
	--
	--      Skin table              skinID       skinName     Masque skin name
	addSkin(module.skins.standard,  "standard",  "Standard",  "CT_BarMod Standard");
	addSkin(module.skins.alternate, "alternate", "Alternate", "CT_BarMod Alternate");
end

function module:skinOverlayGlow(button, Glow, Ants)
	-- Update the Glow and Ants textures used for button overlay glows
	-- (ie. spell activation alerts).
	-- Overlay frame keys and texture names are from ActionBarFrame.xml.
	local overlay = button.overlay;
	if (not overlay) then
		return;
	end
	if (not Glow) then
		-- Use default glow texture.
		Glow = "Interface\\SpellActivationOverlay\\IconAlert";
	end
	if (not Ants) then
		-- Use default ants texture.
		Ants = "Interface\\SpellActivationOverlay\\IconAlertAnts";
	end
	if (overlay.innerGlow) then
		overlay.innerGlow:SetTexture(Glow);
	end
	if (overlay.innerGlowOver) then
		overlay.innerGlowOver:SetTexture(Glow);
	end
	if (overlay.outerGlow) then
		overlay.outerGlow:SetTexture(Glow);
	end
	if (overlay.outerGlowOver) then
		overlay.outerGlowOver:SetTexture(Glow);
	end
	if (overlay.spark) then
		overlay.spark:SetTexture(Glow);
	end
	if (overlay.ants) then
		overlay.ants:SetTexture(Ants);
	end
end
