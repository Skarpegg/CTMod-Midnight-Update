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

local isEnabled = nil;

--------------------------------------------
-- Performance Monitor

local function updatePosition(self)
	if (isEnabled) then
		local x1, y1, w1, h1 = self.frame:GetRect()
		h1 = MainMenuBarPerformanceBarFrame:GetHeight()
		local x2, y2, w2, h2 = KeyRingButton:GetRect()
		if (KeyRingButton:IsShown() 
			and ((x1 > x2 and x1 < x2 + w2) or (x1 + w1 > x2 and x1 + w1 < x2 + w2))
			and ((y2 > y1 and y2 < y1 + h1) or (y2 + h2 > y1 and y2 + y2 < h1 + h1))
		) then
			-- colides with the KeyRingButon, so move left.
			MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMRIGHT", self.frame, 0, 0);
		else
			MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMRIGHT", self.frame, 8, 0);
		end
		MainMenuBarPerformanceBar:SetDrawLayer("BACKGROUND", -1);
	else
		MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMRIGHT", MainMenuBar, KeyRingButton:IsShown() and -235 or -227, -10);
	end
end

local function addon_Update(self)
	-- Update the frame
	-- self == actionbar arrows bar object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", MainMenuBarPerformanceBarFrame, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", MainMenuBarPerformanceBarFrame, "BOTTOMRIGHT", 5, 0);
end


local function addon_Enable(self)
	isEnabled = true;
	updatePosition(self);
end

local function addon_Disable(self)
	isEnabled = false;
	updatePosition(self);
end

local function addon_Init(self)
	-- Initialization
	-- self == actionbar arrows bar object

	appliedOptions = module.appliedOptions;

	module.ctClassicPerformanceBar = self;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;
	
	self.frame:SetClampRectInsets(5,5,35,15);
	
	local frame2 = self.frame.button;
	frame2:HookScript("OnMouseUp", function()
		updatePosition(self)
	end);
	
	KeyRingButton:HookScript("OnShow", function()
		updatePosition(module.ctClassicPerformanceBar);
	end)	
	return true;
end

local function addon_PostInit(self)
	local isActive = nil;
	hooksecurefunc(MainMenuBarPerformanceBarFrame, "SetPoint", function()
		if (isActive) then
			return;
		else
			isActive = true;
			updatePosition(self);
			isActive = nil;
		end
		
	end);
end

local function addon_Register()
	module:registerAddon(
		"Classic Performance Bar",  -- option name
		"ClassicPerformanceBar",  -- used in frame names
		module.text["CT_BottomBar/Options/ClassicPerformanceBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/ClassicPerformanceBar"],  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMRIGHT", ctRelativeFrame, "BOTTOM", 277, -10 },
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		addon_PostInit,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		addon_Disable,
		"helperFrame",
		MainMenuBarPerformanceBarFrame
	);
end

module.loadedAddons["Classic Performance Bar"] = addon_Register;
