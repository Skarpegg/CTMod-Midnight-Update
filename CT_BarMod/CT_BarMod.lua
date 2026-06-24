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

local MODULE_NAME = "CT_BarMod";
local MODULE_VERSION = strmatch(C_AddOns.GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

-- End Initialization
--------------------------------------------

if module:getGameVersion() >= 10 then
	--return
end

--------------------------------------------
-- Local Copies

local floor = floor;
local hooksecurefunc = hooksecurefunc;
local string = string;
local tonumber = tonumber;
local InCombatLockdown = InCombatLockdown;

-- End Local Copies
--------------------------------------------

--------------------------------------------
-- Slash command

local function slashCommand(msg)
	local val1, val2;
	val1, msg = string.match(msg or "", "^(%S+)%s*(.*)$");
	val2, msg = string.match(msg or "", "^(%S+)%s*(.*)$");
	if (val1) then
		val1 = string.lower(val1);
		if (val1 == "hide" or val1 == "show") then
			-- val2 is the group number.
			local groupNum = floor(tonumber(val2) or 0);
			if (groupNum < 1 or groupNum > module.maxBarNum) then
				module:print("You must specify a bar number from 1 to " .. module.maxBarNum .. ".");
				return;
			else
				-- Value to assign to the option.
				local show = false;
				if (val1 == "show") then
					show = 1;
				end

				-- Convert group number into group id.
				local groupId = module.GroupNumToId(groupNum);

				-- Enable or disable the bar.
				-- If the bar is enabled it will either show or hide based on the
				-- configured visibility conditions.
				module:setOption("showGroup" .. groupId, show);

				return;
			end
		end
	end
	module:showModuleOptions();
end

module:setSlashCmd(slashCommand, "/ctbar", "/ctbm", "/ctbarmod");

--------------------------------------------
-- Hide/show the game's extra action bars.
-- Note: Here, "extra bar" refers to the game's four MultiBar bars, not the ExtraBar
-- that Blizzard added to the game after this code had been written.

-- (in game options) (frame name)         (enable bar variable)   (action bar page)       (our bar number)
--
-- Bottom Left Bar,  MultiBarBottomLeft,  SHOW_MULTI_ACTIONBAR_1, Main action bar page 6, CT_BarMod bar 6
-- Bottom Right Bar, MultiBarBottomRight, SHOW_MULTI_ACTIONBAR_2, Main action bar page 5, CT_BarMod bar 5
-- Right Bar,        MultiBarRight,       SHOW_MULTI_ACTIONBAR_3, Main action bar page 3, CT_BarMod bar 3
-- Right Bar 2,      MultiBarLeft,        SHOW_MULTI_ACTIONBAR_4, Main action bar page 4, CT_BarMod bar 4

-- Normal for the game:
--
--	When MultiBarRight (Right Bar) is disabled in the game options
--		MultiBarRight gets hidden.
--		Page 3 is not ignored by the main action bar previous/next commands.
--		MultiBarLeft stays enabled, but its checkbox cannot be modified by the player.
--		MultiBarLeft gets hidden.
--		Page 4 is not ignored by the main action bar previous/next commands.
--
--	When MultiBarRight (Right Bar) is enabled in the game options
--		MultiBarRight gets shown.
--		Page 3 is ignored by the main action bar previous/next commands.
--		MultiBarLeft is shown or hidden based on whether it is enabled (show) or disabled (hide).
--
--      Possible combinations of bar 3 and 4:
--		Bar 3 is hidden, Bar 4 is hidden. Main action bar will show page 3 and 4.
--		Bar 3 is shown,  Bar 4 is hidden. Main action bar will show page 4, but not 3.
--		Bar 3 is shown,  Bar 4 is shown.  Main action bar will not show page 3 or 4.
--
--		The game will not show bar 4 unless bar 3 is enabled (shown).
--
-- For CT_BarMod:
--	If "hideExtraBar3" option is enabled, then force "hideExtraBar4" to be enabled.
--	If "hideExtraBar3" option is disabled, then the player can enable or disable "hideExtraBar4".

local extraHidden = {};
local extraHooked = {};

local function adjustVehicleSeatIndicator()
	-- Adjust VehicleSeatIndicator position.
	-- Based on code in MultiActionBar_Update in MultiActionBars.lua.

	if (not VehicleSeatIndicator) then
		return;
	end

	-- We don't want to move the frame if it looks like something else is controlling the position.
	local point = VehicleSeatIndicator:GetPoint(1);

	-- If it looks like the anchor point was set by Blizzard...
	if (
		point and
		point[1] == "TOPRIGHT" and
		point[2] == MinimapCluster and
		point[3] == "BOTTOMRIGHT" and
		(point[5] >= -13.1 and point[5] <= -12.9) and
		(
			(point[4] >= -100.1 and point[4] <= -99.9) or 
			(point[4] >=  -62.1 and point[4] <= -61.9) or 
			(point[4] >=   -0.1 and point[4] <=   0.1)
		)			
	) then
		-- Instead of using SHOW_MULTI_ACTIONBAR_3 and SHOW_MULTI_ACTIONBAR_4
		-- like in Blizzard's function, we need to use the actual frames and test
		-- if they are shown.
		--
		-- Because Blizzard is not using the bar frames in their tests, they may move
		-- the vehicle seat indicator even though we have the action bar(s) hidden.

		VehicleSeatIndicator:ClearAllPoints();
		if ( MultiBarRight:IsShown() and MultiBarLeft:IsShown() ) then
			VehicleSeatIndicator:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", -100, -13);
		elseif ( MultiBarRight:IsShown() ) then
			VehicleSeatIndicator:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", -62, -13);
		else
			VehicleSeatIndicator:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", 0, -13);
		end
	end
end

local function hooked_MultiActionBar_Update()
	-- (hooksecurefunc of MultiActionBar_Update in MultiActionBars.lua)

	-- If the vehicle seat indicator frame exists,
	if (VehicleSeatIndicator) then
		-- If we're hiding one or both of the extra vertical action bars on the right...
		local hide3 = not not module:getOption("hideExtraBar3");
		local hide4 = not not module:getOption("hideExtraBar4");
		if (hide3) then
			-- Prevent invalid combination.
			hide4 = true;
		end
		if (hide3 or hide4) then
			-- Adjust VehicleSeatIndicator position
			adjustVehicleSeatIndicator();
		end
	end
end

local function extraBar_setButtonAlpha(frame, alpha)
	-- Set the alpha of all the buttons to 0.
	local button;
	local fname = frame:GetName();
	for i = 1, 12 do
		button = _G[fname .. "Button" .. i];
		if (button) then
			button:SetAlpha(alpha);
		end
	end
end

local function extraBar_OnShow(self)
	-- If we want to keep this frame hidden..
	if (self.ctbarHide) then
		-- If we're not in combat...
		if (not InCombatLockdown()) then
			-- Hide the frame
			self:Hide();
		else
			-- Set the alpha of the frame's buttons to 0.
			extraBar_setButtonAlpha(self, 0);
		end
	end
end

local function extraBar_OnHide(self)
	-- If we want to keep this frame hidden...
	if (self.ctbarHide) then
		-- Set the alpha of the frame's buttons to 0.
		extraBar_setButtonAlpha(self, 0);

		-- Adjust position of managed frames (some may be affected by this frame).
		UIParent_ManageFramePositions();
	end
end

local function hideExtraBar(page, hide)
	-- Hide or show one of the game's extra action bars.
	-- We cannot be in combat when we do this.

	if (InCombatLockdown()) then
		module.needHideExtraBars = true;
		return;
	end

	local frame;
	if (page == 6) then
		frame = MultiBarBottomLeft;
	elseif (page == 5) then
		frame = MultiBarBottomRight;
	elseif (page == 3) then
		frame = MultiBarRight;
	else -- if (page == 4) then
		frame = MultiBarLeft;
	end

	frame.ctbarHide = hide;

	if (hide) then
		-- Hide the bar.
		extraHidden[page] = true;

		-- Hook the frame's OnShow and OnHide scripts
		if (not extraHooked[page]) then
			extraHooked[page] = true;
			frame:HookScript("OnShow", extraBar_OnShow);
			frame:HookScript("OnHide", extraBar_OnHide);
		end

		-- Use a state driver to keep the bar hidden.
		RegisterStateDriver(frame, "visibility", "hide");
	else
		-- If we hid this frame...
		if (extraHidden[page]) then
			-- Show the bar.
			extraHidden[page] = false;

			-- Remove the state driver
			UnregisterStateDriver(frame, "visibility");

			-- Restore the frame to its proper visibility state.
			-- Based on code in MultiActionBar_Update() in MultiActionBars.lua
			if (page == 6) then
				if ( SHOW_MULTI_ACTIONBAR_1 and MainMenuBar.state=="player" ) then
					MultiBarBottomLeft:Show();
				else
					MultiBarBottomLeft:Hide();
				end
			elseif (page == 5) then
				if ( SHOW_MULTI_ACTIONBAR_2 and MainMenuBar.state=="player") then
					MultiBarBottomRight:Show();
				else
					MultiBarBottomRight:Hide();
				end
			elseif (page == 3) then
				if ( SHOW_MULTI_ACTIONBAR_3 and MainMenuBar.state=="player") then
					MultiBarRight:Show();
				else
					MultiBarRight:Hide();
				end
			else -- if (page == 4) then
				if ( SHOW_MULTI_ACTIONBAR_3 and SHOW_MULTI_ACTIONBAR_4 and MainMenuBar.state=="player") then
					MultiBarLeft:Show();
				else
					MultiBarLeft:Hide();
				end
			end

			-- Set the alpha of the frame's buttons to 1.
			extraBar_setButtonAlpha(frame, 1);

			-- Adjust VehicleSeatIndicator position
			adjustVehicleSeatIndicator();

			-- Adjust position of managed frames (some may be affected by this frame).
			UIParent_ManageFramePositions();
		end
	end
end

function module:hideExtraBars()
	if (InCombatLockdown()) then
		module.needHideExtraBars = true;
		return;
	end

	module.needHideExtraBars = false;

	local hide6 = not not module:getOption("hideExtraBar6");
	local hide5 = not not module:getOption("hideExtraBar5");
	local hide3 = not not module:getOption("hideExtraBar3");
	local hide4 = not not module:getOption("hideExtraBar4");
	if (hide3) then
		-- Prevent invalid combination.
		hide4 = true;
	end

	hideExtraBar(6, hide6);
	hideExtraBar(5, hide5);

	if (not hide3 and not hide4) then
		-- Show both starting with bar 3 so that we have a
		-- valid bar 3 & 4 combination before bar 4 gets shown.
		hideExtraBar(3, false);
		hideExtraBar(4, false);

	elseif (not hide3 and hide4) then
		-- Show bar 3 first so that we have a valid
		-- bar 3 & 4 combination before bar 4 gets hidden.
		hideExtraBar(3, false);
		hideExtraBar(4, true);

	else
		-- (hide3 and hide4) or   -- Valid combination
		-- (hide3 and not hide4)  -- Invalid combination. Hide both instead.
		--
		-- Hide both starting with bar 4 so that we have a
		-- valid bar 3 & 4 combination before bar 3 gets hidden.
		hideExtraBar(4, true);
		hideExtraBar(3, true);
	end
end

--------------------------------------------
-- Secure frame

function module:setAttributes()
	-- Update some attributes of our secure frame (when not in combat).
	-- May also update bars/buttons.
	-- Also sets or clears the flag that indicates if we need to call this function.

	if (not InCombatLockdown()) then
		CT_BarMod_SecureFrame:SetAttribute("buttonLock", module:getOption("buttonLock"));
		CT_BarMod_SecureFrame:SetAttribute("buttonLockKey", module:getOption("buttonLockKey") or 3);

		-- Update button attributes
		local actButton = CT_BarMod_ActionBarButton;
		-- Process all groups.
		local groupNum = 1;
		local group = actButton:GetAttribute("group1");
		while (group) do
			-- Process all buttons associated with the group.
			local count = 1;
			local button = group:GetAttribute("child1");
			local object, value, value2;
			while (button) do
				local update
				object = button.object;

				-- Update the visibility attributes (gridshow, showbutton)
				value = button:GetAttribute("gridshow");
				if (value ~= object.gridShow) then
					button:SetAttribute("gridshow", object.gridShow);
					update = true;
				end

				value = button:GetAttribute("showbutton");
				if (value ~= object.showButton) then
					button:SetAttribute("showbutton", object.showButton);
					update = true;
				end

				if (update) then
					object:updateVisibility();
				end

				-- Update the flyout direction attributes (flyoutDirection)
				value = button:GetAttribute("flyoutDirection");
				value2 = (module:getOption("flyoutDirection" .. object.buttonId) or "UP");
				if (value ~= value2) then
					button:SetAttribute("flyoutDirection", value2);
					object:updateFlyout();
				end

				-- Next button
				count = count + 1;
				button = group:GetAttribute("child" .. count);
			end
			-- Next group
			groupNum = groupNum + 1;
			group = actButton:GetAttribute("group" .. groupNum);
		end

		-- Clear the flag
		module.needSetAttributes = false;
	else
		-- Need to set attributes when not in combat.
		module.needSetAttributes = true;
	end
end

local function initUpdateButtonType()

	-- Wrap the OnShow and OnHide scripts of the possess button that cancels possession so that
	-- we know when Blizzard has shown or hidden it. They do so after checking the "enable" return
	-- value from GetPossessInfo() which is something we can't do from secure code, so we'll let
	-- them do it and notify us indirectly via these wrappers.

	if (PossessBarFrame) then
		-- not in classic

		CT_BarMod_SecureFrame:SetAttribute("updateButtonType",
		[=[
			-- This will update the "type" attribute of the action buttons that have
			-- an actionMode of "cancel"
			-- an actionMode of "leave"

			-- self == CT_BarMod_SecureFrame
			-- select(1, ...) == true if the possess cancel button is enabled

	--		local secureFrame = self;
	--		local showCancel = secureFrame:GetAttribute("showcancel");

			local enabled = select(1, ...);
			local groupNum = 1;
			local groupFrame = self:GetFrameRef("group" .. groupNum);
			while (groupFrame) do
				local actionId;
				local actionMode;
				local buttonNum = 1;
				local buttonFrame = groupFrame:GetFrameRef("child" .. buttonNum);
				while (buttonFrame) do
					actionId = buttonFrame:GetAttribute("action");
					actionMode = buttonFrame:GetAttribute("actionMode");
					if (actionMode == "cancel") then
						--
						-- For similar "type" attribute code see also:
						-- 1) setActionPage_Secure in CT_BarMod_Use.lua
						-- 2) secureFrame_OnAttributeChanged in CT_BarMod.lua
						-- 3) initUpdateButtonType() in CT_BarMod.lua
						--
						if (enabled) then
							buttonFrame:SetAttribute("type", "click");
						else
							buttonFrame:SetAttribute("type", nil);
						end
					elseif (actionMode == "leave") then
						--
						-- For similar "type" attribute code see also:
						-- 1) setActionPage_Secure in CT_BarMod_Use.lua
						-- 2) secureFrame_OnAttributeChanged in CT_BarMod.lua
						-- 3) initUpdateButtonType() in CT_BarMod.lua
						--
						buttonFrame:SetAttribute("type", "click");
					else
						if (buttonFrame:GetAttribute("type") ~= "action") then
							buttonFrame:SetAttribute("type", "action");
						end
					end
					buttonNum = buttonNum + 1;
					buttonFrame = groupFrame:GetFrameRef("child" .. buttonNum);
				end
				groupNum = groupNum + 1;
				groupFrame = self:GetFrameRef("group" .. groupNum);
			end
		]=]);

		SecureHandlerWrapScript(_G["PossessButton" .. (POSSESS_CANCEL_SLOT or 2)], "OnShow", CT_BarMod_SecureFrame,
			[=[
				local enabled = true;
				control:SetAttribute("showcancel", enabled);
				control:RunAttribute("updateButtonType", enabled);
				return nil; -- we want the wrapped handler to execute
			]=]
		);

		SecureHandlerWrapScript(_G["PossessButton" .. (POSSESS_CANCEL_SLOT or 2)], "OnHide", CT_BarMod_SecureFrame,
			[=[
				local enabled = false;
				control:SetAttribute("showcancel", enabled);
				control:RunAttribute("updateButtonType", enabled);
				return nil; -- we want the wrapped handler to execute
			]=]
		);

		-- Set the initial value of the attribute in case Blizzard has already shown/hidden the button.
		local texture, name, enabled = GetPossessInfo(POSSESS_CANCEL_SLOT or 2);
		CT_BarMod_SecureFrame:SetAttribute("showcancel", enabled or false);
	end
