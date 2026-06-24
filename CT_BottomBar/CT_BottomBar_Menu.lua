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
-- Menu bar (micro buttons)

-- Game UI elements referenced:
--
-- CharacterMicroButton
-- SpellbookMicroButton
-- TalentMicroButton
-- AchievementMicroButton
-- QuestLogMicroButton
-- GuildMicroButton
-- LFDMicroButton
-- CollectionsMicroButton
-- EJMicroButton
-- StoreMicroButton
-- MainMenuMicroButton
--
-- MainMenuBarArtFrame
-- OverrideActionBarLeaveFrame:
-- OverrideActionBarPitchFrame:

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctAddon;
local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;
local setpoint;
local setparent;

--------------------------------------------
-- Misc

local function isBusy()
	return module:isBlizzardAnimating();
end

local function setDelayedUpdate(value)
	module:setDelayedUpdate(ctAddon, value);
end

local function addon_OverrideActionBar_GetMicroButtonAnchor()
	-- This is a modified version of OverrideActionBar_GetMicroButtonAnchor() from OverrideActionBar.lua
	local hasExit, hasPitch = OverrideActionBar.leaveFrame:IsShown(),  OverrideActionBar.pitchFrame:IsShown();
	local x, y = 544 , 41;
	if hasExit and hasPitch then
		x = 628;
	elseif hasPitch then
		x = 632;
	elseif hasExit then
		x = 540;
	end
	return x,y
end

--------------------------------------------
-- Our UI

local function addon_UpdateOrientation_OurUI(self, orientation)
	-- Orient for our UI.
	-- self == our menu bar object
	-- orientation == "ACROSS" or "DOWN"
	local frames = self.frames;
	local obj;

	orientation = orientation or "ACROSS";

	for i = 2, #frames do
		obj = frames[i];
		setparent(obj, self.frame);
		obj:EnableMouse(true);
		obj:ClearAllPoints();
		obj:Show();
	end

	for i = 3, #frames do
		obj = frames[i];
		if (orientation == "ACROSS") then
			setpoint(obj, "LEFT", frames[i-1], "RIGHT", -1 + (appliedOptions.microButtonSpacing or module:getGameVersion() >= 10 and 0 or -3), 0)
		else
			setpoint(obj, "TOP", frames[i-1], "BOTTOM", 0, 1 - (appliedOptions.microButtonSpacing or 0));  	-- was 0, 1 before CTMod 10.0.0.x
		end
	end

	obj = frames[2];  -- CharacterMicroButton
	setpoint(obj, "BOTTOMLEFT", self.frame, 0, -2);
end

local function addon_Update_OurUI(self)
	-- Update and orient for our UI.
	-- self == our menu bar object

	-- Anchor the left and right most buttons to our helper frame.
	local objChar = CharacterMicroButton;  -- Left most button
	local objHelp = MainMenuMicroButton;  -- Right most button
	local frame = self.helperFrame;
	frame:ClearAllPoints();
	frame:SetPoint("TOPLEFT", objChar, "TOPLEFT", -3, 3);
	frame:SetPoint("BOTTOMRIGHT", objHelp, "BOTTOMRIGHT", 3, -3);

	-- Orient for our UI.
	addon_UpdateOrientation_OurUI(self, self.orientation);
end

--------------------------------------------
-- Override UI

local function addon_Update_OverrideUI(self)
	-- Update and orient for the override UI.
	-- self == menu bar object
	local bar = OverrideActionBar;
	local parent = OverrideActionBar;  -- parent frame for the micro buttons
	local frames = self.frames;
	local obj;

	for i = 2, #frames do
		obj = frames[i];
		setparent(obj, parent);
		obj:EnableMouse(true);
		obj:ClearAllPoints();
		obj:Show();
	end

	for i = 3, #frames do
		obj = frames[i];
		setpoint(obj, "LEFT", frames[i-1], "RIGHT", -1, 0);	-- was -3, 0 before CTMod 10.0.0.x
	end

	local anchorX, anchorY = addon_OverrideActionBar_GetMicroButtonAnchor();

	local obj1 = frames[2];  -- CharacterMicroButton
	local obj2 = frames[8];  -- LFDMicroButton

	obj1:ClearAllPoints();
	setpoint(obj1, "BOTTOMLEFT", bar, "BOTTOMLEFT", anchorX, anchorY);

	obj2:ClearAllPoints();
	setpoint(obj2, "TOPLEFT", obj1, "BOTTOMLEFT", 0, 0);
