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
local isEnabled

--------------------------------------------
-- MultiCast Bar (Totem bar)

local function moveBar()
	if isEnabled and not InCombatLockdown() then
		local x, y = module.ctMultiCastBar.frame:GetScaledRect()
		local x2, y2 = MultiCastActionPage1:GetScaledRect()
		local scale = MultiCastActionPage1:GetEffectiveScale()
		MultiCastActionPage1:AdjustPointsOffset((x-x2)/scale, (y-y2)/scale)
		MultiCastActionPage2:AdjustPointsOffset((x-x2)/scale, (y-y2)/scale)
		MultiCastActionPage3:AdjustPointsOffset((x-x2)/scale, (y-y2)/scale)
		MultiCastSlotButton1:AdjustPointsOffset((x-x2)/scale, (y-y2)/scale)
		
		local x3,y3 = MultiCastSummonSpellButton:GetScaledRect()
		MultiCastSummonSpellButton:AdjustPointsOffset((x-30-x3)/scale, (y-y3)/scale)
		
		MultiCastRecallSpellButton:ClearPoint("BOTTOMLEFT")
		
		--local x4,y4 = MultiCastRecallSpellButton:GetScaledRect()
		--MultiCastRecallSpellButton:AdjustPointsOffset((x+30-x4)/scale, (y-y4)/scale)
	end	
end


local function addon_Update(self)
	-- Update the frame
	-- self == actionbar arrows bar object
	
	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", self.frame, -30, 30);
	self.helperFrame:SetPoint("BOTTOMRIGHT", self.frame, 150, 0);

	moveBar()

end

local function addon_Enable(self)
	self.frame:SetClampRectInsets(0,0,0,0);
	isEnabled = true
	moveBar()
end

local function addon_Disable(self)
	MultiCastActionPage1:SetPoint("BOTTOMLEFT", 36, 3)
	MultiCastActionPage2:SetPoint("BOTTOMLEFT", 36, 3)
	MultiCastActionPage3:SetPoint("BOTTOMLEFT", 36, 3)
	MultiCastSlotButton1:SetPoint("BOTTOMLEFT", 36, 3)
	isEnabled = false
end

local function addon_Init(self)
	-- Initialization
	-- self == actionbar arrows bar object

	appliedOptions = module.appliedOptions;

	module.ctMultiCastBar = self;

	self.frame:SetFrameLevel(1);


	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;
	
	hooksecurefunc(MultiCastActionBarFrame, "SetPoint", moveBar)
	hooksecurefunc(MultiCastActionBarFrame, "Show", moveBar)
	hooksecurefunc(MultiCastSlotButton1, "SetPoint", moveBar)
	module:regEvent("PLAYER_REGEN_ENABLED", moveBar)
	hooksecurefunc(self.frame,"StopMovingOrSizing", moveBar)

	
	-- modification to this function so it stops moving things in response to events.
	local oldMultiCastSummonSpellButton_Update = MultiCastSummonSpellButton_Update
	local oldMultiCastRecallSpellButton_Update = MultiCastRecallSpellButton_Update
	module:regEvent("PLAYER_REGEN_ENABLED", function()
		if isEnabled then
			MultiCastSummonSpellButton_Update = oldMultiCastSummonSpellButton_Update
			MultiCastSummonSpellButton_Update(MultiCastSummonSpellButton)
			MultiCastRecallSpellButton_Update = oldMultiCastRecallSpellButton_Update
			MultiCastRecallSpellButton_Update(MultiCastRecallSpellButton)
		end
	end)
	module:regEvent("PLAYER_REGEN_DISABLED", function()
		if isEnabled then
			MultiCastSummonSpellButton_Update = nop
			MultiCastRecallSpellButton_Update = nop
		end
	end)

	
	return true;
end



local function addon_Register()
	module:registerAddon(
		"MultiCastBar",  -- option name
		"MultiCastBar",  -- used in frame names
		module.text["CT_BottomBar/Options/MultiCastBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/MultiCastBar"],  -- title for horizontal orientation
		"Totems",  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -486, 149 },
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- not assigning the orientation function (not for use with this bar)
		addon_Enable,
		addon_Disable,
		"helperFrame",
		MultiCastActionBarFrame
	);
end

if (module:getGameVersion() == 3 or module:getGameVersion() == 4) and UnitClassBase("player") == "SHAMAN" then
	module.loadedAddons["MultiCastBar"] = addon_Register;
end
