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

if CT_BottomBar:getGameVersion() >= 10 then
	return
end

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
	self.helperFrame:SetPoint("TOPLEFT", self.frame, -10, 60);
	self.helperFrame:SetPoint("BOTTOMRIGHT", self.frame, 10, -35);

end

local function addon_Enable(self)
	ZoneAbilityFrame.Style:SetPoint("CENTER", self.frame, -2, 0)
	ZoneAbilityFrame.SpellButtonContainer:SetPoint("CENTER", self.frame, 0, 0)
	self.frame:SetClampRectInsets(0,0,0,0);
end

local function addon_Disable(self)
	ZoneAbilityFrame.Style:SetPoint("CENTER", ZoneAbilityFrame, -2, 0)
	ZoneAbilityFrame.SpellButtonContainer:SetPoint("CENTER", ZoneAbilityFrame)
end

local function addon_Init(self)
	-- Initialization
	-- self == actionbar arrows bar object

	appliedOptions = module.appliedOptions;

	module.ctZoneAbilityBar = self;

	self.frame:SetFrameLevel(1);

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Zone Ability Button",  -- option name
		"ZoneAbilityBar",  -- used in frame names
		module.text["CT_BottomBar/Options/ZoneAbilityBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/ZoneAbilityBar"],  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{"BOTTOM", ExtraAbilityContainer },
		{ -- settings
			orientation = "ACROSS",
			noHideOption = true,  -- no "hide" option for this bar
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		addon_Disable,
		"helperFrame"
	);
end

module.loadedAddons["Zone Ability Bar"] = addon_Register;