end

local function addon_UpdateOrientation_OverrideUI(self, orientation)
	-- Orient for the override UI.
	-- self == menu bar object
	-- orientation == "ACROSS" or "DOWN"
	
	-- Update and orient for the override UI.
	addon_Update_OverrideUI(self);
end

--------------------------------------------
-- Pet Battle UI

local function addon_Update_PetBattleUI(self)
	-- Update and orient for the pet battle UI.
	-- self == menu bar object
	local bar = PetBattleFrame.BottomFrame.MicroButtonFrame;
	local parent = bar;  -- parent frame for the micro buttons
	local frames = self.frames;
	local obj;

	for i = 2, #frames do
		obj = frames[i];
		setparent(obj, parent);
		obj:EnableMouse(true);
		obj:ClearAllPoints();
		obj:Show();
	end

	for i = 3, #frames do
		obj = frames[i];
		setpoint(obj, "LEFT", frames[i-1], "RIGHT", -1, 0)	-- was -3, 0 before CTMod 10.0.0.x
	end

	local anchorX, anchorY = -9, 25;

	local obj1 = frames[2];  -- CharacterMicroButton
	local obj2 = frames[8];  -- LFDMicroButton

	obj1:ClearAllPoints();
	setpoint(obj1, "BOTTOMLEFT", bar, "BOTTOMLEFT", anchorX, anchorY);

	obj2:ClearAllPoints();
	setpoint(obj2, "TOPLEFT", obj1, "BOTTOMLEFT", 0, 2);
end

local function addon_UpdateOrientation_PetBattleUI(self, orientation)
	-- Orient for the pet battle UI.
	-- self == menu bar object
	-- orientation == "ACROSS" or "DOWN"
	
	-- Update and orient for the pet battle UI.
	addon_Update_PetBattleUI(self);
end

--------------------------------------------
-- Orient the bar.

local function addon_UpdateOrientation(self, orientation)
	-- Orient the bar.
	-- self == menu bar object
	-- orientation == "ACROSS" or "DOWN"
	if (isBusy()) then
		setDelayedUpdate(1);
		return;
	end

	-- Check for a vehicle or override UI.
	if (module:hasPetBattleUI()) then
		if (not appliedOptions.petbattleHideFrame) then
			addon_UpdateOrientation_PetBattleUI(self, orientation);
			return;
		end
	elseif (module:hasVehicleUI()) then
		if (not appliedOptions.vehicleHideFrame) then
			addon_UpdateOrientation_OverrideUI(self, orientation);
			return;
		end
	elseif (module:hasOverrideUI()) then
		if (not appliedOptions.overrideHideFrame) then
			addon_UpdateOrientation_OverrideUI(self, orientation);
			return;
		end
	end

	-- Orient for our UI.
	addon_UpdateOrientation_OurUI(self, orientation);
end

--------------------------------------------
-- Update the bar

local function addon_Update(self)
	-- Update the bar.
	-- self == menu bar object
	if (isBusy()) then
		setDelayedUpdate(1);
		return;
	end

	-- Check for a vehicle or override UI.
	if (module:hasPetBattleUI()) then
		if (not appliedOptions.petbattleHideFrame) then
			addon_Update_PetBattleUI(self);
			return;
		end
	elseif (module:hasVehicleUI()) then
		if (not appliedOptions.vehicleHideFrame) then
			addon_Update_OverrideUI(self);
			return;
		end
	elseif (module:hasOverrideUI()) then
		if (not appliedOptions.overrideHideFrame) then
			addon_Update_OverrideUI(self);
			return;
		end
	end

	-- Update for our UI.
	addon_Update_OurUI(self);
end

local function addon_OnDelayedUpdate(self, value)
	-- Perform a delayed update.
	-- self == menu bar object
	-- value == value that was passed to module:setDelayedUpdate()
	-- Returns: true if delayed update was completed.
	--          false, nil == the delayed update was not completed.
	self:update();
	return true;
end

