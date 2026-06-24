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
-- Vehicle tools bar

-- Game UI elements referenced:
--
-- OverrideActionBar
-- OverrideActionBarLeaveFrame
-- OverrideActionBarLeaveFrameExitBG
-- OverrideActionBarLeaveFrameLeaveButton
-- OverrideActionBarPitchFrame
-- OverrideActionBarPitchFramePitchBG
-- OverrideActionBarPitchFramePitchUpButton,
-- OverrideActionBarPitchFramePitchDownButton

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctAddon;
local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

--------------------------------------------
-- Misc

local function isBusy()
	return module:isBlizzardAnimating();
end

local function setDelayedUpdate(value)
	module:setDelayedUpdate(ctAddon, value);
end

--------------------------------------------
-- Our UI

local function addon_UpdateOrientation_OurUI(self, orientation)
	-- Orient for our UI.
	-- self == our vehicle tools bar object
	-- orientation == "ACROSS" or "DOWN"
	local frames = self.frames;
	local offset;
	local obj;
	local attach;
	local frame_SetAlpha = module.frame_SetAlpha;
	local frame_EnableMouse = module.frame_EnableMouse;
	local leaveButton2 = CT_BottomBar_MainMenuBarVehicleLeaveButton;

	orientation = orientation or "ACROSS";

	for i = 2, #frames do
		obj = frames[i];
		frame_SetAlpha(obj, obj.ctUseAlpha);
		frame_EnableMouse(obj, obj.ctUseMouse);
		obj:SetParent(self.frame);
		obj:ClearAllPoints();
	end
	leaveButton2:ClearAllPoints();
	
	local pitchFrame = OverrideActionBarPitchFrame;
	local pitchUp = pitchFrame.PitchUpButton;
	local pitchDown = pitchFrame.PitchDownButton;

	for i = 2, #frames do
		obj = frames[i];
		if (i == 2) then
			obj:SetPoint("BOTTOMLEFT", self.frame);
			leaveButton2:SetPoint("BOTTOMLEFT", self.frame);
			offset = 10;
		else
			attach = true;
			if ( 
				(obj == pitchUp or obj == pitchDown ) and
				(not appliedOptions.vehicleBarAimButtons)
			) then
				-- This is one of the aim buttons, and user does not want to see it
				-- on the vehicle bar, so don't attach it.
				attach = false;
			end
			if (attach) then
				if (orientation == "ACROSS") then
					obj:SetPoint("LEFT", frames[i-1], "RIGHT", offset, 0);
				else
					obj:SetPoint("TOP", frames[i-1], "BOTTOM", 0, -offset);
				end
				offset = 2;
			end
		end
	end
end

