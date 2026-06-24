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
--                                            --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes since 2018        --
--                                            --
-- This file provides the core functionality, --
-- together with CT_BottomBar_Addon.lua that  --
-- forms the basis for all the custom bars.   --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_BottomBar";
local MODULE_VERSION = strmatch(C_AddOns.GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);
local L = module.text;	-- see localization.lua

module.loadedAddons = {};

local appliedOptions;
local pendingOptions;

--------------------------------------------
-- Secure frame

local function secureFrame_update_unsecure(self, name, value)
	-- self == our secure frame
	if (name == "has-vehicleui" or name == "has-overridebar" or name == "has-petbattle") then
		module:updateAllVisibility();
	end
end

local secureFrame_OnAttributeChanged = [=[
	-- Parameters: self, name, value
	-- self == our secure frame
	-- name == name of attribute
	-- value == value of attribute
	if (name == "state-vehicleui") then
		self:SetAttribute("has-vehicleui", value);
	elseif (name == "state-overridebar") then
		self:SetAttribute("has-overridebar", value);
	elseif (name == "state-possessbar") then
		self:SetAttribute("has-possessbar", value);
	elseif (name == "state-petbattle") then
		self:SetAttribute("has-petbattle", value);
	end

	self:CallMethod("update_unsecure", name, value);
]=];

local function initSecureFrame()
	local frame = CT_BottomBar_SecureFrame;

	-- Set the attribute that will tell the game which secure snippet to use when an attribute changes.
	frame:SetAttribute("_onattributechanged", secureFrame_OnAttributeChanged);

	-- An unsecure method to be called.
	frame.update_unsecure = secureFrame_update_unsecure;

	-- Detect when the vehicleui state changes.
	RegisterStateDriver(frame, "vehicleui", "[vehicleui]1;nil");
	
	-- Detect when the overridebar state changes.
	RegisterStateDriver(frame, "overridebar", "[overridebar]1;nil");

	-- Detect when the possessbar state changes.
	RegisterStateDriver(frame, "possessbar", "[possessbar]1;nil");

	-- Detect when the petbattle state changes.
	RegisterStateDriver(frame, "petbattle", "[petbattle]1;nil");
end

--------------------------------------------
-- Fix CT_BarMod bar positioning issue when CT_BarMod loads before CT_BottomBar.

local function fix_CT_BarMod_BarPositions()

	-- If this is a first run for CT_BarMod...
	if (CT_BarMod and CT_BarMod.isFirstRun and CT_BarMod:isFirstRun()) then

		if (CT_BarMod.resetAllBarPositions) then
			-- Reset the position of all CT_BarMod bars.
			-- This fixes a positioning issue with the bottom left and right
			-- CT_BarMod bars when CT_BarMod loads before CT_BottomBar.
			--
			-- When CT_BarMod starts it can't detect CT_BottomBar since it
			-- isn't loaded yet. It defaults to placing the bottom left and
			-- right action bars above the exp bar. If CT_BottomBar later
			-- loads, those two action bars will then be covering the rep
			-- bar.
			--
			-- Now that CT_BottomBar has loaded, we'll reset the position
			-- of all bars, but only upon detecting a first run of CT_BarMod
			-- since the user won't have had a chance to move the bars
			-- anywhere yet.

			CT_BarMod.resetAllBarPositions();
		end
	end
end

--------------------------------------------
-- MainMenuBar and OverrideActionBar animations.

local animFlag;
local animCount = 0;

function module:animStarted()
	-- Called when a MainMenuBar or OverrideActionBar animation has started.
	animCount = animCount + 1;
	animFlag = true;
end

function module:animStopped()
	-- Called when a MainMenuBar or OverrideActionBar animation has stopped.
	animCount = animCount - 1;
	animFlag = true;
end

function module:isBlizzardAnimating()
	-- Returns true if Blizzard is animating the main menu bar or override bar.
	return animCount > 0;
end

--------------------------------------------
-- Performing delayed bar updates due to Blizzard animations.

local needDelayedUpdate;
local updateTable = {};

function module:getDelayedUpdate(addon)
	-- Get value of delayed update for specified addon.
	-- addon == addon object
	return updateTable[addon];
end

