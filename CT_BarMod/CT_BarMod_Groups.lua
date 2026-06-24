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

-- End Initialization
--------------------------------------------

if module:getGameVersion() >= 10 then
	--return
end

--------------------------------------------
-- Local Copies

local floor = floor;
local ipairs = ipairs;
local pairs = pairs;
local setmetatable = setmetatable;
local tinsert = tinsert;
local tonumber = tonumber;
local type = type;
local GetOverrideBarIndex = GetOverrideBarIndex;
local GetVehicleBarIndex = GetVehicleBarIndex;
local InCombatLockdown = InCombatLockdown;
local IsShiftKeyDown = IsShiftKeyDown;

-- End Local Copies
--------------------------------------------

--------------------------------------------
-- Group Management

local group =  {};
local groupMeta = { __index = group };

local groupList = {};
module.groupList = groupList;

local dragOnTop = false;
local dragTransparent = false;

local dragEdgeSize = 11;
local overlayEdgeSize = 0;

-- Frame levels relative to the bar's positioning frame.
local overlayLevelAdjust = 1;
local dragLevelAdjust = overlayLevelAdjust + 1;
local buttonLevelAdjust = dragLevelAdjust + 1;
local dragOnTopLevelAdjust = buttonLevelAdjust + 2;  -- + 2 since cooldown is between button and top dragframe

local backdrop1 = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 5, right = 4, top = 5, bottom = 4 },
};

local backdrop2 = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 12, right = 12, top = 12, bottom = 10 }
};

local actionButtons;
local multiBars = {};

--------------------------------------------
-- Group frame

local groupFrameTable;

local function groupFrame_OnEnter(self)
	if (not module:getOption("dragHideTooltip")) then
		local text = "|c00FFFFFF" .. self.object.fullName .. "|r\n" ..
			"Left click to drag\n" ..
			"Right click to rotate\n" ..
			"Shift click to reset";
		module:displayTooltip(self, text);
	end
end

local function groupFrame_OnMouseDown(self, button)
	if (button == "LeftButton") then
		-- Hide the tooltip while user is dragging the frame.
		if (GameTooltip:IsOwned(self)) then
			GameTooltip:Hide();
		end
		-- Start moving the frame.
		module:moveMovable(self.movable);
	end
end

local function groupFrame_OnMouseUp(self, button)
	if (button == "LeftButton") then
		if ( IsShiftKeyDown() ) then
			self.object:resetPosition();
		else
			-- Stop moving the frame.
			module:stopMovable(self.movable);

			-- Redisplay the tooltip
			groupFrame_OnEnter(self);
		end
	elseif (button == "RightButton") then
		-- Toggle current orientation of the bar.
		local orientation = self.object.orientation;
		if ( orientation == "DOWN" ) then
			orientation = "ACROSS";
		else
			orientation = "DOWN";
		end
		module:setOption("orientation" .. self.object.groupId, orientation);
	end
end

local function groupFrame_OnLoad(self)
	self:SetBackdropBorderColor(1, 1, 1, 0);
end

local function groupFrameSkeleton()
	-- Frame that is used to anchor the first action button to.
	if ( not groupFrameTable ) then
		groupFrameTable = {
			-- Frame used to allow dragging of the action buttons.
			["button#hidden#i:dragframe#st:LOW"] = {
				"backdrop#tooltip#0:0:0.5:0.85",
				"font#v:GameFontNormalLarge#i:text",
				["onenter"] = groupFrame_OnEnter,
				["onmousedown"] = groupFrame_OnMouseDown,
				["onmouseup"] = groupFrame_OnMouseUp,
				["onload"] = groupFrame_OnLoad,
			}
		};
	end
	return "frame#s:60:30#v:SecureFrameTemplate,SecureHandlerAttributeTemplate", groupFrameTable;  -- width=60, height=30
end

-- Existing CT_BarMod_GroupNN frames are 60 wide.
-- The first button was positioned TOP relative to the frame (ie. centered).
-- Now that we're positioning TOPLEFT relative to the frame,
-- we'll use the following offset when positioning the first button so that
-- existing users' bars will be in the same place.
local firstButtonOffset = 12;

local function groupOnLeave(group)
	group.isHovered = nil;
	if (group.barMouseover) then
		group.frame:SetAlpha((InCombatLockdown() and group.barFadedCombat) or group.barFaded or 0)
	else
		group.frame:SetAlpha(group.opacity or 1)
	end
end

local function groupCheckHover(group)
	if (group.overlay:IsMouseOver() == true) then
		C_Timer.After(0.1, function() groupCheckHover(group) end);
	else
		group.overlay:SetMouseMotionEnabled(true);
		groupOnLeave(group);
	end
end

local function groupOnEnter(obj)
	local group = module:getGroup(obj.groupId);
	if (not group.isHovered) then
		group.overlay:SetMouseMotionEnabled(false);
		group.isHovered = true;
		group.frame:SetAlpha(group.opacity or 1);
		groupCheckHover(group);
	end
end



local function groupOnCombatStart(group)
	if (not group.isHovered) then
		if (group.barMouseover) then
			group.frame:SetAlpha(group.barFadedCombat or group.barFaded or 0)
		else
			group.frame:SetAlpha(group.opacity or 1)
		end
	end
end

local function groupOnCombatEnd(group)
	if (not group.isHovered) then
		if (group.barMouseover) then
			group.frame:SetAlpha(group.barFaded or 0)
		else
			group.frame:SetAlpha(group.opacity or 1)
		end
	end	
end

module.groupOnLeave = function() end -- no longer needed
module.groupOnEnter = groupOnEnter

function module:setDragOnTop(onTop)
	-- Show group drag frames on top or behind the action buttons.
	if (onTop) then
		dragOnTop = true;
	else
		dragOnTop = false;
	end
	for groupNum, group in pairs(groupList) do
		group:updateDragframe();
	end
end

function module:setDragTransparent(value)
	-- Drag frame is always transparent.
	dragTransparent = not not value;
	for groupNum, group in pairs(groupList) do
		group:updateDragframe();
	end
end

--------------------------
-- Group Class

local function getGroup(groupId)
	local groupNum = module.GroupIdToNum(groupId);
	return groupList[groupNum] or group:new(groupId);
end

function module:getGroup(groupId)
	return getGroup(groupId)
end

module.updateActionBar = function(pos, orientation, scale, opacity, spacing, hide)
	-- Update the action bar.
	-- This was added so that CT_BottomBar could update the action bar.
	-- This is intended to be run before CT_BarMod's option window gets opened.
	-- This function does not update option window widgets.

	local groupId = module.actionBarId;
	local obj = getGroup(groupId);
	local frame = obj.frame;

	if (type(pos) == "table") then
		-- Set the position of the action bar.
		frame:ClearAllPoints();
		frame:SetPoint(pos[1] or "TOPLEFT", UIParent, pos[3] or "TOPLEFT", pos[4] or 0, pos[5] or 0);
		module:stopMovable(obj.movable);

	else
		-- Reset action bar to default position.
		obj:resetPosition();
	end

	local optName, value;

	optName = "orientation";
	value = orientation;
	module:setOption(optName .. groupId, value);
	obj:update(optName, value);

	optName = "barScale";
	value = scale;
	module:setOption(optName .. groupId, value);
	obj:update(optName, value);

	optName = "barOpacity";
	value = opacity;
	module:setOption(optName .. groupId, value);
	obj:update(optName, value);

	optName = "barSpacing";
	value = spacing;
	module:setOption(optName .. groupId, value);
	obj:update(optName, value);

	optName = "showGroup";
	value = not hide;
	module:setOption(optName .. groupId, value);
end

module.resetActionBarPosition = function()
	-- Reset the position of the action bar.
	-- This was added so that CT_BottomBar could reset the position of the action bar.
	local obj = getGroup(module.actionBarId);
	if (obj) then
		obj:resetPosition();
	end
end

module.resetAllBarPositions = function()
	-- Reset the position of the action bar.
	-- This was added so that CT_BottomBar could reset the position of the bars.
	for groupNum, obj in pairs(groupList) do
		obj:resetPosition();
	end
end