end

local function secureFrame_updateButton_unsecure(self, groupNum, buttonNum)
	-- self == our secure frame
	-- groupNum == group number containing the button to be udpated
	-- buttonNum == button number within the group


	local group = self:GetAttribute("group" .. groupNum);
	local button = group:GetAttribute("child" .. buttonNum);
	button.object:update();
end

local function secureFrame_OnAttributeChanged_unsecure(self, name, value)
	if (name == "state-petbattle" or name == "state-overridebar" or name == "state-vehicleui") then
		-- The pet battle state is changing.
		-- Set the action button override key bindings.
		module.setActionBindings();
	end
end

local secureFrame_OnAttributeChanged = [=[
	-- Parameters: self, name, value
	-- self == our secure frame
	-- name == name of attribute
	-- value == value of attribute

	if name == "state-vehicleui" then
		self:SetAttribute("hasVehicleUI", value)
	elseif name == "state-overridebar" then
		self:SetAttribute("hasOverrideBar", value)
	elseif name == "state-possessbar" then
		self:SetAttribute("hasPossessBar", value)
	elseif name == "state-petbattle" then
		self:SetAttribute("hasPetBattle", value)
	elseif name == "state-dragonriding" then
		self:SetAttribute("hasDragonRiding", value)
	end

	if (name == "state-overridebar" or name == "state-vehicleui" or name == "state-possessbar" or name == "state-dragonriding") then
		-- Override bar, vehicle bar, or possess bar state has changed.
		--
		-- Update visibility of buttons with related action ids.
		--
		-- If the user has configured a bar to always show the control bar buttons,
		-- when the buttons on the control bar no longer have actions (such as after
		-- exiting a vehicle) there may still be buttons visible with icons.
		--
		-- After exiting a vehicle, there is a period of time where HasAction() still
		-- returns true for the override bar action id numbers, which can cause these
		-- buttons to still be visible. This state driver allows us to do a finishing
		-- pass on the buttons to make sure they are properly hidden or shown.
		--
		-- For similar visibility code see also:
		-- 1) actionButton_OnAttributeChanged_Pre_Secure in CT_BarMod_Groups.lua
		-- 2) useButton:updateVisibility() in CT_BarMod_Use.lua
		-- 3) SecureHandlerWrapScript(button, "PostClick", ... in CT_BarMod_Use.lua
		-- 4) secureFrame_OnAttributeChanged in CT_BarMod.lua
		--
		local secureFrame = self;
		local showCancel = secureFrame:GetAttribute("showcancel");

		local groupNum = 1;
		local groupFrame = self:GetFrameRef("group" .. groupNum);
		while (groupFrame) do
			-- Update the action page (updates the actionId and actionMod values).
			-- The state-barpage may get set before, between, or after the state attributes set in this routine,
			-- so we need to call setActionPage for each state change since the setActionPage code depends on
			-- the state attributes set in this routine.
			groupFrame:RunAttribute("setActionPage", groupFrame:GetAttribute("currentPage") or 1);

			local actionId;
			local actionMode;
			local buttonNum = 1;
			local button = groupFrame:GetFrameRef("child" .. buttonNum);
			while (button) do
				actionId = button:GetAttribute("action");
				actionMode = button:GetAttribute("actionMode");
				
				-- Ensure that buttons with the following action ids get assigned
				-- the correct "type" attribute.
				--
				-- This is also done in the setActionPage_secure snippet
				-- in CT_BarMod_Use.lua.
				--
				-- When dealing with bars that don't change pages and have
				-- these action ids (such as the normal controlbar), we have to
				-- update the attribute here as well, since other snippet
				-- won't get called due to no page being changed.
				--
				-- The snippet in this file (secureFrame_OnAttributeChanged)
				-- gets called after other the snippet in the other file.
				--
				-- For similar "type" attribute code see also:
				-- 1) setActionPage_Secure in CT_BarMod_Use.lua
				-- 2) secureFrame_OnAttributeChanged in CT_BarMod.lua
				-- 3) initUpdateButtonType() in CT_BarMod.lua
				--
				if (actionMode == "cancel") then
					if (showCancel) then
						button:SetAttribute("type", "click");
					else
						-- This is to prevent Blizzard's code from causing an error
						-- if the user clicks the button when there is no possess info
						-- available.
						button:SetAttribute("type", nil);
					end
				elseif (actionMode == "leave") then
					button:SetAttribute("type", "click");
				else
					if (button:GetAttribute("type") ~= "action") then
						button:SetAttribute("type", "action");
					end
				end