--------------------------------------------
-- Movement Hooks

local function addon_Hooked_MicroButton_SetPoint(...)
	if (ctAddon.isDisabled) then
		return;
	end
	setDelayedUpdate(1);
end

local function addon_Hooked_MicroButton_SetParent(self, parent)
	if (ctAddon.isDisabled) then
		-- If the default action bar is disabled...
		if (module.actionBarDisabled) then
			-- Only do this if the menu bar and the default action bar
			-- have both been disabled.
--			self:EnableMouse(true);
		end
		return;
	end
	setDelayedUpdate(1);
end

local function addon_Hooked_UpdateMicroButtons()
	if (ctAddon.isDisabled) then
		return;
	end
	setDelayedUpdate(1);
end

local function addon_Hooked_UpdateMicroButtonsParent(parent)
	if (ctAddon.isDisabled) then
		return;
	end
	setDelayedUpdate(1);
end

local function addon_Hooked_MoveMicroButtons(anchor, achorTo, relAnchor, x, y, isStacked)
	if (ctAddon.isDisabled) then
		return;
	end
	setDelayedUpdate(1);
end

--[[
	-- As of WoW 4.0 Blizzard is using special large bonus action
	-- bar frames for some quest items, etc. The frame looks similar
	-- to the vehicle frame, but is just for bonus bar actions.
	--
	-- Blizzard uses an animation to slide the MainMenuBar and
	-- the BonusActionBarFrame in/out. At the end of the animation
	-- they move the exp bar and micro buttons.
	--
	-- Note: If we hide the BonusActionBarFrame using something like a visibility
	-- state driver, the animation "out" finishes, but the next animation "in"
	-- doesn't complete (self.nextAnimBar.slideout:IsPlaying() stays true).
	-- Until it finishes our buttons will not appear in the correct spot.
	-- If we try to move them before the animation finishes then we end up with
	-- them in the wrong spot. Setting the BonusActionBarFrame's alpha to 0
	-- does not cause this issue (although disabling the mouse for the frame doesn't
	-- affect BonusActionBar1, etc).
	--
	-- An alternate approach is to hook UpdateMicroButons() which Blizzard calls
	-- right after repositioning the buttons and before they start to play the
	-- animation. This also prevents the buttons from lingering in sight on the
	-- bars during the animation.
	-- 
	-- Another alternative is to hooksecurefunc each micro button's SetPoint.
	--
	-- self == The bar being animated
	--
	-- Only do the update if these conditions are true.
	-- Doing it at any other time will result in the buttons being positioned
	-- lower on the screen than expected. These two conditions are the only
	-- ones in Blizzard's routine which do not cause an animation group to
	-- start playing.
	--
	--if ((self.animOut and not self.nextAnimBar) or (not self.animOut)) then
	--	addon_Update(ctAddon);
	--	ctAddon:updateDragVisibility(nil);
	--end
	--
	-- At some point (during 4.3.?) the calls to addon_update() started
	-- causing the micro buttons to get stuck some distance below the bar,
	-- so Blizzard may have changed something.
	-- To avoid this we are now trying to wait until after the animations
	-- have finished and then we will call addon_update() during the
	-- next OnUpdate.
--]]

--------------------------------------------
-- HelpTip Hooks

-- Prevents help tips from being off screen (ie, the "you need to select a talent" message)

local function configureHelpTips()
	if (HelpTip) then  -- not in Classic
		local lastParent, lastInfo, lastRelativeRegion

		local function addon_Hooked_HelpTip_Show(__, parent, info, relativeRegion)
			lastParent, lastInfo, lastRelativeRegion = parent, info, relativeRegion
		end

		local function addon_Hooked_MicroButton_ShowAlert(microButton)
			if (lastRelativeRegion == microButton and ctAddon.isDisabled == false) then
				if (ctAddon.orientation == "DOWN") then
					HelpTip:HideAllSystem("MicroButtons")
					lastInfo.targetPoint = microButton:GetLeft() > UIParent:GetRight()/2 and HelpTip.Point.LeftEdgeCenter or HelpTip.Point.RightEdgeCenter
					HelpTip:Show(lastParent, lastInfo, lastRelativeRegion)
				elseif (microButton:GetBottom() > UIParent:GetTop()/2) then
					HelpTip:HideAllSystem("MicroButtons")
					lastInfo.targetPoint = HelpTip.Point.BottomEdgeCenter
					HelpTip:Show(lastParent, lastInfo, lastRelativeRegion)
				end
			end
		end

		hooksecurefunc(HelpTip, "Show", addon_Hooked_HelpTip_Show)
		hooksecurefunc("MainMenuMicroButton_ShowAlert", addon_Hooked_MicroButton_ShowAlert)
	end