local setActionPage_unsecure = function(self, page)
	-- Unsecure code to set the action page (to be called from the secure version).
	-- self == group frame
	-- page == action bar page number (1 to n)
	local actionId;
	local actionMode;
	local count = 1;
	local button = self:GetAttribute("child1");
	while (button) do
		-- Get the values we set while in secure code.
		actionId = button:GetAttribute("action");
		actionMode = button:GetAttribute("actionMode");
		-- Assign them to non-secure values.
		button.actionMode = actionMode;
		button.object.actionMode = actionMode;
		button.action = actionId;
		button.object.actionId = actionId;
		-- Update the buttons visually.
		button.object:update();
		button.object:updateRange();
		-- Get next button.
		count = count + 1;
		button = self:GetAttribute("child" .. count);
	end

	-- Blizzard doesn't update the page number font string on the
	-- action bar arrows when you get into a vehicle, even though
	-- the game has changed the action bar page to 1 (GetActionBarPage() == 1).
	-- Blizzard's main-bar page-number font string moved across versions and is gone in Midnight;
	-- resolve it safely and skip if it no longer exists, instead of indexing a nil value.
	local pageNumberText = MainMenuBarPageNumber
		or (MainMenuBarArtFrame and MainMenuBarArtFrame.PageNumber)
		or (MainMenuBar and MainMenuBar.ActionBarPageNumber and MainMenuBar.ActionBarPageNumber.Text);
	if (pageNumberText) then
		pageNumberText:SetText(GetActionBarPage());   --Changed in WoW 8.0.1
	end


	-- Update our key bindings list if the window is visible.
	module.keybindings_buttonsUpdateList();
end

local setActionPage_secure = [=[
	-- Secure code to set the action page.
	-- Parameters: self, pagenum
	-- self == group frame
	-- select(1, ...) == action bar page number (1 to n).
	
	local secureFrame = self:GetFrameRef("SecureFrame");
	local hasVehicleUI = secureFrame:GetAttribute("hasVehicleUI");
	local hasOverrideBar = secureFrame:GetAttribute("hasOverrideBar");
	local hasPossessBar = secureFrame:GetAttribute("hasPossessBar");
	local hasDragonRiding = secureFrame:GetAttribute("hasDragonRiding");
	local showCancel = secureFrame:GetAttribute("showcancel");
	local maxPage = secureFrame:GetAttribute("maxPage");
	
	local page = select(1, ...);
	page = floor(tonumber(page) or 1);
	-- Use current page if out of range
	if (page < 1 or page > maxPage) then
		page = secureFrame:GetAttribute("currentpage") or 1;
		if (page < 1 or page > maxPage) then
			page = 1;
		end
	end
	local usePage = page;
	local base = (usePage - 1) * 12;
		
	local count = 1;
	local actionId;
	local actionMode;
	local button = self:GetFrameRef("child1");
	
	-- see CT_BarMod_SpellFlyout.lua
	local flyout = button:GetFrameRef("ctSpellFlyout")
	if flyout then
		flyout:Hide()
	end
	
	while (button) do
		-- Determine the action number for this button.
		actionId = base + count;
		
		-- Determine the action mode value for this button.
		--
		-- "action" == action, multicast, tempshapeshift button
		-- "vehicle" == vehicle button
		-- "possess" == possess button
		-- "override" == override button
		-- "cancel" == cancel button
		-- "leave" == leave vehicle button
		--
		-- Page 1 to 10 == action
		-- Page 11 == multicast (GetMultiCastBarIndex() == 11)
		-- Page 12 == vehicle [vehicleui] and possess [possessbar] (GetVehicleBarIndex() == 12)
		-- Page 13 == temporary shapeshift (when does game use this?) (GetTempShapeshiftBarIndex() == 13)
		-- Page 14 == override [overridebar] (GetOverrideBarIndex() == 14)
		
		-- DRAGONFLIGHT
		-- Page 13 == Dragonriding
		-- Page 18 == override [overridebar]  (GetOverrideBarIndex() == 18)
		--
		if (usePage >= 12) then  -- vehicle or possess buttons
			if (hasVehicleUI) then
				if (count == 12) then  -- last button on bar
					actionMode = "leave";
				else
					actionMode = "vehicle";
				end
			elseif (hasPossessBar) then
				if (count == 11) then  -- second to last button on bar
--					actionMode = "cancel";
					actionMode = "possess";
				else
					actionMode = "possess";
				end
			elseif (hasOverrideBar) then
				if (count == 11) then  -- second to last button on bar
--					actionMode = "cancel";
					actionMode = "override";
				else
					actionMode = "override";
				end
			elseif hasDragonRiding then
				actionMode = "action";
			else  -- unexpected set of buttons
				actionMode = "action";
			end
		else
			-- action buttons (pages 1 to 10)
			-- multicast buttons (page 11)
			-- tempshapeshift buttons (page 13)
			actionMode = "action";
		end
		button:SetAttribute("actionMode", actionMode);
		button:SetAttribute("action", actionId);

		--
		-- For similar "type" attribute code see also:
		-- 1) setActionPage_Secure in CT_BarMod_Use.lua
		-- 2) secureFrame_OnAttributeChanged in CT_BarMod.lua
		-- 3) initUpdateButtonType() in CT_BarMod.lua
		--
		if (actionMode == "cancel") then
			-- Set the "type" attribute based on whether or not the
			-- cancel possess button is enabled. That button when clicked
			-- can either exit a vehicle or cancel a possession spell.
			--
			-- We're using secure wrapper around Blizzard's PossessButton2's
			-- OnShow and OnHide scripts to tell us when the possess information
			-- is available and the possess button can be clicked. This is
			-- necessary because GetPossessInfo() is not callable from
			-- secure snippets.
			--
			if (showCancel) then
				button:SetAttribute("type", "click");
			else
				-- This is to prevent Blizzard's code from trying to cancel
				-- a nil buff thus causing an error if the user clicks the
				-- button when there is no possess info available.
				button:SetAttribute("type", nil);
			end

			-- We can't use a secure frame reference to a button since the
			-- frame reference does not have a "Click" method that the
			-- SecureTemplates.lua routine wants to use when our action button
			-- gets clicked.
			-- The button needs to be assigned to the attribute while in unsecure
			-- code (see CT_BarModUse.lua useButton:constructor()).
			--button:SetAttribute("clickbutton", button:GetFrameRef("PossessButton2"));

		elseif (actionMode == "leave") then
			button:SetAttribute("type", "click");

			-- We can't use a secure frame reference to a button since the
			-- frame reference does not have a "Click" method that the
			-- SecureTemplates.lua routine wants to use when our action button
			-- gets clicked.
			-- The button needs to be assigned to the attribute while in unsecure
			-- code (see CT_BarModUse.lua useButton:constructor()).
			--button:SetAttribute("clickbutton", button:GetFrameRef("VehicleMenuBarLeaveButton"));
		else
			if (button:GetAttribute("type") ~= "action") then
				button:SetAttribute("type", "action");
			end
		end

		do
			-- We need to update the show/hide state of the button when the page changes.
			-- If a user has the "hide empty button grid" option enabled, and they have an
			-- empty button on page 2, and they switch to page 1 while in combat, then the
			-- unsecure code can't unhide the button that was hidden while page 2 was
			-- displayed on the bar, so have to do it here in secure code.

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
		end

		count = count + 1;
		button = self:GetFrameRef("child" .. count);
	end

	self:SetAttribute("currentpage", usePage);

	-- Perform visual updates of the buttons
	self:CallMethod("setActionPage", usePage);
]=];

local group_OnAttributeChanged_secure = [=[
	-- Parameters: self, name, value
	if (name == "state-barpage") then
		-- value == action page number

		-- Bar state
		self:RunAttribute("setActionPage", value);
	end
]=];

local firstTime;
function group:new(groupId)
	local group = { };
	local backdrop = backdrop2;
	local movable = "GROUP"..groupId;

	setmetatable(group, groupMeta);

	-- Create the frame for the group.
	-- This is a small fixed-size frame that is not shown.
	-- This bar is used to position the first button of the bar on the screen.
	-- The first button for the bar is always located just below this frame.
	local frame = module:getFrame(groupFrameSkeleton, UIParent, "CT_BarMod_Group" .. groupId);  -- skeleton, parent, name

	-- Assign to the group frame a reference to the secure frame so we can access the frame from the frame's secure code.
	SecureHandlerSetFrameRef(frame, "SecureFrame", CT_BarMod_SecureFrame);

	-- +5 frame.dragframe (when showing dragframe above button)
	-- +4 cooldown (one level above the button)
	-- +3 action button
	-- +2 frame.dragframe (when showing dragframe below button)
	-- +1 frame.overlay
	-- +0 frame (always hidden)
	-- If Masque is loaded then the action button, cooldown, and dragframe (when on top) will be raised higher
	-- since Masque places some frames below the level of the action button. We want our lower drag frame to be below
	-- all of Masque's frames, and our upper drag frame to be above them.
	local frameLevel = 10;  -- High enough to get above the level of Blizzard's ActionButton buttons.
	frame:SetFrameLevel(frameLevel);