function module:setDelayedUpdate(addon, value)
	-- addon == addon object
	-- value == nil -- cancel delayed update
	--          ? -- value will be passed to the addon.settings.OnDelayedUpdate function.
	updateTable[addon] = value;
	if (value) then
		needDelayedUpdate = true;
	end
end

local function performDelayedUpdates()
	-- Perform bar updates when animations have finished.
	--
	-- We want to delay certain bar updates if the MainMenuBar or the OverrideActionBar
	-- are being animated by Blizzard, and then perform the update during the next OnUpdate.
	-- If we try to manipulate some of the things parented to a bar being animated, then
	-- the items or their textures may get stuck out of position.
	-- For example, trying to move the micro buttons before the animations finish can
	-- result in the button textures being located some distance below the buttons, even
	-- though the texture's :GetPoint() is correct.
	if (not needDelayedUpdate) then
		return;
	end
	if (module:isBlizzardAnimating()) then
		return;
	end
	needDelayedUpdate = false;
	for addon, value in pairs(updateTable) do
		if (addon.settings.OnDelayedUpdate) then
			if (not addon.settings.OnDelayedUpdate(addon, value)) then
				-- The update was not completed. Try again next time.
				needDelayedUpdate = true;
			else
				updateTable[addon] = nil;
			end
		else
			updateTable[addon] = nil;
		end
	end
end

--------------------------------------------
-- Configuration

local function convertOldActionBarPosition(oldPosition, oldButtonScale)
	-- Convert the saved position of the old CT_BottomBar action bar drag frame
	-- into a position that can be used to reposition CT_BarMod's action bar frame.
	--
	-- Returns true if conversion worked, else false.
	-- Also returns table containing converted position information if conversion worked.

	if (not CT_BarMod.actionBarId) then
		return false;
	end

	local newDragFrame = _G["CT_BarMod_Group" .. CT_BarMod.actionBarId];
	local newButton = CT_BarModActionButton133;

	if (not newDragFrame or not newButton) then
		return false;
	end

	local oldAncP = oldPosition[1];
	local oldXOffset = oldPosition[4];
	local oldYOffset = oldPosition[5];

	-- The old drag frame.
	-- _G["CT_BottomBarAddon-Action Bar"]
	-- :GetWidth() == 30
	-- :GetHeight() == 1
	local oldDragWidth = 30;
	local oldDragHeight = 1;

	-- The first button that was attached to the old drag frame.
	-- ActionButton1
	-- :GetWidth() == 36
	-- :GetHeight() == 36
	-- :GetPoint() == "BOTTOMLEFT", _G["CT_BottomBarAddon-Action Bar"], "BOTTOMLEFT", 0, 0
	local oldButton = ActionButton1;
	local oldButtonWidth = 36;
	local oldButtonHeight = 36;

	oldButtonWidth = oldButtonWidth * oldButtonScale;
	oldButtonHeight = oldButtonHeight * oldButtonScale;

	-- The new drag frame.
	-- CT_BarMod_Group12
	-- :GetWidth() == 60
	-- :GetHeight() == 30
	local newDragWidth = newDragFrame:GetWidth() or 60;
	local newDragHeight = newDragFrame:GetHeight() or 30;

	-- The first button that is attached to the new drag frame.
	-- CT_BarModActionButton133
	-- :GetWidth() == 36
	-- :GetHeight() == 36
	-- :GetPoint() == "TOPLEFT", CT_BarMod_Group12, "BOTTOMLEFT", 12, -4
	local newButtonScale = oldButtonScale;  -- use same scale for new buttons
	local newButtonWidth = newButton:GetWidth() or 36;
	local newButtonHeight = newButton:GetHeight() or 36;
	local newAncP, newRelF, newRelP, newButtonXOffset, newButtonYOffset = newButton:GetPoint(1);
	newButtonXOffset = abs(newButtonXOffset or 12);
	newButtonYOffset = abs(newButtonYOffset or 4);

	newButtonWidth = newButtonWidth * newButtonScale;
	newButtonHeight = newButtonHeight * newButtonScale;
	newButtonXOffset = newButtonXOffset * newButtonScale;
	newButtonYOffset = newButtonYOffset * newButtonScale;

	local newXOffset;
	local newYOffset;

	if (oldAncP == "TOPLEFT" or oldAncP == "LEFT" or oldAncP == "BOTTOMLEFT") then
		newXOffset = oldXOffset - newButtonXOffset;

	elseif (oldAncP == "TOPRIGHT" or oldAncP == "RIGHT" or oldAncP == "BOTTOMRIGHT") then
		newXOffset = oldXOffset - oldDragWidth + (newDragWidth - newButtonXOffset);

	else -- if (oldAncP == "TOP" or oldAncP == "CENTER" or oldAncP == "BOTTOM") then
		newXOffset = oldXOffset - (oldDragWidth / 2) - newButtonXOffset + (newDragWidth / 2);
	end

	if (oldAncP == "TOPLEFT" or oldAncP == "TOP" or oldAncP == "TOPRIGHT") then
		newYOffset = oldYOffset + newButtonHeight + newDragHeight + newButtonYOffset;

	elseif (oldAncP == "BOTTOMLEFT" or oldAncP == "BOTTOM" or oldAncP == "BOTTOMRIGHT") then
		newYOffset = oldYOffset + newButtonHeight + newButtonYOffset;

	else -- if (oldAncP == "LEFT" or oldAncP == "CENTER" or oldAncP == "RIGHT") then
		newYOffset = oldYOffset + newButtonHeight + newButtonYOffset + (newDragHeight / 2);
	end

	return true, { oldPosition[1], oldPosition[2], oldPosition[3], newXOffset, newYOffset };