local function addon_Update_OurUI(self)
	-- Update and orient for our UI.
	-- self == our vehicle tools bar object
	local bar = OverrideActionBar;
	local leaveFrame = bar.leaveFrame;
	local pitchFrame = bar.pitchFrame;
	local frame_SetAlpha = module.frame_SetAlpha;
	local frame_EnableMouse = module.frame_EnableMouse;

	local button;
	local height = 30;
	local width = 30;
	local parent = self.helperFrame;
	local hasVehicleUI = module:hasVehicleUI();
	local canExitVehicle = CanExitVehicle();
	local showPitch = appliedOptions.vehicleBarAimButtons and hasVehicleUI and IsVehicleAimAngleAdjustable();

	-- Prepare the Leave button.
	button = leaveFrame.LeaveButton;
	button.ctInUse = true;  -- Now using this button.
	button.ctUseAlpha = 1;
	button.ctUseMouse = true;
	frame_SetAlpha(button, button.ctUseAlpha);
	frame_EnableMouse(button, button.ctUseMouse);
	button:SetHeight(height);
	button:SetWidth(width);
	button:SetParent(self.frame);
	if (canExitVehicle and hasVehicleUI) then
		button:Show();
	else
		button:Hide();
	end
	
	local leaveButton = button;

	-- Prepare the standalone Leave button.
	button = CT_BottomBar_MainMenuBarVehicleLeaveButton;
	button:SetHeight(height);
	button:SetWidth(width);
	button:SetParent(self.frame);
	if (canExitVehicle and not hasVehicleUI) then
		button:Show();
	else
		button:Hide();
	end

	-- Prepare the pitch up button.
	button = pitchFrame.PitchUpButton;
	button.ctInUse = true;  -- Now using this button.
	button.ctUseAlpha = 1;
	button.ctUseMouse = true;
	frame_SetAlpha(button, button.ctUseAlpha);
	frame_EnableMouse(button, button.ctUseMouse);
	button:SetHeight(height);
	button:SetWidth(width);
	button:SetParent(self.frame);
	if (showPitch) then
		button:Show();
	else
		button:Hide();
	end

	-- Prepare the pitch down button.
	button = pitchFrame.PitchDownButton;
	button.ctInUse = true;  -- Now using this button.
	button.ctUseAlpha = 1;
	button.ctUseMouse = true;
	frame_SetAlpha(button, button.ctUseAlpha);
	frame_EnableMouse(button, button.ctUseMouse);
	button:SetHeight(height);
	button:SetWidth(width);
	button:SetParent(self.frame);
	if (showPitch) then
		button:Show();
	else
		button:Hide();
	end

	-- Anchor our frame around the left and right most buttons.
	-- Start out with the Leave button being both the left and right most button.
	local objLeft = leaveFrame.LeaveButton;  -- Left most button
	local objRight = objLeft;  -- Right most button
	if (appliedOptions.vehicleBarAimButtons) then
		-- User wants to reserve space for the aiming buttons (even if not being shown on this vehicle).
		-- Assign the PitchDownButton as the right most button.
		objRight = pitchFrame.PitchDownButton;
	end
	local frame = self.helperFrame;
	frame:ClearAllPoints();
	frame:SetPoint("TOPLEFT", objLeft);
	frame:SetPoint("BOTTOMRIGHT", objRight);

	-- Orient for our UI.
	addon_UpdateOrientation_OurUI(self, self.orientation);
end

--------------------------------------------
-- Override UI

local function addon_Update_OverrideUI(self)
	-- Update and orient for the override UI.
	-- self == our vehicle tools bar object

	-- (Size, SetParent, and SetPoint info are from OverrideActionBar.xml)
	-- We also need to make sure the buttons are shown, since that is the expected
	-- state of the buttons in the default UI (it hides the parent frame when the
	-- buttons should not be visible).
	local bar, button;
	local leaveFrame, pitchFrame;
	local frame_SetAlpha = module.frame_SetAlpha;
	local frame_EnableMouse = module.frame_EnableMouse;

	bar = OverrideActionBar;
	leaveFrame = bar.leaveFrame;
	pitchFrame = bar.pitchFrame;

	-- Update the Leave button in the vehicle frame.
	button = leaveFrame.LeaveButton;
	button.ctInUse = nil;  -- No longer using this button.
	frame_SetAlpha(button, button.ctSaveAlpha);
	frame_EnableMouse(button, button.ctSaveMouse);
	button:SetSize(42, 42);
	button:ClearAllPoints();
	button:SetPoint("CENTER", leaveFrame.ExitBG, 0, -5);
	button:SetParent(leaveFrame);
	button:Show();

	-- Our standalone leave vehicle button.
	button = CT_BottomBar_MainMenuBarVehicleLeaveButton;
	button:Hide();

	-- Update the Pitch Up and Pitch Down buttons in the vehicle frame.
	button = pitchFrame.PitchUpButton;
	button.ctInUse = nil;  -- No longer using this button.
	frame_SetAlpha(button, button.ctSaveAlpha);
	frame_EnableMouse(button, button.ctSaveMouse);
	button:SetSize(34, 34);
	button:ClearAllPoints();
	button:SetPoint("CENTER", pitchFrame.PitchButtonBG, 0, 14);
	button:SetParent(pitchFrame);
	button:Show();

	button = pitchFrame.PitchDownButton;
	button.ctInUse = nil;  -- No longer using this button.
	frame_SetAlpha(button, button.ctSaveAlpha);
	frame_EnableMouse(button, button.ctSaveMouse);
	button:SetSize(34, 34);
	button:ClearAllPoints();
	button:SetPoint("CENTER", pitchFrame.PitchButtonBG, 0, -22);
	button:SetParent(pitchFrame);
	button:Show();

end

local function addon_UpdateOrientation_OverrideUI(self, orientation)
	-- Orient for the override UI.
	-- self == our vehicle tools bar object
	-- orientation == "ACROSS" or "DOWN"
	
	-- Update and orient for the override UI.
	addon_Update_OverrideUI(self);