--				if (actionMode == "possess" or actionMode == "override" or actionMode == "vehicle" or actionMode == "cancel" or actionMode == "leave") then
				if (actionMode ~= "action") then
					local show;

					-- If we are showing this button (ie. it is not being forced hidden)...
					if (button:GetAttribute("showbutton")) then

						-- If a show grid event is not currently active...
						if (button:GetAttribute("gridevent") == 0) then

							-- If the button has an action...
							if ( HasAction(actionId) ) then
								show = true;
							elseif ( actionMode == "cancel" ) then
								show = true;
							elseif ( actionMode == "leave" ) then
								show = true;
							else
								-- The button has no action.
								-- If we want to show empty buttons...
								if (button:GetAttribute("gridshow") > 0) then
									show = true;
								end
							end
						else
							-- There is a show grid event that is currently active.
							-- The user is probably dragging an action button.
							-- Show all buttons, empty or not.
							show = true;
						end
					end

					if (show) then
						button:Show();
					else
						button:Hide();
					end

					-- Update the button in case the icon is still showing because
					-- we couldn't hide the empty button due to a show grid event
					-- being active.
					self:CallMethod("updateButton_unsecure", groupNum, buttonNum);
				end

				buttonNum = buttonNum + 1;
				button = groupFrame:GetFrameRef("child" .. buttonNum);
			end
			groupNum = groupNum + 1;
			groupFrame = self:GetFrameRef("group" .. groupNum);
		end
	elseif (name == "state-petbattle" or name == "state-vehicleui" or name == "overridebar") then
		self:CallMethod("OnAttributeChanged_unsecure", name, value);
	end
]=];