end

local function configureActionBar()
	-- Configure/disable the default main action bar.
	-- It may get disabled, CT_BarMod's main action may get enabled and moved, etc.

	local disableMainBar;
	local resetMainBarPos;

	-- Get the current value of the option to disable the default action bar.
	-- This option will only be nil once per character, or per reset of CT_BottomBar options.
	disableMainBar = module:getOption("disableDefaultActionBar");

	if (disableMainBar == nil) then
		-- This is a first run for CT_BottomBar.
		-- (new character, reset of options, or first time using this version)

		-- If CT_BarMod is loaded, and it supports a main action bar...
		if (CT_BarMod and CT_BarMod.actionBarId) then

			-- Disable the default main action bar.
			disableMainBar = true;

			-- Enable the CT_BarMod main action bar
			CT_BarMod:setOption("showGroup" .. CT_BarMod.actionBarId, 1);

			-- Reset position of CT_BarMod main action bar.
			resetMainBarPos = true;
		else
			-- CT_BarMod is not loaded, or
			-- This version of CT_BarMod does not support a main action bar.

			-- Do not disable the default main action bar.
			disableMainBar = false;
		end

	else
		-- Since the disableDefaultActionBar option has a value, this is not a first run for CT_BottomBar.

		if (disableMainBar and CT_BarMod and CT_BarMod.actionBarId) then
			-- We are going to disable the main action bar,
			-- and CT_BarMod is loaded,
			-- and this version of CT_BarMod supports a main action bar.

			-- If this is a first run for CT_BarMod...
			if (CT_BarMod.isFirstRun and CT_BarMod:isFirstRun()) then

				-- Enable the CT_BarMod main action bar
				CT_BarMod:setOption("showGroup" .. CT_BarMod.actionBarId, 1);

				-- Reset position of CT_BarMod main action bar.
				resetMainBarPos = true;
			end
		end
	end

	-- Possibly disable the game's default action and bonus action bars/buttons.
	-- The default if the option is nil, is true (disable the action bar).
	if ( disableMainBar ) then
		module:disableActionBar();
		-- Set a flag we can test for to see if the action bar is disabled.
		module.actionBarDisabled = true;
	else
		module.actionBarDisabled = false;
	end

	if (resetMainBarPos) then

		-- See if the user has saved data for the action bar from a previous version
		-- of CT_BottomBar.
		local oldPosition = module:getOption("MOVABLE-Action Bar");
		local oldOrientation = module:getOption("orientationAction Bar");
		local oldOpacity = module:getOption("barOpacity");
		local oldScale = module:getOption("barScale");
		local oldSpacing = module:getOption("barSpacing");
		local oldHide = module:getOption("Action Bar");  -- default was not to hide the bar

		local oldData = oldPosition or oldOrientation or oldOpacity or oldScale or oldSpacing or oldHide;

		-- Flag that indicates if we have already converted the old action bar data.
		local oldActionBarConvertedFlag = module:getOption("oldActionBarConvertedFlag");

		-- If we haven't already converted the old action bar data,
		-- and we have old data,
		-- and CT_BarMod is loaded,
		-- and CT_BarMod has the function we need...
		if (not oldActionBarConvertedFlag and oldData and CT_BarMod and CT_BarMod.updateActionBar) then

			-- Try to convert the old CT_BarMod action bar position.
			local converted, newPosition;
			if (oldPosition) then
				converted, newPosition = convertOldActionBarPosition(oldPosition, oldScale or 1);
			end
			if (not converted) then
				-- Will reset to default position instead.
				newPosition = false;
			end

			-- Update CT_BarMod's action bar.
			CT_BarMod.updateActionBar(
				newPosition,
				oldOrientation or "ACROSS",
				oldScale or 1,
				oldOpacity or 1,
				oldSpacing or 6,
				not not oldHide
			);

			-- Set a flag to keep us from using the old data more than once.
			module:setOption("oldActionBarConvertedFlag", true);

			-- If this is the first run for CT_BarMod...
			if (CT_BarMod.isFirstRun and CT_BarMod:isFirstRun()) then
				-- When CT_BarMod is first run, it automatically enables group ids 1 through 5,
				-- and disables group ids that are greater than 5.

				-- Disable the CT_BarMod action bars with group ids 1 through 5 (bars 2 through 6).
				for groupId = 1, 5 do
					CT_BarMod:setOption("showGroup" .. groupId, false);
				end
			end

		elseif (CT_BarMod and CT_BarMod.resetActionBarPosition) then
			-- Move the main action bar to where the default one is normally located.

			-- We couldn't have CT_BarMod reset the position of the ation bar until
			-- after we disabled the default bar, since CT_BarMod's reset function
			-- checks for a flag which indicates that the default main bar has been
			-- disabled.

			CT_BarMod.resetActionBarPosition();
		end
	end