end

--------------------------------------------
-- Enable, disable, initialize, register.

local function addon_Disable(self)
	-- This bar is being deactivated.
	if (module:hasPetBattleUI()) then
		addon_Update_PetBattleUI(self);
	elseif (module:hasVehicleUI()) then
		addon_Update_OverrideUI(self);
	elseif (module:hasOverrideUI()) then
		addon_Update_OverrideUI(self);
	end
end

local function addon_Init(self)
	-- Initialization
	-- self == menu bar object
	appliedOptions = module.appliedOptions;

	ctAddon = self;
	module.ctMenuBar = self;

	if MainMenuBartArtFrame then
		self.frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1)
	end

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	setpoint = frame.SetPoint;
	setparent = frame.SetParent;

	-- (from MainMenuBarMicroButtons.lua)
	hooksecurefunc("UpdateMicroButtons", addon_Hooked_UpdateMicroButtons);
	hooksecurefunc("UpdateMicroButtonsParent", addon_Hooked_UpdateMicroButtonsParent);
	hooksecurefunc("MoveMicroButtons", addon_Hooked_MoveMicroButtons);

	configureHelpTips()

	return true;
end

local function addon_PostInit(self)
	-- Post initialization
	-- self == menu bar object
	
	-- Hook each micro button's SetPoint and SetParent function.
	local frames = self.frames;
	for i = 2, #frames do
		hooksecurefunc(frames[i], "SetPoint", addon_Hooked_MicroButton_SetPoint);
		hooksecurefunc(frames[i], "SetParent", addon_Hooked_MicroButton_SetParent);
	end
	
	-- Apply scaling
	function module.rescaleMicroButtons(scale)
		scale = Clamp(scale or 1, 0.8, 1.2)
		for i= 2, #frames do
			frames[i]:SetScale(scale)
		end
		addon_Update_OurUI(self)
	end
	
	module.rescaleMicroButtons(module:getOption("rescaleMicroButtons"))
	
end

local function addon_Register()

	local allButtons =
	{
		CharacterMicroButton,
		SpellbookMicroButton,
		TalentMicroButton,
		AchievementMicroButton,
		QuestLogMicroButton,
		GuildMicroButton or SocialsMicroButton,
		WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and (C_Seasons.HasActiveSeason() and LFGMicroButton or WorldMapMicroButton) or LFGMicroButton or LFDMicroButton,
		CollectionsMicroButton,
		EJMicroButton,
		StoreMicroButton,
		MainMenuMicroButton,		-- Retail has both, but the latter is not useful when the former is available
		WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE and HelpMicroButton or nil,
		PVPMicroButton,		
	}
	
	local realButtons = {}	-- classic vs retail
	
	for i=1, 13 do
		if allButtons[i] then
			tinsert(realButtons, allButtons[i])
		end
	end

	module:registerAddon(
		"Menu Bar",  -- option name
		"MenuBar",  -- used in frame names
		module.text["CT_BottomBar/Options/MenuBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/MenuBar"],  -- title for horizontal orientation
		"Menu",  -- title for vertical orientation
		module:getGameVersion() >= 8 and { "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 36, 28 } or { "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 40, 4 },
		{ -- settings
			orientation = "ACROSS",
			usedOnVehicleUI = true,
			usedOnOverrideUI = true,
			usedOnPetBattleUI = true,
			OnDelayedUpdate = addon_OnDelayedUpdate,
		},
		addon_Init,
		addon_PostInit,
		nil,  -- no config function
		addon_Update,
		addon_UpdateOrientation,
		nil,  -- no enable function
		addon_Disable,
		"helperFrame", -- 1
		unpack(realButtons)
	)
end

module.loadedAddons["Menu Bar"] = addon_Register;