--	frame:SetBackdrop(backdrop);
--	frame:SetBackdropColor(1, 1, 1, 0.85);
	frame.object = group;

	-- frame.dragframe is the blue frame that the user appears to drag while the options window is open.
	-- Although they mouse down on 'frame.dragframe', it is actually the hidden 'frame' that gets
	-- moved and who's postion gets saved.
	-- The action buttons are positioned relative to 'frame'.
	local dragframe = frame.dragframe;
	dragframe:SetParent(UIParent);
	dragframe:SetHitRectInsets(5, 5, 5, 5);
	dragframe:SetBackdropColor(0, 0, 0.5, 0.85);
	dragframe:SetFrameLevel(frameLevel + dragLevelAdjust);  -- Should be above the overlay frame we'll create shortly.
	dragframe.movable = movable;
	dragframe.object = group;
	
	group.orientation = module:getOption("orientation" .. groupId);
	group.frame = frame;
	group.groupId = groupId;
	group.movable = movable;
	group.num = module.GroupIdToNum(groupId);

	group.frame:SetAttribute("groupNum", group.num);

	-- .fullName is used in drag frame tooltip, and in keybindings section.
	-- .longName is displayed on bar.
	-- .shortName is displayed on bar.
	if (group.groupId == module.actionBarId) then
		group.fullName = "Bar 12 (Action bar)";
		group.longName = "Action bar";
		group.shortName = "Act";
	elseif (group.groupId == module.controlBarId) then
		group.fullName = "Bar 11 (Control bar)";
		group.longName = "Control bar";
		group.shortName = "Ctl";
	else
		group.fullName = "Bar " .. group.num;
		group.longName = "Bar " .. group.num;
		group.shortName = "B" .. group.num;
	end

	group.barColumns = 1; -- Desired number of columns (across) or rows (down). Init to 1.
	group.numColumns = 1; -- Actual number of columns (across) or rows (down). Init to 1.
	group.numRows = 1;  -- Actual number of rows (across) or columns (down). Init to 1.
	group.barNumToShow = 12; -- Number of buttons to show. Remaining buttons are kept hidden. Init to 12.

	-- Do the following option tests and sets before we add the group to the groupList table.

	if (module:getOption("orientation" .. groupId) == nil) then
		-- This character does not have a value assigned to this option yet.
		-- If this is not one of the original 5 bars (groupIds 1 through 5),
		-- then initially hide this group so that it does not appear in the middle
		-- of the user's screen. They can toggle it on via the CT_BarMod options.
		if (groupId >= 6) then
			module:setOption("showGroup" .. groupId, false);
		end
	end

	if (module:getOption("barHideInVehicle" .. groupId) == nil) then
		-- This character does not have a value assigned to this option yet.
		-- This option was added in 3.304 to replace an existing vehicleHideOther option.
		-- Initialize the new option to the same setting as the old option.
		local hide = module:getOption("vehicleHideOther"); -- default was 1, 1=hide, 2=hide, 3=hide, 4=show
		if (hide ~= nil) then
			if (hide == 4) then
				hide = false;
			else
				hide = 1;
			end
		end
		-- If the bar is not enabled...
		if (not module:getOption("showGroup" .. groupId)) then
			if (group.groupId == module.actionBarId) then
				-- Don't hide main action bar when in a vehicle
				hide = false;
			elseif (group.groupId == module.controlBarId) then
				-- Don't hide control bar when in a vehicle
				hide = false;
			end
		end
		module:setOption("barHideInVehicle" .. groupId, hide);
	end
	if (module:getOption("barHideInOverride" .. groupId) == nil) then
		-- Hide when there is an override bar.
		-- This character does not have a value assigned to this option yet.
		-- This option was added in 5.0001. We'll initialize this to the
		-- same value as the player's "Hide when in vehicle" option.
		local hide = module:getOption("barHideInVehicle" .. groupId) ~= false;
		module:setOption("barHideInOverride" .. groupId, hide);
	end

	if (module:getOption("stdPositions") == nil) then
		-- If this option is nil, then this is a new character,
		-- or an existing character's first time for this option.
		if (module:getOption("orientation1") == nil) then
			-- New character
			local newPositions = module:getOption("newPositions");
			if (newPositions == nil) then
				-- Default to using the standard bar positions.
				newPositions = true;
			end
			module:setOption("stdPositions", newPositions);
		else
			-- Existing character's first time for this option.
			-- Default to the original CT_BarMod positions value (false) since
			-- those would be the bar positions that they have been using.
			module:setOption("stdPositions", false);
		end
		firstTime = true;
	end

	-- Position each of the groups
	group:position(group.orientation, module:getOption("stdPositions"));

	-- Add the group object to the list of groups.
	groupList[group.num] = group;

	-- Tell CT_Library that the frame is movable so it will keep track of the position.
	module:registerMovable(movable, frame);

	-- Set the frame clamping. Note: Do this after the module:registerMovable() call.
	group:setClamped(not not module:getOption("clampFrames"));

	-- Create a frame and anchor it around the action buttons.
	-- This will allow us to detect OnEnter and OnLeave events when the dragframe is not visible.
	local overlay = CreateFrame("Frame", "CT_BarMod_Group" .. groupId .. "Frame", frame, BackdropTemplateMixin and "BackdropTemplate");
--	overlay:SetBackdrop(backdrop);
--	overlay:SetBackdropColor(1, 1, 1, 0.85);
--	overlay:EnableMouse(true);
	overlay:SetFrameLevel(frameLevel + overlayLevelAdjust);  -- At or above 'frame'. Below 'dragframe' and the action buttons.
	-- This affects how far the enablemouse extends near the edge.
	overlay:SetHitRectInsets(0, 0, 0, 0);  -- was 10's
	overlay.background = overlay:CreateTexture(nil, "BACKGROUND");
	overlay.background:SetAllPoints();
	overlay.background:SetColorTexture(1, 1, 1, 0);
	overlay.background:SetVertexColor(1, 1, 1, 1);
	overlay.background:Show();
	
	overlay:Show();
	overlay.groupId = groupId;
	overlay:HookScript("OnEnter", groupOnEnter);
	overlay:SetMouseClickEnabled(false);
	overlay:HookScript("OnEvent", function(__, event)
		if (event == "PLAYER_REGEN_DISABLED") then
			C_Timer.After(0.001, function()
				groupOnCombatStart(group);
			end);
		elseif (event == "PLAYER_REGEN_ENABLED") then
			groupOnCombatEnd(group);
		end
	end);
	overlay:RegisterEvent("PLAYER_REGEN_DISABLED");
	overlay:RegisterEvent("PLAYER_REGEN_ENABLED");

	frame.overlay = overlay;
	group.overlay = overlay;
	group:updateOverlay();

	-- Set the attribute that will tell the game which secure function to call.
	group.frame:SetAttribute("_onattributechanged", group_OnAttributeChanged_secure);

	-- A secure snippet to change the action page.
	group.frame:SetAttribute("setActionPage", setActionPage_secure);

	-- An unsecure method for the secure function to call.
	group.frame.setActionPage = setActionPage_unsecure;

	-- Add a reference to this group, to the secure ActionBarButton we're using to deal
	-- with ACTIONBAR_SHOWGRID and ACTIONBAR_HIDEGRID events.
	SecureHandlerSetFrameRef(CT_BarMod_ActionBarButton, "group" .. group.num, group.frame);
	CT_BarMod_ActionBarButton:SetAttribute("group" .. group.num, group.frame);

	-- Add a reference to this group, to our secure frame.
	SecureHandlerSetFrameRef(CT_BarMod_SecureFrame, "group" .. group.num, group.frame);
	CT_BarMod_SecureFrame:SetAttribute("group" .. group.num, group.frame);

	-- Create a button group in Masque for this bar.
	if (module:isMasqueLoaded()) then
		module:createMasqueGroup(group);
	end
	
	group.objects = group.objects or {};
	if (groupId == 12) then
		actionButtons = group.objects;
	elseif (groupId == 2) then
		multiBars["MultiBarRight"] = group.objects;
	elseif (groupId == 3) then
		multiBars["MultiBarLeft"] = group.objects;
	elseif (groupId == 4) then
		multiBars["MultiBarBottomRight"] = group.objects;
	elseif (groupId == 5) then
		multiBars["MultiBarBottomLeft"] = group.objects;
	end
	return group;
end