end

--------------------------------------------
-- Orient the bar.

local function addon_UpdateOrientation(self, orientation)
	-- Orient the bar.
	-- self == our vehicle tools bar object
	-- orienation == "ACROSS" or "DOWN"
	if (isBusy()) then
		setDelayedUpdate(1);
		return;
	end

	-- Check for a vehicle UI.
	if (module:hasVehicleUI()) then
		if (not appliedOptions.vehicleHideFrame) then
			addon_UpdateOrientation_OverrideUI(self, orientation);
			return;
		end
	end

	-- Orient for our UI.
	addon_UpdateOrientation_OurUI(self, orientation);
end

--------------------------------------------
-- Update the bar.

local function addon_Update(self)
	-- Update the bar.
	-- self == our vehicle tools bar object
	if (isBusy()) then
		setDelayedUpdate(1);
		return;
	end

	-- Check for a vehicle UI.
	if (module:hasVehicleUI()) then
		if (not appliedOptions.vehicleHideFrame) then
			addon_Update_OverrideUI(self);
			return;
		end
	end

	-- Update for our UI.
	addon_Update_OurUI(self);
end

local function addon_OnDelayedUpdate(self, value)
	-- Perform a delayed update.
	-- self == vehicle tools bar object
	-- value == value that was passed to module:setDelayedUpdate()
	-- Returns: true if delayed update was completed.
	--          false, nil == the delayed update was not completed.
	self:update();
	return true;
end

local function addon_OnAnimFinished(self)
	-- Called after the Main Menu Bar and Override Action Bars
	-- have finished animating.
	-- self == vehicle tools bar object
	self:update();
end

--------------------------------------------
-- Hooks

local function addon_Hooked_MainMenuBarVehicleLeaveButton_Update()
	if (ctAddon.isDisabled) then
		return;
	end
	-- The game shows a vehicle leave button when the vehicle that the player
	-- is in does not have its own vehicle UI. This is a different button than
	-- the one the game displays on the vehicle menu bar when the player has
	-- a vehicle UI.
	--
	-- We're going to keep Blizzard's leave button hidden and show our
	-- version of their button on our vehicle tools bar.
	--
	-- We're keeping Blizzard's leave button hidden because its visibility
	-- affects things like the position of the default pet bar.
	-- (see PetActionBarFrame.lua and UIParent.lua).
	setDelayedUpdate(1);
end

local function addon_Hooked_OverrideActionBar_CalcSize()
	if (ctAddon.isDisabled) then
		return;
	end
--	setDelayedUpdate(1);
	
	if (MainMenuBar.slideOut and not MainMenuBar.slideOut:IsPlaying() or OverrideActionBar.slideOut and OverrideActionBar.slideOut:IsPlaying()) then
		-- Get items back on default UI frames before they start to be animated.
		addon_Update_OverrideUI();
	end
end

--local function addon_Hooked_OverrideActionBar_Setup()
--	if (ctAddon.isDisabled) then
--		return;
--	end
----	setDelayedUpdate(1);
-- --addon_Update_OverrideUI();
--end

local function addon_Hooked_MainMenuBarVehicleLeaveButton_OnShow(self)
	-- The only time Blizzard shows this button is during MainMenuBarVehicleLeaveButton_Update
	-- which is in MainMenuBar.lua. They show it right after they've positioned the button, and
	-- before they call ShowPetActionBar(true).
	if (ctAddon.isDisabled) then
		return;
	end
	-- Keep Blizzard's leave vehicle button hidden since we will be
	-- using our own button on the vehicle tools bar.
	self:Hide();
end

--------------------------------------------
-- Enable, disable, initialize, register.

local function addon_Enable(self)
	-- This bar is being activated.

	-- Hide Blizzard's standalone leave vehicle button.
	-- We'll be using our own button instead.
	MainMenuBarVehicleLeaveButton:Hide();
end

