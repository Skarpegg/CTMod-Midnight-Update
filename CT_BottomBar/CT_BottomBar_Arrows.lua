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

local CT_BB_PageNumber;

local objUp = ActionBarUpButton
local objDown = ActionBarDownButton
local objNumber = (MainMenuBarArtFrame and MainMenuBarArtFrame.PageNumber) or MainMenuBarPageNumber

--------------------------------------------
-- Action bar arrows and page number

local function addon_Update(self)
	-- Update the frame
	-- self == actionbar arrows bar object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", objUp, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", objDown, "BOTTOMRIGHT", 15, -5);

	objDown:SetParent(self.frame);
	objUp:SetParent(self.frame);
	
	objDown:ClearAllPoints();
	objUp:ClearAllPoints();

	objDown:SetPoint("TOPRIGHT", self.frame, 0, 0);
	objUp:SetPoint("BOTTOMRIGHT", self.frame, 0, (module:getGameVersion() <= 7 and -12) or 0);
end

local function addon_Enable(self)
	self.frame:SetClampRectInsets(10, -10, 39, 10);
	objNumber:Hide();
	if (CT_BB_PageNumber) then
		CT_BB_PageNumber:Show();
	else
		CT_BB_PageNumber = self.frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");
		CT_BB_PageNumber:SetText(GetActionBarPage());
		CT_BB_PageNumber:SetPoint("CENTER", self.frame, "RIGHT", (module:getGameVersion() <= 7 and 4) or 5, (module:getGameVersion() <= 7 and -6) or 0);
		self.frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED");
		self.frame:SetScript("OnEvent",function(newself, event, ...)
			if (event == "ACTIONBAR_PAGE_CHANGED") then
				CT_BB_PageNumber:SetText(GetActionBarPage());
			end
		end);
	end
end

local function addon_Disable(self)
	objNumber:Show();
	CT_BB_PageNumber:Hide();
end

local function addon_Init(self)
	-- Initialization
	-- self == actionbar arrows bar object

	appliedOptions = module.appliedOptions;

	module.ctActionBarPage = self;

	self.frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1);

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Action Bar Arrows",  -- option name
		"ActionBarPage",  -- used in frame names
		module.text["CT_BottomBar/Options/ActionBarPage"],  -- shown in options window & tooltips
		"Page",  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM",  (module:getGameVersion() <= 7 and -4.9) or -6, (module:getGameVersion() <= 7 and 26) or 24},
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		addon_Disable,  -- no disable function
		"helperFrame",
		objUp,
		objDown,
		objNumber
	);
end

module.loadedAddons["Action Bar Arrows"] = addon_Register;