local defaultPositions = {};

-- These are the original bar positions used by CT_BarMod.
--   Bar  4 = LE = Left
--   Bar  2 = BL = Bottom left
--   Bar  3 = BR = Bottom right
--   Bar  6 = IR = Inside right
--   Bar  5 = OR = Outside right
--   Bar  7 = BC = Bottom center (lowest)
--   Bar  8 = LC = Lower center
--   Bar  9 = UC = Upper center
--   Bar 10 = TC = Top center
--   Bar  1 = AC = Above center
--   Bar 11 = OC = Over center
--   Bar 12 = HC = High center (highest)
--
-- Secondary index is the bar (group) id.
defaultPositions[1] = {
	[10] = {"BOTTOMLEFT",  "BOTTOM",      -260, 560, "ACROSS", "AC"},  -- Bar  1, Above center
	[1]  = {"BOTTOMLEFT",  "BOTTOM",      -516, 102, "ACROSS", "BL"},  -- Bar  2, Bottom left
	[2]  = {"BOTTOMLEFT",  "BOTTOM",        0,  102, "ACROSS", "BR"},  -- Bar  3, Bottom right
	[3]  = {"BOTTOMLEFT",  "TOPLEFT",      -10, -85, "DOWN",   "LE"},  -- Bar  4, Left
	[4]  = {"BOTTOMRIGHT", "BOTTOMRIGHT",   12, 603, "DOWN",   "OR"},  -- Bar  5, Outside right
	[5]  = {"BOTTOMRIGHT", "BOTTOMRIGHT",  -31, 603, "DOWN",   "IR"},  -- Bar  6, Inside right
	[6]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 300, "ACROSS", "BC"},  -- Bar  7, Bottom center
	[7]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 365, "ACROSS", "LC"},  -- Bar  8, Lower center
	[8]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 430, "ACROSS", "UC"},  -- Bar  9, Upper center
	[9]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 495, "ACROSS", "TC"},  -- Bar 10, Top center
	[11] = {"BOTTOMLEFT",  "BOTTOM",      -260, 625, "ACROSS", "OC"},  -- Bar 11 (Control bar), Over center
	[12] = {"BOTTOMLEFT",  "BOTTOM",      -516, 65, "ACROSS", "HC"},  -- Bar 12 (Action bar), High center
};

-- The following standard (Blizzard) bar positions reorganize the groups
-- so that the bar contents match the bars that Blizzard places in the
-- same screen locations. This makes it easier to switch between using CT_BarMod
-- and the default Blizzard bars since the icons on the bars will be the same.
--   Bar  2 = LE = Left
--   Bar  6 = BL = Bottom left
--   Bar  5 = BR = Bottom right
--   Bar  4 = IR = Inside right
--   Bar  3 = OR = Outside right
--   Bar  7 = BC = Bottom center (lowest)
--   Bar  8 = LC = Lower center
--   Bar  9 = UC = Upper center
--   Bar 10 = TC = Top center
--   Bar  1 = AC = Above center
--   Bar 11 = OC = Over center
--   Bar 12 = HC = High center (highest)
--
-- Secondary index is the bar (group) id.
defaultPositions[2] = {
	[10] = {"BOTTOMLEFT",  "BOTTOM",      -260, 560, "ACROSS", "AC"},  -- Bar  1, Above center
	[1]  = {"BOTTOMLEFT",  "TOPLEFT",      -10, -85, "DOWN",   "LE"},  -- Bar  2, Left
	[2]  = {"BOTTOMRIGHT", "BOTTOMRIGHT",   12, 603, "DOWN",   "OR"},  -- Bar  3, Outside right
	[3]  = {"BOTTOMRIGHT", "BOTTOMRIGHT",  -31, 603, "DOWN",   "IR"},  -- Bar  4, Inside right
	[4]  = {"BOTTOMLEFT",  "BOTTOM",        0,  102, "ACROSS", "BR"},  -- Bar  5, Bottom right
	[5]  = {"BOTTOMLEFT",  "BOTTOM",      -516, 102, "ACROSS", "BL"},  -- Bar  6, Bottom left
	[6]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 300, "ACROSS", "BC"},  -- Bar  7, Bottom center
	[7]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 365, "ACROSS", "LC"},  -- Bar  8, Lower center
	[8]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 430, "ACROSS", "UC"},  -- Bar  9, Upper center
	[9]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 495, "ACROSS", "TC"},  -- Bar 10, Top center
	[11] = {"BOTTOMLEFT",  "BOTTOM",      -260, 625, "ACROSS", "OC"},  -- Bar 11, Over center
	[12] = {"BOTTOMLEFT",  "BOTTOM",      -516, 65, "ACROSS", "HC"},  -- Bar 12, High center
};

-- This holds the position for the main action bar when we detect that CT_BottomBar has disabled
-- the game's main action bar.
--
-- Secondary index is the bar (group) id.
defaultPositions[3] = {
	[12] = {"BOTTOMLEFT", "BOTTOM", -516, 65, "ACROSS", "AB"},  -- Bar 12, Action Bar position
};

if (module:getGameVersion() <= 7) then
	-- override positions to fit better with classic
	defaultPositions[1][12][4] = 45;
	defaultPositions[2][12][4] = 45;
	defaultPositions[3][12][4] = 45;
end

function group:position(orientation, stdPositions)
	if (InCombatLockdown()) then
		return;
	end
	local groupId = self.groupId;
	local frame = self.frame;
	local pos;
	local yoffset;
	if (stdPositions) then
		pos = defaultPositions[2][groupId];
	else
		pos = defaultPositions[1][groupId];
	end
	if (groupId == module.actionBarId) then
		-- If we detect that CT_BottomBar has disabled the default main action bar
		-- then use this position for the action bar. It will place it in the same
		-- spot as the default UI's main action bar.
		if (CT_BottomBar and CT_BottomBar.actionBarDisabled) then
			pos = defaultPositions[3][groupId];
		end
	end
	if (not pos) then
		pos = defaultPositions[2][module.controlBarId];
	end
	yoffset = pos[4];
	if (pos[6] == "BL" or pos[6] == "BR" or pos[6] == "OR" or pos[6] == "IR") then
		if (firstTime and CT_BottomBar) then
			yoffset = yoffset + 9;
		else
			if (MainMenuBarMaxLevelBar and MainMenuBarMaxLevelBar:IsShown()) then
				-- Max level bar only
				yoffset = yoffset - 5;
			else
				if (ReputationWatchBar and ReputationWatchBar:IsShown()) then
					if (MainMenuExpBar and MainMenuExpBar:IsShown()) then
						-- Rep and Exp bars
						yoffset = yoffset + 9;
					-- else
						-- Rep bar only
						-- yoffset = yoffset + 0;
					end
				-- else
					-- Exp bar only
					-- yoffset = yoffset + 0;
				end
			end
		end
	end
	if (TitanMovable_GetPanelYOffset and TITAN_PANEL_PLACE_BOTTOM and TitanPanelGetVar) then
		if (pos[6] == "BL" or pos[6] == "BR") then
			yoffset = yoffset + (tonumber( TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM, TitanPanelGetVar("BothBars")) ) or 0);
		end
	end
	frame:ClearAllPoints();
	frame:SetPoint(pos[1], UIParent, pos[2], pos[3], yoffset);
	module:setOption("orientation" .. groupId, orientation or pos[5] or "ACROSS");
end

function group:resetPosition()
	-- Reset position of the group
	self:position(nil, module:getOption("stdPositions"));
	module:stopMovable(self.movable);
end

