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

-- Credit:
-- CT_BB module written by DDCorkum


--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

local CT_BB_StanceBar_IsEnabled = nil;
local CT_BB_FlightBar_IsEnabled = nil;

--------------------------------------------
-- Action bar arrows and page number

local function moveStanceBar()
	if (not StanceBarFrame or InCombatLockdown()) then return; end
	if (CT_BB_StanceBar_IsEnabled) then
		StanceButton1:ClearAllPoints();
		StanceButton1:SetPoint("BOTTOMLEFT",CT_BottomBar_CTStanceBarFrame_Frame);
	else
		StanceButton1:ClearAllPoints();
		StanceButton1:SetPoint("BOTTOMLEFT",StanceBarFrame, 11, 3);
	end
end

local function moveFlightBar()
	if (not StanceBarFrame or not MainMenuBarVehicleLeaveButton or InCombatLockdown()) then return; end
	if (CT_BB_FlightBar_IsEnabled) then
		MainMenuBarVehicleLeaveButton:ClearAllPoints();
		MainMenuBarVehicleLeaveButton:SetPoint("BOTTOMLEFT", CT_BottomBar_CTFlightBarFrame_Frame);	
	elseif (CT_BB_StanceBar_IsEnabled) then
		MainMenuBarVehicleLeaveButton:ClearAllPoints();
		MainMenuBarVehicleLeaveButton:SetPoint("RIGHT", StanceButton1, "LEFT", -10, 0);
	else
		MainMenuBarVehicleLeaveButton:ClearAllPoints();
		MainMenuBarVehicleLeaveButton:SetPoint("RIGHT", ctRelativeFrame, "BOTTOM", -492, 90);
	end
end

local function UpdateStanceBar(self)
	-- Update the frame
	-- self == talking head object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, -5);
end

local function EnableStanceBar(self)
	CT_BB_StanceBar_IsEnabled = true;
	moveStanceBar();
end

local function DisableStanceBar(self)
	CT_BB_StanceBar_IsEnabled = false;
	moveStanceBar();
end

local function InitStanceBar(self)
	-- Initialization
	-- self == stance bar object

	appliedOptions = module.appliedOptions;

	module.ctStanceBar = self;

	self.helperFrame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	local function resizeHelperFrame()
		self.helperFrame:SetPoint("RIGHT", StanceButton5 and StanceButton5:IsShown() and StanceButton5 or StanceButton4 and StanceButton4:IsShown() and StanceButton4 or StanceButton3 and StanceButton3:IsShown() and StanceButton3 or StanceButton2 and StanceButton2:IsShown() and StanceButton2 or self.frame, "RIGHT", 5, 0);
	end
	StanceButton2:HookScript("OnShow", resizeHelperFrame);
	StanceButton2:HookScript("OnHide", resizeHelperFrame);
	StanceButton3:HookScript("OnShow", resizeHelperFrame);
	StanceButton3:HookScript("OnHide", resizeHelperFrame);
	StanceButton4:HookScript("OnShow", resizeHelperFrame);
	StanceButton4:HookScript("OnHide", resizeHelperFrame);
	StanceButton5:HookScript("OnShow", resizeHelperFrame);
	StanceButton5:HookScript("OnHide", resizeHelperFrame);
	resizeHelperFrame();
	
	self.frame:SetHeight(32);
	self.frame:SetWidth(29);
	
	hooksecurefunc("UIParent_ManageFramePositions", moveStanceBar);
	StanceBarFrame:HookScript("OnShow", moveStanceBar);

	return true;
end

local function UpdateFlightBar(self)
	-- Update the frame
	-- self == talking head object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 10);
	self.helperFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 10, 0);
end

local function EnableFlightBar(self)
	CT_BB_FlightBar_IsEnabled = true;
	moveFlightBar();
end

local function DisableFlightBar(self)
	CT_BB_FlightBar_IsEnabled = false;
	moveFlightBar();
end

local function InitFlightBar(self)
	-- Initialization
	-- self == flight bar object

	appliedOptions = module.appliedOptions;

	module.ctFlightBar = self;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;
	
	self.frame:SetHeight(20);
	self.frame:SetWidth(20);
	
	hooksecurefunc("UIParent_ManageFramePositions", moveFlightBar);
	MainMenuBarVehicleLeaveButton:HookScript("OnShow", moveFlightBar);

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Stance Bar",  -- option name
		"CTStanceBarFrame",  -- used in frame names
		module.text["CT_BottomBar/Options/StanceBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/StanceBar"],  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -482, 60 },
		{ -- settings
			orientation = "ACROSS",
		},
		InitStanceBar,
		nil,  -- no post init function
		nil,  -- no config function
		UpdateStanceBar,
		nil,  -- no orientation function
		EnableStanceBar,
		DisableStanceBar,  -- no disable function
		"helperFrame",
		StanceButton1,
		StanceButton2,
		StanceButton3,
		StanceButton4,
		StanceButton5,
		StanceButton6,
		StanceButton7,
		StanceButton8,
		StanceButton9,
		StanceButton10
	);
	module:registerAddon(
		"Flight Bar",  -- option name
		"CTFlightBarFrame",  -- used in frame names
		module.text["CT_BottomBar/Options/FlightBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/FlightBar"],  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "RIGHT", ctRelativeFrame, "BOTTOM", -492, 90 },
		{ -- settings
			orientation = "ACROSS",
		},
		InitFlightBar,
		nil,  -- no post init function
		nil,  -- no config function
		UpdateFlightBar,
		nil,  -- no orientation function
		EnableFlightBar,
		DisableFlightBar,  -- no disable function
		"helperFrame",
		MainMenuBarVehicleLeaveButton
	);
end

module.loadedAddons["Stance Bar"] = addon_Register;