end

local function configureThings()
	-- Configure the CT_BottomBar bars and environment.

	-- Initialize each addon
	for key, obj in ipairs(module.addons) do
		obj:init();
		if (not obj.isDisabled) then
			obj:setClamped(appliedOptions.clampFrames);
			obj:updateVisibility();
		end
	end

	-- Perform any additional configuration for each addon.
	for key, obj in ipairs(module.addons) do
		obj:config();
	end

	-- Configure MainMenuBar related items (gryphons, artwork).
	if module:getGameVersion() <= 9 then
		module:mainmenuConfigure();
	end
end

--------------------------------------------
-- OnUpdate function

local needOverrideUpdate;
function module:needOverrideUpdate(value)
	-- Inform the OnUpdate routine that we need to update the override bar.
	needOverrideUpdate = value;
end

local function CT_BottomBar_OnUpdateFunc(self, elapsed)
	if (animFlag) then
		if (not module:isBlizzardAnimating()) then
			animFlag = nil;
			for key, obj in ipairs(module.addons) do
				if (not obj.isDisabled) then
					if (obj.settings.OnAnimFinished) then
						obj.settings.OnAnimFinished(obj);
					end
				end
			end
		end
	end
	if (needDelayedUpdate) then
		performDelayedUpdates();
	end
	if (needOverrideUpdate) then
		module:override_OnUpdate(needOverrideUpdate);
	end
end

local function initOnUpdate()
	-- Set up an OnUpdate function.
	local frame = CT_BottomBar_Frame;
	frame:SetScript("OnUpdate", CT_BottomBar_OnUpdateFunc);
end

--------------------------------------------
-- Event handling