function group:positionButtons()
	local objects = self.objects;
	if ( not objects ) then
		return;
	end
	
	if (InCombatLockdown()) then
		return;
	end

	local frame = self.frame;
	local buttons = self:getNumButtonsToShow();
	local button;
	local offset = self.spacing or 6;

	local anchor1, relative1, xoffset1, yoffset1;
	local anchor2, relative2, xoffset2, yoffset2;
	local anchor3, relative3, xoffset3, yoffset3;

	anchor1 = "TOPLEFT";
	relative1 = "BOTTOMLEFT";
	xoffset1 = firstButtonOffset;
	yoffset1 = -4;

	if (self.orientation == "DOWN") then
		if (self.barFlipHorizontal) then
			anchor2 = "RIGHT";
			relative2 = "LEFT";
			xoffset2 = -offset;
			yoffset2 = 0;
		else
			anchor2 = "LEFT";
			relative2 = "RIGHT";
			xoffset2 = offset;
			yoffset2 = 0;
		end
		if (self.barFlipVertical) then
			anchor3 = "BOTTOM";
			relative3 = "TOP";
			xoffset3 = 0;
			yoffset3 = offset;
		else
			anchor3 = "TOP";
			relative3 = "BOTTOM";
			xoffset3 = 0;
			yoffset3 = -offset;
		end
	else -- if (self.orientation == "ACROSS" ) then
		if (self.barFlipVertical) then
			anchor2 = "BOTTOM";
			relative2 = "TOP";
			xoffset2 = 0;
			yoffset2 = offset;
		else
			anchor2 = "TOP";
			relative2 = "BOTTOM";
			xoffset2 = 0;
			yoffset2 = -offset;
		end
		if (self.barFlipHorizontal) then
			anchor3 = "RIGHT";
			relative3 = "LEFT";
			xoffset3 = -offset;
			yoffset3 = 0;
		else
			anchor3 = "LEFT";
			relative3 = "RIGHT";
			xoffset3 = offset;
			yoffset3 = 0;
		end
	end

	local row, rows, column, columns;
	rows = self.numRows;
	columns = self.numColumns;
	row = 1;
	column = 1;
	for key, object in ipairs(objects) do
		button = object.button;
		button:ClearAllPoints();
		if (key > buttons or row > rows) then
			-- caused errors in WoW 8.2; why was this even needed? -- button:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
			object:updateVisibility();
		else
			if (key == 1) then
				button:SetPoint(anchor1, frame, relative1, xoffset1, yoffset1);
			elseif (column == 1) then
				button:SetPoint(anchor2, objects[key - columns].button, relative2, xoffset2, yoffset2);
			else
				button:SetPoint(anchor3, objects[key-1].button, relative3, xoffset3, yoffset3);
			end
			object:updateVisibility();
		end
		column = column + 1;
		if (column > columns) then
			column = 1;
			row = row + 1;
		end
	end

	self:updateDragframePosition();
	self:updateOverlayPosition();
end

function group:updateClampRectInsets()
	-- Adjust the clamping insets

	-- self.frame (which is the movable frame) is
	-- a small rectangle that the first action button is
	-- anchored to. We need to adjust the clamping
	-- insets so that they encompass all of the
	-- action buttons.

	local frame = self.frame;
	local dragframe = frame.dragframe;

	local left, right, top, bottom;

	local frameLeft = frame:GetLeft() or 0;
	local frameRight = frame:GetRight() or 0;
	local frameTop = frame:GetTop() or 0;
	local frameBottom = frame:GetBottom() or 0;

	local dragframeLeft = dragframe:GetLeft() or 0;
	local dragframeRight = dragframe:GetRight() or 0;
	local dragframeTop = dragframe:GetTop() or 0;
	local dragframeBottom = dragframe:GetBottom() or 0;
	local dragframeHeight = dragframe:GetHeight() or 0;

	local edgeSize = dragEdgeSize;
	if (dragOnTop) then
		edgeSize = edgeSize - 3;
	end

	if (frameLeft < dragframeLeft) then
		left = (dragframeLeft - frameLeft) + edgeSize;
	else
		left = edgeSize - (frameLeft - dragframeLeft);
	end

	if (frameRight > dragframeRight) then
		right = -((frameRight - dragframeRight) + edgeSize);
	else
		right = (dragframeRight - frameRight) - edgeSize;
	end

	top = -((frameTop - dragframeTop) + edgeSize);

	if (frameBottom > dragframeTop) then
		bottom = -(dragframeHeight - edgeSize + (frameBottom - dragframeTop));
	else
		bottom = -(dragframeHeight - edgeSize - (dragframeTop - frameBottom));
	end

	frame:SetClampRectInsets(left, right, top, bottom);
end

function group:setClamped(clamp)
	-- Set clamped state of the frame
	self.frame:SetClampedToScreen(clamp);
	self:updateClampRectInsets();
end

function group:getNumButtonsToShow()
	-- Determine how many of the buttons to show.
	-- The first n buttons will be shown, and the last n buttons will be hidden.
	local buttons;
	local objects = self.objects;
	if (not objects) then
		buttons = 0;
	else
		buttons = #objects;
		if (buttons > self.barNumToShow) then
			buttons = self.barNumToShow;
		end
	end
	return buttons;
end

function group:calculateDimensions()
	-- Determine how many rows and columns are needed.
	--
	-- The user selects how many columns/rows they want to see, and this routine
	-- will determine how many rows/columns will be needed.
	--
	-- The actual interpretation of the number chosen by the user depends on the
	-- bar orientation being used.
	--
	-- In "ACROSS" orientation, the columns var represents columns, and the rows var represents rows.
	-- In "DOWN" orientation, the columns var represents rows, and the rows var represents columns.
	--
	local objects = self.objects;
	local buttons = self:getNumButtonsToShow();

	local columns = self.barColumns;  -- desired number of columns
	if (columns > buttons) then
		columns = buttons;
	end
	if (columns <= 0) then
		columns = 1;
	end

	local rows = floor((buttons - 1) / columns) + 1;
	if (rows > buttons) then
		rows = buttons;
	end
	if (rows <= 0) then
		rows = 1;
	end

	-- Actual number of rows and columns.
	self.numRows = rows;
	self.numColumns = columns;
end