local function initSecureFrame()
	local frame = CT_BarMod_SecureFrame;
	local overrideBarIndex = GetOverrideBarIndex and GetOverrideBarIndex() or 14 -- Used to be 14.  Now its 18 in Dragonflight and WotLK Classic.  The function is unavail on Classic Era
	frame:SetAttribute("maxPage", overrideBarIndex);				
	frame:SetAttribute("maxAction", overrideBarIndex * 12);

	-- Set the attribute that will tell the game which secure snippet to use when an attribute changes.
	frame:SetAttribute("_onattributechanged", secureFrame_OnAttributeChanged);

	-- An unsecure method for the secure function to call when an attribute changes.
	frame.OnAttributeChanged_unsecure = secureFrame_OnAttributeChanged_unsecure;

	-- A method to update a button object.
	frame.updateButton_unsecure = secureFrame_updateButton_unsecure;

	initUpdateButtonType();

	-- Detect when the vehicleui state changes.
	--
	-- We need to do this because of the way ENV.UnitHasVehicleUI() is currently written
	-- in RestrictedEnvironment.lua (as of 4.2.2.14545):
	-- 	function ENV.UnitHasVehicleUI(unit)
	--		unit = tostring(unit);
	--		return UnitHasVehicleUI(unit) and
        --			(UnitCanAssist("player", unit:gsub("(%D+)(%d*)", "%1pet%2")) and true) or
        --			(UnitCanAssist("player", unit) and false);
	--	end
	--
	-- The problem is that both UnitCanAssist function calls return nil when
	-- you are in a vehicle with a vehicle UI and unit == "player". This causes
	-- the return value of ENV.UnitHasVehicleUI to be nil.
	--
	-- Also of note is that the second UnitCanAssist return value is 'and'ed with false,
	-- which will always result in a nil or false value. That essentially makes the
	-- 'or' and the second UnitCanAssist call irrelevant.
	--
	-- Also, I'm not sure why they are calling UnitCanAssist in the first place.
	--
	
	RegisterStateDriver(frame, "vehicleui", "[vehicleui]1;nil")
	
	-- Detect when the overridebar state changes.
	RegisterStateDriver(frame, "overridebar", "[overridebar]1;nil")

	-- Detect when the possessbar state changes.
	RegisterStateDriver(frame, "possessbar", "[possessbar]1;nil")

	-- Detect when the petbattle state changes.
	RegisterStateDriver(frame, "petbattle", "[petbattle]1;nil")
	
	-- Detect when the petbattle state changes.
	RegisterStateDriver(frame, "dragonriding", "[bonusbar:5]1;nil")