local function CT_BottomBar_EventFunc(self, event, arg1, arg2, arg3, ...)

	-- (WoW 3.x notes)
	-- If you reload the UI while in a vehicle, the PLAYER_ENTERING_VEHICLE and PLAYER_ENTERED_VEHICLE
	-- events occur *after* PLAYER_ENTERING_WORLD.
	-- However, if you /exit and click 'exit now', when you restart the game and log back in,
	-- the PLAYER_ENTERING_VEHICLE and PLAYER_ENTERED_VEHICLE events occur *before* PLAYER_ENTERING_WORLD.
	--
	-- (Wow 4.x)
	-- If you log out of the game in a vehicle, when you log back in you won't be in the
	-- vehicle anymore. I'm not sure if the game ejects you from the vehicle before logging out
	-- or when logging back in, or whether this happens for all vehicles or just some.
	-- In 3.x you used to end up back in the vehicle when you returned.

--	print(event, arg1, arg2, arg3, ...);

	if (event == "UNIT_ENTERED_VEHICLE") then
		-- Note: It is possible to enter one vehicle from another (no exited event appears).
		if (arg1 == "player") then
			module:updateBarVisibility();
		end
		module.vehicleSkinName = arg3;

	elseif (event == "UNIT_EXITED_VEHICLE") then
		if (arg1 == "player") then
			module:updateBarVisibility();
		end
		module.vehicleSkinName = nil;

	elseif (event == "PLAYER_ENTERING_WORLD") then
--		module:updateBarVisibility();
--		module:updateSpecialVisibility();
		module:updateAllVisibility();

	elseif (event == "PLAYER_REGEN_DISABLED") then
		-- About to enter combat lockdown.
		module:applyPendingOptions();

--		module:updateBarVisibility();
--		module:updateSpecialVisibility();
		module:updateAllVisibility();

	elseif (event == "PLAYER_REGEN_ENABLED") then
		-- Combat lockdown is now over.
		module:applyPendingOptions();

--		module:updateBarVisibility();
--		module:updateSpecialVisibility();
		module:updateAllVisibility();

	elseif (event == "PLAYER_LOGIN" and module:getGameVersion() <= 9) then
		-- Restore CT_BottomBar's gryphons setting.
		-- This will override CT_Core's setting.
		module:restoreGryphons();
	end
end

local function registerEvents()
	-- Rregister events.

	local frame = CT_BottomBar_Frame;

	if (VehicleMenuBar) then
		-- frame:RegisterEvent("UNIT_ENTERING_VEHICLE");
		-- frame:RegisterEvent("UNIT_EXITING_VEHICLE");
		frame:RegisterEvent("UNIT_ENTERED_VEHICLE");
		frame:RegisterEvent("UNIT_EXITED_VEHICLE");
	end

	frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	frame:RegisterEvent("PLAYER_REGEN_DISABLED");

	frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	frame:RegisterEvent("PLAYER_LOGIN");

	frame:SetScript("OnEvent", CT_BottomBar_EventFunc);
end

--------------------------------------------
-- UIParent_ManageFramePositions

local function CT_BottomBar_Hooked_UIParent_ManageFramePositions()
	-- (hooksecurefunc of UIParent_ManageFramePosition in UIParent.lua)
	-- This func and the hooks used to be at the end of the CT_BottomBar_ShapeshiftBar_Init function.

	for key, obj in ipairs(module.addons) do
		if (obj.settings and obj.settings.UIParent_ManageFramePositions) then
			obj.settings.UIParent_ManageFramePositions();
		end
	end
end

--------------------------------------------
-- Hook functions