function group:addObject(object)
	local objects = self.objects;
	if (not objects) then
		objects = {};
		self.objects = objects;
	end

	local button = object.button;
	local frame = self.frame;

	-- Add the object to the list.
	local lastObject = objects[#objects];  -- Last object in list before we add this one.
	tinsert(objects, object);

	-- Determine how many rows and columns are needed.
	self:calculateDimensions();

	-- Create a frame reference and an attribute reference to the button.
	local buttonCount = #objects;
	SecureHandlerSetFrameRef(frame, "child" .. buttonCount, button);
	frame:SetAttribute("child" .. buttonCount, button);

	-- Prepare to position the object
	if (InCombatLockdown()) then
		return;
	end

	button:SetParent(frame);
	button:ClearAllPoints();

	local adjust;
	-- Raise the button enough to get it above the overlay frame,
	-- and above the drag frame (when the drag frame is below the buttons).
	adjust = buttonLevelAdjust;
	if (module:isMasqueLoaded()) then
		-- Raise the frame level of the action button enough that Masque will be able
		-- to lower some frames without them ending up below the group's drag frame (when
		-- the drag frame is below the buttons).
		adjust = adjust + module:getMasqueFrameLevelAdjustment();
	end
	button:SetFrameLevel(frame:GetFrameLevel() + adjust);

	if ( not lastObject ) then
		-- This object is the only one in the group so far.
		button:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", firstButtonOffset, -4);
		return;
	end
	
	local buttons = self:getNumButtonsToShow();
	if (#objects > buttons) then
		button:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		object:updateVisibility();
	else
		-- Calculate row and column of the object.
		local columns = self.numColumns;
		if (columns == 0) then
			columns = 1;
		end
		local row = floor((buttons - 1) / columns) + 1;
		local column = buttons - ((row - 1) * columns);

		-- Attach the object to the group.
		local lastButton = lastObject.button;
		local offset = self.spacing or 6;

		local anchor2, relative2, xoffset2, yoffset2;
		local anchor3, relative3, xoffset3, yoffset3;
		if (self.orientation == "DOWN") then
			if (self.barFlipHorizontal) then
				anchor2 = "RIGHT";
				relative2 = "LEFT";
				xoffset2 = -offset;
				yoffset2 = 0;
			else
				anchor2 = "LEFT";
				relative2 = "RIGHT";
				xoffset2 = offset;
				yoffset2 = 0;
			end
			if (self.barFlipVertical) then
				anchor3 = "BOTTOM";
				relative3 = "TOP";
				xoffset3 = 0;
				yoffset3 = offset;
			else
				anchor3 = "TOP";
				relative3 = "BOTTOM";
				xoffset3 = 0;
				yoffset3 = -offset;
			end
		else -- if (self.orientation == "ACROSS" ) then
			if (self.barFlipVertical) then
				anchor2 = "BOTTOM";
				relative2 = "TOP";
				xoffset2 = 0;
				yoffset2 = offset;
			else
				anchor2 = "TOP";
				relative2 = "BOTTOM";
				xoffset2 = 0;
				yoffset2 = -offset;
			end
			if (self.barFlipHorizontal) then
				anchor3 = "RIGHT";
				relative3 = "LEFT";
				xoffset3 = -offset;
				yoffset3 = 0;
			else
				anchor3 = "LEFT";
				relative3 = "RIGHT";
				xoffset3 = offset;
				yoffset3 = 0;
			end
		end
		if (column == 1) then
			button:SetPoint(anchor2, objects[buttons - columns].button, relative2, xoffset2, yoffset2);
		else
			button:SetPoint(anchor3, lastButton, relative3, xoffset3, yoffset3);
		end
		object:updateVisibility();
	end
	button:SetScale(self.scale or 1);
	
	self:updateDragframePosition();
	self:updateOverlayPosition();
end

function group:getAnchorButtons()
	local buttons = self:getNumButtonsToShow();

	-- Pretend the player is using a "Right to left, Grow down" configuration.
	-- Determine which buttons will be used to anchor the top left, top right,
	-- and bottom left corners of the drag frame.
	local tl, tr, bl;
	local objectTL, objectTR, objectBL, objectBR
	tl = 1;
	tr = self.numColumns;
	if (buttons < tr) then
		tr = buttons;
	end
	bl = (self.numRows - 1) * self.numColumns + 1;
	if (buttons < bl) then
		-- Calculate number of first object on same row as the last object.
		local columns = self.numColumns;
		if (columns == 0) then
			columns = 1;
		end
		bl = floor((buttons - 1) / columns) * columns + 1;
	end
	if ( self.orientation == "DOWN" ) then
		-- If the orientation is "DOWN", then swap the top right
		-- and bottom left values. This applies whether or not
		-- we will be flipping horizontally and/or vertically.
		local temp = tr;
		tr = bl;
		bl = temp;
	end
	if (self.barFlipHorizontal) then
		if (self.barFlipVertical) then
			-- Right to left, Grow up
			--   D
			-- CBA
			--
			-- Bottom to top, Grow left
			--  C
			--  B
			-- DA
			objectTL = nil;
			objectTR = bl;
			objectBL = tr;
			objectBR = tl;
		else
			-- Right to left, Grow down
			-- CBA
			--   D
			--
			-- Top to bottom, Grow left
			-- DA
			--  B
			--  C
			objectTR = tl;
			objectTL = tr;
			objectBL = nil;
			objectBR = bl;
		end
	else
		if (self.barFlipVertical) then
			-- Left to right, Grow up
			-- D
			-- ABC
			--
			-- Bottom to top, Grow right
			-- C
			-- B
			-- AD
			objectTL = bl;
			objectTR = nil;
			objectBL = tl;
			objectBR = tr;
		else
			-- Left to right, Grow down
			-- ABC
			-- D
			--
			-- Top to bottom, Grow right
			-- AD
			-- B
			-- C
			objectTL = tl;
			objectTR = tr;
			objectBL = bl;
			objectBR = nil;
		end
	end
	return objectTL, objectTR, objectBL, objectBR;
end

function group:updateDragframePosition()
	-- Update position of the button that allows the user to drag the group.
	local objects = self.objects;
	if ( not objects ) then
		return;
	end
	
--	if (InCombatLockdown()) then
--		return;
--	end

	local objectTL, objectTR, objectBL, objectBR = self:getAnchorButtons();

	-- Anchor three corners of the drag frame to buttons.
	local dragframe = self.frame.dragframe;
	local offset = dragEdgeSize;
	if (dragOnTop) then
		offset = offset - 3;
	end
	local minimumOffset = offset;

	local edgeSize = 0;

	local offsetTop, offsetLeft, offsetBottom, offsetRight;
	local bd = self.overlay:GetBackdrop();
	offsetTop    = edgeSize;
	offsetBottom = edgeSize;
	offsetLeft   = edgeSize;
	offsetRight  = edgeSize;
	if (bd and bd.insets) then
		offsetTop = offsetTop + bd.insets.top;
		offsetBottom = offsetBottom + bd.insets.bottom;
		offsetLeft = offsetLeft + bd.insets.left;
		offsetRight = offsetRight + bd.insets.right;
	end

	if (offsetTop < minimumOffset) then
		offsetTop = minimumOffset;
	end
	if (offsetBottom < minimumOffset) then
		offsetBottom = minimumOffset;
	end
	if (offsetLeft < minimumOffset) then
		offsetLeft = minimumOffset;
	end
	if (offsetRight < minimumOffset) then
		offsetRight = minimumOffset;
	end

	dragframe:ClearAllPoints();
	if (objectTL) then
		dragframe:SetPoint("TOPLEFT", objects[objectTL].button, -offsetLeft, offsetTop);
	end
	if (objectTR) then
		dragframe:SetPoint("TOPRIGHT", objects[objectTR].button, offsetRight, offsetTop);
	end
	if (objectBL) then
		dragframe:SetPoint("BOTTOMLEFT", objects[objectBL].button, -offsetLeft, -offsetBottom);
	end
	if (objectBR) then
		dragframe:SetPoint("BOTTOMRIGHT", objects[objectBR].button, offsetRight, -offsetBottom);
	end

	-- Display the name of the group.
	local text = dragframe.text;
	text:ClearAllPoints();
	if (dragOnTop) then
		text:SetPoint("CENTER", dragframe, "CENTER", 0, 0);
	else
		text:SetPoint("BOTTOM", dragframe, "TOP", 0, -5);
	end
	if ( self.orientation == "ACROSS" ) then
		if (self.numColumns == 1) then
			text:SetText(self.shortName);
		else
			text:SetText(self.longName);
		end
	else
		if (self.numRows == 1) then
			text:SetText(self.shortName);
		else
			text:SetText(self.longName);
		end
	end

	self:updateClampRectInsets();
end

function group:updateDragframe()
	local dragframe = self.frame.dragframe;

	local adjust;
	if (dragOnTop) then
		-- Raise the level of the dragframe enough that it will be above the action buttons.
		adjust = dragOnTopLevelAdjust;
		if (module:isMasqueLoaded()) then
			-- Add enough to account for the fact that Masque will lower some frames
			-- below the level of the action button. The action button's frame level is raised
			-- with this in mind when Masque is loaded.
			adjust = adjust + module:getMasqueFrameLevelAdjustment();
		end
	else
		adjust = dragLevelAdjust;
	end
	dragframe:SetFrameLevel(self.frame:GetFrameLevel() + adjust);

	if (dragTransparent) then
		-- Drag frame is always transparent.
		dragframe:SetBackdropColor(0, 0, 0, 0);
	else
		dragframe:SetBackdropColor(0, 0, 0.5, 0.85);
	end

	self:updateDragframePosition();
end

function group:updateOverlayPosition()
	local objects = self.objects;
	if ( not objects ) then
		return;
	end

	local objectTL, objectTR, objectBL, objectBR = self:getAnchorButtons();

	-- Anchor three corners of the overlay frame to buttons.
	local overlay = self.overlay;
	local offset = overlayEdgeSize;
	if (dragOnTop) then
		offset = offset - 3;
	end

	local edgeSize = 0;

	local offsetTop, offsetLeft, offsetBottom, offsetRight;
	local bd = overlay:GetBackdrop();
	offsetTop    = 0
	offsetBottom = 0;
	offsetLeft   = 0;
	offsetRight  = 0;
	if (bd and bd.insets) then
		offsetTop = offsetTop + bd.insets.top;
		offsetBottom = offsetBottom + bd.insets.bottom;
		offsetLeft = offsetLeft + bd.insets.left;
		offsetRight = offsetRight + bd.insets.right;
	end

	overlay:ClearAllPoints();
	if (objectTL) then
		overlay:SetPoint("TOPLEFT", objects[objectTL].button, -(offsetLeft + edgeSize), (offsetTop + edgeSize));
	end
	if (objectTR) then
		overlay:SetPoint("TOPRIGHT", objects[objectTR].button, (offsetRight + edgeSize), (offsetTop + edgeSize));
	end
	if (objectBL) then
		overlay:SetPoint("BOTTOMLEFT", objects[objectBL].button, -(offsetLeft + edgeSize), -(offsetBottom + edgeSize));
	end
	if (objectBR) then
		overlay:SetPoint("BOTTOMRIGHT", objects[objectBR].button, (offsetRight + edgeSize), -(offsetBottom + edgeSize));
	end
	-- Set frame level of the overlay frame. Should be at or just above the postitioning frame.
	overlay:SetFrameLevel(overlay:GetParent():GetFrameLevel() + overlayLevelAdjust);

	overlay.background:ClearAllPoints();
	overlay.background:SetPoint("TOPLEFT", overlay, (offsetLeft), -(offsetTop));
	overlay.background:SetPoint("BOTTOMRIGHT", overlay, -(offsetRight), (offsetBottom));
end

function group:updateOverlay()
	local overlay = self.overlay;
	self:updateOverlayPosition();
end

function group:setOrientation(orientation)
	-- orientation must be "ACROSS" or "DOWN"
	self.orientation = orientation or "ACROSS";
	self:positionButtons();
end

function group:show()
	if (InCombatLockdown()) then
		return;
	end
--	self.frame:Show();
end

function group:hide()
	if (InCombatLockdown()) then
		return;
	end
--	self.frame:Hide();
end

function group:toggleHeader(show)
	if ( show ) then
		self.frame.dragframe:Show();
	else
		self.frame.dragframe:Hide();
	end
	self:updateDragframe();
end

function group:update(optName, value)
	if ( optName == "barScale" ) then
		self.scale = value;
		if (InCombatLockdown()) then
			return;
		end
		local objects = self.objects;
		if ( objects ) then
			for key, object in ipairs(objects) do
				object.button:SetScale(value);
			end
		end
		self:updateClampRectInsets();
		
	elseif ( optName == "barMouseover" ) then
		self.barMouseover = value;
		if (self.overlay:IsMouseOver() or not value) then
			self.isHovered = nil;
			groupOnEnter(self);
		else
			self.isHovered = true;
			groupOnLeave(self);		
		end

	elseif ( optName == "barFaded" ) then
		self.barFaded = value;
		if (not self.overlay:IsMouseOver()) then
			self.isHovered = true;	-- forces a reset of the faded value
			groupOnLeave(self);		
		end
		
	elseif ( optName == "barFadedCombat" ) then
		self.barFadedCombat = value;
		if (not self.overlay:IsMouseOver()) then
			self.isHovered = true;	-- forces a reset of the faded value
			groupOnLeave(self);		
		end

	elseif ( optName == "barOpacity" ) then
		self.opacity = value;
		if (self.overlay:IsMouseOver() or not self.barMouseover) then
			self.isHovered = nil;   -- forces a reset of the base opacity
			groupOnEnter(self);	
		end

	elseif ( optName == "barSpacing" ) then
		self.spacing = value;
		self:positionButtons();

	elseif ( optName == "showGroup" ) then
		if (InCombatLockdown()) then
			return;
		end
		if ( value ) then
			self:show();
		else
			self:hide();
		end

	elseif ( optName == "orientation" ) then
		self:setOrientation(value);  -- value is "ACROSS" or "DOWN"

	elseif ( optName == "barFlipHorizontal" ) then
		self.barFlipHorizontal = not not value;
		self:positionButtons();

	elseif ( optName == "barFlipVertical" ) then
		self.barFlipVertical = not not value;
		self:positionButtons();

	elseif ( optName == "barNumToShow" ) then
		-- Number of buttons to show, starting from the first one (topmost, or leftmost).
		value = value or 12;
		self.barNumToShow = value;

		local objects = self.objects;
		if ( objects ) then
			-- Flag each button for showing or hiding.
			local show;
			for key, object in ipairs(objects) do
				if (key > value) then
					show = false;
				else
					show = true;
				end
				object.showButton = show;
				if (not InCombatLockdown()) then
					object.button:SetAttribute("showbutton", show);
				else
					module.needSetAttributes = true;
				end
			end
		end

		-- Any time we change the number of buttons to show on the bar ("barNumToShow")
		-- we also want to change the upper limit of the slider that controls the desired
		-- number of columns/rows ("barColumns"). The user should not be allowed to select
		-- a "barColumns" value that exceeds the number of buttons we want to show.
		--
		-- The upper limit of the slider will get changed during the function that updates
		-- the "barColumns" widgets on the options screen. However, that function won't get
		-- called until after we return from this current function.
		--
		-- When the upper limit of that slider is changed, it will force the "barColumns" option
		-- to be changed if the current value is greater than the new limit.
		--
		-- Before we return from this function, we want to adjust "self.barColumns" if
		-- necessary, so that the new value will be used in the functions we are going to
		-- call before returning. This will be the same test that occurs when the slider's
		-- max value is eventually changed, but here we're not changing the actual "barColumns"
		-- option.

		if (self.barColumns > self.barNumToShow) then
			-- Adjust the group's copy of the "barColumns" option so that it will get
			-- used in the functions we're about to call before returning.
			self.barColumns = self.barNumToShow;
		end

		self:calculateDimensions();
		self:positionButtons();

	elseif ( optName == "barColumns" ) then
		-- Change the number of columns (or rows) that the user would
		-- like to see. The actual number of columns and rows will
		-- then be calculated.
		self.barColumns = value or 12;
		self:calculateDimensions();
		self:positionButtons();

	end
end

function group:setSkin(skinNumber)
	-- Set the CT skin to use with the buttons in this CT group.
	local objects = self.objects;
	for key, object in ipairs(objects) do
		object:setSkin(skinNumber);
	end
end

function group:reskin()
	-- Reskin the buttons in this group (uses the CT skin).
	local objects = self.objects;
	for key, object in ipairs(objects) do
		object:reskin();
	end
end

--------------------------------------------
-- ACTIONBAR_SHOWGRID and ACTIONBAR_HIDEGRID event handling

-- We want to be able to handle the ACTIONBAR_SHOWGRID and ACTIONBAR_HIDEGRID events in secure code.
-- To do this we'll create an ActionBarButton that inherits from ActionBarButtonTemplate in ActionBarFrame.xml.
-- Blizzard's OnEvent script for these events call functions which change an attribute.
-- We can use a secure wrapper around the button's OnAttributeChanged script so that we can
-- get into secure code in order to show/hide our buttons in response to these events.

local actionButton_gridevent_Unsecure = function(self, showgrid)
	-- Parameters: self, name, value
	-- self == CT_BarMod_ActionBarButton
	-- showgrid == true if ACTIONBAR_SHOWGRID event, else false if ACTIONBAR_HIDEGRID event.

	-- Process all groups.
	local groupNum = 1;
	local group = self:GetAttribute("group1");
	while (group) do
		-- Process all buttons associated with the group.
		local count = 1;
		local button = group:GetAttribute("child1");
		while (button) do

			if (showgrid) then
				button.normalTexture:SetVertexColor(1, 1, 1, 0.5);
			else
				button.object:updateUsable();
			end

			-- Next button
			count = count + 1;
			button = group:GetAttribute("child" .. count);
		end
		-- Next group
		groupNum = groupNum + 1;
		group = self:GetAttribute("group" .. groupNum);
	end
end

local actionButton_OnAttributeChanged_Pre_Secure = [=[
	-- Pre wrap of a securely wrapped OnAttributeChanged script for a button that
	-- inherits from ActionBarButtonTemplate in ActionBarFrame.xml
	--
	-- This is to allow us to handle the "ACTIONBAR_SHOWGRID" and "ACTIONBAR_HIDEGRID"
	-- events via secure code.
	--
	-- Params: self, name, value
	-- self == Special secure button we created that inherits from ActionBarButtonTemplate.
	-- name == Name of attribute
	-- value == Value being assigned to attribute.

	if (name == "showgrid") then
		-- We need to show or hide the empty buttons where applicable.

		-- If new value is greater than previous value, then this was an ACTIONBAR_SHOWGRID event,
		-- else it was an ACTIONBAR_HIDEGRID event.
		local showgrid;
		if (not previousValue) then
			previousValue = 0;
		end
		if (value > previousValue) then
			showgrid = true;
		end
		previousValue = value;

		-- Process all groups.
		local groupNum = 1;
		local group = self:GetFrameRef("group1");
		while (group) do
			-- Process all buttons associated with the group.
			local count = 1;
			local button = group:GetFrameRef("child1");
			while (button) do

				-- For similar visibility code see also:
				-- 1) actionButton_OnAttributeChanged_Pre_Secure in CT_BarMod_Groups.lua
				-- 2) useButton:updateVisibility() in CT_BarMod_Use.lua
				-- 3) SecureHandlerWrapScript(button, "PostClick", ... in CT_BarMod_Use.lua
				-- 4) secureFrame_OnAttributeChanged in CT_BarMod.lua

				-- Show or hide the button
				local show;
				if (showgrid) then
					-- Increase the gridevent count
					button:SetAttribute("gridevent", button:GetAttribute("gridevent") + 1);

					-- If we are showing this button (ie. it is not being forced hidden)...
					if (button:GetAttribute("showbutton")) then
						show = true;
					end
				else
					-- Decrease the gridevent count
					button:SetAttribute("gridevent", max(0, button:GetAttribute("gridevent") - 1));

					-- If we are showing this button (ie. it is not being forced hidden)...
					if (button:GetAttribute("showbutton")) then

						-- If a show grid event is not currently active...
						if (button:GetAttribute("gridevent") == 0) then

							-- Dragging something onto a button may not immediately updated HasAction() so we have to
							-- test for the "receiveddrag" attribute (which we set in the secure code that received
							-- the drag) so that we don't hide the button.

							-- If the button has an action, or if we just dragged something onto this button...
							local actionId = button:GetAttribute("action");
							local actionMode = button:GetAttribute("actionMode");
							if ( HasAction(actionId) ) then
								show = true;
							elseif ( actionMode == "cancel" ) then
								show = true;
							elseif ( actionMode == "leave" ) then
								show = true;
							elseif ( button:GetAttribute("receiveddrag") ) then
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
				end
				if (show) then
					button:Show();
				else
					button:Hide();
				end

				button:SetAttribute("receiveddrag", nil);

				-- Next button
				count = count + 1;
				button = group:GetFrameRef("child" .. count);
			end
			-- Next group
			groupNum = groupNum + 1;
			group = self:GetFrameRef("group" .. groupNum);
		end
		
		-- Perform visual updates of the buttons
		self:CallMethod("grideventFunc", showgrid);
	end

	
	
	return nil;  -- return a non-false value to allow wrapped script to execute
]=];