end

--------------------------------------------
-- Mod Initialization

local firstRun;

function module:isFirstRun()
	return firstRun;
end

module.update = function(self, optName, value)
	if ( optName == "init" ) then

		if (module:getOption("orientation1") == nil) then
			-- This option is always nil the very first time this
			-- addon is run for a new character, or after resetting
			-- the options for this addon.
			--
			-- This option will not be nil when the user logs out
			-- or reloads their UI, so this first run flag we're
			-- going to set can only be tested for during the very
			-- first run of this addon.
			--
			-- Set a flag so we can query the first run flag from
			-- another addon such as CT_BottomBar, via the
			-- CT_BarMod:isFirstRun() function.

			firstRun = true;
		end

		-- Add skins to CT_BarMod (and Masque if loaded).
		module:addSkins();

		-- Create a frame for the addon (used for events, etc).
		local frame = CreateFrame("Frame", "CT_BarMod_Frame");

		-- Create a secure frame
		local secureFrame = CreateFrame("Frame", "CT_BarMod_SecureFrame", nil, "SecureFrameTemplate,SecureHandlerAttributeTemplate");
		initSecureFrame();

		-- Hook MultiActionBar_Update in MultiActionBars.lua.
		hooksecurefunc("MultiActionBar_Update", hooked_MultiActionBar_Update);

		-- Font object for use with the cooldown counts.
		module.CooldownFont = CreateFont("CT_BarMod_CooldownFont");
		module.CooldownFont:SetFontObject(GameFontNormalLarge);

		self:setMode("use");
		
		-- Set up our buttons
		--savedButtons = self:getOption("buttons");
		--if ( not buttons ) then
			--savedButtons = { };
			module:setupPresetGroups();
		--else
		--	for key, value in ipairs(buttons) do
		--		actionButton:new();
		--	end
		--end
	end

	self:bindingUpdate(optName, value);
	self:useUpdate(optName, value);
	self:optionUpdate(optName, value);