local function hook_UIParent_ManageFramePositions()
	-- Hook the UIParent_ManageFramePositions function so we can make some adjustments.

	-- This hook catches the places where the function is called using its global name.
	hooksecurefunc("UIParent_ManageFramePositions", CT_BottomBar_Hooked_UIParent_ManageFramePositions);

	-- The following hooks are required for Blizzard xml scripts that use the following syntax to
	-- call UIParent_ManageFramePositions. This xml syntax does not call our secure hook of
	-- UIParent_ManageFramePositions, so we have to explicitly hook anything that calls it to
	-- ensure our function gets called.
	--
	-- 	<OnShow function="UIParent_ManageFramePositions"/>
	-- 	<OnHide function="UIParent_ManageFramePositions"/>

	if StanceBarFrame then
		-- From StanceBar.xml
		StanceBarFrame:HookScript("OnShow", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
		StanceBarFrame:HookScript("OnHide", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
	end
	
	if DurabilityFrame then
		-- From DurabilityFrame.xml
		DurabilityFrame:HookScript("OnShow", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
		DurabilityFrame:HookScript("OnHide", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
	end
	
	-- From PetActionBarFrame.xml
	if PetActionBarFrame then
		PetActionBarFrame:HookScript("OnShow", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
		PetActionBarFrame:HookScript("OnHide", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
	end
	
	if PossessBarFrame then	
		-- From PossessActionBarFrame.xml
		PossessBarFrame:HookScript("OnShow", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
		PossessBarFrame:HookScript("OnHide", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
	end
	
	if MultiCastActionBarFrame then
		-- From MultiCastActionBarFrame.xml
		MultiCastActionBarFrame:HookScript("OnShow", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
		MultiCastActionBarFrame:HookScript("OnHide", CT_BottomBar_Hooked_UIParent_ManageFramePositions)
	end
	

	-- From MainMenuBar.xml
	-- (Replaced with StatusTrackingBar in 8.0.1) MainMenuBarMaxLevelBar:HookScript("OnShow", CT_BottomBar_Hooked_UIParent_ManageFramePositions);
	-- (Replaced with StatusTrackingBar in 8.0.1) MainMenuBarMaxLevelBar:HookScript("OnHide", CT_BottomBar_Hooked_UIParent_ManageFramePositions);
	
	-- From ReputationFrame.xml
	-- (Replaced with StatusTrackingBar in 8.0.1) ReputationWatchBar:HookScript("OnHide", CT_BottomBar_Hooked_UIParent_ManageFramePositions);
	
end

local function hookFunctions()
	-- Hook various Blizzard functions.

	-- Hook the function Blizzard uses to position various bars on the screen, hide/show some textures, etc.
	hook_UIParent_ManageFramePositions();
end

--------------------------------------------
-- CT_BottomBar initialization

function module:update(optName, value)
	self:updateOption(optName, value)	-- CT_BottomBar_Options.lua
end

function module:init()
	-- Initialize CT_BottomBar.
	-- This will be the first code run by CT_Library once the game has loaded CT_BottomBar.

	-- Create a frame for the addon (used for events, etc).
	local frame = CreateFrame("Frame", "CT_BottomBar_Frame");
	module.frame_SetAlpha = frame.SetAlpha;
	module.frame_EnableMouse = frame.EnableMouse;

	-- Create the options tables.
	module.appliedOptions = {};
	module.pendingOptions = {};

	appliedOptions = module.appliedOptions;
	pendingOptions = module.pendingOptions;


	-- Create a secure frame
	local secureFrame = CreateFrame("Frame", "CT_BottomBar_SecureFrame", nil, "SecureFrameTemplate,SecureHandlerAttributeTemplate");
	initSecureFrame();

	-- Fix CT_BarMod bar positioning issue when CT_BarMod loads before CT_BottomBar.
	fix_CT_BarMod_BarPositions()


	
	-- Initialize some bars bar
	if (module:getGameVersion() >= 3) then
		module:initOverrideActionBar();
	end
	
	-- Make sure Blizzard managed frames are in position.
	UIParent_ManageFramePositions();
		
	-- Initialize some other lua files.
	if (module:getGameVersion()  >= 3) then	
		module:overrideInit();
	end
	
	-- Configure/disable the default main action bar
	if module:getGameVersion() <= 9 then
		-- prior to WoW 10.x
		configureActionBar();
		module:initMainMenuBar();
		module:mainmenuInit();	
	else 
		-- WoW 10.x
		if module:getOption("disableDragonflightActionBarInVehicle") ~= false then
			MainMenuBar.ctBBHiddenInVehicle = true
		end
		
		if module:getOption("disableDragonflightActionBarWhileDragonriding") then
			MainMenuBar.ctBBHiddenInDragonriding = true
		end
		
		if CT_BarMod and CT_BarMod.updateOptionFromOutside then
			local t1, t2 = module:getOption("disableDragonflightActionBarChangedDate"), CT_BarMod:getOption("disableDragonflightActionBarChangedDate")
			preventLoop = true
			if (t1 and t2 and t1 > t2) or (t1 and not t2) then
				CT_BarMod:setOption("disableDragonflightActionBar", module:getOption("disableDragonflightActionBar"))
			elseif (t1 and t2 and t2 < t1) or (t2 and not t1) then
				module:setOption("disableDragonflightActionBar", CT_BarMod:getOption("disableDragonflightActionBar"))			
			end
			preventLoop = nil
		end  

		if module:getOption("disableDragonflightActionBar") ~= false then
			MainMenuBar.ctBBHidden = true
			if MainMenuBar.ctBBHiddenInDragonriding then
				RegisterAttributeDriver(MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "hide" or "[overridebar] show; [vehicleui] show; hide")
			else
				RegisterAttributeDriver(MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "[bonusbar:5] show; hide" or "[bonusbar:5] show; [overridebar] show; [vehicleui] show; hide")
			end
		end
	end
	
	module:optionsInit();
	module:addonsInit();

	-- Load the addons (bars).
	do
		-- We want to do this before initializing the applied options table.
		
		-- Common Button Bars
		module:insertAddonTitle(L["CT_BottomBar/Options/AddonList/CommonBarsSubheading"])
		module:loadAddon("Action Bar Arrows");
		if module:getGameVersionAndPatch() < 10.05 then
			module:loadAddon("Bags Bar");
			module:loadAddon("Menu Bar")
		end
		if (KeyRingButton) then
			module:loadAddon("Classic Key Ring Button");
		end
			
		-- Special Button Bars
		module:insertAddonTitle(L["CT_BottomBar/Options/AddonList/SpecialBarsSubheading"])
		module:loadAddon("Pet Bar");
		if (MultiCastActionBarFrame) then
			-- note: in the source code of CT_BottomBar_MultiCast.lua, the last line is commented out making this fruitless
			module:loadAddon("MultiCastBar");
		end
		if (PossessBarFrame) then
			-- WoD onwards
			module:loadAddon("Possess Bar");	
		end
		if (module:getGameVersion() <= 7) then
			-- Classic
			module:loadAddon("Stance Bar")
		else
			-- Retail
			module:loadAddon("Class Bar");
		end
		if (ExtraActionBarFrame) then
			module:loadAddon("Extra Bar");
		end
		if module:getGameVersionAndPatch() < 10.05 and VehicleSeatIndicator then
			module:loadAddon("Vehicle Bar");
		end
		if (ZoneAbilityFrame) then
			module:loadAddon("Zone Ability Bar");
		end

		-- Status Tracking (Exp/Rep) Bars
		module:insertAddonTitle(L["CT_BottomBar/Options/AddonList/StatusTrackingBarsSubheading"])
		if (StatusTrackingBarMixin) then
			-- Retail
			if module:getGameVersionAndPatch() < 10.05 then
				module:loadAddon("Status Bar");
			end
		else
			-- Classic
			module:loadAddon("Experience Bar");
			module:loadAddon("Reputation Bar");	-- must come after experience bar
		end
		
		-- Informational Bars
		module:insertAddonTitle(L["CT_BottomBar/Options/AddonList/InformationalBarsSubheading"])
		module:loadAddon("Framerate Bar");
		if (MainMenuBarPerformanceBarFrameButton) then
			module:loadAddon("Classic Performance Bar");
		end
		if (TalkingHead_LoadUI) then
			module:loadAddon("Talking Head");
		end
	end

	-- Hook some functions.
	hookFunctions();

	-- Register some events.
	registerEvents();
	
	-- Setup an OnUpdate function
	initOnUpdate();

	-- Initialize the applied options table.
	module:optionsInitApplied();

	-- Configure things
	configureThings();

	-- Update the "disable the default action bar" option.
	-- This will also update CT_BarMod's version of this option.
	module:setOption("disableDefaultActionBar", module.actionBarDisabled);
end

--------------------------------------------
-- Slash command.

local function slashCommand(msg)
	module:showModuleOptions();
end

module:setSlashCmd(slashCommand, "/ctbb", "/ctbottom", "/ctbottombar");


--------------------------------------------
-- Placeholder funcs

module.hasPetBattleUI = nop
module.hasVehicleUI = nop
module.hasOverrideUI = nop
module.hideOverrideActionBar = nop
module.showOverrideActionBar = nop