-- Create an ActionBarButton that inherits from ActionBarButtonTemplate in ActionBarFrame.xml.
local actButton = CreateFrame("CheckButton", "CT_BarMod_ActionBarButton", UIParent, "ActionBarButtonTemplate");
actButton:ClearAllPoints();
actButton:SetPoint("BOTTOMRIGHT", UIParent, "TOPLEFT", 0, 0);
actButton:SetAttribute("statehidden", true);  -- keep it hidden (Blizzard's code will test for this attribute)
actButton:Hide();

SecureHandlerWrapScript(actButton, "OnAttributeChanged", actButton, actionButton_OnAttributeChanged_Pre_Secure, nil);

actButton.grideventFunc = actionButton_gridevent_Unsecure;

if MultiBar7 then
	SecureHandlerSetFrameRef(MultiBar7Button12, "ctActButton", actButton)
	SecureHandlerWrapScript(
		MultiBar7Button12,
		"OnAttributeChanged",
		MultiBar7Button12,
		[=[
			-- name, value
			if name == "showgrid" and value == 1 then
				if self:GetAttribute("ctForceHideGrid") == 1 then
					return true, true
				end
			elseif name == "showgrid" and value == 4 and self:GetFrameRef("ctActButton"):GetAttribute(name) == 4 then
				-- after releasing a spell dragged directly from the spellbook
				return true, true
			else
				self:GetFrameRef("ctActButton"):SetAttribute(name,value)
				return true;
			end
		]=],
		[=[
			self:SetAttribute("showgrid", 0)
		]=]
	)
	MultiBar7Button12:SetAttribute("showgrid", 0)
end



--------------------------------------------
-- Interface

function module:addObjectToGroup(object, groupId)
	-- Add a CT button object to the specified group Id
	-- object == CT button object
	local group = getGroup(groupId);
	group:addObject(object);
end

function module:setSkin(skinNumber)
	-- Set the CT skin to use with each CT group.
	for groupNum, group in pairs(groupList) do
		group:setSkin(skinNumber);
	end
end

function module:reskinAllGroups()
	-- Reskin all groups (uses the CT skin)
	for groupNum, group in pairs(groupList) do
		group:reskin();
	end
end

--------------------------------------------
-- Bar Paging

-- WoW 4 large bonus   : [vehicleui] == false, [bonusbar:5] == true
-- WoW 5 large override: [vehicleui] == false, [possessbar] == false, [overridebar] = true,  [petbattle] = false
-- 
-- WoW 4 large vehicle : [vehicleui] == true,  [bonusbar:5] == true
-- WoW 5 large vehicle : [vehicleui] == true,  [possessbar] == true,  [overridebar] = false, [petbattle] = false
-- 
-- WoW 4 mind control  : [vehicleui] == false, [bonusbar:5] == true
-- WoW 5 dominate mind : [vehicleui] == false, [possessbar] == true,  [overridebar] = false, [petbattle] = false
-- 
-- WoW 5 pet battle    : [vehicleui] == false, [possessbar] == false, [overridebar] = false, [petbattle] = true

function module:buildPageBasicCondition(groupId)
	-- Build the basic macro conditions needed for bar paging of the specified group.
	local group = getGroup(groupId);
	local bar;
	local condition = "";

	if (module:getGameVersion() >= 3) then
		if (groupId == module.actionBarId) then
			condition = condition .. "[vehicleui]" .. GetVehicleBarIndex() .. "; ";
			condition = condition .. "[overridebar]" .. GetOverrideBarIndex() .. "; ";
			condition = condition .. "[possessbar]" .. GetVehicleBarIndex() .. "; ";
		elseif (groupId == module.controlBarId) then
			condition = condition .. "[vehicleui]" .. GetVehicleBarIndex() .. "; ";
			condition = condition .. "[overridebar]" .. GetOverrideBarIndex() .. "; ";
			condition = condition .. "[possessbar]" .. GetVehicleBarIndex() .. "; ";
		end
	end

	bar = module:getOption("pageAltKey" .. groupId) or 1;
	if (bar > 1) then
		condition = condition .. "[mod:alt]" .. (bar - 1) .. "; ";
	end

	bar = module:getOption("pageCtrlKey" .. groupId) or 1;
	if (bar > 1) then
		condition = condition .. "[mod:ctrl]" .. (bar - 1) .. "; ";
	end

	bar = module:getOption("pageShiftKey" .. groupId) or 1;
	if (bar > 1) then
		condition = condition .. "[mod:shift]" .. (bar - 1) .. "; ";
	end

	if (groupId == module.actionBarId) then
		for count = 2, 6 do
			condition = condition .. "[bar:" .. count .. "]" .. count .. "; ";
		end
		for count = 1, 5 do
			condition = condition .. "[bonusbar:" .. count .. "]" .. (count + 6) .. "; ";
		end
		condition = condition .. "1";
	elseif (groupId ~= module.controlBarId) then
		condition = condition .. group.num;
	end

	return condition;
end

function module:buildPageAdvancedCondition(groupId)
	-- Build the advanced macro conditions needed for bar paging of the specified group.
	return module.buildCondition(module:getOption("pageCondition" .. groupId) or "");
end

function module:buildPageCondition(groupId)
	-- Build the macro conditions needed for bar paging of the specified group.
	local condition;
	local barPaging = module:getOption("barPaging" .. groupId) or 1;

	if (barPaging == 2) then
		-- Advanced conditions
		condition = module:buildPageAdvancedCondition(groupId);
	else
		-- Basic conditions
		condition = module:buildPageBasicCondition(groupId);
	end

	return condition;
end

function module:registerPagingStateDriver(groupId)
	-- Register the state driver for bar paging.
	if (InCombatLockdown()) then
		module.needRegisterPagingStateDrivers = true;
		return;
	end
	local group = getGroup(groupId);
	RegisterStateDriver(group.frame, "barpage", module:buildPageCondition(groupId));
end

function module:registerAllPagingStateDrivers()
	-- Register all bar paging state drivers.
	if (InCombatLockdown()) then
		return;
	end
	for groupNum, group in pairs(groupList) do
		module:registerPagingStateDriver(group.groupId);
	end
	module.needRegisterPagingStateDrivers = nil;
end



do
	-- selectively monitor ActionButtonDown() and ActionButtonUp() while the keybindings have been overridden by CT_BarMod_KeyBindings.lua
	hooksecurefunc("ActionButtonDown", function(id)
		if (actionButtons) then
			local button = actionButtons[id];
			if (button) then
				button.button:SetButtonState("PUSHED")
			end
		end
	end);
	
	hooksecurefunc("ActionButtonUp", function(id)
		if (actionButtons) then
			local button = actionButtons[id];
			if (button) then
				button.button:SetButtonState("NORMAL")
			end
		end
	end);
	
	hooksecurefunc("MultiActionButtonDown", function(bar, id)
		bar = multiBars[bar]
		if (bar) then
			local button = bar[id];
			if (button) then
				button.button:SetButtonState("PUSHED")
			end
		end
	end);

	hooksecurefunc("MultiActionButtonUp", function(bar, id)
		bar = multiBars[bar]
		if (bar) then
			local button = bar[id];
			if (button) then
				button.button:SetButtonState("NORMAL")
			end
		end
	end);
end