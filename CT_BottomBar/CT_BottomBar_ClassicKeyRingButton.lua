------------------------------------------------
--               CT_BottomBar                 --
--                                            --
-- Breaks up the main menu bar into pieces,   --
-- allowing you to hide and move the pieces   --
-- independently of each other.               --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

--------------------------------------------
-- Action bar arrows and page number

local function addon_Update(self)
	-- Update the frame
	-- self == actionbar arrows bar object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", KeyRingButton, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", KeyRingButton, "BOTTOMRIGHT", 0, 5);

end

local function addon_Enable(self)
	KeyRingButton:SetPoint("RIGHT", self.frame, 0, 0);
	self.frame:SetClampRectInsets(0,0,0,0);
end

local function addon_Disable(self)
	KeyRingButton:SetPoint("RIGHT", ctRelativeFrame, "BOTTOM", 295, 21.5);
end

local function addon_Init(self)
	-- Initialization
	-- self == actionbar arrows bar object

	appliedOptions = module.appliedOptions;

	module.ctClassicKeyRingButton = self;

	self.frame:SetFrameLevel(1);

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Classic Key Ring Button",  -- option name
		"ClassicKeyRingButton",  -- used in frame names
		module.text["CT_BottomBar/Options/ClassicKeyRingButton"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/ClassicKeyRingButton"],  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		--{ "RIGHT", MainMenuBarArtFrame, "BOTTOMRIGHT", -216, 21.5 },
		{"RIGHT", ctRelativeFrame, "BOTTOM", 295, 21.5 },
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		addon_Disable,
		"helperFrame",
		KeyRingButton
	);
end

module.loadedAddons["Classic Key Ring Button"] = addon_Register;