local function addon_Disable(self)
	-- This bar is being deactivated.

	-- Update buttons as if they are on the default vehicle frame.
	-- This ensures they are back in their normal locations when
	-- we deactivate our bar.
	-- It also hides our standalone leave vehicle button.
	addon_Update_OverrideUI(self);

	-- Show Blizzard's standalone leave vehicle button if applicable.
	-- ("if" logic is from MainMenuBarVehicleLeaveButton_Update() in MainMenuBar.lua)
	if (CanExitVehicle() and ActionBarController_GetCurrentActionBarState() == LE_ACTIONBAR_STATE_MAIN) then
		MainMenuBarVehicleLeaveButton:Show();
	end
end

--------------------------------------------
-- Leave vehicle button

local function create_CT_BottomBar_MainMenuBarVehicleLeaveButton()
	local button = CreateFrame("Button", "CT_BottomBar_MainMenuBarVehicleLeaveButton");
	button:SetWidth(32);
	button:SetHeight(32);
	button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
	button:SetScript("OnEvent",
		function(self, event)
			if (ctAddon) then
				ctAddon:update();
			end
		end
	);
	button:SetScript("OnClick",
		function(self, button)
			VehicleExit();
		end
	);
	button:SetScript("OnEnter",
		function(self)
			module:displayTooltip(self, LEAVE_VEHICLE, "CT_ABOVEBELOW");
		end
	);
	button:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up");
	button:GetNormalTexture():SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375);
	button:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down");
	button:GetPushedTexture():SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375);
	button:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Highlight");
	button:GetHighlightTexture():SetTexCoord(0.130625, 0.879375, 0.120625, 0.879375);
	button:Hide();
end

local function addon_Init(self)
	-- Initialization
	-- self == our vehicle tools bar object
	appliedOptions = module.appliedOptions;

	ctAddon = self;
	module.ctVehicleBar = self;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;
	
	-- Create a leave vehicle button for use when the player
	-- can exit the vehicle, but they don't have a vehicle UI.
	create_CT_BottomBar_MainMenuBarVehicleLeaveButton();

	-- We can't create our own buttons for the pitch up and pitch down functions
	-- because the functions are only available to the Blizzard UI. We need to move
	-- Blizzard's buttons onto our frame when they are not visible on the vehicle frame.
	--
	-- The restricted functions are: VehicleAimUpStart, VehicleAimUpStop,
	-- VehicleAimDownStart, and VehicleAimDownStop.
	--
	-- The buttons are not secure so we can reposition them during combat.

	-- (from MainMenuBar.lua)
	-- This is the routine where Blizzard shows or hides a vehicle leave button
	-- when the player does not have a vehicle ui.
	if MainMenuBarVehicleLeaveButton_Update then
		hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", addon_Hooked_MainMenuBarVehicleLeaveButton_Update)
		hooksecurefunc("OverrideActionBar_CalcSize", addon_Hooked_OverrideActionBar_CalcSize);
	else
		hooksecurefunc(MainMenuBarVehicleLeaveButton, "Update", addon_Hooked_MainMenuBarVehicleLeaveButton_Update)
		hooksecurefunc(OverrideActionBar, "CalcSize", addon_Hooked_OverrideActionBar_CalcSize);
	end

	-- (from OverrideActionBar.lua)
	
--	hooksecurefunc("OverrideActionBar_Setup", addon_Hooked_OverrideActionBar_Setup);

	-- Hook the OnShow script of the MainMenuBarVehicleLeaveButton.
	MainMenuBarVehicleLeaveButton:HookScript("OnShow", addon_Hooked_MainMenuBarVehicleLeaveButton_OnShow);
end

local function addon_Register()
	module:registerAddon(
		"Vehicle Bar",  -- option name
		"VehicleToolsBar",  -- used in frame names
		"Vehicle Tools Bar",  -- shown in options window & tooltips
		"Vehicle",  -- title for horizontal orientation
		"Vehicle",  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 269, 107 },
		{ -- settings
			usedOnVehicleUI = true,
			orientation = "ACROSS",
			OnDelayedUpdate = addon_OnDelayedUpdate,
			OnAnimFinished = addon_OnAnimFinished,
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		addon_UpdateOrientation,
		addon_Enable,
		addon_Disable,
		"helperFrame", -- 1
		OverrideActionBar.leaveFrame.LeaveButton, -- 2
		OverrideActionBar.pitchFrame.PitchUpButton, -- 3
		OverrideActionBar.pitchFrame.PitchDownButton -- 4
	);
end

module.loadedAddons["Vehicle Bar"] = addon_Register;