end


--------------------------------------------
-- Prevent various frames from appearing behind custom bar positions

do
	local panels =
	{
		-- Two formats:
		-- [optionName] = {needhook = "load-on-demand function to hook", futureFrame = "name of a frame that is loaded on demand"},
		-- [optionName] = {frame = reference_to_a_frame_that_is_always_loaded},
		
		["pullForwardChallengeMode"] = ChallengeMode_LoadUI and {needHook = "ChallengeMode_LoadUI", futureFrame = "ChallengesKeystoneFrame"} or nil,
		["pullForwardCovenantSanctum"] = CovenantSanctum_LoadUI and {needHook = "CovenantSanctum_LoadUI", futureFrame = "CovenantSanctumFrame"} or nil,
	}
	
	local function pullPanelsForward(option, value)
		local panel = panels[option];
		if (panel) then
			if (panel.needHook) then
				hooksecurefunc(panel.needHook, function()
					if (panel.futureFrame) then
						panel.frame = _G[panel.futureFrame];
						panel.futureFrame = nil;
						pullPanelsForward(option, module:getOption(option));
					end
				end)
				panel.needHook = nil;
			elseif (panel.frame) then
				panel.originalLevel = panel.originalLevel or panel.frame:GetFrameLevel();
				if (value ~= false) then
					panel.modified = true;
					panel.frame:SetFrameLevel(max(14, panel.originalLevel));
				elseif (panel.modified) then
					panel.modified = false;
					panel.frame:SetFrameLevel(panel.originalLevel);
				end
			end
			
		end
	end
	
	for option in pairs(panels) do
		pullPanelsForward(option, module:getOption(option));
	end
	
	function module:pullPanelsForward(option, value)
		pullPanelsForward(option, value);
	end
end